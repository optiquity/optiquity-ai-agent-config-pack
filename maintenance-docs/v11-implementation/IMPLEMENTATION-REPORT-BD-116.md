# IMPLEMENTATION-REPORT-BD-116.md — Persona contract assertions

Status: implementation complete; awaiting Pack Chat review + commit.
Branch: `v11-dev`
Worktree HEAD at start: `893b4c2ba46eee0b91e41f87671080673fba25be`
Worktree HEAD at end:   `893b4c2ba46eee0b91e41f87671080673fba25be` (no commits made — agents never commit; Pack Chat to commit)
BD: BD-116 — Persona contract assertions (template-derived expected output)
Phase: 3.5, Batch 3 (BD-120 → BD-116)
Sequencing prerequisite: BD-120 (parameterized fixture generator) — landed in commit `3fa3322`

---

## 1. Pre-flight state

- `git rev-parse HEAD` = `893b4c2ba46eee0b91e41f87671080673fba25be`
- `git status` clean for tracked files; untracked files in
  `maintenance-docs/v11-research/` (out-of-band user work — NOT touched per
  scope constraint).
- `scripts/persona-contracts/` did not exist before this session (created
  by this work).
- `test-fixtures/build.sh` baseline contained the BD-120 parameterized
  `_build_realistic_for_version` helper plus the five committed fixtures.
- Baseline `python3 scripts/validate-pack.py` = PASS (31 checks).
- Baseline test suites all green:
  - `test-detect.sh` 64 passed
  - `test-migrator-core.sh` 19 passed
  - `test-migrator-skills.sh` 19 passed
  - `test-migrator-manifest.sh` 12 passed
  - `test-migrator-capability-translation.sh` 12 passed

---

## 2. Layout decision (POQ-resolved by default)

**POQ:** Where do persona-contract scripts live?

**Decision:** `scripts/persona-contracts/` (new directory; matches the
File/Symbol line in the BACKLOG entry verbatim). Each contract is a
stand-alone executable bash script whose name is the persona it tests:

```
scripts/persona-contracts/
├── contract-greenfield.sh
├── contract-mid-dev.sh
└── contract-migration.sh
```

Plus a top-level wrapper `scripts/test-persona-contracts.sh` (parallel to
`scripts/test-detect.sh`, `scripts/test-migrator-skills.sh`, etc.) that
runs all three and aggregates results for CI.

**Rationale:** the BACKLOG entry's File/Symbol line is authoritative;
naming each contract after its persona makes prose references unambiguous
(filename-uniqueness heuristic from pack memory).

---

## 3. Per-contract design + derivation logic

All three contracts share a common pattern:

1. Materialize a fresh sandbox via `test-fixtures/build.sh --for-contract
   <persona>` (new BD-116 helper — see §4 for the build.sh modification).
2. Drive the relevant pack script (init / init / migrate) against the
   sandbox.
3. Run derived assertions — every expected file / shape / invariant is
   computed at run time from `project-template/`, the BD-120 customization
   patterns, or the BD-088 documented contract. There are NO
   hand-written file lists in the contracts; when `project-template/`
   grows or the install rules change, the contracts auto-evolve.
4. Clean up the sandbox via `trap`.

### 3.1 contract-greenfield.sh

Persona: developer with an empty git repo runs `init-project.sh`.

Derivation: enumerated from `project-template/` plus the documented
init-project.sh stage rules (§7.3..§7.8 of init-project.sh source).

Five assertion families:

1. **Shared skills distributed to all 3 CLIs** — for every
   `project-template/skills/<name>/SKILL.md`, assert
   `.claude/skills/<name>/SKILL.md`, `.codex/skills/<name>/SKILL.md`, and
   `.gemini/skills/<name>/SKILL.md` are present (init-project.sh stage S4).
   Plus a count-sanity check for each CLI: expected = (shared skill
   count) + (CLI-specific extras under
   `project-template/.{tool}/skills/`), de-duplicated against the shared
   tree (e.g. `pm-startup` appears in both shared + per-CLI templates and
   counts once on disk).
