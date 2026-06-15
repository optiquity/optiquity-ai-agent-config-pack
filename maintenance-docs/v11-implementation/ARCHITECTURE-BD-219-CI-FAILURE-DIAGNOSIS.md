<!-- pack-only architecture artifact — CI-FAILURE DIAGNOSIS for BD-219 C2 first-sharded run (GH Actions run 27549132073, HEAD e5a366f). Read-only analysis; feeds a fix-coder. Not a client deliverable. -->
# ARCHITECTURE — BD-219 CI-failure diagnosis (run 27549132073, HEAD `e5a366f`)

**Architect:** pack-architect (fresh; CI-failure diagnostic pass)
**Date:** 2026-06-15 · **Repo HEAD:** `e5a366f9f94c4819d407ec252e4eb691e14ab251` (branch `v11-dev`)
**CI run under diagnosis:** GitHub Actions `27549132073` (`Validate Pack`), conclusion **failure**.
**Scope:** diagnose the first sharded-CI red, classify every failure + sweep the whole battery for the same bug classes, render the C2-sharding-soundness verdict, and produce a fix plan + clean-room verification recipe. Read-only; the only Write is this doc.

---

## READ ATTESTATION (each read in full or at the cited region; no skim/derive)

| Doc / artifact | Read |
|---|---|
| `CLAUDE.md` § "## Pack memory" (CI-guard, runtime-compounding, empirical-evidence, triage-challenge, scope, agents-never-commit, verify-full-ci-suite) | YES (session context, full) |
| `backlog/BD-219.md` (lines 1–23, incl. all 2026-06-14/15 notes) | YES (full) |
| `…/ARCHITECTURE-BD-219-CI-RUNTIME-OPTIMIZATION.md` §2.5 fixture cohesion / §5 wiring | YES (cited regions + §8) |
| `…/ARCHITECTURE-BD-219-C2-WIRED-SET-SOURCE.md` | YES (full, lines 1–302) |
| `…/PLAN-BD-219-C2-REVISED.md` | (covered via the C2-wired-set addendum §EE refs + committed yml) |
| COMMITTED `.github/workflows/validate-pack.yml` (matrix `tests` + `tests-result` + `validate`) | YES (matrix include, run-loop, fixture step) |
| COMMITTED `scripts/lib/ci-shard-plan.py` (`--print-partition`) | YES (partition output captured) |
| `scripts/ci-shard-weights.tsv` · `scripts/ci-test-wiring-allowlist.txt` | YES (allowlist full + its embedded C3-discrepancy note) |
| Failing test scripts: `test-tracker-promote-path1.sh`, `…-path2.sh`, `…-direct.sh`, `test-validate-pack-check-16.sh` | YES (failing regions read) |
| Library `scripts/lib/tracker-promote.sh` (tracker-mode block 663–745), `scripts/lib/tracker-labels.sh` (`_tracker_labels_create` @212), stub `scripts/tests/fixtures/tracker-provider/stub-backend.sh` | YES |
| `…/memory/feedback_ci_guard_design_measure_then_bound.md` + `…/feedback_verify_full_ci_suite.md` | YES (full) |
| CI logs via `gh run view 27549132073` (per-job `--log`) | YES (shard 1 + shard 2 full logs pulled) |

All load-bearing claims carry an Empirical-Evidence Block (§EE-A…§EE-K), measured at HEAD `e5a366f` on 2026-06-15. I reproduced the local-vs-CI divergence rather than assuming it (§EE-F).

---

## VERDICT (lead)

**The C2 sharding MECHANISM is SOUND. The sharding broke NOTHING. Every failure is pre-existing test debt that C3 newly wired and whose latent bugs surfaced on their FIRST-EVER run in a fresh, unauthenticated Linux CI runner.**

- **Failing test scripts: 3** (not 4 — see the check-16 caveat below).
  - `scripts/tests/test-tracker-promote-path2.sh` — shard 1, FAIL: 16
  - `scripts/tests/test-tracker-promote-path1.sh` — shard 1, FAIL: 13
  - `scripts/tests/test-tracker-promote-direct.sh` — shard 2, FAIL: 1
- **`scripts/tests/test-validate-pack-check-16.sh` did NOT fail** (shard 1, **PASS: 10 / FAIL: 0**, "All tests passed."). Its line-266 stderr noise (`[label]: command not found`, the leaked f-string) is a real latent bug but is **non-fatal** — it must still be fixed (it pollutes logs and is one stray heredoc-eval away from a real failure), classed (A).

