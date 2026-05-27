# ARCHITECTURE-BD-185-RECONCILIATION.md — Post-Code-Red-2 reconciliation pass

**Authored by:** pack-architect (read-only reconciliation pass).
**Date:** 2026-05-27 (US/Pacific).
**Branch:** v11-dev.
**Working-tree HEAD at reconciliation start + end:** `2648bb2`
(`docs: v11 — BD-185 open (Batch 19d phase parts + ordering, pack-only)`
after the BD-194 follow-up + H.1 NIT cleanup chain completed).
**Pipeline position:** Original architect (2026-05-25 D1-D14 lock,
2026-05-26 D15 + D16 lock) → original planner (2026-05-26 POQ-1..7 lock)
→ H.1 coder + review committed (`8b4c607` + `2648bb2`) → BD-193 +
BD-194 closed (11 commits; new architectural baseline) → **THIS
RECONCILIATION (re-validate D1-D16 + H.1-H.16 against new baseline)**
→ user review → planner addendum → H.2 coder spawn.

---

## §1 — Scope

### §1.1 — What this document is

This is a re-validation of the BD-185 architectural design
(`ARCHITECTURE-BD-185.md`, 1233 lines, 16 USER-LOCKED decisions D1-D16)
and the 16-commit plan (`PLAN-BD-185.md`, 1424 lines, H.1-H.16)
against the post-Code-Red-2 architectural baseline established by
BD-193 + BD-194 (11 commits between H.1-NIT and this pass).

Per the user-locked Pack memory rule
`feedback_preliminary_triage_architect_challenge` (saved 2026-05-26):

> "All triage decisions are PRELIMINARY; architects MUST challenge
> each at design; user retains final authority; tiered bar: PS-internal
> LOW (architect explores freely) / boundary-with-existing-pack HIGH
> (must investigate thoroughly out-of-scope changes); artifacts carry
> explicit 'preliminary; subject to architect challenge' disclaimer."

The 16 D-N decisions in `ARCHITECTURE-BD-185.md` §1.4 and the 7 POQ
resolutions in `PLAN-BD-185.md` §6 are USER-LOCKED at their original
authoring dates BUT predate BD-193/194. This reconciliation challenges
each decision against the new baseline and assigns one of four
verdicts (defined in §2.3 below).

### §1.2 — What changed since the original architect + planner passes

Between original BD-185 architect/planner pass (2026-05-25/26) and
this reconciliation (2026-05-27), the following architectural
baseline shifts landed:

1. **BD-193 F1 (INDEX segregation)** — `templates-archive/v11.0/INDEX.md`
   and `templates-archive/v11.1/INDEX.md` now segregate entry types
   into "Client-applicable" and "Pack-internal (informational only;
   NOT applicable to client projects)" sub-sections.
2. **BD-193 F1.c (bd-v11.0 PACK-INTERNAL header)** — the bd-v11.0
   SCHEMA acquired a `**SCOPE: PACK-INTERNAL.**` header explicitly
   declaring the file is not a client-project concept.
3. **BD-193 F2.a (phase-task-v11.0 SCHEMA dep grammar)** — BD-NNN
   admission removed from dependencies grammar (L79, L91); now admits
   `phase-N`, `phase-N.M`, `TD-NNN` only.
4. **BD-193 F2.b (phase-part-v11.1 SCHEMA grammar)** — applied at H.1
   landing time per current HEAD: phase-part prerequisites grammar
   admits `phase-N`, `Phase-N.Part-x`, `Phase-N.Task-M`,
   `Phase-N.Part-x.Task-M`, `TD-NNN` (BD-NNN explicitly excluded).
5. **BD-193 F2.c (v11.0 archive form bug-fix carve-out)** —
   `templates-archive/v11.0/forms/work-item.yml` had `bd` option
   removed as a D16 Convention Y bug-fix carve-out (this is the
   v11.0 archive snapshot — not the live pack-root form).
6. **BD-193 F2.d (live project-template form divergence)** — the
   project-template-side `.github/ISSUE_TEMPLATE/work-item.yml`
   removed the `bd` wi-type option; pack-root retains 4 options
   (`bd`, `td`, `phase-epic-skeleton`, `phase-task-skeleton`);
   project-template has 3 options (`td`, `phase-epic-skeleton`,
   `phase-task-skeleton`). The two forms also diverge in title
   default (`BD-NNN:` vs `TD-NNN:`), markdown intro audience, and
   L18 project-side boundary-defense statement.
7. **BD-193 F2.e (METHODOLOGY parser regex)** —
   `supporting-docs/METHODOLOGY.md` parser regex now
   `^\s*-\s+(phase-\d+(\.\d+)?\|TD-\d+)(\s+(.*))?$` (BD-NNN dropped
   from grammar).
8. **BD-193 F3 (project backlog `_intro.md`)** —
   `project-template/docs/project/backlog/_intro.md` L34 cross-
   references list no longer includes `BD-NNN`.
9. **BD-193 F4/F5 (init-project.sh S11)** — the client install
   source for `HELP-FRAGMENT-TRACKER.md` is now
   `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` (the
   project-side authority); the pack-ops/ fallback was removed.
10. **BD-193 collateral (`check_issue_template_forms`)** — the CI
    check is now PER-SURFACE with a `expected_wi_type_options_per_surface`
    dict; `test-issue-forms.sh` gained surface-aware `check_workitem`.
11. **BD-194 (Check 24 retirement)** — `check_help_fragment_tracker_byte_identity`
    was DELETED. The pack-side and project-side HELP-FRAGMENT-TRACKER.md
    files are now declared SEPARATE artifacts with SEPARATE audiences.
    Pack-side existence is now Check 23 fail-loud; project-side
    existence is Check 41 (`_CLIENT_INSTALLED_FILES`); cross-surface
    byte-identity is NEITHER asserted NOR required.
12. **BD-194 (Check 22 per-surface fix)** — `check_help_fragment_freshness`
    now selects the per-surface tracker fragment via the surfaces
    dict; no cross-surface concatenation.
13. **BD-194 (test file install-source assertions)** —
    `test-init-project.sh` test 3.3 and `test-migrate-v10-to-v11.sh`
    test 2.5 assert the client install matches the project-template-side
    source (not the pack-side canonical).
14. **BD-194 (pack-root trinity)** — `CLAUDE.md` / `AGENTS.md` /
    `GEMINI.md` Filename-uniqueness-heuristic exemption-class list
    dropped the "byte-identical mirrors per CI Check 24" clause.
15. **Three USER-LOCKED pack memory rules (2026-05-26):**
    - `feedback_bd_pack_only_operational_rule` — client-facing
      content MUST NOT operationally treat BDs (dependency grammars,
      peer-tables, form admissions, parser regexes); MAY reference
      in MIGRATION/glossary/explanatory contexts with clear pack-only
      disclosure; 3-layer enforcement (CI + file allowlist + manual
      review).
    - `feedback_pack_project_separation_of_concerns` — pack-side and
      project-side versions of any doc/file are SEPARATE artifacts
      with SEPARATE audiences; pack version NEVER a fallback for
      project version (or vice versa); byte-identity is COINCIDENCE
      not design rationale.
    - `feedback_client_facing_token_economy` — client-facing docs
      (METHODOLOGY / SKILLS / agents / prompts) get RAG-indexed;
      pack-only references waste tokens; default REMOVE pack-only
      references from client-facing docs unless client-necessary
      (3-question necessity test); applies to BD-NNN, architect
      docs, pack-history.
16. **Pack memory rule extensions (2026-05-25/26):**
    - `feedback_preliminary_triage_architect_challenge` — all
      preliminary triage decisions MUST be challenged at design;
      tiered bar by surface boundary risk.
    - `feedback_pattern_matching_out_of_context_antipattern` —
      adopting structural pattern A for use case B without
      verifying property-fit is poor design.

### §1.3 — Scope (what this document is NOT)

This reconciliation:

- Does NOT modify `ARCHITECTURE-BD-185.md` or `PLAN-BD-185.md` (the
  original docs remain as authored).
- Does NOT re-litigate the BD-193 / BD-194 architectural decisions
  (those are the new baseline).
- Does NOT re-litigate the USER-LOCKED pack memory rules.
- Does NOT propose implementation work (architect, not coder).
- Does NOT produce code edits, file diffs, or commit-level mechanics
  (those land in the planner addendum the user authorizes after
  reviewing this document).

### §1.4 — Output

This document is the SOLE output of this reconciliation pass.
Downstream: user reviews → planner produces PLAN-BD-185 addendum →
H.2 coder spawns.

---

## §2 — Methodology

### §2.1 — Tiered bar per pack memory

Per `feedback_preliminary_triage_architect_challenge`:

- **LOW bar — PS-internal style decisions.** Naming choices,
  internal structural decisions that don't cross the pack/project
  boundary. Architect explores freely; default trust the prior
  decision when no new evidence contradicts.
- **HIGH bar — Boundary-with-existing-pack decisions.** Pack/project
  separation contracts, byte-identity assertions, per-surface gates,
  validate-pack checks, client-facing content shape. Architect MUST
  investigate thoroughly, cite BD-193/194 evidence, and present the
  divergence concretely.

This document applies the HIGH bar to anything that touches the
pack/project boundary; the LOW bar to anything purely internal to
BD-185's own surfaces.

### §2.2 — Challenge protocol

For each D-N decision and each H-N plan step:

1. State the decision verbatim (cite original §1.4 row or §5 H.X).
2. Read against post-BD-193/194 baseline — identify changes since
   original authoring that affect the decision.
3. Assign verdict per §2.3.
4. If verdict is NEEDS-ADJUSTMENT or WRONG-AND-NEEDS-REPLACEMENT,
   propose the adjustment with concrete evidence.
5. If a NEW POQ surfaces, cite it.

### §2.3 — Verdict categories

