<!-- pack-only planning artifact — feeds the BD-219 coder. Not a client deliverable. -->
# PLAN — BD-219 CI Runtime Optimization (effectiveness-preserving)

**Planner:** pack-planner (plan stage; AFTER the architect; feeds the coder)
**Date:** 2026-06-14 · **Repo HEAD at planning:** `1f95b8eedd9fa21b7c9a824736648599c543bb2d` (branch `v11-dev`)
**Primary inputs:** `backlog/BD-219.md`; `maintenance-docs/v11-implementation/ARCHITECTURE-BD-219-CI-RUNTIME-OPTIMIZATION.md` (the APPROVED design — sequenced here, NOT changed); `maintenance-docs/v11-implementation/RESEARCH-BD-219-CI-RUNTIME-OPTIMIZATION.md`.
**Account/runner target:** personal GitHub **User** account; repo **PRIVATE**; runners `ubuntu-latest`.

> This is an EXECUTION plan. It turns the architect's locked design into an
> exact, ordered, per-commit recipe a coder can follow without ambiguity. It
> does NOT relitigate any design decision (4 shards, dynamic matrix, KEEP
> `--only-check`, generalized Check 42, project-side doc-only). Where this plan
> states a fact about the repo it carries an Empirical-Evidence Block (bottom).

---

## READ ATTESTATION (each read IN FULL, no skim/crop/derive)