- **Class breakdown:**
  - **Class C (live-`gh`-dependent → mis-classified KEEP, must re-STRIP or fix-to-offline): the 3 tracker-promote tests.** Their tracker-mode groups call `gh label create` DIRECTLY (`scripts/lib/tracker-labels.sh:212`), which the `_TRACKER_PROVIDER_BACKEND_OVERRIDE=stub` seam does **not** intercept. They pass on the dev machine ONLY because `gh` is installed AND authenticated there (account `DShaneNYC`, §EE-G); on a fresh CI runner `gh` is unauthenticated → label-create fails → the orchestrator rolls back and `return 1` with empty JSON → every tracker-mode assertion fails. The allowlist's own embedded note (§EE-H) records that C3 RE-classified these from STRIP→KEEP on the false premise "zero live gh calls."
  - **Class A (portability / latent shell bug, fix the test): `test-tracker-promote-direct.sh:265` hardcoded dev-path** (the shard-2 `FileNotFoundError`), the **`grep -c … || echo 0` double-zero** sites, and the **check-16 unquoted-heredoc backticks**.
  - **Class B (sharding-induced state/fixture/ordering regression of a previously-passing test): ZERO.** None of the failing tests existed in the OLD monolithic CI; all were newly wired by C3 (§EE-D). A test that was never in the monolithic job cannot have been "broken by sharding."

**Load-bearing conclusion: the C2 design does not need a fixture/state/`--needs-fixtures` redesign. This is test debt + a C3 classification error, not a sharding-architecture defect.** Fix the tests (or re-STRIP the un-offline-able tracker-mode legs); the sharding stays.

---

## PER-TEST FAILURE TABLE

