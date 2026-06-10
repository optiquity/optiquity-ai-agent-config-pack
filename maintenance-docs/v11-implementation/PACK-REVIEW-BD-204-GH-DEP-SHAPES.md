# PACK-REVIEW — BD-204 GH first-class dependency GraphQL shapes (reviewer pass 1)

- **Scope reviewed:** entire uncommitted working tree vs HEAD `08fd605606017374d6005de88e7b3b48432a79ca` (branch `v11-dev`).
- **Change under review:** rename `blockedByIssueId` → `blockingIssueId` (add/remove mutation arg) and `Issue.blockedByIssues` → `Issue.blockedBy` (reverse read field) across lib + tests + fixtures, with comment hedges upgraded from "unverified offline" to LIVE-VERIFIED (2026-06-10 introspection). Semantics (directionality convention) unchanged.
- **Footprint observed (`git status --porcelain`):** exactly the 6 expected modified files (`scripts/lib/tracker-provider-gh.sh`, `scripts/lib/tracker-migrate-reverse.sh`, `scripts/tests/tracker-provider-test.sh`, `scripts/tests/tracker-migrate-roundtrip-test.sh`, `scripts/tests/tracker-migrate-reverse-test.sh`, `scripts/tests/fixtures/tracker-provider/gh-list-blocked-by.json`) + 1 untracked coder IMPL-REPORT (`maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-GH-DEP-SHAPES.md`) + this report.

## Verdict

**APPROVE** — commit-ready as-is. Zero BLOCKER / MUST / SHOULD findings. One advisory NIT (Pack Chat triage item, not a change defect; see N-1).

---

## 1. Correctness vs schema ground truth (independently re-verified)

I re-ran the read-only introspection myself this session (no live mutations of any kind):

`AddBlockedByInput` inputFields (verbatim):

```
issueId          (ID!)  "The ID of the issue to be blocked."
blockingIssueId  (ID!)  "The ID of the issue that blocks the given issue."
clientMutationId (String)
```

`RemoveBlockedByInput` inputFields (verbatim):

```
issueId          (ID!)  "The ID of the blocked issue."
blockingIssueId  (ID!)  "The ID of the blocking issue."
clientMutationId (String)
```

`Issue` fields containing "block" (verbatim):

```
blockedBy  "A list of issues that are blocking this issue."  NON_NULL IssueConnection
blocking   "A list of issues that this issue is blocking."   NON_NULL IssueConnection
```

`Mutation` fields confirmed live: `addBlockedBy(input: AddBlockedByInput!)` and
`removeBlockedBy(input: RemoveBlockedByInput!)` both exist with those exact input
types. There is no `blockedByIssueId` arg and no `blockedByIssues` field — the
old shapes are conclusively disproven; the new code matches ground truth exactly,
including the new comment's gloss in `scripts/lib/tracker-provider-gh.sh`
("`issueId: ID!` (the issue that IS blocked) + `blockingIssueId: ID!` (the issue
that BLOCKS it)"), which matches the schema descriptions word-for-meaning.

### Directionality convention — PRESERVED exactly

The semantic role of the second argument is unchanged: old assumed
`blockedByIssueId` = "the issue [issueId] is blocked by" = the blocker; live
`blockingIssueId` = "the issue that blocks" = the blocker. Same operand, new name.
The operand-inversion wiring in both mutations is untouched (the `if [[ "$kind" ==
"blocked-by" ]]` blocks assigning `source_node`/`target_node` appear only as
unchanged context lines in the diff):

- `tracker_provider_gh_link` (`scripts/lib/tracker-provider-gh.sh`): kind=blocked-by →
  `issueId=$issue_node` (the blocked issue), `blockingIssueId=$other_node` (the
  blocker) — correct per the schema description. kind=blocks → operands inverted
  (`issueId=$other_node`, `blockingIssueId=$issue_node`) — "id blocks other" =
  other is blocked by id — correct.
- `tracker_provider_gh_unlink`: identical wiring against `removeBlockedBy` — correct.
- Tests pin the wiring: 1.17a/1.17b (link) and 1.20a/1.20b (unlink) in
  `scripts/tests/tracker-provider-test.sh` assert the exact `issueId=NODE_NN` /
  `blockingIssueId=NODE_NN` pairs for both kinds, including the inverted cases.
- Reverse read (`_tmr_fetch_first_class_blocked_by`, `scripts/lib/tracker-migrate-reverse.sh`):
  queries `issue(number: N).blockedBy` = "issues blocking this issue" = N's
  blockers, which is exactly what the Blockers-field decoder needs. jq path
  updated in lock-step (`.data.repository.issue.blockedBy.nodes[]?.number`).

