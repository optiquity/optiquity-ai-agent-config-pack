# IMPL-REPORT — BD-204 Commit C-6 (Mode-3 read surfaces repoint + POQ-1)

- **Branch:** `v11-dev`
- **Base HEAD:** `4ab4a08a4bf908b7d0a4fa8e9ecab7e3a65e2f38`
- **Final HEAD (worktree):** `4ab4a08a4bf908b7d0a4fa8e9ecab7e3a65e2f38` (no commit — agents never commit)
- **Scope:** `pack-only`. Edits confined to the PACK-surface branches of three libs + their two tests.

## Summary

C-6 repoints the Mode-3 READ surfaces (agent-read + doctor) off the DELETED pack
monolith `pack-ops/BACKLOG.md` (BD-203 no-mirror SSOT) onto the per-entry `/backlog/`
tree, AND retires the `--mirror-only` short-circuit's pack branch (POQ-1, surfaced by
the C-5 review F-2). The project-side (`TD-*` / `phase-*` / client `else`) branches are
byte-unchanged in runtime behavior (BD-207 owns the client tree repoint).

After C-6, NO pack-surface code path reads or regenerates `pack-ops/BACKLOG.md` — not
agent-read, not doctor, not the `--mirror-only` short-circuit.

## Files changed (inventory)

| Path | Type | Branch touched |
|---|---|---|
| `scripts/lib/tracker-agent-read.sh` | modified | PACK fall-through (BD-* + `*)` default) |
| `scripts/lib/tracker-doctor.sh` | modified | PACK-surface freshness check (d) |
| `scripts/lib/tracker-migrate-forward.sh` | modified | `--mirror-only` PACK branch (POQ-1) |
| `scripts/tests/tracker-agent-read-test.sh` | modified | Group 2 + 5.7 + header |
| `scripts/tests/tracker-bd130-doctor-wired-test.sh` | modified | new Group 8 |
| `scripts/tests/tracker-migrate-forward-test.sh` | modified | Test 4.5 |

Diffstat: `6 files changed, 246 insertions(+), 88 deletions(-)`. Manifest diff EMPTY (no
inventory change) — nothing to stage.

---

## Part A.1 — Agent-read (C4 REPOINT)

`scripts/lib/tracker-agent-read.sh`. The per-entry-tree prefer-branch (lines ~211-245)
already reads `/backlog/BD-NNN.md` DIRECTLY for `BD-*` (the file IS the entry). The
EDIT is to the *fall-through* (formerly the monolith mirror selection): the `BD-*` and
the `*)` unknown-prefix branches that pointed at `$repo_root/pack-ops/BACKLOG.md` now
FAIL LOUD instead of reading the deleted monolith. The `TD-*` / `phase-*` (project)
mirror-path selection is preserved.

New fall-through (quoted):

```sh
    case "$pack_id" in
        BD-*|TD-*|phase-*) : ;;
        *)
            tracker_error_emit "not-found" \
                "agent_read: $pack_id not found in pack per-entry tree at $repo_root/backlog (no monolith fallback — BD-203 no-mirror SSOT)"
            return 1
            ;;
    esac
    if [[ "$pack_id" == BD-* ]]; then
        tracker_error_emit "not-found" \
            "agent_read: $pack_id not found in pack per-entry tree at $repo_root/backlog/$pack_id.md (no monolith fallback — BD-203 no-mirror SSOT)"
        return 1
    fi
    local mirror_path=""
    case "$pack_id" in
        TD-*)    mirror_path="$repo_root/docs/project/BACKLOG.md" ;;
        phase-*) mirror_path="$repo_root/docs/project/IMPLEMENTATION-PLAN.md" ;;
    esac
    if [[ ! -f "$mirror_path" ]]; then
```

Behaviour: BD-* resolves only via the per-entry tree prefer-branch; when absent it
fails loud. `*)` fails loud. `TD-*` / `phase-*` retain their project-mirror fallback
unchanged.

## Part A.2 — Doctor (C7b REPOINT)

`scripts/lib/tracker-doctor.sh` check (d). The pack-surface mirror-freshness check
(formerly `backlog_path="$repo_root/pack-ops/BACKLOG.md"` + mtime/`<!--` header test)
now maps to the tree's regen-state via `/backlog/_toc.md` mtime vs
`migration.last_forward_run`. The project surface moved verbatim into the `*)` branch.

New `pack)` branch (quoted):

