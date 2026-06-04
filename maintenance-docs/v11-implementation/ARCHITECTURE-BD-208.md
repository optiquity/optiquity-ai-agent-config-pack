# ARCHITECTURE-BD-208 — Pack Chat editing-actor rule (minor-only Pack Chat; coder does all MAJOR + everything outside the small set)

**Status:** Design (architect). DESIGN ONLY — no source edits, no git verbs.
**HEAD at design:** `a630a312d7c7b93437b99c9d9f87cf52e1afe949`
**Date:** 2026-06-04
**BD:** BD-208 (`pack-ops/BACKLOG.md` L3420–3439)
**Pipeline:** architect (this doc) → planner → (coder → bounded review/fix) per commit.

This doc designs (1) the new trinity `## Pack memory` rule text, (2) the
operational MINOR-vs-MAJOR boundary, (3) the lock-step propagation as targeted
in-place edits, (4) the reconciliation against every rule it touches, (5) the
encoding-surface lock-step. The BD's binding decisions are FIXED; this design
sits within them and challenges only their realizability (§0.1).

**AMENDMENT (user, 2026-06-04 — Option B).** The user chose Option B over the
original #3/#9 = MAJOR dispositions: **authoring a substantive NEW BD/CHANGELOG
ENTRY stays Pack-Chat-direct** (it is ALREADY user-reviewed governance — the
user approves BD-opens and version-boundary CHANGELOG content — so it is NOT the
un-reviewed-edit class the asymmetry targets). The MAJOR-to-coder rule now bites
on **substantive edits of EXISTING (landed) content + everything outside the
small set.** §1 rule text, §2 boundary + §2.1/§2.2, and §4.3 are amended in
place; §3/§5/§6/§8 carry only the consequential follow-on edits. One coherence
loophole (delete-and-reauthor to launder a major edit as minor) is SURFACED and
closed in §2.2 — not silently fixed. User note: "Option B is fine until I see
any problems that cause me to change my mind."

---

## 0. Binding decisions (FIXED) and the asymmetry being closed

Per BD-208 (user 2026-06-04, FIXED — architect designs WITHIN):

- **D1.** The small PM-only set Pack Chat may MINOR-edit: `BACKLOG.md`,
  `CHANGELOG.md`, `README.md` version table, `PACK-CHAT.md`, `PACK-AGENTS.md`,
  the trinity `CLAUDE/AGENTS/GEMINI.md` (root + `project-template/`),
  `PACK-MEMORY-RATIONALE.md`, + the per-entry tree directories (`/backlog/`,
  `/changelog/`, the three `project-template/docs/project/{backlog,
  implementation-plan,changelog}/` template trees).
- **D2.** Pack Chat does MINOR edits only on that set. MAJOR edits to the set
  → coder, scoped in. (Architect defines the precise boundary — §2.)
- **D3.** The coder does ALL major edits + ALL edits outside the small set,
  under the bounded review/fix cycle.
- **D4.** Pack Chat retains: commits (`agents-never-commit`), irreducible
  destructive ops (deletions, user-approved), its own memory files.
- **D5.** Applies to BDs 203, 204, 206, 207, BD-205's fix-cycle, "and more."

**The asymmetry being closed (user, BD-208 Problem line).** Coder edits flow
through the bounded review/fix cycle naturally; Pack-Chat-direct edits did NOT
(Pack Chat cannot review itself; no natural fix loop). On a large structural
BD the old "Pack Chat edits PM-only directly" convention forced a split where
Pack Chat hand-edited substantial content with NO review while coder edits got
the cycle. BD-208 makes the cycle UNIFORM: any MAJOR edit, regardless of
target, runs through coder + bounded review/fix.

### 0.1 Realizability challenge (preliminary-triage-architect-challenge)

The binding decisions are realizable. One realizability tension surfaced and is
resolved inside the rule text (NOT silently "fixed"):

- **CHALLENGE-1 (resolved in rule, §1).** D1's small set is byte-identical to
  the EXISTING PM-only-files list (PACK-AGENTS.md L133–140 + dirs L142–155).
  So D1 does not ADD a Pack-Chat write surface — the surface is unchanged. What
  BD-208 changes is the *depth* Pack Chat may apply on that surface (minor only)
  and re-homes major-depth edits to the coder. This is realizable because the
  surface set is already enumerated and CI-tracked; the rule narrows the verb,
  not the file list. Recorded so the planner does not mistake D1 for a
  surface-list change.
