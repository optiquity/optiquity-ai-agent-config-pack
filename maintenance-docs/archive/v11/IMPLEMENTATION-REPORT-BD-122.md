# IMPLEMENTATION-REPORT-BD-122

BD-122 — Document `test-fixtures/` `<vN>-<persona>` versioning convention.

## 1. Branch + final HEAD SHA

- Branch: `v11-dev`
- HEAD SHA (worktree base, unchanged — pack-coder does not commit):
  `240867dea828224bd92dd28943dca9aa5c18f92e`

## 2. Pre-flight check output

```
$ git rev-parse HEAD
240867dea828224bd92dd28943dca9aa5c18f92e

$ git status
On branch v11-dev
Your branch is up to date with 'origin/v11-dev'.

nothing to commit, working tree clean

$ ls test-fixtures/
build.sh
manifest.txt
README.md

$ grep -n "BD-122" BACKLOG.md
1251:Unblocks: BD-122 (test-fixtures convention doc no longer has to disambiguate from a live v9 system)
1306:**BD-122 — Document `test-fixtures/` `<vN>-<persona>` versioning convention**
```

State at session start matched the prompt: clean v11-dev tree at the
expected base SHA, BD-122 entry present in BACKLOG.md, `test-fixtures/`
directory present with the three expected files (build.sh, manifest.txt,
README.md). Note: the live fixture subdirectories (`v10-minimal/`, etc.)
are gitignored per the README's "Why fixtures are gitignored" section,
so their absence from `ls` is expected — they are not committed and
were not needed for this docs-only task.

## 3. Per-task summary

Single task, single file.

- `test-fixtures/README.md` — `+47 / -7` (1 file changed, 47 insertions,
  7 deletions per `git diff --stat`). Three behavior changes landed:

  1. The "Available fixtures" table gained a new **Versioning** column
     (second column, between Name and Pack source). Each existing row
     was updated with one of three values: `v10-pinned`, `v11-pinned`,
     or `version-agnostic`. This surfaces the version-pinning per row
     without restructuring the table.
  2. A new **Naming convention** section was added immediately after the
     fixture table. Two bullets: `<vN>-<persona>` for version-pinned
     fixtures (anchors to a tag or HEAD; persona names the shape), and
     bare hyphenated descriptors for version-agnostic fixtures. Closes
     with a one-line picker rule (snapshot of pack output → version-
     pinned; input to the pack → version-agnostic).
  3. A new **When to add a fixture here vs. elsewhere** section was
     added immediately after Naming convention. Two paragraphs: when to
     promote (multi-consumer or persona/baseline with documentation
     value beyond one test) vs. when to keep inline (single-use,
     trivially derivable, lives within `mktemp -d` scope of one test).

Existing sections (Quick start, How fixtures are used by tests,
Determinism, Why fixtures are gitignored, Adding a new fixture, See
also) are untouched.

## 4. Full file contents and unified diffs

Modified file diff (against worktree base
`240867dea828224bd92dd28943dca9aa5c18f92e`):

