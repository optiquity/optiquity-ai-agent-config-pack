# IMPL-REPORT — BD-204 Commit C-1 (`Deferred` reverse-decode branch, DP-3 gap-fill)

- **Branch:** `v11-dev`
- **Base HEAD (pre-flight + final, unchanged — agent does not commit):** `4d312d504d36ad32ea78100a16506071ac432887`
- **Scope keyword:** `pack-only` (all edits under `scripts/`; no `project-template/` or project-side touch)
- **Status:** all 3 in-scope edits complete; full verification battery PASS; changes unstaged.

## Files changed (inventory)

| Path | Change type |
|---|---|
| `scripts/lib/tracker-migrate-reverse.sh` | modified (2 insertions: both `_tmr_decode_status` switches) |
| `scripts/tests/tracker-migrate-reverse-test.sh` | modified (1 insertion: Group-1 decoder assert) |

`test-fixtures/manifest.txt` — regenerated; **diff empty** (manifest tracks the `project-template/` install
surface, which is unchanged by these `scripts/` edits). Not staged because empty (per
`regenerate-manifest-v11-surface`: empty diff → not a v11-surface manifest change).

No new files. No deletions. Line delta: +3 lines total (2 in lib, 1 in test).

## Edits (quoted)

### Edit 1 — production fix: canonical-object OPEN-state switch (the sole live reverse path)

`scripts/lib/tracker-migrate-reverse.sh`, `_tmr_decode_status`, `# Open: derive from label` block.
Added the `status:deferred` case parallel to the existing `status:unblocked` case:

```
    # Open: derive from label.
    case "$label" in
        status:unblocked)   echo "Unblocked" ;;
        status:deferred)    echo "Deferred" ;;
        *)                  echo "Open" ;;
    esac
```

This is the only branch on the live production reverse path: the sole production call
(`status=$(_tmr_decode_status "$issue")` in `tracker_migrate_reverse_reconstruct`) passes a full
Issue JSON object → first char `{` → canonical-object path (per ARCHITECTURE §2.6.1 EE block).

### Edit 2 — test symmetry: legacy `[`-array switch (enumerate-encoding-surfaces)

Same function, the legacy labels-only `case "$label"` (reached only on `[`-array input). Added the
`status:deferred` case so the two switches encode the same `status:* → state` contract symmetrically:

```
            status:open)        echo "Open" ;;
            status:unblocked)   echo "Unblocked" ;;
            status:deferred)    echo "Deferred" ;;
            status:resolved)    echo "Resolved" ;;
```

### Edit 3 — Group-1 fixture assertion (test symmetry)

`scripts/tests/tracker-migrate-reverse-test.sh`, Group-1 decoder block, placed parallel to the
existing `status:unblocked` assert and matching the surrounding column alignment / numbering:

```
assert_eq "1.1 status:deferred → Deferred"   "Deferred"   "$(_tmr_decode_status '["status:deferred"]')"
```

All three additions are targeted in-place insertions (no rewrite); re-read post-edit (see "Final state"
below) confirms each is correctly placed parallel to the matching `unblocked` case/assert with correct
indentation.

## Manifest regen

```
bash test-fixtures/build.sh --all --clean   → rc=0
git diff --stat test-fixtures/manifest.txt  → (empty)
```

Empty diff → `manifest.txt` is not part of this commit's scope (the edits touch `scripts/` source, not
the `project-template/` install surface the manifest enumerates).

## Verification (FULL CI battery — all PASS before PREFLIGHT)

| Command | Result |
|---|---|
| `python3 scripts/validate-pack.py` | `rc=0` — `PASSED — all checks clean` |
| `bash scripts/tests/tracker-migrate-reverse-test.sh` | `rc=0` — `Passed: 114  Failed: 0  All tests passed.`; new `PASS 1.1 status:deferred → Deferred` confirmed |
| `bash scripts/tests/tracker-migrate-roundtrip-test.sh` | `rc=0` — `Passed: 45  Failed: 0  All tests passed.` |
| `bash scripts/tests/test-v11-realistic-ot.sh` | `rc=0` — `All v11-realistic-ot integration tests PASSED (33/33).` |

## Final state (re-read evidence)

- `git status --short`: `M scripts/lib/tracker-migrate-reverse.sh` + `M scripts/tests/tracker-migrate-reverse-test.sh` (nothing staged).
- `git rev-parse HEAD`: `4d312d504d36ad32ea78100a16506071ac432887` (unchanged — no commit).
- Canonical switch re-read (lines 245–249): `status:unblocked` then `status:deferred` then `*)`.
- Legacy switch re-read (lines 202–209): `open / unblocked / deferred / resolved / cancelled / deprecated / *`.
- Test assert re-read (lines 133–137): `open / unblocked / deferred / resolved / cancelled` in sequence.

## Plan deviations

None. Implemented exactly the PLAN-BD-204 § "Commit C-1" recipe (canonical-object switch as the
load-bearing change; legacy switch + Group-1 assert for test symmetry; manifest regen) and the
ARCHITECTURE-BD-204 §2.6 / §2.6.1 determination.

## New POQs introduced

None.

## Definition-of-Done checklist