| # | Test (shard) | Failing assertions / error | Exact root cause | Class | Fix |
|---|---|---|---|---|---|
| 1 | `test-tracker-promote-path1.sh` (1) — FAIL: 13 | All of **Group 4 (tracker mode)**: `4.1 mode=tracker expected='tracker' actual=''`; `4.2 \|create missing`; `4.3 no \|close line`; `4.3 tracker_id expected 99 actual ''`; `4.4/4.5 F2 update … "BATCH-17 F2 fix not wired"`; `7.5 F7 message names provider_create — needle missing`. Groups 1–3,5,6,8 PASS. | `tracker_promote_path1` in tracker mode (id-map present, `flat_only=0`) calls `_tracker_labels_create "$derived_label"` (`tracker-promote.sh:678`), which shells **`gh label create` directly** (`tracker-labels.sh:212`) — NOT routed through the stub. On the CI runner `gh` is unauthenticated → label-create fails → function rolls back the plan mutation and `return 1` with NO JSON → `result2=''` → `jq -r .mode` = `''` → the whole Group-4 cascade fails. Group 7.5 F7 (failure-path message) is a separate latent assertion-text mismatch unmasked once the function exercises the failure path. | **C** (live-`gh` dep mis-classified KEEP) | Make the tracker-mode label path offline-deterministic: install a fake `gh` on PATH in Group 4 (the pattern `tracker-bd129-gh-repo-test.sh` / `tracker-init-test.sh` already use), OR route `_tracker_labels_create` through the provider so the stub intercepts it, OR re-STRIP the 3 scripts (allowlist) with the "live-gh in tracker mode" reason. (Architect recommends the gh-PATH-shim fix — keeps coverage; see Fix Plan.) |
| 2 | `test-tracker-promote-path2.sh` (1) — FAIL: 16 | Same **Group 4** cascade as #1 plus `[[: 0` + `0: syntax error in expression (error token is "0")` at lines 247/264, and `6.1/6.2 cycle-graph store created — no file …links-graph.json`. Groups 1–3,5,7 PASS. | Same Class-C root cause (Group 4 tracker mode → unstubbed `gh label create` → empty result). ADDITIONALLY a Class-A shell bug: `create_lines=$(grep -cE '^\|create' "$LOG" 2>/dev/null \|\| echo 0)` — when there are zero matches, `grep -c` prints `0` AND exits non-zero, so `\|\| echo 0` ALSO runs → `create_lines="0\n0"` → `[[ "$create_lines" -ge 1 ]]` errors `[[: 0 …syntax error`. (Same pattern at :263.) The Group-6 store-file failure is a downstream symptom of the early `return 1`. | **C** (Group 4) **+ A** (double-zero @246/263) | Class-C fix as #1. Class-A fix: drop the `\|\| echo 0` (grep -c already prints 0), or `\|\| echo 0; true` collapsed to `$(grep -cE … ; true)` / `$(grep -cE … \|\| true)` so only ONE `0` is emitted; or `tr -d '\n'`. |
| 3 | `test-tracker-promote-direct.sh` (2) — FAIL: 1 | `5.2 --fold-into appears as a wired branch in pack-td.sh`, preceded by `Traceback … FileNotFoundError: [Errno 2] No such file or directory: '/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/pack-td.sh'`. All other groups PASS — incl. its OWN Group 4 because it passes `flat-file` and never enters the live-gh label path. | **Hardcoded absolute dev-machine path** at line 265 inside a SINGLE-quoted heredoc (`python3 - <<'PYEOF'`): `with open("/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/pack-td.sh")`. The single-quoted heredoc blocks `$REPO_ROOT` substitution, so the author hardcoded the path. Exists on the dev machine; on the CI runner the repo is at `/home/runner/work/...` → `FileNotFoundError` → the python `print("0")` else-branch → 5.2 t_fail. (Line 260 just above correctly uses `"$REPO_ROOT/scripts/pack-td.sh"`.) | **A** (hardcoded path) | Pass `$REPO_ROOT` into the python heredoc via env or argv (`REPO_ROOT="$REPO_ROOT" python3 - <<'PYEOF'` then `os.environ["REPO_ROOT"]`, or `python3 - "$REPO_ROOT" <<'PYEOF'` then `sys.argv[1]`). Do NOT switch to an unquoted heredoc (re-introduces the backtick/`$`-eval hazard seen in check-16). |
| — | `test-validate-pack-check-16.sh` (1) — **PASS: 10 / FAIL: 0** (NOT a failure) | Stderr noise at line 266: `[label]: command not found`; `label/name: No such file or directory`; `check_trinity_addenda_h2: command not found`; `syntax error near unexpected token 'f"{label}/{name} — …"'`. Test STILL reports All tests passed. | Group 3 uses an **unquoted** heredoc `python3 <<EOF` (line 266). Inside it, the Python COMMENT lines 322–326 contain bash-active backtick spans — ``[label]``, ``check_trinity_addenda_h2``, `` `fail(f"{label}/{name} — …")` ``. Bash performs command substitution on them BEFORE handing the body to python, emitting the errors to stderr and substituting empty. Because the affected lines are python comments, the python body is otherwise intact → assertions pass. Non-fatal but log-polluting and fragile. | **A** (heredoc quoting; latent) | Quote the heredoc delimiter (`python3 <<'EOF'`) — but verify the body has no `$REPO_ROOT`/`$VALIDATE` that NEEDS expansion (lines 268/270 do). Safer: pass `$REPO_ROOT`/`$VALIDATE` via env/argv (as in fix #3) and quote the heredoc; OR backslash-escape the backticks. |

---

## WHOLE-BATTERY SWEEP (measure-then-bound; not bounded to the 2 failed shards)

Per `ci-guard-design-measure-then-bound`, I grepped ALL 71 wired test scripts for each bug class so a future re-partition cannot resurrect a latent failure in a currently-passing shard.

### Sweep 1 — hardcoded absolute dev-paths (`/Users/…`, `/home/…`)
**Exactly ONE occurrence in the entire battery** (§EE-A): `test-tracker-promote-direct.sh:265`. No `/home/` literals. → the shard-2 failure is the ONLY hardcoded-path bug; no latent copies elsewhere.

### Sweep 2 — `grep -c … || echo 0` double-zero antipattern (§EE-B)
Occurrences feeding arithmetic/string comparison:
- `test-tracker-promote-path2.sh:246, :263` — **ACTIVE FAIL** (Group 4 arithmetic), fix now.
- `test-tracker-promote-path1.sh:275` — **LATENT**: consumed by `[[ "$plan_after_f2_count" -ge 1 ]]`. Misfires only when count is genuinely 0 (an already-failing path); cosmetic noise, but fix for cleanliness in the same pass.
- `tracker-bd134-close-retry-test.sh:325, :360, :365` — **LATENT**: consumed by `assert_eq` (string compare). Misfires only if the underlying count is 0; passed on shard 4 today. Fix for robustness.
- (`grep -c … || true` forms — e.g. path2:506, tracker-migrate-forward, tracker-bd129 — are **NOT** the bug: `|| true` appends nothing, leaving the single `0` grep already printed.)

### Sweep 3 — BSD/macOS-only shell constructs (§EE-C)
- `sed -i ''`, `stat -f`, `readlink -f`, `date -j`: **none** in wired tests.
- `date -r` once (`tracker-migrate-forward-test.sh:783`) — BSD-ism, but `-r` is also GNU-`date` "reference file" and the line has `… || echo ""`; ran in passing shard 3. LATENT-low; note it.
- `mktemp -d -t PREFIX.XXXXXX` (promote tests + several others): **portable** — accepted by both BSD and GNU mktemp; the promote tests' Groups 1–3 (SCRATCH-derived worktrees) PASSED on CI, empirically ruling mktemp OUT as a cause.
- `echo -e`: bash-builtin-safe (CI runs `bash`, not `sh`). Not a bug.

### Sweep 4 — unstubbed live-`gh` calls in tracker mode (the Class-C class) (§EE-I)
Tests touching `_tracker_labels_create` / `gh label` AND exercising tracker mode WITHOUT a gh-PATH shim:
- `test-tracker-promote-path1.sh`, `…-path2.sh` — **ACTIVE FAIL** (no shim; tracker-mode Group 4).
- `test-tracker-promote-direct.sh` — touches `tracker-labels.sh` but its Group 4 runs flat-file → no live-gh path → that test's only failure is the hardcoded path, not the gh dep.
- **PASSING gh-touching tests use a fake-`gh`-on-PATH shim** (`tracker-bd129-gh-repo-test.sh:103-104 export PATH=$WORKDIR/bin:$PATH`; `tracker-init-test.sh:170 export PATH=$FAKE_BIN…`) — the canonical offline pattern the promote tests OMIT. → the fix pattern is already established in the repo.
- `test-tracker-phase-task.sh` — passed; 0 tracker-mode-promote/live-label invocations (§EE-J). Not at risk.

### Sweep 5 — unquoted heredoc with backticks (the check-16 class) (§EE-K)
`test-validate-pack-check-16.sh` Group 3 (`python3 <<EOF`, lines 266–338) is the only confirmed offender that actually emitted bash-eval noise. Other unquoted `<<EOF` heredocs in the file (lines 93/158/351/396) and across the battery did not emit errors in CI (no backticks in their bodies). The fix-coder should grep wired tests for `<<EOF` (unquoted) heredocs whose bodies contain backticks or `$(` and quote/escape them defensively — but the only proven leak is check-16.

---

## C2-DESIGN VERDICT (the load-bearing question, answered with evidence)

**SOUND. The sharding did not break a single previously-passing test (Class B = 0).**

Evidence chain:
1. **Every failing test was newly wired by C3, NOT present in the old monolithic CI.** In the pre-C3 yml (`38e0ae4^`), `grep -c "run: bash …test-tracker-promote-{path1,path2,direct}"` = **0 / 0 / 0** (§EE-D). C3 (`38e0ae4`) added 10 `run: bash` lines including the 3 tracker-promote tests; its yml comment states they were "previously unwired … re-classified KEEP vs the architecture's preliminary STRIP." A test never in the monolithic sequential job CANNOT be a sharding-induced regression of a passing test.
2. **The aggregator anti-footgun worked.** `tests-result` (`needs:[tests]`, assert `needs.tests.result=='success'`) correctly went red while `validate` + shards 3/4 went green — the sharding MECHANISM reported the real failure. No false-green.
3. **No fixture/`--needs-fixtures`/cohesion defect.** The fixture-owning shard is shard 1 (`[FIXTURE-OWNER]`, §EE-E partition). The failures in shard 1 (tracker-promote) and shard 2 (direct) are NOT fixture-build failures — Groups 1–3 of every promote test PASS, and the build step is unrelated to `gh` auth. The single check-49-style fixture cohesion group is intact; no test failed for missing fixtures.
4. **Local reproduction proves environment, not ordering.** `test-tracker-promote-path1.sh` and `…-direct.sh` run EXIT 0 / PASS on the dev machine (§EE-F) and red on CI — the canonical "passes where `gh` is authed, fails where it isn't" signature, not an inter-test ordering artifact. Running them in isolation (their own fresh runner per shard) does not change the outcome.

**Therefore: no C2 fixture-cohesion / `--needs-fixtures` / partition redesign is warranted.** The C2-wired-set-source addendum (`ARCHITECTURE-BD-219-C2-WIRED-SET-SOURCE.md`) remains valid; the static `include` matrix is not implicated.

**Secondary (not a C2 defect, but a C3 process gap to record):** C3's "confirm offline-deterministic (EXIT 0)" step ran on the dev machine, where `gh` is installed AND authenticated — so it could not detect the live-`gh` dependency. This is the `verify-full-ci-suite` lesson at the environment level: "passes locally" was insufficient; the real gate is a clean-room (unauthenticated-`gh`) run. Capture this in the fix so it cannot recur.

---

## FIX PLAN

### Decomposition (recommended: TWO pack-only commits, separable by class)

The C2 design is not changed, so there is no C2-design-fix commit. The two classes are independently testable:

**Commit 1 — `fix: v11 — BD-219 portability/shell bugs in newly-wired tests (Class A) (pack-only)`**
- `test-tracker-promote-direct.sh:265` — pass `$REPO_ROOT` into the single-quoted python heredoc via env (`REPO_ROOT="$REPO_ROOT" python3 - <<'PYEOF'` → `os.environ["REPO_ROOT"]`). Removes the only hardcoded dev-path in the battery.
- `test-tracker-promote-path2.sh:246, :263` — fix the double-zero (`grep -cE … 2>/dev/null || true` drops the spurious second `0`; verify the var stays numeric for `[[ -ge ]]`).
- `test-tracker-promote-path1.sh:275`; `tracker-bd134-close-retry-test.sh:325, :360, :365` — same double-zero hygiene (latent; fix in lockstep so a re-partition can't resurface them).
- `test-validate-pack-check-16.sh` Group 3 heredoc — quote the delimiter (`<<'EOF'`) AND thread `$REPO_ROOT`/`$VALIDATE` via env/argv (lines 268/270 need them), OR backslash-escape the backticks on 322–326. Removes the stderr noise.
- (Optional defensive: `tracker-migrate-forward-test.sh:783` `date -r` — leave as-is if shard 3 stays green; it is guarded by `|| echo ""`.)

**Commit 2 — `fix: v11 — BD-219 tracker-promote tests offline-deterministic in tracker mode (Class C) (pack-only)`**
- Make the tracker-mode (Group 4) legs of `test-tracker-promote-path1.sh` and `…-path2.sh` offline-deterministic by installing a **fake `gh` on PATH** for those groups, mirroring `tracker-bd129-gh-repo-test.sh` (`export PATH="$WORKDIR/bin:$PATH"` with a recording `gh` shim that returns success for `label list`/`label create`). This keeps the tests WIRED (preserves effectiveness — BD-219's HARD constraint) and removes the live-`gh` dependency.
  - The shim must satisfy `_tracker_labels_create` (`gh label create … --force`) and `tracker-labels.sh:201` (`gh label list --json name --limit 200`). Confirm via the existing bd129/init fake-gh shims for the exact arg shapes.
- **Alternative if the shim proves brittle (architect-flagged, NOT default):** route `_tracker_labels_create` through `provider_*` so the stub backend intercepts it — but that is a PRODUCTION-CODE change (`scripts/lib/tracker-labels.sh`) with blast radius into `pack td promote` and the tracker-deferral clamp; it must NOT be made under a CI-fix BD without architect+user sign-off. Prefer the test-side shim.
- **Last-resort if neither lands cleanly:** re-STRIP the 3 scripts in `scripts/ci-test-wiring-allowlist.txt` with reason "tracker-mode legs invoke live `gh label create` (tracker-labels.sh:212) not covered by the stub seam; offline-deterministic shim deferred." This REVERSES the C3 KEEP decision and shrinks coverage — it is effectiveness-reducing for those legs, so it needs explicit user approval and a tracked anchor (a follow-up BD to add the shim). Update the allowlist's embedded C3-discrepancy note accordingly, and regenerate the partition + manifest (Check 42 set-equality must stay green).

**Cross-cutting (both commits):**
- Both touch `scripts/` (v11-surface) → **regenerate `test-fixtures/manifest.txt`** (`bash test-fixtures/build.sh --all --clean`) and stage iff the diff is non-empty (`regenerate-manifest-v11-surface`).
- If commit 2 takes the re-STRIP path, the partition (`ci-shard-plan.py`) drops from 71→68 wired; the static `include` matrix in the yml MUST be regenerated (`--emit-matrix`) and Check 42 re-verified — that makes commit 2 a yml+allowlist+manifest change. The shim path does NOT change the wired set (preferred for that reason too).

### Clean-room verification recommendation (the catch: local pass is insufficient)

Portability + live-`gh` bugs DO NOT manifest on the dev machine (`gh` authed at `DShaneNYC`; repo at `/Users/david/...`). Before re-push, the fix MUST be verified in an environment that mimics the CI runner:

1. **Primary — unauthenticated-`gh` + relocated-path clean checkout (no Docker needed):**
   `git worktree`/`git clone` the repo into a `/tmp/bd219-cleanroom/<random>` path (NOT `/Users/david/...`) so any residual hardcoded path FAILs loudly, then run the 3 tracker-promote tests + check-16 with `gh` auth scrubbed:
   `env -u GH_TOKEN -u GITHUB_TOKEN GH_CONFIG_DIR=$(mktemp -d) HOME=$(mktemp -d) bash scripts/tests/test-tracker-promote-path1.sh` (and -path2, -direct, -check-16). The empty `GH_CONFIG_DIR`+`HOME` forces `gh` unauthenticated, reproducing the CI failure pre-fix and proving the fix post-fix. Assert EXIT 0 + `FAIL: 0` for each.
2. **Stronger — Linux container** (matches the actual runner OS, catches bash-5-vs-3.2 + GNU-coreutils deltas the macOS+path-relocation check misses):
   `docker run --rm -v "$PWD":/repo -w /repo ubuntu:latest bash -lc 'apt-get update -qq && apt-get install -y -qq git jq gh python3 && env -u GH_TOKEN -u GITHUB_TOKEN bash scripts/tests/test-tracker-promote-path1.sh && … '`. This is the truest pre-push gate; recommend it for the Class-C fix specifically.
3. **Full-suite backstop** (`verify-full-ci-suite`): run EVERY one of the 71 wired tests (the `--print-partition` list) + general+deep `validate-pack` locally, quoting each exit, before the commit — a green `validate-pack` alone is NOT a green commit (the recurring lesson). Then watch CI run as the real gate.
4. **Add a standing guard so this can't recur (optional, surface to user — do NOT silently add):** a CI-side or test-harness assertion that the 3 (now-offline) tracker tests are run with `gh` unauthenticated, OR a lightweight validate-pack check that greps wired tracker tests for an unstubbed `gh ` call without a PATH shim. This closes the "confirm-offline-ran-on-an-authed-machine" gap that produced the C3 mis-classification. Scope it cheap (`ci-check-runtime-compounding`): one grep over the wired set, no subprocess-per-test.

### `ci-check-runtime-compounding` note
None of the fixes touch `ci-shard-plan.py` fixture/shard logic or add a per-invocation validator scan (the shim path leaves the partition unchanged; the optional new guard is a single grep). No runtime-guard regression. If commit 2 takes the re-STRIP path, the only validator delta is Check 42's set-equality re-verifying 68==68 — same cost class.

---

## EMPIRICAL-EVIDENCE BLOCKS
All at HEAD `e5a366f9f94c4819d407ec252e4eb691e14ab251`, branch `v11-dev`, 2026-06-15.

### §EE-A — exactly one hardcoded dev-path in the whole battery
- **Claim:** the only `/Users/david/` literal in any wired test is `test-tracker-promote-direct.sh:265`.
- **Command + output:** `grep -rnF '/Users/david/' scripts/test*.sh scripts/tests/*.sh` → single line: `scripts/tests/test-tracker-promote-direct.sh:265:with open("/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/pack-td.sh") as f:`. `grep -rnE '/Users/[a-z]|/home/[a-z]' … | grep -vF '$'` → same single hit.
- **Conclusion: SUPPORTED.**

### §EE-B — the double-zero antipattern sites
- **Claim:** `grep -c … || echo 0` appears at path2:246/263 (active), path1:275, bd134:325/360/365 (latent).
- **Command + output:** `grep -rnE 'grep -c[A-Za-z]* .*\|\| *echo 0' scripts/test*.sh scripts/tests/*.sh` → exactly those 6 lines. Usage confirmed: path2:247 `[[ "$create_lines" -ge 1 ]]`; path1:276 `[[ "$plan_after_f2_count" -ge 1 ]]`; bd134:326/362 `assert_eq`.
- **Conclusion: SUPPORTED.**

### §EE-C — no fatal BSD-only construct; mktemp -t is portable
- **Claim:** no `sed -i ''`/`stat -f`/`readlink -f`; `mktemp -t` ruled out by passing Groups 1–3.
- **Command + output:** `grep -rnE "sed -i '' |stat -f|readlink -f" scripts/test*.sh scripts/tests/*.sh` → empty. `mktemp -d -t tpr1.XXXXXX` (path1:104) — Groups 1–3 of path1 PASSED on CI (shard-1 log lines for `=== Group 1/2/3 ===` all PASS), proving SCRATCH/worktree creation succeeded on Linux.
- **Conclusion: SUPPORTED.**

### §EE-D — every failing test was newly wired by C3, none in the monolithic CI
- **Claim:** path1/path2/direct have 0 `run: bash` lines pre-C3; check-16 = 1 (pre-existing).
- **Command + output:** for `t` in the 3 promote tests + check-16: `git show 38e0ae4^:.github/workflows/validate-pack.yml | grep -cE "run: bash scripts/tests/$t\.sh"` → `0, 0, 0, 1`. C3 diff `git show 38e0ae4 -- .github/workflows/validate-pack.yml | grep '^+.*run: bash'` lists the 3 promote tests + 7 others as ADDED. The C3-parent yml comment: "BD-219 C3: offline KEEP tests previously unwired … The three tracker-promote tests use a STUB backend (zero live gh) — re-classified KEEP vs the architecture's preliminary STRIP."
- **Conclusion: SUPPORTED (Class B impossible for these).**

### §EE-E — the partition + fixture-owner; which shard ran each failing test
- **Claim:** shard 1 = FIXTURE-OWNER and holds path1/path2 + check-16; shard 2 holds direct; failures are not fixture-build failures.
- **Command + output:** `python3 scripts/lib/ci-shard-plan.py --print-partition` → `wired: 71 … KEEP: 71 shards: 4`; shard 1 `[FIXTURE-OWNER]` lists `test-tracker-promote-path2.sh`, `test-tracker-promote-path1.sh`, `test-validate-pack-check-16.sh`; shard 2 lists `test-tracker-promote-direct.sh`. CI shard-1 log: every promote test's Groups 1–3 PASS (no fixture error); only Group 4 (tracker) fails.
- **Conclusion: SUPPORTED (no fixture/cohesion defect).**

### §EE-F — local PASS vs CI FAIL (the environment, not ordering)
- **Claim:** path1 + direct run EXIT 0 / PASS on the dev machine.
- **Command + output:** `bash scripts/tests/test-tracker-promote-path1.sh` → `=== Summary === PASS: 79 FAIL: 0`, EXIT=0. `bash scripts/tests/test-tracker-promote-direct.sh` → `PASS: 31 FAIL: 0`, EXIT=0. CI run 27549132073: path1 FAIL: 13, direct FAIL: 1.
- **Conclusion: SUPPORTED (passes-locally signature; gate must be clean-room).**

### §EE-G — `gh` is installed AND authenticated on the dev machine (masks the dep)
- **Claim:** dev machine has authed `gh`; CI does not.
- **Command + output:** `which gh` → `/opt/homebrew/bin/gh`; `gh --version` → `gh version 2.93.0`. `gh auth status` → `✓ Logged in to github.com account DShaneNYC (keyring) … Active account: true`. CI `tests` shards have no `GH_TOKEN`/`GITHUB_TOKEN` step → `gh` unauthenticated.
- **Conclusion: SUPPORTED.**

### §EE-H — the C3 mis-classification is recorded in the allowlist's own note
- **Claim:** C3 reversed the 3 promote tests STRIP→KEEP on the false "zero live gh calls" premise.
- **Command + output:** `scripts/ci-test-wiring-allowlist.txt` embedded note: "The C3 coder's empirical re-measure (run-each-offline) found the three `test-tracker-promote-*.sh` scripts use a STUB backend (`_TRACKER_PROVIDER_BACKEND_OVERRIDE=stub`; zero live `gh` calls) and pass offline (EXIT 0) — so they are KEEP, not STRIP." The "zero live `gh` calls" claim is FALSIFIED by §EE-I.
- **Conclusion: SUPPORTED.**

### §EE-I — the unstubbed live-`gh` call in tracker mode
- **Claim:** tracker-mode promote calls `gh label create` directly, bypassing the stub.
- **Command + output:** `tracker-promote.sh:678` `if ! _tracker_labels_create "$derived_label"; then … return 1`. `tracker-labels.sh:212` `gh label create "$name" --description … --color "ededed" --force >/dev/null 2>&1` (and `:201` `gh label list --json name --limit 200`). The stub dispatch (`tracker-provider.sh:73-112`) only intercepts `tracker_provider_stub_*`; `_tracker_labels_create` never routes through `provider_*`. `grep -nE 'BACKEND_OVERRIDE|stub' scripts/lib/tracker-labels.sh` → no stub awareness.
- **Conclusion: SUPPORTED (Class C; "zero live gh" is false for Group 4).**

### §EE-J — passing gh-tests use a fake-gh-PATH shim; promote tests omit it
- **Claim:** the offline pattern exists in the repo; the failing tests don't use it.
- **Command + output:** `tracker-bd129-gh-repo-test.sh:21` "All scenarios are mock-based (fake `gh` on PATH …)"; `:103-104` `ORIG_PATH="$PATH"; export PATH="$WORKDIR/bin:$PATH"`. `tracker-init-test.sh:170` `export PATH="$FAKE_BIN_NA:$PATH_SAVED"`. `grep -nE 'PATH=|gh\(\)|fake.?gh|shim' scripts/tests/test-tracker-promote-path{1,2}.sh scripts/tests/test-tracker-promote-direct.sh` → EMPTY. `test-tracker-phase-task.sh` `grep -cnE 'tracker_promote_path|BACKEND_OVERRIDE'` → 0 (no tracker-mode promote → passed).
- **Conclusion: SUPPORTED (fix pattern is established; promote tests are the omission).**

### §EE-K — check-16 PASSED; the line-266 noise is non-fatal heredoc backtick eval
- **Claim:** check-16 is PASS:10/FAIL:0; the errors come from bash-evaluating backticks in an unquoted heredoc's python comments.
- **Command + output:** CI shard-1 log for `test-validate-pack-check-16.sh`: `=== Summary === PASS: 10 FAIL: 0 / All tests passed.` Heredoc opens `python3 <<EOF` (line 266, unquoted). Lines 322–326 (python comments) contain backtick spans; `sed -n '322,326p' … | grep '`'` shows ``[label]``, ``check_trinity_addenda_h2``, `` `fail(f"{label}/{name} — …")` ``. CI stderr: `[label]: command not found`, `syntax error near unexpected token 'f"{label}/{name} — …"'`.
- **Conclusion: SUPPORTED (Class A latent; not counted as a test failure).**

---

## RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted / measured) | Conclusion |
|---|---|---|
| **empirical-evidence-blocks** | §EE-A…§EE-K back every state-claim (1 hardcoded path; 6 double-zero sites; no BSD-fatal; newly-wired-by-C3 0/0/0/1; partition+fixture-owner; local PASS vs CI FAIL; authed-gh; allowlist note; unstubbed `gh label create`@212; shim pattern; check-16 PASS) with command + verbatim output + HEAD `e5a366f` + 2026-06-15 + interpretation + SUPPORTED. | COMPLIANT |
| **ci-guard-design-measure-then-bound** | Swept the WHOLE 71-test battery for each bug class (Sweeps 1–5), not just the 2 failed shards: found the LATENT double-zero (path1:275, bd134:325/360/365) and LATENT-low `date -r`, classified each KEEP/fix vs STRIP. Sized the fix to exactly the measured set; flagged that the re-STRIP last-resort must keep the allowlist bounded + regen the partition. | COMPLIANT |
| **preliminary-triage-architect-challenge** | CHALLENGED the "it's just test debt" framing: explicitly tested the Class-B hypothesis (sharding broke a passing test) and FALSIFIED it via §EE-D (every failing test absent from monolithic CI) + §EE-F (local pass / CI fail = environment, not ordering). Did not accept the caller's "two compounding causes" at face value — proved C2 sound and C3-misclassification the real second cause. | COMPLIANT |
| **ci-check-runtime-compounding** | The recommended fixes (PATH-shim, double-zero hygiene, heredoc quoting) do NOT touch `ci-shard-plan.py` fixture/shard logic or add per-invocation validator scans; the shim path leaves the 71-test partition unchanged. The optional standing guard is scoped to ONE grep over the wired set (no subprocess-per-test). No runtime-guard regression introduced. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Delivered exactly the charge: failing-test enumeration + per-test root cause, whole-battery sweep, A/B/C classification, the C2-soundness verdict with evidence, fix plan + commit decomposition + clean-room recipe. IGNORED the unrelated uncommitted working-tree changes (`backlog/BD-201/217/221`, RESEARCH-BD-217/221) per the note. Did not design beyond the fix (flagged the production-code reroute + the new-guard as user-gated, not adopted). | COMPLIANT |
| **agents-never-commit** | Read-only git only: `git log`, `git status`, `git show <ref>:path`, `git rev-parse`. No add/commit/push/checkout/restore/worktree/etc. `gh run view` is read-only. Single Write = this diagnosis doc at the caller-specified path. No source file edited. | COMPLIANT |
| **rules-applied-verification-block** | This table — per-rule, quoted/measured evidence, terminal COMPLIANT; no empty evidence; no AMBIGUOUS. | COMPLIANT |
