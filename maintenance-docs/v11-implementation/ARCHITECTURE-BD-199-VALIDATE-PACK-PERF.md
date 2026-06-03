# ARCHITECTURE-BD-199 — validate-pack.py Check 43 performance regression

**Status:** design (read-only architect pass). **Scope:** BD-199 (NOT BD-195).
**Target:** `scripts/validate-pack.py` · `check_project_side_bare_internal_refs`
(Check 43) and its bare-prose / qualified-prefix inner loops.
**Baseline measured at:** HEAD `696528b` (working-tree line numbers drift due to a
concurrent C6 edit; all citations below are to `git show HEAD:scripts/validate-pack.py`).
**Goal:** behavior-PRESERVING optimization — identical WARN/FAIL fire-set, ~360 s → ~seconds.

---

## 1. Root cause (empirical)

### 1.1 The profile is correct, and the mechanism is per-iteration regex (re)compilation in the bare-prose tier

Check 43 has THREE distinct per-line scanning costs. Exactly one of them
recompiles a regex per inner-iteration and dominates:

| Tier | Loop shape | Pattern source | Compiled where |
|---|---|---|---|
| Qualified `supporting-docs/<X>` | `re.finditer(literal_pat, line)` per line | module-constant *string* | re-compiled per **line** (cache-hit; cheap) |
| Commit-SHA | `_CHECK_43_COMMIT_SHA_PATTERN.search(line)` | pre-compiled module constant | **once** (good) |
| **Bare-prose pack-doc-basename** | `for doc_basename in pack_only_doc_basenames: bp_pat = "(?<!…)" + re.escape(doc_basename) + "(?!…)"; re.search(bp_pat, line)` | **built per (line × basename)** | **per (line × basename)** — the blowup |
| Qualified `pack-ops/`,`maintenance-docs/` | `pattern = re.compile(re.escape(prefix)+…); pattern.finditer(line)` per (line × prefix) | built per (line × prefix) | per (line × prefix); only 2 prefixes (minor) |
| Bare-ref / hyperlink | `_CHECK_40_*_PATTERN.finditer(line)` | pre-compiled module constants | **once** (good) |

The bare-prose tier (`git show HEAD:…` lines 5670–5703) constructs a **fresh
pattern string and runs `re.search` for every basename, on every line, in every
walked file**. Because each distinct pattern STRING is new (a different
`re.escape(doc_basename)`), Python's internal `re` cache (`re._cache`, 512 slots)
churns — every call is effectively a fresh `re._compile`. This is exactly the
profile's "`re._compile` called ≈ `re.search` called" signature (every search is
a cache MISS).

> Empirical-Evidence Block — bare-prose loop recompiles per (line × basename)
> - Command: `git show HEAD:scripts/validate-pack.py | sed -n '5670,5703p'`
> - Output (verbatim, abridged to the load-bearing lines):
>   ```
>   for doc_basename in pack_only_doc_basenames:
>       bp_pat = r"(?<![A-Za-z0-9_.-])" + _re_local.escape(
>           doc_basename
>       ) + r"(?![A-Za-z0-9_.-])"
>       m = _re_local.search(bp_pat, line)
>   ```
> - HEAD/date: `696528b` / 2026-06-03
> - Interpretation: `bp_pat` depends ONLY on `doc_basename` (loop-invariant w.r.t.
>   `line`), yet is rebuilt+searched inside the per-line loop. `re.escape` +
>   string concat + `re.search` (→ `re._compile` cache-miss) run once per
>   (line × basename).
> - Conclusion: SUPPORTED.

### 1.2 Quantifying the iteration count

