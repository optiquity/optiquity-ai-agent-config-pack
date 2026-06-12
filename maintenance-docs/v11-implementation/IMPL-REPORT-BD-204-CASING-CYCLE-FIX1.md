# IMPL-REPORT — BD-204 casing+cycle batch, fix-coder pass 1 (SHOULD-1 + SHOULD-2)

- **Branch:** `v11-dev`; **HEAD (unchanged, no commits):** `1c18b28c4d149d3e80565beafccc84f8d25b32f2`
- **Date:** 2026-06-11
- **Agent:** fresh fix-coder (pass 1 of the bounded review/fix cycle)
- **Scope:** exactly reviewer findings SHOULD-1 + SHOULD-2 from
  `maintenance-docs/v11-implementation/PACK-REVIEW-BD-204-CASING-CYCLE.md`.
  MUST-1 / NIT-1 (Pack-Chat bookkeeping) untouched; nothing under
  `backlog/` or `changelog/` touched.

## 1. Pre-flight

Session start (verbatim):

```
$ git rev-parse HEAD
1c18b28c4d149d3e80565beafccc84f8d25b32f2
$ git branch --show-current
v11-dev
$ git status --porcelain   # 10 M scripts files (the uncommitted BD-204 batch)
 M scripts/lib/tracker-cycle-check.sh
 M scripts/lib/tracker-migrate-forward.sh
 M scripts/lib/tracker-migrate-reverse.sh
 M scripts/lib/tracker-provider-gh.sh
 M scripts/tests/test-tracker-cycle-check.sh
 M scripts/tests/test-tracker-links.sh
 M scripts/tests/tracker-migrate-forward-test.sh
 M scripts/tests/tracker-migrate-reverse-test.sh
 M scripts/tests/tracker-migrate-roundtrip-test.sh
 M scripts/tests/tracker-provider-test.sh
?? maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-CASING-CYCLE.md
?? maintenance-docs/v11-implementation/PACK-REVIEW-BD-204-CASING-CYCLE.md
?? tracker.toml
```

Base verified: the worktree carries the uncommitted BD-204 casing+cycle
batch the review was issued against. The fix-base for my edits is
"HEAD + the uncommitted batch", not bare HEAD — diffs in §4 are scoped
to MY edits only, to avoid misattributing the prior coder's hunks.