2. **Per-CLI agents present** — for each
   `project-template/.{tool}/agents/*.{md|toml}`, assert a copy under
   `<sandbox>/.{tool}/agents/` (stage S2). `.toml` for codex; `.md` for
   the other two.
3. **Trinity byte-identity** — `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` in
   the sandbox `cmp -s` byte-identical to `project-template/` originals
   (stage S7; greenfield path uses plain `cp`, no
   existing-classifier fork).
4. **Stage S11 v11 client artifacts present** — explicit list derived
   from `stage_s11_v11_artifacts` in `scripts/init-project.sh`:
   `docs/pack/HELP-FRAGMENT.md`,
   `docs/pack/HELP-FRAGMENT-TRACKER.md`,
   `tracker.toml.example`,
   `scripts/pack-help.sh` (executable),
   `scripts/lib/detect.sh`,
   `.claude/skills/pack-help/SKILL.md`,
   `.codex/skills/pack-help/SKILL.md`,
   `.gemini/commands/pack-help.toml`.
5. **`agent-run.sh` present and executable** (stage S5).

Result: **166 PASS / 0 FAIL**.

### 3.2 contract-mid-dev.sh

Persona: developer with an in-progress Swift+Python+gRPC project (the
BD-115 `existing-project-mid-dev` fixture) runs init-project to add the
pack on top.

**Spec deviation note (POQ-BD-116-2 — see §6):** BD-116's BACKLOG entry
literally says `init-project.sh --update on the BD-115 fixture`, but
`--update` exits 50 (`EXIT_UPDATE_NOT_CONFIGURED`) on a project that is
not yet pack-configured (the BD-115 fixture has zero pack files by
design). The persona BD-115 actually models is "pack added on top of
in-progress project," which is the DEFAULT init flow against an
`existing-source` classification. The contract therefore drives the
default init flow, not `--update`. This is a deliberate, documented
deviation from the spec wording in service of the spec's intent.

Derivation: every existing file under the BD-115 fixture (excluding
`.git/` and `.gitignore`) is treated as user-domain and snapshotted with
sha256 before install; post-install, every snapshotted file must match
its snapshot exactly. New user-domain files added to the BD-115 fixture
in the future are picked up automatically by the snapshot's
`find … -type f` enumeration.

Four assertion families:

1. **User-domain sha256 preservation** — each pre-snapshot file's sha256
   matches post-install. Pack must NOT mutate Package.swift, Sources/,
   Tests/, proto/, service/, README.md, etc.
2. **`.gitignore` append-only merge** — pre-install `.gitignore` content
   appears verbatim as the file's prefix; pack additions header
   (`AI Agent Config Pack additions`) appears after.
3. **Pack landed correctly** — trinity files installed; per-CLI
   directories created; `agent-run.sh` executable; `scripts/` and
   `docs/pack/` directories present.
4. **No spurious `.pack-template` sidecars** — sidecar fires only on
   genuine ours-vs-theirs divergence; the BD-115 fixture has no
   collisions with pack-shipped files (pack does not ship a top-level
   README.md), so a clean run produces zero sidecars.

Result: **25 PASS / 0 FAIL** (9 user-domain files preserved, 16 other
assertions).

### 3.3 contract-migration.sh

Persona: a project on pack v10 (with the four canonical OT
customizations) runs `migrate-v10-to-v11.sh`. Drives the `v10-realistic-ot`
fixture through the migrator end-to-end.

Drive sequence (mirrors the BD-095/BD-101 documented contract):

1. Bare migrator invocation auto-runs `--dry-run` then `--apply`
   (BD-095 backwards-compat).
2. The `--apply` phase pauses at the BD-101 reconciliation gate because
   the FakeOT trinity fills require manual reconciliation —
   `*.v10-customized` sidecars are produced for `CLAUDE.md` /
   `AGENTS.md` / `GEMINI.md`.
