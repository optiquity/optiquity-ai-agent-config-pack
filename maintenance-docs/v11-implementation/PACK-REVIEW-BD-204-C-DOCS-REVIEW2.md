# PACK-REVIEW-BD-204-C-DOCS-REVIEW2 — fresh pass-2 review of the ENTIRE C-DOCS change

> **Agent:** pack-reviewer (FRESH, pass 2 of the bounded cycle). **Date:** 2026-06-10.
> **HEAD:** `c7f9af6a575af00baaea0cb6e02261e141be5bfe` (branch `v11-dev`; unchanged — read-only
> git verbs only). **Scope reviewed:** the COMPLETE uncommitted working-tree diff of
> `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md` against HEAD (+296/−76, 16
> targeted hunks), i.e., the full C-DOCS reconciliation including the folded-in first fix pass —
> reviewed fresh on its own merits, per the calling prompt. No prior `PACK-REVIEW-*.md` was read.

## VERDICT: APPROVE — commit-ready

48/48 verification commands green (general validate-pack, `PACK_VALIDATE_DEEP=1` deep
validate-pack, and all 46 unattended battery test scripts from
`.github/workflows/validate-pack.yml`). Every owed edit from
`PLAN-BD-204-LOSSLESS-FIX-SEQUENCE.md` §4 is present. Every symbol, capability key, check
number, test-case ID, and behavior claim in the changed text was verified to exist and be
accurate against the as-built code. No new line-number references in any added line. Dated
decision records are byte-stable with supersession handled by adjacent addenda. Scope is exactly
one modified tracked file, docs-only, pack-only. Two NIT findings (below) — neither blocks the
commit; both are optional polish.

---

## 1. Owed-edit coverage (PLAN §4 — every item verified present)

| PLAN §4 owed edit | Where realized in the diff | Status |
|---|---|---|
| §2.4.1 carrier text → gz64 verbatim-body blob | §2.4.1 "The carrier, stated once (AS-BUILT…)" — full replacement: captured span lines 2..EOF, gzip `mtime=0` + base64, python3-pinned codec, corrupt-blob FAIL-LOUD, blob-authoritative + normalization-tolerant divergence backstop + `--force` override; example block now `<!-- pack-entry-body-gz64: … -->` | PRESENT |
| §2.4.2 zero-orphaned re-grounded on the blob + the CI faithfulness guard | §2.4.2 EE INTERP reconciled ("(as-built, reconciled 2026-06-10)") + the "Re-grounding (2026-06-10)" paragraph naming (a) the byte-carrying blob and (b) `check_migrator_field_faithfulness` (Check 49) with the single-source guard chain (batch siblings, equivalence tests 2.9.1–2.9.4 / 2.1e-i/ii, Check 50) | PRESENT |
| §2.11 lossless-contract pillars → blob | §2.11 rebuilt: (a) pack-id identity, (b) the blob, (c) `n_skipped` partial-write refusal + `_tmr_decode_body_blob` corrupt-blob fail-loud + `_tmr_check_blob_h2_divergence`, (d) status matrix, (e) Check-49 guard | PRESENT |
| §3.1 overflow-recovered item → blob | §3.1 item 4 → "Entire body recovered (as-built…)" by construction + the new unattended-enforcement paragraph (Check 49 byte/size/title/control-char legs) | PRESENT |
| ADD size (stored-byte axis) | §2.4.1 operational-contract bullet 1 (stored bytes vs `body.limit: 65536`; `provider_body_limit − TMF_SIZE_SAFETY_MARGIN`; fail-loud never truncate; BD-136 ~62%) | PRESENT |
| ADD pacing | §2.4.1 bullet 2 + §2.12 ON bullet (≥ `rate_limits.min_write_interval_s` GH 1s; retry-after on 403/429; 80/min + 500/hr caps; `TMF_PACING_SLEEP_CMD` seam) | PRESENT |
| ADD mention/autolink neutralization | §2.4.1 bullet 3 + §2.12 ON bullet (`_tmf_neutralize_autolinks`, inline-code span, 4 forms, blob untouched) | PRESENT |
| ADD `provider_body_storage_format` | §2.4.1 bullet 4 (`raw_text` \| `rich_text_normalizing`; GH declares `raw_text`; rich-text fails loud) + the §2.4.x mini-block tracker-agnostic row | PRESENT |
| §3.4 (and §2.12) archive wording → Option-A archive-only disposal | §3.4 fully rewritten: credential-capability preflight first (incl. `gh` ≥ 2.0 floor), REPEATABLE uniquely-named scratch repos, ARCHIVE-only end-state (`isArchived == true` asserted, trap-archives on failure), no-`gh repo delete` grep-guard, manual delete = user-only RECOMMEND, REAL repo never archived; both pre-fix `gh repo delete`-as-cleanup statements removed. §2.12 carried no archive wording at HEAD; a working-tree-wide `archiv` sweep finds zero stale archive wording (remaining hits = template-archive-path material + as-built Option-A text) | PRESENT |
| RECON attested-no-change; PLAN-BD-204.md not re-edited | §7 ledger attests both; `git status` confirms neither file modified | PRESENT |
| Reconciliation chain (architect-doc-reality rule) | New §7 ledger: per-section table, realized-consumer chain by file+symbol, byte-stable-disposition list, rules mini-block, review-fix-pass record; IMPL-REPORT cross-linked | PRESENT |

