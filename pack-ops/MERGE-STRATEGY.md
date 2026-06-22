# MERGE-STRATEGY.md — per-file customization preservation contract

> **Audience: pack-internal.** This document is pack-internal reference
> for pack maintainers running the migrator. Project users encounter
> the per-class disposition tokens via the `report.md` produced by the
> migrator; they do not read this file directly. References here to
> other pack-internal docs (e.g., `HELP-FRAGMENT-PACK.md`) and
> pack-shipped agent files are appropriate at this pack-only path.

When `init-project.sh --update` or `scripts/migrate-v10-to-v11.sh`
refresh a project to a newer pack version, every file the migrator touches
is dispatched to a per-class preservation strategy implemented in
`scripts/lib/customization-preserve.sh`. This document is the
**user-readable matrix** of those rules — what each class does, what kind
of customization it preserves, and what to do when the migrator reports a
file as needing manual reconciliation.

The same matrix applies to both upgrade paths: `init-project.sh --update`
and `scripts/migrate-v10-to-v11.sh`. The contract is symmetric.

---

## How to read this document

Every file the migrator touches belongs to one of 11 classes. For each
class:

- **Strategy** — the preservation algorithm
- **What's preserved** — the project-side content that survives a refresh
- **What gets updated** — the pack-side content that gets adopted
- **Disposition tokens** — the labels that appear in `report.md`
- **What to do on `customization-detected-needs-reconciliation`** — the
  action you take when the migrator flags a file for review

Disposition tokens are the truthful-report contract — every file
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

## The 11 file classes

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

### 2. `claude-settings` — `.claude/settings.json`, `.claude/settings.json.example`

**Strategy:** allowlist-based JSON key-merge via `scripts/merge-json.py`.

The classifier auto-emits `claude-settings` for paths matching
`.claude/settings.json`. (The departing v10 `.gemini/settings.json` is
NOT routed through this class on a v10→v11 migration — Gemini is retired
to `gemini-retired-docs/`; Antigravity reads MCP config from
`.agents/mcp_config.json`, not a per-CLI settings file.)

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
`scripts/merge-json.py` writes warnings to `<state-dir>/diffs/...merge-warnings.log`.
Inspect, choose the correct value manually, edit any CLI's settings.json
file (e.g., `project-template/.claude/settings.json`), remove the sidecar.

---

### 3. `claude-mcp-example` — `.mcp.json.example`, `.mcp.json`

**Strategy:** same as `claude-settings` (JSON allowlist via `scripts/merge-json.py`).

The MCP example file is a template; project edits to add custom MCP
servers (e.g., a dev/stage GraphQL endpoint) are preserved.

---

### 3a. `mcp-config-json` — `.agents/mcp_config.json`, `.agents/mcp_config.json.example`

**Strategy:** same as `claude-mcp-example` (JSON allowlist via
`scripts/merge-json.py`).

The Antigravity workspace MCP config is `mcpServers`-shaped JSON, portable
across MCP clients; the class name is CLI-neutral by design. Project edits
to add custom MCP servers, or to tune `BASE_DIR` / `DB_PATH`, are preserved
via key-level union — the structured class preserves project edits in
place rather than clobbering the live file on a both-edited update.

---

### 4. `codex-config` — `.codex/config.toml`, `.codex/requirements.toml`

**Strategy:** allowlist-based TOML key-merge via `scripts/merge-toml.py`.

Mirrors `scripts/merge-json.py`'s contract but at the TOML table level. The
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

### 6. `pm-chat` — `docs/pack/PM-CHAT.md`

**Strategy:** 3-way text dispatch (same as `trinity`).

PM-CHAT.md mixes pack-managed operating rules (pack maintainer behavior,
Stage Coverage spec) with project-specific customizations (project-name
substitution, project-specific role definitions). Both layers must
survive a refresh.

The current implementation routes through the generic 3-way text
dispatcher — same algorithm as `trinity`. The single dispatcher handles
both surfaces correctly when the project keeps marker headers intact.

---

### 7. `custom-agent` — `.claude/agents/x-*.md`, `.codex/agents/x-*.md`, `.agents-plugin/*/agents/x-*.md` (and legacy-READ `.gemini/agents/x-*.md`)

**Strategy:** unconditional preservation. Project-owned by reserved-prefix
contract (V3 §I.4); the pack never ships an `x-`-prefixed agent and the
migrator never overwrites one.

**Surfaces.** The class covers BOTH the loose per-CLI agent dirs
(`.claude/agents/`, `.codex/agents/`) AND the Antigravity plugin bundle
(`.agents-plugin/*/agents/`, e.g. `.agents-plugin/optiquity-agents/agents/`).
The classifier tests the `x-` filename prefix FIRST so a client custom in
the SHARED bundle namespace is told apart from a pack bundle agent and is
protected from replace-if-different. The departing v10 `.gemini/agents/x-*.md` leg is a legacy-READ
carve-out: the migrator classifies the departing Gemini custom so it can
LIFT it into the Antigravity bundle (next paragraph).

