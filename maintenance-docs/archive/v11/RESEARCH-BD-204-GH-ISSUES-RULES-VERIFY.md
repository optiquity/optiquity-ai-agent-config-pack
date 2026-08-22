# RESEARCH-BD-204 — VERIFICATION of the GH-Issues rule set report (adversarial)

> **Role:** pack-docs-researcher (ADVERSARIAL VERIFIER). **Mode:** read-only repo + ONLINE research;
> one report write. No design.
> **Under verification:** `maintenance-docs/v11-implementation/RESEARCH-BD-204-GH-ISSUES-RULES.md`.
> **HEAD (verified):** `feaa45dcb7a39dd3cc12fb4ff9c234d9845cfb53` (`git rev-parse HEAD`). **Date:** 2026-06-07.
> **Method:** assume the report is WRONG until verified. Three independent checks: (§1) per-rule
> correctness vs independently-fetched sources; (§2) missed-rule hunt from scratch; (§3) repo-input
> coverage + independent re-measurement of the §2 census, reconciled to the report's numbers; (§4) verdict.
> Every PLATFORM claim: URL + quoted text. Every REPO claim: CMD + verbatim OUT + HEAD `feaa45d` + INTERP + CONCL.
> All repo measurements are my own, run this session (not copied from the report).

---

## §0 — Bottom line

The report under verification is **substantially correct and well-evidenced**: all 25 rule rows I
could independently source are VERIFIED (values + personal-account GA availability), and every §2
census number reproduces EXACTLY under my independent re-measurement (211 entries; title max 223 /
stored 231; gz64 worst BD-136 40,771 = 62.2%; raw-b64 worst 65,335 = 99.7%; 0 control bytes; 6
labels/issue; longest label 24; status histogram; `-->` set = {BD-065,069,103,136}; fence = {BD-136}).
Its §3 code citations are real (symbols present; line numbers drift ≤3, the report mostly uses
symbols + spans so this is immaterial).

**Verdict: CORRECTIONS-NEEDED** — not for any WRONG value, but for **three missed platform rules**
(§2) that are directly material to BD-204's hard-lossless, 211-issue, dogfood-with-archive design,
plus **two correctness nuances** to flag:

1. **MISS-1 (the most material):** Multiple authoritative practitioner sources assert the 65,536
   limit is enforced on the **gzipped API-request payload size**, NOT the raw character/byte count
   (a 231k-char comment posted as a 55K gzipped call succeeded). The report (and the architecture)
   frame the limit as 65,536 of stored body bytes/codepoints. The report's conservative byte budget
   stays SAFE under either reading, but the report does not surface this alternate enforcement model —
   a `census-before-design` gap exactly of the class this research exists to prevent.
2. **MISS-2:** **Autolink / cross-reference / @mention SIDE-EFFECTS on bulk creation.** The report's
   R-BODY-4 treats autolinking as render-only and stops there. It MISSED the *side-effect* dimension:
   migrating 211 verbatim bodies — **21 of which carry `#NNN` tokens and 4 carry `@`-tokens** (my
   census below) — will auto-generate cross-reference backlinks and may emit mention notifications,
   and GitHub documents NO way to suppress standard cross-linking. Material to a clean dogfood.
3. **MISS-3:** **Archived-repository read-only behavior.** BD-204's own scope (`BD-204.md:20`) plans
   a "scratch-repo proof → **archive** → real flip" dogfood sequence. Archived repos are fully
   read-only — **no issue create, no label edit, no reverse-sync write**. The report's rule set never
   censuses this, despite it appearing in the BD's own scope line; if the design intends to operate on
   an archived repo, that is impossible.

Two further nuances (NUANCE-A: secondary-rate ALSO carries an abuse/spam-flagging + account-invisibility
risk the report's R-OPS-2/3 omits; NUANCE-B: `state_reason: duplicate` was a *breaking* Dec-2024
addition — the report lists it as GA without the recency flag). Details in §2.

---

## §1 — PER-RULE CORRECTNESS (every §1 rule row independently sourced)

Legend: **VERIFIED** (source confirms value + availability) · **WRONG** (correct value supplied) ·
**UNVERIFIABLE** (cited source does not say that). Personal-account GA axis re-checked each row.

