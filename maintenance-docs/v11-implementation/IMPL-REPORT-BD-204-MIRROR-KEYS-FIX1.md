# IMPL-REPORT — BD-204 mirror-keys fix-coder pass 1 (FIX1)

- **Branch:** v11-dev
- **HEAD:** `aa508973b119b90dce1186cd32bd1e40dd50d3da` (unchanged — no commits made)
- **Date:** 2026-06-11
- **Scope:** exactly the five APPROVE-WITH-FIXES findings from
  `PACK-REVIEW-BD-204-MIRROR-KEYS.md` (user triage: FIX-ALL). All edits are
  targeted in-place edits on the UNCOMMITTED BD-204 working-tree change.
- **Not touched:** Pack-Chat-owned untracked root `tracker.toml` + gitignored
  `.pack-tracker/`; `project-template/`; `supporting-docs/`; no live GitHub
  calls anywhere.

## 1. Per-finding before/after

### SHOULD-1 — `scripts/validate-pack.py` module-header Check 29 inventory

- **Before** (module docstring, Check 29 summary): `... [mode].state`,
  `` `[mirror]`, `[id_namespace].prefix`, ... `` — `[mirror]` listed in the
  unconditional required-keys list.
- **After:** `` `[mirror]` (per-surface, BD-204: required on the client
  example; optional/omitted on the no-monolith pack example), `` — the
  inventory now matches `_validate_tracker_toml`'s `mirror_required`
  per-surface contract. 1 line → 3 lines; no other docstring text changed.

### SHOULD-2 — ARCHITECTURE.md §3.1 reconciliation addendum

- **Before:** `maintenance-docs/v11-research/ARCHITECTURE.md` §3.1 schema
  block showed `[mirror]` unconditionally; no as-built note.
- **After:** a blockquote **as-built addendum** inserted immediately after
  the §3.1 schema fence (house style per `ARCHITECTURE-BD-204.md` §7's
  reconciliation-ledger pattern: dated, adjoining, supersession-explicit).
  It states the table is SURFACE-CONDITIONAL as built — pack omits `[mirror]`
  under the no-monolith model realized at BD-203/BD-204; client keeps the
  bare-name keys until BD-206 — and names the realized consumers by file +
  symbol only: `scripts/lib/tracker-init.sh` — `_tracker_init_write_config`;
  `scripts/validate-pack.py` — `_validate_tracker_toml` (per-surface
  `mirror_required`). No line numbers anywhere in the addendum.
- **Dated record byte-stable:** `git diff --stat` on the file = `16
  insertions(+), 0 deletions(-)`; grep of the diff for deleted lines → 0.
  The schema block and all surrounding prose are untouched.

### NIT-1 — `tracker.toml.pack-example` stale `[mode]` comment

- **Before:** `# "tracker"   = use tracker as source-of-truth; mirrors
  regenerated.`
- **After:**
  ```
  # "tracker"   = use tracker as source-of-truth; the per-entry trees +
  #               _toc.md regenerate from tracker state (no monolith
  #               mirrors on the pack surface post-BD-203).
  ```
- The client example's identical comment is correct for its surface (BD-206
  pending) and was NOT touched (file not in the diff).

### NIT-2 — init-suite legs 1.1-1.3 cwd-sensitivity hardening

