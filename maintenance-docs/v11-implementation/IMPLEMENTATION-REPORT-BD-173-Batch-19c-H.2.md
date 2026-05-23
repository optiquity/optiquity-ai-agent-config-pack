# IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.2

**Branch:** v11-dev
**Pre-edit HEAD SHA:** f22f800d3581b1961926b6553af351c08744184b
**Worktree HEAD at IMPL-REPORT write:** f22f800d3581b1961926b6553af351c08744184b
(No commits performed by coder; HEAD unchanged. Pack Chat will stage + commit.)

---

## Summary

H.2 PM-CHAT.md behavioral rules consolidation — 8 new bullets in
`project-template/docs/pack/PM-CHAT.md` `## Behavioral rules` section
(per V2 §C.1 / §C.4 / §C.7 / §C.8 / §C.9 / §C.10 / §C.11 / §C.13) plus
1 new `>` callout in `supporting-docs/METHODOLOGY.md` Part 7 Procedure 4
(per V2 §D.5). All 9 edits applied verbatim from V2 AFTER text; §C.10 +
§C.11 carry the M-3 neutral-language sibling annotations referencing
§C.13. Step ordering per PLAN §3 H.2 (post-§C.13-integration renumbering).

---

## Edits applied

### Edit 1 — §C.11 (open-questions-surface) — PM-CHAT.md

- **Source:** V2 §C.11 AFTER text (incl. M-3 neutral-language sibling
  annotation referencing §C.13).
- **Insertion location:** Immediately after the existing bullet "Plan
  before executing." (PM-CHAT.md `## Behavioral rules` section).
- **V1 anchor cite (V2 doc):** L180-181. **Anchor at HEAD f22f800 pre-edit:**
  L180-181 — RESOLVED (no drift).
- **Before:** Anchor bullet "Plan before executing." at L180-181, followed
  immediately by "No solutions in agent prompts." at L182.
- **After:** Anchor bullet "Plan before executing." unchanged at L180-181;
  new bullet "Open questions surface to user, never decided unilaterally."
  inserted at L182-195 (14 lines including sibling annotation); "No
  solutions in agent prompts." pushed to L214.
- **One-line diff summary:** New bullet starts with "- **Open questions
  surface to user, never decided unilaterally.**" and ends with
  "...to the open-questions decision class."

### Edit 2 — §C.13 (decision presentation protocol) — PM-CHAT.md

- **Source:** V2 §C.13 AFTER text verbatim (5-point meta-rule).
- **Insertion location:** Immediately after the §C.11 bullet inserted in
  Edit 1.
- **V1 anchor cite:** None (§C.13 NEW per user direction 2026-05-23).
  **Insertion-after-target at HEAD post-Edit-1:** §C.11 bullet at L182-195.
- **Before:** §C.11 bullet ends at L195, followed by "No solutions in
  agent prompts." at L214 post-Edit-1.
- **After:** §C.11 ends at L195; new bullet "Decision presentation
  protocol." inserted at L196-213 (18 lines, 5 numbered points); "No
  solutions in agent prompts." now at L214.
- **One-line diff summary:** New bullet starts with "- **Decision
  presentation protocol.** When the PM chat surfaces any decision..."
  and ends with "...spawn an agent to produce the work the right way."

### Edit 3 — §C.7 (re-read per-agent prompt files + REPORT FILE verify) — PM-CHAT.md

- **Source:** V2 §C.7 AFTER text verbatim.
- **Insertion location:** Immediately after the existing bullet "Follow
  Prompt Authoring Principles." in PM-CHAT.md `## Behavioral rules`.
- **V1 anchor cite (V2 doc):** L188-189. **Anchor at HEAD pre-edit:**
  L188-189 — RESOLVED (no drift). **Anchor post-Edits-1+2:** L220-221
  (shifted +32 lines by Edits 1+2).
- **Before (post-Edits-1+2):** Anchor bullet "Follow Prompt Authoring
  Principles." at L220-221, followed by "Select skills using
  PLATFORM-SKILLS.md." at L222.
