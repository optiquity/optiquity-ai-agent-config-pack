# RESEARCH-BD-204 — Complete GitHub Issues rule set + entry-violation census + design-compliance map

> **Revised after adversarial verification (RESEARCH-BD-204-GH-ISSUES-RULES-VERIFY.md); 3 missed rules
> + 2 nuances folded in.** The verifier confirmed every value + every census number; the fold-in adds
> R-BODY-7 (gzipped-request enforcement axis / MISS-1), R-OPS-6 (autolink/mention side-effects /
> MISS-2), R-ACCT-4 (archived-repo read-only / MISS-3), and enriches R-OPS-2 (abuse-flagging /
> NUANCE-A) + R-STATE-2 (`duplicate` recency / NUANCE-B). Every folded source was re-checked by me this
> session. Rule count: **25 -> 28** (see Section 1 reconciliation). Fold-in ledger at Section 8.
>
> **Second fold-in (2026-06-07): 2 census-gap rules, architect completeness pass**
> (SWEEP-BD-204-RULES-COMPLIANCE.md §S-9 / design §11.3). Two gaps made newly relevant by two late
> user decisions — (a) scratch rehearsals are REPEATABLE (many throwaway repos), and (b) the PAT has
> NO repo-delete permission (archive only → archived scratch repos ACCUMULATE). Added R-OPS-7
> (repo-CREATION rate limit) + R-ACCT-5 (account repo QUOTA + on-disk size). Every source re-checked by
> me this session. Rule count: **28 -> 30** (see Section 1 reconciliation + the Section 9 second-fold-in
> ledger).
>
> **Role:** pack-docs-researcher. **Mode:** read-only repo + ONLINE research; one report write. No design.
> **Scope:** PACK-ONLY (project-side read only; nothing edited; no git verb).
> **HEAD (verified):** `feaa45dcb7a39dd3cc12fb4ff9c234d9845cfb53` (`git rev-parse HEAD`). **Date:** 2026-06-07.
> **Mandate (external-rules-census-before-design):** enumerate the COMPLETE official GitHub Issues
> rule set UP FRONT from authoritative sources, census all 211 backlog entries (raw + projected) for
> violations, and map each rule to the design/code. No incremental discovery; no invented behavior.
>
> **Verification convention.** Every PLATFORM claim carries: official URL + exact quoted text +
> verified value + GA/personal-account availability. Every REPO-STATE claim carries an Empirical-
> Evidence Block: `CMD` · `OUT` (verbatim) · `AT` (HEAD `feaa45d`, 2026-06-07) · `INTERP` · `CONCL`.
> All repo measurements are my own, run this session.
>
> **Target environment (per verify-availability-not-just-existence).** The pack's GitHub account is an
> **individual / personal** account (`DShaneNYC/optiquity-ai-agent-config-pack`, per
> `.github/ISSUE_TEMPLATE/config.yml:8` discussions URL). The design space is **GA + personal-account
> only**. Every rule below is checked on those axes.

---

## §0 — Bottom line

The complete GitHub Issues rule set governing lossless entry transport is **30 rule rows** across 8
categories (§1) — 28 after the first (adversarial-verification) fold-in, +2 after the second
(architect-completeness) fold-in that added the REPEATABLE-multi-scratch census gaps: R-OPS-7
(repo-CREATION has no repo-specific rate limit — governed by the general secondary caps, so the
issue-pacing gate bounds the cadence) and R-ACCT-5 (personal repos UNLIMITED below a 100,000 hard cap;
archived scratch repos COUNT but accumulate harmlessly — issues live in the database, not the 10 GB
on-disk `.git` budget). Censused against all 211 `backlog/BD-*.md` entries — both raw and under the current
verbatim-blob projection (ARCHITECTURE-BD-204-LOSSLESS-FIX.md §3.3) — **every hard CONTENT limit is
satisfied with headroom**: the largest projected Issue body is BD-136 at 40,771 bytes (62.2% of the
65,536 limit); the longest title is 223 chars (raw) / 231 chars (ID-prefixed stored form), under the
256 limit; the longest generated label is 24 chars, under the 50 limit; no entry body carries a NUL
byte, CR, or non-LF/non-tab control character. **Two rules are DOCUMENTED-SILENT** (issue-body
web-edit normalization; HTML-comment/autolink storage-vs-render) — for both, the design already relies
on empirically-grounded handling (the gz64 blob rides the safe base64 alphabet inside an HTML comment;
the §3.3a comparator is normalization-tolerant).

The genuine OPERATIONAL gaps (not content-limit violations — every content limit is clean) are three,
all surfaced by the adversarial verification and folded into this revision: (1) the **secondary rate
limit** for the C-8 bulk create of 211+ issues — the design is SILENT on the documented "wait ≥1
second between mutative requests / serial" mitigation AND on the abuse/spam-flagging + account-
invisibility risk of an unpaced burst (R-OPS-2/3 + R-OPS-6 side-effects); (2) **autolink / @mention
side-effects** — 21 entries carry `#NNN` tokens and 2 carry a bare `@`-token outside inline-code that
will auto-generate spurious cross-links / fire mention notifications on a real-repo create (R-OPS-6 /
MISS-2); (3) **archived-repo read-only** — BD-204.md:20's "scratch-repo proof -> archive -> real flip"
dogfood wording needs architect/user disambiguation, because operating on an archived repo (create
issue / edit label / reverse-sync write) is IMPOSSIBLE (R-ACCT-4 / MISS-3). A further enforcement-axis
nuance (the 65,536 limit is, per multiple practitioner sources, enforced on the GZIPPED REQUEST
PAYLOAD, not the raw stored count — R-BODY-7 / MISS-1) leaves the conservative size budget SAFE but
should ground the architect's size contract in the real enforcement model.

---

## §1 — THE COMPLETE GITHUB ISSUES RULE SET (official sources, GA + personal-account verified)

Each rule: ID · the limit/behavior · official source URL + exact quoted text · verified value ·
personal-account GA availability.

### Category A — Issue BODY

**R-BODY-1 — Issue body maximum size = 65,536 characters (codepoints).**
- Source (primary, official error surface): the GitHub REST API returns
  `422 Unprocessable Entity` with `"Body is too long (maximum is 65536 characters)"` when an issue/PR
  body or comment exceeds the limit. Quoted error (community discussion + many action repos):
  *"Body is too long (maximum is 65536 characters)"*.
  - <https://github.com/orgs/community/discussions/41331> ("Cannot create issue - Comment is too long (maximum is 65536 characters)")
  - <https://github.com/reviewdog/reviewdog/issues/1065> (verbatim `422 Unprocessable Entity ... Body is too long (maximum is 65536 characters)`)
- Source (compiled limits reference, with verification method):
  <https://github.com/dead-claudia/github-limits/blob/master/README.md> §"Issue description":
  exact quote: *"Min length: 0 characters / Max length: 65536 codepoints"* — verification:
  *"verified by creating an issue with a very long description and confirmed with an error message."*
- **Verified value:** 65,536 codepoints (the unit is CODEPOINTS for issue *description*, not bytes —
  see R-BODY-2 for the comment/byte nuance). The github-limits note records the underlying store as a
  MySQL `mediumblob` max 262,144 (= 65,536 × 4-byte UTF-8 worst case).
- **Over-limit behavior:** API ERROR (422), NOT truncation. A too-long body is rejected; nothing is
  silently dropped.
- **Availability:** GA, personal-account — applies to all repos.

**R-BODY-2 — Issue COMMENT body limit is byte-measured (262,144 bytes), distinct from the description
codepoint limit.**
- Source: <https://github.com/dead-claudia/github-limits/blob/master/README.md> §"Issue comments":
  exact quote: *"Min length: 1 character / Max length: 262144 bytes (65536-262144 characters depending
  on UTF8-encoded size)"* — *"verified by POST-ing bodies of various sizes to a dummy issue via the V3 API."*
- **Verified value:** comments = 262,144 BYTES; issue *description* (R-BODY-1) = 65,536 CODEPOINTS.
  These are different units. The design carries entry content in the issue BODY (description), so
  R-BODY-1 (codepoints) is the binding limit; comments are dropped by the design (§1 cat. G).
- **DOCUMENTED-SILENT nuance:** whether the issue *description* limit is exactly 65,536 codepoints vs
  bytes is asserted differently across sources (the error string says "characters"; the store is a
  262,144 mediumblob). The design's conservative byte-based budget (§3.3c) treats the limit as 65,536
  BYTES — which is the SAFE (smaller-or-equal) interpretation for ASCII/base64 content. See §4.
- **Availability:** GA, personal-account.

**R-BODY-3 — The 65,536 limit also applies to PR bodies and is enforced via REST/GraphQL identically.**
- Source: <https://github.com/dead-claudia/github-limits/blob/master/README.md> §"PR body":
  *"Max length: 65536 codepoints ... verified by making PATCH requests to
  /repos/{owner}/{repo}/pulls/{pull_number} with "body" ... and ... adding longer body (262,145
  characters) ... confirmed with the error: There was an error posting your comment: Body is too long."*
- **Verified value:** same 65,536 limit on the write path (POST/PATCH), web and API.
- **Availability:** GA, personal-account.

**R-BODY-4 — Stored body byte-fidelity / server-side rewriting: DOCUMENTED-SILENT.**
- Official docs describe Markdown RENDERING (autolinks, @mentions, issue-reference autolinks) but do
  NOT state whether the STORED raw body is byte-verbatim or whether autolink/mention processing
  rewrites stored content. Markdown autolinking is a RENDER-time transform per
  <https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax>
  (autolinked references render `#N`/`@user` as links) — but the docs do not assert storage rewriting.