| Verdict | Definition |
|---|---|
| **STILL-VALID** | Decision aligns with new baseline; concrete evidence cited (e.g., independent of BD-193/194 surface contracts; rule still applies as authored). |
| **NEEDS-ADJUSTMENT** | Decision largely valid but requires specific drift correction; propose adjustment with concrete text. |
| **WRONG-AND-NEEDS-REPLACEMENT** | Decision fundamentally conflicts with new baseline; propose replacement design. |
| **NEW-POQ-SURFACED** | Architectural question not anticipated in original; raise as POQ for user resolution (do NOT auto-decide). |

### §2.4 — Authoritative inputs read

This document is informed by full reads of:

1. `ARCHITECTURE-BD-185.md` (1233 lines)
2. `PLAN-BD-185.md` (1424 lines)
3. `IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.1.md`
4. `ARCHITECTURE-BD-194.md` (1179 lines)
5. `IMPLEMENTATION-REPORT-BD-194.md` (980 lines)
6. `IMPLEMENTATION-REPORT-BD-194-STALE-REFS.md`
7. `IMPLEMENTATION-REPORT-BD-194-FOLLOWUP.md`
8. `PACK-REVIEW-BD-194.md` (selective re Check 22/23/24 surfaces)
9. `AUDIT-DISPOSITION-BD-TD-PATH.md` (BD-193 Phase 2)
10. `IMPLEMENTATION-REPORT-BD-193.md` (BD-193 Phase 3)
11. `PACK-REVIEW-BD-193-PHASE-4.md` (selective re Check 24 latent
    concern, M-8 finding)
12. `pack-ops/BACKLOG.md` BD-185 entry (lines 1746-1793)
13. Working-tree HEAD `2648bb2`: `.github/ISSUE_TEMPLATE/work-item.yml`
    (pack-root); `project-template/.github/ISSUE_TEMPLATE/work-item.yml`;
    `pack-ops/HELP-FRAGMENT-TRACKER.md`; `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`;
    `scripts/validate-pack.py` (Check 22/23/24/41 + `check_issue_template_forms`);
    `templates-archive/v11.0/INDEX.md`; `templates-archive/v11.1/INDEX.md`;
    `templates-archive/v11.0/phase-task-v11.0/SCHEMA.md`;
    `templates-archive/v11.1/phase-part-v11.1/SCHEMA.md`;
    `CLAUDE.md` (pack root, Pack-memory section).
14. The full `## Pack memory` section of `CLAUDE.md` (current rules at
    HEAD `2648bb2`).

---

## §3 — Decision-by-decision verdict (D1-D16)

Each D-N row receives a verdict plus evidence + adjustment-text if
needed. Decisions are LOCKED in the original sense (user authorized)
but PRELIMINARY for this reconciliation per the tiered-bar rule.

### §3.1 — D1 (INV-7 5th `wi-type` option ACCEPTED)

**Decision:** Accept the BD-068 4-option soft-cap breach. Add
`phase-part-skeleton` as 5th `wi-type` option (in addition to
`bd`, `td`, `phase-epic-skeleton`, `phase-task-skeleton`). Defense
documented in `ARCHITECTURE-BD-185.md` §4.3.

**Verdict:** **NEEDS-ADJUSTMENT.**