A swapped operand would have shown up as a changed `source_node`/`target_node`
assignment or a swapped `-F` wiring; neither occurs anywhere in the diff.

## 2. Completeness — reviewer-leg grep-zero gate (rename-measure-then-bound)

Run independently by me at HEAD `08fd605` + working tree:

```
$ grep -rn "blockedByIssueId" scripts/ .github/
(no output) exit=1

$ grep -rn "blockedByIssues" scripts/ .github/
(no output) exit=1
```

ZERO hits for both old tokens in the in-scope set. Empty allowlist, as expected.

Repo-wide sweep (beyond the gate scope):

```
$ grep -rln "blockedByIssueId\|blockedByIssues" . --exclude-dir=.git
backlog/BD-111.md
maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-GH-DEP-SHAPES.md
maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-111.md
```

The coder's IMPL-REPORT legitimately quotes the old tokens (it documents the
rename); the other two are the POQ-1 historical sites assessed in §5.

### Mock/fixture echo agreement (no false-pass mocks)

Every encoding surface verified consistent with the new shapes:

- `scripts/tests/fixtures/tracker-provider/gh-list-blocked-by.json` — key now
  `blockedBy`; consumed via `cat` by reverse-test Groups 7.3 and 7.5
  (`G7_FIXTURE` at `scripts/tests/tracker-migrate-reverse-test.sh:931`); the lib
  jq path extracts it — verified by the 7.3/7.5 assertions passing (133/133).
- `scripts/tests/tracker-migrate-reverse-test.sh:1020` — Group 7.6 inline JSON
  emits `blockedBy` (empty-nodes legacy path).
- `scripts/tests/tracker-migrate-roundtrip-test.sh` stateful fake-gh — `-F` parse
  arm `blockingIssueId=*` (line 239); reverse-read dispatch arm
  `*"blockedBy(first"*` (line 273); response emitter `{... blockedBy: {nodes: ...}}`
  (line 286). The lib query string is `blockedBy(first: 50)` so the dispatch
  pattern matches; the mutation strings carry capital-B `addBlockedBy(input:` /
  `removeBlockedBy(input:` so they can NOT false-match the lowercase
  `blockedBy(first` pattern — the arm is order-independent as the coder's
  deviation note 2 claims. Verified sound.
- `scripts/tests/tracker-provider-test.sh` — all 8 renamed assertions
  (1.17a/b, 1.20a/b) plus 4 comment chains; dispatch-dir fixtures
  (`gh-add-blocked-by.json` / `gh-remove-blocked-by.json`) keyed by `api-graphql`
  filename, not by token — no stale keying.

## 3. No scope creep

The diff is exactly: token renames + the three hedge-comment blocks rewritten to
LIVE-VERIFIED (with the 2026-06-10 introspection date and BD-204 attribution),
directionality-convention explanations retained, EXTERNAL-RESEARCH §1.3/§1.8
citations retained where still load-bearing (mutation name source; 50-cap
ceiling). No behavior change outside the shapes: control flow, error handling
(`provider_raw` → `_gh_classify_error` swallow-and-`[]` fallback), the 50 cap,
and the de-dup/fold logic are all untouched context in the diff. The
`gh-remove-blocked-by.json` pointer dropped from the old unlink comment was part
of the now-obsolete wrong-guess contingency text — correct removal. No typed-
deferral comments added or needed (the BD-088/BD-093 "verify later" hedges are
now discharged, which is the point of the fix).

## 4. Verification (independently run)

- **Full unattended CI battery** per `.github/workflows/validate-pack.yml` tests
  job: **56/56 steps PASS, 0 FAIL** (log: `/tmp/bd204-review-battery.log`),
  comprising `validate-pack.py` normal + `PACK_VALIDATE_DEEP=1` (both
  "PASSED — all checks clean"), all 52 workflow test scripts, the live oracle,
  and the fixture-manifest verify.
- **Four directly affected mock suites** (counts captured): tracker-provider
  **127/0**, tracker-migrate-reverse **133/0**, tracker-migrate-forward **181/0**,
  tracker-migrate-roundtrip **51/0** (Passed/Failed).
- **Integration test** `scripts/tests/test-v11-realistic-ot.sh`: 33/33 PASS.
- **Live oracle default-SKIP honored:** `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh`
  → `SKIP: live-GH oracle (set PACK_TRACKER_LIVE_GH=1 + gh auth to run)`, rc=0.
  No live mutation was run by me or (per evidence) by the coder.
