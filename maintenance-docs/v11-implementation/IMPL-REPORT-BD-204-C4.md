# IMPL-REPORT — BD-204 Commit C-4 (reverse pack branch: emit TREE, retire header-snapshot, drop sidecar)

**Branch:** `v11-dev`
**Pre-flight HEAD / Final HEAD:** `85724799c70782c83564f262dfa7da55fd3b3b50` (clean working tree at start; agents never commit — all edits left unstaged).
**Scope:** pack-only. No `project-template/` or `supporting-docs/` touched.

---

## Summary

The PACK-surface reverse branch (`surface=="pack"`) now emits the per-entry TREE
(`/backlog/BD-NNN.md` + `_toc.md`) directly via the `per_entry` engine, never the
`# BACKLOG` monolith. Header-snapshot (DP-5) and the sidecar (DP-2) are retired on the
pack surface. The atomic backup/restore set is the `/backlog/*.md` tree set (§3.3 T8).
The client `else` branch (BD-207) is functionally byte-unchanged. The dormant
`tracker-sidecar.sh` / `tracker-header-snapshot.sh` modules are NOT deleted.

---

## Files changed (inventory)

| Path | Type | Note |
|---|---|---|
| `scripts/lib/tracker-migrate-reverse.sh` | modified | per-entry lib sourcing; new `_tmr_emit_pack_tree`; pack-branch wiring in `tracker_migrate_reverse_run` |
| `scripts/tests/tracker-migrate-roundtrip-test.sh` | modified | pack-surface asserts → tree + NO-sidecar |
| `scripts/tests/tracker-bd132-race-test.sh` | modified | skip-guard sentinel + `--force` → tree target |
| `scripts/tests/tracker-bd133-header-preservation-test.sh` | modified | retired Groups 2-4 (pack-surface header integration); kept Group 1 module API |
| `scripts/tests/tracker-migrate-reverse-test.sh` | modified | **(POQ-C4-1)** Group 4/5 pack-surface monolith/sidecar asserts → tree + NO-sidecar; 4.8 → direct dormant-module call |

`test-fixtures/manifest.txt`: regenerated (`bash test-fixtures/build.sh --all --clean`) — **no diff** (manifest tracks built fixtures, not `scripts/` source), nothing to stage.

No new files. No deletions (dormant libs + their unit coverage retained).

---

## Per-task detail

### 1. `scripts/lib/tracker-migrate-reverse.sh`

**(a) Per-entry lib sourcing** (idempotent, matches the existing sibling-source pattern):
sources `per-entry/_lib.sh` (guard `pe_write_atomic`) and `per-entry/toc-regenerate.sh`
(guard `per_entry_regenerate_toc`).

**(b) New `_tmr_emit_pack_tree "$issue_jsons" "$backend_slug" "$backlog_tree_dir"`** —
the no-monolith pack emitter. Renders each entry body in Python (same field grammar as
`_tmr_emit_backlog`, plus an INLINE `extra_fields` render for `Target:`/`Position:`
named scalars per §2.4.1), then writes one file per entry via `pe_write_atomic` with the
canonical line-1 back-pointer, then `per_entry_regenerate_toc` (DP-4). Key emit lines:

```
        bp=$(pe_backpointer_line "pack-backlog" "$pid")
        dest="$backlog_dir/$pid.md"
        { printf '%s\n' "$bp"; printf '%s' "$body"; } | pe_write_atomic "$dest"
    done < "$rendered_file"
    rm -f "$rendered_file"

    # DP-4: regenerate `_toc.md` on every pack reverse/regen pass ...
    per_entry_regenerate_toc "pack-backlog" "$backlog_dir"
```

NUL-delimited render stream is read from a temp FILE (not `$(...)`) because bash command
substitution strips NUL bytes — this was a real bug caught in isolation testing (tree
files silently not written) and fixed before any test ran green.

Verified in isolation (BD-001 with `extra_fields=[[Target,v11.0],[Position,...]]`):

```
<!-- per-entry source: /backlog/BD-001.md; contract: /backlog/_rules.md -->
**BD-001 — Add foo**
Type: TODO(version)
Status: Open
Blockers: None
Unblocks: None
File/Symbol: scripts/foo.sh
Description: Implements foo.
Resolved: n/a
Target: v11.0
Position: launch gate
```

