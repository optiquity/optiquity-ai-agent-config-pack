# Release Gate — major-version pre-tag checklist

**Last updated:** 2026-05-15 (v11.0 development; BD-117 retro fix —
hook count, §2/§4 alignment, fixup re-verification, BD-115 trace,
regex tolerance, in-flight CI guidance).

This document is the authoritative pre-tag checklist for **any** major
pack version cut (v11.0, v12.0, ...). The five gate items below MUST all
pass on the candidate release commit before the version tag is created
or moved.

---

## 1. Purpose

Major-version cuts have historically depended on tribal knowledge — "did
we run the dry-run?", "did the persona contracts pass?", "is CI green on
exactly *this* SHA?". This checklist removes the guesswork. Any release-pin
commit (BD-093 for v11.0, the analogue BD for v12.0+) must be able to point
at this file and answer "yes, all five items satisfied" with concrete
evidence in the release-pin BD's `Resolved:` line.

The gate is intentionally short (five items) and prescriptive (specific
commands, specific pass criteria). It is a checklist, not a tutorial.

---

## 2. When to run

- **Every major version pre-tag commit.** v11.0 release (BD-093). v12.0
  release (analogue BD). v13.0, v14.0, ... — same gate.
- **Run order:** items 1 and 5 are working-tree state checks (run any
  time during release prep, but items 2, 3, 4 must be re-run on the
  exact candidate-tag commit immediately before tagging — see §4 for
  the per-item ordering rationale).
- **Sign-off:** the release-pin BD records pass evidence (commit SHA, CI
  run URL, contract output) per item in its `Resolved:` line.

This gate is **separate from** per-batch CI gates (those are documented
in `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md` §7) and
**separate from** the final milestone audit (Batch 22) and dog-food
migration (Batch 23). Those run earlier in the release sequence; this
gate is the last barrier before `git tag`.

---

## 3. Gate items

Five items. Each must pass. If any item fails, hold the release until
the cause is fixed and the item re-passes.

### Item 1 — Per-version migrator uses the BD-119 framework

**Asserts:** the per-version migrator
`scripts/migrate-v<N>-to-v<N+1>.sh` exists, sources
`scripts/lib/migrator-core.sh`, and uses the documented adapter
contract (`MIGRATOR_*` env vars + the five declarative hook
functions: `migrator_manifest`, `migrator_directory_sweeps`,
`migrator_relocations`, `migrator_artifact_installs`,
`migrator_post_report_hook`). It is **not** a copy-and-rewrite of a
previous version's migrator.

**Commands to run:**

```bash
# Replace <N>/<N+1> with the actual majors (e.g., 10 / 11 for v11.0).
test -x scripts/migrate-v<N>-to-v<N+1>.sh
grep -q 'scripts/lib/migrator-core.sh' scripts/migrate-v<N>-to-v<N+1>.sh
grep -E '^[[:space:]]*MIGRATOR_(FROM_VERSION|TO_VERSION|BASELINE_TAG)=' \
    scripts/migrate-v<N>-to-v<N+1>.sh
```

**Pass criterion:**

- The script exists and is executable.
- It sources `scripts/lib/migrator-core.sh` (one or more `source` /
  `.` lines referencing the path).
- It declares the framework's required `MIGRATOR_*` env vars
  (`MIGRATOR_FROM_VERSION`, `MIGRATOR_TO_VERSION`,
  `MIGRATOR_BASELINE_TAG` at minimum).
- v11.0 worked example: `scripts/migrate-v10-to-v11.sh` — see
  `maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md` for
  the full adapter contract.

**Common failure mode:** maintainer copies the previous migrator and
hand-edits version constants instead of using the framework. This
regresses the BD-119 refactor and silently re-introduces shared-defect
classes (customization preservation, sidecar handling, BACKLOG
migration, trinity diff, dry-run mode). If the script does not source
`migrator-core.sh`, fix the framework adoption before tagging.

---

### Item 2 — BD-114 dry-run against real OT passes with expected diff shape

**Asserts:** the BD-114 parameterized dry-run harness, pointed at the
real Optiquity Theatre (OT) repo, completes successfully and produces
a diff matching the documented expected shape for this major. The
maintainer signs off on the diff manually — this item is intentionally
not in CI because it touches a real network-hosted repo.

**Commands to run:**

```bash
# $OT_URL is the maintainer's read-only-credentialed v<N> URL for OT;
# never hardcoded in the pack. The harness clones into /tmp, runs the
# migrator read-only against the clone, captures the diff, removes the
# clone via EXIT trap.
bash scripts/dry-run-migration.sh "$OT_URL" --report-out /tmp/release-gate-dry-run.md
```

**Pass criterion:**

- Exit code `0` from `dry-run-migration.sh`.
- Report at `/tmp/release-gate-dry-run.md` (or whatever path was passed
  to `--report-out`) shows the migrator completed all stages without
  unresolved sidecars or unexpected stage failures.
- Maintainer reviews the diff and confirms the change set matches the
  documented expected shape for this major (per the major's
  `MIGRATION-v<N>-to-v<N+1>.md` doc).
- For v11.0: see `supporting-docs/MIGRATION-v10-to-v11.md` Phase A
  for the expected diff shape.

**Common failure mode:** OT contains client customizations the
migrator does not handle cleanly, surfacing `*.merge-conflict` sidecars
or per-class customization-preserve warnings. Either reconcile the
sidecars and re-run, or update the migrator manifest to handle the
new customization shape.

---

### Item 3 — All three BD-116 persona contracts pass

**Asserts:** the three persona contract scripts (greenfield, mid-dev,
migration) all exit `0`. Contracts derive their expected output from
`project-template/` and BD-088 customization-preservation invariants —
they do not rely on hand-written file lists, so they auto-evolve with
the templates.