```diff
diff --git a/test-fixtures/README.md b/test-fixtures/README.md
index 6cb391f..bca5ba2 100644
--- a/test-fixtures/README.md
+++ b/test-fixtures/README.md
@@ -23,13 +23,53 @@ bash test-fixtures/build.sh --verify

 ## Available fixtures

-| Name | Pack source | What it is | Use case |
-|---|---|---|---|
-| `v10-minimal` | pack at `v10` tag | Bare v10 install via `init-project.sh`; no customizations | Control fixture for migrator tests; the "what does the migrator do to a vanilla v10?" baseline |
-| `v10-realistic-ot` | pack at `v10` tag | Fake-OT shape: project-name fills (`FakeOT`); x-prefixed custom agent on Claude/Codex/Gemini; `.codex/config.toml` `model_providers.ollama` removed; 5-entry TD-* `BACKLOG.md`; trinity v10 self-label intact | Realistic OT-style migration test; exercises BD-088 customization-preservation against shapes a real client would have |
-| `v11-flat-file` | pack at current `HEAD` | v11 install via current `init-project.sh`; no `tracker.toml`; flat-file BACKLOG | "Vanilla v11 client" — what most users have on day 1 of v11. Use for tracker-init dog-food. |
-| `v11-tracker-on` | pack at current `HEAD` | v11 install + `tracker.toml` with `mode.state = "tracker"` and `migration.forward_complete = true` set by hand (no live GH state) | Code-path testing for tracker-aware logic without round-tripping through real GH. |
-| `existing-project-mid-dev` | none — synthesized | Realistic in-progress Swift+Python+gRPC project: `Package.swift`, `Sources/AcmeWidget/`, `Tests/AcmeWidgetTests/`, `proto/catalog.proto`, `service/` (Python tooling), top-level `README.md`, `.gitignore`, and 3 commits of pre-existing project history. Contains **zero** pack files (no `.claude/`, `.codex/`, `.gemini/`, `CLAUDE.md`/`AGENTS.md`/`GEMINI.md`, no pack scripts). | Input fixture for the BD-116 "init --update on top of an existing project" persona contract. Version-agnostic — same fixture serves v11, v12, … (BD-115). |
+| Name | Versioning | Pack source | What it is | Use case |
+|---|---|---|---|---|
+| `v10-minimal` | v10-pinned | pack at `v10` tag | Bare v10 install via `init-project.sh`; no customizations | Control fixture for migrator tests; the "what does the migrator do to a vanilla v10?" baseline |
+| `v10-realistic-ot` | v10-pinned | pack at `v10` tag | Fake-OT shape: project-name fills (`FakeOT`); x-prefixed custom agent on Claude/Codex/Gemini; `.codex/config.toml` `model_providers.ollama` removed; 5-entry TD-* `BACKLOG.md`; trinity v10 self-label intact | Realistic OT-style migration test; exercises BD-088 customization-preservation against shapes a real client would have |
+| `v11-flat-file` | v11-pinned | pack at current `HEAD` | v11 install via current `init-project.sh`; no `tracker.toml`; flat-file BACKLOG | "Vanilla v11 client" — what most users have on day 1 of v11. Use for tracker-init dog-food. |
+| `v11-tracker-on` | v11-pinned | pack at current `HEAD` | v11 install + `tracker.toml` with `mode.state = "tracker"` and `migration.forward_complete = true` set by hand (no live GH state) | Code-path testing for tracker-aware logic without round-tripping through real GH. |
+| `existing-project-mid-dev` | version-agnostic | none — synthesized | Realistic in-progress Swift+Python+gRPC project: `Package.swift`, `Sources/AcmeWidget/`, `Tests/AcmeWidgetTests/`, `proto/catalog.proto`, `service/` (Python tooling), top-level `README.md`, `.gitignore`, and 3 commits of pre-existing project history. Contains **zero** pack files (no `.claude/`, `.codex/`, `.gemini/`, `CLAUDE.md`/`AGENTS.md`/`GEMINI.md`, no pack scripts). | Input fixture for the BD-116 "init --update on top of an existing project" persona contract. Version-agnostic — same fixture serves v11, v12, … (BD-115). |
+
+## Naming convention
+
+Fixture directory names follow one of two patterns:
+
+- **`<vN>-<persona>` for version-pinned fixtures.** The `vN` prefix
+  (`v10-`, `v11-`, …) anchors the fixture to a specific pack-version
+  baseline — either a tagged release (`v10-minimal` is built from the
+  `v10` tag) or the current pack `HEAD` for the named major
+  (`v11-flat-file`, `v11-tracker-on`). The `<persona>` half names the
+  shape the fixture represents (`minimal`, `realistic-ot`, `flat-file`,
+  `tracker-on`). When v12 lands, expect `v12-flat-file`,
+  `v12-tracker-on`, etc., as siblings — never overwrite a v11 fixture
+  in place.
+- **Bare descriptor for version-agnostic fixtures.** When the fixture
+  models something that does not depend on a pack version (e.g.,
+  `existing-project-mid-dev` models a generic in-progress project the
+  pack is being added to), drop the `vN` prefix and use a hyphenated
+  descriptor. The fixture is reused unchanged across versions
+  (BD-115/BD-116).
+
+Pick version-pinned when the fixture's content is a snapshot of pack
+output at a specific version. Pick version-agnostic when the fixture is
+input *to* the pack and is not itself a pack artifact.
+
+## When to add a fixture here vs. elsewhere
+
+Add it to `test-fixtures/` when (a) more than one test consumes it, or
+(b) it represents a persona / baseline that has documentation value
+beyond a single test (migrator-baseline, tracker-on, mid-dev project,
+etc.). These fixtures live as their own git repos with deterministic
+SHAs so multiple test runs and dog-food sessions get byte-identical
+clones.
+
+Keep it inline in the test script when the fixture is single-use,
+trivially derivable in a few `mkdir`/`echo` lines, and not interesting
+on its own — e.g., a one-off `tmp` directory a single test creates,
+mutates, and deletes within its own `mktemp -d` scope. Don't promote
+single-use scratch state to a persistent fixture; the build/verify
+overhead isn't worth it.

 ## How fixtures are used by tests
```

