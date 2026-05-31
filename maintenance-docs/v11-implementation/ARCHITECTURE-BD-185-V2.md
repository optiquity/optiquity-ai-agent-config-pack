# ARCHITECTURE-BD-185-V2.md — Phase parts hierarchy + tracker-mode execution ordering (v11.0)

**Status:** Authoritative. Standalone. Self-contained.
**Authored:** 2026-05-28. **Repo HEAD at authoring:** `e580dda`.
**Scope:** Pack-side design for BD-185 (P1–P4 / SC1–SC8), landing in **v11.0**.

---

## §0 — Supersession notice (read first)

**Forward pointer — ordering subsystem superseded (BD-195 S1, 2026-05-31).**
The tracker-mode execution-ordering subsystem of this doc — §5.1/§5.2, the D-7
mechanism clause, D-8, §7 ordering ops, and §6 ordering reads/writes — is
**SUPERSEDED** by `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md`
§0.1. For execution-ordering, the ORDERING-ADDENDUM wins; this doc remains
authoritative for everything else (phase-parts hierarchy, archive shape,
decision log, contamination-correction enumeration). The supersession is
one-directional: read the ORDERING-ADDENDUM for ordering, this doc for all else.

This document **SUPERSEDES** both prior BD-185 architect docs in their entirety:

- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md` (original)
- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-RECONCILIATION.md`

A reader needs **neither** superseded doc to act on this one. The decision log
(§3), challenge record (§11), and contamination-correction enumeration (§10)
are complete here.

**Why supersession is required.** Both prior docs carry one categorical error:
they treated **v11.0 as a closed/shipped version** and routed all phase-parts
work into a nonexistent **"v11.1 archive cut."** That premise is false.

**The corrected ground truth (FACTS this design is built on):**

1. **v11.0 is UNRELEASED.** It is the current in-development version
   (`README.md` version table, top row — "v11.0 | May 2026"). It has **no git
   release tag**.
2. **The archive is mutable while v11.0 is open.** `templates-archive/README.md`
   states the archive "is append-only **after a release tag**." v11.0 has no
   tag → nothing in the v11.0 archive cut is frozen. Independent corroboration:
   `templates-archive/translations.yaml` L8 reads *"At v11.0 the manifest is
   empty (no v11.x has shipped yet)"* and L9 *"When v11.1 ships..."* — the
   archive's own translation manifest documents v11.0 as not-yet-shipped and
   v11.1 as a FUTURE cut.
3. **Phase-parts is v11.0 scope, unambiguously.** BD-185 SC8 governs "any
   v11.0 forward-migration"; its Unblocks line names "v11.0 flat→tracker
   migrators." The ONLY legitimate v11.1 reference in the BD entry is **GH
   Projects integration**, listed under **Out of scope** — a different feature.
   GH Projects stays deferred. Everything else BD-185 covers is v11.0.
4. **The "structural freeze → therefore a v11.1 cut" premise is rejected.** The
   prior "Convention Y / D16" clause over-generalized a narrow user approval
   (additive edits to an existing schema) into a structural freeze of the
   whole v11.0 archive cut, then used the freeze to justify minting a v11.1
   directory. The user never approved a structural freeze of v11.0. See §3
   (D-7) and §11 (challenge record CR-1, CR-2, CR-3).

**What does NOT change.** The phase-part on-tracker **grammar** (identifier
scheme, body marker trio, label family, 4-state taxonomy, body section
grammar, sub-issue hierarchy, body marker reservations) is a **FIXED,
user-approved input** (§2.B). Phase-part creation/usage **semantics** (§2.A)
are fixed. The error this doc corrects is the **version framing only**
(location, naming, the `v11.1` version tag, the v11.1-cut placement).

---

## §1 — Scope, inputs, method

### §1.1 — Problem statements (BD-185 P1–P4)

Read verbatim from the BD-185 entry at `pack-ops/BACKLOG.md`. Summarized:

- **P1 — Mid-work phase splits have no first-class tracker representation.**
  `supporting-docs/METHODOLOGY.md` § "Multi-part phases" defines "Part 1,
  Part 2" sub-sections inside `IMPLEMENTATION-PLAN.md`, but the tracker
  form-family has no Part field, no Part label, and computes task titles as
  `Phase N.M` with no Part awareness.
- **P2 — The hierarchy changes when Parts are added.** Pre: Phase N → Tasks
  N.1..N.k. Post: Phase N → Parts, each containing tasks. Existing task IDs
  must survive without renumbering. No documented grouping mechanism exists.
- **P3 — Tracker-mode execution ordering has no native mechanism.** GH Issues
  lack a user-mutable execution-order field; issue numbers reflect creation
  order; blockers give only partial order; sub-issues give containment, not
  sibling order. In flat-file mode ordering lives in execution notes that do
  not survive sync to a regenerated mirror.
- **P4 — v10→v11 and flat→tracker migrations must absorb pre-existing
  whole-number phases** without manual intervention, initializing the new
  ordering mechanism from current implementation order.

**Plus the corrected-scope problem (P0):** the prior architecture mis-versioned
all of P1–P4 as v11.1. This doc lands it in v11.0.

### §1.2 — Success criteria

This design satisfies BD-185 SC1–SC8 (read them at `pack-ops/BACKLOG.md`; not
restated here). Section-by-criterion coverage is in §9. Two
corrected-scope criteria are added:

- **SC-V (version correctness):** phase-parts lands in v11.0; no v11.1 cut; no
  bump to a nonexistent v11.1; D16 entanglement resolved without breaking
  BD-193's completed work.
- **SC-B (boundary compliance):** the design honors boundary rules 1–13 (§1.5);
  placement choices are shown where they could go either way (§8).

### §1.3 — Inputs read (authoritative, current working tree)

- `pack-ops/BACKLOG.md` — BD-185 entry in full (P1–P4, SC1–SC8, File/Symbol,
  Out-of-scope); BD-193 entry + Resolved line; BD-194 entry.
- `README.md` (version table — v11.0 top row, no tag; Repository Layout).
- `CLAUDE.md` § "Pack memory" (boundary rules 1–13).
- `templates-archive/README.md`, `templates-archive/translations.yaml`,
  `maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md`, `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md`,
  `maintenance-docs/v11-research/templates-archive/v11.1/phase-part-v11.1/SCHEMA.md` (the FIXED grammar),
  `maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml`.
- LIVE forms: `.github/ISSUE_TEMPLATE/work-item.yml` (pack-root),
  `project-template/.github/ISSUE_TEMPLATE/work-item.yml`.
- `scripts/validate-pack.py` — `check_issue_template_forms()`,
  `check_template_archive_v11()`.
