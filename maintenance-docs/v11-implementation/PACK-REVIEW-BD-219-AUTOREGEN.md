<!-- pack-only review artifact. Independent review of the BD-219 dynamic
auto-regen CI-matrix redesign (disk-derived matrix + location-based fixture
cohesion). Reviewer ran IN-PLACE, read-only on the codebase; the single
permitted write is this report. No git/working-tree state changed. -->
# PACK-REVIEW — BD-219 dynamic, disk-derived CI matrix + location-based fixture cohesion

**Reviewer:** pack-reviewer (fresh) · **Date:** 2026-06-15 · **HEAD at review:** `26a0179ecc8e00761c53c80e0f60bf0752a58b48` (`v11-dev`)
**Regime:** IN-PLACE, read-only on the codebase (single write = this report).
**Reviewed against:** `PLAN-BD-219-DYNAMIC-AUTOREGEN.md` §4.1–§4.9 + `ARCHITECTURE-BD-219-DYNAMIC-AUTOREGEN.md` (incl. the location-based Addendum). The IMPL-REPORT was read to learn what was CLAIMED; every load-bearing property below was INDEPENDENTLY re-measured (commands quoted in §3).

---

## 1. VERDICT

**CLEAN — implementation correct, complete, and zero-regression. No BLOCKER, no MUST.** Every load-bearing property of the redesign was independently re-measured and holds: the matrix is truly disk-derived at CI time (no static `include`, no refresh comment), the anti-hazard KEEP set excludes all 26 inert data files (KEEP==72), `FIXTURE_COHESION_GROUP` is gone and replaced by a pure-path `detect_fixture_dependent()`, Check 61 backstops a misplaced fixture test (negative proof re-run), the full 72-test wired battery passes, and scope is clean (no C4/BD-223 leakage in the BD-219 edits). The findings below are 3 SHOULD/NIT items — all are Pack-Chat **staging-discipline** reminders the coder already flagged in the IMPL-REPORT, NOT coder defects.

---

## 2. FINDINGS

