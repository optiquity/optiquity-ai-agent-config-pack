# PACK-REVIEW-BD-115-BD-119 — review of Batch 8a

**Reviewer:** pack-reviewer
**Date:** 2026-05-08
**Scope:** BD-115 (existing-project-mid-dev fixture) + BD-119 (general
N→N+1 migrator framework, commits 6286fcf..d2cd9b4 inclusive).
**Authoritative inputs:** ARCHITECTURE-BD-119.md, PLAN-BD-119.md,
BACKLOG.md (BD-115/BD-119 entries). Per-commit IMPLEMENTATION-REPORT
files in this directory were deliberately NOT read.

---

## 1. Summary verdict

**Pass-with-fixes (BD-119 has 1 BLOCKER and several SHOULD-FIX);
BD-115 is pass-with-fixes (1 SHOULD-FIX).**

The framework lands faithfully against ARCHITECTURE/PLAN: the public
surface is correct and frozen, exit-code constants + synonym are
present, the trinity-parity validator works, the manifest TSV parser
covers the four declared verbs, and the behavior-preservation harness
passes 5/5 axes against both `v10-realistic-ot` and `v10-minimal`.
However:

1. **BLOCKER.** The C-6 adapter's `PACK="${PACK:-$(cd "$SCRIPT_DIR/.." && pwd)}"`
   auto-resolution silently changes a documented exit-code path. The
   pre-refactor monolith returned `EXIT_PACK_INVALID=10` when PACK was
   unset; the refactored adapter falls back to its own `..` and
   proceeds to a target-not-git failure (rc=11). This is provably a
   behavior regression — `scripts/tests/test-migrate-v10-to-v11.sh`
   case 1.3 fails on HEAD. PLAN §8 mandated behavior preservation as
   absolute; the harness missed it because the harness always sets
   PACK explicitly. Fix the adapter (do not auto-resolve PACK) and
   extend the harness to cover the 5 negative-leg exit codes named in
   PLAN §8.4.

2. **SHOULD-FIX.** The three new test scripts (`test-migrator-core.sh`,
   `test-migrator-manifest.sh`, `test-migrator-behavior-preservation.sh`)
   are NOT wired into `.github/workflows/validate-pack.yml`. PLAN T-12
   and T-14 explicitly required CI hookup, and the v11.0 CHANGELOG
   entry already claims they "all run on every push." They are not
   running on any push. Validate-pack Check 26 IS wired and is green.

3. **SHOULD-FIX.** CHANGELOG.md was modified at C-7 to add a Scope C
   block + a "Migrator-framework regression coverage" bullet that
   misstates current CI state ("all run on every push; validate-pack
   Check 26 lints adapter manifests" — Check 26 does NOT lint
   manifests, only the inventory). PLAN §2.3 explicitly forbade
   touching CHANGELOG.md mid-version; CLAUDE.md restates this.

