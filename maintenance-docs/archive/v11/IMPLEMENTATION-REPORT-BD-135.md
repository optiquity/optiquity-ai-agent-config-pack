# IMPLEMENTATION REPORT — BD-135

**BD:** BD-135 — Disambiguate `tracker.toml.example` filename pair (rename pack-side and client-side)
**Branch:** `v11-dev`
**HEAD at start:** `dc68878`
**HEAD at finish:** `dc68878` (working-tree only — no commits per pack-coder rule)
**Date:** 2026-05-09

---

## Summary

Renamed both `tracker.toml.example` files in the pack repo to filename-distinct forms per the codified `feedback_filename_uniqueness.md` heuristic, eliminating the recurring confusion vector that led to the (now Cancelled) BD-123 misframing. Pack-side example is now `tracker.toml.pack-example`; client-side template (the source file in the pack's `project-template/`) is now `tracker.toml.project-example`. The install destination basename in client projects deliberately stays at `tracker.toml.example` — see "Open design choice" below for reasoning. Updated 9 reference sites across docs, scripts, and tests; ran the validator and the two relevant test scripts; all green.

## What landed

### Renames (2)

| Old path | New path | Mechanism |
|---|---|---|
| `/tracker.toml.example` | `/tracker.toml.pack-example` | Read original → Write to new path → `rm` original (byte-identity verified pre-rm). |
| `/project-template/tracker.toml.example` | `/project-template/tracker.toml.project-example` | Same Read+Write+rm mechanism (byte-identity verified pre-rm). |

The `rm` of each original file is the **only** destructive action taken in this BD. Both removals are explicitly authorized by BD-135's scope ("the rm step of each rename is explicitly permitted; flag clearly in your report"). Flagged here.

### Reference updates (per file, terse)

| File | Lines touched | Change |
|---|---|---|
| `README.md` | 128, 226 | Updated layout-block entries: `project-template/` row now reads `tracker.toml.project-example` (with annotation that it lands at the client root as `tracker.toml.example`); pack-root row now reads `tracker.toml.pack-example` (with annotation that you copy it to `tracker.toml` to opt the pack repo in). |
| `OPTIONAL-FEATURES.md` | 156–158 | Replaced single-name reference with prose that names both the pack-side template (`tracker.toml.pack-example`) and the client-side install destination (`tracker.toml.example` installed by `init-project.sh`). |
| `HELP-FRAGMENT-TRACKER.md` (pack-root) | 29 | Replaced ambiguous `tracker.toml.example` reference with parenthetical that disambiguates pack-repo vs. client-repo context. |
| `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` | 29 | Same edit, byte-identical (DELTA L1, Check 24 enforced). |
| `supporting-docs/MERGE-STRATEGY.md` | 243 | Catch-all classifier paragraph clarified to call out source-name (`project-template/tracker.toml.project-example`) explicitly. |
| `supporting-docs/MIGRATION-v10-to-v11.md` | 8, 48, 118, 226, 252 | Five reference points all annotated to identify the source path (`project-template/tracker.toml.project-example`) while preserving the install-destination name (`tracker.toml.example`) used in client narrative. |
| `scripts/init-project.sh` | 14 (header comment), 722–729 (the copy block — line numbers shifted +2 from the spec due to added comment lines), 882 (manifest entry) | Source path updated to `tracker.toml.project-example`; destination basename retained as `tracker.toml.example`; comment block expanded to record BD-135 rationale at the call site. |
| `scripts/migrate-v10-to-v11.sh` | 25 (header comment), 181–189 (the copy block — line numbers shifted) | Same: source path updated, destination retained. |
| `scripts/test-migrator-manifest.sh` | 277–279, 331 | Synthetic-manifest test cases updated to use the new source path so `cp` succeeds; destination basename retained. |

### Files NOT modified despite containing the basename

The following files contain `tracker.toml.example` that intentionally refers to the **install destination basename** (kept by design — see next section). No edits needed:

| File | Lines | Why retained |
|---|---|---|
| `scripts/tests/test-init-project.sh` | 159–161 | Asserts `[[ -f "$T/tracker.toml.example" ]]` where `$T` is the **target** (post-install) directory. Destination basename is unchanged, so the assertion is correct. |
| `scripts/tests/test-migrate-v10-to-v11.sh` | 135–137 | Same — checks the post-migration target file. |
| `scripts/lib/migrator-core.sh` | 484 | Lists `tracker.toml.example` in the v11 **target surface** (the customization-relevant file basename **on the target**, not the source path). Destination is unchanged. |
| `scripts/test-migrator-core.sh` | 359, 370, 391, 396 | Validates that `migrator_target_surface_for_version v11` includes the `tracker.toml.example` target basename. Same reason as above. |

PM-only files (`BACKLOG.md`, `CHANGELOG.md`, root trinity files, `PACK-CHAT.md`, `PACK-AGENTS.md`, README version table) and historical reports under `maintenance-docs/v11-implementation/` and `maintenance-docs/v11-research/` were not touched per scope. The historical reports (e.g., `IMPLEMENTATION-REPORT-BD-119-*.md`, `PACK-REVIEW-*.md`) preserve the prior state at time of writing and are not authoritative for current pack behavior — leaving them stable is correct.

## Open design choice — install destination basename

**Decision:** Keep the install-destination basename in client projects at `tracker.toml.example` (unchanged). Only the pack-internal source filenames change.

**Reasoning.** The unique-filename heuristic (`feedback_filename_uniqueness.md`) is fundamentally a **pack-repo concern** — the heuristic protects authors who reference files in prose without paths. Inside the pack repo, two files with the basename `tracker.toml.example` create the collision the heuristic was written to prevent; they're now distinct (`tracker.toml.pack-example` vs `tracker.toml.project-example`).

Inside any one **client project**, only ONE tracker example file ever exists (the one installed at the project root). There is no collision client-side, so the heuristic does not apply. Renaming the install destination would: (a) break every existing v11 client project on next `init-project.sh --update` or `migrate-v10-to-v11.sh` re-run by leaving an orphan `tracker.toml.example` next to a new `tracker.toml.project-example`; (b) force documentation, CLI help text, and the `pack tracker init` flow to evolve in lockstep across every client; (c) provide zero offsetting clarity gain (because there's nothing to disambiguate from in client context).

The migrator/init scripts now read from the renamed source and write to the unchanged destination, making the rename transparent to client developers. The two-name asymmetry is documented at every reference site (README layout block, OPTIONAL-FEATURES, MIGRATION guide, MERGE-STRATEGY, and the script comment blocks at `init-project.sh:723–725` and `migrate-v10-to-v11.sh:184–185`).

## How verified

### Validator

```
$ python3 scripts/validate-pack.py
... [all checks logged] ...
============================================================
PASSED — all checks clean
```

All 28 checks pass. Notable: Check 24 (HELP-FRAGMENT-TRACKER byte-identity, DELTA L1) passes — the trinity-mirror constraint is preserved.

### Trinity byte-identity

```
$ diff HELP-FRAGMENT-TRACKER.md project-template/docs/pack/HELP-FRAGMENT-TRACKER.md
$ echo $?
0
```

Empty diff, rc=0 — files are byte-identical.

### Functional tests

`bash scripts/test-migrator-manifest.sh` — **12 passed, 0 failed.** Confirms the synthetic-manifest test cases now correctly resolve `project-template/tracker.toml.project-example` as the source and successfully write `tracker.toml.example` at the target. (Both the "additive write only when target missing" and "skip when target already present" paths verified.)

`bash scripts/test-migrator-core.sh` — **19 passed, 0 failed.** Confirms `migrator_target_surface_for_version v11` still correctly lists `tracker.toml.example` (the target-side basename, kept by design).

### Source-content integrity

Pre-rm diffs verified byte-identical content between old and new files for both renames:
- `diff tracker.toml.example tracker.toml.pack-example` → empty
- `diff project-template/tracker.toml.example project-template/tracker.toml.project-example` → empty

After `rm`, the new files were re-listed via `ls`; both present, originals absent.

### Sanity grep

```
grep -rn 'tracker\.toml\.example' README.md OPTIONAL-FEATURES.md \
    HELP-FRAGMENT-TRACKER.md project-template/docs/pack/HELP-FRAGMENT-TRACKER.md \
    supporting-docs/MERGE-STRATEGY.md supporting-docs/MIGRATION-v10-to-v11.md \
    scripts/init-project.sh scripts/migrate-v10-to-v11.sh scripts/tests/
```

Returns only intentional hits: install-destination basename references in the migration narrative, the test-script `[[ -f "$T/tracker.toml.example" ]]` assertions, and inline annotation prose ("...lands at the project root as `tracker.toml.example`"). No stale references remain.

## Files modified

| Path | Change type | Note |
|---|---|---|
| `tracker.toml.example` | DELETED | Replaced by `tracker.toml.pack-example`. |
| `tracker.toml.pack-example` | NEW | Byte-identical content to deleted `tracker.toml.example`. |
| `project-template/tracker.toml.example` | DELETED | Replaced by `project-template/tracker.toml.project-example`. |
| `project-template/tracker.toml.project-example` | NEW | Byte-identical content to deleted file. |
| `README.md` | modified | Lines 128, 226 layout-block entries. |
| `OPTIONAL-FEATURES.md` | modified | Lines 156–161 install-narrative. |
| `HELP-FRAGMENT-TRACKER.md` | modified | Line 29 — trinity-mirrored. |
| `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` | modified | Line 29 — trinity-mirrored, byte-identical. |
| `supporting-docs/MERGE-STRATEGY.md` | modified | Line 243 catch-all paragraph. |
| `supporting-docs/MIGRATION-v10-to-v11.md` | modified | 5 references at lines 8, 48–50, 118–121, 226–229, 252–256. |
| `scripts/init-project.sh` | modified | Header comment + S11 copy block + manifest entry. |
| `scripts/migrate-v10-to-v11.sh` | modified | Header comment + S5 copy block. |
| `scripts/test-migrator-manifest.sh` | modified | Two synthetic-manifest source paths updated. |

Stat: 2 deleted, 2 added, 9 modified — 13 path changes total.

## Working-tree state (post-edit)

```
$ git status
On branch v11-dev
Your branch is up to date with 'origin/v11-dev'.

Changes not staged for commit:
	modified:   HELP-FRAGMENT-TRACKER.md
	modified:   OPTIONAL-FEATURES.md
	modified:   README.md
	modified:   project-template/docs/pack/HELP-FRAGMENT-TRACKER.md
	deleted:    project-template/tracker.toml.example
	modified:   scripts/init-project.sh
	modified:   scripts/migrate-v10-to-v11.sh
	modified:   scripts/test-migrator-manifest.sh
	modified:   supporting-docs/MERGE-STRATEGY.md
	modified:   supporting-docs/MIGRATION-v10-to-v11.md
	deleted:    tracker.toml.example

Untracked files:
	project-template/tracker.toml.project-example
	tracker.toml.pack-example
```

No commits, no `git add`, no `git mv` — all per the read-only-git-verbs rule. Pack Chat stages and commits.

## Plan deviations

**None.** Implemented exactly as scoped:
- Both files renamed via Read+Write+rm.
- All ~9 reference sites updated (README ×2, OPTIONAL-FEATURES, both HELP-FRAGMENT-TRACKER copies, MERGE-STRATEGY, MIGRATION ×5 lines, init-project.sh ×3, migrate-v10-to-v11.sh ×2). Plus one beyond-spec edit to `scripts/test-migrator-manifest.sh` — the BD prompt did not list this file, but its synthetic-manifest test cases referenced `project-template/tracker.toml.example` as a real pack file used by `cp`; without the update the test would have failed (source file missing). Documented above; in scope of "ensure test pass".
- Install-destination basename decision documented with reasoning.

## New POQs

**None.** No architectural gap was discovered. The unique-filename heuristic was applied cleanly; the install-destination decision is documented for future reference but does not require a new BD.

## Definition of Done

| Item | Status |
|---|---|
| Old `/tracker.toml.example` and `/project-template/tracker.toml.example` no longer exist; new uniquely-named files exist with byte-identical content. | PASS |
| Every reference site updated; no stale references except intentional install-destination retention. | PASS |
| HELP-FRAGMENT-TRACKER.md byte-identical across pack-root and client mirror. | PASS |
| `python3 scripts/validate-pack.py` passes. | PASS |
| Install-destination basename choice documented with rationale. | PASS |
| `scripts/test-migrator-manifest.sh` passes (12/12). | PASS |
| `scripts/test-migrator-core.sh` passes (19/19). | PASS |
| No state-changing git verbs run. | PASS |
| PM-only files untouched. | PASS |
| Trinity byte-identity preserved on HELP-FRAGMENT-TRACKER. | PASS |

## Deferred items

**None.** Everything in BD-135 scope landed in this session.

## Suggested follow-up (optional, not a hard requirement)

The historical reports under `maintenance-docs/v11-implementation/` (e.g., `IMPLEMENTATION-REPORT-BD-119-C{3,4,4b,5,6,7}.md`, `IMPLEMENTATION-REPORT-BD-114.md`, `PACK-REVIEW-CUMULATIVE-V11*.md`) and the v11 EXECUTION-PLAN reference the legacy basename. They are time-stamped historical artifacts — leaving them as-is correctly preserves the record at time of writing. If a future cleanup batch wants to update these for searchability, that would be a low-priority docs-hygiene BD; not required by BD-135.
