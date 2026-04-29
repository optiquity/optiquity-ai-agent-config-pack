# V10-PROMPT-STRUCTURE-PLAN

**Author:** pack-planner (Phase 4 planner pass)
**Date:** 2026-04-28
**Implements:** `maintenance-docs/V10-PROMPT-STRUCTURE-DESIGN.md`
**Status:** Draft — planner output. Read-only on every pack source.
No edits, no commits.

---

## 0. Status and supersession

This plan implements `V10-PROMPT-STRUCTURE-DESIGN.md` (architect pass,
2026-04-28). It supersedes nothing — it adds detail (per-file edit
specs, commit sequence, verification gates, BD-049 entry text) that the
design pass deliberately deferred to the planner.

The design pass's eight pre-resolved decisions (D1–D8 in §1 of the
design) are inputs to this plan and are NOT re-litigated. The four
open questions the architect surfaced (Q1–Q4 in §8 of the design)
have been resolved by the project lead and the resolutions are baked
into this plan:

- **Q1 — RESOLVED Q1b.** In `coder.md` Variant: fix-cycle, the per-fix
  middle label is renamed `Expected behavior:` → `Goal:` for label
  consistency with the prompt-level triad.
- **Q2 — RESOLVED Q2b.** `pm-chat.md` Variant: kickoff gets a separate
  one-line callout immediately under the existing italic descriptor,
  with the wording specified by the project lead (verbatim text in
  §1.8 below).
- **Q3 — RESOLVED IN SCOPE.** `validate-pack.py` gains a new check
  enforcing the labeled triad on every in-scope prompt template
  variant. The check is in scope for v10.0 (not deferred). Pack Chat
  edits `validate-pack.py` per a follow-on detailed prompt the
  implementer drafts after this planner pass; Pack Chat does not act
  until that prompt exists. **Numbering RESOLVED per O1a (project lead,
  2026-04-28):** the new check is numbered **Check 10** (next available
  in the script, which currently ships Checks 1–9). The earlier "Check
  11" label in upstream prompts was a mis-statement; this plan uses
  Check 10 throughout.
- **Q4 — RESOLVED Q4b.** The multi-part phase header convention moves
  from `PROMPT-AUTHORING.md` to `METHODOLOGY.md` § Prompt Authoring
  Principles, lodged adjacent to the file-based-reporting subsection
  as either a named subsection or paragraph. `PROMPT-AUTHORING.md`
  collapses to a true one-line cross-reference plus a brief
  directory-level starting-points paragraph per the design's §6
  closing prose.

**Goal addressed.** This plan covers BD-049 (the new backlog entry the
implementation lands; entry text in §7) and closes the gap the audit
identified between the pack's stated Prompt Authoring Principles and
the actual content of the ten prompt templates that ship.

**Files affected by this work** (full list; sources before any edit):

Pack-product files (project-template/ + supporting-docs/):
1. `project-template/docs/pack/prompts/architect.md` — Variant: mid-phase
2. `project-template/docs/pack/prompts/auditor.md` — Variant: standard
3. `project-template/docs/pack/prompts/coder.md` — Variants: standard + fix-cycle
4. `project-template/docs/pack/prompts/docs-researcher.md` — Variant: standard
5. `project-template/docs/pack/prompts/grpc-schema.md` — placeholder (no body change; mention only)
6. `project-template/docs/pack/prompts/planner.md` — Variant: standard
7. `project-template/docs/pack/prompts/pm-chat.md` — 4 variants (1 out, 3 in)
8. `project-template/docs/pack/prompts/repo-ops.md` — placeholder (no body change; mention only)
9. `project-template/docs/pack/prompts/reviewer.md` — Variant: standard
10. `project-template/docs/pack/prompts/tester.md` — Variant: standard
11. `project-template/docs/pack/prompts/PROMPT-AUTHORING.md` — collapse to one-line cross-reference
12. `supporting-docs/METHODOLOGY.md` — § Prompt Authoring Principles replacement + multi-part header subsection move-in

Pack-repo operational / scripts:
13. `scripts/validate-pack.py` — add new check (Pack Chat edits per follow-on prompt)
14. `BACKLOG.md` — add BD-049 entry (Pack Chat edits per follow-on prompt)

Reference / supersession docs (already on disk; carried forward, no edit):
15. `maintenance-docs/V10-PROMPT-STRUCTURE-DESIGN.md` — already on disk (architect output)
16. `maintenance-docs/V10-PROMPT-STRUCTURE-PLAN.md` — this file (planner output)

Files that are NOT touched (called out for clarity):
- `project-template/CLAUDE.md`, `project-template/AGENTS.md`,
  `project-template/GEMINI.md` — trinity-ruled context files; not
  affected by this work (rationale in §5).