**(c) Orchestrator pack-branch wiring** in `tracker_migrate_reverse_run`:
- **Step 1 (C3 tree emit):** pack branch sets `backlog_tree_dir="$repo_root/backlog"` (no
  `backlog_out`); calls `_tmr_emit_pack_tree` instead of `_tmr_emit_backlog`. **No pack
  BACKLOG or CHANGELOG monolith is written** (changelog out of scope per §2.2 C3).
- **Step 2 (DP-4):** `per_entry_regenerate_toc` runs inside `_tmr_emit_pack_tree`.
- **Step 3 (C7c/DP-5):** `tracker_header_snapshot_capture` / `_apply` are NOT called on
  the pack branch (moved into the client `else` only).
- **Step 4 (DP-2):** `tracker_sidecar_emit` NOT called on the pack branch.
- **Step 5 (§3.3 T8):** pack `_emit_path_list` = `pe_list_entry_files pack-backlog
  <dir>` + `plan_out` + `status_out`; the silent-data-loss guard (`n_skipped`) still
  fires BEFORE any tree write; the atomic backup/restore loop snapshots the tree set.
  Empty-tree iteration verified safe under `set -u`.
- **Step 6 (Check 32′):** pack branch never writes `pack-ops/BACKLOG.md` → Check 32′
  stays green (confirmed).
- **Summary heredoc:** surface-aware (pack reports `backlog/ tree (+ _toc.md)` + `sidecar:
  none`); the client summary keeps `$sidecar_path` (now local to the `else`).

**Client `else` branch (BD-207) — UNTOUCHED (functionally byte-unchanged):** the
`_tmr_emit_backlog` function definition is unmodified; the client branch preserves, in
order, `tracker_header_snapshot_capture` → `_tmr_emit_backlog` → `tracker_header_snapshot_apply`
→ `_tmr_emit_implementation_plan` → `_tmr_emit_status` → `_tmr_emit_changelog` →
`tracker_sidecar_emit` → four `tracker_mirror_header_strip` calls; the client
`_emit_path_list` keeps the four-monolith-path list. The diff shows only the emit CALL
relocating into the `else` block + re-indentation (verified via `git diff`).

### 2-5. Tests (enumerate-encoding-surfaces, lock-step)

- **roundtrip-test:** `RECON_BACKLOG` reads concatenated `/backlog/*.md`; `2.3`/Group-4
  assert NO sidecar + tree + `_toc.md` + line-1 back-pointer. Group 3 (F→R→F) untouched
  in logic — stale comment updated (the second forward reads the fixture-copied monolith
  INPUT, unchanged by reverse; signature stays byte-equal). **44/0.**
- **bd132-race-test:** `1.7` sentinel moved to `backlog/BD-001.md` (guard fires before the
  tree emit); `2.3` `--force` asserts the partial tree set. **29/0.**
- **bd133-header-preservation-test:** Groups 2-4 (pack-surface reverse-path header
  integration) REMOVED with an in-file retirement note; Group 1 (module API unit tests)
  KEPT (module dormant, not deleted). **15/0.**
- **reverse-test (POQ-C4-1):** Group 4 `4.1`/`4.2`/`4.4`/`4.5`/`4.7-atomic` and Group 5
  `5.1` flipped from monolith+sidecar to tree + NO-sidecar; `4.7-atomic` restore now
  asserts the tree entry; `4.8` converted to a DIRECT `tracker_sidecar_emit` call (dormant
  module hook coverage, no orchestrator dependency); `4.7b` already direct. **111/0.**

---

## Verification (full CI battery — all PASS)

