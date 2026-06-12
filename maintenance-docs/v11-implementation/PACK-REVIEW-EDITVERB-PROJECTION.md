# PACK-REVIEW — BD-204 edit verb derives H2 projection from raw_body (reviewer pass 1)

**Date:** 2026-06-12
**Branch:** v11-dev — HEAD `6a3f15caaf0d322e0dd3b8a99ba66b69a6ea7ae6` (unchanged throughout)
**Scope reviewed:** uncommitted 2-file diff — `scripts/lib/tracker-edit.sh` (+57/-0),
`scripts/tests/tracker-provider-test.sh` (+66/-0) — plus the coder report
`maintenance-docs/v11-implementation/IMPL-REPORT-EDITVERB-PROJECTION.md`.

## Verdict: APPROVE-WITH-FIXES

The fix itself is correct, minimal, comparator-clean by construction, and
independently red-green verified. The findings below are adjacent-defect
dispositions (POQ-1/POQ-2 as the prompt required) plus one create/edit
guard asymmetry the new parse block makes nearly free to close. Nothing in
the diff is wrong; F1/F2 should land in this review cycle before the verb's
next real use (the pending #94/#204/#205 re-edits are raw-body-only and are
NOT exposed to F1/F2, so the re-edit itself is safe either way).

---

## 1. What I verified (clean unless flagged)

### 1.1 Derivation seam is genuinely the comparator's own — CONFIRMED

Traced both paths end-to-end:

- **Edit path (post-fix):** `tracker_edit_entry` (`scripts/lib/tracker-edit.sh:353-377`)
  writes `ed_raw_body` (trailing-newline-faithful, sentinel idiom, line 331-332)
  to a temp file → `_tmf_parse_backlog_file` → `jq '.[0].<field> // ""'` for each
  absent field → `tmf_compose_issue_body` (`scripts/lib/tracker-migrate-forward.sh:1075`),
  which projects each field through `_tmf_neutralize_autolinks` (lines 1092-1095)
  and encodes the blob from `raw_body` verbatim (line 1101).
- **Comparator path:** `_tmr_check_blob_h2_divergence`
  (`scripts/lib/tracker-migrate-reverse.sh:825`) decodes the identical blob bytes
  → temp file → the SAME `_tmf_parse_backlog_file` (line 843) → the SAME
  `jq '.[0].<field>'` extraction (851-854) → the SAME `_tmf_neutralize_autolinks`
  (857-860) → `norm()` (CRLF/CR→LF, per-line trailing-ws strip, single trailing
  newline) applied identically to both sides (878-899).

**No normalization asymmetry between parse-for-compose and parse-for-compare:**
both sides run parse→neutralize over byte-identical input; `norm()` is applied
symmetrically. Two sub-points checked explicitly:

- The composer's empty-omission conditionals (forward lib 1113-1121) test the
  RAW field while emitting the NEUTRALIZED value — safe because
  `_tmf_neutralize_autolinks` never maps non-empty→empty.
- `## Description` is unconditionally emitted even when empty; the comparator's
  `_tmr_extract_section` of an empty section returns `""`, and
  `norm("") == norm("")` — probe P2 confirms CLEAN.
- Multi-entry raw_body: both sides use `.[0]` — symmetric (see F2 for the
  hazard this leaves open at tree-materialization, which the comparator
  structurally cannot see).

### 1.2 Precedence incl. explicit-empty-string — CORRECT, NOT AMBIGUOUS

- `cmd_edit` (`scripts/pack-tracker.sh:348-371`) builds the patch with
  `if $field != "" then {...} else {} end` — **empty flags never ride**, so at
  the CLI, `--description ""` is byte-identical to omitting the flag.
- At the lib level, `jq -r '.description // ""'` plus the `[[ -z ... ]]`
  derivation guards collapse explicit-`""` and absent identically → **derive**.
  Probe P1 (explicit `description:""` + raw_body) empirically confirms: derived
  from raw_body, real comparator CLEAN.
- **Which SHOULD it be:** derive. With raw_body present the blob is truth;
  "wipe" semantics (compose an empty H2 over a non-empty blob field) would
  produce a guaranteed comparator divergence by construction. To genuinely
  remove a field's content, the caller edits the raw_body — which is the SSOT
  contract. The function-contract comment (tracker-edit.sh:212-223) documents
  exactly this. Not flagged.

