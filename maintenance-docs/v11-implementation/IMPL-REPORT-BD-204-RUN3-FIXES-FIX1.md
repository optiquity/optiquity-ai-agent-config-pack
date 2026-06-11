# IMPL-REPORT — BD-204 run-3-fixes FIX1 (review pass-1 findings F-1 / F-2 / POQ-1)

- **Branch:** `v11-dev`
- **HEAD (unchanged; no git state changes):** `451f20f4e4d665498aeb9101885fadb2ee503b5a`
- **Fix-coder:** fresh fix-coder, 2026-06-10
- **Scope:** exactly the three approved findings from
  `maintenance-docs/v11-implementation/PACK-REVIEW-BD-204-RUN3-FIXES.md`
  (pack-only; no live GitHub calls; targeted in-place edits only)

## F-1 (SHOULD) — false audit sentence in the committed IMPL-REPORT

**Independently verified first:** `grep -n "Resolution: n/a" scripts/pack-td.sh`
→ `259:  Resolution: n/a    → Resolution: $res_text`. Read in context
(`pack-td.sh:251-264`): it sits inside the F4/BD-107 BACKLOG-patch advisory
heredoc printed to **stderr** for the human operator — prose, never parsed,
so the Defect-C parse change cannot affect it (the parse change touches only
`_tmf_parse_backlog_file`'s `resolution` projection; this text never enters
that parser). The review's rationale confirmed.

**Edit 1** — `IMPL-REPORT-BD-204-RUN3-FIXES.md` § Defect C "Optional-H2 audit":

- Before: `` `Resolution: n/a` (the non-canonical header spelling, found only
  in test fixtures) normalizes identically — semantically the same "no
  resolution". ``
- After: same sentence minus the false "found only in test fixtures" claim,
  plus the true occurrence inventory: test fixtures
  (`scripts/tests/fixtures/tracker-promote/BACKLOG.md` + path1/path2 promote
  tests) PLUS the one non-test occurrence `scripts/pack-td.sh:259` (stderr
  advisory heredoc — prose, never parsed, unaffected by the Defect-C parse
  change; all three promote suites pass rc=0, FAIL: 0).

**Edit 2** — same file, Plan-deviation 2(c):

- Before: `(c) `Resolution: n/a` appears nowhere outside test fixtures.`
- After: `(c) `Resolution: n/a` appears in no PARSED content outside test
  fixtures (its one non-test occurrence, `scripts/pack-td.sh:259`, is unparsed
  advisory prose in a stderr heredoc — see the Optional-H2 audit note above).`

The fixture-canonicalization decision's other two grounds (emitter
else-branch; 40 live `Resolved: n/a` entries) are untouched. No code change
(per the review: none required).

## F-2 (NIT) — ambiguous re-run `links:` summary line

`scripts/lib/tracker-migrate-forward.sh` summary emit (was line 1872).
Encoding-surface sweep BEFORE editing: `grep -rn "links:" scripts/tests/` →
no hits; `grep -rn "blocked-by=" scripts/ supporting-docs/ project-template/`
→ only the emit line itself. No test or doc pins the wording — safe.

- Before: `  links:      parent=$linked_parent, blocked-by=$linked_blocked`
- After: `  links:      parent=$linked_parent, blocked-by=$linked_blocked (ensured present)`
  plus a 7-line `# BD-204 F-2:` comment above the heredoc documenting the
  "ensured present" (not "created this run") semantics and why the
  orchestrator cannot split ensured-vs-created (provider stdout discarded;
  threading the `already_linked` marker not warranted for a summary line).

This is the review's recommended option (a) — "links ensured" semantics,
documented at the summary heredoc — with the smallest printed-output change
that removes the operator-facing ambiguity.

## POQ-1 — heredoc backtick noise in the forward-test fake-gh

`scripts/tests/tracker-migrate-forward-test.sh` Group-3 fake-gh unquoted
`<<FAKEGH` heredoc (spans 519-593; verified the 535-536 pair is the ONLY
backtick occurrence inside it).

- Before (lines 535-536): `` # can see it reflected in subsequent `issue list --state `` /
  `` # closed --label …` calls. … `` — executed as command substitution at
  heredoc expansion.