**Evidence.** D1 is per-surface valid at the pack-root surface (still
4→5 options) but WRONG at the project-template surface. Post-BD-193
F2.d, the project-template form is 3-option (`td`,
`phase-epic-skeleton`, `phase-task-skeleton`); adding
`phase-part-skeleton` makes it 4-option (not 5). The original D1
defense ("the soft cap's mobile-scanability concern applies to
common-path options, not to fallback options") still holds for
project-template (3→4 is BELOW the soft cap; defense not even
required). At pack-root, the defense applies (4→5).

The BD-068 INV-7 soft cap defense is therefore TWO-SIDED:
- Pack-root: 4→5 options (5th option added; soft cap breached).
- Project-template: 3→4 options (4th option added; soft cap NOT
  breached).

**Adjustment.** Reframe D1's defense per-surface. The defense in
`ARCHITECTURE-BD-185.md` §4.3 needs a paragraph addendum naming the
per-surface option counts post-BD-193. Also: the original §4.3 form
addition table assumed byte-identical pack-side + project-side forms;
that assumption is now FALSE. See D-NEW-1 (POQ-NEW-1) for the
divergence-aware form-edit shape.

**Cross-reference.** §3.NEW-1 below + §4.2 (H.2 verdict).

### §3.2 — D2 (Part collapse REJECTED as anti-pattern)

**Decision:** Part collapse rejected as anti-pattern; no
`pack phase collapse` verb in any release. Once split, the split is
permanent.

**Verdict:** **STILL-VALID.**

**Evidence.** D2 is a PS-internal style decision about pack verbs.
No BD-193/194 baseline change touches collapse semantics, verb
introduction, or split permanence. The rule is independent of
pack/project separation contracts. The architecturally consistent
behavior (no collapse) is reaffirmed by the new memory rule
`feedback_deferral_is_scope_creep` ("Defending defer needs SIZE /
BLOCKED / LOGICAL FIT") — collapse would be invented work, not
defendable as size/blocked/fit-aligned.

**Cross-reference.** §4.9 (H.9 verdict — `pack phase split` should
NOT introduce a `pack phase collapse` peer).

### §3.3 — D3 (Empty Parts FORBIDDEN at creation)

**Decision:** Every Part must have ≥1 task at creation. The
`pack phase split` verb validates this and rejects splits with
empty Parts.

**Verdict:** **STILL-VALID.**

**Evidence.** D3 is a PS-internal validity constraint. The new
baseline does not affect Part creation semantics. The CI check
introduced for D3 (`check_part_has_member_task` — H.10 new check)
remains a tracker-side check; the rule's per-surface independence
holds.

**Cross-reference.** §4.9 (H.9 verb behavior) + §4.10 (H.10 new
check landing).

### §3.4 — D4 (Mid-life re-parenting FORBIDDEN; supersede-only)

**Decision:** Once Parts exist, tasks DO NOT move between Parts.
Work conceptually needing to move uses `pack task supersede`. No
`pack task reparent` verb exists.

**Verdict:** **STILL-VALID.**

**Evidence.** D4 is PS-internal. No BD-193/194 baseline change
affects task supersession semantics. The supersede verb (§4.8 of
the original architect doc) carries the same shape post-BD-193/194.

**Cross-reference.** §4.9 (H.9 verb behavior).

### §3.5 — D5 (`cancelled` state ADDED to task taxonomy)

**Decision:** 7-state phase-task taxonomy gains `cancelled` (❌
marker; `status:cancelled`; `closed + state_reason: not_planned`).
Per D16 Convention Y, this is an intra-file additive extension to
`templates-archive/v11.0/phase-task-v11.0/SCHEMA.md` §3 (Label
family).

**Verdict:** **STILL-VALID.**

**Evidence.** D5 is PS-internal at the v11.0 archive surface
(Convention Y permits intra-file additive extension). The new
client-facing token-economy rule
(`feedback_client_facing_token_economy`) does NOT prohibit adding
new state values; it prohibits BD-NNN/architect-doc references in
client-facing content. The `cancelled` state addition is a label
namespace addition (not a BD reference), and the SCHEMA documents
the semantic distinction without architect-doc cites.

Note: BD-185 H.13 lands this v11.0 SCHEMA extension. The HEAD state
shows the phase-task-v11.0 SCHEMA does NOT yet carry `cancelled` (no
match in grep). H.13 still has work to do — this is a TRACKING note,
not an issue with D5 itself.

**Cross-reference.** §4.13 (H.13 verdict).

### §3.6 — D6 (Primary-source verification VERIFY-AT-IMPLEMENTATION-TIME)

**Decision:** Planner / coder verifies GitHub Issue Fields GraphQL
API names at implementation-time. No extra researcher pass.

**Verdict:** **STILL-VALID.**

**Evidence.** D6 is a process decision orthogonal to BD-193/194
content scope. The verify-at-implementation-time discipline is
codified by the post-BD-169 PREFLIGHT pattern; H.4 coder will perform
the verification at H.4 commit time. No new memory rule contradicts.

### §3.7 — D7 (`_order.md` separate per-entry file + SSOT/view contract)

**Decision:** `_order.md` is a NEW per-entry supporting file
(parallel to `_toc.md`); regenerated view of the execution-order
SSOT; never source of truth; cross-referenced from BD-189 groupings
forward-pointer.

**Verdict:** **STILL-VALID.**

**Evidence.** D7 is a PS-internal per-entry-tree design decision.
The new pack memory `feedback_pack_project_separation_of_concerns`
applies to PACK-vs-PROJECT mirrors; `_order.md` is purely
project-side (lives in `project-template/docs/project/implementation-plan/`)
and has no pack-side analog. No separation conflict.

**Cross-reference.** §4.7 (H.7 verdict — D7 mechanically implemented
via NEW `_order-generate.sh` per POQ-5).

### §3.8 — D8 (Execution-note prose default to phase_number + structured warning)

**Decision:** Default execution-order = phase_number; emit structured
context-rich warning when an `> **Execution note**:` paragraph is
detected; user resolves manually post-migration via 3 paths
(accept default / reorder / mark historical).

**Verdict:** **STILL-VALID.**

**Evidence.** D8 is PS-internal (migrator behavior, user prompts).
No BD-193/194 baseline change affects this. The 7-field warning
template still works.

**Cross-reference.** §4.8 (H.8 verdict).

### §3.9 — D9 (Forgejo/Gitea support DESIGNED for v11.1+; DEFER `provider_sub_issue_reprioritize`)

**Decision:** Design Forgejo/Gitea sub-issue-reprioritize fallback
as v11.1+ forward-pointer; v11.0 ships dispatcher stub for the new
op. v11.0 → 20 ops; v11.1+ → 21 ops.

**Verdict:** **STILL-VALID.**

**Evidence.** D9 is PS-internal (TrackerProvider abstraction
extension). The new tracker-portability memory rule
(`feedback_tracker_portability`, saved 2026-05-25) explicitly
endorses abstractable design for non-GH backends, which D9
satisfies. The BD-193/194 baseline does not touch the
TrackerProvider abstraction.

**Cross-reference.** §4.4 (H.4 verdict).

### §3.10 — D10 (gh CLI version-pin via `gh api graphql` routing)

**Decision:** Use `gh api graphql` for Issue Fields ops; avoids
`gh` CLI version-pin via the subcommand surface.

**Verdict:** **STILL-VALID.**

**Evidence.** D10 is PS-internal. No BD-193/194 baseline change.
The verify-at-implementation-time rule (D6) covers any future
GraphQL subcommand drift.

### §3.11 — D11 (NEW `tracker-phase-part.sh` library)

**Decision:** NEW library `scripts/lib/tracker-phase-part.sh`
parallel to `tracker-phase-task.sh`; carries parser/emitter + state
taxonomy + lib invariants.

**Verdict:** **STILL-VALID.**

**Evidence.** D11 is PS-internal (script-naming + library design).
The filename uniqueness check at H.0 baseline confirmed no collision.
No BD-193/194 baseline change affects this.

**Cross-reference.** §4.5 (H.5 verdict).

### §3.12 — D12 (LAZY `pack-id-v2` marker backfill)

**Decision:** Only Part-expanded tasks gain v2 marker. Pre-expansion
tasks remain v1-only.

**Verdict:** **STILL-VALID.**

**Evidence.** D12 is PS-internal (body-marker lifecycle). No
BD-193/194 baseline change. The pack/project-separation memory rule
applies only to pack-side-vs-project-side artifacts; v1/v2 markers
are project-side content evolution.

### §3.13 — D13 (Issue Fields name-collision: capability-detection + `Pack Execution Order` fallback)

**Decision:** Capability-detect at tracker init; if `Execution Order`
field already exists at the org, use `Pack Execution Order` fallback
name. Persist field-name choice to `tracker.toml`
`[execution_order] field_name = "..."`.

**Verdict:** **STILL-VALID.**

**Evidence.** D13 is PS-internal (tracker-init capability detection).
No BD-193/194 baseline change.

**Cross-reference.** §4.4 (H.4 verdict — provider capability flags
extension).

### §3.14 — D14 (Mid-development phase appends to END of sub-issue priority order)

**Decision:** New phase added mid-development appends to END of
sub-issue priority order under phase-order-root (GH default
behavior). User reorders via `pack tracker phase reorder` post-creation.

**Verdict:** **STILL-VALID.**

**Evidence.** D14 is PS-internal (sub-issue priority semantics).
No BD-193/194 baseline change.

### §3.15 — D15 (Task letter-suffix REJECTED grammar-wide; `Task-M` integer-only)

**Decision:** No letter suffix on Task. New tasks always get next
integer. Task number ≠ execution order. Cross-refs strict.

**Verdict:** **STILL-VALID.**

**Evidence.** D15 is PS-internal grammar design. No BD-193/194
baseline change.

### §3.16 — D16 (Convention Y: v11.0 archive structural shape frozen + intra-file additive extensions allowed)

**Decision:** v11.0 archive directory structure frozen at 5 entry-type
subdirs; intra-file content MAY evolve via backward-compatible
additive extensions.

**Verdict:** **NEEDS-ADJUSTMENT (boundary expansion already EXERCISED).**

**Evidence.** D16 was authored as "structural-shape-frozen-plus-additive-content."
BD-193 F2.c then EXERCISED Convention Y as a "bug-fix carve-out" by
REMOVING the `bd` option from `templates-archive/v11.0/forms/work-item.yml`.
That's not strictly "backward-compatible additive extension" — it's
a bug-fix carve-out that REMOVES content. The v11.0 INDEX.md now
explicitly cites this carve-out at L31:

> "The original v11.0 shipped form admitted a 4th `bd` option; D16
> removed it from the archive as a bug-fix carve-out."

D16 therefore has TWO recognized exercise classes:
- Class A (additive extension) — phase-task-v11.0 SCHEMA gains
  `cancelled` state; INDEX gains forward-reference footnote.
- Class B (bug-fix carve-out) — v11.0 forms `bd` option removal
  (BD-193 F2.c).

**Adjustment.** Original D16 was authored for Class A only. BD-193
expanded it operationally to Class A + B. The architect doc §10.1 +
§14.1 should acknowledge the carve-out class. PLAN-BD-185 H.13 +
H.14 reference "intra-file additive extension permitted under
v11.0 structural-shape-frozen contract" — that wording is now
incomplete (omits Class B).

This adjustment does NOT change any H.X commit's behavior — H.13
adds `cancelled` (Class A); H.14 adds INDEX footnote (Class A). It
clarifies the rule's actual operational scope for future readers.

**Cross-reference.** §4.13 (H.13 verdict) + §4.14 (H.14 verdict).

---

## §4 — Per-commit plan verdict (H.0-H.16)

Each H.X step from `PLAN-BD-185.md` §5 receives a verdict plus
evidence + adjustment-text if needed. Verdicts apply the same
methodology as §3.

### §4.0 — H.0 — Baseline verification

**Plan:** Pre-flight checks. No commit.

**Verdict:** **NEEDS-ADJUSTMENT (HEAD references stale).**

**Evidence.** H.0 cites HEAD `062cb8f` as the planner-pass HEAD. The
current HEAD is `2648bb2`; 11 commits have landed since. H.0 needs
to refresh the HEAD reference and verify post-BD-193/194 baseline
state (no longer just "BD-185 H.1 complete"; the BD-193 + BD-194
landings are also baseline).

**Adjustment.** Re-execute H.0 against HEAD `2648bb2`:

1. `git rev-parse HEAD` = `2648bb2` (or later descendant).
2. `git status` — working tree clean except plan addendum + this
   reconciliation report.
3. `python3 scripts/validate-pack.py` — PASS at 40 invoked checks
   (NOT 43; Check 24 was retired).
4. BD-185 status: `grep -A2 "BD-185" pack-ops/BACKLOG.md | head -5`
   confirms `Status: Open`.
5. `find . -name "tracker-phase-part.sh" -not -path "./.git/*"` —
   STILL ZERO matches (architect's filename uniqueness assumption
   for H.5 preserved).
6. `find . -name "pack-phase.sh" -not -path "./.git/*"` — STILL
   ZERO matches.
7. `find . -name "_order.md" -not -path "./.git/*"` — STILL ZERO
   matches.
8. `find . -name "_order-generate.sh" -not -path "./.git/*"` —
   STILL ZERO matches (POQ-5 resolution introduces this script at
   H.7).
9. Verify v11.1 archive layout has SCHEMA + INDEX only (no
   `forms/work-item.yml` yet) — confirmed at HEAD.

### §4.1 — H.1 — v11.1 templates-archive cut

**Plan:** Already committed at SHAs `8b4c607` (H.1 main) + `2648bb2`
(H.1 NIT cleanup). No outstanding work.

**Verdict:** **STILL-VALID (committed; no changes needed).**

**Evidence.** H.1 landed before BD-193/194 (HEAD `0912a7e` at H.1
start; `2648bb2` at NIT cleanup; latter is the current HEAD). The
H.1 IMPL-REPORT confirms phase-part-v11.1 SCHEMA + v11.1/INDEX.md
exist with no BD-NNN dependency-grammar admissions and the
client/pack-internal segregation pattern matches the BD-193 F1 shape.

The H.1 NIT cleanup commit landed the `cancelled` state CROSS-REFERENCE
(as a Part-state-taxonomy exclusion note); the underlying v11.0
SCHEMA extension is still pending in H.13.

### §4.2 — H.2 — Form-family extension

**Plan:** EXTEND pack-root + project-template work-item.yml byte-
identically with 5th `wi-type` option `phase-part-skeleton` +
`wi-part-letter` input + Blockers/Unblocks/Dependencies description
updates admitting Part-id forms. CREATE
`templates-archive/v11.1/forms/work-item.yml` byte-identical to
the live form.

Verification command per plan:

```bash
diff .github/ISSUE_TEMPLATE/work-item.yml project-template/.github/ISSUE_TEMPLATE/work-item.yml
# Expected: empty (byte-identical).
```

**Verdict:** **WRONG-AND-NEEDS-REPLACEMENT.**

**Evidence.** Pack Chat surfaced this in the spawn prompt; the
reconciliation confirms it. Post-BD-193 F2.d the two forms are
deliberately DIVERGENT:

| Property | Pack-root current | Project-template current |
|---|---|---|
| `name` | `Pack work item (BD / TD / phase-epic / phase-task)` | `Project work item (TD / phase-epic / phase-task)` |
| `description` | "Pack-development backlog item (BD-NNN), project technical-debt item (TD-NNN), phase epic skeleton, or phase task skeleton." | "Project technical-debt item (TD-NNN), phase epic skeleton, or phase task skeleton." |
| `title` default | `BD-NNN: <short title>` | `TD-NNN: <short title>` |
| Markdown intro audience | "pack-managed work" | "project-managed work" |
| Markdown chat reference | "Pack Chat at migration time" | "PM Chat at migration time" |
| Markdown L18 (project only) | (absent) | "Pack-development items (BD-NNN) belong in the pack repo, not in this project." (boundary defense) |
| `wi-type` options | `{bd, td, phase-epic-skeleton, phase-task-skeleton}` | `{td, phase-epic-skeleton, phase-task-skeleton}` |
| `wi-type` description | "Pick BD for pack-development items; TD for project items; ..." | "Pick TD for project items; ..." |
| `wi-kind` label | `Kind (BD / TD only)` | `Kind (TD only)` |
| `wi-kind` description | "Required for Type=bd or Type=td." | "Required for Type=td." |
| `wi-status` description | "Defaults to Open for BD/TD." | "Defaults to Open for TD." |
| `Description` label / desc | mentions BD/phase contexts | "For TD/phase-epic-skeleton." |
| Blockers / Dependencies grammar | admits ... | admits ... (BD-NNN removed) |

H.2's "byte-identical" assertion would either:
(a) Re-introduce `bd` to project-template (regresses BD-193 F2.d) —
WRONG.
(b) Drop `bd` from pack-root (loses pack-developer audience tool) —
WRONG.
(c) Force every other content divergence back to identity — WRONG
across 8+ properties.

H.2 needs to be redesigned as a PER-SURFACE form extension with
audience-specific edits.

**Adjustment.** Reframe H.2 as PER-SURFACE form-family extension.
The mechanical edits divide as follows:

**Pack-root `.github/ISSUE_TEMPLATE/work-item.yml`:**
- `wi-type` options: `{bd, td, phase-epic-skeleton, phase-task-skeleton}` → `{bd, td, phase-epic-skeleton, phase-task-skeleton, phase-part-skeleton}` (4 → 5; D1 INV-7 breach defended at pack-root surface).
- `wi-part-letter` input: ADD (conditional on `phase-part-skeleton`).
- `wi-type` description: extend to mention `phase-part-skeleton`.
- Blockers / Unblocks / Dependencies descriptions: admit `Phase-N.Part-x` and `Phase-N.Part-x.Task-M` forms.
- `name` / `description` / `title` / markdown intro: UNCHANGED (pack-developer audience).

**Project-template `.github/ISSUE_TEMPLATE/work-item.yml`:**
- `wi-type` options: `{td, phase-epic-skeleton, phase-task-skeleton}` → `{td, phase-epic-skeleton, phase-task-skeleton, phase-part-skeleton}` (3 → 4; under BD-068 soft cap; no defense required).
- `wi-part-letter` input: ADD (conditional on `phase-part-skeleton`).
- `wi-type` description: extend to mention `phase-part-skeleton`.
- Blockers / Unblocks / Dependencies descriptions: admit `Phase-N.Part-x` and `Phase-N.Part-x.Task-M` forms. **Must NOT re-introduce `BD-NNN`** (would regress BD-193 F2 dep-grammar cleanup).
- `name` / `description` / `title` / markdown intro / L18 boundary defense: UNCHANGED.

**`templates-archive/v11.1/forms/work-item.yml`:**

Per the current `templates-archive/v11.1/INDEX.md` "Forms file"
section (visible at HEAD `2648bb2`), the archive snapshot needs a
DECISION: when populated, the snapshot must reflect the post-BD-193
pack/project divergence. Three options:

| Option | Mechanic | Pros | Cons |
|---|---|---|---|
| (a) Snapshot pack-root only | Single file at `v11.1/forms/work-item.yml` byte-identical to pack-root | Smallest archive footprint | Loses the project-template snapshot; partial v11.1 archive |
| (b) Snapshot both | Two files: `v11.1/forms/work-item-pack.yml` + `v11.1/forms/work-item-project.yml` | Complete v11.1 snapshot of both surfaces | Splits a single conceptual form file into two; needs documentation in INDEX |
| (c) Snapshot project-template only | Single file at `v11.1/forms/work-item.yml` byte-identical to project-template | Aligns with client-facing-archive framing | Loses the pack-root snapshot (BD-068 form-family research value lost) |

The v11.0 archive shipped exactly ONE `forms/work-item.yml` (the
F2.c carve-out variant — 3 options, no `bd`). That is partial:
the v11.0 archive does NOT carry the pack-root variant either. So
v11.0 set the precedent of "archive captures the client-facing
form."

**Recommendation.** Option (c) for v11.1 archive (client-facing form
only; matches v11.0 archive precedent). Pack-root form is captured
in git history at the live path; archive duplication would be
maintenance burden without clear value. The INDEX.md must explicitly
state which surface the archive snapshots.

This is a NEW POQ — see §5 POQ-NEW-1.

**Plan-text replacement for H.2 §5:**

H.2's `**Files modified**` becomes:

- `.github/ISSUE_TEMPLATE/work-item.yml` (pack-root, EXTEND per
  pack-root edit list above).
- `project-template/.github/ISSUE_TEMPLATE/work-item.yml`
  (project-template, EXTEND per project-template edit list above).
- `maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml`
  (NEW; byte-identical to project-template post-H.2 edits per
  POQ-NEW-1 recommendation; if POQ-NEW-1 resolves to Option a or b
  the file count / content adjusts).

H.2's verification command CHANGES from `diff` of both forms (expected
empty) to TWO independent verifications:
```bash
# Pack-root has 5 wi-type options:
grep -A6 "id: wi-type" .github/ISSUE_TEMPLATE/work-item.yml | grep -c "^[[:space:]]*-" 
# Expected: 5
# Project-template has 4 wi-type options:
grep -A6 "id: wi-type" project-template/.github/ISSUE_TEMPLATE/work-item.yml | grep -c "^[[:space:]]*-"
# Expected: 4
# Project-template still does NOT admit bd:
grep "^[[:space:]]*-[[:space:]]*bd$" project-template/.github/ISSUE_TEMPLATE/work-item.yml
# Expected: NO match
```

The "byte-identical mirror" assertion is RETIRED.

**Cross-reference.** §3.1 (D1 needs-adjustment) + §4.10 (H.10 must
update `expected_wi_type_options_per_surface` per-surface) + §5
POQ-NEW-1.

### §4.3 — H.3 — implementation-plan per-entry tree contract

**Plan:** EXTEND `_rules.md` + `_intro.md` for the implementation-plan
stream. Document body marker quad + H3 Part grammar + execution-order
marker + reorder workflow + supersede workflow + historical marker.

**Verdict:** **STILL-VALID.**

**Evidence.** H.3 is purely project-side (no pack-side analog). The
per-entry tree contract files are not in the `feedback_pack_project_separation_of_concerns`
divergence space. The user-facing token-economy memory rule
(`feedback_client_facing_token_economy`) does apply: H.3 must AVOID
introducing BD-NNN / architect-doc references in client-facing
content. Read of plan text confirms H.3 references the new pack
verbs (`pack phase split`, `pack phase reorder`, `pack task
supersede`), the body marker quad, and the H3 / H4 grammar — no
BD-NNN cites required. The plan-text editor at coder-time should
ensure no BD-NNN / architect-doc refs leak into `_rules.md` or
`_intro.md`.

**Cross-reference.** §4.10 (H.10 Check 43 leak-sweep prevention will
catch any accidental leak).

### §4.4 — H.4 — TrackerProvider abstraction extension

**Plan:** EXTEND `tracker-provider.sh` + `tracker-provider-gh.sh`
with 3 new ops (`_set_field`, `_get_field`, `_sub_issue_reprioritize`);
GH backend implementation; capability flags.

**Verdict:** **STILL-VALID.**

**Evidence.** H.4 is purely script-internal (`scripts/lib/`). No
client-facing surface; no pack/project boundary crossing. The new
memory rules don't touch this surface. The `feedback_tracker_portability`
rule reinforces the abstractable-by-design approach.

### §4.5 — H.5 — NEW `tracker-phase-part.sh` + test file

**Plan:** CREATE `scripts/lib/tracker-phase-part.sh` (parser/emitter
+ state taxonomy + lib invariants) parallel to `tracker-phase-task.sh`;
CREATE `scripts/tests/test-tracker-phase-part.sh`.

**Verdict:** **STILL-VALID.**

**Evidence.** H.5 is purely script-internal. Filename uniqueness
preserved (`find` returns 0 matches at HEAD `2648bb2`). The new
library state taxonomy (`pending / in-progress / done / deferred`,
no `cancelled` for Parts) is unchanged.

### §4.6 — H.6 — tracker-* lib extensions

**Plan:** EXTEND ~7 tracker-* lib files for Part admission + execution-order
plumbing + id-map/sidecar schema. Includes `tracker-promote.sh`
Path 2 extension to admit `Phase-N.Part-x` target per POQ-4
resolution.

**Verdict:** **STILL-VALID.**

**Evidence.** H.6 is purely script-internal (`scripts/lib/`). The
POQ-4 outcome (Path 2 extension only; no Path 3; no task targets)
respects INV-6 and is independent of BD-193/194 baseline.

### §4.7 — H.7 — Per-entry sort key + mirror-generate + `_order-generate.sh`

**Plan:** EXTEND `_lib.sh:pe_sort_entries` + `mirror-generate.sh`;
CREATE `scripts/lib/per-entry/_order-generate.sh` (POQ-5) +
`scripts/tests/test-_order-generate.sh`.

**Verdict:** **STILL-VALID.**

**Evidence.** H.7 is purely script-internal + per-entry contract
side. The POQ-5 outcome (NEW `_order-generate.sh`) is consistent
with the existing single-responsibility-per-file pattern
(`toc-regenerate.sh` is the precedent). Filename uniqueness
preserved.

### §4.8 — H.8 — Migrators forward + reverse + v10→v11

**Plan:** EXTEND `tracker-migrate-forward.sh`, `tracker-migrate-reverse.sh`,
`migrate-v10-to-v11/decompose.sh`, `migrate-v10-to-v11/apply.sh`.
Implement execution-note structured warning per D8 §6.3a.

**Verdict:** **STILL-VALID.**

**Evidence.** H.8 is purely script-internal. The migrator framework
(BD-119) is unchanged; the new ops (H.4) are callable. SC7 + SC8
round-trip integrity is preserved.

Note: H.8 migrator behavior touches `pack-id-v2` marker emission
on phase-N.md files. Those markers are in client-installed file
content; per `feedback_client_facing_token_economy` they must not
carry BD-NNN refs in the emitted content. The plan correctly
specifies `pack-id-v2` + `execution-order` markers only — no BD
cites required.

### §4.9 — H.9 — New pack verbs

**Plan:** CREATE `scripts/pack-phase.sh` (`pack phase split` +
`pack phase reorder`); EXTEND `scripts/pack-tracker.sh`
(`pack tracker phase split` + `pack tracker phase reorder`); EXTEND
`scripts/pack-td.sh` (`pack task supersede`).

**Verdict:** **STILL-VALID.**

**Evidence.** H.9 is purely script-internal (`scripts/`). New verb
introduction is unaffected by BD-193/194 baseline. Filename
uniqueness preserved (`pack-phase.sh` 0 matches at HEAD).

### §4.10 — H.10 — validate-pack.py extensions + 4 NEW checks

**Plan:** EXTEND Check 32/33/34/35 + `check_issue_template_forms` +
`check_template_archive_v11`; ADD 4 new checks
(`check_phase_part_schema_v11_1`, `check_execution_order_marker`,
`check_part_re_parentage_invariants`, `check_part_has_member_task`);
wire 4 new per-check tests in workflow.

**Verdict:** **NEEDS-ADJUSTMENT (multiple per-surface alignments).**

**Evidence.** H.10 needs adjustments in several places to align with
the post-BD-193/194 baseline:

1. **Check 32 / Check 33** — unchanged (still applies to per-entry
   stream regex). STILL-VALID.
2. **Check 34** — extends `CROSS_REF_RE` to admit Part-id forms.
   STILL-VALID.
3. **Check 35** — verifies `tracker-phase-part.sh` exists + admits
   `cancelled` state per D5. The D5 admission must align with H.13's
   v11.0 SCHEMA extension. STILL-VALID; check Check 35's docstring
   accurately reflects D5 + D16 carve-out context.
4. **`check_issue_template_forms`** — H.10 needs to extend the EXISTING
   per-surface dict, NOT introduce per-surface logic from scratch:
   ```python
   expected_wi_type_options_per_surface = {
       "pack-root": {"bd", "td", "phase-epic-skeleton", "phase-task-skeleton", "phase-part-skeleton"},  # +phase-part-skeleton
       "project-template": {"td", "phase-epic-skeleton", "phase-task-skeleton", "phase-part-skeleton"},  # +phase-part-skeleton
   }
   ```
   Pack-root: 4 → 5; project-template: 3 → 4. The check ALREADY
   carries the per-surface dict (post-BD-193 F2.d + collateral); H.10
   only adds one key (`phase-part-skeleton`) to each surface set.
   NEEDS-ADJUSTMENT in plan TEXT (H.10 plan currently says "extend
   `expected_wi_type_options` from 4 to 5" — that wording assumes a
   single dict, which is now wrong).
5. **`check_template_archive_v11`** — H.10 references v11.0 frozen at
   5 entry-types + v11.1 declared 6 entry-types. STILL-VALID. The
   structural shape is preserved across BD-193 (BD-193 F1 INDEX
   segregation is an INDEX content extension, not a directory-shape
   change).
6. **Check 22 / Check 23 / Check 24 / Check 41** — H.10 plan does
   NOT touch these directly. But H.10's PLAN-text reference to
   "47 checks total (current 43 + 4 new)" is STALE per BD-194.
   Current count at HEAD `2648bb2` is 40 invoked checks (Check 24
   retired; 38 numbered + 2 informational). Post-H.10 the count is
   40 + 4 = 44 invoked checks (NOT 47 as plan asserts).

**Adjustment.** H.10 plan-text needs three updates:
(a) `expected_wi_type_options_per_surface` extension framing (single
key add per surface) — replace "extend from 4 to 5" with "extend
both surface sets by one key (`phase-part-skeleton`); pack-root
goes 4 → 5, project-template goes 3 → 4".
(b) Check-count expectations updated from "47 checks total (current
43 + 4 new)" to "44 invoked checks (current 40 + 4 new)".
(c) Verification command `python3 scripts/validate-pack.py 2>&1 |
grep -E "^── Check " | wc -l` — expected output is 44, not 47.

