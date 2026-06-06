# IMPL-REPORT — BD-204 C-5 CI-RED fix (bd134 forward-reads-tree fixture)

- **Branch:** `v11-dev`
- **Base HEAD (start):** `e228b38821c9a8a8e043e76a76d0faf0d76f68a2`
- **Final HEAD (this worktree):** `e228b38821c9a8a8e043e76a76d0faf0d76f68a2` (no commit — agents never commit; edits left unstaged)
- **Scope:** `pack-only` — `scripts/tests/` test-fixture edit only. No `project-template/`, no production-code change.

---

## 1. Root cause

C-5 (committed at `e228b38`) made the pack-surface FORWARD migration read the
per-entry TREE under `<repo>/backlog/` instead of the deleted
`pack-ops/BACKLOG.md` monolith:

`scripts/lib/tracker-migrate-forward.sh` (pack surface, ~L790-807):
```
backlog_path="$repo_root/backlog"
...
entries=$(tmf_parse_backlog_tree "pack-backlog" "$backlog_path") || return 1
```
`tmf_parse_backlog_tree` (~L506-510) hard-fails when the tree dir is absent:
```
tracker_error_emit "not-found" "per-entry tree not found at $stream_dir"
```

`tracker-bd134-close-retry-test.sh` `build_repo()` still SEEDED the monolith
(`pack-ops/BACKLOG.md`) and never created `<repo>/backlog/`. Groups 1 & 2 call
`tracker_migrate_forward_run` on the pack surface → "per-entry tree not found"
→ 15 failing assertions. (Group 3 is helper-only, no migration; it stayed
green.) The C-5 coder did not run this integration test, so the breakage only
surfaced in CI.

---

## 2. CI test-harness enumeration (the FULL set CI runs)

CI workflow: `.github/workflows/validate-pack.yml`. Two jobs.

**`validate` job:** `python3 scripts/validate-pack.py`.

**`tests` job (per-name steps, in workflow order):**

```
scripts/test-detect.sh
scripts/tests/tracker-provider-test.sh
scripts/tests/tracker-config-test.sh
scripts/tests/tracker-init-test.sh
scripts/tests/tracker-agent-read-test.sh
scripts/tests/tracker-migrate-forward-test.sh
scripts/tests/tracker-migrate-reverse-test.sh
scripts/tests/tracker-migrate-roundtrip-test.sh
scripts/tests/test-tracker-phase-task.sh
scripts/tests/test-tracker-links.sh
scripts/tests/test-tracker-cycle-check.sh
scripts/tests/tracker-errors-test.sh
scripts/tests/tracker-config-schema-test.sh
scripts/tests/recommendation-state-schema-test.sh
scripts/tests/test-per-entry.sh
scripts/tests/test-validate-pack-checks-32-33-34.sh
scripts/tests/test-validate-pack-checks-36-37-38.sh
scripts/tests/test-validate-pack-check-39.sh
scripts/tests/test-validate-pack-check-40.sh
scripts/tests/test-validate-pack-check-41.sh
scripts/tests/test-validate-pack-check-18.sh
scripts/tests/test-validate-pack-check-16.sh
scripts/tests/test-validate-pack-check-19.sh
scripts/tests/test-validate-pack-check-42.sh
scripts/tests/test-validate-pack-check-43.sh
scripts/tests/test-validate-pack-check-44.sh
scripts/tests/test-validate-pack-check-45.sh
scripts/tests/test-validate-pack-check-46.sh
scripts/tests/test-validate-pack-check-removed-doc-advisory.sh
scripts/tests/tracker-bd129-gh-repo-test.sh
scripts/tests/tracker-bd130-doctor-wired-test.sh
scripts/tests/tracker-bd132-race-test.sh
scripts/tests/tracker-bd133-header-preservation-test.sh
scripts/tests/tracker-bd134-close-retry-test.sh
scripts/tests/recommendation-test.sh
scripts/tests/pack-help-test.sh
scripts/tests/test-customization-preserve.sh
scripts/tests/test-init-project.sh
scripts/tests/test-migrate-v10-to-v11.sh
scripts/tests/test-migrate-v10-to-v11-dry-run.sh
scripts/tests/test-migrate-v10-to-v11-gates.sh
scripts/tests/test-migrate-v10-to-v11-decompose.sh
scripts/test-migrator-core.sh
scripts/test-migrator-manifest.sh
scripts/test-migrator-capability-translation.sh
test-fixtures/build.sh --all --clean        (build fixtures)
git checkout HEAD -- test-fixtures/manifest.txt   (restore manifest)
test-fixtures/build.sh --verify              (manifest verify)
scripts/tests/test-v11-realistic-ot.sh
scripts/test-migrator-skills.sh
scripts/test-persona-contracts.sh
scripts/tests/template-translations-test.sh
scripts/tests/template-version-test.sh
scripts/tests/test-issue-forms.sh
```

