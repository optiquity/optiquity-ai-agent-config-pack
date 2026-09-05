# ARCHITECTURE-BD-119 — General N→N+1 Migrator Framework

**Author:** pack-architect
**Date:** 2026-05-08
**Status:** Proposed (read-only architecture pass)
**Scope:** BD-119. Informs BD-114, BD-117, BD-120, and every future
`migrate-v<N>-to-v<N+1>.sh`.
**Inputs reviewed:** `scripts/migrate-v10-to-v11.sh`, `scripts/init-project.sh`,
`scripts/lib/customization-preserve.sh`, `scripts/lib/three-way.sh`,
`scripts/lib/detect.sh`, `test-fixtures/build.sh`, `test-fixtures/README.md`,
`maintenance-docs/v11-implementation/DOG-FOOD-MIGRATION-REPORT.md`,
`README.md`, `BACKLOG.md` (BD-119, BD-114, BD-115, BD-117, BD-118, BD-120,
BD-088, BD-097, BD-098, BD-099, BD-102), `supporting-docs/MERGE-STRATEGY.md`,
`supporting-docs/MIGRATION-v10-to-v11.md`.

---

## Table of contents

1. [Purpose and framing](#1-purpose-and-framing)
2. [Concerns inventory in `migrate-v10-to-v11.sh`](#2-concerns-inventory-in-migrate-v10-to-v11sh)
3. [Framework structure (file layout + public surface)](#3-framework-structure-file-layout--public-surface)
4. [Per-version adapter contract](#4-per-version-adapter-contract)
5. [Cross-version dispatch and version detection](#5-cross-version-dispatch-and-version-detection)
6. [Safety contract (invariants enforced by the core)](#6-safety-contract-invariants-enforced-by-the-core)
7. [Tracker integration boundary](#7-tracker-integration-boundary)
8. [Defect-class coverage (Phase A D-1..D-7 + D-prefix migrator defects)](#8-defect-class-coverage)
9. [BD-120 enablement (realistic-OT fixture parameterization)](#9-bd-120-enablement)
10. [Refactor plan: `migrate-v10-to-v11.sh` against the framework](#10-refactor-plan-migrate-v10-to-v11sh-against-the-framework)
11. [Risks and open questions](#11-risks-and-open-questions)

---

## 1. Purpose and framing

`scripts/migrate-v10-to-v11.sh` works for the v10→v11 transition, but it
is monolithic. Every shared safety concern (preflight, backup, sidecar
hygiene, dispatch, report rendering) lives inline next to the
v10→v11-specific manifest. Shipping v12 against this baseline forces
copy-paste-then-edit, which structurally re-introduces every defect class
the v10→v11 dog-food run surfaced and any new ones a fresh hand-rewrite
adds.

**Design goal.** Extract everything that is the *same* across any N→N+1
transition into a single `scripts/lib/migrator-core.sh` and reduce each
per-version migrator to a thin adapter that declares only what is
version-specific. This is the same discipline `customization-preserve.sh`
already applies for per-file rules; we are extending it one level up to
the migrator orchestration itself.

**Constraint.** Pure bash, macOS+Linux, no new language deps, trinity
rule applies. Refactoring `migrate-v10-to-v11.sh` against the framework
must be behavior-preserving: same exit codes, same artifacts, same
report shape, same console output. Behavior preservation is the
proof-by-construction that the framework is sufficient.

**Out of scope.** Phase A defects D-1..D-7 from the BD-102 dog-food
report are tracker-side defects (`pack-tracker.sh`,
`tracker-migrate-reverse.sh`, `tracker-labels.sh`). Their *existence*
informs the framework only insofar as it tells us where the tracker
boundary lies; the *fixes* are out of scope for BD-119 and are tracked
as their own BD entries (per the dog-food report's "Proposed v11.0 BD
additions" table). Section 8 maps each defect to whether it would land
in the framework, the per-version adapter, or the tracker subsystem.

---

## 2. Concerns inventory in `migrate-v10-to-v11.sh`

Every block in the existing 437-line script, classified as either
**[shared]** (belongs in `migrator-core.sh`) or **[adapter]** (belongs
in the per-version `migrate-v<N>-to-v<N+1>.sh`). Line ranges cite the
current file.

| # | Concern | Lines | Class | Notes |
|---|---|---|---|---|
| C1 | Exit-code constants (PACK_INVALID, NOT_GIT, DIRTY, NOT_V*, BASELINE_MISSING, LIB_MISSING, INTERNAL) | 34–40 | shared | Versionless; `EXIT_NOT_V10` becomes `EXIT_NOT_BASELINE` (generic). |
| C2 | Baseline tag env var (`V10_TAG`) | 42–45 | adapter declares; shared consumes | Adapter declares `BASELINE_TAG="v10"`; core reads it as `MIGRATOR_BASELINE_TAG`. |
| C3 | `say/info/warn/die/fail_stage` helpers | 47–59 | shared | Identical for every migrator. |
| C4 | S0 preflight: `$PACK` valid, libraries present, target is git, working tree clean, ai-config markers present, baseline tag exists in pack | 63–92 | shared | Generic against any vN baseline. The v10-specific "CLAUDE.md + .claude/ present" check is generic "ai-config markers" and can use `detect_ai_config` from `lib/detect.sh`. |
| C5 | Stale-sidecar refusal (`*.pre-update`, `*.v10-customized`) | 94–108 | shared | Single-slot sidecar invariant is version-agnostic; the *suffix list* is version-aware (each adapter contributes its own previous-version sidecar suffix to a registry). |
| C6 | S1 backup: full working-tree tar to `.pack-migrate-vN-to-vM-backup/` with exclude list | 113–139 | shared | The directory name is version-derived (`.pack-migrate-${FROM}-to-${TO}-backup`); body is identical. |
| C7 | S2 lib setup: source three-way + customization-preserve + customization-report; `customization_preserve_init STATE_DIR SIDECAR_SUFFIX` | 143–157 | shared | State dir name is version-derived (`.pack-migrate-${FROM}-to-${TO}`); sidecar suffix is adapter-declared (`.v10-customized` for v10→v11). |
| C8 | `v10_baseline_to_tmp` helper (`git show $TAG:$path > tmp`) | 164–173 | shared | Renamed to `migrator_baseline_to_tmp`; takes the baseline tag from `MIGRATOR_BASELINE_TAG`. |
| C9 | S3 explicit per-file dispatch list (the trinity + settings + configs + pm-chat + pack docs entries) | 185–222 | adapter | This is the version-specific manifest — the heart of "what files transform v10→v11". |
| C10 | S3 directory-iteration dispatch for `scripts/`, `.claude/agents/`, `.codex/agents/`, `.gemini/agents/` | 226–253 | mostly shared, partly adapter | The *iteration mechanism* is shared; the *directory list + class assignment* is per-version (an adapter declares which dirs to sweep with which class). |
| C11 | S4 BD-042 legacy-doc relocation (METHODOLOGY/PROMPT-TEMPLATES/PM-CHAT/PLATFORM-SKILLS/PACK-FEEDBACK at root → `docs/pack/`) | 261–301 | adapter | The relocation table is purely v10→v11-specific: it cleans up v9-era stragglers. v11→v12 will have its own relocation table (or none). |
| C12 | S5 v11 artifact installs (HELP-FRAGMENT*, tracker.toml.example, ISSUE_TEMPLATE/*, per-CLI pack-help skill+command, pack-help.sh + lib/detect.sh shipped to project) | 305–370 | adapter | Pure "files added in v11 that did not exist in v10". This is the additive manifest. |
| C13 | S6 report rendering (`customization_report STATE/dispositions.tsv → report.md`) + final stdout summary including revert instructions and tracker-init pointer | 374–404 | shared with adapter overrides | Core renders the report. The "tracker-init pointer" line (`pack tracker init`) is v11-specific guidance that an adapter can append via a hook (not every future version will have a tracker-init-style follow-up). |
| C14 | Usage / `main` arg parsing (positional target, `--help`) | 408–435 | shared | The `--dry-run / --apply / --resume` modes BD-095 plans for slot in here. |
| C15 | Stage sequencer (`stage_s0 ... stage_s6` called in order) | 428–434 | shared | Core runs the canonical stage order; adapters fill stage-specific hooks. |

**One important reclassification.** Today's S3 mixes two concerns:
(1) the *engine* — iterate manifest entries, call
`customization_preserve` for each — and (2) the *manifest* — which
files, with which class. The engine is shared; the manifest is the
adapter's primary deliverable. The framework must make this split
explicit so adapters never re-implement the engine.

---

## 3. Framework structure (file layout + public surface)

### 3.1 File layout

```
scripts/
├── lib/
│   ├── migrator-core.sh           NEW — orchestrator, public API consumed by adapters
│   ├── migrator-stages.sh         NEW — per-stage implementations (sourced by core)
│   ├── migrator-manifest.sh       NEW — manifest parser + dispatch engine
│   ├── migrator-skills.sh         BD-147 — skill-rename / skill-split adapter (sourced by core)
│   ├── customization-preserve.sh  EXISTING — unchanged
│   ├── customization-report.sh    EXISTING — unchanged
│   ├── three-way.sh               EXISTING — unchanged
│   └── detect.sh                  EXISTING — adds `detect_target_pack_version()` (see §5)
├── migrate-v10-to-v11.sh          REFACTORED — thin adapter (target ~120 lines)
├── migrate-v11-to-v12.sh          FUTURE — same shape as v10→v11 adapter
└── dry-run-real-ot.sh             FUTURE BD-114 — calls migrator-core.sh::migrator_dispatch
```

**Why three files for the core, not one.** A single 800-line
`migrator-core.sh` recreates the monolith problem. The split mirrors
the existing concerns:

- `migrator-core.sh` — public API, argument parsing, stage sequencing,
  exit-code constants. The file an adapter sources.
- `migrator-stages.sh` — `_stage_preflight`, `_stage_backup`,
  `_stage_libs`, `_stage_dispatch`, `_stage_report`. Implementation
  detail; only `migrator-core.sh` sources it.
- `migrator-manifest.sh` — parser for the declarative manifest that
  adapters provide (see §4) and the dispatch engine that calls
  `customization_preserve` per entry. Parallel role to
  `customization-preserve.sh`: the latter handles per-file class rules;
  this one handles per-migration manifest iteration.

If at refactor time the line counts argue for fewer files, collapsing
manifest into stages is acceptable. The split is justified up-front
so the architecture does not bias toward another monolith.

**Sibling lib added in BD-147 — `migrator-skills.sh`.** The BD-035
v10→v11 split helper (per-line scan, server/data disambiguation, and
advisory-file emission) was originally inline in
`migrate-v10-to-v11.sh` S5b. BD-147 extracts that helper into
`scripts/lib/migrator-skills.sh` as a fourth blessed framework lib so
future N→N+1 adapters that need skill renames or splits can call a
stable API rather than duplicating the helper. Public surface (frozen
at BD-147 ship):

- `migrator_skill_rename <old-skill> <new-skill> [<advisory-path>]` —
  bare-token rewrite of `<old-skill>` references across a fixed file
  list (default: `docs/pack/PLATFORM-SKILLS.md` + the trinity). Two
  modes: SIMPLE (unconditional rewrite) and SPLIT (selected via the
  `MIGRATOR_SKILLS_SPLIT_TO_SERVER` / `MIGRATOR_SKILLS_SPLIT_TO_DATA`
  env vars, applying the BD-035 5-rule disambiguation). Writes an
  advisory file when the split mode finds ambiguous sites.
- `migrator_skill_split <old-skill> <new-server-skill> <new-data-skill>
  [<advisory-path>]` — forward-declared one-to-many split. v11.0 BD-035
  calls `migrator_skill_rename` in split mode directly; this wrapper
  exists so future adapters with a more readable split call site, or
  with extended split semantics (additional destination skills, custom
  signal patterns), have a stable entry point.

`migrator-core.sh` sources `migrator-skills.sh` alongside
`migrator-stages.sh` and `migrator-manifest.sh`, so adapters get the
public API with the same single-source pattern. The lib is
syntax-checked, function-defined, and source-graph-verified by Check 26
in `scripts/validate-pack.py` (extended in BD-147 from a 3-lib check
to a 4-lib check per PLAN-SKILL-DIMENSIONS.md §7.2).

### 3.2 Public surface (what an adapter sees)

An adapter sources exactly one file and calls exactly one function:

```bash
source "$PACK/scripts/lib/migrator-core.sh"
migrator_run "$@"
```

Before that call, the adapter declares the version-specific contract by
setting variables and defining hook functions. The core reads them.

**Required adapter-declared variables (set before `migrator_run`):**

- `MIGRATOR_FROM_VERSION="v10"` — source major version (no minor).
- `MIGRATOR_TO_VERSION="v11"` — destination major version.
- `MIGRATOR_BASELINE_TAG="${V10_TAG:-v10}"` — pack-repo tag used as
  BASE for three-way classification. Defaults to `MIGRATOR_FROM_VERSION`.
- `MIGRATOR_PRIOR_SIDECAR_SUFFIXES=("pre-update" "v9-customized")` — sidecars
  that previous upgrade paths could have left in the working tree;
  preflight refuses to proceed if any are present (see C5 / §6).
- `MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"` — sidecar suffix this
  migrator emits via `customization-preserve.sh` (single-slot rule).

**Required adapter-declared functions (hooks the core calls):**

- `migrator_manifest()` — emits the per-file dispatch manifest on
  stdout (TSV; one entry per line; format in §4.2). Replaces today's
  S3 array literal. **The single most important adapter-only deliverable.**
- `migrator_directory_sweeps()` — emits `<pack-dir> <class>` lines for
  directory-iteration dispatch (replaces C10).
- `migrator_relocations()` — emits `<old-path> <new-path>` lines for
  relocations like BD-042 (C11). Empty output is allowed and is the
  expected default for most version transitions.
- `migrator_artifact_installs()` — emits the additive-only file list
  for files newly added in vN+1 (replaces S5; C12). Format in §4.3.
- `migrator_post_report_hook()` — optional; called by the core after
  the report is rendered. Adapter prints any version-specific
  follow-up guidance to stdout (replaces the "pack tracker init"
  pointer at v10→v11). Default is a no-op the core supplies.

**Optional adapter-declared functions:**

- `migrator_pre_dispatch_hook()` — runs after S2 (libs init) and
  before S3 (dispatch). Use sparingly; manifest-declarative is preferred.
- `migrator_post_dispatch_hook()` — runs after S3, before S4 (relocation).
- `migrator_from_version_delivered <pack-relpath> <proj-relpath>` — rc 0
  iff the FROM version installed `<pack-relpath>` at `<proj-relpath>`.
  Consulted by `migrator_baseline_for_row` (below) only when the client
  has NO file at the destination: an absence at a destination the FROM
  version never created (a TO-version rename such as `.mcp.json.example`
  → `.mcp.json`) is not a client deletion, so the row dispatches with an
  empty base and installs as a clean add; a file the client DOES have
  there keeps the baseline SOURCE blob as its three-way base (a copy the
  client made from the pack's example has that example as its plausible
  ancestor). Undefined ⇒ every row counts as delivered. Addendum: added as an
  additive extension to the frozen surface; the realized consumer is the
  v10→v11 adapter's `migrator_from_version_delivered` in
  `scripts/migrate-v10-to-v11.sh`.

**Public-API functions exposed by the core (callable from adapters
*and* from external harnesses like BD-114):**

- `migrator_run "$@"` — full end-to-end migration with the calling
  adapter's declared contract.
- `migrator_dispatch <target-dir>` — programmatic entry, no usage
  printing; same effect as `migrator_run "$target-dir"`.
- `migrator_detect_target_version <target-dir>` — echo the major
  version installed in target (e.g. `v10`). Used by `dry-run-real-ot.sh`
  to pick the correct adapter (see §5).
- `migrator_select_adapter <from-version>` — echo the path to
  `migrate-v<from>-to-v<from+1>.sh`. Errors if missing.
- `migrator_pause` — adapter pause signal (no args). Sets the flag the
  EXIT trap reads to render a PAUSED (not FAILED) report, then exits 0;
  adapters call it instead of `exit 0` for a deliberate, `--resume`-able
  pause. Added by BD-282 as an additive extension to the frozen surface
  (mirrors the `EXIT_GATE_FAILED` additive-constant note); the realized
  consumer is `scripts/lib/migrate-v10-to-v11/apply.sh`
  `migrate_v10_to_v11_apply_after_dispatch`.
- `migrator_baseline_for_row <pack-relpath> <proj-relpath> <tmpfile>` —
  destination-aware BASE resolution: `migrator_baseline_to_tmp` gated, for
  an absent client file only, by the optional
  `migrator_from_version_delivered` hook (rc 1 + empty tmpfile when the
  hook says the FROM version never created that destination). Addendum:
  additive extension to the frozen surface; the realized consumers are the
  manifest engine (`_manifest_dispatch_transform`,
  `_manifest_sweep_directories` in `scripts/lib/migrator-manifest.sh`) and
  the v10→v11 adapter's `_v10_to_v11_map_derived_install`.

### 3.3 Env-var conventions

All framework env vars are prefixed `MIGRATOR_*` (adapter-declared) or
`_MIGRATOR_*` (core-internal, reset between runs). Existing
customization-preserve `_CP_*` vars are unchanged. State directory:
`.pack-migrate-${MIGRATOR_FROM_VERSION}-to-${MIGRATOR_TO_VERSION}/`.
Backup directory: same name with `-backup` suffix. Both names are
*derived*, never adapter-declared, so a sidecar/state-dir naming defect
fixed once is fixed for every adapter.

---

## 4. Per-version adapter contract

### 4.1 Adapter shape (what a v11→v12 file looks like)

A per-version migrator becomes ~80–120 lines of pure declaration:

```bash
#!/usr/bin/env bash
# migrate-v11-to-v12.sh — v11 → v12 migrator. Adapter against migrator-core.sh.

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Adapter-declared contract (read by migrator-core.sh).
MIGRATOR_FROM_VERSION="v11"
MIGRATOR_TO_VERSION="v12"
MIGRATOR_BASELINE_TAG="${V11_TAG:-v11}"
MIGRATOR_OWN_SIDECAR_SUFFIX="v11-customized"
MIGRATOR_PRIOR_SIDECAR_SUFFIXES=("pre-update" "v10-customized")

# Manifest hooks.
migrator_manifest()             { ... }   # see §4.2
migrator_directory_sweeps()     { ... }   # see §4.2
migrator_relocations()          { ... }   # likely empty for most transitions
migrator_artifact_installs()    { ... }   # see §4.3
migrator_post_report_hook()     { ... }   # version-specific guidance text

source "$PACK/scripts/lib/migrator-core.sh"
migrator_run "$@"
```

Every safety concern (preflight, backup, state dir, three-way dispatch,
report rendering, exit codes, dry-run, idempotency) is inherited from
the core. The adapter cannot override the safety concerns; it can only
*supply* the version-specific data those concerns operate on.

### 4.2 Declarative manifest format (TSV, one entry per line)

The manifest is the heart of "what changes from vN to vN+1." Today's
v10→v11 array literal at lines 185–200 of `migrate-v10-to-v11.sh`
becomes:

```
# pack-relpath<TAB>project-relpath<TAB>class<TAB>action
project-template/CLAUDE.md     CLAUDE.md     trinity      transform
project-template/AGENTS.md     AGENTS.md     trinity      transform
project-template/GEMINI.md     GEMINI.md     trinity      transform
project-template/.claude/settings.json   .claude/settings.json   claude-settings   transform
...
```

Columns:
- **pack-relpath** — path under `$PACK` (used both for THEIRS and for
  `git show $BASELINE_TAG:<path>` extraction of BASE).
- **project-relpath** — path under target.
- **class** — explicit `customization-preserve.sh` class
  (`trinity`, `claude-settings`, `codex-config`, etc.).
- **action** — one of:
  - `transform` — three-way dispatch via `customization_preserve`.
  - `add` — additive-only install (no preservation; only writes if
    target is missing the file). Equivalent to today's S5.
  - `remove` — file existed in vN, no longer ships in vN+1; record
    `removed-by-design` via the customization-report contract.
  - `relocate-from <old-path>` — file moved within the project
    layout (today's S4). Includes git-mv semantics and the "both root
    and docs/pack present → sidecar the root copy" branch.

The directory-sweep hook (`migrator_directory_sweeps`) emits a
parallel TSV listing whole directories to iterate (currently
`scripts/`, `.claude/agents/`, `.codex/agents/`, `.gemini/agents/`)
plus the BD-088 class to assign to each (`pack-script` /
`pack-agent`). Manifest entries take precedence over sweep entries
when paths collide, so an adapter can override a sweep result for a
specific file.

**Why declarative TSV, not imperative bash hooks.**

1. **Diff readability.** A v11→v12 manifest diffed against v10→v11
   answers "what changed in this transition?" at a glance — currently
   that question requires reading two scripts side-by-side.
2. **Validation.** A linter can check the manifest for duplicate
   entries, unknown classes, or paths that don't exist at the source
   pack tag — without executing it.
3. **Tooling reuse.** BD-114's `dry-run-real-ot.sh` and BD-116's
   migration-contract test can read the manifest to predict the
   expected output shape, instead of running the migrator and
   inspecting its diff.
4. **Defect surface area.** Imperative hooks tempt adapters to embed
   tiny bits of safety logic ("only do this if file X exists, except
   on macOS"); declarative entries push that logic into the engine
   where it is fixed once.

The `transform` / `add` / `remove` / `relocate-from` vocabulary is
intentionally small. Anything not expressible in those four verbs is a
sign that either (a) the version transition is doing something the
framework should be extended to support generically, or (b) the
specific case is rare enough that an `migrator_post_dispatch_hook` is
the right escape hatch. Both decisions are visible in code review.

### 4.3 Additive-install (`add`) semantics

`add` entries differ from `transform` in three ways:

1. The customization-preserve library is *not* invoked. `add` is for
   files that did not exist at the BASELINE_TAG; there is no BASE to
   classify against, no OURS to preserve.
2. The engine writes to the destination only if the target path does
   not already exist. A user who hand-created the file is not clobbered.
3. The engine still records a finding via the report contract
   (`disposition: pack-update-applied` or `project-only-file` if
   target already had it). This keeps the report truthful per the
   BD-088 contract: every shipped vN+1 file is accounted for.

This subsumes today's S5 v11-artifacts logic in a uniform way and
removes the per-file `if [[ ! -f $TARGET/... ]]` boilerplate at
lines 311–369.

### 4.4 What an adapter inherits (and cannot override)

- Exit-code constants and `say/info/warn/die/fail_stage` helpers.
- Stage sequencer order: preflight → backup → libs → dispatch →
  relocations → additive-install → report.
- Preflight checks (PACK valid, libs present, target git, working
  tree clean, baseline tag exists, ai-config markers present, no
  stale prior sidecars).
- Backup directory naming and tar exclude list. (The adapter cannot
  shrink the exclude list. Adding to it requires a framework change
  reviewed on its own merits.)
- State-directory naming (`.pack-migrate-<from>-to-<to>/`).
- Report renderer call.
- Argument parsing for `--help`, `--dry-run`, `--apply`, `--resume`
  (BD-095).

This list is the safety contract the core enforces (§6).

---

## 5. Cross-version dispatch and version detection

### 5.1 Detecting a target's installed pack version

Today, `lib/detect.sh::detect_pack_version` reads the *pack repo*'s
git tag — that's the version of the pack source the user is operating
*from*, not the version *installed in their project*. Cross-version
dispatch needs the latter.

**Proposal.** Add `detect_target_pack_version <target-dir>` to
`lib/detect.sh`. Detection algorithm (cheapest signal first):

1. **`tracker.toml` `[pack] version` field if present** — v11+ projects
   carry their pack version in tracker.toml. (Per §7, BD-119 should
   propose adding this field if it does not already exist; the v11
   client knows it is v11, recording that explicitly avoids future
   inference.)
2. **Trinity addenda fingerprint** — v11 ships a "Quick reference"
   addendum block in `CLAUDE.md / AGENTS.md / GEMINI.md` headed by a
   characteristic line (`run \`pack help\` for the full verb list`).
   Presence of that line implies v11+.
3. **Surface markers** — `.claude/skills/pack-help/SKILL.md` exists →
   v11+. `.github/ISSUE_TEMPLATE/work-item.yml` exists → v11+.
   `docs/pack/HELP-FRAGMENT.md` exists → v11+.
4. **Negative markers** — `docs/pack/PROMPT-TEMPLATES.md` present
   *and* surface-3 markers absent → v10. `METHODOLOGY.md` at root
   *and* `docs/pack/METHODOLOGY.md` absent → v9.x.
5. **Fallback.** If no signal pins a version, return `unknown` and
   the caller errors out with a hint pointing at the manual MIGRATION
   guide.

Each adapter contributes its own positive marker via a hook (e.g.
`migrator_target_version_marker()` returns `v11`'s fingerprint
algorithm). This keeps detection extensible without core edits.

### 5.2 External harness dispatch (BD-114 `dry-run-real-ot.sh`)

The harness needs to say "migrate this directory forward by one major"
without baking in the migrator filename. The core exposes:

```bash
detected=$(migrator_detect_target_version "$tmp_clone")  # → "v10"
adapter=$(migrator_select_adapter "$detected")           # → "$PACK/scripts/migrate-v10-to-v11.sh"
PACK="$PACK" bash "$adapter" "$tmp_clone"
```

`migrator_select_adapter` validates that the adapter file exists and
is executable, and that an adapter exists for the *next* major above
the detected version. If `detected=v11` and only
`migrate-v10-to-v11.sh` exists, the call errors with
`no migrator from v11 to v12 (latest) yet`.

### 5.3 Multi-step jumps (v9 → v11) and skipped versions

**Decision: the framework refuses multi-step jumps.** Each
`migrate-vN-to-vM.sh` migrates exactly one major step. If a user is on
v9 and wants v11, they run v9→v10 first, then v10→v11. This matches
how v10→v11 already documents the path (`MIGRATION-v10-to-v11.md`
states "If you're on v9.x or earlier, run migrate-v9-to-v10.sh first").

The core enforces this in preflight: if
`migrator_detect_target_version <target>` returns a version that is
not `MIGRATOR_FROM_VERSION`, exit `EXIT_NOT_BASELINE` (today's `EXIT_NOT_V10=13`,
renamed) with a message naming both detected and required versions
plus the suggested chain (`run migrate-v9-to-v10.sh first, then re-run
this`).

**Why not auto-chain.** Auto-chaining would mean the framework owns
the question "is it safe to run multiple migrators in sequence without
the user inspecting intermediate state?" Today it isn't safe — each
migrator's report is the user-visible artifact for triaging
customization conflicts; chaining hides the v9→v10 report behind the
v10→v11 report. Single-step keeps the user in the loop and is what the
existing migration docs already promise.

A future BD could add `pack migrate --chain v9 v11` as a thin wrapper
that runs each step with explicit pauses for the user to inspect each
step's report — but that's an additive feature, not a core capability.

### 5.4 Error semantics for unsupported jumps

| Detected | Required (adapter says) | Behavior |
|---|---|---|
| `v10` | `v10` | Proceed. |
| `v9` | `v10` | Exit `EXIT_NOT_BASELINE` with chain hint. |
| `v11` | `v10` | Exit `EXIT_NOT_BASELINE` "target is already at v11; nothing to do" (idempotent re-run sanity). |
| `unknown` | `v10` | Exit `EXIT_NOT_BASELINE` with manual-migration pointer. |
| `v12` | `v10` | Exit `EXIT_NOT_BASELINE` "target ahead of source"; future versions never auto-downgrade. |

---

## 6. Safety contract (invariants enforced by the core)

Each invariant below is enforced *by the framework* and *cannot be
bypassed by an adapter*. This is the structural payoff of BD-119.

| # | Invariant | Where enforced | How an adapter interacts |
|---|---|---|---|
| I1 | Preflight: `$PACK` valid, libraries sourceable, target is git, working tree clean | `_stage_preflight` in `migrator-stages.sh` | Read-only; adapters cannot disable. |
| I2 | Working-tree backup before any mutation, full-tree (not git-archive HEAD), excludes only `.git/` + state dirs + prior backups | `_stage_backup` in `migrator-stages.sh` | Read-only; adapters cannot skip. |
| I3 | BD-088 customization-preservation contract: every dispatched file goes through `customization_preserve` so the report is truthful | `_stage_dispatch` engine in `migrator-manifest.sh` | Adapter supplies the manifest; engine guarantees the call. |
| I4 | Single-slot sidecar rule: refuses to start if prior-version sidecar suffixes are present in the working tree (defends against mixed `--update` and `migrate-*` runs) | `_stage_preflight` reads `MIGRATOR_PRIOR_SIDECAR_SUFFIXES` | Adapter declares which suffixes its predecessors used. |
| I5 | Trinity diff parity (CLAUDE/AGENTS/GEMINI must move together) | Validation pass in `_stage_dispatch`: when manifest contains one of the three, the other two must also be present with the same `class`/`action` | Adapter declares all three; engine errors at parse time if any is missing. |
| I6 | Dry-run mode: `--dry-run` performs preflight + manifest validation + a *would-write* report but never modifies target | `_stage_*` functions branch on `_MIGRATOR_DRY_RUN`; argument parser sets the flag | Adapter cannot override; the BD-095 `--dry-run / --apply / --resume` modes live here. |
| I7 | No destructive ops without explicit flag — the migrator never `rm -rf`s the user's tree, never `git reset --hard`, never `git push` | Core has zero such calls; adapter hooks run in a function scope where the core's helpers don't expose `rm -rf <target>` shortcuts | Trust + code review of adapters; future hardening via shellcheck rule could ban `rm -rf "$TARGET"` patterns in adapter files. |
| I8 | Idempotency on re-run: a migrator that has already run leaves a state-dir marker; re-running detects it and exits with `EXIT_ALREADY_MIGRATED` (proposed new exit code) unless `--resume` or `--force-rerun` is passed | `_stage_preflight` checks for `<state-dir>/dispositions.tsv` from a successful prior run | Read-only. |
| I9 | Report rendering is mandatory: even on partial failure, the core attempts a final report render so the user has a truthful artifact | Trap on `EXIT` in `migrator_run` | Adapters cannot skip. |
| I10 | Exit codes are stable across versions: same condition → same code in every per-version migrator | Constants in `migrator-core.sh` | Adapters use the constants by name; cannot redefine. |

**Note on I5 (trinity).** Today's S3 manifest at lines 186–188
declares CLAUDE/AGENTS/GEMINI together by hand. The framework should
turn that into a hard validation: `migrator_manifest` is parsed at
dispatch start; if any one of the three trinity files appears, the
other two must also appear with the same `class` and `action`, else
the engine errors before any mutation. This is the trinity rule
expressed as a framework invariant, not a per-adapter convention.

**Note on I8 (idempotency).** The current `migrate-v10-to-v11.sh`
errors at S1 backup if `.pack-migrate-v10-to-v11-backup/` already
exists (line 117) — a useful safety, but the message tells the user
to rename the backup, not "you already migrated." Promoting this to
a first-class idempotency check at preflight (see I8 above) gives
the user a clearer signal and lets `--resume` distinguish "interrupted
mid-run" from "ran successfully and you're now re-running by accident."

---

## 7. Tracker integration boundary

**Decision: tracker init is NOT a framework concern, NOT an adapter
concern. It is a separately-invoked post-migration step.**

Rationale:

1. **Tracker init is opt-in by design.** Per the v11 high-level goals
   memory ("pack tracker opt-in + OT-style automated migration both
   with little/no user intervention"), tracker init is a *user* action
   triggered by `pack tracker init`. The migrator landing on a
   project must not opt the user into the tracker silently.
2. **The current v10→v11 migrator already does the right thing.** It
   ends with a stdout pointer ("To opt into the v11 issue-tracker
   integration, run: pack tracker init") and stops there. The
   pointer is version-specific guidance text — not migrator behavior.
3. **The Phase A defects D-1..D-7 are all tracker-side.** They live
   in `tracker-*.sh`. None of them are caused by, or fixable in, the
   migrator framework. Bringing tracker init into the migrator
   framework would couple the migrator's exit codes to tracker
   defects and widen the blast radius.
4. **Future versions may not have a tracker init step.** v12→v13
   may have a different opt-in surface, or none. Coupling the
   framework to "tracker init runs at end" assumes a v11-specific
   feature persists in every future version.

**Concretely:** the framework provides `migrator_post_report_hook()`
as the named extension point for "things the adapter wants to print
after the report is rendered." For v10→v11, that hook prints the
`pack tracker init` pointer. For v11→v12, the adapter declares its
own hook (or a no-op).

If a future version *does* require a follow-up step that must run
inline (e.g. a database schema migration that no user could be
expected to run by hand), that becomes its own BD with its own design
review. The framework deliberately does not anticipate that case.

**One related concern: target-version recording.** Section 5.1
proposed adding a `[pack]` section to `tracker.toml` with `version =
"v11"`. The migrator framework should write that field at the end of
a successful run *if `tracker.toml` already exists in the target* (a
v10 project that opted into tracker between v10 install and v10→v11
migration). That's a one-line write, version-derived
(`MIGRATOR_TO_VERSION`), and lives in `_stage_report` of the core —
not in the tracker subsystem. This is the *only* tracker touchpoint
the framework should own.

---

## 8. Defect-class coverage

The seven Phase A defects D-1..D-7 from
`maintenance-docs/v11-implementation/DOG-FOOD-MIGRATION-REPORT.md` are
all in the tracker subsystem (`pack-tracker.sh`,
`tracker-migrate-reverse.sh`, `tracker-labels.sh`,
`tracker-provider-gh.sh`). None are migrator defects. The mapping
below classifies each as "out of scope for BD-119" and explains why,
plus identifies what *migrator-side* defect classes the framework
*does* structurally prevent — the latter informed by the structural
risks the dog-food report names in passing.

### 8.1 Mapping Phase A defects to the framework

| Defect | Surface | Class under BD-119 | Reasoning |
|---|---|---|---|
| D-1 | `tracker-labels.sh`, `tracker-provider-gh.sh` (gh `--repo` slug) | Out of scope (tracker subsystem) | Tracker library defect; runs only inside `pack tracker init`. The migrator never invokes gh. Fix lives in the tracker libraries, not the framework. |
| D-2 | `pack-tracker.sh` `cmd_doctor` (missing `tracker_doctor_run`) | Out of scope (tracker subsystem) | Implementation gap in the tracker CLI verb. Framework has no analog. |
| D-3 | (withdrawn) | n/a | Not a defect. |
| D-4 | `tracker.toml` `forward_complete` flag stuck false | Out of scope (tracker subsystem) | Tracker forward-migration state-machine bug. Framework does not write this flag. |
| D-5 | `tracker-migrate-reverse.sh` racing with init close-step | Out of scope (tracker subsystem) | gh API consistency bug in tracker reverse migration. No analog in the migrator framework. |
| D-6 | `tracker-migrate-reverse.sh` BACKLOG header preamble loss | Out of scope (tracker subsystem) | Tracker reverse renderer bug. The migrator does not rewrite BACKLOG.md. |
| D-7 | `pack-tracker.sh` close-step partial-write (~5%) | Out of scope (tracker subsystem) | gh-API retry policy. No analog in the migrator framework. |

### 8.2 Migrator-side defect classes the framework structurally prevents

Although D-1..D-7 are all tracker-side, the dog-food report and
BD-088 review history identify several *migrator-side* defect classes
that copy-paste-then-edit would re-introduce in v11→v12 if BD-119 is
not landed first. The framework prevents each:

| Class | Concrete instance from history | Where prevented |
|---|---|---|
| M1: Mixed sidecar suffixes (`.pre-update` vs `.v10-customized`) leave two parallel pre-migration snapshots | Existing migrator's lines 99–108 (stale-sidecar refusal) | Centralized in core preflight (I4); adapter only declares which suffixes its predecessors used. A new v11→v12 adapter could not forget the check; it inherits it. |
| M2: Trinity drift — only one of CLAUDE/AGENTS/GEMINI receives a class change | Hand-maintained S3 array literal | Core validation pass (I5) errors at parse time if trinity entries are not symmetric. |
| M3: Backup excludes too much (e.g. forgets `.gemini/.env` because it is gitignored) | Lines 122–125 explicitly call out this as a hand-fixed defect (`git archive HEAD would miss gitignored files`) | Core's tar-with-exclude-list lives in `_stage_backup`. Adapter cannot reduce the exclude list. Fixed once, fixed forever. |
| M4: BD-088 dispatch skipped for one-side-absent files (would hide a planned-but-not-shipped pack file) | Lines 213–219 explicitly comment "Always dispatch — even when both sides absent" | Core engine in `migrator-manifest.sh` makes the always-dispatch contract structural; the adapter cannot supply a manifest entry that the engine then conditionally skips. |
| M5: Hard-coded version strings in safety messages (`v10 → v11`-specific revert instructions reused unchanged in a future migrator) | Lines 386–393 of revert-instructions block | Core renders revert instructions templated against `MIGRATOR_FROM_VERSION` / `MIGRATOR_TO_VERSION`; nothing in the message is hand-written by the adapter. |
| M6: Stage exit codes drift between migrators (S1 fails with code X in v10→v11 but Y in v11→v12) | Lines 52–59 `fail_stage` calculation | Core owns `fail_stage`; adapters call it by name. Codes are stable. |
| M7: Idempotent re-run produces a confusing "backup already exists, rename it" message instead of "you already migrated" | Line 117 | Promoted to first-class I8 idempotency check at preflight with a clearer message. |
| M8: Tracker-init pointer text duplicated and drifts from the actual `pack tracker init` syntax | Lines 401–403 | Centralized as `migrator_post_report_hook` whose default in `migrator-core.sh` calls a single `pack help tracker` command — never hand-written verb syntax. |
| M9: Per-CLI artifact installs duplicated three times with subtle drift between them | Lines 336–354 (claude / codex / gemini pack-help install blocks; near-identical but separate) | Manifest entries with `add` action and per-CLI rows; engine iterates uniformly. The trinity validation in I5 extends to per-CLI artifacts (a `pack-help` skill must ship for all three or none). |

The structural payoff: when v11→v12 ships, these nine defect classes
are not re-introducible by mistake. A v12 adapter can only specify
*what* changes, never *how* the engine handles change.

---

## 9. BD-120 enablement (realistic-OT fixture parameterization)

### 9.1 BD-120 in scope

BD-120 wants `_build_v10_realistic_ot` (today's hardcoded function in
`test-fixtures/build.sh` at lines 136–268) refactored into
`_build_realistic_for_version <vN>` so the same OT-shape
customization patterns apply against any pack tag. The patterns are:

1. Trinity project-name fills (`[PROJECT_NAME]`, `[PLATFORM_TARGETS]`,
   `[TRANSPORT]`).
2. `model_providers.ollama` removed from `.codex/config.toml`.
3. `x-`-prefixed custom agent on all 3 CLIs.
4. TD-* BACKLOG.md.

### 9.2 BD-120 dependence on BD-119 (and what helpers BD-119 should expose)

BD-120 is *informed by* BD-119 but *not blocked on* the public API
beyond one helper:

**`migrator_target_surface_for_version <vN>` (proposed core helper).**
Echo the relative paths a vN install creates that a fixture builder
needs to mutate to produce realistic customizations. For v10:
`CLAUDE.md AGENTS.md GEMINI.md .codex/config.toml .claude/agents/
.codex/agents/ .gemini/agents/ BACKLOG.md`. For v11: same plus the
v11-additive surfaces (`docs/pack/HELP-FRAGMENT.md`,
`tracker.toml.example`, etc.) — but not all of those are
customization surfaces; only the ones a real client edits.

The helper is *thin*: it returns a list, not a transformation. The
fixture builder applies the patterns; the helper just tells it where
the targets live in this version. This avoids duplicating "what does
v11 ship?" knowledge across `init-project.sh`, `migrate-vN-to-vM.sh`,
and `build.sh`.

**Alternative: BD-120 is fully independent.** BD-120 could read the
target surfaces directly off a freshly-built v10/v11 fixture and
discover the paths that way (find . -name '[PROJECT_NAME]' -prune ...
plus a known list). This works but duplicates the surface-list
knowledge. The helper is preferred but optional.

**Decision:** ship the helper as part of BD-119 — one-line addition to
the core's public surface, removes a future drift risk for free. If
BD-119's review finds the helper is not load-bearing it can be
deferred to BD-120's own scope without ripple.

**Addendum (2026-05-16, BD-160):** The §9.2 main text above preserves
the original BD-120-anchored design intent (the helper was specified
and shipped under BD-119 with BD-120 as the named first consumer).
The realized first fixture-builder consumer of
`migrator_target_surface_for_version` is BD-160 (commit `a57dd04`,
2026-05-16), which wired the v11 case in `_build_realistic_for_version`
inside `test-fixtures/build.sh` — BD-120 itself shipped without
sourcing the helper (this was identified in the BD-120 retro F1 fix).
The historical framing and the post-realization framing are not
contradictory: §9.2 documents the architectural contract; BD-160
documents the contract's first realization. The in-code docstring at
`scripts/lib/migrator-core.sh` for `migrator_target_surface_for_version`
was updated in the same commit `a57dd04` to name BD-160 as the
realized consumer (with the BD-120-retro F1 context preserved); read
the two together for the full historical chain.

### 9.3 What BD-120 inherits from BD-119

- The version-detection contract (§5.1) tells BD-120 how to validate
  that the fixture it just built actually appears as version `vN` to
  the migrator (catches non-deterministic drift between fixture
  builder and migrator's version-detection logic).
- The manifest format (§4.2) is the source of truth for "which files
  does the v10→v11 migrator touch?" — BD-116's migration-contract
  test (mentioned alongside BD-120 in BACKLOG) reads it directly to
  predict expected output.

### 9.4 What BD-120 does NOT need from BD-119

The fixture builder runs *before* the migrator; it does not need any
runtime helpers beyond the surface helper above. BD-120 can land
before or after BD-119's refactor of `migrate-v10-to-v11.sh` — they
do not strictly serialize.

---

## 10. Refactor plan: `migrate-v10-to-v11.sh` against the framework

This is the proof-by-construction. Each numbered block in the existing
file maps to either a core function or an adapter declaration. No
behavior change; same exit codes, same artifacts, same console output.

| Existing block (lines) | Becomes |
|---|---|
| Header comment + exit codes (1–40) | Adapter keeps a short header; exit code constants come from `migrator-core.sh`. |
| `V10_TAG` (42–45) | Adapter sets `MIGRATOR_BASELINE_TAG="${V10_TAG:-v10}"`. |
| `say/info/warn/die/fail_stage` (47–59) | Removed from adapter; inherited from core. |
| `stage_s0_preflight` (63–109) | Removed; core's `_stage_preflight` does it. Adapter declares `MIGRATOR_PRIOR_SIDECAR_SUFFIXES=("pre-update")`. The "must look like v10" check (lines 82–85) becomes the version-detection contract from §5.1; if `migrator_detect_target_version` does not return `v10`, core errors with `EXIT_NOT_BASELINE`. |
| `stage_s1_backup` (113–139) | Removed; core's `_stage_backup` does it. Backup dir name is derived from `MIGRATOR_FROM_VERSION` / `MIGRATOR_TO_VERSION`. |
| `stage_s2_libs` (143–157) | Removed; core's `_stage_libs` does it. State dir name derived; sidecar suffix from `MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"`. |
| `v10_baseline_to_tmp` (164–173) | Removed; core's `migrator_baseline_to_tmp` (renamed) replaces. |
| `stage_s3_dispatch` explicit entries (185–222) | Becomes `migrator_manifest()` — the adapter's primary deliverable, ~14 TSV rows, one-to-one with the current array literal. |
| `_stage_s3_iter_dir` (236–253) | Engine moves to `migrator-manifest.sh`. Adapter contributes `migrator_directory_sweeps()` returning `scripts/ pack-script` and three `.<tool>/agents/ pack-agent` rows. |
| `stage_s4_bd042_relocation` (261–301) | Adapter contributes `migrator_relocations()` returning the five `<old> <new>` rows (METHODOLOGY.md → docs/pack/METHODOLOGY.md, etc.). The git-mv-with-fallback logic moves to the core's relocation engine; the adapter just lists the moves. |
| `stage_s5_v11_artifacts` (305–370) | Adapter contributes `migrator_artifact_installs()` returning the additive `add`-action manifest entries (HELP-FRAGMENT*, tracker.toml.example, ISSUE_TEMPLATE/*.yml, per-CLI pack-help, scripts/pack-help.sh, scripts/lib/detect.sh). |
| `stage_s6_report` (374–404) | Removed; core's `_stage_report` does it. The "pack tracker init" pointer at lines 401–403 becomes `migrator_post_report_hook()` in the adapter. |
| `usage / main / arg parsing` (408–435) | Removed; core's `migrator_run` does it. |
| `main "$@"` (437) | Replaced by `migrator_run "$@"`. |

**Expected adapter line count after refactor:** ~120 lines (header
comment + variable declarations + four hook functions + source/run).
**Existing line count:** 437. **Deleted lines:** ~317. Those 317 lines
become the core (~500–700 lines once split across the three core
files), but they are now amortized across every future per-version
migrator. v12's adapter expects to be ~120 lines too.

**Behavior preservation checks** (run after refactor, before BD-119
is closed):

1. Run refactored `migrate-v10-to-v11.sh` against
   `test-fixtures/v10-realistic-ot` and against
   `test-fixtures/v10-minimal`.
2. Diff the resulting working trees against the same fixtures
   migrated by the *current* `migrate-v10-to-v11.sh` (preserved as
   a tag or branch snapshot before refactor).
3. Diff the rendered `report.md` artifacts.
4. Diff stdout (modulo timestamps).
5. Diff exit codes across all triggerable failure paths
   (PACK_INVALID, NOT_GIT, DIRTY, NOT_BASELINE, BASELINE_MISSING).

Any non-trivial diff is a behavior-preservation defect and blocks
BD-119 closure.

---

## 11. Risks and open questions

### 11.1 Risks the framework takes on

**R1: Shared-bug blast radius.** A defect in `migrator-core.sh`
affects every per-version migrator. Today a defect in
`migrate-v10-to-v11.sh` affects only that script. **Mitigation:** the
behavior-preservation check in §10 is mandatory before closure;
BD-118's CI workflow runs migration contracts on every push (per
BACKLOG.md BD-118), catching regressions; BD-114's real-OT dry-run is
a manual release gate (per BD-117) before any major version tag.

**R2: Wrong abstraction.** If the four manifest verbs
(`transform / add / remove / relocate-from`) prove insufficient for
v11→v12, the framework either bloats with new verbs or escapes via
imperative hooks (the `migrator_*_hook` functions). **Mitigation:**
the hooks exist precisely as the escape valve; an adapter that ends
up using them heavily is the early signal that the manifest format
needs a new verb. This is reviewable in code review.

**R3: Bash portability.** macOS bash 3.2 vs Linux bash 5+ already
forces the existing migrator to avoid associative arrays in the tar
exclude path (lines 122–135). The TSV manifest format avoids
associative arrays entirely; the engine reads line-by-line with
`while IFS=$'\t' read`. **Mitigation:** run the framework's
behavior-preservation check on both macOS (BSD utils) and Linux
(GNU utils) — already required by repo CI. Concrete portability
notes:

- `find -print` is portable; framework avoids `find -print0` because
  paths in `project-template/` have no spaces.
- `tar --exclude-from=` is portable across BSD and GNU tar.
- `mktemp` invocation patterns differ between BSD and GNU; the
  existing migrator uses the safe form (`mktemp` no template) and the
  framework should preserve that.

**R4: Trinity-rule enforcement at parse time may surprise adopters.**
If a v12 adopter forgets to add a `GEMINI.md` row to their manifest,
the engine errors before any mutation. This is by design (I5) but
will be a new failure mode for someone hand-writing a manifest for the
first time. **Mitigation:** clear error message naming all three
trinity files and which one is missing; documentation in
`MIGRATION-vN-to-vM.md` template.

**R5: Coupling to `customization-preserve.sh` API.** The framework's
`_stage_dispatch` engine calls `customization_preserve` directly. If
BD-NNN later changes that signature, every migrator breaks. **Mitigation:**
the engine is the single caller of `customization_preserve` for
migrators (today there are two — `migrate-v10-to-v11.sh` and
`init-project.sh --update`); after BD-119, signature changes ripple
through one file, not many.

### 11.2 Open questions deferred to pack-planner / implementation

**OQ1: BD-095 dry-run/apply/resume mode integration.** BD-095 is
mentioned in the existing migrator's header (line 28) as future work
that adds `--dry-run / --apply / --resume`. This architecture assumes
those modes live in the core (I6, I8). pack-planner needs to confirm
BD-095's design has not already constrained where the modes live.

**OQ2: Manifest validation tooling.** Section 4.2 names a "linter
that can check the manifest." Whether that's a separate
`scripts/validate-migrator-manifest.sh` or a check in
`scripts/validate-pack.py` is an implementation choice. Either is
fine; pack-planner picks based on existing CI shape.

**OQ3: Adapter discovery for `migrator_select_adapter`.** Glob
`scripts/migrate-v*-to-v*.sh` and parse, or maintain a registry file?
Glob is simpler and matches existing pack conventions; a registry is
more explicit. pack-planner decides at implementation.

**OQ4: How does the framework interact with `init-project.sh
--update`?** Today `--update` and `migrate-vN-to-vM.sh` share the
BD-088 customization-preservation library but not their orchestration
shells. Should `--update` *also* be expressed as a "vN to vN
self-migration" against the framework? This would unify both upgrade
paths. **Architect's leaning:** yes, but explicitly *out of scope* for
BD-119 — addressing it would expand BD-119's surface materially. A
follow-up BD can revisit once BD-119 has shipped and stabilized.

**OQ5: Trinity-rule check coverage.** Section §6 I5 enforces trinity
parity for the three context files (CLAUDE.md / AGENTS.md /
GEMINI.md). M9 in §8.2 generalizes the check to per-CLI artifacts
(pack-help skill, agents directory). pack-planner needs to specify
the exact list of "trinity-class" surfaces the validator checks
against; the architect's recommendation is the seven surfaces
`detect.sh` already iterates (`.claude/agents`, `.codex/agents`,
`.gemini/agents`, `.claude/skills`, `.codex/skills`, `.gemini/skills`,
`docs/pack/prompts`).

### 11.3 What this architecture does *not* decide

- The exact stage numbering/naming (S0..S6 vs preflight/backup/etc.).
  The current `S<N>` numbering is fine; the framework keeps it.
- Whether `migrator-stages.sh` and `migrator-manifest.sh` are
  separate files or fold into `migrator-core.sh`. Implementation
  choice based on resulting line counts.
- The exact test-suite shape for the framework. BD-118 already
  scopes the CI workflow; BD-116 already scopes the persona contracts.
  BD-119 inherits both as testing coverage; it does not introduce a
  third test surface.

---

## End of architecture document

Next step: pack-planner reads this document and produces an
implementation plan for BD-119 — file creation order, function-level
extraction sequence, behavior-preservation test plan, commit
sequencing.
