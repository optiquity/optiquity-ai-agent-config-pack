# IMPL-REPORT-BD-204-C-DOCS-FIX1 — review-fix pass for the C-DOCS reconciliation

> **Fix-coder report.** Branch: `v11-dev`. HEAD: `c7f9af6a575af00baaea0cb6e02261e141be5bfe`
> (unchanged — no git state-changing verb run; the fix folds into the uncommitted C-DOCS
> working-tree change). Date: 2026-06-10.
> **Input:** `PACK-REVIEW-BD-204-C-DOCS.md` (APPROVE-WITH-FIXES; 1 MUST, 2 SHOULD, 3 NIT;
> user-approved FIX-ALL).
> **Scope held:** the ONLY content file edited is
> `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md`; this report is the only new file.

## Summary

All six findings fixed via targeted in-place edits; untouched sections byte-stable. Every edit
was grounded by a read-only verification of the as-built code it describes BEFORE writing.
Verification: `python3 scripts/validate-pack.py` PASS, `PACK_VALIDATE_DEEP=1` PASS, and the full
46-script unattended battery from `.github/workflows/validate-pack.yml` PASS (46/46). The live
oracle (`tracker-bd204-lossless-roundtrip-test.sh`) was NOT invoked (default-SKIP; it has no
unattended workflow `run:` line). Line-number sweep over all added diff lines: clean.

## Per-finding record

### MUST-1 — §2.1 step 2 phantom symbol + stale line ref

**Code evidence:** `grep -n "tracker_migrate_reverse_reconstruct" scripts/lib/tracker-migrate-reverse.sh`
→ definition `tracker_migrate_reverse_reconstruct()` exists (the reverse orchestrator calls it as
`rec=$(tracker_migrate_reverse_reconstruct "$issue" "$mapping" "$force")`). No
`_tmr_reverse_reconstruct` symbol exists.

**Before:**
```
2. For each Issue, `_tmr_reverse_reconstruct` (`tracker-migrate-reverse.sh:506`) builds an
   in-memory entry object
```
**After:**
```
2. For each Issue, `tracker_migrate_reverse_reconstruct` (`scripts/lib/tracker-migrate-reverse.sh`)
   builds an in-memory entry object
```
File + symbol, no line number, per the pass's own convention.

### SHOULD-1 — §2.4.2 batch-codec attribution restated as-built

**Code evidence (all read-only this session):**
- Production forward: `tmf_compose_issue_body` emits the blob via
  `blob=$(printf '%s' "$raw_body" | _tmf_gz64_encode)` (single-record).
- Production reverse: `tracker_migrate_reverse_reconstruct` decodes via
  `raw_body=$(printf '%s' "$body" | _tmr_decode_body_blob ...)` (single-record).
- `_tmf_gz64_encode_batch` / `_tmr_decode_body_blob_batch` carry explicit "ADDITIVE … NOT a
  behavior change to the single-record …" comments in the SAME lib files.
- Equivalence tests: `scripts/tests/tracker-migrate-forward-test.sh` cases 2.9.1 (gz64 batch ==
  single-record), 2.9.2 (neutralizer), 2.9.3 (composer), 2.9.4 (single-record byte-unchanged
  additive invariant); `scripts/tests/tracker-migrate-reverse-test.sh` cases 2.1e-i (batch decode
  == single decode) and 2.1e-ii (batch decode(encode(x)) == x). Cited by test-case ID, not line.
- `scripts/validate-pack.py`: Check 49 header — "drives the SINGLE-SOURCED batch codec … NOT a
  reproduced codec (OQ-4)"; Check 50 header — FAILs CI if a reproduced gz64/base64 codec is
  (re)introduced into validate-pack.py; "Check 49 instead sub-invokes the SHARED BATCH codec."

**Before (the literally-false parenthetical):**
```
(`_tmf_gz64_encode_batch` / `_tmr_decode_body_blob_batch` — the SAME functions the production
migration uses, so no second codec can drift and FALSE-PASS a lossy change): the byte-faithful
```
**After (as-built guard chain):**
```
(`_tmf_gz64_encode_batch` / `_tmr_decode_body_blob_batch` — the ADDITIVE batch siblings of the
single-record `_tmf_gz64_encode` / `_tmr_decode_body_blob` the production migration calls,
sourced from the SAME migrator lib files; batch and single-record are equivalence-bound by
per-commit byte-identity tests — forward `tracker-migrate-forward-test.sh` cases 2.9.1–2.9.4
(gz64 / neutralizer / composer batch == single-record, plus the single-record-byte-unchanged
additive invariant) and reverse `tracker-migrate-reverse-test.sh` cases 2.1e-i/ii (batch decode
== single-record decode; batch decode(encode(x)) == x) — and Check 50 (the OQ-4 single-source
codec guard, `scripts/validate-pack.py`) FAILs CI if validate-pack.py itself reproduces the
codec, so no second codec can drift and FALSE-PASS a lossy change): the byte-faithful
```

