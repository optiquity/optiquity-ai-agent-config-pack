# IMPLEMENTATION REPORT — BD-173 Batch 19c H.5 SHOULD-1 fix

- **Branch:** `v11-dev`
- **HEAD at start / end:** `b14483a5dfdfe2b6b148332d00e6d7ebb6f71b97` (no
  commits made by this coder; HEAD unchanged — Pack Chat will stage and
  commit per the no-state-changing-git-verbs rule).
- **Scope:** H.5 INLINE reviewer SHOULD-1 — close two downstream
  cross-reference gaps in `supporting-docs/METHODOLOGY.md` exposed by
  the H.5 additions (V2 §D.4 / §D.2 / §C.12 verbatim, landed at
  `b14483a`). Derivative cross-references only — no new procedural
  content; the H.5 H4 sub-section at the prior L574-606 remains the
  authoritative source for the planner-trigger semantics.

---

## §1 Scope

One file modified: `supporting-docs/METHODOLOGY.md` (a v11-surface file
copied to clients by `scripts/init-project.sh` stage S6, hence
`test-fixtures/manifest.txt` regenerated alongside per Pack-memory rule
"Regenerate test-fixtures/manifest.txt on every v11-surface commit").

Two surface edits:

1. **Workflow 4 step-list narrative (prior L448-460, code block).**
   Inserted a new step 6 (planner-trigger handler), parallel in shape to
   the existing step 5 (architect-trigger handler). Renumbered the
   existing step 6 ("Items that pass the deferral test") to step 7.
2. **Workflow → template cross-reference table (prior L671, table
   row).** Appended `planner.md` Variant: standard to the Workflow 4
   row's "Prompts to use" cell, positioned between the existing
   `architect.md` Variant: mid-phase entry and the `reviewer.md`
   Variant: standard entry.

Both edits are cross-references only. They point at the H.5 H4
sub-section "Planner trigger conditions (mid-phase)" (at the prior
L574-606 in §H4 directly above the cross-reference table) for the
actual trigger-P-A/P-B/P-C definitions. No procedural content from §D.4
is duplicated.

Files in scope (final state):
- `supporting-docs/METHODOLOGY.md` — modified (12 lines net: +10
  insertions, -2 deletions per `git diff --stat`)
- `test-fixtures/manifest.txt` — modified (3 v11-* fixture HEAD-SHA
  rows updated; v10-* and `existing-project-mid-dev` rows unchanged
  per determinism contract)

---

## §2 Edits applied

### Edit 1 — Workflow 4 step-list narrative (new step 6)

**Insertion anchor:** The existing architect-trigger step 5 inside the
```` ``` ````-fenced code block under "### Workflow 4 — Fix cycle (when
reviewer finds issues)". The step is identified by its lead phrase
"5. If TRIGGER: PM chat identifies root cause →".

**Choice of step number (6, not 5a).** The existing list uses pure
integer numbering. A new integer step is consistent with the existing
shape; an "a"-suffix sub-step (5a) would break that convention.
Insertion between architect-trigger (step 5) and deferral (step 6
→ step 7) reflects the runtime ordering documented in the H.5 §D.4
"Planner-vs-architect demarcation" paragraph at the prior L599-606:
"If a coder reports both, run the architect trigger first" — therefore
the step-list checks architect-trigger first (step 5), then
planner-trigger (new step 6), then deferral (step 7).

**BEFORE (lines 451-460 of HEAD `b14483a`):**

```
3. PM chat checks for architect trigger (see below) before generating any fix plan
4. If NO trigger: PM chat presents fix plan → developer approves → coder fix pass → reviewer (step 1)
5. If TRIGGER: PM chat identifies root cause → presents architect pass plan → developer approves
   → architect agent runs (read-only, proposes doc changes) → PM chat presents proposed changes
   → developer approves doc changes → PM chat applies them via Desktop Commander or manual
   → PM chat presents coder fix plan covering both reviewer issues and new arch direction
   → developer approves → coder fix pass → reviewer (step 1)
6. Items that pass the deferral test (see triage protocol): PM chat generates BACKLOG.md
   addition with explicit named blocker → developer runs in standard claude
```

**AFTER:**

```
3. PM chat checks for architect trigger (see below) before generating any fix plan
4. If NO trigger: PM chat presents fix plan → developer approves → coder fix pass → reviewer (step 1)
5. If TRIGGER: PM chat identifies root cause → presents architect pass plan → developer approves
   → architect agent runs (read-only, proposes doc changes) → PM chat presents proposed changes
   → developer approves doc changes → PM chat applies them via Desktop Commander or manual
   → PM chat presents coder fix plan covering both reviewer issues and new arch direction
   → developer approves → coder fix pass → reviewer (step 1)
