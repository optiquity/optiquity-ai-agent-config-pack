# TOUCH-POINT-INVENTORY-GROUPINGS-V2.md

**Authored by:** pack-docs-researcher (read-only enumeration pass).
**Date:** 2026-05-21 (US/Pacific).
**Branch:** v11-dev.
**Repo HEAD at authoring:** 70edb97 — docs: v11 — BD-179 survey report (Phase 1 print-only run; 160 bare-refs detected).
**Source doc:** `main:maintenance-docs/v11-research/V11.1-DISCUSSION-GITHUB-PROJECTS.md` (344 lines; copied to `/tmp/V11.1-DISCUSSION-GITHUB-PROJECTS.md` at authoring time).

## Purpose

Comprehensive, read-only enumeration of every file in the pack repo that
would be touched if the pack added a **grouping** primitive under the
four design constraints in the brief:

1. First-class entity treatment (per-entry tree + tracker representation
   + bi-directional sync).
2. Tracker portability (BD-060 TrackerProvider extension, not GH-only).
3. Reversibility (every tracker state round-trips to flat-file).
4. Smooth integration with existing v11 design (minor adjustments OK;
   major revisions flagged for user discussion).

Style mirror: `maintenance-docs/archive/v11/TOUCH-POINT-INVENTORY-PER-ENTRY.md`.
The architect downstream must cover every row in §3 (touch-point table)
by section number or explicitly defer with rationale; the compatibility
break-points in §6 are not designable here.

## Conventions

- Paths are repo-root-relative unless otherwise noted.
- `Scope` is one of `pack` / `project` / `both`.
- Citations use `path:line` for v11-dev files (verified at HEAD above)
  and `main:path` for V11.1-DISCUSSION lines (extracted from
  `/tmp/V11.1-DISCUSSION-GITHUB-PROJECTS.md`).
- "Native grouping primitive" = a tracker's first-class entity that
  collects multiple work items into a higher-order container with
  optional fields (status, dates, ownership). The pack's grouping
  abstraction sits on top of these per-backend.
- "Phase parts" = BD-185 mid-work splitting mechanism. Distinct from
  groupings (which span PHASES, not within a phase).
- "v11.0 design constraint" (per V11.1 doc §12) — v11.0 ships without
  any grouping-related code or doc changes; the inventory below
  describes the v11.1+ overlay surface.

## Section index

1. §1 — What the V11.1 doc proposes (concept/feature inventory)
2. §2 — Native grouping primitives by tracker (primary-doc citations)
3. §3 — Touch-point table (new + modified files at file/symbol level)
4. §4 — Per-stream contract for a grouping per-entry tree
5. §5 — TrackerProvider extension surface (BD-060 op-level additions)
6. §6 — Integration touch points with existing v11 design (minor vs
   major flag)
7. §7 — Compatibility break-points (must be discussed before any work)
8. §8 — Immutability invariants and round-trip carriers
9. §9 — Bi-directional sync touch points (forward + reverse + sidecar
   shape)
10. §10 — Validator check footprint and fixture-test inventory
11. §11 — Open observations (anomalies, naming, asymmetries)

---

## §1 — What the V11.1 doc proposes

Itemised inventory of distinct concepts / features / operations the
V11.1 doc raises. Organisation reflects my own reading order from the
primary source; section references in parentheses are V11.1 sections.

### §1.1 — Concept-level proposals (the design space)

| # | Concept | V11.1 § | Status in pack today |
|---|---|---|---|
| C1 | Grouping = named collection of phase IDs sharing a common purpose | §8 | Absent. Pack has no grouping primitive (flat-file OR tracker). |
| C2 | Grouping is **explicit-membership** (declared in the grouping doc, not via phase tags or heuristics) | §9 (decision) | Absent. |
| C3 | Grouping `Kind` is enumerated (default enum: `user-journey`, `ambient-feature`, `foundational-batch`, `refactor-cluster`, `release-package`); user-extensible TBD per §14 Q2 | §10 | Absent. |
| C4 | Grouping membership is **just IDs** — no reordering, no annotation, no execution-sequence metadata (execution order = phase Blockers/Unblocks DAG; UX order = PRD/journeys doc) | §10 | Absent. The pack has Blockers/Unblocks (ARCHITECTURE-V3.3-DELTA.md §5; admits `phase-N`, `phase-N.M`, `TD-NNN`, `BD-NNN` per §5.3) but no membership-by-list primitive. |
| C5 | PRD / JOURNEYS.md reference is **optional and unparsed** by the pack — pack does NOT enforce any PRD format | §11 | Absent. Pack has no PRD/JOURNEYS concept at all. |
| C6 | A phase can belong to multiple groupings (overlap dedup via tracker semantics — closing the issue propagates to all Projects) | §8 dedup section | Absent. |
| C7 | Phases stay grouping-agnostic at v11.0 (no Groupings field; no tags); groupings layer in v11.1+ as overlay | §12 | The v11.0 phase entity (per `project-template/docs/project/implementation-plan/_rules.md` + ARCHITECTURE-V3.3-DELTA.md §6.3) carries no grouping field — satisfied today. |
| C8 | Phase-as-Project rejected; Grouping-as-Project is the right granularity | §7 | n/a (no Projects today). |
| C9 | "Hybrid where it earns its keep" — a grouping doc MAY declare `auto-include phases matching X regex` as a convenience layer (feature of the grouping, not a phase tag) | §9 hybrid sub-section | Absent. |
| C10 | Cross-Project membership at issue level — one phase issue lives as multiple Project items, each with per-Project field values | §2 + §8 dedup | Absent. The pack's existing entity model (V3.3 §6.3) admits one entity per issue with one set of labels/state; per-Project field overlays are unrepresented. |

### §1.2 — Surface-level proposals (concrete shapes)

| # | Surface | V11.1 § | Status / pre-existing analog |
|---|---|---|---|
| S1 | A `groupings/` directory under `docs/project/` (client) and optionally pack-root `groupings/` for pack-self — parallel to per-entry `backlog/` / `implementation-plan/` / `changelog/` | §10 + §12 | Absent. Per-entry trees exist for the three v11.0 streams (`project-template/docs/project/backlog/`, `implementation-plan/`, `changelog/` — see `_rules.md` files). No fourth `groupings/` tree. Pack-self per-entry trees exist for BACKLOG + CHANGELOG only (no IMPLEMENTATION-PLAN per V11.1 §14 Q1 + per `scripts/lib/per-entry/_lib.sh:64`). |
| S2 | A `groupings/_rules.md` per-stream contract (extends the per-entry pattern) | §12 (last bullet) | Absent. The pattern is established for the three streams via `_rules.md` (filename regex + lifecycle states + supporting files + write authority — see `project-template/docs/project/backlog/_rules.md`). |
| S3 | Grouping doc shape (one file per grouping; H1 title; `**Kind:**`; `**Description:**`; `**Member phases (by ID):**` list; optional `**Source PRD section / journeys doc:**`) | §10 | Absent. |
| S4 | Optional `tracker.toml` `[project]` section (project number / URL / default-field-map) | §5 Shape 1 + §13 row Y-2 | Absent. `tracker.toml.pack-example` + `project-template/tracker.toml.project-example` have `[backend]` / `[mode]` / `[mirror]` / `[id_namespace]` / `[migration]` / `[cli_acceleration]` only (per `scripts/lib/tracker-init.sh:342-372` emitter). |
| S5 | `pack tracker init` extension: read groupings + create Project + populate items + set field-map from BACKLOG/phase state | §13 row Y-3 | Verb exists (`scripts/pack-tracker.sh` per BD-066 `pack-ops/BACKLOG.md:120-129`); extension adds a new stage. |
| S6 | NEW `pack tracker groupings rebuild` verb — refresh Project membership after grouping doc edits | §13 row Y-4 | Absent. |
| S7 | NEW `scripts/lib/tracker-grouping.sh` helper library | §13 row Y-3 + Y-4 | Absent. |
| S8 | Trinity / HELP-FRAGMENT / OPTIONAL-FEATURES.md updates documenting the new feature | §13 row Y-5 | Documents exist (per `project-template/CLAUDE.md:222-226` Document locations; `pack-ops/HELP-FRAGMENT-PACK.md`; `OPTIONAL-FEATURES.md` per touch-point inventory archive §1.D); the additions are deltas to existing files. |
| S9 | Phase-Iteration "single all-phases Project sliced by Iteration field, where each Phase ID becomes an Iteration" (sprint-board temporal view) | §7 last paragraph + §13 row Y-6 optional | Absent. GH Iteration field is a separate primitive — see §2.1 below. |
| S10 | PRD / JOURNEYS.md reference resolution (clickable links from grouping doc to PRD anchor) | §13 row Y-7 optional | Absent. Pack does not currently link any operational doc to a PRD-shaped file. |
| S11 | NEW `MIGRATION-v11.0-to-v11.1.md` user-facing migration narrative | §13 row Y-5 | Absent (no v11.1 yet; analog: `supporting-docs/MIGRATION-v10-to-v11.md` per `pack-ops/CHANGELOG.md` BD-084). |

### §1.3 — Open questions the V11.1 doc identifies (planner / architect surface)

Verbatim per §14, with the pack-relevant noun extracted:

| Q | Topic | Pack surface that would carry the answer |
|---|---|---|
| Q1 | Groupings directory location for pack-self — does pack-self even *have* phases? | Pack-self per-entry trees (per `scripts/lib/per-entry/_lib.sh:64-83` — pack-self has `pack-backlog` + `pack-changelog` only; no `pack-implementation-plan`). |
| Q2 | Kind enumeration extensibility (fixed vs user-extensible) | `groupings/_rules.md` + (if extensible) a validate-pack check enforcing the enum. |
| Q3 | Project-creation API costs (rate limits; incremental creation; checkpoints; opt-out) | `scripts/lib/tracker-grouping.sh` + reuse of BD-065 / BD-066 checkpoint shape (per `pack-ops/BACKLOG.md:105-129`). |
| Q4 | Sync direction for Project fields (GH UI edit → pack overwrite on next sync, or pull into BACKLOG entry?) | TrackerProvider extension + reverse-emit shape (BD-067 reverse migration is the current contract per `pack-ops/BACKLOG.md:133-143`). |
| Q5 | Multi-Project membership cost (per-Project field-map config) | `tracker.toml` `[project]` section schema. |
| Q6 | Should groupings be in the RAG manifest? | `project-template/docs/pack/PM-CHAT.md:135-172` RAG ingestion manifest table + `## Additional project documents` section. |
| Q7 | Provider abstraction implications — Linear has Projects (similar); Jira has Epics + Sprints (different); Forgejo has nothing equivalent. Grouping doc should be provider-agnostic; tracker integration of groupings should be per-provider. | BD-060 TrackerProvider abstraction (`scripts/lib/tracker-provider.sh:1-20`; 18 ops + raw + capabilities — see §5 below for the extension surface). |

### §1.4 — Decisions the V11.1 doc declares "working assumption" (§15 parking lot)

These are NOT design proposals to evaluate; they are framing the architect must respect or surface as needing user revisitation:

- Shape 1 (lightweight `tracker.toml [project]` section) chosen over Shape 0 (do nothing) and Shape 2 (full first-class Project integration).
- v11.1 minor, not v12 major.
- Phase-as-Project rejected.
- Explicit-membership over tagging and heuristics (§9 decision).
- Phases stay agnostic of grouping membership.
- PRD/JOURNEYS format is user's choice; pack does not parse.
- GH Projects' multi-Project-per-issue semantics handles overlap dedup automatically.
- v11.0 ships without grouping-related code or doc changes.

### §1.5 — Scope NOT in V11.1 (per §6 + §17)