I reproduced this full set locally (fixtures built first per CI ordering, so
the fixture-dependent tests — migrator-skills / persona-contracts /
manifest-verify / v11-realistic-ot — run against built artifacts).

---

## 3. The fix (bd134 fixture)

File: `scripts/tests/tracker-bd134-close-retry-test.sh`. Two edits.

**Edit A — source the per-entry decompose libs** (needed to seed the tree),
mirroring `tracker-migrate-roundtrip-test.sh`:
```
source "$LIB_DIR/per-entry/_lib.sh"
source "$LIB_DIR/per-entry/decompose.sh"
```

**Edit B — `build_repo()` now seeds the per-entry TREE, not the monolith.**
The inline 2-entry backlog content is unchanged; it is written to a temp
monolith and decomposed into `<repo>/backlog/` via
`per_entry_decompose "pack-backlog"` — the exact C-5 reconcile pattern from
`tracker-migrate-roundtrip-test.sh::_setup_test_repo`. The `pack-ops/`
directory marker is kept (so `tracker_config_auto_surface` returns `"pack"`);
NO `pack-ops/BACKLOG.md` is written (fail-loud, no monolith). The new core:
```
    # pack-surface marker (so tracker_config_auto_surface returns "pack").
    mkdir -p "$repo/pack-ops"
    # Seed the per-entry TREE (no monolith) for the C-5 forward read-side.
    mkdir -p "$repo/backlog"
    local _mono
    _mono=$(mktemp -t bd134-mono.XXXXXX)
    cat > "$_mono" <<'EOF'
# Backlog

## Active

**BD-001 — First entry, will be closed**
Type: TODO(v11)
Status: Resolved
...
**BD-002 — Second entry, will be closed**
...
EOF
    per_entry_decompose "pack-backlog" "$_mono" "$repo/backlog" >/dev/null
    rm -f "$_mono"
```

**Assertions preserved verbatim.** No assertion in Groups 1/2/3 was changed —
only the fixture SEED. Group 1 (transient close → retry recovers), Group 2
(persistent close → bounded partial-write naming the gh-id, exactly 3
attempts/id), and Group 3 (`_tmf_retry_one_close` helper isolation) all run as
written.

bd134 result after fix: **24 passed, 0 failed** (was 9 passed / 15 failed).

---

## 4. Same-class sweep (verify-full-ci-suite + enumerate-encoding-surfaces)

I enumerated EVERY test that both (a) seeds a monolith and (b) exercises the
pack forward/reverse path — the exact breakage class.

Tests seeding a monolith (`pack-ops/BACKLOG.md` or `> ...BACKLOG.md`):
```
grep -ln 'pack-ops/BACKLOG.md\|>.*BACKLOG\.md' scripts/tests/*.sh scripts/*.sh
```
Tests calling the pack forward/reverse path:
```
grep -ln 'tracker_migrate_forward_run\|tracker_migrate_reverse_run' scripts/tests/*.sh scripts/*.sh
```

Intersection (the class) and disposition:

| Test | Seeds | Calls pack path | Status |
|---|---|---|---|
| `tracker-bd134-close-retry-test.sh` | was monolith | forward | **FIXED this commit** |
| `tracker-migrate-forward-test.sh` | tree (`per_entry_decompose`) | forward | Already C-5-reconciled — PASS |
| `tracker-migrate-reverse-test.sh` | tree | reverse | Already C-5-reconciled — PASS |
| `tracker-migrate-roundtrip-test.sh` | tree | forward+reverse | Already C-5-reconciled — PASS |
| `tracker-bd132-race-test.sh` | tree (`$REPO/backlog/BD-*.md`, no monolith) | reverse only | Already tree-seeded (C-4) — PASS |

Conclusion: bd134 was the **only** un-reconciled test in the class. The other
forward/reverse tests were already moved to tree-seed during C-4/C-5. CI
surfaced only bd134, and the exhaustive sweep confirms no other test would
break under forward-reads-tree.

(The remaining files in the monolith-seeding grep — e.g.
`test-validate-pack-check-40.sh`, `tracker-config-schema-test.sh`,
`test-per-entry.sh`, `test-v11-realistic-ot.sh`, `tracker-agent-read-test.sh`,
`tracker-bd133-header-preservation-test.sh` — do NOT call the pack
forward/reverse migration, so they are out of the breakage class. All pass.)

