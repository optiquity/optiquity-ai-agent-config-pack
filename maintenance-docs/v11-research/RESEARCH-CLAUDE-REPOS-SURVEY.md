# RESEARCH-CLAUDE-REPOS-SURVEY

**Date:** 2026-05-11
**Scope:** Evaluate 20 Claude Code-ecosystem repositories from the Medium-style "20 repos I actually use" list against the AI Agent Config Pack (v11+). For each repo, rate utility for (A) pack development workflows and (B) client-project workflows (the codebases the pack is installed into), surface integration shape, and flag conflicts with existing v11 surfaces (mcp-local-rag, pack-tracker, the 16-agent project roster, the 5-agent pack roster, the trinity files CLAUDE.md / AGENTS.md / GEMINI.md, OPTIONAL-FEATURES.md opt-in pattern).

**Source list:** `/Users/david/Developer/__external-docs/optiquity-ai-agent-config-pack/Claude Repos to Investigate.txt` (items 1-20; "Bonus: AnotherWrapper" skipped as a marketing item).

**Methodology:** Each repo was verified via WebSearch against its GitHub README and ecosystem coverage. Star counts cited from the Medium article are not re-verified — the article's claims are explicitly treated as the author's assertion, not pack-verified fact. Two ratings per repo: **pack rating** (utility for the pack maintainer building/evolving the pack) and **client rating** (utility for projects that install the pack). 0 = no-op, 5 = transformative.

**Verdict scale:**
- `no-op` — neither side benefits enough to justify integration
- `useful (pack)` — clear pack-dev win, marginal/none for clients
- `useful (client)` — clear client-side win, marginal/none for pack-dev
- `useful (both)` — clear win on both sides

**Already-in-use baseline:** items 1 (claude-code), 12 (github-mcp-server), 13 (playwright-mcp), 15 (context7) are confirmed already integrated in this pack's tooling. Their ratings reflect *extended* use beyond current configuration.

---

## Executive ranking

Sorted by `max(pack-rating, client-rating)` descending. Ties broken by total pack+client rating, then by item number.

