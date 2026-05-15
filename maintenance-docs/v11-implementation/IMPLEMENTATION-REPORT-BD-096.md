---
title: IMPLEMENTATION-REPORT-BD-096
author: pack-coder (v11-dev, Batch 16)
status: implementation complete; ready for Pack Chat stage + commit
date: 2026-05-14
---

# Implementation report — BD-096 Synthetic-fixture set (Batch 16)

**Branch / HEAD:** `v11-dev` @ `91e7563c172afed77d79f390c2452a1e6fd01342` (unchanged — agent did not commit, per pack rules).

## Files changed (inventory)

**Modified (1):**
- `scripts/tests/test-customization-preserve.sh` (+162 lines: new Group 8 driver for directory-based fixtures; existing Groups 1-7 byte-identical).

**New (78 fixture files + 1 README + 5 manifests + 5 assertions = 89 files):**

Top-level fixture README:
- `scripts/tests/fixtures/customization-preserve/README.md`

Per-fixture (`scripts/tests/fixtures/customization-preserve/<name>/`):

| Fixture | manifest.tsv rows | base/ files | ours/ files | theirs/ files | assertions.tsv rows |
|---|---|---|---|---|---|
| `lightly-customized-minimal/` | 5 | 4 | 5 | 4 | 1 |
| `heavily-customized/` | 11 | 6 | 11 | 6 | 9 |
| `language-heterogeneous/` | 6 | 4 | 6 | 5 | 5 |
| `custom-agents-heavy/` | 9 | 3 | 9 | 3 | 1 |
| `v10-with-customization/` | 5 | 3 | 5 | 3 | 7 |

Total fixture artifacts on disk: 91 (`find … -type f`).

## Per-fixture customization shape decisions

1. **`lightly-customized-minimal/`** — happy path. Trinity untouched (`unchanged-pack` x3), one project-only `x-` agent (`project-only-file`), one structured-config merge where both sides added separate allow-list entries (`merged-with-customization` via `merge-json.py`). Smallest fixture; proves the algorithm doesn't over-react when the project barely customizes.
2. **`heavily-customized/`** — worst-case. Trinity all 3 with project + pack edits → 3x `customization-detected-needs-reconciliation` with sidecars. Custom agents in all 3 CLI dirs + 1 `x-` script. Pack script `bootstrap.sh` with both edits → sidecar. JSON + TOML structured configs with merges. PM-CHAT.md with both edits → sidecar. Stresses every strategy code path.
3. **`language-heterogeneous/`** — multi-language project. `.gemini/.env` exercises the `_cp_strategy_gemini_env` key-union merge (project AGENT_CAPABILITIES with three languages wins; pack-new key adopted). Pack scripts: 2 `pack-update-applied`, 1 `merged-with-customization`, 1 `customization-detected-needs-reconciliation`. Plus 1 `x-grpc-coder` custom agent.
4. **`custom-agents-heavy/`** — focuses on the agent surface. 6 `x-` custom agents (2 per CLI), plus 3 pack agents driven through the 3 distinct dispositions: pack-edited+project-edited (sidecar), pack-edited only (copy), project-edited only (preserve). Validates that `custom-agent` vs `pack-agent` classification + their separate strategies work for all three CLIs.
5. **`v10-with-customization/`** — OT-modeled. Mirrors the inline Group 3 (XCODE_SCHEME + permissions JSON merge), Group 4 (ollama removal + lmstudio addition TOML merge), Group 5 (gemini-env key-union), trinity sidecar, and `x-ot-reviewer` custom agent — but as a directory-based fixture to give the OT shape parity with the other four.

**BD-088 OT preservation decision:** kept the inline TSV cases in Groups 1-7 byte-identical AND added the directory-based equivalent under `v10-with-customization/`. This is supplemental (not converted), so no coverage regression risk and the algorithmic unit-test surface in Groups 1-7 is preserved.

## Test runner extension approach

