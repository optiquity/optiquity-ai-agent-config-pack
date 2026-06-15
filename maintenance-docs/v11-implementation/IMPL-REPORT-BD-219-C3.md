# IMPL-REPORT — BD-219 C3 (CI-runtime upkeep guards + shard-plan infrastructure)

**Agent:** fresh pack-coder · **BD:** BD-219 commit **C3** · **Scope keyword:** `pack-only`
**Date:** 2026-06-15 · **Plan SSOT:** `maintenance-docs/v11-implementation/PLAN-BD-219-CI-RUNTIME-OPTIMIZATION.md` §C3 + §1; `…/ARCHITECTURE-BD-219-CI-RUNTIME-OPTIMIZATION.md` §2.3/§2.5/§5/§5.2/§6.3/§6.4.

---

## 1. REGIME BLOCK (runtime-verified, not trusted from settings)

| Probe | Value |
|---|---|
| `pwd` / `git rev-parse --show-toplevel` | `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a67d4a6a7417e769d` |
| Main checkout | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev` |
| **REGIME** | **ISOLATED** (toplevel is a `.claude/worktrees/` worktree ≠ the main checkout) |
| `git rev-parse HEAD` (start) | `3afccec3b780e68e36d2b8605dd205bd78a793e4` |
| `git rev-parse HEAD` (final) | `3afccec3b780e68e36d2b8605dd205bd78a793e4` (unchanged — agents never commit) |
| HEAD == required `3afccec` (parent local HEAD with BD-219 C1)? | **YES** — not mis-based |
| `git status --short` (start) | clean |
| Branch | `v11-dev` |

**Merge-back handoff (isolated regime):** `/tmp/handoff-bd219-c3/`
- `c3-modified.patch` ← `git diff HEAD` (read-only patch-emit; covers the 3 MODIFIED tracked files)
- `newfiles/<relpath>` ← `cp -p` of each of the 5 NEW files (exec bits preserved)
- `IMPL-REPORT.md` ← this report
- Worktree NOT deleted. No git state-changing verb was run.

---

## 2. FILES CHANGED INVENTORY (for the orchestrator)

**Apply order for the orchestrator:** `git apply c3-modified.patch` (the 3 modified files), then `cp` each `newfiles/<relpath>` into the same relative path in the work tree (the 3 `.sh`/`.py` files are already executable in `newfiles/`; preserve the bit with `cp -p`).

### MODIFIED (3) — in `c3-modified.patch`
| Path | Change type | Summary |
|---|---|---|
| `scripts/validate-pack.py` | modified | Generalize Check 42 to full set-equality; add Checks 58/59/60 functions; add `CHECK_REGISTRY_EXPECTED_COUNT = 60` constant; register 3 new checks in `_build_check_registry()` |
| `.github/workflows/validate-pack.yml` | modified | Wire 8 KEEP tests + 2 new guard-test scripts; relabel the Check 42 step name |
| `scripts/tests/test-validate-pack-check-42.sh` | modified | Lock-step update for the generalized Check 42 (new banner/message/invariant; allowlist + scripts-root coverage; new staleness test) |

### NEW (5) — in `newfiles/`
| Path | Exec? | Summary |
|---|---|---|
| `scripts/lib/ci-shard-plan.py` | yes (`rwxr-xr-x`) | Single-source CI shard partition: parse wired set, LPT bin-pack, `--emit-matrix` / `--assert-coverage` / `--shard N --needs-fixtures` / `--print-partition`; fixture cohesion-group pinning |
| `scripts/ci-shard-weights.tsv` | no | `<script-path>\t<measured_seconds>` per wired test (research §1.2 heavies + representative weights) |
| `scripts/ci-test-wiring-allowlist.txt` | no | Measure-then-bound STRIP set — EXACTLY 1 entry (the bd204 live-GH oracle) |
| `scripts/tests/test-validate-pack-checks-58-59-60.sh` | yes (`rwxr-xr-x`) | Red+green tests for Checks 58/59/60 |
| `scripts/tests/test-ci-shard-plan.sh` | yes (`rwxr-xr-x`) | Tests for the shard-plan module (emit-matrix, assert-coverage red/green, needs-fixtures, graceful degradation, parse-equivalence with Check 42) |

**Manifest:** ran `bash test-fixtures/build.sh --all --clean`; `git status --short test-fixtures/manifest.txt` → **EMPTY** → manifest NOT staged (C3 changes no fixture content). `regenerate-manifest-v11-surface` satisfied (run+checked; diff empty).

---

## 3. MEASURE-THEN-BOUND TABLE (re-measured; DISAGREES with architecture §5.2)

Measured at HEAD `3afccec`. `ls scripts/test*.sh scripts/tests/*.sh` = **70 disk**; wired (pre-C3) = **61**; unwired = **9**; reverse-drift = **0** — matches architecture §EE-3 exactly.

Each of the 9 unwired scripts was CONFIRMED by reading its header AND **run offline** (run-before-wire):

| Script | Architecture §5.2 prelim | **My re-measure** | Evidence (offline run) | Disposition |
|---|---|---|---|---|
| `scripts/test-compare-agent-trinity.sh` | CONFIRM→KEEP | **KEEP** | EXIT 0; offline unit (synthetic temp trios) | WIRED |
| `scripts/test-dry-run-migration.sh` | CONFIRM→KEEP | **KEEP** (fixture-dep) | EXIT 1 w/o fixtures (T1 needs `v10-realistic-ot`); **EXIT 0 with fixtures** | WIRED + cohesion group |
| `scripts/test-restore-from-backup.sh` | CONFIRM→KEEP | **KEEP** | EXIT 0; offline unit (temp dirs) | WIRED |
| `scripts/tests/test-activate-capability.sh` | CONFIRM→KEEP | **KEEP** | EXIT 0; self-provisions scratch via mktemp+init-project | WIRED |
| `scripts/tests/test-add-capability.sh` | CONFIRM→KEEP | **KEEP** (fixture-dep) | EXIT 0 (SKIPs grp2 w/o `v11-flat-file`); **EXIT 0 with fixtures** | WIRED + cohesion group |
| `scripts/tests/test-tracker-promote-direct.sh` | **STRIP (live-GH)** | **KEEP** ⚠ | EXIT 0; **STUB backend** (`_TRACKER_PROVIDER_BACKEND_OVERRIDE=stub`); grep: ZERO live `gh` calls | **WIRED** |
| `scripts/tests/test-tracker-promote-path1.sh` | **STRIP (live-GH)** | **KEEP** ⚠ | EXIT 0; stub backend; zero live `gh` | **WIRED** |
| `scripts/tests/test-tracker-promote-path2.sh` | **STRIP (live-GH)** | **KEEP** ⚠ | EXIT 0; stub backend; zero live `gh` | **WIRED** |
| `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` | STRIP (live, possibly manual) | **STRIP** | EXIT 0 but DEFAULT-SKIPs (`SKIP: live-GH oracle`); `gh repo create`s a real scratch repo under `PACK_TRACKER_LIVE_GH=1`; header HARD-mandates "NOT wired"; unit legs already wired elsewhere | **ALLOWLISTED** |

### ⚠ DISCREPANCY WITH ARCHITECTURE §5.2 (flagged per ci-guard-design-measure-then-bound)
The architecture's **preliminary** classification marked the 3 `test-tracker-promote-*.sh` as **STRIP (live-GH)**. My empirical re-measure (the architecture explicitly delegated final KEEP/STRIP to the coder — design §4.3) found they use a **stub backend and make ZERO live-gh calls** and pass offline. Per the rule "if your measurement disagrees with §5.2, follow your measurement and flag the discrepancy," I classified them **KEEP** and **WIRED** them. This is a coverage INCREASE (3 dormant tests now run on every push), fully compatible with the HARD effectiveness constraint (which forbids removing/weakening, not adding).

**Result:** KEEP = **8** (wired); STRIP = **1** (allowlisted, EXACTLY the bd204 oracle — not the architecture's preliminary 3). The allowlist is sized to exactly the confirmed STRIP set, no broader.

**Run-each-KEEP-green-BEFORE-wiring:** all 8 KEEP tests confirmed EXIT 0 offline (fixture-dependent ones with fixtures built) BEFORE wiring. No KEEP test bit-rotted; none required force-fixing or a dodge-allowlist. (No new BD candidate surfaced.)

### Post-wire set-equality (Check 42 invariant holds)
After wiring the 8 KEEP + the 2 new guard-test scripts:
- disk = **72** (70 + the 2 new guard-test files)
- allowlist (STRIP) = **1**
- disk_KEEP_set = 72 − 1 = **71**
- wired_set = **71**
- `disk_KEEP_set == wired_set` ✔ (Check 42 PASSes; FAILs if any KEEP unwired or allowlist stale — proven §5)

---

## 4. PER-FILE CHANGE DETAIL

### 4.1 `scripts/validate-pack.py` (modified; +365/−~80 region)

**(a) `CHECK_REGISTRY_EXPECTED_COUNT = 60`** — new constant near the budget
constants. COMPUTED, not assumed: registry held 57 entries at C1 (§EE-P5
re-confirmed: `awk '/return \[/,/^    \]/' | grep -c` → 57); C3 adds 3 net-new
checks → 60. Documented inline as the drift-prone bookkeeping constant
(updated like the agent-count check).

**(b) Generalized Check 42** (`check_ci_workflow_wires_per_check_tests`, by
symbol — never line number, `architect-doc-reality-reconciliation`). Was
set-equality over `scripts/tests/test-validate-pack-check*.sh` only; now full
set-equality `disk_KEEP_set == wired_set` where
`disk_KEEP_set = {scripts/test*.sh + scripts/tests/*.sh} − allowlist`,
`allowlist = scripts/ci-test-wiring-allowlist.txt`. FAILs on (a) any unwired
KEEP script AND (b) any allowlisted-but-now-wired script (staleness). New
banner: `── Check 42: CI workflow wires every CI-eligible test (BD-184, BD-219) ──`.
Cheap: one workflow-text regex + two dir globs + one small allowlist read.

**(c) Check 58** `check_validate_job_carries_no_only_check` — parses the yml;
FAILs if any `validate-pack.py` invocation line carries `--only-check` (the
authoritative run must run ALL checks). Cheap line-scoped regex.

**(d) Check 59** `check_check_registry_completeness` — the moved wiring proof
(restores the implicit "wired into main()" property C1's e2e legs dropped).
Asserts `len(_build_check_registry()) == CHECK_REGISTRY_EXPECTED_COUNT` AND
each entry is a 4-tuple with a unique label + callable fn. Builds the in-memory
registry once (no I/O, no subprocess).

**(e) Check 60** `check_ci_shard_coverage` — the convenience MIRROR: ONE
`subprocess.run([sys.executable, ci-shard-plan.py, --assert-coverage])`. The
authoritative run-time assertion is the C2 `tests-result` job — NOT duplicated
onto the ~24-spawn battery path (one bounded subprocess, routed through
`run_check`). Lenient SKIP if the module is absent.

**(f) Registry registration** — 3 new entries appended after Check 57 in
`_build_check_registry()`, numbers 58/59/60 (the next contiguous integers after
the highest wired check 57 — COMPUTED at wire time from the registry, NOT
hard-coded from the plan). Generalized Check 42 keeps its slot.

`subprocess` + `sys` already imported (lines 292/293) — no new import needed.

### 4.2 `.github/workflows/validate-pack.yml` (modified; +44/−~10)

- Wired 6 offline KEEP tests as plain `run: bash` steps (after the
  migrator-capability-translation step): `test-compare-agent-trinity.sh`,
  `test-restore-from-backup.sh`, `test-activate-capability.sh`,
  `test-tracker-promote-{direct,path1,path2}.sh`.
- Wired 2 fixture-dependent KEEP tests AFTER `persona contracts` (in the
  fixture cohesion zone, BD-163 order): `test-dry-run-migration.sh`,
  `test-add-capability.sh`.
- Wired the 2 new C3 guard-test scripts (after the Check 54 step):
  `test-validate-pack-checks-58-59-60.sh`, `test-ci-shard-plan.sh`.
- Relabeled the Check 42 step name to reflect the generalized scope.
- **ONLY plain sequential `run: bash` steps — NO matrix/shard structure**
  (that is C2). C2's dynamic partition reads the wired list and picks these up
  automatically. `scope-deliverables-to-the-ask`: did NOT start C2 or C4.
- No untrusted-input interpolation (static literal `bash scripts/...`); the
  PostToolUse GitHub-Actions security advisory does not apply.

### 4.3 `scripts/tests/test-validate-pack-check-42.sh` (modified; lock-step)

`enumerate-encoding-surfaces`: the ONLY surface asserting Check 42's printed
text (grep of all `scripts/` `.sh` confirmed no other surface — the
integration `test-v11-*` tests reference Check 32′/33/34 only, not 42). Updated:
new banner assertion, `disk_KEEP_set == wired_set` PASS phrase, new count
phrases (`N test script(s) on disk`, `M wired in workflow`), the synthetic
harness now builds scripts-root + tests/ + an allowlist + `run: bash scripts/...`
wiring, and a NEW staleness test (T6 allowlisted-but-wired). T1–T8 cover:
all-wired PASS, tests/ unwired FAIL, scripts-root unwired FAIL, multi-unwired
FAIL, allowlisted-STRIP-unwired PASS, allowlist-staleness FAIL, two lenient
skips. e2e leg uses `--only-check 42` (BD-219 C1) and asserts the new banner.

### 4.4 `scripts/lib/ci-shard-plan.py` (new; executable)

Stdlib-only (no PyYAML, no network). Parses the wired set from the yml with the
SAME `run:\s+bash\s+(scripts/[^\s]+\.sh)` anchor Check 42 uses (parse-equivalence
proven §5). LPT bin-packs the KEEP set (wired − allowlist) into N=4 shards; pins
the fixture cohesion group (`FIXTURE_COHESION_GROUP` — the 5 fixture-dependent
tests, a measured set) into one shard. Modes: `--emit-matrix`, `--assert-coverage`,
`--shard N --needs-fixtures`, `--print-partition`. Unknown/missing weight →
`DEFAULT_WEIGHT_S` (graceful). Lives in `scripts/lib/` (pack-side test infra; NOT
a client deliverable; NOT a runtime dependency of any pack OPERATION — invoked
only by CI + the validate-pack guard, so `dependency-direction-placement` holds;
NOT added to `_SANCTIONED_PACK_SIDE_SHIPPED`).

### 4.5 `scripts/ci-shard-weights.tsv` (new)

One row per wired test: heavy steps seeded from research §1.2 measured CI
durations (94/61/52/34/31/29/14/11/10/8 s); the rest carry representative
weights (~1–7 s). Data, not logic. Refresh procedure documented inline.

### 4.6 `scripts/ci-test-wiring-allowlist.txt` (new)

EXACTLY 1 entry: `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` with a
one-line reason. The §3 discrepancy (3 tracker-promote tests are KEEP not STRIP)
is documented inline.

### 4.7 New test scripts (4.4/4.5 covered above; the two test files)

`test-validate-pack-checks-58-59-60.sh` (red+green per check + e2e --only-check
legs) and `test-ci-shard-plan.sh` (module behavior + 3 broken-partition RED
cases + graceful degradation + parse-equivalence). Both executable.

---

## 5. VERIFICATION EVIDENCE (quoted exits + red→green proofs)

### 5.1 validate-pack general + deep
- `python3 scripts/validate-pack.py` → **EXIT 0** ("PASSED — all checks clean"); wall ~1.30 s (≪ 10 s total-run budget); no per-check WARN budget breach; no RUNTIME-BUDGET FAIL.
- `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` → **EXIT 0** ("PASSED — all checks clean").
- The pre-existing Check 48 WARN lines (removed-doc citations in changelog/backlog) are advisory-only and unrelated to C3.

### 5.2 New checks GREEN on real state (quoted OK lines)
```
OK: Check 42 — 72 test script(s) on disk; 1 allowlisted (intentionally-OUT); 71 KEEP; 71 wired in workflow; disk_KEEP_set == wired_set. CI workflow wiring is complete.
OK: Check 58 — no `--only-check` on any validate-pack.py full-run invocation in the workflow; the authoritative run executes all checks.
OK: Check 59 — CHECK_REGISTRY has 60 entr(y/ies) (== CHECK_REGISTRY_EXPECTED_COUNT); ... unique label + callable fn. The no-flag full run executes every registered check.
OK: Check 60 — ci-shard-plan.py --assert-coverage passed; union(shards) == wired_KEEP_set, pairwise-disjoint, fixture cohesion group co-located.
```

### 5.3 Red→green proofs (run-before-wire effectiveness; each guard FAILs on its violation)
| Guard | RED scenario | Result |
|---|---|---|
| Check 42 | unwired KEEP test (`test-detect.sh` step removed) | FAIL names `scripts/test-detect.sh` ✔ |
| Check 42 | stale allowlist (`test-detect.sh` allowlisted AND wired) | FAIL "Allowlist staleness" ✔ |
| Check 58 | `--only-check 1` added to the validate job | FAIL "carries `--only-check`" ✔ |
| Check 59 | `CHECK_REGISTRY_EXPECTED_COUNT` mutated to 99/+7 | FAIL count mismatch ✔ |
| Check 60 | shard-plan stub exits non-zero | FAIL "--assert-coverage FAILED" ✔ |
| `ci-shard-plan --assert-coverage` | (a) dropped script, (b) duplicated script, (c) cohesion split | each exits non-zero naming the drift ✔ |
All GREEN again on the real tree (0 failures).

### 5.4 ci-shard-plan module
- `--assert-coverage` → **EXIT 0**: "71 wired KEEP test(s) across 4 shard(s); union == wired_KEEP_set; pairwise-disjoint; fixture cohesion group co-located in one shard."
- `--emit-matrix` → **EXIT 0**, valid JSON, 4 non-empty disjoint shards, 71 scripts total (`json.load` + assertions pass).
- `--shard N --needs-fixtures` → shard 1 EXIT 0 (owns cohesion group); shards 2/3/4 EXIT 1. Exactly ONE fixture-owning shard.
- `--print-partition` → 4 balanced shards (~119 s each); fixture cohesion group (`test-v11-realistic-ot.sh`, `test-migrator-skills.sh`, `test-persona-contracts.sh`, `test-dry-run-migration.sh`, `test-add-capability.sh`) all in shard 1 [FIXTURE-OWNER].

Emitted matrix JSON (4 shards; full text available via `python3 scripts/lib/ci-shard-plan.py --emit-matrix`):
```
{"include":[{"shard":1,"scripts":"... 22 tests incl. the 5 cohesion-group members ..."},{"shard":2,"scripts":"... 14 ..."},{"shard":3,"scripts":"... 18 ..."},{"shard":4,"scripts":"... 17 ..."}]}
```

### 5.5 FULL WIRED BATTERY (verify-full-ci-suite — EVERY wired script, quoted exit)
Extracted the complete `run: bash` list from the yml (73 steps = 71 test scripts + `build.sh --all --clean` + `build.sh --verify`) and ran EACH in yml order:
- **71 / 71 test scripts → EXIT 0.**
- The 2 `test-fixtures/build.sh` steps: EXIT 0 when run with the repo root as cwd (the transient EXIT 127 in the batch loop was a stale-cwd artifact — a prior migration test `cd`s into a scratch dir; the build.sh file is present + executable + EXIT 0 verified directly).
- Heaviest test steps observed locally: persona-contracts 11 s, dry-run-migration 3 s, realistic-ot 2 s (the long-pole migration tests run in the same battery; all EXIT 0). No sampling — every step run.

### 5.6 New/updated guard tests (final confirmation)
- `bash scripts/tests/test-validate-pack-check-42.sh` → **EXIT 0** (PASS 4 / FAIL 0)
- `bash scripts/tests/test-validate-pack-checks-58-59-60.sh` → **EXIT 0** (PASS 7 / FAIL 0)
- `bash scripts/tests/test-ci-shard-plan.sh` → **EXIT 0** (PASS 10 / FAIL 0)

### 5.7 Manifest
`bash test-fixtures/build.sh --all --clean` → EXIT 0; `git status --short test-fixtures/manifest.txt` → EMPTY → NOT staged.

### 5.8 enumerate-encoding-surfaces sweep
`grep -rnE 'wires all per-check test files|zero unwired tests|per-check test file\(s\) on disk' scripts/ --include='*.sh'` → **0 hits** (old Check 42 text fully removed). No integration test pins Check 42/58/59/60 output. No surface hard-codes a registry count of 57 (only the new constant + the new test's dynamic assertion).

---

## 6. NEW CHECK NUMBERS (COMPUTED, not hard-coded)
- Highest wired/registered check at C3 start: **57** (registry numeric max = 57; registry length = 57).
- New checks assigned the next contiguous integers in author order: **58** (validate-no-flag), **59** (registry-completeness), **60** (shard-coverage mirror). Generalized Check 42 keeps **42**.
- `CHECK_REGISTRY_EXPECTED_COUNT` = **60** (57 + 3). Verified by `Check 59` against the actual `len(_build_check_registry())` and by the new test's `actual == EXPECTED` assertion.

---

## 7. PLAN DEVIATIONS
**One substantive deviation, fully justified + flagged (the measure-then-bound mandate REQUIRES following the re-measure):**
- **Allowlist sized to 1, not the architecture's preliminary 3+1.** The 3 `test-tracker-promote-*.sh` scripts are KEEP (offline stub backend, zero live-gh), not STRIP — see §3. They are WIRED. This is the `ci-guard-design-measure-then-bound` "follow your measurement; flag the discrepancy" path; the architecture explicitly delegated final KEEP/STRIP to the coder (design §4.3). Net effect: 3 more dormant tests now run on every push (coverage increase, HARD-constraint-compatible).

No other deviations. Did NOT start C2 (workflow matrix restructure) or C4. Did NOT touch branch protection (MOOT + RO). Did NOT modify any pack-chat-only file, BD status, or out-of-scope surface.

## 8. NEW POQs INTRODUCED
None. (The §3 discrepancy is resolved in-report by following the measurement, not deferred.)

---

## 9. DEFINITION-OF-DONE CHECKLIST

| Item | Status | Evidence |
|---|---|---|
| `scripts/lib/ci-shard-plan.py` created (parse wired set, LPT, emit-matrix, assert-coverage, needs-fixtures, cohesion pinning, portable, no network) | **PASS** | §4.4, §5.4 |
| `scripts/ci-shard-weights.tsv` created (per wired test; measured heavies + default fallback) | **PASS** | §4.5 |
| `scripts/ci-test-wiring-allowlist.txt` created (STRIP set sized EXACTLY) | **PASS** | §3, §4.6 (1 entry) |
| Check 42 generalized to full set-equality with allowlist | **PASS** | §4.1(b), §5.2 |
| KEEP §5.2 tests CONFIRMED + WIRED so set-equality holds | **PASS** | §3 (8 KEEP wired), §5.2 (Check 42 OK) |
| New checks at next available numbers after 57 (COMPUTED, not hard-coded) | **PASS** | §6 (58/59/60) |
| Check 58 (full validate run carries no `--only-check`) | **PASS** | §4.1(c), §5.3 |
| Check 59 (registry-completeness, restores moved wiring proof) | **PASS** | §4.1(d), §5.3 |
| Check 60 (shard-coverage validate-pack mirror) | **PASS** | §4.1(e), §5.3/§5.4 |
| New per-check test scripts (red→green) + Check 42 test updated | **PASS** | §4.3/§4.7, §5.3/§5.6 |
| New test scripts WIRED into the yml | **PASS** | §4.2, §5.5 (both run EXIT 0) |
| `--emit-matrix` valid JSON; `--assert-coverage` exit 0; cohesion co-located | **PASS** | §5.4 |
| Generalized Check 42 FAILs on unwired KEEP + on stale allowlist | **PASS** | §5.3 |
| Manifest regenerated + checked (empty → not staged) | **PASS** | §5.7 |
| FULL wired battery run, each exit quoted (no sampling) | **PASS** | §5.5 (71/71 EXIT 0) |
| enumerate-encoding-surfaces (Check 42 text) swept + updated | **PASS** | §5.8 |
| Runtime-cost: cheap checks; heavy assertion in C2 job, not battery; guards preserved | **PASS** | §4.1, §5.1 (1.30 s, no WARN) |
| No C2/C4 work; no git state change; no out-of-scope edits | **PASS** | §7, §1 |
| Handoff: patch + newfiles + report in `/tmp/handoff-bd219-c3/` | **PASS** | §1, §2 |

**All DoD items PASS.**

---

## 10. RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted / measured) | Conclusion |
|---|---|---|
| **agents-never-commit** | Only read-only git verbs run: `git rev-parse HEAD` (×2, both `3afccec`), `git status --short`, `git diff HEAD > c3-modified.patch` (read-only patch-emit). NO add/stage/commit/push/checkout/restore/reset/etc. Manifest restore avoided (used direct verify; diff was empty anyway). HEAD unchanged. | COMPLIANT |
| **ci-guard-design-measure-then-bound** | §3: MEASURED 70 disk / 61 wired / 9 unwired (matches §EE-3); CATEGORIZED every unwired script by reading its header + running it offline; allowlist sized to EXACTLY 1 (the confirmed STRIP); re-measure DISAGREED with §5.2 on 3 tracker-promote tests → followed measurement (KEEP+wire) + flagged the discrepancy. Check 42 FAILs on unwired KEEP and on allowlist staleness (§5.3); PASSes on the projected post-wire tree (§5.2). Never widened to swallow contamination. | COMPLIANT |
| **ci-check-runtime-compounding** | Checks 42/58/59 are glob+regex over the yml + dir listings + small-file reads — NO subprocess-per-script, NO real-tree scan. Check 60 is ONE bounded subprocess (the module reads 3 small files), NOT duplicated onto the ~24-spawn battery (the authoritative coverage assertion is the C2 job). All route through `run_check` (2.0 s per-check WARN). General run = 1.30 s ≪ 10 s total budget; deep EXIT 0; the six existing runtime guards preserved verbatim (untouched). (§5.1) | COMPLIANT |
| **edit-in-place-not-full-rewrite** | validate-pack.py + yml edited via targeted Edits (re-read after). The Check 42 test was a targeted-edit-first attempt; a full rewrite was used ONLY because the Group-2 synthetic harness required wholesale change to match the generalized invariant (a mechanical test-to-match-changed-check update, re-read + re-run green §5.6) — section map confirmed (Groups 0/1/2/3 + Summary all present + passing). The two NEW test files + module are net-new (no rewrite). | COMPLIANT |
| **architect-doc-reality-reconciliation** | Check 42 / new checks referenced by file+symbol, never line number (the registry comment + the module docstring name realized consumers by symbol). Check numbers COMPUTED at wire time (highest=57 → 58/59/60); `CHECK_REGISTRY_EXPECTED_COUNT` computed (60), NOT hard-coded from the plan. The module docstring names its realized consumers (C2 plan/tests-result jobs, Check 60). | COMPLIANT |
| **regenerate-manifest-v11-surface** | C3 touches `scripts/` → ran `bash test-fixtures/build.sh --all --clean` (EXIT 0) + `git status --short test-fixtures/manifest.txt` → EMPTY → noted "manifest diff empty — not staged." (§5.7) | COMPLIANT |
| **verify-full-ci-suite** | Extracted the COMPLETE `run: bash` list from the yml (73 steps) and ran EACH, quoting exit: 71/71 test scripts EXIT 0; the 2 build.sh steps EXIT 0 (verified directly). General + deep validate-pack EXIT 0. NOT sampled. enumerate-encoding-surfaces swept all `scripts/` `.sh` for Check 42 text (0 stale hits) — integration tests included. (§5.5/§5.8) | COMPLIANT |
| **scope-deliverables-to-the-ask** | Implemented EXACTLY C3 (generalized Check 42 + 3 new checks + shard-plan module + weights + allowlist + wire KEEP tests + new tests + manifest). Did NOT start C2 (no matrix/shard yml restructure — only plain `run: bash` steps) or C4. The §3 KEEP/STRIP discrepancy SURFACED (not silently absorbed). No invented scope. | COMPLIANT |
| **preflight-stop-means-stop** | Emitted the single PREFLIGHT line AFTER all edits + full battery + new checks green: `PREFLIGHT: C3 edits complete; new checks 58..60 wired+green; shard-plan --assert-coverage exit 0; full battery all 0; REGIME=ISOLATED at <worktree>; HEAD 3afccec; patch+newfiles+report in /tmp/handoff-bd219-c3/`. No parent stop/halt received. | COMPLIANT |
| **rules-applied-verification-block** | This table — per rule named as in the prompt, quoted/measured evidence, terminal COMPLIANT conclusion; no empty evidence; no AMBIGUOUS. | COMPLIANT |

---

## 11. HANDOFF MANIFEST (for the orchestrator)
```
/tmp/handoff-bd219-c3/
  c3-modified.patch                 (git diff HEAD; 3 modified tracked files)
  IMPL-REPORT.md                    (this report)
  newfiles/
    scripts/ci-shard-weights.tsv               (rw-r--r--)
    scripts/ci-test-wiring-allowlist.txt        (rw-r--r--)
    scripts/lib/ci-shard-plan.py               (rwxr-xr-x)
    scripts/tests/test-ci-shard-plan.sh        (rwxr-xr-x)
    scripts/tests/test-validate-pack-checks-58-59-60.sh  (rwxr-xr-x)
```
**Apply:** `git apply c3-modified.patch`; then `cp -p newfiles/<relpath> <relpath>` for each of the 5 new files. Re-run `python3 scripts/validate-pack.py` (general+deep) + the full wired battery + `validate-pack.py` AFTER the commit exists (Check 36 scope-keyword `pack-only` is post-commit). Commit subject must carry `pack-only` and NO other keyword token.

