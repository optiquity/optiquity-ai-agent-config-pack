# PACK-REVIEW — BD-204 run-3 fixes, reviewer pass 2 (fresh, full-diff)

- **Branch:** `v11-dev`; **HEAD:** `451f20f4e4d665498aeb9101885fadb2ee503b5a` (unchanged; read-only git verbs only)
- **Reviewer:** fresh pack-reviewer, 2026-06-10 (pass 2 of the bounded cycle)
- **Scope reviewed:** the ENTIRE uncommitted diff vs HEAD — 8 modified files under
  `scripts/` (+336/−6 per `git diff --stat`) — every hunk and the resulting state,
  on its own merits. Prior review NOT read (`PACK-REVIEW-BD-204-RUN3-FIXES.md`
  exists untracked but was not opened). Coder reports read for inventory only:
  `IMPL-REPORT-BD-204-RUN3-FIXES.md`, `IMPL-REPORT-BD-204-RUN3-FIXES-FIX1.md`.
- **No live GitHub calls made.** All verification mock-based / offline.

## VERDICT: APPROVE

No BLOCKER, no MUST, no SHOULD. One pre-existing NIT recorded (outside this
diff; tech-debt candidate, not a commit blocker). The change is commit-ready.

---

## 1. Defect B — provider-truth read-before-write (`scripts/lib/tracker-provider-gh.sh:609-644`)

**Directionality — VERIFIED CORRECT, both kinds.** The read targets the BLOCKED
issue and looks for the BLOCKING number among its `blockedBy` nodes:
- `blocked-by`: `blocked_num=$id`, `blocking_num=$other_id` — matches the
  mutation mapping at lines 647-648 (`issueId=id, blockingIssueId=other_id`).
- `blocks`: operands inverted (`blocked_num=$other_id`, `blocking_num=$id`) —
  matches the mutation's inversion (`issueId=other_node, blockingIssueId=issue_node`).

Empirical probe (scratch fake gh in /tmp, state: issue 5 blocked by issue 7):

```
case A: tracker_provider_gh_link 7 5 blocks      → {"... "kind": "blocks", "already_linked": true}  rc=0, no mutation
case B: tracker_provider_gh_link 5 7 blocked-by  → {"... "already_linked": true}                    rc=0, no mutation
case C: tracker_provider_gh_link 9 7 blocked-by  → normal success JSON, exactly 1 mutation attempted
```

The `blocks`-kind skip is NOT covered by the new mock legs (the forward
orchestrator only emits `blocked-by`), but the probe above confirms the
inversion is correct in code; no test gap worth blocking on since no in-tree
caller passes `blocks` today.

**Failed-read degradation — VERIFIED.** Probed two failure modes (read arm
`exit 1`; read arm returning `{}`): both fall through to the mutation
(1 mutation attempted, rc=0) — exactly pre-fix behavior, as the comment at
lines 621-626 promises. The jq guard `.nodes[]?.number | tostring` handles
null/missing paths without erroring (verified: `{}` yields empty array →
no match → fall-through). No error-string classification anywhere on the
path (the fake-gh sentinel text in the roundtrip mock is explicitly marked
STAND-IN at `scripts/tests/tracker-migrate-roundtrip-test.sh:289-297`).

**Read shape parity — VERIFIED.** The `read_query` at
`tracker-provider-gh.sh:636` is the same `blockedBy(first: 50) { nodes { number } }`
shape as `_tmr_fetch_first_class_blocked_by`
(`scripts/lib/tracker-migrate-reverse.sh:436`); the `first: 50` ceiling claim
matches that function's header citation (`per_relationship_ceiling=50`,
lines 380-381). Skip path returns at line 642 BEFORE the node-id REST calls
(saves two reads on skip) and before the generic success printf at line 678 —
no double-print.

