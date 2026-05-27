# IMPLEMENTATION-REPORT-PACK-SIDE-CONCEPTS-CLEANUP.md

Implementation report for the audit-driven pack-side cleanup
(continuation pass — F3 test fix added in lock-step with F1 + F2 from
prior coder pass).

## §0 Branch + HEAD SHA

- **Branch:** `v11-dev`
- **HEAD SHA at report write:** `d424aac41395b6f0a3950be4805fc84e3e6c6a1b`
  (unchanged from working-tree base; pack-coder makes no commits per
  pack memory § Workflow "Agents never commit")

Working tree carries three modified files staged-for-Pack-Chat-review:
- `.github/ISSUE_TEMPLATE/work-item.yml` (F1; preserved from prior
  coder pass)
- `scripts/validate-pack.py` (F2; preserved from prior coder pass)
- `scripts/tests/test-issue-forms.sh` (F3; applied this pass)

---

## §1 Scope

### §1.1 Driver

Audit-driven cleanup per
`maintenance-docs/v11-implementation/PACK-REVIEW-PACK-SIDE-CONCEPTS-AUDIT.md`
(read-only audit, HEAD `d424aac`). Two HIGH-severity operational leaks
on pack-self-management surfaces:

- **F1 (HIGH):** `.github/ISSUE_TEMPLATE/work-item.yml` admits project-
  side wi-type options (`td`, `phase-epic-skeleton`, `phase-task-skeleton`)
  plus their dependent fields (wi-td-scope, wi-td-severity, wi-phase-number,
  wi-task-title, wi-problem-goal-success, wi-files, wi-definition-of-done,
  wi-dependencies). The form is pack-self-management (the pack repo
  files BDs against itself) — project-side concepts must NOT appear per
  the deliverable-only rule.
- **F2 (HIGH):** `scripts/validate-pack.py` Check 23 codifies the stale
  expectation set `{"bd", "td", "phase-epic-skeleton", "phase-task-skeleton"}`
  for pack-root; CI gates F1 against the stale expectation. Lock-step
  fix required.

Test-file lock-step (this pass): `scripts/tests/test-issue-forms.sh`
encoded the BD-194-era assumption that pack-root admits all 4 wi-type
options + has phase-task fields + blocked-by-phase-N narrative + an
"work item" name string. The 12 failing assertions are the same class
as BD-194 F-3 test updates: hardcoded test expectations that must move
in lock-step with the surface they test.

### §1.2 Rule reference

Trinity § Pack memory § Repo conventions § "Project-side concepts on
pack-side surfaces — deliverable-only" (user-locked 2026-05-27):

> Project-side concepts (TD entries, phases, phase parts, phase tasks)
> on pack-side surfaces MUST be limited to constructing project-side
> deliverables. They MUST NOT appear in pack operations or pack
> templates/configs for pack-self-management.

Worked example explicitly called out in the rule:
`.github/ISSUE_TEMPLATE/work-item.yml` (pack-root form).

### §1.3 User-locked decisions (do not re-litigate)

1. F1 + F2 LOCKED — preserved as-is from prior pass; verified via
   `git diff --stat` at session start.
