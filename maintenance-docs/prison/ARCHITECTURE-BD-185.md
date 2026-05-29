# ARCHITECTURE-BD-185.md — Phase Parts hierarchy + tracker-mode execution ordering

**Authored by:** pack-architect (read-only design pass).
**Date:** 2026-05-25 (US/Pacific).
**Branch:** v11-dev.
**Repo HEAD at authoring:** 4d1f9e5 — docs: v11 — BD-185 open (Batch 19d phase parts + ordering, pack-only).
**Source BD:** BD-185 (`pack-ops/BACKLOG.md` BD-185 entry — Open).
**Primary input:** `maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-PARTS-AND-ORDERING.md` (1051-line researcher fact base, HEAD a5c7e62).
**Pipeline:** docs-researcher (complete) → architect (THIS doc) → user review → planner → user review → coder.

---

## §1 — Scope

This document is the architect-pass design for BD-185 (Phase parts hierarchy + tracker-mode execution ordering). It addresses four problems and eight success criteria from the BD entry, subject to five USER-LOCKED constraints (C-1..C-5) surfaced 2026-05-25, and triages all 17 observations in inventory §12 + all checklist items in inventory §13.

### §1.1 — Problem statements (BD-185, verbatim)

- **P1.** Mid-work phase splits have no first-class tracker representation.
- **P2.** The hierarchy changes when parts are added (Phase N → Parts → Tasks), and existing task IDs must survive without renumbering.
- **P3.** Tracker-mode execution ordering has no native mechanism (issue numbers reflect creation order; blockers give partial order only; sub-issues give containment only; flat-file execution notes do not survive sync).
- **P4.** v10→v11 and flat-file→tracker migrations must absorb pre-existing whole-number phases without manual intervention, including ordering initialization.

### §1.2 — Success criteria (BD-185, verbatim)

- **SC1.** At-creation phase splits produce multiple phases with new immutable numbers (both modes).
- **SC2.** Mid-work phase expansion to multi-part form preserves the phase number and all existing task IDs (both modes).
- **SC3.** Phase numbers and task IDs (N.M) are never renumbered; tracker entity IDs are inherently immutable.
- **SC4.** Execution ordering is expressible in both modes; tracker mode does not depend on a flat-file artifact and does not use GH Projects.
- **SC5.** STATUS.md remains a dashboard; does not become ordering SSOT.
- **SC6.** Tracker form-family supports parts and ordering with the smallest possible template_version delta consistent with BD-068.
- **SC7.** Bi-directional sync preserves part membership and execution order (forward + reverse).
- **SC8.** Pre-existing whole-number phases pass through v10→v11 and v11.0 flat→tracker without manual intervention; ordering initialized from current implementation order.

### §1.3 — User-locked constraints (C-1..C-5)

- **C-1.** Part-id grammar: phase = integer only; part = letter only; task = integer base with optional letter suffix. Composite forms: `Phase-1.Part-a.Task-3d` (with Part), `Phase-2.Task-7` (null-Part — skip the `.Part-X` segment entirely). PROHIBITED: empty-separator forms like `Phase-2..Task-7`. Architect may propose alternatives if more concise/clear AND unambiguous.
- **C-2.** Issue Fields is the chosen mechanism for v11+ execution ordering and may be considered for Part identity. Architect MUST design: (1) Issue Fields shape for ordering, (2) Issue Fields shape for Part identity if chosen, (3) NON-JSON-SIDECAR fallback for trackers without Issue Fields (Forgejo, Gitea), (4) flat-file-mode fallback (existing Execution note convention may suffice or new convention needed).
- **C-3.** Groupings constraints (4 hard rules): G-1 groupings contain ONLY phases (no orphan parts, tasks, backlog entries); G-2 minimum 2 phases per grouping; G-3 backlog entry must be converted to a phase AND scheduled before joining a grouping; G-4 architect may skim BD-189 docs but groupings has NOT been architected — anything beyond G-1/G-2/G-3 is groupings-architect judgment.
- **C-4.** Immutability invariants INV-1..INV-9 (per inventory §9) are LOCKED. Design MUST NOT violate any; violating an invariant is OUT OF SCOPE for BD-185 and surfaces to user discussion.
- **C-5.** Trinity rule + cross-CLI parity per `CLAUDE.md` § "Trinity rule" + `ARCHITECTURE-BD-182.md` §4.1 canonical reference table for any cross-CLI references.

### §1.4 — Decision log (Pack Chat review sessions 2026-05-25 + 2026-05-26)

All 10 architect POQs were resolved during a Pack Chat review session with the user 2026-05-25 (D1–D14). Two additional architectural refinements (D15 + D16) emerged during a subsequent Pack Chat review session 2026-05-26 that resolved the 7 planner POQs (PLAN-BD-185.md §6 → §6a). The 16 decisions are recorded here as a comprehensive audit trail.

| # | Decision | Source | Resolution | Cross-ref |
|---|---|---|---|---|
| D1 | INV-7 breach (5th `wi-type` option `phase-part-skeleton`) | Architect §4.3 | ACCEPTED — defense documented; soft cap exceeded with rationale | §4.3 |
| D2 | Part collapse | Architect POQ-1 | REJECTED as anti-pattern — architectural rule; no `pack phase collapse` verb in any release | §4.7 |
| D3 | Empty Parts at creation | User-driven (2026-05-25) | FORBIDDEN — every Part must have ≥1 task at creation | §4.7 |
| D4 | Mid-life re-parenting between Parts | User-driven (2026-05-25) | FORBIDDEN — supersede only via `pack task supersede` | §4.7, §4.8 |
| D5 | `cancelled` state in task taxonomy | User-driven (2026-05-25) | ADDED — 7-state taxonomy; ❌ marker | §4.4a, §11 |
| D6 | Primary-source verification | Architect POQ-2 | VERIFY-AT-IMPLEMENTATION-TIME — planner/coder verifies; no extra researcher pass | §5.1, §7 |
| D7 | `_order.md` separate file | Architect POQ-3 | ACCEPTED Option Y + SSOT documentation + BD-189 forward-pointer | §5.3, §5.X SSOT |
| D8 | Execution-note prose parsing | Architect POQ-4 | DEFAULT to phase_number + STRUCTURED CONTEXT-RICH WARNING + historical-marker | §6.3 |
| D9 | Forgejo/Gitea support | Architect POQ-5 | KEEP design as v11.1+ forward-pointer; DEFER `provider_sub_issue_reprioritize` op | §5.2, §7 |
| D10 | gh CLI version-pin strategy | Architect POQ-6 | `gh api graphql` routing (avoids version-pin) | §5.1 |
| D11 | NEW `tracker-phase-part.sh` library | Architect POQ-7 | ACCEPTED new file (parallel to `tracker-phase-task.sh`) | §10.1, §14.2, §14.9 |
| D12 | `pack-id-v2` marker backfill | Architect POQ-8 | LAZY — only Part-expanded tasks gain v2 marker | §4.1, §6.3 |
| D13 | Issue Fields name collision | Architect POQ-9 | Capability-detection + `Pack Execution Order` fallback name | §5.1 |
| D14 | Mid-development phase position | Architect POQ-10 | Append to END of sub-issue priority order (GH default) | §5.2 |
| D15 | Task letter-suffix removed; task numbering rule clarified | User-driven (2026-05-26 POQ-4 discussion) | Letter suffix REJECTED grammar-wide; Task-M integer-only; new tasks get next integer; task number ≠ execution order; cross-refs strict | §4.1, §4.1a (NEW), §4.7 |
| D16 | Convention Y: v11.0 archive intra-file additive-extension allowed | User-driven (2026-05-26 POQ-6 discussion) | Structural shape frozen at 5 subdirs; intra-file content may evolve via backward-compatible additive extensions; admits D5 cancelled state addition to phase-task-v11.0/SCHEMA.md + v11.0/INDEX.md forward-reference footnote | §10.1 |

The full decision rationale lives in the Pack Chat session transcripts 2026-05-25 (sessionId `f6d6104f-9268-42ff-90cf-ac8ae35433e3`) + 2026-05-26 (planner POQ resolution session) per pack memory convention.

### §1.5 — Architect-pass scope

This document is **design only**. It does not contain implementation code, file diffs, or commit sequencing. The downstream planner pass converts this design into ordered commits; the coder pass implements each commit; the reviewer pass verifies. Architect deferrals were originally surfaced as POQs (Pending Open Questions); ALL 10 POQs + 3 derivative design decisions + INV-7 breach acceptance = 14 decisions were resolved 2026-05-25 per Pack Chat decision-review session — see §1.4 Decision log for the full audit trail. §12 carries the resolution reference; the original POQ table is preserved in git history.

---

## §2 — Inputs read

The following authoritative inputs were read in full at HEAD 4d1f9e5 before drafting this design. Citations in subsequent sections refer to these inputs.

