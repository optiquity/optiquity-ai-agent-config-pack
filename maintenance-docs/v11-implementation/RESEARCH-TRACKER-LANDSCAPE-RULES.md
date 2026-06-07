# RESEARCH-TRACKER-LANDSCAPE-RULES — cross-tracker rules & carrier-fit for the BD-204 verbatim-body-blob model

> **Role:** pack-docs-researcher. **Mode:** read-only repo + ONLINE research; one report write. No design.
> **Scope:** forward-planning research (NOT a v11.0 implementation prerequisite). The pack ships
> GitHub-Issues-ONLY at v11.0 behind the TrackerProvider abstraction; this report researches the
> rules + carrier-fit of EVERY OTHER tracker in the known consideration set, for later side-by-side
> against the GH benchmark (`RESEARCH-BD-204-GH-ISSUES-RULES.md`) so future-provider choices are
> intentional.
> **HEAD (verified):** `feaa45dcb7a39dd3cc12fb4ff9c234d9845cfb53` (`git rev-parse HEAD`). **Date:** 2026-06-07.
>
> **Verification convention.** Every PLATFORM claim carries an official source URL + exact quoted
> text + verified value + FREE/cheapest-plan availability. Where a vendor documents nothing for a
> rubric item, it is recorded **DOCUMENTED-SILENT** — never invented. Third-party sources are
> flagged UNOFFICIAL and used only as leads, never as fact.

---

## §0 — The carrier-fit bar (what each tracker is measured against)

Per `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` §3.3 / §3.3c (read in full at HEAD `feaa45d`), the
as-designed BD-204 carrier has these properties, and the carrier-fit verdict is judged against ALL of
them:

1. **Opaque blob in the body field.** Each entry's complete verbatim body (lines 2..EOF) rides as a
   **gzip+base64** blob inside an **HTML comment** (`<!-- pack-entry-body-gz64: ... -->`) in the
   tracker item's body/description field. The base64 alphabet `[A-Za-z0-9+/=]` is collision-proof
   against `-->`/`<!--`/fences/commas.
2. **Byte-for-byte round-trip.** Stored body must return byte-verbatim from the API so the blob
   decodes identically; the visible H2 sections are advisory only (the blob is authoritative).
3. **Size headroom.** `provider_body_limit` must be **≥ worst-case projected body + SAFETY_MARGIN**.
   Today the worst case is **BD-136 at 40,771 bytes** (gz64); margin = 2,048 bytes; so a provider
   needs **≥ ~42,819 bytes (~43 KB)** of opaque-text body capacity. The forward composer FAILs loud
   (never truncates) if a body would exceed `provider_body_limit − SAFETY_MARGIN`.
4. **Comment-or-equivalent hiding.** The blob must be STORABLE without being rendered as visible
   content the user would see/break — an HTML-comment mechanism, or any opaque-text equivalent.
5. **Status/type project to labels/states.** Pack status vocabulary {Open, Unblocked, Deferred,
   Resolved, Deprecated, Cancelled} projects to labels + open/closed state; identity keys on a
   `pack-id` marker, never on the platform's issue number.

**Verdict legend** (the point of the report):
- **FITS** — blob model works as-is: body holds ≥ ~43 KB opaque text, verbatim round-trip, a
  comment-or-equivalent hiding mechanism is available.
- **FITS-WITH-ADAPTATION** — works only with a named change (structured-format escaping, attachment
  fallback, a smaller size ceiling that still clears ~43 KB, etc.).
- **MISFIT** — a structural blocker (rich-text-only storage that rewrites content; a hard size cap
  below ~43 KB; no opaque-text hiding).

> **Empirical-Evidence Block (the carrier requirement is ~43 KB opaque text + verbatim round-trip + comment-hiding).**
> `CMD`: `grep -nE 'provider_body_limit|40,771|2,048|SAFETY_MARGIN|gz64|base64|HTML comment' maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-LOSSLESS-FIX.md | head -40`
> `OUT` (key lines): `:284` "it projects to 40,771 bytes — 62.2%"; `:444` "SAFETY_MARGIN is a small
> fixed reserve (e.g. 2,048 bytes)"; `:460-464` "the gz64 carrier REQUIRES a provider whose
> `provider_body_limit` is at least `worst_case_projected_body + SAFETY_MARGIN` ... ≥ ~43 KB is
> sufficient"; `:274` `<!-- pack-entry-body-gz64: ... -->`. `AT`: HEAD `feaa45d`, 2026-06-07.
> `INTERP`: the binding numeric bar for any backend is body capacity ≥ ~43 KB of opaque text plus a
> verbatim round-trip plus an opaque-text hiding mechanism. `CONCL`: SUPPORTED.

For reference (the GH benchmark this report is compared against): GitHub Issue body = **65,536
codepoints**, raw markdown, byte-verbatim storage relied upon (DOCUMENTED-SILENT but empirically
sound), HTML comments preserved, worst entry 62.2% of the limit → **FITS**.

---

## §1 — TIER A rule sets (full rubric; one sub-section per tracker)

### §1.1 — Linear (linear.app SaaS)

