# IMPLEMENTATION-REPORT-BD-169-FIX — Pack-Chat-triaged fix subset of PACK-REVIEW-BD-169.md

**Branch:** `v11-dev`
**Base HEAD (start + end of run; agent does not commit):** `cf67a969c9c94d0185a550987bee0e4e13e9c262`
**Review subject:** BD-169 — per-entry split pack-product wording updates (commit `cf67a96`)
**Review input:** `maintenance-docs/v11-implementation/PACK-REVIEW-BD-169.md` (Pack-Chat-triaged FIX subset; 5/5 fixes applied, 1 SKIP)
**Scope:** 3 in-scope edits + 1 untracked-file append + 1 new report file

---

## §1 — Summary

Five fixes from Pack Chat's triage of `PACK-REVIEW-BD-169.md` applied
to the BD-169 commit `cf67a96` working tree without staging or
committing:

- **M1 (MUST)** — `supporting-docs/MIGRATION-v10-to-v11.md`: reframed
  the pre-commit-hook paragraph as a forward-looking note pointing at
  Addendum #1 §5.6 (Layer 0 deferral); removed the non-existent
  `init-project.sh --install-pre-commit-hook` flag invocation and the
  reference to the non-existent `project-template/scripts/git-hooks/
  pre-commit-check32.sh` script. Kept the architectural intent (the
  future hook will use block-and-flag semantics) and the
  cross-reference traceability. Until a future hook lands, divergence
  is caught at CI time via `validate-pack.py` Check 32 (mirror-in-
  sync) and Check 33 (TOC-in-sync).
- **S1 (SHOULD)** — `project-template/skills/audit-methodology/
  SKILL.md` rule 29 sub-bullet 2: aligned the detection criterion
  with `validate-pack.py` Check 32 detection — presence of
  `_rules.md` (in a directory that exists) is now the sufficient
  condition, matching the validator's `stream_dir.is_dir()` +
  `_rules.md` test. The greenfield case (init-project.sh-installed
  stream with `_rules.md`/`_intro.md`/`_toc.md` and zero BD entries)
  is now consistently "present" in both subsystems.
- **S2 (SHOULD)** — same rule 29 sub-bullet 1: added
  `_v8-resolved-archive.md` (pack `/backlog/` only per integration
  parent §2.6 + §10.5) to the supporting-file list so the rule
  enumerates the same set the architect text enumerates.
- **N2 (NIT)** — same rule 29 sub-bullet 1: added a
  `(changelog-stream-only per integration parent §3.2 + §10.5)`
  qualifier on `_format.md` so a reader cannot infer it should exist
  for every stream. S2 + N2 are landed as a single coherent
  supporting-file list rewrite (not fragmented).
- **N1 (NIT)** — `maintenance-docs/v11-implementation/
  IMPLEMENTATION-REPORT-BD-169.md`: added new §6.1 documenting the
  STATUS.md disclaimer-literal divergence between PLAN §5.8 and
  integration parent §5.3, naming the PLAN as the binding text for
  this commit and flagging architect-doc reconciliation to the
  Batch 19b cleanup architect. Also appended a one-line sub-section
  (L8.1) to `CLEANUP-INPUTS-SESSION-RULES.md` so the architect
  ingests the divergence as part of the cleanup batch.

One reviewer finding SKIPPED per reviewer self-classification:

- **N3 (NIT)** — MIGRATION-v10-to-v11.md "Per-entry decomposition"
  section size delta vs PLAN estimate. Reviewer recorded as "size
  delta is a planning estimate variance, not a defect."

Verification: `validate-pack.py` PASSED clean (all 35 checks); all 10
baseline test scripts PASSED at expected counts; HEAD unchanged at
`cf67a96`.

---

## §2 — Files modified / created

