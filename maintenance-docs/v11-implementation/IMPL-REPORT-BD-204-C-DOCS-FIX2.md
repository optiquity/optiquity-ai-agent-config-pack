# IMPL-REPORT-BD-204-C-DOCS-FIX2 — fix-coder pass 2 (FINAL): NIT-1 + NIT-2

> **Agent:** pack-coder (FRESH fix-coder, pass 2 of the bounded cycle). **Date:** 2026-06-10.
> **Branch:** `v11-dev`. **HEAD:** `c7f9af6a575af00baaea0cb6e02261e141be5bfe` (unchanged —
> read-only git verbs only). **Scope:** the two user-approved NIT fixes from
> `PACK-REVIEW-BD-204-C-DOCS-REVIEW2.md`, applied as targeted in-place edits to
> `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md` (folding into the same
> UNCOMMITTED C-DOCS working-tree change). Nothing else edited.

## Summary

- **2/2 approved fixes applied** (NIT-1 §3.4 attribution; NIT-2 §7 ledger entry), plus one
  cosmetic reflow of my own NIT-2 insertion's line wrap (same sentence, same bytes of content).
- Diff moved from the reviewed +296/−76 to **+304/−76** (net +8 lines = NIT-1 +5, NIT-2 +3);
  hunk count unchanged at **16** — both fixes folded into existing hunks; no new hunks, no
  section dropped (section map re-verified: 37 headers, tail `**End of ARCHITECTURE-BD-204.md**`
  intact).
- **Verification: 57/57 battery commands PASS** (both validate-pack invocations incl. the
  `PACK_VALIDATE_DEEP=1` Check-49 leg + all 55 remaining workflow commands; 2 `pip install`
  lines skipped — PyYAML native). Zero FAIL.
- Scope end-state: exactly ` M ARCHITECTURE-BD-204.md` + the four pre-existing untracked C-DOCS
  reports + this report. `pack-only` holds; `git diff test-fixtures/manifest.txt` empty (not
  v11-surface; rebuild confirmed zero drift).

## Files changed (this pass)