- Graphify is explicitly deferred to v12 per `RESEARCH-GRAPHIFY-SYNTHESIS.md` (cited in V11.1 §17). Graphify and groupings are different timelines.
- BD-185 (phase parts hierarchy + tracker-mode execution ordering) is a sibling concern at the phase level — not the grouping level. BD-185 lives at Batch 19d per `pack-ops/BACKLOG.md:1744-1789`. Groupings (this BD's scope) sit one level ABOVE phase parts; the architect must ensure the two compose cleanly (see §6 + §7 below).

---

## §2 — Native grouping primitives by tracker

This section enumerates how each tracker the pack might plausibly support represents "a named collection of work items." Citations are direct primary-source URLs (verified by web search at authoring time; URLs subject to upstream change).

### §2.1 — GitHub (Projects v2)

GH offers **two complementary primitives** that the grouping abstraction could map onto:

- **Project (Projects v2)** — a project-management view layer over issues + PRs at user / org / repo scope. Custom fields, multiple views (Board / Table / Roadmap), built-in automations, sub-issue + Item shape support. Project items are issues, PRs, or Drafts. ([GH docs: About Projects](https://docs.github.com/en/issues/planning-and-tracking-with-projects/learning-about-projects/about-projects))
- **Iteration field** — a project-scoped custom field type that represents time-boxed periods (sprints / cycles); each project may declare one or more iterations. ([GH GraphQL API for Projects](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-api-to-manage-projects))

**Field types supported in Projects v2 custom fields:** single-select, text, number, date, **iteration** (per [GH community discussion on Projects v2 webhooks](https://github.com/orgs/community/discussions/17405)).

**Per-Project field limit:** **50 fields total** per project — built-in metadata + custom fields + organization-level issue fields all count toward this limit. ([GH community discussion: fields limits](https://github.com/orgs/community/discussions/66977))

**Per-Org issue-field limit:** up to **25 issue fields per organisation** (separate from per-Project limit). ([GH docs: Managing issue fields](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/managing-issue-fields-in-your-organization))

**Single-select option limit:** 25 options per single-select field (long-standing constraint per [GH community discussion 6419](https://github.com/orgs/community/discussions/6419)).

**Project items live where:** as project-scoped overlay on issues. The Project item carries per-Project field values; the underlying issue is still the issue (same number, body, labels, comments). Removing an item from a Project does not change the issue. Closing the issue can trigger Project automations. ([V11.1 §2 + GH docs](https://docs.github.com/en/issues/planning-and-tracking-with-projects/learning-about-projects/about-projects))

**Multi-Project membership:** one issue can live in multiple Projects with different field values per Project. ([V11.1 §2 + §8 dedup section])

**Webhook surface:** `project_v2_item` event includes project custom-field changes (previous + current values) directly in the payload. Project webhooks are **organisation-level only** — user-level project webhooks are not available. ([GH Changelog 2024-06-27](https://github.blog/changelog/2024-06-27-github-issues-projects-graphql-and-webhook-support-for-project-status-updates-and-more/))

**API access:** GraphQL only for Projects v2 (REST is for Projects Classic, retired). Mutations: `addProjectV2ItemById`, `updateProjectV2ItemFieldValue`, `deleteProjectV2Item`, `createProjectV2Field`, etc. ([GH docs: Using the API to manage Projects](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-api-to-manage-projects))

**Automations:** built-in workflows auto-set fields on add/change; auto-archive when criteria met; auto-add from a repo when items match criteria. ([V11.1 §2 + GH docs above])

**Insights:** built-in charts (status histogram, burnup, group-by-field counts). ([V11.1 §2])

### §2.2 — Linear

Linear has **three relevant primitives**, each with distinct semantics:

- **Projects** — named collections of issues with start/end dates, lead, status. Closest analog to a "grouping" in V11.1's sense. ([Linear docs: Projects](https://linear.app/docs/projects))
- **Cycles** — time-boxed sprint-equivalents at the team level. Configurable length, auto-rollover for incomplete issues, cycle-level velocity tracking. ([Linear docs: Cycles](https://linear.app/docs/use-cycles))
- **Custom views** — saved filtered/sorted projections over issues; per-page-level (cycles, projects, etc.) can save inline-filter custom views. ([Storylane tutorial on custom views](https://www.storylane.io/tutorials/how-to-create-custom-views-in-linear))

**API:** GraphQL only. Schema is explorable at Apollo Studio. ([Linear API and Webhooks docs](https://linear.app/docs/api-and-webhooks))

**Webhook events:** Issues, Comments, Issue attachments, Documents, Emoji reactions, **Projects**, Project updates, **Cycles**, Labels, Users, Issue SLAs. ([Linear docs: API and Webhooks](https://linear.app/docs/api-and-webhooks))

**Mapping to V11.1 grouping primitive:** Linear's **Project** is the closest match — a named collection of issues with metadata. Linear's **Cycle** is the closest match to V11.1 §7's "phase-as-iteration" alternative. The pack's grouping abstraction would route to Project; the phase-iteration overlay (V11.1 §7) would route to Cycle.

### §2.3 — Jira

Jira has **three primitives**, with the issue-type hierarchy as the load-bearing structural element:

- **Epic** — Level 1 of Jira's default hierarchy (above Story / Task / Bug at Level 0; Subtask at Level -1). An epic is a parent issue containing child issues. ([Jira Cloud REST API: Project hierarchy](https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-projects/))
- **Sprint** — a time-boxed period for completing a set of issues. Requires sprint name + origin board id; start/end dates and goal optional. ([Jira Software Cloud REST API: Sprints](https://developer.atlassian.com/cloud/jira/software/rest/api-group-sprint/))
- **Component** — categorical metadata for issues within a project (often used for sub-product or sub-team grouping). [Jira REST API v2 — Components endpoint, per Atlassian docs.]

**Issue-type hierarchy:** Level 1 Epic → Level 0 Story/Task/Bug → Level -1 Subtask. ([Jira hierarchy guide](https://www.upscale.tech/blog/epic-story-task-hierarchy-in-jira))

**REST API endpoints (v3):** `/rest/api/3/project/{projectId}/hierarchy`; sprint endpoints under `/rest/agile/1.0/sprint/`. ([Jira Cloud REST API docs](https://developer.atlassian.com/cloud/jira/platform/rest/v3/))

**Mapping to V11.1 grouping primitive:** Jira's **Epic** maps to grouping semantically, but Jira's epic is **hierarchical** (children are issues, not metadata-tagged) — different from GH Projects' overlay model. Jira's **Component** maps to a "grouping kind tag" — but components are scoped to a single project, not cross-cutting like V11.1's grouping concept. Jira's **Sprint** maps to V11.1 §7's phase-iteration overlay.

**Asymmetry vs GH Projects:** GH allows one issue in multiple Projects with different field values. Jira allows one issue in **one epic** (parentage is exclusive). The V11.1 design's "phase belongs to multiple groupings" (C6 above) does NOT cleanly express in Jira's epic model — it would require Components (which can be multi-valued) or a separate epic-linking mechanism. The provider abstraction must handle this asymmetry.

### §2.4 — Redmine

Redmine has two relevant primitives:

- **Version** — a release-grouping primitive at the project level. Issues are assigned to a version; the version shows progress and contains the issues. Closest match to V11.1 grouping's `release-package` Kind. ([Redmine wiki: Rest Versions](https://www.redmine.org/projects/redmine/wiki/Rest_Versions))
- **Issue Category** — categorical tag for issues within a project (defaults to a project-level enum like "Bug" / "UI" / "Backend"). ([Redmine wiki: Rest IssueCategories](https://www.redmine.org/projects/redmine/wiki/Rest_IssueCategories))

**API:** REST (XML + JSON). Versions endpoint listed at `/projects/foo/versions.json`; issue categories at `/projects/foo/issue_categories.json`. ([Redmine REST API wiki](https://www.redmine.org/projects/redmine/wiki/rest_api))

**Mapping to V11.1 grouping primitive:** Redmine's **Version** maps to V11.1's `release-package` Kind specifically. Redmine's **Issue Category** maps to other Kind values, but is single-valued per issue (asymmetry similar to Jira's Component).

### §2.5 — GitLab

GitLab has three primitives:

- **Epic** — group-level container for related issues (Ultimate tier; nested epics provide hierarchy). ([GitLab docs: Epics](https://docs.gitlab.com/user/group/epics/) — the Epics REST API is deprecated per [GitLab Epics API docs](https://docs.gitlab.com/api/epics/) — migration TBD)
- **Milestone** — project- or group-scoped collection of issues / merge requests / epics with a target date. Can be assigned to epics (recent feature). ([GitLab docs: Milestones](https://docs.gitlab.com/user/project/milestones/))
- **Iteration** — sprint-equivalent for agile-style planning. ([GitLab Epics #2422 about iterations](https://gitlab.com/groups/gitlab-org/-/epics/2422))

**Mapping to V11.1 grouping primitive:** GitLab's **Epic** is closest to grouping (Ultimate-tier feature). **Milestone** is closer to release-package Kind. **Iteration** maps to V11.1 §7's phase-iteration overlay.

**Caveat:** Epic API deprecation makes the integration future-uncertain. The provider abstraction would need to track GitLab's replacement API.

### §2.6 — Forgejo / Gitea

Forgejo (fork of Gitea since 2022; current pack-acknowledged backend in OPTIONAL-FEATURES.md per `pack-ops/BACKLOG.md` BD-060 description as a future-reserved provider) has:

- **Milestone** — issue-grouping primitive at the repo level with a due date. ([DeepWiki: Gitea Issue Management](https://deepwiki.com/go-gitea/gitea/5.1-issue-management-system))
- **Project boards** (kanban-style; lightweight) — repo or org scope. [Per general Gitea / Forgejo docs.]

**Mapping to V11.1 grouping primitive:** Forgejo's **Milestone** maps to release-package Kind (similar to Redmine Version). The **Project boards** map structurally to GH Projects but with reduced field-type flexibility.

**Status:** Forgejo is API-compatible with Gitea per [comparison docs](https://forgejo.org/compare/); both have "nothing equivalent to GH Projects' rich field-typed overlay" per V11.1 §14 Q7 wording. The grouping doc would need to degrade gracefully on Forgejo (or be GH-conditional).

### §2.7 — Cross-tracker matrix

| Tracker | Grouping primitive | Iteration primitive | Multi-grouping per issue? | Native field types |
|---|---|---|---|---|
| GitHub | Project (v2) | Iteration field (custom field) | **yes** (multi-Project per issue) | single-select, text, number, date, iteration |
| Linear | Project | Cycle | yes (multi-Project per issue) | multiple custom field types |
| Jira | Epic + Component | Sprint | **no** (epic is exclusive parent); Component is multi-valued | issue type fields |
| Redmine | Version + Issue Category | (none native; emulated) | Category multi-valued; Version single-valued | custom fields |
| GitLab | Epic + Milestone | Iteration | partially (Epic nested; Milestone multi-issue) | custom fields |
| Forgejo / Gitea | Milestone | (none native) | no (one milestone per issue) | labels only |

**Architect-relevant asymmetry summary:** The "multi-Project per issue" property V11.1 §8 relies on for overlap dedup is **GH-specific** (also present in Linear). Jira / Redmine / Forgejo / Gitea would need emulation or a degraded surface. The V11.1 doc's §14 Q7 already flagged this; the grouping doc format being provider-agnostic (per Q7) means the **tracker integration** of groupings is per-provider.

---

## §3 — Touch-point table

A flat enumeration of every file that would be **new** or **modified** if a v11.1+ grouping primitive landed under the four design constraints. Rows are grouped under sub-headings; the heading order is for browsing only.

### §3.A — NEW pack-product surfaces (project-template/, ships to clients)

| Path | Scope | Type | Per-stream impact | Notes |
|---|---|---|---|---|
| `project-template/docs/project/groupings/_rules.md` | project | NEW per-stream contract | high — defines stream identity, filename regex, lifecycle states, supporting files, write authority | Mirrors style of `project-template/docs/project/{backlog,implementation-plan,changelog}/_rules.md` (see §4 below for the full contract draft surface). Stream key reservation in `scripts/lib/per-entry/_lib.sh:64` PE_STREAM_KEYS list needed (see §3.D). |
| `project-template/docs/project/groupings/_intro.md` | project | NEW per-stream intro | high — mirror header that names the per-entry tree as source of truth in flat-file mode, mirror in tracker mode | Mirrors style of `project-template/docs/project/{backlog,implementation-plan,changelog}/_intro.md`. |
| `project-template/docs/project/groupings/_toc.md` | project | NEW per-stream TOC seed | low — empty seed at install per BD-164 TOC regenerator pattern in `scripts/lib/per-entry/toc-regenerate.sh` | Greenfield empty seed; generator-produced; same pattern as `init-project.sh:1025-1028`. |
| `project-template/docs/project/groupings/_format.md` (CONDITIONAL) | project | NEW per-stream format spec | medium — only if grouping doc shape needs explicit format pinning beyond `_rules.md` (open architect decision; the precedent is `project-template/docs/project/changelog/_format.md` which exists because changelog has append-only + dated semantics) | Architect decides whether grouping needs `_format.md`; if the Kind enum + Member-list shape is fully captured in `_rules.md` no `_format.md` is needed. |
| `project-template/docs/project/GROUPINGS.md` | project | NEW regenerated mirror | high — read-stable concatenation produced by `scripts/lib/per-entry/mirror-generate.sh`; never source of truth in flat-file mode | Parallel to `docs/project/{BACKLOG,IMPLEMENTATION-PLAN,CHANGELOG}.md` per `project-template/CLAUDE.md` Document locations table (per `project-template/CLAUDE.md` § "Per-entry source-of-truth trees (v11.0)"). |

### §3.B — NEW pack-self surfaces (pack-root, optional per V11.1 §14 Q1)

The V11.1 doc §14 Q1 explicitly raises whether pack-self has phases that benefit from grouping. Pack-self uses BD numbering + batch grouping inside EXECUTION-PLAN (per the V11.1 doc itself); the architect must resolve whether pack-self gets a `groupings/` tree at all.

| Path | Scope | Type | Per-stream impact | Notes |
|---|---|---|---|---|
| `groupings/` (pack-root) | pack | NEW per-stream tree (OPTIONAL — pending Q1 resolution) | medium | If pack-self has no phases that benefit, this tree is omitted entirely and `PE_STREAM_KEYS` adds only the `project-groupings` key (not `pack-groupings`). |
| `groupings/_rules.md` (pack-root) | pack | NEW (CONDITIONAL on Q1) | medium | Mirrors project-template per-stream-contract style. |
| `groupings/_intro.md` (pack-root) | pack | NEW (CONDITIONAL on Q1) | medium | Mirror header. |
| `pack-ops/GROUPINGS.md` | pack | NEW (CONDITIONAL on Q1) regenerated mirror | medium | Parallel location to `pack-ops/BACKLOG.md` / `pack-ops/CHANGELOG.md` per current pack-ops/ convention. |

### §3.C — NEW scripts (helper libraries + verb dispatchers)

| Path | Scope | Type | Symbol-level | Notes |
|---|---|---|---|---|
| `scripts/lib/tracker-grouping.sh` | both | NEW helper library | new functions: `tracker_grouping_load` (parse `groupings/<name>.md`), `tracker_grouping_resolve_phases` (resolve member-ID list to tracker IDs), `tracker_grouping_create_project_items` (forward), `tracker_grouping_reverse` (tracker → flat-file), `tracker_grouping_validate_membership` | V11.1 §13 row Y-3 calls this out explicitly. Consumes `scripts/lib/tracker-provider.sh` extension surface (§5 below). |
| `scripts/lib/per-entry/_lib.sh` adapter for groupings stream (NOT new file; MODIFY existing) | both | MODIFY — add `project-groupings` (and conditionally `pack-groupings`) to `PE_STREAM_KEYS` constant; add new `case` branch in `pe__stream_attr()` | `scripts/lib/per-entry/_lib.sh:64` PE_STREAM_KEYS string; `:66-122` pe__stream_attr() case statement | Adds tuple: `mirror` = `docs/project/GROUPINGS.md`; `entry-regex` = e.g., `^[a-z][a-z0-9-]*\.md$` (architect decides — slug-based naming TBD); `support` = `_rules.md _intro.md _toc.md` (or +`_format.md` per §3.A row 4); `dir-suffix` = `docs/project/groupings`. |
| `scripts/pack-tracker.sh` cmd_groupings dispatcher | both | MODIFY — add new verb dispatch for `pack tracker groupings <subcommand>` | new subcommand cases: `groupings init` (V11.1 §13 row Y-3), `groupings rebuild` (V11.1 §13 row Y-4), `groupings status`, `groupings doctor`, `groupings disable` (parallel to existing tracker verbs) | Existing pattern (per BD-066): the dispatcher takes a verb + optional subverb. The groupings verb cluster is a sibling to `tracker init` / `tracker status` etc. |

### §3.D — MODIFIED — tracker config schema

| Path | Scope | Type | Symbol-level | Notes |
|---|---|---|---|---|
| `tracker.toml.pack-example` | pack | MODIFY (CONDITIONAL on Q1) | add `[project]` section: `enabled = false` (opt-in); `project_number = 0`; `project_url = ""`; `default_field_map = { status = "Status", iteration = "Iteration" }` (TBD by architect) | V11.1 §5 Shape 1 + §13 row Y-2. New section schema must compose with existing `[backend]` / `[mode]` / `[mirror]` / `[id_namespace]` / `[migration]` / `[cli_acceleration]` sections (per `scripts/lib/tracker-init.sh:342-372`). |
| `project-template/tracker.toml.project-example` | project | MODIFY | add `[project]` section (same shape as pack copy with comment placeholder `<your-project-number>`) | Mirror of pack copy. |
| `scripts/lib/tracker-config.sh` | both | MODIFY — add getter functions for `[project]` keys | new functions: `tracker_project_enabled`, `tracker_project_number`, `tracker_project_url`, `tracker_project_field_map` | Follows pattern of existing config-getter functions per BD-061 (`pack-ops/BACKLOG.md:48-58`). |
| `scripts/lib/tracker-init.sh` `_tracker_init_write_tracker_toml()` | both | MODIFY — emit `[project]` section in default `tracker.toml` | `scripts/lib/tracker-init.sh:342-372` add `[project]` block emission | The current emitter writes 6 sections; adds a 7th (or 8th if a separate `[grouping]` section is preferred — architect decides). |

### §3.E — MODIFIED — TrackerProvider abstraction

See §5 for the full op-level extension surface; this row is the touch-point inventory entry.

| Path | Scope | Type | Symbol-level | Notes |
|---|---|---|---|---|
| `scripts/lib/tracker-provider.sh` | both | MODIFY — add provider operations for groupings (per-backend dispatch) | new functions: `provider_project_create`, `provider_project_update`, `provider_project_delete`, `provider_project_get`, `provider_project_list`, `provider_project_field_create`, `provider_project_field_update`, `provider_project_field_value_set`, `provider_project_item_add`, `provider_project_item_remove`, `provider_project_item_list` (op count TBD by architect; §5 expands) | The abstraction would gain ~10-12 new ops over the current 18 + raw + capabilities. The `raw()` escape hatch remains the fallback for backends that need backend-specific calls. |
| `scripts/lib/tracker-provider-gh.sh` | both | MODIFY — implement GH backend for the new ops via GraphQL Projects v2 API | functions: `tracker_provider_gh_project_create`, etc. (mirroring the abstract op names) | All GH Projects v2 ops are GraphQL only (REST is for Classic which is retired); the existing `_gh_run` helper at `scripts/lib/tracker-provider-gh.sh:115` will need a GraphQL variant or extension. Capability flags (per BD-060) add `projects_v2` capability. |
| `scripts/lib/tracker-provider-<backend>.sh` (Linear / Jira / Forgejo / etc. — reserved per BD-060) | both | NEW per-backend implementations as backends ship | per-backend dispatch via `_tracker_provider_dispatch` switch (`scripts/lib/tracker-provider.sh:100`) | The V11.1 doc §14 Q7 explicitly defers per-provider grouping integration. Each new backend adds a case to the dispatcher per the BD-060 contract at `scripts/lib/tracker-provider.sh:9-23`. |
| `scripts/lib/tracker-labels.sh` | both | MODIFY (CONDITIONAL) — add label namespace for groupings if labels-based emulation is needed for low-capability backends | new label families: `grouping:<name>`, `grouping-kind:<kind>` | Pattern matches BD-066 45-label canonical set per `pack-ops/BACKLOG.md:120-129` (architect determines whether to use labels or sidecar emulation). |

### §3.F — MODIFIED — init / migrate / customization scripts

| Path | Scope | Type | Symbol-level | Notes |
|---|---|---|---|---|
| `scripts/init-project.sh` stage S11 | project | MODIFY — install groupings per-entry tree skeleton at fresh install | extend the per-entry install block at `scripts/init-project.sh:902-1031` to include `pe_src/groupings/` → `pe_dst/groupings/` copy + empty-seed mirror + TOC regenerate; extend the `pe_spec` loop at `:1007-1010` to add `"project-groupings|docs/project/GROUPINGS.md|docs/project/groupings"` tuple | Same pattern as the existing 3-stream install (backlog / implementation-plan / changelog). The pe_src + pe_dst path computations carry forward; only the loop spec grows. |
| `scripts/init-project.sh` cmd_update | project | MODIFY — extend `_cmd_update_iter_dir` to pick up new `groupings/` template files for existing clients | `scripts/init-project.sh:1047-1061` iteration loop already walks `$PACK/project-template/`; new files under `project-template/docs/project/groupings/` are picked up automatically. Validation: the customization-preserve classifier must route new files to `generic` 3-way text dispatch per `pack-ops/MERGE-STRATEGY.md:245-275`. | Trivial extension; the iteration is directory-wide so files are picked up by structure. |
| `scripts/migrate-v10-to-v11.sh` | n/a (v10→v11 already shipped; v11.0→v11.1 is a new migrator) | n/a | n/a — pre-existing v10 projects do not have groupings; the v10→v11 migrator does not touch this surface | New `scripts/migrate-v11.0-to-v11.1.sh` adapter required per `maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md` migrator framework — see next row. |
| `scripts/migrate-v11.0-to-v11.1.sh` | project | NEW migrator adapter | sources `scripts/lib/migrator-core.sh` per CLAUDE.md:35-40 contract; declares `MIGRATOR_FROM_VERSION="v11.0"`, `MIGRATOR_TO_VERSION="v11.1"`, the hook functions, and any new stage hooks (e.g., `stage_groupings_install`) per `scripts/lib/migrator-stages.sh` | Per CLAUDE.md:35-40: "Do NOT copy `scripts/migrate-v10-to-v11.sh` and rewrite — that regresses the framework." Use the BD-119 framework. |
| `scripts/lib/migrator-core.sh` `migrator_target_surface_for_version()` | both | MODIFY — add `v11.1` case that inherits v11.0 surface + adds groupings | `scripts/lib/migrator-core.sh:524-565` case statement — new `v11.1)` branch listing all v11.0 entries plus `docs/project/groupings/_rules.md`, `docs/project/groupings/_intro.md`, `docs/project/GROUPINGS.md` (and `_format.md` if used) | Per BD-160's first realized consumer pattern (per CLAUDE.md "Architect-doc-vs-reality reconciliation" rule) — when v11.1 BDs realize the design here, the helper gains a new version case. |
| `scripts/lib/customization-preserve.sh` | project | MODIFY (CONDITIONAL) — extend 12 file classes if groupings need their own class | new class `grouping-entry` (CONDITIONAL — pending architect decision); else route through `generic` 3-way text per `pack-ops/MERGE-STRATEGY.md:245-275` | The per-entry trees route through `generic` today per `MERGE-STRATEGY.md:256-275`; the simplest path is to keep groupings under `generic`. A dedicated class is only needed if groupings have non-text content (e.g., declarative YAML headers) requiring specialised merge. |

### §3.G — MODIFIED — METHODOLOGY + project-template trinity + PM-CHAT

| Path | Scope | Type | Symbol-level | Notes |
|---|---|---|---|---|
| `supporting-docs/METHODOLOGY.md` | project | MODIFY — add Groupings to Part 2 Standard Project Documents table | `supporting-docs/METHODOLOGY.md:110-120` table — new row: `GROUPINGS.md | Named collections of phase IDs sharing a common purpose (user journeys, ambient features, foundational batches, releases) | PM chat | When groupings are created or membership changes`. Possible new Part section if grouping workflow needs orchestration text. | The four streams become five; the existing 4-stream coverage at `:122-138` hygiene rules extends to a 5th stream. |
| `supporting-docs/METHODOLOGY.md` Part 3+ procedures referencing streams | project | MODIFY — extend Procedure 1 phase gate check if groupings affect gate logic; extend Procedure 5 / 6 if grouping creation has a standard workflow | `supporting-docs/METHODOLOGY.md` Part 7 Procedures (line range ~1070-1247 per touch-point archive §1.E) | Architect decides whether groupings affect phase gate, post-session, orphan audit, or resolution procedures. Likely the new "grouping doctor" verb runs alongside `pack tracker doctor` per V11.1 §13 row Y-4. |
| `project-template/CLAUDE.md` § Document locations | project | MODIFY — extend the `docs/project/` row to mention `GROUPINGS.md` (regenerated mirror; per-entry source in subdir) | `project-template/CLAUDE.md:222-226` table (per the system-reminder visible above) — extend the `docs/project/` Contents column: `ARCHITECTURE.md, IMPLEMENTATION-PLAN.md, BACKLOG.md, STATUS.md, CHANGELOG.md, **GROUPINGS.md** (regenerated mirrors for BACKLOG/IMPLEMENTATION-PLAN/CHANGELOG/**GROUPINGS** — per-entry source in subdirs)` | Trinity rule — `AGENTS.md` and `GEMINI.md` get the same edit per `CLAUDE.md` trinity rule. |
| `project-template/AGENTS.md` § Document locations | project | MODIFY — trinity-parallel edit | (same content) | Trinity rule applies. |
| `project-template/GEMINI.md` § Document locations | project | MODIFY — trinity-parallel edit | (same content) | Trinity rule applies. |
| `project-template/CLAUDE.md` § "Per-entry source-of-truth trees" paragraph | project | MODIFY — extend the bulleted enumeration of per-entry trees | currently names backlog / implementation-plan / changelog; extends to add groupings | Same applies to AGENTS.md + GEMINI.md (trinity rule). |
| `project-template/docs/pack/PM-CHAT.md` § File access strategy table | project | MODIFY — add row for `docs/project/groupings/<grouping-slug>.md` (Direct read of single entry) and `docs/project/groupings/_rules.md` (Direct read at session start) | `project-template/docs/pack/PM-CHAT.md:117-131` table — extend with new per-entry-tree rows in the pattern of the existing `docs/project/backlog/<ID>.md, …` row at `:124-125` | Existing table already has per-entry-source rows for backlog / implementation-plan / changelog at `:124-125`; the grouping row joins them. |
| `project-template/docs/pack/PM-CHAT.md` § "Pack agent roster" or new orchestration section | project | MODIFY (CONDITIONAL) — add orchestration text for grouping creation workflow if the architect determines PM Chat orchestrates grouping creation (vs user-direct edit) | open architect decision | If groupings have an automation workflow (auto-include regex per V11.1 §9 hybrid), PM Chat orchestrates it; if they are purely declarative human-authored docs, no PM Chat orchestration text is needed beyond the standard "PM Chat writes; agents do not" rule. |
| `pack-ops/HELP-FRAGMENT-PACK.md` | pack | MODIFY (CONDITIONAL on Q1) — add pack-self grouping verbs to pack-side help fragment | line range ~40-41 (per touch-point archive §1.D) — add `pack tracker groupings <subcommand>` family | Verb dispatcher addition. |
| `pack-ops/HELP-FRAGMENT-TRACKER.md` | pack | MODIFY — add tracker-mode grouping verbs (byte-identity with project-template/docs/pack/HELP-FRAGMENT-TRACKER.md per BD-077 Check 24) | `pack-ops/HELP-FRAGMENT-TRACKER.md:13,26` (per touch-point archive §1.D) — add `pack tracker groupings rebuild` + sibling verbs | Byte-identical mirror at `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` per Check 24. |
| `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` | project | MODIFY — byte-identical mirror of the pack-root copy | same as above | Check 24 enforces byte identity. |
| `project-template/docs/pack/OPTIONAL-FEATURES.md` | project | MODIFY — add Groupings section describing the new feature | description, recommendation signals (?), opt-in path, MIGRATION pointer | Pattern follows existing "Tracker integration (v11)" section per touch-point archive §1.D. |
| `supporting-docs/MIGRATION-v11.0-to-v11.1.md` | project | NEW user-facing migration narrative | per V11.1 §13 row Y-5 | Pattern follows existing `supporting-docs/MIGRATION-v10-to-v11.md` (per `pack-ops/CHANGELOG.md` BD-084 description). |

### §3.H — MODIFIED — validate-pack checks (and NEW checks)

See §10 for the full validator check footprint and fixture-test count. This row is the touch-point inventory entry.

| Path / function | Scope | Type | Streams touched | Notes |
|---|---|---|---|---|
| `scripts/validate-pack.py` Check 29 (`check_tracker_config()`) | pack | MODIFY — extend `_validate_tracker_toml()` to admit and validate the new `[project]` section schema | `scripts/validate-pack.py:2669` and helper `_validate_tracker_toml()` (per touch-point archive §1.I) | New keys: `[project].enabled`, `[project].project_number`, `[project].project_url`, `[project].default_field_map`. |
| `scripts/validate-pack.py` Check 32 (`check_mirror_in_sync()`) | both | MODIFY — extend to validate `docs/project/GROUPINGS.md` mirror is in sync with `docs/project/groupings/` per-entry tree | `scripts/validate-pack.py:3058` | New stream is appended to the loop; the existing 3-stream check at `:3058-3265` adds groupings as a 4th. |
| `scripts/validate-pack.py` Check 33 (`check_toc_in_sync()`) | both | MODIFY — extend to include groupings TOC if `_toc.md` is generated | `scripts/validate-pack.py:3266` | Same loop extension. |
| `scripts/validate-pack.py` Check 34 (`check_cross_reference_integrity()`) | both | MODIFY — extend to validate phase IDs referenced in grouping doc Member-phases lists actually exist in implementation-plan | `scripts/validate-pack.py:3465` | The cross-ref scanner already covers BD-NNN / TD-NNN / phase-N references; extend to validate that a grouping's member list of phase-IDs resolves to existing phases. |
| `scripts/validate-pack.py` NEW Check (`check_grouping_membership_integrity()`) | both | NEW | n/a (new) | Validates: each grouping `_rules.md` declares Kind enum value from the canonical list; each grouping entry has a valid Kind; member-phase list contains only valid phase IDs; no phase ID is double-listed within one grouping. |
| `scripts/validate-pack.py` NEW Check (`check_grouping_per_stream_contract()`) | both | NEW | n/a (new) | Mirrors the existing per-entry checks: filename regex, supporting files admitted, back-pointer line present per `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2.md` §2. |
| `scripts/validate-pack.py` Check 40 (`check_bare_pack_ops_refs()`) | pack | n/a (no change) | n/a | Currently in flight per BD-179; not affected by groupings work. |

### §3.I — MODIFIED — agent files (pack-side + project-side)

| Path | Scope | Type | Symbol-level | Notes |
|---|---|---|---|---|
| `project-template/.claude/agents/coder.md` + `.codex` + `.gemini` mirrors | project | MODIFY (CONDITIONAL) — add `GROUPINGS.md` to the root-md prohibition list if the grouping mirror is PM-only | `project-template/.claude/agents/coder.md:81` (per touch-point archive §1.J) | Extension of existing PM-only file list. |
| `project-template/.claude/agents/auditor.md` + mirrors | project | MODIFY (CONDITIONAL) — add grouping doc as a `## Next steps` cross-reference target if auditor identifies grouping-related issues | `project-template/.claude/agents/auditor.md:42` | Optional. |
| `.claude/agents/pack-architect.md` + Codex/Gemini mirrors | pack | MODIFY (CONDITIONAL on Q1) — add `GROUPINGS.md` to required reading if pack-self has groupings | `.claude/agents/pack-architect.md:27` (per touch-point archive §1.L) | Conditional. |
| `project-template/docs/pack/prompts/architect.md` | project | MODIFY (CONDITIONAL) — add grouping membership as architect input if architect should propose new groupings during architecture work | `project-template/docs/pack/prompts/architect.md:25-35,56` (per touch-point archive §1.K) | Optional — architect work might propose grouping creation as part of phase decomposition. |
| `project-template/docs/pack/prompts/pm-chat.md` Variant `backlog-status-update` | project | MODIFY (CONDITIONAL) — add a Variant `grouping-update` for the PM Chat orchestration of grouping creation / membership change | `project-template/docs/pack/prompts/pm-chat.md:98-178` (per touch-point archive §1.K) | Architect decision: does grouping creation need its own PM Chat prompt variant, or is it handled by the standard `backlog-status-update` variant? |

### §3.J — MODIFIED — skill files (pack-side + project-side)

| Path | Scope | Type | Symbol-level | Notes |
|---|---|---|---|---|
| `project-template/skills/pm-startup/SKILL.md` Step 2 | project | MODIFY — add groupings stream to trinity-resolver framing | `project-template/skills/pm-startup/SKILL.md:69-87` (per touch-point archive §1.N) | Step 2 reads BACKLOG/STATUS/IMPLEMENTATION-PLAN/CHANGELOG today; extend to include GROUPINGS.md (or `docs/project/groupings/_intro.md` for the tree-source view per the per-entry pattern). |
| `project-template/skills/pm-startup/SKILL.md` Step 4 RAG reconciliation | project | MODIFY (CONDITIONAL) — extend RAG manifest reconciliation if groupings are RAG-eligible per V11.1 §14 Q6 | `project-template/skills/pm-startup/SKILL.md:96-169` | V11.1 §14 Q6 leaves Q6 open. The discriminator-column pattern at `project-template/docs/pack/PM-CHAT.md:135-172` would route grouping access-method through `Direct read` (per V11.1 §14 Q6 wording "reading the grouping doc directly is fastest") — meaning no RAG ingestion. If architect decides differently, this Step changes. |
| `project-template/skills/pm-startup/SKILL.md` Step 6 startup report | project | MODIFY (CONDITIONAL) — add `Open groupings: N` to startup summary | `project-template/skills/pm-startup/SKILL.md:191-192` | Pattern matches "Open BACKLOG items: [count]; Last TD number" line at `:191-192`. |
| `project-template/skills/pm-startup/SKILL.md` Step 8 recommendation | project | MODIFY (CONDITIONAL) — add grouping-related signal if architect determines D-19 recommendation needs a grouping-presence signal | `project-template/skills/pm-startup/SKILL.md:211-253` (per touch-point archive §1.N) | Optional — D-19 currently has 7 client signals per `scripts/lib/recommendation.sh:145-175`; adding an 8th signal (grouping_count) is a small extension. |
| Per-CLI mirrors of pm-startup (Claude / Codex / Gemini) | project | MODIFY — byte-equivalent per BD-076 / Check 27 | `project-template/.claude/skills/pm-startup/SKILL.md`, `.codex/skills/pm-startup/SKILL.md`, `.gemini/commands/pm-startup.toml` (per touch-point archive §1.J + §1.N) | Per-CLI parity enforced by Check 27 (`check_pm_startup_per_cli_parity()` at `scripts/validate-pack.py:2314`). |
| `.claude/skills/pack-startup/SKILL.md` (and Codex/Gemini mirrors) | pack | MODIFY (CONDITIONAL on Q1) | analogous extensions for pack-self if pack-self has groupings | Conditional. |
| `project-template/docs/pack/PLATFORM-SKILLS.md` | project | MODIFY (CONDITIONAL) — if grouping work surfaces new skill dimensions (unlikely per V11.1; included for completeness) | n/a | Very unlikely. |

### §3.K — NEW + MODIFIED — test fixtures

See §10 for the full inventory.

| Path | Scope | Type | Notes |
|---|---|---|---|
| `test-fixtures/v11-flat-file/` + `test-fixtures/v11-tracker-on/` | both | n/a (v11.0 fixtures unchanged) | Existing fixtures for v11.0 do not include groupings. |
| `test-fixtures/v11.1-groupings-flat/` (NEW) | both | NEW fixture directory | Greenfield v11.1 client with groupings populated for forward / reverse / round-trip testing. |
| `test-fixtures/v11.1-groupings-tracker-on/` (NEW) | both | NEW fixture directory | v11.1 client in tracker mode with GH Projects mirrored. |
| `scripts/tests/test-tracker-grouping.sh` (NEW) | both | NEW test script | Mirrors pattern of `scripts/tests/tracker-init-test.sh` (per BD-066). Covers `pack tracker groupings init/rebuild/status/doctor/disable`. |
| `scripts/tests/tracker-migrate-roundtrip-test.sh` | both | MODIFY — extend round-trip fixture to include a grouping doc with N>=2 member phases (forward → reverse → forward; diff = 0 whitespace-tolerant) | per BD-068 round-trip property (`pack-ops/BACKLOG.md:147-157`) | The round-trip extension mirrors V3.3 §4.4 BD-068 extension pattern. |
| `test-fixtures/manifest.txt` | both | MODIFY — auto-rebuild via `bash test-fixtures/build.sh --all --clean` per CLAUDE.md "Regenerate test-fixtures/manifest.txt" rule | n/a | Mandatory for any v11-surface commit; covered by the rule already. |

### §3.L — MODIFIED — workflow / CI

| Path | Scope | Type | Notes |
|---|---|---|---|
| `.github/workflows/validate-pack.yml` | pack | MODIFY (CONDITIONAL) — add Check 41+ (the new grouping checks) to the per-check job list | per `scripts/validate-pack.py` `check_ci_workflow_wires_per_check_tests()` Check (line ~5291 per `grep -n "^def check_"`) | The CI workflow enforces per-check test wiring; new checks → new CI rows. |
| RELEASE-GATE doc (if exists post-v11.0) | pack | MODIFY (CONDITIONAL) | extend ship-gate items to include grouping coverage | Pre-v11.0 RELEASE-GATE per BD-115 (per touch-point archive §1.G context). |

---

## §4 — Per-stream contract for a grouping per-entry tree

The architect must specify the following per-stream attributes. Each is currently expressed in the existing per-entry contracts (`project-template/docs/project/{backlog,implementation-plan,changelog}/_rules.md`) — the pattern is established. The values below are extracted directly from V11.1 §10 + §8 + §9; they are facts the architect must reconcile, not options.

### §4.1 — Stream identity (per the V11.1 doc)

| Attribute | Value | Source |
|---|---|---|
| Stream name | `project-groupings` (and conditionally `pack-groupings` per §1.3 Q1) | inferred from `scripts/lib/per-entry/_lib.sh:64` `PE_STREAM_KEYS` naming convention |
| Pack version that mints this contract | v11.1 (per V11.1 §6) | V11.1 §6 |
| Directory | `docs/project/groupings/` (project); `groupings/` (pack-self, CONDITIONAL) | V11.1 §10 + §12 |

### §4.2 — Filename convention

Per V11.1 §10's example "one file per grouping," the filename is a human-readable slug (e.g., `auth-and-identity.md`, `foundational-platform.md`, `release-v2.0.md`). No `^TD-\d+\.md$` style numeric prefix (groupings have no equivalent of TD-NNN ID).

| Candidate regex | Pros | Cons |
|---|---|---|
| `^[a-z][a-z0-9-]*\.md$` | matches the V11.1 example slugs | requires architect to forbid `_` (which collides with `_rules.md`-style supporting files) |
| `^[a-z][a-z0-9_-]*\.md$` | broader | underscore + supporting-file collision risk |

Architect chooses; the simplest collision-safe form is the first (lowercase + hyphens). The `_rules.md` / `_intro.md` / `_format.md` / `_toc.md` supporting files all start with `_` which the first regex excludes.

### §4.3 — Entry contract (the grouping doc shape)

Per V11.1 §10's example, each grouping file has:

- H1 heading: `# Grouping: <Title> (<kind>)`
- `**Kind:**` field — enumerated (one of: `user-journey`, `ambient-feature`, `foundational-batch`, `refactor-cluster`, `release-package`; or extended values per V11.1 §14 Q2)
- `**Description:**` — free prose
- `**Member phases (by ID):**` — bulleted list of phase IDs (`phase-N` form; possibly `phase-N.M` after BD-185 lands — see §6 below)
- `**Source PRD section / journeys doc:**` — optional cross-reference
- (CONDITIONAL per V11.1 §9 hybrid section) `**Auto-include:**` regex pattern for phase auto-inclusion

The first line is an HTML-comment back-pointer ABOVE the H1 heading per `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2.md` §2 (the existing convention for per-entry trees per `project-template/docs/project/backlog/_rules.md:18-26`).

### §4.4 — Lifecycle states admitted

Per V11.1 §10 + §15 working assumptions, a grouping has no formal lifecycle states (no `Open` / `Resolved` like backlog entries). The doc is either present (the grouping exists) or absent (the grouping is removed). Architect decides whether to introduce:

- `active` / `archived` annotation (parallel to backlog `Open` / `Resolved`), or
- presence/absence-only (delete the file to dissolve a grouping)

V11.1 §10 doesn't pre-specify; this is an architect-resolvable surface.

### §4.5 — Supporting files

Per the pattern at `project-template/docs/project/backlog/_rules.md:38-46` ("Supporting files" list of `_rules.md` / `_intro.md` / `_toc.md`):

- `_rules.md` (mandatory — stream contract)
- `_intro.md` (mandatory — mirror header)
- `_toc.md` (mandatory — auto-generated by `scripts/lib/per-entry/toc-regenerate.sh`)
- `_format.md` (OPTIONAL per architect decision; precedent is `project-template/docs/project/changelog/_format.md`)

The per-entry helpers read this list at runtime per `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` §7.5. Files not matching the entry regex AND not in this list are SKIP.

### §4.6 — Write authority

Per the existing pattern at all three v11.0 stream contracts (`_rules.md` final section):

- Writes are PM-Chat authority.
- Read more at `docs/pack/PM-CHAT.md` + `docs/pack/METHODOLOGY.md` (specific Part TBD by architect — likely a new Part or extension to Part 4 IMPLEMENTATION-PLAN guidance).
- The monolithic `docs/project/GROUPINGS.md` is a regenerated mirror — never source of truth; hand-edits are silently overwritten on the next regeneration.

---

## §5 — TrackerProvider extension surface (BD-060 op-level additions)

This section enumerates the API-shape extension required at the BD-060 abstraction (`scripts/lib/tracker-provider.sh`) to support groupings as a first-class tracker entity under Constraint 2 (tracker portability). Op signatures are at type-shape level — the architect refines argument lists.

### §5.1 — Current state of TrackerProvider abstraction

Per `scripts/lib/tracker-provider.sh:1-23`, the surface today is **18 ops + raw + capabilities** = 19 functions:

1. `provider_list` (list issues with filter + pagination)
2. `provider_get` (single issue fetch)
3. `provider_search` (search-by-query)
4. `provider_create`
5. `provider_update`
6. `provider_close`
7. `provider_reopen`
8. `provider_comment`
9. `provider_set_labels`
10. `provider_set_assignee`
11. `provider_set_milestone`
12. `provider_link`
13. `provider_unlink`
14. `provider_sub_issue_create`
15. `provider_sub_issue_list`
16. `provider_sub_issue_unlink`
17. `provider_capabilities`
18. `provider_raw` (escape hatch)
19. (the `link` / `sub_issue_*` are conditional per backend capability flags; the other 16 are required)

GH backend implementation at `scripts/lib/tracker-provider-gh.sh:188-785` — one `tracker_provider_gh_<op>` function per op.

### §5.2 — Proposed extension surface (architect refines)

To support GH Projects v2 + Linear Projects + Jira Epics + Redmine Versions + GitLab Epics + Forgejo Milestones, the abstraction needs ops that handle the "named collection of issues with optional metadata fields" concept. The cleanest factoring is:

| Op | Purpose | Required by backend if backend has a grouping primitive | Capability flag |
|---|---|---|---|
| `provider_grouping_create` | Create a new grouping (Project in GH, Project in Linear, Epic in Jira, Version in Redmine, etc.) | yes (else returns `unsupported` typed error) | `grouping.supported = true/false` |
| `provider_grouping_update` | Update grouping metadata (title, description, dates) | yes | (subsumed by above) |
| `provider_grouping_delete` | Delete a grouping (no items deleted — only the container) | yes (else delete is best-effort) | (subsumed) |
| `provider_grouping_get` | Fetch a single grouping by ID | yes | (subsumed) |
| `provider_grouping_list` | List all groupings for the configured backend project | yes | (subsumed) |
| `provider_grouping_item_add` | Add an issue/PR to a grouping | yes | (subsumed) |
| `provider_grouping_item_remove` | Remove an issue/PR from a grouping (issue itself unchanged) | yes | (subsumed) |
| `provider_grouping_item_list` | List items in a grouping (issue/PR IDs + any per-grouping field values) | yes | (subsumed) |
| `provider_grouping_field_create` | Create a custom field at the grouping level (GH custom fields; Linear custom fields) | OPTIONAL (only backends with custom fields) | `grouping.custom_fields = true/false` |
| `provider_grouping_field_value_set` | Set per-item field value within a grouping | OPTIONAL | (subsumed by `grouping.custom_fields`) |
| `provider_grouping_iteration_create` | Create an iteration field option (GH Iteration; Linear Cycle; Jira Sprint; GitLab Iteration) | OPTIONAL | `grouping.iterations = true/false` |
| `provider_grouping_iteration_set` | Set the iteration value on an item | OPTIONAL | (subsumed) |

**Op-count delta:** 8-12 new ops, depending on architect's factoring (some backends have iteration as a sub-feature of grouping; others treat it as a separate primitive). The architect must decide whether iteration is a separate op family or a sub-feature of `provider_grouping_*`.

### §5.3 — Per-backend implementation requirements

| Backend | Native primitive maps to | Notes |
|---|---|---|
| GH | Projects v2 (GraphQL only — REST is for retired Classic) | All ops via GraphQL. Existing `_gh_run` helper at `tracker-provider-gh.sh:115` is REST-focused; a `_gh_run_graphql` variant is required. |
| Linear | Project (GraphQL) | Linear is GraphQL-only; existing pattern transfers. |
| Jira | Epic + Sprint + Component | Three different primitives map to three different ops. `provider_grouping_create` with `kind = "release-package"` maps to Component or Version; with `kind = "ambient-feature"` maps to Epic. Architect decides the routing table. |
| Redmine | Version + Issue Category | Version for releases; Category for thematic groupings. |
| GitLab | Epic + Milestone | Epic for groupings (Ultimate tier; deprecated API); Milestone for release-package. |
| Forgejo / Gitea | Milestone only | No GH-Projects-equivalent; the grouping doc would have no tracker projection on Forgejo unless emulated via labels. |

### §5.4 — Capability flag additions

Per BD-060's capability-flag model at `scripts/lib/tracker-provider-gh.sh:728-784`, the new capability set:

```
grouping.supported     = true | false
grouping.custom_fields = true | false  (CONDITIONAL on supported)
grouping.iterations    = true | false  (CONDITIONAL on supported)
grouping.multi_per_item = true | false  (the "one issue in multiple groupings" property V11.1 §8 dedup relies on)
grouping.field_limit   = <integer> (per V11.1-doc cited GH limit of 50; -1 for unlimited)
```

The `multi_per_item` flag is **load-bearing for V11.1 §8 dedup behavior**: when false, the pack must either degrade (no multi-grouping membership for that backend) or emulate via label-tagging.

### §5.5 — `raw()` escape hatch usage

Backends without native primitives can use `provider_raw()` to issue backend-specific calls. This is the existing escape hatch per `scripts/lib/tracker-provider.sh:5,142`. The grouping integration on Forgejo (which has no GH-Projects equivalent) would likely use `raw()` for any custom-emulation calls.

### §5.6 — Typed-error contract (BD-070)

Per BD-070's 10 typed codes (`pack-ops/BACKLOG.md:176-186`), new error conditions:

- `grouping_not_supported` — backend has no grouping primitive (e.g., Forgejo). Surfaces typed error per V1 §2.5; next-step verb `pack tracker doctor`.
- `grouping_field_limit_exceeded` — adding a custom field would exceed `grouping.field_limit` (GH Projects v2: 50 per project). Surfaces typed error with diagnostic.

---

## §6 — Integration touch points with existing v11 design

Each row identifies an existing v11 design touch point + how groupings would interact + whether the integration is a **minor adjustment** (acceptable by default per Constraint 4) or a **major revision** (must surface for user discussion before any architect picks up).

### §6.A — Phases (IMPLEMENTATION-PLAN.md + per-entry tree at `docs/project/implementation-plan/`)

**Interaction:** Groupings **reference** phases by ID. Phases do NOT carry grouping metadata (per V11.1 §9 explicit-membership decision + §12).

**Integration classification: MINOR.** Phases stay agnostic — no new field, no new tag, no schema change to `phase-N.md` entries. The grouping doc points at phases; phases don't point back. This is the design choice V11.1 §12 explicitly anchors to "v11.0 impact: zero."

**Pack-side facts:**
- Phase entity schema at `ARCHITECTURE-V3.3-DELTA.md` §6.3 (state taxonomy table) — unchanged.
- Phase per-entry contract at `project-template/docs/project/implementation-plan/_rules.md:13-29` — unchanged.
- Phase parser at `scripts/lib/per-entry/_lib.sh:93-104` (`project-implementation-plan` case) — unchanged.

### §6.B — Tasks (phase-N.M entries inline in phase-N.md per BD-167)

**Interaction:** Groupings reference phases (not tasks). Tasks are not directly groupable per V11.1 §7 ("Phase = collection of phases is the right granularity" — phase tasks are below the grouping granularity).

**Integration classification: MINOR.** Tasks unaffected.

**Pack-side facts:**
- Tasks live inline in `phase-N.md` per BD-167 spec at `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md` §6.4 (per `project-template/docs/project/implementation-plan/_rules.md:15-20`).
- Task identifier `phase-N.M` per ARCHITECTURE-V3.3-DELTA.md §6.4.

### §6.C — Backlog items (BD-NNN at pack-self; TD-NNN at project)

**Interaction:** Backlog items do NOT participate in groupings (V11.1 §8: "A grouping is a named collection of phase IDs"). The grouping primitive scope is phases-only.

**Integration classification: MINOR.** Backlog items unaffected.

**Open question for architect:** Should TD-NNN promotion path 1 (per V3.3 §3 — TD becomes new phase epic) trigger any grouping membership check (e.g., "the new phase joins the current promoted-from TD's containing grouping if there is one")? V11.1 doc does not address this; could be deferred to v11.1 planner.

### §6.D — STATUS.md dashboard

**Interaction:** V11.1 §4 explicitly identifies STATUS.md as the "one real overlap zone" — GH Projects Board view does much of what STATUS.md does (current phase, phase table, throughput). In tracker mode, STATUS.md becomes somewhat redundant if a Project is also in use.

**Integration classification: MAJOR REVISION FLAG.** The V11.1 doc declines to specify how STATUS.md changes when groupings + Projects exist. Possibilities:
- (a) STATUS.md is unchanged; groupings + Projects are an optional view layer.
- (b) STATUS.md gains a "Grouping" column referencing each phase's groupings.
- (c) STATUS.md is reduced or deprecated when tracker + groupings + Projects are all on.

This is OUT OF SCOPE for the researcher to design. The architect must propose; the user must approve.

**Pack-side facts STATUS.md must be aware of:**
- STATUS.md is a dashboard, not a stream (per touch-point archive §3 STATUS verification).
- STATUS.md role is governed by `supporting-docs/METHODOLOGY.md:116,127,1321,1429` + `project-template/docs/pack/PM-CHAT.md:204-220`.
- STATUS.md "never-source-of-truth disclaimer" rule at `project-template/docs/pack/PM-CHAT.md:212-220` — disclaimer points to per-entry tree as canonical source. If groupings overlap STATUS dashboard role, the disclaimer text needs revision.
- BD-185 SC5 (per `pack-ops/BACKLOG.md:1774`) explicitly states "STATUS.md remains a dashboard. Its role does not expand to ordering SSOT in either mode." Groupings should respect this same invariant.

### §6.E — METHODOLOGY workflows (Workflows 1-7)

**Interaction:** New workflow needed for grouping creation + membership change. Existing workflows largely unaffected because phases are unchanged.

**Integration classification: MINOR.** Existing workflows 1-7 (per touch-point archive §1.E) operate on backlog / changelog / implementation-plan / status; adding GROUPINGS.md as a 5th surface adds workflow steps but doesn't change existing flows.

**Open architect work:** Decide whether grouping creation is:
- (a) a standalone workflow (Workflow 8 — Grouping creation),
- (b) a sub-step of Workflow 1 (Starting a new project) — declare initial groupings during architecture phase,
- (c) PM-Chat-direct edit per `project-template/docs/pack/PM-CHAT.md:201-203` "Source file edits" rule (BACKLOG.md / STATUS.md / GROUPINGS.md may be PM-Chat-direct after explicit user approval).

### §6.F — Agent prompts (architect / planner / coder / reviewer / tester / docs-researcher / auditor under `project-template/docs/pack/prompts/`)

**Interaction:** Architect MAY propose grouping creation as part of phase decomposition. Coder / reviewer / tester likely have no direct involvement (groupings are PM-Chat / architect concerns).

**Integration classification: MINOR.** Prompt files at `project-template/docs/pack/prompts/{architect,coder,reviewer,tester,…}.md` need at most a single new line in `architect.md` referencing the grouping doc as an input/output surface.

### §6.G — PM-CHAT orchestration rules

**Interaction:** PM-CHAT.md gains grouping orchestration entries: when does PM Chat invoke the grouping creation workflow; what's the user-approval path; how does PM Chat update grouping membership when phases are added/removed.

**Integration classification: MINOR.** New rules slot into existing PM-CHAT structure (Behavioral rules + File access strategy + Permission profiles sections).

### §6.H — validate-pack checks

See §3.H + §10 for the new + extended checks.

**Integration classification: MINOR.** All extensions are additive to existing checks; the per-entry mirror-in-sync / TOC / cross-ref checks loop over streams, so adding `project-groupings` to the stream list is a one-tuple addition.

### §6.I — Migrator stages

**Interaction:** v10→v11 migrator unchanged (v10 has no groupings). v11.0→v11.1 migrator (NEW) installs the groupings tree skeleton at existing client projects.

**Integration classification: MINOR.** Per CLAUDE.md:35-40, the BD-119 migrator framework supports this via a new adapter (`scripts/migrate-v11.0-to-v11.1.sh`).

### §6.J — init-project.sh stages

**Interaction:** Stage S11 (v11 client artifacts install per `scripts/init-project.sh:803-1031`) extends to install the groupings tree skeleton.

**Integration classification: MINOR.** Pattern matches the existing 3-stream install at `:902-1031`.

### §6.K — Per-entry helpers (`scripts/lib/per-entry/`)

**Interaction:** The 4-file helper set (`_lib.sh`, `decompose.sh`, `mirror-generate.sh`, `toc-regenerate.sh`) extends via the stream tuple addition in `_lib.sh:64-122`. Mirror generator + TOC regenerator + decomposer are stream-agnostic — they consume the tuple.

**Integration classification: MINOR.** A single new stream tuple in `PE_STREAM_KEYS` + a single new case in `pe__stream_attr()` is the entire extension. The downstream generators are stream-agnostic.

### §6.L — Tracker mode (current v11.0 design at `ARCHITECTURE-V3.3-DELTA.md`)

**Interaction:** V3.3-DELTA's entity model (L1 = phase epic + TD + BD; L2 = phase task; L3 reserved) does NOT mention groupings. Groupings are a NEW concept at a different conceptual layer:
- L1-L3 hierarchy is about **issues** (work items).
- Groupings are about **collections of issues** (view layer per V11.1 §2, §4).

**Integration classification: MINOR for the hierarchy** (groupings don't conflict — they sit above L1 as a view-layer overlay), but **MAJOR FLAG for sub-issue semantics composition** — see §7 break-point B3 below.

### §6.M — BD-185 (phase parts + tracker-mode execution ordering)

**Interaction:** BD-185 (per `pack-ops/BACKLOG.md:1744-1789`) introduces phase parts (Phase N → Part 1..p, each part containing tasks) and a tracker-mode execution-ordering mechanism. Groupings reference phases by ID; BD-185 mutates the phase representation. The architect must reconcile:
- Does a grouping member list reference `phase-N` only, or `phase-N.Part-M` once BD-185 ships?
- Does the execution-order mechanism BD-185 introduces interact with grouping membership (e.g., "all phases in grouping X must execute in declared grouping order")? V11.1 §8 explicitly rejects this — execution order is the Blockers/Unblocks DAG, not grouping order. But if BD-185's ordering mechanism shifts the SSOT, the rule needs explicit re-affirmation.

**Integration classification: MAJOR REVISION FLAG.** BD-185 has not yet been architected at this writing (per `pack-ops/BACKLOG.md:1747` blocker on Batch 19c). The grouping work must be re-checked AFTER BD-185 lands. The simplest reconciliation is to defer groupings to AFTER BD-185 (which is already the V11.1 timeline per the v11.0 → v11.1 sequence), but if BD-185 changes the phase ID scheme, the grouping doc Member-phases grammar must be updated.

---

## §7 — Compatibility break-points

Explicit list of places where existing v11 design assumptions would break if groupings landed without revision. These are NOT for the researcher to design solutions; they are surface-the-issue items requiring user + architect discussion BEFORE any v11.1 work.

### §7.B1 — STATUS.md role overlap with GH Projects Board view

**Break-point:** V11.1 §4 identifies STATUS.md as the one real overlap zone with GH Projects. In tracker mode, the Project Board view does much of what STATUS.md does. If groupings land + Projects are created, the user may have:
- STATUS.md (pack-managed, regenerated from per-entry tree)
- GH Project Board (user-managed, optional, overlay view)
- Both showing similar information with potential divergence.

**Existing rule that would break (or need explicit re-affirmation):** `project-template/docs/pack/PM-CHAT.md:212-220` STATUS.md disclaimer rule says STATUS is a working snapshot, never source of truth; per-entry tree wins. If GH Projects becomes a parallel view, the disclaimer must address which view takes priority and whether GH Project field edits flow back into the per-entry tree (V11.1 §14 Q4 explicitly leaves this open).

**Architect decision needed:** Disclaimer wording extension OR explicit "tracker mode: GH Project Board supersedes STATUS.md; flat-file mode: STATUS.md is canonical" rule OR another reconciliation.

### §7.B2 — Multi-grouping per phase + non-GH tracker backends

**Break-point:** V11.1 §8 dedup section relies on GH Projects' multi-Project-per-issue semantics ("Closing the issue once propagates to all Projects"). This semantics is **GH and Linear only** per §2.7 cross-tracker matrix.

**Existing constraint broken on Jira / Redmine / Forgejo / GitLab Epics:** A phase issue can belong to one Jira Epic (parentage is exclusive) — not multiple. Adding the same issue to a second epic is not a Jira primitive. The V11.1 §8 dedup mechanism does not apply.

**Architect decision needed:** Either (a) restrict the multi-grouping feature to GH + Linear (degrade on other backends), or (b) emulate multi-grouping via labels on lower-capability backends (with the round-trip + sidecar surface that implies per BD-067 reverse migration), or (c) declare multi-grouping a GH-conditional feature and document it as such.

### §7.B3 — Phase epic ↔ grouping confusion in tracker mode

**Break-point:** In V3.3-DELTA tracker model, a phase epic is an L1 issue. In V11.1, a grouping is a Project (or backend-equivalent — see §2). Both are "collections of work" at the tracker level. If both ship, the user may conflate them, or the pack may misroute (e.g., creating a Project when the user meant a phase epic, or vice versa).

**Architect decision needed:** Clear conceptual distinction. The V11.1 doc §2 already explains it ("Projects don't replace Issues; they organize them"), but the pack's PM-CHAT.md + METHODOLOGY.md need explicit guidance: when does the user create a phase (issue) vs a grouping (Project / Epic / Version)? The default-Path-1 routing for TD promotion (per V3.3 §3.1) creates a phase epic; groupings are a separate creation path with no equivalent verb chain at v11.0.

### §7.B4 — Sub-issue depth ceiling (3-level cap from V3.3 §2.3)

**Break-point:** V3.3 §2.3 commits to a 3-level cap (L1 + L2 + L3 reserved) to maintain cross-tracker portability. Groupings via GH Projects do NOT consume a level (Projects are an overlay, not a parent issue) — so the cap is unaffected for GH. But on Jira (where Epic IS a parent issue), grouping-as-epic consumes L1, leaving only L0 (Story/Task/Bug) below it.

**Existing constraint that needs re-affirmation:** V3.3 §2.3's 3-level cap. If groupings map to Jira Epics, the cap on Jira is consumed (phase epic = Jira Epic = grouping?), which forces phase epics and groupings to be at the SAME level on Jira — a conflict the architect must resolve.

**Architect decision needed:** Either (a) on Jira, phase epics and groupings collapse to the same L1 entity with disambiguation by label (`phase-epic` vs `grouping-epic`), or (b) groupings on Jira map to Components / Versions instead of Epics, or (c) groupings on Jira are unsupported.

### §7.B5 — Round-trip property (BD-068)

**Break-point:** BD-068 (`pack-ops/BACKLOG.md:147-157`) guarantees forward → reverse → forward is a no-op for the v10-grammar entry set. V11.1 doc §14 Q4 explicitly raises whether per-Project field edits (custom fields the user sets in the GH UI) round-trip back to the per-entry tree.

**Existing contract:** "GH issue is source of truth, mirror file is local cache" (per V11.1 §14 Q4). Per-Project fields sit ABOVE the issue; they don't flow into the issue body. If the user adds an "Estimate" custom field in a Project and sets it for an item, that data lives only in the Project — not in the issue body the pack's reverse migration reads.

**Architect decision needed:** Either (a) per-Project fields do NOT round-trip (data is tracker-mode-only; reverse migration drops them), or (b) per-Project fields are captured in the sidecar (per BD-067 sidecar shape at `pack-ops/BACKLOG.md:133-143`) so they survive reverse for re-forward, or (c) only a documented subset of Project field types round-trip (e.g., Iteration → IMPLEMENTATION-PLAN execution notes; Status → already in issue body).

### §7.B6 — RAG ingestion manifest discriminator

**Break-point:** V11.1 §14 Q6 raises whether groupings should be in the RAG manifest. The existing discriminator pattern at `project-template/docs/pack/PM-CHAT.md:135-172` routes by access-method column; `Direct read` rows skip RAG.

**Existing rule:** RAG manifest is the union of `docs/pack/METHODOLOGY.md` + every `## Additional project documents` row whose access-method starts with `RAG` (per PM-CHAT.md:172).

**Architect decision needed:** Default access-method for groupings rows. Likely `Direct read` per V11.1 §14 Q6 wording ("reading the grouping doc directly is fastest"), in which case RAG is unaffected. But if a project has 50+ groupings, direct-read becomes expensive; the architect may want RAG-eligible groupings via the `## Additional project documents` extension pattern.

### §7.B7 — Kind enumeration extensibility

**Break-point:** V11.1 §10 declares Kind enumerated (default: 5 values); §14 Q2 leaves user-extensibility open.

**Existing pattern:** Pack-shipped enums are validated by validate-pack checks (e.g., `wi-status` enum at `.github/ISSUE_TEMPLATE/work-item.yml:48-57` enforced by Check 19). If Kind is fixed-enum, a new validate-pack check enforces it. If user-extensible, the validation must distinguish pack-shipped Kinds (always valid) from user-added Kinds (must follow a contract — naming convention? sidecar registry? `_rules.md` enum extension?).

**Architect decision needed:** Fixed-enum (simpler, mirrors `wi-status`) or extensible-enum (more flexible, requires extension contract). If extensible, what's the validation surface — naming pattern, registry file, sidecar declaration?

---

## §8 — Immutability invariants and round-trip carriers

Per Constraint 3 (reversibility): everything that lives in the tracker must round-trip to flat-file. This section enumerates what data must round-trip without loss, what naming/numbering rules apply, and where invariants overlap with existing v11 rules (especially BD-185 parts/ordering).

### §8.1 — Naming / identifier invariants

| Invariant | Source | Applies to grouping how |
|---|---|---|
| INV-1 — Phase number is immutable | METHODOLOGY:332-337 + BD-185 SC3 (`pack-ops/BACKLOG.md:1772`) | Grouping member-phase list cites `phase-N` IDs; renumbering would invalidate grouping membership. Architect must preserve this. |
| INV-2 — Task ID `phase-N.M` is immutable | ARCHITECTURE-V3.3-DELTA.md §6.4 + BD-185 SC3 | Groupings reference phases (not tasks per V11.1 §7), so task ID immutability is not directly groupings-load-bearing — but if architect admits task-level groupings, the invariant applies. |
| INV-3 — TD-NNN identifier is immutable across promotion (per V3.3 §3) | `pack-ops/BACKLOG.md:894-925` + V3.3 §3 | Groupings don't reference TDs per V11.1 §8 — but if architect admits cross-namespace groupings, the invariant applies. |
| INV-4 — Tracker entity ID (e.g., GH Issue number) is inherently immutable | BD-060 + V3.3 §6.4 | A grouping references issues via tracker IDs; sync helper must use the tracker ID as the stable cross-link key. |
| INV-5 — Grouping name (slug) is immutable for the grouping's lifetime | NEW (proposed; architect decides) | Rename = new grouping + delete old. Renaming would invalidate any external doc that referenced the grouping by name. |
| INV-6 — Grouping `Kind` is mutable (a grouping can be re-classified from `user-journey` to `release-package` if priorities shift) | inferred from V11.1 §10 (Kind is declarative; doc is the source of truth) | Forward + reverse sync must reconcile Kind changes without losing existing membership. |

### §8.2 — Round-trip carriers

Data the round-trip must preserve byte-equivalent on tracker side and whitespace-tolerant on flat-file side:

| Data | Forward carrier (flat → tracker) | Reverse carrier (tracker → flat) | Round-trip safety mechanism |
|---|---|---|---|
| Grouping name (slug) | Project title (GH) / Project name (Linear) / Epic name (Jira) | Project name → file basename slug | Slug = lowercase basename without `.md`; matches `^[a-z][a-z0-9-]*$` |
| Grouping Kind | Project description prefix (GH) OR custom field (Linear) OR Epic label (Jira) | Parse from same | Architect picks the canonical carrier per backend |
| Grouping description | Project description body | Project description → `**Description:**` field | Plain text round-trip |
| Member-phase list | `provider_grouping_item_add` calls for each member | `provider_grouping_item_list` returns list; emitter writes `**Member phases (by ID):**` bullets | Ordered list; order preserved via tracker item order |
| PRD reference (optional) | Project description footer (GH) OR custom field | Same | Free-text round-trip |
| Auto-include regex (optional per V11.1 §9 hybrid) | Sidecar field (no native tracker carrier) | Sidecar read → re-emit in `_rules.md` or grouping doc | Sidecar-only (analogous to BD-067 sidecar's `extra_fields` shape at `pack-ops/BACKLOG.md:133-143`) |

### §8.3 — Sidecar shape (extends BD-067 sidecar)

Per V3.3-DELTA §4.3 + BD-067 sidecar (`scripts/lib/tracker-sidecar.sh:1-30` per touch-point archive §1.G):

| Field | Per-grouping | Notes |
|---|---|---|
| `template_version` | yes | e.g., `grouping-v11.1` per D-18 dual-carrier pattern |
| `extra_fields` | yes | per-grouping arbitrary tracker-only fields (e.g., GH Project custom fields the user added that don't map to grouping doc shape) |
| `kind_carrier_method` | yes | string: `"label"` / `"description-prefix"` / `"custom-field"` per backend |
| `auto_include_pattern` | OPTIONAL | per V11.1 §9 hybrid extension |
| `multi_per_item_emulation` | OPTIONAL | per §7.B2; how multi-grouping is emulated on Jira/Forgejo |

### §8.4 — Overlap with BD-185 parts/ordering invariants

BD-185 introduces two new invariants the grouping work MUST respect:

| BD-185 invariant | Source | Grouping interaction |
|---|---|---|
| BD-185 SC3 — Phase numbers and task IDs (N.M) are never renumbered | `pack-ops/BACKLOG.md:1772` | Grouping member-phase IDs are stable across BD-185's Part introduction (whole-number phases remain whole-number; Part suffixes are added without changing the N). |
| BD-185 SC5 — STATUS.md remains a dashboard; its role does not expand to ordering SSOT | `pack-ops/BACKLOG.md:1774` | Mirror invariant for groupings: GROUPINGS.md (mirror) does NOT become ordering SSOT. The grouping doc is membership SSOT; execution order remains the Blockers/Unblocks DAG per V11.1 §8. |

### §8.5 — Cross-reference grammar extension

Existing v10 grammar (per ARCHITECTURE-V3.3-DELTA.md §5.3) admits `phase-N`, `phase-N.M`, `TD-NNN`, `BD-NNN` in `Blockers:` / `Unblocks:` / phase task `Dependencies:` bullets.

Grouping work adds a new cross-reference target: grouping slug names. The grammar would extend to admit `grouping:<slug>` references. Question: where? Likely the optional `**Source PRD section / journeys doc:**` field per V11.1 §10 — but PRD references are free-text per V11.1 §11. The architect decides if there's a need for grouping-to-grouping or backlog-to-grouping cross-references; if so, the grammar admits a new ID form.

---

## §9 — Bi-directional sync touch points

Per Constraint 3 + V11.1 §14 Q4, every forward + reverse operation must preserve data byte-equivalent on tracker side and whitespace-tolerant on flat-file side. This section enumerates the operations and the data that flows in each direction.

### §9.1 — Forward operations (flat-file → tracker)

| F-Op | Trigger | What gets sent to tracker | Provider ops invoked |
|---|---|---|---|
| F1 | `pack tracker init` (initial opt-in, extended per V11.1 §13 row Y-3) | All grouping docs → Projects (or backend-equivalent); membership populated per `provider_grouping_item_add` | `provider_grouping_create`, `provider_grouping_item_add` (per member) |
| F2 | `pack tracker groupings rebuild` (per V11.1 §13 row Y-4) | Re-sync membership: add new members; remove dropped members | `provider_grouping_item_add`, `provider_grouping_item_remove`, `provider_grouping_item_list` (diff computation) |
| F3 | Forward migration on a grouping doc edit (mid-cycle) | Single grouping refresh after `_rules.md` or doc-body change | Subset of F2 ops, scoped to one grouping |
| F4 | `pack tracker init` re-run (idempotent — currently per BD-066) | No-op when grouping + members already correct; updates Kind or description if they changed | `provider_grouping_get` + selective `provider_grouping_update` |

### §9.2 — Reverse operations (tracker → flat-file)

| R-Op | Trigger | What gets pulled from tracker | Provider ops invoked |
|---|---|---|---|
| R1 | `pack tracker disable` (per BD-067 — runs full reverse migration) | All Projects → grouping doc tree; reconstruct member-phase lists from `provider_grouping_item_list` | `provider_grouping_list`, `provider_grouping_get`, `provider_grouping_item_list` |
| R2 | `pack tracker doctor` (per BD-067) | Read-only check; reports drift | `provider_grouping_list`, `provider_grouping_item_list` (no writes) |
| R3 | Reverse pull on a single grouping (NEW verb? `pack tracker groupings pull --name=<slug>` — architect decides) | Single grouping → single grouping doc refresh | `provider_grouping_get`, `provider_grouping_item_list` |
| R4 | Sidecar population on reverse | Per-grouping `extra_fields` (custom fields the user added in Project UI that don't map to grouping doc shape) | `provider_grouping_field_list` (NEW op? — architect decides) |

### §9.3 — What gets lost (and why)

Per V11.1 §14 Q4 + the round-trip carrier table in §8.2 above:

| Data | Lossy in which direction | Why | Mitigation |
|---|---|---|---|
| Custom field values per-item set in GH Project UI | Reverse (tracker → flat) — they don't map into grouping doc shape | Grouping doc has Member-phase list only; no per-member field shape | Sidecar capture per §8.3 row `extra_fields`. Re-forward replays from sidecar. |
| Project automations (auto-add by criteria; auto-set Status) | Reverse — automations are tracker-side configuration, not data | Pack does not manage Project automations | Out of scope per V11.1 §5 Shape 1 (lightweight). If architect later expands to Shape 2, sidecar must capture automations as YAML. |
| Project Insights / charts | Reverse — Insights are computed views, not data | View layer, not state | Always lossy; rebuilt on tracker side from current data. |
| Project Drafts (items that haven't been promoted to issues) | Reverse — Drafts are project-local items per V11.1 §2 | Pack's model is issue-based; Drafts have no flat-file representation | Sidecar capture (analogous to BD-067 reactions/attachments deferral per `pack-ops/BACKLOG.md:143`). |
| Per-Project Status field value (when user uses non-pack-default Status enum) | Reverse — pack reads default `Status:` field; user-defined Status fields are tracker-side | Pack's Status taxonomy is per V3.3 §6.3 (9 values); user-extended enum exceeds the model | Architect decides: drop, sidecar capture, or pull into per-grouping extension shape |
| Cross-Project field divergence (one issue in two Projects with different field values per Project) | Reverse — pack can only emit one value per field per issue per flat-file representation | Flat-file is single-valued; tracker can be multi-valued | Architect decides: pick one (which?), capture both in sidecar, or constrain forward to disallow divergence |

### §9.4 — Two-pass sync pattern (extends V3.3 §5.7)

Per V3.3 §5.7's two-pass approach (create entities first; create links second), the grouping sync should follow a parallel two-pass:

1. **Pass 1: Create groupings.** For each grouping doc, call `provider_grouping_create`.
2. **Pass 2: Populate membership.** For each grouping, for each member phase ID, resolve phase-ID → tracker ID via mapping file, then `provider_grouping_item_add`.

This avoids the bootstrap problem (a grouping can't reference an issue that doesn't exist yet); both passes are within the same orchestration run.

### §9.5 — Checkpoint / resumability (extends BD-065 checkpoint at `pack-ops/BACKLOG.md:110-116`)

V11.1 §14 Q3 raises Project-creation API costs. The existing checkpoint pattern at `.pack-tracker/forward.checkpoint.json` (per BD-065) supports resume after partial failure. Grouping sync extends this:

- Add checkpoint cadence after each `provider_grouping_create` (cheaper than issue creation).
- Add checkpoint cadence every N `provider_grouping_item_add` calls (per V1 §6.4 every 25 issues pattern; architect picks N).

### §9.6 — Auth + capability re-probe (extends BD-067 doctor at `pack-ops/BACKLOG.md:133-143`)

`pack tracker doctor` extends to re-probe `grouping.supported` capability per `provider_capabilities()` call. If a backend gains grouping support mid-project (e.g., Forgejo adds Projects), doctor surfaces the new capability + offers re-init. Per BD-067 resolved note, capability re-probing is currently deferred — grouping work could close this deferral or stay within it.

---

## §10 — Validator check footprint and fixture-test inventory

### §10.1 — Existing checks affected (extend without breaking)

Per `scripts/validate-pack.py` (function inventory via `grep -n "^def check_"`):

| Check | Function | Current scope | Grouping extension |
|---|---|---|---|
| Check 29 | `check_tracker_config()` at `:2669` | tracker.toml schema validation | Extend `_validate_tracker_toml()` to admit `[project]` section + sub-keys per §3.D |
| Check 32 | `check_mirror_in_sync()` at `:3058` | per-entry tree ↔ mirror sync for the 3 v11.0 streams | Add `project-groupings` stream to the loop |
| Check 33 | `check_toc_in_sync()` at `:3266` | TOC ↔ tree sync for the 3 v11.0 streams | Add `project-groupings` stream to the loop |
| Check 34 | `check_cross_reference_integrity()` at `:3465` | BD-NNN / TD-NNN / phase-N references resolve to existing entries | Validate grouping Member-phase IDs resolve to existing phase entries |
| Check 36 | `check_commit_scope_honesty()` at `:3904` | commit-subject scope keyword matches diff | Unaffected (the new `docs/project/groupings/` path counts as `project-only` scope; the existing keyword vocabulary covers it) |
| Check 40 | `check_bare_pack_ops_refs()` at `:4806` | pack-ops/ bare cross-reference scanner | Unaffected (current focus per BD-179) |
| Check (init-project structure) | `check_init_project_structure()` at `:725` | init-project.sh stage verification | Extend to verify S11 installs the `groupings/` tree |

### §10.2 — NEW checks proposed

| Check | Function | Purpose |
|---|---|---|
| Check (per-stream contract — groupings) | `check_grouping_per_stream_contract()` | Mirror the existing per-entry pattern enforcement: filename regex, supporting files admitted, back-pointer line present |
| Check (membership integrity) | `check_grouping_membership_integrity()` | Each grouping declares valid Kind from the canonical enum; member-phase list contains only valid phase IDs; no phase ID is double-listed within one grouping (within one grouping; cross-grouping multi-membership is allowed per V11.1 §8) |
| Check (per-Kind constraint, CONDITIONAL) | `check_grouping_kind_constraint()` | If Kind enum has per-Kind constraints (e.g., `release-package` requires a date in description), enforce them |
| Check (phase-level dependency cycles) | `check_grouping_phase_dependency_cycles()` | **Phase-level dependency cycle detection** (new check; covers REQUIREMENTS-GROUPINGS-V11.md Capability #13 SC13.22 per §5.1 amendment). Detects cycles in the union of member-phase `Blockers:` / `Unblocks:` graphs across all groupings — including inter-grouping cycle implications (Grouping A → Grouping B → Grouping A). Shared infrastructure with `pack groupings deps` / `pack groupings order` derived-query verbs per REQUIREMENTS Capability #9 SC9.9. Typed error per BD-070. Failure-mode anchor: OT PA-013 (7 cycles, 60 of 196 features unlayerable until manual cleanup) — see PLANNING-PROCESS-INSIGHTS-FROM-OT.md §4.2 + §5.1. Algorithm + persistence choice deferred to architect per HANDOFF-V11.1-ARCHITECT.md "Open architect-level surfaces" |

### §10.3 — Fixture-test inventory

| Fixture | Purpose | Status |
|---|---|---|
| `test-fixtures/v11.1-groupings-flat/` | Greenfield v11.1 client in flat-file mode with N>=2 groupings declared | NEW |
| `test-fixtures/v11.1-groupings-tracker-on/` | v11.1 client in tracker mode with N>=2 groupings mirrored to GH Projects | NEW |
| `scripts/tests/fixtures/roundtrip/grouping-v11.1/` | Round-trip fixture per BD-068 extension (forward → reverse → forward; diff = 0) | NEW |
| `scripts/tests/test-tracker-grouping.sh` | End-to-end test of `pack tracker groupings init/rebuild/status/doctor/disable` | NEW |
| `scripts/tests/test-grouping-per-entry-tree.sh` | Per-entry tree decompose / mirror-regenerate / TOC-regenerate for grouping stream | NEW |
| `scripts/tests/tracker-migrate-roundtrip-test.sh` | EXTEND: add grouping scenarios to existing round-trip test | MODIFY |
| `scripts/tests/test-validate-pack-check-N.sh` (one per new check) | Per-check test harness per CLAUDE.md CI Check 41 (`check_ci_workflow_wires_per_check_tests`) | NEW per check |

### §10.4 — CI workflow extension

`.github/workflows/validate-pack.yml` job list extends to include the new checks per `check_ci_workflow_wires_per_check_tests()` at `scripts/validate-pack.py:5291`. Per the pattern, each new check needs both a `test-validate-pack-check-N.sh` and a workflow job row.

### §10.5 — `test-fixtures/manifest.txt` regeneration

Per CLAUDE.md "Regenerate test-fixtures/manifest.txt on every v11-surface commit" rule: any commit touching `project-template/` / `scripts/` / `pack-ops/` / `supporting-docs/` requires `bash test-fixtures/build.sh --all --clean` before staging. All grouping work falls within this trigger; the architect should bake the regeneration step into the BD-by-BD plan.

---

## §11 — Open observations

Anomalies, naming questions, asymmetries, or curiosities noticed during the walk. Not for the researcher to resolve.

1. **V11.1 doc proposes pack-root `groupings/` AND project-template `docs/project/groupings/` as possibly co-existing surfaces.** Per V11.1 §12 ("New `groupings/` directory under `docs/project/` (client) or repo root (pack, if needed)"). The pack-self per-entry tree pattern at `scripts/lib/per-entry/_lib.sh:64-83` has TWO pack-self streams (pack-backlog, pack-changelog) and THREE project streams (project-backlog, project-implementation-plan, project-changelog) — pack-self lacks IMPLEMENTATION-PLAN entirely. If groupings depend on phases (per V11.1 §8) and pack-self has no phases (per V11.1 §14 Q1), pack-self has no groupings either. The architect's default likely is "client-only" per V11.1 §14 Q1.

2. **The V11.1 doc never says whether `**Member phases (by ID):**` membership is ordered or unordered.** §10's example shows an ordered list (phase-2.1, phase-2.3, phase-3.4, phase-4.1, phase-4.2 — but this is just file order). V11.1 §8 says "execution order is the DAG, UX-presentation order belongs in PRD, grouping doc enumerates membership" — strongly suggests **unordered** (the bullet list is for human reading; order has no semantic meaning). The architect should explicitly affirm this in `_rules.md`.

3. **Grouping filename naming convention is open.** V11.1 §10 example shows `# Grouping: Auth & Identity (user-journey)` as H1 title; doesn't specify the filename. The pattern at the three v11.0 streams uses ID-based filenames (`TD-NNN.md`, `phase-N.md`, `YYYY-MM-DD-slug.md`). Groupings don't have a natural ID prefix; the architect must pick: slug-only (`auth-and-identity.md`), Kind-prefix (`user-journey-auth-and-identity.md`), or numeric ID (`grouping-001.md`). V11.1 doc doesn't bias.

4. **Pack-self trinity has no `## Document locations` section (per touch-point archive observation 12).** If pack-self DOES get a `groupings/` tree per Q1, the pack-root trinity exemption per D-6 footnote means there's no Document locations table to extend. The grouping reference would land in the existing "Key files to read" lists at `CLAUDE.md:28-33` instead. Asymmetric to project-template surface but consistent with existing pack-self exemption.

5. **The `_format.md` per-stream file exists only for the project-changelog stream.** Per `scripts/lib/per-entry/_lib.sh:114` (support tuple for `project-changelog` includes `_format.md`). The other 4 streams have no `_format.md`. The architect decides whether groupings need a `_format.md` — the precedent suggests it's only needed when there's a non-trivial format spec beyond what `_rules.md` carries (changelog has append-only + dated semantics; groupings might have similar carve-outs for Kind enum + member-list grammar, but the rules can also live in `_rules.md` per the precedent of backlog/implementation-plan).

6. **V11.1 §13 row Y-1 names the file/symbol as `project-template/docs/project/groupings/` + `project-template/docs/project/groupings/_rules.md` only.** Missing from the row: `_intro.md`, `_toc.md`, the regenerated mirror `GROUPINGS.md`, and the optional `_format.md`. The V11.1 author probably elided these as derivative, but the architect should make them explicit so the BD-Y-1 plan doesn't miss them. The pattern is fully established at the three v11.0 streams.

7. **GH Projects v2 is GraphQL-only; existing `tracker-provider-gh.sh` is REST-focused via `_gh_run` helper.** Per `scripts/lib/tracker-provider-gh.sh:115` `_gh_run` invokes `gh api` — could accept `gh api graphql` queries but the existing pattern is REST. The grouping work needs a GraphQL variant or a new helper. Pattern decision belongs to architect.

8. **The "lightweight" Shape 1 (V11.1 §5) integration is what the V11.1 doc anchors on, but Shape 1's `tracker.toml [project]` section is only briefly described.** §5 Shape 1 says "project number / URL / default-field-map" without concrete schema. The architect must reify this into a TOML schema; the schema cite (per §3.D) shows the minimum-viable shape, but a real architect pass will iterate.

9. **V11.1 §15 working assumption "Phase-as-Project is rejected; Grouping-as-Project is the granularity" is opposite of the V11.1 §7 footnote alternative "single all-phases Project sliced by Iteration field."** Both can coexist per §7 ("This doesn't conflict with grouping projects — both can coexist (one issue can live in multiple Projects)"), but the architect should explicitly affirm: by default, pack creates one Project per grouping. The optional phase-iteration single-Project (per V11.1 §13 row Y-6 optional) is a separate verb / opt-in.

10. **The current v11.0 design (per ARCHITECTURE-V3.3-DELTA.md §0) does not anticipate groupings.** §1 V3.2-DELTA disposition table mentions D-21 (entity placement) / D-22 (TD promotion) / D-23 (auditor agents) but no grouping decision. Groupings are a v11.1 add. The architect should not retro-fit V3.3 decisions; the grouping work composes WITH V3.3 unchanged.

11. **`scripts/lib/recommendation.sh` D-19 signals do not include a grouping signal.** Client signals (per touch-point archive §1.G observation 9): 7 today (`td_count_active`, `td_count_total`, `backlog_kb`, `phase_count`, `implementation_plan_kb`, `td_tbd_comment_count`, `typed_deferral_count`). Architect decides whether `grouping_count` joins (an 8th signal would surface "you have N phases but 0 groupings — consider organizing into journeys / batches"). Not load-bearing for v11.1 launch but is part of the discoverability surface.

12. **The "Pack Chat does NO fixes" rule (per CLAUDE.md Pack memory § Pack Chat scope) DOES apply to GROUPINGS.md edits — Pack Chat is direct-edit on PM-only files including the project-template trinity.** Per CLAUDE.md "What Pack Chat CAN edit directly" bullet: PM-only files (BACKLOG.md / CHANGELOG.md / README version table / PACK-CHAT.md / PACK-AGENTS.md / trinity ops files at pack root / `project-template/` trinity). Adding GROUPINGS.md to PM-only is a Pack-Chat-direct edit category; coder-required for code surfaces. The architect should explicitly resolve which surface GROUPINGS.md falls under (likely PM-only because it parallels BACKLOG.md / STATUS.md governance).

13. **BD-185 must precede groupings work.** Per `pack-ops/BACKLOG.md:1789` BD-185 is positioned at Batch 19d. The grouping work depends on BD-185's phase-parts decision (whether `phase-N` IDs gain a Part suffix that would affect grouping membership grammar). The user-approved sequencing puts BD-185 before any v11.1 work; the grouping doc Member-phase grammar must accept whatever BD-185 produces.

14. **The `scripts/lib/per-entry/_lib.sh` `pe_stream_for_path` resolver (lines 149-173) matches by longest path suffix.** Adding `docs/project/groupings` as a 4th project-side suffix is collision-free with the existing 3 suffixes. No regression risk for the resolver.

---

End of v11.1+ groupings touch-point inventory. This doc enumerates the fact base from V11.1-DISCUSSION-GITHUB-PROJECTS.md + current v11-dev SSOTs + primary tracker documentation. Architect / planner / user takes it from here.
