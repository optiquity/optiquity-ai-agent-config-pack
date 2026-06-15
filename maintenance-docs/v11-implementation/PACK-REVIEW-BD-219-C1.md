<!-- pack-only review artifact — BD-219 C1. Not a client deliverable. -->
# PACK-REVIEW — BD-219 C1 (`--only-check` + `CHECK_REGISTRY` + e2e-leg adoption + 3 stale-comment strips)

**Reviewer:** pack-reviewer (fresh; independent re-verification, IMPL-REPORT claims NOT trusted)
**Date:** 2026-06-14 · **Repo HEAD:** `f140c48722940578a325971b9f12611a6e9db1fd` (branch `v11-dev`)
**Scope claim:** `pack-only` · **Regime:** in-place against the parent tree (C1 patch applied, uncommitted)

---

## VERDICT: **APPROVE**

C1 adds the `--only-check` selector + `CHECK_REGISTRY` refactor with **byte-equivalent no-flag behavior** (identical execution order, identical banner sequence, identical per-check budgets, exit 0 general + deep), adopts the flag in 23 e2e legs **with zero assertion weakening**, strips exactly the 3 stale Check-54-reserved comments leaving Check 54's implementation untouched, hard-codes no count, starts no C2/C3/C4 scope, and passes the **full 63-script wired battery** (independently re-run, every exit 0) plus an **independent mutation proof** on a check the coder did NOT name (Check 53). No findings at any severity.

---

## SCOPE CONFIRMATION (independent)

`git diff --stat HEAD` + `git status --short` at `f140c48`, 2026-06-14:
- `scripts/validate-pack.py` (modified) + 22 `scripts/tests/test-validate-pack-*.sh` files (23 legs) + untracked `maintenance-docs/v11-implementation/IMPL-REPORT-BD-219-C1.md`.
- `git status --short | grep -v <C1 paths>` → **(no out-of-scope changes)**.
- `.github/` → clean (C2 surface untouched). No new `scripts/` files (`git status --short scripts/ | grep '^??'` → none — C3 surface untouched). `project-template/` → clean (C4 surface untouched).
- C3 artifacts absent: `ls scripts/lib/ci-shard-plan.py scripts/ci-shard-weights.tsv scripts/ci-test-wiring-allowlist.txt` → all "No such file or directory" (correctly not started).
- `validate` job invocations carry NO `--only-check`: `grep -nE 'validate-pack\.py' .github/workflows/validate-pack.yml` → only line 97 (`python3 scripts/validate-pack.py`) + line 104 (`PACK_VALIDATE_DEEP=1 python3 …`), both flagless. The authoritative full run is structurally untouched.

All paths pack-only. **Scope CLEAN.**

---

## EFFECTIVENESS-PRESERVATION (the load-bearing claim — independently proven)