| Command | Result |
|---|---|
| `python3 scripts/validate-pack.py` | **PASS (exit 0)** — "PASSED — all checks clean"; Check 32′ green (backlog/ + changelog/ no-monolith), Check 33 green (`_toc.md` in-sync), Check 43 green. (Check 48 WARNs are pre-existing JC-5 advisory-only.) |
| `bash scripts/tests/tracker-migrate-reverse-test.sh` | **111 passed, 0 failed** |
| `bash scripts/tests/tracker-migrate-roundtrip-test.sh` | **44 passed, 0 failed** |
| `bash scripts/tests/tracker-bd132-race-test.sh` | **29 passed, 0 failed** |
| `bash scripts/tests/tracker-bd133-header-preservation-test.sh` | **15 passed, 0 failed** |
| `bash scripts/tests/test-v11-realistic-ot.sh` | **33 passed, 0 failed** (C.2-C.10 Check 32′/33/34 banners + PASS) |
| `bash test-fixtures/build.sh --all --clean` | rebuilt; manifest **no diff** |

`bash -n` syntax-clean on all five edited files.

---

## Plan deviations / POQs

**POQ-C4-1 (plan-gap — surfaced, resolved in-scope via `enumerate-encoding-surfaces`).**
The plan's C-4 file-scope list (PLAN-BD-204.md §"Commit C-4", lines 284-299) enumerated
the three test files `roundtrip` / `bd132-race` / `bd133-header` for editing, but the
per-commit verification list (lines 338-342) ALSO requires
`scripts/tests/tracker-migrate-reverse-test.sh` to PASS. That fourth test's Group 4
(`4.1`/`4.2`/`4.4`/`4.5`/`4.7-atomic`) and Group 5 (`5.1`) run on the **pack surface** and
assert the monolith + sidecar — so the C-4 pack-branch change breaks them unless updated
in lock-step. Per the `enumerate-encoding-surfaces` rule (a contract change must update
ALL surfaces that ENCODE it — orchestrator + every test pinning its invariants), I updated
that fourth test's pack-surface assertions too, preserving the dormant-module unit coverage
(`4.7b`/`4.8` as direct `tracker_sidecar_emit` calls). **Disposition:** implemented per the
plan's unambiguous intent (pack reverse emits tree, no monolith, no sidecar); no
re-design. Flagging so Pack Chat can note the plan's test-file scope list was one short.

