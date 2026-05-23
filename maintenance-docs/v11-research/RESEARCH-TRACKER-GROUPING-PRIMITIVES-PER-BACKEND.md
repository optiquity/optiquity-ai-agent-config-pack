# RESEARCH-TRACKER-GROUPING-PRIMITIVES-PER-BACKEND.md

**Authored by:** pack-docs-researcher (BD-186 ancillary research).
**Date:** 2026-05-23 (US/Pacific).
**Branch:** v11-dev.
**Repo HEAD at authoring:** 5e66836890515ec62b45198f93501849ed70be8e — docs: v11 — BD-185 open (Batch 19d phase parts + ordering, pack-only).
**Companion documents:**
- `maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md` (just-landed requirements).
- `maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-GROUPINGS-V2.md` §2 (2026-05-21 baseline; this doc supersedes/extends).

## Purpose

This document supplies verified per-backend reference material for the
v11.1+ groupings feature architect. Each section enumerates the
grouping-related primitives of a tracker backend, with primary-source
citations dated where the source provides a date, and architect-
relevant gotchas flagged.

Scope-of-verification per backend (verification items):

- V1. Native grouping primitives.
- V2. Multi-grouping-per-issue support.
- V3. Custom field support.
- V4. Iteration / sprint / cycle primitives.
- V5. API access mechanism + auth.
- V6. Webhook support for grouping-related events.
- V7. Field / item limits.
- V8. API rate limits (bulk-migration relevance).
- V9. Recent / upcoming deprecations.

Discrepancies versus the 2026-05-21 V2 inventory §2 baseline are
called out inline with both old and new facts cited.

## Section index

Pass-1 sections (§1-§9):

- §1 — GitHub (Projects v2)
- §2 — Linear
- §3 — Jira (Cloud)
- §4 — Redmine
- §5 — GitLab
- §6 — Forgejo / Gitea
- §7 — Cross-backend comparison matrix (REFACTORED in Pass-2 to 0-5 graded; covers all 10 graded backends)
- §8 — Architect-relevant gotchas summary (EXTENDED in Pass-2; §8.7-§8.12 are Pass-2 addendum)
- §9 — Appendix: source-of-truth snapshot (EXTENDED in Pass-2; §9.1 adds Tier-1 + Tier-2 portals)

Pass-2 sections (§10-§15):

- §10 — Azure DevOps Boards (Microsoft) — Tier-1, V1-V10
- §11 — YouTrack (JetBrains) — Tier-1, V1-V10
- §12 — Asana — Tier-1, V1-V10
- §13 — ClickUp — Tier-1, V1-V10
- §14 — Tier-2 long-tail tracker survey (Notion / monday.com / OpenProject / Trello / Phorge / Bugzilla / Mantis / Taiga / Bitbucket Issues / Sourcehut Todo)
- §15 — Tier-3 sunset / not realistic for v11.1+ (Pivotal Tracker / Phabricator upstream / Bitbucket Issues cross-ref)

---

## §1 — GitHub (Projects v2)

### §1.1 — Native grouping primitives (V1)