- **DOCUMENTED-SILENT.** Empirical basis: HTML comments (`<!-- ... -->`) are widely used as hidden
  body markers (the pack's own form family `.github/ISSUE_TEMPLATE/work-item.yml:103-105` stores
  `<!-- pack-id: ... -->` markers; the design stores `<!-- pack-entry-body-gz64: ... -->`) and are
  preserved in the stored body (they re-emit on edit). No official doc CONFIRMS this; it is empirically
  relied upon by the design and by GitHub's own form templates. What is needed to fully close this:
  an empirical round-trip on the live target repo (the C-7 oracle's job) confirming the stored body
  decodes byte-identically. Do NOT assert byte-verbatim storage as a documented fact.

**R-BODY-5 — Web-edit body normalization (line endings / trailing whitespace): DOCUMENTED-SILENT for
the issue-body field specifically.**
- Official docs cover (a) GIT FILE line-ending normalization via `.gitattributes`
  (<https://docs.github.com/en/get-started/git-basics/configuring-git-to-handle-line-endings>) and
  (b) the web CODE editor (Monaco-based) normalizing file content on load
  (<https://github.com/orgs/community/discussions/142407> "Github should not automatically change line
  endings"). Neither documents the ISSUE-BODY textarea's normalization behavior.
- **DOCUMENTED-SILENT.** Empirical basis (and the design's own grounding,
  ARCHITECTURE-BD-204-LOSSLESS-FIX.md §3.3a (ii) / N-2): a web round-trip of an issue body
  canonicalizes CRLF→LF and strips per-line trailing whitespace. This is asserted by the design as
  GitHub's "documented body munging" but the citation given is the codebase's own whitespace-tolerant
  precedent (`tracker-mirror.sh`), NOT an official GitHub doc. What is needed: an empirical web-edit
  round-trip on the target repo. The design's tolerant comparator (§3.3a) is sized to exactly this
  conjectured normalization — appropriately conservative, but the normalization itself is NOT
  officially documented for the issue-body field.

**R-BODY-6 — Unicode / control-character / null-byte handling in bodies: PARTIALLY DOCUMENTED.**
- Official docs do not enumerate forbidden control characters in issue bodies. The body is UTF-8
  Markdown. NUL bytes and most C0 control characters are not valid in a text field and are not
  documented as accepted. DOCUMENTED-SILENT on the exact accepted control-char set. Empirical basis:
  the pack tree carries NONE of these (§2 census R-BODY-6 row), so the question is MOOT for the live
  data — but a future entry introducing a NUL/CR/control byte is an UNDEFINED-behavior risk.

**R-BODY-7 — The 65,536 limit is (per multiple authoritative practitioner sources) enforced on the
GZIPPED API-REQUEST PAYLOAD size, not only the raw stored character/byte count. [FOLDED IN — MISS-1]**
- Source: <https://github.com/orgs/community/discussions/41331> ("Cannot create issue - Comment is too
  long (maximum is 65536 characters)") + the action-repo cluster reporting the same behavior:
  <https://github.com/changesets/action/issues/174>, <https://github.com/renovatebot/renovate/issues/14551>.
  Exact reported behavior (community#41331, re-verified by me this session via WebSearch):
  *"The 65536-character limit is based on the API call's gzipped size, not raw character count"* — one
  report: *"a 231k-character comment was able to be posted successfully and resulted in a 55K API call."*
- **Verified value:** the binding enforcement is (per these sources) the GZIPPED REQUEST size against a
  ~65,536 budget — a THIRD axis distinct from R-BODY-1 (stored codepoints) and R-BODY-2 (stored
  bytes). The official error string still says "65536 characters"; the docs do NOT state which axis is
  authoritative — so this is an AUTHORITATIVE-PRACTITIONER claim, not an official-doc claim (recorded
  as such, not invented).
- **Net effect / availability:** FAVORABLE and GA, personal-account. If the binding limit is the
  gzipped request, the design's conservative stored-byte budget (§3.3c; worst BD-136 62.2% of 65,536
  STORED) is even safer than claimed, since the request gzips again in transit. It does NOT break the
  design — but the architect's size contract (`provider_body_limit`, §3.3c) should state WHICH axis it
  targets (the safe choice is to keep the conservative stored-byte budget, which bounds all three
  axes). See §3 R-BODY-7 row and §4 DS-3.

### Category B — Issue TITLE

**R-TITLE-1 — Title length: min 1, max 256 characters.**
- Source: <https://github.com/dead-claudia/github-limits/blob/master/README.md> §"Issue title":
  exact quote: *"Min length: 1 character / Max length: 256 characters"* — *"verified by creating an
  issue with a very long title and confirmed with an error message."*
- **Verified value:** 256 chars max, 1 char min. Over-limit ⇒ validation error (not truncation).
- **Availability:** GA, personal-account.

**R-TITLE-2 — Title is single-line; newlines not permitted.**
- The title is an `<input>`-class single-line field (the work-item form uses
  `title: "BD-NNN: <short title>"` as a single line, `.github/ISSUE_TEMPLATE/work-item.yml:3`).
  Official docs do not explicitly state "no newline," so this leg is DOCUMENTED-SILENT but
  structurally enforced (titles are single-line by the platform's title input). Empirical basis: the
  design's title source is the bold-header line (single line by `_rules.md` ID-extraction), so a
  newline cannot arise. MOOT for the data.

### Category C — LABELS

**R-LABEL-1 — Label name max length = 50 characters.**
- Source (validation, with the documentation-gap acknowledgment): <https://github.com/github/docs/issues/32156>
  ("Document the character limit of label names") — the API validation error is
  *"name is too long (maximum is 50 characters)"*. github-limits does not list labels; the doc-issue
  is the authoritative pointer.
- **Verified value:** 50 chars max (emoji count toward it, as UTF-8 codepoints).
- **Availability:** GA, personal-account.

**R-LABEL-2 — Maximum labels per issue/PR = 100.**
- Source: <https://docs.github.com/en/issues/using-labels-and-milestones-to-track-work/managing-labels>
  (Managing labels) — and the community confirmation
  <https://github.com/orgs/community/discussions/76832>: a maximum of 100 labels per issue/PR.
- **Verified value:** 100 labels/issue.
- **Availability:** GA, personal-account.

**R-LABEL-3 — Label description max length = 100 characters.**
- Source: <https://github.com/orgs/community/discussions/189718> ("Entering a Issue Label Description
  longer than 101 characters throws an error") + github-presets confirmation. The design sets no
  custom label descriptions, so this is informational.
- **Verified value:** 100 chars. **Availability:** GA, personal-account.

**R-LABEL-4 — Label name case/charset: case-preserving, case-INSENSITIVE-unique; broad charset incl.
emoji and colons.**
- Source: <https://docs.github.com/en/issues/using-labels-and-milestones-to-track-work/managing-labels>
  + <https://github.blog/2018-02-22-label-improvements-emoji-descriptions-and-more/> (emoji in label
  names). Colons are permitted in label names (the pack uses `status:open`, `template:bd-v11.0`).
- **Verified value:** label names admit `:` and arbitrary UTF-8; uniqueness is case-insensitive within
  a repo. **Availability:** GA, personal-account.

### Category D — STATE

**R-STATE-1 — `state` enum = {open, closed}.**
- Source: <https://docs.github.com/en/rest/issues/issues?apiVersion=2022-11-28> (Update an issue):
  exact quote: *"state string The open or closed state of the issue. Can be one of: open, closed"*.
- **Verified value:** exactly two states. **Availability:** GA, personal-account.

**R-STATE-2 — `state_reason` enum (on close/update) = {completed, not_planned, duplicate, reopened, null}.**
- Source: <https://docs.github.com/en/rest/issues/issues?apiVersion=2022-11-28> (Update an issue):
  exact quote: *"state_reason string or null The reason for the state change. Ignored unless state is
  changed. Can be one of: completed, not_planned, duplicate, reopened, null"*.
- **Verified value:** 4 non-null values + null. `state_reason` is IGNORED unless `state` changes.
- **Availability:** GA, personal-account. (Note: `duplicate` as a `state_reason` value is GA per this
  current doc; the pack's status mapping uses only `completed`/`not_planned` — see §3.)
- **NUANCE-B [FOLDED IN].** `duplicate` is a RECENT (Dec-2024) addition that BROKE existing clients.
  Source (re-verified by me this session): changelog 2024-12-12
  <https://github.blog/changelog/2024-12-12-github-issues-projects-close-issue-as-a-duplicate-rest-api-for-sub-issues-and-more/>
  + community#150535 *"`Issue.state_reason` can now be `duplicate`, breaking existing clients."*
  <https://github.com/orgs/community/discussions/150535>. The enum value IS GA on github.com, but its
  recency matters if an OLDER GH-Enterprise-Server target is ever in scope (it may not emit/accept it),
  and the pack's reverse decode that parses `state_reason` must tolerate the value's presence/absence.

### Category E — IDENTITY

**R-ID-1 — Issue numbers: min 1, max 1,073,741,824; assigned by the platform, never settable,
monotonic per repo, never reused.**
- Source: <https://github.com/dead-claudia/github-limits/blob/master/README.md> §"Issue/pull request
  numbers": exact quote: *"Max value: 1073741824 (max 4-byte Ruby integer) / Min value: 1"*.
- **Verified value:** issue numbers are platform-assigned, immutable, sequential, non-reusable. The
  REST create endpoint has NO `number` input. **Availability:** GA, personal-account.
- **Design relevance:** the design correctly keys identity on the `pack-id` marker, NOT the issue
  number (BD-204.md:11 "Identity keys on the `pack-id` marker, NEVER on GH Issue numbers").

**R-ID-2 — created_at / updated_at timestamps are NOT settable via the standard REST create/update
endpoints (server-controlled).**
- Source: <https://docs.github.com/en/rest/issues/issues?apiVersion=2022-11-28> — the "Create an
  issue" and "Update an issue" body-parameter tables list `title, body, assignee(s), milestone,
  labels, state, state_reason, type` — NO `created_at`/`updated_at` write parameter; those appear only
  in RESPONSE objects.
- **Verified value:** timestamps server-set, not settable (the legacy Issue Import API could set
  them, but that is a separate, non-GA-documented endpoint and out of scope). **Availability:** GA,
  personal-account.
- **Design relevance:** original authoring timestamps are NOT preservable through GH Issue metadata;
  if an entry's authoring date matters, it must live INSIDE the body (it does — entries carry
  `Resolved:`/dated prose), which the verbatim blob preserves.


### Category F — OPERATIONS (rate limits, pagination, search — for the C-8 create of 211+ issues and the reverse lister)

**R-OPS-1 — Primary rate limit: 5,000 requests/hour (authenticated personal token); 60/hour
(unauthenticated).**
- Source: <https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api>
  ("About primary rate limits"): exact quote: *"All of these requests count towards your personal
  rate limit of 5,000 requests per hour."* and *"The primary rate limit for unauthenticated requests
  is 60 requests per hour."*
- **Verified value:** 5,000/hr authenticated (personal access token). Creating 211 issues is far under
  the hourly primary cap. **Availability:** GA, personal-account.

**R-OPS-2 — Secondary rate limit: ≤ 80 content-generating requests/minute AND ≤ 500/hour; some
endpoints lower.**
- Source: <https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api>
  ("About secondary rate limits"): exact quote: *"In general, no more than 80 content-generating
  requests per minute and no more than 500 content-generating requests per hour are allowed. Some
  endpoints have lower content creation limits. Content creation limits include actions taken on the
  GitHub web interface as well as via the REST API and GraphQL API."*
- **Verified value:** 80/min and 500/hour content-creating. **211 issue creates EXCEEDS the 500/hour
  secondary cap if done in one burst** — this is the binding operational constraint for C-8.
- **Over-limit behavior:** exact quote: *"you will receive a 403 or 429 response and an error message
  that indicates that you exceeded a secondary rate limit. If the retry-after response header is
  present, you should not retry your request until after that many seconds has elapsed."*
- **NUANCE-A [FOLDED IN] — abuse/spam-flagging + account-invisibility risk (sharper than a 403/429).**
  The secondary limits exist "to prevent abuse"; an unpaced burst of hundreds of creates can trip
  GitHub's ABUSE DETECTION, a WORSE failure than a transient 429 — it can mark a personal account as
  spammy / invisible. Source (re-verified this session): docs Rate-limits (secondary limits prevent
  abuse) + community#110990 ("Account marked as spammy and went invisible")
  <https://github.com/orgs/community/discussions/110990>. For a PERSONAL account dogfooding 211 creates,
  this raises the stakes on the pacing the design currently leaves SILENT (see §3 R-OPS-2 row).
- **Availability:** GA, personal-account.

**R-OPS-3 — Required mitigation: serialize writes + wait ≥ 1 second between mutative requests.**
- Source: <https://docs.github.com/en/rest/guides/best-practices-for-using-the-rest-api>
  ("Pause between mutative requests"): exact quote: *"If you are making a large number of POST, PATCH,
  PUT, or DELETE requests, wait at least one second between each request. This will help you avoid
  secondary rate limits."* and ("Avoid concurrent requests"): *"To avoid exceeding secondary rate
  limits, you should make requests serially instead of concurrently."*
- **Verified value:** ≥ 1 s/request, serial. At 211 issues × (≥1 s) the forward migration must pace
  itself; AND the 500/hour secondary cap means a single-shot 211-create run must spread across time or
  handle 403/429 + `retry-after`. **Availability:** GA, personal-account.

**R-OPS-4 — Listing/pagination: max `per_page` = 100; Link-header pagination for the full set.**
- Source: <https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api>
  — `per_page` capped at 100; use the `link` header to traverse. The reverse lister enumerating 211+
  issues needs ≥ 3 pages (211 ÷ 100). **Availability:** GA, personal-account.

**R-OPS-5 — Search API: ≤ 1,000 results/query; ≤ 100/page; query ≤ 256 chars + ≤ 5 boolean
operators; 30 search requests/minute.**
- Source: <https://docs.github.com/en/rest/search/search?apiVersion=2022-11-28>: exact quotes:
  *"the GitHub REST API provides up to 1,000 results for each search"*; *"Limitations on query length
  You cannot use queries that: Are longer than 256 characters (not including operators or qualifiers).
  Have more than five AND, OR, or NOT operators."*; *"For authenticated requests, you can make up to
  30 requests per minute for all search endpoints except for the Search code endpoint."*
- **Verified value:** 1,000-result ceiling; 100/page; 256-char query; 5 operators; 30 searches/min.
- **Design relevance:** with 211 pack issues, the 1,000-result search ceiling is not yet binding, but
  the reverse path should LIST (R-OPS-4, unbounded via Link header) rather than SEARCH for completeness
  if the set could exceed 1,000. **Availability:** GA, personal-account.

**R-OPS-6 — Autolink / cross-reference / @mention SIDE-EFFECTS on creating issues whose bodies carry
`#NNN` / `@name` tokens (spurious backlinks; real-user notifications). [FOLDED IN — MISS-2]**
- Source (official): docs "Autolinked references and URLs"
  <https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/autolinked-references-and-urls>
  — references like `#NNN` *"are automatically converted to shortened links"* and create a BACKLINK
  from the referenced issue; `@username` mentions notify the user (docs basic-formatting). There is NO
  documented way to suppress standard cross-linking (only the `redirect.github.com` workaround).
  Re-verified this session.
- **Verified value / behavior:** on CREATING a verbatim body, GitHub autolinks each `#NNN` to whatever
  issue/PR holds that number IN THE TARGET REPO (the pack's `#1`..`#N` tokens are Actions-step /
  footnote references, NOT GH issue numbers — so they MIS-LINK to unrelated target-repo issues), and
  fires a mention notification for any `@token` that resolves to a real GH username AND is not inside an
  inline-code span (GitHub does not render mentions inside backticks).
- **Net effect / availability:** GA, personal-account. This is an OPERATIONAL HYGIENE / NOISE rule, NOT
  a losslessness break — the `#NNN`/`@` tokens decode byte-identically from the gz64 blob (the round-
  trip is unaffected; only the VISIBLE H2 autolinks). Material to a CLEAN dogfood: scratch-repo (C-7)
  absorbs the noise; the REAL-repo flip (C-8) will scatter cross-ref backlinks / possibly fire mention
  notifications. See the §2 R-OPS-6 census (21 `#NNN`-bearing + 2 bare-`@` entries) and §3 R-OPS-6 row.

**R-OPS-7 — REPOSITORY CREATION has NO documented repo-specific rate limit; it is a content-generating
mutation governed by the GENERAL secondary rate limits (+ the abuse/concurrency/points/CPU caps).
[FOLDED IN — GAP 1 / architect §11.3]**
- Source (official): <https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api>
  ("About secondary rate limits"). GitHub documents NO repository-creation-specific limit. Repo create
  (`POST /user/repos`, `gh repo create`) is a content-generating request, so the SAME secondary caps as
  issue creation apply. Exact quotes (re-fetched this session): *"In general, no more than 80
  content-generating requests per minute and no more than 500 content-generating requests per hour are
  allowed."*; *"No more than 100 concurrent requests are allowed. This limit is shared across the REST
  API and GraphQL API."*; *"No more than 900 points per minute are allowed for REST API endpoints..."*;
  *"No more than 90 seconds of CPU time per 60 seconds of real time is allowed."* The doc also frames
  the whole secondary regime as existing *"to prevent abuse"* (the same abuse-detection dimension as
  NUANCE-A on R-OPS-2).
- **Verified value / DOCUMENTED-SILENT scope:** there is NO repo-create-specific per-hour/per-day
  count in official docs — DOCUMENTED-SILENT on a repo-only threshold. What the GENERAL limits IMPLY
  for a multi-rehearsal cadence: a single scratch repo per rehearsal is 1 content-creating mutation —
  trivially under 500/hour even with dozens of rehearsals; the BINDING constraint is NOT the repo
  create itself but the 211 ISSUE creates that follow each repo (R-OPS-2), and the abuse-detection risk
  (NUANCE-A) of an unpaced burst. So a repeatable cadence of N scratch repos/day is safe on the
  repo-create axis PROVIDED each rehearsal's 211 issue-creates are PACED (R-OPS-3, ≥1s/serial) and
  spread under 500/hour — i.e. the issue-pacing gate the design already owes (§3.3d) is what bounds the
  cadence, not a separate repo-create gate.
- **Net effect / availability:** GA, personal-account. No NEW pacing mechanism is required for the repo
  create itself; the rule is recorded so the design's cadence rests on the documented general limits,
  not an assumed repo-specific one. See §3 R-OPS-7 row.

### Category G — COMMENTS (enumerated for completeness; the design DROPS them)

**R-COMMENT-1 — Comment body limit = 262,144 bytes (see R-BODY-2); min 1 char.**
- Source: github-limits §"Issue comments" (quoted at R-BODY-2). Comments are a separate object from
  the issue body. **Availability:** GA, personal-account.
- **Design relevance:** ARCHITECTURE-BD-204-LOSSLESS-FIX.md and the carrier memory
  (`feedback_tracker_carrier_no_sidecar`) DROP comments/reactions/attachments for v11.0 — all entry
  content rides the issue BODY. No pack entry uses GH comments (entries are flat files), so dropping
  comments loses nothing for the migration. (Completeness note only.)

### Category H — ACCOUNT-TYPE constraints on touched features

**R-ACCT-1 — Issue Forms / templates: GA on personal accounts.**
- Source: <https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository>
  — YAML issue forms (`.github/ISSUE_TEMPLATE/*.yml`) work on any public repo, personal or org.
  The pack's `work-item.yml` / `inbound.yml` / `config.yml` are in use. **Availability:** GA, personal.

**R-ACCT-2 — Labels & open/closed state: GA on personal accounts** (the only tracker capabilities the
design's status mapping requires). **Availability:** GA, personal.

**R-ACCT-3 — Issue Fields (custom typed fields) and custom Issue Types: ORG-ONLY and/or PREVIEW —
UNUSABLE on the personal pack account; EXCLUDED from the design.**
- This confirms the standing `feedback_verify_availability_not_just_existence` finding (BD-204,
  2026-06-05): GH Issue Fields are org-only + preview; custom Issue Types are org-only. The pack
  account is personal (`DShaneNYC/...`). The design correctly excludes both (BD-204.md:14 DECISION
  TIERS "GA + personal-account GH features ONLY (NO Issue Fields / Issue Types — org-only/preview)").
- **Verified value:** OUT of the design space. This is WHY the design must carry structured fields in
  the body blob rather than native typed fields.

**R-ACCT-4 — An ARCHIVED repository is fully READ-ONLY: no issue create, no label edit, no
reverse-sync write — for everyone, including the owner. [FOLDED IN — MISS-3]**
- Source (official): docs "Archiving repositories"
  <https://docs.github.com/en/repositories/archiving-a-github-repository/archiving-repositories>
  — exact quotes (re-fetched this session): *"You can archive a repository to make it read-only for
  all users and indicate that it's no longer actively maintained."* and *"When a repository is
  archived, its issues, pull requests, code, labels, milestones, projects, wiki, releases, commits,
  tags, branches, reactions, code scanning alerts, comments and permissions become read-only. To make
  changes in an archived repository, you must unarchive the repository first."*
- **Verified value:** an archived repo CANNOT have issues created, labels edited, or any write applied
  — every C-8 forward write and every reverse-sync write is IMPOSSIBLE on an archived repo. GA,
  personal-account (applies to all repos, including personal).
- **Design relevance:** BD-204.md:20 scope reads *"Dogfood-sequence gated (scratch-repo proof ->
  archive -> real flip)."* A literal "operate on an archived repo" reading is IMPOSSIBLE. The likely
  intent is "archive the THROWAWAY scratch proof repo AFTER the proof, then flip the REAL repo" (archive
  = teardown of the scratch, not an operate-on-archived step) — but the wording is AMBIGUOUS and this
  research does NOT resolve it; it is FLAGGED for architect/user disambiguation (see §3 R-ACCT-4 row).
  *This is a fact-and-flag only; resolving the sequence is a design decision, out of researcher scope.*

**R-ACCT-5 — A personal account owns UNLIMITED public + private repos; the only hard cap is 100,000
repositories per account (banner at 50,000); archived repos COUNT toward it; the on-disk size
recommendation (10 GB) is the `.git` folder, which issues do NOT consume. [FOLDED IN — GAP 2 /
architect §11.3]**
- Source (official, repo count): <https://docs.github.com/en/get-started/learning-about-github/types-of-github-accounts>
  exact quote: *"All personal accounts can own an unlimited number of public and private repositories,
  with an unlimited number of collaborators on those repositories."*
- Source (official, hard cap): <https://docs.github.com/en/repositories/creating-and-managing-repositories/repository-limits>
  ("Organization and account limits") exact quote: *"Organizations and accounts may not exceed 100,000
  repositories. When an account surpasses 50,000 repositories, a banner will appear, noting the
  approaching limit. Additionally, administrators will receive email notifications, and the audit log
  will update every additional 5,000 repositories created."*
- Source (official, on-disk size): same repository-limits doc exact quote: *"On-disk size: 10 GB.
  On-disk size refers to the size of the .git folder (the compressed form of the repository)."* (this
  is a RECOMMENDATION — *"we recommend staying within the following maximum limits"* — not a hard cap.)
- **Verified value:** personal-account repo count is UNLIMITED below the 100,000 hard cap; archived
  repos are NOT exempted (the doc states no archive exception — they count). The 10 GB on-disk figure
  is the `.git` (code) folder only.
- **Do accumulating archived scratch repos (each ~211 issues) approach any quota? — NO (verified).**
  (a) REPO COUNT: each rehearsal that archives one scratch repo adds 1 toward the 100,000 cap; even a
  daily multi-rehearsal campaign over years stays orders of magnitude below 100,000 (and the 50,000
  banner). (b) ON-DISK SIZE: ISSUES live in GitHub's DATABASE, NOT the `.git` folder — the on-disk
  recommendation measures the repository's git content (compressed `.git`), and a scratch repo carries
  ~no code, so 211 issues consume ~0 of the 10 GB on-disk budget. So accumulating archived
  issue-heavy scratch repos approaches NEITHER the repo-count cap NOR the on-disk recommendation.
- **Net effect / availability:** GA, personal-account, FREE plan. The accumulation is benign on both
  quota axes; the design's §5.c archive-not-delete disposal does not risk a quota wall. (Per the
  architect's §11.3 mitigation menu, public scratch repos / prompted manual delete remain optional
  housekeeping, not a quota necessity.) See §3 R-ACCT-5 row.

### §1 rule-count reconciliation

30 rule rows: A (R-BODY-1..7 = 7) + B (R-TITLE-1..2 = 2) + C (R-LABEL-1..4 = 4) + D (R-STATE-1..2 = 2)
+ E (R-ID-1..2 = 2) + F (R-OPS-1..7 = 7) + G (R-COMMENT-1 = 1) + H (R-ACCT-1..5 = 5) = 30 rule rows
across 8 categories (was 25 at first census; first fold-in +R-BODY-7 MISS-1 / +R-OPS-6 MISS-2 /
+R-ACCT-4 MISS-3 -> 28; second fold-in +R-OPS-7 GAP-1 / +R-ACCT-5 GAP-2 -> 30).
(Hard CONTENT-limit rules that gate lossless transport: R-BODY-1/2/3,
R-TITLE-1, R-LABEL-1/2 — these are the §2 census's primary axes; the rest are behavior/operational.)


---

## §2 — ENTRY-VIOLATION CENSUS (all 211 entries: raw + projected, against every §1 content rule)

Projection model (per ARCHITECTURE-BD-204-LOSSLESS-FIX.md): TITLE = bold-header text after the
em-dash; BODY = visible H2 sections (upper-bounded by raw body) + the `pack-entry-body-gz64` blob
(gzip-mtime0 + base64 of lines 2..EOF) + marker wrapper; LABELS = static form labels
(`work-item`, `needs-triage`, `template:work-item-v11.0`) + computed (`bd-entry`, `template:bd-v11.0`,
`status:<x>`). Each rule states the violating-entry list explicitly; an EMPTY list is a proven-clean
result.

> **Empirical-Evidence Block (entry count).**
> `CMD`: `ls backlog/BD-*.md | wc -l`
> `OUT`: `211`. `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: 211 per-entry files — the census universe.
> `CONCL`: SUPPORTED.

### R-TITLE-1 (title ≤ 256 chars) — CLEAN (0 violations)

> **Empirical-Evidence Block (max title length across all 211 bold-headers).**
> `CMD`: python over all `backlog/BD-*.md`, extract the `^\*\*(BD-\d{3})\s*[—-]\s*(.+?)\*\*$`
> group-2 (title), measure `len()`.
> `OUT`: max title length = **223** (BD-208); titles > 256: **0** (empty list). Top 5: BD-208 223,
> BD-200 189, BD-169 174, BD-180 153, BD-211 150. `AT`: HEAD `feaa45d`, 2026-06-07.
> `INTERP`: every raw title is under 256. The longest stored title under the form's `BD-NNN: <title>`
> shape = ID(6) + `: `(2) + 223 = **231** (BD-208) — still under 256. `CONCL`: SUPPORTED.
> **Violating entries: NONE.** (Headroom: 256 − 231 = 25 chars on the worst entry; a new title ≥ 248
> chars after the ID-prefix would breach — informational only.)

### R-TITLE-2 (single-line, no newline) — CLEAN (0 violations)

> **Empirical-Evidence Block (title control-character scan).**
> `CMD`: scan each bold-header group-2 for codepoints < 0x20.
> `OUT`: titles with control chars: **[]** (empty). `AT`: HEAD `feaa45d`, 2026-06-07.
> `INTERP`: titles are single-line by the `_rules.md` ID-extraction grammar; none carries a control
> char or embedded newline. `CONCL`: SUPPORTED. **Violating entries: NONE.**
> (26 titles contain non-ASCII codepoints — em-dashes / typographic chars — which are VALID in titles
> per R-TITLE-1; not a violation, recorded for completeness.)

### R-BODY-1 / R-BODY-2 / R-BODY-3 (issue body ≤ 65,536) — CLEAN under the gz64 projection (0 violations)

> **Empirical-Evidence Block (projected body size, all 211, gz64 vs raw-base64).**
> `CMD`: per entry, body = bytes after line 1 (back-pointer stripped); `gz64` = base64(gzip mtime=0);
> projected body = `len(body) + 80 + 29 + len(blob)`; sort desc; bucket vs 65,536.
> `OUT` (top 6, gz64 projection): BD-136 **40,771 (62.2%)**; BD-191 29,866 (45.6%); BD-203 17,683
> (27.0%); BD-200 16,024 (24.5%); BD-204 15,726 (24.0%); BD-195 15,696 (24.0%). Entries over 80% of
> 65,536: **0**; over 100%: **0**. Largest RAW body (lines 2..EOF) = BD-136 27,954 bytes (42.7% of
> the limit). For contrast, RAW-base64 (the pre-gzip mechanism) projects BD-136 to 65,335 (99.7%) with
> exactly **1** entry over 80%. `AT`: HEAD `feaa45d`, 2026-06-07.
> `INTERP`: under the design's gz64 carrier EVERY projected body is under 63% of the GH limit; the
> worst entry has ~24.7 KB headroom. My independent measurement reproduces the architecture's §3.3c
> figures exactly (BD-136 gz64 40,771 / 62.2%; raw-b64 65,335 / 99.7%). `CONCL`: SUPPORTED.
> **Violating entries (gz64 projection): NONE.** (Under the RETIRED raw-base64 mechanism BD-136 sat at
> 99.7% — a single edit would have breached; this is the precise reactive-discovery the census exists
> to pre-empt. The gz64 decision removes it.)

### R-BODY-6 (no NUL / CR / disallowed control chars in body) — CLEAN (0 violations)

> **Empirical-Evidence Block (body control-character / line-ending scan, all 211).**
> `CMD`: per entry, body bytes after line 1; scan for `\x00`, `\r`, `\t`, and any byte < 0x20 not in
> {tab, LF}.
> `OUT`: NUL bytes: **[]**; CR (`\r`): **[]**; TAB: **0 entries**; other control chars: **{}** (all
> empty). `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: every entry body is clean UTF-8 with LF-only
> line endings, no control bytes — nothing that could trigger undefined platform handling.
> `CONCL`: SUPPORTED. **Violating entries: NONE.**

### R-LABEL-1 (label name ≤ 50 chars) — CLEAN (0 violations)

> **Empirical-Evidence Block (longest generated label name).**
> `CMD`: enumerate the full generated label set (static form labels + computed entry/template/status
> labels from `_tmf_labels_for_entry`), measure `len()`.
> `OUT`: longest = **24** (`template:work-item-v11.0`); next `template:bd-v11.0` 17,
> `status:deprecated` 17, `status:unblocked` 16. `AT`: HEAD `feaa45d`, 2026-06-07.
> `INTERP`: every label the migration sets is ≤ 24 chars, well under 50. The label set is a FIXED
> vocabulary (not derived from free entry text), so no entry can push a label over the limit.
> `CONCL`: SUPPORTED. **Violating entries: NONE.**

### R-LABEL-2 (≤ 100 labels/issue) — CLEAN (0 violations)

> **Empirical-Evidence Block (max labels per migrated issue).**
> `CMD`: count the labels `_tmf_labels_for_entry` + the form static set yield per entry: static
> {work-item, needs-triage, template:work-item-v11.0} + computed {bd-entry, template:bd-v11.0,
> status:<one>}; status maps to exactly ONE label per entry (`sed -n '1515,1530p'
> scripts/lib/tracker-migrate-forward.sh`).
> `OUT`: max labels/issue = **6** (3 static + 3 computed; status contributes exactly 1). `AT`: HEAD
> `feaa45d`, 2026-06-07. `INTERP`: 6 ≪ 100. `CONCL`: SUPPORTED. **Violating entries: NONE.**

### R-STATE-2 (status → state/state_reason maps to a legal value) — CLEAN for the carried mapping

> **Empirical-Evidence Block (distinct Status values across the tree).**
> `CMD`: `for f in backlog/BD-*.md; do tail -n +2 "$f" | grep -m1 -E '^Status:'; done | sed
> 's/Status: *//' | sort | uniq -c`
> `OUT`: `Resolved` 167, `Open` 28, `Deferred` 11, `Deprecated` 3, `Cancelled` 1, `Unblocked` 1.
> `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: 6 distinct lifecycle states. The forward migrator
> (`_tmf_labels_for_entry`) maps each to a `status:*` LABEL (status:open / unblocked / deferred /
> resolved / cancelled / deprecated) — NOT to GH `state_reason`. The OPEN/CLOSED `state` (R-STATE-1)
> and `state_reason` (R-STATE-2, completed/not_planned) are a SEPARATE projection the reverse decode
> handles. The status vocabulary is carried as labels (all ≤ 50 chars, R-LABEL-1) PLUS inside the
> verbatim blob, so no status value is lost. `CONCL`: SUPPORTED. **Violating entries: NONE** against
> R-STATE — all 6 status values have a label mapping (the `Deferred` case was added in C-5, confirmed
> at `scripts/lib/tracker-migrate-forward.sh` `_tmf_labels_for_entry` `Deferred) status_label=
> "status:deferred"`). (NOTE: this is a label-vocabulary observation; whether the CLOSE-path
> `state_reason` mapping is COMPLETE for Cancelled/Deprecated is a design-completeness question, §3
> R-STATE-2 row — not an entry violation.)

### R-ID-1 / R-ID-2 (identity, timestamps) — N/A to entry content (no per-entry violation possible)

Issue numbers are platform-assigned (R-ID-1) and timestamps server-set (R-ID-2); no entry can
"violate" these. The design keys on `pack-id` (correct, R-ID-1). Authoring dates that matter live
inside entry bodies (e.g. BD-204's `(user 2026-06-04)` annotations) and ride the verbatim blob —
preserved. **Violating entries: NONE (rule is structural, not entry-checkable).**

### R-BODY-4 / R-BODY-5 (storage-vs-render / web normalization) — DOCUMENTED-SILENT; census of the
HAZARD surface

Because R-BODY-4/5 are DOCUMENTED-SILENT (§1), I census the entries that EXERCISE the hazard so the
design's empirical handling can be checked against the real data:

> **Empirical-Evidence Block (entries whose body contains HTML-comment / `-->` / code-fence hazards).**
> `CMD`: per entry, body after line 1: `grep -cF '<!--'`; `grep -qF -- '-->'`; `grep -qF '```'`.
> `OUT`: bodies containing `<!--`: BD-065 (1), BD-069 (1), BD-103 (1), BD-136 (12). Bodies containing
> `-->`: **BD-065, BD-069, BD-103, BD-136** (4). Bodies containing a triple-backtick fence:
> **BD-136** (1). `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: 4 entries carry an HTML-comment
> terminator and 1 carries a fence — these are exactly the collision hazards a naive raw-comment or
> fenced carrier would corrupt. Under the gz64 blob (base64 alphabet `[A-Za-z0-9+/=]`, which CANNOT
> contain `-->`, `<!--`, a fence, or a comma) these are SAFE: the blob is collision-proof, so R-BODY-4
> (the marker survives stored-body round-trip) holds for these entries by construction. The VISIBLE H2
> projection still contains the raw `-->`/fence (it re-emits the field values) — but the H2 is advisory
> (not the round-trip source), so a storage-vs-render rewrite of the visible H2 does not lose content
> as long as the blob decodes. `CONCL`: SUPPORTED — the hazard set is bounded (4 + 1) and handled by
> the carrier design, NOT silently dropped. The residual DOCUMENTED-SILENT risk (does GH ever rewrite
> a stored HTML comment?) is unaddressed by official docs and needs the C-7 live oracle to confirm
> empirically. **Entries requiring live-oracle confirmation: BD-065, BD-069, BD-103, BD-136.**

### R-OPS-6 (autolink / @mention side-effects) — census of the HAZARD surface [FOLDED IN — MISS-2]

R-OPS-6 is an operational side-effect rule, not a content-limit; I census the entries whose VERBATIM
body carries autolink/mention triggers, so the design can weigh the C-8 real-repo noise (the round-trip
itself is UNAFFECTED — the tokens decode byte-identically from the gz64 blob).

> **Empirical-Evidence Block (entries whose body carries `#NNN` autolink tokens / `@`-mention tokens).**
> `CMD`: python over all `backlog/BD-*.md` body (lines 2..EOF): `#NNN` = `(?<![\w&])#\d+`; `@`-token
> ANYWHERE = `(?<![\w])@[A-Za-z][A-Za-z0-9._-]*`; `@`-token OUTSIDE inline-code = same regex AFTER
> stripping backtick-delimited code spans (`` `[^`]*` ``), since GitHub does NOT render mentions inside
> inline code.
> `OUT`: bodies with `#NNN`: **21** → `BD-065, BD-066, BD-069, BD-114, BD-128, BD-138, BD-161, BD-164,
> BD-165, BD-166, BD-167, BD-168, BD-169, BD-170, BD-173, BD-179, BD-186, BD-188, BD-189, BD-191,
> BD-192`. Bodies with an `@`-token ANYWHERE: **4** → `BD-023, BD-043, BD-157, BD-158`. Bodies with a
> bare `@`-token OUTSIDE inline-code (the TRUE mention hazard): **2** → `BD-023` (`@objc`), `BD-157`
> (`@ModelAttribute`). `AT`: HEAD `feaa45d`, 2026-06-07.
> `INTERP`: real autolink triggers exist (21 `#NNN`-bearing entries). For mentions, the verifier's
> count of **4** is "`@`-token anywhere"; my reconciliation shows **2** of those carry a bare `@`
> OUTSIDE backticks — BD-043 (`` `@agent-name` ``) and BD-158 (`` `@MainActor` `` etc.) have their `@`
> tokens inside inline-code spans, which GitHub does NOT turn into mentions. Both figures are reported:
> 4 (any `@`) and 2 (true mention hazard). The `#NNN` tokens are Actions-step / footnote references,
> NOT GH issue numbers, so on a real repo they MIS-LINK to whatever issue holds that number. `CONCL`:
> SUPPORTED — the hazard is non-empty (21 cross-link + 2 mention) and was not censused in the original.
> **NOT a losslessness violation** (blob decodes verbatim); an operational-noise rule for C-8.

### §2 census reconciliation (counts cross-checked multiple ways)

- **Universe:** 211 entries (Block above; matches RESEARCH-BD-204-LOSSLESS-FIELD-CENSUS.md §1.1 and
  ARCHITECTURE-BD-204-LOSSLESS-FIX.md §1.4).
- **Hard content-limit rules (R-BODY-1/2/3, R-TITLE-1/2, R-LABEL-1/2, R-BODY-6):** violating set =
  **∅ (empty)** for all eight — every one proven clean by direct measurement over all 211.
- **DOCUMENTED-SILENT hazard surface (R-BODY-4/5):** 4 entries (`-->`) + 1 (fence) flagged for live-
  oracle confirmation; handled by the gz64 carrier; NOT a hard violation.
- **Autolink/mention side-effect surface (R-OPS-6, FOLDED IN):** 21 `#NNN`-bearing + 2 bare-`@`
  (4 any-`@`) entries — an operational-noise hazard for the C-8 real-repo create, NOT a hard violation
  (the blob decodes verbatim).
- **Cross-check vs the architecture's own measurements:** my gz64 worst case (BD-136 40,771 / 62.2%),
  raw-b64 worst (65,335 / 99.7%), the `-->` set (4), the fence set (1), and the no-Description cohort
  (carried by R-BODY-1 headroom) all match ARCHITECTURE-BD-204-LOSSLESS-FIX.md §3.3c / §4.2 exactly —
  two independent measurement runs agree.
- **BOTTOM LINE:** under the current verbatim-blob design, NO backlog entry violates ANY hard GitHub
  Issues content rule. The reactive-discovery risk that motivated this research (BD-136 at 99.7% under
  the retired raw-base64 mechanism) is the ONE near-miss, and the gz64 decision already retires it.


---

## §3 — DESIGN / CODE COMPLIANCE MAP (per rule: design-doc §, landed C-1..C-6 code, parked C-7 oracle)

Verdict legend: **COMPLIES** (addressed + correct), **VIOLATES** (addressed but wrong, or unhandled
where it must be), **SILENT** (not addressed). "Landed code" = the committed C-1..C-6 migrators at
HEAD `feaa45d`; the gz64 carrier + faithfulness check are PARKED (C-4.5/C-4.6, not yet in code) —
noted per rule.

> **Empirical-Evidence Block (gz64 carrier + faithfulness check are NOT yet in landed code).**
> `CMD`: `grep -niE 'pack-entry-body-gz64|gz64|raw_body|gzip' scripts/lib/tracker-migrate-forward.sh
> scripts/lib/tracker-migrate-reverse.sh` ; `grep -niE 'check_migrator_field_faithfulness'
> scripts/validate-pack.py`
> `OUT`: both **empty**. `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: the verbatim-blob carrier (§3.3)
> and its CI guard (§4) are DESIGN-ONLY in ARCHITECTURE-BD-204-LOSSLESS-FIX.md; the landed C-1..C-6
> code still carries the 9-field whitelist + the dead `pack-extra-fields` path. The compliance map
> therefore distinguishes DESIGN compliance from LANDED-CODE compliance. `CONCL`: SUPPORTED.

| Rule | Design doc (ARCHITECTURE-BD-204-LOSSLESS-FIX.md) | Landed C-1..C-6 code | Parked C-7 oracle | Verdict |
|---|---|---|---|---|
| **R-BODY-1** body ≤ 65,536 | §3.3c: MEASURES all 211 vs 65,536, picks gz64 (worst 62.2%), ADDS fail-loud overflow contract + `provider_body_limit` capability | Body size NOT enforced (`grep 65536\|body_limit` → empty in forward/reverse/provider libs) | C-7 does not test size (`grep 65536\|size` → empty) | **DESIGN COMPLIES; LANDED CODE SILENT; ORACLE SILENT** |
| **R-BODY-2** comment vs description unit | §3.3c uses a BYTE budget (conservative ≤ codepoint limit) | n/a (carries body, not comments) | n/a | **DESIGN COMPLIES** (byte budget is the safe interpretation) |
| **R-BODY-3** write-path limit (POST/PATCH) | §3.3c overflow check runs in the forward COMPOSER before `provider_create` | not enforced | not tested | **DESIGN COMPLIES; LANDED CODE SILENT** |
| **R-BODY-4** storage-vs-render / byte-verbatim | §3.3: gz64 blob in safe base64 alphabet inside an HTML comment — collision-proof + (claimed) normalization-proof | landed body uses HTML-comment markers (`work-item.yml:103-105` trio) — same idiom, no rewrite observed | C-7 IS the live round-trip that would empirically confirm stored-body fidelity — but its fixture cannot carry the drop set (per RESEARCH-BD-204-LOSSLESS-FIELD-CENSUS §4.3) | **DESIGN COMPLIES (empirically-grounded); needs C-7 to CONFIRM (DOCUMENTED-SILENT platform behavior)** |
| **R-BODY-5** web-edit normalization | §3.3a (ii) / N-2: normalization-tolerant comparator (CRLF→LF + trailing-ws strip + single trailing newline) | landed `tracker-mirror.sh` has trailing-newline normalization (the cited precedent); the N-2 comparator itself is PARKED (C-3 amendment) | C-7 round-trips through real GH (would surface normalization) | **DESIGN COMPLIES; comparator LANDED CODE SILENT (parked C-3 amend)** |
| **R-BODY-6** no NUL/CR/control | not explicitly addressed (entries are clean — §2 proves ∅) | no validation | not tested | **SILENT (MOOT — §2 census ∅; no future-entry guard exists)** |
| **R-BODY-7** 65,536 enforced on gzipped request (MISS-1) | §3.3c budget targets STORED bytes; does NOT state which enforcement axis it assumes | size not enforced (same as R-BODY-1) | not tested | **DESIGN SAFE-but-UNSTATED — the conservative stored-byte budget bounds all three axes (stored codepoints / stored bytes / gzipped request); the design should NAME the axis its `provider_body_limit` targets (factual; no fix proposed)** |
| **R-TITLE-1** title ≤ 256 | §3.3: title from bold-header; the blob's header line is authoritative; the GH title is "advisory" | landed forward sets title from `ENTRY_HEADER` group-2; no length check | not tested for length | **SILENT on the 256 bound (MOOT — §2 max 231; no guard for a future 248+ title)** |
| **R-TITLE-2** single-line | implied (header is single-line by `_rules.md`) | enforced by the `ENTRY_HEADER` regex (single line) | n/a | **COMPLIES (structural)** |
| **R-LABEL-1** label ≤ 50 | not addressed (label vocabulary is fixed) | `_tmf_labels_for_entry` emits a FIXED label set (max 24 chars) | tests label round-trip, not length | **COMPLIES (fixed vocabulary; max 24 ≤ 50)** |
| **R-LABEL-2** ≤ 100 labels | not addressed | max 6 labels/issue (3 static + 3 computed) | n/a | **COMPLIES (6 ≤ 100)** |
| **R-LABEL-3** desc ≤ 100 | n/a (no custom label descriptions set) | n/a | n/a | **N/A** |
| **R-LABEL-4** case/charset (`:` allowed) | uses `status:*` / `template:*` colon labels | landed labels use colons (`status:open`, `template:bd-v11.0`) — valid | round-trips labels | **COMPLIES** |
| **R-STATE-1** state {open,closed} | status→label model + open/closed projection | `_tmr_decode_status` + close-path (BD-134 close loop) map to open/closed | C-7 stresses a Deferred entry (HARD gate) | **COMPLIES** |
| **R-STATE-2** state_reason {completed,not_planned,duplicate,reopened} | DECISION TIERS reference a "complete status mapping" (BD-204.md:18) incl. the missing Deferred row | C-5 added `Deferred → status:deferred` (forward) + the C-1 reverse decode; `Deprecated → not_planned` close-path test is a C-5 carry-forward (BD-204.md:23) | C-7 carries a Deferred stress entry that HARD-GATES the flip | **DESIGN COMPLIES (carries the full vocabulary in labels + blob); LANDED state_reason mapping for Cancelled/Deprecated is a documented C-5 carry-forward (verify at impl) — PARTIAL** |
| **R-ID-1** issue-number immutable, key on pack-id | BD-204.md:11 keys on `pack-id`, never issue number | landed migrators search/match on the `pack-id` marker (`provider_list` + marker search) | C-7 round-trips identity by pack-id | **COMPLIES** |
| **R-ID-2** timestamps not settable | authoring dates ride INSIDE the body (blob preserves them) | landed code does not attempt to set created_at/updated_at | n/a | **COMPLIES** |
| **R-OPS-1** primary rate (5,000/hr) | not addressed (211 ≪ 5,000) | provider classifies `rate-limit-primary` errors (`tracker-provider-gh.sh:72-73`) | C-7 runs against a live scratch repo (real rate limits) | **COMPLIES (under cap; error detected)** |
| **R-OPS-2** secondary rate (80/min, 500/hr) | **NOT addressed** — no design section bounds the C-8 bulk-create rate against the 500/hour secondary cap | provider DETECTS `rate-limit-secondary` (`tracker-provider-gh.sh:69-70`) + DECLARES `writes_per_minute_recommended: 60` (`:769-771`); forward create loop has NO between-create pacing sleep (the only `sleep` is the post-create STABILIZE poll + the BD-134 close-RETRY sweep, not write pacing) | C-7 would hit it live with 200+ creates, but does not assert a mitigation | **SILENT in the design; LANDED CODE: DETECTS but does NOT PACE — 211 creates in one burst exceeds 500/hour and risks 403/429** |
| **R-OPS-3** ≥1s/mutative, serial | not addressed in the design doc | provider declares `writes_per_minute_recommended: 60` (= 1/s) but the migrator does not ENFORCE a 1s gap between `provider_create` calls; the post-create stabilize sleep (2s) is incidental, not a pacing mechanism | not tested | **SILENT (the recommended-rate capability exists but is unenforced by the migration loop)** |
| **R-OPS-4** pagination (per_page ≤ 100) | not addressed | provider read path uses `gh` list (handles paging via `gh`); 211 issues need ≥3 pages | C-7 lists a live repo | **COMPLIES (delegated to `gh`)** |
| **R-OPS-5** search (1,000 ceiling, 256-char query, 30/min) | not addressed | provider declares `search.result_ceiling_per_query: 1000` (`tracker-provider-gh.sh:766-768`); reverse uses marker search/list | C-7 round-trips via live search/list | **COMPLIES today (211 < 1,000); the ceiling is DECLARED in the capability block** |
| **R-OPS-6** autolink/@mention side-effects (MISS-2) | NOT addressed — design treats autolinking as render-only (R-BODY-4) and does not weigh bulk-create side-effects | no suppression / no flag (and there is no documented suppression mechanism) | C-7 (scratch repo) ABSORBS the noise; not asserted | **SILENT — 21 `#NNN` + 2 bare-`@` entries will scatter cross-links / fire mentions on the C-8 REAL-repo create; NOT a lossless break (blob decodes verbatim) but a dogfood-cleanliness gap to acknowledge** |
| **R-OPS-7** repo-CREATION rate limit (GAP 1) | §3.3d declares `provider_min_write_interval_s`=1 + `provider_writes_per_hour_max`=500 and PACES the create loop | provider classifies `rate-limit-secondary`/`-primary` (`tracker-provider-gh.sh:69-73`); no repo-create-specific pacing (none needed — 1 repo/rehearsal) | C-7 repeatable multi-scratch exercises repo create live | **DESIGN's §3.3d pacing MUST honor: the repo create itself needs no separate gate (1 mutation/rehearsal ≪ 500/hr), but the per-rehearsal 211 ISSUE creates MUST be paced under the SAME general secondary caps + abuse detection — the issue-pacing gate is what bounds a repeatable cadence (factual mapping; no design)** |
| **R-COMMENT-1** comments dropped | carrier-no-sidecar memory: comments/reactions DROPPED for v11.0 | landed code carries only the body | n/a | **COMPLIES (intentional drop; no entry uses comments)** |
| **R-ACCT-1** issue forms GA personal | uses the existing form family | `.github/ISSUE_TEMPLATE/*.yml` in use | C-7 uses the forms | **COMPLIES** |
| **R-ACCT-2** labels/state GA personal | status mapping uses only labels + open/closed | landed | n/a | **COMPLIES** |
| **R-ACCT-3** Issue Fields/Types excluded | BD-204.md:14 explicitly excludes org-only/preview features | landed code uses no Issue Fields/Types | n/a | **COMPLIES** |
| **R-ACCT-4** archived-repo read-only (MISS-3) | NOT addressed — but BD-204.md:20 scope says "scratch-repo proof -> archive -> real flip" | every C-8 / reverse write is IMPOSSIBLE on an archived repo (platform read-only) | C-7/C-8 would fail outright if pointed at an archived repo | **SILENT + CONFLICT-TO-DISAMBIGUATE — the BD's own "archive -> real flip" wording is ambiguous; operating on an archived repo is impossible. FLAGGED for architect/user (researcher does not resolve the sequence)** |
| **R-ACCT-5** account repo QUOTA + on-disk size (GAP 2) | §5.c disposal ARCHIVES scratch repos (no-delete credential), so they accumulate; §11.3 named the quota as an unmeasured gap | n/a (platform quota, not code) — disposal is archive-only per §5.c | C-7 repeatable multi-scratch accumulates archived repos | **DESIGN's §5.c archive-not-delete disposal is SAFE on both quota axes: repo count is unlimited below a 100,000 cap (archived repos count, but a campaign stays orders of magnitude under it), and 211 issues consume ~0 of the 10 GB on-disk `.git` budget (issues are in the DB, not git). No quota wall; the §11.3 mitigations (public scratch / prompted manual delete) are optional housekeeping (factual mapping; no design)** |

### §3 compliance summary

- **Fully COMPLIES (design + landed where applicable):** R-BODY-2, R-TITLE-2, R-LABEL-1/2/4,
  R-STATE-1, R-ID-1/2, R-OPS-1/4/5, R-COMMENT-1, R-ACCT-1/2/3 (14 rules).
- **DESIGN COMPLIES but LANDED CODE SILENT (parked C-4.5/C-4.6/C-3 work):** R-BODY-1, R-BODY-3,
  R-BODY-4 (needs C-7 confirm), R-BODY-5 (3 rules + the gz64 carrier itself).
- **PARTIAL:** R-STATE-2 (full vocabulary carried; the Cancelled/Deprecated → state_reason close-path
  is a C-5 carry-forward to verify at implementation).
- **DESIGN HONORS (census gaps closed by the design's existing hooks — not new SILENT items):**
  R-OPS-7 (repo-CREATION) is bounded by the §3.3d issue-pacing gate (the repo create itself needs no
  separate gate — 1 mutation/rehearsal); R-ACCT-5 (account repo QUOTA + on-disk) is satisfied by the
  §5.c archive-not-delete disposal being SAFE on both axes (unlimited repos below the 100,000 cap;
  issues consume ~0 of the 10 GB on-disk `.git` budget). Both are RESOLVED-by-measurement, not gaps.
- **SILENT / unaddressed (the genuine gaps this census surfaces):**
  1. **R-OPS-2 / R-OPS-3 (secondary rate limit) — the most material gap.** Neither the design doc nor
     the landed migration loop PACES the C-8 bulk create. The provider DETECTS rate-limit errors and
     DECLARES a 60-writes/min recommendation, but nothing enforces the documented "wait ≥1s between
     mutative requests" mitigation or spreads 211 creates under the 500/hour secondary cap. A
     single-shot C-8 run risks 403/429 — and (NUANCE-A, FOLDED IN) can trip GitHub's ABUSE DETECTION,
     flagging the PERSONAL account as spammy/invisible (a worse failure than a transient 429).
  2. **R-OPS-6 (autolink/@mention side-effects on the C-8 real-repo create) — FOLDED IN (MISS-2).** 21
     `#NNN`-bearing + 2 bare-`@` entries (§2 R-OPS-6 census) will scatter spurious cross-link backlinks
     (the `#NNN` are NOT GH issue numbers) and may fire mention notifications when the verbatim bodies
     are created on the real repo. NOT a losslessness break (the blob decodes verbatim) — a dogfood-
     cleanliness gap the design does not acknowledge; there is no documented suppression mechanism.
  3. **R-ACCT-4 (archived-repo read-only) — FOLDED IN (MISS-3).** BD-204.md:20's "scratch-repo proof
     -> archive -> real flip" wording is AMBIGUOUS: operating on an archived repo (create/label/write)
     is IMPOSSIBLE. Flagged for architect/user disambiguation (researcher does not resolve the
     sequence).
  4. **R-BODY-7 (enforcement axis) — FOLDED IN (MISS-1).** The 65,536 limit may be enforced on the
     gzipped request, not the stored count; the conservative stored-byte budget stays SAFE, but the
     design should NAME the axis its `provider_body_limit` targets.
  5. **R-BODY-6 / R-TITLE-1 future-entry guards — MOOT today (§2 ∅) but unguarded.** No check stops a
     FUTURE entry from introducing a NUL/control byte (R-BODY-6) or a title that, ID-prefixed, exceeds
     256 (R-TITLE-1, current headroom 25 chars on BD-208). The §3.3c size guard covers body bytes but
     not title length or control chars.


---

## §4 — DOCUMENTED-SILENT items (official docs do not state the behavior; empirical basis recorded; nothing invented)

| # | Behavior | Why DOCUMENTED-SILENT | Empirical basis that EXISTS | Empirical basis still NEEDED |
|---|---|---|---|---|
| DS-1 | Issue-body STORAGE is byte-verbatim (HTML comments preserved; no autolink/mention rewrite of STORED content) — R-BODY-4 | Official docs describe Markdown RENDER-time autolinking, not stored-content rewriting | GitHub's own form templates store `<!-- ... -->` markers (pack `work-item.yml:103-105`); they re-emit on edit | A live round-trip on the target repo (the C-7 oracle) decoding the stored `pack-entry-body-gz64` blob byte-identically — confirms no stored rewrite |
| DS-2 | Issue-BODY field web-edit normalization (CRLF→LF, trailing-whitespace strip) — R-BODY-5 | Docs cover git-file + Monaco CODE-editor normalization, NOT the issue-body textarea | The design's own whitespace-tolerant precedent (`tracker-mirror.sh` trailing-newline norm); widespread practitioner reports | A live web-edit-then-read round-trip on the target repo measuring exactly which transforms GH applies to a stored issue body |
| DS-3 | Issue body 65,536 ENFORCEMENT AXIS — stored codepoints (R-BODY-1) vs stored bytes (R-BODY-2) vs GZIPPED-REQUEST size (R-BODY-7 / MISS-1) | The error string says "65536 characters"; github-limits lists "65536 codepoints" (description) / "262144 bytes" (comments); practitioner sources (community#41331 + action repos) report the limit tracks the GZIPPED REQUEST size — official docs name NO authoritative axis | The design uses a conservative BYTE budget (safe ≤ ALL THREE axes — a stored-byte bound also bounds stored-codepoints and, since the request gzips, the gzipped-request size) | An empirical write probing each axis on the target repo to confirm the binding one (only matters for multibyte/large bodies; pack bodies are ASCII+base64 at worst 62.2%, so all three axes clear with margin) |
| DS-4 | Accepted control-character set in issue bodies — R-BODY-6 | Docs do not enumerate forbidden control chars | The pack tree carries NONE (§2 ∅), so MOOT for current data | If a future entry introduces a NUL/control byte, an empirical write to confirm accept/reject/strip behavior |
| DS-5 | Title newline handling — R-TITLE-2 | Docs do not state "no newline in title" explicitly | The title field is single-line by platform UI; the pack's title source is a single header line | MOOT (no pack title can carry a newline); no empirical work needed unless the title source changes |
| DS-6 | `gh` CLI version that introduced `gh repo archive` / `gh repo view --json isArchived` / `--jq` (the migration's dependencies) — architect's absorbed-with-flag item | The `gh` releases page lists per-version notes but NO single official line pins the version that added `gh repo archive`; WebSearch this session found the command docs but not its introducing version | The commands are GA in modern `gh` (≥ 2.x); the JSON/`--jq` surface is stable | A `gh --version` floor BELONGS to the §5.f credential/tooling preflight (architect §11.3); per the mandate ("note ONLY if officially documented; otherwise skip"), NO version is asserted here — the preflight asserts the runtime `gh` supports the needed commands. Recorded as the absorbed flag, not a fabricated pin. |

**No DOCUMENTED-SILENT behavior is asserted as a documented fact anywhere in this report.** Each is
flagged for the C-7 live oracle (the only surface that can empirically confirm platform behavior on
the actual target repo).

---

## §5 — Sources (official + authoritative-compiled)

GitHub official documentation (docs.github.com):
- Autolinked references and URLs (R-OPS-6 / MISS-2) — <https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/autolinked-references-and-urls>
- Archiving repositories — read-only (R-ACCT-4 / MISS-3) — <https://docs.github.com/en/repositories/archiving-a-github-repository/archiving-repositories>
- Secondary rate limits — concurrency/points/CPU + content-creation (R-OPS-7 / GAP 1) — <https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api>
- Types of GitHub accounts — unlimited personal repos (R-ACCT-5 / GAP 2) — <https://docs.github.com/en/get-started/learning-about-github/types-of-github-accounts>
- Repository limits — 100,000 cap + 10 GB on-disk `.git` (R-ACCT-5 / GAP 2) — <https://docs.github.com/en/repositories/creating-and-managing-repositories/repository-limits>
- Rate limits for the REST API — <https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api>
- Best practices for using the REST API — <https://docs.github.com/en/rest/guides/best-practices-for-using-the-rest-api>
- REST API endpoints for issues (state / state_reason / create / update) — <https://docs.github.com/en/rest/issues/issues?apiVersion=2022-11-28>
- REST API endpoints for search (1,000 ceiling / 256-char query / 30/min) — <https://docs.github.com/en/rest/search/search?apiVersion=2022-11-28>
- Using pagination in the REST API — <https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api>
- Managing labels (max 100/issue) — <https://docs.github.com/en/issues/using-labels-and-milestones-to-track-work/managing-labels>
- Configuring Git to handle line endings — <https://docs.github.com/en/get-started/git-basics/configuring-git-to-handle-line-endings>

GitHub official changelog/blog + docs-repo issues:
- Label improvements: emoji, descriptions — <https://github.blog/2018-02-22-label-improvements-emoji-descriptions-and-more/>
- Document the character limit of label names (50) — <https://github.com/github/docs/issues/32156>
- Label description > 100 chars error — <https://github.com/orgs/community/discussions/189718>
- Max labels per issue/PR (100) — <https://github.com/orgs/community/discussions/76832>
- Body too long (65536) — <https://github.com/orgs/community/discussions/41331>, <https://github.com/reviewdog/reviewdog/issues/1065>
- Github auto line-ending change (web editor) — <https://github.com/orgs/community/discussions/142407>
- 65,536 enforced on gzipped request (R-BODY-7 / MISS-1) — <https://github.com/orgs/community/discussions/41331>, <https://github.com/changesets/action/issues/174>, <https://github.com/renovatebot/renovate/issues/14551>
- `state_reason: duplicate` Dec-2024 breaking addition (R-STATE-2 / NUANCE-B) — <https://github.blog/changelog/2024-12-12-github-issues-projects-close-issue-as-a-duplicate-rest-api-for-sub-issues-and-more/>, <https://github.com/orgs/community/discussions/150535>
- Secondary-rate abuse/spam-flagging + account-invisibility (R-OPS-2 / NUANCE-A) — <https://github.com/orgs/community/discussions/110990>

Authoritative-compiled limits reference (CC-BY, with per-entry verification methods quoted):
- github-limits (issue title 256 / description 65536 codepoints / comment 262144 bytes / issue number range) — <https://github.com/dead-claudia/github-limits/blob/master/README.md>

---

## §6 — Rules-Applied Verification Block

| Rule | Verification evidence (actual command / quote / measurement) | Conclusion |
|---|---|---|
| `agents-never-commit` | No `git add/commit/push/tag` or any state-changing verb issued; `git rev-parse HEAD` (read-only) is the only git call; the sole write is this ONE report; `curl` fetched docs into `/tmp` (outside the repo). | COMPLIANT |
| `external-rules-census-before-design` | §1 enumerates **30 rule rows** / 8 categories from official docs + the authoritative-compiled reference, each with URL + exact quoted text + verified value; §2 censuses all 211 entries against every content rule; §3 maps each rule to design/code (COMPLIES/VIOLATES/SILENT). First fold-in (adversarial verification) added R-BODY-7 / R-OPS-6 / R-ACCT-4 + NUANCE-A/B (28); SECOND fold-in (architect §11.3 completeness) added R-OPS-7 (repo-creation rate limit) + R-ACCT-5 (account repo quota + on-disk) (30) — every source for both passes RE-CHECKED by me this session (WebSearch + curl of the archiving / repository-limits / types-of-accounts / rate-limits docs), not accepted on faith. No reactive single-pass discovery. | COMPLIANT |
| `verify-availability-not-just-existence` | Every rule checked on GA + personal-account axes (§1 "Availability" line per rule); R-ACCT-3 confirms Issue Fields/Types are org-only/preview → EXCLUDED; target environment (personal `DShaneNYC/...`) stated up front. | COMPLIANT |
| `researcher-maps-blast-radius` | §2 censuses ALL 211 entries (no sampling) against EVERY content rule; counts reconciled multiple ways (entry count 211; gz64 worst 62.2% = raw-b64 99.7% = arch §3.3c; `-->` set = 4; fence = 1). Fold-in: independently RE-RAN the R-OPS-6 autolink/mention census (my own regex over all 211) — `#NNN` = 21 (matches the verifier exactly); `@`-token = 4 any / 2 bare-outside-code (RECONCILED the verifier's 4 by isolating inline-code spans, with evidence) — no number accepted unmeasured. | COMPLIANT |
| `empirical-evidence-blocks` | Every repo-state claim carries CMD + verbatim OUT + HEAD `feaa45d` + 2026-06-07 + INTERP + CONCL (§2 title/body/label/status/hazard blocks; §3 parked-code block). Every platform claim carries URL + exact quote (§1). | COMPLIANT |
| `scope-deliverables-to-the-ask` | Exactly the 3 deliverables: §1 rule set (cited), §2 violation census (explicit empty lists), §3 compliance map (factual, no fix proposals) + §4 documented-silent. No design, no fix recommendations. | COMPLIANT |
| `filename-uniqueness-heuristic` | `find . -name "RESEARCH-BD-204-GH-ISSUES-RULES.md" -not -path "./.git/*"` returned EMPTY before write (Bash, this session). | COMPLIANT |
| `rules-applied-verification-block` | This table — per-rule, evidence quoted, terminal conclusion; no empty evidence; no AMBIGUOUS terminal state. | COMPLIANT |

---

## §7 — READ-IN-FULL attestation (per-file direct-read, this session, at HEAD `feaa45d`)

| Document | Direct-read proof |
|---|---|
| `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` | Read full (1-497 page 1, 498-970 page 2). The verbatim-blob carrier (§3.3), size budget (§3.3c), normalization comparator (§3.3a), and CI guard (§4) are the projection the §2 census measures and the §3 map cross-references. |
| `RESEARCH-BD-204-LOSSLESS-FIELD-CENSUS.md` | Read full (1-436). The 9-carry/19-drop field census + the green-CI root cause; cross-checked against my independent §2 measurements. |
| `backlog/_rules.md` | Read full (1-84). Entry contract + ID-extraction grammar (title = bold-header after em-dash); confirms the title-source single-line property (R-TITLE-2). |
| `backlog/BD-204.md` | Read full (1-27). The re-scoped entry; DECISION TIERS (GA + personal-account only; NO Issue Fields/Types — R-ACCT-3); identity-on-pack-id (R-ID-1); status-mapping completeness (R-STATE-2). |
| `.github/ISSUE_TEMPLATE/work-item.yml` | Read full (1-106). The form field set + the marker trio (`:103-105`) — the static label set + the HTML-comment-marker idiom (R-BODY-4 / R-LABEL census). |
| `.github/ISSUE_TEMPLATE/inbound.yml` | Read full (1-77). The second intake lane (R-COMMENT/feedback completeness). |
| `.github/ISSUE_TEMPLATE/config.yml` | Read full (1-10). `blank_issues_enabled: false`; the discussions URL confirming the personal account `DShaneNYC/...`. |
| `scripts/lib/tracker-migrate-forward.sh` | Read directly — `ENTRY_HEADER`/`FIELD_LINE` (`:387-388`), `_tmf_labels_for_entry` (`:1500-1534`), stabilize/sleep + create loop (`:105-130`, `:911`, `:965`), no body-size/rate-pacing (grep empty). |
| `scripts/lib/tracker-migrate-reverse.sh` | Read directly via grep — no gz64/raw_body (empty), reconstruct + emit references per the prior census. |
| `scripts/lib/tracker-provider-gh.sh` | Read directly — `_gh_classify_error` rate-limit detection (`:60-80`), capability block `rate_limits`/`search.result_ceiling_per_query: 1000` (`:760-774`). |
| `scripts/validate-pack.py` | Read via grep — no `check_migrator_field_faithfulness` (empty → faithfulness check parked). |
| `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` | Read via grep — no size/rate assertions (empty); confirms C-7 SILENT on size + ops rules. |
| Memory files (read in full this session) | `feedback_external_rules_census_before_design`, `feedback_verify_availability_not_just_existence`, `feedback_researcher_maps_blast_radius_before_architect`, `feedback_architect_planner_empirical_evidence`, `feedback_scope_deliverables_to_the_ask`, `feedback_agent_output_rules_applied_block` — all read directly; carried as governing rules (reflected in §6). |
| `CLAUDE.md ## Pack memory` | Provided in full in session context; the in-force rules (boundary, dependency-direction, ci-guard-measure-then-bound, scope-deliverables, empirical-evidence) applied. |
| Official GitHub docs + github-limits | Fetched via `curl`/WebSearch this session; exact quotes captured in §1/§5 (rate-limits, best-practices, issues REST, search REST, github-limits README, label doc-issue #32156). NOT relied on from training data. |
| `RESEARCH-BD-204-GH-ISSUES-RULES-VERIFY.md` (fold-in input) | Read full (1-348) this session. Verdict CORRECTIONS-NEEDED (3 missed rules + 2 nuances); folded into §0/§1/§2/§3/§4/§5/§6 + the §8 ledger. Every folded value INDEPENDENTLY RE-CHECKED, not accepted on faith. |
| Folded-in sources (re-checked this session) | Archiving doc re-fetched via `curl` (exact read-only quote, R-ACCT-4); WebSearch re-confirmed the gzipped-request behavior (community#41331 + changesets#174 + renovate#14551, R-BODY-7), the `state_reason: duplicate` Dec-2024 changelog + community#150535 (NUANCE-B), the abuse-flagging community#110990 (NUANCE-A), and the autolinked-references doc (R-OPS-6). The `#NNN`/`@` census was re-run by me over all 211. |
| `SWEEP-BD-204-RULES-COMPLIANCE.md` §S-9 + `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` §11.3 (second fold-in input) | Read this session — the completeness verdict + the 2 named census gaps (repo-creation rate limit; account repo quota) + the design hooks §3.3d (pacing) / §5.c (archive-not-delete disposal) / §5.f (credential preflight) the §3 map factually references. |
| Second-fold-in sources (re-checked this session) | `curl`-fetched the Repository-limits doc (exact 100,000 + 10 GB on-disk `.git` quotes, R-ACCT-5) + re-read the rate-limits secondary section (concurrency/points/CPU + content-creation, R-OPS-7); WebSearch re-confirmed types-of-accounts "unlimited public and private repositories" (R-ACCT-5). The gh-archive introducing-version (DS-6) was checked and found NOT officially pinned — recorded DOCUMENTED-SILENT, not fabricated. |

**No named document was derived rather than read.** All repo measurements are this session's own
command output at HEAD `feaa45d` (2026-06-07); all platform claims carry an official-source URL + exact
quoted text.

---

## §8 — Fold-in ledger (adversarial-verification corrections; what was added where)

| Finding | Type | Where folded | Independent re-check (this session) |
|---|---|---|---|
| MISS-1 — 65,536 enforced on GZIPPED REQUEST payload | new rule **R-BODY-7** | §1 Cat A (new row); §3 (new table row + SILENT-summary item 4); §4 DS-3 reframed to 3 axes; §0; §5 sources | WebSearch re-confirmed community#41331 + changesets/action#174 + renovate#14551 (231k-char comment posted as ~55K gzipped call) |
| MISS-2 — autolink / @mention SIDE-EFFECTS on bulk create | new rule **R-OPS-6** | §1 Cat F (new row); §2 (new census block: 21 `#NNN` + 2 bare-`@` / 4 any-`@`); §2 reconciliation line; §3 (new table row + SILENT-summary item 2); §0; §5 sources | Re-ran my own `#NNN`/`@` regex census over all 211 (matched the verifier's 21 `#NNN` exactly; RECONCILED `@` 4→2 by excluding inline-code spans, with evidence); re-read the autolinked-references doc |
| MISS-3 — archived repository READ-ONLY | new rule **R-ACCT-4** | §1 Cat H (new row, with BD-204.md:20 disambiguation FLAG — not resolved); §3 (new table row + SILENT-summary item 3); §0; §5 sources | `curl`-fetched the official Archiving-repositories doc; captured the exact "...become read-only..." quote |
| NUANCE-A — secondary-rate abuse/spam-flagging + account-invisibility | enrich **R-OPS-2** | §1 R-OPS-2 (NUANCE-A bullet); §3 SILENT-summary item 1; §0; §5 sources | WebSearch re-confirmed community#110990 ("Account marked as spammy and went invisible") |
| NUANCE-B — `state_reason: duplicate` Dec-2024 breaking addition | flag **R-STATE-2** | §1 R-STATE-2 (NUANCE-B bullet); §5 sources | WebSearch re-confirmed changelog 2024-12-12 + community#150535 ("breaking existing clients") |

**Rule count: 25 -> 28 rule rows** (+R-BODY-7, +R-OPS-6, +R-ACCT-4; NUANCE-A/B enrich existing rows,
not new rows). **Nothing in the original report was WRONG** — the verifier confirmed every value and
every census number; this revision is purely ADDITIVE completeness per the fold-in mandate. The verify
report (`RESEARCH-BD-204-GH-ISSUES-RULES-VERIFY.md`) remains the audit trail.

---

## §9 — Second fold-in ledger (architect-completeness census-gap pass; what was added where)

Source: `SWEEP-BD-204-RULES-COMPLIANCE.md` §S-9 / `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` §11.3. Two gaps
made newly relevant by two late user decisions (REPEATABLE multi-scratch rehearsals; no-delete PAT →
archived scratch repos accumulate). Both answered from OFFICIAL sources, re-checked by me this session.

| Gap | Answer (brief) | Type | Where folded | Independent re-check (this session) |
|---|---|---|---|---|
| GAP 1 — repo-CREATION limits | NO documented repo-specific rate limit. Repo create is a content-generating mutation under the GENERAL secondary caps (80/min, 500/hr, 100 concurrent, 900 points/min, 90s CPU/60s) + abuse detection. DOCUMENTED-SILENT on a repo-only threshold. Implication: 1 repo/rehearsal is trivially safe; the BINDING constraint is the per-rehearsal 211 ISSUE creates (R-OPS-2/3 pacing), so the issue-pacing gate bounds a multi-rehearsal cadence. | new rule **R-OPS-7** | §0; §1 Cat F (new row); §1 reconciliation; §3 (new table row mapping to §3.3d) + §3 summary "DESIGN HONORS"; §5 sources; §6 census row | Re-fetched the rate-limits secondary section (exact concurrency/points/CPU + 80/500 quotes) |
| GAP 2 — account repo QUOTA | Personal accounts own UNLIMITED public+private repos; hard cap 100,000/account (banner at 50,000); archived repos COUNT toward it; the 10 GB on-disk RECOMMENDATION is the `.git` folder, which ISSUES do NOT consume (issues are in the DB). So accumulating archived ~211-issue scratch repos approaches NEITHER the count cap NOR the on-disk budget — benign. | new rule **R-ACCT-5** | §0; §1 Cat H (new row); §1 reconciliation; §3 (new table row mapping to §5.c disposal) + §3 summary "DESIGN HONORS"; §5 sources; §6 census row | `curl`-fetched Repository-limits (100,000 + 10 GB `.git`) + types-of-accounts ("unlimited public and private repositories") |
| Absorbed flag — `gh` version pin | NO official line pins the version that introduced `gh repo archive`; per the mandate, NOT asserted. The `gh --version` floor belongs to the §5.f credential/tooling preflight. | DOCUMENTED-SILENT **DS-6** | §4 (new DS row) | WebSearch found the command docs but no introducing-version; recorded silent, not fabricated |

**Rule count: 28 -> 30 rule rows** (+R-OPS-7 GAP-1, +R-ACCT-5 GAP-2; DS-6 is a documented-silent item,
not a rule). Both gaps are RESOLVED-BY-MEASUREMENT and the design's existing hooks (§3.3d issue-pacing,
§5.c archive-not-delete disposal) already HONOR them — neither is a new SILENT gap; the factual §3
mapping states what each hook must honor. **No design proposed.**

**End of RESEARCH-BD-204-GH-ISSUES-RULES.md**
