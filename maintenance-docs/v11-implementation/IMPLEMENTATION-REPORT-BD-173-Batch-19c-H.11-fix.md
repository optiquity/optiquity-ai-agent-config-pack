# IMPLEMENTATION-REPORT — BD-173 Batch 19c H.11 fix (3 NITs closed)

**Branch:** v11-dev
**HEAD before edits:** `17682c77ed0c46b1fd8ead9ebae9c975e521dbc7` (parent session committed `17682c7` PS-landscape research after the prompt was authored; the H.11 commit `553ab88` is the immediate parent)
**HEAD after edits:** `17682c77ed0c46b1fd8ead9ebae9c975e521dbc7` (working-tree edits only; pack-coder does not commit)
**Date:** 2026-05-24
**Stage:** H.11-fix — close 3 NITs surfaced by H.11 INLINE reviewer
**Scope keyword:** (none — mixed-scope commit touching `supporting-docs/` + `maintenance-docs/` IMPL-REPORT + `test-fixtures/manifest.txt`; Check 36 SKIP)

## §1 — Scope

Three NITs from `/tmp/PACK-REVIEW-BD-173-Batch-19c-H.11.md` §3, all
triaged **FIX** by Pack Chat per user (A) decisions:

| ID | File | Anchor | Class |
|---|---|---|---|
| N1 | `supporting-docs/INSTALL-PROCEDURES.md` | L942-945 + L961-968 | Cross-file consistency drift (Procedure 7 §7.0 still described pre-H.11 PM-chat behavior) |
| N2 | `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.11.md` | §1 (L8) | IMPL-REPORT accuracy (false `Scope keyword: project-only` claim) |
| N3 | `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.11.md` | §7.3 (L486) + §8 (L502) | IMPL-REPORT accuracy (off-by-one line-count claim) |

**Files modified:**

