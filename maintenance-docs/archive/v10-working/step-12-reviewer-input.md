# Step 12 Reviewer Input — Developer Notes

*These are corrections identified by the developer during G8 review
of the V10-DESIGN.md draft. The Step 12 pack-reviewer audit must
verify each is addressed. Fixes are applied by the pack chat before
Step 13 approval.*

---

## DN-1 — Capabilities pattern must not be forced

The BD-045 content throughout V10-DESIGN.md Part 3 uses "required"
language for the capabilities pattern (e.g., "LSP and capabilities
are independent required practices"). This is too strong.

**Correction:** The capabilities pattern is a recommended best
practice — championed proactively during architecture, not mandated.
If the project's architecture doesn't support it naturally or the
developer explicitly opts out, that is valid. The architecture-review
skill should flag absence as a finding (recommendation, not failure).
The auditor-architecture agent should surface it as a suggestion, not
a defect. The wording "required" must be changed to "recommended" or
"best practice" everywhere it refers to the capabilities pattern.
LSP remains required.

**Affects:** Part 3 §3.1, §3.2 (trinity file draft text), §3.3
(apple-architecture-core rules), §3.4 (python-best-practices rules),
§3.5 (future language skill template), §3.6 (architecture-review
rules), §3.7 (auditor-architecture bullets), §3.9 (relationship
statement). The BD-045 BACKLOG entry also uses "required" and should
be noted as superseded by this design decision.

---

## DN-2 — PLATFORM-SKILLS.md four dimensions must be supported equally

PLATFORM-SKILLS.md defines four skill-selection dimensions: Platform
Targets, Languages, Component Roles, and Communication Protocols. The
v10 design for custom skills and agents must ensure all four dimensions
are supported equally.

**Correction:** When the PM chat creates a custom skill (Procedure 5.2)
or custom agent (Procedure 5.1), the clarifying questions must include
which of the four dimensions the custom item covers. The Custom agents
and Custom skills sections in PLATFORM-SKILLS.md should classify
entries by dimension, matching how pack skills are organized. The prompt
template format, PM chat workflow, and detection scan must all handle
custom items from any dimension — not only language skills.

**Affects:** Part 5 §5.1 (creation workflow clarifying questions),
§5.2 (PLATFORM-SKILLS.md section column specs — may need a Dimension
column or classification), §5.7 (Procedure 5 outline — clarifying
questions list).

---

## DN-3 — Codex agent files require both `name` and `description`

During the v10 design process, a Codex smoke test revealed that Codex
CLI requires both `name` and `description` fields in `.codex/agents/
*.toml` files — agents missing either field are silently ignored
("malformed agent role definition"). This was fixed for all 20 existing
Codex agents in the pack.

**Correction:** Verify that V10-DESIGN.md consistently lists both
`name` and `description` as required fields wherever the Codex agent
file format is specified. Specifically: AD-2 §Codex row, Part 5 §5.1
creation workflow (the Codex agent file artifacts table), Part 5 §5.9
(registration artifacts for a Registered custom agent), and any
pseudocode or example that shows a Codex TOML file.

**Affects:** Part 2 AD-2, Part 5 §5.1, §5.9, any worked examples.

---

## DN-4 — No v9.x functionality regression without explicit deprecation

The v10 design changes docs, workflows, and processes significantly.
No v9.x capability should be lost unless it is explicitly deprecated
with a documented replacement.

**Correction:** V10-DESIGN.md must include an explicit statement
(in Part 0, Part 1, or a new section) that v10 preserves all v9.x
functionality unless explicitly noted otherwise. The following v9.x
capabilities must be verified as preserved:
- Developer choice of Claude Code CLI, Claude Desktop app, Codex CLI,
  or Gemini CLI for PM chat and agent work
- Developer can use Claude, Codex, and Gemini interchangeably for any
  task per the phase routing table
- PACK-FEEDBACK.md mechanism and workflow (PM chat observes → records →
  delivers to Pack Chat at workflow boundaries)
- All v9.x agent roles, skills, scripts, and their documented behaviors
- Desktop Commander / filesystem MCP patterns for Claude Desktop
- mcp-local-rag for large file RAG (METHODOLOGY.md)

Where a specific tool has limitations (e.g., Codex hooks only fire for
Bash, Claude Desktop without filesystem MCP requires manual file
upload), those must be documented as known limitations, not silently
accepted.

**Affects:** Part 0 or Part 1 (add a "v9.x compatibility" statement),
Part 5 §5.1 (per-tool workflow table already exists — verify
completeness), Part 6 §6.9 (migration guide must note any behavioral
differences).
