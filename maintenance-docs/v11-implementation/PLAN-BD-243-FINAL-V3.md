# PLAN (V3 — FINAL, INTEGRATED) — BD-243 remaining work: BLOAT phase + DURABLE-ENFORCEMENT GATES + surfaced fixes

Planner: FRESH planner instance (pack-planner, RO). I did NOT author `PLAN-BD-243-BLOAT-PHASE.md`, `PLAN-BD-243-BLOAT-PHASE-V2.md`, the `DESIGN-BD-243-*` docs, or the `CENSUS-*`; conclusions are my own (reconciliation-instance-independence). I re-measured every load-bearing fact at runtime.
Runtime: repo `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`, branch `v11-dev`, canonical HEAD **`103cca8`** (verified at runtime — `git rev-parse HEAD` = `103cca8e51feef9c80e4e76be17bd0dd274d3a6b`, clean working tree, untracked plan docs only), 2026-06-22. READ-ONLY; no edits, no patch, no state-changing git.
Status: **PLANNER-READY** — goes to the user at the planner-to-coder gate (planner-output-user-review); NOT auto-approved into a coder spawn. This is the user's last cheap redirect window before CB-01's coder spawns.

This V3 SUPERSEDES `PLAN-BD-243-BLOAT-PHASE-V2.md` and integrates ALL remaining BD-243 work into ONE dependency-correct, sequenced, executable plan:
1. the **bloat reduction wave** CB-01..CB-09 (V2's structure + the approved `DESIGN-BD-243-BLOAT-METHOD.md`), with the **D-1 PLATFORM-SKILLS catalog strip** folded in;
2. the **4 durable-enforcement gates** (`DESIGN-BD-243-DURABLE-GATES.md`) under the user's binding decisions D-1..D-4 + R2;
3. the **2 surfaced fixes** (the PLATFORM-SKILLS deferred catalog = D-1; the `feedback_review_fix_one_cycle.md` dangling ref).

The STRIP phase (CG-01..CG-13) is DONE, committed, pushed, CI-green at `103cca8`; this plan does NOT re-plan or re-run it.

---

## 0. EXECUTIVE ANSWER (decision-ready)

- **Total remaining commits: 13** (with two sanctioned reviewability splits available → up to 15). Sequence:
  - **Bloat wave (9):** CB-01 .. CB-09 (CB-09 splittable → CB-09a/CB-09b).
  - **Gate-infra commit (1):** **CG-14-prep-a** — the shared scope infra (`_iter_operating_docs()` + EXEMPT constant) + Gate 4 (Check 69) + the Check-65 repoint + R2 `incident` tightening. NO count-bearing content gate yet beyond Check 69.
  - **Gate-content commit (1):** **CG-14-prep-b** — Gates 1b/2/3 (Checks 66/67/68) bodies + their allowlists + the D-1 PLATFORM-SKILLS adjudication-strip's gate consequence + the dangling-ref fix + Gate-1 parameter derivation from the measured reduced tree.
  - **Activation commit (1):** **CG-14** — wire all 4 new checks into `CHECK_REGISTRY`, bump `CHECK_REGISTRY_EXPECTED_COUNT` **63 → 67**, flip Check 44 advisory→FAIL, populate/repoint Check 65 scope to the full IN set, full battery green.
  - **Final push (1 step, not a commit):** manifest-sync if a fixture input changed → push → CI watch.
- **The D-1 PLATFORM-SKILLS catalog strip is a STRIP-class content edit (the `### Deferred skills` roll-up at L503 + the 16 inline `*(deferred)*` table tags), NOT a bloat edit.** It is the same platform-future-skills strip class as CG-12/CG-13. I FOLD it into a dedicated step **inside the bloat wave at CB-08** (which already touches PLATFORM-SKILLS for bloat), but I scope it as an EXPLICIT, separately-verified work unit (WU-PLATSKILLS-D1) so it is not confused with bloat reshaping. Justification + the alternative considered: §4.3.
- **CRITICAL ordering (the hard dependency):** Gate 1's PARAMETERS (Check 66 bullet char-cap + Check 44 hardened FAIL ceilings) are DERIVED from the MEASURED reduced tree — so they CANNOT be finalized until CB-01..CB-09 land. They are derived at **CG-14-prep-b** (D-4). Gates 2/3/4 + R2 land at the gate wave (calibration-of-final-tree work).
- **CRITICAL count-bump (the recent-CI-failure lesson, item 2):** 4 new checks ⇒ registry count **63 → 67**. The surface that MUST move in lock-step in the count-bump commit (CG-14) is enumerated EXACTLY in §2. The load-bearing miss-risk is `scripts/tests/test-validate-pack-check-64.sh` which **hardcodes the literal `63`** (lines 74-75) — it WILL fail CI if not bumped to `67`. Full enumeration + the stale prose "62" reconciliation: §2.
- **Per-commit verification = the FULL wired battery** (`ci-shard-plan.py` + `validate-pack.py`), NOT a subset — this is the verify-full-ci-suite lesson; the prior CI failure reached CI precisely because per-commit verification ran a subset. §8.
- **User decisions encoded exactly:** D-1 STRIP the PLATFORM-SKILLS catalog (keep the on-demand guardrail); D-2 Gate 2 (Check 67) FAIL-with-allowlist; D-3 Gate 4 standalone Check 69; D-4 Gate 1 ceilings/caps derived at CG-14-prep-b from the reduced tree (FAIL); R2 `incident`→`\bincident\b`.

---

## 1. STATE BASELINE (measured @ `103cca8`, independently re-verified)

The full strip phase has landed; the anti-bloat/anti-history gate (Check 65) is registered but INERT; the 4 new gates do not yet exist.

- `git rev-parse HEAD` = `103cca8e51feef9c80e4e76be17bd0dd274d3a6b`; branch `v11-dev`; `git status --short` empty (clean; untracked plan docs only).
- `CHECK_REGISTRY_EXPECTED_COUNT = 63` (validate-pack.py:496); `_CHECK_65_OPERATING_DOCS = ()` (validate-pack.py:7926) — Check 65 enforces NOTHING against the live tree yet. CG-14 is the sole activation point.
- Highest registered check NUMBER = 65 → next free check numbers are **66, 67, 68, 69**.
- `python3 scripts/validate-pack.py` = `PASSED — all checks clean` (exit 0).

**EE-BASE — state baseline @ `103cca8`.**
- Cmd: `git rev-parse HEAD; git branch --show-current; git status --short; grep -n 'CHECK_REGISTRY_EXPECTED_COUNT = ' scripts/validate-pack.py; grep -n '_CHECK_65_OPERATING_DOCS = ' scripts/validate-pack.py; python3 scripts/validate-pack.py | tail -2`
- Output (verbatim, key): `103cca8e51feef9c80e4e76be17bd0dd274d3a6b`; `v11-dev`; (empty status); `496:CHECK_REGISTRY_EXPECTED_COUNT = 63`; `7926:_CHECK_65_OPERATING_DOCS = ()`; `PASSED — all checks clean`.
- HEAD/date: `103cca8` / 2026-06-22.
- Interpretation: strip phase complete; gate inert; tree green; EXPECTED_COUNT 63; next free numbers 66-69.
- Conclusion: **SUPPORTED.**

---

## 2. THE COUNT-BUMP SURFACE ENUMERATION (item 2 — the load-bearing, repeat-CI-failure prevention)

**This is the single most defect-prone step in the entire plan.** The recent CI failure was an `enumerate-encoding-surfaces` miss on exactly this axis: a count-encoding surface was left un-bumped. 4 new checks (66/67/68/69) ⇒ `CHECK_REGISTRY_EXPECTED_COUNT` goes **63 → 67** (NOT to 69 — number ≠ count; the registry has duplicate-number entries + `None`-number entries, so the count lags the max number; the in-file CAUTION at validate-pack.py:489-491 states this explicitly). Gate 1a (Check 44 in-place hardening) and R2 (Check 65 in-place pattern tighten) are +0 entries each.

**EVERY surface that encodes the count — measured authoritatively via `grep -rn` (grep is authoritative here, not the graph) — and MUST move in lock-step in the CG-14 count-bump commit:**

| # | Surface | File:line(s) @ `103cca8` | Current value | Required at CG-14 | Mechanism | Miss = CI failure? |
|---|---|---|---|---|---|---|
| S1 | The constant itself | `scripts/validate-pack.py:496` | `CHECK_REGISTRY_EXPECTED_COUNT = 63` | `= 67` | literal | **YES — Check 59 FAILs** |
| S2 | The 4 new `CHECK_REGISTRY` entries | `scripts/validate-pack.py` registry tail (after the Check-65 entry ~line 10345+) | (absent) | append `(66,…)`,`(67,…)`,`(68,…)`,`(69,…)` | registry tuples | YES — count won't reach 67 without them |
| S3 | The EXPECTED_COUNT comment LEDGER | `scripts/validate-pack.py:475-495` (the arithmetic `+1 net-new …` block) | sums to 63 | add 4 `+1 net-new BD-243 check (66/67/68/69 …)` lines; update the CAUTION's "(65 for BD-243)" → note 66-69 | comment | NO (doc only) but REQUIRED for audit hygiene + the in-file lock-step contract |
| S3b | The STALE prose "62" in that comment | `scripts/validate-pack.py:476` ("so the registry now holds **62** entries") | says 62 (already stale; constant is 63) | reconcile to 67 | comment prose | NO (doc only) — but fix it in the same commit; it is already wrong at `103cca8` and the count-bump is the natural reconciliation point |
| S4 | **The hardcoded-literal test** | `scripts/tests/test-validate-pack-check-64.sh:74-75` (`if mod.CHECK_REGISTRY_EXPECTED_COUNT != 63: … FAIL_COUNT_NOT_63`) + line 82 pass-message `(== 63)` | hardcodes `63` | `!= 67` + message `(== 67)` | literal in a `.sh` test | **YES — this test FAILs in CI; THIS is the recent-failure class** |
| S5 | Check 59's runtime assertion | `check_registry_completeness` (asserts `len(_build_check_registry()) == CHECK_REGISTRY_EXPECTED_COUNT`) | dynamic | self-satisfies once S1+S2 land together | code (no edit) | auto (FAILs if S1/S2 out of sync) |
| S6 | Check 60's shard-coverage mirror | `check_shard_coverage` (derives the shard partition from the registry) | dynamic | self-satisfies once S2 lands | code (no edit) | auto |

**The DYNAMIC tests that need NO edit (verified — do NOT touch, but VERIFY they pass):** `test-validate-pack-check-62.sh` (line 70: `len(...) != mod.CHECK_REGISTRY_EXPECTED_COUNT`), `test-validate-pack-check-63.sh` (line 62: same dynamic form), `test-validate-pack-checks-58-59-60.sh` (line 146: dynamic form). These compare the computed registry length to the constant rather than to a literal, so a correct +4 bump satisfies them automatically. **The asymmetry between S4 (hardcoded) and these (dynamic) is the trap — only check-64's test hardcodes the literal.**

**The 4 NEW per-check tests (66/67/68/69) MUST use the DYNAMIC count-invariant form, never the hardcoded literal** (`if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT` + `if NN not in nums`), matching the check-62/63 pattern — NOT the check-64 hardcoded-`63` pattern. This prevents minting a NEW hardcoded-literal trap for the NEXT count bump. **This is a hard instruction to the CG-14-prep-b / CG-14 coder.**

**Lock-step atomicity rule:** S1 + S2 + S4 MUST land in the SAME commit (CG-14). S3/S3b ride the same commit. If S1 bumps without S2, or S2 lands without S4's literal edit, CI is RED. The coder PREFLIGHT for CG-14 runs the FULL battery (§8) which exercises check-64's test — catching an S4 miss BEFORE the patch is produced.

**EE-COUNT — the count-encoding surfaces @ `103cca8`.**
- Cmd: `grep -rnE "CHECK_REGISTRY_EXPECTED_COUNT|_build_check_registry\(\)|!= 63|== 63|FAIL_COUNT_NOT" scripts/validate-pack.py scripts/tests/*.sh`
- Output (verbatim, key): `validate-pack.py:496:CHECK_REGISTRY_EXPECTED_COUNT = 63`; `test-validate-pack-check-64.sh:74:if mod.CHECK_REGISTRY_EXPECTED_COUNT != 63:`; `:75: print('FAIL_COUNT_NOT_63 got', …)`; `:82: t_pass "… count invariant holds (== 63)"`; `test-validate-pack-check-62.sh:70:if len(mod._build_check_registry()) != mod.CHECK_REGISTRY_EXPECTED_COUNT:`; `test-validate-pack-check-63.sh:62:` (same dynamic form); `test-validate-pack-checks-58-59-60.sh:146:if actual != mod.CHECK_REGISTRY_EXPECTED_COUNT:`. The EXPECTED_COUNT comment (`:475-496`) prose says "the registry now holds 62 entries" while the arithmetic + constant = 63 (stale prose).
- HEAD/date: `103cca8` / 2026-06-22.
- Interpretation: exactly ONE test hardcodes the literal `63` (check-64); three tests use the dynamic form (no edit needed); the comment prose carries a stale "62". The count-bump commit must edit S1 (constant), append S2 (4 entries), edit S4 (check-64 literal `63`→`67` + message), and reconcile S3/S3b (comment). New tests must use the dynamic form.
- Conclusion: **SUPPORTED.**


---

## 3. THE BLOAT METHOD (carried from `DESIGN-BD-243-BLOAT-METHOD.md` — apply per surface)

Three methods, selected by surface class (the per-commit table §4 names the method per file).

### 3.1 Skills + agent-defs → the §A examples S-test + A.2 invariant set + A.5 verification

Binding user ruling: **TEXT-AMOUNT-ONLY reduction; ZERO meaning/functionality change. Guardrails, rules, in/out-of-scope concepts INVARIANT. Examples kept only if they add irreplaceable specificity.**

**The S-test (per example/pattern/snippet — KEEP if ANY sub-test is YES):**
- **(S1) Concrete shape** — a literal shape a reader would otherwise guess (exact API call, config-key path, code construct, filename grammar, message format, settings snippet). KEEP.
- **(S2) Edge case / disambiguation** — pins a case the reader would get WRONG (counter-example, "this NOT that" contrast, an abstractly-stated boundary). KEEP.
- **(S3) Irreducible enumeration** — one item in a set the rule MUST enumerate to be correct (the deletion rules `.nullify`/`.cascade`/`.deny`/`.noAction`; the denied git-verb list). KEEP.
- **REMOVE only if ALL three are NO** — pure redundant illustration restating adjacent prose. Text-amount bloat → REMOVE.

**The A.2 INVARIANT set — NEVER touched:** guardrails, rules/directives, triggers (load predicate), exceptions/carve-outs, in/out-of-scope concepts (an "out of scope for this skill" statement is an OPERATIVE GUARDRAIL → KEEP), frontmatter (Check 1). Only REDUCIBLE: redundant prose, hedging, restated imperatives, padding, redundant examples (the REMOVE-class).

**B-type license on skills (tightened):** B1/B2 = pure RESHAPE (every clause survives as a row); B3 = the primary text-amount lever; B4 = parity-locked ×3, reshape not dedup. "Aggressive terseness" is SUPERSEDED for skills — no substantive deletion; expect MODEST reduction on technical skills (most lines are S-test-passing).

**The A.5 verification contract (reviewer's per-skill proof):** for every skill a bloat commit touches —
1. **Invariant-set diff** — enumerate the A.2 set from `git show HEAD:<skill>` and the post-bloat file; the two sets MUST be EQUAL. A non-empty asymmetric diff = a meaning-loss BLOCKER.
2. **Example-removal justification log** — IMPL-REPORT records, per REMOVED example, the S-test verdict. An example removed WITHOUT a log entry is a BLOCKER.
3. **Example-retention spot-check** — sampled KEPT examples each pass ≥1 S-test.
4. **Frontmatter intact (Check 1)** + **no net new directive/clause** (diff is removals + reshapes only).

### 3.2 OPTIONAL-FEATURES → the §B human-readable reduction — CB-01 ONLY

Binding user ruling: **human-readable reference doc; reduce text without losing clarity/meaning; NEVER modify structures/code/JSON/examples; apply the rule human-readably.**

**Process-doc finding:** OPTIONAL-FEATURES is NOT executed as a process doc; two CI guards treat narrow properties as contracts — Check 54 (literal tokens `baseRef`, `bgIsolation`, `permissions.deny` present in BOTH surfaces; FAILs the build if missing) + Check 44 (advisory length). These are content-presence GUARDRAILS the reduction must respect.

**REDUCIBLE (prose only):** restatement padding, hedging/persuasive padding, B2 prose→table where it improves human readability AND never reshapes a protected block.

**PROTECTED (NEVER modified):** all fenced code/JSON/text/bash blocks (byte-identical); inline settings specifications (`worktree.baseRef: "head"`, `["head","fresh"]`, `worktree.bgIsolation`, `permissions.deny`, `isolation:"worktree"` — these ARE both the protected settings examples AND the Check-54 tokens); structure (headers, the §1.1 backend caveat, the privacy/secrets facts, any worked-example shape); the K13 graphify snippet `DESIGN-BD-225-GRAPHIFY-PACK-INTEGRATION.md`.

### 3.3 All other operating docs → B1-B4 + C.2 clause-preserving + C.3 clause-set-diff

**C.2 clause-preserving conversion (mandatory for any rule >~800 chars):** (1) clause-enumerate first; (2) convert prose→structured one-clause-per-row; (3) re-enumerate (post == pre — a dropped clause = behavior change = FAIL); (4) trim B3 padding within a clause only; (5) trinity/tri-family lock in the same commit.
**C.3 reviewer clause-set-diff:** for every swept rule, a before/after clause-set diff (`git show HEAD:<file>` vs post-edit) asserting set-equality modulo flagged B3 padding; a non-empty asymmetric diff that is NOT flagged padding = a meaning-loss BLOCKER.

---

## 4. THE BLOAT WAVE — 9 COMMITS (CB-01..CB-09) + the D-1 fold

A bloat commit collects reviewed-clean work-unit patches and applies them as ONE grouped commit, GREEN at apply (full battery exit 0; Check 65 vacuous until CG-14). Grouping mirrors the strip-phase surface partition so the no-double-BLOAT-touch invariant holds (each file = at most one bloat commit). The all-skills ruling does NOT change the count or partition.

### 4.1 The 9-commit structure

| Commit | Content (bloat axis + folded cleanup) | Files | Method | Scope keyword | Lock |
|---|---|---|---|---|---|
| **CB-01** | Pack-ops operating-doc bloat **+ FLAG-2a strip + 2 history-NARRATIVE strips + OPTIONAL ceiling re-derive** | `pack-ops/OPTIONAL-FEATURES.md` (hard: 544→floor; §3.2 + FLAG-2a + §5 ceiling recipe), `MERGE-STRATEGY.md`, `CONCEPTUAL-REVIEW-METHODOLOGY.md` (+ Empirical-validation history-NARRATIVE para), `PACK-CHAT.md`, `PACK-AGENTS.md`, `DRY-RUN-MIGRATION.md`, `BOUNDARY-DEFINITION.md` (+ AUDIT-USER-CURATION history-NARRATIVE clause) | §3.2 (OPTIONAL) + §3.3 (rest) | `pack-only` | parallel across distinct files |
| **CB-02** | Pack RATIONALE bloat (surgical) | `pack-ops/PACK-MEMORY-RATIONALE.md` | §3.3 (B1 per-`## slug` Why + B3) | `pack-only` | own commit (784 ln, heaviest; K2-K5/K13 snippet-stable) |
| **CB-03** | Pack stream-meta bloat | `backlog/_rules.md`, `changelog/_rules.md` | §3.3 (B3) | `pack-only` | parallel; K7 snippet-stable (backlog/_rules) |
| **CB-04** | Pack skills bloat | `.claude/skills/*/SKILL.md` (11) | **§3.1 S-test** | `pack-only` | parallel; Check 1 frontmatter intact; A.5 contract |
| **CB-05** | Pack agent-defs bloat | `.claude/agents/pack-*.md` (5) | **§3.1 S-test** | `pack-only` | parallel; Check 11 informational; A.5 contract |
| **CB-06** | Pack-root trinity bloat | `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` (pack root) | §3.3 (C.2 mega-rule) | `pack-only` | trinity-locked ×3 ONE commit; K1/K2/K3/K12 snippet-stable; sanctioned Claude-only asymmetry preserved |
| **CB-07** | Project trinity bloat | `project-template/{CLAUDE,AGENTS,GEMINI}.md` | §3.3 (C.2 mega-rule) | `project-only` | trinity-locked ×3 ONE commit; ∥ CB-06; K12 snippet-stable |
| **CB-08** | Project docs/pack + prompts + stream-meta bloat **+ D-1 PLATFORM-SKILLS catalog strip (WU-PLATSKILLS-D1)** | `docs/pack/PM-CHAT.md`, `PLATFORM-SKILLS.md` (bloat + D-1 strip), `OPTIONAL-FEATURES.md`, `PACK-FEEDBACK.md`; `docs/pack/prompts/*.md` (10); `docs/project/{backlog,changelog,implementation-plan}/_rules.md` + `changelog/_format.md` | §3.3 (B-types) + §4.3 (D-1 strip); project OPTIONAL is NOT §3.2 | `project-only` | parallel; K11/K9/K10 snippet-stable |
| **CB-09** | Project agent-defs + skills bloat | 16 roles ×3 families + `RUNTIME-SUBAGENT-PATTERN.md`; `project-template/skills/*/SKILL.md` (37) | agent-defs §3.3 (B4 tri-family); skills **§3.1 S-test** | `project-only` | tri-family-locked per role; roles parallel; skills parallel; Check 1 intact; A.5 contract. SPLITTABLE → CB-09a (agent-defs) / CB-09b (project skills) |

**Splitability:** CB-09 → CB-09a (agent-defs) / CB-09b (project skills) on reviewer-load demand (10 bloat commits). Reviewability split, not a scope change; no re-approval. The §3.1 S-test + A.5 contract attach to CB-09b.

**Scope-keyword cleanliness (Check 36):** CB-01..CB-06 = `pack-only`; CB-07..CB-09 = `project-only`. NO bloat commit is cross-surface. CRITICAL for the project-only commits (CB-07/CB-08/CB-09): a snippet reword needing a `pack-ops/` allowlist co-update (C-SNIP-2(b)) breaks `project-only` → use C-SNIP-2(a) verbatim-keep (§7).

### 4.2 Accumulated cleanup folds (carried from V2)

- **FLAG-2a (→ CB-01):** the OPTIONAL-FEATURES worktree `**Status:**` line "Claude Code only — no Codex or Antigravity equivalent yet (the cross-CLI story is tracked separately and is out of scope here)." KEEP "Claude Code only" current-state; STRIP the "no … equivalent yet … tracked separately" forward-look (CENSUS §5 split). CB-01 already touches OPTIONAL-FEATURES.
- **History-NARRATIVE prose (→ CB-01):** `BOUNDARY-DEFINITION.md` AUDIT-USER-CURATION audit-provenance clause → reduce to the operative exempt reason; `CONCEPTUAL-REVIEW-METHODOLOGY.md` `## Empirical validation requirement` trailing "empirically validated retroactively across prior multi-BD batches" paragraph → reduce to the operative requirement. Both files are in CB-01's membership; both folds land in CB-01.
- **Gate-completeness items (→ the gate wave, NOT the bloat commits):** the `incident`→`\bincident\b` tightening + the GC-3/GC-4 allowlist records → CG-14-prep-a (R2 + scope infra). Division: bloat passes handle history-NARRATIVE prose; the gate wave handles the gate allowlist + the regex tightening.

### 4.3 The D-1 PLATFORM-SKILLS catalog strip (WU-PLATSKILLS-D1) — folded into CB-08, separately verified

**Why a fold into CB-08 (not a dedicated commit), with justification:** PLATFORM-SKILLS.md is ALREADY in CB-08's membership (bloat). The no-double-BLOAT-touch invariant requires a file get at most one CB commit; opening a SEPARATE D-1 commit for the SAME file would either (a) violate that invariant or (b) force CB-08 to skip PLATFORM-SKILLS's bloat and a second commit to do both — needless serialization on one file. The D-1 strip and the bloat reshape on PLATFORM-SKILLS are best done together, in one worktree, by one coder, as TWO clearly-separated work units (WU-PLATSKILLS-D1 = the strip; WU-PLATSKILLS-BLOAT = the §3.3 reshape). CB-08 is `project-only`; both work units are project-side → scope-clean.

**Alternative considered + rejected:** a dedicated CG-style strip commit (e.g. "CG-14b") landing AFTER the bloat wave. REJECTED — it re-touches PLATFORM-SKILLS after CB-08 already touched it (double-touch on one file across two commits), and it splits a single file's edits across the bloat/gate boundary, complicating the snippet-stability + parity reasoning. The fold keeps all PLATFORM-SKILLS edits atomic.

**The D-1 strip recipe (STRIP-class, same as CG-12/CG-13 platform-future-skills — KEEP-the-guardrail / STRIP-the-promise per CENSUS §5):**
1. **DELETE the `### Deferred skills (create when project need arises)` roll-up section** (PLATFORM-SKILLS.md:503-527 @ `103cca8` — the flat roll-up of D1/D2/D5/intersection/D4 deferred skill names + the "D1-implied languages (deferred…)" block). This is the named deferred-skill catalog D-1 targets.
2. **STRIP the 16 inline `*(deferred)*` table tags** (measured @ `103cca8`: 16 occurrences, e.g. `| android *(deferred)* | …` at L68, plus L69/71/72/73/101/102/137/138/139/155/156/157/158/159, and the L506 back-reference "(rows tagged *(deferred)*)"). The strip removes the `*(deferred)*` TAG; the disposition of each row's CONTENT (keep the row as a not-yet-built entry vs delete the row) follows the KEEP-the-guardrail rule below.
3. **STRIP the `*(future)*` placeholder tags** in the same tables (e.g. the swift-server-architecture / Vapor-Hummingbird placeholder rows the CENSUS named) — same platform-future-skills class.
4. **KEEP the operative on-demand guardrail.** Replace the deferred catalog with a single current-state operative statement, e.g. "Platform skills beyond the current set are created on-demand per INSTALL-PROCEDURES; no dedicated skill exists for non-Apple platforms yet." This preserves the bound on what the agent may assume exists (the guardrail) WITHOUT advertising a planned creation roadmap (the promise). The CENSUS §5 USER RULING governs: an "out of scope / no dedicated skill yet" statement is an OPERATIVE GUARDRAIL → KEEP; the "deferred / will be created / planned post-v11.0" promise → STRIP.
5. **Verify:** WU-PLATSKILLS-D1's reviewer confirms grep-zero for the deferred-skill ADVERTISEMENT patterns over PLATFORM-SKILLS.md post-strip (`### Deferred skills`, `*(deferred)*`, `*(future)*`, "create when project need arises", "deferred to a future", "planned post-v11.0") while confirming the on-demand guardrail survives. This grep-zero is ALSO the precondition that makes Gate 2 (Check 67) activatable clean over PLATFORM-SKILLS (it was the census MISS — EE-G2-PLAT; D-1 resolves it at CB-08 so the gate wave inherits a clean file).

**Dependency note (load-bearing):** because the D-1 strip lands at CB-08 (inside the bloat wave), the Gate-2 (Check 67) allowlist at the gate wave does NOT need a 29-record PLATFORM-SKILLS block (the rejected option-(ii) from the architect's D-1 decision). The user chose option-(i) STRIP → PLATFORM-SKILLS is clean by CB-08, and Gate 2 FAIL-activates over it with no allowlist carve-out for the deferred catalog. The Gate-2 allowlist sizes only to the genuine KEEP categories (rule self-reference, generic client-product advice, operative current-state caveats, the live TD-deferral feature).

**EE-D1 — the PLATFORM-SKILLS deferred catalog @ `103cca8`.**
- Cmd: `grep -nF "Deferred skills" project-template/docs/pack/PLATFORM-SKILLS.md; grep -cF "(deferred)" project-template/docs/pack/PLATFORM-SKILLS.md; grep -nF "(deferred)" … | head; sed -n '503,527p' …`
- Output (verbatim, key): `503:### Deferred skills (create when project need arises)`; `(deferred)` count = `16`; inline tags at L68/69/71/72/73/101/102/137/138/139/155/156/157/158/159 + L506 back-ref; the L503-527 roll-up ("D1 — Runtime / OS substrate: android-architecture …", "D2 — Cross-platform languages: rust-best-practices …", "D1-implied languages (deferred with their D1 value): …", "D5 — Deployment surface: …", "Intersection (deferred sibling servers): swift-server-architecture …", "D4 — Communication protocols: graphql-patterns …").
- HEAD/date: `103cca8` / 2026-06-22.
- Interpretation: a real, client-facing deferred-skill catalog (1 roll-up section + 16 inline tags + the back-reference) exactly as D-1 describes. The strip removes the roll-up + the tags + the promise prose; the on-demand guardrail replaces it. This is the same platform-future-skills strip class as CG-12/CG-13.
- Conclusion: **SUPPORTED.**

### 4.4 Sequencing / dependency map (rule-10 parallel-vs-dependent) — bloat wave

- **Phase gate:** all CB-01..CB-09 run AFTER `103cca8`. The clause-set-diff / invariant-set-diff baseline for every commit is `git show HEAD:<file>` against the strip-clean version.
- **Same-file serialization:** NONE across CB commits — the §4.1 partition gives every bloat-bearing file exactly one CB commit. Each CB serializes only internally (its trinity/tri-family lock).
- **Trinity lock:** CB-06 (pack ×3) and CB-07 (project ×3) each ONE atomic commit; CB-06 ∥ CB-07 (disjoint sets).
- **Tri-family lock:** CB-09(a) edits each role's 3 family files as ONE unit; roles parallel.
- **Parallel waves (scheduler hint to Pack Chat):** {CB-01, CB-02, CB-03, CB-04, CB-05} pack waves parallel across distinct files; CB-06 + CB-07 trinity serial bottlenecks (∥ each other); CB-08 + CB-09 high-parallelism project waves. No bloat commit blocks another on a shared file.
- **The gate wave depends on ALL CB-01..CB-09 landed** (Gate 1 parameters measure the final reduced tree; the two-axis sweep runs over it).

**EE-NDT — no-double-BLOAT-touch census @ `103cca8`.**
- Cmd: manual cross-check of §4.1 file membership against the strip-phase partition.
- Output: each bloat-bearing file maps to exactly one CB row; PLATFORM-SKILLS appears only in CB-08 (its D-1 strip + bloat both there); no file in two CB rows.
- HEAD/date: `103cca8` / 2026-06-22.
- Interpretation: the no-double-BLOAT-touch invariant holds across the 9-commit partition, including the D-1 fold (PLATFORM-SKILLS single-commit).
- Conclusion: **SUPPORTED.**


---

## 5. THE CB-01 OPTIONAL-FEATURES CEILING RECIPE (measure-then-bound; reduce-then-re-derive)

The 271 ceiling is STALE: `271 = ceil(235 × 1.15)` from a 235-line baseline that PRE-DATES the graphify section; the doc is now 544 lines.

**The deterministic recipe the CB-01 coder runs:**
1. **Reduce to the human-readable floor (§3.2):** apply §B.2 prose-only reduction + the FLAG-2a strip + leave ALL fenced blocks byte-identical + preserve the Check-54 trio + the K13 graphify snippet verbatim.
2. **Measure:** `wc -l pack-ops/OPTIONAL-FEATURES.md` in the worktree = `measured_reduced_lines`.
3. **Re-derive:** `new_ceiling = ceil(measured_reduced_lines × 1.15)`.
4. **Apply the bound:** `≤ 235` → 271 stands; `235 < measured ≤ 271` → 271 stands; `> 271` → UPDATE the ceiling in the SAME `pack-only` commit (CB-01).
5. **Do NOT over-terse to hit 271** — the advisory never fails the build; re-derive UP to the irreducible floor if reaching 271 would drop a settings example or human-useful clarity.

**Lock-step surfaces IF the ceiling changes (enumerate-encoding-surfaces, @ `103cca8`):**
- `scripts/validate-pack.py` — the `("pack-ops/OPTIONAL-FEATURES.md", 271)` tuple row in `_CHECK_44_DURABLE_DOCS` (~validate-pack.py:7763) → new value.
- The comment block (~validate-pack.py:7752-7755) recording `OPTIONAL 235` → the new `measured_reduced_lines`.
- **The Check-44 TEST needs NO value edit** — `scripts/tests/test-validate-pack-check-44.sh` uses a SYNTHETIC mocked doc + parameterized `advisory_ceiling`; it does NOT hardcode 271.
- No other surface encodes 271.

**Cross-reference to Gate 1a (D-4):** at the gate wave, Check 44's ceiling axis flips advisory→FAIL (Gate 1a). The CB-01 re-derived ceiling for OPTIONAL-FEATURES becomes one of the 6 FAIL ceilings; the OTHER 5 durable docs' FAIL ceilings are re-derived at CG-14-prep-b from THEIR measured reduced trees (BOUNDARY/CONCEPTUAL/DRY-RUN/HELP-PACK/MERGE — those CB-01 also reduces, so their measured-reduced line counts exist by the gate wave). **The CB-01 coder records each of the 6 docs' `measured_reduced_lines` in its IMPL-REPORT** so the gate-wave coder can derive all 6 FAIL ceilings without re-measuring against a possibly-drifted tree. (CB-01 reduces 5 of the 6; HELP-PACK is not in CB-01's set — verify it is unchanged or measure it at the gate wave.)

**EE-CEIL — the 271 ceiling basis + the 6 durable docs @ `103cca8`.**
- Cmd: `sed -n '7746,7763p' scripts/validate-pack.py`; `python3 scripts/validate-pack.py --only-check 44 2>&1 | grep -iE "ADVISORY|PASS"`.
- Output (verbatim, key): comment "(BOUNDARY 135, CONCEPTUAL-REVIEW 298, DRY-RUN 199, HELP-PACK 48, MERGE 484, OPTIONAL 235)"; tuple `("pack-ops/OPTIONAL-FEATURES.md", 271)`; `_CHECK_44_DURABLE_DOCS` = 6 rows; only OPTIONAL exceeds (544 vs 271, ADVISORY); `PASSED — all checks clean`.
- HEAD/date: `103cca8` / 2026-06-22.
- Interpretation: 6 durable docs carry per-doc ceilings; only OPTIONAL is over; the re-derivation is per-doc measure-then-bound. CB-01 reduces 5 of the 6 (all but HELP-PACK).
- Conclusion: **SUPPORTED.**

---

## 6. THE GATE WAVE — the 4 durable gates + R2 (lands AFTER the bloat wave)

The gate wave is partitioned into THREE commits, dependency-ordered. The architect's design (`DESIGN-BD-243-DURABLE-GATES.md`) is carried; the user's D-1..D-4 + R2 are encoded; I sequence the implementation.

### 6.0 The shared scope model (carried — auto-discover + EXEMPT + meta-check)

Three content gates (Check 65 history, Check 67 deferred, Check 68 dangling-operating-doc-half) share ONE discovery helper `_iter_operating_docs()` (family glob minus the frozen `_CHECK_OPERATING_DOC_EXEMPT` constant ≈3 patterns: `_intro.md`, `_toc.md`, `HELP-FRAGMENT*.md`). Gate 4 (Check 69) is the completeness meta-check that asserts the glob's coverage. This replaces the frozen-IN `_CHECK_65_OPERATING_DOCS` tuple (the silent-rot hole). The IN set = 135 files @ `103cca8`.

### 6.1 Gate designs (carried, with the user decisions encoded)

**Gate 1 — BLOAT/VOLUME (Check 44 hardened [Gate 1a] + new Check 66 [Gate 1b]).**
- **Gate 1a** — flip Check 44's per-doc length branch from ADVISORY to **FAIL** over the frozen 6-doc `_CHECK_44_DURABLE_DOCS`; the 6 ceilings re-derived `ceil(measured_reduced × 1.15)` from the bloat-reduced tree (D-4). +0 registry entry.
- **Gate 1b** — NEW **Check 66** `check_operating_doc_bullet_concision`: per-bullet/per-rule char-cap over the bullet-bearing surface (pack + project trinity + RATIONALE — the `## Pack memory` / `## <slug>` bullet structure). A SINGLE cap constant `_CHECK_66_BULLET_CHAR_CAP` derived from the POST-REDUCTION max legitimate bullet × headroom; a snippet-anchored allowlist for any irreducibly-long bullet (enumeration class). **FAIL** (D-4). +1 registry entry.
- **False-positive guarantee (volume-only, never meaning):** parameters derived from post-reduction reality + headroom (legitimate content below cap by construction); the allowlist admits genuinely-irreducible over-cap bullets with a re-verified `reason:`; a char count asserts nothing about meaning.

**Gate 2 — DEFERRED-FEATURE RECALL (new Check 67) — D-2 = FAIL-with-allowlist.**
- NEW **Check 67** `check_operating_doc_no_deferred_feature`: a compiled-alternation of deferral markers (`_CHECK_67_DEFERRED_PATTERNS` — `\bdeferred\b`, `future (pack )?version|future release|in a future`, `\bnot yet (created|implemented|built|shipped)\b`, `once .{0,40}\b(land|lands|ship|ships)\b`, `\broadmap\b`, `v11\.1|v11\.x`, `\bslated\b`, etc.) over `_iter_operating_docs()`. Allowlist file `pack-ops/.operating-doc-deferred-feature-allowlist.txt` (same `_parse_manifest_records` format as Check 65), sized EXACTLY to the genuine KEEP categories (rule self-reference; generic client-product advice; operative current-state caveats; the live TD-deferral feature). **FAIL with allowlist** (D-2). +1 registry entry.
- **D-1 INTERACTION (load-bearing):** PLATFORM-SKILLS's deferred catalog — the architect's Gate-2 activation precondition (EE-G2-PLAT) — is RESOLVED at CB-08 by the D-1 strip (§4.3). So Gate 2 FAIL-activates over a clean PLATFORM-SKILLS with NO catalog allowlist block. The Gate-2 allowlist authoring at CG-14-prep-b sizes only to the 4 genuine KEEP categories; any unclassified hit = a BLOCKER surfaced to the user (R-1 measure-then-bound; never auto-allowlisted).

**Gate 3 — DANGLING-REFERENCE (new Check 68, generalizes Check 64).**
- NEW **Check 68** `check_dangling_file_refs`: reuses Check 40's bare-ref + hyperlink patterns + `_strip_code_blocks` + `_CHECK_40_ANCHOR_PHRASES` + the once-built basename index; adds ONE bounded `_CHECK_68_QUALIFIED_PATH_PATTERN` for `` `dir/.../FILE.ext` `` refs (the shape Check 40's `/`-exclusion misses — where deleted-doc refs hide). Scope = `_iter_operating_docs()` ∪ Check-64 deliverable surface, minus the maintenance-docs/test-fixtures/per-entry-store excludes. Allowlist `pack-ops/.dangling-ref-allowlist.txt` sized to the measured intentional-placeholder set (grammar patterns, anchor-phrase-self-flagged retired/declined refs, runtime-generated outputs, `x-`/`vN` framework patterns). **FAIL with allowlist** (existence is objective). +1 registry entry.
- **Surfaced fix 2 (the dangling ref):** the 1 genuine dangling ref `feedback_review_fix_one_cycle.md` (`pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md:186` "Review/fix cycles per BD AND per batch (per `feedback_review_fix_one_cycle.md`)") is FIXED at CG-14-prep-b so Gate 3 runs clean at activation (measure-then-bound: verify clean against projected post-fix state). The correct memory file is `feedback_review_fix_cycle.md` (no "one"). NB: this ref's TARGET is a curated-memory file outside the repo tree (`~/.claude/projects/<slug>/memory/`), so Gate 3 must treat the memory-index family appropriately (allowlist the family OR resolve the corrected name) — the FIX is to correct the name to `feedback_review_fix_cycle.md`; whether the corrected name then needs an allowlist record depends on Gate 3's resolution rule for the out-of-repo memory family. The coder resolves at CG-14-prep-b (see R-3, §9).

**Gate 4 — NEW-DOC AUTO-COVERAGE (new Check 69) — D-3 = standalone (not folded into Check 59).**
- NEW **Check 69** `check_operating_doc_scope_completeness`: globs the operating-doc families, asserts every member is in `(family-glob ∪ _CHECK_OPERATING_DOC_EXEMPT ∪ _CHECK_OPERATING_DOC_OUT_OF_FAMILY)`. A new doc in an un-globbed location FAILs loud. Reads NO file bodies (path glob + set arithmetic — the cheapest gate). **FAIL.** +1 registry entry. Standalone per D-3 (one-concern-per-check; Check 59 is about the CHECK registry, not the DOC scope).

**R2 — `incident` regex tightening (Check 65 in-place):** `("incident", re.compile(r"incident"))` → `("incident", re.compile(r"\bincident\b"))` in `_CHECK_65_FORBIDDEN_PATTERNS`. Kills the 2 substring false-positives (GC-1 "incidents" PACK-FEEDBACK:59; GC-2 "coincidental" reviewer.md:128); retains the 7 whole-word hits (6 rule-self-reference + 1 KEEP GC-3 boundary-investigation project copy). +0 registry entry; edit `test-validate-pack-check-65.sh` (whole-word case).

### 6.2 The gate-wave commit partition (3 commits)

**CG-14-prep-a (`pack-only`) — scope infrastructure + Gate 4 + Check-65 repoint + R2.** The +0-count-OR-Check-69-only foundation that everything else builds on.
- Author `_iter_operating_docs()` + `_CHECK_OPERATING_DOC_FAMILIES` + `_CHECK_OPERATING_DOC_EXEMPT` (shared helper — single surface, prevents drift).
- Author **Check 69** (Gate 4) `check_operating_doc_scope_completeness` + `_CHECK_OPERATING_DOC_OUT_OF_FAMILY` + NEW `test-validate-pack-check-69.sh` (DYNAMIC count form). **This is the ONLY new check in -a** → it alone bumps the count +1 here IF -a and -b/CG-14 are separate count bumps. **DECISION (count atomicity):** to avoid two separate count bumps (two chances to mis-bump), I RECOMMEND the count bump (63→67) + ALL 4 registry entries land in ONE commit = **CG-14** (activation), and CG-14-prep-a/-b author the check BODIES + constants + tests WITHOUT yet registering them in `CHECK_REGISTRY` or bumping the count. See §6.3 for the registration-deferral mechanism. Under this model CG-14-prep-a is +0 count.
- Repoint Check 65 scope: `_CHECK_65_OPERATING_DOCS = tuple(_iter_operating_docs())` at module load (model B — preserves the test's monkeypatch seam). Apply R2 (`incident`→`\bincident\b`) + edit `test-validate-pack-check-65.sh`.
- Land the GC-3 (boundary-investigation project copy) + GC-4 (`backlog/_rules.md` `**BD-167 — <Title>**` K7-extension) allowlist records in `pack-ops/.operating-doc-history-allowlist.txt`.
- **Verify:** the §6.4 Axis-1 history sweep over the full IN set runs clean (`--only-check 65` exit 0 with the auto-discovered scope + the new GC records); Check 69 PASSes on the live tree; full battery green.

**CG-14-prep-b (`pack-only`) — the content gates (Checks 66/67/68) bodies + allowlists + Gate-1 parameters + the dangling-ref fix.**
- Author **Check 66** (Gate 1b) body + `_CHECK_66_BULLET_CHAR_CAP` + its allowlist + `test-validate-pack-check-66.sh` (DYNAMIC count form).
- Author **Check 67** (Gate 2) body + `_CHECK_67_DEFERRED_PATTERNS` + `pack-ops/.operating-doc-deferred-feature-allowlist.txt` (sized to the 4 KEEP categories; any unclassified hit = BLOCKER to user, R-1) + `_check_67_load_allowlist()` + `test-validate-pack-check-67.sh` (DYNAMIC).
- Author **Check 68** (Gate 3) body + `_CHECK_68_QUALIFIED_PATH_PATTERN` + `pack-ops/.dangling-ref-allowlist.txt` (sized to the measured KEEP set) + `test-validate-pack-check-68.sh` (DYNAMIC).
- **Fix the 1 genuine dangling ref** `feedback_review_fix_one_cycle.md` → `feedback_review_fix_cycle.md` at `CONCEPTUAL-REVIEW-METHODOLOGY.md:186` so Gate 3 is clean at activation.
- **Derive Gate-1 parameters from the measured reduced tree (D-4):** the 6 Check-44 FAIL ceilings (`ceil(measured_reduced × 1.15)` per doc, using the CB-01 IMPL-REPORT's recorded counts + HELP-PACK measured/unchanged); the Check-66 bullet char-cap (measure the max legitimate post-reduction bullet × headroom) + the over-cap allowlist (size to the measured residue). Flip Check 44's length branch advisory→FAIL (Gate 1a) + edit `test-validate-pack-check-44.sh` (add a FAIL-path case; value-agnostic mock).
- **Verify (measure-then-bound):** each new check runs CLEAN against the live (final reduced) tree via `--only-check NN` (registration-deferred dry form, §6.3); the §6.4 Axis-2 deferred-feature re-grep returns ZERO outside the KEEP set; the dangling-ref fix lands (grep-zero for `feedback_review_fix_one_cycle`); full battery green.

**CG-14 (`pack-only`) — ACTIVATION + the atomic count bump.**
- Register all 4 new checks in `CHECK_REGISTRY`: append `(66, "check_operating_doc_bullet_concision", …, W)`, `(67, "check_operating_doc_no_deferred_feature", …, W)`, `(68, "check_dangling_file_refs", …, W)`, `(69, "check_operating_doc_scope_completeness", …, W)` (S2).
- **Bump `CHECK_REGISTRY_EXPECTED_COUNT` 63 → 67** (S1); update the comment ledger (S3) + reconcile the stale prose "62"→67 (S3b); **edit `test-validate-pack-check-64.sh` literal `63`→`67` + its pass-message (S4)** — the load-bearing item-2 edit.
- Confirm Check 65 enforces over the full auto-discovered IN set (the C-SNIP-4 re-verification); confirm Gate 1a FAIL ceilings + Check 66 cap are live; confirm Checks 67/68/69 enforce.
- **Verify:** the FULL wired battery green (§8) — Check 59 auto-asserts count==67; Check 60 auto-derives the shard partition; check-64's test passes with `67`; all new per-check tests pass.

### 6.3 The registration-deferral mechanism (why -a/-b author bodies but CG-14 registers)

A check that is AUTHORED (function defined, constant defined, test file present) but NOT yet in `CHECK_REGISTRY` does NOT run in the no-flag battery and does NOT count toward `len(_build_check_registry())` — so the count stays 63 and Check 59 stays green through CG-14-prep-a/-b. The check's body is still EXERCISABLE in -a/-b via its per-check test's synthetic + `--only-check NN` legs (the test can import the module and call the function directly even when unregistered, matching the existing per-check test pattern that monkeypatches REPO_ROOT). This keeps every intermediate commit GREEN (validate-pack.py passes throughout) while the count bump + all 4 registrations land ATOMICALLY at CG-14 — ONE commit, ONE chance to get S1+S2+S4 right, verified by the full battery before the patch. **This is the deliberate design that makes "validate-pack.py must pass at every intermediate step" hold while concentrating the fragile count-bump into a single reviewed commit.**

**Alternative considered + rejected:** register-as-you-go (each gate commit bumps the count by its own +N). REJECTED — it creates THREE count-bump events (three chances for the S1/S2/S4 lock-step to drift, and the recent CI failure was exactly an S-axis drift), and it forces check-64's hardcoded literal to be edited multiple times. One atomic bump at CG-14 is the lower-risk path.

### 6.4 The two-axis sweep (the deferred-feature completeness backstop)

Run at CG-14-prep-a (Axis 1) and CG-14-prep-b (Axis 2), over the full IN set on the post-bloat tree:
- **Axis 1 — Check-65 history sweep:** with the auto-discovered scope live, `python3 scripts/validate-pack.py --only-check 65` exit 0 (every history hit allowlist-covered, incl. the new GC-3/GC-4 records + the R2 tightening). Any uncovered hit = a residue a bloat reword introduced or a gate-completeness miss → FIX.
- **Axis 2 — deferred-feature re-grep:** the CENSUS §1 vocabulary over the full IN set; expect ZERO hits outside the CENSUS §5 KEEP set. This is the recall gate over the bloat re-touches AND the D-1 strip's completeness check (PLATFORM-SKILLS must be clean post-CB-08). Any hit not in §5 KEEP = a BLOCKER to the user (R-1; never auto-allowlisted).

### 6.5 The gate-completeness records (carried from V2 §6.2)

- **GC-1/GC-2 (false-positives)** — "individual incidents" (PACK-FEEDBACK:59) + "not coincidental" (reviewer.md:128) — KILLED by R2 `\bincident\b`; no allowlist record needed.
- **GC-3 (legitimate KEEP)** — "The audit incident (P-missed-7)" (`project-template/skills/boundary-investigation/SKILL.md:33`, PROJECT copy only; pack copy clean) — survives R2 (whole word) → needs a K-extension allowlist record (doc + pattern `incident` + snippet `The audit incident (P-missed-7)` + reason). Lands at CG-14-prep-a.
- **GC-4 (legitimate KEEP)** — `backlog/_rules.md:35` `**BD-167 — <Title>**` (bd-tag; the existing K7 snippet `BD-167.md` does NOT substring-match `BD-167 —`) → needs a K7-extension record (snippet `**BD-167 — <Title>**` + reason). Lands at CG-14-prep-a.


---

## 7. THE SNIPPET-STABILITY CONTRACT (C-SNIP — binding; load-bearing because CG-14 activates AFTER bloat)

Check 65 clears an allowlisted line ONLY when its `snippet:` is a SUBSTRING of that line (`(doc, snippet-substring)`; line numbers NOT used). A bloat reword that alters an allowlisted line so the snippet no longer matches makes the forbidden token resurface UNCOVERED → CG-14 turns RED at activation. Every bloat reword on a doc carrying allowlisted lines MUST keep every snippet substring matchable.

**C-SNIP-1 — Inventory per bloat commit (37 records @ `103cca8`, per-doc counts measured):**

| Bloat commit | File | Allowlisted snippets that must stay matchable |
|---|---|---|
| CB-01 | `pack-ops/OPTIONAL-FEATURES.md` | `DESIGN-BD-225-GRAPHIFY-PACK-INTEGRATION.md` (K13) |
| CB-01 | `pack-ops/PACK-CHAT.md` | 2 PACK-CHAT records |
| CB-01 | `pack-ops/PACK-AGENTS.md` | 1 PACK-AGENTS record |
| CB-02 | `pack-ops/PACK-MEMORY-RATIONALE.md` | 6 RATIONALE records |
| CB-03 | `backlog/_rules.md` | `BD-167.md` (K7), `^BD-\d+\.md$` (K7) — AND after CG-14-prep-a, the new `**BD-167 — <Title>**` K7-extension (GC-4) |
| CB-06 | `CLAUDE.md`/`AGENTS.md`/`GEMINI.md` (pack) | 5 records each (K1 `until BD-206`, K2/K3 doc-refs, K12 rule self-ref ×2) |
| CB-07 | `project-template/{CLAUDE,AGENTS,GEMINI}.md` | 2 records each (K12 rule self-ref) |
| CB-08 | `project-template/docs/pack/PACK-FEEDBACK.md` | `Status: Ready (2026-06-15)` (K11) |
| CB-08 | `project-template/docs/project/changelog/_format.md` | 2 date-format records (K9) — do NOT reword the example lines |
| CB-08 | `project-template/docs/project/changelog/_rules.md` | 1 date-format record (K10) |

**C-SNIP-2 — Preserve OR co-update.** EITHER (a) leave the snippet substring verbatim in the reworded line (PREFERRED — stable tokens: filenames, dates, rule-self-ref phrases), OR (b) update the matching record's `snippet:` in the SAME commit. **SCOPE HAZARD:** the allowlist is `pack-ops/` (pack-only). For CB-07/CB-08 (project-only) a (b) co-update breaks `project-only` (Check 36) → those MUST use (a) verbatim-keep. For CB-01..CB-06 (pack-only) a (b) co-update stays in-scope.

**C-SNIP-3 — Coder PREFLIGHT dry-activation probe.** Before each bloat commit's IMPL-REPORT, the coder temporarily sets `_CHECK_65_OPERATING_DOCS` to JUST the touched files, runs `--only-check 65`, expects exit 0 (every snippet still matches; no residue), then REVERTS the probe (NO commit of the probe — agents never commit; local read-only verification, discarded).

**C-SNIP-4 — CG-14 activation re-verification.** At CG-14, with the auto-discovered scope live, re-run the §6.4 Axis-1 sweep over the full IN set and confirm `--only-check 65` exits 0. The single authoritative activation gate over the final state.

**New gates' allowlist authoring (measure-then-bound, R-1):** the 3 new allowlist files (`.operating-doc-deferred-feature-allowlist.txt`, `.dangling-ref-allowlist.txt`, and the Check-66 bullet allowlist) are sized EXACTLY to the measured KEEP sets at CG-14-prep-b. No category is widened to admit an unclassified hit; any unclassified occurrence = a BLOCKER surfaced to the user (the prohibited widen-to-admit move is forbidden per ci-guard-measure-then-bound).

---

## 8. PER-COMMIT VERIFICATION PLAN — the FULL wired battery (verify-full-ci-suite)

**The lesson from the recent CI failure: per-commit verification MUST run the FULL wired battery, not a subset.** The prior failure reached CI precisely because per-commit verification ran a partial check set and missed a count-encoding surface. Every commit in this plan (CB-01..CB-09, CG-14-prep-a, CG-14-prep-b, CG-14) verifies with the FULL battery BEFORE its patch is produced:

1. **The full CI battery, in the same partition CI runs:** `python3 scripts/ci-shard-plan.py` (the shard planner CI uses) executed across ALL shards, plus `python3 scripts/validate-pack.py` (no-flag full run = every registered check), plus the relevant per-check tests (`scripts/tests/test-validate-pack-check-*.sh`) — INCLUDING the count-invariant tests (`test-validate-pack-check-62/63/64.sh` + `test-validate-pack-checks-58-59-60.sh`) on the gate commits. The coder PREFLIGHT line asserts the full battery PASS, not a validate-pack-only PASS.
2. **The method's substantive proof (by surface):**
   - **Skills/agent-defs (CB-04, CB-05, CB-09 skills):** the A.5 contract — invariant-set diff EQUAL + example-removal justification log + retention spot-check + frontmatter intact.
   - **OPTIONAL-FEATURES (CB-01):** the §3.2 protected-content proof — Check-54 trio survives (`--only-check 54` exit 0); fenced blocks byte-unchanged; K13 snippet verbatim; FLAG-2a applied; the §5 ceiling reduce-then-re-derive recipe in PREFLIGHT; record all 6 durable-doc `measured_reduced_lines`.
   - **All other docs:** the C.3 clause-set-diff (set-equality modulo flagged padding; C.2 clause-preserving for any rule >~800 chars — hardest on CB-06 `graph-first-context` 5024c + 5 rules >1200c).
   - **D-1 PLATFORM-SKILLS (CB-08, WU-PLATSKILLS-D1):** grep-zero for the deferred-skill advertisement patterns; the on-demand guardrail survives.
3. **Snippet-stability probe (C-SNIP-3)** for any file in the §7 table.
4. **Trinity/tri-family parity (enumerate-encoding-surfaces):** CB-06/CB-07 byte-parallel across the 3 trinity files at each location, MODULO the sanctioned Claude-only asymmetries (the `### Sub-agent behavior (Claude-only)` block — pack CLAUDE.md only — + Trinity-exempt notes); CB-09 identical substance ×3 per role.

**Gate-wave verification specifics:**
- **CG-14-prep-a:** Axis-1 history sweep clean over the full IN set with auto-discovered scope; Check 69 PASS on the live tree; R2 test green; GC-3/GC-4 records verified by the Axis-1 sweep; full battery green (count still 63 — checks 66-69 unregistered).
- **CG-14-prep-b:** each new check CLEAN against the live reduced tree via `--only-check NN`; Axis-2 re-grep ZERO outside KEEP; dangling-ref fix grep-zero; Gate-1 parameters derived + Check 44 FAIL flip; the 6 FAIL ceilings verified against the reduced docs (each doc UNDER its new FAIL ceiling); full battery green (count still 63).
- **CG-14:** the ATOMIC count bump (S1+S2+S3+S3b+S4) — full battery green with count==67; Check 59 asserts count==67; Check 60 shard partition includes 66-69; `test-validate-pack-check-64.sh` passes with `67`; all 4 new per-check tests pass; C-SNIP-4 activation re-verification; Check 65 enforces over the full IN set.

**ci-check-runtime-compounding (the 4 new checks ×~155 invocations):** the architect's cheap design holds — Check 66 reads 5 bullet files once (O(lines)); Check 67 one alternation-scan per IN line (shares Check 65's read); Check 68 reuses Check 40's once-built basename index (near-free); Check 69 reads NO file bodies (path glob + set arithmetic). R2 narrows an existing pattern (same compile-cost). NO whole-tree-scan-per-entry; NO subprocess storm. The plan adds NO expensive verification. Confirmed cheap.

**Bounded review/fix cycle per commit:** ≤2 review/fix pairs + 1 final reviewer = 3 reviewer / 2 fix-coder spawns max per commit; if dirty after the final reviewer, STOP and spawn pack-architect (no fix-coder pass 3).

---

## 9. THE FINAL PUSH (after CG-14 lands, CI-green locally)

1. Run `bash scripts/manifest-sync.sh` (push-time, tool-enforced). Doc + validate-pack + test edits do NOT change fixture INPUTS, so expect NO manifest churn (exit 0). If a fixture input did change (it should not in this plan), exit 10 → commit the regenerated `test-fixtures/manifest.txt` with user approval.
2. `git push` (the ~remaining BD-243 commits as the unit).
3. Watch the `Validate Pack` CI run (`gh run list` / `gh run watch`) in the background; surface the verdict when it lands (background-long-waits — never foreground-block).

---

## 10. OPEN RISKS / UNKNOWNS

- **R-1 (deferred-allowlist sizing — BLOCKER discipline).** The Gate-2 allowlist (and the dangling/bullet allowlists) size EXACTLY to the measured KEEP sets at CG-14-prep-b. The `deferred`/`planned`/`future` hits are dominated by the 4 KEEP categories, but a few may need per-line adjudication. Any unclassified hit is a BLOCKER surfaced to the user — NEVER auto-allowlisted (the prohibited widen-to-admit move). MITIGATION: the D-1 strip removes the largest unclassified cluster (PLATFORM-SKILLS) at CB-08, shrinking the residue the gate-wave coder must classify.
- **R-2 (count-bump lock-step — the repeat-CI-failure risk).** S1+S2+S4 must land atomically at CG-14; check-64's HARDCODED `63` is the load-bearing miss-risk. MITIGATION: the registration-deferral mechanism (§6.3) concentrates the bump into ONE commit; the full-battery PREFLIGHT (§8) exercises check-64's test BEFORE the patch; the new tests use the DYNAMIC form to avoid minting a new trap. RESIDUAL: low IF §2 is followed; this is the single highest-attention item for the CG-14 coder + reviewer.
- **R-3 (Gate 3 + the out-of-repo memory-file family).** The dangling ref `feedback_review_fix_one_cycle.md` points at a curated-memory file that lives OUTSIDE the repo tree (`~/.claude/projects/<slug>/memory/`). The FIX is to correct the name to `feedback_review_fix_cycle.md`. But Gate 3's existence check must not then FAIL on the corrected name (which also has no in-repo target). MITIGATION: the CG-14-prep-b coder decides Gate 3's resolution rule for the memory-file family (allowlist the family pattern with a reason, OR the corrected ref is in prose that Gate 3's scope/anchor mechanism already clears). The architect's design treats such refs via the anchor-phrase / curated-allowlist mechanism; the coder sizes it measure-then-bound. SURFACE to the user if the resolution requires a judgment.
- **R-4 (project-only commits + allowlist co-update conflict, CB-07/CB-08).** C-SNIP-2(a) verbatim-keep is mandatory for project-only commits; if a reword genuinely must change a snippet, drop the `project-only` keyword (neutral subject) rather than carry a false claim. RESIDUAL: low — the project-side snippets are stable date/status/rule-self-ref tokens.
- **R-5 (skill invariant-set-diff judgment, CB-04/CB-05/CB-09b).** The A.5 invariant-set diff requires consistent enumeration across baseline + post-bloat; medium risk on the largest technical skills (python-observability 527, swift-concurrency 418) where most lines are S-test-passing — which is exactly why expected reduction is MODEST; an over-zealous coder is caught by the invariant-set diff (BLOCKER on any asymmetric loss).
- **R-6 (stale graph).** The graph is STALE for BD-243-era surfaces (DESIGN/CENSUS EE-GRAPH). Discovery used the graph then fell to grep/`wc -l` (G2). ALL sizing + the count-bump enumeration are `grep`/`wc -l`-authoritative. No residual — the gate is the file read, not the graph.
- **R-7 (Gate 1 parameter timing, D-4).** Gate 1 ceilings/caps derive at CG-14-prep-b from the reduced tree; they CANNOT be finalized before the bloat wave lands. Confirmed dependency; the plan orders it correctly. If the user wanted Gate 1 to land before the bloat wave, it could only be the existing advisory until reduction (cannot FAIL on bloated numbers) — but D-4 = FAIL at the gate wave is the user's decision.

---

## 11. CONSOLIDATED DEPENDENCY-ORDERED SEQUENCE (the scheduler's map)

```
[BLOAT WAVE — all base on 103cca8; gate inert]
  CB-01 (pack-only)   pack-ops bloat + FLAG-2a + 2 hist-narr + OPTIONAL ceiling re-derive   ┐
  CB-02 (pack-only)   RATIONALE                                                              │ parallel
  CB-03 (pack-only)   pack stream-meta                                                       │ across
  CB-04 (pack-only)   pack skills (S-test)                                                   │ distinct
  CB-05 (pack-only)   pack agents (S-test)                                                   ┘ files
  CB-06 (pack-only)   pack trinity (trinity-locked ×3)        ┐ ∥ each other (disjoint)
  CB-07 (project-only) project trinity (trinity-locked ×3)    ┘
  CB-08 (project-only) project docs/pack + prompts + stream-meta + D-1 PLATFORM-SKILLS strip ┐ parallel
  CB-09 (project-only) project agent-defs (tri-family) + project skills (S-test)             ┘ [split CB-09a/b opt]
        │  (ALL CB-01..CB-09 must land before the gate wave)
        ▼
[GATE WAVE — bases on the bloat-reduced tree]
  CG-14-prep-a (pack-only)  _iter_operating_docs() + EXEMPT + Check 69 body + Check-65 repoint
                            + R2 incident-tighten + GC-3/GC-4 records  [count still 63; checks unregistered]
        │
  CG-14-prep-b (pack-only)  Checks 66/67/68 bodies + 3 allowlists + Gate-1 params from reduced tree
                            + Check-44 advisory→FAIL + dangling-ref fix  [count still 63; checks unregistered]
        │
  CG-14 (pack-only)         ATOMIC: register 4 checks + count 63→67 (S1+S2+S3+S3b+S4)
                            + activate Check 65 over full IN set + full battery green
        │
        ▼
[FINAL PUSH]  manifest-sync (expect exit 0) → git push → watch Validate Pack CI (background)
```

**BD-243 scope coverage (deferral-is-scope-creep — all of it LANDS):** bloat reduction (CB-01..CB-09) ✓; the 4 durable gates (Checks 66/67/68/69 + Gate 1a hardening + R2) ✓; surfaced fix 1 = D-1 PLATFORM-SKILLS catalog strip (CB-08 WU-PLATSKILLS-D1) ✓; surfaced fix 2 = the `feedback_review_fix_one_cycle.md` dangling ref (CG-14-prep-b) ✓; the carried cleanup items (FLAG-2a, 2 history-NARRATIVE strips, GC-1..GC-4) ✓. Nothing deferred.

---

## 12. EMPIRICAL-EVIDENCE BLOCK (consolidated)

All measurements @ HEAD `103cca8` (`103cca8e51feef9c80e4e76be17bd0dd274d3a6b`), branch `v11-dev`, 2026-06-22, repo `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`, clean tree. Graph queried for discovery; STALE for BD-243-era surfaces (per DESIGN/CENSUS EE-GRAPH) → G2 fallback to `grep`/`wc -l`/`git`/`python3 validate-pack.py` for every exact-state claim. The authoritative gate for sizing + the count-bump enumeration is `grep`/`wc -l`.

- **EE-BASE** (§1) — HEAD `103cca8`; clean tree; `CHECK_REGISTRY_EXPECTED_COUNT = 63`; `_CHECK_65_OPERATING_DOCS = ()`; next free check numbers 66-69; `python3 scripts/validate-pack.py` = PASSED (exit 0). SUPPORTED.
- **EE-COUNT** (§2) — count-encoding surfaces: ONLY `test-validate-pack-check-64.sh:74-75` hardcodes the literal `63` (the item-2 load-bearing edit `63`→`67`); `test-validate-pack-check-62/63.sh` + `checks-58-59-60.sh` use the DYNAMIC `len(_build_check_registry()) != EXPECTED_COUNT` form (no edit); the EXPECTED_COUNT comment prose says a STALE "62" while the arithmetic + constant = 63. Cmd: `grep -rnE "CHECK_REGISTRY_EXPECTED_COUNT|!= 63|== 63|FAIL_COUNT_NOT|_build_check_registry\(\)" scripts/validate-pack.py scripts/tests/*.sh`. SUPPORTED.
- **EE-D1** (§4.3) — PLATFORM-SKILLS deferred catalog: `503:### Deferred skills (create when project need arises)` + 16 inline `*(deferred)*` tags (L68/69/71/72/73/101/102/137/138/139/155/156/157/158/159 + L506 back-ref) + the L503-527 roll-up. Cmd: `grep -nF "Deferred skills" …; grep -cF "(deferred)" …; sed -n '503,527p' …`. SUPPORTED.
- **EE-DANGLE** (§6.1 Gate 3) — the 1 genuine dangling ref: `CONCEPTUAL-REVIEW-METHODOLOGY.md:186` "Review/fix cycles per BD AND per batch (per `feedback_review_fix_one_cycle.md`)" — the correct name is `feedback_review_fix_cycle.md` (no "one"); target is an out-of-repo curated-memory file. Cmd: `grep -n "feedback_review_fix_one_cycle" pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md; sed -n '186p' …`. SUPPORTED.
- **EE-CEIL** (§5) — `271 = ceil(235×1.15)`; 235 baseline pre-dates graphify (now 544); `_CHECK_44_DURABLE_DOCS` = 6 rows (BOUNDARY 135, CONCEPTUAL 298, DRY-RUN 199, HELP-PACK 48, MERGE 484, OPTIONAL 235→271); only OPTIONAL over (ADVISORY); test mock-parameterized (no value edit). Cmd: `sed -n '7746,7763p' …; --only-check 44`. SUPPORTED.
- **EE-REGTAIL** (§6.2) — the `CHECK_REGISTRY` tail entries 62/63/64/65 follow the `(NN, "check_name", check_name, W)` tuple shape with a preceding comment block; the EXPECTED_COUNT comment ledger (validate-pack.py:475-496) carries the per-BD `+1 net-new` lines + the "number ≠ count" CAUTION. Cmd: `sed -n '10320,10345p' …; sed -n '464,496p' …`. SUPPORTED.
- **EE-INSET (carried)** — operating-doc IN set = 135 files @ `103cca8` (DESIGN EE-INSET). SUPPORTED (carried; not re-measured — the gate-wave coder re-verifies via `_iter_operating_docs()` at CG-14-prep-a).
- **EE-G2-PLAT / EE-G3-BARE (carried)** — PLATFORM-SKILLS 22 deferred + 7 future (the Gate-2 census MISS, resolved by D-1 at CB-08); 1 genuine bare-ref dangling (`feedback_review_fix_one_cycle.md`, resolved at CG-14-prep-b). SUPPORTED (carried from DESIGN; the two load-bearing facts independently re-verified here as EE-D1 + EE-DANGLE).

---

## 13. RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **agents-never-commit** | Only read-only verbs run: `git rev-parse HEAD` / `git branch --show-current` / `git status --short` (snapshot), `wc -l`, `grep`/`grep -rn`, `sed`, `ls`, `find`, `python3 scripts/validate-pack.py` (read-only validation). Sole write = this plan doc via `cat >>`/`cat >` to the caller-specified `/tmp/pack-handoff-bd243-plan/PLAN-BD-243-FINAL-V3.md`. No repo-file edit; no patch; no `git add`/`commit`/`apply`/state-changing verb. | COMPLIANT |
| **reconciliation-instance-independence** | FRESH planner; did NOT author the prior PLAN-V1/-V2, the DESIGNs, or the CENSUS. Reached own conclusions: independently re-measured the count-encoding surfaces and FOUND the exact hardcoded-literal trap (check-64:74-75) vs the dynamic tests (check-62/63), plus the STALE prose "62" (a NEW finding — S3b); independently verified the D-1 catalog (16 tags + the L503 roll-up) + the dangling-ref line 186; reached my own gate-commit partition (3 commits with the registration-deferral mechanism, §6.3) rather than copying the architect's CG-14-prep-a/-b sketch wholesale; reached my own D-1 fold-into-CB-08 decision with the alternative rejected (§4.3). Folded the architect method + the user decisions without relitigating. | COMPLIANT |
| **planner-output-user-review** | Marked PLANNER-READY (header + §0); NOT auto-approved into a coder spawn; §0 one-line decision-ready answers + per-section detail; D-1..D-4 + R2 encoded with the open user-surfaced items (R-1 unclassified BLOCKERs, R-3 memory-file resolution) flagged for the user. The planner-to-coder gate is the user's last cheap redirect window. | COMPLIANT |
| **enumerate-encoding-surfaces** | §2 enumerates EVERY count-encoding surface (S1 constant, S2 four registry entries, S3 comment ledger, S3b stale prose, S4 hardcoded-literal test, S5 Check 59, S6 Check 60) with file:line + required value + miss=CI-failure flag; identifies the load-bearing trap (check-64:74-75 hardcoded `63`) and the dynamic tests that need no edit; §5 enumerates the ceiling lock-step surfaces; §6.1/6.2 enumerate per-gate body+constant+allowlist+test+registry+count+comment. This is the load-bearing application; the recent CI failure was exactly this miss. | COMPLIANT |
| **verify-full-ci-suite** | §8 specifies the FULL wired battery (`ci-shard-plan.py` all shards + `validate-pack.py` no-flag + the per-check tests incl. the count-invariant tests) per commit, BEFORE the patch; the coder PREFLIGHT asserts full-battery PASS not validate-pack-only; the gate-commit verification explicitly exercises `test-validate-pack-check-64.sh` (the S4 surface) so an S4 miss is caught pre-patch. | COMPLIANT |
| **empirical-evidence-blocks** | Every state-claim backed by EE-BASE/COUNT/D1/DANGLE/CEIL/REGTAIL (+ carried EE-INSET/G2-PLAT/G3-BARE): command + verbatim output (counts/paths/quotes) + HEAD `103cca8` + 2026-06-22 + interpretation + SUPPORTED. The count-bump enumeration (the item-2 load-bearing claim) is grep-authoritative (EE-COUNT); sizing via `wc -l`/`grep`; the registry structure via `sed`. | COMPLIANT |
| **ci-check-runtime-compounding** | §8 confirms the architect's cheap design holds for all 4 new checks ×~155 invocations: Check 66 reads 5 files once; Check 67 one alternation-scan/line (shares Check 65's read); Check 68 reuses Check 40's once-built index; Check 69 reads no bodies (glob + set arithmetic); R2 narrows an existing pattern (no added pattern). NO whole-tree scan, NO subprocess storm, NO expensive verification added. | COMPLIANT |
| **deferral-is-scope-creep** | §11 BD-243 scope coverage: bloat (CB-01..CB-09) + 4 gates + both surfaced fixes (D-1 strip at CB-08; dangling ref at CG-14-prep-b) + the carried cleanup (FLAG-2a, 2 hist-narr, GC-1..GC-4) ALL planned to LAND. Nothing hand-waved; the two-axis sweep is the completeness backstop. | COMPLIANT |
| **graph-first-context** | Discovery used graph-first intent via the injected absolute path; STALE for BD-243-era surfaces (DESIGN/CENSUS EE-GRAPH) → G2 fallback to `grep`/`wc -l`/`git`/`python3 validate-pack.py` IMMEDIATELY for every exact-state claim; the count-bump surface enumeration is grep-authoritative per the prompt; did not block on the graph; did not recompute the graph path from own toplevel. | COMPLIANT |
| **rules-applied-verification-block** | This table — every rule in the prompt's Rules-in-force block has measured/quoted evidence + a terminal COMPLIANT conclusion (no empty evidence; no AMBIGUOUS). | COMPLIANT |

**END — PLAN-BD-243-FINAL-V3.md**