### 1.3 Regression leg has teeth — RED-GREEN REPRODUCED INDEPENDENTLY

In my own `.git`-stripped sandbox (`/tmp/revw-edv/sb`), pre-fix lib obtained
via read-only `git show HEAD:scripts/lib/tracker-edit.sh`:

- **RED** (pre-fix lib + new tests): suite rc=1, exactly the 7 pinned FAILs the
  coder reported (4×4.7c H2-derivation, 1×4.7c comparator-CLEAN, 2×4.7d
  absent-field derivation). The comparator-CLEAN leg (4.7c) fails RED — the
  exact maiden-run defect is pinned by the REAL oracle, not a string assert.
- **GREEN** (fixed lib restored, `cmp`-verified byte-exact): rc=0,
  **218 PASS / 0 FAIL**, "All tests passed."

Leg quality: 4.7c decodes the actual gz64 payload blob and runs the REAL
`_tmr_check_blob_h2_divergence` against the composed payload — the strongest
available oracle. 4.7d pins precedence both directions (explicit wins, parsed
value absent from H2, absent fields still derive) and correctly does NOT
assert the comparator (an explicit field disagreeing with raw_body is
divergence by definition — flagging it is the comparator's job).

### 1.4 Parse-seam edge cases — probed against the real comparator

All probes ran in the sandbox through the real `tracker_edit_entry` →
real composer → real comparator (`/tmp/revw-edv/probes.sh`):

| Probe | Shape | Result |
|---|---|---|
| P1 | explicit `description:""` + raw_body | DERIVED; comparator CLEAN |
| P2 | raw_body with NO Description field | empty `## Description` emitted; comparator CLEAN |
| P3 | raw_body with bare `Resolved: n/a` | no Resolution H2 (parser n/a→empty convention honored); comparator CLEAN |
| P4 | multiline continuation Description/Context | carried into H2; comparator CLEAN |
| P5 | projection-only patch, no raw_body | **NO blob marker in composed body** → F1/POQ-1 confirmed lossy |
| P6 | raw-body-only patch with `Status: Resolved` | no `provider_close`, `add_labels=[]` → POQ-2 confirmed |
| P7 | explicit `resolution:"n/a"` + raw_body `Resolved: n/a` | literal `n/a` H2 emitted; comparator **DIVERGENT** → F4 |
| P8 | raw_body header `**BD-002**` while editing BD-001 | rc=0, update dispatched to issue 42, blob carries BD-002 span → F2 |

Unparseable raw_body (no header): derives nothing and composes with patch
literals; comparator skips unparseable blobs
(`tracker-migrate-reverse.sh:848`) — consistent in that branch too (verified
by code trace; same skip predicate `-z || == "[]"` on both sides).

### 1.5 Battery + manifest + keyword — ALL VERIFIED

- **Full CI `tests`-job battery, all FOREGROUND, run by me** (not trusted from
  the coder report): 47 sandbox legs (subject suite 218/0; validate-pack +
  DEEP both "PASSED — all checks clean"; all 13 tracker suites; all 15
  per-check validator suites; bd129-134; recommendation; pack-help;
  customization-preserve; capability-translation; template-translations;
  template-version; issue-forms; fixture `--verify`; realistic-ot;
  migrator-skills) + 11 isolated-clone legs (detect, init-project,
  migrate-v10-to-v11 ×4, migrator-core, migrator-manifest, persona-contracts,
  fixture build `--all --clean`, fixture `--verify`) = **58 legs, 0 failures**
  (`FAILED-SUITES:none`). Live oracle `tracker-bd204-lossless-roundtrip-test.sh`:
  default-SKIP exit 0 ("SKIP: live-GH oracle"), as mandated.
- **9 repo-git-dependent legs — coder deviation ASSESSED AND ACCEPTED:** these
  suites intrinsically require the pack repo to be a git repo carrying the
  `v10` tag (the migrators clone the pack at the v10 baseline;
  init-project/persona validate against pack git state). A `.git`-stripped
  sandbox cannot run them by construction. The coder's isolated `/tmp` clone
  is the correct shape; I replicated it (clone → checkout v11-dev → overlay
  the 2 edited files, `cmp`-verified → v10-tag + no-tracker.toml-leak
  verified) and all 9 pass. `git clone` is read-only on the source.
- **Manifest (rule 7) — verified WITHOUT writing the main tree** (improvement
  over the coder's main-tree rebuild): rebuilt all six fixtures in the
  isolated clone (content == working tree) and ran `git -C clone diff --
  test-fixtures/manifest.txt` → **EMPTY**. Coder's empty-diff claim VERIFIED.
  Main-tree `git diff test-fixtures/manifest.txt` is also 0 lines. The
  no-drift cause checks out: neither edited file is client-installed
  (fixture `scripts/lib/` carries only `detect.sh`).
- **Commit-subject keyword:** proposed subject carries `(pack-only)`. Diff
  touches `scripts/lib/`, `scripts/tests/` (+ the IMPL-REPORT under
  `maintenance-docs/`) — no `project-template/`, no `supporting-docs/` →
  Check 36 compatible. Boundary discipline (P-missed-7): no project-side
  surface touched; no SSOT investigation applicable.

---

## 2. Findings

### F1 (MUST) — POQ-1: projection-only edit silently destroys the gz64 blob (lossy-class, reachable from the documented CLI)

`tracker_edit_entry` with a patch carrying a projection field but no
`raw_body` (CLI: `pack tracker edit BD-NNN --description ...`, or the
canonical resolve flow `--status Resolved --resolution "..."`) enters the
`has_content` branch, composes via `tmf_compose_issue_body` with empty
raw_body → **no `pack-entry-body-gz64` marker** (forward lib 1099-1102 emits
the blob only when raw_body non-empty) → `provider_update` REPLACES the issue
body, destroying the existing blob. Probe P5 confirms. The loss is **silent**:
both comparators skip blob-less issues (`tracker-migrate-reverse.sh:834,951`),
and reverse degrades to legacy H2 reconstruction — the raw span's `Type:` /
`Status:` / `Blockers:` / `Unblocks:` lines and any interior `## Sub-entry`
content are NOT in the four H2 projections and are unrecoverable.

- **Can a current caller hit it?** Yes — `cmd_edit` accepts `--description`
  et al. without `--raw-body-file` (`scripts/pack-tracker.sh:284-287`), and
  the resolve flow (`--status Resolved --resolution ...`) is the single most
  likely real-world edit shape after the raw-body re-edit.
- **Pre-existing, not introduced by this diff** — but this diff's new contract
  comment ("a tracker-side edit never updates one without the other",
  tracker-edit.sh:57-62, 209-211) is now overbroad: the H2-only shape updates
  by destruction.
- **Deferral test (size/blocked/fit):** the FULL fix (provider_get → decode
  existing blob → splice the edited field into raw_body → recompose) is a
  real design exercise (merge semantics, conflict with concurrent GH edits)
  — SIZE defends anchoring it as a new BD. But a **fail-loud guard is small
  and a concrete same-file/same-contract fit with THIS commit**: in the
  `has_content` branch, when `ed_raw_body` is empty, refuse with a typed
  validation error directing the caller to `--raw-body-file` (BD-/TD- entries
  carry blobs by construction since forward migration; if blob-less phase
  epics must stay editable, scope the refusal to ids matching `^(BD|TD)-`).
  **Disposition recommendation: fold the guard now (this review cycle) +
  anchor the merge-edit UX as a new BD inserted immediately after BD-204's
  current work** (new-BD-open needs user approval per OQ-1). Until one of
  those lands, the lossy path is live on a verb in active use.

### F2 (SHOULD) — derivation block lacks cmd_new_entry's single-entry + id-match guards (silent, comparator-blind)

`cmd_new_entry` enforces, on the SAME parse of the SAME span shape:
exactly-one-entry (`scripts/pack-tracker.sh:462-467`) and parsed-id == given-id
(lines 469-474). The edit path's new derivation block enforces neither:
probe P8 shows editing BD-001 with a raw_body headed `**BD-002 — ...**`
dispatches rc=0, stamps `<!-- pack-id: BD-001 -->`, and stores a blob whose
verbatim span claims BD-002. The H2 comparator stays CLEAN (it compares field
values, not ids), so the corruption is invisible until the next
tree-materialization emits a BD-002-headed entry file under the BD-001
mapping. A multi-entry raw_body similarly derives from `.[0]` while the blob
carries BOTH entries verbatim into the tree.

Pre-existing in the sense that pre-fix raw_body rode into the blob unparsed —
but THIS diff adds the parse, making the guard ~8 lines in the exact block
touched (`_ted_parsed` already holds `.[0].pack_id` and `length`), mirroring
new-entry's error wording. **Disposition: fold now** (size trivial, logical
fit exact) + one test leg each (id-mismatch refusal, multi-entry refusal).

### F3 (SHOULD) — POQ-2: raw-body `Status:` change not projected (fail-loud downstream; anchor)

Probe P6 confirms: a raw-body-only patch whose span says `Status: Resolved`
updates the blob, fires no `provider_close`, adds no `status:*` label. The
blocking status-coherence comparator (`_tmr_check_status_coherence`,
`tracker-migrate-reverse.sh:943`) flags it at next materialization —
**fail-loud, not lossy**, exactly as the coder disclosed. Note the symmetry
datapoint: the CREATE path projects status from the parsed body
(`_tmf_labels_for_entry`, pack-tracker.sh:489), so edit is the only
projection actor that doesn't.

**Deferral test:** deriving `new_status` from `_ted_parsed` is 3 lines, BUT a
correct label swap needs the OLD `status:*` label removed — unknown without a
`provider_get` (or blob read) of current labels, and naive derivation accretes
stale `status:*` labels that make the reverse decode ambiguous. SIZE therefore
defends anchoring. **Disposition: anchor as a new BD — folds naturally with
F1's merge-edit BD ("edit-verb projection completeness": status + label
reconciliation + H2-only merge), inserted immediately after current BD-204
work, user approval required for the open.** Acceptable interim: it cannot
corrupt (comparator blocks), and the documented `--status`/`--old-status`
flags are the supported channel.