- Pack-repo trinity copies (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md` at
  the pack repo root) — not affected.
- `PACK-CHAT.md`, `PACK-AGENTS.md` — operational; not affected.
- `README.md` version table — not affected (PM-chat-only territory;
  no version bump triggered by this work — it lands as additional
  v10.0 work pre-ship).
- `CHANGELOG.md` — not edited until v10.0 ship (project-lead direction
  per CLAUDE.md "version boundaries with explicit instruction").
- `project-template/docs/pack/PM-CHAT.md` — already references
  `docs/pack/prompts/PROMPT-AUTHORING.md` and METHODOLOGY's Prompt
  Authoring Principles. The references survive verbatim since both
  files continue to exist (PROMPT-AUTHORING as one-liner; METHODOLOGY
  with replaced section). Verified in §6 cross-reference sweep.
- All `.claude/agents/`, `.codex/agents/`, `.gemini/agents/` agent
  definition files — agent prompts (the templates) and agent definition
  files (the per-tool persona files) are different artifacts; the
  former is what this work edits, the latter is unaffected.
- `scripts/init-project.sh`, `scripts/lib/detect.sh`, migration scripts
  — unaffected.
- `.github/workflows/validate-pack.yml` — unaffected; the workflow
  re-runs `validate-pack.py` and inherits the new check automatically.


---

## 1. Per-file edit specifications

Each subsection below names line ranges in the **current** file
(pre-edit), the canonical-section skeleton the variant must end up
matching after the implementation pass, and the file-based-reporting
sub-case (A or B per design §4) the variant inherits. The implementer
writes the actual prose at execution time; this plan does not draft
the prose.

**Canonical section order (from D3, used in every "Skeleton" block
below):**

1. **Role + agent identity** — already present as the variant H2
   heading + italic descriptor. Keep as-is unless noted.
2. **Context:** — bolded inline label
3. **Required reading:** — bolded inline label
4. **Problem:** — bolded inline label
5. **Goal:** — bolded inline label
6. **Success criteria:** — bolded inline label
7. **Files in scope:** — bolded inline label
8. **Constraints:** — bolded inline label
9. **Out of scope:** — bolded inline label (omit when redundant with
   Constraints, per D3 note 9)
10. **Completion report:** — bolded inline label; sub-case A or B per
    §4 of the design

Skeleton blocks below use `**Label:**` notation to mean "bolded inline
label, content follows on the same line or as an indented bullet
list." Existing prose in the variant (procedure, format requirements,
output shape) is preserved and re-grouped under the section it
belongs to (Constraints or Completion report). The implementer does
NOT rewrite preserved prose; they re-locate it under the appropriate
labeled section.

---

### 1.1 `architect.md` — Variant: mid-phase

**Current state.** File is 51 lines. Variant body lines 9–51. Has:
- Lines 9–14: variant H2 + four italic descriptors
- Lines 16–17: read-only callout (blockquote)
- Lines 19–21: required-reading prose ("Read ARCHITECTURE.md…")
- Lines 23–25: bolded label `**Context — why this architect pass was triggered:**` + placeholder
- Lines 27–28: bolded label `**Reviewer findings that this pass must address:**` + placeholder
- Lines 30–33: bolded label `**Your task:**` + prose
- Lines 35–47: numbered list (1–3) for root-cause identification + the proposed-change format block
- Lines 49–50: closing constraints prose ("Do not propose source code changes…")

**REPORT FILE sub-case.** A (architect produces a markdown analysis
report).

**Skeleton (target state).**

```
## Variant: mid-phase

*[existing italic descriptors — preserve all four lines 11–14]*

> [existing read-only callout — preserve lines 16–17]

**Context:** [migrate the prose from current `**Context — why this architect
pass was triggered:**` block. Keep the placeholder.]

**Required reading:** [migrate lines 19–21 prose: ARCHITECTURE.md, IMPLEMENTATION_PLAN.md
Phase [N], CLAUDE.md, AGENTS.md, plus reviewer-flagged files placeholder.]

**Reviewer findings that this pass must address:** [migrate the lines 27–28 placeholder block;
this is a sub-element of the Context, but is preserved as a labelled inline
sub-block per the existing prompt shape.]

**Problem:** The recurring or worsening reviewer-finding pattern indicates that
the design documentation is ambiguous, incomplete, or incorrect — not that the
coder is making mistakes. Identify the root cause(s) in the design layer.

**Goal:** Produce a list of named root causes (one per identified design defect),
each tied to the specific section of the specific document that contains the
problem, with proposed exact text changes to ARCHITECTURE.md, IMPLEMENTATION_PLAN.md,
CLAUDE.md, or AGENTS.md.

**Success criteria:**
- Every reviewer finding listed in `**Reviewer findings…**` is traced to one
  or more named root causes.
- Each root cause has a `**Proposed change [N] — [Document name], [Section name]**`
  block in the format specified below.
- No source code changes proposed; no build/test commands run.

**Files in scope:** None (read-only). Output is a proposed-change list only.

**Constraints:** Read-only analysis pass. Do not modify any files. Do not propose
source code changes. Do not run any build or test commands. Output proposed doc
changes only.

**Completion report:**
REPORT FILE: `<PM-chat-supplied path; e.g., /tmp/architect-mid-phase-N.md>`

Format each proposed change as:

**Proposed change [N] — [Document name], [Section name]**
Root cause: [explanation]
Current text: [quote the existing text]
Proposed replacement: [exact new text]
Why this fixes it: [explanation]
```

**Notes for the implementer.**
- The existing root-cause-identification numbered list (lines 35–40 of the
  current file: "Name it precisely — which section…", "Explain why…",
  "Propose the exact text change…") is **format guidance for the proposed-
  change blocks**; preserve it as instructional prose under Completion report
  immediately above the proposed-change block specimen.
- The "Reviewer findings that this pass must address:" sub-block is a piece
  of dynamic context the PM chat fills in; it is the input to the Problem
  section (the agent reads it to recognize the pattern). Keep it as a labelled
  sub-block under Context (or immediately after Context) — do not promote it
  to a top-level section; it is data, not a prompt section.
- Preserved prose: every word of the proposed-change block format
  (lines 41–47) survives verbatim — it IS the format requirement (per design
  §3 row "architect").

---

### 1.2 `auditor.md` — Variant: standard

**Current state.** File is 85 lines. Variant body lines 9–65 (the
Templates 10–12 superseded section, lines 67–84, is informational and
out of scope for triad addition — it is post-variant footer prose).
Variant has:
- Lines 9–14: H2 + italic descriptor
- Line 16: opening prose ("You are the audit coordinator…")
- Lines 19–24: bolded label `**Skip rules for this project:**` + placeholder
- Lines 26–35: bolded label `**Platform skills to load per subagent**` + per-subagent list
- Lines 37–42: bolded label `**File scope guidance.**` + always-exclude list
- Lines 44–48: bolded label `**Spawn the subagents**` + per-tool mechanism
- Lines 50–62: bolded label `**Consolidate the reports**` + numbered list (1–4)
- Lines 64–65: bolded label `**Constraint:**` + closing prose

**REPORT FILE sub-case.** A (auditor parent produces a consolidated
markdown report).

**Skeleton (target state).**

```
## Variant: standard

*[existing italic descriptor lines 11–14 — preserve all four]*

**Context:** [Brief framing — the project requires a full-codebase structural audit
(or a fix-verification audit). The PM chat fills in the trigger.]

**Required reading:** `audit-methodology` skill (loaded by the parent only). Each
spawned subagent loads the platform skills listed in `**Platform skills to load per
subagent**` below from PLATFORM-SKILLS.md.

**Problem:** The codebase has not had a recent full-codebase structural audit
across the seven cluster dimensions (security, architecture, tests, ops, code,
ui, docs), or a fix-verification audit is needed against a known set of prior
findings.

**Goal:** A consolidated report containing the executive summary plus per-cluster
subagent reports, with skipped clusters disclosed and findings deduplicated per
ownership precedence.

**Success criteria:**
- Executive summary present per `audit-methodology` rules 11–13: total findings
  per severity, top 3 issues (highest severity first; tie-break by cluster
  order from rule 38), pass/fail verdict, skipped subagents with reason.
- All non-skipped subagent reports appended in cluster order (rule 53):
  security → architecture → tests → ops → code → ui → docs.
- Duplicate findings resolved per ownership precedence rules 33–39 with
  surviving entries annotated `(also detected by: <other-clusters>)`.
- `## Next steps` section appended listing Critical and Major findings in
  priority order, cross-referencing METHODOLOGY.md Part 6 BACKLOG processing.

**Files in scope:** None (read-only audit). Output is the consolidated report only.

**Constraints:**
- Read-only audit. Do not write to BACKLOG.md, STATUS.md, or any other project file.
- **Skip rules for this project:** [PM CHAT FILLS — preserve the existing
  placeholder prose lines 19–24 verbatim]
- **Platform skills to load per subagent:** [preserve lines 26–35 verbatim]
- **File scope guidance:** [preserve lines 37–42 verbatim — always-exclude
  globs from rule 25]
- **Spawn the subagents:** [preserve lines 44–48 verbatim — per-tool mechanism]

**Completion report:**
REPORT FILE: `<PM-chat-supplied path; e.g., /tmp/audit-report-YYYY-MM-DD.md>`

Consolidate per rules 48–55:
[preserve the existing numbered consolidation procedure (lines 50–62) verbatim
here — it is the format spec for the report's body.]
```

**Notes for the implementer.**
- The "Templates 10–12 — Superseded" footer (current lines 67–84) is
  preserved verbatim BELOW the Variant: standard body. It is not part
  of the variant; it is documentation. Do not move or relabel it.
- Preserved prose: the skip rules placeholder, the platform-skills loadout
  list, the file-scope guidance with the always-exclude globs, the spawn-
  the-subagents per-tool list, and the consolidate-the-reports numbered
  procedure (1–4). All are format requirements per design §3 row "auditor."
- The current line 65 ("Return the consolidated report to the developer.")
  is replaced by the explicit `REPORT FILE:` line under Completion report.

---

### 1.3 `coder.md` — Variant: standard

**Current state.** File is 165 lines covering both variants. Variant: standard
body lines 10–84. Has:
- Lines 10–12: H2 + italic descriptor
- Lines 14–15: required-reading prose ("Read ARCHITECTURE.md…")
- Lines 17–26: bolded label `**Scope constraint:**` + escape-valve prose
- Lines 28–31: bolded label `**Root .md file prohibition:**`
- Lines 33–43: bolded label `**Deferral comments:**` + format spec
- Line 45: bolded label `**Next available TD number…:**`
- Lines 47–55: bolded label `**Tasks:**` + numbered task placeholder block
  with per-task DOD
- Lines 56–61: bolded label `**Verification:**` + script invocations
- Lines 63–70: bolded label `**Completion report:**` + report header line +
  proposed-CHANGELOG-entry instruction
- Lines 72–76: bolded label `**Unplanned file modifications**` + format spec
- Lines 78–84: bolded label `**Deferred items**` + format spec

**REPORT FILE sub-case.** A (coder produces a markdown completion report).

**Skeleton (target state).**

```
## Variant: standard

*[existing italic descriptor line 12 — preserve]*

**Context:** [PM chat fills in: Phase [N] of IMPLEMENTATION_PLAN.md is the next
implementation phase, and the listed tasks below are not yet implemented.]

**Required reading:** ARCHITECTURE.md (full), CHANGELOG.md, IMPLEMENTATION_PLAN.md
Phase [N] (full), and the specific files in the **Files in scope** list below.

**Problem:** Phase [N] tasks are not yet implemented.

**Goal:** Each task in the **Tasks** list below is implemented per its
Definition of done. Verification suite passes with zero compiler warnings.
Any work that cannot be completed in this phase is reported via deferral
comments and the Deferred items section, not silently skipped.

**Success criteria:**
- All tasks complete per their per-task Definition of done.
- `./scripts/format.sh` and `./scripts/validate.sh` exit 0 with zero warnings.
- Completion report present, beginning with the header line specified under
  Completion report.
- "Unplanned file modifications" and "Deferred items" sections present
  (with "None" if nothing to report).

**Files in scope:** [PM chat fills — explicit list of files the coder may
create or modify. Files NOT on this list trigger the escape valve documented
under Constraints.]

**Tasks:** [preserve current Tasks block lines 47–55: numbered list, per-
task with Files-to-create / Files-to-modify / Definition of done. The Tasks
list lives under Goal as task-scope detail per D4.]

**Constraints:**
- **Scope constraint:** [preserve current scope-constraint paragraph
  lines 17–26 verbatim — escape-valve text for unlisted files.]
- **Root .md file prohibition:** [preserve lines 28–31 verbatim.]
- **Deferral comments:** [preserve lines 33–43 verbatim — typed format
  rules and TD-TBD discipline.]
- **Next available TD number (for PM chat reference only — coder writes
  TD-TBD):** TD-[NNN]
- **Verification:** [preserve lines 56–61 verbatim — format.sh and
  validate.sh invocations and the zero-warning expectation.]

**Completion report:**
REPORT FILE: `<PM-chat-supplied path; e.g., /tmp/coder-phase-N-pass-1.md>`

Begin the report with this header line as the very first line of output:
`Phase [N] — [Phase title] — Coder Report, Pass 1`

Then report which files were modified and the final test count.
[If this is the last task in the phase:] Include a **"Proposed CHANGELOG
entry"** section in this report, formatted exactly as it would appear in
`CHANGELOG.md`: dated header, summary paragraph, files created/modified
list, and test count. Do not write to `CHANGELOG.md` or any other `.md`
file in the project root — the PM chat applies the entry after reviewer
approval.

**Unplanned file modifications** (required section — write "None" if no
unlisted files were changed): [preserve format spec lines 72–76 verbatim]

**Deferred items** (required section — write "None" if nothing was
deferred): [preserve format spec lines 78–84 verbatim]
```

**Notes for the implementer.**
- D4 binding: per-task Definition of done remains inside each task entry
  in the Tasks list (under Goal). It is task-scope detail, not a substitute
  for prompt-level Success criteria.
- Preserved prose: scope-constraint, root-md prohibition, deferral-comment
  rules, verification commands, the entire Completion-report shape
  (including header line, Unplanned-file-modifications, Deferred items)
  are format requirements per design §3 row "coder."
- The "Next available TD number" line is a PM-chat-supplied data field
  (not a section); keep it under Constraints adjacent to the Deferral
  comments rule for proximity.

---

### 1.4 `coder.md` — Variant: fix-cycle

**Current state.** File continues lines 86–165. Variant: fix-cycle has:
- Lines 86–89: H2 + italic descriptor (with the explicit "PM chat must
  describe problems, not solutions" callout)
- Lines 92–94: callout blockquote
- Lines 96–97: required-reading prose
- Lines 99–102: bolded label `**Root .md file prohibition:**`
- Lines 104–109: prose paragraph ("The reviewer found the following…")
- Lines 111–115: per-fix block 1 (`**❌ Fix 1 — [Issue title]**` /
  `File:` / `Problem:` / `Expected behavior:` / `Success criteria:`)
- Lines 117–121: per-fix block 2 (same shape)
- Lines 123–131: bolded label `**Deferral comments:**` + format spec
- Lines 133–137: bolded label `**Verification:**`
- Lines 139–146: bolded label `**Completion report:**` + header + Fixes
  applied list
- Line 145: `**Files modified:**`
- Lines 147–150: bolded label `**Unplanned file modifications**`
- Lines 152–158: bolded label `**Deferred items**`
- Line 160: `**Validation:**`
- Lines 162–164: closing **Note:** about CHANGELOG handling

**REPORT FILE sub-case.** A (coder produces a markdown fix-cycle
completion report).

**Q1b application.** Rename the per-fix middle label `**Expected behavior:**`
to `**Goal:**` in BOTH per-fix block specimens (current lines 114 and 120).
Update the inline reference in the body prose at line 105 ("Fix each issue
so that it meets the expected behavior described.") to reference "Goal" or
"the goal described" — the implementer chooses the smoothest wording at
execution time but must update the reference for consistency.

**Skeleton (target state).**

```
## Variant: fix-cycle

*[existing italic descriptor lines 88–89 — preserve]*

> [existing PM-chat-must-describe-problems callout, lines 92–94 — preserve verbatim]

**Context:** [PM chat fills in: reviewer pass [N-1] returned ❌ findings that
the coder must resolve before the phase can advance. The fix plan has been
presented to the user and approved.]

**Required reading:** ARCHITECTURE.md (full), IMPLEMENTATION_PLAN.md Phase [N],
and the specific files listed below.

**Problem:** The reviewer's pass-[N-1] findings indicate behavior in the
implemented code that does not match the architecture or implementation plan.
Each ❌ entry below names what is wrong, what correct behavior looks like, and
how the reviewer will verify the fix.

**Goal:** Each ❌ fix listed below is applied so that the reviewer's described
correct behavior holds.

**Success criteria:**
- Re-review (pass [N]) marks all listed ❌ items resolved.
- Verification suite passes with zero warnings.
- Deferred items reported via the typed-comment + Deferred-items section.

**Files in scope:** [PM chat fills — files affected by the listed fixes,
plus the same escape valve as the standard variant for unlisted supporting
files.]

**Fixes (one entry per ❌ item — these are task-scope detail under Goal):**

**❌ Fix 1 — [Issue title]**
File: `[path/to/file]`
Problem: [exact description of what is wrong and why]
**Goal:** [what correct behavior looks like — no implementation instructions]
Success criteria: [what the reviewer will check to confirm this fix is complete]

**❌ Fix 2 — [Issue title]**
File: `[path/to/file]`
Problem: [exact description of what is wrong and why]
**Goal:** [what correct behavior looks like — no implementation instructions]
Success criteria: [what the reviewer will check to confirm this fix is complete]

**Constraints:**
- **Root .md file prohibition:** [preserve lines 99–102 verbatim]
- **Escape valve:** [preserve the lines 104–109 paragraph about supporting
  files and Unplanned file modifications]
- **Deferral comments:** [preserve lines 123–131 verbatim]
- **Verification:** [preserve lines 133–137 verbatim — includes the
  [VERIFICATION COMMAND] placeholder]

**Completion report:**
REPORT FILE: `<PM-chat-supplied path; e.g., /tmp/coder-phase-N-fix-pass-2.md>`

Begin the report with this header line as the very first line of output:
`Phase [N] — [Phase title] — Fix Cycle Coder Report, Pass [N]`

**Fixes applied** (one entry per ❌ item addressed): [preserve lines 142–143]

**Files modified:** [list all files changed]

**Unplanned file modifications** (required section — write "None" if no
unlisted files were changed): [preserve lines 147–150 verbatim]

**Deferred items** (required section — write "None" if nothing was
deferred): [preserve lines 152–158 verbatim]

**Validation:** [test count and confirmation that zero warnings remain]

**Note:** [preserve lines 162–164 — CHANGELOG handling note]
```

**Notes for the implementer.**
- Q1b is the ONLY semantic wording change in this variant. Every other
  word of the per-fix shape, the deferral rules, the verification
  block, and the completion-report block survives verbatim.
- The per-fix triad (Problem / Goal / Success criteria) lives under Goal
  as task-scope detail. The prompt-level triad sits above. Two triads,
  different scopes — D4 + the design §1 D4 rationale + design §7 row E
  cover this.
- The "PM chat must describe problems, not solutions" callout (lines
  92–94) is a format-and-discipline requirement and stays in its
  current position immediately after the italic descriptor. Do not
  move it under Constraints — its prominence is the point.

---

### 1.5 `docs-researcher.md` — Variant: standard

**Current state.** File is 39 lines. Variant body lines 9–39:
- Lines 9–11: H2 + italic descriptor
- Line 13: required-reading prose
- Lines 15–16: inline goal ("Your job is to VERIFY…")
- Lines 18–24: bolded label `**Items to verify:**` + numbered placeholder list
- Lines 26–35: bolded label `**Output format:**` + header line + ✅/⚠️ block format
- Lines 37–38: closing prose (cite sources, no code changes)

**REPORT FILE sub-case.** A.

**Skeleton (target state).**

```
## Variant: standard

*[existing italic descriptor line 11 — preserve]*

**Context:** [PM chat fills — Phase [N] of the implementation plan depends on
external claims (API behavior, framework feature, doc reference) that may have
drifted from current official documentation.]

**Required reading:** ARCHITECTURE.md §[RELEVANT SECTIONS], IMPLEMENTATION_PLAN.md
Phase [N].

**Problem:** Phase [N] depends on external assumptions that may have drifted
from current official documentation. Drift could cause the implementation to
fail or produce incorrect behavior.

**Goal:** Each claim in the **Items to verify** list below is checked against
current official documentation. Discrepancies are flagged with the required
change.

**Success criteria:**
- Every listed claim has either ✅ CONFIRMED + source URL or a ⚠️ DISCREPANCY
  block with What-the-plan-assumes / What-the-docs-actually-say / Impact /
  Required-change fields filled in.
- Source cited for every fact (no unverified statements).
- Report header line correct (per Completion report below).
- Confirmed facts are separated from unverified assumptions in the report.

**Files in scope:** None (read-only research). Output is the verification report only.

**Items to verify:** [preserve lines 18–24 — numbered list with claim + URL
placeholders. This list lives under Goal as the per-claim task scope.]

**Constraints:** Read-only research pass. Do not make any code changes.

**Completion report:**
REPORT FILE: `<PM-chat-supplied path; e.g., /tmp/docs-researcher-phase-N.md>`

Begin the report with this header line as the very first line of output:
`Phase [N] — [Phase title] — Docs-Researcher Report`

Then list findings:
- ✅ CONFIRMED — [topic]: [evidence + source URL]
- ⚠️ DISCREPANCY — [topic]:
  What the plan assumes: [...]
  What the docs actually say: [...]
  Impact: [...]
  Required change: [...]

Separate confirmed facts from unverified assumptions. Cite sources for everything.
```

**Notes for the implementer.**
- The ✅/⚠️ block shape and citation discipline are format requirements per
  design §3 row "docs-researcher" — preserve verbatim under Completion report.
- "Items to verify" is dynamic content (PM chat fills the list); lives under
  Goal as task-scope detail.

---

### 1.6 `grpc-schema.md` — placeholder (no body change)

**Current state.** File is 11 lines. `variants: []` in frontmatter. No
variant bodies ship.

**Disposition.** No file edit required. The METHODOLOGY mandate (per
§1.11 below) covers any future variant added here. Mention only — no
template skeleton applies because there is no current variant body.

**Notes for the implementer.**
- Do NOT touch this file as part of the implementation pass unless a
  semantic change is needed elsewhere (none identified).
- If a future PR adds a variant, that PR's author MUST follow the
  convention specified in METHODOLOGY.md § Prompt Authoring Principles
  (post-implementation state). Validate-pack.py Check 10 (§2 below)
  enforces compliance automatically once the variant exists.

---

### 1.7 `planner.md` — Variant: standard

**Current state.** File is 28 lines. Variant body lines 9–28:
- Lines 9–11: H2 + italic descriptor
- Lines 13–14: required-reading prose
- Line 16: inline goal ("Break Phase [N] into ordered implementation tasks…")
- Lines 17–20: per-task bullet list
- Lines 22–23: dependencies + risk-ranking prose
- Lines 25–27: header line + closing constraint

**REPORT FILE sub-case.** A.

**Skeleton (target state).**

```
## Variant: standard

*[existing italic descriptor line 11 — preserve]*

**Context:** [PM chat fills — Phase [N] is too complex to send to the coder
without an ordered task breakdown.]

**Required reading:** ARCHITECTURE.md (full), IMPLEMENTATION_PLAN.md Phase [N],
and the listed relevant files.

**Problem:** Phase [N] is too complex to send to the coder without a task
breakdown — the implementation order, the dependencies between tasks, and the
risk-ranking are not yet specified at a level the coder can execute against.

**Goal:** An ordered task list for Phase [N] with per-task Definition of done,
dependencies between tasks identified, and the highest-risk task surfaced with
an approach suggestion.

**Success criteria:**
- Report contains the task list, each task with what / files / DOD / risk.
- Dependency edges between tasks named (which must complete before another
  can start).
- Highest-risk task identified with a suggested approach for tackling it first.
- Report header line correct (per Completion report below).

**Files in scope:** [PM chat fills — the relevant files the planner reads to
understand Phase [N]. Read-only.]

**Constraints:** Read-only planning pass. Output is the task breakdown and risk
analysis only. Do not write any code.

**Completion report:**
REPORT FILE: `<PM-chat-supplied path; e.g., /tmp/planner-phase-N.md>`

Begin the output with this header line as the very first line:
`Phase [N] — [Phase title] — Planner Report`

For each task:
- What exactly needs to be done
- Which files will be created or modified
- What the verifiable definition of done is
- What the risk is and how to detect a problem early

Name any dependencies between tasks (which must complete before another can
start). Identify the highest-risk task and suggest how to approach it first.
```

**Notes for the implementer.**
- Per-task field shape (what / files / DOD / risk) and dependency-edge naming
  are format requirements per design §3 row "planner" — preserve under
  Completion report.

---

### 1.8 `pm-chat.md` — Variant: kickoff (OUT of scope)

**Current state.** File is 220 lines covering 4 variants. Variant: kickoff
body lines 18–90. Has italic descriptor at lines 20–21 (current wording:
*"Paste this at the start of a new PM chat session to establish project
context." / "Fill in all [PLACEHOLDERS] before pasting."*).

**Disposition.** Convention does NOT apply (per design §5 + Q2b
resolution). Body is preserved verbatim EXCEPT one insert.

**Q2b insert (verbatim wording).** Immediately after the existing
italic descriptor at line 21 and before the "Before pasting:" block at
line 23, insert this one-line callout (Markdown):

```
**Convention exception:** kickoff is a context handoff, not an agent-task prompt. The labeled-section convention does not apply. All other variants and all other prompt files in this directory follow it.
```

The callout is a single bolded-label inline line. No surrounding
blockquote, no list bullet — bolded inline label so the syntactic
shape parallels the labeled-section convention while not being a
section per se. Preserve exactly one blank line between the italic
descriptor and the callout, and one blank line between the callout
and the "Before pasting:" block.

**Notes for the implementer.**
- Validate-pack.py Check 10 (§2 below) detects the callout via a
  literal substring match against the marker text (specifically the
  literal `**Convention exception:**`) so the kickoff variant is the
  ONE exempt variant. The exact substring is what the check keys on;
  verbatim wording matters.
- No other body change to the kickoff variant. Lines 23–90 remain as
  they currently are (R/I/E/M Procedure 7 prose, surface declaration,
  PM-CHAT.md customization, Active skills line, etc.).

---

### 1.9 `pm-chat.md` — Variant: backlog-status-update (IN scope, sub-case B)

**Current state.** Variant body lines 91–142:
- Lines 91–95: H2 + italic descriptor + approval-gate banner
- Lines 96–97: "Read BACKLOG.md… Make exactly the following changes." prose
- Lines 99–116: BACKLOG-entry schema block
- Lines 118–124: Resolved/Cancelled/Deprecated handling block
- Lines 130–141: STATUS.md update block (phase title link convention etc.)
- Line 142: "Confirm what was changed."

**REPORT FILE sub-case.** B (target file is BACKLOG.md and/or
STATUS.md). No separate `REPORT FILE:` line; the artifact IS the
target file edit.

**Skeleton (target state).**

```
## Variant: backlog-status-update

*[existing italic descriptor lines 93–94 — preserve]*

**Context:** A BACKLOG and/or STATUS state-change requires recording. The PM
chat composes this prompt against itself after explicit user approval.

**Required reading:** BACKLOG.md (full), and/or STATUS.md (full), depending
on which file(s) the change targets.

**Problem:** A BACKLOG/STATUS state-change is required (new entry, status
flip, resolution, phase advance, etc.) and has been approved by the user.

**Goal:** The named entries are updated per the listed schema below. No other
files touched.

**Success criteria:**
- Exact entries exist with the prescribed BACKLOG-entry shape (per the schema
  block below).
- Phase-title links in STATUS.md validate (anchor format per the rule below).
- Cancelled/Deprecated items have flag-for-review applied to dependents.
- The artifact (BACKLOG.md and/or STATUS.md edits) is the target file edit
  itself; no separate report file is needed (sub-case B).

**Files in scope:** BACKLOG.md and/or STATUS.md only. No other file is
modified.

**Constraints:** PM chat self-prompt. Requires explicit user approval before
executing. Do not modify any other file.

**[Schema and update blocks — preserve current lines 99–141 verbatim:]**

[BACKLOG entry schema block — current lines 99–116]
[Resolved/Cancelled/Deprecated handling block — current lines 118–124]
[STATUS.md update block including phase-title link convention — current
lines 130–141]

**Completion report:** The artifact is the target-file edit itself (sub-case
B). Confirm what was changed by naming the file(s) edited and the change
summary inline in chat — no separate REPORT FILE.
```

**Notes for the implementer.**
- Sub-case B distinguisher: target-file edit IS the artifact. The
  Completion report section names the target file and the change
  summary; no `REPORT FILE:` path placeholder.
- Format requirements per design §3 (schema, link conventions, anchor
  rules) live under Constraints + Completion report by virtue of
  preserving lines 99–141 verbatim under those sections.
- The current line 142 ("Confirm what was changed.") survives as the
  final line of the variant under the Completion-report instruction.


---

### 1.10 `pm-chat.md` — Variant: generate-setup (IN scope, sub-case B)

**Current state.** Variant body lines 144–163:
- Lines 144–146: H2 + italic descriptor
- Lines 148–149: required-reading + framing prose
- Lines 151–160: bullet placeholder list
- Lines 162–163: closing prose ("Remove any sections that don't apply…
  Output the complete SETUP.md content ready to save…")

**REPORT FILE sub-case.** B (target file is `SETUP.md` written at
project root).

**Skeleton (target state).**

```
## Variant: generate-setup

*[existing italic descriptor line 146 — preserve]*

**Context:** A new project has no `SETUP.md`. The PM chat fills in the pack's
SETUP_TEMPLATE.md with values from the planning conversation.

**Required reading:** `supporting-docs/SETUP_TEMPLATE.md` from the AI Agent
Config Pack, plus the planning conversation context already in the PM chat
session.

**Problem:** The project has no `SETUP.md`.

**Goal:** A complete `SETUP.md` produced from the pack template, with all
relevant placeholders filled and inapplicable sections removed.

**Success criteria:**
- Output is a single complete `SETUP.md` ready to save to the project root.
- All listed placeholder values (per the placeholder list below) are answered.
- No template-only HTML comment block remaining at the top.
- Sections that don't apply to this project are removed.

**Files in scope:** Project-root `SETUP.md` (sub-case B — target file IS the
artifact).

**[Placeholder list — preserve current lines 151–160 verbatim:]**
[Placeholder list block]

**Constraints:** PM chat self-prompt. Output the complete file content; do
not partially fill or skip placeholders.

**Completion report:** The artifact is `SETUP.md` written at the project
root (sub-case B). No separate REPORT FILE.
```

**Notes for the implementer.**
- Sub-case B handling identical to §1.9.
- Preserved prose: the placeholder bullet list (lines 151–160) is data
  the PM chat fills in; lives under Goal as task-scope detail.

---

### 1.11 `pm-chat.md` — Variant: generate-agent-kickoff (IN scope, sub-case B)

**Current state.** Variant body lines 165–219:
- Lines 165–167: H2 + italic descriptor
- Lines 169–172: required-reading + framing prose
- Lines 173–213: bullet placeholder list including the structural-decisions
  checklist (type-erasure, notification, ViewModel-navigation Notes blocks)
- Lines 214–215: closing instructions ("Remove sections that don't apply…")
- Lines 216–219: developer-paste-into-CLI guidance

**REPORT FILE sub-case.** B (target file is `AGENT_KICKOFF.md` written
at project root).

**Skeleton (target state).**

```
## Variant: generate-agent-kickoff

*[existing italic descriptor line 167 — preserve]*

**Context:** The architect kickoff session has no kickoff brief. The PM chat
fills in the pack's AGENT_KICKOFF_TEMPLATE.md with values from the architecture
planning conversation.

**Required reading:** `supporting-docs/AGENT_KICKOFF_TEMPLATE.md` from the AI
Agent Config Pack, plus the architecture planning conversation context already
in the PM chat session.

**Problem:** The architect kickoff session has no `AGENT_KICKOFF.md` brief.

**Goal:** A complete `AGENT_KICKOFF.md` produced from the pack template, with
project description, platform, pattern, structural decisions, required stubs,
test infrastructure, and external resources filled in.

**Success criteria:**
- Output is a single complete `AGENT_KICKOFF.md` ready to save to the project
  root.
- All listed placeholder values (per the placeholder list below) are answered.
- Structural-decisions checklist enumerated (each □ item present with
  rationale slot for the architect to fill).
- CLI launch command for the architect agent included at the end.
- Sections that don't apply are removed.

**Files in scope:** Project-root `AGENT_KICKOFF.md` (sub-case B — target file
IS the artifact).

**[Placeholder list including structural-decisions checklist — preserve
current lines 173–213 verbatim, including the type-erasure / notification /
ViewModel-navigation Notes paragraphs which are architecture-rule reminders
the architect agent reads later (per design §5 final paragraph):]**
[Placeholder + structural-decisions checklist + Notes blocks]

**Constraints:** PM chat self-prompt. Output the complete file content; do
not partially fill placeholders. The structural-decisions checklist must be
enumerated regardless of whether the planning conversation has resolved each
item — the slots themselves drive the architect's later kickoff session.

**Completion report:** The artifact is `AGENT_KICKOFF.md` written at the
project root (sub-case B). No separate REPORT FILE.
[Preserve lines 216–219 — developer-paste-into-CLI launch instructions —
under this Completion report section as the closing prose.]
```

**Notes for the implementer.**
- The structural-decisions checklist Notes paragraphs are NOT solutions
  for the kickoff-generation prompt to follow (per design §5 final
  paragraph). They are architecture rules that travel into the
  AGENT_KICKOFF.md output and are consumed by the architect agent
  later. They survive verbatim under the placeholder list.
- The closing developer-paste-into-CLI launch line ("`./agent-run.sh
  claude --agent architect`…") is consumer guidance that lives under
  Completion report as documentation of how the artifact gets used
  next.

---

### 1.12 `repo-ops.md` — placeholder (no body change)

**Current state.** File is 14 lines. `variants: []` in frontmatter. No
variant bodies ship.

**Disposition.** Same as §1.6 (`grpc-schema.md`). No edit. The
METHODOLOGY mandate covers any future variant. Validate-pack.py
Check 10 (§2) enforces compliance automatically once any variant is
added.

---

### 1.13 `reviewer.md` — Variant: standard

**Current state.** File is 83 lines. Variant body lines 9–83:
- Lines 9–13: H2 + italic descriptor + read-only callout
- Lines 15–17: pass-N framing prose
- Lines 19–22: required-reading prose
- Line 23: per-phase-files-modified list placeholder
- Lines 24–57: numbered list (1–8) of the eight review dimensions, each
  with sub-bullets of dimension-specific rules
- Line 58: per-phase focus areas placeholder
- Lines 60–64: bolded label `**Verification**` + command + tests-pass
  expectation
- Lines 66–72: bolded label `**Output format:**` + header line + ✅/❌/⚠️
  marker format
- Lines 74–78: bolded label `**Pass summary**` + four sub-bullets
- Lines 80–82: closing **Verdict:** lines

**REPORT FILE sub-case.** A.

**Skeleton (target state).**

```
## Variant: standard

*[existing italic descriptor line 11 — preserve]*

> [existing read-only callout line 13 — preserve]

**Context:** This is reviewer pass **[N]** for Phase **[X]**. [If N > 1:]
Previous pass ([N-1]) had the following open ❌/⚠️ issues that the coder was
asked to fix: [PM chat inserts the open issue list].

**Required reading:** ARCHITECTURE.md (full), CHANGELOG.md (Phase [X] entry),
CLAUDE.md, IMPLEMENTATION_PLAN.md Phase [X] (full), plus all files modified
in Phase [X]: [LIST FILES].

**Problem:** The coder's pass-[X] output has not been verified against the
architecture, the implementation plan, or the eight review dimensions.

**Goal:** An eight-dimension review producing a Verdict line (Ready to commit
/ Needs fixes) and a structured findings list with ✅/❌/⚠️ markers per
finding.

**Success criteria:**
- Report header line correct (per Completion report below).
- Every one of the eight review dimensions addressed (no skipping).
- Findings tagged ✅ PASS / ❌ FAIL / ⚠️ WARN per the format below.
- Pass summary block present at end of report.
- Verdict line ends the report.
- Verification command run; result reported.

**Files in scope:** None (read-only review). Output is the report only.

**Constraints:**
- Read-only review pass. Do not modify any files. Output a report only.
- **Eight review dimensions (do not skip any):** [preserve current lines
  24–57 verbatim — the entire numbered list with sub-bullets.]
- [Per-phase focus-area placeholder line 58 preserved verbatim.]
- **Verification:** [preserve lines 60–64 verbatim — verification command
  block and tests-pass expectation.]

**Completion report:**
REPORT FILE: `<PM-chat-supplied path; e.g., /tmp/reviewer-phase-X-pass-N.md>`

Begin the report with this header line as the very first line of output:
`Phase [X] — [Phase title] — Reviewer Report, Pass [N]`

Then list findings: [preserve lines 69–72 verbatim — ✅ / ❌ / ⚠️ marker
formats]

**Pass summary (required at end of report):**
[preserve lines 74–78 verbatim — four sub-bullets]

End with one of: [preserve lines 80–82 verbatim — Verdict: Ready / Needs
fixes]
```

**Notes for the implementer.**
- The eight review dimensions, ✅/❌/⚠️ markers, Pass summary block,
  and Verdict line are format requirements per design §3 row "reviewer."
  All preserve verbatim.
- Per-phase focus areas placeholder (current line 58) lives under
  Constraints adjacent to the dimension list, not under Goal —
  these are scope additions, not goal additions, per the design's
  dimension-list framing.

---

### 1.14 `tester.md` — Variant: standard

**Current state.** File is 33 lines. Variant body lines 9–33:
- Lines 9–11: H2 + italic descriptor
- Lines 13–15: required-reading + Glob-and-build-inventory prose
- Line 17: inline goal ("Produce a test strategy for Phase [N]…")
- Lines 19–24: per-component bullet block (5 bullets)
- Lines 26–27: Priority Summary prose
- Lines 29–30: bolded label `**Report header (first line of output):**`
- Lines 32–33: bolded label `**Constraint:**` + closing prose

**REPORT FILE sub-case.** A.

**Skeleton (target state).**

```
## Variant: standard

*[existing italic descriptor line 11 — preserve]*

**Context:** [PM chat fills — Phase [N] / [COMPONENT SCOPE] has implementation-
bound test gaps that must be characterized before implementation begins.]

**Required reading:** ARCHITECTURE.md (full), CHANGELOG.md, BACKLOG.md. Use
Glob to list every source file. Read them all. Build your own complete
inventory — do NOT rely on any pre-specified list of components.

**Problem:** Phase [N] / [COMPONENT SCOPE] has implementation-bound test gaps
that must be identified, ranked by likelihood of catching real bugs, and
mapped to specific BACKLOG items before test implementation begins.

**Goal:** A test strategy listing what is tested, what is not, related
BACKLOG items, the appropriate test type, and required test doubles per
component, with a priority summary of top gaps.

**Success criteria:**
- Every source file in the source-file inventory appears under at least one
  component analysis.
- Every component has the prescribed five-field block (currently tested /
  NOT tested / related BACKLOG items / test type / test doubles).
- Priority Summary present and ranked by likelihood of catching a real bug,
  with the specific test to write and the failure it would catch.
- Report header line correct (per Completion report below).

**Files in scope:** None (read-only test strategy). Output is the report
only.

**Constraints:** Output a report only. Do not write any test code.

**Completion report:**
REPORT FILE: `<PM-chat-supplied path; e.g., /tmp/tester-phase-N.md>`

Begin the report with this header line as the very first line of output:
`Phase [N] — [Phase title] — Tester Report`

For each component: [preserve lines 19–24 — five-bullet block]

End with a Priority Summary: [preserve lines 26–27 — priority summary prose]
```

**Notes for the implementer.**
- The five-field per-component block and Priority Summary format are format
  requirements per design §3 row "tester" — preserve verbatim under
  Completion report.
- The "use Glob to list every source file" instruction lives under Required
  reading (it is methodology for the agent's intake), not under Constraints.

---

### 1.15 `supporting-docs/METHODOLOGY.md` — § Prompt Authoring Principles

**Current state.** Existing § "Prompt Authoring Principles" section
spans lines 546–664 (located between Workflow tables and Part 6 — Audit
Checkpoints). Subsections in the current file:

- § "The core rule: describe the problem, goal, and success criteria
  — not the solution" (lines 552–602)
- § "On scoping the problem statement" (lines 604–617)
- § "Exceptions — where prescriptive content is appropriate" (lines
  619–638) — table + architect-stronger-restriction paragraph
- § "When generating prompts from IMPLEMENTATION_PLAN.md task
  entries" (lines 640–647)
- § "PM chat self-check before generating any prompt" (lines 649–663)

**Edit specification.**

(a) **Replace** the body of § "Prompt Authoring Principles" with the
architect's draft text from V10-PROMPT-STRUCTURE-DESIGN.md § 6 (lines
369–542 of the design document, the full block between the
`### Draft METHODOLOGY.md § Prompt Authoring Principles
(replacement / extension)` heading and `**End of draft METHODOLOGY.md
edit text.**`).

(b) **Subsection mapping** — the architect draft preserves three
existing METHODOLOGY subsections by reference:

  - "On scoping the problem statement" (current lines 604–617) —
    architect draft references it as `*(existing subsection retained
    as-is — root-cause framing, files-in-scope as the bounding
    mechanism, audit-and-report behavior for unknown scope.)*`. The
    implementer literally retains the current 604–617 prose in place
    of that placeholder.
  - "When generating prompts from IMPLEMENTATION_PLAN.md task
    entries" (current lines 640–647) — same handling.
  - "Data-dependency trace" (current lines 656–662, currently
    embedded inside § "PM chat self-check") — same handling: the
    architect draft references it as item 3 of the new self-check
    section.

(c) **Drop** the current § "Exceptions — where prescriptive content
is appropriate" subsection (lines 619–638). The architect draft
replaces it with the new § "Format requirements vs. solutions"
subsection (with its own per-agent table). D6 + design §7 row C cover
why.

(d) **Q4b multi-part header subsection move-in.** Add a new subsection
to METHODOLOGY's § Prompt Authoring Principles, placed adjacent to
the architect draft's § "File-based reporting" subsection (immediately
after it). Heading: `### Multi-part phase report headers`. Body
sources from the current `PROMPT-AUTHORING.md` lines 42–46:

```
### Multi-part phase report headers

When a phase is split into sequential implementation chunks, use **Part [M]**
(not "pass") appended to the phase title in all report headers. Pass numbers
reset to 1 for each new part. Single-part phases use the existing header
format — do not append `, Part 1`. Example:
`Phase 12 — Auth Flows, Part 2 — Reviewer Report, Pass 1`

This applies to every agent's completion report regardless of which file in
`docs/pack/prompts/` the prompt came from.
```

(e) **Section ordering after edit.** The new § Prompt Authoring
Principles section reads (top to bottom):

1. § Prompt Authoring Principles (intro paragraph from architect draft)
2. § The core rule: describe the problem, goal, and success criteria —
   not the solution
3. § Mandatory section structure (canonical order)
4. § Format requirements vs. solutions (with per-agent table)
5. § File-based reporting (with sub-cases A and B)
6. § Multi-part phase report headers (Q4b move-in — NEW location)
7. § On scoping the problem statement (preserved from current)
8. § When generating prompts from IMPLEMENTATION_PLAN.md task entries
   (preserved from current)
9. § PM chat self-check before generating any prompt (rewritten per
   architect draft, four numbered items including Triad check, Solution
   check, Data-dependency trace, and REPORT FILE check)

**Notes for the implementer.**
- Use the literal architect-draft text (design §6 blockquoted text)
  as the source. Strip the `> ` blockquote prefix from each line — the
  architect draft uses blockquote markdown so the draft sits inside
  the design doc; the actual METHODOLOGY edit is plain markdown.
- The "Data-dependency trace" item in the new self-check (architect
  draft step 3) carries an `*(existing subsection retained …)*`
  reference; substitute the literal current self-check item 2 prose
  (lines 656–662) verbatim under that step.
- Keep the existing surrounding sections (§ "Workflow tables" before;
  § "Part 6 — Audit Checkpoints" after) intact.
- Validate after edit that the section header `## Prompt Authoring
  Principles` remains at H2; subsections are H3 (`###`).

---

### 1.16 `project-template/docs/pack/prompts/PROMPT-AUTHORING.md`

**Current state.** File is 56 lines (per Read). Has:
- Lines 1–7: H1 + intro paragraph (directory framing)
- Lines 9–18: § "How to use these templates" (starting-points framing)
- Lines 20–32: § "Per-agent exceptions" + table
- Lines 34–49: § "Self-check" (multi-part phases + self-check question)
- Lines 51–56: § "Full authoring standard" (cross-reference paragraph)

**Edit specification.** Replace the file with a short two-paragraph
body (one starting-points paragraph + one cross-reference one-liner).
Suggested target shape (implementer writes the actual prose;
substantive content fixed):

```
# PROMPT-AUTHORING.md — Directory guidance

This directory contains one file per agent. The PM chat reads
`<agent>.md` on demand, locates the requested variant by its `## Variant: <slug>`
heading, copies the body, and customizes it for the task at hand.

These templates are starting points. The PM chat customizes phase numbers,
file names, scheme names, and verification commands per use; sections that
don't apply to the current phase are removed.

See `supporting-docs/METHODOLOGY.md` § **Prompt Authoring Principles** for the
complete prompt-authoring standard — the labeled-section convention every
variant in this directory follows, the format-vs-solution distinction, the
file-based-reporting rule, and the multi-part phase report header convention.
```

**Drop** from the current file:
- § "Per-agent exceptions" (current lines 20–32) — METHODOLOGY now owns
  this content (D1 + D6).
- § "Self-check" (current lines 34–49) — split into:
  - Multi-part phases convention (lines 42–46) — moves to METHODOLOGY
    per Q4b (see §1.15(d) above).
  - "Am I describing what needs to be true, or how to do it?" self-check
    (lines 48–49) — METHODOLOGY's PM chat self-check subsection now
    owns the canonical version.
- § "Full authoring standard" (lines 51–56) — collapses into the new
  one-line cross-reference paragraph.

**Notes for the implementer.**
- File continues to exist (validate-pack.py Check 6 requires
  `PROMPT-AUTHORING.md` in the prompts directory — see
  scripts/validate-pack.py line 284).
- The frontmatter shape used by other prompt files (`agent: …` /
  `variants: …`) does NOT apply — PROMPT-AUTHORING.md is a
  directory-guidance file, not a per-agent prompt file. The current
  file has no frontmatter and the post-edit version preserves that.
- Validate-pack.py Check 6 only checks per-agent files for frontmatter
  (excluding PROMPT-AUTHORING.md by name — line 290 of validate-pack.py).
  No regression risk on this front.


---

## 2. validate-pack.py Check 10 specification

**Numbering RESOLVED per O1a (project lead, 2026-04-28).** The new
check is numbered **Check 10** (next available — `scripts/validate-pack.py`
currently ships Checks 1–9, verified by inspection of the file's
docstring and the function-call sequence in `main()`, lines 536–550).
The earlier "Check 11" label in upstream prompts was a mis-statement;
this specification uses Check 10 throughout.

**This is a specification.** It defines what Check 10 does — input,
logic, output, exit behavior. It does NOT contain Python code; the
Pack Chat writes the Python code per the implementer's downstream
prompt (§3 below).

### Inputs

- Directory: `project-template/docs/pack/prompts/` (the constant
  `PROMPTS_DIR` already defined at validate-pack.py line 44).
- File set: every `*.md` file in `PROMPTS_DIR` EXCLUDING
  `PROMPT-AUTHORING.md` (already excluded in Check 6 via the same
  filter `if p.name != "PROMPT-AUTHORING.md"` at line 290; reuse the
  same filter).
- Per-file content: read with `f.read_text()`.
- Per-file body: text after the closing `---\n` of the YAML
  frontmatter. The Check 6 implementation already extracts this via
  `body = content[fm_match.end():]` (line 370). Reuse the same
  approach.

### Variant identification

Within each file body, identify variant blocks by the H2 heading
pattern `^## Variant: (\S+)\s*$` (the same regex Check 6 uses at
line 371). Each variant body runs from its `## Variant:` heading line
to either the next `## Variant:` heading or end-of-file. (For
files with `## ` H2 headings that are NOT `## Variant:` blocks —
e.g., `auditor.md` has `## Templates 10–12 — Superseded` at line 67 —
those non-variant H2 sections are excluded from variant scanning by
the regex anchor.)

### Per-variant rules

For each variant block identified:

**Rule N.1 — Kickoff exception detection.**
If the variant body contains the literal substring
`**Convention exception:**` (case-sensitive, exact match), the
variant is exempt from rules N.2 and N.3. Per the design's §5 +
Q2b resolution, this substring marks the kickoff variant in
`pm-chat.md` as out-of-scope for the convention. The check records
"exempt" for this variant and continues.

**Rule N.2 — Triad presence.**
The variant body must contain ALL THREE of the following
case-sensitive substrings, each appearing as a bolded inline label:

  - `**Problem:**`
  - `**Goal:**`
  - `**Success criteria:**`

If any are missing, fail the variant with a message naming the
missing label(s).

**Rule N.3 — File-based completion report presence.**
The variant body must contain at least ONE of the following
substrings (sub-case A or B per design §4):

  - `REPORT FILE:` (sub-case A — agent produces a report at a path)
  - `**Completion report:**` (sub-case B — PM-chat self-prompt edits a
    target file; the Completion report section labels what was edited)

Sub-case B variants typically have `**Completion report:**` AND
explicit prose naming the target file (BACKLOG.md / STATUS.md /
SETUP.md / AGENT_KICKOFF.md). The check requires only the label —
the target-file naming is editorial.

If neither substring is present, fail the variant with a message
naming the missing completion-report indicator.

### Output

**On pass (per file):**
```
  OK: project-template/docs/pack/prompts/<file>.md — N variant(s) pass triad+report-file rule
```
Where N is the count of variants in the file (excluding exempt
variants — those count separately in a parenthetical, e.g.,
`(1 exempt: kickoff)`).

**On fail (per variant):**
```
FAIL: project-template/docs/pack/prompts/<file>.md — Variant: <slug> — missing labeled section(s): <list>
```

The check records each failure via the existing `fail()` helper
(line 86). At end of run, the global `failures` list determines exit
code (1 if any failures, 0 if all pass) — this is already the
existing pattern for Checks 1–9.

### Integration with main()

Add a new function `check_prompt_triad_compliance()` (name suggested;
implementer chooses) following the pattern of `check_prompts_directory`
(line 278). Add a call to it inside `main()` (line 536–550) after
`check_init_project_structure()` (line 549) and before the closing
print-and-exit block. The new call sits as the LAST check, preserving
ordering of Checks 1–9.

### Exit behavior

Identical to Checks 1–9. The check records failures via the global
`fail()` helper; main() exits non-zero if `failures` is non-empty.

### Docstring update

The validate-pack.py module docstring (lines 1–25) lists the checks
("Checks: 1. SKILL.md frontmatter… 9. Init-project structure…").
Add a new line:

```
  N. Prompt template triad compliance: every in-scope variant in
     project-template/docs/pack/prompts/*.md (excluding the kickoff
     variant identified by `**Convention exception:**`) contains
     `**Problem:**`, `**Goal:**`, `**Success criteria:**`, and a
     file-based completion-report indicator (`REPORT FILE:` or
     `**Completion report:**`).
```

### Acceptance criteria for the Pack Chat work

- New function added to validate-pack.py per the spec above.
- main() calls the new function in the order specified.
- Module docstring updated with the new check description.
- All existing checks (1–9) unchanged in behavior.
- Running `python3 scripts/validate-pack.py` exits 0 against the
  post-implementation state (12 in-scope variants pass; 1 kickoff
  variant exempt; 2 placeholder files have zero variants and contribute
  zero variant rows). Pre-implementation state would fail this check
  on every variant — that is expected and is the reason the templates
  are edited FIRST (per §6 verification ordering).

---

## 3. Pack Chat prompt requirements specification

The implementer drafts a downstream prompt for Pack Chat that edits
`scripts/validate-pack.py` and files BD-049 to `BACKLOG.md`. This
section specifies what that prompt must include — not the prompt
text itself.

### Prompt structure

The prompt follows pack-agent prompt rules (per CLAUDE.md operating
memory: every agent prompt must include context, output file path,
read-only flags where applicable, markdown-only, problem/goal/
criteria, CLI command). For Pack Chat specifically, the "output file
path" is the file Pack Chat edits, not a separate report file.

### Required content

1. **Role declaration.** "Role: Pack Chat (write-capable on
   `scripts/validate-pack.py` and `BACKLOG.md` only; no other file
   touched)."