**No-store-bug claim — VERIFIED.** `tracker_links_create_blocked_by`
(`scripts/lib/tracker-links.sh:196-287`): nothing on the create path reads
the cycle-graph store as a dedup; `_tracker_cycle_check_store_add` (Step 5)
is write-side only and runs after provider success. The new Step-4 comment
(lines 242-251) correctly documents why the store is intentionally NOT a
create-dedup (store loss / GH-side unlink would make a store-based skip
silently wrong) and that the orchestrator re-calls `provider_link` every run.
Comment matches the code as it stands.

**Run-3 evidence fit.** Log lines 85-90 / 122-127 (`step-7 link blocked-by:
BD-907 -> BD-901` partial-write on BOTH re-runs, never on run 1) are exactly
the non-idempotent-mutation signature this fix removes.

## 2. Defect C — bare-`n/a` resolution normalization (`scripts/lib/tracker-migrate-forward.sh:477-498`)

**Single shared parse point — VERIFIED.** The normalization lives in
`flush_entry` inside `_tmf_parse_backlog_file` — the one parser shared by:
the forward compose path (`tracker_migrate_forward_run:1377`), the tree
parser (`tmf_parse_backlog_tree:631`), AND the divergence comparator
(`_tmr_check_blob_h2_divergence` re-parses the blob through it,
`tracker-migrate-reverse.sh:827`). No comparator carve-out; no carry-path
carve-out.

**Blob verbatim — VERIFIED.** The normalization touches only
`current["resolution"]`; the `raw_body_by_pid` capture (lines 443-457,
547-549) is a separate accumulation never touched by `flush_entry`'s field
logic. Probe confirmed `raw_body` retains the literal `Resolved: n/a` line
while `resolution` projects empty. Reverse-test 2.1f additionally pins
`raw_body` byte-faithful including the `Resolved: n/a` line.

**Variant probes (all run against the live working-tree parser):**

```
Resolved: n/a                  → resolution=""            (normalized)
Resolved: N/A                  → resolution=""            (case-insensitive)
Resolved:   n/a␣␣              → resolution=""            (whitespace-trimmed)
Resolution: n/a                → resolution=""            (both header spellings map to the key)
Resolved: n/a — pending        → resolution="n/a — pending"  (content-bearing untouched)
Resolved: n/a.                 → resolution="n/a."        (untouched)
Resolved: 2026-04-01 — fixed…  → resolution unchanged     (real text untouched)
Resolved: n/a + continuation   → resolution="n/a\ncontinuation text" (multi-line untouched)
```

Exactly the documented scope: only the `resolution` key, only an exact bare
match. `File/Symbol: n/a — new dir` parses unchanged (content-bearing).

**Three-actor agreement — VERIFIED.**
- Composer: `tmf_compose_issue_body:973-975` emits `## Resolution` only when
  resolution is non-empty → no phantom H2 post-fix (pinned by forward-test
  4.2 grep leg and reverse-test 2.1f `assert_not_contains`).
- Comparator: re-parses the blob through the fixed parser → expects no H2 →
  a blob-consistent empty-resolution recompose matches (reverse-test 2.1f
  rc=0; roundtrip 6.3 post-CRUD reverse rc=0).
- Edit path: `tracker_edit` (`scripts/lib/tracker-edit.sh:246-275`) takes
  caller-supplied fields and recomposes via the same composer — an
  empty-resolution recompose (the run-3 CRUD shape) now agrees.
