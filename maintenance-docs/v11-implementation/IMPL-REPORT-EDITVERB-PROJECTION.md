# IMPL-REPORT — BD-204 edit verb derives H2 projection from raw_body

**Date:** 2026-06-12
**Branch:** v11-dev
**HEAD (worktree base, unchanged):** `6a3f15caaf0d322e0dd3b8a99ba66b69a6ea7ae6`
**Proposed commit subject:** `fix: v11 — BD-204 edit verb derives H2 projection from raw_body (comparator-caught maiden-run defect) (pack-only)`

---

## 1. Root-cause confirmation

Confirmed exactly as stated in the task. Pre-fix `tracker_edit_entry`
(`scripts/lib/tracker-edit.sh`), on a patch carrying ANY content field,
extracted the projection fields FROM THE PATCH
(`ed_description=$(... jq -r '.description // ""')` etc.) and passed them
to `tmf_compose_issue_body "$pack_id" "$ed_description" "$ed_context"
"$ed_resolution" "$ed_file_symbol" "$ed_raw_body"`. A raw-body-ONLY patch
(the `pack tracker edit --raw-body-file` shape — `cmd_edit` in
`scripts/pack-tracker.sh` builds `{raw_body: ...}` and nothing else when
only that flag is passed) therefore composed:

- gz64 blob: full body (correct — raw_body rides verbatim into
  `_tmf_gz64_encode`),
