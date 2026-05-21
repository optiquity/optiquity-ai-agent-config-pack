# BD-185 — Docs-researcher prompt (QUEUED — DO NOT FIRE YET)

**Status:** QUEUED
**Date queued:** 2026-05-21
**Queued by:** Pack Chat per user direction (one-time exception to pack rule "Pack Chat does not edit maintenance-docs/" — granted by user 2026-05-21 specifically for this BD's queued-prompt persistence; after this single file, the regular rule returns)
**Fire condition:** Batch 19c (BD-173) closes and commits AND explicit user approval to fire
**Spawn method:** background sub-agent via Agent tool (`subagent_type=pack-docs-researcher`, `run_in_background=true`); **NOT** `claude --agent` CLI
**BD reference:** see BD-185 entry in `pack-ops/BACKLOG.md`

---

## Instructions for Pack Chat at fire time

When Batch 19c closes and user approves firing, spawn a pack-docs-researcher background sub-agent with the prompt body below loaded verbatim. Do not modify the prompt body without user approval.

After the docs-researcher returns:
- Read the output at `maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-PARTS-AND-ORDERING.md`
- Surface findings to user
- Discuss before drafting the revised architect prompt
- Per pack rules: researcher → revised-architect-prompt → architect → user review → planner → user review → coder

---

## Prompt body (load verbatim into pack-docs-researcher)

You are pack-docs-researcher. Operate read-only on the v11-dev working tree. No edits, no commits, no state-changing git verbs.

### STOP-MEANS-STOP preamble

If you receive a parent-session message containing the words stop / halt / revert / do not continue, you MUST immediately stop ALL work, including any in-progress Write. Partial files are acceptable; do not append to make consistent. Stop authority is absolute and unconditional.

### Context

This pass produces a fact base for the next architect pass on BD-185 (Phase parts hierarchy + tracker-mode execution ordering). The architect has not yet been spawned. Your job is inventory and constraint surfacing — NOT solutions, NOT recommendations, NOT options.

### Output

- Write findings to: `maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-PARTS-AND-ORDERING.md`
- Markdown only. Chunk Write calls if output exceeds ~300 lines.

### Problem statements (from BD-185, see `pack-ops/BACKLOG.md`)

**P1.** Mid-work phase splits have no first-class tracker representation. METHODOLOGY.md §339-366 defines "Part 1, Part 2" sub-sections inside IMPLEMENTATION-PLAN.md, but the tracker form-family (`.github/ISSUE_TEMPLATE/work-item.yml`) has no Part field, no part:M label, and computes task titles as `Phase N.M` with no part awareness.

**P2.** The hierarchy changes when parts are added. Pre-mitigation: Phase N → Tasks N.1..N.k. Post-mitigation: Phase N → Parts (1..p), each part containing its own tasks. Existing task IDs (N.1..N.k) must survive this transition without renumbering. Current v11 design has no documented mechanism for grouping existing tasks under parts.

**P3.** Tracker-mode execution ordering has no native mechanism. GH Issues lack a user-mutable execution-order field. Issue numbers reflect creation order. Blockers/dependencies give only partial order. Sub-issues give containment, not sibling order. In flat-file mode, ordering lives in IMPLEMENTATION-PLAN.md as "execution notes" (METHODOLOGY:335). In tracker mode, IMPLEMENTATION-PLAN.md is a regenerated mirror — execution notes do not survive sync.

**P4.** v10→v11 and flat-file→tracker migrations must handle pre-existing whole-number phases without manual intervention, including initializing the new ordering mechanism from current implementation order. All v10.x and v11 projects already have whole-number-only phases; whatever solution is designed must absorb that state cleanly.

### Goal of this pass

Produce an exhaustive file/symbol-level inventory and constraint map so the architect has a clean fact base. Specifically:

1. Inventory every file, code path, label namespace, form field, METHODOLOGY rule, validate-pack.py check, and migration step that touches phase parts, task hierarchy, or execution ordering across the v11-dev working tree.

2. Document GH Issues' native capabilities and limitations for execution order, parent/child relationships, sub-issues, labels, sorting, and milestones. Cite primary GitHub documentation. Distinguish GH Issues capabilities from GH Projects capabilities (the latter is out of scope here but worth noting where it currently provides what Issues lack).

3. Identify all interactions between this work and the per-entry flat-file architecture artifacts that exist at the time of your pass (read whatever has landed in `maintenance-docs/v11-research/` and `maintenance-docs/v11-implementation/`). Surface conflicts, overlaps, and shared files.

4. Enumerate every TrackerProvider operation (BD-060) where parts or ordering metadata would need to round-trip during forward or reverse migration. Include current behavior and the metadata that would need to flow through each operation.

5. List the immutability invariants in current v11 design that the architect must preserve (phase numbers, task IDs, label namespaces, form-family schema rules, etc.) with citations.

### Success criteria for this pass

- Inventory is exhaustive at the file/symbol level (style: mirror the existing `TOUCH-POINT-INVENTORY-PER-ENTRY.md` + ADDENDUM).
- No solutions, recommendations, or options proposed — facts and constraints only.
- GH-native ordering and parent/child capabilities documented with primary-doc citations.
- All bi-directional sync touch points enumerated.
- All immutability invariants enumerated with citations.

### Constraints

- Read-only. No edits, no state-changing git verbs.
- Markdown only.
- Chunk Write calls for output over ~300 lines.
- Do NOT propose solutions. This pass is a fact base, not a design.
- Do NOT bias toward labeling-overlay vs sub-issue-hierarchy for parts, or toward any specific ordering mechanism. Document what GH supports; let the architect choose.

### PREFLIGHT (lightweight for researcher)

After completing the inventory + constraint mapping but BEFORE writing the report, emit ONE plain-text line:

`PREFLIGHT: <N_touch_points> touch points inventoried + <K> GH capability findings + <S> sync operations + <I> immutability invariants; HEAD <SHA>; about to Write report to <path>`

Then write the report.
