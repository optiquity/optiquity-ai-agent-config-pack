# IMPL-REPORT — BD-204 Commit C-5

**Branch:** `v11-dev` · **Base HEAD (worktree):** `f36ab990e7fe8a2cc01b6f8db033e6fb399099c7`
(no commit made — agents never commit; left unstaged)
**Scope:** pack-only. No `project-template/` or `supporting-docs/` touched.

C-5 = forward pack branch reads the per-entry TREE (C2a), retires the Step-10
mirror regen on the pack branch (C2b), + the two BD-204 carry-forward MUST-fix
items (Deferred forward-label; explicit Deprecated close-path assertion).

---

## Files changed (inventory)

| Path | Type | What |
|---|---|---|
| `scripts/lib/tracker-migrate-forward.sh` | modified | C2a forward-read-tree + factor parser + `tmf_parse_backlog_tree`; C2b Step-10 retire on pack branch; carry-forward #1 `Deferred` label case |
| `scripts/tests/tracker-migrate-forward-test.sh` | modified | BD-only tree seed for integration groups; Step-10-not-regenerated assert; Deferred-label assert; count reconcile |
| `scripts/tests/tracker-migrate-roundtrip-test.sh` | modified | `_setup_test_repo` seeds BD-only tree (forward reads tree); count reconcile; 2.2c TD-040 relocated to decode-layer injection; monolith-free assert |
| `scripts/tests/tracker-provider-test.sh` | modified | carry-forward #2: explicit Open→Deprecated close-path (`not_planned` + `status:deprecated` label) assertion (4.4b) |

`test-fixtures/manifest.txt` — regen ran (`bash test-fixtures/build.sh --all
--clean`); **diff EMPTY** (no tracked fixture files added/removed; tree seeds are
runtime temp dirs), so not staged.

---

## A. Plan C-5 — forward reads the tree (`scripts/lib/tracker-migrate-forward.sh`)

### A1. C2a — factor the parser + tree parser

Added an idempotent source of `per-entry/_lib.sh` (for `pe_list_entry_files` +
`pe_strip_backpointer_stdin`), mirroring the C-4 reverse pattern.

`tmf_parse_backlog` was refactored to delegate to a shared file-based core
`_tmf_parse_backlog_file` (renamed the python heredoc to read `sys.argv[1]` —
unchanged grammar). NOTE: a `python3 - <file>` STDIN-heredoc cannot ALSO read
piped stdin, so the tree path materializes its entry-stream to a temp file
(found + fixed during implementation — first attempt piped to a heredoc-stdin
python and parsed 0 entries).

New `tmf_parse_backlog_tree "$key" "$stream_dir"` enumerates the tree via
`pe_list_entry_files` (the SAME single source the backup set + `_toc.md` regen
use), strips each file's line-1 back-pointer, concatenates into the
monolith-grammar stream (`---`-separated), and feeds the shared core — so the
entries-JSON shape (and the downstream `provider_create` payload) is identical
to the monolith read.

```sh
tmf_parse_backlog_tree() {
    local key="$1"; local stream_dir="$2"
    ...
    while IFS= read -r f; do
        [[ -n "$f" ]] || continue
        pe_strip_backpointer_stdin < "$f" >> "$stream_file"
        printf '\n---\n' >> "$stream_file"
    done < <(pe_list_entry_files "$key" "$stream_dir")
    _tmf_parse_backlog_file "$stream_file"
    ...
}
```

### A2. C2a — repoint the Step-1+2 read (pack branch only)

```sh
    if [[ "$surface" == "pack" ]]; then
        backlog_path="$repo_root/backlog"
    else
        backlog_path="$repo_root/BACKLOG.md"          # client UNCHANGED
    fi
    ...
    if [[ "$surface" == "pack" ]]; then
        entries=$(tmf_parse_backlog_tree "pack-backlog" "$backlog_path") || return 1
    else
        entries=$(tmf_parse_backlog "$backlog_path") || return 1   # client UNCHANGED
    fi
```

