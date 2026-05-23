# REQUIREMENTS-GROUPINGS-V11.md

**Authored by:** Pack Chat (sidecar session for BD-186 requirements gathering).
**Date:** 2026-05-23 (US/Pacific).
**Branch:** v11-dev.
**Repo HEAD baseline at authoring:** ad79bf0 — docs: v11 — BD-188 open (phase-iteration sprint view, pack-only).
**Source BD:** BD-186 (`pack-ops/BACKLOG.md`).
**Sidecar inputs:**
- `maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-GROUPINGS-V2.md` (constraint enumeration of current v11 design + external tracker capabilities)
- `maintenance-docs/v11-research/V11.1-DISCUSSION-GITHUB-PROJECTS.md` (parking-lot brainstorm of feature shape)
- `pack-ops/BACKLOG.md` BD-185 entry (phase-parts adjacency context)
- User-stated design principles + constraints surfaced 2026-05-21 through 2026-05-23

## Purpose

This document is the **input to the v11.1+ architect pass for the groupings feature.** It specifies WHAT the groupings feature must be (problem, goal, success criteria per capability) and the user-approved design constraints the architect must respect. It does NOT specify HOW the feature is implemented — that is the architect's deliverable.

Per pack memory `feedback_no_solutions_in_agent_prompts`: requirements set scope (problem / goal / success criteria); architect makes design decisions within those bounds. User-architect-prescriptive decisions surfaced during BD-186 triage are recorded as constraints the architect must respect.

## Scope decision

**All 17 capabilities defer to v11.1+ implementation.** v11.0 ships the existing scope (BD-093 release pin + the remaining v11.0 backlog) without groupings. Rationale: groupings is genuinely architect-pass material spanning multiple BDs of implementation; SIZE deferral defense (per pack memory `feedback_deferral_is_scope_creep`) is valid; V11.1-DISCUSSION-GITHUB-PROJECTS.md anchored the feature at v11.1 originally; v11.0 launches sooner with current scope intact.

