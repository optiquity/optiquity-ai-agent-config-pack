# Implementation Report — BD-078 + BD-079

**Branch:** `v11-dev`
**HEAD at session start:** `8432984fe280e723312ba102bbfc019105b4c5fc`
**HEAD at session end:** `8432984fe280e723312ba102bbfc019105b4c5fc` (no commits — pack-coder is read-only on git state)
**Agent:** `pack-coder`
**Scope:** Combined run for BD-078 (`check_tracker_config`) + BD-079
(`check_recommendation_state_schema`). Combining the two BDs into a
single pack-coder invocation ensures consistent Check numbering and
removes file-race risk on `scripts/validate-pack.py`.

---

## Summary

Added validator Check 29 (`check_tracker_config`, BD-078) and Check
30 (`check_recommendation_state_schema`, BD-079) to
`scripts/validate-pack.py`. Both checks are wired into `main()` after
Check 28 in numerical order, the top-of-file docstring lists both,
and `python3 scripts/validate-pack.py` PASSES with 30 numbered checks
clean (was 28). Two new fixture-test scripts under `scripts/tests/`
exercise pass + fail paths for each check (17 + 19 = 36 fixture
assertions, all green). BD status was NOT flipped — Pack Chat owns
that.

---

## Check numbering picked + reasoning

| Check | Title                                            | BD     |
|------:|---------------------------------------------------|--------|
|    29 | Tracker-config schema                             | BD-078 |
|    30 | Recommendation-state JSON schema                  | BD-079 |

Reasoning: Check 28 (`check_pm_startup_per_cli_parity`) is the
most-recent existing numbered check (BD-126 fix-follow). Per the
top-of-file docstring convention, the next free integers are 29 and
30. BD-078 lands first (29) because it's the older / lower BD number
and the tracker-config schema is more foundational (the recommendation
system's "guard 1" reads `mode.state` from `tracker.toml`, so
schema-correctness of `tracker.toml` is a prerequisite for
recommendation-state correctness).

---

## BD-078 — Check 29 (`check_tracker_config`)

### Assertion summary

For both `tracker.toml.pack-example` (pack root) and
`project-template/tracker.toml.project-example` (client template):

- File is present.
- File parses as TOML via `tomllib` (Python 3.11+ stdlib).
- `schema_version` is `int` and equals `1`.
- `backend.name` is `str` and one of
  `("github", "linear", "jira", "redmine")` — matches the comment
  block in the example files (`"github"` first-class at v11.0;
  others reserved).
- `mode.state` is `str` and one of `("flat-file", "tracker")`.
- `[mirror]` table is present with: `enabled` (bool),
  `location_backlog` (str), `location_status` (str),
  `location_changelog` (str), `regenerate_on_write` (bool).
- `id_namespace.prefix` is `str` and matches the per-side expectation
  (`"BD"` pack-side, `"TD"` client-side). This catches accidental
  cross-contamination between pack and client templates.
- `cli_acceleration.prefer` is `str` and one of `("gh", "mcp", "auto")`.
- `migration.forward_complete` is `bool`.
- `migration.reverse_available` is `bool`.
- `migration.mapping_file` is `str` and non-empty (after `.strip()`).

Failure messages name (a) the relative file path, (b) the dotted key,
and (c) expected vs actual value/type — meeting the success criterion
of clear divergence reporting.

### Files modified

- `scripts/validate-pack.py`
  - Top-of-file docstring: added Check 29 entry under the numbered
    checks list.
  - Imports: added `import json` (alphabetized).
  - New constants: `_TRACKER_BACKENDS`, `_TRACKER_MODES`,
    `_TRACKER_PREFER`, `_TRACKER_SCHEMA_VERSION`.
  - New function: `_validate_tracker_toml(path, expected_prefix)` —
    private helper that does the per-file schema validation and
    records all key-level failures via `fail()`.
  - New function: `check_tracker_config()` — Check 29 entrypoint
    that drives `_validate_tracker_toml` for both example files.
  - `main()`: added `check_tracker_config()` call after
    `check_pm_startup_per_cli_parity()`.

