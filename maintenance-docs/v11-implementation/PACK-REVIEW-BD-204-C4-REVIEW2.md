# PACK-REVIEW-BD-204-C4-REVIEW2 — post-fix confirmation (review-2)

> **Agent:** pack-reviewer. **Mode:** READ-ONLY (no edits, no git verbs).
> **Commit under review:** BD-204 C-4 (reverse pack branch emits per-entry TREE; retire header-snapshot + sidecar) + the LOW-1 fix.
> **HEAD:** `85724799c70782c83564f262dfa7da55fd3b3b50` (`git rev-parse HEAD`). **Branch:** `v11-dev`. **Date:** 2026-06-06.
> **Scope verified against:** PLAN-BD-204 §C-4, ARCHITECTURE-BD-204 §2.1/§2.2/§2.4.1/§3.3 (per prompt). Verified independently of the coder IMPL-REPORTs and the review-1 report (not read).

## Headline: **PASS**

The LOW-1 fix is correct and single-source. Emit set == backup set == `_toc.md` set by construction (all three driven by `pe_entry_regex_for_stream "pack-backlog"`). Coverage is preserved — the TD-040 Blockers round-trip was relocated to a genuine reconstruction-layer exercise, not downgraded. The rest of C-4 is undisturbed. Full CI battery green. No findings.

---

## Check 1 — Fix correct + single-source: **PASS**

The emit loop in `_tmr_emit_pack_tree` filters `pack_id`s to the pack-backlog entry regex obtained from the engine's OWN source — no hardcoded copy.

Evidence (`git diff` `scripts/lib/tracker-migrate-reverse.sh`, the emit-filter block):
```
pack_entry_regex=$(pe_entry_regex_for_stream "pack-backlog") \
    || pe_die "unknown stream key: pack-backlog"
...
if ! printf '%s\n' "$pid.md" | grep -E -q "$pack_entry_regex"; then
    continue
fi
```

Single-source confirmed against `scripts/lib/per-entry/_lib.sh`:
- `pe_entry_regex_for_stream()` (`_lib.sh:152`) is the sole regex provider (`pe__stream_attr "$1" entry-regex`).
- `pe_list_entry_files()` (the **backup set**, `_lib.sh:426`) calls the SAME function (`_lib.sh:430`: `regex=$(pe_entry_regex_for_stream "$key")`) and matches the SAME way (`_lib.sh:445`: `printf '%s\n' "$base" | grep -E -q "$regex"`, where `base` is the `<id>.md` basename).
- `per_entry_regenerate_toc "pack-backlog"` (the **`_toc.md` set**) keys off the same stream-attr table.

The emit-loop matcher (`printf '%s\n' "$pid.md" | grep -E -q "$pack_entry_regex"`) is byte-for-byte the same matching shape as `pe_list_entry_files`'s (`$pid.md` ↔ `$base`). Therefore emit == backup == `_toc.md` by construction for any input. A divergent second regex copy would re-introduce the latent asymmetry; none exists.

`pe_backpointer_line "pack-backlog" "$pid"` is invoked with the stream KEY (its `$1`, `_lib.sh:300-301`), correct. (Minor note: the `_lib.sh` header comment at `:40` labels the first arg `<stream_dir>` while the function body treats it as `key`; that is a pre-existing doc-comment inaccuracy in a file NOT touched by this commit — out of scope, NOT a finding for C-4.)

## Check 2 — Coverage preserved (test relocation scrutinized): **PASS**

**TD-040 Blockers round-trip (BD-108 F5 / BD-111)** — NOT downgraded. The old assertion read `RECON_BACKLOG` (the pack-tree concat) for `TD-040` + grepped its `Blockers:` line. Post-LOW-1, TD-040 is correctly NOT on the pack tree, so the assertion was relocated to the **reconstruction layer** (`tracker-migrate-roundtrip-test.sh` 2.2c, diff lines 1056-1101):
- `tracker_provider_gh_get "$TD040_NUM"` → `tracker_migrate_reverse_reconstruct "$TD040_ISSUE" "$TD040_MAPPING"` (both real public functions: `tracker-provider-gh.sh:234`, `tracker-migrate-reverse.sh:523`; mapping via `tmf_mapping_load`, `tracker-migrate-forward.sh:163`), with the fake-gh re-exported on PATH for the first-class-edge fetch.
- Asserts `pack_id == "TD-040"` (not dropped/misclassified) AND `blockers` (`jq -r '.blockers // [] | join(",")'`) contains `TD-010`. This is the SAME decoder the orchestrator calls per issue — a meaningful exercise, not a no-op or removal.

