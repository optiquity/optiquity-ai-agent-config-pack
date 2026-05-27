---
name: boundary-investigation
description: Use before recommending or applying any change to a project-side file (project-template/ trees or pack-shipped client content). Codifies P-missed-7 — project-side SSOT investigation precedes pack-style defaults.
allowed-tools: Read, Grep, Glob
---

# Boundary investigation

## When this skill applies

This skill applies to any session whose scope includes a change to:

- `project-template/` (any file — agent prompts, skills, configs, trinity, docs)
- `supporting-docs/` (pack-internal content that may flag mis-location)
- Any pack-shipped client-installable directory (e.g., `project-template/.claude/`, `.codex/`, `.gemini/` parallels)

It does NOT apply to changes scoped entirely to pack-only files:
pack-repo root trinity (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` at repo
root), `pack-ops/` (any file there), `maintenance-docs/`, `scripts/`,
`test-fixtures/`, or the pack-repo `.claude/` / `.codex/` / `.gemini/`
dotted dirs at the pack repo root.

## Why this skill exists

<!-- DENY-LIST-CONTENT-START -->
Project and pack are intentionally designed differently. The pack repo
maintains its own operating rules (Pack Chat, pack-architect / pack-coder
/ etc. agent roster, `pack-ops/` operational docs, `maintenance-docs/`
design records). None of that infrastructure exists at a client install
— clients receive only the `project-template/` content distributed by
`scripts/init-project.sh`.

The audit incident (P-missed-7) documented the regression mechanism this
skill prevents: a reviewer or implementer, sticky on pack-side mental
models from a prior review/fix cycle, recommends or applies pack-side
mechanisms (e.g., "see `PACK-AGENTS.md` for the roster") inside a
project-side file. The pack-side reference is meaningless at a client
install — the file does not exist there. The contamination either
breaks at install (broken cross-reference) or pollutes the project's
design intent (importing pack-side orchestration into project-side
content).
<!-- DENY-LIST-CONTENT-END -->

The cure is mechanical: before recommending or applying any project-side
change, **investigate whether a project-side source of truth exists for
the concept being changed**, and cite or augment THAT — not the pack-side
equivalent the actor happens to know.

## Methodology (run BEFORE recommending or applying a change)

### Step 1 — Identify the concept being changed

What rule, reference, enumeration, or role is the proposed change adding,
modifying, or removing? Name it in plain language. Examples:

- "the agent roster"
- "the skill-selection matrix"
- "the feedback-to-pack channel"
- "the trinity-rule explanatory note"
- "the universal collaboration rules section"

### Step 2 — Locate the project-side SSOT for the concept

Search the project-side surface for the existing source of truth. Common
project-side SSOTs:

| Concept | Project-side SSOT |
|---|---|
| Agent roster + PM chat orchestration rules | `project-template/docs/pack/PM-CHAT.md` |
| Skill-selection matrix (5+3 dimensions) | `project-template/docs/pack/PLATFORM-SKILLS.md` |
| Project-to-pack feedback channel | `project-template/docs/pack/PACK-FEEDBACK.md` |
| Universal project rules (trinity) | `project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md` |
| Per-agent prompt templates | `project-template/docs/pack/prompts/<agent>.md` |
| Project-side skills (methodology) | `project-template/skills/<name>/SKILL.md` |
| Install + setup procedures | `project-template/docs/pack/INSTALL-PROCEDURES.md` |
| Methodology + procedures | `project-template/supporting-docs/METHODOLOGY.md` (when applicable) |

If the project-side SSOT for the concept is not obvious from this table,
grep `project-template/` for keywords related to the concept. The
authoritative source for the SSOT for an actively-maintained area lives
in `project-template/`.

### Step 3 — Decide the SSOT-relative action

- **SSOT exists, change is aligned:** recommend or apply the change as
  an augmentation to the SSOT (cite SSOT, edit SSOT, or reference SSOT
  — never duplicate).
- **SSOT exists, change conflicts:** flag the conflict. Do NOT apply.
  <!-- DENY-LIST-CONTENT-START -->
  Surface to Pack Chat (or the PM chat at a client install) for
  re-design.
  <!-- DENY-LIST-CONTENT-END -->
- **No SSOT exists, change is needed:** flag the gap. Do NOT improvise.
  Surface for "needs project-design rationale" — a new project-side
  SSOT may need to be designed before any project-side rule lands.
- **No SSOT exists, change is not needed:** drop the change.

### Step 4 — NEVER cross-reference pack-only paths from project-side files

The pack-only deny-list (not exhaustive; CI Check 37 enforces the
canonical list):

<!-- DENY-LIST-CONTENT-START -->
- **File names:** `PACK-AGENTS.md`, `PACK-CHAT.md`, `HELP-FRAGMENT-PACK.md`,
  `HELP-FRAGMENT-TRACKER.md` (bare-filename refs from project-side; the
  pack-ops copy lives at `pack-ops/HELP-FRAGMENT-TRACKER.md` per CI
  Check 24 byte-identity contract with `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`),
  `OPTIONAL-FEATURES.md` (bare-filename refs; project-side has its own
  `project-template/docs/pack/OPTIONAL-FEATURES.md`)
- **Path prefixes:** `maintenance-docs/`, `pack-ops/` (any file there —
  PACK × OPERATIONS files including `pack-ops/BOUNDARY-DEFINITION.md`,
  `pack-ops/BACKLOG.md`, `pack-ops/CHANGELOG.md`, `pack-ops/PACK-AGENTS.md`,
  `pack-ops/PACK-CHAT.md`, `pack-ops/HELP-FRAGMENT-PACK.md`,
  `pack-ops/HELP-FRAGMENT-TRACKER.md`, `pack-ops/OPTIONAL-FEATURES.md`,
  `pack-ops/MERGE-STRATEGY.md`, `pack-ops/DRY-RUN-MIGRATION.md`,
  `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`,
  `pack-ops/.boundary-exempt-root.txt`), `scripts/` (pack-repo only;
  project-side scripts live at `project-template/scripts/`),
  `test-fixtures/`
- **Agent names:** `pack-architect`, `pack-coder`, `pack-planner`,
  `pack-reviewer`, `pack-docs-researcher` (the five pack-* agents; the
  project agent roster is the unprefixed names — `architect`, `coder`,
  `planner`, `reviewer`, etc.)
- **Role names:** `Pack Chat` (capitalized as the pack-repo orchestrator
  role; lower-case "pack chat" describing the feedback flow in
  `PACK-FEEDBACK.md` / `PM-CHAT.md` / `METHODOLOGY.md` /
  `SETUP-EXISTING.md` is LEGITIMATE per audit §D-4)
- **Files exempt at pack root:** `tracker.toml.pack-example` (STAYS at
  pack root per pack-repo audit finding; not installed at
  client; bare-filename refs from project-side qualified by "in the
  pack repo" are LEGITIMATE distinction-callouts)
<!-- DENY-LIST-CONTENT-END -->

### Step 5 — Document the investigation in the deliverable

- **Reviewer:** under review dimension 9 (Boundary discipline) finding,
  name the project-side SSOT investigated (file path + relevant section)
  OR explicitly state "no SSOT exists for `<concept>` — flagging for
  project-design rationale before recommending content."
- **Implementer:** under IMPL-REPORT (or completion-report) "Boundary
  discipline check" section, name the project-side SSOT investigated
  per project-side edit. If a "Boundary discipline stop" was triggered
  (Step 4 deny-list hit), report (a) the proposed edit, (b) the
  pack-only target, (c) the project-side SSOT to use instead, (d) a
  request for re-prompting from the orchestrator with the corrected
  reference.

## Frame-rotation reminder

When reviewing or implementing a commit or batch that touches BOTH
pack-side and project-side files, mentally rotate frames between
pack-side and project-side. The same review dimension (e.g., "rule is
missing", "cross-reference is stale") has DIFFERENT correct answers
depending on which side the file lives on:

<!-- DENY-LIST-CONTENT-START -->
- **Pack-side correct answer:** cite pack-side SSOT
  (`CLAUDE.md` at pack root / `pack-ops/PACK-AGENTS.md` /
  `maintenance-docs/`).
- **Project-side correct answer:** cite project-side SSOT
  (`docs/pack/PM-CHAT.md` / `docs/pack/PLATFORM-SKILLS.md` / project
  trinity).
<!-- DENY-LIST-CONTENT-END -->

The bias to import framing from the earlier-reviewed side into the
later-reviewed side is real. This skill's Step 2 + Step 4 are the
explicit antidote.

## Worked example (V1 anti-pattern)

A pack reviewer flagged that the project trinity agent enumeration was
missing several auditor variants. The reviewer's recommendation was:

<!-- DENY-LIST-CONTENT-START -->
> "Add: see `PACK-AGENTS.md` for the full roster."
<!-- DENY-LIST-CONTENT-END -->

Running this skill against the recommendation:

- **Step 1:** Concept = "the project agent roster."
- **Step 2:** Project-side SSOT = `docs/pack/PM-CHAT.md` §
  "Pack agent roster" (the project-side authoritative roster, present
  at every client install).
- **Step 3:** SSOT exists, change is aligned — recommend the trinity
  cite `docs/pack/PM-CHAT.md` § "Pack agent roster" (NOT `PACK-AGENTS.md`
  which is pack-repo only).
- **Step 4:** The original recommendation's deny-list match
  (`PACK-AGENTS.md`) is exactly what this step catches. STOP and
  redirect to the project-side SSOT.
- **Step 5:** Reviewer's dimension 9 finding documents:
  "Recommended trinity cite `docs/pack/PM-CHAT.md` § 'Pack agent
  roster' (project-side SSOT) — NOT `PACK-AGENTS.md` which is pack-repo
  only and would break at client install."

The corrected recommendation lands in trinity at a client install
without breaking; the V1 regression is averted.