- **CHALLENGE-2 (resolved, §4.3).** `review-cycle-position-checkpoint` memory
  item #3 says a Pack-Chat-DIRECT PM-only edit is "an IMPLEMENTATION [that] gets
  an INDEPENDENT reviewer reading the actual diff before commit." A naive
  reading of BD-208's "Pack Chat does MINOR edits" could be read as exempting
  minor edits from that reviewer. That would be UNSAFE and is NOT what BD-208
  authorizes. Resolved (Option B) by scoping the Pack-Chat-direct set to (a)
  bookkeeping tokens — covered by the `validate-pack`+parity/grep sanity pass —
  and (b) NEW-ENTRY authoring — covered by the USER's own governance review of
  the open/changelog content (the independent reviewer for a new entry IS the
  user's approval). Substantive edits of ALREADY-LANDED content carry no such
  user-governance review, so they stay MAJOR → coder → reviewer. See §2 + §4.3.

No binding decision is unworkable. Proceed.

---

## 1. THE NEW RULE (trinity `## Pack memory` text)

**Placement:** `### Pack Chat scope` subsection, inserted IMMEDIATELY AFTER the
existing "What Pack Chat CAN edit directly" bullet and BEFORE
"Commit-approval requests include next-steps plan", in all three trinity files
(CLAUDE.md / AGENTS.md / GEMINI.md at pack root). Verified correct home:
`### Pack Chat scope` already owns "Pack Chat does NO fixes", "What Pack Chat
CAN edit directly", and "Pack Chat NO coder review; bounded reviewer/fix cycle"
— the new rule is the editing-ACTOR companion to those three.

**Rule text (byte-identical across all three trinity files — no CLI-specific
content):**

```
- **Pack Chat does MINOR edits only; coder does every MAJOR edit and
  everything outside the small set.** On the small PM-only set — `BACKLOG.md`,
  `CHANGELOG.md`, the `README.md` version table, `PACK-CHAT.md`,
  `PACK-AGENTS.md`, the trinity `CLAUDE/AGENTS/GEMINI.md` (pack root +
  `project-template/`), `PACK-MEMORY-RATIONALE.md`, and the per-entry tree
  directories (`/backlog/`, `/changelog/`, `project-template/docs/project/
  {backlog,implementation-plan,changelog}/`) — Pack Chat may apply directly:
  (a) bookkeeping tokens (a `Status:`/`Resolved:` state flip, a version bump, a
  dated note, a README version-table row, a CHANGELOG release-block append); and
  (b) AUTHORING A NEW ENTRY — opening a substantive BD entry or authoring a NEW
  version-boundary CHANGELOG entry — because a new entry is already user-reviewed
  governance (the user approves BD-opens and version-boundary CHANGELOG content).
  Every MAJOR edit goes to a `pack-coder` scoped in by Pack Chat's prompt, under
  the bounded review/fix cycle. An edit is MAJOR if it makes a SUBSTANTIVE edit
  to ALREADY-LANDED content (re-scoping an existing entry; a multi-field rewrite
  of a landed entry; a bulk hand-rewrite of a monolith), OR alters a
  rule/contract, OR touches any file OUTSIDE the small set. Deleting-and-
  reauthoring an existing entry-ID is a substantive edit of landed content (=
  MAJOR), NOT a new authoring — the new-entry carve-out covers genuinely new IDs
  only. When in doubt between a new-entry author and an existing-content edit, it
  is MAJOR (route to coder). Pack Chat scoping a PM-only file INTO a coder prompt
  is the supported path for major PM-only work — it is NOT a boundary violation.
  Pack Chat retains only:
  commits (`agents-never-commit`), irreducible user-approved destructive ops
  (deletions), and its own out-of-repo memory files. A Pack-Chat-direct edit is
  still an IMPLEMENTATION: Pack Chat's `validate-pack`/parity/grep sanity pass is
  the bounded check on it; a NEW-ENTRY author rides on the user's own governance
  review of the open/changelog content (the user approves it), not a coder
  reviewer. The moment an edit instead touches ALREADY-LANDED content
  substantively — or any out-of-small-set file — it is MAJOR and the independent
  reviewer applies via the coder cycle.
  `[roles: universal] [rationale: pack-chat-minor-edits-only]`
```

**Rationale slug:** `pack-chat-minor-edits-only` (single kebab-case token —
matches Check 45 heading regex `^##\s+([a-z0-9][a-z0-9-]*)\s*$`; verified
unique against the 21 existing corpus slugs, §5/E-3).

**Role tag:** `[roles: universal]` — binds Pack Chat AND every agent (an agent
must know that major PM-only work is legitimately routed to it via scope-in).

---

## 2. THE MINOR-vs-MAJOR BOUNDARY (operational definition)

**Definition (Option B — an agent/Pack Chat applies this unambiguously):**

> An edit is **MINOR (Pack-Chat-direct)** iff it targets a file in the small set
> (D1) AND is one of: (a) a bookkeeping-token change — a `Status:`/`Resolved:`
> value, a version string, a dated one-line note, a new table ROW in the
> established column shape, or a CHANGELOG release-block APPEND; OR (b) AUTHORING
> A GENUINELY NEW ENTRY — opening a substantive BD entry at a new ID, or
> authoring a new version-boundary CHANGELOG entry (the user's approval of the
> open / changelog content IS the governance review).
>
> An edit is **MAJOR (→ coder)** iff it is ANY of: a SUBSTANTIVE edit to
> ALREADY-LANDED content (re-scoping an existing entry; a multi-field rewrite of
> a landed entry; a bulk hand-rewrite of a monolith); a rule/contract change; OR
> any edit to a file OUTSIDE the small set. A delete-and-reauthor of an EXISTING
> entry-ID is a substantive edit of landed content (MAJOR), not a new author.
>
> **Tie-break: when unsure whether something is a new-entry author or an
> existing-content edit, treat it as MAJOR (route to coder).**

The Option-B pivot is NEW-vs-LANDED, not prose-vs-token. Authoring a NEW entry —
even multi-line substantive prose — is Pack-Chat-direct because the user reviews
the open/changelog content as governance. Editing ALREADY-LANDED content
substantively has no such user-governance review, so it needs the coder's
independent reviewer. The decisive question is *"am I authoring a brand-new
entry the user approves as governance, or substantively changing content that
already landed?"* New-author or bookkeeping-token ⇒ MINOR. Substantive change to
landed content (or anything outside the small set) ⇒ MAJOR.

### 2.1 Worked dispositions (every example from the ask, resolved)

| # | Edit | Disposition | Why |
|---|---|---|---|
| 1 | A status flip (`Status: Open` → `Resolved`) | **MINOR** | Single-token; correctness = the BD's batch is done (already-decided). `BACKLOG.md`-has-no-Resolved-section rule already governs the shape. |
| 2 | A status flip carrying a NEW rationale paragraph in `Resolved:` of a LANDED entry | **MAJOR** | The `Resolved:` rationale is a substantive edit to ALREADY-LANDED content (was the resolution characterized truthfully? — the BD-059 false-`customization:none` failure class) and carries no user-governance review. The token flip alone would be minor; the substantive edit to the landed entry makes the whole edit MAJOR → coder. |
| 3 | Opening a substantive NEW BD entry (real Type/Problem/Acceptance prose, new ID) | **MINOR** *(Option B)* | Authoring a NEW entry IS user-reviewed governance — the user approves the BD-open content. Not the un-reviewed-edit class the asymmetry targets. (Was MAJOR pre-amendment.) |
| 4 | A README version-table row ADD (new minor version row, established columns) | **MINOR** | Fixed-shape row following the existing table columns; correctness = the version/date are correct, covered by `check_readme_version` (Check). No prose. |
| 5 | A README narrative/version-HISTORY paragraph (not the table row) | **MAJOR** | Substantive prose outside the fixed table shape. |
| 6 | A one-line dated note ("2026-06-04: blocked on BD-203") on an entry | **MINOR** | Single dated bookkeeping line, no re-scope. |
| 7 | A RE-SCOPE of an EXISTING (landed) entry (rewrites Scope/Acceptance/Problem) | **MAJOR** | Substantive edit of already-landed content; alters the entry's contract; no user-governance review attaches to a re-scope the way it does to an open → needs the coder's independent reviewer. |
| 7b | A MULTI-FIELD edit to an EXISTING (landed) entry (several fields rewritten at once) | **MAJOR** | Substantive edit of landed content; the multi-field surface is exactly what the independent reviewer exists to read. |
| 8 | A CHANGELOG release-block APPEND (already-decided entries, ship time) | **MINOR** | Append of already-decided, fixed-shape release content at a version boundary; correctness = the entries match what shipped (already decided in their BDs). No NEW prose authored here. |
| 9 | Authoring NEW version-boundary CHANGELOG entry prose (first-time description) | **MINOR** *(Option B)* | A version-boundary CHANGELOG entry is user-reviewed governance (the user approves version-boundary content). New authoring, not a landed-content edit. (Was MAJOR pre-amendment.) |
| 13 | BULK STRUCTURAL hand-rewrite of a monolith (e.g. BD-203 B0 — bulk hand-rewrite of `BACKLOG.md`/`CHANGELOG.md`) | **MAJOR** | This is the ORIGINAL asymmetry the user is closing: a large structural rewrite of landed content with no independent review. Stays coder + bounded review/fix. Confirmed MAJOR under Option B. |
| 10 | Editing a rule in `PACK-CHAT.md`/`PACK-AGENTS.md`/trinity `## Pack memory` | **MAJOR** | Alters a rule/contract — always major; additionally already gated by `pack-architect spawn protocol` (architect-first). |
| 11 | A version bump in `README.md` table + tag-relevant fields | **MINOR** | Version-string token change; established shape. |
| 12 | A per-entry stub/file in `/backlog/` (new ID — empty skeleton OR substantive new BD body) | **MINOR** *(Option B)* | A new-ID entry author is user-reviewed governance (same as #3) whether skeleton or full body. (A LATER substantive edit to that entry once it has landed is MAJOR — see #7/#7b.) |

### 2.2 Edge cases resolved

- **SURFACED LOOPHOLE — delete-and-reauthor (closed, not silently fixed).** The
  "new-entry author = MINOR / existing-entry edit = MAJOR" line opens an obvious
  laundering path: delete a landed entry and re-author it to dress a major edit
  as a minor new-author. CLOSURE (cleanest Option-B form consistent with the
  user's intent — user-reviewed ENTRY governance is direct, un-reviewed
  SUBSTANTIVE edits of landed content go to coder): the new-entry carve-out
  applies ONLY to a GENUINELY NEW entry-ID with no prior landed version. Any
  edit that touches an entry-ID that has already landed — including a
  delete-then-reauthor of that same ID — is a substantive edit of landed content
  and is MAJOR. The test is the ENTRY-ID's history (new vs landed), not the
  mechanism (author vs edit vs delete+readd). **Flagged for the user:** this is
  the one genuine incoherence in the raw "new=minor" framing; the ID-history
  closure resolves it without contradicting Option B. If the user prefers a
  different closure, this is the decision point.
- **Mixed edit (token flip + substantive landed-content edit).** If a single
  logical edit on a LANDED entry contains BOTH a minor token (e.g. a `Status:`
  flip) AND a substantive change to that landed entry (e.g. a new `Resolved:`
  rationale — #2), the WHOLE edit is MAJOR and goes to the coder — Pack Chat does
  NOT split off the token and apply it directly. (Prevents the fragmentation that
  re-creates the asymmetry BD-208 closes.) A pure token flip with no substantive
  landed-content change stays MINOR.
- **New-entry author vs landed-content edit is the pivot, not prose-vs-token.**
  Authoring a NEW entry is MINOR even when it is multi-line substantive prose,
  because the user reviews the open/changelog content as governance. The same
  prose authored as an EDIT to an entry that already landed is MAJOR. The test
  is NEW-vs-LANDED, not how much prose the edit contains.
- **Per-entry mirror regeneration.** Regenerating a monolithic mirror
  (`BACKLOG.md`/`CHANGELOG.md`) from the per-entry tree via the regenerator is
  MECHANICAL output, not a Pack-Chat hand-edit — out of scope of this boundary
  (it is generator output, governed by the per-entry-tree rules). Only HAND
  edits are classified by this boundary.
- **Memory files (out-of-repo).** Always Pack-Chat-direct (D4) — not in the
  small repo set, not subject to this boundary (Pack Chat's own operating
  state, not pack work). Unchanged by BD-208.

---

## 3. PROPAGATION (targeted in-place edits — NOT rewrites)

Follows the rule-change propagation procedure in `PACK-CHAT.md` § "Keeping
CLAUDE.md, AGENTS.md, GEMINI.md, and PACK-AGENTS.md current" → "Rule-change
propagation procedure" (corpus → rationale → references + manifest in same
commit → cache → manifest-regen last). Removing-a-rule order is not needed (this
is an ADD).

All edits below are TARGETED inserts/replacements with exact anchor text
(edit-in-place-not-full-rewrite). The coder re-reads each file's section map
after editing and reports actual re-read evidence.

### 3.1 Corpus — trinity `## Pack memory` ×3 (procedure step 1)

**Surface:** `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` (pack root), `### Pack Chat
scope` subsection.
**Edit:** INSERT the §1 rule bullet (byte-identical in all three) immediately
after the "What Pack Chat CAN edit directly" bullet and before the
"Commit-approval requests include next-steps plan" bullet.

**Exact anchor (identical across all three files).** The "What Pack Chat CAN
edit directly" bullet ENDS with this byte-identical line in all three:

```
  - Pack Chat may NOT edit project-template / supporting-docs /
    maintenance-docs / scripts / fixtures / agent definitions —
    those go to pack-coder.
```

INSERT the new bullet on the line AFTER that line and BEFORE:

```
- **Commit-approval requests include next-steps plan.** Every
```

Parity note: the "What Pack Chat CAN edit directly" bullet has a CLI-specific
MIDDLE sub-bullet (CLAUDE = "Memory files"; AGENTS = "Per V2 §D, Codex has no
… memory cache"; GEMINI = "Per V2 §D, Gemini …"). The INSERT anchor (the final
"may NOT edit …those go to pack-coder" sub-bullet) and the following bullet are
byte-identical across all three, so the SAME insertion is applied 3× with NO
per-CLI variation in the new bullet. The new rule has no CLI-specific content,
so full trinity parity holds (no trinity-exemption needed).

**Enforcing checks:** trinity-parity (Check 18 — H2 STRUCTURE only; bullet text
is not gated, but parity discipline applies); Check 45 bijection requires the
new `[rationale: pack-chat-minor-edits-only]` to resolve (step 2 lands it).

### 3.2 Rationale — `PACK-MEMORY-RATIONALE.md` (procedure step 2)

**Surface:** `pack-ops/PACK-MEMORY-RATIONALE.md`.
**Edit:** APPEND a new `## pack-chat-minor-edits-only` section at END of file
(the file is an ordered list of `## <slug>` sections; append is in-place, not
rewrite). Suggested body (Why + How-to-apply + rejected-alternative — the
established 3-part shape):

```
## pack-chat-minor-edits-only

**Why.** User-authorized 2026-06-04 (BD-208). The pre-BD-208 convention let
Pack Chat edit PM-only files directly at ANY depth. Coder edits flow through
the bounded review/fix cycle; Pack-Chat-direct edits did not (Pack Chat cannot
review itself — see `bounded-review-fix-cycle`). On a large structural BD
(BD-203) this forced a split: Pack Chat hand-edited substantial PM-only content
with NO independent review while the coder's edits got the cycle. The asymmetry
let un-reviewed substantive edits of LANDED content land. BD-208 (Option B)
makes the review uniform per CLASS: substantive edits of already-landed content
+ rule edits + out-of-small-set edits run through a coder + reviewer; NEW-entry
authoring stays Pack-Chat-direct under the user's governance approval.

**How to apply.** Classify every PM-only edit by the §2 boundary in
ARCHITECTURE-BD-208.md (Option B): MINOR (Pack-Chat-direct) = (a) a bookkeeping
token (status flip / version bump / dated note / table row / decided-block
append) OR (b) authoring a GENUINELY NEW entry (BD-open at a new ID /
version-boundary CHANGELOG entry) — the user's governance approval IS the review.
MAJOR (→ coder) = a substantive edit of ALREADY-LANDED content (re-scope /
multi-field rewrite / structural rewrite), a rule edit, or any out-of-small-set
edit. A delete-and-reauthor of a landed ID is MAJOR (landed-content edit), not a
new author. Tie-break: when unsure new-vs-landed, MAJOR. Scoping a PM-only file
INTO a coder prompt is the supported path and is NOT a boundary violation (the
same scope-in clause PACK-AGENTS.md § "Agent permission rules" already grants
per-entry dirs). A bookkeeping edit gets Pack Chat's `validate-pack`/parity/grep
sanity pass; a new-entry author rides the user's governance review; neither
self-promotes into a substantive edit of landed content (that is MAJOR).

**Rejected alternative.** "Let Pack Chat keep editing PM-only at any depth, just
add a post-hoc reviewer pass on Pack-Chat edits." Rejected: Pack Chat cannot
spawn a reviewer on its OWN in-place edits without first packaging them as a
coder deliverable (no IMPL-REPORT, no fresh-context diff to review) — the
clean structural fix is to route major edits through the coder that already
produces the reviewable artifact. This composes `bounded-review-fix-cycle`
rather than bolting a second review path onto Pack Chat.
```

**Enforcing check:** Check 45 bijection (slug-set equality). Lands in the SAME
commit as step 1 so the bijection never sees a half-applied state.

### 3.3 References — `PACK-AGENTS.md` PM-only section (procedure step 4)

**Surface:** `pack-ops/PACK-AGENTS.md` § "Agent permission rules", the
**"PM-only files and directories"** block (L130–159) and its scope-in clause
(L157–159).

**Does the "off-limits unless scoped in" clause need rewording?** YES — a
minimal one-line ADDITION, not a rewrite. Current text (L130–131):

```
**PM-only files and directories** are off-limits to all agents unless the
caller's prompt explicitly scopes them in.
```

This is already CORRECT for BD-208 (scope-in is the major-edit path). But it
frames scope-in as an EXCEPTION ("unless"). BD-208 promotes scope-in to the
DEFAULT for MAJOR edits. ADD one reference line after the existing scope-in
clause at L157–159 (which currently reads):

```
`pack-coder` MAY scope a per-entry directory in for an explicit BD when
Pack Chat's prompt scopes it — the same exception clause that applies to
the PM-only files above.
```

INSERT immediately after it (one-line REFERENCE, no imperative restatement —
anti-restate-safe per §5/E-2):

```
Per trinity `## Pack memory` `[rationale: pack-chat-minor-edits-only]`, scoping
a PM-only file into a coder prompt is the DEFAULT path for any MAJOR edit to it
(Pack Chat does only MINOR bookkeeping edits directly); the imperative + the
minor-vs-major boundary live in the corpus, not here.
```

This is a NAME+slug reference (resolves to the SSOT), NOT a body restatement.
The existing "off-limits unless scoped in" wording stays — it is still true for
agents; BD-208 adds WHO defaults to scope-in for major work.

**Enforcing check:** Check 46 anti-restate (must NOT verbatim-restate ≥60 chars
of the corpus body) + reference-resolution (the reference names the canonical
home). The line above names the rule + slug and paraphrases — anti-restate-safe.

### 3.4 References — `PACK-CHAT.md` scope section (procedure step 4)

**Surface:** `pack-ops/PACK-CHAT.md`. Two touch points:

**(a)** § "Behavioral rules" — no existing bullet states the editing-actor
split. ADD one REFERENCE bullet (anti-restate-safe) after the "Real fixes only
— no green-the-test band-aids" bullet (which ends L94):

```
- **Pack Chat does MINOR edits only; coder does MAJOR.** On the small PM-only
  set Pack Chat applies directly only (a) bookkeeping edits (status flips,
  version bumps, dated notes, table rows, decided-block appends) and (b) NEW-entry
  authoring (BD-open / version-boundary CHANGELOG, which the user reviews as
  governance); every MAJOR edit — a substantive edit of already-landed content, a
  rule edit, or anything outside the small set — goes to `pack-coder` scoped in,
  under the bounded review/fix cycle. See trinity `## Pack memory`
  `[rationale: pack-chat-minor-edits-only]` for the imperative + the boundary
  (the canonical home).
```

This names the rule + paraphrases the split (the distinguishing word-set, not a
verbatim ≥60-char body slice) and points to the SSOT. Anti-restate-safe.

**(b)** § "Role" (L9–21) currently says Pack Chat "Write[s] files directly to
the repo (CLI: native file write and git)" (L13) and "plan and execute pack
changes directly" (L21). These read as ANY-depth direct write — now stale under
BD-208. TARGETED in-place edit of L13 and L21:

- L13 replace `Write files directly to the repo (CLI: native file write and
  git)` → `Apply bookkeeping edits and NEW-entry authoring (BD-opens /
  version-boundary CHANGELOG) to the small PM-only set directly; route every
  MAJOR edit — substantive edits of already-landed content, rule edits, anything
  outside the small set — to a pack-coder per trinity` `## Pack memory`
  `[rationale: pack-chat-minor-edits-only]``
- L21 replace `You plan and execute pack changes directly, with explicit
  approval before any commit.` → `You plan pack changes; you apply bookkeeping
  edits + new-entry authoring on the small PM-only set directly and route every
  MAJOR (landed-content / rule / out-of-set) edit to a pack-coder, with explicit
  approval before any commit.`

Both are minimal in-place replacements of the stale "directly at any depth"
framing; neither restates the corpus body.

**Enforcing check:** Check 46 anti-restate + reference-resolution (same as §3.3).

### 3.5 Spawn-rule manifest — `.spawn-rule-manifest.txt` (procedure step 5)

**Surface:** `pack-ops/.spawn-rule-manifest.txt`.
**Edit:** APPEND one new record (the file is blank-line-separated records;
append is in-place). Because §3.3 and §3.4 add reference surfaces that point at
the new rule, the manifest MUST record them so Check 46 reference-resolution
covers them:

```
slug:       pack-chat-minor-edits-only
canonical:  ## Pack memory
corpus:     ### Pack Chat scope — "Pack Chat does MINOR edits only; coder does every MAJOR edit and everything outside the small set"
references: PACK-AGENTS.md § "Agent permission rules" (PM-only scope-in = default major-edit path); PACK-CHAT.md § "Behavioral rules" ("Pack Chat does MINOR edits only; coder does MAJOR"); PACK-CHAT.md § "Role" (minor-direct / major-to-coder split)
```

**Enforcing check:** Check 46 reference-resolution — every named reference
surface must exist AND reference the canonical home (`## Pack memory`). The §3.3
+ §3.4 reference lines each name `## Pack memory` + the slug, so they resolve.

### 3.6 Memory cache (procedure step 3) — Pack-Chat upkeep, out-of-repo

Pack Chat adds a thin recall-only memory file `feedback_pack_chat_minor_edits_
only.md` to its out-of-repo cache pointing at `[rationale:
pack-chat-minor-edits-only]`, and adds the index line under "Pack Chat scope" in
MEMORY.md. No validator gate (trinity wins). This is Pack-Chat upkeep, NOT a
coder deliverable — out of the commit's repo scope. Named here for completeness
per the propagation procedure.

### 3.7 Manifest regen (procedure step 6) — last

The commit touches `pack-ops/` files (PACK-AGENTS.md, PACK-CHAT.md,
PACK-MEMORY-RATIONALE.md, .spawn-rule-manifest.txt) → v11-surface
(`regenerate-manifest-v11-surface`). Coder runs `bash test-fixtures/build.sh
--all --clean`; if `git diff test-fixtures/manifest.txt` is non-empty, stage it
in the SAME commit. (The 3 pack-root trinity files are NOT under the four
trigger dirs, but the `pack-ops/` edits ARE — so regen is required.)

---

## 4. RECONCILIATION (challenge against every rule the new rule touches)

Every contradiction is surfaced and resolved IN the rule text (§1) or boundary
(§2). None left open.

### 4.1 `Pack Chat does NO fixes` — COMPOSES, does not contradict

The no-fixes rule (trinity `### Pack Chat scope`) is specifically about applying
REVIEW FINDINGS to pack-product: "Pack Chat does NOT use Edit/Write tools to
apply review findings… A one-line typo fix from a review finding goes to
fix-coder." Its scope is the review/fix cycle output.

BD-208's minor carve-out is about ORIGINATING bookkeeping edits to the small
PM-only set — NOT applying review findings. These are disjoint:
- A review FINDING (even a one-token one) → fix-coder. UNCHANGED by BD-208.
- A bookkeeping ORIGINATION (status flip, version bump) on the small set →
  Pack-Chat-direct (minor). This is what the EXISTING "What Pack Chat CAN edit
  directly" bullet already permits ("these are NOT fixes").

**Resolution:** BD-208 does not touch the no-fixes rule's domain (findings) at
all. The new rule's clause "Pack Chat retains only: commits, … and its own
memory files" plus the §2 boundary keeps the two domains separate. The rule
text explicitly says a MAJOR edit goes to coder "under the bounded review/fix
cycle" — i.e., BD-208 makes MORE edits flow to the coder, never fewer; it
strengthens, never weakens, no-fixes. No contradiction. (The existing
distinct-from cross-reference in PACK-CHAT.md "Real fixes only" bullet, which
already names `feedback-pack-chat-does-no-fixes`, stays valid.)

### 4.2 PM-only "off-limits unless explicitly scoped in" — REWORDED to default

(PACK-AGENTS.md L130–131 + scope-in clause L157–159.) Pre-BD-208: scope-in is
an EXCEPTION granted per-prompt. BD-208: scope-in is the DEFAULT path for MAJOR
PM-only edits.

**Resolution:** §3.3 ADDS a reference line promoting scope-in to default for
major edits WITHOUT removing the "off-limits unless scoped in" base rule (still
true: an agent may not touch a PM-only file unless its prompt scopes it in).
The two compose: the base rule says "agents need scope-in"; BD-208 says "for
MAJOR edits, Pack Chat's default is to give that scope-in to a coder rather
than edit directly." No contradiction — BD-208 changes Pack-Chat's DEFAULT
behavior, not the agent permission gate.

### 4.3 `review-cycle-position-checkpoint` item #3 — the central reconciliation

Memory item #3: a Pack-Chat-DIRECT (PM-only) edit is "an IMPLEMENTATION [that]
gets an INDEPENDENT reviewer reading the actual diff before commit… Pack Chat's
own validate-pack/parity/grep self-check is a sanity pass, NOT the independent
review." User-locked 2026-06-03, after rejecting a Pack-Chat-direct trinity edit
committed on "architect design + self-check" with no reviewer.

**Does the minor carve-out need a review EXEMPTION, and is it safe?**

The new rule does NOT exempt review-worthy edits from independent review — it
RE-PARTITIONS by WHO provides the review (Option B):
- A MAJOR edit (substantive edit of ALREADY-LANDED content / rule change /
  out-of-small-set) goes to a CODER, whose IMPL-REPORT the independent reviewer
  reads — i.e., BD-208 brings these UNDER the independent reviewer item #3
  demands. This STRENGTHENS item #3: the un-reviewed substantive Pack-Chat edits
  of landed content that item #3 reacted to are exactly what BD-208 eliminates.
- A NEW-ENTRY author (substantive BD-open / version-boundary CHANGELOG entry,
  §2(b)) stays Pack-Chat-direct, and its independent review IS the USER's
  governance approval of the open/changelog content — not a coder reviewer. This
  is SAFE because the user reviews every BD-open and every version-boundary
  CHANGELOG change as governance; that approval is the independent read item #3
  is asking for, applied at the governance gate rather than a coder cycle.
- A bookkeeping-token edit (status flip / version bump / dated note / decided
  block, §2(a)) keeps the sanity-pass-only treatment — fully covered by
  `validate-pack` Check 45/18/`readme-version` + parity + grep; no prose to
  reason about.
- The incident item #3 reacted to was a substantive TRINITY RULE edit — MAJOR
  under §2 (#10), routed to a coder + reviewer. NEITHER carve-out covers it.

**Resolution:** Item #3 is preserved under Option B: every review-worthy edit
still gets an independent read — landed-content edits via the coder's reviewer,
new entries via the user's governance approval, rule edits via the coder cycle.
The new rule text's closing sentences ("a NEW-ENTRY author rides on the user's
own governance review …; the moment an edit instead touches ALREADY-LANDED
content substantively … it is MAJOR and the independent reviewer applies via the
coder cycle") carry this split.

**Required lock-step edit to item #3 (memory cache, §3.6).** Item #3 currently
says a Pack-Chat-direct trinity/README/BACKLOG edit "gets an INDEPENDENT
reviewer." Under BD-208 (Option B) this must be reconciled in the SAME
memory-cache upkeep step (§3.6) to read: "a substantive Pack-Chat edit of
ALREADY-LANDED content (re-scope / multi-field rewrite / structural rewrite) +
any rule edit does not happen direct — it routes to a coder whose IMPL-REPORT
the reviewer reads; a NEW-ENTRY author (BD-open / version-boundary CHANGELOG)
stays Pack-Chat-direct with the USER's governance approval as the independent
read; a bookkeeping-token edit gets the sanity pass — per
`pack-chat-minor-edits-only`." This is Pack-Chat out-of-repo upkeep (trinity-
wins; no validator gate) — flagged for Pack Chat, NOT a coder deliverable.
**Surfaced, not silently fixed.**

### 4.4 `bounded-review-fix-cycle` — COMPOSES (the cycle is the destination)

The new rule routes every MAJOR edit "under the bounded review/fix cycle" — it
FEEDS the bounded cycle, never bypasses or extends it (still max 2 review/fix
pairs + 1 final = 3 reviewer / 2 fix-coder per commit; architect escalation if
dirty). No change to the cycle's bound. The rejected-alternative in §3.2
explicitly chose "route major edits through the coder that already produces the
reviewable artifact" precisely to compose with this rule rather than bolt a
second review path onto Pack Chat. No contradiction.

### 4.5 `feedback_pack_chat_boundaries` — CONSISTENT (item #2 carve-out preserved)

Boundaries item #2 ("Pack Chat does NO fixes") already carries the exception:
"Pack Chat MAY edit memory files (its own state) and PM-only files (…) — those
are PM-only by construction, not 'fixes.'" BD-208 NARROWS that PM-only exception
from any-depth to (bookkeeping tokens + NEW-entry authoring) only, and moves
substantive edits of already-landed content + rule edits to the coder.

**Resolution:** This is a TIGHTENING of an existing carve-out, fully consistent
with boundaries' intent (Pack Chat does less hands-on editing, routes more to
the owning agent — the boundaries doc's whole thesis: "Identify which agent owns
the work. Spawn that agent."). BD-208 makes boundaries MORE true. The
boundaries memory-cache file should get the same reconciliation note in §3.6
(narrow the PM-only exception to bookkeeping + new-entry authoring; substantive
landed-content edits route to coder) — surfaced for Pack-Chat upkeep, not a
coder deliverable.

### 4.6 No unresolved contradictions

Every rule the new rule touches (`no-fixes`, PM-only off-limits clause,
`review-cycle-position-checkpoint` #3, `bounded-review-fix-cycle`,
`pack-chat-boundaries`) either COMPOSES or is a documented TIGHTENING. Two
out-of-repo memory-cache files (item #3 and `pack-chat-boundaries`) need
reconciliation notes — surfaced in §4.3 / §4.5 / §3.6 as Pack-Chat upkeep, NOT
silently changed and NOT in the coder's repo scope.

---

## 5. ENCODING SURFACES (validators / tests / CI — lock-step)

Per `enumerate-encoding-surfaces`: every surface that ENCODES the touched
rules' expected state, with the lock-step update.

| Surface | Encodes | Lock-step update | Breaks if skipped? |
|---|---|---|---|
| `scripts/validate-pack.py` Check 45 (bijection) | corpus `[rationale: slug]` set == rationale `## <slug>` set | NONE to the check; the new slug + new rationale section make the sets N+1 on both sides → still equal. Parametric. | YES if rationale section omitted (orphan corpus slug) — guarded by same-commit step-1+step-2 landing. |
| `scripts/validate-pack.py` Check 46 (anti-restate + ref-resolution) | reference surfaces resolve to canonical home; no ≥60-char body restatement | NONE to the check; the new manifest record + the NAME-only reference lines (§3.3/§3.4) resolve and stay under the 60-char body threshold. | YES if a reference line verbatim-copies ≥60 chars of the corpus body — §3.3/§3.4 deliberately paraphrase. |
| `scripts/validate-pack.py` Check 18 (trinity H2 parity) | H2 STRUCTURE parity across trinity | NONE — the new rule is a BULLET inside the existing `### Pack Chat scope` H2; adds no new H2; identical in all three files. | No (bullet text not gated; H2 unchanged). |
| `scripts/tests/test-validate-pack-check-45.sh` | Check 45 behavior (synthetic trees) | NONE — parametric (synthetic balanced/orphan trees, not the live slug set). Re-run to confirm green; no edit. | No. |
| `scripts/tests/test-validate-pack-check-46.sh` | Check 46 behavior + Group 2 end-to-end on HEAD | NONE to the test; Group 2 runs validate-pack on HEAD and must stay clean — satisfied once §3.1–3.5 land consistently. Re-run to confirm. | Group 2 FAILS if the live manifest/refs are inconsistent — covered by landing §3.3/3.4/3.5 together. |
| `pack-ops/.spawn-rule-manifest.txt` | spawn-rule slug → canonical + reference surfaces | ADD the §3.5 record (lock-step with §3.3/3.4 reference lines). | YES — Check 46 ref-resolution fails if a reference surface is named but the manifest omits it, or vice versa. |
| `pack-ops/PACK-MEMORY-RATIONALE.md` | rule rationale bodies (bijection partner) | ADD §3.2 section. | YES — Check 45 orphan-corpus-slug fail. |
| `test-fixtures/manifest.txt` | fixture SHAs for v11-surface files | REGEN (§3.7) if diff non-empty. | YES — `fixture manifest verify` CI gate (RELEASE-GATE item 5) fails on stale manifest. |
| `pack-ops/PACK-CHAT.md` § "Rule-change propagation procedure" table | the ordered propagation surfaces | NONE — the procedure is generic (corpus/rationale/refs/manifest); this BD is an instance, adds no new surface TYPE. | No. |

**Measure-then-bound note (ci-guard-measure-then-bound).** BD-208 designs NO
new CI guard/allowlist — it adds one corpus rule + one rationale section + one
manifest record to EXISTING parametric checks (45/46). The "allowlist" analogue
is the bijection slug-set, which is auto-sized (set-equality), so no manual
allowlist sizing is needed. Measurement done: 21 existing corpus slugs (E-3);
new slug `pack-chat-minor-edits-only` is unique; sets stay equal at N+1.

---

## 6. Empirical-Evidence Block

### State-claim E-1: "The small PM-only set in D1 is byte-identical to the existing PACK-AGENTS.md PM-only files+dirs list."
- **Command:** `Read pack-ops/PACK-AGENTS.md` L130–159 (this session).
- **Output (verbatim, abridged to the list):** Files: `BACKLOG.md`,
  `CHANGELOG.md`, `README.md` version table, `PACK-CHAT.md`, `PACK-AGENTS.md`,
  `CLAUDE.md / AGENTS.md / GEMINI.md (root and project-template/)`,
  `PACK-MEMORY-RATIONALE.md`. Directories: `/backlog/`, `/changelog/`,
  `project-template/docs/project/backlog/`, `.../implementation-plan/`,
  `.../changelog/`. Plus the scope-in clause L157–159.
- **HEAD:** `a630a312`; **Date:** 2026-06-04.
- **Interpretation:** D1's set == PACK-AGENTS.md list verbatim.
- **Conclusion:** SUPPORTED.

### State-claim E-2: "Check 46 anti-restate scans imperative BODY (≥60 chars), not the rule NAME — so a NAME+slug reference line cannot false-positive."
- **Command:** `Read scripts/validate-pack.py` L6603–6705 (Check 46 helpers).
- **Output (verbatim):** `_CHECK_46_ANTI_RESTATE_MIN_LEN = 60`; helper
  `_check_46_extract_pack_memory_imperative_bodies` takes "the BODY (everything
  after the bold name)… The NAME is deliberately excluded so a one-line
  reference that names the rule cannot match (SC7 bound)."
- **HEAD:** `a630a312`; **Date:** 2026-06-04.
- **Interpretation:** §3.3/§3.4 reference lines NAME the rule + slug and
  paraphrase (no ≥60-char verbatim body slice) → anti-restate-safe.
- **Conclusion:** SUPPORTED.

### State-claim E-3: "There are 21 corpus rationale slugs at HEAD; the new slug `pack-chat-minor-edits-only` is unique."
- **Command:** `grep -oE '\[rationale: [a-z0-9-]+\]' CLAUDE.md | sort -u` (count 21);
  `grep '^## ' pack-ops/PACK-MEMORY-RATIONALE.md` (23 `## ` headers, 2 of which
  are non-slug format examples `## Rules-Applied Verification` / `## Empirical-
  Evidence Block` excluded by Check 45's `^##\s+([a-z0-9][a-z0-9-]*)\s*$` regex
  → 21 slug headers).
- **Output (verbatim, slugs):** agents-never-commit, architect-doc-reality-
  reconciliation, boundary-investigation-precedes-pack-defaults,
  bounded-review-fix-cycle, ci-guard-measure-then-bound,
  cross-cli-reference-normalization, deferral-is-scope-creep,
  deferred-work-tracked-anchor, dependency-direction-placement,
  empirical-evidence-blocks, enumerate-encoding-surfaces, enumerate-rules-inline,
  filename-uniqueness-heuristic, no-deferral-without-user-direction,
  pack-repo-code-comment-deferrals, pack-side-project-concepts-deliverable-only,
  per-action-approval-sub-agents, preflight-stop-means-stop,
  regenerate-manifest-v11-surface, rules-applied-verification-block,
  skill-agent-maintenance-mechanical. (`pack-chat-minor-edits-only` not present.)
- **HEAD:** `a630a312`; **Date:** 2026-06-04.
- **Interpretation:** 21 slugs both sides (bijection holds today); new slug is
  unique → adding it keeps N+1 set-equality.
- **Conclusion:** SUPPORTED.

### State-claim E-4: "The 'What Pack Chat CAN edit directly' insertion anchor (the final 'may NOT edit …pack-coder' sub-bullet) and the following bullet are byte-identical across CLAUDE/AGENTS/GEMINI.md."
- **Command:** `grep -n 'PM-only IS Pack-Chat-direct'` + `Read` of L372–397
  (CLAUDE), L334–350 (AGENTS), L301–316 (GEMINI).
- **Output (verbatim):** All three end the bullet with `- Pack Chat may NOT edit
  project-template / supporting-docs / maintenance-docs / scripts / fixtures /
  agent definitions — those go to pack-coder.` followed by `- **Commit-approval
  requests include next-steps plan.**`. The MIDDLE sub-bullet differs per CLI
  (Memory files / Codex no-cache / Gemini no-cache).
- **HEAD:** `a630a312`; **Date:** 2026-06-04.
- **Interpretation:** The insert anchor + following bullet are identical → same
  3× insertion, no per-CLI variation in the new bullet.
- **Conclusion:** SUPPORTED.

### State-claim E-5: "test-45 and test-46 are parametric (do not hardcode the live slug set / manifest record count), so adding a slug+section+record does not require editing them."
- **Command:** `grep -nE 'slug|count|...' scripts/tests/test-validate-pack-check-45.sh`
  + `...check-46.sh`.
- **Output (verbatim, abridged):** test-45 builds synthetic `claude`/`rationale`
  via `run_check_with_synthetic` (balanced 2==2, orphan, both-direction); no
  live-slug assertion. test-46 builds synthetic trees via `build_tree(…,
  boundary_records, spawn_records, surfaces…)`; Group 2 runs validate-pack on
  HEAD for clean-exit.
- **HEAD:** `a630a312`; **Date:** 2026-06-04.
- **Interpretation:** No hardcoded live count/slug → no test edit; only re-run
  to confirm green (test-46 Group 2 requires the live §3.x edits be consistent).
- **Conclusion:** SUPPORTED.

### State-claim E-6: "PACK-AGENTS.md + PACK-CHAT.md + PACK-MEMORY-RATIONALE.md + .spawn-rule-manifest.txt are under pack-ops/ → the commit is v11-surface → manifest regen required."
- **Command:** `ls pack-ops/PACK-AGENTS.md pack-ops/PACK-CHAT.md
  pack-ops/PACK-MEMORY-RATIONALE.md pack-ops/.spawn-rule-manifest.txt`.
- **Output:** all four exist under `pack-ops/`.
- **HEAD:** `a630a312`; **Date:** 2026-06-04.
- **Interpretation:** `regenerate-manifest-v11-surface` trigger fires (pack-ops/
  is one of the four trigger dirs).
- **Conclusion:** SUPPORTED.

---

## 7. Edit summary for the planner (one commit, atomic)

All in ONE commit (so Check 45 bijection + Check 46 never see a half-applied
state), `pack-only` scope (no `project-template/` or `supporting-docs/` paths):

1. `CLAUDE.md` — insert §1 rule bullet (§3.1 anchor).
2. `AGENTS.md` — insert §1 rule bullet (same anchor, §3.1).
3. `GEMINI.md` — insert §1 rule bullet (same anchor, §3.1).
4. `pack-ops/PACK-MEMORY-RATIONALE.md` — append §3.2 `## pack-chat-minor-edits-only`.
5. `pack-ops/PACK-AGENTS.md` — insert §3.3 reference line after scope-in clause.
6. `pack-ops/PACK-CHAT.md` — insert §3.4(a) Behavioral-rules reference bullet + §3.4(b) two Role-section in-place replacements.
7. `pack-ops/.spawn-rule-manifest.txt` — append §3.5 record.
8. `test-fixtures/manifest.txt` — regen (§3.7) if diff non-empty.

Pack-Chat upkeep (NOT in the coder commit — out-of-repo memory cache, §3.6 +
§4.3 + §4.5): add `feedback_pack_chat_minor_edits_only.md`; reconcile item #3 of
`review_cycle_position_checkpoint` + item #2 of `pack_chat_boundaries`.

**Verification gate (coder PREFLIGHT):** `python3 scripts/validate-pack.py`
(Checks 18/45/46 + Check 43 leak-sweep) PASS; `bash
scripts/tests/test-validate-pack-check-45.sh` + `...check-46.sh` PASS;
manifest regen + stage.

## 8. Out-of-scope issues surfaced (NOT fixed here)

- **OOS-1 (memory-cache reconciliation).** `review_cycle_position_checkpoint`
  item #3 and `pack_chat_boundaries` item #2 (out-of-repo memory files) need
  wording reconciliation under BD-208. Surfaced in §4.3/§4.5/§3.6 as Pack-Chat
  upkeep (trinity-wins; no validator gate). NOT a coder repo deliverable —
  flagged for Pack Chat to apply during memory upkeep.
- **OOS-2 (PACK-CHAT.md Role-section staleness, in-scope-adjacent).** The Role
  section's "Write files directly… execute pack changes directly" framing
  (L13/L21) predates BD-208 and reads as any-depth direct write. §3.4(b) folds
  the minimal reconciliation into THIS BD's commit (it is the same rule's
  surface) rather than deferring — per `deferral-is-scope-creep` (no SIZE/
  BLOCKED/FIT defense for splitting it out). Named so the planner sees it is
  intentional in-scope, not creep.
- **OOS-3 (Option-B coherence flag — user decision point).** The raw
  "new-entry-author = MINOR / existing-entry-edit = MAJOR" framing opens a
  delete-and-reauthor loophole (§2.2). This design closes it with the ID-history
  test (new-ID = MINOR; any edit touching a landed ID, including delete+readd, =
  MAJOR), which is the cleanest closure consistent with the user's intent. SURFACED
  per the user's instruction ("flag any genuine incoherence"); the user noted
  "Option B is fine until I see any problems that cause me to change my mind." If
  the user prefers a different closure (e.g. classify by edit SIZE, or send all
  CHANGELOG/BD authoring to coder), this is the decision point. NOT silently fixed.

No other out-of-scope issues observed. The new rule does not re-litigate WHICH
files are PM-only (D1 is user-confirmed) and does not touch the per-BD
application to 203/204/206/207 (already authorized).

---

## Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| read-in-full + NO-DERIVATION | All named docs Read DIRECTLY this session (see READ-IN-FULL proof row below): BD-208 entry (BACKLOG L3418–3439); CLAUDE.md `## Pack memory` (L130–539); PACK-AGENTS.md (1–226 full); PACK-CHAT.md (1–310 full); PACK-MEMORY-RATIONALE.md (1–566 full); 8 memory files full. No content derived — every claim cites a direct Read or a `grep`/`Read` command run this session. | COMPLIANT |
| empirical-evidence-blocks | §6 carries E-1…E-6, each with command + verbatim output + HEAD `a630a312` + date 2026-06-04 + interpretation + SUPPORTED. Every state-claim in §1–§5 (small-set==PM-only list; anti-restate body-scan; 21 slugs; byte-identical anchors; parametric tests; v11-surface) is backed by an E-block. | COMPLIANT |
| preliminary-triage-architect-challenge | §0.1 CHALLENGE-1 + CHALLENGE-2 raised/resolved; AMENDMENT: the user's Option-B decision was applied within (not silently re-decided), and the genuine new-vs-landed coherence loophole was SURFACED (§2.2 + §8 OOS-3) with a proposed ID-history closure flagged as a user decision point — not silently fixed. | COMPLIANT |
| edit-in-place-not-full-rewrite | Every propagation edit (§3.1–§3.5) specified as a TARGETED insert/replacement with exact byte-quoted anchor text; no full-file rewrite proposed. Rationale + manifest are APPENDS to ordered-list files. | COMPLIANT |
| enumerate-encoding-surfaces | §5 table enumerates Check 45/46/18, test-45, test-46, spawn-rule-manifest, RATIONALE.md, manifest.txt, propagation-procedure table — each with lock-step update + breaks-if-skipped. | COMPLIANT |
| scope-deliverables-to-the-ask | AMENDMENT edits IN PLACE only (§1/§2/§2.1/§2.2/§4.3 + consequential §3.2/§3.4/§4.5/§8); §3 propagation surfaces, §5 encoding, §6 EE-blocks, §7 summary kept intact except where the boundary change forced a follow-on edit (each named). No whole-doc rewrite; no edge-case sprawl beyond the user's four required dispositions (#7 re-scope, multi-field, #2 flip+rationale, BD-203 B0 structural). | COMPLIANT |
| rules-applied-verification-block | This block (per-rule evidence + conclusion) + the READ-IN-FULL proof row below; no empty-evidence rows; no AMBIGUOUS. | COMPLIANT |
| AMENDMENT re-verification (Option B) | Re-grep after edits: `grep -c 'pack-chat-minor-edits-only'` across CLAUDE/AGENTS/GEMINI live files = 0 (slug still unique, not yet landed — design-only); doc anchors for §1/§2/§4.3 all matched exactly-once on apply (assert n==1 each). The Option-B boundary change touches NO state-claim in E-1…E-6 (file-set identity, anti-restate body-scan, slug count, parity anchors, parametric tests, v11-surface are all independent of the minor/major line) — EE-block stays SUPPORTED unchanged. | COMPLIANT |

### READ-IN-FULL proof (direct-read evidence per file)

| Doc | Direct-read proof (first line / last line or range) |
|---|---|
| BD-208 entry (`pack-ops/BACKLOG.md`) | Read L3418–3537; first: `---` (L3418) → `**BD-208 — Pack Chat editing-scope rule…**` (L3420); last BD-208 line `Position: pack-self governance; parallel with BD-203…` (L3439). |
| `CLAUDE.md` `## Pack memory` | Read L130–539; first `## Pack memory (project-local learnings)` (L136); last `### Project goals (v11)` …`OT itself is read-only for` (L539). 21 `[rationale:]` slugs grepped. |
| `pack-ops/PACK-AGENTS.md` | Read L1–226 (full; file is 226 lines). first `# PACK-AGENTS.md — AI Agent Config Pack (Pack Repo)` (L1); last `Always run \`git add -A && git status\`…` (L226). PM-only list L130–159 captured. |
| `pack-ops/PACK-CHAT.md` | Read L1–310 (full; file is 309+1 lines). first `# PACK-CHAT.md — Pack Chat Startup and Operating Instructions` (L1); last propagation-procedure note `…not a hard-enforced step sequence.` (L309). |
| `pack-ops/PACK-MEMORY-RATIONALE.md` | Read L1–566 (full; file is 565+1). first `# PACK-MEMORY-RATIONALE.md — rationale bodies…` (L1); last `…growth is a deliberate, sign-off-gated constant edit, never an incidental map add.` (L566). 23 `## ` headers (21 slug + 2 format-example) grepped. |
| `feedback_pack_chat_boundaries.md` | Read full; first frontmatter `name: pack-chat-boundaries`; last `…Spawn (or SendMessage) that agent. Surface results to the user.` |
| `feedback_review_cycle_position_checkpoint.md` | Read full; first `name: review-cycle-position-checkpoint`; last cross-ref `…(Pack Chat does no fixes / never reviews coder output).` Item #3 (Pack-Chat-direct = implementation needing independent reviewer) captured. |
| `feedback_review_fix_cycle.md` | Read full; first `name: review-fix-cycle`; last `Cross-refs: [[pack-chat-boundaries]]… [[agent-prompt-enumerates-rules]]…`. |
| `feedback_edit_in_place_not_full_rewrite.md` | Read full; first `name: edit-in-place-not-full-rewrite`; last `…[[feedback_pack_chat_no_coder_review]] (independent verification).` |
| `feedback_preliminary_triage_architect_challenge.md` | Read full; first `name: preliminary-triage-architect-challenge-discipline`; last `Cross-refs: [[feedback-user-prescriptive-authority]]…[[pack-chat-boundaries]]…`. |
| `feedback_architect_planner_empirical_evidence.md` | Read full; first `name: architect-planner-empirical-evidence`; last `Related: [[agent-output-rules-applied-block]], [[ci-guard-design-measure-then-bound]].` |
| `feedback_agent_output_rules_applied_block.md` | Read full; first `name: agent-output-rules-applied-block`; last `Related: [[agent-prompt-enumerates-rules]], [[architect-planner-empirical-evidence]].` |
| `feedback_scope_deliverables_to_the_ask.md` | Read full; first `name: scope-deliverables-to-the-ask-no-noise`; last `…the user's standing preference for terse, exactly-scoped work.` |
