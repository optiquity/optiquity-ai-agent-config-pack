# PACK-REVIEW — BD-204 surface-aware [mirror] writer — reviewer pass 2

- **Reviewer:** fresh pack-reviewer (pass 2 of the bounded review/fix cycle)
- **Branch:** v11-dev; **HEAD:** `aa508973b119b90dce1186cd32bd1e40dd50d3da` (unchanged end-to-end)
- **Date:** 2026-06-11
- **Scope:** the ENTIRE uncommitted BD-204 mirror-keys change (base pass +
  fix pass 1 folded into one working-tree diff), excluding the
  Pack-Chat-owned runtime artifacts (untracked root `tracker.toml`,
  gitignored `.pack-tracker/`) which were not touched.
- **Diff reviewed:** 7 modified files (`scripts/lib/tracker-init.sh`,
  `scripts/validate-pack.py`, `scripts/tests/tracker-init-test.sh`,
  `scripts/tests/tracker-config-schema-test.sh`, `tracker.toml.pack-example`,
  `maintenance-docs/v11-research/ARCHITECTURE.md`,
  `maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-CLOSE-REASON-FIX.md`)
  + 2 untracked coder reports. No prior `PACK-REVIEW-*.md` was read
  (the pass-1 review file was listed by `git status` only; never opened).

## VERDICT: APPROVE-WITH-FIXES

One NIT (a one-clause documentation-honesty gap in an internal report's
provenance note). Everything functional — writer, validator, example,
tests, addendum, manifest, scope — is clean and independently reproduced.
The NIT does not affect any shipped or executable surface; Pack Chat may
fold the one-clause amendment in at triage or commit as-is with the NIT
tracked, per the user's triage authority.

---

## 1. Findings

### NIT-1 — §5 provenance note omits the SHOULD-1 `validate-pack.py` delta

**Anchor:** `maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-MIRROR-KEYS.md`
lines 131-139 (the "Fix pass 1 note" blockquote).

The note discloses that fix pass 1 amended `tracker.toml.pack-example`
(NIT-1) and `scripts/tests/tracker-init-test.sh` (NIT-2) "beyond the
snapshots below" — but FIX1's SHOULD-1 also amended
`scripts/validate-pack.py` (module-header Check 29 inventory), and that
file's §5.1 fenced snapshot is now equally stale and is NOT named.
Reproduced: §5.1 snapshot index line `cde216a..71230dc` vs live diff
`cde216a..6a4b2f5`; the live diff carries an extra module-header hunk
(`@@ -92`) absent from the snapshot, and the later hunks shift by +2
(`@@ -2598` → `@@ -2600`). FIX1 §1 NIT-3's "verified current … BEFORE my
NIT-1 edit" was true at that instant, but the same pass's SHOULD-1 edit
then invalidated the validate-pack.py portion and the enumeration was
never extended. Since the explicit purpose of the note (per FIX1 §1
NIT-3: "keeping the whole of §5 honest after this pass") is complete
disclosure, the omission is a real, if small, defect against the
"honest provenance" success criterion. **Fix:** add
"`scripts/validate-pack.py` (SHOULD-1)" to the note's enumeration —
one clause. The FIX1 report itself (§1 SHOULD-1 before/after + §7
inventory) already documents the delta fully, which is why this is a
NIT and not a MUST.

No BLOCKER, MUST, or SHOULD findings.

### Out-of-scope observation (pre-existing; NOT a finding of this change)