## 2. Factual accuracy vs as-built code (every named symbol/claim spot-checked)

| Doc claim (changed text) | As-built evidence (this session, HEAD `c7f9af6`) | Verdict |
|---|---|---|
| `tracker_migrate_reverse_reconstruct` (§2.1 step 2) | `tracker-migrate-reverse.sh:536` `tracker_migrate_reverse_reconstruct()`; emits `raw_body` onto the jq object (`--arg raw_body`, key `raw_body:`) | ACCURATE |
| `_tmf_parse_backlog_file` / `tmf_compose_issue_body` defaulted 6th param | defs at forward `:402` / `:907`; `local raw_body="${6:-}"` at `:913` | ACCURATE |
| `_tmf_gz64_encode` / `_tmf_gz64_encode_batch` / `_tmf_neutralize_autolinks` / `_tmf_neutralize_autolinks_batch` | defs at forward `:704` / `:731` / `:767` / `:813` | ACCURATE |
| `_tmr_decode_body_blob` / `_tmr_decode_body_blob_batch` / `_tmr_check_blob_h2_divergence` / `_tmr_emit_pack_tree` | defs at reverse `:663` / `:727` / `:794` / `:1005` | ACCURATE |
| Comparator transforms "CRLF/CR→LF, per-line trailing-whitespace strip, single trailing newline — no broader" | `norm()` in `_tmr_check_blob_h2_divergence`: `s.replace("\r\n","\n").replace("\r","\n")`; `line.rstrip(" \t")`; `s.rstrip("\n") + "\n"` — exactly three transforms | ACCURATE |
| Dead `extra_fields` render DELETED | only 1 remaining `extra_fields` token in reverse lib — a comment recording the deletion (`:999`); no code path | ACCURATE |
| `n_skipped` partial-write refusal | reverse `:1420–1445` (refusal unless `--force`) | ACCURATE |
| `pe_backpointer_line` + verbatim `raw_body` emit | reverse `:1019` / `:1067` | ACCURATE |
| `tracker_edit_entry` regenerates BOTH H2 + blob via the blob-aware composer | `tracker-edit.sh:182` + `:240–264` (`tmf_compose_issue_body` call; "no gz64/H2 emit re-implemented here") | ACCURATE |
| GH capability block `body.limit: 65536`, `body.storage_format: "raw_text"`, `rate_limits.min_write_interval_s: 1`, `rate_limits.writes_per_hour_max: 500` | `tracker-provider-gh.sh:770–777` — all four keys/values exact | ACCURATE |
| Pacing gate reads `.rate_limits.min_write_interval_s`; `TMF_PACING_SLEEP_CMD` test seam; retry-after backoff | forward `:867–903`, `:134`, `:1388` | ACCURATE |
| Size budget `provider_body_limit − TMF_SIZE_SAFETY_MARGIN`, fail-loud never truncate | forward `:124` (margin 2048), `:971–974` (the exact "NEVER truncates" abort message) | ACCURATE |
| `check_migrator_field_faithfulness` = Check 49, `PACK_VALIDATE_DEEP`-gated, four legs (codec-lossless + parse-faithful, size, title ≤ 256, control byte) | validate-pack.py `:7540–7675`: banner "Check 49", `:7551` env gate + SKIP, FAIL strings for codec/parse-faithful/control-byte/size/title legs | ACCURATE |
| Check 50 = OQ-4 single-source codec guard | validate-pack.py `:7713`/`:7780`/`:7788` banner "Check 50: OQ-4 single-source codec guard (BD-204 §4.5)" | ACCURATE |
| `run_check` timing harness | validate-pack.py `:451` `def run_check(name, fn, budget_s=…)` | ACCURATE |
| Batch siblings "ADDITIVE … equivalence-bound by per-commit byte-identity tests" (cases 2.9.1–2.9.4 / 2.1e-i/ii) | forward-test `:343–382` (2.9.1 gz64, 2.9.2 neutralizer; 2.9.3/2.9.4 in file); reverse-test `:387–413` (2.1e-i, 2.1e-ii) — all test-case IDs exist verbatim | ACCURATE |
| Per-check test + dedicated deep workflow step | `scripts/tests/test-validate-pack-check-49-field-faithfulness.sh` exists on disk; workflow `:104` `run: PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` + `:208` `run: bash scripts/tests/test-validate-pack-check-49-field-faithfulness.sh` | ACCURATE |
| Rebuilt C-7 oracle: credential preflight (create/issues/archive, NOT delete; `gh` ≥ 2.0 floor), archive-only disposal + trap, `isArchived == true` assert, manual-delete RECOMMEND, no-`gh repo delete` grep-guard | oracle `:144–178` (preflight incl. version floor + delete_repo-absent check), `:206–214` (trap archive + RECOMMEND), `:763–774` (archive + `isArchived` assert), `_FORBIDDEN="gh repo de""lete"` static self-guard | ACCURATE |
| §3.4 fixture claims (drop-set, no-Description, 4-form autolink entries) | fixture `tracker-bd204-lossless/BACKLOG.md`: `Target:`/`Position:` present; 7 entries vs 6 `Description:` fields (one no-Description entry); BD-904 carries all four trigger forms (`#123`, `@…`, bare SHA, URL) | ACCURATE |
| Unit-level legs run unattended in the battery | pacing (forward-test 2.8.x via fake-sleep seam), size-budget (2.8.5), corrupt-blob (reverse-test 2.1b), divergence comparator (2.1d), neutralization (2.9.2), plus the Check-49 per-check test — all wired into the workflow battery | ACCURATE in substance; see NIT-1 on attribution |
| Oracle manual-only / default-SKIP | oracle `:60–64` exits 0 unless `PACK_TRACKER_LIVE_GH=1` + `gh auth`; zero `run:` lines reference it in the workflow | ACCURATE |
| §7 ledger section naming (§2.10 capability census, §2.11, §2.12) | headers confirmed at doc `:807`/`:831`/`:851` — hunks land in the named sections | ACCURATE |

