# PACK-REVIEW-BD-204-C-DOCS — review of the committed-chain-doc reconciliation (working tree at HEAD `c7f9af6`)

> **Reviewer:** pack-reviewer. **Date:** 2026-06-10. **Branch:** `v11-dev`.
> **Under review:** the uncommitted working-tree diff to
> `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md` (+259/−74, one file), plus the
> coder's new `IMPL-REPORT-BD-204-C-DOCS.md` (read for inventory only; the diff and resulting doc
> were reviewed on their own merits).
> **Authoritative references reviewed:** `PLAN-BD-204-LOSSLESS-FIX-SEQUENCE.md` §1/§4/§7,
> `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` (§1.3, §3.3/§3.3a–e, §4, §5.c/§5.d/§5.f), `backlog/BD-204.md`,
> and the as-built code (read-only): `scripts/lib/tracker-migrate-forward.sh`,
> `tracker-migrate-reverse.sh`, `tracker-provider-gh.sh`, `tracker-edit.sh`,
> `scripts/validate-pack.py`, `.github/workflows/validate-pack.yml`,
> `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` + its fixture. No prior PACK-REVIEW read.
> No repo file edited; no state-changing git verb run; this report is the only write.

## Verdict

**APPROVE-WITH-FIXES** — 1 MUST, 2 SHOULD, 3 NIT. The reconciliation is substantively complete,
overwhelmingly accurate against the as-built code, in scope, and well-disciplined about dated
records. The MUST is a one-line phantom-symbol fix inside a sentence this very pass edited.

---

## 1. Findings

### MUST-1 — §2.1 step 2 names a phantom symbol with a stale line number, inside a reconciled claim

**File/anchor:** `ARCHITECTURE-BD-204.md` §2.1 "How the tree is regenerated FROM the tracker",
step 2 (resulting doc ~line 272).

Step 2 reads: `` `_tmr_reverse_reconstruct` (`tracker-migrate-reverse.sh:506`) `` builds the entry
object. No function named `_tmr_reverse_reconstruct` exists as-built — the real symbol is
`tracker_migrate_reverse_reconstruct` (defined in `scripts/lib/tracker-migrate-reverse.sh`; def at
`:536` today, so the `:506` ref is also stale). The C-DOCS diff rewrote the second half of this
exact sentence (the `raw_body`-from-blob clause) while leaving the phantom symbol + line ref in the
first half. This step IS in the §7 reconciliation ledger ("§2.1 step 2 — Regen path reads the
verbatim `raw_body`…"), and the §7 Rules-Applied row claims "Every reconciled claim names its
realized consumer by file + symbol (never line numbers)" — the step violates both halves of that
claim. Fix: replace with `tracker_migrate_reverse_reconstruct` and drop the line number (symbol-only
per the pass's own convention). Note: the same phantom name appears at ~line 695 inside the dated
§2.6.1 EE block (`OUT:` quote) — that occurrence is a dated record and may stay, but the live step-2
claim must be correct.

### SHOULD-1 — "the SAME functions the production migration uses" overstates the batch-codec seam

**File/anchor:** `ARCHITECTURE-BD-204.md` §2.4.2 "Re-grounding (2026-06-10)" paragraph.

The text claims the guard runs "via the single-sourced batch codec (`_tmf_gz64_encode_batch` /
`_tmr_decode_body_blob_batch` — the SAME functions the production migration uses, so no second
codec can drift and FALSE-PASS a lossy change)". As-built, the production forward path calls the
single-record `_tmf_gz64_encode` (`tracker-migrate-forward.sh`, blob emit in
`tmf_compose_issue_body`) and production reverse calls the single-record `_tmr_decode_body_blob`
(`tracker-migrate-reverse.sh`, reconstruct path); the `_batch` variants are ADDITIVE siblings in the
same libs ("ADDITIVE … NOT a behavior change to the single-record `_tmf_gz64_encode` above" —
forward lib comment), consumed by Check 49. So the parenthetical is literally false: the batch
functions are NOT the functions the production migration calls — they are the single-source batch
mode living in the same migrator libs, with Check 50 (`OQ-4 single-source codec guard`,
`scripts/validate-pack.py`) forbidding any reproduced codec inside the validator. The protection
claim is real but mis-attributed. Suggested wording: "the single-sourced batch mode of the
production codec, living in the migrator libs beside the single-record production functions and
enforced same-source by the Check-50 OQ-4 guard." (The spec's own §4 framing — 'the guard calls the
SAME functions' with 'a BATCH mode' — describes a mode on one function; the as-built realization is
sibling `_batch` functions, so the doc should describe the as-built shape, which is this pass's
whole purpose.)