The 4 NEW checks (`check_phase_part_schema_v11_1`,
`check_execution_order_marker`, `check_part_re_parentage_invariants`,
`check_part_has_member_task`) are PS-internal extensions; STILL-VALID
as designed. They will receive numeric assignments at impl time
(planner addendum can leave the gap-allocation question open per
the precedent of Checks 12-15 retired + Check 24 retired — both
existing gaps in numbering).

**Cross-reference.** §3.1 (D1 needs-adjustment) + §4.2 (H.2
needs-replacement).

### §4.11 — H.11 — METHODOLOGY.md substantive doc edits

**Plan:** EXTEND `supporting-docs/METHODOLOGY.md` Multi-part phases
+ Phase numbering rules + D3/D4/D5/D8 rules + no-collapse rule.

**Verdict:** **NEEDS-ADJUSTMENT (token-economy compliance).**

**Evidence.** METHODOLOGY.md is client-installed via `init-project.sh`
stage S6 and is RAG-indexed in client agent contexts. The new memory
rule `feedback_client_facing_token_economy` requires that METHODOLOGY
edits AVOID gratuitous pack-only references (BD-NNN, architect-doc
cites, pack-history). The current H.11 plan text uses architect-doc
cross-references like "(architect §4.4)" and "(architect §4.5 + H.9)"
inside the prose; those are PLAN-TEXT references that the coder
must NOT carry into the actual METHODOLOGY edits — the coder edits
must reference client-readable surfaces only.