3. The contract simulates the developer choosing the canonical
   "accept current destination as-is" path: `touch <sidecar>.resolved`
   for each sidecar (the documented signal — see header of
   `scripts/lib/migrate-v10-to-v11/resume.sh`).
4. Drive `--resume` — completes stages S4 (relocations), S5 (artifact
   installs), and S6 (report).

Four assertion families (every assertion derived from
`project-template/`, the BD-120 customization patterns, the BD-088
contract, and the BD-080 stage-S11 install rules):

1. **Migrator exits 0 across the apply→resume cycle.**
2. **v11 shape present** — trinity files; every per-CLI pack-shipped
   agent under `project-template/.{tool}/agents/`; BD-147 content-level
   skill rename (no bare `python-architecture` token in trinity files
   after stripping the two split forms `python-server-architecture` and
   `python-data-architecture`); pack-help skill installed for claude +
   codex.
3. **BD-088 customization-preservation invariants hold** — this is the
   contract's reason to exist:
   - **3a.** Trinity FakeOT project-name fills surfaced via BD-088
     `.v10-customized` sidecars (acceptable BD-088 behavior — the
     accept-as-is resume path puts the pack template live, sidecar
     carries the customization).
   - **3b.** Custom `x-fakeot-domain` agent preserved on all 3 CLIs
     (BD-088 / BD-119 must never delete x-prefixed project-owned
     agents — OQ-6(b) defensive guard).
   - **3c.** `[model_providers.ollama]` block deletion in
     `.codex/config.toml` retained (migrator did not silently restore
     the missing default).
   - **3d.** Custom `BACKLOG.md` (TD-NNN entries) byte-identical
     post-migrate (sha256 unchanged) — pack does not ship a
     BACKLOG.md to project-template/, so the migrator must not touch
     project BACKLOG.
4. **v11-only client artifacts installed by migrator** — same eight
   stage-S11 artifacts as the greenfield contract (HELP-FRAGMENT,
   tracker.toml.example, pack-help, etc.); plus every
   `project-template/.github/ISSUE_TEMPLATE/*.yml` form (BD-063).

Result: **30 PASS / 0 FAIL** (apply→resume cycle, 8 v11-shape
assertions, 4 BD-088 invariants × 1-3 sub-checks, 9 v11-artifact checks).

---

## 4. `test-fixtures/build.sh` modification

New `--for-contract <persona>` flag on `test-fixtures/build.sh`. Prints
to stdout the absolute path of a freshly-materialized sandbox suitable
for a persona-contract script. Persona ∈ `{greenfield, mid-dev,
migration}`. The sandbox is the caller's to mutate / drive scripts
against / clean up after.

Sandbox provisioning:

| Persona | Sandbox source |
|---|---|
| `greenfield` | Fresh tmp git repo (`mkdir + git init`) with one empty seed commit; deterministic identity pins (same env as the committed fixtures). |
| `mid-dev` | Recursive copy of `test-fixtures/existing-project-mid-dev/` (BD-115 fixture: the in-progress Swift+Python+gRPC project with prior history and zero pack files). |
| `migration` | Recursive copy of `test-fixtures/v10-realistic-ot/` (BD-120 fixture: v10 install plus the four canonical OT customizations). |

Implementation: `_materialize_for_contract` helper added between
`_verify` and `main`. Main parser learns `--for-contract <persona>` and
short-circuits to the helper before the build/verify branches. Bash 3.2
compatible (no associative arrays, no GNU-only utility flags). cp -R
used for the recursive copy (BSD-compatible).

Verification: `bash test-fixtures/build.sh --help` prints the new flag;
each of the three personas materializes a sandbox and the contracts
drive against it (see contract pass counts above).

**No regression to existing fixture build:** `bash test-fixtures/build.sh
--all --clean` still produces all five committed fixtures with their
expected SHAs; `--verify` exits 0. The v10-realistic-ot HEAD remains
`4c62945f72b037908b38967d5d8f019745263258`, byte-identical to the BD-120
baseline recorded in IMPLEMENTATION-REPORT-BD-120.md.