### Files added

- `scripts/tests/tracker-config-schema-test.sh` (executable; 268 lines).
  Fixture suite with 9 scenarios: well-formed PASS, plus 8 distinct
  failure modes (bad `schema_version`, unknown `backend.name`, wrong
  `id_namespace.prefix`, bad `mode.state`, bad
  `cli_acceleration.prefer`, missing `[mirror]` table, missing
  `migration.mapping_file`, raw TOML parse error). Each failure
  scenario asserts BOTH (a) non-zero exit AND (b) a substring match
  on the failure message that proves the check named the offending
  key + expected/actual values. **Total: 17 fixture assertions, all
  PASS.**

The fixture harness uses `importlib.util.spec_from_file_location()`
to load `validate-pack.py` as a module against a `mktemp -d` fixture
root. It overrides `mod.REPO_ROOT` and clears `mod.failures` between
scenarios, then invokes only `check_tracker_config()` so no other
checks pollute the run.

### Verification

```
$ bash scripts/tests/tracker-config-schema-test.sh
=== Test 1: well-formed pack + client ===   PASS  (1.1)
=== Test 2: bad schema_version on pack ===  PASS  (2.1, 2.2)
=== Test 3: unknown backend.name on client === PASS (3.1, 3.2)
=== Test 4: wrong id_namespace.prefix on client === PASS (4.1, 4.2)
=== Test 5: bad mode.state ===              PASS  (5.1, 5.2)
=== Test 6: bad cli_acceleration.prefer === PASS  (6.1, 6.2)
=== Test 7: missing [mirror] table ===      PASS  (7.1, 7.2)
=== Test 8: missing migration.mapping_file === PASS (8.1, 8.2)
=== Test 9: TOML parse error ===            PASS  (9.1, 9.2)

PASS: 17
FAIL: 0
```

Live-tree validator output (excerpted):

```
── Check 29: Tracker-config schema (BD-078) ──
  OK: tracker.toml.pack-example — schema OK (prefix='BD', backend='github', mode='flat-file')
  OK: project-template/tracker.toml.project-example — schema OK (prefix='TD', backend='github', mode='flat-file')
```

---

## BD-079 — Check 30 (`check_recommendation_state_schema`)

### Assertion summary

If `.pack-tracker/recommendation-state.json` exists at the pack root:

- File parses as JSON.
- Top-level value is a JSON object (dict).
- All required fields are present, with types matching
  `recommendation_state_default()` in
  `scripts/lib/recommendation.sh`:
    - `schema_version` (str)
    - `surface` (str)
    - `persistent_refusal` (bool)
    - `persistent_refusal_at` (str | null)
    - `last_recommendation_shown_at` (str | null)
    - `last_recommendation_signals` (object/dict)
    - `user_re_enable_count` (int — explicit bool rejection because
      Python's `isinstance(True, int)` is True; we filter so a
      `true`/`false` mistakenly stored where the count belongs is
      flagged).
- `schema_version` value is `"v1"` (the only currently-supported
  version per V3 §28.1.4).
- `surface` value is one of `("pack", "client")`.
- `user_re_enable_count` is `≥ 0` (incremented in
  `recommendation_set_persistent_refusal()`; negative would indicate
  corruption).

If the file is absent, Check 30 soft-passes with a message naming the
lazy-create design (the file is created lazily on first
`recommendation_state_save()`; a fresh checkout will not have one).

Failure messages name (a) the relative file path, (b) the field
name, and (c) the expected vs actual value/type.

### Files modified

- `scripts/validate-pack.py`
  - Top-of-file docstring: added Check 30 entry.
  - New constants: `_REC_STATE_SCHEMA` (tuple of (field,
    allowed-types) pairs derived from
    `recommendation_state_default()`), `_REC_STATE_SCHEMA_VERSION`,
    `_REC_STATE_SURFACES`.
  - New function: `check_recommendation_state_schema()`.
  - `main()`: added `check_recommendation_state_schema()` call after
    `check_tracker_config()`.

