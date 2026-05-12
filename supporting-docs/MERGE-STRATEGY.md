# MERGE-STRATEGY.md — per-file customization preservation contract

When `init-project.sh --update` (BD-080) or `migrate-v10-to-v11.sh` (BD-085)
refresh a project to a newer pack version, every file the migrator touches
is dispatched to a per-class preservation strategy implemented in
`scripts/lib/customization-preserve.sh` (BD-088). This document is the
**user-readable matrix** of those rules — what each class does, what kind
of customization it preserves, and what to do when the migrator reports a
file as needing manual reconciliation.

The same matrix applies to both upgrade paths: `init-project.sh --update`
and `scripts/migrate-v10-to-v11.sh`. The contract is symmetric.

---

## How to read this document

Every file the migrator touches belongs to one of 12 classes. For each
class:

- **Strategy** — the preservation algorithm
- **What's preserved** — the project-side content that survives a refresh
- **What gets updated** — the pack-side content that gets adopted
- **Disposition tokens** — the labels that appear in `report.md`
- **What to do on `customization-detected-needs-reconciliation`** — the
  action you take when the migrator flags a file for review

Disposition tokens are the BD-088 truthful-report contract — every file
the migrator processes produces exactly one row in `dispositions.tsv`,
listed in `report.md` under one of:

- `unchanged-pack` — file is byte-equal across baseline / project / new pack
- `pack-update-applied` — pack updated; project hadn't customized
- `merged-with-customization` — project edits preserved; pack changes adopted
- `customization-detected-needs-reconciliation` — both sides edited; sidecar written; YOU resolve
- `removed-by-design` — pack retired the file
- `project-only-file` — project-owned file the pack does not ship
- `project-deleted-pack-kept` — project deleted a file pack still ships
- `removed-everywhere` — already absent on both sides

---

## The 12 file classes

### 1. `trinity` — `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`

**Strategy:** 3-way merge against the previous-pack baseline.

The migrator extracts the v10 baseline from the pack repo's `v10` git
tag, compares against the project's current trinity content, and adopts
new pack template content while preserving project-side customizations
(stack defaults, custom agents, project-specific operating notes).

**What's preserved:** every line outside the pack-template marker
sections — the entire body of project-specific content, custom
agents, project addenda, etc.

**What gets updated:** the pack-template-managed sections (Capability
policy, Core priorities, etc.) when those have evolved between the
baseline and the new pack.

**On `customization-detected-needs-reconciliation`:** the migrator
writes the new pack template to `<file>.md` and saves your pre-update
copy as `<file>.md.v10-customized` (migrator) or `<file>.md.pre-update`
(`init-project.sh --update`). Open both, manually merge the project
content into the new template, delete the sidecar, and `git add`.

---

### 2. `claude-settings` — `.claude/settings.json`, `.claude/settings.json.example`, `.gemini/settings.json`

**Strategy:** allowlist-based JSON key-merge via `scripts/merge-json.py`.

The `.gemini/settings.json` file is routed through this same class by
the migrator (BD-085 stage S3) — same algorithm, different file path.
The classifier auto-emits `claude-settings` for paths matching
`.claude/settings.json`; for `.gemini/settings.json` the migrator passes
the class explicitly.

Recursive key-union over BASE / OURS / THEIRS, with set-difference logic
for arrays. Pack-managed top-level keys adopt new pack values; project-
tuned keys (e.g., `XCODE_SCHEME`, `XCODE_DESTINATION`, project-specific
permission entries) survive intact.

**What's preserved:** every project-set key not in the pack baseline,
plus project edits to any pack-shipped key.

**What gets updated:** pack-shipped keys whose project value matched
the baseline (no project edit).

**On `customization-detected-needs-reconciliation`:** rare — only when
both sides edited the same scalar key with conflicting values.
`merge-json.py` writes warnings to `<state-dir>/diffs/...merge-warnings.log`.
Inspect, choose the correct value manually, edit `settings.json`,
remove the sidecar.

