# TOOL-COMPARISON.md — AI Tool Capability Reference

*Location: `maintenance-docs/TOOL-COMPARISON.md`*
*This is a living reference document. Update when tool capabilities change.*
*Supersedes: GEMINI-CLI-ANALYSIS.md and ANDROID-ANALYSIS.md. Deprecation notices
are added to those files in Step 2 of V9-DESIGN.md.*

---

## How to use this document

This document is the authoritative reference for capability differences across
the three major AI tools supported by this pack: Claude, Codex, and Gemini.
It covers PM chat capabilities, agent invocation, skill loading, approval
models, context windows, and cost routing.

Read this before: setting up a new project on a tool you haven't used before,
switching PM chat tools mid-project, or designing agent prompts that need to
work across tools.

---

## Part 1 — PM Chat Capability Matrix

*Last verified: April 2026. Verify currency before relying on this table.*
*Update policy: When any capability changes are confirmed, update this table,
update the "Last verified" date, and add a line to CHANGELOG.md noting what
changed and the new verification date.*

Gemini Web (AI Studio) and Gemini IDE are excluded — neither supports the PM
chat capabilities that matter (persistent project rules, repo access, file write,
session history) and both are primarily model playgrounds or IDE sidebars rather
than project management surfaces.

*¹ ChatGPT Web is used as the Codex PM chat surface. Codex Web (chatgpt.com/codex)
is the cloud agent executor — it runs tasks in sandboxed environments and is not
used as a PM chat surface.*

**Legend:** ✅ Native/default · ⚙️ Native with setup · 🔌 Requires tool/MCP · ❌ Unavailable

| Capability | Claude CLI | Claude Desktop | Claude Web | Codex CLI | Codex App (local)² | ChatGPT Web (PM chat)¹ | Gemini CLI |
|---|---|---|---|---|---|---|---|
| Persistent project rules | ⚙️ CLAUDE.md | ⚙️ CLAUDE.md | ✅ Projects | ⚙️ AGENTS.md | ⚙️ AGENTS.md | ⚙️ Custom instructions | ⚙️ GEMINI.md |
| Repo read access | ✅ Filesystem | ✅ Filesystem | 🔌 GitHub connector | ✅ Filesystem | ✅ Filesystem | 🔌 GitHub connector | ✅ Filesystem |
| File write access | ✅ Native | ✅ Desktop Commander | 🔌 Desktop Commander | ✅ Native | ✅ Native | ❌ | ✅ Native |
| Cross-session history | ⚙️ /chat save | ✅ Session history | ✅ Projects | ⚙️ codex --resume | ⚙️ Session resume | ⚙️ Threads | ⚙️ /chat save + resume |
| Context compression | ✅ /compact | ✅ /compact | ❌ | ❌ | ❌ | ❌ | ✅ /compress |
| Skill loading | ✅ Auto | ✅ Auto | ❌ | ✅ On-demand | ✅ On-demand | ❌ | ✅ activate_skill |
| MCP servers | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Web search | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Multi-machine sync | ❌ Local | ❌ Local | ✅ Cloud | ❌ Local | ❌ Local | ✅ Cloud | ❌ Local |

*² Codex App (`codex app`) is a local development server, not a full desktop
application. Capabilities may differ from Codex CLI in edge cases.*

**Best PM chat surface per tool:**
- Claude: Web Projects (cloud, semantic GitHub search, Desktop Commander via MCP)
- Codex: ChatGPT Web (cloud, persistent threads, GitHub connector)
- Gemini: Gemini CLI (local, /chat save/resume, GEMINI.md hierarchy)

---

## Part 2 — Agent Invocation Differences

