# test-fixtures/

Persistent baseline fixtures for pack tests and dog-food runs. Each
fixture is itself a git repo with deterministic content so tests can
clone it into `/tmp` for mutation-safe runs without rebuilding from
scratch every time.

## Quick start

```sh
# (Re)build all fixtures from scratch:
bash test-fixtures/build.sh --all

# Build one specific fixture:
bash test-fixtures/build.sh --name v10-realistic-ot

# Wipe and rebuild everything:
bash test-fixtures/build.sh --all --clean

# Verify the local builds match the committed manifest:
bash test-fixtures/build.sh --verify
```

## Available fixtures

| Name | Pack source | What it is | Use case |
|---|---|---|---|
| `v10-minimal` | pack at `v10` tag | Bare v10 install via `init-project.sh`; no customizations | Control fixture for migrator tests; the "what does the migrator do to a vanilla v10?" baseline |
| `v10-realistic-ot` | pack at `v10` tag | Fake-OT shape: project-name fills (`FakeOT`); x-prefixed custom agent on Claude/Codex/Gemini; `.codex/config.toml` `model_providers.ollama` removed; 5-entry TD-* `BACKLOG.md`; trinity v10 self-label intact | Realistic OT-style migration test; exercises BD-088 customization-preservation against shapes a real client would have |
| `v11-flat-file` | pack at current `HEAD` | v11 install via current `init-project.sh`; no `tracker.toml`; flat-file BACKLOG | "Vanilla v11 client" — what most users have on day 1 of v11. Use for tracker-init dog-food. |
| `v11-tracker-on` | pack at current `HEAD` | v11 install + `tracker.toml` with `mode.state = "tracker"` and `migration.forward_complete = true` set by hand (no live GH state) | Code-path testing for tracker-aware logic without round-tripping through real GH. |
| `existing-project-mid-dev` | none — synthesized | Realistic in-progress Swift+Python+gRPC project: `Package.swift`, `Sources/AcmeWidget/`, `Tests/AcmeWidgetTests/`, `proto/catalog.proto`, `service/` (Python tooling), top-level `README.md`, `.gitignore`, and 3 commits of pre-existing project history. Contains **zero** pack files (no `.claude/`, `.codex/`, `.gemini/`, `CLAUDE.md`/`AGENTS.md`/`GEMINI.md`, no pack scripts). | Input fixture for the BD-116 "init --update on top of an existing project" persona contract. Version-agnostic — same fixture serves v11, v12, … (BD-115). |

## How fixtures are used by tests

The fixture is the **pristine baseline**. Tests should NEVER mutate
the fixture directly. Pattern:

```sh
# Each test run gets its own throwaway clone:
WORK=$(mktemp -d -t pack-test.XXXXXX)
git clone test-fixtures/v10-realistic-ot "$WORK/target"

# Run the thing being tested against the throwaway clone:
PACK=$(pwd) bash scripts/migrate-v10-to-v11.sh "$WORK/target"

# Inspect or assert. Fixture itself untouched.
rm -rf "$WORK"
```

## Determinism

`build.sh` pins:

- `GIT_AUTHOR_NAME` / `GIT_AUTHOR_EMAIL` — fixed strings (`Test Fixture` / `test@fixture`)
- `GIT_AUTHOR_DATE` / `GIT_COMMITTER_DATE` — fixed epoch (`2026-01-01T00:00:00Z`)
- Source pack repo HEAD or v10 tag

Two runs of `build.sh` from the same pack-repo state produce
**byte-identical** fixtures (same git SHAs).

`manifest.txt` records each fixture's expected `HEAD` SHA after build.

- For `v10-*` fixtures: SHAs are stable as long as the v10 tag doesn't
  move. They're frozen in time.
- For `v11-*` fixtures: SHAs change whenever the pack's current
  `HEAD` changes the v11 surface (template files, scripts, etc.).
  Re-running `build.sh` regenerates the manifest — `git diff
  manifest.txt` shows what moved.

`build.sh --verify` rebuilds + compares against the committed
manifest. Useful in CI for v10-* fixtures (which should never drift)
and as an after-rebuild sanity check.

## Why fixtures are gitignored, not committed

Each fixture is a git repo with its own `.git/` directory. Committing
them would require either nested-git workarounds, tar archives, or
submodules — all of which add review friction. Gitignoring the
fixture content + committing the deterministic rebuild recipe
(`build.sh`) is the standard pattern: same as `node_modules/` or
docker build outputs.

If you accidentally `rm -rf` a fixture, run `bash build.sh --name
<fixture>` and you're back in 30 seconds. The manifest tells you the
expected SHA so you can confirm the rebuild matches.

## Adding a new fixture

1. Add a `_build_<name>()` function to `build.sh` following the
   pattern of the existing builders.
2. Add the name to the `FIXTURE_NAMES` array near the top.
3. Document the new fixture in this README's table.
4. Run `bash build.sh --all` and commit the updated `manifest.txt`.

Each builder writes its fixture deterministically into
`test-fixtures/<name>/` with a clean `git init` and a single commit.

## See also

- `scripts/migrate-v10-to-v11.sh` — the migrator these fixtures
  exercise.
- `scripts/init-project.sh` — produces the v11 surface in
  `v11-*` fixtures.
- `maintenance-docs/v11-implementation/DOG-FOOD-MIGRATION-REPORT.md`
  — the BD-102 dog-food consumes these fixtures.
- `BACKLOG.md` BD-113 — the entry that introduces this directory.