- **Project (Projects v2)** — first-class container at user, org, or
  enterprise scope; overlays issues + PRs + draft items with custom
  fields, multiple views (board / table / roadmap), automations, and
  built-in insights.
  ([GitHub Docs: About Projects](https://docs.github.com/en/issues/planning-and-tracking-with-projects/learning-about-projects/about-projects))
- **Issue types** (org-level; up to 25 types; separate from Project
  primitive — relevant because they group issues categorically without
  needing a Project).
  ([GitHub Docs: Managing issue types](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/managing-issue-types-in-an-organization))
- **Issue fields** (org-level structured metadata; new since 2026-03;
  per GH Changelog 2026-05-21 in public preview to all orgs).
  ([GitHub Changelog 2026-05-21: Issue fields public preview](https://github.blog/changelog/2026-05-21-issue-fields-are-now-in-public-preview-for-all-organizations/))

### §1.2 — Multi-grouping-per-issue (V2)

Confirmed: one issue may appear in multiple Projects simultaneously,
each Project carrying its own field-value overlay for the item. The
underlying issue keeps its single set of labels / state / body.
([GitHub Docs: About Projects](https://docs.github.com/en/issues/planning-and-tracking-with-projects/learning-about-projects/about-projects))

### §1.3 — Custom field support (V3)

Project-scoped custom field types supported:

- Single-select
- Text
- Number
- Date
- Iteration (special: time-boxed; auto-rolls)

Org-level issue-field types (separate primitive): Single-select, Text,
Number, Date. ([GitHub Docs: Managing issue fields](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/managing-issue-fields-in-your-organization))

### §1.4 — Iteration primitives (V4)

The **Iteration field** is a Project-scoped custom field type that
declares time-boxed periods (sprints / cycles), each Iteration having
a start date and duration; the field auto-advances as iterations
complete.
([GitHub Docs: Using the API to manage Projects](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-api-to-manage-projects))

### §1.5 — API access (V5)

- **Projects v2:** GraphQL only. The REST surface that existed for
  legacy "Projects Classic" was retired with Classic.
- Mutations include `addProjectV2ItemById`,
  `updateProjectV2ItemFieldValue`, `deleteProjectV2Item`,
  `createProjectV2Field`, `archiveProjectV2Item`, etc.
- Auth: PAT (`project` + `read:org` scopes), GitHub App installation
  token, or OAuth user token.
  ([GitHub Docs: Using the API to manage Projects](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-api-to-manage-projects))

### §1.6 — Webhook support (V6)

- `projects_v2` — Project lifecycle (created / edited / closed /
  reopened / deleted).
- `projects_v2_item` — Item add / edit / archive / restore / delete /
  converted; PAYLOAD INCLUDES previous + current field-value pairs
  inline (no follow-up GraphQL needed for field-change observation).
- `projects_v2_status_update` — Status update CRUD (added
  2024-06-27 changelog).
- Scope restriction: Project webhooks are **organisation-level only**;
  no user-scoped Project webhooks; events deliver as the same
  payload shape on Enterprise Cloud.
- Current status: "public preview, subject to change."
  ([GitHub Docs: Webhook events and payloads](https://docs.github.com/en/webhooks/webhook-events-and-payloads))
  ([GitHub Changelog 2024-06-27: status updates + webhooks](https://github.blog/changelog/2024-06-27-github-issues-projects-graphql-and-webhook-support-for-project-status-updates-and-more/))

### §1.7 — Field / item limits (V7)

| Limit | Value | Source |
|---|---|---|
| Fields per project | **50** (sum of built-in + custom fields) | [community discussion 66977](https://github.com/orgs/community/discussions/66977) |
| Items per project | **50 000** (raised from 1 200 in 2024 GA) | [GH Changelog 2024-02-12](https://github.blog/changelog/2024-02-12-github-issues-projects-projects-without-limits-private-beta/); [community discussion 152407](https://github.com/orgs/community/discussions/152407) |
| Issue fields per organisation | **25** | [GitHub Docs: Managing issue fields](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/managing-issue-fields-in-your-organization) |
| Issue types per organisation | **25** | [GitHub Docs: Managing issue types](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/managing-issue-types-in-an-organization) |
| Single-select options per field | **50** (raised from 25) | [GH Docs: About single select fields](https://docs.github.com/en/issues/planning-and-tracking-with-projects/understanding-fields/about-single-select-fields); raised per [community discussion 6419](https://github.com/orgs/community/discussions/6419) |

**Discrepancy from V2 baseline:** the 2026-05-21 V2 inventory §2.1
cited "25 options per single-select field." Current docs confirm the
limit was **raised to 50** options per single-select field. Architect
should rely on the 50 value. ([GitHub Docs: About single select fields](https://docs.github.com/en/issues/planning-and-tracking-with-projects/understanding-fields/about-single-select-fields))

### §1.8 — Rate limits (V8)

GraphQL API: standard 5 000 points/hour for authenticated PAT;
GitHub App installation tokens scale by installation count;
enterprise plans have higher pools. Complex mutations cost more
points; pagination required for large field-value bulk reads.
([GitHub Docs: Rate limits for the GraphQL API](https://docs.github.com/en/graphql/overview/resource-limitations))

### §1.9 — Deprecations / upcoming changes (V9)

- Projects Classic (REST) — retired (already gone; v2 is the only
  current generation).
- Projects v2 webhook events still flagged "public preview" — payload
  shape MAY change. Architect should design against the documented
  payload but assume a non-breaking minor-version field shift is
  possible without a major-version event.

### §1.10 — Discrepancies vs V2 baseline

1. **Single-select options:** V2 cited 25; current docs confirm 50.
2. **Issue fields:** V2 mentioned "up to 25 issue fields per
   organisation" without dating; verified still 25 as of 2026-05-21
   public preview rollout to all orgs.
3. **Items per project:** V2 §2.1 did not state an items-per-project
   limit. The current limit is 50 000 (GA from public preview ~2024)
   — relevant to bulk-migration scenarios per BD-186 SC1 V7.


---

## §2 — Linear

### §2.1 — Native grouping primitives (V1)

- **Project** — named collection of issues with start/end dates, lead,
  status, and prose description. Closest match to V11.1 grouping
  semantics. Projects can be shared across multiple teams.
  ([Linear Docs: Projects](https://linear.app/docs/projects))
- **Initiative** (added 2025; widely available 2026) — higher-order
  container that organizes multiple Projects (and sub-Initiatives) at
  workspace level. Supports nesting up to **five levels deep**
  via sub-Initiatives. Auto-rolls progress from its Projects.
  ([Linear Docs: Initiatives](https://linear.app/docs/initiatives))
  ([Linear Docs: Sub-initiatives](https://linear.app/docs/sub-initiatives))
- **Custom Views** — saved filtered/sorted issue projections; not a
  grouping container per se, but a primary discovery primitive.
  ([Linear Docs: Custom Views](https://linear.app/docs/custom-views))

### §2.2 — Multi-grouping-per-issue (V2)

Confirmed multi-Project membership for issues. An issue can sit in
multiple Projects; an issue's parent Project is a single value but
issues are also movable across Projects via bulk operations. Note
the asymmetry vs GH Projects: Linear's "Project" is closer to
single-parent-with-cross-team-sharing than to GH's
overlay-per-Project model.
([Linear Docs: Projects](https://linear.app/docs/projects))

**Discrepancy from V2 baseline:** V2 §2.2 stated "yes (multi-Project
per issue)" without distinguishing Linear's parent-style Project
from GH's overlay-style Project. The architect must treat this as
SEMANTICALLY DIFFERENT from GH multi-Project membership. Linear's
multi-grouping is closer to "shared across teams within one Project"
than to "lives in N independent Projects." The Initiatives layer
gives Linear cross-project rollup that GH does not natively provide.

### §2.3 — Custom field support (V3)

- Issue custom fields: text, number, single-select, date, user,
  multi-select, and others (Linear's schema is more open than GH's).
  ([Linear Docs: Custom Views](https://linear.app/docs/custom-views) — references custom-field types)
- Custom statuses per Team (workflow customization).
  ([Storylane: How to Create Custom Statuses in Linear](https://www.storylane.io/tutorials/how-to-create-custom-statuses-in-linear))

### §2.4 — Iteration primitives (V4)

**Cycle** — time-boxed sprint-equivalent at the Team level.
Configurable length, auto-rollover of incomplete issues, velocity
tracking. ([Linear Docs: Use Cycles](https://linear.app/docs/use-cycles))

Architect mapping: Linear **Project** maps to V11.1 grouping;
Linear **Cycle** maps to V11.1 §7 phase-iteration overlay.

### §2.5 — API access (V5)

- **GraphQL only.** Endpoint: `https://api.linear.app/graphql`.
- Auth: API key (personal, 5 000 req/h) or OAuth (per-user).
- Schema explorable at [Apollo Studio (Linear API Graph)](https://studio.apollographql.com/public/Linear-API/schema/reference?variant=current).
  ([Linear Docs: API and Webhooks](https://linear.app/docs/api-and-webhooks))
  ([Linear Developers: Getting started](https://linear.app/developers/graphql))

### §2.6 — Webhook support (V6)

Resource types supported:

- Issues
- Issue comments
- Issue attachments
- Documents
- Emoji reactions
- **Projects**
- Project updates
- **Cycles**
- Labels
- Users
- Issue SLAs
- OAuthApp revoked

Webhook payload mirrors the GraphQL entity shape. Per-team or
all-public-teams scope. Webhook creation requires admin permissions
and uses `webhookCreate` mutation.
([Linear Developers: Webhooks](https://linear.app/developers/webhooks))
([Linear Docs: API and Webhooks](https://linear.app/docs/api-and-webhooks))

### §2.7 — Field / item limits (V7)

Linear documentation does not publish hard project-item or
custom-field count limits. Linear's pricing tiers gate
feature availability (e.g., Custom Views beyond a free quota on
some plans) rather than item counts.
([Linear Docs: Projects](https://linear.app/docs/projects))

Sub-initiative nesting cap: **5 levels deep**.
([Linear Docs: Sub-initiatives](https://linear.app/docs/sub-initiatives))

### §2.8 — Rate limits (V8)

- **5 000 req/h** for API-key-authenticated requests.
- **600 req/h** unauthenticated.
- Algorithm: leaky-bucket with `LIMIT_AMOUNT / LIMIT_PERIOD` refill.
- GraphQL 429: HTTP **400** (NOT 429) with `errors[].code = RATELIMITED`
  in body. Three response headers expose remaining/used quotas.
  ([Linear Developers: Rate limiting](https://linear.app/developers/rate-limiting))

**Architect-relevant gotcha:** the HTTP 400 response for rate limiting
is non-standard. Bulk-migration code must inspect response body, not
HTTP status alone.

### §2.9 — Deprecations / upcoming changes (V9)

No published deprecation timeline for Project / Cycle / Initiative
primitives. Initiatives is the most recent major addition (2025-2026
GA).

### §2.10 — Discrepancies vs V2 baseline

1. **Initiatives primitive omitted** from V2 §2.2 entirely. The V11.1
   architect should consider Linear Initiative as a third-tier grouping
   above Project (which itself is above issues), giving Linear a
   three-tier hierarchy that none of the other backends except GitLab
   nested epics provides.
2. **5-level sub-initiative nesting** — architect must decide whether
   V11.1 groupings map to flat Project list or take advantage of
   Initiative hierarchy on Linear specifically.
3. **GraphQL rate-limit HTTP status** — V2 baseline did not note the
   non-standard HTTP 400 for rate-limited responses.

---

## §3 — Jira (Cloud)

### §3.1 — Native grouping primitives (V1)

- **Epic** — Level 1 issue-type in Jira's default hierarchy (above
  Story / Task / Bug at Level 0; Subtask at Level -1). A parent
  issue whose children ARE the grouped issues (hierarchical
  parentage; NOT overlay).
  ([Atlassian Developer: Project hierarchy](https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-projects/))
- **Component** — categorical metadata; project-scoped enum;
  multi-valued per issue. Closest match to "grouping kind tag" but
  project-scoped (does not cross projects).
- **Sprint** — Jira Software-only; time-boxed iteration; requires
  origin Board.
  ([Atlassian Developer: Sprint API](https://developer.atlassian.com/cloud/jira/software/rest/api-group-sprint/))
- **Fix Version** — release-package primitive; multi-valued per issue
  (related to but distinct from Component).
- **Label** — free-text multi-valued tag (no project scope; no
  validation).

### §3.2 — Multi-grouping-per-issue (V2)

- **Epic:** **EXCLUSIVE** — an issue has ONE parent epic at a time.
  Cannot reside in multiple epics.
  ([Atlassian Support: New Parent field](https://support.atlassian.com/jira-software-cloud/docs/upcoming-changes-epic-link-replaced-with-parent/))
- **Component:** multi-valued per issue.
- **Sprint:** issues can move between sprints; one active sprint at a
  time.
- **Fix Version:** multi-valued per issue.
- **Label:** multi-valued per issue.

**Asymmetry surface:** Jira's primary grouping primitive (Epic) is
single-parent. The V11.1 §8 "phase in multiple groupings, overlap
dedup via tracker semantics" pattern DOES NOT MAP directly to Jira
Epic. Fallback options: Components (project-scoped only), Labels
(no validation), or sidecar tracking outside Jira.

### §3.3 — Custom field support (V3)

Jira supports a rich custom-field ecosystem (text, number,
single-select, multi-select, user picker, cascade, date, datetime,
URL, version picker, sprint, etc.). Custom fields are global (admin-
defined) and scoped to projects via field configurations.
([Atlassian Developer: Jira Cloud REST API v3](https://developer.atlassian.com/cloud/jira/platform/rest/v3/))

### §3.4 — Iteration primitives (V4)

**Sprint** is Jira Software's iteration primitive. Sprint API:

- `POST /rest/agile/1.0/sprint` — create
- `GET /rest/agile/1.0/sprint/{sprintId}` — get
- `GET /rest/agile/1.0/sprint/{sprintId}/issue` — list issues
- Requires `originBoardId`; supports `name`, `goal`, `startDate`,
  `endDate`, `state`.
  ([Atlassian Developer: Sprint REST API](https://developer.atlassian.com/cloud/jira/software/rest/api-group-sprint/))

### §3.5 — API access (V5)

- **Mixed REST + GraphQL.** REST is the primary surface; GraphQL is
  used for newer features.
- REST: `/rest/api/3/...` for platform; `/rest/agile/1.0/...` for
  Jira Software (sprints, epics, boards).
- Auth: API token (basic auth with email + token); OAuth 2.0 (3LO);
  Forge / Connect for apps.

### §3.6 — Webhook support (V6)

Webhooks fire for issue events including parent-link changes (epic
re-parenting), component changes, sprint changes, version changes.
WARNING: deprecation in flight — see §3.9.

### §3.7 — Field / item limits (V7)

Jira does not publish hard per-project epic / component / sprint
limits in public docs (instance-tier dependent for Data Center; Cloud
plans). Per-project label sets effectively unbounded; performance
degrades past tens of thousands of issues per project.

### §3.8 — Rate limits (V8)

- **New points-based rate limits enforced from 2026-03-02** (already
  enforced as of this doc's authoring 2026-05-23).
- **65 000 points/hour per site** (Tier 1 Global Pool, all apps share).
- Each REST/GraphQL call consumes points proportional to work
  (simple GET ~1 point; bulk search returning 100 issues much more).
- Applies to **Forge, Connect, OAuth 2.0 (3LO)** apps.
- **API-token traffic still on legacy burst limits** (not points).
- 429 returned on quota exhaustion. App migration headers
  (`Migration-App`) request elevated quotas.
  ([Atlassian Developer: Rate limiting](https://developer.atlassian.com/cloud/jira/platform/rate-limiting/))
  ([Atlassian Blog: Evolving API rate limits](https://www.atlassian.com/blog/platform/evolving-api-rate-limits))

**Architect-relevant gotcha for V11.1 bulk migration:** if the pack
uses OAuth 3LO for Jira access, bulk grouping creation MUST be
points-aware. If the pack uses API tokens, it inherits legacy burst
limits — simpler but smaller per-hour budget.

### §3.9 — Deprecations / upcoming changes (V9)

**MAJOR:** Epic Link and Parent Link custom fields are being
deprecated in REST APIs and webhooks. Replacement is a unified
**Parent field** (extending parent JQL function to cover former
epic-link, parent-link, parentEpic functions).

Specific deprecation items:

- `field` values `Epic Link` and `Parent` in issue history changelogs:
  deprecated; both old and new values returned during deprecation
  period.
  ([Atlassian Developer: Deprecation notice — issue reparenting changelogs](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-issue-reparenting-changelogs/))
- `GET /rest/agile/1.0/sprint/{sprintId}/issue` (and related sprint
  endpoints) — 6-month deprecation window; **removal after
  2026-11-01.**
  ([Atlassian Developer: Jira Software Cloud changelog](https://developer.atlassian.com/cloud/jira/software/changelog/))
- `toString` representation of sprints in `Get issue` response —
  deprecated.
  ([Atlassian Developer: toString sprints deprecation](https://developer.atlassian.com/cloud/jira/platform/deprecation-notice-tostring-representation-of-sprints-in-get-issue-response/))

**Architect-relevant gotcha:** any Jira backend implementation
SHOULD target the unified Parent field, not legacy Epic Link / Parent
Link custom fields. Sprint REST endpoints must be replaced by JQL +
issue search before 2026-11-01.

### §3.10 — Discrepancies vs V2 baseline

1. **Parent field consolidation** — V2 §2.3 cited "Epic" without
   noting the active deprecation of Epic Link / Parent Link in favor
   of unified Parent. Architect must design against unified Parent.
2. **Sprint REST endpoint removal** — V2 baseline did not flag the
   2026-11-01 removal of `/rest/agile/1.0/sprint/{sprintId}/issue`.
3. **Points-based rate limits** — V2 baseline did not flag the
   2026-03-02 enforcement of the new points-based quota system.


---

## §4 — Redmine

### §4.1 — Native grouping primitives (V1)

- **Version** — release-grouping primitive at the project level.
  Issues are assigned to a Version; the Version aggregates progress
  and dates. Closest match to V11.1 `release-package` Kind.
  ([Redmine Wiki: Rest_Versions](https://www.redmine.org/projects/redmine/wiki/Rest_Versions))
- **Issue Category** — project-scoped categorical tag for issues.
  Single-valued by default (architect-relevant — see V2).
  ([Redmine Wiki: Rest_IssueCategories](https://www.redmine.org/projects/redmine/wiki/Rest_IssueCategories))
- **Project** — top-level Redmine container; not "grouping" in the
  V11.1 sense (Redmine Project ≈ a whole product, not a grouping of
  issues within one product).

### §4.2 — Multi-grouping-per-issue (V2)

- **Version:** an issue has ONE target Version (single-valued).
  Discussion in the Redmine community has rejected multi-Version
  assignment as a design choice (statistics integrity).
  ([Redmine forums: Multiple categories for issue creation](https://www.redmine.org/boards/4/topics/39734))
- **Issue Category:** single-valued PER CORE; multi-category support
  has been requested in Feature #5220 and Feature #1189 but has not
  landed in core Redmine. Some users patch this in.
  ([Redmine Feature #5220: multi-select category](https://www.redmine.org/issues/5220))
  ([Redmine Feature #1189: Multiselect custom fields](https://www.redmine.org/issues/1189))
- **Custom fields:** multi-value support EXISTS for custom fields
  (added in Redmine 1.4.0 as `multiple = true` attribute).
  ([Redmine Wiki: Rest_CustomFields](https://www.redmine.org/projects/redmine/wiki/Rest_CustomFields))

**Asymmetry surface:** Redmine's native grouping primitives are
single-valued per issue. To support V11.1 multi-grouping semantics,
the integration would need to use multi-select custom fields
(losing native UI integration).

### §4.3 — Custom field support (V3)

Custom fields support: text, long text, integer, float, date,
boolean, list, user, version, attachment. The `multiple` attribute
enables multi-value for list-shaped fields. `searchable`,
`is_required`, `field_format`, `possible_values` attributes per
custom-field definition. The `/custom_fields` REST endpoint
requires admin privileges.
([Redmine Wiki: Rest_CustomFields](https://www.redmine.org/projects/redmine/wiki/Rest_CustomFields))

### §4.4 — Iteration primitives (V4)

**No native sprint / cycle primitive.** Versions with start/end
dates are sometimes used as sprint analogs but lack
sprint-specific semantics (no auto-rollover; no velocity).

### §4.5 — API access (V5)

- **REST only** (no GraphQL).
- Supports XML and JSON payloads.
- Auth: API key (per-user), HTTP Basic auth, or session.
- Standard endpoints: `/projects/{id}/versions.{json|xml}`,
  `/projects/{id}/issue_categories.{json|xml}`, `/issues.{json|xml}`,
  `/custom_fields.{json|xml}` (admin only).
  ([Redmine Wiki: rest_api](https://www.redmine.org/projects/redmine/wiki/rest_api))

### §4.6 — Webhook support (V6)

**No native webhooks in core Redmine.** Third-party plugins exist
(`redmine_webhook`, `redmine-plugin-webhook`); Feature #29664 and
Feature #31006 track upstream native webhook proposals (still open).
For Forgejo / Gitea-style real-time sync, the v11.1 integration
would need to depend on a specific webhook plugin or fall back to
polling.
([Redmine Feature #29664: Webhook triggers in Redmine](https://www.redmine.org/issues/29664))
([Redmine Feature #31006: Add feature Webhook](https://www.redmine.org/issues/31006))

### §4.7 — Field / item limits (V7)

- **Default REST pagination limit: 100 items per request**
  (configurable as of Patch #16069 in modern Redmine).
  ([Redmine Patch #16069: Allow configuration of API limit](https://www.redmine.org/issues/16069))
- No documented per-project Version / Category cap; effectively
  unbounded.

### §4.8 — Rate limits (V8)

No native rate limiting in core Redmine; depends on host
infrastructure (reverse proxy, Rate Plugin, etc.).
([Redmine Wiki: PluginRate](https://www.redmine.org/projects/redmine/wiki/PluginRate))

### §4.9 — Deprecations / upcoming changes (V9)

- Current released Redmine versions as of 2026-03-16: **6.1.2**,
  **6.0.9**, **5.1.12** (3 supported branches).
- No major API deprecations announced.

### §4.10 — Discrepancies vs V2 baseline

1. **Webhooks gap** — V2 §2.4 did not flag the lack of native
   webhooks. This is a material architecture constraint:
   tracker-mode bidirectional sync on Redmine MUST use polling or
   require a third-party webhook plugin.
2. **Multi-value Category status** — V2 §2.4 said "Category
   multi-valued" but Redmine core does not support this. Only custom
   fields with `multiple = true` support multi-value semantics.
   Architect must use custom fields, not Issue Category, for
   multi-grouping on Redmine.

---

## §5 — GitLab

### §5.1 — Native grouping primitives (V1)

- **Epic** (Premium+; Ultimate for nested epics historically) —
  group-level container for issues. Now represented as a **Work Item**
  (since GitLab 17.2).
  ([GitLab Docs: Epic work items API migration guide](https://docs.gitlab.com/api/graphql/epic_work_items_api_migration_guide/))
- **Milestone** — project- or group-scoped collection of issues / MRs
  / epics with a target date. Available in all tiers.
  ([GitLab Docs: Milestones](https://docs.gitlab.com/user/project/milestones/))
  ([GitLab Docs: Project milestones API](https://docs.gitlab.com/api/milestones/))
- **Iteration** (Premium+) — time-boxed sprint; group-level only
  (project-level iterations removed).
  ([GitLab Docs: Iterations](https://docs.gitlab.com/user/group/iterations/))
  ([GitLab Docs: Project iterations API](https://docs.gitlab.com/api/iterations/))
- **Label** — categorical multi-valued tag.

### §5.2 — Multi-grouping-per-issue (V2)

- **Epic:** issues belong to ONE epic at a time; nested epics give
  hierarchical (not overlay) multi-membership.
- **Milestone:** issue has ONE milestone at a time.
- **Iteration:** issue has ONE iteration at a time.
- **Label:** multi-valued per issue.

### §5.3 — Custom field support (V3)

Issue custom fields exist; rich type support via Work Item widgets
(epic, hierarchy, health status, weight, iteration, milestone,
labels, assignees). Custom fields are evolving toward the Work Item
widget model.

### §5.4 — Iteration primitives (V4)

**Iteration** is GitLab's sprint primitive. Group-level only (since
project-level iterations were removed). Available in Premium and
Ultimate tiers.
([GitLab Docs: Project iterations API](https://docs.gitlab.com/api/iterations/))

### §5.5 — API access (V5)

- **Mixed REST + GraphQL.** GraphQL is the strategic surface; REST
  remains for legacy and stable operations.
- Auth: PAT (`api` scope), OAuth, deploy tokens.

### §5.6 — Webhook support (V6)

Issue, MR, epic, milestone events all webhook-emit. Epic webhooks
exist for epic-link changes (deprecated; see V9).

### §5.7 — Field / item limits (V7)

No documented per-group epic / milestone count cap. Per-instance
limits exist for self-hosted (admin-configurable).

### §5.8 — Rate limits (V8)

GitLab Cloud: configurable per instance; default is conservative
(roughly 600 req/min authenticated for gitlab.com). Self-hosted
admin-configurable.

### §5.9 — Deprecations / upcoming changes (V9)

**MAJOR:** Epic REST + GraphQL APIs deprecated; Work Items API is
the replacement.

Timeline:

- **GitLab 17.0** — Epics REST API deprecated (planned for removal
  in API v5).
- **GitLab 17.2** — Epics introduced as Work Items.
- **GitLab 18.1** — Work Item API generally available; feature flag
  `work_item_epics` removed.
- **GitLab 19.0** — Epic GraphQL API planned removal.
  ([GitLab Docs: Epics API (deprecated)](https://docs.gitlab.com/api/epics/))
  ([GitLab Docs: Epic Issues API (deprecated)](https://docs.gitlab.com/api/epic_issues/))
  ([GitLab Docs: Linked epics API (deprecated)](https://docs.gitlab.com/api/linked_epics/))
  ([GitLab Docs: Epic Links API (deprecated)](https://docs.gitlab.com/api/epic_links/))
  ([GitLab Docs: Epic work items API migration guide](https://docs.gitlab.com/api/graphql/epic_work_items_api_migration_guide/))
  ([GitLab issue 460668: Epics REST API to be deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/460668))

**Architect-relevant gotcha:** ANY GitLab backend implementation
MUST target the Work Items API (GraphQL) for new code. Epic-specific
REST/GraphQL endpoints are end-of-life. The IID (group-scoped ID)
remains stable between epic and work-item representations; the
internal ID changes.

### §5.10 — Tier restriction summary

| Feature | Free | Premium | Ultimate |
|---|---|---|---|
| Issues | yes | yes | yes |
| Milestones (project + group) | yes | yes | yes |
| Epics | **no** | yes | yes |
| Iterations | **no** | yes | yes |
| Nested Epics (sub-epics) | no | yes (Premium gets the basic; check current docs) | yes |

(GitLab tier matrix moves frequently; verify against current pricing
page at integration time.)

### §5.11 — Discrepancies vs V2 baseline

1. **Epic API deprecation timeline** — V2 §2.5 cited "deprecated per
   GitLab Epics API docs — migration TBD." Current docs show a
   concrete timeline (17.0 / 17.2 / 18.1 / 19.0).
2. **Project iteration removal** — V2 baseline did not note that
   project-level iterations no longer exist; only group-level.
3. **Work Items as the unified surface** — V2 §2.5 named separate
   primitives. Current GitLab strategy is Work Items as a single
   typed surface with widgets per type.

---

## §6 — Forgejo / Gitea

### §6.1 — Native grouping primitives (V1)

- **Milestone** — issue-grouping primitive at the repository level
  with a due date. Auto-calculates completion percentage from
  open/closed counts.
  ([DeepWiki: Gitea Issue Management](https://deepwiki.com/go-gitea/gitea/5.1-issue-management-system))
- **Project board** — kanban-style board at repo or organization
  scope. A "Project" in Forgejo / Gitea terminology IS a kanban
  board, not a GitHub Project v2-style typed overlay.
  ([Forgejo Docs: Projects](https://forgejo.org/docs/next/user/project/))
- **Label** — multi-valued categorical tag per issue.

### §6.2 — Multi-grouping-per-issue (V2)

- **Milestone:** an issue has ONE milestone at a time (single-valued).
- **Project board:** an issue currently CANNOT belong to multiple
  Projects — Forgejo issue #2462 tracks the open feature request.
  ([Forgejo Issue #2462: Multiple Projects Per Issue](https://codeberg.org/forgejo/forgejo/issues/2462))
- **Label:** multi-valued per issue.

**Asymmetry surface (sharpest of any backend):** Forgejo / Gitea has
the most restrictive grouping primitive. To support V11.1
multi-grouping semantics, the integration must use Labels (no
validation, no structure) or accept a degraded surface with
sidecar-only metadata.

### §6.3 — Custom field support (V3)

**No custom fields** in Forgejo / Gitea core today. Labels are the
primary metadata extension. This is a fundamental capability gap
versus the other backends.

### §6.4 — Iteration primitives (V4)

**No native sprint / cycle primitive.** Milestones with due dates
are sometimes used as sprint analogs but lack iteration semantics.

### §6.5 — API access (V5)

- **REST only.** GitHub-API-compatible surface (Gitea heritage); most
  integrations that target GH REST work on Gitea / Forgejo with
  endpoint base swap.
- Auth: PAT, basic auth, OAuth.
  ([Gitea Docs: API](https://docs.gitea.com/api/))

### §6.6 — Webhook support (V6)

Repo-scoped, org-scoped, and instance-wide webhooks supported.
Events include issue lifecycle, milestone changes.

**Known issue:** webhooks for issue events created or modified via
the API do NOT fire (UI-only trigger). This is documented at
Forgejo issue #7655.
([Forgejo Issue #7655: Webhooks for issue events not sent when using the API](https://codeberg.org/forgejo/forgejo/issues/7655))

**Architect-relevant gotcha:** any pack-driven (API-side) state
change on Forgejo / Gitea will NOT emit a webhook. Bidirectional
sync via webhook is broken for pack-side writes; only human-UI
writes propagate via webhook. Polling is required for catching
pack-side writes.

### §6.7 — Field / item limits (V7)

No documented per-repo milestone / label cap; effectively unbounded.

### §6.8 — Rate limits (V8)

Native API rate limiting was proposed at Gitea issue #9559; current
status: configurable per instance, default off (admin-tuned).
Typical pattern mirrors GitHub: 5 000 req/h authenticated, 60 req/h
unauthenticated, when limits are enabled.
([Gitea Issue #9559: Feature API rate limiting](https://github.com/go-gitea/gitea/issues/9559))

### §6.9 — Deprecations / upcoming changes (V9)

- Forgejo v14.0 released 2026-01 introduced inline issue-search
  filters, web-editor refresh, stateless CSRF.
  ([European Purpose: Forgejo Review 2026](https://europeanpurpose.com/tool/forgejo))
- No major API deprecations announced for the milestone / project
  primitives.

### §6.10 — Discrepancies vs V2 baseline

1. **Multi-Project-per-issue** — V2 §2.6 said "no (one milestone per
   issue)" which is correct, but did not flag that **Project boards
   ALSO cannot be multi-membership**. Forgejo issue #2462 confirms.
2. **API-write webhook gap** — V2 baseline did not flag the
   UI-vs-API webhook asymmetry. This is a load-bearing constraint
   for any tracker-mode bidirectional design.
3. **No custom fields** — V2 §2.6 said "labels only" in the matrix
   (correct), but did not surface that this means the V11.1
   `Kind` enum cannot land as a typed field on Forgejo; it must be
   emulated by label namespace.


---

## §7 — Cross-backend comparison matrix (Pass-2: 0-5 graded)

This section replaces the Pass-1 textual matrix with a 0-5 graded
comparison covering 10 backends (the 6 Pass-1 backends + 4 Tier-1
Pass-2 additions). Tier-2 (§14) and Tier-3 (§15) backends are NOT
in this matrix; their nuance lives in their respective text
sections.

### §7.1 — Reading the matrix

**Grade scale (0-5):**

```
0 = not supported at all
1 = supported only via emulation/hacks (significant complexity / labels-only)
2 = supported with major caveats (e.g., single-valued where multi expected)
3 = supported with minor caveats (e.g., tier-restricted, paid plan only, deprecated API still working)
4 = full native support with minor edge cases
5 = full native support, no caveats, mature API
```

**Two column groups:**

- **Graded columns** (0-5 numeric): `native_grouping`, `multi_per_item`,
  `custom_fields`, `iterations`, `webhooks`, `api_maturity`,
  `bulk_operations`. Single integer per cell.
- **Notes columns** (text/value): `field_limit`, `api_type`,
  `tier_restriction`, `rate_limit`, `recent_deprecations`. Brief text.

For deeper nuance behind any grade, read the per-backend section
(§1-§6 for Pass-1 backends; §10-§13 for Tier-1 Pass-2 backends).
Grades reflect that section's V1-V10 findings translated onto a
calibrated 0-5 scale; per-cell justification is one section read
away.

### §7.2 — Graded columns

| Backend | native_grouping | multi_per_item | custom_fields | iterations | webhooks | api_maturity | bulk_operations |
|---|---:|---:|---:|---:|---:|---:|---:|
| GitHub (Projects v2) | 5 | 5 | 4 | 5 | 4 | 5 | 4 |
| Linear | 5 | 4 | 5 | 5 | 5 | 5 | 4 |
| Jira (Cloud) | 4 | 2 | 5 | 4 | 3 | 4 | 3 |
| Redmine | 3 | 1 | 4 | 1 | 1 | 3 | 2 |
| GitLab | 3 | 1 | 4 | 3 | 4 | 3 | 3 |
| Forgejo / Gitea | 2 | 0 | 0 | 0 | 2 | 3 | 2 |
| Azure DevOps Boards | 4 | 2 | 5 | 4 | 4 | 5 | 3 |
| YouTrack | 4 | 3 | 5 | 5 | 4 | 4 | 3 |
| Asana | 5 | 5 | 4 | 1 | 3 | 4 | 3 |
| ClickUp | 4 | 4 | 5 | 3 | 4 | 4 | 3 |

### §7.3 — Notes columns

| Backend | field_limit | api_type | tier_restriction | rate_limit | recent_deprecations |
|---|---|---|---|---|---|
| GitHub (Projects v2) | 50 fields/project; 50 000 items/project; 25 issue fields/org; 50 single-select options | GraphQL | none (Projects v2 in all plans) | 5 000 GraphQL pts/h authenticated | webhook payload "public preview, subject to change" |
| Linear | none documented; sub-initiative nesting cap 5 | GraphQL | feature-gating on free vs paid | 5 000 req/h (HTTP 400 not 429 on rate-limit) | none material |
| Jira (Cloud) | none documented | mixed REST + GraphQL | Sprint requires Jira Software | 65 000 pts/h per site (OAuth/Forge/Connect); legacy burst for API tokens | yes — Epic Link/Parent Link deprecated; sprint REST endpoints removal **2026-11-01**; points-based quotas enforced from **2026-03-02** |
| Redmine | 100 items/request default (configurable) | REST (JSON + XML) | none (open source) | varies (host-dependent; no native rate limit) | none material |
| GitLab | self-hosted admin-configurable | mixed REST + GraphQL | **Epic + Iteration are Premium+/Ultimate** | gitlab.com ~600 req/min; self-hosted configurable | yes — Epic REST deprecated 17.0; Epic GraphQL planned removal **GitLab 19.0**; project-level iterations removed |
| Forgejo / Gitea | none documented | REST (GH-compatible) | none (open source) | 5 000 req/h authenticated when enabled; self-hosted configurable | none material; **API-side writes do NOT emit webhooks** (Forgejo issue #7655) |
| Azure DevOps Boards | 10 000 iteration paths/project; 300 paths/team; 2 MB webhook payload | REST | none (Basic plan ok) | ~200 TSTUs / 5-minute sliding window (composite metric) | none material |
| YouTrack | none documented | REST | license-tier (user count) | not publicly documented (adaptive back-off recommended) | none material; 2026.1 added Hub-API parity (additive) |
| Asana | 150 custom fields/project | REST | **custom fields are Premium+** | 150 req/min Free; 1 500 req/min Premium+ | none material |
| ClickUp | none documented (plan-gated features) | REST | multi-list feature plan-gated | 100 req/min Free/Unlimited/Business; 1 000 Business Plus; 10 000 Enterprise | none material |

### §7.4 — Calibration notes (load-bearing for re-grades)

Grade rationale for selected hard-call cells, anchoring the scale
consistently across columns and backends:

- **GH multi_per_item = 5** — native overlay; one issue in N projects
  with per-project field values; mature.
- **Linear multi_per_item = 4** — issues movable across projects +
  Initiatives hierarchy (5-level nest); semantically closer to
  parent-with-cross-team than GH overlay; minor edge cases.
- **Jira multi_per_item = 2** — Epic exclusive parent (major caveat
  for V11.1 §8 dedup pattern); Component / Fix Version / Label
  multi-valued; mixed grade reflects "main hierarchy primitive is
  single but ancillary primitives multi-valued."
- **Redmine multi_per_item = 1** — native primitives (Version, Issue
  Category) single-valued; emulation via `multiple = true` custom
  fields possible but loses native UI.
- **GitLab multi_per_item = 1** — Epic / Milestone / Iteration all
  single-valued; only Label is multi-valued; heavy emulation needed
  for V11.1 multi-grouping.
- **Forgejo multi_per_item = 0** — no native multi-grouping; no
  custom-field framework to emulate with; labels-only as workaround
  is the closest available.
- **Azure DevOps multi_per_item = 2** — Work Item parent / Area Path /
  Iteration Path all single-valued; tag is the only multi-valued
  primitive; same shape as Jira but with hierarchical paths instead
  of flat epics.
- **YouTrack multi_per_item = 3** — Sprint can span projects (uncommon
  capability); Project ownership is single-valued; query-defined
  agile boards give filter-based multi-membership but not
  explicit-assignment. Mixed grade reflecting the partial-native /
  partial-emulation surface.
- **Asana multi_per_item = 5** — tasks live in 0..N projects natively
  (multi-homing); per-project section + custom-field-value overlay
  semantically equivalent to GH's per-Project values.
- **ClickUp multi_per_item = 4** — "Tasks in Multiple Lists" feature
  provides multi-homing similar to Asana; minor caveat: plan-gated
  availability (not on all tiers).
- **webhooks = 0 for Redmine** — not native to core; requires
  third-party plugin OR polling.
- **webhooks = 2 for Forgejo** — native exists but API-side writes
  do NOT emit webhooks (issue #7655); a fundamental coverage gap.
- **iterations = 0 for Forgejo** — no native sprint primitive; not
  even emulated via dated milestones at first-class.
- **iterations = 1 for Asana** — no native sprint primitive; emulation
  via dated Projects or sub-Projects per sprint is awkward but
  achievable.
- **iterations = 1 for Redmine** — Versions sometimes used as sprint
  analogs but lack iteration semantics (no velocity, no auto-rollover).
- **api_maturity = 3 for Forgejo, GitLab, Redmine** — REST surface
  works but has gaps or rapid churn (GitLab in Epic→WorkItems
  migration; Forgejo API-write-webhook gap; Redmine no native
  webhooks). Grade reflects "usable but with sharp edges."
- **bulk_operations = 2 for Forgejo, Redmine** — no published rate
  limits but no published bulk-import APIs either; have to
  paginate / loop. Grade reflects "works but no bulk-optimized
  path."

### §7.5 — Information that moved from Pass-1 textual matrix

The Pass-1 textual matrix carried per-cell qualifying prose
("yes (overlay; one issue in N projects with per-project values)").
That detail is no longer in §7 — it lives in the per-backend
sections (§1-§6, §10-§13) which §7.1 instructs the reader to
consult. No information is lost; the matrix is glanceable + the
text sections are authoritative.

---

## §8 — Architect-relevant gotchas summary

The following per-backend gotchas are load-bearing for the V11.1
capability matrix + graceful-degradation design. They are extracted
from the per-section discussions above for cross-reference at
architect-pass time.

### §8.1 — Active or imminent deprecations

| Backend | Surface | Status | Timeline |
|---|---|---|---|
| Jira | Epic Link, Parent Link custom fields | Deprecating | Both values returned during deprecation; replace with unified Parent field |
| Jira | `/rest/agile/1.0/sprint/{sprintId}/issue` and related sprint REST endpoints | Deprecation period 6 months | **Removal after 2026-11-01** |
| Jira | API-token vs OAuth/Forge/Connect quotas split | Enforced | **From 2026-03-02** points-based quotas for non-API-token apps |
| GitLab | Epics REST API | Deprecated GitLab 17.0 | Removal in API v5 |
| GitLab | Epic GraphQL API | Deprecated | Removal **GitLab 19.0** |
| GitHub | Projects v2 webhook payloads | "Public preview, subject to change" | No removal but breaking-change risk |

### §8.2 — Tier / plan restrictions

| Backend | Restriction | Effect on V11.1 |
|---|---|---|
| GitLab | Epic + Iteration are Premium+/Ultimate; Milestones in all tiers | Free-tier GitLab users can ONLY use Milestones as grouping; capability matrix degrades. |
| Linear | Custom views beyond free quota gated | Feature parity but at premium tiers. |
| Jira | Sprint is Jira Software (vs Jira Work Management) | Sprint integration only when Software is enabled. |

### §8.3 — Authentication asymmetries

| Backend | Auth surface |
|---|---|
| GitHub | PAT, GitHub App installation token, OAuth user token |
| Linear | API key (per-user), OAuth |
| Jira | API token (basic auth with email + token), OAuth 2.0 (3LO), Forge / Connect |
| Redmine | API key, HTTP Basic, session |
| GitLab | PAT, OAuth, deploy tokens |
| Forgejo / Gitea | PAT, basic auth, OAuth |

**Architect implication:** the BD-060 TrackerProvider abstraction
already supports auth shape per backend; v11.1 must not assume a
single auth model. Bulk migration scenarios are particularly
sensitive — see Jira's points-based quotas for token-vs-OAuth split.

### §8.4 — Semantic asymmetries blocking multi-backend portability

| Asymmetry | Backends affected | V11.1 portability impact |
|---|---|---|
| Multi-grouping-per-item native vs single-parent | GH (overlay) + Linear (cross-team) vs Jira (Epic exclusive) + Redmine (Version single) + GitLab (Epic single) + Forgejo (Milestone single + Project single) | The V11.1 §8 "phase in N groupings, dedup via tracker semantics" pattern is **GH-native + Linear-near-native**; all others require label-namespace emulation or sidecar tracking |
| Custom-field support | GH + Linear + Jira + Redmine + GitLab support custom fields; Forgejo / Gitea do NOT | Kind enum cannot land as a typed field on Forgejo; must use label namespace |
| Iteration primitive present | GH (Iteration field) + Linear (Cycle) + Jira (Sprint) + GitLab (Iteration) | Redmine + Forgejo / Gitea have no native iteration; emulation via Versions / Milestones with start/end dates |
| Webhook emission on API writes | GH + Linear + Jira + GitLab emit on API writes | Forgejo / Gitea do NOT emit webhooks for API-initiated writes (issue #7655) — bidirectional sync requires polling on these backends |
| Native webhooks at all | All except Redmine | Redmine requires third-party webhook plugin or polling |

### §8.5 — Bulk-migration considerations

| Backend | Rate-limit budget for bulk grouping creation |
|---|---|
| GitHub | 5 000 GraphQL points/h authenticated; complex mutations more expensive |
| Linear | 5 000 req/h authenticated; HTTP 400 (not 429) for rate-limited |
| Jira | 65 000 points/h per site for OAuth/Forge/Connect; legacy burst for API tokens; **points-based since 2026-03-02** |
| Redmine | No native rate limit; host-infrastructure dependent |
| GitLab | gitlab.com ~600 req/min authenticated; self-hosted configurable |
| Forgejo / Gitea | 5 000 req/h authenticated (when enabled); self-hosted configurable |

### §8.6 — Items not covered

Items the architect must resolve but this research does not pre-
specify:

- The mapping from V11.1 `Kind` enum to per-backend native primitive
  (e.g., does `release-package` land as GH Project + Linear Project +
  Jira Fix Version + Redmine Version + GitLab Milestone + Forgejo
  Milestone, or as a uniform label namespace, or some hybrid?).
- The fallback strategy for single-valued backends (Jira / Redmine /
  GitLab / Forgejo) when V11.1 §8 multi-grouping semantics are used:
  emulation via labels (lossy but portable) vs sidecar-only metadata
  (lossless but tracker-invisible) vs feature-degrade with explicit
  per-backend documentation.
- The threshold for declaring a backend "supported" vs "reserved" vs
  "graceful-degradation only" in the capability matrix.
- The provider-portability test surface (round-trip property tests
  per backend; see V2 inventory §3.K test-fixture rows).

---

## §9 — Appendix: source-of-truth snapshot

All URLs verified live at authoring time (2026-05-23 US/Pacific).
Each in-text citation links a primary source (vendor docs, GitHub
community discussion, GitLab issues, Codeberg / Atlassian developer
docs). The architect should re-verify URLs at architect-pass time
(BD-186 spec carries no SLA on third-party doc URL stability).

Primary documentation portals used:

- GitHub: https://docs.github.com/en/issues + https://github.blog/changelog
- Linear: https://linear.app/docs/ + https://linear.app/developers/
- Atlassian (Jira): https://developer.atlassian.com/cloud/jira/
- Redmine: https://www.redmine.org/projects/redmine/wiki/
- GitLab: https://docs.gitlab.com/ + https://gitlab.com/gitlab-org/gitlab/
- Forgejo: https://forgejo.org/docs/ + https://codeberg.org/forgejo/
- Gitea: https://docs.gitea.com/ + https://github.com/go-gitea/gitea/

### §9.1 — Pass-2 additional portals

Tier-1 (full V1-V10 sections §10-§13) and Tier-2 (§14 surveys) sources:

- Microsoft (Azure DevOps): https://learn.microsoft.com/en-us/azure/devops/ + https://learn.microsoft.com/en-us/rest/api/azure/devops/
- JetBrains (YouTrack): https://www.jetbrains.com/help/youtrack/devportal/ + https://www.jetbrains.com/help/youtrack/cloud/
- Asana: https://developers.asana.com/docs/ + https://forum.asana.com/ + https://help.asana.com/
- ClickUp: https://developer.clickup.com/docs/ + https://help.clickup.com/
- Notion: https://developers.notion.com/reference/ + https://www.notion.com/help/
- monday.com: https://developer.monday.com/api-reference/
- OpenProject: https://www.openproject.org/docs/api/
- Trello: https://developer.atlassian.com/cloud/trello/
- Phorge: https://we.phorge.it/ (community-maintained; Wikipedia for legacy context)
- Bugzilla: https://bugzilla.readthedocs.io/
- MantisBT: https://mantisbt.org/ + https://support.mantishub.com/api/
- Taiga: https://docs.taiga.io/
- Bitbucket Issues: https://developer.atlassian.com/cloud/bitbucket/ + https://community.atlassian.com/ (sunset bulletin)
- Sourcehut: https://docs.sourcehut.org/ + https://sourcehut.org/blog/

### §9.2 — Pass-2 §8 gotchas addendum (logical extension of §8; physically located here for proximity)

The following Pass-2-introduced gotchas extend §8.1-§8.6. Read in
conjunction with the original §8 tables; do not treat this addendum
as standalone. The §8.X numbering below is logical (continuing §8.1-§8.6); physical location is under §9 to keep all Pass-2 additions contiguous.

**§8.7 — Pass-2 Tier-1 active or imminent deprecations**

| Backend | Surface | Status | Timeline |
|---|---|---|---|
| Bitbucket Issues | Issue Tracker REST API (`/repositories/{ws}/{repo}/components` and all Issue Tracker endpoints) | **Sunset announced** | **Removal mid-August 2026 (2026-08-20)** — Atlassian recommends migrating to Jira. See §14.9. |
| Pivotal Tracker | Entire service | **Decommissioned** | **2025-04-30** — no longer available. See §15.1. |
| Notion | `database.schema_updated` event (API 2022-06-28) | Deprecated | Replaced by `data_source.schema_updated` (API 2025-09-03) |

**§8.8 — Pass-2 Tier-1 tier / plan restrictions**

| Backend | Restriction | Effect on V11.1 |
|---|---|---|
| Asana | Custom fields are Premium+ (not Free) | Free-tier Asana users cannot project V11.1 `Kind` enum onto typed fields; tags become the fallback |
| Asana | Portfolios are Business+ | Higher-tier feature for hierarchical grouping |
| ClickUp | Multi-list ("Tasks in Multiple Lists") plan-gated | Free-tier ClickUp users degrade to single-list per task |
| ClickUp | Rate-limit tiers (100 / 1 000 / 10 000 req/min) | Free-tier bulk migration is the slowest of any Tier-1 backend |
| YouTrack | License-tier user-count gating | Cloud and Server both gate via user count, not via API feature |
| Azure DevOps | Microsoft Entra (Azure AD) auth federation | Enterprise auth requirements not present on the open-source / freemium backends |

**§8.9 — Pass-2 Tier-1 authentication asymmetries**

| Backend | Auth surface (Pass-2 additions) |
|---|---|
| Azure DevOps | PAT, OAuth 2.0 (Microsoft Entra), Azure DevOps Services tokens, Azure AD federated identity |
| YouTrack | Permanent token (per-user) or OAuth 2.0 |
| Asana | PAT, OAuth 2.0 |
| ClickUp | Personal token, OAuth 2.0 |

Including these in the BD-060 TrackerProvider auth shape brings the
adapter count to 10 distinct auth-model surfaces across the matrix.

**§8.10 — Pass-2 Tier-1 semantic asymmetries**

| Asymmetry | Pass-2 backends added to existing gotcha | V11.1 portability impact |
|---|---|---|
| Multi-grouping-per-item native | Asana (5) + ClickUp (4) join GH (5) + Linear (4) as overlay-or-near-overlay backends | The "native-overlay" set is now 4 backends (GH + Linear + Asana + ClickUp), not just GH+Linear |
| Single-valued primary primitive | Azure DevOps joins Jira + Redmine + GitLab + Forgejo as single-valued-primary backends | 5 of 10 graded backends have single-valued primary; emulation strategy for V11.1 §8 dedup must cover this majority |
| Hierarchical container paths | Azure DevOps (Area Path + Iteration Path are trees) + ClickUp (Workspace / Space / Folder / List) introduce path-based hierarchy unfamiliar to GH/Linear/Forgejo readers | V11.1 grouping spec must declare a "tree-flatten" rule or admit per-backend tree-aware mappings |
| Sprint-across-projects native | YouTrack — uncommon capability; Jira sprints are board-scoped, others single-project | Architect can opt to exploit on YouTrack or constrain to single-project semantics for portability |
| Webhook delivery latency | Asana up to **10 minutes typical** vs near-real-time on GH / Linear / GitLab | Bidirectional-sync tightness varies by backend |
| Query-defined boards (filter-based) | YouTrack agile boards (filter-based membership, not explicit assignment) | V11.1 grouping abstraction on YouTrack agile boards is effectively a saved filter |

**§8.11 — Pass-2 Tier-1 bulk-migration considerations**

| Backend | Rate-limit budget for bulk grouping creation |
|---|---|
| Azure DevOps | ~200 TSTUs per 5-minute sliding window; composite metric — single heavy queries can spend many TSTUs; throttle via response headers |
| YouTrack | No publicly documented hard limits; adaptive back-off recommended |
| Asana | 150 req/min Free; 1 500 req/min Premium+ |
| ClickUp | 100 req/min Free/Unlimited/Business; 1 000 Business Plus; 10 000 Enterprise — tightest free-tier limit in matrix |

**§8.12 — Pass-2 deferred items**

Items the architect must resolve, augmenting Pass-1 §8.6:

- Whether V11.1 supports any Tier-2 backend (§14) at first ship —
  Phorge / OpenProject / Taiga have non-trivial userbases and clean
  grouping primitives; Trello has overwhelming reach but kanban-only
  semantics.
- Whether the pack supports Bitbucket Issues (§14.9) at all given
  the 2026-08-20 sunset — recommendation: NO, exclude from
  capability matrix entirely.
- The TSTU translation table for Azure DevOps bulk migration —
  TSTU costs per work-item-create / area-path-update / iteration-
  path-update are not publicly published; would require empirical
  measurement.
- The grading-scale recalibration discipline — Pass-2 grades are
  authored from Pass-1 + Pass-2 V1-V10 sub-sections; future passes
  must re-grade against the same V1-V10 evidence to keep the matrix
  comparable.

---

# Pass-2 extension — additional backends + matrix refactor

**Pass-2 authored:** 2026-05-23 (US/Pacific).
**Pass-2 HEAD at extension start:** e35236b701cd3048017a6c9ebcfcb264f0236311 —
feat: v11 — BD-173 PM-CHAT.md source-edit discipline (Batch 19c.3).
**Pass-2 scope:** add 4 Tier-1 backends with full V1-V10 structure
(§10-§13); 10 Tier-2 brief surveys (§14); Tier-3 sunset footnote (§15);
refactor §7 to 0-5 graded matrix; extend §8 gotchas with Tier-1
material.

§7 below is replaced in place by the graded matrix. §1-§6 remain
unchanged from Pass-1; §8-§9 retain their Pass-1 content with the
Pass-1 6-backend gotchas plus a Pass-2 Tier-1 addendum (§8 column
appended; §9 source-portal list appended).

---

## §10 — Azure DevOps Boards (Microsoft)

### §10.1 — Native grouping primitives (V1)

Azure DevOps Boards is Microsoft's enterprise tracker layer (part of
Azure DevOps Services for cloud and Azure DevOps Server for on-prem).
Three orthogonal grouping primitives:

- **Work Item hierarchy** — Epic / Feature / User Story / Task / Bug
  in the **Agile** process; Epic / Feature / Product Backlog Item /
  Task / Bug in **Scrum**; Epic / Feature / Requirement / Change
  Request / Task in **CMMI**; Epic / Issue / Task in **Basic**.
  Parent-child relationships create the hierarchy.
  ([Microsoft Learn: About work items and work item types](https://learn.microsoft.com/en-us/azure/devops/boards/work-items/about-work-items?view=azure-devops))
  ([Microsoft Learn: Define features and epics](https://learn.microsoft.com/en-us/azure/devops/boards/backlogs/define-features-epics?view=azure-devops))
- **Area Path** — hierarchical tree of organizational nodes
  (typically team / sub-team / product / feature area) assigned to
  work items. Single-valued per work item.
  ([Microsoft Learn: About areas and iterations](https://learn.microsoft.com/en-us/azure/devops/organizations/settings/about-areas-iterations?view=azure-devops))
- **Iteration Path** — hierarchical tree of time-boxed periods
  (release / sprint / milestone). Single-valued per work item; up to
  **10 000 iteration paths per project**; up to **300 paths assigned
  to a single team**.
  ([Microsoft Learn: Define iteration paths and configure team iterations](https://learn.microsoft.com/en-us/azure/devops/organizations/settings/set-iteration-paths-sprints?view=azure-devops))
- **Tag** — free-text multi-valued label.

### §10.2 — Multi-grouping-per-issue (V2)

- **Work Item parent:** ONE parent at a time (Epic → Feature →
  Story → Task). Hierarchical, exclusive.
- **Area Path:** single-valued.
- **Iteration Path:** single-valued.
- **Tag:** multi-valued.

**Asymmetry surface:** Azure DevOps's grouping primitives are
single-valued except for tags. The V11.1 §8 multi-grouping pattern
must rely on tag namespace or sidecar tracking for multi-membership.

### §10.3 — Custom field support (V3)

Rich. Inherited or custom process templates support adding fields
to any work item type with types: String, Integer, Double, DateTime,
Boolean, PlainText, HTML, TreePath, History, Identity, PicklistString.
Per-process or per-organization scope.
([Microsoft Learn: Customize a process](https://learn.microsoft.com/en-us/azure/devops/organizations/settings/work/customize-process?view=azure-devops))

### §10.4 — Iteration primitives (V4)

**Iteration Path** is the native sprint primitive. Sprint cadence is
configurable (per-team). Endpoint `GET/PATCH /work/teamsettings/iterations`.
([Microsoft Learn: Iterations - List](https://learn.microsoft.com/en-us/rest/api/azure/devops/work/iterations/list?view=azure-devops-rest-7.1))

### §10.5 — API access (V5)

- **REST only** for primary surface; some GraphQL availability via
  Microsoft Graph for organizational metadata (not work-item).
- REST base: `https://dev.azure.com/{organization}/...`; version
  selector via `api-version=7.1` query parameter or header.
- Auth: PAT (Personal Access Token), OAuth 2.0 (Microsoft Entra),
  Azure DevOps Services tokens, Azure AD federated identity.
  ([Microsoft Learn: Work REST API](https://learn.microsoft.com/en-us/rest/api/azure/devops/work/?view=azure-devops-rest-7.1))

### §10.6 — Webhook support (V6)

**Service Hooks** is the webhook framework. Supported events
include work item created / updated / commented / deleted, code push,
build complete, release deployment, etc. Maximum payload **2 MB per
webhook event**. Subscriptions in "frequent failure" state may be
auto-disabled.
([Microsoft Learn: Webhooks with Azure DevOps](https://learn.microsoft.com/en-us/azure/devops/service-hooks/services/webhooks?view=azure-devops))
([Microsoft Learn: Integrate with Service Hooks](https://learn.microsoft.com/en-us/azure/devops/service-hooks/overview?view=azure-devops))

### §10.7 — Field / item limits (V7)

| Limit | Value |
|---|---|
| Iteration paths per project | **10 000** |
| Iteration paths assigned to one team | **300** |
| Webhook payload max | **2 MB** |

No published per-project work-item limit, area-path limit, or tag
limit (effectively unbounded; performance-bounded).
([Microsoft Learn: About areas and iterations](https://learn.microsoft.com/en-us/azure/devops/organizations/settings/about-areas-iterations?view=azure-devops))

### §10.8 — Rate limits (V8)

Sliding 5-minute window of **~200 TSTUs** (Throughput Service Time
Units) per user / pipeline globally. Response headers
`X-RateLimit-Resource`, `X-RateLimit-Limit`, `X-RateLimit-Remaining`,
`X-RateLimit-Delay`, `Retry-After` provide back-pressure metadata.
([Microsoft Learn: REST API rate limits](https://learn.microsoft.com/en-us/azure/devops/integrate/concepts/rate-limits?view=azure-devops))

**Architect-relevant gotcha:** TSTU is a composite metric — a single
heavy query can spend many TSTUs. Bulk grouping creation must throttle
explicitly using the response headers, not request-count heuristics.

### §10.9 — Deprecations / upcoming changes (V9)

No major work-item or iteration-path deprecations announced for 2026.
REST API v7.1 is current; v7.2 in preview. Microsoft Entra (Azure AD)
auth tightening is ongoing but not affecting work-item endpoints
specifically.

### §10.10 — Discrepancies vs Pass-1 / V2 baseline

Not in Pass-1 or V2 baseline at all. Pass-2 fills the Azure DevOps
gap. Architect-relevant facts that change V11.1 design space:

1. **Enterprise userbase consideration** — Azure DevOps is the
   default tracker for many Microsoft-ecosystem orgs; V11.1 capability
   matrix excluding it would limit pack reach.
2. **Iteration Path hierarchy** — Azure DevOps's IterationPath is a
   *hierarchical* tree (e.g., Release 1 / Sprint 5), unlike GH
   Iteration field (flat list with dates). The V11.1 §7 phase-iteration
   overlay must handle hierarchical iteration paths on this backend.
3. **TSTU rate-limit model** — opaque cost-per-call metric; harder to
   pre-budget for bulk migration than Linear's clean req/h or GH's
   point-cost system.

---

## §11 — YouTrack (JetBrains)

### §11.1 — Native grouping primitives (V1)

YouTrack is JetBrains' issue tracker (Cloud + on-prem Server).
Primitives:

- **Project** — top-level container (similar to Jira project; each
  project carries its own custom-field schema, workflow, board, and
  permissions).
  ([JetBrains Help: YouTrack REST API](https://www.jetbrains.com/help/youtrack/devportal/youtrack-rest-api.html))
- **Agile board** — issue board overlay; multiple projects can share
  one board.
  ([JetBrains Help: Agiles API resource](https://www.jetbrains.com/help/youtrack/devportal/resource-api-agiles.html))
- **Sprint** — sub-resource of an agile board; can include issues
  from **multiple projects** (notable cross-project capability).
  ([JetBrains Help: Operations with Specific Sprint](https://www.jetbrains.com/help/youtrack/devportal/operations-api-agiles-agileID-sprints.html))
- **Issue link types** — typed associations (parent, subtask, relates,
  duplicates) — relationship-based grouping.

### §11.2 — Multi-grouping-per-issue (V2)

- **Project:** an issue has ONE owning project (move via API requires
  the operations-API-issues-issueID-project endpoint).
  ([JetBrains Help: Operations with Specific Issue Project](https://www.jetbrains.com/help/youtrack/devportal/operations-api-issues-issueID-project.html))
- **Agile board:** issues belong to all boards filtered to match
  (board membership is by query, not by explicit assignment).
- **Sprint:** an issue can belong to multiple sprints simultaneously
  (multi-valued via custom-field of type "sprint").
- **Issue link:** multi-valued (issue can have many links of many
  types).

**Architect-relevant uniqueness:** YouTrack's agile boards are
query-defined (filter-based), not explicit-membership. A grouping
abstraction layered on YouTrack agile boards is effectively a saved
filter.

### §11.3 — Custom field support (V3)

Rich. Custom fields are first-class with types: enum (single +
multi-select), date, text, string, integer, float, period, user,
group, ownedField, build, version, state, sprint, etc. The `$type`
attribute identifies the field type. **2026.1** added Hub-like
endpoints (org / team / role).
([JetBrains Help: Issue Custom Fields](https://www.jetbrains.com/help/youtrack/devportal/resource-api-issues-issueID-customFields.html))
([JetBrains Help: Update Issue Custom Fields](https://www.jetbrains.com/help/youtrack/devportal/api-how-to-update-custom-fields-values.html))

### §11.4 — Iteration primitives (V4)

**Sprint** (sub-resource of agile board). Sprints can include issues
from multiple projects. Sprints can be active simultaneously per
board configuration.
([JetBrains Help: Agiles](https://www.jetbrains.com/help/youtrack/devportal/resource-api-agiles.html))

### §11.5 — API access (V5)

- **REST only.** Base: `https://{instance}.youtrack.cloud/api/`.
- Auth: permanent token (per-user) or OAuth 2.0.
- 2026.1 introduced Hub-API parity — user, group, project team,
  organization, and role endpoints now in YouTrack REST.
  ([JetBrains Help: YouTrack REST API](https://www.jetbrains.com/help/youtrack/devportal/youtrack-rest-api.html))

### §11.6 — Webhook support (V6)

**Webhook Triggers app** — server-side workflow extension that emits
HTTP POST on issue / comment / work-item / attachment changes. Can be
attached to one or more projects; configured via the workflow editor.
([JetBrains Help: Webhook Triggers App](https://www.jetbrains.com/help/youtrack/cloud/webhook-triggers.html))

### §11.7 — Field / item limits (V7)

No published hard limits on custom fields per project, projects per
instance, or issues per project. JetBrains gates by license tier
(user count for self-hosted; user count for Cloud).

### §11.8 — Rate limits (V8)

No publicly documented hard rate-limit numbers in JetBrains official
docs (community references suggest per-user throttling exists but
without specific quotas). Architects should design for adaptive
back-off rather than fixed budgets.

### §11.9 — Deprecations / upcoming changes (V9)

No major API deprecations announced for 2026. **2026.1** consolidated
Hub-API endpoints into YouTrack REST — additive, not deprecating.

### §11.10 — Discrepancies vs Pass-1 / V2 baseline

Not in Pass-1 or V2 baseline. Architect-relevant facts that change
V11.1 design space:

1. **Sprint-across-projects native support** — YouTrack is the only
   backend in this research where a sprint primitive natively spans
   projects. V11.1 §7 phase-iteration overlay could exploit this.
2. **Query-defined agile boards** — board membership is filter-based,
   not explicit-assignment. A V11.1 grouping abstraction layered on
   agile boards becomes a saved-filter pattern.
3. **2026.1 Hub-API consolidation** — newly available endpoints
   (orgs, roles, teams) — architect can use these for org-scoped
   grouping if desired.

---

## §12 — Asana

### §12.1 — Native grouping primitives (V1)

- **Project** — primary container; tasks live in 0..N projects
  (multi-homing native).
  ([Asana Developers: Custom fields guide](https://developers.asana.com/docs/custom-fields-guide))
- **Section** — sub-grouping within a Project (kanban column or
  ordered group). Single-valued per task within a project.
- **Portfolio** — collection of Projects (Premium / Business+ plans
  only). Portfolios can be nested.
  ([Asana Developers: Get a portfolio's custom fields](https://developers.asana.com/reference/getcustomfieldsettingsforportfolio))
- **Goal** — strategic objective; can link Projects + Portfolios.
- **Tag** — free-text multi-valued label.
- **Custom field "multi-select"** — type-defined multi-valued
  metadata.

### §12.2 — Multi-grouping-per-issue (V2)

- **Project:** a task lives in 0..N projects natively (multi-homing).
- **Section:** single-valued per (task, project) pair.
- **Portfolio:** Projects can live in multiple Portfolios.
- **Tag:** multi-valued.

**Native multi-grouping support strong** — Asana's Project model is
overlay-style (closer to GH Projects than to Jira Epic). One task in
N Projects with per-Project custom-field values is a design pattern,
not an emulation.

### §12.3 — Custom field support (V3)

- Premium-and-above feature; not available on Free tier.
- Types: text, number, date, single-select (enum), multi-select,
  people, formula, etc.
- **150 custom fields per project** (across all paid tiers).
  ([Asana Forum: Increase Custom Field Limit per Project Beyond 100](https://forum.asana.com/t/increase-custom-field-limit-per-project-beyond-100/1106430))
  ([Asana Help: Custom field types and limitations](https://help.asana.com/s/article/custom-field-types-and-limitations?language=en_US))

### §12.4 — Iteration primitives (V4)

**No native sprint / cycle primitive** in Asana. Sprint emulation via
Project + start/end-date custom fields, or sub-Projects per sprint.
Cadence not first-class.

### §12.5 — API access (V5)

- **REST only.** Base: `https://app.asana.com/api/1.0/`.
- Auth: PAT, OAuth 2.0.
- ([Asana Developer Documentation](https://developers.asana.com/docs/getting-started))

### §12.6 — Webhook support (V6)

- Webhooks fire on task / project / story / section events.
- **Delivery typically within a minute; most within 10 minutes.**
  (Not real-time.)
- Workflow-level webhooks support project custom-field-change
  triggers.
  ([Asana Developers: Webhooks](https://developers.asana.com/reference/webhooks))
  ([Asana Forum: Workflow Level Webhook - Project Custom Field Change](https://forum.asana.com/t/workflow-level-webhook-project-custom-field-change/794738))

### §12.7 — Field / item limits (V7)

| Limit | Value |
|---|---|
| Custom fields per project | **150** (all paid plans) |
| Tasks per project | no documented hard cap |
| Projects per portfolio | (plan-dependent) |

### §12.8 — Rate limits (V8)

- **Free plan:** 150 requests/minute per token.
- **Premium / Business+ plans:** 1 500 requests/minute per token.
- 429 returns with `Retry-After` header.
- Per-token allocation (different tokens have independent budgets).
  ([Asana Developers: Rate limits](https://developers.asana.com/docs/rate-limits))

### §12.9 — Deprecations / upcoming changes (V9)

No major published deprecations for 2026. Custom-field API expansion
in February 2025 added public+private custom-field support to
Create-Task and Update-Task actions.

### §12.10 — Discrepancies vs Pass-1 / V2 baseline

Not in Pass-1 or V2 baseline. Architect-relevant facts:

1. **Strong multi-grouping native support** — Asana joins GH (and
   Linear less directly) in the multi-Project-per-task camp.
2. **Portfolio nesting** — gives Asana hierarchical multi-grouping;
   relevant for V11.1 if architect wants to expose hierarchy.
3. **Webhook delivery latency** — up to 10 minutes typical; not
   suitable for tight bidirectional-sync loops.
4. **Custom fields are paid-tier only** — Free-tier Asana users
   cannot use V11.1 typed `Kind` enum; would need to use tags.

---

## §13 — ClickUp

### §13.1 — Native grouping primitives (V1)

ClickUp has a deep hierarchical container model:

- **Workspace** — top-level container.
- **Space** — second-level (sub-organization within Workspace).
- **Folder** — optional third-level (groups Lists within a Space).
- **List** — primary task container.
- **Task** — work item; tasks live in a primary List, can be added to
  additional Lists via the "Tasks in Multiple Lists" feature
  (multi-homing).
- **Goal** — separate strategic-objective entity (can roll up tasks).
- **Custom fields** — first-class.
  ([ClickUp Developer: Getting started](https://developer.clickup.com/docs/Getting%20Started))
  ([ClickUp Developer: Custom Fields](https://developer.clickup.com/docs/customfields))

### §13.2 — Multi-grouping-per-issue (V2)

- **List:** a task has ONE primary List; multi-list membership
  available via "Tasks in Multiple Lists" feature (plan-gated).
- **Folder / Space / Workspace:** task inherits from primary List;
  no direct multi-membership.
- **Goal:** rolls up tasks via Goal Target linking.
- **Tag:** multi-valued.

**Architect note:** ClickUp's multi-list feature is closer to Asana's
multi-Project-per-task pattern than to GH's overlay model. Each List
membership carries its own status mapping.

### §13.3 — Custom field support (V3)

Rich. Types: text, number, money, dropdown (single/multi-select),
checkbox, date, URL, email, phone, rating, files, labels, location,
formula, relationships, automatic progress, etc. Custom fields
defined at Workspace / Space / Folder / List level (inherited
downward).
([ClickUp Developer: Custom Fields](https://developer.clickup.com/docs/customfields))

### §13.4 — Iteration primitives (V4)

**Sprints** are available as a ClickApp (toggleable feature). When
enabled, Sprints function as time-boxed Lists with sprint-specific
points and velocity tracking. Not core; opt-in per Space.

### §13.5 — API access (V5)

- **REST only.** Base: `https://api.clickup.com/api/v2/`.
- Auth: personal token, OAuth 2.0.
  ([ClickUp Developer: Getting started](https://developer.clickup.com/docs/Getting%20Started))

### §13.6 — Webhook support (V6)

**Workspace-level webhooks.** Events:

- Tasks: `taskCreated`, `taskUpdated`, `taskDeleted`, `taskMoved`,
  `taskCommentPosted`, `taskAssigneeUpdated`
- Lists: `listCreated`, `listUpdated`, `listDeleted`
- Folders: `folderCreated`, `folderUpdated`, `folderDeleted`
- Spaces: `spaceCreated`, `spaceUpdated`, `spaceDeleted`
- Goals: `goalCreated`, `goalUpdated`, `goalDeleted`

([ClickUp Developer: Webhooks](https://developer.clickup.com/docs/webhooks))

### §13.7 — Field / item limits (V7)

No published hard caps on tasks per List, Lists per Folder, or
custom fields per List. Plan-gated feature availability is the
primary constraint.

### §13.8 — Rate limits (V8)

Per-token, per-minute:

| Plan | Limit |
|---|---|
| Free Forever / Unlimited / Business | **100 req/min** |
| Business Plus | **1 000 req/min** |
| Enterprise | **10 000 req/min** |

429 returned on overage.
([ClickUp Developer: Rate Limits](https://developer.clickup.com/docs/rate-limits))

### §13.9 — Deprecations / upcoming changes (V9)

No major published deprecations for 2026.

### §13.10 — Discrepancies vs Pass-1 / V2 baseline

Not in Pass-1 or V2 baseline. Architect-relevant facts:

1. **Deepest container hierarchy of any backend** — Workspace /
   Space / Folder / List / Task is a four-level nest. V11.1 grouping
   architecture must pick one level to map to (most natural is
   List).
2. **Multi-list feature is plan-gated** — Free-tier ClickUp users
   may not have multi-list; degraded surface.
3. **100 req/min on Free is the tightest rate limit** of any backend
   surveyed — bulk migration on Free-tier ClickUp will be slow.


---

## §14 — Tier 2 long-tail tracker survey

Brief capability summaries for trackers unlikely to be primary v11.1
backends but worth documenting for completeness. NO V1-V10 sub-section
structure; 1-2 paragraphs each; NOT in the §7 matrix. Each entry cites
at least one primary source.

### §14.1 — Notion

Notion is a documents-and-databases hybrid; many teams use Notion
databases as tracker. Native primitives: **database**, **page** (each
row in a database is a page), **property** (typed columns: select,
multi-select, status, date, person, etc.). Multi-membership: a page
can live in one database (no native multi-database membership);
**relation properties** link pages across databases as cross-references
(relation cardinality 1:1 / 1:N / N:N depending on configuration).
([Notion Developers: Webhooks](https://developers.notion.com/reference/webhooks))

Webhook situation: **shipped 2026-01** (automation webhooks) and
**expanded 2026-03** (API webhooks with signature verification). New
`data_source.schema_updated` event (API 2025-09-03) replaces
deprecated `database.schema_updated` (API 2022-06-28).
([Fazm Blog: Notion API Webhooks Support in 2026](https://fazm.ai/blog/notion-api-webhooks-support-2026))

Architect note: Notion's grouping abstraction is "row in a database"
— similar to a flat list with rich typed columns. Multi-grouping
would map to relation properties, but the schema is database-bound,
not free-floating; harder to project a portable Kind enum onto.

### §14.2 — monday.com

monday.com uses **boards** as primary containers (similar to ClickUp
Lists or Asana Projects). Sub-grouping via **groups** (rows-in-board
clustering). Items live in 0..N boards (multi-board membership
native via the "Connect Boards" column). API is **GraphQL** at
`api.monday.com/v2`.
([monday.com Developer: GraphQL Overview](https://developer.monday.com/api-reference/docs/introduction-to-graphql))
([monday.com Developer: Boards](https://developer.monday.com/api-reference/reference/boards))

2026 updates: **2026-01-23** added `create_project` mutation
(Enterprise portfolio solution); **2026-04** added Board.folder and
Board.created_from_board_id fields.
([monday.com Developer: Changelog](https://developer.monday.com/api-reference/changelog?page=2))

Architect note: monday.com is closest to ClickUp in capability;
GraphQL-only is the main API distinguisher. Enterprise-tier gating
applies to portfolio / project-board features.

### §14.3 — OpenProject

Open-source Jira alternative; AGPL-licensed. Primitives:
**Project** (top-level), **Work Package** (issue/task; configurable
types), **Version** (release-grouping), **Category** (project-scoped
classification). REST API v3 at `/api/v3/`.
([OpenProject: API Documentation](https://www.openproject.org/docs/api/))
([OpenProject: API Versions](https://www.openproject.org/docs/api/endpoints/versions/))
([OpenProject: API Categories](https://www.openproject.org/docs/api/endpoints/categories/))

Multi-grouping: Version single-valued per work package; Category
single-valued per work package; Tag-like multi-valued via custom
fields. Self-hosted-first (Cloud option available but most installs
are on-prem).

Architect note: OpenProject resembles Redmine more than Jira despite
the marketing positioning; similar single-valued-primitive
limitations.

### §14.4 — Trello (Atlassian)

Trello is Atlassian's simpler tracker (acquired 2017). Primitives:
**Board**, **List** (column on a board), **Card**, **Label**
(multi-valued). Custom Fields are a **core API component** since
2018; a board can have up to **50 Custom Fields**. Webhook support
for boards / lists / cards / custom-field actions; **no limit on
number of webhooks**.
([Atlassian Developer: Trello REST API Introduction](https://developer.atlassian.com/cloud/trello/guides/rest-api/api-introduction/))
([Atlassian Developer: Trello Custom Fields](https://developer.atlassian.com/cloud/trello/guides/rest-api/getting-started-with-custom-fields/))

Query result cap: **1 000 results** per call for long lists (Cards /
Actions); pagination required.

Architect note: Trello is GitHub-Project-board-shaped (kanban-only).
No epic / hierarchy primitive; multi-membership-per-card is
single-Board (a card belongs to ONE Board, ONE List in that Board).
Multi-grouping emulation via Labels or via copying cards.

### §14.5 — Phorge

Phorge is the community fork of Phabricator (after Phacility wound
down operations in 2021; bare-minimum maintenance mode). Phorge
released stable on **2022-09-07** and is actively maintained.
Maniphest is Phorge's task/bug tracker; Projects provide
lightweight management with tags, workboards, sub-projects. API is
**Conduit** (HTTP JSON).
([Wikipedia: Phabricator](https://en.wikipedia.org/wiki/Phabricator))
([j3t.ch: Phorge is here](https://j3t.ch/tech/phabricator-alternative-phorge/))

Multi-grouping: Maniphest tasks can have multiple Projects assigned
(multi-valued natively); workboards within a Project provide
column-organisation.

Architect note: Phorge has GH-Projects-style multi-grouping (one task
in N Projects) — relatively rich for an open-source tracker, but
small userbase relative to Tier 1 backends. Conduit API works against
Phorge unchanged from Phabricator.

### §14.6 — Bugzilla

Mozilla's legacy bug tracker; REST API v1 is stable
("currently-recommended API for new development"). Primitives:
**Product**, **Component** (within Product), **Milestone**, **Version**.
A bug belongs to ONE Product + ONE Component + ONE Milestone +
ONE Version (all single-valued). Custom Fields available
(admin-defined).
([Bugzilla Documentation: Products REST API](https://bugzilla.readthedocs.io/en/latest/api/core/v1/product.html))
([Bugzilla Documentation: Classifications, Products, Components, Versions, and Milestones](https://bugzilla.readthedocs.io/en/stable/administering/categorization.html))

Architect note: Bugzilla's single-valued grouping primitives mirror
Redmine's. Userbase concentrated in Mozilla, Apache, Linux kernel
ecosystem and a small set of long-running OSS projects; not typical
for new product teams.

### §14.7 — Mantis Bug Tracker

PHP-based open-source tracker. REST API enabled by default since
**MantisBT 2.8.0**. Primitives: **Project** (with sub-projects),
**Category** (per-project; global categories also supported),
**Target Version** (used for milestones). Custom fields supported.
([Mantis Bug Tracker Forums: Obtaining lists of status, category, tags etc via REST API](https://mantisbt.org/forums/viewtopic.php?t=28109))
([MantisHub: REST API support](https://support.mantishub.com/api/rest_api))

Architect note: Milestone-like grouping via the Target Version field;
single-valued. Project-tree-with-subprojects gives some hierarchy.

### §14.8 — Taiga

Open-source agile tracker (Scrum / Kanban / Scrumban). Primitives:
**Project**, **Epic** (user-story grouping; one Epic can hold many
User Stories), **User Story**, **Task** (sub-of-User-Story), **Issue**
(bug-type), **Sprint** (milestone). API + webhooks both supported.
([docs.taiga.io: API documentation](https://docs.taiga.io/api.html))

Multi-grouping: an Epic can span User Stories from multiple
Projects (cross-project Epic support — uncommon among open-source
trackers).

Architect note: Taiga is one of the few open-source backends with
native Epic + Sprint primitives at full first-class status. Smaller
ecosystem than Forgejo / GitLab but cleaner agile-primitive model.

### §14.9 — Bitbucket Issues (DEPRECATING)

**WARNING:** Bitbucket Cloud Issues are being **SUNSET on
2026-08-20**. API endpoints (`/repositories/{workspace}/{repo_slug}/components`
and related Issue Tracker endpoints) will be removed mid-August 2026.
Atlassian recommends migrating to Jira.
([Atlassian Community: Announcing sunset of Bitbucket Issues and Wikis](https://community.atlassian.com/forums/Bitbucket-articles/Announcing-sunset-of-Bitbucket-Issues-and-Wikis/ba-p/3193882))
([Atlassian Developer: Bitbucket Cloud REST API - Issue Tracker](https://developer.atlassian.com/cloud/bitbucket/rest/api-group-issue-tracker/))

Primitives (until sunset): **Issue**, **Component**, **Version**,
**Milestone** — all single-valued per issue.

Architect note: Do NOT design V11.1 against Bitbucket Issues. The
**2026-08-20 removal** is < 90 days from this research authoring;
the API will be gone before V11.1 ships.

### §14.10 — Sourcehut Todo (todo.sr.ht)

Drew DeVault's minimal tracker. Primitives: **Tracker**, **Ticket**,
**Label**, **Comment**. **GraphQL-only API** at `https://todo.sr.ht/query`.
Q1 2026 (2026-02-18) update expanded GraphQL with arbitrary-resource
fetching by ID and added Resource IDs across the UI.
([Sourcehut docs: todo.sr.ht](https://docs.sourcehut.org/todo.sr.ht/))
([Sourcehut Blog: What's cooking Q1 2026](https://sourcehut.org/blog/2026-02-18-whats-cooking-q1-2026/))

Multi-grouping: no native multi-grouping primitive — tickets live in
ONE Tracker; labels are the only multi-valued metadata. No milestones,
no sprints, no epics in core (deliberate minimalism).

Architect note: Sourcehut Todo is the leanest backend surveyed.
V11.1 grouping is effectively unrepresentable except via label
namespace. Userbase is small but committed (Drew DeVault's
audience).

---

## §15 — Tier 3 — sunset / not realistic for v11.1+

Trackers explicitly EXCLUDED from V11.1 design consideration due to
sunset or end-of-life status. Architect should NOT plan to support
these.

### §15.1 — Pivotal Tracker

**DECOMMISSIONED 2025-04-30.** VMware Tanzu (the division that owned
Pivotal Tracker post-acquisition) announced end-of-life in
**September 2024**, with the service shutting down for ALL plans
(free, sponsored, paid, Enterprise) on **2025-04-30**. No support
for data migration is provided beyond that date.
([Pivotal Tracker Blog: News regarding your Pivotal Tracker subscription](https://www.pivotaltracker.com/blog/2024-09-18-end-of-life))
([Hacker News: Unfortunately, Pivotal Tracker was decommissioned on April 30, 2025](https://news.ycombinator.com/item?id=44062473))

**V11.1 implication:** zero. Pack should not advertise Pivotal
Tracker as a backend candidate.

### §15.2 — Phabricator (upstream)

Phacility (the original Phabricator owner) announced wind-down in
**June 2021**; Phabricator entered **bare-minimum maintenance mode**.
The active continuation is **Phorge** (community fork; see §14.5).
References to "Phabricator" in any V11.1 doc should redirect to
Phorge.
([Wikipedia: Phabricator](https://en.wikipedia.org/wiki/Phabricator))

**V11.1 implication:** treat Phabricator as Phorge-equivalent if a
user requests Phabricator support; do not build separate code
paths.

### §15.3 — Bitbucket Issues (cross-reference)

**SUNSET 2026-08-20** — see §14.9. Cross-referenced here because the
August 2026 removal falls within the realistic V11.1 development
window.

---