| Rule | Report value | My independent source + quote | Verdict |
|---|---|---|---|
| **R-BODY-1** body ≤ 65,536 codepoints; 422 not truncation | 65,536 codepoints; API ERROR | github-limits README: *"Issue description … Max length: 65536 codepoints"*; error string *"Body is too long (maximum is 65536 characters)"* corroborated across reviewdog#1065, changesets/action#174, release-please#1034, renovate#14551, community#41331 | **VERIFIED** (but see MISS-1: enforcement-unit nuance the report did not surface) |
| **R-BODY-2** comments = 262,144 BYTES (distinct unit) | 262,144 bytes | github-limits README: *"Issue comments … Max length: 262144 bytes (65536-262144 characters depending on UTF8-encoded size)"*; community#27190 corroborates | **VERIFIED** |
| **R-BODY-3** 65,536 on PR body, web+API write path | same limit POST/PATCH | github-limits §"PR body" + the same 422 across PR-creating actions (renovate#14551 PR-creation) | **VERIFIED** |
| **R-BODY-4** storage-vs-render / byte-verbatim = DOCUMENTED-SILENT | DOCUMENTED-SILENT | Confirmed docs describe RENDER-time autolinking only (docs autolinked-references); no doc asserts stored-byte rewrite | **VERIFIED as DOCUMENTED-SILENT** — but INCOMPLETE: misses the autolink/mention/cross-ref SIDE-EFFECT (MISS-2) |
| **R-BODY-5** web-edit body normalization = DOCUMENTED-SILENT | DOCUMENTED-SILENT | No official doc found for the issue-body textarea's CRLF/trailing-ws normalization; report's honest "empirical, not documented" stance is correct | **VERIFIED as DOCUMENTED-SILENT** |
| **R-BODY-6** control/NUL chars = PARTIALLY DOCUMENTED | undocumented set; data clean | No doc enumerates the accepted control set; report's "MOOT for current data" is correct | **VERIFIED** |
| **R-TITLE-1** title 1–256 chars; error not truncation | 256 max | github-limits README: *"Issue title … Max length: 256 characters"* (verified-by-error) | **VERIFIED** |
| **R-TITLE-2** single-line, no newline = structurally enforced | DOCUMENTED-SILENT / structural | No doc says "no newline in title"; report flags it DOCUMENTED-SILENT + MOOT — correct | **VERIFIED** |
| **R-LABEL-1** label name ≤ 50 chars | 50 | github/docs#32156 (doc-gap issue; validation *"name is too long (maximum is 50 characters)"*); corroborated by label-presets#63 | **VERIFIED** |
| **R-LABEL-2** ≤ 100 labels/issue | 100 | docs Managing-labels + community#76832: max 100 labels/issue-or-PR | **VERIFIED** |
| **R-LABEL-3** label description ≤ 100 chars | 100 | community#189718 ("> 101 characters throws an error") + label-presets#63 | **VERIFIED** (informational; design sets no descriptions) |
| **R-LABEL-4** case-insensitive-unique; `:`/emoji/UTF-8 allowed | colons + UTF-8 OK | docs Managing-labels + github.blog 2018-02-22 (emoji in label names); pack uses `status:open` colon labels | **VERIFIED** |
| **R-STATE-1** state ∈ {open, closed} | 2 states | docs REST Issues "Update an issue": *"Can be one of: open, closed"* | **VERIFIED** |
| **R-STATE-2** state_reason ∈ {completed, not_planned, duplicate, reopened, null}; ignored unless state changes | 4+null | docs REST Issues + changelog 2024-12-12 (`duplicate` added via REST); community#150535 confirms `duplicate` now valid | **VERIFIED** — NUANCE-B: `duplicate` was a Dec-2024 *breaking* addition (community#150535 "breaking existing clients"); report lists it GA without the recency flag |
| **R-ID-1** issue numbers 1..1,073,741,824; platform-assigned, immutable, non-reusable | range + immutability | github-limits §"Issue/pull request numbers": *"Max value: 1073741824 … Min value: 1"*; REST create has no `number` input | **VERIFIED** |
| **R-ID-2** created_at/updated_at not settable via standard create/update | server-set | docs REST Issues create/update param tables list no `created_at`/`updated_at` write param | **VERIFIED** |
| **R-OPS-1** primary 5,000/hr auth (PAT); 60/hr unauth | 5,000/hr | docs Rate-limits: *"personal rate limit of 5,000 requests per hour"*; *"unauthenticated … 60 requests per hour"* | **VERIFIED** |
| **R-OPS-2** secondary ≤ 80/min AND ≤ 500/hr content-creating; 403/429 + retry-after | 80/min, 500/hr | docs Rate-limits: *"no more than 80 content-generating requests per minute and no more than 500 content-generating requests per hour"* | **VERIFIED** — but INCOMPLETE: omits the abuse/spam-flagging dimension (NUANCE-A) |
| **R-OPS-3** ≥1s/mutative, serial | 1s/serial | docs Best-practices: *"wait at least one second between each request"*; *"make requests serially instead of concurrently"* | **VERIFIED** |
| **R-OPS-4** pagination per_page ≤ 100, Link header | 100 | docs Using-pagination (per_page cap 100; Link header) | **VERIFIED** |
| **R-OPS-5** search: 1,000-result ceiling; 100/page; 256-char query; 5 operators; 30/min | as listed | docs REST Search (1,000 ceiling; 256-char query; 5 AND/OR/NOT; 30/min) | **VERIFIED** (minor: community#133400 notes the 256-char validation is "unstable" at the boundary — immaterial here) |
| **R-COMMENT-1** comment 262,144 bytes; design drops comments | 262,144 | github-limits §"Issue comments" (= R-BODY-2) | **VERIFIED** |
| **R-ACCT-1** Issue Forms/templates GA on personal | GA personal | docs Configuring-issue-templates (YAML forms on any repo); pack forms in use | **VERIFIED** |
| **R-ACCT-2** labels + open/closed GA on personal | GA personal | implied by R-LABEL-* / R-STATE-* docs (no org gating) | **VERIFIED** |
| **R-ACCT-3** Issue Fields + custom Issue Types ORG-ONLY/PREVIEW → excluded | org-only/preview, excluded | Matches the standing `verify-availability-not-just-existence` finding (BD-204, 2026-06-05); design correctly excludes both | **VERIFIED** |

**§1 correctness conclusion:** 0 WRONG, 0 UNVERIFIABLE, 25 VERIFIED. Two rows carry a flagged
nuance (R-STATE-2 recency; R-OPS-2 abuse dimension) and one row (R-BODY-4) is verified-as-stated but
incomplete on a side-effect axis — all carried into §2.

---

## §2 — MISSED RULES (hunted from scratch; official + authoritative-practitioner)

These are official/authoritative GitHub behaviors absent from the report that bear on BD-204's HARD
lossless / bulk-create / archive-dogfood design.

### MISS-1 — The 65,536 limit is (per multiple sources) enforced on the GZIPPED REQUEST PAYLOAD, not the raw body count — MATERIAL

- **Source:** community#41331 + the cluster of action-repo issues (changesets/action#174, renovate
  #14551/#15850, release-please#1034) report, repeatedly, that the 65,536 limit tracks the **gzipped
  size of the API request**, not the uncompressed character/byte count — one report: a **231k-char
  comment posted successfully as a ~55K gzipped API call**.
  - <https://github.com/orgs/community/discussions/41331>
  - <https://github.com/changesets/action/issues/174>
  - <https://github.com/renovatebot/renovate/issues/14551>
- **Why it's a MISS:** the report's R-BODY-1/§4 DS-3 frame the open question as "codepoints vs bytes
  of the STORED body." The practitioner-documented enforcement model is a THIRD axis the report never
  raises: **compressed-request-size**. This is exactly the class of "knowable-up-front platform rule
  discovered reactively" that `external-rules-census-before-design` exists to kill.
- **Net effect on BD-204:** FAVORABLE but unstated. If the binding limit is the gzipped request, the
  design's conservative stored-byte budget (worst 62.2% raw stored) is even safer than claimed (the
  request gzips again in transit). It does NOT break the design — but the report should have surfaced
  it so the architect's size contract (§3.3c `provider_body_limit`) is grounded in the REAL
  enforcement model, not an assumed stored-byte one. **Severity: SHOULD-add to the rule set** (correct
  the framing; the conservative budget stands).

### MISS-2 — Autolink / cross-reference / @mention SIDE-EFFECTS on bulk-creating 211 verbatim bodies — MATERIAL

- **Source (official):** docs "Autolinked references and URLs"
  <https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/autolinked-references-and-urls>
  — *"references … are automatically converted to shortened links"* and *"manually linking to an
  issue … will automatically generate another link from the issue back"* (backlink generation);
  community#23123 confirms there is **no way to prevent** standard cross-linking (only the
  `redirect.github.com` workaround). `@username` mentions notify the user (docs basic-formatting).
