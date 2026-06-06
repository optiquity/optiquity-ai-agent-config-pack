# PACK-REVIEW-BD-204-C4 — reverse pack branch emits per-entry tree (no monolith)

> **Reviewer:** pack-reviewer (READ-ONLY). **HEAD:** `8572479`. **Branch:** `v11-dev`.
> **Scope reviewed:** uncommitted Commit C-4 — `scripts/lib/tracker-migrate-reverse.sh`
> + 4 test files. **Date:** 2026-06-06.

## Headline: **PASS** (1 LOW finding; 0 BLOCKER / MUST)

The load-bearing no-monolith change is correct. The pack reverse branch emits the
per-entry TREE via `_tmr_emit_pack_tree` (atomic per-file write + line-1 back-pointer
+ `_toc.md` regen), retires the header-snapshot + sidecar on the pack surface, and
points the backup loop at the tree set. The client `else` branch and `_tmr_emit_backlog`
are byte-faithful. The NUL-strip bug fix is real and proven by content-asserting tests.
Full CI battery green. One LOW finding (test-fixture-only backup/toc asymmetry on a
mixed BD+TD surface that cannot occur in production) — surfaced, not blocking.

---

## Check results

### 1. Tree emit correct — PASS
`_tmr_emit_pack_tree` (`tracker-migrate-reverse.sh:712`) writes each entry to
`<backlog_dir>/<pack_id>.md` via `pe_write_atomic` (`:766`), prepends
`pe_backpointer_line "pack-backlog" "$pid"` as line 1 (`:763`), filename keyed on the
`pack_id` marker, then `per_entry_regenerate_toc "pack-backlog" "$backlog_dir"` (`:774`).
The pack branch (`:1252`) calls `_tmr_emit_pack_tree`, NOT `_tmr_emit_backlog`.
Signatures verified against `_lib.sh`: `pe_write_atomic <dest>` reads stdin (`:393`);
`pe_backpointer_line <key> <id>` (`:300`); `per_entry_regenerate_toc <key> <dir>`.
`mkdir -p "$backlog_dir"` runs before any write so `pe_write_atomic`'s dir-exists
precondition (`:397`) holds.

### 2. NUL / tree-actually-written — PASS (fix is real; critical)
The reported bug: `$(...)` strips NUL bytes, so a NUL-delimited render captured via
command substitution silently writes zero files. The fix is genuine: the Python render
writes a NUL-delimited stream to a temp FILE (`rendered_file`, `:732`), and the bash
writer reads it via `while IFS= read -r -d '' record; do ... done < "$rendered_file"`
(`:760-772`) — disk read, not `$(...)`. No command-substitution capture of the
NUL-delimited stream remains. Record split on the first tab (`pid="${record%%$'\t'*}"`)
is safe — pack-ids (`BD-NNN[a-z]*`) contain no tab/NUL, and multi-line bodies survive
because the delimiter is NUL not newline.
**Empirical proof the tree materializes (not exit-0-only):** `tracker-migrate-roundtrip-test.sh`
Group 4 `assert_contains "4.1 tree carries BD-001 entry"` reads `cat .../backlog/BD-*.md`
content; `tracker-migrate-reverse-test.sh` 4.2 asserts `**BD-001 — Add foo to bar**`,
`Status: Open`, `File/Symbol:`, `Description:` in the concatenated tree files. Both PASS
— the assertions inspect file CONTENT, so a zero-write would fail them. A silent
zero-write is excluded.

### 2b/3. Carrier (DP-2) inline; no sidecar — PASS
No `tracker_sidecar_emit` call on the pack branch (it is inside the client `else` only,
`:1278`). `extra_fields` render INLINE in the Python loop (`:752-758`, dict-or-list
defensive handling). Prose sub-blocks (`Description`/`Context`/`Resolution`) ride the
body verbatim (`:744-749`). Roundtrip Group 4 + reverse-test 4.4 assert
`[[ -z "$sidecar" ]]` — no sidecar written. Note: `extra_fields` is absent on entry
objects until the reverse decode populates it (forward-compatible; handled defensively),
so the inline carrier is wired but not yet exercised end-to-end — consistent with the
plan (§2.4.1, carrier landing in C-4/C-5).

### 3b. Header-snapshot retired (pack only) — PASS
Pack branch calls neither `tracker_header_snapshot_capture` nor `_apply` (both inside
the client `else`, `:1266`/`:1270`). `_intro.md`/`_rules.md` untouched. The
`tracker-header-snapshot.sh` module + its Group-1 module-API unit tests in
`tracker-bd133-header-preservation-test.sh` are KEPT (dormant). bd133 Groups 2-4
(pack-surface integration) correctly REMOVED with a retirement-rationale comment.