## 5. Verification output

Docs-only change (no shell scripts modified, no test scripts touched).
Verification ran the pack validator:

```
$ python3 scripts/validate-pack.py
... (full output truncated; tail follows)
  OK: codex: project-template/.codex/skills/pm-startup/SKILL.md — Step 4 + Step 6 RAG line match canonical
  OK: gemini: project-template/.gemini/commands/pm-startup.toml — Step 4 + Step 6 RAG line match canonical

============================================================
PASSED — all checks clean
```

The validator passes after the edit. Check 26 (BD-119
migrator-framework inventory) is unaffected — it scans `scripts/`, not
`test-fixtures/`. No other check inspects `test-fixtures/README.md`.

```
$ git diff --stat test-fixtures/README.md
 test-fixtures/README.md | 54 ++++++++++++++++++++++++++++++++++++++++++-------
 1 file changed, 47 insertions(+), 7 deletions(-)
```

## 6. Plan deviations

None. The prompt scoped exactly one file (`test-fixtures/README.md`)
and asked for a Naming convention section, a "when here vs. elsewhere"
paragraph, and a table update making versioning visible per row. All
three landed; no other files were touched. The new "Versioning" column
was added (vs. a parenthetical or row-comment) because the table
already has one short value per cell and a column reads cleanly without
inflating any existing cell — the prompt explicitly left this choice
to the implementer ("through a column rename, a new column, or a
parenthetical — your call, keep it tight").

## 7. POQs (Planner-Open-Questions) introduced

None. Scope was tight and self-contained.

## 8. Definition-of-Done checklist

- **PASS — README clearly states the naming rule.** New "Naming
  convention" section, two bullets covering version-pinned and
  version-agnostic patterns, with `v10-minimal`, `v11-flat-file`,
  `v11-tracker-on`, and `existing-project-mid-dev` named as concrete
  examples.
- **PASS — README explains the "when here vs. elsewhere" decision
  criterion.** New "When to add a fixture here vs. elsewhere" section,
  two paragraphs (promote vs. keep inline) with the specific signals
  (multi-consumer, persona/baseline value vs. single-use, trivially
  derivable, mktemp-scoped).
- **PASS — fixture table surfaces version-pinning per row.** New
  "Versioning" column added; each row now carries `v10-pinned`,
  `v11-pinned`, or `version-agnostic` explicitly.
- **PASS — `validate-pack.py` PASSES, no regression on Check 26 or any
  other check.** Final tally line: `PASSED — all checks clean`.
- **PASS — addition is approximately 1–2 paragraphs + table update,
  not a treatise.** `+47 / -7` lines: roughly 6 lines for the table-row
  versioning column updates plus header, ~20 lines for the Naming
  convention section, ~13 lines for the "when here vs. elsewhere"
  section. Tight.

## Files modified

| Path | Change type | Line delta |
|---|---|---|
| `test-fixtures/README.md` | modified | +47 / -7 |

## Working-tree state

```
$ git status
On branch v11-dev
Your branch is up to date with 'origin/v11-dev'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   test-fixtures/README.md

no changes added to commit (use "git add ..." to commit)
```

(One additional file appears in the working tree —
`maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-122.md`,
this report itself. It is the agent's deliverable, not a code change.)

## Deferred items

None.

## 9. Proposed commit message

```
docs: v11 — BD-122 document test-fixtures/ <vN>-<persona> naming convention
```

(Single-line; tiny docs-only change; matches pack convention.)
