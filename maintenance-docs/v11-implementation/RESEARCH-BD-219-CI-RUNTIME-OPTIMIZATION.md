<!-- pack-only research artifact — feeds the BD-219 architect. Not a client deliverable. -->
# RESEARCH — BD-219 CI Runtime Optimization (effectiveness-preserving)

**Researcher:** pack-docs-researcher (FIRST pipeline stage; feeds architect)
**Date:** 2026-06-14 · **Repo HEAD at measurement:** `1f95b8eedd9fa21b7c9a824736648599c543bb2d` (branch `v11-dev`)
**Account/runner target (availability axis):** personal/individual GitHub **User** account `DShaneNYC`; repo **PRIVATE**; runners `ubuntu-latest` (standard GitHub-hosted). Verified `gh api user --jq .type` → `"User"` (not an organization).
**Scope of this report:** problem-mapping + authoritative-source feasibility only. No design, no implementation, no file edits beyond this report.

---

## READ ATTESTATION (each read IN FULL, no skim/crop/derive)

| Doc | Read |
|---|---|
| `CLAUDE.md` § "## Pack memory" | YES (full file read; Pack-memory section incl. all rules) |
| `backlog/BD-219.md` | YES (lines 1–20, full entry) |
| `.github/workflows/validate-pack.yml` | YES (lines 1–324, full file) |
| `…/memory/feedback_ci_check_runtime_compounding.md` | YES (full) |
| `…/memory/feedback_verify_availability_not_just_existence.md` | YES (full) |
| `…/memory/feedback_external_rules_census_before_design.md` | YES (full) |
| `…/memory/feedback_researcher_maps_blast_radius_before_architect.md` | YES (full) |
| `…/memory/feedback_ci_guard_design_measure_then_bound.md` | YES (full) |

Also read for grounding (not in the named-set, but load-bearing): `scripts/validate-pack.py` `main()` (lines 9338–9460), `run_check` + budget constants (lines 435–481), Check 42 (`check_ci_workflow_wires_per_check_tests`, lines 6652–6781), total-run budget enforcement (lines 9594–9620).

---

## EXECUTIVE SUMMARY

### The single most important finding — the BD's premise needs reframing

