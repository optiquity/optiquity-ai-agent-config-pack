# RESEARCH-BD-204 — Lossless field census + green-CI root cause

> **Role:** pack-docs-researcher. **Mode:** read-only investigation; one report write.
> **Scope:** PACK-ONLY (project-side read for schema parity only; nothing edited).
> **HEAD:** `feaa45dcb7a39dd3cc12fb4ff9c234d9845cfb53`  **Date:** 2026-06-06.
> **Mandate:** verified FACTS only. No fix, no design, no categorization-as-recommendation.
> Factual classification ("in-schema-not-carried" vs "not-in-schema-not-carried") is allowed (deliverable 2).

This report is the MEASURE step for a future guard (ci-guard-measure-then-bound):
it captures the COMPLETE occurrence set, not a sample.

---

## §0 — Bottom line (one paragraph, all facts proven below)

The forward migrator parser (`_tmf_parse_backlog_file`, `scripts/lib/tracker-migrate-forward.sh`
:382-495) extracts a **9-key whitelist** (`type, status, blockers, unblocks, file_symbol,
description, context, resolution`+`resolved`-alias). Any entry line whose label is NOT in that
whitelist is **silently discarded** (parser :477-480: unknown label → `field_being_collected =
None`, subsequent content dropped). `tmf_compose_issue_body` (:601-630) emits ONLY
Description / File-Symbol / Context / Resolution body sections. The reverse reconstruct
(`tracker_migrate_reverse_reconstruct` :523-599) emits a JSON object with NO `extra_fields`
key and never parses a `pack-extra-fields` block. The `extra_fields` / `pack-extra-fields`
handling in the reverse emitter (`_tmr_emit_pack_tree` :753-785) is **defensive dead code** —
it is never fed data. Net: **9 of the 28 distinct top-level field labels** present in the live
211-entry backlog round-trip; the other **19 labels are dropped** on forward migration. CI is
green because the ONLY content-faithfulness test (`tracker-bd204-lossless-roundtrip-test.sh`,
the §3.2 oracle) is **manual-only + default-SKIP** (never runs in CI) AND its fixture — like the
two CI-wired round-trip/forward fixtures — contains **only the 9 carried fields**, so no test
ever exercises an entry carrying a dropped field. The ARCHITECTURE-BD-204 §2.4/§2.4.1/§2.4.2
"zero-orphaned-fields" claim describes a `pack-extra-fields`-block carrier that **does not exist
in the code**.

---

## §1 — Exhaustive per-entry field census + reconciliation

**EVIDENCE BLOCK 1.1 — entry count + total field-lines**
- `CMD`: `ls backlog/BD-*.md | wc -l`
- `OUT`: `211`
- `CMD`: `for f in backlog/BD-*.md; do tail -n +2 "$f"; done | grep -cE '^[A-Z][A-Za-z/ -]+:'`  (tail -n +2 strips the line-1 `<!-- per-entry source -->` back-pointer)
- `OUT`: `1527`
- HEAD `feaa45d`, 2026-06-06. INTERP: 211 entry files; 1527 total field-LINES. CONCL: SUPPORTED.

**EVIDENCE BLOCK 1.2 — per-label LINE counts (complete occurrence set, not sampled)**
- `CMD`: `for f in backlog/BD-*.md; do tail -n +2 "$f"; done | grep -oE '^[A-Z][A-Za-z/ -]+:' | sort | uniq -c | sort -rn`
- `OUT` (verbatim):

| Label | LINE count | Label | LINE count |
|---|---|---|---|
| `Type:` | 213 | `Out of scope:` | 10 |
| `Status:` | 213 | `Resolution:` | 4 |
| `Resolved:` | 210 | `Encapsulation:` | 4 |
| `Description:` | 202 | `Acceptance criteria:` | 4 |
| `Unblocks:` | 193 | `Surfaced:` | 2 |
| `Blockers:` | 193 | `Problem:` | 2 |
| `File/Symbol:` | 180 | `Goal:` | 2 |
| `Context:` | 41 | `Steps:` | 1 |
| `Position:` | 14 | `Risk note:` | 1 |
| `Target:` | 11 | `Quality bar:` | 1 |
| `Scope:` | 11 | `Pipeline:` | 1 |
| `References:` | 10 | `Paused:` / `Note:` / `Disposition:` / `Alias:` | 1 each |

- 28 distinct labels. HEAD `feaa45d`, 2026-06-06. CONCL: SUPPORTED.