| Doc | Read |
|---|---|
| `CLAUDE.md` § "## Pack memory" (all rules) | YES (full, via session context) |
| `backlog/BD-219.md` (incl. 2026-06-14 + the two 2026-06-15 notes) | YES (lines 1–22, full) |
| `backlog/BD-220.md` (Candidate E anchor) | YES (lines 1–18, full) |
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-219-CI-RUNTIME-OPTIMIZATION.md` | YES (lines 1–475, full) |
| `maintenance-docs/v11-implementation/RESEARCH-BD-219-CI-RUNTIME-OPTIMIZATION.md` | YES (lines 1–357, full) |
| `.github/workflows/validate-pack.yml` | YES (lines 1–324, full) |
| `scripts/validate-pack.py` — `main()` (9338), `__main__` (9621), `run_check` (463), Check 42 (6688), reserved-54 comments (9549/9572/9587) | YES (targeted, verified §EE) |
| `project-template/docs/pack/OPTIONAL-FEATURES.md` (entry shape + "Adding new entries") | YES (full structure) |
| `…/memory/feedback_verify_full_ci_suite.md` | YES (full) |
| `…/memory/feedback_manifest_regen_on_v11_surface.md` | YES (full) |
| `…/memory/feedback_commit_subject_keyword_token_trap.md` | YES (full) |
| `…/memory/feedback_architect_planner_empirical_evidence.md` | YES (full) |
| `…/memory/feedback_ci_guard_design_measure_then_bound.md` | YES (full) |
| `…/memory/feedback_ci_check_runtime_compounding.md` | YES (full) |

All load-bearing state-claims independently re-verified at HEAD `1f95b8e` on
2026-06-14 (Empirical-Evidence Blocks §EE-P1…§EE-P10). I did not change any
design decision; I sequenced the design and corrected one minor architect
note now moot under verified facts (branch protection — §2 below).

---

## 0. COMMIT SEQUENCE OVERVIEW

Four single-surface commits. **Recommended order: C1 → C3 → C2 → C4.**
(This matches the architect §8 sequence and is dependency-justified in §3 of
this plan: the dynamic matrix in C2 imports `ci-shard-plan.py` created in C3, so
C3 must precede C2; C1 is the standalone `--only-check`/registry/comment-strip
work that C3's registry-completeness guard depends on at run-but-not-author
time.)

| # | Order | Scope keyword | Surface | One-line contents | Manifest regen? | Review cycle |
|---|---|---|---|---|---|---|
| **C1** | 1st | `pack-only` | `scripts/validate-pack.py` + 23 per-check test legs + manifest | `--only-check` argparse + `CHECK_REGISTRY` refactor + total-run budget suppression + adopt flag in e2e legs + strip 3 stale "Check 54 reserved" comments | YES (scripts/) | coder → reviewer → triage → fix → final reviewer |
| **C3** | 2nd | `pack-only` | `scripts/validate-pack.py` (Check 42 generalize + new checks) + 3 NEW files under `scripts/` + new/updated guard tests + wire KEEP tests in yml + manifest | wiring-completeness generalization + shard-plan module + weights tsv + allowlist + full-run/registry guards + wire confirmed-KEEP unwired tests | YES (scripts/) | own cycle |
| **C2** | 3rd | `pack-only` | `.github/workflows/validate-pack.yml` (+ manifest only if a `scripts/` file co-changes) | `plan` job + matrix `tests` job (`fail-fast:false`, dynamic `fromJSON`) + `tests-result` aggregation job | NO (yml-only; see note) | own cycle |
| **C4** | 4th | `project-only` | `project-template/docs/pack/OPTIONAL-FEATURES.md` | one project-native "CI test parallelization" entry; NO pack-self leak | N/A (project-template/ IS v11-surface — see §C4) | own cycle |

**Multi-commit single-BD review model (per `bounded-review-fix-cycle` +
`per-BD-review-fix-runs-inline`):** each commit gets its OWN bounded cycle
(coder → reviewer → triage → fix-coder → final reviewer; max 2 fix pairs + 1
final pass). There is ALSO an end-of-BD reviewer pass over the whole BD-219
batch after C4 lands. Each commit's coder is a FRESH instance
(`per-commit-fresh-coder`).

**Branch-protection note (architect §2.6 / research §2.3 MOOTED — established
fact):** branch protection is NOT enabled on this repo (Free plan + private;
required status checks are a Pro/public feature — verified 2026-06-15 by the
caller). Therefore the design's "required-check rename hazard" and the paired
repo-admin action ("coordinate `tests` → `tests-result` in branch protection")
do NOT apply: there is no live gate to break and no admin action to schedule.
The plan KEEPS the `tests-result` aggregator job (good practice + future-proof
for when protection is enabled), but drops every step that says "coordinate a
branch-protection change." This is a one-line correction to the architect's §2.6
process step, not a design change.

---

## 1. SHARED CONTRACTS (apply to every commit's coder + reviewer)

These bind ALL commits; per-commit sections do not repeat them.

### 1.1 Manifest-regen contract (`regenerate-manifest-v11-surface`)
Any commit whose diff touches `project-template/`, `scripts/`, `pack-ops/`, or
`supporting-docs/` MUST regenerate `test-fixtures/manifest.txt`
(`bash test-fixtures/build.sh --all --clean`) and stage it in the SAME commit
**when the manifest diff is non-empty**. Per-commit applicability:
- **C1** touches `scripts/` → regen; stage manifest iff diff non-empty.
- **C3** touches `scripts/` → regen; stage manifest iff diff non-empty.
- **C2** touches only `.github/` (NOT a v11-surface dir) → NO regen UNLESS a
  `scripts/` file co-changes in C2 (it should not, per the surface split).
- **C4** touches `project-template/` → regen; stage manifest iff diff non-empty.
  (A doc-only edit to OPTIONAL-FEATURES.md almost certainly yields an EMPTY
  manifest diff — manifest tracks fixture SHAs, not doc text — but the coder
  MUST run the regen and CHECK, never assume empty.)

The coder runs `bash test-fixtures/build.sh --all --clean`, then
`git status --short test-fixtures/manifest.txt`; if `M`, stage it in the same
commit; if clean, note "manifest diff empty — not staged" in the IMPL-REPORT.

### 1.2 Full-CI-suite verification contract (`verify-full-ci-suite`)
A green `validate-pack.py` is NOT a green commit. For EVERY commit, the coder's
PREFLIGHT and the reviewer's independent pass MUST run the FULL battery:
1. `python3 scripts/validate-pack.py` (general).
2. `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` (deep).
3. **Every** test script wired in `.github/workflows/validate-pack.yml`'s
   `tests` job — extract the complete `run: bash …` list from the yml and run
   each, quoting each EXIT status. Sampling a subset is the defect that caused
   the BD-203 C-1 and BD-214 C1 CI-red incidents. (The wired list at HEAD is 61
   scripts — §EE-P3; after C3 wires the confirmed-KEEP tests it grows.)
4. **Enumerate-encoding-surfaces:** any commit that changes validator OUTPUT
   (banner text, a check's printed verdict, a new check's banner) MUST grep ALL
   of `scripts/tests/` (unit AND `test-v11-*` integration) for assertions on the
   changed output and update them in lock-step. C1 (registry/`--only-check`
   refactor risks touching banners) and C3 (Check 42 generalization changes its
   printed message) are the high-risk commits here.

### 1.3 Runtime-cost contract (`ci-check-runtime-compounding`)
Every NEW or generalized `validate-pack.py` check (C1 registry-completeness +
full-run-no-flag; C3 generalized Check 42 + shard-coverage mirror) MUST be a
cheap glob+regex over `.github/workflows/validate-pack.yml` + a directory
listing + reads of the two small committed files (weights tsv, allowlist) — NO
subprocess-per-script, NO hardcoded whole-real-tree scan, scoped to the repo's
own workflow/test dirs. Each MUST route through `run_check` so the per-check
2.0 s WARN budget catches a regression. The heavier run-time `--assert-coverage`
re-check lives in the `tests-result` aggregation JOB (once per CI run), NOT on
the ~24-spawn battery path. The six existing runtime guards (§EE-P9) are
preserved verbatim; under `--only-check` the total-run budget is SUPPRESSED (one
check is not the real surface) while the per-check WARN STAYS ACTIVE — the
no-flag `validate` job keeps the total-run budget LIVE over the full set.

### 1.4 Commit-subject keyword contract (`commit-subject-keyword-token-trap`)
Each commit subject carries EXACTLY its one claimed scope keyword and NO OTHER
keyword token anywhere in the subject (Check 36 substring-scans the whole
subject; a denying token wins). Approved forms:
- **C1/C3:** `feat: v11 — BD-219 <desc> (pack-only)` — the subject MUST NOT
  contain the literal `project-only` or `pack-chat-only` tokens anywhere.
- **C2:** `feat: v11 — BD-219 <desc> (pack-only)` — same rule. Describe the
  workflow restructure without any other keyword token.
- **C4:** `feat: v11 — BD-219 <desc> (project-only)` — the subject MUST NOT
  contain `pack-only` or `pack-chat-only`. Describe the doc as "client-facing"
  or "project-native," never with a pack-keyword token.
ALWAYS re-run `validate-pack.py` AFTER the commit exists (Check 36 validates
subject-vs-diff and can only surface post-commit).

### 1.5 PREFLIGHT contract (`preflight-stop-means-stop`)
Each coder emits the single PREFLIGHT line only after all in-scope edits +
verification (full battery §1.2 + manifest §1.1) PASS; if anything fails, report
what went wrong INSTEAD of a partial IMPL-REPORT. A parent stop/halt message
halts all work immediately.

---

## 2. PER-COMMIT DETAIL

### C1 — `--only-check` + `CHECK_REGISTRY` + per-check e2e leg adoption + 3 stale-comment strips (`pack-only`)

**Goal:** add the greenfield `--only-check` selector (KEEP decision, design §3),
refactor `main()`'s flat `run_check` sequence into a `CHECK_REGISTRY` so the
selector and a future registry-completeness guard share one source, adopt the
flag in the per-check e2e legs WITHOUT weakening assertions, and strip the 3
stale "Check 54 reserved" comments (BD anchor; cosmetic).

**Files created:** none.

**Files edited:**

1. `scripts/validate-pack.py`
   - **Add argparse** (greenfield — 0 existing argparse, §EE-P7) inside the
     `if __name__ == "__main__":` block (line 9621) and/or `main()` (line 9338).
     Define `--only-check` accepting a numeric check number (`52`) AND the
     `run_check` label string (`check_pack_rw_ro_two_class`) per design §3.3
     item 1. Default `None` → run ALL checks.
   - **`CHECK_REGISTRY` refactor (design §3.3 item 3):** extract the flat
     `run_check(...)` sequence in `main()` (57 callsites — §EE-P5) into an
     ordered registry of `(number, label, callable)`. `main()` builds the
     registry once; with no flag, iterates the full registry through `run_check`
     (preserving per-check WARN timing + order); with `--only-check K`, resolves
     K against the SAME registry and runs ONLY the matching entry. An unmatched
     selector exits non-zero with a LOUD named error (never a silent no-op — a
     silent no-op turns a per-check test into a tautology = effectiveness loss).
   - **Total-run budget suppression (design §3.3 item 4):** `main()` SKIPS the
     `total_elapsed > total_budget` FAIL block when `--only-check` is set (prints
     a one-line "total-run budget N/A in single-check mode" notice). The per-check
     WARN budget STAYS active. The no-flag path keeps the total-run budget LIVE.
     The deep ENV-gate + deep faithfulness budget are UNCHANGED (orthogonal).
   - **Exit-code contract (design §3.3 item 5):** `--only-check K` exits non-zero
     IFF the selected check FAILed (appended to `failures`); unknown K → non-zero
     named error.
   - **Preserve the module-import path:** the `if __name__ == "__main__"` guard
     (line 9621) MUST remain so per-check tests' `spec_from_file_location` import
     does NOT run `main()` (§EE-P7). Add argparse INSIDE the guard / inside
     `main()`, never at module top level.
   - **Strip the 3 stale "Check 54 reserved" comments** (BD-219 folded-in
     cleanup; located by grepping `reserved` referencing Check 54 / Guard-A′, NOT
     by line number — they drift). At HEAD they are at lines **9549, 9572, 9587**
     (§EE-P10): 9549 `Check number 54 — reserved for Guard-A′…`; 9572
     `…54 is reserved for the C8b Guard-A′…`; 9587 `…54 is reserved for…` (inside
     a "Check number 57 (next available…" comment). Check 54 is fully implemented
     + CI-wired (yml line 230) — the "reserved" wording is stale. COSMETIC: strip
     the stale "reserved" assertion from each of the three comment sites
     (preserve any surrounding non-stale comment text). The coder re-greps
     `reserved` after editing to confirm no Check-54-reserved comment remains.

2. `scripts/tests/test-validate-pack-check*.sh` (the 23 per-check test files —
   §EE-P5) — adopt `--only-check NN` for the e2e leg ONLY (design §3.4):
   - Change each e2e subprocess from `python3 …/validate-pack.py` to
     `python3 …/validate-pack.py --only-check NN` (NN = that file's check number).
   - **Preserve ALL THREE assertions verbatim** (exit-0; the "Check NN:" banner;
     the clean-verdict line). The flag narrows WHICH checks run in the subprocess;
     it does NOT change WHETHER the target check's assertion fires. Do NOT delete
     or weaken any assertion.
   - The module-import unit-assertion legs (in-process check calls) are
     UNCHANGED.
   - **Wiring-proof migration (design §3.4 last bullet + §6.4):** the e2e leg
     today implicitly proved "Check NN is wired into `main()`'s full run." Under
     `--only-check` that implicit proof is replaced by the explicit
     registry-completeness guard introduced in **C3** (§6.4). C1 therefore does
     NOT lose the wiring proof permanently — but note the dependency: C3 MUST
     land for the wiring proof to be re-established. (This is why C1 → C3 order
     matters even though C1 ships first: C1's e2e legs stop carrying the implicit
     wiring side-effect, and C3 restores it as an asserted invariant. See §3.)

3. `test-fixtures/manifest.txt` — regen per §1.1 (C1 touches `scripts/`); stage
   iff diff non-empty.

**Scope keyword:** `pack-only`. Subject e.g.
`feat: v11 — BD-219 add validate-pack --only-check + CHECK_REGISTRY; strip stale Check-54 reserved comments (pack-only)`.
No other keyword token anywhere in the subject.

**Manifest regen:** YES (scripts/).

**Verification (full battery §1.2) + C1-specific effectiveness proofs:**
- Run the full wired battery (61 scripts) + general + deep validate-pack,
  quoting each exit status.
- **`--only-check` round-trip proof (per BD acceptance, mutation-proven):** for
  a sample of per-check tests (at minimum checks 52, 43, 40 — the ones measured
  §EE-P6), prove (a) `--only-check NN` exits 0 on clean HEAD and prints the
  Check NN banner+verdict; (b) MUTATE that check's body to force a failure →
  `--only-check NN` exit flips non-zero AND the per-check test FAILs (proving the
  narrowed run still catches the regression); (c) revert the mutation.
- **Full-job-runs-all-checks proof:** `python3 scripts/validate-pack.py` with NO
  flag still runs all 57 registry checks (count the banners / assert registry
  length 57 — §EE-P5/§EE-P8). Confirm the `validate` job invocations (yml lines
  97, 104) carry no `--only-check` (the C3 guard will enforce this; C1 verifies
  it manually).
- **Unknown-selector loudness proof:** `--only-check 9999` (and
  `--only-check bogus_label`) exits non-zero with a named error, NOT a silent
  pass.
- **No-weakening proof:** diff each edited per-check test; confirm the three
  assertions are byte-preserved except the subprocess flag addition.
- Enumerate-encoding-surfaces: grep `scripts/tests/` for any assertion on
  validate-pack's no-flag full-run banner sequence that the registry refactor
  could perturb; update in lock-step if any.

**Review cycle:** fresh coder → reviewer → Pack-Chat triage → fix-coder (if
needed) → final reviewer. Bounded: max 2 fix pairs + 1 final pass.

---

### C3 — generalized Check 42 + shard-plan module + weights + allowlist + full-run/registry guards + wire KEEP tests (`pack-only`)

**Goal:** close the upkeep gap (design §4/§6). Generalize Check 42 to full
set-equality over the CI-eligible test set; introduce the single-source shard
partition module + its weight data + the measured allowlist; add the
full-run-no-flag and registry-completeness guards (the latter restores C1's
moved wiring proof); confirm + WIRE the KEEP unwired tests.

**Files created:**

1. `scripts/lib/ci-shard-plan.py` (design §2.3/§6.1) — single source of the
   partition. Reads the wired-test list (parsed from
   `.github/workflows/validate-pack.yml`, the SAME parse Check 42 uses) + the
   weights TSV; LPT bin-packs into N=4 shards. Modes:
   - `--emit-matrix` → prints the GitHub Actions matrix JSON
     (`{"include":[{"shard":1,"scripts":"a.sh b.sh …"},…]}`) for the `plan` job.
   - `--assert-coverage` → exit non-zero unless `union(shards) == wired_KEEP_set`
     AND shards pairwise-disjoint.
   - `--shard N --needs-fixtures` → exit 0 iff shard N owns a fixture-dependent
     test (drives the conditional fixture build, design §2.5).
   - Pins the fixture-dependent COHESION GROUP into a single shard and asserts
     the build/restore/verify triple stays co-located (design §2.5). The
     fixture-dependent set is the named tests at yml lines 284–314:
     `build.sh --all --clean`, the BD-118 manifest-restore, `build.sh --verify`,
     `test-v11-realistic-ot.sh`, `test-migrator-skills.sh`,
     `test-persona-contracts.sh` (the BD-163/BD-115/BD-116 group).
   - Missing/unknown script → default (median) weight so balance degrades
     gracefully, never breaks (design §6.5).
   - Lives in `scripts/lib/` (pack-side test infra; NOT a client deliverable;
     NOT a runtime dependency of any pack OPERATION — invoked only by CI + the
     validate-pack guard, so dependency-direction is satisfied,
     `dependency-direction-placement`). It is NOT added to the
     `_SANCTIONED_PACK_SIDE_SHIPPED` allowlist (it does not ship to clients).

2. `scripts/ci-shard-weights.tsv` (design §2.3) — one row per wired test script:
   `<script-path>\t<measured_seconds>`. Seed from the research §1.2 CI per-step
   durations (94/61/52/34/31/29/14/11/10/8 s for the named heavy steps; median
   default for the rest). Data, not logic. (Candidate E is OUT — BD-220; this
   commit only POPULATES the tsv with measured values, never refactors a test.)

3. `scripts/ci-test-wiring-allowlist.txt` (design §4.3/§6.2) — the measured
   STRIP set ONLY, each with a one-line reason. Sized to EXACTLY the
   confirmed-intentionally-OUT scripts — no broader (`ci-guard-measure-then-bound`).

4. New guard test(s) under `scripts/tests/` — e.g.
   `test-validate-pack-ci-shard-coverage.sh` (or fold into existing patterns) and
   any test for the shard-plan module + the new full-run/registry checks. The
   coder picks the lowest-churn shape but MUST cover: generalized-Check-42
   set-equality (KEEP-wired / STRIP-allowlisted), `--assert-coverage`,
   full-run-no-flag, registry-completeness. These new per-check test files MUST
   themselves be wired into the yml `tests` job (Check 42 generalized will demand
   it) — see the yml edit below.

**Files edited:**

1. `scripts/validate-pack.py`
   - **Generalize Check 42** (`check_ci_workflow_wires_per_check_tests`, line
     6688) to full set-equality (design §6.2): invariant
     `disk_KEEP_set == wired_set` where
     `disk_KEEP_set = {scripts/test*.sh + scripts/tests/*.sh} − allowlist` and
     `allowlist = scripts/ci-test-wiring-allowlist.txt`. FAIL names each unwired
     KEEP script AND each allowlisted-but-now-wired script (allowlist staleness).
     Keep the existing per-check sub-assertion as a special case OR fold it into
     the general set-equality (coder picks lower churn; either way
     `test-validate-pack-check-42.sh` is updated in lock-step —
     `enumerate-encoding-surfaces`). Cheap glob+regex (§1.3).
   - **Shard-coverage validate-pack mirror** (design §6.3, recommended): a thin
     check that shells/imports `ci-shard-plan.py --assert-coverage` so a local
     `validate-pack` run surfaces coverage drift without pushing. Routes through
     `run_check`; cheap (the module reads two small files). (The authoritative
     run-time assertion is in C2's aggregation job; this is the convenience
     mirror.)
   - **Full-job-no-flag invariant** (design §6.4): a check parsing the yml that
     asserts the `validate` job's `python3 scripts/validate-pack.py` invocations
     carry NO `--only-check`. Cheap regex.
   - **Registry-completeness invariant** (design §6.4 — restores C1's moved
     wiring proof): assert `len(CHECK_REGISTRY) == <expected_count>` and that
     every registry entry is reachable by the full run. Expected count is **57**
     at HEAD (§EE-P5/§EE-P8) **BUT** the C1+C3 work ADDS new checks (shard-mirror,
     full-run-no-flag, registry-completeness, generalized-42 stays one slot). The
     coder MUST compute the FINAL registry count at wire time and set the constant
     to that value — DO NOT hard-code 57 blindly (see §5 cross-doc note). The
     expected-count constant is a one-line bookkeeping edit (like the existing
     agent-count check).
   - **Number the new checks** at the next available numbers after the highest
     wired check. Highest wired today is **57** (yml line 227, §EE-P8 / the yml
     wiring list). The new checks (generalized-42 keeps 42; shard-coverage
     mirror, full-run-no-flag, registry-completeness are NEW) get **58, 59, 60**
     in author order — **coder-confirmed-at-wire-time** by reading the current
     highest check number, NOT hard-coded from this plan (numbers drift; §5).

2. `.github/workflows/validate-pack.yml` — **wire the confirmed-KEEP unwired
   tests as plain sequential `run: bash` steps** (design §8 note, Option (i)):
   add a `- name: … / if: always() / run: bash <script>` step for each
   confirmed-KEEP script + each new C3 guard test. Wiring them as plain steps in
   C3 (NOT as shards) means C2's dynamic partition picks them up automatically
   (the partition reads the wired list). This keeps C3's generalized wiring guard
   GREEN before C2 reshapes the job. **This is the ONLY yml edit C3 makes** — no
   matrix/shard structure (that is C2).

3. `test-fixtures/manifest.txt` — regen per §1.1 (C3 touches `scripts/`); stage
   iff diff non-empty.

**CRITICAL measure-then-bound step (coder MUST do — `ci-guard-measure-then-bound`):**
the architect gave a PRELIMINARY KEEP/STRIP classification of the 9 unwired
scripts (§EE-P3 lists them) in design §4.3. The coder MUST CONFIRM each by
opening the script header before sizing the allowlist:
- **STRIP (→ allowlist, with reason):** a script that (a) touches a LIVE
  network/GH surface (cannot run offline in CI) or (b) is a manual-only dev
  utility with no offline-deterministic mode. Architect's preliminary STRIP:
  `test-tracker-promote-direct.sh`, `test-tracker-promote-path1.sh`,
  `test-tracker-promote-path2.sh` (live-GH family).
- **CONFIRM → likely KEEP (→ wire + shard):** `tracker-bd204-lossless-roundtrip-test.sh`,
  `test-activate-capability.sh`, `test-add-capability.sh`,
  `test-compare-agent-trinity.sh`, `test-dry-run-migration.sh`,
  `test-restore-from-backup.sh`. The coder opens each header; if it runs offline
  deterministically → KEEP+wire; if it needs a live surface → STRIP+allowlist.
- The allowlist is sized to EXACTLY the confirmed STRIP set — never broadened to
  "allowlist all 9 to go green" (the forbidden anti-pattern).
- **Run-each-KEEP-green-BEFORE-wiring (design §4.3 SURFACED callout):** before
  wiring a KEEP test, the coder runs it locally to confirm it passes offline. A
  dormant test that has bit-rotted could fail on first wiring. If a KEEP test
  FAILs on first run, the coder SURFACES it to Pack Chat/user as a SEPARATE
  finding (a new BD candidate), rather than force-fixing it inside BD-219 or
  silently allowlisting it. (Allowlisting a KEEP test to dodge a failure is the
  forbidden anti-pattern.)

**Scope keyword:** `pack-only`. Subject e.g.
`feat: v11 — BD-219 generalize CI wiring guard + shard-plan module + full-run/registry guards; wire dormant KEEP tests (pack-only)`.

**Manifest regen:** YES (scripts/).

**Verification (full battery §1.2) + C3-specific guard-effectiveness proofs:**
- Run the full wired battery (now GROWN by the newly-wired KEEP tests + new
  guard tests) + general + deep validate-pack, quoting each exit status.
- **Generalized-42 FAILs on an unwired KEEP test:** temporarily remove a wired
  KEEP test's yml step → Check 42 FAILs naming it → restore. AND: temporarily
  add an allowlisted (STRIP) script's yml step → Check 42 FAILs on allowlist
  staleness → restore.
- **Allowlist bounded proof:** confirm the allowlist contains ONLY the confirmed
  STRIP scripts (count + names match the categorization); no KEEP script
  appears.
- **`--assert-coverage` proof:** `ci-shard-plan.py --assert-coverage` exits 0 on
  the real wired list; `union(shards) == wired_KEEP_set` and shards pairwise
  disjoint (print the partition + the set diff = empty). Corrupt the weights tsv
  / drop a script from a shard in a scratch copy → `--assert-coverage` FAILs.
- **Full-run-no-flag guard FAILs when violated:** in a scratch yml, add
  `--only-check 1` to the `validate` job invocation → the guard FAILs → confirm
  the real yml passes.
- **Registry-completeness guard:** mutate `CHECK_REGISTRY` (drop an entry) →
  guard FAILs on the count mismatch → revert. Confirm the expected-count
  constant equals the ACTUAL final registry length (coder-computed, not 57
  assumed).
- **Runtime-cost proof (`ci-check-runtime-compounding`):** time the general
  validate-pack run before/after C3; confirm no new check exceeds the 2.0 s
  per-check WARN and the general total stays under the 10 s total-run budget
  (the new checks are glob+regex — milliseconds).
- Enumerate-encoding-surfaces: `test-validate-pack-check-42.sh` updated in
  lock-step with the generalized message; grep `scripts/tests/` for any other
  assertion on Check 42's printed text.

**Review cycle:** own bounded cycle (fresh coder → reviewer → triage → fix →
final).

---

### C2 — dynamic matrix workflow restructure + `tests-result` aggregation (`pack-only`)

**Goal:** restructure the monolithic sequential `tests` job into a 4-shard
dynamic matrix consuming `ci-shard-plan.py` (from C3), with a `plan` job emitting
the partition and a `tests-result` aggregation job as the single signal (design
§2.4).

**Files created:** none.

**Files edited:**

1. `.github/workflows/validate-pack.yml` — apply the design §2.4 shape:
   - **`validate` job — UNCHANGED** (runs ALL checks, general + deep; not
     sharded; lines 85–104).
   - **NEW `plan` job:** `runs-on: ubuntu-latest`; checkout + setup-python; one
     step `python3 scripts/lib/ci-shard-plan.py --emit-matrix` → `$GITHUB_OUTPUT`
     `matrix`. (No `needs:`.)
   - **`tests` job → matrix:** `needs: [plan]`;
     `strategy: { fail-fast: false, matrix: ${{ fromJSON(needs.plan.outputs.matrix) }} }`.
     `fail-fast: false` is a HARD REQUIREMENT (preserves "surface all failures").
     Steps: checkout (`fetch-depth: 0`) + setup-python + `pip install pyyaml`;
     conditional fixture build (`if: always()` + `ci-shard-plan.py --shard … --needs-fixtures`
     guard → `build.sh --all --clean` + the BD-118 manifest-restore
     `git checkout HEAD -- test-fixtures/manifest.txt`); the per-script run loop
     (`if: always()`; `for t in ${{ matrix.scripts }}; do …; bash "$t" || rc=1; …; done; exit $rc`)
     with `::group::` markers. The per-script `|| rc=1` loop preserves the current
     per-step `if: always()` "every script runs, shard exits non-zero on any
     failure" property.
   - **NEW `tests-result` job:** `needs: [plan, tests]`, `if: always()`;
     checkout + setup-python; step 1 asserts `needs.tests.result == 'success'`
     (converts "a shard failed → aggregator skipped" into "→ aggregator FAILED" —
     the anti-footgun); step 2 runs `ci-shard-plan.py --assert-coverage`
     (run-time coverage re-assertion, defense in depth). This job is the single
     signal (and the future required check, if protection is ever enabled).
   - **NO path/branch filter** added (research §2.2 rule 7); `on: push` unchanged.

2. `test-fixtures/manifest.txt` — NO regen (C2 touches only `.github/`, not a
   v11-surface dir). If — and only if — the coder finds a `scripts/` file must
   co-change in C2 (it should NOT, per the surface split), then regen applies;
   otherwise the coder notes "C2 is yml-only; no v11-surface scripts/ change; no
   manifest regen."

**Branch-protection (MOOT — established fact, see §0):** branch protection is
NOT enabled on this repo, so there is NO required-check rename to coordinate and
NO repo-admin action paired with C2. The architect's §2.6/§8 "paired repo-admin
action" step is DROPPED. The `tests-result` aggregator is retained as good
practice + future-proofing (if protection is enabled later, `tests-result` is
the count-stable required check to point at — but that is a future, out-of-BD
action). The coder does NOT touch branch-protection settings (and could not —
RO; and there is nothing to touch).

**Scope keyword:** `pack-only`. Subject e.g.
`feat: v11 — BD-219 shard the tests job via dynamic matrix + tests-result aggregation (pack-only)`.

**Manifest regen:** NO (yml-only) — unless a `scripts/` file co-changes (it
should not).

**Verification (full battery §1.2) + C2-specific proofs:**
- **Local pre-push proofs (cannot fully exercise the matrix locally — it runs in
  CI):** validate the yml is syntactically well-formed (`python3 -c` yaml parse
  or `actionlint` if available); run `ci-shard-plan.py --emit-matrix` and confirm
  it emits valid JSON with 4 shards, each a non-empty `scripts` string;
  `ci-shard-plan.py --assert-coverage` exits 0; for each shard,
  `ci-shard-plan.py --shard N --needs-fixtures` returns the expected fixture-need
  (exactly the fixture-owning shard returns true).
- **Coverage-by-construction proof:** confirm `union(shards) == wired_KEEP_set`
  (every wired test lands in exactly one shard; print the partition). Confirm the
  fixture cohesion group (build/restore/verify + realistic-ot + migrator-skills +
  persona-contracts) is co-located in ONE shard in the BD-163 order.
- **Every-wired-test-still-runs proof:** the union of all shards' `scripts`
  equals the full wired list — no test silently un-sharded (this is the BD
  acceptance criterion; `--assert-coverage` is the enforcer).
- **Run the full local battery** (§1.2) to confirm the restructure did not change
  any test's behavior (the scripts are unchanged; only orchestration changed).
- **Post-push (the real matrix gate):** watch the actual CI run via
  `gh run list` / `gh run view` (Pack Chat backstop). Confirm 4 shards run,
  `fail-fast: false` keeps siblings running on a forced failure, `tests-result`
  reports the aggregate, and `--assert-coverage` passes. Record the BEFORE
  (~462 s sequential tests job — §EE-P1) and AFTER (max-shard ~140–160 s)
  wall-time for the BD acceptance "measurable reduction" criterion.

**Review cycle:** own bounded cycle.

---

### C4 — project-native "CI test parallelization" note in OPTIONAL-FEATURES.md (`project-only`)

**Goal:** ship ONE short, project-native, boundary-compliant note so PM chats
can proactively tell their users that GitHub Actions `strategy: matrix`
parallelizes a sequential multi-suite CI battery (design §7). Ship NOTHING
mechanical.

**Files created:** none.

**Files edited:**

1. `project-template/docs/pack/OPTIONAL-FEATURES.md` — add ONE new section
   following the file's "Adding new entries" convention (line 308: Status / What
   it is / When it matters / How to enable / How to use the pack's pieces with
   it / Caveats / When to skip). Place it as a new `##` section (e.g. before the
   "Tracker integration (deferred)" section or after the Gemini placeholder —
   coder picks a natural slot among the existing `##` sections at lines 19, 96,
   274, 281, 288, 308).
   - **Title:** "CI test parallelization (GitHub Actions matrix)".
   - **Content (project-native vocabulary ONLY):** if your project's CI runs many
     independent test suites sequentially in one job and wall-time is a pain,
     GitHub Actions `strategy: matrix` (with `fail-fast: false` to surface all
     failures, and an aggregation job as the single required status check)
     parallelizes them across runners with NO loss of coverage — every suite
     still runs. Note the required-status-check rename consideration (a matrix
     renames the job's check; require an aggregation job). When to skip: CI
     already fast or single-suite.
   - **Boundary discipline (HARD — `bd-pack-only-operational-rule`,
     `pack-project-separation-of-concerns`, P-missed-7):** the entry mentions NO
     `BD-NNN`, NO `validate-pack.py`, NO `pack-*` agent name, NO `pack-ops/`, NO
     `maintenance-docs/`, NO reference to the pack's own `tests` job. Client
     vocabulary only ("your CI", "your test suites"). General technique guidance,
     not a description of the pack's internal optimization.
   - **Trinity note:** OPTIONAL-FEATURES.md is a single project-side doc, NOT a
     trinity CLAUDE/AGENTS/GEMINI file → no trinity parallel-edit triggered.

2. `test-fixtures/manifest.txt` — `project-template/` IS a v11-surface dir, so
   the coder RUNS the regen (`build.sh --all --clean`) and CHECKS the diff. A
   doc-only text edit to OPTIONAL-FEATURES.md will almost certainly yield an
   EMPTY manifest diff (the manifest pins fixture SHAs, not arbitrary
   project-template doc text) — but the coder MUST run+check, NOT assume. If the
   diff is empty, do NOT stage the manifest (staging it would break the
   `project-only` keyword — manifest.txt is outside project prefixes); note
   "manifest diff empty — not staged" in the IMPL-REPORT. If — unexpectedly —
   the diff is non-empty, the manifest change canNOT ride in a `project-only`
   commit (Check 36 would deny); the coder STOPS and surfaces this to Pack Chat
   (it would mean a fixture changed, which a doc edit should not cause —
   investigate before committing).

**Scope keyword:** `project-only`. Subject e.g.
`feat: v11 — BD-219 document CI test parallelization for client projects (project-only)`.
The subject MUST NOT contain `pack-only` or `pack-chat-only` tokens. Describe it
as "client-facing"/"project-native," never with a pack-keyword token.

**Manifest regen:** run+check (project-template/ is v11-surface); expected empty
→ not staged.

**Verification (full battery §1.2):**
- Run general + deep validate-pack + the full wired battery — confirm the doc
  edit breaks nothing (Check 44 durable-doc concision, Check 43 project-side leak
  scanner, and any project-template structure checks pass).
- **Boundary-leak proof:** grep the new entry for `BD-`, `validate-pack`,
  `pack-ops`, `maintenance-docs`, `pack-` → ZERO hits (Check 43 enforces this;
  the coder verifies manually too).
- Confirm Check 36 passes post-commit on the `project-only` keyword (the diff is
  exclusively under `project-template/`).

**Review cycle:** own bounded cycle.

---

## 3. DEPENDENCY-ORDERING RATIONALE (why C1 → C3 → C2 → C4)

The order is dictated by three hard dependencies and one soft preference.

1. **C3 BEFORE C2 (hard — import dependency).** C2's `tests` matrix consumes
   `ci-shard-plan.py` via the `plan` job's `--emit-matrix` and the aggregation
   job's `--assert-coverage`. That module is CREATED in C3. If C2 landed first,
   its workflow would reference a non-existent script → the `plan` job fails →
   the whole sharded `tests` job never runs. So C3 must precede C2. (This is the
   architect §8 ordering; confirmed dependency-correct.)

2. **C1 BEFORE C3 (hard — registry-then-guard dependency).** C3's
   registry-completeness guard (§6.4) asserts over the `CHECK_REGISTRY` that C1
   introduces. The guard cannot exist before the registry it guards. Equally
   important: C1's per-check e2e legs STOP carrying the implicit "Check NN is
   wired into `main()`" proof (they now run `--only-check NN`), and C3's
   registry-completeness guard RESTORES that proof as an explicit asserted
   invariant. The window between C1 landing and C3 landing is the only point
   where the wiring proof is weaker than today — keeping C1 and C3 ADJACENT (C1
   then immediately C3) minimizes that window. The full battery is green at both
   C1 and C3 (the e2e legs still assert exit-0 + banner + verdict at C1; C3 adds
   back the wiring invariant), so no intermediate commit is broken — but the
   wiring-proof completeness argument requires C3 to follow C1 promptly.

3. **C2 AFTER C3 (hard, restated) — born-guarded workflow.** Wiring the
   confirmed-KEEP tests as plain sequential steps in C3 means C3's generalized
   Check 42 is GREEN over the full wired set BEFORE C2 reshapes the job into a
   matrix. C2's dynamic partition then picks up the newly-wired tests
   automatically (it reads the wired list). This is the architect §8 Option (i),
   chosen over merging C2+C3 because it gives review granularity and a clean
   worktree-isolation partition (§4). The alternative (C2+C3 as one commit) is
   acceptable per the architect but is NOT chosen here.

4. **C4 LAST (soft — independence).** C4 (project-side doc) depends on nothing in
   C1/C2/C3 and nothing depends on it. It is sequenced last for tidiness (the
   pack-only mechanism lands and is proven before the client-facing note that
   describes the general technique). It could land anytime; last is cleanest for
   review framing. C4 could equally be authored in PARALLEL with the pack-only
   work (see §4).

**Every intermediate state is working / CI-green:**
- After C1: full battery green; `--only-check` available; full no-flag run still
  runs all checks; the wiring proof is temporarily an implicit-gap (restored by
  C3) but no test fails.
- After C3: full battery green (grown by KEEP tests + guard tests); generalized
  Check 42 green; coverage assertable; registry/full-run guards green; wiring
  proof restored.
- After C2: full battery green; the `tests` job is sharded; coverage re-asserted
  at run time; wall-time reduced.
- After C4: full battery green; client doc shipped.

---

## 4. WORKTREE-ISOLATION TRIAL PARTITION NOTE (coder phase)

The coder phase will trial Claude Code worktree isolation (parallel isolated
coders authoring disjoint file-sets). The safe partition for parallelism, by
file-set disjointness:

- **C1 and C3 are NOT safely parallel.** Both edit `scripts/validate-pack.py` in
  overlapping regions: C1 refactors `main()` into `CHECK_REGISTRY` + adds
  argparse + strips the reserved-54 comments; C3 generalizes Check 42 and ADDS
  new checks (which must register in the same `CHECK_REGISTRY` C1 builds) + edits
  `main()`'s registry. Two isolated coders editing the same file's `main()` would
  produce conflicting patches and a broken registry. **Sequence C1 then C3 on
  `validate-pack.py`.** (This also matches the hard ordering dependency in §3.)
- **C4 is disjoint from C1/C2/C3.** C4 touches ONLY
  `project-template/docs/pack/OPTIONAL-FEATURES.md` (+ a manifest check that is
  expected empty). No pack-only commit touches that file. **C4 can be authored by
  a parallel isolated coder concurrently with the C1→C3 sequence.**
- **C2 is file-disjoint from C1/C3** (C2 = `.github/workflows/validate-pack.yml`
  only; C1/C3's yml edits in C3 are sequential steps, but C2 OWNS the matrix
  restructure of the same file). BUT C2 has a hard ORDERING dependency on C3
  (imports `ci-shard-plan.py` — §3). So even though C2's files are disjoint from
  C1's `validate-pack.py`, C2 CANNOT run before C3 lands. C2 is therefore NOT
  parallelizable with C3 (ordering forbids it), and is best authored AFTER C3.

**Cleanest safe parallel split (per architect §8):**
`{C1 → C3 sequential on validate-pack.py + scripts/}` ‖ `{C4 on OPTIONAL-FEATURES.md}`;
then **C2 lands after C3** (sequential, non-parallel due to the import-ordering
dependency).

**Ordering that FORBIDS parallelism (flagged):** C1‖C3 (same file region), C2‖C3
and C2‖C1 (C2 needs C3's module first). Only C4 is freely parallel.

---

## 5. CROSS-DOC CONSISTENCY CHECK

**Commit set — AGREE.** BD-219 names two levers + the upkeep guard + the
project-side note + the 3 reserved-comment strips. The architect §8 decomposes
into C1/C2/C3 (pack-only) + C4 (project-only). This plan keeps the SAME four
commits and the SAME C1→C3→C2→C4 order. No commit added, dropped, or re-scoped.

**Lever decisions — AGREE.** Matrix-shard (4 shards, dynamic matrix, generated
partition, `fail-fast:false`, `tests-result` aggregator) = design §2.
`--only-check` KEEP (greenfield argparse, registry refactor, e2e-leg adoption
without weakening) = design §3. Generalized Check 42 + measured allowlist =
design §4/§6. Project-side doc-only, separate `project-only` commit = design §7.
Candidate E OUT → BD-220 (verified Deferred, v11.1, Candidate-E anchor —
§EE-P-BD220). The plan adds NO long-pole-test refactor; C3 only POPULATES
`ci-shard-weights.tsv` with measured values.

**Check/guard numbers — COVERED, coder-confirmed-at-wire-time:**
- Highest wired check today is **57** (yml line 227 wires Check 57; the highest
  numbered run_check label — §EE-P8). Check 54 IS implemented + wired (yml line
  230), so the "reserved" comments are stale (C1 strips them).
- The NEW C3 checks (shard-coverage validate-pack mirror; full-job-no-flag;
  registry-completeness) get the **next available numbers after 57 → expected
  58, 59, 60** in author order. **These are EXPECTED numbers, NOT hard-coded:**
  the coder MUST read the current highest check number at wire time and assign
  the next contiguous integers, because numbers drift between this plan and
  implementation. (Generalized Check 42 keeps number 42.)
- The registry-completeness guard's `expected_count` constant is **57 at HEAD**
  but MUST be set to the FINAL registry length after C1+C3 add their checks
  (57 + the count of net-new run_check entries). **Coder computes the actual
  final count; never hard-codes 57.** This is the single most drift-prone
  constant in the BD — flagged for both the coder PREFLIGHT and the reviewer.

**Acceptance criteria — MAPPED:**
| BD-219 acceptance criterion | Where satisfied |
|---|---|
| Measurable `tests`-job wall-time reduction (before/after) | C2 verification (record ~462 s → ~140–160 s) |
| COMPLETE check set still runs in `validate` job (no check dropped) | C1 full-job-runs-all proof + C3 full-job-no-flag guard + registry-completeness guard |
| COMPLETE wired test list still runs, sharded, none silently dropped; a guard proves every test lands in exactly one shard | C3 generalized Check 42 + `ci-shard-plan.py --assert-coverage`; C2 run-time aggregator `--assert-coverage` |
| per-check tests using `--only-check` still catch their check's regressions (mutation-proven) | C1 round-trip mutation proof |
| full CI battery green | every commit's §1.2 full-battery verification |
| `ci-check-runtime-compounding` per-check runtime guards remain | §1.3 + C3 runtime-cost proof (six guards preserved, §EE-P9) |
| strip 3 stale "Check 54 reserved" comments | C1 (located by grep, lines 9549/9572/9587 at HEAD) |
| project-side boundary-compliant doc | C4 (boundary-leak proof) |

**No contradictions found** between BD-219, the architecture doc, and this plan.

---

## EMPIRICAL-EVIDENCE BLOCKS

All measurements at HEAD `1f95b8eedd9fa21b7c9a824736648599c543bb2d`, branch
`v11-dev`, 2026-06-14.

### §EE-P1 — `tests` job is the long pole (~462 s); `validate` ~12–15 s, parallel
- **Claim:** wall-time = the `tests` job; the BEFORE figure for C2's reduction is
  ~462 s sequential.
- **Evidence:** RE-USED from RESEARCH §1.1/§1.2 (run 27512425188 = validate 15 s
  / tests 464 s; Σ per-step ≈ 462 s) and ARCHITECTURE §EE-1, both at this HEAD.
  Independently confirmed the two jobs are siblings with no `needs:` between
  them: `grep -nE '^  [a-z…]:' .github/workflows/validate-pack.yml` →
  `85:  validate:` and `106:  tests:` (both top-level under `jobs:`; verified by
  reading lines 84–116 — neither lists the other in `needs:`).
- **Interpretation:** sharding the tests job is the only wall-time lever; C2's
  before/after is ~462 s → ~140–160 s.
- **Conclusion: SUPPORTED.**

### §EE-P2 — `validate-pack.py` has NO argparse (greenfield for `--only-check`)
- **Claim:** `--only-check` is a greenfield addition.
- **Command + output:** `grep -cE 'import argparse|add_argument|ArgumentParser' scripts/validate-pack.py` → `0`.
- **Interpretation:** C1 adds argparse cleanly; no existing arg handling to
  refactor.
- **Conclusion: SUPPORTED.**

### §EE-P3 — 70 disk / 61 wired / 23 per-check / 9 unwired
- **Claim:** the upkeep MEASURE step counts.
- **Command + output:**
  `ls scripts/test*.sh scripts/tests/*.sh | wc -l` → `70`;
  `grep -E '^\s+run: bash ' .github/workflows/validate-pack.yml | awk '{print $3}' | grep -v build.sh | sort -u | wc -l` → `61`;
  `ls scripts/tests/test-validate-pack-check*.sh | wc -l` → `23`;
  `comm -23 <(ls scripts/test*.sh scripts/tests/*.sh | sort -u) <(…wired list…)` →
  the 9 unwired: `test-compare-agent-trinity.sh`, `test-dry-run-migration.sh`,
  `test-restore-from-backup.sh`, `test-activate-capability.sh`,
  `test-add-capability.sh`, `test-tracker-promote-direct.sh`,
  `test-tracker-promote-path1.sh`, `test-tracker-promote-path2.sh`,
  `tracker-bd204-lossless-roundtrip-test.sh`.
- **Interpretation:** matches RESEARCH §1.3 and ARCHITECTURE §EE-3 exactly; the
  9 unwired need KEEP/STRIP categorization in C3.
- **Conclusion: SUPPORTED.**

### §EE-P4 — `def main` at 9338; `if __name__` at 9621 (module-import path intact)
- **Claim:** argparse goes inside `main()`/`__main__`; the import path is
  preserved by the `__main__` guard.
- **Command + output:** `grep -nE '^def main' scripts/validate-pack.py` →
  `9338:def main() -> None:`; `grep -n 'if __name__' scripts/validate-pack.py` →
  `9621:if __name__ == "__main__":`.
- **Interpretation:** per-check tests `spec_from_file_location` import without
  running `main()`; C1's argparse must live inside the guard/`main()`.
- **Conclusion: SUPPORTED.**

### §EE-P5 — 57 `run_check` callsites in `main()` (registry size at HEAD)
- **Claim:** the full run executes 57 checks; the registry-completeness
  expected_count base is 57.
- **Command + output:**
  `awk '/^def main/,/^if __name__/' scripts/validate-pack.py | grep -cE 'run_check\('` → `57`.
- **Interpretation:** C1's `CHECK_REGISTRY` holds 57 entries at HEAD; C3's
  expected_count is 57 PLUS the net-new checks C1+C3 add (coder computes final).
- **Conclusion: SUPPORTED.**

### §EE-P6 — per-check e2e leg ~1.2–1.6 s (sample checks 52/43/40)
- **Claim:** the `--only-check` round-trip mutation proof targets exist and the
  saving is real.
- **Evidence:** RE-USED from ARCHITECTURE §EE-6 / RESEARCH §1.4 (measured at this
  HEAD): `test-validate-pack-check-52.sh` ≈ 1.29 s, `-43` ≈ 1.52 s, `-40` ≈
  1.59 s; the general validator alone ≈ 1.26–1.39 s. (Not re-timed by the planner
  — these are runtime measurements, not source-state claims; the source files
  exist: `ls scripts/tests/test-validate-pack-check-{52,43,40}.sh` present in the
  23 per-check set §EE-P3.)
- **Interpretation:** C1's mutation proof uses these three as the sample.
- **Conclusion: SUPPORTED (timings re-used; file existence verified).**

### §EE-P7 — `--only-check` greenfield + import path preserved (composite)
- **Claim:** combines §EE-P2 + §EE-P4.
- **Conclusion: SUPPORTED** (see §EE-P2, §EE-P4).

### §EE-P8 — highest wired check = 57; new checks number from 58
- **Claim:** new C3 checks get 58/59/60 (coder-confirmed).
- **Command + output:** the yml wires checks up to Check 57
  (`grep -nE 'validate-pack Check 5[0-9]' .github/workflows/validate-pack.yml`
  shows Check 49/50/51/52/53/56/55/57/54 steps; the highest NUMBER wired is 57 at
  line 227). The validate-pack invocations in the workflow:
  `grep -nE 'validate-pack\.py' .github/workflows/validate-pack.yml` →
  `97: python3 scripts/validate-pack.py` (general, no flag) +
  `104: PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` (deep, no
  selector). So the `validate` job carries NO `--only-check` today — the C3
  full-job-no-flag guard's baseline is already satisfied.
- **Interpretation:** next available is 58; C3 assigns 58/59/60 in author order,
  coder-confirmed at wire time (numbers drift).
- **Conclusion: SUPPORTED.**

### §EE-P9 — six runtime guards exist (must be preserved)
- **Claim:** the `ci-check-runtime-compounding` guards are preserved.
- **Evidence:** RE-USED from ARCHITECTURE §EE-9 / RESEARCH §1.6 at this HEAD:
  `RUN_CHECK_PER_CHECK_WARN_BUDGET_S=2.0` (line 448),
  `…TOTAL_GENERAL…=10.0` (449), `…TOTAL_DEEP…=35.0` (450),
  `…DEEP_FAITHFULNESS…=30.0` (457), `def run_check` (463), the deep ENV-gate
  (`PACK_VALIDATE_DEEP=1`, yml line 104). The planner verified `run_check` exists
  at line 463 and the general/deep invocations at yml 97/104 (§EE-P8).
- **Interpretation:** §1.3 contract preserves all six; total-run suppressed only
  in single-check mode.
- **Conclusion: SUPPORTED.**

### §EE-P10 — 3 stale "Check 54 reserved" comments at 9549/9572/9587
- **Claim:** the C1 cosmetic strip targets exist.
- **Command + output:** `grep -niE 'reserved' scripts/validate-pack.py | grep -E '54'` →
  `9549:    # tokens). Check number 54 — reserved for Guard-A′ across the prior BD-197`;
  `9572:    # after 52/53/56; 54 is reserved for the C8b Guard-A′ — a non-contiguous`;
  `9587:    # Check number 57 (next available after 52/53/55/56; 54 is reserved for`.
  Check 54 is wired: `.github/workflows/validate-pack.yml` line 230
  (`validate-pack Check 54 tests (BD-197 C8b, OPTIONAL-FEATURES presence-check Guard-A′)`).
- **Interpretation:** three sites confirmed; located by `reserved`-grep (not line
  number — they drift); C1 strips the stale "reserved" assertion from each.
- **Conclusion: SUPPORTED.**

### §EE-P-BD220 — Candidate E is OUT of BD-219, anchored as BD-220 (Deferred, v11.1)
- **Claim:** the plan adds no long-pole-test refactor; Candidate E is BD-220.
- **Command + output:** `ls backlog/BD-220.md` → present. Read: `Status: Deferred`,
  `Target: v11.1 (user 2026-06-15) — scheduled at the END of v11.1`, title
  "Refactor the CI long-pole tests internally to lower the shard floor", explicit
  "the 'candidate E' optimization surfaced (and deliberately NOT absorbed) by the
  BD-219 architect", `Out of scope: the matrix-shard orchestration … (BD-219);
  validate-pack --only-check (BD-219)`.
- **Interpretation:** C3 only POPULATES `ci-shard-weights.tsv` with measured
  values; no test-internal refactor in BD-219.
- **Conclusion: SUPPORTED.**

### §EE-P-BP — branch protection NOT enabled (rename hazard MOOT)
- **Claim:** the architect's required-check rename hazard + paired admin action
  do not apply.
- **Evidence:** ESTABLISHED FACT supplied by the caller (verified 2026-06-15:
  Free plan + private repo; required status checks are a Pro/public feature). The
  planner did not (and as RO cannot) mutate or independently re-read live
  branch-protection config; this is taken as a given per the caller's directive.
  Consistent with RESEARCH §2.3 ("the actual rule config was not inspected … flagged
  for the architect to confirm whether a rule is live").
- **Interpretation:** keep `tests-result` (good practice); drop the
  branch-protection coordination step from C2. PARTIAL self-verification (relies
  on caller-supplied fact, not a planner command — appropriately, since it is a
  live-admin-surface fact outside the RO read surface).
- **Conclusion: SUPPORTED (caller-established; no contradicting repo evidence).**

---

## RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted / measured) | Conclusion |
|---|---|---|
| **empirical-evidence-blocks** | §EE-P1…§EE-P10 + §EE-P-BD220 + §EE-P-BP: every load-bearing state-claim (job long-pole, 0 argparse, 70/61/23/9 inventory, main@9338 / __main__@9621, 57 run_check, e2e-leg timings, highest-check 57, six guards, 3 reserved-54 comments @9549/9572/9587, BD-220 Deferred, branch-protection moot) carries command + verbatim output (or sourced re-use) + HEAD `1f95b8e` + date 2026-06-14 + interpretation + SUPPORTED/PARTIAL conclusion. | COMPLIANT |
| **verify-full-ci-suite** | §1.2 binds EVERY commit to run general + deep validate-pack + EVERY wired `run: bash` script in the yml `tests` job (quoting each exit), NOT a sample; §1.2 item 4 + C1/C3 verification require enumerate-encoding-surfaces sweeps of `scripts/tests/` (unit AND integration) for output assertions; C2 verification names the post-push `gh run` backstop as secondary, not the first detector. | COMPLIANT |
| **regenerate-manifest-v11-surface** | §1.1 + per-commit "Manifest regen" rows: C1 YES (scripts/), C3 YES (scripts/), C2 NO (yml-only unless scripts/ co-changes), C4 run+check (project-template/ is v11-surface; expected-empty → not staged, with a STOP-and-surface if unexpectedly non-empty to protect the project-only keyword). Each names `bash test-fixtures/build.sh --all --clean` + `git status --short test-fixtures/manifest.txt` + stage-iff-non-empty. | COMPLIANT |
| **commit-subject-keyword-token-trap** | §1.4 + per-commit "Scope keyword": C1/C2/C3 = `pack-only` (subject MUST contain no `project-only`/`pack-chat-only` token); C4 = `project-only` (no `pack-only`/`pack-chat-only` token); other-scope content described with non-keyword vocabulary ("client-facing"/"project-native"); re-run validate-pack AFTER the commit exists (Check 36 is post-commit). | COMPLIANT |
| **ci-guard-design-measure-then-bound** | §EE-P3 MEASURES the 70/61/9 set; C3 "CRITICAL measure-then-bound step" requires the coder to CONFIRM each of the 9 unwired KEEP/STRIP by opening the header, size the allowlist to EXACTLY the confirmed STRIP set (never "allowlist all 9 to go green"), and run-each-KEEP-green-BEFORE-wiring + surface a failing KEEP test as a separate finding rather than allowlist it. C3 verification proves Check 42 FAILs on an unwired KEEP and on allowlist staleness. | COMPLIANT |
| **ci-check-runtime-compounding** | §1.3 + C3 runtime-cost proof: every new/generalized check is glob+regex over the yml + a dir listing + two small files (no subprocess-per-script, no hardcoded real-tree scan), routes through `run_check` (2.0 s WARN); the heavier `--assert-coverage` lives in the aggregation JOB (once/run), not the ~24-spawn battery; the six existing guards (§EE-P9) preserved; total-run suppressed only in single-check mode. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Plan covers exactly BD-219's deliverables (the 4 commits + the 3 reserved-comment strips + the per-commit verification + dependency order + worktree partition + cross-doc check). Candidate E stays BD-220 (§EE-P-BD220); the plan adds NO long-pole-test refactor (C3 only populates the weights tsv). No invented files/conventions; no over-built scope. | COMPLIANT |
| **agents-never-commit** | Only read-only git verbs used: `git rev-parse HEAD`, `git branch --show-current`, `git status` (none run as a state change). No add/commit/push/checkout/restore/etc. Single write = this plan doc at `maintenance-docs/v11-implementation/PLAN-BD-219-CI-RUNTIME-OPTIMIZATION.md`. No source file edited. | COMPLIANT |
| **rules-applied-verification-block** | This table — per-rule, quoted/measured evidence, terminal COMPLIANT conclusion; no empty evidence; no AMBIGUOUS. | COMPLIANT |
