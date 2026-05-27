# IMPLEMENTATION-REPORT-BD-194-FOLLOWUP.md

Status: pack-coder deliverable — small follow-on fix bundling 3
reviewer findings (F-1 + F-2 + F-3) from PACK-REVIEW-BD-194.md.
Working-tree HEAD at pass start: `4ef6c02c84797ed151cffad94ca326723e6b7ff7`.
Author: pack-coder; produced 2026-05-27 per BD-194 follow-on pipeline.

This is a small follow-on fix pass to BD-194 BEFORE the BD-194 commit
is pushed to remote. F-3 is a CI blocker (will FAIL on push if not
fixed); F-1 is a MUST same-class staleness fix; F-2 is a NIT doc
accuracy fix.

---

## §1 Scope

This pass applies the 3 reviewer findings surfaced by
`PACK-REVIEW-BD-194.md` §4.1 (F-1), §4.2 (F-2), and §5.6 (F-3) per
user-locked decisions:

- **F-1 (MUST)** — Drop the stale "per CI Check 24 byte-identity
  contract with `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`"
  parenthetical clause from 3 pack-repo dotted-skill mirrors of
  `boundary-investigation/SKILL.md`. Minimal surgical edit
  (Decision 2 Approach 1; identical to the project-template canonical
  fix already applied in BD-194 main commit).
- **F-3a (MUST)** — Update `scripts/tests/test-validate-pack-check-43.sh`
  test expectations: drop `"pack-ops/HELP-FRAGMENT-TRACKER.md"` from
  `expected_extras` list per the post-BD-193 F4/F5 separation contract.
  (Pack-side file is NOT a client-installed file; only the project-
  template-side file is the install source.)
- **F-3b (MUST)** — Same edit shape for
  `scripts/tests/test-validate-pack-checks-36-37-38.sh`.
- **F-2 (NIT)** — Update `IMPLEMENTATION-REPORT-BD-194-STALE-REFS.md`
  §5.2 narrative count from "41 invocations" to "43 invocations"
  (preserving the "40 unique checks" claim, which was correct).

User-locked decisions (NOT re-litigated):
1. F-1 fix approach: drop the stale parenthetical entirely; minimal
   surgical edit; no rephrase or audit-trail addition.
2. F-3 fix approach: Option A — update test expectations to match the
   post-BD-193 inventory.
3. F-2 fix approach: correct the documented count from 41 to 43.
4. Commit shape: single follow-on commit BEFORE BD-194 is pushed;
   bundle all 3 fixes + manifest regen.

---

## §2 Files modified

| File | Change | Surface |
|---|---|---|
| `.claude/skills/boundary-investigation/SKILL.md` | F-1 | Pack-repo dotted-skill (Claude) |
| `.codex/skills/boundary-investigation/SKILL.md` | F-1 | Pack-repo dotted-skill (Codex) |
| `.gemini/skills/boundary-investigation/SKILL.md` | F-1 | Pack-repo dotted-skill (Gemini) |
| `scripts/tests/test-validate-pack-check-43.sh` | F-3a | Pack CI test |
| `scripts/tests/test-validate-pack-checks-36-37-38.sh` | F-3b | Pack CI test |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-194-STALE-REFS.md` | F-2 | BD-194 stale-refs IMPL-REPORT |

No new files created. No files deleted. Manifest regenerated with
empty diff (no fixture row drift; see §8).

---

## §3 F-1 details (3 pack-repo dotted-skill mirrors)

### §3.1 What changed

For each of the 3 pack-repo dotted-skill mirrors at L100-102, the
trailing parenthetical clause `per CI Check 24 byte-identity contract
with `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`` was
removed. Before/after at L100-102 (identical across all 3 files):

BEFORE:
```
  `HELP-FRAGMENT-TRACKER.md` (bare-filename refs from project-side; the
  pack-ops copy lives at `pack-ops/HELP-FRAGMENT-TRACKER.md` per CI
  Check 24 byte-identity contract with `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`),
```

AFTER:
```
  `HELP-FRAGMENT-TRACKER.md` (bare-filename refs from project-side; the
  pack-ops copy lives at `pack-ops/HELP-FRAGMENT-TRACKER.md`),