**EVIDENCE BLOCK 1.3 — RECONCILIATION axis A: per-label LINE sum == total field-lines**
- `CMD`: `... | grep -oE '^[A-Z][A-Za-z/ -]+:' | sort | uniq -c | awk '{s+=$1} END{print s}'`
- `OUT`: `1527`  → equals Block 1.1's 1527. CONCL: SUPPORTED (axis A closes).

**EVIDENCE BLOCK 1.4 — RECONCILIATION axis B: entry-level (distinct-per-file) presence**
- `CMD`: per-label `for f in backlog/BD-*.md; do tail -n +2 "$f" | grep -qE "^<lbl>:" && n++`
- `OUT` (distinct-per-file counts): Type 211, Status 211, Resolved 207, Description 200,
  Unblocks 191, Blockers 191, File/Symbol 180, Context 41, Position 14, Target 11, Scope 11,
  References 10, Out of scope 10, Resolution 4, Encapsulation 4, Acceptance criteria 4,
  Surfaced 2, Problem 2, Goal 2, (Steps/Risk note/Quality bar/Pipeline/Paused/Note/
  Disposition/Alias) 1 each.
- entry-level distinct-label total = **1514**. HEAD `feaa45d`, 2026-06-06.

**EVIDENCE BLOCK 1.5 — RECONCILIATION axis C: LINE − ENTRY diff == in-body/second-occurrence lines (BD-211 fold + one stray)**
- LINE total 1527 − entry-level distinct 1514 = **13**.
- Per-label LINE−ENTRY diffs: Type +2, Status +2, Resolved +3, Description +2, Unblocks +2,
  Blockers +2 → sum = **13**. CONCL: the two totals reconcile exactly via the multi-occurrence files.
- `CMD`: `for f in backlog/BD-*.md; do c=$(tail -n +2 "$f" | grep -cE '^Type:'); [ "$c" != 1 ] && echo "$f=$c"; done` (and same for Status/Resolved/Description/Unblocks/Blockers)
- `OUT`: every label with a second occurrence resolves to exactly these files:
  - `BD-167.md` and `BD-169.md` each carry a SECOND in-body `Type/Status/Resolved/Description/
    Unblocks/Blockers` line — these are the **BD-211 folded sub-entry sections** (former BD-167b /
    BD-169b, folded as in-body sections). Per file that is +6 lines; two files = **+12**.
  - `BD-120.md` carries a second `Resolved:` line (line 17 `Resolved: n/a`, an in-body stray
    BELOW the real `Resolved:` at line 16). That is **+1**.
  - 12 + 1 = **13**. CONCL: SUPPORTED — entry-level vs line-level is NOT conflated; every excess
    line is accounted for.

**EVIDENCE BLOCK 1.6 — three-axis reconciliation summary**
- Axis A (per-label LINE sum) = 1527. Axis A' (raw `grep -c`) = 1527. Axis B (entry-level
  distinct) = 1514. Axis C (B + 13 in-body lines) = 1527 = A. All three axes close. CONCL: SUPPORTED.

**EVIDENCE BLOCK 1.7 — entries with NO `Description:` field (11)**
- `CMD`: `for f in backlog/BD-*.md; do c=$(tail -n +2 "$f" | grep -cE '^Description:'); [ "$c" = 0 ] && basename "$f"; done`
- `OUT`: `BD-195 BD-202 BD-203 BD-204 BD-205 BD-206 BD-207 BD-208 BD-209 BD-210 BD-211` (11 entries)
- INTERP: these newer entries express their substance via `Problem:`/`Scope:`/`Goal:` instead of
  `Description:`. CONCL: SUPPORTED — material to deliverable 3 (their carried body is near-empty).

**EVIDENCE BLOCK 1.8 — per-label ENTRY LISTS for every non-template label**
- `CMD`: per-label `for f in backlog/BD-*.md; do tail -n +2 "$f" | grep -qE "^<lbl>:" && basename "$f" .md; done`
- `OUT` (verbatim entry lists):
  - `Scope:` → BD-195, BD-202, BD-203, BD-204, BD-205, BD-206, BD-207, BD-208, BD-209, BD-210, BD-211
  - `Target:` → BD-197, BD-202, BD-203, BD-204, BD-205, BD-206, BD-207, BD-208, BD-209, BD-210, BD-211
  - `Position:` → BD-136, BD-195, BD-196, BD-197, BD-202, BD-203, BD-204, BD-205, BD-206, BD-207, BD-208, BD-209, BD-210, BD-211
  - `References:` → BD-202, BD-203, BD-204, BD-205, BD-206, BD-207, BD-208, BD-209, BD-210, BD-211
  - `Out of scope:` → BD-202, BD-203, BD-204, BD-205, BD-206, BD-207, BD-208, BD-209, BD-210, BD-211
  - `Resolution:` → BD-021, BD-022, BD-023, BD-123
  - `Encapsulation:` → BD-038, BD-039, BD-040, BD-041
  - `Acceptance criteria:` → BD-202, BD-205, BD-208, BD-210
  - `Surfaced:` → BD-195, BD-196
  - `Problem:` → BD-204, BD-211
  - `Goal:` → BD-195, BD-200
  - `Steps:` → BD-195;  `Quality bar:` → BD-195;  `Alias:` → BD-195
  - `Risk note:` → BD-040;  `Pipeline:` → BD-208;  `Paused:` → BD-185;  `Note:` → BD-205;  `Disposition:` → BD-202