- **After (post-Edit-3):** Anchor bullet unchanged at L220-221; new bullet
  "Re-read the per-agent prompt file before generating any agent prompt
  — every time, no exceptions." inserted at L222-237 (16 lines).
- **One-line diff summary:** New bullet starts with "- **Re-read the
  per-agent prompt file..."  and ends with
  "...breaking the file-based-reporting contract."

### Edit 4 — §C.10 PM-CHAT.md half (architect-output → user-reads) — PM-CHAT.md

- **Source:** V2 §C.10 FIRST text block (REVISED-WORDING per salvageability
  B1 — V1 cross-side citation dropped). Includes M-3 neutral-language
  sibling annotation referencing §C.13.
- **Insertion location:** Immediately after the §C.7 bullet inserted in
  Edit 3 (per PLAN step 7: "Insert immediately after the §C.7 (re-read
  per-agent prompt files) bullet inserted in step 3 above").
- **V1 anchor cite:** Behavioral-rules section (post-§C.7 placement).
  **Insertion-after-target at HEAD post-Edit-3:** §C.7 bullet ends at L237.
- **Before (post-Edit-3):** §C.7 bullet ends at L237, followed by "Select
  skills using PLATFORM-SKILLS.md." at L238.
- **After (post-Edit-4):** §C.7 ends at L237; new bullet "Architect
  output → user reads → next step waits." inserted at L238-251 (14 lines
  including sibling annotation); "Select skills using PLATFORM-SKILLS.md."
  now at L252.
- **One-line diff summary:** New bullet starts with "- **Architect output
  → user reads → next step waits.**" and ends with "...to the
  architect-output decision class."

### Edit 5 — §C.1 PM-CHAT.md half (always-reviewer-after-coder) — PM-CHAT.md

- **Source:** V2 §C.1 FIRST text block (PM-CHAT.md half) verbatim. NOT
  the METHODOLOGY.md half — that landed in H.1.
- **Insertion location:** Immediately after the existing bullet "Fix cycle
  rules." in PM-CHAT.md `## Behavioral rules`.
- **V1 anchor cite (V2 doc):** L201-202. **Anchor at HEAD pre-edit:**
  L201-202 — RESOLVED (no drift). **Anchor post-Edits-1+2+3+4:** L263-264
  (shifted +62 lines by Edits 1+2+3+4).
- **Before (post-Edits-1+2+3+4):** Anchor bullet "Fix cycle rules." at
  L263-264, followed by "Source file edits." at L265.
- **After (post-Edit-5):** Anchor bullet unchanged at L263-264; new bullet
  "Always run reviewer after every coder report — no exceptions."
  inserted at L265-276 (12 lines).
- **One-line diff summary:** New bullet starts with "- **Always run
  reviewer after every coder report — no exceptions.**" and ends with
  "...PM chat never requests or suggests skipping."

### Edit 6 — §C.4 (closeout-sequence: present-before-write) — PM-CHAT.md

- **Source:** V2 §C.4 AFTER text verbatim.
- **Insertion location:** Immediately after the existing bullet "Source
  file edits." in PM-CHAT.md `## Behavioral rules`.
- **V1 anchor cite (V2 doc):** L203-205. **Anchor at HEAD pre-edit:**
  L203-205 — RESOLVED (no drift; salvageability §C.4 confirmed anchor
  resolves post-BD-178). **Anchor post-Edits-1..5:** L277-279.
- **Before (post-Edits-1..5):** Anchor bullet "Source file edits." at
  L277-279, followed by "STATUS.md phase title links." at L280.
- **After (post-Edit-6):** Anchor bullet unchanged at L277-279; new bullet
  "Closeout sequence — present, wait, then write." inserted at L280-290
  (11 lines, 5 numbered steps).
- **One-line diff summary:** New bullet starts with "- **Closeout
  sequence — present, wait, then write.**" and ends with
  "...requires manual revert."

### Edit 7 — §C.9 (mid-pipeline working-tree intentional) — PM-CHAT.md

- **Source:** V2 §C.9 AFTER text verbatim.
- **Insertion location:** Immediately after the §C.4 bullet inserted in
  Edit 6 (per PLAN step 6).
