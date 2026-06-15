# RESEARCH-BD-221 — Gemini CLI → Antigravity (Antigravity CLI) full transition

**BD:** BD-221 (convert the pack's Gemini-CLI support to Antigravity, the Gemini CLI successor). **Author:** pack-docs-researcher (fresh, unbiased). **READ-ONLY pass** — this file is the only write.
**Tree:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev` (branch `v11-dev`). **HEAD at research time:** `e5a366f9f94c4819d407ec252e4eb691e14ab251`.
**Date:** 2026-06-15. **Mandate:** foundational, current research for the BD-221 architect — install/invocation, config layout (RESOLVE the path disagreement), MCP config (the BD-201 piece), the official Gemini→Antigravity migration, feature/API parity vs Gemini, community signal, preview-vs-GA stability, and a surface-by-surface conversion map. All external facts re-verified against authoritative online sources on 2026-06-15 (URLs + dates inline). Inference is flagged throughout.

**Attestation of required reading (all read in full at HEAD `e5a366f`):** `CLAUDE.md` § "## Pack memory"; `backlog/BD-221.md`; `backlog/BD-201.md`; `backlog/BD-217.md`; `maintenance-docs/v11-implementation/RESEARCH-BD-217-WORKTREE-ISOLATION.md` (the worktree survey + the config-dir disagreement); the pack's current Gemini surfaces — `project-template/GEMINI.md` (492 lines), the pack-root `GEMINI.md` (539 lines), `project-template/.gemini/` (settings.json, .env.example, 16 `agents/*.md`, 2 `commands/*.toml`), the pack-root `.gemini/` (5 `pack-*` agents, 2 commands, 9 skills); the Gemini-referencing validators/scripts (`scripts/validate-pack.py`, `scripts/init-project.sh`, `scripts/lib/*.sh`, `scripts/compare-agent-trinity.py`, `scripts/merge-trinity.py`, `scripts/migrate-v10-to-v11.sh`) and docs (`supporting-docs/{SETUP-NEW,SETUP-EXISTING,INSTALL-PROCEDURES,METHODOLOGY,DEPENDENCIES,CLI-PM-SETUP,MIGRATION-v10-to-v11}.md`, `project-template/docs/pack/*`); memory `feedback_verify_availability_not_just_existence.md` + `feedback_external_rules_census_before_design.md`.

---

## 0. EXECUTIVE SUMMARY (read this first)

**The product is real, public, and inspectable NOW.** Antigravity CLI (binary name **`agy`**, built in Go, closed-source) shipped at Google I/O **2026-05-19** as the terminal surface of the four-product Google Antigravity platform (Antigravity 2.0 desktop, Antigravity CLI, Antigravity SDK, Antigravity IDE). Its source-of-record GitHub repo is **`google-antigravity/antigravity-cli`** (created 2026-05-13; an active CHANGELOG through **v1.0.8** and a live issue tracker). Official docs live at `antigravity.google/docs/cli-*`. [Google Developers Blog, 2026-05-19; README `google-antigravity/antigravity-cli`, retrieved 2026-06-15.]

**CONFIG-DIR RESOLUTION (the BD-217 disagreement, settled).** The two candidate paths the BD-217 survey flagged are BOTH real but mean DIFFERENT things — they are not competitors:
- **`~/.gemini/`** is the agent config-of-record home (the Antigravity suite kept the `.gemini` home dir from Gemini CLI). Its modern sub-layout is: `~/.gemini/config/` = the **shared** cross-surface config (`mcp_config.json`, `hooks.json`, shared plugins, approved `projects/`); `~/.gemini/antigravity-cli/` = the **CLI-specific** state (`settings.json`, `cache/`, CLI-only `skills/`, CLI-only `plugins/`, dynamically-generated `mcp/`); `~/.gemini/skills/` = **shared** skills across all Antigravity tools; `~/.gemini/GEMINI.md` = global context. [Goratela day-1 hands-on confirmed via the `/skills` command, 2026-05-24; CHANGELOG v1.0.2/v1.0.3/v1.0.8 path-fix entries; retrieved 2026-06-15.]
- **`~/.config/Antigravity/`** (capital A) is the **desktop app's Linux install/bin root** (it holds the `agy-node` wrapper) — NOT the agent config-of-record. The community `~/.config/antigravity/config.toml` claim is a CONFLATION with the desktop installer path; it is not where MCP/skills/agents/permissions live. [antigravity-cli issue **#354** "Installer violates XDG spec by placing executables in `~/.config`", OPEN; retrieved 2026-06-15.]
  - **Verdict:** the pack converts AGAINST `~/.gemini/` (global) + project-root `.agents/` (workspace), NOT `~/.config/antigravity/`. The BD-217 survey's `~/.gemini/antigravity-cli/` guess was directionally right for CLI-specific state; the `~/.config/antigravity/` guess was wrong for agent config.

**MCP-CONFIG PATH (the BD-201 piece, settled).** Global/shared MCP config is **`~/.gemini/config/mcp_config.json`** (a single top-level `mcpServers` object). Per-workspace MCP config is **`.agents/mcp_config.json`** at the project root. The stdio shape (`command` / `args` / `env`) is UNCHANGED from Gemini's `settings.json` `mcpServers` block. THREE deltas vs Gemini: (1) the block moved OUT of `settings.json` into a dedicated `mcp_config.json` (BD-201's anticipated relocation — CONFIRMED); (2) remote/HTTP servers use **`serverUrl`** (older `httpUrl`/`url` semantics shifted — see §3 for the nuance; `url` IS accepted per CHANGELOG v1.0.5 but the auth-bearing remote shape wants `serverUrl`); (3) top-level per-server `timeout` is no longer supported (a configurable launch timeout exists globally per CHANGELOG v1.0.7). [Goratela 2026-05-24; CHANGELOG v1.0.3/v1.0.5/v1.0.7; antigravity-cli issue **#60** project-local MCP read-but-ignored; retrieved 2026-06-15.]

**PREVIEW-vs-GA + STABILITY VERDICT (`verify-availability-not-just-existence`).** Antigravity CLI is **PUBLIC PREVIEW, free for individuals, closed-source, no org/plan gate on the CLI's core features** — usable on a personal Google account TODAY. BUT it is **actively churning** (8 patch releases 1.0.1→1.0.8 in weeks; config paths fixed across versions; a buggy weekly-compute quota; multiple open data-safety/crash bugs). For the pack this means: TREAT THE CONFIG PATHS AS STABLE-ENOUGH-TO-SHIP (they are now primary-source-confirmed and the recent CHANGELOG fixes CONVERGED on them), but TREAT THE AGENT/SUBAGENT MODEL + the worktree feature as FORWARD-LOOKING / still-settling, and DO NOT hard-code model IDs, quota assumptions, or the migration command's exact spelling without a re-verify at design time.

**THE BIGGEST CONVERSION RISK (architect must confront first).** Antigravity CLI **abolishes the loose `.gemini/agents/*.md` per-agent-file model** that the pack's 16 Gemini agents depend on. Antigravity subagents are **DYNAMIC / on-demand** (the main agent spawns them; no upfront markdown files are required or auto-discovered from a bare `agents/` dir). Custom NAMED agents are definable, but only **inside a plugin bundle** (`plugins/<name>/agents/`) and in a **JSON `agent.json` shape** (`name`/`description`/`hidden`/`config`), NOT as loose `*.md` files with YAML frontmatter. There is an OPEN official discussion (#27305 "What's the Subagent format for antigravity-cli?") — the exact custom-agent authoring contract is the single least-settled load-bearing detail. **The pack's whole "16 trinity-parallel agent files per CLI" architecture does not map 1:1 onto Antigravity.** The architect must decide: (a) convert the 16 Gemini agents into an Antigravity **plugin** that bundles `agents/` + `skills/`, OR (b) collapse the agent roster into AGENTS.md/GEMINI.md guidance + skills and lean on dynamic subagents, OR (c) a hybrid. This is a structural fork, not a path-substitution. [Galloro migration guide, 2026-06; agentpedia deep-dive; gemini-cli discussion #27305; antigravity-awesome-skills plugins.md; retrieved 2026-06-15.]

**OTHER TOP CONVERSION RISKS:**
1. **Skills are MOSTLY portable** — Antigravity uses the cross-tool "Agent Skills" `SKILL.md` standard (YAML `name`/`description` frontmatter + markdown body), the SAME shape the pack already ships. But the LOCATION changes: global = `~/.gemini/skills/` (shared) or `~/.gemini/antigravity-cli/skills/` (CLI-only); workspace = **`.agents/skills/`** (NOT `.gemini/skills/`). The pack's installer (`stage_s4_skills()`) currently writes `.gemini/skills/` — that path is read-but-not-the-modern-location and must move to `.agents/skills/`.
2. **Commands change format + home.** The pack ships `.gemini/commands/*.toml` (Gemini's TOML custom-command format). Antigravity custom slash commands come from **skills** (a skill registers as a `/name` slash command) or **plugins**, not loose project `.toml` files. The `.toml` command files have no direct Antigravity analog.
3. **The `.env` capability mechanism** (`.gemini/.env` `AGENT_CAPABILITIES`) — Antigravity's settings/permissions live in `~/.gemini/antigravity-cli/settings.json` with a structured `permissions` block (allow/ask/deny, Deny>Ask>Allow). The pack's per-CLI capability-parity design (Claude settings.json env / Codex config.toml table / Gemini .env) needs an Antigravity-correct landing spot decided at design time.
4. **The pack ships NO settings file (hard constraint).** Antigravity auto-writes `~/.gemini/antigravity-cli/settings.json` and a `trustedWorkspaces` list on first run; the pack must NOT ship/auto-write it — same posture as today's Gemini support. The MCP config (`mcp_config.json`) is the one config the pack documents as an example, never ships live (matches the existing `.mcp.json.example` / `settings.json` example pattern).
5. **`agy` binary vs `antigravity` desktop collision + PATH** — `~/.local/bin/agy` must be on PATH; on Linux the desktop app's `/usr/bin/antigravity` collides. `agent-run.sh` (the pack's launcher) must learn the `agy` invocation, the new approval/permission flags (`--dangerously-skip-permissions`, `--sandbox`, `-p`/`--print` headless), and the @-agent vs dynamic-subagent reality.
6. **Worktree isolation is native but BUGGY** — coordinated with BD-217: subagents can auto-create isolated worktrees + auto-cleanup + post diffs back, AND `request-review` is the DEFAULT permission level (a near-native fit for agents-never-commit). BUT data-loss bugs are OPEN (issue **#388** "Deleting Conversation Deletes entire worktree" — wiped untracked files, filed 2026-06-14; **#253** no project ref when launched from a worktree; **#184** subagent quota). Design defensively.

**PACK-vs-PROJECT SEPARATION (`pack-project-separation-of-concerns`).** The conversion spans TWO separate artifact families: (A) pack-self surfaces (pack-root `GEMINI.md`, `.gemini/pack-*` agents/commands/skills, the pack's own dev tooling) and (B) client `project-template/` surfaces (the shipped `GEMINI.md`, `.gemini/` agents/commands/skills/settings, install plumbing, docs, validators that check the shipped tree). These are SEPARATE deliverables and must be converted independently — the §1 map tags each row PACK-SELF or PROJECT-TEMPLATE.

**SCHEDULE NOTE for BD-221's blocker line.** BD-221 lists "EXTERNAL — Antigravity GA (~2026-06-18)" as a blocker. That estimate conflates two dates: **06-18 is the Gemini-CLI DEPRECATION date, not an Antigravity GA date.** Antigravity CLI has been publicly available since 2026-05-19 and is inspectable now; there is no separate "GA" gate to wait for (it is labeled public preview, and Google has not announced a strict-commercial-GA date). The research/design is UNBLOCKED today. Only a user requirement of "no preview software in v11.0" would re-impose a gate — surface this to the user (it mirrors the BD-217 survey's §3 finding).

---

## 1. SURFACE-BY-SURFACE CONVERSION MAP (architect designs from this)

Confidence legend: **HIGH** = primary-source-confirmed (official repo/CHANGELOG/blog or multiple independent corroborating sources); **MED** = single strong community source or settling-but-consistent; **LOW** = single-sourced / conflicting / explicitly flagged unconfirmed by its own source.

| # | Pack Gemini surface (current) | Surface family | Antigravity equivalent | Conversion action | Conf. | Citation |
|---|---|---|---|---|---|---|
| 1 | `project-template/GEMINI.md` (trinity member, 492 ln) | PROJECT-TEMPLATE | `GEMINI.md` still read (backward-compat); `AGENTS.md` also read; `.antigravity.md` reportedly takes precedence | KEEP GEMINI.md as the trinity member (it still works); update its Gemini-CLI-specific prose (operating notes, `@agent`, `.gemini/` paths, approval modes) to Antigravity reality. Decide whether to ALSO ship `.antigravity.md` (LOW-conf precedence claim — do not chase yet). | HIGH (GEMINI.md works) / LOW (.antigravity.md precedence) | inventivehq 2026-05-22; agentpedia AGENTS.md guide; gcli-migration docs |
| 2 | pack-root `GEMINI.md` (539 ln) | PACK-SELF | same as #1 | Same treatment, pack-audience prose. Separate artifact from #1. | HIGH | (as #1) |
| 3 | `project-template/.gemini/agents/*.md` (16 agents, YAML frontmatter) | PROJECT-TEMPLATE | **NO loose-`.md` equivalent.** Dynamic subagents (on-demand); custom NAMED agents only via plugin bundle `plugins/<name>/agents/` + `agent.json` (JSON: `name`/`description`/`hidden`/`config`) | **STRUCTURAL FORK** (see §0 top risk). Architect decides: plugin-bundle the roster, OR collapse to AGENTS.md+skills+dynamic subagents, OR hybrid. NOT a path substitution. | MED (plugin agents/ exists) / LOW (exact agent.json contract — discussion #27305 open) | Galloro 2026-06; agentpedia deep-dive; antigravity-awesome-skills plugins.md; gemini-cli #27305 |
| 4 | pack-root `.gemini/agents/pack-*.md` (5 agents) | PACK-SELF | same as #3 | Same fork, pack-audience. Separate artifact. | MED/LOW | (as #3) |
| 5 | `project-template/.gemini/commands/*.toml` (pm-startup, pack-help) | PROJECT-TEMPLATE | Custom slash commands come from **skills** (skill → `/name`) or **plugins**; no loose project `.toml` command format | Convert each `.toml` command into a skill (or plugin command) that registers the slash command. The TOML format is dropped. | MED | addyosmani agent-skills (skills→slash cmds); agentpedia "no gemini skills cmd yet"; cli-plugins docs |
| 6 | pack-root `.gemini/commands/*.toml` (pack-help, pack-startup) | PACK-SELF | same as #5 | Same, pack-audience. | MED | (as #5) |
| 7 | `project-template/.gemini/skills/` (Tier-0 skills, installed by `stage_s4_skills()`) | PROJECT-TEMPLATE | Workspace skills at **`.agents/skills/<name>/SKILL.md`**; SKILL.md format = cross-tool Agent Skills standard (UNCHANGED frontmatter) | MOSTLY PORTABLE: SKILL.md content stays; the DIRECTORY moves `.gemini/skills/` → `.agents/skills/`. Update `stage_s4_skills()` target path. | HIGH (SKILL.md format) / HIGH (`.agents/skills/` workspace path) | Goratela 2026-05-24; agentpedia deep-dive; dev.to skills standard |
| 8 | pack-root `.gemini/skills/` (9 skills) | PACK-SELF | global shared skills at `~/.gemini/skills/` OR CLI-only `~/.gemini/antigravity-cli/skills/`; in-repo, workspace `.agents/skills/` | Decide global-vs-workspace placement; SKILL.md content portable. | HIGH | (as #7) |
| 9 | `project-template/.gemini/settings.json` (`mcpServers` block + `_readme`/`_tools`) | PROJECT-TEMPLATE | MCP block RELOCATES to `mcp_config.json`; settings.json becomes Antigravity's own auto-written file (NOT pack-shipped) | Move the `mcpServers` example OUT of settings.json INTO a `mcp_config.json` example (global `~/.gemini/config/mcp_config.json` or workspace `.agents/mcp_config.json`). Do NOT ship a live settings.json (Antigravity auto-writes it). | HIGH | CHANGELOG v1.0.3; Goratela; BD-201 |
| 10 | MCP stdio shape (`command`/`args`/`env`/`timeout`) inside #9 | PROJECT-TEMPLATE | `command`/`args`/`env` UNCHANGED; top-level `timeout` dropped; remote uses `serverUrl` | Keep the `local-rag` stdio block verbatim (`npx -y mcp-local-rag`, `BASE_DIR`/`DB_PATH`/`CACHE_DIR` env). REMOVE the per-server `timeout: 30000`. (local-rag is stdio, so `serverUrl` N/A.) | HIGH | CHANGELOG v1.0.5/v1.0.7; Goratela; project-template/.gemini/settings.json |
| 11 | `project-template/.gemini/.env.example` (`AGENT_CAPABILITIES`) | PROJECT-TEMPLATE | Permissions/settings live in `~/.gemini/antigravity-cli/settings.json` `permissions` block (allow/ask/deny); `.env` capability mirror has no direct Antigravity analog | Decide the Antigravity capability-parity landing: settings.json `permissions` (not shippable) vs a documented example vs dropping the `.env` mirror for Antigravity. Coordinate with the cross-CLI capability-parity design (validate-pack Check). | MED | cli-permissions docs; community permissions examples; validate-pack.py capability check |
| 12 | `agent-run.sh` (`--agent` → Gemini `@agent-name`) | PROJECT-TEMPLATE | `agy` binary; in-session `/agents` panel; dynamic subagents; headless `agy -p`; flags `--sandbox` / `--dangerously-skip-permissions` / `--model` | Teach `agent-run.sh` the `agy` invocation + new flag set. The `@agent-name` translation may no longer map (dynamic subagents) — re-design the launcher's Gemini path. | HIGH (agy/flags) / MED (agent invocation) | README google-antigravity/antigravity-cli; CHANGELOG v1.0.1/v1.0.5/v1.0.6; project-template/GEMINI.md L454 |
| 13 | GEMINI.md "Gemini CLI operating notes" (`/chat save`, `/compress`, `save_memory`, `--approval-mode=plan`) | BOTH | Antigravity slash cmds differ: `/resume`/`/switch`, `/fork`, `/rewind`, `/permissions`, `/model`, `/mcp`, `/skills`, `/agents`, `/tasks`; permission levels `request-review`(default)/`proceed-in-sandbox`/`always-proceed`/`strict` | Rewrite the operating-notes section to Antigravity's slash-command + permission vocabulary. `save_memory`→`~/.gemini/GEMINI.md` still plausible (global context) but re-verify. | HIGH (slash cmds/permissions) | CHANGELOG; antigravitylab slash-commands; cli-permissions docs |
| 14 | Setup/migration docs (`SETUP-NEW`, `SETUP-EXISTING`, `INSTALL-PROCEDURES`, `CLI-PM-SETUP`, `METHODOLOGY`, `MIGRATION-v10-to-v11`) | BOTH | install `curl ... install.sh \| bash` → `~/.local/bin/agy`; `agy plugin import gemini`; PATH + desktop-collision fix | Rewrite Gemini-CLI install/usage sections to `agy`. Add a Gemini→Antigravity client-migration step (`agy plugin import gemini`, non-destructive). | HIGH (install) / MED (migration cmd spelling) | README; inventivehq; pasqualepillitteri; gcli-migration docs |
| 15 | `DEPENDENCIES.md` (Gemini CLI tool dependency) | BOTH | Antigravity CLI (`agy`), Go binary, closed-source, public preview | Update the dependency row: name, install, version posture (churning preview), closed-source note, weekly-quota caveat. | HIGH | README; theregister 2026-05-20; datastudios |
| 16 | `scripts/validate-pack.py` Gemini checks (agent-count parity, `.gemini/settings.json`, skills trinity, capability parity, `.gemini/.env`) | PACK-SELF (validates project tree) | new dir layout (`.agents/skills/`, `mcp_config.json`, agent-model fork) | Rework every Gemini-pinned check to the Antigravity tree shape. Agent-count-parity check assumes 3 symmetric agent dirs — that invariant BREAKS if the agent-model fork (#3) changes the Gemini agent shape. Enumerate ALL encoding surfaces (validators + tests + CI). | HIGH (checks exist) / MED (new shape) | validate-pack.py L357-684, L1123-1178; enumerate-encoding-surfaces rule |
| 17 | `scripts/init-project.sh` `stage_s4_skills()` + `.gemini/` staging | PACK-SELF | `.agents/skills/` workspace path; possibly a plugin install step | Repoint skill staging to `.agents/skills/`; decide if agent roster ships as a plugin (then add an install step). | HIGH (skills path) / MED (plugin staging) | init-project.sh; Goratela; #7 |
| 18 | `scripts/lib/{detect,customization-preserve,migrator-*}.sh`, `compare-agent-trinity.py`, `merge-trinity.py`, `migrate-v10-to-v11.sh` | PACK-SELF | dir-layout-dependent migration/detection logic | Update `.gemini/` path assumptions + agent-trinity comparison (the 3-way agent parity may no longer hold — see #3/#16). | MED | grep of scripts (Gemini refs); #3 |
| 19 | Test fixtures with `.gemini/` + `GEMINI.md` (`test-fixtures/v11-*`, `scripts/tests/fixtures/customization-preserve/*`) | PACK-SELF | new tree shape | Regenerate fixtures to the Antigravity tree; `manifest.txt` regen on v11-surface commits. | HIGH | find output; regenerate-manifest rule |
| 20 | MCP: `project-template/.mcp.json.example` (`_tools` BD-201 forward-looking note) | PROJECT-TEMPLATE | `mcp_config.json` (the BD-201 target) | Resolve the BD-201 forward-looking note → concrete `mcp_config.json` path + migration step. FOLDED INTO BD-221. | HIGH | BD-201; #9/#10 |
| 21 | Worktree / parallel-agent support (none shipped today; BD-217 territory) | BOTH | native subagent worktrees + auto-cleanup + diff-post-back + `request-review` default | Coordinate with BD-217 (researcher recommended folding Antigravity-worktree INTO BD-221). Design defensively vs open worktree bugs (#388/#253). | MED | datacamp; antigravitylab; antigravity-cli #388/#253; RESEARCH-BD-217 |


---

## 2. INSTALL + INVOCATION (Charge item 1)

### 2.1 Install (HIGH confidence — official README)
- **macOS/Linux:** `curl -fsSL https://antigravity.google/cli/install.sh | bash`
- **Windows PowerShell:** `irm https://antigravity.google/cli/install.ps1 | iex`
- **Windows CMD:** `curl -fsSL https://antigravity.google/cli/install.cmd -o install.cmd && install.cmd && del install.cmd`
- **Binary name is `agy`** (NOT `antigravity`). Drops to `~/.local/bin/agy` on Unix; `%LOCALAPPDATA%\Antigravity\` on Windows. The "agy not found" first-run issue is PATH (`~/.local/bin` not on PATH) or a collision with the desktop app's `/usr/bin/antigravity` on Linux (symlink/alias fix). Verify with `agy --version`.
- A Homebrew cask (`brew install --cask antigravity-cli`) is single-sourced/LOW-conf — do not assume it. Canonical download: `antigravity.google/download`.
- [Sources: README `google-antigravity/antigravity-cli`; dev.to arindam hands-on 2026; inventivehq 2026-05-22; pasqualepillitteri 2026. Retrieved 2026-06-15.]

### 2.2 Auth (HIGH confidence)
- Run `agy` → system keyring, falling back to Google Sign-In OAuth. Desktop auto-opens the browser; SSH/remote prints an auth URL to open locally; `/logout` clears credentials. Any Google AI Pro/Ultra/free account works; Code Assist Standard/Enterprise via existing license; enterprise via connecting a GCP project at onboarding. API-key auth via `ANTIGRAVITY_API_KEY` (from Google AI Studio) is reported but SINGLE-SOURCED (LOW) — verify before CI wiring.
- [Sources: README Authentication section; inventivehq; pasqualepillitteri. Retrieved 2026-06-15.]

### 2.3 The agent + SUBAGENT model (MED/LOW on custom-agent contract — THE structural fork)
- **Main agent + dynamic subagents.** The main `agy` agent reasons across the project, edits multiple files, calls tools, and **spawns subagents on demand** for parallel background work (docs lookup, builds, validation). Subagents run **asynchronously** without blocking the prompt. `/agents` opens the subagent panel (status: running/done/killed + current step).
- **Key delta vs Gemini CLI:** Gemini required **upfront `.gemini/agents/*.md` markdown files**; Antigravity **needs no upfront markdown agent files** — subagents are instantiated dynamically. This abolishes the pack's loose-per-agent-file convention.
- **Custom NAMED agents ARE possible — but only inside a PLUGIN bundle.** A plugin (`~/.gemini/antigravity-cli/plugins/<name>/` or installed via `agy plugin install`) may contain an `agents/` directory of "subagent definition templates." A subagent stored form is reported as `~/.gemini/antigravity-cli/agents/<name>/agent.json` with fields `name`, `description`, `hidden`, `config` (JSON, not `.md`+YAML). The EXACT custom-agent authoring contract is the least-settled load-bearing detail — there is an OPEN official discussion **gemini-cli #27305 "What's the Subagent format for antigravity-cli?"**. RE-VERIFY at design time against `antigravity.google/docs/subagents` + `/docs/cli-plugins`.
- **Permission/orchestration lever (relevant to agents-never-commit):** "the main agent decides what tools/permissions subagents get, including whether they can write files / use MCP tools." If a subagent hits a tool call needing confirmation, it bubbles up to the subagent panel for approval. This is a clean lever for a "subagent cannot commit; orchestrator applies" posture.
- [Sources: Galloro migration guide (Medium google-cloud, 2026-06); DataCamp parallel-agents tutorial (JS-gated — see NEEDS-PLAYWRIGHT); agentpedia deep-dive; antigravity-awesome-skills plugins.md; gemini-cli #27305. Retrieved 2026-06-15.]

### 2.4 Command + skill invocation (MED confidence)
- **Slash commands** exist only inside a running `agy` TUI session (not on the shell wrapper). Inventory: `/resume`(`/switch`), `/rewind`(`/undo`), `/rename`, `/clear`, `/fork`, `/reset`, `/new`, `/config`, `/settings`, `/permissions`, `/model`, `/keybindings`, `/statusline`, `/tasks`, `/skills`, `/mcp`, `/open`, `/add-dir`, `/usage`, `/quota`, `/credits`, `/logout`, `/agents`, `/diff`, `/hooks`, `/changelog`, `/btw`, `/grill-me`.
- **Custom slash commands** come from **skills** (a skill registers a `/name` command — e.g. a `SKILL.md` becomes `/lint`) or from **plugins**, NOT from loose project `.toml` files (Gemini's custom-command format is dropped). NOTE the addyosmani guide's caveat: name a custom planning command `/planning` not `/plan` (collides with Antigravity's internal plan-generation).
- **Skills** are auto-discovered from `skills/` dirs (plugin or workspace `.agents/skills/`); the agent matches user intent to a skill's trigger description and (per addyosmani) prompts for permission before executing. There is NO `gemini skills`-equivalent terminal management command yet (author by hand or `npx skills install`).
- [Sources: antigravitylab slash-commands first-look; CHANGELOG v1.0.x (slash-cmd additions); addyosmani agent-skills setup; agentpedia deep-dive. Retrieved 2026-06-15.]

---

## 3. CONFIG LAYOUT (Charge item 2 — RESOLVE the path disagreement)

### 3.1 The definitive home layout (HIGH confidence — Goratela day-1 hands-on, confirmed via `/skills`, + CHANGELOG path-fix entries)

The Antigravity suite KEPT the `~/.gemini/` home directory from Gemini CLI. Its modern sub-layout (verbatim from the Goratela hands-on, corroborated by CHANGELOG fixes):

```
~/.gemini/
├── antigravity/            # (suite dir)
├── config/                 # SHARED across all Antigravity surfaces (CLI + IDE + 2.0)
│   ├── plugins/            #   shared/global plugins ("extensions" renamed)
│   ├── projects/           #   approved project folders
│   ├── mcp_config.json     #   SHARED MCP config  ← BD-201 target (global)
│   └── hooks.json          #   SHARED hooks (CHANGELOG v1.0.8 moved it here)
├── antigravity-cli/        # CLI-SPECIFIC state
│   ├── settings.json       #   CLI settings + permissions (auto-written; DO NOT SHIP)
│   ├── cache/              #   incl. projects.json, changelog cache (CHANGELOG v1.0.4/v1.0.5)
│   ├── mcp/               #   dynamically generated from the shared MCP config
│   ├── skills/            #   CLI-only ("global to all workspaces, CLI only") skills
│   └── plugins/           #   CLI-installed plugins (agy plugin install)
├── antigravity-ide/        # IDE-specific (mcp/, plugins symlinked, installation_id)
├── skills/                 # SHARED skills across ALL Antigravity tools
│   └── <skill_name>/SKILL.md
└── GEMINI.md               # global context (still honored)
```

### 3.2 RESOLUTION of `~/.gemini/antigravity-cli/` vs `~/.config/antigravity/` (the BD-217 disagreement)
- **`~/.gemini/...` WINS as the agent config-of-record.** It is where MCP, skills, agents, plugins, hooks, permissions, and global context all live. The BD-217 survey's `~/.gemini/antigravity-cli/` candidate was directionally correct for CLI-specific state (settings.json, cache, CLI-only skills/plugins).
- **`~/.config/Antigravity/` (capital A) is the DESKTOP-APP install root on Linux**, holding the executable wrapper `agy-node` — it is an INSTALL/PATH location, NOT a config-of-record. The community `~/.config/antigravity/config.toml` claim conflated the desktop installer path with agent config; no MCP/skills/agents config lives there. CONFIRMED by antigravity-cli issue **#354** ("Installer violates XDG spec by placing executables in `~/.config/Antigravity/bin/`", OPEN) and the README install paths.
- **Architect directive:** convert AGAINST `~/.gemini/` (global) + project-root `.agents/` (workspace). Do NOT design any path under `~/.config/antigravity/`.
- [Sources: Goratela 2026-05-24; CHANGELOG v1.0.2/v1.0.3/v1.0.4/v1.0.8; antigravity-cli #354. Retrieved 2026-06-15.]

### 3.3 Per-project (workspace) config (HIGH/MED)
- **Workspace context files:** `GEMINI.md` + `AGENTS.md` at the project root are read (and `~/.gemini/GEMINI.md` global). `.antigravity.md` reportedly takes precedence over `GEMINI.md` (LOW — single-sourced; do not chase).
- **Workspace skills:** `.agents/skills/<name>/SKILL.md` (the MODERN workspace path). Old `.gemini/skills/` is read by some flows but must be relocated to `.agents/skills/` for reliable pickup.
- **Workspace MCP:** `.agents/mcp_config.json` at the project root (project-scoped). NOTE: the OLDER project-local path `.antigravitycli/mcp_config.json` is **read-but-silently-ignored** (only HOME-level loads) per OPEN issue **#60** — so do NOT target `.antigravitycli/`.
- **`agy inspect`** shows which config files were loaded (`.agents/`, `AGENTS.md`, project instructions) — useful as a validation hook.
- [Sources: agentpedia AGENTS.md guide; addyosmani; arm learning path; antigravity-cli #60; agentpedia deep-dive. Retrieved 2026-06-15.]

### 3.4 settings.json shape (MED — community-confirmed, churning)
- Minimal auto-written shape includes `colorScheme`, `trustedWorkspaces` (array). A structured `permissions` block (allow/ask/deny lists) and `toolPermission` mode live here. Writing arbitrary unknown keys was reported to be silently wiped in early versions; CHANGELOG v1.0.7 fixed "Preserved unknown fields in settings.json during read/write/merge." The CLI inherits `use_ai_credits` from global user settings on startup (v1.0.8).
- **Pack posture:** the pack must NOT ship/auto-write settings.json (Antigravity owns it); this matches the existing "no settings file shipped" hard constraint.
- [Sources: antigravity-cli #352 (user shows the minimal settings.json); CHANGELOG v1.0.7/v1.0.8; cli-permissions community examples. Retrieved 2026-06-15.]

---

## 4. MCP CONFIG (Charge item 3 — the BD-201 piece)

### 4.1 Path (HIGH confidence)
- **Global/shared:** `~/.gemini/config/mcp_config.json` — the single shared MCP config for CLI + IDE + 2.0. (CHANGELOG v1.0.3 explicitly fixed a TUI bug that wrote to "the legacy `mcp_config.json` path instead of the migrated `config/mcp_config.json` path"; CHANGELOG v1.0.2 moved plugin install to the shared `~/.gemini/config/` dir. These primary-source fixes CONFIRM `config/mcp_config.json` as canonical.)
- **Per-workspace:** `.agents/mcp_config.json` at the project root.
- **AVOID:** the older `.antigravitycli/mcp_config.json` (read-but-ignored — issue #60) and bare `~/.gemini/antigravity-cli/mcp_config.json` (an earlier/legacy path the CLI was migrating away from per the v1.0.3 fix; some sources still cite it for global, but `~/.gemini/config/mcp_config.json` is the converged shared location).
- [Sources: CHANGELOG v1.0.2/v1.0.3; Goratela 2026-05-24; codelabs google-workspace-mcp-antigravity; antigravity-cli #60. Retrieved 2026-06-15.]

### 4.2 Block shape (HIGH confidence — stdio UNCHANGED)
- Top-level `mcpServers` object, one key per server. **stdio shape is UNCHANGED from Gemini:** `command`, `args`, `env`. Confirms BD-201's "stdio command/args/env shape is unchanged."
- **Deltas:** (1) top-level per-server `timeout` is NO LONGER supported (a configurable global launch timeout exists per CHANGELOG v1.0.7; `-1` disables it); (2) inline JSON comments not supported; (3) `disabled: true` per-server flag is supported; (4) remote/HTTP servers use **`serverUrl`** (+ `headers`, `authProviderType`, `oauth`). NOTE the nuance: CHANGELOG v1.0.5 "Added support for `url` in mcp_config.json to configure MCP servers directly via a URL" — so `url` IS accepted, but the converged/auth-bearing remote shape across the suite is `serverUrl` (the migration "silent failure" trap several community guides flag: remote servers left as `url` fail silently at tool-invocation time in some flows). The pack's `local-rag` server is STDIO, so `serverUrl`/`url` is N/A for it.
- **Example (Goratela's working config, abridged):**
```json
{ "mcpServers": {
    "gcloud": { "command": "npx", "args": ["-y", "@google-cloud/gcloud-mcp"] },
    "remote-github": { "serverUrl": "https://api.githubcopilot.com/mcp/",
      "headers": { "Authorization": "Bearer <key>", "Content-Type": "application/json" } } } }
```
- **Pack conversion for the shipped `local-rag` block:** keep `command: "npx"`, `args: ["-y","mcp-local-rag"]`, the `env` block (`BASE_DIR`/`DB_PATH`/`CACHE_DIR`) verbatim; REMOVE `timeout: 30000`; relocate from `settings.json` to an `mcp_config.json` example (global `~/.gemini/config/mcp_config.json` and/or workspace `.agents/mcp_config.json`). Update the `DB_PATH`/`CACHE_DIR` defaults if the pack wants them under `.agents/` rather than `.gemini/`.
- **Known MCP bugs (design caveats):** env-var passthrough reportedly broken for some users (Goratela had to hard-code API keys — re-verify); incomplete MCP tool schema serialization (#368/#369); `agy` clears `mcp_oauth_tokens.json` on every WSL launch (#348).
- [Sources: Goratela 2026-05-24; CHANGELOG v1.0.5/v1.0.7; inventivehq (serverUrl trap); antigravity-cli #60/#348/#368/#369; project-template/.gemini/settings.json. Retrieved 2026-06-15.]


---

## 5. THE OFFICIAL GEMINI → ANTIGRAVITY MIGRATION (Charge item 4)

### 5.1 Timeline (HIGH — official blog/discussion)
- **2026-05-19 (Google I/O):** Antigravity CLI announced + available to everyone; Gemini CLI transition announced.
- **Phase 1 (now → ~Mar 2026 framing in community guides; the blog's "starting today"):** Antigravity CLI public preview; Gemini CLI keeps working.
- **Phase 2 (Apr → Jun 17, 2026):** Gemini CLI in maintenance mode (community framing).
- **2026-06-18 (HARD CUTOVER):** Gemini CLI + Gemini Code Assist IDE extensions STOP serving requests for Google AI Pro, Ultra, and free Gemini Code Assist for individuals. Gemini Code Assist for GitHub: no new org installs on 06-18, requests stop in following weeks. **Enterprise EXEMPT:** orgs with Gemini Code Assist Standard/Enterprise licenses (or Code Assist for GitHub via Google Cloud) keep unchanged access; Gemini CLI remains via paid Gemini / Gemini Enterprise Agent Platform API keys.
- [Sources: Google Developers Blog "An important update: Transitioning Gemini CLI to Antigravity CLI" 2026-05-19 (read in full); gemini-cli discussion #27274; theregister 2026-05-20. Retrieved 2026-06-15.]

### 5.2 What's preserved vs what changes (HIGH on the four feature families; MED on the migration mechanics)
- **Google states these carry over (NOT 1:1 parity "right out of the gate"):** Agent **Skills**, **Hooks** (same JSON format + lifecycle), **Subagents** (now run async in background), **Extensions → renamed plugins** (the industry standardized on "plugin").
- **The migration command:** **`agy plugin import gemini`** (non-destructive — leaves `~/.gemini/` intact; reversible until 06-18). Multiple sources + the binary naming + the addyosmani guide + official-docs references converge on this. A MINORITY/LOW source claims `antigravity migrate --from-gemini-cli` — treat as unconfirmed; RE-VERIFY against `antigravity.google/docs/gcli-migration`. Independently, **first launch auto-detects `~/.gemini/`** and PROMPTS to import MCP servers, allowed-command list, keybindings, theme into the new locations — so a manual command may not even be needed.
- **The FOUR breaking behaviors** (community-flagged, MED-conf — verify against official docs; they catch mechanical renames):
  1. **Default model** changed (Gemini CLI default → Antigravity default is a Gemini-3-class model; pin with `--model` if tuned to an old one).
  2. **`--stream` format** → SSE events by default (Gemini emitted plain deltas); add a plain-format flag to keep pipes working.
  3. **Agent state dir** moved (`~/.gemini/agents/` → an Antigravity state dir; first run auto-migrates; `--state-dir` overrides may break). [NOTE: community guides cite `~/.antigravity/` for state; the Goratela primary-source layout shows CLI state under `~/.gemini/antigravity-cli/` — the two community claims CONFLICT; re-verify.]
  4. **Exit codes** non-zero on tool-use failures (Gemini exited 0).
- **Other migration gotchas:** CI/cron calling `gemini` is NOT auto-migrated (hand-edit to `agy`); `gemini --acp` (ACP stdio) reportedly absent at launch; model IDs may have changed (don't hardcode); some extensions relying on internal Node APIs need a Go rewrite or the MCP bridge.
- [Sources: Google Developers Blog 2026-05-19; inventivehq 2026-05-22; digitalapplied; harshrastogi; addyosmani agent-skills; gcli-migration docs (JS-gated — see NEEDS-PLAYWRIGHT). Retrieved 2026-06-15.]

### 5.3 Automated migration tooling Google provides
- The non-destructive `agy plugin import gemini` + the first-launch import prompt ARE the official tooling. There is no separate standalone migrator binary reported. `agy inspect` / `agy config --edit` verify the imported state.
- **Pack implication:** the pack's CLIENT migration story (a v10/v11 project that has `.gemini/` agents/skills/commands) should document `agy plugin import gemini` (or the first-launch prompt) AND the pack-specific moves the import won't do (relocate workspace skills `.gemini/skills/` → `.agents/skills/`; convert the 16 agent files per the §0 fork; drop the `.toml` commands). The import is for the USER's personal `~/.gemini/`; the pack's project-tree conversion is a SEPARATE, pack-authored migration step.

---

## 6. FEATURE / API PARITY vs GEMINI — per pack surface (Charge item 5)

| Pack Gemini capability | Antigravity parity | Status flag |
|---|---|---|
| Trinity `GEMINI.md` context file | YES — read as backward-compat; AGENTS.md also read | STABLE-now |
| Per-agent `.gemini/agents/*.md` (16, YAML frontmatter, `model`/`temperature`/`max_turns`) | NO direct equivalent — dynamic subagents + plugin-bundled `agent.json` (JSON, different fields) | NOT-AT-PARITY (structural fork; authoring contract PREVIEW/unsettled — #27305) |
| `.gemini/commands/*.toml` custom commands | NO — slash commands via skills/plugins | NOT-AT-PARITY (format dropped) |
| `.gemini/skills/<name>/SKILL.md` | YES — same Agent Skills SKILL.md standard; location → `.agents/skills/` (workspace) / `~/.gemini/skills/` (shared) | STABLE-now (content) / path-changed |
| MCP via settings.json `mcpServers` | YES — relocated to `mcp_config.json`; stdio shape unchanged | STABLE-now (with the 3 deltas in §4.2) |
| Sandbox / approval modes (`--approval-mode=plan`, per-command approval) | YES, RICHER — `permissions` allow/ask/deny (Deny>Ask>Allow), levels `request-review`(default)/`proceed-in-sandbox`/`always-proceed`/`strict`, `--sandbox`, `--dangerously-skip-permissions`, `proceed-in-sandbox` | STABLE-now (vocabulary changed) |
| `agent-run.sh` `@agent-name` invocation | PARTIAL — `/agents` panel + dynamic subagents; @-mention typeahead exists but maps differently | NOT-AT-PARITY (launcher re-design) |
| Cross-session memory `save_memory` → `~/.gemini/GEMINI.md` | LIKELY (global context still `~/.gemini/GEMINI.md`) — verify the exact verb | FORWARD-LOOKING (verify) |
| Session save/resume (`/chat save`, `/chat resume`) | YES, different verbs — `/resume`, `/switch`, `/fork`, `/rewind`; SQLite conversation store (`.db`) | STABLE-now (verbs changed) |
| Hooks | YES — same JSON format/lifecycle; `~/.gemini/config/hooks.json` (shared) | STABLE-now (path settled v1.0.8) |
| Worktree / parallel agents (not shipped; BD-217) | YES native (subagent worktrees + auto-cleanup + diff-post-back + `request-review` default) but BUGGY | PREVIEW + OPEN-BUGS (#388/#253) |
| ACP stdio (`gemini --acp`) | Reportedly ABSENT at launch | NOT-AT-PARITY (preview gap) |
| Telemetry/OTLP token export | Feature-request OPEN (#366) | NOT-AT-PARITY |
| Open-source / inspectable source | NO — Antigravity CLI is closed-source (Gemini CLI was Apache-2.0) | CHANGED (governance/dependency note) |

---

## 7. COMMUNITY SIGNAL — reviews, tips, known issues, gotchas (Charge item 6, user-directed)

### 7.1 Confirmed open bugs / data-safety hazards (HIGH — official issue tracker `google-antigravity/antigravity-cli`, retrieved 2026-06-15)
- **#388 (OPEN, 2026-06-14) "Deleting Conversation Deletes entire worktree."** Deleting a conversation WIPED the entire worktree folder including untracked `.env`/configs — UNRECOVERABLE. **This is the BD-197/BD-217 "agents-never-commit / no destructive surprises" nightmare confirmed in Antigravity.** Any worktree-isolation design must treat conversation-delete as destructive and never expose it to an agent.
- **#253 (OPEN) / #68 (CLOSED) "Agy has no reference of the project workspace if launched from a git worktree"** — when `agy` is started from inside a worktree it can't find AGENTS.md/CLAUDE.md and reports "no active workspace." Directly impacts any "spawn agent INTO a worktree" pattern (BD-217). `--add-dir` did not help (#253).
- **#184 (OPEN) "Sub-agents do not use AI credits and hit quota limits"** — parallel subagents each consume independent token budget; quota exhaustion is a real parallel-execution limiter.
- **#60 (OPEN) project-local `.antigravitycli/mcp_config.json` read-but-ignored** — only HOME-level MCP loads (some versions). Use `.agents/mcp_config.json`.
- **#354 (OPEN) installer XDG violation** (executables in `~/.config/Antigravity/bin/`) — the source of the `~/.config/antigravity` confusion.
- **#352 (OPEN)** user asking "Is there a settings.json like Gemini?" + report that writing extra keys deletes them (pre-v1.0.7 fix).
- **#351 (OPEN)** child-of-child subagents invisible in CLI/IDE.
- **CPU/crash bugs:** #347/#359/#373/#378 SIGILL on non-AES-NI / older CPUs; #363 SIGSEGV in markdown renderer; #350 Windows Job Object kills spawned GUI processes on CLI exit; #355 WMClass collision CLI vs IDE; #348 `agy` clears `mcp_oauth_tokens.json` every WSL launch.
- **Permission/diff UX requests (relevant to review-before-apply):** #380 / #362 "Ask permission and SEE the diff before the agent edits" (like Gemini CLI) — i.e. the diff-before-apply UX is requested/imperfect; the `request-review` permission level is the closest current lever.
- [Source: `github.com/google-antigravity/antigravity-cli/issues`, individual issue bodies fetched via the GitHub API, retrieved 2026-06-15.]

### 7.2 Quota / stability complaints (HIGH — official forum + support + issues)
- The official forum is "filling with quota, stability, and update bugs" (Epium roundup). Specific: Pro quota showing a "99-hour weekly reset instead of 5-hour cycle"; models locked 74h instead of the promised 5h; `429 RESOURCE_EXHAUSTED` on long tasks; #387 quota endpoint always returns 100% despite exhaustion; #393 "QUOTA finished after 3 days." The quota model changed from Gemini's ~1,000 req/day to a **weekly compute-based cap** that multiple users report exhausting in a couple of requests. **Pack implication:** any parallel-subagent / worktree workflow the pack documents must warn about weekly-quota exhaustion (subagents consume independent budget — #184).
- [Sources: Epium "Google Antigravity forum fills with quota/stability/update bugs"; support.google.com gemini thread 435891951; antigravity-cli #184/#386/#387/#393. Retrieved 2026-06-15.]

### 7.3 Tips / tricks (MED — community guides)
- **The two install gotchas:** `~/.local/bin` on PATH; the desktop-app `/usr/bin/antigravity` collision on Linux (symlink `agy`).
- **The `serverUrl` MCP trap:** remote MCP servers must use `serverUrl` (not `url`/`httpUrl`) or fail silently at tool-invocation time — rename proactively.
- **`/grill-me`** aligns on a plan before execution (a planning-mode analog); name custom planning commands `/planning` not `/plan`.
- **`agy inspect`** to see loaded config; **`agy plugin list/validate`** to verify plugins.
- **Worktree-per-agent pattern** (antigravitylab, 2026-06-13) is the same `git worktree add` pattern BD-197/BD-217 use — community has already hit the parallel-agents-share-one-index data-loss class and recommends worktree isolation.
- [Sources: inventivehq; pasqualepillitteri; antigravitylab worktree-parallel article; addyosmani. Retrieved 2026-06-15.]

---

## 8. PREVIEW-vs-GA + STABILITY (Charge item 7 — `verify-availability-not-just-existence`)

### 8.1 Availability matrix (each cell cited)
| Axis | Status | Usable on the pack's target (personal Google account)? | Citation |
|---|---|---|---|
| Tool availability | PUBLIC PREVIEW, "available to everyone today" (2026-05-19) | YES | Google Dev Blog 2026-05-19; README |
| Cost / plan gate | FREE for individuals during preview; no credit card; weekly compute quota; enterprise via GCP/Code-Assist license | YES (free tier) | datastudios; theregister; datacamp |
| Source availability | CLOSED-SOURCE (no OSS release planned); Gemini CLI was Apache-2.0 | N/A (governance note) | inventivehq; theregister |
| Strict-commercial GA | NOT declared GA; "public preview" labeling | YES to USE; NO if user requires non-preview | Google Dev Blog; datastudios |
| Config paths (`~/.gemini/config/mcp_config.json`, `.agents/`, `~/.gemini/antigravity-cli/settings.json`) | CONVERGED across recent releases (CHANGELOG path-fixes 1.0.2→1.0.8) | YES — stable-enough-to-ship | CHANGELOG; Goratela |
| Subagent/custom-agent authoring contract | UNSETTLED (open discussion #27305; JSON `agent.json` vs plugin templates) | PARTIAL — design FORWARD-LOOKING | gemini-cli #27305; antigravity-awesome-skills |
| Worktree isolation | NATIVE but OPEN data-safety bugs | USE WITH DEFENSES (or degrade) | antigravity-cli #388/#253 |
| Model IDs / quota | CHURNING; buggy weekly quota | DO NOT hard-code | inventivehq; Epium; #387 |

### 8.2 Stable-now vs forward-looking (architect directive)
- **STABLE-now (safe to ship in v11.0):** the `agy` binary + install/auth; `GEMINI.md`/`AGENTS.md` context files; the `~/.gemini/config/mcp_config.json` + `.agents/mcp_config.json` MCP paths + stdio shape; the `SKILL.md` Agent-Skills standard; the `.agents/skills/` workspace path; the `permissions` allow/ask/deny model + `request-review` default; hooks at `~/.gemini/config/hooks.json`; the `agy plugin import gemini` migration direction (verify spelling).
- **FORWARD-LOOKING (design tolerantly; do not hard-code; re-verify at design/impl):** the exact custom-agent authoring contract (#27305); model IDs; quota numbers; the worktree-isolation reliability (bug-fix status of #388/#253); the `.antigravity.md` precedence claim; the `ANTIGRAVITY_API_KEY` var; the four "breaking behaviors" exact spellings (esp. the state-dir path conflict ~/.antigravity vs ~/.gemini/antigravity-cli); env-var passthrough in MCP.
- **Process guard:** because the product churns weekly, the architect's design should reference paths/contracts by their CONFIRMED form here and add an explicit "re-verify at impl" note for each FORWARD-LOOKING item — and the impl should pin against a specific `agy --version` observed at build time, not assume forward-stability.


---

## NEEDS-PLAYWRIGHT-CAPTURE

The official Antigravity docs site (`antigravity.google/docs/*`) is a JS-rendered SPA: every page returns HTTP 200 with only a ~4 KB shell and NO server-rendered body content via curl. Several load-bearing details are PRIMARY-only on these pages and should be captured with Playwright to firm up the MED/LOW-confidence items above BEFORE the architect commits to the agent-model fork and the migration mechanics. For each: the URL + the SPECIFIC information needed.

1. **`https://antigravity.google/docs/gcli-migration`** — the OFFICIAL migration guide. NEEDED: (a) the exact migration command (`agy plugin import gemini` vs `antigravity migrate --from-gemini-cli` — sources conflict); (b) the authoritative old→new path mapping table (settles the state-dir conflict `~/.antigravity/` vs `~/.gemini/antigravity-cli/`); (c) the exact list of the "four breaking behaviors."
2. **`https://antigravity.google/docs/subagents`** — NEEDED: the AUTHORITATIVE custom-subagent authoring contract (file format — `agent.json` JSON vs markdown; where it lives; required fields; whether loose project agents are supported at all). This is the §0 top conversion risk; #27305 is open precisely because this is under-documented. Resolves conversion-map rows #3/#4.
3. **`https://antigravity.google/docs/cli-plugins`** — NEEDED: the `plugin.json` manifest schema (which of `skills`/`agents`/`rules`/`mcp_config.json`/`hooks.json` fields are required/optional; how `agents/` templates are declared), to decide whether the pack ships its roster as a plugin (conversion rows #3/#5/#17).
4. **`https://antigravity.google/docs/cli-permissions`** — NEEDED: the authoritative `permissions` schema + the exact tool-permission level names/defaults + how to deny commit/git verbs (the agents-never-commit lever for BD-217). Confirms conversion row #11/#13.
5. **`https://antigravity.google/docs/cli-features`** and **`/docs/cli-overview`** and **`/docs/cli-using`** — NEEDED: the authoritative slash-command list, the worktree feature description (`New Worktree`, auto-cleanup, diff-post-back), and the `agy` subcommand list (`inspect`, `config`, `plugin`, `models`, `changelog`). Firms up rows #12/#21.
6. **`https://antigravity.google/docs/mcp`** — NEEDED: authoritative confirmation of `~/.gemini/config/mcp_config.json` as the canonical global path + the `serverUrl`-vs-`url` rule + the dropped-`timeout` rule (row #9/#10/§4).
7. **`https://www.datacamp.com/tutorial/antigravity-cli`** — Cloudflare/JS-gated (returned "Enable JavaScript"). NEEDED: the parallel-subagents + worktree-isolation + permissions walkthrough (corroborates rows #3/#21 with concrete commands).

(All other sources cited in this report WERE successfully read with available tools — official GitHub repo README + CHANGELOG + issue API, the Google Developers Blog post, and the server-rendered community deep-dives. The Playwright list is strictly the JS-gated primary docs + DataCamp.)

---

## SOURCES (all retrieved 2026-06-15)

**Primary (official):**
- Google Developers Blog — "An important update: Transitioning Gemini CLI to Antigravity CLI" (2026-05-19): https://developers.googleblog.com/an-important-update-transitioning-gemini-cli-to-antigravity-cli/ (read in full)
- `google-antigravity/antigravity-cli` README: https://raw.githubusercontent.com/google-antigravity/antigravity-cli/main/README.md (read in full)
- `google-antigravity/antigravity-cli` CHANGELOG (v1.0.1–v1.0.8): https://raw.githubusercontent.com/google-antigravity/antigravity-cli/main/CHANGELOG.md (read in full)
- `google-antigravity/antigravity-cli` issues (via GitHub API): #388, #354, #352, #253, #184, #68, #60, plus the open-issue list — https://github.com/google-antigravity/antigravity-cli/issues
- gemini-cli discussion #27274 (official transition announcement) + #27305 ("What's the Subagent format for antigravity-cli?"): https://github.com/google-gemini/gemini-cli/discussions/27274
- Official docs (JS-gated — see NEEDS-PLAYWRIGHT): antigravity.google/docs/{gcli-migration, subagents, cli-plugins, cli-permissions, cli-features, cli-overview, cli-using, mcp}

**Strong community / corroborating:**
- Deven Goratela (Google Cloud Community) — "Configuring MCP Servers and Skills for Antigravity CLI and IDE" (2026-05-24, day-1 hands-on, confirmed via `/skills`): https://devengoratela.com/2026/05/configuring-mcp-servers-and-skills-for-antigravity-cli-and-ide/ (read in full)
- inventivehq — "Antigravity CLI: Install, First Run, and Migrating Your Gemini CLI Config" (2026-05-22, confidence-flagged): https://inventivehq.com/blog/antigravity-cli-install-migrate-config (read in full)
- Pasquale Pillitteri — "Antigravity CLI (agy): Install, Migrate from Gemini CLI..." (2026): https://pasqualepillitteri.it/en/news/3422/antigravity-cli-agy-install-migrate-gemini-cli
- DEV (arindam) — "Antigravity CLI: A Hands-On Guide": https://dev.to/arindam_1729/antigravity-cli-a-hands-on-guide-to-googles-terminal-coding-agent-5bc7 (read in full)
- addyosmani/agent-skills — Antigravity setup doc (plugin install/import, slash commands, `.agents/skills/`): https://raw.githubusercontent.com/addyosmani/agent-skills/main/docs/antigravity-setup.md (read in full)
- agentpedia.codes — "Antigravity CLI Deep Dive" + AGENTS.md guide: https://agentpedia.codes/blog/antigravity-cli-deep-dive
- antigravitylab.net — "Running Multiple Agents on One Repo Breaks It — Isolating Work Areas with Worktrees" (2026-06-13) + slash-commands first-look: https://antigravitylab.net/en/articles/agents/antigravity-worktree-parallel-agent-isolation-design
- Giovanni Galloro (Google Cloud Community) — "Migrating to Antigravity CLI": https://medium.com/google-cloud/migrating-to-antigravity-cli-a841c6964f37
- Epium — "Google Antigravity forum fills with quota, stability, and update bugs": https://epium.com/news/google-antigravity-forum-quota-stability-update-bugs/
- The Register — "Bye-bye, Gemini CLI; Google nudges devs toward Antigravity" (2026-05-20): https://www.theregister.com/ai-ml/2026/05/20/bye-bye-gemini-cli-google-nudges-devs-toward-antigravity/
- datastudios.org — Antigravity free access / Gemini 3 trials / limits: https://www.datastudios.org/post/google-antigravity-free-access-and-gemini-3-trials-availability-limits-and-what-users-can-access
- dev.to (volodymyr_nehir) — "How to Build Custom Skills for Antigravity Using Agent Skills Standard": https://dev.to/volodymyr_nehir/how-to-build-custom-skills-for-antigravity-using-agent-skills-standard-4ab9
- sickn33/antigravity-awesome-skills — plugins.md (plugin bundle structure): https://github.com/sickn33/antigravity-awesome-skills/blob/main/docs/users/plugins.md
- DataCamp — "Google Antigravity CLI: Orchestrating Parallel AI Agents" (JS-gated): https://www.datacamp.com/tutorial/antigravity-cli

**Pack-internal (read at HEAD `e5a366f`):** `backlog/BD-221.md`, `backlog/BD-201.md`, `backlog/BD-217.md`, `maintenance-docs/v11-implementation/RESEARCH-BD-217-WORKTREE-ISOLATION.md`, `project-template/GEMINI.md`, `project-template/.gemini/{settings.json,.env.example,agents/coder.md,commands/pm-startup.toml}`, pack-root `GEMINI.md` + `.gemini/`, `scripts/validate-pack.py`, `CLAUDE.md` § Pack memory, memory `feedback_verify_availability_not_just_existence.md` + `feedback_external_rules_census_before_design.md`.

---

## Rules-Applied Verification Block

| # | Rule (as named in prompt) | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | verify-availability-not-just-existence [researcher] | §8.1 availability matrix gives a per-axis GA/preview/free/closed-source/usable-on-personal-account cell with a citation each; Antigravity flagged "PUBLIC PREVIEW, free for individuals, closed-source, no org gate, NOT strict-GA"; §8.2 splits STABLE-now vs FORWARD-LOOKING; custom-agent contract + worktree + model IDs explicitly excluded from stable-now as "design tolerantly, re-verify." Every availability claim carries a URL + 2026-06-15 date. | COMPLIANT |
| 2 | external-rules-census-before-design [researcher] | §3 enumerates the COMPLETE config-dir layout (verbatim tree); §4 the complete MCP rule set (path, block shape, 3 deltas: dropped timeout / no inline comments / serverUrl vs url); §5 the migration timeline + four breaking behaviors + preserved-feature set; §6 a per-surface parity table; §7 the COMPLETE open-bug/limit census from the official issue tracker (#388/#354/#352/#253/#184/#68/#60/#351/#347/#359/#373/#378/#363/#350/#355/#348/#380/#362/#387/#393/#366/#368/#369), each cited; conflicts (migration cmd, state-dir path, serverUrl/url) recorded as DOCUMENTED-CONFLICT not invented. | COMPLIANT |
| 3 | prompts-grounded-in-facts [universal] | Every capability claim tied to a cited source + date; inference flagged ("researcher recommendation", "LOW-conf", "single-sourced", "re-verify at design", "CONFLICT"); no invented Antigravity behavior — the under-documented custom-agent contract is stated as UNSETTLED (#27305) rather than guessed; confidence legend (HIGH/MED/LOW) applied per conversion-map row. | COMPLIANT |
| 4 | pack-project-separation-of-concerns [researcher] | §0 "PACK-vs-PROJECT SEPARATION" paragraph names the two artifact families; the §1 conversion map tags each row PACK-SELF / PROJECT-TEMPLATE / BOTH (rows #1 vs #2, #3 vs #4, #5 vs #6, #7 vs #8 are the paired separate artifacts); never treats a pack-self surface as a fallback for the project surface. | COMPLIANT |
| 5 | scope-deliverables-to-the-ask [universal] | Report covers exactly the 8 charge items (install/invocation, config-dir resolution, MCP/BD-201, official migration, parity, community signal, preview-vs-GA, surface-by-surface map) + NEEDS-PLAYWRIGHT + sources; no unrelated tangents (no Claude/Codex redesign, no BD-197 mechanism redesign — worktree limited to the BD-217-coordination relevance the charge names). | COMPLIANT |
| 6 | agents-never-commit [universal] | Only git verbs run: `git rev-parse HEAD` + `git branch --show-current` (read-only) + the read-only grep/find/curl research. No add/commit/push/stash/checkout/merge/reset/worktree state-change. Report written via heredoc `cat >>` (file write, not git). Concurrent BD-219/backlog working-tree changes ignored per prompt. | COMPLIANT |
| 7 | rules-applied-verification-block [universal] | This table; every prompt rule has quoted/measured evidence + a non-empty terminal conclusion. | COMPLIANT |

---
*End of RESEARCH-BD-221-ANTIGRAVITY-TRANSITION.md — read-only research pass, HEAD `e5a366f`, 2026-06-15.*
