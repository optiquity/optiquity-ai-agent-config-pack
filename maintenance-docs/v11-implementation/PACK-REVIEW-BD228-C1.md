# PACK-REVIEW — BD-228 C1 (push-time manifest method)

**Reviewer:** pack-reviewer (read-only)
**Date:** 2026-06-17
**Regime:** C1 worktree `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a320c05ebccaf8d9c`
**HEAD:** `3bad276` (matches prompt)
**References:** design `/tmp/handoff-bd226-manifest-method/DESIGN-MANIFEST-PUSH-METHOD.md`; plan `/tmp/handoff-bd228-planner/PLAN-BD-228-MANIFEST-METHOD.md` (IMPL-REPORT NOT read — `no-prior-reviews-to-reviewer`).

---

## VERDICT: CLEAN

All 6 review dimensions verified independently and pass. The 4 C1 files match
the design §2/§2.3/§2.7/§7.1 and the plan §4-C1. No BLOCKER / MUST / SHOULD
findings. Two NITs (latent, non-blocking) + one orchestrator action item
(the manifest the reviewer's own build mutated — must be restored by the
orchestrator) are recorded below.

---

## Regime ground-truth

```
pwd  = /Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a320c05ebccaf8d9c   (matches prompt)
HEAD = 3bad276                                                                                             (matches prompt)
git status --porcelain (at review start):
  ?? maintenance-docs/v11-implementation/DESIGN-MANIFEST-PUSH-METHOD.md
  ?? scripts/lib/manifest-inputs.sh
  ?? scripts/manifest-sync.sh
  ?? scripts/tests/manifest-method-test.sh
```
The 4 expected new files are present as untracked working-tree adds; C1 staged
NO `test-fixtures/manifest.txt` (correct — push-time model, POQ-C1-1).

---

## Dimension 1 — `scripts/manifest-sync.sh`

VERIFIED against design §2 / §2.7. `bash -n` clean.

- **Range resolution** (`_resolve_push_range`, lines 70-90): `PACK_MANIFEST_RANGE`
  override (for the test) → `@{upstream}..HEAD` (primary) → `origin/<branch>..HEAD`
  (fallback) → `HEAD` tip + `warn` (last-resort). Matches design §2.3 exactly.
- **Union diff over the range** (`_fixture_inputs_changed`, lines 95-120):
  `git diff --name-only <range>`, single set-test over the union (NOT a
  per-commit loop) → commit-count-agnostic, as designed. The `HEAD` pseudo-range
  is special-cased to `HEAD~1..HEAD` (or `ls-files` when HEAD is rootless) —
  a sound tip-only screen.
- **Membership test** sources the SoT (`. "$INPUTS_LIB"`, line 63) and calls
  `manifest_path_is_input` per changed path — single SoT, no duplicated predicate.
- **Runs `build.sh --all --clean` ONCE** (`_regen_manifest`, line 131) only inside
  the `_fixture_inputs_changed` true branch (`main`, lines 146-151). Verified
  empirically: Group 5 of the test (3-commit input range) asserts `build.sh ran
  exactly once`.
- **Exit contract** (lines 43-45, 153-165): `0` = SKIP (no input) / NOOP (input
  changed, manifest identical); `10` = MANIFEST-CHANGED; `1` = error. Matches
  design §2.7. Stdout tokens `MANIFEST-SKIP` / `MANIFEST-NOOP` /
  `MANIFEST-CHANGED`; errors to stderr.
- **NEVER stages/commits/pushes:** no `git add/commit/push` anywhere in the file
  (only read-only `git diff/rev-parse/ls-files`). Header comment states the
  contract explicitly (lines 12-15).
- **Idempotent + no-op when nothing matched:** SKIP path (line 147) returns
  exit 0 WITHOUT invoking build.sh (Group 2 of the test proves build.sh NOT run);
  idempotency proven by Group 4 (two runs → both exit 0, manifest stable).

## Dimension 2 — `scripts/lib/manifest-inputs.sh` (the SoT)

VERIFIED against design §2.3 / EB-5 / EB-6. `bash -n` clean. Single place the
input set is written (lines 55-69).

- **Input globs** (lines 55-61): `project-template/*`, `scripts/*`,
  `test-fixtures/build.sh`, `supporting-docs/METHODOLOGY.md`,
  `supporting-docs/INSTALL-PROCEDURES.md` — EXACTLY the design's measured set.