| Aspect | Claude Code | Codex CLI | Gemini CLI |
|---|---|---|---|
| Agent definition format | Markdown (`.claude/agents/*.md`) | TOML (`.codex/agents/*.toml`) | GEMINI.md sections + skills |
| Invoke with agent | `claude --agent <name>` | `codex --agent <name>` | Skill activation + GEMINI.md role |
| Standard launcher | `agent-run.sh claude --agent <name>` | `agent-run.sh codex --agent <name>` | No `--agent` flag; invocation via skill activation + GEMINI.md role — `agent-run.sh` Gemini support designed in Step 9 |
| Local model support | ❌ Anthropic models only | ✅ Ollama, LM Studio via `[model_providers]` | ❌ Google models only |
| Model profiles | Single model per invocation | `cloud-default`, `local-light`, `local-code` profiles in `config.toml` | Single model per invocation |
| Context file read | CLAUDE.md (auto) | AGENTS.md (auto) | GEMINI.md (auto, hierarchical) |
| Subagent support | ✅ Parallel, tool-isolated | ✅ Via config | ✅ Local execution (current default) |
| Interactive/TUI | ✅ | ✅ | ✅ PTY shell (handles interactive) |
| Headless/scripted | ✅ exec mode | ✅ exec mode | ✅ headless mode |
| Windows support | ❌ (WSL only) | ⚙️ Experimental | ✅ Node.js cross-platform |

**`agent-run.sh`:** The standard launcher script shipped in every project template.
It automatically applies the correct read-only permission flags for agents that
should never write files (reviewer, auditor and subagents, planner, architect,
docs-researcher, grpc-schema) and write flags for agents that should (coder,
tester, repo-ops). Invoking agents through `agent-run.sh` is the recommended
approach for consistent permission behavior.

---

## Part 3 — Skill Loading Mechanisms

All three tools use the same SKILL.md format (name, description, allowed-tools
frontmatter followed by natural-language instructions). Skills created for one
tool work on the others without modification.

**How skills are discovered and loaded:**