### SHOULD-2 — end-of-§1 "DECISION POINTS summary" blockquote dispositioned

The dated 2026-06-06 summary blockquote stays byte-stable. Adjoined immediately after it (DP-2
note style):
```
> **As-built note (reconciled 2026-06-10, C-DOCS review-fix pass).** The summary's DP-2 line
> above is the dated 2026-06-06 decision record verbatim; its "in-body `pack-extra-fields`
> block" phrase describes the superseded pre-fix realization. The as-built in-body carrier is
> the `pack-entry-body-gz64` verbatim-body blob (§2.4.1 as-built); disposition in the §7
> reconciliation ledger.
```
AND the blockquote was added to §7's "Dated records intentionally left byte-stable" disposition
list (see "§7 ledger updates" below).

### NIT-1 — §2.4.1 comparator enumeration corrected

**Code evidence:** the as-built `norm()` inside `_tmr_check_blob_h2_divergence`
(`scripts/lib/tracker-migrate-reverse.sh`) does `s.replace("\r\n", "\n").replace("\r", "\n")`,
and the adjacent shell comment reads "Normalize BOTH sides identically (CRLF/CR → LF; …)".

**Before:** `…the normalization-tolerant comparator: CRLF→LF, per-line trailing-whitespace
strip, single trailing newline — exactly GH's munging, no broader…`
**After:** `…the normalization-tolerant comparator: CRLF/CR→LF, per-line trailing-whitespace
strip, single trailing newline — exactly GH's munging, no broader…`
(One-token fix using the code's own comment wording; with bare-CR included the enumeration is
accurate, so "no broader" now holds.)

### NIT-2 — two carried-over `file:line` refs re-anchored by section/field