- After: both backticks escaped (`` \` ``); comment text byte-identical
  otherwise. The review's directive honored: backticks escaped, delimiter NOT
  quoted (the heredoc's intended expansions are preserved).

**Gone-stderr proof:**

- BEFORE (this session, pre-edit): suite run captured
  `scripts/tests/tracker-migrate-forward-test.sh: line 519: issue: command
  not found` on stderr (grep hit count 1); suite 183/0, rc=0.
- AFTER: same run; `grep -c "command not found"` on captured stderr → **0**;
  remaining stderr is only the expected `per-entry decompose: wrote N entry
  file(s)` functional lines; suite **183 passed / 0 failed**, rc=0.

## Files changed this fix pass

| Path | Change | Delta vs pre-fix tree |
|---|---|---|
| `maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-RUN3-FIXES.md` | F-1: two sentence corrections (Optional-H2 audit + Plan-deviation 2(c)) | 2 targeted Edits |
| `scripts/lib/tracker-migrate-forward.sh` | F-2: summary-line qualifier + comment | +8 / −1 (file now +30/−1 vs HEAD) |
| `scripts/tests/tracker-migrate-forward-test.sh` | POQ-1: 2 backticks escaped in heredoc comment | +2 / −2 (file now +20/−2 vs HEAD) |

End-state `git status --porcelain`: the same 8 modified `scripts/` files +
the 2 untracked reports + this report. No new files elsewhere; no deletions.
Plan deviations: none. New POQs: none (the only out-of-scope observations
were already covered by the reviewer's report).

Note: the original IMPL-REPORT's "New POQs" § still records POQ-1's
surfaced-not-fixed state — that is historically accurate for the
implementation pass; THIS report records its resolution in the fix pass.

## Verification (full CI battery, FOREGROUND, at the fixed tree)

Syntax: `bash -n` on both edited shell files → SYNTAX-OK.

Changed/affected suites: forward **183/0** (stderr noise GONE), reverse
**147/0**, roundtrip **70/0**, links **43/0**, BD-204 oracle (env unset) →
`SKIP: live-GH oracle (…)`, rc=0 (default-SKIP intact).

Validators: `python3 scripts/validate-pack.py` → `PASSED — all checks clean`;
`PACK_VALIDATE_DEEP=1` variant → same.

Every `.github/workflows/validate-pack.yml` tests-job step run locally,
foreground, rc=0 each: detect 100/0; tracker-provider / config / init /
agent-read; phase-task; cycle-check; errors; config-schema;
recommendation-state-schema; per-entry 57/57; per-check suites 32-34 (85/85),
36-38, 39, 40, 41, 18, 16, 19, 42, 43, 44, 45, 46, removed-doc-advisory,
49-field-faithfulness; bd129 14/0; bd130 24/0; bd132 29/0; bd133; bd134 24/0;
recommendation; pack-help; customization-preserve; init-project;
migrate-v10-to-v11 (+dry-run +gates +decompose); migrator-core 19/0;
migrator-manifest 12/0; migrator-capability-translation 12/0;
`test-fixtures/build.sh --all --clean` rc=0 + `--verify` all 6 rows OK;
realistic-ot **33/33**; migrator-skills 19/0; persona-contracts 3/3;
template-translations; template-version; issue-forms. Off-CI promote suites
(F-1 evidence): direct / path1 / path2 all rc=0, FAIL: 0. The workflow's
`git checkout HEAD -- test-fixtures/manifest.txt` step was NOT run (forbidden
git verb); the equivalent read-only check `git diff test-fixtures/manifest.txt`
was used instead (below). Live oracle stayed default-SKIP throughout.

Manifest: `bash test-fixtures/build.sh --all --clean` rc=0 ("manifest
written"); `git diff test-fixtures/manifest.txt` → EMPTY (0 lines);
`git status --porcelain test-fixtures/` → empty; `--verify` → all 6 rows OK
(v11-flat-file f9705c27…, v11-tracker-on 944ddee3…, existing-project-mid-dev
a54e081a…, v11-realistic-ot ae3fc6ff…, v10 rows unchanged). No staging needed.

## Read-in-full attestation (agents-read-rule-docs-in-full)

| File | Lines read |
|---|---|
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md` (full, incl. `## Pack memory`) | 579 |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-204-RUN3-FIXES.md` | 304 |
| `maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-RUN3-FIXES.md` (the F-1 target) | 422 |
| `…/memory/feedback_edit_in_place_not_full_rewrite.md` | 15 |
| `…/memory/feedback_verify_full_ci_suite.md` | 43 |
| `…/memory/feedback_agent_output_rules_applied_block.md` | 15 |
| `pack-ops/PACK-MEMORY-RATIONALE.md` § rules-applied-verification-block (conditional MUST-READ) | lines 196-235 |

## Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| agents-never-commit | Git verbs this session: `git rev-parse HEAD`, `git status` / `--porcelain`, `git diff` (numstat / per-file / manifest). Zero add/commit/push/tag/stash/reset/restore/checkout (the workflow's `git checkout HEAD -- …` step explicitly substituted with read-only `git diff test-fixtures/manifest.txt` → EMPTY). | COMPLIANT |
| per-action-approval-sub-agents | No `rm -rf` / `git rm` / trusted-file overwrites; only targeted Edit calls on 3 files + this report Write; scratch limited to `/tmp/bd204-fix1-*` + `/tmp/b*.log` capture files; fixture rebuild left `test-fixtures/` byte-identical (`git status --porcelain test-fixtures/` empty). | COMPLIANT |
| preflight-stop-means-stop | Emitted before this Write: `PREFLIGHT: 3/3 fixes complete; verification PASS; HEAD 451f20f4e4d665498aeb9101885fadb2ee503b5a; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-RUN3-FIXES-FIX1.md`. No parent stop message received. | COMPLIANT |
| agent-output-rules-applied-block | This table; conditional MUST-READ honored (`pack-ops/PACK-MEMORY-RATIONALE.md` § rules-applied-verification-block, lines 196-235, read this session); every row carries quoted measurement. | COMPLIANT |
| agents-read-rule-docs-in-full | All 5 prompt-named files read IN FULL via Read tool with line counts per the attestation table above (CLAUDE.md 579; review 304; original IMPL-REPORT 422; memories 15/43/15) + the conditional rationale section. | COMPLIANT |
| verify-full-ci-suite | `validate-pack.py` → "PASSED — all checks clean" rc=0; `PACK_VALIDATE_DEEP=1` → same; EVERY workflow tests-job step run FOREGROUND to completion (forward 183/0, reverse 147/0, roundtrip 70/0, links 43/0, detect 100/0, per-entry 57/57, 32-34 85/85, realistic-ot 33/33, fixtures build+verify rc=0, full list in § Verification). POQ-1 stderr noise confirmed GONE: `grep -c "command not found"` on captured forward-suite stderr = 0 (was 1 pre-fix, same session). Live oracle default-SKIP (pinned SKIP line, rc=0). | COMPLIANT |
| regenerate-manifest-v11-surface | `scripts/` touched → `bash test-fixtures/build.sh --all --clean` rc=0 ("manifest written"); `git diff test-fixtures/manifest.txt` → EMPTY (manifest-diff-lines=0); `--verify` all 6 rows OK. Empty post-rebuild diff is canonical → no staging needed. | COMPLIANT |
| edit-in-place-not-full-rewrite | 5 targeted Edit calls total (2 IMPL-REPORT sentences, 1 lib hunk, 1 test hunk ×1 two-line region); zero full-file Writes except THIS new report. Edited regions re-read post-edit via `sed -n 1864,1882p` (lib), `sed -n 533,538p` (test), `sed -n '/Optional-H2 audit/…/p'` + `grep -n "appears in no PARSED"` (report) — actual bytes confirmed, not intent. `git diff` shows only the intended hunks added to the pre-existing BD-204 diff. | COMPLIANT |
| pack-only | End-state `git status --porcelain`: 8 modified files all under `scripts/`, untracked = the 2 existing BD-204 reports (incl. the F-1-corrected IMPL-REPORT) + this report under `maintenance-docs/v11-implementation/`. Zero `project-template/` / `supporting-docs/` / pack-chat-only paths. | COMPLIANT |
| scope-deliverables-to-the-ask | Exactly F-1 + F-2 + POQ-1; no other working-tree content touched (numstat delta vs pre-fix tree confined to the 3 target files); no out-of-scope discoveries arose, so no new POQs; report kept terse. | COMPLIANT |