2. **Context.** Names this planner pass document
   (`maintenance-docs/V10-PROMPT-STRUCTURE-PLAN.md`) as the source of
   truth for the spec. Names the architect design
   (`V10-PROMPT-STRUCTURE-DESIGN.md`) as the upstream rationale. States
   that templates and METHODOLOGY have already been edited (per the
   verification ordering in §6 of this plan) before Pack Chat runs.

3. **Files Pack Chat edits.**
   - `scripts/validate-pack.py` — add the new check per §2 of this
     plan; specifically the function definition, the `main()` call
     insertion, and the docstring update. No edits to existing checks
     1–9.
   - `BACKLOG.md` — add the BD-049 entry per §7 of this plan. Locate
     the entry between BD-048 and the `## Deferred` section header;
     follow the format used by BD-046/BD-047/BD-048 (multi-line
     bolded TD-NNN header, Type, Status, Blockers, Unblocks,
     File/Symbol, Description, Context, Resolved fields).

4. **Files Pack Chat must NOT edit.**
   - Any prompt template file (templates already done by implementer).
   - METHODOLOGY.md, PROMPT-AUTHORING.md (already done by implementer).
   - PM-CHAT.md, PACK-CHAT.md, PACK-AGENTS.md (operational rules; PM-
     chat-only territory).
   - Trinity files at any location.
   - README.md, CHANGELOG.md (PM-chat-only at version boundaries).
   - `.github/workflows/validate-pack.yml` (no workflow change needed
     — workflow re-runs the script and inherits the new check
     automatically).