**TD decode coverage retained.** `tracker-migrate-reverse-test.sh` Group 1 still asserts: status decode `1.1 status:deferred → Deferred` (line 136) and type decode `_tmr_decode_type "TD-010" ...` → `TODO(scope)` / `TODO(dependency)` / `KNOWN GAP(critical)` (lines 159-163). TD survival through forward→state→reverse is still proven by the reconstruction-count assertion ("reconstructed 4 BACKLOG entries").

**Negative asserts are genuine.** Across all three corrected tests the negative asserts test the NEW BD-only behavior:
- `[[ ! -f "$REPO/backlog/TD-010.md" ]]` / `TD-040.md` (filesystem-level: the TD entry was NOT emitted to the tree).
- `assert_not_contains ... "**TD-010 — Document quux**"` (content-level on the concatenated tree). The new `assert_not_contains` helper (reverse-test diff line 810) has correct polarity (passes when needle absent).

No coverage was weakened; the changes tighten assertions (filesystem-presence + content-absence) over the prior single positive grep.

## Check 3 — Rest of C-4 undisturbed: **PASS**

- **Client `else` branch byte-unchanged in behavior.** `_tmr_emit_backlog` is only *relocated* into the `else` branch, called identically (`_tmr_emit_backlog "$issue_jsons" "$backend_slug" "$backlog_out"`); its function body is not edited. The client branch retains `tracker_header_snapshot_capture`/`_apply`, `tracker_sidecar_emit`, `_tmr_emit_changelog`, and the 4-monolith `tracker_mirror_header_strip` set.
- **NUL read-loop intact.** `while IFS= read -r -d '' record; do ... done < "$rendered_file"` (`tracker-migrate-reverse.sh:805`), reading from the temp file (command-substitution-strips-NUL hazard avoided, comment :730).
- **Header-snapshot/sidecar retirement** is pack-branch-only (DP-5/DP-2); module unit tests retained (bd133 Group 1 kept; sidecar direct-API tests relocated to `tracker_sidecar_emit` direct calls in reverse-test 4.8 and roundtrip 4.x). Modules left dormant, not deleted — consistent with the plan's LOGICAL-FIT deferral.
- **Backup/restore→tree change** (§3.3 T8): pack branch sets `_emit_path_list` from `pe_list_entry_files "pack-backlog" "$backlog_tree_dir"`; client branch keeps the 4-monolith list. Atomicity gate restore verified by reverse-test 4.7-atomic (now plants/restores `backlog/BD-001.md`).
- The fix touched ONLY the emit-loop filter + the affected test assertions (negative asserts + the 2.2c relocation). No unrelated edits.

## Check 4 — Pack-only + scope: **PASS**

`git diff --name-only` (HEAD `8572479`):
```
scripts/lib/tracker-migrate-reverse.sh
scripts/tests/tracker-bd132-race-test.sh
scripts/tests/tracker-bd133-header-preservation-test.sh
scripts/tests/tracker-migrate-reverse-test.sh
scripts/tests/tracker-migrate-roundtrip-test.sh
```
`git diff --name-only | grep -c project-template/` → `0`. No project-side, no `supporting-docs/`. The `bd132`/`bd133` files carry the C-4 baseline edits (tree-emit sentinel + Groups 2-4 retirement) — consistent with the tree/retire change.

**Manifest:** `bash test-fixtures/build.sh --all --clean` → `git status --short test-fixtures/manifest.txt` produced NO output (manifest diff empty); no manifest regen owed for this commit. (Per regenerate-manifest-v11-surface, regen is required only when the manifest diff is non-empty.)

