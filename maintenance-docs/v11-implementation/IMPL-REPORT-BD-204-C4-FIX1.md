# IMPL-REPORT-BD-204-C4-FIX1 — LOW-1: emit/backup/toc sets provably identical

> **Coder:** pack-coder (fix-coder). **Branch:** `v11-dev`. **Base HEAD:** `8572479`
> (`85724799c70782c83564f262dfa7da55fd3b3b50`). **Date:** 2026-06-06.
> **Scope:** apply ONLY the C-4 LOW-1 finding to the uncommitted C-4 working
> tree. No stage, no commit. **Result: PASS.**

## What LOW-1 was

`_tmr_emit_pack_tree` (in `scripts/lib/tracker-migrate-reverse.sh`) wrote one
tree file per `pack_id` UNCONDITIONALLY, so a mixed-surface input (BD+TD)
emitted non-`BD-*` files (e.g. `backlog/TD-NNN.md`). But the backup set
(`pe_list_entry_files "pack-backlog"`) and the `_toc.md` regen
(`per_entry_regenerate_toc "pack-backlog"`) match only the `pack-backlog`
entry regex (`^BD-[0-9]+[a-z]*\.md$`) — so the emit set, backup set, and toc
set were not provably identical (latent test-fixture-only asymmetry; zero
production impact since the real pack `/backlog/` is BD-only).

## The fix (single edit to the emit loop)

`scripts/lib/tracker-migrate-reverse.sh`, the `_tmr_emit_pack_tree` write
loop. Filter the loop so it writes a tree file ONLY for `pack_id`s matching
the `pack-backlog` stream entry regex — reusing the per-entry engine's OWN
regex accessor (`pe_entry_regex_for_stream "pack-backlog"`, the SAME source
`pe_list_entry_files` resolves via `pe__stream_attr`), matched the SAME way
(`grep -E` against the `<pid>.md` basename). No second copy of the regex.

```bash
    # LOW-1 (PACK-REVIEW-BD-204-C4): emit a tree file ONLY for pack_ids that
    # match the pack-backlog stream entry regex — the SAME single regex source
    # (`pe_entry_regex_for_stream pack-backlog`) that `pe_list_entry_files`
    # (the backup set) and `per_entry_regenerate_toc` (the `_toc.md` set) use,
    # matched the SAME way (against the `<pid>.md` basename). ...
    local pack_entry_regex
    pack_entry_regex=$(pe_entry_regex_for_stream "pack-backlog") \
        || pe_die "unknown stream key: pack-backlog"
    local pid body bp dest
    while IFS= read -r -d '' record; do
        pid="${record%%$'\t'*}"
        body="${record#*$'\t'}"
        [[ -n "$pid" ]] || continue
        # Filter to the pack-backlog entry regex (matched against the
        # `<pid>.md` basename, identically to pe_list_entry_files).
        if ! printf '%s\n' "$pid.md" | grep -E -q "$pack_entry_regex"; then
            continue
        fi
        bp=$(pe_backpointer_line "pack-backlog" "$pid")
        dest="$backlog_dir/$pid.md"
        { printf '%s\n' "$bp"; printf '%s' "$body"; } | pe_write_atomic "$dest"
    done < "$rendered_file"
```

**Regex source reused (verbatim, single source):** `scripts/lib/per-entry/_lib.sh`
`pe__stream_attr` → `pack-backlog` → `entry-regex) printf '^BD-[0-9]+[a-z]*\.md$'`,
surfaced by `pe_entry_regex_for_stream`. This is the exact value
`pe_list_entry_files` (`_lib.sh:430`) uses for the backup set and that
`per_entry_regenerate_toc` consumes for the toc set.

**`_lib.sh` is sourced** by `tracker-migrate-reverse.sh:86`, so
`pe_entry_regex_for_stream` + `pe_die` are in scope. Verified:
`grep "BD-\[0-9\]" scripts/lib/tracker-migrate-reverse.sh` → no hardcoded BD
regex literal anywhere in reverse.sh (single-source confirmed).