### A3. C2b — retire Step-10 mirror regen (pack branch only)

```sh
    if [[ "$surface" != "pack" ]]; then
        if ! _tmf_regen_mirror "$backlog_path" "$backend_slug" 2>/dev/null; then
            printf 'step-10 mirror regen: %s (re-run with --mirror-only to recover)\n' \
                "$backlog_path" >> "$partial_failures"
        fi
    fi
```

**Client `else` branch byte-unchanged — verified** (`git diff` shows only
pack-branch + factoring additions): client read at `:798`
(`backlog_path="$repo_root/BACKLOG.md"`), client monolith parse at `:809`
(`tmf_parse_backlog "$backlog_path"`), client Step-10 regen at `:1284`
(now under `if [[ "$surface" != "pack" ]]`). The `--mirror-only` short-circuit
(`:772/:779`) is untouched (out of C-5 scope — see POQ-1).

---

## B. Carry-forward #1 (FORWARD complement to C-1) — `Deferred` label

`_tmf_labels_for_entry` status-label `case`, parallel to the existing rows
(matches DP-3 matrix order, between `Unblocked` and `Resolved`):

```sh
        Deferred)    status_label="status:deferred" ;;
```

Empirical verification (standalone source + call):
```
Deferred -> ["bd-entry","template:bd-v11.0","status:deferred"]
Open     -> ["bd-entry","template:bd-v11.0","status:open"]
```
Tree-parse of the REAL `/backlog/`: 209 BD entries parsed, **11 Deferred**
(matches design §2.6 DP-3 evidence), BD-204 = Open.

**Test (forward-test Group 2.6):**
```sh
labels_deferred=$(_tmf_labels_for_entry '{"pack_id":"BD-001","status":"Deferred"}')
assert_contains "2.6 status:deferred (DP-3 carry-forward #1)" "$labels_deferred" '"status:deferred"'
# + negative: Deferred does NOT fall through to status:open
```

---

## C. Carry-forward #2 (NIT) — explicit Deprecated close-path test

`tracker-provider-test.sh` Group 4 (`tracker_edit_entry` close path). Pre-C-5,
the C-3 close-with-reason path was covered only TRANSITIVELY by the Cancelled
case (4.4). Added **4.4b** for Open→Deprecated directly. The `provider_update`
stub was extended to capture its payload (`$2 → TED_UPDATE_PAYLOAD`) so the
`status:deprecated` label (which rides the update `add_labels`) is assertable:

```sh
tracker_edit_entry "BD-001" '{"status":"Deprecated","old_status":"Open"}' "$TED_REPO" >/dev/null
assert_contains "4.4b Open→Deprecated closes with not_planned (DP-3 Deprecated row)" "$TED_CALLS" "|close:42:not_planned"
assert_contains "4.4b Open→Deprecated adds status:deprecated label" \
    "$(printf '%s' "$TED_UPDATE_PAYLOAD" | jq -c '.add_labels // []')" '"status:deprecated"'
```

---

## D. Tests + fixture reconcile (enumerate-encoding-surfaces)

### D1. `tracker-migrate-forward-test.sh`
- Added `_seed_pack_tree <repo> <monolith>` helper: filters the mixed fixture
  monolith to its BD-* entries, then `per_entry_decompose` into a clean BD-only
  `/backlog/` tree. NO `pack-ops/BACKLOG.md` written (fail-loud).
- Integration groups 3/4.3/4.4/4.6/5.3/5.4/6 now seed the tree (Group 6 writes
  its inline mini-fixture to a temp monolith then decomposes).
- The pack backlog is **BD-only by design** (TD is the project namespace). The
  mixed fixture's BD-* set is {BD-001, BD-002, BD-003}, so the integration
  counts move 5→3 entries / 7→5 creates+mapped; 3.3 close ≥2→≥1 (BD-003
  Resolved is the only closed-state BD; TD-011 Cancelled was a TD, dropped).
  5.3/5.4 failure points re-pointed (4th→2nd / 4th→3rd create) for the 3-entry
  set. Group 1 (parser) + Group 2 (helpers) keep the mixed monolith fixture for
  direct `tmf_parse_backlog`/helper unit tests (client-branch parser, unaffected).