| # | Sev | File / area | Evidence | Recommended action |
|---|-----|-------------|----------|--------------------|
| F1 | SHOULD | `test-fixtures/manifest.txt` (commit staging) | Working tree shows ` M test-fixtures/manifest.txt`. Independent `build.sh --all --clean` reproduced the SAME 3 changed v11 SHAs the IMPL-REPORT reported (`e9972b9`/`03f8555`/`39652fe`); the 2 v10 fixtures are unchanged. BD-219 touches NO fixture builder/source (`build.sh` not in diff); the v11 drift traces to C4's `OPTIONAL-FEATURES.md` edit (baked into v11 fixtures). | Pack Chat MUST NOT stage `test-fixtures/manifest.txt` into the BD-219 commit (explicit-pathspec commit, never `-a`). BD-219's own manifest delta is EMPTY. This matches IMPL-REPORT §7 / RISK-M — flagged here as a staging gate, not a defect. |
| F2 | SHOULD | 5 moved tests (commit staging) | `git status --short` shows `RM` on all 5 moved paths (R=staged rename, M=unstaged content edit) — the post-mv-restage smoking gun. Plus `?? scripts/tests/test-validate-pack-check-61.sh` (new, untracked). | Pack Chat MUST re-`git add` each of the 5 moved paths (until porcelain shows `R `) AND `git add` the new check-61 test before committing. IMPL-REPORT §8 already states this; surfaced for the commit gate. |
| F3 | NIT | scope / commit pathspec | Working tree also carries C4/BD-223 changes: ` M backlog/_toc.md`, ` M project-template/docs/pack/OPTIONAL-FEATURES.md` (+113 lines), `?? backlog/BD-223.md`, 4 `?? *BD-219-C4*` reports. None were touched by the BD-219 edits (verified: BD-219's diff is confined to the §4 surface). | Pack Chat commits ONLY the enumerated BD-219 pathspec, leaving the C4/BD-223 working-tree changes untouched. No action for the coder. |

No findings against the implementation itself. Two deviations the coder declared (KEEP==72 not 71; H2 false-positive set is 2 not 3) were independently confirmed CORRECT and are NOT defects — see §3.

---

## 3. INDEPENDENT-VERIFICATION EVIDENCE (re-run; output quoted)

### 3.1 Dynamic matrix is truly disk-derived (the whole point)
- `plan` job emits at CI time: `.github/workflows/validate-pack.yml:149` → `run: echo "matrix=$(python3 scripts/lib/ci-shard-plan.py --emit-matrix)" >> "$GITHUB_OUTPUT"`; outputs.matrix wired at `:140`.
- `tests` consumes: `:171 matrix: ${{ fromJSON(needs.plan.outputs.matrix) }}`, `:167 needs: [plan]`, `fail-fast: false` preserved. `tests-result.needs: [plan, tests]` (`:220`).
- NO static `include:` array (`grep -n "^\s*include:\|- shard:"` → no matches). NO "REFRESH PROCEDURE" / "paste" comment (`grep -ni "refresh procedure\|paste"` → none).
- `parse_wired_tests()` reads DISK (3 `os.listdir` calls over scripts/, scripts/tests/, scripts/tests/fixture-dependent/; no `workflow_text` arg, no `WORKFLOW_PATH`). `grep parse_wired_tests( ... | grep -v '()'` → no arg-passing call site remains.
- **Zero-touch proved end-to-end:** scratch `scripts/tests/test-zerotouch-normal-scratch.sh` (no other edit) → `--emit-matrix` `in matrix: True`, union 72→73, `--assert-coverage` exit 0, Check 42 exit 0. Scratch removed; tree green.

### 3.2 Anti-hazard: KEEP==72, no data-dir leak
```
$ python3 scripts/lib/ci-shard-plan.py --print-partition | head -1
wired: 72   allowlisted (STRIP): 1   KEEP: 72   shards: 4
```
Disk arithmetic (3 explicit non-recursive dirs): `scripts/test*.sh`=6, `scripts/tests/*.sh`=62 (61 baseline + new check-61 test), `scripts/tests/fixture-dependent/*.sh`=5, allowlist=1 → 6+62+5−1 = **72**.
`scripts/tests/fixtures/` has **26** inert `.sh` (recursive); `--print-partition | grep -c "/tests/fixtures/"` → **0**. KEEP is 72, NOT 71+26=97. The glob is 3 explicit dirs, not `scripts/tests/**`. (The prompt's literal "KEEP==71" is the pre-redesign figure; the +1 is the new check-61 encoding test mandated by plan §4.7(b) — a legitimate, declared deviation.)

### 3.3 FIXTURE_COHESION_GROUP gone; location-based detection
`grep -rn FIXTURE_COHESION_GROUP scripts/ .github/` → only 2 hits, both COMMENTS ("Replaces the deleted FIXTURE_COHESION_GROUP frozenset" docstring + a test header comment); zero live `= frozenset(`/`csp.FIXTURE_COHESION_GROUP` references. `detect_fixture_dependent()` is a pure path prefix (`p.startswith("scripts/tests/fixture-dependent/")`). Independent run: `detect_fixture_dependent(parse_wired_tests())` returns EXACTLY the 5 relocated paths (count 5, all under `fixture-dependent/`).

### 3.4 Coverage + emit
```
$ python3 scripts/lib/ci-shard-plan.py --assert-coverage; echo $?
ci-shard-plan --assert-coverage OK: 72 wired KEEP test(s) across 4 shard(s);
union == wired_KEEP_set; pairwise-disjoint; fixture cohesion group co-located in one shard.
0
```
`--emit-matrix` → valid single-line JSON; `json.loads` OK; `include` key present; 4 combinations; each has keys `['scripts','shard']`; union==72. All matrix.scripts tokens are real files; no quotes/newlines (run-loop-safe).

### 3.5 Check 61 + 42 + 60 + registry count
- `--only-check 61` exit 0; `--only-check 42` exit 0; `--only-check 60` exit 0; `--only-check 58/59` exit 0.
- `CHECK_REGISTRY_EXPECTED_COUNT = 61` (line 475), COMPUTED-asserted by Check 59 (`n = len(_build_check_registry()); if n != CHECK_REGISTRY_EXPECTED_COUNT: fail(...)` — not a hand-pinned literal). Check 61 registered LAST (`(61, "check_fixture_dependent_location", ...)`).
- Check 42 re-scoped to allowlist validity (existence + glob-shape + non-empty KEEP); reads the allowlist file, NOT the yml. Banner: `── Check 42: CI test-wiring allowlist is valid + bounded (BD-184, BD-219 redesign) ──`. The 3 `disk_KEEP_set == wired_set` string hits are all docstrings explicitly describing the RETIRED tautology — not live assertions.
- Check 60 docstring updated (disk source + location-based cohesion; no "static include"/"frozen matrix" wording).
- **Check 61 NEGATIVE proof (re-run):** dropped a scratch `test-fixtures/v10-minimal/...`-referencing test into `scripts/tests/` (NOT fixture-dependent/) → `--only-check 61` exit **1**, `FAILED — 1 issue(s)` naming the file + "move it to scripts/tests/fixture-dependent/" remediation. Scratch removed; Check 61 green again.

### 3.6 The 5 relocated tests + sibling rebases
All 4 root vars use `../../..` (3 levels up). The 2 sibling-path rebases the coder flagged resolve to the UNMOVED siblings:
- `test-dry-run-migration.sh:28 HARNESS="$SCRIPT_DIR/../../dry-run-migration.sh"` → `os.path.normpath` = `scripts/dry-run-migration.sh` (exists: YES).
- `test-persona-contracts.sh:33 CONTRACTS_DIR="$SCRIPT_DIR/../../persona-contracts"` → `scripts/persona-contracts` (exists: YES).
All 5 ran green from the new location in the full battery (§3.7). `git log --follow` resolves history through the rename (`72789fc … BD-116 persona contracts`).

### 3.7 verify-full-ci-suite (EVERY wired test, not a sample)
- `python3 scripts/validate-pack.py` (general) → exit **0** (`PASSED — all checks clean`).
- `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` (deep) → exit **0**.
- Built fixtures (`build.sh --all --clean` exit 0), then enumerated the complete wired set from `--emit-matrix` (72 paths) and ran each:
```
=== FULL WIRED BATTERY RESULT ===
PASS=72 FAIL=0  (total 72)
```
Every test, exit checked — not sampled. Encoding tests individually: `test-ci-shard-plan.sh` exit 0, `test-validate-pack-check-42.sh` exit 0, `test-validate-pack-check-61.sh` exit 0, `test-validate-pack-checks-58-59-60.sh` exit 0.

### 3.8 enumerate-encoding-surfaces
- Live old-path refs for the 5 moved tests in `scripts/`/`.github/`/`README.md` (excluding `fixture-dependent` + maintenance-docs) → **none**. README:225-226 + migrate-v10:437 use the NEW paths. Weights TSV: 5 cohesion rows re-pathed to `fixture-dependent/`; no old-path rows linger.
- H2 RE-MEASURE on the POST-relocation tree: non-`fixture-dependent/` KEEP tests matching `test-fixtures/<FIXTURE_NAME>` → **count 0** (empty set after the 2 comment rewordings). `test-validate-pack-checks-36-37-38.sh` was NOT modified (it keys on `manifest.txt`/`v11-trinity-marker-prepped` non-FIXTURE_NAMES paths) — coder deviation #2 (2 rewordings not 3) is CORRECT.
- `test-validate-pack-check-42.sh` covers the re-scoped charge (stale / malformed / multi-invalid / empty-KEEP FAIL; valid + empty + fixture-dependent PASS) via a tmp-tree harness — caller-target-scoped (runtime-compounding-safe).

### 3.9 bash portability
`grep '\${#[A-Za-z_]*\[@\]:-'` across all touched shell (5 moved tests + 2 reworded + 2 encoding tests + new check-61 test + migrate-v10) → **no matches** (the malformed array-length-with-default class that reddened a prior run is absent). The full battery + all encoding tests pass on **bash 3.2.57** (macOS) — so the bash-3.2 leg is exercised green locally.

### 3.10 trinity / skill parity
`md5` of the 3 `verification-harness/SKILL.md` copies (.claude/.codex/.gemini) → all `83742b4fbdf5e9002794c3093febcb9f` (byte-identical, matches IMPL-REPORT). No `x-` frontmatter keys (`grep "^x-|^  x-"` → none) → client `x-` contract intact. The placement-convention section (`## Where a test runner lives …`) is accurate and drift-free with README + the workflow cohesion comment + the ci-shard-plan header (DYNAMIC matrix, `--emit-matrix`, location-based `fixture-dependent/`, Check 61).

### 3.11 manifest + scope
- BD-219 touches no fixture builder/source → its own manifest delta is EMPTY; the working-tree `manifest.txt` delta is the reproducible C4 v11-fixture drift (independently rebuilt to the same 3 SHAs). See F1.
- The BD-219 edits are confined to the §4.1–§4.9 surface + the 2 declared reconciliation files (weights TSV, allowlist header). C4/BD-223 files were NOT touched by BD-219. See F3.

---

## 4. RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted / measured) | Conclusion |
|---|---|---|
| **agents-never-commit** | Read-only git only this session: `git rev-parse HEAD` (26a0179, unchanged), `git branch --show-current`, `git status --short`, `git diff`, `git log --follow`. Scratch files for negative/zero-touch proofs were created with `cat >` and removed with `rm` (working-tree files, never staged/committed); NO `add`/`commit`/`mv`/`checkout`/`reset`/`apply`. Single Write = this report. | COMPLIANT |
| **per-action-approval-sub-agents** | No destructive op on my own authority; scratch test files created+removed in-place for proofs (no real-tree mutation persisted; verified each removed via `ls` → no-such-file). Read-only review otherwise. | COMPLIANT |
| **ci-guard-design-measure-then-bound** | INDEPENDENTLY measured: 3-dir glob excludes all 26 `scripts/tests/fixtures/**` data files (`grep -c "/tests/fixtures/"` → 0); Check 61 H2 false-positive set RE-MEASURED on the post-relocation tree → 0 (allowlist/exempt-list not widened — exactly the legitimate set); Check 42 allowlist validity sized to existence+glob-shape+non-empty. No allowlist widened to admit borderline hits. | COMPLIANT |
| **ci-check-runtime-compounding** | Read Check 42 + Check 61 bodies: each = 3 dir globs + one small read + one anchored regex per KEEP file, NO subprocess-per-script, NO whole-real-tree scan, routed through `run_check`; `detect_fixture_dependent` = pure path filter (zero file reads); Check 60 = ONE bounded `--assert-coverage` subprocess. The check-42 test harness validates a tmp tree (caller-scoped), not the real 211-tree. No compounding regression. | COMPLIANT |
| **verify-full-ci-suite** | Ran BOTH validate-pack legs (general exit 0, deep exit 0) AND every one of the 72 disk-glob wired tests with exits checked (`PASS=72 FAIL=0`) — fixtures built first; not a sample. Encoding/integration tests that pin validator output (check-42/61/58-59-60, ci-shard-plan) re-run green; the 2 reworded-comment tests pass. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Confirmed the BD-219 edits are confined to the §4.1–§4.9 surface + the 2 declared reconciliation files; no C4/BD-223 leakage in the diff (F3). Report leads with the one-line verdict; no SUSPECTED/edge-case padding. | COMPLIANT |
| **regenerate-manifest-v11-surface** | Independently re-ran `build.sh --all --clean`; the 3 changed SHAs match the IMPL-REPORT and trace to C4's `OPTIONAL-FEATURES.md` (baked into v11 fixtures), NOT BD-219 (`build.sh` absent from the BD-219 diff; v10 fixtures unchanged). BD-219's own manifest delta is EMPTY → must NOT be swept into the commit (F1). | COMPLIANT |
| **enumerate-encoding-surfaces** | Swept every encoding surface: validator checks (42/60/61/58/59), dedicated tests (ci-shard-plan, check-42, new check-61, 58-59-60), yml, README, migrate-v10 comment, weights TSV, the 3 SKILL.md copies. No stale assertion or old path found in any live surface; the only old-path/old-string hits are intentional historical-context docstrings. | COMPLIANT |
| **architect-doc-reality-reconciliation** | Spot-checked: docstrings reference file+symbol (`ci-shard-plan.py parse_wired_tests()`, `Check 61 check_fixture_dependent_location`), no line-number cross-refs in code; `CHECK_REGISTRY_EXPECTED_COUNT` is the bookkeeping constant with the actual count COMPUTED (`len(_build_check_registry())`) and asserted equal by Check 59. | COMPLIANT |
| **agents-read-rule-docs-in-full** | Read DIRECTLY and IN FULL via the Read tool: PLAN-BD-219-DYNAMIC-AUTOREGEN.md (417 lines, both pages — first line "pack-only planner artifact…", last RULES-APPLIED row "rules-applied-verification-block"), ARCHITECTURE-BD-219-DYNAMIC-AUTOREGEN.md (563 lines incl. the location Addendum §A.1–§A.5 + EE-9…EE-12), IMPL-REPORT-BD-219-AUTOREGEN.md (202 lines), and the 7 named memory files (ci-guard-measure-then-bound, ci-check-runtime-compounding, verify-full-ci-suite, rules-applied-block, agents-read-rule-docs-in-full, scope-deliverables, manifest-regen) — each opened directly, not derived. CLAUDE.md `## Pack memory` provided in full in session context. No content derived from another source. | COMPLIANT |
| **rules-applied-verification-block** | This table — per-rule, quoted/measured evidence, terminal COMPLIANT; no empty evidence; no AMBIGUOUS. | COMPLIANT |

---

## 5. CLOSING

The redesign delivers exactly the property it was charged with: **adding a test is zero-touch** (proved empirically — a scratch test entered the matrix with no other edit), and the "Frankenstein" static-matrix paste is eliminated (no frozen array, no refresh step). Fixture cohesion is now a pure-path filter with a measured-zero-false-positive Check 61 backstop. All 72 wired tests pass on bash 3.2; validate-pack general + deep are green. The only open items are three Pack-Chat **commit-staging** gates (exclude the C4 manifest delta; re-`git add` the 5 moved paths + the new check-61 test; commit the BD-219 pathspec only) — all already flagged in the IMPL-REPORT. **Recommended verdict: CLEAN — proceed to commit with the staging gates honored.**