- **V1 anchor cite:** Behavioral-rules section (post-§C.4 placement).
  **Insertion-after-target at HEAD post-Edit-6:** §C.4 bullet ends at L290.
- **Before (post-Edit-6):** §C.4 bullet ends at L290, followed by
  "STATUS.md phase title links." at L291.
- **After (post-Edit-7):** §C.4 ends at L290; new bullet "Mid-pipeline
  working-tree state is intentional — no auto-commit at checkpoints."
  inserted at L291-303 (13 lines); "STATUS.md phase title links." now at
  L304.
- **One-line diff summary:** New bullet starts with "- **Mid-pipeline
  working-tree state is intentional — no auto-commit at checkpoints.**"
  and ends with "...multi-pass jobs wait."

### Edit 8 — §C.8 (pack-repo-is-read-only) — PM-CHAT.md

- **Source:** V2 §C.8 AFTER text verbatim (REVISED-WORDING per
  salvageability B2 + audit §3.1.8 — drop "supporting-docs/" parenthetical;
  "Pack Chat" audience cite replaced with "the pack maintainer";
  PACK-FEEDBACK.md product-feature cross-ref retained).
- **Insertion location:** Immediately after the existing bullet "Pack
  feedback loop." in PM-CHAT.md `## Behavioral rules`.
- **V1 anchor cite (V2 doc):** L221-227. **Anchor at HEAD pre-edit:**
  L221-227 — RESOLVED (no drift). **Anchor post-Edits-1..7:** L319-325
  (shifted +98 lines by Edits 1..7).
- **Before (post-Edits-1..7):** Anchor bullet "Pack feedback loop."
  (multi-line) at L319-325, followed by "Custom files via Procedure 5
  only." at L326.
- **After (post-Edit-8):** Anchor bullet unchanged at L319-325; new bullet
  "Pack repo is read-only from this project." inserted at L326-336 (11
  lines); "Custom files via Procedure 5 only." now at L337.
- **One-line diff summary:** New bullet starts with "- **Pack repo is
  read-only from this project.**" and ends with "...scope all agent edits
  to this project's working tree."

### Edit 9 — §D.5 (METHODOLOGY.md Part 7 Procedure 4 cross-ref callout) — METHODOLOGY.md

- **Source:** V2 §D.5 AFTER text verbatim.
- **Insertion location:** `supporting-docs/METHODOLOGY.md` Part 7
  Procedure 4 — immediately after the Procedure 4 fenced code block
  close, before the "### Procedure 5 — Custom agent and skill workflow"
  heading.
- **V1 anchor cite (V2 doc):** L1198. **PLAN cross-walk cite:** L1219.
  **Actual fence-close at HEAD pre-edit:** L1259 (post-H.1 +40-line
  growth). See "Anchor verification" section below for drift detail.
- **Before:** Procedure 4 fenced block ends at L1259 with closing ` ``` `,
  followed by blank line and "### Procedure 5" heading at L1261.
- **After:** Procedure 4 fenced block unchanged (ends at L1259); new
  `>` callout block "Closeout-sequence rule." inserted at L1261-1268 (8
  lines including blank-line spacing); "### Procedure 5" heading now at
  L1270.
- **One-line diff summary:** New callout starts with "> **Closeout-
  sequence rule.** Procedure 4 step 3 ('PM chat marks Status: Resolved')..."
  and ends with "Never write closeout files before presenting their
  content and receiving approval."

---

## Anchor verification

All V1-cited anchors in PM-CHAT.md verified as RESOLVED with NO drift
between V2 cite and HEAD pre-edit positions:

| V2 cite | HEAD pre-edit position | Status |
|---|---|---|
| "Plan before executing." (L180-181) | L180-181 | RESOLVED — no drift |
| "Follow Prompt Authoring Principles." (L188-189) | L188-189 | RESOLVED — no drift |
| "Fix cycle rules." (L201-202) | L201-202 | RESOLVED — no drift |
| "Source file edits." (L203-205) | L203-205 | RESOLVED — no drift |
| "Pack feedback loop." (L221-227) | L221-227 | RESOLVED — no drift |

METHODOLOGY.md Procedure 4 anchor — **DRIFTED**:

- V1 doc cite: L1198 (pre-H.1 baseline).
- PLAN-CLEANUP-BATCH-19C.md §1 cross-walk cite (planner's recorded HEAD
  `9a95bfa`): L1219 (Procedure 4 fenced block close).
- Actual fence-close at HEAD f22f800 pre-edit (post-H.1 commit `abc95da`):
  L1259.
- **Cause:** H.1 commit `abc95da` added 40 lines to METHODOLOGY.md
  (verified via `git diff --stat abc95da~1 abc95da` — METHODOLOGY.md
  +40 net). These insertions landed earlier in the file (Workflow 2 and
  Workflow 4 callouts per H.1 scope), pushing Procedure 4 fence-close
  from L1219 (planner cross-walk) to L1259 (post-H.1).
- **Coder action:** Used the durable anchor (Procedure 4 fenced block
  closing ``` ``` ``` followed by blank line followed by `### Procedure 5`
  heading) rather than the line number. Edit applied correctly at the
  actual fence-close position.

