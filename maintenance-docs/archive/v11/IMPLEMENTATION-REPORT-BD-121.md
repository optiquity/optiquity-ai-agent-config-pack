# IMPLEMENTATION REPORT — BD-121 (v9 sunset)

**Branch:** worktree-agent-acc599b3c89f54a6a
**Final HEAD SHA:** 01ecadd7601dc2ae043f85dccc43c70423ed807e (unchanged — agent does not commit)
**Date:** 2026-05-08

## Tool-environment caveat

The Edit and Write tools failed silently for files inside this worktree
on this run: every Edit returned "success" and Read showed updated
content, but `git diff` confirmed nothing reached disk. Write to /tmp
worked; Write inside the worktree did not. The four file deletions
(via Bash `rm` / `rm -rf`) DID reach disk normally.

To complete the task, all in-worktree edits were performed via Bash
(`awk` / `sed -i ''`) with verification through `git diff` and
`bash -n` / `python3 -c 'import ast; ast.parse(...)'` after each
change. The report itself was written via Write to `/tmp/` then
`cp`'d into the worktree (Write to worktree silently failed on
this run too).

## Pre-flight (verbatim)

```
/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-acc599b3c89f54a6a
01ecadd7601dc2ae043f85dccc43c70423ed807e
worktree-agent-acc599b3c89f54a6a
01ecadd docs: v11 — BD-121 correction: remove forbidden CHANGELOG mid-version edit step
63a096c feat: v11 — flip BD-115 + BD-119 to Resolved (Batch 8a closed; persona-coverage infra + N→N+1 migrator framework)
79f3aef fix: v11 — BD-119 fix-follow: B1 BLOCKER + S1..S5 SHOULD-FIX (Batch 8a review)
17a0cda docs: v11 — pack-reviewer report for BD-115 + BD-119 (1 BLOCKER, 5 SHOULD-FIX, 3 NICE-TO-HAVE)
d2cd9b4 docs: v11 — BD-119 C-7: migrator-framework doc refresh
861c158 refactor: v11 — BD-119 C-6: cut migrate-v10-to-v11.sh over to framework adapter
9f9f052 feat: v11 — BD-119 C-5: behavior-preservation harness (mandatory pre-C-6 gate)
3724d72 docs: v11 — reshape BD-114 for public usability + open BD-125 companion doc
0532526 docs: v11 — clarify BD-116 sequencing note + expand BD-121 scope (validate-pack + supporting-docs ripple)
23b0cb0 feat: v11 — BD-119 C-4b: add test-migrator-core.sh (T-12 unit tests; closes POQ-6)
---fixtures---
build-migration-fixture.sh
migration-v9.3-empty
migration-v9.3-marker-convention
migration-v9.3-pattern-coverage
---scripts---
scripts/migrate-v9-to-v10.sh
scripts/test-migration.sh
---v9 docs---
MIGRATION-v8-to-v9.md
MIGRATION-v9-to-v10.md
---BD-121---
2
```

All preconditions met (HEAD at 01ecadd; v9 fixtures present; both
v9 scripts present; MIGRATION-v9-to-v10.md present; BD-121 entry
appears twice in BACKLOG.md).

## Audit — `scripts/lib/` v9-only vs. shared

Task plan step 1: determine which library files are v9-exclusive
versus shared with the v10→v11 framework.

### Source-statement audit

```
$ grep -E "^source |^\\. " scripts/migrate-v9-to-v10.sh
source "$SCRIPT_DIR/lib/detect.sh"
source "$SCRIPT_DIR/lib/three-way.sh"

$ grep -E "^source |^\\. " scripts/migrate-v10-to-v11.sh
. "$SCRIPT_DIR/lib/migrator-core.sh"
```

The v9 migrator only directly sources `detect.sh` and `three-way.sh`.

### Per-lib consumer audit

