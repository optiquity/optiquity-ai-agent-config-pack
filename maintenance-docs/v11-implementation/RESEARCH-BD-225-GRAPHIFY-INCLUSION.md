# RESEARCH-BD-225-GRAPHIFY-INCLUSION

Research-only report for BD-225 (wire Graphify PACK-SIDE into this repo so Pack
Chat + pack-* agents query a compact subgraph instead of re-reading the file
tree). **No design, no integration recommendation, no "we should."** Open items
are phrased as questions for the eventual architect. This is the pre-architect
research the user requested before deciding whether BD-225 is architect-ready.

- **Author role:** pack-docs-researcher (read-only).
- **Date:** 2026-06-18 · **HEAD SHA:** 47d8f600f376ce24e1c36a0e241f182529ad4fd6 · **branch:** v11-dev
- **Installed target verified:** `graphify 0.8.39` (`graphify --version`); skill `~/.claude/skills/graphify/.graphify_version` = `0.8.39`.
- **Headline counts:** Graphify capability/config/constraint items captured = 70 (§1–§3); pack file-categories that COULD-BE-INDEXED = 14; pack file-categories that COULD-BE-AFFECTED = 13 (§5). "Archive"-named exclusion dirs found = 2 (+1 ambiguous filename). Docs-vs-CLI mismatches flagged = 7 (§4). Sources inaccessible = 0 (every named source read; website fetched via curl).

---

## STEP 1 — Graphify: full capability / config / constraint surface (authoritative: graphify.net + actual CLI)

### 1.1 What Graphify is (source: graphify.net homepage; PLAN.md §"What it is")
- Open-source **knowledge-graph skill** for AI coding assistants. PyPI package **`graphifyy`** (double-y); CLI command is **`graphify`** (single-y). Repo `safishamsi/graphify`. MIT licensed. Maintainer Safi Shamsi.
- Turns a folder (code + docs/PDFs/images/video) into a **queryable knowledge graph**, then serves **compressed subgraphs** to the assistant instead of raw files. Claimed **~71.5x token reduction** per query (Karpathy mixed-corpus benchmark; homepage + PLAN.md).
- Site advertises `softwareVersion "0.3"` in JSON-LD and "Python 3.10+"; the **installed CLI is 0.8.39 on isolated Python 3.12** (PLAN.md pins 3.12 because Leiden community-detection needs < 3.13). The site version string is stale relative to the installed binary — see §4 mismatch (a).

### 1.2 Three-pass pipeline (source: PLAN.md §"What it is"; homepage "Architecture & Pipeline")
1. **Code -> tree-sitter AST** — deterministic, 100% local, **no LLM, never leaves the machine** (any config).
2. **Audio/video -> faster-whisper** — local; only with the `[video]` extra (NOT installed here).
3. **Docs/PDFs/images/comments -> LLM semantic extraction** — **the only model step**; non-code text is sent to the chosen backend (default = the Claude Code session subscription).
- Module pipeline (homepage): `detect -> extract -> build (NetworkX) -> cluster (Leiden) -> analyze (god nodes & surprises) -> report -> export`. Supporting modules: `ingest.py` (URL fetch), `cache.py` (semantic cache), `security.py` (input validation), `watch.py` (live updates), `serve.py` (MCP service).

### 1.3 The `/graphify` skill vs the `graphify` CLI split (source: REPO-QUICKSTART top; SKILL.md)
- **`/graphify ...` (slash)** = the SKILL, runs INSIDE a Claude Code session. **Only path that does the semantic/LLM pass** (build/update the doc layer), billed to the subscription.
- **`graphify ...` (bare)** = the CLI, a plain local binary. Querying (`query`/`path`/`explain`/`affected`) and the code-only `update` are **deterministic, no LLM, ~0 tokens**. Headless semantic work via the CLI needs an explicit `--backend`.
- This split is load-bearing for everything below: read/query = free CLI; build/refresh-of-doc-layer = subscription-billed skill.