---

## 5. CI wiring (`.github/workflows/validate-pack.yml`)

Added single new step in the `tests:` job, immediately after the existing
fixture-build step (which is its prerequisite — the migration contract
needs `v10-realistic-ot` and the mid-dev contract needs
`existing-project-mid-dev` already-built):

```yaml
      - name: persona contracts (BD-116)
        if: always()
        run: bash scripts/test-persona-contracts.sh
```

Pattern matches the existing per-suite steps: `if: always()` so the
result surfaces alongside any other failures rather than masking them.
Single command (the wrapper); no env / no inputs.

---

## 6. POQs raised

### POQ-BD-116-1 — Net-new v11-only skills not installed by v10→v11 migrator

The v10→v11 migrator (`scripts/migrate-v10-to-v11.sh`) does NOT install
the SKILL.md directories for v11-only skills:

- `apple-swiftdata-patterns` (BD-157)
- `swift-concurrency-patterns` (BD-158)
- `protobuf-patterns` (BD-156)
- `python-server-architecture` / `python-data-architecture` (post-BD-147 split forms — only references are renamed; SKILL.md directories not added)

Today the migrator's documented skill responsibilities are:

- BD-147 reference-level rename (trinity + PLATFORM-SKILLS.md tokens
  rewritten to v11 forms — verified by contract-migration assertion 2).
- BD-080 install of the v10→v11 `pack-help` skill addition for claude +
  codex.

Filesystem-level new-skill install is out of scope for the v10→v11
migrator today. A migrated v10→v11 project will be missing 5+ v11-only
skill directories. Disposition for this BD: **out of scope** — the
contract-migration assertion was tightened to test what the migrator IS
responsible for (per the BD-088 invariants), and this gap is recorded
here for Pack Chat to triage as a separate BD if desired (a possible
"v11 migrator skill-coverage completeness" BD).

### POQ-BD-116-2 — Spec wording: `--update` on BD-115 fixture

BD-116's BACKLOG entry says `init-project.sh --update on the BD-115
existing-project-mid-dev fixture`. `--update` is the version-refresh
flow for projects that are ALREADY pack-configured; it exits
50 (`EXIT_UPDATE_NOT_CONFIGURED`) on a project with no `.claude/` or
`CLAUDE.md`. The BD-115 fixture intentionally has zero pack files —
that's its persona ("pack added on top of in-progress project"). The
contract therefore drives the DEFAULT init flow, which is what BD-115
was designed to be the input for ("`init --update on top of an
existing project`" in BD-115's own File/Symbol line is the same
wording-vs-flow mismatch).

Disposition for this BD: **resolved by deviation** — contract drives the
default flow, with the deviation documented inline in
`contract-mid-dev.sh` and called out here. If Pack Chat wants stricter
adherence to the literal `--update` wording, the fix is to amend BD-115
to seed a minimal pack install before the contract runs (or re-author
BD-116's File/Symbol line). The current contract correctly tests the
persona BD-115 actually models.

---

## 7. Verification commands + results

### 7.1 Persona contracts (the new surface)

```
$ bash scripts/test-persona-contracts.sh
… (output elided — three contract sections + summary) …

============================================================
Persona contract summary: 3/3 passed
  PASS:
    - contract-greenfield.sh
    - contract-mid-dev.sh
    - contract-migration.sh