- **Why it's a MISS:** the report's R-BODY-4 concludes autolinking is render-only and stored content
  is (empirically) preserved — TRUE for STORAGE, but it stops there. It never censuses the
  **side-effect** of carrying `#NNN`/`@name` tokens verbatim into 211 freshly-created issue bodies:
  GitHub will (a) autolink each `#NNN` to whatever issue/PR holds that number in the TARGET repo
  (creating spurious cross-links / backlinks — and the pack's `#1`..`#NNN` tokens are NOT GH issue
  numbers, they are Actions-step / footnote references, so they will mis-link to unrelated target-repo
  issues), and (b) fire mention notifications for any `@token` that resolves to a real GH username.
- **Census (my own, this session):**
  > `CMD`: python over `backlog/BD-*.md` body (lines 2..EOF): `#\d+` not preceded by word-char; `@[A-Za-z…]`.
  > `OUT`: bodies with `#NNN`: **21** (BD-065 `#1 #2 #3 #5`, BD-066, BD-069, BD-114, BD-128, BD-138,
  > BD-161, BD-164, BD-165, BD-166, BD-167, BD-168, … ). bodies with `@`-tokens: **4** (BD-023 `@objc`,
  > BD-043 `@agent-name`, BD-157 `@Model @MainActor`, BD-158 `@MainActor @preconcurrency`).
  > `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: real autolink/mention triggers exist in the live tree.
  > `CONCL`: SUPPORTED — the hazard is non-empty and the report did not census it.
- **Net effect on BD-204:** a single-shot 211-create against the real repo will scatter cross-ref
  backlinks (and possibly mention notifications). The blob round-trip is UNAFFECTED (the `#NNN`/`@`
  tokens decode byte-identically from the gz64 blob), so this is NOT a losslessness break — it is a
  **bulk-creation cleanliness / noise** rule the design should acknowledge (the visible H2 carries the
  tokens; the blob does not autolink). **Severity: SHOULD-add** (operational hygiene, not a lossless
  gate).

