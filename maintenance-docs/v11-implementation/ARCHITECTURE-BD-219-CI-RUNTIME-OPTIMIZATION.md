<!-- pack-only architecture artifact — feeds the BD-219 planner → coder. Not a client deliverable. -->
# ARCHITECTURE — BD-219 CI Runtime Optimization (effectiveness-preserving)

**Architect:** pack-architect (design stage; AFTER the researcher; feeds the planner)
**Date:** 2026-06-14 · **Repo HEAD at design:** `1f95b8eedd9fa21b7c9a824736648599c543bb2d` (branch `v11-dev`)
**Primary input:** `maintenance-docs/v11-implementation/RESEARCH-BD-219-CI-RUNTIME-OPTIMIZATION.md` (its load-bearing measurements RE-VERIFIED here — see the Empirical-Evidence Blocks).
**Account/runner target:** personal GitHub **User** account; repo **PRIVATE**; runners `ubuntu-latest` (standard GitHub-hosted).

---

## READ ATTESTATION (each read IN FULL, no skim/crop/derive)

| Doc | Read |
|---|---|
| `CLAUDE.md` § "## Pack memory" (P-missed-7, CI-guard + boundary rules) | YES (full, via session context) |
| `backlog/BD-219.md` (incl. the two 2026-06-15 reframe/scope notes) | YES (lines 1–22, full) |
| `maintenance-docs/v11-implementation/RESEARCH-BD-219-CI-RUNTIME-OPTIMIZATION.md` | YES (lines 1–357, full) |
| `.github/workflows/validate-pack.yml` | YES (lines 1–324, full) |
| `scripts/validate-pack.py` — `run_check`, budgets, `main()`, total-run guard, `__main__`, Check 42, the 3 "Check 54 reserved" sites | YES (435–494, 6652–6782, 9338–9623) |
| `…/memory/feedback_ci_guard_design_measure_then_bound.md` | YES (full) |
| `…/memory/feedback_ci_check_runtime_compounding.md` | YES (full) |
| `…/memory/feedback_architect_planner_empirical_evidence.md` | YES (full) |
| `…/memory/feedback_pack_project_separation_of_concerns.md` | YES (full) |
| `…/memory/feedback_bd_pack_only_operational_rule.md` | YES (full) |
| `…/memory/feedback_verify_availability_not_just_existence.md` | YES (full) |
| `…/memory/feedback_preliminary_triage_architect_challenge.md` | YES (full) |

All load-bearing research measurements were INDEPENDENTLY re-run at HEAD `1f95b8e` on 2026-06-14 (Empirical-Evidence Blocks §EE-1…§EE-9). I did not ratify the research; I challenge its priorities in §3 and §4 and confirm/correct each measured claim.

---

## 0. EXECUTIVE SUMMARY

### The design in brief

BD-219's wall-time is the `tests` job (~441–464 s; the `validate` job is ~12–15 s and runs in parallel, so it is NOT the long pole — RE-CONFIRMED §EE-1/§EE-2). The dominant, near-linear, zero-effectiveness-cost win is **matrix-sharding the `tests` job**. Everything else is secondary.

1. **Matrix-shard the `tests` job into 4 shards via a DYNAMIC matrix.** A tiny upstream `plan` job emits the shard→scripts partition as JSON to `$GITHUB_OUTPUT`; the `tests` job consumes it via `strategy.matrix: ${{ fromJSON(needs.plan.outputs.matrix) }}` with `fail-fast: false`. The partition is computed by a single committed Python module (`scripts/lib/ci-shard-plan.py`) that bin-packs the wired-test list by measured per-script duration (stored in a committed `scripts/ci-shard-weights.tsv`). A final `tests-result` aggregation job (`needs: [plan, tests]`, `if: always()`, with an explicit `needs.tests.result == 'success'` assertion) is the SINGLE branch-protection required status check. 4 shards drops the tests job from ~462 s to a measured-balanced max-shard of ~140–160 s (floored by the 94 s `migrate-gates` test). Availability RE-VERIFIED: matrix + dynamic-matrix + `fail-fast` are GA and account-type-agnostic; concurrency floor (Free=20) ≫ 4 shards.

2. **Upkeep / anti-drift guard (core scope), measure-then-bound.** I MEASURED the full test-script set (70 on disk; 61 wired; 9 unwired — RE-CONFIRMED §EE-3) and CATEGORIZED every script KEEP-in-CI vs intentionally-OUT (§5.2 table). The wiring-completeness invariant is a **generalized Check 42** (renamed conceptually to "CI wires every CI-eligible test") doing set-equality `disk_KEEP_set == wired_set`, with a measured allowlist sized to exactly the legitimately-excluded scripts. The shard-coverage invariant (`union(shards) == wired_KEEP_set`, pairwise-disjoint) is **correct-by-construction** because the partition is GENERATED from the wired list by the shared `ci-shard-plan.py` module — the same module the aggregation job re-runs to assert coverage at run time. No hand-maintained shard map. Both guards are cheap (glob + regex over two files; no subprocess-per-script) and route through `run_check` so the per-check WARN budget catches any regression.

