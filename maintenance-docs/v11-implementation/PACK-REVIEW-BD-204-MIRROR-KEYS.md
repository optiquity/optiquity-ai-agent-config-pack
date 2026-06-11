# PACK-REVIEW — BD-204 surface-aware tracker.toml [mirror] writer (reviewer pass 1)

- **Branch:** v11-dev
- **HEAD at review:** `aa508973b119b90dce1186cd32bd1e40dd50d3da`
- **Date:** 2026-06-11
- **Reviewer:** fresh pack-reviewer, foreground verification throughout
- **Scope reviewed:** entire uncommitted diff vs HEAD `aa50897` (6 modified files +
  new `IMPL-REPORT-BD-204-MIRROR-KEYS.md`), excluding the Pack-Chat-owned runtime
  artifacts (untracked root `tracker.toml`, gitignored `.pack-tracker/`) which were
  not touched by the change or by this review.

## Verdict

**APPROVE-WITH-FIXES** — no BLOCKER, no MUST. Two SHOULDs (one stale doc line
inside a modified file; one missing architect-doc reconciliation addendum that a
standing pack-memory rule makes mandatory) and three NITs. All functional claims
in the IMPL-REPORT were independently reproduced and hold.

Base-SHA note: the IMPL-REPORT cites base `0fc2ec0`; HEAD is now `aa50897`. Verified
`0fc2ec0` is an ancestor and the single intervening commit (`aa50897`) touched only
`backlog/BD-204.md` — zero overlap with the diff's files. No rebase hazard.

## Findings

### SHOULD-1 — `scripts/validate-pack.py` module-header check inventory still lists `[mirror]` as unconditional

- **Anchor:** `scripts/validate-pack.py` lines 89-98 (module docstring, Check 29
  summary): `(schema_version, [backend].name, [backend].repo, [mode].state,
  [mirror], [id_namespace].prefix, ...)` — `[mirror]` appears in the
  unconditional required-keys list.
- **Rationale:** the diff updated `_validate_tracker_toml`'s docstring and
  `check_tracker_config`'s docstring to per-surface semantics but missed the
  top-of-file check inventory in the SAME file. Per `enumerate-encoding-surfaces`
  (pack memory, roles: reviewer coder), cross-reference doc lines encoding the
  check's contract update in lock-step. One-line fix: annotate `[mirror]` as
  per-surface (client-required / pack-optional, BD-204).

### SHOULD-2 — ARCHITECTURE.md §3.1 reconciliation addendum missing (coder POQ-1; fold now)

- **Anchor:** `maintenance-docs/v11-research/ARCHITECTURE.md` lines 503-508 — the
  §3.1 schema block shows `[mirror]` unconditionally with bare-name monolith
  locations; no per-surface note. Confirmed stale against the shipped behavior.
- **Rationale:** the `architect-doc-vs-reality reconciliation` pack-memory rule
  requires the chain (a) in-code docstring naming consumers — PRESENT
  (`_tracker_init_write_config` docstring; `_validate_tracker_toml` docstring);
  (b) architect-doc addendum — MISSING; (c) IMPL-REPORT cross-reference —
  PRESENT (§8 POQ-1). The coder's deferral was prompt-scoping, not authority
  (per `no-deferral-without-user-direction`, defer-recommendations are scoping
  signals). The addendum is small (a §3.1 note: pack omits `[mirror]`
  post-BD-203/BD-204; client keeps it until BD-206; consumers
  `scripts/lib/tracker-init.sh _tracker_init_write_config` +
  `scripts/validate-pack.py _validate_tracker_toml`), unblocked, and
  same-contract with this commit — it fails the deferral size/blocked/fit test
  and should land in the fix pass. Subject to user triage per OQ-1.

### NIT-1 — pack example `[mode]` comment "mirrors regenerated" stale on pack surface (coder POQ-2; real, one-line)

- **Anchor:** `tracker.toml.pack-example` line 27: `# "tracker"   = use tracker
  as source-of-truth; mirrors regenerated.`
