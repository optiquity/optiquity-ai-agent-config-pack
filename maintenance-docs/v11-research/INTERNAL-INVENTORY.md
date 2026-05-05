# v11 Internal Inventory: Flat-File Work-Tracking Surface

**Scope.** Read-only inventory of every flat Markdown file in the pack repo and
in `project-template/` that records or governs work state, plus every script,
skill, agent file, agent prompt, validate-pack check, supporting-docs
procedure, and trinity-rule rule that reads / writes / cross-references / or
enforces format on each file. Includes a comparison against
`/Users/david/Developer/OptiquityTrader` (OT), the only real-world project
currently using the pack.

**Date.** 2026-04-30. Pack version v10.0 (BD-059 fix in flight, on `main`,
no version bump). OT mid-flight on the v10 migration's reconciliation
phase but on `main` after revert.

**No solutions or designs proposed** — this is the architect's map.

**Companion file.** `EXTERNAL-RESEARCH.md` (parallel research on GitHub
Issues / `gh` / GitHub MCP / Codex CLI / Gemini CLI). The two files together
form the architect's input.

---

## Pass A — Pack repo flat files (operational state)

The pack repo's operational surface is intentionally flat (no
`docs/project/` / `docs/pack/` split — those exist only in `project-template/`
and downstream projects). The pack's PACK-CHAT.md "Separation of pack
operations and pack product" rule (lines 65-72) requires this isolation.

### BACKLOG.md (pack repo) — pack-development backlog of BD-NNN items

**Location(s):** `/Users/david/Developer/optiquity-ai-agent-config-pack/BACKLOG.md` (1618 lines).

**Role:** Pack-development backlog. Tracks every planned improvement to the
pack itself with `BD-NNN` identifiers (intentionally distinct from project
`TD-NNN` to avoid collision when projects vendor pack docs). Sections are
manually authored: `## How to use this file`, `## Active — v10 Scope`,
`## Resolved — v8 (March 2026)`, `## Deferred`. Resolved items are flipped
in place (Status flip + `Resolution:` line); see MEMORY note "Pack BACKLOG
has no Resolved section."

**Pack-prescribed?** **Yes** (for pack-repo use).
- Format: `BACKLOG.md` line 5 — *"Format follows the standard BACKLOG item
  format from METHODOLOGY.md Part 7."* (i.e., the pack reuses its own project
  format internally.)
- Required to exist by `validate-pack.py` Check 3 (`check_td_tbd_sentinels`).
- Cited as a key file in `CLAUDE.md` (pack), `AGENTS.md` (pack),
  `GEMINI.md` (pack), `PACK-CHAT.md`, `PACK-AGENTS.md`,
  `.claude/skills/pack-startup/SKILL.md`.

**Producers:**
- Pack Chat (CLI session) — exclusive write authority per `CLAUDE.md`
  (pack) line 71: *"BACKLOG.md (PM chat only, after user approval)."*
- Manual edits at PR review time (rare).

**Consumers:**
- `pack-startup` skill Step 2 — *"Read `BACKLOG.md` in full."*
- `pack-startup` skill Step 4 — counts `Status: Open + Status: Unblocked`
  for the ready report.
- `validate-pack.py` Check 3 — scans for `**TD-TBD —` entry headers (line
  179 regex: `r"\*\*TD-TBD\s*—"`).
- Pack agents (`pack-architect`, `pack-planner`, `pack-reviewer`,
  `pack-docs-researcher`) at session start.
- Commit-message generation: every `feat: vN — BD-NNN ...` commit cites
  an item from this file.

**Cross-references in:** Commit messages name `BD-NNN`; CHANGELOG.md
entries name `BD-NNN` per-bullet.

**Cross-references out:** Items reference each other via `Blockers:` /
`Unblocks:`; reference `maintenance-docs/` design docs by path; reference
specific scripts and template files.

**Format rules (cited):**
- `METHODOLOGY.md` § Part 7 "BACKLOG item format" (lines 984-1017).
  Required keys per entry: `Type:`, `Status:`, `Blockers:`, `Unblocks:`,
  `File/Symbol:`, `Description:`, `Context:`, `Resolution:`. Status set
  is closed: `Open | Unblocked | Resolved | Cancelled | Deprecated`.
- `BACKLOG.md` line 5 cites the same.
- `validate-pack.py` Check 3 (line 179): an entry header must be a real
  `BD-NNN`, never literal `TD-TBD` (the latter is a defect).

**Implicit expectations:**
- The `## How to use this file` heading is part of normal content (no
  lint rule enforces it).
- Section ordering convention `Active — v<current>` first, then resolved
  versions descending, then `## Deferred` last is convention-only —
  enforced by Pack Chat behavior, not validation.
- `pack-startup` step 2 reads the file *in full*, so whatever section
  ordering the file has is the order presented to the agent.
- `pack-startup` step 4 *counts* "Status: Open + Status: Unblocked" lines
  case-sensitively; any future status-name change must update the skill.
- The "highest existing BD-NNN, increment by 1" rule (CLAUDE.md/AGENTS.md/
  GEMINI.md, all three) requires monotonic number assignment; gaps are
  permitted but never re-used.

**validate-pack.py checks:** Check 3 (`check_td_tbd_sentinels`, lines
163-185).

**Pack-prescribed vs author-discretion:** Pack-prescribed for the pack
repo (a single canonical instance, owned by the pack maintainer).

---

### CHANGELOG.md (pack repo) — pack version history

**Location(s):** `/Users/david/Developer/optiquity-ai-agent-config-pack/CHANGELOG.md` (472 lines).

**Role:** Authoritative dated history of pack changes, organized by version
header (`## v10 — April 2026`, `### v10.0 (post-release patches) — April
2026`, etc.). Each commit-batch contributes one or more bullets; bullets
typically open with the affected file path and the BD-NNN tag in
parentheses.

**Pack-prescribed?** **Yes** (for pack-repo use).

**Producers:**
- Pack Chat exclusively, at version boundaries, per `CLAUDE.md` (pack)
  line 55: *"CHANGELOG.md only at version boundaries with explicit
  instruction."*

**Consumers:**
- `pack-startup` skill Step 2: "Read only the most recent dated entry
  from `CHANGELOG.md`."
- Pack agents reading version context.
- Tag-move ceremony: `bare major tag always floats to latest minor` requires
  reading CHANGELOG to confirm latest tag.

**Cross-references in:** Pack commits describing what changed; cites
`BD-NNN` per bullet.

**Cross-references out:** References `BACKLOG.md` items, `maintenance-docs/`
design docs, scripts, template files.

**Format rules (cited):**
- No formal validate-pack check on CHANGELOG.
- `PACK-CHAT.md` lines 41-46 list it under "File access strategy" with
  *"Direct read (last entry only)"*.
- Convention-only: `## v<N>` H2 per major version, `### v<N>.<M>` H3 per
  minor.

**Implicit expectations:**
- "Most recent dated entry" — `pack-startup` reads only the top of file,
  so newest-first order inside the file is required.
- `## v<N>` H2 boundary must be parsable; `pack-startup` does not
  programmatically parse but other readers may.

**validate-pack.py checks:** None directly. Check 4 (`check_readme_version`)
checks README.md version table consistency, not CHANGELOG itself.

**Pack-prescribed vs author-discretion:** Pack-prescribed.

---

### README.md version table (pack repo) — version index

**Location(s):** `/Users/david/Developer/optiquity-ai-agent-config-pack/README.md` (232 lines), the `## Version History` section's table.

**Role:** Newest-first table of pack versions. Three commits ago
(`56b3057`) reversed it to newest-first to match `pack-startup` skill's
"first data row is the current version" assumption. The bare major tag
(e.g., `v10`) always floats to latest minor.

**Pack-prescribed?** **Yes** (for pack-repo use).

**Producers:** Pack Chat only.

**Consumers:**
- `pack-startup` skill Step 4 — reads the version table and reports
  `**Current version:** v[N.N]`.
- `validate-pack.py` Check 4 (`check_readme_version`) — verifies version
  table format (newest-first, version cells matching `vN.N`).
- `validate-pack.py` Check 9(d) (`check_init_project_structure`) —
  asserts README contains `detect.sh` and `MIGRATION-vN-to-vM.md`
  literal strings (line 542, 549).

**Cross-references in:** Repository Layout section and version table.

**Cross-references out:** Each row cites a tag and a brief description.

**Format rules (cited):**
- `pack-startup` skill line 24-26: *"the table under `## Version History`
  is sorted newest-first. The first data row is the current version."*
- `validate-pack.py` Check 4 enforces this format.

**Implicit expectations:**
- "First data row is current" — newest-first sort order is now contractual.
- The Repository Layout section is the authoritative repo-structure
  reference cited by all three pack-side trinity files.

**validate-pack.py checks:** Check 4, Check 9(d).

**Pack-prescribed vs author-discretion:** Pack-prescribed.

---

### CLAUDE.md / AGENTS.md / GEMINI.md (pack repo) — pack-side trinity

**Location(s):**
- `/Users/david/Developer/optiquity-ai-agent-config-pack/CLAUDE.md` (77 lines)
- `/Users/david/Developer/optiquity-ai-agent-config-pack/AGENTS.md` (71 lines)
- `/Users/david/Developer/optiquity-ai-agent-config-pack/GEMINI.md` (62 lines)

**Role:** Behavioral rules for agents operating *on the pack repo itself*.
Same trinity rule applies as project-template (parallel edits required).
Each cites BACKLOG.md, CHANGELOG.md, README.md as key files for pack
agents to read.

**Pack-prescribed?** **Yes** — by their own internal rules and by the
trinity rule (CLAUDE.md line 58-64; AGENTS.md line 52-58; GEMINI.md
line 42-46).

**Producers:** Pack Chat only.

**Consumers:**
- Claude Code, Codex, Gemini CLI auto-load these at session start.
- `pack-startup` skill Step 2: *"Read `PACK-CHAT.md` in full"* (PACK-CHAT
  cites these); pack agents are expected to read them.
- `validate-pack.py` checks: Check 16 (`## Project addenda` H2 — currently
  scoped to `project-template/`, NOT pack-repo trinity); Check 17
  (`check_trinity_h2_parity`) and Check 18 (`check_trinity_no_scaffolding_comments`)
  — same scoping note.