- `## Description` H2: EMPTY (composer always emits it),
- `## Context` / `## Resolution` / `## File / Symbol` H2s: OMITTED
  (composer's empty-omission rule).

The reverse comparator `_tmr_check_blob_h2_divergence`
(`scripts/lib/tracker-migrate-reverse.sh:825`) re-parses the blob through
the REAL forward parser and compares against the stored H2 sections — so
it (correctly) blocked every subsequent materialization with
`divergence: ... (Description,Resolution,File / Symbol)`, matching the
maiden-run error on issue #94 (BD-094) verbatim in shape. The C-7
oracle's CRUD leg (test 4.7) always passed synced explicit fields
alongside raw_body, so the raw-body-only path had zero coverage.

## 2. Parser-reuse decision (the seam)

**Seam chosen:** `_tmf_parse_backlog_file`
(`scripts/lib/tracker-migrate-forward.sh:402`) — raw_body written to a
temp file, parsed, projection fields extracted via
`jq -r '.[0].<field> // ""'`.

**Why this seam and not another:**

- It is the SINGLE grammar all three projection actors already share:
  the forward migration (`tracker_migrate_forward_run` entry loop), the
  Mode-3 create path (`cmd_new_entry` step 2 — its doc comment names
  this exact reuse: "parse the --body-file verbatim entry span through
  the REAL forward parser (`_tmf_parse_backlog_file`)"), and the
  divergence comparator itself (`_tmr_check_blob_h2_divergence` lines
  839-854 do precisely `mktemp` → `printf raw_body` →
  `_tmf_parse_backlog_file` → `jq '.[0].description'` ...). Deriving the
  edit verb's projection through the SAME parser makes the composed
  result comparator-CLEAN **by construction** — the comparator's
  expectation and the composer's input are now the same parse.
- raw_body is defined as the verbatim entry span starting at the
  `**BD-NNN — title**` bold-header line, which is exactly a
  single-entry input to the parser — no synthesis or wrapping needed.
- No field extraction was re-implemented; the fix is ~20 lines of
  plumbing (temp file + four guarded `jq` reads) plus comments.
- The forward lib is already sourced by `tracker-edit.sh` (the existing
  `tmf_compose_issue_body` source block), so no new source wiring.

**Unparseable raw_body:** derives nothing (falls through with the
patch's literal fields). This mirrors the comparator, which SKIPS the
H2 check when the blob is unparseable (`[[ -z "$parsed" || "$parsed" ==
"[]" ]] && return 0` — the corrupt-blob guards own that class), so the
composed result stays comparator-consistent in that branch too.

**Precedence (documented in both the function-contract comment and the
inline fix comment):** an explicitly-provided patch field ALWAYS
overrides the parsed value; only fields absent from the patch are
parse-derived. Per the `cmd_edit` patch contract, absent and empty are
identical (empty flags never ride), so "absent" = empty-string at the
lib level. The blob continues to carry raw_body verbatim either way —
only the H2 projection derivation changed.

## 3. Per-file edits

### `scripts/lib/tracker-edit.sh` (modified; 412 → 469 lines, +57, 0 deletions)

1. **Function-contract comment** (`tracker_edit_entry` header, the
   `raw_body` key paragraph): appended the "PROJECTION DERIVATION +
   PRECEDENCE (C-8 maiden-run fix)" paragraph documenting derivation
   via `_tmf_parse_backlog_file` and explicit-field precedence.
2. **Derivation block** (inside the `has_content == 1` branch,
   immediately after the `ed_raw_body` sentinel extraction, before the
   `tmf_compose_issue_body` call): when `ed_raw_body` is non-empty,
   parse it via temp file + `_tmf_parse_backlog_file`; for each of
   `ed_description` / `ed_context` / `ed_resolution` / `ed_file_symbol`
   that is empty (absent from the patch), fill from
   `jq -r '.[0].<field> // ""'`. `mktemp` failure fails loud (typed
   validation error, no provider op attempted). Unparseable raw_body
   derives nothing.

### `scripts/tests/tracker-provider-test.sh` (modified; 1397 → 1463 lines, +66, 0 deletions)

New Group-4 legs inserted between 4.7b and 4.8:

- **4.7c (pinned regression, red-green):** raw-body-only patch
  (`{raw_body: ...}` with Description, Context, Resolution,
  File/Symbol field lines in the raw span). Asserts: provider_update
  fires; each of the four H2 values appears in the composed payload;
  and — the oracle the task demanded — decodes the payload's gz64 blob
  and runs the REAL body comparator `_tmr_check_blob_h2_divergence`
  against the payload body, asserting CLEAN (rc=0). Pre-fix this leg
  fails (hollow H2s; comparator rc=1).
- **4.7d (precedence):** mixed patch (`raw_body` + explicit
  `description`). Asserts the explicit description wins in the H2, the
  parsed description does NOT appear, and the absent context/resolution
  still derive from raw_body. (Comparator deliberately not asserted
  here: an explicit field that disagrees with raw_body composes a
  blob-vs-H2 divergence by definition — flagging that is the
  comparator's job; the leg pins only the precedence contract.)

Status-coherence note: the task named `_tmr_check_status_coherence` as
the status comparator; it is not exercised by these legs because the
fix scope is the H2 body projection (the maiden-run divergence class).
See POQ-2 for the adjacent status-line gap.

## 4. Red-green evidence (revert-probe in the sandbox copy)

Method: `.git`-stripped sandbox copy at `/tmp/bd204-c8-sandbox`
(tracked files, working-tree content). RED = sandbox lib overwritten
with the PRE-FIX `git show HEAD:scripts/lib/tracker-edit.sh`; new tests
in place. GREEN = fixed lib restored byte-exact (`cmp -s` verified).

**RED (pre-fix lib + new tests): suite rc=1, 7 pinned FAILs**

```
FAIL 4.7c raw-body-only edit derives the Description H2 from raw_body
FAIL 4.7c raw-body-only edit derives the File / Symbol H2 from raw_body
FAIL 4.7c raw-body-only edit derives the Context H2 from raw_body
FAIL 4.7c raw-body-only edit derives the Resolution H2 from raw_body
FAIL 4.7c raw-body-only edit: blob ↔ H2 comparator CLEAN (pre-fix shape diverged)
FAIL 4.7d mixed patch: absent context still derives from raw_body
FAIL 4.7d mixed patch: absent resolution still derives from raw_body
```

(4.7d's "explicit description wins" legs pass pre-fix as expected —
explicit fields always rode; the comparator-CLEAN leg is the exact
maiden-run defect pin.)

**GREEN (fixed lib): suite rc=0, 218 PASS / 0 FAIL, "All tests passed."**

## 5. Verification counts

| Step | Where | Result |
|---|---|---|
| `bash -n` both edited files | main tree (syntax only) | OK |
| `python3 scripts/validate-pack.py` | sandbox | `PASSED — all checks clean` |
| `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | sandbox | `PASSED — all checks clean` |
| `tracker-provider-test.sh` (subject suite) | sandbox | 218 PASS / 0 FAIL |
| Full CI `tests`-job battery — 44 further legs (all `scripts/tests/*` CI-wired suites incl. realistic-ot, fixture `--verify`, migrator-skills, template/issue-forms, per-entry, all validate-pack per-check suites, bd129-134) | sandbox | ALL PASS |
| 9 repo-git-dependent CI legs (detect, init-project, migrate-v10-to-v11 x4, migrator-core, migrator-manifest, persona-contracts) | isolated `/tmp` clone (see deviations) | ALL PASS |
| `tracker-bd204-lossless-roundtrip-test.sh` (live oracle) | sandbox | default-SKIP, exit 0: `SKIP: live-GH oracle (set PACK_TRACKER_LIVE_GH=1 + gh auth to run)` |
| `bash test-fixtures/build.sh --all --clean` | main tree (rule-7 mandate) | all six fixtures built |
| `git diff test-fixtures/manifest.txt` | main tree | EMPTY (no drift) |
| `bash test-fixtures/build.sh --verify` | main tree | all six rows OK |

Battery total: 56 legs (47 sandbox + 9 isolated clone), 0 failures;
`FAILED-SUITES:none` / `ALL-GREEN` from the atomic script.

**Manifest no-drift explanation (rule 7 evidence):** the `scripts/`
trigger fired and the rebuild ran, but the rebuilt manifest is
byte-identical to the committed one — verified empirically:
client installs receive a CURATED scripts subset
(`test-fixtures/v11-flat-file/scripts/lib/` contains only `detect.sh`;
`find` over all three v11 fixtures returns no `tracker-edit.sh` or
`tracker-provider-test.sh`). Per the rule's own authority clause ("the
manifest diff after rebuild is the canonical authority — the trigger
globs are a screen for WHEN to run the rebuild"), no manifest staging
is needed.

## 6. Plan deviations

1. **Nine CI legs ran in an isolated `/tmp` git clone, not the
   `.git`-stripped sandbox.** They fail there by construction
   (`error: v10 baseline tag 'v10' not present in pack repo at
   /tmp/bd204-c8-sandbox`; init-project PACK-root git validation) —
   they intrinsically require the pack repo to be a git repo with the
   v10 tag. Resolution: `git clone` (read-only on the source) to
   `/tmp/bd204-c8-gitclone`, the two edited files overlaid so clone
   content == working tree, fixtures copied in, verified (v10 tag
   present, no local tracker.toml leak). All mutation surface confined
   to the clone; the main tree executed nothing for these legs. None
   of the nine touches `tracker-edit.sh`.
2. **Fixture rebuild + `--verify` ran in the MAIN tree**, as the
   manifest-regen Pack-memory rule explicitly mandates ("run
   `bash test-fixtures/build.sh --all --clean` from the pack root" —
   the manifest diff must be checkable in git). Fixture trees are
   gitignored build output; the build's git verbs act on scratch
   fixture repos and a read-only v10 clone of the pack repo, never the
   pack repo's git state.
3. **The atomic script was invoked twice** (ledger-resume design): the
   first invocation completed sandbox creation + verification +
   red-green + 47 sandbox legs; the second added Phase 3 (the isolated
   clone) for the nine repo-git-dependent legs and skipped all
   completed work via `.ok` markers. Sandbox creation + verification +
   use all live in the one script (`/tmp/bd204-c8-atomic.sh`).

No deviations from the FIX DESIGN itself: parser-reuse seam, precedence,
and test shapes are exactly as the task specified.

## 7. New POQs introduced

- **POQ-1 — H2-only edits wipe an existing gz64 blob.** A patch
  carrying a projection field but NO `raw_body` (CLI:
  `pack tracker edit --description ... ` without `--raw-body-file`)
  recomposes via `tmf_compose_issue_body` with empty raw_body → the
  composed body carries NO `pack-entry-body-gz64` marker → the
  provider_update REPLACES the issue body, destroying any existing
  blob. Reverse then silently degrades to legacy H2 reconstruction
  (the comparator skips blob-less issues). Pre-existing behavior, NOT
  introduced or worsened by this fix; adjacent defect class.
  **Disposition:** surfaced for Pack Chat triage (candidate new BD);
  not fixed here per scope-deliverables-to-the-ask.
- **POQ-2 — raw-body-only edit with a changed `Status:` line does not
  project status.** The fix derives the four H2 projection fields
  only. A raw_body whose `Status:` line changed, without an explicit
  `--status`, updates the blob but not the `status:*` label /
  open-closed state; `_tmr_check_status_coherence` would then
  (correctly) flag at materialization — same defect shape as the one
  fixed here, but on the status projection (DP-3) rather than the H2
  body. **Disposition:** surfaced for Pack Chat triage (candidate
  fold-in with POQ-1); not fixed here per
  scope-deliverables-to-the-ask.

## 8. Boundary discipline check

All edits are pack-side (`scripts/lib/`, `scripts/tests/`). No
`project-template/`, `supporting-docs/`, or other client-shipped
surface touched (fixture check in §5 confirms the edited files are not
client-installed). No project-side SSOT investigation applicable; no
boundary-discipline stop. No pack-only references added to any
project-side file (none edited).

## 9. Definition-of-Done checklist

| Item | Status |
|---|---|
| Raw-body-only edit derives H2 projection by parsing raw_body via the real forward parser (no re-implemented extraction) | PASS (§2, §3; leg 4.7c) |
| Explicit patch fields override parsed values; precedence documented in the function comment | PASS (§3; leg 4.7d; contract + inline comments) |
| Blob carries raw_body verbatim; only projection derivation changed | PASS (composer call unchanged; 4.7c blob-decode assert) |
| Test 1: raw-body-only edit → comparator (`_tmr_check_blob_h2_divergence`) CLEAN on composed result | PASS (4.7c, rc=0 green) |
| Test 2: mixed patch → explicit field wins | PASS (4.7d) |
| Test 3: pre-fix shape pinned as regression (red-green revert-probe in sandbox) | PASS (§4: RED rc=1 with 7 pinned FAILs; GREEN 218/218) |
| `validate-pack` + DEEP green | PASS (§5) |
| Full unattended CI battery green; live oracle default-SKIP | PASS (§5: 56 legs, 0 fail) |
| Manifest rule honored (rebuild + diff + verify, evidence) | PASS (§5: rebuild ran; diff empty; verify OK) |
| Untouched text byte-stable (edit-in-place) | PASS (§10: diff is 123 insertions, 0 deletions) |
| No git state changes; no live GH calls | PASS (§10 evidence rows) |

## 10. Files changed + Rules-Applied Verification

**Files changed inventory:**

| Path | Type | Delta |
|---|---|---|
| `scripts/lib/tracker-edit.sh` | modified | +57 / -0 |
| `scripts/tests/tracker-provider-test.sh` | modified | +66 / -0 |
| `maintenance-docs/v11-implementation/IMPL-REPORT-EDITVERB-PROJECTION.md` | new (this report) | — |

No new source files; full contents of new files: none beyond this
report.

**Read-in-full attestation (agents-read-rule-docs-in-full):**

| File | Lines | Read |
|---|---|---|
| `CLAUDE.md` § Pack memory (pack root) | 590 (file) | IN FULL (verbatim in session context; Pack memory section complete) |
| `scripts/lib/tracker-edit.sh` (pre-edit) | 412 | IN FULL |
| `~/.claude/.../memory/feedback_edit_in_place_not_full_rewrite.md` | 15 | IN FULL |
| `~/.claude/.../memory/feedback_verify_full_ci_suite.md` | 43 | IN FULL |
| `~/.claude/.../memory/feedback_agent_output_rules_applied_block.md` | 15 | IN FULL (+ mandated follow-up: `pack-ops/PACK-MEMORY-RATIONALE.md` § rules-applied-verification-block) |
| Section reads | — | `_tmf_parse_backlog_file` (tmf:344-643), `tmf_compose_issue_body` (tmf:1040-1175), `_tmr_check_blob_h2_divergence` (tmr:800-944), `cmd_edit` (pack-tracker.sh:250-394), Group 4/5 edit legs (provider test:900-1130) |

## Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| agents-never-commit | Only read-only git verbs ran: `rev-parse`, `status`, `diff`, `show HEAD:...`, `ls-files`, `clone` (read-only on source, target /tmp). Final `git status --porcelain` shows ` M scripts/lib/tracker-edit.sh`, ` M scripts/tests/tracker-provider-test.sh` + 3 pre-existing untracked docs; HEAD unchanged at `6a3f15c...`. No add/commit/push/tag/stash/reset/restore/checkout anywhere. | COMPLIANT |
| per-action-approval-sub-agents | No destructive ops on repo files; `rm -rf` used only on self-created /tmp scratch (`/tmp/bd204-c8-*`). GitHub MCP tools appeared mid-session and were NEVER invoked (sandbox protocol: no live GH; lossless oracle default-SKIPped: "SKIP: live-GH oracle"). | COMPLIANT |
| preflight-stop-means-stop | PREFLIGHT line emitted verbatim before this Write: "PREFLIGHT: 2/2 in-scope file edits complete; verification PASS; HEAD 6a3f15caaf0d322e0dd3b8a99ba66b69a6ea7ae6; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPL-REPORT-EDITVERB-PROJECTION.md". No stop message received at any point. | COMPLIANT |
| agent-output-rules-applied-block | This table, per the format in `pack-ops/PACK-MEMORY-RATIONALE.md` § rules-applied-verification-block (read this session, lines 206-233: "per-rule table `Rule | Verification evidence | Conclusion`"). Every row carries non-empty quoted evidence. | COMPLIANT |
| agents-read-rule-docs-in-full | Attestation table in §10: all five named docs read in full with line counts (590 / 412 / 15 / 43 / 15) + the five mandated section-reads with line ranges. | COMPLIANT |
| verify-full-ci-suite | §5: `validate-pack.py` and DEEP both "PASSED — all checks clean"; full CI tests-job battery 56 legs ALL PASS (`FAILED-SUITES:none` / `ALL-GREEN`); subject suite 218 PASS / 0 FAIL; live oracle pinned SKIP exit 0. Integration legs (realistic-ot, fixture verify) included, not just unit suites. | COMPLIANT |
| regenerate-manifest-v11-surface | `scripts/` touched → `bash test-fixtures/build.sh --all --clean` ran in main tree ("manifest written: .../test-fixtures/manifest.txt"); `git diff test-fixtures/manifest.txt` EMPTY; `--verify` all six rows OK. Empirical cause of no-drift: edited files are not client-installed (fixture `scripts/lib/` contains only `detect.sh`). Diff-after-rebuild is the rule's canonical authority → nothing to stage. | COMPLIANT |
| edit-in-place-not-full-rewrite | `git diff --stat`: "2 files changed, 123 insertions(+)" — ZERO deletions; all changes are targeted Edit insertions (3 Edit calls total); untouched text byte-stable by diff shape. No full-file rewrite of any existing file. | COMPLIANT |
| pack-only | Final diff touches only `scripts/lib/tracker-edit.sh` + `scripts/tests/tracker-provider-test.sh` (+ this report under `maintenance-docs/`) — no `project-template/`, no `supporting-docs/`. Added pack-side text contains no phase refs (added comments reference BD-204 / C-8 / DP-3 / §3.3a, no `phase-N`). | COMPLIANT |
| scope-deliverables-to-the-ask | Exactly the defect + its coverage: one derivation block + contract comment + two test legs. Adjacent discoveries (blob-wipe on H2-only edit; status-line projection gap) recorded as POQ-1 / POQ-2 in §7 with dispositions, NOT implemented. | COMPLIANT |