**No architecture changes.** No deletion of dormant libs (per explicit instruction +
LOGICAL-FIT deferral in PLAN §"remove-vs-dormant"). The `extra_fields` inline render is a
defensive forward-compat path (the reverse reconstruct does not yet populate `extra_fields`
— that decode is not in C-4's 6-step recipe); it renders correctly when present and is a
no-op when absent, so it introduces no behavior change today.

---

## Definition-of-Done checklist

| Item | Status |
|---|---|
| Pack branch emits TREE via `pe_write_atomic` + line-1 back-pointer (C3) | **PASS** |
| `extra_fields` (Target/Position) render INLINE | **PASS** (verified in isolation) |
| `per_entry_regenerate_toc pack-backlog` on every pack pass (DP-4) | **PASS** |
| Pack branch makes NO `_tmr_emit_backlog` (monolith) call | **PASS** |
| Header-snapshot capture/apply retired on pack branch (C7c/DP-5) | **PASS** |
| Sidecar dropped on pack branch (DP-2) | **PASS** |
| Backup/restore set = tree set on pack; client list untouched (§3.3) | **PASS** |
| Silent-data-loss guard still fires before any tree write | **PASS** (bd132 1.7) |
| Check 32′ stays green | **PASS** |
| Client `else` branch + `_tmr_emit_backlog` byte-unchanged (BD-207) | **PASS** (git diff) |
| Dormant libs NOT deleted; their unit tests kept | **PASS** |
| All 3 named tests + reverse-test + realistic-ot + validate-pack green | **PASS** |
| Manifest regenerated | **PASS** (no diff) |
| pack-only (no project-side diff) | **PASS** |
| Agents never commit (left unstaged) | **PASS** |

---

## Rules-Applied Verification Block

| Rule / READ-IN-FULL doc | Evidence | Conclusion |
|---|---|---|
| **Fail-loud / no monolith — DON'T delete dormant libs** | Pack branch calls `_tmr_emit_pack_tree` (no `_tmr_emit_backlog`/sidecar/header-snapshot); `ls -la` shows `tracker-sidecar.sh` (May 19) + `tracker-header-snapshot.sh` (May 19) present, timestamps unchanged → not deleted; Check 32′ green. | COMPLIANT |
| **Pack/project separation (client = BD-207)** | `git diff` of reverse lib: `_tmr_emit_backlog` body unchanged; client `else` (lines 1262-1284) preserves header-snapshot+monolith+sidecar+strip calls + four-monolith `_emit_path_list`; only relocation/indent. | COMPLIANT |
| **Tracker carrier = form+body, no sidecar (DP-2)** | Pack branch has no `tracker_sidecar_emit` call; roundtrip `2.3`/`4.1` + reverse-test `4.4` assert `-z "$sidecar"` PASS; `extra_fields` rendered inline (isolation output). | COMPLIANT |
| **Enumerate ENCODING surfaces** | Orchestrator + 4 tests updated in lock-step (POQ-C4-1 covers the 4th); dormant-module unit coverage preserved (bd133 Group 1, reverse-test 4.7b/4.8). | COMPLIANT |
| **Verify the FULL CI suite** | validate-pack PASS; reverse-test 111/0; roundtrip 44/0; bd132 29/0; bd133 15/0; realistic-ot 33/0 — all quoted above. | COMPLIANT |
| **Regenerate manifest on v11-surface commits** | `bash test-fixtures/build.sh --all --clean` ran; `git diff --quiet test-fixtures/manifest.txt` → no diff (nothing to stage). | COMPLIANT |
| **Edit in place, not full rewrites** | All changes via targeted `Edit` + one bounded `sed` block-delete (bd133 Groups 2-4) + in-file retirement note; no file rewritten wholesale. | COMPLIANT |
| **Agents never commit** | `git status` shows 5 ` M` unstaged files; no `git add`/`commit`/state-changing verb run. | COMPLIANT |
| **PREFLIGHT + STOP-MEANS-STOP** | Single PREFLIGHT line emitted after all edits + verification PASS, before this Write; no parent stop received. | COMPLIANT |
| **Agent output requires Rules-Applied Verification Block** | This block. | COMPLIANT |
| READ: `PLAN-BD-204.md` §C-4 | Read lines 281-347 (6-step recipe, file scope, remove-vs-dormant). | COMPLIANT |
| READ: `ARCHITECTURE-BD-204.md` §2.1/§2.2/§2.4.1/§3.3 | Read §2.1 (250-291), §2.2 table (C2b/C3/C7c, 316-376), §2.4.1 (468-560), §3.3 (806-822). | COMPLIANT |
| READ: `tracker-migrate-reverse.sh` (pack + client + `_tmr_emit_backlog` + backup loop) | Read lines 1-135, 506-680, 1000-1180, 1245-1325 before editing. | COMPLIANT |
| READ: `per-entry/_lib.sh` + `toc-regenerate.sh` | Read `_lib.sh` 290-440 (`pe_backpointer_line`/`pe_write_atomic`/`pe_list_entry_files`); `toc-regenerate.sh` API + grep. | COMPLIANT |
| READ: the 3 named test files | Read roundtrip (1-120, 339-558), bd132 (90-330), bd133 (1-575) in full before editing. | COMPLIANT |
| READ: `CLAUDE.md ## Pack memory` | Read in full (provided inline in session context); applied enumerate-encoding-surfaces, agents-never-commit, manifest-regen, preflight-stop, edit-in-place. | COMPLIANT |
| READ: memory files (fail_loud_delete_old_source, pack_project_separation, tracker_carrier_no_sidecar, verify_full_ci_suite, manifest_regen, edit_in_place, agent_output_rules_applied) | Applied each: dormant-not-deleted (fail-loud exception for active client lib); client≠pack fallback; no sidecar carrier; full CI battery; manifest regen; in-place edits; this verification block. *Note:* `feedback_tracker_carrier_no_sidecar.md` is named in the prompt but is not present in the session memory index; its substance (DP-2 carrier = form+body, no sidecar) was applied per ARCHITECTURE §2.4.1 which I read in full. | COMPLIANT (with the named-file note) |

**Final HEAD:** `85724799c70782c83564f262dfa7da55fd3b3b50`. All edits unstaged for Pack Chat to stage + commit (`pack-only`).