`scripts/lib/tracker-init.sh` usage text (lines 263-265, "Auto-detected
from PACK-CHAT.md or docs/pack/ presence") and the comment at line 98
("Pack root has PACK-CHAT.md") still describe the pre-BD-175 pack-surface
marker; the code at lines 101-102 uses the `pack-ops/` marker. Both
strings are present at HEAD `aa50897` unchanged by this diff — recorded
here only as a future hygiene candidate.

---

## 2. What was checked (all clean unless noted)

### 2.1 Writer surface-threading + both emitted shapes (reproduced)

- Read `scripts/lib/tracker-init.sh` IN FULL (447 lines). Single call
  site (`tracker_init_run` line 193) passes `"$surface"` as the 5th arg;
  `surface` is guaranteed non-empty ("pack"|"client") before line 193 by
  the flag/auto-detect/prompt flow (lines 100-118). No other caller of
  `_tracker_init_write_config` exists anywhere in `scripts/` (grep).
- Reproduced both shapes in an isolated /tmp probe by sourcing the lib
  and calling `_tracker_init_write_config` directly:
  - pack → 0 `[mirror]` occurrences, 0 mirror keys, parses as TOML,
    `[mode]` flows via one blank line to `[id_namespace]` (heredoc
    splice mechanics verified byte-level).
  - client vs the HEAD writer (extracted via read-only
    `git show HEAD:scripts/lib/tracker-init.sh`), same inputs,
    timestamps normalized → `diff` empty → **CLIENT BYTE-PARITY OK**
    (the bare-name keys are preserved byte-identically until BD-206).

### 2.2 Validator accept/reject matrix (probed independently)

Probed via my own fixture harness importing `check_tracker_config`
(same import mechanism as the suite but independently constructed):

| Probe | Expected | Observed |
|---|---|---|
| pack-absent `[mirror]`, client-present | PASS | rc=0 PASS |
| client-absent `[mirror]` | FAIL naming `mirror` | rc=1, `project-example — missing required key: mirror` |
| pack-present malformed (missing 2 location keys) | FAIL | rc=1, names `mirror.location_status` + `mirror.location_changelog` |
| client-present wrong type (`enabled = "yes"`) | FAIL | rc=1, `key mirror.enabled: expected bool, got str` |
| pack `mirror = true` (non-table) | FAIL | rc=1, `key mirror: expected dict, got bool` |
| BOTH live example files as shipped | PASS | rc=0 PASS |

The `if mirror_required or "mirror" in data` branch
(`scripts/validate-pack.py:2700`) is correct for all six cells,
including the non-table edge (the `"mirror" in data` arm routes a
present-but-wrong-type value into `_require("mirror", dict)`).
The module-header Check 29 inventory (lines 89-100) now truthfully
states the per-surface requirement — verified against the code it
describes. The `_check_mirror_staleness` no-mirror guard (lines
2806-2816) and schema-suite Tests 15/16 pre-exist at HEAD (confirmed
via `git show HEAD:`); this change correctly only documents them
(test-file header lines 28-29) rather than re-adding them.

### 2.3 ARCHITECTURE.md §3.1 as-built addendum

- Every claim verified against the named symbols:
  `_tracker_init_write_config` (tracker-init.sh:334, surface-aware
  emission — verified §2.1) and `_validate_tracker_toml`
  (validate-pack.py:2603, per-surface `mirror_required` — verified
  §2.2). File+symbol only; no line numbers in the addendum (pack-memory
  reconciliation pattern honored).
- "Pack deleted its monolith mirrors at BD-203": verified empirically —
  `BACKLOG.md`/`STATUS.md`/`CHANGELOG.md` absent at pack root AND under
  `pack-ops/`; `backlog/_toc.md` + `changelog/_toc.md` present.
- "Client keeps the bare-name keys until BD-206": consistent with
  `backlog/BD-206.md` (client-side no-mirror application, POST-BD-204
  REFRESH anchor read).
- Dated record byte-stable: `git diff --numstat` = **16 insertions,
  0 deletions** — pure insertion after the schema fence; the schema
  block and surrounding prose untouched.

### 2.4 Pack example consistency

`tracker.toml.pack-example` read IN FULL (74 lines). No `[mirror]`
table; replacement comment names BD-203/BD-204/BD-206 and the Check-29
no-mirror semantics accurately; header comment (lines 3-5) and `[mode]`
comment (lines 27-29, the FIX1 NIT-1 reword) both state the per-entry
trees as the flat representation. Zero stale monolith prose anywhere in
the file. Consistent with the fixed writer's pack output on the
`[mirror]` dimension (example is flat-file mode by design; writer emits
tracker mode — orthogonal and correct). The live example passes Check 29
(matrix row 6). Repo-wide sweep for `location_backlog`/`[mirror]`
outside tests/maintenance-docs/per-entry files found only legitimate
hits (validator key list, staleness reader, client-branch heredoc) and
ZERO hits in `project-template/` (beyond the intentionally-unchanged
project example), `supporting-docs/`, or `pack-ops/`.

### 2.5 Test-leg soundness + real-tree 104/0

- Both suites read IN FULL (530 + 567 lines). Legs 1.1-1.3: scratch
  `TR_FLAGVAL` mktemp root with `pack-ops/` marker is correct — fresh
  dir defeats the prior-state rail, the marker resolves surface before
  the backend/repo validation under test, asserted needles unchanged,
  cleanup present. Leg 1.9 (no `--repo-root`) remains cwd-safe because
  unknown-flag errors fire in the parse loop before the rail. No
  coverage weakened: old Test 7's pack-missing-mirror FAIL premise is
  intentionally inverted by the approved design; the matrix is now
  pinned by Test 1 (pack-absent PASS), Test 7 (client-absent FAIL,
  message anchored to `project-example`), Test 17 (pack
  present-but-malformed FAIL), plus init legs 3.3b/3.3c (pack omission)
  and 3.5 ×7 (client keys + `docs/pack/` path + TD prefix). Test 17's
  append-after-`[migration]` construction is TOML-valid; Test 7's awk
  strip is correct (skip resets on the next `[` line, which prints).
- Real-tree runs (FOREGROUND, this session, with the Pack-Chat-owned
  `.pack-tracker/` + root `tracker.toml` present):
  `tracker-init-test.sh` → **Passed: 104 / Failed: 0** (claim
  reproduced); `tracker-config-schema-test.sh` → **PASS: 34 / FAIL: 0**;
  `python3 scripts/validate-pack.py` → rc=1 with **exactly the 3 known
  issues** (live `tracker.toml` mirror files BACKLOG/STATUS/CHANGELOG
  "does not exist on disk") and nothing else — matches the declared
  baseline; the live-config correction is Pack Chat's separate
  post-commit edit per the prompt.

### 2.6 §5.1 snapshot accuracy + provenance

- The §5.1 `tracker-init.sh` fenced diff, awk-extracted and compared
  byte-for-byte against `git diff HEAD -- scripts/lib/tracker-init.sh`
  → **identical** (valid because the single intervening commit
  `aa50897` between snapshot base `0fc2ec0` and HEAD touched only
  `backlog/BD-204.md` — verified via `git log` + `merge-base
  --is-ancestor`).
- Provenance note: discloses the NIT-3 refresh + NIT-1/NIT-2 deltas
  honestly, but omits the SHOULD-1 `validate-pack.py` delta → **NIT-1
  of this review** (§1 above). The flip-log figure correction
  (162→167) verified against the primary source:
  `/tmp/bd204-c8-flip.log:22` = `closed:     167`.

### 2.7 Full battery — isolated /tmp checkout (FOREGROUND)

Copy: `rsync -a` of the working tree to `/tmp/bd204-rev2-checkout`
excluding `/tracker.toml` + `/.pack-tracker/` (exclusions asserted);
the worktree `.git` gitfile was file-copied as-is and **zero git verbs
ran inside the copy** (the CI manifest-restore step was emulated with
`cp`/`cmp`). Every `run:` step of `.github/workflows/validate-pack.yml`
(lines 97-296, enumerated from the workflow), in CI order, all rc=0:

| Step | Result |
|---|---|
| `validate-pack.py` / `PACK_VALIDATE_DEEP=1` | rc=0 / rc=0 — PASSED, all checks clean |
| test-detect | rc=0, 100/0 |
| tracker-provider / -config / **-init** / -agent-read | rc=0 ×4; **init 104/0** |
| tracker-migrate-forward / -reverse / -roundtrip | rc=0 ×3, Failed: 0 |
| phase-task / links / cycle-check / errors | rc=0 (100/0, 43/0, 26/0, 60/0) |
| **tracker-config-schema-test** | **rc=0, 34/0** |
| recommendation-state-schema / test-per-entry | rc=0 (19/0, 57/0) |
| checks-32-33-34 (85/85) / 36-37-38 / 39 / 40 / 41 / 18 / 16 / 19 / 42 / 43 / 44 / 45 / 46 / removed-doc-advisory / 49-field-faithfulness | rc=0 ×15 |
| bd129 / bd130 / bd132 / bd133 / bd134 | rc=0 ×5 (14/24/29/clean/24) |
| recommendation / pack-help / customization-preserve | rc=0 ×3 |
| test-init-project / migrate-v10-to-v11 (+dry-run/gates/decompose) | rc=0 ×5 |
| migrator-core / -manifest / -capability-translation | rc=0 (19/12/12) |
| `build.sh --all --clean` + manifest `cmp` + `--verify` | rc=0; manifest IDENTICAL (restore no-op); verify rc=0 |
| test-v11-realistic-ot | rc=0, 33/33 |
| migrator-skills / persona-contracts | rc=0 (19/0; 3/3) |
| template-translations / template-version / test-issue-forms | rc=0 ×3 |
| Live oracle `tracker-bd204-lossless-roundtrip-test.sh` | rc=0, pinned `SKIP: live-GH oracle (set PACK_TRACKER_LIVE_GH=1 + gh auth to run)` — default-SKIP honored, NOT run live |

### 2.8 Manifest + pack-only

- Real tree: `bash test-fixtures/build.sh --all --clean` rc=0;
  `git diff --quiet -- test-fixtures/manifest.txt` → **MANIFEST DIFF
  EMPTY**; `--verify` rc=0 (all fixture rows OK). The undrifted-manifest
  claim is verified, not taken on faith.
- `git diff --name-only` = exactly the 7 expected files; zero
  `project-template/` or `supporting-docs/` paths
  (`git diff HEAD --stat -- project-template/ supporting-docs/` empty).
  Untracked additions are `maintenance-docs/` reports + the
  Pack-Chat-owned `tracker.toml`. The `(pack-only)` commit-subject claim
  (Check 36) holds.
- End-state `git status --short` identical to review-start state —
  my verification disturbed nothing.

## 3. Read-in-full attestation (rule 5)

| File | Lines read |
|---|---|
| `CLAUDE.md` incl. complete `## Pack memory` | 579 (full, in session context; count verified via `wc -l`) |
| `memory/feedback_verify_full_ci_suite.md` | 42 (full) |
| `memory/feedback_agent_output_rules_applied_block.md` | 14 (full) |
| Conditional MUST-READ fired and honored | `pack-ops/PACK-MEMORY-RATIONALE.md` § rules-applied-verification-block (lines 206-235) |
| Section/full reads per prompt | `scripts/lib/tracker-init.sh` (full, 447); `scripts/validate-pack.py` 60-149 (module-header inventory) + 2590-2950 (`_validate_tracker_toml`, `_check_mirror_staleness`, `check_tracker_config`); `tracker.toml.pack-example` (full, 74); `maintenance-docs/v11-research/ARCHITECTURE.md` 460-569 (§3.1 + addendum); `scripts/tests/tracker-config-schema-test.sh` (full, 567); `scripts/tests/tracker-init-test.sh` (full, 530); `scripts/lib/tracker-mirror.sh` (full, 105); `scripts/lib/tracker-config.sh` mirror-reader grep (no mirror-key getters exist — confirms the reader-audit claim); `IMPL-REPORT-BD-204-MIRROR-KEYS.md` (full, 769); `IMPL-REPORT-BD-204-MIRROR-KEYS-FIX1.md` (full, 227); `backlog/BD-206.md` (head, scope verification); `.github/workflows/validate-pack.yml` run-step enumeration |
| NOT read | any `PACK-REVIEW-*.md` (incl. the pass-1 review) |

## Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| 1. agents-never-commit | Git verbs this session: `rev-parse`, `status --short`, `diff`/`--stat`/`--numstat`/`--name-only`/`--quiet`, `log --oneline`, `merge-base --is-ancestor`, `show HEAD:<path>` (read-only extraction ×3) — all read-only. No add/commit/push/tag/stash/reset/restore/checkout anywhere; the /tmp copy used `rsync` (no git verbs) and the CI manifest-restore was emulated via `cp`/`cmp`. HEAD before = after = `aa50897…`; end-state `git status --short` identical to start. Output = this report only. | COMPLIANT |
| 2. per-action-approval-sub-agents | No destructive ops on trusted state: `rm -rf` ran only on self-created scratch (`/tmp/bd204-rev2-*`, mktemp probe/matrix dirs). Root `tracker.toml` + `.pack-tracker/` untouched (end-state status quoted §2.8). No stop condition encountered → nothing surfaced. | COMPLIANT |
| 3. preflight-stop-means-stop | Emitted before this Write: `PREFLIGHT: review complete; verification PASS; HEAD aa508973b119b90dce1186cd32bd1e40dd50d3da; about to Write report to maintenance-docs/v11-implementation/PACK-REVIEW-BD-204-MIRROR-KEYS-REVIEW2.md`. No parent stop/halt/revert message received at any point. | COMPLIANT |
| 4. agent-output-rules-applied-block | This table; per-rule quoted evidence; conditional MUST-READ honored — `pack-ops/PACK-MEMORY-RATIONALE.md` § rules-applied-verification-block (lines 206-235) read this session; fenced format template followed. | COMPLIANT |
| 5. agents-read-rule-docs-in-full | §3 attestation: all three named files read IN FULL with line counts (579 / 42 / 14); all prompt-named section reads enumerated; fired conditional rationale section read. | COMPLIANT |
| 6. verify-full-ci-suite | Modified suites on the REAL tree (init **104/0**; schema **34/0**; real-tree `validate-pack.py` red = exactly the 3 known live-`tracker.toml` mirror issues, quoted §2.5) + FULL CI battery in the isolated /tmp checkout: every `run:` step of `validate-pack.yml` lines 97-296 executed FOREGROUND across batches 1-8, all rc=0, per-step counts tabled §2.7. Live oracle default-SKIP verified (pinned SKIP line quoted, rc=0); NOT run live; no live GitHub calls anywhere this session. | COMPLIANT |
| 7. regenerate-manifest-v11-surface | Diff touches `scripts/` (v11-surface) → real-tree `bash test-fixtures/build.sh --all --clean` rc=0; `git diff --quiet -- test-fixtures/manifest.txt` → EMPTY; `--verify` rc=0. Cross-checked in the isolated checkout: rebuild → `cmp` vs saved manifest IDENTICAL. The undrifted-manifest claim is independently verified. | COMPLIANT |
| 8. pack-only (BD-204 HARD constraint) | `git diff --name-only` = exactly the 7 expected files (quoted §2.8); `git diff HEAD --stat -- project-template/ supporting-docs/` → empty. Untracked = maintenance-docs reports + Pack-Chat-owned `tracker.toml`. The `(pack-only)` Check-36 claim holds. | COMPLIANT |
| 9. scope-deliverables-to-the-ask | One finding (NIT-1), anchored to a file+line range, defended against a stated success criterion ("honest provenance"); the pre-existing PACK-CHAT.md-marker prose recorded as an explicitly out-of-scope observation, NOT a finding; no speculative or stylistic findings raised (e.g. the 3.5 `t_pass` asymmetry was evaluated and ruled not finding-worthy). | COMPLIANT |

— end of pass-2 review —