---

### 3. `claude-mcp-example` — `.mcp.json.example`, `.mcp.json`

**Strategy:** same as `claude-settings` (JSON allowlist via `merge-json.py`).

The MCP example file is a template; project edits to add custom MCP
servers (e.g., a dev/stage GraphQL endpoint) are preserved.

---

### 4. `codex-config` — `.codex/config.toml`, `.codex/requirements.toml`

**Strategy:** allowlist-based TOML key-merge via `scripts/merge-toml.py`.

Mirrors `merge-json.py`'s contract but at the TOML table level. The
canonical OT case is `[model_providers.ollama]` / `[model_providers.lmstudio]`:
project intentionally removes a section; pack still ships it; the
migrator honors the project-side removal (set-difference logic).

**What's preserved:** project-intentional section removals, project-set
provider keys, project-tuned table values.

**What gets updated:** new sections / new keys the pack added since
the baseline that the project hasn't touched.

**On `customization-detected-needs-reconciliation`:** same recipe as
JSON — read the warnings log, reconcile manually.

---

### 5. `codex-config-example` — `.codex/config.toml.example`

Same strategy as `codex-config`.

---

### 6. `gemini-env` — `.gemini/.env`, `.gemini/.env.example`

**Strategy:** KEY=VALUE line preservation with project-wins-on-conflict.

Routed through the canonical 4-case classifier (BD-088 review M1) so
real-merge-required cases surface as `customization-detected-needs-reconciliation`
with sidecar — the user is told when a true 3-way conflict occurred and
their value silently won.

**What's preserved:** every project-set KEY=VALUE, including
`AGENT_CAPABILITIES` (the canonical BD-059 case). Duplicate keys
deduped; leading whitespace stripped before key match.

**What gets updated:** pack-new keys appended at the bottom under a
`# Added by v11 pack update` comment.

**On `customization-detected-needs-reconciliation`:** project value
won the merge. Inspect the new pack values in
`<file>.pre-update` (or `.v10-customized`); decide whether to keep
the project value or adopt the pack value. Edit `.env`, remove the
sidecar.

---

### 7. `pm-chat` — `docs/pack/PM-CHAT.md`

**Strategy:** 3-way text dispatch (same as `trinity`).

PM-CHAT.md mixes pack-managed operating rules (pack maintainer behavior,
Stage Coverage spec) with project-specific customizations (project-name
substitution, project-specific role definitions). Both layers must
survive a refresh.

The current implementation routes through the generic 3-way text
dispatcher — same algorithm as `trinity`. Future BDs may add explicit
marker-section + diff-recognition fallback (per BD-088 spec) for finer-
grained preservation; today the single dispatcher handles both surfaces
correctly when the project keeps marker headers intact.

---

### 8. `custom-agent` — `.claude/agents/x-*.md`, `.codex/agents/x-*.md`, `.gemini/agents/x-*.md`

**Strategy:** unconditional preservation. Project-owned by reserved-prefix
contract (V3 §I.4); the pack never ships an `x-`-prefixed agent and the
migrator never overwrites one.

**Disposition:** always `project-only-file`.

---

### 9. `pack-agent` — `.{claude,codex,gemini}/agents/<non-x>.md`

**Strategy:** 3-way text dispatch.

Pack-shipped agent files (e.g., `pack-architect.md`, `pack-reviewer.md`).
Trinity rule applies — refreshes are delivered in lockstep across the
three CLI variants. The `auditor-issue-tracking` agent (BD-109 / BD-110)
is on the v11.x roadmap; when it ships it will route through the same
class.

---

### 10. `custom-script` — `scripts/x-*.sh`, `scripts/<project-added>.{sh,py}`

**Strategy:** unconditional preservation when reached.