Extended the existing `scripts/tests/test-customization-preserve.sh` rather than creating a new runner. Rationale:
- The runner already sources the SUT libraries, defines `assert_eq` / `assert_contains` / `tsv_col` helpers, and integrates with CI (`.github/workflows/validate.yml` line 127-129).
- A second runner would duplicate setup boilerplate and require a parallel CI registration.
- Extension is a self-contained Group 8 that walks `FIXTURES_DIR` data-driven; new fixtures can be added without touching code.

The Group 8 driver:
1. Stages each fixture's `ours/` tree under a temp project root (mirrors how a real migration sees pre-update state).
2. Walks `manifest.tsv`, calling `customization_preserve` for each row with the manifest-pinned class.
3. Asserts the recorded disposition + class match expected (per-row).
4. Walks optional `assertions.tsv`, checking `dest`/`sidecar` file content for required substrings.
5. Renders the truthful report and asserts every manifest rel appears in it (BD-059 truthfulness contract).

Driver uses BSD `cp -R src/. dest/` (verified to copy hidden directories on Darwin) and bash 3.2-only constructs.

## Verification gate evidence

```
$ bash scripts/tests/test-customization-preserve.sh
=== Group 1: customization_classify ===
=== Group 2: text-strategy 4-case ===
=== Group 3: structured config (JSON) ===
=== Group 4: structured config (TOML) ===
=== Group 5: gemini-env preservation ===
=== Group 6: custom-agent / custom-script preservation ===
=== Group 6b: init guard for _CP_PACK_ROOT (B1) ===
=== Group 6c: BD-112 collision-safe flat naming ===
=== Group 7: truthful report ===
=== Group 8: BD-096 directory-based fixtures ===
=== Summary ===
Passed: 210
Failed: 0
All tests passed.
```

Baseline before changes: `Passed: 79 / Failed: 0`. New: `Passed: 210 / Failed: 0` (+131 tests; all green; all 5 fixtures fully exercised).

```
$ python3 scripts/validate-pack.py
… (Checks 1-31 plus 4 informational) …
PASSED — all checks clean
```

Same status as baseline (`91e7563` HEAD). No new checks added; no existing check regressed.

```
$ bash --version
GNU bash, version 3.2.57(1)-release (arm64-apple-darwin25)
```

Confirmed compatibility with macOS bash 3.2 + BSD utils target.

## Plan deviations

None. BD-096 spec called for 5 fixtures + README + runner exercising all 5 end-to-end; that is what shipped.

## New POQs introduced

None.

## Definition-of-Done checklist

| Item | Status |
|---|---|
| 5 fixture directories under `scripts/tests/fixtures/customization-preserve/` | PASS |
| Each fixture has realistic content (not empty placeholders) | PASS |
| `bash scripts/tests/test-customization-preserve.sh` PASSES end-to-end with all 5 fixtures exercised | PASS (210/210) |
| `python3 scripts/validate-pack.py` PASSES (all checks clean; no new checks) | PASS |
| Each fixture's customization shape documented (in fixture README) | PASS (`scripts/tests/fixtures/customization-preserve/README.md`) |
| Trinity rule N/A (no trinity files modified) | PASS (only test runner + fixtures touched) |
| Fixtures deterministic (no timestamps, no machine paths) | PASS |
| BD-088 OT-modeled fixture preserved (inline + directory equivalent) | PASS (Groups 1-7 byte-identical; `v10-with-customization/` added supplementally) |
| Phase-task fixtures NOT included (deferred to BD-106 in Batch 17) | PASS (none added) |
| No PM-only files modified (BACKLOG/CHANGELOG/README/PACK-CHAT/PACK-AGENTS/CLAUDE/AGENTS/GEMINI/EXECUTION-PLAN/RELEASE-GATE) | PASS |
| Agent did not commit (no `git add`/`commit`/`push`/`tag`) | PASS (HEAD unchanged at `91e7563`) |
| BD-096 status flip in BACKLOG.md left for Pack Chat | PASS (BACKLOG.md untouched per agent constraints) |

## Notes for Pack Chat