The H.11 plan should explicitly state: "References to
`ARCHITECTURE-BD-185.md` or BD-185 / D-N labels MUST NOT appear in
the METHODOLOGY edits themselves. Reference points are: (a) `pack
phase split` / `pack phase reorder` / `pack task supersede` verbs
documented at `docs/pack/HELP-FRAGMENT.md` + `HELP-FRAGMENT-TRACKER.md`;
(b) `templates-archive/v11.1/phase-part-v11.1/SCHEMA.md` (client-readable
under maintenance-docs-not-installed, but the SCHEMA's content
contract is implementable client-side); (c) per-entry tree
`_rules.md` + `_intro.md` (client-installed)."

The existing H.11 plan §3 ("Multi-part phases extensions") and §4
("Execution-note-status marker convention (D8)") are SUBSTANCE
correct (no BD cite required). Only the plan-text reference shapes
need to be clarified for the coder.

**Adjustment.** Add a "Token-economy compliance" sub-section to H.11
plan §3 + §4 reviewer-focus list:

> Per `feedback_client_facing_token_economy`: METHODOLOGY edits must
> reference client-readable surfaces only. NO BD-NNN cites; NO
> architect-doc cites; NO pack-history.

**Cross-reference.** §4.13 (H.13 — same rule applies to PM-CHAT.md).

### §4.12 — H.12 — MIGRATION + HELP-FRAGMENT pair

**Plan:** EXTEND `supporting-docs/MIGRATION-v10-to-v11.md` +
`pack-ops/HELP-FRAGMENT-PACK.md` + `project-template/docs/pack/HELP-FRAGMENT.md` +
`pack-ops/HELP-FRAGMENT-TRACKER.md` +
`project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`. Verification
includes:

```bash
diff pack-ops/HELP-FRAGMENT-PACK.md project-template/docs/pack/HELP-FRAGMENT.md
# Expected: empty (byte-identical) OR per existing convention if not identical
diff pack-ops/HELP-FRAGMENT-TRACKER.md project-template/docs/pack/HELP-FRAGMENT-TRACKER.md
# Expected: empty
```

**Verdict:** **WRONG-AND-NEEDS-REPLACEMENT.**

**Evidence.** Three issues:

1. **HELP-FRAGMENT-TRACKER byte-identity assertion is RETIRED.** Per
   BD-194 Candidate 6, `pack-ops/HELP-FRAGMENT-TRACKER.md` and
   `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` are SEPARATE
   artifacts with SEPARATE audiences per
   `feedback_pack_project_separation_of_concerns`. Check 24 retired.
   The "Expected: empty (byte-identical)" verification is WRONG —
   the diff may be empty TODAY by coincidence but must not be
   ASSERTED as required.
2. **HELP-FRAGMENT-PACK / HELP-FRAGMENT.md (pack vs project)** are
   NOT byte-identical at HEAD. (`HELP-FRAGMENT-PACK.md` is pack-side
   verb listings; `HELP-FRAGMENT.md` is project-side verb listings;
   these are different content per existing convention.) The "OR
   per existing convention if not identical" hedge in the plan
   acknowledges this but is imprecise. There has never been a CI
   gate asserting byte-identity between these two files (Check 24
   only ever applied to HELP-FRAGMENT-TRACKER.md).
3. **Per-surface content authority.** Post-BD-193 F4/F5 + BD-194:
   - `pack-ops/HELP-FRAGMENT-TRACKER.md` is pack-developer-audience;
     content is what `pack help` shows when run against the pack
     repo itself.
   - `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` is
     client-audience; content is what `pack help` shows in client
     installs (after S11 copies it to `docs/pack/`).
   - Adding `pack tracker phase split` + `pack tracker phase reorder`
     to BOTH surfaces is appropriate (they're verbs available to
     both audiences). But the edits are NOT mechanically byte-
     identical mirrors; they are SAME-CONTENT EDITS APPLIED
     INDEPENDENTLY to each surface.

H.12's verification + plan-text framing must align with the
post-BD-194 contract.

**Adjustment.** Reframe H.12 as PER-SURFACE same-content edits:

**Pack-side** (`pack-ops/HELP-FRAGMENT-PACK.md` +
`pack-ops/HELP-FRAGMENT-TRACKER.md`):
- HELP-FRAGMENT-PACK gains `pack phase split`, `pack phase reorder`,
  `pack task supersede` rows.
- HELP-FRAGMENT-TRACKER gains `pack tracker phase split`,
  `pack tracker phase reorder` rows.
- Content shape: pack-developer audience.

**Project-side** (`project-template/docs/pack/HELP-FRAGMENT.md` +
`project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`):
- HELP-FRAGMENT gains same verb rows as pack-side
  HELP-FRAGMENT-PACK.
- HELP-FRAGMENT-TRACKER gains same verb rows as pack-side
  HELP-FRAGMENT-TRACKER.
- Content shape: client-project-user audience. (Today at HEAD this
  is byte-identical to pack-side for HELP-FRAGMENT-TRACKER; that's
  coincidence not contract.)