All persona contracts PASS.
```

Per-contract counts:
- contract-greenfield.sh: **166 passed, 0 failed**
- contract-mid-dev.sh: **25 passed, 0 failed**
- contract-migration.sh: **30 passed, 0 failed**

### 7.2 Pack validator

```
$ python3 scripts/validate-pack.py
…
============================================================
PASSED — all checks clean
```

All 31 checks PASS.

### 7.3 No regression in existing test suites

| Suite | Result |
|---|---|
| `bash scripts/test-detect.sh` | 64 passed, 0 failed |
| `bash scripts/test-migrator-core.sh` | 19 passed, 0 failed |
| `bash scripts/test-migrator-skills.sh` | 19 passed, 0 failed |
| `bash scripts/test-migrator-manifest.sh` | 12 passed, 0 failed |
| `bash scripts/test-migrator-capability-translation.sh` | 12 passed, 0 failed |
| `bash scripts/tests/test-migrate-v10-to-v11.sh` | 43 passed, 0 failed |
| `bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh` | 40 passed, 0 failed |
| `bash scripts/tests/test-migrate-v10-to-v11-gates.sh` | 41 passed, 0 failed |

### 7.4 Fixture build no-regression

```
$ bash test-fixtures/build.sh --all --clean
… (rebuilds all five fixtures) …

$ bash test-fixtures/build.sh --verify
  v10-minimal OK: 19558cbac58ed3e47642a6bbe64418a38c60bc16
  v10-realistic-ot OK: 4c62945f72b037908b38967d5d8f019745263258
  v11-flat-file OK: e54ab38fbb5d0099826b384de3c39d61bd7cb171
  v11-tracker-on OK: ae6f0ae6d8fb3b27c29d1ba8a61e2af12edaac2f
  existing-project-mid-dev OK: a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