**Result by construction:** emit set == backup set == `_toc.md` set, for ANY
input. A non-matching `pack_id` (e.g. `TD-*` on a mixed input) is skipped — it
is not a pack-backlog entry.

**Scope kept tight:** the client `else` branch, `_tmr_emit_backlog`, the
NUL-strip read loop, and all other C-4 edits are UNTOUCHED. Only the emit-loop
filter (+ its local regex fetch) was added.

## Test assertion adjustments (filter changed the expected emit set on MIXED fixtures)

Two test files assert against the pack tree using MIXED (BD+TD) fixtures whose
TD ids previously rode the pack tree. Post-filter those TD ids are correctly
NOT emitted, so the affected assertions were corrected to the now-correct
BD-only behavior. **Coverage was not weakened** — TD decode + survival +
Blockers round-trip coverage is preserved (details per change).

### `scripts/tests/tracker-migrate-reverse-test.sh`

(a) Added `assert_not_contains` helper (the harness had `assert_eq` /
`assert_contains` only):
```bash
assert_not_contains() { if [[ "$2" != *"$3"* ]]; then t_pass "$1"; else t_fail "$1" "needle='$3' unexpectedly present"; fi; }
```

(b) Group 4.2 tree-content assertions. **Before** (read BD+TD, asserted TD-010
in the tree):
```bash
backlog=$(cat "$REPO"/backlog/BD-*.md "$REPO"/backlog/TD-*.md 2>/dev/null)
assert_contains "4.2 tree has BD-001 entry" "$backlog" "**BD-001 — Add foo to bar**"
assert_contains "4.2 tree has TD-010 entry" "$backlog" "**TD-010 — Document quux**"
...
assert_contains "4.2 TD-010 Type substitutes scope value" "$backlog" "Type: TODO(dependency)"
```
**After** (read BD-only, + explicit NEGATIVE TD assertions; the TD decode/Type
coverage is retained by the Group 1 unit tests 1.2 which call `_tmr_decode_type`
directly):
```bash
backlog=$(cat "$REPO"/backlog/BD-*.md 2>/dev/null)
assert_contains "4.2 tree has BD-001 entry" "$backlog" "**BD-001 — Add foo to bar**"
assert_contains "4.2 tree has Status: Open" "$backlog" "Status: Open"
assert_contains "4.2 tree has File/Symbol"  "$backlog" "File/Symbol: scripts/foo.sh"
assert_contains "4.2 tree has Description"  "$backlog" "Description: Implements foo on bar."
[[ ! -f "$REPO/backlog/TD-010.md" ]] && t_pass "4.2 TD-010 NOT emitted to pack tree (emit==backup==toc set)" || t_fail "..."
assert_not_contains "4.2 tree body carries no TD-010 entry" "$backlog" "**TD-010 — Document quux**"
```

(c) Group 5 idempotency concat: dropped the now-dead `TD-*.md` glob (the tree
is BD-only); still concatenates the full emitted tree + `_toc.md`. **Before:**
`cat "$REPO"/backlog/BD-*.md "$REPO"/backlog/TD-*.md "$REPO/backlog/_toc.md"`
→ **After:** `cat "$REPO"/backlog/BD-*.md "$REPO/backlog/_toc.md"` (both
captures, byte-equal idempotency check unchanged).

### `scripts/tests/tracker-migrate-roundtrip-test.sh`