5. **Function signature shape (validate-pack.py).** Use the same
   shape as `check_prompts_directory()` (def at line 278): no
   arguments, no return value, calls `fail()` and `ok()` from module
   scope, accumulates failures into the module-level `failures` list.

6. **Test data shape.** The check runs against the post-implementation
   state of `project-template/docs/pack/prompts/`. After the
   implementer's template edits land:
   - 8 files contribute variants.
   - 13 variant blocks total (12 in-scope + 1 kickoff exempt).
   - Each in-scope variant body contains `**Problem:**`, `**Goal:**`,
     `**Success criteria:**`, and a Completion-report indicator.
   - The kickoff variant body contains `**Convention exception:**`
     and is recorded as exempt.

7. **Integration with existing main() flow.** The new function call
   sits as the LAST check in `main()`; ordering of checks 1–9 is
   preserved.

8. **Commit message convention.** Pack Chat does NOT commit. The
   implementer commits everything atomically per §4 of this plan.
   Pack Chat performs file edits only and reports back.

9. **No other files modified.** Explicit statement: Pack Chat
   touches only `scripts/validate-pack.py` and `BACKLOG.md`. Any
   other file change requires a flag-back to the implementer.

10. **Output report file path.** Pack Chat writes a confirmation
    report to a path the implementer specifies in the prompt
    (e.g., `/tmp/pack-chat-validate-and-bd049.md`) listing the
    function added, the docstring update, the BD-049 entry text
    inserted, and any flag-back conditions encountered.