**Verification command replacement:**

```bash
# Pack-side new verbs present:
grep -nE "pack phase split|pack phase reorder|pack task supersede" pack-ops/HELP-FRAGMENT-PACK.md
grep -nE "pack tracker phase split|pack tracker phase reorder" pack-ops/HELP-FRAGMENT-TRACKER.md
# Project-side new verbs present:
grep -nE "pack phase split|pack phase reorder|pack task supersede" project-template/docs/pack/HELP-FRAGMENT.md
grep -nE "pack tracker phase split|pack tracker phase reorder" project-template/docs/pack/HELP-FRAGMENT-TRACKER.md
# Pack-side existence assertions (Check 23 fail-loud safety):
test -f pack-ops/HELP-FRAGMENT-TRACKER.md && echo "pack-side present"
# Project-side existence assertion (Check 41 self-doc list integrity):
test -f project-template/docs/pack/HELP-FRAGMENT-TRACKER.md && echo "project-side present"
```

The `diff ... = empty` assertions are RETIRED for HELP-FRAGMENT-TRACKER.md
specifically. For HELP-FRAGMENT-PACK vs HELP-FRAGMENT.md the diff
was never an asserted invariant; that line in H.12 plan should be
DROPPED as misleading.

**Reviewer scope per BD-194:**
- Pack-side and project-side HELP-FRAGMENT-TRACKER MUST gain the
  same verb rows (semantic equivalence per audience).
- BYTE-IDENTITY is NOT required and MUST NOT be asserted.
- Each surface's content is judged on its OWN merit per its
  audience.

**Cross-reference.** §4.13 (H.13 PM-CHAT.md) + §5 POQ-NEW-2.

### §4.13 — H.13 — PM-CHAT.md workflow + v11.0 phase-task-v11.0 SCHEMA cancelled extension

**Plan:** EXTEND `project-template/docs/pack/PM-CHAT.md` workflow
references for `pack phase split` + `pack task supersede`. EXTEND
`templates-archive/v11.0/phase-task-v11.0/SCHEMA.md` Section 3
(Label family) admits `cancelled`; Section 4 (Body grammar) admits
`<!-- execution-note-status: historical -->` per D8.

**Verdict:** **NEEDS-ADJUSTMENT (token-economy + Convention Y
clarity).**

**Evidence.** Two sub-issues:

1. **PM-CHAT.md token-economy compliance.** Per
   `feedback_client_facing_token_economy`, PM-CHAT.md is
   client-installed (per `init-project.sh` stage S6) and
   RAG-indexed. The plan text already says "No solution-in-prompt
   content per `feedback_no_solutions_in_agent_prompts`", but the
   token-economy rule is additional: NO BD-NNN cites; NO
   architect-doc cites; NO pack-history. The plan's reviewer-focus
   list at §4.13 should explicitly include this constraint.
2. **v11.0 SCHEMA extension under D16 Class A.** The H.13 phase-task
   SCHEMA edit is the canonical D16 Class A intra-file additive
   extension. The plan correctly references D16 Convention Y. NEEDS
   minor framing addition: per BD-193 F2.a, the `phase-task-v11.0/SCHEMA.md`
   dependencies grammar at L79, L91 was already EDITED (BD-NNN
   removed). H.13's `cancelled` extension is a SEPARATE intra-file
   edit. The H.13 plan-text should NOT regress the F2.a edit
   (i.e., H.13 must NOT re-introduce BD-NNN to the dep-grammar even
   incidentally). The reviewer-focus list should call this out.

**Adjustment.** H.13 plan text adjustments:

(a) Add token-economy compliance to PM-CHAT.md edit constraints.
(b) Add reviewer-focus item: "Verify the BD-193 F2.a dep-grammar
edit at L79, L91 is NOT regressed — `phase-task-v11.0/SCHEMA.md`
must continue to omit BD-NNN from dep-grammar; H.13 only adds
`cancelled` to state enumeration and `execution-note-status` marker."

The substantive H.13 edits are CORRECT; only the framing needs
adjustment.

**Cross-reference.** §3.16 (D16 needs-adjustment for class clarity).

### §4.14 — H.14 — Templates-archive cross-references (v11.0 ↔ v11.1)

**Plan:** EXTEND `templates-archive/v11.1/INDEX.md` (finalize
cross-references); EXTEND `templates-archive/v11.0/INDEX.md` (add
forward-reference footnote per POQ-6 + D16 Convention Y).
Verification includes:

```bash
diff maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml .github/ISSUE_TEMPLATE/work-item.yml
# Expected: empty (byte-identical; no H.14-refresh needed per POQ-1 resolution 2026-05-26).
```

**Verdict:** **NEEDS-ADJUSTMENT (archive snapshot target).**

**Evidence.** The H.14 verification `diff v11.1/forms/work-item.yml
.github/ISSUE_TEMPLATE/work-item.yml` is the byte-identity assertion
between the archive snapshot and PACK-ROOT work-item.yml. Post-BD-193
F2.d, the pack-root and project-template forms diverge, so the
archive snapshot CANNOT be byte-identical to BOTH. Per POQ-NEW-1
recommendation (§5 below), the archive should snapshot
project-template (client-facing-archive precedent set by v11.0).

If POQ-NEW-1 resolves to Option (c) — archive snapshots
project-template only — H.14's verification command must change:

```bash
diff maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml \
     project-template/.github/ISSUE_TEMPLATE/work-item.yml
# Expected: empty (archive snapshots project-template-side; matches
# v11.0 archive precedent — client-facing-archive).
```

The v11.0/INDEX.md forward-reference footnote (D16 Class A intra-file
additive extension) is unchanged in shape and STILL-VALID.

**Adjustment.** Update H.14 verification command per the POQ-NEW-1
resolution. The plan-text framing already notes the file was
"CREATED byte-identically from H.2 per POQ-1 resolution 2026-05-26";
that sentence must specify WHICH live form the archive copies.

**Cross-reference.** §4.2 (H.2 verdict) + §5 POQ-NEW-1.

### §4.15 — H.15 — Test infrastructure

**Plan:** EXTEND `template-version-test.sh` (add `phase-part-v11.1`),
`tracker-init-test.sh` (label provisioning), `test-per-entry.sh`
(new sort fixture); CREATE per-entry sort fixture subdir.

**Verdict:** **STILL-VALID.**

**Evidence.** H.15 is purely test-infrastructure (`scripts/tests/`).
No client-facing surface; no pack/project boundary touched.

### §4.16 — H.16 — End-of-batch reviewer + status flip

**Plan:** Run `pack-reviewer` on full batch diff; Pack Chat triages;
fix-coder spawns; combine fix + status flip into ONE final commit
(or standalone status flip if no fixes).

**Verdict:** **NEEDS-ADJUSTMENT (reviewer scope expansion).**

**Evidence.** H.16's reviewer scope must explicitly include:

1. **Token-economy compliance review** for client-installed surfaces
   (METHODOLOGY, PM-CHAT, HELP-FRAGMENT*, `_rules.md`, `_intro.md`,
   skill files) per `feedback_client_facing_token_economy`. No
   BD-NNN cites; no architect-doc cites; no pack-history.
2. **Pack/project separation discipline review** per
   `feedback_pack_project_separation_of_concerns`. Per-surface
   form / HELP-FRAGMENT-TRACKER edits judged on their own merit;
   no cross-surface byte-identity asserted (unless on
   `HELP-FRAGMENT-PACK ↔ HELP-FRAGMENT.md` — also NOT asserted by
   any current CI gate).
3. **BD-NNN operational-rule compliance review** per
   `feedback_bd_pack_only_operational_rule`. Client-facing dep
   grammars / form admissions / parser regexes must NOT re-introduce
   BD-NNN. The H.13 v11.0 SCHEMA edit must not regress F2.a dep
   grammar.

The plan text references `feedback_no_prior_reviews_to_reviewer` (correct
— reviewer prompt cites ARCHITECTURE doc only), `feedback_fix_all_review_findings`,
`feedback_review_carry_forward_discipline`. These all still apply.

**Adjustment.** H.16 plan §"Reviewer focus dimensions specific to
BD-185" gains three new bullets:

- **Token-economy compliance** — no BD/architect-doc/pack-history
  refs in client-installed surfaces.
- **Pack/project separation discipline** — per-surface judgments;
  no cross-surface byte-identity asserted on HELP-FRAGMENT* pair.
- **BD-NNN operational-rule preservation** — H.13 v11.0 SCHEMA edit
  does not regress F2.a; dep grammars don't re-acquire BD-NNN.

The BD-185 status flip mechanics are unchanged; the close-commit
summary text suggestion in H.16 plan may be lightly extended to
mention BD-193/194 architectural baseline integration if Pack Chat
chooses.

---

## §5 — NEW POQs surfaced

The reconciliation surfaced two architectural questions not
anticipated in the original architect doc or planner doc. Both are
USER-RESOLVE decisions; auto-classification would violate
`feedback_preliminary_triage_architect_challenge`.

### §5.1 — POQ-NEW-1 — v11.1 archive snapshot target (pack-root or project-template)

**Question.** Post-BD-193 F2.d, the live work-item.yml forms at
pack-root and project-template DIVERGE (5 wi-type options post-H.2
on pack-root; 4 on project-template). The
`templates-archive/v11.1/forms/work-item.yml` archive snapshot
(per planner POQ-1 resolution: created at H.2 byte-identically to
the live form) must choose ONE source-of-truth surface.

Three options:

| Option | Mechanic | Evidence-based recommendation? |
|---|---|---|
| (a) Snapshot pack-root only | Single `v11.1/forms/work-item.yml`, byte-identical to pack-root | Loses client-facing archive (regresses v11.0 archive precedent) |
| (b) Snapshot both | Two files: `v11.1/forms/work-item-pack.yml` + `v11.1/forms/work-item-project.yml` | Most complete archive; splits one conceptual file into two; needs INDEX update |
| (c) Snapshot project-template only | Single `v11.1/forms/work-item.yml`, byte-identical to project-template | Aligns with v11.0 archive precedent (the v11.0 archive form is also project-template-shaped after F2.c bug-fix carve-out); smallest footprint |