- **3.6 FLIPPED** to assert NO `pack-ops/BACKLOG.md` is regenerated by forward
  (Step-10 retired) — the plan's named assertion.
- Deferred-label assertion added (Group 2.6 — item B).

### D2. `tracker-migrate-roundtrip-test.sh` (shared C-4/C-5 fixture — reconciled)
- Re-read C-4's landed edits first; built on them (did not fight them).
- `_setup_test_repo` now seeds the BD-only tree (BD-filter → `per_entry_decompose`).
  Found + worked around a `per_entry_decompose` behavior: on a MIXED monolith it
  appends non-matching (TD) blocks to the preceding BD file (BD-002.md swallowed
  TD-010/TD-040) → a BD-only PRE-FILTER is required for a clean tree.
- Round-trip is now monolith-free on BOTH directions (forward reads tree C-5;
  reverse emits tree C-4). Counts reconciled: Group 1 4→2 entries / 6→4 issues /
  6→4 mapping; Group 2.1 4→2; Group 3.1 second-forward 6→4 issues (F→R→F
  signature stays byte-equal — forward now reads the tree the first reverse
  re-emitted).
- **2.2c TD-040 coverage RELOCATED, not dropped:** the BD-only pack forward never
  creates a TD issue, so the TD reconstruct + first-class-Blockers round-trip is
  exercised at the DECODE layer by injecting a TD-040 issue (+ TD-010 upstream +
  the first-class blocked-by edge) directly into the fake-tracker state, then
  running the SAME public `tracker_migrate_reverse_reconstruct` decoder. Exact
  property preserved (pack-id reconstruct + TD-010 folds via the BD-111
  first-class channel). Pure decode-unit coverage also lives in
  `tracker-migrate-reverse-test.sh` Group 1/2 (per `ANALYSIS-BD-204-SHARED-TEST-BOUNDARY.md`).
- Stale C-4 "forward reads the monolith until C-5" comments reconciled to the
  tree-read reality; added a "NO `pack-ops/BACKLOG.md` monolith" fail-loud assert.

### D3. `tracker-provider-test.sh`
- Deprecated close-path assertion 4.4b (item C).

### D4. `test-fixtures/manifest.txt`
- Regen ran; diff EMPTY → not staged.

---

## Verification (FULL CI battery — all PASS, quoted)

| # | Command | Result |
|---|---|---|
| 1 | `python3 scripts/validate-pack.py` | `PASSED — all checks clean` (Check 32′ green; only advisory removed-doc WARNs, exit unaffected) |
| 2 | `bash scripts/tests/tracker-migrate-forward-test.sh` | `Passed: 144 / Failed: 0` |
| 3 | `bash scripts/tests/tracker-migrate-roundtrip-test.sh` | `Passed: 42 / Failed: 0` |
| 4 | `bash scripts/tests/tracker-provider-test.sh` | `Passed: 114 / Failed: 0` |
| 5 | `bash scripts/tests/tracker-migrate-reverse-test.sh` | `Passed: 111 / Failed: 0` (C-4 reverse path not broken) |
| 6 | `bash scripts/tests/test-v11-realistic-ot.sh` | `PASS: 33 / FAIL: 0` |

`bash -n` syntax check: all 4 files OK.

---

## Plan deviations

None to the C-5 change recipe. Two reconciliation notes, both authorized:
- The roundtrip + forward integration fixtures were flipped to **BD-only trees**
  (the pack backlog is BD-only by design — `ARCHITECTURE-BD-204.md` / the
  analysis doc; C-4 already made the reverse emit BD-only). The plan's risk #1
  explicitly authorizes the coder to "reconcile the fixture seed" so the test is
  coherent at each commit; the reviewer verifies coherence. This required count
  reconciliation + relocating (not dropping) the 2.2c TD-040 coverage to the
  decode layer.