### 4. CLIENT BRANCH BYTE-UNCHANGED — PASS (key pack-only check)
`_tmr_emit_backlog` **definition** (`:627-698`) is NOT in the diff — body byte-unchanged.
The client `else` branch (`:1261-1285`) preserves the exact original call sequence:
`header_snapshot_capture → _tmr_emit_backlog → header_snapshot_apply → emit_implementation_plan
→ emit_status → emit_changelog → sidecar_emit → 4× mirror_header_strip`. The client path
assignments (`backlog_out`/`changelog_out`, `:1198/:1201`) and the client `_emit_path_list`
(`:1224`, the four monolith paths) are intact. The only delta is wrapping the pre-existing
client logic in an `else` — pure relocation, no logic change. No BLOCKER.

### 5. Backup/restore + BD-132 guard — PASS
Pack `_emit_path_list` = `pe_list_entry_files "pack-backlog" "$backlog_tree_dir"` set +
`plan_out` + `status_out` (`:1219-1222`); client keeps the four-monolith list (`:1224`).
The silent-data-loss guard (`:1161` `n_skipped > 0 && force != 1 → return 1`) fires BEFORE
`_tmr_emit_pack_tree` (`:1252`). bd132 test 1.7 empirically confirms the pre-seeded tree
sentinel (`backlog/BD-001.md`) survives unchanged when the guard fires. BD-132 class NOT
reopened. Backup-key basenames (`BD-NNN.md`, `IMPLEMENTATION-PLAN.md`, `STATUS.md`) do not
collide.

### 6. No-monolith + toc-sync — PASS
`python3 scripts/validate-pack.py` → `PASSED — all checks clean`. Check 32′:
`backlog/ — no monolith present` (green through reverse). Check 33:
`backlog/_toc.md byte-identical (21682 bytes)` (green after the `_toc.md` regen).
Check 43 green.