### 1.4 Full CLI command surface (source: actual `graphify --help`, v0.8.39 — verbatim authoritative)
Build/extract/maintenance:
- `install [--platform P]` — copy skill to a platform config dir (claude|windows|codebuddy|codex|opencode|aider|amp|claw|droid|trae|trae-cn|gemini|cursor|antigravity|hermes|kiro|pi|devin).
- `uninstall` (`--purge` also deletes `graphify-out/`).
- `update <path>` — re-extract **code files** and update the graph (no LLM). `--force` (overwrite even if fewer nodes; also `GRAPHIFY_FORCE=1`), `--no-cluster`.
- `extract <path>` — **headless full extraction (AST + semantic LLM)** for CI/scripts. Flags: `--backend gemini|kimi|claude|openai|deepseek|ollama`, `--model M`, `--mode deep`, `--max-workers N`, `--token-budget N` (default 60000), `--max-concurrency N` (default 4; 1 for local LLMs), `--api-timeout S` (default 600), `--out DIR`, `--google-workspace`, `--no-cluster`, `--postgres DSN`, `--cargo`, `--global`, `--as <tag>`.
- `cluster-only <path>` — rerun clustering; `--no-viz`, `--graph`, `--no-label`, `--backend=`, `--model=`.
- `label <path>` — (re)name communities with LLM backend; `--backend=`, `--model=`.
- `watch <path>` — watch a folder, rebuild on **code** changes (no LLM).
- `add <url>` — fetch a URL into `./raw` and update graph; `--author`, `--contributor`, `--dir`.
- `clone <github-url>` — clone repo locally, print path; `--branch`, `--out`.
- `check-update <path>` — check `needs_update` flag, notify if semantic re-extraction pending (cron-safe).

Query (read-only, deterministic, ~0 tokens):
- `query "<question>"` — BFS traversal; `--dfs`, `--context C` (repeatable), `--budget N` (default 2000), `--graph <path>`.
- `path "A" "B"` — shortest path; `--graph`.
- `explain "X"` — node + neighbors summary; `--graph`.
- `affected "X"` — reverse traversal (impact/blast-radius); `--relation R` (repeatable), `--depth N` (default 2), `--graph`.
- `save-result` — save a Q&A into `graphify-out/memory/` (feedback loop); `--question`, `--answer`, `--type query|path_query|explain`, `--nodes ...`, `--memory-dir`.

Cross-repo / global graph:
- `global add <graph.json>` (`--as <tag>`), `global remove <tag>`, `global list`, `global path`.
- `merge-graphs <g1> <g2> ...` (`--out`), `merge-driver <base> <current> <other>` (git union-merge driver for `graph.json`).

Diagnostics / views / benchmark:
- `diagnose multigraph` — same-endpoint edge-collapse risk; `--json`, `--max-examples`, `--directed`/`--undirected`, `--extract-path`.
- `tree` — D3 collapsible-tree HTML; `--graph`, `--output`, `--root`, `--max-children`, `--top-k-edges`, `--label`.
- `benchmark [graph.json]` — token-reduction vs naive full-corpus.
- `export callflow-html` — Mermaid architecture/call-flow HTML. (Other exports — html/svg/graphml/neo4j/falkordb/wiki/obsidian — are documented via the skill `--<fmt>` flags + REPO-QUICKSTART table; see §1.8.)

Git hooks (code-only rebuild):
- `hook install` (post-commit + post-checkout), `hook uninstall`, `hook status`. Bypass: `GRAPHIFY_SKIP_HOOK=1 git commit`.

Per-platform always-on installers (each with matching `uninstall`):
- `claude install` (writes a `## graphify` section to **CLAUDE.md** + a **PreToolUse hook** in settings.json), `codex install` (AGENTS.md), `opencode install` (AGENTS.md + plugin), `gemini install` (GEMINI.md section + BeforeTool hook), `antigravity install` (`.agents/rules` + `.agents/workflows` + skill), `cursor install` (`.cursor/rules/graphify.mdc`), plus codebuddy/kilo/aider/copilot/vscode/claw/droid/trae/trae-cn/hermes/kiro/pi/devin.

### 1.5 Configuration files & directories (source: REPO-QUICKSTART §Reference; SKILL.md Step 1)
- **`.graphifyignore` / `.graphifyinclude`** at the **scan root** (or an ancestor) — gitignore-syntax exclude / re-include. NOT read from nested subdirectories.
- **`graphify-out/`** (per repo, intended **.gitignored**): `graph.json` (queryable graph), `GRAPH_REPORT.md` (human summary), `graph.html` (viz), `cache/` (`ast/`, `semantic/`), `memory/` (saved Q&As; always kept internally), `wiki/` (export), plus internal dotfiles written by the skill: `.graphify_python` (pins the interpreter), `.graphify_root` (scan root), `.graphify_version`, transient `.graphify_*.json` scratch files, `cost.json` (cumulative token tracker), `needs_update` flag.
- **`~/.graphify/`** (per machine): `global-graph.json` (cross-repo; `graphify global path`) and `repos/<owner>/<repo>/` (where `clone` checks out external repos).
- **Per-machine install artifacts** (from `graphify install`): `~/.claude/skills/graphify/` (SKILL.md ~32 KB + `references/`) and a 3-line `~/.claude/CLAUDE.md` trigger nudge; a dormant `graphify-mcp` binary (installed, NOT registered).