- `scripts/tests/test-issue-forms.sh` (Groups 2 + 5).
- `supporting-docs/METHODOLOGY.md` § "Multi-part phases" (current L414–441;
  BD-185 entry's "~339–366" cite has drifted).
- `maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-PARTS-AND-ORDERING.md`
  — EXTERNAL GH findings (§4) TRUSTED; internal form/validator facts treated
  as STALE and independently re-verified against the working tree (§2.C).

**Prior architect docs** (`ARCHITECTURE-BD-185.md`,
`ARCHITECTURE-BD-185-RECONCILIATION.md`) were read under the challenge mandate
(§11). The two contaminated PLAN docs were NOT read.

### §1.4 — Method

Design-only. No code, no diffs, no commit sequencing — the downstream planner
orders commits; the coder implements; the reviewer verifies. Every prior
decision (D1–D16 in the superseded corpus) was independently re-justified under
the corrected v11.0 premise; adopted substance is re-derived and re-numbered in
this doc's own decision log (§3, D-1..D-N) with NO live references to prior-doc
D-IDs. Prior-doc decision IDs appear only inside the challenge record (§11) as
historical citations.

### §1.5 — Boundary rules honored (anchors)

1. **Pack/project separation** — pack and project versions of any doc/file are
   separate artifacts; pack is never a fallback for project.
2. **BD entries are pack-only operationally** — client-facing content must not
   operationally treat BDs; may reference in explanatory contexts with
   pack-only disclosure.
3. **Project-side concepts on pack-side surfaces — deliverable-only** — TD /
   phase / phase-part / phase-task references on pack-side surfaces are allowed
   ONLY when the surface constructs a project-side deliverable; forbidden in
   pack-self-management.
4. **Client-facing doc token economy** — default remove pack-only references
   from RAG-indexed client-facing docs unless client-necessary.
5. **Enumerate ENCODING surfaces** — every surface that encodes a rule's
   expected state (surface + validator + test + CI workflow + cross-ref docs)
   updates in lock-step.
6. **Separate pack ops from pack product.**
7. **P-missed-7** — investigate the project-side SSOT first.
8. **DISJOINT invariant** — pack-root wi-type `{bd}` and project-template
   wi-type `{td, phase-epic-skeleton, phase-task-skeleton, phase-part-skeleton}`
   are disjoint.
9. **Trinity rule** — audience-correct canonical values, not byte-identical
   adoption of CLI-specific paths.
10. **Tracker portability** — GH-specific mechanisms designed as abstractable
    through the BD-060 TrackerProvider pattern.
11. **Entry-type data-structure semantics** — phases never born split; Parts
    are evolution-only; tasks are phase components; groupings hold phases only.
12. **No deferral without user direction** — all phase-parts work lands in
    v11.0.
13. **Filename uniqueness** — proposed new files do not collide repo-wide.

---

## §2 — Fixed inputs (adopted as-is) and verified current state

### §2.A — Phase-part creation & usage semantics (FIXED — not challenged)

Per the SCHEMA §intro + §4 lifecycle invariant and METHODOLOGY § "Multi-part
phases":

- Phases begin with **zero Parts**. A phase too big at birth splits into **two
  phases** (each a new immutable number), never a born-split phase.
- Parts are **evolution-only**, introduced mid-work by `pack phase split` /
  `pack tracker phase split` when a phase must be expanded.
- **No collapse, no delete, no empty Parts at creation, no mid-life
  re-parenting** (use `pack task supersede`). **Deferral is the only exit** for
  an unused Part.

### §2.B — Phase-part on-tracker GRAMMAR (FIXED — adopted verbatim in substance)

Defined in the SCHEMA at
`maintenance-docs/v11-research/templates-archive/v11.1/phase-part-v11.1/SCHEMA.md`.
This design adopts, without redesign:

- **§1 identifier scheme** — `Phase-N.Part-x`; `Part-x ∈ [a-z]`; uniqueness per
  project per phase; prohibited forms (empty separator, lowercase atoms,
  numeric Part).
- **§2 body marker trio** — `pack-id`, `template_version`, `pack-version` (same
  three marker types, same order as phase-epic / phase-task).
- **§3 label family** — `phase-part`, `phase-N`, `template:<part-version>`,
  `status:<pending|in-progress|done|deferred>`; the excluded-labels list
  (no merge, no supersede-by, no cancelled, no derived-from:TD).
- **§4 restrictive 4-state taxonomy** — pending / in-progress / done /
  deferred (LOAD-BEARING).
- **§5 body section grammar** — Goal / Prerequisites / Member tasks; fixed
  order; Prerequisites Part-id forms; Member-tasks informational.
- **§6 sub-issue hierarchy** — Part at depth 2; tasks at depth 3; one
  phase-epic parent; no parenting to tasks.
- **§8 body marker reservations** — `execution-note-status: historical` is
  reserved for the phase epic, intentionally absent from Parts.

**VERSION-TAG CARVE-OUT (the ONE thing in the SCHEMA that is NOT fixed).** The
embedded `phase-part-v11.1` tag — the title string, the §2 `template_version`
marker value, and the §3 `template:phase-part-v11.1` label — is part of the
v11.1 contamination, **not** the approved grammar. It corrects to the v11.0
framing this doc designs (§3 D-1: `phase-part-v11.0`). The grammar substance is
unchanged; only the version label moves.

**Still-open (NOT fixed — designed here):** the reverse-emit grammar (SCHEMA §7
is explicitly TBD); the tracker-mode execution-ordering mechanism (the SCHEMA
does not cover ordering); how the Part affordances integrate into the work-item
form; migration of pre-existing whole-number phases; validate-pack.py checks and
all ENCODING surfaces; correct v11.0 placement/naming; D16 resolution.

### §2.C — Verified current state of the form-family + validator (re-verified, not from the stale inventory)

The TOUCH-POINT inventory's internal form/validator facts predate BD-193/BD-194.
Verified directly against the working tree at HEAD `e580dda`:

| Surface | Verified state |
|---|---|
| Pack-root `work-item.yml` | `wi-type` options = **`{bd}`** ONLY (1 option). No `wi-part-letter`. Blockers description carries no phase grammar. `template:work-item-v11.0` label + `work-item-v11.0` body marker. |
| Project-template `work-item.yml` | `wi-type` options = **`{td, phase-epic-skeleton, phase-task-skeleton, phase-part-skeleton}`** (4 options). Has `wi-part-letter` (conditional on `phase-part-skeleton`). Blockers/Unblocks/Dependencies admit `Phase-N.Part-x` + `Phase-N.Part-x.Task-M`. `template:work-item-v11.0` label + `work-item-v11.0` body marker. |
| `validate-pack.py` `check_issue_template_forms()` | `expected_wi_type_options_per_surface = {pack-root: {bd}, project-template: {td, phase-epic-skeleton, phase-task-skeleton, phase-part-skeleton}}`. Inline comments (L1086, L1121–1123) assert these were "added at **v11.1** (BD-185 H.2)". |
| `validate-pack.py` `check_template_archive_v11()` | Informational. Hardcoded to `v11.0/` only; checks **5** entry-type subdirs (bd, td, phase-epic, phase-task, inbound); byte-compares archived v11.0 forms against live forms (INFO-only on client drift). Does NOT reference `v11.1/` or `phase-part`. |
| `test-issue-forms.sh` Group 2 + 5 | Surface-aware: asserts the same per-surface option sets, the `wi-part-letter` presence (project-template only) / absence (pack-root), the Part-id Blockers grammar (project-template only), the DISJOINT invariant, and `work-item-v11.0` markers. Inline comments (L18–19, L94–95, L138–142, L162, L180, L264–265) assert these were "added at **v11.1** (BD-185 H.2)". |

**Two facts that constrain the correction (§10):**

1. The **functional substance already landed correctly** — the live forms carry
   `work-item-v11.0` markers (NOT a bumped v11.1 marker), the wi-type sets are
   disjoint and correct, and the validator/test assertions match. **Only the
   version FRAMING is wrong** (comments + archive directory name + SCHEMA tag +
   the v11.1/INDEX.md "bump to work-item-v11.1" claim).
2. The contaminated `maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml` snapshot
   **itself** carries `template:work-item-v11.0` (L7) and body marker
   `work-item-v11.0` (L186) — internally contradicting the v11.1/INDEX.md claim
   that the form bumped to `work-item-v11.1`. The contamination is incoherent on
   its own terms; the correction is to drop the bump claim, not honor it.

---

## §3 — Decision log (self-contained; this doc's own numbering)

No live references to prior-doc D-IDs. Where substance is carried from the
superseded corpus, it is re-derived under the v11.0 premise. Cross-references to
prior decisions live only in §11.

### D-1 — Phase-part template version is `phase-part-v11.0` (NOT v11.1)

The phase-part entry type is introduced **in v11.0** (the current version).
Its `template_version` body marker, `template:` label, and SCHEMA title all
read `phase-part-v11.0`. Rationale: v11.0 is the version under development; the
entry type ships as part of it; the version tag of a new artifact is the
version it ships in. This is the single substantive correction the grammar
carve-out (§2.B) requires.

### D-2 — There is NO new template-archive minor cut for BD-185

BD-185 does **not** mint a `maintenance-docs/v11-research/templates-archive/v11.1/` directory. The
phase-part SCHEMA, the INDEX update, and the form snapshot all land **inside the
existing `maintenance-docs/v11-research/templates-archive/v11.0/` cut**, because:

- The archive convention is **one directory per pack minor version**
  (`templates-archive/README.md` § Versioning rules). v11.0 is the live minor;
  v11.1 does not exist as a pack version.
- A new archive cut is created **when a new version ships** ("the live forms are
  updated first, then the old shipped versions are copied into the archive in a
  separate commit. The archive is append-only **after a release tag**").
  No tag → no cut.
- `translations.yaml` confirms no v11.x transition exists yet (empty `[]`; L8–9
  describe v11.1 as future).

So the phase-part entry type is the **6th entry type of the v11.0 cut**, added
to `maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md`, with its SCHEMA under
`maintenance-docs/v11-research/templates-archive/v11.0/phase-part-v11.0/`. (See §10 for the full
relocation enumeration and §4.4 for the form-snapshot decision.)

### D-3 — The v11.0 archive cut is MUTABLE while v11.0 is open (resolves the D16 entanglement)

**Decision.** The v11.0 archive cut accepts content changes (additions,
extensions, and bug-fix carve-outs) for as long as v11.0 has no release tag.
The "structural shape frozen at 5 entry-type subdirs" framing from the
superseded corpus is **rejected**.

**Why the prior "frozen" framing was already self-contradicted.** BD-193 F2.c
**removed** the stray `bd` option from `maintenance-docs/v11-research/templates-archive/v11.0/forms/work-item.yml`.
You cannot remove content from a frozen artifact. The fact that completed,
correct BD-193 work mutated the v11.0 archive **proves** the cut was never
frozen. The superseded RECONCILIATION doc itself graded its own "frozen" clause
as NEEDS-ADJUSTMENT once it noticed the carve-out — but it patched the symptom
(added a "Class B carve-out" exception) instead of rejecting the root premise.
This doc rejects the root premise: while v11.0 is open, its archive cut is
mutable. Additions (the phase-part 6th entry type), additive extensions, and
bug-fix carve-outs are all simply "changes to an unshipped artifact."

**What this preserves (BD-193 must not break).** BD-193's work is correct and
stays:
- The `bd`-option removal from `maintenance-docs/v11-research/templates-archive/v11.0/forms/work-item.yml`
  (the archived form is the client-facing/project-template shape; the pack-root
  `{bd}` form lives at its live path, not duplicated in the archive).
- The `v11.0/INDEX.md` "Frozen forms" note at L31–34, which documents the
  carve-out:

  > "...the original v11.0 shipped form admitted a 4th `bd` option; D16 removed
  > it from the archive as a bug-fix carve-out."

  This footnote is **version-framing-neutral** — it describes a content
  carve-out, not a freeze, and does not depend on the rejected "v11.1 cut"
  clause. **It stays as-is in substance.** (Optional polish in §10 / OPEN-Q-1:
  whether the "D16" shorthand and "Frozen forms" heading should be reworded now
  that the broader "frozen" framing is rejected — but the carve-out FACT and
  BD-193's behavior are untouched either way.)

**What this rejects.** The contaminated clause that said: "v11.0 structural
shape is frozen → therefore BD-185 work belongs in a new v11.1 cut." That
inference is invalid on both halves: v11.0 is not frozen, and even if a future
release froze it, the cure would be "ship BD-185 before the v11.0 tag," not
"mint a v11.1 cut for an unshipped version."

### D-4 — `maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md` becomes a 6-entry-type index

The phase-part row is added to the v11.0 INDEX client-applicable table
(TD, phase-epic, phase-task, **phase-part**, inbound + the pack-internal BD
row). The phase-part `template_version` and `template:` label read `-v11.0`.
The v11.0/INDEX "Frozen forms" section's wi-type enumeration updates to reflect
that the **project-template** form now admits `phase-part-skeleton` (the archive
captures the client-facing form per BD-193 precedent — see D-9 / §4.4). The
"append-only after a release tag" rule from the README continues to apply: once
v11.0 ships, this 6-entry-type cut freezes and v11.1 (whenever it ships) would
reference it.

### D-5 — `status:cancelled` is NOT introduced by BD-185 (corrects a fictional prior claim)

The superseded v11.1/INDEX.md (L47–49) claimed "Convention Y is exercised
twice," one exercise being a `status:cancelled` extension to
`phase-task-v11.0/SCHEMA.md`. **Verified false:** `phase-task-v11.0/SCHEMA.md`
contains no `status:cancelled`. BD-185 does **not** add a cancelled state to any
entry type. Parts explicitly **exclude** a cancelled state (SCHEMA §3
excluded-labels; an unused Part exits via `deferred`, §2.A). This design touches
the phase-task SCHEMA **only** if a real, separately-justified need arises — and
none does for BD-185. The phase-task taxonomy stays as shipped. (Challenge
record CR-4.)

### D-6 — Parts are first-class tracker entities (sub-issues at depth 2), NOT a label overlay

Per the FIXED SCHEMA §6, a Part is a sub-issue child of its phase epic
(depth 2), parent of its tasks (depth 3). The `part:M` label-namespace idea
floated in the BD-185 File/Symbol line is **rejected** — Parts carry identity in
their `pack-id`, not in a label. Rationale: SC2 (mid-work tracker
representation) and SC7 (round-trip) require a Part to carry a Goal, a state,
prerequisites, and member-task parentage — a label cannot hold that. EXTERNAL
finding (inventory §4.1): sub-issues support depth 8 / 100 children / **1 parent
per child** — Part-at-depth-2 is well within caps, and the 1-parent constraint
is satisfied because a task's single parent becomes its Part (not its phase
epic) once the phase is split (SCHEMA §6 re-parentage). This is design substance
carried from the corpus and re-justified here; the version framing is corrected
to v11.0 throughout.

### D-7 — Execution ordering: the ordering value lives ON THE PHASE ENTITY; never on STATUS.md or a flat-file mirror

**Decision.** Phase execution order is a per-phase value owned by the phase
entity itself:
- **Tracker mode:** a GH **Issue Field** (`number` type) on the phase-epic
  issue (§5.1). Fallback for trackers without Issue Fields: sub-issue
  reprioritize against a pack-managed order-root (§5.2).
- **Flat-file mode:** an HTML-comment body marker `<!-- execution-order: N -->`
  on each `phase-N.md` (§5.3).

`STATUS.md` stays a dashboard (SC5) — it DISPLAYS order, never owns it. Any
`_order.md` convenience view is a **regenerated view of the SSOT, never the
SSOT** (§5.4). This satisfies SC4 (ordering expressible in both modes, not
dependent on a flat-file artifact in tracker mode, not GH-Projects-based) and
SC5. Carried substance; v11.0-framed.

### D-8 — Issue Fields is the GitHub primary path; it is a NEW design-space option flagged for primary-source verification at implementation

EXTERNAL finding (inventory §4.7): GitHub Issue Fields reached public preview
for **all** organizations 2026-05-21 — a `number` field type exists, 25-field
org cap, preconfigured Priority/Effort/Start/Target. This feature did NOT exist
at the v11 EXTERNAL-RESEARCH pass (2026-04-30); it is a NEW option. The design
adopts a dedicated org-level `number` field `Execution Order` (NOT a
preconfigured field — Priority/Effort are semantically wrong). **Residual
research gap (RG-1, §7):** preview-status "subject to change" caveat; exact
read/write call shape via `gh api graphql`; whether per-issue cardinality and
`gh`-CLI exposure are sufficient. The planner/coder MUST verify against the live
primary docs before committing to a call shape. This is a genuine EXTERNAL
dependency, not a v11.1 deferral.

### D-9 — Form integration is PER-SURFACE and audience-specific; the archive snapshots the project-template (client-facing) form

The Part affordances integrate into the work-item form **per surface**, honoring
the DISJOINT invariant (rule 8) and the deliverable-only rule (rule 3):

- **Project-template form** (constructs the project-side deliverable): admits
  `phase-part-skeleton` as a 4th wi-type option; adds `wi-part-letter`; admits
  Part-id forms in Blockers/Unblocks/Dependencies. **Already shipped at H.2 and
  CORRECT** (§2.C) — no functional change needed, only comment de-contamination.
- **Pack-root form** (pack-self-management): admits **`{bd}` ONLY**; gets
  **NO** Part affordances. Parts are a project-side concept; admitting
  `phase-part-skeleton` to the pack-self-management form would violate the
  deliverable-only rule. **Already correct** (§2.C) — no change.
- **Archive snapshot:** a single `work-item.yml` snapshot capturing the
  **project-template (client-facing)** form (§4.4 / D-9 rationale). This
  matches the BD-193 precedent: the v11.0 archive form is project-template-shaped
  (the pack-root `{bd}` variant lives at its live path; the archive does not
  duplicate it).

The form `template_version` stays **`work-item-v11.0`** (§2.C fact 2; the prior
"bump to work-item-v11.1" was contamination and is also internally contradicted
by the snapshot's own markers). The `phase-part-skeleton` option fits under the
BD-068 soft cap of 5 on the project-template surface (4 ≤ 5; no defense
required). Carried substance, corrected for the post-BD-194 `{bd}`-only pack-root
reality (the superseded RECONCILIATION doc still treated pack-root as carrying
td/phase concepts — that premise was stale; CR-5).

### D-10 — Migration backfills the ordering value from current implementation order; pre-existing whole-number phases pass through unchanged

Per SC8 + SC3: the v10→v11 migrator (BD-119 framework) and any v11.0
flat→tracker forward-migration:
- Pass pre-existing whole-number phases through with **no renumbering** (phase
  numbers and task IDs N.M are immutable, SC3).
- Initialize the ordering value from **current implementation order** — for
  OT-style birth-order = execution-order projects, `execution-order = phase
  number`; the design does NOT auto-parse execution-note prose, instead emitting
  a structured, context-rich warning for user interpretation (§6.3).
- For any phase that already carries `### Part` H3 sub-sections in
  `IMPLEMENTATION-PLAN.md` (a planner split a phase before tracker opt-in),
  Phase A preserves the H3 content inline; Phase B (tracker opt-in) creates the
  Part sub-issues and re-parents tasks. Carried substance; v11.0-framed.

### D-11 — Parts mechanism gets a dedicated parser/emitter library; ordering verbs are new pack verbs

The SCHEMA §2/§5 require a Part parser/emitter; ordering requires read/reorder
verbs. The design introduces (names checked for repo-wide uniqueness, rule 13):
- `scripts/lib/tracker-phase-part.sh` — Part marker-trio + body-section
  validate/parse/emit (tracker mode). **Unique** (0 repo matches).
- `pack phase split` / `pack tracker phase split` — create Parts mid-work.
- `pack phase reorder` / `pack tracker phase reorder` — mutate the ordering SSOT.
- `pack task supersede` — the only re-parent-adjacent verb (SCHEMA §2.A).

These are design names for the planner to confirm; exact host scripts
(`pack-phase.sh` vs extending `pack-tracker.sh`) are a planner concern. The
ordering value and Part membership round-trip through the TrackerProvider
abstraction (§7) so non-GitHub backends can plug in analogs (rule 10).

### D-12 — Reverse-emit grammar for Parts (SCHEMA §7 TBD) is specified here

SCHEMA §7 is explicitly TBD; this doc specifies it (§6.4) under v11.0 scope.
Parts reverse-emit as **H3 sub-sections inside `phase-N.md`** (no per-Part
per-entry file): `### Part a — <title>` carrying the Goal, with H4 task headers
grouped under their Part. The H3+H4 grouping is the flat-file round-trip carrier
for Part membership; tracker-mode membership round-trips via sub-issue
parentage. This honors the per-entry tree contract (Parts are content WITHIN the
phase entry, not separate entries — consistent with §8.2's decompose anchor on
H2).

---

## §4 — Parts mechanism design

### §4.1 — Part identity and grammar (adopts FIXED SCHEMA §1–§6, §8 verbatim; version tag → v11.0)

Identity: `Phase-N.Part-x` (`Part-x ∈ [a-z]`). Round-trip carriers: title prefix
`Phase N.Part x — <title>` + body marker `<!-- pack-id: phase-N.Part-x -->`.
Marker trio (corrected version tag):

```
<!-- pack-id: phase-N.Part-x -->
<!-- template_version: phase-part-v11.0 -->
<!-- pack-version: v11 -->
```

Label family: `phase-part`, `phase-N`, `template:phase-part-v11.0`,
`status:<pending|in-progress|done|deferred>`. State taxonomy: the FIXED 4-state
restrictive set (LOAD-BEARING). Body section grammar: Goal / Prerequisites /
Member tasks (fixed order). Hierarchy: Part at depth 2 under one phase epic;
tasks at depth 3 under their Part. (All per §2.B; only the version tag differs
from the SCHEMA-as-written.)

### §4.2 — Part as a tracker entity (SC2)

A `pack [tracker] phase split` operation, given a phase epic and a user's
task-to-Part assignment:
1. Creates `phase-part-v11.0` sub-issues under the phase epic (one per Part),
   each with the marker trio, label family, and Goal/Prerequisites/Member-tasks
   body.
2. Re-parents each existing task from the phase epic to its assigned Part using
   the existing `provider_sub_issue_unlink` + `provider_sub_issue_create` op
   pair (the 1-parent-per-child constraint means a task is parented to its Part,
   not simultaneously to the phase epic — SCHEMA §6).
3. Preserves all existing task IDs `N.M` (SC3 — no renumber). The Part adds a
   grouping layer; it does not rename tasks.

The reverse operation (Part collapse) is REJECTED as anti-pattern (§2.A);
deferral is the only exit for an unused Part.

### §4.3 — Flat-file Parts (SC2 in flat-file mode)

In flat-file mode a phase split adds `### Part a` / `### Part b` H3 sub-sections
to the phase's `phase-N.md` per-entry file (and the regenerated
`IMPLEMENTATION-PLAN.md` mirror reflects them). This is the existing METHODOLOGY
§ "Multi-part phases" representation (the **project-side SSOT** per P-missed-7,
rule 7) — the design EXTENDS it for the mid-work expansion mechanism rather than
inventing a parallel pack-style structure. The decompose anchor stays on H2
(§8.2), so Parts-as-H3 are captured as content within the phase entry.

### §4.4 — Form-family integration (SC6) — per-surface; archive snapshots client-facing form

**Project-template form** (constructs project-side deliverable — Part
affordances ALLOWED per deliverable-only rule):
- `wi-type`: `{td, phase-epic-skeleton, phase-task-skeleton, phase-part-skeleton}`
  (4 options; ≤ BD-068 soft cap of 5). **Already shipped, correct (§2.C).**
- `wi-part-letter` input (conditional on `phase-part-skeleton`). **Shipped.**
- Blockers/Unblocks/Dependencies admit `Phase-N.Part-x` + `Phase-N.Part-x.Task-M`
  (and must NOT re-introduce `BD-NNN` — BD-193 dep-grammar cleanup). **Shipped.**
- `template_version` stays `work-item-v11.0` (no bump). **Shipped, correct.**

**Pack-root form** (pack-self-management — Part affordances FORBIDDEN per
deliverable-only rule): `wi-type` = `{bd}` only; no `wi-part-letter`; no Part-id
Blockers grammar. **Already correct (§2.C); no change.**

**DISJOINT invariant (rule 8):** `{bd}` ∩ `{td, phase-epic-skeleton,
phase-task-skeleton, phase-part-skeleton}` = ∅. Holds.

**Archive form-snapshot decision (D-9).** The v11.0 archive captures a SINGLE
`work-item.yml` snapshot of the **project-template (client-facing)** form. This
matches the existing v11.0 archive precedent (the archived form is
project-template-shaped post-BD-193 carve-out; the pack-root `{bd}` form is
preserved at its live path and in git history, not duplicated in the archive).
Rationale: the archive's stated purpose (`templates-archive/README.md`) is to
reflect "what clients install"; the client installs the project-template form.
Capturing pack-self-management `{bd}` form state in the client-facing archive
would mix pack-ops into pack-product framing (rule 6). The snapshot's markers
read `work-item-v11.0` (consistent with the live form).

**Why no template_version bump (SC6 — smallest delta).** The work-item form
gains one wi-type option, one conditional input, and three description
extensions — all **backward-compatible additive** changes to an unshipped
(v11.0) form. Since v11.0 has not shipped, the form is still at its first-and-only
v11.0 cut; there is no prior shipped `work-item-v11.0` to migrate FROM, so there
is no version bump and no `translations.yaml` transition. The ONLY new
`template_version` value introduced by BD-185 is `phase-part-v11.0` (the new
entry type). This is the smallest possible delta consistent with SC2/SC7 (Parts
need a body-carrying entity, which a label cannot provide).

---

## §5 — Execution-ordering mechanism (SC3 / SC4 / SC5 / SC7)

### §5.1 — GitHub primary path: Issue Fields `Execution Order` (number)

| Property | Value |
|---|---|
| Field name | `Execution Order` (fallback `Pack Execution Order` on org name-collision) |
| Field type | `number` (one of the 4 Issue-Field types per inventory §4.7) |
| Applies to | Phase-epic issues (tasks inherit order via phase membership) |
| Semantics | Smaller = earlier; **sparse** values allowed (gaps avoid renumber-on-insert; e.g., insert at 2.5 between 2 and 3); null sorts LAST (uninitialized) |
| Mutability | Pack-mutable via the new `provider_set_field` op (§7) |

**Why a dedicated `number` field, not a preconfigured field or single-select:**
`Priority`/`Effort` are semantically wrong (priority ≠ order; effort ≠ order).
Single-select would require enumerating order values at field-definition time
(an org-admin operation on every insert — brittle). A `number` field admits
arbitrary sparse values without schema change.

**Org-level constraints & detection.** Issue Fields are org-defined (25-field
cap). At `pack tracker init`, pack capability-detects the field (creates or
reuses), records the resolved name in `tracker.toml [execution_order]`, and
`pack tracker doctor` verifies existence + `number` type + writeability. If the
org has exhausted the 25-field cap, the fallback (§5.2) activates.

**RESIDUAL RESEARCH GAP RG-1 (§7).** Issue Fields are public preview ("subject
to change"). The exact `gh api graphql` read/write mutation shape, per-issue
cardinality, and `gh`-CLI exposure MUST be verified against the live primary
docs (inventory §4.7 cites the two changelog posts) before the coder commits to
a call shape. This is an EXTERNAL dependency for the implementation pass, NOT a
deferral of the BD-185 feature.

### §5.2 — Fallback for trackers without Issue Fields: sub-issue reprioritize against an order-root

For trackers lacking an Issue-Fields-or-analog (and the GH org-cap-exhausted
edge case): pack creates a singleton **order-root** issue at `pack tracker
init`; all phase epics are linked as its sub-issues; **phase execution order =
sibling order under the order-root** (the reprioritize endpoint provides total
order among siblings). Pack writes order via the new
`provider_sub_issue_reprioritize` op (§7); reads via the existing
`provider_sub_issue_list`.

**Why sub-issue reprioritize over a label namespace (`order:NNN`):** a label
namespace bloats the label set (one label per phase; 50+ phases → 50+ labels),
costs a label-set update per reordered phase, and needs zero-padding to sort
lexically. Sub-issue reprioritize is one API call, order-explicit, and read-free
(`_sub_issue_list` already returns sibling order).

**EXTERNAL caveat (inventory §4.1, §4.2 — TRUSTED).** Sub-issue reprioritize is
**sibling-only** (parent-scoped order, NOT a global project order on its own).
That is exactly why the order-root pattern works: putting **all phase epics
under one order-root** makes "siblings under the order-root" == "global phase
order." The exact REST/GraphQL reprioritize body-parameter names
(`sub_issue_id`/`after_id` vs alternatives) are **NOT** primary-source verified
(inventory §4.2 flags a snippet-only source). **RESIDUAL RESEARCH GAP RG-2
(§7).**

**Scope boundary (rule 12 — this is NOT the phase-parts v11.1 error).** GitHub
(Issue Fields) is the v11.0 BD-185 ship path. Non-GitHub backends
(Linear/Jira/GitLab/Redmine) are listed **Reserved** in the BD-185 Out-of-scope
("tracker backends other than github — reserved"); the fallback design is
specified abstractly so those backends inherit the abstract ops (rule 10) but
their concrete implementations are out of BD-185's scope by the BD entry itself.
This is a backend-coverage axis, distinct from the version-framing error.
Forgejo/Gitea concrete support is likewise a Reserved-backend concern. The
abstract `provider_sub_issue_reprioritize` op is DESIGNED in v11.0; whether a
v11.0 dispatcher stub ships or the op is wired only for GitHub's edge case is a
planner sizing decision — NOT a phase-parts deferral.

### §5.3 — Flat-file mode ordering: per-phase HTML marker

Each `phase-N.md` carries `<!-- execution-order: N -->` alongside its existing
body markers. The marker is parseable by the per-entry tools, ignored by
Markdown viewers. The existing METHODOLOGY `> **Execution note**:` prose stays
for human-readable rationale.

**Mirror sort (verify-then-fix, per inventory §3.D.3).** The per-entry mirror
generator currently sorts `phase-N.md` filenames with `LC_ALL=C sort` (lexical
— `phase-10.md` before `phase-2.md`). The design sorts the
`project-implementation-plan` stream by the tuple `(execution-order,
phase_number, filename)`: read each entry's `execution-order` marker (default to
phase number if absent; filename if both absent). Result: greenfield / migrated
projects with no markers sort by phase number (= current implementation order,
P4); projects with markers sort by the marker.

### §5.4 — STATUS.md stays a dashboard (SC5, LOCKED)

STATUS.md does not become an ordering SSOT. When regenerated, its phase table
**displays** phases in execution order (sorted by the read ordering value) — a
display change, not an ownership change. Any `_order.md` convenience view (if
the planner adds one) is a regenerated view of the per-phase SSOT, carrying the
standard "never source of truth" disclaimer. The ordering SSOT is the phase
entity's Issue-Field value (tracker) or `execution-order` marker (flat-file).

### §5.5 — Reorder verb

`pack phase reorder` (flat-file: rewrites markers in `phase-N.md`, regenerates
mirror + STATUS.md) and `pack tracker phase reorder` (tracker: writes the
ordering value via Issue Fields or the fallback). Reordering touches ONLY the
ordering value — never phase numbers (SC3) or task IDs. Sparse values let a user
insert between two phases without renumbering.

---

## §6 — Migration design (SC8)

### §6.1 — v10 → v11 migrator (BD-119 framework)

**Phase A (local file changes, `scripts/lib/migrate-v10-to-v11/`):** the
decompose step (`_v10_to_v11_decompose_streams`) that emits per-entry
`phase-N.md` files additionally writes the `<!-- execution-order: N -->` marker,
value = the phase's 1-indexed position in `IMPLEMENTATION-PLAN.md` (= current
implementation order, P4). For OT-style birth-order = execution-order projects,
this equals the phase number. If a v10 plan already contains `### Part` H3
sub-sections, Phase A preserves them inline (decompose anchors on H2) and logs a
notice that Phase B will create Part tracker entities.

**Phase B (optional tracker opt-in):** `pack tracker init` provisions the
`Execution Order` Issue Field (or detects + reuses), then after all phase epics
are created, writes ordering values (1..N) from current implementation order.
For trackers using the fallback, it creates the order-root and links phase epics
as siblings in implementation order. If Phase A detected H3 Parts, Phase B
creates the `phase-part-v11.0` sub-issues and re-parents tasks per the H3
grouping.

### §6.2 — v11.0 flat → tracker forward-migration

The path for a v11.0 flat-file project opting into tracker mode (this is the
SC8 "any v11.0 forward-migration" surface — the corrected scope; there is no
"v11.0 → v11.1" migration because v11.1 does not exist):
- For each phase, read its `execution-order` marker and write it to the phase
  epic's Issue Field (or fallback) post-create (`provider_set_field`).
- For each phase carrying H3 Parts, create `phase-part-v11.0` sub-issues and
  re-parent tasks.
- Phase-task Dependencies admit `Phase-N.Part-x` targets.
- Write per-Part membership + state to the tracker sidecar (round-trip support).

### §6.3 — Execution-note handling: structured warning, no auto-ordering (D-10)

The migrator does NOT parse `> **Execution note**:` prose to auto-assign order
(default = phase number). When it encounters an execution note, it emits a
**structured, context-rich warning** for the user containing: phase number +
title; the full note text (excerpt, not paraphrase); referenced entities
extracted by heuristic regex (phase numbers, BD-NNN, TD-NNN, phase-N.M —
display-only, never auto-assigned); each referenced entity's current
state/order; a contextual assessment (e.g., all referenced phases done → likely
historical); three concrete suggested actions ([1] accept default, [2] `pack
phase reorder phase-N --order X.Y` with a suggested sparse value, [3] mark
historical via `<!-- execution-note-status: historical -->`); and a doc
cross-reference. The user interprets; the verbs mutate the SSOT.

**Worked example (OT-style 60-phase project, P4 absorption):** phases 1..60 in
birth-order = execution-order; migrator assigns `execution-order = phase_number`
(1..60); no execution notes → no warnings; mirror emits phases in order = phase
number = user intuition. Pre-existing whole-number phases pass through unchanged
(SC8, SC3).

### §6.4 — Reverse migration (tracker → flat) — specifies SCHEMA §7 (D-12)

`_tmr_emit_implementation_plan` and `_tmr_emit_status` sort phases by the read
`Execution Order` value (was: `phase_number`), writing the `<!-- execution-order:
N -->` marker into each emitted `phase-N.md`. For phases with Part children, the
emitter writes H3 `### Part a — <subtitle>` sub-sections with H4 task headers
grouped under their Part — the flat-file round-trip carrier for Part membership.
Phase-task body emit carries the Part-scoped identifier where a task belongs to
a Part. Tracker-only enrichment (reactions/comments/attachments) is preserved in
the reverse-migration sidecar.

---

## §7 — TrackerProvider abstraction (rule 10) + research gaps

Per the BD-060 18-op surface (verified at `scripts/lib/tracker-provider.sh`),
BD-185 adds:

| New op | Purpose | GitHub backing | Portability note |
|---|---|---|---|
| `provider_set_field <issue-id> <field-name> <value>` | Write an Issue Field value (ordering primary path, §5.1) | `gh api graphql` field mutation (RG-1) | Linear Properties / Jira+GitLab+Redmine Custom Fields inherit the abstract op (Reserved backends) |
| `provider_get_field <issue-id> <field-name>` | Read an Issue Field value (reverse-emit sort, §6.4) | same | same |
| `provider_sub_issue_reprioritize <parent-id> <child-id> [--after <sibling>]` | Move a sub-issue to a new sibling position (ordering fallback, §5.2; sibling-only per inventory §4.1) | REST `PATCH .../sub_issues/priority` or GraphQL `reprioritizeSubIssue` (RG-2) | Forgejo/Gitea native ordering is a Reserved-backend concern |

**Existing-op behavior changes:** `provider_create` writes the Part marker trio
(`phase-part-v11.0`) for Part entities; `provider_sub_issue_create` admits a
Part as a valid sub-issue parent (was: phase epic only) — the parent-id regex
extends from `^phase-\d+$` to admit `^Phase-\d+(\.Part-[a-z])?$`;
`provider_set_labels` admits the existing `status:*` vocabulary on Parts (no new
namespace); `provider_link` admits `Phase-N.Part-x` dependency forms;
`provider_capabilities` returns `execution_order.mechanism ∈ {issue_fields,
sub_issue_reprioritize, none}` and `parts.supported`.

**Portability (rule 10).** The ordering and Parts mechanisms are expressed
entirely through `provider_*` ops, so a Linear/Jira/Redmine user plugs in their
analog (Properties / Custom Fields for ordering; native sub-tasks for Parts) per
the BD-060 TrackerProvider pattern. The GH-specific call shapes live only in
`tracker-provider-gh.sh`.

**Residual research gaps (EXTERNAL dependencies — flag to planner; NOT
deferrals):**

- **RG-1 — Issue Fields call shape + status.** Public-preview "subject to
  change"; verify the `gh api graphql` read/write mutation, per-issue
  cardinality, and `gh`-CLI exposure against the two changelog posts +
  "Adding and managing issue fields" doc (inventory §4.7) before committing a
  call shape.
- **RG-2 — sub-issue reprioritize body params.** The REST/GraphQL parameter
  names (`sub_issue_id`/`after_id` vs alternatives) are snippet-sourced only
  (inventory §4.2); verify against the live REST sub-issues doc + GraphQL
  mutations reference before the fallback path is coded.

Both gaps are GitHub-capability questions the researcher fact base flags as
needing primary-source confirmation at implementation time. They do not block
the architecture; they bound the coder's verification step.

---

## §8 — Boundary placement (show-your-work where it could go either way)

### §8.1 — phase-part SCHEMA + INDEX + form snapshot: pack-side, but deliverable-constructing → ALLOWED

The phase-part SCHEMA, the v11.0 INDEX row, and the form snapshot live under
`maintenance-docs/v11-research/templates-archive/v11.0/` — a **pack-side**
surface. Rule 3 (deliverable-only) test: *is this surface constructing a
project-side deliverable, or doing pack-self-management?* The template archive
is the source-of-truth for `pack tracker update-templates` and reverse-migration
translation — it **constructs/governs the project-side tracker representation**
that clients install. Therefore project-side concepts (phase-part, the
project-template form snapshot) are ALLOWED here. This is the same reasoning that
already permits the v11.0 archive to carry td/phase-epic/phase-task schemas. PASS.

### §8.2 — Parts in METHODOLOGY: project-side SSOT first (P-missed-7) → EXTEND, don't invent

METHODOLOGY § "Multi-part phases" is the **project-side flat-file SSOT** for
Parts (rule 7). The design EXTENDS that existing structure (H3 sub-sections,
the Part-vs-pass distinction, the report-header convention) for the mid-work
expansion mechanism — it does NOT import a pack-style structure. METHODOLOGY is
client-installed (`docs/pack/`), so the extension must stay client-appropriate:
no BD references operationally (rule 2), no pack-ops references (rule 4). PASS.

### §8.3 — The work-item forms: DISJOINT, per-surface (rules 3 + 8)

The project-template form (deliverable) carries Part affordances; the pack-root
form (self-management) does not. The DISJOINT invariant holds. The validator +
test ENCODE this; they update in lock-step (§10, rule 5). PASS.

### §8.4 — Ordering verbs + Issue Field: pack scripts that emit/manage project-side tracker state → ALLOWED

`scripts/lib/tracker-phase-part.sh`, the reorder verbs, and `provider_set_field`
are pack-side scripts that construct/manage the project-side tracker
deliverable. Rule 3 test: constructing a deliverable → ALLOWED. They must not
reference BDs operationally (rule 2) or carry pack-self-management semantics.
PASS.

### §8.5 — What is FORBIDDEN (the boundary the prior passes risked)

- The **pack-root** work-item form must NOT gain `phase-part-skeleton` (it is
  pack-self-management; Parts are project-side). Verified absent (§2.C).
- METHODOLOGY / the project-template form must NOT reference BD-NNN
  operationally (rule 2) — the Part-id dependency grammar admits
  `phase-N`/`phase-N.M`/`Phase-N.Part-x`/`Phase-N.Part-x.Task-M`/`TD-NNN`, NOT
  `BD-NNN` (BD-193 cleanup; verified §2.C).
- The validator/test inline comments must not leave **"v11.1 (BD-185 H.2)"**
  framing in client-adjacent or pack-self-management surfaces — corrected in
  §10.

---

## §9 — Success-criteria coverage

| Criterion | Where satisfied |
|---|---|
| SC1 (split-at-creation = two phases, both modes) | §2.A + §4 (born-split forbidden; oversize-at-birth → two phases) |
| SC2 (mid-work expansion to Parts, both modes; preserve phase + task IDs) | §4.2 (tracker) + §4.3 (flat-file); SC3 preserved |
| SC3 (no renumber; tracker IDs immutable) | §4.2 step 3, §5.5, §6.1–§6.4 (ordering value is separate from phase number/task ID) |
| SC4 (ordering expressible both modes; tracker not flat-file-dependent; no GH Projects) | §5.1 (Issue Fields), §5.2 (fallback), §5.3 (flat-file marker); GH Projects stays out-of-scope |
| SC5 (STATUS.md stays a dashboard) | §5.4, §8.2 |
| SC6 (form-family + label + smallest template_version delta) | §4.4 (one new `phase-part-v11.0` template; no form bump; ≤ soft cap) |
| SC7 (bi-directional sync preserves Part membership + order) | §6.2 (forward), §6.4 (reverse), §7 (provider ops round-trip) |
| SC8 (v10→v11 + any v11.0 forward-migration absorb whole-number phases; init order) | §6.1, §6.2, §6.3 worked example |
| SC-V (v11.0 correctness; no v11.1 cut; D16 resolved) | §0, §3 D-1..D-5, §10 |
| SC-B (boundary rules 1–13) | §1.5, §8, §10 |

---

## §10 — Contamination-correction enumeration (files + content; NOT git mechanics)

**Path convention for this section (BD-195 F-AC1-01).** All archive paths in
this section are relative to `maintenance-docs/v11-research/`; when executing
recipe steps, prefix that path. The inline path forms below have already been
normalized to the full `maintenance-docs/v11-research/templates-archive/...`
shape per BD-195 F-AC1-01 — this preamble is belt-and-suspenders against
future bare-form regression.

This enumerates exactly what must change to bring the shipped H.1/H.2 artifacts
**and their ENCODING surfaces** (rule 5) to the correct v11.0 state. The
**substance already shipped is correct** (§2.C fact 1); the corrections are
**version-framing relocations + de-contamination of comments**. Forward-fix
sequencing (git unwind vs forward-edit) is a planner/coder concern, explicitly
out of scope here.

**Group A — Relocate the phase-part SCHEMA into the v11.0 cut.**
- **From:** `maintenance-docs/v11-research/templates-archive/v11.1/phase-part-v11.1/SCHEMA.md`
- **To:** `maintenance-docs/v11-research/templates-archive/v11.0/phase-part-v11.0/SCHEMA.md`
- **Content edits inside it:** correct the version tag everywhere it appears
  (title L1 `phase-part-v11.1` → `phase-part-v11.0`; §2 marker
  `template_version: phase-part-v11.1` → `-v11.0` at L43 + L117; §3 label
  `template:phase-part-v11.1` → `-v11.0` at L69; prose mentions at L4, L49, L63,
  L187, L217). **Do NOT** change any grammar substance (§1–§6, §8 stay verbatim).
  Fix the §4.1 cross-references inside §5 that point at sibling v11.0 SCHEMAs
  (paths shift from `../v11.0/...` to `../...` once co-located).
- **Encodes:** none in code (no script/validator consumes the SCHEMA path — verified).

**Group B — Fold the phase-part entry type into the v11.0 INDEX; retire the v11.1 INDEX.**
- **Edit:** `maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md` — add the phase-part row to the
  client-applicable table (`template_version` = `phase-part-v11.0`, label =
  `template:phase-part-v11.0`, schema link `phase-part-v11.0/SCHEMA.md`); update
  the "Frozen forms" wi-type enumeration to note the project-template form
  admits `phase-part-skeleton` (4 options).
- **Retire:** `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md` — its content folds into the
  v11.0 INDEX. Remove the FALSE Convention-Y claims (the `status:cancelled`
  exercise that never happened, §3 D-5; the "work-item-v11.0 → work-item-v11.1
  bump" that never happened, §2.C fact 2; the "v11.0 frozen at 5 subdirs"
  framing, §3 D-3). Remove the D1–D16 decision-log cross-reference block
  (L95–107) — those are superseded-corpus IDs; this doc's §3 is the live log.
- **Encodes:** the informational archive check (Group E) references the INDEX.

**Group C — Relocate / reframe the form snapshot.**
- **From:** `maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml`
- **To:** `maintenance-docs/v11-research/templates-archive/v11.0/forms/work-item.yml` — BUT note the v11.0 cut
  already has a `forms/work-item.yml` (the post-BD-193 project-template-shaped
  3-option form). The correct end-state is a SINGLE v11.0 `forms/work-item.yml`
  reflecting the **current** project-template form (4 options incl.
  `phase-part-skeleton`). Decision per D-9 / §4.4: the v11.0 archive form is the
  client-facing (project-template) snapshot. So the existing v11.0
  `forms/work-item.yml` is UPDATED to the 4-option project-template shape (it
  was a 3-option snapshot pre-H.2), and the duplicate v11.1 snapshot is retired.
  Its markers already read `work-item-v11.0` (correct).
- **Caveat for planner:** this is the one place where "the v11.0 archive form is
  mutable while v11.0 is open" (D-3) is load-bearing — updating the archived
  form is legitimate precisely because v11.0 has not shipped. The informational
  archive check (Group E) byte-compares this to the live project-template form.

**Group D — `validate-pack.py` `check_issue_template_forms()` — de-contaminate comments.**
- **No functional change** — `expected_wi_type_options_per_surface` is already
  correct (§2.C). 
- **Comment edits:** L1086 + L1121–1123 — replace "added at v11.1 (BD-185 H.2)"
  with "added in v11.0 (BD-185)". The `phase-part-skeleton` option is a v11.0
  project-side entry type, not a v11.1 one.
- **Encodes:** this IS an encoding surface for the form's expected state (rule 5).

**Group E — `validate-pack.py` `check_template_archive_v11()` — extend to 6 entry types.**
- **Edit:** the entry-type loop (L1237) currently iterates
  `("bd", "td", "phase-epic", "phase-task", "inbound")` (5). Add `"phase-part"`
  → 6 entry types, so it verifies `v11.0/phase-part-v11.0/SCHEMA.md` exists.
  The function name + docstring (`check_template_archive_v11`, "v11.0") stay —
  it already targets the v11.0 cut. The byte-compare of archived vs live forms
  (L1265) continues; after Group C the client-side comparison reflects the
  4-option form (still INFO-style; pack-side `{bd}` form intentionally differs).
- **Note for planner:** this check is INFORMATIONAL (INFO/FAIL soft style), so a
  missing phase-part subdir would not hard-fail CI — but correctness still
  requires the loop update so the human-readable archive report is complete.

**Group F — `scripts/tests/test-issue-forms.sh` — de-contaminate comments (LEAK, test-encoded).**
- **No functional change** — the assertions (Group 2 per-surface options,
  `wi-part-letter` presence/absence, Part-id Blockers grammar, Group 5 DISJOINT,
  `work-item-v11.0` marker at L190) are already correct (§2.C).
- **Comment edits:** L18–19, L94–95, L138–142, L162–164, L180–183, L264–265 —
  replace "added at v11.1 (BD-185 H.2)" framing with "added in v11.0 (BD-185)".
- **Why this is in-scope (rule 5 + the `enumerate ENCODING surfaces` memory):**
  this test file ENCODES the form's expected state in assertions; its comments
  encode the (wrong) version framing. Per the LEAK-operational-test-encoded
  verdict sub-class, a test comment asserting the wrong version is the same leak
  class as the wrong version in the audited surface. This is exactly the
  asymmetric-coverage gap the memory rule was written to prevent.

**Group G — `v11.0/INDEX.md` "Frozen forms" / D16 footnote (PRESERVE substance; optional reword).**
- **Substance:** the BD-193 carve-out FACT (L31–34) and BD-193's behavior stay
  untouched (§3 D-3).
- **Optional polish (OPEN-Q-1):** the "Frozen forms" heading and the "D16"
  shorthand reference a now-rejected "frozen" framing. The planner MAY reword to
  "Archived forms" and drop the bare "D16" cite (replace with "BD-193 bug-fix
  carve-out"), preserving the carve-out fact. This is cosmetic and does not
  change CI or BD-193's correctness; surface it to the user rather than
  auto-applying.

**Group H — Cross-reference / narrative surfaces (no functional change).**
- `pack-ops/BACKLOG.md` BD-193 Resolved-line + BD-185 entry: narrative
  references to `maintenance-docs/v11-research/templates-archive/v11.1/...` paths describe completed history.
  Once Groups A–C relocate the files, these prose paths are stale. The BD-185
  entry's "Pipeline"/"Position" prose and the BD-193 Resolved line should be
  reconciled by Pack Chat (PM-only surface) when the correction lands — flag,
  don't auto-edit (these are PM-only per the permission rules).
- Workflow artifacts (`IMPLEMENTATION-REPORT-BD-185-*.md`,
  `PACK-REVIEW-BD-185-*.md`, the H.1 NITS report) reference the v11.1 paths.
  These are archive-sweep material (Pattern B) — they sweep to
  `maintenance-docs/archive/v11/` at version ship and need no edit now; they are
  a historical record of what was done, including the error and its correction.

**ENCODING-surface completeness check (rule 5).** Surfaces that encode the
form/archive expected state: the forms themselves (correct — Groups A–C
relocate; no functional change), `validate-pack.py` (Groups D + E), the test
file (Group F), the INDEX docs (Groups B + G), and the CI workflow (no change —
it already wires `test-issue-forms.sh`; verify via Check 42). No script consumes
the `v11.1/` archive path (verified), so relocation has zero code-consumer blast
radius. Manifest note: none of the touched files are under
`project-template/`/`scripts/`/`pack-ops/`/`supporting-docs/` EXCEPT Groups D/E/F
(`scripts/`) — those commits MUST regenerate `test-fixtures/manifest.txt` per the
manifest rule.

---

## §11 — Challenge record

Every prior decision (D1–D16 in the superseded corpus) was re-examined under the
corrected v11.0 premise. **3 rejected, 13 kept-with-re-justification.** Prior-doc
D-IDs below are historical citations only.

### Rejected (3)

- **CR-1 — Reject prior D16's "v11.0 structural shape frozen" clause.** v11.0 is
  unshipped; the archive is mutable (README "append-only after a release tag" +
  translations.yaml "no v11.x shipped yet"). BD-193 already mutated the v11.0
  archive, self-contradicting the freeze. Resolved by this doc's D-3. The
  prior RECONCILIATION graded D16 NEEDS-ADJUSTMENT but patched the symptom (added
  a "Class B carve-out" exception) instead of rejecting the premise — a
  missed-finding the new pass corrects at root.
- **CR-2 — Reject the "v11.1 archive cut" placement** (prior §4.3, §8.5, §8.7).
  No v11.1 pack version exists; BD-185 is v11.0 scope (SC8 + Unblocks). The
  phase-part entry type is the 6th type of the **v11.0** cut (D-2, D-4).
- **CR-3 — Reject the `work-item-v11.0 → work-item-v11.1` template bump** (prior
  §4.3 delta table). The form's additive changes are intra-v11.0 (unshipped);
  there is no prior shipped version to migrate from; translations.yaml is empty.
  The contaminated snapshot's own markers (`work-item-v11.0`) already contradict
  the bump claim. Resolved by D-9 / §4.4.

### Kept, re-justified under v11.0 (13)

- **CR-4 (prior D1) — 4th project-template wi-type option** kept; re-justified
  as a v11.0 project-side entry type under the BD-068 soft cap, NOT a "v11.1 INV-7
  breach." Note: the prior framing assumed the **pack-root** form would also gain
  the option (4→5); that is now WRONG (CR-5) — pack-root is `{bd}`-only.
- **CR-5 (prior D1 pack-root half / RECONCILIATION §4.2) — pack-root form
  unchanged at `{bd}`.** The superseded RECONCILIATION (§4.2 L601, L624) treated
  pack-root as `{bd, td, phase-epic-skeleton, phase-task-skeleton}` (4 options)
  and prescribed extending it to 5. **Stale + wrong:** BD-194/commit `b4906d1`
  made pack-root `{bd}`-only under the deliverable-only rule (verified §2.C).
  Parts are project-side; the pack-root form gets NO Part affordances. This is a
  missed-finding (the reconciliation was not re-validated against the
  post-BD-194 reality). Resolved by D-9.
- **CR-6 (prior D2/D3/D4) — Part collapse rejected; empty Parts forbidden;
  mid-life re-parenting forbidden** kept verbatim (FIXED §2.A); these are
  user-approved lifecycle invariants.
- **CR-7 (prior D6) — primary-source-verify-at-implementation** kept and
  sharpened into RG-1 + RG-2 (§7) as explicit EXTERNAL dependencies.
- **CR-8 (prior D7) — ordering SSOT on the phase entity; `_order.md` a view**
  kept (D-7, §5.4). The prior "v11.1+ groupings forward-pointer" prose is
  trimmed to a neutral note (groupings are BD-186/BD-189, a separate feature).
- **CR-9 (prior D8) — execution-note default-to-phase-number + structured
  warning** kept (§6.3).
- **CR-10 (prior D9) — Forgejo/Gitea / `provider_sub_issue_reprioritize`
  scope** kept as a **Reserved-backend** matter (BD-185 Out-of-scope names
  non-github backends "reserved"). Re-framed: this is a backend-coverage axis,
  NOT the phase-parts version error. The abstract op is designed in v11.0
  (§5.2, §7); concrete non-GitHub backing is Reserved by the BD entry itself,
  which is a legitimate, user-sanctioned scope line (distinct from rule 12,
  which forbids deferring phase-parts to v11.1).
- **CR-11 (prior D11) — dedicated `tracker-phase-part.sh` library** kept (D-11);
  filename verified repo-unique (rule 13).
- **CR-12 (prior D13) — Issue Fields name-collision fallback** kept (§5.1).
- **CR-13 (prior D14) — mid-dev phase appends to END of fallback order** kept
  (§5.2; matches GH default sub-issue append).
- **CR-14 (prior D15) — Task letter-suffix rejected; `Task-M` integer-only**
  kept (FIXED grammar §1 prohibited forms; matches BD-185 Out-of-scope
  "letter-suffix phase forms rejected").
- **CR-15 (prior D5) — phase-task `cancelled` state** — see CR-4 in §3 D-5:
  the prior claim that BD-185 adds `cancelled` is FICTIONAL (the SCHEMA never
  got it; verified). NOT kept as a BD-185 change; phase-task taxonomy is
  untouched.
- **CR-16 (prior D12) — lazy `pack-id-v2` marker backfill** kept as a
  reverse-emit detail (§6.4) where dual markers round-trip.

### Gaps / missed findings in the prior architecture (beyond the v11.1 error)

1. **The `status:cancelled` Convention-Y claim is fictional** (§3 D-5; v11.1/INDEX
   L47–49 asserts an exercise that does not exist in `phase-task-v11.0/SCHEMA.md`).
   Neither prior doc caught it.
2. **The RECONCILIATION's pack-root form premise is stale** (CR-5): it predates
   BD-194's `{bd}`-only cleanup and would have re-introduced project-side wi-type
   options to a pack-self-management surface — a deliverable-only-rule regression.
3. **The prior passes did not enumerate the test-encoded version framing**
   (Group F): `test-issue-forms.sh` and `validate-pack.py` comments carry the
   "v11.1 (BD-185 H.2)" framing. This is the exact asymmetric-coverage /
   LEAK-test-encoded gap the pack memory rule warns about; correcting it is part
   of the lock-step update.
4. **The contaminated snapshot is internally incoherent** (§2.C fact 2): a file
   under `v11.1/` carrying `work-item-v11.0` markers while the INDEX claims a
   v11.1 bump. The prior reconciliation treated the snapshot as a pending
   decision (its three options a/b/c) without flagging the marker contradiction.

---

## §12 — Handoff notes for planner

- This is design-only. The planner sequences the §10 corrections into commits
  and converts §4–§7 into ordered implementation steps.
- §10 corrections are version-framing relocations + comment de-contamination;
  the functional form/validator/test substance is already correct and must not
  regress (re-verify DISJOINT + `work-item-v11.0` markers post-edit).
- RG-1 + RG-2 (§7) are EXTERNAL primary-source gaps the coder must close before
  committing GH call shapes; they bound the verification step, not the design.
- PM-only surfaces (BACKLOG BD-185/BD-193 prose, Group H) are reconciled by Pack
  Chat, not the coder. Workflow artifacts (Group H) sweep at version ship.
- OPEN-Q-1 (Group G reword) is cosmetic — surface to the user, do not
  auto-apply.
- Commits touching `scripts/` (Groups D/E/F) must regenerate
  `test-fixtures/manifest.txt` in the same commit (manifest rule).