User authorized the v11.1+ deferral 2026-05-23 with the constraint that v11.0 → v11.1 migration must be fully architected, planned, and implemented as part of v11.1 work — NOT an ad-hoc set of file copies (captured as #16 SC10 + design decision (d)).

This artifact is the source-of-truth requirements input. The v11.1 architect reads it as primary input; this artifact + V11.1-DISCUSSION-GITHUB-PROJECTS.md + TOUCH-POINT-INVENTORY-GROUPINGS-V2.md form the architect's context set.

## Reading order

1. **§Design principles** — the 5 user-stated principles + 2 additional design considerations established during triage
2. **§User-stated constraints** — C1-C7 surfaced during BD-186 triage
3. **§Capability disposition summary** — table of 17 capabilities with v11.0/v11.1 verdicts
4. **§Capabilities #1-#17** — per-capability problem / goal / success criteria + user-approved design decisions + open architect-level surfaces + cross-references
5. **§BD landscape** — BDs opened during triage + downstream v11.1 BD landscape
6. **§Pipeline forward** — architect / planner / coder cycles for v11.1 implementation

---

## §1 — Design principles

The following design principles were stated by the user during BD-186 triage 2026-05-21 through 2026-05-23. They are AUTHORITATIVE for the v11.1 architect pass — the architect MUST respect them; design decisions are bounded by them.

### Core principles (user-stated 2026-05-21)

1. **Purpose-driven.** Design decisions are purpose-driven — based on what should be possible. Usage data is informative for HOW to implement and where friction exists, but does not determine WHETHER a capability is included. Empirical absence-when-disabled carries no signal.

2. **First-class entity.** Groupings are a first-class entity in the pack, equivalent in status to backlog items, implementation-plan entries, and changelog entries. The grouping primitive composes with the existing per-entry-tree pattern; differences from existing streams are explicitly documented (per #5 and capability cross-references).

3. **Reversibility.** Anything stored in a tracker (GH Issues, GH Projects, Linear, Jira, etc.) has a flat-file equivalent and round-trips between the two without information loss. No tracker-only state. Single SSOT discipline: pack repo carries all canonical state.

4. **Tracker portability.** Tracker-specific implementations sit behind a tracker-agnostic abstraction (per the BD-060 TrackerProvider pattern established for GH Issues), so developers on Linear / Jira / Redmine / etc. can plug in their equivalent backend. The grouping doc format is provider-agnostic; the tracker integration of groupings is per-provider.

5. **Compatibility.** Groupings integrate with the existing v11 design — phases, tasks, backlog items, and project management workflows already designed in v11. Minor modifications to existing surfaces are acceptable; major revisions require user discussion. Major revisions surfaced during triage (STATUS.md role per #14; capability matrix per #11) are resolved with user direction.

### Additional design considerations (established during BD-186 triage)

6. **External-tool accommodation (C6 elaboration).** Some projects author user journeys / PRDs / groupings in external tools (Notion, Productboard, ProductPlan, Linear product specs, Confluence, etc.). The pack must accommodate predetermined groupings — accepting external-tool content via PM-Chat-mediated translation when needed, and supporting the case where external content names groupings without identifying member phases (reconciliation workflow with PM/developer). The pack does NOT parse external formats with bespoke parsers (per V11.1-DISCUSSION §11). Per #7.

7. **Graceful tracker degradation (C7 elaboration).** Trackers vary enormously in grouping primitive support. Capable trackers (GH Projects v2, Linear Projects) MUST NOT be downgraded to lowest-common-denominator behavior. Incapable trackers (Forgejo Milestone-only; Jira epic-exclusive-parentage) MUST have documented mitigations (emulation via labels / sidecar custom fields / etc.) or explicit "not supported" declarations. Per principle 4 (portability) and #11.

User-architect-prescriptive decision (2026-05-22): treat C6 and C7 as principle ELABORATIONS rather than separate principles (#4 absorbs C7's portability stance; #6 records C6 as a top-level consideration since external-tool accommodation is its own concern that doesn't fold cleanly into any of #1-#5).

---

## §2 — User-stated constraints (C1-C7)

The following constraints were stated by the user during BD-186 triage. They are AUTHORITATIVE inputs to the v11.1 architect pass.

**C1 — Phases-only membership.** Only phases can be members of a grouping. Phase parts (`phase-N.Part-M` per BD-185), tasks (`phase-N.M`), and backlog entries (TD-NNN, BD-NNN) are NEVER members. Reasoning: phase parts and tasks are never orphaned (they're always under a phase); backlog entries must be scheduled into phases before they're up for implementation.

**C2 — Minimum 2 members per grouping.** A grouping must have at least 2 member phases. Single-member groupings require explicit approval recorded in the grouping doc (per #3 sub-decision A — in-doc exception field). Dissolution workflow when membership drops below 2.

**C3 — Per-entry-tree pattern imitation with explicit differences.** The bi-directionality of the implementation-plan and backlog directories, the structure of files in those directories, and the integration of those files into workflows are patterns to investigate and imitate. Groupings will differ in many ways (entry shape, lifecycle states, tracker projection, cross-reference direction); differences are documented explicitly.

**C4 — Phase→grouping migration capability.** Existing projects with phases (no groupings yet) need a way to identify candidate groupings from their phase set. This is a NEW capability area beyond V11.1-DISCUSSION's enumeration. Lightweight pack-character mechanisms preferred (PM-Chat-mediated; no heavyweight standalone scripts). Per #6.

**C5 — Grouping recognition characteristics + tooling.** Characteristics or tools to recognize groupings from phase content OR from PRDs. Extensible Kind enumeration (not fixed). Per #4 + #6.

**C6 — External-tool accommodation.** See §1 design consideration #6 above. Per #7.

**C7 — Graceful tracker degradation.** See §1 design consideration #7 above. Per #11.

User reserves the right to add additional constraints as work proceeds and corrections / clarifications emerge.

---

## §3 — Capability disposition summary

All 17 capabilities defer to v11.1+ implementation. The disposition table summarizes scope verdict + key cross-references; full per-capability requirements follow in §4.

| # | Capability | v11.0 / v11.1 verdict | Key dependencies |
|---|---|---|---|
| 1 | Grouping primitive — core shape | v11.1+ | Defines schema other capabilities reference |
| 2 | Explicit-membership model | v11.1+ | C1; V11.1 §9; V3.3-DELTA §5 inverse-of-cite |
| 3 | Membership rules | v11.1+ | C1 + C2; #13 validation |
| 4 | Kind enumeration (extensible) | v11.1+ | C5; #13 validation |
| 5 | Per-entry tree + supporting files | v11.1+ | C3; mirror DROPPED per #14 revision |
| 6 | From-phases derivation + recognition tooling | v11.1+ | C4 + C5; BD-187 (canonical characteristics doc) |
| 7 | From-external ingest + reconciliation | v11.1+ | C6; BD-187 (external-tool author guidance) |
| 8 | Tracker projection — `pack tracker init` | v11.1+ | #11 capability matrix; BD-060 / BD-065 / BD-066 / BD-067 |
| 9 | Operational verbs + query verbs | v11.1+ | Shared infrastructure with #14 per cross-reference |
| 10 | Bi-directional sync | v11.1+ | #11 capability matrix; BD-067 / BD-068 |
| 11 | Tracker capability matrix + graceful degradation | v11.1+ | C7; BD-060 capability flags |
| 12 | Workflow integration | v11.1+ | Trinity rule + Check 24 + Check 27 lockstep |
| 13 | Validation (validate-pack + fixtures) | v11.1+ | Extends 5 existing checks; adds 2 new |
| 14 | STATUS.md role coordination (revised) | v11.1+ | Major revision per user 2026-05-23; richer dashboard; cross-tree read + reverse-lookup + mode-aware rendering |
| 15 | Optional / advanced capabilities | v11.1+ | D-19 signal in v11.1; sprint view → BD-188 parking-lot |
| 16 | Install / upgrade scripting | v11.1+ | BD-119 framework; full architect / planner / coder rigor per user 2026-05-23 |
| 17 | Degenerate-state handling | v11.1+ | Architect designs cross-stream parity with full context |

**BDs opened during BD-186 triage:**
- BD-186 (this BD; the requirements-gathering BD itself; closes on this artifact landing)
- BD-187 (standalone entry-type instruction doc; parking-lot TODO(version); blocker = BD-186 close; scheduling recommend post-v11.1)
- BD-188 (Phase-Iteration sprint view = V11.1 §13 Y-6; parking-lot TODO(version); blocker = BD-186 close + v11.1+ groupings ship; scheduling deferred)

---

## §4 — Per-capability requirements

### Capability #1 — Grouping primitive: core shape

**Problem:** Groupings need a canonical document shape. Without one, groupings are amorphous; can't validate, can't sync, can't query consistently.

**Goal:** Specify the minimum required field set, what's optional, and what's explicitly excluded from a grouping document.

**Success criteria:**
- SC1.1. Every grouping declares Kind, Description, Member-phases (required) and a back-pointer line per per-entry convention.
- SC1.2. PRD/journeys reference is optional free-text; pack does not parse referenced docs (per V11.1 §11).
- SC1.3. No grouping-doc-level field exists for auto-include or implicit membership — explicit-membership preserved at the schema level (not just behaviorally).
- SC1.4. The doc shape is identifiable to validate-pack and PM-Chat tooling via declarative fields, not heuristics.

**User-approved design decisions (architect bounded by):**
- 5 required fields: H1 title, Kind, Description, Member-phases, back-pointer line
- 1 optional field: Source PRD / journeys doc reference (free-text)
- Auto-include regex (V11.1 §9 hybrid) DROPPED — defeated by recognition tooling (#6) without schema complexity; YAGNI; rejected after evaluation

**Architect-level surfaces:**
- Exact field-name strings (`**Kind:**` vs `Kind:` vs `## Kind`, etc.)
- H1 title format details
- Back-pointer line per ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2.md §2 (existing convention)

**Anchor / cross-references:**
- V11.1-DISCUSSION-GITHUB-PROJECTS.md §10 (grouping doc shape source)
- TOUCH-POINT-INVENTORY-GROUPINGS-V2.md §4 (per-stream contract surface)
- C1 (this artifact §2)

---

### Capability #2 — Explicit-membership model

**Problem:** Membership state needs a single location. Tagging phases with grouping refs creates drift risk + double-edit + violates SSOT. Heuristic detection at the schema level is fuzzy and brittle.

**Goal:** Establish a single-direction reference pattern (grouping → phase) consistent with V3.3-DELTA §5 inverse-of-cite, and a many-to-many relationship between phases and groupings.

**Success criteria:**
- SC2.1. Phase entries (`phase-N.md`) contain no grouping field, tag, or derived metadata.
- SC2.2. Grouping membership state lives only in grouping docs (Member-phases list).
- SC2.3. Reverse lookup ("which groupings include phase-N?") is provided via tooling that scans grouping docs, not stored phase-side state.
- SC2.4. A phase may be a member of N groupings simultaneously; each grouping declares its own membership independently.
- SC2.5. Groupings have NO declared dependencies. Inter-grouping execution order is derived from phase Blockers/Unblocks at query time; the grouping primitive does not introduce a parallel dependency surface.

**User-approved design decisions:**
- Phases carry no grouping metadata (inverse-of-cite pattern)
- Reverse-lookup is verb-based (Option B from #2 triage), not phase-stored
- Many-to-many membership (rejects 1-to-1 hypothetical evaluated during triage 2026-05-22)
- Grouping execution order is DERIVED from phase Blockers/Unblocks, not declared

**Architect-level surfaces:**
- Exact reverse-lookup verb implementation (covered in #9; shared infrastructure with #14 per cross-reference)

**Anchor / cross-references:**
- V11.1-DISCUSSION-GITHUB-PROJECTS.md §9 (explicit-membership decision source)
- ARCHITECTURE-V3.3-DELTA.md §5 (existing inverse-of-cite pattern)
- C1 (phases-only membership precondition)

---

### Capability #3 — Membership rules

**Problem:** Need unambiguous structural rules for what counts as a valid grouping — which entities can be members, minimum size, exception paths, behavior when rules are violated.

**Goal:** Establish testable membership rules that the pack can validate and the user can understand.

**Success criteria:**
- SC3.1. Only phases can be members. Phase parts, tasks, backlog entries explicitly excluded.
- SC3.2. Minimum 2 members required.
- SC3.3. Single-member groupings require an explicit in-doc exception declaration with rationale.
- SC3.4. No maximum-member rule at requirements level; tracker-side limits handled per #11.
- SC3.5. Kind is grouping-level identity; not derived from member-phase characteristics; not constrained by member kinds.
- SC3.6. Membership dropping below 2 (and no exception declared) triggers validation failure; pack performs no auto-mutation.
- SC3.7. Dangling member references (citing a non-existent phase) are caught by validation per #13.

**User-approved design decisions:**
- Exception mechanism: in-doc field (Option A from #3 triage) — `**Single-member exception:**` field with rationale, when declared
- Dissolution-when-membership-drops behavior: validation-fail with no auto-action (Option β from #3 triage)
- No max-members rule at requirements level
- Kind is grouping-level (not constrained by member-phase characteristics)
- Dangling-ref validation deferred to #13

**Architect-level surfaces:**
- Exact exception field name + format
- Exact failure-message wording for min-2 violation

**Anchor / cross-references:**
- C1 + C2 (this artifact §2)
- V11.1-DISCUSSION-GITHUB-PROJECTS.md §8 (many-to-many decision)
- #13 (validation surface)
- #11 (tracker max-member implications)

---

### Capability #4 — Kind enumeration (extensible)

**Problem:** Groupings need a classification system. Fixed enum constrains user creativity; freeform string defeats validation; pack-prescribed taxonomy may not fit all projects.

**Goal:** A pack-shipped default Kind set + extensible per-project mechanism, with validation that catches typos and undeclared kinds.

**Success criteria:**
- SC4.1. Pack ships a default Kind set covering common patterns.
- SC4.2. Projects can extend the Kind enum without forking the pack.
- SC4.3. Kind is classification (identity), not behavior driver (per-Kind behavior optional at architect level).
- SC4.4. Validation enforces declared Kinds against the per-project enum; unknown Kinds fail validation.
- SC4.5. Kind extension is declarative and validated (lives in per-stream contract, not freeform).

**User-approved design decisions:**
- Default Kind set (9 values): `user-journey`, `ambient-feature`, `foundational-batch`, `refactor-cluster`, `release-package`, `shared-feature`, `architectural-pattern`, `tech-debt-removal`, `bug-fix`
- Extension mechanism: user edits per-project `_rules.md` (Option A from #4 triage) — declarative; validated by validate-pack
- Kind behavior: Position 1 primary (pure classification); Position 2 PERMITTED at architect level (per-Kind default tracker field-map per V11.1 §10 hint); Position 3 explicitly OUT (no per-Kind validation rules)

**Architect-level surfaces:**
- Final Kind name strings (slug form: `user-journey` vs `User Journey`; underscore vs hyphen; etc.)
- Per-Kind default field-map if architect chooses Position 2
- `_rules.md` Kind-enum extension block format

**Anchor / cross-references:**
- V11.1-DISCUSSION-GITHUB-PROJECTS.md §10 (5-value default enum source; expanded to 9)
- TOUCH-POINT-INVENTORY-GROUPINGS-V2.md §7.B7 (fixed-vs-extensible break-point resolved by extensible)
- C5 (extensible-by-default constraint)
- #13 (validation surface)

---

### Capability #5 — Per-entry tree + supporting files

**Problem:** Groupings need a file-system representation consistent with the established v11 per-entry-tree pattern (backlog / implementation-plan / changelog) while differing where the entity model differs.

**Goal:** A per-entry tree for groupings imitating the established pattern with explicit deltas (filename = ID-prefixed; no lifecycle states; declarative classification + member list shape; NO mirror file per #14 revision).

**Success criteria:**
- SC5.1. Per-entry tree at `project-template/docs/project/groupings/` with supporting files + entry files per established convention.
- SC5.2. Filenames follow `GRP-NNN.md` ID-prefix pattern (matches BD-NNN / TD-NNN / phase-N).
- SC5.3. **No `GROUPINGS.md` mirror file.** Pattern deviation from backlog / implementation-plan / changelog (those streams have mirrors because per-entry bodies are long-form; grouping docs are short; STATUS.md absorbs the convenience-reading role per #14). `_toc.md` serves the per-entry tree TOC role.
- SC5.4. ID is invariant once assigned (rename = new GRP + delete old).
- SC5.5. Numbering rule mirrors BD-NNN: read tree, increment highest; reservation lists from sidecar sessions are not authoritative.
- SC5.6. PM-Chat-direct write authority (project-side coder agents do not edit grouping files).
- SC5.7. Empty grouping tree (no entry files; supporting files populated) is a first-class valid state per #17.

**User-approved design decisions:**
- Tree shape: 3 mandatory supporting files (`_rules.md` + `_intro.md` + `_toc.md`) + zero-to-N `GRP-NNN.md` entry files
- No `_format.md` (only project-changelog has one today; groupings has no comparable special semantics)
- Filename convention: `GRP-NNN.md` with regex `^GRP-\d{3,}\.md$` (3-digit zero-padded minimum)
- ID invariant; H1 carries human-readable name: `# GRP-NNN: <Title> (<kind>)`
- No mirror file (revision driven by #14 user direction 2026-05-23)
- PM-Chat-direct write authority (project-side; coder agents bound out)

**Differences from existing per-entry trees (the C3 explicit deltas):**

| Aspect | backlog / implementation-plan | groupings |
|---|---|---|
| Entry filename | ID-based (TD-NNN.md, phase-N.md) | ID-based (`GRP-NNN.md`) — pattern preserved |
| Lifecycle states | Open/Resolved/etc. | None declared (present or absent) |
| Body shape | Issue-style fields + free description | Declarative classification (Kind) + Member-phases list |
| Minimum size | 1 entry possible | Min 2 members per-grouping (C2); empty tree fine (per #17) |
| Tracker projection | Issue | Project / Epic / Version (#11) |
| Cross-references | Bidirectional (backlog cites phases; phases cite backlog) | Unidirectional (groupings cite phases; phases don't cite back per #2) |
| Kind classification | Implicit (TD vs phase prefix) | Explicit Kind field per #4 |
| Regenerated mirror file | Yes (BACKLOG.md / IMPLEMENTATION-PLAN.md / CHANGELOG.md) | **No** — STATUS.md absorbs the convenience-reading role per #14 |

**Architect-level surfaces:**
- TOC regenerator extension for groupings stream (per BD-164 pattern)
- Per-entry helper extension for `project-groupings` stream tuple (`scripts/lib/per-entry/_lib.sh` PE_STREAM_KEYS list)
- Numbering-assignment workflow (PM-Chat-direct; reads tree on each new GRP creation)

**Anchor / cross-references:**
- V11.1-DISCUSSION-GITHUB-PROJECTS.md §10 + §12 (per-entry tree placement)
- TOUCH-POINT-INVENTORY-GROUPINGS-V2.md §3.A + §4 (per-stream contract surface)
- C3 (per-entry-tree pattern imitation)
- #14 (mirror dropped; STATUS.md absorbs convenience role)
- #16 (install/upgrade scripting)
- #17 (empty-state cross-stream parity)

---

### Capability #6 — From-phases derivation + recognition tooling

**Problem:** Projects with existing phases (no groupings yet) need a way to identify what groupings should be created and which phases belong where. Pure manual authoring is high friction; heavyweight tooling (deterministic script with language-specific parsers, NLP, etc.) overshoots pack character.

**Goal:** Support project adoption of groupings by helping users identify candidate groupings from existing phases, using lightweight pack-character mechanisms (PM-Chat-mediated; no standalone parser script).

**Success criteria:**
- SC6.1. Users can convert from "phases only" to "phases + groupings" via a documented workflow.
- SC6.2. Recognition assistance is non-prescriptive — pack suggests; user reviews / edits / approves.
- SC6.3. Pack ships starting recognition characteristics per Kind to guide PM-Chat suggestions.
- SC6.4. No standalone parser/analyzer script required at v11.1 (PM-Chat is workhorse, consistent with pack character).
- SC6.5. Project-side adoption requires no schema migration of existing phases; phases stay grouping-agnostic.
- SC6.6. Explicit-membership (per #2) is preserved — recognition output is candidate groupings with proposed memberships; user finalizes.

**User-approved design decisions:**
- Tooling shape: γ PM-Chat-mediated (NOT a separate deterministic script α; NOT AI-direct script β; NOT user-driven-only δ)
- Characteristics doc location: A — fold canonical version into BD-187 (standalone entry-type instruction doc); inline starting set lives in this artifact + #12 PM-Chat prompt variant content
- No migration verb (parallel to #7's no-verb decision); PM-Chat workflow is sufficient
- Deterministic script deferred to v11.x or v12 if real demand emerges; NOT in v11.1 scope

**Starting recognition characteristics (per Kind from #4) — handed to PM Chat prompt variant for the from-phases workflow:**

| Kind | Recognition signals (PM Chat applies judgment) |
|---|---|
| user-journey | Titles/descriptions reference UI surfaces, user actions, user roles, end-to-end flows |
| ambient-feature | Non-user-facing infrastructure topics — observability, telemetry, security, logging, metrics |
| foundational-batch | Phases that have many `Unblocks:` pointers (others depend on them); titles reference schema, base classes, contracts, platform |
| refactor-cluster | Titles include "refactor", "restructure", "extract", "rename"; descriptions reference code quality without behavior change |
| release-package | Phases pinned to a specific minor/major release; descriptions reference version targets |
| shared-feature | Phases producing reusable libraries/APIs; titles reference "shared", "common", "library", "utility" |
| architectural-pattern | Phases establishing design pattern conventions (Repository, Factory, etc.); descriptions reference architectural decisions |
| tech-debt-removal | Titles include "remove", "deprecate", "migrate off", "sunset", "retire" |
| bug-fix | Titles include "fix", "patch", "address"; descriptions reference bug reports or known-issue artifacts |

This is the STARTING set — architect refines, and BD-187 absorbs the canonical version when that BD lands.

**Architect-level surfaces:**
- METHODOLOGY procedure for "Creating groupings from existing phases"
- PM-Chat prompt variant for from-phases workflow (one of two variants per #12)
- Final canonical characteristics doc (lives in BD-187 when scheduled)

**Anchor / cross-references:**
- C4 + C5 (this artifact §2)
- V11.1-DISCUSSION-GITHUB-PROJECTS.md §10 (Kind enum) + §9 (recognition framing)
- BD-187 (forward dependency for canonical characteristics doc)
- #12 (METHODOLOGY procedure + PM-Chat prompt variant implementation)
- #7 (sibling ingress path — from-external)

---

### Capability #7 — From-external ingest + reconciliation workflow

**Problem:** Projects with predetermined groupings authored in external tools (Notion, Productboard, ProductPlan, Linear specs, prepared journeys docs) shouldn't have to re-author in pack format from scratch. Pack can't realistically maintain parsers for N external formats. Locking users into pack format alone creates friction that drives users away (per C6).

**Goal:** Pack accepts external grouping definitions via a flexible ingress path that doesn't require external tools to know pack format, doesn't require pack to parse N external formats, and gracefully handles the input-quality spectrum from fully-structured to free-text.

**Success criteria:**
- SC7.1. Pack accepts pack-format direct authoring (`GRP-NNN.md` authored manually or via external AI tools using BD-187 guidance).
- SC7.2. Pack accepts non-pack-format input via PM-Chat-mediated translation (chat reads external content; asks clarifying questions; produces draft `GRP-NNN.md`).
- SC7.3. Reconciliation workflow handles the C6 case where external groupings name groupings without identifying member phases.
- SC7.4. Pack does NOT parse N external formats with bespoke parsers.
- SC7.5. External tools guided by BD-187 produce pack-compatible content directly; ungrouped/unstructured external content is handled via the same PM-Chat workflow as a D-soft fallback.
- SC7.6. External task-level references (when external tools use tasks instead of phases) roll up to parent phases per C1 phases-only membership; minimum-2 enforced at the phase level after rollup.
- SC7.7. PRD/journeys cross-references are recorded as optional free-text on the grouping doc; pack does not parse referenced docs.

**User-approved design decisions:**
- Ingress: γ both paths supported (pack-format direct AND PM-Chat-mediated external translation per user direction 2026-05-22)
- Reconciliation workflow: PM-Chat-mediated, inverse direction of #6 (input = external grouping definition; output = phase mapping suggestions)
- D-soft helper: Option 1 (inherent in PM-Chat workflow; no separate mechanism)
- Tasks-rollup edge case: roll up to parent phases at ingress; dedupe; min-2 enforced at phase level
- No ingress verb (parallel to #6 no-migration-verb decision)
- PRD/journey field: optional free-text, supports multiple references inside the field

**Architect-level surfaces:**
- METHODOLOGY procedure for "Ingesting external groupings into pack"
- PM-Chat prompt variant for from-external workflow (one of two variants per #12)
- Prompt design to handle the input-quality spectrum (structured external formats → unstructured prose)

**Anchor / cross-references:**
- C6 + the "B+C+D-soft" nuance (this artifact §2 + user direction 2026-05-22)
- V11.1-DISCUSSION-GITHUB-PROJECTS.md §11 (no PRD parsing)
- BD-187 (forward dependency for external-tool author guidance)
- #6 (parallel PM-Chat-mediated approach + shared recognition characteristics)
- #12 (METHODOLOGY procedure + prompt variant implementation)

---

### Capability #8 — Tracker projection: `pack tracker init` extension

**Problem:** When a project opts into tracker mode AND has groupings declared, those groupings need a tracker-side representation. The existing `pack tracker init` (BD-066) handles backlog + implementation-plan + changelog at the issue level; groupings are a NEW projection layer at a higher level (Project for GH; Epic for Jira; Version for Redmine; etc.).

**Goal:** `pack tracker init` extends to handle groupings projection — creating the tracker-side container entity and populating membership — alongside its existing entity projections, as a single coherent forward migration.

**Success criteria:**
- SC8.1. On `pack tracker init`, each grouping is projected to the tracker's native primitive when capable, or to a documented emulation per #11 when not.
- SC8.2. Membership populated by mapping `phase-N` IDs to tracker issue IDs via existing BD-067 sidecar mapping (no new mapping mechanism).
- SC8.3. Init is idempotent per existing BD-066 pattern — re-running is safe.
- SC8.4. Init for groupings projection is opt-in (separate gate from tracker-mode opt-in itself); users on capable backends may choose not to project groupings.
- SC8.5. API cost managed via checkpoint/resume pattern extending BD-065.
- SC8.6. Failure modes use typed errors per BD-070, including `phase_not_found` for unmigrated member references (blocks init until resolved).

**User-approved design decisions:**
- Behavior: A+C from #8 triage — create groupings + populate membership in one verb AND opt-in gate via `tracker.toml [project] enabled` (default false)
- Two-pass: create groupings first, populate membership second
- Phase-ID mapping reuses existing BD-067 sidecar (no new mapping mechanism)
- Missing-phase behavior: BLOCK with typed error (not warn/skip)
- Checkpoint pattern: extend BD-065 mechanism (no new mechanism)
- `[project]` section schema includes opt-in flag + project number/URL + optional Kind→field-map per V11.1 §10 Position 2

**Architect-level surfaces:**
- Exact `[project]` TOML schema (field names, types, defaults)
- Two-pass orchestration in `scripts/lib/tracker-grouping.sh`
- Checkpoint cadence (N items between checkpoints; architect picks N per BD-065 precedent)
- Per-backend projection routing per #11 capability matrix

**Anchor / cross-references:**
- V11.1-DISCUSSION-GITHUB-PROJECTS.md §13 row Y-3 (verb shape source)
- TOUCH-POINT-INVENTORY-GROUPINGS-V2.md §9.1 (forward operations) + §9.4 (two-pass) + §9.5 (checkpoint)
- BD-060 / BD-065 / BD-066 / BD-067 / BD-070 (existing tracker infrastructure)
- #9 (operational verbs for re-sync), #10 (bi-directional sync), #11 (capability matrix)

---

### Capability #9 — Operational verbs + query verbs

**Problem:** Once groupings exist in both flat-file and tracker representations, users need verbs to re-sync after edits, detect drift, reverse to flat-file, enumerate groupings, and query derived properties (which groupings include phase X, what execution order do members take, what dependencies exist between groupings, which groupings share members). These map to two families: tracker-side operational verbs requiring tracker mode active, and mode-agnostic query verbs working in flat-file mode too.

**Goal:** Provide a complete verb set covering both families, integrated with existing pack verb infrastructure (BD-066 init, BD-067 doctor/disable) without fragmenting the user-facing verb taxonomy.

**Success criteria:**
- SC9.1. Re-sync after grouping doc edits is explicit and user-invoked (no implicit auto-sync, watchers, or background daemons).
- SC9.2. Drift detection between flat-file and tracker state is accessible via the existing tracker doctor surface (not fragmented into a separate verb family).
- SC9.3. Reverse migration handles groupings as part of the existing `pack tracker disable` sweep (not a separate verb).
- SC9.4. Query verbs work in flat-file mode without tracker dependency.
- SC9.5. All verbs are idempotent per BD-067 pattern.
- SC9.6. All verbs use typed errors per BD-070.
- SC9.7. Output format supports both human-readable and machine-parseable usage; consistent with existing pack verb conventions.
- SC9.8. The verb set covers the core groupings UX (rebuild + drift detection + reverse + enumerate + reverse-lookup) PLUS derived queries (execution order, dependencies, intersection) — none deferred to v11.x given they are small-medium, isolated, share infrastructure, and pass logical-fit with #9 cleanly.
- SC9.9. Underlying reverse-lookup + derived-query algorithms are implemented as SHARED INFRASTRUCTURE consumed by both query verbs AND STATUS.md generator (per #14). Architect-pass decision required on shape: persisted derived artifact (matching existing `_toc.md` pattern — episodic regeneration, regeneratable from SSOT, survives across invocations) vs rebuild-every-time (no persistence; fresh scan per invocation). Risk-of-rebuild-every-time: repeat queries pay full scan cost; STATUS.md regen pays full scan cost; PM-Chat reverse-lookup queries pay full scan cost. Risk-of-persisted-artifact: cache invalidation correctness; CI gating to verify index-vs-tree consistency. No persisted-vs-not decision locked in v11.1; architect chooses based on scale + complexity tradeoff.

**User-approved design decisions:**
- Namespace split (γ from #9 triage): `pack tracker groupings ...` for tracker-only ops; `pack groupings ...` for mode-agnostic queries
- v11.1 verb set: 8 verbs total
  - **Tracker-side:** `pack tracker groupings rebuild`; extension of `pack tracker doctor`; extension of `pack tracker disable`
  - **Mode-agnostic queries:** `pack groupings list`; `pack groupings list-membership`; `pack groupings deps`; `pack groupings order`; `pack groupings shared-with`
- Doctor + disable: extend EXISTING verbs (Option 1 from #9 triage), not add separate groupings-namespaced versions
- Output shape: flag-controlled (verbose default; `-q` for scripts)
- All 3 query verbs (`deps` / `order` / `shared-with`) implemented as executable scripts (deterministic graph operations); NOT PM-Chat workflows
- Reverse-lookup + derived-query algorithms implemented as shared library (used by verbs AND STATUS.md generator) — persisted-vs-not is architect decision

**Architect-level surfaces:**
- Exact verb subcommand names (`rebuild` vs `re-sync` vs `update`, etc.)
- Output format details (table vs plain list; column widths; etc.)
- Persisted index file location + format if architect chooses persisted approach (e.g., `_reverse-lookup.md` alongside `_toc.md`; or `.pack-cache/grouping-membership.json`; etc.)
- Cache invalidation strategy + CI gating if persisted
- Failure-message wording for typed errors

**Anchor / cross-references:**
- V11.1-DISCUSSION-GITHUB-PROJECTS.md §13 row Y-4 (rebuild verb source)
- TOUCH-POINT-INVENTORY-GROUPINGS-V2.md §3.C (verb dispatcher modify), §9.2 (reverse operations), §9.6 (doctor capability re-probe)
- BD-066 / BD-067 (existing tracker verbs being extended)
- BD-070 (typed-error model)
- #2 (reverse-lookup Option B)
- #14 (STATUS.md uses shared reverse-lookup library function; coordination critical)
- #11 (capability matrix for backend-specific verb behavior)

---

### Capability #10 — Bi-directional sync

**Problem:** Trackers vary enormously in their grouping primitive support — GH Projects v2 + Linear Projects offer multi-grouping per issue + custom fields; Jira has exclusive-parent epic + component + sprint; Redmine has single-valued version + multi-valued category; GitLab has epic (deprecated) + milestone; Forgejo has milestone only. Pack must support groupings across this heterogeneity without crippling capable trackers (per C7) AND must maintain single SSOT in pack repo (per principle 3 — "no tracker-only state").

**Goal:** Bidirectional sync between pack-repo state (SSOT) and tracker representation (mirror) such that grouping state survives round-trip (forward → reverse → forward) without information loss, across the full range of supported tracker backends.

**Success criteria:**
- SC10.1. Forward sync (flat → tracker) projects each grouping to the tracker's native primitive when available, or a documented emulation mechanism when not (per #11 capability matrix).
- SC10.2. Reverse sync (tracker → flat) reconstructs flat-file state with byte-equivalent fidelity (whitespace-tolerant on flat-file side; byte-equivalent on tracker side).
- SC10.3. Round-trip property (BD-068 extension): forward → reverse → forward → reverse converges; no drift across cycles.
- SC10.4. No grouping state originates in the tracker that is not ultimately reflected back into pack repo. Single SSOT discipline: pack repo carries all canonical state.
- SC10.5. Tracker-side extensions (custom fields the user adds in tracker UI; per-backend embellishments that aren't part of the canonical grouping shape) are captured and preserved across round-trip via SOME mechanism that maintains single-SSOT discipline. Mechanism is architect-level.
- SC10.6. Conflict resolution behavior (when concurrent edits occur on both sides) is deterministic and documented. Specific resolution algorithm is architect-level; constraint is "deterministic + documented."
- SC10.7. Capable trackers (GH, Linear) expose their native grouping features without forced degradation; incapable trackers (Forgejo, Redmine where applicable) degrade with documented mitigations per #11.
- SC10.8. Sync triggers are explicit / user-controlled (no implicit watchers or background daemons). User-controllable matches existing pack character; specific verb shapes covered in #9.

**User-approved design decisions:**

NONE locked at requirements level. The earlier "split authority (pack-authoritative for structure + tracker-authoritative-via-sidecar for tracker-only fields)" recommendation was REJECTED 2026-05-23 for being design-shaped and creating dual SSOTs that violate principle 3. All carrier mechanism + authority allocation + conflict algorithm + sidecar shape + location decisions are architect-level.

**Architect-level surfaces:**
- Specific carrier mechanism for tracker-side extensions (single sidecar / per-grouping sidecar / inline-in-grouping-doc / hybrid)
- Per-field authority split vs unified-authority approach
- Conflict resolution algorithm (last-write-wins / merge / block / etc.)
- Round-trip test fixture shape
- Sidecar file format and location

**Constraints to architect:**
- Per principle 3: tracker is mirror; pack is SSOT
- Per principle 4: tracker portability via BD-060 abstraction
- Per C7: capable trackers not crippled; mitigations for incapable
- Per existing BD-067 / BD-068 patterns: sidecar mechanism and round-trip test framework exist — extend rather than reinvent
- Per #11: per-backend capability variations addressed separately

**Anchor / cross-references:**
- TOUCH-POINT-INVENTORY-GROUPINGS-V2.md §7.B5 (round-trip break-point), §8.3 (sidecar shape candidates), §9.3 (lossy items), §10.3 (round-trip test fixture)
- V11.1-DISCUSSION-GITHUB-PROJECTS.md §14 Q4 (sync direction question)
- BD-067 (sidecar contract), BD-068 (round-trip property)
- #11 (capability matrix for backend-specific sync variations)

---

### Capability #11 — Tracker capability matrix + graceful degradation

**Problem:** Tracker backends vary enormously in grouping primitive support (per #10 problem statement + inventory §2.7 cross-tracker matrix). V11.1 §8's multi-Project-per-issue dedup behavior is GH/Linear-specific. Per C7, capable trackers must not be crippled to LCD; per principle 4, the pack must support all backends via BD-060 abstraction.

**Goal:** A per-backend capability declaration mechanism that drives the pack's behavior — enabling native features where supported, providing documented mitigations where not, and surfacing degradation transparently to users.

**Success criteria:**
- SC11.1. Each supported tracker backend declares its grouping-related capabilities in a queryable form accessible to pack tools (verbs, validators, PM Chat).
- SC11.2. Capability flags cover the load-bearing distinctions: presence of native grouping primitive; multi-grouping-per-issue support; custom-field support; iteration/sprint support; field limits.
- SC11.3. When a capability is absent, the pack EITHER provides a documented emulation/mitigation OR documents the feature as unavailable on that backend (no silent failure).
- SC11.4. Capability gaps do NOT degrade capable backends' behavior — multi-grouping-per-issue on GH/Linear works fully even though Jira/Redmine/Forgejo require emulation or restriction.
- SC11.5. The capability matrix is documented user-facing (so users picking a tracker know what they're choosing); behind-the-scenes capability flags drive tooling behavior.
- SC11.6. Operational verbs (per #9) are capability-aware — `pack tracker doctor` surfaces emulation status; `pack tracker init` warns when projecting to a backend that emulates rather than provides natively; `pack tracker groupings rebuild` uses the correct mechanism per backend.
- SC11.7. Capability changes over time (backend adds a feature) are detectable — `pack tracker doctor` re-probes and reports newly available features.
- SC11.8. New backend support (Linear, Jira, etc., reserved via BD-060) extends the matrix without breaking existing capable backends.

**User-approved design decisions:**
- (a) Declaration mechanism: γ — declaration + verification. Provider library declares capabilities (extends existing BD-060 `provider_capabilities` op); `pack tracker doctor` verifies; warns on drift.
- (b) Multi-grouping-per-issue mitigation strategy: LEFT OPEN (architect decides). Three candidate strategies surfaced in triage — restrict / label-emulation / hybrid native+label — each with cost/benefit tradeoffs. Recommendation NOT locked; architect picks based on per-backend user-behavior considerations not predictable at requirements time.
- (c) Documentation surface: D3 — central per-backend capability matrix doc + inline cross-references throughout pack docs.

**Architect-level surfaces:**
- Exact capability flag set (5 candidates from inventory §5.4: `grouping.supported`, `grouping.custom_fields`, `grouping.iterations`, `grouping.multi_per_item`, `grouping.field_limit`; architect refines)
- Multi-grouping-per-issue mitigation strategy per backend (architect decides — restrict, label emulation, hybrid, or backend-specific)
- Per-backend emulation mechanism details (label format, primary-grouping selection rule, sidecar custom-field shape, etc.)
- Per-backend warning UX details (when to warn, how loud, dismissible?)
- Capability matrix doc format (table vs prose vs YAML)
- GH backend is the v11.1 implementation reference; Linear / Jira / Redmine / Forgejo extend later as backends ship (reserved per BD-060)

**Anchor / cross-references:**
- TOUCH-POINT-INVENTORY-GROUPINGS-V2.md §2 (per-tracker primitives), §5.4 (capability flag set), §7.B2 + §7.B4 (break-points resolved via capability matrix + emulation)
- V11.1-DISCUSSION-GITHUB-PROJECTS.md §14 Q5 + Q7
- BD-060 (TrackerProvider abstraction + capabilities)
- C7 (this artifact §2)
- #10 (sync behavior depends on capabilities)
- #9 (verbs use capability info)
- #14 (STATUS.md mode-aware rendering depends on per-backend URL formats)

---

### Capability #12 — Workflow integration

**Problem:** Groupings as a new entity type need integration into existing pack documentation, orchestration, and CI-gated surfaces. Without integration: users can't discover the feature; agents (project-side coder/auditor) don't know to treat grouping files as PM-only; trinity files don't expose the new tree in their Document locations; PM-Chat doesn't know to invoke the from-phases or from-external workflows; validate-pack CI gates (byte-identity, per-CLI parity) need extension; METHODOLOGY workflows have no mention of grouping creation/change.

**Goal:** All existing pack documentation, orchestration, and CI-gated surfaces are extended in lockstep to accommodate groupings, following established patterns (trinity rule, byte-identity mirrors, per-CLI parity, PM-only file lists).

**Success criteria:**
- SC12.1. `supporting-docs/METHODOLOGY.md` Part 2 Standard Project Documents table is updated with grouping context (note: no `GROUPINGS.md` row per #5 revision driven by #14; reference points at per-entry tree + STATUS.md groupings section); new procedure(s) cover grouping creation, membership change, dissolution.
- SC12.2. `project-template/docs/pack/PM-CHAT.md` File access strategy includes grouping surfaces (`docs/project/groupings/<GRP-NNN>.md` for per-entry source; `docs/project/groupings/_rules.md` at session start); orchestration text covers the from-phases (#6) and from-external (#7) workflows.
- SC12.3. Project-template trinity files (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`) are updated in LOCKSTEP per trinity rule: `## Document locations` table mentions the per-entry tree (NOT a `GROUPINGS.md` mirror, since none exists per #5 revision); "Per-entry source-of-truth trees" paragraph includes groupings stream alongside backlog/implementation-plan/changelog.
- SC12.4. HELP-FRAGMENT files document the new verb families (`pack tracker groupings ...` and `pack groupings ...` per #9 namespace split); `pack-ops/HELP-FRAGMENT-TRACKER.md` and `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` remain byte-identical per BD-077 Check 24.
- SC12.5. `project-template/docs/pack/OPTIONAL-FEATURES.md` describes the Groupings feature with opt-in path + cross-references to MIGRATION doc and BD-187 standalone instruction doc (when BD-187 lands).
- SC12.6. Project-side agent files (`project-template/.claude/agents/coder.md` + Codex/Gemini mirrors) include `docs/project/groupings/` in their PM-only file lists (so coder agents do not edit grouping files).
- SC12.7. Project-side agent prompts (`project-template/docs/pack/prompts/architect.md` + `pm-chat.md`) reference grouping doc as input where applicable; PM-Chat prompt variant(s) cover from-phases (#6) and from-external (#7) workflows.
- SC12.8. Skill files (`project-template/skills/pm-startup/SKILL.md` + per-CLI mirrors at `.claude/`, `.codex/`, `.gemini/`) are updated: Step 2 includes groupings stream in trinity-resolver framing; Step 6 startup report adds "Open groupings: N"; Step 8 optional D-19 grouping signal per #15; per-CLI parity preserved per BD-076 / Check 27.
- SC12.9. `supporting-docs/MIGRATION-v11.0-to-v11.x.md` (user-facing narrative for the version that ships groupings) covers user adoption story per #16.
- SC12.10. All trinity-affected edits land in lockstep across the three trinity files in the SAME commit per trinity rule; HELP-FRAGMENT byte-identity preserved per Check 24; per-CLI skill parity preserved per Check 27. Validate-pack catches drift; CI fails on regression.

**User-approved design decisions:**
- (a) Two specialized PM-Chat prompt variants per β: `grouping-from-phases` + `grouping-from-external` (NOT one generic variant covering all grouping orchestration)
- (b) New METHODOLOGY Workflow for grouping creation/maintenance per Option 1 (NOT folded into Workflow 1 / NOT PM-Chat-direct only)

**Architect-level surfaces:**
- Exact procedure structure (number of sub-procedures, step granularity, decision flows)
- Specific prompt variant text content
- Exact wording for trinity Document-locations entry
- OPTIONAL-FEATURES.md section structure
- MIGRATION narrative content

**Anchor / cross-references:**
- TOUCH-POINT-INVENTORY-GROUPINGS-V2.md §3.G (METHODOLOGY + trinity + PM-CHAT), §3.I (agent files), §3.J (skill files)
- BD-077 / Check 24 (HELP-FRAGMENT byte-identity)
- BD-076 / Check 27 (per-CLI skill parity)
- C3 (this artifact §2)
- BD-187 (cross-reference target for OPTIONAL-FEATURES section)
- #5 revision (no GROUPINGS.md mirror)
- #6 (from-phases workflow + prompt variant)
- #7 (from-external workflow + prompt variant)
- #14 (STATUS.md disclaimer extension)
- #15 (D-19 grouping signal)
- #16 (MIGRATION narrative)

---

### Capability #13 — Validation (validate-pack + test fixtures)

**Problem:** Groupings need validation to enforce the membership rules, schema, cross-references, and per-stream contract established in #1-#5. Without validation: drift goes undetected (GRP-NNN.md filename typos pass; Kind enum violations slip through; dangling phase references accumulate; min-2 rule is decorative); SSOT discipline degrades; explicit-membership model erodes because the pack can't enforce it.

The existing validate-pack infrastructure has 40+ checks covering backlog/implementation-plan/changelog. Groupings need parallel coverage following established patterns.

**Goal:** Extend existing validate-pack infrastructure to cover the grouping surface, reusing established patterns (stream-tuple addition for TOC/cross-ref checks; new focused checks for grouping-specific rules; per-check fixture + CI wire-up). NOTE: Check 32 mirror-in-sync is NOT extended for groupings per #5 revision (no GROUPINGS.md mirror).

**Success criteria:**

**Membership rule enforcement (from #3):**
- SC13.1. Only phases can be members; parts / tasks / backlog entries in Member-phases list fails validation.
- SC13.2. Min-2 members enforced; single-member grouping fails unless explicit exception declared per #3 in-doc mechanism.
- SC13.3. No double-listing within a single grouping's Member-phases list.
- SC13.4. Member references resolve to existing phases (cross-reference integrity) — dangling references fail.

**Schema enforcement (from #1 + #5):**
- SC13.5. Required fields present in each grouping doc (H1 title, Kind, Description, Member-phases, back-pointer line).
- SC13.6. Kind value is in the per-project declared enum (validator reads `_rules.md` per #4 extension mechanism; unknown Kinds fail).
- SC13.7. Filename matches `^GRP-\d{3,}\.md$` pattern.
- SC13.8. Back-pointer line present per ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2.md §2 convention.

**Per-stream contract enforcement (from #5):**
- SC13.9. Required supporting files present: `_rules.md`, `_intro.md`, `_toc.md`.
- SC13.10. TOC in sync with per-entry tree.
- SC13.11. Check 32 `check_mirror_in_sync()` NOT extended for groupings (no mirror per #5 revision).

**Tracker config enforcement (from #8):**
- SC13.12. `tracker.toml [project]` section schema valid; opt-in flag valid; project_number/URL format valid.

**Degenerate state (from #17):**
- SC13.13. Empty grouping tree (supporting files present, no GRP-NNN entry files) passes validation.

**STATUS.md content (from #14):**
- SC13.14. STATUS.md cross-link integrity validation: each phase row's groupings column references valid groupings; each grouping row's member-phases column references valid phases; intra-doc anchors are consistent. Architect-level for specific check granularity.

**Infrastructure parity:**
- SC13.15. New checks land in `scripts/validate-pack.py` following existing per-check structure (one function per check; clear failure messages; deterministic output).
- SC13.16. CI workflow (`.github/workflows/validate-pack.yml`) wires per-check test files per Check 42 pattern.
- SC13.17. Manifest regenerated per RC9 trigger when grouping files change.

**Test fixtures:**
- SC13.18. Positive-case fixtures cover valid v11.x grouping state (flat-file mode and tracker-on mode).
- SC13.19. Negative-case fixtures cover each new check's rule violation (minimum one negative case per check).
- SC13.20. Round-trip fixture per BD-068 pattern validates forward → reverse → forward byte-equivalence for grouping projection.
- SC13.21. Empty-state fixture covers #17 degenerate-state handling.

**User-approved design decisions:**
- (a) Split into focused checks per β (NOT one big `check_groupings()`)
- (b) Extend 4 existing checks (Check 33 toc_in_sync, Check 34 cross_reference_integrity, Check 29 tracker_config, `check_init_project_structure`) + add 2 new mandatory checks (`check_grouping_per_stream_contract`, `check_grouping_membership_integrity`); SKIP conditional Kind-constraint check (per #4 sub-decision Position 3 is out); SKIP Check 32 mirror_in_sync extension (per #5 revision)
- (c) Minimum fixture coverage per α (one valid + one negative per check); architect adds edge cases based on real test gaps

**Architect-level surfaces:**
- Exact check function signatures and internal logic
- Specific failure message wording
- Test fixture filenames and content
- Per-check test file naming (`test-validate-pack-check-N.sh` pattern)
- CI workflow YAML structure for new check wires
- STATUS.md content validation granularity (SC13.14 architect-level)

**Anchor / cross-references:**
- TOUCH-POINT-INVENTORY-GROUPINGS-V2.md §3.H + §10 (validator footprint)
- Check 24 (HELP-FRAGMENT byte-identity — #12), Check 27 (per-CLI parity — #12), Check 33/34 (existing per-stream checks)
- Check 42 (CI workflow wires per-check tests)
- BD-068 (round-trip property)
- RC9 manifest regen rule (CLAUDE.md)
- #5 revision (no mirror; no Check 32 extension)
- #3 (membership rules source)
- #10 (round-trip property)
- #14 (STATUS.md content validation)
- #17 (empty-state cross-stream parity)

---

### Capability #14 — STATUS.md role coordination (REVISED 2026-05-23)

**Problem:** Users need at-a-glance project visibility that integrates phases + groupings + tracker links (when applicable) into a single human-readable reference. The pre-revision design fragmented this across STATUS.md (phases only), GROUPINGS.md (groupings mirror), and tracker UI. A unified STATUS.md serves the human-navigation use case better; the GROUPINGS.md mirror's marginal value doesn't justify the maintenance cost for short grouping docs (per user direction 2026-05-23).

**Goal:** STATUS.md becomes the unified human-readable dashboard surface — phase-centric AND grouping-aware — with cross-links to flat-file and tracker entries. STATUS.md remains derivative (never SSOT) per BD-185 SC5. GROUPINGS.md mirror is dropped (per #5 revision).

**Success criteria:**
- SC14.1. STATUS.md is regenerated from per-entry trees (implementation-plan + groupings) and tracker metadata when tracker mode is active; it is never SSOT.
- SC14.2. STATUS.md contains a **phase table**: one row per phase, with link(s) to flat-file phase entry AND tracker entry (when tracker mode active).
- SC14.3. Each phase row in the phase table also carries a column with link(s) to the groupings the phase belongs to (flat-file + tracker when applicable). Reverse lookup happens at regeneration time.
- SC14.4. STATUS.md contains a **groupings table** (positioned below the phase table): one row per grouping, with link(s) to flat-file grouping entry AND tracker entry (when applicable).
- SC14.5. Each grouping row in the groupings table includes a member-phases column listing the phases in that grouping. The list uses intra-doc anchors to the phase table row when available; otherwise inline links to flat-file/tracker phase entries.
- SC14.6. STATUS.md regeneration is mode-aware: flat-file mode renders flat-file links only; tracker mode renders BOTH flat-file and tracker links (per principle 3 — flat-file remains valid even in tracker mode).
- SC14.7. STATUS.md role remains DASHBOARD, not SSOT, per BD-185 SC5. Disclaimer in PM-CHAT.md updated to reflect the unified-dashboard role.
- SC14.8. No `GROUPINGS.md` mirror file. `groupings/_toc.md` serves the per-entry-tree TOC role; per-entry tree carries SSOT; STATUS.md absorbs the convenience-reading role.
- SC14.9. Tracker-mode link format is backend-dependent (GitHub issue URL vs Linear project URL vs Jira epic URL vs etc.); per-backend rendering handled via #11 capability matrix.
- SC14.10. Mode transitions (flat-file ↔ tracker per BD-067 reverse) preserve STATUS.md behavior — regenerates cleanly in either mode without surprise content changes.
- SC14.11. STATUS.md regeneration uses the shared reverse-lookup library function from #9 — not a separate implementation. Avoids drift between query verb output and STATUS.md display.

**User-approved design decisions:**
- (a) STATUS.md unified-dashboard design per user direction 2026-05-23 (rejected the prior "STATUS unchanged + disclaimer extension only" design as creating dual SSOTs + brittle authority cascade)
- (b) Disclaimer extension documents three derived surfaces (STATUS.md / per-entry tree TOC / tracker Project Board) and their non-SSOT nature
- (c) Drop GROUPINGS.md mirror (per #5 revision)

**User acknowledgment of complexity cost (2026-05-23):** This design substantially INCREASES the work complexity (roughly 5-10x for the STATUS.md generator) compared to the alternative "STATUS unchanged + disclaimer extension only" design. The complexity is in service of better UX (single jump-point dashboard with cross-linked phases + groupings). User approved with awareness of the tradeoff.

**Architect-level surfaces (the new complexity from the revised design):**
- Cross-tree read at regen: implementation-plan AND groupings trees
- Reverse-lookup at regen time: for each phase, compute which groupings include it (uses shared library from #9)
- Mode-aware rendering: flat-file links always; tracker links conditionally; per-backend URL formatting (tied to #11 capability matrix)
- Intra-doc anchor management: phase-row anchors used by the groupings table's member-phases column; anchor naming convention; collision handling
- New groupings table section in STATUS.md (schema, generator implementation, validation per #13 SC13.14, rendering rules)
- Phase table extension (new column for member-groupings link)
- Test coverage for new content + cross-link integrity + mode-aware rendering + per-backend URL formats
- STATUS.md schema documentation in METHODOLOGY / format spec

**Anchor / cross-references:**
- BD-185 SC5 (STATUS dashboard role lock — unchanged by revision)
- V11.1-DISCUSSION-GITHUB-PROJECTS.md §4 (overlap-zone discussion)
- TOUCH-POINT-INVENTORY-GROUPINGS-V2.md §6.D (major-revision flag resolved by revised design)
- `project-template/docs/pack/PM-CHAT.md:212-220` (existing STATUS disclaimer being extended)
- #5 revision (no mirror; STATUS.md absorbs convenience role)
- #9 (shared reverse-lookup library used by STATUS.md)
- #11 (per-backend tracker link rendering)
- #13 SC13.14 (validation of STATUS.md content)

---

### Capability #15 — Optional / advanced capabilities

**Problem:** Beyond the core groupings feature, several adjacent capabilities could enhance UX or discoverability. Each has different scope and value: Phase-Iteration sprint view (V11.1 §13 Y-6); PRD/journeys cross-reference link rendering (V11.1 §13 Y-7); per-grouping custom fields (GH Projects v2 specific); D-19 recommendation signal extension (8th signal). Each needs a scope verdict.

**Goal:** Decide v11.1 scope for each adjacent capability and document where they land.

**Success criteria:**
- SC15.1. **D-19 recommendation signal:** `grouping_count` joins the existing 7-signal client-side recommendation system; pack-startup surfaces grouping opt-in suggestion when phases exist but groupings don't. **Lands in v11.1.**
- SC15.2. **PRD/journeys cross-reference rendering:** The PRD field per #1 is free-text markdown. Standard markdown rendering automatically supports clickable links — no special tooling required. **No additional capability work needed.**
- SC15.3. **Per-grouping custom fields:** Covered by #10 bi-directional sync + #4 Position 2 (per-Kind default field-maps permitted at architect level); no additional capability surface needed.
- SC15.4. **Phase-Iteration sprint view (Y-6):** OUT OF v11.1 scope. Opened as parking-lot BD-188 for future scheduling (similar to BD-187 pattern). Live forward-pointing anchor preserves the idea.

**User-approved design decisions:**
- (a) D-19 grouping_count signal lands in v11.1 (small extension to existing `scripts/lib/recommendation.sh`; SIZE deferral defense fails)
- (b) BD-188 opened as parking-lot for Y-6 (per pack memory `feedback_deferred_work_tracking` live forward-pointing surface rule); Y-7 + per-grouping custom fields covered elsewhere (no separate scope)

**Architect-level surfaces:**
- D-19 grouping_count threshold logic (when to fire suggestion)
- BD-188 architect content (drafted at scheduling time, not now)

**Anchor / cross-references:**
- V11.1-DISCUSSION-GITHUB-PROJECTS.md §13 (Y-6, Y-7 source)
- TOUCH-POINT-INVENTORY-GROUPINGS-V2.md §11.11 (D-19 signal observation)
- #4 (Kind→default field-map for per-grouping custom fields)
- #10 (sidecar capture for per-grouping custom fields)
- BD-187 (parking-lot precedent for BD-188)
- BD-188 (live anchor for Y-6 sprint view)
- `scripts/lib/recommendation.sh` (existing D-19 implementation surface)

---

### Capability #16 — Install / upgrade scripting

**Problem:** When groupings ship in v11.1+, two install paths must handle the new surface:
- Fresh client install: init-project.sh stage S11 needs to install the groupings tree skeleton (supporting files + empty groupings/ directory; no entry files, no GROUPINGS.md mirror per #5 revision)
- v11.0 → v11.x upgrade: existing clients on v11.0 (no groupings tree) need a migration path that installs the tree skeleton without disturbing user customizations to other v11.0 files

User direction 2026-05-23: v11.0 → v11.1 migration must be FULLY ARCHITECTED, PLANNED, AND IMPLEMENTED — NOT ad-hoc file copies. Architect / planner / coder pipeline rigor required.

**Goal:** Extend existing install + upgrade infrastructure (init-project.sh, BD-119 migrator framework, BD-088 customization-preservation, MIGRATION docs) to handle the groupings tree at fresh install and v11.0 → v11.x upgrade, preserving any user-authored grouping files across upgrade boundaries.

**Success criteria:**
- SC16.1. `scripts/init-project.sh` stage S11 installs the groupings tree skeleton at fresh client install: `_rules.md` + `_intro.md` + empty `_toc.md` + empty `groupings/` directory. **No `GROUPINGS.md` mirror** (per #5 revision).
- SC16.2. `scripts/init-project.sh --update` mode picks up new groupings template files for existing v11.x clients.
- SC16.3. `scripts/migrate-v11.0-to-v11.x.sh` (target version TBD at release-planning time) is a thin adapter sourcing `scripts/lib/migrator-core.sh` per BD-119 framework — NOT a copy-and-rewrite of `migrate-v10-to-v11.sh` per pack memory framework rule.
- SC16.4. `scripts/lib/migrator-core.sh`'s `migrator_target_surface_for_version()` is extended with the v11.x case listing v11.0 surfaces PLUS groupings tree files (`docs/project/groupings/_rules.md`, `docs/project/groupings/_intro.md`). Empty `_toc.md` is generator-produced, not pack-shipped.
- SC16.5. `scripts/lib/customization-preserve.sh` classifier routes `groupings/` files via the generic 3-way text merge path per `pack-ops/MERGE-STRATEGY.md` — no dedicated grouping class.
- SC16.6. Existing user-authored `GRP-NNN.md` files survive both install + upgrade paths without overwrite (per BD-088 customization-preservation pattern).
- SC16.7. `supporting-docs/MIGRATION-v11.0-to-v11.x.md` provides the user-facing upgrade narrative.
- SC16.8. After fresh install OR upgrade, validate-pack passes on the resulting groupings tree (empty state per #17 + per-stream contract per #5 + validation rules per #13).
- SC16.9. `test-fixtures/manifest.txt` regeneration trigger fires per RC9 rule.

**Architect/planner/coder rigor requirements (user direction 2026-05-23):**
- SC16.10. v11.0 → v11.1 migration work goes through the full architect → planner → coder pipeline per pack memory `feedback_pack_chat_does_not_architect` + `feedback_researcher_architect_planner_pipeline`. Pack Chat does NOT perform ad-hoc file copies, informal edits, or "quick patches" for the migration. The pack-architect produces an ARCHITECTURE doc for v11.0 → v11.1 migration; pack-planner produces a PLAN; pack-coder implements per the approved PLAN; pack-reviewer runs the cycle.
- SC16.11. Migration uses the BD-119 framework rigorously.
- SC16.12. Migration is idempotent per BD-088 / BD-119 patterns. Re-running on an already-upgraded client is a verified no-op (same exit code, same file state, no spurious diffs). Idempotency is tested via fixture, not just asserted.
- SC16.13. Migration test fixtures cover at minimum:
  - (a) Fresh-install positive case (clean greenfield client)
  - (b) v11.0 → v11.1 upgrade with NO user customizations (vanilla upgrade)
  - (c) v11.0 → v11.1 upgrade PRESERVING user customizations to existing v11.0 files
  - (d) v11.0 → v11.1 upgrade where the user was in TRACKER MODE pre-upgrade — tracker state preserved across migration boundary; groupings projection added correctly
  - (e) Idempotency case (re-run migration on already-upgraded client; verify no-op)
- SC16.14. Migration handles tracker-mode users (already in tracker mode under v11.0) correctly. Either:
  - (a) Migration extends existing tracker projection to add groupings projection in-place, OR
  - (b) Migration adds groupings flat-file state and requires user to re-run `pack tracker init` for groupings projection (documented in MIGRATION-v11.0-to-v11.x.md)
  
  Architect picks the approach; SC requires that ONE is implemented + documented. No silent tracker-state loss.
- SC16.15. MIGRATION-v11.0-to-v11.x.md is part of the architect's deliverable, not a Pack Chat afterthought.
- SC16.16. The migration architect surfaces v11.0 → v11.1 ROLLBACK / DOWNGRADE considerations.

**User-approved design decisions:**
- (a) Generic 3-way text classifier routing per α
- (b) `v11.x` placeholder for target version in artifact; final number at release-planning
- (c) Single MIGRATION doc per minor version
- (d) Migration goes through full architect → planner → coder cycle with dedicated ARCHITECTURE + PLAN docs; not Pack Chat ad-hoc (user direction 2026-05-23)

**Architect-level surfaces:**
- ARCHITECTURE-v11.0-to-v11.x-migration.md (architect's deliverable)
- PLAN-v11.0-to-v11.x-migration.md (planner's deliverable)
- BD-119 framework hook function bodies for the new migrator
- Tracker-mode-on-during-migration handling specifics (SC16.14 (a) vs (b))
- Test fixture content for each case in SC16.13
- Stage S11 install ordering
- `_toc.md` generator behavior during upgrade

**Anchor / cross-references:**
- BD-080 (init-project.sh stage S11 + --update mode)
- BD-085 (scripts/migrate-v10-to-v11.sh precedent)
- BD-088 (customization-preservation library)
- BD-084 (MIGRATION-v10-to-v11.md narrative precedent)
- BD-119 (migrator framework + migrator-core.sh)
- TOUCH-POINT-INVENTORY-GROUPINGS-V2.md §3.F (install/migrate/customization scripts)
- CLAUDE.md migrator framework rule (no copy-and-rewrite)
- RC9 manifest regen trigger
- #5 revision (groupings tree skeleton; no GROUPINGS.md mirror)
- #14 (no GROUPINGS.md mirror)
- #17 (empty-state handling)

---

### Capability #17 — Degenerate-state handling

**Problem:** Per-entry trees can legitimately be empty — no entries authored yet. This is the initial state after fresh client install (per #16 SC16.1), after v11.0 → v11.1 migration (per #16 SC16.13 case b), and after dissolution of all existing groupings. All consuming operations (validate-pack checks, mirror/TOC generators, operational verbs, tracker projection, STATUS.md dashboard rendering, bi-directional sync) must handle empty state cleanly.

Per C3 scoping direction, empty-state behavior should be CONSISTENT across all per-entry streams (backlog, implementation-plan, changelog, groupings) — not unique to one. This requires the architect to view empty-state handling across all four streams with full context, not designed in isolation per stream.

**Goal:** Empty state is a valid first-class state for the groupings stream AND consistent with how existing streams handle their empty states. Where existing streams have gaps in empty-state handling, those are SEPARATE BDs outside BD-186 scope.

**Success criteria:**
- SC17.1. Empty groupings tree (supporting files populated; empty `_toc.md`; zero `GRP-NNN.md` entries) is a valid, validate-pack-passing state.
- SC17.2. Per-stream contract check (per #13) passes on empty tree.
- SC17.3. Membership rules check (per #3 + #13) does not false-fire against zero groupings — the min-2 rule is per-grouping, not per-tree.
- SC17.4. Cross-reference integrity check (per #13) does not false-fire on empty Member-phases lists.
- SC17.5. Operational verbs (per #9) handle empty tree gracefully — `pack groupings list` returns empty result (not error); typed errors per BD-070 when querying nonexistent groupings.
- SC17.6. Tracker projection behavior on empty tree (per #8) is consistent with how tracker projection handles other empty per-entry-tree states. Architect determines the consistent pattern with full visibility across all streams.
- SC17.7. STATUS.md dashboard rendering on empty groupings (per #14) is consistent with how STATUS.md handles other dashboard-relevant empty states. Architect determines the consistent pattern with full context.
- SC17.8. Bi-directional sync (per #10) handles transitions to and from empty state consistently across streams.
- SC17.9. Empty state is bidirectionally reachable — user can dissolve all groupings (per #3 + min-2-with-exception mechanism) and return to empty state; pack tooling continues to function.
- SC17.10. **Architect-pass-level parity verification:** during v11.1 architect work, verify that empty-state handling is consistent across all per-entry streams. Where parity gaps surface in existing streams, open as SEPARATE BDs outside BD-186 scope. The architect surfaces such gaps; Pack Chat does NOT pre-judge what gaps exist.

**User-approved design decisions:**

NONE locked at requirements level. All design choices (empty-tree rendering in STATUS.md, tracker init behavior on empty tree, verb empty-result behavior, etc.) are architect-level with full cross-stream context. Earlier locked-in (a)/(b)/(c) sub-decisions REJECTED 2026-05-23 as design-shaped without full cross-stream context.

**Architect-level surfaces:**
- Consistent rendering pattern for empty per-entry trees in STATUS.md (or other dashboards)
- Consistent tracker projection behavior on empty trees across all streams
- Consistent verb behavior for empty-tree edge cases
- Empty-state fixture content for validation
- Any cross-stream parity gaps that need separate BDs

**Anchor / cross-references:**
- BD-164 (TOC regenerator pattern + empty-seed form)
- BD-080 (init-project.sh S11 produces empty state at fresh install)
- #5 (per-entry tree structure)
- #13 (validation passes on empty state)
- #14 (STATUS.md dashboard rendering)
- #16 (empty state is initial state after fresh install / migration)
- C3 (this artifact §2)

---

## §5 — BD landscape

### BDs opened during BD-186 triage (this session)

| BD | Title | Status | Position | Anchor |
|---|---|---|---|---|
| BD-186 | Groupings requirements + v11.0/v11.1 scope decision | Open → flips to Resolved on this artifact landing | Batch 19d-parallel (independent of BD-185) | `pack-ops/BACKLOG.md` |
| BD-187 | Standalone entry-type instruction doc for external-tool consumption | Open (TODO(version) parking-lot) | End of v11 active section | `pack-ops/BACKLOG.md` |
| BD-188 | Phase-Iteration sprint view (V11.1 §13 Y-6) | Open (TODO(version) parking-lot) | End of v11 active section, after BD-187 | `pack-ops/BACKLOG.md` |

### v11.1 implementation BD landscape (architect/planner refines)

This artifact does NOT pre-decide the v11.1 BD breakdown for groupings implementation. The architect designs the implementation surface; the planner breaks it into BDs and sequences them. Capability-to-BD mapping is the planner's deliverable, not Pack Chat's.

That said, a likely shape (planner refines):
- BD-A: Per-entry tree infrastructure (#5 + #17) — `groupings/` tree, supporting files, generators, stream-tuple addition
- BD-B: Schema + validation (#1 + #3 + #4 + #13) — grouping doc shape, membership rules, Kind enum, validate-pack checks + fixtures
- BD-C: Workflow integration (#12) — METHODOLOGY + PM-CHAT + trinity + HELP-FRAGMENT + OPTIONAL-FEATURES + agent + skill files
- BD-D: From-phases derivation (#6) — PM-Chat prompt variant + methodology procedure + recognition characteristics
- BD-E: From-external ingest (#7) — PM-Chat prompt variant + methodology procedure
- BD-F: Tracker projection — basic (#8 + #11 GH backend) — `pack tracker init` extension + capability matrix start
- BD-G: Tracker projection — operational verbs + queries (#9 + shared infrastructure with #14) — 8 verbs + shared library
- BD-H: Bi-directional sync (#10) — sync contract + sidecar shape + round-trip test
- BD-I: STATUS.md role coordination + revamped generator (#14) — substantial; could split further per planner
- BD-J: Optional/advanced (#15) — D-19 signal extension
- BD-K: Install / upgrade scripting (#16) — init-project.sh extension + migrator adapter + customization-preserve routing + MIGRATION doc; architect/planner/coder rigor per SC16.10-SC16.16

Planner finalizes the BD breakdown + ordering when v11.1 architect produces the ARCHITECTURE doc.

---

## §6 — Pipeline forward

### v11.1 cycle

1. **Architect pass** — read this artifact + V11.1-DISCUSSION-GITHUB-PROJECTS.md + TOUCH-POINT-INVENTORY-GROUPINGS-V2.md + relevant BD entries (BD-186, BD-187, BD-188); produce ARCHITECTURE-GROUPINGS.md covering the design with full context across all 17 capabilities + cross-stream parity for #17.
2. **User review** of architect output (per pack memory `feedback_planner_user_review_before_coder` cycle).
3. **Planner pass** — produce PLAN-GROUPINGS.md with BD breakdown, commit sequencing, verification strategy.
4. **User review** of planner output.
5. **Coder cycles** — per-BD implementation with reviewer cycles per pack memory `feedback_review_fix_one_cycle` + `feedback_per_bd_inline_review`.
6. **Migration architect/planner/coder pass** (separately scoped per #16 SC16.10) — ARCHITECTURE-v11.0-to-v11.x-migration.md + PLAN-v11.0-to-v11.x-migration.md + implementation.
7. **End-of-batch reviewer + BD status flip + MIGRATION doc landing + release pin.**

### Parking-lot BD scheduling (post-v11.1)

- BD-187 (entry-type instruction doc): scheduling recommendation post-v11.1 ship so doc reflects shipped reality
- BD-188 (sprint view): scheduling deferred until observed user demand for sprint-board view

---

## §7 — Closing

This artifact captures the requirements + user-approved design constraints for the v11.1+ groupings feature as agreed during BD-186 triage 2026-05-21 through 2026-05-23. It is INPUT TO ARCHITECT, not architecture or implementation.

User retains the right to revise requirements at architect-pass time if new constraints surface or assumptions need refinement. Per `feedback_planner_user_review_before_coder` cycle, the architect output IS the next user-review gate; corrections to this artifact can occur there if needed.

End of REQUIREMENTS-GROUPINGS-V11.md.