### SHOULD-2 — the end-of-§1 "DECISION POINTS summary" blockquote still asserts the phantom carrier with no supersession marker

**File/anchor:** `ARCHITECTURE-BD-204.md` §1, the "DECISION POINTS summary — ALL FIVE RESOLVED
(user 2026-06-06)" blockquote after DP-5 (resulting doc ~lines 245–252).

It still reads "DP-2 → carrier = form family + Issue body incl. the in-body `pack-extra-fields`
block". The new §1 as-built note's scope phrase — "Mentions of `pack-extra-fields` in this §1
decision record" — sits ~130 lines earlier inside the DP-2 record and most naturally reads as
scoped to DP-2 alone; and §7's "Dated records intentionally left byte-stable" list names the DP-2
RESOLVED wording, the §2.4.2 EE `CMD`/`OUT`, the `template_version` EE `CMD`, §5, and §6 — but NOT
this summary block. A reader landing on the summary sees a live-looking stale carrier claim with no
adjacent or ledgered disposition, which also strains §7's "dated records that mention it are
explicitly marked superseded" COMPLIANT row. Fix (any one suffices): widen the §1 note's scope
sentence to name the end-of-§1 summary block; or add the block to §7's byte-stable disposition
list; or adjoin a one-line as-built pointer to the summary block itself (mirroring the DP-2
treatment — addendum, not rewrite).

### NIT-1 — comparator normalization description omits bare-CR canonicalization while claiming "no broader"

**File/anchor:** `ARCHITECTURE-BD-204.md` §2.4.1 "Realized consumers" paragraph
(`_tmr_check_blob_h2_divergence` description: "CRLF→LF, per-line trailing-whitespace strip, single
trailing newline — exactly GH's munging, no broader").

The as-built `norm()` (`tracker-migrate-reverse.sh`, inside `_tmr_check_blob_h2_divergence`) does
`s.replace("\r\n","\n").replace("\r","\n")` — i.e., it ALSO canonicalizes bare CR, one transform
broader than the doc's three-item enumeration. Cosmetic: say "CRLF/CR→LF" (the code's own comment
wording) or drop "no broader".

### NIT-2 — two carried-over file:line refs re-emitted inside rewritten "as-built" prose

**File/anchor:** `ARCHITECTURE-BD-204.md` §2.4 boundary principle (`ARCHITECTURE-V3.3-DELTA.md:312`)
and §2.4.1 carrier paragraph (`backlog/BD-204.md:14`).

Both refs existed in the replaced pre-image text (so they are not NEW line-number references — the
success criterion is met), and both are accurate today (`backlog/BD-204.md:14` is the HARD-tier
bullet containing "full-CRUD true-SSOT"). But they now live inside paragraphs rewritten by a pass
whose own ledger says "never line numbers", and `backlog/BD-204.md` is a living entry whose line
numbers drift (it gained a dated note on 2026-06-10). Opportunistic fix: anchor by section/field
("the `backlog/BD-204.md` DECISION TIERS HARD bullet") rather than line.

### NIT-3 — §5 audit row presents the phantom carrier as a COMPLIANT result with the disposition only in §7

**File/anchor:** `ARCHITECTURE-BD-204.md` §5 Rules-Applied table, "Pattern-matching out of context"
row (~line 1110): "the overflow carrier (§2.4) is the form family + the in-body `pack-extra-fields`
block … COMPLIANT".

Unlike SHOULD-2, this record IS named in §7's byte-stable disposition list, so the treatment is
defensible (dated audit record; addendum-not-rewrite discipline). Optional polish: a one-line
forward-pointer adjoining §5 (as §1 DP-2 got) would protect a §5-alone reader. Not blocking.

---

## 2. Coverage check — every §4-owed edit (PLAN §4 + spec §5.d)

All owed edits are present; verified against the diff hunks and the resulting doc:

| Owed (PLAN §4 / spec §5.d) | Delivered | Where |
|---|---|---|
| §2.4.1 / §2.4.2 / §2.11 / §3.1 carrier text → gz64 verbatim-body blob | YES | §2.4.1 carrier statement replaced (gz64 marker example, lines-2..EOF span, `mtime=0`, python3-pinned, corrupt-blob FAIL-LOUD, blob-authoritative + comparator + `--force`); §2.4.2 INTERP reconciled; §2.11 pillars rebuilt; §3.1 item 4 → "entire body recovered" |
| Zero-orphaned claim re-grounded (blob + faithfulness check, not the phantom block) | YES | §2.4.2 "Re-grounding (2026-06-10)" — by-construction blob + Check 49 |
| ADD size (stored-byte axis) + pacing + mention-neutralization + `provider_body_storage_format` | YES | §2.4.1 "As-built operational contract" (4 bullets) + §2.12 ON bullet |
| §3.4 / §2.12 archive wording → Option-A scratch disposal | YES | §3.4 fully rewritten (preflight, REPEATABLE, ARCHIVE-only + trap, grep-guard, user-only manual delete, REAL repo never archived); §2.12 contains no archive wording as-committed — nothing to convert there; its pacing/deterministic-blob edits match the §7 ledger |
| Named by §/symbol, never line number | YES with one defect | New consumer references are file+symbol throughout (§2.4.1, §2.11, §3.4, §4.3, §7); the `:1032-1042` ref in §2.11 was converted to the `n_skipped` symbol. Defect: MUST-1 (a phantom symbol + stale line ref survived inside edited §2.1 step 2); NIT-2 (two carried-over refs) |
| Dead-carrier disposition described (spec §5.d bullet 2) | YES | §2.4.1 "Realized consumers" + §4.3 + §7 ("dead `extra_fields` render is DELETED"; `_tmr_emit_pack_tree` REWRITTEN verbatim) |
| `PLAN-BD-204.md` NOT re-edited; `ARCHITECTURE-BD-204-POST-BD211-RECON.md` left as attested history | YES | Neither file in the diff; §7 records both attestations |

## 3. Factual-accuracy spot-checks performed (all against the as-built code at `c7f9af6`)

Every claim below was verified by direct read/grep; ✓ = claim matches code.

- **Forward:** `_tmf_parse_backlog_file` exists and captures `raw_body` = verbatim lines 2..EOF
  (forward lib `raw_body_by_pid`, "lines 2..EOF exactly") ✓. `tmf_compose_issue_body` has a
  DEFAULTED 6th `raw_body` param (`local raw_body="${6:-}"`) ✓; emits
  `<!-- pack-entry-body-gz64: … -->` via `_tmf_gz64_encode` ✓; refuses `rich_text_normalizing`
  storage FAIL-LOUD ✓; size budget `provider_body_limit − TMF_SIZE_SAFETY_MARGIN`, "NEVER
  truncates" in the error text ✓. `_tmf_gz64_encode_batch`, `_tmf_neutralize_autolinks`,
  `_tmf_neutralize_autolinks_batch` exist ✓. Neutralization triggers = `#NNN`, bare `@token`,
  bare 7–40-hex SHA, bare `http(s)://` URL; inline-code fence widened past existing backtick runs;
  blob never routed through it ✓. Pacing gate sleeps the provider's
  `.rate_limits.min_write_interval_s` with `TMF_PACING_SLEEP_CMD` as the test seam; retry-after
  honored at the create call site ✓.