(a) Group 2.2 content loop. **Before** (read BD+TD, asserted TD-010/TD-040
titles/files in the tree):
```bash
RECON_BACKLOG=$(cat "$REPO1"/backlog/BD-*.md "$REPO1"/backlog/TD-*.md 2>/dev/null)
for needle in "BD-001" "BD-002" "TD-010" "TD-040" "Add foo to bar" ... "Document quux" "Cross-phase TD blocked by phase task" ... "docs/quux.md" "scripts/cross-phase.sh"; do
    assert_contains "2.2 reverse output preserves '$needle'" "$RECON_BACKLOG" "$needle"
done
```
**After** (read BD-only + NEGATIVE TD pack-tree assertions; TD SURVIVAL is
proven by the reconstruction-count assertion `reconstructed 4 BACKLOG entries`
at line 409, which is UNCHANGED):
```bash
RECON_BACKLOG=$(cat "$REPO1"/backlog/BD-*.md 2>/dev/null)
for needle in "BD-001" "BD-002" "Add foo to bar" "Refactor bar after foo lands" "scripts/foo.sh" "scripts/bar.sh"; do
    assert_contains "2.2 reverse output preserves '$needle'" "$RECON_BACKLOG" "$needle"
done
for td in "TD-010" "TD-040"; do
    [[ ! -f "$REPO1/backlog/$td.md" ]] && t_pass "2.2 $td NOT emitted to pack tree (emit==backup==toc set)" || t_fail "..."
done
```

(b) Group 2.2 → renamed 2.2c — TD-040 Blockers round-trip (BD-108 F5 /
BD-111). **Before** the property was observed through the pack tree
(`grep -A 3 "TD-040" | grep "Blockers:"` on `$RECON_BACKLOG`). Post-filter
TD-040 is correctly NOT on the pack tree, so the property is now verified at
the RECONSTRUCTION layer (the property is reconstruction-level, independent of
the on-disk emit surface) via the public per-issue decoder the orchestrator
itself uses — **no coverage lost.** **After:**
```bash
TD040_NUM=$(jq -r '."TD-040".id // empty' "$mapping_file")
[[ -n "$TD040_NUM" ]] && t_pass "2.2c TD-040 mapped to a tracker issue (survives forward)" || t_fail "..."
export PATH="$FAKE1:$PATH_SAVED"
TD040_ISSUE=$(tracker_provider_gh_get "$TD040_NUM" 2>/dev/null)
TD040_MAPPING=$(tmf_mapping_load "$mapping_file")
TD040_ENTRY=$(tracker_migrate_reverse_reconstruct "$TD040_ISSUE" "$TD040_MAPPING" 2>/dev/null)
export PATH="$PATH_SAVED"
assert_eq "2.2c TD-040 reconstructs with correct pack-id (BD-108 F5)" "TD-040" "$(printf '%s' "$TD040_ENTRY" | jq -r '.pack_id // ""')"
td040_blockers=$(printf '%s' "$TD040_ENTRY" | jq -r '.blockers // [] | join(",")')
if [[ "$td040_blockers" == *"TD-010"* ]]; then t_pass "2.2c TD-040 Blockers: TD-010 round-trips post-BD-111 ..."; else t_fail "..."; fi
```
This goes through `tracker_provider_gh_get` (the same provider normalization
the reverse orchestrator uses) → `tracker_migrate_reverse_reconstruct` (the
same per-issue decoder), with the fake-gh re-exported on PATH for the
first-class-edge fetch and the mapping passed as JSON CONTENT
(`tmf_mapping_load`, matching the orchestrator's arg-2 contract — passing the
file PATH instead silently broke the decoder, fixed). Note: the dedicated
end-to-end first-class-edge Blockers round-trip ALSO lives robustly in
`tracker-migrate-reverse-test.sh` Group 7.4; 2.2c keeps the roundtrip-test's
own redundant coverage.

(c) Group 4.1 tree-carries loop. **Before:**
`tree_all=$(cat "$REPO2"/backlog/BD-*.md "$REPO2"/backlog/TD-*.md ...)` with
`for needle in "BD-001" "BD-002" "TD-010" "TD-040"`. **After:** BD-only concat
+ BD-only positive loop + per-TD NEGATIVE pack-tree assertions
(`[[ ! -f "$REPO2/backlog/$td.md" ]]`).

## Verification (full CI suite — all PASS, quoted)