- BD-096 is ready for status flip (`Status: Open` → `Status: Resolved`, `Resolved: 2026-05-14, v11.0 — …`). Agents-never-commit rule + don't-touch-PM-only-files rule both prevent the agent from doing this.
- Files to stage: `scripts/tests/test-customization-preserve.sh` (modified) + `scripts/tests/fixtures/customization-preserve/` (89 new files). Confirmed via `git status`.
- CI will pick this up automatically: workflow already runs `bash scripts/tests/test-customization-preserve.sh`.

---

## Review fix cycle (F-1..F-9)

End-of-batch review (`maintenance-docs/v11-implementation/REVIEW-BD-096.md`,
target commit `4a5a6e5`) returned **REJECT-AND-RESPIN** — 1 BLOCKER + 4
SHOULD-FIX + 4 NIT. User approved fix-all (including F-5 option (a):
add a 6th fixture). All 9 findings addressed in this fix cycle. No
commit by the agent (per pack rules); Pack Chat stages + commits.

Fix-cycle base HEAD: `4a5a6e5fa8b78dd82ffb2c56d2d1a48fe66bd90d`.

### F-1 (BLOCKER) — `.gemini/.env` fixture files gitignored

**Fix:** Added an `!`-negation exception immediately after `.env` (line 38)
in root `.gitignore`:

```
!scripts/tests/fixtures/**/.env
```

**Verification:** All 4 `.env` files now untracked-not-ignored:

```
$ git ls-files --others --exclude-standard scripts/tests/fixtures/customization-preserve/ | grep '\.env'
scripts/tests/fixtures/customization-preserve/language-heterogeneous/ours/.gemini/.env
scripts/tests/fixtures/customization-preserve/language-heterogeneous/theirs/.gemini/.env
scripts/tests/fixtures/customization-preserve/v10-with-customization/ours/.gemini/.env
scripts/tests/fixtures/customization-preserve/v10-with-customization/theirs/.gemini/.env

$ git check-ignore scripts/tests/fixtures/customization-preserve/language-heterogeneous/ours/.gemini/.env; echo "exit=$?"
exit=1   # exit 1 = "not ignored" per git-check-ignore(1)
```

Note: `git check-ignore -v` on a file matching a negation pattern
prints the negation line (the `!`-rule), not empty output. The
dispositive "not ignored" check is the exit-code-1 from
`git check-ignore` (without `-v`) and the file's appearance in
`git ls-files --others --exclude-standard`. Both confirm the fix.

The narrowness of the exception is preserved: only files matching
`scripts/tests/fixtures/**/.env` are un-ignored. All other `.env`
files (project root, `.venv/.env`, etc.) remain ignored — the
security-relevant ignore rule is intact.

Pack Chat will run `git add -f` on the 4 `.env` files at staging
time per the prompt's instruction; the `-f` is technically not
required after the negation lands (the files are no longer
considered ignored), but using it is harmless and explicit.

**Files touched:** `.gitignore`.

### F-2 (SHOULD-FIX) — Negative-substring assertion type

**Design:** A leading `!` on an `assertions.tsv` substring inverts the
assertion. The runner detects `${a_sub:0:1} == "!"`, strips the `!`,
and switches from `assert_contains` to a manual `[[ "$content" != *"$sub_actual"* ]]`
check (since `assert_contains` is one-directional). Pass / fail output
mirrors `assert_contains` shape with "does NOT contain" wording so
test diffability is preserved.

Why a runtime sentinel rather than a separate column: keeps the schema
4-column-stable (matches manifest format), is opt-in per row, and
backward-compatible — existing positive-substring rows are unaffected.

**Fixture row added to** `v10-with-customization/assertions.tsv`:

```
.codex/config.toml	dest	!ollama	project removal of ollama honored
```

This guards the OT property "project intentionally removed
`[model_providers.ollama]` from `.codex/config.toml`" which the BD-088
`merge-toml.py` honors — a regression that re-adds ollama via union-
merge would now fail this assertion.

**Files touched:** `scripts/tests/test-customization-preserve.sh`
(assertion loop), `scripts/tests/fixtures/customization-preserve/v10-with-customization/assertions.tsv`,
`scripts/tests/fixtures/customization-preserve/README.md` (assertions
schema docs the `!` prefix).

### F-3 (SHOULD-FIX) — `lightly-customized-minimal` pack-side adoption assertion