- HEAD `feaa45d`, 2026-06-06. CONCL: SUPPORTED.

---

## §2 — Authoritative-schema reconciliation table (the core artifact)

**Canonical TEMPLATE source** (located + read): the canonical BD/TD entry template is
`supporting-docs/METHODOLOGY.md` Part 7 "BACKLOG item format" (:1199-1216), referenced by
`backlog/_rules.md` :49-50 ("...per the standard BACKLOG item format (METHODOLOGY.md Part 7)").
The template defines EXACTLY these fields: **Type, Status, Blockers, Unblocks, File/Symbol,
Description, Context, Resolution**. (Pack convention uses `Resolved:` in place of `Resolution:`;
the parser aliases both — Block 2.B.)

**EVIDENCE BLOCK 2.A — TEMPLATE field set**
- `CMD`: `sed -n '1199,1216p' supporting-docs/METHODOLOGY.md`
- `OUT` (field lines): `Type:`, `Status:`, `Blockers:`, `Unblocks:`, `File/Symbol:`,
  `Description:`, `Context:`, `Resolution:`. CONCL: SUPPORTED.

**EVIDENCE BLOCK 2.B — forward PARSER whitelist (the carry set)**
- `CMD`: `sed -n '464,483p' scripts/lib/tracker-migrate-forward.sh`
- `OUT` (the `mapping` dict): keys `type, status, blockers, unblocks, file/symbol, file-symbol,
  description, context, resolution, resolved`. `key is None → field_being_collected = None;
  continue` (:477-480) — unknown label content is DROPPED.
- CONCL: SUPPORTED. The carry whitelist == the METHODOLOGY template set (+`resolved` alias).

**EVIDENCE BLOCK 2.C — forward BODY composer**
- `CMD`: `sed -n '601,630p' scripts/lib/tracker-migrate-forward.sh`
- `OUT`: emits `## Description` (always), `## File / Symbol` (if non-empty), `## Context`
  (if non-empty), `## Resolution` (if non-empty). Type/Status/Blockers/Unblocks → labels/links
  (NOT body), per the header comment :598-600 and `_tmf_labels_for_entry` :1501-1534.
- CONCL: SUPPORTED.

**EVIDENCE BLOCK 2.D — reverse RECONSTRUCT (what comes back)**
- `CMD`: `sed -n '523,599p' scripts/lib/tracker-migrate-reverse.sh`
- `OUT`: the emitted JSON object has keys `pack_id, title, type, status, scope, severity,
  blockers, unblocks(=[]), file_symbol, description, context, resolution`. `description/context/
  resolution/file_symbol` ← body H2 sections; `scope/severity` ← LABELS (`_tmr_decode_scope`/
  `_tmr_decode_severity`, NOT from any `Scope:` body line); `type/status` ← labels. **NO
  `extra_fields` key is ever set.** No `Target/Position/Problem/Goal/Out of scope/References`
  decode exists.
- CONCL: SUPPORTED.

**EVIDENCE BLOCK 2.E — reverse `extra_fields` is dead code**
- `CMD`: `grep -nE 'pack-extra-fields' scripts/lib/tracker-migrate-reverse.sh`
- `OUT`: matches ONLY at :706 and :753 — both inside COMMENTS in `_tmr_emit_pack_tree`. The code
  at :758 `extra = e.get("extra_fields", None)` always reads `None` because reconstruct (Block 2.D)
  never sets that key; the comment :755-757 states "absent today until the reverse decode populates
  it — handled defensively." CONCL: SUPPORTED — the emitter's extra-field inliner is unreachable.

**EVIDENCE BLOCK 2.F — validate-pack checks touching entry fields / migration**
- `CMD`: `grep -nE '^def check_' scripts/validate-pack.py` (45 checks); manual inspection of each
  whose name/docstring touches entry structure or migration.