11. **Read-only flag.** Pack Chat reads (no write) every other file in
    the repo it needs for context (CLAUDE.md, BACKLOG.md, the
    validate-pack.py existing file, the planner doc, the architect
    doc).

12. **Chunked-write rule.** Per the operating-memory rule on long
    outputs: if Pack Chat's edits to validate-pack.py exceed ~300
    lines of new content, chunk the writes (the new check function
    will likely be 40–80 lines plus docstring update — well under the
    threshold; the rule applies generally).

13. **Markdown-only constraint.** Confirmation report (item 10) is
    markdown.

### Out of scope for the Pack Chat prompt

- Drafting BD-049 entry text (the planner has drafted it in §7;
  Pack Chat copies the text verbatim).
- Drafting the validate-pack.py Python code in advance (Pack Chat
  writes it, against this spec).
- Any change to `.github/workflows/validate-pack.yml`.
- Any test of the new check against fixtures (the check runs
  against the actual `project-template/docs/pack/prompts/` tree as
  part of the implementer's local verification per §6).

### Approval gates inside the Pack Chat session

- After Pack Chat presents the proposed validate-pack.py diff and the
  proposed BD-049 entry, the implementer reviews and approves before
  Pack Chat applies the writes.
- If Pack Chat surfaces a flag-back condition (e.g., the function
  already exists with the chosen name; the BD-049 number is taken;
  the existing check ordering has changed since the spec was
  written), Pack Chat does NOT proceed without explicit
  implementer confirmation.


---

## 4. Commit sequencing recommendation

**Project-lead direction.** Commit only after all work is complete
(atomic). Two options on the table:

- **Option (a) — single atomic commit.** Design doc + plan doc +
  validate-pack.py + METHODOLOGY + PROMPT-AUTHORING + 12 templates
  + BD-049 entry, all in one commit.
- **Option (b) — two commits.** Prep commit (design doc + plan doc)
  + implementation commit (everything else).

**Recommendation: Option (b).**

**Justification.**

1. **Pre-implementation artifact preservation.** The design doc and
   this plan doc are reference artifacts. They describe the rationale
   for everything in the implementation commit. Landing them first
   means:
   - If the implementation commit is later reverted (verification
     failure not caught locally; integration regression in a later
     commit), the design + plan stay in repo history as the basis
     for re-attempting.
   - The implementation commit message can reference the plan-doc
     SHA as the spec being implemented, which is more useful than
     a self-referencing single-commit message.

2. **Working-state integrity at every step.** validate-pack.py must
   pass at every intermediate state (per CLAUDE.md repo rules). With
   Option (b):
   - **After commit 1 (design + plan)**: only maintenance-docs/ files
     change. Zero impact on validate-pack.py — none of its 9 checks
     touch maintenance-docs. Pass guaranteed.
   - **After commit 2 (implementation)**: validate-pack.py has Check 10
     added AND every variant satisfies it. Pass guaranteed by
     construction (templates edited before validate-pack.py is changed,
     per §6 verification ordering).
   With Option (a), the same property holds — but the single commit
   lumps maintenance-docs file additions with substantive pack-product
   edits, making review harder.

3. **Reviewer scrutiny.** Option (b) lets a code reviewer (human or
   automated CI inspection of the diff) review the implementation
   commit against the plan-doc commit it implements. With Option (a)
   the reviewer reads the rationale and the implementation in one
   blob, fighting noise.

4. **Rollback granularity.** If verification surfaces a regression
   that can be traced to one specific template edit but the plan doc
   remains valid, Option (b) preserves the option of reverting only
   the implementation commit while keeping the design + plan as
   reference for the next attempt. Option (a) requires reverting
   everything.

5. **Negligible cost.** Two commits vs. one commit is one extra
   `git commit` invocation. The overhead is zero. The benefits are
   structural.

**Counter-argument considered: "atomic" interpretation.** The word
"atomic" in the project-lead direction can be read two ways:
(i) one single commit, or (ii) all-or-nothing landing — i.e., if the
work commits at all, every part must commit together. Option (b)
satisfies (ii): the prep commit alone is harmless (just maintenance
docs) and never lands without the implementation commit immediately
after. The project lead's intent (working-state integrity, no
half-done state in repo) is preserved.