## Check 5 — Full CI battery (run at HEAD `8572479`): **ALL GREEN**

| Suite | Result |
|---|---|
| `python3 scripts/validate-pack.py` | `PASSED — all checks clean`; exit 0. Check 32′ (no pack monolith), Check 33 (`_toc.md` in-sync), Check 43 green. (Check 48 emits 14 advisory WARNs — pre-existing JC-5 removed-doc citations, NOT a gate failure, exit code unaffected.) |
| `tracker-migrate-reverse-test.sh` | `Passed: 111  Failed: 0` — All tests passed (exit 0) |
| `tracker-migrate-roundtrip-test.sh` | `Passed: 41  Failed: 0` — All tests passed (exit 0) |
| `tracker-bd132-race-test.sh` | `29 passed, 0 failed` (exit 0) |
| `tracker-bd133-header-preservation-test.sh` | `Passed: 15  Failed: 0` — All tests passed (exit 0) |
| `test-v11-realistic-ot.sh` | `PASS: 33  FAIL: 0` — All integration tests PASSED (33/33) (exit 0) |

## Findings: **none**

No BLOCKER / MUST / SHOULD / NIT. The LOW-1 fix is correct, single-sourced, and coverage-preserving; the whole commit verifies clean across the full CI battery.

---

## Rules-Applied Verification Block

| Rule | Evidence | Conclusion |
|---|---|---|
| No duplicated regex (single source) | Emit filter calls `pe_entry_regex_for_stream "pack-backlog"`; same fn used by `pe_list_entry_files` (`_lib.sh:430`) + `per_entry_regenerate_toc`. No second literal regex in the diff. | COMPLIANT |
| Coverage not weakened | TD-040 Blockers round-trip relocated to real `tracker_migrate_reverse_reconstruct` exercise (roundtrip 2.2c) asserting pack_id + blockers⊇TD-010; TD decode retained (reverse-test 1.1 line 136, type 159-163); negative asserts are filesystem-`! -f` + `assert_not_contains` (genuine). | COMPLIANT |
| Pack/project separation | `_tmr_emit_backlog` body unchanged (only call-site relocated to client `else`); client branch keeps sidecar+snapshot+4-monolith strip; `git diff --name-only | grep -c project-template/` = 0. | COMPLIANT |
| Empirical evidence | All findings/CI cite `git diff` lines + command output at HEAD `85724799`; CI tables quote summary lines verbatim. | COMPLIANT |
| Enumerate ENCODING surfaces | Validator (Check 32′/33) + all 4 affected tests + the cross-surface bd132/bd133 baseline tests run and consistent; manifest checked (empty diff). | COMPLIANT |
| Rules-Applied Verification Block | This table. | COMPLIANT |

### Read-docs attestation

| Doc | Read | Note |
|---|---|---|
| PLAN-BD-204.md §C-4 (+§0-§6 context) | YES | lines 1-552 read in full + §C-4 (281-346) |
| ARCHITECTURE-BD-204 §2.1/2.2/2.4.1/3.3 | DERIVED via PLAN §C-4 change-recipe cross-refs (design §-anchors quoted in plan + code comments) | Plan §C-4 enumerates the design §-recipe; verified code against plan. N/A as primary read — verification done against plan + actual code. |
| Full `git diff` | YES | 1223-line diff read in full (both pages) |
| `_tmr_emit_pack_tree` + emit loop | YES | diff lines 35-157 + filter 127-156 |
| `scripts/lib/per-entry/_lib.sh` (regex source) | YES | `:152`, `:300-344`, `:426-449` |
| `CLAUDE.md ## Pack memory` | YES | provided in full via project-instructions context |

> Note on ARCHITECTURE-BD-204: I verified the C-4 behavior against PLAN-BD-204 §C-4 (which quotes the design §-anchors in its change recipe) and against the actual landed code, rather than re-opening the architecture doc as a separate read. The plan is the executed spec for this commit and matches the code; no design contradiction found.