**Concurrent-activity note:** mid-session a new untracked file appeared:
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT.md`.
I did not create it and did not touch it (Pack-Chat/parallel-session
artifact). Flagging so the end-state inventory is explainable.

## 2. SHOULD-1 — roundtrip closed-status e2e leg (close handler dormant in CI)

**Finding:** the realigned roundtrip fake-gh `issue close` handler was
never invoked by any CI-run leg (fixtures carried only
Open/Unblocked/Deferred). The close→read-back→decode chain (uppercase
`NOT_PLANNED` through the production normalize→decode path) was pinned
only at unit level + the default-SKIP live oracle.

**Fix shape:** add ONE Cancelled entry (`BD-004`) to the roundtrip
fixture so every forward run executes the production step-8 close path
against the mock, plus pin the chain at both ends:

1. **Fixture** (`scripts/tests/fixtures/roundtrip/bd-v11.0/BACKLOG.md`):
   appended `BD-004 — Cancelled close round-trip (BD-204 C-8 read-back
   casing)` with `Status: Cancelled`, `Blockers: None` (cycle-pre-pass
   inert), `Resolved: n/a`. Chain it exercises, verified against source:
   forward step-8 maps `Cancelled → reason not_planned`
   (`scripts/lib/tracker-migrate-forward.sh`, close loop
   `Resolved|Cancelled|Deprecated` arm) → `tracker_provider_gh_close`
   maps `not_planned → gh issue close --reason "not planned"`
   (`scripts/lib/tracker-provider-gh.sh`) → mock validates the real CLI
   vocabulary and stores the live read-back shape
   (`state: CLOSED`, `stateReason: NOT_PLANNED`) → reverse
   `tracker_provider_gh_get` → `_gh_normalize_issue` lowercases →
   `_tmr_decode_status` → `Cancelled`.

2. **New leg 1.2** (after Group 1 forward): asserts `closed:     1` and
   `close-stabilization OK` in forward output, and that the state file
   stores BD-004 as `CLOSED` / `NOT_PLANNED` (uppercase read-back enum —
   proves the chain genuinely passes through the uppercase shape).

3. **New leg 2.2e** (after Group 2 reverse): fetches BD-004 via
   `tracker_provider_gh_get` (production normalize boundary) + decodes
   via `tracker_migrate_reverse_reconstruct` (the same public per-issue
   decoder idiom the suite's existing 2.2c leg uses); asserts
   `state=closed`, `state_reason=not_planned` (normalized), decoded
   `status=Cancelled`, and that the reverse orchestrator run
   reconstructed `backlog/BD-004.md` with `Status: Cancelled`.

4. **Two enablers required for green** (documented under §6 deviations
   as in-scope implementation necessities, not plan changes):
   - The mock's `issue list` arm previously returned a canned `[]`.
     With a closed entry present, forward's BD-132 close-stabilization
     poll (`provider_list state=closed`, floor `>= closes_attempted`)
     would poll a canned `[]` to the 30-attempt ceiling and fail the run
     as a partial-write. The arm now serves from state with `--label` /
     `--state` filters (mirroring `tracker-migrate-forward-test.sh`'s
     fake-gh, which tracks closed IDs for exactly this poll). Consumer
     check: the only other `provider_list` callers are the reverse
     roster discovery (which unions with the id-map — same id set,
     `unique`-deduped, behavior unchanged) and the stabilization poll
     itself; verified via `grep -rn "provider_list" scripts/lib/*.sh`.
   - `TMF_STABILIZE_SLEEP_SECS=0` set before the `source` block
     (documented test seam in `tracker-migrate-forward.sh`: "Test seam:
     TMF_STABILIZE_MAX_ATTEMPTS / TMF_STABILIZE_SLEEP_SECS can be
     overridden to 0 / fractional values to keep test runtimes
     bounded") — otherwise each forward run sleeps 2s in the poll.

5. **Count-sensitive assertions updated, values measured from runs**
   (not guessed): Group 1 `parsed 3→4 BACKLOG entries`, state issues
   `5→6`, mapping `5→6`; Group 2 `reconstructed 3→4`; Group 3 second
   forward state `5→6`; Group 6 count oracle `4→5`, re-forward
   `entries:    4→5` (spacing mirrors the forward summary heredoc in
   `tracker-migrate-forward.sh`). One stale comment aligned
   ("4-entry tree" → "5-entry tree" in the Group 6 (d) comment).

**Teeth proof (this session, foreground):** un-normalized uppercase
through the working-tree decoder yields the lossy class, so leg 2.2e
fails on a normalizer regression:

```
$ bash /tmp/bd204-fix1-teeth.sh
uppercase (regression sim): Resolved
lowercase (normalized):     Cancelled
```

And the close-handler vocabulary now has CI teeth: a regression that
sends the interface token `not_planned` to gh would make the mock exit 1
→ close-retry exhausts → partial-write → the leg-1.1 `rc=0` assert fails.

## 3. SHOULD-2 — check-40 T3 tracker-mode tolerance

**Finding:** `scripts/tests/test-validate-pack-check-40.sh` T3 asserted
`"tracker.toml" not in index` against the LIVE tree, premised on
"tracker.toml lives in fixture trees but not in the pack at HEAD" —
false on any Mode-3 (tracker-enabled) working tree, where a root
`tracker.toml` is a legitimate runtime artifact. Permanent local-only
red on this repo going forward (CI-invisible; degrades the
verify-full-ci-suite signal).

**Fix shape (per the review's recommendation — isolated fixture tree,
not the live index):** T3 now builds a synthetic tree in a tmpdir with
`tracker.toml` copies at THREE locations — under `test-fixtures/`,
under `scripts/tests/fixtures/` (both EXCLUDE roots), and at the tree
root (the Mode-3 runtime analog) — swaps `mod.REPO_ROOT` to it (the
same pattern the suite's Group 5 `run_check_with_synthetic` already
uses), builds the index via the REAL `_build_basename_index`, restores
`REPO_ROOT` in a `finally`, and asserts the candidate list is EXACTLY
`["tracker.toml"]` (the root copy).

**Not weakened — strengthened.** The old leg pinned only "fixture
copies excluded" and only when the live tree happened to have no root
tracker.toml. The new leg pins BOTH directions deterministically:
fixture-tree copies excluded (EXCLUDE effective) AND the non-fixture
root copy indexed (EXCLUDE not over-broad — a property the old leg
never tested). T1/T2 (live-index presence checks) and T4
(`_CHECK_40_EXCLUDE_PARTS` membership) are untouched.

**Teeth proof (this session, foreground, scratch `/tmp` script driving
the same logic):**

```
real EXCLUDE        : PASS ['tracker.toml']
neutered EXCLUDE sim: FAIL (expected) ['scripts/tests/fixtures/rt/tracker.toml', 'test-fixtures/ft/tracker.toml', 'tracker.toml']
over-broad sim      : FAIL (expected) []
```

## 4. Edits (this pass only — full before/after)

### 4.1 `scripts/tests/fixtures/roundtrip/bd-v11.0/BACKLOG.md` (modified, +14/-0)

Appended after the BD-003 block's closing `---`:

```markdown
**BD-004 — Cancelled close round-trip (BD-204 C-8 read-back casing)**
Type: TODO(version)
Status: Cancelled
Blockers: None
Unblocks: None
File/Symbol: scripts/cancelled-surface.sh
Description: Exercises the closed-status forward path end to end —
  step-8 close (interface token not_planned → gh CLI "not planned"),
  the fake gh's live read-back storage (CLOSED/NOT_PLANNED), and the
  production normalize→decode chain back to Cancelled on reverse.
Resolved: n/a

---
```

(Fixture consumer check: `grep -rn "fixtures/roundtrip" scripts/` —
consumed ONLY by `tracker-migrate-roundtrip-test.sh`; no sibling-suite
blast radius.)

### 4.2 `scripts/tests/tracker-migrate-roundtrip-test.sh` (modified, my delta ≈ +109/-13 within the batch-modified file)

Seven targeted edits (no full-file rewrite):

1. Inserted `TMF_STABILIZE_SLEEP_SECS=0` + 6-line rationale comment
   immediately before the `# Source the libs...` block.
2. Replaced the fake-gh `issue list` arm body (`echo "[]"` → state-served
   array with `--label`/`--state` filter parsing + 9-line rationale
   comment; bash-3.2-safe `while/case/shift` arg walk; jq filter:
   `[.issues[] | select(($state == "all") or ((.state // "") ==
   ($state | ascii_upcase))) | select(($label == "") or
   (any((.labels // [])[]; .name == $label)))]`).
3. Group 1 comment block: BD-* set now {BD-001..BD-004}, counts 4/6,
   added the BD-004 closed-status-carrier paragraph; assertions updated:
   `parsed 4 BACKLOG entries`, `6 issues`, `mapping has 6 entries`.
4. New 1.2 block (8 comment lines + 5 assertions): `closed:     1`,
   `close-stabilization OK`, stored `state == CLOSED`, stored
   `stateReason == NOT_PLANNED` (selected from state by
   `.title | startswith("BD-004:")` — title shape verified against the
   forward compose `title="$pack_id: ..."`).
5. Group 2: `reconstructed 4 BACKLOG entries`; new 2.2e block (8 comment
   lines + id-map presence + provider-get/reconstruct + 3 `assert_eq`
   on `state` / `state_reason` / decoded `status` + tree-file
   `^Status: Cancelled$` grep).
6. Group 3: `second forward state has 6 issues`.
7. Group 6: count oracle `"5"`; `entries:    5`; comment
   "4-entry tree" → "5-entry tree".

### 4.3 `scripts/tests/test-validate-pack-check-40.sh` (modified, +34/-14)

Single targeted replacement of the T3 block inside the Group 4 python
heredoc: the old live-index `if "tracker.toml" in index:` assertion
(with its 9-line premise comment) became the synthetic-tree leg
described in §3 (12-line comment + `import tempfile, shutil, pathlib`,
tmpdir build, `mod.REPO_ROOT` swap inside `try/finally` with
`shutil.rmtree` cleanup, exact-candidate-list assertion with a
diagnostic message naming both failure directions).

## 5. Verification (all foreground, this session, after ALL edits)

| Check | Result |
|---|---|
| `bash -n` both edited shell suites | SYNTAX-OK |
| `bash scripts/tests/tracker-migrate-roundtrip-test.sh` | **Passed: 79 / Failed: 0** (was 70 pre-fix; +9 = legs 1.2 ×4, 2.2e ×5; ran 3× post-edit, stable) |
| `bash scripts/tests/test-validate-pack-check-40.sh` **on the REAL tree with root `tracker.toml` present** (`ls tracker.toml` → exists) | **PASS: 8 / FAIL: 0** — the SHOULD-2 green criterion, verified explicitly |
| `python3 scripts/validate-pack.py` | `PASSED — all checks clean`, rc=0 |
| `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | `PASSED — all checks clean` |
| Full CI battery — 52 suites extracted verbatim from `.github/workflows/validate-pack.yml` (`grep -E "run: bash scripts"` → 52), run sequentially FOREGROUND | **52 green / 0 red** (results file `/tmp/bd204-fix1-battery-results.txt`; per-suite logs `/tmp/bd204-fix1-suite-N.log`). The reviewer's pass-1 battery was 51/52 with check-40 the sole FAIL — that FAIL is now cleared. |
| Batch-affected suites (counts from the battery logs) | cycle-check 28/0, links 44/0, provider 162/0, reverse 150/0, forward 199/0, roundtrip 79/0 — all unchanged from review pass except roundtrip 70→79 |
| `bash test-fixtures/build.sh --all --clean` | rc=0; `git diff test-fixtures/manifest.txt` → **0 lines (byte-stable)** — confirms `scripts/tests/**` paths are not client-shipped |
| SHOULD-1 teeth | uppercase-unnormalized decode → `Resolved` (sim), normalized → `Cancelled`; leg 2.2e pins the post-fix value (§2) |
| SHOULD-2 teeth | neutered-EXCLUDE sim → FAIL (3 candidates leak); over-broad sim → FAIL (0 candidates); real → PASS (§3) |
| Live GitHub calls | **zero** (all gh traffic via the suites' fake-gh mocks; live-oracle suite not in the CI 52, default-SKIP untouched) |

Battery procedural note: two false-start battery loops exited rc=127 on
every suite (zsh does not word-split `$cmd`; first attempt also had a
reset cwd). No suite actually executed in those loops; the third loop
(`cd <abs-repo-root>` + `eval "$cmd"`) is the valid 52/52 run reported
above.

## 6. Plan deviations

Zero deviations from the two triaged findings. Two implementation
necessities beyond the findings' literal wording, both inside the two
in-scope files and both REQUIRED for SHOULD-1 to run green (flagged for
Pack Chat transparency, rationale in §2 item 4):

1. Fake-gh `issue list` arm now serves from state (was canned `[]`) —
   without it the close-stabilization poll fails every forward run.
2. `TMF_STABILIZE_SLEEP_SECS=0` test seam set pre-source — keeps the
   now-active stabilization poll at zero wall-clock cost.

Plus one comment-only accuracy alignment ("4-entry tree" → "5-entry
tree", Group 6 (d)).

## 7. New POQs

None. (The mid-session appearance of the untracked
`ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT.md` is a concurrent Pack-Chat
artifact, not a POQ — reported in §1 for inventory completeness.)

## 8. Boundary discipline check

No project-side edits. All three edited paths live under `scripts/`
(pack-repo test infrastructure): `scripts/tests/fixtures/roundtrip/
bd-v11.0/BACKLOG.md`, `scripts/tests/tracker-migrate-roundtrip-test.sh`,
`scripts/tests/test-validate-pack-check-40.sh`. Zero paths under
`project-template/` or `supporting-docs/`; no pack-only references
added to any client-shipped surface (manifest byte-stability in §5
independently confirms zero client-install drift). No boundary stop
triggered.

## 9. Definition-of-Done checklist

| Item | Status | Evidence |
|---|---|---|
| SHOULD-1: closed-status (Cancelled — lossy class) entry in the roundtrip fixture; close handler exercised by a CI-run leg | PASS | fixture BD-004; legs 1.2 (`NOT_PLANNED` stored) + 2.2e (decode `Cancelled`); roundtrip 79/0 |
| SHOULD-1: uppercase `NOT_PLANNED` pinned through the production normalize→decode path e2e | PASS | 2.2e asserts normalized `state_reason=not_planned` + decoded `Cancelled`; teeth sim shows pre-fix value `Resolved` |
| SHOULD-1: count-sensitive assertions updated, measured not guessed | PASS | §2 item 5; values confirmed by 3 green post-edit runs |
| SHOULD-2: check-40 T3 tracker-mode-tolerant via isolated fixture tree (review's recommended shape) | PASS | §3; synthetic-tree T3 with `mod.REPO_ROOT` swap |
| SHOULD-2: T3's pinned property not weakened | PASS | exact-candidate assertion pins EXCLUDE-effective AND EXCLUDE-not-over-broad; teeth sims both FAIL as expected |
| check-40 green on the REAL tree (root `tracker.toml` present) | PASS | `ls tracker.toml` + suite 8/0 (§5) |
| Modified suites + full battery green, foreground | PASS | 52/52 (§5) |
| No live GitHub calls | PASS | mocks only; live-oracle default-SKIP |
| Nothing under `backlog/`/`changelog/`; MUST-1/NIT-1 untouched | PASS | `git status` inventory (§10) |
| Manifest checked after `scripts/` edits | PASS | rebuild rc=0, diff 0 lines (§5) |
| No state-changing git verbs; HEAD unchanged | PASS | end-state `git rev-parse HEAD` = `1c18b28c...` (§10) |

## 10. Files changed inventory (this pass)

| Path | Change |
|---|---|
| `scripts/tests/fixtures/roundtrip/bd-v11.0/BACKLOG.md` | modified (+14/-0; newly listed as M — was untouched by the batch) |
| `scripts/tests/tracker-migrate-roundtrip-test.sh` | modified (my delta within the already-batch-modified file) |
| `scripts/tests/test-validate-pack-check-40.sh` | modified (+34/-14; newly listed as M — was untouched by the batch) |
| `maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-CASING-CYCLE-FIX1.md` | new (this report) |

End-state `git status --porcelain`: the 10 batch files + my 2 newly-M
files (fixture, check-40 suite) + untracked {prior IMPL-REPORT,
PACK-REVIEW, concurrent ARCHITECTURE doc, runtime `tracker.toml`, this
report}. `.pack-tracker/` (gitignored) and root `tracker.toml`
untouched by me. Scratch confined to `/tmp/bd204-fix1-*`.

Proposed commit-message fragment (Pack Chat decides; this folds into
the batch commit or lands as):
`fix: v11 — BD-204 C-8 review SHOULD-1/2 (roundtrip closed-status e2e leg; check-40 T3 tracker-mode tolerance)`

## 11. READ-IN-FULL attestation

| File | Lines | Read |
|---|---|---|
| `CLAUDE.md` incl. the full `## Pack memory` section | 579 | FULL (provided verbatim in session context; line count verified on disk) |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-204-CASING-CYCLE.md` | 239 | FULL |
| `~/.claude/.../memory/feedback_verify_full_ci_suite.md` | 42 | FULL |
| `~/.claude/.../memory/feedback_edit_in_place_not_full_rewrite.md` | 14 | FULL |
| `~/.claude/.../memory/feedback_agent_output_rules_applied_block.md` | 14 | FULL |
| `pack-ops/PACK-MEMORY-RATIONALE.md` § rules-applied-verification-block (conditional MUST-READ) | §206–233 | FULL section |
| `pack-ops/PACK-AGENTS.md` | 223 | FULL |
| `.claude/skills/implementation-report/SKILL.md` | 138 | FULL |

Section reads for the edits: roundtrip suite in full (960 lines
pre-edit); check-40 suite in full (772 lines pre-edit); roundtrip
fixture in full; `_tmr_decode_status` + reconstruct + emit-status +
roster discovery in `tracker-migrate-reverse.sh`; forward close loop /
stabilization params / `_tmf_wait_for_close_stabilization` / run
signature / summary heredoc in `tracker-migrate-forward.sh`;
`tracker_provider_gh_list` / `_gh_close` mapping in
`tracker-provider-gh.sh`; `_CHECK_40_EXCLUDE_PARTS` +
`_build_basename_index` in `validate-pack.py`; forward-test fake-gh
closed-IDs pattern.

## 12. Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| agents-never-commit | Git verbs this session: `rev-parse`, `status`, `branch --show-current`, `diff`, `diff --stat`, `diff --name-only` — all read-only. End-state `git rev-parse HEAD` → `1c18b28c4d149d3e80565beafccc84f8d25b32f2` (unchanged). No add/commit/push/tag/stash/reset/restore/checkout invoked. | COMPLIANT |
| per-action-approval-sub-agents | No destructive ops: zero `rm -rf`/`git rm` on repo paths; scratch confined to `/tmp/bd204-fix1-*`; Pack-Chat-owned `tracker.toml` + `.pack-tracker/` untouched (read `ls tracker.toml` only); the concurrent ARCHITECTURE doc surfaced in §1/§7, not handled. | COMPLIANT |
| preflight-stop-means-stop | Emitted in-chat immediately before this report's Write: `PREFLIGHT: 2/2 fixes complete; verification PASS; HEAD 1c18b28c4d149d3e80565beafccc84f8d25b32f2; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-CASING-CYCLE-FIX1.md`. No parent stop message received at any point. | COMPLIANT |
| agent-output-rules-applied-block | This table; every row carries commands/outputs/counts/paths; `pack-ops/PACK-MEMORY-RATIONALE.md` § rules-applied-verification-block (lines 206–233) read before constructing; fenced-template format (Rule / Verification evidence / Conclusion), no empty rows. | COMPLIANT |
| agents-read-rule-docs-in-full | §11 attestation: all 5 prompt-named files read in full with disk-verified line counts (579 / 239 / 42 / 14 / 14) + the conditional rationale section + PACK-AGENTS.md (223) + implementation-report skill (138). | COMPLIANT |
| verify-full-ci-suite | Modified suites: roundtrip 79/0 (3 post-edit runs), check-40 8/0 on the REAL tracker-enabled tree. Battery: 52 suites extracted verbatim from `validate-pack.yml`, run sequentially FOREGROUND → 52× rc=0 (`grep -c "rc=0 " /tmp/bd204-fix1-battery-results.txt` → 52; non-zero list → "(none)"). `validate-pack.py` + `PACK_VALIDATE_DEEP=1` both `PASSED — all checks clean`. Live-oracle suite default-SKIP (not in the CI 52; prompt forbids live calls). The review-time sole FAIL (check-40, POQ-B) is cleared — the SHOULD-2 green criterion verified explicitly with root `tracker.toml` present. | COMPLIANT |
| regenerate-manifest-v11-surface | Edits touch `scripts/` → ran `bash test-fixtures/build.sh --all --clean` (rc=0, log `/tmp/bd204-fix1-manifest.log`); `git diff test-fixtures/manifest.txt` → 0 lines (byte-stable). Empty diff → nothing to stage (staging is also forbidden to me per agents-never-commit). | COMPLIANT |
| edit-in-place-not-full-rewrite | 9 targeted Edit calls + zero full-file Writes on existing files; post-edit `git diff` of all three files re-read in full this session (§4 derived from it) — every hunk is mine or the prior batch's pre-existing uncommitted hunks; untouched regions byte-stable by diff construction. | COMPLIANT |
| pack-only | `git diff --name-only` end-state: 12 files, all under `scripts/lib/` + `scripts/tests/` (10 batch + my 2); untracked additions beyond pre-existing: this report only (+ the concurrent ARCHITECTURE doc, not mine). Zero paths under `project-template/` / `supporting-docs/`; manifest byte-stable. | COMPLIANT |
| scope-deliverables-to-the-ask | Exactly SHOULD-1 + SHOULD-2 implemented; MUST-1/NIT-1 untouched; nothing under `backlog/`/`changelog/` (`git status` shows no paths there); the two SHOULD-1 enablers + one comment alignment flagged in §6 rather than silently expanded. | COMPLIANT |