- **Manifest:** `git diff test-fixtures/manifest.txt` → empty;
  `bash test-fixtures/build.sh --verify` (read-only compare of built fixtures vs
  manifest) → all rows OK, rc=0 — independently confirms the coder's
  empty-diff claim. Consistent with `scripts/init-project.sh` not copying the
  tracker libs into client installs (grep for `lib/tracker|tracker-provider|tracker-migrate`
  in `scripts/init-project.sh` → no hits); per the rule's canonical-authority
  clause, the empty post-rebuild diff governs. No manifest change is owed.
- **pack-only holds:** all 6 modified files under `scripts/`; untracked additions
  are only the coder's IMPL-REPORT and this report (both `maintenance-docs/`,
  outside the Check 36 deny-set `project-template/` + `supporting-docs/`). The
  proposed commit subject's `pack-only` keyword claim is valid.
- **Tree state after my review runs:** `git status --porcelain` identical to the
  pre-review footprint; HEAD unchanged at `08fd605`.

## 5. Coder deviation/escalation notes — assessment

1. **`gh-add-blocked-by.json` not edited (deviation 1) — CORRECT.** I read the
   fixture: its content is only the mutation *response*
   (`{"data":{"addBlockedBy":{"issue":{"number":42}}}}`) — neither old token
   appears, and the mutation name `addBlockedBy` is live-verified unchanged (my
   `Mutation` introspection above). The prompt's known-site list was wrong; the
   gate (grep-zero) was the contract and it is clean. Same for
   `gh-remove-blocked-by.json` (checked: response-only, token-free).
