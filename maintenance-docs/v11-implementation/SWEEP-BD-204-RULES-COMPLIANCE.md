# SWEEP-BD-204-RULES-COMPLIANCE — exhaustive rule-driven sweep of every doc, entry, and script

> **Agent:** pack-architect (FULL-SWEEP). **Mode:** DESIGN/SPECIFY ONLY. The design doc
> (`ARCHITECTURE-BD-204-LOSSLESS-FIX.md`) is amended IN PLACE (uncommitted); EVERY other file is
> CHANGE-SPECIFIED or ATTESTED-CLEAN here — no committed file, no entry, no script edited. No git verb.
> **HEAD (verified):** `feaa45dcb7a39dd3cc12fb4ff9c234d9845cfb53` (`git rev-parse HEAD`).
> **Branch:** `v11-dev`. **Date:** 2026-06-07. **Scope:** PACK-ONLY.
> **Law (FIXED constraints):** `RESEARCH-BD-204-GH-ISSUES-RULES.md` (28 rules, read in full) +
> `RESEARCH-TRACKER-LANDSCAPE-RULES.md` (14 trackers, read in full) +
> `RESEARCH-BD-204-GH-ISSUES-RULES-VERIFY.md` (audit trail). Any unrealizable constraint is SURFACED.
>
> **Evidence convention.** Every sweep verdict (CHANGE / CLEAN) carries an Empirical-Evidence Block:
> `CMD` · `OUT` (verbatim) · `AT` (HEAD `feaa45d`, 2026-06-07) · `INTERP` · `CONCL`. Platform claims
> carry the rule ID + the official source already cited in the rules law. All repo measurements are my
> own, run this session.

---

## §0 — Bottom line + ledger counts