| # | Path | Sections read | Purpose |
|---|---|---|---|
| 1 | `maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-PARTS-AND-ORDERING.md` | §1-§13 in full | Primary fact base; touch-point table; GH-native capabilities; immutability invariants; 17 observations; architect's worksheet |
| 2 | `pack-ops/BACKLOG.md` BD-185 entry (lines 1744-1789) | Full entry | P1-P4 problem statements; SC1-SC8; Out of scope; Pipeline; File/Symbol candidate list |
| 3 | `supporting-docs/METHODOLOGY.md` | Part 3 § "Planner trigger rule"; Part 4 § "Phase Structure" / § "Phase numbering rules" / § "Multi-part phases"; Part 5 § "Multi-part phase report headers" / § "Workflow 2" / § "Workflow 4"; Part 2 § "STATUS.md" rule + table-row purpose; Part 9 § "File-write authority" | Source-of-truth for Part term + Multi-part phase grammar + Execution note + Phase numbering + STATUS.md role |
| 4 | `maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md` | §1 design principles; §2 C1-C7 constraints (esp. C1 phase-N.Part-M reference); §3 capability disposition; §4 capabilities #1-#5 + #10 + #14 | Constraint C1 (Parts NEVER grouping members); cross-feature integration anchors |
| 5 | `maintenance-docs/v11-research/HANDOFF-V11.1-ARCHITECT.md` | "What's locked vs what's yours to design"; § Reading order | Confirm groupings architect pass deferred; groupings architect surfaces (#10 sync, #11 capability matrix) not yet decided |
| 6 | `scripts/lib/tracker-provider.sh` | Lines 120-143 (18-op public API + dispatcher) | Existing op surface; new ops needed for BD-185 |
| 7 | `maintenance-docs/v11-implementation/ARCHITECTURE-BD-182.md` | §4 + §4.1 + §4.1.1 + §5 + worked examples | Canonical reference table for any cross-CLI references; TOOL-SPECIFIC vs TOOL-NEUTRAL decision criteria |
| 8 | `maintenance-docs/v11-research/templates-archive/v11.0/phase-epic-v11.0/SCHEMA.md` | §1-§4 | Identifier scheme; body marker trio; label family; body section grammar |
| 9 | `maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md` | §1-§4 (per inventory §3.B.2 cite) | Phase-task identifier scheme; parent rule (one phase epic only) |

**HEAD SHA at start of read:** 4d1f9e5.

---

## §3 — Observations triage (§12 challenge per USER-LOCKED directive)

Every observation in inventory §12 receives a verdict (LOAD-BEARING / OUT-OF-SCOPE / CONTAMINANT) with evidence citation. All 17 covered.

| §12.N | Observation summary | Verdict | Evidence + rationale |
|---|---|---|---|
| §12.1 | METHODOLOGY.md line citations in BD-185 prompt are stale | OUT-OF-SCOPE | Verified: section names are correct, line numbers drifted. This document cites by section name per `project-template/CLAUDE.md` § "Filename uniqueness heuristic". No design impact. |
| §12.2 | Three competing Part-id grammar proposals at HEAD | LOAD-BEARING | Superseded by USER-LOCKED C-1 grammar (2026-05-25). §4.1 of this design specifies the grammar; three legacy sites identified for update in §11. |
| §12.3 | Mirror generator emits phases in lexical order, not integer order | LOAD-BEARING | Worked example: phase-10.md sorts before phase-2.md under `LC_ALL=C sort` (verified in `pe_sort_entries` function in `scripts/lib/per-entry/_lib.sh`). Execution-order mechanism design (§5) must specify how the mirror is sorted post-BD-185. |
| §12.4 | Tracker reverse migration emits phases in integer order | LOAD-BEARING | Verified `_tmr_emit_implementation_plan` and `_tmr_emit_status` functions in `tracker-migrate-reverse.sh` sort phases by `int(phase_number)`. §5 + §6 specify reverse-emit behavior when execution-order is present. |
| §12.5 | `sort by created_at DESC` is typical GH issue browse order | LOAD-BEARING | Creation-order divergence from execution order is exactly P3. §5 design accounts for the divergence. |
| §12.6 | "No pack-side IMPLEMENTATION_PLAN.md" | CONTAMINANT (per user note 2026-05-25) | Verified: pack repo has no IMPLEMENTATION-PLAN at any cut (`ARCHITECTURE-V3.md:603`); v11.0 file is `IMPLEMENTATION-PLAN.md` (hyphen, not underscore) and is a directory tree per Addendum #1 BD-167. The observation as written conflates pack vs project surface AND uses outdated filename. Design does NOT introduce pack-side IMPLEMENTATION-PLAN surface (would violate the separation rule). BD-185 commit scope-keyword `pack-only` is appropriate because edits land in `scripts/`, `pack-ops/`, `supporting-docs/`, `project-template/` (the last is pack-shipped client content, owned by pack — counts as pack scope for CI Check 36 purposes). |
| §12.7 | Provider abstraction lacks sub-issue-reprioritize op | LOAD-BEARING | §5.2 + §7 add `provider_sub_issue_reprioritize` as a new op (designed in v11.0 surface; implementation deferred to v11.1+ per D9; v11.0 ships at 18→20, v11.1+ at 20→21). Forgejo/Gitea fallback uses it. |
| §12.8 | Issue Fields (§4.7) is NEW; EXTERNAL-RESEARCH.md stale | LOAD-BEARING | C-2 mandates Issue Fields as primary mechanism. §5.1 design follows §4.7 cite of `2026-03-12` (public preview) + `2026-05-21` (all-orgs) changelog posts. EXTERNAL-RESEARCH.md is not used as Issue Fields authority. |
| §12.9 | Cross-CLI dimension (Codex / Gemini) | LOAD-BEARING | C-5 + trinity rule + `ARCHITECTURE-BD-182.md` §4.1 govern any cross-CLI reference. METHODOLOGY.md edits (single file copied identically to `docs/pack/`) require no per-CLI divergence. Project-template trinity edits (if any — most BD-185 work is scripts + form-family + schemas) follow Override 9 carve-out only for CLI-specific paths. §11 names trinity-affected surfaces (none anticipated at design time). |
| §12.10 | Issue dependency cap (50 per issue) | OUT-OF-SCOPE | Design (§5) does NOT use block/blocked-by chains as the ordering mechanism. The cap remains a phase-dependency concern, not an ordering concern. |
| §12.11 | No pack-verb for phase split / Part introduction today | LOAD-BEARING | Design (§4.5 + §10) introduces `pack phase split` and `pack tracker phase split` verbs to mediate mid-work expansion. New pack-tracker.sh + HELP-FRAGMENT edits anticipated. |
| §12.12 | Single-Part-no-suffix asymmetry (0 Parts or 2+ Parts; never 1) | LOAD-BEARING | Design (§4.4) preserves this invariant: a phase has either ZERO Parts (default; never instantiated) or 2+ Parts (post-expansion). No "Part 0" implicit state; no `has_parts: true/false` field; the existence of Part entities IS the signal. |
| §12.13 | task_order is per-phase, not per-Part | LOAD-BEARING | Design (§4.6 + §8.1) keeps `task_order` per-phase (preserves backward compatibility with v11.0 sidecar shape). Per-Part task membership is expressed via sub-issue parentage (Part is sub-issue parent of its member tasks); membership round-trip via tracker → flat-file uses sub-issue traversal at reverse-emit time. |
| §12.14 | Part state taxonomy is undefined | LOAD-BEARING | Design (§4.7) defines Part state taxonomy: `pending / in-progress / done / deferred`. Excludes `merged-into:` and `superseded-by:` (Parts cannot be merged or superseded — they expand a phase mid-work and remain part of that phase's permanent history; the phase epic itself absorbs lifecycle complexity). |
| §12.15 | METHODOLOGY's "Insert new phases at the end" rule | LOAD-BEARING | This rule IS the root cause of P3. INV-1 preserves it. Design (§5) makes execution order an explicit mechanism orthogonal to birth-order phase numbering. |
| §12.16 | Two passes of phase-state vocabulary | OUT-OF-SCOPE for BD-185 | The phase-epic open/closed vs flat-file pending/in-progress/done/deferred/merged-into/superseded-by reconciliation is a v11.0 carry-over (pre-BD-185). Part state taxonomy is defined fresh in §4.7. Recommend a follow-up BD if reconciliation is desired, but BD-185 does not depend on it. |
| §12.17 | Per-entry filename uniqueness vs Part-id | LOAD-BEARING (preventive) | Design (§4.6) keeps Parts INLINE inside `phase-N.md` (no new per-entry file pattern like `phase-N.Part-a.md`). No filename collision risk introduced. |

**Triage summary:** 14 LOAD-BEARING, 2 OUT-OF-SCOPE, 1 CONTAMINANT. Every load-bearing observation maps to a design section below. No observation is silently skipped.

---

## §4 — Parts mechanism design

### §4.1 — Part identifier grammar (USER-LOCKED C-1)

The grammar is USER-LOCKED 2026-05-25. This section enumerates the canonical forms and validates that they satisfy SC1/SC2/SC3 + INV-1/INV-2/INV-3.

**Atomic identifiers:**

| Atom | Grammar | Examples | Notes |
|---|---|---|---|
| Phase | `Phase-N` where `N` matches `[1-9][0-9]*` (integer; no leading zero except `0`; pack uses 1-indexed phases, but `Phase-0` is legal for v10-compat) | `Phase-1`, `Phase-7`, `Phase-23`, `Phase-60` | INV-1 holds: N is birth-order, immutable. |
| Part | `Part-x` where `x` matches `[a-z]` (single lowercase ASCII letter) | `Part-a`, `Part-b`, `Part-c` | Up to 26 parts per phase. If a phase ever exceeds 26 parts, that is an architect-pass review trigger — not a BD-185 default case (planner triggers cap at 5+ tasks; 26-part phases are out of design scope). |
| Task | `Task-M` where `M` matches `[1-9][0-9]*` (integer only; NO letter suffix per D15) | `Task-3`, `Task-7`, `Task-23` | M is birth-order ordinal per INV-2; task numbering is integer-only; new tasks always get next available integer after the last task in the phase. |

**Composite identifiers:**

| Form | Shape | Examples | Use |
|---|---|---|---|
| With Part | `Phase-N.Part-x.Task-M` | `Phase-1.Part-a.Task-3`, `Phase-7.Part-b.Task-12` | Used after mid-work split when a task belongs to a specific Part |
| Without Part (null-Part) | `Phase-N.Task-M` | `Phase-2.Task-7`, `Phase-12.Task-3` | DEFAULT for phases without Parts (most phases). Skip the `.Part-X` segment entirely. |
| Phase-only | `Phase-N` | `Phase-7` | Reference the phase epic itself |
| Part-only | `Phase-N.Part-x` | `Phase-7.Part-a` | Reference a specific Part epic (when Parts exist on the phase) |

**Prohibited forms:**
- Empty separator: `Phase-2..Task-7` — REJECTED by C-1. The null-Part form skips the segment ENTIRELY (no `..`).
- Lowercase `phase` / `part` / `task`: REJECTED. The grammar uses capitalized atoms. (Rationale: matches METHODOLOGY's existing `Phase N` / `Part M` prose; visual scan distinguishes identifiers from English; aligns with `Phase-N` / `Part-M` proposals in inventory §12.2.)
- Numeric Part identifier: REJECTED per C-1. Numeric Parts would collide with the existing `phase-N.M` legacy convention (which uses dot-separator for tasks).
- **Letter suffix on Task** (e.g., `Task-Md`, `Task-3a`): REJECTED per D15. Rationale: task numbers are birth-order ordinals per INV-2; letter suffix as positional indicator contradicts birth-order semantic. Insertion semantic uses dependency edges (`blocked-by` / `blocks`), not letter suffix. New tasks always get next available integer.

**Backward-compatibility legacy form retained:**

The existing v11.0 task pack-id `phase-N.M` (lowercase, with dot-separator, no letters) MUST continue to resolve. Per INV-2, existing task IDs do not renumber. The design adopts the following compatibility shim:

- Existing v11.0 phase tasks carry pack-id `phase-N.M` (lowercase) in their body marker AND a parallel `<!-- pack-id-v2: Phase-N.Task-M -->` marker when the phase undergoes mid-work Part expansion. Both markers reference the same entity (the task issue). Parsers prefer `pack-id-v2` when present; fall back to `pack-id` otherwise.
- New phase tasks created AFTER BD-185 lands carry both markers from creation.
- Migration step (§6) backfills the `pack-id-v2` marker on existing tasks LAZILY per D12 — only tasks in phases that undergo Part expansion receive the v2 marker. Most v11.0 tasks remain v1-only (`pack-id: phase-N.M`); the v1 marker continues to resolve in all parsers.

**Rationale (defensive justification for C-1 acceptability):**

The C-1 grammar is more verbose than the proposed alternatives (`phase-N.Part-M`, `phase-N.M`, `part:M`) but is **unambiguous in all referencing contexts**. The two-atom prefix (`Phase-N.Part-a`) immediately reveals that `Part-a` is a Part identifier (not a task), distinguishing it from `Phase-N.M` (which is a task). The letter-vs-integer dichotomy (`Part-a` vs `Task-3`) prevents ambiguity in mid-form references (e.g., `Phase-1.a` would be ambiguous; `Phase-1.Part-a` is not). The architect does NOT propose an alternative — C-1 satisfies the usage-logic + concision-balance test stated by the user.

### §4.1a — Task numbering rule — task number ≠ execution order

**Task numbering rule (per D15 + INV-2):**

- Task IDs are birth-order ordinals. M = the order in which the task was created within its phase. Stable; immutable across renames, reorders, supersessions.
- New tasks always get the next available integer after the last task in the phase. For example: if Phase 7 currently has Task-1 through Task-12, the next task created is Task-13. Even if Task-3 has been cancelled or superseded, Task-13 is still the next.
- **Task number does NOT define execution order.** Execution order is governed by: priority, dependencies being unblocked (`blocked-by` / `blocks` edges), and optional parallel-implementation optimizations.
- Execution order has its own mechanism (per §5). The per-phase Issue Field (tracker mode) or `<!-- execution-order: NNN -->` marker (flat-file mode) is the execution-order SSOT.
- Cross-references to task IDs are STRICT: `Phase-7.Task-3` refers to that exact entity. There is no 'family' resolution (e.g., `Task-3` and a hypothetical `Task-3a` are separate concepts and the latter doesn't exist by grammar).

### §4.2 — Part as a tracker entity (SC2 mandate)

SC2 requires mid-work phase expansion to work in tracker mode. The existing METHODOLOGY-only Part mechanism (H3 sub-sections in IMPLEMENTATION-PLAN.md) does not survive tracker sync (the H3s would be captured as inline content within the phase epic body, but there is no first-class Part entity that can carry sub-issue parentage of tasks). Therefore Parts MUST be tracker entities in tracker mode.

C-2(2) Issue Fields shape for Part identity is REJECTED — Parts are first-class sub-issue entities (per this section's decision), not Issue Field annotations on phase tasks. Issue Fields are reserved for execution-order (§5.1).

**Decision: Parts are sub-issue children of phase epics, and sub-issue parents of phase tasks.** This places Parts at sub-issue depth 2 (under phase epic at depth 1; tasks at depth 3). Sub-issue depth cap is 8 levels per `EXTERNAL-RESEARCH.md:53` and inventory §4.1; 100 children per parent; 1 parent per child. All caps respected.

**Hierarchy comparison:**

```
Pre-BD-185 (current v11.0):
  Phase Epic (phase-N)
  └── Phase Task (phase-N.M)  [sub-issue parent = phase epic]
  └── Phase Task (phase-N.M)
  ...

Post-BD-185, phase WITHOUT Parts (default — most phases):
  Phase Epic (phase-N)         [pack-id: phase-N; pack-id-v2: Phase-N]
  └── Phase Task (phase-N.M)   [pack-id: phase-N.M; pack-id-v2: Phase-N.Task-M]
  └── Phase Task (phase-N.M)
  ...

Post-BD-185, phase WITH Parts (post-expansion):
  Phase Epic (phase-N)                       [pack-id-v2: Phase-N]
  ├── Phase Part (phase-N.Part-a)            [pack-id-v2: Phase-N.Part-a]
  │   ├── Phase Task (phase-N.M)             [pack-id-v2: Phase-N.Part-a.Task-M]
  │   └── Phase Task (phase-N.M)
  └── Phase Part (phase-N.Part-b)
      └── Phase Task (phase-N.M)
```

**Re-parentage during expansion (SC2 + SC3 + INV-3 preservation):**

Mid-work expansion adds Part entities AND re-parents existing phase task issues from "child-of-phase-epic" to "child-of-phase-part". This is a sub-issue-parent change ONLY; the task issue retains:
- Its tracker entity ID (GH Issue number) — INV-3 preserved.
- Its body marker pack-id (`phase-N.M`) — INV-2 preserved.
- Its parallel `pack-id-v2` marker — updated from `Phase-N.Task-M` to `Phase-N.Part-a.Task-M` (recorded change is to the optional v2 marker; the v1 marker stays).
- Its labels (`phase-task`, `phase-N`, `template:phase-task-v11.0`).
- Its dependencies (Blockers / Unblocks).

The re-parentage uses the existing `provider_sub_issue_unlink` + `provider_sub_issue_create` op pair. Cost: 2 API calls per re-parented task. For typical phases with 5-10 tasks split into 2-3 Parts, expansion is 10-30 sub-issue ops + N Part-creation ops — well within the 5,000 req/hr rate budget (inventory §4.12).

### §4.3 — Form-family extension (SC6 + INV-7 + INV-8)

SC6 requires the smallest template_version delta consistent with BD-068 form-family rules. INV-7 + INV-8 cap the `wi-type` dropdown at 4 options as a soft cap (V2 §17 R11). BD-185 requires a 5th option for Part creation.

**Decision: Add `phase-part-skeleton` as the 5th `wi-type` option.**

**Defense of BD-068 soft-cap breach (5 options instead of 4):**

The 4-option soft cap was set in V2 §17 R11 as a usability heuristic — GitHub Issue Forms dropdowns become hard to scan past 4-6 options on mobile. Phase-part-skeleton is the rare-case fallback path (like phase-epic-skeleton and phase-task-skeleton today), not the common path. Day-to-day, Parts are created programmatically by `pack tracker phase split` or by the planner agent's IMPLEMENTATION-PLAN.md edits + sync. Form-based Part creation is a fallback for projects without pack tooling (e.g., bare clone, missing scripts).

The 5-option dropdown is acceptable because:
1. **All five options follow the same naming convention** (`bd`, `td`, `phase-epic-skeleton`, `phase-task-skeleton`, `phase-part-skeleton`) — pattern-recognition compensates for length.
2. **Rare-case use** — three of the five (phase-epic-skeleton, phase-task-skeleton, phase-part-skeleton) are intentional fallbacks. The typical user encounters only `bd` and `td`. The soft cap's mobile-scanability concern applies to common-path options, not to fallback options that most users never select.
3. **No path forward without the breach** — Parts MUST be creatable via the form for projects that don't run the pack scripts. Skipping the form is a worse UX than 5 options.

**Form-field additions (project-template/.github/ISSUE_TEMPLATE/work-item.yml + pack-side mirror):**

| Field | Type | Conditional | Description |
|---|---|---|---|
| `wi-phase-number` | input (existing) | now also applies to `phase-part-skeleton` | "Phase the Part belongs to. Use 'N'." |
| `wi-part-letter` | input (NEW) | `phase-part-skeleton` only | "Part letter. Use 'a', 'b', 'c', etc. — next available letter under phase N." |
| `wi-blockers` | textarea (existing) | unchanged | Description text updated to admit `Phase-N.Part-x` form (per §4.1 grammar). |
| `wi-unblocks` | textarea (existing) | unchanged | Same. |
| `wi-dependencies` | textarea (existing) | unchanged | Same (admit `Phase-N.Part-x` and `Phase-N.Part-x.Task-M` forms). |

**Template archive cut:** v11.0 is closed (5 entry-type subdirs). v11.1 is the cut for BD-185 work. NEW archive directories:
- `maintenance-docs/v11-research/templates-archive/v11.1/phase-part-v11.1/` (NEW; SCHEMA.md defines Part body marker trio + body grammar + label family + state taxonomy)
- `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md` (NEW; enumerates 6 entry types: bd, td, phase-epic, phase-task, phase-part, inbound)
- `maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml` (NEW; byte-identical archive of post-BD-185 live work-item.yml)

**Template_version delta (SC6 — smallest possible):**

| Entry type | v11.0 | v11.1 | Reason for change |
|---|---|---|---|
| `bd-v11.0` | bd-v11.0 | bd-v11.0 (unchanged) | No body marker or content change |
| `td-v11.0` | td-v11.0 | td-v11.0 (unchanged) | No body marker change |
| `phase-epic-v11.0` | phase-epic-v11.0 | phase-epic-v11.0 (unchanged) | Body marker trio unchanged; new Parts are children of phase epic via sub-issue parentage (graph-only); no body marker delta on the epic itself |
| `phase-task-v11.0` | phase-task-v11.0 | phase-task-v11.0 (unchanged) | Body marker trio unchanged; the optional `pack-id-v2` marker is ADDITIVE (not required for v11.0-era tasks; introduced for Part-aware tasks) and does NOT bump template_version per §4.1 backward-compat shim |
| `phase-part-v11.1` | (n/a) | phase-part-v11.1 (NEW) | NEW entry type |
| `inbound-v11.0` | inbound-v11.0 | inbound-v11.0 (unchanged) | No body marker change |
| `work-item-v11.0` (form) | work-item-v11.0 | **work-item-v11.1** (BUMP) | `wi-type` adds option; `wi-part-letter` field added; description fields admit Part-id forms |

**Total template_version delta: ONE new template (phase-part-v11.1) + ONE bumped template (work-item-v11.0 → work-item-v11.1).** Four existing templates unchanged. This is the smallest possible delta — any smaller would require Parts to be label-only (no body marker, no entity), which fails SC2 (mid-work tracker representation) and SC7 (round-trip).

### §4.4 — Part state taxonomy (§12.14 LOAD-BEARING)

| State | Tracker shape | Notes |
|---|---|---|
| pending | open + label `status:pending` | Part declared but no task started |
| in-progress | open + label `status:in-progress` | At least one task in this Part is in-progress |
| done | closed + state_reason `completed` | All tasks in this Part are closed-completed |
| deferred | closed + state_reason `not_planned` + label `status:deferred` | Part deferred mid-work; member tasks stay assigned (re-parenting forbidden per D4 — see §4.7 supersede-only rule). Trigger: all member tasks are in a terminal state (done / deferred / cancelled / superseded) but NOT all done — see §4.7 operational paths. |

**Excluded states (rationale):**
- `merged-into:` — Parts cannot be merged into another Part. The phase epic carries lifecycle complexity (`merged-into` is reserved for phase-level cross-phase merges per existing phase-task taxonomy).
- `superseded-by:` — Parts cannot supersede another Part. Same rationale.

**Lifecycle invariant:** Parts are CREATED via mid-work expansion. They cannot be created at phase-birth time (a phase begins with 0 Parts by §12.12 invariant). They cannot be deleted nor collapsed — collapse rejected as anti-pattern per D2 (§4.7); deletion would conflict with the no-collapse rule. Empty Parts forbidden at creation per D3 (every Part must have ≥1 task at creation). Mid-life task re-parenting between Parts forbidden per D4 (supersede only). Deferral is the only "exit" path for an unused Part.

### §4.4a — Phase task state taxonomy (extended per D5)

**Phase task state taxonomy (extended from 6 to 7 states per user direction 2026-05-25):**

| Marker | Status label | Tracker state | `state_reason` | Semantic meaning |
|---|---|---|---|---|
| (none) | `status:pending` | open | — | Planned work; not started |
| 🚧 | `status:in-progress` | open | — | Active work happening |
| ✅ | `status:done` | closed | `completed` | Work completed |
| ➡ | `status:deferred` | closed | `not_planned` | Put off — work may return later |
| ❌ | `status:cancelled` | closed | `not_planned` | **NEW** — decided not to do; permanent; not replaced |
| (note) | `status:merged-into:phase-N` | closed | `not_planned` | Work moved entirely to another phase |
| (note) | `status:superseded-by:phase-N.M` (or `Phase-N.Part-x.Task-M` per v2) | closed | `not_planned` | Replaced by another specific task |

The new `cancelled` state semantically distinguishes 'permanent rejection with no replacement' (cancelled) from 'put off for later' (deferred) and 'replaced by another task' (superseded-by). Reverse-emit grammar extension (per `phase-task-v11.0/SCHEMA.md`): `#### ❌ N.M <task title>` for `status:cancelled`.

Pack `phase-task-v11.0/SCHEMA.md` Section 3 (Label family) MUST be extended to include `cancelled` in the status enumeration: `status:<pending|in-progress|done|deferred|cancelled|merged-into:phase-N|superseded-by>`.

Validator extension: Check 35 gains `cancelled` as an admitted state value (per §10.1).

### §4.5 — Part creation verb (§12.11 LOAD-BEARING)

The pack today has no `pack phase split` verb. BD-185 introduces verbs to mediate Part creation programmatically.

| Verb | Mode | Surface | Behavior |
|---|---|---|---|
| `pack phase split <phase-N> --parts <count>` | flat-file | `scripts/pack-phase.sh` (NEW) | Splits a phase by introducing `Part-a`, `Part-b`, ..., `Part-{count}` H3 sub-sections in `docs/project/implementation-plan/phase-N.md`. Prompts user to assign existing tasks to Parts. Regenerates IMPLEMENTATION-PLAN.md mirror. |
| `pack tracker phase split <phase-N> --parts <count>` | tracker | `scripts/pack-tracker.sh` (extend) | Same as above + creates `phase-part-v11.1` sub-issues under the phase epic + re-parents tasks per user assignment. Updates id-map.json. |

The verbs are mediated (user is prompted to assign existing tasks to Parts) because a planner-agent invocation cannot reliably partition tasks without user judgment — this matches METHODOLOGY's existing "the planner agent recommends, the user approves" pattern.

### §4.6 — Per-entry tree integration (§11.1 + §12.17)

**Decision: Parts are INLINE inside `phase-N.md`. NO per-Part per-entry file (`phase-N.Part-a.md`).**

This preserves the BD-167 "tasks inline" decision and extends it to Parts. Rationale:
1. **Filename uniqueness.** Adding `phase-N.Part-a.md` introduces a new filename pattern; preserving inline keeps the existing 1-file-per-phase contract.
2. **Discoverability.** A user reading `phase-7.md` sees the entire phase in one place: H2 phase heading + H3 Parts (post-expansion) + H4 tasks under each Part. No file-hopping.
3. **Mirror behavior unchanged.** The decompose helper anchors on H2 (phase-N), captures everything to next H2 boundary; Parts as H3 fall within. No change to decompose / mirror-generate logic for Part-aware projects.
4. **Round-trip simplicity.** Forward migration sees Parts as H3 sub-sections inside the phase block and creates Part entities + re-parents tasks. Reverse migration sees Part sub-issues and emits H3 sub-sections inside `phase-N.md`.

**Phase task `task_order` (per §12.13):**

The existing per-phase `task_order` sidecar field (per `tracker_sidecar_compose_phase_tasks_block` function docstring in `tracker-sidecar.sh`) stays per-phase. When Parts are introduced, `task_order` continues to list ALL tasks in the phase in their original birth-order. Per-Part membership is expressed via sub-issue parentage in the tracker; in flat-file, by H3 sub-section grouping (`### Part a` H3 contains H4 task headers for its member tasks).

**Sidecar shape extension (§8.2):**

```yaml
phase_tasks:
  phase-N:
    task_order: [N.1, N.2, ...]         # unchanged: ALL tasks in phase
    parts:                              # NEW (optional; only present if Parts exist)
      Part-a:
        task_members: [N.1, N.3]        # tasks belonging to Part-a
        state: in-progress              # Part state per §4.4
      Part-b:
        task_members: [N.2, N.4]
        state: pending
    tasks:                              # unchanged
      phase-N.M:
        problem: <body>
        parent_phase: phase-N           # unchanged: parent_phase is always phase-N (tasks still belong to phase semantically)
        parent_part: Part-a             # NEW (optional; only present if task belongs to a Part)
        dependencies: [...]
        template_version: phase-task-v11.0
```

The `parent_part` field is optional and additive. v11.0 sidecar files load cleanly (no `parts` block, no `parent_part` per task).

### §4.7 — Phase task migration to Part membership

When a phase undergoes mid-work expansion:

1. User runs `pack phase split <phase-N> --parts 2` (or `pack tracker phase split ...` in tracker mode).
2. Verb prompts user: "Assign each of {existing tasks N.1, N.2, ...} to a Part: a, b". Default = all to Part-a (first Part).
3. Verb emits Parts + re-parents tasks (sub-issue ops in tracker mode; H3 sub-section grouping in flat-file).
4. Per-task `pack-id-v2` body marker updated from `Phase-N.Task-M` to `Phase-N.Part-a.Task-M` (or `Part-b`, ...).
5. `task_order` array unchanged (still phase-scoped).
6. `parts` block written to sidecar with `task_members` lists.

**Reverse operation (Part collapse) — REJECTED as anti-pattern per user direction 2026-05-25.** Once a phase has been split into Parts, the split is permanent. There is NO `pack phase collapse` verb in any release (not v11.0, not v11.1+, not ever).

Rationale (user direction 2026-05-25): A collapse operation would mutate the audit trail without operational benefit. Parts represent work-evolution history; removing them retroactively introduces dead references from docs, commits, and IMPL-REPORTs that reference Part identifiers.

Operational paths that don't require collapse:
- A Part with no active work can be marked `status:deferred` (per §4.4)
- A Part with all tasks completed naturally closes via `status:done`
- Tasks that need to move work to a different Part use `pack task supersede` (per D4 / §4.8) — original task stays in its original Part marked `status:superseded-by:Phase-N.Part-x.Task-M`; new task created in target Part with linked supersede pointer.

**Part creation rule (D3 — no empty Parts):** Every Part must contain at least one task at creation time. The `pack phase split` verb enforces this by rejecting splits that would leave any Part empty. Empty Parts cannot exist — placeholder Parts are not allowed.

Rationale (user direction 2026-05-25): No operational benefit to empty Parts; closes the edge case of empty-Part deletion (which would conflict with the no-collapse rule per D2); short-circuits any workflow that could auto-create Parts in an unbounded loop.

Operational flow for `pack phase split`:
1. Read existing tasks for phase N
2. Prompt user: 'Assign each task to a Part (a, b, c, ...)'
3. VALIDATE: every declared Part has ≥1 assigned task; reject the split with actionable error if any Part is empty
4. Emit Parts + re-parent tasks (one-time initial Part assignment)

NEW Check (CI validator extension): every Part entity in tracker has at least one task as a sub-issue child OR is marked `status:deferred`. Architect notes Check 44 (or next available number) for this.

**Mid-life re-parenting rule (D4 — supersede only):**

**Initial Part assignment (allowed; one-time at phase split):** When `pack phase split` runs, existing tasks gain a Part-parent for the first time. This is initial Part assignment, not re-parenting — the tasks previously had no Part-parent. Task IDs (`phase-N.M`) are immutable per INV-2.

**Mid-life re-parenting (FORBIDDEN per user direction 2026-05-25):** Once Parts exist, tasks DO NOT move between Parts. If work conceptually needs to move from Part-a to Part-b, the path is **supersession**: original task stays in Part-a marked `status:superseded-by:Phase-N.Part-b.Task-X`; new task created in Part-b with linked supersede pointer.

**Task immutability rule:** Once a task is assigned to a Part (at phase split time), the task remains in that Part forever. Tasks are never deleted; they are deprecated, superseded, or marked done/cancelled. See `pack task supersede` verb in §4.8.

There is NO `pack task reparent` verb. Any verb that conceptually moves a task between Parts explicitly errors with 'use `pack task supersede` instead' guidance.

### §4.8 — `pack task supersede` verb (D4 — new verb specification)

**`pack task supersede <old-task-id> --with <new-task-id-template>`**

Creates a new task in a specified target Part (or target phase, for cross-phase supersession) with content derived from (or independent of) the original task. Links the two via the supersede relationship:

- Old task: state transitions to `status:superseded-by:Phase-N.Part-x.Task-M` (the new task's ID). Old task body, body markers, sub-issue parentage, and Part membership stay byte-identical.
- New task: created in the target Part with content (identical, modified, or different — user's choice). Carries `<!-- pack-id: phase-N.M -->` + `<!-- pack-id-v2: Phase-N.Part-y.Task-M -->` per LAZY v2 marker rule (D12).

Cross-references in IMPL-REPORTs, BACKLOG, etc. to the OLD task ID continue to resolve (the entity exists; just marked superseded). Cross-references to the NEW task ID resolve to the new entity.

No `pack task reparent` verb exists. If invoked (e.g., by an old script reference), the verb fails with 'use `pack task supersede` instead'.

---

## §5 — Execution-ordering mechanism design

C-2 mandates Issue Fields as the chosen mechanism for v11+ execution ordering. This section specifies the Issue Fields shape, the non-JSON-sidecar fallback for trackers without Issue Fields, and the flat-file-mode behavior. Satisfies SC4 / SC5 / SC7 / SC8.

### §5.1 — Issue Fields shape for GitHub (primary path per C-2)

**Field definition (organization-level, defined once per org via `gh api graphql` or web UI):**

| Property | Value |
|---|---|
| Field name | `Execution Order` |
| Field type | `number` (per inventory §4.7: number is one of the 4 supported types) |
| Description | "Sort key for phase execution order. Smaller value = earlier execution. Sparse values allowed (gaps support insertion without renumber). Range: positive integer or floating-point." |
| Applies to | Phase epic issues only (pack writes the field on phase-epic issues at creation; phase tasks inherit ordering by virtue of belonging to their phase epic) |
| Default | (no value — null means "ordering not yet initialized") |
| Mutability | Pack-mutable via `provider_set_field` (NEW op — §7) |

**Field value semantics:**

- **Type:** integer or floating-point. Pack writes integers by default (e.g., 1, 2, 3, ...) but the field admits floats for fractional insertion (e.g., insert phase between order=2 and order=3 → write order=2.5).
- **Sparse:** gaps are allowed (e.g., orders [1, 3, 5, 7] is valid). Sparseness avoids renumber-on-insert.
- **Unique-per-phase:** not enforced by GH (Issue Fields don't have uniqueness constraints). Pack validates uniqueness at write time (`pack tracker phase reorder` verb — see §5.5).
- **Read semantics:** smaller = earlier. To execute phases in order, sort by `Execution Order` ascending; phases with null/missing value sort LAST (initial state for unmigrated phases) per `ORDER BY field NULLS LAST` convention.

**Why number (not single-select):**

- Single-select would require pre-defining all order values at field-definition time (e.g., enumerate "Phase 1", "Phase 2", ...). This is brittle: every phase insertion requires a field-schema update at org level (admin operation; not pack-mutable per inventory §4.7 "org-level definition").
- Number admits arbitrary values without schema change; pack can write any positive number. Aligns with the "sparse value, no renumber" goal.

**Why not preconfigured Priority/Effort:**

- Inventory §4.7 lists `Priority`, `Effort`, `Start date`, `Target date` as preconfigured fields. `Priority` is semantically wrong (priority ≠ execution order; high-priority phases can be deferred), and `Effort` is also semantically wrong (effort ≠ order). Using a preconfigured field for the wrong semantic would mis-communicate intent. Pack defines a dedicated `Execution Order` field.

**Per-organization 25-field cap impact:**

Inventory §4.7 documents 25 issue fields per org. Pack uses one slot (`Execution Order`). Pack-managed projects sharing an org pool one slot across all pack projects (assumption: pack projects per org share the same field definition). If a pack-managed project lives in an org that has reached the 25-field cap, the fallback path (§5.2) activates.

**Issue Fields name-collision handling (D13):**

Capability-detection at `pack tracker init` time: pack checks whether an `Execution Order` field already exists at the org. If a non-pack-controlled field with that name exists, pack falls back to the name `Pack Execution Order` (and uses the alternate name throughout for that project).

**tracker.toml schema extension (per Issue Fields name-collision handling):**

```toml
[execution_order]
field_name = "Execution Order"   # or "Pack Execution Order" if fallback
```

Set at `pack tracker init` time after capability-detection. Read by any verb that touches the field (`pack phase reorder`, `pack tracker doctor`, etc.). User can manually edit if they need to migrate to a different field name (advanced operation).

**`pack tracker doctor` extension:**

When `pack tracker doctor` runs, it verifies:
- The configured `field_name` exists at the org
- The field has type `number`
- The field is writeable by the authenticated user

Flags any mismatch as a diagnostic.

**Tool requirement:** GitHub access via Issue Fields requires `gh` CLI installed + authenticated. See `supporting-docs/DEPENDENCIES.md` for the full tracker-mode dependency set. BD-185 adds no new tool dependency beyond the existing tracker-mode requirement.

### §5.2 — Fallback mechanism for trackers without Issue Fields (NON-JSON-SIDECAR per C-2)

Forgejo, Gitea, and any tracker without an Issue-Fields-or-analog mechanism uses sub-issue reprioritize against a designated "phase-order-root" issue.

**Mechanism:**

1. At `pack tracker init` time, pack creates a singleton "phase-order-root" issue (title: `Phase order root (do not modify directly)`, labels: `phase-order-root`, `pack-internal`, `template:phase-order-root-v11.1`). Body marker: `<!-- pack-id: phase-order-root -->`.
2. All phase epics are linked as sub-issues of the phase-order-root.
3. Phase execution order = sibling order under phase-order-root (the sub-issue reprioritize endpoint provides total order).
4. Pack writes order via `provider_sub_issue_reprioritize` (NEW op — §7); reads order via `provider_sub_issue_list` (existing op; returns child IDs in sibling order).

**Mid-development phase position (per D14):**

When a new phase is added mid-development to a phase-order-root fallback project, the new phase appears at the END of the sub-issue priority order by default. This matches GitHub's default sub-issue create behavior (new sub-issues append to the end of the sibling list). The user can run `pack tracker phase reorder` post-creation to move the new phase to a different execution position.

**Why sub-issue reprioritize (not labels):**

The user's C-2 directive enumerates label namespace as an option to evaluate. Sub-issue reprioritize is chosen over labels because:
- **Total order without label proliferation.** With 50+ phases, label namespace `order:001`, `order:002`, ... bloats the label set (50 labels just for ordering; one per phase). Sub-issue reprioritize uses a single root issue + sibling positioning.
- **Mutation cost.** Reordering with labels requires label-set updates per affected phase. Reordering with sub-issue reprioritize is one API call (PATCH `/sub_issues/priority`).
- **Read cost.** `provider_sub_issue_list` already returns sibling order; no extra read pass needed.
- **Padding-sensitivity avoided.** Labels with `LC_ALL=C sort` would require zero-padding (e.g., `order:001` to sort before `order:010`); sub-issue reprioritize is order-explicit (not lexical).

**Backend support matrix:**

| Backend | Issue Fields support | Fallback mechanism |
|---|---|---|
| GitHub (Issues) | Yes (preview; per inventory §4.7) | Issue Fields `Execution Order` |
| GitLab | Yes (Custom Fields since 2024 per inventory §4.7 mentions) | Custom Fields (primary-source verification at implementation-time per D6) |
| Linear | Yes (Properties, mature, GA) | Properties `Execution Order` |
| Jira | Yes (Custom Fields, mature, GA) | Custom Fields `Execution Order` |
| Redmine | Yes (Custom Fields, mature) | Custom Fields `Execution Order` |
| Forgejo | No | Sub-issue reprioritize against phase-order-root issue |
| Gitea | No | Sub-issue reprioritize against phase-order-root issue |

Per BD-185 entry "Out of scope" — non-github backends are RESERVED. The design enumerates them for forward planning but BD-185 implementation only covers GitHub (Issue Fields). The other backends inherit the abstract `provider_set_field` op when implemented in their respective tracker-provider libraries (no v11.0 work).

**Forgejo/Gitea support (per D9):** DESIGNED for v11.1+ implementation; NOT shipping in v11.0. The fallback design (sub-issue reprioritize against `phase-order-root` singleton) is documented here as forward-pointer; v11.1+ implementation pass will refine and verify the Forgejo/Gitea sub-issue API contract.

In v11.0: GH primary path (Issue Fields) ships; flat-file mode ships; no fallback tracker path active.

**Capability detection:**

The `provider_capabilities` op (existing — `provider_capabilities` function in `tracker-provider.sh`) gains a new capability flag:
- `execution_order.mechanism = "issue_fields"` (GitHub default; future Linear/Jira/GitLab/Redmine)
- `execution_order.mechanism = "sub_issue_reprioritize"` (Forgejo/Gitea fallback; GitHub at org-cap-exhausted edge case)
- `execution_order.mechanism = "none"` (declared unsupported; pack falls back to flat-file ordering only)

Pack reads capability at tracker init and writes per-mechanism. Migrator initialization (§6) reads the capability before writing initial values.

### §5.3 — Flat-file mode execution ordering

In flat-file mode there is no tracker; ordering lives in the per-entry tree.

**Decision: Extend the existing METHODOLOGY `> **Execution note**:` convention with a typed body marker AND add per-entry-tree ordering support.**

**In `phase-N.md` body (per-entry tree):**

```markdown
<!-- back-pointer: docs/project/IMPLEMENTATION-PLAN.md -->
<!-- pack-id: phase-N -->
<!-- pack-id-v2: Phase-N -->
<!-- execution-order: 3 -->

## Phase N — [Title]

**Goal**: ...
**Prerequisite**: ...
> **Execution note**: (optional human-readable explanation of the order)
```

The new `<!-- execution-order: NNN -->` HTML-comment marker is parseable by the per-entry tools and ignored by Markdown viewers. The existing `> **Execution note**:` prose remains for human-readable context (e.g., "runs between Phase 3 and Phase 4 despite higher birth-order number").

**Mirror generation sort order (§12.3 LOAD-BEARING):**

The current mirror generator (`scripts/lib/per-entry/mirror-generate.sh` + `pe_sort_entries` function in `scripts/lib/per-entry/_lib.sh`) uses `LC_ALL=C sort` on filenames — lexical, not integer-aware. Worked example: `phase-10.md` sorts before `phase-2.md`.

**Decision: Mirror generator sorts by `execution-order` marker value (ascending), then by phase number (ascending) as tie-breaker, then by filename (lexical) as final tie-breaker.**

Implementation: extend `_lib.sh:pe_sort_entries` with a new sort key extractor for the `project-implementation-plan` stream. Read each entry's `execution-order` marker (default to phase number if missing; default to filename if both missing). Sort by `(execution-order, phase_number, filename)` tuple.

This produces:
- Greenfield projects (no execution-order markers): order = phase number = creation order. Matches user intuition.
- Projects with execution-order markers: order reflects the marker. Mirror file emits phases in execution order.
- v10→v11 migrated projects (no markers initially): order = phase number — equivalent to "current implementation order" per P4. Migrator (§6) backfills markers as part of the migration sweep.

**Per-entry supporting file (NEW, LOCKED per D7):**

Per `_rules.md` convention, supporting files include `_rules.md`, `_intro.md`, `_toc.md`. BD-185 introduces:
- `_order.md` — human-readable list of phases in execution order, regenerated by `pack mirror-generate` from the SSOT (similar to `_toc.md`).

Per D7 (user direction 2026-05-25), `_order.md` is LOCKED as a separate per-entry supporting file — Option Y in the original POQ-3 framing. See §5.X Execution-order SSOT (below) for the SSOT-vs-view contract and BD-189 groupings forward-pointer.

### §5.X — Execution-order SSOT location (D7)

The execution-order single source of truth (SSOT) lives on the PHASE ENTITY itself:

- **Tracker mode:** per-phase Issue Field value (`Execution Order` field or `Pack Execution Order` fallback name per D13)
- **Flat-file mode:** per-phase HTML-comment marker `<!-- execution-order: NNN -->` on each `phase-N.md`

`_order.md` is a **regenerated view of the SSOT — never the source of truth.** When a user runs `pack phase reorder`, the verb mutates the SSOT (Issue Field value or HTML-comment marker); `_order.md` regenerates from the new SSOT state at next mirror-generate pass.

**Pattern extensibility for v11.1+ groupings:** If BD-189 groupings/stream later needs a `_order.md` for grouping execution order, the pattern follows the same shape:
- Grouping execution-order SSOT lives on the grouping entity (Issue Field or flat-file marker)
- `groupings/_order.md` is a regenerated view
- **Phase execution-order SSOT remains authoritative** for the phase's global execution position; grouping ordering is grouping-internal display, not an override
- BD-189 architect MUST honor this SSOT principle when designing grouping ordering reconciliation

Forward-pointer: BD-189 groupings implementation cross-references this §5.X for the SSOT pattern.

### §5.4 — SC5 — STATUS.md role (LOCKED)

STATUS.md does NOT become an ordering SSOT. The design honors INV-9.

Per inventory §3.K and BD-185 SC5, STATUS.md remains a dashboard. The execution-order mechanism (Issue Fields or per-entry-tree marker) is the SSOT in tracker mode and flat-file mode respectively. STATUS.md DISPLAYS execution order — it does not own it.

**STATUS.md emission update:**

When STATUS.md is regenerated (from tracker or from flat-file), the phase table is sorted by execution order (not phase number). This is a DISPLAY change, not an ownership change. STATUS.md continues to read order from the source (tracker Issue Fields or flat-file `execution-order` markers). Implementation lives in `_tmr_emit_status` function in `tracker-migrate-reverse.sh` — modify the phase sort key from `phase_number` to the read execution-order value.

### §5.5 — Reorder verb (new pack verb)

| Verb | Mode | Surface | Behavior |
|---|---|---|---|
| `pack phase reorder` | flat-file | `scripts/pack-phase.sh` (NEW per §4.5) | Interactive: reads current order from `execution-order` markers; presents phases sorted by current order; user reorders via index swap; rewrites markers in `phase-N.md` files; regenerates mirror + STATUS.md. |
| `pack tracker phase reorder` | tracker | `scripts/pack-tracker.sh` (extend) | Same UX; writes via Issue Fields (or fallback mechanism); reads via `provider_get` per phase. |

Reordering does NOT touch phase numbers (INV-1) or task IDs (INV-2). It only updates the execution-order value (Issue Fields or marker).

---

## §6 — Migration design

Satisfies SC8: v10→v11 + v11.0 flat→tracker migrators pass pre-existing whole-number phases through unchanged AND initialize the execution-order mechanism from current implementation order.

### §6.1 — v10 → v11 migrator (BD-119 framework)

Per inventory §10.1, the v10 → v11 migrator runs in two phases (A = local file changes; B = optional tracker integration). BD-185 affects both.

**Phase A changes (`scripts/lib/migrate-v10-to-v11/`):**

1. **Per-entry decompose step (existing):** The decompose step (`_v10_to_v11_decompose_streams`) reads v11-shape monolithic IMPLEMENTATION-PLAN.md and emits per-entry `phase-N.md` files. BD-185 extends:
   - On emit of each `phase-N.md`, write the body-marker quad: `<!-- back-pointer: ... -->`, `<!-- pack-id: phase-N -->`, `<!-- pack-id-v2: Phase-N -->`, `<!-- execution-order: NNN -->`.
   - `execution-order` value = the phase's position in the IMPLEMENTATION-PLAN.md (1-indexed) per "current implementation order" (P4). For OT-style projects with phases in birth-order = execution-order, the value matches phase_number. For projects with execution-note prose, the migrator does NOT parse the prose for auto-ordering (D8 default to phase_number); instead it emits the structured context-rich warning per §6.3a for user interpretation.

2. **Multi-part phase handling (NEW):** If a v10 IMPLEMENTATION-PLAN.md contains `### Part 1` / `### Part 2` H3 sub-sections inside a phase (i.e., the planner introduced Parts in v10 before BD-185 shipped), the migrator:
   - Preserves the H3 sub-sections inline in the emitted `phase-N.md` (decompose anchors on H2; Parts as H3 are content within the phase entry).
   - Does NOT create Part tracker entities during Phase A (Phase A is local-file-only).
   - Logs a notice: "Multi-part phase detected at phase-N. Run `pack tracker init` (Phase B) to create Part tracker entities."

**Phase B changes (optional tracker integration):**

1. **Initialize Issue Field at tracker init:** `pack tracker init` provisions the `Execution Order` field at the org level (or detects existence + use). For Forgejo/Gitea-class trackers, creates the phase-order-root issue instead.
2. **Initial-order write:** After all phase epics are created, the migrator writes execution-order values (1, 2, 3, ..., N) corresponding to current implementation order. For OT-style projects, this is phase_number ascending.
3. **Multi-part phase entity creation:** If decompose detected H3 Parts (per Phase A item 2), `pack tracker init` creates Part sub-issues + re-parents tasks per the H3 structure.

### §6.2 — v11.0 → v11.1 forward migration (flat → tracker)

This is the path for v11.0 projects (flat-file mode) opting into tracker mode at any v11 minor cut.

**Migrator step extensions:**

| Step | Existing behavior | BD-185 addition |
|---|---|---|
| Step 5: For each phase, create phase epic | Existing | Read `execution-order` marker from `phase-N.md`; pass to `provider_create` for inclusion in the Issue Fields write (post-create `provider_set_field` call) |
| Step 5.5: For each phase with H3 Parts (NEW) | (none) | Create `phase-part-v11.1` sub-issues; re-parent tasks per H3 grouping |
| Step 7b: phase-task Dependencies | Existing (`tracker-migrate-forward.sh`) | Admit `Phase-N.Part-x` form in dependency targets |
| Step 8: Write Issue Field values (NEW) | (none) | After all phase epics exist, call `provider_set_field` per phase with the execution-order value read from flat-file markers |
| Step 9: Sidecar `parts` block (NEW) | (none) | Write per-Part `task_members` + `state` blocks to sidecar |

### §6.3 — Reverse migration (tracker → flat)

Per inventory §10.3 + §12.4, current reverse-emit sorts by `int(phase_number)`. BD-185 changes:

| Surface | Existing behavior | BD-185 change |
|---|---|---|
| `_tmr_emit_implementation_plan` | Sorts phases by phase_number ascending | Sorts phases by `execution-order` value (read from Issue Fields or fallback); writes `<!-- execution-order: NNN -->` marker into emitted `phase-N.md` |
| `_tmr_emit_status` | Sorts phases by phase_number ascending | Same: sort by execution-order |
| Phase-epic body emit | Existing | Emits `<!-- pack-id-v2: Phase-N -->` marker alongside existing `<!-- pack-id: phase-N -->` |
| Phase-task body emit | Existing | Emits `<!-- pack-id-v2: Phase-N.Part-x.Task-M -->` marker (or `Phase-N.Task-M` if no Part membership) alongside existing `<!-- pack-id: phase-N.M -->` |
| Multi-part phase emit (NEW) | (none) | For phases with Part children, emits H3 `### Part a — <subtitle>` / `### Part b — <subtitle>` sub-sections; H4 task headers grouped under their Part |

### §6.3a — Execution-note structured warning template (D8)

**Execution-note warning template (context-rich; required content):**

When the migrator encounters a phase with an `> **Execution note**:` paragraph, it emits a structured warning containing:

1. **Phase number + title** (e.g., 'Phase 25 — Auth refactor follow-up')
2. **Full note text** (the `> **Execution note**:` paragraph as written; excerpt, not paraphrased)
3. **Referenced entities** — phase numbers, BD-NNN, TD-NNN, phase-N.M extracted from the note text via heuristic regex (display only; not auto-assigned). Suggested regex shapes: `\bPhase\s+\d+\b`, `\bphase-\d+\b`, `\bBD-\d+\b`, `\bTD-\d+\b`, `\bphase-\d+\.\d+\b`
4. **Current state of each referenced entity** — execution-order value, status (pending / in-progress / done / deferred / cancelled / etc.)
5. **Contextual assessment data** — surface the data; do NOT auto-decide. Examples: all referenced phases `status:done` → likely historical; at least one `status:pending` → likely still operative; phase's own status `status:done` → execution order is moot
6. **Suggested actions with concrete commands** — three explicit paths:
   - [1] Accept default (do nothing; order stays at phase_number)
   - [2] Reorder per the note (`pack phase reorder phase-N --order X.Y` with suggested sparse value)
   - [3] Mark as historical (write `<!-- execution-note-status: historical -->` to phase-N.md so future tools don't re-warn)
7. **Doc cross-reference** — pointer to the procedure (METHODOLOGY.md or MIGRATION-v10-to-v11.md section on execution-note handling)

Reference-extraction regex is heuristic; the migrator does NOT auto-assign ordering based on regex matches. The user interprets the data; the verbs mutate the SSOT.

**Historical-marker persistence:**

When a user marks a phase's execution note as historical:
- Marker: `<!-- execution-note-status: historical -->` (HTML comment, body-marker style consistent with existing pack-id markers)
- Effect: future migrations / lint passes / tools that scan execution notes skip warning on this phase
- Round-trip: marker round-trips through reverse migration (body markers always do)
- Removal: user can remove the marker manually if the historical assessment changes

### §6.4 — Initialization-from-current-implementation-order algorithm

**Algorithm (greenfield + v10→v11 + v11.0 → tracker mode):**

1. Read all phases from current state (flat-file: `phase-N.md` files in lexical-sorted order; OR IMPLEMENTATION-PLAN.md `## Phase N` headings in document order).
2. Filter to phases NOT yet having an `execution-order` marker (greenfield / unmigrated phases).
3. For each phase WITHOUT a marker, in document-order:
   - Assign `execution-order = phase_number` (default — works for OT-style birth-order = execution-order projects).
   - If the phase has a `> **Execution note**:` prose (e.g., "this phase runs between Phase 3 and Phase 4"), the migrator emits the structured warning per §6.3a (context-rich; required content includes full note text, referenced entities + state, contextual assessment, suggested actions with commands, doc cross-reference). The order is set to phase_number but the user is alerted with actionable context. The user may then [1] accept default, [2] reorder, or [3] mark as historical via `<!-- execution-note-status: historical -->`.
4. Write markers (flat-file mode) or write Issue Field values (tracker mode).

**Worked example (OT-style 60-phase project):**

- Phases 1..60 in birth-order = execution-order.
- Migrator assigns execution-order = phase_number (1, 2, ..., 60).
- No warnings (no execution notes in OT-style projects).
- Mirror emits phases in execution order (= phase number ascending) — matches user intuition.

**Worked example (project with execution notes for re-ordered phases):**

- Phases 1..30, but Phase 25 has `> **Execution note**: runs between Phase 8 and Phase 9` (i.e., out-of-birth-order).
- Migrator assigns execution-order = phase_number (1, 2, ..., 30). Phase 25 gets order=25.
- Structured warning emitted per §6.3a (full note text + extracted references to Phase 8 + Phase 9 with their current state + contextual assessment + three suggested actions including the exact `pack phase reorder phase-25 --order 8.5` command).
- User runs `pack phase reorder` post-migration to move Phase 25 to order=8.5 (between Phase 8 at order=8 and Phase 9 at order=9). Sparse value (8.5) avoids renumbering.

The architect chooses NOT to parse execution-note prose for auto-ordering heuristics (D8 — default to phase_number). The migrator extracts entity references (phase numbers, BD-NNN, TD-NNN, phase-N.M) via heuristic regex for DISPLAY in the structured warning per §6.3a, but does NOT auto-assign ordering based on regex matches. The user interprets the data; the verbs mutate the SSOT.

---

## §7 — TrackerProvider abstraction changes

Per inventory §8 + §12.7, the BD-060 18-op surface needs extension for BD-185. New ops added:

| New op | Signature | Purpose | Backend support |
|---|---|---|---|
| `provider_sub_issue_reprioritize` | `provider_sub_issue_reprioritize <parent-id> <child-id> [--after <sibling-id>]` | Move a sub-issue to a new sibling position under its parent. Used by execution-order fallback (§5.2) AND by Part re-parentage if siblings need re-ordering. | GH: REST `PATCH /sub_issues/priority` (§4.2) (primary-source verification of REST param names at implementation-time per D6). Forgejo/Gitea: native sub-issue ordering NOT supported — fallback degrades to label-namespace `order:NNN` if exposed via `provider_capabilities` flag. |
| `provider_set_field` | `provider_set_field <issue-id> <field-name> <value>` | Write an Issue Field value (number / single-select / text / date). Used by execution-order primary path (§5.1). | GH: `gh api graphql` with `updateIssueField` mutation (primary-source verification at implementation-time per D6). Linear: Properties API. Jira: Custom Fields API. GitLab: Custom Fields API. Redmine: Custom Fields API. Forgejo/Gitea: NOT supported (mechanism = sub-issue reprioritize). |
| `provider_get_field` | `provider_get_field <issue-id> <field-name>` | Read an Issue Field value. Used by reverse-emit (§6.3) to read execution-order for sort. | Same backend matrix as `_set_field`. |

**Total surface:**
- v11.0: 18 → 20 ops + raw (`provider_set_field` + `provider_get_field` added)
- v11.1+ (when Forgejo/Gitea ships): 20 → 21 ops + raw (adds `provider_sub_issue_reprioritize`)

`provider_sub_issue_reprioritize` is DESIGNED only in v11.0; implementation deferred to v11.1+ Forgejo/Gitea support pass per D9.

**Existing op behavior changes:**

| Op | BD-185 impact |
|---|---|
| `provider_create` | When creating a phase-part-v11.1 entity, body includes the new `<!-- pack-id: phase-N.Part-x -->` + `<!-- template_version: phase-part-v11.1 -->` markers. No change to the op signature. |
| `provider_set_labels` | Admits new namespace `status:pending`/`status:in-progress`/`status:done`/`status:deferred` on Part entities (vocabulary already exists for phase tasks — no new label). No new label namespace introduced (the part:M label namespace mentioned in BD-185 BACKLOG entry is REJECTED — Parts are full tracker entities, not label-annotated tasks; identity is in pack-id, not labels). |
| `provider_sub_issue_create` | Admits Part entity as a valid sub-issue parent (was: phase epic only). Updates the sub-issue parent regex `^phase-\d+$` (in `_tmr_decode_blockers` function in `tracker-migrate-reverse.sh`) to admit `^Phase-\d+(\.Part-[a-z])?$` (or equivalent). |
| `provider_capabilities` | Returns new flag: `execution_order.mechanism = "issue_fields" | "sub_issue_reprioritize" | "none"`; new flag: `parts.supported = true | false`. |
| `provider_link` | Admits Part-id forms (`Phase-N.Part-x`) as dependency source/target (per `tracker-links.sh` extension). |

### §7.1 — Per-backend support matrix

| Backend | Parts (sub-issue depth-2) | Execution Order (Issue Fields) | Fallback (sub-issue reprioritize) | Notes |
|---|---|---|---|---|
| GitHub | Yes (sub-issues GA 2025; depth 8 / 100 children / 1 parent) | Yes (preview; per §5.1) | Yes (REST `reprioritize_sub_issue` per §4.2) | Default for v11.0 BD-185 ship |
| Linear | Yes (sub-issues with parent_id) | Yes (Properties; GA) | (n/a — Issue Fields primary) | Reserved (non-BD-185 work) |
| Jira | Yes (with caveats — Jira's sub-task parentage is more restrictive than GH; epic-task exclusive parentage) | Yes (Custom Fields; GA) | Partial (Jira issue links can express sibling order but not native reprioritize) | Reserved |
| GitLab | Yes (sub-issues via Epic relationships, license-tier sensitive) | Yes (Custom Fields since 2024) | (n/a — Issue Fields primary) | Reserved |
| Redmine | Yes (sub-tasks) | Yes (Custom Fields; mature) | Partial | Reserved |
| Forgejo | Yes (sub-issues; capability check at runtime; primary-source verification at v11.1+ implementation per D6 + D9) | NO native | Sub-issue reprioritize against phase-order-root (degrades to label namespace if sub-issue API not available) | Designed for v11.1+; NOT BD-185 implementation per D9 |
| Gitea | Yes (sub-issues; capability check at runtime; primary-source verification at v11.1+ implementation per D6 + D9) | NO native | Same as Forgejo | Designed for v11.1+; NOT BD-185 implementation per D9 |

### §7.2 — id-map.json schema extension

Per inventory §8.1, the existing id-map.json shape is:

```json
{
  "BD-NNN": {"id": <int>, "url": <url>},
  "TD-NNN": {"id": <int>, "url": <url>},
  "phase-N": {"id": <int>, "url": <url>, "task_order": ["1", "2", "3"]},
  "phase-N.M": {"id": <int>, "url": <url>}
}
```

**BD-185 additive extension:**

```json
{
  "BD-NNN": {"id": <int>, "url": <url>},
  "TD-NNN": {"id": <int>, "url": <url>},
  "phase-N": {
    "id": <int>,
    "url": <url>,
    "task_order": ["1", "2", "3"],
    "execution_order": <number>,                                // NEW (optional; only present if order is initialized)
    "parts": {                                                   // NEW (optional; only present if phase has Parts)
      "Part-a": {"id": <int>, "url": <url>, "task_members": ["1", "3"]},
      "Part-b": {"id": <int>, "url": <url>, "task_members": ["2"]}
    }
  },
  "phase-N.M": {
    "id": <int>,
    "url": <url>,
    "parent_part": "Part-a"                                      // NEW (optional; only present if task belongs to a Part)
  },
  "phase-order-root": {"id": <int>, "url": <url>}                // NEW (optional; only present for Forgejo/Gitea-class fallback)
}
```

All new fields are OPTIONAL and ADDITIVE. v11.0 id-map.json loads cleanly (no `execution_order`, no `parts`, no `parent_part`, no `phase-order-root`).

### §7.3 — Sidecar (.pack-tracker/sidecar.yaml) extension

Per §4.6, the sidecar gains:
- `phase_tasks.phase-N.parts` block (per-Part container with state + member list)
- `phase_tasks.phase-N.tasks.phase-N.M.parent_part` field (per-task Part membership)

A new top-level block carries phase-level execution order (DUPLICATE of id-map.json field, for sidecar consumers that don't read id-map):

```yaml
phase_execution_order:
  phase-1: 1
  phase-2: 3
  phase-3: 2
  ...
```

This is duplicative state by design — sidecar is the tracker-only state file; id-map.json is the tracker forward-migration state file. Both carry execution_order for read-path simplicity.

**Round-trip semantics (sidecar vs flat-file):**

- Tracker → flat-file: pack reads execution_order from sidecar (or Issue Fields directly), writes `<!-- execution-order: NNN -->` markers to per-entry `phase-N.md` files.
- Flat-file → tracker: pack reads markers from `phase-N.md`, writes Issue Fields + sidecar values.

The flat-file markers are the SSOT in flat-file mode; Issue Fields are the SSOT in tracker mode. Sidecar is derived cache (tracker-only).

---

## §8 — §13 worksheet checklist coverage

Every checkbox from inventory §13 is addressed below: design decision OR explicit deferral with rationale.

### §8.1 — Parts hierarchy checkboxes

| Checkbox | Decision | Where |
|---|---|---|
| Part identifier grammar chosen | `Phase-N.Part-x.Task-M` (with-Part) / `Phase-N.Task-M` (null-Part) per C-1 user-lock; Task-M integer-only per D15 | §4.1 |
| Part body marker decision | Trio: `<!-- pack-id: phase-N.Part-x -->`, `<!-- template_version: phase-part-v11.1 -->`, `<!-- pack-version: v11 -->` (matches existing phase-epic/phase-task pattern) | §4.3 + §11 |
| Part label namespace decision | NO new label namespace. Identity is in pack-id markers + sub-issue parentage. Existing `status:*` labels apply to Parts. The `part:M` label namespace from BD-185 entry File/Symbol is REJECTED (identity-as-label is the wrong layer — labels are searchable annotations, not identity carriers; pack-id is the SSOT). | §4.3 + §7 |
| Part state taxonomy | pending / in-progress / done / deferred (excludes merged-into and superseded-by per §4.4 lifecycle invariant) | §4.4 |
| Part sub-issue placement | Sub-issue child of phase epic; sub-issue parent of phase tasks (depth 2 in the 8-deep tree) | §4.2 |
| Form-family extension decision | Add `phase-part-skeleton` to wi-type (5th option); add `wi-part-letter` input | §4.3 |
| Form-family soft cap impact (4→5 options; BD-068) | Soft cap BREACHED with documented defense in §4.3 (rare-case fallback path; common-path users see only 2 of 5 options; alternative is to skip form, worse UX) | §4.3 |
| Template archive cut decision | v11.0 closed; v11.1 cut introduces `phase-part-v11.1` subdir + bumps `work-item-v11.0` → `work-item-v11.1` | §4.3 |
| Tasks compose with Parts (inside / parallel) | Tasks INSIDE Parts (via sub-issue re-parentage); flat-file H3 grouping. Pre-Part state: tasks AT phase level. | §4.2 + §4.6 |

### §8.2 — Execution ordering checkboxes

| Checkbox | Decision | Where |
|---|---|---|
| Phase-level execution-order mechanism chosen | Issue Fields `Execution Order` (number) — primary path per C-2; sub-issue reprioritize against phase-order-root — fallback path for Forgejo/Gitea-class | §5.1 + §5.2 |
| Migrator initial-order writing | execution-order = phase_number for greenfield/OT-style; WARNING emitted for phases with execution-note prose | §6.4 |
| STATUS.md role NOT expanded (SC5) | Confirmed: STATUS.md remains dashboard. Display order changes (sort by execution_order); ownership stays in Issue Fields / per-entry markers. | §5.4 |
| Tracker-mode + flat-file-mode round-trip | Issue Fields ↔ `<!-- execution-order: NNN -->` marker; sidecar caches for consumers | §5.3 + §7.3 |
| Cap consideration (rate limits) | Reorder ops are infrequent (manual user verb); typical project: 1-5 reorders per phase lifecycle. Bulk-init at migration: N writes (N = phase count, typically 28-60). Well within 5,000 req/hr budget. | §5.2 |
| CLI/gh-version-pin sensitivity | Issue Fields read/write routes through `gh api graphql` (avoids `gh` CLI version-pinning) — locked per D10 | §5.1 |

### §8.3 — Migration checkboxes

| Checkbox | Decision | Where |
|---|---|---|
| v10 → v11 migrator carries existing whole-number phases unchanged | Yes (INV-1 preserved; decompose emits `phase-N.md` with phase_number = N) | §6.1 |
| v11.0 flat → tracker migrator initializes ordering | Yes (Step 8 writes Issue Field values from flat-file markers OR phase_number if no marker) | §6.2 + §6.4 |
| No manual intervention required | Yes for OT-style birth-order = execution-order projects (most common case). WARNING for execution-note projects (manual reorder post-migration). | §6.4 |

### §8.4 — Immutability invariants checkboxes

| INV | Status |
|---|---|
| INV-1 phase number immutability | Preserved — design never renumbers phases; new phases insert at end (per METHODOLOGY) |
| INV-2 task-id `phase-N.M` immutability | Preserved — `phase-N.M` body marker carries forward; optional `pack-id-v2` marker is ADDITIVE (does not replace the existing marker) |
| INV-3 tracker entity ID immutability | Preserved — Part expansion re-parents tasks (sub-issue parent change); does NOT recreate task issues |
| INV-4 phase-task body marker trio | Preserved — trio unchanged; v2 marker is additive |
| INV-5 phase-epic body marker trio | Preserved — trio unchanged; v2 marker is additive |
| INV-6 Path 3 (`--fold-into`) forbidden | Preserved — design does NOT introduce any fold-into path |
| INV-7 wi-type 4-option soft cap | BREACHED (5 options); defense documented §4.3 |
| INV-8 form-family BD-068 rules | Respected modulo §4.3 defense |
| INV-9 STATUS.md dashboard role | Preserved per §5.4 |

### §8.5 — CI checks checkboxes

| Check | Extension |
|---|---|
| Check 32 (mirror in-sync) | Stream regex `^phase-\d+\.md$` unchanged (Parts inline). Mirror sort order changes (per §5.3); test fixtures updated. |
| Check 33 (TOC in-sync) | Group regex `^phase-\d+\.md$` unchanged. TOC display order may extend to show execution order (planner discretion). |
| Check 34 (cross-reference integrity) | Extended to admit Part-id form `Phase-N.Part-x` and `Phase-N.Part-x.Task-M` in cross-references AND legacy `phase-N.M` form continues to resolve |
| Check 35 (phase-task lib invariants) | Paralleled by Check 35.5: enforces phase-part-v11.1 SCHEMA + library invariants (parser/emitter at new `tracker-phase-part.sh` per D11) |
| `check_issue_template_forms` | `expected_wi_type_options` extended from 4 to 5 (adds `phase-part-skeleton`) |
| `check_template_archive_v11` | v11.1 cut: extends to 6 entry-type subdirs (adds `phase-part-v11.1`) — but v11.0 archive stays frozen at 5 subdirs |
| NEW Check N (Part state taxonomy) | Validates phase-part-v11.1 SCHEMA per §4.4 + §11; rejects un-admitted state values |
| NEW Check N+1 (execution-order marker presence) | Validates that every phase-N.md has the `<!-- execution-order: NNN -->` marker post-migration; flags violations |

### §8.6 — TrackerProvider checkboxes

| Item | Coverage |
|---|---|
| Each of 18 existing ops verified | §7 enumerates per-op BD-185 impact (table) |
| New ops added if needed | 3 new ops: `provider_sub_issue_reprioritize`, `provider_set_field`, `provider_get_field` |
| id-map.json schema extension | §7.2 — additive only |
| sidecar.yaml schema extension | §4.6 + §7.3 — additive only |

### §8.7 — Doc surface checkboxes

| Doc | Update |
|---|---|
| METHODOLOGY.md (Multi-part phases) | Extend § "Multi-part phases" to document tracker representation (Parts as sub-issue entities); add per-Part lifecycle states; reference `pack phase split` verb |
| MIGRATION-v10-to-v11.md | Document multi-part phase handling in Phase A (decompose preserves inline H3) + Phase B (creates Part entities) |
| HELP-FRAGMENT-PACK.md | Add `pack phase split`, `pack phase reorder` verb docs |
| HELP-FRAGMENT-TRACKER.md | Add `pack tracker phase split`, `pack tracker phase reorder` verb docs |
| `_rules.md` (implementation-plan stream) | Document Part H3 sub-section grammar; document `<!-- execution-order: NNN -->` marker |
| `_intro.md` (implementation-plan stream) | User guidance on when to split a phase into Parts; reordering workflow |

---

## §9 — Cross-feature integration with groupings (BD-186 / BD-189)

Per C-3 and inventory §11.5, BD-185 design must respect groupings constraints G-1..G-3 even though groupings (BD-189) is not yet architected.

### §9.1 — G-1 (Groupings contain ONLY phases)

BD-185 design honors G-1 by NOT introducing Parts as grouping candidates. Parts are sub-issue children of phase epics; they are never members of any grouping. The grouping membership shape (per HANDOFF-V11.1-ARCHITECT.md — "5-field grouping doc shape" includes `**Member phases (by ID):**`) reads `phase-N` identifiers only. The design's choice to keep Parts INLINE (per §4.6, no per-entry `phase-N.Part-a.md` file) reinforces this: grouping membership cannot accidentally reference a Part because Parts have no standalone per-entry file.

### §9.2 — G-2 (Minimum 2 phases per grouping)

Independent of BD-185. The BD-185 design does not affect minimum-2 enforcement.

### §9.3 — G-3 (Backlog must convert to phase before joining grouping)

Independent of BD-185. The BD-185 design does not affect backlog-to-phase conversion.

### §9.4 — G-4 (Anything beyond G-1/G-2/G-3 is groupings-architect decision pending)

The following BD-185 design choices may interact with the groupings architect's eventual design; flagged here for the groupings architect's awareness:

| BD-185 surface | Potential groupings interaction | Architect decision pending |
|---|---|---|
| `<!-- execution-order: NNN -->` marker on `phase-N.md` | Groupings may reference phases via this marker (sort grouping members by execution order). The marker is read-stable for groupings consumers. | Groupings architect: decide whether grouping_member_view sorts by execution_order or by phase_number. |
| `Phase-N.Part-x` identifier grammar | C1 (Parts NEVER grouping members) means groupings doc shape SHOULD NOT admit Part identifiers in `**Member phases (by ID):**`. If the groupings architect adds Part-aware membership later, design must justify violating C1. | Groupings architect aware of C1; BD-185 design assumes C1 holds. |
| `phase-part-v11.1` template | Groupings may need to inspect Parts to count phase-task progress per grouping. Parts as sub-issues are read-visible via `provider_sub_issue_list`. | Groupings architect: decide whether grouping_progress_view aggregates Part-level state. |
| Issue Fields `Execution Order` (number) | Groupings may want a sibling field `Grouping Membership` (single-select or text) on phase epics. Both fields share the 25-field-per-org cap. | Groupings architect: budget the field allocation against the 25-cap. |

These are flagged as cross-feature notes; the groupings architect resolves them in the v11.1+ design cycle.

---

## §10 — CI check changes

Per §8.5 + inventory §7. Specific extensions:

### §10.1 — Existing checks extended

**Check 32 (`check_mirror_in_sync`, BD-168):**
- Stream regex `^phase-\d+\.md$` unchanged (Parts inline; no new file pattern).
- Mirror sort order changes (per §5.3): mirror file now reflects execution order. Test fixtures under `scripts/tests/fixtures/per-entry-split/` need a fixture demonstrating execution-order sort vs phase-number sort.

**Check 33 (`check_toc_in_sync`, BD-168):**
- Group regex `^phase-\d+\.md$` unchanged.
- `_toc.md` content may extend to display execution order (planner discretion; `_order.md` is the SSOT-derived view per D7 / §5.3).

**Check 34 (`check_cross_reference_integrity`, BD-168):**
- Cross-ref regex (`CROSS_REF_RE` in `validate-pack.py`; Check 34 docstring) extends from `phase-N[.M]` to admit:
  - `Phase-N` (capitalized, v2 form)
  - `Phase-N.Part-x` (Part identifier)
  - `Phase-N.Part-x.Task-M` (Part-scoped task identifier)
  - `Phase-N.Task-M` (null-Part task identifier; v2 form)
- Legacy `phase-N.M` (lowercase, dot-separator) continues to resolve.

**Check 35 (`check_tracker_phase_task_invariants`, BD-106):**
- Existing: verifies `scripts/lib/tracker-phase-task.sh` exists; Path 3 forbidden.
- Extended: `scripts/lib/tracker-phase-part.sh` is CREATED per D11 (parallel to `tracker-phase-task.sh`); verify it follows the same lib-invariant pattern.
- Status enumeration admits `cancelled` (per §4.4a; see also §11.1 SCHEMA archive extension).

**`check_issue_template_forms`:**
- `expected_wi_type_options` set extends from 4 to 5: `{bd, td, phase-epic-skeleton, phase-task-skeleton, phase-part-skeleton}`.

**`check_template_archive_v11`:**
- v11.0 archive **structural shape** is frozen at 5 entry-type subdirs (bd / td / phase-epic / phase-task / inbound) — no new directories added in the v11.0 archive after v11.0 ship. **Intra-file content MAY evolve** via backward-compatible additive extensions (e.g., new admitted state values, forward-reference footnotes to v11.1+ evolutions). This matches the pack's existing design philosophy of additive extension (cf. D12 LAZY backfill). BD-185 exercises this convention: `phase-task-v11.0/SCHEMA.md` Section 3 admits new `cancelled` state value (per D5); `v11.0/INDEX.md` may add a forward-reference footnote pointing to v11.1+ archive.
- v11.1 archive cut: NEW check `check_template_archive_v11_1` verifies 6 entry-type subdirs (`bd`, `td`, `phase-epic`, `phase-task`, `phase-part`, `inbound`) — OR (cleaner) the existing check is parameterized by version and verifies the v11.N archive matches its INDEX.md declaration.

### §10.2 — New checks introduced

**Check N (`check_phase_part_schema_v11_1`):**
- Verifies `maintenance-docs/v11-research/templates-archive/v11.1/phase-part-v11.1/SCHEMA.md` exists.
- Verifies the SCHEMA declares: identifier scheme = `Phase-N.Part-x`; body marker trio with `template_version: phase-part-v11.1`; label family (no new namespace; `status:*` only); state taxonomy = `pending / in-progress / done / deferred`.
- Pattern parallels Check 35.

**Check N+1 (`check_execution_order_marker`):**
- Verifies every `phase-N.md` in `docs/project/implementation-plan/` (project-side) carries a `<!-- execution-order: NNN -->` marker.
- Optional / gated by tracker.toml — project not yet at v11.1 doesn't have markers and isn't required to.
- Implementation: scan per-entry tree files; assert marker presence; CI failure names missing-marker files.

**Check N+2 (`check_part_re_parentage_invariants`):**
- Verifies that for every phase epic with Part sub-issues, all phase tasks are sub-issue children of a Part (not direct children of the phase epic).
- Tracker-side check only (no flat-file analog).
- Read via `provider_sub_issue_list`; assert phase task IDs appear under a Part, not under the phase epic directly.

**Check N+3 (`check_part_has_member_task`):**
- Verifies every Part entity in tracker has at least one task as a sub-issue child OR is marked `status:deferred`.
- Tracker-side check only.
- Per D3 §4.7 L353-L359.

---

## §11 — Doc surface changes

Per §8.7 + inventory §11.6. Specific edits:

### §11.1 — METHODOLOGY.md (`supporting-docs/METHODOLOGY.md`)

**Section: Part 4 § "Multi-part phases" (under the Part 4 § "Multi-part phases" subhead).**

Extend with:
- Reference to tracker-mode representation: "When tracker mode is enabled (tracker.toml configured), Parts are first-class sub-issue entities under phase epics. See `templates-archive/v11.1/phase-part-v11.1/SCHEMA.md`."
- New sub-section "Part state taxonomy": pending / in-progress / done / deferred (matches §4.4).
- New sub-section "Creating Parts programmatically": references `pack phase split` and `pack tracker phase split` verbs (§4.5).
- Note: "Existing `phase-N.M` task identifiers are immutable across Part expansion. The pack-id v2 marker (`pack-id-v2: Phase-N.Part-x.Task-M`) is the Part-aware form; the legacy `pack-id: phase-N.M` marker continues to resolve."

**Section: Part 4 § "Phase numbering rules" (under the Part 4 § "Phase numbering rules" subhead).**

Extend with:
- Reference to execution-order mechanism: "To reorder execution, use the `<!-- execution-order: NNN -->` marker (flat-file mode) OR the Issue Field `Execution Order` (tracker mode). The `> **Execution note**:` prose is preserved as human-readable context but is no longer the SSOT for order."
- Cross-reference: see `ARCHITECTURE-BD-185.md` §5.

**Additional Multi-part phases extensions (D3 + D4 + D8 + D2 + D5):**

- **Part creation rule (D3 — ≥1 task at creation):** Every Part must contain at least one task at creation time. The `pack phase split` verb rejects splits that would leave any Part empty.
- **Task immutability rule (D4 — no mid-life re-parent; supersede only):** Once a task is assigned to a Part (at phase split time), the task remains in that Part forever. Tasks that need to move work to a different Part use `pack task supersede` (per §4.8). NO `pack task reparent` verb exists.
- **Supersede verb is the canonical mid-life task-move mechanism (D4):** Document the supersede verb as the canonical mid-life task-move mechanism; reject mid-life re-parenting between Parts (see §4.8).
- **Execution-note-status marker convention (D8 — historical/active):** Phases whose execution note has been superseded by current state may carry `<!-- execution-note-status: historical -->`. Migrations / lint passes / tools that scan execution notes skip warning on phases carrying this marker. Round-trips through reverse migration.
- **Decision-2 no-collapse rule:** Part collapse is REJECTED as anti-pattern (D2). Once split, the split is permanent — no `pack phase collapse` verb in any release.

**SCHEMA archive extensions (D5 — `cancelled` state):**

`maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md` extensions:
- Section 3 (Label family) status enumeration extended with `cancelled`: `status:<pending|in-progress|done|deferred|cancelled|merged-into:phase-N|superseded-by>`.
- Section 4 (Body grammar) marker list extended with optional body marker: `<!-- execution-note-status: historical -->`.

### §11.2 — MIGRATION-v10-to-v11.md (`supporting-docs/MIGRATION-v10-to-v11.md`)

**Section: § "Per-entry decomposition" (under the top-level § "Per-entry decomposition" heading).**

Extend with:
- Documented behavior: multi-part phase H3 sub-sections are preserved inline in `phase-N.md` during Phase A decompose.
- Documented behavior: execution-order initialization writes `<!-- execution-order: NNN -->` markers with value = phase_number.
- Warning case: phases with `> **Execution note**:` prose emit a migration warning recommending post-migration review via `pack phase reorder`.

**Section: NEW § "Phase B — multi-part phase tracker materialization" (insert after existing Phase B section).**

New documented step: if H3 Parts are present in flat-file, Phase B creates Part sub-issues + re-parents tasks per H3 grouping.

### §11.3 — HELP-FRAGMENT-PACK.md / HELP-FRAGMENT-TRACKER.md

**HELP-FRAGMENT-PACK.md additions:**
- `pack phase split <phase-N> --parts <count>` — Split a phase into multi-part form mid-work.
- `pack phase reorder` — Interactively reorder phase execution order (writes markers).

**HELP-FRAGMENT-TRACKER.md additions:**
- `pack tracker phase split <phase-N> --parts <count>` — Create Part sub-issues + re-parent tasks (tracker mode).
- `pack tracker phase reorder` — Update Issue Field `Execution Order` (or fallback mechanism).

### §11.4 — `_rules.md` (per-entry tree contract — implementation-plan stream)

**File: `project-template/docs/project/implementation-plan/_rules.md`**

Extend the entry contract (under the § "Entry contract" subhead):
- Body marker quad (add `<!-- pack-id-v2: Phase-N -->` and `<!-- execution-order: NNN -->` to the existing back-pointer + `<!-- pack-id: phase-N -->`).
- H3 sub-sections: "### Part a — [Subtitle]" / "### Part b — [Subtitle]" admitted as optional content after the phase H2 heading and before `### Tasks`. For phases without Parts, the H3 Part sub-sections are absent.
- H4 task headers under Parts: `#### Task M — <title>` (the legacy `#### N.M — <title>` form continues to resolve via the pack-id v1 marker).

Phase-state vocabulary unchanged (pending / in-progress / done / deferred / merged-into / superseded-by per existing _rules.md lines 28-31).

### §11.5 — `_intro.md` (per-entry tree user guidance)

**File: `project-template/docs/project/implementation-plan/_intro.md`**

Add new sub-section "Splitting a phase into Parts":
- When to split: per METHODOLOGY § Planner trigger rules (5+ tasks, non-linear deps, second-failure).
- How to split: run `pack phase split <phase-N> --parts 2` (or `--parts 3`, etc.). Prompt assigns existing tasks to Parts.
- What changes: H3 sub-sections appear in `phase-N.md`; task pack-ids gain `pack-id-v2: Phase-N.Part-x.Task-M` markers; tracker (if enabled) creates Part sub-issues.

Add new sub-section "Reordering phase execution":
- Why: phase numbers are immutable (INV-1), but execution order can change as priorities shift.
- How: run `pack phase reorder` (flat-file mode) or `pack tracker phase reorder` (tracker mode).

### §11.6 — Trinity rule applicability (C-5)

Per C-5 + `ARCHITECTURE-BD-182.md` §5, trinity rule applies to `project-template/{CLAUDE,AGENTS,GEMINI}.md`. BD-185 anticipated trinity-affected surfaces:

| Surface | Anticipated edit | Trinity action |
|---|---|---|
| Coder / reviewer prompt templates (`project-template/docs/pack/prompts/`) | Per-Part report headers (already documented in METHODOLOGY § Part 5) — no template edit anticipated beyond inheriting from METHODOLOGY | None — METHODOLOGY-only edit |
| `project-template/{CLAUDE,AGENTS,GEMINI}.md` Phase routing section | None anticipated — phase routing is per-phase, not per-Part | None |
| `project-template/{CLAUDE,AGENTS,GEMINI}.md` Skill/Agent references | None anticipated | None |

If the planner pass discovers trinity-affected edits during decomposition, the planner flags them; coder implements per Override 9 (CLI-specific paths) or default trinity parity (byte-identical).

---

## §12 — Open architect questions (POQs) — RESOLVED

ALL 10 POQs RESOLVED 2026-05-25 per Pack Chat decision-review session. See §1.4 Decision log (NEW) for the full decision record. The original POQ table is preserved in git history for audit purposes.

### §12a — Follow-on items (not BD-185 scope)

**Follow-on items surfaced during BD-185 review (2026-05-25):**

The following are NOT BD-185 scope but were surfaced during the review session for future work consideration:

1. **DEPENDENCIES.md framing cleanup** — current 'optional' framing for gh CLI is misleading for tracker mode (it's REQUIRED, not optional; the opt-in is to tracker mode itself, not gh CLI). Suggested update: 'gh CLI | REQUIRED for tracker mode (v11+); not needed for flat-file mode'. **Candidate follow-on BD.**
2. **Required-tools discoverability** — README.md and INSTALL-PROCEDURES.md should have prominent 'Required tools' pointer to DEPENDENCIES.md. **Candidate follow-on BD.**
3. **Client-tool abstraction layer for non-gh paths** — GitHub MCP / other CLIs / direct REST as alternative paths to GitHub. Significant architecture work; v11.1+ direction if user demand emerges. **NOT v11.0 scope.**

---

## §13 — Cross-references

| Artifact | Cite | Relevance to BD-185 |
|---|---|---|
| `maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-PARTS-AND-ORDERING.md` | §1-§13 | Primary fact base; all design decisions cross-reference inventory sections |
| `maintenance-docs/v11-research/ARCHITECTURE-V3.3-DELTA.md` | §2 D-21 (phase-N.M identifier); §6.3 (state machine); §4.1-§4.2 (parser/emitter); §4.3 (task_order); §5 (dependency grammar) | BD-185 ADDS on top (Parts + execution-order); does NOT redefine v11.0 surfaces |
| `maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-SPLIT-ADDENDUM.md` | §2 (tasks-inline decision) | BD-185 honors tasks-inline by keeping Parts inline (no per-Part per-entry file per §4.6) |
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md` | Migrator framework | New migrator operations (§6) follow the framework |
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-182.md` | §4.1 canonical reference table; §5 TOOL-SPECIFIC vs TOOL-NEUTRAL | C-5 applicability for cross-CLI references; BD-185 anticipates minimal trinity-affected edits per §11.6 |
| `maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md` | §2 C1-C7; §4 capabilities #1-#5 + #10 + #14 | C1 (Parts never grouping members) — BD-185 design honors per §9.1 |
| `maintenance-docs/v11-research/HANDOFF-V11.1-ARCHITECT.md` | Reading order; "What's locked vs what's yours to design" | Groupings architect deferred; BD-185 surfaces cross-feature notes per §9.4 |
| `pack-ops/BACKLOG.md` BD-185 | Full entry | Problem statements P1-P4; SC1-SC8; pipeline; out-of-scope |
| Pack memory `feedback_clarg_trinity` | Trinity rule | C-5 applicability; §11.6 |
| Pack memory `feedback_no_solutions_in_agent_prompts` | Design discipline | Architect surfaced POQs (§12) for user discussion; user-prescriptive-authority resolved all 14 decisions 2026-05-25 — see §1.4 |
| Pack memory `feedback_pack_entry_type_data_structure_semantics` (saved 2026-05-23) | Pack entry-type semantics | Parts as entities (not phase-parts) align with the established "phase parts are evolution-only" rule |

---

## §14 — Files touched inventory (planner input)

The downstream planner pass converts the design into ordered commits. Anticipated file list:

### §14.1 — Schema + form-family files (NEW or extended)

| Path | Operation | Reason |
|---|---|---|
| `maintenance-docs/v11-research/templates-archive/v11.1/phase-part-v11.1/SCHEMA.md` | CREATE | NEW Part schema per §4.3 |
| `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md` | CREATE | v11.1 archive cut: 6 entry-type subdirs |
| `maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml` | CREATE | Byte-identical archive of post-BD-185 live form |
| `.github/ISSUE_TEMPLATE/work-item.yml` (pack-root) | EXTEND | Add 5th wi-type option; add wi-part-letter input; extend Blockers/Unblocks/Dependencies descriptions |
| `project-template/.github/ISSUE_TEMPLATE/work-item.yml` (client-side) | EXTEND | Mirror of pack-root edit |

Note: edits to `project-template/.github/ISSUE_TEMPLATE/work-item.yml` and pack-side mirror trigger `test-fixtures/manifest.txt` regeneration per pack memory `feedback_manifest_regen_on_v11_surface` (BD-176 v11-surface trigger; cross-ref §14.9).

### §14.2 — Tracker provider library files (extended or NEW)

| Path | Operation | Reason |
|---|---|---|
| `scripts/lib/tracker-provider.sh` | EXTEND | Add 3 new ops (`_sub_issue_reprioritize`, `_set_field`, `_get_field`) |
| `scripts/lib/tracker-provider-gh.sh` | EXTEND | Implement 3 new ops for GitHub backend |
| `scripts/lib/tracker-phase-part.sh` | CREATE (per D11) | Parser/emitter + state taxonomy for Parts (parallels `tracker-phase-task.sh`) |
| `scripts/lib/tracker-phase-task.sh` | EXTEND | Admit Parts in parent regex; admit Part-id forms in cross-references |
| `scripts/lib/tracker-promote.sh` | EXTEND | Admit `--to=Phase-N.Part-x` form (if architect adds the third promotion path — POQ note) |
| `scripts/lib/tracker-labels.sh` | EXTEND | Add `template:phase-part-v11.1` to label provisioning |
| `scripts/lib/tracker-links.sh` | EXTEND | Admit `Phase-N.Part-x` in dependency grammar |
| `scripts/lib/tracker-sidecar.sh` | EXTEND | Emit `parts` block + `phase_execution_order` block |
| `scripts/lib/tracker-migrate-forward.sh` | EXTEND | New step for Part creation + execution-order write |
| `scripts/lib/tracker-migrate-reverse.sh` | EXTEND | Sort by execution_order; emit v2 markers; emit Part H3 sub-sections |
| `scripts/lib/tracker-init.sh` | EXTEND | Provision `Execution Order` Issue Field OR phase-order-root issue based on capability |
| `scripts/lib/tracker-doctor.sh` | EXTEND | Admit Part pack-id in sanity check regex |

### §14.3 — Per-entry library files (extended)

| Path | Operation | Reason |
|---|---|---|
| `scripts/lib/per-entry/_lib.sh` | EXTEND | New sort key for `project-implementation-plan` stream (execution-order, phase-number, filename tuple) |
| `scripts/lib/per-entry/decompose.sh` | (no change anticipated; Parts inline as H3) | — |
| `scripts/lib/per-entry/mirror-generate.sh` | EXTEND | Sort entries by new sort key |
| `scripts/lib/per-entry/toc-regenerate.sh` | EXTEND (planner discretion per D7) | Display execution order in TOC; `_order.md` is the SSOT-derived view file per D7 |

### §14.4 — Migrator files (extended)

| Path | Operation | Reason |
|---|---|---|
| `scripts/migrate-v10-to-v11.sh` | EXTEND (via migrator framework hooks) | Carry execution-order initialization |
| `scripts/lib/migrate-v10-to-v11/decompose.sh` | EXTEND | Emit execution-order markers + v2 pack-id markers |
| `scripts/lib/migrate-v10-to-v11/apply.sh` | EXTEND | Phase B Part-entity creation step |

### §14.5 — New pack verbs

| Path | Operation | Reason |
|---|---|---|
| `scripts/pack-phase.sh` | CREATE | `pack phase split`, `pack phase reorder` |
| `scripts/pack-tracker.sh` | EXTEND | `pack tracker phase split`, `pack tracker phase reorder` |
| `scripts/pack-td.sh` | (no change anticipated) | — |
| `scripts/init-project.sh` | (no change anticipated; per-entry tree provisioning already covers implementation-plan stream) | — |

### §14.6 — CI validator (extended)

| Path | Operation | Reason |
|---|---|---|
| `scripts/validate-pack.py` | EXTEND | Check 32 / 33 / 34 / 35 extensions; `check_issue_template_forms` extension; NEW checks (Part schema, execution-order marker presence, Part re-parentage) per §10.2 |

### §14.7 — Per-entry tree contract files (extended)

| Path | Operation | Reason |
|---|---|---|
| `project-template/docs/project/implementation-plan/_rules.md` | EXTEND | Document body marker quad + Part H3 grammar |
| `project-template/docs/project/implementation-plan/_intro.md` | EXTEND | User guidance per §11.5 |

### §14.8 — Documentation files (extended)

| Path | Operation | Reason |
|---|---|---|
| `supporting-docs/METHODOLOGY.md` | EXTEND | § Multi-part phases + § Phase numbering rules per §11.1 |
| `supporting-docs/MIGRATION-v10-to-v11.md` | EXTEND | § Per-entry decomposition + NEW § Phase B Part materialization per §11.2 |
| `pack-ops/HELP-FRAGMENT-PACK.md` | EXTEND | Pack-side verb help per §11.3 |
| `project-template/docs/pack/HELP-FRAGMENT.md` | EXTEND | Client-side mirror |
| `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` | EXTEND | Tracker-side verb help per §11.3 |
| `pack-ops/HELP-FRAGMENT-TRACKER.md` | EXTEND | Pack-side mirror |
| `project-template/docs/pack/PM-CHAT.md` | EXTEND | Reference `pack phase split` workflow |
| `project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md` | (no change anticipated; per §11.6) | — |
| `pack-ops/BACKLOG.md` | UPDATE | Status flip BD-185 Open → Resolved at batch close (per pack memory `feedback_implicit_status_flip`) |
| `pack-ops/CHANGELOG.md` | UPDATE | Add v11.1 entry at version cut (NOT a BD-185 work item; pack memory `feedback_pack_chat_does_no_fixes` restricts; planner notes) |

### §14.9 — Test files (extended or NEW)

| Path | Operation | Reason |
|---|---|---|
| `scripts/tests/test-tracker-phase-task.sh` | EXTEND | Admit Parts in fixtures |
| `scripts/tests/test-tracker-phase-part.sh` | CREATE (per D11) | Parallel to phase-task lib test |
| `scripts/tests/template-version-test.sh` | EXTEND | Add `phase-part-v11.1` to expected versions list |
| `scripts/tests/tracker-init-test.sh` | EXTEND | Add label provisioning for new template_version |
| `scripts/tests/test-per-entry.sh` | EXTEND | New sort-order fixture |
| `scripts/tests/check-*.sh` per-check tests | CREATE (per new checks) | Per-check test files for new CI checks per §10.2 |
| `test-fixtures/manifest.txt` | REGENERATE | Per pack memory `feedback_manifest_regen_on_v11_surface` — BD-185 touches all 4 v11-surface dirs |

---

## §15 — Closing notes

**Design completeness check (against §1.2 SC list):**

- SC1 (split at creation): Implicit — splitting at creation = creating N phases instead of 1; no design change needed (METHODOLOGY's existing phase-creation mechanism handles this). Architect confirms NO BD-185 work required for SC1.
- SC2 (mid-work expansion): §4 design satisfies (Parts as sub-issue entities; re-parentage preserves task IDs).
- SC3 (no renumbering): §4 + §8.4 — INV-1, INV-2, INV-3 preserved by design.
- SC4 (tracker-mode ordering without flat-file SSOT): §5 design satisfies (Issue Fields = tracker SSOT; sub-issue reprioritize fallback).
- SC5 (STATUS.md dashboard): §5.4 confirms; INV-9 preserved.
- SC6 (smallest template_version delta): §4.3 — 1 NEW template + 1 BUMPED template; 4 templates unchanged.
- SC7 (bi-directional sync): §6 + §7 + §7.2 + §7.3 — forward (id-map updates, sidecar updates, Issue Field writes) + reverse (sort by execution_order, emit v2 markers + H3 Parts).
- SC8 (migration pass-through): §6.4 — initialize from phase_number; warn on execution-note prose; user reorder post-migration if needed.

**Invariant compliance check (against §8.4):**

INV-1, INV-2, INV-3, INV-4, INV-5, INV-6, INV-9 preserved. INV-7 BREACHED with documented defense (§4.3). INV-8 respected modulo §4.3 defense.

**Pipeline forward:**

This document is read by Pack Chat → user review → planner. The planner pass converts the design into ordered commits + per-commit success criteria. All 10 POQs (+ 3 derivative design decisions + INV-7 breach acceptance) were resolved 2026-05-25 per Pack Chat decision-review session — see §1.4 Decision log for the full audit trail; planner pass spawns with the user-locked decisions as constraints.

---

## End of architect pass