---

## New POQs introduced (surfaced, not silently absorbed)

- **POQ-1 — `--mirror-only` / `pack tracker mirror-rebuild` short-circuit still
  reads + regenerates the pack monolith.** The forward `mirror_only==1`
  short-circuit (`tracker-migrate-forward.sh:772/:779`) still computes
  `backlog_path="$repo_root/pack-ops/BACKLOG.md"` and calls `_tmf_regen_mirror`
  on the pack surface. The plan's C-5 file scope named only the Step-1+2 read
  (`:733`) and the Step-10 regen (`:1208`), and design §2.2's table lists only
  C2a/C2b — the `--mirror-only` verb is NOT in the C-5 recipe. Under the
  no-monolith model the pack surface has no monolith, so `pack tracker
  mirror-rebuild` on the pack surface would error (`BACKLOG.md not found`) or, if
  one existed, regenerate a forbidden monolith. **Disposition:** left as-is per
  the plan's named scope (forward-test 4.5 still seeds the monolith to exercise
  the UNCHANGED `--mirror-only` path); flagged for Pack Chat to decide whether
  C-6 / a follow-up retires the pack-surface `--mirror-only`/`mirror-rebuild`
  verb. Recommended default: retire/repoint it alongside the C-6 doctor work
  (same "pack-surface monolith machinery" family).

- **POQ-2 — real `/backlog/` tree parses 209 of 212 entry files via the strict
  `^\*\*(BD|TD)-\d{3}` header regex.** `tmf_parse_backlog_tree` against the live
  pack `/backlog/` returned 209 (suffix entries like `BD-019b` / non-3-digit
  shapes are not matched by the existing monolith grammar). This is a
  PRE-EXISTING property of `tmf_parse_backlog`'s grammar (not introduced by C-5)
  and is only exercised for real at the GATED C-8 dogfood flip, not this commit.
  **Disposition:** flagged for the C-7 lossless oracle / C-8 gate (the oracle's
  count + identity legs will catch any real entry loss); the suffix-entry
  grammar is the rename-plans / `feedback_no_bd_letter_suffix` territory.

---

## Boundary discipline check

Per the P-missed-7 pre-flight: all C-5 edits are pack-side (`scripts/lib/`,
`scripts/tests/`). No `project-template/`, `supporting-docs/`, or any
client-shipped surface was touched (verified: `git diff --name-only | grep -E
'project-template/|supporting-docs/'` → none). No pack-only reference was added
to any project-side file (none edited). The client `else` branch (BD-207) is
byte-unchanged. No project-side SSOT investigation was needed — zero project-side
edits. No "Boundary discipline stop" triggered.

---

## Rules-Applied Verification Block