**Code/doc evidence:** `ARCHITECTURE-V3.3-DELTA.md` §6.1 contains the D-17 statement ("structured
iff a finite enum drives a label, sub-issue parent, or state transition; otherwise textarea") —
the content the old `:312` pointed at. `backlog/BD-204.md` DECISION TIERS HARD bullet contains
"full-CRUD true-SSOT" — the content the old `:14` pointed at.

**§2.4 boundary principle — before/after:**
```
(D-17, `ARCHITECTURE-V3.3-DELTA.md:312`)  →  (D-17, `ARCHITECTURE-V3.3-DELTA.md` §6.1)
```
**§2.4.1 carrier paragraph — before/after:**
```
(HARD true-SSOT, `backlog/BD-204.md:14`)
  →  (HARD true-SSOT, the `backlog/BD-204.md` DECISION TIERS HARD bullet)
```
(Plus a two-line rewrap of the continuation sentence so no stub line was left mid-paragraph;
wording unchanged.) The third `backlog/BD-204.md:14` occurrence (§2.4.1 "Why the sidecar is
dropped") sits in UNCHANGED pre-C-DOCS context — per the reviewer's sweep only the two refs
inside rewritten as-built prose were in scope; it stays byte-stable.

### NIT-3 — §5 audit-row forward-pointer

The dated §5 table (including the "Pattern-matching out of context" row) stays byte-stable.
Adjoined immediately after the §5 table, before the READ-IN-FULL attestation subsection:
```
> **As-built note (reconciled 2026-06-10, C-DOCS review-fix pass).** The "Pattern-matching out
> of context" row above is the dated 2026-06-05 audit record verbatim; its "in-body
> `pack-extra-fields` block" carrier claim describes the superseded pre-fix realization. The
> as-built carrier is the `pack-entry-body-gz64` verbatim-body blob (§2.4.1 as-built);
> disposition in the §7 reconciliation ledger.
```

### §7 ledger updates (caller-directed companion edit)

1. The "Dated records intentionally left byte-stable" paragraph now names the end-of-§1
   "DECISION POINTS summary" blockquote (SHOULD-2) and the §5 "Pattern-matching out of context"
   row (NIT-3), each with its adjoining-note disposition.
2. A "Review-fix pass (2026-06-10, per `PACK-REVIEW-BD-204-C-DOCS.md`; folded into this commit)"
   paragraph was appended after the §7 rules table, recording all six fixes and stating that the
   file+symbol/never-line-numbers claim now holds for every reconciled claim.
3. The §7 "Edit-in-place" rule row was aligned (it had claimed §5 wholly byte-stable; it now
   reads "§5 (dated table rows; an as-built note adjoins the table per the review-fix pass)") —
   this avoids the fix pass introducing a fresh internal inconsistency. §7 is this commit's live
   ledger, not a dated record, so editing it in place is the correct treatment.

## Verification evidence

1. **Validator (general path):** `python3 scripts/validate-pack.py` →
   `PASSED — all checks clean` (Check 48 advisory WARNs only; Check 50 OK; Check 49 SKIP as
   designed without the deep gate).
2. **Validator (deep path):** `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` → PASS
   (log: `/tmp/bd204fix-deep.log`).
3. **Full unattended battery** (every `run: bash scripts/tests/...` line in
   `.github/workflows/validate-pack.yml` — 46 scripts): **46/46 PASS** (summary:
   `/tmp/bd204fix-battery-summary.txt`; per-test logs `/tmp/bd204fix-<test>.log`). Includes
   `tracker-migrate-forward-test.sh` (the 2.9.x equivalence cases SHOULD-1 cites),
   `tracker-migrate-reverse-test.sh` (the 2.1e cases), and
   `test-validate-pack-check-49-field-faithfulness.sh`.
4. **Live oracle:** `tracker-bd204-lossless-roundtrip-test.sh` NOT invoked — default-SKIP per the
   caller's instruction; it carries no unattended workflow `run:` line.
5. **Line-number sweep (success criterion):**
   `git diff … | grep -E '^\+' | grep -E ':[0-9]{2,}'` → zero matches ("SWEEP CLEAN") — no new
   line-number references anywhere in the added lines; the two carried-over refs are gone.
6. **End-state `git status --short`:** exactly
   `M maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md` + the two pre-existing
   untracked reports (`IMPL-REPORT-BD-204-C-DOCS.md`, `PACK-REVIEW-BD-204-C-DOCS.md`) + this
   report. HEAD unchanged at `c7f9af6`.
7. **Manifest regen:** NOT owed — the diff touches only `maintenance-docs/` (not v11-surface:
   no `project-template/`, `scripts/`, `pack-ops/`, or `supporting-docs/` file in the diff).

## Boundary discipline check

No project-side file touched. The single content edit is a pack-internal maintenance-doc
(`maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md`); `pack-only` holds (BD-204 HARD
constraint). No boundary-discipline stop triggered; no project-side SSOT investigation owed.

## Plan deviations

None against the six approved fixes. Two implementation notes (both within the caller's stated
scope, recorded for transparency):
- A two-line rewrap accompanying the NIT-2 `backlog/BD-204.md` re-anchor (no wording change) to
  keep the paragraph cleanly wrapped.
- The §7 "Edit-in-place" row alignment (item 3 under "§7 ledger updates") — a consequence of
  NIT-3's adjoining note, folded into the caller-directed "update the §7 ledger so it reflects
  the fix pass" instruction.

## New POQs

None.

## Definition of Done

| Item | Status |
|---|---|
| MUST-1 applied; symbol verified against `scripts/lib/tracker-migrate-reverse.sh` | PASS |
| SHOULD-1 applied; guard chain verified against forward/reverse libs + tests + Check 49/50 | PASS |
| SHOULD-2 applied; dated blockquote byte-stable; §7 disposition added | PASS |
| NIT-1 applied; matches as-built `norm()` | PASS |
| NIT-2 applied; both refs re-anchored by section/field | PASS |
| NIT-3 applied; dated §5 row byte-stable | PASS |
| §7 ledger reflects the fix pass | PASS |
| No new line-number refs in any added line (sweep) | PASS |
| `python3 scripts/validate-pack.py` green | PASS |
| `PACK_VALIDATE_DEEP=1` validator green | PASS |
| Full 46-script unattended battery green | PASS |
| Live oracle untouched (default-SKIP) | PASS |
| Scope: only `ARCHITECTURE-BD-204.md` + this report written | PASS |
| No state-changing git verb run | PASS |

## Files changed

| Path | Change type |
|---|---|
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md` | modified (fix pass folded into the uncommitted C-DOCS change; cumulative working-tree diff now +296/−76) |
| `maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-C-DOCS-FIX1.md` | new (this report) |

**End of IMPL-REPORT-BD-204-C-DOCS-FIX1.md**
