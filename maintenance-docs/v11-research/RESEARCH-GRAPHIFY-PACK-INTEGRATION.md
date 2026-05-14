# RESEARCH-GRAPHIFY-PACK-INTEGRATION.md

Read-only research report. Analyzes how Graphify (open-source knowledge-graph
builder; see `/Users/david/Developer/__external-docs/optiquity-ai-agent-config-pack/How to Use Graphify.txt`)
would integrate with the Optiquity AI Agent Config Pack. Covers both flavors:

- **(A) Pack development** — the maintainer's workflow against the pack repo itself
  (v10.1 tip at `/Users/david/Developer/optiquity-ai-agent-config-pack/`, v11-dev at
  `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/`).
- **(B) Client project development** — projects that install the pack via
  `init-project.sh` and run the per-project agents on Swift / Python / gRPC code.

All file:line citations refer to the **v11-dev tree** unless otherwise noted,
since v11 is the deployed target. Where v10.1 differs materially, the v10.1
path is cited explicitly.

---

## 1. Current RAG / context strategy

The pack today uses **`mcp-local-rag`** — an MCP server that ingests
markdown files into a local embedding store and exposes `list` / `ingest` /
`delete` tools to the PM Chat. The strategy is deliberately minimal.

**Who ingests what.** Authoritative declaration of the RAG set lives in the
per-project `docs/pack/PM-CHAT.md` § **RAG ingestion manifest** at
`project-template/docs/pack/PM-CHAT.md:133-170` (v11-dev). The default
manifest is **exactly one file**:

> "This project's RAG index (`mcp-local-rag`) ingests exactly **one**
> file: `docs/pack/METHODOLOGY.md`. All other project files are direct-read."
> — `project-template/docs/pack/PM-CHAT.md:135-137`

Projects may add files under `## Additional project documents`; rows whose
access-method begins with `RAG query` join the manifest, rows whose
access-method begins with `Direct read` do not
(`project-template/docs/pack/PM-CHAT.md:159-170`).

**When and by whom ingestion happens.** PM-startup Step 4 reconciles the
live index against the manifest on **every** `/pm-startup` invocation
(canonical at `project-template/skills/pm-startup/SKILL.md:97-169`).
The same reconciliation procedure is duplicated into the three per-CLI
surfaces (validator Check 28 enforces parity — see
`scripts/validate-pack.py` header lines 78-84):

- `project-template/.claude/skills/pm-startup/SKILL.md`
- `project-template/.codex/skills/pm-startup/SKILL.md` (cited refs at lines 99, 110, 117, 127, 139, 142, 149)
- `project-template/.gemini/commands/pm-startup.toml` (cited refs at lines 96, 107)

**The reconciliation contract.** From
`project-template/skills/pm-startup/SKILL.md:130-145`:

- **Orphans** (in index, not in manifest) → auto-deleted.
- **Stale** (manifest path mtime > ingest timestamp) → delete + re-ingest.
- **Missing** (manifest path not in index) → ingest.
- Diff appears as the `RAG:` line of the startup summary (Step 6 line at
  `project-template/skills/pm-startup/SKILL.md:198`).

**Why orphans matter.** `supporting-docs/METHODOLOGY.md:140-184` (v11-dev)
codifies the *"orphans are confidently-wrong retrievals"* principle:

> "A retired-path chunk that lingers in the index is returned by future
> queries and cited as if it were current content. The PM chat receives
> confidently-wrong retrievals — stale guidance, dead paths, removed file
> references — with no signal that the source is gone."
> — `supporting-docs/METHODOLOGY.md:148-154`

**How each CLI sees the server.** The `local-rag` MCP server is wired
through three parallel surfaces:

- Claude: `project-template/.mcp.json.example` lines 4-15 declares
  `mcpServers.local-rag` with `BASE_DIR` / `DB_PATH` / `CACHE_DIR`
  env keys.
- Codex: `project-template/.codex/config.toml.example:19-26` ships the
  block **commented out**; user uncomments to opt in.
