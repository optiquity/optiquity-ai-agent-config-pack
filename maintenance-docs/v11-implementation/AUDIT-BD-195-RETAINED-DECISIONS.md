# AUDIT-BD-195-RETAINED-DECISIONS.md

**Pass:** BD-195 (Code Red 3) Step-1 — Retained-Decisions extraction. This doc
extracts every user pre-approved / user-locked BD-185 decision from the
contaminated source corpus IN PLACE, with auditable provenance, so the keep-set
survives the later prisoning (Step 2) of those sources.

**Author:** pack-docs-researcher (read-only pass; one output file).
**Date:** 2026-05-28. **Repo HEAD at extraction:** `e580dda` (per the V2/plan
docs' own `Repo HEAD at authoring` lines; not independently re-derived in this
read-only pass).
**Branch:** v11-dev.

**Scope note / categorical fact applied (BD-195 directive, not re-litigated):**
v11.0 is UNRELEASED (no release tag, never frozen). Phase-parts was ALWAYS
v11.0 scope. Any source statement labelling phase-parts (or other in-flight
v11.0 work) as "v11.1", or asserting v11.0 content was "frozen", is
categorically WRONG and is a contamination signal, NOT a retained decision. I
have therefore extracted the DECISIONS' substance and, where a source stated
the substance under a wrong v11.1/frozen wrapper, I retain the substance and
flag the wrapper as contamination (see OPEN QUESTIONS). The cleanest verbatim
re-statement of each decision under the corrected v11.0 framing lives in
`ARCHITECTURE-BD-185-V2.md` (§2.A/§2.B FIXED inputs, §3 decision log, §11
challenge record) + `ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md` (§2 A-1..A-8);
the original user-lock provenance lives in `ARCHITECTURE-BD-185.md` (§1.3
C-1..C-5, §1.4 D1..D16, §4.x).

---

## COVERAGE ATTESTATION

Every source named in the task body was READ in place at HEAD `e580dda`. Listed
"read" = opened and scanned for approval markers (`user-approved` /
`user-locked` / `user-confirmed` / `user direction` / `user decision` /
`pre-approved` / `FIXED` / `C-N` / `D-N`) plus surrounding decision substance.

Untracked working-tree V2 docs:
- [read] `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-V2.md` (1054 lines; full)
- [read] `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md` (739 lines; full)
- [read] `maintenance-docs/v11-implementation/PLAN-BD-185-V2.md` (965 lines; §0 + §1 in full, remainder via targeted approval-marker grep)
- [read] `maintenance-docs/v11-implementation/PACK-REVIEW-BD-185-H.2.md` (683 lines; §1-§3 in full, remainder via approval-marker grep)
- [read] `maintenance-docs/v11-research/RESEARCH-BD-185-ORDERING-API.md` (368 lines; headline + RG-1 §1-§3; confirmed it is a facts-only verification doc carrying NO user-approved DESIGN decisions)

Committed BD-185-attempt docs:
- [read] `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md` (1233 lines; §1.3 C-1..C-5, §1.4 D1..D16, §3 triage, §4.1/§4.1a/§4.2/§4.3/§4.7/§4.8 in full; remainder via approval-marker grep)
- [read] `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-RECONCILIATION.md` (1590 lines; via approval-marker grep — surfaces 16 D-decisions + 3 user-locked pack-memory rules as inputs, no NEW user-approved design decision beyond what V2 §11 already supersedes)
- [read] `maintenance-docs/v11-implementation/PLAN-BD-185.md` (1424 lines; §1.3 D1..D16 list + §1.4 C-1..C-5 in full; remainder via grep)
- [read] `maintenance-docs/v11-implementation/PLAN-BD-185-ADDENDUM.md` (2266 lines; §2 user-locked inputs + §2.3 re-affirmed decisions in full; remainder via grep)
- [read] `maintenance-docs/v11-implementation/PACK-REVIEW-BD-185-H.1.md` (387 lines; approval-marker grep + §1 pipeline + finding-source table)

Additional committed BD-185 docs encountered while reading (cross-referenced
within the epicenter) and scanned via approval-marker grep:
- [read] `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-POST-PLANNER-POQS.md`
- [noted, not separately mined] `IMPLEMENTATION-REPORT-BD-185-ARCHITECT-DOC-EDITS.md`, `...-ARCHITECT-DOC-REVIEW-FIXES.md`, `...-Batch-19d-H.1.md`, `...-Batch-19d-H.2.md`, `...-H.1-NITS.md` (IMPL-REPORTs are mechanical-application records of the locked decisions above; they introduce no NEW user-approved decision)
- [noted] `maintenance-docs/v11-research/BD-185-DOCS-RESEARCHER-QUEUED-PROMPT.md` (the original queued research prompt; not a decision source)

Pack-side keep-intent:
- [read] `pack-ops/BACKLOG.md` BD-185 entry (L1746-1793: P1-P4, SC1-SC8, Out-of-scope, Pipeline, Position) and BD-195 entry (L3127-3155: Step 1 keep-intent, "retain the user's preapproved good decisions so they need not be re-explained").