**Fix:** Appended one row to `lightly-customized-minimal/assertions.tsv`:

```
.claude/settings.json	dest	pack-new-perm	pack allow-list addition adopted
```

Closes the symmetric coverage gap noted by reviewer (the `project-perm`
assertion confirmed project-side preservation; this adds the pack-side
adoption check).

**Files touched:**
`scripts/tests/fixtures/customization-preserve/lightly-customized-minimal/assertions.tsv`.

### F-4 (SHOULD-FIX) — `custom-agents-heavy` undertested dispositions

**Fix:** Appended three rows to `custom-agents-heavy/assertions.tsv`,
verbatim from reviewer's recommendation. All three substrings verified
present in the actual fixture file content:

```
$ grep -n "state-changing git verbs forbidden" scripts/tests/fixtures/customization-preserve/custom-agents-heavy/theirs/.codex/agents/pack-coder.md
8:- Never commits (state-changing git verbs forbidden).

$ grep -n "data-flow diagram" scripts/tests/fixtures/customization-preserve/custom-agents-heavy/ours/.gemini/agents/pack-architect.md
9:- Project addition: include data-flow diagram in every architecture doc.

$ grep -n "No implementation" scripts/tests/fixtures/customization-preserve/custom-agents-heavy/ours/.gemini/agents/pack-architect.md
8:- No implementation.
```

All three substrings exist; no substitution required.

The three rows together exercise:
- `pack-update-applied` (pack-coder.md) — dest must contain v11
  wording from theirs (the `cp "$theirs" "$dest"` strategy step).
- `merged-with-customization` (pack-architect.md, project edit
  preserved) — dest contains the project's `data-flow diagram`
  addition because the strategy records `preserved` and the runner
  pre-staged ours/ → dest, which the strategy doesn't overwrite.
- `merged-with-customization` (pack-architect.md, baseline content
  intact) — dest contains `No implementation` from base/ours common
  content (proves no surprise content drop on the preserve path).

**Files touched:**
`scripts/tests/fixtures/customization-preserve/custom-agents-heavy/assertions.tsv`.

### F-5 (SHOULD-FIX, option a) — 6th fixture `pack-retires-files/`

**Customization-shape decisions:**

The fixture exercises the four file-removal disposition pathways the
existing 5 fixtures all skip. Per BD-088's `_cp_disposition_for`
mapping, `removed-by-pack-clean` and `removed-by-pack-customized` both
collapse to the disposition token `removed-by-design`; the two are
distinguished by their action (`removed` for both) and by the
sidecar field (empty for clean, populated for customized).

| Manifest row                          | Triplet shape                | Recorded disposition           | Action / sidecar evidence |
|---------------------------------------|------------------------------|--------------------------------|---------------------------|
| `scripts/legacy-cleanup.sh`           | base ✓ ours == base ✓ theirs ✗ | `removed-by-design`            | dest removed; no sidecar (project never edited) |
| `scripts/legacy-bootstrap.sh`         | base ✓ ours edited ✓ theirs ✗ | `removed-by-design`            | dest removed; sidecar contains `project-legacy-bootstrap-edit` |
| `docs/pack/RETIRED-GUIDE.md`          | base ✓ ours ✗ theirs ✓        | `project-deleted-pack-kept`    | dest left absent (deletion honored); pack still ships |
| `scripts/old-helper.sh`               | base ✓ ours ✗ theirs ✗        | `removed-everywhere`           | no-op |

The `legacy-bootstrap.sh` sidecar substring assertion is the dispositive
check that the BD-088 algorithm correctly distinguishes the two
collapse-to-`removed-by-design` paths at the action layer (clean
removes silently; customized writes the sidecar).

`old-helper.sh` exercises the BASE-present + both-absent variant of
`removed-everywhere`. Group 2.x inline cases exercise the BASE-also-
absent variant via the `customization_preserve` early-return at
`scripts/lib/customization-preserve.sh:525`. The two paths converge on
the same disposition token but reach it through different code; this
fixture exercises the classifier path (base present), inline tests
exercise the early-return path (base absent).