4. **SHOULD-FIX.** Trinity wording for the "Migrator framework
   (BD-119)" bullet is not byte-identical across CLAUDE.md / AGENTS.md
   / GEMINI.md (CLAUDE/AGENTS: "+ the hook functions"; GEMINI: "+ hook
   functions"; one line break differs). PLAN §9.3 said "identical
   wording in all three." Trivial fix.

5. **SHOULD-FIX.** Behavior-preservation harness covers ONE fixture
   per invocation and zero negative-leg exit codes. PLAN §8.4 said
   "2 fixtures × 5 axes + 5 negative tests = 15 assertions."

BD-115's fixture is byte-deterministic and does what the user prompt
required; the only finding is that `bash test-fixtures/build.sh
--verify` warns ("not present locally") in CI rather than rebuilding,
which is a CI-side issue (BD-118 surface) — not a defect in BD-115's
deliverable.

---

## 2. BD-115 audit — PASS-with-fixes

Mapping the user-prompt criteria for BD-115:

| Criterion | Verdict | Evidence |
|---|---|---|
| `_build_existing_project_mid_dev` follows existing-builder pattern | PASS | `test-fixtures/build.sh:340-594` mirrors `_build_v10_minimal` shape: `_fixture_git_init` + per-commit `_fixture_commit_all` calls. Author / email / dates pinned via `FIXTURE_AUTHOR_NAME` / `FIXTURE_AUTHOR_EMAIL` / `FIXTURE_EPOCH`. |
| Deterministic (pinned author/email/dates per FIXTURE_EPOCH) | PASS | Build at HEAD produced SHA `a54e081a9e1d04f293bfb38fa0af77fd9f7f8619` (matches manifest.txt). |
| `--verify` passes | PASS | Verified locally; only caveat is the fixture must be built first (`bash test-fixtures/build.sh --name existing-project-mid-dev --clean`). |
| `--all --clean` produces byte-identical manifests across two runs | PASS (by inspection) | Determinism is structurally guaranteed by the env vars; SHA matches the committed manifest after a fresh build. |
| Fixture contains zero pack files | PASS | No `.claude/`, `.codex/`, `.gemini/`, `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, no `scripts/pack-*.sh` — only Swift package, Python service, proto, README, .gitignore. |
| ≥ 2 commits of project history | PASS | 3 commits: `scaffold...`, `feat: add proto contract...`, `wip: detail view model stub...`. Note: unlike `v10-minimal` / `v10-realistic-ot`, there is no leading "initial empty repo" seed commit — for this fixture's "real project" persona that's correct (a real project's first commit isn't empty). |
| Documented in `test-fixtures/README.md` | PASS | Row 5 of the fixtures table at `test-fixtures/README.md:32`. |
| Documented in pack-root `README.md` Repository Layout | PASS | `README.md:219`. |
| Trinity rule (CLAUDE/AGENTS/GEMINI) untouched by BD-115 | PASS | BD-115 commit `6286fcf` only touches `test-fixtures/` and `README.md`. |

**Single finding for BD-115 (SHOULD-FIX):**

- The fixture is gitignored; `bash test-fixtures/build.sh --verify`
  warns "built fixture not present locally" rather than auto-building.
  In a fresh-clone CI run (when BD-118 lands the workflow hookup) the
  verify step would fail-warn unless the workflow first runs
  `--all --clean`. This is properly BD-118 scope; BD-115 should land
  as Resolved.

---

## 3. BD-119 audit

### 3.1 Public-API surface lock (PASS)

All six function names are defined in `scripts/lib/migrator-core.sh`
and `bash -c 'type ...'` resolves each from a sourced subshell:

- `migrator_run` — line 314
- `migrator_dispatch` — line 328
- `migrator_detect_target_version` — line 340
- `migrator_select_adapter` — line 363
- `migrator_baseline_to_tmp` — line 419
- `migrator_target_surface_for_version` — line 454

Names did not change between C-2 → C-7 (auditable via `git log -p`
on `migrator-core.sh`). `test-migrator-core.sh` cases 2, 6, 7, 8, 11,
14 directly assert the names + arities. PASS.

### 3.2 Exit-code constants (PASS)

All eight `readonly`-declared at `migrator-core.sh:53-60` with the
correct numeric values per PLAN §3.5:

```
EXIT_PACK_INVALID=10  EXIT_NOT_GIT=11  EXIT_DIRTY=12
EXIT_NOT_BASELINE=13  EXIT_BASELINE_MISSING=14  EXIT_LIB_MISSING=15
EXIT_ALREADY_MIGRATED=16  EXIT_INTERNAL=99
```

`EXIT_NOT_V10=$EXIT_NOT_BASELINE` synonym at line 66. `test-migrator-core.sh`
case 1 asserts each value verbatim. PASS.

### 3.3 Adapter contract (PASS structurally; BLOCKER on PACK auto-resolve)

`scripts/migrate-v10-to-v11.sh:56-63` declares all five `MIGRATOR_*`
vars. `migrator_manifest`, `migrator_directory_sweeps`,
`migrator_relocations`, `migrator_artifact_installs`,
`migrator_post_report_hook` all defined. `migrator_run "$@"` invoked
at line 255.

**BLOCKER finding** — line 249:

```bash
PACK="${PACK:-$(cd "$SCRIPT_DIR/.." && pwd)}"
```

The pre-refactor monolith DID NOT auto-resolve PACK; it relied on the
preflight check to die with `EXIT_PACK_INVALID=10` when PACK was
unset. The new line silently substitutes the script's parent directory
when the user runs the migrator without PACK set, which:

- Breaks documented exit code 10 (the script's own header at
  `scripts/migrate-v10-to-v11.sh:46-47` still claims "Exit codes are
  inherited from the framework" with EXIT_PACK_INVALID=10).
- Causes `scripts/tests/test-migrate-v10-to-v11.sh` case 1.3 to fail
  on HEAD: `expected='10' got='11'`. (Verified: existing test suite
  shows 38 passed / 1 failed on HEAD.)
- Slipped past the behavior-preservation harness because the harness
  always exports PACK explicitly. PLAN §8.4 named EXIT_PACK_INVALID as
  one of the five required negative-leg tests; the harness does not
  implement them.

The adapter has a comment at line 247 ("`$PACK` is required by every
framework helper; resolve to the pack repo this script lives in if
the caller did not export it.") that is itself an architecture
violation: the architecture and PLAN both treat unset PACK as a fatal
preflight, not a recoverable default.

### 3.4 Stages + safety invariants (PASS)

`migrator-stages.sh` implements `_stage_preflight` (I1, I4, I8),
`_stage_backup` (I2), `_stage_libs`, `_stage_dispatch`,
`_stage_relocations`, `_stage_artifact_installs`, `_stage_report`.
`_migrator_run_stages` in core orders them per architecture §6 and
optionally invokes `migrator_pre_dispatch_hook` /
`migrator_post_dispatch_hook` between S2 and S3 / between S3 and S4.

I3 (always-dispatch via `customization_preserve`) is upheld in
`_manifest_dispatch_transform` and `_manifest_sweep_one_dir` — both
unconditionally invoke `customization_preserve` with empty-string
sentinels for absent-side files (`migrator-manifest.sh:285-296,
508-518`). M4 contract preserved.

I5 (trinity parity validator) runs at `_stage_dispatch` BEFORE the
`_manifest_iterate` loop (`migrator-stages.sh:228-249`); errors before
any mutation. `test-migrator-manifest.sh` cases 4, 5, 6 cover the
positive + missing-third + class-drift paths.

I8 (idempotency) at `migrator-stages.sh:131-135` exits
`EXIT_ALREADY_MIGRATED` when `dispositions.tsv` exists. Covered by
`test-migrator-manifest.sh` case 12. PASS.

### 3.5 Manifest verbs (PASS)

`migrator-manifest.sh:115-121` whitelists exactly
`transform | add | remove | relocate-from`; any other verb errors
with `EXIT_INTERNAL` and message `unknown manifest action`.
`test-migrator-manifest.sh` case 3 asserts this. Bash-3.2 portable —
parallel indexed arrays only (`_MIGRATOR_MANIFEST_PACK_RELS`, etc.),
no associative arrays anywhere. PASS.

### 3.6 Behavior-preservation harness (PASS for what is implemented; SHOULD-FIX for breadth)

`scripts/test-migrator-behavior-preservation.sh` enforces the 5 axes
(A1 file list, A2 file content, A3 report.md post-redaction, A4
stdout post-redaction, A5 exit code). Verified locally:

- v10-realistic-ot: 5/5 pass.
- v10-minimal: 5/5 pass.

Allowed redactions in `_redact()` at line 167:

- ISO-8601 timestamps
- 10-digit epoch seconds
- `/tmp/...` paths, `/var/folders/...` paths (BSD mktemp on macOS), and
  `$TMPDIR/...` paths

This is broader than PLAN §8.2 strictly authorized ("timestamps + tmp
paths") but each addition is justified: epoch seconds appear in
customization-report timestamps; `/var/folders/` is the macOS
equivalent of `/tmp/`. Acceptable.

The four PLAN §13.3 forbidden soft fixes are all absent: no
allow-list, no redaction beyond the documented set, no
`continue-on-error`, no harness-disable.

**SHOULD-FIX gap.** PLAN §8.4 specified "2 fixtures × 5 axes + 5
negative tests = 15 assertions, all green." The harness as shipped:

- Runs against ONE fixture per invocation (defaults to
  v10-realistic-ot; user can pass `v10-minimal`). PLAN required both
  in a single CI run.
- Has zero negative-leg tests for the 5 documented exit codes
  (EXIT_PACK_INVALID, EXIT_NOT_GIT, EXIT_DIRTY, EXIT_NOT_BASELINE,
  EXIT_BASELINE_MISSING).

The PACK-auto-resolution defect (§3.3 BLOCKER) directly demonstrates
why the negative tests matter — they would have caught it.

### 3.7 Cross-version dispatch (PASS)

`scripts/lib/detect.sh:322-386` implements `detect_target_pack_version`
with the 5-signal cascade: tracker.toml `[pack].version` → trinity
addenda fingerprint → v11 surface markers → v10-shape negative
markers → unknown. `test-detect.sh:288-347` (40 cases total, 7 for
the new function) covers all 5 signals + the "v10 with tracker.toml
but no `[pack].version`" cascade-through case from PLAN PR-9.

`migrator_select_adapter` globs
`$PACK/scripts/migrate-v*-to-v*.sh` (`migrator-core.sh:385`), uses
`BASH_REMATCH` on `migrate-v([0-9]+)-to-v([0-9]+)\.sh`, reports
collisions, accepts both `v10` and bare `10` forms. Matches PLAN
OQ3 disposition. PASS.

### 3.8 Refactor faithfulness (PASS modulo the PACK-auto-resolve BLOCKER)

The pre-refactor monolith (d7b3f07) was 437 lines; the C-6 adapter is
~256 lines (more than the planned ~120, primarily because the
v10-specific S4/S5 logic stayed inline in `migrator_post_dispatch_hook`
rather than migrating to declarative `migrator_relocations` /
`migrator_artifact_installs`). The adapter's header comment at lines
22-40 explicitly justifies this:

> The framework's declarative hooks correctly record dispositions
> (architecture §4.3, structural payoff M9). For a future v11→v12
> adapter, using the declarative hooks is the right call. v10→v11
> stays on `migrator_post_dispatch_hook` for backward compatibility.

This justification is sound — the monolith's S5 silent
"copy-without-recording-disposition" semantics could not be
reproduced inside `migrator_artifact_installs` without weakening the
BD-088 truthful-report invariant for *future* adapters. Accepting
this divergence preserves byte-equivalence at the harness level,
which is what PLAN §8 made the gate.

The architecture's M5 (templated revert instructions against
MIGRATOR_FROM_VERSION/TO_VERSION) is correctly implemented at
`migrator-stages.sh:452-460`.

### 3.9 Trinity rule (SHOULD-FIX — wording drift)

The "Migrator framework (BD-119)" bullet was added to all three
pack-repo trinity files in C-7 (commit d2cd9b4). However:

- CLAUDE.md:37 — "(`MIGRATOR_*` vars + the hook functions)"
- AGENTS.md:31 — "(`MIGRATOR_*` vars + the hook functions)"
- GEMINI.md:25 — "(`MIGRATOR_*` vars + hook functions)"  ← missing "the"

And one line break differs: GEMINI.md splits "rewrite — / that"
across two lines; CLAUDE/AGENTS keep "rewrite — that" on one line.
PLAN §9.3 said the wording is "the same across all three trinity
files. No tool-specific carve-out is justified." Trivial fix.

Also: `project-template/CLAUDE.md / AGENTS.md / GEMINI.md` are
correctly UNTOUCHED (per PLAN §9.1 — framework is pack-internal,
not shipped to projects).

### 3.10 Test coverage (PASS for content; SHOULD-FIX for CI wiring)

- `scripts/test-migrator-core.sh` — 19 cases, all pass locally.
  Covers all six public-API functions, exit-code constants, dirty-
  target → EXIT_DIRTY, dispatch arity guard. Exceeds PLAN T-12's
  minimum.
- `scripts/test-migrator-manifest.sh` — 12 cases, all pass locally.
  Covers happy-path parse, malformed-row, unknown-action,
  trinity validator (3 cases), all four manifest verbs in
  `_manifest_iterate`, idempotency. Matches PLAN T-9.
- `scripts/test-detect.sh` — 40 cases, all pass; 7 new cases cover
  `detect_target_pack_version` 5-signal cascade.

**SHOULD-FIX:** None of the new test scripts are wired into
`.github/workflows/validate-pack.yml`. PLAN T-12 and T-14 explicitly
required wiring; PLAN row C-4 said "new `test-migrator-core.sh` step
green" must hold at C-4. The CHANGELOG (incorrectly modified — see
§4) further claims "all run on every push." They do not.

`scripts/tests/test-migrate-v10-to-v11.sh` (BD-085 suite) IS wired
into the workflow (line 92-94), and currently fails 1/39 due to the
PACK-auto-resolve regression in §3.3.

**Path note.** The PLAN said tests would live under
`scripts/tests/test-migrator-*.sh`. They were placed at
`scripts/test-migrator-*.sh` (one level up). Either path is
defensible (alongside `scripts/test-detect.sh`), but the PLAN
specified the deeper path. Not a defect — minor PLAN deviation.

### 3.11 validate-pack Check 26 (PASS)

`scripts/validate-pack.py:1693-1777` implements Check 26 per PLAN
T-3 and OQ2 disposition:

- Asserts presence + `bash -n` validity of all three new lib files.
- Asserts the 6 public-API function-name regexes match in
  `migrator-core.sh`.
- Asserts the 8 exit-code constants are `readonly` declared.
- Asserts the `EXIT_NOT_V10` synonym is preserved.
- Lenient when `migrator-core.sh` is absent (early-commit safety),
  strict once present.

Wired in `main()` at `validate-pack.py:1814`. `python3
scripts/validate-pack.py` exits 0 with all 26 checks green.

The header comment claims Check 26 "lints adapter manifests." It
does not — only the inventory + public-API + exit-code + synonym
checks. The lint-adapter-manifests aspiration from PLAN OQ2's
"extends it during T-13 to actually parse the v10→v11 adapter's
manifest" is not implemented. SHOULD-FIX (claim alignment) but the
inventory check is sufficient for the BD-119 closure gate.

### 3.12 Bash 3.2 + BSD-utils portability (PASS)

Spot-checked the new code for portability:

- No associative arrays (`declare -A`).
- No `${var^^}` upper-case expansion — the one place it was needed,
  `_migrator_usage`, uses `tr '[:lower:]' '[:upper:]'`.
- No `&>` redirections.
- No `mapfile` / `readarray`.
- `find -print` (no `-print0`) — paths under `project-template/` are
  whitespace-free, safe.
- `tar --exclude-from=` used in `_stage_backup` (BSD + GNU compatible).
- No `sed -i` (BSD vs GNU divergent); writes to tmp + `mv` instead
  (`_stage_report_stamp_tracker_version`).
- `_redact()` in the harness avoids `sed -i` and uses `-E`-only
  regex (BSD + GNU portable).
- `mktemp` invoked without a template (BSD-portable form).
- `nullglob` deliberately not used (bash 4 only); guarded by
  `[[ -e "$f" ]]` inside the loop.

All `bash -n` clean (verified). PASS.

### 3.13 macOS / Linux invariance (PASS)

`scripts/migrate-v10-to-v11.sh:52` uses `cd "$(dirname
"${BASH_SOURCE[0]}")" && pwd` for `SCRIPT_DIR`. EXIT trap installed
via `trap _migrator_exit_trap EXIT` in `migrator_run`. Tmp creation
via `mktemp` no template. PASS.