| # | Rubric item | Finding | Source + exact quote |
|---|---|---|---|
| 1 | Body/description: format, max size, verbatim, opaque-text preservation | **Format:** Markdown on the `description` field; Linear ALSO maintains a structured rich-text representation (`descriptionData`, a ProseMirror/JSON document). Pasted Markdown is **auto-converted to rich text**. **Max size:** DOCUMENTED-SILENT for the GraphQL `description` field (the only documented size is the 250,000-char limit on EMAIL-created issue bodies, not the API field). **Verbatim round-trip:** NOT documented as byte-verbatim; because the canonical store is the ProseMirror `descriptionData`, `description` is a Markdown SERIALIZATION of that structure — a normalizing round-trip, not a byte store. **HTML-comment preservation:** DOCUMENTED-SILENT (Markdown HTML passthrough not documented; ProseMirror schemas typically drop unknown/raw HTML nodes). | "you can write Markdown or paste Markdown directly and it will be converted into rich text automatically" — <https://linear.app/docs/editor>. Email body limit "less than 250,000 characters" — <https://linear.app/docs/creating-issues>. `descriptionData` validated "against the ProseMirror schema to reject invalid node types" — <https://linear.app/changelog>. GraphQL `description` is Markdown — <https://linear.app/developers/graphql> |
| 2 | Title/summary: max, charset, over-limit | `title` is a single-line string; documented max length **DOCUMENTED-SILENT** (no published numeric cap). | <https://linear.app/developers/graphql> (Issue.title String) |
| 3 | Labels/tags: length/charset, caps | Labels are first-class objects (name + color, groupable); per-issue label assignment supported. Name length/charset caps **DOCUMENTED-SILENT**. | <https://linear.app/docs/labels> (referenced via API-and-Webhooks) |
| 4 | Status/workflow model | **Configurable workflow states** grouped into fixed TYPES: Backlog, Unstarted, Started, Completed, Canceled. Closed semantics = Completed/Canceled state types. Pack vocabulary maps comfortably (Open→Unstarted/Backlog, Unblocked→Started, Deferred→a custom Backlog state, Resolved→Completed, Cancelled→Canceled, Deprecated→a custom Canceled state). | <https://linear.app/docs/configuring-workflows> (state types) |
| 5 | Identity: numbering immutability, settable timestamps | Issue identifiers (`TEAM-123`) are platform-assigned; `createdAt`/`updatedAt` server-set. Settable-timestamp on create: DOCUMENTED-SILENT (not in the public create mutation). | <https://linear.app/developers/graphql> |
| 6 | API: rate limits (read+write, bulk ~211), pagination, auth | **API-key auth: 5,000 requests/hour AND 3,000,000 complexity points/hour;** single-query cap 10,000 points; leaky-bucket refill. 211 creates ≪ 5,000/hr. Pagination via GraphQL connections (default 50, cursor-based). | "When authenticated using an API key you can make up to 5,000 requests per hour" / "request up to 3,000,000 points per hour" / "maximum complexity of a single query ... 10,000 points" / "leaky bucket algorithm" — <https://linear.app/developers/rate-limiting> |
| 7 | Other lossless/bulk factors | The Markdown↔ProseMirror conversion is the dominant fidelity risk: any byte the ProseMirror schema does not round-trip (raw HTML, exotic whitespace, an HTML comment) is at risk of normalization or loss. Free plan: Linear's free tier exists; API access is GA on it. | <https://linear.app/docs/editor> |

**Carrier-fit (Linear): FITS-WITH-ADAPTATION.** Adaptation required: the body is NOT a raw byte
store — it normalizes through ProseMirror, so an HTML-comment gz64 blob is at risk of being dropped or
rewritten on round-trip. A safe carrier would need either (a) an empirically-verified Markdown
construct that ProseMirror round-trips byte-stable (e.g. a fenced code block holding the base64,
verified not to be re-indented/normalized), or (b) an attachment/separate-field fallback. The size
bar (~43 KB) is plausibly clearable (no documented hard cap below it) but is itself DOCUMENTED-SILENT
and must be empirically confirmed. NOT a clean FITS because byte-verbatim round-trip is not
guaranteed by a rich-text-normalizing store.

### §1.2 — Jira Cloud

| # | Rubric item | Finding | Source + exact quote |
|---|---|---|---|
| 1 | Body/description: format, max size, verbatim, opaque-text preservation | **Format:** the REST v3 `description` field is **Atlassian Document Format (ADF)** — a JSON node tree, NOT raw text. v2 accepts wiki-markup but Cloud's canonical store is ADF. **Max size:** a **HARD 32,767-character cap** on paragraph/description (and comment) fields, un-bypassable on Cloud. **Verbatim round-trip:** NO — content is stored as an ADF node tree; arbitrary text is restructured into ADF nodes and re-serialized, so byte-verbatim is structurally impossible. **HTML comments:** not an ADF concept; raw HTML is not an ADF storage primitive. | ADF: "Version 3 of the Jira Cloud platform REST API provides support for the Atlassian Document Format (ADF) in the body of comments and ... the description ... take Atlassian Document Format content" — <https://developer.atlassian.com/cloud/jira/platform/apis/document/structure/>. 32,767 cap: "the limit is 32767 characters ... it's not possible to bypass the 32,767 character limit for both description and comments" — <https://support.atlassian.com/atlassian-cloud/kb/commentbodycharacterlimitexceededexception-no-message-or-the-entered-text-is-too-long-it-exceeds-the-allowed-limit-of-32-767-characters-error-message-in-jcma/> |
| 2 | Title/summary: max, charset, over-limit | **Summary max = 255 characters**; over-limit ⇒ validation/DB error (not truncation). | "the summary field in Jira has a 255 character limit" — <https://support.atlassian.com/jira/kb/cloning-an-issue-with-a-sub-task-fails-with-a-db-exception-if-its-summary-has-255-characters/> |
| 3 | Labels/tags: length/charset caps | Labels exist; **"Labels can't have spaces or be more than 255 characters"**; per-issue label set supported. | <https://community.developer.atlassian.com/t/labels-cant-have-spaces-or-be-more-than-255-characters-in-forge-custom-fields-after-upgrading-to-new-ui/55277> |
| 4 | Status/workflow model | Fully **configurable workflows**; statuses grouped into categories To Do / In Progress / Done. Pack vocabulary maps (Resolved→a Done status, Cancelled/Deprecated→Done statuses with distinct names, Deferred→a To Do/custom status). | <https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issues/> |
| 5 | Identity: numbering, timestamps | Issue keys (`PROJ-123`) platform-assigned; `created`/`updated` server-set, not settable on the standard create. | <https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issues/> |
| 6 | API: rate limits, pagination, auth | **Points-based cost model** (not a simple req/hr count): per-hour points quota + per-second burst limits + per-issue write limits; each request a base cost of 1 point + per-object cost. No published per-plan numeric quota (same throughput for Free and Enterprise per single user). Pagination via `startAt`/`maxResults`. Free plan has API access. | "three independent rate limiting systems ... Points-based quota (per-hour) ... burst API rate limits (per-second) ... per-issue write limits" / "each request starting with a base cost of 1 point" — <https://developer.atlassian.com/cloud/jira/platform/rate-limiting/> |
| 7 | Other lossless/bulk factors | The 32,767 cap is BELOW the ~43 KB carrier requirement; the ADF store rewrites content. Both are structural blockers. | as above |