**File content:** Realistic per pack convention. `legacy-cleanup.sh` and
`legacy-bootstrap.sh` are bash scripts mirroring the shape of pack-
shipped scripts (shebang + `set -euo pipefail` + an `echo` step).
`RETIRED-GUIDE.md` is markdown with H1 + Contents H2 in the trinity
shape. `old-helper.sh` mirrors the same script convention.

**Files created:**
- `scripts/tests/fixtures/customization-preserve/pack-retires-files/manifest.tsv` (4 rows)
- `scripts/tests/fixtures/customization-preserve/pack-retires-files/assertions.tsv` (1 row — sidecar substring check)
- `scripts/tests/fixtures/customization-preserve/pack-retires-files/base/scripts/legacy-cleanup.sh`
- `scripts/tests/fixtures/customization-preserve/pack-retires-files/base/scripts/legacy-bootstrap.sh`
- `scripts/tests/fixtures/customization-preserve/pack-retires-files/base/scripts/old-helper.sh`
- `scripts/tests/fixtures/customization-preserve/pack-retires-files/base/docs/pack/RETIRED-GUIDE.md`
- `scripts/tests/fixtures/customization-preserve/pack-retires-files/ours/scripts/legacy-cleanup.sh` (== base)
- `scripts/tests/fixtures/customization-preserve/pack-retires-files/ours/scripts/legacy-bootstrap.sh` (edited)
- `scripts/tests/fixtures/customization-preserve/pack-retires-files/theirs/docs/pack/RETIRED-GUIDE.md` (pack updated)

README updated with §6 entry per F-5 instruction.

### F-6 (NIT) — Field-count guard at runner loops

**Fix:** Added a guard immediately after the comment-/empty-row skip
case at both the manifest loop (~line 594 → now ~line 600) and the
assertion loop (~line 644 → now ~line 658). Required columns 1-3 must
be non-empty; `notes` (col 4) may be empty (per the column-position-
discipline rationale). Smoke-tested with a synthesized 2-column row
inline:

```
$ rel="foo.md" klass="generic" expected="" ; \
  if [[ -z "$rel" || -z "$klass" || -z "$expected" ]]; then echo "GUARD FIRED"; fi
GUARD FIRED
```

**Files touched:** `scripts/tests/test-customization-preserve.sh`.

### F-7 (NIT) — Auto-discovery loop replaces hard-coded fixture list

**Fix:** Replaced the explicit 5-fixture `for` list at `~line 687-693`
with `LC_ALL=C ls -d "$FIXTURES_DIR"/*/ 2>/dev/null | sort` over the
fixtures directory:

```bash
for fixture_path in $(LC_ALL=C ls -d "$FIXTURES_DIR"/*/ 2>/dev/null | sort); do
    [[ -d "$fixture_path" ]] || continue
    fixture=$(basename "$fixture_path")
    printf "\n--- 8.%s ---\n" "$fixture"
    run_fixture "$fixture"
done
```

`LC_ALL=C` + `sort` for deterministic ordering across hosts. Verified
the 6th fixture from F-5 was auto-picked-up without a code edit:

```
$ bash scripts/tests/test-customization-preserve.sh 2>&1 | grep -E "^--- 8\."
--- 8.custom-agents-heavy ---
--- 8.heavily-customized ---
--- 8.language-heterogeneous ---
--- 8.lightly-customized-minimal ---
--- 8.pack-retires-files ---
--- 8.v10-with-customization ---
```

Six fixtures, alphabetical ordering. README "How to add a fixture"
claim is now accurate.

**Files touched:** `scripts/tests/test-customization-preserve.sh`,
`scripts/tests/fixtures/customization-preserve/README.md` (intro
paragraph documents auto-discovery).

### F-8 (NIT) — `notes` column comment

**Fix:** Added explanatory comments at both the manifest loop (line ~594)
and the assertion loop (line ~644). Comment explains the column-
position-discipline rationale: `notes` is read for symmetry with the
manifest format and so future column additions don't ambiguate the
schema, but the runner does not assert on it.

**Files touched:** `scripts/tests/test-customization-preserve.sh`.

### F-9 (NIT) — Heavily-customized `dest` assertions for needs-reconciliation rows