**Cross-references in:** Each lists `README.md`, `BACKLOG.md`, `CHANGELOG.md`,
`PACK-CHAT.md`, `PACK-AGENTS.md` as key files. CLAUDE.md (pack) line 71-74:
list of "what agents must never modify without explicit instruction" includes
BACKLOG.md, README.md version table, PACK-CHAT.md, the trinity files.

**Cross-references out:** Each names commit format, BD numbering rule,
trinity rule. GEMINI.md adds Gemini-CLI-specific operational notes.

**Format rules (cited):**
- Trinity rule applies (parallel edits required for content the rule
  covers; tool-specific deviations require justification).
- `validate-pack.py` Check 17 enforces H2 parity *for project-template
  copies* (lines 1021-1093). Pack-repo copies are intentionally not
  bound to identical H2 lists; the rule still requires symmetric content.

**Implicit expectations:**
- All three name a "Trinity rule" section that explicitly says "This rule
  also applies to the pack-repo copies of these three files." (CLAUDE.md
  line 64; AGENTS.md line 58; GEMINI.md line 46.)

**validate-pack.py checks:** None directly on pack-repo trinity. Checks
16, 17, 18 scope to `project-template/`.

**Pack-prescribed vs author-discretion:** Pack-prescribed.

---

### PACK-CHAT.md — Pack Chat operating instructions

**Location(s):** `/Users/david/Developer/optiquity-ai-agent-config-pack/PACK-CHAT.md` (163 lines).

**Role:** Operating manual for the Pack Chat (the persistent CLI session
maintaining the pack repo). Defines startup procedure, file access
strategy (table at lines 40-47), behavioral rules (lines 50-99),
session-naming scheme, cross-machine instructions, "Keeping
CLAUDE.md/AGENTS.md/GEMINI.md/PACK-AGENTS.md current" rule.

**Pack-prescribed?** **Yes**. Author of itself; only Pack Chat may
modify per CLAUDE.md (pack) line 73.

**Producers:** Pack Chat only.

**Consumers:**
- `pack-startup` skill Step 2: "Read `PACK-CHAT.md` in full — this
  establishes your behavioral rules for this session."
- Pack agents (per PACK-AGENTS.md line 104-106).