### MISS-3 — Archived-repository = fully READ-ONLY (no create / no label edit / no write) — MATERIAL, contradicts BD-204 scope wording

- **Source (official):** docs "Archiving repositories"
  <https://docs.github.com/en/repositories/archiving-a-github-repository/archiving-repositories>
  — archiving makes a repo read-only to everyone *including owners*, across *issues, pull requests,
  labels, milestones, projects, comments, reactions*; community#35100 + gitpod#3978 corroborate
  ("Repository was archived so is read-only"); community#19988 ("can't edit project fields on issues
  in an archived repository").
- **Why it's a MISS:** BD-204.md:20 scope reads *"Dogfood-sequence gated (scratch-repo proof →
  **archive** → real flip)."* An archived repo CANNOT have issues created, labels edited, or
  reverse-sync writes applied. The report's rule set (which includes R-ACCT account-type rules) never
  states archived-repo read-only — yet it is squarely an account/repo-state constraint on every write
  the migrator performs.
  > `CMD`: `grep -n 'archive' backlog/BD-204.md`
  > `OUT`: `:20 … (scratch-repo proof → archive → real flip) per user direction.`
  > `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: the BD's own scope names an archive step.
  > `CONCL`: SUPPORTED — the rule is in-scope by the BD's text and was not censused.
- **Net effect on BD-204:** depends on the intended sequence. If "archive" means *archive the SCRATCH
  proof repo AFTER the proof and BEFORE flipping the REAL repo* (i.e., archive is a teardown of the
  throwaway, not an operate-on-archived step), there is no conflict — but the architect MUST confirm
  that reading, because "archive → real flip" is ambiguous and a literal "operate on an archived repo"
  reading is IMPOSSIBLE. **Severity: SHOULD-add the rule + flag the BD-204:20 wording for architect/user
  disambiguation.**

### NUANCE-A — Secondary rate limit ALSO carries an abuse/spam-flagging + account-invisibility risk (sharpens R-OPS-2/3)

- **Source:** docs Rate-limits (secondary limits "to prevent abuse"); community#110990 ("Account
  marked as spammy and went invisible"); practitioner reports that "creating hundreds … at the same
  moment triggers GitHub's abuse detection."
  - <https://github.com/orgs/community/discussions/110990>
- **Why:** the report correctly names R-OPS-2/3 as "the most material gap" (unpaced 211-create), but
  frames it purely as a 403/429-and-retry concern. The omitted dimension is **account-level abuse
  flagging** (a worse failure than a transient 429). For a personal account dogfooding 211 creates,
  this raises the stakes on the pacing the report already flags as SILENT. **Severity: enrich the
  existing R-OPS-2/3 finding, not a new gate.**

### NUANCE-B — `state_reason: duplicate` was a Dec-2024 breaking addition (sharpens R-STATE-2)

- **Source:** changelog 2024-12-12 (close-as-duplicate via REST); community#150535 (*"`Issue.state_reason`
  can now be `duplicate`, breaking existing clients"*).
  - <https://github.blog/changelog/2024-12-12-github-issues-projects-close-issue-as-a-duplicate-rest-api-for-sub-issues-and-more/>
- **Why:** the report lists `duplicate` as a plain GA enum value. It IS GA, but its recency + the fact
  it broke clients is worth a one-line flag, since the pack's reverse decode parses `state_reason` and
  an older GH Enterprise target might not emit it. **Severity: one-line flag; report's enum is correct.**

### Hunted-but-CLEAN (explicit empty results — verification is not re-authoring)

- **GraphQL node/connection limits** (search, cost) — checked; not binding at 211 entries; the design
  delegates listing to `gh` (R-OPS-4). No additional rule needed. **No finding.**
- **Issue Import API timestamp-setting** — the report (R-ID-2) already notes the legacy import endpoint
  can set timestamps but is out of GA scope. **No finding.**
- **Attachment / gist rules** — design DROPS attachments (carrier-no-sidecar memory); no entry uses
  them. **No finding.**
- **Content-policy / Markdown-injection** — the gz64 blob is in the safe base64 alphabet; the visible
  H2 is plain markdown the entries already author. No additional rule. **No finding.**

---

## §3 — REPO-INPUT COVERAGE + INDEPENDENT CENSUS RE-MEASUREMENT

### 3.1 Input-set coverage (re-derived from the task; did the report read what it should have?)

| Required input (re-derived) | Report read it? | Verdict |
|---|---|---|
| `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` §3.3 / §3.3c (projections censused) | Yes (READ-IN-FULL §7; my read confirms §3.3/§3.3c are the projection it measured) | COVERED |
| `RESEARCH-BD-204-LOSSLESS-FIELD-CENSUS.md` (9-carry/19-drop) | Yes (§7) | COVERED |
| `backlog/_rules.md` (ID-extraction grammar; title single-line) | Yes (§7) | COVERED |
| `backlog/BD-204.md` (DECISION TIERS, identity-on-pack-id, status mapping, **archive scope line**) | Read — but the **archive step at :20 was not turned into a rule** (MISS-3) | PARTIAL |
| GH form family (`work-item.yml`/`inbound.yml`/`config.yml`) | Yes (§7); marker trio `:103-105`, personal-account discussions URL `DShaneNYC/...` confirmed by my read | COVERED |
| Migrator code (forward/reverse/provider/validate-pack/oracle test) | Yes (§3 + §7); symbols verified real below | COVERED |
| BD-204 (the entry) | Yes | COVERED (modulo MISS-3) |

**Coverage conclusion:** the report read the full input set. The single coverage defect is
substantive, not bibliographic: it READ `BD-204.md:20` but did not derive the archived-repo rule from
it (MISS-3).

### 3.2 §2 census re-measurement (my own runs; reconcile to the report EXACTLY)

> **Entry count.** `CMD`: `ls backlog/BD-*.md | wc -l` · `OUT`: `211` · `AT`: `feaa45d`, 2026-06-07 ·
> CONCL: SUPPORTED — matches report.

> **Title (R-TITLE-1/2).** `CMD`: python regex `^\*\*(BD-\d{3})\s*[—-]\s*(.+?)\*\*$` group-2 len over all 211.
> `OUT`: max **223** (BD-208); >256: **0**; top5 BD-208 223 / BD-200 189 / BD-169 174 / BD-180 153 /
> BD-211 150; ID-prefixed worst **231** (BD-208); titles with control chars: **0**; non-ascii titles: **26**.
> `AT`: `feaa45d`, 2026-06-07. CONCL: SUPPORTED — **every figure matches the report exactly.**

> **Body projection (R-BODY-1/2/3).** `CMD`: per entry body=bytes after line 1; gz=`len+80+29+len(b64(gzip mtime0))`; raw=`len+80+29+len(b64)`.
> `OUT`: gz64 top6 — BD-136 **40,771 (62.2%)**, BD-191 29,866 (45.6%), BD-203 17,683 (27.0%),
> BD-200 16,024 (24.5%), BD-204 15,726 (24.0%), BD-195 15,696 (24.0%); gz over 80%/100%: **0/0**;
> raw-b64 worst BD-136 **65,335 (99.7%)**, raw over 80%: **1**; largest RAW body BD-136 **27,954 (42.7%)**.
> `AT`: `feaa45d`, 2026-06-07. CONCL: SUPPORTED — **every figure matches the report exactly** (incl.
> the report's "BD-136 raw-b64 65,335" and "27,954 raw"; the architecture's §3.3c says raw-b64 "65,336"
> — a 1-byte difference between the two prior docs; MY run = 65,335, agreeing with THIS report, not the
> architecture. Immaterial 1-byte rounding/marker-length difference; both round to 99.7%).

> **Control bytes (R-BODY-6).** `CMD`: per entry body scan for `\x00`,`\r`,`\t`, other <0x20 not in {tab,LF}.
> `OUT`: NUL **[]**, CR **[]**, TAB **[]**, other-control **{}**.
> `AT`: `feaa45d`, 2026-06-07. CONCL: SUPPORTED — matches report (∅).

> **Labels (R-LABEL-1/2).** `CMD`: longest generated label `len()`; labels/issue = static{work-item,
> needs-triage,template:work-item-v11.0} + computed{bd-entry,template:bd-v11.0,status:<1>}.
> `OUT`: longest **24** (`template:work-item-v11.0`); max labels/issue **6**.
> `AT`: `feaa45d`, 2026-06-07. CONCL: SUPPORTED — matches report.

> **Status histogram (R-STATE).** `CMD`: per-file first `^Status:` | sort | uniq -c.
> `OUT`: Resolved 167, Open 28, Deferred 11, Deprecated 3, Cancelled 1, Unblocked 1 (6 states).
> `AT`: `feaa45d`, 2026-06-07. CONCL: SUPPORTED — matches report.

> **Hazard set (R-BODY-4/5).** `CMD`: per body `grep -cF '<!--'`, `grep -qF -- '-->'`, `grep -qF '\`\`\`'`; + python occurrence count.
> `OUT`: `-->` set = **{BD-065, BD-069, BD-103, BD-136}** (4); fence = **{BD-136}** (1). `<!--` LINE
> counts (report's `grep -cF`): BD-065 1, BD-069 1, BD-103 1, **BD-136 12**. `<!--` OCCURRENCE count
> (python): **BD-136 14** (12 lines, 2 lines carry two markers).
> `AT`: `feaa45d`, 2026-06-07. CONCL: SUPPORTED — the `-->` and fence sets match the report exactly.
> The report's "BD-136 (12)" is the LINE count from its quoted `grep -cF` CMD and is self-consistent;
> the true OCCURRENCE count is 14. **NOT a finding** (the report's number is correct for its stated
> command; both are reconciled here). The 4+1 hazard sets — the ones that actually matter — are exact.

**Census reconciliation verdict:** every load-bearing §2 number reproduces under independent
measurement. No census mismatch rises to a finding.

### 3.3 §3 compliance-map code-citation verification (file + symbol real?)

> `CMD`: grep for each cited symbol.
> `OUT`:
> - `_tmf_labels_for_entry` → `scripts/lib/tracker-migrate-forward.sh:1501` (report says 1500/1501-1534) — REAL.
> - `Deferred) status_label="status:deferred"` → forward `:1525` — REAL (the C-5 carry-forward landed).
> - forward labels call site → `:902` (report says :901/:902) — REAL.
> - `ENTRY_HEADER`/`FIELD_LINE` → forward `:387`/`:388` — REAL (matches report).
> - `_tmr_emit_pack_tree` → reverse `:712`; dead `extra = e.get("extra_fields", None)` → reverse `:758` — REAL (matches report).
> - `gz64|raw_body|gzip` in forward+reverse → **EMPTY** — REAL (carrier is design-only, matches report's parked-code block).
> - `check_migrator_field_faithfulness` in validate-pack.py → **EMPTY** — REAL (faithfulness check parked, matches report).
> - provider gh: `rate-limit-secondary` `:70`, `rate-limit-primary` `:73`, `result_ceiling_per_query":1000` `:767`, `writes_per_minute_recommended":60` `:770` — REAL (report cites :69-70/:72-73/:766-768/:769-771; ≤3-line drift).
> - work-item.yml marker trio `:103-105`; config.yml `DShaneNYC/...` discussions URL `:8` — REAL.
> `AT`: `feaa45d`, 2026-06-07. `INTERP`: every cited symbol exists; line numbers drift by ≤3 (the
> report predominantly cites symbols + spans, so the drift is immaterial). `CONCL`: SUPPORTED — no
> fabricated citation; the §3 map's "DESIGN COMPLIES; LANDED CODE SILENT" verdicts are grounded in
> real code state.

**§3 map verdict:** code citations are real and the design-vs-landed distinction is accurate. The
report's identification of R-OPS-2/3 (secondary-rate pacing) as the genuine SILENT gap is CONFIRMED
and is SHARPENED by NUANCE-A (abuse-flagging) above.

---

## §4 — VERDICT

**CORRECTIONS-NEEDED** (the report is correct on every value it states and every census number it
reports; the corrections are ADDITIONS the completeness mandate requires, not refutations).

Enumerated corrections, in priority order:

1. **ADD MISS-1** (compressed-request-size enforcement model for the 65,536 limit) to the rule set /
   §4 documented-silent table. Reframe R-BODY-1's enforcement axis; the conservative budget stands.
   *Severity: SHOULD — closes a census-before-design gap; design unaffected (favorable).*
2. **ADD MISS-3** (archived-repo read-only) as a new R-ACCT rule AND flag `BD-204.md:20`
   "archive → real flip" wording for architect/user disambiguation (operate-on-archived is impossible).
   *Severity: SHOULD — directly touches the BD's own dogfood scope; architect must confirm the sequence.*
3. **ADD MISS-2** (autolink/cross-ref/@mention side-effects) as a bulk-creation-hygiene rule; census
   shows 21 `#NNN`-bearing + 4 `@`-bearing entries. Not a lossless gate (blob decodes verbatim) but a
   real noise/notification side-effect on the 211-create. *Severity: SHOULD.*