> Empirical-Evidence Block — inner-loop product ≈ profile call count
> - Command (Python, replicating the fn's walk + basename build against the live tree):
>   measured `pack_only_doc_basenames`, the project-template/ walked-file set
>   (suffix-filtered, mirror-skipped), and total lines.
> - Output (verbatim):
>   ```
>   project-template matched files (walked) = 152
>   total lines across walked files = 16040
>   pack_only_doc_basenames = 586
>   inner-loop compiles (lines x basenames) = 9399440
>   ```
> - HEAD/date: `696528b` / 2026-06-03
> - Interpretation: the bare-prose tier alone performs 16040 × 586 ≈ **9.40M**
>   `re.escape`+`re.compile`+`re.search` calls. The qualified-prefix tier adds
>   16040 × 2 ≈ 32K compiles; `finditer` for supporting-docs/ + bare-ref/hyperlink
>   add the rest. Sum is consistent with the profile's ~11.4M `re.search` /
>   ~11.5M `re._compile`. (The profile run included additional walked surface —
>   `_iter_client_installed_files` also admits sanctioned pack-side files — so the
>   profile's count is slightly higher than the project-template-only 9.4M, as
>   expected.)
> - Conclusion: SUPPORTED. The bare-prose tier is the dominant term; the profile
>   interpretation in the task brief is CONFIRMED.

### 1.3 Wall-time baseline (the regression is real and reproducible)

> Empirical-Evidence Block — single Check-43 run = 363 s, GREEN
> - Command: `/usr/bin/time -p python3 scripts/validate-pack.py --check 43`
> - Output (verbatim, abridged):
>   ```
>   real 363.29
>   user 361.59
>   sys 0.77
>   …
>   PASSED — all checks clean
>   ```
> - HEAD/date: `696528b` / 2026-06-03 (working tree; C6 Check 48 already present)
> - Interpretation: one Check-43 invocation costs ~6 min wall, ~362 s CPU, ~100%
>   user (pure compute, not I/O). The run is GREEN — the current fire-set is the
>   behavior to preserve. The CI `tests` job invokes validate-pack across ~38
>   steps → ~38 × 6 min ≈ 2 h+ matches the reported regression.
> - Conclusion: SUPPORTED.

### 1.4 Challenge — is precompile the WHOLE story, or is there a deeper algorithmic blowup?

Per `preliminary-triage-architect-challenge`, I stress-tested whether the cost is
*only* recompilation or whether there is an irreducible O(files × lines ×
basenames) algorithm that needs an index/set, not just precompilation.

Finding: it is **BOTH a recompile cost AND an O(L × B) scan**, but the recompile
is the >99% term and is removable WITHOUT changing the algorithm's detection set.

- Recompile term (removable): demonstrated 26,000× per-search overhead vs a
  precompiled pattern.
  > Empirical-Evidence Block — per-iteration compile is the dominant constant
  > - Command: micro-benchmark (200 lines × 586 synthetic basenames), compile-in-loop
  >   vs one precompiled alternation.
  > - Output (verbatim):
  >   ```
  >   per-iteration compile (3 runs, 200 lines x586): 8.33 s
  >   precompiled alternation (3 runs, 200 lines): 0.0003 s
  >   speedup ratio ~ 26468
  >   ```
  > - HEAD/date: 2026-06-03
  > - Interpretation: removing the per-iteration compile (via a single precompiled
  >   alternation) eliminates ~4 orders of magnitude of the per-line cost.
  > - Conclusion: SUPPORTED.
- Residual O(L × B) term (only if we KEEP the per-basename loop but precompile
  each pattern at function entry): 9.4M `re.search` calls on already-compiled
  patterns is still ~tens of seconds — NOT seconds. So per-basename
  precompilation alone is **insufficient**; the design must ALSO collapse the 586
  per-basename patterns into ONE combined alternation so the per-line cost is O(L)
  not O(L × B). The combined-alternation form is what reaches ~seconds.

Conclusion of challenge: the correct fix is **both** levers from the GOAL —
(a) precompile once AND (b) collapse N per-candidate patterns into ONE
alternation — not (a) alone. There is NO need for a fundamentally different data
structure (the alternation IS the index); a Python-level `set`-membership rewrite
is not required and would change tokenization semantics (rejected in §2.4).

---

## 2. Fix design (minimal, behavior-preserving)

### 2.1 Lever A — precompile the bare-prose detector as ONE alternation at FUNCTION ENTRY

Replace the per-(line × basename) construction with a single module-level helper
that builds ONE precompiled alternation regex from `pack_only_doc_basenames`,
constructed ONCE per Check-43 invocation (right after `pack_only_doc_basenames =
_build_pack_only_doc_basenames()`), then `finditer` it per line.

Pattern shape (semantically identical boundaries to the current `bp_pat`):

```
(?<![A-Za-z0-9_.-])(?:<esc-b1>|<esc-b2>|…|<esc-bN>)(?![A-Za-z0-9_.-])
```

where each `<esc-bk>` is `re.escape(doc_basename)`. The lookbehind/lookahead
character classes are byte-identical to the current per-basename `bp_pat`, so the
match boundary semantics are preserved exactly.

**Alternation-ordering caveat (MUST be handled).** Python `re` alternation is
**leftmost / first-alternative-wins**, NOT longest-match. Two basenames can share
a prefix where one is a substring of another up to a boundary
(e.g. `ARCHITECTURE.md` vs `ARCHITECTURE-BD-199.md` — though the trailing-boundary
lookahead `(?![A-Za-z0-9_.-])` prevents the shorter from matching inside the
longer here, because `-` is in the boundary class). To be provably safe
regardless of basename shapes, **sort the alternatives by descending length**
before joining. Longest-first ordering guarantees that at any position the regex
prefers the longest valid basename, which (combined with the trailing boundary)
reproduces the union of the 586 independent single-basename searches. This is the
one non-mechanical subtlety; the planner/coder MUST apply descending-length sort.

### 2.2 Lever B — recover per-match basename + preserve the per-match backtick-skip and the fail() text

The current loop does three things per matched basename that the alternation must
reproduce exactly:

1. **Backtick-isolated skip** — if the match is wrapped in backticks
   (`` `X.md` ``), skip (handled by the bare-ref tier). This is a per-MATCH test
   on `m.start()/m.end()` against `line`. With `finditer` over the alternation,
   each `m` still exposes `m.start()/m.end()` and `m.group()` (the matched
   basename), so the identical backtick test applies per match. PRESERVED.
2. **Anchor-phrase exemption** — `_check_43_context_has_anchor(...)` on the line.
   Per match. PRESERVED (call is unchanged).
3. **`fail()` naming the specific basename** — the message embeds
   `` `{doc_basename}` ``. With `finditer`, `m.group()` IS the matched basename;
   substitute it into the message. Message text otherwise byte-identical.
   PRESERVED.

**Multiplicity equivalence.** Current code uses `re.search` (FIRST occurrence
only) PER basename, looping all 586 basenames — so on a single line it can fire
once per DISTINCT basename present. `finditer` over the alternation yields ALL
occurrences left-to-right, which can include the SAME basename twice on one line.
This is a potential behavior delta (one line could emit 2 fails for the same
basename under `finditer` where the old code emitted 1). To preserve EXACTLY the
old fire-set, the coder MUST **dedupe per line by basename**: track a
`seen_on_line: set[str]` and skip a match whose `m.group()` was already
fail/anchor-counted on this line. This reproduces the "search = first-match,
once per basename" semantics of the original while scanning each line ONCE.

> Note: the old loop also iterated basenames in `set` iteration order and emitted
> fails in that order; the new code emits in left-to-right line position order.
> `fail()` writes to stderr and sets a flag — **ordering of fail lines is not a
> behavioral contract** (the gate is pass/fail + the SET of messages). The
> equivalence proof (§3) diffs the SET of emitted lines, not their order; the
> coder MUST sort before diffing.

### 2.3 Lever C (the two qualified-prefix patterns) — precompile at module level

The `for prefix in _CHECK_43_PACK_INTERNAL_PREFIXES:` block (lines 5709–5742)
builds `re.compile(re.escape(prefix)+…)` per (line × prefix). Only 2 prefixes →
~32K compiles → minor vs 9.4M, but it is the SAME anti-pattern and trivially
fixed: hoist to two module-level precompiled constants (or one 2-alternation
constant keyed so the matched prefix is recoverable via a named group). Include
in scope (cheap, same pattern, `scope-deliverables-to-the-ask` is satisfied — it
is the same defect class in the same function, not sprawl). The
`supporting-docs/<X>` `finditer` already uses a literal module-constant string and
hits the re-cache (1 distinct pattern → cache HIT), so it is NOT a recompile
blowup; precompiling it to a module constant is an OPTIONAL micro-tidy, not
required for the perf target — recommend doing it for consistency since it is one
line, but it is not load-bearing.

### 2.4 Rejected alternatives (challenge record)

- **Plain `set`-membership tokenizer (split line into words, test `word in
  basenames`).** REJECTED: would change detection semantics — the current regex
  matches a basename *inside a qualified path* (`docs/pack/FOO.md`) via the
  non-word boundary classes; a naive whitespace tokenizer would miss those and
  ALTER the fire-set. Behavior-preservation forbids it.
- **Per-basename precompile but KEEP the per-basename loop (Lever A without the
  alternation collapse).** REJECTED as insufficient: leaves the O(L × B) = 9.4M
  `re.search` term → tens of seconds, not seconds. Fails the perf target.
- **Lowering the recursion/`rglob` cost in `_build_pack_only_doc_basenames`.**
  OUT OF SCOPE / negligible: that function runs ONCE per Check-43 invocation
  (one `rglob` of the repo), not in the hot loop. The profile attributes ~0% to
  it. No change.

---

## 3. Behavioral-equivalence guarantee (non-negotiable)

The optimized Check 43 MUST produce the IDENTICAL set of WARN/FAIL lines and the
IDENTICAL exit code on the same tree. Equivalence rests on three preserved
invariants + one mechanical diff gate:

1. **Same match boundaries.** The alternation's lookbehind/lookahead classes are
   byte-copied from the current `bp_pat`; the alternatives are exactly
   `re.escape(b)` for each `b in pack_only_doc_basenames` (same set, same source
   builder, unchanged). Descending-length sort makes the union-of-searches and
   the single-alternation match the SAME spans (§2.1).
2. **Same per-match decisions.** Backtick-skip, anchor exemption, and the
   per-line per-basename dedupe (§2.2) reproduce "first match per distinct
   basename, skip backticked, skip anchored" exactly.
3. **Same messages.** `fail()` strings are byte-identical except the basename is
   sourced from `m.group()` instead of the loop variable — same value.

### 3.1 Coder verification procedure (mandatory, in the IMPL-REPORT)

The coder MUST prove equivalence empirically, not by inspection:

1. **Golden-output capture (before):** on the unmodified working tree,
   `python3 scripts/validate-pack.py --check 43 > /tmp/c43.before 2>&1`.
   (Baseline already known GREEN — §1.3.)
2. Apply the fix.
3. **Golden-output capture (after):**
   `python3 scripts/validate-pack.py --check 43 > /tmp/c43.after 2>&1`.
4. **Set-diff gate (order-independent):**
   `diff <(grep -E '^(WARN|FAIL|  OK):' /tmp/c43.before | sort) \
         <(grep -E '^(WARN|FAIL|  OK):' /tmp/c43.after | sort)`
   MUST be empty. (Sort because fail-line ORDER is not a contract — §2.2.) The
   final summary line (`PASSED`/exit code) MUST be identical.
5. **Negative-fixture proof (does it still DETECT):** the fix must not silently
   stop firing. The coder MUST run the existing Check-43 test
   (`scripts/tests/test-validate-pack-check-43.sh`) which exercises the
   fail-paths against synthetic fixtures; it MUST still pass. Additionally, the
   coder injects ONE temporary positive fixture (a project-template/ scratch line
   citing a known pack-only-doc basename in bare prose, e.g. `MERGE-STRATEGY.md`),
   confirms BOTH before and after fire the SAME fail on it, then removes the
   scratch line (no fixture left behind).
6. **Full-gate green:** `python3 scripts/validate-pack.py` exits 0 (fire-set 0)
   post-fix, AND the per-check test wired in CI passes.

If step 4 is non-empty, the fix is a correctness regression — STOP and report,
do not ship.

> Empirical-Evidence Block — the existing Check-43 test exists and is the
> equivalence anchor
> - Command: `ls scripts/tests/ | grep 43`
> - Output: `test-validate-pack-check-43.sh`
> - HEAD/date: `696528b` / 2026-06-03
> - Interpretation: a per-check test already encodes Check 43's fail-path
>   behavior; it is the regression anchor for step 5.
> - Conclusion: SUPPORTED.

---

## 4. Sibling sweep (Check 40, Check 47, others)

> Empirical-Evidence Block — Check 40 does NOT share the anti-pattern
> - Command: `git show HEAD:scripts/validate-pack.py | sed -n '5081,5226p'`
> - Output (load-bearing lines): Check 40's per-line loop calls
>   `_CHECK_40_BARE_REF_PATTERN.finditer(line)` and
>   `_CHECK_40_HYPERLINK_PATTERN.finditer(line)` — both **module-level
>   pre-compiled constants** (defined lines 4924/4930). No per-iteration
>   `re.compile`/`re.escape` in the loop.
> - HEAD/date: `696528b` / 2026-06-03
> - Interpretation: Check 40 already follows the precompile pattern. No fix needed.
> - Conclusion: NOT-AFFECTED (out of scope).

> Empirical-Evidence Block — Check 47 has no regex loop at all
> - Command: `git show HEAD:scripts/validate-pack.py | sed -n '6989,7045p'`
> - Output: `check_sanctioned_pack_side_shipped` is pure set algebra
>   (`map_pack_side == frozen`, set differences). No regex, no per-line loop.
> - HEAD/date: `696528b` / 2026-06-03
> - Interpretation: structurally cannot exhibit the recompile blowup.
> - Conclusion: NOT-AFFECTED (out of scope).

**In-scope siblings (same function, same defect class):** the two qualified-prefix
`re.compile`-in-loop sites in Check 43 itself (§2.3 Lever C). Fix-now — cheap,
identical pattern, same function. Out-of-scope: everything else (Check 40/47 clean;
`_build_pack_only_doc_basenames` `rglob` is once-per-call, negligible). No
repo-wide `re.compile`-inside-loop audit is in scope for BD-199 — the profile
names exactly one function; the GOAL bounds the fix to the hot path
(`ci-guard-measure-then-bound`: bound the fix to the measured cost).

---

## 5. Verification target (re-measurement plan + expected result)

| Metric | Before (measured) | After (target) | How to measure |
|---|---|---|---|
| Check-43 wall time | 363 s (§1.3) | **< 5 s** | `/usr/bin/time -p python3 scripts/validate-pack.py --check 43` |
| `re._compile` calls | ~11.5M (profile) | **< ~1.5K** (one alternation + 2 prefix patterns + module constants, compiled once) | `python3 -X importtime`? no — use `cProfile` on `--check 43`, read `re._compile` ncalls |
| Full validate-pack wall | minutes | back to **< ~30 s** (the non-43 checks dominate the residual) | `/usr/bin/time -p python3 scripts/validate-pack.py` |
| CI `tests` job | ~2 h | back to **< ~4 min** | CI run after merge |
| Check-43 fire-set | GREEN, N WARN/OK lines | **byte-identical set** (§3.1 step 4) | sorted set-diff of `--check 43` output |

Expected `re._compile` drop: from ≈ (lines × basenames) ≈ 9.4M down to a small
constant (one combined alternation built once + 2 hoisted prefix patterns + the
already-precompiled Check-40 constants). The alternation `re.compile` itself runs
ONCE per Check-43 invocation.

---

## 6. Scope / commit shape

- **BD-199**, single-BD. NOT part of BD-195. One commit.
- **Lands AFTER** BD-195 content commits C6–C8, **BEFORE** the single batched push.
- **`pack-only`** scope keyword is correct: the only touched file is
  `scripts/validate-pack.py` (pack-side; not under `project-template/` or
  `supporting-docs/`). CI Check 36 will pass the `pack-only` claim.
- **Manifest:** `scripts/` is a v11-surface → the commit MUST regen
  `test-fixtures/manifest.txt` if its diff is non-empty
  (`regenerate-manifest-v11-surface`). validate-pack.py is the only source edit;
  manifest likely changes (file hash). Coder regens + stages in the SAME commit.
- **Composition with C6 (Check 48).** C6 added `check_soft_advisory_removed_doc_scan`
  (Check 48) — a SEPARATE function, already present at HEAD `696528b` (its OK line
  appears in the §1.3 run). BD-199 touches ONLY Check 43's three loops + adds
  module-level precompiled constants; it does NOT touch Check 48, Check 40, or
  Check 47. The new module-level constants (the alternation builder is a
  function called at Check-43 entry; the 2 prefix patterns are module constants)
  sit adjacent to the existing `_CHECK_43_*` constants — no overlap with C6's
  additions. Clean composition.
- **Pipeline:** architect (this doc) → planner → user-approve plan → coder →
  bounded review/fix → commit. The planner MUST carry the descending-length-sort
  caveat (§2.1) and the per-line dedupe requirement (§2.2) as explicit plan steps
  — they are the two non-mechanical points where a naive precompile would alter
  the fire-set.

---

## 7. Empirical-Evidence summary (state-claims index)

| # | Claim | Conclusion |
|---|---|---|
| 1 | Bare-prose tier rebuilds+searches a regex per (line × basename) | SUPPORTED (§1.1) |
| 2 | Inner-loop product ≈ 9.4M, consistent with ~11.4M profile | SUPPORTED (§1.2) |
| 3 | One Check-43 run = 363 s, currently GREEN | SUPPORTED (§1.3) |
| 4 | Per-iteration compile is ~26,000× a precompiled search | SUPPORTED (§1.4) |
| 5 | Per-basename precompile ALONE is insufficient (O(L×B) residual) | SUPPORTED (§1.4) |
| 6 | Check 40 uses precompiled constants — not affected | SUPPORTED (§4) |
| 7 | Check 47 has no regex loop — not affected | SUPPORTED (§4) |
| 8 | Existing Check-43 test exists as equivalence anchor | SUPPORTED (§3.1) |

---

## 8. Rules-Applied Verification Block

| Rule | Evidence | Conclusion |
|---|---|---|
| agents-never-commit | No `git add/commit/push/tag` issued; only Read/Bash(read-only measurement)/one Write of this doc. | COMPLIANT |
| agents-read-rule-docs-in-full | Read IN FULL: `CLAUDE.md` (incl. `## Pack memory`), `pack-ops/PACK-AGENTS.md`, `pack-ops/PACK-CHAT.md`, and the 7 curated memory files (`feedback_agents_read_rule_docs_in_full`, `_ci_guard_design_measure_then_bound`, `_architect_planner_empirical_evidence`, `_edit_in_place_not_full_rewrite`, `_agent_output_rules_applied_block`, `_scope_deliverables_to_the_ask`, `_preliminary_triage_architect_challenge`), plus `git show HEAD:scripts/validate-pack.py` Check 43 fn + helpers + Check 40 + Check 47. Complete read; no crop. | COMPLIANT |
| empirical-evidence-blocks | Every state-claim (lines, counts, "compiled per-iteration", 363 s, GREEN, test exists, siblings clean) carries an Empirical-Evidence Block with command + verbatim output + HEAD `696528b` + date 2026-06-03 + interpretation + conclusion (§1.1–§1.4, §3.1, §4). | COMPLIANT |
| ci-guard-design-measure-then-bound | Measured the tree first (9.4M product; 152 files; 586 basenames; 363 s); bounded the fix to the measured hot path (bare-prose tier + the 2 in-function prefix sites); preserved detection semantics exactly (§3 equivalence proof); declared NO repo-wide audit beyond the measured cost. | COMPLIANT |
| preliminary-triage-architect-challenge | Challenged "is precompile the whole story?" → found O(L×B) residual requires the alternation collapse, not precompile alone; rejected set-tokenizer (semantics delta) and per-basename-precompile-only (insufficient) with evidence (§1.4, §2.4). | COMPLIANT |
| scope-deliverables-to-the-ask | Designed exactly the perf fix; in-scope = the one named function's 3 loops; explicitly bounded OUT Check 40/47, `_build_pack_only_doc_basenames` rglob, and any repo-wide audit (§4). No sprawl. | COMPLIANT |
| rules-applied-verification-block | This table. | COMPLIANT |
| preflight-stop-means-stop | No fabrication; all numbers are measured outputs quoted verbatim; would halt on a parent stop. | COMPLIANT |

**Empirical-Evidence Block — complete-read attestation**
- Command: (self-report of tool calls in this session) — Read CLAUDE.md (541 lines),
  PACK-AGENTS.md (226 lines), PACK-CHAT.md (310 lines) in full; Read all 7 curated
  memory files in full; `git show HEAD:scripts/validate-pack.py` slices covering
  Check 43 (5389–5890), Check 40 (5081–5226), Check 47 (6989–7045), helpers
  (4132–4293), constants (grep 4917–5383).
- Output: each Read returned the full file (no truncation reminder); git slices
  returned the full requested ranges.
- HEAD/date: `696528b` / 2026-06-03.
- Interpretation: every named always-on doc + curated memory file + target-code
  region was read in full.
- Conclusion: SUPPORTED — COMPLETE read (not partial).
