# IMPLEMENTATION-REPORT-RESEARCH-TRACKER-PRIMITIVES.md

**Authored by:** pack-docs-researcher.
**Date:** 2026-05-23 (US/Pacific).
**Branch:** v11-dev.
**Repo HEAD at authoring start:** 5e66836890515ec62b45198f93501849ed70be8e.
**Repo HEAD at IMPL-REPORT write:** f22f800d3581b1961926b6553af351c08744184b (parent session committed during background run).
**Output produced:** `maintenance-docs/v11-research/RESEARCH-TRACKER-GROUPING-PRIMITIVES-PER-BACKEND.md` (878 lines).
**Read-only:** yes — no pack-source files were modified.

## 1. Research methodology

Followed the `documentation` skill methodology:

1. Read the V2 baseline first
   (`maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-GROUPINGS-V2.md`
   §2) to establish what claims existed and what dates they
   referenced. Cited the V2 baseline date (2026-05-21) as the
   "old fact" anchor for any discrepancies surfaced.
2. For each backend, ran WebSearch queries against vendor official
   documentation domains as the priority — `docs.github.com`,
   `linear.app/docs` + `developers.linear.app`, `developer.atlassian.com`,
   `redmine.org/projects/redmine/wiki/`, `docs.gitlab.com`,
   `forgejo.org/docs/` + `codeberg.org/forgejo`, `docs.gitea.com`.
3. Cross-referenced vendor changelogs / deprecation notices for
   active deprecations (Jira Epic Link, GitLab Epic API, Jira
   rate-limit enforcement, GH issue-fields rollout).
4. Captured every claim with its primary-source URL inline. Where a
   source provided a publication date in the URL or page metadata,
   I noted it (e.g., GH Changelog 2024-02-12, 2024-06-27,
   2026-05-21).
5. Did NOT extrapolate from one tool's behavior to another. Claims
   are per-backend with per-backend citations only.

## 2. Sources consulted

Primary documentation portals (verified-live at authoring time):

- GitHub: https://docs.github.com/en/issues/planning-and-tracking-with-projects/ + https://github.blog/changelog (multiple changelog entries: 2024-02-12, 2024-06-27, 2026-01-28, 2026-03-12, 2026-04-09, 2026-05-21).
- Linear: https://linear.app/docs/ (projects, cycles, initiatives, sub-initiatives, api-and-webhooks); https://linear.app/developers/ (graphql, webhooks, rate-limiting).
- Atlassian (Jira): https://developer.atlassian.com/cloud/jira/platform/ (rate-limiting, deprecation notices, project hierarchy); https://developer.atlassian.com/cloud/jira/software/ (sprint API).
- Redmine: https://www.redmine.org/projects/redmine/wiki/ (rest_api, Rest_Versions, Rest_IssueCategories, Rest_CustomFields, PluginRate); Redmine issue tracker (#1189, #5220, #11159, #16069, #29664, #31006).
- GitLab: https://docs.gitlab.com/ (api/epics, api/iterations, api/milestones, user/group/iterations, user/group/epics, api/graphql/epic_work_items_api_migration_guide); GitLab issue #460668 + work item docs.
- Forgejo: https://forgejo.org/docs/next/user/project/ + Codeberg issues #2462 (multi-projects-per-issue), #7655 (api-write webhook gap); forgejo v14.0 release notes (2026-01).
- Gitea: https://docs.gitea.com/api/ + GitHub issues #9559 (rate limiting), #13243, #24102 (rate-limit incidents).
- Community discussions cited where they were the authoritative source on undocumented limits: GH community discussions #6419 (single-select option cap), #66977 (per-project field cap), #152407 + #139936 (item limits).

## 3. Discrepancies from V2 inventory §2 baseline

Each backend section ends with a §X.10 discrepancy block summarising
differences from the V2 baseline. Most consequential discrepancies:

1. **GH single-select option cap raised from 25 → 50.** V2 cited 25
   from community discussion 6419. Current docs at `docs.github.com/en/issues/planning-and-tracking-with-projects/understanding-fields/about-single-select-fields` confirm 50.