**Architect recommendation: Option (c).** Reasons:
- v11.0 set the precedent — its archive form is the client-facing
  shape (the F2.c carve-out left only the 3-option client form;
  pack-root was not duplicated).
- Pack-root form is preserved in git history at the live path; the
  archive's purpose is to capture the client-facing template
  contract, not pack-internal variants.
- Smallest maintenance burden; smallest archive footprint.

**User decision needed before planner addendum H.2 + H.14 specifies
the file path + verification command.**

### §5.2 — POQ-NEW-2 — HELP-FRAGMENT-PACK vs HELP-FRAGMENT.md byte-identity status (CURRENT)

**Question.** The H.12 plan's verification command currently includes:

```bash
diff pack-ops/HELP-FRAGMENT-PACK.md project-template/docs/pack/HELP-FRAGMENT.md
# Expected: empty (byte-identical) OR per existing convention if not identical
```

These two files were NEVER under Check 24's byte-identity contract
(Check 24 only applied to HELP-FRAGMENT-TRACKER.md, not
HELP-FRAGMENT-PACK / HELP-FRAGMENT.md). The "OR per existing convention"
hedge in H.12 plan acknowledges that they may already differ.

A separation-of-concerns reading suggests these two files ALSO
diverge by audience:
- `HELP-FRAGMENT-PACK.md` is the pack-developer help for `pack help`
  run against the pack repo.
- `HELP-FRAGMENT.md` (project-side) is the client help for `pack help`
  run in a client install.

Today's HEAD state (sample audit):

```
$ wc -l pack-ops/HELP-FRAGMENT-PACK.md project-template/docs/pack/HELP-FRAGMENT.md
```

This question was not in the original architect or planner docs but
arises from the separation-of-concerns rule applied symmetrically.

**Architect recommendation.** TREAT these two files as SEPARATE
artifacts going forward (consistent with HELP-FRAGMENT-TRACKER pair
post-BD-194). The H.12 verification command should DROP the diff
assertion entirely. Same-content edits land per-surface; byte-identity
is coincidence not contract.

**User decision needed.** If the user prefers to keep an explicit
diff check (as belt-and-suspenders), that's a deliberate retention
that should be cited in H.12 plan as "convention preserves byte-
identity for HELP-FRAGMENT-PACK/HELP-FRAGMENT.md pair only, NOT for
HELP-FRAGMENT-TRACKER pair (Check 24 retired)." The recommendation
is to drop the assertion in line with BD-194.

### §5.3 — POQ-NEW-3 — Check 22 cross-reference impact on H.10 + H.12

**Question.** BD-194's Check 22 fix introduced a per-surface
`tracker_fragment` lookup. The surfaces dict now has:

```python
surfaces = {
    "pack-root": {
        ...
        "fragment": pack-ops/HELP-FRAGMENT-PACK.md,
        "tracker_fragment": pack-ops/HELP-FRAGMENT-TRACKER.md,
    },
    "project-template": {
        ...
        "fragment": project-template/docs/pack/HELP-FRAGMENT.md,
        "tracker_fragment": project-template/docs/pack/HELP-FRAGMENT-TRACKER.md,
    },
}
```

H.10 plan does NOT reference Check 22 (the plan was authored before
BD-194). After H.12 lands the new verb rows in each tracker_fragment,
Check 22 will verify each per-surface fragment's verb-presence
against the per-surface fragment's own prose. If a docs/pack
substantive doc edit (per H.11 → METHODOLOGY) references a new verb
in prose but the corresponding HELP-FRAGMENT-TRACKER does not have
it listed, Check 22 will FAIL on the surface whose docs reference
the verb.

This is a positive constraint — Check 22 will actively catch H.12
plan-vs-implementation mismatches. But H.10's reviewer-focus list
should explicitly call out that Check 22 + Check 23 + Check 41
already enforce surface-local invariants for HELP-FRAGMENT-TRACKER
in ways that the H.10 design did not anticipate.

**Architect recommendation.** Treat this as informational, not a
blocking POQ. The planner addendum should note in H.10 + H.12
reviewer-focus lists that:
- Check 22 enforces "each surface's verbs match its own
  HELP-FRAGMENT-TRACKER content";
- Check 23 enforces "pack-side HELP-FRAGMENT-TRACKER must exist
  (fail-loud)";
- Check 41 enforces "project-side HELP-FRAGMENT-TRACKER must be in
  `_CLIENT_INSTALLED_FILES`".

The BD-185 H.10 NEW checks (phase-part schema / exec-order marker /
Part re-parentage / Part membership) are ORTHOGONAL to these and do
NOT need to take over Check 22/23/41's role.

**User can defer this** to coder pass; not a blocking decision.

---

## §6 — Cross-cutting findings

Five patterns affect multiple D-N or H-N items. Surfaced here for
the user / planner / coder to internalize once rather than
re-derive at each touch point.

### §6.1 — The byte-identity-mirror assumption is broken across multiple H.X steps

`PLAN-BD-185.md` was authored under the implicit assumption that
pack-side and project-side mirrors of "the same file" are
byte-identical. That assumption was reasonable at planner time
(pre-BD-193/194 baseline) but is now broken across three file pairs:

1. `work-item.yml` (pack-root vs project-template) — H.2 + H.14
   affected.
2. `HELP-FRAGMENT-TRACKER.md` (pack-ops vs project-template/docs/pack)
   — H.12 affected.
3. `HELP-FRAGMENT.md` family (pack-ops/HELP-FRAGMENT-PACK.md vs
   project-template/docs/pack/HELP-FRAGMENT.md) — H.12 affected;
   per-surface authority recommended (POQ-NEW-2).

The planner addendum should sweep `PLAN-BD-185.md` for all `diff` /
"byte-identical" assertions and replace each with a per-surface
verification command.

### §6.2 — Client-facing surface plan-text references to BD-N / D-N / architect-doc cites are NOT carried into actual file edits

The plan text uses internal scaffolding references like "(architect
§4.4)", "(D5 §4.4a)", "(per BD-185 §4.5 + H.9)" to anchor planner
intent. The H.11 + H.13 + H.12 + H.3 reviewer-focus lists must
EXPLICITLY say the actual file edits MUST NOT carry these references
into client-installed content. The reviewer pass must verify NO
BD-NNN / architect-doc / pack-history cite is introduced into:

- `supporting-docs/METHODOLOGY.md`
- `supporting-docs/MIGRATION-v10-to-v11.md` (Class B WASTE class —
  Class A LEGITIMATE migration-mechanism cites preserved per BD-193
  §6.3 user resolution)
- `project-template/docs/pack/PM-CHAT.md`
- `project-template/docs/pack/HELP-FRAGMENT.md` /
  `HELP-FRAGMENT-TRACKER.md`
- `project-template/docs/project/implementation-plan/_rules.md` /
  `_intro.md`
- `pack-ops/HELP-FRAGMENT-PACK.md` /
  `pack-ops/HELP-FRAGMENT-TRACKER.md` (pack-side but still indexable
  per `feedback_client_facing_token_economy` reasoning — these are
  the same audience-classified content as their project-side mirrors;
  the rule encourages minimal pack-only references for
  conceptual-consistency reasons even on pack-side).

Check 43 already catches some leak patterns (project-side bare
cross-reference scanner / V11 leak-sweep prevention). The planner
addendum should remind H.11 / H.12 / H.13 / H.3 reviewers to apply
Check 43 + token-economy rule + boundary-investigation skill.

### §6.3 — Check count expectations are STALE across H.10

`PLAN-BD-185.md` H.10 references "47 checks total (current 43 +
4 new)". Post-BD-194: current is 40 (38 numbered + 2 informational
— Check 24 retired). Post-H.10: 40 + 4 = 44 invoked checks.

Three places in PLAN-BD-185 carry the stale count:
- H.10 success criteria #5 ("47 checks total").
- H.10 verification command grep `wc -l` expected output 47.
- H.16 success criteria #4 ("47 checks total").

The planner addendum should update all three to 44.

### §6.4 — D16 Convention Y has TWO operational classes; original framing covered ONE

D16 was authored as Class A (additive content extensions) only.
BD-193 F2.c exercised Class B (bug-fix carve-out via REMOVAL). The
v11.0 INDEX.md L31 now codifies this:

> "The original v11.0 shipped form admitted a 4th `bd` option; D16
> removed it from the archive as a bug-fix carve-out."

The architect doc §10.1 + §14.1 reference "intra-file additive
extension permitted under v11.0 structural-shape-frozen contract" —
that wording is now incomplete. The planner addendum should
acknowledge both classes when referring to D16, with H.13 explicitly
being a Class A use (additive `cancelled` state) and BD-193 F2.c
being a Class B precedent.

### §6.5 — `check_issue_template_forms` is ALREADY per-surface; H.10 only ADDS one key

Pre-BD-193, `check_issue_template_forms` had a single
`expected_wi_type_options` set. BD-193 split it into a per-surface
dict. The H.10 plan-text framing "extend from 4 to 5" reflects the
pre-BD-193 understanding. The actual H.10 edit is now ONE-key-add
per surface, not a single-set transform.

This is a plan-text-only correction; the substantive H.10 work
(four NEW checks + Check 32/33/34/35 extensions) is unaffected.

---

## §7 — Recommended next steps

### §7.1 — Planner addendum scope

Surface to the user the verdicts in §3 + §4 + §5 + §6 above. After
user review (with potential decision changes), produce a
`PLAN-BD-185-ADDENDUM.md` that:

1. **For each WRONG-AND-NEEDS-REPLACEMENT H.X verdict** (H.2, H.12),
   provide the replacement plan-text in full per the adjustment
   recommendations in §4.2 + §4.12.