**Decision point.** This is a recommendation, not a binding
selection. The project lead approves at execution time per the
plan's flag-back gate (§8 below). If the project lead prefers Option
(a), the verification ordering in §6 still holds — only the commit
boundary changes.

### Commit shape — Option (b) detail

**Commit 1 — prep:**
```
docs: v10 — V10-PROMPT-STRUCTURE design + plan docs

Land the architect design pass (V10-PROMPT-STRUCTURE-DESIGN.md) and
the planner pass (V10-PROMPT-STRUCTURE-PLAN.md) for the prompt-
template labeled-section convention. No pack-product or script edits
in this commit; implementation lands separately. See planner doc
§4 for sequencing rationale.
```
Files touched:
- `maintenance-docs/V10-PROMPT-STRUCTURE-DESIGN.md` (new)
- `maintenance-docs/V10-PROMPT-STRUCTURE-PLAN.md` (new)

**Commit 2 — implementation:**
```
feat: v10 — BD-049 prompt-template labeled-section convention + Check 10

Apply the labeled-section convention from V10-PROMPT-STRUCTURE-PLAN.md
to all 12 in-scope prompt template variants in
project-template/docs/pack/prompts/. Add the Q2b convention-exception
callout to the kickoff variant in pm-chat.md. Replace
supporting-docs/METHODOLOGY.md § Prompt Authoring Principles with
the architect's draft text (V10-PROMPT-STRUCTURE-DESIGN.md §6),
including the file-based-reporting subsection and the multi-part
phase header subsection (Q4b move-in). Collapse PROMPT-AUTHORING.md
to a one-line cross-reference plus a directory-level starting-points
paragraph. Add validate-pack.py Check 10 to enforce triad presence
on every in-scope variant. File BD-049 in BACKLOG.md.

Per Q1b: rename the per-fix middle label in coder.md Variant: fix-cycle
from `Expected behavior:` to `Goal:` for label consistency with the
prompt-level triad.
```
Files touched: per the §0 list above (10 prompt template files +
METHODOLOGY + PROMPT-AUTHORING + validate-pack.py + BACKLOG.md).