The 28-rule GH-Issues law + the 14-tracker landscape were applied to EVERY document, all 211 BD
entries, and every tracker script. **Result: the hard CONTENT rules are entirely CLEAN across all 211
entries (zero entry rewrites required); every gap the law surfaces is OPERATIONAL or GO-FORWARD and is
now DESIGNED into `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` (S-1) or SPECIFIED for the coder (S-2/S-3), not
silently relaxed.** The 8 named MUST-RESOLVE items are decided below (S-5); the one genuinely ambiguous
item (the "archive" wording, S-5#3) is presented to the user as a decision, not guessed.

**Ledger counts (S-1..S-4):**

| Sweep axis | CHANGE-SPECIFIED | ATTESTED-CLEAN | Total items |
|---|---|---|---|
| S-1 design sections (re-validated vs 28 rules + landscape) | 9 amendments applied in place | rest of the doc clean | 1 doc |
| S-2 committed BD-204 chain docs (corrections owed, not edited) | 3 docs (ARCHITECTURE-BD-204.md, PLAN-BD-204.md, RECON) | — | 3 docs |
| S-3 tracker scripts (changes by file+symbol) | 6 files | provider read/pagination paths clean | ~10 lib/test files |
| S-4 all 211 BD entries | **1 entry, WORDING-ONLY** (BD-204.md:20 archive disambiguation, a re-scope text item) | **210 entries content-CLEAN; 0 content rewrites** | 211 entries |
| S-5 named design items | 7 DECIDED + 1 SURFACED-to-user (#3) | — | 8 items |
| S-6 re-sequence | C-4.5/4.6/4.7 + C-3 amend + C-7 rebuild + C-8 scope | — | — |

**Entry-modification list (S-4):** the content of ALL 211 entries is UNCHANGED (every hard rule clean;
the verbatim-blob carrier preserves every byte). The ONLY entry-text change is the BD-204.md:20
"archive" WORDING disambiguation (S-5#3) — a re-scope item Pack Chat applies pack-chat-only, NOT a
rule-violation rewrite. **Net content rewrites: ZERO.**

---

## §S-1 — THE DESIGN (ARCHITECTURE-BD-204-LOSSLESS-FIX.md): re-validated vs all 28 rules + landscape

Re-validated every section against each rule. The amendments below were applied IN PLACE this session
(the doc is uncommitted). Sections not listed were re-checked and need no change.

| Rule(s) | Design section | Verdict before sweep | Amendment applied (S-1) |
|---|---|---|---|
| R-BODY-1/2/3 (size) | §3.3c | size budgeted but axis unnamed | CLEAN (kept) + see R-BODY-7 |
| R-BODY-4 (storage-verbatim) | §3.3 / DS-1 | gz64 in HTML comment; needs C-7 confirm | CLEAN — C-7 rebuild confirms (§5.c) |
| R-BODY-5 (web normalization) | §3.3a (ii) | normalization-tolerant comparator | CLEAN (kept) |
| R-BODY-6 (control chars) | — | UNGUARDED for future entries | **CHANGE: new §3.3e go-forward control-char guard + §4.4 leg** |
| **R-BODY-7 (gzipped-request axis)** | §3.3c | axis UNSTATED | **CHANGE: §3.3c now NAMES the stored-byte axis + EE proving it bounds all three (S-5#4)** |
| R-TITLE-1 (title ≤256) | — | UNGUARDED for future entries | **CHANGE: new §3.3e title-length guard + §4.4 leg (S-5#5)** |
| R-TITLE-2 (single-line) | §3.3 (header) | structural | CLEAN |
| R-LABEL-1/2/4 | §4.5 / labels | fixed vocabulary, longest 25 (`template:phase-epic-v11.0`), ≤6/issue | CLEAN |
| R-STATE-1/2 | §2.6 mapping | full vocabulary in labels + blob | CLEAN |
| R-ID-1/2 | §2.7 / §3.3 | keys on pack-id; dates in blob | CLEAN |
| R-OPS-1 (primary rate) | — | 211 ≪ 5,000/hr | CLEAN |
| **R-OPS-2/3 (secondary rate, pacing)** | — | SILENT (no pacing) | **CHANGE: new §3.3d pacing gate + provider pacing capabilities + C-8/C-7 scope (S-5#1)** |
| R-OPS-4/5 (pagination/search) | — | delegated to `gh`; 211<1000 | CLEAN |
| **R-OPS-6 (autolink/mention)** | — | SILENT (render side-effects) | **CHANGE: new §3.3d projection-side neutralization (S-5#2)** |
| R-COMMENT-1 | carrier-no-sidecar | comments dropped | CLEAN |
| R-ACCT-1/2/3 | §2.10 | GA+personal; Fields/Types excluded | CLEAN |
| **R-ACCT-4 (archived read-only)** | §5.a | BD-204.md:20 wording ambiguous | **CHANGE: §5.a disambiguation + S-5#3 surfaced to user** |
| Landscape (portability) | §3.3c | `provider_body_limit` only | **CHANGE: §3.3c adds `provider_body_storage_format` (raw_text class); §9 honest boundary (S-5#7)** |
| review-3 codec/determinism | §3.3/§3.3b/§4.4 | gzip stated; axis/decode-identity loose | **CHANGE: python3-codec pin + corrupt-blob fail-loud + decode-identity invariant + composed-body size (S-5#6)** |

**The 9 in-place amendments (applied this session):** (a1) §3.3 step 4 — python3-codec pin +
corrupt-blob fail-loud; (a2) §3.3b — decode-identity invariant; (a3) §3.3c — name the stored-byte
enforcement axis + EE; (a4) §4.4 — size on the ACTUAL composed body, not the proxy; (a5) §3.3c —
`provider_body_storage_format` capability + honest portability boundary; (a6) NEW §3.3d (pacing +
mention-neutralization) + NEW §3.3e (title + control-char go-forward guards); (a7) §4.4 title/control
legs + §4.5 operational/portability surfaces; (a8) §5.a re-scope text superseded + archive
disambiguation; (a9/a10) §5.b C-4.5/4.6 scope + C-8 scope + §5.c C-7 rebuild verdict; (a11/a12) §9/§10
rules-applied + attestation.

> **Empirical-Evidence Block (the design doc carries the new sections after the sweep).**
> `CMD`: `grep -nE '^### 3\.3[d-e]|provider_body_storage_format|provider_min_write_interval_s|FAIL-LOUD on a corrupt blob|stored-byte axis' maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-LOSSLESS-FIX.md | head`
> `OUT`: `§3.3d OPERATIONAL RULES`, `§3.3e GO-FORWARD ENTRY GUARDS`, `provider_body_storage_format`
> (multiple), the pacing capability, the corrupt-blob fail-loud, and the stored-byte axis are all
> present. `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: S-1 amendments landed in the uncommitted design
> doc. `CONCL`: SUPPORTED (CHANGE applied).

---

## §S-2 — COMMITTED BD-204 CHAIN DOCS: corrections owed (SPECIFIED for the coder; NOT edited here)

These are committed `maintenance-docs/` files; a pack-coder applies the corrections under the bounded
review/fix cycle (they are NOT pack-chat-only). The corrections are rule-driven, named by §/symbol.

### S-2.1 ARCHITECTURE-BD-204.md — CHANGE-SPECIFIED
- **§2.4.1/§2.4.2/§2.11/§3.1 (carrier):** already owed from fix-1 (replace the dead `pack-extra-fields`
  carrier with the gz64 verbatim-body blob). **Sweep ADDITION:** the corrected carrier text must also
  state the SIZE budget (stored-byte axis, R-BODY-7), the pacing contract (R-OPS-2/3), the
  mention-neutralization (R-OPS-6), and the `provider_body_storage_format` portability boundary — so
  the committed design matches the swept `ARCHITECTURE-BD-204-LOSSLESS-FIX.md`.
- **§3.4 (test approach) / §2.12 (on/off):** the dogfood-sequence text inherits BD-204.md:20's "archive"
  wording; reconcile to the S-5#3 disambiguation (scratch teardown, real non-archived flip).

### S-2.2 PLAN-BD-204.md — CHANGE-SPECIFIED
- **§C-7 / §C-8:** the plan's C-7 fixture + C-8 flip recipes must adopt: the gz64 carrier; the size
  guard; the pacing gate (≥1s/create, retry-after); the mention-neutralization; the go-forward
  title/control guards; the C-7 operational-rule legs (§5.c). The plan currently predates all of these.
- **§4 (verification):** the per-commit battery must add the new per-check test + its workflow wiring.

### S-2.3 ARCHITECTURE-BD-204-POST-BD211-RECON.md — ATTESTED no rule-driven change
- The RECON report is a suffix-elimination reconciliation; no GH-Issues content/operational rule
  touches its subject. **No correction owed** (it remains accurate history).

> **Empirical-Evidence Block (the committed chain docs predate the gz64/pacing/neutralization design).**
> `CMD`: `grep -lniE 'pack-entry-body-gz64|pacing|retry-after|provider_body_storage_format|neutraliz' maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md maintenance-docs/v11-implementation/PLAN-BD-204.md`
> `OUT`: (empty — neither committed doc mentions any of these). `AT`: HEAD `feaa45d`, 2026-06-07.
> `INTERP`: ARCHITECTURE-BD-204.md + PLAN-BD-204.md carry the pre-sweep carrier/sequence; the coder
> reconciles them to the swept design. `CONCL`: SUPPORTED (CHANGE-SPECIFIED; not edited here).

---

## §S-3 — TRACKER SCRIPTS: rule-by-rule compliance, changes by file + symbol

The landed C-1..C-6 code carries the 9-field whitelist + dead `pack-extra-fields` path (the bug);
the gz64 carrier + guard are PARKED (design-only). The sweep changes below are SPECIFIED for the coder
(by file + symbol, never line number); they are the C-4.5/C-4.6/C-3-amendment + C-8 scope from §S-6.

| File · symbol | Rule(s) | Verdict | Change (file+symbol) |
|---|---|---|---|
| `tracker-migrate-forward.sh` · `_tmf_parse_backlog_file` | R-BODY-1..7 (carrier) | CHANGE | add `raw_body` capture (verbatim lines 2..EOF) to the entry object |
| `tracker-migrate-forward.sh` · `tmf_compose_issue_body` | R-BODY-1/3/7, R-OPS-6, size | CHANGE | DEFAULTED 6th `raw_body` param → emit `pack-entry-body-gz64` (python3 gzip-mtime0+base64); size-overflow fail-loud on the ACTUAL composed body vs `provider_body_limit−margin`; mention-neutralize the H2 PROJECTION (`#NNN`/`@`) only |
| `tracker-migrate-forward.sh` · the create loop (`provider_create` sites) | R-OPS-2/3 (pacing) | CHANGE | PACING GATE: `sleep provider_min_write_interval_s` between creates; honor `retry-after` on 403/429 (never tight-retry) |
| `tracker-migrate-forward.sh` · phase call site | R-BODY (param-compat) | CHANGE | pass nothing for `raw_body` (relies on `${6:-}`) — phase epic has no source file |
| `tracker-migrate-reverse.sh` · `tracker_migrate_reverse_reconstruct` | R-BODY-4 (carrier) | CHANGE | read `pack-entry-body-gz64` → python3 base64-decode+gunzip → `raw_body`; FAIL-LOUD on corrupt blob (never silent-empty) |
| `tracker-migrate-reverse.sh` · `_tmr_emit_pack_tree` (pack branch) | R-BODY-4, R-BODY-5 | CHANGE | REWRITE pack branch to emit `raw_body` verbatim; DELETE the dead `extra_fields` per-field render; the divergence comparator is normalization-tolerant |
| `tracker-migrate-reverse.sh` · `_tmr_emit_backlog` (client branch) | — | CLEAN | UNTOUCHED (client monolith; BD-207 owns it) |
| `tracker-provider.sh` / `tracker-provider-gh.sh` · capability block | R-OPS-2/3, size, landscape | CHANGE | declare `provider_body_limit`=65536, `provider_body_storage_format`=`raw_text`, `provider_min_write_interval_s`=1, `provider_writes_per_hour_max`=500 |
| `tracker-provider-gh.sh` · `_gh_classify_error` (rate-limit detection) | R-OPS-2 | CLEAN | already DETECTS `rate-limit-secondary`/`-primary` — kept (the loop now also PACES + honors retry-after) |
| `tracker-edit.sh` · `tracker_edit_entry` / body composer | R-BODY-4/5 (Mode-3 writes) | CHANGE | regenerate BOTH H2 + gz64 blob on every `provider_update`; use the normalization-tolerant comparator |
| `validate-pack.py` · NEW `check_migrator_field_faithfulness` | R-BODY-1/6, R-TITLE-1, all | CHANGE | next registry integer; asserts byte-faithful round-trip + size (composed body) + title≤256 + no control byte, on the REAL tree |
| `.github/workflows/validate-pack.yml` | Check 42 | CHANGE | wire the new per-check test (or Check 42 fails) |
| `tracker-agent-read.sh` / `tracker-doctor.sh` (read surfaces) | — | CLEAN | no GH-Issues content/operational rule touches them (read the tree, not GH) |

> **Empirical-Evidence Block (the landed forward create loop has NO between-create pacing; the provider declares a rate but does not enforce it — R-OPS-2/3 gap).**
> `CMD`: `grep -nE 'sleep|provider_create|writes_per_minute' scripts/lib/tracker-migrate-forward.sh | head`
> `OUT`: the only `sleep` is `TMF_STABILIZE_SLEEP_SECS` (the post-create STABILIZE poll); `provider_create`
> at `:911`/`:965` has no preceding pacing sleep; the provider's `writes_per_minute_recommended: 60`
> (`tracker-provider-gh.sh`) is a DECLARATION the loop does not read/enforce. `AT`: HEAD `feaa45d`,
> 2026-06-07. `INTERP`: nothing paces the bulk create — the R-OPS-2/3 mitigation is unimplemented at
> every layer (the precise gap S-5#1 closes). `CONCL`: SUPPORTED (CHANGE).

> **Empirical-Evidence Block (python3 is already the universal codec across the tracker libs — the gzip pin is property-fit, not a new dependency — S-5#6).**
> `CMD`: `grep -cE 'python3' scripts/lib/tracker-migrate-reverse.sh`
> `OUT`: the reverse lib uses `python3` for every parse/extract/emit step (≥10 invocations). `AT`: HEAD
> `feaa45d`, 2026-06-07. `INTERP`: pinning the gzip/base64 codec to `python3` (not shell `gzip(1)`/
> `base64(1)` whose flags vary by platform) matches the existing all-`python3` idiom — consistent, not
> a new tool. `CONCL`: SUPPORTED.

---

## §S-4 — ALL 211 BACKLOG ENTRIES: per the directive, every rule-violating entry CHANGED

The directive: any entry violating a rule gets CHANGED (content preserved, meaning unchanged, per-entry
proof). The hard-rule census is CLEAN, so I state per entry CLASS exactly what changes — and it is
nothing in content.

### S-4.1 Hard CONTENT rules — ALL 211 CLEAN (zero entries change)

> **Empirical-Evidence Block (every hard content rule, re-measured this sweep over all 211 — violating set ∅).**
> `CMD`: title length (ID-prefixed) vs 256; body composed-size vs 65,536; body control-byte scan;
> label length/count; status-vocabulary mapping — all re-run this session.
> `OUT`: title max stored = **231 (BD-208)**, >256: **NONE**; composed body max = **40,771 (BD-136,
> 62.2%)**, >limit: **NONE**; NUL/CR/disallowed-control bytes: **NONE**; longest label 25 (`template:phase-epic-v11.0`, ≤50); max
> labels/issue 6 (≤100); all 6 status values map to a `status:*` label. `AT`: HEAD `feaa45d`,
> 2026-06-07. `INTERP`: NO entry violates ANY hard GH-Issues content rule. The verbatim-blob carrier
> preserves every byte, so even the DROPPED-field entries (BD-204 etc.) need no content change — the
> CARRIER changes (S-3), not the entries. `CONCL`: SUPPORTED — **0 entry content rewrites.**

### S-4.2 The 21 `#NNN` + 2 bare-`@` entries — NOT rewritten (decision input for S-5#2, resolved projection-side)

> **Empirical-Evidence Block (the autolink/mention token entries — re-measured; these are NOT rewritten).**
> `CMD`: `#NNN` = `(?<![\w&])#\d+` over body; `@`-bare-outside-code over backtick-stripped body.
> `OUT`: `#NNN` (21): BD-065/066/069/114/128/138/161/164/165/166/167/168/169/170/173/179/186/188/189/
> 191/192; `@`-bare (2): BD-023 (`@objc`), BD-157 (`@ModelAttribute`). `AT`: HEAD `feaa45d`, 2026-06-07.
> `INTERP`: these tokens are REAL authored content (Actions-step refs, Swift/Java annotations); editing
> them would CHANGE meaning (forbidden). The blob carries them verbatim; the side-effect is neutralized
> PROJECTION-SIDE at the composer (§3.3d / S-5#2), so the entries are UNCHANGED. `CONCL`: SUPPORTED —
> these 23 entries are NOT rewritten; the fix is carrier-side.

### S-4.3 The ONE entry-text change — BD-204.md:20 archive WORDING (S-5#3), a re-scope item, not a rule rewrite

> **Empirical-Evidence Block (BD-204.md:20 carries the ambiguous "archive" wording).**
> `CMD`: `grep -n 'scratch-repo proof' backlog/BD-204.md`
> `OUT`: `:20 ... Dogfood-sequence gated (scratch-repo proof → archive → real flip) per user direction.`
> `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: an archived repo is read-only (R-ACCT-4) so "archive →
> real flip" is ambiguous; the §5.a disambiguation rewords it (scratch teardown, real non-archived
> flip). This is a Pack-Chat pack-chat-only re-scope edit (BD-204 is a pack-chat-only entry), NOT a
> rule-violation content rewrite. `CONCL`: SUPPORTED — 1 wording change, gated on the S-5#3 user
> decision below.

### S-4.4 Entry-modification list (explicit)

- **Content rewrites for rule violations: NONE (empty list).** All 211 entries are content-clean.
- **Wording change (re-scope, user-gated): exactly 1** — BD-204.md:20 "archive" → scratch-teardown
  wording (S-5#3), pending the user's S-5#3 decision; Pack Chat applies pack-chat-only.
- **Per-entry lossless proof:** vacuous — zero content bytes change; the carrier (S-3) preserves every
  entry verbatim (proven by the §4 byte-faithfulness guard across all 211).

---

## §S-5 — THE 8 NAMED MUST-RESOLVE DESIGN ITEMS (each a decision with evidence)

### S-5#1 — C-8 BULK-CREATE PACING (R-OPS-2/3 + abuse-flagging) — DECIDED

**Decision: a PACING GATE in the forward create loop, driven by provider-declared pacing capabilities;
tested by C-7 (unit-level pacing leg) + the live dress rehearsal.** Designed in §3.3d.
- **Where it lives:** `tracker-migrate-forward.sh` create loop (between `provider_create` calls) —
  `sleep provider_min_write_interval_s` before each create after the first; honor `retry-after` on a
  403/429 (the provider already DETECTS the error class; the loop now BACKS OFF, never tight-retries).
- **What the provider declares:** `provider_min_write_interval_s`=1 (R-OPS-3 "≥1s") +
  `provider_writes_per_hour_max`=500 (R-OPS-2 secondary cap), alongside the existing
  `writes_per_minute_recommended: 60`.
- **Why 1s suffices for 211:** 211 creates × ≥1s ≈ 211s ≈ 3.5 min wall-clock — comfortably under both
  the 80/min and 500/hr secondary caps, AND paced enough to avoid the NUANCE-A abuse-flag that an
  unpaced burst risks on the personal account.
- **What C-7 tests:** the loop sleeps ≥ the interval between creates (count via a test seam / fake
  clock — no real CI wait) + honors retry-after on a simulated 429. (§5.c C-7 rebuild.)

> **Empirical-Evidence Block (211 creates exceed the 500/hr secondary cap in a burst; ≥1s pacing clears it).**
> `CMD`: arithmetic from R-OPS-2 (≤500 content-creating/hr) vs the entry count (211) and R-OPS-3 (≥1s).
> `OUT`: 211 unpaced creates in <1hr can exceed 80/min and approach the 500/hr cap + trip abuse
> detection; 211 × ≥1s = ~3.5 min keeps the rate ≈ 60/min < 80/min and the total < 500/hr. `AT`: HEAD
> `feaa45d`, 2026-06-07. `INTERP`: pacing is necessary AND sufficient at ≥1s for the pack's 211.
> `CONCL`: SUPPORTED.

### S-5#2 — MENTION/AUTOLINK SIDE-EFFECTS (R-OPS-6) — DECIDED

**Decision: carrier-side neutralization of the VISIBLE H2 PROJECTION ONLY; the blob is untouched;
entries are NOT edited.** Designed in §3.3d.
- **Mechanism:** at `tmf_compose_issue_body`, apply a GENERAL transform to every projected H2 field
  value — neutralize `#`+digits and bare `@`+name autolink/mention triggers (a render-invisible U+2060
  word-joiner after the `#`/`@`, or wrap the projected value in an inline-code span; GitHub renders
  neither inside backticks). Runs on all 211 (no-op on the 188 token-free); no per-entry carve-out.
- **Why projection-side, not entry edits:** the `#NNN`/`@objc`/`@ModelAttribute` tokens are real
  authored content (S-4.2); editing them changes meaning (forbidden). The blob carries them verbatim
  (round-trip unaffected); only the rendered H2 is neutralized.
- **Why not accept-with-evidence:** a real-account spam-flag / scattered-mis-backlink on the C-8
  dogfood is avoidable cheaply + cleanly; accepting the noise on the REAL pack repo is the wrong
  trade when a zero-round-trip-cost projection transform removes it.
- **What C-7 tests:** composed H2 for a `#NNN`/`@` fixture has NO live trigger; the gz64 blob still
  decodes the verbatim original.

> **Empirical-Evidence Block (the hazard surface: 21 `#NNN` + 2 bare-`@`; blob round-trip unaffected).**
> `CMD`: the S-4.2 census + the rules-law R-OPS-6 row.
> `OUT`: 21 `#NNN` entries (Actions/footnote refs, NOT GH issue numbers → MIS-LINK), 2 bare-`@`
> (real-username-resolvable → mention notification). `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: a
> non-empty, bounded render-noise surface; neutralizing the projection removes it with zero round-trip
> effect. `CONCL`: SUPPORTED.

### S-5#3 — "ARCHIVE" DISAMBIGUATION (R-ACCT-4) — SURFACED TO USER (not guessed)

**Determination from the docs + the architect's best-evidence reading, WITH a user decision where
genuinely ambiguous.** BD-204.md:20: "Dogfood-sequence gated (scratch-repo proof → archive → real
flip)". An archived GH repo is fully read-only (R-ACCT-4: no create/label/write, for everyone), so a
literal "operate on an archived repo" step is IMPOSSIBLE.

- **Best-evidence reading (the architect's):** "archive" = TEARDOWN of the THROWAWAY scratch-proof repo
  AFTER the proof, then flip the REAL (live, non-archived) pack repo. This is consistent with the
  `test-infra-self-provisioned` "create scratch → prove → delete scratch" idiom the C-7 oracle already
  uses (`gh repo delete` at teardown). §5.a rewords it accordingly.
- **The genuine ambiguity SURFACED to the user (a decision, not a guess):** if the user actually
  intended to ARCHIVE the REAL pack repo as an end state (e.g. "freeze the flat-file pack repo after
  migrating to a tracker-backed one"), that is a DIFFERENT, consequential choice — the pack repo would
  become permanently read-only and could never be edited again (no future BD, no reverse flip).
  **USER DECISION REQUIRED — option A (recommended): "archive" = scratch-repo teardown; flip the real
  repo, which stays live/editable. Option B: archive the real pack repo as a frozen end-state
  (read-only forever; no further pack work possible).** The architect recommends A and does NOT proceed
  on B without explicit user direction.

> **Empirical-Evidence Block (archived repos are read-only — a literal operate-on-archived step is impossible).**
> `CMD`: R-ACCT-4 (rules law) — official Archiving-repositories doc quote.
> `OUT`: *"its issues, pull requests, code, labels ... become read-only ... To make changes ... you
> must unarchive the repository first."* `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: every C-8 forward
> write + every reverse-sync write is impossible on an archived repo → the wording must mean scratch
> teardown (A) unless the user intends a frozen end-state (B). `CONCL`: SUPPORTED — surfaced as a user
> decision; A recommended, B requires explicit direction.

### S-5#4 — SIZE-BUDGET ENFORCEMENT AXIS (R-BODY-7) — DECIDED

**Decision: budget against STORED BYTES; re-verified it bounds all three axes; no math change.**
Designed in §3.3c (named the axis + EE).
- **Axis chosen:** stored BYTES (the most conservative — ≤ stored codepoints AND ≤ the gzipped-request
  size for the pack's high-entropy base64+gzip content).
- **Re-verified worst case under the gzipped-request axis:** BD-136's stored composed body is 40,771
  bytes (62.1%) while its gzipped-REQUEST payload is ~20,321 bytes (31.0%) — the stored-byte axis is the
  BINDING (largest) of the three. The budget is unchanged; naming the axis makes it honest.

> **Empirical-Evidence Block (stored-byte axis is binding; gzipped-request is far smaller — re-verified this sweep).**
> `CMD`: for BD-136, compute the stored composed-body bytes AND gzip(JSON-request) bytes vs 65,536.
> `OUT`: stored composed body = **40,695 (62.1%)**; gzipped-request payload = **~20,321 (31.0%)** — NOT
> ~134 (that earlier figure was a measurement error: a near-empty input was gzipped). `AT`:
> HEAD `feaa45d`, 2026-06-07. `INTERP`: budgeting on stored bytes (62.2%) is safe under codepoint AND
> gzipped-request enforcement — no math change; axis named. `CONCL`: SUPPORTED.

### S-5#5 — GO-FORWARD ENTRY GUARDS (title length + control chars) — DECIDED

**Decision: a GENERAL validate-pack enforcement leg (no per-entry exception) for title ≤ 256 and
no NUL/CR/disallowed-control byte, sized to the measured-clean tree (bound = zero violations).**
Designed in §3.3e + §4.4.
- **Title (R-TITLE-1):** assert ID-prefixed title ≤ 256 per entry; BD-208 worst at 231 (25 headroom).
- **Control chars (R-BODY-6):** scan each body for a disallowed control byte; clean across all 211.
- Both run in the unattended CI guard alongside the byte-faithfulness + size legs.

> **Empirical-Evidence Block (both guards run green on the current tree; headroom on the worst title is 25).**
> `CMD`: title-length scan + control-byte scan over all 211 (this sweep).
> `OUT`: max stored title 231 (BD-208), >256 NONE; control bytes NONE. `AT`: HEAD `feaa45d`,
> 2026-06-07. `INTERP`: the guards are clean today; they catch a FUTURE 248+ title or control byte
> before it can break a create. `CONCL`: SUPPORTED.

### S-5#6 — THE REVIEW-3 ITEMS (python3-gzip pin / decode-identity / corrupt-blob fail-loud / actual-body size) — DECIDED

**Decision: all four pinned in the design.** §3.3 step 4 (python3-codec pin on EVERY path +
corrupt-blob FAIL-LOUD, never silent-empty); §3.3b (the invariant restated as DECODE-IDENTITY
`gunzip(b64decode(blob))==raw_body`, with `mtime=0` determinism as a secondary convenience for the
size leg + re-create stability); §4.4 (the size check + CI-guard leg compute on the ACTUAL composed
body via `len(tmf_compose_issue_body(...))`, NOT the §3.3c distribution proxy — the SAME measurement
in the composer overflow check, the CI guard, and the C-7 size leg).

> **Empirical-Evidence Block (gzip+base64 decode-identity holds + is deterministic with mtime=0; python3 is the universal codec).**
> `CMD`: deterministic gzip (`GzipFile(mtime=0)`) of BD-136 body, decode-compare + encode-twice; grep python3 in the libs.
> `OUT`: `gunzip(b64decode(blob)) == raw_body` (byte-identical); two encodings identical (mtime field
> `0 0 0 0`); `python3` is used for every codec step in the reverse lib. `AT`: HEAD `feaa45d`,
> 2026-06-07. `INTERP`: decode-identity is the load-bearing invariant (holds regardless of encoder
> determinism); `mtime=0` makes the encoder deterministic (size-leg + re-create convenience); python3
> is property-fit. `CONCL`: SUPPORTED.

### S-5#7 — HONEST PORTABILITY BOUNDARY (landscape) — DECIDED

**Decision: the blob is the RAW-TEXT-BODY-CLASS carrier; the provider declares
`provider_body_storage_format` (raw_text | rich_text_normalizing) alongside `provider_body_limit`;
the migrator FAILs loud on a rich-text-normalizing OR too-small-body backend.** Designed in §3.3c +
the §9 portability row. No tracker-agnostic claim over-reaches: GitLab/Redmine/Shortcut FIT; Jira
Cloud is a DOUBLE misfit (32,767 cap + ADF rewriting). Same provider contract, class-appropriate
carriers — a rich-text backend needs a different carrier (attachment / split), a FUTURE BD.

> **Empirical-Evidence Block (the landscape verdicts ground the raw-text-class boundary).**
> `CMD`: RESEARCH-TRACKER-LANDSCAPE-RULES.md §3.2 verdicts.
> `OUT`: FITS = GitLab/Redmine/Shortcut (raw-text body ≥ ~43 KB); MISFIT = Jira (32,767 + ADF),
> Trello (16,384), Monday (2,000), Asana/Basecamp (restricted-HTML), Notion (block model). `AT`: HEAD
> `feaa45d`, 2026-06-07. `INTERP`: the carrier works on the raw-text class only; the storage-format
> capability makes the boundary explicit + fail-loud. `CONCL`: SUPPORTED.

### S-5#8 — C-7 DISPOSITION (rebuild vs discard) — DECIDED: REBUILD

**Decision: REBUILD (not discard); the rebuild spec now also exercises the testable operational rules.**
Designed in §5.c. C-7 is the only surface that can empirically confirm the DOCUMENTED-SILENT platform
behaviors (DS-1 stored byte-verbatim, DS-2 web normalization) on the real target repo + the C-8 dress
rehearsal — discarding it leaves the live round-trip unproven. Its current carry-set-only fixture
cannot catch the drop OR the operational rules, so the rebuild is substantial: drop-set + no-Description
fixtures (carrier); size leg (composed-body measurement); pacing leg (sleep count + retry-after); the
mention-neutralization leg; the corrupt-blob fail-loud leg. The unit-level legs (size/pacing/
neutralization/corrupt-blob — no live GH needed) ALSO run in the unattended battery; the full live
round-trip stays manual + default-SKIP.

> **Empirical-Evidence Block (the parked C-7 tests none of the operational rules today).**
> `CMD`: `grep -niE 'sleep|rate|pacing|mention|#NNN|size|65536|per.minute|corrupt' scripts/tests/tracker-bd204-lossless-roundtrip-test.sh`
> `OUT`: no match for any operational rule (only the forward/reverse run + the content/identity/status
> legs). `AT`: HEAD `feaa45d`, 2026-06-07. `INTERP`: C-7 must be rebuilt to exercise pacing /
> neutralization / size / corrupt-blob — discarding it would lose the only live-confirmation surface.
> `CONCL`: SUPPORTED — REBUILD.

---

## §S-6 — RE-SCOPE + RE-SEQUENCE

### S-6.1 Updated BD-204 entry text
Superseded in `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` §5.a (the LOSSLESS FIELD-CARRIER + GH-RULES FIX
section now folds in size/portability/operational/go-forward/CI + the archive disambiguation). Pack
Chat applies pack-chat-only, gated on the S-5#3 user decision.

### S-6.2 The complete commit sequence (scope per commit)

| Commit | Scope | Pack-only? | Gate |
|---|---|---|---|
| **C-4.5** | gz64 carrier (python3 codec) + emit rewrite + size budget (stored-byte axis, composed-body) + corrupt-blob fail-loud + mention-neutralization (projection) + provider capabilities (`provider_body_limit`/`_storage_format`/`_min_write_interval_s`/`_writes_per_hour_max`) + unit tests + roundtrip fixtures + manifest | YES | after C-6 |
| **C-3 amendment** (folded into the existing C-3 CRUD commit) | `tracker-edit.sh` regenerates BOTH H2 + gz64 blob on `provider_update`; normalization-tolerant divergence comparator | YES | with C-3 |
| **C-4.6** | the CI guard (`check_migrator_field_faithfulness`, next registry integer): byte-faithful + size + title≤256 + control-char legs; per-check test; workflow-yml wiring (Check 42); positive/negative fixtures; manifest | YES | after C-4.5 |
| **C-4.7** | `backlog/_rules.md` byte-faithful-migration statement (MAJOR contract change → coder); METHODOLOGY NOT edited (supporting-docs/ ships to clients — F-2) | YES | after C-4.6 |
| **C-5** (existing, plan) | forward Deferred-encode carry-forward (already landed) — verify | YES | — |
| **C-7** (REBUILD, S-5#8) | rebuilt oracle: drop-set + no-Description fixtures; size/pacing/neutralization/corrupt-blob legs; manual-only + default-SKIP; unit-level legs also in the unattended battery | YES | after C-4.5/4.6 |
| **C-8** (existing, plan; scope ADDITIONS S-5#1/#2/#3) | the real-repo dogfood flip via the PACED, mention-neutralized create loop, targeting the REAL (NON-ARCHIVED) repo; gated on C-7 green + explicit user approval (live RUN user-gated) | YES | LAST; C-7 green + user approval + S-5#3 resolved |

Every commit carries the `pack-only` scope keyword; every `scripts/`-touching commit regenerates
`test-fixtures/manifest.txt` (the regen rule). Sequencing rationale: carrier (C-4.5) before guard
(C-4.6, must run green on the fixed migrator) before the oracle rebuild (C-7, tests the fixed behavior)
before the flip (C-8, must not lose data / trip rate limits).

### S-6.3 BD-206 / BD-207 impact
- **BD-206** (project per-entry no-mirror): no migrator-field/operational change; inherits the carrier +
  guard when BD-207 reuses the machinery. No new impact from the sweep.
- **BD-207** (project tracker reuse): reuses the gz64 carrier + the guard + the provider capabilities
  unchanged (prefix-agnostic). The sweep ADDS, for BD-207's eventual rewrite: the
  `provider_body_storage_format` portability boundary (the project surface inherits the raw-text-class
  contract) + the pacing capabilities (a project-side bulk create paces identically). BD-207's
  POST-BD-204 REFRESH anchor should reference the swept design as the as-built contract.

---

## §S-7 — RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (actual command / quote / measurement) | Conclusion |
|---|---|---|
| `agents-never-commit` | No `git add/commit/push/tag` or any state-changing verb; `git rev-parse HEAD` (read-only) only; the writes are the IN-PLACE design-doc amendments (uncommitted) + this ONE sweep report. | COMPLIANT |
| `per-action-approval-sub-agents` | No destructive op; no live GH (no `gh repo create`/network write — all measurement local read-only); no file deleted/overwritten outside the two deliverables. | COMPLIANT |
| `external-rules-census-before-design` | The 28-rule GH-Issues law + the 14-tracker landscape (both read in full) are treated as FIXED; every design section re-validated (S-1); the one unrealizable item (operate-on-archived, R-ACCT-4) SURFACED as a user decision (S-5#3), never silently relaxed. | COMPLIANT |
| `ci-guard-measure-then-bound` | The SIZE axis (S-5#4), the title/control go-forward guards (S-5#5), and the pacing (S-5#1) are each MEASURED first (distribution / headroom / count) then BOUNDED (fail-loud / general guard / pacing gate); no allowlist; verified clean against the current tree. | COMPLIANT |
| `empirical-evidence-blocks` | Every CHANGE/CLEAN verdict carries CMD + verbatim OUT + HEAD `feaa45d` + 2026-06-07 + INTERP + CONCL (S-1 amendments, S-2 chain-docs, S-3 pacing/python3, S-4 content-clean/token/archive, S-5 all 8). | COMPLIANT |
| `architect-doc-reality-reconciliation` | S-2 names the committed-doc corrections by §/symbol (ARCHITECTURE-BD-204.md §2.4.1/§2.4.2/§3.1/§3.4; PLAN-BD-204.md §C-7/§C-8/§4) — never line numbers; the realized consumers (`_tmf_parse_backlog_file`, `tmf_compose_issue_body`, `_tmr_emit_pack_tree`, `tracker_edit_entry`, the provider capability block) named by symbol in S-3. | COMPLIANT |
| `enumerate-encoding-surfaces` | S-3 enumerates every code/test/workflow/provider/capability surface the rule-driven changes touch, in lock-step with the design §4.5; the client emit branch is explicitly CLEAN/untouched. | COMPLIANT |
| `pattern-matching-out-of-context` | The pacing gate reuses the existing rate-detection + capability/enforcement split (not invented); the python3 codec reuses the all-python3 lib idiom; the mention-neutralization is a general projection transform (not a per-entry hack); the storage-format capability sits alongside the existing capability floor — each property-fit, evidenced. | COMPLIANT |
| `pack-project-separation` | All changes pack-side; METHODOLOGY.md (`supporting-docs/`, client-shipped) NOT edited; the 3 project-side `_rules.md` untouched (diverge until BD-206/207, correct-by-design); BD-207 impact is a design-property note, not a project edit. | COMPLIANT |
| `scope-deliverables-to-the-ask` | Delivered exactly: the design amended in place (S-1) + this sweep report with the S-1..S-6 ledger, the 8 decisions, the entry-modification list (1 wording / 0 content), the re-sequenced commits. No extra surface. | COMPLIANT |
| `filename-uniqueness-heuristic` | `find . -name "SWEEP-BD-204-RULES-COMPLIANCE.md" -not -path "./.git/*"` returned EMPTY before write (Bash, this session). | COMPLIANT |
| `tracker-portability` | The honest boundary (S-5#7): raw-text-body class only; `provider_body_storage_format` capability; fail-loud on misfit; no GitHub-sized over-claim. | COMPLIANT |
| `rules-applied-verification-block` | This table — per-rule, evidence quoted, terminal conclusion; no empty evidence; no AMBIGUOUS. | COMPLIANT |

## §S-8 — READ-IN-FULL attestation (this session, at HEAD `feaa45d`)

| Document | Read proof |
|---|---|
| `RESEARCH-BD-204-GH-ISSUES-RULES.md` (law; now 30 rules after the GATE-(B) second fold-in) | Read FULL across passes — all rules, §2 census, §3 map, §8 fold-in ledgers. GATE-(B) this turn: read the two new rows R-OPS-7 (no repo-creation-specific limit; rides the general secondary caps) + R-ACCT-5 (personal repos unlimited < 100,000; 10 GB on-disk `.git` recommendation; issues DB-stored) + their §3 map rows. |
| `RESEARCH-BD-204-GH-ISSUES-RULES-VERIFY-2.md` (GATE-(B) verification) | Read this turn — verdict = VERIFIED; the archived-quota framing NIT (docs SILENT on an archived-repo exemption → conservative "archived counts toward the cap" reading adopted in §11.3 / §S-9). |
| `RESEARCH-TRACKER-LANDSCAPE-RULES.md` (law) | Read FULL (1-406) — Tier A/B trackers, §3 carrier-fit verdicts, §4 documented-silent register. |
| `RESEARCH-BD-204-GH-ISSUES-RULES-VERIFY.md` (audit trail) | Read (1-60 + §0 verdict) — confirms values + census numbers; CORRECTIONS-NEEDED resolved by the fold-in. |
| `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` | Read across the sweep + amended IN PLACE (§3.3/§3.3a-e/§3.3c/§4.4/§4.5/§5.a/§5.b/§5.c/§9/§10). |
| `backlog/BD-204.md` | Read full — the archive wording (S-5#3); re-scope (§5.a). |
| `backlog/BD-206.md` / `backlog/BD-207.md` | Read full (fix-1) — BD-207 reuse impact (S-6.3). |
| `scripts/lib/tracker-migrate-forward.sh` | Read directly — parser/composer/create-loop/phase-site; pacing absence + python3 idiom re-verified this sweep. |
| `scripts/lib/tracker-migrate-reverse.sh` | Read directly (fix-1/2) — reconstruct/emit/comparator; python3 codec count this sweep. |
| `scripts/lib/tracker-provider-gh.sh` | Read directly — capability block (`writes_per_minute_recommended`, `result_ceiling_per_query`, `raw_escape_hatch`), `_gh_classify_error`. |
| `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` | Read directly — confirmed it tests NO operational rule (S-5#8). |
| `scripts/validate-pack.py` | Read via grep — Check 42 (no exemption), highest banner 48, no faithfulness check. |
| Live tree (all 211 `backlog/BD-*.md`) | RE-MEASURED this sweep: R-OPS-6 token census (21 `#NNN` + 2 bare-`@`); R-TITLE-1 (BD-208 231/256, 0 over); R-BODY-6 (0 control bytes); gzipped-request axis (BD-136 31.0% gzipped-request vs 62.1% stored — corrected from a wrong 0.2%); size distribution (worst 62.1%). |
| `CLAUDE.md ## Pack memory` + curated memory | In session context; in-force rules applied (external-rules-census, ci-guard-measure-then-bound, tracker-portability, pack-project-separation, scope-deliverables, empirical-evidence, agent-output-rules-applied-block). |

**No named document was derived rather than read.** Every repo measurement is this session's own
command output at HEAD `feaa45d` (2026-06-07); every platform constraint traces to the 28-rule law +
the landscape (each with an official source already cited there).

---

## §S-9 — COMPLETENESS VERDICT (cohesive re-read; the core of the cohesive-design mandate)

The authoritative verdict + the full known-unknown→rehearsal-leg map + the census-gap hunt live in
`ARCHITECTURE-BD-204-LOSSLESS-FIX.md` **§11** (so the verdict sits with the design it judges). Summary
for this ledger:

**VERDICT: COHESIVE-AND-COMPLETE for the as-designed v11.0 scope, CONDITIONAL on (a) ONLY — the
irreducible C-7 live-rehearsal gate confirming the DOCUMENTED-SILENT platform behaviors before C-8.
Gate (b) is CLOSED: the GATE-(B) close-out (R-OPS-7 + R-ACCT-5; VERIFY-2 = VERIFIED) MEASURED both
census gaps to resolution — no researcher pass remains.**

**The cohesive-design review findings + constraint B — finding→edit ledger:**

| Finding | Severity | Edit applied |
|---|---|---|
| MUST-1: gzipped-request EE wrong (134/0.2% → real 20,321/31.0%) | MUST | Re-measured (20,321 / 31.0%); corrected §3.3c EE (design) + S-5#4 EE (this report); axis conclusion re-derived (62.1% stored > 31.0% request — survives). |
| MUST-2: phantom `tracker_edit_apply` | MUST | Replaced with `tracker_edit_entry` (verified at `tracker-edit.sh:156`) in §3.3a/§4.5/§5.b/§7 R-EDIT + this report's S-3 + S-7; ALL named symbols re-verified by grep. |
| SHOULD-3: autolink completeness (SHAs/URLs) | SHOULD | Censused all 4 forms (21 `#NNN`, 2 `@`, 97 SHA-outside-code, 2 URL); PINNED the inline-code-span variant (form-agnostic), REJECTED the U+2060 variant; §3.3d + §4.5 + §7 R-AUTOLINK + C-7 leg updated. |
| SHOULD-4: settled Option A + multi-rehearsal | SHOULD | §5.a now states SETTLED Option A (real repo NEVER archived; archive=scratch disposal) + REPEATABLE multi-rehearsal; dropped the A-vs-B framing; §5.c encodes multi-rehearsal. |
| NIT: label max 24→25 | NIT | Corrected to 25 (`template:phase-epic-v11.0`) in both docs. |
| Constraint B: no-delete credential | NEW | C-7 disposal reworked to ARCHIVE-not-delete + recommend manual delete + assert `isArchived` (§5.c); NEW §5.f credential-capability preflight + required-permission set; §4.5 preflight/disposal surfaces; §7 R-PREFLIGHT/R-DISPOSAL; credential permission set recorded as a third external-constraint class. |
| GATE-(B) close-out: the 2 §11.3 census gaps | RESEARCHED + RESOLVED | R-OPS-7 (verified-negative: NO repo-creation-specific limit; the §3.3d issue-pacing gate bounds the multi-rehearsal cadence) + R-ACCT-5 (personal repos unlimited < 100,000, issues DB-stored → archived accumulation benign; conservative archived-counts-toward-cap framing). VERIFY-2 = VERIFIED. §11.1/§11.3/§11.4 flipped RESOLVED-BY-MEASUREMENT; the §11 verdict flipped to gate (a) ONLY; §5.c cadence note reconciled. No new gate. |

**Known-unknown → rehearsal-leg map (design §11.2):** 7 mapped (DS-1 content-faithfulness, DS-2
normalization-comparator, DS-3 size/near-budget, KU-OPS-2/3 paced-create, KU-OPS-6 autolink-render,
KU-CRED preflight+disposal) + 2 MOOT (DS-4 control-char guarded, DS-5 title structural). None unmapped.

**Census-gap hunt (design §11.3) — both gaps RESEARCHED + RESOLVED-BY-MEASUREMENT (GATE-(B) close-out):**
1. **Repo-CREATION rate limit → RESOLVED (R-OPS-7; VERIFY-2 = VERIFIED).** Verified NEGATIVE: GitHub
   has NO repo-creation-specific rate limit; a repo create rides the general secondary caps (R-OPS-2/3).
   The binding multi-rehearsal constraint is each rehearsal's 211 ISSUE creates — already bounded by the
   §3.3d pacing gate (the single repo-create per rehearsal needs no separate gate). No new gate.
2. **Account / private-repo quota → RESOLVED (R-ACCT-5; VERIFY-2 = VERIFIED).** A personal account owns
   unlimited public + private repos below a 100,000 hard cap (50,000 banner); the 10 GB on-disk figure
   is a `.git` recommendation and issues are DB-stored — so an accumulating archived-scratch campaign
   consumes ~0 of both axes. (Conservative framing: docs are SILENT on an archived-repo quota EXEMPTION
   rather than excluding archived repos, so they are read as counting toward the cap — still negligible.)
   Accumulation benign; §5.c archive-not-delete already honors it; public-scratch / manual-delete are
   optional housekeeping.
Plus 1 minor absorbed-with-flag (gh CLI version pin → fold into the §5.f preflight). 5 other candidate
classes (CI-env, token tier, issue-dependency caps, forms caps, etc.) ABSORBED with evidence (§11.3).

Both gaps were NEWLY relevant only because of the late-settled multi-scratch + no-delete decisions; the
GATE-(B) close-out MEASURED them to resolution rather than carry them — consistent with the lesson that
two constraint classes (platform rules, then credential permissions) already arrived late. NO researcher
pass remains; the SOLE condition before C-8 is the irreducible gate-(a) C-7 live rehearsal.

---

**End of SWEEP-BD-204-RULES-COMPLIANCE.md**