2. **For each NEEDS-ADJUSTMENT H.X verdict** (H.0, H.10, H.13, H.14,
   H.16), provide the targeted plan-text edits in §4.0 + §4.10 +
   §4.13 + §4.14 + §4.16.
3. **For each NEEDS-ADJUSTMENT D-N verdict** (D1, D16), provide the
   targeted architect-doc edits or addendum notes in §3.1 + §3.16.
4. **For each NEW POQ** (POQ-NEW-1, POQ-NEW-2, POQ-NEW-3), surface
   to the user with the architect's recommendation; do NOT
   auto-resolve per `feedback_no_solutions_in_agent_prompts` (the
   user retains decision authority).
5. **For cross-cutting findings** (§6.1-§6.5), apply globally:
   - §6.1 sweep all "byte-identical" assertions across H.2, H.12,
     H.14.
   - §6.2 add token-economy compliance to reviewer focus lists for
     H.3, H.11, H.12, H.13.
   - §6.3 update check-count expectations in H.10 + H.16.
   - §6.4 acknowledge D16 Class A + Class B in framing references
     across H.13 + H.14.
   - §6.5 reframe H.10 `check_issue_template_forms` extension as
     "add one key per surface" rather than "extend 4→5".

The planner addendum should NOT rewrite the original
`PLAN-BD-185.md`; it should be a separate file that the coder reads
ALONGSIDE the original. This preserves audit history.

### §7.2 — User-discussion POQ list

Before planner addendum spawns, the user resolves:

1. **POQ-NEW-1** — v11.1 archive snapshot target. Architect
   recommends Option (c) (project-template surface; matches v11.0
   precedent). User authorizes one of (a) / (b) / (c).
2. **POQ-NEW-2** — HELP-FRAGMENT-PACK / HELP-FRAGMENT.md byte-identity
   assertion. Architect recommends DROP per BD-194 separation
   alignment. User authorizes DROP or KEEP-AS-CONVENTION.
3. **POQ-NEW-3** — Check 22/23/41 informational note in H.10 + H.12
   reviewer-focus lists. Architect recommends include as
   informational; not blocking. User authorizes inclusion shape.

### §7.3 — H.2 coder readiness gate

H.2 coder MUST NOT spawn until the planner addendum lands AND the
user re-approves the (revised) H.2 design. The current H.2 plan
text contains the byte-identical assertion that, if executed
mechanically, would regress BD-193 F2.d.

Per `feedback_planner_user_review_before_coder`, the planner addendum
output is NEVER auto-approved into a coder spawn — Pack Chat surfaces
the addendum for user review and waits for explicit approval before
spawning the H.2 coder.

### §7.4 — Sequence the planner addendum + user review explicitly

Recommended sequence (Pack Chat orchestration):

1. User reviews THIS reconciliation report (`ARCHITECTURE-BD-185-RECONCILIATION.md`).
2. User decisions on POQ-NEW-1, POQ-NEW-2, POQ-NEW-3 (and any
   verdict-level overrides).
3. Pack Chat spawns `pack-planner` (background) to produce
   `PLAN-BD-185-ADDENDUM.md` consuming this reconciliation +
   user-locked POQ-NEW resolutions.
4. User reviews planner addendum.
5. Pack Chat spawns `pack-coder` (background) for H.2 with the
   revised H.2 plan-text from the addendum.

Per the pack memory `feedback_decision_presentation_protocol` (saved
2026-05-25, extended 2026-05-25), Pack Chat presents each POQ to the
user individually, with full inline context, an architect
recommendation, and waits for the decision before moving to the
next. The architect provided recommendations in §5 above; Pack Chat
sequences the discussion.

---

## §8 — Cross-references

### §8.1 — Input docs

- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md` —
  original architect pass (1233 lines; 16 USER-LOCKED decisions).
- `maintenance-docs/v11-implementation/PLAN-BD-185.md` — original
  planner pass (1424 lines; 16-commit plan).
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.1.md`
  — H.1 coder pass (committed; SHA `8b4c607`).
- `maintenance-docs/v11-implementation/PACK-REVIEW-BD-185-H.1.md` —
  H.1 review.
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-H.1-NITS.md`
  — H.1 NIT cleanup (committed; SHA `2648bb2`).
- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-194.md` —
  Check 24 retirement architect (1179 lines; Candidate 6).
- `maintenance-docs/v11-implementation/PLAN-BD-194.md` — BD-194
  planner (946 lines).
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-194.md`
  — BD-194 coder pass (980 lines).
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-194-STALE-REFS.md`
  — BD-194 stale-refs.
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-194-FOLLOWUP.md`
  — BD-194 follow-up (F-1 + F-2 + F-3 fixes).
- `maintenance-docs/v11-implementation/PACK-REVIEW-BD-194.md` —
  BD-194 review.
- `maintenance-docs/v11-implementation/AUDIT-INVENTORY-BD-TD-PATH.md`
  — BD-193 Phase 1.
- `maintenance-docs/v11-implementation/AUDIT-DISPOSITION-BD-TD-PATH.md`
  — BD-193 Phase 2.
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-193.md`
  — BD-193 Phase 3.
- `maintenance-docs/v11-implementation/PACK-REVIEW-BD-193-PHASE-4.md`
  — BD-193 Phase 4 audit.
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-193-PHASE-5.md`
  — BD-193 Phase 5.

### §8.2 — Pack memory anchors

Authoritative rules this reconciliation applied (all visible in the
`## Pack memory` section of pack-root `CLAUDE.md` at HEAD `2648bb2`):

- `feedback_bd_pack_only_operational_rule` — user-locked
  2026-05-26 during BD-185 Code Red 2. Authoritative for §3.1 D1
  per-surface defense + §4.13 H.13 dep-grammar regression check +
  §6.2 cross-cutting finding.
- `feedback_pack_project_separation_of_concerns` — user-locked
  2026-05-26 during BD-185 Code Red 2. Authoritative for §4.2 H.2
  needs-replacement + §4.12 H.12 needs-replacement + §6.1
  cross-cutting + §5.1 POQ-NEW-1 + §5.2 POQ-NEW-2.
- `feedback_client_facing_token_economy` — user-locked 2026-05-26.
  Authoritative for §4.3 H.3 + §4.11 H.11 needs-adjustment + §4.13
  H.13 needs-adjustment + §6.2 cross-cutting.
- `feedback_preliminary_triage_architect_challenge` — established
  2026-05-25; extended 2026-05-26. Authoritative for §2.1 methodology
  + every D-N challenge in §3 + every H-N challenge in §4.
- `feedback_pattern_matching_out_of_context_antipattern` —
  established 2026-05-25. Authoritative for §6.1 cross-cutting
  (byte-identity-mirror pattern reuse without property-fit
  re-check is the anti-pattern here).
- `feedback_pack_coder_preflight_pattern` — updated `ba9e09d`
  (per-check test runs gate added). Authoritative for §7.3 H.2
  coder readiness gate (PREFLIGHT line must verify Check 22/23/41
  PASS post-edit).
- `feedback_planner_user_review_before_coder` — authoritative for
  §7.3 + §7.4 (planner addendum → user review → coder spawn
  sequencing).
- `feedback_decision_presentation_protocol` — authoritative for §7.4
  POQ presentation sequence.
- `feedback_tracker_portability` — authoritative for §3.9 D9 +
  §4.4 H.4 (abstractable design principle preserved).
- `feedback_deferral_is_scope_creep` — authoritative for §3.2 D2
  (collapse rejected; no "invented work" path) + planner addendum
  scope (in-scope vs new-BD discipline).

### §8.3 — BD entries

- BD-185 entry: `pack-ops/BACKLOG.md` lines 1746-1793. Status:
  Open. Position: Batch 19d.
- BD-193 entry: `pack-ops/BACKLOG.md` lines 3015-3072. Resolved
  per Phase 5 close.
- BD-194 entry: `pack-ops/BACKLOG.md` lines 3076-3124. Resolved per
  follow-up close.

### §8.4 — Working-tree HEAD state evidence (at reconciliation pass)

- HEAD SHA `2648bb2`
  (`docs: v11 — BD-185 open (Batch 19d phase parts + ordering, pack-only)`
  per H.1 NIT cleanup chain completion).
- Pack-root `.github/ISSUE_TEMPLATE/work-item.yml`: 4 wi-type
  options including `bd`.
- Project-template `.github/ISSUE_TEMPLATE/work-item.yml`: 3 wi-type
  options excluding `bd`; L18 boundary defense present.
- `pack-ops/HELP-FRAGMENT-TRACKER.md`: 49 lines, byte-identical to
  project-template counterpart TODAY (coincidence per BD-194).
- `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`: 49 lines.
- `scripts/validate-pack.py`: Check 24 retired (function deleted,
  callsite removed, check-list comment carries retirement note).
- `templates-archive/v11.0/phase-task-v11.0/SCHEMA.md`: no BD-NNN
  dep grammar admissions; `cancelled` state NOT YET admitted in
  Section 3 (H.13 pending).
- `templates-archive/v11.1/phase-part-v11.1/SCHEMA.md`: exists; no
  BD-NNN admissions in prerequisites grammar; `cancelled` state
  cross-referenced as exclusion (Part-state taxonomy 4-state).
- `templates-archive/v11.1/INDEX.md`: declares 6 entry types (5
  client-applicable + 1 pack-internal); cites D16 + Convention Y;
  Forms file section names the post-BD-193 pack/project divergence.
- `templates-archive/v11.0/INDEX.md`: declares 5 entry types (4
  client-applicable + 1 pack-internal); the F2.c carve-out for `bd`
  in the v11.0 forms is cited at L31.
- `find . -name "tracker-phase-part.sh" -not -path "./.git/*"` —
  0 matches.
- `find . -name "pack-phase.sh" -not -path "./.git/*"` — 0 matches.
- `find . -name "_order.md" -not -path "./.git/*"` — 0 matches.
- `find . -name "_order-generate.sh" -not -path "./.git/*"` —
  0 matches.

---

*End of reconciliation deliverable.*