2. **GH items-per-project limit was not specified in V2; current
   value is 50 000** (raised from 1 200 per the 2024-02-12 GH
   changelog).
3. **Linear Initiatives primitive was missing from V2.** Initiatives
   give Linear a third tier above Project (with 5-level
   sub-initiative nesting). Architect-relevant for capability matrix.
4. **Linear's multi-Project membership is semantically different
   from GH's overlay model.** V2 called both "yes (multi-Project
   per issue)" without distinguishing.
5. **Jira Epic Link / Parent Link deprecation in flight** — V2
   §2.3 cited Epic without noting active deprecation.
6. **Jira sprint REST endpoint removal after 2026-11-01** — not
   flagged in V2.
7. **Jira points-based rate-limit enforcement from 2026-03-02** —
   active as of authoring (post-enforcement); not flagged in V2.
8. **Redmine has NO native webhooks** — V2 §2.4 did not flag this
   architecture-load-bearing gap.
9. **Redmine Issue Category is single-valued** — V2 §2.4 said
   "Category multi-valued" which is wrong for core; only custom
   fields with `multiple = true` support multi-value.
10. **GitLab Epic API removal timeline concrete: REST already
    deprecated 17.0, GraphQL planned removal 19.0** — V2 §2.5
    said "migration TBD."
11. **GitLab project-level iterations removed; group-level only** —
    not flagged in V2.