```sh
        pack)
            local toc_path
            toc_path="$repo_root/backlog/_toc.md"
            if [[ -f "$toc_path" ]]; then
                local toc_mtime last_forward
                toc_mtime=$(date -r "$toc_path" -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo "")
                if [[ -f "$cfg_path" ]]; then
                    last_forward=$(tracker_config_get "$cfg_path" "migration.last_forward_run" 2>/dev/null || echo "")
                fi
                if [[ -n "$toc_mtime" && -n "$last_forward" ]]; then
                    if [[ "$toc_mtime" > "$last_forward" || "$toc_mtime" == "$last_forward" ]]; then
                        echo "  [OK]   /backlog tree regen index is current (_toc.md mtime=$toc_mtime, last_forward=$last_forward)"
                    else
                        echo "  [WARN] /backlog tree regen index is older than last_forward_run  → Run: pack tracker init --forward"
                        n_warn=$((n_warn + 1))
                    fi
                else
                    echo "  [OK]   /backlog per-entry tree present (_toc.md index)"
                fi
            else
                echo "  [INFO] /backlog/_toc.md absent (flat-file pre-regen or scratch tree)"
            fi
            ;;
```

The `*)` branch retains the identical `docs/project/BACKLOG.md` (+ legacy
`$repo_root/BACKLOG.md`) selection, mirror-header test, mtime comparison, and
OK/WARN/INFO emissions — relocated + re-indented only.

## Part B — POQ-1: `--mirror-only` pack branch fail-loud

`scripts/lib/tracker-migrate-forward.sh`, the `if [[ "$mirror_only" == "1" ]]`
short-circuit. The pack branch no longer sets `backlog_path=pack-ops/BACKLOG.md` and no
longer calls `_tmf_regen_mirror`; it emits a typed `validation` error and `return 1`.
The client `else` branch is byte-unchanged.

New pack branch (quoted):

```sh
        if [[ "$surface" == "pack" ]]; then
            tracker_error_emit "validation" \
                "forward --mirror-only: mirror-rebuild is not applicable on the no-mirror pack surface — the /backlog per-entry tree is the SSOT (regenerated by the reverse/regen path in tracker mode, NOT a forward mirror-rebuild). BD-203 deleted pack-ops/BACKLOG.md."
            return 1
        fi
        local backend_slug backlog_path
        backend_slug=$(tracker_repo_slug "$cfg_path" 2>/dev/null || echo "unknown")
        backlog_path="$repo_root/BACKLOG.md"
        if [[ ! -f "$backlog_path" ]]; then
            tracker_error_emit "not-found" \
                "forward --mirror-only: BACKLOG.md not found at $backlog_path"
            return 1
        fi
        _tmf_regen_mirror "$backlog_path" "$backend_slug"
        echo "forward --mirror-only: BACKLOG.md mirror header refreshed"
        return 0
```

(The retained `_tmf_regen_mirror` call is now reachable ONLY via the client `else`
path; `backlog_path` resolves to `$repo_root/BACKLOG.md`, never `pack-ops/`.)

## Client / `else` / TD branches byte-unchanged (confirmation)

- **agent-read:** `TD-*` → `docs/project/BACKLOG.md`, `phase-*` →
  `docs/project/IMPLEMENTATION-PLAN.md` selection + the downstream `python3` mirror
  parse are untouched. `git diff` additions touching `TD-`/`phase-`/`docs/project` are
  comments + the diverting `case` only.
- **doctor:** the `*)` project branch logic is identical (the four
  `OK/WARN/INFO  BACKLOG.md ...` echo lines reappear verbatim under `*)`).
- **forward `--mirror-only`:** the `else` branch (`backlog_path="$repo_root/BACKLOG.md"`
  + `_tmf_regen_mirror` + "mirror header refreshed") is unchanged.
- **forward Step-10 (`:1294`):** already wrapped `if [[ "$surface" != "pack" ]]` by
  C-5 — not touched by C-6.

## Test updates (enumerate-encoding-surfaces lock-step)

- **`tracker-agent-read-test.sh`:** `_setup_flat_repo` now seeds pack `BD-*` into the
  `/backlog/` per-entry tree (with line-1 back-pointers) instead of
  `pack-ops/BACKLOG.md`. Group 2: 2.1 asserts `Source: flat-file (per-entry:` +
  `backlog/BD-001.md` + back-pointer stripped; 2.7 asserts BD-* fails loud
  (`no monolith fallback`) AND that a planted stale `pack-ops/BACKLOG.md` sentinel is
  NEVER read. 5.7 asserts the `*)` unknown-prefix path fails loud (`no monolith
  fallback`). TD-*/phase-* groups unchanged. → **57 passed, 0 failed**.
- **`tracker-bd130-doctor-wired-test.sh`:** new **Group 8** sources the lib + deps and
  runs `tracker_doctor_run` against a pack fixture holding the `/backlog/` tree + a
  stale `pack-ops/BACKLOG.md` sentinel; asserts the doctor reports the `/backlog` tree
  (8.1) and does NOT emit any `BACKLOG.md mirror` line / header (8.2, 8.3). →
  **24 passed, 0 failed**.