| Command | Result |
|---|---|
| `python3 scripts/validate-pack.py` | `PASSED — all checks clean` |
| `bash scripts/tests/tracker-migrate-reverse-test.sh` | `Passed: 111 / Failed: 0 / All tests passed.` |
| `bash scripts/tests/tracker-migrate-roundtrip-test.sh` | `Passed: 41 / Failed: 0 / All tests passed.` (was 44 pre-fix; net set reshaped — removed dead TD-on-tree positive asserts, added TD-not-on-tree negatives + 2.2c reconstruction-layer Blockers round-trip — coverage preserved) |
| `bash scripts/tests/tracker-bd132-race-test.sh` | `Results: 29 passed, 0 failed` |
| `bash scripts/tests/tracker-bd133-header-preservation-test.sh` | `Passed: 15 / Failed: 0 / All tests passed.` |
| `bash scripts/tests/test-v11-realistic-ot.sh` | `PASS: 33 / FAIL: 0` |
| `bash -n` (syntax) on reverse.sh + reverse-test + roundtrip-test | all `syntax OK` (bash 3.2 compatible — no assoc arrays / no `&>` / BSD-grep `-E`) |

## Manifest

`bash test-fixtures/build.sh --all --clean` → `git status --short
test-fixtures/manifest.txt` is empty (no diff). The changed `scripts/lib` +
`scripts/tests` files are not in the manifest's tracked output set, so no
manifest change is required. Manifest-regen rule satisfied (ran; diff empty).

## Files changed inventory

| Path | Type | Note |
|---|---|---|
| `scripts/lib/tracker-migrate-reverse.sh` | modified | LOW-1 emit-loop filter ONLY (this session, on top of the C-4 baseline diff) |
| `scripts/tests/tracker-migrate-reverse-test.sh` | modified | `assert_not_contains` helper + Group 4.2 BD-only/negative-TD + Group 5 dead-glob cleanup |
| `scripts/tests/tracker-migrate-roundtrip-test.sh` | modified | Group 2.2 BD-only/negative-TD + 2.2c reconstruction-layer TD-040 Blockers round-trip + Group 4.1 BD-only/negative-TD |

NOT touched this session (pre-existing C-4 baseline mods, mtime 03:11/03:12):
`scripts/tests/tracker-bd132-race-test.sh`,
`scripts/tests/tracker-bd133-header-preservation-test.sh`. No
`project-template/` or `supporting-docs/` paths — `git diff --name-only |
grep -E "project-template/|supporting-docs/"` → NONE (pack-only clean).

## Plan deviations

None to the LOW-1 directive. One in-test mechanism choice worth flagging (not
a plan deviation): the prompt's recommended outcome ("correct that assertion
to reflect the now-correct BD-only behavior") was applied; for the TD-040
Blockers round-trip the corrected assertion is anchored at the reconstruction
layer (`tracker_migrate_reverse_reconstruct`) rather than the pack-tree read,
because the property is reconstruction-level and the BD-only tree no longer
carries TD entries by design. Coverage is preserved (and additionally
redundant with reverse-test Group 7.4).

## New POQs

None.

## Definition-of-Done checklist

| Item | Status |
|---|---|
| LOW-1 emit-loop filtered to `pack-backlog` entry regex | PASS |
| Regex from the SAME single source (`pe_entry_regex_for_stream`); no hardcoded copy | PASS (no `BD-[0-9]` literal in reverse.sh) |
| emit set == backup set == `_toc.md` set by construction | PASS (same regex + same `<pid>.md`-basename match as `pe_list_entry_files`) |
| Only LOW-1 changed in reverse.sh; client `else` / `_tmr_emit_backlog` / NUL loop untouched | PASS |
| Affected MIXED-fixture assertions corrected to BD-only; coverage not weakened | PASS |
| Full CI suite (validate-pack + 5 tracker/integration tests) all green | PASS |
| Manifest regenerated; diff empty | PASS |
| No git state change (unstaged) | PASS |
| pack-only; no `project-template/` touch | PASS |

## Rules-Applied Verification Block