| Path | Change type |
|---|---|
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md` | modified (2 targeted in-place edits + 1 reflow of own insertion) |
| `maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-C-DOCS-FIX2.md` | new (this report) |

## Fix 1 — NIT-1: §3.4 unit-leg attribution (disposal-contract closing sentence)

**Finding (REVIEW2 NIT-1):** "the unit-level legs also run unattended in the battery" misreads
as if the ORACLE's own legs run unattended; as-built the oracle default-SKIPs unattended. The
spec's clarifying parenthetical was dropped.

**Evidence consulted before editing (read-only):**

- Oracle SKIP behavior — `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh`, the
  DEFAULT-SKIP GUARD block ("the FIRST action"): if `PACK_TRACKER_LIVE_GH` is unset OR `gh` is
  absent OR `gh auth status` fails, it prints
  `SKIP: live-GH oracle (set PACK_TRACKER_LIVE_GH=1 + gh auth to run)` and `exit 0` — BEFORE any
  assertion. ALL its legs (drop-set/size/pacing/neutralization/corrupt-blob/comparator included)
  are behind that guard.
- Workflow wiring — `grep -n "bd204-lossless-roundtrip" .github/workflows/validate-pack.yml`
  → exit 1 (zero references; the oracle has no `run:` line).
- Spec phrasing — `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` §5.c "CI-execution model" bullet (read
  in full, lines 1314–1413 region): "…the pacing/neutralization/size/corrupt-blob/preflight
  assertions that DON'T need live GH (the unit-level legs) ALSO run in the unattended battery
  **(the in-process check or a mock-based unit test)**, so CI tests them even though the full
  live round-trip stays manual."
- Actual unattended carriers — `scripts/tests/tracker-migrate-forward-test.sh` (2.8.x gz64/
  determinism, 2.8.4 neutralization; pacing/size cases present per the same suite),
  `scripts/tests/tracker-migrate-reverse-test.sh` (2.1b corrupt-blob fail-loud, 2.1d/2.1d-i/ii
  comparator), `scripts/tests/test-validate-pack-check-49-field-faithfulness.sh` — all three
  carry workflow `run:` lines (battery items 10, 11, 34; all PASS this session).

**Before** (§3.4, end of "Disposal contract" paragraph):

```
no-`gh repo delete` grep-guard), alongside its drop-set / size / pacing / autolink-neutralization
/ corrupt-blob / normalization-comparator legs — the unit-level legs also run unattended in the
battery while the live round-trip stays manual.
```

**After:**

```
no-`gh repo delete` grep-guard), alongside its drop-set / size / pacing / autolink-neutralization
/ corrupt-blob / normalization-comparator legs. The live round-trip — the oracle itself, ALL its
legs included — stays manual + default-SKIP unattended (CI-execution model below); the SAME
unit-level contracts are covered unattended in the battery via "the in-process check or a
mock-based unit test" (`ARCHITECTURE-BD-204-LOSSLESS-FIX.md` §5.c): the Check-49 per-check test
(`test-validate-pack-check-49-field-faithfulness.sh`) plus the mock-based
`tracker-migrate-forward-test.sh` (pacing / size / neutralization legs) and
`tracker-migrate-reverse-test.sh` (corrupt-blob / comparator legs).
```

This restores the spec's dropped precision (the §5.c parenthetical quoted verbatim) and names
the actual unattended carriers by test FILE (no line numbers, no test-case IDs that could
drift). Consistent with the immediately-following "C-7 CI-execution model — MANUAL-ONLY"
sub-section, which already states the SKIP mechanics.

## Fix 2 — NIT-2: §7 byte-stable disposition ledger gains the §2.4.1 DP-2 blockquote

**Finding (REVIEW2 NIT-2):** the §7 "Dated records intentionally left byte-stable" list omits
the §2.4.1 "RESOLVED, FIXED constraint (user 2026-06-06)" blockquote — the third surviving
dated `pack-extra-fields` record, whose supersession is carried by the adjacent as-built
paragraph.

**Evidence consulted:** ARCHITECTURE-BD-204.md §2.4.1 — the blockquote ("> **RESOLVED, FIXED
constraint (user 2026-06-06).** DROP the `.pack-tracker/reverse.sidecar.*` … in-body
`pack-extra-fields` HTML-comment block …") is unchanged context in the diff; the
immediately-following "**The carrier, stated once (AS-BUILT — reconciled 2026-06-10 …
supersedes the `pack-extra-fields` named-scalar block …)**" paragraph sits in the same
subsection and carries the supersession.

**Before** (§7 disposition list, after the end-of-§1 summary item):

```
own adjoining as-built note added by the review-fix pass — SHOULD-2), the §2.4.2 EE `CMD`/`OUT`
(a real input census), the `template_version` EE `CMD` string, §5 (the 2026-06-05 Rules-Applied
```

**After** (one ledger entry inserted, same style as the existing entries — record named +
parenthetical naming where its supersession lives):

```
own adjoining as-built note added by the review-fix pass — SHOULD-2), the §2.4.1 "RESOLVED,
FIXED constraint (user 2026-06-06)" blockquote (its supersession is carried by the
immediately-following "carrier, stated once (AS-BUILT …)" paragraph in the same subsection),
the §2.4.2 EE `CMD`/`OUT` (a real input census), the `template_version` EE `CMD` string, §5
(the 2026-06-05 Rules-Applied
```

(The trailing two lines are the reflowed continuation of the pre-existing sentence — content
byte-identical, wrap only.)

## Edit-in-place verification

- Re-read both edited regions after editing (actual re-read evidence: §3.4 lines 991–1006 and
  §7 lines 1234–1247 printed and inspected — both fixes present, prose coherent).
- Section map: `grep -c "^## \|^### \|^#### "` = **37** headers (identical to pre-edit map);
  document tail `**End of ARCHITECTURE-BD-204.md**` intact.
- `git diff | grep -c '^@@'` = **16** hunks (unchanged from the reviewed diff); `--stat` =
  `+304/−76` (reviewed: +296/−76; delta = exactly the two fixes).
- Reference hygiene: sweep of ADDED lines for `(\.md|\.sh|\.py|\.yml):[0-9]` (excluding the
  three reviewer-adjudicated pre-existing refs) → **zero** hits; my added text names files and
  spec sections only, never line numbers or test-case IDs.

## Verification evidence (full CI suite, per `verify-full-ci-suite`)

All `run:` commands extracted from `.github/workflows/validate-pack.yml` (59 lines → 57
executable + 2 `pip install` skipped as PyYAML is native), executed sequentially:

```
grep -c '^PASS' /tmp/bd204fix2-results.txt  →  57
grep '^FAIL'    /tmp/bd204fix2-results.txt  →  (none) "NO FAILURES"
```

Key rows: `[2] python3 scripts/validate-pack.py` PASS; `[3] PACK_VALIDATE_DEEP=1 python3
scripts/validate-pack.py` PASS (Check-49 deep leg green); `[34]
test-validate-pack-check-49-field-faithfulness.sh` PASS; `[51] test-fixtures/build.sh --all
--clean` PASS + `[53] --verify` PASS (manifest diff after rebuild = 0 lines — maintenance-docs
is not v11-surface; no manifest staging owed). Per-command logs at `/tmp/bd204fix2-log-N.txt`;
results at `/tmp/bd204fix2-results.txt`. The live oracle was NOT invoked
(`PACK_TRACKER_LIVE_GH` never set; it has no workflow `run:` line — default-SKIP honored).

## Scope / end-state

`git status --porcelain` at completion:

```
 M maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md
?? maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-C-DOCS-FIX1.md
?? maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-C-DOCS.md
?? maintenance-docs/v11-implementation/PACK-REVIEW-BD-204-C-DOCS-REVIEW2.md
?? maintenance-docs/v11-implementation/PACK-REVIEW-BD-204-C-DOCS.md
```

plus this report. No `project-template/`, no `supporting-docs/`, no script/entry/fixture
touched. Plan deviations: **none** (the cosmetic reflow of my own NIT-2 insertion is wrap-only
within the inserted sentence, not a third edit). New POQs: **none**.

## Boundary discipline check

No project-side file edited or scoped (the single content edit is
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md`, a pack-internal design record).
No SSOT investigation owed; no boundary stop triggered.