| Lib file | Non-v9 consumers found |
|---|---|
| `detect.sh` | migrate-v10-to-v11.sh, validate-pack.py, init-project.sh, test-detect.sh, add-capability.sh, tests/test-init-project.sh, tests/test-migrate-v10-to-v11.sh, lib/migrator-core.sh |
| `three-way.sh` | test-migrator-manifest.sh, test-restore-from-backup.sh, validate-pack.py, init-project.sh, merge-trinity.py, lib/customization-preserve.sh, lib/migrator-stages.sh |
| `customization-preserve.sh` | test-migrator-manifest.sh, init-project.sh, validate-pack.py, tests/test-customization-preserve.sh, lib/customization-report.sh, lib/migrator-stages.sh, .github/workflows/validate-pack.yml |
| `customization-report.sh` | test-migrator-manifest.sh, init-project.sh, validate-pack.py, tests/test-customization-preserve.sh, lib/migrator-stages.sh, lib/customization-preserve.sh |
| `recommendation.sh` | pack-tracker.sh, tests/recommendation-test.sh |
| `template-translations.sh` | tracker-migrate.sh, pack-tracker.sh, tests/template-translations-test.sh |
| `template-version.sh` | tracker-migrate.sh, pack-tracker.sh, tests/{template-version-test.sh,template-translations-test.sh}, lib/tracker-sidecar.sh |
| `migrator-{core,stages,manifest}.sh` | test-migrator-{core,manifest}.sh, migrate-v10-to-v11.sh, validate-pack.py, .github/workflows/validate-pack.yml, lib/* (BD-119 framework) |
| All `tracker-*.sh` | tracker-migrate.sh, pack-tracker.sh, tests/tracker-*-test.sh |

### Verdict

**Zero `scripts/lib/*.sh` files are v9-exclusive.** Every lib file
has non-v9 consumers (migrate-v10-to-v11.sh, the BD-119 framework,
init-project.sh, pack-tracker.sh, or test scripts). The "4 merge
helpers" mentioned in BD-121's BACKLOG entry refer to four `.py`
files in `scripts/` (not `scripts/lib/`): `merge-trinity.py`,
`merge-platform-skills.py`, `merge-json.py`, `merge-toml.py`. Three
of these (`merge-trinity.py`, `merge-toml.py`, `merge-json.py`) are
also referenced by `customization-preserve.sh` and `init-project.sh`
in v11; `merge-platform-skills.py` was not found in the repo at all
(grep returned no hits anywhere), suggesting it was already retired
or never landed under that exact name.

**No deletions in `scripts/lib/` or `scripts/merge-*.py` performed.**
This is the expected outcome of a careful audit, consistent with
the BACKLOG entry's contingent phrasing ("audit — keep if used by
v10→v11 migrator, delete if v9-exclusive").

## File-by-file disposition

### Deleted (4 paths; 19 tracked entries)

| Path | Reason |
|---|---|
| `scripts/migrate-v9-to-v10.sh` | v9→v10 migrator; v9 sunset (BD-121) |
| `scripts/test-migration.sh` | v9 migrator regression harness; sunset with the migrator |
| `maintenance-docs/test-fixtures/` (recursive; 16 files) | v9.3 fixture set used only by `test-migration.sh` |
| `supporting-docs/MIGRATION-v9-to-v10.md` | v9→v10 user-facing migration guide |

Total: 4801 line deletions across 19 tracked files (per `git diff
--stat`).

### Modified

| Path | Summary |
|---|---|
| `scripts/validate-pack.py` | Header docstring: added "Checks 12-15 retired" callout in Check 9 description. `REQUIRED_BD044_DOCS`: removed v9 entry, added retirement comment. Check 9 sub-step (e): replaced BD-059 test-migration harness assertion with retirement comment. Removed function bodies for `check_three_way_helper_present`, `check_merge_helpers_consistent`, `check_disposition_table_documented`, `check_migration_test_runs_clean` (lines 693-822); replaced with a 22-line block-comment explaining the retirement. Removed the four caller lines from `main()`. Updated the stale comment inside `check_tool_config_capability_parity` referencing the v9 migrator's .env handling. Updated the docstring inside `check_gitignore_env_example_exception` referencing the v9 migrator's S0 step. Net: −150 lines (1832 → 1682). |
| `supporting-docs/MIGRATION-v10-to-v11.md` | 3 references rewritten: pre-flight v9.x guidance now points to recovery via `git checkout v10`; exit-code-13 row drops "if you're on v9.x, run migrate-v9-to-v10.sh first"; BD-059 lessons-learned paragraph reframes the migrator as "the historical v10 migrator (the v9→v10 script, sunset in v11 per BD-121)". |
| `supporting-docs/SETUP-NEW.md` | 4 references rewritten: intro paragraph routes upgraders to MIGRATION-v10-to-v11.md and notes v9 sunset; existing-config STOP message routes to generic `MIGRATION-vN-to-vM.md` with v9 sunset note; gitignore rationale now describes generic `migrate-vN-to-vM.sh` backup pattern; "Upgrading later" list rewritten with v10→v11 as the supported path. |
| `supporting-docs/INSTALL-PROCEDURES.md` | 2 references rewritten + 2 historical-banner additions: (1) shipping-source paragraph names the active migrator generically. (2) "Pack-controlled deletions skip x-*" bullet generalized to `migrate-vN-to-vM.sh`. (3) Procedure 5-C now opens with a HISTORICAL banner explaining the v9 sunset; body retained as historical narrative. (4) Procedure 5-S given the same HISTORICAL banner. The remaining 4 inline `migrate-v9-to-v10.sh` references are in the bodies of those historical procedures and are correct as historical text. |
| `scripts/init-project.sh` | 2 references rewritten: (1) the user-facing "already-configured STOP" message previously routed to migrate-v9-to-v10.sh; now routes to "the migrator for your current → target version (e.g. scripts/migrate-v10-to-v11.sh ...)" and notes v9 sunset. (2) The internal stale-root cleanup comment generalized; v9 migrator removal mentioned in past tense. |
| `README.md` | 2 references rewritten in Repository Layout: MIGRATION-v9-to-v10.md row replaced with sunset note pointing to git-history recovery; migrate-v9-to-v10.sh row replaced with same. The v10.0 changelog row (line 61) is historical and was not modified. |
| `test-fixtures/manifest.txt` | INCIDENTAL — modified by `bash scripts/test-migrator-behavior-preservation.sh` during verification. The harness rebuilds fixtures and updates this file. NOT a BD-121 change; Pack Chat may discard via `git checkout -- test-fixtures/manifest.txt` if desired. |

### Audited, no change

| Path | Why |
|---|---|
| `.github/workflows/validate-pack.yml` | grep for `test-migration` / `migrate-v9` returned no matches; no v9-only step to remove. |
| `scripts/lib/*.sh` | All 23 lib files have non-v9 consumers; none are v9-exclusive. See audit above. |
| `scripts/merge-trinity.py` / `merge-toml.py` / `merge-json.py` | Each has `migrate-v9-to-v10.sh` mentioned in a docstring comment; these helpers are still consumed by `customization-preserve.sh` / `init-project.sh` in v11. Comment-only refs are non-load-bearing; left in place to keep the diff focused. |
| `scripts/lib/three-way.sh` line 3 docstring | "Sourced by migrate-v9-to-v10.sh (and any future migration script)" — historical and forward-compatible; not a defect. |
| `scripts/lib/detect.sh` line 3 docstring | "Sourced by init-project.sh, migrate-v9-to-v10.sh, and add-capability.sh" — has-been-true comment; not a defect. |
| `scripts/test-migrator-core.sh` line 18 | Header docstring example mentions "from=v9 → migrate-v9-to-v10.sh"; the actual test cases never exercise from=v9, so the test still passes after deletion. Left as historical doc. |
| `scripts/lib/tracker-migrate-forward.sh` line 215 | Comment references the v9→v10 migrator; non-load-bearing historical context. |
| `scripts/add-capability.sh` line 18 | Comment-block describes the contract honored by both init-project and the (historical) v9 migrator; non-load-bearing. |
| `CHANGELOG.md` | Per BD-121 BACKLOG entry: NOT modified mid-version. Will be summarized in v11.0 release entry. |
| Trinity files (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` root + project-template/) | Not touched in this BD; trinity rule N/A. |

## Diffs

Diffs are large (4801 deletions plus ~150 lines of source edits).
Rather than embedding them inline, see `git diff` against the
baseline `01ecadd` for the full set. Key surface checks:

```
$ git diff --stat 01ecadd -- scripts/validate-pack.py
 scripts/validate-pack.py | 305 ++++------------------ ...
$ git diff --stat 01ecadd -- supporting-docs/
 supporting-docs/INSTALL-PROCEDURES.md   |  29 +++++++++--
 supporting-docs/MIGRATION-v10-to-v11.md |  20 +++++--
 supporting-docs/SETUP-NEW.md            |  18 ++++++--
 supporting-docs/MIGRATION-v9-to-v10.md  | 858 -------------------------------
$ git diff --stat 01ecadd -- README.md scripts/init-project.sh
 README.md                |  9 ++++++---
 scripts/init-project.sh  | 14 +++++++++-----
```

(Pack Chat: run `git diff 01ecadd -- <path>` for the full unified
diff of any modified file. The agent did not embed full unified
diffs because the report is meant to be reviewable; the working
tree IS the source of truth.)

## Files staged for deletion (Pack Chat to `git add -u`)

```
maintenance-docs/test-fixtures/build-migration-fixture.sh
maintenance-docs/test-fixtures/migration-v9.3-empty/README.md
maintenance-docs/test-fixtures/migration-v9.3-marker-convention/README.md
maintenance-docs/test-fixtures/migration-v9.3-marker-convention/overlay/docs/pack/PLATFORM-SKILLS.md
maintenance-docs/test-fixtures/migration-v9.3-pattern-coverage/README.md
maintenance-docs/test-fixtures/migration-v9.3-pattern-coverage/overlay/.claude/agents/coder.md
maintenance-docs/test-fixtures/migration-v9.3-pattern-coverage/overlay/.claude/settings.json
maintenance-docs/test-fixtures/migration-v9.3-pattern-coverage/overlay/.claude/skills/swift-best-practices/SKILL.md
maintenance-docs/test-fixtures/migration-v9.3-pattern-coverage/overlay/.claude/skills/swift-best-practices/notes.md
maintenance-docs/test-fixtures/migration-v9.3-pattern-coverage/overlay/.codex/config.toml
maintenance-docs/test-fixtures/migration-v9.3-pattern-coverage/overlay/AGENTS.md
maintenance-docs/test-fixtures/migration-v9.3-pattern-coverage/overlay/CLAUDE.md
maintenance-docs/test-fixtures/migration-v9.3-pattern-coverage/overlay/GEMINI.md
maintenance-docs/test-fixtures/migration-v9.3-pattern-coverage/overlay/docs/pack/PM-CHAT.md
maintenance-docs/test-fixtures/migration-v9.3-pattern-coverage/overlay/scripts/format.sh
maintenance-docs/test-fixtures/migration-v9.3-pattern-coverage/overlay/scripts/x-fixture.sh
scripts/migrate-v9-to-v10.sh
scripts/test-migration.sh
supporting-docs/MIGRATION-v9-to-v10.md
```

## Verification

### Syntax checks

```
$ bash -n scripts/init-project.sh
(no output — pass)
$ python3 -c "import ast; ast.parse(open('scripts/validate-pack.py').read()); print('OK')"
OK
```

### `python3 scripts/validate-pack.py` — last 12 lines

```
── Check 25: Customization-detection regression guard (BD-089) ──
  OK: 4/4 fixture rows recorded with expected disposition + class
  OK: truthful-report contract: every fixture file appears in report.md

── Check 26: BD-119 migrator-framework inventory ──
  OK: scripts/lib/migrator-core.sh syntax valid
  OK: scripts/lib/migrator-stages.sh syntax valid
  OK: scripts/lib/migrator-manifest.sh syntax valid
  OK: migrator-core.sh declares all 6 public-API functions
  OK: migrator-core.sh declares all 8 exit-code constants
  OK: migrator-core.sh preserves EXIT_NOT_V10 back-compat synonym

============================================================
PASSED — all checks clean
```

### Regression test suites (one-line summaries)

```
$ bash scripts/test-migrator-core.sh   →  === Results: 19 passed, 0 failed ===
$ bash scripts/test-migrator-manifest.sh   →  === Results: 12 passed, 0 failed ===
$ bash scripts/test-migrator-behavior-preservation.sh   →  === Results: 15 passed, 0 failed ===
$ bash scripts/test-detect.sh   →  === Results: 40 passed, 0 failed ===
```

All four suites green. Aggregate: 86/86 pass, 0 fail.

## Plan deviations

**Step 2 (Delete v9-only `scripts/lib/` files):** No deletions
performed. Audit found zero v9-exclusive lib files. This is
consistent with BD-121's contingent wording ("audit — keep if used
by v10→v11 migrator, delete if v9-exclusive"). The "4 merge helpers"
phrase in the BACKLOG turned out to refer to `scripts/merge-*.py`,
not `scripts/lib/`. Three of those four .py helpers (`merge-trinity`,
`merge-toml`, `merge-json`) have v11 consumers (`customization-
preserve.sh`); the fourth (`merge-platform-skills.py`) does not
exist in the current tree. No `scripts/merge-*.py` deletions
performed.

**Check renumbering:** Per the BACKLOG plan ("Renumber subsequent
checks if numbering must stay sequential, otherwise leave gaps"),
chose to LEAVE GAPS at 12-15. Rationale: validate-pack.py already
has gaps (15→17, 17→20) so existing convention is gap-tolerant;
renumbering would invalidate cross-references in BACKLOG entries
and archive docs that cite specific check numbers.

## New POQs introduced

**POQ-BD121-1 (caveat for Pack Chat):** The Edit / Write tools
silently failed for in-worktree paths in this session. All edits
were performed via Bash (`awk` / `sed -i ''`). Pack Chat should
verify the working tree matches the per-file dispositions table
above by running `git diff 01ecadd -- <path>` for each modified
file before staging. This is a session-local issue; it does not
indicate a defect in the BD-121 changes themselves.

## Definition of Done checklist

| Item | Status |
|---|---|
| All v9 paths gone (`scripts/migrate-v9-to-v10.sh`, `scripts/test-migration.sh`, `maintenance-docs/test-fixtures/`, `supporting-docs/MIGRATION-v9-to-v10.md`) | PASS |
| `validate-pack.py` green | PASS (28→24 active checks; 4 retired with explanatory block-comment) |
| `supporting-docs/` updated (MIGRATION-v10-to-v11, SETUP-NEW, INSTALL-PROCEDURES) | PASS |
| README.md Repository Layout updated for deleted paths | PASS |
| `scripts/init-project.sh` user-facing v9 routing message updated | PASS |
| `.github/workflows/validate-pack.yml` audited (no v9-only step found) | PASS |
| No CHANGELOG edit | PASS |
| Existing v10/v11 tests still green (test-migrator-core 19/19, test-migrator-manifest 12/12, test-migrator-behavior-preservation 15/15, test-detect 40/40) | PASS |
| `bash -n` on every modified shell script | PASS (init-project.sh) |
| `python3 -c 'import ast; ast.parse(...)'` on every modified Python file | PASS (validate-pack.py) |

## Proposed commit message

```
feat: v11 — BD-121 sunset v9 migration infrastructure
```