- `OUT`: Checks 32 (`check_mirror_in_sync` :3211 — no-monolith structural guard), 33
  (`check_toc_in_sync` :3345 — `_toc.md` byte-sync), 34 (`check_cross_reference_integrity`
  :3615), 29 (`check_tracker_config` :2794 — tracker.toml schema), 26
  (`check_migrator_framework_inventory` :2276 — the vN→vM VERSION migrator, NOT tracker
  forward/reverse). **No check inspects `tmf_compose_issue_body`, the parser whitelist, or
  forward→reverse content faithfulness.** No check asserts which entry field labels are carried.
- CONCL: SUPPORTED — validate-pack ENFORCES none of the entry field labels' migration fate.

### The reconciliation table

Columns: **(a) in METHODOLOGY template** · **(b) in GH form family** (work-item.yml /
inbound.yml / config.yml) · **(c) carried by FORWARD** (parser whitelist + compose body /
labels) · **(d) reconstructed by REVERSE** · **(e) enforced by validate-pack**.
Cell evidence: (a)=Block 2.A; (b)=`.github/ISSUE_TEMPLATE/*.yml` read in full; (c)=Blocks 2.B/2.C;
(d)=Block 2.D/2.E; (e)=Block 2.F.

| Field label | (a) template | (b) GH form | (c) FORWARD-carried | (d) REVERSE-reconstructed | (e) validate-pack |
|---|---|---|---|---|---|
| `Type:` | YES | YES (`wi-kind` dropdown) | YES → label (`_tmf_labels_for_entry`) | YES (`_tmr_decode_type` ← label) | NO |
| `Status:` | YES | YES (`wi-status` dropdown) | YES → `status:*` label | YES (`_tmr_decode_status`) | NO |
| `Blockers:` | YES | YES (`wi-blockers`) | YES → first-class links | YES (`_tmr_decode_blockers`) | NO |
| `Unblocks:` | YES | YES (`wi-unblocks`) | YES → links | YES (computed inverse, `_tmr_compute_unblocks`) | NO |
| `File/Symbol:` | YES | YES (`wi-file-symbol`) | YES → `## File / Symbol` body | YES (`_tmr_extract_section`) | NO |
| `Description:` | YES | YES (`wi-description`) | YES → `## Description` body | YES (`_tmr_extract_section`) | NO |
| `Context:` | YES | YES (`wi-context`) | YES → `## Context` body | YES (`_tmr_extract_section`) | NO |
| `Resolution:` | YES | YES (`wi-resolution`) | YES → `## Resolution` body | YES (`_tmr_extract_section`) | NO |
| `Resolved:` (pack alias) | (alias of Resolution) | YES (`wi-resolution`) | YES → mapped to `resolution` (parser :475) → `## Resolution` body | YES (as Resolution; re-emitted `Resolved:`) | NO |
| `Scope:` | NO | NO (form has no Scope textarea; `wi-*` set fixed) | **NO** (not in whitelist → dropped) | partial: reverse emits `Scope:` ONLY from a `scope:*` LABEL, never from the dropped `Scope:` line | NO |
| `Target:` | NO | NO | **NO** (dropped) | **NO** (no decode; `extra_fields` dead) | NO |
| `Position:` | NO | NO | **NO** (dropped) | **NO** | NO |
| `Problem:` | NO | NO | **NO** (dropped) | **NO** | NO |
| `Goal:` | NO | NO | **NO** (dropped) | **NO** | NO |
| `Out of scope:` | NO | NO | **NO** (dropped) | **NO** | NO |
| `References:` | NO | NO | **NO** (dropped) | **NO** | NO |
| `Acceptance criteria:` | NO | NO | **NO** (dropped) | **NO** | NO |
| `Encapsulation:` | NO | NO | **NO** (dropped) | **NO** | NO |
| `Surfaced:` | NO | NO | **NO** (dropped) | **NO** | NO |
| `Steps:` | NO | NO | **NO** (dropped) | **NO** | NO |
| `Risk note:` | NO | NO | **NO** (dropped) | **NO** | NO |
| `Quality bar:` | NO | NO | **NO** (dropped) | **NO** | NO |
| `Pipeline:` | NO | NO | **NO** (dropped) | **NO** | NO |
| `Paused:` | NO | NO | **NO** (dropped) | **NO** | NO |
| `Note:` | NO | NO | **NO** (dropped) | **NO** | NO |
| `Disposition:` | NO | NO | **NO** (dropped) | **NO** | NO |
| `Alias:` | NO | NO | **NO** (dropped) | **NO** | NO |
| `Severity:` (not in live BD set; reverse-only) | NO | NO | n/a (no live `Severity:` line) | reverse emits from `severity:*` label only | NO |