```

Net delta per file: -2 lines.

### §3.2 Files

- `.claude/skills/boundary-investigation/SKILL.md` (Edit at L100-102).
- `.codex/skills/boundary-investigation/SKILL.md` (Edit at L100-102).
- `.gemini/skills/boundary-investigation/SKILL.md` (Edit at L100-102).

The 3 pack-repo dotted-skill files are byte-identical mirrors; same
surgical edit applies to all three. Identity preserved post-edit
(verified per §7.2).

### §3.3 Rationale

Per PACK-REVIEW-BD-194.md §4.1: Check 24 was retired in BD-194 main
commit (`4ef6c02`); the parenthetical references a check that no
longer exists. The project-template canonical
(`project-template/skills/boundary-investigation/SKILL.md`) was
correctly fixed in the BD-194 main commit (Fix 2 of stale-refs pass),
but the three pack-repo CLI mirrors at pack ROOT were not touched.
These files are LIVE OPERATIONAL skill content loaded by pack-* agents
per the dotted-skill load directives — any pack agent loading the
skill at HEAD would read the stale retired-check reference.

### §3.4 Boundary-discipline check (P-missed-7)

Concept edited: pack-only deny-list parenthetical content (filename
guidance text).

Surface: pack-repo internal skill files (`.claude/skills/`,
`.codex/skills/`, `.gemini/skills/`). NOT under `project-template/`;
NOT client-installed; pack-internal skill content loaded only by
pack-* agents.

SSOT: Each pack-repo dotted-skill file IS the SSOT for its CLI
variant. The 3 CLIs maintain byte-identical content by convention
(pack-side mirrors track each other). No project-side SSOT applies
(the project-template canonical is a separate file with its own
content trajectory).

Direction: REMOVES a stale reference to a retired CI check; does not
introduce pack-only references to project-side files. Surface-local
edit on pack-internal files. SSOT-respecting.

---

## §4 F-3a details (test-validate-pack-check-43.sh)

### §4.1 What changed

L183-191 `expected_extras` list updated to drop
`"pack-ops/HELP-FRAGMENT-TRACKER.md"`. Comment also updated to
document the post-BD-193 F4/F5 + BD-194 rationale.

BEFORE (L183-191):
```python
# T3: includes the explicit non-project-template entries (per
#     _CLIENT_INSTALLED_FILES inventory).
expected_extras = [
    "pack-ops/HELP-FRAGMENT-TRACKER.md",
    "supporting-docs/METHODOLOGY.md",
    "supporting-docs/INSTALL-PROCEDURES.md",
    "scripts/pack-help.sh",
    "scripts/lib/detect.sh",
]
```

AFTER:
```python
# T3: includes the explicit non-project-template entries (per
#     _CLIENT_INSTALLED_FILES inventory). Post-BD-193 F4/F5 + BD-194:
#     pack-ops/HELP-FRAGMENT-TRACKER.md is NOT a client-installed file
#     (project-template/docs/pack/HELP-FRAGMENT-TRACKER.md is the
#     install source per BD-193 F4/F5).
expected_extras = [
    "supporting-docs/METHODOLOGY.md",
    "supporting-docs/INSTALL-PROCEDURES.md",
    "scripts/pack-help.sh",
    "scripts/lib/detect.sh",
]
```

Net delta: -1 list entry, +4 lines comment rationale; same 4 surviving
list entries.

### §4.2 Rationale

Per PACK-REVIEW-BD-194.md §5.6 F-3a: the test asserted that
`_iter_client_installed_files()` returns `pack-ops/HELP-FRAGMENT-
TRACKER.md` as an expected extra. Post-BD-193 (`85196d4`), the
`_CLIENT_INSTALLED_FILES_START/_END` inventory in
`scripts/init-project.sh:1273-1311` correctly OMITS that file (the
pack-side copy is NOT the install source — the project-template-side
file is). Per `feedback_pack_project_separation_of_concerns` (user-
locked 2026-05-26), pack-side and project-side are separate artifacts
with separate audiences — only the project-template-side file is
client-installed.

Option A (update test expectations) aligns the test with the
authoritative inventory. The test was correct in pre-BD-193 state but
became stale when BD-193 corrected the install source.

---

## §5 F-3b details (test-validate-pack-checks-36-37-38.sh)

### §5.1 What changed

L634-648 `expected_extras` set updated to drop
`'pack-ops/HELP-FRAGMENT-TRACKER.md'`. Comment also updated to reflect
post-BD-193 F4/F5 + BD-194 reality; previous comment cited architect
§3.3's pre-BD-193 5-entry list.

BEFORE (L634-648):
```python
# G7.T3: Helper returns >= 5 explicit non-project-template entries
#   plus all project-template/ files. Architect §3.3 lists the 5
#   extras: pack-ops/HELP-FRAGMENT-TRACKER.md,
#   supporting-docs/METHODOLOGY.md, supporting-docs/INSTALL-PROCEDURES.md,
#   scripts/pack-help.sh, scripts/lib/detect.sh.
if hasattr(mod, '_iter_client_installed_files'):
    walked = mod._iter_client_installed_files()
    walked_str = {str(p) for p in walked}
    expected_extras = {
        'pack-ops/HELP-FRAGMENT-TRACKER.md',
        'supporting-docs/METHODOLOGY.md',
        'supporting-docs/INSTALL-PROCEDURES.md',
        'scripts/pack-help.sh',
        'scripts/lib/detect.sh',
    }