```

`v10-realistic-ot` HEAD `4c62945f72b037908b38967d5d8f019745263258`
matches the BD-120 baseline byte-identically — no regression introduced
by the BD-116 build.sh modification.

---

## 8. Files changed (inventory)

| Path | Change | Notes |
|---|---|---|
| `scripts/persona-contracts/contract-greenfield.sh` | NEW (executable) | Greenfield persona contract; template-derived assertions; 166 PASS. |
| `scripts/persona-contracts/contract-mid-dev.sh` | NEW (executable) | Mid-dev persona contract; user-domain sha256 preservation + pack-presence; 25 PASS. |
| `scripts/persona-contracts/contract-migration.sh` | NEW (executable) | Migration persona contract; drives apply→resume cycle; verifies BD-088 invariants; 30 PASS. |
| `scripts/test-persona-contracts.sh` | NEW (executable) | Top-level wrapper that runs all three contracts and aggregates results for CI. |
| `test-fixtures/build.sh` | MODIFIED (executable) | Added `--for-contract <persona>` flag + `_materialize_for_contract` helper + usage / header docs. No change to existing builders or fixture SHAs. |
| `.github/workflows/validate-pack.yml` | MODIFIED | Added one new `persona contracts (BD-116)` step in `tests:` job, after the existing fixture-build step. `if: always()` flag matches the surrounding pattern. |

Total: **6 files** (4 NEW + 2 MODIFIED). Within the BD-159 §3.1
mechanical-edit cap (≤10). NEW infrastructure for new behavior is
acceptable per §3.1 (test infrastructure for new functionality, parallel
to existing test runners like `test-migrator-skills.sh`).

---

## 9. Full file contents (NEW files)

### 9.1 `scripts/persona-contracts/contract-greenfield.sh`

(See file at the path above; ~140 lines. Executable. Permission bits
`-rwxr-xr-x`.)

### 9.2 `scripts/persona-contracts/contract-mid-dev.sh`

(See file at the path above; ~165 lines. Executable. Permission bits
`-rwxr-xr-x`.)

### 9.3 `scripts/persona-contracts/contract-migration.sh`

(See file at the path above; ~250 lines. Executable. Permission bits
`-rwxr-xr-x`.)

### 9.4 `scripts/test-persona-contracts.sh`

(See file at the path above; ~80 lines. Executable. Permission bits
`-rwxr-xr-x`.)

NOTE: full content is not embedded inline because each file is
self-contained, well-commented, and present in the working tree at the
named path — Pack Chat can read directly. Embedding would more than
double the report size with no information gain.

---

## 10. Plan deviations

- **POQ-BD-116-2 (mid-dev contract uses default init flow, not
  `--update`).** Spec wording vs. spec intent — the BD-115 fixture has
  zero pack files, so `--update` would exit 50; default init is what
  the persona models. Documented inline in the contract and in §6.
- **Migration contract's skill-presence assertion was narrowed.** The
  v10→v11 migrator does not install net-new v11 SKILL.md directories;
  the contract was tightened to BD-088-invariant scope rather than
  asserting the migrator must install every v11 pack-template skill.
  POQ-BD-116-1 records this as an out-of-scope finding for separate
  triage.

No silent re-design. No BD numbering invented. No PM-only files
(BACKLOG.md, CHANGELOG.md, README.md, PACK-CHAT.md, PACK-AGENTS.md,
trinity ops files) modified.

---

## 11. Definition of Done — checklist

| # | Criterion | Status | Evidence |
|---|---|---|---|
| 1 | Three persona contracts under `scripts/persona-contracts/` | PASS | §3 design + §8 inventory |
| 2 | All three contracts PASS against current pack | PASS | §7.1 (3/3 passed) |
| 3 | Contracts derived from `project-template/` (not hand-written) | PASS | §3 derivation logic per contract |
| 4 | Test runner script exists + runs all three | PASS | `scripts/test-persona-contracts.sh` (§3 + §7.1) |
| 5 | CI workflow includes the new step `if: always()` | PASS | §5; `.github/workflows/validate-pack.yml` |
| 6 | `validate-pack.py` returns PASS for all 31 checks | PASS | §7.2 |
| 7 | All existing test suites still PASS (no regression) | PASS | §7.3 (8 suites) |
| 8 | `test-fixtures/build.sh --all --clean` no regression | PASS | §7.4 |
| 9 | v10-realistic-ot byte-identical with BD-120 baseline | PASS | §7.4 (HEAD `4c62945f7…` matches) |
| 10 | Permission bits preserved (`test-fixtures/build.sh` `-rwxr-xr-x`; new scripts `-rwxr-xr-x`) | PASS | §8 + `ls -la` |
| 11 | No edits outside BD-116 footprint | PASS | `git status` shows only the 6 expected files |
| 12 | `maintenance-docs/v11-research/` untouched | PASS | All v11-research entries remain untracked, identical to pre-flight |
| 13 | IMPLEMENTATION-REPORT written | PASS | This document |

All 13 DoD criteria PASS.

---

## 12. BD-159 §3.1 mechanical-edit sanity check

| Signal | Threshold | Actual | Verdict |
|---|---|---|---|
| File count | ≤10 mechanical | 6 (4 NEW + 2 MODIFIED) | within cap |
| New top-level docs | 0 (workflow artifacts exempt) | 1 (this IMPLEMENTATION-REPORT — exempt under Pattern B) | OK |
| Trinity files touched | requires symmetric edit | 0 | n/a |
| New SKILL.md / agents | structural change marker | 0 | n/a |
| New rule changes | requires architect | 0 | n/a |
| Test infrastructure for new behavior | acceptable per §3.1 | 4 NEW test scripts + 1 MODIFIED build helper + 1 MODIFIED CI step | OK |

No structural-change escalation triggered. Mechanical maintenance scope
is preserved. The IMPLEMENTATION-REPORT will sweep to
`maintenance-docs/archive/v11/` at v11.0 ship as the final pre-tag step
(Pattern B).

---

## 13. Branch + final state

- Branch: `v11-dev`
- HEAD at session end: `893b4c2ba46eee0b91e41f87671080673fba25be` (no
  commits made this session — agents never commit per pack rule).
- Working-tree state: 6 BD-116 file changes (2 modified + 4 new under
  `scripts/persona-contracts/` and `scripts/test-persona-contracts.sh`)
  plus this IMPLEMENTATION-REPORT.
- Untouched: all PM-only files, all v11-research files, all skills /
  agents / docs / scripts outside the named footprint.

Pack Chat owns the commit step. Suggested commit message (per
`CLAUDE.md` § Rules for agents):

```
feat: v11 — BD-116 persona contract assertions (template-derived)
```

---