2. **POQ-1 out-of-scope classification (`backlog/BD-111.md` +
   `IMPLEMENTATION-REPORT-BD-111.md`) — CORRECT.** Both are historical
   point-in-time records: BD-111's `Resolved:` line (backlog/BD-111.md:26)
   accurately records what shipped on 2026-05-15, and the BD-111 IMPL-REPORT's
   §verification checklist (lines 335-361) explicitly *predicted* this exact
   fix path ("If the field is named `blockedBy` (no `Issues` suffix), update
   the GraphQL query string ... plus the fixture key in
   `gh-list-blocked-by.json`") — i.e., it is accurate history of a hedged
   guess, not a live prescriptive surface. Additionally `backlog/` is
   pack-chat-only write authority (per `/backlog/_rules.md` § Write authority and
   the `commit-discipline` skill §4), so the coder could not have edited it
   without explicit scoping. Neither belongs in this change. See N-1 for the
   optional follow-up.

## 6. Findings

### N-1 (NIT, advisory — Pack Chat triage, not a defect of this change)

`backlog/BD-111.md:26` still presents `Issue.blockedByIssues` (and by reference
the old arg shape) inside its Resolved narrative with no pointer to the
correction. A future reader tracing BD-111 could re-trust the disproven shapes.
Recommended disposition: when Pack Chat next touches the backlog tree (e.g., the
BD-204 status flip at batch end), append a one-line dated note to BD-111 —
"shapes superseded by BD-204 live verification 2026-06-10
(`blockingIssueId` / `Issue.blockedBy`)" — and regenerate `_toc.md`. This is
pack-chat-only authority; it does NOT block this commit, and the historical
`IMPLEMENTATION-REPORT-BD-111.md` should stay as-written (point-in-time record
whose own checklist anticipated the correction).

No BLOCKER, MUST, or SHOULD findings. No carry-forwards.

### What was checked and found clean (explicit)

- Schema ground truth re-introspected independently (mutations, input types,
  Issue fields) — new code matches exactly (§1).
- Operand wiring in both mutations + both kinds — directionality preserved;
  pinned by 8 test assertions (§1).
- Grep-zero gate, both tokens, scripts/ + .github/ — zero hits; repo-wide sweep
  matches the coder's (§2).
- Every mock/fixture/dispatch echo of the shapes — consistent; no false-pass
  mock remains (§2).
- Diff-wide scope check — renames + comment reconciliation only; no behavior
  drift (§3).
- Full CI battery 56/56 green; affected suites 127/133/181/51 with 0 failures;
  manifest verified in-sync; pack-only footprint confirmed (§4).
- Coder IMPL-REPORT internal claims (baseline counts, deviation rationale,
  DoD table) — spot-verified against the tree; no discrepancies found.
- Trinity files untouched (N/A); no new files needing README-layout or
  validate-pack coverage (the IMPL-REPORT + this report are Pattern-B workflow
  artifacts, archive-swept at version ship); no client-shipped surface touched,
  so MIGRATION/QUICKSTART unaffected; BD-204 backlog entry correctly remains
  `Status: Open` mid-BD.

## Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| agents-never-commit | Git verbs run this session: `status --porcelain`, `rev-parse HEAD`, `diff`, `diff --stat` — read-only only. Final `git status --porcelain` shows the same 6 ` M` + 2 `??` entries (nothing staged); HEAD still `08fd605606017374d6005de88e7b3b48432a79ca`. Deliverable = this report only. | COMPLIANT |
| per-action-approval-sub-agents | No destructive op run or needed: no `rm -rf` outside `/tmp` scratch by test harnesses themselves, no `git rm`, no file overwrite except this report at the prompted path. `build.sh --verify` chosen over `--all --clean` specifically to avoid rewriting `test-fixtures/manifest.txt` (usage line 74-75: "Compare HEAD SHA of each existing fixture against manifest.txt"). | COMPLIANT |
| preflight-stop-means-stop | Emitted in-chat immediately before this Write: "PREFLIGHT: review complete; verification PASS; HEAD 08fd605606017374d6005de88e7b3b48432a79ca; about to Write report to maintenance-docs/v11-implementation/PACK-REVIEW-BD-204-GH-DEP-SHAPES.md". No parent stop message received at any point. | COMPLIANT |
| agent-output-rules-applied-block | This block; format per `pack-ops/PACK-MEMORY-RATIONALE.md` § rules-applied-verification-block (read this session, lines 206-233: "per-rule table `Rule | Verification evidence | Conclusion`"); every row carries quoted evidence; no AMBIGUOUS rows. | COMPLIANT |
| agents-read-rule-docs-in-full | Read in full with line counts: `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md` (579 lines, incl. complete `## Pack memory`); `~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_rename_plans_measure_then_bound.md` (43); `.../feedback_verify_full_ci_suite.md` (42); `.../feedback_agent_output_rules_applied_block.md` (14, plus its conditional MUST-READ: PACK-MEMORY-RATIONALE.md § rules-applied-verification-block). Also read: `/backlog/_rules.md` (95), `/changelog/_rules.md` (66), skills `review`, `architecture-review`, `commit-discipline` (each in full). | COMPLIANT |
| rename-measure-then-bound (reviewer leg) | `grep -rn "blockedByIssueId" scripts/ .github/` → no output, exit=1; `grep -rn "blockedByIssues" scripts/ .github/` → no output, exit=1. Both ZERO; allowlist empty. Repo-wide sweep → only `backlog/BD-111.md`, `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-111.md`, and the coder's IMPL-REPORT (each justified in §2/§5). | COMPLIANT |
| verify-full-ci-suite | Ran the FULL battery myself: 56 steps, `grep -c "^PASS"` = 56, `grep -c "^FAIL"` = 0 (`/tmp/bd204-review-battery.log`), incl. `validate-pack.py` normal + DEEP ("PASSED — all checks clean") and `test-v11-realistic-ot.sh` ("All v11-realistic-ot integration tests PASSED (33/33)"). Four affected mock suites re-run with counts: 127/0, 133/0, 181/0, 51/0. Live oracle default-SKIP: "SKIP: live-GH oracle (set PACK_TRACKER_LIVE_GH=1 + gh auth to run)" rc=0. | COMPLIANT |
| regenerate-manifest-v11-surface | `git diff test-fixtures/manifest.txt` → empty (manifest-diff-exit=0, no output); `bash test-fixtures/build.sh --verify` → all fixture rows OK, rc=0 (final row: "existing-project-mid-dev OK: a54e081a..."). Coder's empty-diff claim independently confirmed; no manifest change owed. | COMPLIANT |
| pack-only (BD-204 HARD constraint) | `git status --porcelain`: 6 ` M` files all under `scripts/`; `??` = coder IMPL-REPORT + this report, both under `maintenance-docs/v11-implementation/`. Nothing under `project-template/` or `supporting-docs/`. `git diff --stat` corroborates (6 files, 58+/71-). | COMPLIANT |
| scope-deliverables-to-the-ask | Report contains only: the 5 prompted verification areas, 1 real advisory finding (N-1), the verdict, and the required attestation blocks. No proposed refactors, no speculative findings ("might have a problem" class excluded per review skill item 12). | COMPLIANT |