### No-flag run = ALL checks, byte-equivalent behavior
- **Registry size = HEAD callsite count:** `awk '/^def main/,/^if __name__/' <HEAD copy> | grep -cE 'run_check\('` → **57**; working `_build_check_registry()` tuple count → **57**. (`def check_` count is 54 in BOTH HEAD and working — no check function added/removed; the 57>54 delta is the dual-registration of Checks 16/18/19 across project-template + pack-root surfaces.)
- **Execution ORDER identical:** ordered `run_check` label sequence from HEAD `main()` vs the working registry's label sequence → `diff` → **EXECUTION ORDER IDENTICAL** (57 == 57, line-for-line).
- **Banner SEQUENCE identical:** ran HEAD's validate-pack.py and the working one with no flag (HEAD content via a `/tmp` symlink-mirror so `REPO_ROOT = __file__.parent.parent` resolves to the real tree); `diff` of the ordered `── Check` banner lines → **BANNERS IDENTICAL** (56 banner lines each).
- **Per-check budgets unchanged:** `run_check(name, fn, budget_s=RUN_CHECK_PER_CHECK_WARN_BUDGET_S)` default (= 2.0 = the registry's `W`); the only non-default entry is Check 49 (`RUN_CHECK_DEEP_FAITHFULNESS_BUDGET_S`), matching HEAD's `budget_s=…` keyword. No budget regression.
- **Real-tree run:** `python3 scripts/validate-pack.py` → **exit 0**, `PASSED — all checks clean`; `PACK_VALIDATE_DEEP=1 …` → **exit 0**, `PASSED — all checks clean`.

(Note: the symlink-mirror HEAD run reported exit 1 — a pure symlink artifact: Check 40 `check_bare_pack_ops_refs` resolves filesystem basenames and the symlinked fake-root confused its existence resolution. It is NOT a HEAD failure — the real-tree working run is clean, and the banner-SEQUENCE diff (the actual behavioral-equivalence test) is identical.)

### `--only-check` works + effectiveness-preserving
| Invocation | exit | observed |
|---|---|---|
| `--only-check 52` | 0 | 1 banner; `running 1 selected check(s): check_pack_rw_ro_two_class`; `total-run budget N/A in single-check mode; per-check WARN budget stays active`; `PASSED` |
| `--only-check 18` | 0 | `running 2 selected check(s): …[project-template], …[pack-root]`; 2 `Check 18 [` banners (dual-entry preserved) |
| `--only-check 16` | 0 | `running 2 selected check(s): …addenda_h2[project-template], …[pack-root]` (dual-entry preserved) |
| `--only-check check_pack_rw_ro_two_class` (label) | 0 | `running 1 selected check(s)`; Check 52 ran |
| `--only-check 9999` | **1** | `FAIL: --only-check: unknown selector '9999' …`; `FAILED — 1 issue(s) found` (LOUD, not silent no-op) |
| `--only-check bogus_label` | **1** | `FAIL: --only-check: unknown selector 'bogus_label' …`; `FAILED — 1 issue(s) found` |

Budget interaction (read from the diff + verified at runtime): the total-run FAIL block is gated `if only_check is None:` (suppressed for single-check, LIVE for the no-flag full run); selected entries route through `run_check(label, fn, budget_s=budget_s)` so the **per-check WARN stays active**. The six runtime guards (constants @448–457 + `run_check` body + deep ENV-gate) are untouched in the diff.

### In-process `mod.main()` full-run + total-run-budget preserved
`main(only_check=None)` keeps the backward-compatible signature. `test-validate-pack-check-49-field-faithfulness.sh` Group 4(b) calls `mod.main()` **with no args** under a synthetic 999 s clock and asserts the `RUNTIME-BUDGET: validate-pack total` hard-FAIL fires; that test → **exit 0 (8 PASS / 0 FAIL)**. The default-arg full-run path is intact.

---

## INDEPENDENT MUTATION PROOF (Check 53 — NOT a coder-named check)

To avoid coder bias I mutated **Check 53** (`check_worktree_isolation_prohibition_flip_block`), which the coder did NOT use (coder named 52/40). Mutation done on a `/tmp` symlink-mirror copy of the WORKING validate-pack.py; the real tracked file was never edited (`grep -c 'MUTATION-PROOF' scripts/validate-pack.py` → 0 throughout; real validate-pack stayed exit 0).

- Injected `fail("MUTATION-PROOF-REVIEWER-53: …")` into the Check 53 body.
- `python3 <mirror>/validate-pack.py --only-check 53` → **exit 1**, `FAIL: MUTATION-PROOF-REVIEWER-53: injected failure`, `FAILED — 1 issue(s) found`.
- `bash <mirror>/scripts/tests/test-validate-pack-check-53.sh` (its e2e legs run `--only-check 53`) → **exit 1** (the per-check test FAILs, catching the regression).
- Mirror removed; real tree re-verified clean.

The `--only-check` narrowing is effectiveness-preserving: the per-check test still catches its check's regression.

---

## PER-CHECK TEST LEGS (no weakening — spot-checked + full numstat)

- `git diff HEAD --numstat -- scripts/tests/`: every file **+1/-1** (single line), except `test-validate-pack-check-49-field-faithfulness.sh` **+2/-2** (its two legs: deep + general). The only changed content per file is the subprocess invocation gaining `--only-check NN`; no `grep -q` / `t_pass` / `t_fail` / exit-status assertion line was touched.
- Spot-checks (>3):
  - **Check 48** (`removed-doc-advisory`, line "Group 2"): asserts `grep -q "PASSED — all checks clean"`. Under `--only-check 48` the verdict line `PASSED — all checks clean` is still printed (it depends on empty `failures`, not on how many checks ran) → assertion preserved; test exit 0 (3 PASS / 0 FAIL). Footgun avoided.
  - **Check 49** (two legs): general path under `--only-check 49` still prints `SKIP: field-faithfulness deep check`; deep path prints `Check 49 — 220 entries byte-faithful …`. Both assertions preserved; test exit 0 (8 PASS).
  - **Check 18** (dual-entry): leg `--only-check 18` keeps `grep -q "Check 18 [project-template]" && … "[pack-root]"`; both surfaces run (`running 2 selected check(s)`), assertion preserved.
  - **Check 52/53/54/57**: each e2e leg `--only-check NN` retains its banner-grep + clean-verdict-grep; all exit 0 in the battery.

### Deliberate deviation (verified correct — NOT a coverage loss)
`test-validate-pack-checks-36-37-38.sh` has TWO full-validate-pack subprocesses:
- **Group 4, line 398** — `python3 "$REPO_ROOT/scripts/validate-pack.py"` (full run) asserting `t_pass "validate-pack.py exits 0 with all checks including 36/37/38 on HEAD"`. **LEFT as a full run** (correct — narrowing it would destroy its genuine all-checks-exit-0 assertion).
- **G6.T11, line 662** — adopted `--only-check 37` (its target IS Check 37; asserts exit 0 + G6.T12 `'fenced LEGITIMATE-content line'` success message — both preserved).

The deviation is coverage-PRESERVING and was surfaced in the IMPL-REPORT §4 rather than silently applied. `test-validate-pack-checks-32-33-34.sh` correctly has no e2e leg to adopt (module-import only) and is unchanged.

---

## STALE-COMMENT STRIPS (exactly 3; Check 54 impl untouched)

- HEAD had 3 genuine Check-54-reserved comments (HEAD lines 9549/9572/9587). Working tree: `grep -niE 'reserved' scripts/validate-pack.py | grep -iE '54|guard-a'` → only one residual hit (line 549, the WORD "preserved" in Check 3's comment — a substring false-positive on the digits `54` in the line number, not a Check-54 reference). **All 3 genuine reserved-54 assertions removed.**
- The surrounding comment blocks were carried verbatim into the registry (BD-197 C8b/C6b/C7b rationale preserved); only the stale "reserved" clauses were stripped.
- Check 54's implementation untouched: the diff shows only the registry callsite `(54, "check_optional_features_presence", check_optional_features_presence, W)`; the `check_optional_features_presence` function body is NOT in the diff. `def check_` count identical (54) HEAD vs working.
- Located by comment text (grep on `reserved`/`Guard-A′`), not line numbers — consistent with `architect-doc-reality-reconciliation`.

## NO HARD-CODED COUNT
`git diff … | grep '^+' | grep -E '== 5[0-9]|len\(CHECK_REGISTRY\)|expected_count|57\b'` → the only `57` literals added are the Check 57 registry entry `(57, …)` and its banner comment "Check number 57." — these are check-banner numbers, NOT a count invariant. No `len(CHECK_REGISTRY) == 57` / `expected_count` constant (correctly deferred to C3). The selected-count is computed at runtime (`len(selected)`).

---

## FULL CI BATTERY (independently re-run — NOT sampled)

Extracted every `run: bash …` step from `.github/workflows/validate-pack.yml`'s `tests` job (63 targets) and ran each, plus general + deep validate-pack.

- **General** `python3 scripts/validate-pack.py` → **0**; **Deep** `PACK_VALIDATE_DEEP=1 …` → **0**.
- **55 non-fixture wired scripts** (test-detect → test-migrator-capability-translation, incl. heavy long poles `tracker-migrate-forward-test.sh` ~61 s and `test-migrate-v10-to-v11-gates.sh` ~94 s) → **PASS=55 FAIL=0** (each exit 0).
- **Fixture group:** `test-fixtures/build.sh --all --clean` → 0; `test-fixtures/build.sh --verify` → 0; then `test-v11-realistic-ot.sh` 0, `test-migrator-skills.sh` 0, `test-persona-contracts.sh` 0, `template-translations-test.sh` 0, `template-version-test.sh` 0, `test-issue-forms.sh` 0.
- **Total: 63/63 wired scripts exit 0** + general + deep.

(The yml manifest-restore `git checkout HEAD -- test-fixtures/manifest.txt` is a state-changing git verb, NOT run by this RO reviewer; the fixtures are freshly built so `--verify` passes against them and the committed manifest is unchanged — CI runs the restore.)

### Manifest-regen contract
`bash test-fixtures/build.sh --all --clean` then `git status --short test-fixtures/manifest.txt` → **empty** (no fixture SHA changed; C1 edits only validate-pack.py + test scripts). Correctly NOT staged — matches the IMPL-REPORT and the plan §1.1.

### enumerate-encoding-surfaces
No existing banner / verdict text changed (`── Check N:` banners + `PASSED — all checks clean` / `FAILED — N issue(s)` are byte-identical — banner-sequence diff IDENTICAL). The NEW C1 strings (`single-check mode`, `selected check(s)`, `unknown selector`, `total-run budget N/A`) are asserted by NO test: `grep -rE 'single-check mode|selected check\(s\)|unknown selector|total-run budget N/A' scripts/tests/ scripts/test*.sh` → **(none)**. No lock-step assertion update needed; no stale assertion remains.

---

## RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted / measured @ `f140c48`, 2026-06-14) | Conclusion |
|---|---|---|
| **verify-full-ci-suite** | Ran general (0) + deep (0) + all 63 `run: bash` wired scripts (55 non-fixture PASS=55/FAIL=0; build/verify 0/0; 6 fixture-dependent all 0) — extracted from the yml, NOT sampled. Heavy long poles (gates ~94 s, tracker-migrate-forward ~61 s) included, each exit 0. | COMPLIANT |
| **empirical-evidence-blocks** | Every finding above carries the command + verbatim output + HEAD `f140c48` + date 2026-06-14 (registry-count 57==57, execution-order diff IDENTICAL, banner diff IDENTICAL, selector table, mutation proof, numstat, reserved-grep, battery exits). | COMPLIANT |
| **enumerate-encoding-surfaces** | No banner/verdict text changed (banner-sequence diff IDENTICAL); the 4 new C1 strings asserted by no test (`grep -rE … scripts/tests/` → none); Check-42/48/49/18 assertions verified intact under the flag. No stale assertion remains. | COMPLIANT |
| **ci-check-runtime-compounding** | Total-run budget suppressed ONLY in single-check mode (`if only_check is None:` gate; verified `total-run budget N/A …` printed under `--only-check`, LIVE on no-flag); per-check WARN stays active via `run_check(…, budget_s=budget_s)`; six runtime guards (consts @448–457 + `run_check` body + deep ENV-gate) untouched in the diff; no new check added. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Diff confined to validate-pack.py + 22 test files + IMPL-REPORT; no `.github/`, no new `scripts/` file, no `project-template/`, no C3 artifacts, no new Check, no hard-coded count. The one full-run leg the literal reading would weaken was SURFACED (§4), not absorbed. | COMPLIANT |
| **architect-doc-reality-reconciliation** | Comment strips + registry numbers reference checks by banner text/symbol, never line numbers (reserved comments located by grep); no `expected_count`/`len(CHECK_REGISTRY)` literal introduced (computed at runtime). | COMPLIANT |
| **agents-never-commit** | Only read-only git verbs run: `git rev-parse`, `git status`, `git diff [--stat\|--numstat\|HEAD]`, `git show HEAD:…`. No add/commit/push/checkout/restore/reset/apply/stash. Mutation done on a `/tmp` mirror copy, never the tracked tree (`grep -c MUTATION-PROOF scripts/validate-pack.py` → 0). Single write = this review doc. | COMPLIANT |
| **rules-applied-verification-block** | This table — per-rule, quoted/measured evidence, terminal COMPLIANT; no empty evidence; no AMBIGUOUS. | COMPLIANT |

---

## FINDINGS BY SEVERITY

- **BLOCKER:** none.
- **MUST:** none.
- **SHOULD:** none.
- **NIT:** none.

**Recommendation: APPROVE — commit C1 as-is.** Carry forward only the by-design note (already in the plan §3 / design §6.4 + IMPL-REPORT §2 C): the e2e legs' implicit "Check NN is wired into `main()`'s full run" side-effect is moved to C3's registry-completeness guard; keep C3 adjacent to C1 to minimize the window where the wiring proof is an asserted-by-C3-not-yet invariant. This is the intended ordered C1→C3 sequence, not a defect.