- Fail-loud retained: reverse-test 2.1f-ii proves a REAL one-word H2 edit on
  the same n/a entry still flags (rc=1, names issue #81 + Description).

**Emitter inverse rule — VERIFIED.** `_tmr_emit_backlog:987-990` writes
`Resolution: <res>` when non-empty, else `Resolved: n/a` — so
`emit(parse(...))` now round-trips canonical `Resolved: n/a` entries
byte-stably (pre-fix it morphed them to `Resolution: n/a`).

**Downstream `resolution`-key consumers audited (beyond the three actors):**
- `tracker-promote.sh:596,604` — idempotency guard matches `*"to $target]"*`;
  neither `"n/a"` nor `""` ever matched; no behavior change. The contains-
  search at 1332/1368 targets real resolution text; unaffected.
- `tracker-edit.sh:249` — `has_content` test on the caller's patch, not
  parser output; unaffected.
- Fixture knock-on: `scripts/tests/fixtures/tracker-links/BACKLOG-phase-task-blockers.md`
  is consumed only by `test-tracker-links.sh:226` (verified by grep); its 4.1
  byte-identity leg required the canonical spelling post-fix; links suite
  43/0.

**Run-3 evidence fit.** Log lines 103-114: the phantom `(Resolution)`
divergence on issue #4 (BD-904) aborting reverse 3 and cascading the
BD-908-missing / status / count FAILs (plus line 129's `entries: 8`) — all
five reproduce-and-clear in roundtrip Group 6.3/6.4 and reverse 2.1f.

## 3. Defect A — oracle needle + non-empty-fetch guard (`scripts/tests/tracker-bd204-lossless-roundtrip-test.sh:391-409`)

- **Default-SKIP stays first — VERIFIED.** The guard at lines 60-65 is the
  first action; with `PACK_TRACKER_LIVE_GH` unset the suite printed the
  pinned SKIP line and exited 0 in my run. The Defect-A edits sit at
  lines 394-409, far below the guard; nothing above it changed.
- **Needle** `<code>` → `<code` matches the run-3 live evidence
  (log lines 39-40: `needle='<code>' missing`; GH renders
  `<code class="notranslate">`). Attribute-tolerant open-tag prefix is the
  minimal honest relaxation. No other file pins the old needle (grep for
  `"<code>"` across `scripts/tests/` → zero hits).
- **Guard** correctly precedes the four `assert_not_contains` legs and uses
  the suite's own `t_pass`/`t_fail` helpers (both defined, lines 77-82;
  `assert_not_contains` defined at line 82 — the helper-existence trap that
  bit the forward suite does not apply here).
- Only the Defect-A leg was touched in this file (diff shows exactly the
  two hunks).

## 4. Fix-pass edits (F-1 / F-2 / POQ-1)

- **F-1 — IMPL-REPORT audit sentences now TRUE (verified against
  `scripts/pack-td.sh` myself).** `grep -rn "Resolution: n/a"` over the repo:
  hits are the promote fixtures/tests (`scripts/tests/fixtures/tracker-promote/BACKLOG.md`,
  `test-tracker-promote-path1.sh`, `test-tracker-promote-path2.sh`) plus
  exactly one non-test occurrence, `scripts/pack-td.sh:259`. Read in context
  (lines 251-264): it sits inside `cat >&2 <<EOF` — the F4/BD-107 BACKLOG-patch
  advisory printed to stderr for a human; prose, never fed to
  `_tmf_parse_backlog_file`. The corrected IMPL-REPORT inventory ("test
  fixtures … PLUS one non-test occurrence — `scripts/pack-td.sh:259` …
  advisory … never parsed") is accurate. All three promote suites pass
  (direct/path1/path2: rc=0, FAIL: 0).
- **F-2 — summary wording.** `links: parent=…, blocked-by=… (ensured present)`
  (`tracker-migrate-forward.sh:1879`) with the 7-line semantics comment above
  the heredoc. Pinning sweep: grep for `links:      parent` and `blocked-by=`
  across `scripts/`, `supporting-docs/`, `project-template/` → only the emit
  line itself. No test or doc pins the old wording. "Ensured present" is an
  accurate description of the post-fix semantics (the skip path returns
  success, so counts are identical on re-runs) and the comment correctly
  explains why ensured-vs-created cannot be split (provider stdout discarded).
- **POQ-1 — heredoc backticks.** `tracker-migrate-forward-test.sh:534-536`:
  the only backtick pair inside the unquoted `<<FAKEGH` heredoc is now
  escaped (`` \` ``); comment text otherwise identical. Stderr proof from my
  own run: `grep -c 'command not found'` on captured suite stderr → **0**;
  remaining stderr is 9 functional `per-entry decompose: wrote N entry file(s)`
  lines. Suite 183/0, rc=0.

## 5. New mock coverage — teeth inspection

- **Duplicate-edge sentinel** (`tracker-migrate-roundtrip-test.sh:286-307`):
  the fake's `addBlockedBy` arm exits 1 when the edge already exists in
  `first_class_edges`. The fake's PRE-EXISTING `blockedBy(first` read arm
  (lines 325-338, BD-111 retrofit) serves edges from the same state — so the
  production read-skip is what keeps 6.2/6.4 green; a regression that
  re-attempts the mutation trips the sentinel. Genuine teeth (and the leg
  distribution proves it: Group 3 wipes state+id-map, so Group 6.2 is the
  only mock coverage of the intact-state re-link topology).
- **`issue edit` state application** (lines 184-216): body-file + label
  add/remove applied to state, making the REAL `provider_update` path
  exercisable in 6.3. Flag parsing is mock-grade but sufficient for the
  call shapes used.
- **Group 6 legs** reproduce the run-3 topologies faithfully: 6.2 = the
  repeated-cycle re-run (rc=0, `created:    0`, no step-7 failure, no
  partial-write, edge-count stable); 6.3 = interleaved CRUD (provider_create
  BD-009 + id-map register, blob-consistent status flip via REAL
  provider_update with empty resolution, post-CRUD reverse rc=0, BD-009
  byte-verbatim, BD-002 `Status: Deferred` round-trips byte-verbatim,
  count 4); 6.4 = post-CRUD re-forward (rc=0, `entries:    4` — the run-3
  line-129 analog). Call signatures verified against the lib
  (`tracker_migrate_reverse_reconstruct(issue, mapping, force=0)`;
  `tmf_compose_issue_body` 6-arg shape).
- **Reverse 2.1f/2.1f-ii** pin the symmetry at the unit layer including the
  no-carve-out proof (real edit still rc=1). `assert_not_contains` is
  defined in this suite (line 27) — the new legs' helper usage is valid.
- **Forward 1.1/4.2** pin the parser rule directly (entry[0] empty,
  entry[2] real text retained) and the composer chain (grep idiom — correct,
  since this suite genuinely lacks `assert_not_contains`; verified by grep).

## 6. Full battery, manifest, scope

**Full unattended CI battery run FOREGROUND at the edited tree — ALL GREEN:**

| Step | Result |
|---|---|
| `python3 scripts/validate-pack.py` | PASSED — all checks clean (rc=0) |
| `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | PASSED — all checks clean (rc=0) |
| test-detect | 100/0 |
| tracker-provider / config / init / agent-read | rc=0 each |
| tracker-migrate-forward-test | **183 passed / 0 failed** |
| tracker-migrate-reverse-test | **147 passed / 0 failed** |
| tracker-migrate-roundtrip-test | **70 passed / 0 failed** |
| test-tracker-phase-task / cycle-check / errors | rc=0 each |
| test-tracker-links | **43 passed / 0 failed** |
| config-schema / recommendation-state-schema | rc=0 |
| test-per-entry | 57/57 |
| per-check suites 32-34 (85/85), 36-38, 39, 40, 41, 18, 16, 19, 42, 43, 44, 45, 46, removed-doc-advisory, 49-field-faithfulness | rc=0 each |
| tracker-bd129 (14/0) / bd130 (24/0) / bd132 (29/0) / bd133 / bd134 (24/0) | rc=0 each |
| recommendation / pack-help / customization-preserve / init-project | rc=0 each |
| migrate-v10-to-v11 (+ dry-run + gates + decompose) | rc=0 each |
| migrator-core 19/0; migrator-manifest 12/0; migrator-capability-translation 12/0 | rc=0 each |
| `test-fixtures/build.sh --all --clean` | rc=0 |
| `test-fixtures/build.sh --verify` | all 6 rows OK, rc=0 |
| test-v11-realistic-ot | **33/33** |
| test-migrator-skills 19/0; persona-contracts 3/3 | rc=0 |
| template-translations / template-version / test-issue-forms | rc=0 each |
| BD-204 live oracle (env unset) | `SKIP: live-GH oracle (…)`, rc=0 — default-SKIP intact |
| Off-CI promote suites (F-1 evidence) | direct/path1/path2 rc=0, FAIL: 0 |

The workflow's `git checkout HEAD -- test-fixtures/manifest.txt` step was
substituted with the read-only equivalent (`git diff test-fixtures/manifest.txt`
→ empty, so verify compared against committed-identical content).

**Manifest claim — VERIFIED.** After `bash test-fixtures/build.sh --all
--clean` (rc=0): `git diff test-fixtures/manifest.txt` → 0 lines;
`git status --porcelain test-fixtures/` → empty; `--verify` all 6 rows OK
(v11-flat-file f9705c27, v11-tracker-on 944ddee3, existing-project-mid-dev
a54e081a, v11-realistic-ot ae3fc6ff, v10 rows tag-pinned). The empty
post-rebuild diff confirms these tracker-lib/test edits are not
fixture-affecting; no manifest staging needed.

**pack-only — VERIFIED.** End-state `git status --porcelain`: exactly the 8
expected modified files, all under `scripts/`; untracked additions are
exactly the two IMPL reports + the pass-1 review report (cycle artifact, not
read) + this report. Zero `project-template/` / `supporting-docs/` /
pack-chat-only paths. My probes wrote only `/tmp` scratch (cleaned).

## Findings

- **NIT-1 (pre-existing; OUTSIDE this diff; tech-debt candidate, not a
  commit blocker).** `scripts/pack-td.sh:258-259` — the human-facing
  BACKLOG-patch advisory shows the "before" line as `Resolution: n/a`, but
  the canonical unresolved placeholder in real entries is `Resolved: n/a`
  (per `backlog/_rules.md` and the emitter's else-branch). A human applying
  the advisory patch by search would not find `Resolution: n/a` in a
  canonical entry. Pre-existing at HEAD 451f20f, untouched by this change,
  and adjacent to (not caused by) the Defect-C canonicalization. Suggest
  Pack Chat triage as small follow-up tech debt (one-line advisory wording).

No other findings. Residual notes, both acceptable as designed: (a) a future
`tracker_edit` caller passing the literal string `"n/a"` as `resolution`
would re-create a phantom H2, but the comparator fail-louds at the next
reverse rather than corrupting — consistent with the single-parse-point
design decision documented in the code; (b) POQ-2 (pre-fix-composed issues
in archived scratch repos would flag divergence post-fix) is correctly
documented in the IMPL-REPORT and moot for unlaunched v11.0.

## Read-in-full attestation (agents-read-rule-docs-in-full)

| File | Lines read |
|---|---|
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md` (full file incl. `## Pack memory`) | 579/579 |
| `/tmp/bd204-rehearsal-run3.log` | 137/137 |
| `/Users/david/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_verify_full_ci_suite.md` | 42/42 |
| `/Users/david/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_agent_output_rules_applied_block.md` | 14/14 |

Named code sections read: `tracker_provider_gh_link` (provider-gh 555-729);
parse point (forward 380-640) + `tmf_compose_issue_body` (900-1030) + summary
emit (1830-1899); `_tmr_check_blob_h2_divergence` (reverse 800-899) +
`_tmr_emit_backlog` resolution rule (924-999) + `_tmr_fetch_first_class_blocked_by`
(380-456); `tracker_links_create_blocked_by` (links 170-287); oracle edited
legs + guard (bd204 test 1-82, 360-430); FAKEGH heredoc region (forward test
505-604); plus `pack-td.sh:235-279`, `tracker-edit.sh:230-289`,
`tracker-promote.sh:575-619`, the full `git diff`, the CI workflow, and both
IMPL reports in full.

## Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| agents-never-commit | Git verbs run this session (complete list): `git rev-parse HEAD` (×2 → `451f20f4e4d…`), `git status --porcelain` (×3), `git diff` / `--stat` / `test-fixtures/manifest.txt`. Zero add/commit/push/tag/stash/reset/restore/checkout (the workflow's `git checkout HEAD -- manifest.txt` step explicitly substituted with read-only `git diff` → 0 lines). Output = this report file only. | COMPLIANT |
| per-action-approval-sub-agents | No destructive ops on repo paths: probes used `mktemp`-created `/tmp` dirs only (`rev2-fake.*`, `rev2-fake2.*`), removed with `rm -rf` on those /tmp paths only; no `git rm`, no repo-file overwrites; the only repo write is this report. End-state `git status --porcelain` unchanged vs review start (same 8 modified + 3 untracked, + this report). | COMPLIANT |
| preflight-stop-means-stop | Emitted before this Write: `PREFLIGHT: review complete; verification PASS; HEAD 451f20f4e4d665498aeb9101885fadb2ee503b5a; about to Write report to maintenance-docs/v11-implementation/PACK-REVIEW-BD-204-RUN3-FIXES-REVIEW2.md`. No parent stop message received at any point. | COMPLIANT |
| agent-output-rules-applied-block | This table; every row carries quoted measurements (commands, counts, rc values); no row empty; no AMBIGUOUS verdicts. | COMPLIANT |
| agents-read-rule-docs-in-full | All 4 named files read IN FULL via Read tool with wc-verified line counts (579, 137, 42, 14 — attestation table above); all named code sections read (list above). The prior review report was NOT read per the fresh-review constraint. | COMPLIANT |
| verify-full-ci-suite | `python3 scripts/validate-pack.py` → "PASSED — all checks clean" rc=0; `PACK_VALIDATE_DEEP=1` variant → same; EVERY `.github/workflows/validate-pack.yml` tests-job step run FOREGROUND to completion in this session (full table in §6: forward 183/0, reverse 147/0, roundtrip 70/0, links 43/0, detect 100/0, per-entry 57/57, 32-34 85/85, realistic-ot 33/33, fixtures build rc=0 + verify all-6-OK, persona 3/3, migrator-skills 19/0, every remaining step rc=0). Live oracle stayed default-SKIP: pinned `SKIP: live-GH oracle (…)` line, rc=0. No background monitors armed. | COMPLIANT |
| regenerate-manifest-v11-surface | Empty-manifest-diff claim independently verified: ran `bash test-fixtures/build.sh --all --clean` (rc=0, "manifest written"), then `git diff test-fixtures/manifest.txt` → `manifest-diff-lines=0` and `git status --porcelain test-fixtures/` → empty; `--verify` → all 6 rows OK. Claim correct; no staging needed. | COMPLIANT |
| pack-only (BD-204 HARD) | `git status --porcelain`: modified = exactly the 8 expected `scripts/` files (3 libs, 1 fixture, 4 test suites); untracked = `IMPL-REPORT-BD-204-RUN3-FIXES.md`, `IMPL-REPORT-BD-204-RUN3-FIXES-FIX1.md`, `PACK-REVIEW-BD-204-RUN3-FIXES.md` (pass-1 cycle artifact, unread) + this report. Zero `project-template/` / `supporting-docs/` paths. | COMPLIANT |
| scope-deliverables-to-the-ask | Findings limited to one real (pre-existing, clearly-flagged) NIT; everything else reported as verified-clean with evidence; no speculative redesign requests; residual design notes explicitly marked no-action. Review confined to the diff + its encoding surfaces + the prompt's six verification goals. | COMPLIANT |

— end of review —
