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
files, tracker.toml.example, and issue-template forms route through
this class. The classifier is conservative: when unsure, fall back to
text 3-way which preserves project edits via sidecar.

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

**BD-095 will extend `migrate-v10-to-v11.sh` with three modes:**

- `--dry-run` — emit the dispositions TSV and report without writing
  any project files. Useful for previewing changes before commit.
- `--apply` — the default behavior today (write changes, write
  sidecars, exit).
- `--resume` — after the user reconciles `*.merge-conflict` sidecars,
  resume the migration from the next pending dispatch. Sentinel-based
  (mirrors the v9→v10 migrator's `stage-S*.done` files).

Until BD-095 lands, follow this single-shot recipe:

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