---

## 4. Cross-doc consistency

### CHANGELOG.md

**SHOULD-FIX.** PLAN §2.3 explicitly listed CHANGELOG.md under "Files
explicitly NOT modified" with rationale "Mid-version refactor, no
changelog entry. Per CLAUDE.md, CHANGELOG is touched at version
boundaries with explicit instruction." PLAN §9.1 reiterated the
"N/A" disposition for CHANGELOG.

C-7 (commit d2cd9b4) added a **Scope C — Migrator framework
refactor (BD-119)** block plus a **Migrator-framework regression
coverage (BD-119)** bullet to the v11.0 entry. The bullet contains
two claims that do not match landed state:

1. "all run on every push" — three new test scripts are NOT wired
   into `validate-pack.yml`.
2. "validate-pack Check 26 lints adapter manifests" — Check 26 does
   inventory + public-API + exit-code + synonym checks, not
   manifest linting.

Recommended fix: revert the CHANGELOG hunk in the fix-follow batch.

### README.md

PASS. Repository Layout at `README.md:181-205` lists:

- The new lib files (migrator-core.sh, migrator-stages.sh,
  migrator-manifest.sh) — lines 193-195.
- The three new test scripts — lines 203-205.
- The new fixture (existing-project-mid-dev) — line 219.