- **`tracker-migrate-forward-test.sh`:** Test 4.5 rewritten — pack-surface
  `--mirror-only` now seeds the tree (no monolith), asserts non-zero rc + `ERROR:
  validation` + `not applicable on the no-mirror pack surface` + NO
  `pack-ops/BACKLOG.md` written + 0 gh calls + no id-map. → **145 passed, 0 failed**.

Suite-wide grep for other pins of the retired pack agent-read/doctor/`--mirror-only`
monolith behaviour found only Test 4.5 (forward) — updated in lockstep above. The
remaining `pack-ops/BACKLOG.md` occurrences in other tests
(roundtrip/reverse/bd133/bd134 etc.) assert `! -f` (no-monolith), which is the desired
state and stays green.

## Grep proof

```
$ grep -n 'pack-ops/BACKLOG.md' scripts/lib/tracker-agent-read.sh scripts/lib/tracker-doctor.sh
scripts/lib/tracker-agent-read.sh:255:    # BD-204 C-6 (C4 REPOINT): the pack monolith `pack-ops/BACKLOG.md`
scripts/lib/tracker-doctor.sh:116:    # BD-204 C-6 (C7b REPOINT): the pack monolith `pack-ops/BACKLOG.md`
```

Both remaining hits are COMMENTS (documenting the retirement); no pack-surface READ of
the monolith remains.

```
$ grep -n '_tmf_regen_mirror\|pack-ops/BACKLOG.md' scripts/lib/tracker-migrate-forward.sh
767:        # `pack-ops/BACKLOG.md` is DELETED (BD-203 no-mirror SSOT). On    <- comment
779:        ... BD-203 deleted pack-ops/BACKLOG.md."                          <- error-message string
790:        _tmf_regen_mirror "$backlog_path" "$backend_slug"                 <- CLIENT else branch (backlog_path=$repo_root/BACKLOG.md)
1295:        if ! _tmf_regen_mirror "$backlog_path" "$backend_slug" ...       <- Step-10, already wrapped `if surface != pack` (C-5)
1425:    # BD-175: pack-side BACKLOG canonical at pack-ops/BACKLOG.md.        <- inside _tmf_regen_mirror helper (client path)
1428:        mirror_path="$repo_root/pack-ops/BACKLOG.md"                     <- helper internal (only reached via client branch)
1524:_tmf_regen_mirror() {                                                    <- helper definition
```

The `--mirror-only` PACK branch (`:769-783`) no longer calls `_tmf_regen_mirror` and no
longer references `pack-ops/BACKLOG.md` as a path — only the typed error string.

## no-project-regression

```
$ bash scripts/tests/test-v11-realistic-ot.sh   →  All v11-realistic-ot integration tests PASSED (33/33).
$ git diff --name-only | grep -E '^(project-template|supporting-docs)/'   →  (empty; CLEAN)
```

## pack-only

```
$ git diff --name-only
scripts/lib/tracker-agent-read.sh
scripts/lib/tracker-doctor.sh
scripts/lib/tracker-migrate-forward.sh
scripts/tests/tracker-agent-read-test.sh
scripts/tests/tracker-bd130-doctor-wired-test.sh
scripts/tests/tracker-migrate-forward-test.sh
```

No `project-template/` or `supporting-docs/` paths. Manifest diff empty → not staged.

## Manifest

```
$ bash test-fixtures/build.sh --all --clean     →  rc=0
$ git status --short test-fixtures/manifest.txt  →  (empty)
```

Manifest diff non-existent (lib/test content edits add no files) → nothing to stage per
`regenerate-manifest-v11-surface`.

## FULL CI aggregate

```
$ python3 scripts/validate-pack.py
... PASSED — all checks clean   (Check 32′ green; 14 pre-existing JC-5 removed-doc
                                 advisory WARNs, exit-code-unaffected)

Entire CI tests set (51 scripts enumerated from .github/workflows/validate-pack.yml):
AGGREGATE: 51 passed, 0 failed
FAILED_LIST: (empty)
```

In-scope per-test counts: agent-read 57/0; doctor-wired 24/0; forward 145/0;
realistic-ot 33/33.

## Plan deviations

None. Implemented exactly the plan's C-6 recipe (A1 agent-read repoint, A2 doctor
repoint) + the C5-review-anchored POQ-1 (Part B), all `pack-only`.

## New POQs introduced

None.

## Definition-of-Done checklist

| Item | Result |
|---|---|
| Agent-read pack BD-* + `*)` read the tree / fail loud (no monolith) | PASS |
| Doctor pack-surface freshness maps to tree regen-state | PASS |
| `--mirror-only` pack branch fails loud (no `_tmf_regen_mirror`, no monolith) | PASS |
| TD-*/phase-*/client `else` branches byte-unchanged | PASS |
| Tests updated in lockstep (agent-read + doctor + forward) | PASS |
| `validate-pack.py` green (Check 32′ green) | PASS |
| Full CI suite green (51/51) | PASS |
| realistic-ot green (33/33) | PASS |
| Grep proof: no pack-surface monolith read/regen | PASS |
| pack-only scope (no project-template/supporting-docs) | PASS |
| Manifest regen run (empty diff → no stage) | PASS |
| No commit / no git state change | PASS |

