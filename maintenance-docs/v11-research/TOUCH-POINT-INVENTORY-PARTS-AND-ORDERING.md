# TOUCH-POINT-INVENTORY-PARTS-AND-ORDERING.md

**Authored by:** pack-docs-researcher (read-only enumeration pass).
**Date:** 2026-05-24 (US/Pacific).
**Branch:** v11-dev.
**Repo HEAD at authoring:** a5c7e62 — docs: v11 — BD-185 open (Batch 19d phase parts + ordering, pack-only).
**Source BD:** BD-185 (`pack-ops/BACKLOG.md:1744-1789`).
**Sidecar inputs:**
- `maintenance-docs/v11-research/BD-185-DOCS-RESEARCHER-QUEUED-PROMPT.md` (the prompt that authorized this pass)
- `maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-GROUPINGS-V2.md` (style mirror + BD-185-adjacent constraint surface, especially §6.M + §8.4)
- `maintenance-docs/archive/v11/TOUCH-POINT-INVENTORY-PER-ENTRY.md` (additional style mirror)
- `maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md` (C1 phases-only-membership constraint that excludes phase parts from groupings)

> **CORRECTION (BD-195 S1, 2026-05-31):** Several rows + decision-checklist
> items below frame phase-parts as a **v11.1** feature landing under a
> `templates-archive/v11.1/phase-part-v11.1/` cut (e.g., §3.I.2 L231 "Adding
> `phase-part-v11.1` would extend this", §6 L559
> `<!-- template_version: phase-part-v11.1 -->`, the §"check_template_archive_v11"
> row L614 "the v11.1 cut (not v11.0) gains it", and the open Part-decision
> checklist items L993 `template:phase-part-v11.1?` / L998 "Template archive cut
> decision (v11.0 = closed; v11.1 = new — landing under
> `templates-archive/v11.1/phase-part-v11.1/`)"). That phase-parts-as-v11.1
> framing is **fictional contamination**, retired per BD-195 S1·C3. Phase-parts
> was always **v11.0**; v11.0 is UNRELEASED and was never frozen/"closed". The
> phase-part SCHEMA now lives at
> `maintenance-docs/v11-research/templates-archive/v11.0/phase-part-v11.0/SCHEMA.md`;
> the `templates-archive/v11.1/` directory no longer exists. This is a tracked,
> completed read-only inventory (a constraint fact base) — its body is preserved
> unaltered, but every affected `v11.1` phase-part framing below is
> **superseded** by the corrected v11.0 fact. **Held-state note:** BD-185 is
> PAUSED pending BD-195 Step 9 (`pack-ops/BACKLOG.md` BD-185 entry), and the
> BD-185 V2 architect substrate that consumed this inventory
> (`ARCHITECTURE-BD-185-V2.md`) is itself held. When the BD-185 restart resumes,
> the open Part-decision-checklist items above (L991–L998) MUST be read against
> the corrected v11.0 fact — NOT re-imported as live "v11.1 = new" decisions.
> See `AUDIT-BD-195-S1-INFO1-SWEEP.md` (surface G2 + §3 sequencing note).

## Purpose

Comprehensive, read-only enumeration of every file in the pack repo that touches phase parts, task hierarchy, or execution ordering — produced as a constraint fact base for the forthcoming pack-architect pass on BD-185.

Every row in §3 (touch-point table) must be covered by the BD-185 architecture doc (by section number) or explicitly deferred with rationale. The architect must not skip touch points; this inventory makes them explicit. The architect must not pre-bias toward labeling-overlay vs. sub-issue-hierarchy for parts, or toward any specific ordering mechanism — §4 (GH-native capabilities) catalogues what GH supports; §5–§9 catalogue the existing pack surface; the architect chooses among the cataloged options.

**Out of scope by BD-185 entry §"Out of scope":** GH Projects integration (v11.1, parking-lot at `maintenance-docs/v11-research/V11.1-DISCUSSION-GITHUB-PROJECTS.md` on `main`); non-github backends (linear/jira/redmine — reserved); STATUS.md schema changes beyond its current dashboard role; letter-suffix phase forms (7a, 7b — rejected).

## Conventions

- Paths are repo-root-relative unless otherwise noted.
- `Scope` is one of `pack` / `project` / `both`.
- Citations use `path:line` for v11-dev files (verified at HEAD above).
- "Phase parts" / "Parts" = the BD-185 mid-work splitting mechanism that introduces `### Part 1 — <subtitle>` / `### Part 2 — <subtitle>` sub-sections inside a phase block (per METHODOLOGY.md:420-428). This is distinct from `phase-N.M` (phase tasks).
- "Phase tasks" = first-class L2 entities identified by `phase-N.M` (per ARCHITECTURE-V3.3-DELTA.md §2 D-21 + §6.4).
- "Execution ordering" = the order in which phases are executed (P3 in the BD-185 entry).
- "Task ordering" = the order in which tasks (`phase-N.M`) appear inside a phase. Task ordering already has a designed mechanism (`task_order` sidecar field per V3.2 §4.3 / V3.3 §3 carry-forward); BD-185's P3 is about PHASE-level execution ordering, not task ordering.
- All file-line citations were verified at HEAD a5c7e62. Use `git diff` to validate freshness if reading this doc on a later commit.

## Section index

1. §1 — Problem statements (verbatim from BD-185 entry)
2. §2 — Phase parts / parts terminology (current state)
3. §3 — Touch-point table (every file at file/symbol level)
4. §4 — GH-native capabilities (parts hierarchy + ordering; primary-doc citations)
5. §5 — Form-family and label-namespace inventory
6. §6 — METHODOLOGY.md rules touching phase shape and execution ordering
7. §7 — validate-pack.py check inventory (parts + ordering touch points)
8. §8 — TrackerProvider (BD-060) sync surface — every op where parts/ordering metadata would need to round-trip
9. §9 — Immutability invariants the architect must preserve (with citations)
10. §10 — Migration-step inventory (v10→v11 + v11.0 flat→tracker)
11. §11 — Interactions with in-flight per-entry artifacts (overlap + conflict surface)
12. §12 — Open observations (anomalies, naming asymmetries, unsigned spaces)

---

## §1 — Problem statements (verbatim from BD-185)

Reproduced from `pack-ops/BACKLOG.md:1757-1767` (the BD-185 entry's Description) without paraphrase or interpretation:

**P1.** Mid-work phase splits have no first-class tracker representation. METHODOLOGY.md §339-366 defines "Part 1, Part 2" sub-sections inside IMPLEMENTATION-PLAN.md, but the tracker form-family (`.github/ISSUE_TEMPLATE/work-item.yml`) has no Part field, no part:M label, and computes task titles as `Phase N.M` with no part awareness.

**P2.** The hierarchy changes when parts are added. Pre-mitigation: Phase N → Tasks N.1..N.k. Post-mitigation: Phase N → Parts (1..p), each part containing its own tasks. Existing task IDs (N.1..N.k) must survive this transition without renumbering. Current v11 design has no documented mechanism for grouping existing tasks under parts.

**P3.** Tracker-mode execution ordering has no native mechanism. GH Issues lack a user-mutable execution-order field. Issue numbers reflect creation order. Blockers/dependencies give only partial order. Sub-issues give containment, not sibling order. In flat-file mode, ordering lives in IMPLEMENTATION-PLAN.md as "execution notes" (METHODOLOGY:335). In tracker mode, IMPLEMENTATION-PLAN.md is a regenerated mirror — execution notes do not survive sync.

**P4.** v10→v11 and flat-file→tracker migrations must handle pre-existing whole-number phases without manual intervention, including initializing the new ordering mechanism from current implementation order. All v10.x and v11 projects already have whole-number-only phases; whatever solution is designed must absorb that state cleanly.

**Important wording correction (verified during research).** P1 cites METHODOLOGY.md §339-366 for the "Part 1, Part 2" definition. The CURRENT live file at HEAD a5c7e62 places that definition at `supporting-docs/METHODOLOGY.md:414-441` ("### Multi-part phases" section), and the "Execution note" mechanism cited at "METHODOLOGY:335" in P3 actually appears at `supporting-docs/METHODOLOGY.md:375` (in the per-phase format template) and `supporting-docs/METHODOLOGY.md:410` (the phase-numbering-rules bullet). The line numbers in the BD-185 prompt are stale; the section names are correct. The architect should use the section names ("Multi-part phases", "Execution note") for citations rather than line numbers, per pack memory `reference_pack_filename_uniqueness` (and per `project-template/CLAUDE.md:319-321`: "use the symbol name not the line number. Line numbers drift with every edit; symbol names are stable.").

---

## §2 — Phase parts / parts terminology — current state

### §2.1 — Where "Part" is defined today (flat-file)

`supporting-docs/METHODOLOGY.md:414-441` (Part 4 § "Multi-part phases"):

- The term **Part** is reserved for "sequential implementation chunks" of a phase. "Pass" is reserved for the coder/reviewer cycle counter — these two terms MUST NOT be confused (`METHODOLOGY.md:417-418`).
- Flat-file shape inside IMPLEMENTATION-PLAN.md: `### Part 1 — [Subtitle]` and `### Part 2 — [Subtitle]` are H3 sub-sections within the H2 phase (`METHODOLOGY.md:422-428`).
- Report-header convention for coder/reviewer/fix-coder agents: append `, Part [M]` to the phase title (`METHODOLOGY.md:430-437`):
  - `Phase [N] — [Phase title], Part [M] — Coder Report, Pass 1`
  - `Phase [N] — [Phase title], Part [M] — Reviewer Report, Pass [N]`
  - `Phase [N] — [Phase title], Part [M] — Fix Cycle Coder Report, Pass [N]`
- Pass counter resets to 1 at the start of each new Part (`METHODOLOGY.md:431`).
- Single-part phase uses unchanged header format — `, Part 1` is NEVER appended when there is only one part (`METHODOLOGY.md:439-441`). This means Parts are ALWAYS pluralized — a phase has either ZERO Parts (one chunk, unannotated) or 2+ Parts (multi-chunk). Never 1 Part.
- The same Multi-part wording appears at `supporting-docs/METHODOLOGY.md:967-974` (Part 5 § "Multi-part phase report headers") — duplicated for report-header context.

### §2.2 — How a phase gets Parts added — triggering mechanism

`supporting-docs/METHODOLOGY.md:316-323` (Planner trigger rule, Part 3):

- Trigger 1: phase has more than ~5 tasks, OR task dependencies are non-linear.
- Trigger 2: PM chat cannot map plan description to discrete verifiable tasks.
- Trigger 3: a coder has failed the same phase twice without progress (and the cause is task definition, not architecture).

When the planner runs and decides to split a phase, it emits `### Part 1` / `### Part 2` sub-sections per `METHODOLOGY.md:414-428`. **NB** — the rule says "a planning agent recommends splitting" (`METHODOLOGY.md:416-417`); the actual split is performed by the planning agent's output (the updated IMPLEMENTATION-PLAN.md). There is NO existing programmatic verb (`pack phase split` or analog) that creates Parts.

Trigger P-A / P-B / P-C in `supporting-docs/METHODOLOGY.md:660-680` (mid-phase planner triggers) cover task-level revision needs (Trigger P-C names "Task-ordering revision discovered mid-phase" — note this is TASK ordering inside a phase, not PHASE ordering at the IMPLEMENTATION-PLAN level).

### §2.3 — Where "Part" is mentioned outside METHODOLOGY

- `project-template/docs/pack/prompts/` (coder.md / reviewer.md / planner.md): per the `, Part [M]` header convention. Concrete cites: `project-template/docs/pack/prompts/coder.md:118` (REPORT FILE comment) — phase-N pattern; the per-prompt body inherits the METHODOLOGY § Part 5 convention but does not explicitly enumerate Part labels.
- No other file in the pack repo declares Part-specific grammar. Searches at HEAD a5c7e62 for `Part 1\|Part 2\|Part [0-9]\|multi-part\|Multi-part` produced 0 hits inside `scripts/`, `scripts/lib/`, `scripts/tests/`, `scripts/lib/per-entry/`, `scripts/lib/migrate-v10-to-v11/`, `.github/ISSUE_TEMPLATE/`, `project-template/.github/ISSUE_TEMPLATE/`, `pack-ops/`, and `maintenance-docs/v11-research/templates-archive/v11.0/` (i.e., no Part field in any form, no Part-recognition in any parser, no Part-aware emitter, no Part-aware label, no Part-aware test fixture).

### §2.4 — "Part" vs the existing `phase-N.M` task hierarchy

The two concepts have no documented relationship at HEAD:

- **Tasks** (`phase-N.M`) are first-class L2 entities in tracker (`ARCHITECTURE-V3.3-DELTA.md` §2 D-21 + §6.4) with their own pack-id, label family, sub-issue parentage, template_version (`phase-task-v11.0`), state taxonomy, dependency edges, and round-trip carriers (title prefix + body marker). See `maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md`.
- **Parts** are flat-file H3 sub-sections inside a phase epic body, with no tracker representation today. They exist only in METHODOLOGY.md and in coder/reviewer report headers. They have no pack-id, no label, no template_version, no sub-issue placement, no state taxonomy, no round-trip carrier.

P2 of BD-185 surfaces the question: when Parts are introduced, how do `phase-N.M` tasks (already existing) relate to the Parts? METHODOLOGY.md is silent on this; the `### Tasks` H3 sits between the H2 phase heading and the `### Part 1 / ### Part 2` H3 sub-sections, but METHODOLOGY does not say whether tasks go INSIDE Parts (`### Part 1` contains its own `### Tasks` and `#### N.M`), or OUTSIDE Parts (tasks at the phase level, Parts as parallel implementation-strategy markers).

### §2.5 — Forward-pointing references to BD-185's Part suffix grammar (NOT yet adopted)

These references PROPOSE a possible grammar but commit to nothing. The architect is NOT bound by them; they are noted only because they exist in the working tree at HEAD a5c7e62:

- `maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md:69` (C1 constraint): "Phase parts (`phase-N.Part-M` per BD-185)" — this is the only known forward-pointing identifier-grammar suggestion in the working tree. The form `phase-N.Part-M` is a guess by Pack Chat at sidecar-time, not an architect decision. The architect is free to choose any grammar that satisfies BD-185 SC3 (no renumbering of existing N or N.M).
- `maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-GROUPINGS-V2.md:413` ("`**Member phases (by ID):**` — bulleted list of phase IDs (`phase-N` form; possibly `phase-N.M` after BD-185 lands — see §6 below)") — uses `phase-N.M` shape rather than the `Part-M` form from REQUIREMENTS-GROUPINGS-V11.md. The two PROPOSAL surfaces disagree about the grammar; neither is authoritative.
- `pack-ops/BACKLOG.md:1750` (BD-185 entry, File/Symbol): "Part field + part:M label namespace (NEW)" — names `part:M` as a candidate label namespace. Again, this is a candidate, not a decision.

The architect should treat all three above as candidate spellings and select one (or invent another) bound by the immutability invariants in §9.

---

## §3 — Touch-point table

Single flat table of every file the architect must consider when designing parts hierarchy + execution ordering. Rows are grouped under sub-headings for browsability; ordering inside each group is alphabetical by path.


### §3.A — Tracker form-family (intake schema)

| # | Path | Scope | Part-related symbols | Ordering-related symbols | Notes |
|---|---|---|---|---|---|
| 3.A.1 | `.github/ISSUE_TEMPLATE/work-item.yml` | pack | none today | none today | Pack-side form. Has `wi-type` dropdown with 4 options (bd / td / phase-epic-skeleton / phase-task-skeleton — `work-item.yml`; verified at pack-root). Phase-epic-skeleton and phase-task-skeleton paths exist as rare-case fallbacks per BD-185 entry citing the form-family rule (BD-068) + template_version delta (BD-069). NO Part field, NO part:M label, NO execution-order field. |
| 3.A.2 | `project-template/.github/ISSUE_TEMPLATE/work-item.yml` | project | none today | none today | Client-side form (179 lines verified). `wi-type` dropdown lines 24-28. `wi-phase-number` input at lines 87-94 (used by phase-epic-skeleton and phase-task-skeleton). `wi-task-title` input at lines 95-101 with the M-resolution rule: "The chat composes the issue title as `Phase N.M — <task title>` where M is the next available task number under phase N." NO Part field, NO part:M label, NO Part-aware composition rule for task titles. |
| 3.A.3 | `.github/ISSUE_TEMPLATE/inbound.yml` | pack | n/a (no phase intake) | n/a | Listed for completeness; inbound form has no phase concept. |
| 3.A.4 | `project-template/.github/ISSUE_TEMPLATE/inbound.yml` | project | n/a | n/a | Same as above; client-side. |
| 3.A.5 | `.github/ISSUE_TEMPLATE/config.yml` | pack | n/a | n/a | Per-config (blank_issues_enabled=false). Listed for boundary completeness. |
| 3.A.6 | `project-template/.github/ISSUE_TEMPLATE/config.yml` | project | n/a | n/a | Same as above. |

### §3.B — Template-version archive (the v11.0 cut)

| # | Path | Scope | Part-related symbols | Ordering-related symbols | Notes |
|---|---|---|---|---|---|
| 3.B.1 | `maintenance-docs/v11-research/templates-archive/v11.0/phase-epic-v11.0/SCHEMA.md` | pack-internal (design) | none today | none today | 124 lines verified. Defines phase-epic body markers, label family (`phase-epic`, `phase-N`, `template:phase-epic-v11.0`, `derived-from:TD-NNN`, `status:*`), state mapping, body grammar with `## Phase summary` / `## Plan anchor` / `## Tasks` sections, sub-issue/hierarchy rules (children are phase-task issues), reverse-emit grammar. Tasks section is "auto-generated by chat: bullet list of phase-task issues (linked via sub-issue parent or label fallback). Updated when phase tasks are added, removed, or change state." (lines 78-80). No Part section in body, no Part label, no execution-order section. |
| 3.B.2 | `maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md` | pack-internal (design) | none today | none today | 147 lines verified. Defines phase-task body markers, label family (`phase-task`, `phase-N`, `template:phase-task-v11.0`, `derived-from:TD-NNN`, `status:<pending|in-progress|done|deferred|merged-into:phase-N|superseded-by>`), state mapping with marker→status table (lines 49-56), body grammar, sub-issue/hierarchy rules (parents are phase epics; "Phase tasks may not be parented to BD/TD entries or to other phase tasks — a phase task's parent is exactly one phase epic. Cross-phase relationships are expressed via the Dependencies section, not parent/child." — lines 104-107), reverse-emit grammar. No Part membership, no parent-Part relationship. |
| 3.B.3 | `maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md` | pack-internal (design) | none today | none today | Enumerates 5 entry types at v11.0: bd, td, phase-epic, phase-task, inbound (lines 8-14). No Part entry type. |
| 3.B.4 | `maintenance-docs/v11-research/templates-archive/v11.0/forms/work-item.yml` | pack-internal (design) | none today | none today | Byte-identical archive of the live `.github/ISSUE_TEMPLATE/work-item.yml` per BD-064 Addendum 4 §2.2. CI verifies byte-equality (validate-pack.py check `check_template_archive_v11`). |
| 3.B.5 | `maintenance-docs/v11-research/templates-archive/translations.yaml` | pack-internal (design) | none today (empty at v11.0) | none today | Translation manifest for cross-template_version migrations (BD-069). At v11.0 the manifest is empty (`translations.yaml:8-10`). The v11.1 template family that BD-185 produces would land its first entries here (architect's call on shape). |

### §3.C — Tracker provider library (BD-060 surface)

| # | Path | Scope | Part-related symbols | Ordering-related symbols | Notes |
|---|---|---|---|---|---|
| 3.C.1 | `scripts/lib/tracker-provider.sh` | pack (also installed) | none today | none today | 18 ops + raw (`provider_list`, `provider_get`, `provider_search`, `provider_create`, `provider_update`, `provider_close`, `provider_reopen`, `provider_comment`, `provider_set_labels`, `provider_set_assignee`, `provider_set_milestone`, `provider_link`, `provider_unlink`, `provider_sub_issue_create`, `provider_sub_issue_list`, `provider_sub_issue_unlink`, `provider_capabilities`, `provider_raw`) — verified at lines 125-142. Dispatcher routes to `tracker_provider_<backend>_<op>` per `_tracker_provider_dispatch` (line 100). Adding new ops requires updating both this file's switch and each backend's library. |
| 3.C.2 | `scripts/lib/tracker-provider-gh.sh` | pack | none today | none today | GH backend (785+ lines). Implements all 18 ops. Sub-issue ops are `tracker_provider_gh_sub_issue_create` (line 653), `_sub_issue_list` (line 685), `_sub_issue_unlink` (line 704). No reprioritize_sub_issue op exposed; `tracker_provider_gh_capabilities` (line 728) names hierarchy support. |
| 3.C.3 | `scripts/lib/tracker-phase-task.sh` | pack | none today | per-phase `task_order` shape | 557 lines verified. Phase-task entity model (BD-106; V3.3 §2 D-21 + §3.5). Public API: `tracker_phase_task_compose_pack_id`, `tracker_phase_task_dependency_re`, `tracker_phase_task_parse`, `tracker_phase_task_emit`. Parser produces JSON with `task_order` per phase (lines 51, 296). Emitter consumes the same shape (lines 527-549). NO Part-aware parsing; parser regex `TASK_HEADER = re.compile(r'^####\s+(\d+)\.(\d+)\s*[—-]\s*(.+?)\s*$')` (line 191) — H4 only. If Parts are introduced as a new H3 inside phases, the parser would need explicit handling (currently `OTHER_H3` regex at line 190 would treat `### Part 1` as a sibling H3 that closes the Tasks zone — see line 312-316). |
| 3.C.4 | `scripts/lib/tracker-promote.sh` | pack | none today | none today | TD promotion paths (Path 1 / Path 2 per V3.3 §3.3 / §3.4). `tracker_promote_compose_phase_section` (line 305) emits phase skeleton. `tracker_promote_compose_phase_task_block` (line 110, signature comment) emits phase task block. `tracker_promote_next_phase_task_M` (line 115) computes next available M for phase N. Path 3 (`--fold-into`) FORBIDDEN per V3.3 §3 line 27 (`tracker_promote.sh:18-19`, error message at line 178). No Part-aware promotion path. |
| 3.C.5 | `scripts/lib/tracker-labels.sh` | pack | none today | none today | Label namespaces (BD-067 / V3.3 §3.5). Entry-type provenance labels include `phase-epic`, `phase-task` (lines 76-77). Phase membership label is `phase-N` (form: `phase-3`, `phase-12`). Template-version labels include `template:phase-epic-v11.0`, `template:phase-task-v11.0` (lines 112-113). Promotion forward-pointer labels: `promoted-to:phase-N` / `promoted-to:phase-N.M` (line 38, validated at line 241 with regex `^phase-[0-9]+(\.[0-9]+)?$`). NO `part:M`, NO `template:phase-part-v11.0`, NO `order:N`. |
| 3.C.6 | `scripts/lib/tracker-links.sh` | pack | none today | none today | Cross-entity dependency links (BD-068 / V3.3 §5). Accepts `phase-N`, `phase-N.M`, `TD-NNN`, `BD-NNN` (lines 7-10, 129-130, 158-165). NO Part-id form admitted in the link grammar. |
| 3.C.7 | `scripts/lib/tracker-sidecar.sh` | pack | none today | per-phase `task_order` | Sidecar JSON composer (V3.3 §4.3). `tracker_sidecar_compose_phase_tasks_block` (line 312) emits per-phase YAML with `task_order: [N.1, N.2, ...]` and per-task body (problem / dependencies / template_version). NO Part block in the sidecar schema. |
| 3.C.8 | `scripts/lib/tracker-migrate-forward.sh` | pack | none today | per-phase `task_order` (mapping["phase-N"].task_order) | Forward migration (BD-077 + BD-106). Step 5 "For each phase: create phase epic" (line 18). `tmf_mapping_set_phase_task_order` (line 245) writes per-phase task_order into id-map.json. `tmf_mapping_get_phase_task_order` (line 267) reads it. NO Part-aware step in the forward migration. |
| 3.C.9 | `scripts/lib/tracker-migrate-reverse.sh` | pack | none today | per-phase `task_order` (read from sidecar) | Reverse migration (BD-077). `_tmr_phase_task_order` (line 101) reads `mapping["phase-N"].task_order`; fallback to numeric scan of `phase-N.M` keys (line 124). `_tmr_emit_implementation_plan` (line 683) emits IMPLEMENTATION-PLAN.md from phase-epic titles. Phase emission sorts by `phase_number` (line 697) — ascending integer order. NO Part-aware reverse emission. STATUS.md reverse-emit (`_tmr_emit_status` at line 712) sorts phases by phase_number ascending (line 733) — phase EXECUTION order is not captured in tracker state today. |
| 3.C.10 | `scripts/lib/tracker-init.sh` | pack | none today | none today | Tracker initialization (BD-064 + Addendum 4). Creates the label set per V3.3 §3.5 + the form-family seeds. No Part label provisioning. |
| 3.C.11 | `scripts/lib/tracker-mirror.sh` | pack | none today | none today | Mirror semantics (BD-103 tracker-mode mirror header injection). Reads from tracker, writes monolithic mirror with read-only header. No Part awareness. |
| 3.C.12 | `scripts/lib/tracker-config.sh` | pack | none today | none today | tracker.toml parser. No Part-related config keys. |
| 3.C.13 | `scripts/lib/tracker-cycle-check.sh` | pack | none today | none today | Cycle detection on cross-entity dependency graph. Operates on the link grammar from `tracker-links.sh`. |
| 3.C.14 | `scripts/lib/tracker-doctor.sh` | pack | none today | none today | Sanity checker. Reads id-map pack-id grammar via `^(BD|TD)-[0-9]+$|^phase-[0-9]+(\\.[0-9]+)?$` (line 101). A new Part-id grammar must be admitted here too if Parts get pack-ids. |
| 3.C.15 | `scripts/lib/tracker-errors.sh` | pack | none today | none today | Typed-error formatter. Listed for completeness. |
| 3.C.16 | `scripts/lib/tracker-header-snapshot.sh` | pack | none today | none today | Mirror-header snapshot helper. Listed for completeness. |

### §3.D — Per-entry split helpers (BD-164 + Addendum 1 + Addendum 2)

| # | Path | Scope | Part-related symbols | Ordering-related symbols | Notes |
|---|---|---|---|---|---|
| 3.D.1 | `scripts/lib/per-entry/_lib.sh` | pack | none today | none today | Shared parser + stream-shape constants. The 5 streams declared at line 64: `pack-backlog`, `pack-changelog`, `project-backlog`, `project-implementation-plan`, `project-changelog`. The `project-implementation-plan` stream's entry regex is `^phase-[0-9]+\.md$` (line 100), set per Addendum #1 §6.4 BD-167 spec override (tasks INLINE in the phase file). Decompose/emit anchors are H2 `## Phase N — ` per `decompose.sh:131-137`. NO Part-id stream, NO Part regex, NO Part filename. |
| 3.D.2 | `scripts/lib/per-entry/decompose.sh` | pack | none today | none today | Decomposes a monolithic file into per-entry files. The project-implementation-plan anchor is `^## Phase (\d+) — ` (line 133); section break is any `^## ` H2 (line 137). Parts as H3 sub-sections would NOT trigger section break (H2-only). The current decompose logic captures everything from the phase H2 through to the next H2 boundary; if Parts are H3 sub-sections, they would be captured as content WITHIN the phase entry, not as separate entries. |
| 3.D.3 | `scripts/lib/per-entry/mirror-generate.sh` | pack | none today | none today | Mirror regeneration — assembles entries back into the monolithic mirror file. Entries are emitted in lexical sort order (per `_lib.sh:64-69` ordering). For `project-implementation-plan`, `LC_ALL=C sort` on `phase-N.md` filenames produces ascending integer order (e.g., `phase-0.md`, `phase-1.md`, `phase-10.md`, `phase-2.md`, ...). **Important observation:** lexical sort on `phase-N.md` is NOT integer-order-preserving — `phase-10.md` sorts before `phase-2.md`. Inventory has not verified whether the mirror generator applies a numeric sort or accepts the lexical-sort artifact; the architect should confirm before designing any execution-order mechanism that depends on filename order. (Verification: `_lib.sh:393-401` `pe_sort_entries` uses `LC_ALL=C sort` — pure lexical.) |
| 3.D.4 | `scripts/lib/per-entry/toc-regenerate.sh` | pack | none today | none today | `_toc.md` regenerator. `project-implementation-plan` grouped by phase number (line 71); group regex is `^phase-\d+\.md$` (line 87). Group ordering at `order_groups` (line 198) — likely sorts numerically (caller should verify). NO Part-aware TOC entry. |

### §3.E — Project-template per-entry stream files (the client-side shape)

| # | Path | Scope | Part-related symbols | Ordering-related symbols | Notes |
|---|---|---|---|---|---|
| 3.E.1 | `project-template/docs/project/implementation-plan/_rules.md` | project | none today | none today | 49 lines verified. Per-stream contract for `project-implementation-plan`. Filename regex: `^phase-\d+\.md$` (line 14). Phase-state vocabulary: `pending / in-progress / done / deferred / merged-into / superseded-by` (lines 28-31). Supporting files: `_rules.md`, `_intro.md`, `_toc.md` (lines 33-37). Entry contract (lines 18-24): "Phase epic + tasks inline: H2 phase heading (`## Phase N — <title>`), `**Goal**:`, `**Prerequisite**:`, `---`, `### Tasks` (with `#### N.M — <title>` sub-sections inline), `### Verification`, `### Agent`, `### Risks`. The first line is an HTML-comment back-pointer ABOVE the phase heading." NO Part section in the entry contract. |
| 3.E.2 | `project-template/docs/project/implementation-plan/_intro.md` | project | "Part" mentions in prose | none today | "Adding a new phase" + "Updating a phase task" + "Marking phase state" prose (lines 27-44). The "Marking phase state" section enumerates the same vocabulary as `_rules.md:28-31`. NO Part mechanism in the prose. |
| 3.E.3 | `project-template/docs/project/backlog/_rules.md` | project | none today | none today | Per-stream contract for project backlog (TD-NNN entries). Listed for completeness — backlog entries reference phases via Dependencies bullets per METHODOLOGY Part 4. |
| 3.E.4 | `project-template/docs/project/changelog/_rules.md` | project | none today | none today | Per-stream contract for project changelog. Filename: `^[0-9]{4}-[0-9]{2}-[0-9]{2}(-.+)?\.md$`. Listed for completeness. |
| 3.E.5 | `project-template/docs/project/changelog/_format.md` | project | none today (changelog "Phase NN" prose) | none today | Changelog entry shape contract. Mentions `2026-04-20-phase-35.md` filename pattern (line 63). |
| 3.E.6 | `project-template/docs/project/backlog/_intro.md` | project | none today | none today | "Cross-references" mentions `phase-N`, `phase-N.M` (line 34). |

### §3.F — Pack-side per-entry stream files (for parity)

| # | Path | Scope | Part-related symbols | Ordering-related symbols | Notes |
|---|---|---|---|---|---|
| 3.F.1 | `/backlog/_rules.md` | pack | none today | none today | Per-stream contract for pack backlog (BD-NNN entries). Listed for completeness — there is NO pack-side `implementation-plan/` stream at HEAD (pack repo has no IMPLEMENTATION_PLAN.md per V3 §28.1 / `ARCHITECTURE-V3.md:603`). |
| 3.F.2 | `/changelog/_rules.md` | pack | none today | none today | Per-stream contract for pack changelog. Listed for completeness. |


### §3.G — Documentation and methodology rules

| # | Path | Scope | Part-related symbols | Ordering-related symbols | Notes |
|---|---|---|---|---|---|
| 3.G.1 | `supporting-docs/METHODOLOGY.md` Part 4 (lines 366-441) | both (pack-shipped to client at `docs/pack/`) | "Part 1", "Part 2", "Multi-part phases" (lines 414-441) | "Execution note" (line 375), "Phase numbering rules" (lines 407-412) | THE source-of-truth file. § "Part 4 — Phase Structure" carries: phase format template (lines 370-405) including `> **Execution note**: (optional) deliberate deferral or ordering constraint.` line 375; "Phase numbering rules" (lines 407-412) — "Never renumber phases", "To reorder execution, use execution notes ... not renumbering", "Insert new phases at the end of the plan", "Fractional phases (2.1, 2.2) only during early architecture work — use whole numbers after that"; § "Multi-part phases" (lines 414-441) — defines "Part" vs "pass", H3-sub-section grammar, report-header rule, single-part-NO-`, Part 1`-suffix rule. |
| 3.G.2 | `supporting-docs/METHODOLOGY.md` Part 5 § "Multi-part phase report headers" (lines 967-974) | both | "Multi-part phase report headers" | none | Restates report-header rule with example: `Phase 12 — Auth Flows, Part 2 — Reviewer Report, Pass 1` (line 974). |
| 3.G.3 | `supporting-docs/METHODOLOGY.md` Part 3 § "Planner trigger rule" (lines 310-323) | both | indirectly (split triggers) | none | The 3 planner triggers that cause Parts to be introduced. |
| 3.G.4 | `supporting-docs/METHODOLOGY.md` Part 5 § "Workflow 4 — Fix cycle" + § "Trigger P-A/P-B/P-C" (lines 580-689) | both | none directly | "Task-ordering revision discovered mid-phase" Trigger P-C (line 673) | Trigger P-C governs TASK-order revisions inside a phase mid-execution. NOT phase EXECUTION-order revision. |
| 3.G.5 | `supporting-docs/MIGRATION-v10-to-v11.md` § "Per-entry decomposition" (lines 243-313) | pack-internal (user-facing migration narrative) | none today | none today | Documents per-entry tree for client projects after v10→v11 migration. NO Part-aware migration documented; pre-existing whole-number phases pass through. |
| 3.G.6 | `project-template/CLAUDE.md` § "Document locations" + "Per-entry source-of-truth trees" + "Phase routing" | project | none today | none today | Trinity files. Phase routing table (lines 374-389) names which agent runs which phase. No Part-aware routing. |
| 3.G.7 | `project-template/AGENTS.md` (same sections, trinity parity) | project | none today | none today | Same as above. |
| 3.G.8 | `project-template/GEMINI.md` (same sections, trinity parity) | project | none today | none today | Same as above. |
| 3.G.9 | `project-template/docs/pack/PM-CHAT.md` | project | none today | none today | PM-Chat operating doc. Mentions `pack td promote --to=phase-N` / `--to=phase-N.M` (lines 540-647). No Part-promotion verb. |
| 3.G.10 | `project-template/docs/pack/prompts/coder.md` | project | "Part [M]" via METHODOLOGY § Part 5 inheritance | none | Coder prompt template. Inherits the per-part report-header rule from METHODOLOGY. |
| 3.G.11 | `project-template/docs/pack/prompts/reviewer.md` | project | "Part [M]" via inheritance | none | Same as coder. |
| 3.G.12 | `project-template/docs/pack/prompts/planner.md` | project | indirectly (planner emits Parts) | none | The planner is the agent that decides to split a phase into Parts (per METHODOLOGY § "Planner trigger rule"). |
| 3.G.13 | `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` | project | none today | none today | TD-promotion-path help. No Part-promotion verb. |
| 3.G.14 | `project-template/docs/pack/HELP-FRAGMENT.md` | project | none today | none today | Pack verb help. No Part-related verb. |

### §3.H — validate-pack.py (the CI gate)

| # | Path / check | Scope | Part-related symbols | Ordering-related symbols | Notes |
|---|---|---|---|---|---|
| 3.H.1 | `scripts/validate-pack.py` Check 32 (per-entry mirror in-sync, BD-168) at line 3065 | both | none today | none today | Verifies `IMPLEMENTATION-PLAN.md` mirror is in-sync with `implementation-plan/phase-N.md` per-entry tree. Stream regex `^phase-\d+\.md$`. NO Part-id stream. |
| 3.H.2 | `scripts/validate-pack.py` Check 33 (per-entry _toc.md in-sync, BD-168) at line 3273 | both | none today | none today | Verifies `_toc.md` regenerator output matches on-disk. Grouped by phase number for project-implementation-plan. |
| 3.H.3 | `scripts/validate-pack.py` Check 34 (cross-reference integrity, BD-168) at line 3472 | both | none today | none today | Reads per-entry cross-references: `BD-NNN`, `TD-NNN`, `vN.M`, `phase-N[.M]` (line 136). NO Part-id form admitted. |
| 3.H.4 | `scripts/validate-pack.py` Check 35 (Phase-task lib invariants, BD-106) at line 3613 | pack | none today | none today | Verifies `scripts/lib/tracker-phase-task.sh` exists; Path 3 (`folded-into:`) forbidden. |
| 3.H.5 | `scripts/validate-pack.py` `check_issue_template_forms` (line 1067) | both | none today | none today | Verifies `work-item.yml` `wi-type` has exactly 4 options (bd / td / phase-epic-skeleton / phase-task-skeleton) per V3.3 §6.1. Adding a phase-part-skeleton option would require either expanding `expected_wi_type_options` (line 1091) or living with the failure. |
| 3.H.6 | `scripts/validate-pack.py` `check_template_archive_v11` (line 1171) | pack | none today | none today | Verifies template archive at v11.0 carries the 5 entry-type subdirectories (bd, td, phase-epic, phase-task, inbound — line 1177). Adding phase-part as a new entry type would require a 6th subdirectory under v11.1 (BD-185 carry-out). |
| 3.H.7 | `scripts/validate-pack.py` cross-reference filename allowlist (lines 4706-5168) | both | `phase-N.md`, `phase-N.M.md`, `phase-0.md`, `phase-NN.md`, `phase-35.md` allowlisted | none | Lines 4748, 5121, 5164-5168 enumerate phase-shape filenames the validator admits in prose. A new phase-part filename would need to be added if Parts get per-entry files. |

### §3.I — Tests and fixtures

| # | Path | Scope | Part-related symbols | Ordering-related symbols | Notes |
|---|---|---|---|---|---|
| 3.I.1 | `scripts/tests/test-tracker-phase-task.sh` | pack | none today | per-phase `task_order` test cases | 350+ lines. Tests parser/emitter for `### Tasks` block. Test 5.6 enforces Path 3 forbidden invariant (line referenced in `validate-pack.py:3623`). Test fixtures under `scripts/tests/fixtures/tracker-phase-task/`. NO Part-aware test. |
| 3.I.2 | `scripts/tests/template-version-test.sh` | pack | none today | none today | Tests `template_version` parsing for `bd-v11.0`, `td-v11.0`, `phase-epic-v11.0`, `phase-task-v11.0`, `inbound-v11.0`. Lines 38, 45, 58, 67 verified. Adding `phase-part-v11.1` (or whatever naming Architect picks) would extend this. |
| 3.I.3 | `scripts/tests/tracker-init-test.sh` | pack | none today | none today | Tests label provisioning. Line 280-288 enumerates type-family labels: `bd-entry`, `td-entry`, `phase-epic`, `phase-task`, `work-item`, `inbound`, `external`, `pack-feedback`, `needs-triage`. Line 288 enumerates template-version labels: `template:bd-v11.0`, `template:td-v11.0`, `template:phase-epic-v11.0`, `template:phase-task-v11.0`. Adding part labels expands these sets. |
| 3.I.4 | `scripts/tests/test-per-entry.sh` | pack | none today | none today | Per-entry decompose/regenerate test. Cited by `tracker-init-test.sh:180`. |
| 3.I.5 | `test-fixtures/manifest.txt` + `test-fixtures/build.sh` | pack | none today | none today | Fixture manifest (regenerated; CI checks byte-equality per BD-115 + RELEASE-GATE item 5). Per pack memory `feedback_manifest_regen_on_v11_surface`, any commit touching `project-template/`, `scripts/`, `pack-ops/`, or `supporting-docs/` MUST regenerate this. BD-185 implementation will touch all 4 surfaces in some form, so the regen rule applies. |

### §3.J — README, BACKLOG and other operational surfaces

| # | Path | Scope | Part-related symbols | Ordering-related symbols | Notes |
|---|---|---|---|---|---|
| 3.J.1 | `pack-ops/BACKLOG.md` BD-185 entry (lines 1744-1789) | pack | "Part", "Multi-part phases", "parts (1..p)" | "Execution ordering", "execution-order field", "execution notes", "task_order" | The BD itself. |
| 3.J.2 | `pack-ops/CHANGELOG.md` | pack | none today | none today | Where the eventual BD-185 entry lands at version cut. Listed for boundary completeness. |
| 3.J.3 | `pack-ops/HELP-FRAGMENT-TRACKER.md` | pack | none today | none today | Pack-side TD-promote help. Mentions `pack td promote --to=phase-N` / `--to=phase-N.M`. |
| 3.J.4 | `pack-ops/HELP-FRAGMENT-PACK.md` | pack | none today | none today | Pack-side verb help. |
| 3.J.5 | `pack-ops/PACK-CHAT.md` | pack | none today | none today | Pack Chat operating doc. |
| 3.J.6 | `README.md` (pack repo) | pack | none today | none today | Version table + repository layout. |
| 3.J.7 | `pack-ops/PACK-AGENTS.md` | pack | none today | none today | Pack agent roster. |

### §3.K — STATUS.md (the BD-185 SC5 lock surface)

STATUS.md does NOT exist as a pack-template file at HEAD (no `project-template/STATUS.md`); it is created at project kickoff by PM Chat (`METHODOLOGY.md:458`: "Create `BACKLOG.md`, `STATUS.md`, `CHANGELOG.md` (initially sparse)"). The schema is defined entirely in METHODOLOGY.md:

| # | Reference | Scope | Part-related symbols | Ordering-related symbols | Notes |
|---|---|---|---|---|---|
| 3.K.1 | `supporting-docs/METHODOLOGY.md:190` (Part 2 table) | both | none today | none today | "STATUS.md | Current phase, phase table, next actions, key metrics" — schema. |
| 3.K.2 | `supporting-docs/METHODOLOGY.md:202` (Part 2 rule) | both | none today | none today | "STATUS.md is updated after every phase — stale status is worse than no status." — update cadence. |
| 3.K.3 | `supporting-docs/METHODOLOGY.md:1556-1580` (Part 9 file-write authority) | both | none today | none today | STATUS.md is PM-chat-write-after-phase. |
| 3.K.4 | `scripts/lib/tracker-migrate-reverse.sh::_tmr_emit_status` (line 712) | pack | none today | phase emission sorted by phase_number ascending (line 733) | The reverse-migration STATUS.md emitter. Phases sorted by integer phase number; NO execution-order metadata round-tripped. |
| 3.K.5 | BD-185 SC5 (`pack-ops/BACKLOG.md:1774`) | pack | n/a | LOCK constraint | "STATUS.md remains a dashboard. Its role does not expand to ordering SSOT in either mode." This is the architect's constraint: STATUS.md schema is OFF the table for ordering. |

### §3.L — Migrator scripts and stages

| # | Path | Scope | Part-related symbols | Ordering-related symbols | Notes |
|---|---|---|---|---|---|
| 3.L.1 | `scripts/migrate-v10-to-v11.sh` | pack | none today | none today | Top-level migrator adapter. Sources `migrator-core.sh` (BD-119 framework) and supplies MIGRATOR_* vars + hook functions. |
| 3.L.2 | `scripts/lib/migrate-v10-to-v11/decompose.sh` | pack | none today | none today | The `_v10_to_v11_decompose_streams` operation (BD-164/167) — per `MIGRATION-v10-to-v11.md:292-297`, runs as the 6th and last in-sequence step, reads final v11-shape monolithic files, emits per-entry tree + regenerated mirror. NO Part-aware decompose. |
| 3.L.3 | `scripts/lib/migrate-v10-to-v11/apply.sh` | pack | none today | none today | Apply-phase orchestration. |
| 3.L.4 | `scripts/lib/migrate-v10-to-v11/checkpoint.sh` | pack | none today | none today | Two-phase checkpoint state. The word "phase" here means migrator-phase (Phase A / Phase B), NOT project-phase. |
| 3.L.5 | `scripts/lib/migrate-v10-to-v11/dry-run.sh` | pack | none today | none today | Dry-run summary. |
| 3.L.6 | `scripts/lib/migrate-v10-to-v11/resume.sh` | pack | none today | none today | Resume-after-failure. |
| 3.L.7 | `scripts/lib/migrate-v10-to-v11/gate-1-dry-run-summary.sh` | pack | none today | none today | Gate 1. |
| 3.L.8 | `scripts/lib/migrate-v10-to-v11/gate-2-phase-a-verify.sh` | pack | none today | none today | Gate 2 (Phase A = local file changes). |
| 3.L.9 | `scripts/lib/migrate-v10-to-v11/gate-3-phase-b-verify.sh` | pack | none today | none today | Gate 3 (Phase B = optional tracker integration). |
| 3.L.10 | `scripts/migrator-core.sh` | pack | none today | none today | BD-119 framework. |
| 3.L.11 | `scripts/migrator-stages.sh` | pack | none today | none today | S0..S6 stage orchestration. |
| 3.L.12 | `scripts/migrator-skills.sh` | pack | none today | none today | Skills mass-copy. |
| 3.L.13 | `scripts/migrator-manifest.sh` | pack | none today | none today | Manifest application. |
| 3.L.14 | `scripts/init-project.sh` | pack | none today | none today | New-project bootstrap. Stage S6 copies METHODOLOGY.md + INSTALL-PROCEDURES.md; Stage S11 copies HELP-FRAGMENT-TRACKER.md (per pack memory `feedback_manifest_regen_on_v11_surface`). Empty mirrors at `docs/project/{BACKLOG.md,IMPLEMENTATION-PLAN.md,CHANGELOG.md}` (line 1030). |


---

## §4 — GH-native capabilities (parts hierarchy + ordering)

This section catalogues what GitHub Issues / Projects / gh CLI / GH MCP server natively support for:
- Parent / child relationships (sub-issues)
- Sibling ordering of children under a parent
- User-mutable per-issue execution-order fields
- Sorting + filtering of issues into an ordered view

Every claim is cited to primary GitHub documentation. The architect is NOT bound to use any of these; the section is a fact base for the architect's design choices.

### §4.1 — Sub-issues (parent / child) — GA 2025

Source: [Evolving GitHub Issues and Projects (GA) · community · Discussion #154148](https://github.com/orgs/community/discussions/154148); [REST API endpoints for sub-issues](https://docs.github.com/en/rest/issues/sub-issues); [GitHub Issues & Projects 2024-12-12 Changelog](https://github.blog/changelog/2024-12-12-github-issues-projects-close-issue-as-a-duplicate-rest-api-for-sub-issues-and-more/); [How GitHub Built Sub-Issues, InfoQ 2025-04](https://www.infoq.com/news/2025/04/github-subissues-journey/).

**Hard limits (verified at HEAD of `EXTERNAL-RESEARCH.md` 2026-04-30; cross-referenced to source):**
- **Depth:** 8 levels (per Discussion #154148).
- **Sub-issues per parent:** 100 (per Discussion #154148).
- **Parents per issue:** 1 (per Discussion #154148). A child has exactly one parent. This is the load-bearing constraint for Parts-as-sub-issues: a phase task can only be parented to ONE thing (today: its phase epic; if Parts ship as sub-issues, the choice is parent-by-phase OR parent-by-Part, not both).

**API surfaces:**
- REST: `/repos/{owner}/{repo}/issues/{issue_number}/sub_issues` — `GET` list, `POST` add, `DELETE` remove. Plus a **reprioritize endpoint** ([REST API endpoints for sub-issues](https://docs.github.com/en/rest/issues/sub-issues); confirmed in [Sub-issues Public Preview · Discussion #146942](https://github.com/orgs/community/discussions/146942) as part of the 2024-12-12 changelog cut; subsequent improvements in [2025-09-11 changelog](https://github.blog/changelog/2025-09-11-a-rest-api-for-github-projects-sub-issues-improvements-and-more/)).
- GraphQL: mutation `reprioritizeSubIssue` with input parameters `issueId`, `subIssueId`, `afterId` (per [GitHub GraphQL mutations reference](https://docs.github.com/en/graphql/reference/mutations)).
- The reprioritize endpoint accepts a sibling ordering hint (specifying placement relative to another sub-issue under the same parent — see §4.2 below).

**Sub-issue ordering is sibling-only.** The reprioritize endpoint orders SIBLINGS under a SHARED PARENT. It does not produce a global execution order across the whole project — it produces a parent-scoped order for each parent.

**Closing semantics.** Closing the parent does NOT auto-close children, and vice versa. The relationship is a link, not a cascade ([Discussion #154148](https://github.com/orgs/community/discussions/154148); cited in `EXTERNAL-RESEARCH.md:71-72`).

**gh CLI gap.** `gh` does NOT have a built-in `gh issue sub-issue` subcommand as of late 2025 ([cli/cli #10298](https://github.com/cli/cli/issues/10298), cited in `EXTERNAL-RESEARCH.md:74-78`). Third-party extensions fill the gap ([yahsan2/gh-sub-issue](https://github.com/yahsan2/gh-sub-issue), [agbiotech/gh-sub-issue](https://github.com/agbiotech/gh-sub-issue), [jwilger/gh-issue-ext](https://github.com/jwilger/gh-issue-ext), [d-oit/gh-sub-issues](https://github.com/d-oit/gh-sub-issues)). The pack today calls sub-issue ops via `gh api graphql` directly per `scripts/lib/tracker-provider-gh.sh` `_gh_has_sub_issue_extension` (line 47) and `tracker_provider_gh_sub_issue_create` (line 653).

### §4.2 — REST reprioritize_sub_issue endpoint

Source: [REST API endpoints for sub-issues](https://docs.github.com/en/rest/issues/sub-issues).

**Endpoint shape (verified via web search 2026-05-24):** the reprioritize endpoint is `PATCH /repos/{owner}/{repo}/issues/{issue_number}/sub_issues/priority` (search confirmed "PATCH /repos/{owner}/{repo}/issues/{issue_number}/sub_issues/priority endpoint allows you to reorder sub-issues, using a curl request with parameters like `sub_issue_id` and `after_id`"). Body parameters known from search results: `sub_issue_id` (the child to move) and `after_id` (the sibling to place it after); `before_id` referenced in some discussions but not verified in primary source.

**Caveat — primary-source verification gap.** The web-search summary above was sourced from a Bing/Google search snippet of `https://docs.github.com/en/rest/issues/sub-issues` (2026-05-24). The exact request-body shape (whether parameter names are `sub_issue_id`/`after_id`, or `child_id`/`before_id`, or different) is not directly verifiable from snippets — the architect MUST verify against the live primary doc before committing to a specific call shape. Mark this as a residual research gap if the architect proceeds with a sub-issue-reprioritize-based ordering mechanism.

**GitHub MCP equivalent.** The MCP server exposes `reprioritize_sub_issue` as one of the sub-issue tools ([github-mcp-server #196](https://github.com/github/github-mcp-server/issues/196), cited in `EXTERNAL-RESEARCH.md:352`). Tool name confirmed but I/O shape requires primary verification.

### §4.3 — Issue dependencies (Blocks / Blocked by) — GA 2025-08-21

Source: [Dependencies on issues, GitHub Changelog 2025-08-21](https://github.blog/changelog/2025-08-21-dependencies-on-issues/), cited in `EXTERNAL-RESEARCH.md:82`.

- **Cap:** 50 issues per relationship type per issue (50 "blocks", 50 "blocked by").
- **Cross-repo:** same-repository or same-organization internal repos only; external repos not supported as of GA.
- **API:** GraphQL mutations `addBlockedBy` / removal. EMU users can hit `FORBIDDEN: Unauthorized; path: addBlockedBy` for cross-enterprise links.
- **Closing-keywords distinction.** `Closes #N` / `Resolves #N` / `Fixes #N` in PR bodies are merge-time close triggers; they are NOT dependency markers. Free-text `#42` references do not create dependencies — they only cross-link.

**Use as a phase-ordering mechanism — analysis.** Block / blocked-by gives a PARTIAL order, not a total order: if phase A blocks phase B, the topological sort places A before B, but if phase A and phase C have no relationship and both are unblocked, the order between A and C is unspecified. This is exactly the limitation BD-185 P3 cites: "Blockers/dependencies give only partial order."

The pack's existing dependency model (`scripts/lib/tracker-links.sh` per BD-068 / V3.3 §5) admits `phase-N` (and other entity types) as dependency targets; phase epics can have `blocked-by` edges to other phase epics. Whether the architect chooses to surface this as the execution-order mechanism, augment it (e.g., with a tie-breaker field), or design a separate mechanism is the architect's choice.

### §4.4 — Labels — current capacity

Source: [Managing labels](https://docs.github.com/en/issues/using-labels-and-milestones-to-track-work/managing-labels); [Discussion #76832](https://github.com/orgs/community/discussions/76832) (per `EXTERNAL-RESEARCH.md:101-105`).

- **Description:** max 100 chars.
- **Labels per issue / PR:** 100.
- **Labels per repo:** No documented hard cap.
- **Color:** 6-char hex.

**Use as ordering / parts mechanism — observation only.** Labels can express:
- Parts membership: `part:1`, `part:2`, ... (1 label per phase task indicating which Part it belongs to).
- Execution order: `order:1`, `order:2`, ... (1 label per phase epic indicating sort position).
- Both at once: a phase task could carry `phase-3`, `part:2`, plus whatever else.

The pack's existing label provisioning (`scripts/lib/tracker-labels.sh`) carries `phase-N` membership labels (a regex-based namespace `^phase-[0-9]+$`); adding a `part:` or `order:` namespace would extend `tracker_labels_phase_n` (or analog) without changing the underlying mechanism. Validation of label name uniqueness vs. label name collision is a separate concern.

**Trade-off note (not a recommendation).** Labels are ergonomically searchable (`gh issue list --label part:2`) and CLI-friendly. They are NOT first-class entities — closing a phase epic with `part:1` does not affect labels on its tasks. They do NOT carry rich state (no per-label description per Part beyond the 100-char limit). The architect weighs labels against alternatives (sub-issues, custom fields, sidecar) per the design space.

### §4.5 — Milestones

Source: [Managing labels](https://docs.github.com/en/issues/using-labels-and-milestones-to-track-work/managing-labels) (per `EXTERNAL-RESEARCH.md:107-110`).

- **One milestone per issue** (single-milestone constraint).
- Optional due date.
- Percent complete computed from open vs closed issues.
- No documented hard cap on milestones per repo.

**Use as ordering mechanism — observation only.** Each milestone carries a due-date which provides an implicit chronological order (sort by due date). Milestones could express phase grouping ("Milestone: Phase 3") with the due date being the planned phase end. Limitation: 1 milestone per issue means a phase task can be in EXACTLY ONE milestone, so milestones cannot overlay (e.g., they cannot simultaneously express phase AND release grouping). The pack does NOT currently use milestones for any phase concept (no `provider_set_milestone` call in any phase-task creation path verified at HEAD).

### §4.6 — Issue Type (GA 2025) — first-class field, not a label

Source: [About the issue type field](https://docs.github.com/en/issues/planning-and-tracking-with-projects/understanding-fields/about-the-issue-type-field); [Discussion #148715](https://github.com/orgs/community/discussions/148715); per `EXTERNAL-RESEARCH.md:112-122`.

- **One type per issue** (mutually exclusive with itself; coexists with labels).
- Defined at organization level, applied at issue level.
- Not available for PRs (issues only).
- Settable via issue forms YAML (`type:` key), via REST/GraphQL, and via `gh` (`--type` flag in recent gh versions — version-pin sensitive).

**Use for parts mechanism — observation only.** Type field could carry `phase-epic` / `phase-task` / `phase-part` as types instead of (or alongside) the label-based `phase-epic` / `phase-task` provenance the pack uses today. Concrete trade-offs: type is a single-select field (good for mutual exclusivity), but version-pinning of `gh --type` flag is a portability risk (older `gh` rejects it per `EXTERNAL-RESEARCH.md:120-122`). The pack today uses labels for entry-type provenance, not the issue-type field (per `scripts/lib/tracker-labels.sh:13-15`); migrating to issue types would be a separate architectural decision.

### §4.7 — Issue Fields (NEW — public preview 2026-03-12, all-orgs 2026-05-21)

Source: [Issue fields: Structured issue metadata is in public preview, GitHub Changelog 2026-03-12](https://github.blog/changelog/2026-03-12-issue-fields-structured-issue-metadata-is-in-public-preview/); [Issue fields are now in public preview for all organizations, GitHub Changelog 2026-05-21](https://github.blog/changelog/2026-05-21-issue-fields-are-now-in-public-preview-for-all-organizations/); [Adding and managing issue fields](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/adding-and-managing-issue-fields); [Managing issue fields in your organization](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/managing-issue-fields-in-your-organization).

**This is a NEW feature surface that did NOT exist at the time of the v11 EXTERNAL-RESEARCH.md research pass (2026-04-30).** Discovered during this 2026-05-24 verification pass.

- **Status:** Public preview for ALL organizations as of 2026-05-21 (subject to change — preview status caveats apply).
- **Field types:** 4 types — `single select`, `text`, `number`, `date`.
- **Cap per organization:** 25 issue fields total.
- **Preconfigured fields (default):** `Priority`, `Effort`, `Start date`, `Target date` (pinned to issue types).
- **Capabilities:** searchable + filterable by field value; addable as columns in project views; tracked in timeline; automatable via REST + GraphQL + webhooks.
- **Org-level definition:** fields are defined at org level, applied at issue level. Issue fields and system fields together count toward projects' 50-field cap.

**Use for execution-order mechanism — observation only.** A `number` field (e.g., `Execution order`) could carry the per-phase position; sortable + filterable via the project view. The PRECONFIGURED `Priority` and `Effort` fields are number-shaped already. The architect could (a) use a preconfigured field, (b) define a new org-level number field, or (c) NOT use issue fields at all (preview status carries a "subject to change" caveat). Constraints to verify before adopting: per-issue cardinality (is each issue field 1-valued or multi-valued?); whether issue-field state is exposed via `gh` CLI yet; whether the pack's existing `provider.*` ops cover read/write of issue-field state; org-admin requirements for defining new fields (pack-managed projects may not have org-admin access). The architect should treat issue fields as a NEW option in the design space, not a default, given its preview status. **This finding closes a knowledge gap in the v11 EXTERNAL-RESEARCH.md — the architect must read these two changelog posts as primary inputs.**

### §4.8 — GitHub Projects v2 (OUT OF SCOPE for BD-185)

BD-185 entry explicitly lists "GH Projects integration" as OUT OF SCOPE (`pack-ops/BACKLOG.md:1779-1781`; v11.1 scope per `V11.1-DISCUSSION-GITHUB-PROJECTS.md` on `main`).

Noting only because primitives Projects v2 has that Issues lack are relevant cross-reference for the architect:
- Projects v2 has a per-item **position** that's user-mutable (via `updateProjectV2ItemPosition` mutation — verified via web search 2026-05-24); confirmed in [Add GraphQL mutations for ProjectV2 view management · Discussion #194509](https://github.com/orgs/community/discussions/194509) and via [GraphQL Mutations Reference](https://docs.github.com/en/graphql/reference/mutations).
- Projects v2 has per-item custom fields (`single_select`, `number`, `date`, `iteration`, `text` per `EXTERNAL-RESEARCH.md:126-128`) that can express execution-order at the item level.
- Projects v2 has up to 50,000 items per project ([Changelog 2025-02-26](https://github.blog/changelog/2025-02-26-increased-items-in-github-projects-now-in-public-preview/)).
- Projects v2 is GraphQL-only ([Using the API to manage Projects](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-api-to-manage-projects)).

**Per BD-185 out-of-scope:** the architect SHOULD NOT design BD-185's solution around Projects v2. The architect MAY note that Projects v2 provides the missing primitives but defer the integration to v11.1+.

### §4.9 — Search and filter capabilities (for ordering-by-query)

Source: [Filtering and searching issues and PRs](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/filtering-and-searching-issues-and-pull-requests); [Searching issues and pull requests](https://docs.github.com/en/search-github/searching-on-github/searching-issues-and-pull-requests); [Issues search now supports nested queries and boolean operators](https://github.blog/developer-skills/application-development/github-issues-search-now-supports-nested-queries-and-boolean-operators-heres-how-we-rebuilt-it/); per `EXTERNAL-RESEARCH.md:142-164`.

- Search qualifiers: `is:`, `state:`, `type:`, `author:`, `assignee:`, `mentions:`, `team:`, `commenter:`, `involves:`, `linked:`, `label:`, `milestone:`, `project:`, `status:`, `head:`, `base:`, `comments:`, `interactions:`, `reactions:`, `draft:`, `created:`, `updated:`, `closed:`, `merged:`, `archived:`. Exclusion via `-qualifier:value`.
- **Advanced search (GA 2025-09-04):** boolean `AND` / `OR` with parenthesized nesting.
- **Hard limit:** 1,000 results per query (REST + GraphQL). Use date-range / label slicing to walk past 1,000.

**Use for ordering mechanism — observation only.** Search results have an implicit ordering controlled by GraphQL `orderBy` / REST `sort` parameters, e.g., `sort:created-asc`, `sort:updated-desc`, `sort:reactions-+1-desc`. None of these are user-mutable per-issue execution-order. Sort-by-label-name is possible (`gh issue list --label order:1 --label order:2 ...` produces label-grouped results) but not a true sort.

### §4.10 — `gh` CLI JSON output fields

Source: [gh-issue-list manpage](https://man.archlinux.org/man/gh-issue-list.1.en); [cli/cli #5902](https://github.com/cli/cli/discussions/5902); per `EXTERNAL-RESEARCH.md:262-281`.

`gh issue list --json` field set: `assignees, author, body, closed, closedAt, closedByPullRequestsReferences, comments, createdAt, id, isPinned, labels, milestone, number, projectCards, projectItems, reactionGroups, state, stateReason, title, updatedAt, url`.

**Notable gaps:**
- `--json type` for the GA issue type field was added in late-2025 gh releases ([cli/cli #12477](https://github.com/cli/cli/issues/12477)) — version-pin sensitive.
- Sub-issue parent / children NOT exposed via `--json`. Must shell to `gh api graphql` or use the `gh-sub-issue` extension.
- Blocks / blocked-by NOT exposed via `--json`. Same workaround.
- Issue fields (§4.7) — exposure status via `--json` not verified during this pass.

**Implication for BD-185.** If the architect chooses to express ordering or Parts via a mechanism `gh issue list --json` cannot read, the agent-side read path (`scripts/lib/tracker-agent-read.sh`) must use `gh api graphql` or an extension — a portability cost.

### §4.11 — GitHub MCP server (Issues toolset)

Source: [github/github-mcp-server](https://github.com/github/github-mcp-server); per `EXTERNAL-RESEARCH.md:322-373`.

Relevant tools (Issues toolset, default-on):
- `list_issues`, `get_issue`, `create_issue`, `update_issue`, `add_issue_comment`, `get_issue_comments`, `search_issues`.
- `list_issue_types` (org-level).
- `add_sub_issue`, `list_sub_issues`, `remove_sub_issue`, `reprioritize_sub_issue` (per `github-mcp-server #196`).
- `assign_copilot_to_issue`.

Note: MCP tool surface evolves between releases ([modelcontextprotocol/servers #541](https://github.com/modelcontextprotocol/servers/issues/541), per `EXTERNAL-RESEARCH.md:374-381`); the pack today does NOT depend on MCP for any tracker operation (pack uses `gh` + `gh api graphql` exclusively per `tracker-provider-gh.sh`).

### §4.12 — Rate limits (cost of high-frequency reordering)

Source: [Rate limits for the REST API](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api); [Rate limits and query limits for the GraphQL API](https://docs.github.com/en/graphql/overview/rate-limits-and-query-limits-for-the-graphql-api); per `EXTERNAL-RESEARCH.md:200-217`.

| API | Authenticated primary | Secondary |
|---|---|---|
| REST core | 5,000 req/hr/user | ≤ 900 points/min |
| REST search | 30 req/min | (folds into core 5k/hr) |
| GraphQL | 5,000 points/hr/user | ≤ 2,000 points/min |
| Unauth | 60 req/hr per IP | (do not use for chat) |

**Use as constraint.** If the architect designs an ordering mechanism that requires per-reorder API calls (e.g., `reprioritize_sub_issue` per Part-list edit, or `updateProjectV2ItemPosition` per phase reorder), the rate budget allows ~5k operations per hour. Bulk-reorder workflows (e.g., the migration P4 case where ALL existing phases need an initial ordering written) must respect this — particularly across the 30 req/min REST-search limit if the migrator does any search-and-reorder pattern.

### §4.13 — Summary of GH-native options for BD-185 (NO recommendations)

The architect chooses among these mechanisms; this list is exhaustive at HEAD a5c7e62 + verified primary sources (2026-05-24):

**For Parts hierarchy (P1 / P2):**
1. **Sub-issues** as Parts: phase epic → Part sub-issues (depth 2) → task sub-issues (depth 3). Capacity 8 levels, 100 children per parent, 1 parent per child. Reverse migration impact: would change phase epic body grammar (no `## Tasks` section needed; tasks listed via `provider_sub_issue_list`).
2. **Labels** as Parts: `part:1`, `part:2` labels on tasks; phase epic body lists Parts as a section. Capacity 100 labels/issue. Reverse migration impact: minimal.
3. **Issue type** as Part-vs-task: define `phase-part` as a 3rd issue type. Capacity 1 type/issue. Cross-repo portability via org-level config.
4. **Issue fields** as Part identifier: a `Part` number or single-select field on each task. Capacity 25 fields/org. Preview status (subject to change).
5. **Pure flat-file (no tracker representation)**: Parts remain METHODOLOGY-only; tracker mode either fails to round-trip Parts or treats them as report-header-only metadata that doesn't survive sync. Compatible with current P1 behavior; would violate BD-185 SC2 (mid-work expansion must work in tracker mode).

**For execution ordering (P3 / P4):**
1. **Issue fields — number** (e.g., `Execution order`): per-phase mutable field. Preview status. Surfacing via `--json` not verified.
2. **Sub-issue reprioritize**: all phase epics become sub-issues of a single ROOT issue ("Project root"); execution order = sibling order under that root. Forces a root entity, but expresses total ordering. Capacity: 100 children per parent — fine for v11 typical phase count (~28-60).
3. **Projects v2 item position**: out of scope per BD-185 entry.
4. **Labels** (e.g., `order:001`, `order:002`): label-namespace ordering. Easy to read via `gh issue list --label order:001 --label order:002 ...`; not a true sort.
5. **Block/blocked-by chain**: add ordering-by-dependency from phase to phase. Produces total order only if every adjacent pair has a link. Cap 50 blocks/issue limits chains.
6. **Sidecar JSON** (e.g., `.pack-tracker/execution-order.json`): pack-managed local file, synced to tracker via a dedicated reverse-emit operation. Custom integration cost. Already-pattern at `scripts/lib/tracker-sidecar.sh` per V3.3 §4.3.
7. **Issue numbers themselves (no mechanism)**: P3 explicitly excludes this — "Issue numbers reflect creation order" cannot be user-mutated. Listed for completeness.


---

## §5 — Form-family + label-namespace inventory

### §5.1 — Form-family (work-item.yml) — the intake schema

Source: `.github/ISSUE_TEMPLATE/work-item.yml` (pack-root) + `project-template/.github/ISSUE_TEMPLATE/work-item.yml` (client-side, 179 lines).

**Top-level metadata** (`work-item.yml:1-7`):
- `name`: "Project work item (TD / phase-epic / phase-task)"
- `description`: "Project technical-debt item (TD-NNN), phase epic skeleton, or phase task skeleton. (Pack development BDs are filed against the pack repo, not here.)"
- `title`: `"TD-NNN: <short title>"` (default; chat triage renames at intake)
- `labels` (auto-applied): `work-item`, `needs-triage`, `template:work-item-v11.0`

**Form fields** (`work-item.yml:19-179`):

| Field id | Type | Required | Description | Part-related? |
|---|---|---|---|---|
| `wi-type` | dropdown | yes | bd / td / phase-epic-skeleton / phase-task-skeleton | NO (no phase-part-skeleton option) |
| `wi-kind` | dropdown | (BD/TD only) | feat / fix / refactor / docs / chore / infra | NO |
| `wi-status` | dropdown | yes | Open / Unblocked / Pending / In Progress / Resolved / Done / Deferred / Cancelled / Deprecated | NO (no part-specific status) |
| `wi-td-scope` | dropdown | (TD only) | phase-N / dependency / feature / perf / version | NO |
| `wi-td-severity` | dropdown | (TD only) | critical / functional / polish | NO |
| `wi-phase-number` | input | (phase-* only) | "Use 'N'" | NO Part number |
| `wi-task-title` | input | (phase-task-skeleton only) | M-resolution rule at line 99: "next available task number under phase N" | NO Part-aware M-resolution |
| `wi-blockers` | textarea | optional | "Blockers may name 'phase-N' (entire phase) or 'phase-N.M' (specific task)" | NO Part-id form admitted |
| `wi-unblocks` | textarea | optional | inverse of Blockers | NO |
| `wi-file-symbol` | input | optional | Affected path or symbol | n/a |
| `wi-description` | textarea | optional | BD/TD/phase-epic-skeleton | n/a |
| `wi-context` | textarea | optional | n/a | n/a |
| `wi-resolution` | textarea | optional | n/a | n/a |
| `wi-problem-goal-success` | textarea | (phase-task-skeleton only) | "Body section per METHODOLOGY § Part 4" | n/a |
| `wi-files` | textarea | (phase-task-skeleton only) | n/a | n/a |
| `wi-definition-of-done` | textarea | (phase-task-skeleton only) | n/a | n/a |
| `wi-dependencies` | textarea | (phase-task-skeleton only) | "Accepts `phase-N`, `phase-N.M`, `TD-NNN`, `BD-NNN`" | NO Part-id form admitted |
| (footer `markdown` block) | markdown | n/a | `<!-- pack-id: PENDING --> <!-- template_version: work-item-v11.0 --> <!-- pack-version: v11 -->` | NO Part-aware body marker |

**Architect's BD-185 surface for the form:**
- Add `wi-part-number` input + a `phase-part-skeleton` option to `wi-type` dropdown — OR — leave the form alone and create Parts programmatically (matching how phase-epic and phase-task are created day-to-day — `templates-archive/v11.0/phase-task-v11.0/SCHEMA.md:5-8`).
- Extend `wi-blockers` / `wi-unblocks` / `wi-dependencies` descriptions to admit a Part-id form if Parts are tracker entities AND can be dependency targets.

### §5.2 — Label namespaces (tracker-labels.sh)

Source: `scripts/lib/tracker-labels.sh:1-300` (verified at HEAD).

**Existing namespaces** (lines 71-115 enumerate the canonical label set):

1. **Entry-type provenance** (`tracker-labels.sh:11-15`): `bd-entry`, `td-entry`, `phase-epic`, `phase-task`, `work-item`, `inbound`, `external`, `pack-feedback`, `needs-triage`.
2. **Scope** (TD only — line 23): `scope:phase-N` (per-phase), `scope:dependency`, `scope:feature`, `scope:perf`, `scope:version`.
3. **Severity** (TD KNOWN GAP variant): `severity:critical`, `severity:functional`, `severity:polish`.
4. **Status** (lifecycle, line 24): `status:open`, `status:resolved`, `status:deferred`, `status:cancelled`, `status:deprecated`, `status:pending`, `status:in-progress`, `status:done`, `status:unblocked`. Plus parameterized: `status:merged-into:phase-N`, `status:superseded-by`.
5. **Template version** (lines 28-29): `template:bd-v11.0`, `template:td-v11.0`, `template:phase-epic-v11.0`, `template:phase-task-v11.0`, `template:inbound-v11.0`, `template:work-item-v11.0`.
6. **Promotion forward-pointer** (line 38, validator at line 241): `promoted-to:phase-N` (Path 1), `promoted-to:phase-N.M` (Path 2). Validator regex `^phase-[0-9]+(\.[0-9]+)?$` — would need extension if Parts become a promotion target.
7. **Derived-from reverse-pointer** (line 35): `derived-from:TD-NNN`.
8. **Phase membership** (per V3.3 §3.5): `phase-N` (e.g., `phase-3`). Applied to phase epics, phase tasks, and TD entries with scope `phase-N`.

**Adding a Part namespace.** A `part:M` label is a candidate per BD-185 entry File/Symbol (`pack-ops/BACKLOG.md:1750`). Open architect questions if pursued:
- Format: `part:M` (e.g., `part:1`) — collides with no current namespace. Format `phase-N.part:M` is also possible (e.g., `phase-3.part:1`) — more verbose but disambiguates across phases.
- Validation: where (`tracker-labels.sh` lib?) and what regex.
- Application: phase task only, or also phase epic? (Phase epic with `part:1` would suggest the phase HAS Parts; without it would mean single-Part phase.)
- Forward-migration: when migrator runs against a flat-file with Multi-part phases, does it create label-set per task? (CI cost: 1 extra label-set call per task.)
- Removal semantics: if a phase merges two Parts back into one, do labels get stripped?

**Adding an Order namespace.** An `order:NNN` label is a candidate ordering mechanism (§4.13 option 4). Open architect questions:
- Granularity: 1 label per phase epic only (phase-level order), or also per phase task (task-level order — already covered by `task_order` sidecar field)?
- Padding: `order:001` vs `order:1` — padding controls lexical sort. With `LC_ALL=C sort`, `order:10` < `order:2` if unpadded.
- Mutation: pack must update labels on reorder; lots of write-traffic on bulk reorders.

### §5.3 — Body markers (the trinity per entry)

Source: `maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md:23-29`; phase-epic-v11.0 SCHEMA.md:22-28.

Phase epic body trio:
```
<!-- pack-id: phase-N -->
<!-- template_version: phase-epic-v11.0 -->
<!-- pack-version: v11 -->
```

Phase task body trio:
```
<!-- pack-id: phase-N.M -->
<!-- template_version: phase-task-v11.0 -->
<!-- pack-version: v11 -->
```

**Architect's BD-185 surface for body markers:**
- If Parts become tracker entities, they need their own pack-id + template_version: e.g., `<!-- pack-id: phase-N.Part-M -->`, `<!-- template_version: phase-part-v11.1 -->`, `<!-- pack-version: v11 -->`.
- If Parts get sub-issue parentage (sub-issue of phase epic), the body marker is the only round-trip carrier — round-trip parsers (`tracker-migrate-reverse.sh:511`) regex `<!--\s*pack-id:\s*([A-Z]+-\d+|phase-\d+(?:\.\d+)?)\s*-->` would need to admit the new shape.
- If Parts remain METHODOLOGY-only (no tracker representation), no body marker change.

---

## §6 — METHODOLOGY.md rules touching phase shape and execution ordering

The architect must respect (or explicitly amend) these rules in their design. Each rule is named by its section + line range.

### §6.1 — Phase Structure (§ Part 4, lines 366-441)

| Rule | Location | Architect impact |
|---|---|---|
| Phase format template | `METHODOLOGY.md:370-405` | The H2/H3/H4 grammar is what the per-entry decompose helper anchors on. Any addition (e.g., `### Part 1` H3) must be designed against this grammar. |
| Execution note (optional) | `METHODOLOGY.md:375` | `> **Execution note**: (optional) deliberate deferral or ordering constraint.` This is the FLAT-FILE ordering mechanism per P3. Tracker mode must round-trip it (or replace it with a tracker-native mechanism). |
| Phase numbering rules | `METHODOLOGY.md:407-412` | "Never renumber phases", "reorder via execution notes, not renumbering", "Insert new phases at end of plan", "Fractional phases (2.1, 2.2) only during early architecture work". These are the immutability invariants for P2/P4. |
| Multi-part phases | `METHODOLOGY.md:414-441` | The Parts mechanism today. Part vs. Pass terminology (line 417-418); H3 sub-section grammar (line 422-428); report-header rule (line 430-437); single-part-no-suffix rule (line 439-441). |
| Multi-part phase report headers | `METHODOLOGY.md:967-974` (Part 5 restatement) | Restates the report-header rule with concrete example. |

### §6.2 — Planner triggers that create Parts

| Rule | Location | Architect impact |
|---|---|---|
| Planner trigger rule (Part 3) | `METHODOLOGY.md:310-323` | The 3 triggers (5+ tasks; non-linear deps; second-failure-on-task-definition) cause Parts to be introduced. The planner is the AGENT that produces Parts; no programmatic verb today. |
| Trigger P-A / P-B / P-C (mid-phase) | `METHODOLOGY.md:660-680` | Mid-phase planner triggers (architecture; replan; task-ordering). Trigger P-C ("Task-ordering revision discovered mid-phase") is TASK ordering inside a phase, NOT phase EXECUTION ordering. Distinct from BD-185 P3. |

### §6.3 — STATUS.md update cadence (Part 2 + Part 9)

| Rule | Location | Architect impact |
|---|---|---|
| STATUS.md table-row purpose | `METHODOLOGY.md:190` | "Current phase, phase table, next actions, key metrics" |
| STATUS.md update timing | `METHODOLOGY.md:202` | "after every phase — stale status is worse than no status" |
| File-write authority | `METHODOLOGY.md:1556-1580` | STATUS.md is PM-chat-write-after-phase. BD-185 SC5 LOCKS this role (STATUS.md does NOT become ordering SSOT). |

### §6.4 — Workflow per-phase execution

| Rule | Location | Architect impact |
|---|---|---|
| Workflow 2 (per-phase execution) | `METHODOLOGY.md:474-509` | The standard coder → reviewer cycle. Operates one phase at a time. With Parts, the cycle runs per Part (per the Multi-part rule). |
| Workflow 3 (per-phase with external API research) | `METHODOLOGY.md:511+` | Adds a docs-researcher pass. Operates one phase (or one Part) at a time. |

---

## §7 — validate-pack.py check inventory

These CI checks intersect BD-185 work. Each check enforces an invariant; the architect's design must extend (or replace) each check that touches Parts / ordering / hierarchy / form schema.

| Check # | Function | What it enforces | BD-185 impact |
|---|---|---|---|
| Check 32 | `check_mirror_in_sync` (line 3065) | Per-entry mirror in-sync with tree; stream regex `^phase-\d+\.md$` | If Parts become per-entry files (`phase-N.Part-M.md`?), the regex extends. If Parts are inline H3 in phase file, no extension needed. |
| Check 33 | `check_toc_in_sync` (line 3273) | `_toc.md` matches generator output; `project-implementation-plan` grouped by phase number | Same as 32. |
| Check 34 | `check_cross_reference_integrity` (line 3472) | `BD-NNN`, `TD-NNN`, `vN.M`, `phase-N[.M]` references valid (line 136) | If Parts get a new id shape, the cross-ref regex (line 3424) extends. |
| Check 35 | `check_tracker_phase_task_invariants` (line 3613) | `scripts/lib/tracker-phase-task.sh` exists; Path 3 (`folded-into:`) forbidden | If Parts ship with new sibling-lib (`tracker-phase-part.sh`?), a parallel check applies. |
| (existing series) | `check_issue_template_forms` (line 1067) | `work-item.yml` `wi-type` has exactly 4 options | If Parts get a 5th option (`phase-part-skeleton`), set `expected_wi_type_options` (line 1091) extends. |
| (existing series) | `check_template_archive_v11` (line 1171) | Archive has 5 entry-type subdirs | If Parts get a 6th archived schema, the v11.1 cut (not v11.0) gains it. |
| (existing series) | `STREAMS` constants (in `validate-pack.py` near line 3115) | Pack-side `pack-backlog` + `pack-changelog` only; project-side per-entry trees only | If pack-side ever gains an implementation-plan stream (currently the pack has no IMPLEMENTATION_PLAN per V3 §28.1), the STREAMS table grows. NOT a BD-185 concern unless the architect extends to pack-side. |
| Check 40 | `check_bare_pack_ops_refs` (line 4953) | Pack-ops/ bare-cross-reference scanner | Listed for completeness; any new doc-cite produced by BD-185 must pass this. |
| Check 43 | `check_project_side_bare_internal_refs` (line 5210) | Project-side bare cross-reference scanner | Same as 40 on project surface. |
| Check 41 | `check_client_installed_files` (line 5668) | `_CLIENT_INSTALLED_FILES` self-doc list | If a new file ships to client (e.g., `project-template/.github/ISSUE_TEMPLATE/work-item.yml` schema extension), the manifest catches it. |


---

## §8 — TrackerProvider sync surface (BD-060)

Every op in the BD-060 18-op surface where Parts metadata OR ordering metadata would need to round-trip. Listed in dispatch order from `tracker-provider.sh:125-142`.

| Op | Path | Forward direction (flat → tracker) — what data crosses | Reverse direction (tracker → flat) — what data crosses | Part-related metadata that would need to flow | Ordering metadata that would need to flow |
|---|---|---|---|---|---|
| `provider_list` | `tracker-provider.sh:125` | n/a (read-only) | Returns issues; pack-id + template_version + labels parsed by caller | Part body marker (if Parts get one) | Order field value (if Parts get one) |
| `provider_get` | line 126 | n/a (read-only) | Single-issue read | Same as list | Same as list |
| `provider_search` | line 127 | n/a (read-only) | Query result | Search by label (`part:M`) or by type/field if those become ordering carriers | Search by `order:M` label or by issue-field number |
| `provider_create` | line 128 | Issue body (with pack-id trio) + labels + assignees + milestone + project | Returns new issue id | Body marker `<!-- pack-id: phase-N.Part-M -->` if Parts get pack-ids | n/a directly (creation doesn't order; reorder is separate) |
| `provider_update` | line 129 | Same as create (mutation) | n/a | If Part membership of a task changes (mid-work re-shuffling), update writes new label | Issue-field number update IF that's the mechanism |
| `provider_close` | line 130 | Closing state + state_reason | n/a | If a Part's last task closes, does Part epic auto-close? METHODOLOGY says no for sub-issues (§4.1) | n/a |
| `provider_reopen` | line 131 | Reopen | n/a | If a Part epic reopens, do its tasks reopen? No (per §4.1) | n/a |
| `provider_comment` | line 132 | Comment body | Comments fetched | Comments can carry execution-note text in tracker mode if execution-notes are persisted as a comment (one option) | Same |
| `provider_set_labels` | line 133 | Label set (full replacement OR add/remove) | n/a | `part:M` label mutations | `order:M` label mutations |
| `provider_set_assignee` | line 134 | Assignee | n/a | n/a | n/a |
| `provider_set_milestone` | line 135 | Milestone id | n/a | Each Part could be its own milestone (1 per Part); each phase could be its own milestone (1 per phase); each release could be its own milestone — capacity 1 per issue is a constraint | Milestone due date implicit order |
| `provider_link` | line 136 | Cross-entity dependency edge (`kind=blocked-by`, source, target) | n/a | If Parts get pack-ids, their cross-entity dependency form admits `phase-N.Part-M` as source/target | Block/blocked-by chain expresses partial order across Parts |
| `provider_unlink` | line 137 | Remove edge | n/a | Same as link | Same |
| `provider_sub_issue_create` | line 138 | Parent id + child id | n/a | **The key Parts-as-sub-issues op** — if Parts become sub-issue parents, this op creates the parent → Part → task hierarchy | Sub-issue ordering managed by reprioritize_sub_issue (NOT exposed via this op family today) |
| `provider_sub_issue_list` | line 139 | n/a | Returns child ids in sub-issue priority order | Returns Parts under a phase epic if Parts-as-sub-issues | Returns priority order of children — the only built-in ordering today |
| `provider_sub_issue_unlink` | line 140 | Parent + child | n/a | Re-parenting a task to a different Part | n/a |
| `provider_capabilities` | line 141 | n/a | Returns capability flags JSON (e.g., `hierarchy.supported = true`) | If new Parts-related capabilities are added (e.g., `sibling_ordering.supported`), they go here | Same |
| `provider_raw` | line 142 | Arbitrary backend-native call | n/a | If the architect uses an op not in the 18-op surface (e.g., `gh api graphql -F ...reprioritizeSubIssue`), it goes via raw — but raw is a capability-cliff (other backends won't have the same op) | Same |

**Missing from the 18-op surface (relevant to BD-185):**
- `provider_sub_issue_reprioritize` — there is NO such op in the current 18-op surface (cf. `tracker-provider.sh:138-140` exposes only `_create`, `_list`, `_unlink`). The GH backend supports it via the REST `reprioritize_sub_issue` endpoint (§4.2) and via the MCP `reprioritize_sub_issue` tool, but the pack does not expose the operation through the abstraction. If BD-185 adopts sub-issue reordering, the 18-op surface grows to 19 ops + raw. Architect's call whether to add it.
- `provider_set_field` (or analog) — no support for setting an issue field today. If BD-185 adopts the issue-fields ordering mechanism (§4.7), a new op may be needed (or use `provider_raw`).
- `provider_set_type` (or analog) — no support for setting issue type today. If BD-185 adopts the issue-type mechanism for Parts (§4.6), a new op may be needed.

### §8.1 — id-map.json (the forward-side state)

Source: `scripts/lib/tracker-migrate-forward.sh:200-272` (BD-106 phase-task id-map handling).

Current shape (additive per BD-106 / V3.2 §4.1):
```
{
  "BD-NNN": {"id": <gh-int>, "url": <gh-url>},
  "TD-NNN": {"id": <gh-int>, "url": <gh-url>},
  "phase-N": {"id": <gh-int>, "url": <gh-url>, "task_order": ["1", "2", "3"]},
  "phase-N.M": {"id": <gh-int>, "url": <gh-url>}
}
```

**Surface for BD-185:**
- Per-phase `task_order` already exists (line 245). If Parts are introduced, the field could extend to `part_order` (list of Part numbers in execution order) OR `tasks` could become a nested structure under Parts.
- Per-Part entry: if Parts get pack-ids (e.g., `phase-N.Part-M`), they need an entry of their own with `id` + `url` + child `task_order`.
- Phase-level execution order: if `phase-N` entries gain a position field (e.g., `execution_order: 3` meaning "this phase is the 3rd to execute"), the field lands here.
- Backwards compatibility: BD-106 left v10 entries untouched (additive intent at lines 197, 207-209). Any new fields BD-185 adds should be additive too — old id-map state from v11.0 must still load.

### §8.2 — Sidecar (.pack-tracker/sidecar.yaml) — tracker-only state

Source: `scripts/lib/tracker-sidecar.sh:282-360`; ARCHITECTURE-V3.3-DELTA.md §4.3.

Current shape excerpt (per `tracker-sidecar.sh:288-303`):
```yaml
phase_tasks:
  phase-N:
    task_order: [N.1, N.2, ...]
    tasks:
      phase-N.M:
        problem: <body>
        parent_phase: phase-N
        dependencies:
          - kind: blocked-by
            target: phase-X.Y
            annotation: ...
        template_version: phase-task-v11.0
```

**Surface for BD-185:**
- A `phase_parts` block could mirror `phase_tasks`: per-Part container with member tasks; per-Part state taxonomy.
- A `phase_execution_order` top-level block could carry phase-level execution order: a list of phase IDs in execution order, or a per-phase field.
- Sidecar contents are tracker-only per V3.3 §4.3 — they do NOT round-trip to flat-file. The architect must distinguish: data that MUST round-trip (cross-reference: §9 immutability invariants) vs data that can live tracker-only.

### §8.3 — Sub-issue parentage routing (V3.3 §5.3 line 263)

Source: `scripts/lib/tracker-migrate-reverse.sh:467-477`.

Current rule (verbatim from `tracker-migrate-reverse.sh:467-473`):
> Sub-issue parent → phase epic only. V3.3 §2 D-21: phase tasks (phase-N.M) are first-class L2 entities; they are NOT sub-issue parents. Restrict to phase-N (no `.M` component) to avoid misclassifying a phase-task parent as a phase-epic blocker.

Code:
```python
if pack_parent and re.match(r'^phase-\d+$', pack_parent):
    ...
```

**Surface for BD-185:**
- If Parts become sub-issue children of phase epic (Parts AT L2), tasks become sub-issue children of Parts (tasks AT L3). The "phase-task may not be a sub-issue parent" rule would invert: Parts CAN be sub-issue parents.
- The regex `^phase-\d+$` would need to extend to admit Part identifiers as valid sub-issue parents.
- Phase task SCHEMA.md (line 104-107) currently states: "Phase tasks may not be parented to BD/TD entries or to other phase tasks — a phase task's parent is exactly one phase epic." If Parts ship as sub-issue parents, this rule changes to "phase task's parent is exactly one phase epic OR one phase part."


---

## §9 — Immutability invariants the architect must preserve

These invariants are stated in current v11 design and locked by BD-185 SC3 (verbatim: "Phase numbers and task IDs (N.M) are never renumbered. Tracker entity IDs (GH Issue numbers) are inherently immutable."). The architect's design must NOT violate any. If a design requires violating an invariant, it is OUT OF SCOPE for BD-185 and surfaces to user discussion.

| INV # | Invariant | Source (verified) |
|---|---|---|
| INV-1 | Phase numbers are immutable. Never renumber phases. Reorder via execution notes, not renumbering. Insert new phases at the end. | `supporting-docs/METHODOLOGY.md:407-412` (Phase numbering rules); `pack-ops/BACKLOG.md:1772` (BD-185 SC3) |
| INV-2 | Task identifiers `phase-N.M` are immutable. M is "the task's birth-order ordinal, not a positional index". Stable across renames and reorders. | `maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md:14-19`; `ARCHITECTURE-V3.3-DELTA.md:72-73`; `pack-ops/BACKLOG.md:1772` (BD-185 SC3) |
| INV-3 | Tracker entity IDs (GH Issue numbers) are inherently immutable. | `pack-ops/BACKLOG.md:1772` (BD-185 SC3) |
| INV-4 | Phase task body-marker trio is required: `<!-- pack-id: phase-N.M -->`, `<!-- template_version: phase-task-v11.0 -->`, `<!-- pack-version: v11 -->`. Validated by parser/emitter at `tracker-migrate-reverse.sh:511`. | `templates-archive/v11.0/phase-task-v11.0/SCHEMA.md:23-29` |
| INV-5 | Phase epic body-marker trio is required: `<!-- pack-id: phase-N -->`, `<!-- template_version: phase-epic-v11.0 -->`, `<!-- pack-version: v11 -->`. | `templates-archive/v11.0/phase-epic-v11.0/SCHEMA.md:22-28` |
| INV-6 | Path 3 (TD `--fold-into=phase-N.M`) is FORBIDDEN. No `(from TD-NNN)` body marker recognized. No `folded-into:` label. | `ARCHITECTURE-V3.3-DELTA.md:26-27` (D-22 V3.3); `scripts/lib/tracker-labels.sh` (per Check 35 lint); `validate-pack.py:3613` Check 35 |
| INV-7 | `wi-type` dropdown has EXACTLY 4 options (bd / td / phase-epic-skeleton / phase-task-skeleton). Verified by CI Check `check_issue_template_forms`. | `validate-pack.py:1091`; `templates-archive/v11.0/INDEX.md:8-14` (the 5 entry types at v11.0 — note: 4 in form, 5 in archive includes inbound) |
| INV-8 | Form-family pattern (BD-068): 4-option soft cap on dropdowns per V2 §17 R11. Adding a 5th option (e.g., phase-part-skeleton) trips the soft cap and requires architect's explicit defense. | `ARCHITECTURE-V3.3-DELTA.md:28-29`; `templates-archive/v11.0/forms/work-item.yml` |
| INV-9 | STATUS.md remains a DASHBOARD — does NOT become ordering SSOT. | `pack-ops/BACKLOG.md:1774` (BD-185 SC5) |

**Additional invariants from BD-185 SC1–SC8** (`pack-ops/BACKLOG.md:1769-1778`):
- SC1: At-creation phase splits produce multiple phases (each new immutable number) — invariant: split-at-creation is just creating N phases instead of 1, with new numbers. No mid-state.
- SC2: Mid-work splits expand a phase into Parts (preserve N + preserve all N.M task IDs).
- SC4: Execution ordering does NOT depend on flat-file artifact in tracker mode AND does NOT use GH Projects as ordering substitute.
- SC6: Tracker form-family supports parts + ordering with the SMALLEST possible template_version delta consistent with BD-068 form-family rules.
- SC7: Bi-directional sync preserves part membership + execution order across forward and reverse.
- SC8: v10→v11 migrator and v11.0 flat→tracker migrator pass pre-existing whole-number phases through unchanged and initialize the ordering mechanism from current implementation order without manual intervention.

---

## §10 — Migration-step inventory (v10→v11 + v11.0 flat→tracker)

### §10.1 — v10 → v11 migrator (BD-119 framework via `scripts/migrate-v10-to-v11.sh`)

Per `MIGRATION-v10-to-v11.md`:
- Two phases (migrator-phase): **Phase A** = local file changes (rename, relocation, install, capability-token translation, decompose); **Phase B** = optional tracker integration. Per `scripts/lib/migrate-v10-to-v11/checkpoint.sh:4-5`.
- Phase A operations in `scripts/lib/migrate-v10-to-v11/`:
  1. (existing pre-BD-167 operations: rename, relocate, install, token-translate)
  2. `_v10_to_v11_decompose_streams` — the 6th and last in-sequence step (`MIGRATION-v10-to-v11.md:292-297`); reads v11-shape monolithic files and emits per-entry tree + regenerated mirror.

**P4 surface for BD-185:**
- The v10 → v11 migrator's decompose step reads each v11-shape monolithic IMPLEMENTATION-PLAN.md. v10 OT-shape has whole-number phases only (per `RESEARCH-PER-ENTRY-SPLIT.md` §3 lines 348-401; OT live count "60 phases" cited in `ARCHITECTURE-V3.md:1929`). The decompose helper produces `phase-N.md` per phase.
- For BD-185: the decompose helper would need to handle Multi-part phases if they appear at v10→v11 time. Today they don't (Multi-part is a planner-introduced concept that arises mid-development; v10 OT-shape doesn't have Multi-part phases by design). But the future case where a v10 → v11 migration encounters a phase with Multi-part inline H3 sub-sections needs a decision: does decompose preserve the H3s as-is inside `phase-N.md`, or hoist them to per-Part files? The current decompose anchors on H2 only (`decompose.sh:131-137`), so Multi-part inline H3s are preserved as inline content.
- For execution-order initialization: the v10 → v11 migrator does NOT currently surface any execution-order field. If BD-185 introduces one, the migrator's Phase A would gain a new operation (or the decompose helper itself) to initialize the order from "current implementation order" — meaning the order phases appear in IMPLEMENTATION-PLAN.md, which equals phase-number ascending order in OT's case.

### §10.2 — v11.0 flat-file → tracker migrator (`pack tracker init` / `tracker-migrate-forward.sh`)

Per `scripts/lib/tracker-migrate-forward.sh:18-37`:
- Forward steps include: parse BACKLOG → parse IMPLEMENTATION_PLAN phases → create phase epic per phase (step 5) → sub-issue link TD → phase (step 6) → step 7 (Blockers: phase-N.M / BD-NNN / TD-NNN) → step 7b (phase-task Dependencies bullets) → step 8 (checkpoint).
- Per-phase `task_order` written via `tmf_mapping_set_phase_task_order` (line 245).
- Phase-task creation is implicit in step 5 + BD-106 (`tracker-migrate-forward.sh:223-239`).

**P4 surface for BD-185:**
- v11.0 → tracker forward migration would gain Part-recognition + Part-creation (if Parts are tracker entities). The decision interacts with sub-issue ordering: if Parts become sub-issue parents of phase tasks, the migrator must call `provider_sub_issue_create` per Part (cost: 1 API call per Part per phase).
- Execution-order initialization from "current implementation order": equivalent to phase-number-ascending. The migrator could populate the chosen ordering mechanism (issue field, label, or sidecar) with positions 1..N for phase-1, phase-2, ..., phase-N.

### §10.3 — Reverse migration (`tracker-migrate-reverse.sh`)

Per `scripts/lib/tracker-migrate-reverse.sh:78-128, 467-516, 683-708, 712-741, 905-925`:
- Reads tracker phase epics + phase tasks → reconstructs IMPLEMENTATION_PLAN.md (sorted by phase_number ascending — line 697) and STATUS.md (same sort — line 733).
- Phase task ordering preserved via `task_order` sidecar (lines 117-122; with fallback to numeric scan at lines 124-128).

**P4 surface for BD-185:**
- Reverse must emit Parts inline (if METHODOLOGY's H3 grammar stays) and emit phases in execution order (NOT phase_number ascending) if BD-185 lands a phase-level execution-order mechanism.
- The emission order is currently sorted-by-int-of-phase_number; BD-185 would change this to sorted-by-execution-order.

### §10.4 — Init-project script

`scripts/init-project.sh:1009` declares 5 streams to init-empty. The implementation-plan stream is declared as `project-implementation-plan|docs/project/IMPLEMENTATION-PLAN.md|docs/project/implementation-plan`. If a new Part stream is added, the init script must declare it too.

### §10.5 — `pack td promote` extension surface

Source: `scripts/pack-td.sh:9-103`; `scripts/lib/tracker-promote.sh`.

Current verbs:
- `pack td promote --to=phase-N <td-id>` (Path 1 — new phase epic).
- `pack td promote --to=phase-N.M <td-id>` (Path 2 — new phase task under phase N).

**BD-185 surface:**
- If Parts become tracker entities, a third promotion target may arise: `pack td promote --to=phase-N.Part-M` — but BD-185 entry does NOT enumerate this as a goal. Architect's call.
- The `--to` argument grammar (line 22: "The `--to` argument's grammar disambiguates Path 1 (`phase-N`) from Path 2 (`phase-N.M`).") would extend to admit a Part shape if added.

---

## §11 — Interactions with in-flight per-entry artifacts

The per-entry split work (BD-164 + ADDENDUM #1 + ADDENDUM #2) shipped at HEAD a5c7e62 — `scripts/lib/per-entry/` is live. BD-185 work builds on top.

### §11.1 — Per-entry decomposition decision: tasks INLINE (no per-task files)

Source: `maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-SPLIT-ADDENDUM.md` §2; `scripts/lib/per-entry/_lib.sh:94-100` confirms.

Project-side implementation-plan is decomposed ONE FILE PER PHASE. Tasks live INLINE in the phase file. There are NO `phase-N.M.md` per-task files (per Addendum #1 §6.4 BD-167 spec override of sidecar §3.4 — `_lib.sh:95-97` carries the in-code comment).

**BD-185 impact:**
- If Parts are introduced and the architect chooses to give them per-entry files (e.g., `phase-N.Part-M.md`), this REVERSES the "tasks inline" decision for Part-aware projects. The architect should consider why the original tasks-inline decision was made and whether the same arguments apply to Parts. Original rationale (`ARCHITECTURE-PER-ENTRY-SPLIT-ADDENDUM.md:188-225`): discoverability, brittleness, flat-files-not-tracker, identifier-scheme-preserved, simple-rule.
- If Parts remain inline (sub-sections within `phase-N.md`), the architect must ensure the decompose helper handles them (today it captures everything between H2 boundaries as one entry — Parts as H3 fall within this, so no change needed at decompose level).

### §11.2 — Mirror generator (ordering)

Source: `scripts/lib/per-entry/mirror-generate.sh` + `_lib.sh:393-401` (`pe_sort_entries`).

Per-entry files are concatenated in `LC_ALL=C sort` order (lexical). For `phase-N.md` filenames, this is NOT integer-order-preserving — `phase-10.md` sorts before `phase-2.md`. This was true before BD-185 and remains true at HEAD a5c7e62.

**BD-185 impact:**
- Current behavior: mirror file emits phases in lexical order, which differs from execution order (and differs from integer order).
- If BD-185 introduces an execution-order mechanism, the mirror generator's sort order is a critical surface. Options:
  - Keep lexical sort (mirror displays phases NOT in execution order — confusing).
  - Change to integer sort by phase_number (integer order = creation order in OT shape; mostly matches execution order for greenfield projects).
  - Change to execution order (sort by the new mechanism if present; fallback to integer order).
- The architect must decide. Touch point: `_lib.sh:393-401` + caller in `mirror-generate.sh`.

### §11.3 — `_intro.md` and `_rules.md` (the per-stream contract)

Source: `project-template/docs/project/implementation-plan/_rules.md` + `_intro.md`.

`_rules.md` declares filename regex `^phase-\d+\.md$` (line 14) and entry contract (lines 18-24). It does NOT declare:
- Whether phases have Parts (entry contract names `### Tasks` and `#### N.M`, not Parts).
- Whether the file has any execution-order anchor.

**BD-185 impact:**
- The `_rules.md` for implementation-plan stream must extend to declare Parts (if they become part of the entry contract) and/or any execution-order anchor (if one is added to the phase file).
- The `_intro.md` user guidance must update to explain Parts ("Multi-part phases — when to split, what the file looks like, how to mark Part state").

### §11.4 — Per-entry source for STATUS.md

NOT a stream today. STATUS.md is a single file authored by PM Chat (per `METHODOLOGY.md:1556-1580`). No decompose, no per-entry tree, no `_rules.md`. BD-185 SC5 locks this — STATUS.md remains its current form.

### §11.5 — Per-entry source for grouping (BD-186 — IF v11.1+ groupings ships)

Source: `maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md` (BD-186 Resolved 2026-05-23).

C1 constraint: "Only phases can be members of a grouping. Phase parts (`phase-N.Part-M` per BD-185), tasks (`phase-N.M`), and backlog entries (TD-NNN, BD-NNN) are NEVER members."

**BD-185 impact:**
- BD-186 EXCLUDES Parts from grouping membership. This is a forward-compatibility commitment: BD-185 architects MUST NOT design Parts as grouping members.
- Per `TOUCH-POINT-INVENTORY-GROUPINGS-V2.md:643-649` (BD-185 interaction notes), the grouping architect deferred to BD-185 to resolve whether grouping member-phases ever reference `phase-N.M` or `phase-N.Part-M` shapes. With C1 now resolved (no Parts in grouping membership), the BD-185 architect is unconstrained by groupings on this dimension.
- BD-185 SC3 (no renumbering) is independently load-bearing for groupings: if BD-185 renumbered phases, all grouping member-phase lists would invalidate. BD-185 architect MUST preserve INV-1.

### §11.6 — In-flight architecture artifacts overlapping with BD-185 scope

| Artifact | Path | Overlap with BD-185 |
|---|---|---|
| ARCHITECTURE-V3.3-DELTA.md | `maintenance-docs/v11-research/ARCHITECTURE-V3.3-DELTA.md` | Defines `phase-N.M` identifier scheme (§6.4), state machine (§6.3), parser/emitter (§4.1, §4.2), task_order (§4.3). All of these are CARRIED FORWARD; BD-185 ADDS Parts + execution-order on top — does not redefine. |
| ARCHITECTURE-PER-ENTRY-SPLIT-ADDENDUM.md | `maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-SPLIT-ADDENDUM.md` | §2 reverses parent's per-task-file decision to tasks-inline. BD-185 design must not contradict this (or must explicitly amend it). |
| ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md | `maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` | Defines the BD-164/167 integration with migrate-v10-to-v11. BD-185 changes to migrator must compose with this. |
| ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2.md | same dir | Line-1 HTML-comment back-pointer rule. BD-185 should not change this. |
| ARCHITECTURE-BD-119.md | `maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md` | Migrator framework contract. New migrator operations BD-185 introduces must follow the contract. |
| EXECUTION-PLAN-V11.0.md | `maintenance-docs/archive/v11/EXECUTION-PLAN-V11.0.md` | Batch sequencing. BD-185 lands at Batch 19d per `pack-ops/BACKLOG.md:1789`. |
| TOUCH-POINT-INVENTORY-PER-ENTRY.md | `maintenance-docs/archive/v11/TOUCH-POINT-INVENTORY-PER-ENTRY.md` | Style mirror for THIS inventory. |
| TOUCH-POINT-INVENTORY-GROUPINGS-V2.md | `maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-GROUPINGS-V2.md` | Style mirror; §6.M + §8.4 cite BD-185 as a constraint surface for the v11.1+ groupings work. |
| REQUIREMENTS-GROUPINGS-V11.md | `maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md` | C1 commits to "Parts NEVER members". |
| EXTERNAL-RESEARCH.md | `maintenance-docs/v11-research/EXTERNAL-RESEARCH.md` | GitHub capabilities baseline (2026-04-30). §4 of THIS inventory cross-references it but also adds NEW finding (Issue fields, §4.7) discovered 2026-05-24. |
| RESEARCH-TRACKER-GROUPING-PRIMITIVES-PER-BACKEND.md | `maintenance-docs/v11-research/RESEARCH-TRACKER-GROUPING-PRIMITIVES-PER-BACKEND.md` | Updated 2026-05-23 grouping-primitive details across backends. Out of scope for BD-185 (non-GH backends are reserved) but referenced for completeness. |
| V11.1-DISCUSSION-GITHUB-PROJECTS.md | (on `main`, not v11-dev) | Parking lot for v11.1+ Projects integration. Out of scope per BD-185. |


---

## §12 — Open observations (anomalies, naming asymmetries, unsigned spaces)

Reading-order findings. Each is a factual observation; none is a recommendation.

### §12.1 — METHODOLOGY.md line citations in BD-185 prompt are stale

BD-185's docs-researcher prompt cites `METHODOLOGY.md §339-366` for the Part 1 / Part 2 definition and `METHODOLOGY:335` for the execution-note mechanism. At HEAD a5c7e62, the actual locations are `METHODOLOGY.md:414-441` and `METHODOLOGY.md:375` respectively. Section names are correct; line numbers drifted. Architect should cite by section name per `project-template/CLAUDE.md:319-321`.

### §12.2 — Two competing Part-id grammar proposals at HEAD

`REQUIREMENTS-GROUPINGS-V11.md:69` proposes `phase-N.Part-M`. `TOUCH-POINT-INVENTORY-GROUPINGS-V2.md:413` proposes `phase-N.M` shape (with no Part-suffix mention). `pack-ops/BACKLOG.md:1750` (BD-185 entry File/Symbol) proposes `part:M` label namespace separately. Three places, three different shapes. None is authoritative; architect picks (or invents a fourth shape).

### §12.3 — Mirror generator emits phases in lexical order, not integer order

`scripts/lib/per-entry/mirror-generate.sh` uses `LC_ALL=C sort` on filenames. For `phase-10.md` vs `phase-2.md`, lexical order places phase-10 before phase-2. This was true before BD-185 and is independent of BD-185's execution-order design. Architect's design must specify whether this stays (and what the mirror file then DISPLAYS as the canonical phase order — i.e., NOT integer order, NOT execution order, NOT creation order) or whether the mirror generator's sort changes. Worked example: an OT-shape project with 60 phases has many 2-digit phase numbers; the mirror would emit phase-1, phase-10, phase-11, ..., phase-2, phase-20, ..., not the intuitive integer order.

### §12.4 — Tracker reverse migration emits phases in integer order

`scripts/lib/tracker-migrate-reverse.sh:697, 733` both sort phases by `int(phase_number)`. This is integer order, not execution order. If BD-185 introduces phase execution order, the reverse-emit must respect it (or document explicitly that reverse-emit preserves integer order regardless).

### §12.5 — `sort by created_at DESC` is the typical GH issue browse order

Per `EXTERNAL-RESEARCH.md:262-281` `gh issue list --json` field set. Creation order (issue number ascending) is the implicit ordering of any issue listing. For phase epics created in single-pass migration, this matches integer order. But if phases are added mid-development, creation order DIVERGES from integer order — and BD-185's P3 cites this divergence as a problem.

### §12.6 — No pack-side IMPLEMENTATION_PLAN.md

`ARCHITECTURE-V3.md:603` (per inventory survey at `RESEARCH-PER-ENTRY-SPLIT.md:50`): "the pack repo has no `IMPLEMENTATION_PLAN.md`". BD-185 is pack-only-keyword-tagged (per `pack-ops/BACKLOG.md:1744`); pack-side changes are config files + scripts + maintenance-docs, but no pack-side phase-aware flat-file source. BD-185's tracker-side and form-side changes affect ALL clients (project-side); the absence of a pack-side IMPLEMENTATION-PLAN.md means the pack-only commit-scope-keyword is technically correct only if the BD's commit content is purely scripts + tracker schema + docs.

### §12.7 — Provider abstraction lacks a sub-issue-reprioritize op

`scripts/lib/tracker-provider.sh:138-140` exposes 3 sub-issue ops: `_create`, `_list`, `_unlink`. No `_reprioritize`. The GH backend supports REST + GraphQL reprioritization (§4.2). If BD-185 chooses sub-issue reordering as its mechanism, the abstraction grows from 18 ops to 19 + raw. Other backends (linear/jira/redmine — reserved) would need to implement or stub the new op.

### §12.8 — Issue fields (§4.7) is a NEW finding closing a knowledge gap

`maintenance-docs/v11-research/EXTERNAL-RESEARCH.md` was authored 2026-04-30 and does NOT mention Issue fields (GA public preview 2026-03-12; all-orgs 2026-05-21). The architect's design space includes Issue fields as an ordering mechanism. The architect should NOT cite `EXTERNAL-RESEARCH.md` as authoritative for "what fields GH issues support" — they should read the two changelog posts cited in §4.7 directly. Suggestion (NOT a solution proposal): the architect may want a small addendum to EXTERNAL-RESEARCH.md before designing, OR may treat THIS inventory's §4.7 as the canonical fact base.

### §12.9 — Cross-CLI dimension (Codex / Gemini)

BD-185 entry does not surface Codex CLI / Gemini CLI considerations. The cross-CLI surface (per pack memory `feedback_clarg_trinity` + the trinity rule in `CLAUDE.md`) affects:
- METHODOLOGY.md edits ship to all three CLIs identically (it's a single file copied to `docs/pack/METHODOLOGY.md` at client install).
- Project-template trinity edits (CLAUDE.md / AGENTS.md / GEMINI.md) must be byte-symmetric except for provably tool-specific changes.
- Coder / reviewer prompt templates in `project-template/docs/pack/prompts/` are read by all three CLIs.

If BD-185 introduces Part-aware report headers or new commands that name CLI-specific paths, the trinity rule applies. Architect should defer to `maintenance-docs/v11-implementation/ARCHITECTURE-BD-182.md` for the canonical cross-CLI reference table.

### §12.10 — Issue dependency cap (50 per issue) vs. potential ordering use

If BD-185 chooses block/blocked-by chains as the ordering mechanism (§4.13 option 5), the cap of 50 blocks per issue × 50 blocked-by per issue means a phase can express dependencies on up to 50 other phases. For typical project shapes (~28-60 phases) this is fine; for OT-style 60-phase projects it could be tight depending on graph topology.

### §12.11 — No pack-verb for phase split / Part introduction today

There is NO `pack phase split` verb in `scripts/pack-tracker.sh`, `scripts/pack-td.sh`, or any other script at HEAD. The planner agent emits Parts as part of its IMPLEMENTATION-PLAN.md output; the pack does not have programmatic Part-creation. If BD-185 surfaces a need for `pack phase split`, that's a new verb (cost: pack-tracker.sh + tracker-mode equivalent + help fragments + tests + CI).

### §12.12 — The single-Part-no-suffix convention is asymmetric with Parts existence

`METHODOLOGY.md:439-441` says: a single-Part phase uses the unchanged header format — `, Part 1` is NEVER appended when there is only one Part. Combined with the rule that Multi-part phases use `, Part [M]` headers, this means Parts are ALWAYS pluralized: either ZERO Parts (one chunk, unannotated) or 2+ Parts (multi-chunk). NEVER 1 Part.

The implications:
- A phase pre-split has no Part state.
- A phase post-split has 2+ Parts.
- There is no "1 Part" or "currently being split" intermediate state.

If BD-185 chooses to make Parts trackable entities, the architect must decide what the tracker state is BEFORE Parts exist. Options: no Part entities (phase epic only); a single implicit "Part 0" entity that becomes "Part 1, Part 2, ..." on split; a separate `has_parts: true/false` field. None is currently designed.

### §12.13 — task_order is per-phase, not per-Part

The existing `task_order` sidecar field (`tracker-sidecar.sh:289-303`) is keyed by phase: `phase_tasks.phase-N.task_order = [N.1, N.2, ...]`. If Parts are introduced and tasks belong to Parts, the task_order field would need to either:
- Stay per-phase (with task order spanning across Parts).
- Move to per-Part (each Part has its own task_order list of its member tasks).
- Both (per-phase task_order is union of per-Part orders).

This is an architect decision. The current sidecar schema supports the first option (no change). The second would require renaming/restructuring the sidecar.

### §12.14 — Part state taxonomy is undefined

The phase task state taxonomy (per `phase-task-v11.0/SCHEMA.md:49-56`) admits: pending / in-progress / done / deferred / merged-into:phase-N / superseded-by. Phase epic state (per `phase-epic-v11.0/SCHEMA.md:51-54`) admits: open (phase active) / closed (phase complete — all tasks done).

For Parts: undefined. Possible options if Parts are entities:
- Same as phase task taxonomy.
- Same as phase epic (open/closed, with closed-when-all-tasks-done).
- New taxonomy unique to Parts.

Architect decides. The Multi-part doc (`METHODOLOGY.md:430-441`) implies Parts complete sequentially (Part 1 finishes, then Part 2 begins — the report-header convention reinforces this with the Pass counter resetting per Part). But "finish" of a Part is implicit; there is no documented "Part 1 done" state today.

### §12.15 — METHODOLOGY's "Insert new phases at the end" rule

`METHODOLOGY.md:411`: "Insert new phases at the end of the plan."

Implications:
- A new phase that LOGICALLY belongs between Phase 3 and Phase 4 cannot become "Phase 3.5" (fractional only allowed during early architecture). It becomes "Phase 27" (or whatever the next available number is) and uses an Execution note to indicate it runs between Phase 3 and Phase 4.
- This rule makes phase numbers DIVERGE from execution order over time. Phase numbers are the BIRTH order; execution order needs to be expressed separately.
- BD-185 P3 is exactly this gap: in flat-file mode, execution-note prose explains the divergence; in tracker mode, the prose doesn't survive sync.
- Architect's reconciliation: pick how to express execution order such that the new mechanism initializes from "current implementation order" (P4) — meaning, on a fresh v10/v11 project with phase-1..phase-N where Execution notes have NOT been used yet, the natural ordering IS phase-number-ascending.

### §12.16 — Two passes of phase-state vocabulary

Phase epic state per `phase-epic-v11.0/SCHEMA.md:51-54`: open / closed.

Per-entry-tree phase-state per `project-template/docs/project/implementation-plan/_rules.md:28-31`: pending / in-progress / done / deferred / merged-into / superseded-by. Annotated in H2 via 🚧 / ✅ / ➡ markers.

These are TWO different state taxonomies referring to the SAME entity (the phase). The tracker phase epic admits only open/closed; the flat-file phase header admits more detailed state. The round-trip mechanism (per `tracker-migrate-reverse.sh:467-477`) must reconcile. Currently the reconciliation is informal — the flat-file additional states (pending/deferred/merged-into/superseded-by) map to tracker close+state_reason combinations.

For BD-185: the Part state taxonomy decision will face the same dual-taxonomy issue if Parts ship in tracker. Architect should pick a small, round-trip-clean taxonomy.

### §12.17 — Per-entry filename uniqueness vs Part-id

Per pack memory `feedback_filename_uniqueness` (cited in CLAUDE.md): filenames should be unique across the repo so prose references are unambiguous. If Parts get per-entry files named `phase-N.Part-M.md`, they introduce a NEW filename pattern; `phase-N.md` is the existing pattern. Both forms are unique relative to each other; both are unique relative to other streams. No collision risk.

But: filename uniqueness ALSO applies to fixtures and tests. If `scripts/tests/fixtures/per-entry-split/phase-1.Part-2.md` (or similar) appears, it should be unique across the repo. Architect should run the `find . -name "<proposed-name>" -not -path "./.git/*"` check before naming.

---

## §13 — Architect's worksheet checklist

For convenience, the BD-185 architect can cross-check their design against this list. The list is comprehensive at HEAD a5c7e62 and is mechanically derivable from §3 + §4 + §5 + §6 + §7 + §8 + §9 + §10. The architect must cover every row OR explicitly defer with rationale.

**For Parts hierarchy (P1, P2, SC2, SC6):**
- [ ] Part identifier grammar chosen (none of `phase-N.Part-M`, `phase-N.M`, `part:M` is authoritative — pick one or invent another)
- [ ] Part body marker decision (trio? double? none?)
- [ ] Part label namespace decision (`part:M`? `template:phase-part-v11.1`? none?)
- [ ] Part state taxonomy chosen
- [ ] Part sub-issue placement decision (sub-issue child of phase epic? Or pure label?)
- [ ] Form-family extension decision (add `phase-part-skeleton` to wi-type? Or programmatic-only?)
- [ ] Form-family soft cap impact assessed (4 → 5 options — V2 §17 R11 defense if needed)
- [ ] Template archive cut decision (v11.0 = closed; v11.1 = new — landing under `templates-archive/v11.1/phase-part-v11.1/`)
- [ ] Method by which tasks (`phase-N.M`) compose with Parts (tasks INSIDE Parts? Tasks AT phase level + Parts as parallel markers?)

**For execution ordering (P3, P4, SC4, SC7, SC8):**
- [ ] Phase-level execution-order mechanism chosen (1 of 6 listed in §4.13)
- [ ] Migrator initial-order writing decided (greenfield = phase-number-ascending — equivalent to "current implementation order"?)
- [ ] STATUS.md role NOT expanded (SC5)
- [ ] Tracker-mode + flat-file-mode round-trip preservation of order
- [ ] Cap consideration for chosen mechanism (rate limits §4.12)
- [ ] CLI/gh-version-pin sensitivity (issue-type flag, issue-fields, advanced-search — all version-pin sensitive)

**For migration (P4, SC8):**
- [ ] v10 → v11 migrator carries existing whole-number phases through unchanged
- [ ] v11.0 flat-file → tracker migrator (any) initializes ordering mechanism from current implementation order
- [ ] No manual intervention required (init-project / migrator handles initialization)

**For all immutability invariants (§9):**
- [ ] INV-1 phase number immutability preserved
- [ ] INV-2 task-id `phase-N.M` immutability preserved
- [ ] INV-3 tracker entity ID immutability preserved (no entity recreation)
- [ ] INV-4, INV-5 body-marker trios preserved
- [ ] INV-6 Path 3 forbidden (no folding)
- [ ] INV-7, INV-8 form-family rules respected (4-option soft cap; defense if extended)
- [ ] INV-9 STATUS.md dashboard role locked

**For CI checks (§7):**
- [ ] Check 32 (mirror in-sync) extended if Parts get per-entry files
- [ ] Check 33 (TOC in-sync) extended if Parts impact TOC grouping
- [ ] Check 34 (cross-reference integrity) extended if Parts get new id form
- [ ] Check 35 (phase-task lib invariants) extended/paralleled if Parts get their own lib
- [ ] `check_issue_template_forms` extended if `wi-type` gains a 5th option
- [ ] `check_template_archive_v11` extended if Parts get an archive entry

**For TrackerProvider (§8):**
- [ ] Each of 18 existing ops verified for Part / ordering metadata flow
- [ ] New ops added if needed (`provider_sub_issue_reprioritize`? `provider_set_field`? `provider_set_type`?)
- [ ] id-map.json schema extension decision
- [ ] sidecar.yaml schema extension decision

**For doc surface:**
- [ ] METHODOLOGY.md updates (Multi-part phases extended for mid-work expansion + tracker representation)
- [ ] MIGRATION-v10-to-v11.md updates (if migrator behavior changes)
- [ ] HELP-FRAGMENT-PACK.md / HELP-FRAGMENT-TRACKER.md updates (if new verbs)
- [ ] `_rules.md` extension for implementation-plan stream (if Part shape affects entry contract)
- [ ] `_intro.md` user guidance update

---

## End of inventory

This inventory is exhaustive at HEAD a5c7e62 across the v11-dev working tree. No claim of completeness for any future state. Re-verify if working from a later commit; the architect should re-read `pack-ops/BACKLOG.md`, `supporting-docs/METHODOLOGY.md`, and `scripts/lib/tracker-*.sh` for any drift before designing.

For questions about content of this inventory, contact pack-docs-researcher author at the date of authoring above. The inventory contains NO solutions and NO recommendations; it is a fact base only.