| Rank | # | Repo | Verdict | Pack | Client | Already in use? | One-line justification |
|------|---|------|---------|------|--------|-----------------|------------------------|
| 1 | 1 | anthropics/claude-code | useful (both) | 5 | 5 | yes (CLI itself) | The pack runs on top of this; staying current on CLI features (plugins, hooks, agent teams) is mandatory. |
| 2 | 5 | hesreallyhim/awesome-claude-code | useful (both) | 4 | 3 | no | Master discovery index for the entire ecosystem — pack maintainer's standing horizon-scan tool. |
| 3 | 3 | anthropics/anthropic-cookbook (now claude-cookbooks) | useful (both) | 4 | 4 | no | Canonical tool-use / RAG / agent patterns — reference material for prompt-authoring and architect decisions. |
| 4 | 8 | obra/superpowers | useful (client) | 2 | 4 | no | Competing full methodology (brainstorm/spec/plan/TDD/subagent); cherry-pick TDD + subagent-driven patterns but do not adopt wholesale — overlaps pack workflows. |
| 5 | 20 | nizos/tdd-guard | useful (client) | 1 | 4 | no | Hook-enforced TDD gate; natural fit as an opt-in feature for the tester/coder loop in client projects with mature test suites. |
| 6 | 16 | zilliztech/claude-context | useful (client) | 2 | 4 | no | Semantic code search MCP for large monorepos; complementary to mcp-local-rag (docs) and Graphify (structural). Strong fit for big client codebases. |
| 7 | 2 | anthropics/skills | useful (client) | 2 | 4 | no | Official PDF/DOCX/XLSX/PPTX skills — drop-in optional skills for client projects that produce reports or office artifacts. |
| 8 | 4 | anthropics/claude-code-action | useful (client) | 3 | 4 | no | GitHub Action for @claude PR review; natural fit as an opt-in CI surface for client repos with PR workflows. |
| 9 | 14 | crystaldba/postgres-mcp | useful (client) | 1 | 4 | no | Safe Postgres access via MCP; transformative for any client project with a Postgres backend (read-only mode aligns with pack's safety bias). |
| 10 | 12 | github/github-mcp-server | useful (both) | 4 | 4 | yes (in active use) | Already integrated; extended use covers tracker-mode automation, issue triage, CI bridging. |
| 11 | 15 | upstash/context7 | useful (both) | 4 | 4 | yes (in active use) | Already integrated; extended use covers more libraries (Swift/gRPC stacks especially). Pack-docs-researcher already loads it. |
| 12 | 6 | ComposioHQ/awesome-claude-skills | useful (client) | 2 | 3 | no | Curated skill catalog with production tags; useful for pulling specific skills (postgres, deep-research, root-cause) into client projects. Discovery, not infrastructure. |
| 13 | 9 | travisvn/awesome-claude-skills | useful (client) | 2 | 3 | no | Second curated skill catalog; community-curated with anti-marketing filter. Use alongside #5 and #6 for horizon-scan. |
| 14 | 11 | baryhuang/claude-code-by-agents | no-op | 1 | 1 | no | Desktop GUI + remote-agent orchestration via @mentions; orthogonal to pack's CLI-first model. The "59 agents" claim doesn't match the actual repo (which is the orchestration shell, not an agent library). |
| 15 | 7 | ComposioHQ/awesome-claude-plugins | useful (client) | 1 | 3 | no | Frontend/design/artifacts plugins; only matters if a client project has a frontend/UI surface. Not in scope for current Optiquity/Swift focus. |
| 16 | 10 | wshobson/agents | useful (client) | 2 | 3 | no | Large subagent library (83 agents). Competes with pack's 16-agent roster — borrow patterns from individual agents, don't adopt wholesale. |
| 17 | 13 | microsoft/playwright-mcp | useful (client) | 2 | 3 | yes (in active use) | Already integrated; extended use only matters for client projects with browser-automation/web-scraping needs. |
| 18 | 17 | ruvnet/claude-flow (Ruflo) | no-op | 1 | 2 | no | Competing orchestration platform (queens, swarms, hive-mind, 87 MCP tools, daemon). Architecturally inconsistent with pack's deterministic PM-Chat-coordinated model. |
| 19 | 18 | smtg-ai/claude-squad | no-op | 2 | 2 | no | tmux + git-worktrees TUI for parallel agents; useful as a personal dev tool but redundant against Claude Code's Agent Teams and the pack's own opt-in worktree isolation (BD-197), both documented in OPTIONAL-FEATURES.md. |
| 20 | 19 | thedotmack/claude-mem | no-op | 1 | 2 | no | Tool-output compression + ChromaDB memory; pack already has mcp-local-rag + git as memory. Adding another memory layer worsens audit trail without clear win. |

---

## Per-repo evaluations

### 1. anthropics/claude-code

| Field | Content |
|---|---|
| Repo | `anthropics/claude-code` — https://github.com/anthropics/claude-code |
| What it is | Anthropic's official Claude Code CLI. Agentic terminal coding tool with native plugin system, hooks, subagents, and Agent Teams (experimental). |
| Verdict | useful (both) |
| Pack rating | 5 |
| Client rating | 5 |
| Already in use? | yes — the CLI the pack is built around |
| Integration shape | The pack ships agent definitions, skills, hooks, and settings designed for this CLI. Extended use: track CHANGELOG for new flags, plugin-system surface, hook taxonomy, and Agent Teams maturation; reflect new features in OPTIONAL-FEATURES.md and TOOL-COMPARISON.md. Action item: README mentions Anthropic moved away from npm to native installers (Homebrew / WinGet) — pack's QUICKSTART + DEPENDENCIES.md should be re-verified against the current install method. |
| Risks / friction | Fast-moving target. The CHANGELOG ships breaking changes between minor versions. Pack must own a "validated against Claude Code vX.Y" marker in DEPENDENCIES.md (already partially done). |
| Verdict justification | The pack is a layer on top of this CLI; staying current on its features is non-negotiable. The plugin/marketplace direction in particular needs deliberate pack response (do we publish pack agents as a plugin, or stay as a template that gets copied into projects?). |

### 2. anthropics/skills

| Field | Content |
|---|---|
| Repo | `anthropics/skills` — https://github.com/anthropics/skills |
| What it is | Anthropic's official skills library. Includes production skills for `pdf`, `docx`, `xlsx`, `pptx`, plus a `skill-creator` meta-skill. Source-available, not OSI-OSS. |
| Verdict | useful (client) |
| Pack rating | 2 |
| Client rating | 4 |
| Already in use? | no |
| Integration shape | Add an OPTIONAL-FEATURES.md entry "Office document skills" pointing at this repo. For client projects that need to *produce* Word/Excel/PowerPoint/PDF artifacts (reports, vendor exports, customer-facing docs), copy the relevant skill into `project-template/.claude/skills/` (and trinity peers) under a clear "optional, only if your project produces office docs" gate. Add a `Skills:` block in `PLATFORM-SKILLS.md` mapping `office-export` capability → these skills. No new agent. The `skill-creator` skill is interesting for the pack's own skill-authoring discipline — the pack-docs-researcher could load it when drafting new skills. |
| Risks / friction | Source-available license is not OSI; pack's LICENSE.md is also source-available so the licenses are compatible in spirit, but bundling Anthropic's skill source into the pack would create a license surface the maintainer should audit. Safer: link to it as a downloadable upstream, do not vendor. |
| Verdict justification | Genuinely useful for any client project that crosses the "produces office artifacts" threshold. Pack-side, the only win is the `skill-creator` meta-skill for the pack's own skill discipline. The PDF/XLSX/DOCX skills don't help the pack maintainer because the pack doesn't produce office docs. |

### 3. anthropics/anthropic-cookbook (now `claude-cookbooks`)

| Field | Content |
|---|---|
| Repo | `anthropics/claude-cookbooks` (renamed from `anthropic-cookbook`) — https://github.com/anthropics/claude-cookbooks |
| What it is | Anthropic's official notebook recipes: tool use, RAG patterns, agent patterns, prompt caching, extended thinking, multimodal, classification. |
| Verdict | useful (both) |
| Pack rating | 4 |
| Client rating | 4 |
| Already in use? | no (referenced informally; not pinned) |
| Integration shape | Reference, not vendored. Add a row to `maintenance-docs/VERIFIED-NOTES.md` (or a new `REFERENCE-MATERIAL.md`) listing it as the canonical source for agent patterns. The `patterns/agents/` directory in particular is the closest external analog to what the pack codifies in `METHODOLOGY.md` — pack-architect should read it when proposing pattern changes. For client projects, the `tool_use/` and RAG recipes are direct copy material when a project crosses into "needs production-shaped tool-use loops." `pack-docs-researcher` should know about it as a citable source. |
| Risks / friction | Notebook format (Jupyter) is awkward in a Markdown-only pack workflow. The pack doesn't ingest notebooks today; reference only. Repo renamed in 2026 — old `anthropic-cookbook` URL still redirects but the article uses the old name; pack docs should use the new name. |
| Verdict justification | Canonical reference material. Doesn't change the pack's surface but informs every architect/methodology decision. Citing it improves trust in the pack's pattern claims. |

### 4. anthropics/claude-code-action

| Field | Content |
|---|---|
| Repo | `anthropics/claude-code-action` — https://github.com/anthropics/claude-code-action |
| What it is | Official GitHub Action that runs Claude Code against PRs and issues. Supports `@claude` mentions in comments, automatic PR review, custom checklists, issue triage. |
| Verdict | useful (client) |
| Pack rating | 3 |
| Client rating | 4 |
| Already in use? | no |
| Integration shape | Natural fit for an opt-in OPTIONAL-FEATURES.md entry: "CI-based PR review with Claude Code Action." Ship a `project-template/.github/workflows/claude-pr-review.yml.example` (not active by default) that wires the action to the pack's `reviewer` and `auditor-security` agent definitions via the action's prompt input. For the pack repo itself, this could replace or augment the existing `Validate Pack` GitHub Action — pack-reviewer running as a comment-bot on PRs to the pack would catch trinity-symmetry violations before merge. Pairs with the v11 tracker mode (the action can read GH-issue state). |
| Risks / friction | Costs API tokens per PR — needs ANTHROPIC_API_KEY secret with budget guardrails. Pack's "deterministic, auditable" property weakens slightly when CI introduces non-deterministic reviewer behavior. License/IP: the action sends repo code to Anthropic — for IP-sensitive client projects this needs an explicit privacy-delta call-out in OPTIONAL-FEATURES.md (parallel to the Graphify Pass-3 privacy note). |
| Verdict justification | High-value for clients with active PR workflows; medium for the pack itself because the pack's CI is mostly structural validation that doesn't benefit from Claude review. Worth a v12 BD cluster as an opt-in feature. |

### 5. hesreallyhim/awesome-claude-code

| Field | Content |
|---|---|
| Repo | `hesreallyhim/awesome-claude-code` — https://github.com/hesreallyhim/awesome-claude-code |
| What it is | The master "awesome" index for the Claude Code ecosystem. Categorized: skills, hooks, slash-commands, agents, orchestrators, applications, plugins. PRs accepted only from Claude itself. |
| Verdict | useful (both) |
| Pack rating | 4 |
| Client rating | 3 |
| Already in use? | no (informally browsed) |
| Integration shape | Treat as the pack-maintainer's standing horizon-scan reference. Add a row to `maintenance-docs/RECOMMENDATIONS.md` pointing here for new-feature surveying. Establish a quarterly cadence: pack-architect scans this index for new categories (hooks, status-lines, output-styles) and reports back. No code/skill changes from the pack — discovery only. For clients, the README is a useful "what could I add to my project?" menu; cite it in `OPTIONAL-FEATURES.md` as an upstream menu. |
| Risks / friction | Quality variance — being in the index does not mean production-ready. Pack must vet anything before adopting. Index can lag (typical "awesome" repo problem). |
| Verdict justification | Discovery infrastructure. Doesn't change pack surface but materially improves the maintainer's ability to keep the pack current. The "only Claude submits PRs" curation gimmick is mildly amusing but does not improve quality assurances. |

### 6. ComposioHQ/awesome-claude-skills

| Field | Content |
|---|---|
| Repo | `ComposioHQ/awesome-claude-skills` — https://github.com/ComposioHQ/awesome-claude-skills |
| What it is | Composio's curated skill catalog with production-tested tags. Notable skills include `postgres` (safe read-only SQL), `deep-research` (Gemini Deep Research Agent integration), `root-cause-tracing`. |
| Verdict | useful (client) |
| Pack rating | 2 |
| Client rating | 3 |
| Already in use? | no |
| Integration shape | Cherry-pick. `root-cause-tracing` is the most pack-aligned: parallels the pack's `auditor` clusters; could be added as an optional skill in `project-template/skills/root-cause-tracing/SKILL.md` and exposed to the `auditor-code` / `reviewer` agents via `PLATFORM-SKILLS.md` capability mapping. `postgres` overlaps with item 14 (crystaldba/postgres-mcp) — prefer the MCP server over a skill for Postgres access; the skill could wrap MCP queries. `deep-research` is interesting but Gemini-bound; would need pack-side abstraction to make it cross-CLI. Use the catalog primarily as a discovery feed, not as a dependency. |
| Risks / friction | Vendor-shaped (Composio is the maintainer; their broader product is a 500+ tool connector). Anti-pattern risk: pulling skills that quietly require Composio's commercial backend. Vet each skill for "does it need an external service?" before adoption. |
| Verdict justification | A useful menu, but each skill must be evaluated individually. The catalog itself doesn't change the pack — it's a source of optional capabilities client projects can opt into. |

### 7. ComposioHQ/awesome-claude-plugins

| Field | Content |
|---|---|
| Repo | `ComposioHQ/awesome-claude-plugins` — https://github.com/ComposioHQ/awesome-claude-plugins |
| What it is | Curated Claude Code *plugin* catalog (plugins extend Claude Code with custom commands, agents, hooks, MCP servers via the plugin system). Includes `frontend-design`, `artifacts-builder`, `theme-factory`, `canvas-design`, `connect-apps`. |
| Verdict | useful (client) |
| Pack rating | 1 |
| Client rating | 3 |
| Already in use? | no |
| Integration shape | The pack does not currently package itself as a Claude Code plugin (open question: should it?). If a v12 plan moves the pack to plugin format, this index becomes the comparison set. For client projects with a UI surface (web frontend / design work), `frontend-design` and `artifacts-builder` are useful opt-in additions — but Optiquity's current focus (Swift app + Python server + gRPC) has no frontend surface where these plugins would apply. Reference, not adoption, until/unless a client project type with a web frontend enters the pack scope. |
| Risks / friction | Frontend/design plugins overlap with VS Code companion templates (which the pack already ships). Two competing UI-design surfaces would confuse client devs. |
| Verdict justification | Tied to project type. For Swift/Python/gRPC clients these plugins are no-op; for any future web-frontend client they become 4-rated. Holding at 3 to reflect typical client diversity. |

### 8. obra/superpowers

| Field | Content |
|---|---|
| Repo | `obra/superpowers` — https://github.com/obra/superpowers |
| What it is | A full agentic skills framework + software development methodology by Jesse Vincent (Prime Radiant). Skills: `brainstorming`, `planning`, `subagent-driven-development`, TDD (RED/GREEN/REFACTOR), git-worktree isolation, two-stage review (spec compliance → code quality). Cross-CLI (Claude Code / Codex / Cursor / Gemini CLI). |
| Verdict | useful (client) |
| Pack rating | 2 |
| Client rating | 4 |
| Already in use? | no |
| Integration shape | **Do not adopt wholesale — this is a competing methodology.** The pack's METHODOLOGY.md already codifies brainstorm/spec/plan/coder/reviewer/tester roles. Superpowers overlaps on every axis. *Selective borrowing:* (a) the `subagent-driven-development` skill's two-stage review pattern (spec compliance → code quality) maps cleanly onto the pack's coder + reviewer + auditor flow; could be cited in METHODOLOGY.md Part X with attribution. (b) The git-worktree isolation pattern is now supported as the pack's own opt-in worktree isolation (BD-197) — Superpowers' approach is more mature; worth comparing for the next pack-architect pass. (c) The `writing-skills` and RED/GREEN TDD skills are reference material for the pack's own skill authoring. For *client projects,* a user could run Superpowers alongside the pack — but the resulting agent-prompt collision (both want to spawn TDD subagents) needs an explicit coexistence note in OPTIONAL-FEATURES.md if we document it. |
| Risks / friction | **Direct collision with the pack's PM-Chat-coordinated workflow.** Superpowers wants to drive the workflow itself; the pack also wants to drive the workflow. They cannot both be "the brain" simultaneously. A client adopting both must choose one as primary. The pack should document this either-or explicitly. Maintenance churn: Superpowers is actively developed (RELEASE-NOTES shows frequent updates) — same schema-drift risk as Graphify. |
| Verdict justification | Genuinely good methodology and skills; structurally incompatible with running alongside the pack as a peer. Use as a reference / inspiration source for pack METHODOLOGY refinements; do not ship as a pack dependency or opt-in feature. |

### 9. travisvn/awesome-claude-skills

| Field | Content |
|---|---|
| Repo | `travisvn/awesome-claude-skills` — https://github.com/travisvn/awesome-claude-skills |
| What it is | Second curated skill catalog (distinct from ComposioHQ's, item 6). 12.3k stars per README. Anti-marketing filter ("not a marketing channel"); requires community traction (stars) for inclusion; warns about untrusted skills. |
| Verdict | useful (client) |
| Pack rating | 2 |
| Client rating | 3 |
| Already in use? | no |
| Integration shape | Same as ComposioHQ's catalog: discovery feed, vet individual skills, cherry-pick. The anti-marketing filter is a quality signal worth respecting. Cite alongside item 6 in `maintenance-docs/RECOMMENDATIONS.md` as the two-source horizon scan for skills. The catalog's curation criteria (stars + generalizability) are a model the pack could adopt for its own skill-inclusion criteria. |
| Risks / friction | Overlap with item 6 — running both surveys creates duplicate work. Pack maintainer should pick one as primary; the other is sanity-check. The Medium article's mention of "SEO, marketing, design, security" categories was not verified in WebSearch — current catalog focus is developer tools / documents / AI workflows. |
| Verdict justification | Same shape as item 6 but with different curation philosophy. Worth keeping in the discovery rotation; not pack infrastructure. |

### 10. wshobson/agents

| Field | Content |
|---|---|
| Repo | `wshobson/agents` — https://github.com/wshobson/agents |
| What it is | Large production-shaped subagent library: 83 specialized AI agents, 15 multi-agent workflow orchestrators, 42 development tools. Agents distributed across Haiku/Sonnet/Opus by task complexity. Drop-in via `~/.claude/agents/`. |
| Verdict | useful (client) |
| Pack rating | 2 |
| Client rating | 3 |
| Already in use? | no |
| Integration shape | **Reference, do not adopt wholesale.** Pack's 16-agent project roster (architect / coder / reviewer / tester / planner / auditor + 7 variants / docs-researcher / grpc-schema / repo-ops) is intentionally minimal and trinity-symmetric. Adopting wshobson's 83 agents into the pack would explode the roster and break trinity (his agents are Claude-only Markdown). Useful as a *pattern source* for new pack agents: when a client project needs a specialist not in the roster (e.g. `database-architect`, `observability-engineer`), check wshobson first for prompt prior art. The user can install wshobson's agents at `~/.claude/agents/` *alongside* the pack's project-level `.claude/agents/` — Claude Code merges machine-level and project-level rosters. Document this coexistence path in OPTIONAL-FEATURES.md as "augmenting the roster with community agents." |
| Risks / friction | Roster collision: if wshobson ships an `architect.md` and the pack ships an `architect.md`, project-level wins but the user may be confused which is loading. Trinity asymmetry: wshobson is Claude-only — copying his agents into `.codex/agents/` (TOML) or `.gemini/agents/` (YAML frontmatter) is a manual port the pack does not automate. Model-tier baked into agent files; user must accept his tier choices. |
| Verdict justification | Big library, good patterns, structurally incompatible with the pack's trinity-symmetric and intentionally-small roster. Use as a reference catalog when designing new pack agents; never copy-paste in bulk. |

### 11. baryhuang/claude-code-by-agents

| Field | Content |
|---|---|
| Repo | `baryhuang/claude-code-by-agents` — https://github.com/baryhuang/claude-code-by-agents |
| What it is | Electron desktop app + API for multi-agent Claude Code orchestration via `@mentions`. Coordinates local AND remote agents (each remote runs Claude Code on its own machine). Tech stack: Electron, Deno backend, TypeScript/React frontend. Not "59 specialized agents" — the Medium article appears to confuse this repo (orchestration shell) with a different agent library. |
| Verdict | no-op |
| Pack rating | 1 |
| Client rating | 1 |
| Already in use? | no |
| Integration shape | Does not fit. The pack is CLI-first; the PM Chat coordinates agents via paste-back, not via a desktop GUI's @mention system. The "remote agent" mode is interesting (could let a Mac and a Linux dev box share an agent pool) but the pack's existing cross-machine workflow (the git repo *is* the memory; sessions are local) is simpler and already documented in CLI-PM-SETUP.md. |
| Risks / friction | Adopting would replace the pack's coordination model. Architecturally inconsistent. The Medium article's "59 specialized agents" claim was not corroborated by WebSearch; users coming via the article will have wrong expectations. |
| Verdict justification | Solving a different problem than the pack solves. Not harmful, but no integration shape exists that adds value without replacing the PM Chat. |

### 12. github/github-mcp-server

| Field | Content |
|---|---|
| Repo | `github/github-mcp-server` — https://github.com/github/github-mcp-server |
| What it is | GitHub's official MCP server. Tools for issues, PRs, code search, releases, workflow runs, repo metadata. The most-used MCP server in the ecosystem per the Medium article. |
| Verdict | useful (both) |
| Pack rating | 4 |
| Client rating | 4 |
| Already in use? | yes — confirmed active in this session |
| Integration shape | Already integrated. Extended use opportunities: (a) **Tracker mode automation** — v11's `pack-tracker.sh` shells out to `gh` CLI; the MCP server provides the same surface via tool calls. Migrating `tracker-provider-gh.sh` to optionally use the MCP server (when available) could give richer tool-call telemetry and cleaner agent integration. Open BD candidate. (b) **Issue triage in CI** — pair with item 4 (claude-code-action) for `@claude` triage of inbound bugs via the `inbound.yml` issue form. (c) **Pack-reviewer** in PR-review mode (item 4) calls this MCP server to fetch PR diffs/comments. (d) PR review templates use it for "search prior reviewer comments." |
| Risks / friction | Auth scopes: the MCP server inherits the running user's GH credentials; pack must document required scopes in DEPENDENCIES.md (already partially done for `gh` CLI). Rate limits on hot loops. Tool-call telemetry leaks repo names/issue titles to the host CLI's vendor — note in privacy section. |
| Verdict justification | Already part of the workflow; the unexploited surface is non-trivial. Worth a deliberate "MCP-vs-shell-out" decision in v12 for the tracker path. |

### 13. microsoft/playwright-mcp

| Field | Content |
|---|---|
| Repo | `microsoft/playwright-mcp` — https://github.com/microsoft/playwright-mcp |
| What it is | Microsoft's official MCP server for Playwright browser automation. Lets Claude navigate web pages, fill forms, scrape dynamic content. |
| Verdict | useful (client) |
| Pack rating | 2 |
| Client rating | 3 |
| Already in use? | yes — confirmed active in this session |
| Integration shape | Already integrated for pack-dev use (likely for doc-research / link verification). For client projects: only matters if the project has browser-interaction needs (UI testing, web scraping, dynamic-content verification, OAuth flow testing). Optiquity's current scope (Swift + Python + gRPC) has no browser surface, so client-side value is project-type-dependent. Add a `PLATFORM-SKILLS.md` row "web-automation" → `playwright-mcp` capability for future client projects that include a web frontend. |
| Risks / friction | Cost: each Playwright session spins up a real browser; tokens for screenshots/DOM serialization add up. Privacy: pages visited are visible to the host CLI's vendor. For IP-sensitive client research, document the data flow. |
| Verdict justification | Already in use for pack-side research. Client-side value is conditional on having a UI surface, which most current Optiquity projects don't. Rated 3 to reflect realistic project mix. |

### 14. crystaldba/postgres-mcp

| Field | Content |
|---|---|
| Repo | `crystaldba/postgres-mcp` — https://github.com/crystaldba/postgres-mcp |
| What it is | "Postgres MCP Pro" — configurable read/write Postgres access for AI agents. Two protection modes: "Unrestricted" (dev) and "Restricted" (production-safe with SQL pre-parse via pglast, COMMIT/ROLLBACK rejection). Includes index tuning, query plans, schema intelligence, health analysis. |
| Verdict | useful (client) |
| Pack rating | 1 |
| Client rating | 4 |
| Already in use? | no |
| Integration shape | Natural fit for OPTIONAL-FEATURES.md entry "Postgres MCP" for any client project with a Postgres backend (Optiquity's Python server projects in particular). Default to "Restricted" mode in pack examples. Configuration goes in `.mcp.json.example`; pack-coder + reviewer + auditor-code + tester all benefit when working on DB-touching code (the architect can ask schema questions instead of grepping migration files). Pair with `PLATFORM-SKILLS.md` capability `postgres-access`. For the pack repo itself: no Postgres surface, so pack-dev value is near-zero. |
| Risks / friction | Connection string is a credential — must NOT be committed; document in `.mcp.json.example` and `.gitignore`. The "Unrestricted" mode is dangerous; pack docs should be unambiguous that "Restricted" is the default. Read-only DB user pattern should be the recommended setup. |
| Verdict justification | Transformative for client projects with Postgres; no-op for pack-dev. Pair this with the v11 tracker mode for projects that use issues + Postgres together — gives agents a coherent view. Worth a v12 BD as the second MCP-server opt-in feature after Graphify. |

### 15. upstash/context7

| Field | Content |
|---|---|
| Repo | `upstash/context7` — https://github.com/upstash/context7 |
| What it is | MCP server that fetches real-time, version-specific library documentation into prompts. Prevents Claude from hallucinating APIs. |
| Verdict | useful (both) |
| Pack rating | 4 |
| Client rating | 4 |
| Already in use? | yes — confirmed active in this session, system-reminder confirms it |
| Integration shape | Already integrated for pack-docs-researcher (verified library docs against training data). Extended use: (a) Document explicit guidance in `pack-docs-researcher.md` agent file to prefer Context7 over WebSearch for known libraries (system-reminder this session says "prefer this over web search for library docs"). (b) For client projects: ensure `.mcp.json.example` includes Context7 by default for Swift package docs (Swift, SwiftUI, Combine, Network), Python (FastAPI, gRPC, SQLAlchemy), gRPC schema docs. (c) Add a `PLATFORM-SKILLS.md` capability `library-docs` mapped to `context7`. (d) Re-verify Context7 catalog coverage for Apple frameworks specifically — gaps would push back to WebSearch + the bundled Xcode docs path the pack already uses. |
| Risks / friction | Catalog coverage varies — not every library is indexed. Sends library names + question to Upstash. Cost: free tier today, may change. |
| Verdict justification | Already a load-bearing MCP server for pack-docs-researcher and for client agents touching unfamiliar libraries. Extended use mostly about making the default config richer and documenting the "prefer over WebSearch" rule in agent files. |

### 16. zilliztech/claude-context

| Field | Content |
|---|---|
| Repo | `zilliztech/claude-context` — https://github.com/zilliztech/claude-context |
| What it is | Semantic code search MCP for Claude Code. Hybrid search over very large repos (millions of LOC). Merkle-tree incremental indexing. AST-aware chunking with fallback. Supports multiple embedding providers (OpenAI, VoyageAI, Ollama, Gemini) and vector DBs (Milvus, Zilliz Cloud). Languages: TS/JS/Python/Java/C++/C#/Go/Rust/PHP/Ruby/Swift/Kotlin/Scala/Markdown. Reports ~40% token reduction at equivalent retrieval quality. |
| Verdict | useful (client) |
| Pack rating | 2 |
| Client rating | 4 |
| Already in use? | no |
| Integration shape | Strong client-side fit for large multi-language client codebases (Swift app + Python server + gRPC schemas — covers all three). Add OPTIONAL-FEATURES.md entry "Semantic code search (claude-context)" parallel to a future Graphify entry. **Coexistence with mcp-local-rag and Graphify:** mcp-local-rag indexes *docs* (METHODOLOGY.md and similar). Graphify (deferred to v12 per RESEARCH-GRAPHIFY-SYNTHESIS.md) indexes *structural code relationships*. claude-context indexes *semantic code chunks* for retrieval. Three different layers, all complementary; document the layering explicitly in CLI-PM-SETUP.md. For the pack repo itself: pack is small enough (~hundreds of files) that grep + direct read still wins; the semantic layer adds noise. Pack-dev rating 2 reflects this. |
| Risks / friction | Requires running a vector DB (Milvus locally or Zilliz Cloud paid). Adds infrastructure dependency the pack has so far avoided (mcp-local-rag is process-only). Embedding provider choice has privacy implications — OpenAI sends code embeddings off-machine; Ollama keeps local. Document the Ollama option as the local-first default. |
| Verdict justification | The "right" tool for large client codebases where mcp-local-rag's doc-only scope and grep both run out of headroom. Strong v12 candidate alongside Graphify; the two solve different problems and should both be opt-in. |

### 17. ruvnet/claude-flow (now Ruflo)

| Field | Content |
|---|---|
| Repo | `ruvnet/claude-flow` (renamed to `ruvnet/ruflo`) — https://github.com/ruvnet/claude-flow |
| What it is | Enterprise orchestration platform with "hive-mind swarm intelligence" — queens coordinate worker agents, 54+ specialized agents, 87 MCP tools, SQLite-backed persistent memory, always-on daemon with 5-second status line, ReasoningBank vector memory + knowledge graph + neural-network outcome learning. |
| Verdict | no-op |
| Pack rating | 1 |
| Client rating | 2 |
| Already in use? | no |
| Integration shape | **Does not fit.** Claude-flow is its own coordination platform competing with the pack's PM-Chat-coordinated model. Adopting it would mean abandoning the pack's "Claude Chat is the brain, CLI agents are the hands" axiom from METHODOLOGY.md. The daemon + persistent SQLite memory + neural-network learning system breaks the pack's "the git repo is the memory" property. None of the pack's 16 agent definitions would survive the move. |
| Risks / friction | High complexity, high opacity (neural-network-based routing is non-deterministic), runs as a daemon (the pack avoids daemons). Renamed mid-flight to Ruflo — repo path stability concern. Version churn appears high (v2.7, v3 alpha). |
| Verdict justification | A coherent product, just a fundamentally different architecture. The pack and claude-flow are alternative solutions to the same problem; they cannot meaningfully coexist. Worth understanding as a competitor; not worth integrating. |

### 18. smtg-ai/claude-squad

| Field | Content |
|---|---|
| Repo | `smtg-ai/claude-squad` — https://github.com/smtg-ai/claude-squad |
| What it is | Go TUI that manages parallel Claude Code / Codex / Gemini / Aider sessions. tmux for terminal isolation + git worktrees for code isolation. Each agent gets its own worktree; no automatic task coordination (the user decides what each agent works on). Install via Homebrew or curl. |
| Verdict | no-op |
| Pack rating | 2 |
| Client rating | 2 |
| Already in use? | no |
| Integration shape | Overlaps with Claude Code's native Agent Teams and the pack's own opt-in worktree isolation (BD-197), both documented in OPTIONAL-FEATURES.md. The base-branch behavior that BD-197 addresses (an isolated worktree branching from `origin/main` rather than local HEAD unless `worktree.baseRef: "head"` is set) is the same class of pitfall claude-squad's per-agent-worktree model would expose. A user could install it as a personal multi-tasking tool unrelated to the pack; the pack does not need to know about it. Not worth an OPTIONAL-FEATURES.md entry. |
| Risks / friction | Worktree-isolation interaction overlaps the pack's own opt-in worktree isolation (BD-197) and its `worktree.baseRef: "head"` base-branch requirement. tmux dependency. The "no automatic task coordination" property removes the pack's PM-Chat-coordinated discipline; users running claude-squad will fall into the pattern the pack is designed to prevent. |
| Verdict justification | Genuinely useful as a personal dev convenience for someone running many parallel sessions; not a pack-integration target. The Agent Teams feature already covers the structured-parallel use case. |

### 19. thedotmack/claude-mem

| Field | Content |
|---|---|
| Repo | `thedotmack/claude-mem` — https://github.com/thedotmack/claude-mem |
| What it is | Claude Code plugin that captures all tool usage during sessions, compresses with Claude agent-sdk, stores in ChromaDB, and injects relevant context into future sessions via MCP. Beta "Endless Mode" compresses tool outputs to ~500-token observations to extend session length. |
| Verdict | no-op |
| Pack rating | 1 |
| Client rating | 2 |
| Already in use? | no |
| Integration shape | **Conflicts with the pack's memory model.** Pack's existing memory strategy: (a) git repo is authoritative — BACKLOG.md, STATUS.md, CHANGELOG.md, agent reports under `chat-output/` or similar; (b) mcp-local-rag for doc retrieval; (c) PM Chat's session history for in-flight context. Adding claude-mem inserts a third tier that auto-summarizes prior tool calls — but those tool calls are *already* recoverable from the git diff / agent report. Auditability degrades when AI-compressed summaries replace verifiable text. The "Endless Mode" claim of extending session length is real but the pack's discipline is to *commit and start fresh* at phase boundaries, not stretch sessions. The pack already has the right pattern. |
| Risks / friction | ChromaDB persistence is per-machine — breaks the pack's "git repo is the memory" cross-machine property documented in CLI-PM-SETUP.md. AI compression means the recovered context may be subtly wrong. License/cost: requires Claude API tokens for the compression itself. |
| Verdict justification | A genuine solution for users who run very long single sessions without committing — but that is an anti-pattern from the pack's perspective. The pack solves session-length problems by sharper commit discipline, not by AI summarization. |

### 20. nizos/tdd-guard

| Field | Content |
|---|---|
| Repo | `nizos/tdd-guard` — https://github.com/nizos/tdd-guard |
| What it is | Claude Code hook that intercepts file modifications and blocks edits that violate TDD: implementation without a failing test, over-implementation beyond test requirements, adding multiple tests at once. Configurable via env vars (validation client = sdk or api, model = claude-sonnet-4-0 default). Documented support for Vitest and pytest reporters; works with any language/runner. |
| Verdict | useful (client) |
| Pack rating | 1 |
| Client rating | 4 |
| Already in use? | no |
| Integration shape | Natural OPTIONAL-FEATURES.md opt-in for client projects with a mature test suite. The pack already has a `tester` agent and a `verification-harness` skill; tdd-guard plugs in at the hook layer, *below* those — the pack's tester runs after the work is allowed; tdd-guard gates whether the coder can do the work in the first place. Concretely: ship `project-template/.claude/settings.json` with a commented-out hook stanza that points to tdd-guard, plus a `PLATFORM-SKILLS.md` capability `tdd-enforcement` that hints at this hook when the project's test coverage threshold is met. Trinity-exempt: hooks are Claude Code-specific (Codex / Gemini have different surfaces); document the asymmetry the same way OPTIONAL-FEATURES.md handles Agent Teams. For the pack itself: pack is mostly Markdown + shell + a Python validator; no useful TDD surface here. |
| Risks / friction | False positives are inevitable — block legitimate prototyping / spike work. Document an escape hatch (`TDD_GUARD_DISABLE=1` or similar) prominently. Costs API tokens for every blocked edit (the hook calls Claude to validate the edit). Trinity asymmetry: Codex hooks and Gemini hooks are different surfaces; the pack would need separate equivalents or an explicit "Claude-only feature" gate. |
| Verdict justification | Right shape for mature client projects (Python server + Swift unit-test surface both qualify). Trinity asymmetry and token cost keep it at opt-in. Excellent fit for the `tester` + `coder` loop. Strong v12 BD candidate alongside Graphify and postgres-mcp. |

---

## Synthesis

### High-rated items grouped by category

**Official Anthropic foundations (1, 2, 3, 4)** — the four `anthropics/*` repos are the canonical reference set. Item 1 (claude-code) is the platform; item 3 (cookbooks) is the pattern reference; item 4 (claude-code-action) is the CI surface; item 2 (skills) is the official skills exemplar. These four have no internal conflict and should all be cited / pinned in pack reference material (DEPENDENCIES.md, VERIFIED-NOTES.md, RECOMMENDATIONS.md).

**Discovery indexes (5, 6, 9)** — three "awesome" lists. Item 5 (hesreallyhim) is the master index; items 6 (Composio) and 9 (travisvn) are skill-specific catalogs with different curation philosophies. The pack maintainer should establish a quarterly horizon-scan against all three. They do not conflict — they overlap, which is a feature for cross-checking.

**MCP servers — already integrated (12, 13, 15)** — github-mcp-server, playwright-mcp, context7. These are load-bearing. Extended use is mostly about documenting the existing integration more rigorously in DEPENDENCIES.md and `.mcp.json.example`, and (for context7 specifically) updating `pack-docs-researcher.md` with explicit prefer-over-WebSearch guidance.

**MCP servers — opt-in candidates (14, 16)** — postgres-mcp and claude-context. Both transformative for client projects of the right shape; both no-op for pack-dev. Both are strong v12 BD candidates following the same opt-in pattern as the v11 tracker and the planned Graphify integration. They compose cleanly: claude-context for code retrieval, postgres-mcp for DB awareness, mcp-local-rag for doc retrieval, Graphify for structural queries — four orthogonal layers, no overlap.

**Subagent libraries (8, 10, 11)** — Superpowers (8) is a competing methodology that overlaps the pack's whole stack; wshobson/agents (10) is a 83-agent library that overflows the pack's intentional 16-agent roster; baryhuang/claude-code-by-agents (11) is an orchestration desktop GUI. None should be adopted wholesale. All three are useful as pattern references when designing new pack agents or refining methodology.

**Orchestration/memory competitors (17, 18, 19)** — claude-flow/Ruflo (17), claude-squad (18), and claude-mem (19) all want to coordinate or persist context in ways that conflict with the pack's PM-Chat-coordinated + git-as-memory model. All three are no-op for the pack. Worth knowing about for competitive awareness; not worth integrating.

**Quality-enforcement hooks (20)** — tdd-guard. Cleanest fit of the "competing" tools because it operates at the hook layer below the pack's agent layer rather than above it. A user can run tdd-guard without it touching METHODOLOGY.md's agent flow.

**Frontend/design plugins (7)** — ComposioHQ/awesome-claude-plugins. Project-type-dependent; no current Optiquity project has a UI surface where these apply.

### Compositions that work

A v12 client project could opt into all of the following simultaneously without internal conflict:
- mcp-local-rag (already pack-default) for METHODOLOGY ingestion
- github-mcp-server for tracker mode + PR / issue automation
- context7 for library docs
- playwright-mcp if the project has any web surface
- postgres-mcp for DB-backed projects
- claude-context for large-codebase semantic search
- Graphify (v12 deferred) for structural queries
- tdd-guard for mature-test-suite projects
- claude-code-action for PR review CI
- selected anthropics/skills (pdf/docx/xlsx/pptx) for office-export projects

Layered conceptually: hooks (tdd-guard) below agents (pack roster) below context retrieval (the MCP server stack) below coordination (PM Chat). Each layer is independently opt-in.

### Compositions that conflict

- **Superpowers (8) ↔ pack METHODOLOGY** — both want to drive the workflow. Either-or, not both.
- **claude-flow / Ruflo (17) ↔ pack PM-Chat-coordinated model** — alternative architectures for the same problem.
- **wshobson/agents (10) installed at `~/.claude/agents/`** with a pack agent of the same name at project level — project-level wins per Claude Code rules, but causes confusion. If a user installs wshobson alongside the pack, recommend prefixing his agents (`wsh-architect.md` etc.) or disabling overlapping ones.
- **claude-mem (19) ↔ "git repo is the memory" axiom** — ChromaDB per-machine memory breaks cross-machine workflow.
- **claude-squad (18) ↔ pack PM-Chat coordination + the pack's own opt-in worktree isolation (BD-197)** — wrong layer for the pack's discipline.

### Things you may not have asked

**(a) Plugin packaging question.** The Claude Code plugin system (anthropics/claude-plugins-official, item 1 search result) is now an officially supported distribution channel. The pack currently distributes as a template repo that gets copied into projects via `init-project.sh`. A v12 question worth a dedicated pack-architect pass: **should the pack also publish as a Claude Code plugin?** That would shift the install surface from "clone + run init script" to "`/plugin install optiquity-ai-agent-config-pack`." Pros: discoverability, native upgrade path. Cons: Claude-only (breaks trinity unless Codex/Gemini parity is maintained separately), plugin format constraints may not fit the pack's multi-CLI ambitions.

**(b) Cookbook patterns the pack doesn't codify yet.** The cookbook's `patterns/agents/` directory contains specific patterns (e.g. evaluator-optimizer loop, orchestrator-worker, routing) that the pack's METHODOLOGY.md sketches but does not formally name. A v12 pass could align METHODOLOGY.md vocabulary with cookbook vocabulary for easier user comprehension.

**(c) Privacy delta accumulating.** Each MCP server adds a data-flow surface. The pack today is local-first with one external surface (the host CLI's vendor). Adding postgres-mcp (DB content), playwright-mcp (web content), context7 (library queries), tdd-guard (file edit content for validation), claude-code-action (PR diffs to Anthropic) each adds a new external touch. By v12 the privacy story is more complex than "the CLI talks to its vendor." Worth a unified `PRIVACY.md` in supporting-docs/ that enumerates every external data flow and the opt-in to enable it.

**(d) Token-budget transparency.** Several of these features (tdd-guard, claude-code-action, claude-mem) call the Claude API on every gate. The pack does not currently surface a "this feature costs ~N tokens per X" line in OPTIONAL-FEATURES.md. Adding that field to the OPTIONAL-FEATURES.md schema (the entry shape ends at "When to skip" today) would help users make informed opt-in decisions.

**(e) Skill license clarity.** anthropics/skills is "source-available, not OSI." The pack's LICENSE.md is also source-available. Bundling Anthropic skills directly would create a license interaction the pack hasn't audited. Recommend: reference upstream paths, do not vendor.

**(f) The discoverable-feature problem.** Even with three "awesome" indexes, the pack maintainer has no automated way to know when a *new* category appears (e.g. the rise of "output styles" as a Claude Code concept). A simple `maintenance-docs/HORIZON-SCAN.md` with a quarterly checklist (visit each awesome list, note new categories, write a one-line "do we care?" assessment) would be the cheapest defense.

**(g) "Already in use" but not pinned.** The four items confirmed in active use (1, 12, 13, 15) are not all pinned in DEPENDENCIES.md to specific versions. Pin them, even loosely (`>= v0.x.y`), so the validate-pack workflow can flag drift.

---

CLAUDE-REPOS-SURVEY-COMPLETE: 2026-05-11 — The four `anthropics/*` foundations plus three MCP servers (postgres-mcp, claude-context, tdd-guard hooks) are the strongest v12 opt-in additions; the orchestration competitors (claude-flow, claude-squad, claude-mem) and the methodology overlap (Superpowers) are no-ops because they architecturally conflict with the pack's PM-Chat-coordinated, git-as-memory, trinity-symmetric model.