| Rule (as named) | Verification evidence (quoted) | Conclusion |
|---|---|---|
| Fail-loud / no monolith | Pack forward writes no monolith: `if [[ "$surface" != "pack" ]]` guards Step-10 (`:1284`); forward-test 3.6 asserts `! -f pack-ops/BACKLOG.md`; roundtrip 2.3 asserts `! -f pack-ops/BACKLOG.md`; `validate-pack` `PASSED` (Check 32′ green). Tree seeds write no monolith. | COMPLIANT |
| Pack/project separation | `git diff --name-only` = only `scripts/lib/tracker-migrate-forward.sh` + 3 test files; `grep -E 'project-template/|supporting-docs/'` → none. Client `else` branch byte-unchanged (read at `:798`, parse `:809`, Step-10 `:1284`). | COMPLIANT |
| Enumerate ENCODING surfaces | Updated in lock-step: lib (forward read + label + Step-10) + forward-test (seed + Step-10-assert + Deferred-label + counts) + roundtrip-test (seed + counts + 2.2c relocate) + provider-test (Deprecated 4.4b). Shared roundtrip fixture reconciled coherent end-to-end (built on C-4's landed edits). | COMPLIANT |
| Verify the FULL CI suite | All 6 quoted PASS: validate-pack `PASSED — all checks clean`; forward `144/0`; roundtrip `42/0`; provider `114/0`; reverse `111/0`; realistic-ot `33/0`. Ran reverse + roundtrip to prove the C-4 path is not broken. | COMPLIANT |
| Regenerate manifest on v11-surface commits | `bash test-fixtures/build.sh --all --clean` ran; `git diff --stat test-fixtures/manifest.txt` = empty → no manifest change to stage. | COMPLIANT (no-op, empty diff) |
| Agents never commit | No `git add`/`commit`/`tag`/`push` run; `git status` shows 4 unstaged modified files + this new report. HEAD unchanged at `f36ab99`. | COMPLIANT |
| PREFLIGHT + STOP-MEANS-STOP | Emitted one `PREFLIGHT:` line after all edits + all 6 verifications PASSED, before this Write. No parent stop/halt received. | COMPLIANT |
| Edit in place, not full rewrite | All changes via targeted `Edit` calls (no full-file `Write` of any source/test); re-read affected regions after editing. | COMPLIANT |
| Rules-Applied Verification Block | This block. | COMPLIANT |

### READ-IN-FULL doc/code attestation

| Doc / code | Evidence | Conclusion |
|---|---|---|
| `PLAN-BD-204.md` § Commit C-5 | Read `:348-383` (recipe C2a REPOINT / C2b RETIRE) + risk #1 `:547-553` (shared-fixture reconcile authorization) + coverage table `:594`. | COMPLIANT |
| `ARCHITECTURE-BD-204.md` §2.2 (C2a/C2b) | Read `:316-318` (C2a read repoint, C2b Step-10 retire pack) + §2.2.C1/§2.2 context. | COMPLIANT |
| `ARCHITECTURE-BD-204.md` §2.6 DP-3 matrix | Read `:129-180` (Deferred→`status:deferred` open row; Deprecated→`not_planned`+`status:deprecated`); 11 Deferred entries confirmed by live tree-parse. | COMPLIANT |
| `backlog/BD-204.md` carry-forward anchor | Read `:23` (the IMPLEMENTATION CARRY-FORWARD → C-5 line — both items verbatim). | COMPLIANT |
| `tracker-migrate-forward.sh` (pack+client branches, `tmf_parse_backlog`, `_tmf_regen_mirror`, `_tmf_labels_for_entry`) | Read `:1-60`, `:335-477`, `:670-799`, `:1255-1276`, `:1390-1431`. | COMPLIANT |
| `per-entry/_lib.sh` (`pe_list_entry_files`, back-pointer strip) | Read `:290-344`, `:426-457`; `pe_list_entry_files` returns 212 files on live tree. | COMPLIANT |
| 3 test files incl. C-4's landed roundtrip edits | Read forward-test full (1-1436), roundtrip-test full (built on C-4 lines 415-626), provider-test Group 4 `:619-708`; reviewed `git show f36ab99 --stat` for C-4's roundtrip reshape. | COMPLIANT |
| `CLAUDE.md` `## Pack memory` | Read in full (provided in context). | COMPLIANT |
| `feedback_fail_loud_delete_old_source.md` | Read in full — no monolith regenerated; tree is SSOT. | COMPLIANT |
| `feedback_pack_project_separation_of_concerns.md` | Read in full — only pack-surface edited; client branch unchanged. | COMPLIANT |
| `feedback_verify_full_ci_suite.md` | Read in full — ran the full 6-command battery incl. integration tests, not just validate-pack. | COMPLIANT |
| `feedback_manifest_regen_on_v11_surface.md` | Read in full — regen ran; empty diff. | COMPLIANT |
| `feedback_edit_in_place_not_full_rewrite.md` | Read in full — targeted Edits only. | COMPLIANT |
| `feedback_agent_output_rules_applied_block.md` | Read in full — this block present with quoted evidence. | COMPLIANT |