- Gemini: `project-template/.gemini/settings.json:3-12` has the same
  block live (Gemini ships it active, with `BASE_DIR` placeholder).

**Key takeaway.** Today's "RAG" is a single-file embedding store of
`METHODOLOGY.md`, with a robust hygiene contract. **Everything else is
direct read** (per the table at `project-template/docs/pack/PM-CHAT.md:125-131`).
The pack treats RAG as a narrow optimization for one large, stable
document — not a general context-curation layer.

---

## 2. Per-CLI context surfaces

### 2.1 Skill directories

- Claude: `.claude/skills/` — `SKILL.md` files with YAML frontmatter
  (`name`, `description`, `allowed-tools`). Example:
  `project-template/skills/pm-startup/SKILL.md:1-5` (canonical), copied per
  validator Check 28 into `.claude/skills/pm-startup/`.
- Codex: `.codex/skills/` — same `SKILL.md` shape, parallel copies.
  Inventory at `.codex/skills/`: `architecture-review`, `commit-discipline`,
  `dependency-intake`, `documentation`, `implementation-report`, `pack-help`,
  `pack-startup`, `planning`, `review`, `verification-harness`.
- Gemini: `.gemini/commands/` — TOML command files
  (e.g. `pack-startup.toml`, `pack-help.toml`). **Note asymmetry:** Gemini
  uses `commands/`, not `skills/`. Project-template-side Gemini also has
  `.gemini/skills/` for skills shared with the project-template-side roster.

### 2.2 Agent directories

- Claude (`.claude/agents/`): markdown with YAML frontmatter (16 agents in
  `project-template/.claude/agents/` v11-dev — `architect.md`, `coder.md`,
  …, `auditor-*.md`). Pack-side has 5 agents in
  `.claude/agents/`: `pack-architect.md`, `pack-coder.md`,
  `pack-docs-researcher.md`, `pack-planner.md`, `pack-reviewer.md`.
- Codex (`.codex/agents/`): TOML files, same per-agent inventory.
- Gemini (`.gemini/agents/`): markdown with YAML frontmatter (native
  Gemini subagent format).

Validator Check 5 enforces equal agent-file counts across the three CLI dirs
(`scripts/validate-pack.py` header line 10).

### 2.3 Trinity files

`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` exist in both the pack root and
`project-template/`. The trinity rule (`CLAUDE.md:68-79` v11-dev pack root)
requires parallel edits across all three; tool-specific asymmetry is allowed
only when provable. Validator Checks 16 / 17 / 18 enforce H2-structure
parity and content symmetry
(`scripts/validate-pack.py` header lines 36-48).

### 2.4 Where Graphify-generated graph data could be referenced

Graphify outputs three artifacts (per the Graphify README at
`/Users/david/Developer/__external-docs/optiquity-ai-agent-config-pack/How to Use Graphify.txt:37-41`):

- `graph.json` — machine-readable, queried by the AI assistant.
- `graph.html` — human-readable viewer.
- `GRAPH_REPORT.md` — provenance audit.
- Optional `--obsidian` Vault for visual navigation.

Cross-CLI parity options:

- **CLI-neutral**: write artifacts to a `.pack-graph/` or `docs/pack/graph/`
  directory that the trinity files reference identically. Any CLI agent can
  Read the artifacts via its standard `Read` tool. This preserves trinity
  symmetry.
- **Hook-specific (asymmetric)**: Graphify's PreToolUse hook is currently
  Claude-only (per the Graphify article line 47). Codex has its own hook
  surface; Gemini has hooks too; the *hook integration* is necessarily
  per-CLI and would be a documented trinity exemption similar to the
  v11-dev *Sub-agent isolation (Claude-only)* exemption at
  `CLAUDE.md:139-153`.

**Recommendation.** Keep the *artifact location* trinity-symmetric (so
agents on any CLI can Read `.pack-graph/graph.json`). Document the
*hook integration* as a per-CLI optional in `OPTIONAL-FEATURES.md` — each
CLI gets its own opt-in section, no trinity mirroring required.

---

## 3. Agent invocation flow

### 3.1 `scripts/agent-run.sh`