### 7. POQ-C4-1 out-of-plan test edit — PASS (justified; strengthens coverage)
`tracker-migrate-reverse-test.sh` (not in the plan's C-4 named scope) was edited because
its Group 4/5 pack-surface assertions would fail under the change.
(a) **Required:** old assertions read `pack-ops/BACKLOG.md` + asserted the sidecar — both
now wrong; they would fail.
(b) **No coverage weakening:** the edit ADDS coverage — new negative assertions (4.1 `no
pack BACKLOG/CHANGELOG monolith written`), 4.5 now asserts the per-entry back-pointer on
line 1 (stronger than the old "no mirror header"), 4.7-atomic repoints the restore check
to the tree, and crucially **4.8 preserves the sidecar-module hook contract** by calling
`tracker_sidecar_emit` DIRECTLY (the orchestrator no longer emits it) — so the dormant
module's coverage is NOT lost.
(c) **No smuggled changes:** every hunk is C-4-driven (tree/no-sidecar repoint).
Legitimate enumerate-encoding-surfaces addition.

### 8. Full CI battery — PASS (all quoted)
- `python3 scripts/validate-pack.py` → `PASSED — all checks clean`
- `tracker-migrate-reverse-test.sh` → `Passed: 111 / Failed: 0 / All tests passed.`
- `tracker-migrate-roundtrip-test.sh` → `Passed: 44 / Failed: 0 / All tests passed.`
- `tracker-bd132-race-test.sh` → `Results: 29 passed, 0 failed`
- `tracker-bd133-header-preservation-test.sh` → `Passed: 15 / Failed: 0 / All tests passed.`
- `test-v11-realistic-ot.sh` → `PASS: 33 / FAIL: 0`
- `git diff --name-only` = exactly the 5 script files; NO `project-template/` or
  `supporting-docs/` (pack-only clean).
- Manifest: `bash test-fixtures/build.sh --all --clean` produces no diff (`git status`
  clean on `manifest.txt`) — correctly not staged (the changed `scripts/lib` + `scripts/tests`
  files are not in the manifest's tracked output set). Manifest-regen rule satisfied.

---

## Findings (severity-ranked)

### LOW-1 — `_tmr_emit_pack_tree` writes per-`pack_id` files (incl. `TD-*`) but the backup loop + `_toc.md` regen only track the `pack-backlog` (`BD-*`) regex set
`_tmr_emit_pack_tree` writes one file per `pack_id` UNCONDITIONALLY (`:740-742`), so a
mixed-surface input (the roundtrip/reverse-test fixtures conflate BD+TD) writes
`backlog/TD-NNN.md`. But `pe_list_entry_files "pack-backlog"` matches only
`^BD-[0-9]+[a-z]*\.md$` (verified empirically: lists `BD-001.md`, NOT `TD-010.md`), so on
a `--disable` flip a pre-existing `TD-NNN.md` would NOT be backed up/restored, and
`per_entry_regenerate_toc pack-backlog` excludes TD entries from `_toc.md`.
**Production impact: NONE.** The real pack `/backlog/` is BD-only (`ls backlog/ | grep TD`
→ empty); pack Issues are BD-only, so production emits only `BD-*` files and the set is
fully tracked. This is a latent test-fixture-only asymmetry: the emitter is more permissive
than the backup/toc machinery it feeds. **Recommendation (non-blocking):** consider filtering
`_tmr_emit_pack_tree` to the `pack-backlog` entry regex (skip non-`BD-*` `pack_id`s on the
pack surface) so the emit set, backup set, and `_toc.md` set are provably identical — closes
the latent gap and makes the property robust if a future fixture or surface change introduces
non-BD ids. No live data is at risk today.

No BLOCKER, MUST, or SHOULD findings.

---

## Rules-Applied Verification Block

| Rule (prompt / CLAUDE.md) | Evidence (quoted / measured @ HEAD `8572479`) | Conclusion |
|---|---|---|
| Fail-loud / no monolith (dormant libs kept) | Check 32′ `backlog/ — no monolith present` green through reverse; pack branch never calls `_tmr_emit_backlog`/`tracker_sidecar_emit`/`header_snapshot_*`; `tracker-header-snapshot.sh` + `tracker-sidecar.sh` modules + their unit tests retained (bd133 Group 1 kept; reverse-test 4.8 calls `tracker_sidecar_emit` directly). | COMPLIANT |
| Pack/project separation (client byte-unchanged) | `_tmr_emit_backlog` def (`:627-698`) absent from diff; client `else` (`:1261-1285`) preserves the exact original call sequence + `backlog_out`/`changelog_out` + 4-monolith `_emit_path_list`. Pure relocation. | COMPLIANT |
| Tracker carrier = form+body, no sidecar | No `tracker_sidecar_emit` on pack branch; `extra_fields` rendered inline (`:752-758`); roundtrip Group 4 + reverse-test 4.4 assert `[[ -z "$sidecar" ]]` PASS. | COMPLIANT |
| Enumerate ENCODING surfaces | 4 pack-surface test files updated in lock-step (roundtrip Group 4, bd132 1.7/2.3, bd133 Groups 2-4 retired + Group 1 kept, reverse-test 4.1-4.8); dormant-module unit tests kept; POQ-C4-1 addition justified + coverage-strengthening (negative monolith asserts, back-pointer assert, direct sidecar-module call). | COMPLIANT |
| Empirical evidence | All findings + CI re-run cite `git diff` line anchors + quoted test output at HEAD `8572479`; `pe_list_entry_files` TD-exclusion reproduced live. | COMPLIANT |
| Verify the FULL CI suite | All 6 named tests + validate-pack run and quoted (incl. `test-v11-realistic-ot.sh` banner-pinning → 33/33). | COMPLIANT |
| Rules-Applied Verification Block | This table; every row carries quoted/measured evidence (none empty). | COMPLIANT |

### READ-IN-FULL attestation (this session)
| File | Read proof |
|---|---|
| `PLAN-BD-204.md` § C-4 | Read full (1-552 + 553-655) — C-4 file scope, change recipe steps 1-6, remove-vs-dormant, §4.4 enumerate-encoding lock-step, risks. |
| `git diff` (all 5 files) | Read full via `git diff <file>` per file. |
| `tracker-migrate-reverse.sh` `_tmr_emit_pack_tree` + pack/client branches | Read `:712-776` (emit fn), `:1184-1313` (orchestrator pack + client branches). |
| `per-entry/_lib.sh` | Read `:290-449` (`pe_backpointer_line`/`pe_write_atomic`/`pe_list_entry_files`/`pe_strip_backpointer_stdin`); `:72-161` (`PE_STREAM_KEYS`/regex). |
| `CLAUDE.md` `## Pack memory` | Read in full (session context) — no-mirror SSOT, pack/project-separation, enumerate-encoding-surfaces, bounded-review-fix-cycle, manifest-regen. |
| Coder IMPL-REPORT | NOT read (verified independently per prompt). | 

**No named document was derived rather than read.**

**End of PACK-REVIEW-BD-204-C4.md**