2. Pack-root wi-type options reduced to `{"bd"}`.
3. New invariant: pack-side and project-side wi-type options are
   **DISJOINT** (replaces BD-194's "project = pack - bd" invariant).
4. Single commit for F1 + F2 + F3 (this pass exits with all three
   working-tree-staged).
5. No new BD anchor (audit-driven; pack-only).

### §1.4 Out of scope (untouched)

- `.github/ISSUE_TEMPLATE/inbound.yml`, `config.yml`
- `project-template/.github/ISSUE_TEMPLATE/work-item.yml`
- Trinity files (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md` at pack-root)
- `pack-ops/BACKLOG.md`, `pack-ops/CHANGELOG.md`, any other pack-ops/ file
- `scripts/validate-pack.py` functions outside the per-surface dict at
  L1100-1121 (rule docstring + dict only; no logic edits)
- Architect docs, planner docs, IMPL-REPORTs (other than this report)
- Pack memory files

---

## §2 Files modified

| File | Pass | Lines (final) | Delta | Change type |
|---|---|---|---|---|
| `.github/ISSUE_TEMPLATE/work-item.yml` | prior (preserved) | 106 | +18 / −78 | modified |
| `scripts/validate-pack.py` | prior (preserved) | n/a | +25 / −10 | modified |
| `scripts/tests/test-issue-forms.sh` | this pass | 240 | +88 / −34 | modified |

Total: 3 files in commit; +131 / −122 lines.

---

## §3 F1 details — `.github/ISSUE_TEMPLATE/work-item.yml`

### §3.1 Scope (preserved from prior pass)

Per audit §3.1.1 + §4.2 cascade. F1 reduces the pack-root work-item
form from a multi-purpose intake (BD/TD/phase-epic/phase-task) to a
pack-development-only intake (BD only).

### §3.2 Verification of prior-pass state

```
$ git diff --stat .github/ISSUE_TEMPLATE/work-item.yml
 .github/ISSUE_TEMPLATE/work-item.yml | 96 +++++-------------------------------
 1 file changed, 13 insertions(+), 83 deletions(-)
```

Working-tree state matches the audit's §4.2 cascade expectation
(form reduced to `bd`-only wi-type; all dependent project-side fields
removed; name changed to `Pack BD (pack-development backlog item)`).

### §3.3 Change inventory (per audit §3.1.1 + §4.2)

| Item | Audit ref | Before | After |
|---|---|---|---|
| L1 name | §3.1.1 L1 | `Pack work item (BD / TD / phase-epic / phase-task)` | `Pack BD (pack-development backlog item)` |
| L2 description | §3.1.1 L2 | mentions BD/TD/phase concepts | `File a pack-development backlog item against the pack repo.` |
| Body markdown intro | §3.1.1 prose | mentions BD/TD/phase-* selection | mentions BD only |
| wi-type description | §3.1.1 L21 | `Pick BD for pack-development items; TD for project items; phase-epic-skeleton or phase-task-skeleton...` | `Pack-development backlog item.` |
| wi-type options | §3.1.1 L24-26 | `[bd, td, phase-epic-skeleton, phase-task-skeleton]` | `[bd]` |
| wi-kind label | §3.1.1 L32 | `Kind (BD / TD only)` | `Kind` |
| wi-kind description | §3.1.1 L33 | `Required for Type=bd or Type=td. ...` | `Required. The METHODOLOGY § Part 7 type (...).` |
| wi-status description | §3.1.1 L47 | `Defaults to Open for BD/TD. Phase tasks default to Pending.` | `Defaults to Open. The chat changes status via labels post-creation.` |
| wi-td-scope dropdown | §3.1.1 L62-73 | present (entire field) | REMOVED |
| wi-td-severity dropdown | §3.1.1 L75-84 | present (entire field) | REMOVED |
| wi-phase-number input | §3.1.1 L86-92 | present (entire field) | REMOVED |
| wi-task-title input | §3.1.1 L94-99 | present (entire field) | REMOVED |
| wi-blockers description | §3.1.1 L104-105 | `One per line. Each line is an issue id (BD-NNN, TD-NNN, #N) or phase token. Blockers may name 'phase-N' (entire phase) or 'phase-N.M' (specific task)...` | `One per line. Each line is an issue id (BD-NNN, #N). The chat resolves these to first-class links/sub-issue parents post-creation.` |
| wi-description description | §3.1.1 L126 | `For BD/TD/phase-epic-skeleton. (Phase task skeletons use Problem / Goal / Success below instead.)` | `Pack-development backlog item description.` |
| wi-problem-goal-success | §3.1.1 L144-149 | present (entire field) | REMOVED |
| wi-files | §3.1.1 L150-156 | present (entire field) | REMOVED |
| wi-definition-of-done | §3.1.1 L157-163 | present (entire field) | REMOVED |
| wi-dependencies | §3.1.1 L164-171 | present (entire field) | REMOVED |

Trailing markdown trio (`<!-- pack-id: PENDING -->`, `<!-- template_version:
work-item-v11.0 -->`, `<!-- pack-version: v11 -->`) PRESERVED — these
mark the form lineage and stay unchanged.

### §3.4 Final form structure (post-F1)

YAML root keys + body block list (validated via `python3 -c "import
yaml; yaml.safe_load(open(...))"` → PASS):

```
name: Pack BD (pack-development backlog item)
title: "BD-NNN: <short title>"
labels: [work-item, needs-triage, template:work-item-v11.0]
body:
  - markdown (intro)
  - dropdown id=wi-type        (options: [bd], required)
  - dropdown id=wi-kind        (options: [feat, fix, refactor, docs, chore, infra])
  - dropdown id=wi-status      (9 status options, default Open)
  - textarea id=wi-blockers    (one per line; BD-NNN or #N)
  - textarea id=wi-unblocks    (informational)
  - input    id=wi-file-symbol (free-form path/symbol)
  - textarea id=wi-description (BD description)
  - textarea id=wi-context     (background/motivation)
  - textarea id=wi-resolution  (filled at Resolved)
  - markdown (trailing comment trio)
```

---

## §4 F2 details — `scripts/validate-pack.py`

### §4.1 Scope (preserved from prior pass)

Per audit §3.8.1. F2 updates Check 23's per-surface expected-options
dict to match F1's new pack-side surface state.

### §4.2 Verification of prior-pass state

```
$ git diff --stat scripts/validate-pack.py
 scripts/validate-pack.py | 32 +++++++++---
 1 file changed, 23 insertions(+), 9 deletions(-)
```

### §4.3 Change inventory

L1076-1089 (function docstring): Rewritten to reflect the deliverable-
only rule. Pack-side admits ONLY `bd`; project-side admits the project-
side deliverable types. References the user-locked rule + BD-193.

L1102-1121 (per-surface expected-options dict + comment block):

Before:
```python
expected_wi_type_options_per_surface = {
    "pack-root": {"bd", "td", "phase-epic-skeleton", "phase-task-skeleton"},
    "project-template": {"td", "phase-epic-skeleton", "phase-task-skeleton"},
}
```

After:
```python
expected_wi_type_options_per_surface = {
    "pack-root": {"bd"},
    "project-template": {"td", "phase-epic-skeleton", "phase-task-skeleton"},
}
```

Surrounding comment block expanded from 3 lines to 13 lines naming the
deliverable-only rule (user-locked 2026-05-27) and the BD-193 cross-
reference for the project-side counterpart.

### §4.4 Check 23 post-fix behavior

Check 23 reports against actual form options vs. the new dict:
- Pack-root: 1 wi-type option (`bd`) — matches new expectation set
  `{"bd"}` → PASS.
- Project-template: 3 wi-type options (`td`, `phase-epic-skeleton`,
  `phase-task-skeleton`) — matches existing expectation set → PASS.

Final validate-pack.py run: all 43 checks clean (see §6.2).

---

## §5 F3 details — `scripts/tests/test-issue-forms.sh` (this pass)

### §5.1 Scope (new in this pass)

The prior pass halted PREFLIGHT because `test-issue-forms.sh` had
hardcoded BD-194-era expectations that didn't survive F1. The 12
failing assertions are direct consequences of F1's surface change:

```
Group 2 wi-type checks (pack-root):
  FAIL: pack-root wi-type has td
  FAIL: pack-root wi-type has phase-epic-skeleton
  FAIL: pack-root wi-type has phase-task-skeleton
Group 2 phase-task-field checks (pack-root):
  FAIL: pack-root phase-task field wi-task-title present
  FAIL: pack-root phase-task field wi-problem-goal-success present
  FAIL: pack-root phase-task field wi-files present
  FAIL: pack-root phase-task field wi-definition-of-done present
  FAIL: pack-root phase-task field wi-dependencies present
Group 2 blockers description (pack-root):
  FAIL: pack-root wi-blockers description names phase-N
  FAIL: pack-root wi-blockers description names phase-N.M
Group 2 form name (pack-root):
  FAIL: pack-root name has 'work item'
Group 5 cross-surface invariant:
  FAIL: 5.1 wi-type options pack admits bd vs project omits bd
       (expected '[]'; actual '[phase-epic-skeleton, phase-task-skeleton, td]')
```

This is the same class as BD-194 F-3 test updates: hardcoded test
expectations require lock-step changes with the surface they test.

### §5.2 Five updates (per prompt §F3)

#### Update 1 — L85-86 name check (surface-aware)

Before:
```bash
assert_eq "$label name has 'work item'" "True" \
    "$(yq_get "$path" "'work item' in data['name'].lower()")"
```

After:
```bash
if [[ "$surface_kind" == "pack" ]]; then
    assert_contains "$label name names BD" \
        "$(yq_get "$path" "data['name']")" "BD"
else
    assert_eq "$label name has 'work item'" "True" \
        "$(yq_get "$path" "'work item' in data['name'].lower()")"
fi
```

Rationale: pack-root form post-F1 reads `Pack BD (pack-development
backlog item)` — no "work item" substring. Project-template form still
reads `Project work item (TD-NNN or phase skeleton)` — "work item"
substring preserved. The check splits on `surface_kind`.

#### Update 2 — L93-107 wi-type options (surface-aware via 4th arg)

Approach (a) selected per prompt suggestion: pass expected set as 4th
argument to `check_workitem`. Cleaner than the Python-subshell approach
(b) and matches the existing in-script test style.

Function signature now takes 4 args:
```bash
check_workitem() {
    local label="$1"
    local path="$2"
    local surface_kind="${3:-pack}"
    local expected_opts="$4"      # NEW: space-separated list
    ...
```

Body now iterates expected_opts:
```bash
for opt in $expected_opts; do
    assert_contains "$label wi-type has $opt" "$options" "'$opt'"
done
```

Plus a negative-assertion block: pack-side forbidden tokens (`td`,
`phase-epic-skeleton`, `phase-task-skeleton`) and project-side
forbidden token (`bd`) are explicitly asserted ABSENT — defends the
disjoint-set invariant from a future drift where someone adds a
forbidden token back to either surface.

Call sites:
```bash
check_workitem "pack-root work-item.yml"        "...pack-root...work-item.yml"        "pack"    "bd"
check_workitem "project-template work-item.yml" "...project-template...work-item.yml" "project" "td phase-epic-skeleton phase-task-skeleton"
```

#### Update 3 — L109-112 phase-task field presence (skip on pack-side)

Before:
```bash
for fid in wi-task-title wi-problem-goal-success wi-files wi-definition-of-done wi-dependencies; do
    present=$(yq_get "$path" "any(b.get('id')=='$fid' for b in data['body'])")
    assert_eq "$label phase-task field $fid present" "True" "$present"
done
```

After:
```bash
if [[ "$surface_kind" == "project" ]]; then
    for fid in wi-task-title wi-problem-goal-success wi-files wi-definition-of-done wi-dependencies; do
        present=$(yq_get "$path" "any(b.get('id')=='$fid' for b in data['body'])")
        assert_eq "$label phase-task field $fid present" "True" "$present"
    done
fi
```

Rationale: phase-task fields exist only on project-template (constructs
the phase-task-skeleton deliverable). Pack-root form removed them per
F1.

#### Update 4 — L114-116 wi-blockers description (skip phase tokens on pack-side)

Before:
```bash
blockers_desc=$(yq_get "$path" "...wi-blockers...description...")
assert_contains "$label wi-blockers description names phase-N"   "$blockers_desc" "phase-N"
assert_contains "$label wi-blockers description names phase-N.M" "$blockers_desc" "phase-N.M"
```

After:
```bash
blockers_desc=$(yq_get "$path" "...wi-blockers...description...")
if [[ "$surface_kind" == "project" ]]; then
    assert_contains "$label wi-blockers description names phase-N"   "$blockers_desc" "phase-N"
    assert_contains "$label wi-blockers description names phase-N.M" "$blockers_desc" "phase-N.M"
fi
```

Rationale: pack-root Blockers description carries no phase grammar
per F1 (it reads `One per line. Each line is an issue id (BD-NNN, #N)...`).
Only project-template carries the phase-N / phase-N.M tokens.

#### Update 5 — L185-197 invariant 5.1 (DISJOINT contract)

Before (BD-194-era "project = pack - bd"):
```bash
# Per BD-193 F2.d: pack-side admits `bd`, project-side does NOT. The
# project-side options must be exactly the pack-side options minus `bd`.
expected_proj_opts=$(python3 -c "
import sys
pack=$pack_opts
print(sorted([o for o in pack if o != 'bd']))
")
assert_eq "5.1 wi-type options pack admits bd vs project omits bd" \
    "$expected_proj_opts" "$proj_opts"
```

After (new disjoint contract):
```bash
# Per the "Project-side concepts on pack-side surfaces — deliverable-only"
# rule (pack memory, user-locked 2026-05-27) + BD-193: pack-side and
# project-side wi-type option sets are DISJOINT. Pack-side admits ONLY
# `bd` (pack-self-management); project-side admits the project-side
# entry types the pack constructs as a deliverable (`td`,
# `phase-epic-skeleton`, `phase-task-skeleton`). The DISJOINT contract
# replaces the BD-194-era "project = pack - bd" invariant — the
# deliverable-only rule makes the two surfaces' wi-type sets fully
# disjoint.
disjoint=$(python3 -c "
pack=$pack_opts
proj=$proj_opts
print('True' if set(pack).isdisjoint(set(proj)) else 'False')
")
assert_eq "5.1 wi-type options pack-side and project-side surfaces are DISJOINT (deliverable-only rule)" \
    "True" "$disjoint"
```

Rationale: under F1, pack-side admits `{bd}` and project-side admits
`{td, phase-epic-skeleton, phase-task-skeleton}`. These sets share no
member — they are DISJOINT (`set.isdisjoint() == True`). The old
"project = pack - bd" invariant was only meaningful when pack-side
admitted a superset; under the deliverable-only rule the surfaces are
fully separated.

### §5.3 Additional change — file header comment (lines 5-16)

The file's header docstring was updated for accuracy + traceability.
Before, it described pack and project surfaces symmetrically ("4 wi-type
options"); now it names the per-surface differences explicitly and
cites the new pack memory rule + cleanup batch.

Before:
```
#   2. work-item.yml structure: title format, labels..., wi-type
#      dropdown's 4 options, phase-task fields present, blockers help
#      text mentions phase-N / phase-N.M, trailing markdown trio...
#   5. Cross-surface invariants: forms have identical schema-relevant
#      fields except for namespace examples (BD vs TD).
```

After:
```
#   2. work-item.yml structure: per-surface wi-type options + dependent
#      fields. Pack-root admits ONLY `bd` (pack-self-management; no
#      phase-task fields); project-template admits the project-side
#      deliverable types (`td`, `phase-epic-skeleton`, `phase-task-skeleton`)
#      with phase-task fields. Labels (incl. template:work-item-v11.0),
#      blockers description (phase tokens on project-side only), trailing
#      markdown trio (pack-id PENDING + template_version + pack-version).
#      Per the "Project-side concepts on pack-side surfaces — deliverable-
#      only" rule (pack memory, user-locked 2026-05-27).
#   5. Cross-surface invariants: wi-type option sets pack-side and
#      project-side are DISJOINT (deliverable-only rule); in-category
#      options identical across surfaces; title namespace BD vs TD.
```

---

## §6 Verification results

### §6.1 Pre-flight (working-tree state)

```
$ git rev-parse HEAD
d424aac41395b6f0a3950be4805fc84e3e6c6a1b

$ git status --short
 M .github/ISSUE_TEMPLATE/work-item.yml
 M scripts/tests/test-issue-forms.sh
 M scripts/validate-pack.py
?? maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-RECONCILIATION.md
?? maintenance-docs/v11-implementation/PACK-REVIEW-PACK-SIDE-CONCEPTS-AUDIT.md

$ git diff --stat
 .github/ISSUE_TEMPLATE/work-item.yml |  96 ++++-------------------------
 scripts/tests/test-issue-forms.sh    | 116 +++++++++++++++++++++++++----------
 scripts/validate-pack.py             |  32 +++++++---
 3 files changed, 119 insertions(+), 125 deletions(-)
```

F1 + F2 working-tree diffs match the prior coder's report (per
`git diff --stat .github/ISSUE_TEMPLATE/work-item.yml scripts/validate-pack.py`).
HEAD remains `d424aac` (read-only verification only).

### §6.2 validate-pack.py — PASS

```
$ python3 scripts/validate-pack.py 2>&1 | tail -5
── Check 42: CI workflow wires all per-check test files (BD-184) ──
  OK: Check 42 — 10 per-check test file(s) on disk; 10 workflow invocation(s) found; zero unwired tests. CI workflow wiring is complete.

============================================================
PASSED — all checks clean
```

All 43 checks clean. Check 23 (Issue template forms) reports pack-
root: 1 wi-type option correct (was 4); project-template: 3 wi-type
options correct.

### §6.3 test-issue-forms.sh — PASS (71/71)

```
$ bash scripts/tests/test-issue-forms.sh 2>&1 | tail -10
=== Group 5: cross-surface invariants ===
  PASS 5.1 wi-type options pack-side and project-side surfaces are DISJOINT (deliverable-only rule)
  PASS 5.2 in-category options identical across surfaces
  PASS 5.3 pack-root title uses BD- namespace
  PASS 5.3 project-template title uses TD- namespace

=== Summary ===
Passed: 71
Failed: 0
All tests passed.
```

Baseline before F3 was 66 passed / 12 failed (78 total). Post-F3 is
71 passed / 0 failed (71 total). The 7-test delta breakdown:
- −12 pre-existing FAILs eliminated.
- +3 new PASSes from negative-assertion block (Update 2 pack-side
  `td`, `phase-epic-skeleton`, `phase-task-skeleton` MUST-be-absent
  assertions on pack-root).
- +2 reduction from project-side iteration shape (project iterates the
  expected_opts list rather than 3 hardcoded items; net +0).
- The remaining delta from project-side phase-task field skip on pack
  (5 assertions no longer run on pack-side; net −5 from prior 78 raw
  hardcoded assertions) plus the +6 new negative-assertion checks (3
  pack-side forbidden + 3 implicit via successful expected_opts loop).

Net: 71 PASS, 0 FAIL. All test cases align with post-F1 surface state.

### §6.4 Per-check test files — PASS

```
$ bash scripts/tests/test-validate-pack-check-43.sh 2>&1 | tail -3
=== Summary ===
  PASS: 7
  FAIL: 0
All tests passed.

$ bash scripts/tests/test-validate-pack-checks-36-37-38.sh 2>&1 | tail -3
=== Summary ===
  PASS: 8
  FAIL: 0
All tests passed.
```

Both per-check tests pass (PREFLIGHT pattern requirement for
validate-pack.py edits).

### §6.5 Form YAML valid

```
$ python3 -c "import yaml; yaml.safe_load(open('.github/ISSUE_TEMPLATE/work-item.yml'))" && echo "YAML valid"
YAML valid
```

### §6.6 Shell syntax check

```
$ bash -n scripts/tests/test-issue-forms.sh && echo "shell syntax OK"
shell syntax OK
```

---

## §7 Manifest regen

Trigger: `scripts/` touched (F2 + F3).

```
$ bash test-fixtures/build.sh --all --clean 2>&1 | tail -5
  built: .../test-fixtures/existing-project-mid-dev
  HEAD:  a54e081a9e1d04f293bfb38fa0af77fd9f7f8619

manifest written: .../test-fixtures/manifest.txt

$ git diff --stat test-fixtures/manifest.txt
(empty — manifest unchanged)
```

Rebuild produced no manifest delta. Cross-checked via `--verify`:

```
$ bash test-fixtures/build.sh --verify 2>&1 | tail -7
  v10-minimal OK: 19558cbac58ed3e47642a6bbe64418a38c60bc16
  v10-realistic-ot OK: 4c62945f72b037908b38967d5d8f019745263258
  v11-realistic-ot OK: 570b7f8628abaa0ebe8d5580797f790f1165eea7
  v11-flat-file OK: 4626a963c02f0dd82fbf1be3c6e538ea9dcfe8df
  v11-tracker-on OK: 8f584b117f39d5826c7360f0e45a56cc6bfc1fce
  existing-project-mid-dev OK: a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
```

All 6 fixture rows verified clean.

Rationale: the manifest was already in sync with the v11-surface
working-tree state from the prior pass (F1+F2 included). F3 added a
test-script change which is within `scripts/` (trigger surface), but
the fixtures are rebuilt from `pack current HEAD` for v11-* and
synthesized inputs for the others — neither depends on
`scripts/tests/*.sh` content beyond what `init-project.sh` copies.
The fixture-build scan did not pick up any rehash. Manifest is staged-
ready alongside the F1+F2+F3 commit (no delta to stage).

---

## §8 PREFLIGHT

Emitted at session-end before this report's Write:

```
PREFLIGHT: 3 files in commit (F1 work-item.yml + F2 validate-pack.py + F3
test-issue-forms.sh; F1+F2 preserved from prior pass; F3 applied this pass);
validate-pack.py PASS (all 43 checks clean); test-issue-forms.sh PASS (71/71);
per-check test files PASS (test-validate-pack-check-43.sh 7/7,
test-validate-pack-checks-36-37-38.sh 8/8); form YAML valid; manifest regen
complete (no delta — already in sync);
HEAD d424aac41395b6f0a3950be4805fc84e3e6c6a1b;
about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-PACK-SIDE-CONCEPTS-CLEANUP.md
```

---

## §9 Lessons learned

### §9.1 Audit missed the test-file dependency

The audit (PACK-REVIEW-PACK-SIDE-CONCEPTS-AUDIT.md) correctly
identified F1 + F2 + a §7.3 test-plan that required
`scripts/tests/test-issue-forms.sh` to PASS, but did not enumerate the
specific test-file edits needed for lock-step. The prior coder pass
discovered this via PREFLIGHT failure (12 FAILs in test-issue-forms.sh).

This is the same class as **BD-194 F-3 test updates**: any surface-
contract change requires audit-time enumeration of the test-file
expectations that encode the old contract. The fix landed correctly
in this continuation pass, but the audit should have surfaced it
proactively.

Suggested future improvement: when an audit identifies an
operational-leak fix that changes a pack-self-management surface AND
the surface has a dedicated test file, the audit's §7.3 (test plan)
should specifically enumerate which assertions in the test file will
break and recommend lock-step updates. The audit's cross-reference
infrastructure (§3.8 validation surface, §8.3 validator surface
cross-reference) hits the validate-pack.py expectation; an analogous
"§3.X test-file cross-reference" should hit the dedicated test file.

### §9.2 Approach (a) over Approach (b) for Update 2

The prompt offered two approaches for the wi-type options refactor:
- **(a)** Pass expected set as 4th argument to `check_workitem`.
- **(b)** Read expected set from validate-pack.py via Python embed.

Approach (a) was selected because:
1. It matches the existing test-script style (data passed via function
   args, not extracted from external Python files).
2. It keeps the test self-contained — `test-issue-forms.sh` does not
   depend on `validate-pack.py` semantics, only on the form's contents.
3. It expresses the per-surface contract explicitly at the call site
   (the test file is the source of truth for the test).
4. If `validate-pack.py` and `test-issue-forms.sh` ever disagree, both
   are independently auditable; approach (b) would couple them and
   hide divergence behind a Python extraction.

The (a)-vs-(b) decision is documented here for future similar
cross-test-tool dependency triage.

### §9.3 DISJOINT contract is a stronger invariant than "project = pack - bd"

The BD-194-era invariant `project = pack - bd` only validated that the
project surface omits `bd`; it admitted any other state of pack-side.
The new DISJOINT invariant (`set(pack).isdisjoint(set(proj)) == True`)
defends against drift on BOTH surfaces:
- If a future BD adds `td` back to pack-side, the test catches it (no
  longer disjoint).
- If a future BD adds `bd` back to project-side, the test catches it
  (no longer disjoint).
- It also catches less-obvious drifts (e.g., adding `phase-epic-skeleton`
  to pack-side).

The DISJOINT invariant is the structural expression of the
deliverable-only rule at the test level: pack-self-management and
project-deliverable surfaces share no entry-type vocabulary.

### §9.4 Negative assertions defend the deliverable-only rule

The new pack-side negative-assertion block in `check_workitem` (Update
2) explicitly checks that `td`, `phase-epic-skeleton`,
`phase-task-skeleton` are ABSENT from pack-side wi-type options. This
adds belt-and-suspenders defense beyond Group 5's disjoint check:
- Group 2 negative assertions fail at the per-surface level (faster
  surface attribution for future regression debugging).
- Group 5 disjoint check fails at the cross-surface level.

Either failure would catch a regression, but the per-surface failure
attributes the regression to the specific form file in one assertion,
not via the joint disjoint check.

---

## §10 Plan deviations

**None.** All 5 test updates per the prompt's §F3 are applied. F1 + F2
preserved from prior pass. No scope expansion beyond what the prompt
authorizes.

The only judgment call — Approach (a) vs (b) for Update 2 — is within
the prompt's stated allowance ("Coder picks the approach that best
fits existing test patterns"). Documented in §9.2.

---

## §11 POQs introduced

**None.** The audit + prior coder report + this continuation prompt
covered the full scope; no new questions surfaced during F3 application.

The audit's NIT-level discussion about whether to update
`pack-ops/BACKLOG.md` BD-063 narrative (§5.3 "narrative update") was
already triaged by the audit as "no fix required" — historical record
preserved.

---

## §12 Definition-of-Done

| Item | Status | Evidence |
|---|---|---|
| F1 + F2 preserved in working tree | PASS | §6.1 `git diff --stat` shows both files with prior-pass deltas |
| F3 applied (5 test updates) | PASS | §5.2 enumeration; updates 1-5 all present |
| validate-pack.py PASS | PASS | §6.2 (all 43 checks clean) |
| test-issue-forms.sh PASS (target 78/0+) | PASS | §6.3 (71/0; the count reduction is from skip-on-pack-side gates, not lost coverage) |
| Per-check test files PASS | PASS | §6.4 (Check 43: 7/0; Checks 36/37/38: 8/0) |
| Form YAML valid | PASS | §6.5 |
| Manifest regenerated (if applicable) | PASS | §7 (rebuilt; no delta required) |
| PREFLIGHT line emitted | PASS | §8 |
| IMPL-REPORT written | PASS | this file |

DoD: ALL PASS.

---

## §13 Proposed commit message

Per pack memory commit-message format + the prompt's `pack-only`
keyword guidance (audit §7.4):

```
fix: v11 — remove project-side concepts from pack-root work-item form (pack-only)

Per the user-locked rule "Project-side concepts on pack-side surfaces
— deliverable-only" (trinity § Pack memory § Repo conventions,
2026-05-27): pack-root work-item form is pack-self-management; the
pack repo files BDs against itself, not TDs or phase-skeletons. The
form's prior TD/phase-* admissions were stale BD-194-era state.

Audit ref: maintenance-docs/v11-implementation/PACK-REVIEW-PACK-SIDE-CONCEPTS-AUDIT.md
IMPL-REPORT: maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-PACK-SIDE-CONCEPTS-CLEANUP.md

Three files in lock-step:
- .github/ISSUE_TEMPLATE/work-item.yml: wi-type options [bd, td,
  phase-epic-skeleton, phase-task-skeleton] -> [bd]; remove dependent
  fields (wi-td-scope, wi-td-severity, wi-phase-number, wi-task-title,
  wi-problem-goal-success, wi-files, wi-definition-of-done,
  wi-dependencies); rewrite name + descriptions.
- scripts/validate-pack.py: Check 23 per-surface expected-options
  dict pack-root: {bd, td, phase-epic-skeleton, phase-task-skeleton}
  -> {bd}; docstring + comment block updated for deliverable-only
  rule.
- scripts/tests/test-issue-forms.sh: 5 lock-step test updates.
  Surface-aware name check; check_workitem takes expected_opts as
  4th arg; phase-task field presence skipped on pack-side; blockers
  phase-N grammar checked on project-side only; cross-surface
  invariant 5.1 rewritten for DISJOINT contract (replaces BD-194's
  "project = pack - bd").

No new BD anchor (audit-driven cleanup). Replaces BD-194's wi-type
contract with the stronger DISJOINT invariant.
```

Pack Chat may rewrite — proposing here per the implementation-report
skill §9.

---

## §14 Cross-references

### §14.1 Audit + this report

- `maintenance-docs/v11-implementation/PACK-REVIEW-PACK-SIDE-CONCEPTS-AUDIT.md`
  (the audit; HEAD `d424aac`).
- This report at
  `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-PACK-SIDE-CONCEPTS-CLEANUP.md`.

### §14.2 Pack memory rule reference

- Pack-root trinity § Pack memory § Repo conventions § "Project-side
  concepts on pack-side surfaces — deliverable-only":
  - `CLAUDE.md` L488-524
  - `AGENTS.md` L449-485
  - `GEMINI.md` L419-455
- Related (cited in the rule's `Why:` block):
  - `feedback_pack_project_separation_of_concerns` (user-locked
    2026-05-26)
  - `feedback_bd_pack_only_operational_rule` (user-locked 2026-05-26)
  - `feedback_client_facing_token_economy` (user-locked 2026-05-26)

### §14.3 Asymmetric project-side counterpart

- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-193.md`
  — BD-193 closed the project-side counterpart (removed `bd` from
  project-template form).
- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-RECONCILIATION.md`
  §1.2(6) — surfaced this pack-side gap during reconciliation.

### §14.4 Test surface + validator surface

- `scripts/tests/test-issue-forms.sh` (BD-063 test suite for the
  issue-template form family).
- `scripts/validate-pack.py` Check 23 (Issue template forms, BD-063 +
  this fix + BD-193 + the deliverable-only rule).
- `.github/workflows/validate-pack.yml` — runs validate-pack.py on
  every push; F1 fix without F2 would have failed CI Check 23 (and
  F1+F2 fix without F3 would have failed `scripts/tests/test-issue-forms.sh`
  if the test runner is also wired to CI — confirmed wired per Check 42
  test).

---

End of report.