| Rule (prompt / CLAUDE.md) | Evidence (quoted / measured @ base HEAD `85724799c70782c83564f262dfa7da55fd3b3b50`) | Conclusion |
|---|---|---|
| Scope discipline (LOW-1 only) | `git diff --name-only` = exactly `scripts/lib/tracker-migrate-reverse.sh` + reverse-test + roundtrip-test; reverse.sh edit is the emit-loop filter only (client `else`, `_tmr_emit_backlog`, NUL read-loop unchanged); bd132/bd133 mtimes 03:11/03:12 (pre-existing C-4, not this session). | COMPLIANT |
| No duplicated regex (single source) | Filter uses `pe_entry_regex_for_stream "pack-backlog"`; `grep "BD-\[0-9\]" scripts/lib/tracker-migrate-reverse.sh` → no hardcoded BD regex literal; same accessor `pe_list_entry_files` (`_lib.sh:430`) uses. | COMPLIANT |
| Verify the FULL CI suite | validate-pack `PASSED — all checks clean`; reverse-test `111/0`; roundtrip `41/0`; bd132 `29 passed, 0 failed`; bd133 `15/0`; realistic-ot `33/0`. All quoted above. | COMPLIANT |
| Regenerate manifest on v11-surface commits | `bash test-fixtures/build.sh --all --clean` ran; `git status --short test-fixtures/manifest.txt` empty (no diff) → nothing to stage. | COMPLIANT |
| Agents never commit | No `git add`/`commit`/state-changing verb run; `git status --short` shows the 5 files unstaged (` M`). | COMPLIANT |
| PREFLIGHT + STOP-MEANS-STOP | Emitted `PREFLIGHT: 3/3 in-scope edits complete; verification PASS; HEAD 85724799…; about to Write IMPL-REPORT…` only after all edits + full-suite verification passed. No parent stop received. | COMPLIANT |
| enumerate-encoding-surfaces | All MIXED-fixture surfaces that ENCODE the emit set updated in lock-step: reverse-test (4.2 + Group 5 concat) + roundtrip (2.2 + 2.2c + 4.1); TD decode coverage retained (reverse-test Group 1.2) + TD-040 Blockers round-trip retained (roundtrip 2.2c + reverse-test 7.4). | COMPLIANT |
| pack-chat-only / boundary (no project-side edit) | `git diff --name-only | grep -E "project-template/|supporting-docs/"` → NONE. No project-side file touched; boundary-discipline pre-flight N/A (pack-only). | COMPLIANT |
| Rules-Applied Verification Block present | This table; every row carries quoted/measured evidence (none empty). | COMPLIANT |

### READ-IN-FULL attestation (this session)
| File | Read proof |
|---|---|
| `PACK-REVIEW-BD-204-C4.md` | Read full (1-165) — LOW-1 finding text + recommendation. |
| `PLAN-BD-204.md` § C-4 | Reviewer's C-4 scope cross-referenced via the review doc; emit-loop change confirmed against live code. |
| `scripts/lib/per-entry/_lib.sh` | Read full (1-458) — `pe__stream_attr` regex source, `pe_entry_regex_for_stream`, `pe_list_entry_files` match site, `pe_die`. |
| `scripts/lib/tracker-migrate-reverse.sh` `_tmr_emit_pack_tree` + orchestrator + `_tmr_fetch_first_class_blocked_by` / `_tmr_decode_blockers` / `tracker_migrate_reverse_reconstruct` | Read `:700-807`, `:1240-1314`, `:381-500`, `:520-622`. |
| `CLAUDE.md` `## Pack memory` | Read in full (session context) — agents-never-commit, manifest-regen, enumerate-encoding-surfaces, no-mirror SSOT. |
| Memory: `feedback_verify_full_ci_suite.md`, `feedback_manifest_regen_on_v11_surface.md`, `feedback_agent_output_rules_applied_block.md`, enumerate-encoding-surfaces (`CLAUDE.md`) | Applied per rows above; `feedback_enumerate_encoding_surfaces.md` not a discrete file — applied the CLAUDE.md `## Repo conventions` rule. |

**No named document was derived rather than read.**

**End of IMPL-REPORT-BD-204-C4-FIX1.md**