**Reachability:** the auto-classifier (`customization_classify`) routes
all `scripts/*` paths to `pack-script` (3-way text). The `custom-script`
class is reachable only when a caller passes it explicitly via the
6th argument to `customization_preserve`. The migrator and
`init-project.sh --update` currently iterate `scripts/` with
`cls=pack-script` for the entire directory, so a project-added script
will route through `pack-script` 3-way text dispatch:

- A `scripts/x-tool.sh` not present in the pack repo will hit
  `project-only-file` via three-way classification (BASE absent,
  THEIRS absent, OURS present) — same effective outcome as
  `custom-script`. The migrator does NOT touch it.
- A `scripts/<name>.sh` whose name collides with a pack-shipped script
  WILL route through 3-way text — the migrator treats it as the
  pack-shipped file (with potential customization-detected-needs-
  reconciliation if both sides differ from baseline).

The reserved `x-` prefix contract guarantees collisions cannot occur:
the pack never ships `x-`-prefixed scripts (validate-pack Check 8
enforces). Per-CLI agents under `.{claude,codex,gemini}/agents/x-*.md`
ARE classified directly to `custom-agent` by name; scripts use the
prefix-by-convention but rely on three-way's project-only-file
classification rather than a dedicated classifier branch.

---

### 11. `pack-script` — `scripts/<pack-shipped>.{sh,py}`

**Strategy:** 3-way text dispatch.

Pack-shipped scripts get the canonical 4-case classification.
Customizations (e.g., a project that added a `--quick-mode` flag to
a pack script) surface as `customization-detected-needs-reconciliation`
with sidecar.

---

### 12. `generic` — everything else

**Strategy:** 3-way text dispatch (default).

Catch-all for files the classifier doesn't recognize. HELP-FRAGMENT
files, the client-installed tracker.toml.example (sourced from
`project-template/tracker.toml.project-example`), and issue-template
forms route through this class. The classifier is conservative: when
unsure, fall back to text 3-way which preserves project edits via
sidecar.

---

## Per-file notes

### `docs/pack/PLATFORM-SKILLS.md` (BD-148, v11 reframe)

**Class:** routes through `generic` (3-way text dispatch with
sidecar) for the body. Two `## Custom *` H2 sections at the bottom
are project-owned and preserved verbatim by the BD-088 sidecar
mechanism.

**v11 reframe note (BD-142, BD-148).** v11 reshapes the file from
the four-dimension model (Platform Targets, Languages, Component
Roles, Communication Protocols) to a five-dimension model (D1
runtime / OS substrate, D2 cross-platform languages, D3 component
role, D4 communication protocols, D5 deployment surface — new) plus
three orthogonal load mechanisms (Tier 0 base, intersection-cell,
trigger-loaded). The reshape is **`transform`-class for the
pack-managed body** (sections from §"How skill selection works"
through §"Full skill inventory" / §"Extending this file") — i.e.,
the pack ships a wholesale-replaced template; project edits to
those sections are not preserved automatically. Per the architecture
§7.6 advisory, projects with locally edited PLATFORM-SKILLS.md
bodies must re-apply edits manually after the migrator writes the
v11 template (the migrator saves the pre-migration copy as
`docs/pack/PLATFORM-SKILLS.md.v10-customized` for the manual
reconciliation pass).

**`## Custom agents` and `## Custom skills` are user-owned.** These
two H2 sections at the bottom of the file are preserved
**byte-identical** by the BD-088 customization-preserve sidecar
mechanism — the migrator does NOT rewrite them, even when the
column headers inside them are stale. The v11 illustrative-row
column headers are `Base skills | Dimensional skills` (replacing
the v10 `Tier 1 skills | Tier 2 skills`); projects with real custom
rows under the deprecated v10 headers keep those headers
post-migration and rename them manually. See
`MIGRATION-v10-to-v11.md` § "Skill model changes" for the
manual-rename note and `INSTALL-PROCEDURES.md` § "Procedure 5.1"
for the v11 column convention used when a new custom agent is
registered.