```

AFTER:
```python
# G7.T3: Helper returns >= 4 explicit non-project-template entries
#   plus all project-template/ files. Post-BD-193 F4/F5 + BD-194, the
#   4 client-installed extras are: supporting-docs/METHODOLOGY.md,
#   supporting-docs/INSTALL-PROCEDURES.md, scripts/pack-help.sh,
#   scripts/lib/detect.sh. (Architect §3.3's pre-BD-193 5-entry list
#   included pack-ops/HELP-FRAGMENT-TRACKER.md; per BD-193 F4/F5 the
#   pack-side file is NOT the install source —
#   project-template/docs/pack/HELP-FRAGMENT-TRACKER.md is — so it is
#   correctly absent from _CLIENT_INSTALLED_FILES.)
if hasattr(mod, '_iter_client_installed_files'):
    walked = mod._iter_client_installed_files()
    walked_str = {str(p) for p in walked}
    expected_extras = {
        'supporting-docs/METHODOLOGY.md',
        'supporting-docs/INSTALL-PROCEDURES.md',
        'scripts/pack-help.sh',
        'scripts/lib/detect.sh',
    }
```

Net delta: -1 set entry, +5 lines comment rationale (count adjusted
from "5" to "4"; pre-BD-193 cite preserved with explanation); same 4
surviving set entries.

### §5.2 Rationale

Per PACK-REVIEW-BD-194.md §5.6 F-3b: same root cause as F-3a. The
Group 7 T3 test in this file expects the same `expected_extras` set;
same architectural correction class.

The comment update preserves the architect §3.3 cite while explaining
why the entry was removed; this is auditability-positive (a reader
visiting the comment later can reconstruct WHY the test diverged from
the architect doc's enumeration).

---

## §6 F-2 details (IMPL-REPORT-STALE-REFS.md §5.2 count)

### §6.1 What changed

§5.2 of `IMPLEMENTATION-REPORT-BD-194-STALE-REFS.md` claimed "41
invocations across 40 unique checks". Actual at HEAD `4ef6c02` (and
unchanged at this fix-pass HEAD) is 43 invocations across 40 unique
checks.

BEFORE (L209-214):
```
Invoked checks: 41 invocations across 40 unique checks (Check 16,
18, 19 each invoked twice — once for pack-root trinity and once for
project-template trinity — yielding 3 extra invocations; 40 unique
check IDs in range 1-23 + 25-43 with Check 24 absent per main BD-194
deletion). Matches the expected post-main-BD-194 invocation count of
40 invoked checks.
```

AFTER:
```
Invoked checks: 43 invocations across 40 unique checks (Check 16,
18, 19 each invoked twice — once for pack-root trinity and once for
project-template trinity — yielding 3 extra invocations; 40 unique
check IDs in range 1-23 + 25-43 with Check 24 absent per main BD-194
deletion). Matches the expected post-main-BD-194 invocation count of
40 invoked checks.
```

Net delta: -"41 invocations" + "43 invocations" (-1 word + 1 word
edit; total +0 lines). The "40 unique checks" claim is preserved
(correct per the unique-ID enumeration); only the invocation count
was wrong.

The "3 extra invocations" arithmetic in the same paragraph is
consistent with 43 (40 + 3 = 43); the paragraph was internally
inconsistent pre-fix (claimed 41 but arithmetic implied 43).

### §6.2 Rationale

Per PACK-REVIEW-BD-194.md §4.2 F-2: documentation-only inaccuracy in
an IMPL-REPORT artifact. Fixed for accuracy; archive sweep at version
ship (Pattern B) will preserve the corrected figure.

---

## §7 Verification results (all 6 gates)

### §7.1 F-1 stale-ref purge

```
$ grep -n "Check 24 byte-identity" \
    .claude/skills/boundary-investigation/SKILL.md \
    .codex/skills/boundary-investigation/SKILL.md \
    .gemini/skills/boundary-investigation/SKILL.md
