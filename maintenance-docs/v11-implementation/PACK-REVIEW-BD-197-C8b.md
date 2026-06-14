# PACK-REVIEW — BD-197 C8b — Guard-A′ (Check 54) OPTIONAL-FEATURES presence-check

**VERDICT: APPROVE.** Check 54 is correctly sized to exactly the 3 mandated tokens (`baseRef`, `bgIsolation`, `permissions.deny`) × 2 OPTIONAL-FEATURES surfaces, green on arrival, independently proven load-bearing on all 6 missing-token cells, runtime-trivial, and authored→run→wired in lockstep with its dedicated test — all scope, manifest, and CI checks pass with no defects found.

- **Reviewer:** fresh pack-reviewer (read-only on the codebase; this report is the sole write).
- **HEAD (no commit made):** `286b4b1e43c00536d3dcf847d521654d2401eefd`
- **Branch:** `v11-dev` · **Date:** 2026-06-14
- **Regime:** in-place (report written to the named parent-tree path).

---

## Read attestation (read directly, in full, no derivation)

- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` — §13.1a (Guard-A′ presence-check; the MANDATED 3-token form; "sized to EXACTLY those three"; prose `isolation` param explicitly NOT folded), §11.5 readiness / §14 reconciliation / §16 Block-C row 5.
- `maintenance-docs/v11-implementation/PLAN-BD-197-WORKTREE-ISOLATION.md` — §B C8a/C8b (Check 54 ships ONCE here, decision 7; both surfaces; measure-then-bound; green on arrival), §C run-before-wire mandate + the complete wired battery + green-per-commit proof, §D verification strategy, §G manifest "expected EMPTY — S-2".
- `backlog/BD-197.md` — all 15 numbered notes; **note 14 in full** (the user-mandated Guard-A′ extension — `permissions.deny` recipe token in BOTH files in addition to `baseRef`+`bgIsolation`; SUPERSEDES the design's earlier "optional (P3-architect call)" framing → mandated C8b deliverable), note 15 (records as-built check number "Guard-A′=54 (C8b, to land)").
- `pack-ops/OPTIONAL-FEATURES.md` (C5) + `project-template/docs/pack/OPTIONAL-FEATURES.md` (C8a) — both read; tokens + carriers measured.
- `git diff` of the two tracked C8b files + the new `scripts/tests/test-validate-pack-check-54.sh`.
- `maintenance-docs/v11-implementation/IMPL-REPORT-BD-197-C8b.md` — coder claims (independently re-verified, not trusted).
- `CLAUDE.md` § "## Pack memory" (full).

---

## Explicit verdicts on the three demanded points

### (a) 3-token measure-then-bound — VERDICT: CORRECT

`_CHECK_54_REQUIRED_TOKENS = ("baseRef", "bgIsolation", "permissions.deny")` and
`_CHECK_54_OPTIONAL_FEATURES_SURFACES = ("pack-ops/OPTIONAL-FEATURES.md", "project-template/docs/pack/OPTIONAL-FEATURES.md")` — exactly the 3 design-§13.1a / note-14-mandated tokens × the 2 surfaces, no broader.

Independent re-measure at HEAD `286b4b1`, 2026-06-14:
```
pack-ops/OPTIONAL-FEATURES.md:                   baseRef=10  bgIsolation=6  permissions.deny=4
project-template/docs/pack/OPTIONAL-FEATURES.md: baseRef=10  bgIsolation=6  permissions.deny=4
```
Counts match the IMPL-REPORT (10/6/4 both files) exactly. All three present in both → sized to the measured legitimate set.

- **Prose `isolation` param correctly NOT folded in:** `grep -c isolation` = 10/10 in both files (it IS present in prose) yet it is deliberately absent from `_CHECK_54_REQUIRED_TOKENS`. Test case G enforces this (3 tokens + no `isolation` param → still PASS). Matches design §13.1a: "the prose `isolation` PARAMETER is explicitly NOT folded into the bounded check (it is prose, not a settings key)."
- **Tightest matcher:** the check uses `tok not in text` (literal substring membership), NOT regex. Verified `'permissions.deny' in 'permissionsXdeny'` → `False`; the `.` is a literal dot, no wildcard over-match. `permissions.deny` carriers are genuine (pack lines 186/193/228/253; project 173/181/215/258).

### (b) Load-bearing / missing-token-catch — VERDICT: PROVEN (6/6)

Independent /tmp synthetic-tree mutation (pointed `mod.REPO_ROOT` at a tmp tree; NO real-tree mutation, NO `git checkout`), removing one token at a time from one file:
```
baseline (both files all 3 tokens):  failures=0  (expect 0)                PASS
PACK    minus baseRef:               failures=1  names_path & names_tok    PASS
PACK    minus bgIsolation:           failures=1  names_path & names_tok    PASS
PACK    minus permissions.deny:      failures=1  names_path & names_tok    PASS
PROJECT minus baseRef:               failures=1  names_path & names_tok    PASS
PROJECT minus bgIsolation:           failures=1  names_path & names_tok    PASS
PROJECT minus permissions.deny:      failures=1  names_path & names_tok    PASS
TOTAL catch cases proven: 6/6
```
Every cell fails AND the failure message names both the offending surface path and the missing token. Baseline clean. Real-tree counts UNCHANGED after the proof (`pack 10/6/4`, `proj 10/6/4`) → the /tmp methodology touched nothing in the repo. The guard is genuinely load-bearing, not a tautology.

### (c) Check number 54 + contiguity — VERDICT: CORRECT

- **54 was unused pre-edit:** `git show HEAD:scripts/validate-pack.py | grep -E 'Check 54|check_optional_features|_CHECK_54'` → zero hits. 54 was a genuine reserved gap. Matches BD-197 note 15 ("Guard-A′=54 (C8b, to land)").
- **Contiguity:** post-C8b the banner set `── Check {52,53,54,55,56,57}:` is complete — no missing number.
- **Banner order ≠ numeric order (by design):** live run banner order is `52, 53, 54, 56, 55, 57` (commit/dispatch order — `check_optional_features_presence` dispatches immediately after Check 53). Grep for any validator/test asserting banner==numeric order → none. Check numbers are reservation-assigned, dispatch order is commit order; this is by design and load-bearing for none.

---

## Independent re-verification (commands + verbatim + HEAD `286b4b1` + 2026-06-14)

| Aspect | Command | Result |
|---|---|---|
| validate-pack general | `python3 scripts/validate-pack.py` | **EXIT 0**; Check 54 `OK ... all 3 mandated tokens ... documented in each` |
| validate-pack DEEP | `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | **EXIT 0**; Check 54 OK |
| dedicated test | `bash scripts/tests/test-validate-pack-check-54.sh` | **EXIT 0** — `PASS: 3, FAIL: 0` (Groups 0/1/2) |
| wired into yml | `grep -n test-validate-pack-check-54.sh .github/workflows/validate-pack.yml` | line 232, in `tests:` job (job starts line 106), `if: always()`, after the Check-57 step |
| BD-184 wiring guard | Check 42 in general run | **OK: 23 disk / 23 wired; zero unwired** — the run-before-wire backstop counts check-54 balanced (would FAIL 23/22 if unwired) |
| sibling check tests | check-52/53/55/56/57 + check-51-flip-block | all **EXIT 0** |
| sample battery | test-issue-forms.sh, test-per-entry.sh | all **EXIT 0** |
| isolated wall-time | timed `check_optional_features_presence()` | **0.128 ms** (≈ IMPL-REPORT's 0.113 ms); 2 `read_text` + 6 `in` tests; no subprocess, no whole-tree walk |
| manifest | `cp` backup → `build.sh --all --clean` (EXIT 0) → `git diff --quiet manifest` | **EXIT 0 (EMPTY)**; regenerated == backup; `build.sh --verify` EXIT 0; restored via `cp`, NO `git checkout` |
| scope | `git diff --name-only` | exactly `scripts/validate-pack.py` + `.github/workflows/validate-pack.yml` (tracked); new test untracked; **no `project-template/`/`supporting-docs/`** → `pack-only` claim valid |
| OPTIONAL-FEATURES untouched | `git status --short` on both files | empty (C5/C8a authored them; C8b did not edit) |
| diff stat | `git diff --stat` | `2 files changed, 144 insertions(+)` (py +141, yml +3) — matches IMPL-REPORT |

**Run-before-wire:** the BD-184/Check-42 guard structurally enforces test↔yml lockstep (it counts disk tests vs yml invocations); its green 23/23 state is only reachable because the coder wired check-54. The IMPL-REPORT's "BD-184 gate reproduced pre-wire, cleared post-wire" claim is consistent with this guard's mechanics.

---

## Findings by severity

**BLOCKER / MUST / SHOULD: none.**

**NIT (informational only — no fix required, no tech-debt anchor warranted):**

- **N-1 (cosmetic, do-not-fix):** the IMPL-REPORT prose says the yml step was added "after the Check-57 step." The diff shows it inserted between the Check-57 step and the `tracker-deferral-gate-test` step — i.e. it IS after Check-57, just not at end-of-file. The description is accurate; flagged only because "after the Check-57 step" could be misread. The placement (grouped with the other BD-197 guard-test steps) is the correct choice. No action.

No invented nits. No softened blockers — none exist.

---

## Lockstep / encoding-surfaces confirmation

Check + test + yml were edited in lockstep in this one (uncommitted) changeset:
- `scripts/validate-pack.py` — constants + `check_optional_features_presence()` + `run_check` dispatch + comment block (+141).
- `scripts/tests/test-validate-pack-check-54.sh` — new (251 lines; `chmod +x` confirmed `-rwxr-xr-x`); Group 0 sizing assertion, Group 1 cases A–G (PASS + 6 missing-token/absent-surface FAILs + measure-then-bound G), Group 2 e2e.
- `.github/workflows/validate-pack.yml` — the wired step (+3).
No asymmetric coverage (validator without test, or vice versa). The dedicated test additionally pins the sizing (`_CHECK_54_REQUIRED_TOKENS == ('baseRef','bgIsolation','permissions.deny')` and the 2-surface tuple), so a future widening of the asserted set would fail Group 0.

---

## Rules-Applied Verification Block

| Rule (as named in prompt) | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| ci-guard-design-measure-then-bound [verify] | `_CHECK_54_REQUIRED_TOKENS=('baseRef','bgIsolation','permissions.deny')` × 2 surfaces; independent counts 10/6/4 both files at HEAD 286b4b1; prose `isolation` (10/10) NOT folded (test G); literal `in` matcher (`'permissions.deny' in 'permissionsXdeny'`→False); 6/6 missing-token catch proven, baseline 0, real tree unchanged. Sized to KEEP-set, no broader. | COMPLIANT |
| ci-check-runtime-compounding [verify] | Isolated wall-time 0.128 ms; body = 2 `path.read_text` + 6 `in` tests; grep of body for `subprocess/os.walk/rglob/glob/Popen/iterdir` → none; well under 2.0 s WARN budget; `run_check` times it; general+deep both EXIT 0. | COMPLIANT |
| enumerate-encoding-surfaces [verify] | validate-pack.py (check) + test-validate-pack-check-54.sh (new, exec) + validate-pack.yml (wired line 232) all present in the one changeset; Check 42 (BD-184) reports 23 disk/23 wired balanced; no asymmetric coverage. | COMPLIANT |
| verify-full-ci-suite [universal] | Re-ran validate-pack general (EXIT 0) + DEEP (EXIT 0) + check-54 test (EXIT 0, PASS 3/0) + sibling check-52/53/55/56/57 (all EXIT 0) + check-51-flip-block / test-issue-forms / test-per-entry (all EXIT 0) + manifest build/verify (EXIT 0, empty diff). Representative sample green; no sampling-only of validate-pack. | COMPLIANT |
| empirical-evidence-blocks [reviewer] | Every claim backed by command + verbatim output + HEAD 286b4b1 + date 2026-06-14 (token counts, 6/6 catch table, wall-time, pre-edit grep exit, contiguity grep, manifest diff, exit codes, name-only diff). | COMPLIANT |
| scope-deliverables-to-the-ask [universal] | `git diff --name-only` = exactly validate-pack.py + validate-pack.yml (tracked) + new check-54 test (untracked); no project-template/ or supporting-docs/ touched; OPTIONAL-FEATURES files untouched; C8a audit docs (untracked) left for orchestrator. `pack-only` claim valid. | COMPLIANT |
| agents-never-commit [universal] | Only read-only git verbs run: `git rev-parse`, `git status`, `git show HEAD:...`, `git diff`. Manifest backup/restore via `cp` (NO `git checkout`). Sole file write = this review doc. | COMPLIANT |
| rules-applied-verification-block [universal] | This block. | COMPLIANT |

---

**Bottom line:** C8b implements Guard-A′ (Check 54) exactly per design §13.1a + plan §B C8b + BD-197 note 14 — measure-then-bound to 3 tokens × 2 files, load-bearing on all 6 cells, runtime-trivial, lockstep check+test+yml, green on arrival both surfaces, scope clean `pack-only`, manifest empty. **APPROVE.**