The `tests` job IS the long pole (confirmed: ~7.3–7.7 min vs the `validate` job's ~12–15 s — a **~30× ratio**, runs in parallel, no `needs:`). **But the per-check `validate-pack.py` tests are NOT where the time goes.** Measured from CI step data (run `27512425188`, HEAD):

- **All `validate-pack Check NN` steps combined = ~76 s of the ~462 s tests-job (≈16%).**
- The **slowest steps call `validate-pack.py` ZERO times**: `migrate-v10-to-v11 verification gates` = **94 s**, `tracker-migrate forward` = **61 s**, `tracker-migrate roundtrip` = **52 s**, `tracker-migrate reverse` = **34 s**, `migrate-v10-to-v11 dry-run` = **31 s**, `migrate-v10-to-v11` = **29 s**. These spawn full migrations / many `gh`-stub iterations, not the validator.

**Consequence for the two known levers:**

| Lever | Verdict | Expected wall-time gain | Effectiveness impact |
|---|---|---|---|
| **(1) Matrix-shard the `tests` job** | **FEASIBLE + GA + usable on this account; the DOMINANT win.** | Near-linear in shard count for the work that parallelizes; e.g. 4 balanced shards → tests-job ≈ max-shard ≈ ~120–160 s (from ~462 s) once the 94 s/61 s/52 s long poles are split across shards. | ZERO — every script still runs, just on parallel runners. |
| **(2) `validate-pack --only-check`** | **FEASIBLE (greenfield argparse; no current argparse in the file) but a SMALL win.** | Bounded by the ~76 s the per-check steps consume, and realistically far less — most per-check tests spawn the full validator only ONCE (~1.2 s) as an end-to-end assertion; cutting that to ~1/56th saves ~tens of seconds **total**, not per-test. | ZERO **if** designed so per-check tests keep their module-import unit assertions AND the `validate` job still runs ALL checks (no flag = all). |
| **(3) Minor: cache pip/Python** | **FEASIBLE but ~0 win here.** Setup overhead measured = **~7 s total** (Python 3.12 pre-cached on the runner; `pip install pyyaml` is trivial). | Negligible; under sharding it is paid once PER SHARD, so it slightly raises aggregate cost. | None. |

**Bottom line for the architect:** Lever 1 (sharding) is the design's center of gravity and should be balanced by **measured per-step CI time** (this report supplies it), NOT by script-name hash (which would put the 94 s + 61 s + 52 s steps in unpredictable shards). Lever 2 is a legitimate effectiveness-neutral cleanup of the compounding pattern but should be presented as a modest secondary gain, not co-equal.

### Additional effectiveness-preserving mechanisms (shortlist — full table in §6)

- **A. Measured-balance shard map** (not hash-balance) — assign scripts to shards by their measured CI duration so the slowest shard is minimized (bin-packing). ZERO effectiveness impact. Strongest multiplier on Lever 1.
- **B. Run `validate` and the deep `validate` (`PACK_VALIDATE_DEEP=1`) as they already are** — already parallel; no change needed, noted so the architect preserves it.
- **C. Per-shard fixture build only where needed** — `build.sh --all --clean` (~6 s) + fixture-dependent tests must co-locate in a shard; build fixtures once per shard that needs them, not in shards that don't. ZERO effectiveness impact; small saving + a correctness constraint.
- **D. `pip`-cache via `actions/setup-python` `cache:`** — bounded/near-zero gain (setup is ~7 s); list as available but low-value.
- **E. Reduce subprocess churn inside the migrate/tracker-migrate tests** (the real long poles) — POTENTIALLY large, but **bounded/flagged**: only safe if it does not change WHAT is asserted; this is test-internal refactor risk and must be effectiveness-proven (mutation) per case. Surface as a candidate, not a recommendation.
- **REJECTED (effectiveness-reducing):** path-filtered conditional test skipping; sampling/subset runs; result caching that could serve stale results; `fail-fast: true` on the test matrix (would cancel in-progress shards and HIDE other shards' failures — reduces effectiveness of a single run's signal). See §6 "Rejected".

### Upkeep / anti-drift recommendation (options + evidence in §7)

The existing wiring guard (**Check 42**) covers ONLY `scripts/tests/test-validate-pack-check*.sh` — measured: **9 test scripts on disk are currently un-wired** into CI and Check 42 does not catch them (they are not per-check files). Sharding ADDS a second drift axis ("a wired test that lands in NO shard"). The architect should design a **measure-then-bound wiring-completeness + shard-coverage guard** that asserts (set-equality, both directions): every test-runner script that should run is wired AND lands in exactly one shard. Recommended home: extend/replace Check 42's set-equality pattern inside `validate-pack.py` (it already owns the disk↔workflow comparison), with the shard map as the bounded allowlist source. Full options + the measured drift evidence in §7.

---

## 1. MEASURED BLAST RADIUS

All repo state-claims below carry the command + measured output, taken at HEAD `1f95b8e` on 2026-06-14.

### 1.1 Per-job wall-time (CI, authoritative) — `tests` is the long pole, confirmed

`gh run view <id> --json jobs` on the 4 most-recent `Validate Pack` runs, durations computed from `startedAt`/`completedAt`:

| Run | HEAD | `validate` job | `tests` job | ratio |
|---|---|---|---|---|
| 27512425188 | `1f95b8e` (current HEAD) | **15 s** | **464 s (7.7 m)** | 31× |
| 27510880116 | `7da3380` | 14 s | 441 s (7.3 m) | 32× |
| 27510025460 | `286b4b1` | 12 s | 463 s (7.7 m) | 39× |
| 27509281980 | `13bb32e` | 15 s | 456 s (7.6 m) | 30× |

- **Confirmed:** the two jobs run in PARALLEL (`validate` and `tests` both `startedAt` ~the same second; no `needs:` in the yml). Workflow wall-time ≈ the `tests` job ≈ **~7.3–7.7 min**.
- **Confirmed:** `validate` (the whole `validate-pack.py` general run + the deep `PACK_VALIDATE_DEEP=1` run) finishes in ~12–15 s. It is NOT the long pole and needs no optimization for wall-time. (Local single general run = **1.20–1.23 s**; local deep run = **2.48 s**; the CI 12–15 s is dominated by checkout+setup-python+pip, not the validator.)
- The BD cites "C6a `4226dc8` = 7m25s" — consistent with the ~7.3–7.7 min band measured here. **RECONCILED.**

### 1.2 Heaviest `tests`-job steps (CI step data, run 27512425188) — the real long poles

`gh run view 27512425188 --json jobs --jq '… .steps[] …'`, durations from per-step timestamps:

| Duration | Step | Calls `validate-pack.py`? |
|---|---|---|
| **94 s** | migrate-v10-to-v11 verification gates (BD-101) | **NO (0)** |
| **61 s** | tracker-migrate forward tests (BD-065) | **NO (0)** |
| **52 s** | tracker-migrate roundtrip tests (BD-070) | NO |
| **34 s** | tracker-migrate reverse tests (BD-068) | NO |
| **31 s** | migrate-v10-to-v11 dry-run/apply/resume (BD-095) | NO |
| **29 s** | migrate-v10-to-v11 tests (BD-085) | NO |
| 14 s | migrate-v10-to-v11 decompose (BD-165) | NO |
| 11 s | persona contracts (BD-116) | NO |
| 10 s | validate-pack Check 49/50 (deep faithfulness) | yes |
| 8 s | tracker-provider tests | NO |

- **Setup/teardown overhead** (checkout + setup-python + pip + post): **~7 s total** for the whole tests job. Caching pip yields ~0 here.
- **Sum of all per-step durations = 462 s; actual test execution = ~455 s.**
- **Sum of all `validate-pack Check NN` steps = ~76 s (≈16% of 462 s).**
- **Interpretation:** the long poles are migration + tracker-migration tests that spawn full migrations / many `gh`-stub iterations — they do not touch `validate-pack.py`. The `--only-check` lever cannot help them. **Sharding is the only lever that parallelizes them.**

Local cross-check (subprocess timing of the heavy scripts, this machine):
`test-migrate-v10-to-v11-gates.sh` = **77.9 s**, `…-dry-run.sh` = 32.7 s, `…-v10-to-v11.sh` = 30.7 s, `…-decompose.sh` = 14.3 s, `test-persona-contracts.sh` = 9.5 s, `test-v11-realistic-ot.sh` = 1.4 s. (Local ≈ CI ordering; absolute values track.)

### 1.3 Test-script inventory — wired vs on-disk (reconciled 3 ways)

**Wired test-runner scripts in `tests` job = 61 distinct scripts** (reconciled two independent ways):
- `grep -E '^\s+run: bash ' …yml | grep -v build.sh | wc -l` → **61**
- `grep -E '^\s+run: bash ' …yml | awk '{print $3}' | grep -v build.sh | sort -u | wc -l` → **61**

Total **named steps in the `tests` job = 65** = 1 `pip` + 1 `git checkout` (manifest restore) + 63 `run: bash`. Of the 63 bash steps: **61 distinct test scripts** + `test-fixtures/build.sh` appearing in **2** steps (`--all --clean` build; `--verify`).

**On-disk test scripts (`scripts/test*.sh` + `scripts/tests/*.sh`) = 70.** Difference vs 61 wired = **9 un-wired scripts** (drift evidence; see §7):
```
scripts/test-compare-agent-trinity.sh
scripts/test-dry-run-migration.sh
scripts/test-restore-from-backup.sh
scripts/tests/test-activate-capability.sh
scripts/tests/test-add-capability.sh
scripts/tests/test-tracker-promote-direct.sh
scripts/tests/test-tracker-promote-path1.sh
scripts/tests/test-tracker-promote-path2.sh
scripts/tests/tracker-bd204-lossless-roundtrip-test.sh
```
`comm -13` (wired-but-not-on-disk) = **EMPTY** — no stale workflow line. The drift is one-directional (scripts exist but aren't run). **NOTE:** this report does not adjudicate whether each of the 9 SHOULD be wired (some may be intentionally manual — e.g. promote-path tests touch live GH); that classification is the architect's measure-then-bound KEEP/STRIP step. The fact relevant to BD-219 is that **the current guard (Check 42) cannot see them.**

### 1.4 `validate-pack.py` invocation count across the battery — reconciled, with the BD's "238" addressed

The BD states **"238 `validate-pack.py` invocations … 26 per-check tests + others each spawn the FULL validator."** Re-measured:

| Measurement | Command | Result |
|---|---|---|
| Textual occurrences of `validate-pack.py`, ALL on-disk test scripts | `grep -rE 'validate-pack\.py' scripts/tests/*.sh scripts/test*.sh \| wc -l` | **260** |
| Textual occurrences, WIRED scripts only | (loop over wired list) | **259** |
| Textual occurrences, wired, excl. comment + module-import + `VALIDATE=` lines | (filtered) | **173** |
| **Actual FULL-validator subprocess spawns** (`python3 … validate-pack.py` command lines, wired) | filtered grep | **~24** (range 24–27 once loop-embedded spawns are counted; see note) |

- **I cannot reconcile "238" to any single clean measurement** — the closest is the textual-occurrence family (260 / 259 / 173). I flag 238 as an **un-reconciled estimate**; the architect should treat the **subprocess-spawn count (~24–27)** as the real cost driver, not 238. The discrepancy matters because the design rationale ("each of 238 invocations does ~1/56th the work") overstates the lever-2 gain by ~10×.
- **The architectural reason the spawn count is low:** the per-check tests load `validate-pack.py` as a Python MODULE (`importlib.util.spec_from_file_location`) and call the target check function IN-PROCESS for their unit assertions (fast — the module import does NOT run `main()` because of the `if __name__ == "__main__"` guard at line 9621). Each per-check test then spawns the full validator **once** end-to-end (`python3 …/validate-pack.py`) as an integration assertion ("exits 0; Check NN ran clean at HEAD"). Measured: 23 of the 27 validate-pack-calling wired scripts are `test-validate-pack-check*` (≈1 full spawn each); the other 4 are `recommendation-state-schema-test.sh`, `tracker-config-schema-test.sh`, `tracker-init-test.sh`, `test-v11-realistic-ot.sh` (7 spawns — the heaviest validator caller).
- **Measured per-check test cost:** `test-validate-pack-check-52.sh` = 1.30 s, `-43.sh` = 1.48 s, `-40.sh` = 1.52 s — i.e. each is dominated by its ONE ~1.2 s full-validator spawn; the module-import unit assertions are sub-second. So `--only-check` shrinks the ~1.2 s e2e leg of each per-check test toward ~tens of ms → realistic total saving ≈ **(number of per-check tests) × ~1.1 s ≈ ~25–30 s**, all of it inside the ~76 s validate-pack-step bucket.

### 1.5 The compounding pattern (`ci-check-runtime-compounding`) — where it bites and where it doesn't

The root-cause memory says: cost = per-run-cost × battery-invocation-count, and a heavy check compounds across the battery's many `validate-pack` invocations. Applied here:
- The compounding the memory warns about is REAL but **already mitigated**: the deep field-faithfulness leg (Check 49, the historical 1.5 h incident) is ENV-GATED (`PACK_VALIDATE_DEEP=1`) and runs ONCE in the `validate` job's dedicated deep step (yml lines 103–104) — it SKIPs on the ~24-spawn general battery path (validator lines 7689–7697). So the battery's ~24 general spawns each pay only the ~1.2 s general cost, not the deep cost. **This mitigation MUST be preserved by BD-219.**
- Where compounding still costs: 24 spawns × ~1.2 s ≈ ~29 s of redundant full-tree re-scan, since a per-check test only needs ITS check. This is exactly Lever 2's target — a legitimate but **~29 s** (not 238×) opportunity.
- **The bigger compounding the BD does NOT name** is the migrate/tracker-migrate subprocess churn (94 s/61 s/52 s steps) — these compound via per-iteration migration/`gh`-stub spawns, NOT validate-pack. Sharding parallelizes them; only a test-internal refactor (flagged-bounded, §6E) could shrink them in absolute terms.

### 1.6 Existing per-check runtime guards (enumerate so the architect PRESERVES them)

All in `scripts/validate-pack.py`:
1. **`run_check(name, fn, budget_s)`** (lines 463–480) — times every check; WARNs (not fails) if a single check exceeds the per-check budget. EVERY check in `main()` routes through it (lines 9348+).
2. **Per-check WARN budget** `RUN_CHECK_PER_CHECK_WARN_BUDGET_S = 2.0` (line 448).
3. **Total general-run budget** `RUN_CHECK_TOTAL_GENERAL_BUDGET_S = 10.0` (line 449) — hard FAIL at end of `main()` (lines 9594–9620) on the general path; a check that regresses into the general path (the C-4.6 shape) blows it.
4. **Total deep-run budget** `RUN_CHECK_TOTAL_DEEP_BUDGET_S = 35.0` (line 450) — larger budget applied only when `PACK_VALIDATE_DEEP=1`, so a legitimate deep run is not falsely failed.
5. **Deep faithfulness-leg per-check budget** `RUN_CHECK_DEEP_FAITHFULNESS_BUDGET_S = 30.0` (line 457) — Check 49's deep leg WARN budget.
6. **ENV-gating of the deep leg** (lines 7689–7697; yml step lines 103–104) — the heavy whole-real-tree verification runs ONCE under `PACK_VALIDATE_DEEP=1`, not on the general battery path.

**BD-219 constraint:** a `--only-check` mode must keep these guards meaningful. Open design question for the architect (NOT decided here): with `--only-check`, the **total-run budget** (which sums ALL checks' timings) no longer has all checks to sum — the architect must decide whether `--only-check` skips the total-run FAIL (it should, since it isn't running the full set) while leaving the **per-check WARN** active (it still times the one check). The `validate` job (no flag) must keep running ALL checks so the total-run budget still guards the real surface.

---

## 2. LEVER 1 — MATRIX-SHARD THE `tests` JOB (authoritative feasibility)

### 2.1 Availability verdict (per `verify-availability-not-just-existence`)

| Capability | GA? | Usable on THIS target (personal `User` account, private repo, `ubuntu-latest`)? | Source |
|---|---|---|---|
| `jobs.<id>.strategy.matrix` | **GA** — core workflow syntax, no preview/beta marker on the feature | **YES** — works identically on personal and org accounts; not gated by plan/edition | [Using a matrix for your jobs](https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs) |
| `strategy.fail-fast`, `strategy.max-parallel`, `include`/`exclude` | GA | YES | same doc + [Workflow syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions) |
| Dynamic matrix via `fromJSON(needs.<job>.outputs.<x>)` | GA | YES | [Using a matrix for your jobs](https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs) (matrix-from-previous-job pattern) |
| Standard GitHub-hosted runner concurrency | GA | YES — **≥20 concurrent jobs even on the lowest (Free) plan** | [Actions limits](https://docs.github.com/en/actions/reference/limits) |

The two "beta"/"private preview" strings found on the matrix doc page are the docs-site UI chrome (the "Beta" tag is on the Copilot search widget; the "private preview" string is a generic banner template), NOT markers on `strategy: matrix`. The matrix feature has been GA for years and is account-type-agnostic.

### 2.2 External-rules census (per `external-rules-census-before-design`) — the complete GitHub Actions rule set relevant to sharding

Each rule quoted/cited from official docs; each mapped to the BD-219 design.

1. **Matrix max jobs = 256 per workflow run.** Quoted: *"A matrix will generate a maximum of 256 jobs per workflow run. This limit applies to both GitHub-hosted and self-hosted runners."* — [Workflow syntax for GitHub Actions](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions). **Design impact:** a ≤8-shard map is ~3% of the cap; non-binding. SUPPORTED.
2. **Total concurrent jobs (the real ceiling on parallel speedup):** measured from [Actions limits](https://docs.github.com/en/actions/reference/limits) → "Job concurrency limits for GitHub-hosted runners" table: **Free = 20, Pro = 40, Team = 60, Enterprise = 500** total concurrent standard GitHub-hosted jobs. **Design impact:** even on Free, 20 simultaneous runners ≫ a 4–8 shard map; the matrix shards will not queue behind the concurrency cap on this account. SUPPORTED. (Note: this account's exact plan was not exposed via the PAT — `gh api user .plan` returned null — but the design is safe at the FLOOR of the table, so the plan is immaterial.)
3. **Concurrency-group queue cap:** *"up to 100 jobs or workflow runs can be queued per concurrency group"* — [Actions limits](https://docs.github.com/en/actions/reference/limits). **Design impact:** only relevant if a `concurrency:` group is added; a shard map of ≤8 is far under 100. SUPPORTED.
4. **`fail-fast` semantics:** *"When `fail-fast` is enabled [the default, `true`] … if any of the jobs … fail, all jobs that are in progress or queued will be cancelled."* — [Using a matrix for your jobs](https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs). **Design impact / EFFECTIVENESS:** `fail-fast: true` would CANCEL sibling shards on the first shard failure, HIDING which other tests would have failed — a reduction in the diagnostic effectiveness of a single CI run (today every step has `if: always()` precisely so all failures surface). **The shard matrix MUST set `fail-fast: false`** to preserve the current "one failure surfaces all" behavior. This is a hard requirement, not a preference.
5. **`max-parallel`:** *"To set the maximum number of jobs that can run simultaneously … use `jobs.<job_id>.strategy.max-parallel`."* — same doc. **Design impact:** optional; only needed if the design wants to cap below the account concurrency. Not required at ≤8 shards.
6. **Required status checks + matrix naming:** matrix jobs surface as SEPARATE status checks named `<job-name> (<matrix-value>)` (e.g. `tests (shard-1)`). Branch-protection required checks match by exact name. Official guidance: *"make sure that job names are unique across all workflows"* and *"The name key and required job name … must be the same."* — [Troubleshooting required status checks](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks). **Design impact — see §2.3 (the critical question).**
7. **Do NOT path/branch-filter a required workflow:** *"if a workflow is skipped due to path filtering, branch filtering or a commit message, then checks associated with that workflow will remain in a 'Pending' state, and a pull request that requires those checks … will be blocked."* — same troubleshooting doc. **Design impact:** reinforces the §6 "Rejected" entry on path-filtered skipping — it both reduces effectiveness AND can wedge branch protection. SUPPORTED (as a prohibition).
8. **Dependent job on a matrix:** *"a dependent job will wait for all matrix job combinations to finish"* and *"if a job fails or is skipped, all jobs that need it are skipped unless … a conditional expression."* — [Using jobs in a workflow](https://docs.github.com/en/actions/using-jobs/using-jobs-in-a-workflow) + [Using a matrix](https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs). **Design impact — see §2.3.**

### 2.3 The required-status-check-with-matrix question (the BD called this out explicitly)

**Question:** does a branch-protection "Validate Pack / tests" required check still gate correctly when `tests` is sharded?

**Answer (authoritative):** **NO, not automatically — a check literally named `tests` ceases to exist once `tests` becomes a matrix.** The matrix produces checks named `tests (shard-1)`, `tests (shard-2)`, …. A branch-protection rule that required `tests` would then **never be satisfied** (the named check never reports) and would BLOCK merges, OR (if the rule is by job and GitHub maps it) behave ambiguously. Two GA-supported remediations:

- **(A) Require each shard check** — list `tests (shard-1) … tests (shard-N)` as required checks. Downside: the required-check list must be edited every time the shard COUNT changes (drift surface; couples branch protection to the shard map).
- **(B) Aggregation job (RECOMMENDED pattern, GA):** add a final job (e.g. `tests-result`) with `needs: [tests]`. It runs once after all shards. Make the **stable name `tests-result`** (or keep a job named `tests` as the aggregator and rename the matrix job) the single required status check. **Critical gotcha to flag:** by GitHub's default, a `needs:` job is **SKIPPED** (not failed) if a needed matrix job fails — and a *skipped* required check can let a PR through. The aggregation job therefore MUST use `if: always()` AND explicitly assert success, e.g. a step that fails unless `needs.tests.result == 'success'`. This makes the aggregator FAIL (not skip) when any shard fails. Cited behavior: dependent-job skip-on-failure — [Using jobs in a workflow](https://docs.github.com/en/actions/using-jobs/using-jobs-in-a-workflow); `always()` override — [Evaluate expressions](https://docs.github.com/en/actions/learn-github-actions/expressions).

**Note on current state:** the workflow header (yml lines 75–78) DOCUMENTS branch protection as a "one-time repo admin action" requiring the `validate` and `tests` checks, but the repo is private and the actual rule config was not inspected in this read-only pass (a branch-protection read is a separate admin surface; flagged for the architect to confirm whether a rule is live before renaming the `tests` job). Whether or not a rule is currently live, the architect's design MUST account for option (B) so a future rule keeps gating correctly.

### 2.4 Results aggregation & how a sharded run reports

- A `needs: [tests]` aggregation job waits for ALL shards (rule 8) and, with `if: always()` + the explicit `result == 'success'` assertion, yields ONE green/red signal. This is also the natural home for the **"the full wired test list still ran"** acceptance check (it can read the shard map and assert coverage — see §7).
- With `fail-fast: false` (rule 4) every shard runs to completion regardless of sibling failures, preserving the current `if: always()` "surface all failures" property — but now the per-shard logs are where failures live; the aggregator summarizes.

### 2.5 Sharding mechanics the architect can choose between (all GA)

- **Static shard map (explicit):** `strategy.matrix.shard: [1,2,3,4]` + each shard runs a known sublist. Sublists can be an explicit array per shard (most legible; pairs with measured-balance §6A) or derived at runtime by a deterministic partition of a script list.
- **Dynamic matrix:** a tiny upstream job emits the shard→scripts JSON to `$GITHUB_OUTPUT`; the `tests` job does `strategy.matrix: ${{ fromJSON(needs.plan.outputs.matrix) }}` (rule: matrix-from-previous-job, GA). This lets the partition be COMPUTED (e.g. by measured durations) so adding a script never requires hand-editing shard arrays — directly supports the anti-drift goal (§7). Cited: [Using a matrix for your jobs](https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs) (define-matrix-in-one-job → fromJSON-in-another).
- **Fixture-build constraint (correctness, not perf):** the fixture-dependent tests — `persona contracts`, `migrator-skills`, `fixture manifest verify`, `v11-realistic-ot` (yml lines 50–67 enumerate them) — require `test-fixtures/build.sh --all --clean` (+ the BD-118 manifest-restore) to have run earlier IN THE SAME RUNNER. Under sharding, fixtures are gitignored build artifacts that do NOT exist until built, and each shard is a fresh runner. So either (a) every shard that contains a fixture-dependent test must run the build step first, or (b) fixture-dependent tests are grouped into one shard that builds fixtures. The architect must preserve the BD-163 step-ordering invariant within whatever shard owns those tests. This is an effectiveness/correctness constraint the shard partition MUST respect.

---

## 3. LEVER 2 — `validate-pack.py --only-check <N>`/`NAME` (authoritative feasibility)

### 3.1 Feasibility verdict — greenfield, clean

- **`validate-pack.py` currently has NO argparse.** `grep -cE 'import argparse|add_argument|ArgumentParser' scripts/validate-pack.py` → **0**. `main()` (line 9338) runs every check unconditionally via `run_check(...)` calls. So `--only-check` is a greenfield addition, not a refactor of existing arg handling.
- **`argparse` is Python stdlib** — always available; no new dependency. Verified `python3 -c "import argparse"` → OK. (Authoritative: [argparse — Parser for command-line options](https://docs.python.org/3/library/argparse.html).) The CI runner pins Python 3.12 (yml line 93); argparse semantics used here (`add_argument`, `choices`, `nargs`) are GA since Python 2.7/3.2 — no version risk on 3.12.
- **The module-import path the per-check tests rely on is preserved by the existing `if __name__ == "__main__":` guard** (line 9621). Per-check tests do `importlib.util.spec_from_file_location('vp', VALIDATE)` and call the check function directly — importing does NOT execute `main()`, so adding argparse INSIDE `main()`/the `__main__` block does not break the import path. (Verified the import pattern in `test-validate-pack-check-52.sh` lines 49–51, 76–78.)

### 3.2 The exact contract the architect must specify (problem framing, NOT a design)

The architect needs to define (this report only enumerates the decision points + the constraints each must satisfy):
1. **Selector shape:** `--only-check <N>` (numeric, e.g. `52`) and/or `--only-check NAME` (function/label, e.g. `check_pack_agent_trinity` or the `run_check` label). The repo's checks are addressed two ways today: numeric "Check NN" in output banners + the `run_check("name", fn)` label string. The architect must pick the stable key. Constraint: the key must survive check renumbering/renaming without silently selecting the wrong check (tie to the §7 guard).
2. **No-flag behavior = ALL checks** (hard constraint, BD acceptance criterion): the `validate` job runs `python3 scripts/validate-pack.py` with NO flag and MUST still run the complete set. Verified the `validate` job (yml lines 96–104) passes no selector — so as long as `--only-check` is opt-in, the full-coverage job is unaffected.
3. **Effectiveness preservation in the per-check tests:** the per-check tests today assert two things — (a) module-import unit assertions on the check's internals (already in-process, already fast, UNCHANGED), and (b) ONE end-to-end `python3 …/validate-pack.py` "exits 0 / Check NN ran clean at HEAD". Adopting `--only-check NN` for leg (b) means the e2e leg runs only its target check. **Constraint:** the e2e leg must still prove the check RUNS and reaches a verdict (the current assertion). Switching to `--only-check` must NOT weaken that — it narrows WHICH checks run in that subprocess, not WHETHER the target check's assertion fires. Mutation-proof requirement is already in the BD acceptance criteria.
4. **Runtime-guard interaction (from §1.6):** with `--only-check`, the total-run budget (sum of ALL checks) is not meaningful (not all checks ran) → the architect should specify that `--only-check` suppresses the total-run FAIL while keeping the per-check WARN (`run_check` still times the single check). The no-flag `validate` job keeps the total-run budget live.
5. **Exit-code contract:** `--only-check` must exit non-zero iff the selected check FAILs (so the per-check test's `if python3 … ; then PASS` logic still works). An unknown check name/number should be a loud error (non-zero, named), not a silent no-op pass — a silent no-op would let a typo'd selector turn a per-check test into a tautology (effectiveness loss).

### 3.3 Quantified gain (do not oversell)

- Per-check e2e leg today ≈ ~1.2 s (one full general run). `--only-check` reduces it to ~the cost of one check + import (~tens of ms to maybe ~0.2–0.4 s for import overhead). Saving ≈ **~0.8–1.1 s per per-check test**.
- ~23 per-check tests + a few others → **realistic total saving ≈ ~25–30 s**, all inside the ~76 s validate-pack-step bucket, i.e. **~5–6% of the ~462 s tests-job** — and that 5–6% only materializes if those steps are NOT already overlapped by sharding (under sharding they run in parallel with the long poles anyway). **Net: Lever 2 is a correctness-of-pattern cleanup with a small standalone win; under sharding its marginal wall-time contribution shrinks further.**
- **It does NOTHING for the 94 s/61 s/52 s migrate/tracker-migrate long poles** (they never call validate-pack).

---

## 4. WHY THE LEVERS COMBINE THE WAY THEY DO (for the architect's prioritization)

- The wall-time is `tests`-job ≈ Σ(sequential step times) ≈ 462 s. Sharding turns Σ into max-over-shards. The theoretical floor of any shard is its single longest member: **the 94 s `migrate-gates` step is the hard floor** unless that test is itself made faster (§6E, bounded). So:
  - **2 shards:** ~max(largest-balanced-half) ≈ ~240–260 s.
  - **4 shards (measured-balanced):** ~max ≈ ~120–160 s (bounded below by 94 s + co-located neighbors + ~7 s setup).
  - **6–8 shards:** diminishing returns — you cannot go below the 94 s longest single test (plus its shard's setup). More shards mainly add aggregate setup cost.
- **Therefore the highest-leverage architect decisions are:** (1) shard COUNT chosen so the longest shard ≈ the longest single test (≈4 is the natural knee given a 94 s max and ~462 s total); (2) **measured-balance** the partition so the 94/61/52/34/31/29 s heavyweights are spread across shards rather than colliding; (3) whether to ALSO attack the 94 s test internally (§6E) to lower the floor below 94 s — only if effectiveness is provably unchanged.

---

## 5. (reserved — merged into §6)

## 6. ADDITIONAL EFFECTIVENESS-PRESERVING MECHANISMS (enumerated; each with source + gain + effectiveness assessment)

### Recommended (zero effectiveness impact)

| ID | Mechanism | Authoritative source | Expected gain | Effectiveness impact |
|---|---|---|---|---|
| **A** | **Measured-balance shard partition** (bin-pack scripts by their measured CI step duration so the slowest shard is minimized) instead of name-hash. The §1.2 per-step CI durations are the input. | Matrix is GA: [Using a matrix](https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs); dynamic matrix: same doc (`fromJSON(needs.*.outputs.*)`). | Turns a naive 4-shard (~max could be 94+61=155 s if heavies collide) into ~max ≈ ~120–160 s; biggest multiplier on Lever 1. | **ZERO** — same scripts, same assertions, only the runner assignment changes. |
| **C** | **Co-locate fixture-dependent tests + build fixtures only in shards that need them** (don't run `build.sh --all --clean` in shards with no fixture-dependent test). | yml lines 48–67 (BD-163 ordering invariant); `test-fixtures/build.sh`. | Saves the ~6 s build + manifest-restore in shards that don't need fixtures; also a CORRECTNESS requirement (fixtures are gitignored, per-runner). | **ZERO** (and prevents a correctness regression). |
| **B** | **Keep `validate` + deep-`validate` parallel and unsharded** (already the case; the `validate` job is ~15 s and not the long pole). Preserve the `PACK_VALIDATE_DEEP=1` ENV-gate so the deep leg runs ONCE, not on the battery. | yml lines 84–104; validator lines 7689–7697. | Preserves the existing ~1.5 h-incident mitigation; no new gain but prevents a regression. | **ZERO** (preservation). |
| **D** | **`actions/setup-python` `cache: pip`** keyed on a deps file. | [actions/setup-python README — caching](https://github.com/actions/setup-python) + [caching ADR](https://github.com/actions/setup-python/blob/main/docs/adrs/0000-caching-dependencies.md). | **Near-zero** here — total setup is ~7 s and `pip install pyyaml` is trivial; under sharding the cost is paid per shard, so caching is at best a wash. List as available; do NOT prioritize. Note: there is no `requirements.txt`/`pyproject.toml` today, so a cache key would need one added. | **ZERO** (but low/no value). |

### Candidate — potentially large but BOUNDED/FLAGGED (must be effectiveness-proven per case; NOT a free win)

| ID | Mechanism | Why bounded | Effectiveness risk |
|---|---|---|---|
| **E** | **Reduce subprocess churn inside the long-pole tests** (`test-migrate-v10-to-v11-gates.sh` 94 s, `tracker-migrate-forward-test.sh` 61 s, etc.). These spawn many full migrations / `gh`-stub iterations (measured: gates runs ~33 migration/init invocations; tracker-migrate-forward ~125 loop/gh sites). Lowering per-iteration spawn cost (shared setup, batched fixtures, fewer redundant full-migration runs) would lower the 94 s FLOOR that bounds the whole sharded design. | This is a TEST-INTERNAL refactor, not a CI-config change. It changes HOW the test runs, which risks changing WHAT it proves. | **MEDIUM-HIGH** — must be proven effectiveness-neutral per test (every assertion preserved; mutation-tested). Surface to the architect as a separate, optional, per-test-justified line of work — explicitly NOT bundled into the sharding lever. Out of the BD's two named levers; the architect/user decides whether to scope it in. |

### REJECTED (would reduce effectiveness — do NOT recommend as wins)

| Mechanism | Why rejected (effectiveness reason) | Source |
|---|---|---|
| **Path-filtered / changed-files conditional test skipping** (run only tests "related" to changed paths) | Changes WHICH tests run against WHICH inputs → a regression in an un-skipped area would be missed by that run; BD-219's HARD constraint is "every test still runs." Also wedges branch protection: a path-skipped required workflow stays "Pending" and BLOCKS merge. | BD-219 scope; [Troubleshooting required status checks](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks) |
| **Sampling / running a subset of fixtures or checks per push** | Reduces coverage per run by construction. | BD-219 scope |
| **Result caching that could serve stale results** (cache test outcomes keyed on a coarse hash) | Could pass a test on stale cached output when the real inputs changed → false green. | BD-219 scope; general CI-caching hazard |
| **`fail-fast: true` on the test matrix** | Cancels in-progress sibling shards on first failure → hides which other tests would have failed; contradicts today's `if: always()` "surface all failures." | [Using a matrix](https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs) (fail-fast semantics) |
| **Dropping the redundant full-validator e2e leg from per-check tests** (instead of `--only-check`) | The e2e leg proves the check is WIRED INTO `main()` and runs at HEAD — removing it weakens the assertion. `--only-check` is the effectiveness-preserving alternative (narrow the run, keep the assertion). | §1.4 / §3.2 |

---

## 7. UPKEEP / ANTI-DRIFT — WHERE/HOW THE ARCHITECT SHOULD DESIGN THE GUARD (options + evidence; NOT a design)

Per `ci-guard-design-measure-then-bound`: the guard must be MEASURED against current state, every occurrence categorized KEEP/STRIP, the allowlist sized exactly to the legitimate set, and verified clean against the projected post-fix tree. This section supplies the MEASUREMENT and frames the options so the architect can do the categorize/bound steps.

### 7.1 The two drift axes BD-219 introduces or exposes

1. **Wiring drift (pre-existing, partially guarded):** a test script on disk that is wired into NO CI step. **Measured today: 9 such scripts** (§1.3 list). The existing guard **Check 42** (`check_ci_workflow_wires_per_check_tests`, validator lines 6688–6781) covers ONLY the glob `scripts/tests/test-validate-pack-check*.sh` — it does NOT see the other 9 (they are tracker-*, promote-*, capability-*, agent-trinity, dry-run, restore-from-backup). So 8 of the 9 fall entirely outside any guard; the design's wiring-completeness acceptance criterion currently has no enforcer for non-per-check tests.
2. **Shard-coverage drift (new with sharding):** a test that IS wired but lands in NO shard (or in two shards). This axis does not exist today (single sequential list); sharding creates it. The BD acceptance criterion "a wiring-completeness guard proves every test lands in exactly one shard" targets exactly this.

### 7.2 Measured current state for the guard (the measure step)

- **Disk test-runner scripts (candidate "should run" set):** 70 files (`scripts/test*.sh` + `scripts/tests/*.sh`). NOT all are CI-eligible — at least the 3 live-GH `test-tracker-promote-*` and possibly `tracker-bd204-lossless-roundtrip-test.sh` may be intentionally manual (they touch GH/round-trip surfaces). **The architect must categorize each of the 70 (or the 9 currently-unwired) as KEEP-in-CI vs intentionally-OUT, and size the guard's expected-wired set to the KEEP set** — exactly the measure-then-bound contract. This report does NOT pre-decide that categorization (that would widen/narrow the allowlist without the architect's KEEP/STRIP analysis).
- **Wired set:** 61 distinct scripts (§1.3), reconciled two ways.
- **Existing enforcement surface:** Check 42 (per-check only), plus the workflow header comment (yml lines 5–9) which is documentation, not enforcement.

### 7.3 Options for the guard's home + shape (evidence-backed; architect chooses)

| Option | Where | How it would work | Evidence / fit |
|---|---|---|---|
| **O1 — Extend Check 42 in `validate-pack.py`** to a general "every CI-eligible test script is wired" set-equality (disk KEEP-set ↔ workflow `bash` invocations), beyond just per-check files. | `scripts/validate-pack.py` (new/extended check) | Set-equality both directions over the KEEP-set allowlist; FAIL names the un-wired (or stale) script. Mirrors Check 42's existing disk↔workflow diff and the Check 32/45 set-equality pattern already in the file. | Check 42 ALREADY owns this comparison for a subset; generalizing keeps one mechanism. Note `ci-check-runtime-compounding`: this check is a cheap glob+regex over two files — runs in ms, no per-entry subprocess; safe at the battery's ~24 validate-pack invocations. |
| **O2 — Shard-coverage guard** asserting the shard map partitions the wired set EXACTLY (every wired test in exactly one shard; union of shards == wired set; intersection empty). | If shard map is a committed file (static) → a `validate-pack.py` check reading it; if dynamic (computed in a job) → the aggregation job (§2.4) recomputes and asserts coverage at run time. | The shard map is the bounded allowlist source; the guard diffs map-union vs wired-set. | Pairs with the dynamic-matrix pattern (§2.5) — if the partition is COMPUTED from the wired list, coverage is correct by construction and the guard just re-verifies. |
| **O3 — Make the shard partition derive from the wired list at runtime** (no hand-maintained shard arrays). | Upstream `plan` job emits `fromJSON` matrix from the discovered wired-test list (§2.5). | A new test cannot "fall out of all shards" because the partition is generated from the same list the wiring guard checks. | Strongest anti-drift: removes the hand-edited shard array as a drift surface entirely. Cited GA pattern: dynamic matrix from job output — [Using a matrix](https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs). |
| **O4 — Full-check-set invariant** asserting the `validate` job still runs ALL checks (no `--only-check` leaked into the full job; the check count is unchanged). | `validate-pack.py` self-introspection (count `run_check` callsites / a registry) + a CI assertion. | Guards Lever 2's "no check silently dropped from the full run" criterion. | Ties to the BD criterion "the COMPLETE set of checks still runs in the `validate` job." The validator already routes every check through `run_check` (line 9348+), so a registry/count is enumerable. |

### 7.4 What a CI-enforced invariant should assert (so the architect can bound it)

- **"No test silently un-sharded":** `union(shards) == wired_KEEP_set` AND shards are pairwise disjoint. (O2/O3.)
- **"No CI-eligible test silently un-wired":** `wired_set == disk_KEEP_set`. (O1 — generalizes Check 42.)
- **"The full check set still runs":** the `validate` job runs with no `--only-check`; the live check count == the expected count. (O4.)
- **Ownership of shard rebalancing:** if the partition is hand-maintained (O2 static), rebalancing is a human task that drifts as durations change — recommend a periodic measure (the §1.2 method: `gh run view --json jobs`) or, better, O3 (derive at runtime) so balance self-maintains by current durations. The architect should pick where "rebalance" lives and what triggers it (e.g. a soft WARN when one shard exceeds X× the median, surfaced by the aggregation job).
- **Measure-then-bound discipline:** every guard above sizes its allowlist to the KEEP-set the architect categorizes — NOT broadened to swallow the currently-unwired 9 without classifying each. A guard that simply allowlists all 9 unwired scripts to make itself green would be treating drift as legitimate (the exact anti-pattern `ci-guard-design-measure-then-bound` forbids).

### 7.5 Runtime-cost note for any new guard (per `ci-check-runtime-compounding`)

Any new `validate-pack.py` check (O1/O2/O4) runs on the general battery path (~24 spawns). It MUST be cheap: glob + regex over `.github/workflows/validate-pack.yml` + a directory listing (microseconds–milliseconds), NO subprocess-per-script, scoped to the caller's tree (not a hardcoded real-tree scan). It should route through `run_check` so the per-check WARN budget (2.0 s) catches any regression. A shard-coverage guard that lives in the aggregation JOB (O2-dynamic/O3) runs once per CI run, not on the battery — preferable for anything heavier.

---

## 8. OPEN ITEMS / FLAGS FOR THE ARCHITECT (not decided here)

1. **The BD's "238 validate-pack invocations" is an over-estimate** of the real cost driver (true full-validator subprocess spawns ≈ 24–27). The BD's "each of 238 invocations does ~1/56th the work" rationale should be corrected — the realistic Lever-2 saving is ~25–30 s total. (§1.4)
2. **The BD's framing implies the per-check validate-pack tests are the long pole; they are not** — the migrate/tracker-migrate tests (94/61/52 s, zero validate-pack calls) dominate. Sharding is the dominant lever; `--only-check` is secondary. (§1.2, §4)
3. **Branch-protection rename hazard:** turning `tests` into a matrix renames its status check; if a required check named `tests` is live, it must be re-pointed to an aggregation job (§2.3 option B with the `if: always()` + `result=='success'` gotcha). Confirm the live rule before renaming. (§2.3)
4. **9 currently-unwired test scripts** need KEEP/STRIP categorization before the wiring guard's allowlist is sized. (§1.3, §7.2)
5. **Fixture-build + BD-163 ordering invariant** must be preserved within whatever shard owns the fixture-dependent tests. (§2.5)
6. **`PACK_VALIDATE_DEEP=1` ENV-gate and all six runtime guards (§1.6) must be preserved**; `--only-check` must define its interaction with the total-run budget. (§1.6, §3.2)
7. **Account plan not exposed** via PAT (`gh api user .plan` → null); design is safe at the Free-plan floor (20 concurrent jobs), so the plan is immaterial for ≤8 shards. (§2.2)

---

## SOURCES (external, with URLs)

- GitHub Actions — Using a matrix for your jobs (matrix, fail-fast, max-parallel, dynamic matrix `fromJSON`): https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs
- GitHub Actions — Workflow syntax (256-job matrix cap; `jobs.<id>.name`): https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions
- GitHub Actions — Actions limits (concurrent-job table: Free 20 / Pro 40 / Team 60 / Enterprise 500; 100-per-concurrency-group queue): https://docs.github.com/en/actions/reference/limits
- GitHub Actions — Using jobs in a workflow (`needs:` waits for all matrix combinations; skip-on-failure): https://docs.github.com/en/actions/using-jobs/using-jobs-in-a-workflow
- GitHub — Troubleshooting required status checks (matrix check naming; unique job names; do-not-path-filter-a-required-workflow): https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks
- GitHub Actions — Evaluate expressions (`always()`): https://docs.github.com/en/actions/learn-github-actions/expressions
- GitHub — About protected branches: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches
- actions/setup-python (pip caching): https://github.com/actions/setup-python — caching ADR: https://github.com/actions/setup-python/blob/main/docs/adrs/0000-caching-dependencies.md
- Python — argparse: https://docs.python.org/3/library/argparse.html
- Community discussion — status check for matrix jobs (aggregation pattern): https://github.community/t/branch-protections-job-names-and-matrix-jobs/16317

---

## RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted / measured) | Conclusion |
|---|---|---|
| **agents-never-commit** | Only read-only git verbs used: `git rev-parse HEAD` → `1f95b8e…`, `git status --short`, `git branch --show-current` → `v11-dev`. No `add`/`commit`/`push`/`checkout`/etc. issued. Single write = this report at `maintenance-docs/v11-implementation/RESEARCH-BD-219-CI-RUNTIME-OPTIMIZATION.md` (allowed RO-agent report write). No source file edited. | COMPLIANT |
| **researcher-maps-blast-radius-before-architect** | Counts reconciled multiple ways: test scripts wired = 61 (two methods, §1.3); on-disk = 70; unwired = 9 (`comm -23`, listed); reverse `comm -13` = EMPTY. validate-pack invocations measured 4 ways (260/259/173 textual; ~24 subprocess spawns) and the BD's 238 explicitly flagged un-reconcilable (§1.4). Per-job + per-step CI timings pulled from `gh run view` across 4 runs (§1.1–1.2). Existing runtime guards enumerated from source line numbers (§1.6). | COMPLIANT |
| **verify-availability-not-just-existence** | Target axes verified: account `gh api user --jq .type` → `"User"` (personal, not org); repo `visibility` → `PRIVATE`; runner `ubuntu-latest`. Availability matrix in §2.1 with per-row GA + usable-on-target verdict + citations. Concurrency floor (Free=20) measured from the limits table → design safe regardless of unexposed plan (§2.2 rule 2, §8 item 7). Matrix confirmed GA (the only "beta/preview" strings are docs-site UI chrome, stated §2.1). | COMPLIANT |
| **external-rules-census-before-design** | §2.2 enumerates the COMPLETE GitHub-Actions rule set relevant to sharding — 8 rules (256-job cap, concurrent-job table, 100/group queue, fail-fast, max-parallel, required-check naming, no-path-filter-required-workflow, needs-on-matrix), each quoted + cited + mapped to a SUPPORTED design impact. | COMPLIANT |
| **ci-check-runtime-compounding** | Grounded the analysis in cost = per-run × battery-count: measured ~24 full-validator spawns × ~1.2 s ≈ ~29 s redundant (§1.5); confirmed the deep-leg ENV-gate mitigation is in place (validator 7689–7697; yml 103–104) and required it be preserved (§1.6); required any new guard be cheap/non-subprocess-per-script (§7.5). | COMPLIANT |
| **ci-guard-design-measure-then-bound** | §7 supplies the MEASURE step (9 unwired scripts; 61 wired; 70 disk; Check 42 coverage gap) and frames the guard so the architect categorizes KEEP/STRIP and sizes the allowlist to the KEEP-set — explicitly refusing to pre-decide categorization or allowlist all 9 (§7.2, §7.4 last bullet). | COMPLIANT |
| **scope-deliverables-to-the-ask** | Report delivers exactly the charge: re-measured blast radius, two-lever feasibility w/ the required-check question, additional mechanisms w/ source+gain+effectiveness, upkeep options. No design, no implementation, no edits beyond this report. Out-of-scope BD-219 cleanup (3 stale Check-54 comments) noted as out-of-scope, not investigated. | COMPLIANT |
| **rules-applied-verification-block** | This table — per-rule, with quoted/measured evidence and a terminal COMPLIANT/N/A/VIOLATED conclusion (no empty evidence; no AMBIGUOUS). | COMPLIANT |