**Fix:** Added 5 `dest` substring assertions to
`heavily-customized/assertions.tsv`, mirroring the existing sidecar
assertions for the 5 needs-reconciliation rows (CLAUDE.md, AGENTS.md,
GEMINI.md, bootstrap.sh, PM-CHAT.md). Each substring is unique to the
corresponding `theirs/` file (verified via `grep`):

```
$ grep -n "v11 addition" scripts/tests/fixtures/customization-preserve/heavily-customized/theirs/CLAUDE.md scripts/tests/fixtures/customization-preserve/heavily-customized/theirs/AGENTS.md scripts/tests/fixtures/customization-preserve/heavily-customized/theirs/GEMINI.md
… each file has line "## Pack workflow rules (v11 addition)" …

$ grep -n "step two (added in v11)" scripts/tests/fixtures/customization-preserve/heavily-customized/theirs/scripts/bootstrap.sh
5:echo "pack bootstrap step two (added in v11)"

$ grep -n "Pack workflow additions (v11)" scripts/tests/fixtures/customization-preserve/heavily-customized/theirs/docs/pack/PM-CHAT.md
11:## Pack workflow additions (v11)
```

For PM-CHAT.md the unique substring is `Pack workflow additions (v11)`
(the prompt's suggested `step two (added in v11)` is the bootstrap.sh
substring). The 5 rows together prove the `needs-reconciliation`
disposition correctly:
- writes `theirs/` content to dest (these new assertions), AND
- writes `ours/` content to sidecar (pre-existing assertions)

A regression that swaps the two would now fail at least 5 tests.

**Files touched:**
`scripts/tests/fixtures/customization-preserve/heavily-customized/assertions.tsv`.

### Updated verification gate evidence

```
$ bash scripts/tests/test-customization-preserve.sh
… (Groups 1-7 unchanged) …
=== Group 8: BD-096 directory-based fixtures ===
--- 8.custom-agents-heavy ---
--- 8.heavily-customized ---
--- 8.language-heterogeneous ---
--- 8.lightly-customized-minimal ---
--- 8.pack-retires-files ---
--- 8.v10-with-customization ---
=== Summary ===
Passed: 233
Failed: 0
All tests passed.
```

Pre-fix: `Passed: 210`. Post-fix: `Passed: 233` (+23 new tests:
F-3 +1, F-4 +3, F-5 +13 [4 disposition + 4 class + 1 sidecar
substring + 4 truthful-report], F-2 +1, F-9 +5).

```
$ python3 scripts/validate-pack.py
… (all checks) …
PASSED — all checks clean
```

No new validate-pack checks added; no existing check regressed.

```
$ git rev-parse HEAD
4a5a6e5fa8b78dd82ffb2c56d2d1a48fe66bd90d   # unchanged — agent did not commit
```

### `git status` after fix cycle

```
modified:   .gitignore
modified:   scripts/tests/fixtures/customization-preserve/README.md
modified:   scripts/tests/fixtures/customization-preserve/custom-agents-heavy/assertions.tsv
modified:   scripts/tests/fixtures/customization-preserve/heavily-customized/assertions.tsv
modified:   scripts/tests/fixtures/customization-preserve/lightly-customized-minimal/assertions.tsv
modified:   scripts/tests/fixtures/customization-preserve/v10-with-customization/assertions.tsv
modified:   scripts/tests/test-customization-preserve.sh

Untracked files:
    maintenance-docs/v11-implementation/REVIEW-BD-096.md   # pre-existing (review doc)
    scripts/tests/fixtures/customization-preserve/language-heterogeneous/ours/.gemini/
    scripts/tests/fixtures/customization-preserve/language-heterogeneous/theirs/.gemini/
    scripts/tests/fixtures/customization-preserve/pack-retires-files/
    scripts/tests/fixtures/customization-preserve/v10-with-customization/ours/.gemini/
    scripts/tests/fixtures/customization-preserve/v10-with-customization/theirs/.gemini/
```

The 4 `.gemini/` parent directories now appear because their `.env`
contents are no longer ignored (F-1 fix). The 4 `.env` files within
will be staged by Pack Chat at commit time.