6. PM chat also checks for planner trigger (Trigger P-A / P-B / P-C; see
   "Planner trigger conditions (mid-phase)" below). If a planner trigger
   fires: PM chat surfaces the trigger and a candidate planner pass plan
   → developer approves → planner agent runs (`planner.md` Variant: standard)
   producing an updated IMPLEMENTATION-PLAN.md Phase N task block
   → PM chat presents the proposed task-block change → developer approves
   → PM chat applies the change → PM chat presents coder fix plan against
   the revised task block → developer approves → coder fix pass → reviewer (step 1)
7. Items that pass the deferral test (see triage protocol): PM chat generates BACKLOG.md
   addition with explicit named blocker → developer runs in standard claude
```

**Shape parity with step 5 (architect-trigger):** Both steps follow the
same arrow-chained pattern: (a) Pack-Chat surfaces the trigger + a
candidate plan, (b) developer approves, (c) the agent runs and produces
an artifact, (d) Pack-Chat presents the proposed change, (e) developer
approves, (f) Pack-Chat applies the change, (g) Pack-Chat presents the
coder fix plan, (h) developer approves, (i) coder fix pass, (j) loop
back to reviewer (step 1). The planner variant produces an
"IMPLEMENTATION-PLAN.md Phase N task block" (per H.5 §D.4 "the planner
pass produces an updated IMPLEMENTATION-PLAN.md Phase N task block");
the architect variant produces "doc changes" (per existing step 5).

**No duplication of §D.4 content.** Step 6 names the trigger labels
(P-A / P-B / P-C) and points at the §D.4 H4 sub-section by its heading
text "Planner trigger conditions (mid-phase) below" — it does NOT
restate when P-A/P-B/P-C individually fire. The §D.4 sub-section
remains the authoritative source.

### Edit 2 — Workflow → template cross-reference table

**Insertion anchor:** The row "| Workflow 4 — Fix cycle | …" in the
markdown table under "### Workflow → template cross-reference". The
row is uniquely identified by its leading cell `| Workflow 4 — Fix
cycle`.

**Position within the cell.** Appended `planner.md` Variant: standard
between the existing `architect.md` Variant: mid-phase entry and the
`reviewer.md` Variant: standard entry. This positioning mirrors the
runtime ordering (architect-trigger checked first; planner-trigger
second; reviewer re-runs after every fix; pm-chat.md backlog-status-
update applies to deferred items) and matches the parallel structure
used in the step-list narrative (Edit 1).

**BEFORE (line 671 of HEAD `b14483a`):**

```
| Workflow 4 — Fix cycle | `coder.md` Variant: fix-cycle (main); `architect.md` Variant: mid-phase (when Trigger A or B fires); `reviewer.md` Variant: standard (re-runs the cycle after each fix); `pm-chat.md` Variant: backlog-status-update (for items deferred to BACKLOG) |
```

**AFTER:**

```
| Workflow 4 — Fix cycle | `coder.md` Variant: fix-cycle (main); `architect.md` Variant: mid-phase (when Trigger A or B fires); `planner.md` Variant: standard (when Trigger P-A, P-B, or P-C fires); `reviewer.md` Variant: standard (re-runs the cycle after each fix); `pm-chat.md` Variant: backlog-status-update (for items deferred to BACKLOG) |
```

**Format-parity verification:**
- Same backtick-delimited template-name format
  (`` `<agent>.md` Variant: <slug> ``) as every other entry in this
  row and in every other row.
- Same parenthetical-fires-when clause format
  ("(when Trigger P-A, P-B, or P-C fires)") that mirrors the existing
  architect entry "(when Trigger A or B fires)" two cells earlier.
- Semicolon separator preserved (the row uses `; ` between entries).
- Trailing pipe `|` and column alignment preserved.

---

## §3 Verification

### `python3 scripts/validate-pack.py`

```
PASSED — all checks clean
```

All 42 checks PASS. Notable check results (relevant to this surface):
- Check 24 (byte-identical mirrors): OK (manifest regeneration was
  required and applied — see §3.2 below).
- Check 36 (commit-scope honesty): OK — Pack Chat will frame this
  fix's commit subject; no scope-keyword decision falls to the coder.
- Check 37 (project-side pack-only deny-list): OK — `supporting-docs/`
  is a v11-surface tree but is checked by Check 37 as a client-shipped
  surface; zero deny-list contamination introduced.
- Check 41 (`_CLIENT_INSTALLED_FILES` self-doc list integrity): OK —
  no copy-site changes.

### `bash test-fixtures/build.sh --all --clean`

All 6 fixtures rebuilt successfully:

```
── building v10-minimal ──             HEAD: 19558cba…
── building v10-realistic-ot ──        HEAD: 4c62945f…
── building v11-realistic-ot ──        HEAD: 368a2b4f…  (new)
── building v11-flat-file ──           HEAD: a1572ced…  (new)
── building v11-tracker-on ──          HEAD: 63753327…  (new)
── building existing-project-mid-dev ──HEAD: a54e081a…