NOTE on form-family (b): the work-item form's textareas are EXACTLY `wi-blockers, wi-unblocks,
wi-file-symbol, wi-description, wi-context, wi-resolution` plus dropdowns `wi-type, wi-kind,
wi-status` (verified by reading `.github/ISSUE_TEMPLATE/work-item.yml` in full). There is NO
`pack-extra-fields` field in the form; the form's only HTML-comment markers are `pack-id`,
`template_version`, `pack-version` (:103-105). `inbound.yml` is the second lane (category/
observation/etc.) and carries NONE of the BD entry fields. `config.yml` only sets
`blank_issues_enabled: false` + a discussions link.

**Factual classification (permitted per deliverable 2):**
- **IN-SCHEMA, carried** (9): Type, Status, Blockers, Unblocks, File/Symbol, Description,
  Context, Resolution(+Resolved alias). These are the template set and the carry set — they coincide.
- **NOT-in-schema, NOT carried** (19): Scope, Target, Position, Problem, Goal, Out of scope,
  References, Acceptance criteria, Encapsulation, Surfaced, Steps, Risk note, Quality bar,
  Pipeline, Paused, Note, Disposition, Alias — and `Severity` (reverse-only label decode, no
  live forward line). `Scope` is a special case: dropped on forward as a BODY line, but reverse
  re-emits a `Scope:` line if a `scope:*` LABEL is present — so a live `Scope:` value is still LOST
  (the label path never sees it).

---

## §3 — The definitive DROP SET + worst-case example

**The drop set (19 labels) — entries impacted** (counts from Block 1.8, distinct-per-file):
Scope (11), Target (11), Position (14), Problem (2), Goal (2), Out of scope (10), References (10),
Acceptance criteria (4), Encapsulation (4), Surfaced (2), Steps (1), Risk note (1),
Quality bar (1), Pipeline (1), Paused (1), Note (1), Disposition (1), Alias (1). `Severity`:
0 live forward lines.

**EVIDENCE BLOCK 3.1 — empirical parse of BD-204 through the REAL forward parser**
- `CMD`: source the forward lib; `tail -n +2 backlog/BD-204.md > tmp; printf '\n---\n' >> tmp;
  _tmf_parse_backlog_file tmp | jq '.[0]'`
- `OUT` (the parsed entry object, values truncated):
  `pack_id=BD-204; title=Pack self-migration Phase 2...; type=feat — STRUCTURAL...; status=Open;
   blockers=["Follows BD-203..."]; unblocks=["the pack tracks its OWN backlog..."];
   file_symbol=(empty); description=(EMPTY); context=(empty); resolution=n/a`
- INTERP: BD-204's `Target:`, `Problem:`, `Scope:`, `Out of scope:`, `References:`, `Position:`
  lines produce NO key and are NOT folded into `description` (which is empty). They are gone.
- CONCL: SUPPORTED — silent drop proven against the actual parser.

**EVIDENCE BLOCK 3.2 — WORST-CASE concrete before/after (BD-204, a no-Description entry)**
- `CMD`: source forward lib; `tmf_compose_issue_body "BD-204" "" "" "n/a" ""`
- `OUT` (the ENTIRE migrated Issue body that forward would create):
```
<!-- pack-id: BD-204 -->
<!-- template_version: bd-v11.0 -->
<!-- pack-version: v11 -->

## Description



## Resolution

n/a
```
- BEFORE (the live entry's substantive field lines, from Block 1.8 / `backlog/BD-204.md`):
  `Type:`, `Status:`, `Target:`, `Blockers:`, `Unblocks:`, `Problem:`, `Scope:`, `Out of scope:`,
  `References:`, `Resolved:`, `Position:` — PLUS ~15 multi-line capitalized prose blocks
  (HARD CONSTRAINT / DESIGN BASELINE / REVERSIBILITY / SSOT/MIRROR MODEL / GENERALIZABLE /
  DECISION TIERS / PACK FEEDBACK / CAPABILITY-INFORMED / IMPLEMENTATION CARRY-FORWARD), each of
  which begins with a capitalized label-like token but is body prose.
- AFTER: an Issue whose body is the 3 markers + an EMPTY `## Description` + `## Resolution: n/a`.
  Every `Problem/Scope/Out of scope/References/Target/Position` line AND every multi-line design
  block is GONE. INTERP: BD-204 is the worst case — it has NO `Description:` to even partially
  carry content, so the migrated Issue body is essentially empty of substance. CONCL: SUPPORTED.