### Files inventory (fix cycle delta)

**Modified (7):**
- `.gitignore` (+3 lines: `!`-negation exception per F-1)
- `scripts/tests/test-customization-preserve.sh` (+~50 lines net: F-2
  negative-substring branch, F-6 field-count guards x2, F-7 auto-
  discovery, F-8 column-discipline comments x2)
- `scripts/tests/fixtures/customization-preserve/README.md` (intro
  + assertion schema `!` docs + new §6 for `pack-retires-files/`)
- `…/lightly-customized-minimal/assertions.tsv` (+1 row, F-3)
- `…/custom-agents-heavy/assertions.tsv` (+3 rows, F-4)
- `…/v10-with-customization/assertions.tsv` (+1 row, F-2 with `!`)
- `…/heavily-customized/assertions.tsv` (+5 rows, F-9)

**New (9 — for F-5 fixture):**
- `…/pack-retires-files/manifest.tsv`
- `…/pack-retires-files/assertions.tsv`
- `…/pack-retires-files/base/scripts/legacy-cleanup.sh`
- `…/pack-retires-files/base/scripts/legacy-bootstrap.sh`
- `…/pack-retires-files/base/scripts/old-helper.sh`
- `…/pack-retires-files/base/docs/pack/RETIRED-GUIDE.md`
- `…/pack-retires-files/ours/scripts/legacy-cleanup.sh`
- `…/pack-retires-files/ours/scripts/legacy-bootstrap.sh`
- `…/pack-retires-files/theirs/docs/pack/RETIRED-GUIDE.md`

Plus the 4 pre-existing `.env` files now becoming trackable (no new
content; just no longer ignored): `language-heterogeneous/{ours,theirs}/.gemini/.env`
and `v10-with-customization/{ours,theirs}/.gemini/.env`.

### Plan deviations (fix cycle)

None. All 9 findings addressed per reviewer's recommended fix or per
the user-approved option choice (F-5 option (a)). For F-9, PM-CHAT.md
needed substring `Pack workflow additions (v11)` rather than the
prompt's suggested `v11 addition` (the latter was already used for
trinity files; PM-CHAT.md's parallel content uses different wording).
This is documented in F-9 above and is a verbatim string match against
existing fixture content — no fixture edits.

### New POQs introduced (fix cycle)

None.

### Definition-of-Done checklist (fix cycle)

| Item | Status |
|---|---|
| F-1: `.gitignore` exception added; 4 `.env` files no longer ignored | PASS (`git ls-files --others --exclude-standard` shows all 4) |
| F-2: negative-substring assertion type implemented + documented + used | PASS (1 row in v10-with-customization; runner `!` branch; README §"Assertions format") |
| F-3: lightly-customized-minimal pack-side adoption assertion | PASS (+1 row) |
| F-4: 3 custom-agents-heavy assertions | PASS (+3 rows; substrings verified by grep) |
| F-5(a): 6th `pack-retires-files/` fixture exercises 4 removal dispositions | PASS (4 manifest rows + 1 sidecar assertion + 7 fixture content files; all rows pass) |
| F-6: field-count guards at manifest + assertion loops | PASS (smoke-tested; existing rows unaffected) |
| F-7: auto-discovery replaces hard-coded fixture list | PASS (6 fixtures alphabetical; no runner edit needed for F-5 6th fixture) |
| F-8: column-discipline comment near both loops | PASS (2 comments added) |
| F-9: 5 dest assertions for heavily-customized needs-reconciliation rows | PASS (+5 rows; substrings verified by grep) |
| All 9 findings addressed | PASS |
| `bash scripts/tests/test-customization-preserve.sh` PASSES | PASS (233/233; was 210/210) |
| `python3 scripts/validate-pack.py` PASSES | PASS (no new checks; no regression) |
| `git status` matches expected pattern from prompt §"Verification" | PASS |
| HEAD unchanged (agent did not commit) | PASS (`4a5a6e5`) |
| No PM-only file edits | PASS (only `.gitignore` + runner + fixture-internal README + assertions + new fixture) |