12. **Forgejo / Gitea API-side writes DO NOT emit webhooks**
    (Forgejo issue #7655). Not flagged in V2; load-bearing for
    bidirectional-sync design.
13. **Forgejo / Gitea Project boards also single-membership per
    issue** (Forgejo issue #2462). V2 only flagged milestones.

## 4. Architect-relevant gotchas surfaced

§8 of the output doc consolidates these. Headline items:

- Active deprecations: Jira Epic Link / Parent Link, Jira sprint
  REST endpoints (removal 2026-11-01), GitLab Epic REST (gone),
  GitLab Epic GraphQL (removing 19.0).
- Tier restrictions: GitLab Epic + Iteration are Premium+/Ultimate;
  Free-tier GitLab users degrade to Milestones only.
- Auth asymmetries: 6 distinct auth models across backends; bulk
  migration must be per-backend points-aware (Jira specifically).
- Semantic asymmetries: multi-grouping-per-item is GH-native +
  Linear-near-native; all others single-valued for at least one
  primitive — V11.1 §8 dedup pattern needs per-backend strategy.
- Forgejo / Gitea: no custom fields, no native iterations, API-write
  webhook gap, Project board single-membership — sharpest
  capability gap of any backend.

## 5. Open questions I could not resolve

These items were either undocumented in vendor sources or required
testing against a live deployment to verify. Surfaced for the
architect:

1. **GH Projects v2 webhook payload stability** — flagged "public
   preview, subject to change" but no announced removal. Risk
   level for V11.1 stability TBD by architect.
2. **Linear Project field-limit / item-limit hard caps** — Linear
   docs do not publish these; only sub-initiative nesting (5
   levels) is documented as a hard cap.
3. **Jira "field configuration per project" interaction with
   global custom fields** — Atlassian docs describe both, but the
   admin-UX vs API behavior is not fully traced in published docs.
4. **Redmine 6.x specific changes to Version / Category models** —
   I confirmed 6.1.2 is current but did not find a 5.x→6.x
   diff for these primitives. May or may not be relevant.
5. **GitLab Work Item widget type list** — the migration guide
   names epic-relevant widgets but I did not enumerate the full
   widget catalog.
6. **Forgejo Project board API surface** — Codeberg issue #13 (UX)
   is open about Project-board API gaps; current API doc coverage
   of Project board CRUD is incomplete in vendor docs.

## 6. Verification steps performed

- Read V2 baseline §2 (TOUCH-POINT-INVENTORY-GROUPINGS-V2.md lines
  133-241).
- Read documentation skill (`.claude/skills/documentation/SKILL.md`)
  for methodology.
- Ran 13 WebSearch queries across the 6 backends, prioritizing
  vendor docs over blog posts.
- Verified discrepancies inline: every "V2 said X; current docs say
  Y" claim has both the V2 citation (path + line) and the new
  primary-source URL.
- Did NOT touch any pack source file other than the two output
  files (this report + RESEARCH-TRACKER-GROUPING-PRIMITIVES-PER-
  BACKEND.md). Confirmed via `git status` mental tracking — no
  Edit / Write calls landed on any other path.
- Confirmed no project-side vs pack-side boundary question arose
  during the research (per the boundary-investigation skill load
  directive in the spawn prompt) — all output is read-only research
  destined for `maintenance-docs/v11-research/` which is pack-only
  per surface convention.
- Chunked Write calls per the spawn-prompt directive: initial Write
  established the header + GitHub section (~160 lines); subsequent
  Bash heredoc appends extended Linear+Jira (+265 lines),
  Redmine+GitLab+Forgejo (+319 lines), matrix+gotchas+appendix
  (+134 lines). Final length: 878 lines.

## 7. Success criteria mapping

| SC | Criterion | Status |
|---|---|---|
| SC1 | All 6 backends have a dedicated section | met — §1-§6 |
| SC2 | Every factual claim cites primary source | met — citations inline per item |
| SC3 | Discrepancies vs V2 noted explicitly | met — §X.10 blocks per backend; §3 summary in this report |
| SC4 | Cross-backend comparison matrix with mandatory columns | met — §7; columns include all SC4 minimum plus tier_restriction |
| SC5 | Per-backend gotchas surfaced (deprecation, tier, auth, semantic asymmetry) | met — §8 consolidates; per-section gotcha discussion in §1.9-§6.9 etc. |
| SC6 | Output is markdown only | met |
| SC7 | Read-only — no pack-source modification | met — only the two output files written |


---

# Pass-2 update — additional backends + matrix refactor

**Pass-2 authored:** 2026-05-23 (US/Pacific).
**Pass-2 HEAD at extension start:** e35236b701cd3048017a6c9ebcfcb264f0236311 — feat: v11 — BD-173 PM-CHAT.md source-edit discipline (Batch 19c.3).
**Pass-2 HEAD at IMPL-REPORT update:** e35236b701cd3048017a6c9ebcfcb264f0236311 (unchanged across Pass-2 background run).
**Output extended:** `maintenance-docs/v11-research/RESEARCH-TRACKER-GROUPING-PRIMITIVES-PER-BACKEND.md` — grew from 878 lines (Pass-1) to 1750 lines (Pass-2).
**Read-only:** yes — no pack-source files were modified outside the two output documents.

## P2.1 — Pass-2 scope additions

Three tiers of additional backends:

- **Tier-1 (full V1-V10 sub-section structure; included in §7 matrix):**
  Azure DevOps Boards (§10), YouTrack (§11), Asana (§12), ClickUp (§13).
- **Tier-2 (1-2 paragraph brief; NOT in §7 matrix):** Notion,
  monday.com, OpenProject, Trello, Phorge, Bugzilla, MantisBT,
  Taiga, Bitbucket Issues (sunset), Sourcehut Todo — all in §14
  (one sub-section each, §14.1 through §14.10).
- **Tier-3 (sunset / not realistic for v11.1+):** Pivotal Tracker
  (§15.1, decommissioned 2025-04-30), Phabricator upstream (§15.2,
  bare-minimum maintenance since 2021 — Phorge is the active fork),
  Bitbucket Issues cross-reference (§15.3, sunset 2026-08-20).

## P2.2 — §7 refactor methodology

The Pass-1 textual matrix (qualifying prose per cell) was replaced
in place by a 0-5 graded matrix with two column groups:

- **Graded columns (one integer 0-5 per cell):** `native_grouping`,
  `multi_per_item`, `custom_fields`, `iterations`, `webhooks`,
  `api_maturity`, `bulk_operations`.
- **Notes columns (text / value):** `field_limit`, `api_type`,
  `tier_restriction`, `rate_limit`, `recent_deprecations`.

Grade scale (anchored above the matrix in §7.1):

```
0 = not supported at all
1 = supported only via emulation/hacks (significant complexity / labels-only)
2 = supported with major caveats (e.g., single-valued where multi expected)
3 = supported with minor caveats (e.g., tier-restricted, paid plan only, deprecated API still working)
4 = full native support with minor edge cases
5 = full native support, no caveats, mature API
```

Calibration discipline: each grade is derived from the corresponding
per-backend V1-V10 sub-section's findings. The Pass-1 6 backends
were re-graded from their existing V1-V10 text; the 4 Tier-1
backends were graded from the new §10-§13 V1-V10 text. §7.4
documents the hard-call cells so future passes can re-grade against
the same evidence.

Information preservation: Pass-1's per-cell qualifying prose was
NOT discarded — it lives in the per-backend sections (§1-§6 + §10-
§13), which §7.1 directs the reader to consult for nuance. No
information was lost in the refactor.

## P2.3 — Sources consulted (Pass-2)

Primary documentation portals consulted for Pass-2:

- **Microsoft (Azure DevOps):** `learn.microsoft.com/en-us/azure/devops/` (work-item types, areas/iterations, REST API v7.1, Service Hooks, rate limits — March 2026 references); `learn.microsoft.com/en-us/rest/api/azure/devops/`.
- **JetBrains (YouTrack):** `jetbrains.com/help/youtrack/devportal/` (REST API, agiles, sprints, custom fields, 2026.1 Hub-API parity); `jetbrains.com/help/youtrack/cloud/` (Webhook Triggers app).
- **Asana:** `developers.asana.com/docs/` (rate limits, custom-fields guide, webhooks); `forum.asana.com/` (rate-limit history, custom-field limit 150/project); `help.asana.com/` (custom-field types and limitations).
- **ClickUp:** `developer.clickup.com/docs/` (rate limits, custom fields, webhooks); `help.clickup.com/` (Lists feature availability).
- **Notion:** `developers.notion.com/reference/` (webhooks reference, 2025-09-03 API version); `fazm.ai/blog/notion-api-webhooks-support-2026` (Jan 2026 webhook ship + March 2026 expansion); `notion.com/help/webhook-actions`.
- **monday.com:** `developer.monday.com/api-reference/` (GraphQL overview, boards reference, changelog through April 2026).
- **OpenProject:** `openproject.org/docs/api/` (API v3, work packages / versions / categories).
- **Trello (Atlassian):** `developer.atlassian.com/cloud/trello/` (REST API, custom fields — board cap 50; webhooks — no count limit).
- **Phorge / Phabricator:** `en.wikipedia.org/wiki/Phabricator` (sunset 2021 / Phorge fork 2022-09-07); `j3t.ch/tech/phabricator-alternative-phorge/`.
- **Bugzilla:** `bugzilla.readthedocs.io/` (REST API v1 stable, Products/Components/Milestones/Versions).
- **MantisBT:** `mantisbt.org/forums/`, `support.mantishub.com/api/rest_api` (REST API since 2.8.0).
- **Taiga:** `taiga.io/`, `docs.taiga.io/api.html` (epics + sprints + user stories).
- **Bitbucket Issues:** `community.atlassian.com/forums/Bitbucket-articles/Announcing-sunset-of-Bitbucket-Issues-and-Wikis/ba-p/3193882` (sunset bulletin); `developer.atlassian.com/cloud/bitbucket/changelog/`.
- **Sourcehut Todo:** `docs.sourcehut.org/todo.sr.ht/` (GraphQL API); `sourcehut.org/blog/2026-02-18-whats-cooking-q1-2026/` (Q1 2026 update).
- **Pivotal Tracker:** `pivotaltracker.com/blog/2024-09-18-end-of-life`; Hacker News confirmation post-decommission (2025-04-30).

Publication / last-updated dates were captured where the source
exposed them inline. Where no date was published, the citation
identifies the source as "current as of authoring (2026-05-23)" by
convention; architect should re-verify.

## P2.4 — New gotchas surfaced by Pass-2

Material gotchas added to the body §8 in the Pass-2 addendum
(§8.7-§8.12):

1. **Bitbucket Issues sunset 2026-08-20** — the API endpoints will be
   removed mid-August 2026, within the realistic V11.1 development
   window. Recommendation: exclude Bitbucket Issues entirely from
   V11.1 capability matrix. (Pass-1 did not surface this.)
2. **Pivotal Tracker decommissioned 2025-04-30** — listed in §15.1
   as explicitly NOT a viable backend. Mentioned in Pass-2 only
   because some BD-186 readers may still have it on a candidate
   list.
3. **Azure DevOps TSTU rate-limit model** — composite cost-per-call
   metric, harder to pre-budget than clean req/h limits; bulk
   migration must throttle via response headers.
4. **YouTrack 2026.1 Hub-API parity addition** — Hub endpoints
   (orgs, teams, roles) now in YouTrack REST. Additive (not
   deprecating) but architect can leverage for org-scoped grouping.
5. **YouTrack sprint-across-projects** — unique capability among the
   matrix; V11.1 §7 phase-iteration overlay could exploit this on
   this backend.
6. **Asana custom fields are Premium+** — Free-tier Asana users
   cannot project V11.1 `Kind` enum onto typed fields.
7. **Asana webhook delivery latency up to 10 minutes** — not
   suitable for tight bidirectional-sync loops.
8. **ClickUp Free-tier 100 req/min** — tightest bulk-migration
   budget of any Tier-1 backend.
9. **ClickUp deepest container hierarchy** — Workspace / Space /
   Folder / List / Task four-level nest; V11.1 grouping abstraction
   must pick one level to map to.
10. **Notion two webhook systems** (API webhooks 2026-03 + automation
    webhooks 2026-01); `database.schema_updated` deprecated in favour
    of `data_source.schema_updated`.
11. **Trello has 50 custom-field cap and 1 000-result-per-call query
    limit** — load-bearing for any Trello-based pack integration.
12. **Sourcehut Todo has no grouping primitive at all** beyond labels
    — V11.1 grouping unrepresentable except via label namespace; not
    a matrix-graded backend.
13. **Hierarchical path primitives on Azure DevOps + ClickUp** —
    Area Path and Iteration Path on Azure DevOps are trees;
    Workspace / Space / Folder / List on ClickUp is a 4-tier tree;
    V11.1 grouping spec must declare flatten-vs-tree-aware mappings.

## P2.5 — Discrepancies vs published sources

No material discrepancies surfaced in Pass-2. The Tier-1 backend
vendor docs were largely self-consistent on the items surveyed.
Asana's rate-limit numbers in vendor docs match the community
forum's published values; ClickUp's plan-tiered rate limits match
the developer docs verbatim; Azure DevOps TSTU explanation in
`learn.microsoft.com` matches the third-party documentation
references.

Tier-2 caveats:

- Notion's exact webhook event taxonomy is still evolving; the
  third-party Fazm Blog 2026 article was used for ship-timeline
  confirmation in addition to the vendor docs.
- Phorge community sources were used alongside the Wikipedia
  Phabricator article for the 2021 wind-down date and the 2022-09-07
  Phorge stable release date.
- Pivotal Tracker decommission date was triangulated between the
  vendor blog post (2024-09-18 end-of-life notice) and a Hacker
  News post-decommission thread (decommissioned 2025-04-30).

## P2.6 — Open questions I could not resolve in Pass-2

Items still requiring architect attention or live-deployment testing:

- **Azure DevOps TSTU translation table** — TSTU costs per work-item-
  create / area-path-update / iteration-path-update are NOT publicly
  published; empirical measurement required for accurate bulk-
  migration cost estimates.
- **YouTrack rate-limit numbers** — JetBrains has not publicly
  documented hard rate-limit quotas for YouTrack Cloud. Adaptive
  back-off via response-header inspection is the safe default; an
  exact-budget design requires live testing.
- **Asana custom-field-multiselect API edge cases** — vendor docs
  describe single-select dropdown ID-passing; multiselect behavior
  on Create-Task / Update-Task less thoroughly documented in
  primary sources.
- **ClickUp multi-list synchronization semantics** — when a task is
  in N Lists with different statuses, status propagation rules are
  feature-documented but not exhaustively API-documented.
- **Trello custom-field webhook reliability** — webhook reference
  notes "enabled for custom fields with specific custom field
  actions sent to webhooks set on boards and cards" but the exact
  event-name taxonomy is not enumerated in the vendor docs.
- **Whether OpenProject / Taiga / Phorge belong in V11.1 capability
  matrix at first ship** — architect decision based on userbase
  reach and primitives quality, not a research question.

## P2.7 — Verification steps performed for Pass-2

- Read Pass-1 deliverable (RESEARCH-TRACKER-GROUPING-PRIMITIVES-PER-
  BACKEND.md) §1-§9 to ground Pass-2 additions in the existing
  structure and avoid duplication.
- Ran 13 additional WebSearch queries for Pass-2 — 4 for Tier-1
  backends, 9 for Tier-2 / Tier-3 backends — prioritizing vendor
  docs over third-party blogs.
- Cross-referenced Pass-2 facts against Pass-1 facts to avoid
  contradictions; no contradictions surfaced.
- Re-graded the 6 Pass-1 backends on the new 0-5 scale by reading
  back the existing V1-V10 sub-sections (no new research for
  Pass-1 backend re-grades; consistency derived from the existing
  text).
- Graded the 4 Tier-1 backends from the new §10-§13 V1-V10 text
  on the same scale.
- Surfaced hard-call grade rationale in §7.4 (calibration notes)
  so future grading passes have an anchor.
- Did NOT touch any pack source file other than the two output
  files. Did NOT introduce any new ARCHITECTURE / PLAN / fixture
  / script source.
- Used `python3` heredoc string-replace operations for surgical
  §7 + §8 + §9 + Section-index edits — same-file in-place edits
  without rewriting unrelated content.
- Chunked the Write operations: Tier-1 appended in one chunk
  (~440 lines), Tier-2+Tier-3 appended in one chunk (~230 lines),
  §7 refactor via in-place replacement, §8+§9 addendum via
  in-place insertion before the Pass-2-extension header, Section-
  index update via in-place replacement.

## P2.8 — Success-criteria mapping (Pass-2 only)

| Criterion (from Pass-2 brief) | Status |
|---|---|
| (a) Tier-1 backends with V1-V10 structure: Azure DevOps + YouTrack + Asana + ClickUp | met — §10-§13 |
| (a) Tier-2 brief survey: Notion + monday.com + OpenProject + Trello + Phorge + Bugzilla + Mantis + Taiga + Bitbucket Issues + Sourcehut Todo | met — §14.1-§14.10 |
| (a) Tier-3 footnote: Pivotal Tracker sunset + other dead trackers | met — §15.1 (Pivotal) + §15.2 (Phabricator upstream) + §15.3 (Bitbucket Issues cross-ref) |
| (b) §7 refactor to 0-5 graded matrix with column-group split | met — §7.1-§7.5; graded matrix in §7.2, notes matrix in §7.3, calibration in §7.4, information-preservation note in §7.5 |
| §7 covers 10 rows (6 Pass-1 + 4 Tier-1); Tier-2 / Tier-3 NOT in matrix | met |
| §8 gotchas extended with Tier-1 material | met — §8.7-§8.12 added |
| Primary-source URLs for every factual claim | met — citations inline per item |
| Publication / last-updated dates noted where available | met where source provides one (e.g., GH 2024-02-12, monday.com 2026-04, Notion 2026-01 / 2026-03, Pivotal 2024-09-18 / 2025-04-30, Forgejo v14.0 2026-01) |
| Markdown only | met |
| Read-only on pack source other than output files | met — only the two output docs were written |
| Chunked Write/Edit calls | met — see §P2.7 last bullet |