$ echo $?
1
```

Zero occurrences (grep exit 1 = no matches). PASS.

### §7.2 Cross-CLI parity for F-1

```
$ diff .claude/skills/boundary-investigation/SKILL.md .codex/skills/boundary-investigation/SKILL.md
$ echo $?
0
$ diff .claude/skills/boundary-investigation/SKILL.md .gemini/skills/boundary-investigation/SKILL.md
$ echo $?
0
```

Both diffs empty (exit 0 = files identical). All 3 mirrors byte-
identical post-edit. PASS.

### §7.3 F-3a verification — test-validate-pack-check-43.sh

```
$ bash scripts/tests/test-validate-pack-check-43.sh
...
=== Group 2: _iter_client_installed_files() base-set verification ===
OK
  PASS _iter_client_installed_files() returns base set per §3.1
...
=== Summary ===
  PASS: 7
  FAIL: 0

All tests passed.
```

PASS: 7 / FAIL: 0. The pre-existing T3 `_iter_client_installed_files()
missing expected entry` failure no longer occurs. PASS.

### §7.4 F-3b verification — test-validate-pack-checks-36-37-38.sh

```
$ bash scripts/tests/test-validate-pack-checks-36-37-38.sh
...
=== Group 7: Check 37 scope expansion (Guardrail 3) unit tests ===
OK
  PASS Group 7 — Guardrail 3 scope expansion unit tests
...
=== Summary ===
  PASS: 8
  FAIL: 0

All tests passed.
```

PASS: 8 / FAIL: 0. The pre-existing G7.T3 `missing expected non-
project-template extras` failure no longer occurs. PASS.

### §7.5 validate-pack.py PASS (no regression)

```
$ python3 scripts/validate-pack.py 2>&1 | tail -3
============================================================
PASSED — all checks clean
```

All 40 unique checks (43 invocations) PASS. No regression from main
BD-194 pass. PASS.

### §7.6 Manifest regeneration verification

```
$ bash test-fixtures/build.sh --all --clean
[builds all 6 fixtures]
manifest written: .../test-fixtures/manifest.txt
$ git diff test-fixtures/manifest.txt
[empty]
$ bash test-fixtures/build.sh --verify
v10-minimal OK: 19558cbac58ed3e47642a6bbe64418a38c60bc16
v10-realistic-ot OK: 4c62945f72b037908b38967d5d8f019745263258
v11-realistic-ot OK: 570b7f8628abaa0ebe8d5580797f790f1165eea7
v11-flat-file OK: 4626a963c02f0dd82fbf1be3c6e538ea9dcfe8df
v11-tracker-on OK: 8f584b117f39d5826c7360f0e45a56cc6bfc1fce
existing-project-mid-dev OK: a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
```

Empty diff = no fixture row drift. All 6 fixtures verify clean post-
rebuild. PASS.

---

## §8 Manifest regen details

Manifest was regenerated per CLAUDE.md RC9 ("Regenerate test-fixtures/
manifest.txt on every v11-surface commit"). F-3 edits touch
`scripts/tests/` (under the v11-surface `scripts/` trigger). F-1 edits
touch pack-repo dotted-skill dirs (`.claude/skills/`, `.codex/skills/`,
`.gemini/skills/`) which are NOT under the v11-surface trigger paths;
the project-template skill mirrors (`project-template/skills/`) ARE
under v11-surface and are propagated to clients, but only the
PROJECT-TEMPLATE canonical was touched in BD-194 main commit (already
in the manifest at `4ef6c02`).

Per the empirical authority of the manifest delta (CLAUDE.md RC9 final
paragraph: "The manifest diff after rebuild is the canonical authority
— the trigger globs are a screen for WHEN to run the rebuild"):

- Rebuild ran: all 6 fixtures rebuilt.
- Manifest diff: empty (`git diff test-fixtures/manifest.txt` returns
  empty).
- Reason: neither `scripts/tests/` nor pack-repo dotted-skill dirs are
  copied to clients by `init-project.sh`. `stage_s4_skills()` copies
  from `project-template/skills/` (not pack-repo dotted-skills);
  `scripts/tests/` is not mass-copied to clients. So no client-
  installed surface changed.
- Manifest does NOT need staging (no change to record).

The 6 fixture SHAs at HEAD are:
```
v10-minimal              19558cbac58ed3e47642a6bbe64418a38c60bc16
v10-realistic-ot         4c62945f72b037908b38967d5d8f019745263258
v11-realistic-ot         570b7f8628abaa0ebe8d5580797f790f1165eea7
v11-flat-file            4626a963c02f0dd82fbf1be3c6e538ea9dcfe8df
v11-tracker-on           8f584b117f39d5826c7360f0e45a56cc6bfc1fce
existing-project-mid-dev a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
```

Unchanged from `4ef6c02` baseline.

---

## §9 PREFLIGHT line

```
PREFLIGHT: 6 files edited (F-1: 3 mirrors + F-3: 2 tests + F-2: 1 doc); manifest regen ran with empty diff (no fixture row drift); validate-pack.py PASS; test-validate-pack-check-43.sh PASS (7/7); test-validate-pack-checks-36-37-38.sh PASS (8/8); F-1 stale-ref purge clean (zero grep matches); cross-CLI parity verified (both diffs empty); HEAD 4ef6c02c84797ed151cffad94ca326723e6b7ff7; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-194-FOLLOWUP.md
```

---

## §10 Files-changed inventory

| Path | Change type | Lines (approx) |
|---|---|---|
| `.claude/skills/boundary-investigation/SKILL.md` | Modified | -2 |
| `.codex/skills/boundary-investigation/SKILL.md` | Modified | -2 |
| `.gemini/skills/boundary-investigation/SKILL.md` | Modified | -2 |
| `scripts/tests/test-validate-pack-check-43.sh` | Modified | -1 list entry, +4 comment lines |
| `scripts/tests/test-validate-pack-checks-36-37-38.sh` | Modified | -1 set entry, +5 comment lines |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-194-STALE-REFS.md` | Modified | 0 line delta (word swap "41" → "43") |
| `test-fixtures/manifest.txt` | Unchanged | empty diff post-regen |