---

## 5. Manifest (regenerate-manifest-v11-surface)

`scripts/tests/` is under `scripts/` (v11-surface). Ran:
```
bash test-fixtures/build.sh --all --clean   # rc=0
git status --short test-fixtures/manifest.txt   # (empty — no diff)
```
The manifest diff is EMPTY (a test-fixture edit under `scripts/tests/` does not
change any built fixture's HEAD SHA). Per the rule, the manifest is staged in
the same commit only when the diff is non-empty — it is empty here, so nothing
to stage. `test-fixtures/build.sh --verify` rc=0 confirms the committed
manifest still matches the rebuilt fixtures.

---

## 6. Verification — FULL CI suite (each pass line quoted)

`python3 scripts/validate-pack.py` → **rc=0**, tail: `PASSED — all checks clean`

`test-fixtures/build.sh --all --clean` → rc=0
`test-fixtures/build.sh --verify` → **rc=0** (e.g. `existing-project-mid-dev OK`, `v11-tracker-on OK`)

Every `tests`-job step (rc=0 each):
```
PASS  scripts/test-detect.sh
PASS  scripts/tests/tracker-provider-test.sh
PASS  scripts/tests/tracker-config-test.sh
PASS  scripts/tests/tracker-init-test.sh
PASS  scripts/tests/tracker-agent-read-test.sh
PASS  scripts/tests/tracker-migrate-forward-test.sh
PASS  scripts/tests/tracker-migrate-reverse-test.sh
PASS  scripts/tests/tracker-migrate-roundtrip-test.sh
PASS  scripts/tests/test-tracker-phase-task.sh
PASS  scripts/tests/test-tracker-links.sh
PASS  scripts/tests/test-tracker-cycle-check.sh
PASS  scripts/tests/tracker-errors-test.sh
PASS  scripts/tests/tracker-config-schema-test.sh
PASS  scripts/tests/recommendation-state-schema-test.sh
PASS  scripts/tests/test-per-entry.sh
PASS  scripts/tests/test-validate-pack-checks-32-33-34.sh
PASS  scripts/tests/test-validate-pack-checks-36-37-38.sh
PASS  scripts/tests/test-validate-pack-check-39.sh
PASS  scripts/tests/test-validate-pack-check-40.sh
PASS  scripts/tests/test-validate-pack-check-41.sh
PASS  scripts/tests/test-validate-pack-check-18.sh
PASS  scripts/tests/test-validate-pack-check-16.sh
PASS  scripts/tests/test-validate-pack-check-19.sh
PASS  scripts/tests/test-validate-pack-check-42.sh
PASS  scripts/tests/test-validate-pack-check-43.sh
PASS  scripts/tests/test-validate-pack-check-44.sh
PASS  scripts/tests/test-validate-pack-check-45.sh
PASS  scripts/tests/test-validate-pack-check-46.sh
PASS  scripts/tests/test-validate-pack-check-removed-doc-advisory.sh
PASS  scripts/tests/tracker-bd129-gh-repo-test.sh
PASS  scripts/tests/tracker-bd130-doctor-wired-test.sh
PASS  scripts/tests/tracker-bd132-race-test.sh
PASS  scripts/tests/tracker-bd133-header-preservation-test.sh
PASS  scripts/tests/tracker-bd134-close-retry-test.sh     <-- the fix
PASS  scripts/tests/recommendation-test.sh
PASS  scripts/tests/pack-help-test.sh
PASS  scripts/tests/test-customization-preserve.sh
PASS  scripts/tests/test-init-project.sh
PASS  scripts/tests/test-migrate-v10-to-v11.sh
PASS  scripts/tests/test-migrate-v10-to-v11-dry-run.sh
PASS  scripts/tests/test-migrate-v10-to-v11-gates.sh
PASS  scripts/tests/test-migrate-v10-to-v11-decompose.sh
PASS  scripts/test-migrator-core.sh
PASS  scripts/test-migrator-manifest.sh
PASS  scripts/test-migrator-capability-translation.sh
PASS  scripts/tests/test-v11-realistic-ot.sh
PASS  scripts/test-migrator-skills.sh
PASS  scripts/test-persona-contracts.sh
PASS  scripts/tests/template-translations-test.sh
PASS  scripts/tests/template-version-test.sh
PASS  scripts/tests/test-issue-forms.sh
```
**51/51 tests PASS + validate-pack PASS + manifest-verify PASS.** Explicit:
`tracker-bd134-close-retry-test.sh` now passes (24 passed, 0 failed).

---

## 7. Files changed inventory

| Path | Change type |
|---|---|
| `scripts/tests/tracker-bd134-close-retry-test.sh` | modified (fixture seed monolith→tree + 2 lib sources) |
| `maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-C5-CIFIX.md` | new (this report) |

`git status --short` at report time: only `M scripts/tests/tracker-bd134-close-retry-test.sh`
(plus this report once written). No staged files. `test-fixtures/manifest.txt`
unchanged. (An unrelated pre-existing untracked file
`RESEARCH-BD-211-GRAMMAR-BLAST-RADIUS.md` is present but NOT mine and left
untouched.)

---

## 8. Plan deviations

None. The fix mirrors the C-5 reconcile pattern exactly; production code
untouched; scope held to `scripts/tests/`.

## 9. New POQs

None.

## 10. Definition-of-Done checklist

| Item | Status |
|---|---|
| CI-RED root-caused | PASS |
| bd134 fixture seeds tree (not monolith), assertions preserved | PASS |
| bd134 passes (24/0) | PASS |
| Same-class sweep done; all class members reconciled | PASS |
| Production C-5 code unchanged (no monolith fallback / revert) | PASS |
| Scope = `scripts/tests/` only (pack-only) | PASS |
| Manifest regen run; diff empty → nothing to stage; verify rc=0 | PASS |
| FULL CI suite run locally + each pass line quoted | PASS |
| No git state change (unstaged) | PASS |

---

## 11. Rules-Applied Verification Block

| Rule | Evidence | Conclusion |
|---|---|---|
| Verify the FULL CI suite | Ran validate-pack (rc=0) + all 51 tests-job steps (51× `PASS`) + manifest verify (rc=0), enumerated from `validate-pack.yml`; each pass line quoted in §6 | COMPLIANT |
| Enumerate ENCODING surfaces | Two greps in §4 (monolith-seed set ∩ pack-forward/reverse-call set); 5 class members tabulated, only bd134 un-reconciled | COMPLIANT |
| Fix the test, not the behavior | `scripts/lib/tracker-migrate-forward.sh` not edited; no monolith fallback added; only `build_repo` seed changed monolith→tree | COMPLIANT |
| Pack/project separation | `git status --short` shows only `scripts/tests/tracker-bd134-close-retry-test.sh`; no `project-template/` path touched | COMPLIANT |
| Manifest regen on v11-surface commits | `bash test-fixtures/build.sh --all --clean` rc=0; `git status --short test-fixtures/manifest.txt` empty (no diff) → not staged per rule; `--verify` rc=0 | COMPLIANT |
| Agents never commit | No `git add`/`commit`/`tag`/`push` run; only read-only `git status`/`rev-parse`; final HEAD == base `e228b38` | COMPLIANT |
| PREFLIGHT + STOP-MEANS-STOP | Emitted single PREFLIGHT line after FULL set passed; no parent stop received | COMPLIANT |
| Rules-Applied Verification Block | This table | COMPLIANT |

### Read-docs verification

| Doc | Evidence read | Conclusion |
|---|---|---|
| `.github/workflows/validate-pack.yml` | Read full file; enumerated tests-job steps in §2 | COMPLIANT |
| `scripts/tests/tracker-bd134-close-retry-test.sh` | Read full file; edited build_repo + lib sources | COMPLIANT |
| `scripts/tests/tracker-migrate-roundtrip-test.sh` | Read full file; mirrored `_setup_test_repo` decompose pattern | COMPLIANT |
| `scripts/lib/tracker-migrate-forward.sh` | Grepped + read read-side (~L498-809); confirmed `tmf_parse_backlog_tree` reads `<repo>/backlog` on pack surface | COMPLIANT |
| `scripts/lib/per-entry/decompose.sh` | Read `per_entry_decompose` signature + pack-backlog anchor regex (L39-158) | COMPLIANT |
| `CLAUDE.md ## Pack memory` | Read in full via project instructions; applied verify-full-ci-suite, enumerate-encoding-surfaces, manifest-regen, agents-never-commit, PREFLIGHT | COMPLIANT |
| `feedback_verify_full_ci_suite.md` (rule in CLAUDE.md) | Applied: ran entire battery incl. integration tests, not a subset | COMPLIANT |
| `feedback_enumerate_encoding_surfaces.md` (rule in CLAUDE.md) | Applied: §4 sweep of all class members | COMPLIANT |
| `feedback_manifest_regen_on_v11_surface.md` (rule in CLAUDE.md) | Applied: §5 manifest build + verify | COMPLIANT |
| `feedback_agent_output_rules_applied_block.md` (rule in CLAUDE.md) | This block | COMPLIANT |