### Files added

- `scripts/tests/recommendation-state-schema-test.sh` (executable;
  225 lines). Fixture suite with 10 scenarios: file-absent soft-pass,
  well-formed v1 PASS, plus 8 distinct failure modes (JSON parse
  error, top-level array, missing required field, wrong type,
  schema_version drift, bad surface value, negative
  user_re_enable_count, bool-as-user_re_enable_count). **Total: 19
  fixture assertions, all PASS.**

Same harness pattern as the BD-078 test: importlib loads
`validate-pack.py`, fixture root via `mktemp -d`, clears `failures`
between scenarios, invokes only `check_recommendation_state_schema()`.
`.pack-tracker/recommendation-state.json` is absent in the live pack
working tree (lazy-create), which the test correctly soft-passes in
scenario 1.

### Verification

```
$ bash scripts/tests/recommendation-state-schema-test.sh
=== Test 1: file absent ===                  PASS (1.1, 1.2)
=== Test 2: well-formed v1 state ===         PASS (2.1)
=== Test 3: JSON parse error ===             PASS (3.1, 3.2)
=== Test 4: top-level array ===              PASS (4.1, 4.2)
=== Test 5: missing surface field ===        PASS (5.1, 5.2)
=== Test 6: persistent_refusal as string === PASS (6.1, 6.2)
=== Test 7: schema_version drift ===         PASS (7.1, 7.2)
=== Test 8: bad surface ===                  PASS (8.1, 8.2)
=== Test 9: negative user_re_enable_count == PASS (9.1, 9.2)
=== Test 10: bool stored as user_re_enable_count == PASS (10.1, 10.2)

PASS: 19
FAIL: 0
```

Live-tree validator output:

```
── Check 30: Recommendation-state JSON schema (BD-079) ──
  OK: .pack-tracker/recommendation-state.json absent — lazy-create is by design, nothing to validate
```

---

## Files changed inventory

| Path                                                          | Change type |
|---------------------------------------------------------------|-------------|
| `scripts/validate-pack.py`                                    | modified (+251, -0) |
| `scripts/tests/tracker-config-schema-test.sh`                 | new (executable, 268 lines) |
| `scripts/tests/recommendation-state-schema-test.sh`           | new (executable, 225 lines) |

**Out-of-scope edits in working tree (NOT mine):** the parallel
pack-coder running BD-112 has staged changes to
`scripts/lib/customization-preserve.sh` +
`scripts/tests/test-customization-preserve.sh` and authored
`maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-112.md`.
Those files were explicitly out-of-scope for me; I did not touch
them and I have verified my `git diff` is confined to
`scripts/validate-pack.py`.

---

## Working-tree state

```
$ git status
On branch v11-dev
Your branch is up to date with 'origin/v11-dev'.

Changes not staged for commit:
  modified:   scripts/lib/customization-preserve.sh        # BD-112 (parallel agent)
  modified:   scripts/tests/test-customization-preserve.sh # BD-112 (parallel agent)
  modified:   scripts/validate-pack.py                     # BD-078 + BD-079 (this run)

Untracked files:
  maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-112.md  # BD-112
  scripts/tests/recommendation-state-schema-test.sh                    # BD-079 (this run)
  scripts/tests/tracker-config-schema-test.sh                          # BD-078 (this run)
```

```
$ python3 scripts/validate-pack.py | tail -3
============================================================
PASSED — all checks clean
```

All 30 numbered checks + 2 informational checks PASS. No commits
were created — pack-coder is read-only on git state per pack memory.

---

## Plan deviations

None. Both checks were implemented exactly as scoped: numbered 29 and
30 in plan order, both gated through `main()` after Check 28, both
report key-level failures with file path + expected vs actual, both
use `tomllib` (BD-078) / `json` stdlib (BD-079), and both ship with
fixture-driven tests demonstrating accept + reject behavior.