6 files modified. 0 files created. 0 files deleted.

---

## §11 Plan deviations

ZERO. All 4 fixes applied per user-locked decisions:

1. F-1 minimal surgical edit on all 3 mirrors — applied.
2. F-3a `expected_extras` list entry removed — applied (with rationale
   comment addition per the natural extension of the planner's
   "adjacent comment" suggestion).
3. F-3b `expected_extras` set entry removed; architect §3.3 cite
   updated per the planner's "Update the architect §3.3 cite comment
   if applicable" guidance — applied.
4. F-2 count corrected — applied.

The two test-file comment-block updates (F-3a + F-3b) are NOT
deviations; they apply the planner's explicit "Update any adjacent
comment" / "Update the architect §3.3 cite comment if applicable"
guidance from the spawn prompt.

---

## §12 New POQs introduced

NONE. No new design questions surfaced.

---

## §13 Definition-of-Done checklist

| Criterion | Status |
|---|---|
| F-1 applied to all 3 pack-repo dotted-skill mirrors (cross-CLI parity) | PASS |
| F-3a applied (test-validate-pack-check-43.sh expected_extras updated) | PASS |
| F-3b applied (test-validate-pack-checks-36-37-38.sh expected_extras updated) | PASS |
| F-2 applied (IMPL-REPORT-STALE-REFS.md §5.2 count corrected) | PASS |
| Both per-check tests PASS at HEAD (no more failures) | PASS |
| validate-pack.py PASS (no regression) | PASS |
| Manifest regenerated (empty diff per §8) | PASS |
| PREFLIGHT line emitted | PASS |
| IMPL-REPORT written | PASS |

9/9 PASS.

---

## §14 Boundary discipline check (P-missed-7)