No FALSE or unverifiable claim was found anywhere in the changed text.

## 3. Reference hygiene

- **No new line-number references.** Sweep over every added line:
  `git diff … | grep -E '^\+' | grep -E '(\.md|\.sh|\.py|\.yml|_lib):[0-9]'` → ZERO matches.
  The two pre-fix refs inside rewritten prose (`ARCHITECTURE-V3.3-DELTA.md:312`,
  `backlog/BD-204.md:14` in the §2.4.1 carrier paragraph) are re-anchored by section/field
  (`§6.1`; "the DECISION TIERS HARD bullet"). Line refs that survive in the doc
  (`work-item.yml:103-105`, `tracker-migrate-reverse.sh:1085-1098`, `backlog/BD-204.md:14` in
  the unchanged "Why the sidecar is dropped" paragraph, §5/§6 dated rows) all sit in UNCHANGED
  context — outside this pass's mandate.
- **Dated records byte-stable; supersession by adjacent addenda.** The §1 DP-2 RESOLVED wording,
  the end-of-§1 DECISION POINTS summary, the §2.4.1 DP-2 RESOLVED blockquote, the §2.4.2 EE
  `CMD`/`OUT`, the `template_version` EE `CMD`, the §5 audit table rows, and §6 are all
  unchanged in the diff (context lines only); supersession is carried by four adjoining as-built
  notes (§1 DP-2, end-of-§1 summary, §5 table, plus the §2.4.1 AS-BUILT carrier paragraph that
  immediately follows the §2.4.1 blockquote). No history rewriting. The §2.4.2 EE INTERP edit is
  the one in-block reconciliation — it is explicitly ordered by the spec
  (`ARCHITECTURE-BD-204-LOSSLESS-FIX.md` §5.d: "the zero-orphaned claim must be re-grounded")
  and is transparently date-stamped "(as-built, reconciled 2026-06-10)", with `CMD`/`OUT`
  preserved verbatim.
- **Internal consistency.** Remaining `pack-extra-fields` tokens in the working doc (15) are ALL
  inside dispositioned dated records or inside the supersession/ledger prose itself; zero live
  design statements name the phantom carrier. Zero stale archive/delete wording survives
  (`gh repo delete` appears only in the as-built "never runs / grep-guarded" statements).

## 4. Edit-in-place / byte-stability