| Item | Status |
|---|---|
| `status:deferred → Deferred` added to canonical-object OPEN-state switch (live path) | PASS |
| `status:deferred → Deferred` added to legacy `[`-array switch (test symmetry) | PASS |
| Group-1 fixture assertion added, matching existing style/numbering | PASS |
| Both switches + their test stay symmetric (no audit gap) | PASS |
| Existing decode cases / other behavior unchanged (additive only) | PASS |
| No `project-template/` or project-side touch (pack-only) | PASS |
| No `else`/client-branch touch | PASS (no shared `else` branch involved) |
| Manifest regenerated; empty diff documented | PASS |
| `validate-pack.py` green | PASS |
| Full CI integration battery (reverse + roundtrip + realistic-ot) green | PASS |
| No git state change (unstaged, HEAD unchanged) | PASS |

---

## Rules-Applied Verification Block

| Rule / READ-IN-FULL doc | Verification evidence (quoted) | Conclusion |
|---|---|---|
| **Agents never commit** | `git status --short` shows ` M` (unstaged) on both files; `git rev-parse HEAD` = `4d312d50…` (= pre-flight SHA). No `git add/commit/push/tag` run. | COMPLIANT |
| **Per-action approval extends to sub-agents** | Only ops performed: 3 targeted Edits + `test-fixtures/build.sh --all --clean` (the in-scope regen) + read-only verification commands. No `rm`/overwrite of a trusted file beyond scope. | COMPLIANT |
| **PREFLIGHT + STOP-MEANS-STOP** | Emitted `PREFLIGHT: 3/3 in-scope edits complete; verification PASS; HEAD 4d312d50…; about to Write IMPL-REPORT…` only after all 4 verification commands returned rc=0. No parent stop message received. | COMPLIANT |
| **Enumerate ENCODING surfaces** | Three surfaces updated in lock-step: canonical switch (`status:deferred) echo "Deferred"`), legacy switch (same arm), Group-1 assert (`PASS 1.1 status:deferred → Deferred`). All three confirmed present via post-edit re-read + test run. | COMPLIANT |
| **Verify the FULL CI suite, not just validate-pack** | Ran all four: `validate-pack.py` (rc=0), `tracker-migrate-reverse-test.sh` (114/0), `tracker-migrate-roundtrip-test.sh` (45/0), `test-v11-realistic-ot.sh` (33/33). Quoted in Verification table. | COMPLIANT |
| **Regenerate manifest on v11-surface commits** | `bash test-fixtures/build.sh --all --clean` rc=0; `git diff --stat test-fixtures/manifest.txt` → empty; per the rule, empty diff ⇒ not a manifest change to stage. | COMPLIANT |
| **Edit in place, not full rewrite** | Three `Edit` calls (string-replace), each adding one line into an existing block; no `Write` to a source file. Post-edit re-read (sed of lines 202–211, 244–251, 133–137) confirms placement + no dropped surrounding content. | COMPLIANT |
| **Rules-Applied Verification Block** | This block. | COMPLIANT |
| READ: `PLAN-BD-204.md` § Commit C-1 | Read lines 179–218 directly; recipe followed verbatim (canonical switch + legacy switch + Group-1 assert label `1.1 status:deferred → Deferred` + manifest regen + verification battery). | COMPLIANT |
| READ: `ARCHITECTURE-BD-204.md` §2.6 + §2.6.1 | Read lines 572–631 directly; §2.6 6-row matrix (`Deferred` = open + `status:deferred`, parallel to `status:unblocked`); §2.6.1 determination (canonical-object switch = live REQUIRED site; legacy switch + fixture = test-symmetry SHOULD). | COMPLIANT |
| READ: `tracker-migrate-reverse.sh` `_tmr_decode_status` (both switches) | Read full file (1178 lines); both switches located (legacy `:202–209`, canonical `:245–248` pre-edit) and edited. | COMPLIANT |
| READ: `tracker-migrate-reverse-test.sh` Group-1 asserts | Read full file (823 lines); Group-1 block `:133–150` located; assertion inserted matching style. | COMPLIANT |
| READ: `CLAUDE.md` ## Pack memory | Read in full (provided in context); applied `enumerate-encoding-surfaces`, `regenerate-manifest-v11-surface`, `preflight-stop-means-stop`, `agents-never-commit`, `edit-in-place`, `rules-applied-verification-block`. | COMPLIANT |
| READ: `feedback_verify_full_ci_suite.md` | Read in full; ran integration tests (not validate-pack alone), incl. `test-v11-realistic-ot.sh` which pins validator banners — green (33/33). | COMPLIANT |
| READ: `feedback_manifest_regen_on_v11_surface.md` | Read in full; ran regen; empty diff ⇒ correctly not staged (rule: empty diff → not a v11-surface manifest change). | COMPLIANT |
| READ: `feedback_edit_in_place_not_full_rewrite.md` | Read in full; used targeted Edits + post-edit re-read evidence (not intent). | COMPLIANT |
| READ: `feedback_agent_output_rules_applied_block.md` | Read in full; this block carries per-rule + per-doc quoted evidence with terminal COMPLIANT/N-A/VIOLATED states (no empty rows). | COMPLIANT |