**Exhaustiveness statement.** The retained-decision set below is the union of:
(a) the 5 USER-LOCKED constraints C-1..C-5 (original architecture §1.3);
(b) the 16 user-locked decisions D1..D16 (original architecture §1.4), as
carried/re-justified or corrected in V2 §11; (c) the Part lifecycle semantics
the original doc marks "per user direction 2026-05-25"; (d) the v11.0
version-correction the BACKLOG + V2 establish as ground truth; (e) the C-2
REVISION (Issue Fields demoted + gated) the ordering addendum records as a
USER DECISION; and (f) the OQ-A1 resolution PLAN-V2 records as user-resolved.
Items the corpus itself flags as FICTIONAL (the `status:cancelled` Convention-Y
"exercise") or as contamination (v11.1 cut / frozen) are NOT retained as
decisions; the substance behind D5/D16 is captured where a real user direction
underlies it, with the contamination wrapper called out.

---

## RETAINED DECISIONS

### Group 1 — The five USER-LOCKED constraints (C-1..C-5)

RESEARCHER FINDING: retained decision — RD-1: Part-id grammar (C-1, as refined by D15)
- Decision (self-contained): The phase/part/task identifier grammar is
  user-locked. Atoms: Phase = `Phase-N`, `N` matches `[1-9][0-9]*` (integer,
  birth-order, immutable; `Phase-0` legal for v10-compat). Part = `Part-x`,
  `x` matches `[a-z]` (single lowercase ASCII letter; up to 26 per phase).
  Task = `Task-M`, `M` matches `[1-9][0-9]*` (INTEGER ONLY, no letter suffix).
  Composite forms: `Phase-N.Part-x.Task-M` (with Part), `Phase-N.Task-M`
  (null-Part — the `.Part-x` segment is skipped ENTIRELY, never `Phase-N..Task-M`),
  `Phase-N` (phase epic), `Phase-N.Part-x` (Part epic). PROHIBITED: empty
  separator (`Phase-2..Task-7`); lowercase atoms (`phase`/`part`/`task`);
  numeric Part identifier; letter suffix on Task (`Task-3d`). Legacy v11.0 task
  pack-id `phase-N.M` (lowercase, dot-separator) MUST continue to resolve
  (INV-2 no-renumber).
- Source doc(s) + anchor: `ARCHITECTURE-BD-185.md` §1.3 (C-1 statement) +
  §4.1 (canonical enumeration) + §4.1a (task-number rule); D15 refinement at
  §1.4 D15. Re-stated under v11.0 framing at `ARCHITECTURE-BD-185-V2.md` §2.B
  (§1 identifier scheme, "prohibited forms") + §4.1 + §11 CR-14. Re-affirmed
  `PLAN-BD-185.md` §1.4 C-1 + §1.3 D15.
- Establishing quote: `ARCHITECTURE-BD-185.md` §1.3 — *"C-1. Part-id grammar:
  phase = integer only; part = letter only; task = integer base ... Composite
  forms: `Phase-1.Part-a.Task-3d` (with Part), `Phase-2.Task-7` (null-Part ...).
  PROHIBITED: empty-separator forms like `Phase-2..Task-7`."* AND §4.1 —
  *"The grammar is USER-LOCKED 2026-05-25."* AND D15 (§1.4) — *"Letter suffix
  REJECTED grammar-wide; Task-M integer-only ... User-driven (2026-05-26 POQ-4
  discussion)."*
- Why retained: The on-tracker grammar is the foundational identity contract
  the entire phase-parts feature is built on; V2 §2.B explicitly marks it
  "FIXED — adopted verbatim in substance."
- Confidence: high (basis: explicit "USER-LOCKED 2026-05-25" marker + dual
  re-affirmation; ONE wrinkle — see OQ-1 on the C-1-vs-D15 task-suffix conflict).

RESEARCHER FINDING: retained decision — RD-2: Execution-ordering mechanism family (C-2, ORIGINAL form — superseded by RD-15)
- Decision (self-contained, AS ORIGINALLY LOCKED): GitHub Issue Fields is the
  chosen mechanism for v11+ execution ordering (and considered for Part
  identity). The architect must design: (1) Issue Fields shape for ordering;
  (2) Issue Fields shape for Part identity if chosen; (3) a NON-JSON-SIDECAR
  fallback for trackers without Issue Fields (Forgejo, Gitea); (4) a
  flat-file-mode fallback (existing Execution-note convention may suffice or a
  new convention). NOTE: this original C-2 was later REVISED by the user — see
  RD-15. The DURABLE core that survives the revision is items (3) + (4): a
  non-sidecar tracker fallback AND a flat-file `<!-- execution-order: N -->`
  marker are both required; and Issue Fields for Part IDENTITY was REJECTED
  (Parts are first-class sub-issues, RD-6).
