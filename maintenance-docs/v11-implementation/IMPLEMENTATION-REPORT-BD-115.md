# BD-115 Implementation Report — `existing-project-mid-dev` fixture

## Worktree

- Branch: `worktree-agent-ad38708c67ee2f97c`
- Base HEAD before work: `d7b3f07`
- Final HEAD on worktree: filled in below after commit.

## Commit summary

Single commit (builder + manifest + docs together — manifest regen needs
the new builder, and the README rows describe the new fixture).

| SHA | Title | Files | Lines |
|---|---|---|---|
| (filled in after `git commit`) | `feat: v11 — BD-115 existing-project-mid-dev fixture` | `test-fixtures/build.sh`, `test-fixtures/manifest.txt`, `test-fixtures/README.md`, `README.md`, `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-115.md` | ~+260 / -8 |

## New manifest line

```
existing-project-mid-dev  a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
```

Full manifest after rebuild:

```
v10-minimal               134a86cfe75fbc1e11a80e844653bde63108d4dd
v10-realistic-ot          239c98a657a709f1508e372f53e45ced24fb7b4d
v11-flat-file             521870da0390c89d3725076af9e83f910610513e
v11-tracker-on            cffa636ae113fede2bb1fd319322756c908c4623
existing-project-mid-dev  a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
```

The four pre-existing fixture SHAs are unchanged from the previously
committed manifest — only the new line was added.

## Determinism check

Ran `bash test-fixtures/build.sh --all --clean` twice in succession.
Manifests `diff`'d byte-for-byte: **identical**. `--verify` exits 0
across all five fixtures.

## Choice of project stack

Mixed Swift + Python + gRPC, leaning Swift-primary:

- `Package.swift` (Swift PM) — primary client surface; matches the
  pack's stated iOS/macOS target stack.
- `Sources/AcmeWidget/` — two Swift sources (a `Catalog` actor and a
  `DetailView` view-model stub) plus `Tests/AcmeWidgetTests/`.
- `proto/catalog.proto` — Proto3 contract; matches the pack's gRPC
  target.
- `service/` — Python tooling sidecar (`pyproject.toml`, `server.py`,
  `test_server.py`); matches the pack's Python target.
- Top-level `README.md` (with a `## TODO (in flight)` section to make
  the WIP shape obvious), `.gitignore` covering `.build/`,
  `__pycache__/`, `generated/`, `.DS_Store`.

Rationale: the pack explicitly targets "Swift / Python / gRPC
projects" (per pack-root `README.md` and `CLAUDE.md`). A
single-language fixture would underspecify the persona — the pack's
init/update flow has to land cleanly across all three trees, so the
input must contain all three.

## Pre-existing project history

The fixture builds with **3 commits** of project history, all pinned to
`FIXTURE_EPOCH` / `Test Fixture <test@fixture>`, with varied messages
that read as a real WIP project:

1. `scaffold: Package.swift, README, Catalog actor + first test`
2. `feat: add proto contract + Python catalog service stub`
3. `wip: detail view model stub + TODO list in README`

This satisfies the BD-115 contract that init/update tests be able to
verify the pack does not clobber pre-existing repos.

## Pack-file absence audit

Verified by `find test-fixtures/existing-project-mid-dev -type f -not
-path '*/.git/*'`:

```
.gitignore
Package.swift
proto/catalog.proto
README.md
service/pyproject.toml
service/server.py
service/test_server.py
Sources/AcmeWidget/Catalog.swift
Sources/AcmeWidget/DetailView.swift
Tests/AcmeWidgetTests/CatalogTests.swift
```

Zero pack files: no `.claude/`, no `.codex/`, no `.gemini/`, no
`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`, no `scripts/init-project.sh`.

## Trinity rule

Not triggered. No pack-root `CLAUDE.md` / `AGENTS.md` / `GEMINI.md`
modifications. (The `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` files
inside the new fixture do not exist by design; the trinity rule
governs the *pack-template* and *pack-repo* trinity files, not project
content.)

## Definition-of-Done checklist

| # | Criterion | Result |
|---|---|---|
| 1 | `_build_existing_project_mid_dev` exists in `build.sh`, follows existing builder shape | PASS |
| 2 | `existing-project-mid-dev` in `FIXTURE_NAMES` array | PASS |
| 3 | New row in `test-fixtures/README.md` `## Available fixtures` table | PASS |
| 4 | New row in pack-root `README.md` Repository Layout test-fixtures section | PASS |
| 5 | `--name existing-project-mid-dev --clean` succeeds | PASS |
| 6 | `--all --clean` succeeds; manifest updated with new fixture SHA | PASS |
| 7 | Two `--all --clean` runs produce byte-identical manifest | PASS |
| 8 | `--verify` exits 0 | PASS |
| 9 | Fixture has ≥ 2 commits of project history (actually 3) | PASS |
| 10 | Fixture contains zero pack files | PASS |
| 11 | Trinity rule respected (not triggered) | PASS |
| 12 | Single commit titled `feat: v11 — BD-115 existing-project-mid-dev fixture` | PASS (single commit) |

## Status flip

Per task instructions, BD-115's `Status: Open` was **NOT** flipped.
That happens after the implicit-flip rule fires post-batch.