- **Root cause (reviewer's, confirmed):** legs 1.1-1.3 called
  `tracker_init_run` without `--repo-root`, defaulting to `$(pwd)`; a
  runtime `.pack-tracker/id-map.json` at the suite's cwd tripped the
  prior-state rail before flag validation.
- **Fix** (`scripts/tests/tracker-init-test.sh`, Group 1): a scratch
  `TR_FLAGVAL=$(mktemp -d ...)` root with a `pack-ops/` surface marker
  (so surface auto-detect still resolves `pack` and the legs reach the
  intended backend/repo validation errors); `--repo-root "$TR_FLAGVAL"`
  added to the three `tracker_init_run` calls; `rm -rf "$TR_FLAGVAL"`
  cleanup; 5-line explanatory comment citing BD-204 review NIT-2. Asserted
  needles unchanged. Legs 1.4+ untouched.
- **Real-tree green proof (the explicit NIT-2 criterion):**
  `bash scripts/tests/tracker-init-test.sh` ON THE REAL TREE (with the
  Pack-Chat-owned `.pack-tracker/` present at the repo root) →
  `Passed: 104 / Failed: 0 / All tests passed.` (was 101/3 at review).

### NIT-3 — IMPL-REPORT §5.1 stale pre-tweak diff snapshot

- **Fix** (`IMPL-REPORT-BD-204-MIRROR-KEYS.md`): the §5.1 `tracker-init.sh`
  diff refreshed to the final working-tree shape: index line
  `f7a91b8..7a70fca` → `f7a91b8..3d07852`; the 4-line splice comment
  replaced with the actual 7-line heredoc-mechanics comment; hunk headers
  `+356,25` → `+356,28` and `+386,7` → `+389,7`. A provenance blockquote
  added under the §5 intro disclosing the refresh AND that fix pass 1
  further amended `tracker.toml.pack-example` (NIT-1) and
  `scripts/tests/tracker-init-test.sh` (NIT-2) beyond the §5.1/§5.2
  snapshots, with deltas documented in THIS report — keeping the whole of
  §5 honest after this pass.
- **Byte-equality proof:** the refreshed §5.1 `tracker-init.sh` fenced
  portion extracted via `awk` and diffed against
  `git diff 0fc2ec0 -- scripts/lib/tracker-init.sh` → identical
  (`SECTION-5.1-INIT-DIFF-MATCHES-REAL-DIFF`). The §5.1 validate-pack.py +
  pack-example portions were verified current against `git diff 0fc2ec0`
  BEFORE my NIT-1 edit (byte-for-byte match), hence the provenance note
  rather than a second snapshot refresh.

## 2. Verification evidence

### 2.1 Syntax / parse checks (real tree, FOREGROUND)

| Check | Result |
|---|---|
| `bash -n scripts/tests/tracker-init-test.sh` | OK |
| `python3 -m py_compile scripts/validate-pack.py` | OK |
| `python3 -c "tomllib.load(tracker.toml.pack-example)"` | parse OK |

### 2.2 Real tree (FOREGROUND)

| Command | Result |
|---|---|
| `bash scripts/tests/tracker-init-test.sh` | **Passed: 104 / Failed: 0** — legs 1.1-1.3 now green on the real tree with `.pack-tracker/` present (NIT-2 criterion met) |
| `bash scripts/tests/tracker-config-schema-test.sh` | PASS: 34 / FAIL: 0 |
| `python3 scripts/validate-pack.py` | FAILED — exactly the 3 known mirror issues from the Pack-Chat-owned live `tracker.toml` (`mirror file 'BACKLOG.md'/'STATUS.md'/'CHANGELOG.md' ... does not exist on disk`); zero issues from this fix pass |
| `bash test-fixtures/build.sh --all --clean` then `git diff -- test-fixtures/manifest.txt` | build rc=0; **manifest diff empty** (no staging needed) |

### 2.3 Isolated /tmp checkout — full CI battery (FOREGROUND)

Copy: `rsync -a` of the working tree to `/tmp/bd204-fix1-checkout` excluding
root `/tracker.toml` + `/.pack-tracker/` (exclusions asserted); ZERO git
verbs executed inside the copy — the CI `git checkout HEAD --
test-fixtures/manifest.txt` restore step emulated via a saved-copy
`cp`/`cmp`. Every `run:` step of `.github/workflows/validate-pack.yml`
(lines 97-296), in CI order:

| Step | Result |
|---|---|
| `python3 scripts/validate-pack.py` | rc=0 (the 3 mirror issues absent without the runtime artifacts — environment-only, confirmed again) |
| `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | rc=0 |
| test-detect | rc=0 |
| tracker-provider / tracker-config / **tracker-init** / tracker-agent-read | rc=0 ×4; **init: Passed: 104 / Failed: 0** |
| tracker-migrate-forward / -reverse / -roundtrip | rc=0 ×3, Failed: 0 each |
| test-tracker-phase-task / -links / -cycle-check / tracker-errors | rc=0 ×4, Failed: 0 each |
| **tracker-config-schema-test** | **rc=0, PASS: 34 / FAIL: 0** |
| recommendation-state-schema / test-per-entry | rc=0 (19/0, 57/0) |
| checks-32-33-34 (PASS 85) / 36-37-38 / 39 / 40 / 41 / 18 / 16 / 19 / 42 / 43 / 44 / 45 / 46 / removed-doc-advisory / 49-field-faithfulness | rc=0 ×15, FAIL: 0 each |
| bd129 / bd130 / bd132 / bd133 / bd134 | rc=0 ×5 (14/24/29/clean/24 passed, 0 failed) |
| recommendation / pack-help / test-customization-preserve | rc=0 ×3 |
| test-init-project / test-migrate-v10-to-v11 (+ dry-run / gates / decompose) | rc=0 ×5 |
| test-migrator-core / -manifest / -capability-translation | rc=0 (19/12/12) |
| `test-fixtures/build.sh --all --clean` | rc=0; manifest `cmp` vs saved pre-build copy → **IDENTICAL** (restore a no-op); restore emulated via `cp`; `--verify` rc=0, all 6 fixture rows OK |
| test-v11-realistic-ot | rc=0, PASS: 33 / FAIL: 0 |
| test-migrator-skills / test-persona-contracts | rc=0 (19/0; 3/3) |
| template-translations / template-version / test-issue-forms | rc=0 ×3 |

Live oracle: `tracker-bd204-lossless-roundtrip-test.sh` (local-only, not a
workflow step) run unattended → pinned `SKIP: live-GH oracle (set
PACK_TRACKER_LIVE_GH=1 + gh auth to run)`, rc=0. Default-SKIP honored; NOT
run live; no live GitHub calls made anywhere this session.

Scratch (`/tmp/bd204-fix1-*`) removed after verification.

## 3. Boundary discipline check (P-missed-7)

No project-side file was edited: all five fixes touch pack-side surfaces
only (`scripts/`, `maintenance-docs/`, `tracker.toml.pack-example`).
`project-template/tracker.toml.project-example` and the project trinity were
not touched (confirmed by end-state `git status` — no `project-template/`
path in the diff). No SSOT-investigation needed; no boundary stop raised.

## 4. Plan deviations

None. The five fixes landed exactly as scoped. The only judgment call within
scope: NIT-3's "refresh or relabel" option resolved as refresh-plus-
provenance-note — the refresh makes §5.1 byte-accurate for the file this fix
pass does NOT touch (`tracker-init.sh`), and the note honestly discloses the
NIT-1/NIT-2 deltas this pass added on top of the §5.1/§5.2 snapshots.

## 5. New POQs introduced

None.

## 6. Definition-of-Done checklist

| Item | Status |
|---|---|
| SHOULD-1: module-header inventory per-surface | PASS (re-read; quoted in §1) |
| SHOULD-2: §3.1 as-built addendum, file+symbol, dated record byte-stable | PASS (16+/0− diff; consumers by symbol; no line numbers) |
| NIT-1: `[mode]` comment rewords to no-monolith truth | PASS (TOML still parses; Check 29 green via suites) |
| NIT-2: legs 1.1-1.3 cwd-hardened; init suite green ON THE REAL TREE | PASS (104/0 real-tree, was 101/3) |
| NIT-3: §5.1 snapshot honest | PASS (awk-extract vs `git diff 0fc2ec0` identical + provenance note) |
| Modified suites green (init, schema) real tree | PASS (104/0; 34/0) |
| Full CI battery, isolated /tmp checkout, foreground | PASS (every `run:` step rc=0; tables in §2.3) |
| Manifest regen + drift check | PASS (rebuild rc=0; diff empty) |
| Untracked `tracker.toml` + `.pack-tracker/` untouched | PASS (end-state `git status` identical modulo this report) |
| No git state-changing verbs; no live GH calls | PASS |

## 7. Files changed inventory (this fix pass)

| Path | Change |
|---|---|
| `scripts/validate-pack.py` | modified (SHOULD-1: module docstring, +2 net lines) |
| `maintenance-docs/v11-research/ARCHITECTURE.md` | modified (SHOULD-2: +16 lines, pure insertion) |
| `tracker.toml.pack-example` | modified (NIT-1: 1 comment line → 3) |
| `scripts/tests/tracker-init-test.sh` | modified (NIT-2: Group 1 hardening, +11 net lines) |
| `maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-MIRROR-KEYS.md` | modified (NIT-3: §5.1 refresh + §5 provenance note; untracked file) |
| `maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-MIRROR-KEYS-FIX1.md` | new (this report) |

End-state `git status --short` (tracked): the six BD-204 files from the base
change (` M`) + ` M maintenance-docs/v11-research/ARCHITECTURE.md`;
untracked: the two BD-204 docs + this report + Pack-Chat-owned
`tracker.toml` (`.pack-tracker/` gitignored). Nothing else.

## 8. Read-in-full attestation (rule 5)

| File | Lines read |
|---|---|
| `CLAUDE.md` incl. complete `## Pack memory` | 579 (full, in session context) |
| `maintenance-docs/v11-implementation/PACK-REVIEW-BD-204-MIRROR-KEYS.md` | 310 (full, via Read) |
| `~/.claude/.../memory/feedback_edit_in_place_not_full_rewrite.md` | 15 (full) |
| `~/.claude/.../memory/feedback_verify_full_ci_suite.md` | 43 (full) |
| `~/.claude/.../memory/feedback_agent_output_rules_applied_block.md` | 15 (full) |
| Conditional MUST-READ fired and honored | `pack-ops/PACK-MEMORY-RATIONALE.md` § rules-applied-verification-block (lines 206-235) |
| Section reads for the work | `scripts/lib/tracker-init.sh` (full, 447); `scripts/validate-pack.py` 80-109 (Check 29 inventory); `tracker.toml.pack-example` (full, 72→74); `scripts/tests/tracker-init-test.sh` 1-140 (Group 1) + re-read post-edit; `maintenance-docs/v11-research/ARCHITECTURE.md` 470-554 (§3.1) + post-edit re-read; `ARCHITECTURE-BD-204.md` §6-§7 (addendum house style); `IMPL-REPORT-BD-204-MIRROR-KEYS.md` §5 region (126-356) + header map |
| NOT read | any prior `PACK-REVIEW-*.md` other than the pass-1 review this fix pass implements |

## Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| 1. agents-never-commit | Git verbs this session: `rev-parse`, `status`, `status --short`, `diff`/`diff --stat`/`diff --name-only` (incl. `git diff 0fc2ec0 -- <path>` read-only extraction). No add/commit/push/tag/stash/reset/restore/checkout anywhere; the CI manifest-restore step was emulated with `cp`/`cmp` in the /tmp copy specifically to avoid `git checkout`. HEAD before = after = `aa50897…`. Output = working-tree edits + this report. | COMPLIANT |
| 2. per-action-approval-sub-agents | No destructive ops on trusted state: `rm -rf` ran only on self-created scratch (`TR_FLAGVAL` mktemp dir inside the suite, `/tmp/bd204-fix1-*`). Root `tracker.toml` + `.pack-tracker/` untouched (end-state `git status --short` quoted in §7). No stop condition encountered → nothing surfaced. | COMPLIANT |
| 3. preflight-stop-means-stop | Emitted before this Write: `PREFLIGHT: 5/5 fixes complete; verification PASS; HEAD aa508973b119b90dce1186cd32bd1e40dd50d3da; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-MIRROR-KEYS-FIX1.md`. No parent stop/halt/revert message received at any point. | COMPLIANT |
| 4. agent-output-rules-applied-block | This table; per-rule quoted evidence; conditional MUST-READ honored — `pack-ops/PACK-MEMORY-RATIONALE.md` § rules-applied-verification-block (lines 206-235) read this session; fenced format template followed. | COMPLIANT |
| 5. agents-read-rule-docs-in-full | §8 attestation: all five named files read IN FULL with line counts (CLAUDE.md 579 incl. complete Pack memory; review 310; the three memory files 15/43/15); section reads enumerated. | COMPLIANT |
| 6. verify-full-ci-suite | Modified suites on the REAL tree (init **104/0 — green with `.pack-tracker/` present, the explicit NIT-2 criterion**; schema 34/0; real-tree `validate-pack.py` red = exactly the 3 known mirror issues, quoted in §2.2) + FULL CI battery in the isolated /tmp checkout: every `run:` step of `validate-pack.yml` lines 97-296 executed FOREGROUND, all rc=0, per-step counts tabled in §2.3. Live oracle default-SKIP verified (pinned SKIP line quoted, rc=0); NOT run live. | COMPLIANT |
| 7. regenerate-manifest-v11-surface | `scripts/` touched → real-tree `bash test-fixtures/build.sh --all --clean` rc=0; `git diff -- test-fixtures/manifest.txt` EMPTY (nothing to stage). Cross-checked in the isolated checkout: rebuild → `cmp` vs saved manifest IDENTICAL; `--verify` rc=0, all 6 rows OK. Matches the reviewer's mechanism note (these files do not ship into fixtures). | COMPLIANT |
| 8. edit-in-place-not-full-rewrite | 8 targeted Edit calls, zero full-file Writes on existing files; every edited region re-read post-edit (§1 quotes are from the re-reads, not intent). ARCHITECTURE.md dated record byte-stable: `git diff --stat` = 16 insertions, 0 deletions; deleted-line grep of the diff → 0. §5.1 refresh proven byte-equal to the real diff via awk-extract + `diff`. | COMPLIANT |
| 9. pack-only | End-state `git status --short` (§7): the six base-change files + `ARCHITECTURE.md` (in-scope SHOULD-2) modified; untracked = the two BD-204 docs + this report + the Pack-Chat-owned runtime artifacts. Zero `project-template/` or `supporting-docs/` paths; manifest undrifted. | COMPLIANT |
| 10. scope-deliverables-to-the-ask | Exactly the five findings fixed; no other file or region touched (e.g. the client example, the `[mode]` comment in the client example, IMPL-REPORT §8 POQ dispositions, and the suite's cosmetic 3.5 `t_pass` asymmetry the reviewer ruled not finding-worthy were all deliberately left alone). | COMPLIANT |

— end of FIX1 report —