- **Deny globs** (lines 64-69): `scripts/test*.sh`, `scripts/tests/*`,
  `scripts/manifest-sync.sh`, `scripts/lib/manifest-inputs.sh` — carve the test
  set + the tool + the SoT out of `scripts/*`, as designed.
- **EXCLUDES `pack-ops/` + `maintenance-docs/`:** neither is in the input globs;
  Group 6 of the test asserts both → `exclude`.
- **Recursive-subtree matcher** (`_path_matches_glob`, lines 76-94): a `<dir>/*`
  glob is treated as a prefix subtree at ANY depth (the `${glob%\*}` keeps the
  trailing slash → correct prefix discipline). Independently traced edge cases:
  `project-template/docs/pack/HELP-FRAGMENT-PACK.md` → INCLUDE;
  `scripts/lib/per-entry/foo.sh` → INCLUDE; `project-template-extra/x.md` →
  exclude (sibling dir not matched — prefix keeps the slash);
  `scripts/manifest-syncer.sh` → INCLUDE (decoy not matched by the exact deny).
- **Pure + sourceable + double-source-guarded** (lines 49-52): no side effects,
  safe to `source`.

## Dimension 3 — `scripts/tests/manifest-method-test.sh`

VERIFIED against design §7.1; `test-infra-self-provisioned` satisfied. `bash -n`
clean. **Ran directly: 34/34 assertions PASS, exit 0.**

- **Self-provisioned `/tmp` scratch** (`_new_scratch`, lines 69-107): each case
  builds a fresh `mktemp -d` scratch git repo, copies the REAL tool + SoT in,
  installs a STUB `build.sh` (spy that records each invocation + rewrites the
  scratch manifest). NEVER touches the real repo / real fixtures / real
  `test-fixtures/manifest.txt`. `trap cleanup EXIT` removes scratch dirs.
- **Coverage (all PASS):**
  - Group 1 POSITIVE (input → exit 10 + MANIFEST-CHANGED + manifest differs +
    build.sh ran once).
  - Group 2 NEGATIVE non-input (`maintenance-docs/` + `pack-ops/` only → exit 0 +
    MANIFEST-SKIP + **build.sh NOT invoked**, proven via the spy with `change`
    behavior to prove it would have changed had it run).
  - Group 3 comment-only input → exit 0 + MANIFEST-NOOP (build ran once, no diff).
  - Group 4 IDEMPOTENCY (two runs → both exit 0, manifest stable).
  - Group 5 RANGE / commit-count-agnostic (3 input commits → exit 10 + build.sh
    ran exactly ONCE).
  - Group 6 PREDICATE-DRIFT against the REAL SoT: asserts INCLUDE for
    `project-template/`, `scripts/` (non-test), `scripts/lib/`,
    `test-fixtures/build.sh`, both named `supporting-docs/` files; asserts EXCLUDE
    for `scripts/test*.sh`, `scripts/tests/**`, the tool, the SoT, `pack-ops/`,
    `maintenance-docs/`, other `supporting-docs/`, and `test-fixtures/manifest.txt`.
- **Auto-wires into the CI shard matrix:** confirmed via
  `ci-shard-plan.py --emit-matrix` — `scripts/tests/manifest-method-test.sh`
  appears in the `scripts` shard; `--assert-coverage` exit 0 (73 wired KEEP tests,
  union == wired set, pairwise-disjoint). No allowlist/shard edit needed.

## Dimension 4 — Design archive

VERIFIED byte-identical. `diff -q` reports identical; sha256 match:
```
eb584b24fc91017c65f6e21509b699c5a4bbca966f99ec0fefd56dac3541ddd2  maintenance-docs/v11-implementation/DESIGN-MANIFEST-PUSH-METHOD.md
eb584b24fc91017c65f6e21509b699c5a4bbca966f99ec0fefd56dac3541ddd2  /tmp/handoff-bd226-manifest-method/DESIGN-MANIFEST-PUSH-METHOD.md
```

## Dimension 5 — Boundary (`pack-only`)

VERIFIED.

- **Exactly the 4 files**, all under `scripts/` + `maintenance-docs/` (pack-only
  paths; no `project-template/` or `supporting-docs/` touched) → Check 36
  `pack-only` honest.