16 targeted hunks (`git diff | grep -c '^@@'` = 16); +296/−76 against a 1044-line base — no
full rewrite. Hunk ranges land exactly in the sections the §7 ledger names (§1 ×2, §2.1, §2.4
intro/table/principle, §2.4.1, §2.4.2, §2.4.x mini-block, §2.10, §2.11, §2.12, §3.1, §3.4,
§4.3, §5 note, §7). Sections the ledger declares byte-stable (DP-1/DP-3/DP-4/DP-5, §2.2/§2.3/
§2.5–§2.9, §3.2/§3.3, §4.1/§4.2, the §5/§6 dated bodies) have no hunks. Document tail
(`**End of ARCHITECTURE-BD-204.md**`) intact after the new §7.

## 5. Scope

`git status --porcelain` at review end: exactly `M maintenance-docs/v11-implementation/
ARCHITECTURE-BD-204.md` + four untracked BD-204 C-DOCS report files (the two IMPL reports, the
pass-1 review report, and this report). No `project-template/`, no `supporting-docs/`, no
script/entry/fixture touched. Docs-only, `pack-only` holds (CI Check 36 safe). No manifest
regen owed (no v11-surface directory in the diff; confirmed by the FIX1 report and by the
diff's file list).

## 6. Verification run (this session, full suite)

- `python3 scripts/validate-pack.py` → **PASS** ("PASSED — all checks clean"; PyYAML native).
- `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` → **PASS** (Check 49 deep leg green
  on the real tree).
- Full unattended battery — every `run:` command in `.github/workflows/validate-pack.yml`
  (48 commands: the 2 validate-pack invocations + 46 test scripts) executed sequentially:
  **48 PASS / 0 FAIL** (results `/tmp/bd204r2-battery-results.txt`; per-command logs
  `/tmp/bd204r2-log-*.txt`).
- Live oracle `tracker-bd204-lossless-roundtrip-test.sh`: NOT invoked (default-SKIP per the
  calling prompt; it has no workflow `run:` line; `PACK_TRACKER_LIVE_GH` never set).

## 7. Findings

### NIT-1 — §3.4 unit-leg attribution is ambiguous (doc: §3.4 "Disposal contract" closing sentence)

The sentence "Realized in `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` (…), alongside
its drop-set / size / pacing / autolink-neutralization / corrupt-blob / normalization-comparator
legs — the unit-level legs also run unattended in the battery while the live round-trip stays
manual" can be read as claiming the ORACLE's own legs run unattended. As-built, the oracle exits
0 immediately when `PACK_TRACKER_LIVE_GH` is unset (oracle `:60–64`) and has no workflow `run:`
line; the unattended unit-level coverage lives in `tracker-migrate-forward-test.sh` (2.8.x
pacing/size, 2.9.x), `tracker-migrate-reverse-test.sh` (2.1b corrupt-blob, 2.1d comparator), and
the Check-49 per-check test. The governing spec (`ARCHITECTURE-BD-204-LOSSLESS-FIX.md` §5.c)
carries a clarifying parenthetical — "(the in-process check or a mock-based unit test)" — that
the reconciled sentence dropped. Substance is true; attribution could mislead. Optional one-line
clarification; non-blocking.

### NIT-2 — §7 byte-stable disposition list omits the §2.4.1 DP-2 RESOLVED blockquote (doc: §7 "Dated records intentionally left byte-stable")

The §2.4.1 "RESOLVED, FIXED constraint (user 2026-06-06)" blockquote is the third surviving
dated record naming `pack-extra-fields` (after the §1 DP-2 record and the end-of-§1 summary). It
is byte-stable and its supersession IS handled — the immediately-following "carrier, stated once
(AS-BUILT — … supersedes the `pack-extra-fields` named-scalar block …)" paragraph sits in the
same subsection — but the §7 disposition list does not enumerate it the way it enumerates the
other dated records. Ledger-completeness polish only; no reader-misleading risk. Non-blocking.

## 8. Verdict line

**APPROVE** — the ENTIRE uncommitted C-DOCS change is commit-ready as-is. NIT-1/NIT-2 are
optional polish for Pack Chat triage (fix-or-track per the default fix-all/tech-debt rule);
neither warrants holding the commit, and the bounded cycle's remaining budget is the user's
call.

---

## Rules-Applied Verification Block

| Rule | Verification evidence (actual command / output / measurement) | Conclusion |
|---|---|---|
| `agents-never-commit` | Git verbs run this session: `git status --porcelain`, `git rev-parse HEAD`, `git diff` (×4, read-only). No `add`/`commit`/`push`/`tag`/`rm`. Final `git rev-parse HEAD` = `c7f9af6a575af00baaea0cb6e02261e141be5bfe` (unchanged). Sole repo write = this report file at the prompted path. | COMPLIANT |
| `per-action-approval-sub-agents` | No destructive op run: zero `rm -rf` / `git rm` / file overwrites; battery logs and lists written to `/tmp` only; no live `gh` mutation (`PACK_TRACKER_LIVE_GH` never set — oracle list-check output: `0` workflow references, never invoked). | COMPLIANT |
| `preflight-stop-means-stop` | Emitted verbatim before this Write: `PREFLIGHT: review complete; verification PASS; HEAD c7f9af6a575af00baaea0cb6e02261e141be5bfe; about to Write report to maintenance-docs/v11-implementation/PACK-REVIEW-BD-204-C-DOCS-REVIEW2.md`. No parent stop message received at any point. | COMPLIANT |
| `agent-output-rules-applied-block` | This table: one row per prompt-listed rule, quoted command output / paths / counts as evidence, terminal conclusions only (no AMBIGUOUS, no empty cell). Prerequisite read: `feedback_agent_output_rules_applied_block.md` read FULL (15 lines). | COMPLIANT |
| `agents-read-rule-docs-in-full` | Direct full reads this session: (1) `CLAUDE.md` 580/580 lines incl. the complete `## Pack memory` section; (2) `PLAN-BD-204-LOSSLESS-FIX-SEQUENCE.md` 243/243; (3) `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` 1708/1708 (four contiguous Reads: 1–475, 476–950, 951–1450, 1451–1708); (4) `feedback_verify_full_ci_suite.md` 43/43; (5) `feedback_edit_in_place_not_full_rewrite.md` 15/15; (6) `feedback_agent_output_rules_applied_block.md` 15/15. No named doc derived rather than read. | COMPLIANT |
| `verify-full-ci-suite` | Ran `python3 scripts/validate-pack.py` (tail: "PASSED — all checks clean") AND the complete workflow battery: 48 `run:` commands extracted from `.github/workflows/validate-pack.yml` (`wc -l` = 48, incl. the `PACK_VALIDATE_DEEP=1` step), executed sequentially → results file: `grep -c '^PASS'` = **48**, `grep '^FAIL'` = none ("NO FAILURES"). Live oracle default-SKIP honored (0 workflow refs; env var never set). | COMPLIANT |
| `edit-in-place-not-full-rewrite` | `git diff … | grep -c '^@@'` = **16** targeted hunks, +296/−76 on a 1044-line file; hunk start-lines enumerated and mapped to the §7 ledger's touched-section list; ledger-declared byte-stable sections (§2.2–§2.3, §2.5–§2.9, §3.2/§3.3, §4.1/§4.2, §5/§6 dated bodies, DP-1/3/4/5) have zero hunks; §5/§6 dated table rows and the §2.4.2 EE `CMD`/`OUT` appear only as context lines in the diff. | COMPLIANT |
| `pack-only` (BD-204 HARD) | `git status --porcelain` = ` M maintenance-docs/v11-implementation/ARCHITECTURE-BD-204.md` + untracked `IMPL-REPORT-BD-204-C-DOCS.md`, `IMPL-REPORT-BD-204-C-DOCS-FIX1.md`, `PACK-REVIEW-BD-204-C-DOCS.md`, and this report. Zero `project-template/` or `supporting-docs/` paths in the diff or the untracked set. | COMPLIANT |
| `scope-deliverables-to-the-ask` | Delivered exactly the prompted verdict surface: owed-edit coverage, factual-accuracy spot-check, reference hygiene, edit-in-place, scope, verification counts, 2 findings (both real, both labeled), one verdict line, this block. No coverage sprawl; unchanged sections audited only for contradiction-with-as-built (the prompt's criterion 3). | COMPLIANT |

**READ-IN-FULL attestation:** `CLAUDE.md` (580 lines), `PLAN-BD-204-LOSSLESS-FIX-SEQUENCE.md`
(243), `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` (1708), `feedback_verify_full_ci_suite.md` (43),
`feedback_edit_in_place_not_full_rewrite.md` (15), `feedback_agent_output_rules_applied_block.md`
(15) — each opened directly via Read this session at HEAD `c7f9af6`; no derivation. The two
permitted coder reports (`IMPL-REPORT-BD-204-C-DOCS.md`, `IMPL-REPORT-BD-204-C-DOCS-FIX1.md`)
were read for the edit inventory; `PACK-REVIEW-BD-204-C-DOCS.md` was NOT read.

**End of PACK-REVIEW-BD-204-C-DOCS-REVIEW2.md**
