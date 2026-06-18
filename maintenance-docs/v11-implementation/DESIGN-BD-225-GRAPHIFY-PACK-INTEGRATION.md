# DESIGN-BD-225-GRAPHIFY-PACK-INTEGRATION

**FINAL architect design — the single source of truth a planner implements directly.**
This document REPLACES the prior preliminary options/OQ design entirely (user-sanctioned
supersession; the old options doc is gone — no mirror, no banner). Every decision below is
either a USER-LOCKED call (encoded faithfully, not re-opened) or net-new design content the
old doc lacked, with each command/state claim backed by an Empirical-Evidence Block re-measured
against the installed `graphify 0.8.39`. This is HOW the LOCKED BD-225 lands — not WHETHER.

- **Author role:** pack-architect (fresh, adversarial-of-self; read-only except this one doc).
- **Date:** 2026-06-18 · **HEAD SHA:** `0a90f56ddfd8ec10216ac40012b831adb4b6e050` · **branch:** `v11-dev`.
- **Target binary:** `graphify 0.8.39` (`/Users/david/.local/bin/graphify`, verified). Extras present `[pdf,svg,watch]`; absent `[neo4j,falkordb,video]`.
- **Inputs read in full:** the prior `DESIGN-BD-225-*` (superseded), `PLAN-BD-225-*`, `PLAN-BD-225-ADVERSARIAL-REVIEW.md`, `RESEARCH-BD-225-GRAPHIFY-INCLUSION.md`; `backlog/BD-225.md` / `BD-233.md` / `BD-234.md`; pack-root trinity `CLAUDE.md`/`AGENTS.md`/`GEMINI.md` (incl. `## Pack memory`); `pack-ops/PACK-MEMORY-RATIONALE.md`; `pack-ops/PACK-CHAT.md` (propagation procedure); `pack-ops/OPTIONAL-FEATURES.md`; `scripts/validate-pack.py` (Checks 45/46/59/62 + registry).
- **Probes:** every `graphify` invocation this design relies on was independently probed against 0.8.39 in throwaway `/tmp` git repos (built + queried there, then `rm -rf`'d). NO graph was built or indexed in the pack repo; NO `.graphify*` file was written into the pack repo; NO repo file was mutated except this design doc.

> **Boundary banner (absolute, governs every artifact this design prescribes).** PACK-OPS ONLY.
> The graph MAY index the whole repo (incl. `project-template/`) for agent context, but EVERY
> setup artifact (`.graphifyignore`, the `.gitignore` entry, the trinity graph-first rule, the
> rationale section, the CI guard, the post-commit hook) is PACK-SIDE, and the graph-first rule
> lives in the PACK-ROOT trinity, NEVER `project-template/` (P-missed-7 / `bd-pack-only`). Nothing
> ships to clients; clients are entirely unaffected (see §10 opt-in posture). Verified clean:
> `git grep -in graphify -- 'project-template/'` → empty at HEAD (EE-2).

> **How to read.** §1 the two locked invariants that drive everything · §2 graceful degradation +
> opt-in posture (net-new) · §3 the re-validated command table (every invocation probed on 0.8.39,
> net-new) · §4 the `.graphifyignore` (D1/D2/D6) · §5 git hygiene + Check 63 (D8) · §6 the
> graph-first rule + the B-1 rationale-section bijection · §7 the post-commit maintenance hook
> (D4/D5, incl. the M-3 force-on-removal resolution) · §8 backend/secrets guards (Core/D3) ·
> §9 the stale-doc deletion + dangling-ref fixes (D10/M-1) · §10 opt-in/degradation summary +
> the surfaces every change touches (enumerate-encoding-surfaces) · §11 the dropped MEMORY.md
> step + the BD-232 flag (S-2, hard) · §12 Empirical-Evidence Blocks · §13 Rules-Applied block.

---

## 1. The two locked invariants that drive the whole design

### 1.1 Backend = Claude subscription ONLY, via `--backend claude-cli` (Core, LOCKED)

Every headless semantic refresh uses `graphify extract . --backend claude-cli` — the no-key
subscription path. This is load-bearing and has a TRAP the implementer must not "correct":

- The top-level `graphify --help` `extract --backend` enum lists only
  `gemini|kimi|claude|openai|deepseek|ollama` — it **OMITS `claude-cli`** (EE-3).
- The ACTUAL accepted backend set (surfaced only by the invalid-backend error) is
  `azure, bedrock, claude, claude-cli, deepseek, gemini, kimi, ollama, openai` (EE-4).
- `--backend claude` (the value the help DOES list) **requires `ANTHROPIC_API_KEY`** and is NOT
  the subscription path; `--backend claude-cli` requires no key and uses the subscription (EE-4).

**Design rule (S-3, hard):** pin `--backend claude-cli` literally everywhere; the runbook carries
the one-line caveat *"the top-level `--help` enum omits `claude-cli`; it is valid (verified via the
invalid-backend error) and is the no-key subscription path — do NOT substitute `claude`, which
demands `ANTHROPIC_API_KEY`."* A coder who "fixes" `claude-cli` → `claude` to match the help breaks
the no-key guarantee. This is the single highest-consequence substitution error in the integration.

### 1.2 The graph is a per-clone, gitignored, manual OPT-IN (Core posture, LOCKED scope D6)

The graph (`graphify-out/`), the post-commit hook (`.git/hooks/`), and the initial build are
**per-clone, gitignored, manually installed** — none is committed, none syncs across machines (EE-5,
research §1.10). The committed artifacts are only: the `.graphifyignore`, the `.gitignore` entry, the
trinity rule + its rationale section, the CI guard, and the runbook. Index scope = whole repo minus
the `.graphifyignore` exclusions (D6 "start big"; BD-234 re-tunes after burn-in). This posture has two
direct design consequences, designed in §2: the trinity rule must **degrade gracefully** on a no-graph
clone (the default state), and the hook must be a **guarded, non-blocking** no-op when graphify or the
graph is absent. The feature is BOTH opt-in AND graceful-on-failure (§10).

---

## 2. Graceful degradation + opt-in posture (NET-NEW — the old design lacked this)

A clone has NO graph by default (it is gitignored and per-clone). The integration therefore must
never error or block when the graph is absent; it must silently fall back to normal grep/Read. Three
guards make this true; all three are mandatory.

### 2.1 G1 — the trinity rule carries an existence guard

The graph-first rule (§6) MUST open with the guard *"IF
`$(git rev-parse --show-toplevel)/graphify-out/graph.json` exists, prefer graph queries for
orientation/relationship/blast-radius questions; otherwise use normal grep/Read."* On a fresh clone
(the DEFAULT — no graph), the rule degrades to ordinary tool use with zero friction. The rule is
phrased so an agent that reads it on a graphless clone simply proceeds as it does today.

### 2.2 G2 — fallback-on-query-failure

Even when `graph.json` exists, a query can fail (a stale/torn graph, a vocab miss returning noise, a
matcher mismatch). The rule MUST instruct: *"if a graph query errors or returns nothing useful, fall
back to file reads — never block on the graph."* This makes the graph a best-effort accelerator, never
a hard dependency of any agent task.

### 2.3 G3 — the post-commit hook is GUARDED + NON-BLOCKING

The hook (§7) MUST be the guarded, always-exit-0 template: it runs the refresh ONLY if
`[ -x "$(command -v graphify)" ] && [ -f "<abs>/graphify-out/graph.json" ]`, backgrounds the refresh,
and `exit 0` unconditionally. An installer whose graphify is broken or whose graph was never built
gets a SILENT no-op — never a broken commit. Probed: the guard predicate evaluates correctly and
`exit 0` is unconditional (EE-12).

### 2.4 Opt-in posture (stated plainly)

The graph, the hook, and the initial build are **per-clone, manual, gitignored opt-in**. A maintainer
who does nothing gets exactly today's behavior. Clients are entirely unaffected: nothing graphify
ships in the config pack; no `project-template/` file is touched; the rule lives only in the pack-root
trinity (boundary banner; EE-2). The feature satisfies the dual requirement: it is opt-in AND it
degrades gracefully when it fails or is absent.

---

## 3. Re-validated command table (NET-NEW — every invocation probed on 0.8.39)

Each invocation the design relies on was probed independently against the installed `graphify 0.8.39`
in throwaway `/tmp` git repos. The probe evidence is in §12 (EE-3..EE-12); the table is the
implementer's authoritative invocation reference. **Result: every command below is syntax-valid on
0.8.39 as written; the only doc-vs-CLI gaps are `extract` has no `--no-viz` (M-2) and the `--backend`
help-enum omits `claude-cli` (S-3) — both encoded as caveats, not failures. Commands re-validated: 11
(plus the two env-guard predicates). None failed as designed.**