- **Rationale:** on the pack surface nothing is "mirror"-regenerated (per-entry
  trees + `_toc.md` are the flat representation; the new comment block directly
  below says so). Per the calling prompt's directive, flagged for the fix pass
  rather than left: one-line tweak, e.g. `; per-entry tree + _toc.md regenerated
  (no mirrors on the pack surface)`. The client example's identical comment is
  correct for its surface (BD-206 pending) and stays.

### NIT-2 — init-suite legs 1.1-1.3 cwd-sensitivity (coder POQ-3; fold-now candidate, user-gated)

- **Anchor:** `scripts/tests/tracker-init-test.sh` Group 1 — legs call
  `tracker_init_run` without `--repo-root`, defaulting to `$(pwd)`; on the real
  tree the Pack-Chat-owned `.pack-tracker/id-map.json` trips the prior-state
  rail before flag validation (reproduced: failure text is `init: prior tracker
  state found at .../.pack-tracker/id-map.json`, not the asserted needles).
- **Rationale:** pre-existing test design, green in CI by construction, NOT
  introduced by this diff. But the hardening (point those legs at a `mktemp -d`
  `--repo-root`) is ~6 lines in a file ALREADY in this diff — concrete same-file
  logical fit — and removes a recurring 3-failure reclassification burden from
  every real-tree run. Recommend fold-now in the fix pass; per OQ-1 the
  alternative is a tracked anchor (open BD), user decides at triage.

### NIT-3 — IMPL-REPORT §5.1 shows the pre-tweak diff for `tracker-init.sh`

- **Anchor:** `IMPL-REPORT-BD-204-MIRROR-KEYS.md` §5.1 (blob `7a70fca`, 4-line
  splice comment) vs the working tree (blob `3d07852`, 7-line comment beginning
  "The heredoc's two leading empty lines carry the newline...").
- **Rationale:** the report discloses the final comment tweak (§6.2, §6.4
  re-verification) but presents the pre-tweak diff as the §5.1 inventory.
  Documentation-accuracy only; the final comment text is itself accurate (I
  verified the splice mechanics it describes). No code action; optional one-line
  report correction in the fix pass.

## What was checked (clean unless noted)

### 1. Writer correctness — VERIFIED

- **Call-site threading:** `grep -rn _tracker_init_write_config scripts/
  project-template/` → exactly ONE caller, `tracker-init.sh:193`, passing
  `"$surface"` as the 5th arg. No other call site exists.