Lives at `project-template/agent-run.sh` (deployed to client repos by
`init-project.sh`). Reviewed at lines 30-129 (configuration block):

- **Read-only agents** (`architect`, `reviewer`, `planner`, `tester`,
  `docs-researcher`, `grpc-schema`, all `auditor-*`) receive CLI-appropriate
  read-only flags (`project-template/agent-run.sh:38-53, 95-129`):
  - Claude: `--permission-mode bypassPermissions
    --disallowedTools Bash(git commit:*) Bash(git push:*)` (lines 96-99).
  - Codex: `--sandbox workspace-write -a never` (lines 110-113).
  - Gemini: default mode (lines 122).
- **Write agents** (`coder`, `repo-ops`) run with defaults
  (or `--approval-mode=yolo` for Gemini, lines 127-129).

### 3.2 What each agent reads at startup

Per `PACK-AGENTS.md:147-154` (pack root, v11-dev):

> "1. Reads its tool-native context file before starting:
> Claude Code → CLAUDE.md · Codex → AGENTS.md · Gemini → GEMINI.md"

Plus skills loaded via the `## Skill loading` section in the trinity files
(referenced at `project-template/skills/pm-startup/SKILL.md:90-94`).

The PM Chat curates *per-invocation* context via prompt content; agents read
files explicitly named in the prompt or required by their definition
(`PACK-AGENTS.md:154-158`). They do **not** auto-read the codebase.

### 3.3 Agents that would benefit most from a graph

- **`architect` / `pack-architect`** — cross-cutting design decisions
  benefit from "all call sites of X" / "all references to module Y" queries
  that today require multiple grep passes.
- **`reviewer` / `pack-reviewer`** — call-site verification, downstream
  impact of a changed signature.