| # | Absolute path | Change type | Notes |
|---|---|---|---|
| 1 | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/supporting-docs/MIGRATION-v10-to-v11.md` | modified | FIX M1 — pre-commit-hook paragraph reframed |
| 2 | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/skills/audit-methodology/SKILL.md` | modified | FIX S1 + S2 + N2 — rule 29 sub-bullets (single coherent rewrite) |
| 3 | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-169.md` | modified | FIX N1 — added §6.1 STATUS.md disclaimer divergence note |
| 4 | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/CLEANUP-INPUTS-SESSION-RULES.md` | modified (in-place append to untracked file) | FIX N1 partner edit — added L8.1 sub-section to flag architect-doc divergence to Batch 19b architect (file was pre-existing untracked per prompt's special note; appending one sub-section preserves that state) |
| 5 | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-169-FIX.md` | new (this report) | Written LAST after PREFLIGHT line per prompt |

`git status --short` (post-edit) verified at §4.4 below.

---

## §3 — Per-fix detail (before / after)

### §3.1 — FIX M1 (MUST) — MIGRATION-v10-to-v11.md pre-commit-hook paragraph

**Path:** `supporting-docs/MIGRATION-v10-to-v11.md`
**Anchor:** final paragraph of the `### \`--force-overwrite-mirror\`
flag (advanced)` subsection inside the new "Per-entry decomposition"
section.

**Before (committed text in `cf67a96`):**

```
The same block-and-flag semantics apply to the optional
client-side pre-commit hook (installed via
`init-project.sh --install-pre-commit-hook`): the hook fails the
commit on divergence and prints the recovery instruction. See
`MERGE-STRATEGY.md` § "12. `generic` — everything else" for the
mirror-vs-source treatment in the BD-088 customization-preserve
pipeline.
```

**After (post-fix text):**

```
A future opt-in client-side pre-commit hook (deferred to v11.x per
`ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md` §5.6) is
planned to inherit these same block-and-flag semantics; that work is
tracked separately and is not part of the v11.0 ship surface. Until
then, divergence is caught at CI time via `validate-pack.py` Check 32
(mirror-in-sync) and Check 33 (TOC-in-sync), and the
`--force-overwrite-mirror` recovery flag described above is available
for advanced users to acknowledge intentional overwrites. See
`MERGE-STRATEGY.md` § "12. `generic` — everything else" for the
mirror-vs-source treatment in the BD-088 customization-preserve
pipeline.
```

**Rationale + spec compliance:**

- Literal `init-project.sh --install-pre-commit-hook` invocation
  removed (Layer 0 is deferred to v11.x per Addendum #1 §5.6 +
  Addendum #1 §0.1 "BD-172?").
- Reference to non-existent `project-template/scripts/git-hooks/
  pre-commit-check32.sh` removed.
- Architectural intent preserved ("inherit these same block-and-flag
  semantics").
- Cross-reference to Addendum #1 §5.6 added for traceability.
- Forward-looking framing makes it clear the hook is planned, not
  shipped.
- Bridges the gap explicitly via the CI checks that DO exist today
  (Check 32 mirror-in-sync; Check 33 TOC-in-sync) — the user is told
  exactly which gate protects them in v11.0 absent the hook.
- Cross-reference to `--force-overwrite-mirror` (preserved, as it
  exists in `scripts/migrate-v10-to-v11.sh` per the per-review
  observation §7 item 2) maintains the recovery-path guidance.
- Voice/tone consistent with surrounding subsection (declarative,
  cross-references companion docs by file + section).

### §3.2 — FIX S1 + S2 + N2 — audit-methodology SKILL.md rule 29 sub-bullets (single coherent rewrite)

**Path:** `project-template/skills/audit-methodology/SKILL.md`
**Anchor:** the two indented sub-bullets under rule 29
(`**auditor-docs**`), introduced by BD-169 commit `cf67a96`.

**Before (committed text in `cf67a96`, sub-bullet 1):**

```
- **Per-entry source-of-truth trees are IN SCOPE.** Per-entry tree
  files (`docs/project/backlog/BD-NNN.md`, ..., including each
  stream's `_rules.md`, `_intro.md`, `_format.md`, and `_toc.md`
  supporting files) ...
```

**After (post-fix sub-bullet 1):**

```
- **Per-entry source-of-truth trees are IN SCOPE.** Per-entry tree
  files (`docs/project/backlog/BD-NNN.md`,
  `docs/project/implementation-plan/phase-N.md`,
  `docs/project/changelog/YYYY-MM-DD-*.md`, including each stream's
  `_rules.md`, `_intro.md`, `_toc.md`, `_format.md`
  (changelog-stream-only per integration parent §3.2 + §10.5), and
  `_v8-resolved-archive.md` (pack `/backlog/` only per integration
  parent §2.6 + §10.5) supporting files) are authored source-of-truth
  in flat-file mode and are audited as documentation per the rule
  above. Same applies to the pack-side per-entry trees at `/backlog/`
  and `/changelog/` when present (pack-self dog-food per integration
  parent §10.5).
```

This single sub-bullet now lands both S2 (added
`_v8-resolved-archive.md` with `(pack /backlog/ only ...)`
qualifier) and N2 (added `(changelog-stream-only ...)` qualifier on
`_format.md`) per the prompt's "Combine S2 and N2 in a single
coherent supporting-file list rewrite (don't fragment)" directive.

**Before (committed text in `cf67a96`, sub-bullet 2 — detection clause):**

```
... Detection: a stream's per-entry tree is "present" when its
directory contains one or more entry files (e.g., `BD-NNN.md`)
alongside `_rules.md`. ...
```

**After (post-fix sub-bullet 2 — detection clause):**

```
... Detection: a stream's per-entry tree is "present" when its
directory exists and contains `_rules.md` (aligned with
`validate-pack.py` Checks 32/33/34 detection — no entry-file
requirement; a greenfield stream installed by `init-project.sh`
with `_rules.md`/`_intro.md`/`_toc.md` but zero entry files yet
still counts as present). If only the monolithic file exists
(pre-v11.0 client, no decomposition applied), audit the monolithic
file as before.
```

This lands FIX S1 — detection criterion is now identical in shape to
`validate-pack.py` Checks 32/33/34 (`stream_dir.is_dir()` plus
`_rules.md` presence; no entry-file requirement). The auditor-docs
agent and the validator now agree on the greenfield case (newly
init-installed stream, no BD entries yet) — both treat it as
"present" and audit / gate against the per-entry tree accordingly.

**Rationale + spec compliance:**

- S1: aligns auditor-docs detection with the validator's published
  detection per `scripts/validate-pack.py` Check 32 (the validator
  tests `stream_dir.is_dir()` plus presence of `_rules.md` with no
  entry-file requirement). Eliminates the greenfield-case
  inconsistency where auditor-docs would audit the monolithic mirror
  while the validator fires mirror-in-sync against the empty tree.
- S2: `_v8-resolved-archive.md` is enumerated by the architect at
  multiple sites (integration parent §2.6, §10.5, lines 324, 364,
  453, 475, 592) as a pack-side `/backlog/`-only supporting file;
  parallel-shaped with `_format.md` (changelog-only). Now listed
  with the explicit scope qualifier so future readers don't infer it
  exists for every stream.
- N2: `_format.md` scoping clarified per integration parent §3.2 +
  §10.5 ("Project changelog/ only: `_format.md`").
- The two sub-bullets remain compact and ordered (IN SCOPE list
  first, OUT OF SCOPE detection second) — no restructuring of the
  rule itself.
- The supporting-file list ordering reorganized to put the
  shared-across-all-streams files first (`_rules.md`, `_intro.md`,
  `_toc.md`), then scoped files with qualifiers (`_format.md`,
  `_v8-resolved-archive.md`) — improves readability.

### §3.3 — FIX N1 — STATUS.md disclaimer divergence note (IMPLEMENTATION-REPORT-BD-169.md §6.1)

**Path:** `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-169.md`
**Anchor:** end of §6 Plan deviations (preferred placement per prompt:
"as a new sub-section under §6 Plan deviations").

**Before (final paragraph of §6):**

```
These refinements are within the architect-doc planner-deferred
authority ("Exact directive-line wording for pack-startup /
pm-startup per Addendum #1 §1.3" in PLAN §5.8 "Architect-doc
planner-deferred items") and do not deviate from the spec.

---

## §7 — Trinity rule compliance
```

**After (new sub-section inserted before §7):**

```
These refinements are within the architect-doc planner-deferred
authority ("Exact directive-line wording for pack-startup /
pm-startup per Addendum #1 §1.3" in PLAN §5.8 "Architect-doc
planner-deferred items") and do not deviate from the spec.

### §6.1 — Architect-doc divergence flagged for Batch 19b cleanup (STATUS.md disclaimer literal)

The PLAN-PER-ENTRY-SPLIT-BATCH-19.md §5.8 spec and the parent
ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §5.3 prescribe DIFFERENT
exact STATUS.md disclaimer wordings:

- **PLAN §5.8 wording** (used in this commit; the PLAN is the binding
  reference per the agent prompt's primary citation): `<!-- Working
  snapshot. Source-of-truth lives in docs/project/backlog/ (per-entry
  tree). Regenerated mirror at docs/project/BACKLOG.md. Edits to
  STATUS.md must not contradict the per-entry tree. -->`
- **Integration parent §5.3 wording** (not used in this commit): `<!--
  STATUS.md is a CONVENIENCE VIEW. It is NEVER source of truth. Counts
  and links may be stale; if they disagree with the per-entry tree at
  docs/project/backlog/ or the regenerated BACKLOG.md mirror, the
  per-entry tree wins. Workflows must not depend on STATUS.md being
  current; depend on the per-entry tree. -->`

The implementation followed PLAN §5.8 verbatim (per the run prompt's
primary reference). This is NOT a coder defect — the coder followed
the binding PLAN text. The architect-doc divergence is flagged here
for the Batch 19b cleanup architect to resolve (architect picks
which wording is canonical and updates the other architect text to
match). This IMPL-REPORT note is the live forward-pointing anchor
for the deferred reconciliation per the pack memory rule
`feedback_deferred_work_tracking` (deferred work must be tracked,
not hoped-for).

---

## §7 — Trinity rule compliance
```

**Partner edit — `CLEANUP-INPUTS-SESSION-RULES.md` L8.1 sub-section:**

**Path:** `maintenance-docs/v11-implementation/CLEANUP-INPUTS-SESSION-RULES.md`
**Anchor:** end of existing L8 section (added 2026-05-16). New
sub-heading `#### L8.1 — Architect-doc divergence: STATUS.md
disclaimer literal (added 2026-05-16 during BD-169 fix pass)` per
the prompt's special note ("Append to the existing L8 section ...
under a new sub-heading"). File was pre-existing untracked; this
edit preserves that state — no restructure.

**After (new sub-section appended at end of L8):**

```
#### L8.1 — Architect-doc divergence: STATUS.md disclaimer literal (added 2026-05-16 during BD-169 fix pass)

`PLAN-PER-ENTRY-SPLIT-BATCH-19.md` §5.8 vs
`ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` §5.3 prescribe
different STATUS.md disclaimer literals (see
`IMPLEMENTATION-REPORT-BD-169.md` §6.1 for both verbatim texts).
The BD-169 implementation followed PLAN §5.8 verbatim per the agent
prompt's primary reference. The Batch 19b cleanup architect should
pick which wording is canonical and update the other architect text
to match — this is documentation-coordination cleanup, not a coder
defect.
```

**Rationale + spec compliance:**

- The IMPL-REPORT §6.1 is the live forward-pointing anchor for the
  deferred reconciliation per `feedback_deferred_work_tracking`
  (memory: deferred work must be tracked, not hoped-for; archived
  reports are not acceptable anchors).
- The CLEANUP-INPUTS-SESSION-RULES.md L8.1 append makes the
  divergence visible to the Batch 19b cleanup architect at ingest
  time — the architect already reads this file per its declared
  purpose ("input data for triage" / "ingest the two
  undocumented-rules lists + the user strategic concerns + the
  current-session learnings (L1-L8)").
- Architect-doc files (PLAN, integration parent, ADDENDUM, ADDENDUM-2)
  are NOT edited per the run prompt's out-of-scope rule — the
  divergence routes to Batch 19b via the IMPL-REPORT note, not via
  direct architect-doc edits.

---

## §4 — Verification

All verification commands listed in the run prompt were executed
against the post-edit working tree. HEAD remained
`cf67a969c9c94d0185a550987bee0e4e13e9c262` throughout (agent does
not commit per `feedback_agents_never_commit`).

### §4.1 — Pack validation

```
$ python3 scripts/validate-pack.py 2>&1 | tail -8
── Check 35: Phase-task lib invariants (BD-106) ──
  OK: scripts/lib/tracker-phase-task.sh present
  OK: scripts/lib/tracker-labels.sh — no tracker_labels_folded_into helper definition (Path 3 forbidden)
  OK: scripts/lib/ — no `folded-into` literal in executable code (V3.3 §3 line 27); comment-only references allowed

============================================================
PASSED — all checks clean
```

**Result:** PASS (all 35 checks clean).

### §4.2 — Baseline test scripts

| Test script | Expected | Observed (tail of output) | Verdict |
|---|---|---|---|
| `bash scripts/tests/test-per-entry.sh` | 57/57 | `All per-entry tests PASSED (57/57).` | PASS |
| `bash scripts/tests/test-init-project.sh` | 67/67 | `Passed: 67 / Failed: 0 / All tests passed.` | PASS |
| `bash scripts/tests/test-migrate-v10-to-v11.sh` | 43/43 | `Passed: 43 / Failed: 0 / All tests passed.` | PASS |
| `bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh` | 61/61 | `Passed: 61 / Failed: 0 / All BD-095 tests passed.` | PASS |
| `bash scripts/tests/test-migrate-v10-to-v11-gates.sh` | 87/87 | `Passed: 87 / Failed: 0 / All BD-101 gate tests passed.` | PASS |
| `bash scripts/tests/test-migrate-v10-to-v11-decompose.sh` | 45/45 | `Passed: 45 / Failed: 0 / All BD-165 decompose tests passed.` | PASS |
| `bash scripts/tests/tracker-agent-read-test.sh` | 52/52 | `Passed: 52 / Failed: 0 / All tests passed.` | PASS |
| `bash scripts/tests/test-validate-pack-checks-32-33-34.sh` | 65/65 | `All BD-168 validate-pack Check 32/33/34 tests PASSED (65/65).` | PASS |
| `bash scripts/test-migrator-core.sh` | 19/19 | `=== Results: 19 passed, 0 failed ===` | PASS |
| `bash scripts/test-persona-contracts.sh` | 3/3 | `All persona contracts PASS.` | PASS |

All 10 baseline test scripts PASS at expected counts. Zero
regression introduced.

### §4.3 — Fix-specific spot-checks (per run prompt verification list)

**M1 — negative grep for removed literals:**

```
$ grep -n "install-pre-commit-hook\|pre-commit-check32.sh" supporting-docs/MIGRATION-v10-to-v11.md
$ echo "exit=$?"
exit=1
```

Empty output + exit=1 confirms both literal strings removed (grep
exits non-zero on no-match). FIX M1 verified.

**S1 — detection criterion alignment grep:**

```
$ grep -B 1 -A 2 "_rules.md" project-template/skills/audit-methodology/SKILL.md | head -16
```

Returned the rule-29 sub-bullets; the relevant fragment now reads:

```
... Detection: a stream's per-entry tree is "present" when its
directory exists and contains `_rules.md` (aligned with
`validate-pack.py` Checks 32/33/34 detection — no entry-file
requirement; ...).
```

FIX S1 verified — detection criterion matches the validator's
`stream_dir.is_dir()` + `_rules.md` test; greenfield case correctly
covered.

**S2 — new `_v8-resolved-archive.md` match:**

```
$ grep -n "_v8-resolved-archive" project-template/skills/audit-methodology/SKILL.md
76:    - **Per-entry source-of-truth trees are IN SCOPE.** ... `_v8-resolved-archive.md` (pack `/backlog/` only ...) ...
```

One new match on line 76 (the sub-bullet 1 supporting-file list).
FIX S2 verified.

**N2 — new `changelog-stream-only` qualifier match:**

```
$ grep -n "changelog-stream-only\|changelog only" project-template/skills/audit-methodology/SKILL.md
76:    - **Per-entry source-of-truth trees are IN SCOPE.** ... `_format.md` (changelog-stream-only per integration parent §3.2 + §10.5) ...
```

One match on line 76. FIX N2 verified.

### §4.4 — HEAD unchanged + working tree status

```
$ git rev-parse HEAD
cf67a969c9c94d0185a550987bee0e4e13e9c262

$ git status --short
 M maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-169.md
 M project-template/skills/audit-methodology/SKILL.md
 M supporting-docs/MIGRATION-v10-to-v11.md
?? maintenance-docs/v11-implementation/CLEANUP-INPUTS-SESSION-RULES.md
?? maintenance-docs/v11-implementation/PACK-REVIEW-BD-169.md
```

- HEAD unchanged at `cf67a96` (verifies "agent does not commit").
- Three `M` files match the in-scope set (MIGRATION-v10-to-v11.md +
  audit-methodology SKILL.md + IMPLEMENTATION-REPORT-BD-169.md).
- Two `??` untracked files are pre-existing per the run prompt:
  - `CLEANUP-INPUTS-SESSION-RULES.md` was already untracked and was
    modified in-place (append-only) per the prompt's special note
    ("the file is currently untracked (pre-existing; user direction
    to leave untracked through Batch 19b). Adding one entry to it
    is consistent with its purpose."). It remains untracked
    post-edit.
  - `PACK-REVIEW-BD-169.md` was the review input — untracked
    throughout (Pack Chat manages its lifecycle separately).
- After this report is written, the `??` count rises to 3 (this
  report file becomes untracked alongside the other two).

---

## §5 — Definition-of-Done checklist

Each Pack-Chat-triaged FIX item × PASS/FAIL with evidence pointer.

| # | Fix item | Severity | Status | Evidence pointer |
|---|---|---|---|---|
| 1 | M1 — remove `install-pre-commit-hook` flag literal | MUST | PASS | §3.1 (before/after); §4.3 M1 grep (empty output + exit=1) |
| 2 | M1 — remove `pre-commit-check32.sh` reference | MUST | PASS | §3.1 (before/after); §4.3 M1 grep (empty output + exit=1) |
| 3 | M1 — preserve architectural intent (block-and-flag semantics) | MUST | PASS | §3.1 After ("inherit these same block-and-flag semantics") |
| 4 | M1 — preserve Addendum #1 §5.6 cross-reference | MUST | PASS | §3.1 After ("deferred to v11.x per `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md` §5.6") |
| 5 | M1 — name CI bridge (Check 32 / Check 33) and `--force-overwrite-mirror` flag | MUST | PASS | §3.1 After ("via `validate-pack.py` Check 32 (mirror-in-sync) and Check 33 (TOC-in-sync), and the `--force-overwrite-mirror` recovery flag described above is available for advanced users") |
| 6 | S1 — detection criterion aligned with `validate-pack.py` Check 32 | SHOULD | PASS | §3.2 sub-bullet 2 After; §4.3 S1 grep |
| 7 | S2 — `_v8-resolved-archive.md` added with `(pack /backlog/ only)` qualifier | SHOULD | PASS | §3.2 sub-bullet 1 After; §4.3 S2 grep (line 76 match) |
| 8 | S2 + N2 combined in single coherent rewrite (not fragmented) | (combined) | PASS | §3.2 sub-bullet 1 is one merged edit; both S2 and N2 land in the same supporting-file list |
| 9 | N2 — `_format.md` scoping qualifier added | NIT | PASS | §3.2 sub-bullet 1 After; §4.3 N2 grep (line 76 match) |
| 10 | N1 — IMPLEMENTATION-REPORT-BD-169.md §6.1 added documenting STATUS.md disclaimer divergence | NIT | PASS | §3.3 IMPL-REPORT §6.1 After |
| 11 | N1 — CLEANUP-INPUTS-SESSION-RULES.md L8.1 sub-section appended | NIT | PASS | §3.3 L8.1 partner edit (append to existing L8, no restructure) |
| 12 | N1 — both texts (PLAN §5.8 + integration parent §5.3) cited verbatim in IMPL-REPORT | NIT | PASS | §3.3 IMPL-REPORT §6.1 After (both disclaimer literals quoted) |
| 13 | N1 — IMPL-REPORT names this as the live forward-pointing anchor per `feedback_deferred_work_tracking` | NIT | PASS | §3.3 IMPL-REPORT §6.1 After (explicit memory citation) |
| 14 | `validate-pack.py` PASSES (all 35 checks) | (verification) | PASS | §4.1 (`PASSED — all checks clean`) |
| 15 | All 10 baseline test scripts PASS at expected counts | (verification) | PASS | §4.2 (full table — 57/57, 67/67, 43/43, 61/61, 87/87, 45/45, 52/52, 65/65, 19/19, 3/3) |
| 16 | HEAD unchanged at `cf67a96` | (constraint) | PASS | §4.4 (`git rev-parse HEAD` = `cf67a969...`) |
| 17 | No out-of-scope source edits (architect docs, BACKLOG, PACK-CHAT, trinity files all untouched) | (constraint) | PASS | §4.4 (`git status --short` lists 3 in-scope `M` files; 0 out-of-scope edits) |
| 18 | No staging, no commits (agents never commit) | (constraint) | PASS | §4.4 (HEAD unchanged; `git status` shows working-tree-only changes) |
| 19 | PREFLIGHT one-line message emitted before IMPL-REPORT write | (Pack Chat policy) | PASS | Emitted in chat: `PREFLIGHT: 5/5 fixes applied (M1, S1, S2, N1, N2); 1 SKIP (N3); verification PASS; HEAD cf67a969c9c94d0185a550987bee0e4e13e9c262; about to Write IMPL-REPORT to /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-169-FIX.md` |

All 19 DoD items: **PASS**.

---

## §6 — Plan deviations

**Zero plan deviations.**

All 5 in-scope fixes (M1, S1, S2, N1, N2) applied per Pack Chat's
triage. Skip (N3) honored per reviewer self-classification. Edits
confined to the 4 in-scope files + 1 new report file. No
architect-doc edits, no BACKLOG edits, no trinity file edits, no
out-of-scope file edits. PREFLIGHT line emitted per protocol before
IMPL-REPORT Write. No staging, no commits — Pack Chat owns those
steps.

---

## §7 — Skip rationale

**N3 — MIGRATION-v10-to-v11.md "Per-entry decomposition" section
size exceeds PLAN estimate.**

- **Reviewer self-classification (PACK-REVIEW-BD-169.md §2.3 N3):**
  "**Suggested remediation:** None — the size delta is a planning
  estimate variance, not a defect. Recorded for visibility."
- **Pack Chat triage decision (per run prompt §Skip list):** No
  action. IMPL-REPORT §3 Group C already acknowledges the delta
  ("~85 lines (slightly over PLAN's ~30 estimate)") and the reviewer
  confirmed the expansion is faithful without padding (PACK-REVIEW
  §2.3 N3 evidence: "Spot-check confirms: the 5 sub-sections expand
  the bullet inventory faithfully without redundancy.").
- **No fix applied.** PLAN §5.8's ~30-line estimate was advisory
  per the reviewer; the 5 sub-coverage items are all present per
  PACK-REVIEW §5 verification ("5 of 5 sub-coverage items present").

---

## §8 — Out-of-scope observations

**Intentionally empty.**

Per the run prompt: "Drift-resilient phrasing in IMPL-REPORT (no
hard-coded line numbers in claims where relative reference works)"
and the implicit principle that this is a focused FIX subset
applying Pack Chat's triage — not a fresh review pass. No new
findings, no new POQs, no new observations introduced. The
architect-doc divergence flagged in N1 §6.1 is the only forward
pointer, and it routes through CLEANUP-INPUTS-SESSION-RULES.md L8.1
to the Batch 19b cleanup architect per the prompt's directive.

---

**End of report.**