`migrate-v10-to-v11.sh` line 181 reads "thin adapter on the BD-119
framework at lib/migrator-*.sh" — accurate.

### HELP-FRAGMENT-PACK.md

Behavior-preserved language continues to describe the migration
script accurately as a one-shot v10→v11 migrator. No staleness.

### supporting-docs/

`MERGE-STRATEGY.md` and `MIGRATION-v10-to-v11.md` reference
`migrate-v10-to-v11.sh`, the `.pack-migrate-v10-to-v11/` state dir,
the `.pack-migrate-v10-to-v11-backup/` directory, and the S0..S6
stage names. All remain accurate after C-6 because behavior is
preserved (state dir name is derived to the same value, stage banners
reproduce the monolith verbatim). PASS.

No supporting-docs reference the old monolith's internal
function names (`stage_s3_dispatch`, `v10_baseline_to_tmp`).

### BACKLOG.md

Both BD-115 (line 1082) and BD-119 (line 1169) remain `Status: Open`
with `Resolved: n/a`, which is correct — implicit-flip happens after
review accepts the batch. Future-BD entries (BD-114, BD-116, BD-117,
BD-118, BD-120, BD-121, BD-122, BD-123, BD-124, BD-125) all present
and coherent at 1034..1416.

### ARCHITECTURE-BD-119.md / PLAN-BD-119.md