| # | Invocation (as the design uses it) | Probe verdict (0.8.39) | Parameter-fit justification |
|---|---|---|---|
| C-a | Initial build: interactive `/graphify .` (Claude session), `--no-viz` ON, clustering ON | VALID (skill path; `--no-viz` is a build/skill flag, EE-3) | One-time, parallel (faster than the serial hook); `--no-viz` skips the HTML render that refuses >5000 nodes anyway and is never opened in an agent flow (EE-3); clustering ON because the Leiden communities/god-nodes power `query`/`explain` (the whole value). |
| C-b | `graphify update .` (code-only refresh) | VALID — runs no-LLM, ~0 tokens; rebuilt graph.json in probe (EE-6) | The FREE deterministic branch of the doc-gate (§7); tree-sitter only, never touches the semantic layer. |
| C-c | `graphify extract . --backend claude-cli` (semantic refresh) | VALID — `claude-cli` accepted (EE-4); serial subscription path; **`--no-viz` is NOT a flag of `extract` (M-2)** | The semantic branch of the doc-gate; `claude-cli` = no-key subscription; serial (`GRAPHIFY_CLAUDE_CLI_PARALLEL` off — parallel `claude -p` conflicts). Do NOT pass `--no-viz` here (extract emits no HTML; the flag would be an unknown-option error — EE-3). |
| C-d | `graphify check-update .` (safety net) | VALID — exit 0 in probe (EE-12) | Cron-safe "is a semantic re-extraction pending?" notification; the backstop if a backgrounded refresh was missed. |
| C-e | `graphify query "..." --budget N --graph <abs>` | VALID — BFS subgraph returned in probe (EE-7) | The primary read; `--budget` = 2000 human / 1500 agent / 1000 Pack-Chat prompt-construction (§6.3). `--graph` ALWAYS absolute. |
| C-f | `graphify path "A" "B" --graph <abs>` | VALID — shortest path returned in probe (EE-7) | Structural "how does A reach B"; architect-oriented. |
| C-g | `graphify explain "X" --graph <abs>` | VALID — node+neighbors summary in probe (EE-7) | Node orientation; architect-oriented. |
| C-h | `graphify affected "X" --depth 2 --relation R --graph <abs>` | VALID — reverse-traversal in probe (EE-7); `--depth` default 2 | Blast-radius; reviewer-oriented. Default depth 2 (direct + one hop); raise to 3 only for a deep audit. `--relation` default = all; constrain once edge vocab is known post-build. |
| C-i | Absolute `--graph`: `$(git rev-parse --show-toplevel)/graphify-out/graph.json` | VALID — query against absolute path returned in probe (EE-7) | A sub-agent/hook may start in a different cwd; absolute is non-negotiable. |
| C-j | `GRAPHIFY_FORCE=1 graphify update .` (force-on-removal) | VALID — `update` reads `GRAPHIFY_FORCE` (EE-9); `extract` does NOT (EE-10) | M-3 RESOLVED below: force binds to `update`, not `extract`. |
| C-k | The full post-commit hook command (G3 guard + backgrounded refresh + `exit 0`) | VALID — guard predicate + `exit 0` probed (EE-12) | §7 template; guarded + non-blocking. |
| C-l | Env-guard predicates (assert `GEMINI_API_KEY`/`GOOGLE_API_KEY`/`OPENAI_API_KEY` unset) | VALID — clean-subshell unset check probed (EE-11) | §8 auto-route foot-gun defense. |

**Build / perf knobs (probed-or-doc-grounded, all at the locked Core values):** initial `/graphify .`
build `--no-viz` ON, clustering ON, `--mode deep` OFF (deep multiplies quota for marginal inferred
edges on a 2.65M-word corpus), `--max-workers` default, `GRAPHIFY_CLAUDE_CLI_PARALLEL` OFF (serial),
`GRAPHIFY_NO_BACKUP` 0 (keep backups — needed for the G2 atomic-swap safety, §7.4). All other knobs
default; BD-234 re-tunes with measured `cost.json` after burn-in.

---

## 4. `.graphifyignore` — the exclusion list (D1, D2, D6)

### 4.1 Why a `.graphifyignore` is mandatory, and the one-file-or-the-other consequence

The archive dirs are TRACKED (not gitignored), so a `.gitignore`-based skip would not exclude them
(research EE-3, §1.6). The D1 archive-exclusion lock therefore forces an explicit `.graphifyignore`.
And the moment `.graphifyignore` exists, graphify uses ONLY it and stops reading `.gitignore` for
indexing (one-file-or-the-other; research §1.6). So every gitignored category that must stay out of the
graph is re-listed here. Graphify's built-in always-pruned set (`graphify-out`, `node_modules`, `.git`,
`.venv`, `build`, `dist`, `.next`, `target`, caches) applies ON TOP regardless and is NOT re-listed.

### 4.2 The matcher is Python `fnmatch`, NOT git's pathspec (S-4 — design against the real matcher)

Graphify matches `.graphifyignore` patterns via Python **`fnmatch`** (`detect.py:3 import fnmatch`;
`_is_ignored` matches the rel path, the basename, and each path component, last-match-wins — EE-8),
NOT git's `pathspec`. fnmatch differs in load-bearing ways: `*` **crosses `/`** (it does not in git);
`**` is **not special** (just two `*`); bracket classes `[Aa]` **are** supported (so D1 holds). The D1
and D2 globs below were VALIDATED against THAT matcher (EE-8), not git's. A future maintainer editing
this list under git-glob assumptions could introduce a pattern that behaves differently — the file's
header comment states the matcher explicitly.

### 4.3 The exact `.graphifyignore` content the coder writes (repo root, new file)

```
# .graphifyignore — graphify-only exclusion list for the pack repo (BD-225).
# MATCHER: graphify uses Python fnmatch (detect.py), last-match-wins — NOT git's
# pathspec. So `*` crosses `/`, `**` is NOT special (just two `*`), and bracket
# classes `[Aa]` work. Patterns below were validated against fnmatch.
# ONE-FILE-OR-THE-OTHER: when this file is present, graphify uses ONLY this list
# and does NOT read .gitignore for indexing. graphify's built-in always-pruned
# set (graphify-out, node_modules, .git, .venv, build, dist, .next, target,
# caches) applies on top of this and is NOT re-listed.
# Index scope = WHOLE REPO minus the exclusions below (BD-225 D6 "start big";
# revisit via BD-234 after burn-in).

# ── Archive dirs AND archive-named files (D1: case-insensitive, any depth) ──
*[Aa][Rr][Cc][Hh][Ii][Vv][Ee]*

# ── Secrets / secrets-adjacent (D2 + privacy posture §8) ──
.env
.env.*
**/.env
**/.env.*
.mcp.json
.claude/settings.local.json

# ── Local tracker state (regenerable; no graph value) ──
.pack-tracker/
/tracker.toml

# ── Derived / generated output (pollutes graph with generated symbols) ──
generated/
**/generated/swift/
**/generated/python/

# ── External / not-present reference dir ──
shared-docs/ios26/

# ── OS / editor noise ──
.DS_Store
.AppleDouble
.LSOverride
.Spotlight-V100
.Trashes
._*
.vscode/
.idea/
*.swp
*.swo

# ── Working-tree-only snapshot ──
scripts/.bd119-pre-refactor-monolith.sh.snapshot
```

### 4.4 D1 + D2 globs are empirically validated (against the fnmatch matcher)

Probed against graphify's own `detect._is_ignored` in a `/tmp` fixture (EE-8): the single D1 glob
`*[Aa][Rr][Cc][Hh][Ii][Vv][Ee]*` IGNORES `maintenance-docs/archive/v11/A.md`,
`maintenance-docs/v11-research/templates-archive/T.md`, AND the archive-named FILE
`maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-BATCH-ARCHIVE.md`, while KEEPING
`maintenance-docs/v11-implementation/normal.md`. The D2 globs IGNORE root `.env`, `.env.local`, and a
nested fixture `.env` (e.g. `scripts/tests/fixtures/proj1/.env`). D1 is whole-repo, any-depth,
case-insensitive; D2 covers both top-level and nested `.env`/`.env.*`. (Note: D1's case-insensitive
filename match also excludes the archive-named FILE from the GRAPH — not from git; an agent can still
Read it directly. This follows the D1 lock, which the prior design's "index the archive-named file"
recommendation was overridden by.)

### 4.5 Post-design extension: `test-fixtures/` exclusion block (BD-225 fix-follow)

The shipped `.graphifyignore` was EXTENDED after this design landed by the BD-225 `.graphifyignore`
fix-follow. The §4.3 verbatim block above ENDS at the BD-119 snapshot line
(`scripts/.bd119-pre-refactor-monolith.sh.snapshot`) and carries NO `test-fixtures/` content; the
realized file (`.graphifyignore`, the block headed `── build.sh-generated fixture trees under
test-fixtures/ (BD-225) ──`) appends a `test-fixtures/` exclusion block. It MIRRORS
`test-fixtures/.gitignore` (ignore-everything-except: a broad `test-fixtures/*` exclude followed by `!`
negations re-including the committed recipe/manifest files and the static-snapshot dir), is
fnmatch-validated against `detect.py` (same matcher as §4.2/§4.4), and is future-forward (any NEW
build.sh-generated dir not in the keep-list is excluded automatically). It keeps the build.sh-generated
fixture trees out of the graph while preserving the committed `test-fixtures/` content.

Realized consumer: `.graphifyignore` (repo root), block headed `── build.sh-generated fixture trees
under test-fixtures/ (BD-225) ──`. Provenance: the fix-follow IMPL-REPORT at
`/tmp/handoff-bd225-graphifyignore/IMPL-REPORT.md` (initial extension) and the NIT-1/SHOULD-1 fix pass
`/tmp/handoff-bd225-graphifyignore/FIX-IMPL-REPORT.md` (which authored this §4.5 addendum and the
companion note in `PLAN-BD-225-GRAPHIFY-PACK-INTEGRATION.md` §C1).

---

## 5. Git hygiene: `.gitignore` entry + Check 63 never-tracked guard (D8)

### 5.1 `.gitignore` append (targeted, in-place — do NOT rewrite the file)

`graphify-out/` is a per-clone, regenerated build artifact and must never be committed (research
§1.10). It is currently absent from `.gitignore` (EE-5). Append ONE block at the file tail (the
current last entry is the BD-119 snapshot, EE-5):

```
# ── Graphify knowledge-graph build artifact (BD-225) ─────────────────────────
# Per-clone, regenerated; never committed (CI Check 63 enforces). Includes
# graph.json, GRAPH_REPORT.md, graph.html, cache/, cost.json, memory/, needs_update.
graphify-out/
```

### 5.2 Check 63 — `graphify-out/` is never tracked (measure-then-bound)