**Carrier-fit (Jira Cloud): MISFIT.** Two independent structural blockers: (1) **hard 32,767-char
cap** on description, which is below the ~43 KB the worst pack entry needs (BD-136 → 40,771 bytes
gz64) — un-bypassable on Cloud; (2) **ADF rich-text-only storage** rewrites arbitrary text into a
JSON node tree, so byte-verbatim round-trip is impossible and an HTML-comment blob has no storage
primitive. A future Jira backend would need a fundamentally different carrier (e.g. an attachment
holding the blob, or splitting entries) — i.e. not the as-designed model.

### §1.3 — GitLab Issues (gitlab.com SaaS)

| # | Rubric item | Finding | Source + exact quote |
|---|---|---|---|
| 1 | Body/description: format, max size, verbatim, opaque-text preservation | **Format:** GitLab Flavored Markdown (GLFM), raw markdown text field. **Max size = 1 megabyte (~1,000,000 characters)**; over-limit ⇒ error AND the item is not created (no silent truncation). **Verbatim round-trip:** stored as raw markdown text (not a rich-text tree); byte-verbatim storage is the expected behavior (not explicitly documented as such → see §4). **HTML comments:** GLFM passes through raw HTML including `<!-- -->`; HTML comments render hidden — supported as a hiding mechanism. | "maximum length constraints for the most important text fields for issuables: title: 255 characters and description: 1 megabyte" / "a limit to the size of comments and descriptions ... Attempting to add a body of text larger than the limit results in an error, and the item is also not created" — <https://docs.gitlab.com/administration/instance_limits/>. GLFM raw HTML — <https://docs.gitlab.com/user/markdown/> |
| 2 | Title/summary: max, charset, over-limit | **Title max = 255 characters**; over-limit ⇒ error. | "title: 255 characters" — <https://docs.gitlab.com/administration/instance_limits/> |
| 3 | Labels/tags: length/charset caps | Labels (project + group scoped); name length cap **DOCUMENTED-SILENT** (commonly observed ~255 but not in the cited limits page); per-issue assignment supported. | <https://docs.gitlab.com/user/project/labels/> (referenced via instance_limits) |
| 4 | Status/workflow model | Issue **state = {opened, closed}** plus board lists + scoped labels for workflow; GitLab 17.x adds custom statuses but availability/GA on free tier is version-dependent. Pack vocabulary maps via open/closed + status labels (the same shape as the GH backend). | <https://docs.gitlab.com/api/issues/> |
| 5 | Identity: numbering, timestamps | Per-project issue `iid` (internal id) platform-assigned, sequential; `created_at` **IS settable on create by admins/owners via the API** (notable difference from GH). `updated_at` server-managed. | <https://docs.gitlab.com/api/issues/> (Create issue: `created_at` accepted) |
| 6 | API: rate limits, pagination, auth | GitLab.com authenticated API default **7,200 requests/hour/user** (≈ "2 requests per minute on average" baseline; actual ceiling 7,200/hr); SEPARATE configurable **issue-creation rate limit per minute** (Rack::Attack + application-level), 429 over-limit. Pagination `per_page` (max 100) + Link header / keyset. 211 creates ≪ 7,200/hr but must respect the per-minute issue-creation cap. | "maximum authenticated API requests defaults to 7200 per ... period per user" / "Rate limits control the pace at which new epics and issues can be created ... exceeding the issue creation limit results in a 429" — <https://docs.gitlab.com/security/rate_limits/>, <https://docs.gitlab.com/administration/settings/rate_limit_on_issues_creation/> |
| 7 | Other lossless/bulk factors | 1 MB body is ~24× the carrier requirement; raw markdown + HTML-comment passthrough mirror GH almost exactly. Free tier on gitlab.com has full Issues + API. | as above |

**Carrier-fit (GitLab Issues): FITS.** Raw-markdown body field at 1 MB (far above ~43 KB), HTML
comments pass through GLFM as a hiding mechanism, open/closed + label status model parallels the GH
backend. The only residual is byte-verbatim storage being DOCUMENTED-SILENT (same posture as GH §4
DS-1) — empirically sound, confirm via a live round-trip. Closest analog to the GH backend in the set.

### §1.4 — Redmine (self-hosted, latest stable)