- **`docs-researcher` / `pack-docs-researcher`** — mixed-format research
  (the article emphasizes Graphify ingests PDFs, images, video transcripts
  via faster-whisper — see article lines 23-32; this maps onto the
  pack's `__external-docs/` directory shape).
- **`auditor` and the seven `auditor-*` subagents** — the auditor's job is
  to find usage patterns across the codebase
  (`supporting-docs/METHODOLOGY.md:893-918` references the
  cluster model); a graph reduces this from full-repo grep to
  subgraph retrieval.
- **`planner` / `pack-planner`** — file-dependency analysis (cited as
  pack-planner's role at `PACK-AGENTS.md:16`) is *exactly* what a
  call-graph + import-graph encodes.

Agents that would benefit **least**: `coder` (already scope-narrow with
explicit Edit/Write targets), `repo-ops` (operates on git state, not code
structure), `grpc-schema` (proto-file scoped; tree-sitter has proto3 support
but the proto surface is small).

---

## 4. GH-issue tracker integration in v11

### 4.1 What the tracker surface looks like

`scripts/pack-tracker.sh` (v11-dev, 436 lines) is the verb dispatcher.
Verb surface at `scripts/pack-tracker.sh:4-21`:

- `init` — opt-in: writes `tracker.toml`, validates auth, runs forward
  migration (BACKLOG.md → GH Issues).
- `status` — mapping freshness, mode, mirror state.
- `disable` — reverse migration: reads live issues, writes sidecar
  BACKLOG.md, flips `[mode].state` back to flat-file.
- `doctor`, `update-templates`, `mirror-rebuild`,
  `enable-recommendations`.

Backing libs in `scripts/lib/` (v11-dev):

- `tracker-provider.sh` / `tracker-provider-gh.sh` — provider abstraction
  for `gh` (Forgejo / Linear / Jira plug in later; only `gh` ships in v11.0
  per `OPTIONAL-FEATURES.md:127-132`).
- `tracker-migrate-forward.sh` / `tracker-migrate-reverse.sh`.
- `tracker-mirror.sh` — flat-file mirror writers.
- `tracker-sidecar.sh` — reconciliation sidecars on real-merge cases.
- `recommendation.sh` — inflection-point recommendation engine
  (per `OPTIONAL-FEATURES.md:138-145`).

### 4.2 How a Graphify graph would interact

- **Issue bodies as graph nodes?** Each GH issue body is a markdown
  document with structured BD-NNN identifiers (currently up to BD-155 per
  the BACKLOG inspection). The tracker mirror writes per-issue
  bodies to disk; Graphify could ingest them as Pass-3 LLM-extraction
  material to build a `BD-N → BD-N` dependency graph (matching today's
  ad-hoc `BD-NNN → BD-NNN` "blocked by" lines).
- **Issue ↔ BACKLOG.md mapping.** The tracker mapping lives at
  `.pack-tracker/mapping.json` (gitignored — `.gitignore` v11-dev pack root
  lines 11-15). Graphify could ingest this as a typed edge set (`BD-NNN`
  node → `gh-issue/N` node, provenance `EXTRACTED`, confidence 1.0).
- **Cadence implication.** If Graphify ingests the mirror, the graph
  rebuild needs to follow tracker-state-changing verbs. The natural
  trigger points are `pack-tracker.sh mirror-rebuild` (an event already
  produced) and `pack-tracker.sh init` / `disable` (mode flips).

### 4.3 Should the graph track BACKLOG ↔ GH-issue mappings?

**Yes** — but as a *consumer* of the existing tracker mapping, not a
parallel source of truth. The tracker's `[mode].state` field
(`tracker.toml.pack-example`) is authoritative; Graphify would re-derive
edges on rebuild. The graph never writes back to the tracker.

---

## 5. Pack validators

`scripts/validate-pack.py` ships 28+ numbered checks (header at lines 1-113
v11-dev). Validator extensions needed if Graphify becomes a pack component:

- **New check: Graphify artifact gitignore.** Mirror Check 20 (pack
  `.gitignore !.env.example` exception, header lines 49-51) — add a check
  that `.pack-graph/`, `graph.json`, `graph.html`, `GRAPH_REPORT.md`, and the
  optional Obsidian Vault dir are listed in `project-template/.gitignore`
  *and* the pack-root `.gitignore`.
- **New check: graph freshness sentinel.** Mirror the RAG manifest hygiene
  contract (Check 28 — see `scripts/validate-pack.py` header lines 78-84):
  if `.pack-graph/graph.json` exists, its mtime must be more recent than
  the most recent commit on the active branch. (Soft warn — don't hard-fail
  in CI, since CI itself runs after commit.)
- **Skip-list extension.** Add `.pack-graph/` to validator's path-skip
  filters (the same way `.git/`, `.pack-migration-backup/`,
  `.pack-tracker/` are skipped today — search for "skip" patterns in
  `validate-pack.py` body).
- **Check 28 parity extension.** If a Graphify integration ships a
  per-CLI hook config, parity must be validated across `.claude/`,
  `.codex/`, `.gemini/` — same shape as today's pm-startup parity check.
- **Optional: Check on Graphify version pin.** If the pack pins a known-good
  Graphify version (per §10 below), validate that the pin matches what
  setup docs say.

---

## 6. Optionality model

The pack already has a well-defined "optional feature" convention codified
in `OPTIONAL-FEATURES.md` (v11-dev). Inspected the full file:

- Each entry has the shape: **Status** / **What it is** / **When it
  matters** / **How to enable** / **How to use the pack's pieces with it** /
  **Caveats** / **When to skip** (`OPTIONAL-FEATURES.md:215-228`
  — the "Adding new entries" section is literally the shape spec).
- Existing entries: **Claude Code Agent Teams** (Claude-only, gated by
  `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, lines 19-109), **Tracker
  integration v11** (cross-CLI, opt-in per-surface, lines 125-211).
- **Defaults stance.** "The Config Pack stays cross-CLI by default. Opt in
  per-feature when the benefit outweighs the asymmetry."
  (`OPTIONAL-FEATURES.md:14-15`).

**Graphify fits this shape cleanly.** A new section `## Graphify
knowledge-graph integration` follows the same template. **Status** would be
"experimental, opt-in per-surface (pack repo and per-project repo opt in
independently)" — mirroring the tracker entry's stance at
`OPTIONAL-FEATURES.md:127-132`.

**Opt-in verb.** The pack convention is a `pack <thing> init` / `pack
<thing> disable` pair (tracker pattern, `OPTIONAL-FEATURES.md:147-154`).
For Graphify: `bash scripts/pack-graphify.sh init` / `... rebuild` /
`... query <node>` / `... disable`.

---

## 7. Trinity rule implications

### 7.1 Where Graphify state would land

- **Pack memory in CLAUDE.md** — Graphify's PreToolUse hook (per article
  line 47) attaches at the Claude Code hook surface. The hook needs a
  config entry in `.claude/settings.json`. **This is Claude-specific**.
- **AGENTS.md / GEMINI.md mirrors** — Codex and Gemini both support hooks
  in their own forms (the pack already exploits Codex's TOML config and
  Gemini's `settings.json` hooks). Parity requires per-CLI hook configs,
  not literal trinity copies.

### 7.2 Comparable precedent

The v11-dev *Sub-agent isolation (Claude-only)* rule at
`CLAUDE.md:139-153` (pack root) is the canonical trinity-exemption
template:

> "**Trinity exemption.** This rule is Claude-specific (not mirrored
> in `AGENTS.md` / `GEMINI.md`) because it concerns Claude Code's
> Agent tool behavior." — `CLAUDE.md:151-153`

A Graphify hook-config rule would carry the same shape: "This rule is
[Claude/Codex/Gemini]-specific because it concerns [CLI]'s PreToolUse
hook surface."

### 7.3 The asymmetry decision

- **Symmetric part** (mirror in all three trinity files): the *fact* that
  the project has graph artifacts at `.pack-graph/`, the manifest of what
  Graphify ingests, the "graph is stale → rebuild" rule.
- **Asymmetric part** (per-CLI sections, no mirror required): hook
  registration syntax. Document each in `OPTIONAL-FEATURES.md`, not in
  the trinity files.

This keeps the trinity rule clean and validator Check 18 happy.

---

## 8. Graph staleness in a fast-moving repo

The pack churns: v11-dev shows 5 commits across the 5 most recent log
entries, all dated within the same week. A day-old graph is stale.

### 8.1 Rebuild triggers — pack-dev (flavor A)

- **`/pack-startup`** — runs at session start. But the article notes
  Pass-3 LLM extraction takes time (parallel subagents). Rebuilding on
  every startup is too aggressive. **Recommended: detect-only on
  `/pack-startup`**, mirroring how Check 28's RAG reconciliation surfaces
  the diff in the startup summary. Add a `Graphify:` summary line:
  `Graphify: graph age 6h / N nodes / M edges` or
  `Graphify: stale (last build 3d ago, 27 commits since) — run pack graphify rebuild`.
- **Post-commit hook** — too aggressive in a 20-commit-per-day cycle;
  causes thrash during batch BD work.
- **Pre-PR hook** — natural fit. Aligns with the existing PR-gate validate
  step (`Validate Pack` GH Actions workflow). But the pack's daily flow is
  multi-commit-per-batch, so a pre-PR rebuild is the right granularity.
- **Manual `pack graphify rebuild` verb** — primary mechanism. Aligns
  with the tracker's `mirror-rebuild` precedent
  (`scripts/pack-tracker.sh:72-74`).

### 8.2 Rebuild triggers — client-project (flavor B)

Client projects move at a different cadence — typically multiple commits
per day during active phases, idle for days between phases. Recommended:

- **`/pm-startup`** — detect-only, surface a `Graphify:` line in the Step 6
  summary block (`project-template/skills/pm-startup/SKILL.md:187-201`).
- **Pre-phase-gate rebuild** — phase gates are explicit decision points in
  the v11 workflow (per `supporting-docs/METHODOLOGY.md` Workflow 4); a
  rebuild before phase-gate review aligns with when the developer pauses
  for cross-cutting analysis anyway.
- **No post-commit hook** — same reasoning as pack-dev.

### 8.3 The right cadence

| Surface | Cadence | Trigger |
|---|---|---|
| Pack-dev | On-demand + pre-PR | Manual `pack graphify rebuild`, GitHub Action on PR open |
| Client | On-demand + pre-phase | Manual `pack graphify rebuild`, before phase-gate review |
| Both | Detection only | `/pm-startup` and `/pack-startup` surface `Graphify:` line |

This pattern is **identical in shape** to the RAG reconciliation
contract — detect always, rebuild on signal — so it slots into the existing
mental model.

---

## 9. What would have to change in the pack

Concrete diff surface to ship Graphify as an optional pack feature:

### 9.1 New per-CLI skill / command files

Mirror the pm-startup pattern (validator Check 28). Canonical lives at
`project-template/skills/graphify/SKILL.md`; per-CLI copies at:

- `project-template/.claude/skills/graphify/SKILL.md`
- `project-template/.codex/skills/graphify/SKILL.md`
- `project-template/.gemini/commands/graphify.toml`

Pack-side parallel (for pack-dev flavor A):

- `.claude/skills/graphify/SKILL.md`
- `.codex/skills/graphify/SKILL.md`
- `.gemini/commands/graphify.toml`

### 9.2 Setup doc

Parallel to `supporting-docs/CLI-PM-SETUP.md` (v11-dev). New file:
`supporting-docs/CLI-GRAPHIFY-SETUP.md`. Documents install
(`pip install graphifyy`), BASE_DIR semantics, per-CLI hook
registration, troubleshooting (same shape as
`CLI-PM-SETUP.md:199-238`).

### 9.3 `.gitignore` entries

Pack root `.gitignore` (v11-dev, lines 1-30) and
`project-template/.gitignore` (lines 1-10) add a new block:

```
# ── Graphify artifacts (BD-NNN) ─────────────────────────────────────────
# Generated graph files; regenerable from source. Never committed.
.pack-graph/
graph.json
graph.html
GRAPH_REPORT.md
# Optional Obsidian Vault
ObsidianVault/
```

Place it adjacent to the `.pack-tracker/` block (v11-dev pack-root
`.gitignore:9-15`) to keep the "regenerable local state" entries
grouped.

### 9.4 Validator extensions

Per §5 above: 1 new gitignore check, 1 new freshness sentinel, skip-list
extension, optional version-pin check.

### 9.5 HELP-FRAGMENT updates

Two files:

- `HELP-FRAGMENT-PACK.md` (v11-dev, lines 7-20): add row
  `bash scripts/pack-graphify.sh <verb>` to the **Pack scripts** table.
- `HELP-FRAGMENT-TRACKER.md` (byte-identical pack-root + project-template
  per validator Check 24, header lines 62-64) — N/A; Graphify is independent
  of tracker.
- New `HELP-FRAGMENT-GRAPHIFY.md` would be overkill given verb count;
  inline rows in the existing fragments are enough.

### 9.6 Scripts

New `scripts/pack-graphify.sh` dispatcher (mirroring
`scripts/pack-tracker.sh` shape, lines 57-100). Verbs:

- `init` — install Graphify if missing, configure hooks per-CLI, run first
  build.
- `rebuild` — re-run `graphify .` from repo root, capture artifacts.
- `status` — graph age, node/edge counts, last build commit SHA.
- `query <node>` — passthrough to Graphify's subgraph retrieval.
- `disable` — remove hooks, optionally `rm -rf .pack-graph/`
  (per-step approval per the user's `feedback_no_destructive_without_approval`
  rule in MEMORY.md).

### 9.7 Optional new agent / skill

A `graph-query` *skill* (not agent) is sufficient — agents that benefit
(architect, reviewer, auditor, docs-researcher per §3.3) load the skill via
the standard `## Skill loading` mechanism. A dedicated agent is overkill;
the skill encapsulates the query-graph-then-narrow-to-files pattern.

### 9.8 Migration story

For existing v11.x projects opting in mid-project: `pack graphify init`
must be **idempotent** and **reversible** (matching the tracker contract
at `OPTIONAL-FEATURES.md:188-211`). No data migration needed — the graph
is derived from source. The reverse is `pack graphify disable` (removes
hooks, optionally deletes artifacts).

### 9.9 Pack-side trinity additions

`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` (both pack root and
`project-template/`) gain a single-paragraph note under a new H3 under
`## Pack memory` referring to `OPTIONAL-FEATURES.md § Graphify` —
exactly the way the tracker is referenced today. **Stay symmetric** across
the three trinity files for this note; defer per-CLI asymmetry to the
`OPTIONAL-FEATURES.md` entry's "How to enable" subsection.

---

## 10. Maintenance burden

### 10.1 Upstream version pinning

Graphify's article cites `pip install graphifyy` (note the double-`y`).
This is a young project — schema drift is the real risk. **Recommendation:
pin a known-good version** in setup docs and (optionally) in a
`requirements-graphify.txt`-style file at the pack root. Validator could
check the pin matches what `CLI-GRAPHIFY-SETUP.md` documents.

### 10.2 Schema drift detection

Graphify outputs `graph.json` with EXTRACTED / INFERRED / AMBIGUOUS
provenance tags (article line 42). If Graphify changes its schema (e.g.,
adds a new tag, restructures edges), pack queries break. **Mitigation**:
ship a schema-version-detect step in `pack-graphify.sh status` that
parses `graph.json` and warns on unrecognized versions.

### 10.3 Per-CLI hook API drift

The pack already lives with this risk for `mcp-local-rag` (the
troubleshooting block at `supporting-docs/CLI-PM-SETUP.md:208-212` cites
"the vector index format may change between versions"). Graphify's
PreToolUse hook depends on each CLI's hook surface, which evolves:

- Claude: `.claude/settings.json` hook shape exists today (used at
  `project-template/.claude/settings.json:26-39` for `PostToolUse`).
  Graphify uses `PreToolUse` — new matcher, new shape. Surface known.
- Codex: hook surface is younger and less documented. Validate with
  `pack-docs-researcher` agent (per `PACK-AGENTS.md:19`) before shipping.
- Gemini: ditto.

**Recommendation**: a `pack-docs-researcher` quarterly cadence to verify
each CLI's hook API is unchanged, mirroring the existing
docs-researcher cadence for CLI feature drift.

### 10.4 Doc currency

The "How to Use Graphify" article itself will drift. The pack's
`CLI-GRAPHIFY-SETUP.md` should cite the upstream Graphify repo URL and
include a "Verified against Graphify vX.Y.Z" line — the same convention
the pack already uses for METHODOLOGY's version stamp
(`supporting-docs/METHODOLOGY.md` first 5 lines, per
`project-template/skills/pm-startup/SKILL.md:81`).

### 10.5 Who owns Graphify-pack health?

`pack-docs-researcher` for upstream drift detection;
`pack-architect` for schema-evolution decisions; `pack-reviewer` for
pre-commit verification of artifact gitignore. No new agent needed.

---

## 11. Anything I haven't asked

### 11.1 Does Graphify conflict with mcp-local-rag?

**No direct conflict.** They occupy different layers:

- `mcp-local-rag` indexes prose documents (`METHODOLOGY.md` and custom
  project docs) via embedding chunks. Returns relevance-ranked snippets.
  Strong for: "what does the methodology say about X".
- Graphify indexes code structure + provenance-tagged semantic content via
  AST parsing + LLM extraction. Returns subgraphs. Strong for: "where is
  X called", "what depends on Y", "what concepts cluster around Z".

They are **complementary**. Today's pack uses RAG only for the single
prose file `METHODOLOGY.md`; Graphify would extend coverage to **code +
mixed-format research**. The pack could ship both; the per-project
manifest disambiguates which retriever to consult.

### 11.2 Should Graphify replace mcp-local-rag?

**Not in v11.x.** Three reasons:

1. The hygiene contract (manifest reconciliation, orphan removal) is mature
   and codified across all three CLIs (validator Check 28 enforces parity).
   Tearing it out to replace with Graphify is a big-bang migration with
   broad surface.
2. `METHODOLOGY.md` is prose, not code. Graphify's strengths are code
   structure + cross-format research; for a single prose doc, RAG retrieval
   is the right tool.
3. The pack's "stay cross-CLI by default" stance
   (`OPTIONAL-FEATURES.md:14-15`) prefers additive optional features over
   forced replacements. Coexistence honors that stance.

**Longer-term consideration**: if Graphify proves robust over several
pack versions, a future BD could evaluate moving custom-project-document
ingestion to Graphify and leaving RAG to only handle METHODOLOGY (or even
retiring RAG entirely). Defer that decision until Graphify's schema and
hook stability are demonstrated.

### 11.3 How would auditor queries change shape?

Today the auditor and its 7 subagents do file-scope computation per
audit-methodology rules 25-32 (referenced at
`scripts/agent-run.sh:275-276` and `project-template/agent-run.sh:75-87`).
With a graph available, auditor subagents could:

- `auditor-architecture` — query "all cross-module imports of unstable
  symbols" via graph traversal instead of repo-wide grep.
- `auditor-security` — query "all call sites of sensitive APIs" via call
  graph instead of regex sweep.
- `auditor-tests` — query "code with INFERRED provenance only" (Graphify
  tag at article line 42) to find under-documented surface areas.

But: the auditor's *file scope* computation must stay deterministic
(audit-methodology rules 25-32). A graph **supplements** the audit — it
doesn't replace the file-scope contract. The auditor reads the graph,
identifies candidate files, *then* runs the deterministic per-file
audit. Same workflow shape, narrower file set.

### 11.4 Cost considerations

Graphify's Pass-3 (LLM extraction, article lines 28-32) costs tokens. The
article does not state the cost per build, but the pack has the same
build-cost concern that today's RAG ingestion has (
`supporting-docs/CLI-PM-SETUP.md:208-212` cites the embedding model
download). Per the pack's "higher-cost" optional-feature criterion
(`OPTIONAL-FEATURES.md:9-15`), Graphify should be flagged opt-in with
explicit cost language in `OPTIONAL-FEATURES.md` — token cost per
rebuild, embedding model size, disk footprint of `.pack-graph/`.

### 11.5 Privacy / data-out-of-repo considerations

Pass 1 (AST parsing) is local-only per article line 19. Pass 2
(transcription via faster-whisper) is local-only per article line 27.
Pass 3 (LLM extraction) sends content to whichever CLI's model. **For the
pack**: this means Graphify ingestion of `__external-docs/` material —
which may include scratch notes, dated transcripts, possibly proprietary
material — would go through the Claude/Codex/Gemini model. The pack's
existing data-out-of-repo posture (the `mcp-local-rag` server keeps
embeddings local, never round-tripping prose to a remote model) is
**stricter** than Graphify's. Document this in the "Caveats" subsection
of the `OPTIONAL-FEATURES.md` entry.

### 11.6 Test fixtures

The pack ships fixture trees at
`/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/test-fixtures/`:
`v10-minimal`, `v10-realistic-ot`, `v11-flat-file`, `v11-tracker-on`. A
Graphify integration would benefit from a `v11-graphify-on` fixture for
migration / rebuild / disable round-trip tests, paralleling the tracker
fixture set.

### 11.7 CI implications

`Validate Pack` runs on every push (per project `CLAUDE.md` instructions
to never disable). If Graphify becomes a hard CI dependency, CI build time
grows. **Recommendation**: keep Graphify's CI footprint **soft** —
validator can detect-only on the freshness sentinel; never *rebuild* the
graph in CI. Rebuilds are developer-local or pre-PR (per §8).

---

INTEGRATION-ANALYSIS-COMPLETE: 2026-05-11 — Graphify is a clean additive
optional feature: ship as an `OPTIONAL-FEATURES.md` entry mirroring the
tracker pattern, coexist with (not replace) `mcp-local-rag`, gate via
`scripts/pack-graphify.sh init/rebuild/status/disable`, detect-only on
`/pm-startup` and `/pack-startup`, and treat per-CLI hook registration
as a documented trinity exemption.