**Gemini→Antigravity lift (v10→v11 migration).** On a v10→v11 migration
the client's custom (`x-`) agents are KEPT — the migrator copies each
departing `.gemini/agents/x-*.md` (falling back to `.claude/agents/x-*.md`)
INTO the Antigravity bundle at `.agents-plugin/optiquity-agents/agents/`
so it becomes a live Antigravity agent (it does NOT require manual
re-creation). The whole departing `.gemini/` tree is then moved to
`gemini-retired-docs/` as a BACKUP. The loose `.claude`/`.codex` `x-`
copies stay preserved in place (Claude/Codex still read their loose dirs).

**Disposition:** always `project-only-file` (preservation on bump; the
one-time Gemini→bundle lift is a direct copy, never a clobber of a
same-named bundle custom).

---

### 8. `pack-agent` — `.claude/agents/<non-x>.md`, `.codex/agents/<non-x>.md`, `.agents-plugin/*/agents/<non-x>.md` (and legacy-READ `.gemini/agents/<non-x>.md`)

**Strategy:** 3-way text dispatch — replace-if-different on a pack
version bump.

Pack-shipped agent files (e.g., the pack-architect / pack-reviewer set of
agents at `.claude/agents/` and the Antigravity bundle at
`.agents-plugin/optiquity-agents/agents/`). Pack agents are not
client-modifiable, but a config-pack version bump CAN update them: on a
bump/migrate the new pack agent REPLACES the client's copy when it
DIFFERS (`cmp -s` byte-comparison), ADDs it when the client lacks it, and
preserves a client-edited copy via sidecar when the pack ALSO changed —
identical treatment across the loose surfaces AND the Antigravity bundle.
Trinity rule applies — refreshes are delivered in lockstep across the CLI
variants.

---

### 9. `custom-script` — `scripts/x-*.sh`, `scripts/<project-added>.{sh,py}`

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
enforces). Per-CLI agents under `.claude/agents/x-*.md` /
`.codex/agents/x-*.md` and bundle agents under
`.agents-plugin/*/agents/x-*.md` (plus the legacy-READ `.gemini/agents/x-*.md`)
ARE classified directly to `custom-agent` by name; scripts use the
prefix-by-convention but rely on three-way's project-only-file
classification rather than a dedicated classifier branch.

---

### 10. `pack-script` — `scripts/<pack-shipped>.{sh,py}`

**Strategy:** 3-way text dispatch.

Pack-shipped scripts get the canonical 4-case classification.
Customizations (e.g., a project that added a `--quick-mode` flag to
a pack script) surface as `customization-detected-needs-reconciliation`
with sidecar.

---

### 11. `generic` — everything else

**Strategy:** 3-way text dispatch (default).

Catch-all for files the classifier doesn't recognize. HELP-FRAGMENT
files and issue-template forms route through this class. The classifier
is conservative: when unsure, fall back to text 3-way which preserves
project edits via sidecar.

**v11.0 per-entry trees — source vs regenerated mirror.** Per-entry
tree files under `docs/project/backlog/`,
`docs/project/implementation-plan/`, and `docs/project/changelog/`
(entry files plus the `_rules.md` / `_intro.md` / `_format.md` /
`_toc.md` supporting files) route through `generic` 3-way text
dispatch — they are flat-file source-of-truth in v11.0 and any
project-side hand edit is preserved via sidecar like any other
generic file. The monolithic `docs/project/BACKLOG.md`,
`docs/project/IMPLEMENTATION-PLAN.md`, and `docs/project/CHANGELOG.md`
files are regenerated mirrors of the per-entry trees in flat-file
mode; the migrator overwrites them from the per-entry tree on each
mirror-regeneration step and they are NOT treated as authoritative
edit targets. If a developer hand-edits a mirror between
regenerations, the next regenerator run overwrites the edit; the
`scripts/validate-pack.py` Check 32 (mirror-in-sync) CI gate catches any
committed divergence. See `supporting-docs/MIGRATION-v10-to-v11.md` § "Per-entry
decomposition" for the v10 → v11 decomposition contract and the
`--force-overwrite-mirror` flag semantics for the rare advanced
case where a hand-edited mirror must be force-overwritten.

---

## Per-file notes

### `docs/pack/PLATFORM-SKILLS.md` (v11 reframe)

**Class:** routes through `generic` (3-way text dispatch with
sidecar) for the body. Two `## Custom *` H2 sections at the bottom
are project-owned and preserved verbatim by the sidecar mechanism.

