# RESEARCH — BD-185 Execution-Ordering API (RG-1 + RG-2)

**Research date:** 2026-05-28
**Researcher:** pack-docs-researcher (read-only pass; primary GitHub docs only)
**HEAD at research time:** `e580dda7eb46c640a92afabd3469bbada17d1975`
**Scope:** Close exactly two residual research gaps flagged by the BD-185 architecture pass, against PRIMARY GitHub documentation. Facts + citations only — no design, no recommendations, no "pick one."

**Inputs read:**
- `maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-PARTS-AND-ORDERING.md` §4.1, §4.2, §4.7 (source leads; CONFIRMED or SUPERSEDED below).

**Verification method:** Each call shape below was extracted from the live `__NEXT_DATA__` schema JSON embedded in the primary GitHub docs pages (the same structured data GitHub renders the reference pages from), not from blog/forum snippets. Where a fact could not be confirmed from a primary GitHub source, it is marked PARTIAL or UNRESOLVED.

**Headline status:**
- **RG-1 (Issue Fields `number` type): RESOLVED.** Read + write call shapes confirmed for both REST and GraphQL; types, caps, cardinality, org-admin requirement, and rate limits confirmed from primary docs. One sub-item (the exact GraphQL preview header string) is PARTIAL — see RG-1 §8.
- **RG-2 (sub-issue reprioritize): RESOLVED.** Exact REST endpoint + body params and GraphQL mutation + input object confirmed from primary docs. The inventory's snippet-sourced §4.2 is corrected below.

---

## RG-1 — GitHub Issue Fields (`number` type)

### RG-1 §1 — Status: RESOLVED

The `number` Issue-Field type EXISTS and is fully readable/writable via both REST and GraphQL. Confirmed against the Issue Fields changelog posts, the two user-facing docs pages, the REST reference (two pages), and the GraphQL reference (mutations / input-objects / objects / unions / enums).

### RG-1 §2 — Available Issue-Field types (CONFIRMED; one discrepancy)

**Primary source (user-facing):** "Managing issue fields in your organization" — *About issue field types*:
> "You can create up to 25 issue fields per organization. The following field types are available: Single-select … Text … Number: accept numeric input, including decimals. Date …"
(https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/managing-issue-fields-in-your-organization)

