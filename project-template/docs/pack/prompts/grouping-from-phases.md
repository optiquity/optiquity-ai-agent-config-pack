---
agent: grouping-from-phases
variants:
  - from-phases
---

# grouping-from-phases — prompt template

## Variant: from-phases

*PM-chat self-prompt — derives CANDIDATE groupings from the existing
phase plan (METHODOLOGY.md Workflow 7a). Output is draft text for user
review; the PM chat never writes a grouping entry without explicit user
approval of that entry.*

**Context:** The project's implementation plan has phases that are not
yet organized into groupings, and the developer has asked for a
from-phases derivation pass.

**Required reading:** the implementation-plan tree
(`docs/project/implementation-plan/` — every `phase-N.md` H2 title,
`Goal`, and `Status:`); the groupings contract
(`docs/project/groupings/_rules.md`) in full; every existing
`docs/project/groupings/` entry (so candidates extend, not duplicate,
the declared set).

**Problem:** Related phases carry no declared membership, so grouping
queries, the derived-status rollup, and the STATUS.md groupings table
have nothing to report for them.

**Goal:** A set of CANDIDATE groupings covering the phases whose
relatedness the recognition signals below support — each candidate a
complete draft GRP-NNN.md body in the contract's closed
serialization, explicitly labeled DRAFT.

**Success criteria:**
- Every candidate is a complete entry body in the closed serialization
  (bold-pair header, declared field order, members ascending).
- Every `Kind:` is one of the contract's fixed enum slugs, justified by
  the recognition signals; `unassigned` is never suggested — it is
  hand-chosen by the user only.
- Every member token resolves to an existing
  `docs/project/implementation-plan/` phase entry.
- Two or more members per candidate, or a proposed
  `Single-member exception:` rationale.
- No candidate proposes GRP-000 membership — the declared-ungrouped
  ledger is ruled per phase in Workflow 7d, never derived.
- Each candidate carries a one-line WHY (which signals fired), outside
  the draft body.

**Recognition characteristics per Kind** (judgment signals, never
prescriptive — the user finalizes):

| Kind | Recognition signals |
|---|---|
| user-journey | H2 titles / Goals name UI surfaces, user actions or roles, end-to-end flows |
| ambient-feature | non-user-facing infrastructure Goals: observability, telemetry, security, logging, metrics |
| foundational-batch | high `Unblocks:` fan-out; titles / Goals name schema, base classes, contracts, platform |
| refactor-cluster | titles carry refactor / restructure / extract / rename; Goals name code quality without behavior change |
| release-package | phases pinned to a version target in Goal / title |
| shared-feature | Goals produce reusable libraries / APIs; titles carry shared / common / library / utility |
| architectural-pattern | Goals establish pattern conventions or architectural decisions |
| tech-debt-removal | titles carry remove / deprecate / migrate-off / sunset / retire |
| bug-fix | titles carry fix / patch / address; Goals reference defect artifacts |

**Constraints:** Draft-only — do not create, edit, or delete any file.
Do not propose membership edits to existing groupings beyond flagging
overlap for the user. After the user approves candidates, the PM chat
writes the approved entries and runs the Workflow 7c regeneration
chain.

**Completion report:** Present the candidate entries as text in chat
(the artifact is the user-approved entry set the PM chat writes after
approval — no separate report file). For each candidate: the draft
body, the WHY line, and any overlap or ambiguity flags.