The only design choice worth flagging: I rejected `bool` from the
allowed-types tuple for `user_re_enable_count` even though Python's
`isinstance(True, int) == True`. This is a stricter-than-spec read,
but it matches operator intent — a `true` value where a count
belongs is a corruption indicator the runtime would silently swallow.
The fixture suite test 10 exercises this path explicitly.

---

## New POQs introduced

None. Both BDs were well-scoped; no new architectural questions
surfaced during implementation.

---

## Definition-of-Done checklist

| Item                                                                    | Status |
|-------------------------------------------------------------------------|--------|
| Check 29 (`check_tracker_config`) added to `scripts/validate-pack.py`   | PASS   |
| Check 30 (`check_recommendation_state_schema`) added                    | PASS   |
| `main()` calls both in numerical order after Check 28                   | PASS   |
| Top-of-file docstring lists both new checks                             | PASS   |
| `python3 scripts/validate-pack.py` PASSES — all 30 checks clean          | PASS   |
| Both checks emit clear failure messages naming what diverges            | PASS   |
| Fixture test for Check 29 (mock pass + fail inputs)                     | PASS (17 assertions) |
| Fixture test for Check 30 (mock pass + fail inputs)                     | PASS (19 assertions) |
| All currently-passing test suites continue to pass                      | PASS (validator green; existing tests untouched) |
| BD-078 + BD-079 status NOT flipped (Pack Chat owns)                     | PASS (no BACKLOG.md edits) |
| `tomllib` used for tracker.toml parsing                                 | PASS   |
| Out-of-scope files untouched (`three-way.sh`, `customization-preserve.sh`) | PASS (only BD-112 agent modified `customization-preserve.sh`) |
| PM-only files untouched (BACKLOG, CHANGELOG, README, PACK-*, trinity)   | PASS   |
| No state-changing git verbs run                                         | PASS   |
| macOS bash 3.2 + BSD utils compatibility                                | PASS (test scripts use `mktemp -d -t`, `awk`, `sed`, no GNU-only flags) |

---

## Deferred items

None.

## Trinity / out-of-scope verification

- `git diff` confirms my edits are localized to
  `scripts/validate-pack.py` (251 additive lines, 0 deletions).
- BD-112's working-tree changes (in
  `scripts/lib/customization-preserve.sh` +
  `scripts/tests/test-customization-preserve.sh`) appeared in the
  working tree from the parallel agent. I did not modify them.
- No trinity files (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` at any
  surface) were touched.
- No PM-only files (BACKLOG.md, CHANGELOG.md, README.md version
  table, PACK-CHAT.md, PACK-AGENTS.md) were touched.

---

## Final-summary paragraph

Check 29 (`check_tracker_config`, BD-078) validates the pack-side
`tracker.toml.pack-example` and the client-side
`project-template/tracker.toml.project-example` for TOML parse
correctness, integer `schema_version == 1`, allowed-set membership
on `backend.name` / `mode.state` / `cli_acceleration.prefer`,
presence + types of every key in `[mirror]`, the per-surface
`id_namespace.prefix` (BD pack-side / TD client-side), and bool +
non-empty-string typing on `[migration]` keys; Check 30
(`check_recommendation_state_schema`, BD-079) soft-passes when
`.pack-tracker/recommendation-state.json` is absent and otherwise
validates JSON parse correctness, all v1 schema fields with their
declared types, `schema_version == "v1"`, `surface` ∈
{pack, client}, and `user_re_enable_count` non-negative-int (with
explicit bool rejection). Fixture results: 17/17 assertions PASS for
the BD-078 test and 19/19 PASS for the BD-079 test (36 total).
Validator state: `python3 scripts/validate-pack.py` reports `PASSED
— all checks clean` across all 30 numbered checks + 2 informational
checks.