| Tool | Discovery | Loading |
|---|---|---|
| Claude Code | All skill descriptions loaded into system prompt at startup | Full skill content loaded when task matches description |
| Codex CLI | Skills listed in project docs (AGENTS.md — the project's Codex context file) are known | Loaded on-demand when listed; flag `--enable skills` required (may still be gated) |
| Gemini CLI | Skill descriptions loaded at startup | `activate_skill` tool loads full content when description matches task |

**Implication for skill authoring:**
- Skill descriptions must be tight enough to trigger correct activation in
  Codex and Gemini — overly broad descriptions cause false activations.
- Skills that are always needed for a project type should be listed explicitly
  to ensure availability: in AGENTS.md for Codex projects, in GEMINI.md for
  Gemini projects. Listing ensures availability without relying on description-matching alone.
- Claude Code can tolerate more verbose descriptions since it loads all at once.

---

## Part 4 — Approval Model Defaults

Approval models control when the agent pauses for human confirmation before
taking an action (file write, shell command). Different defaults across tools
mean the same prompt behaves differently without explicit configuration.

| Tool | Default approval behavior | Recommended for coder | Recommended for reviewer/auditor |
|---|---|---|---|
| Claude Code | Approval before each file write and shell command | Default (approval on) | Default (approval on) |
| Codex CLI | `--ask-for-approval on-request` with workspace sandbox | Default | Default |
| Gemini CLI | Plan Mode: read-only proposal before any edits (current default) | Confirm plan then execute | Plan Mode (natural fit) |

**Critical:** Never use full-auto / no-approval mode for agents that modify
production source files. The `--yolo` / `--dangerously-bypass-approvals`
flags on Codex and Claude Code respectively are not permitted in this workflow.

---

## Part 5 — Context Window and Cost

*Note: Pricing and model names change frequently. Verify current pricing at
each tool's official documentation before making cost decisions. The table
below reflects April 2026 information.*

| Tool | Context window | Free tier | Paid tier | Recommended for |
|---|---|---|---|---|
| Claude Code (Sonnet) | 200K tokens | None | Per token ($3/$15 per 1M) | Coder, architect (quality) |
| Claude Code (Opus 4.6) | 1M tokens | None | Per token (higher) | Complex coder, large codebase |
| Codex CLI (GPT-5.1 Max) | Large | Included in ChatGPT Plus | ChatGPT Plus $20/mo | General coder, debugging |
| Gemini CLI (Flash) | 1M tokens | 1,000 req/day | Free | Reviewer, tester, docs-researcher |
| Gemini CLI (Pro) | 1M tokens | Limited | Paid | Auditor (large codebase) |

**Recommended tool routing by agent type:**

| Agent | Recommended tool | Rationale |
|---|---|---|
| `architect` | Claude Code (Sonnet) | Complex reasoning; architectural errors are expensive |
| `coder` | Claude Code (Sonnet) | Code quality matters; reliable file writes |
| `reviewer` | Gemini CLI (Flash, free) | Read-only; pattern-matching; free tier sufficient |
| `tester` | Gemini CLI (Flash, free) | Analysis and report; high volume, zero cost |
| `auditor` | Gemini CLI (Pro) | Large context; 1M window handles full codebase |
| `docs-researcher` | Gemini CLI (Flash, free) | Web search + report; Flash handles this well |
| `planner` | Claude Code (Sonnet) or Gemini CLI (Pro) | Phase breakdown benefits from good reasoning |
| `repo-ops` | Any | Mechanical; model quality irrelevant |
| `grpc-schema` | Claude Code (Sonnet) | Schema design benefits from careful reasoning |

*Note: This table is a recommendation, not a requirement. Any agent can run on
any tool. Use this as a starting point and adjust based on observed results.*

---

## Part 6 — Cross-Tool Operational Differences

### MCP configuration locations

| Tool | Config file | Desktop Commander available? |
|---|---|---|
| Claude Code | `~/.claude/` settings | ✅ Claude Desktop only |
| Codex CLI | `~/.codex/config.toml` | ❌ No equivalent |
| Gemini CLI | `~/.gemini/settings.json` | ❌ Native file write used instead |

### PM chat session commands

| Operation | Claude | Gemini CLI | ChatGPT Web |
|---|---|---|---|
| Save session | Automatic (Projects) | `/chat save <tag>` | Automatic (threads) |
| Resume session | Return to Project | `/chat resume <tag>` | Return to thread |
| Compress context | `/compact` | `/compress` | Not available |
| Add persistent fact | Memory system | `save_memory` | Custom instructions |
| Startup orientation | `pm-startup` skill | pm-startup skill | Paste startup prompt |

### Switching PM chat tools mid-project

This is supported. The startup skill on each tool reads the four key state
docs (`IMPLEMENTATION_PLAN.md`, `STATUS.md`, `BACKLOG.md`, `CHANGELOG.md`)
and reconstructs context. The current phase, open backlog items, and recent
changes are all recoverable from the project docs.

What is NOT preserved across a tool switch: the reasoning behind past decisions
as expressed in prior turns. This is why every significant decision must be
written into `ARCHITECTURE.md` or `IMPLEMENTATION_PLAN.md` before the session
ends — those docs are the permanent record, not the conversation history.

For detailed daily-use guidance on CLI PM chat sessions (resume procedures, RAG
setup, cross-machine workflow, and troubleshooting), see
`supporting-docs/CLI-PM-SETUP.md`.

---

## Part 7 — Platform-Specific Notes

### Windows support
- Claude Code: Not supported natively. WSL required.
- Codex CLI: Experimental on Windows. WSL recommended for best experience.
- Gemini CLI: Cross-platform via Node.js. Best Windows compatibility.
- All pack scripts use POSIX-compatible bash and degrade gracefully on WSL.

### macOS-specific tools
- Desktop Commander: Claude Desktop on macOS only.
- swift-format, xcodebuild: macOS only.
- uv, ruff, pyright: Cross-platform.
- buf: Cross-platform.

### Deprecated analysis documents
The following files contain point-in-time analysis that has been superseded
by this document:
- `maintenance-docs/GEMINI-CLI-ANALYSIS.md` — content absorbed here
- `maintenance-docs/ANDROID-ANALYSIS.md` — content absorbed here

Both files remain in the repo for historical reference but should not be
treated as current. This document takes precedence.

---

*Last updated: April 2026*
*Update the "Last verified" date in Part 1 when the capability matrix is re-checked.*
