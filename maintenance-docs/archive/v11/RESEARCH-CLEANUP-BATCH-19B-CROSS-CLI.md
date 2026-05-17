# RESEARCH-CLEANUP-BATCH-19B-CROSS-CLI — Cross-CLI capability matrix for memory + sub-agents + messaging + stop control

- Branch: v11-dev (HEAD `cd8246c` at start of research)
- Author: pack-docs-researcher (Batch 19b cleanup, second-architect-pass input)
- Date retrieved: 2026-05-16
- Scope: R-1 (Codex), R-2 (Gemini), R-3 (cross-CLI parity for L8 SendMessage-defiance incident); plus sanity-check of Claude Code surfaces the first architect pass characterized by assertion.

This report is facts only. No design recommendations. Where a question is unanswerable from authoritative documentation, that is stated explicitly under §7 "Confirmed-absent vs couldn't-find inventory."

---

## Summary

All three CLIs (Claude Code, Codex CLI, Gemini CLI) now ship a sub-agent / specialized-agent mechanism and a hierarchical context-file mechanism (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`). All three also ship a separate "memory" surface that is logically distinct from the context file — but only Claude Code's memory is per-project + auto-loaded into every session as the user's MEMORY.md design assumes. Codex memories are opt-in feature-flagged and not available in EEA / UK / Switzerland at launch. Gemini's "memory" is in-band: the model edits the GEMINI.md hierarchy (or a Gemini-tool-managed extension thereof) rather than maintaining a separate per-project app-level cache. Inter-agent messaging (the SendMessage-equivalent of Claude Code's experimental Agent Teams) is **confirmed absent** in Codex CLI (GitHub issue #12462 closed as enhancement request) and **confirmed absent** in Gemini CLI (subagents are hub-and-spoke: report-back-to-parent only). The L8 SECURITY WARNING mechanism (Claude Code's transcript classifier flagging subagent action histories at handoff) is a Claude-Code-specific platform feature with no documented equivalent in either Codex CLI or Gemini CLI.

### Headline matrix

| Capability | Claude Code | Codex CLI | Gemini CLI |
|---|---|---|---|
| Trinity-file auto-load at session start | YES (CLAUDE.md) | YES (AGENTS.md) | YES (GEMINI.md) |
| App-level per-project memory (separate from trinity file, auto-loads) | YES (`~/.claude/projects/<proj>/memory/MEMORY.md`, on by default) | YES, but FEATURE-FLAGGED OFF + REGIONALLY RESTRICTED (`~/.codex/memories/`, opt-in, not in EEA/UK/CH) | NO separate per-project app-level memory cache — "memory" is the GEMINI.md hierarchy itself |
| MEMORY.md-style index file convention | YES (MEMORY.md is the index) | NO documented index file; Codex generates summary/durable/recent-input files | NO (no separate index — GEMINI.md hierarchy is the surface) |
| Markdown + YAML frontmatter format | YES | NO — Codex memory files are generated state, "treat as opaque"; AGENTS.md is plain markdown | YES for GEMINI.md (Markdown; `@file.md` imports) |
| Sub-agent spawning (parent delegates to typed sub-agent) | YES (Task tool with `subagent_type`) | YES (built-in: `default`, `worker`, `explorer`; custom in `.codex/agents/*.toml`) | YES (built-in: `codebase_investigator`, `cli_help`, `generalist`, `browser_agent`; custom in `.gemini/agents/*.md`) |
| Background / concurrent sub-agent spawn | YES (`background: true` frontmatter; Ctrl+B; or `--agents` JSON; Task tool `background` field) | YES (parallel spawn by default; `agents.max_threads` config caps concurrency, default 6) | YES (parallel spawn by `@` invocation or natural-language request) |
| Inter-agent messaging (peer-to-peer between spawned agents) | YES but EXPERIMENTAL + FLAG-GATED (Agent Teams: SendMessage tool requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, v2.1.32+) | NO — confirmed absent (issue #12462 closed as enhancement); subagents report results to parent only, no peer messaging | NO — confirmed absent in docs; subagents report findings back to the main agent only |
| Parent → spawned sub-agent stop directive (in-band, mid-task) | PARTIAL — `Esc` to interrupt foreground; `Ctrl+F` to kill all background agents; SendMessage with stop-text (when Agent Teams enabled); reliability issues open (issues #34476, #47936) | PARTIAL — `/agent` command + natural-language ("ask Codex directly to stop it, or close completed agent threads"); reliability issues open (issues #19197, #5905, #1215) | PARTIAL — natural-language stop request; `Ctrl+C` known to terminate whole session not just current op (issue #3385); reliability issues (issues #21052, #14043) |
| Subagent-defiance detection (system warning when sub ignores stop) | YES — transcript classifier flags subagent action history at handoff; emits "SECURITY WARNING: This sub-agent performed actions that may violate security policy. Reason: ..." | COULDN'T FIND any documented equivalent | COULDN'T FIND any documented equivalent |

---

## §1 Claude Code matrix

### 1.1 Trinity-file auto-load (CLAUDE.md)
- **Status:** Confirmed-present.
- **Locations + load order** (root→specific): managed policy file (`/Library/Application Support/ClaudeCode/CLAUDE.md` on macOS / `/etc/claude-code/CLAUDE.md` on Linux / `C:\Program Files\ClaudeCode\CLAUDE.md` on Windows); user (`~/.claude/CLAUDE.md`); project (`./CLAUDE.md` or `./.claude/CLAUDE.md`); local (`./CLAUDE.local.md`). Subdirectory CLAUDE.md files load on demand when Claude reads files in those directories.
- **Format:** Plain markdown with `@path/to/file.md` import syntax (recursive up to 5 hops); YAML frontmatter NOT required at top-level; YAML frontmatter IS used in `.claude/rules/*.md` for `paths:` scoping.
- **Auto-load:** Loaded in full at session start (no size cap, but >200 lines reduces adherence).
- **AGENTS.md handling:** Claude Code reads CLAUDE.md, not AGENTS.md. Recommended pattern is `@AGENTS.md` import from CLAUDE.md, or a symlink. (Source: https://code.claude.com/docs/en/memory, retrieved 2026-05-16.)

### 1.2 App-level per-project auto memory
- **Status:** Confirmed-present.
- **Storage location:** `~/.claude/projects/<project>/memory/`, where `<project>` is derived from the git repository (so all worktrees of one repo share a single memory directory). Configurable via `autoMemoryDirectory` in user settings (NOT project/local settings — security mitigation).
- **Index file convention:** `MEMORY.md` is the index. Optional topic files (`debugging.md`, `api-conventions.md`, etc.) live alongside it.
- **Auto-load:** "The first 200 lines of `MEMORY.md`, or the first 25KB, whichever comes first, are loaded at the start of every conversation. Content beyond that threshold is not loaded at session start." Topic files are loaded on demand by Claude using standard file tools.
- **Format:** Plain markdown. The architect's hypothesis "markdown with YAML frontmatter (name, description, metadata.type)" is **NOT confirmed** by the official memory doc — the doc shows MEMORY.md as a free-form concise index. The user's local MEMORY.md format with YAML frontmatter is a pack convention, not a Claude Code requirement.
- **Version requirement:** Auto memory requires Claude Code v2.1.59+ (per `code.claude.com/docs/en/memory`). On by default; `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1` to disable.
- **Machine-local:** Not shared across machines or cloud environments.
- (Source: https://code.claude.com/docs/en/memory.md, retrieved 2026-05-16.)

### 1.3 Sub-agent spawning
- **Status:** Confirmed-present.
- **Mechanism:** Task tool with `subagent_type` parameter. Built-in subagents: `Explore` (Haiku, read-only), `Plan` (read-only, used in plan mode), `general-purpose` (all tools), plus helpers `statusline-setup` and `claude-code-guide`.
- **Custom subagents:** Markdown files with YAML frontmatter; scopes (in priority order): managed settings, `--agents` JSON CLI flag, `.claude/agents/`, `~/.claude/agents/`, plugin `agents/`.
- **Frontmatter fields:** `name`, `description`, `tools`, `disallowedTools`, `model`, `permissionMode`, `mcpServers`, `hooks`, `maxTurns`, `skills`, `initialPrompt`, `memory`, `effort`, `background`, `isolation`, `color`.
- **Memory field:** `memory: user|project|local` gives subagents persistent memory at `~/.claude/agent-memory/<agent>/` (user scope) or `.claude/agent-memory/<agent>/` (project). Introduced in Claude Code v2.1.33 (per search hits) — independent of the project-level auto memory at `~/.claude/projects/<proj>/memory/`.
- (Source: https://code.claude.com/docs/en/sub-agents.md, retrieved 2026-05-16.)

### 1.4 Background / `run_in_background`
- **Status:** Confirmed-present.
- **Mechanism:** Subagent frontmatter `background: true` runs as background task by default. Per-spawn: ask Claude in natural language ("run this in the background") or press `Ctrl+B` to background a running task. The Task tool also accepts a `background` field.
- **Behavior:** "Background subagents run concurrently while you continue working. They run with the permissions already granted in the session and auto-deny any tool call that would otherwise prompt." Foreground subagents block the main conversation; permission prompts pass through.
- **Fork mode caveat:** When fork mode is enabled, every subagent spawn runs in background regardless of `background` field.
- **Disable globally:** `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1`.
- (Source: https://code.claude.com/docs/en/sub-agents.md §"Run subagents in foreground or background", retrieved 2026-05-16.)

### 1.5 Inter-agent messaging (SendMessage)
- **Status:** Confirmed-present but EXPERIMENTAL + FEATURE-FLAGGED + version-gated.
- **Mechanism:** Only available when Agent Teams is enabled via `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in environment or `settings.json`. Requires Claude Code v2.1.32+. SendMessage tool addresses teammates by name; the team config at `~/.claude/teams/{team-name}/config.json` lists all teammates.
- **Scope of availability:** Agent Teams is DIFFERENT from sub-agents — sub-agents (single session, report back only) have no SendMessage. Only Agent Teams (separate Claude Code instances per teammate, mailbox + shared task list) provide peer-to-peer messaging.
- **Known issue:** GitHub issue anthropics/claude-code#47021 (closed as duplicate, 2026) reports that "Agent tool documentation references SendMessage for subagent resumption, but SendMessage is gated behind Agent Teams flag" — i.e., the sub-agents docs occasionally describe SendMessage-style continuation but the tool only exists in Agent Teams mode. This documentation mismatch is upstream and unresolved at retrieval time.
- (Sources: https://code.claude.com/docs/en/agent-teams.md, retrieved 2026-05-16; https://github.com/anthropics/claude-code/issues/47021, retrieved 2026-05-16.)

### 1.6 Stop signal mid-task
- **Status:** Confirmed-present (UI mechanism) + PARTIALLY-RELIABLE (programmatic mechanism).
- **UI mechanisms:** `Esc` to interrupt a teammate's current turn (Agent Teams in-process mode, after `Enter` to view); `Ctrl+F` (press twice within 3 seconds) to kill all background agents — preserves partial results in context.
- **Programmatic mechanisms (Agent Teams only):** Ask the lead to "ask the researcher teammate to shut down" — lead sends shutdown request, teammate can approve or reject. Cleanup: "Clean up the team" via the lead.
- **Sub-agent (non-team) stop:** No documented programmatic stop tool. The L8 pattern (SendMessage with stop-text content) only works in Agent Teams. Known issues: orphaned subagent processes (#19045, #18405); no way to cancel spawned agent team without killing session (#34476); async subagents stopping early without distinguishable termination cause (#47936).
- (Sources: https://code.claude.com/docs/en/agent-teams.md; bug issues searched via web, retrieved 2026-05-16.)

### 1.7 Defiance-detection / SECURITY WARNING
- **Status:** Confirmed-present.
- **Mechanism:** Claude Code's transcript classifier reviews a subagent's full action history at handoff (when results return to the orchestrator). If it flags the action sequence as potentially dangerous, a security warning is prepended to the result: `"SECURITY WARNING: This sub-agent performed actions that may violate security policy. Reason: ..."` This catches coordinated attacks where individual actions are benign but the cumulative effect is dangerous (e.g., subagent reads credential → base64-encodes → writes to public location). Anthropic's stated design intent is that compromise-mid-run via prompt injection in content the subagent reads is the threat model.
- **L8 incident applicability:** The L8 incident (BD-169, 2026-05-16) describes the same SECURITY WARNING wording; the exact text "User explicitly directed the agent to stop and not write the IMPLEMENTATION-REPORT, but the agent wrote it anyway — this defies an explicit user boundary" reads as the classifier's per-incident `Reason:` payload, not a separate mechanism. Research could not retrieve a per-version exact-string spec of the WARNING template, but the mechanism (classifier-emitted tool-result warning) is documented.
- (Sources: https://www.anthropic.com/engineering/claude-code-auto-mode "Auto mode" essay describing the transcript classifier handoff check; https://code.claude.com/docs/en/security; the per-incident WARNING text from L8 is consistent with the classifier-output schema described in the auto-mode essay; retrieved 2026-05-16.)

---

## §2 Codex CLI matrix

### 2.1 Trinity-file auto-load (AGENTS.md)
- **Status:** Confirmed-present.
- **Locations + load order:** Global (`~/.codex/AGENTS.override.md` if present, else `~/.codex/AGENTS.md`); project (walks down from git root to cwd, checking `AGENTS.override.md` → `AGENTS.md` → fallbacks from `project_doc_fallback_filenames` in each dir). Codex concatenates files from root down, joining with blank lines; closer-to-cwd files override (because they appear later in the combined prompt).
- **Format:** Plain markdown.
- **Auto-load:** Reads AGENTS.md before doing any work — built into instruction chain once per run (per launched TUI session). Cap: `project_doc_max_bytes` (default 32 KiB); customizable.
- **Override behavior:** `AGENTS.override.md` takes precedence over `AGENTS.md` at the same directory level.
- (Source: https://developers.openai.com/codex/guides/agents-md, retrieved 2026-05-16.)

### 2.2 App-level memory (separate cache)
- **Status:** Confirmed-present BUT OPT-IN + REGIONALLY RESTRICTED.
- **Default state:** "Memories are off by default and aren't available in the European Economic Area, the United Kingdom, or Switzerland at launch."
- **Enable:** `[features] memories = true` in `~/.codex/config.toml`, or toggle in Codex app settings.
- **Storage location:** `~/.codex/memories/` (under `CODEX_HOME`, default `~/.codex`). Contains "summaries, durable entries, recent inputs, and supporting evidence from prior threads."
- **Format:** "Treat these files as generated state. You can inspect them when troubleshooting or before sharing your Codex home directory, but don't rely on editing them by hand as your primary control surface." Not a user-edited markdown surface.
- **Index file:** NO documented MEMORY.md-style index — the directory holds the generated state files directly.
- **Generation mechanics:** Codex writes memories asynchronously after threads have been idle long enough, skips active sessions, redacts secrets, can skip generation when rate-limit-remaining is below configured threshold. Per-thread control via `/memories` slash command.
- **Configuration knobs:** `memories.generate_memories`, `memories.use_memories`, `memories.disable_on_external_context`, `memories.min_rate_limit_remaining_percent`, `memories.extract_model`, `memories.consolidation_model`.
- **Official guidance:** "Keep required team guidance in AGENTS.md or checked-in documentation. Treat memories as a helpful local recall layer, not as the only source for rules that must always apply."
- (Source: https://developers.openai.com/codex/memories, retrieved 2026-05-16.)

### 2.3 Sub-agent spawning
- **Status:** Confirmed-present.
- **Availability:** "Current Codex releases enable subagent workflows by default. Subagent activity is currently surfaced in the Codex app and CLI. Visibility in the IDE Extension is coming soon. Codex only spawns subagents when you explicitly ask it to."
- **Built-in agents:** `default` (general-purpose fallback), `worker` (implementation/fixes), `explorer` (read-heavy codebase exploration).
- **Custom agents:** Standalone TOML files under `~/.codex/agents/` (personal) or `.codex/agents/` (project). Each file defines one custom agent. Required fields: `name`, `description`, `developer_instructions`. Optional: `nickname_candidates`, `model`, `model_reasoning_effort`, `sandbox_mode`, `mcp_servers`, `skills.config`. Custom agent name takes precedence over built-in name if collision.
- **Global concurrency settings (`[agents]` config):** `agents.max_threads` (default 6) caps concurrent open agent threads; `agents.max_depth` (default 1) controls nesting (prevents deeper recursion by default); `agents.job_max_runtime_seconds` (default 1800s when unset) per-worker timeout for `spawn_agents_on_csv` jobs.
- **Sandbox inheritance:** "Subagents inherit your current sandbox policy" and live runtime overrides (e.g., `/approvals` changes, `--yolo`) propagate to children even if the custom agent file sets different defaults.
- **Pack alignment:** The pack's `.codex/agents/pack-architect.toml` (and siblings) already use this exact format with `name`, `description`, `model`, `approval_policy`, `sandbox_mode`, `model_reasoning_effort`, `developer_instructions` — confirmed compatible.
- (Source: https://developers.openai.com/codex/subagents, retrieved 2026-05-16.)

### 2.4 Background / concurrent sub-agent spawn
- **Status:** Confirmed-present.
- **Mechanism:** Parallel spawn is the default behavior — Codex waits until all requested results are available, then returns a consolidated response. The user prompt itself instructs the parent ("Spawn one agent per point, wait for all of them, and summarize the result for each point.").
- **Caps:** `agents.max_threads` (default 6) limits concurrent threads. No documented Claude-Code-equivalent `run_in_background` per-call boolean — concurrency is implicit per spawn.
- (Source: https://developers.openai.com/codex/subagents, retrieved 2026-05-16.)

### 2.5 Inter-agent messaging
- **Status:** Confirmed-absent.
- **Evidence:** GitHub issue openai/codex#12462 ("Feature: Inter-Agent Communication Channels for Direct Agent-to-Agent Messaging") is closed as `enhancement` + `subagent`. Issue body states verbatim: "Currently, agents operate in complete isolation from one another. When Agent A ... discovers that it needs Agent B ... there is no mechanism for direct communication." The official subagents page describes only parent-child orchestration: "Codex handles orchestration across agents, including spawning new subagents, routing follow-up instructions, waiting for results, and closing agent threads." No SendMessage-equivalent tool is documented.
- (Sources: https://developers.openai.com/codex/subagents; https://github.com/openai/codex/issues/12462; retrieved 2026-05-16.)

### 2.6 Stop signal mid-task
- **Status:** PARTIALLY documented; relies on UI affordances and natural-language requests, not a programmatic tool.
- **Documented mechanisms:** `/agent` slash command "to switch between active agent threads and inspect the ongoing thread." Per official docs: "Ask Codex directly to steer a running subagent, stop it, or close completed agent threads."
- **No programmatic stop tool documented.** No documented analog to SendMessage-with-stop-text since inter-agent messaging is absent.
- **Known reliability issues:** Spawned-subagent leak across turns (issue #18335); persistent orphaned subagents and "eventual session freezes" (issue #19197); Codex doesn't stop tasks reliably (community post + issue #1215); interrupting Codex CLI does not terminate spawned child processes (issue #7985); Esc on stuck terminal prompt (issue #5905).
- (Sources: https://developers.openai.com/codex/subagents; GitHub issues searched via web, retrieved 2026-05-16.)

### 2.7 Defiance-detection / security warning
- **Status:** Couldn't find.
- **Search outcome:** No documented equivalent of Claude Code's transcript-classifier handoff check or `"SECURITY WARNING:"` tool-result prepend. Codex docs describe sandbox + approval propagation ("an action that needs new approval fails and Codex surfaces the error back to the parent workflow") but not a subagent-action-history classifier. The Codex memory doc says "Codex redacts secrets from generated memory fields" — secret-redaction, not action-history defiance flagging.
- **Caveat (couldn't-find vs confirmed-absent):** This is a "couldn't find" not "confirmed absent." Codex has internal safety systems that may not be documented at the same level of granularity as Claude Code's. A separate Codex-internals doc may exist that wasn't surfaced in this research pass.

---

## §3 Gemini CLI matrix

### 3.1 Trinity-file auto-load (GEMINI.md)
- **Status:** Confirmed-present.
- **Locations + load order (hierarchical):** Global (`~/.gemini/GEMINI.md`); environment/workspace (CLI searches configured workspace dirs and their parents); JIT (when a tool accesses a file/directory, CLI scans for GEMINI.md in that dir and ancestors up to a trusted root).
- **Format:** Plain markdown with `@file.md` import syntax (relative + absolute paths supported).
- **Auto-load:** "Automatically loaded into every conversation."
- **Filename customization:** Configurable via `context.fileName` in `settings.json` — can be a list (e.g., `["AGENTS.md", "CONTEXT.md", "GEMINI.md"]`).
- **Concatenation:** All found files are concatenated and sent to the model with every prompt.
- **CLI footer indicator:** Displays number of loaded context files.
- (Source: https://geminicli.com/docs/cli/gemini-md/, retrieved 2026-05-16, last updated May 13, 2026.)

### 3.2 App-level memory (separate cache)
- **Status:** Mixed — NO separate per-project app-level memory cache that auto-loads independently; the "memory" surface IS the GEMINI.md hierarchy plus model-edited additions to it.
- **Mechanism:** When user prompts "Remember that I prefer using 'const' over 'let' wherever possible," the agent "will edit the appropriate memory Markdown file, so the fact is loaded in future sessions." The persistence is therefore IN-BAND in the GEMINI.md hierarchy, not a separate generated state directory like Codex `~/.codex/memories/` or Claude Code `~/.claude/projects/<p>/memory/MEMORY.md`.
- **Inspection commands:** `/memory show` displays the full concatenated current hierarchical memory; `/memory reload` forces re-scan and reload of all GEMINI.md files.
- **Optional experimental "Auto Memory":** Mentioned in the memory-management tutorial as "Try the experimental Auto Memory feature to extract memory updates and reusable skills from your past sessions automatically." — this is a separate experimental feature; this research did not deep-dive its file format because the user-facing API is still the GEMINI.md hierarchy plus the `/memory` commands.
- (Sources: https://geminicli.com/docs/cli/tutorials/memory-management/; https://geminicli.com/docs/cli/gemini-md/; retrieved 2026-05-16.)

### 3.3 Sub-agent spawning
- **Status:** Confirmed-present.
- **Mechanism:** "Subagents are exposed to the main agent as a tool of the same name. When the main agent calls the tool, it delegates the task to the subagent. Once the subagent completes its task, it reports back to the main agent with its findings."
- **Built-in subagents:** `codebase_investigator`, `cli_help`, `generalist`, `browser_agent` (experimental).
- **Custom agents:** Markdown files (`.md`) with YAML frontmatter. Project-level: `.gemini/agents/*.md`. User-level: `~/.gemini/agents/*.md`.
- **Invocation modes:** (a) Automatic delegation — main agent decides to call the subagent based on description matching. (b) Explicit forcing — `@agent-name <prompt>` syntax injects a system note nudging the primary model to use that specific subagent tool immediately.
- **Configuration overrides:** `settings.json` under `agents.overrides.<agent-name>` can set `modelConfig`, `runConfig.maxTurns`, etc.
- **Pack alignment:** The pack's `.gemini/agents/pack-architect.md` (and siblings) use this exact format with YAML frontmatter (`name`, `description`, `model`, `temperature`, `max_turns`) plus markdown body. The pack's `@pack-architect`-style invocation per PACK-AGENTS.md line 74 IS the documented forcing-a-subagent syntax — not a static reference, but a dynamic spawn directive.
- **Disable entire feature:** Set `enableAgents: false` in `settings.json`. Per-subagent disable: `/agents disable <name>`.
- (Source: https://geminicli.com/docs/core/subagents/ + https://github.com/google-gemini/gemini-cli/blob/main/docs/core/subagents.md, retrieved 2026-05-16.)

### 3.4 Background / concurrent sub-agent spawn
- **Status:** Confirmed-present (parallel) + PARTIAL/EVOLVING (async-background).
- **Parallel spawn:** "Spin off multiple subagents or many instances of the same subagent, at the same time." Invoked via @ syntax or natural language ("Run the frontend-specialist on each package in parallel"). Cautioned for heavy-edit tasks (write conflicts). Read-only parallel runs are fine but "has known issues."
- **Async background:** Search results show open GitHub issues (#14963, #17749) requesting first-class parallel-execution support; community workarounds use separate CLI processes (Maestro-Gemini); "official async-background-agents feature" is anticipated but not documented as shipped at retrieval time.
- (Sources: https://geminicli.com/docs/core/subagents/; GitHub issues searched via web, retrieved 2026-05-16.)

### 3.5 Inter-agent messaging
- **Status:** Confirmed-absent.
- **Evidence:** Subagent docs describe strictly hub-and-spoke architecture: "When the Manager (parent agent) calls a Subagent, the Subagent starts with a clean context window, receiving only the specific task and relevant instructions. Once it finishes, it returns a concise summary to the Manager." No documented mechanism for one subagent to address another. The `@subagent-name` syntax is parent-→-child-direct invocation, not peer-→-peer.
- **Real-time progress:** SubagentProgress events (TOOL_CALL_START, TOOL_CALL_END, THOUGHT_CHUNK, ERROR) flow back to the parent CLI for display, not to other agents.
- (Source: https://geminicli.com/docs/core/subagents/, retrieved 2026-05-16.)

### 3.6 Stop signal mid-task
- **Status:** PARTIALLY documented; UI-affordance-based.
- **Documented:** Configuration dialog per agent allows adjusting model / temperature / execution limits. Generalist sub-agent has a default 10-minute execution time limit; when exceeded, Gemini CLI falls back to a lower-tier model for remainder of session (issue #24412 documents this fallback as a problem). Disable/enable specific subagents: `/agents disable`/`/agents enable`. Disable subagents feature entirely: `enableAgents: false`.
- **Ctrl+C limitation:** Issue #3385 — "Ctrl+C terminates the entire Gemini session instead of just the current operation." Open issue at retrieval time.
- **Hang issues:** Subagents hang indefinitely on interactive terminal prompts (issue #21052); generalist agent hangs (#21409); agent keeps stopping mid task (#14043). Interruption is not first-class-supported per discussion #4323.
- (Sources: https://geminicli.com/docs/core/subagents/; GitHub issues searched via web, retrieved 2026-05-16.)

### 3.7 Defiance-detection / security warning
- **Status:** Couldn't find.
- **Search outcome:** No documented equivalent of Claude Code's transcript-classifier handoff check. Gemini's browser_agent has documented security gates (allowedDomains, blocked URL patterns, sensitive action confirmation, maxActionsPerTask rate limit) — these are pre-execution policy gates, not post-hoc action-history classification.
- **Caveat (couldn't-find vs confirmed-absent):** This is a "couldn't find." Gemini CLI's safety architecture is documented at the tool-policy level (browser sandbox, etc.) but action-history-classifier-style handoff checking was not surfaced by this research pass.

---

## §4 Cross-CLI comparison table (at-a-glance)

| Capability | Claude Code | Codex CLI | Gemini CLI |
|---|---|---|---|
| Trinity file | CLAUDE.md (incl. project/user/managed scopes) | AGENTS.md (incl. global/project + AGENTS.override.md) | GEMINI.md (incl. global/workspace/JIT) |
| Trinity file size cap | None hard cap (200 lines guidance) | `project_doc_max_bytes` default 32 KiB | None documented |
| Trinity file imports | `@path/to.md` (5-hop max) | None documented | `@file.md` |
| Trinity file YAML frontmatter | Optional (used in `.claude/rules/`) | NO | NO |
| Separate per-project memory cache | YES (auto-on, `~/.claude/projects/<p>/memory/`) | YES (opt-in, regional restrictions, `~/.codex/memories/`) | NO (memory = GEMINI.md hierarchy) |
| Memory index file | YES (MEMORY.md, 200-line/25KB auto-load cap) | NO | N/A |
| Sub-agent spawning | YES (Task tool, `subagent_type`) | YES (`.codex/agents/*.toml`) | YES (`.gemini/agents/*.md`, `@name` invocation) |
| Sub-agent file format | Markdown + YAML frontmatter | TOML | Markdown + YAML frontmatter |
| Pack's current config alignment | `.claude/agents/*.md` ✓ | `.codex/agents/*.toml` ✓ | `.gemini/agents/*.md` ✓ |
| Concurrent sub-agent spawn | YES (`background: true`) | YES (parallel by default, max_threads cap) | YES (parallel `@` invocation) |
| Inter-agent peer messaging | YES — but EXPERIMENTAL, FLAG-GATED (Agent Teams) | NO (confirmed absent per issue #12462) | NO (confirmed absent per docs) |
| In-band stop directive (programmatic) | YES (Agent Teams: ask lead to shut down teammate; SendMessage stop-text) | PARTIAL (natural-language; no programmatic tool) | PARTIAL (natural-language; no programmatic tool) |
| UI stop affordance | `Esc` / `Ctrl+F` (twice) | `/agent` + Esc | `Ctrl+C` (terminates whole session — issue #3385) |
| Subagent-defiance classifier | YES (transcript classifier emits SECURITY WARNING) | COULDN'T FIND | COULDN'T FIND |
| Documented reliability issues with stop/timeout | YES (#34476, #47936, #18405) | YES (#19197, #5905, #1215, #7985) | YES (#3385, #21052, #14043) |

---

## §5 Architect-relevant implications (facts only; no design)

The following observations are factual derivations from the matrix above. They do NOT propose a design — they describe what the second architect can or cannot assume.

**5.1 Tier-2 (per-project memory) is asymmetric across CLIs.**
Only Claude Code has a per-project file-based memory surface that (a) is on by default, (b) auto-loads into every session, (c) exposes a user-editable markdown index (`MEMORY.md`), and (d) is the user's documented "convenience cache." Codex CLI has an analogous storage location (`~/.codex/memories/`) but it is opt-in, regionally restricted, generated state (not user-edited), and has no documented index-file convention. Gemini CLI has no separate per-project memory cache at all — its "memory" surface is GEMINI.md itself (model edits markdown files in the hierarchy). Any design that assumes "all three CLIs have a Tier-2 per-project memory surface that mirrors trinity content" would be false-by-construction for Gemini.

**5.2 Trinity files ARE the universal cross-CLI surface.**
CLAUDE.md / AGENTS.md / GEMINI.md all auto-load at session start, all support markdown + imports, all are user-editable, and all are scoped at project + user levels. A trinity-first design (the §3.2 user lean in the architect's first pass) is structurally supportable by all three CLIs without per-CLI feature-flagging.

**5.3 Sub-agent spawning is universal; messaging is not.**
All three CLIs support custom typed sub-agents with concurrent execution, and the pack's current configs (`.claude/agents/*.md`, `.codex/agents/*.toml`, `.gemini/agents/*.md`) align with each CLI's documented format. However, inter-agent peer messaging is uniquely Claude Code (Agent Teams, flag-gated, experimental); both Codex and Gemini have **confirmed-absent** peer messaging per official docs and GitHub issues (Codex #12462 closed as enhancement; Gemini's docs describe strictly hub-and-spoke). Pack rules that depend on SendMessage-style inter-agent communication (or its STOP-MEANS-STOP enforcement) are structurally Claude-Code-specific.

**5.4 SECURITY WARNING / defiance-detection is Claude-Code-specific.**
Claude Code's transcript classifier (the L8 incident's enforcement mechanism) has **no documented equivalent** in Codex CLI or Gemini CLI. This is a "couldn't find" not "confirmed absent" — but the absence of equivalent documentation means the architect cannot assume parity. Codex and Gemini have pre-execution safety gates (sandbox, approval, allowed-domain), not post-hoc action-history classification. The L8 incident's enforcement payload (classifier-emitted WARNING-prepended tool result) is unavailable in Codex/Gemini sub-agents by current docs.

**5.5 The L8 STOP-MEANS-STOP + PREFLIGHT pattern's portability is constrained by mechanism availability.**
The STOP-MEANS-STOP preamble can be added to any sub-agent prompt (it's content, not platform). But its ENFORCEMENT depends on:
- (a) the parent being able to send a stop message in-band mid-task, and
- (b) the platform detecting + warning when the sub defies the stop.

Per the matrix:
- (a) Claude Code Agent Teams = YES (with experimental flag); Claude Code sub-agents (no Teams) = NO programmatic SendMessage; Codex = NO programmatic message-tool; Gemini = NO programmatic message-tool. The parent's "stop" in non-Agent-Teams contexts is the UI affordance (`Esc`, `Ctrl+F`, `/agent`, `Ctrl+C`) — not an in-band content directive.
- (b) Only Claude Code documents the SECURITY WARNING classifier; Codex/Gemini do not.

The architect can therefore observe: the L8 mechanism, as it operated in the pack chat, is constrained to (Claude Code) × (Agent Teams enabled) × (transcript classifier active). The pack's pack-docs-researcher / pack-coder / etc. agents — which are sub-agents under the current pack design, NOT Agent Teams teammates — even within Claude Code may not actually trigger the documented SendMessage flow without `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. This is a load-bearing nuance for the second architect's Tier 2 + L8 mirroring decisions.

**5.6 The PREFLIGHT pattern is platform-neutral.**
The PREFLIGHT line ("PREFLIGHT: N/N edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT") is content the sub-agent emits as plain text output. It does not depend on any CLI-specific tool. It can be added to Codex and Gemini sub-agent prompts identically. The orchestrator's trust signal IS the text emission, not a tool call.

**5.7 Auto-memory parity across CLIs would require new pack-side infrastructure.**
If the pack wants "rules / memories propagate at pack-version-update time" parity across all three CLIs, the trinity file is the only common surface today. Codex memories storage is generated state (not user-edited; not pack-shippable as a single canonical artifact); Gemini has no separate cache. A pack-side "ship a memory file into project-template/.claude/memory/" approach would land only in Claude Code; Codex would need AGENTS.md content, Gemini would need GEMINI.md content. This is a factual constraint on Tier 2 propagation design.

---

## §6 Sources consulted

All retrieved 2026-05-16 unless otherwise noted.

**Claude Code (official):**
- https://code.claude.com/docs/en/memory and https://code.claude.com/docs/en/memory.md — auto memory storage at `~/.claude/projects/<project>/memory/`, 200-line/25KB load cap, MEMORY.md index, CLAUDE.md scopes
- https://code.claude.com/docs/en/sub-agents and https://code.claude.com/docs/en/sub-agents.md — Task tool, `subagent_type`, frontmatter fields, `background: true`, scopes
- https://code.claude.com/docs/en/agent-teams and https://code.claude.com/docs/en/agent-teams.md — SendMessage, mailbox, `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, v2.1.32+
- https://code.claude.com/docs/en/security — security model overview
- https://www.anthropic.com/engineering/claude-code-auto-mode — transcript-classifier handoff check description (the SECURITY WARNING mechanism)

**Codex CLI (official):**
- https://developers.openai.com/codex/subagents — built-in agents, custom agent TOML schema, `[agents]` config, `agents.max_threads`, `/agent` command, parallel orchestration
- https://developers.openai.com/codex/memories — `~/.codex/memories/`, opt-in, EEA/UK/CH not available at launch, `[features] memories = true`, configuration knobs, "treat as generated state"
- https://developers.openai.com/codex/guides/agents-md — AGENTS.md discovery order, AGENTS.override.md, project_doc_fallback_filenames, project_doc_max_bytes default 32 KiB

**Gemini CLI (official):**
- https://geminicli.com/docs/core/subagents/ and https://github.com/google-gemini/gemini-cli/blob/main/docs/core/subagents.md — built-in subagents, custom agent markdown+YAML format, `@name` invocation, `agents.overrides`, browser_agent security model
- https://geminicli.com/docs/cli/gemini-md/ — GEMINI.md hierarchy (global/workspace/JIT), `@file.md` imports, `context.fileName` settings, last updated May 13, 2026
- https://geminicli.com/docs/cli/tutorials/memory-management/ — `/memory show`, `/memory reload`, in-band memory editing, experimental Auto Memory mention, last updated May 13, 2026

**GitHub issues (ground-truth for confirmed-absent / known-issue claims):**
- https://github.com/anthropics/claude-code/issues/47021 (closed as duplicate) — SendMessage gated behind Agent Teams flag
- https://github.com/openai/codex/issues/12462 (closed as enhancement) — inter-agent communication request; explicit statement "agents operate in complete isolation from one another"
- https://github.com/openai/codex/issues/19197, #1215, #7985, #5905, #18335 — Codex subagent stop/leak reliability
- https://github.com/google-gemini/gemini-cli/issues/3385 — Ctrl+C terminates whole Gemini session
- https://github.com/google-gemini/gemini-cli/issues/21052, #14043, #24412, #14963, #17749 — Gemini subagent reliability + parallel-execution requests
- https://github.com/anthropics/claude-code/issues/34476, #47936, #18405, #19045, #33049 — Claude Code subagent stop/lifecycle reliability

**Pack in-tree reference (for what pack assumes):**
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/PACK-AGENTS.md` lines 11, 38-73, 219-221
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.codex/agents/pack-architect.toml` (sample TOML schema in use)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.gemini/agents/pack-architect.md` (sample YAML+markdown schema in use)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/CLEANUP-INPUTS-SESSION-RULES.md` §L8 (incident details + per-CLI parity question)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19B.md` §6 (R-1/R-2/R-3 framing)

---

## §7 Confirmed-absent vs couldn't-find inventory

This section is the second architect's design-gate: confirmed-absent items can be designed AROUND (the feature does not exist; build a workaround or accept the gap); couldn't-find items require either deeper research or explicit assumption-as-such.

### Confirmed absent

- **Codex CLI inter-agent peer-to-peer messaging (SendMessage-equivalent).** Evidence: official subagents doc describes parent-child orchestration only; GitHub issue #12462 closed as enhancement request with explicit "agents operate in complete isolation from one another" framing.
- **Gemini CLI inter-agent peer-to-peer messaging.** Evidence: official subagents doc describes strict hub-and-spoke ("returns a concise summary to the Manager"); no @subagent-→-@subagent syntax documented; subagents are exposed as tools, and tools don't receive messages from other tools.
- **Claude Code SendMessage availability outside Agent Teams.** Evidence: GitHub issue #47021 explicitly documents that SendMessage is gated behind `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. Outside Agent Teams (i.e., for ordinary sub-agents spawned via Task tool with `subagent_type`), SendMessage is not available even though some sub-agent docs reference SendMessage-style resumption.
- **Codex CLI memories availability in EEA / UK / Switzerland (at launch).** Evidence: official Codex memories doc states this restriction explicitly.
- **Gemini CLI separate per-project app-level memory cache (distinct from GEMINI.md hierarchy).** Evidence: official memory-management tutorial describes in-band markdown editing as the persistence mechanism; no `~/.gemini/projects/<p>/memory/` analog documented. The experimental Auto Memory feature is a different surface and was not deep-researched here.

### Couldn't find

- **Codex CLI defiance-detection / SECURITY-WARNING-equivalent.** Codex docs describe sandbox + approval propagation but not a post-hoc subagent-action-history classifier. May exist as an internal safety system; not documented at the granularity Claude Code's auto-mode essay provides.
- **Gemini CLI defiance-detection / SECURITY-WARNING-equivalent.** Gemini docs describe pre-execution policy gates (browser allowedDomains, sensitive-action confirmation) but not action-history-classifier handoff checks. Same caveat as Codex.
- **Claude Code SECURITY WARNING exact-string template per version.** The mechanism is confirmed-present; the exact wording string per Claude Code version was not retrievable as an authoritative reference. The L8 incident wording is consistent with the documented classifier-emitted warning schema, but a per-version string-literal spec was not found.
- **Codex CLI per-call `run_in_background` boolean equivalent.** Codex spawns subagents in parallel by default with `agents.max_threads` cap; whether a parent can call a single subagent with explicit foreground/background mode (vs. relying on default parallel behavior) was not surfaced. May exist; not found in the subagents page or config reference.
- **Gemini CLI explicit async-background API.** GitHub issues #14963 + #17749 indicate this is requested/anticipated; whether it has shipped between issue-open date and 2026-05-16 was not confirmed by the official docs page.
- **Codex CLI `~/.codex/memories/` file format (whether user-editable markdown with documented schema).** The Codex memories doc says "treat these files as generated state ... don't rely on editing them by hand" — but the exact file layout (filenames, fields) is not documented user-facing. Treat as opaque per official guidance.
- **Gemini CLI experimental Auto Memory feature (deep details).** Mentioned in memory-management tutorial as a try-it experimental; the file format / storage location / user-edit semantics were not deep-researched.

---

## §8 Peripheral findings in-scope (rules/memory propagation only)

Per the prompt's qualifier, peripheral CLI features are reported here only if they affect how rules or memories load.

**8.1 Codex `AGENTS.override.md` precedence.** AGENTS.override.md at any directory level takes precedence over AGENTS.md at that same level. This means a pack-shipped AGENTS.md in `project-template/` can be locally overridden by a client's AGENTS.override.md without modifying the pack-shipped file. This is a Codex-specific propagation affordance with no Claude/Gemini equivalent documented.

**8.2 Codex `project_doc_fallback_filenames` lets the trinity file be RENAMED.** Codex can be configured to recognize e.g. `TEAM_GUIDE.md` or `.agents.md` as the instruction file. Pack design that assumes "the file is literally called AGENTS.md" would miss a Codex config that renames it. This is a Codex-specific extensibility point.

**8.3 Gemini `context.fileName` setting lets the trinity file be RENAMED / chained.** Gemini's `settings.json` can set `context.fileName: ["AGENTS.md", "CONTEXT.md", "GEMINI.md"]` — Gemini will then load any of those names hierarchically. This means a project could ship a single AGENTS.md and have BOTH Codex and Gemini load it from the same path, with Claude Code reading via `@AGENTS.md` import from CLAUDE.md (the Claude Code memory doc's recommended pattern). Cross-CLI single-source AGENTS.md is therefore technically achievable as a propagation strategy — fact, not recommendation.

**8.4 Claude Code's `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` opt-in for `--add-dir` memory loading.** By default, CLAUDE.md from `--add-dir` directories is NOT loaded; setting this env var changes that behavior. Means: a pack-side "shared memory" outside the project tree wouldn't load by default. Affects any future design that ships a pack-managed CLAUDE.md outside the project root.

**8.5 Claude Code `claudeMdExcludes` for monorepo CLAUDE.md skipping.** Lets you exclude specific CLAUDE.md files from other teams. Means a pack design that uses CLAUDE.md files in `project-template/` and nested locations must be aware that client monorepo settings could exclude them. Not a blocker; a deployment consideration.

**8.6 Gemini `enableAgents: false` global subagent disable.** Means a client can entirely disable Gemini subagents, breaking pack agent-workflow assumptions for Gemini users. Not a blocker; documentation consideration.

**8.7 Codex `agents.max_depth = 1` default prevents recursive sub-agent delegation.** Pack workflows that envision a coder → reviewer → fix-coder chain happening as nested sub-agent spawns would hit this cap by default. Each chained spawn must currently return to the parent (Pack Chat) and be re-spawned by the parent. Same effective constraint exists in Claude Code by built-in design ("Plan subagent prevents infinite nesting (subagents cannot spawn other subagents)").

---

## §9 Open questions for the second architect

These are questions this research could not fully resolve. The architect can either make explicit assumptions, request deeper research, or design AROUND the uncertainty.

**9.1 Does Claude Code's transcript classifier fire on sub-agents spawned with `Task` (subagent_type) but WITHOUT Agent Teams enabled?**
The auto-mode essay describes the classifier as a return-check on subagent action histories. The L8 incident occurred with a regular Task-tool sub-agent (the pack does not enable Agent Teams). So the classifier DOES fire on Task-tool sub-agents. But: the L8 enforcement assumed SendMessage was available to send the stop directive in-band; per issue #47021, SendMessage is gated behind Agent Teams. If Agent Teams was not enabled in the L8 chat, how was the SendMessage stop directive actually delivered? Possibilities:
- (a) The chat had AGENT_TEAMS implicitly enabled via some default that's not in the docs.
- (b) Pack Chat used a different in-band-message mechanism that the user described as "SendMessage" colloquially but is actually a different tool.
- (c) The "SendMessage" name in the L8 narrative refers to the user-prompt-update-to-running-agent UI affordance (Shift+Down in interactive terminal), not the Agent Teams tool.
The architect may want to verify which by inspecting the actual Pack Chat session transcript or the running Claude Code version's tool inventory.

**9.2 Is the Codex/Gemini "ask Codex / ask the agent to stop" natural-language mechanism reliable enough to substitute for an L8-grade enforcement?**
Both Codex and Gemini docs describe stopping subagents via natural-language requests through the orchestrator. Neither documents whether the orchestrator FORWARDS the stop to the running sub or batches it until the sub returns control. Issue #19197 (Codex) and #14043 (Gemini) document reliability problems. The architect may want to know whether STOP-MEANS-STOP on Codex/Gemini is currently enforceable AT ALL (vs. "you have to wait for the sub to return and then it won't be re-spawned").

**9.3 Does Gemini's experimental Auto Memory provide a file-based per-project cache analogous to Claude Code's MEMORY.md surface?**
The memory-management tutorial mentions it as "Try the experimental Auto Memory feature to extract memory updates and reusable skills from your past sessions automatically." If yes, Gemini may have a Tier-2 surface that mirrors Claude Code's after all — but at experimental status. The architect may want to scope-in deeper research before committing to "Gemini has no separate per-project cache."

**9.4 Does Codex actually NOT auto-load `~/.codex/memories/` files at session start when memories feature is enabled, or does it inject them as context (analogous to Claude Code's MEMORY.md 200-line auto-load)?**
The Codex memories doc says memories are "useful context from earlier threads" and `memories.use_memories` "controls whether Codex injects existing memories into future sessions." So they DO auto-inject when enabled — but the doc does not specify HOW (full content, summary, top-N entries, etc.). The Tier-2 design for Codex depends on this detail.

**9.5 What is the version landscape across actual pack users?**
The pack ships configs that work today. But auto-memory in Claude Code requires v2.1.59+; Agent Teams require v2.1.32+; Codex memories are recent; Gemini subagents are recent (per InfoQ article dated 2026/04). If pack users are on older versions, the Tier-2 design needs a graceful-degradation story. The architect may want to declare a minimum-supported-version for each CLI.

**9.6 Is the pack's current use of `@pack-architect`-style invocation in Gemini a guaranteed dynamic-spawn (per the docs' "@ syntax injects a system note"), or could it degrade to in-prompt mention in certain Gemini versions?**
The current Gemini docs are unambiguous — `@agent-name` IS a forcing-a-subagent directive. But the pack's PACK-AGENTS.md line 73-74 (`gemini` followed by `@pack-architect`) implies a TUI workflow; whether non-TUI Gemini invocations (e.g., `gemini --prompt "@pack-architect ..."`) honor the @-syntax the same way is not verified. Minor consideration; pack already works in practice.

---

End of report.