**v11 reframe note.** v11 reshapes the file from
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
**byte-identical** by the customization-preserve sidecar
mechanism — the migrator does NOT rewrite them, even when the
column headers inside them are stale. The v11 illustrative-row
column headers are `Base skills | Dimensional skills` (replacing
the v10 `Tier 1 skills | Tier 2 skills`); projects with real custom
rows under the deprecated v10 headers keep those headers
post-migration and rename them manually. See
`supporting-docs/MIGRATION-v10-to-v11.md` § "Skill model changes" for the
manual-rename note and `supporting-docs/INSTALL-PROCEDURES.md` § "Procedure 5.1"
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
§ "Monorepo D5 scoping note" and in `supporting-docs/MIGRATION-v10-to-v11.md`
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

- `scripts/migrate-v10-to-v11.sh`: `<file>.v10-customized`
- `init-project.sh --update`: `<file>.pre-update`

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

**`scripts/migrate-v10-to-v11.sh` has three modes:**

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

**Three verification gates** fire inside the `--dry-run` and `--apply`
modes above. Gates do not mutate the working tree — they observe and
either pass or fail.

- **Gate 1 — pre-migration dry-run summary** fires inside `--dry-run`
  after `_stage_report` writes the dispositions TSV + report.md. It
  validates that no `unknown-classification` rows leaked through and
  that report.md was rendered. Read-only; no recovery needed beyond
  re-running `--dry-run` with a fix.
- **Gate 2 — post-Phase-A verification** fires inside `--apply` after
  S6 (post_report_hook). It checks: trinity addenda landed
  (CLAUDE / AGENTS / GEMINI carry the v11 H2 markers), HELP-FRAGMENT
  files match pack mirrors byte-for-byte, dispositions.tsv has no
  unknown rows, relocated docs are in their new
  positions, and `scripts/validate-pack.py` passes against the pack source.
- **Gate 3 — post-Phase-B verification** fires inside `--apply` after
  Gate 2 passes and runs only in tracker mode; in flat-file mode it
  prints `[INFO] tracker: skipped` and returns 0.

**Gate-failure exit code.** A failing gate returns
`EXIT_GATE_FAILED = 31` from the migrator. This slot is intentionally
above the stage-failure range (20..30) so callers / `--resume`
reconciliation logic can distinguish a gate failure from a stage-
internal failure. The exit code is also documented in
`supporting-docs/MIGRATION-v10-to-v11.md` Step 1's exit-codes table.

**Gate-failure recovery.** Recovery depends on which gate fired:

- **Gate 1 FAIL** — re-run `--dry-run` after fixing the defect (no
  working-tree mutation has occurred).
- **Gate 2 FAIL** — fix-and-continue is NOT supported. The S4/S5/S6
  sentinels are already marked `.done` by the time Gate 2 fires, so
  `--resume`'s forward-only guard would skip past the failed stages
  without re-firing the gate. The only supported recovery is to
  restore the working tree from the migrator's `.pack-migrate-v10-to-v11-backup/`
  mirror via `rsync -a --delete --exclude=.git/ --exclude=.pack-migrate-v10-to-v11-backup/ .pack-migrate-v10-to-v11-backup/ ./`
  followed by a fresh `--dry-run` + `--apply`. The Gate 2 FAIL banner
  spells out the exact commands; the canonical recipe also lives in
  `supporting-docs/MIGRATION-v10-to-v11.md` §Rollback. (Note: the legacy
  `scripts/restore-from-backup.sh` is for v9.3→v10 backups and does
  NOT apply to v10→v11; the v10→v11 backup is a faithful working-tree
  mirror with no path flattening.)
- **Gate 3 FAIL** — does not occur in flat-file mode: Gate 3 runs
  only in tracker mode and is skipped otherwise.

Single-shot recipe (the bare invocation default behavior):

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

These are the pack-internal touch points for the customization-preservation contract.

- `scripts/lib/customization-preserve.sh` — the implementation
- `scripts/lib/customization-report.sh` — the report renderer
- `scripts/tests/test-customization-preserve.sh` — class-coverage tests
- `supporting-docs/MIGRATION-v10-to-v11.md` — the user-facing migration narrative
- `QUICKSTART.md` — where to start
- `scripts/validate-pack.py` Check 25 — CI regression guard for the truthful-report contract

> **Note on `scripts/lib/`.** Files under `scripts/lib/` are pack
> implementation details (sourced by other scripts; never invoked
> directly by users). They are intentionally absent from
> `pack-ops/HELP-FRAGMENT-PACK.md` and `scripts/validate-pack.py` Check 22 skips
> `scripts/lib/` and `scripts/tests/` references when scanning user
> docs for verb freshness. To surface a new lib file as a user-facing
> verb, move it to `scripts/<name>.sh` and add it to the help fragment.