---

## Rules-Applied Verification Block

### Rules in force

| Rule | Evidence (quoted) | Conclusion |
|---|---|---|
| Fail-loud / no monolith | `grep pack-ops/BACKLOG.md tracker-agent-read.sh tracker-doctor.sh` → only 2 COMMENT hits (lines 255, 116); migrate-forward pack `--mirror-only` emits `ERROR: validation` "not applicable on the no-mirror pack surface" + `return 1`; agent-read BD-*/`*)` emit `not-found` "no monolith fallback"; `validate-pack` "PASSED — all checks clean" (Check 32′ green) | COMPLIANT |
| Pack/project separation | `git diff --name-only` = 6 scripts paths only; `grep -E '^(project-template\|supporting-docs)/'` empty; doctor `*)` branch echoes reappear verbatim; agent-read `TD-*`/`phase-*` mirror_path selection retained; realistic-ot 33/33 | COMPLIANT |
| Enumerate ENCODING surfaces | agent-read + doctor + `--mirror-only` each updated WITH its test (agent-read-test 57/0; bd130-doctor-wired Group 8 24/0; forward-test 4.5 145/0); suite-grep found only forward 4.5 as additional pin → updated | COMPLIANT |
| Verify the FULL CI suite | enumerated 51 scripts from `.github/workflows/validate-pack.yml`; `AGGREGATE: 51 passed, 0 failed`; `validate-pack` PASSED; realistic-ot 33/33 quoted | COMPLIANT |
| Manifest regen on v11-surface commits | `bash test-fixtures/build.sh --all --clean` rc=0; `git status --short test-fixtures/manifest.txt` empty → no stage needed | COMPLIANT |
| Agents never commit / PREFLIGHT + STOP-MEANS-STOP | No `git add/commit/push/tag`; only read-only git verbs run; PREFLIGHT line emitted after full set PASS; HEAD `4ab4a08` unchanged | COMPLIANT |
| Rules-Applied Verification Block | This block present with per-rule + per-doc evidence | COMPLIANT |

### Read-doc attestation

| Doc | Evidence | Conclusion |
|---|---|---|
| `PLAN-BD-204.md` § Commit C-6 | Read lines 385-410 (file-scope + recipe C4·C7b + verification + ordering) | COMPLIANT |
| `ARCHITECTURE-BD-204.md` (C4/C7b) | Read grep of C4 (`:320`) + C7b (`:321`) repoint rows + census `:299-305` | COMPLIANT |
| `PACK-REVIEW-BD-204-C5.md` (F-2/POQ-1) | Read lines 108-128 (POQ-1 evidence `:765-782`, fold-into-C-6 recommendation) | COMPLIANT |
| `tracker-agent-read.sh` | Read full 1-321 (prefer-branch vs fall-through; BD-*/TD-*/phase-* branches) | COMPLIANT |
| `tracker-doctor.sh` | Read full 1-273 (check (d) pack vs `*)`) | COMPLIANT |
| `tracker-migrate-forward.sh` | Read `:723-812` (mirror-only + read dispatch) + `:1283-1302` (Step-10 wrap) | COMPLIANT |
| `tracker-agent-read-test.sh` | Read full 1-508 (Groups 1-5) | COMPLIANT |
| `tracker-bd130-doctor-wired-test.sh` | Read full 1-187 (Groups 1-7) | COMPLIANT |
| `tracker-migrate-forward-test.sh` | Read `:705-764` (Test 4.5 region) + grep of mirror-only sites | COMPLIANT |
| `.github/workflows/*.yml` | Read/grepped `validate-pack.yml` → 51-script CI set enumerated | COMPLIANT |
| `CLAUDE.md ## Pack memory` | Provided in full via system context; applied workflow + repo-convention rules | COMPLIANT |
| `feedback_fail_loud_delete_old_source.md` | Applied: pack monolith reads removed → fail-loud, no mirror rebuilt | COMPLIANT |
| `feedback_pack_project_separation_of_concerns.md` | Applied: pack vs project branches treated as separate artifacts; project untouched | COMPLIANT |
| `feedback_verify_full_ci_suite.md` | Applied: ran all 51 CI scripts incl. realistic-ot, not validate-pack alone | COMPLIANT |
| `feedback_manifest_regen_on_v11_surface.md` | Applied: build.sh --all --clean run; empty diff → no stage | COMPLIANT |
| `feedback_agent_output_rules_applied_block.md` | Applied: this verification block | COMPLIANT |