Untouched in scope (read-only inputs). PASS.

---

## 5. Severity-ranked findings list

### BLOCKERs (must fix before BD-115 / BD-119 flip to Resolved)

**B1 — Adapter auto-resolves PACK, breaking documented exit code 10.**
Location: `scripts/migrate-v10-to-v11.sh:247-250`.
Problem: `PACK="${PACK:-$(cd "$SCRIPT_DIR/.." && pwd)}"` silently
substitutes a fallback when PACK is unset, so the documented
`EXIT_PACK_INVALID=10` path can no longer fire from this entry point.
Existing CI test `scripts/tests/test-migrate-v10-to-v11.sh` case 1.3
fails on HEAD (38 passed, 1 failed); the behavior-preservation
harness missed it because the harness always exports PACK. PLAN §8
made byte-equivalence absolute.
Fix: remove the auto-resolve. Either let the framework's preflight
fail with `EXIT_PACK_INVALID=10`, or call `die "PACK environment
variable not set" "$EXIT_PACK_INVALID"` at the top of the adapter
before sourcing the framework. The architecture's intent (§3.2,
"PACK valid, libraries sourceable" as I1 invariants) is that the
preflight refuses to proceed.
Severity: BLOCKER.

### SHOULD-FIX (resolve in a fix-follow commit before flip)