4. **ENRICH R-OPS-2/3** with NUANCE-A (abuse/spam-flagging + account-invisibility risk) — the report
   already flags the pacing gap as the most material; this raises its stakes. *Severity: SHOULD.*
5. **FLAG R-STATE-2** with NUANCE-B (`duplicate` = Dec-2024 breaking addition; relevant if an older
   GH-Enterprise target is ever in scope). *Severity: NIT.*

Nothing in the report is WRONG or UNVERIFIABLE. No §2 census number requires correction. No §3
citation is fabricated.

---

## §5 — Rules-Applied Verification Block

| Rule | Verification evidence (actual command / quote / measurement) | Conclusion |
|---|---|---|
| `agents-never-commit` | No `git add/commit/push/tag` or state-changing verb issued; `git rev-parse HEAD` (read-only) only; sole write is this ONE report; WebSearch used for online research. | COMPLIANT |
| `external-rules-census-before-design` | §1 independently re-sourced all 25 rule rows; §2 hunted from scratch with deliberately different queries (gzipped-request, archived-repo, abuse-flagging, autolink side-effects) and surfaced 3 missed rules + 2 nuances, each cited. | COMPLIANT |
| `verify-availability-not-just-existence` | Each §1 row re-checked on GA + personal-account axes; R-ACCT-3 (Fields/Types org-only) reconfirmed; MISS-3 adds the archived-repo availability axis the report omitted; target = personal `DShaneNYC/...` confirmed by config.yml:8 read. | COMPLIANT |
| `researcher-maps-blast-radius` | Re-ran EVERY §2 census over all 211 entries independently (title/body/control/label/status/hazard) + added the `#NNN`/`@` autolink census (21/4); reconciled to the report's numbers exactly; §3 verified every cited symbol. | COMPLIANT |
| `empirical-evidence-blocks` | Every repo claim carries CMD + verbatim OUT + HEAD `feaa45d` + 2026-06-07 + INTERP + CONCL (§3.2/§3.3, MISS-2/MISS-3 census blocks); every platform claim carries URL + quoted text (§1 table, §2). | COMPLIANT |
| `scope-deliverables-to-the-ask` | Exactly the 3 checks + verdict: §1 per-rule correctness, §2 missed rules, §3 input-coverage + census reconciliation, §4 verdict. No design, no fix authoring; empty hunted-but-clean results stated explicitly. | COMPLIANT |
| `filename-uniqueness-heuristic` | `find . -name "RESEARCH-BD-204-GH-ISSUES-RULES-VERIFY.md" -not -path "./.git/*"` returned EMPTY before write (Bash, this session). | COMPLIANT |
| `rules-applied-verification-block` | This table — per-rule, evidence quoted, terminal conclusion; no empty evidence; no AMBIGUOUS state. | COMPLIANT |