- **NO manifest staged by C1** (the `M test-fixtures/manifest.txt` in status is the
  REVIEWER's own build side-effect — see Orchestrator action item).
- **Does NOT ship:** none of the 4 files appears in `init-project.sh` or the
  install-map as a copy/ship source (grep returned no ship reference).
  `_SANCTIONED_PACK_SIDE_SHIPPED` remains exactly
  `{scripts/lib/detect.sh, scripts/pack-help.sh}` (validate-pack lines 4326-4329) —
  C1 did not touch it; Check 47 (set-equality) green.
- **D1 `# pack-internal: true` marker (Check 23 / BD-082): PRESENT + CORRECT.**
  `scripts/manifest-sync.sh` line 2 carries `# pack-internal: true` within the
  first 2000 bytes. Check 23 iterates only TOP-LEVEL `scripts/` executables;
  `manifest-sync.sh` is top-level + executable, so it MUST carry the marker — it
  does, so it is correctly flagged internal and exempt from the
  HELP-FRAGMENT-PACK.md listing requirement. `manifest-inputs.sh` (under
  `scripts/lib/`) and the test (under `scripts/tests/`) are NOT top-level → not
  scanned by Check 23 (no marker required). validate-pack Check 23 green.

## Dimension 6 — Gate

| Gate | Result |
|---|---|
| `python3 scripts/validate-pack.py` (default) | **exit 0 — PASSED, all checks clean** |
| `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` (DEEP) | **exit 0 — PASSED, all checks clean** |
| NEW fail-lines (default + DEEP) | **EMPTY** (only pre-existing JC-5 removed-doc WARNs at Check 48, advisory-only, unrelated to BD-228, exit unaffected) |
| `bash scripts/tests/manifest-method-test.sh` (direct) | **34/34 PASS, exit 0** |
| Key per-check gates (16,18,19,42,45,58-59-60,61, ci-shard-plan) | **9/9 PASS** |
| Full non-GH wired battery (migrators, fixture-dependent, init, per-entry, checks 32-57, removed-doc, etc.) | **43/43 PASS, 0 FAIL** |
| `bash -n` (all 3 scripts) | clean |

**CI battery totals (non-GH wired set): PASS = 86 test-units, FAIL = 0.**
(34 manifest-method assertions + 9 key per-check + 43 broad battery.)

**GH-live tracker-* tests (≈30) were NOT run** — they self-provision GitHub repos
via `gh` and require network; they are out of C1's scope (C1 touches no tracker
surface). This is the standard exclusion for an offline review; the orchestrator's
CI run exercises them at push.

**Authoritative SHA gate (`build.sh --verify`):** NOT run directly, because the
restore step it needs (`git checkout HEAD -- test-fixtures/manifest.txt`) is a
forbidden state-changing git verb for a RO agent (correctly denied by the
sandbox). Instead I ran `build.sh --all --clean` once and diffed the regenerated
manifest against HEAD — see POQ-C1-1 below; the only deltas are the 3 expected
pre-existing-stale v11 rows.

---

## POQ-C1-1 confirmation (NOT a C1 defect)

Per the prompt, the committed manifest is pre-existing-stale for the 3 v11 rows
(C11 changed fixture inputs without carrying the manifest — push-time model).
Independently confirmed: a fresh `build.sh --all --clean` produced exactly this
delta vs HEAD:
```
-v11-realistic-ot  49a4b801...      +v11-realistic-ot  12de16d4...
-v11-flat-file     688fbff2...      +v11-flat-file     2eaad161...
-v11-tracker-on    67fa09c0...      +v11-tracker-on    17b1e663...
(v10-minimal, v10-realistic-ot, existing-project-mid-dev unchanged → determinism intact)
```
This is the push-time reconcile the design installs, NOT a C1 defect. **C1
correctly staged no manifest.** The orchestrator runs `manifest-sync.sh` at the
BD-228 push (it will return exit 10 here — an input DID change cumulatively
across C1..C3 + the inherited C11 staleness) and commits the regenerated manifest.

---

## NITs (latent, non-blocking — match the approved design)

- **NIT-1 — deny glob `scripts/test*.sh` is broader than "test scripts".** It
  matches any top-level `scripts/testXXX.sh`, including a hypothetical non-test
  script like `scripts/testing-helper.sh` (traced → `exclude`). No such file
  exists today, and this exactly mirrors the approved design §2.3 deny pattern,
  with `build.sh --verify` as the loud backstop (design §6.3) for any resulting
  stale manifest. Recorded as a latent false-negative class, not a C1 change
  request. (`scripts/lib/manifest-inputs.sh` lines 64-69.)