manifest written: …/test-fixtures/manifest.txt
```

### `git diff --stat`

```
 supporting-docs/METHODOLOGY.md | 12 ++++++++++--
 test-fixtures/manifest.txt     |  6 +++---
 2 files changed, 13 insertions(+), 5 deletions(-)
```

- METHODOLOGY.md: +10 -2 (well within "small fix" budget of ~10-20
  added lines max).
- manifest.txt: 3 v11-* fixture rows updated (v11-realistic-ot,
  v11-flat-file, v11-tracker-on); v10-minimal, v10-realistic-ot, and
  existing-project-mid-dev rows unchanged per the determinism contract
  (v10 rows pin to a tag; existing-project-mid-dev has no pack
  surface).

### `git diff supporting-docs/METHODOLOGY.md`

Two hunks, both expected:
- Hunk 1 (around L455): step-list new step 6 inserted; previous step 6
  renumbered to step 7.
- Hunk 2 (around L671): cross-reference table Workflow 4 row gains the
  planner.md Variant: standard entry.

No diff lines in the prior L574-606 range (the H.5 §D.4 H4 sub-section
"Planner trigger conditions (mid-phase)") — H.5 additions preserved
byte-identical.

### Manifest drift sanity check

```
-v11-realistic-ot  ed20f3eae0a177e6f8d132f3031cf6db00379d62
-v11-flat-file  88ef91431c22cdc86a611ec4cc0038d170e22095
-v11-tracker-on  cc9f635933de26cd01de953876ebc69edbf992ca
+v11-realistic-ot  368a2b4f606c981dd5cf3c759c03655c9eaca802
+v11-flat-file  a1572ced68e66f343accfce51e6aee47fc5b7aaa
+v11-tracker-on  63753327b4ce98acd1b4e9ca8e5d8c4bf640383a
```

Expected drift: `supporting-docs/METHODOLOGY.md` is copied to client
`docs/pack/METHODOLOGY.md` by `scripts/init-project.sh` stage S6;
v11-realistic-ot, v11-flat-file, and v11-tracker-on all install the
v11 surface, so all three drift. v10-* fixtures pin to tag v10.x and
do not see HEAD changes. `existing-project-mid-dev` is the pre-install
shape and has no pack surface. Behavior matches the determinism
contract at `test-fixtures/README.md` § Determinism.

---

## §4 Cross-references

- **H.5 review SHOULD-1 finding:** the H.5 INLINE reviewer report
  identified two downstream surfaces that lagged the H.5 §D.4 additions
  — the Workflow 4 row of the cross-reference table at the prior L671
  (missing `planner.md` Variant: standard) and the Workflow 4 step-list
  narrative at the prior L448-460 (missing a planner-trigger step
  parallel to architect-trigger step 5). This report closes both via
  derivative cross-references only.
- **Authoritative source for new planner-trigger content:** ARCHITECTURE
  CLEANUP BATCH 19C V2 §D.4 (verbatim landed at H.5 / `b14483a` as the
  H4 sub-section "Planner trigger conditions (mid-phase)" in
  `supporting-docs/METHODOLOGY.md` at the prior L574-606). Both edits in
  this report point at that sub-section by heading-text reference; no
  semantic content from §D.4 is restated.
- **Pack-memory rule applied:** "Regenerate test-fixtures/manifest.txt
  on every v11-surface commit" (CLAUDE.md § Pack memory →
  § Repo conventions). `supporting-docs/` is one of the four
  v11-surface directories; manifest.txt regenerated in-place via
  `bash test-fixtures/build.sh --all --clean` per the bullet's
  canonical-default invocation. v11-* row drift confirms the trigger
  was correctly identified; v10-* rows unchanged confirms determinism.
- **Renumbering compatibility:** the existing step-list inside the
  Workflow 4 code block was a flat integer list (1-6). After this fix
  it is 1-7. No cross-file references in the rest of the repo cite
  "Workflow 4 step 6" or "step N" by absolute number (verified by no
  matching prose anchor in repo prose surface). Renumbering is local;
  no downstream stale anchors introduced.

---

## §5 Success criteria checklist

| # | Criterion | Result |
|---|---|---|
| 1 | `supporting-docs/METHODOLOGY.md` cross-reference table at the Workflow 4 row has `planner.md` Variant: standard | PASS — Edit 2 applied; format-parity with neighbors verified. |
| 2 | `supporting-docs/METHODOLOGY.md` Workflow 4 step-list has a planner-trigger step parallel to architect-trigger step 5 | PASS — Edit 1 applied as new step 6; shape parity with step 5 verified. |
| 3 | H.5 additions at the prior L574-606 are UNCHANGED (byte-identical-to-V2 contract preserved) | PASS — `git diff` shows zero hunks in that range; the §D.4 H4 sub-section is byte-identical to its `b14483a` state. |
| 4 | `python3 scripts/validate-pack.py` PASS | PASS — all 42 checks clean. |
| 5 | `bash test-fixtures/build.sh --all --clean` completes; manifest shows v11-* row drift | PASS — all 6 fixtures rebuilt; manifest shows 3 v11-* row updates (v11-realistic-ot, v11-flat-file, v11-tracker-on); v10-* and existing-project-mid-dev rows unchanged per determinism. |
| 6 | IMPL-REPORT written to the prescribed path | PASS — this file. |

---

## §6 Out-of-scope confirmations

- **H.5 additions at the prior L574-606 untouched.** Verified by
  inspecting `git diff supporting-docs/METHODOLOGY.md` — the diff
  contains exactly two hunks (around L455 and L671), neither in the
  L574-606 range. The "Planner trigger conditions (mid-phase)" H4
  sub-section (the §D.4 verbatim landing) is byte-identical to its
  state at HEAD `b14483a`.
- **No edits outside the explicit scope.** Only
  `supporting-docs/METHODOLOGY.md` and `test-fixtures/manifest.txt`
  modified. No edits to `project-template/`, `pack-ops/`, `scripts/`,
  `.claude/`, `.codex/`, `.gemini/`, or `maintenance-docs/v11-research/`.
  Confirmed by `git status` showing exactly these two files modified
  plus the new IMPL-REPORT under `maintenance-docs/v11-implementation/`.
- **No new procedural content.** Both edits are derivative cross-
  references only. The new step 6 (Edit 1) names the trigger labels
  P-A / P-B / P-C and points at the §D.4 sub-section heading; the new
  table-cell entry (Edit 2) names the variant slug and the fires-when
  clause. Neither restates when P-A / P-B / P-C individually fire,
  which remains the §D.4 sub-section's domain.
- **No git state-changing verbs run.** Only `git status`,
  `git diff`, `git diff --stat`, and `git rev-parse HEAD` invoked —
  all read-only per the agent contract. Pack Chat will stage and
  commit.

---

## §7 Open questions / deferrals

**None.** The existing table-row format ("` `<agent>.md` Variant: <slug>` `
with parenthetical fires-when clause) and the existing step-list shape
(arrow-chained Pack-Chat → developer → agent loop) were unambiguous;
both edits adopted the existing formats without inventing new
conventions.