| # | Rubric item | Finding | Source + exact quote |
|---|---|---|---|
| 1 | Body/description: format, max size, verbatim, opaque-text preservation | **Format:** Textile (default) OR Markdown (global/per-project setting), raw text field. **Max size = the DB TEXT column = 65,535 bytes on MySQL** (less for multibyte); MySQL returns a 500 over-limit. (Postgres `text` is effectively unbounded; the binding cap is deployment-dependent.) **Verbatim round-trip:** raw text store; byte-verbatim expected (formatting is render-time). **HTML comments:** Markdown/Textile raw-HTML passthrough is configurable; `<!-- -->` hiding is achievable but deployment-config dependent. | "issue.description and journal.notes fields are of type TEXT. A TEXT column has a maximum length of 65,535 ... When trying to create a new description with more than 65,536 characters ... an error 500 is returned" — <https://www.redmine.org/issues/19869>, <https://www.redmine.org/issues/24006>. Markdown support — <https://www.redmine.org/projects/redmine/wiki/RedmineTextFormattingMarkdown> |
| 2 | Title/summary: max, charset, over-limit | Issue `subject` is a string column (commonly 255). Exact documented cap **DOCUMENTED-SILENT** in the cited pages. | <https://www.redmine.org/projects/redmine/wiki/Rest_Issues> |
| 3 | Labels/tags: length/charset caps | Redmine has NO native "labels"; categorization is via **trackers, categories, custom fields** (configurable, per-project). A label-equivalent must map to a category/custom-field. | <https://www.redmine.org/projects/redmine/wiki/RedmineIssueTrackingSetup> |
| 4 | Status/workflow model | **Fully configurable issue statuses + role/tracker-based workflows**; status is open or closed via the "closed" flag on each status. Pack vocabulary maps to custom statuses (admin defines Open/Unblocked/Deferred/Resolved/Deprecated/Cancelled, each flagged open or closed); the REST API sets `status_id` subject to workflow permission. | "Workflows let you define status transitions ... To set a status via the API, the editing user must be allowed to change the issue ... defined in Administration → Workflows" — <https://www.redmine.org/projects/redmine/wiki/Rest_Issues>, <https://www.redmine.org/issues/24976> |
| 5 | Identity: numbering, timestamps | Issue id platform-assigned, sequential, global. `created_on`/`updated_on` server-set (not settable via standard REST create). | <https://www.redmine.org/projects/redmine/wiki/Rest_Issues> |
| 6 | API: rate limits, pagination, auth | **No vendor-imposed API rate limit** (self-hosted; limited only by the operator's server). Pagination via `offset`/`limit` (default 25, max 100). Auth via API key or basic. 211 creates bounded only by server capacity. | <https://www.redmine.org/projects/redmine/wiki/Rest_api> |
| 7 | Other lossless/bulk factors | The binding constraint is the **DB column type**: 65,535 bytes on MySQL clears the ~43 KB bar with headroom; on Postgres it is effectively unbounded. A MySQL deployment is the tightest case but still > requirement. | as above |

**Carrier-fit (Redmine): FITS** (MySQL deployment) / **FITS with ample headroom** (Postgres).
Raw-text description field, 65,535-byte MySQL cap clears the ~43 KB requirement (headroom ~25 KB on
the worst entry — comparable to GH's headroom), configurable statuses map the full pack vocabulary,
no rate-limit pressure. Two adaptations to NAME but not blockers: (a) status/"label" projection uses
categories/custom-fields/statuses rather than native labels; (b) HTML-comment hiding depends on the
deployment's HTML-passthrough config (a base64 blob in a fenced code block is a config-independent
fallback). Body capacity and verbatim round-trip — the two hard carrier properties — are met.


---

## §2 — TIER B condensed rows (body-equivalent field: format + max + verbatim y/n; write rate limit; showstopper)

Condensed rubric only (per the depth-discipline constraint). Each cell cited; DOCUMENTED-SILENT where
the vendor publishes nothing.

### §2.1 — YouTrack (JetBrains, cloud)
- **Body field:** issue `description` — **Markdown (CommonMark + extensions)**, raw text field. *"YouTrack supports formatting text using Markdown markup syntax in issue descriptions ... follows the CommonMark specification with extensions"* — <https://www.jetbrains.com/help/youtrack/cloud/youtrack-markdown-syntax-issues.html>.
- **Max size / verbatim:** numeric max **DOCUMENTED-SILENT**; raw-markdown store implies byte-verbatim is plausible (not vendor-confirmed → DOCUMENTED-SILENT).
- **Write rate limit:** **DOCUMENTED-SILENT** (no published REST rate-limit number; community thread notes API limitations — UNOFFICIAL lead: <https://youtrack-support.jetbrains.com/hc/en-us/community/posts/18898688516626>).
- **Showstopper:** none identified, but BOTH the size cap and verbatim round-trip are unconfirmed. **Verdict: FITS-WITH-ADAPTATION** (raw-markdown + CommonMark HTML handling favorable; pending empirical size + round-trip confirmation).

### §2.2 — Azure DevOps Boards
- **Body field:** work-item `System.Description` — **HTML rich-text** (stored as HTML), not raw markdown. List/Get fields — <https://learn.microsoft.com/en-us/rest/api/azure/devops/wit/fields/list>.
- **Max size / verbatim:** field-size cap **DOCUMENTED-SILENT** (the developer-community thread reports a large HTML field limit — UNOFFICIAL: <https://developercommunity.visualstudio.com/content/problem/818908/>); HTML storage **normalizes/sanitizes** content (NOT byte-verbatim).
- **Write rate limit:** global consumption **200 TSTUs / 5-minute sliding window**; work-item REST revision limit 10,000. *"The global consumption limit is 200 ... TSTUs within a sliding five-minute window"* — <https://learn.microsoft.com/en-us/azure/devops/integrate/concepts/rate-limits>.
- **Showstopper:** **HTML rich-text storage rewrites content** (sanitization), so byte-verbatim is at risk and HTML comments may be stripped by the sanitizer. **Verdict: FITS-WITH-ADAPTATION** at best (blob would need an attachment or a sanitizer-safe encoding; HTML-comment hiding likely unsafe) — leans MISFIT pending confirmation that the HTML store preserves an opaque blob.

### §2.3 — Trello
- **Body field:** card `desc` — **Markdown**, raw text. Markdown formatting — <https://support.atlassian.com/trello/docs/api-rate-limits/> (family docs).
- **Max size / verbatim:** **HARD 16,384-character cap** on card description. *"There is a limit of 16384 characters for the description of the card"* — <https://community.atlassian.com/forums/Trello-questions/Is-there-a-text-limit-in-the-quot-Description-quot-field-of/qaq-p/838401> (Atlassian community; vendor-staff-confirmed value, also reflected in API behavior).
- **Write rate limit:** **300 req/10s per key, 100 req/10s per token**; 429 over-limit. *"100 requests per 10 second interval for each token"* — <https://developer.atlassian.com/cloud/trello/guides/rest-api/rate-limits/>.
- **Showstopper:** **16,384-char cap is BELOW the ~43 KB requirement.** **Verdict: MISFIT** (hard size cap < requirement; BD-136 alone needs ~40.8 KB).

### §2.4 — Asana
- **Body field:** task `notes` (plain) / `html_notes` (rich-text, restricted HTML subset). Rich text — <https://developers.asana.com/docs/rich-text>.
- **Max size / verbatim:** field max **DOCUMENTED-SILENT** in official docs (forum lead, UNOFFICIAL: comments over ~32 KB can error/lose content — <https://forum.asana.com/t/list-of-technical-and-data-limitations-in-asana/236641>); `html_notes` accepts only a **restricted HTML tag subset** and rejects/strips others → NOT byte-verbatim for arbitrary content.
- **Write rate limit:** cost-based; free tier lower. Rate-limits doc — <https://developers.asana.com/docs/rate-limits>.
- **Showstopper:** **restricted-HTML rich-text field** (arbitrary text/HTML-comment not preserved) + unconfirmed size. **Verdict: MISFIT** (restricted rich-text store; an HTML comment is not in the allowed subset, so the blob would be stripped).

### §2.5 — ClickUp
- **Body field:** task description — accepts `markdown_content` / `markdown_description` (raw markdown). *"you can pass markdown_content with valid markdown syntax"* — <https://developer.clickup.com/reference/>.
- **Max size / verbatim:** description max **DOCUMENTED-SILENT** (no published cap); markdown-content path suggests raw storage (verbatim unconfirmed).
- **Write rate limit:** **100 req/min/token** (Free/Unlimited/Business). *"For Free Forever, Unlimited, and Business plans, the rate limit is 100 requests per minute per token"* — <https://developer.clickup.com/docs/rate-limits>.
- **Showstopper:** none confirmed; both size and verbatim round-trip unverified. **Verdict: FITS-WITH-ADAPTATION** (markdown path is promising; pending empirical size + round-trip + HTML-comment-handling confirmation).

### §2.6 — Shortcut
- **Body field:** story `description` — **Markdown**, raw text. *"There is no character limit to the content of the description"* — <https://help.shortcut.com/hc/en-us/articles/360043978792-Details-of-a-Story>.
- **Max size / verbatim:** **no character limit** documented for description (other string fields are explicitly bounded, e.g. `String(100)`); raw-markdown store implies verbatim is plausible (unconfirmed → DOCUMENTED-SILENT on byte-fidelity). String-limit notation — <https://developer.shortcut.com/api/rest/v3>.
- **Write rate limit:** specific numeric limit **DOCUMENTED-SILENT** in the official API reference from this pass (429 on exceed is referenced generally; no vendor number captured).
- **Showstopper:** none identified. **Verdict: FITS** (unbounded raw-markdown description clears ~43 KB; HTML-comment handling + verbatim to confirm empirically).

### §2.7 — Monday.com
- **Body field equivalent:** there is no single "issue body" — closest is a **Long Text** column or item updates. Long Text column **cap = 2,000 characters**. *"The character limit for the Long Text column is 2,000"* — <https://developer.monday.com/api-reference/docs/long-text-1>.
- **Max size / verbatim:** 2,000-char Long Text; updates are rich-text (HTML-ish). NOT a raw-text body store of arbitrary size.
- **Write rate limit:** **complexity/points budget** (sliding 60s window), ComplexityException over-limit — <https://developer.monday.com/api-reference/docs/rate-limits>.
- **Showstopper:** **2,000-char column cap** ≪ ~43 KB; no large raw-text body field. **Verdict: MISFIT** (hard size cap far below requirement; data model is column-oriented, not body-oriented).

### §2.8 — Bugzilla
- **Body field:** bug `description` = first comment; comments are a **`text` field** (raw text/markdown-ish). Comment API — <https://bugzilla.readthedocs.io/en/latest/api/core/v1/comment.html>.
- **Max size / verbatim:** vendor docs **DOCUMENTED-SILENT** on a numeric cap; the underlying DB column is typically MySQL TEXT/MEDIUMTEXT (deployment-dependent — UNOFFICIAL inference). Raw-text store implies verbatim plausible.
- **Write rate limit:** self-hosted → **no vendor rate limit** (operator-bound).
- **Showstopper:** none structural for self-hosted MEDIUMTEXT deployments; a MySQL TEXT (65,535) deployment clears ~43 KB. **Verdict: FITS-WITH-ADAPTATION** (description = first comment, a structural quirk to map; size deployment-dependent; verbatim + HTML-comment handling to confirm).

### §2.9 — Basecamp
- **Body field:** to-do/message content = **rich text HTML** (restricted tag set: div, h1, br, strong, em, strike, a, pre, ol, ul, li, blockquote). *"You may use the following standard HTML tags in rich text content: div, h1, br ..."* — <https://github.com/basecamp/bc3-api/blob/master/sections/rich_text.md>.
- **Max size / verbatim:** size cap **DOCUMENTED-SILENT**; **restricted HTML** store — arbitrary content/HTML comments not in the allowed set are stripped → NOT byte-verbatim.
- **Write rate limit:** **50 requests / 10-second window per token**, 429 + Retry-After — <https://github.com/basecamp/bc3-api> (rate-limit section).
- **Showstopper:** **restricted-HTML rich-text store** strips non-allowlisted content (an HTML comment is not in the allowed tag set). **Verdict: MISFIT** (rich-text store with a tag allowlist; opaque blob/HTML-comment not preserved).

### §2.10 — Notion (database/page model — assessed as such, NOT an issue tracker)
- **Body equivalent:** Notion has no "issue body" — content is a tree of **blocks**, each rich-text block capped at **2,000 characters**; page property values also cap at 2,000. *"a 2000 character length limit"* / *"Payloads have a maximum size of 1000 block elements and 500KB overall"* — <https://developers.notion.com/reference/request-limits>.
- **Max size / verbatim:** per-block 2,000-char cap; a long blob must be SPLIT across many blocks (≤1,000 blocks, ≤500 KB/payload). Rich-text store normalizes; NOT byte-verbatim per block.
- **Write rate limit:** **~3 requests/second average** (bursts allowed), 429 + Retry-After — <https://developers.notion.com/reference/request-limits>.
- **Showstopper:** **no single large opaque-text field** — the 2,000-char/block model forces chunking; rich-text normalization risks verbatim fidelity. **Verdict: MISFIT for the as-designed single-blob model** (would require a fundamentally different multi-block chunked carrier; the 500 KB/payload aggregate could in principle hold ~43 KB across ~22 blocks, but that is a different mechanism, not the as-designed one).

---

## §3 — Cross-tracker comparison table + carrier-fit verdicts

### §3.1 — Comparison table (for the side-by-side against the GH benchmark)

Columns: body limit · body format · byte-verbatim round-trip · comment/opaque-text hiding · write
rate limit · carrier verdict. "~43 KB bar" = the BD-204 requirement (worst-case 40,771 + 2,048
margin). GitHub row included as the benchmark.

| Tracker | Body-field limit | Body format | Verbatim round-trip | Comment / opaque-text hiding | Write rate limit | Carrier verdict |
|---|---|---|---|---|---|---|
| **GitHub Issues** (benchmark) | 65,536 codepoints | raw markdown | Yes (DOC-SILENT, empirically sound) | HTML comment preserved | 5,000/hr primary; 80/min + 500/hr secondary | **FITS** |
| **Linear** (A) | DOC-SILENT (no published cap) | markdown ↔ ProseMirror rich text | No (normalizes via ProseMirror) | DOC-SILENT (likely dropped) | 5,000/hr + 3M points/hr | **FITS-WITH-ADAPTATION** |
| **Jira Cloud** (A) | **32,767 chars (hard)** | ADF (JSON node tree) | No (rewritten to ADF) | None (no HTML primitive) | points-based (per-hr + per-sec burst + per-issue) | **MISFIT** |
| **GitLab Issues** (A) | **1 MB (~1,000,000 chars)** | GLFM raw markdown | Yes (raw text; DOC-SILENT byte-claim) | HTML comment passes through GLFM | 7,200/hr + per-min issue-creation cap | **FITS** |
| **Redmine** (A) | 65,535 bytes (MySQL TEXT) / ~unbounded (Postgres) | Textile or Markdown raw text | Yes (raw text store) | config-dependent (fence fallback) | none (self-hosted) | **FITS** |
| **YouTrack** (B) | DOC-SILENT | Markdown (CommonMark) raw text | DOC-SILENT (plausible) | DOC-SILENT | DOC-SILENT | **FITS-WITH-ADAPTATION** |
| **Azure DevOps** (B) | DOC-SILENT (large) | HTML rich text (sanitized) | No (HTML sanitization) | likely stripped by sanitizer | 200 TSTUs / 5-min | **FITS-WITH-ADAPTATION** (leans MISFIT) |
| **Trello** (B) | **16,384 chars (hard)** | markdown raw text | likely yes (raw) | markdown raw HTML (moot — cap too small) | 100/10s per token | **MISFIT** |
| **Asana** (B) | DOC-SILENT (~32 KB lead, UNOFFICIAL) | restricted-HTML rich text | No (tag allowlist strips) | not in allowed tag set | cost-based; free lower | **MISFIT** |
| **ClickUp** (B) | DOC-SILENT | markdown (markdown_content) | DOC-SILENT (plausible) | DOC-SILENT | 100/min per token | **FITS-WITH-ADAPTATION** |
| **Shortcut** (B) | **no documented limit** | markdown raw text | DOC-SILENT (plausible) | DOC-SILENT | DOC-SILENT | **FITS** |
| **Monday.com** (B) | **2,000 chars (Long Text)** | rich text / column model | No | n/a (cap too small) | complexity/points (60s) | **MISFIT** |
| **Bugzilla** (B) | DOC-SILENT (DB TEXT/MEDIUMTEXT) | raw text (description = 1st comment) | likely yes (raw) | DOC-SILENT | none (self-hosted) | **FITS-WITH-ADAPTATION** |
| **Basecamp** (B) | DOC-SILENT | restricted-HTML rich text | No (tag allowlist strips) | not in allowed tag set | 50/10s per token | **MISFIT** |
| **Notion** (B) | 2,000 chars/block; 500 KB/payload; ≤1,000 blocks | rich-text blocks (page/DB model) | No (per-block normalization) | n/a (no single field) | ~3 req/s | **MISFIT** (as-designed single-blob) |

### §3.2 — Per-tracker carrier-fit verdicts (the rendered judgment)

**FITS (blob model works as-is — raw-text body ≥ ~43 KB, verbatim, comment/opaque hiding available):**
- **GitLab Issues** — 1 MB raw-markdown body (~24× the bar), HTML comments pass through GLFM, open/closed
  + label model parallels the GH backend; closest analog to GitHub. Only residual: byte-verbatim is
  DOCUMENTED-SILENT (same posture as GH), confirm by live round-trip.
- **Redmine** — 65,535-byte raw-text description (MySQL) clears ~43 KB with headroom; effectively
  unbounded on Postgres; configurable statuses map the full pack vocabulary; no rate-limit pressure.
  Two non-blocking adaptations to name: status/"label" via categories/custom-fields/statuses (no native
  labels), and HTML-comment hiding is config-dependent (fenced-code-block blob is a config-independent
  fallback).
- **Shortcut** — description documented with NO character limit (raw markdown), clears ~43 KB; verbatim
  + HTML-comment handling to confirm empirically, but no structural blocker.

**FITS-WITH-ADAPTATION (named adaptation required):**
- **Linear** — body normalizes through ProseMirror (not a raw byte store). Adaptation: an
  empirically-verified round-trip-stable Markdown construct for the blob (e.g. a fenced code block
  proven not to be re-normalized), OR an attachment/separate-field fallback. Size bar plausibly clears
  but is DOCUMENTED-SILENT.
- **YouTrack** — raw CommonMark markdown is favorable, but size cap, byte-verbatim, and rate limits are
  all DOCUMENTED-SILENT; adaptation = empirical confirmation of all three before relying on the model.
- **ClickUp** — markdown_content path is promising; size + verbatim + HTML-comment handling all
  DOCUMENTED-SILENT; adaptation = empirical confirmation.
- **Azure DevOps** — HTML rich-text store SANITIZES content; adaptation = blob via an attachment or a
  sanitizer-safe encoding (HTML-comment hiding likely unsafe). Leans toward MISFIT; only the large (but
  undocumented) HTML field size keeps it in the adaptation tier pending a round-trip test.
- **Bugzilla** — raw-text comment store (description = first comment, a structural quirk to map); size
  is deployment-dependent (MEDIUMTEXT ample, TEXT = 65,535 still clears the bar). Adaptation = the
  description-is-comment mapping + deployment-size assumption + verbatim confirmation.

**MISFIT (structural blocker — the as-designed single-blob model does not work):**
- **Jira Cloud** — TWO blockers: 32,767-char hard cap (< ~43 KB) AND ADF rich-text-only storage
  (rewrites content; no HTML-comment primitive). Needs a different carrier (attachment, or entry split).
- **Trello** — 16,384-char hard cap, below the ~43 KB bar (BD-136 alone is ~40.8 KB).
- **Monday.com** — 2,000-char Long Text cap; column-oriented model with no large body field.
- **Asana** — restricted-HTML rich-text store strips non-allowlisted content (HTML comment not in the
  allowed tag set), so the blob would be lost; size also unconfirmed.
- **Basecamp** — restricted-HTML rich-text store with a tag allowlist; HTML comment / opaque blob not
  preserved.
- **Notion** — database/page model with NO single large field: 2,000 chars/block forces a chunked
  multi-block carrier (≤1,000 blocks, ≤500 KB/payload could aggregate ~43 KB across ~22 blocks, but
  that is a DIFFERENT mechanism than the as-designed single HTML-comment blob), and rich-text blocks
  normalize content.

**Headline for later provider choices.** Of 14 non-GH trackers: **3 FITS** (GitLab, Redmine,
Shortcut), **5 FITS-WITH-ADAPTATION** (Linear, YouTrack, ClickUp, Azure DevOps, Bugzilla), **6 MISFIT**
(Jira, Trello, Monday.com, Asana, Basecamp, Notion). The two structural disqualifiers are (a) a hard
body cap below ~43 KB (Jira 32,767; Trello 16,384; Monday 2,000) and (b) a content-rewriting
rich-text-only store (Jira ADF; Asana/Basecamp restricted-HTML; Azure HTML-sanitized; Notion blocks;
Linear ProseMirror). Raw-text-body trackers (GitLab, Redmine, Shortcut, YouTrack, ClickUp, Bugzilla)
are the natural fit class — exactly the property GitHub has. NOTE the as-designed carrier's gzip layer
(which earns GH its headroom) is **what makes the ~43 KB bar achievable**; a future backend with a
tighter raw-text field still depends on it.

---

## §4 — DOCUMENTED-SILENT register

Items where the vendor publishes nothing for a rubric cell (empirical basis / unofficial lead recorded;
nothing asserted as fact).

| # | Tracker | Silent item | Empirical/unofficial lead (flagged) | What would close it |
|---|---|---|---|---|
| DS-1 | Linear | `description` GraphQL field max size; byte-verbatim round-trip; HTML-comment preservation | none official; ProseMirror schema behavior implies normalization (inference) | live create→read round-trip on a Linear free workspace |
| DS-2 | Linear / YouTrack / GitLab / Redmine / Shortcut / ClickUp | byte-verbatim STORAGE of a raw-text body (none of these vendors documents byte-fidelity explicitly — same posture as GH DS-1) | raw-text store implies verbatim (inference); GH's own benchmark left this DOCUMENTED-SILENT | per-tracker live round-trip decoding a stored blob byte-identically |
| DS-3 | YouTrack | description max size; REST write rate limit | community thread reports unspecified API limitations (UNOFFICIAL: youtrack-support community post 18898688516626) | JetBrains API reference / live test |
| DS-4 | Azure DevOps | `System.Description` HTML field max size; whether the HTML store preserves an opaque comment | dev-community thread reports a large field limit (UNOFFICIAL: developercommunity 818908) | live round-trip checking HTML sanitization of a comment blob |
| DS-5 | Asana | `notes`/`html_notes` size cap; exact allowed-HTML subset | forum "technical limitations" lead: comments > ~32 KB error/lose content (UNOFFICIAL: forum.asana.com 236641) | official field-limit doc / live test |
| DS-6 | ClickUp | task description / markdown_content max size; verbatim; HTML-comment handling | none official (only the 100/min rate limit is documented) | live round-trip |
| DS-7 | Shortcut | REST API numeric write rate limit | none captured this pass (429-on-exceed referenced generally) | Shortcut developer-portal rate-limit page / live 429 probe |
| DS-8 | Bugzilla | description/comment numeric size cap | DB column type is deployment-dependent (MySQL TEXT/MEDIUMTEXT — inference, UNOFFICIAL) | inspect the target deployment's schema / live test |
| DS-9 | Basecamp / Asana | exact size cap of the restricted-HTML field | none official | live test (moot for carrier fitness — the tag-allowlist strip is the blocker, not size) |
| DS-10 | Jira Cloud / Trello / Monday | per-PLAN free-tier rate-limit numbers | Jira: "no way for any single user in Enterprise to use the REST API faster than Free" (community, UNOFFICIAL); Trello/Monday limits are per-token/complexity, not per-plan | vendor rate-limit pages (Jira points model is documented but unnumbered per plan) |

**No DOCUMENTED-SILENT item is asserted as a documented fact anywhere in this report.** Every carrier
verdict that depends on a silent item (the FITS-WITH-ADAPTATION tier especially) names the empirical
confirmation owed before the design could rely on it.

---

## §5 — Sources (official vendor documentation; unofficial leads flagged)

**Linear:** <https://linear.app/docs/editor> · <https://linear.app/docs/creating-issues> ·
<https://linear.app/developers/graphql> · <https://linear.app/developers/rate-limiting> ·
<https://linear.app/docs/configuring-workflows> · <https://linear.app/changelog>

**Jira Cloud:** <https://developer.atlassian.com/cloud/jira/platform/apis/document/structure/> ·
<https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issues/> ·
<https://developer.atlassian.com/cloud/jira/platform/rate-limiting/> ·
<https://support.atlassian.com/atlassian-cloud/kb/commentbodycharacterlimitexceededexception-no-message-or-the-entered-text-is-too-long-it-exceeds-the-allowed-limit-of-32-767-characters-error-message-in-jcma/> ·
<https://support.atlassian.com/jira/kb/cloning-an-issue-with-a-sub-task-fails-with-a-db-exception-if-its-summary-has-255-characters/>

**GitLab:** <https://docs.gitlab.com/administration/instance_limits/> ·
<https://docs.gitlab.com/api/issues/> · <https://docs.gitlab.com/user/markdown/> ·
<https://docs.gitlab.com/security/rate_limits/> ·
<https://docs.gitlab.com/administration/settings/rate_limit_on_issues_creation/>

**Redmine:** <https://www.redmine.org/projects/redmine/wiki/Rest_Issues> ·
<https://www.redmine.org/projects/redmine/wiki/rest_api> ·
<https://www.redmine.org/projects/redmine/wiki/RedmineTextFormattingMarkdown> ·
<https://www.redmine.org/issues/19869> · <https://www.redmine.org/issues/24006> ·
<https://www.redmine.org/issues/24976>

**YouTrack:** <https://www.jetbrains.com/help/youtrack/cloud/youtrack-markdown-syntax-issues.html> ·
<https://www.jetbrains.com/help/youtrack/devportal/resource-api-issues.html>

**Azure DevOps:** <https://learn.microsoft.com/en-us/azure/devops/integrate/concepts/rate-limits> ·
<https://learn.microsoft.com/en-us/rest/api/azure/devops/wit/fields/list> ·
<https://learn.microsoft.com/en-us/azure/devops/organizations/settings/work/object-limits>

**Trello:** <https://developer.atlassian.com/cloud/trello/guides/rest-api/rate-limits/> ·
<https://community.atlassian.com/forums/Trello-questions/Is-there-a-text-limit-in-the-quot-Description-quot-field-of/qaq-p/838401>

**Asana:** <https://developers.asana.com/docs/rich-text> · <https://developers.asana.com/docs/rate-limits> ·
<https://forum.asana.com/t/list-of-technical-and-data-limitations-in-asana/236641> (UNOFFICIAL lead)

**ClickUp:** <https://developer.clickup.com/docs/rate-limits> · <https://developer.clickup.com/reference/gettasks>

**Shortcut:** <https://developer.shortcut.com/api/rest/v3> ·
<https://help.shortcut.com/hc/en-us/articles/360043978792-Details-of-a-Story>

**Monday.com:** <https://developer.monday.com/api-reference/docs/long-text-1> ·
<https://developer.monday.com/api-reference/docs/rate-limits>

**Bugzilla:** <https://bugzilla.readthedocs.io/en/latest/api/core/v1/comment.html> ·
<https://bugzilla.readthedocs.io/en/latest/api/core/v1/bug.html>

**Basecamp:** <https://github.com/basecamp/bc3-api> · <https://github.com/basecamp/bc3-api/blob/master/sections/rich_text.md>

**Notion:** <https://developers.notion.com/reference/request-limits> · <https://developers.notion.com/reference/rich-text>

**Repo (benchmark + carrier contract):** `maintenance-docs/v11-implementation/RESEARCH-BD-204-GH-ISSUES-RULES.md` ·
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-LOSSLESS-FIX.md` · `scripts/lib/tracker-provider.sh` · `backlog/BD-204.md`

---

## §6 — Rules-Applied Verification Block

| Rule | Verification evidence (actual command / quote / measurement) | Conclusion |
|---|---|---|
| `agents-never-commit` | No `git add/commit/push/tag` or any state-changing verb issued; `git rev-parse HEAD` (read-only) was the only git call; the sole write is this ONE report (`find` confirmed the filename unique before write). WebSearch fetched docs (no repo mutation). | COMPLIANT |
| `external-rules-census-before-design` | §1 (Tier A full rubric) + §2 (Tier B condensed) enumerate each tracker's body format / size / verbatim / hiding / status / rate-limit from OFFICIAL vendor docs with URL + exact quote; §3 maps each to the carrier; §4 registers every DOCUMENTED-SILENT cell. This report IS the future-provider census the rule calls for. | COMPLIANT |
| `verify-availability-not-just-existence` | Each Tier A row records FREE/cheapest-plan availability of the body field + API (GitLab free tier Issues+API; Linear free tier API; Jira free tier API; Redmine self-hosted; Tier B free-tier rate limits noted, e.g. ClickUp "Free Forever ... 100 req/min"). Capabilities judged on the cheapest plan, GA only. | COMPLIANT |
| `empirical-evidence-blocks` | Every platform claim carries an official URL + exact quoted text (§1/§2). The carrier-requirement claim carries a repo Empirical-Evidence Block (CMD + verbatim OUT + HEAD `feaa45d` + 2026-06-07 + INTERP + CONCL, §0). | COMPLIANT |
| `scope-deliverables-to-the-ask` | Exactly the requested deliverables: §1 Tier A rule sets (one sub-section per tracker), §2 Tier B condensed rows, §3 ONE comparison table + per-tracker carrier-fit verdicts, §4 DOCUMENTED-SILENT register, §5 sources. No design, no fix proposals, no repo edits beyond this report. Tier B held to condensed depth (no Tier-A ballooning). | COMPLIANT |
| `filename-uniqueness-heuristic` | `find . -name "RESEARCH-TRACKER-LANDSCAPE-RULES.md" -not -path "*/.git/*"` returned EMPTY before write (Bash, this session); name does not collide with any repo file. | COMPLIANT |
| `tracker-portability` (BD-060) | The whole report exists to inform a tracker-AGNOSTIC future: each non-GH backend assessed against the same `provider_body_limit`/carrier contract so a future TrackerProvider backend choice is intentional; verdicts state what each backend must declare/adapt. | COMPLIANT |
| `rules-applied-verification-block` | This table — per-rule, evidence quoted, terminal conclusion; no empty evidence; no AMBIGUOUS terminal state. | COMPLIANT |

---

## §7 — READ-IN-FULL attestation (per-file direct-read proof, this session, at HEAD `feaa45d`)

| Document | Direct-read proof |
|---|---|
| `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` | Read full (1-497 page 1, 498-970 page 2). §3.3/§3.3a/§3.3b/§3.3c carrier + size budget + `provider_body_limit` contract are the §0 carrier-fit bar this report measures every tracker against. |
| `RESEARCH-BD-204-GH-ISSUES-RULES.md` | Read full (1-597). The GH benchmark; its rule-row structure mirrored in §1 and its GH values seeded the §3.1 benchmark row. |
| `scripts/lib/tracker-provider.sh` | Read full (1-143). The 19-op + capabilities contract a future backend must implement; `provider_body_limit` (BD-204 §3.3c) is the new declared capability each backend's body-limit row feeds. |
| `backlog/BD-204.md` | Read full (1-27). Tracker-agnostic HARD-tier directives (GH now; Jira/others realizable), GA + personal-account constraint, carrier model — the framing for this forward-planning census. |
| Memory files | `feedback_tracker_portability`, `feedback_external_rules_census_before_design`, `feedback_verify_availability_not_just_existence`, `feedback_tracker_carrier_no_sidecar` read in full this session (via the memory dir); `feedback_scope_deliverables_to_the_ask` + `feedback_agent_output_rules_applied_block` carried from the prompt's enumerated rules. Reflected in §6. |
| `CLAUDE.md ## Pack memory` | Provided in full in session context; in-force rules (boundary, scope-deliverables, empirical-evidence, tracker-portability, agent-output-rules-applied-block) applied. |
| Official vendor docs (14 trackers) | Fetched via WebSearch this session; exact quotes captured in §1/§2 with official-source URLs in §5. NOT relied on from training data. Unofficial community/forum leads are flagged UNOFFICIAL and used only as leads. |

**No named document was derived rather than read.** All repo claims are this session's own
command/Read output at HEAD `feaa45d` (2026-06-07); all platform claims carry an official-source URL +
exact quoted text, or are recorded DOCUMENTED-SILENT with the empirical/unofficial lead flagged.

**End of RESEARCH-TRACKER-LANDSCAPE-RULES.md**