**D5 monorepo gotcha (architecture §7.4).** The new D5 dimension
loads deployment skills globally for every prompt the PM chat
generates. A monorepo with D5 = {`apple-distribution`,
`linux-container`} loads BOTH `deployment-apple` AND
`deployment-python` for every prompt; the agent prompt (constructed
by the PM chat) scopes per-component citation. This is documented
behavior — multi-component projects migrating from v10 should
verify their PM-chat prompt construction continues to scope
deployment-skill rule citations to the relevant component. No
preservation-strategy change is needed for the gotcha; it is a
documentation / behavioral note carried in PLATFORM-SKILLS.md
§ "Monorepo D5 scoping note" and in `MIGRATION-v10-to-v11.md`
§ "Skill model changes — D5 monorepo gotcha".

**D2 reshape advisory (architecture §7.6).** The Apple-family
languages (Swift, Objective-C, C, C++) move from a v10 D2
selection to v11 D1-implied loading (Swift implied by D1=ios/macos,
C/C++ implied by D1=embedded-mcu, etc.). Projects that read
PLATFORM-SKILLS.md programmatically by the v10 D2 row labels will
need to update their reading logic to consult the v11 D1 tables.
Manual readers see the same set of skills loaded for the same
project shape — only the labeling of which dimension causes the
load changes.

---

## Sidecar conventions

When the migrator writes a sidecar (`customization-detected-needs-reconciliation`
or `removed-by-pack-customized` paths), the suffix is:

- `migrate-v10-to-v11.sh` (BD-085): `<file>.v10-customized`
- `init-project.sh --update` (BD-080): `<file>.pre-update`

Sidecars are **single-slot**. If `--update` finds prior `.pre-update`
sidecars in the working tree it refuses to run — the user must
reconcile (edit the destination, remove the sidecar) before re-running.
This prevents a second run from silently overwriting unreconciled
content. The migrator's `S1` stage similarly refuses if its backup
directory already exists.

---

## Diff artifacts

For every `customization-detected-needs-reconciliation` and
`real-merge-required` case, the migrator writes a structured
three-way diff under `<state-dir>/diffs/`:

- BASE → OURS (project edits since the previous pack baseline)
- BASE → THEIRS (pack edits across the same baseline)

Read the diff to understand what each side changed before merging.

---

## A1 fallback (`--dry-run` / `--apply` / `--resume`)

The current migrator runs in single-shot mode: pre-flight → backup →
dispatch → install → report. A re-run requires removing the prior
backup directory.

**BD-095 (shipped 2026-05-10) extended `migrate-v10-to-v11.sh` with three modes:**

- `--dry-run` — emit the dispositions TSV and report without writing
  any project files. Useful for previewing changes before commit.
- `--apply` — the default behavior today (write changes, write
  sidecars, exit). Refuses to run unless a fresh dry-run report exists
  for the current working-tree fingerprint (24h freshness window per
  ARCHITECTURE §6.G). Bare invocation auto-runs `--dry-run` first if
  no fresh dry-run output exists, preserving single-shot UX.