### 1.6 The ignore mechanism — exact semantics (source: REPO-QUICKSTART §"Excluding content"; "How .graphifyignore and .gitignore interact")
- Built-in always-pruned (independent of any ignore file): `graphify-out`, `node_modules`, `.git`, `.venv`, `build`, `dist`, `.next`, `target`, `.graphify` cache, caches. `graphify-out/memory/` is deliberately kept.
- **Strictly ONE file or the other, never merged:**
  - `.graphifyignore` **absent** -> graphify uses the repo's **`.gitignore`** as its skip list.
  - `.graphifyignore` **present** -> graphify uses **ONLY `.graphifyignore`** and does **NOT** read `.gitignore` at all for indexing.
- This affects **graphify only**; git is never affected either way. You need NOT re-list everything from `.gitignore` — copy only the gitignored entries you also want kept out of the graph.
- Honored by **every** entry point (`/graphify .`, `--update`, the hook's `graphify update`, manual runs, `watch`) — no flags needed.
- Per-invocation alternative: repeatable **`--exclude <pattern>`** (anchored at scan root, wins over ignore files) — but must be passed on EVERY run.
- `.graphifyinclude` re-includes hidden files/dirs that would otherwise be skipped; CANNOT override sensitive-file or dep-dir skips.

### 1.7 Graph-freshness model (source: REPO-QUICKSTART §"Keeping the graph fresh"; references/update.md; references/add-watch.md)
- **Two update commands, very different cost:**
  - `graphify update .` (CLI) — re-extracts **code only** (tree-sitter); **~0 tokens**; "every commit."
  - `/graphify . --update` (skill) — incremental **+ re-runs the semantic pass** on changed docs/PDFs/comments; **costs subscription tokens**; "only when the non-code layer changed."
  - NOT interchangeable — `update` never touches the doc/semantic layer.
- Building/updating is a **main-session** job (semantic pass uses the subscription); **agents only read**.
- Stated policy: update before every `git commit`; run free `update` every time, reach for `--update` only when docs/comments changed; "update even when CI is red."
- **Automation options (the doc says the main session should offer the user the choice; manual is the default):**
  - **A — manual/discretionary (default).**
  - **B — hand-written `pre-commit` git hook** running `graphify update .` (code-only; synchronous; per-clone; refreshes existing graph only).
  - **C — `graphify hook install`** (official post-commit + post-checkout; code-only; **backgrounded/non-blocking**; covers branch switches).
  - **`graphify watch .`** — long-running process; rebuilds code graph live as you edit; honors `.graphifyignore`; needs `[watch]` extra (installed).
  - **Semantic auto-refresh** — `graphify extract . --backend claude-cli` in a **post-commit (backgrounded, NOT pre-commit)** hook; serial; spends subscription usage per commit.
- `check-update` exists for cron-safe "is a semantic re-extraction pending?" notification.

### 1.8 Outputs / artifacts & exports (source: REPO-QUICKSTART §"Exports"; references/exports.md; SKILL.md)
- Default build writes `graph.json`, `GRAPH_REPORT.md`, `graph.html`, `cache/` into `graphify-out/`.
- Exports (each needs its flag/command; some need extras): `export html`, `tree` (GRAPH_TREE.html), `export callflow-html` (Mermaid), `export svg` (needs `svg`/matplotlib extra — installed), `export wiki` (`wiki/index.md` — agent-navigable; **the skill auto-uses `wiki/index.md` if present, navigating it instead of raw files**), `export obsidian`, `export graphml` (Gephi/yEd), `export neo4j --push` (needs extra; `NEO4J_PASSWORD`), `export falkordb --push` (needs extra; `FALKORDB_PASSWORD`).
- **MCP server:** `--mcp` / `python3 -m graphify.serve graphify-out/graph.json` starts a stdio MCP server exposing `query_graph`, `get_node`, `get_neighbors`, `get_community`, `god_nodes`, `graph_stats`, `shortest_path`. The installed `graphify-mcp` binary is **dormant** (PLAN.md decision: not registered).
- Real-output shape (read-only example `optiquity-site/graphify-out/GRAPH_REPORT.md`, 2026-06-17): 153 nodes / 185 edges / 20 communities over 2 files / ~68,426 words; sections: Corpus Check, Summary, Community Hubs, **God Nodes**, **Surprising Connections**, Import Cycles, **Hyperedges**, Communities (with cohesion scores), Knowledge Gaps (isolated nodes), Suggested Questions. Node labels for `path`/`explain`/`affected` come from the god-node list in `GRAPH_REPORT.md`.

### 1.9 Backends (source: PLAN.md §"Semantic pass"; REPO-QUICKSTART §Backends)
- Default here: **Claude Code session** — no API key, uses subscription (only the semantic pass; code never leaves machine).
- `claude-cli` — headless `claude -p`, still subscription/no-key; serial.
- API-key backends: `gemini` (`gemini-3-flash-preview`), `openai`, `deepseek`, `azure`, `bedrock`, `kimi` — billed.
- Local: `ollama` (`OLLAMA_MODEL`, `GRAPHIFY_ALLOW_LOCAL_PROVIDERS=1`).
- **Foot-gun (auto-route):** if `GEMINI_API_KEY` / `GOOGLE_API_KEY` / `OPENAI_API_KEY` is set in the shell, graphify **auto-routes the semantic pass to that paid API**. To keep the free Claude flow, those vars must be **unset**.

### 1.10 Limits, constraints, foot-guns (source: REPO-QUICKSTART; PLAN.md; SKILL.md; references/query.md)
- **Privacy:** code is parsed 100% locally and never leaves; the **semantic pass sends non-code text (docs/PDFs/comments) to the model**. In a **secrets-adjacent repo** the auto-mode classifier may refuse to run — "a correct safety stop; don't blindly override it." (PLAN.md intentionally SKIPS the dotfiles repo for this reason.)
- **Sensitive-file skips:** `detect` reports `skipped_sensitive`; `.graphifyinclude` cannot override sensitive-file skips.
- **Query matcher is literal:** case-folded substring + IDF — **no stemming, no synonyms, no cross-language match**. A vocab mismatch collapses the answer to noise; references/query.md mandates a constrained vocab-expansion step before traversal.
- **Per-clone / per-machine:** `graphify-out/`, git hooks, and `~/.graphify/global-graph.json` are NOT synced; each machine builds + maintains its own.
- **Big-repo handling:** `--no-viz` past ~5,000 nodes (`GRAPHIFY_VIZ_NODE_LIMIT`); HTML viz refuses > 5,000 nodes without a warning; corpus-size gate warns at > 2,000,000 words OR > 500 files and asks to narrow to a subfolder.
- **Node-ID / ghost-duplicate fragility:** the extraction ID format must match the AST extractor exactly or orphan ghost-duplicate nodes appear; a format change requires `extract --force`.
- **Skill is build-oriented + large (~32 KB):** REPO-QUICKSTART explicitly says do NOT preload the skill via an agent's `skills:` frontmatter for query-time use — it wastes context; reserve the skill for the main session that builds.
- **Subagents do NOT inherit skills / loaded graph / proactive triggering** (fresh context) — they must be given the CLI explicitly (the query commands are a plain CLI, no skill needed).
- **Subagent `--graph` MUST be an absolute path** (a subagent may start in a different cwd).
- **Honesty rules (SKILL.md):** never invent an edge (use AMBIGUOUS), never skip the corpus warning, always show token cost, never run HTML viz > 5,000 nodes without warning.

---

## STEP 2 — Local sources read + reconciliation against the actual CLI

All named local sources were read IN FULL: REPO-QUICKSTART.md (367 lines), PLAN.md (93 lines), `~/.claude/skills/graphify/SKILL.md` (~32 KB), all 8 files in `~/.claude/skills/graphify/references/` (add-watch, exports, extraction-spec, github-and-merge, hooks, query, transcribe, update), `~/.claude/skills/graphify/.graphify_version` (= `0.8.39`), and the example output `optiquity-site/graphify-out/GRAPH_REPORT.md`. **No source was inaccessible.**

### 2.1 What the UPDATED QuickStart adds vs the PLAN (notable changes observed)
The REPO-QUICKSTART (updated; "Updated 2026-06-17" in the related PLAN) is materially richer than PLAN.md and is now the operational source of truth for per-repo wiring. Notable content present in the QuickStart that the architect will lean on:
- A full **subagent-wiring section** ("Wiring graphify into your subagents") with the exact pattern: add `Bash` to graph-using agents; add ONE graph-first rule to `CLAUDE.md` (auto-loaded into custom subagents); optional role-specific phrasing (auditors -> `affected`, architects -> `path`/`explain`, coders -> `query`); explicit **"Do not edit your skill files"** and **"Do not preload the skill via `skills:` frontmatter."**
- The **`.graphifyignore` vs `.gitignore` one-file-or-the-other** rule, spelled out in full (this is the single most consequential config fact for a repo with an existing `.gitignore`).
- The **B vs C hook comparison table** and the **post-commit-only `claude-cli` semantic-refresh hook** (with the explicit "NOT pre-commit, it blocks every commit" warning).
- The "**update even when CI is red**" guidance and "`graphify-out/` stays gitignored — 'before commit' is timing discipline, not committing the graph."

### 2.2 Per-subcommand `--help` behavior — CONFIRMED (re-verified, read-only, in /tmp)
The prior-probing note is confirmed on 0.8.39:
- `graphify query --help` does **NOT** print help — it attempts to RUN and errors `graph file not found: /private/tmp/graphify-out/graph.json` (exit 0). Same for `graphify explain --help`.
- `graphify update --help` prints `Run 'graphify --help' for full usage.` (does not honor `--help` as a help flag either).
- **`graphify --help` (top-level) is the authoritative surface.** Per-subcommand `--help` is unusable for discovery on 0.8.39. (I did NOT build/index any graph in the pack repo; probes ran from `/tmp` and only produced "graph file not found" errors — no graph was created.)

---

## STEP 3 — (captured inline above)

Steps 1–2 above already constitute the complete external + local capability/config/constraint census. No additional Graphify facts are deferred. The website subpages read were: homepage (`https://graphify.net`), CLI reference (`/graphify-cli-commands.html`), and Claude Code integration (`/graphify-claude-code-integration.html`) — all fetched successfully via `curl -sL`.

---

## STEP 4 — Docs-vs-actual-CLI mismatches (every mismatch flagged; v0.8.39 is the usable target)

| # | Claim / source | Actual on CLI 0.8.39 | Impact |
|---|---|---|---|
| (a) | graphify.net JSON-LD says `softwareVersion "0.3"` and "Python 3.10+" | Installed binary is **0.8.39** on **Python 3.12** (PLAN pins 3.12; Leiden needs <3.13) | Website version metadata is stale; rely on the CLI, not the site, for version-specific behavior. |
| (b) | REPO-QUICKSTART / PLAN usage lists show export as **flags** on the skill (`/graphify <path> --svg`, `--wiki`, `--neo4j`, `--graphml`, `--mcp`, `--obsidian`, `--watch`, `--directed`, `--html`, `--whisper-model`, `--cluster-only`) | The bare CLI `graphify --help` exposes exports as **`export <fmt>` subcommands** (`export callflow-html`, `export svg/wiki/...` via references) and dedicated subcommands (`watch`, `cluster-only`, `tree`); the `--svg`/`--wiki`/etc. forms are **skill-only flags**, not bare-CLI flags | The architect must distinguish skill-invocation flags from CLI subcommands; a flag that works under `/graphify` may not be a bare-`graphify` flag. |
| (c) | Per-subcommand `--help` (implied usable by docs) | **NOT honored** — `query`/`explain` `--help` attempt to run; `update --help` redirects to top-level | Discovery must use `graphify --help` only. |
| (d) | references/exports.md MCP step: `python3 -m graphify.serve ...` and the dormant `graphify-mcp` binary | `--mcp` is a **skill flag**; there is no top-level `mcp` subcommand in `graphify --help`; the MCP path is `graphify.serve` (module) or the dormant binary | MCP integration is not a first-class CLI verb on 0.8.39; it is module/skill/binary-mediated. |
| (e) | SKILL.md Step 3 tip: "set `GEMINI_API_KEY`/`GOOGLE_API_KEY` to use Gemini... `pip install 'graphifyy[gemini]'`" and "No other API keys are read" | `extract --backend` accepts `gemini|kimi|claude|openai|deepseek|ollama`; the auto-route foot-gun is real | The "no other keys read" statement is about the *skill's* Claude-subagent path; the headless `extract` CLI DOES read provider keys. Two different code paths — do not conflate. |
| (f) | PLAN.md says extras installed = `[pdf,svg,watch]`; `[video]`, `[neo4j]`, `[falkordb]` NOT installed | CLI exposes `export neo4j`/`export falkordb`/video transcription regardless | Those exports/features will `ModuleNotFoundError` until their extra is installed — **doc'd-but-not-usable here** without an install change. |
| (g) | REPO-QUICKSTART step 1: `uv tool list | grep graphifyy` / `graphify install` already done by chezmoi | Verified present: `graphify 0.8.39`, skill at `~/.claude/skills/graphify/` with `.graphify_version` = 0.8.39 | Install state matches docs; no action implied by this report. |

No claimed feature was found *absent* from the binary (all `--help` verbs exist); the mismatches are about **invocation surface (skill flag vs CLI subcommand vs module)**, **version metadata**, **per-subcommand help**, and **uninstalled extras**.

---

## STEP 5 — Inclusive survey: pack files/dirs that COULD be INDEXED or AFFECTED

Boundary note (BD-225 / P-missed-7): the graph MAY index the whole repo (incl.
`project-template/`) for agent context, but **every setup artifact lives
pack-side** and the graph-first rule goes in the **pack-root trinity, never
`project-template/`**. Below, "could-be-indexed" = could be a node source;
"could-be-affected" = could be touched/changed by adding Graphify pack-side.
**Inclusive by design ("could," not "will").**

### 5.1 Repo inventory (counts, for reconciliation; measured at HEAD 47d8f60, 2026-06-18)
- Total git-tracked files: **1645**.
- `backlog/` per-entry md entries: **233** (+ `_toc.md`, `_rules.md`, templates).
- `changelog/` tree files: **14**.
- `maintenance-docs/` files: **840 total**, of which **272 are inside the two "archive"-named dirs** (`maintenance-docs/archive/` = bulk; `maintenance-docs/v11-research/templates-archive/`).
- `scripts/`: 24 top-level files; **302 total** incl. `lib/`, `tests/`, fixtures (excl. `__pycache__`).
- Agent definitions: **15** (`.claude/agents/` 5, `.codex/agents/` 5, `.agents-plugin/pack-agents/agents/` 5).
- Skills (`SKILL.md` across `.claude/skills`, `.codex/skills`, `.agents/skills`): **33**.
- `supporting-docs/`: 9 files. `pack-ops/`: 10 files.
- `project-template/`: a full nested tree (CLAUDE/AGENTS/GEMINI.md, docs, proto, scripts, server, skills, fixtures) — indexable but pack-ops-boundary-relevant.

### 5.2 COULD-BE-INDEXED (could be a node source in the graph) — 14 categories

| # | Path / category | One-line WHY | Category |
|---|---|---|---|
| I-1 | `README.md` | Authoritative repo layout + version table; high-degree "god node" candidate. | could-be-indexed |
| I-2 | Pack-root trinity `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` | The pack's operating rules + Pack-memory; dense semantic content agents query most. | could-be-indexed |
| I-3 | `pack-ops/*` (PACK-CHAT, PACK-AGENTS, OPTIONAL-FEATURES, BOUNDARY-DEFINITION, MERGE-STRATEGY, etc.) | Core ops/routing docs; exactly the "re-read for context" surface BD-225 targets. | could-be-indexed |
| I-4 | `backlog/` tree (233 entries + `_toc.md`) | The BD SSOT; cross-entry dependency relationships are graph-shaped. | could-be-indexed |
| I-5 | `changelog/` tree | Version history per-entry; ties BDs to releases. | could-be-indexed |
| I-6 | `supporting-docs/*` (DEPENDENCIES, METHODOLOGY, CLI-PM-SETUP, INSTALL-PROCEDURES, MIGRATION-v10-to-v11, SETUP-*) | Reference docs frequently consulted by agents. | could-be-indexed |
| I-7 | `maintenance-docs/` NON-archive (v11-implementation, v11-research, guides, origins, top-level *.md) ~568 files | Architecture/plan/review history; rich rationale nodes. | could-be-indexed |
| I-8 | `scripts/*.py` + `*.sh` (validate-pack.py, init-project.sh, lib/, migrators, mergers, tests) | Code -> tree-sitter AST nodes/call graph (deterministic, free). | could-be-indexed |
| I-9 | Pack agent definitions (`.claude/.codex/.agents-plugin` agents) | Agent roles/contracts; relationships to skills + ops docs. | could-be-indexed |
| I-10 | Skills (`.claude/.codex/.agents/skills/*/SKILL.md`, 33) | Skill contracts agents load; semantic nodes. | could-be-indexed |
| I-11 | `project-template/` whole tree (CLAUDE/AGENTS/GEMINI, docs, proto, server, scripts, skills) | Deliverables the pack-* agents MAINTAIN; BD-225 says indexing them gives agents context — but they are NOT where pack-ops setup lives (boundary). | could-be-indexed (boundary-noted) |
| I-12 | `.github/workflows/validate-pack.yml` + ISSUE_TEMPLATE/* | CI + intake config; relates to validate-pack.py checks. | could-be-indexed |
| I-13 | Root config/docs: `QUICKSTART.md`, `LICENSE.md`, `tracker.toml.pack-example`, `tracker.toml.project-example` | Repo-level context nodes. | could-be-indexed |
| I-14 | `test-fixtures/` + `scripts/tests/fixtures/` | Code/data fixtures; MAY pull in synthetic `.env`/`.mcp.json.example` secrets-adjacent files (see foot-gun, §5.4). | could-be-indexed (secrets-adjacent flag) |

### 5.3 COULD-BE-AFFECTED (could be touched/changed by adding Graphify pack-side) — 13 categories

| # | Path / category | One-line WHY | Category |
|---|---|---|---|
| A-1 | `.gitignore` | `graphify-out/` (build artifact) would need a gitignore entry; ALSO the `.graphifyignore`-disables-`.gitignore`-fallback interaction makes this file decisive. | output-git-hygiene / ignore-implication |
| A-2 | A new repo-root `.graphifyignore` (and optionally `.graphifyinclude`) | The "archive"-exclusion hard rule + one-file-or-the-other semantics force an explicit decision here. | ignore-implication |
| A-3 | Pack-root trinity `CLAUDE.md` (+ AGENTS.md/GEMINI.md per trinity rule) | The graph-first rule's home per BD-225 (pack-root, NOT project-template); `graphify claude install` would also target CLAUDE.md + a PreToolUse hook. | agent-read-pattern / rule-home |
| A-4 | Pack agent definitions (`.claude/.codex/.agents-plugin` agents, 15) | Graph-using agents need the `Bash` tool + possibly role-specific graph-first phrasing; read-only auditors/reviewers are the offenders. | agent-read-pattern |
| A-5 | `.claude/settings.json` / `settings.local.json` (+ MCP config `.mcp.json`) | `graphify claude install` writes a PreToolUse hook into settings.json; the optional MCP path would touch MCP config. | agent-read-pattern / setup |
| A-6 | `pack-ops/PACK-CHAT.md` | Pack Chat operating rules — where "build/refresh the graph; offer the user automation choice" guidance would live (main-session-only build). | could-be-affected-setup |
| A-7 | `pack-ops/PACK-AGENTS.md` | Agent routing/permission table — graph-read permissions + which agents are graph-aware. | could-be-affected-setup |
| A-8 | `pack-ops/OPTIONAL-FEATURES.md` | Existing home for optional-feature + privacy-delta notes (Pass-3 privacy already referenced there in research). | could-be-affected-setup |
| A-9 | Git hooks (`.git/hooks/` per-clone; or tracked `.githooks/` + `core.hooksPath`) | Freshness automation B/C / `graphify hook install` / post-commit semantic refresh — all hook-based, per-clone. | freshness-automation |
| A-10 | `scripts/validate-pack.py` + `.github/workflows/validate-pack.yml` | A CI guard could verify `graphify-out/` is never committed, or that the `.graphifyignore` covers "archive" dirs; CI-runtime-cost rule applies. | CI-guard |
| A-11 | `scripts/manifest-sync.sh` + `test-fixtures/manifest.txt` (Check 62) | If any graphify artifact becomes a tracked fixture input, manifest hygiene is implicated (likely N/A since output is gitignored — open question). | output-git-hygiene |
| A-12 | `supporting-docs/DEPENDENCIES.md` | If Graphify becomes a pack-dev dependency, the dependency register would record it (pack-ops tooling vs client deliverable distinction). | could-be-affected-setup |
| A-13 | Prior graphify research docs in `maintenance-docs/v11-research/` (RESEARCH-GRAPHIFY-SYNTHESIS / -EXTERNAL / -PACK-INTEGRATION; refs in RESEARCH-CLAUDE-REPOS-SURVEY, TOUCH-POINT-INVENTORY-GROUPINGS-V2, V11.1-DISCUSSION-GITHUB-PROJECTS) | These (dated 2026-05-11) frame Graphify as a CLIENT feature DEFERRED to v12 against an older version — BD-225 supersedes that posture (pack-side, v11.0); they may need a superseding note. | could-be-affected-setup (stale-context) |

### 5.4 The "archive"-named exclusion dirs (user HARD rule: every dir whose name contains "archive" is excluded from the graph)
Measured at HEAD 47d8f60 (`find . -type d -iname '*archive*' -not -path './.git/*'`):
- **`maintenance-docs/archive/`** — EXCLUDE (272 files combined with the next).
- **`maintenance-docs/v11-research/templates-archive/`** — EXCLUDE.
- **No other "archive"-named directories exist** at HEAD.
- **OPEN QUESTION for the architect (ambiguity, not a decision):** one FILE — `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-BATCH-ARCHIVE.md` — has "ARCHIVE" in its *filename* but is NOT in an archive *directory*. The user's rule is scoped to *directories*; should the exclusion also cover archive-named *files*, or only directories? (Surfaced, not resolved.)

### 5.5 Count reconciliation (nothing silently dropped)
- 1645 tracked files = (233 backlog + 14 changelog + 840 maintenance-docs [272 archive-excluded + 568 indexable] + 302 scripts + 15 agent defs + 33 skills + 9 supporting-docs + 10 pack-ops + project-template tree + root files + .github + test-fixtures + companion-templates). Every top-level surface from the env listing (`.agents`, `.agents-plugin`, `.claude`, `.codex`, `.github`, `backlog`, `changelog`, `maintenance-docs`, `pack-ops`, `project-template`, `scripts`, `supporting-docs`, `test-fixtures`, `vscode-companion-templates`, `xcode-companion-templates`, root md/toml files) is represented in §5.2/§5.3 or explicitly excluded in §5.4. `vscode-companion-templates/` and `xcode-companion-templates/` are indexable-low-value (companion deliverables) and fold under I-11-adjacent could-be-indexed; flagged here so they are not "silently dropped."

---

## OPEN QUESTIONS for the eventual architect (phrased as questions; NOT decisions)

1. Should the graph index the **whole repo** (incl. `project-template/`) or be scoped (e.g. pack-ops + docs only)? BD-225 permits whole-repo; scope is undecided.
2. `.graphifyignore` present **disables the `.gitignore` fallback entirely** — if a `.graphifyignore` is added (needed for the "archive" exclusions), which currently-`.gitignore`d paths (e.g. synthetic-fixture `.env` files, `.mcp.json`, `generated/`) must be re-listed to keep them out of the graph?
3. Where exactly does the graph-first rule live — hand-authored in the pack-root trinity, or via `graphify claude install` (which also writes a PreToolUse hook into `settings.json`)? Are the two compatible / is the hook wanted pack-side?
4. Which pack agents become graph-aware (need `Bash` added) and which stay tree-reading? (Read-only reviewers/auditors are the QuickStart's flagged offenders.)
5. Freshness policy: manual (A) vs `pre-commit` (B) vs `graphify hook install` (C) vs `watch` vs post-commit `claude-cli` semantic refresh — and given `agents-never-commit` + the worktree-isolation model (BD-226/197), who runs the build/refresh and when?
6. Is the dormant MCP path (`graphify-mcp` / `graphify.serve`) in scope, or is the plain query-CLI sufficient?
7. Secrets-adjacency: the pack contains synthetic `.env` / `.mcp.json.example` fixtures and a tracker-secrets posture — does the semantic pass's "send non-code text to the model" property + the auto-mode classifier refusal need an explicit privacy-delta call-out (parallel to OPTIONAL-FEATURES' existing notes)?
8. Should a CI guard (validate-pack / workflow) enforce "`graphify-out/` never committed" and/or "`.graphifyignore` covers all archive dirs," subject to the CI-runtime-compounding rule?
9. Does the "archive" exclusion rule extend to archive-named **files** (§5.4) or directories only?
10. Do the 2026-05-11 prior graphify research docs (client-feature/v12-deferred framing) need a superseding note now that BD-225 reframes Graphify as pack-side v11.0?
11. Extras: `neo4j`/`falkordb`/`video` exports are doc'd but their extras are NOT installed — are any of those export paths in scope (they'd require an install change)?

---

## Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|---|
| 1 | agents-never-commit | Ran only read-only git: `git rev-parse HEAD` -> `47d8f600f376ce24e1c36a0e241f182529ad4fd6`; `git ls-files | wc -l` -> `1645`. No add/commit/push/checkout/etc. issued. Sole write = this report via heredoc to the caller-specified path. | COMPLIANT |
| 2 | per-action-approval-sub-agents | No destructive op run. CLI probes ran from `/tmp` and produced `error: graph file not found: /private/tmp/graphify-out/graph.json` — NO graph built/indexed in the pack repo; NO `.graphify*` config written into the pack repo. | COMPLIANT |
| 3 | agents-read-rule-docs-in-full | Read in full: `CLAUDE.md` (1–603 incl. ## Pack memory), `backlog/BD-225.md` (1–17), `REPO-QUICKSTART.md` (1–367), `PLAN.md` (1–93), `SKILL.md` (~32 KB), all 8 `references/*.md`, `.graphify_version` (=`0.8.39`), `optiquity-site/.../GRAPH_REPORT.md`. | COMPLIANT |
| 4 | researcher-maps-blast-radius-before-architect | §5: 14 could-be-indexed + 13 could-be-affected categories, each with a one-line WHY + category; §5.5 reconciles to 1645 tracked files; §5.4 captures both archive dirs + 1 ambiguous filename. | COMPLIANT |
| 5 | external-rules-census-before-design | §1 captures 70 capability/config/constraint items from authoritative sources (graphify.net homepage + CLI-reference + Claude-integration pages; `graphify --help` 0.8.39; QuickStart/PLAN/SKILL/references), each source-cited; no design proposed. | COMPLIANT |
| 6 | verify-availability-not-just-existence | Ran `graphify --version` -> `graphify 0.8.39`; `graphify --help` (full surface captured); per-subcommand `--help` re-verified (`query --help` errors `graph file not found`, `update --help` -> "Run 'graphify --help'"). §4 flags 7 docs-vs-CLI mismatches incl. uninstalled `neo4j/falkordb/video` extras. | COMPLIANT |
| 7 | scope-deliverables-to-the-ask | Report = exactly the three research steps + flagged mismatches + inclusive enumeration + open questions; no integration proposal, no "we should." Closing items are questions. | COMPLIANT |
| 8 | agent-output-rules-applied-block | This block exists with one row per in-force rule, each with quoted evidence + a terminal conclusion (no AMBIGUOUS). | COMPLIANT |
| 9 | bd-pack-only-operational-rule / pack-project-separation-of-concerns | §5 header + I-11 + A-3 keep the boundary explicit: `project-template/` MAY be indexed for context but is NOT where pack-ops setup or the graph-first rule lives (pack-root trinity only). | COMPLIANT |
| 10 | filename-uniqueness-heuristic | `find . -name "RESEARCH-BD-225-GRAPHIFY-INCLUSION.md" -not -path "./.git/*"` -> empty (no collision) before writing. | COMPLIANT |