- **Reverse:** `_tmr_decode_body_blob` (python3 decode; corrupt-blob FAIL-LOUD, "NEVER emits an
  empty/partial entry body") ✓; `_tmr_decode_body_blob_batch` ✓; `_tmr_check_blob_h2_divergence`
  normalization-tolerant comparator with `--force` = loud blob-wins override ✓ (modulo NIT-1
  bare-CR); `_tmr_emit_pack_tree` writes `pe_backpointer_line` + `raw_body` verbatim, dead
  `extra_fields` render gone (zero `extra_fields` reads remain on the emit path) ✓; `n_skipped`
  partial-write refusal (silent-data-loss guard) ✓.
- **Edit path:** `tracker_edit_entry` (`scripts/lib/tracker-edit.sh`) recomposes via
  `tmf_compose_issue_body` so BOTH H2 + blob regenerate from one entry object on every
  `provider_update`; fails loud (no update attempted) if composition fails ✓.
- **Provider capabilities** (`tracker-provider-gh.sh` capability block): `body.limit: 65536`,
  `body.storage_format: "raw_text"`, `rate_limits.min_write_interval_s: 1`,
  `rate_limits.writes_per_hour_max: 500` — all four exactly as the doc states ✓.
- **CI guard:** `check_migrator_field_faithfulness` IS Check 49 in `scripts/validate-pack.py`;
  SKIPs unless `PACK_VALIDATE_DEEP=1` ("~0 ms SKIP" on the general path) ✓; legs = codec
  byte-round-trip + PARSE-FAITHFUL (`PRE_PARSE_ORIGINAL_body == raw_body`) + composed-body size +
  title ≤ 256 + control-byte ✓ (the doc's compressed formula
  `PRE_PARSE_ORIGINAL_body == decode(encode(raw_body))` is implied by the two as-built assertions;
  acceptable summary); registered via the `run_check` timing harness ✓; per-check test
  `scripts/tests/test-validate-pack-check-49-field-faithfulness.sh` exists and is wired in
  `.github/workflows/validate-pack.yml`, alongside the dedicated
  `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` workflow step ✓. (Codec-attribution
  wording → SHOULD-1.)
- **Oracle** (`tracker-bd204-lossless-roundtrip-test.sh`): credential-capability preflight first
  (repo scope, `delete_repo` NOT required, user-read; `gh` ≥ 2.0 floor with FAIL-LOUD before any
  live write) ✓; ARCHIVE-only disposal with trap-archive on failure + `isArchived` assertion +
  RECOMMEND-manual-delete line ✓; self-guard greps the test source for any repo-delete invocation
  ✓; legs present: drop-set, size, pacing (≥1s live elapsed + fake-clock seam), 4-form
  autolink-neutralization, corrupt-blob fail-loud, DS-2 normalization comparator ✓; fixture
  carries drop-set (BD-901), no-Description (BD-902), 4-form autolink (BD-904),
  parenthetical-title (BD-905), Deferred (BD-906), large multi-block (BD-907) entries ✓.
- **Numbers:** worst entry BD-136 ≈ 62% of the GH 65,536 limit matches the BD-204 entry's measured
  40,771 bytes (62.2%) ✓; GH secondary caps 80/min + 500/hr match the entry + provider block ✓.
- **Spec anchors cited by the doc exist:** `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` §1.3, §3.3,
  §3.3a–e, §4, §5.c, §5.f all present ✓.

## 4. Scope, line-number, dated-record, and consistency sweeps (explicit, including null results)

- **Scope check — PASS.** `git status`: exactly one modified file
  (`ARCHITECTURE-BD-204.md`) + one untracked coder report (`IMPL-REPORT-BD-204-C-DOCS.md`).
  No edits to `PLAN-BD-204.md`, `ARCHITECTURE-BD-204-POST-BD211-RECON.md`, any code, template,
  `project-template/`, or `supporting-docs/` file. `pack-only` holds; BD-204's HARD pack-only
  constraint is honored. Manifest regen NOT owed (maintenance-docs is not v11-surface).
- **New line-number references — PASS with NIT-2.** Scanned every `+` line for `file:NN` patterns:
  only two, both carried over from the replaced pre-image text (`ARCHITECTURE-V3.3-DELTA.md:312`,
  `backlog/BD-204.md:14`); zero genuinely new refs. §2.11's old `:1032-1042` ref was converted to
  a symbol. (MUST-1's `:506` is in an UNCHANGED context line, not introduced by this diff.)
- **Dated-record byte-stability — PASS with SHOULD-2.** Diff hunks confirm §2.2/§2.3, §2.5–§2.9,
  §3.2/§3.3, §4.1/§4.2, §5, §6, the §2.4.2 EE `CMD`/`OUT`, and the `template_version` EE are
  untouched; supersession is via the §1 addendum note + the appended §7 ledger, not history
  rewrites. The §2.4.2 EE INTERP rewrite is plan-sanctioned ("zero-orphaned re-grounded") and
  carries an explicit "(as-built, reconciled 2026-06-10)" marker. Gap: the end-of-§1 DP summary
  block (SHOULD-2).
- **Internal-consistency sweep — PASS with SHOULD-2/NIT-3.** Grepped the resulting doc for every
  surviving `pack-extra-fields` mention (12 sites): all are either (a) inside the marked DP-2
  record (§1, covered by the adjoining as-built note), (b) inside the new as-built text in
  deleted/superseded framing (§2.4.1, §2.4.2, §7), (c) the dated §2.4.1 EE quote immediately
  adjacent to the supersession statement, (d) the `template_version` EE `CMD` string
  (§7-dispositioned), or (e) the two gaps flagged above (§1 summary block; §5 row). Zero surviving
  live design statements claim the phantom carrier. Grepped for stale `gh repo delete`-as-cleanup:
  both pre-fix statements removed; the only remaining mentions are negations ("NEVER runs",
  "grep-guarded out"). No contradictory section pairs found: §2.4 ↔ §2.4.1 ↔ §2.4.2 ↔ §2.11 ↔ §3.1
  ↔ §3.4 ↔ §7 all describe the same gz64/Option-A design.
- **Cross-reference integrity — PASS.** Section numbering is unchanged (§7 appended; no heading
  renumbered), so the external citations of this doc's §2.x/§3.x (in `PLAN-BD-204.md`,
  `SWEEP-BD-204-RULES-COMPLIANCE.md`, the IMPL reports, `ARCHITECTURE-BD-204-LOSSLESS-FIX.md`
  §5.d) remain valid — and now point at accurate content.
- **Trinity rule — N/A.** No CLAUDE.md/AGENTS.md/GEMINI.md (root or project-template) touched.
- **validate-pack.py alignment — N/A/PASS.** No new validated surface added; the new files are
  maintenance-docs workflow artifacts (Pattern-B exempt, swept at version ship).
- **Migration safety / README layout — N/A.** Pack-internal doc only; nothing client-installed,
  nothing added/moved/removed outside maintenance-docs.
- **BACKLOG accuracy — PASS.** C-DOCS resolves nothing; `backlog/BD-204.md` correctly stays
  `Status: Open` (rehearsal + C-8 outstanding), and its LOSSLESS FIELD-CARRIER section already
  describes the same as-built design this doc now carries.
- **Validator run (evidence).** `python3 scripts/validate-pack.py` on the working tree: the single
  FAIL is `PyYAML not available — cannot validate issue templates` — an environment artifact of
  this machine's python3 (`import yaml` → ModuleNotFoundError), unrelated to a docs-only
  maintenance-docs diff; CI installs PyYAML. All content checks that ran are green, including
  Check 48 (advisory only) and Check 50 (OQ-4 single-source codec guard).

## 5. What the implementation got right

- Complete coverage of the owed edit set (plan §4 + spec §5.d) with zero scope creep — the
  exact one-file docs-only commit OQ-2 prescribed.
- The as-built operational contract (size / pacing / neutralization / storage-format) is rendered
  with near-perfect fidelity to the code, down to variable names (`TMF_SIZE_SAFETY_MARGIN`,
  `TMF_PACING_SLEEP_CMD`), capability keys, and error-message semantics ("never truncates",
  "never silent-empty").
- Dated-record discipline is genuinely addendum-based: the DP-2 user decision, both EE
  `CMD`/`OUT` blocks, §5, and §6 are byte-stable, with an explicit disposition ledger in §7 —
  exactly the `architect-doc-reality-reconciliation` chain (doc addendum + file+symbol consumers +
  IMPL-REPORT cross-link).
- The §7 reconciliation ledger is a model artifact: per-section table, full consumer chain, and
  explicit do-not-touch attestations for `PLAN-BD-204.md` and the POST-BD211 RECON.
- The Option-A §3.4 rewrite matches the rebuilt oracle leg-for-leg, including the self-guard and
  the never-archive-the-real-repo boundary.

## 6. Fix list (for triage)

1. **MUST-1** — §2.1 step 2: `_tmr_reverse_reconstruct` (`tracker-migrate-reverse.sh:506`) →
   `tracker_migrate_reverse_reconstruct` (symbol only, no line number).
2. **SHOULD-1** — §2.4.2 re-grounding: reword "the SAME functions the production migration uses"
   to describe the as-built single-source batch siblings + the Check-50 OQ-4 guard.
3. **SHOULD-2** — disposition the end-of-§1 "DECISION POINTS summary" blockquote's
   `pack-extra-fields` mention (widen the §1 note's scope, add it to §7's byte-stable list, or
   adjoin a one-line pointer).
4. **NIT-1** — §2.4.1: "CRLF→LF" → "CRLF/CR→LF" (or drop "no broader").
5. **NIT-2** — opportunistically convert the two carried-over line refs
   (`backlog/BD-204.md:14`, `ARCHITECTURE-V3.3-DELTA.md:312`) to section/field anchors.
6. **NIT-3** — optional one-line as-built pointer adjoining the §5 audit row.

No carry-forwards are claimed: every finding above is fix-now material (none passes the
SIZE/BLOCKED/LOGICAL-FIT triple test for deferral).

**Verdict: APPROVE-WITH-FIXES**

**End of PACK-REVIEW-BD-204-C-DOCS.md**