**Measure first (the guard's matching logic against current state).** `git ls-files graphify-out/`
→ 0 rows at HEAD (EE-5). Nothing to strip; the legitimate tracked-graph-artifact set is EMPTY → no
allowlist constant is needed. The guard runs CLEAN against current AND projected-post-`.gitignore`
state. This satisfies `ci-guard-measure-then-bound` (allowlist sized to exactly zero).

**O(1) cost (ci-check-runtime-compounding).** Check 63 = a SINGLE `git ls-files graphify-out/`
subprocess — no tree scan, no per-entry subprocess storm. Across the validate-pack battery (the
codebase's own per-invocation figure varies — comments say 151× / ~155× / ~202× at different lines, so
the exact multiplier is illustrative; N-3) the cost is ~0 regardless. The whole-battery O(1) argument
holds at any of those figures.

**Function contract (the coder writes the body; this is the spec):**
- Banner: `── Check 63: graphify-out/ is never tracked (BD-225) ──`.
- Resolve the git root via `subprocess.run([...], cwd=mod.REPO_ROOT, ...)` and make `REPO_ROOT`
  overridable so the per-check test can monkeypatch `mod.REPO_ROOT` to a `/tmp` repo (N-4 — mirror the
  Check 62 test's technique; the function MUST read its root from the module-level `REPO_ROOT`, not an
  implicit cwd, or the synthetic FAIL test cannot point it at a tmp repo).
- Run `git ls-files graphify-out/`. Empty stdout → `ok("Check 63 — graphify-out/ is not tracked
  (gitignored build artifact; 0 tracked paths).")`. Any path returned → `fail(...)` naming the tracked
  path(s) + remediation: `git rm -r --cached graphify-out/` and confirm `.gitignore` carries
  `graphify-out/`.
- Lenient ONLY if `git` itself is unavailable (mirror Check 62's lenient-skip); never swallow a real
  "tracked path found" failure.

### 5.3 Enumerate-encoding-surfaces: Check 63 ships in LOCKSTEP (four surfaces, one commit)

A check is not done until every surface that ENCODES its existence is updated together
(`enumerate-encoding-surfaces`). For Check 63 those are exactly four, all in one commit:

1. **Validator** — `check_graphify_out_never_tracked` in `scripts/validate-pack.py` (§5.2 contract).
2. **Registry registration** — append, as the LAST entry of `_build_check_registry()` (after the
   Check 62 entry — currently at `scripts/validate-pack.py:9992` — and before the closing `]`):
   `(63, "check_graphify_out_never_tracked", check_graphify_out_never_tracked, W)`, with a short
   comment mirroring the adjacent CI-infra guards (58/59/60/61/62). Cite the insertion point by
   CONTENT (*"the last entry of `_build_check_registry()`, after the Check 62 entry"*), not a line
   number — line numbers drift (N-1).
3. **Count-constant bump** — `CHECK_REGISTRY_EXPECTED_COUNT` 60 → 61 (currently
   `scripts/validate-pack.py:492`), AND extend the running-tally comment block immediately above the
   constant (cite it by content — *"the `CHECK_REGISTRY_EXPECTED_COUNT` comment block just above the
   constant"*, the block ranges ~475-492; the plan's "477-486/477-491" citations were both imprecise —
   N-1) with one line: `# + 1 net-new BD-225 check (63 graphify-out-never-tracked guard).`. The comment
   is documentation only — Check 59 computes the real count from `len(_build_check_registry())` and
   asserts equality — but the lock-step comment update keeps the tally honest.
4. **Per-check test** — `scripts/tests/test-validate-pack-check-63.sh` (§5.4).

**Registry ENTRY count vs check NUMBER are different quantities (N-2).** The new ENTRY makes the
registry 60 → **61 entries**; the new check NUMBER is **63**. These are independent: the registry
currently holds 60 entries = 55 distinct numbered checks + 2 `None`-numbered entries + duplicate
registrations of numbers 16/18/19 (each registered twice) — measured (EE-13). So "highest Check N = 62
→ next number = 63" and "entry count 60 → 61" are two separate facts, not one chain; do not infer that
63 entries exist.

### 5.4 Per-check test `scripts/tests/test-validate-pack-check-63.sh` (model: the Check 62 test)

Auto-wires into CI via the disk glob — the `plan` job derives the `tests` matrix from
`scripts/tests/*.sh` (Check 42, post-BD-219 redesign), so committing the file is the only wiring
needed; no allowlist/matrix edit. Required groups:
- **Group 0 — import + registration:** assert `mod.check_graphify_out_never_tracked` exists; `63 in
  [t[0] for t in mod._build_check_registry()]`; `len(mod._build_check_registry()) ==
  mod.CHECK_REGISTRY_EXPECTED_COUNT` (Check 59's invariant — proves the count bump is consistent).
- **Group 1 — real-state-at-HEAD PASS:** call the check against the real tree; expect 0 failures + the
  "not tracked" PASS message (the real tree has no tracked `graphify-out/`).
- **Group 2 — synthetic PASS/FAIL against a `/tmp` repo (test-infra-self-provisioned):** `git init` a
  throwaway repo in `mktemp -d`; (T1 PASS) no `graphify-out/` → 0 failures; (T2 FAIL)
  `mkdir graphify-out && echo x > graphify-out/graph.json && git add -A` then monkeypatch
  `mod.REPO_ROOT` to the tmp repo (N-4) → expect ≥1 failure naming the tracked path. `rm -rf` the tmp
  repo; NEVER mutate the real tree.
- **Group 3 — end-to-end:** `python3 scripts/validate-pack.py --only-check 63` exits 0 and prints the
  banner + clean message on HEAD.
Header must state the test is NOT fixture-dependent (writes only a `/tmp` REPO_ROOT) so it stays under
`scripts/tests/` (not `fixture-dependent/`).

### 5.5 README "invoked checks" count — fix BOTH instances to the measured number (S-1)

Check 63 increments the check inventory the README describes in TWO places (S-1): the version-table row
(`README.md:60`) and the layout line (`README.md:190`) — BOTH carry the string "48 invoked checks"
(EE-14). That string is NOT CI-gated (no check reads it; `check_readme_version`/Check 4 validates only
the version TABLE — EE-14), so it does not break CI. But it is ALREADY badly stale (it says "48" while
the registry holds 60 entries / 55 distinct numbered checks today — measure-then-bound says fix it to
the empirically-correct figure, not "increment 48 by one"). **Measured correct figure (EE-13):** today
55 distinct numbered checks; after Check 63, **56 distinct numbered checks**. The design's call:
**fix BOTH README instances in the same commit as Check 63** to the measured post-Check-63 figure (56
distinct numbered checks; the surrounding "Check 1-11, 16-23, 25-..." enumeration extends to ...63),
because Check 63 is the change that touches this surface and `enumerate-encoding-surfaces` requires
updating every encoding surface in lock-step. Both instances are named so neither is silently left
stale. (If the user prefers to defer the broader pre-existing README staleness, the defer must name
BOTH instances and a tracked anchor — but the design recommends fix-now since the edit is two lines and
the change is what worsened the drift.)

---

## 6. Graph-first rule: pack-root trinity + the B-1 rationale bijection (B-1→Option1, D7, D9)

### 6.1 Home + boundary

The graph-first rule lives in the **pack-root trinity** (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` at
repo root), appended as the LAST bullet of `### Repo conventions` — between the
`dependency-direction-placement` bullet (ends CLAUDE.md:595 / AGENTS.md:554 / GEMINI.md:531) and the
`### Project goals (v11)` header (CLAUDE.md:597 / AGENTS.md:556 / GEMINI.md:533) — in ALL THREE files in
the SAME commit (trinity rule). Targeted append (`edit-in-place`), not a rewrite. NEVER in
`project-template/` (boundary; EE-2). Pack-root `CLAUDE.md` auto-loads into Claude subagents, so a
single bullet reaches every Claude pack agent (the Codex/Antigravity effectiveness question is
BD-233 — §6.5). Hand-authored, NOT via `graphify claude install` (D7): that command writes only
CLAUDE.md (breaking trinity symmetry) AND a PreToolUse hook the pack does not want — confirmed it
exists and does both (EE-3). No PreToolUse hook.

### 6.2 B-1 → Option 1 (LOCKED): tagged pack-memory rule + matching rationale section

The rule is a TAGGED pack-memory rule carrying `[roles: universal] [rationale: graph-first-context]`,
AND a matching `## graph-first-context` section is ADDED to `pack-ops/PACK-MEMORY-RATIONALE.md` in the
SAME commit. This is **Option 1** (keep it a tagged rule) — NOT Option B (drop the tag).

**This is the BLOCKER the adversarial review caught (B-1).** Check 45 enforces a 1:1 bijection between
the `[rationale: <slug>]` slugs in CLAUDE.md `## Pack memory` and the `## <slug>` headings in
`PACK-MEMORY-RATIONALE.md` — set-equality in BOTH directions; an orphan corpus slug (a tag with no
matching section) is a hard FAIL (EE-15). Baseline is **22 ↔ 22, green** (EE-15). Adding
`[rationale: graph-first-context]` to the corpus WITHOUT the matching section makes it the 23rd orphan
corpus slug → Check 45 FAILS → the whole `validate-pack.py` run exits non-zero → CI-RED. **Mandatory
fix:** the `## graph-first-context` section lands in `PACK-MEMORY-RATIONALE.md` in the SAME commit as
the trinity tag, taking the bijection to 23 ↔ 23. Verification for that commit MUST include
`--only-check 45` (the prior plan's C3 verification omitted it — collateral B-1).

**The `## graph-first-context` rationale section** (mirror the existing sections' shape — Why +
How-to-apply-worked-example + rejected-alternatives, e.g. `## dependency-direction-placement` and
`## cross-cli-reference-normalization`). Content the coder authors:
- **Why:** the pack is doc/reference/agent-heavy; agents re-read the file tree for context, which is
  token-expensive. A compact subgraph answers orientation/relationship/blast-radius questions at ~0
  tokens (deterministic local CLI, no LLM). Graph-first is the token-efficiency win BD-225 buys.
- **How to apply:** when `graphify-out/graph.json` exists, query the graph FIRST for "what relates to
  X / where does Y live / blast radius of Z" questions before broad tree reads; fall through to
  grep/Read for the §6.4 exceptions; if the graph is absent or a query fails, use normal tools (the G1
  guard + G2 fallback). Worked example: to scope which files a coder needs, Pack Chat runs `graphify
  query`/`affected` and names those exact files in the prompt instead of "read the tree."
- **Rejected alternatives:** (a) Option B untagged convention bullet — rejected because the rule is a
  spawn-relevant `[roles: universal]` rule and the tagged form gives it a discoverable rationale
  pointer; (b) `graphify claude install`'s auto-written CLAUDE.md section — rejected (trinity-asymmetric
  + surprise PreToolUse hook, D7); (c) per-agent-frontmatter enablement — unnecessary, all 5 agents
  already carry `Bash` (research EE-6).

The slug `graph-first-context` is unique against the current 22-slug set (none collides — EE-15) and
matches the controlled kebab-case vocab the Check 45 slug regex requires (`^##\s+([a-z0-9][a-z0-9-]*)`).

### 6.3 The CORE rule substance (identical across the trinity; D9 parity)

Every CLI file carries this CORE meaning (the imperative line + tag in `### Repo conventions`):
- **G1 guard FIRST:** *"If `$(git rev-parse --show-toplevel)/graphify-out/graph.json` exists, prefer
  the graph for orientation / relationship / blast-radius / 'what relates to X' / 'where does Y live'
  questions (query ~0 tokens) before broad tree reads; otherwise use normal grep/Read."*
- **G2 fallback:** *"If a graph query errors or returns nothing useful, fall back to file reads — never
  block on the graph."*
- **Exceptions (fall through to grep/Read):** exact-string/token search → grep; authoritative SSOT
  fields (a BD `Status`, the README version table, a `_rules.md` contract) → Read the source;
  freshly-changed/uncommitted files → `git diff`/Read; whole-file exact content (editing, verbatim
  quoting) → Read; archive-dir / excluded-category content → Read/grep (not in the graph). (§6.4.)
- **Absolute `--graph` always** for agents/hooks (a sub-agent may start in a different cwd).
- **Budgets:** `--budget 2000` human/interactive; `1500` spawned agent; `1000` Pack-Chat
  prompt-construction (distilled into a prompt, so tighter).
- **Role phrasing (one optional line):** reviewer → `affected` (blast radius); architect →
  `path`/`explain` (structure); coder / docs-researcher → `query` then open only cited files.
- **Never preload the graphify skill** via an agent's `skills:` frontmatter (~32KB, build-oriented; the
  query CLI needs no skill). Querying needs `Bash` only — all 5 pack agents already have it (research
  EE-6), so NO `tools:` change.
- **Querying is read-only / deterministic / ~0 tokens; only BUILDING/refreshing the doc layer costs
  subscription** — agents QUERY, they never BUILD (build is a main-session/orchestrator job, §7).
- **Boundary note:** the graph indexes the whole repo incl. `project-template/`; consuming it to answer
  a deliverable question is fine — the RULE and SETUP stay pack-side.

### 6.4 The "better tool" exceptions (graph-first UNLESS a better tool fits)

| Exception | Use instead | Why |
|---|---|---|
| Exact-string / token search (a literal symbol, a CI check number, a commit keyword) | `grep`/`Grep` | The graph matcher is case-folded substring + IDF, no exact-anchor guarantee (research §1.10); grep is exact + complete. |
| Authoritative SSOT fields (a BD `Status`, README version table, a `_rules.md` contract) | `Read` the source | The graph is a compressed, possibly-lagging view; SSOT fields must come from source. |
| Freshly-changed / uncommitted files | `git diff` / `Read` | The graph reflects the last refresh, not the working tree. |
| Whole-file exact content (applying an edit, verbatim quote) | `Read` | The graph returns subgraphs, not file bytes. |
| Archive-dir / excluded-category content (§4) | `Read`/`grep` | Deliberately not in the graph. |
| Cross-file structure / "what relates to X" / blast radius / "where does Y live" | **graph (default)** | The graph's strength (`query`/`path`/`affected`) at ~0 tokens — the BD-225 win. |

### 6.5 Per-CLI normalization (D9 — identical CORE, invocation normalized, NOT byte-copied)

Per `cross-cli-reference-normalization`: the CORE substance above is identical in all three files; only
the CLI-specific invocation phrasing differs per audience (EE-16):
- **CLAUDE.md** — the Claude session/skill auto-route + Claude subagents inheriting pack-root
  `CLAUDE.md`; pack agents via `claude --agent pack-<name>` / the Agent tool.
- **AGENTS.md** — Codex audience; pack agents via `codex --agent pack-<name>`; states the rule applies
  the same way and that cross-CLI EFFECTIVENESS (does a Codex agent actually consume this AGENTS.md
  rule at spawn) is verified separately under **BD-233** — the rule ships here for parity; it is inert
  text where unconsumed.
- **GEMINI.md** — Antigravity audience; pack agents via the Antigravity plugin/subagent mechanism
  (`agy` + bundled `pack-<name>`); same BD-233 cross-CLI-effectiveness caveat.
The `[roles: universal] [rationale: graph-first-context]` tag appears on the imperative line in all
three (trinity-parity is separately enforced by Checks 16/18/19; the rationale-bijection is corpus-side
only via CLAUDE.md, Check 45 — §6.2). BD-233 is Deferred (post-v11.0); this design ships only the
parity text, NOT the cross-CLI effectiveness work (D9).

---

## 7. Maintenance: the post-commit hook (D4, D5) — doc-gated refresh + the M-3 force resolution

The maintenance mechanism is a **doc-gated semantic refresh + force-on-removal, backgrounded
post-commit, with `check-update` as a safety net** (D5, LOCKED). It is a per-clone, hand-installed
`.git/hooks/post-commit` (git does not version `.git/hooks`), documented as a runbook STEP in
`pack-ops/OPTIONAL-FEATURES.md`, never a committed file. Cost is confirmed later by BD-234; this design
does NOT change the cadence direction (D5).

### 7.1 The hook fires on the orchestrator's MAIN-tree commit (D4)

Only Pack Chat (the orchestrator) commits (`agents-never-commit`); agents never trigger the hook. The
hook fires on the orchestrator's MAIN-tree commit. TWO coder-VERIFY items remain (D4 — empirically
resolvable at implementation, NOT design-blocking):
- **D4(a) — hook fires under worktree-isolation.** Under the BD-226/197 worktree flow the orchestrator
  applies the agent's patch and commits in the MAIN (parent) tree. A git worktree shares the parent's
  `.git` common dir, so `.git/hooks/post-commit` SHOULD fire from the common dir on the main-tree
  commit — but the coder MUST VERIFY empirically, and confirm the doc-gate's
  `git diff --name-only HEAD~1 HEAD` resolves against the committed ref. Cross-reference the existing
  OPTIONAL-FEATURES.md § "Claude Code — Isolated parallel agents (worktree isolation)" (line 111+).
- **D4(b) — backgrounded-refresh vs in-flight agent-query overlap safety.** Verify a backgrounded
  refresh overlapping an agent's in-flight graph QUERY is safe. Graphify keeps an auto-backup
  (`GRAPHIFY_NO_BACKUP` left at default 0) and writes via a tmp-then-replace path (`watch.py` writes a
  `graph_tmp` then swaps — observed in source, EE-10); a concurrent reader sees either the old or the
  new `graph.json`, not a torn file. Confirm the atomic-swap on the installed 0.8.39 write path before
  declaring the hook safe. (Until both are verified, the runbook's automated hook is "install + VERIFY
  before relying"; the manual doc-gated refresh is the safe fallback.)

### 7.2 The G3 hook template (guarded + non-blocking — net-new)

The runbook documents this exact shape (hand-installed at `.git/hooks/post-commit`, `chmod +x`):

```
#!/usr/bin/env bash
# graphify post-commit refresh (BD-225) — GUARDED + NON-BLOCKING. Never blocks a commit.
GFX="$(command -v graphify)"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
GRAPH="$ROOT/graphify-out/graph.json"
# G3 guard: silent no-op if graphify is missing or the graph was never built.
[ -x "$GFX" ] && [ -f "$GRAPH" ] || exit 0
# §8 key-assert: refuse the paid auto-route; run the refresh in a key-clean subshell.
(
  unset GEMINI_API_KEY GOOGLE_API_KEY OPENAI_API_KEY
  # Doc-gate: did this commit change a doc-layer file (.md/.pdf/comment-bearing code)?
  if git diff --name-only HEAD~1 HEAD | grep -Eq '\.(md|pdf)$'; then
    # Semantic branch (subscription, serial). NO --no-viz (extract has no such flag, M-2).
    GRAPHIFY_CLAUDE_CLI_PARALLEL=0 graphify extract . --backend claude-cli >/dev/null 2>&1 &
  else
    # Free code-only branch. Force-on-removal binds HERE (M-3): GRAPHIFY_FORCE on a removal commit.
    if git diff --name-only --diff-filter=D HEAD~1 HEAD | grep -q .; then
      GRAPHIFY_FORCE=1 graphify update . >/dev/null 2>&1 &
    else
      graphify update . >/dev/null 2>&1 &
    fi
  fi
) >/dev/null 2>&1
exit 0   # always succeed — a refresh problem must never break the commit (G3)
```

(The doc-gate predicate above is a minimal illustrative form — the coder may refine the doc-layer
detection, e.g. comment-bearing code, per D4(a)'s committed-ref resolution. The LOAD-BEARING shape is:
guard → key-clean subshell → doc-gate split → background → unconditional `exit 0`.)

### 7.3 M-3 RESOLVED — `GRAPHIFY_FORCE=1` binds to `update`, NOT `extract` (source-verified)

The adversarial review (M-3) flagged that the prior design did not say WHICH refresh command carries
`GRAPHIFY_FORCE=1` on a removal/archive commit. Resolved by source inspection of the installed 0.8.39
(do NOT punt to coder-verify):

- The shrink-rejection guard lives in `watch.py:_check_shrink` (EE-10) for the **`update`** path. It
  RETURNS-OK (skips the guard) when `force OR not existing_data OR had_explicit_deletions` is true.
- `GRAPHIFY_FORCE` / `--force` is read ONLY by the **`update`** command handler
  (`__main__.py:3294-3295`, EE-9) and is fed into `_check_shrink` as `force`.
- **`extract` does NOT read `GRAPHIFY_FORCE`** (EE-10): its incremental path calls
  `build_merge(..., prune_sources=deleted_files or None, dedup=True, ...)`, and the `build.py:482`
  shrink-guard is explicitly SKIPPED when `prune_sources` (or `dedup`) is active
  (`if graph_path.exists() and not dedup and not prune_sources:` — EE-10). `extract` then writes with
  `_to_json(..., force=True)` unconditionally. So `extract` handles removals natively via
  `prune_sources` and NEVER needs `GRAPHIFY_FORCE`.

**Design conclusion:** on a removal/archive commit, `GRAPHIFY_FORCE=1` belongs to the **`update`
(code-only) branch** of the doc-gate as a belt-and-suspenders safety net. Note `_check_shrink`
auto-skips when it detects explicit deletions (`had_explicit_deletions`), so on a clean
git-detected-deletion commit the flag is often unnecessary — but setting it on a removal commit is
harmless and defends the case where the deletion is not auto-detected (e.g. a non-git scan-root
removal, or a false-positive shrink from a failed prior run). On the **`extract` (semantic) branch**
`GRAPHIFY_FORCE` is a no-op (extract ignores it and prunes natively), so it is NOT set there — and that
also keeps the hook from implying `extract` honors a flag it does not read. This is encoded in the §7.2
template (force only on the `update` removal sub-branch).

### 7.4 Initial build + irreducible manual points (D6, D7)

The first `/graphify .` is a one-time interactive main-session job. The corpus trips BOTH narrow-gates
(1,373 indexable files > 500; ~2.65M `.md` words > 2,000,000 — research EE-1/EE-7), so the build is
interactive and cannot be fully automated. The irreducible manual/permission points (documented in the
runbook):
1. **Narrow-gate decision:** run interactive `/graphify .`; it warns + asks which subfolder to narrow
   to → answer **"proceed whole-repo"** (D6 "start big"); `--no-viz` ON, clustering ON.
2. **First headless `claude -p` permission:** the auto-mode classifier may prompt the first time the
   post-commit semantic hook runs headless — confirm once per machine.
3. **Classifier refusal = correct safety stop:** if it refuses, investigate (do NOT auto-override) —
   §8/D3.
4. **Per-clone / per-machine install:** `graphify-out/`, the post-commit hook, and the global graph do
   not sync; each machine builds its own (cannot be committed — gitignored + `.git/hooks` per-clone).
5. **Env-key hygiene:** one-time confirm `GEMINI_API_KEY`/`GOOGLE_API_KEY`/`OPENAI_API_KEY` unset.
The initial build produces `graphify-out/cost.json` (the measured token-cost tracker) — the input
**BD-234** consumes to confirm/adjust cadence + knobs + scope after burn-in. The runbook states:
cadence direction is LOCKED for now (D5); BD-234 re-tunes with measured numbers — do NOT change cadence
here.

---

## 8. Backend / secrets guards (Core, D3) — authored NOW in OPTIONAL-FEATURES.md

A new `## Graphify — knowledge-graph context (pack-dev)` section is appended to
`pack-ops/OPTIONAL-FEATURES.md` following the file's documented entry shape (Status / What it is / When
it matters / How to enable / How to use / Caveats / When to skip — lines 312+; targeted append,
`edit-in-place`). It carries D3 (privacy), D4/D5 (the hook runbook), the §7.4 initial-build runbook,
and the §1.1 `claude-cli` caveat. The privacy/secrets content (D3, authored NOW):
- The semantic pass sends NON-CODE text (docs/PDFs/comments) to the model; the AST/code pass is 100%
  local and never leaves the machine (research §1.2/§1.10).
- The auto-mode classifier may REFUSE on a secrets-adjacent repo — a CORRECT SAFETY STOP, not a bug;
  investigate, do NOT blindly override (research §1.10).
- This repo is less secrets-adjacent than dotfiles (only synthetic fixtures + `.example` files); the
  `.graphifyignore` excludes all `.env` (D2) + `.mcp.json` + `.claude/settings.local.json`, removing
  the secrets-shaped semantic-pass inputs (§4.3).
- **Backend = Claude subscription ONLY (`--backend claude-cli`)** with the §1.1 stale-enum caveat. The
  auto-route foot-gun: if `GEMINI_API_KEY`/`GOOGLE_API_KEY`/`OPENAI_API_KEY` is set, graphify routes
  the semantic pass to that PAID API (research §1.9) — so the hook unsets them in its own subshell
  (§7.2) AND `--backend claude-cli` is always explicit (defense-in-depth). The assert is designed
  against the documented complete auto-route variable set (the three named keys); I did NOT inspect the
  live shell env (a read-only architect must not surface a secret).
- Ignore the SKILL.md "set `GEMINI_API_KEY`" tip — subscription-only by policy. No API key anywhere in
  pack config. **No Ollama** — a working no-key alternative (`claude-cli`) exists, so the "no Ollama
  unless no alternative" condition is not triggered. **No neo4j/falkordb/video extras** — absent on
  this machine (research EE-11); any such export would `ModuleNotFoundError`; out of scope.

---

## 9. Delete the stale 2026-05-11 graphify research docs + fix ALL dangling refs (D10, M-1)

### 9.1 Delete entirely — no banner, no archive (fail-loud)

Delete the three docs whose posture (Graphify as a CLIENT feature deferred to v12, against an older
version) BD-225 reverses (pack-side, v11.0) — research §5.3 A-13, EE-10-old:
- `maintenance-docs/v11-research/RESEARCH-GRAPHIFY-EXTERNAL.md`
- `maintenance-docs/v11-research/RESEARCH-GRAPHIFY-PACK-INTEGRATION.md`
- `maintenance-docs/v11-research/RESEARCH-GRAPHIFY-SYNTHESIS.md`

D10 LOCKS delete (the prior design's superseding-banner recommendation is overridden). The new
`RESEARCH-BD-225-GRAPHIFY-INCLUSION.md` census + THIS design supersede them; their external-research
evidence is recoverable from git history. **The deletion is a destructive op** — the coder does NOT run
`git rm` (`agents-never-commit`) and does NOT `rm` on its own authority; it surfaces the three paths in
its IMPL-REPORT and the ORCHESTRATOR performs the deletion with explicit user approval at commit time.

### 9.2 The cross-reference census is 4 archive files, not 3 (M-1 — name BD-149)

The reference set to the doomed docs splits into four categories (re-measured, EE-17):
- **(a) Self-refs** in the 3 docs being deleted — moot (deleted).
- **(b) `maintenance-docs/archive/v11/*` — FOUR files, not three (M-1).** The prior census named only
  3 (ARCHITECTURE-PER-ENTRY-FLAT-FILES.md, IMPLEMENTATION-REPORT-BD-146.md,
  PACK-REVIEW-ARCHITECTURE-PER-ENTRY.md). The FOURTH is
  **`maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-149.md`** (the same `??`-snapshot pattern).
  All FOUR are under an `archive/` dir → D1-excluded from the graph AND frozen historical snapshots →
  left UNTOUCHED (fail-loud targets LIVE forward-pointing surfaces, not archived snapshots). The
  disposition is unchanged from the plan; the COUNT is corrected to 4 and BD-149 is named.
- **(c) `??`-snapshot lines** in historical reports (IMPLEMENTATION-REPORT-BD-120/150.md,
  PACK-REVIEW-BD-120.md) — verbatim `git status --short` output (the `??` untracked marker), not
  cross-references; editing them would falsify a historical record → left UNTOUCHED.
- **(d) THREE LIVE refs (fix ALL — fail-loud, zero dangling):**
  - `maintenance-docs/v11-research/RESEARCH-CLAUDE-REPOS-SURVEY.md:271` — "Graphify (deferred to v12
    per RESEARCH-GRAPHIFY-SYNTHESIS.md) indexes structural code relationships" → repoint to BD-225:
    "Graphify (wired pack-side in v11.0 per BD-225 / `DESIGN-BD-225-GRAPHIFY-PACK-INTEGRATION.md`)
    indexes structural code relationships". Preserve the surrounding coexistence prose.
  - `maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-GROUPINGS-V2.md:128` — "Graphify is explicitly
    deferred to v12 per `RESEARCH-GRAPHIFY-SYNTHESIS.md`" → replace the deferral claim + dead path with
    the BD-225 fact (Graphify landed pack-side v11.0; still orthogonal to groupings' timeline).
  - `maintenance-docs/v11-research/V11.1-DISCUSSION-GITHUB-PROJECTS.md:338` —
    "`RESEARCH-GRAPHIFY-SYNTHESIS.md` — explicitly defers Graphify to v12" → replace with the BD-225
    pack-side-v11.0 reference; keep the "different timeline/scope from groupings" point.
  Targeted in-place edits; each re-reads the line's context first.

### 9.3 Completeness gate (no dangling refs anywhere)

After deletion + the 3 live fixes, the gate is:
`git grep -nE "RESEARCH-GRAPHIFY-(EXTERNAL|PACK-INTEGRATION|SYNTHESIS)"` returns ONLY: the
RESEARCH-BD-225/this-design self-references, the 4 untouched archive files (category b), and the
`??`-snapshot historical-verbatim lines (category c) — ZERO remaining LIVE dangling refs. (No CI gate
covers maintenance-docs cross-refs — Check 34 walks only the per-entry stream trees — so this is a
fail-loud correctness gate, not a CI assertion; the coder PREFLIGHT + reviewer enforce it.)

---

## 10. Opt-in / degradation summary + the full surface enumeration

### 10.1 The feature is BOTH opt-in AND graceful-on-failure

| Property | How the design guarantees it |
|---|---|
| Opt-in | Graph + hook + initial build are per-clone, manual, gitignored — a maintainer who does nothing gets today's behavior. Only the committed scaffolding (ignore-list, rule, guard, runbook) lands. |
| Degrades on no-graph | G1 existence guard in the trinity rule → graphless clone (the DEFAULT) uses normal grep/Read with zero friction (§2.1). |
| Degrades on query failure | G2 fallback in the rule → a failed/empty query falls back to file reads (§2.2). |
| Degrades on broken install | G3 guarded + non-blocking hook → silent no-op if graphify/the graph is absent; always `exit 0` (§2.3, §7.2). |
| Client-unaffected | Boundary: nothing graphify ships; no `project-template/` touch; rule pack-root only (§2.4, EE-2). |

### 10.2 Every surface the design touches (enumerate-encoding-surfaces)

| # | Surface | Change | Encoding-lockstep notes |
|---|---|---|---|
| F-1 | `.graphifyignore` (root, NEW) | D1/D2/D6 content (§4.3) | fnmatch-validated (§4.4). |
| F-2 | `.gitignore` (append) | `graphify-out/` block (§5.1) | pairs with Check 63. |
| F-3 | `scripts/validate-pack.py` | Check 63 fn + registry entry + count 60→61 + comment (§5.2/§5.3) | FOUR-surface lockstep with F-4; manifest INPUT → push-time manifest-sync (orchestrator). |
| F-4 | `scripts/tests/test-validate-pack-check-63.sh` (NEW) | per-check test (§5.4) | auto-wires via disk glob (Check 42). |
| F-5/6/7 | `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` (pack-root trinity) | graph-first bullet + `[roles: universal][rationale: graph-first-context]` (§6) | trinity-parity (Checks 16/18/19); **REQUIRES F-8 in the same commit (Check 45)**. |
| F-8 | `pack-ops/PACK-MEMORY-RATIONALE.md` | NEW `## graph-first-context` section (§6.2) | the B-1 fix — Check 45 bijection 22↔22 → 23↔23; verify with `--only-check 45`. |
| F-9 | `pack-ops/OPTIONAL-FEATURES.md` | NEW Graphify section: D3 privacy + D4/D5 hook runbook + §7.4 build runbook + §1.1 caveat (§8) | prose; Check 40 bare-cross-ref scanner must stay green. |
| F-10/11/12 | the 3 stale graphify research docs | DELETE (§9.1) | orchestrator-executed destructive op. |
| F-13/14/15 | the 3 LIVE dangling-ref docs (§9.2(d)) | targeted ref fixes | fail-loud gate §9.3. |
| F-16/17 | `README.md:60` + `README.md:190` | "invoked checks" count → 56 distinct numbered (§5.5) | NOT CI-gated; fix both in the Check-63 commit. |
| — | `backlog/BD-225.md` + `backlog/_toc.md` | Status flip at batch completion | Pack-Chat-direct bookkeeping (not an architect/coder edit). |

**Surfaces deliberately NOT touched (with reasons):** `supporting-docs/DEPENDENCIES.md` — client-facing
deliverable; graphify is pack-dev-only; recording it there is a boundary leak (the pack-dev home is
OPTIONAL-FEATURES.md). `pack-ops/.spawn-rule-manifest.txt` (Check 46) — records ONLY rules with
COLLAPSED restatements in PACK-AGENTS.md/PACK-CHAT.md; the new graph-first rule is a fresh
`### Repo conventions` rule with NO such restatement, so it needs NO manifest record and Check 46 does
not require one (Check 46 iterates the records present, not every corpus slug — verified, EE-18).
`pack-ops/PACK-AGENTS.md` — no parallel touch needed for the same reason (S-2; the new rule introduces
no reference-surface restatement). `test-fixtures/manifest.txt` — reconciled at push by
`manifest-sync.sh` (F-3 is a fixture input), NOT a per-commit propagation step (BD-228).

---

## 11. The dropped MEMORY.md step + the BD-232 flag (S-2 — HARD)

### 11.1 NO MEMORY.md pointer (HARD user directive — encoded by OMISSION)

The new `[roles: universal]` rule is a spawn-relevant rule. The adversarial review (S-2) and the
PACK-CHAT.md propagation procedure both reference an out-of-repo MEMORY.md index pointer. **This design
prescribes NO addition to MEMORY.md.** The rule lives ONLY in the in-repo corpus (the trinity
`## Pack memory` imperative line + the `## graph-first-context` rationale section in
`PACK-MEMORY-RATIONALE.md`). Any input doc that suggests a MEMORY.md pointer is OMITTED here per the
hard user directive — the MEMORY.md half of S-2 is DROPPED.

### 11.2 The propagation procedure mandates a MEMORY.md step — FLAG for BD-232 (do NOT patch here)

The PACK-CHAT.md propagation procedure ("Keeping CLAUDE.md, AGENTS.md, GEMINI.md, and PACK-AGENTS.md
current" → "Rule-change propagation procedure") lists, as **Step 3**, *"Thin memory-cache pointer
(out-of-repo) — Pack-Chat upkeep; trinity-wins (no validator gate)"* (EE-19). That Step 3 IS a
MEMORY.md update step. It DIRECTLY CONTRADICTS the hard NO-MEMORY.md directive in force for this work.

**Per S-2 and the HARD rule: this design does NOT patch PACK-CHAT.md and does NOT add a MEMORY.md
pointer.** It FLAGS the contradiction as a stale-procedure item for **BD-232** to reconcile: the
propagation procedure's Step 3 (out-of-repo memory-cache pointer) is at odds with the current
NO-MEMORY.md posture and should be revisited there. This design simply does NOT execute Step 3.

**On the rest of the propagation procedure:** Steps 1 (corpus ×3 trinity) and 2
(`PACK-MEMORY-RATIONALE.md` `## <slug>`) ARE executed by this design (§6) and are the CI-gated half
(trinity-parity + Check 45 bijection). Step 4 (reference surfaces) and Step 5 (`.spawn-rule-manifest.txt`)
are N/A — the new rule has no collapsed restatement, so no reference surface and no manifest record
(§10.2, EE-18). The only procedure step this design declines is Step 3 (the MEMORY.md step), per the
hard directive — flagged for BD-232.

### 11.3 Roles-scope note (S-2 secondary)

The rule carries `[roles: universal]` per B-1's locked tag form. `universal` means it is enumerated
into EVERY agent spawn's "Rules in force" block (`enumerate-rules-inline`). For an OPT-IN pack-dev
feature this is heavier than strictly necessary on a graphless clone — but the G1 existence guard
makes the rule a no-op there, and `universal` is the locked tag (B-1 → Option 1 with the exact tag
`[roles: universal] [rationale: graph-first-context]`). The design encodes `universal` as locked; the
G1 guard neutralizes the "always enumerated even when no graph" cost.

---

## 12. Empirical-Evidence Blocks (every state-claim + every command-validation)

> All measurements read-only at HEAD `0a90f56ddfd8ec10216ac40012b831adb4b6e050`, branch `v11-dev`,
> 2026-06-18. graphify probes ran in throwaway `/tmp` git repos (`/tmp/gfx-probe-225`,
> `/tmp/gfx-ignore-225`), each `rm -rf`'d after. NO graph was built/indexed in the pack repo; NO
> `.graphify*` file written into the pack repo; NO pack file mutated except this design doc. Evidence
> re-measured here, not cited from prior docs.

**EE-1 — installed binary.** `graphify --version` → `graphify 0.8.39`; `which graphify` →
`/Users/david/.local/bin/graphify`. **Interpretation:** target binary confirmed. **SUPPORTED.**

**EE-2 — boundary is clean; output target.** `git grep -in graphify -- 'project-template/'` → empty
(exit 0, no rows). `find . -name "DESIGN-BD-225-GRAPHIFY-PACK-INTEGRATION.md" -not -path './.git/*'` →
`./maintenance-docs/v11-implementation/DESIGN-BD-225-GRAPHIFY-PACK-INTEGRATION.md` (the overwrite
target). **Interpretation:** no graphify ref in `project-template/`; the rewrite supersedes the named
existing doc. **SUPPORTED.**

**EE-3 — top-level `graphify --help` surface (verbatim, abridged to load-bearing lines).**
```
update <path>   re-extract code files and update the graph (no LLM needed)
  --force         overwrite graph.json even if the rebuild has fewer nodes
                  (also: GRAPHIFY_FORCE=1 env var; use after refactors that delete code)
  --no-cluster    skip clustering, write raw extraction only
cluster-only <path>  ...   --no-viz  skip graph.html generation (useful for >5000 node graphs / CI)
extract <path>  headless full extraction (AST + semantic LLM) for CI/scripts
  --backend B     gemini|kimi|claude|openai|deepseek|ollama (default: whichever API key is set)
  --model / --mode deep / --max-workers / --token-budget / --max-concurrency / --api-timeout / --out
  --google-workspace / --no-cluster / --postgres / --cargo / --global / --as
claude install   write graphify section to CLAUDE.md + PreToolUse hook (Claude Code)
```
**Interpretation:** (i) `--no-viz` is a flag of `cluster-only` (and the build/skill path), NOT of
`extract` — confirms M-2: extract's flag list has no `--no-viz`. (ii) `extract --backend` enum lists
`gemini|kimi|claude|openai|deepseek|ollama` — OMITS `claude-cli` (confirms S-3 stale enum). (iii)
`claude install` writes a CLAUDE.md section + a PreToolUse hook — confirms D7's reason to hand-author.
(iv) `update --force` ↔ `GRAPHIFY_FORCE=1` "use after refactors that delete code". **SUPPORTED.**

**EE-4 — accepted backend set + `claude` requires a key (probed in /tmp/gfx-probe-225).**
```
$ graphify extract . --backend bogusxyz
  error: unknown backend 'bogusxyz'. Available: azure, bedrock, claude,
         claude-cli, deepseek, gemini, kimi, ollama, openai
$ env -u ANTHROPIC_API_KEY ... graphify extract . --backend claude
  error: backend 'claude' requires ANTHROPIC_API_KEY to be set.
```
**Interpretation:** `claude-cli` IS a valid backend (in the Available set) though the help enum omits
it; `--backend claude` (the listed value) demands `ANTHROPIC_API_KEY`; `claude-cli` is the no-key
subscription path. Confirms §1.1 / S-3: pin `claude-cli`, never substitute `claude`. **SUPPORTED.**

**EE-5 — `.gitignore` has no graphify-out; `git ls-files graphify-out/` empty; `.gitignore` tail.**
`grep -c graphify-out .gitignore` → `0`. `git ls-files graphify-out/` → 0 rows. `.gitignore` tail =
the BD-119 snapshot block (`scripts/.bd119-pre-refactor-monolith.sh.snapshot`). **Interpretation:**
append point clean; Check 63 measure-then-bound legitimate-set = empty. **SUPPORTED.**

**EE-6 — `graphify update .` is code-only / no-LLM / builds a graph (probed in /tmp/gfx-probe-225).**
```
$ graphify update .
  Re-extracting code files in . (no LLM needed)...
  [graphify watch] Rebuilt: 4 nodes, 2 edges, 2 communities
  [graphify watch] graph.json, graph.html and GRAPH_REPORT.md updated in graphify-out
$ ls graphify-out/   → graph.json (1522 B), GRAPH_REPORT.md, graph.html, cache/, manifest.json, ...
```
**Interpretation:** the FREE deterministic refresh branch works no-LLM. **SUPPORTED.**

**EE-7 — query/path/explain/affected + absolute `--graph` (probed in /tmp/gfx-probe-225).**
```
$ graphify query "hello" --budget 1000
  Traversal: BFS depth=2 | Start: ['hello()'] | 2 nodes found ... EDGE hello() --contains--> a.py
$ graphify explain "hello"   → Node: hello()  ID: a_hello  Source: a.py L1  Community: 0
$ graphify affected "hello" --depth 2   → Affected nodes ... Depth: 2 ... No affected nodes found.
$ graphify path "hello()" "a.py"   → Shortest path (1 hops): hello() <--contains-- a.py
$ graphify query "doc" --graph "$(git rev-parse --show-toplevel)/graphify-out/graph.json" --budget 500
  Traversal: BFS depth=2 | Start: ['Doc'] | 2 nodes found ... EDGE Doc --contains--> b.md
```
**Interpretation:** all four read commands + `--budget` + absolute `--graph` are syntax-valid and
return subgraphs on 0.8.39. **SUPPORTED.**

**EE-8 — `.graphifyignore` matcher is fnmatch; D1/D2 globs validated (probed in /tmp/gfx-ignore-225).**
```
$ grep -n "import fnmatch\|def _load_graphifyignore\|fnmatch.fnmatch" .../graphify/detect.py
  3:import fnmatch ; 734:def _load_graphifyignore(root) ; 801/803/805/808/810: fnmatch.fnmatch(...)
$ python3 -c "... detect._is_ignored(...) ..."   # with the design's .graphifyignore globs
  loaded patterns: ['*[Aa][Rr][Cc][Hh][Ii][Vv][Ee]*', '.env', '.env.*', '**/.env', '**/.env.*']
  IGNORED  maintenance-docs/archive/v11/A.md
  IGNORED  maintenance-docs/v11-research/templates-archive/T.md
  IGNORED  maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-BATCH-ARCHIVE.md
  kept     maintenance-docs/v11-implementation/normal.md
  IGNORED  .env
  IGNORED  .env.local
  IGNORED  scripts/tests/fixtures/proj1/.env
```
**Interpretation:** graphify matches via Python fnmatch (not git pathspec); the D1 archive glob
excludes both archive DIRS and the archive-named FILE while keeping `normal.md`; D2 excludes root +
nested `.env`/`.env.*`. Confirms §4.2/§4.4 + S-4. **SUPPORTED.**

**EE-9 — `GRAPHIFY_FORCE` is read by the `update` command (source).**
```
$ grep -n 'GRAPHIFY_FORCE' .../graphify/__main__.py
  3295:  force = os.environ.get("GRAPHIFY_FORCE","").lower() in ("1","true","yes")
$ # enclosing handler:
  3294:  elif cmd == "update":
```
**Interpretation:** `GRAPHIFY_FORCE`/`--force` belongs to `update`. **SUPPORTED.**

**EE-10 — `extract` does NOT read GRAPHIFY_FORCE; build_merge skips the shrink-guard on prune;
shrink-guard lives in update's `_check_shrink` (source).**
```
$ awk '... extract handler 3930..end ...' __main__.py | grep -c GRAPHIFY_FORCE   → 0
$ sed -n '4462,4471p' __main__.py
  G = _build_merge([merged], graph_path=existing_graph_path,
                   prune_sources=deleted_files or None, dedup=True, ...)
  ... _to_json(G, communities, str(graph_json_path), force=True)
$ sed -n '482,489p' build.py
  if graph_path.exists() and not dedup and not prune_sources:   # shrink-guard SKIPPED when pruning
      if new_n < existing_n: raise ValueError("build_merge would shrink graph from {N}→{M} nodes...")
$ sed -n '339,353p' watch.py    # update path guard
  if force or not existing_data or had_explicit_deletions: return True   # ok to proceed
  if new_n < existing_n: print("WARNING ... Pass --force to override."); return False
```
**Interpretation:** `extract` reads NO `GRAPHIFY_FORCE` and prunes removals natively
(`prune_sources`), with the build.py shrink-guard skipped under prune/dedup and `_to_json(force=True)`.
The shrink-rejection that `GRAPHIFY_FORCE` overrides lives in `update`'s `_check_shrink` (auto-skipped
on `had_explicit_deletions`). Confirms M-3: force binds to `update`, is a no-op on `extract`.
**SUPPORTED.**

**EE-11 — env-key clean-subshell guard (probed).**
```
$ env -u GEMINI_API_KEY -u GOOGLE_API_KEY -u OPENAI_API_KEY bash -c 'for v in ...; do ...; done'
  GEMINI_API_KEY unset / GOOGLE_API_KEY unset / OPENAI_API_KEY unset
```
**Interpretation:** the §7.2/§8 `unset` subshell pattern produces a key-clean env for the refresh.
**SUPPORTED.**

**EE-12 — G3 hook guard + check-update (probed in /tmp/gfx-probe-225).**
```
$ [ -x "$(command -v graphify)" ] && [ -f "$(git rev-parse --show-toplevel)/graphify-out/graph.json" ]
  && echo "guard PASS"   → guard PASS → would run refresh
$ graphify check-update . ; echo $?   → (clean) exit 0
```
**Interpretation:** the guard predicate evaluates correctly and `check-update` exits 0 — the G3
guarded/non-blocking template and the D5 safety-net command both work. **SUPPORTED.**

**EE-13 — registry entry/number counts (computed).**
```
$ python3 (importlib-load validate-pack.py) → len(_build_check_registry()) = 60
  distinct numbered checks = 55 (max 62); None-numbered entries = 2; numbers 16,18,19 each register 2x
  CHECK_REGISTRY_EXPECTED_COUNT = 60
```
**Interpretation:** entry count 60 → 61 after Check 63; distinct numbered checks 55 → 56; check number
63. Confirms §5.3 N-2 (entry count ≠ check number) and §5.5's measured README figure. **SUPPORTED.**

**EE-14 — README "invoked checks" in TWO places; not CI-gated.** `grep -nE "invoked check" README.md`
→ `60:` (version-table row) and `190:` (layout line), BOTH "48 invoked checks". `check_readme_version`
(Check 4) validates the version TABLE only; no check reads the "invoked checks" string. **Interpretation:**
S-1 — Check 63 worsens the count drift in BOTH instances; fix both; not CI-gated. **SUPPORTED.**

**EE-15 — Check 45 bijection 22↔22 green; slug regex; `graph-first-context` absent.**
```
$ python3 scripts/validate-pack.py --only-check 45 | tail -1
  OK: Check 45 — 22 corpus `[rationale: slug]` pointer(s); 22 rationale `## <slug>` section(s);
      sets are equal (bijection holds, no orphans in either direction).
$ grep -c "graph-first-context" pack-ops/PACK-MEMORY-RATIONALE.md CLAUDE.md AGENTS.md GEMINI.md
  all → 0
# Check 45 slug regex (validate-pack.py): ^##\s+([a-z0-9][a-z0-9-]*)\s*$
```
**Interpretation:** baseline 22↔22; adding the corpus tag without the section orphans it → Check 45
FAIL → CI-RED (confirms B-1). The fix (add `## graph-first-context` in the same commit) → 23↔23. The
slug `graph-first-context` is unique vs the 22 existing slugs and matches the kebab-case slug regex.
**SUPPORTED.**

**EE-16 — per-CLI audience + trinity insertion point.** `grep -nE "^### Repo conventions|^### Project
goals" {CLAUDE,AGENTS,GEMINI}.md` → each has `### Repo conventions` then `### Project goals (v11)`;
last `dependency-direction-placement` bullet ends CLAUDE.md:595 / AGENTS.md:554 / GEMINI.md:531;
`### Project goals` at CLAUDE.md:597 / AGENTS.md:556 / GEMINI.md:533. Audience: AGENTS.md:3 "Context
file for Codex CLI"; GEMINI.md:3 "Context file for Antigravity CLI"; invocations `claude --agent`
(CLAUDE.md:244) / `codex --agent` (AGENTS.md:246) / `agy` + plugin `pack-<name>` (GEMINI.md:213-218).
**Interpretation:** clean append point at the end of `### Repo conventions` in all three; normalize CLI
phrasing per audience, identical CORE substance. **SUPPORTED.**

**EE-17 — cross-reference census = 4 archive files (M-1).** `git grep -nE
"RESEARCH-GRAPHIFY-(EXTERNAL|PACK-INTEGRATION|SYNTHESIS)" -- 'maintenance-docs/archive/v11/*'` returns
refs in FOUR files: ARCHITECTURE-PER-ENTRY-FLAT-FILES.md, IMPLEMENTATION-REPORT-BD-146.md,
**IMPLEMENTATION-REPORT-BD-149.md** (the 4th, prior census missed), PACK-REVIEW-ARCHITECTURE-PER-ENTRY.md.
The 3 LIVE refs are at RESEARCH-CLAUDE-REPOS-SURVEY.md:271, TOUCH-POINT-INVENTORY-GROUPINGS-V2.md:128,
V11.1-DISCUSSION-GITHUB-PROJECTS.md:338. **Interpretation:** archive count corrected to 4 (name BD-149,
disposition unchanged — frozen + D1-excluded); 3 live refs fixed. **SUPPORTED.**

**EE-18 — Check 46 does not require a manifest record for the new rule.** `.spawn-rule-manifest.txt`
header: records ONLY rules whose former restatements in PACK-AGENTS.md/PACK-CHAT.md were collapsed to
one-line references. Check 46 (`check_boundary_and_spawn_pointer_manifests`,
`scripts/validate-pack.py:7344`) iterates the records PRESENT in the manifest (reference-resolution +
anti-restate); it does NOT require every corpus slug to have a record. **Interpretation:** the new
`### Repo conventions` graph-first rule has no collapsed restatement → no manifest record needed →
Check 46 unaffected (§10.2). **SUPPORTED.**

**EE-19 — the propagation procedure's Step 3 is a MEMORY.md step (S-2 / BD-232 flag).**
`pack-ops/PACK-CHAT.md` § "Keeping CLAUDE.md, AGENTS.md, GEMINI.md, and PACK-AGENTS.md current" →
"Rule-change propagation procedure" table, row 3: *"Thin memory-cache pointer (out-of-repo) |
Pack-Chat upkeep; trinity-wins (no validator gate, no pack generator)"*; ordering note: *"... cache
(3) as Pack-Chat upkeep."* **Interpretation:** Step 3 is the out-of-repo MEMORY.md pointer step; it
contradicts the hard NO-MEMORY.md directive for this work → FLAG for BD-232; this design omits Step 3
and does not patch PACK-CHAT.md (§11.2). **SUPPORTED.**

---

## 13. Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|---|
| 1 | agents-never-commit | Read-only git only: `git rev-parse HEAD` → `0a90f56dd...`, `git ls-files`, `git grep`, `git branch`. No add/commit/push/rm/checkout/worktree. Sole write = this design doc via `cat >`/`>>` heredoc to the caller-specified path. | COMPLIANT |
| 2 | per-action-approval-sub-agents | No destructive op on the pack repo. All graphify probes ran in `/tmp/gfx-probe-225` + `/tmp/gfx-ignore-225` (`git init` in `/tmp`), each `rm -rf`'d after (verified: final `ls` of both → "No such file or directory"). NO graph built/indexed in the pack repo; NO `.graphify*` written into the pack repo. | COMPLIANT |
| 3 | agents-read-rule-docs-in-full | Read IN FULL: prior DESIGN (360 lines), PLAN (741), ADVERSARIAL-REVIEW (564), RESEARCH (268), `backlog/BD-225/233/234.md`; pack-root trinity `### Repo conventions` tails + audience lines; `PACK-MEMORY-RATIONALE.md` (preamble + all 24 `## ` headings, of which 22 are Check-45 slugs); `PACK-CHAT.md` propagation procedure (§412-436); `OPTIONAL-FEATURES.md` structure; `validate-pack.py` Checks 45/46/59/62 + registry + count comment. | COMPLIANT |
| 4 | architect-planner-empirical-evidence | §12 carries EE-1…EE-19, each with the actual command + verbatim output + HEAD `0a90f56` + date 2026-06-18 + interpretation + SUPPORTED; every command in the §3 table maps to an EE; re-measured (not cited from prior docs — e.g. EE-15 re-ran Check 45, EE-13 re-loaded the registry, EE-10 re-read build.py/watch.py/__main__.py source). | COMPLIANT |
| 5 | user-prescriptive-authority | LOCKED DECISIONS (B-1→Opt1, D1-D10, Core) + FINDING RESOLUTIONS (M-1..M-3, S-1..S-4, N-1..N-4) encoded faithfully, none re-opened; the §1.1/S-3 D-vs-reality tension (Core `claude-cli` vs stale help enum) VINDICATES the lock (claude-cli valid + no-key; claude needs a key) — surfaced as confirmation, not a re-open. No locked-decision-vs-reality conflict found. | COMPLIANT |
| 6 | NO-MEMORY.md (HARD) | §11 prescribes ZERO MEMORY.md addition; the rule lives ONLY in the in-repo corpus (trinity `## Pack memory` + `## graph-first-context` in PACK-MEMORY-RATIONALE.md). §11.2 + EE-19 FLAG the propagation procedure's Step 3 (MEMORY.md pointer) as a stale contradiction for BD-232 and explicitly OMIT/DROP it; no MEMORY.md pointer added; PACK-CHAT.md NOT patched. | COMPLIANT |
| 7 | bd-pack-only / pack-project-separation | Boundary banner governs every artifact; every setup artifact pack-side; the graph-first rule in the pack-root trinity, NEVER `project-template/` (EE-2 empty grep); §10.2 excludes client-facing DEPENDENCIES.md with reason. | COMPLIANT |
| 8 | ci-guard-design-measure-then-bound | §5.2: measured `git ls-files graphify-out/` → 0 (EE-5) BEFORE designing → legitimate set empty → allowlist sized to zero (no constant) → guard runs clean against current + projected-post-`.gitignore` state. | COMPLIANT |
| 9 | ci-check-runtime-compounding | §5.2: Check 63 = a SINGLE `git ls-files graphify-out/` subprocess, no tree scan, no per-entry storm; O(1) across the battery (the codebase's own 151/155/202 multiplier is illustrative, N-3; the O(1) argument holds at any). | COMPLIANT |
| 10 | verify-availability-not-just-existence | Every §3 command probed on the installed 0.8.39 (EE-3..EE-12), not assumed: M-2 (`extract` has no `--no-viz`) + S-3 (`claude-cli` omitted from the help enum but valid) flagged as doc-vs-CLI gaps with the actual error/help output. | COMPLIANT |
| 11 | cross-cli-reference-normalization | §6.5: identical CORE substance across the trinity; CLI invocation normalized per audience (Claude/Codex/Antigravity per EE-16); explicitly NOT byte-copied; BD-233 carries the cross-CLI effectiveness caveat. | COMPLIANT |
| 12 | fail-loud-delete-old-source | §9.1 deletes the 3 stale docs ENTIRELY (no banner/archive); §9.2 fixes all 3 LIVE dangling refs (M-1: 4 archive files named, BD-149 added, left untouched as frozen); §9.3 zero-dangling gate. This design rewrite itself overwrites the old design IN PLACE (no mirror/banner). | COMPLIANT |
| 13 | enumerate-encoding-surfaces | §5.3 (Check 63 = validator + registry + count-bump + comment + test, FOUR/five surfaces lockstep) + §6.2 (the B-1 tag REQUIRES the PACK-MEMORY-RATIONALE.md `## graph-first-context` section, Check 45) + §10.2 full surface table incl. the deliberately-untouched set (DEPENDENCIES.md, .spawn-rule-manifest.txt, PACK-AGENTS.md) with reasons (EE-18). | COMPLIANT |
| 14 | edit-in-place-not-full-rewrite | All prescribed edits to OTHER pack files are targeted in-place: `.gitignore` append (§5.1), trinity bullet append at a named point (§6.1), PACK-MEMORY-RATIONALE.md section add (§6.2), OPTIONAL-FEATURES.md append (§8), 3 targeted ref fixes (§9.2). The design DOC ITSELF is the sanctioned full rewrite per explicit user request. | COMPLIANT |
| 15 | agent-output-rules-applied-block | This block: one row per in-force rule (1-16), quoted evidence, terminal conclusion; no AMBIGUOUS, no empty evidence. | COMPLIANT |
| 16 | scope-deliverables-to-the-ask | Designs exactly BD-225 as locked + the named finding resolutions + the 3 net-new pieces (graceful degradation, opt-in posture, re-validated command table); out-of-scope items (BD-233 effectiveness, BD-234 re-tune, MCP, global graph, extras) explicitly scoped OUT with reasons; no sprawl. | COMPLIANT |