---

## Sibling-annotation confirmation (M-3 fix)

Both §C.11 (Edit 1) and §C.10 (Edit 4) bullets carry the M-3
neutral-language sibling annotation cross-referencing §C.13 (the
"Decision presentation protocol" bullet inserted in Edit 2):

- **§C.11 (Edit 1) trailing sentence:** "This is a specific application
  of the decision presentation protocol (see the 'Decision presentation
  protocol' bullet in this `## Behavioral rules` section) to the
  open-questions decision class."
- **§C.10 (Edit 4) trailing sentence:** "This is a specific application
  of the decision presentation protocol (see the 'Decision presentation
  protocol' bullet in this `## Behavioral rules` section) to the
  architect-output decision class."

**Neutral-language confirmation:** Both annotations use the phrase "in
this `## Behavioral rules` section" — neither uses positional language
("above" / "below" / "earlier" / "later") that would couple the sibling
annotation to bullet ordering. M-3 fix verified.

**grep verification (post-edits, HEAD f22f800):**

```
$ grep -n "decision presentation protocol" project-template/docs/pack/PM-CHAT.md
193:  This is a specific application of the decision presentation protocol
249:  This is a specific application of the decision presentation protocol
```

```
$ grep -n -B1 -A2 "in this \`## Behavioral" project-template/docs/pack/PM-CHAT.md
193-  This is a specific application of the decision presentation protocol
194:  (see the "Decision presentation protocol" bullet in this `## Behavioral
195-  rules` section) to the open-questions decision class.
196-- **Decision presentation protocol.** When the PM chat surfaces any
--
249-  This is a specific application of the decision presentation protocol
250:  (see the "Decision presentation protocol" bullet in this `## Behavioral
251-  rules` section) to the architect-output decision class.
252-- **Select skills using PLATFORM-SKILLS.md.** Every agent prompt must include
```

Two matches each — exactly the two expected sibling-annotation sites.
No "above"/"below" phrasing present.

---

## Commit subject scope keyword

Per PLAN §3 H.2: `(mixed — no keyword; project-template/ + supporting-docs/
+ maintenance-docs/IMPL-REPORT + test-fixtures/manifest)`.

H.2 commit shape is mixed-scope: this IMPL-REPORT touches
`project-template/docs/pack/PM-CHAT.md` (project-side surface),
`supporting-docs/METHODOLOGY.md` (client-installed pack content), and
the IMPL-REPORT itself lands under `maintenance-docs/v11-implementation/`
(pack-only maintenance content). Pack Chat will also stage
`test-fixtures/manifest.txt` per RC9.

Per the recently-landed M-1 fix in PLAN §3 H.2 + the CLAUDE.md commit-
subject scope-keyword convention table:

- `pack-only`: DENIED (commit touches `project-template/` and
  `supporting-docs/`).
- `project-only`: DENIED (commit touches `maintenance-docs/`, a pack-only
  surface).
- `PM-only`: DOES NOT APPLY (commit edits non-PM-only files —
  PM-CHAT.md is PM-only per PACK-AGENTS.md but METHODOLOGY.md is not).
- **NO keyword (mixed-scope implicit):** CORRECT per M-1 fix.

Pack Chat handles commit subject construction; coder does not propose
commit subject.

---

## Strict-scope adherence

| Check | Result |
|---|---|
| Only `project-template/docs/pack/PM-CHAT.md` + `supporting-docs/METHODOLOGY.md` edited | PASS |
| No other files modified | PASS |
| No git state changes (`git add`, `git commit`, `git push`, `git tag`, `git rebase`, `git reset`, etc.) | PASS |
| No `test-fixtures/build.sh` invocation (Pack Chat handles RC9 manifest regen post-IMPL-REPORT) | PASS |
| No sibling-chat untracked files (`maintenance-docs/v11-research/`) touched | PASS |
| 8 new PM-CHAT.md bullets + 1 new METHODOLOGY.md callout = 9 in-scope edits | PASS |
| §C.10 + §C.11 sibling annotations use M-3 neutral language (`in this ## Behavioral rules section`) | PASS |
| `git diff --stat` shows only 2 files modified | PASS |
| `git status` shows working-tree edits limited to scope | PASS |

`git status` output at IMPL-REPORT write time:

```
On branch v11-dev
Your branch is up to date with 'origin/v11-dev'.

Changes not staged for commit:
        modified:   project-template/docs/pack/PM-CHAT.md
        modified:   supporting-docs/METHODOLOGY.md

Untracked files:
        maintenance-docs/v11-research/IMPLEMENTATION-REPORT-RESEARCH-TRACKER-PRIMITIVES.md
        maintenance-docs/v11-research/RESEARCH-TRACKER-GROUPING-PRIMITIVES-PER-BACKEND.md
```

The two untracked files in `maintenance-docs/v11-research/` are
sibling-chat artifacts pre-existing in the working tree (per pre-flight
`git status`); they are explicitly OUT OF SCOPE per the calling prompt
("Do NOT touch sibling-chat untracked files in
`maintenance-docs/v11-research/`") and remain untouched.

`git diff --stat`:

```
 project-template/docs/pack/PM-CHAT.md | 109 ++++++++++++++++++++++++++++++++++
 supporting-docs/METHODOLOGY.md        |   9 +++
 2 files changed, 118 insertions(+)
```

Net additions: +109 lines PM-CHAT.md, +9 lines METHODOLOGY.md, 0
deletions. Total +118 lines. Edits are pure insertions (no existing
text removed or modified).

---

## Observations

No nits observed in PM-CHAT.md or METHODOLOGY.md during the read-and-
edit pass. Both files at HEAD f22f800 pre-edit appear well-formed; no
typos, formatting issues, or stale cross-references noticed within the
read scope (Behavioral rules section of PM-CHAT.md; Part 7 Procedure 4
of METHODOLOGY.md).

One drift note (already documented in "Anchor verification" above):
PLAN §1 cross-walk records METHODOLOGY.md Procedure 4 fence-close at
L1219, but HEAD f22f800 pre-edit shows the fence-close at L1259 (+40
lines from H.1). Used durable anchor (fence close → blank line →
`### Procedure 5`) rather than the line number. No PLAN update
recommended — the PLAN cross-walk is a pre-H.1 snapshot, and the M-2
fix language in PLAN §3 H.1 already acknowledges H.1-vs-cross-walk
line-number reconciliation; the durable-anchor matching pattern handles
H.1-induced drift cleanly.

**Spurious working-tree diff on sibling-chat file (NOT caused by this
coder).** At IMPL-REPORT-write `git status` time, the working tree
shows `maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md` as
modified (+1 line). Pre-flight `git status` (recorded at session start
in the very first Bash tool call) showed this file as CLEAN — only
two untracked files in `maintenance-docs/v11-research/` and no
modifications to `REQUIREMENTS-GROUPINGS-V11.md`. This coder made NO
Edit/Write tool calls touching `REQUIREMENTS-GROUPINGS-V11.md`. The
diff content is a single trailing tab character + missing-newline
EOF marker:

```
@@ -906,3 +906,4 @@
 End of REQUIREMENTS-GROUPINGS-V11.md.
+\t
\ No newline at end of file
```

**Probable cause:** background editor/IDE process autosaved a
single-character change to that file mid-session (the file lives in
the sibling-chat artifact tree and may be open in another editor
buffer). This is NOT a coder action. Per scope discipline ("Do NOT
touch sibling-chat untracked files in `maintenance-docs/v11-research/`")
I did NOT touch the file to revert it; that would itself be an
out-of-scope edit. **Disposition request for Pack Chat:** when staging
the H.2 commit, do NOT `git add maintenance-docs/v11-research/
REQUIREMENTS-GROUPINGS-V11.md` — the spurious whitespace diff is not
H.2 scope. If Pack Chat wishes to clean up, `git checkout --
maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md` BEFORE
staging would discard the spurious diff (this is a destructive op
requiring user per-action approval per the "No destructive operations"
trinity rule); alternatively, leave it as a benign working-tree
artifact and address in a separate `fix:` commit.

---

## Files-changed inventory

| Path | Change type | Lines added | Lines deleted |
|---|---|---|---|
| `project-template/docs/pack/PM-CHAT.md` | modified | 109 | 0 |
| `supporting-docs/METHODOLOGY.md` | modified | 9 | 0 |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.2.md` | new | (this file) | 0 |

No deletions. No renames. No new directories.

---

## Definition-of-Done checklist

| Check | Result |
|---|---|
| 8 new bullets added to PM-CHAT.md `## Behavioral rules` per V2 §C/§D + PLAN §3 H.2 step ordering | PASS |
| §C.11 bullet present at correct location (after "Plan before executing.") | PASS |
| §C.13 bullet present immediately after §C.11 | PASS |
| §C.7 bullet present at correct location (after "Follow Prompt Authoring Principles.") | PASS |
| §C.10 bullet present immediately after §C.7 | PASS |
| §C.1 PM-CHAT.md half bullet present at correct location (after "Fix cycle rules.") | PASS |
| §C.4 bullet present at correct location (after "Source file edits.") | PASS |
| §C.9 bullet present immediately after §C.4 | PASS |
| §C.8 bullet present at correct location (after "Pack feedback loop.") | PASS |
| 1 new `>` callout added to METHODOLOGY.md Part 7 Procedure 4 per V2 §D.5 | PASS |
| §C.10 + §C.11 sibling annotations use M-3 neutral language | PASS |
| All 9 bullet/callout contents match V2 AFTER text verbatim (modulo M-3 sibling-annotation neutral-language wording) | PASS |
| No other edits to PM-CHAT.md or METHODOLOGY.md | PASS |
| No other files touched | PASS |
| No git state changes | PASS |
| No `test-fixtures/build.sh` invocation by coder (Pack Chat handles RC9 manifest regen) | PASS |
| IMPL-REPORT written to specified maintenance-docs/ path | PASS |
| PREFLIGHT line emitted before IMPL-REPORT write | PASS |

---

## Plan deviations

**None.** All 9 edits applied exactly per PLAN §3 H.2 + V2 §C/§D source
sections. Insertion order: top-to-bottom by source-file line position
(Edit 1 → Edit 2 at L182 area, Edit 3 → Edit 4 at L220 area, Edit 5 at
L263 area, Edit 6 → Edit 7 at L277 area, Edit 8 at L319 area, Edit 9
in METHODOLOGY.md at L1259 area). Top-down ordering keeps each Edit's
`old_string` anchor unambiguous (no later Edit invalidates an earlier
Edit's anchor; anchors all stable through the sequence).

---

## New POQs introduced

**None.** All 9 edits within in-plan-scope. No new architecture
questions surfaced during implementation.

---

## PREFLIGHT line

```
PREFLIGHT: 9/9 in-scope file edits complete; verification PASS; HEAD f22f800; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.2.md
```

(Emitted in chat to Pack Chat parent session before this IMPL-REPORT
Write call commenced.)