- Source doc(s) + anchor: `ARCHITECTURE-BD-185.md` §1.3 (C-2 statement);
  re-affirmed `PLAN-BD-185.md` §1.4 C-2 ("Issue Fields primary; sub-issue
  reprioritize fallback (v11.1+); flat-file marker"). REVISED at
  `ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md` A-2.
- Establishing quote: `ARCHITECTURE-BD-185.md` §1.3 — *"C-2. Issue Fields is
  the chosen mechanism for v11+ execution ordering and may be considered for
  Part identity. Architect MUST design: (1) Issue Fields shape for ordering ...
  (3) NON-JSON-SIDECAR fallback for trackers without Issue Fields (Forgejo,
  Gitea), (4) flat-file-mode fallback ..."*
- Why retained: The requirement that ordering have a tracker mechanism + a
  non-sidecar fallback + a flat-file marker is a user constraint; only the
  Issue-Fields-FIRST priority was later revised (RD-15). The constraint shell
  is retained; the priority is superseded.
- Confidence: high (explicit C-2 user-lock; the revision is separately recorded,
  RD-15).

RESEARCHER FINDING: retained decision — RD-3: Groupings hard rules (C-3)
- Decision (self-contained): Four hard groupings rules constrain the design:
  G-1 groupings contain ONLY phases (no orphan parts, tasks, or backlog
  entries); G-2 minimum 2 phases per grouping; G-3 a backlog entry must be
  converted to a phase AND scheduled before joining a grouping; G-4 the
  architect may skim BD-189 groupings docs but groupings is NOT yet architected
  — anything beyond G-1/G-2/G-3 is groupings-architect judgment. For BD-185
  this constrains the phase-parts design only insofar as Parts are NEVER
  grouping members (G-1).
- Source doc(s) + anchor: `ARCHITECTURE-BD-185.md` §1.3 (C-3); re-affirmed
  `PLAN-BD-185.md` §1.4 C-3. Cross-referenced in `pack-ops/BACKLOG.md` BD-186
  Blockers line ("user constraint C1 excludes phase parts from grouping
  membership").
- Establishing quote: `ARCHITECTURE-BD-185.md` §1.3 — *"C-3. Groupings
  constraints (4 hard rules): G-1 groupings contain ONLY phases (no orphan
  parts, tasks, backlog entries); G-2 minimum 2 phases per grouping; G-3
  backlog entry must be converted to a phase AND scheduled before joining a
  grouping; G-4 architect may skim BD-189 docs but groupings has NOT been
  architected ..."*
- Why retained: User-locked cross-feature boundary; it bounds what phase-parts
  may assume about groupings and is reused by BD-186.
- Confidence: high (explicit C-3 user-lock + independent BACKLOG cross-reference).

RESEARCHER FINDING: retained decision — RD-4: Immutability invariants INV-1..INV-9 are LOCKED (C-4)
- Decision (self-contained): The immutability invariants INV-1..INV-9 (defined
  in the touch-point inventory §9) are user-locked. The design MUST NOT violate
  any; violating an invariant is OUT OF SCOPE for BD-185 and must be surfaced to
  user discussion. The load-bearing ones for phase-parts are INV-1 (phase number
  N is birth-order, immutable), INV-2 (task IDs N.M never renumber), and INV-3
  (tracker entity IDs / GH Issue numbers immutable) — these underwrite SC3.
- Source doc(s) + anchor: `ARCHITECTURE-BD-185.md` §1.3 (C-4); re-affirmed
  `PLAN-BD-185.md` §1.4 C-4. The no-renumber substance carried into
  `ARCHITECTURE-BD-185-V2.md` §1.5 rule 11 + SC3 coverage (§9) +
  `ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md` A-1 ("Decoupled from phase
  number + task ID. Reordering NEVER mutates phase numbers or task IDs").
- Establishing quote: `ARCHITECTURE-BD-185.md` §1.3 — *"C-4. Immutability
  invariants INV-1..INV-9 (per inventory §9) are LOCKED. Design MUST NOT
  violate any; violating an invariant is OUT OF SCOPE for BD-185 and surfaces
  to user discussion."*
- Why retained: Hard correctness constraint the whole design depends on; SC3
  is a direct consequence.
- Confidence: high (explicit C-4 user-lock). Note: INV-1..INV-9 are defined in
  `TOUCH-POINT-INVENTORY-PARTS-AND-ORDERING.md` §9 (an input the V2 doc treats
  as STALE for internal facts but TRUSTED for invariants) — the exact INV text
  was not re-read in this pass; the LOCK on them is what is retained.

RESEARCHER FINDING: retained decision — RD-5: Trinity rule + cross-CLI parity (C-5)
- Decision (self-contained): The trinity rule (CLAUDE.md / AGENTS.md /
  GEMINI.md parity) and cross-CLI parity apply to all BD-185 work; any
  cross-CLI reference uses the canonical reference table at
  `ARCHITECTURE-BD-182.md` §4.1 (audience-correct canonical values, NOT
  byte-identical adoption of CLI-specific paths).
- Source doc(s) + anchor: `ARCHITECTURE-BD-185.md` §1.3 (C-5); re-affirmed
  `PLAN-BD-185.md` §1.4 C-5; carried into `ARCHITECTURE-BD-185-V2.md` §1.5
  rule 9.
- Establishing quote: `ARCHITECTURE-BD-185.md` §1.3 — *"C-5. Trinity rule +
  cross-CLI parity per `CLAUDE.md` § 'Trinity rule' + `ARCHITECTURE-BD-182.md`
  §4.1 canonical reference table for any cross-CLI references."*
- Why retained: Standing pack rule re-affirmed as a BD-185 constraint; governs
  any trinity-touching edit.
- Confidence: high (explicit C-5 user-lock; also a standing pack memory rule).

### Group 2 — Part lifecycle semantics (user direction 2026-05-25; D2/D3/D4)

RESEARCHER FINDING: retained decision — RD-6: Parts are first-class sub-issue entities, not a label/field overlay
- Decision (self-contained): A Part is a first-class tracker entity — a
  sub-issue child of its phase epic (depth 2), and a sub-issue parent of its
  member tasks (depth 3). The `part:M` label-namespace idea (from the BD-185
  File/Symbol line) and the C-2(2) "Issue Fields for Part identity" idea are
  both REJECTED: a Part carries identity in its `pack-id`, and must hold a Goal,
  a state, prerequisites, and member-task parentage — which a label or field
  annotation cannot. Caps respected: sub-issue depth 8 / 100 children-per-parent
  / 1 parent-per-child (the task's single parent becomes its Part once split).
- Source doc(s) + anchor: `ARCHITECTURE-BD-185.md` §4.2 ("Decision: Parts are
  sub-issue children of phase epics, and sub-issue parents of phase tasks") +
  the C-2(2) rejection there. Carried/re-justified at
  `ARCHITECTURE-BD-185-V2.md` §3 D-6 + §2.B §6.
- Establishing quote: `ARCHITECTURE-BD-185.md` §4.2 — *"C-2(2) Issue Fields
  shape for Part identity is REJECTED — Parts are first-class sub-issue
  entities ... Decision: Parts are sub-issue children of phase epics, and
  sub-issue parents of phase tasks."* V2 §3 D-6 — *"the `part:M`
  label-namespace idea floated in the BD-185 File/Symbol line is rejected —
  Parts carry identity in their `pack-id`, not in a label."*
- Why retained: Determines the entire tracker representation of Parts and the
  re-parenting mechanism; it is the architect decision the lifecycle rules
  (RD-7..RD-9) and SC2/SC7 hang on.
- Confidence: high (explicit architect decision derived from C-2 + the FIXED
  SCHEMA §6; consistently carried across both architecture docs).

RESEARCHER FINDING: retained decision — RD-7: Part collapse is REJECTED as anti-pattern (D2)
- Decision (self-contained): Once a phase is split into Parts, the split is
  permanent. There is NO `pack phase collapse` verb in ANY release (not v11.0,
  not v11.1+, not ever). A Part with no active work is marked `status:deferred`;
  a Part whose tasks all complete closes via `status:done`; work that must move
  out of a Part uses `pack task supersede` (RD-9), never collapse. Deferral is
  the only exit for an unused Part.
- Source doc(s) + anchor: `ARCHITECTURE-BD-185.md` §1.4 D2 + §4.7. Carried at
  `ARCHITECTURE-BD-185-V2.md` §2.A + §4.2 + §11 CR-6.
- Establishing quote: `ARCHITECTURE-BD-185.md` §4.7 — *"Reverse operation
  (Part collapse) — REJECTED as anti-pattern per user direction 2026-05-25.
  Once a phase has been split into Parts, the split is permanent. There is NO
  `pack phase collapse` verb in any release (not v11.0, not v11.1+, not
  ever)."*
- Why retained: A permanent lifecycle invariant tied to audit-trail integrity;
  V2 §2.A marks it FIXED.
- Confidence: high (explicit "per user direction 2026-05-25").

RESEARCHER FINDING: retained decision — RD-8: Empty Parts at creation are FORBIDDEN (D3)
- Decision (self-contained): Every Part must contain at least one task at
  creation time. `pack phase split` rejects any split that would leave a Part
  empty. Placeholder/empty Parts cannot exist. (A CI validator extension was
  noted to enforce "every Part has >=1 task sub-issue OR is `status:deferred`".)
- Source doc(s) + anchor: `ARCHITECTURE-BD-185.md` §1.4 D3 + §4.7 ("Part
  creation rule (D3 — no empty Parts)"). Carried at
  `ARCHITECTURE-BD-185-V2.md` §2.A ("no empty Parts at creation").
- Establishing quote: `ARCHITECTURE-BD-185.md` §4.7 — *"Part creation rule
  (D3 — no empty Parts): Every Part must contain at least one task at creation
  time. The `pack phase split` verb enforces this by rejecting splits that
  would leave any Part empty. ... Rationale (user direction 2026-05-25) ..."*
- Why retained: User-driven lifecycle invariant; V2 marks it FIXED.
- Confidence: high (D3 marked "User-driven (2026-05-25)").

RESEARCHER FINDING: retained decision — RD-9: Mid-life re-parenting FORBIDDEN; supersede-only (D4)
- Decision (self-contained): Once Parts exist, a task NEVER moves between
  Parts. Initial Part assignment at `pack phase split` is allowed (the task had
  no Part-parent before — not re-parenting). After that, a task is immutable to
  its Part. To move work conceptually from Part-a to Part-b, use SUPERSESSION:
  the original task stays in Part-a marked
  `status:superseded-by:Phase-N.Part-b.Task-X`; a new task is created in Part-b
  with a linked supersede pointer. There is NO `pack task reparent` verb; any
  such invocation errors with "use `pack task supersede` instead".
- Source doc(s) + anchor: `ARCHITECTURE-BD-185.md` §1.4 D4 + §4.7
  ("Mid-life re-parenting rule (D4 — supersede only)") + §4.8 (`pack task
  supersede` verb spec). Carried at `ARCHITECTURE-BD-185-V2.md` §2.A
  ("no mid-life re-parenting (use `pack task supersede`)") + D-11 (lists
  `pack task supersede` as the only re-parent-adjacent verb).
- Establishing quote: `ARCHITECTURE-BD-185.md` §4.7 — *"Mid-life re-parenting
  (FORBIDDEN per user direction 2026-05-25): Once Parts exist, tasks DO NOT
  move between Parts. ... the path is supersession ... There is NO `pack task
  reparent` verb."*
- Why retained: User-driven lifecycle invariant; defines the `pack task
  supersede` verb's role.
- Confidence: high (D4 marked "User-driven (2026-05-25)" / "FORBIDDEN per user
  direction 2026-05-25").

### Group 3 — Decisions resolved with the user (architect/planner POQ resolutions, D6-D14)

RESEARCHER FINDING: retained decision — RD-10: Execution-note prose is NOT auto-parsed; default to phase number + structured warning (D8)
- Decision (self-contained): The migrator does NOT parse `> **Execution note**:`
  prose to auto-assign execution order. Default ordering value = phase number.
  When an execution note is encountered, the migrator emits a STRUCTURED,
  CONTEXT-RICH WARNING for the user (phase number+title; full note excerpt;
  heuristically-extracted referenced entities, display-only; each entity's
  current state; a contextual assessment; three concrete suggested actions
  including a historical-marker option; a doc cross-reference). The user
  interprets; the verbs mutate the SSOT.
- Source doc(s) + anchor: `ARCHITECTURE-BD-185.md` §1.4 D8 + §6.3. Carried at
  `ARCHITECTURE-BD-185-V2.md` §3 D-10 + §6.3 + §11 CR-9; reaffirmed UNCHANGED
  at `ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md` §6.3.
- Establishing quote: `ARCHITECTURE-BD-185.md` §1.4 D8 — *"Execution-note prose
  parsing | Architect POQ-4 | DEFAULT to phase_number + STRUCTURED CONTEXT-RICH
  WARNING + historical-marker."*
- Why retained: A resolved POQ governing migration behavior (SC8); consistently
  carried and explicitly reaffirmed in the addendum.
- Confidence: high (resolved POQ-4, recorded in the §1.4 decision log).

RESEARCHER FINDING: retained decision — RD-11: New `tracker-phase-part.sh` library (D11)
- Decision (self-contained): The Parts mechanism gets a dedicated
  parser/emitter library `scripts/lib/tracker-phase-part.sh` (parallel to the
  existing `tracker-phase-task.sh`), for Part marker-trio + body-section
  validate/parse/emit in tracker mode.
- Source doc(s) + anchor: `ARCHITECTURE-BD-185.md` §1.4 D11 (+ §10.1/§14.2/
  §14.9 cites). Carried at `ARCHITECTURE-BD-185-V2.md` §3 D-11 + §11 CR-11
  (filename verified repo-unique, rule 13).
- Establishing quote: `ARCHITECTURE-BD-185.md` §1.4 D11 — *"NEW
  `tracker-phase-part.sh` library | Architect POQ-7 | ACCEPTED new file
  (parallel to `tracker-phase-task.sh`)."*
- Why retained: Resolved POQ that fixes a concrete file surface the planner
  sequences; filename uniqueness already verified.
- Confidence: high (resolved POQ-7).

RESEARCHER FINDING: retained decision — RD-12: LAZY `pack-id-v2` marker backfill (D12)
- Decision (self-contained): The `pack-id-v2` body marker is backfilled
  LAZILY — only tasks in phases that undergo Part expansion gain the v2 marker.
  Most v11.0 tasks remain v1-only (`pack-id: phase-N.M`), and the v1 marker
  continues to resolve in all parsers. New tasks created after BD-185 lands
  carry both markers from creation. Parsers prefer `pack-id-v2` when present;
  fall back to `pack-id` otherwise.
- Source doc(s) + anchor: `ARCHITECTURE-BD-185.md` §1.4 D12 + §4.1 + §6.3.
  Carried at `ARCHITECTURE-BD-185-V2.md` §11 CR-16 ("lazy `pack-id-v2` marker
  backfill kept as a reverse-emit detail").
- Establishing quote: `ARCHITECTURE-BD-185.md` §1.4 D12 — *"`pack-id-v2`
  marker backfill | Architect POQ-8 | LAZY — only Part-expanded tasks gain v2
  marker."*
- Why retained: Resolved POQ governing the v10/v11 compatibility shim and
  reverse-emit; consistent across both architectures.
- Confidence: high (resolved POQ-8).

RESEARCHER FINDING: retained decision — RD-13: Issue Fields name-collision fallback (D13)
- Decision (self-contained): When provisioning the org Issue Field for
  execution order, pack capability-detects the field; on a name collision it
  uses the fallback name `Pack Execution Order` (primary name `Execution
  Order`). (This survives into the gated Issue-Fields strategy under RD-15.)
- Source doc(s) + anchor: `ARCHITECTURE-BD-185.md` §1.4 D13 + §5.1. Carried at
  `ARCHITECTURE-BD-185-V2.md` §5.1 + §11 CR-12; survives in the addendum's
  gated Issue-Fields helper (`ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md`
  §5.3 "collision fallback `Pack Execution Order`").
- Establishing quote: `ARCHITECTURE-BD-185.md` §1.4 D13 — *"Issue Fields name
  collision | Architect POQ-9 | Capability-detection + `Pack Execution Order`
  fallback name."*
- Why retained: Resolved POQ; concrete and carried verbatim into the gated
  strategy.
- Confidence: high (resolved POQ-9).

RESEARCHER FINDING: retained decision — RD-14: Mid-development phase appends to END of order (D14)
- Decision (self-contained): A phase created mid-development appends to the END
  of the execution order (the sub-issue priority order / order-root sibling
  list), matching the GitHub default sub-issue append behavior.
- Source doc(s) + anchor: `ARCHITECTURE-BD-185.md` §1.4 D14 + §5.2. Carried at
  `ARCHITECTURE-BD-185-V2.md` §11 CR-13; reaffirmed at
  `ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md` §5.2 ("Append-on-create ...
  matches V2 §11 CR-13").
- Establishing quote: `ARCHITECTURE-BD-185.md` §1.4 D14 — *"Mid-development
  phase position | Architect POQ-10 | Append to END of sub-issue priority
  order (GH default)."*
- Why retained: Resolved POQ governing reorder/append semantics; consistently
  carried.
- Confidence: high (resolved POQ-10).

### Group 4 — The C-2 revision + OQ-A1 resolution (the freshest user decisions, 2026-05-28)

RESEARCHER FINDING: retained decision — RD-15: C-2 REVISED — Issue Fields DEMOTED + GATED; sub-issue-reprioritize is the v11.0 GitHub default
- Decision (self-contained): The original C-2 ("Issue Fields is the v11.0
  first-choice ordering mechanism") is REVISED by the user. GitHub Issue Fields
  `number` stays FULLY DESIGNED and wire-able but is GATED OFF by default in
  v11.0; it is no longer the GitHub first choice. The v11.0 GitHub DEFAULT and
  universal floor is sub-issue-reprioritize against a singleton "order-root"
  issue (repo-write only, GA, works on personal AND org repos). Mechanism
  SELECTION = capability detection x a pack-level availability/enablement gate,
  NOT a hard-coded priority. The driving fact: Issue Fields is org-only +
  org-admin-gated-to-provision + public-preview, so it excludes solo/personal/
  non-admin users and fails the "works for typical users" bar. Issue Fields is
  KEPT (not deleted) so it can be enabled later as a localized policy/config
  change, not new design.
- Source doc(s) + anchor: `ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md` A-2
  ("Issue Fields is DEMOTED and GATED ... revises user-locked C-2") + A-3
  (capability x availability selection) + §9 coverage table row
  ("C-2 revised"). Grounded in `RESEARCH-BD-185-ORDERING-API.md` RG-1 §5/§9
  (org-only, admin-gated, preview). The original C-2 it revises is RD-2.
- Establishing quote: `ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md` A-2 —
  *"This revises the original user-locked C-2 ('Issue Fields is the v11.0
  first-choice') per the explicit USER DECISION recorded in this addendum's
  driving inputs: Issue Fields is KEPT in the design but DEMOTED + GATED."*
  AND A-3 — *"In v11.0 the `issue_fields` gate is shipped OFF ... selection ...
  resolves to `sub_issue_reprioritize` (the universal floor)."*
- Why retained: This is the most recent user decision in the corpus and
  directly contradicts the older C-2/D9 framing; it MUST be preserved across the
  restart so the user is not re-asked. It also supersedes the older D9
  ("reprioritize deferred to v11.1+") — see OQ-2.
- Confidence: high (basis: explicit "USER DECISION" marker in A-2 + the §9
  "C-2 revised" success-criterion + the closed RG-1 facts that motivate it).
  Medium-confidence sub-point: the addendum attributes the decision to "this
  addendum's driving inputs" (the spawn prompt), which I did not read directly;
  the decision itself is unambiguously recorded as a user decision — see OQ-2.

RESEARCHER FINDING: retained decision — RD-16: OQ-A1 resolved to the middle path (Issue-Fields LAYER-3 ships as a documented stub)
- Decision (self-contained): For the K2 ship posture (whether to fully wire the
  gated Issue-Fields backend now), the user resolved OQ-A1 to the MIDDLE PATH:
  FULLY IMPLEMENT + TEST everything personal-account-testable (the three
  abstract ordering ops, the capability x availability selector, the
  4-condition gate with G1 shipped false, the universal floor, all consumers
  routing through the abstract ops, migration ordering-writes, the rate-limit
  throttle, root-chaining, and the `tracker.toml [execution_order]` config);
  but ship the GH-Issue-Fields LAYER-3 call shapes (field provision / value
  read / value write) as a DOCUMENTED STUB carrying the RG-1 verified call
  shapes as typed-TODO comments (`# TODO(version): TD-TBD — ...`). The GA switch
  remains K1 (flip the boolean) + K2 (fill in the recorded stub shapes).
- Source doc(s) + anchor: `PLAN-BD-185-V2.md` §0.3 ("The OQ-A1 implement-vs-stub
  boundary (user-resolved; encoded per commit)") + §0.4 SZ-2; the open question
  itself is `ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md` §11 OQ-A1.
- Establishing quote: `PLAN-BD-185-V2.md` §0.3 — *"Per the user decision
  recorded in the addendum §11 OQ-A1 (resolved to the middle path): FULLY
  IMPLEMENT + TEST (all personal-account-testable) ... DOCUMENTED-STUB ONLY the
  GH-Issue-Fields LAYER-3 call shapes ..."* AND §0.4 SZ-2 — *"The user resolved
  OQ-A1 to the middle path."*
- Why retained: A concrete user resolution of an explicitly-surfaced open
  question; preserving it means the OQ-A1 implement-vs-stub question is NOT
  re-opened at restart.
- Confidence: high (basis: PLAN-V2 §0.3 + SZ-2 both state "user-resolved" /
  "user resolved OQ-A1"). Note: the plan records the resolution; I did not read
  the originating chat. The decision is consistently stated twice in PLAN-V2.

RESEARCHER FINDING: retained decision — RD-17: INDEX "Frozen forms" reword (Group G) is APPROVED
- Decision (self-contained): The optional polish to the v11.0 INDEX (rename the
  "Frozen forms" heading to "Archived forms" and replace the bare "D16"
  shorthand with "BD-193 bug-fix carve-out"), surfaced as OPEN-Q-1 in the V2
  architecture, was APPROVED by the user for application during implementation
  (PLAN-V2 work-stream A-1). The BD-193 carve-out FACT and BD-193's behavior are
  preserved; only the "frozen" framing wording changes.
- Source doc(s) + anchor: `PLAN-BD-185-V2.md` §B work-stream table row "G"
  ("`v11.0/INDEX.md` 'Frozen forms'->'Archived forms'; bare 'D16'->'BD-193
  bug-fix carve-out' (APPROVED)") + the §2 note "per the mission prompt, Group
  G is APPROVED — apply it in A-1." Originating open question:
  `ARCHITECTURE-BD-185-V2.md` §10 Group G / OPEN-Q-1.
- Establishing quote: `PLAN-BD-185-V2.md` (line ~237) — *"per the mission
  prompt, Group G is APPROVED — apply it in A-1."* AND (line ~826) — *"G —
  `v11.0/INDEX.md` 'Frozen forms'->'Archived forms'; bare 'D16'->'BD-193
  bug-fix carve-out' (APPROVED)."*
- Why retained: An explicit approval to apply a previously-optional reword;
  preserving it avoids re-surfacing OPEN-Q-1 to the user.
- Confidence: medium (basis: PLAN-V2 says "per the mission prompt ... APPROVED";
  the approval is attributed to the planner's mission/spawn prompt rather than a
  directly-quoted user statement. The V2 architecture had left it as
  surface-to-user OPEN-Q-1. See OQ-3.)

### Group 5 — The v11.0 version-correction ground truth (categorical, BD-195-confirmed)

RESEARCHER FINDING: retained decision — RD-18: Phase-parts is v11.0 scope; there is NO v11.1 archive cut; nothing in v11.0 is frozen
- Decision (self-contained): Phase-parts (and all of BD-185 P1-P4 / SC1-SC8) is
  v11.0 scope. v11.0 is UNRELEASED (no git release tag), so its templates-archive
  cut is MUTABLE and nothing in it is frozen. There is NO `templates-archive/v11.1/`
  cut for BD-185 — the phase-part entry type is the 6th entry type of the
  existing v11.0 cut. The phase-part `template_version` / `template:` label /
  SCHEMA title read `phase-part-v11.0` (NOT `-v11.1`). The work-item form does
  NOT bump to `work-item-v11.1` (it stays `work-item-v11.0`; the additive
  changes are intra-v11.0). The ONLY legitimate v11.1 reference in all of BD-185
  is GH Projects integration, which is a DIFFERENT feature and stays
  Out-of-scope/deferred.
- Source doc(s) + anchor: `pack-ops/BACKLOG.md` BD-195 entry (Goal + "Known-broken
  SEED": "v11.0/v11.1 mis-versioning") — the user's directive; the categorical
  fact in the BD-195 mission. Re-derived as ground truth at
  `ARCHITECTURE-BD-185-V2.md` §0 (FACTS 1-4) + §3 D-1/D-2/D-3/D-4 + §11
  CR-1/CR-2/CR-3, and as the binding contamination guardrail at
  `PLAN-BD-185-V2.md` §0.2. Corroborated by `templates-archive/README.md`
  ("append-only after a release tag") + `templates-archive/translations.yaml`
  L8-9 (per V2 §0 FACT 2 citation).
- Establishing quote: `ARCHITECTURE-BD-185-V2.md` §0 — *"v11.0 is UNRELEASED.
  It is the current in-development version ... It has no git release tag. ...
  Phase-parts is v11.0 scope, unambiguously."* AND BD-195 BACKLOG entry —
  *"v11.0/v11.1 mis-versioning + pack/project boundary residue are the two we
  currently KNOW about."*
- Why retained: This is the categorical fact BD-195 instructs all passes to
  APPLY (not re-litigate). It is the corrected framing every retained design
  decision lives under, and the prior corpus's contrary "v11.1 cut / frozen"
  framing is the contamination the restart removes.
- Confidence: high (basis: explicit BD-195 user directive + BD-195's own
  "categorical fact you must apply" framing in the task; independently
  corroborated by README/translations.yaml per V2 §0).

---

## NOT RETAINED (flagged contamination / fictional — recorded so they are not re-imported)

These appear in the corpus as if they were decisions, but the corpus itself (or
the BD-195 categorical fact) shows they are wrong. Listed here so the restart
does NOT accidentally carry them forward as "retained."

- **D5 — `cancelled` state added to phase-task taxonomy (7-state).** The
  original architecture §1.4 D5 + the v11.1/INDEX "Convention Y exercised twice"
  claim assert BD-185 adds a `status:cancelled` state to
  `phase-task-v11.0/SCHEMA.md`. `ARCHITECTURE-BD-185-V2.md` §3 D-5 + §11 CR-15
  + §11 "Gaps" #1 VERIFIED this FALSE: the SCHEMA never received it; BD-185 does
  NOT add a cancelled state to any entry type; Parts explicitly EXCLUDE a
  cancelled state (deferral is the only exit). DO NOT retain a "7-state task
  taxonomy" or any `status:cancelled` addition as a user decision. (If the user
  DID at some point want a cancelled state, that is a separate, currently-fictional
  claim needing its own confirmation — see OQ-4.)
- **D16 — "v11.0 archive structural shape frozen at 5 subdirs."** The
  "frozen → therefore a v11.1 cut" inference is the core contamination
  (`ARCHITECTURE-BD-185-V2.md` §3 D-3 + §11 CR-1 reject it). The REAL,
  retainable substance under D16 is only: (a) the v11.0 archive is MUTABLE while
  v11.0 is unshipped (RD-18), and (b) BD-193's `bd`-option-removal carve-out
  FACT stays (preserved, version-framing-neutral). The "frozen" wrapper is NOT
  retained.
- **D9 — "defer `provider_sub_issue_reprioritize` to v11.1+."** Superseded by
  RD-15: the abstract reprioritize floor is the v11.0 GitHub DEFAULT, designed
  AND shipped in v11.0 (the op is designed; non-GitHub concrete backends remain
  Reserved by the BD entry, which is a legitimate backend-coverage line, NOT a
  v11.1 deferral). The "v11.1+ deferral" half of D9 is contamination-adjacent;
  do not retain it. See OQ-2.

---

## OPEN QUESTIONS (intent-only — for the user; ambiguous approval status)

OQ-1 — C-1 grammar: the original verbatim C-1 admitted a Task letter-suffix
(`Phase-1.Part-a.Task-3d`), but D15 (user-driven, 2026-05-26) REJECTED letter
suffixes grammar-wide and locked Task-M integer-only. RD-1 retains the
POST-D15 form (integer-only). Confirm this is the intended final grammar (i.e.,
the original C-1's `Task-3d` example was an earlier draft the user later
overrode). If for any reason the letter-suffix was meant to survive, RD-1 needs
correction. Source conflict: `ARCHITECTURE-BD-185.md` §1.3 (C-1, with `Task-3d`)
vs §1.4 D15 + §4.1 prohibited-forms (no suffix).

OQ-2 — C-2 / RD-15 / D9 reconciliation: three different framings of the
ordering mechanism exist across the corpus, each marked user-locked at its time:
(a) original C-2 "Issue Fields primary" (2026-05-25); (b) D9 "reprioritize
fallback, deferred to v11.1+" (2026-05-25); (c) the addendum A-2 "Issue Fields
DEMOTED + GATED; reprioritize is the v11.0 default" (2026-05-28, the freshest).
RD-15 takes (c) as the surviving decision because it is the latest and is marked
an explicit USER DECISION. Please confirm (c) is the retained ordering decision
and (a)+(b) are superseded. (I did not read the addendum's "driving inputs" /
spawn prompt directly; the addendum attributes the revision to a user decision,
which I am surfacing rather than assuming.)

OQ-3 — Group G ("Frozen forms"->"Archived forms" + drop bare "D16") approval
provenance: V2 architecture left this as surface-to-user OPEN-Q-1 ("do not
auto-apply"). PLAN-V2 then states "per the mission prompt, Group G is APPROVED."
RD-17 retains it as approved, but the approval is attributed to the planner's
mission/spawn prompt rather than a directly-quoted user statement. Please
confirm Group G is genuinely user-approved (vs a planner inference from prompt
framing).

OQ-4 — phase-task `cancelled` state: D5 claims the user wanted a `cancelled`
state added to the phase-task taxonomy, but V2 verified the SCHEMA never got it
and treats the whole claim as fictional. Was a phase-task `cancelled` state ever
actually a user decision (separate from Parts, which correctly exclude it)? If
yes, it is currently UNIMPLEMENTED and would need its own anchor; if no, it
should be dropped entirely. I have NOT retained it. (Note: Parts' 4-state
taxonomy pending/in-progress/done/deferred IS retained as part of the FIXED
grammar under RD-1's grammar family / V2 §2.B §4 — that is settled and excludes
cancelled.)

OQ-5 — INV-1..INV-9 exact text: C-4 (RD-4) locks the immutability invariants by
reference to `TOUCH-POINT-INVENTORY-PARTS-AND-ORDERING.md` §9, which I did not
re-read in this pass (it is outside the named source set and the V2 doc treats
its internal facts as STALE while trusting its invariants). If the restart needs
the verbatim INV text preserved, that inventory §9 should be added to the
retained-source read set before the inventory is prisoned (if it is prisoned).

OQ-6 — `_order.md` separate-file decision (D7): the original architecture §1.4
D7 locked `_order.md` as a separate per-entry supporting file (POQ-3 "Option Y")
WITH an SSOT-vs-view contract. The V2 corpus (V2 §5.4 + addendum A-1) RETAINS the
SSOT contract (ordering value owned by the phase entity; any `_order.md` is a
regenerated view, never the SSOT) but treats whether an `_order.md` view file is
created at all as a planner option ("if the planner adds one"). I did NOT elevate
D7 to a standalone retained decision because its load-bearing core (ordering SSOT
on the phase entity, STATUS.md stays a dashboard) is already captured under RD-4
(INV/no-renumber) + RD-15/A-1. Confirm whether the user wants the explicit
`_order.md` separate-file decision (D7) retained as a hard requirement, or
whether the SSOT-contract-only retention (current) is correct.

---

*End of AUDIT-BD-195-RETAINED-DECISIONS.md (Step-1 extraction).*