- `supporting-docs/INSTALL-PROCEDURES.md` — two surgical prose edits in
  Procedure 7 § preface (L940-948) and § 7.0 (L961-968) describing
  post-H.11 PM-chat behavior.
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.11.md` —
  three surgical edits (§1 scope-keyword line, §7.3 line-count prose,
  §8 table row) correcting inaccuracies surfaced by reviewer.
- `test-fixtures/manifest.txt` — regenerated per
  `feedback-manifest-regen-on-v11-surface` (4-directory v11-surface
  trigger; `supporting-docs/` IS in scope per BD-176).

**Files NOT modified (out-of-scope):**

- `project-template/docs/pack/prompts/pm-chat.md` — H.11 content
  unchanged. The fix-coder pass only addresses the 3 NIT-target sites;
  it does not re-touch H.11's primary deliverable.
- H.11 commit (`553ab88`) itself — immutable history; commit subject
  body's `pm-chat.md: 302 → 507 lines` line is frozen as historical
  record (no destructive git ops permitted).
- No other file under `project-template/`, `pack-ops/`,
  `supporting-docs/` (beyond the one INSTALL-PROCEDURES.md edit),
  `maintenance-docs/` (beyond the one H.11 IMPL-REPORT edit), or
  elsewhere.

## §2 — Edits applied (per NIT)

### N1 — `supporting-docs/INSTALL-PROCEDURES.md` cross-file consistency drift

**Anchor A — Procedure 7 preface (lines 940-945 in pre-fix file).**

**BEFORE:**

```
Procedure 7 is the PM-chat-side companion to the kickoff-variant
continuation pointer. The pointer routes to this procedure; this
procedure fills in the Apple / gRPC toolchain that SETUP-NEW.md
Steps 5–8 would otherwise require the developer to run by hand.
Every auto-discovered value and every install / edit / machine-level
write is confirmed via Form R / I / E / M before the PM chat acts.
```

**AFTER:**

```
Procedure 7 is the PM-chat-side companion to the kickoff-variant
continuation pointer. The pointer routes to this procedure on
shell-capable surfaces; this procedure fills in the Apple / gRPC
toolchain (Xcode scheme variables, swift-format, gRPC tooling,
Xcode companion files) that the developer would otherwise run by
hand. Every auto-discovered value and every install / edit /
machine-level write is confirmed via Form R / I / E / M before the
PM chat acts. On non-shell surfaces, the kickoff variant's `manual`
branch walks the developer through the same sub-flows inline
(M.A–M.D in `docs/pack/prompts/pm-chat.md` § Variant: kickoff).
```

**Rationale.** The pre-H.11 reference to "SETUP-NEW.md Steps 5–8" was
a backward-compatibility cross-reference to a file that is NOT
client-installed (per AUDIT §0.3 Note 2). After H.11, the equivalent
content lives inline in `docs/pack/prompts/pm-chat.md` as the M.A–M.D
sub-flows. The new prose (a) replaces the `SETUP-NEW.md` cite with an
inline enumeration of what Procedure 7 covers (Xcode scheme vars,
swift-format, gRPC tooling, Xcode companion files — matches the
Procedure 7 §§ 7.1-7.4 surface), and (b) adds a one-sentence cross-
reference to the post-H.11 manual-fallback inline location. The new
reference target (`docs/pack/prompts/pm-chat.md`) IS client-installed
(verified per H.11 IMPL-REPORT §3.4).

**Anchor B — Procedure 7 § 7.0 (lines 961-968 in pre-fix file).**

**BEFORE:**

```
declaration. On Web / Desktop surfaces without shell access (Claude
Web, ChatGPT Web), the assistant declares `manual`; Procedure 7 is
not entered; the PM chat emits the `SETUP-NEW.md § Manual fallback`
pointer and waits for developer-reported values. The exit-ramp
reply is interpreted per the § 7.5 reply grammar (`yes` / `no` /
`skip` / `abort` / `edit` / bare value); a positive reply
authorizes Form R, anything else defers per the grammar's
"unrecognized → no" rule.
```

**AFTER:**

```
declaration. On Web / Desktop surfaces without shell access (Claude
Web, ChatGPT Web), the assistant declares `manual`; Procedure 7 is
not entered; the PM chat instead walks the developer through the
manual-fallback sub-flows inline (M.A–M.D in
`docs/pack/prompts/pm-chat.md` § Variant: kickoff, `manual` branch)
and composes the corresponding file edits from developer-reported
values. The exit-ramp reply is interpreted per the § 7.5 reply
grammar (`yes` / `no` / `skip` / `abort` / `edit` / bare value); a
positive reply authorizes Form R, anything else defers per the
grammar's "unrecognized → no" rule.
```

**Rationale.** Line 963 in the pre-fix file claimed "the PM chat
emits the `SETUP-NEW.md § Manual fallback` pointer" — this is
factually wrong post-H.11. The PM chat no longer emits any pointer
for the `manual` flow; it inlines M.A–M.D directly per H.11 IMPL-
REPORT §2 Variant 1. The new prose accurately describes the post-
H.11 behavior: the PM chat walks the developer through the inline
sub-flows in `pm-chat.md` and composes file edits from reported
values. Reference target (`docs/pack/prompts/pm-chat.md`) is client-
installed.

**Boundary discipline.** No new pack-internal references introduced
in either anchor's rewrite. Both new references point at
`docs/pack/prompts/pm-chat.md`, which IS client-installed (per
init-project.sh stage S6 copy of `project-template/docs/pack/`
trees). Boundary grep (§3.4 below) returns clean.

### N2 — IMPL-REPORT §1 false scope-keyword claim

**File:** `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.11.md` line 8.

**BEFORE:**

```
**Scope keyword:** project-only (single-file edit under `project-template/`; manifest regen accompanies per pack-memory rule)
```

**AFTER:**

```
**Scope keyword:** (none — mixed-scope commit touching `project-template/` + `maintenance-docs/` IMPL-REPORT + `test-fixtures/manifest.txt`; Check 36 SKIP, no claim to verify; per PLAN §3 H.11 "Commit subject scope keyword: (mixed — no keyword)")
```

**Rationale.** The actual H.11 commit (`553ab88`) carries no scope
keyword in its subject line, and the diff legitimately spans three
directories: `project-template/` (project-side), `maintenance-docs/`
(pack-only), and `test-fixtures/` (pack-only). Per pack-trinity
§ "Commit-subject scope-keyword convention" + Check 36 contract, a
`project-only` keyword on this commit WOULD HAVE FAILED CI Check 36
because the diff exceeds `project-template/` + `supporting-docs/`. The
commit correctly omits the keyword; the IMPL-REPORT prose was
inconsistent with both the actual subject and the diff. The PLAN
§3 H.11 step explicitly anticipated mixed-scope: `Commit subject
scope keyword: (mixed — no keyword)`. New text captures this
accurately.

### N3 — IMPL-REPORT line-count off-by-one

**Verification commands and results (from §3.2 below):**

```
$ git show df1e97d:project-template/docs/pack/prompts/pm-chat.md | wc -l
     301