One minor downstream observation surfaced during the work but is NOT a
new POQ: the step-list now uses integer 1-7 rather than 1-6. No
cross-file prose anchor references "Workflow 4 step N" by absolute
number, so the renumbering is local and stale-anchor-free. This is
recorded in §4 (Renumbering compatibility) and requires no follow-up.

---

## Plan deviations

**None.** The two edits and the verification harness executed exactly
as prescribed in the prompt's Approach section. Both surface edits
applied at the named anchors; no scope expansion, no alternate-shape
deviation.

## New POQs introduced

**None.**

## Files changed

| Path | Change type |
|---|---|
| `supporting-docs/METHODOLOGY.md` | modified (Edit 1 + Edit 2) |
| `test-fixtures/manifest.txt` | modified (regenerated per v11-surface manifest rule; 3 v11-* row drifts) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.5-SHOULD-1-fix.md` | new (this report) |

## Boundary discipline check

`supporting-docs/METHODOLOGY.md` is a project-side / client-shipped
file (copied to `docs/pack/METHODOLOGY.md` by `init-project.sh` stage
S6). Project-side SSOT for the concept being edited is METHODOLOGY.md
itself — the file IS the project-side SSOT for workflow methodology
and the workflow → template cross-reference table. No pack-only
references introduced (no mention of `pack-ops/PACK-AGENTS.md`,
`pack-ops/PACK-CHAT.md`, the capitalized `Pack Chat` orchestrator role,
or any `pack-*` agent name). Both edits use:

- `pm-chat.md` (the project-side prompt-template filename living under
  client `docs/pack/prompts/pm-chat.md`) — already pre-existing in the
  table and step-list; this fix does not change those references.
- `planner.md` (the project-side prompt-template filename) — added by
  this fix. Project-side reference; no pack-only contamination.
- "PM chat" (lowercase, "the PM chat" — the project-side orchestrator
  noun) — already pre-existing in the step-list narrative; this fix
  preserves the lowercase project-side form in the new step 6.

Boundary check clean.
