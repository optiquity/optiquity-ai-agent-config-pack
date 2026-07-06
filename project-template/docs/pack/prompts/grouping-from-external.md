---
agent: grouping-from-external
variants:
  - from-external
---

# grouping-from-external — prompt template

## Variant: from-external

*PM-chat self-prompt — translates externally-authored grouping content
into draft GRP-NNN.md entries (METHODOLOGY.md Workflow 7b). Output is
draft text for user review; the PM chat never writes a grouping entry
without explicit user approval of that entry.*

**Context:** The developer has pasted or attached external planning
content that declares or implies groupings — a planning-session
deliverable (narrative PRD, journey doc, feature inventory, mapping
doc), a project-provided planning doc, or any other varied-format
source. The pack never parses external formats mechanically; this
translation is PM-chat judgment.

**Required reading:** the pasted / attached content in full; the
groupings contract (`docs/project/groupings/_rules.md`) in full; the
implementation-plan tree (`docs/project/implementation-plan/` — phase
H2 titles + Goals, to resolve member references); every existing
`docs/project/groupings/` entry.

**Problem:** The external source's grouping structure is not in the
pack serialization, may reference work at the wrong granularity
(tasks instead of phases), and may name groupings without identifying
their member phases.

**Goal:** A set of draft GRP-NNN.md bodies in the contract's closed
serialization that faithfully translate the external structure, plus an
explicit clarifying-question list wherever the source under-specifies.

**Success criteria:**
- Every draft is a complete entry body in the closed serialization,
  labeled DRAFT.
- Task-level references roll up to their parent phases; duplicates
  collapse; the two-member minimum holds at the phase level after
  rollup (or a `Single-member exception:` rationale is proposed).
- Every member token resolves to an existing
  `docs/project/implementation-plan/` phase entry; external items with
  no phase counterpart are listed as unmapped, never invented.
- Where the source names a grouping without identifying member phases,
  a clarifying question is asked instead of a guessed membership.
- Source cross-references the user wants preserved land in the
  `Doc-links:` / `Comment:` fields — single-line, opaque, never
  interpreted.
- High-value source content that does not fit the pure-structure format
  (rationale, anti-goals, conditional-inclusion notes) is surfaced to
  the user for disposition, never silently dropped.

**Constraints:** Draft-only — do not create, edit, or delete any file.
After the user approves drafts, the PM chat writes the approved entries
and runs the Workflow 7c regeneration chain.

**Completion report:** Present the draft entries, the unmapped-item
list, and the clarifying-question list as text in chat (the artifact is
the user-approved entry set the PM chat writes after approval — no
separate report file).