Per CLAUDE.md `pack-coder` instructions ("Boundary discipline
pre-flight"), this pass edits the following surfaces, with SSOT
disposition per surface:

- `.claude/skills/boundary-investigation/SKILL.md` —
  **Pack-internal skill content; pack-side SSOT is the file itself
  (mirrored across 3 CLIs). NOT under `project-template/`; not
  client-installed. Edit removes a stale pack-internal reference;
  surface-local.**
- `.codex/skills/boundary-investigation/SKILL.md` — Same as above.
- `.gemini/skills/boundary-investigation/SKILL.md` — Same as above.
- `scripts/tests/test-validate-pack-check-43.sh` —
  **Pack-internal CI test; pack-side SSOT is the file itself. NOT
  copied to clients. Edit aligns test expectations with the post-
  BD-193 inventory (the authoritative source for client-installed
  files at `scripts/init-project.sh:1273-1311`).**
- `scripts/tests/test-validate-pack-checks-36-37-38.sh` — Same as above.
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-194-STALE-REFS.md` —
  **Pack-internal IMPL-REPORT artifact; pack-side SSOT is the file
  itself. Maintenance-docs only; never copied to clients. Edit
  corrects a documentation count inaccuracy.**

No project-side files were modified by this fix pass. No edits
introduce pack-only references into project-side content. F-1 in fact
REMOVES references to a retired pack-internal CI check; F-3 aligns
pack-internal test expectations with the post-BD-193 separation
contract. P-missed-7 boundary discipline is upheld.

---

## §15 Cross-references

### §15.1 Reviewer deliverable

- `maintenance-docs/v11-implementation/PACK-REVIEW-BD-194.md` (HEAD
  `4ef6c02` audit pass)
  - §4.1 F-1 — pack-repo dotted-skill stale-Check-24 reference; applied per §3.
  - §4.2 F-2 — IMPL-REPORT-STALE-REFS invocation-count documentation;
    applied per §6.
  - §5.6 F-3 — pre-existing test failures (F-3a + F-3b); applied per
    §4 + §5.

### §15.2 BD-194 main commit deliverables

- Commit `4ef6c02` — BD-194 main commit; carries:
  - The Check 24 retirement; allowlist comment updates; per-surface
    Check 22 fix; Check 23 fail-loud branch; README prose updates;
    pack-root trinity edit; project-template `boundary-investigation/
    SKILL.md:105-106` minimal surgical edit (the canonical for F-1).
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-194.md` —
  main pass IMPL-REPORT.
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-194-STALE-REFS.md` —
  stale-refs fix pass IMPL-REPORT; THIS pass edits its §5.2 narrative
  per F-2.

### §15.3 Pack memory anchors

- `feedback_pack_project_separation_of_concerns` (user-locked
  2026-05-26) — authoritative for F-3a + F-3b alignment with the post-
  BD-193 F4/F5 contract.
- `feedback_deferral_is_scope_creep` LOGICAL FIT — qualifies F-1 + F-3
  bundling into a small follow-on fix commit (same architectural-
  correction class as BD-194 main; same pack/project separation
  domain).
- `feedback_pack_coder_preflight_pattern` — PREFLIGHT line emitted at
  §9; STOP-MEANS-STOP preamble acknowledged in spawn prompt.
- `feedback_manifest_regen_on_v11_surface` (CLAUDE.md RC9) — manifest
  regenerated per §8; empty diff (no client-installed surface change).
- `feedback_fix_all_review_findings` — all 3 reviewer findings
  applied (no skips beyond user-acknowledged disposition of §3.8 NIT
  trinity line-width drift, which is outside this fix pass's scope per
  the spawn prompt).

### §15.4 BD entry

- `pack-ops/BACKLOG.md:3076-3124` — BD-194 entry (Open at HEAD). This
  fix pass does NOT modify the BD entry (PM-only file; Pack Chat
  status flip on batch completion per `feedback_implicit_status_flip`).

### §15.5 Architect / planner context

- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-194.md` —
  Candidate 6 user-approved design.
- `maintenance-docs/v11-implementation/PLAN-BD-194.md` — single-commit
  plan user-approved. The post-BD-193 F4/F5 contract that F-3
  enforces was a planner-discovery-class finding in the main pass;
  the test alignment was deferred to this follow-on commit per the
  reviewer's Option A recommendation.

---

## §16 Read-only audit confirmation

- HEAD SHA at pass start: `4ef6c02c84797ed151cffad94ca326723e6b7ff7`.
- HEAD SHA at pass end: `4ef6c02c84797ed151cffad94ca326723e6b7ff7`
  (unchanged; this pass did NOT run state-changing git verbs).
- Files modified (working tree only): 6 (listed in §2 and §10).
- Files created: 1 (this IMPL-REPORT).
- Files deleted: 0.
- State-changing git verbs run: NONE (no `git add`, `git commit`,
  `git push`, `git tag`, `git rebase`, `git merge`, `git reset`,
  `git stash`, `git checkout` state-changing forms, `git rm`,
  `git restore`, `git revert`, `git cherry-pick`, `git pull`,
  `git fetch`).
- Read-only git verbs used: `git rev-parse`, `git status`, `git diff`
  (test-fixtures/manifest.txt only).

Pack Chat will stage + commit per usual workflow upon user approval.

---

*End of pack-coder follow-on fix deliverable.*