- `--resume` — after the user reconciles sidecar files (written with
  the per-migrator suffix `*.${MIGRATOR_OWN_SIDECAR_SUFFIX}` —
  currently `*.v10-customized` for the v10→v11 migrator), resume the
  migration from the next pending dispatch. Sentinel-based
  (`stage-S<N>.done` files in the migrator's state directory).
  Forward-only; accepts BOTH a `.resolved` flag-file alongside the
  sidecar AND extension removal as conflict-resolution signals
  (ARCHITECTURE §6.H).

**BD-101 (shipped 2026-05-10) added three verification gates** that
fire inside the `--dry-run` and `--apply` modes above. Gates do not
mutate the working tree — they observe and either pass or fail.

- **Gate 1 — pre-migration dry-run summary** fires inside `--dry-run`
  after `_stage_report` writes the dispositions TSV + report.md. It
  validates that no `unknown-classification` rows leaked through and
  that report.md was rendered. Read-only; no recovery needed beyond
  re-running `--dry-run` with a fix.
- **Gate 2 — post-Phase-A verification** fires inside `--apply` after
  S6 (post_report_hook). It checks: trinity addenda landed
  (CLAUDE / AGENTS / GEMINI carry the v11 H2 markers), HELP-FRAGMENT
  files match pack mirrors byte-for-byte, dispositions.tsv has no
  unknown rows, BD-042 / BD-091 relocated docs are in their new
  positions, and `validate-pack.py` passes against the pack source.
- **Gate 3 — post-Phase-B verification** fires inside `--apply` after
  Gate 2 passes, **conditionally** on tracker mode being active at
  the target (`tracker.toml` present with `mode.state = "tracker"`
  and `migration.forward_complete = true`). In flat-file mode it
  prints `[INFO] tracker: skipped` and returns 0. When tracker mode is
  active it checks: `id-map.json` integrity, BACKLOG.md mirror
  freshness, and `pack tracker doctor` exit-status.

**Gate-failure exit code.** A failing gate returns
`EXIT_GATE_FAILED = 31` from the migrator. This slot is intentionally
above the stage-failure range (20..30) so callers / `--resume`
reconciliation logic can distinguish a gate failure from a stage-
internal failure. The exit code is also documented in
`MIGRATION-v10-to-v11.md` Step 1's exit-codes table.

**Gate-failure recovery.** Recovery depends on which gate fired:

- **Gate 1 FAIL** — re-run `--dry-run` after fixing the defect (no
  working-tree mutation has occurred).
- **Gate 2 FAIL** — fix-and-continue is NOT supported. The S4/S5/S6
  sentinels are already marked `.done` by the time Gate 2 fires, so
  `--resume`'s forward-only guard would skip past the failed stages
  without re-firing the gate. The only supported recovery is
  `bash $PACK/scripts/restore-from-backup.sh
  <state-dir>-backup` followed by a fresh `--dry-run` + `--apply`.
  The Gate 2 FAIL banner spells out the exact commands.
- **Gate 3 FAIL** — Phase-A (working tree) is intact, so
  restore-from-backup is the wrong recovery and would discard
  Phase-A work. Run `pack tracker doctor` for a per-check diagnosis
  and follow its printed recovery verbs; if tracker setup is
  unrecoverable, `pack tracker reset` + `pack tracker init` from a
  clean state.

Pre-BD-095 single-shot recipe (still works as the bare invocation
default behavior):

1. Confirm clean working tree.
2. Run `scripts/migrate-v10-to-v11.sh`.
3. Read `.pack-migrate-v10-to-v11/report.md`.
4. For each `customization-detected-needs-reconciliation` row, open
   the named sidecar, merge project content into the destination,
   remove the sidecar, `git add`.
5. Commit.
6. Remove `.pack-migrate-v10-to-v11-backup/` after sufficient
   confidence in the migration result.

---

## Cross-references

- `scripts/lib/customization-preserve.sh` — the BD-088 implementation
- `scripts/lib/customization-report.sh` — the report renderer
- `scripts/tests/test-customization-preserve.sh` — class-coverage tests
- `MIGRATION-v10-to-v11.md` — the user-facing migration narrative
- `OPTIONAL-FEATURES.md` — tracker opt-in walkthrough
- `QUICKSTART.md` — where to start
- `validate-pack.py` Check 25 — CI regression guard for the truthful-report contract

> **Note on `scripts/lib/`.** Files under `scripts/lib/` are pack
> implementation details (sourced by other scripts; never invoked
> directly by users). They are intentionally absent from
> `HELP-FRAGMENT-PACK.md` and `validate-pack.py` Check 22 skips
> `scripts/lib/` and `scripts/tests/` references when scanning user
> docs for verb freshness. To surface a new lib file as a user-facing
> verb, move it to `scripts/<name>.sh` and add it to the help fragment.