**Cross-references in:** Names BACKLOG.md, CHANGELOG.md, README.md,
METHODOLOGY.md, project-template/docs/pack/prompts/*.md as files the
Pack Chat reads on demand.

**Cross-references out:** PACK-AGENTS.md.

**Format rules:** None enforced. Convention only.

**Implicit expectations:** The "File access strategy" table (lines 40-47)
is the authoritative declaration of which pack-repo files are read
directly vs. on-demand by the Pack Chat.

**validate-pack.py checks:** None.

**Pack-prescribed vs author-discretion:** Pack-prescribed.

---

### PACK-AGENTS.md — pack agent routing table

**Location(s):** `/Users/david/Developer/optiquity-ai-agent-config-pack/PACK-AGENTS.md` (125 lines).

**Role:** Platform-agnostic routing table for the four pack agents
(`pack-architect`, `pack-planner`, `pack-reviewer`, `pack-docs-researcher`),
the skills they load, invocation methods, when to use which.

**Pack-prescribed?** **Yes**. Pack Chat-only edits (CLAUDE.md pack line 74).

**Producers:** Pack Chat only.

**Consumers:** All four pack agents (read at session start per their own
agent definitions); Pack Chat itself.

**Cross-references in:** Names skills (`planning`, `architecture-review`,
`documentation`, `review`, `dependency-intake`) and four pack agents.

**Cross-references out:** `.claude/agents/`, `.codex/agents/`,
`.gemini/agents/`, `.claude/skills/`, `.codex/skills/`, `.gemini/skills/`
(roster locations).

**Format rules:** None enforced. Convention only.

**Implicit expectations:** Skill list at lines 27-32 must match the actual
skill directories under `.claude/skills/`. Currently consistent: present
dirs are `architecture-review`, `dependency-intake`, `documentation`,
`pack-startup`, `planning`, `review`.

**validate-pack.py checks:** None directly. Check 11
(`check_pack_agent_trinity`, lines 634-700) covers the pack-roster agent
files but not PACK-AGENTS.md itself.

**Pack-prescribed vs author-discretion:** Pack-prescribed.

---

### TD-TBD comments in pack repo source

**Location(s):** All 13 occurrences are in
`scripts/validate-pack.py` *as code that documents and enforces* the
TD-TBD rule (lines 8, 84, 86, 87, 88, 163, 165, 166, 172, 174, 178, 179, 180).
**Zero occurrences in pack source code that would be defects.**

**Pack-prescribed?** N/A (pack repo source has no real TD-TBD; the format
itself is prescribed for downstream projects in Part 7 of METHODOLOGY).

**Producers:** Pack Chat / pack agents may write into validate-pack.py
when extending the rule. No coder-style writes occur in pack source.

**Consumers:** `validate-pack.py` Check 3 reads BACKLOG.md and rejects any
`**TD-TBD —` entry header.

**Implicit expectations:** Pack repo deliberately has no `TODO(scope):`
or `KNOWN GAP(severity):` deferral comments; the format is downstream-
project-only. The pack tracks its own work as `BD-NNN` in BACKLOG.md.

**validate-pack.py checks:** Check 3 (BACKLOG.md only).

**Pack-prescribed vs author-discretion:** Pack-prescribed (the system as
a whole).

---

### Files NOT present in pack repo (intentional absence)

These exist in `project-template/` and OT but **deliberately not** in the
pack repo root:

- `STATUS.md` — confirmed absent (`ls` returned `No such file or directory`).
- `IMPLEMENTATION_PLAN.md` — confirmed absent.
- `PACK-FEEDBACK.md` (at root) — confirmed absent. (A `project-template/
  docs/pack/PACK-FEEDBACK.md` template exists for downstream projects to
  copy; the pack repo itself does not maintain a PACK-FEEDBACK.md.)
- `ARCHITECTURE.md` — confirmed absent.

This absence is enforced by the PACK-CHAT.md "Separation of pack operations
and pack product" rule (lines 65-72): the pack tracks its own work via
BACKLOG.md / CHANGELOG.md / README.md and **does not adopt** the
project-side document set.

---

## Pass B — Project surface (project-template/) and OT comparison

The pack ships these flat files for projects, distributed by
`scripts/init-project.sh` (new and existing-empty projects) and
`scripts/migrate-v9-to-v10.sh` (v9.3 → v10 upgrade). The flat-file
surface in `project-template/` covers both **trinity templates**
(at `project-template/CLAUDE.md` etc.) and **`docs/pack/` templates**
(at `project-template/docs/pack/...`). State-bearing project documents
themselves (`BACKLOG.md`, `STATUS.md`, etc.) are NOT shipped pre-populated;
they are written by the project's PM chat at kickoff.

### IMPLEMENTATION_PLAN.md — phase definitions for the project

**Location(s):**
- Pack: not shipped as a template (no `project-template/IMPLEMENTATION_PLAN.md`,
  no `project-template/docs/project/IMPLEMENTATION_PLAN.md`).
- Project (per pack prescription): `docs/project/IMPLEMENTATION_PLAN.md`
  (CLAUDE.md `## Document locations` table, line 198:
  *"`ARCHITECTURE.md`, `IMPLEMENTATION_PLAN.md`, `BACKLOG.md`,
  `STATUS.md`, `CHANGELOG.md` | PM chat and developer during active
  development"*).
- OT actual: `/Users/david/Developer/OptiquityTrader/docs/project/IMPLEMENTATION_PLAN.md` (5235 lines).

**Role:** All project phases with tasks, DoD, agent assignment, risks.
Append-only by phase; never edit prior phases.

**Pack-prescribed?** **PARTIAL.**
- *Existence and location*: prescribed.
  - METHODOLOGY.md Part 2 line 113: lists `IMPLEMENTATION_PLAN.md`
    among "Standard Project Documents" with purpose, who-writes,
    who-updates.
  - Trinity `## Document locations` line 198 places it in
    `docs/project/`.
  - Document hygiene rules line 124: *"ARCHITECTURE.md and
    IMPLEMENTATION_PLAN.md are source of truth — they must reflect
    reality."*
  - Document hygiene rules line 128-132: agents must not modify
    IMPLEMENTATION_PLAN.md unless explicitly instructed.
- *Phase format*: prescribed.
  - METHODOLOGY.md Part 4 (lines 245-292) defines exact format:
    `## Phase N — [Title]`, `**Goal**:`, `**Prerequisite**:`,
    `### Tasks` with `#### N.1 — [Task title]` sub-headings,
    `### Verification`, `### Agent`, `### Risks`. Sub-procedure
    "Multi-part phases" defines `### Part N` sub-format.
  - METHODOLOGY.md Part 4 lines 275-281 — phase numbering rules
    (insertion of new phase numbers at the end, never renumber).
- *Anchor format for STATUS.md links*: prescribed.
  - PM-CHAT.md line 161-165 + STATUS.md `## How to Update This File`
    section in OT line 134-139: lowercase, spaces → hyphens, em-dash
    `—` removed (leaves `--`), special chars stripped.
- *Initial-content shape*: project-author-discretion. The pack ships no
  template body — the planner agent and PM chat draft Phase 0 content
  per project.

**Producers:**
- PM chat + planner agent (METHODOLOGY.md Part 2 table line 113:
  "PM chat + planner agent | Each phase adds entries; never delete old
  phases").
- Architect agent during architecture-correction phases.

**Consumers:**
- `pm-startup` skill Step 2: *"Identify the current phase from STATUS.md,
  then read only that phase's section from `IMPLEMENTATION_PLAN.md`."*
- `coder.md` prompt Variant: standard (lines 14, 17): required reading.
- `reviewer.md` prompt (lines 20-21): required reading "Phase [X] in full".
- `planner.md` prompt (line 16): required reading.
- `pm-chat.md` Variant: backlog-status-update (lines 156-166): STATUS.md
  links must point to `IMPLEMENTATION_PLAN.md#anchor`.
- `architect.md` (lines 25, 35, 56): required reading + propose-text-changes
  target.
- `tester.md`, `auditor.md`, `docs-researcher.md`: read for context.

**Cross-references in:** All agent prompts.

**Cross-references out:** Phase headings are anchor targets for STATUS.md
links.

**Format rules (cited):** METHODOLOGY.md Part 4 lines 245-292.

**Implicit expectations:**
- *Anchor stability*: STATUS.md phase-completion table builds links
  programmatically using a deterministic GitHub-anchor algorithm
  (lowercase, spaces→hyphens, em-dash removed leaves `--`, special
  chars stripped). If a phase's `### Tasks` heading or `## Phase N`
  title text changes after STATUS.md links are written, the links break
  silently. No validate-pack check enforces this.
- *Phase numbering monotonicity*: METHODOLOGY § Part 4 line 275-281 —
  phases are appended; renumbering breaks references in BACKLOG entries
  (`Blockers: phase-N`), TD-TBD code comments (`// TODO(phase-N): TD-TBD`),
  and CHANGELOG entries.
- *"Phase N" string format*: hardcoded in `// TODO(phase-N):` deferral
  scope (METHODOLOGY § Part 7 line 964: valid scope `phase-N`). Numeric;
  must match an actual `## Phase N` heading.
- *pm-startup Step 2*: reads "current phase" by section heading match —
  expects `## Phase ` H2 prefix pattern. No fallback if phases use any
  other shape.

**validate-pack.py checks:** None. (The check would have to know the
project structure, which the pack does not validate.)

**OT actual state:**
- Located at `docs/project/IMPLEMENTATION_PLAN.md` per pack prescription.
- 5235 lines, follows the Part 4 format strictly (verified via grep:
  `^## Phase N — `, `### Tasks`, `### Verification`, `### Agent`,
  `### Risks`).
- Adds an OT-specific `## Codebase Snapshot` table at the top (lines 10-29)
  before Phase 0 — author-discretion content; the pack does not prescribe
  or forbid such a section.
- Top-of-file metadata block (`> **Generated**: 2026-03-20`,
  `> **Updated**: ...`, `> **Based on**: ...`, `> **Target**: ...`) is
  OT-author-discretion.

**OT divergence from prescription:**
- None on format. The "Codebase Snapshot" table and metadata block are
  permitted under "project-author-discretion" content additions.
- Phase numbering shows non-monotonic gaps (Phases 18-24 superseded by
  later phases; Phases 43-58 inserted out of numeric order). This is
  consistent with METHODOLOGY § Part 4 line 282-291 which permits
  inserting phases at the end with new higher numbers.

---

### BACKLOG.md (project) — project technical debt + deferred items

**Location(s):**
- Pack: not shipped as a template body. Format prescribed only.
- Project (per pack prescription): `docs/project/BACKLOG.md`.
- OT actual: `/Users/david/Developer/OptiquityTrader/docs/project/BACKLOG.md` (1471 lines).

**Role:** All project deferred items, technical debt, known gaps,
verification items. Items use `TD-NNN` identifier (project-side; pack
uses `BD-NNN`).

**Pack-prescribed?** **YES (format strict, location strict, content
shape strict).**
- METHODOLOGY.md Part 2 line 115: "BACKLOG.md | Technical debt, deferred
  items, known gaps | PM chat | Add/resolve; never delete items."
- METHODOLOGY.md Part 7 lines 933-1212: full system spec (comment format,
  BACKLOG entry format, status state machine, six procedures).
- METHODOLOGY.md Part 7 line 984-1017: required entry shape.
- METHODOLOGY.md Part 7 line 1003-1013: status state machine.
- METHODOLOGY.md Part 7 lines 1019-1212: Procedures 1, 2, 3, 4, 5, 5-C,
  5-R, 5-S, 6, 7 — many touch BACKLOG.md.

**Producers:** PM chat exclusively (METHODOLOGY § Part 7 line 1207-1212
"Agent BACKLOG write permissions" table — only PM chat may write).

**Consumers:**
- `pm-startup` skill Step 2: "Read `BACKLOG.md` in full" (full file).
- `pm-startup` skill Step 6: counts `Status: Open + Status: Unblocked`
  for "Open BACKLOG items" line; reads `Last TD number`.
- `coder.md` Variant: standard (line 52): coders may use BACKLOG context
  but must not write.
- `reviewer.md` (lines 61-68): grep `TD-TBD`; verify each `TD-NNN` in
  reviewed code has a matching BACKLOG entry.
- `tester.md` (lines 17-18, 24-28, 35, 54): read for context.
- `auditor.md` (lines 18, 42, 48, 91): cross-reference findings to
  BACKLOG; never write.
- `pm-chat.md` Variant: backlog-status-update (lines 98-153): targeted
  edit instructions.
- `audit-methodology` skill lines 113, 146-147.
- METHODOLOGY § Part 7 Procedure 1 step 1 (line 1024): "Read BACKLOG.md
  in full".
- METHODOLOGY § Part 7 Procedure 1 step 2 (lines 1025-1029): for every
  Open item, walk Blockers and unblock if all resolved.
- METHODOLOGY § Part 7 Procedure 1 step 4 (lines 1034-1036): grep
  `TD-TBD`; any result is a defect.
- METHODOLOGY § Part 7 Procedure 3 (lines 1086-1102): orphan audit at
  every phase gate.
- METHODOLOGY § Part 7 Procedure 4 step 4 (lines 1118-1125): disposition
  scan when item resolved/cancelled/deprecated.
- METHODOLOGY § Part 7 Procedure 4 step 1 (line 1107): "from gate check
  approval".

**Cross-references in:** Code deferral comments (`TD-NNN`), CHANGELOG
entries (`mark resolved TD items ✅ in the same commit`), STATUS.md
"Active Backlog" section (OT line 80-103 lists TD-NNN ranges by category).

**Cross-references out:** BACKLOG entries reference `phase-N` (must
match IMPLEMENTATION_PLAN.md), `TD-NNN` (must match other BACKLOG
entries), `File/Symbol:` (must match a real source location).

**Format rules (cited):**
- METHODOLOGY § Part 7 line 984-1001: required keys per entry.
- METHODOLOGY § Part 7 line 1015: "TD counter: read BACKLOG.md, find the
  highest existing TD number, set counter to that value + 1."
- METHODOLOGY § Part 7 line 994: `Unblocks` is informational only;
  actionability is derived only from `Blockers`.
- METHODOLOGY § Part 7 line 1013: "Items are never deleted. Items with
  no blockers start as Unblocked."

**Implicit expectations:**
- *Highest TD number is at the bottom or scannable*: Procedure 1 step 1
  reads BACKLOG.md in full to find max TD, but in a 1471-line OT file
  this is expensive. The "TD counter" rule is monotonic — gaps allowed.
- *Section organization*: METHODOLOGY does not prescribe section
  ordering inside BACKLOG.md. OT organizes by `## Phase N — ...`
  headings (each with `### Technical Debt`); pack-template ships no
  explicit section convention.
- *Resolved items: in-place flip, never moved*: METHODOLOGY § Part 7
  line 1013, OT BACKLOG.md observed practice (e.g., TD-001 line 13 has
  "✅ RESOLVED (Phase 14)" in the same position as Open items).
  MEMORY note "Pack BACKLOG has no Resolved section" generalizes this:
  no separate Resolved section is created in either pack or project
  BACKLOG.
- *`✅ RESOLVED (Phase N)` status decoration*: OT-specific shorthand on
  the entry header line (in addition to `Status: Resolved`); NOT
  prescribed by METHODOLOGY but compatible.
- *grep -c "Status: Open"*: pm-startup line 121 counts open items by
  literal `Status: Open` lines. Format change here breaks the count.
- *Active statuses are exactly `Open` and `Unblocked`*: METHODOLOGY § Part
  7 line 1011. Tools that count active items rely on this exact spelling.
- *TD counter is text-derived from BACKLOG.md*: there is no separate
  numeric counter file; the "next TD" is computed by scanning all
  `TD-NNN` occurrences in BACKLOG.md and taking max+1. Monotonicity
  comes from this scan, not from any persistent counter.

**validate-pack.py checks:** None for project BACKLOG.md (the pack
validates its own BACKLOG via Check 3 only).

**OT actual state:**
- Located at `docs/project/BACKLOG.md` (per prescription). 1471 lines.
- Uses `TD-001`...`TD-113`, conforms to METHODOLOGY § Part 7 entry
  format.
- Section organization: by phase (`## Phase 10 — Public.com Broker
  Integration` → `### Technical Debt`); also `## Simulation Layer`,
  `## How to use this file`, `## Phase 35 §35.5 — Broker Compliance
  Audit` with `### Critical / ### Architecture / ### Code / ### Tests`
  sub-sections (lines 925-1040).
- "✅ RESOLVED (Phase N)" decoration on entry-header lines after Status.

**OT divergence from prescription:**
- *Section organization* — by phase + ad-hoc category sections — is
  OT-author-discretion (METHODOLOGY does not prescribe).
- *Header decoration "✅ RESOLVED (Phase N)"* — OT-author-discretion
  display layer; the underlying `Status: Resolved` line is still
  present.
- *`How to use this file` section at line 485* (mid-file) — anomaly;
  OT placed it inside the file body rather than at the top. Pack
  BACKLOG (pack repo) puts it at line 9, near top. Likely a v9-era
  artifact preserved through migrations.

---

### STATUS.md — current phase state, phase table, key metrics

**Location(s):**
- Pack: not shipped as a template body.
- Project (per pack prescription): `docs/project/STATUS.md`.
- OT actual: `/Users/david/Developer/OptiquityTrader/docs/project/STATUS.md` (139 lines).

**Role:** Current phase, phase completion table (linked to
IMPLEMENTATION_PLAN.md anchors), active backlog summary, key metrics,
next actions.

**Pack-prescribed?** **YES (location strict, format partially strict).**
- METHODOLOGY.md Part 2 line 116: "STATUS.md | Current phase, phase
  table, next actions, key metrics | PM chat or developer | After every
  phase completion".
- METHODOLOGY.md Part 2 hygiene rule line 127: "STATUS.md is updated
  after every phase — stale status is worse than no status."
- PM-CHAT.md (project-template) line 119: "Direct read | Small, changes
  every phase, must always be current".
- PM-CHAT.md lines 160-165: phase title links must use
  `[Title](IMPLEMENTATION_PLAN.md#anchor)` with the documented anchor
  algorithm.
- INSTALL-PROCEDURES § Procedure 5-S Task A (line 865): explicit search
  order `docs/project/STATUS.md`, then `docs/STATUS.md`, then
  `STATUS.md`. Codifies the canonical project-side location.
- pm-chat.md prompt Variant: backlog-status-update (line 156-166):
  format guidance for STATUS edits.

**Producers:** PM chat or developer.

**Consumers:**
- `pm-startup` skill Step 2 (line 70): reads STATUS.md in full.
- `pm-startup` skill Step 2 (line 76-77): identifies "current phase
  from STATUS.md, then read only that phase's section from
  `IMPLEMENTATION_PLAN.md`".
- `pm-startup` Step 6 (line 120): reports "**Current phase:** Phase N —
  [title] ([not started / in progress / complete])".
- `auditor.md` (line 48): "do not write to BACKLOG.md, STATUS.md".
- INSTALL-PROCEDURES § Procedure 5-S Task A (line 865): post-migration
  housekeeping greps for "AI Agent Config Pack" / "Pack version" + `v9`
  token; offers to update version.
- METHODOLOGY § Part 7 Procedure 1 step 2 (line 1027): "Phase N blocker:
  has that phase been committed and marked ✅ in STATUS.md?" — agents
  scan STATUS.md for `✅` at the phase row.

**Cross-references in:** Phase table column "Title" links to
`IMPLEMENTATION_PLAN.md#anchor`; "Active Backlog" section may list
`TD-NNN` ranges.

**Cross-references out:** Each phase row's anchor must resolve to a
real `## Phase N` heading in IMPLEMENTATION_PLAN.md (anchor algorithm
is implicit — no validate-pack check).

**Format rules (cited):**
- METHODOLOGY.md Part 2 line 116 (sections required: current phase,
  phase table, next actions, key metrics).
- PM-CHAT.md lines 160-165 (anchor algorithm).
- pm-startup skill line 76: "current phase" must be parseable. The skill
  does not prescribe a specific marker — it relies on prose to identify
  the phase.

**Implicit expectations:**
- *Phase row markers `✅ Complete` / `⬜ Not started` / `➡ Merged into
  Phase N` / `➡ Superseded by Phase N`*: present in OT, not codified
  in METHODOLOGY. Agents that "check ✅ in STATUS.md" (METHODOLOGY § Part
  7 Procedure 1 step 2) are reading these by character. The exact
  emoji set is OT convention; pack documentation says only "marked ✅".
- *"Current phase" is identified by a level-2 heading or by table state*:
  pm-startup says "identify the current phase from STATUS.md" but does
  not specify how. OT puts it under `## Current Phase` at the top.
- *"Pack version"*: Procedure 5-S Task A greps for "AI Agent Config Pack"
  or "Pack version" + a `v9` token. OT line 113 has `**AI Agent Config
  Pack**: v10` under `## Key Metrics`. The format is convention only.
- *Phase title link consistency*: anchor algorithm (lowercase, em-dash
  removed → `--`, special chars stripped) — drift between actual phase
  title and computed anchor breaks links silently.

**validate-pack.py checks:** None.

**OT actual state:**
- Located at `docs/project/STATUS.md` (per prescription). 139 lines.
- Section structure: `## Current Phase`, `## Phase Completion` (table),
  `## Active Backlog` (TD-NNN ranges by category), `## Key Metrics`,
  `## Next Actions`, `## How to Update This File`.
- `## Key Metrics` at line 113 has `**AI Agent Config Pack**: v10`.
- `## How to Update This File` at line 128-139 self-documents the anchor
  algorithm.

**OT divergence from prescription:**
- None on location.
- `## How to Update This File` self-documentation section is OT-author-
  discretion (METHODOLOGY does not require it but PM-CHAT line 160-165
  documents the same algorithm in the canonical location).
- Phase-row markers (`⬜`, `➡`) are OT convention; pack only
  prescribes `✅`. Architect note: any tracker-integration must
  preserve free-form markers OR map them to fixed states.

---

### CHANGELOG.md (project) — append-only project history

**Location(s):**
- Pack: not shipped as a template body.
- Project (per pack prescription): `docs/project/CHANGELOG.md`.
- OT actual: `/Users/david/Developer/OptiquityTrader/docs/project/CHANGELOG.md` (2579 lines).

**Role:** Permanent dated history of what was built. One entry per phase,
written after reviewer approval.

**Pack-prescribed?** **YES (location strict, format partially strict).**
- METHODOLOGY.md Part 2 line 114: "CHANGELOG.md | Permanent dated
  history of what was built | PM chat | One entry per phase, after
  reviewer approval; coder proposes entry in completion report".
- METHODOLOGY.md Part 2 hygiene rule line 125: "CHANGELOG.md is
  append-only — never edit old entries."
- Trinity (CLAUDE.md project-template line 246-250): coder must include
  a "Proposed CHANGELOG entry" section in completion reports, formatted
  exactly as it would appear; coder must not write CHANGELOG directly.
- coder.md Variant: standard line 95-98 same.
- coder.md Variant: standard line 165-166: "Root .md file prohibition".

**Producers:** PM chat (after reviewer approval).

**Consumers:**
- `pm-startup` skill Step 2 (line 74): "Read only the most recent dated
  section from `CHANGELOG.md`."
- `coder.md` Variant: standard (line 17): required reading.
- `reviewer.md` (line 20): required reading "(Phase [X] entry)".
- `tester.md` (line 17): required reading.
- `documentation` skill line 41 (skill #18): "CHANGELOG drift —
  CHANGELOG entries must match git history. Flag entries that claim
  features not actually committed".
- `documentation` skill line 44: drift severity rules.

**Cross-references in:** Coder completion reports (Proposed CHANGELOG
entry); BACKLOG resolution lines may cite the CHANGELOG date/phase.

**Cross-references out:** Per-entry "Files created/modified" lists
reference real source paths; entries name `BACKLOG.md` items resolved.

**Format rules (cited):**
- The project may extend the format. OT line 11-29 documents an
  expanded entry format (`### YYYY-MM-DD — Phase N — Title`,
  `**Summary**: ...`, body, `**Files created**`, `**Files modified**`,
  `**Test count**: N passing, 0 failing`, `**Build warnings**: 0`).
- Trinity coder rule (CLAUDE.md project-template line 246-250) requires
  "dated header, summary paragraph, itemised task list, files
  created/modified, and final test count" — partially codifies the OT
  shape.

**Implicit expectations:**
- *"Most recent dated section"*: pm-startup reads top-of-file. Newest-
  first is required (OT line 32: "**Append-only**: never edit prior
  entries. Add new entries at the top.").
- *Date in heading*: parseable by `YYYY-MM-DD` prefix in the H3 (OT
  format) or by some date field. Pack does not prescribe; OT prescribes
  via its own `## Format Rules` section.
- *Separator (`---`) before every entry*: OT convention (line 35).

**validate-pack.py checks:** None.

**OT actual state:**
- `docs/project/CHANGELOG.md` 2579 lines.
- Self-documents its own format at top in `## Format Rules` section
  (lines 7-39). Pack does not prescribe the H2 "Format Rules" section.

**OT divergence from prescription:**
- *`## Format Rules` self-documentation section*: OT-author-discretion.
- *Entry shape* (`### YYYY-MM-DD — Phase N — Title`, etc.): partially
  prescribed (coder.md requires "dated header, summary paragraph, ...");
  OT specializes the date format and label syntax. Compatible.

---

### PACK-FEEDBACK.md (project) — upstream feedback log to Pack Chat

**Location(s):**
- Pack template: `project-template/docs/pack/PACK-FEEDBACK.md` (449 lines).
- Project (per pack prescription): `docs/pack/PACK-FEEDBACK.md`.
- OT actual: `/Users/david/Developer/OptiquityTrader/docs/pack/PACK-FEEDBACK.md` (420 lines).

**Role:** Append-only log of observations from the project's PM chat to
the pack maintainer. Categories: Workflow Observations, Prompt Variant
Observations (v10), Agent Performance Log, User Friction Log, Pack Chat
Open Questions, Delivery Log. Status field tracks pack version, last
delivery date.

**Pack-prescribed?** **YES (template, location, format strict).**
- METHODOLOGY.md Part 2 line 119: "PACK-FEEDBACK.md | Upstream feedback
  log to Pack Chat — observations, not solutions | PM chat | Continuously
  (append-only); delivered at workflow boundaries (Part 10)".
- METHODOLOGY.md Part 2 hygiene rule line 133-134: "PACK-FEEDBACK.md in
  particular is never written by any agent — it is the PM chat's
  feedback log to the upstream pack."
- METHODOLOGY.md Part 10 (lines 1302-1349): "Pack Feedback Loop" full
  spec.
- Template body (PACK-FEEDBACK.md) self-documents structure inline
  (lines 16-160).
- PM-CHAT.md project-template line 121: "PACK-FEEDBACK.md | Direct read +
  append writes | PM-chat-owned feedback log for the pack itself".
- PM-CHAT.md lines 166-172: full Pack feedback loop behavioral rule.

**Producers:** PM chat exclusively. *Never* an agent (METHODOLOGY § Part
2 hygiene rule 5; CLAUDE.md project-template line 280-284:
"Never write to `PACK-FEEDBACK.md` under any circumstance — it is the
PM chat's upstream feedback log for the AI Agent Config Pack itself.").

**Consumers:**
- Pack Chat (when receiving a delivered batch).
- Procedure 1 step 6 skill-gap check (METHODOLOGY § Part 7 line 1049-1052):
  "If no matching skill exists in the pack: flag to user AND record in
  PACK-FEEDBACK.md".

**Cross-references in:** PACK-FEEDBACK observations may reference
`BACKLOG.md`, `STATUS.md`, agent prompt variants, METHODOLOGY workflows
1-6.

**Cross-references out:** Delivery prompts go to Pack Chat (out-of-band
hand-off, not a file reference).

**Format rules (cited):**
- Template self-documents.
- Prompt-variant section names must match the agent-file/variant pair
  (PACK-FEEDBACK.md lines 200-244 enumerate per-variant subsections).
- Status state machine for `## Pack Chat Open Questions` items
  (PACK-FEEDBACK.md lines 140-154): {Not Ready, Ready, Prompt Provided,
  Closed, Resolved (No Change), Deprecated}. Status changes must include
  date in parens.

**Implicit expectations:**
- *Append-only*: never modify past entries (PACK-FEEDBACK.md line 136).
- *"Status" table at top*: pack version, project name, project start
  date, last delivery date — all required by template.
- *Per-variant subsections*: the template enumerates subsections by
  variant name; new pack variants require a new subsection. Stale
  variant names (e.g., a v9.3 project with "Prompt Template Observations"
  rather than v10's "Prompt Variant Observations") are an unenforced
  drift.

**validate-pack.py checks:** None directly. Check 6
(`check_prompts_directory`) verifies the variants exist; nothing checks
PACK-FEEDBACK has matching subsections.

**OT actual state:**
- `/Users/david/Developer/OptiquityTrader/docs/pack/PACK-FEEDBACK.md`
  (420 lines).
- Header line 1: `# PACK-FEEDBACK.md — Feedback to the AI Agent Config Pack`
  (matches template).
- Status table (line 6-13): `Pack version in use | v9.3` (STALE — OT is
  on v10 per STATUS.md line 113); other fields filled.
- **Section "Prompt Template Observations" (line 165)** — template name
  from v9.3 era (PROMPT-TEMPLATES.md monolith), not the v10
  "Prompt Variant Observations" name. The migration was supposed to
  reconcile this via Procedure 5-C.

**OT divergence from prescription:**
- Status `Pack version in use` is stale (`v9.3` vs actual `v10`). This is
  the exact symptom Procedure 5-S Task A is designed to surface.
- "Prompt Template Observations" section name is v9.3-era; v10 template
  uses "Prompt Variant Observations". OT was reverted from migration so
  this is expected; the migration's Procedure 5-C step would have
  reconciled.

---

### ARCHITECTURE.md — architectural decisions, layer map, patterns

**Location(s):**
- Pack: not shipped as template body.
- Project (per pack prescription): `docs/project/ARCHITECTURE.md`.
- OT actual: `/Users/david/Developer/OptiquityTrader/docs/project/ARCHITECTURE.md` (5848 lines).

**Role:** Architecture of record. Authored by architect agent at kickoff;
updated whenever architecture changes.

**Pack-prescribed?** **PARTIAL.**
- *Existence and location*: prescribed (METHODOLOGY § Part 2 line 112).
- *Content shape*: not prescribed. Architect agent shapes it per project.
- *Required-reading by other agents*: prescribed.
  - architect.md (line 25, 56), coder.md (line 17), reviewer.md (line 20),
    planner.md (line 16), tester.md (line 17), pm-chat.md (line 51-52)
    all require ARCHITECTURE.md as required reading.
- *"Rejected-alternative documentation rule"* (METHODOLOGY § Part 3
  lines 216-242): for correctness-sensitive design decisions, architect
  must document considered alternatives, why each rejected, why chosen
  approach is correct *in ARCHITECTURE.md at the decision site, not
  only in the planning conversation*.

**Producers:** Architect agent (kickoff); architect agent on mid-phase
correction; PM chat editing.

**Consumers:** All agents read for context (per their prompt
"required reading" line).

**Cross-references in:** Phases reference ARCHITECTURE sections;
BACKLOG.md may reference it for context.

**Cross-references out:** Per-section narrative.

**Format rules:** None codified beyond the "rejected alternatives must
appear at the decision site" rule.

**Implicit expectations:**
- Section structure is project-author-discretion.
- pm-startup does NOT read ARCHITECTURE.md proactively (pm-startup Step 2
  list does not include it). Read only on demand.

**validate-pack.py checks:** None.

**OT actual state:** 5848 lines; OT-shaped section structure.

**OT divergence from prescription:** Content is OT-discretion; no
divergence on hygiene rules.

---

### TD-TBD comments in project source — typed deferral system

**Location(s):**
- Pack repo source: zero (see Pass A).
- Project (per pack prescription): in any source file across `*.swift`,
  `*.py`, `*.ts`, etc.
- OT actual: 88 typed deferral comments (matched
  `// TODO(...)` / `// KNOWN GAP(...)` / `// VERIFY(...)` / Python `#`
  variants in `*.swift` / `*.py`); 147 lines containing real `TD-NNN`
  references in OT source. Zero `TD-TBD` sentinels currently committed
  in OT source.

**Role:** Pack's typed deferral comment scheme. Three forms with required
labels:
```
// TODO(scope): TD-TBD — Short title
// KNOWN GAP(severity): TD-TBD — Short title
// VERIFY(source): TD-TBD — Short title
```
Closed enumerations:
- `scope` ∈ {`phase-N`, `dependency`, `feature`, `perf`, `version`}
- `severity` ∈ {`critical`, `functional`, `polish`}
- `source` is a free-form external source name (e.g., `apple-docs`).

**Pack-prescribed?** **YES (format strict, lifecycle strict).**
- METHODOLOGY.md Part 2 hygiene rule 6 (line 135-138): "Every deferral
  comment ... must have a corresponding BACKLOG.md entry. `TD-TBD` in
  any committed file is a defect."
- METHODOLOGY.md Part 7 lines 946-983: full format spec.
- Trinity (CLAUDE.md project-template lines 259-291; AGENTS.md and
  GEMINI.md parallel): same format, same lifecycle rule, same
  "Always write `TD-TBD` — never invent a TD number" rule.
- coder.md Variant: standard line 71-79: format + reporting requirement.
- coder.md Variant: standard line 79: deferred-items reporting line in
  completion report.
- reviewer.md line 61-68: grep `TD-TBD`; cross-check `TD-NNN` ↔ BACKLOG.

**Producers:**
- Coder agent writes `// TODO(scope): TD-TBD — title` (always literal
  `TD-TBD`).
- PM chat replaces `TD-TBD` with `TD-NNN` after BACKLOG entry created
  (METHODOLOGY § Part 7 line 1078-1079).

**Consumers:**
- pm-startup skill Step 5 (lines 101-108): `grep -rn "TD-TBD" .` — any
  result is a defect.
- METHODOLOGY § Part 7 Procedure 1 step 4 (lines 1034-1036): same grep
  at every phase gate.
- METHODOLOGY § Part 7 Procedure 3 (orphan audit, lines 1086-1102): grep
  for typed comments; cross-check `TD-NNN` ↔ BACKLOG entries; verify
  Type, severity/scope, short-title match between comment and entry.
- reviewer.md line 61-68: per-phase reviewer check.
- review skill line 21 (skill #10): "Check for deferred work: `TODO`,
  `KNOWN GAP`, `VERIFY` comments must use the project's typed format
  with `TD-TBD`."
- pm-chat.md Variant: backlog-status-update (line 137 fragment): may
  read TD comments as part of status update.

**Cross-references in:** Coder writes them when authoring code.

**Cross-references out:** Each comment's `TD-NNN` must match a BACKLOG
entry; the BACKLOG entry's Type, severity/scope, and short title must
match the comment.

**Format rules (cited):**
- METHODOLOGY § Part 7 lines 946-983.
- Trinity files lines 264-275.
- coder.md prompt lines 71-79.

**Implicit expectations:**
- *Comment → BACKLOG synchronization*: orphan audit (Procedure 3) catches
  drift but only when run; no automated enforcement.
- *PM chat's responsibility to rewrite `TD-TBD` → `TD-NNN`*: the
  in-source rewrite is a manual editing step. Procedure 2 step 5 (line
  1077-1078) "Replace TD-TBD with TD-NNN in the source file comment".
- *Comment removal on item Cancelled/Deprecated*: METHODOLOGY § Part 7
  line 1196-1199 ("If a deferral comment exists in source code for this
  item, remove it") and Procedure 4 step 3 (line 1117). Manual.

**validate-pack.py checks:** Check 3 covers BACKLOG.md only. The pack
ships no validator that runs against project source; downstream
projects rely on pm-startup, reviewer, and Procedure 3 manual scans.

**OT actual state:**
- 88 typed deferral comments matching the format.
- 147 source lines reference real `TD-NNN` numbers.
- Zero `TD-TBD` currently committed (consistent with rule).
- Examples: `StubQuoteService.swift:18: KNOWN GAP(polish): TD-031`,
  `ETradeBroker.swift:758: KNOWN GAP(dependency): TD-071`,
  `PublicBroker.swift:472: TODO(phase-35): TD-003`.

**OT divergence from prescription:** None. OT's TD-TBD discipline is
clean.

---

### project-template/CLAUDE.md / AGENTS.md / GEMINI.md — project-side trinity

**Location(s):**
- Pack template: `project-template/CLAUDE.md` (363 lines), `AGENTS.md`
  (339 lines), `GEMINI.md` (391 lines).
- Project (per pack prescription): `<project-root>/CLAUDE.md`,
  `AGENTS.md`, `GEMINI.md`.
- OT actual: `/Users/david/Developer/OptiquityTrader/{CLAUDE,AGENTS,GEMINI}.md`
  (539 / 524 / 571 lines respectively).

**Role:** Project context files. Trinity rule: identical content for
non-tool-specific concerns. Each contains:
- `## Document locations` (the authoritative path map for this project).
- `## Build and repo hygiene` (CHANGELOG / coder rule).
- `## Deferral comments and BACKLOG hygiene` (TD-TBD format).
- `## Skill loading` (Active skills line — read by pm-startup Step 3).
- `## Project addenda` (project-original content; required by validate-
  pack Check 16).

**Pack-prescribed?** **YES (template, format, trinity-rule strict).**

**Producers:**
- `init-project.sh` S5 copies pack template; placeholders filled by PM
  chat at kickoff.
- `migrate-v9-to-v10.sh` S5 splices/merges; project-owned `## Custom
  agents` / `## Custom skills` sections preserved.
- PM chat for Active-skills updates and `## Project addenda` content.

**Consumers:**
- Claude Code, Codex, Gemini auto-load at session start.
- `pm-startup` Step 3 (line 84-88): reads `## Skill loading` section's
  Active-skills line.
- `pm-startup` Step 6 (line 127): reports Active skills.
- pm-chat.md (line 112-114): "All documentation lives under `docs/`. See
  `CLAUDE.md` § 'Document locations' for the full directory map."
- Procedure 6 step 6.3 (METHODOLOGY § Part 7 line 1167): trinity TRIO
  edits — byte-identical content across all three.
- Procedure 5-S Task B (INSTALL-PROCEDURES line 866): grep all three for
  the closed-form placeholder whitelist (`[PROJECT_NAME]`, etc.).

**Cross-references in:** Active skills line is updated when skills
added/removed; `## Document locations` table cites every prescribed
file.

**Cross-references out:** `## Document locations` is the authoritative
path resolver — pm-startup Step 2 line 81: "Use the Document locations
section in the project context file to resolve file paths."

**Format rules (cited):**
- METHODOLOGY § Part 2 lines 117-118: trinity contains project-specific
  rules and agent roster.
- validate-pack.py Check 16 (`check_trinity_addenda_h2`): requires
  `## Project addenda` H2 with HTML-comment placeholder marker
  `<!-- Project addenda go here`.
- validate-pack.py Check 17 (`check_trinity_h2_parity`): H2 lists
  must be parallel across the three files (with documented exceptions).
- validate-pack.py Check 18 (`check_trinity_no_scaffolding_comments`):
  scaffolding HTML comments must be removed before commit.

**Implicit expectations:**
- *`## Document locations` as path resolver*: pm-startup Step 2 reads
  state files by literal name (`BACKLOG.md`, `STATUS.md`, etc.) and uses
  the trinity table to resolve to `docs/project/`. If a project edits
  the table to move a file (e.g., to root), pm-startup follows.
  However, **other consumers do not honor this resolver** — see Risks
  below.
- *Active skills line shape*: prescribed shape is bracketed list on a
  line beginning `**Active skills:**`. pm-startup parses this.

**validate-pack.py checks:** Check 16, 17, 18.

**OT actual state:**
- Trinity at OT root, sizes 539 / 524 / 571 lines.
- `## Document locations` table at line 178-187 places state files in
  `docs/project/`.

**OT divergence from prescription:** None. Trinity is canonical post-
revert.

---

### project-template/docs/pack/PM-CHAT.md — project PM chat operating manual

**Location(s):**
- Pack template: `project-template/docs/pack/PM-CHAT.md` (442 lines).
- Project (per pack prescription): `docs/pack/PM-CHAT.md`.
- OT actual: `/Users/david/Developer/OptiquityTrader/docs/pack/PM-CHAT.md`
  (418 lines).

**Role:** PM chat startup procedure, file access strategy table,
behavioral rules (including the BACKLOG/STATUS/PACK-FEEDBACK ownership
rules and STATUS phase-link anchor algorithm), tool-specific session
naming.

**Pack-prescribed?** **YES (template strict, content owned by pack with
small project-owned markers).**
- INSTALL-PROCEDURES § Procedure 5-C.3 (lines 489-551): the migration's
  reconciliation procedure for PM-CHAT.md treats it as "T (template)
  → P (intermixed prose after kickoff fill)" — i.e., pack-owned with
  project-name fill at kickoff plus optional role-paragraph
  customization.
- Project name H1 (`# [PROJECT_NAME] — PM Chat Instructions`): filled
  during kickoff.
- "Additional project documents" section: filled per project at
  kickoff.

**Producers:**
- init-project.sh / migrate-v9-to-v10.sh copy template.
- PM chat fills placeholders at kickoff.

**Consumers:**
- Claude Code, Codex, Gemini auto-load via the trinity files.
- pm-startup Step 2 (line 71): reads in full.
- pm-startup Step 6 (line 112-114): reads project name from H1.

**Cross-references in:** Heading 1 has project name; "Additional
project documents" section may list project-specific docs.

**Cross-references out:** References METHODOLOGY.md throughout; names
PLATFORM-SKILLS.md, all state files (BACKLOG, STATUS, IMPLEMENTATION_PLAN,
CHANGELOG, PACK-FEEDBACK).

**Format rules (cited):**
- INSTALL-PROCEDURES § Procedure 5-C.3 line 540-545: three placeholder
  shapes must be substituted — `[PROJECT_NAME]`, `[project-short-name]`,
  `/path/to/your-project`.
- Procedure 5-C.3 line 535-538: post-reconciliation grep must produce no
  output for `\[(PROJECT_NAME|project|project-short-name)\]` and
  `/path/to/your-project`.

**Implicit expectations:**
- *PM-CHAT is not under the trinity rule* (Procedure 5-C.3 line 550:
  "PM-CHAT.md is not under the trinity rule; no cross-file symmetry
  check applies.").
- *File access strategy table (lines 116-130)* is the de-facto contract
  between PM chat and the project's flat-file surface — every file
  named here is assumed by the PM chat at runtime.

**validate-pack.py checks:** None directly. Check 6 verifies prompts
directory exists (related but not PM-CHAT specific).

**OT actual state:**
- 418 lines. Smaller than template (template is 442) — expected for a
  reconciled project.
- Project H1 filled with `# OptiquityTrader — PM Chat Instructions`.

**OT divergence from prescription:** Apparent divergence on date is
expected — OT was reverted from migration, this is a v9.3-shape
PM-CHAT.md awaiting reconciliation.

---

### project-template/docs/pack/PLATFORM-SKILLS.md — skill matrix

**Location(s):**
- Pack template: `project-template/docs/pack/PLATFORM-SKILLS.md` (342 lines).
- Project: `docs/pack/PLATFORM-SKILLS.md`.
- OT actual: `/Users/david/Developer/OptiquityTrader/docs/pack/PLATFORM-SKILLS.md` (342 lines).

**Role:** Pack-published matrix of available skills × platform/language
dimensions. Consulted by PM chat when generating agent prompts.

**Pack-prescribed?** **YES (pack-owned, with project-owned `## Custom
agents` and `## Custom skills` sections per Procedure 5-C.4).**

**Producers:** Pack version updates only (METHODOLOGY § Part 2 line 120
analog: "Updated by | Pack version updates only"). The marker-
section convention (BD-059 introduced) reserves project-owned regions.

**Consumers:**
- pm-startup Step 2 (line 72): reads in full.
- METHODOLOGY § Part 7 Procedure 1 step 6 (skill gap check, line 1045):
  "if a matching skill exists in the pack (check PLATFORM-SKILLS.md)".
- pm-chat.md Variant: standard (line 144-146): "Select skills using
  PLATFORM-SKILLS.md."
- Procedure 5.2 (custom skill creation): adds `### x-<name>` row in
  `## Custom skills`.
- Procedure 6 step 6.4: PLATFORM-SKILLS.md row for newly-activated
  dimension may need acknowledgement (informational).

**Format rules (cited):** Marker-section convention introduced in v10
preserves `## Custom agents` and `## Custom skills` H2 regions during
pack updates.

**Implicit expectations:** PM chat trusts the matrix when generating
prompts — drift between matrix and shipped skills is a pack defect.

**validate-pack.py checks:** None directly. The skill list is matched
against `project-template/skills/` via Check 1
(`check_skill_frontmatter`).

**OT actual state:** OT has the same template-shaped file (matched
template byte count 342 lines).

**OT divergence from prescription:** None observed.

---

### project-template/docs/pack/INSTALL-PROCEDURES.md — install / migration / kickoff procedures

**Location(s):**
- Pack source: `supporting-docs/INSTALL-PROCEDURES.md` (1230 lines).
- Pack-template: not directly under `project-template/docs/pack/`;
  copied at install/migrate time by `init-project.sh` S6 (line
  464-468) and `migrate-v9-to-v10.sh` (lines 985-996).
- Project: `docs/pack/INSTALL-PROCEDURES.md`.
- OT actual: `/Users/david/Developer/OptiquityTrader/docs/pack/INSTALL-PROCEDURES.md` (1230 lines).

**Role:** Hosts Procedures 5 / 5-C / 5-S / 7. Procedure 5-C is the
v9.3 → v10 reconciliation; 5-S is post-migration housekeeping; 7 is
kickoff auto-discovery.

**Pack-prescribed?** **YES.** Pack-owned, version-locked.

**Producers:** Pack updates only.

**Consumers:**
- pm-startup Step 0 (lines 21-39): detects `RECON-PENDING` /
  `POSTRUN-PENDING` sentinels and routes to INSTALL-PROCEDURES sections.
- METHODOLOGY § Part 7 Procedures 5, 5-C, 5-R, 5-S, 7 stubs all point
  here (METHODOLOGY lines 1129, 1133, 1137, 1141, 1186).

**Cross-references in:** All from METHODOLOGY pointer-stubs.

**Cross-references out:** References the migration-backup directory
(`.pack-migration-backup/v9.3-to-v10.0/`), the `*.v9-customized` sidecar
naming, the trinity files, PM-CHAT.md, PLATFORM-SKILLS.md.

**Format rules:** None codified beyond "do not edit projects' copy."

**Implicit expectations:** The "Project file conventions in pack-
controlled directories" section (lines 27-78) defines the **`x-` prefix**
contract for project-added files in pack-controlled directories.

**validate-pack.py checks:** Check 9 (`check_init_project_structure`)
verifies INSTALL-PROCEDURES.md exists in supporting-docs; Check 14
(`check_disposition_table_documented`) checks the disposition table;
Check 15 (`check_migration_test_runs_clean`).

**OT actual state:** Synced from migration (file is 1230 lines, identical
size to pack source).

**OT divergence:** None.

---

### project-template/docs/pack/METHODOLOGY.md — methodology reference

**Location(s):**
- Pack source: `supporting-docs/METHODOLOGY.md` (1394 lines).
- Project: `docs/pack/METHODOLOGY.md`.
- OT actual: `/Users/david/Developer/OptiquityTrader/docs/pack/METHODOLOGY.md` (1394 lines).

**Role:** Project-agnostic methodology. The single source of truth for
the BACKLOG/TODO system (Part 7), workflows (Part 5), agent roster
(Part 3), document set (Part 2), prompt-authoring principles, audit
checkpoints (Part 6), pack feedback loop (Part 10).

**Pack-prescribed?** **YES.** Pack-owned.

**Producers:** Pack updates only.

**Consumers:** Read on demand by PM chat and all agents. RAG ingest
target (pm-startup Step 4 lines 91-99: re-ingest if changed since last
known ingest).

**Cross-references in:** Every other pack doc references parts of
METHODOLOGY.

**Cross-references out:** Self-references (Part N → Part M).

**Format rules (cited):** None codified.

**Implicit expectations:** Section structure is stable (Parts 1-10 +
Appendix); pm-startup Step 2 line 79 reads "first 5 lines" for version
number — the version line must be at the top.

**validate-pack.py checks:** Indirect (doc references in Check 9 require
specific docs to exist).

**OT actual state:** synced from migration (1394 lines, matches pack).

**OT divergence:** None.

---

### project-template/docs/pack/prompts/*.md — per-agent prompt templates

**Location(s):**
- Pack template: `project-template/docs/pack/prompts/{architect,auditor,
  coder,docs-researcher,grpc-schema,planner,pm-chat,repo-ops,reviewer,
  tester}.md` (10 files; one per pack agent).
- Project: `docs/pack/prompts/`.

**Role:** Per-agent prompt generation templates with `## Variant: <name>`
sections. PM chat composes prompts by reading the appropriate variant.

**Pack-prescribed?** **YES (template strict; project-added prompts use
`x-` prefix per the convention).**

**Producers:** Pack-owned (pack updates only). Project may add
`x-<name>.md` prompt files.

**Consumers:** PM chat at prompt-generation time.

**Cross-references in/out:** Each prompt names state files
(IMPLEMENTATION_PLAN, ARCHITECTURE, CHANGELOG, BACKLOG, STATUS,
PACK-FEEDBACK) per variant. The pm-chat.md prompt is the one that
defines the workflow for editing these state files.

**Format rules (cited):**
- METHODOLOGY § Prompt Authoring Principles (lines 546-829).
- Labeled-section convention enforced by validate-pack.py Check 10
  (`check_prompt_triad_compliance`): every `## Variant:` must have
  `**Problem:**`, `**Goal:**`, `**Success criteria:**`, plus a
  `REPORT FILE:` or `**Completion report:**` indicator. Kickoff
  variant exempted via `**Convention exception:**` marker.

**Implicit expectations:**
- The "required reading" section in each prompt names state files by
  bare name, not path — relies on `## Document locations` in trinity to
  resolve. Same path-resolution convention as pm-startup.
- `pm-chat.md` Variant: backlog-status-update (lines 98-166) is the
  programmatic spec for BACKLOG/STATUS edits. Includes the BACKLOG
  entry shape, status state machine, anchor algorithm.

**validate-pack.py checks:** Check 6 (presence + count), Check 10
(triad compliance).

**OT actual state:** OT has these files post-migration; current state
on `main` reflects revert.

**OT divergence:** Not currently relevant (revert-state).


---

### project-template/skills/pm-startup/SKILL.md — PM chat startup skill

**Location(s):**
- Pack template: `project-template/skills/pm-startup/SKILL.md` (130 lines).
- Project: `.claude/skills/pm-startup/SKILL.md`,
  `.codex/skills/pm-startup/SKILL.md`,
  `.gemini/skills/pm-startup/SKILL.md` (per-tool copies).
- OT actual: all three present, identical content to pack template.

**Role:** PM chat startup orchestrator. The MOST important consumer of
the project flat-file surface — defines what files are read and how
state is computed for the ready report.

**Pack-prescribed?** **YES.** Pack-owned skill.

**Producers:** Pack updates only.

**Consumers:** Triggered by `/pm-startup` slash command at session
start.

**Cross-references in:** None to project state.

**Cross-references out:** Reads `BACKLOG.md`, `STATUS.md`, `PM-CHAT.md`,
`PLATFORM-SKILLS.md`, `CHANGELOG.md` (top), `IMPLEMENTATION_PLAN.md`
(current-phase section), `METHODOLOGY.md` (first 5 lines for version),
trinity `## Skill loading` section. Step 0 reads
`.pack-migration-backup/v9.3-to-v10.0/postrun-pending` and looks for
`*.v9-customized` sidecars. Step 5 greps `TD-TBD` across `*.swift`,
`*.py`, `*.md`.

**Format rules (cited):** None — skill is the rule consumer.

**Implicit expectations (the load-bearing surface for the architect):**
- *State files referenced by bare name, not path*: Step 2 (line 67-77)
  uses literal filenames (`BACKLOG.md`, `STATUS.md`, etc.) and tells
  the agent to "Use the Document locations section in the project
  context file to resolve file paths." This is a CLI-tool path-resolver
  contract: the trinity `## Document locations` table is the binding
  authority. Any tracker integration that replaces these flat files
  must update the trinity to the new resolver path, OR keep the flat
  file as a generated mirror.
- *Step 6 reports parsed counts*: `Open BACKLOG items` ← count of
  `Status: Open + Status: Unblocked` lines in BACKLOG.md;
  `Last TD number` ← max `TD-NNN` found in BACKLOG.md;
  `TD-TBD check` ← count of grep hits across source.
- *Step 0 sentinel detection*: hard-coded path
  `.pack-migration-backup/v9.3-to-v10.0/postrun-pending`. Migration
  reconciliation routes through here.
- *Step 4 RAG re-ingest*: assumes mcp-local-rag tool available;
  silently no-ops on tools without it.

**validate-pack.py checks:** Check 1 (`check_skill_frontmatter`)
verifies frontmatter shape; nothing checks Step content.

**Pack-prescribed vs author-discretion:** Pack-prescribed.

---

## Other consumers of the flat-file surface (cross-cutting)

These read or reference state files but were not given dedicated
sections above; documented here in summary.

| Consumer | What it reads/writes | Where |
|---|---|---|
| `audit-methodology` skill | BACKLOG.md, STATUS.md (read-only enforced); CHANGELOG drift | `project-template/skills/audit-methodology/SKILL.md` lines 113, 146-147 |
| `documentation` skill | CHANGELOG drift detection rules | line 41, 44 |
| `review` skill | TD-TBD comment format check | line 21 (#10) |
| `auditor.md` Variant: standard | Cross-reference to BACKLOG processing | lines 18, 42, 48, 91 |
| `init-project.sh` | Creates `docs/pack/`, `docs/project/`, `docs/reference/` (line 291); copies template files to `docs/pack/`; copies METHODOLOGY.md and INSTALL-PROCEDURES.md | scripts/init-project.sh |
| `migrate-v9-to-v10.sh` | Reconciles `docs/pack/PM-CHAT.md`, `docs/pack/METHODOLOGY.md`, `docs/pack/INSTALL-PROCEDURES.md`, `docs/pack/PLATFORM-SKILLS.md`, prompts dir; sidecars `.v9-customized` for project-customized files; emits `postrun-pending` | scripts/migrate-v9-to-v10.sh |
| `repo-ops` skill | Read-only access to all flat files | (no specific file refs) |

---

## Summary

### All flat files in scope, classified

| File | Pack-side path | Project-side path | Pack-prescribed? |
|---|---|---|---|
| BACKLOG.md (pack) | `BACKLOG.md` | n/a | Yes |
| CHANGELOG.md (pack) | `CHANGELOG.md` | n/a | Yes |
| README.md version table (pack) | `README.md` | n/a | Yes |
| CLAUDE.md / AGENTS.md / GEMINI.md (pack) | root | n/a | Yes |
| PACK-CHAT.md | `PACK-CHAT.md` | n/a | Yes |
| PACK-AGENTS.md | `PACK-AGENTS.md` | n/a | Yes |
| IMPLEMENTATION_PLAN.md | n/a (no template body) | `docs/project/IMPLEMENTATION_PLAN.md` | **Partial** — location and Part-4 phase format prescribed; content body author-discretion |
| BACKLOG.md (project) | format only (METHODOLOGY § Part 7) | `docs/project/BACKLOG.md` | Yes (location + format strict) |
| STATUS.md | n/a | `docs/project/STATUS.md` | Yes (location + sections required) |
| CHANGELOG.md (project) | n/a | `docs/project/CHANGELOG.md` | Yes (location + entry-shape partially strict) |
| ARCHITECTURE.md | n/a | `docs/project/ARCHITECTURE.md` | **Partial** — location prescribed; content shape author-discretion (except "rejected alternatives" rule) |
| PACK-FEEDBACK.md | `project-template/docs/pack/PACK-FEEDBACK.md` | `docs/pack/PACK-FEEDBACK.md` | Yes (template + format strict) |
| project trinity (CLAUDE/AGENTS/GEMINI.md) | `project-template/{CLAUDE,AGENTS,GEMINI}.md` | root | Yes (template + trinity-rule strict; small project-owned regions) |
| PM-CHAT.md (project) | `project-template/docs/pack/PM-CHAT.md` | `docs/pack/PM-CHAT.md` | Yes (pack-owned with kickoff fill) |
| PLATFORM-SKILLS.md | `project-template/docs/pack/PLATFORM-SKILLS.md` | `docs/pack/PLATFORM-SKILLS.md` | Yes (pack-owned + project marker sections) |
| METHODOLOGY.md (project) | `supporting-docs/METHODOLOGY.md` | `docs/pack/METHODOLOGY.md` | Yes (pack-owned) |
| INSTALL-PROCEDURES.md (project) | `supporting-docs/INSTALL-PROCEDURES.md` | `docs/pack/INSTALL-PROCEDURES.md` | Yes (pack-owned) |
| docs/pack/prompts/*.md | `project-template/docs/pack/prompts/` | `docs/pack/prompts/` | Yes (template + triad rule); project additions via `x-` prefix |
| TD-TBD comment system (project source) | format-only (METHODOLOGY § Part 7) | any source file | Yes (format + lifecycle strict) |

### IMPLEMENTATION_PLAN.md classification result

**Pack-prescribed: PARTIAL.** Existence, location (`docs/project/`), and
phase-format (METHODOLOGY § Part 4 lines 245-292) are pack-prescribed.
The content body of phases is project-author-discretion. The phase-anchor
algorithm used by STATUS.md links is pack-prescribed (PM-CHAT.md lines
160-165). Phase numbering monotonicity is pack-prescribed (METHODOLOGY
§ Part 4 lines 275-281).

This is NOT an OT-specific file. Every project receiving the pack is
expected to have one, written by the planner agent + PM chat at
kickoff. Six other agents read it as required reading.

### TD-TBD inventory summary

| Repo | TD-TBD literals | Real `TD-NNN` references | Typed deferral comments |
|---|---|---|---|
| Pack repo (source: `*.swift`, `*.py`, etc.) | 13 (all in `validate-pack.py` documenting the format) | n/a (pack uses `BD-NNN`, not `TD-NNN`) | 0 |
| OT (source: `*.swift`, `*.py`) | 0 (clean — discipline holds) | 147 lines | 88 typed comments |

Notable concentrations in OT:
- `OptiquityTrader/Data/Brokers/ETrade/ETradeOrderService.swift` — 7
  occurrences of `KNOWN GAP(dependency): TD-071` (single TD repeated at
  multiple sites).
- `OptiquityTrader/Data/Brokers/Public/PublicBroker.swift` — 5+
  occurrences (TD-003, TD-006, TD-022, TD-050).

### Implicit format expectations the architect must preserve

These are unwritten contracts the architect would otherwise miss.

1. **Trinity `## Document locations` is the path resolver** — pm-startup
   Step 2 reads files by bare name and trusts the trinity table to
   resolve. PM-CHAT.md and prompt files do the same. Any v11
   tracker-integration that moves a file's canonical location must
   update the trinity in the same change.

2. **State files are read full or top-only by deterministic strategy** —
   per the PM-CHAT file-access table:
   - `BACKLOG.md`, `STATUS.md`, `PM-CHAT.md`, `PLATFORM-SKILLS.md`:
     full read.
   - `CHANGELOG.md`: top entry only — newest-first sort is contractual.
   - `IMPLEMENTATION_PLAN.md`: current-phase section only —
     current-phase identification driven by STATUS.md.
   - `METHODOLOGY.md`: top 5 lines for version, otherwise on-demand /
     RAG.
   Migration to a different store must preserve these access patterns
   or the cost of every PM session balloons.

3. **`Status: Open` / `Status: Unblocked` literal lines** are counted by
   pm-startup Step 6 line 121. The active-status set is
   `{Open, Unblocked}` — exactly two lexemes, case-sensitive.

4. **Highest-`TD-NNN` derivation is text-scan-based** — there is no
   counter file. Every actor that asks "what's the next TD number"
   greps BACKLOG.md.

5. **`✅` is the pack-prescribed status emoji in STATUS.md phase tables**
   (METHODOLOGY § Part 7 Procedure 1 step 2). OT adds `⬜` and `➡`
   markers; these are author-discretion. Tracker integration must either
   preserve emoji surface or map it.

6. **Phase-link anchor algorithm** (PM-CHAT.md lines 160-165): lowercase,
   spaces→hyphens, em-dash `—` removed (leaves `--`), special chars
   stripped. Hand-coded in PM-CHAT and replicated in STATUS.md `## How
   to Update This File`. No automated test enforces it.

7. **`postrun-pending` sentinel triggers Procedure 5-S** — the file path
   `.pack-migration-backup/v9.3-to-v10.0/postrun-pending` is hard-coded
   in pm-startup Step 0 line 22. Any v11 migration must either keep the
   convention, or update pm-startup atomically.

8. **`*.v9-customized` sidecar discovery is filesystem-wide** —
   pm-startup Step 0 line 24-26 finds all sidecars excluding
   `.pack-migration-backup/` and `.git/`. The naming pattern is the
   contract.

9. **`x-` prefix reserved for project-added files** in pack-controlled
   directories (INSTALL-PROCEDURES.md "Project file conventions" §, lines
   27-78). Pack-roster filenames never start with `x-`. This includes
   `docs/pack/prompts/`.

10. **PACK-FEEDBACK.md "Status" table at top contains pack-version-in-use**
    — Procedure 5-S Task A hunts this for v9 → v10 stale-marker
    correction. Any integration must keep the field discoverable.

11. **TD-TBD literal in code is a defect** — the sentinel is the
    pack-coder discipline-mark; reviewer/pm-startup/Procedure 1
    step 4/Procedure 3 all grep for it. The replacement to a real
    `TD-NNN` is a manual edit by the PM chat in Procedure 2 step 5.

12. **PACK-FEEDBACK.md, BACKLOG.md, STATUS.md are all "PM chat only" by
    rule** — coder/reviewer/auditor/docs-researcher/repo-ops are
    READ-ONLY (METHODOLOGY § Part 7 line 1207-1212; trinity files
    "Deferral comments and BACKLOG hygiene" sections; auditor.md line
    48; pm-chat.md line 157-159).

13. **The pack BACKLOG resolves in place** (no `## Resolved` section
    created) — MEMORY note `reference_pack_backlog_structure`. The
    pack BACKLOG has `## Resolved — v8 (March 2026)` as a *summary
    table* of v8 closures, not a destination. Items in `## Active —
    v10 Scope` flip to `Status: Resolved` in place. The project-side
    BACKLOG behaves the same per METHODOLOGY § Part 7 line 1013.

### Risks for migration to a tracker integration

R1. **Trinity `## Document locations` is read by humans and CLIs**, but
the pm-startup skill does not honor a path-mapping mechanism beyond
"use the table." If v11 introduces optional flat-file → tracker
mapping, every consumer that reads "BACKLOG.md by bare name" needs a
shim.

R2. **OT keeps state files at `docs/project/`** but pm-startup Step 5
greps `--include="*.md"` recursively from cwd, which crosses both
`docs/pack/` (pack-owned templates) and `docs/project/` (project
content). A `TD-TBD` literal accidentally landing in `docs/pack/`
sample text would trigger a false defect. Currently survives because
templates use the literal `TD-TBD` only as documentation of the
format — but the include-pattern is permissive.

R3. **Highest-`TD-NNN` derivation is brittle**. Tracker integration that
synthesizes IDs (e.g., GH issue numbers as `TD-NNN`) needs to keep the
text-scan path consistent or replace pm-startup Step 6 atomically.

R4. **Phase numbering crosses tools**. `// TODO(phase-N): TD-TBD`
references a `phase-N` scope; that string lives in source code. Any
v11 migration that renames or restructures phases requires a code-
sweeping pass.

R5. **`✅` emoji in STATUS.md is the trigger** for METHODOLOGY § Part 7
Procedure 1 step 2 phase-blocker resolution. Tools or trackers that
report phase status with non-emoji markers (`Done`, `closed`,
ticked-checkbox) require parser updates.

R6. **OT's actual STATUS.md, BACKLOG.md, IMPLEMENTATION_PLAN.md,
CHANGELOG.md add OT-specific top-of-file metadata (date stamps,
self-documenting "How to use", "Format Rules" sections)**. Migration
must round-trip these author-discretion sections without loss.

R7. **PACK-FEEDBACK.md status field drift** — OT carries `Pack version
in use | v9.3` while STATUS.md carries `v10`. Procedure 5-S Task A
exists exactly to catch this; an integration must not bypass it.

R8. **The `x-` prefix convention is the only deletion-safe contract for
project-added files in pack-controlled dirs**. v11 must not introduce
new project-owned filenames in those dirs without `x-` prefix.

R9. **`pm-startup` cross-tool replication** — the skill exists in three
copies (`.claude/`, `.codex/`, `.gemini/skills/pm-startup/`). Trinity-
adjacent: changes must replicate. validate-pack does not currently
enforce skill content parity.

R10. **No validate-pack check covers the project-side flat-file
hygiene**. Every rule is enforced at runtime by the agent or skill, not
by CI. Drift between BACKLOG entry shape and the comment format would
require an orphan-audit run to detect.

### Open questions left for the architect

OQ1. *What is the source of truth when a tracker is enabled?* For each
flat file, is the tracker authoritative and the flat file a mirror, or
vice versa? The map above shows what reads / writes / cross-references
each file but does not pre-decide directionality.

OQ2. *Does `## Document locations` become the integration's mapping
table, or is it superseded?* If the trinity stays as path-resolver,
flat files remain primary. If superseded by `.tracker-config.toml`-
style metadata, every consumer needs an update.

OQ3. *How do TD-TBD → BACKLOG → tracker-issue lifecycles interact?*
Currently: coder writes `TD-TBD` → PM chat creates BACKLOG entry +
rewrites comment to `TD-NNN`. With tracker: who creates the issue?
When? Who rewrites the comment? Procedure 2 step 5 changes if BACKLOG
is no longer the source of truth.

OQ4. *Per-procedure migration map.* Procedures 1, 2, 3, 4 in
METHODOLOGY § Part 7 each touch BACKLOG.md. If BACKLOG.md becomes a
mirror of the tracker, each procedure needs a tracker-aware path. This
inventory shows the call sites; the architect must design the
behaviors.

OQ5. *PACK-FEEDBACK.md's Status table* identifies `Pack version in
use`. With multi-source tracker integration, does this evolve to
include tracker config?

OQ6. *Does the migration script (forward and reverse) need to extract
data from the existing BACKLOG.md, STATUS.md, CHANGELOG.md to seed a
tracker, then keep them as projections, or treat them as legacy
read-only?* This inventory captures the read-write graph; the
architect decides directionality.

OQ7. *How do trinity `## Document locations` updates propagate when the
project opts in to a tracker?* All three files must change atomically;
validate-pack Check 17 enforces parity but the migration mechanism is
new ground.

OQ8. *The pack repo's own BACKLOG.md (BD-NNN) is intentionally
separated from project tracking*. Does v11's tracker integration apply
to the pack repo, the projects, or both? PACK-CHAT.md "Separation of
pack operations and pack product" rule frames this question.