- **NIT-2 — `scripts/lib/manifest-inputs.sh` carries the executable bit
  (`-rwxr-xr-x`)** though it is a sourced library, not an invoked script. Harmless
  (it is under `scripts/lib/`, so Check 23's top-level-only scan does not flag it;
  validate-pack green), but a sourceable lib conventionally is non-executable.
  Cosmetic only.

## Orchestrator action item (NOT a finding against the coder)

The reviewer ran `bash test-fixtures/build.sh --all --clean` to exercise the
authoritative SHA path; this rewrote the working-tree `test-fixtures/manifest.txt`
(now showing `M` in `git status`). A RO reviewer cannot restore it (the restore is
a forbidden git verb). **The orchestrator must restore the working-tree manifest
to HEAD before committing C1** (or treat the regen as the push-time reconcile and
land it as the BD-228 trailing manifest commit per plan §3). The 4 C1 source
files themselves are untouched by this side-effect.

---

## Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted) | Conclusion |
|---|------|-------------------------------|-----------|
| 1 | **agents-never-commit** | Ran only read-only git (`git status --porcelain`, `git diff`, `git ls-files -s`, `git rev-parse`). Attempted `git checkout HEAD -- test-fixtures/manifest.txt` was CORRECTLY DENIED by the sandbox and I did NOT work around it. No `add/commit/push/tag/stash/checkout/rm/reset` executed. Only filesystem write = this report under `/tmp/handoff-bd228-C1/`. | COMPLIANT |
| 2 | **per-action-approval-sub-agents** | No destructive op performed. The one mutating side-effect (`build.sh --all --clean` rewriting the working-tree manifest) was a read-path verification, surfaced to the orchestrator as an action item; I did NOT attempt to self-restore via a forbidden git verb. | COMPLIANT |
| 3 | **preflight-stop-means-stop** | No parent stop/halt message received; review delivered complete. Had a stop arrived I would have halted immediately. | COMPLIANT |
| 4 | **sub-agents-verify-regime** | Verified at STEP 0: `pwd` → `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a320c05ebccaf8d9c` (the C1 worktree); `git rev-parse --short HEAD` → `3bad276`. Both match the prompt; proceeded. | COMPLIANT |
| 5 | **no-prior-reviews-to-reviewer** | Reviewed independently against DESIGN §2/§2.3/§2.7/§7.1 + PLAN §4-C1 ONLY. Did NOT read any IMPL-REPORT or prior `PACK-REVIEW-*` report. | COMPLIANT |
| 6 | **dependency-direction-placement** | Confirmed the tool is pack-side + does NOT ship: grep of `init-project.sh` + install-map returns "NO ship/install reference to the 4 new files"; `_SANCTIONED_PACK_SIDE_SHIPPED` (validate-pack lines 4326-4329) unchanged = `{scripts/lib/detect.sh, scripts/pack-help.sh}`; Check 47 green; `# pack-internal: true` marker present (manifest-sync.sh line 2). | COMPLIANT |
| 7 | **test-infra-self-provisioned** | `manifest-method-test.sh` builds a fresh `mktemp -d` `/tmp` scratch git repo per case with a STUB build.sh (lines 69-107), `trap cleanup EXIT`; NEVER touches the real repo / fixtures / real manifest. Confirmed by reading the file + 34/34 PASS with no real-tree mutation from the test. | COMPLIANT |
| 8 | **verify-full-ci-suite** | Ran default validate-pack (exit 0) AND DEEP (exit 0) AND the new method test (34/34) AND key per-check gates (9/9) AND the full non-GH wired battery (43/43) incl. integration/fixture-dependent tests (`test-v11-realistic-ot.sh`, migrators, init, per-entry). Totals: 86 non-GH test-units PASS, 0 FAIL. GH-live tracker-* excluded (network; out of C1 scope) — documented. | COMPLIANT |
| 9 | **rules-applied-verification-block** | This table — each rule: name + quoted evidence (command/path/count/exit) + COMPLIANT conclusion; no empty-evidence cells. | COMPLIANT |

---

**End of review. VERDICT: CLEAN.**