**The 11 no-Description entries** (Block 1.7: BD-195, 202-211) all share this worst-case shape —
their substance lives in dropped labels (`Problem:`/`Scope:`/`Goal:`/etc.) and uncarried prose
blocks, so each migrates to a near-empty `## Description`. (BD-195 additionally loses
`Alias:`/`Surfaced:`/`Goal:`/`Scope:`/`Quality bar:`/`Steps:`/`Position:`.)

---

## §4 — Green-CI ROOT CAUSE (first-class)

**EVIDENCE BLOCK 4.1 — what the CI workflow runs**
- `CMD`: `ls .github/workflows/` → `validate-pack.yml` (the ONLY workflow);
  `grep -nE 'tests/.*\.sh' .github/workflows/validate-pack.yml`
- `OUT` (migration/round-trip tests wired into CI): `tracker-migrate-forward-test.sh` (BD-065),
  `tracker-migrate-reverse-test.sh` (BD-068), `tracker-migrate-roundtrip-test.sh` (BD-070), plus
  phase-task/links/cycle/errors/config tests. **`tracker-bd204-lossless-roundtrip-test.sh` is NOT
  in the workflow.**
- CONCL: SUPPORTED.

**EVIDENCE BLOCK 4.2 — the ONLY content-faithfulness test is manual-only + default-SKIP**
- `CMD`: `sed -n '1,50p' scripts/tests/tracker-bd204-lossless-roundtrip-test.sh`
- `OUT`: line 2 `# pack-internal: true (manual/gated live-GH oracle; not a CI test runner)`;
  lines 41-45: if `PACK_TRACKER_LIVE_GH` unset/empty OR `gh` absent OR `gh auth status` not OK →
  `echo "SKIP..."; exit 0`. Header :13-23 states it is "NOT wired into any .github/workflows/ file
  or any unattended run-all test list."
- INTERP: in CI (`PACK_TRACKER_LIVE_GH` unset) this test SKIPs at line 43 and exits 0 before any
  assertion. CONCL: SUPPORTED — the only test with a content-faithfulness leg never executes in CI.

**EVIDENCE BLOCK 4.3 — even if it ran, its FIXTURE cannot catch the drop**
- `CMD`: `grep -oE '^[A-Z][A-Za-z/ -]+:' scripts/tests/fixtures/tracker-bd204-lossless/BACKLOG.md
  | sort | uniq -c` ; `grep -nE '^(Scope|Problem|Goal|Target|Position|Out of scope|References|Acceptance criteria):' .../BACKLOG.md`