## Definition of Done

| Item | Status |
|---|---|
| NIT-1 §3.4 attribution clarified, spec parenthetical restored, SKIP behavior verified against oracle source | PASS |
| NIT-2 §7 ledger entry added in existing style | PASS |
| Targeted edits only; section map intact; untouched text byte-stable (16 hunks, no new hunks) | PASS |
| Full CI battery green (57/57; deep validate-pack incl.) | PASS |
| Scope end-state pack-only, single modified tracked file | PASS |
| Report written with Rules-Applied block | PASS |

## Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| `agents-never-commit` | Git verbs this session: `git rev-parse HEAD`, `git status --porcelain` (×2), `git diff`/`--stat` (read-only), plus battery item `[52] git checkout HEAD -- test-fixtures/manifest.txt` (the permitted `git checkout -- <path>` content-restore form, a CI-workflow step). No `add`/`commit`/`push`/`tag`. Final `git rev-parse HEAD` = `c7f9af6a575af00baaea0cb6e02261e141be5bfe` (unchanged). | COMPLIANT |
| `per-action-approval-sub-agents` | Zero `rm -rf` / `git rm` / trusted-file overwrites on my own authority; battery logs written to `/tmp` only; `test-fixtures/build.sh --clean` is the sanctioned CI fixture harness operating on its own managed outputs (workflow line `[51]`, PASS, manifest diff 0). No live `gh` mutation (`PACK_TRACKER_LIVE_GH` never set). | COMPLIANT |
| `preflight-stop-means-stop` | Emitted verbatim before this Write: `PREFLIGHT: 2/2 fixes complete; verification PASS; HEAD c7f9af6a575af00baaea0cb6e02261e141be5bfe; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-C-DOCS-FIX2.md`. No parent stop message received at any point. | COMPLIANT |
| `agent-output-rules-applied-block` | This table: one row per prompt-listed rule, quoted commands/outputs/counts as evidence, terminal conclusions only. Conditional MUST-READ honored: `pack-ops/PACK-MEMORY-RATIONALE.md` § `rules-applied-verification-block` (lines 206–233 incl. the fenced format template) read before constructing this block. | COMPLIANT |
| `agents-read-rule-docs-in-full` | Direct full Reads this session: (1) `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md` 580/580 lines incl. the complete `## Pack memory` section; (2) `PACK-REVIEW-BD-204-C-DOCS-REVIEW2.md` 179/179; (3) `feedback_edit_in_place_not_full_rewrite.md` 15/15; (4) `feedback_verify_full_ci_suite.md` 43/43; (5) `feedback_agent_output_rules_applied_block.md` 15/15. Plus the scoped section reads the prompt names: `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` §5.c C-7-rebuild section read fully (lines 1314–1413; whole-spec read expressly not required by the prompt), and the target doc's §2.4.1/§3.4/§7 + section map. No named doc derived rather than read. | COMPLIANT |
| `verify-full-ci-suite` | Ran `python3 scripts/validate-pack.py` AND `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` AND every remaining executable `run:` command from `.github/workflows/validate-pack.yml`: results file `grep -c '^PASS'` = **57**, `grep '^FAIL'` → "NO FAILURES" (2 `pip install` lines SKIP — PyYAML native). Live oracle default-SKIP honored (zero workflow refs; env var never set). | COMPLIANT |
| `edit-in-place-not-full-rewrite` | 2 targeted `Edit` calls + 1 wrap-only reflow of my own insertion (no `Write` on the content file); hunk count before = 16, after = **16**; +8 net lines exactly matching the two fixes; post-edit re-read of both regions performed (actual sed output inspected); section-map header count 37 = pre-edit; tail line intact. | COMPLIANT |
| `pack-only` (BD-204 HARD) | End-state `git status --porcelain` = ` M maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md` + the four pre-existing untracked C-DOCS reports (+ this report). Zero `project-template/` or `supporting-docs/` paths; `git diff test-fixtures/manifest.txt | wc -l` = 0. | COMPLIANT |
| `scope-deliverables-to-the-ask` | Exactly the two approved fixes applied; no opportunistic edits (e.g., NO §7 pass-2 record added — not requested by either NIT); the only extra touch is the wrap reflow inside my own NIT-2 insertion. Report is terse (under 300 lines, single Write). | COMPLIANT |

**READ-IN-FULL attestation:** `CLAUDE.md` (580 lines), `PACK-REVIEW-BD-204-C-DOCS-REVIEW2.md`
(179), `feedback_edit_in_place_not_full_rewrite.md` (15), `feedback_verify_full_ci_suite.md`
(43), `feedback_agent_output_rules_applied_block.md` (15) — each opened directly via Read this
session at HEAD `c7f9af6`. `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` §5.c read fully per the
prompt's scoped-read instruction; `PACK-MEMORY-RATIONALE.md` § `rules-applied-verification-block`
read per its conditional MUST-READ.

**End of IMPL-REPORT-BD-204-C-DOCS-FIX2.md**