---

## §6 — READ-IN-FULL attestation (per-file direct-read, this session, at HEAD `feaa45d`)

| Document | Direct-read proof |
|---|---|
| `RESEARCH-BD-204-GH-ISSUES-RULES.md` (under verification) | Read full (1-597). Every §1 rule row, §2 census block, §3 map row, §4 DS table examined and independently checked. |
| `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` §3.3 / §3.3c | Read full (258-477 + the §3.3c size budget + the §4.5 enumerate-encoding table via grep). The gz64 carrier + size budget are the projections the report censused; my §3.2 reproduces them. |
| `RESEARCH-BD-204-LOSSLESS-FIELD-CENSUS.md` | Read full (1-436). The 9-carry/19-drop census + green-CI root cause; cross-checked against my measurements + the report. |
| `backlog/_rules.md` | Read full (1-84). ID-extraction grammar (title = bold-header after em-dash, single line) — confirms R-TITLE-2 structural basis. |
| `backlog/BD-204.md` | Read full (1-27). DECISION TIERS, identity-on-pack-id, status mapping, and the `:20` archive scope line (basis of MISS-3) + `:23` C-5 Deferred carry-forward (verified landed at forward:1525). |
| Memory files | `feedback_external_rules_census_before_design`, `feedback_verify_availability_not_just_existence`, `feedback_researcher_maps_blast_radius_before_architect`, `feedback_architect_planner_empirical_evidence`, `feedback_scope_deliverables_to_the_ask`, `feedback_agent_output_rules_applied_block` — all read in full this session; carried as governing rules (reflected in §5). |
| `CLAUDE.md ## Pack memory` | Provided in full in session context; in-force rules (boundary, empirical-evidence, ci-guard-measure-then-bound, scope-deliverables) applied. |
| Code (verified real) | `scripts/lib/tracker-migrate-forward.sh` (ENTRY_HEADER:387, _tmf_labels_for_entry:1501, Deferred:1525, call site:902), `tracker-migrate-reverse.sh` (_tmr_emit_pack_tree:712, dead extra_fields:758), `tracker-provider-gh.sh` (rate classify:70/73, capabilities:767/770), `validate-pack.py` (no faithfulness check — grep empty), `.github/ISSUE_TEMPLATE/work-item.yml`:103-105, `config.yml`:8. |
| Official GitHub docs + practitioner sources | Fetched via WebSearch this session; exact quotes captured in §1/§2 (rate-limits, best-practices, REST issues, REST search, pagination, managing-labels, autolinked-references, archiving-repositories, github-limits README, changelog 2024-12-12, community discussions #41331/#76832/#189718/#150535/#110990/#35100/#19988/#23123, github/docs#32156, action-repo body-too-long issues). NOT relied on from training data. |

**No named document was derived rather than read.** All repo measurements are this session's own
command output at HEAD `feaa45d` (2026-06-07); all platform claims carry a source URL + quoted text.

**End of RESEARCH-BD-204-GH-ISSUES-RULES-VERIFY.md**