- `OUT`: fixture labels = ONLY `Type, Status, Blockers, Unblocks, File/Symbol, Description,
  Resolved` (3 each, for BD-901/902/903). Second grep → NO match ("NONE — fixture has no separate
  top-level extension fields").
- INTERP: the fixture's "large multi-block entry" BD-903 deliberately puts its
  `Segments:/Steps:/State:/Goal:/Scope:` content INSIDE the `Description:` field (the test's own
  comment :211-213: "rides the Description field verbatim"). So leg-3 content-faithfulness
  (test :216-224, `diff` orig vs recon) passes — the fixture never carries a TOP-LEVEL dropped
  field. CONCL: SUPPORTED — the oracle's fixture is constructed around the carry set; it cannot
  exercise the drop set even if un-skipped.

**EVIDENCE BLOCK 4.4 — the CI-wired round-trip + forward tests assert structure, not field-completeness, on carry-set-only fixtures**
- `CMD`: `find scripts/tests/fixtures/roundtrip -name BACKLOG.md` + `grep -oE '^[A-Z][A-Za-z/ -]+:'`;
  `grep -nE 'Scope:|Problem:|Goal:|Target:|Position:' scripts/tests/tracker-migrate-roundtrip-test.sh`;
  `grep -nE 'Scope:|Problem:|Goal:|Target:|Position:' scripts/tests/tracker-migrate-forward-test.sh`
- `OUT`: roundtrip fixture `fixtures/roundtrip/bd-v11.0/BACKLOG.md` labels = ONLY the 7 carry-set
  labels (4 each). Roundtrip test "Group 4: BD-204 NO sidecar (DP-2)" (:627-660) asserts only
  (4.1) NO sidecar file is written and (4.2) the tree materializes — it does NOT diff field
  content. forward-test → no Scope/Problem/Goal/Target/Position assertions. The roundtrip test's
  documented property (:9) is "Zero diff (whitespace-tolerant) on v10 grammar" — and the v10
  grammar IS the carry set, so a clean diff is guaranteed.
- INTERP: the two CI-wired tests round-trip cleanly because their fixtures contain ONLY carried
  fields; nothing dropped is present to diff. CONCL: SUPPORTED.

**EVIDENCE BLOCK 4.5 — no validate-pack check asserts field-completeness or faithfulness**
- Per Block 2.F: no check inspects the parser whitelist, `tmf_compose_issue_body`, or
  forward→reverse field content. CONCL: SUPPORTED.

**THE EXACT MISSING ASSERTION.** Green CI is the conjunction of four independent gaps:
1. The only content-faithfulness oracle (`tracker-bd204-lossless-roundtrip-test.sh`) is
   manual-only + default-SKIP → never runs in CI (Block 4.2).
2. That oracle's fixture, and BOTH CI-wired fixtures (`roundtrip/`, forward-test), contain ONLY
   the 9 carry-set fields → no fixture carries a droppable field (Blocks 4.3, 4.4).
3. The CI-wired round-trip test asserts structure (no-sidecar, tree-materializes) and a v10-grammar
   diff, NOT field-by-field faithfulness against the REAL backlog (Block 4.4).
4. No validate-pack check measures forward field-completeness (Block 4.5).
- The single missing assertion that would have caught the lossy migration: **a forward→reverse
  content-faithfulness check that runs in CI against the REAL `/backlog/` tree (all 211 entries),
  asserting every top-level field label present BEFORE is present AFTER** (or, equivalently, that
  the parser carry-whitelist covers every label the live tree contains). Such an assertion does
  not exist on any surface. CONCL: SUPPORTED.

**Design-vs-code divergence (factual).** ARCHITECTURE-BD-204 §2.4/§2.4.1/§2.4.2 CLAIMS a
`pack-extra-fields` HTML-comment block carrier (Target/Position as named scalars; Scope/Goal/
Problem/Out-of-scope/References riding the Issue body) and asserts "zero orphaned fields"
(:503-520). EVIDENCE: the forward migrator emits NO such block (`grep -nE 'pack-extra-fields|
Target|Position|extra_fields' scripts/lib/tracker-migrate-forward.sh` → ZERO matches), and the
reverse references it in COMMENTS only (Block 2.E). The §2.4.2 "zero-orphaned-fields" claim is a
DESIGN claim that the code does not implement. CONCL: SUPPORTED (factual divergence; no fix proposed).

---

## §5 — Generalizability to project-side TD entries

**EVIDENCE BLOCK 5.1 — project-side TD entries share the canonical schema**
- `CMD`: `Read project-template/docs/project/backlog/_rules.md`; `sed -n '1199,1216p'
  supporting-docs/METHODOLOGY.md`
- `OUT`: project `_rules.md` :19 "One v10-grammar TD entry per file"; :43-44 points writers to
  "METHODOLOGY.md Part 7" — the SAME canonical template (Type/Status/Blockers/Unblocks/
  File-Symbol/Description/Context/Resolution). CONCL: SUPPORTED — project TD entries use the same
  schema as pack BD entries.

**EVIDENCE BLOCK 5.2 — the migrator parser admits BD and TD identically**
- `CMD`: `grep -nE 'BD\|TD' scripts/lib/tracker-migrate-forward.sh`
- `OUT`: parser `ENTRY_HEADER = re.compile(r'^\*\*((?:BD|TD)-\d{3})...')` (:387); the whitelist
  (Block 2.B) is prefix-agnostic. INTERP: a TD entry runs through the identical parser/compose/
  reverse path; the same 19-label drop set applies. CONCL: SUPPORTED.

**EVIDENCE BLOCK 5.3 — current project TD fixtures stay within the carry set (so no drop TODAY)**
- `CMD`: `for f in test-fixtures/v11-realistic-ot/docs/project/backlog/TD-*.md; do grep -oE
  '^[A-Z][A-Za-z/ -]+:' "$f" | sort -u; done`; `grep -oE '^[A-Z][A-Za-z/ -]+:'
  test-fixtures/v11-realistic-ot/docs/project/BACKLOG.md | sort | uniq -c`
- `OUT`: every TD fixture uses ONLY `Type, Status, Blockers, Unblocks, File/Symbol, Description,
  Resolved` (the 9 carry-set fields). CONCL: SUPPORTED.

**FACTUAL GENERALIZABILITY STATEMENT.** Project-side TD entries share the identical canonical
METHODOLOGY Part 7 schema and run through the SAME forward/reverse code (BD-204 designs the
machinery to be reused unchanged by BD-207 — `BD-204.md` :12, GENERALIZABLE property). Therefore
the gap is STRUCTURALLY identical for project TD entries: any TD entry that adds a top-level field
beyond the 9-field template (e.g. `Scope:`/`Goal:`/`Target:`) would be dropped the same way. It is
NOT triggered by the current realistic-ot TD fixtures because they stay within the template; it
IS triggered today on the PACK side because pack BD entries (BD-195, BD-202..211, etc.) added
top-level extension fields beyond the template. (No design implication stated — fact only.)

---

## Rules-Applied Verification Block

| Rule | Verification evidence (actual) | Conclusion |
|---|---|---|
| `agents-never-commit` | No `git add/commit/push/tag` issued; only Read/Bash(read-only measurement)/one Write to the report path. `git rev-parse HEAD` was read-only. | COMPLIANT |
| `per-action-approval-sub-agents` | No destructive op attempted; the live-GH oracle was READ, never executed (no `PACK_TRACKER_LIVE_GH` set, no `gh repo create`). No live GH touched. | COMPLIANT |
| `researcher-maps-blast-radius` | §1 censuses ALL 211 entries, ALL 28 labels, with COMPLETE per-entry lists (Block 1.8); reconciled THREE ways (Blocks 1.3/1.4/1.5/1.6) closing exactly (1527=1527, 1514+13=1527); every label categorized in §2 table. | COMPLIANT |
| `empirical-evidence-blocks` | Every state-claim carries CMD + verbatim OUT + HEAD `feaa45d` + 2026-06-06 + INTERP + CONCL (Blocks 1.1-1.8, 2.A-2.F, 3.1-3.2, 4.1-4.5, 5.1-5.3). | COMPLIANT |
| `ci-guard-measure-then-bound` | Captured the COMPLETE occurrence set (Block 1.2 all 28 labels; Block 1.8 all entry lists), not a sample; classified every label KEEP/STRIP-equivalent (carry vs drop) in §2. MEASURE step only; no guard designed. | COMPLIANT |
| `verify-availability-not-just-existence` | Form-family verified against the ACTUAL `.yml` files (read in full — wi-* set enumerated, Block 2.A note); code behavior verified against the ACTUAL parse→emit path by RUNNING the real parser/composer on BD-204 (Blocks 3.1/3.2), not assumption. | COMPLIANT |
| `scope-deliverables-to-the-ask` | Exactly 5 deliverables delivered (§1-§5); no fix/design proposed; factual classification only. | COMPLIANT |
| `filename-uniqueness-heuristic` | `find . -name RESEARCH-BD-204-LOSSLESS-FIELD-CENSUS.md -not -path './.git/*'` returned no path before write (Bash call 1). | COMPLIANT |
| `rules-applied-verification-block` | This table. | COMPLIANT |

## READ-IN-FULL attestation

Read directly and in full (no derivation): `backlog/_rules.md`; `backlog/BD-204.md`;
`.github/ISSUE_TEMPLATE/work-item.yml`, `inbound.yml`, `config.yml`;
`scripts/lib/tracker-migrate-forward.sh` (the parser :382-495, compose :601-630,
`_tmf_labels_for_entry` :1501-1534, orchestrator + read-side :719-826, plus :1-1167 page 1 and
targeted reads of the labels region — the migration-relevant spans);
`scripts/lib/tracker-migrate-reverse.sh` (reconstruct :523-599, emit :627-823, header/decode map
via grep + targeted reads); `scripts/validate-pack.py` (all 45 `def check_` names + docstrings +
targeted reads of Checks 26/29/32/33/34 regions);
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md` §2.4/§2.4.1/§2.4.2 (read via targeted
grep+sed of the cited spans); `supporting-docs/METHODOLOGY.md` Part 7 :1148-1233;
`project-template/docs/project/backlog/_rules.md`; the workflow `.github/workflows/validate-pack.yml`
test list; the test scripts `tracker-bd204-lossless-roundtrip-test.sh` (full),
`tracker-migrate-roundtrip-test.sh` (header + Group 4), `tracker-migrate-forward-test.sh` (grep);
the fixtures under `scripts/tests/fixtures/tracker-bd204-lossless/`, `.../roundtrip/`, and the
realistic-ot project TD fixtures. Curated memory files named in the prompt + CLAUDE.md "## Pack
memory" were carried as governing rules (reflected in the Rules-Applied block).

NOTE (surfaced, not resolved — scope-deliverables): `ARCHITECTURE-BD-204-POST-BD211-RECON.md` was
referenced in the prompt; this report read the ARCHITECTURE-BD-204.md §2.4 census claim directly
and reconciled it against code/entries (the divergence in §4). The RECON doc's claims were not
separately quoted — flagged for the architect, not a finding here.
