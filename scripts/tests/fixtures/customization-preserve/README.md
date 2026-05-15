# scripts/tests/fixtures/customization-preserve/

Synthetic fixtures for BD-088 customization-preservation library coverage
(BD-096). Each fixture is a directory containing v10-shape project files
in three roles — `base/` (previous pack baseline), `ours/` (project
current), `theirs/` (new pack template) — plus a `manifest.tsv`
describing what each file should classify as and what disposition the
algorithm must record.

The runner `scripts/tests/test-customization-preserve.sh` enumerates each
fixture's manifest, calls `customization_preserve` for every row, and
asserts the recorded disposition + class match expectations. Optional
`assertions.tsv` adds content checks against the destination or sidecar
file the algorithm wrote.

## The five fixtures

Together the five fixtures span the practical customization-shape space
that v10→v11 migration must handle. None of them is the OT project
itself — they are general-use scenarios; OT happens to be one realistic
shape (captured in `v10-with-customization/`).

### 1. `lightly-customized-minimal/`

Smallest realistic project: trinity files unchanged from baseline, one
custom `x-` agent, and one minor pack-shipped config tweak. Exercises
the "happy path" where almost nothing needs reconciliation. Disposition
mix is dominated by `unchanged-pack` and `pack-update-applied`.

**Customization shape:**
- Trinity (CLAUDE/AGENTS/GEMINI.md) untouched.
- One `.claude/agents/x-tiny-helper.md` custom agent.
- One `.claude/settings.json` allow-list addition (project-perm).

### 2. `heavily-customized/`

Heavy customization across many file classes: trinity edited, multiple
custom agents across all three CLI directories, a custom script,
edited PM-CHAT.md, and structured-config edits in both `.claude/settings.json`
and `.codex/config.toml`. Exercises the worst-case
`customization-detected-needs-reconciliation` and merge paths.

**Customization shape:**
- All three trinity files have project edits AND pack edits → real merge.
- 3 custom agents (one per CLI: `.claude/agents/x-arch.md`,
  `.codex/agents/x-coder.md`, `.gemini/agents/x-doc.md`).
- 1 custom script `scripts/x-deploy.sh` (project-only).
- 1 pack script `scripts/bootstrap.sh` with project edits + pack edits → sidecar.
- `.claude/settings.json` with project allow-list additions + pack additions → JSON merge.
- `.codex/config.toml` with project tool entry + pack new section → TOML merge.
- `docs/pack/PM-CHAT.md` with project + pack edits → real merge.

### 3. `language-heterogeneous/`

Multi-language project (Swift + Python + gRPC). `.gemini/.env`
`AGENT_CAPABILITIES` lists multiple languages and additional
project-set keys; some pack scripts updated, others customized in place.
Exercises gemini-env preservation and multi-language pack-script update.

**Customization shape:**
- `.gemini/.env` AGENT_CAPABILITIES=swift,python,grpc + PROJECT_VAR additions
  vs pack default AGENT_CAPABILITIES=swift + new PACK_VAR.
- `scripts/test-swift.sh`, `scripts/test-python.sh` unchanged (pack updates apply).
- `scripts/format-swift.sh` project-edited + pack-edited → sidecar.
- 1 custom agent `.claude/agents/x-grpc-coder.md`.

### 4. `custom-agents-heavy/`

Focuses on custom-agent surface across all three CLIs. Multiple `x-`
agents per CLI directory, plus a couple of pack-shipped agents that
the project edited (forcing the `pack-agent` text-merge path).

**Customization shape:**
- 6 custom agents total (2 per CLI directory, all `x-` prefixed).
- 1 pack agent `.claude/agents/pack-reviewer.md` project-edited
  while pack also edited → sidecar.
- 1 pack agent `.codex/agents/pack-coder.md` unchanged (pack update applies).
- 1 pack agent `.gemini/agents/pack-architect.md` project-edited only
  (no pack change) → preserved.

### 5. `v10-with-customization/`

The OT-modeled fixture from BD-088 (modeled on the OT post-migration
audit per BD-059 context), kept as a directory-based fixture for
parity with the other four. Inline TSV-style cases in
`test-customization-preserve.sh` Groups 1-7 still cover the algorithmic
unit tests; this fixture is the directory-based end-to-end equivalent.

**Customization shape:**
- `.claude/settings.json` with `XCODE_SCHEME` env var + custom permissions.
- `.codex/config.toml` with `[model_providers.ollama]` removed by project,
  `[model_providers.lmstudio]` added by pack.
- `.gemini/.env` with project AGENT_CAPABILITIES + new pack key.
- `CLAUDE.md` trinity with project + pack edits.
- One `x-` custom agent `.claude/agents/x-ot-reviewer.md`.

## Manifest format

`manifest.tsv` (tab-separated, header line begins with `#`):

```
# rel_path	class	expected_disposition	notes
CLAUDE.md	trinity	customization-detected-needs-reconciliation	project + pack edits
.claude/agents/x-tiny.md	custom-agent	project-only-file	project-only x- agent
```

Columns:

1. `rel_path` — project-relative path (matches what real migrations see).
2. `class` — explicit class hint passed to `customization_preserve` (use
   `auto` to let the algorithm classify from `rel_path`).
3. `expected_disposition` — must equal the disposition token recorded
   in `dispositions.tsv` after the call.
4. `notes` — human-readable description (not asserted; for fixture authors).

Triplet presence rules:

- Each fixture supplies whichever subset of `base/<rel>`, `ours/<rel>`,
  `theirs/<rel>` matches the customization scenario. Missing files
  are passed as empty paths to `customization_preserve` (per the
  library's own contract — empty inputs route through the
  three-way classifier's absence handling).

## Assertions format (optional per fixture)

`assertions.tsv` (tab-separated, header line begins with `#`):

```
# rel_path	side	required_substring	notes
.gemini/.env	dest	AGENT_CAPABILITIES=swift,python,grpc	project value wins
.claude/settings.json	dest	XCODE_SCHEME	project key preserved
CLAUDE.md	sidecar	project edit marker	pre-update copy keeps project edits
```

Columns:

1. `rel_path` — must appear in the corresponding `manifest.tsv`.
2. `side` — `dest` (the file the algorithm wrote to the dest path) or
   `sidecar` (the `.pre-update` file the algorithm wrote alongside dest).
3. `required_substring` — file content must contain this substring.
4. `notes` — human-readable.

## Determinism

Fixture content is deterministic: no timestamps, no machine paths, no
host-specific values. The runner copies fixture files to a temp
directory, calls the library, and asserts. Cleanup is automatic.