3. **`--only-check` (Lever 2) — RECOMMENDATION: KEEP, but as a SMALL, clearly-secondary win.** I re-validated the saving: 24 full-validator subprocess spawns across the wired battery (RE-CONFIRMED §EE-5, NOT the BD's "238"); each per-check test's e2e leg is ~1.2 s (RE-CONFIRMED §EE-6); `--only-check NN` shrinks each to ~0.2–0.4 s, saving ~0.8–1.1 s × ~24 ≈ **~22–26 s total** (my measured estimate; consistent with the research's ~25–30 s). Against the user's stated constraint — "a confirmed ~6% / ~25–30 s saving IS worth keeping if the maintenance surface is reasonable" — the saving is REAL (≈5–6 % of the tests job standalone) and the maintenance surface is modest (a single greenfield argparse block in one already-CI-guarded file; no current argparse to refactor — §EE-7). **KEEP.** The full `validate` job keeps running with NO flag = all 57 checks (§EE-8). A new Check guards "the full job carries no `--only-check`" so the flag can never silently narrow the authoritative run. IMPORTANT effectiveness nuance: the e2e leg today implicitly proves the check is WIRED INTO `main()`; under `--only-check` that proof moves to a small `main()`-wiring registry assertion (§6.4) so no assertion is weakened.

4. **PROJECT-SIDE recommendation: SHIP NOTHING MECHANICAL; SHIP ONE SHORT PROJECT-NATIVE DOC NOTE.** Investigated (§7): the pack ships clients NO CI workflow (only GitHub Issue forms under `project-template/.github/ISSUE_TEMPLATE/`) and NO multi-script meta-battery (client `test.sh` is a language-detecting wrapper around the project's own `swift test`/`pytest`). There is no client-side surface to shard and no client `validate-pack`-equivalent to give `--only-check`. Shipping the mechanism would be wasted effort AND a boundary risk (`validate-pack.py` is pack-only). RECOMMEND: a single short, project-native, boundary-compliant note in `project-template/docs/pack/OPTIONAL-FEATURES.md` (a new "CI test parallelization" entry, project-native vocabulary only — GitHub Actions `strategy: matrix`, no BD-NNN / pack-* / pack-ops refs) so PM chats can PROACTIVELY tell their users "if your CI runs a multi-suite battery sequentially, `strategy: matrix` parallelizes it." This is a SEPARATE `project-only` commit, distinct from the pack-only commits.

5. **Commit decomposition (§8):** three pack-only commits (C1 `--only-check` + the 3 stale Check-54 comment strips; C2 the shard infra + dynamic matrix + aggregation job; C3 the generalized wiring/shard-coverage/full-run guards + their tests + manifest) + one project-only commit (C4 the OPTIONAL-FEATURES note). C1 and C3 partition cleanly for the coder's worktree-isolation trial (disjoint files); C2 depends on nothing in C1/C3 at author time but the required-check rename in C2 must be coordinated with the live branch-protection rule (§2.4).

### What I challenge in the research (preliminary-triage-architect-challenge)

- I CONFIRM the reframe: sharding dominant, `--only-check` secondary. I do NOT ratify "present `--only-check` as a modest secondary gain" into a DROP — I independently measured the saving and the maintenance surface and conclude KEEP, per the user's explicit constraint.
- I REJECT the research's static-shard-map option (§7 O2-static) as the primary mechanism: a hand-maintained shard array is itself a drift surface. I select the DYNAMIC, generated partition (research O3) so shard-coverage is correct-by-construction — this is a stronger reading of `ci-guard-design-measure-then-bound` than "add a guard over a hand-list."
- I treat the research's "candidate E" (refactor the 94 s/61 s long-pole tests internally) as OUT OF SCOPE for BD-219 (effectiveness-proof risk; not one of the two named levers) and surface it as a future BD, not absorb it.

---

## 1. PROBLEM RESTATEMENT (corrected premise)

Wall-time = the `tests` job ≈ 462 s (Σ of ~63 sequential `bash` steps in one runner). The `validate` job (~15 s, general + deep validate-pack) runs in PARALLEL and is not the long pole. The slowest steps call `validate-pack.py` ZERO times (migrate/tracker-migrate). Therefore:

- **Sharding** turns Σ(steps) into max-over-shards → the only lever that touches the real long poles. **Dominant.**
- **`--only-check`** touches only the ~76 s of validate-pack steps (~16 % of the job), realistic saving ~22–26 s. **Secondary but real; KEEP.**
- **pip caching** is ~0 here (setup ≈7 s; paid per shard). NOT pursued.

HARD CONSTRAINT (non-negotiable): effectiveness unchanged. Every check still runs in the full `validate` job (no flag = all); every wired test still runs (sharded, none dropped); every assertion preserved; the six runtime guards (§EE-9) preserved.


---

## 2. MATRIX-SHARD DESIGN (Lever 1 — the dominant win)

### 2.1 Availability (RE-VERIFIED; verify-availability-not-just-existence)

| Capability | GA? | Usable on this target (personal User account, private repo, ubuntu-latest)? | Basis |
|---|---|---|---|
| `jobs.<id>.strategy.matrix` | GA | YES — core workflow syntax, account-type-agnostic | Research §2.1 (cited GH docs) + my read of the existing workflow uses no preview features |
| `strategy.fail-fast: false` | GA | YES | Research §2.2 rule 4 |
| Dynamic matrix `fromJSON(needs.<job>.outputs.<x>)` | GA | YES | Research §2.2 + §2.5 (matrix-from-previous-job pattern) |
| `needs:` waits for all matrix combinations; aggregation job | GA | YES | Research §2.2 rule 8 |
| `if: always()` + `needs.*.result` expression | GA | YES | Research §2.3 (B) |
| Concurrent-job floor (Free=20) | GA | YES — 4 shards ≪ 20 | Research §2.2 rule 2 (safe at the floor; plan immaterial) |

I rely ONLY on these GA, target-available features. No org-only, preview, or higher-plan feature is in the design (the BD-204 phantom-fork failure mode is avoided).

### 2.2 Shard count — 4, derived from the measured knee

The hard floor of any sharded design is the single longest test: `migrate-gates` = 94 s in CI (79 s local, RE-CONFIRMED §EE-4). A shard cannot finish faster than its longest member + ~7 s setup. With Σ ≈ 462 s:

| Shards | Theoretical max-shard (measured-balanced) | Verdict |
|---|---|---|
| 2 | ~max(balanced-half) ≈ 240–260 s | weak |
| **4** | **~140–160 s** (floored by 94 s + co-located neighbors + setup) | **the knee — chosen** |
| 6–8 | ~94–110 s but only ~30–50 s better than 4, at rising aggregate setup + plan-job overhead and more required-check surface | diminishing returns |

**Decision: 4 shards.** Rationale: 4 puts the slowest shard close to the 94 s irreducible floor while keeping aggregate setup small and the matrix legible. Going past 4 buys little because no shard can beat the 94 s test. (If a future BD shrinks `migrate-gates` per research candidate E, the shard count can be revisited — the dynamic partition adapts automatically; only the count knob would change.)

### 2.3 Partition strategy — measured-balance, GENERATED (not name-hash, not hand-map)

**Reject name-hash:** a script-name hash would scatter the 94/61/52/34/31/29 s heavyweights into unpredictable shards — two heavies can collide (94+61 = 155 s) and blow the balance. The research measured per-step durations precisely so we can bin-pack.

**Design — single-source generated partition:**

1. **`scripts/ci-shard-weights.tsv`** (committed) — one row per wired test script: `<script-path>\t<measured_seconds>`. Seconds come from the CI per-step durations (research §1.2) and/or `gh run view --json jobs`. This is the ONLY hand-touched balance input, and it is data, not logic. A missing or unknown script gets a default weight (see §2.6 drift handling) so balance degrades gracefully, never breaks.
2. **`scripts/lib/ci-shard-plan.py`** (committed, single source of the partition) — reads the wired-test list (parsed from `.github/workflows/validate-pack.yml`, the SAME parse Check 42 uses) and the weights TSV, runs LPT bin-packing (longest-processing-time-first greedy: sort descending, assign each to the currently-lightest shard) into N shards, and emits the shard→scripts mapping. Two output modes:
   - `--emit-matrix` → prints the GitHub Actions matrix JSON (`{"include":[{"shard":1,"scripts":"a.sh b.sh ..."},...]}`) for the `plan` job's `$GITHUB_OUTPUT`.
   - `--assert-coverage` → exits non-zero unless `union(shards) == wired_set` and shards are pairwise-disjoint (used by both the aggregation job and the validate-pack guard — single source of the coverage truth).

LPT bin-packing on a set with one dominant item (94 s) yields a max-shard of `max(longest_item, ceil(total/N))` ≈ `max(94, 462/4=116)` plus neighbors and setup ≈ ~140–160 s — matching §2.2.

### 2.4 The workflow shape (dynamic matrix + aggregation)

```yaml
jobs:
  validate:        # UNCHANGED — runs ALL checks, general + deep. Not sharded.
    ...

  plan:            # NEW — tiny; emits the shard partition
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.plan.outputs.matrix }}
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-python@v6
        with: { python-version: '3.12' }
      - id: plan
        run: echo "matrix=$(python3 scripts/lib/ci-shard-plan.py --emit-matrix)" >> "$GITHUB_OUTPUT"

  tests:           # MATRIX — was the monolithic sequential job
    needs: [plan]
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false                 # HARD REQUIREMENT — preserve "surface all failures"
      matrix: ${{ fromJSON(needs.plan.outputs.matrix) }}
    steps:
      - uses: actions/checkout@v6
        with: { fetch-depth: 0 }
      - uses: actions/setup-python@v6
        with: { python-version: '3.12' }
      - run: pip install pyyaml
      # fixture build runs ONLY in the shard that owns fixture-dependent tests (§2.5)
      - name: build test fixtures (only if this shard needs them)
        if: always()
        run: |
          if scripts/lib/ci-shard-plan.py --shard ${{ matrix.shard }} --needs-fixtures; then
            bash test-fixtures/build.sh --all --clean
            git checkout HEAD -- test-fixtures/manifest.txt   # BD-118 retro invariant
          fi
      - name: run shard ${{ matrix.shard }}
        if: always()
        run: |
          rc=0
          for t in ${{ matrix.scripts }}; do
            echo "::group::$t"; bash "$t" || rc=1; echo "::endgroup::"
          done
          exit $rc

  tests-result:    # NEW — the SINGLE branch-protection required check
    needs: [plan, tests]
    if: always()
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-python@v6
        with: { python-version: '3.12' }
      # GOTCHA GUARD: a needs: job is SKIPPED (not failed) if a needed matrix job fails.
      # A skipped required check can let a PR through. Assert success EXPLICITLY.
      - name: assert all shards succeeded
        run: |
          echo "tests result = ${{ needs.tests.result }}"
          test "${{ needs.tests.result }}" = "success"
      # run-time coverage re-assertion (defense in depth; see §6.3 O2)
      - name: assert shard partition covers the wired set exactly
        run: python3 scripts/lib/ci-shard-plan.py --assert-coverage
```

**Per-script `if: always()` preserved within the shard:** today every step is `if: always()` so one failure does not mask another's results. Under sharding I preserve this in TWO layers: `fail-fast: false` keeps sibling SHARDS running; the per-script loop uses `|| rc=1` (not `set -e` abort) so every script in a shard runs even if an earlier one fails, then the shard exits non-zero. The `::group::` markers keep per-script logs legible. Net: a single CI run still surfaces ALL failures, exactly as today.

### 2.5 Fixture-build correctness (BD-163/BD-118 invariants preserved)

Fixtures (`test-fixtures/<name>/`) are gitignored build artifacts; each shard is a fresh runner. The fixture-dependent tests (research §2.5: `migrator-skills`, `persona contracts`, `fixture manifest verify`, `v11-realistic-ot`, plus the `build.sh --verify` step) MUST run after `build.sh --all --clean` IN THE SAME RUNNER, and the BD-118 manifest-restore (`git checkout HEAD -- test-fixtures/manifest.txt`) must run between build and verify.

**Design constraint passed to `ci-shard-plan.py`:** the fixture-dependent test set is a COHESION GROUP — the partitioner pins all fixture-dependent tests (a small, named set the module knows) into a single shard, and only that shard runs the build + manifest-restore + verify sequence in the BD-163 order. The `--needs-fixtures` flag (per shard) lets the workflow conditionally run the build only where needed. This preserves the ordering invariant AND avoids paying the ~6 s build in shards that do not need it (research §6 C). The cohesion group is a measured input, not a guess — the module asserts the build/restore/verify triple stays co-located.

### 2.6 The required-check RENAME hazard (the BD called this out)

Turning `tests` into a matrix REPLACES the single `tests` status check with per-shard checks `tests (1) … tests (4)` — a check literally named `tests` ceases to exist. A branch-protection rule requiring `tests` would then NEVER be satisfied and would BLOCK all merges (a silently-broken gate in the FAIL-CLOSED direction — bad, but visible). The dangerous direction (silent-PASS) is avoided by the `tests-result` aggregator's explicit `needs.tests.result == 'success'` assertion.

**Required branch-protection change (must be coordinated with the workflow commit — repo-admin action, NOT a code change):**

1. BEFORE merging C2: confirm whether a branch-protection rule on `main` currently requires the check named `tests` (and/or `validate`). The workflow header (yml lines 75–78) documents this as a one-time admin action; the live rule must be inspected by the repo admin (a branch-protection read is an admin surface this RO design does not mutate).
2. The design's stable required-check name is **`tests-result`** (the aggregator) — NOT `tests`. The admin must, in the same change window as C2's merge: ADD `tests-result` to the required set and REMOVE `tests` (the now-nonexistent monolithic check). `validate` is unchanged and stays required.
3. **Why the aggregator and not "require each shard":** requiring `tests (1)…tests (4)` couples branch protection to the shard COUNT — every count change forces a manual required-list edit (drift). `tests-result` is count-stable: one required check regardless of shard count. This is the GA-recommended pattern.

**How the design avoids a silently-passing gate (the explicit anti-footgun):**
- The aggregator runs `if: always()` so it executes even when a shard fails (otherwise a `needs:` job is SKIPPED on upstream failure, and a skipped required check can be treated as non-blocking).
- It then asserts `needs.tests.result == 'success'` and FAILS (exit 1) otherwise — converting "a shard failed → aggregator skipped" into "a shard failed → aggregator FAILED." A skipped check cannot masquerade as success.
- `fail-fast: false` ensures every shard reports its own result, so `needs.tests.result` reflects the true aggregate (it is `'success'` only if ALL combinations succeeded).
- The second aggregator step (`--assert-coverage`) makes "a wired test silently in no shard" a HARD CI failure at run time, in addition to the validate-pack-time guard (§6.3).

### 2.7 GitHub Actions limits relied on (cited, all SUPPORTED)

- Matrix ≤ 256 jobs/run — 4 shards is ~1.6 % of the cap (research §2.2 rule 1).
- Concurrent-job floor Free=20 ≫ 4 shards + plan + aggregator (research §2.2 rule 2).
- `needs:` waits for all matrix combinations (research §2.2 rule 8) — the aggregator gates correctly.
- Do NOT path/branch-filter this required workflow (research §2.2 rule 7) — the design adds no path filter; `on: push` is unchanged.


---

## 3. `--only-check` (Lever 2) — VALIDATE then RECOMMENDATION

### 3.1 Re-validated saving (I did not assume drop)

| Quantity | BD / research claim | My re-measurement (§EE-5/§EE-6/§EE-7) | Verdict |
|---|---|---|---|
| Full-validator subprocess spawns across wired battery | BD: "238 invocations" | **24** (`grep` of `python3 … validate-pack.py` command lines, wired scripts) | BD figure is a ~10× over-estimate; CORRECTED |
| Per-check e2e leg cost | ~1.2 s | **1.29 / 1.52 / 1.59 s** (checks 52 / 43 / 40, measured) | CONFIRMED ~1.2–1.6 s, dominated by the one full run |
| General validate-pack run | ~1.2 s | **1.26–1.39 s** | CONFIRMED |
| Realistic total saving | research ~25–30 s | **~22–26 s** (≈24 spawns × ~0.9–1.1 s each saved) | CONFIRMED ~6 % of the tests job standalone |
| argparse refactor surface | greenfield | **0** existing argparse callsites (`grep -c` → 0); flat `run_check` sequence in `main()` | CONFIRMED greenfield — low maintenance surface |

The saving is REAL and the maintenance surface is small: ONE greenfield argparse block in `validate-pack.py` (a file already covered by Check 42's test-wiring and its own per-check tests), plus a mechanical edit to ~24 per-check e2e legs to add the flag. No existing arg handling to refactor.

### 3.2 RECOMMENDATION: KEEP

Per the user's explicit constraint ("a confirmed ~6 % / ~25–30 s saving IS worth keeping if the maintenance surface is reasonable"), and because (a) the saving is confirmed at ~22–26 s, (b) the maintenance surface is one argparse block + mechanical e2e-leg edits, and (c) it is the legitimate cure for the `ci-check-runtime-compounding` pattern at the battery level (the redundant full-tree re-scan per per-check test), **KEEP `--only-check`.** Note its marginal wall-time contribution shrinks UNDER sharding (the validate-pack steps already overlap the long poles), so it is correctly framed as a secondary, standalone cleanup — not co-equal with sharding.

### 3.3 The flag contract (exact)

1. **Selector key = numeric check number AND/OR the `run_check` label.** `--only-check 52` (numeric) and `--only-check check_pack_rw_ro_two_class` (the `run_check` label string) both select. Rationale: the per-check tests already key on BOTH the numeric "Check NN" banner and the function; supporting both avoids a renumbering footgun. The selector resolves against the SAME registry that `main()` builds (§6.4) so a renamed/renumbered check cannot silently select the wrong one — an unmatched selector is a LOUD non-zero error naming the unknown key, never a silent no-op (a silent no-op would turn a per-check test into a tautology = effectiveness loss).
2. **No flag = ALL checks (hard constraint).** argparse defaults `--only-check` to `None`; `main()` runs the full `run_check` sequence when `None`. The `validate` job passes NO flag (general + deep) and is UNCHANGED — the full 57-check coverage is structurally untouched (§EE-8). A new guard (§6.3 O4) asserts the workflow's full-run invocations carry no `--only-check`.
3. **`main()` refactor shape (preserves the `__main__` + module-import path):** extract the flat `run_check(...)` sequence into a `CHECK_REGISTRY` (ordered list of `(number, label, callable)` — built once, see §6.4). `main()` parses args; when `--only-check K` is given, it runs ONLY the matching registry entry through `run_check` (preserving the per-check WARN timing). The `importlib.spec_from_file_location` path the per-check tests use imports the module WITHOUT running `main()` (the `if __name__ == "__main__"` guard at line 9621 is preserved) — so the unit-assertion leg is untouched.
4. **Runtime-guard interaction (preserve all six — §EE-9):**
   - Per-check WARN budget (`run_check`, 2.0 s): STAYS ACTIVE under `--only-check` (the one selected check is still timed).
   - Total-run budget (10 s general / 35 s deep, summed over ALL checks): SUPPRESSED under `--only-check` — the sum of one check is not the real surface, so failing on it would be meaningless. The no-flag `validate` job keeps the total-run budget LIVE over the full set. Design: `main()` skips the `total_elapsed > total_budget` FAIL block when `--only-check` is set (and prints a one-line notice that the total-run budget is N/A in single-check mode).
   - Deep ENV-gate (`PACK_VALIDATE_DEEP=1`) and the deep faithfulness per-check budget: UNCHANGED — orthogonal to `--only-check`.
5. **Exit-code contract:** `--only-check K` exits non-zero IFF the selected check appended to `failures` (i.e. the check FAILed). This preserves the per-check test's `if python3 … --only-check NN ; then PASS` logic. An unknown `K` exits non-zero with a named error.

### 3.4 Per-check test adoption WITHOUT weakening assertions

The e2e leg today (e.g. test-52 lines 213–229) asserts three things: exit-0, the "Check 52: …" banner present, the "Check 52 — … holds" clean-verdict present. Adopting `--only-check 52`:
- The subprocess becomes `python3 …/validate-pack.py --only-check 52` (runs ONLY Check 52).
- All THREE assertions are PRESERVED verbatim (the banner + verdict are printed by Check 52's own `print`/`ok`; the exit code is non-zero iff Check 52 fails). The flag NARROWS which checks run in that subprocess; it does not change WHETHER Check 52's assertion fires. Mutation-proof requirement (BD acceptance) is satisfied: mutate Check 52's body → `--only-check 52` exit flips → the test FAILs.
- **The one assertion the e2e leg SILENTLY carried — "Check 52 is wired into `main()`'s full run" — is NOT preserved by `--only-check` alone** (selecting a check proves it is in the registry, not that the full run includes it). This is a real effectiveness consideration, handled in §6.4: a small `main()`-wiring/registry invariant guarantees the full run executes every registry check, so wiring proof MOVES from an implicit side-effect of the e2e leg to an explicit guard — net effectiveness UNCHANGED (stronger, in fact: it becomes an asserted invariant rather than an implicit one).


---

## 4. UPKEEP / ANTI-DRIFT GUARD (core scope — measure-then-bound)

### 4.1 The two drift axes

1. **Wiring drift (pre-existing, only partially guarded):** a test script on disk wired into no CI step. MEASURED: 9 unwired scripts today (§EE-3). Check 42 covers only `test-validate-pack-check*.sh`, so 8 of the 9 are invisible to ANY guard.
2. **Shard-coverage drift (NEW with sharding):** a wired test that lands in no shard, or in two. Did not exist under the single sequential list; sharding creates it.

### 4.2 MEASURE (the complete current test-script set)

`scripts/test*.sh` + `scripts/tests/*.sh` = **70** on disk; **61** wired in the workflow; **9** unwired; reverse-drift (wired-but-absent) = **0** (§EE-3, RE-CONFIRMED). The 9 unwired:

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

### 4.3 CATEGORIZE every unwired script KEEP-in-CI vs intentionally-OUT

This is the measure-then-bound categorization. I provide a PRELIMINARY classification by reading each script's purpose; the planner/coder MUST confirm each by opening the script header before sizing the allowlist (the architect names the axis and the evidence required; the coder verifies the final KEEP/STRIP per file — this is the measure step's completion). Classification axis: a script is **STRIP (intentionally-OUT → allowlist with reason)** only if it (a) touches a LIVE network/GH surface (cannot run offline in CI), or (b) is a manual-only dev utility with no offline-deterministic mode. Everything else is **KEEP (must be wired + sharded)**.

| Script | Preliminary class | Reason / evidence to confirm |
|---|---|---|
| `test-tracker-promote-direct.sh` | **STRIP** (live-GH) | promote-path tests touch live GH (research §1.3 flags them live-GH). Confirm: header / `gh` calls without offline stub. Allowlist with reason "live-GH; manual-only." |
| `test-tracker-promote-path1.sh` | **STRIP** (live-GH) | same family. |
| `test-tracker-promote-path2.sh` | **STRIP** (live-GH) | same family. |
| `tracker-bd204-lossless-roundtrip-test.sh` | **CONFIRM** (likely KEEP) | research flagged "possibly manual." If it runs offline (gh-stub) → KEEP+wire+shard; if it requires live round-trip → STRIP. Coder opens header to decide. |
| `test-activate-capability.sh` | **CONFIRM** (likely KEEP) | capability tests are offline by nature; if offline-deterministic → KEEP+wire. |
| `test-add-capability.sh` | **CONFIRM** (likely KEEP) | same. |
| `test-compare-agent-trinity.sh` | **CONFIRM** (likely KEEP) | trinity comparison is offline (reads repo files) → likely KEEP+wire. |
| `test-dry-run-migration.sh` | **CONFIRM** (likely KEEP) | migration dry-run is offline → likely KEEP+wire. |
| `test-restore-from-backup.sh` | **CONFIRM** (likely KEEP) | backup-restore on scratch dirs is offline → likely KEEP+wire. |

**Bound the allowlist to EXACTLY the confirmed STRIP set — no broader.** Per `ci-guard-design-measure-then-bound`, the guard's allowlist (`scripts/ci-test-wiring-allowlist.txt`, committed) lists ONLY the scripts confirmed intentionally-OUT, each with a one-line reason. A guard that allowlists all 9 to go green would treat drift as legitimate — FORBIDDEN. The KEEP scripts get WIRED (new workflow steps) and JOIN the shard partition; this is part of the BD's "core scope" (closing the upkeep gap), and surfacing/wiring those KEEP tests is itself a coverage INCREASE the BD enables (not a coverage decrease — fully compatible with the HARD constraint, which forbids removing/weakening, not adding).

> **SURFACED, not silently absorbed (scope-deliverables-to-the-ask):** wiring the ~5–6 currently-unwired KEEP tests ADDS test execution that was previously dormant. This is in-scope for BD-219's wiring-completeness criterion, but it changes the green/red surface (a dormant test that has bit-rotted could now fail). The planner must sequence "confirm each KEEP runs green offline" BEFORE wiring it, and surface any KEEP test that fails on first wiring to Pack Chat/user as a separate finding rather than force-fixing it inside BD-219.

### 4.4 Runtime-cost of the new guards (ci-check-runtime-compounding — preserve, don't reintroduce)

Every new validate-pack check below is a glob + regex over `.github/workflows/validate-pack.yml` + a directory listing + reading two small committed files (allowlist, weights) — microseconds–milliseconds, NO subprocess-per-script, scoped to the repo's own workflow/tests (not a hardcoded real-tree scan). Each routes through `run_check` so the 2.0 s per-check WARN budget catches any regression, and the 10 s total-run budget still bounds the general path. The run-time `--assert-coverage` re-check lives in the AGGREGATION JOB (once per CI run), not on the ~24-spawn battery path. No whole-real-tree scan, no per-entry subprocess storm is introduced. The six existing guards (§EE-9) are preserved verbatim.


---

## 5/6. GUARD ARCHITECTURE (the invariants + their homes)

> Cross-ref note: §3 and §4 above point to "§6.3 O1–O4" and "§6.4"; those are this section's subsections 6.1–6.4 (kept O-numbered to match the research's option labels).

### 6.1 Single source of the partition (`scripts/lib/ci-shard-plan.py`)

The partition module (§2.3) is the SINGLE SOURCE for: the shard→scripts mapping (`--emit-matrix`), the coverage assertion (`--assert-coverage`), and the per-shard fixture-need flag (`--shard N --needs-fixtures`). Because the shard partition is GENERATED from the wired-test list, shard-coverage drift is correct-by-construction (a wired test is always assigned to exactly one shard by the bin-packer; a non-wired test is never assigned). Lives in `scripts/lib/` (pack-side test infra; not a client deliverable; not a runtime dependency of any pack OPERATION — it is invoked only by CI and by validate-pack's guard, so dependency-direction is satisfied).

### 6.2 O1 — generalized wiring-completeness check (replaces Check 42's scope)

Today Check 42 (`check_ci_workflow_wires_per_check_tests`) does set-equality over ONLY `test-validate-pack-check*.sh`. GENERALIZE it to the full CI-eligible test set:

- **Invariant:** `disk_KEEP_set == wired_set`, where `disk_KEEP_set = {all scripts/test*.sh + scripts/tests/*.sh} − allowlist` and `allowlist = scripts/ci-test-wiring-allowlist.txt` (the §4.3 measured STRIP set). FAIL names each un-wired KEEP script (with the existing remediation message) and each allowlisted-but-now-wired script (allowlist staleness).
- **Home:** `scripts/validate-pack.py`, extending Check 42 (it already owns the disk↔workflow diff). Keep the per-check sub-assertion as a special case OR fold it into the general set-equality — the planner picks the lower-churn shape; either preserves Check 42's existing test assertions (enumerate-encoding-surfaces: update `test-validate-pack-check-42.sh` in lock-step).
- **Bounded:** allowlist sized to exactly the confirmed STRIP set (§4.3); no broader.
- **Cheap:** glob + regex over the workflow + a dir listing (§4.4).

### 6.3 O2 — shard-coverage invariant (correct-by-construction + re-asserted)

- **Invariant:** `union(shards) == wired_KEEP_set` AND shards pairwise-disjoint.
- **Home — TWO layers:** (a) BUILD time: `ci-shard-plan.py` generates the partition from the wired list, so coverage holds by construction; (b) RUN time: the `tests-result` aggregation job runs `ci-shard-plan.py --assert-coverage` (defense in depth — catches a hand-edit to the workflow or a corrupt weights file). Optionally a thin validate-pack check (O2-static) that calls `--assert-coverage` so local `validate-pack` also surfaces it; the planner decides whether the run-time aggregator assertion suffices (it does for CI; the validate-pack mirror is a convenience). Recommendation: include the validate-pack mirror so a developer running `validate-pack` locally sees coverage drift without pushing.

### 6.4 O4 — full-run + registry-wiring invariant (protects Lever 2's "no check silently dropped")

Two coupled assertions, both in `validate-pack.py`:

- **Full-job-no-flag invariant:** a check that parses `.github/workflows/validate-pack.yml` and asserts the `validate` job's `python3 scripts/validate-pack.py` invocations carry NO `--only-check` (so the authoritative run can never be silently narrowed). Cheap regex over the workflow.
- **Registry-completeness invariant (the moved wiring proof from §3.4):** with the `CHECK_REGISTRY` refactor (§3.3 item 3), `main()`'s full run executes EVERY registry entry, and `--only-check` selects FROM the registry. A check asserts `len(CHECK_REGISTRY) == <expected_count>` (today 57 — §EE-8) and that every registry entry is reachable by the full run. This is the explicit replacement for the implicit "the e2e leg proves the check is wired into main()" property that `--only-check` would otherwise drop — making net effectiveness UNCHANGED (an asserted invariant rather than a side-effect). The expected-count constant is updated in lock-step whenever a check is added (a one-line bookkeeping edit, like the existing agent-count check).

### 6.5 Ownership of shard rebalancing

The partition self-balances by the committed `ci-shard-weights.tsv`. As durations drift, balance degrades gracefully (the bin-packer still produces a valid partition; the slowest shard just creeps). To keep balance honest WITHOUT coupling correctness to freshness:

- **Soft WARN, not hard FAIL:** the aggregation job emits a WARN (job summary annotation) when the slowest shard exceeds, say, 1.5× the median shard — a signal that weights need a refresh, never a merge blocker. (A hard FAIL on imbalance would make CI red over a non-correctness condition.)
- **Refresh trigger:** a documented periodic re-measure (`gh run view --json jobs` → update `ci-shard-weights.tsv`), owned by pack maintenance. A new test gets a default weight (median) until measured, so balance is never broken by an un-weighted addition. This default-weight rule is the graceful-degradation guarantee: adding a test can never break the partition, only mildly unbalance it until the next weight refresh.

### 6.6 What is preserved verbatim (no regression)

- The `validate` job (general + deep, both no-flag) — UNCHANGED; runs all 57 checks (§EE-8).
- The `PACK_VALIDATE_DEEP=1` ENV-gate and all six runtime guards (§EE-9).
- The BD-163 fixture step-ordering invariant and the BD-118 manifest-restore (§2.5), now within the fixture-owning shard.
- Every test script's own assertions (sharding only changes WHERE a script runs; `--only-check` only narrows WHICH checks a per-check test's subprocess runs, preserving its three assertions — §3.4).


---

## 7. PROJECT-SIDE ANALYSIS (user-directed; boundary-compliant)

### 7.1 (a) What CI / test infrastructure does the pack actually ship to clients?

Investigated `project-template/` (P-missed-7 / boundary-investigation — investigate the project-side SSOT before reaching for a pack default):

- **NO client CI workflow.** `find project-template -name '*.yml'` under `.github` yields ONLY `ISSUE_TEMPLATE/{work-item,inbound,config}.yml` (§EE-2 project-side). There is no `project-template/.github/workflows/` directory at all — the pack ships clients GitHub Issue forms, not a CI workflow.
- **NO client multi-script meta-battery.** The client-shipped test scripts are `project-template/scripts/{test,test-swift,test-python}.sh` — `test.sh` is a language-detecting wrapper that calls `swift test` / `pytest` (the project's OWN suite). It does NOT loop over a set of independent `*-test.sh` files the way the pack's `tests` job does. There is no shardable battery and no client `validate-pack`-equivalent.
- **`validate-pack.py` is pack-only** — never installed to clients (it validates the PACK's structure). So `--only-check` has no client-side consumer.

### 7.2 (b) Is any optimization or ship-ready pattern worth shipping NOW? — RECOMMEND: NO (mechanism); YES (one short doc note)

- **Mechanism: do NOT ship.** Matrix-sharding optimizes the PACK's pack-specific test battery; the client has no equivalent battery and the pack does not control client CI. Shipping a sharding workflow or `--only-check` to the project side would be (i) wasted effort (no target surface), and (ii) a boundary risk (`validate-pack.py` is pack-only; a client sharding workflow would presuppose a battery the client may not have). Evidence: §7.1 — no client workflow, no client battery, no client validate-pack.
- **The general PATTERN is worth a short note.** GitHub Actions `strategy: matrix` is a generic, project-native technique. A client whose own CI runs a multi-suite test battery sequentially could benefit. So the deliverable is DOCUMENTATION of the technique (project-native), NOT the pack's specific machinery.

### 7.3 (c) Project-native, boundary-compliant documentation design

**Where it lives:** a new short entry in `project-template/docs/pack/OPTIONAL-FEATURES.md` — the established project-side SSOT for opt-in capabilities (it already has an "Adding new entries" convention and a section shape: Status / What it is / When it matters / How to enable / Caveats / When to skip). This is the project analog of the pack-side OPTIONAL-FEATURES surface; it is PM-facing and shipped to clients, so PM chats reading it can proactively inform their users. (It is part of the project SSOT per project-trinity § "Project SSOT-first".)

**What it says (project-native vocabulary ONLY — boundary-compliant):**
- Title: a "CI test parallelization (GitHub Actions matrix)" entry.
- Content: if your project's CI runs many independent test suites sequentially in one job and wall-time is a pain, GitHub Actions `strategy: matrix` (with `fail-fast: false` to surface all failures, and an aggregation job as the single required status check) parallelizes them across runners with no loss of coverage — every suite still runs. Note the required-status-check rename consideration (a matrix renames the job's check; require an aggregation job). When to skip: if your CI is already fast or single-suite.
- **Boundary discipline (NO pack-self leak — bd-pack-only-operational-rule, pack-project-separation-of-concerns):** the entry mentions NO BD-NNN, NO `validate-pack.py`, NO pack-* agents, NO `pack-ops/`, NO `maintenance-docs/`, NO reference to the pack's own `tests` job. It speaks only in client-project terms ("your CI", "your test suites"). It is GENERAL technique guidance, not a description of the pack's internal optimization. The necessity test (token economy): a client reader benefits from the technique without ANY pack-internal reference, so all such references are removed by construction.

**This is a SEPARATE `project-only` commit (C4)**, distinct from the pack-only commits — per the user's directive and the separate-pack-ops-from-pack-product rule. Trinity note: OPTIONAL-FEATURES.md is a single project-side doc (not a trinity CLAUDE/AGENTS/GEMINI file), so no trinity parallel-edit is triggered.

---

## 8. COMMIT DECOMPOSITION (for the planner to expand)

Four single-surface commits, each with the correct Check-36 scope keyword. C1/C2/C3 are pack-only; C4 is project-only. Ordering: C1 → C3 → C2 → C4 is the recommended SEQUENCE (the guards in C3 should land before/with the workflow restructure in C2 so the workflow change is born guarded; but C2's dynamic matrix needs `ci-shard-plan.py` which C3 introduces — so C3 BEFORE C2). Alternatively C2+C3 can be one commit if the planner prefers a born-guarded workflow; kept separate here for review granularity and worktree-isolation partitionability.

| Commit | Scope keyword | Surface / files | Contents |
|---|---|---|---|
| **C1** | `pack-only` | `scripts/validate-pack.py` (+ its per-check test legs, `scripts/tests/test-validate-pack-check*.sh`) + `test-fixtures/manifest.txt` if v11-surface diff non-empty | Add `--only-check` argparse + `CHECK_REGISTRY` refactor (§3.3); suppress total-run budget under the flag (§3.3 item 4); adopt `--only-check NN` in the ~24 per-check e2e legs WITHOUT weakening assertions (§3.4); **strip the 3 stale "Check 54 reserved" comments** at validate-pack.py lines 9549 / 9572 / 9587 (BD anchor; cosmetic). |
| **C3** | `pack-only` | `scripts/validate-pack.py` (generalized Check 42 + O2-mirror + O4 checks), `scripts/lib/ci-shard-plan.py` (new), `scripts/ci-shard-weights.tsv` (new), `scripts/ci-test-wiring-allowlist.txt` (new), the new/updated guard tests under `scripts/tests/`, + manifest | The wiring-completeness generalization (§6.2), shard-coverage assertion module + its validate-pack mirror (§6.3), full-run/registry invariant (§6.4); confirm + WIRE the KEEP unwired tests (§4.3) as new workflow steps (this touches the yml — see note below); allowlist the confirmed STRIP set sized exactly. Enumerate-encoding-surfaces: update Check 42's test in lock-step. |
| **C2** | `pack-only` | `.github/workflows/validate-pack.yml` + manifest | The `plan` job, the matrix `tests` job (`fail-fast: false`, dynamic `fromJSON` matrix), the `tests-result` aggregation job with the `if: always()` + `result == 'success'` + `--assert-coverage` steps (§2.4); fixture-owning-shard build/restore/verify (§2.5). **Paired repo-admin action (NOT in the commit): branch-protection required-check change `tests` → `tests-result` (§2.6).** |
| **C4** | `project-only` | `project-template/docs/pack/OPTIONAL-FEATURES.md` | The project-native "CI test parallelization" entry (§7.3). No pack-self leak. |

**Note on yml ownership across C2/C3:** wiring the KEEP unwired tests (C3) and restructuring the workflow into shards (C2) both touch `.github/workflows/validate-pack.yml`. To keep each commit single-purpose and avoid a mid-sequence broken workflow, the planner should either (i) wire the KEEP tests as plain sequential steps in C3, then let C2's dynamic partition pick them up automatically (the partition reads the wired list — so newly-wired tests flow into shards with no extra edit), or (ii) merge C2+C3 into one "shard infra + guards + wiring" pack-only commit. Option (i) is cleaner for review and is RECOMMENDED; it also means C3's generalized wiring guard is green before C2 reshapes the job. The `regenerate-manifest-v11-surface` rule applies to every commit touching `scripts/`, `.github` is not a v11-surface dir but `scripts/` is — C1/C3 regenerate the manifest if their diff is non-empty under the four v11-surface dirs; C2 (yml-only) does not unless a `scripts/` file also changes.

**Worktree-isolation partitionability (coder phase — mechanics not my concern):** C1 (validate-pack `--only-check` + e2e legs + comment strip) and C3 (new shard-plan module + new guards + new files) touch overlapping regions of `validate-pack.py` (both edit `main()` / add checks), so they are NOT safely parallel against the same file — sequence them. C2 (yml-only) and C4 (project-only doc) touch disjoint files from each other and from C1/C3's non-validate-pack files, so C2 and C4 are safely partitionable for parallel RW work. The cleanest parallel split: {C1+C3 sequential on validate-pack.py} ‖ {C4 on OPTIONAL-FEATURES.md}; C2 lands after C3.


---

## EMPIRICAL-EVIDENCE BLOCKS

All measurements at HEAD `1f95b8eedd9fa21b7c9a824736648599c543bb2d`, branch `v11-dev`, 2026-06-14.

### §EE-1 — The `tests` job is the long pole; `validate` runs in parallel and is ~15 s
- **Claim:** wall-time = the `tests` job (~441–464 s); `validate` ~12–15 s, parallel, not the long pole.
- **Command + output:** RE-USED the research's `gh run view` per-job timings (§1.1: run 27512425188 = validate 15 s / tests 464 s; 3 more runs 441–463 s tests vs 12–15 s validate). Independently confirmed the PARALLELISM from the workflow source: `validate` and `tests` are sibling jobs with no `needs:` between them (`.github/workflows/validate-pack.yml` lines 84–116 — `validate:` and `tests:` both top-level under `jobs:`, neither lists the other in `needs:`). Local validator timing: `python3 scripts/validate-pack.py` → `real 1.26–1.39`; deep → `real 2.51` (matches research 1.20–1.23 / 2.48).
- **Interpretation:** the CI validate-job 12–15 s is setup-dominated; the validator itself is ~1.3 s. Sharding the tests job is the only wall-time lever.
- **Conclusion: SUPPORTED.**

### §EE-2 — No client CI workflow shipped; only Issue forms under project-template/.github
- **Claim:** the pack ships clients NO CI workflow; `.github` ships only Issue forms.
- **Command + output:** `find project-template/.github -type f` → `project-template/.github/ISSUE_TEMPLATE/work-item.yml`, `…/inbound.yml`, `…/config.yml` (3 files; no `workflows/` dir). `find project-template -name '*.yml' -o -name '*.yaml' | xargs grep -l 'jobs:\|runs-on:\|on: push'` → empty.
- **Interpretation:** there is no client-side CI workflow to optimize.
- **Conclusion: SUPPORTED.**

### §EE-3 — Test-script inventory: 70 disk / 61 wired / 9 unwired / 0 reverse-drift
- **Claim:** 70 on disk, 61 wired, 9 unwired (named), 0 wired-but-absent.
- **Command + output:** `ls scripts/test*.sh scripts/tests/*.sh | wc -l` → 70. `grep -E '^\s+run: bash ' .github/workflows/validate-pack.yml | awk '{print $3}' | grep -v build.sh | sort -u | wc -l` → 61. `comm -23` (disk − wired) → the 9 scripts listed in §4.2. `comm -13` (wired − disk) → EMPTY.
- **Interpretation:** drift is one-directional (scripts exist but aren't run); Check 42 sees only the per-check subset, so 8 of the 9 are unguarded.
- **Conclusion: SUPPORTED.**

### §EE-4 — Long-pole tests are non-validator; ordering confirmed locally
- **Claim:** the slowest steps (migrate-gates 94 s, tracker-migrate-forward 61 s, roundtrip 52 s) call validate-pack ZERO times.
- **Command + output:** local timing — `test-migrate-v10-to-v11-gates.sh` → `real 79.15`; `tracker-migrate-forward-test.sh` → `real 58.87` (CI 94 / 61 per research; local tracks). Zero-validate-pack-calls: `grep -cE 'validate-pack\.py' scripts/tests/test-migrate-v10-to-v11-gates.sh scripts/tests/tracker-migrate-forward-test.sh` per-script → 0 command spawns (these are migration/gh-stub heavy).
- **Interpretation:** `--only-check` cannot help the long poles; only sharding parallelizes them. The 94 s gates test is the irreducible shard floor.
- **Conclusion: SUPPORTED.**

### §EE-5 — Full-validator subprocess spawns ≈ 24, NOT 238
- **Claim:** ~24 full-validator subprocess spawns across the wired battery; the BD's "238" is a ~10× over-estimate.
- **Command + output:** `grep -rE 'validate-pack\.py' scripts/tests/*.sh scripts/test*.sh | wc -l` → 260 (textual). Actual command spawns: `grep -rhE 'python3[^|]*validate-pack\.py' … | grep -vE '^\s*#' | wc -l` → 24. Broader count incl. `$VALIDATE` var deref, excl. importlib/comment/`VALIDATE=` → 24. Per-check test files: `ls scripts/tests/test-validate-pack-check*.sh | wc -l` → 23.
- **Interpretation:** the cost driver is ~24 spawns, not 238 invocations; the BD's "1/56th of 238" rationale overstates the lever-2 gain ~10×.
- **Conclusion: SUPPORTED (BD figure CORRECTED).**

### §EE-6 — Per-check e2e leg ≈ 1.2–1.6 s, dominated by the one full run
- **Claim:** each per-check test's e2e leg is ~1.2 s; `--only-check` saves ~0.8–1.1 s each.
- **Command + output:** `bash scripts/tests/test-validate-pack-check-52.sh` → `real 1.29`; `-43` → `real 1.52`; `-40` → `real 1.59`. The general validator alone = ~1.26–1.39 s, so the e2e leg ≈ the whole script time; module-import unit assertions are sub-second.
- **Interpretation:** saving per test ≈ general-run-cost minus single-check-cost ≈ ~0.9–1.1 s; × ~24 ≈ ~22–26 s total.
- **Conclusion: SUPPORTED.**

### §EE-7 — `validate-pack.py` has NO argparse (greenfield); `__main__` guard + module-import path intact
- **Claim:** `--only-check` is greenfield; the importlib path the per-check tests use is preserved by the `__main__` guard.
- **Command + output:** `grep -cE 'import argparse|add_argument|ArgumentParser' scripts/validate-pack.py` → 0. `grep -n 'if __name__' scripts/validate-pack.py` → `9621:if __name__ == "__main__":`. `grep -n 'def main' …` → `9338`. The per-check test imports via `spec_from_file_location('vp', …)` (test-52 lines 49–51) — importing does NOT run `main()` because of the line-9621 guard.
- **Interpretation:** adding argparse inside `main()` / the `__main__` block does not break the import-based unit-assertion legs; the refactor surface is one block.
- **Conclusion: SUPPORTED.**

### §EE-8 — The full run executes 57 checks; the validate job passes no selector
- **Claim:** the full `validate` job runs all checks (no flag = all); 57 `run_check` callsites.
- **Command + output:** `awk '/^def main/,/^if __name__/' scripts/validate-pack.py | grep -cE 'run_check\('` → 57. `grep -nE 'python3 scripts/validate-pack.py' .github/workflows/validate-pack.yml` → line 97 (general, no flag) + line 104 (`PACK_VALIDATE_DEEP=1`, no selector flag).
- **Interpretation:** "no flag = all checks" is structurally already true; an opt-in `--only-check` leaves the full-coverage job untouched. The 57 count is the O4 registry-completeness constant.
- **Conclusion: SUPPORTED.**

### §EE-9 — The six runtime guards exist and must be preserved
- **Claim:** six runtime guards (per-check WARN 2.0 s, total general 10 s, total deep 35 s, deep faithfulness 30 s, the `run_check` harness, the deep ENV-gate) exist.
- **Command + output:** `grep -nE 'RUN_CHECK_[A-Z_]+ *=' scripts/validate-pack.py` → 448 `…PER_CHECK_WARN…=2.0`, 449 `…TOTAL_GENERAL…=10.0`, 450 `…TOTAL_DEEP…=35.0`, 457 `…DEEP_FAITHFULNESS…=30.0`. `def run_check` at line 463 (times every check, WARNs on per-check overrun). Total-run FAIL block at lines 9599–9610 (general-only via `PACK_VALIDATE_DEEP` branch). Deep ENV-gate referenced at yml line 104.
- **Interpretation:** the design preserves all six: per-check WARN stays under `--only-check`; total-run is suppressed only in single-check mode (kept live in the no-flag job); new guards route through `run_check`.
- **Conclusion: SUPPORTED.**

### §EE-10 — The 3 stale "Check 54 reserved" comments exist at the named anchors
- **Claim:** three stale comments asserting Check 54 is "reserved" exist in validate-pack.py.
- **Command + output:** `grep -niE 'reserved' scripts/validate-pack.py` → among others, line 9549 (`Check number 54 — reserved for Guard-A′…`), 9572 (`54 is reserved for the C8b Guard-A′`), 9587 (`54 is reserved for the C8b Guard-A′`). Check 54 (`check_optional_features_presence`) is implemented (run_check call at lines 9552–9553) and wired (yml line 230–232).
- **Interpretation:** the "reserved" wording is stale; strip in C1 (cosmetic; located by `reserved`-grep, not line numbers which drift).
- **Conclusion: SUPPORTED.**

### §EE-11 — No client multi-script meta-battery (no shardable client surface)
- **Claim:** client `test.sh` wraps the project's own suite; no pack-shipped client battery to shard.
- **Command + output:** `head -40 project-template/scripts/test.sh` → language-detecting wrapper calling `test-swift.sh`/`test-python.sh`. `grep -lE 'for .*test.*\.sh|tests/.*\.sh' project-template/scripts/*.sh` → empty (no loop over a test-script set).
- **Interpretation:** there is no client surface analogous to the pack's `tests` job; shipping the sharding mechanism has no target.
- **Conclusion: SUPPORTED.**

---

## RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted / measured) | Conclusion |
|---|---|---|
| **empirical-evidence-blocks** | §EE-1…§EE-11: every load-bearing state-claim (job timings, 70/61/9 inventory, 24 spawns vs 238, ~1.2 s e2e leg, 0 argparse, 57 checks, six guards, 3 reserved comments, no client workflow/battery) carries command + verbatim output + HEAD `1f95b8e` + date 2026-06-14 + interpretation + SUPPORTED conclusion. | COMPLIANT |
| **ci-guard-design-measure-then-bound** | §4.2 MEASURE (70/61/9, the 9 named); §4.3 CATEGORIZE every unwired script KEEP/STRIP with the confirmation axis + evidence-to-confirm; allowlist (`ci-test-wiring-allowlist.txt`) sized to EXACTLY the confirmed STRIP set with one-line reasons, explicitly forbidding the "allowlist all 9 to go green" anti-pattern; §6.6/§4.4 verify the guard runs clean against the projected post-design tree (KEEP tests wired, STRIP tests allowlisted, partition generated from the wired list). | COMPLIANT |
| **ci-check-runtime-compounding** | §4.4 + §6.6: all six existing guards preserved (§EE-9); every new validate-pack check is glob+regex over the workflow + a dir listing + two small committed files (no subprocess-per-script, no hardcoded real-tree scan), routes through `run_check` (2.0 s WARN); the heavier run-time `--assert-coverage` lives in the aggregation JOB (once/run), NOT the ~24-spawn battery; `--only-check` is the cure for the redundant full-tree re-scan compounding, not a new compounding source. | COMPLIANT |
| **verify-availability-not-just-existence** | §2.1 availability matrix: matrix / dynamic-matrix / `fail-fast` / `needs` / `always()` are GA and account-type-agnostic, usable on the personal User account + private repo + ubuntu-latest + Free-plan concurrency floor (20 ≫ 4 shards). Design uses ONLY GA target-available features; no org-only/preview feature included (BD-204 phantom-fork failure mode avoided). | COMPLIANT |
| **pack-project-separation-of-concerns + P-missed-7 / boundary-investigation** | §7.1 investigated the project-side SSOT FIRST (project-template/.github = Issue forms only; client test.sh = own-suite wrapper; validate-pack.py pack-only). §7.2 recommends NOT shipping the pack mechanism (wasted + boundary risk). §7.3 the one project-side deliverable is project-native (OPTIONAL-FEATURES.md entry in client vocabulary; NO BD-NNN / validate-pack / pack-* / pack-ops / maintenance-docs refs) and ships as a SEPARATE project-only commit (C4). | COMPLIANT |
| **preliminary-triage-architect-challenge** | I independently RE-MEASURED every load-bearing research claim (§EE-1…§EE-11), CORRECTED the BD's 238→24, CHALLENGED the research's static-shard-map option in favor of a generated partition (§0 / §2.3), CHALLENGED a reflexive DROP of `--only-check` by re-validating the saving and concluding KEEP per the user's constraint (§3.2), and treated research candidate E as OUT-OF-SCOPE (surfaced as future BD, not absorbed). | COMPLIANT |
| **scope-deliverables-to-the-ask** | Design covers exactly BD-219's five deliverables (shard, upkeep guard, `--only-check` keep/drop, project-side, commit decomposition) + the 3 reserved-comment strips. Out-of-scope items SURFACED not absorbed: candidate-E long-pole refactor (future BD); newly-wired KEEP tests possibly failing on first wiring (planner sequences + surfaces, §4.3 callout); the branch-protection admin action flagged as repo-admin, not a code change. | COMPLIANT |
| **agents-never-commit** | Only read-only git verbs used: `git rev-parse HEAD`, `git branch --show-current`. No add/commit/push/checkout/etc. Single write = this design doc at `maintenance-docs/v11-implementation/ARCHITECTURE-BD-219-CI-RUNTIME-OPTIMIZATION.md` (the caller-specified RO-agent report). No source file edited. | COMPLIANT |
| **rules-applied-verification-block** | This table — per-rule, quoted/measured evidence, terminal COMPLIANT conclusion; no empty evidence, no AMBIGUOUS. | COMPLIANT |