$ wc -l project-template/docs/pack/prompts/pm-chat.md
     507 …
```

**Authoritative values:**
- Pre-H.11 (HEAD `df1e97d`): **301** lines (NOT 302).
- Post-H.11 (HEAD `553ab88`): **507** lines (correct in IMPL-REPORT).
- True delta: **+206** lines (NOT +205).

**Edit 1 — IMPL-REPORT §7.3 prose (line 486).**

**BEFORE:**

```
size grew from 302 lines to 507 lines (+205 lines across all
```

**AFTER:**

```
size grew from 301 lines to 507 lines (+206 lines across all
```

**Edit 2 — IMPL-REPORT §8 table row (line 502).**

**BEFORE:**

```
| `project-template/docs/pack/prompts/pm-chat.md` | modified | +205 / 0 (302 → 507) |
```

**AFTER:**

```
| `project-template/docs/pack/prompts/pm-chat.md` | modified | +206 / 0 (301 → 507) |
```

**Rationale.** The reviewer's off-by-one diagnosis is correct (per
their §3 N3 finding + own `wc -l` reproduction). The discrepancy is
the classic soft-newline-at-EOF counting convention (`wc -l` reports
the count of newline characters, so a file ending without a trailing
newline can appear one short of its "line count" by other tools).
The accurate authoritative count comes from `wc -l` against the
canonical pre-H.11 blob (`git show df1e97d:`) and post-H.11 working-
tree file. Both replacements update prose + table cell to match.

**Note on H.11 commit message body.** The commit subject body
(line `- pm-chat.md: 302 → 507 lines`) is frozen as historical
record. Destructive git ops (commit amend, rebase) are forbidden
per pack-trinity. The commit body is not the IMPL-REPORT's contract
surface — the IMPL-REPORT IS the in-tree fix target per the prompt.
Reviewer N3 explicitly classified this as "No correctness impact;
… No remediation needed" for the commit-message version. Only the
IMPL-REPORT is corrected (per prompt scope).

**Note on other "302" / "205" / "Scope keyword: project-only" occurrences.**
Grep verification (§3.3 below) confirms zero remaining stale values in
the IMPL-REPORT after the edits.

## §3 — Verification

### §3.1 — `python3 scripts/validate-pack.py`

```
============================================================
PASSED — all checks clean
```

All 42 checks PASS, including:

- Check 36 (Commit-scope honesty): 0 scope-claiming commit(s) verified
  clean. (The fix-coder pass adds no new commits; HEAD remains
  `553ab88` which carries no keyword.)
- Check 37 (Project-side pack-only deny-list): 146 project-side files
  walked; zero deny-list contamination.
- Check 38 (Pack-only-file siting): no pack-only content mis-sited.
- Check 39 (cmd_update mapping/glob symmetry): 6
  `project-template/docs/pack/*.md` files symmetric.
- Check 41 (`_CLIENT_INSTALLED_FILES` integrity): 38 entries resolve,
  0 drift.

### §3.2 — Line-count authoritative verification (N3 sourcing)

```
$ git show df1e97d:project-template/docs/pack/prompts/pm-chat.md | wc -l
     301
$ wc -l /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/docs/pack/prompts/pm-chat.md
     507 …
```

Pre-H.11 = 301 (NOT 302). Post-H.11 = 507. Delta = +206 (NOT +205).
IMPL-REPORT edits applied.

### §3.3 — Stale-value sweep in IMPL-REPORT

```
$ grep -nE "302|205|project-only|Scope keyword" .../IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.11.md
8:**Scope keyword:** (none — mixed-scope commit touching `project-template/` + `maintenance-docs/` IMPL-REPORT + `test-fixtures/manifest.txt`; Check 36 SKIP, no claim to verify; per PLAN §3 H.11 "Commit subject scope keyword: (mixed — no keyword)")
```

Only one hit, which is the new accurate `Scope keyword` line. No
remaining "302" / "205" / "project-only" occurrences.

### §3.4 — Boundary discipline grep on INSTALL-PROCEDURES.md (N1)

Per prompt's boundary-verification command:

```
$ grep -nE "V[0-9]+(\.[0-9]+)? §|ARCHITECTURE-V[0-9.]+|AUDIT-USER-CURATION|RESEARCH-PER-ENTRY|maintenance-docs/" supporting-docs/INSTALL-PROCEDURES.md | head -10
(no output)
```

Zero pack-internal leaks in INSTALL-PROCEDURES.md after the N1
edits. Both new cross-references point at
`docs/pack/prompts/pm-chat.md`, which is client-installed.

Cross-check for residual `SETUP-NEW` references in Procedure 7
area:

```
$ grep -nE "SETUP-NEW" supporting-docs/INSTALL-PROCEDURES.md
(no output)
```

All `SETUP-NEW.md` references have been removed (both occurrences in
Procedure 7 were the N1 anchors).

Cross-check for residual `Pack Chat` / pack-internal references in
the broader INSTALL-PROCEDURES.md (sanity sweep):

```
$ grep -nE "pack-ops/|maintenance-docs/|PACK-AGENTS|Pack Chat|pack-architect|pack-planner|pack-coder|pack-reviewer" supporting-docs/INSTALL-PROCEDURES.md | head -10
301:   to Pack Chat before proceeding.
609:   STOP and surface to Pack Chat.
```

Only 2 hits, both pre-existing legitimate "escalation pointers"
(AUDIT §2.3 explicitly classified these 2 lines as LEGITIMATE in the
PRE-19C audit). Neither is in the H.11-fix edit zones (~L940-980).
N1 edits introduce zero new pack-internal references.

### §3.5 — `bash test-fixtures/build.sh --all --clean`

All six fixtures rebuilt without error.

### §3.6 — `git diff --stat test-fixtures/manifest.txt`

```
 test-fixtures/manifest.txt | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)
```

### §3.7 — Manifest diff (content)

```
-v11-realistic-ot  883fa955813d2934f8d6d796f09e52da17ad758c
-v11-flat-file  80a3068c17e5b3a9cfddf4b3b99c9623f7c2c0c8
-v11-tracker-on  557d8d1c049fed24e229d18e8b1e81cbd41fdd26
+v11-realistic-ot  356a0203405c9c6cbe00fa037da01b4add55233b
+v11-flat-file  f4cf290da2becc2682c165cc5c3fe2a5c0fadc8d
+v11-tracker-on  42e5fc40768b0eab7830f87088317aec01dc9210
```

Drift confined to v11-* rows (v10-* tag-pinned;
`existing-project-mid-dev` row unchanged). This is the expected
shape for an edit confined to `supporting-docs/` (which init-project.sh
S6 copies into client `docs/pack/`).

### §3.8 — Edit-stat sanity (per-file)

```
$ git diff --stat supporting-docs/INSTALL-PROCEDURES.md
 supporting-docs/INSTALL-PROCEDURES.md | 28 ++++++++++++++++++---------

$ git diff --stat maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.11.md
 .../IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.11.md | 6 ++++---
```

INSTALL-PROCEDURES.md: 28 line-touches across 2 surgical replacement
zones (matches the two N1 anchor edits + small line-break shape
changes from prose rewrites).

IMPL-REPORT: 6 line-touches across 3 surgical replacements (matches
N2 §1 line + 2 N3 fixes).

### §3.9 — Working-tree summary

```
$ git status --short
 M maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.11.md
 M supporting-docs/INSTALL-PROCEDURES.md
 M test-fixtures/manifest.txt
?? maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.11-fix.md
?? maintenance-docs/v11-research/IMPLEMENTATION-REPORT-RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md
?? maintenance-docs/v11-research/RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md
```

Exactly 3 modified files + this new IMPL-REPORT. The 2 untracked
`v11-research/*` files are pre-existing and outside this fix-coder's
scope (untracked at session start per HEAD `553ab88` working tree).

## §4 — Cross-references

- **H.11 INLINE reviewer report:** `/tmp/PACK-REVIEW-BD-173-Batch-19c-H.11.md`
  (3 NIT findings — N1 + N2 + N3 — all triaged FIX by Pack Chat per
  user (A) decisions).
- **H.11 IMPL-REPORT:** `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.11.md`
  (the doc updated by N2 + N3 edits).
- **AUDIT (pre-19C boundary leaks):** `maintenance-docs/v11-implementation/AUDIT-PRE-19C-BOUNDARY-LEAKS.md`
  §0.3 Note 2 (canonical 5-file list of `supporting-docs/*.md` NOT
  shipped to clients — including `SETUP-NEW.md`); §2.3 (review of
  `supporting-docs/INSTALL-PROCEDURES.md` classified L301 + L609 as
  LEGITIMATE escalations; did not classify the L942 + L963 SETUP-NEW
  references because the audit was scoped to pack-internal vocabulary,
  not "behavior described in client-installed prose that no longer
  matches the PM-chat prompt").
- **Plan source:** `maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19C-V2.md`
  §B.2 (user-direction C-c: Category C variant-rewrite strategy).
- **Pack memory:** `feedback-manifest-regen-on-v11-surface` (4-directory
  v11-surface trigger inclusive of `supporting-docs/`); `P-missed-7`
  (project-side SSOT investigation — applied here when choosing the
  N1 reference target as `docs/pack/prompts/pm-chat.md`, the
  client-installed location, rather than any pack-only file).
- **Client-install copy-site source-of-truth:** `scripts/init-project.sh`
  lines 565-581 (stage S6 copies `supporting-docs/METHODOLOGY.md` and
  `supporting-docs/INSTALL-PROCEDURES.md` to client
  `docs/pack/`). Confirms INSTALL-PROCEDURES.md IS client-installed
  (and thus boundary-clean as a reference target).

## §5 — Success criteria checklist

| # | Criterion | Status |
|---|---|---|
| 1 | N1: `supporting-docs/INSTALL-PROCEDURES.md` L942 + L963 reflect post-H.11 PM-chat behavior accurately | PASS (§2.N1, §3.4) |
| 2 | N2: H.11 IMPL-REPORT §1 no longer claims `Scope keyword: project-only` | PASS (§2.N2, §3.3) |
| 3 | N3: H.11 IMPL-REPORT line-count claims corrected to actual values everywhere they appear | PASS (§2.N3, §3.3 — 2 edits @ §7.3 + §8) |
| 4 | No new leaks introduced in N1 rewrite | PASS (§3.4 boundary grep clean) |
| 5 | `validate-pack.py` PASS | PASS (§3.1 — all 42 checks) |
| 6 | Manifest v11-* row drift (`supporting-docs/` touched) | PASS (§3.6, §3.7 — triple-row drift; v10-* + existing-project rows unchanged) |
| 7 | Fix IMPL-REPORT written | PASS (this file) |

## §6 — Out-of-scope confirmations

- **H.11 commit (`553ab88`) content unchanged.** Only the 3 NIT-target
  sites are touched: 2 anchors in INSTALL-PROCEDURES.md + 3 surgical
  edits in the H.11 IMPL-REPORT. No edits to
  `project-template/docs/pack/prompts/pm-chat.md` (H.11's primary
  deliverable) — its content remains exactly as committed at
  `553ab88`.
- **`17682c7` PS-landscape research content unchanged.** The parent
  session committed `17682c7` (`docs: v11 — PS landscape research
  (pre-BD-190, pack-only)`) between prompt authoring and fix-coder
  spawn. None of its files (`maintenance-docs/v11-research/RESEARCH-
  PRODUCT-SPECIALIST-LANDSCAPE.md`, `maintenance-docs/v11-research/
  IMPLEMENTATION-REPORT-RESEARCH-PRODUCT-SPECIALIST-LANDSCAPE.md`)
  are touched by this fix-coder pass.
- **H.11 commit message body NOT edited.** The H.11 commit's body
  carries `- pm-chat.md: 302 → 507 lines` — this is frozen
  historical record. Touching it would require destructive git ops
  (commit amend or rebase) which are forbidden per pack-trinity
  pack-memory rules. Reviewer N3 explicitly classified the commit-
  message version as "No correctness impact; … No remediation needed."
  Only the IMPL-REPORT is corrected (per prompt scope: "Update the
  H.11 IMPL-REPORT in-place").
- **No other file in `supporting-docs/` touched.** Only INSTALL-
  PROCEDURES.md. Other `supporting-docs/*.md` files (METHODOLOGY.md,
  SETUP-NEW.md, SETUP_TEMPLATE.md, AGENT_KICKOFF_TEMPLATE.md,
  CLI-PM-SETUP.md, MIGRATION-v10-to-v11.md) are unchanged.
- **No other file in `maintenance-docs/` touched.** Only the H.11
  IMPL-REPORT. The two pre-existing untracked `v11-research/*` files
  are out-of-scope for this fix-coder and remain untracked.
- **No new BD opens.** All 3 NITs are routine in-batch fixes (cross-
  file consistency + IMPL-REPORT accuracy). No size/blocked/logical-
  fit signal triggers a separate BD per OQ-1 / `feedback-deferral-
  is-scope-creep`.
- **No `scripts/`, `pack-ops/`, `proto/`, or `project-template/`
  edits.** Working tree confirms (§3.9).
- **Manifest regen is mandatory and accompanied (BD-176 rule).** Edit
  touches `supporting-docs/INSTALL-PROCEDURES.md` which IS in the
  4-directory v11-surface trigger; manifest is regenerated and
  staged in the same fix commit (per `feedback-manifest-regen-on-
  v11-surface`).

## §7 — Files changed

| Path | Change type | Lines (delta) |
|---|---|---|
| `supporting-docs/INSTALL-PROCEDURES.md` | modified | +17 / -11 (N1: 2 prose anchors rewritten) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.11.md` | modified | +3 / -3 (N2 + N3: 3 surgical edits) |
| `test-fixtures/manifest.txt` | modified | +3 / -3 (v11-* row SHA refresh per BD-176 trigger) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.11-fix.md` | new | this file |

No deletions. No renames. No new files outside `maintenance-docs/`.

PREFLIGHT: 3/3 NITs closed (N1+N2+N3); verification PASS; HEAD `17682c77ed0c46b1fd8ead9ebae9c975e521dbc7` (note: prompt referenced `553ab88` as HEAD; parent session committed `17682c7` PS-landscape research between prompt authoring and fix-coder spawn — fix-coder scope unaffected, all 3 NIT-target files touched as specified); about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.11-fix.md