- **Shape probes (reproduced, isolated /tmp, bash):** sourced the new writer
  with stubbed deps; pack output has 0 `mirror` lines and flows
  `[mode]` → blank → `[id_namespace]` (22 lines); client output diffed against
  the HEAD writer's output (extracted via read-only `git show
  HEAD:scripts/lib/tracker-init.sh`), timestamps/user normalized →
  **diff empty, CLIENT BYTE-PARITY OK** (29 lines both). The coder's §6.1 claim
  is independently reproduced.
- **Heredoc mechanics:** `MIRROR_EOF` heredoc is single-quoted (no expansion);
  its two leading blank lines + command-substitution trailing-newline strip
  produce exactly the old writer's `opted_in_by` → blank → `[mirror]` → keys →
  blank → `[id_namespace]` layout. Verified byte-level via the parity diff.
- **Unexpected surface value:** fail-loud BEFORE the writer —
  `tracker_init_run` line 171 calls `tracker_config_resolve_path "$surface"`
  `|| return 1`, and `tracker-config.sh:80-87` rejects any surface other than
  `pack|client` with a typed validation error. Inside the writer an
  out-of-contract value would yield the pack shape (probed with `bogus`:
  0 `[mirror]` lines), but that path is unreachable through `tracker_init_run`.
  Acceptable; no finding.

### 2. Validator correctness — VERIFIED (suite + 5 independent probes)

Probes ran `check_tracker_config` against fixture roots via the suite's
`REPO_ROOT` re-point mechanism:

| Probe | Input | Expected | Observed |
|---|---|---|---|
| P1 | live example files as-shipped (pack no-mirror, client with mirror) | PASS | rc=0 |
| P2 | client example with `[mirror]` stripped | FAIL | rc=1, `project-example — missing required key: mirror` |
| P3 | client example present-but-malformed (`location_status` removed) — case the suite does NOT pin | FAIL | rc=1, `missing required key: mirror.location_status` |
| P4 | pack example with TOP-LEVEL `mirror = "x"` (non-dict) | FAIL | rc=1, `key mirror: expected dict, got str` |
| P5 | new-writer pack config promoted to Mode 3 (`forward_complete=true` + `last_forward_run`) through the staleness leg | soft-pass | rc=0, no failures |

(First P4 attempt appended the key after `[migration]`, making it
`migration.mirror` — probe corrected to top-level placement before concluding.)

- **Staleness leg genuinely unchanged:** `git diff scripts/validate-pack.py`
  hunks at 2598/2608/2689/2867/2897 only — nothing in the
  `_check_mirror_staleness` body (2770-2861). The BD-204 no-mirror guard at
  2804-2814 is pre-existing (HEAD), pinned by pre-existing Tests 15/16 (green).
- **Logic read:** `if mirror_required or "mirror" in data: mirror =
  _require("mirror", dict)` — client-absent fails via `_require`; pack-absent
  skips; present-on-either-surface is fully key/type-validated (Test 17 + P3/P4).
  No widening.

### 3. Example parity — VERIFIED

- `tracker.toml.pack-example`: `[mirror]` table removed; replacement comment
  names BD-203/BD-204/BD-206 and the Check-29 semantics; stale header line
  (monoliths as flat-file SSOT) corrected to the per-entry trees. Parses and
  passes Check 29 on the real tree (`schema OK (prefix='BD', ...)`). Consistent
  with the fixed writer's pack emission (both no-`[mirror]`; the example is
  flat-file-mode by design, the writer emits tracker-mode — expected asymmetry,
  pre-existing). Residual stale `[mode]` comment → NIT-1.
- `project-template/tracker.toml.project-example`: NOT in `git diff
  --name-only`; read in full — `[mirror]` block intact with bare names, matches
  the writer's client block key-for-key, value-for-value.
- Check 38 exemption for `tracker.toml.pack-example` already in place (real-tree
  run shows the exemption list); the BD-NNN references in the new comment are
  covered.

### 4. Reader audit — INDEPENDENTLY VERIFIED (coder's no-change claim holds)

- `grep -rn 'location_backlog|location_status|location_changelog|
  regenerate_on_write|mirror.enabled|"mirror"|[mirror]' --include=*.sh
  --include=*.py scripts/ project-template/` excluding tests → only
  `scripts/validate-pack.py` (Check 29, handled) and `scripts/lib/
  tracker-init.sh` (the writer, handled).
- Repo-wide `grep -rln location_backlog` → remainder are maintenance-docs
  reports (historical), ARCHITECTURE.md §3.1 (SHOULD-2), the examples, pinned
  test fixtures (`scripts/tests/fixtures/tracker-config/*.toml` — read-only
  parser-test inputs, intentionally out of Check 29 scope), and the live
  `tracker.toml` (Pack-Chat-owned).
- `tracker-config.sh` read in full (333 lines): no mirror-key getter; the four
  convenience getters are backend/repo/prefix/mapping; `tracker_config_get`
  returns rc=1 on absent keys by design.
- `tracker-mirror.sh` read in full (105 lines): never reads `tracker.toml`;
  all three functions take explicit paths/slugs.
- Beyond the coder's audit: checked `pack tracker mirror-rebuild`
  (`tracker-migrate-forward.sh:1238-1255` — pack surface already hard-guarded
  "not applicable on the no-mirror pack surface") and `pack tracker doctor`
  (`tracker-doctor.sh:125-188` — surface-branches to `/backlog/_toc.md` mtime
  on pack, filesystem-path probing on client; reads no mirror keys). No
  production consumer breaks on an absent `[mirror]` table.

### 5. Tests — VERIFIED

- New legs pin both shapes: init 3.3b/3.3c (pack config: no `[mirror]` header,
  no mirror keys — grep-based, byte-level), init 3.5 ×7 (client end-to-end
  through `tracker_init_run` with `docs/pack/` auto-detect: config at
  `docs/pack/tracker.toml`, all 5 mirror keys with current values, prefix TD);
  schema Test 1 GOOD_PACK reshaped to no-`[mirror]` (pins pack-shape
  acceptance), Test 7 re-targeted to the client example (preserves the
  missing-table failure-message pin — not deleted), Test 17 (pack
  present-but-malformed still FAILs).
- No coverage deleted: the diff shows only the Test 7 retarget, Test 17
  addition, GOOD_PACK reshape, and header-comment updates; Tests 2-16 bodies
  untouched. Old Test 7's pack-missing-mirror→FAIL premise is intentionally
  inverted by the approved design; its semantic successor is Test 1 (PASS pin)
  + Test 17 (no-widening pin).
- Test 3.5's `[[ -f "$cfg_cli" ]] || t_fail` has no matching `t_pass` (counts
  only on failure) — cosmetic asymmetry, not finding-worthy.

### 6. Ride-along — VERIFIED

`/tmp/bd204-c8-flip.log` still present; line 22 reads `closed:     167`. The
edit (`162` → `167 ... per the flip-log 'closed:     167' summary line`) is
correct. Remaining `162 Resolved` occurrences are intentional: the BD-204 entry
note documenting the correction, a historical review report, and the new
IMPL-REPORT quoting the old line inside its diff.

### 7. POQ dispositions (coder §8)

- **POQ-1 (ARCHITECTURE.md §3.1):** real; fold NOW → SHOULD-2.
- **POQ-2 (`[mode]` comment):** real, one-line; fold NOW per prompt directive →
  NIT-1.
- **POQ-3 (init legs 1.1-1.3 cwd-sensitivity):** real (reproduced, root cause
  confirmed as the prior-state rail on `.pack-tracker/id-map.json`); same-file
  fold-now candidate, user-gated → NIT-2.

### 8. Scope / commit hygiene — VERIFIED

- `git diff --name-only` = exactly the 6 expected files; nothing under
  `project-template/` or `supporting-docs/`; the proposed `(pack-only)` keyword
  claim holds for Check 36.
- Untracked `tracker.toml` + `.pack-tracker/` untouched throughout (end-state
  `git status --short` identical to start).
- Working tree byte-identical at review end — this review made zero repo edits
  besides this report.

## Verification runs (all FOREGROUND, this session)

### Real tree

| Command | Result |
|---|---|
| `bash scripts/tests/tracker-config-schema-test.sh` | PASS: 34 / FAIL: 0 (incl. 7.1/7.2 retarget, 15/16, 17.1/17.2) |
| `bash scripts/tests/tracker-init-test.sh` | Passed: 101 / Failed: 3 — legs 1.1/1.2/1.3 only; failure text reproduced as `init: prior tracker state found at .../.pack-tracker/id-map.json` → environmental (runtime artifact at cwd), matches coder classification, NOT caused by this diff |
| `python3 scripts/validate-pack.py` | FAILED — exactly the 3 known POQ-1 issues (`tracker.toml — mirror file 'BACKLOG.md'/'STATUS.md'/'CHANGELOG.md' ... does not exist on disk`); both example files `schema OK`; zero issues from this change. Expected: the live config correction is Pack Chat's separate post-commit edit per the prompt |
| `git diff -- test-fixtures/manifest.txt` | empty (0 files) |

### Isolated /tmp checkout — full CI battery

Copy: `rsync -a` of the working tree to `/tmp/bd204-rev-checkout` excluding root
`tracker.toml` + `.pack-tracker/`; `.git` included; ZERO git verbs executed
inside the copy (the CI `git checkout HEAD -- test-fixtures/manifest.txt` step
emulated via saved-copy `cp`/`cmp`). Every `run:` step of
`.github/workflows/validate-pack.yml` (lines 95-296), in CI order:

| Step | Result |
|---|---|
| `python3 scripts/validate-pack.py` | rc=0 (the 3 mirror issues are absent without the runtime artifacts — confirms they are environment-only) |
| `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | rc=0 |
| test-detect | rc=0, 100/0 |
| tracker-provider / tracker-config / **tracker-init** / tracker-agent-read | rc=0 ×4; **init: Failed: 0 — all 104 incl. 3.3b/3.3c/3.5×7** (proves the 3 real-tree failures environmental) |
| tracker-migrate-forward / -reverse / -roundtrip | rc=0 ×3 |
| test-tracker-phase-task / -links / -cycle-check / tracker-errors | rc=0 ×4 |
| **tracker-config-schema-test** | **rc=0, PASS: 34 / FAIL: 0** |
| recommendation-state-schema / test-per-entry | rc=0 (19/0, 57/0) |
| checks-32-33-34 (PASS 85) / 36-37-38 / 39 / 40 / 41 / 18 / 16 / 19 / 42 / 43 / 44 / 45 / 46 / removed-doc-advisory / 49-field-faithfulness | rc=0 ×15, all clean |
| bd129 / bd130 / bd132 / bd133 / bd134 | rc=0 ×5 (14/24/29/clean/24) |
| recommendation / pack-help / test-customization-preserve | rc=0 ×3 |
| test-init-project / test-migrate-v10-to-v11 (+ dry-run / gates / decompose) | rc=0 ×5 |
| test-migrator-core / -manifest / -capability-translation | rc=0 (19/12/12) |
| `test-fixtures/build.sh --all --clean` | rc=0; manifest `cmp` vs saved copy → **IDENTICAL** (restore a no-op); `--verify` rc=0 |
| test-v11-realistic-ot | rc=0, PASS: 33 / FAIL: 0 |
| test-migrator-skills / test-persona-contracts | rc=0 (19/0; 3/3) |
| template-translations / template-version / test-issue-forms | rc=0 ×3 |

Live oracle: `tracker-bd204-lossless-roundtrip-test.sh` is NOT a workflow step
(grep of `.github/` → no reference); run unattended anyway → pinned
`SKIP: live-GH oracle (set PACK_TRACKER_LIVE_GH=1 + gh auth to run)`, rc=0.
Default-SKIP honored; NOT run live; no live GitHub calls made anywhere in this
review. (Minor framing note: the IMPL-REPORT §6.4 tables it among workflow
steps; it is a local-only script — no action needed.)

### Manifest claim (rule 7) — verified two ways

- Rebuild in the isolated checkout (which carries all 6 modified files) →
  manifest byte-identical to HEAD's.
- Mechanism: `find test-fixtures -path '*scripts/lib*'` → fixture trees carry
  ONLY `detect.sh`; no `tracker-init.sh`, no `validate-pack.py`, no
  `tracker.toml.pack-example` anywhere under `test-fixtures/` (fixture
  `tracker.toml*` files are pinned migration inputs, explicitly excluded from
  Check 29 per its docstring). Real-tree `git diff -- test-fixtures/manifest.txt`
  empty. The coder's empty-diff claim holds.

## Read-in-full attestation (rule 5)

| File | Lines read |
|---|---|
| `CLAUDE.md` incl. complete `## Pack memory` | 580 (full, via Read) |
| `~/.claude/.../memory/feedback_verify_full_ci_suite.md` | 43 (full) |
| `~/.claude/.../memory/feedback_agent_output_rules_applied_block.md` | 15 (full) |
| Conditional MUST-READ fired and honored | `pack-ops/PACK-MEMORY-RATIONALE.md` § rules-applied-verification-block (lines 195-235) |
| Section reads per prompt | `scripts/lib/tracker-init.sh` (full, 448 lines — `_tracker_init_write_config` + sole caller `tracker_init_run`); `scripts/validate-pack.py` 2590-2929 (`_validate_tracker_toml`, `_check_mirror_staleness`, `check_tracker_config`) + module header 85-104; `tracker.toml.pack-example` (full, 73); `project-template/tracker.toml.project-example` (full, 76, READ-ONLY); `scripts/lib/tracker-config.sh` (full, 334); `scripts/lib/tracker-mirror.sh` (full, 106); `scripts/tests/tracker-config-schema-test.sh` lines 30-160 + full diff of all changed legs; `scripts/tests/tracker-init-test.sh` full diff of new legs 3.3b/3.3c/3.5; `scripts/lib/tracker-doctor.sh` 120-209 (reader audit); `maintenance-docs/v11-research/ARCHITECTURE.md` 473-547 (§3.1); `IMPL-REPORT-BD-204-MIRROR-KEYS.md` (full, 757) |
| NOT read | any `PACK-REVIEW-*.md` (prompt prohibition honored; a grep hit listed filenames only) |

## Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| 1. agents-never-commit | Git verbs this session: `rev-parse`, `status --short`, `diff`/`diff --stat`/`diff --name-only`, `log --oneline`, `merge-base --is-ancestor`, `show --stat`, `show HEAD:scripts/lib/tracker-init.sh` (read-only extraction) — all read-only. No add/commit/push/tag/stash/reset/restore/checkout anywhere (CI manifest-restore step emulated with `cp`/`cmp` in the /tmp copy specifically to avoid `git checkout`). Output = this report only. | COMPLIANT |
| 2. per-action-approval-sub-agents | No destructive ops on trusted state: `rm -rf` ran only on self-created /tmp scratch (`bd204-rev-probe*`, `bd204-rev-checkout`, runner/log files, mktemp fixture dirs). Root `tracker.toml` + `.pack-tracker/` untouched; end-state `git status --short` identical to start (6 ` M` + 2 `??` + this report). | COMPLIANT |
| 3. preflight-stop-means-stop | Emitted before this Write: `PREFLIGHT: review complete; verification PASS; HEAD aa508973b119b90dce1186cd32bd1e40dd50d3da; about to Write report to maintenance-docs/v11-implementation/PACK-REVIEW-BD-204-MIRROR-KEYS.md`. No parent stop message received at any point. | COMPLIANT |
| 4. agent-output-rules-applied-block | This table; per-rule quoted evidence; conditional MUST-READ honored — `pack-ops/PACK-MEMORY-RATIONALE.md` § rules-applied-verification-block (lines 206-233) read this session; format template followed. | COMPLIANT |
| 5. agents-read-rule-docs-in-full | Attestation table above: all three named files read IN FULL with line counts (CLAUDE.md 580 incl. complete Pack memory; verify-full-ci-suite memory 43; rules-applied-block memory 15); section reads enumerated per prompt. | COMPLIANT |
| 6. verify-full-ci-suite | Modified suites on the real tree (schema 34/0; init 101/3, all 3 reproduced + classified environmental with the rail's error text quoted) + FULL CI battery in the isolated /tmp checkout: every `run:` step of `validate-pack.yml` lines 95-296 executed FOREGROUND, all rc=0, per-step counts tabled above. Real-tree `validate-pack.py` failures = exactly the 3 known POQ-1 mirror-file issues (quoted). Live oracle default-SKIP verified (pinned SKIP line, rc=0); NOT run live; no live GitHub call made. | COMPLIANT |
| 7. regenerate-manifest-v11-surface | Empty-diff claim verified: real-tree `git diff --name-only -- test-fixtures/manifest.txt` → 0 files; isolated-checkout rebuild (`build.sh --all --clean` rc=0) → `cmp` vs saved manifest IDENTICAL; `--verify` rc=0. Mechanism confirmed: `find test-fixtures -name 'tracker-init*'` → none; fixture `scripts/lib/` trees carry only `detect.sh`; no `validate-pack.py` / pack example ships into fixtures. | COMPLIANT |
| 8. pack-only (BD-204 HARD constraint) | `git diff --name-only` = `maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-CLOSE-REASON-FIX.md`, `scripts/lib/tracker-init.sh`, `scripts/tests/tracker-config-schema-test.sh`, `scripts/tests/tracker-init-test.sh`, `scripts/validate-pack.py`, `tracker.toml.pack-example` — zero `project-template/` or `supporting-docs/` paths. Client example read-only, unmodified. | COMPLIANT |
| 9. scope-deliverables-to-the-ask | Findings limited to defects in/adjacent-to this change: SHOULD-1 (stale line in a file THIS diff modified), SHOULD-2 + NIT-1 + NIT-2 (the coder's own three POQs, each assessed per the prompt's explicit ask), NIT-3 (this change's IMPL-REPORT accuracy). Pre-existing stale prose discovered elsewhere (help-fragment "flat files become read-only mirrors" wording on the pack surface) predates this change, is BD-203/BD-206-adjacent, and was deliberately NOT raised as a finding against this diff. | COMPLIANT |

— end of review —