**S1 — New test scripts not wired into CI.**
Location: `.github/workflows/validate-pack.yml`.
Problem: `test-migrator-core.sh` (19 tests),
`test-migrator-manifest.sh` (12 tests), and
`test-migrator-behavior-preservation.sh` (5 tests/fixture) are not
referenced by any workflow step. PLAN T-12 and T-14 mandated CI
wiring; CHANGELOG (which itself shouldn't have been modified) claims
they run on every push.
Fix: add three `if: always()` steps under the `tests` job mirroring
the existing per-test step pattern. The behavior-preservation step
should run against both `v10-realistic-ot` and `v10-minimal` (loop
or two steps).
Severity: SHOULD-FIX.

**S2 — Behavior-preservation harness covers 5 axes × 1 fixture; PLAN
required 5 × 2 + 5 negative-leg tests = 15 assertions.**
Location: `scripts/test-migrator-behavior-preservation.sh`.
Problem: the harness defaults to `v10-realistic-ot` and accepts a
fixture name argument; users must invoke it twice for both v10
fixtures, and there are zero negative-leg exit-code tests
(`EXIT_PACK_INVALID`, `EXIT_NOT_GIT`, `EXIT_DIRTY`,
`EXIT_NOT_BASELINE`, `EXIT_BASELINE_MISSING`). The B1 BLOCKER above
demonstrates exactly why the negative-leg tests are load-bearing.
Fix: the harness should iterate over both
`{v10-minimal, v10-realistic-ot}` plus 5 deliberately-broken-target
runs that assert numeric exit-code equality between baseline and
adapter for each documented failure path.
Severity: SHOULD-FIX.

**S3 — CHANGELOG.md modified mid-version, with inaccurate claims.**
Location: `CHANGELOG.md:81-95, 102-107`.
Problem: PLAN §2.3 explicitly forbade CHANGELOG edits; the C-7 commit
added them anyway. Beyond the policy violation, the bullet at
102-107 misstates current state ("all run on every push;
validate-pack Check 26 lints adapter manifests").
Fix: revert the CHANGELOG hunk. Re-add at v11.0 release time per
CLAUDE.md, with claims that match landed state.
Severity: SHOULD-FIX.

**S4 — Trinity bullet wording not byte-identical across CLAUDE/
AGENTS/GEMINI.**
Location: `CLAUDE.md:35-40`, `AGENTS.md:29-34`, `GEMINI.md:23-28`.
Problem: CLAUDE/AGENTS use "+ the hook functions"; GEMINI uses "+
hook functions" (missing "the"). One line break also differs (GEMINI
splits "rewrite — / that"). PLAN §9.3 specified identical wording.
Fix: align all three to one canonical wording.
Severity: SHOULD-FIX.

**S5 — Validate-pack Check 26 docstring overclaims.**
Location: `scripts/validate-pack.py:1696-1714`.
Problem: docstring says Check 26 asserts "shell-syntax valid, and
(when present) source cleanly enough to expose the documented
public-API names." It checks regex presence of function names —
which is fine — but it never sources the file, so "source cleanly
enough" is misleading. The CHANGELOG further claims it lints adapter
manifests, which it does not.
Fix: align docstring to actual behavior; either drop the
"manifest-lint" CHANGELOG claim or extend Check 26 (PLAN OQ2's
T-13 extension).
Severity: SHOULD-FIX.

### NICE-TO-HAVE (defer to follow-up BDs)

**N1 — Test scripts at `scripts/test-migrator-*.sh` instead of
`scripts/tests/test-migrator-*.sh` (PLAN's stated path).**
Trivial. The current location is consistent with `scripts/test-detect.sh`.
Either rename or adjust PLAN expectations in a follow-up.
Severity: NICE-TO-HAVE.

**N2 — `migrator_post_report_hook` is the only required hook the
v10→v11 adapter delegates to (the relocations + artifact-installs
manifest hooks return empty strings and the work happens in the
optional `migrator_post_dispatch_hook`).**
Architecturally documented in the adapter header at
`migrate-v10-to-v11.sh:21-40`, but it means a future maintainer
reading the framework first might be surprised that v10→v11 doesn't
exercise the declarative manifest path. Possible future work:
provide a translation layer that records dispositions in the
`migrator_artifact_installs` `add` action so v10→v11 can use the
declarative path without breaking the harness.
Severity: NICE-TO-HAVE.

**N3 — POQ-3 `tracker.toml [pack].version` write at C-4
(`_stage_report_stamp_tracker_version`) is not exercised by any
fixture in the harness (all v10 fixtures lack tracker.toml in the
target).**
PLAN authorized this addition; a unit test in
`test-migrator-core.sh` or a `v10-with-tracker` fixture would
validate it.
Severity: NICE-TO-HAVE.

---

## 6. Open POQs review (PLAN §15)

| POQ | Status | Disposition |
|---|---|---|
| POQ-1 (manifest TSV — heredoc vs file) | Closed | Adapter uses heredoc inside `migrator_manifest()`; matches PLAN recommendation. |
| POQ-2 (`--dry-run` plumbing) | Closed | `_MIGRATOR_DRY_RUN` flag plumbed into all stages; `_migrator_dryrun_log` centralized. `migrator_run --dry-run` succeeds in `test-migrator-core.sh` case 17 without mutating CLAUDE.md. `--apply` and `--resume` stub-error per PLAN. |
| POQ-3 (`tracker.toml [pack].version` write) | Implemented; not test-covered | `_stage_report_stamp_tracker_version` at `migrator-stages.sh:482-529`. Not reached by any harness or unit test (none of the test fixtures have a tracker.toml in target). N3 above proposes a fix. Closeable. |
| POQ-4 (snapshot file at `scripts/.bd119-pre-refactor-monolith.sh.snapshot`) | Closed (per `.gitignore`) | The harness reads the gitignored snapshot when present; otherwise falls back to `git show d7b3f07:scripts/migrate-v10-to-v11.sh`. Verified: harness ran with the fallback path, succeeded. The on-disk SHA `d7b3f07` is hard-coded in the harness header; if the BD-119 branch ever rebases this needs revisit (PR-6 mitigation). |
| POQ-5 (trinity validator timing) | Closed | Validates at `_stage_dispatch` start (per PLAN recommendation), not at adapter source-time. |
| POQ-6 (test-migrator-core.sh exists) | Closed | C-4b commit `23b0cb0` added the file. Now needs CI wiring (S1). |
| POQ-7 (manifest engine line count keeps separate file vs collapses) | Closed | Three separate files preserved per architecture. `migrator-manifest.sh` is 528 lines, `migrator-stages.sh` 529, `migrator-core.sh` 496 — keeping the split was correct. |
| POQ-8 (POQ enumeration in PLAN reaches 5; no POQ-7/8 in plan) | n/a | The "POQ-7/8" mentioned in the user prompt are not in PLAN-BD-119.md §15 (which has POQ-1..POQ-5 only). Treating "POQ-6/7/8" as informal — what was tracked in the implementation reports as additional planning observations. None are currently load-bearing on closure. |

---

## 7. Recommended disposition

- **BD-115 — Resolved-pending-fix-follow.** The fixture work itself
  is correct and matches the prompt criteria. The only finding is
  the README/CI gap that the verify step needs `--all --clean` first
  (BD-118 scope).

- **BD-119 — Resolved-pending-fix-follow.** The framework architecture
  is faithfully implemented, the public surface is correct and
  frozen, the harness proves byte-equivalence on both v10 fixtures,
  Check 26 is wired and green, and trinity rules + portability are
  observed. The single BLOCKER (B1) is a one-line revert in the
  adapter, surfaced by an existing CI test that did not regress
  silently. The 4 SHOULD-FIX items (CI wiring, harness breadth,
  CHANGELOG revert, trinity wording, Check 26 docstring) are all
  fix-follow material.

A single fix-follow batch addressing B1 + S1..S5 should land before
BD-115 and BD-119 flip to Resolved per the implicit-flip rule. The
fix-follow batch should re-run the existing
`scripts/tests/test-migrate-v10-to-v11.sh` and confirm 39/39 (not
38/39) before flipping.

---

## End of review