**Commands to run:**

```bash
bash scripts/test-persona-contracts.sh
```

**Pass criterion:**

- Exit code `0` from `test-persona-contracts.sh`.
- Stdout contains `Persona contract summary: 3/3 passed` followed by
  `All persona contracts PASS.` on a final line.
- All three of `contract-greenfield.sh`, `contract-mid-dev.sh`,
  `contract-migration.sh` appear under the `PASS:` listing; `FAIL:`
  block is absent.

**Common failure mode:** a recent template change (e.g., new SKILL.md
directory) was not also installed by the migrator stages, so the
migration contract reports a missing file. Either extend the migrator
to install the new template artifact, or document the divergence in
the contract's expected-manifest derivation. v11.0 example: BD-161
(missing skill installs surfaced by the migration contract).

The `mid-dev` contract requires the BD-115 mid-development fixture
under `test-fixtures/existing-project-mid-dev/` to be built and
verified — see item 5.

---

### Item 4 — BD-118 CI workflow green on the release commit

**Asserts:** the GitHub Actions workflow
`.github/workflows/validate-pack.yml` shows both the `validate` and
`tests` jobs green on the **exact candidate-tag SHA** — not an earlier
SHA, not a later one.

**Commands to run:**

```bash
RELEASE_SHA=$(git rev-parse HEAD)
gh run list --workflow=validate-pack.yml --commit="$RELEASE_SHA" \
    --json status,conclusion,name,headSha
```

**Pass criterion:**

- At least one workflow run exists for `headSha == $RELEASE_SHA`.
- That run's `status == "completed"` and `conclusion == "success"`.
- Both the `validate` and `tests` jobs report `success` (use
  `gh run view <run-id> --json jobs` to drill in if the top-level
  conclusion is ambiguous).
- If `status` is `queued` or `in_progress`, wait for the run to
  finish (`gh run watch <run-id>`) and re-check; do not proceed to
  tag until `status` is `completed` and `conclusion` is `success`.

**Common failure mode:** the candidate-tag commit was created locally
but never pushed, so no CI run exists for that SHA. Push the commit
to its release branch, wait for CI, then re-run the gate. Do **not**
tag a SHA without a green CI run.

**Note on fixup commits:** any fix to items 1/2/3/5 that lands a fixup
commit changes the candidate-tag SHA. After each fixup, re-run items
2, 3, 5 against the new SHA and re-verify item 4 against the new SHA's
CI run before tagging. The previous CI run no longer satisfies item 4
once the SHA has moved.

---

### Item 5 — `test-fixtures/build.sh --verify` passes against committed manifest

**Asserts:** the committed test fixtures produce the same SHAs as
recorded in `test-fixtures/manifest.txt`. This catches non-deterministic
fixture drift (timestamps, locale, env-var bleed) that would otherwise
silently invalidate downstream tests.

**Commands to run:**

```bash
bash test-fixtures/build.sh --verify
```

**Pass criterion:**

- Exit code `0` from `test-fixtures/build.sh --verify`.
- Every fixture line reports `OK: <sha>` (no `MISMATCH` lines, no
  `not built` warnings on fixtures that should be built).
- If a fixture is intentionally not yet built locally, run
  `bash test-fixtures/build.sh --all --clean` first, then re-run
  `--verify`.

**Common failure mode:** a maintainer rebuilt fixtures after a
non-deterministic edit (e.g., a fixture builder that injects the
current date), so local SHAs no longer match `manifest.txt`. Trace
the non-determinism and either fix the builder or — if the change
is intentional — regenerate the manifest with `--all` and commit
both the fixture changes and the new manifest in the release-pin
commit.

---

## 4. Maintenance

This document evolves with each major release.

- **The five-item count is fixed.** If a future major needs a sixth
  gate (e.g., a new class of regression to guard), open a BD, run
  it through architect + planner, and update this doc as part of
  that BD. Do not silently add or remove items.
- **Item ordering is significant for items 1 and 5** (they are
  working-tree state — must be true at tag time) and for item 4
  (CI must run on the exact tag SHA — fix items 1, 2, 3, 5 first
  so the candidate SHA is stable). Items 2 and 3 can be re-run
  independently in any order.
- **Update the `Last updated:` line** whenever this document
  changes.
- **Concrete v11.0 examples** (the worked references in items 1
  and 3) may be replaced with v12.0 / v13.0 examples as those
  releases ship. The `<N>` / `<N+1>` placeholders are the
  authoritative form; concrete references are illustrative.

---

## 5. Cross-references

- **BD-117** (this document) — `BACKLOG.md`.
- **BD-093** (release-pin commit consuming this gate) — `BACKLOG.md`.
- **BD-118** (CI wiring referenced by item 4) — `BACKLOG.md`,
  `.github/workflows/validate-pack.yml`.
- **BD-114** (dry-run harness used by item 2) — `BACKLOG.md`,
  `scripts/dry-run-migration.sh`.
- **BD-115** (mid-dev fixture used by item 3 contract) —
  `BACKLOG.md`, `test-fixtures/existing-project-mid-dev/`.
- **BD-116** (persona contracts used by item 3) — `BACKLOG.md`,
  `scripts/persona-contracts/`, `scripts/test-persona-contracts.sh`.
- **BD-119** (migrator framework referenced by item 1) —
  `BACKLOG.md`, `scripts/lib/migrator-core.sh`,
  `maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md`.
- **EXECUTION-PLAN-V11.0.md §7** — per-batch verification gates
  (CI green, validator clean, audit, dog-food); this document
  picks up at the post-batch level for the final tag.
- **`supporting-docs/MIGRATION-v<N>-to-v<N+1>.md`** — the
  per-major user-facing migration guide that documents the
  expected diff shape referenced by item 2.