**Primary source (changelog 2026-05-21):**
> "Fields support four types (i.e., single select, text, number, and date), can be pinned to specific issue types, and work across the platform."
(https://github.blog/changelog/2026-05-21-issue-fields-are-now-in-public-preview-for-all-organizations/)

**Primary source (REST create-field enum):** `POST /orgs/{org}/issue-fields` body param `data_type` enum is exactly:
`['text', 'date', 'single_select', 'number']`
(https://docs.github.com/en/rest/orgs/issue-fields)

**Primary source (GraphQL enum) — DISCREPANCY:** the `IssueFieldDataType` enum in the GraphQL reference lists FIVE values, not four:
`DATE`, `MULTI_SELECT`, `NUMBER`, `SINGLE_SELECT`, `TEXT`.
(https://docs.github.com/en/graphql/reference/enums — `IssueFieldDataType`)

> **Discrepancy note:** The GraphQL `IssueFieldDataType` enum exposes a `MULTI_SELECT` value that the user-facing docs, the changelog, and the REST `data_type` enum do NOT list (all three say four types). The read-side GraphQL unions also expose only the four production types (see RG-1 §6). Treat `number` as confirmed; treat `MULTI_SELECT` as schema-present-but-not-user-documented (likely not GA in the public preview surface). Primary docs are internally inconsistent on the multi-select type; this is noted, not resolved, because BD-185 needs only `number`.

`number` is confirmed by ALL of the above. **decimals are supported** ("accept numeric input, including decimals"), which aligns with the GraphQL value type being `Float` (RG-1 §4) and the REST value being a JSON number (RG-1 §3).

### RG-1 §3 — EXACT REST calls (read + write field VALUES on an issue)

**Doc page:** "REST API endpoints for issue field values" (https://docs.github.com/en/rest/issues/issue-field-values). Four endpoints exist:

| Verb | Path | Title | Permission (fine-grained PAT supported) |
|---|---|---|---|
| `GET` | `/repos/{owner}/{repo}/issues/{issue_number}/issue-field-values` | List issue field values for an issue | "Issues" repo permission: **read** |
| `POST` | `/repos/{owner}/{repo}/issues/{issue_number}/issue-field-values` | Add issue field values to an issue | "Issues" repo permission: **write** |
| `PUT` | `/repos/{owner}/{repo}/issues/{issue_number}/issue-field-values` | Set issue field values for an issue (replace all) | "Issues" repo permission: **write** |
| `DELETE` | `/repos/{owner}/{repo}/issues/{issue_number}/issue-field-values/{issue_field_id}` | Delete an issue field value from an issue | "Issues" repo permission: **write** |

**WRITE a `number` value — PUT (replace-all) body parameters (exact):**
- `issue_field_values` — array of objects. Each object:
  - `field_id` — **integer, REQUIRED** — "The ID of the issue field to set"
  - `value` — **string or number, REQUIRED** — "The value to set for the field. The type depends on the field's data type: For text fields: provide a string value … number: numeric value …"

**Exact PUT description (primary):**
> "Set custom field values for an issue, replacing any existing values. … This endpoint supports the following field data types: text: String values for text fields. single_select: Option names for single-select fields (must match an existing option name). number: Numeric values for number fields. date: ISO 8601 date strings for date fields. This operation will replace all existing field values with the provided ones. If you want to add field values without replacing existing ones, use the POST endpoint instead. Only users with push access to the repository can set issue field values."

**Exact PUT code example (primary doc):**
```json
{"issue_field_values":[{"field_id":123,"value":"Critical"},{"field_id":456,"value":5},{"field_id":789,"value":"2024-12-31"}]}
```
(Here `field_id:456, value:5` is a `number` field set to the JSON numeric value `5`.)

**POST (add without replace):** same body shape (`issue_field_values` array of `{field_id, value}`); semantics = add rather than replace. "Adding an empty array will clear all existing field values for the issue."

**DELETE:** `DELETE …/issue-field-values/{issue_field_id}` removes a single field value; path param `issue_field_id`. "If the specified field does not have a value set" it is a no-op/handled; "Only users with push access … can delete issue field values."

**READ:** `GET …/issue-field-values` — "Lists all issue field values for an issue." (Read permission.) The primary page does not embed a 200 response body example in the structured data extracted; the field-value object shape is most precisely documented on the GraphQL side (RG-1 §6). The REST read returns the set of field values for the issue.

**PUT status codes (primary):** `200`, `400`, `403` (no push access), `404`, `422` (validation / endpoint spammed), `503`.

> **CONFIRMS inventory §4.7's open question** "whether the pack's existing provider.* ops cover read/write of issue-field state": these are NEW REST endpoints under `/repos/.../issue-field-values`, not covered by the pack's 18-op provider surface today.

### RG-1 §4 — EXACT GraphQL calls (write field VALUES on an issue)

**Doc page:** "Mutations" (https://docs.github.com/en/graphql/reference/mutations). The primary mutation named by the user-facing docs is `setIssueFieldValue`; two sibling mutations also exist.

**`setIssueFieldValue`** — "Sets the value of an IssueFieldValue."
- Input: `input: SetIssueFieldValueInput!`
- Returns: `clientMutationId: String`, `issue: Issue`, `issueFieldValues: [IssueFieldValue!]`

**`SetIssueFieldValueInput`** (https://docs.github.com/en/graphql/reference/input-objects):
- `issueId: ID!` — "The ID of the Issue to set the field value on."
- `issueFields: [IssueFieldCreateOrUpdateInput!]!` — "The issue fields to set on the issue."
- `clientMutationId: String`

**`IssueFieldCreateOrUpdateInput`** (the per-field value payload — this is where the `number` value goes):
- `fieldId: ID!` — "The ID of the issue field."
- `numberValue: Float` — **"The numeric value, for a number field."**  ← the number value is a GraphQL `Float`
- `textValue: String` — "The text value, for a text field."
- `dateValue: String` — "The date value, for a date field."
- `singleSelectOptionId: ID` — "The ID of the selected option, for a single select field."
- `delete: Boolean` — "Set to true to delete the field value."

**Sibling mutations (same `IssueFieldCreateOrUpdateInput` payload):**
- `createIssueFieldValue(input: CreateIssueFieldValueInput!)` — input fields: `issueId: ID!`, `issueField: IssueFieldCreateOrUpdateInput!` (single value, not a list), `clientMutationId`.
- `updateIssueFieldValue(input: UpdateIssueFieldValueInput!)` — input fields: `issueId: ID!`, `issueField: IssueFieldCreateOrUpdateInput!`, `clientMutationId`.
- `deleteIssueFieldValue(input: DeleteIssueFieldValueInput!)` — input fields: `issueId: ID!`, `fieldId: ID!`, `clientMutationId`.

> **Note on `delete`:** A `number` value can be cleared two ways — (a) `IssueFieldCreateOrUpdateInput.delete = true` inside a set/update mutation, or (b) the dedicated `deleteIssueFieldValue` mutation. (REST analog: DELETE endpoint, or PUT with the field omitted from the replace-all array.)

### RG-1 §5 — Defining a `number` field (org-level) — requires org-admin (CONFIRMED)

Field DEFINITION is an org-level operation, distinct from setting a value on an issue.

**REST — "REST API endpoints for issue fields"** (https://docs.github.com/en/rest/orgs/issue-fields). Four endpoints:

| Verb | Path | Title | Permission |
|---|---|---|---|
| `GET` | `/orgs/{org}/issue-fields` | List issue fields for an organization | "Issue Fields" org permission: **read** |
| `POST` | `/orgs/{org}/issue-fields` | Create issue field for an organization | "Issue Fields" org permission: **write** |
| `PATCH` | `/orgs/{org}/issue-fields/{issue_field_id}` | Update issue field for an organization | "Issue Fields" org permission: **write** |
| `DELETE` | `/orgs/{org}/issue-fields/{issue_field_id}` | Delete issue field for an organization | "Issue Fields" org permission: **write** |

**Exact POST create-field body parameters (primary):**
- `name` — string, REQUIRED
- `data_type` — string, REQUIRED — enum `['text', 'date', 'single_select', 'number']`
- `description` — string|null, optional
- `visibility` — string, optional — enum `['organization_members_only', 'all']`
- `options` — array|null (single-select only): each `{name (req), description, color (req: gray|blue|green|yellow|orange|red|pink|purple), priority (int, req)}`

**Org-admin requirement (EXACT primary quote, POST description):**
> "Creates a new issue field for an organization. … To use this endpoint, the authenticated user must be an administrator for the organization. OAuth app tokens and personal access tokens (classic) need the `admin:org` scope to use this endpoint."

**GraphQL equivalents** (https://docs.github.com/en/graphql/reference/mutations + input-objects):
- `createIssueField(input: CreateIssueFieldInput!)` — `CreateIssueFieldInput`: `ownerId: ID!` ("The ID of the organization where the issue field will be created"), `dataType: IssueFieldDataType!`, `name: String!`, `description: String`, `options: [IssueFieldSingleSelectOptionInput!]`, `visibility: IssueFieldVisibility`, `clientMutationId`.
- `updateIssueField(input: UpdateIssueFieldInput!)` — `UpdateIssueFieldInput`: `id: ID!`, `name: String`, `description: String`, `options`, `visibility`, `clientMutationId`.
- (delete field mutation present in the same family — `DeleteIssueFieldInput { ... }`.)

> **Load-bearing for BD-185:** defining a NEW org-level `number` field (e.g., an "Execution order" field) requires **org-admin** (REST: `admin:org` scope / org-administrator; GraphQL: write on the org). The FOUR default fields (Priority, Effort, Start date, Target date) are auto-created when issue fields are enabled, but note their types per RG-1 §9.

### RG-1 §6 — EXACT GraphQL read path (read a `number` value on an issue) — CONFIRMED node path

**Node path:** `Issue.issueFieldValues` → `IssueFieldValueConnection` → `nodes: [IssueFieldValue]` → inline-fragment `... on IssueFieldNumberValue { value field { ... } }`.

**`Issue.issueFieldValues`** (https://docs.github.com/en/graphql/reference/objects — `Issue`):
- field `issueFieldValues: IssueFieldValueConnection` — "Fields that are set on this issue." Connection args: `after: String`, `before: String`, `first: Int`, `last: Int`.
- field `viewerCanSetFields: Boolean` — "Check if the current viewer can set fields on the issue." (permission preflight)

**`IssueFieldValueConnection`** fields: `edges: [IssueFieldValueEdge]`, `nodes: [IssueFieldValue]`, `pageInfo: PageInfo!`, `totalCount: Int!`.

**`IssueFieldValue`** union (https://docs.github.com/en/graphql/reference/unions) — "Issue field values." Members:
`IssueFieldDateValue`, `IssueFieldNumberValue`, `IssueFieldSingleSelectValue`, `IssueFieldTextValue`.

**`IssueFieldNumberValue`** object (https://docs.github.com/en/graphql/reference/objects) — "The value of a number field in an Issue item.":
- `value: Float!` — "Value of the field."  ← the number value on read is a non-null `Float`
- `field: IssueFields` — "The issue field that contains this value."
- `id: ID!`

**`IssueFields`** union — "Possible issue fields." Members: `IssueFieldDate`, `IssueFieldNumber`, `IssueFieldSingleSelect`, `IssueFieldText`.

**`IssueFieldNumber`** object — "Represents a number issue field.": `id: ID!`, `name: String!`, `dataType: IssueFieldDataType!`, `description: String`, `visibility: IssueFieldVisibility!`, `createdAt: DateTime!`, `fullDatabaseId: BigInt`.

**Illustrative read query (constructed from the confirmed node path; field names verbatim from primary schema):**
```graphql
query($owner:String!, $repo:String!, $number:Int!) {
  repository(owner:$owner, name:$repo) {
    issue(number:$number) {
      viewerCanSetFields
      issueFieldValues(first: 25) {
        totalCount
        nodes {
          __typename
          ... on IssueFieldNumberValue {
            value
            field { ... on IssueFieldNumber { id name } }
          }
        }
      }
    }
  }
}
```

### RG-1 §7 — Per-issue cardinality + caps (CONFIRMED)

**Per-issue cardinality (one value per field per issue):** Confirmed by the value-mutation/endpoint semantics — there is exactly one value per (issue, field):
- REST DELETE addresses a single value by `issue_field_id` (one value to remove per field).
- User-facing "Clearing a field value": "For text and number fields, delete all text in the input. … After clearing, the field is removed from the sidebar." (singular value per field) (https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/adding-and-managing-issue-fields)
- GraphQL `IssueFieldNumberValue.value` is a scalar `Float!`, not a list.
> The `IssueFieldValueConnection` on `Issue` is a connection over the SET OF FIELDS that have values (one node per field), not multiple values for one field. So: **single-valued per (issue, field)** for the `number` type.

**Org-level field cap — 25 (CONFIRMED, primary "Limits" table):**
| Resource | Limit |
|---|---|
| Issue fields per organization | **25** |
| Options per single-select field | 50 |
| Pinned fields per issue type | 10 |
| Total fields in a project (issue + system fields) | 50 |
(https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/managing-issue-fields-in-your-organization — *Limits*)

> The 25-cap is org-wide (all repos in the org share the 25 fields). "Issue fields and system fields together count toward projects' 50-field cap" — relevant only if BD-185 ever surfaces fields in a Project (out of scope per §4.8 of the inventory).

### RG-1 §8 — `gh` CLI exposure + GraphQL preview header

**`gh` CLI native exposure: NONE confirmed (passthrough only).**
- No `gh issue field`/`issue-field` subcommand is documented in the primary `gh` manual. The user-facing Issue Fields docs say "automate via REST and GraphQL APIs or webhook events" — i.e., API-level, not a `gh` verb.
- `gh issue list --json` field set does NOT include issue-field values (the documented `--json` fields are the standard set; issue fields are not among them). (https://cli.github.com/manual/gh_issue_list)
- Therefore Issue Fields are reachable from `gh` only via `gh api graphql` (mutations/queries in RG-1 §4/§6) or `gh api` REST passthrough (endpoints in RG-1 §3/§5). This matches the pack's existing `gh api graphql` passthrough pattern.
- **PARTIAL on a related `gh` JSON gap:** `gh issue list --json type` (the GA issue *type* field, a different feature) was still being requested as of 2026-01 (cli/cli #12477, OPEN). Not the same as issue *fields*; noted only to avoid conflation.

**GraphQL preview header: `GraphQL-Features: issue_fields` — PARTIAL (search-summary-attributed, not directly quoted from primary HTML).**
- A WebSearch summary of the "Adding and managing issue fields" docs page states: "When working with issue fields through GraphQL, add header `GraphQL-Features: issue_fields` to fetch schema and run queries or mutations." I could NOT locate this literal header string in the raw `__NEXT_DATA__` of the docs pages or the GraphQL reference pages I fetched (the user-facing pages link OUT to the API reference; the article body did not embed the header).
- The issue-field mutations/objects appear in the PRODUCTION GraphQL reference (https://docs.github.com/en/graphql/reference/mutations#setissuefieldvalue etc.) with NO formal schema-preview flag on the schema items (no `preview` key; `isDeprecated:false`). This is consistent with either (a) the preview header is required to actually execute despite the schema being documented, or (b) no header is required because the feature is in the production schema.
- **Status: PARTIAL.** The header MAY be required (preview features historically use `GraphQL-Features: <name>`, e.g. `sub_issues`, `issue_types`). An implementer MUST verify empirically with a live `gh api graphql -H "GraphQL-Features: issue_fields" …` vs without, against a preview-enabled org, before committing. This is the only RG-1 sub-item not fully closed from primary docs.

### RG-1 §9 — Preview status, caveats, rate limits, + inventory reconciliation

**Preview status (CONFIRMED, subject to change):**
- "Issue fields are now in public preview to all GitHub organizations on github.com and GitHub Enterprise Cloud with data residency" — 2026-05-21 (https://github.blog/changelog/2026-05-21-issue-fields-are-now-in-public-preview-for-all-organizations/).
- Both user-facing docs pages open with: "Issue fields are currently in public preview and **subject to change.**"
- Initial (select-orgs) preview: 2026-03-12 (https://github.blog/changelog/2026-03-12-issue-fields-structured-issue-metadata-is-in-public-preview/).
- **Projects caveat (2026-03-12):** "Projects integration: Add issue fields as columns in project views … This is currently only supported in **private** projects."
- Webhook events: `field_added` and `field_removed` (2026-03-12).

**Default fields — INVENTORY CORRECTION (SUPERSEDES §4.7):**
Primary source (org-management page, *Default fields*):
- **Priority — single-select** (Urgent, High, Medium, Low)
- **Effort — single-select** (High, Medium, Low)
- Start date — date
- Target date — date
> The inventory §4.7 stated "The PRECONFIGURED `Priority` and `Effort` fields are number-shaped already." **This is WRONG.** Per primary docs, Priority and Effort are **single-select**, not number. There is NO preconfigured `number` field. A `number` execution-order field would have to be newly defined (org-admin; counts against the 25-cap).

**Rate limits (primary — https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api):**
- Primary, authenticated: **5,000 requests/hour** (GitHub Apps / OAuth owned-by-GHEC: 15,000/hr; `GITHUB_TOKEN`: 1,000/hr/repo).
- Secondary (shared REST + GraphQL): no more than **100 concurrent** requests; **900 points/min** for a single REST endpoint, **2,000 points/min** for the GraphQL endpoint; no more than 90s CPU/60s real time (≤60s of that for GraphQL).
- Secondary, content-generating: **no more than 80 content-generating requests/minute and no more than 500/hour.** Setting/updating issue-field values is content-generating.
- GraphQL points: a mutation = **5 points**; a non-mutation query = 1 point.
- The PUT issue-field-values endpoint carries an explicit warning: "Creating content too quickly using this endpoint may result in secondary rate limiting. … This endpoint triggers notifications."
> **Load-bearing for BD-185 migration P4 bulk-write:** writing an execution-order `number` to every phase epic in a large project is content-generating. The binding limit is the secondary 80/min + 500/hr content-creation cap (TIGHTER than the 5,000/hr primary). A bulk-reorder migration must throttle to stay under ~500 field writes/hour and ~80/min.

**Provider-surface note (fact, not design):** The pack's 18-op `provider.*` surface (`scripts/lib/tracker-provider.sh`) has NO issue-field read/write op today; Issue Fields would be reachable only via `provider_raw` / direct `gh api`. (Stated as a fact about current surface coverage; the architect's call whether to extend.)

---

## RG-2 — GitHub sub-issue reprioritize

### RG-2 §1 — Status: RESOLVED

The reprioritize operation EXISTS as BOTH a REST endpoint and a GraphQL mutation. Exact endpoint path, parameter names, and types confirmed from the primary REST reference page and the primary GraphQL mutations + input-objects references. The inventory's snippet-sourced §4.2 (flagged as a verification gap) is now CONFIRMED with one correction (`before_id` DOES exist).

### RG-2 §2 — EXACT REST endpoint (CONFIRMED) — supersedes inventory §4.2

**Doc page:** "REST API endpoints for sub-issues" (https://docs.github.com/en/rest/issues/sub-issues). The page defines FIVE endpoints; the reprioritize one is:

**`PATCH /repos/{owner}/{repo}/issues/{issue_number}/sub_issues/priority`** — title "Reprioritize sub-issue."
> Description: "You can use the REST API to reprioritize a sub-issue to a different position in the parent list."

**Path parameters:**
- `owner` — string, required
- `repo` — string, required
- `issue_number` — integer, required — "The number that identifies the issue." (This is the PARENT issue's number.)

**Body parameters (EXACT, primary):**
- `sub_issue_id` — **integer, REQUIRED** — "The id of the sub-issue to reprioritize"
- `after_id` — **integer, OPTIONAL** — "The id of the sub-issue to be prioritized after (either positional argument after OR before should be specified)."
- `before_id` — **integer, OPTIONAL** — "The id of the sub-issue to be prioritized before (either positional argument after OR before should be specified)."

> **INVENTORY CORRECTION (supersedes §4.2):** The inventory said `before_id` was "referenced in some discussions but not verified in primary source." It IS in the primary source. Both `after_id` and `before_id` exist; the primary doc states "either … after OR before should be specified." The parameter names `sub_issue_id` / `after_id` / `before_id` are CONFIRMED (not `child_id`, not `issue_number` for the sub-issue).

> **Critical id-vs-number distinction:** `sub_issue_id` / `after_id` / `before_id` are issue **`id`** values (the numeric database/REST id), NOT issue `number` values. Only the path `issue_number` (the parent) is a number. The primary code example uses small ids (`sub_issue_id:6`, `after_id:5`) — these are issue ids.

**Exact REST code example (primary doc):**
```json
{"sub_issue_id":6,"after_id":5}
```
(with path params `owner=OWNER`, `repo=REPO`, `issue_number=ISSUE_NUMBER`; `Accept: application/vnd.github+json`)

**Permission (primary `progAccess`):** "Issues" repository permission: **write**. Fine-grained PATs supported (`fineGrainedPat: true`); user-to-server and server-to-server both supported.

**Status codes (primary):** `200 OK`, `403 Forbidden`, `404 Resource not found`, `422 Validation failed, or the endpoint has been spammed`, `503 Service unavailable`.

**The other four sub-issue REST endpoints (for completeness; from same primary page):**
| Verb | Path | Title |
|---|---|---|
| `GET` | `/repos/{owner}/{repo}/issues/{issue_number}/parent` | Get parent issue |
| `GET` | `/repos/{owner}/{repo}/issues/{issue_number}/sub_issues` | List sub-issues |
| `POST` | `/repos/{owner}/{repo}/issues/{issue_number}/sub_issues` | Add sub-issue (body: `sub_issue_id` int req; `replace_parent` bool opt; "The sub-issue must belong to the same repository owner as the parent issue") |
| `DELETE` | `/repos/{owner}/{repo}/issues/{issue_number}/sub_issue` | Remove sub-issue |

### RG-2 §3 — EXACT GraphQL mutation (CONFIRMED) — supersedes inventory §4.1

**Doc page:** "Mutations" (https://docs.github.com/en/graphql/reference/mutations).

**`reprioritizeSubIssue`** — "Reprioritizes a sub-issue to a different position in the parent list."
- Input: `input: ReprioritizeSubIssueInput!`
- Returns: `clientMutationId: String`, `issue: Issue`

**`ReprioritizeSubIssueInput`** (https://docs.github.com/en/graphql/reference/input-objects) — EXACT fields:
- `issueId: ID!` — "The id of the parent issue."
- `subIssueId: ID!` — "The id of the sub-issue to reprioritize."
- `afterId: ID` — "The id of the sub-issue to be prioritized after (either positional argument after OR before should be specified)."
- `beforeId: ID` — "The id of the sub-issue to be prioritized before (either positional argument after OR before should be specified)."
- `clientMutationId: String`

> **INVENTORY CORRECTION (supersedes §4.1):** The inventory said the mutation has input params "`issueId`, `subIssueId`, `afterId`." It MISSED `beforeId`. The complete set is `issueId` (parent), `subIssueId` (child to move), `afterId` (optional), `beforeId` (optional). All are `ID` GraphQL types (the GraphQL node id, not the issue number).

### RG-2 §4 — Sibling-only / parent-scoped ordering (CONFIRMED)

The ordering is **sibling-only, parent-scoped — NOT a global order.** Confirmed by the primary descriptions of BOTH surfaces:
- REST: "reprioritize a sub-issue to a different position in **the parent list**."
- GraphQL `reprioritizeSubIssue`: "Reprioritizes a sub-issue to a different position in **the parent list**"; `issueId` is documented as "The id of the **parent** issue."

Both operations reorder one child relative to a sibling (`after`/`before`) under a shared parent. There is no operation that imposes a single total order across all issues in a repo/project. (This CONFIRMS inventory §4.1's "sibling-only" statement.)

### RG-2 §5 — Caps + rate limits

**Sub-issues per parent — 100 (documented, NOT in the REST endpoint reference itself):**
- The 100-children-per-parent and 1-parent-per-child and 8-levels-deep limits are documented in the sub-issues community/feature documentation (GitHub community Discussion #154148, cited in the inventory §4.1), NOT embedded in the REST endpoint reference page's structured data. The REST endpoint reference page itself does not restate the 100-cap. **Status of the 100-cap: documented in GitHub's sub-issues feature discussion, not in the REST API reference.** Treat as the known sub-issue cap; primary REST reference is silent on it.
- Sub-issue improvements (https://github.blog/changelog/2025-09-11-a-rest-api-for-github-projects-sub-issues-improvements-and-more/): "Sub-issues now inherit the Project and Milestone of their parent issue by default"; "Sub-issues now support cross-organization issues, allowing a sub-issue to belong to a different organization than its parent"; the parent-fetch REST endpoint was added.
> Note tension: the 2025-09-11 changelog says sub-issues support cross-ORG parents, but the REST Add-sub-issue endpoint body doc says "The sub-issue must belong to the same repository OWNER as the parent issue." The Add constraint is at the repo-owner level; the cross-org support is a later improvement. Implementers parenting across orgs should verify against the live Add/Remove endpoints.

**Rate limits:** identical to RG-1 §9 (same primary doc). The reprioritize PATCH is a content-generating-class mutation for secondary-limit purposes; the 80/min + 500/hr secondary content cap is the binding limit for a bulk-reorder migration (e.g., writing initial sibling order to all phase epics under a root). GraphQL mutation = 5 points toward the 2,000 points/min GraphQL secondary cap.

### RG-2 §6 — `gh` CLI exposure (CONFIRMED: passthrough only)

- No native `gh issue sub-issue`/reprioritize subcommand. cli/cli #10298 ("Add `gh issue` support for parent issues / sub-tasks") is **OPEN** (verified live: `state: OPEN`). (https://github.com/cli/cli/issues/10298)
- Reachable only via `gh api` (REST PATCH in RG-2 §2) or `gh api graphql` (mutation in RG-2 §3), or third-party `gh` extensions. This matches the pack's existing `gh api graphql` sub-issue passthrough in `scripts/lib/tracker-provider-gh.sh`.
- The pack's 18-op `provider.*` surface exposes `_sub_issue_create` / `_sub_issue_list` / `_sub_issue_unlink` but NO `_sub_issue_reprioritize` (fact about current surface coverage, per inventory §12.7).

---

## Inventory reconciliation summary (primary docs win)

| Inventory claim | Verdict | Primary-source correction |
|---|---|---|
| §4.1 GraphQL `reprioritizeSubIssue` args = `issueId`, `subIssueId`, `afterId` | **CORRECTED** | Adds `beforeId: ID` (optional). Full set: `issueId`, `subIssueId`, `afterId`, `beforeId`, `clientMutationId`. |
| §4.2 REST `PATCH …/sub_issues/priority` with `sub_issue_id` + `after_id`; `before_id` "not verified in primary source" | **CONFIRMED + CORRECTED** | Endpoint path exact. `before_id` (integer, optional) IS in the primary source. Params are issue `id` (not `number`). |
| §4.1 sub-issue ordering is sibling-only | **CONFIRMED** | "the parent list"; `issueId` = parent. |
| §4.7 Issue Fields: 4 types incl. `number`; 25/org cap; org-level | **CONFIRMED** | All confirmed; note GraphQL enum also exposes `MULTI_SELECT` (5th value, not user-documented). |
| §4.7 "preconfigured `Priority` and `Effort` fields are number-shaped already" | **WRONG — CORRECTED** | Priority and Effort are **single-select**, not number. No preconfigured `number` field exists. |
| §4.7 open Q: per-issue cardinality | **RESOLVED** | Single-valued per (issue, field) for `number`. |
| §4.7 open Q: `gh` exposes issue fields? | **RESOLVED** | No native `gh` verb; `gh api` / `gh api graphql` passthrough only. |
| §4.7 open Q: org-admin to define fields? | **RESOLVED** | Yes — REST `admin:org` / org-administrator; GraphQL write on org via `ownerId`. |

---

## Primary sources cited

1. REST API endpoints for sub-issues — https://docs.github.com/en/rest/issues/sub-issues (RG-2 endpoint, params, status codes, permissions)
2. GraphQL Mutations reference — https://docs.github.com/en/graphql/reference/mutations (`setIssueFieldValue`, `createIssueField`, `updateIssueField`, `reprioritizeSubIssue` signatures)
3. GraphQL Input objects reference — https://docs.github.com/en/graphql/reference/input-objects (`SetIssueFieldValueInput`, `IssueFieldCreateOrUpdateInput`, `CreateIssueFieldInput`, `ReprioritizeSubIssueInput`, value-mutation input objects)
4. GraphQL Objects reference — https://docs.github.com/en/graphql/reference/objects (`Issue.issueFieldValues`, `IssueFieldValueConnection`, `IssueFieldNumber`, `IssueFieldNumberValue`)
5. GraphQL Unions reference — https://docs.github.com/en/graphql/reference/unions (`IssueFieldValue`, `IssueFields`)
6. GraphQL Enums reference — https://docs.github.com/en/graphql/reference/enums (`IssueFieldDataType`)
7. REST API endpoints for issue field values — https://docs.github.com/en/rest/issues/issue-field-values (GET/POST/PUT/DELETE value endpoints + body shape + code example)
8. REST API endpoints for issue fields (org) — https://docs.github.com/en/rest/orgs/issue-fields (org field CRUD, `data_type` enum, org-admin requirement)
9. Adding and managing issue fields — https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/adding-and-managing-issue-fields (API surface names, value entry, clearing semantics, search syntax)
10. Managing issue fields in your organization — https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/managing-issue-fields-in-your-organization (25-cap + Limits table, field types incl. decimals, default-field types)
11. Changelog 2026-05-21 (Issue fields — all orgs) — https://github.blog/changelog/2026-05-21-issue-fields-are-now-in-public-preview-for-all-organizations/
12. Changelog 2026-03-12 (Issue fields — initial preview) — https://github.blog/changelog/2026-03-12-issue-fields-structured-issue-metadata-is-in-public-preview/ (private-projects caveat, webhook events)
13. Changelog 2025-09-11 (sub-issue improvements + Projects REST) — https://github.blog/changelog/2025-09-11-a-rest-api-for-github-projects-sub-issues-improvements-and-more/
14. Rate limits for the REST API — https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api (primary + secondary + content-generating + GraphQL points)
15. cli/cli #10298 (no native gh sub-issue verb; OPEN) — https://github.com/cli/cli/issues/10298
16. gh issue list manual (no issue-field `--json`) — https://cli.github.com/manual/gh_issue_list

**Unresolved / partial (explicit):**
- GraphQL preview header `GraphQL-Features: issue_fields` — **PARTIAL.** Referenced by a WebSearch summary of source #9 but NOT located verbatim in the primary HTML I fetched; issue-field mutations appear in the production GraphQL reference (#2) with no schema-preview flag. Must be verified empirically against a preview-enabled org before relying on it.
- Sub-issue 100-children-per-parent cap — documented in GitHub's sub-issues community/feature discussion (per inventory §4.1), **NOT** in the REST endpoint reference (#1). The REST reference is silent on the cap.
- `MULTI_SELECT` value in the GraphQL `IssueFieldDataType` enum (#6) is present in the schema but absent from all user-facing docs/changelogs and the REST `data_type` enum — internally inconsistent in primary docs; not resolved (out of scope — BD-185 needs only `number`).