### Commit shape — Option (a) detail

If the project lead chooses Option (a), the single commit message
combines the two messages above; the file list is the union of
both. No semantic difference in execution; only commit-history shape
differs.

---

## 5. Trinity-rule check

**Statement.** This work does NOT touch any trinity-ruled file. The
trinity rule (per pack-repo CLAUDE.md and operating memory) requires
parallel edits to `CLAUDE.md`, `AGENTS.md`, and `GEMINI.md` whenever
ONE of those three is modified — at either the project-template
location or the pack-repo root.

**Rationale.**

- **Project-template trinity** (`project-template/CLAUDE.md`,
  `project-template/AGENTS.md`, `project-template/GEMINI.md`): not
  edited. The convention this work introduces lives in METHODOLOGY.md
  + the prompt templates. The trinity files declare project rules
  (architecture, security, anti-patterns, deferral comments, scripts,
  phase routing); they do NOT declare prompt-authoring conventions.
  No content overlap. The trinity files reference METHODOLOGY.md for
  methodology — that pointer survives this work unchanged.

- **Pack-repo trinity** (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md` at
  `/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/`): not
  edited. These declare pack-repo working rules (versioning, BD
  numbering, validate-pack.py rules, no-modify-without-approval).
  This work does not change any of those rules; it adds a new check
  to the validation script per existing rules.

- **Prompt template files** (`project-template/docs/pack/prompts/*.md`):
  NOT trinity-ruled. They are per-agent prompt templates, not project-
  level context files. The trinity rule applies only to the three
  context files (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md` at either
  template root or pack repo root) because their semantic content
  must remain symmetric across tools. Prompt templates are tool-
  agnostic — one file per agent, used by all three tools — and the
  rule does not apply.

- **Methodology and authoring docs** (`supporting-docs/METHODOLOGY.md`,
  `project-template/docs/pack/prompts/PROMPT-AUTHORING.md`): NOT
  trinity-ruled. These are pack-product reference documents the
  trinity files reference, not trinity members.

**Implementer obligation.** None on the trinity rule axis. The
implementer should NOT add trinity-file edits to this work; doing so
would expand scope outside what the design and this plan cover.

---

## 6. Local verification approach

**Principle.** Run verification BEFORE commit, not after. The pack
must be in a clean working state at every commit boundary.

### Ordering — strict sequence

The implementer executes in this order. The order matters: editing
validate-pack.py before the templates would cause Check 10 to fail
against unedited templates, blocking commit.

1. **Edit prompt templates** (steps 1.1–1.14 of §1 above). Twelve
   variants edited; one variant (kickoff) gets the Q2b callout
   inserted. Two placeholder files (grpc-schema, repo-ops) untouched.

2. **Edit METHODOLOGY.md** (§1.15 above). Replace § Prompt Authoring
   Principles per the architect's §6 draft + Q4b move-in.

3. **Edit PROMPT-AUTHORING.md** (§1.16 above). Collapse to one-line
   cross-reference + directory-level starting-points paragraph.

4. **Manual structural sweep** (no automation):
   - For each of the 12 in-scope variants, grep the variant body
     for the literal `**Problem:**`, `**Goal:**`, `**Success
     criteria:**` substrings AND a completion-report indicator
     (`REPORT FILE:` for sub-case A; `**Completion report:**` for
     sub-case B). Use:
     ```
     grep -c '\*\*Problem:\*\*' project-template/docs/pack/prompts/<file>.md
     ```
     etc. Confirm count ≥ expected variant count for in-scope files.
   - For the kickoff variant: grep for the literal
     `**Convention exception:**` substring; confirm exactly one
     occurrence in `pm-chat.md`.
   - For Q1b: grep for `Expected behavior:` in `coder.md`. Confirm
     ZERO occurrences after edit (the rename should have replaced
     all instances). If non-zero, identify and fix before
     proceeding.
   - For METHODOLOGY: confirm § Prompt Authoring Principles
     contains `Mandatory section structure (canonical order)`,
     `Format requirements vs. solutions`, `File-based reporting`,
     `Multi-part phase report headers` subsection headings.
   - For PROMPT-AUTHORING.md: confirm length ≤ 30 lines (target
     state is ~15 lines including title and blank lines); confirm
     it contains the `supporting-docs/METHODOLOGY.md § Prompt
     Authoring Principles` cross-reference.

5. **Pack Chat session.** Implementer drafts the prompt per §3, runs
   Pack Chat, approves the validate-pack.py diff and BD-049 entry
   text. Pack Chat applies the writes.

6. **Run validate-pack.py.** Execute:
   ```
   python3 scripts/validate-pack.py
   ```
   Expected output: every check (1–9 plus the new Check 10) reports
   `OK` lines; final line reads `PASSED — all checks clean`; exit
   code 0.

7. **Failure handling — Check 10.** If Check 10 fails on any in-scope
   variant:
   - Do NOT commit.
   - Read the failure message; identify the missing label(s).
   - Edit the variant per §1 spec to add the missing label(s).
   - Re-run validate-pack.py.
   - Repeat until clean.

8. **Failure handling — other checks.** If any of Checks 1–9 fails:
   - Likely cause: collateral damage from one of the edits (e.g., a
     PROMPT-AUTHORING.md edit that inadvertently broke the file's
     existence requirement; a METHODOLOGY.md edit that changed a
     line referenced by another check). All checks 1–9 are well-
     scoped to specific files and should not regress; if one does,
     diagnose the regression at the source and fix.
   - Do NOT commit until all checks pass.

9. **Manual cross-reference sweep** (defense in depth):
   - `grep -rn 'PROMPT-AUTHORING.md' project-template/ supporting-docs/`
     — confirm all references still resolve (the file continues to
     exist with the same path; just shorter content).
   - `grep -rn 'Prompt Authoring Principles' project-template/
     supporting-docs/` — confirm references to the METHODOLOGY
     section name still match the post-edit heading text.
   - `grep -rn 'Per-agent exceptions' supporting-docs/
     project-template/` — confirm no stale reference remains to the
     old METHODOLOGY § "Exceptions — where prescriptive content is
     appropriate" heading or PROMPT-AUTHORING's old "Per-agent
     exceptions" table heading. The architect draft replaces the
     concept with "Format requirements vs. solutions"; any pre-existing
     reference to the old name needs an update or noting as a deferred
     follow-up.
   - `grep -rn 'Expected behavior' project-template/docs/pack/prompts/`
     — confirm only documentation references survive (e.g., in
     METHODOLOGY's PM-chat-self-check description if it uses that
     phrase). The per-fix label should now read `Goal:`.

10. **Stage and commit** per §4 (Option (b) recommended).

### What runs in CI

- `.github/workflows/validate-pack.yml` re-runs `validate-pack.py`
  on every push. After the implementation commit lands, CI inherits
  Check 10 automatically. No workflow-file edit needed.

### What is NOT verified locally

- Behavioral correctness of the prompt templates (i.e., the prompts
  produce sensible agent runs). This requires a real PM-chat-driven
  agent run, which is out of scope for this work — Phase 4 final
  verification (C-V10-15) covers integration verification per the
  V10-PHASE-4-VERIFICATION-PLAN-v2.md harness.
- Cross-tool agent invocation parity. Already covered by Check 5
  (agent file count consistency) and is unaffected by this work.


---

## 7. BD-049 BACKLOG.md entry text

**Number rationale.** Highest existing BD-NNN in BACKLOG.md is BD-048
(line 1097, "Capability-addition discovery + install-check symmetry
with kickoff"). Per CLAUDE.md repo rules, the next BD number is
BD-049. Verified by grep against the current file at planner-pass
time.

**Insert position.** Between BD-048 (Open) and the `## Deferred`
section header. Same shape as BD-046, BD-047, BD-048.

**Entry text (verbatim, ready for Pack Chat to copy into
BACKLOG.md):**

```
**BD-049 — Prompt template labeled-section convention + validate-pack.py Check 10**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: `project-template/docs/pack/prompts/architect.md`,
  `project-template/docs/pack/prompts/auditor.md`,
  `project-template/docs/pack/prompts/coder.md`,
  `project-template/docs/pack/prompts/docs-researcher.md`,
  `project-template/docs/pack/prompts/planner.md`,
  `project-template/docs/pack/prompts/pm-chat.md`,
  `project-template/docs/pack/prompts/reviewer.md`,
  `project-template/docs/pack/prompts/tester.md`,
  `project-template/docs/pack/prompts/PROMPT-AUTHORING.md`,
  `supporting-docs/METHODOLOGY.md` § Prompt Authoring Principles,
  `scripts/validate-pack.py`

Description: Phase 4 audit of v10.0 surfaced inconsistency between the pack's
  stated Prompt Authoring Principles in METHODOLOGY.md and the actual
  content of the ten prompt templates that ship. Only `coder.md` Variant:
  fix-cycle surfaced the labeled triad (Problem / Expected behavior /
  Success criteria); the other variants either buried the triad in prose
  or omitted it entirely. METHODOLOGY's existing "Exceptions — where
  prescriptive content is appropriate" subsection was murky enough to be
  read as licensing solutions in the prompt.

  This item lands the labeled-section convention across all 12 in-scope
  prompt template variants, replaces METHODOLOGY's § Prompt Authoring
  Principles with the architect's draft text (mandatory triad on every
  prompt, format-vs-solution distinction, file-based-reporting rule,
  canonical section order), collapses PROMPT-AUTHORING.md to a one-line
  cross-reference, and adds a new validate-pack.py check that enforces
  triad presence on every in-scope variant.

  Per the resolved Q1b: the per-fix middle label in `coder.md` Variant:
  fix-cycle was renamed `Expected behavior:` → `Goal:` for label
  consistency with the prompt-level triad.

  Per the resolved Q2b: `pm-chat.md` Variant: kickoff (a context handoff,
  not an agent-task prompt) is the one exception to the convention; an
  inline `**Convention exception:**` callout marks it, and the new
  validate-pack.py check identifies the exemption via that literal
  substring.

  Per the resolved Q4b: the multi-part phase header convention moved
  from PROMPT-AUTHORING.md into METHODOLOGY.md § Prompt Authoring
  Principles alongside the file-based-reporting subsection.

Context: Identified during Phase 4 audit (April 2026). The audit closed
  with C-V10-01 through C-V10-14 landed (v10-dev tip `459161b` or
  descendant); this work landed before C-V10-15 final verification
  per design pass V10-PROMPT-STRUCTURE-DESIGN.md and planner pass
  V10-PROMPT-STRUCTURE-PLAN.md.
Resolved: April 2026, v10.0 — commit <SHA>.
```

**Notes for Pack Chat.**
- Replace `<SHA>` with the actual commit hash AFTER the
  implementation commit lands. Pack Chat does this as a follow-up
  edit (or the implementer does it post-commit; either works).
- The Status field is `Resolved` because this entry is filed AS PART
  OF the implementation commit — the commit IS the resolution. This
  is consistent with BD-024 / BD-025 / BD-027 / BD-028 / BD-029 / BD-030
  / BD-038 / BD-041 / BD-043 / BD-047 (all filed as Resolved at
  resolution time).
- The "File/Symbol" field lists every file the implementation commit
  touches. The "Description" field references both the architect
  design and this planner doc. The "Resolved" line names v10.0 as
  the version.

---

## 8. Implementer flag-backs

The implementer pauses for project-lead decision in any of the
following conditions:

### F1 — Validate-pack.py check numbering

**RESOLVED per O1a (project lead, 2026-04-28).** The new check is
Check 10. Implementer does NOT pause for confirmation. Retained in
the flag-back list for traceability; future implementers reading
this plan see how the numbering was settled.

### F2 — Variant has prose that resists triad addition without semantic loss

If during template editing the implementer finds a variant whose
existing prose actively contradicts the triad framing (e.g., a
section that says "the agent should produce …" in a way that cannot
be reframed as Problem / Goal / Success criteria without inventing
content not present in the original), pause and surface the variant
to the project lead. The architect's design states no such variant
exists in scope, but the per-line implementation may surface a case
the design did not anticipate. Do NOT invent prose to fit the
convention; flag-back instead.

### F3 — Validate-pack.py Check 10 surfaces unexpected exemptions

If, after running Check 10 against the post-edit templates, a variant
fails the triad test for a reason the implementer cannot resolve by
re-reading §1's spec for that variant (e.g., the body uses Unicode
formatting variants of `**Problem:**` that don't match the literal
substring), pause and surface to the project lead. The check is
literal-substring-match for a reason — silent normalization would
mask defects.

### F4 — Commit shape selection between Option (a) and Option (b)

Per §4 above, the planner recommends Option (b) (two commits:
prep + implementation). The project lead approves at execution time.
The implementer pauses before staging to confirm the selected option.

### F5 — METHODOLOGY edit produces a section heading conflict

If the architect's draft text uses a subsection heading
(`### Mandatory section structure (canonical order)`) that conflicts
with an existing heading at the same level elsewhere in METHODOLOGY,
pause. The architect's draft is intended to land cleanly within the
existing § Prompt Authoring Principles section bracket; cross-section
collisions (unlikely but possible) need project-lead resolution.

### F6 — Cross-reference regression in supporting docs not covered by §6 sweep

If the §6 cross-reference sweep surfaces a stale reference outside
the prompt-template directory, METHODOLOGY, or PROMPT-AUTHORING.md
(e.g., a SETUP-NEW.md paragraph references the old "Per-agent
exceptions" table by name), pause. Such a reference is likely an
out-of-scope edit; the project lead may want to either fold the fix
into this work (expanding scope) or defer it to a separate commit.

### F7 — Pack Chat surfaces a flag-back inside its session

Per §3 item 13, Pack Chat may flag back during its session if the
function name is taken, the BD-NNN is taken, or the existing
validate-pack.py structure has changed since the spec was written.
The implementer surfaces any such flag-back to the project lead
without applying writes.

### F8 — Q1b rename produces awkward per-fix prose

Per §1.4, the rename of `Expected behavior:` → `Goal:` may produce
a sentence like "Goal: the URL builder accepts non-Latin characters"
that reads less naturally than the original "Expected behavior: the
URL builder accepts non-Latin characters." The project lead has
already chosen Q1b for symmetry; this flag-back is for the case
where the implementer finds a per-fix block where the rename
produces a sentence that is grammatically broken (not just less
natural). Surface and confirm wording before committing.

---

## 9. Open questions for the project lead

The architect's design + Q1–Q4 resolutions cover the substantive
decisions for this work. The planner identifies one new question
arising from per-file inspection.

### O1 — validate-pack.py check numbering (Check 10 vs. Check 11)

Per §0 supersession note and §2 numbering caveat: the user prompt
specifies "Check 11" but validate-pack.py currently has only Checks
1–9. The implementer needs the project lead to confirm the
intended number before drafting the Pack Chat prompt for §3. The
options are:

- **O1a.** Number the new check **Check 10** (next available).
  Update the user prompt's references to "Check 10" / "Checks 1–9
  still pass." This matches the actual state of the script.
- **O1b.** Number the new check **Check 11**, indicating that a
  Check 10 lands in a parallel commit before this work. The
  implementer needs to identify which commit and ensure ordering.
- **O1c.** Number the new check **Check 11** anyway, leaving Check
  10 as a placeholder for future use. Unusual but harmless if the
  numbering is purely descriptive (the function ordering, not the
  number, drives execution).

**Planner recommendation:** O1a — match the actual state of the
script. Re-numbering on a hypothetical future Check 10 is harmless
(numbering is descriptive); but introducing a numbering gap on day
one is an avoidable readability cost.

**RESOLVED — O1a (project lead, 2026-04-28).** New check is numbered
**Check 10**. The plan body has been updated throughout to use
Check 10; references to "Check 11" survive only in §0/§2/§8 F1/§9 O1
context paragraphs that document the resolution. The Pack Chat
prompt the implementer drafts after this plan must use Check 10.

This is the only NEW question the per-file inspection raised.

---

## End of plan

The implementer takes this document plus the architect's design pass
(V10-PROMPT-STRUCTURE-DESIGN.md) and executes per the verification
ordering in §6 + the commit shape from §4. After C-V10-15 final
verification per V10-PHASE-4-VERIFICATION-PLAN-v2.md, v10.0 is
ready to ship.