### F4 (NIT) — explicit literal `--resolution "n/a"` composes a guaranteed divergence

Probe P7: explicit `resolution:"n/a"` is non-empty → overrides → composer
emits `## Resolution\n\nn/a`; the comparator's expectation is parser-normalized
**empty** (forward lib 496-498), so the issue is divergence-blocked at next
materialization even though the user's input textually AGREES with the raw
body's `Resolved: n/a`. Fail-loud, narrow input. Cheap symmetric fix (~3
lines): normalize a bare (trimmed, case-insensitive) `n/a` explicit
resolution to `""` in the derivation block, matching the parser's
resolution-only convention — or ride the F3 anchor BD. Either disposition
acceptable.

### F5 (NIT) — contract-comment overclaim pending F1

`scripts/lib/tracker-edit.sh:57-62` ("the edit path is the producer that owns
keeping the two views in sync") and the §3.3a (i) restatement at 309-313 are
falsified by the F1 shape until its guard lands. If F1's guard folds into this
cycle, F5 dissolves; if F1 is anchored instead, annotate the gap at the
`has_content` branch with the typed format per pack memory
(`# KNOWN GAP(high): TD-TBD — H2-only edit wipes existing gz64 blob; see BD-NNN`).

---

## 3. Coder-report accuracy

Every checkable claim in `IMPL-REPORT-EDITVERB-PROJECTION.md` verified true:
root-cause (§1) matches the pre-fix code (`git show HEAD:` inspected);
seam rationale (§2) matches the comparator trace (§1.1 above); red-green (§4)
reproduced with identical FAIL set and counts; verification table (§5)
reproduced (sandbox + clone legs, oracle SKIP, manifest empty-diff); POQ
disclosures (§7) are accurate and complete for what the coder found — my
probes added F2 (id/single-entry guard asymmetry) and F4 (literal-n/a
divergence) beyond the disclosed set. Proposed commit subject is a sanctioned
`fix:` shape with a valid scope keyword.

---

## 4. Read-in-full attestation (agents-read-rule-docs-in-full)

| File | Lines | Read |
|---|---|---|
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md` § Pack memory | 590 (file); §140-590 read from disk this session | IN FULL (on-disk version, which supersedes the older session-context copy) |
| `scripts/lib/tracker-edit.sh` (post-fix) | 469 | IN FULL |
| `maintenance-docs/v11-implementation/IMPL-REPORT-EDITVERB-PROJECTION.md` | 292 | IN FULL |
| `~/.claude/.../memory/feedback_verify_full_ci_suite.md` | 42 | IN FULL |
| `~/.claude/.../memory/feedback_agent_output_rules_applied_block.md` | 14 | IN FULL (+ mandated follow-up: `pack-ops/PACK-MEMORY-RATIONALE.md` § rules-applied-verification-block, lines 206-233) |
| Section reads | — | `_tmf_parse_backlog_file` (forward 344-643), `tmf_compose_issue_body` (forward 1040-1180), `_tmr_check_blob_h2_divergence` + `_tmr_check_status_coherence` head (reverse 780-959), `cmd_edit` (pack-tracker 250-378), `cmd_new_entry` (pack-tracker 394-503), Group-4 legs + fake-gh harness (provider test 900-1135 + full +66 diff hunk) |

## Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| agents-never-commit | Only read-only git verbs ran: `status --porcelain`, `rev-parse`, `diff`/`diff --stat`, `show HEAD:...`, `tag -l`, `clone` (read-only on source; target `/tmp/revw-edv/gitclone`), `checkout`/`checkout HEAD -- manifest` INSIDE the isolated clone only. Final main-tree check: `git status --porcelain` = same 2 ` M` files + 4 pre-existing `??` docs (plus this report, written after); HEAD `6a3f15c...` unchanged; `git diff --stat` = "2 files changed, 123 insertions(+)". No add/commit/push/tag/stash/reset/restore on the main tree. Output = this report file only. | COMPLIANT |
| per-action-approval-sub-agents | No destructive ops on repo files; `rm -rf` confined to self-created `/tmp/revw-edv/*` and `mktemp` scratch. GitHub MCP tools appeared mid-session and were NEVER invoked; no live GH calls (oracle log: "SKIP: live-GH oracle"). No stop message received. | COMPLIANT |
| preflight-stop-means-stop | Emitted verbatim immediately before this Write: "PREFLIGHT: review complete; verification PASS; HEAD 6a3f15caaf0d322e0dd3b8a99ba66b69a6ea7ae6; about to Write report to /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/PACK-REVIEW-EDITVERB-PROJECTION.md". No parent stop/halt/revert message at any point. | COMPLIANT |
| agent-output-rules-applied-block | This table, per the fenced format in `pack-ops/PACK-MEMORY-RATIONALE.md` § rules-applied-verification-block (read this session, lines 206-233: "per-rule table `Rule \| Verification evidence \| Conclusion`"). Every row carries quoted non-empty evidence; no AMBIGUOUS terminal states. | COMPLIANT |
| agents-read-rule-docs-in-full | §4 attestation table: all 5 mandated docs read in full with line counts (590 / 469 / 292 / 42 / 14) + the mandated section reads with line ranges. CLAUDE.md Pack memory read from DISK (lines 140-590), not relied on from session context. | COMPLIANT |
| verify-full-ci-suite | Ran by me, all FOREGROUND: validate-pack + DEEP both "PASSED — all checks clean" (sandbox); full CI tests-job battery 58 legs / 0 failures = 47 `.git`-stripped-sandbox legs (incl. subject suite 218 PASS / 0 FAIL, realistic-ot, fixture `--verify`, migrator-skills) + 11 isolated-clone legs (incl. all 9 repo-git-dependent suites + fixture build/verify); ledger `FAILED-SUITES:none`. Live oracle default-SKIP exit 0. 9-leg deviation assessed and justified in §1.5 (tests intrinsically need the v10-tagged git repo). | COMPLIANT |
| regenerate-manifest-v11-surface | Coder's empty-diff claim INDEPENDENTLY verified read-only: `bash test-fixtures/build.sh --all --clean` in the isolated clone (content cmp-equal to working tree) → `git -C clone diff -- test-fixtures/manifest.txt` EMPTY; clone `--verify` all rows OK after restoring committed manifest (CI parity); main-tree `git diff test-fixtures/manifest.txt \| wc -l` = 0. Nothing to stage. | COMPLIANT |
| pack-only | `git diff --stat` = exactly `scripts/lib/tracker-edit.sh` + `scripts/tests/tracker-provider-test.sh`; untracked additions under `maintenance-docs/` only. No `project-template/`, no `supporting-docs/` → the proposed subject's `pack-only` keyword passes Check 36 semantics. | COMPLIANT |
| scope-deliverables-to-the-ask | Deliverable = this single review report: findings on the 2-file change (F2, F4, F5) + the prompted POQ dispositions (F1, F3) with size/blocked/fit arguments. No fixes applied by me, no new files beyond the report, no out-of-scope sweeps. | COMPLIANT |
