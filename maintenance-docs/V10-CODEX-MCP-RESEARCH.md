# V10 — Codex CLI MCP Server Configuration Research

Status: Research note, read-only pass. Date: 2026-04-30. Backlog ref: BD-059.

> Provenance: produced by `pack-docs-researcher` background agent on
> 2026-04-30. Agent could not write the file directly (Bash file-creation
> blocked + no Write tool); content returned inline and persisted here
> verbatim by Pack Chat.

---

## Part 1 — Verdict

**Codex CLI supports MCP servers.** Configuration lives in `config.toml` — primary path `~/.codex/config.toml`, with optional project-scoped override at `.codex/config.toml` (loaded only when the project is marked trusted). MCP servers are declared under `[mcp_servers.<name>]` tables and may be either STDIO (`command`) or Streamable HTTP (`url`).

Primary citations:
- OpenAI Codex MCP doc: https://developers.openai.com/codex/mcp
- Repo config schema: https://github.com/openai/codex/blob/main/docs/config.md

---

## Part 2 — Evidence (sources consulted, all 2026-04-30)

| # | Source | URL | What it confirms |
|---|--------|-----|------------------|
| 1 | OpenAI Codex Developers — MCP page | https://developers.openai.com/codex/mcp | MCP supported; STDIO + Streamable HTTP; `[mcp_servers.<name>]` tables in `config.toml`; `codex mcp` CLI subcommand; CLI and IDE share config |
| 2 | `openai/codex` repo `docs/config.md` | https://github.com/openai/codex/blob/main/docs/config.md | Authoritative schema for `[mcp_servers.*]` keys |
| 3 | Codex Config Reference | https://developers.openai.com/codex/config-reference | Confirms `[mcp_servers]`, transport split, `experimental_use_rmcp_client` flag |
| 4 | Codex Config Basics | https://developers.openai.com/codex/config-basic | Confirms project-scoped `.codex/config.toml` only loads for **trusted** projects |
| 5 | Codex Agent Approvals & Security | https://developers.openai.com/codex/agent-approvals-security | MCP tool calls subject to `approval_policy` and sandbox rules |
| 6 | PR #4317 — streamable HTTP MCP support | https://github.com/openai/codex/pull/4317 | Streamable HTTP via `rmcp` client, gated by `experimental_use_rmcp_client` |
| 7 | Issue #3441 — MCP servers in config.toml ignored | https://github.com/openai/codex/issues/3441 | Historical bug, now resolved |
| 8 | Issue #13025 — Project `.codex/config.toml` ignored in Desktop | https://github.com/openai/codex/issues/13025 | IDE-extension reliability gap (CLI path is fine) |
| 9 | Issue #2628 — Project-specific MCPs | https://github.com/openai/codex/issues/2628 | Project-level scoping added after early versions |
| 10 | Issue #4707 — streamable HTTP not working properly | https://github.com/openai/codex/issues/4707 | Version-specific reliability gaps for HTTP transport |
| 11 | github/github-mcp-server install guide for Codex | https://github.com/github/github-mcp-server/blob/main/docs/installation-guides/install-codex.md | Independent corroboration with real-world example |

Two-source rule met for every load-bearing fact below.

---

## Part 3 — Config path, format, fields, parity mapping

### 3.1 Config paths

| Scope | Path | Loaded when |
|-------|------|-------------|
| User (default) | `~/.codex/config.toml` | Always |
| Project override | `<repo>/.codex/config.toml` | Only when project is **trusted** by Codex |

CLI and IDE extension share the same config file. Sources 1, 2, 4.

### 3.2 Format — TOML, `[mcp_servers.<name>]` tables

STDIO server example:

```toml
[mcp_servers.local-rag]
command = "npx"
args = ["-y", "mcp-local-rag"]
env = { BASE_DIR = "/abs/path/to/project", DB_PATH = "./.claude/rag-index" }
startup_timeout_sec = 30
required = false
supports_parallel_tool_calls = true
```

Streamable HTTP example:

```toml
experimental_use_rmcp_client = true   # top-level; required for HTTP in current versions

[mcp_servers.figma]
url = "https://mcp.figma.com/mcp"
bearer_token_env_var = "FIGMA_OAUTH_TOKEN"
http_headers = { "X-Figma-Region" = "us-east-1" }
env_http_headers = { "X-Trace-Id" = "TRACE_ID_ENV" }
startup_timeout_sec = 30
```

### 3.3 Supported fields (from source 2)

Common to both transports:
- `startup_timeout_sec` (alias `startup_timeout_ms`)
- `tool_timeout_sec` — overrides default 60s per-tool timeout
- `required` — fail session startup if server can't initialize
- `supports_parallel_tool_calls` — mark all tools from this server parallel-eligible

STDIO-only:
- `command` (required), `args` (optional), `env` (optional)

Streamable-HTTP-only:
- `url` (required)
- `bearer_token_env_var` — env var holding token; sent as `Authorization: Bearer <value>`
- `http_headers` — static header map
- `env_http_headers` — header → env-var-name map for dynamic header values

Top-level (outside `[mcp_servers.*]`):
- `experimental_use_rmcp_client` — required for HTTP transport in pre-stable releases

### 3.4 Parity mapping vs. Claude `.mcp.json` and Gemini `.gemini/settings.json`

| Concept | Claude `.mcp.json` | Codex `config.toml` `[mcp_servers.<name>]` | Gemini `.gemini/settings.json` |
|---|---|---|---|
| Top-level container | `mcpServers` (object) | `[mcp_servers]` (TOML table) | `mcpServers` (object) |
| Server name | object key | TOML sub-table key | object key |
| STDIO command | `command` | `command` | `command` |
| STDIO args | `args[]` | `args[]` | `args[]` |
| STDIO env | `env{}` | `env{}` | `env{}` |
| HTTP URL | `url` (HTTP/SSE) | `url` (Streamable HTTP, gated by `experimental_use_rmcp_client`) | `httpUrl` / `url` |
| Bearer auth | header in `headers` | `bearer_token_env_var` | `headers` / `oauth` |
| Custom HTTP headers | `headers{}` | `http_headers{}` + `env_http_headers{}` | `headers{}` |
| Startup timeout | (not standard) | `startup_timeout_sec`/`_ms` | `timeout` (ms) |
| Per-tool timeout | (not standard) | `tool_timeout_sec` | (not standard) |
| Required-on-startup | (not standard) | `required` | (not standard) |
| Parallel tool-calls hint | (not standard) | `supports_parallel_tool_calls` | (not standard) |
| Allow/deny list | CLI / `permissions` | (no explicit list — sandbox+approval gate at call time) | `mcp.allowed`, `mcp.excluded`, `admin.mcp.*` |
| Project vs user split | `.mcp.json` (project) + `~/.claude.json` (user) | `.codex/config.toml` (project, trusted only) + `~/.codex/config.toml` (user) | `.gemini/settings.json` (project) + `~/.gemini/settings.json` (user) |

**Trinity verdict:** Codex MCP support exists and maps cleanly onto Claude `.mcp.json` for the STDIO path. The pack can ship a parallel `project-template/.codex/config.toml.example` (or extend the existing `config.toml`) to honor BD-059's trinity rule.

---

## Part 4 — If not supported

Not applicable. Codex CLI has first-class MCP support.

---

## Part 5 — Sandbox / approval-policy interaction

From sources 1, 5, and `docs/config.md`:

- MCP tool invocations are subject to the same `approval_policy` as built-in tools. With `approval_policy = "on-request"` (the pack's current default), Codex prompts before invoking MCP tools that escalate the sandbox.
- STDIO MCP servers run as **child processes of the Codex session** and inherit the session's sandbox. With `sandbox_mode = "workspace-write"` and the pack's `network_access = true`, an STDIO MCP server can read/write inside `writable_roots` and reach the network without escalation.
- Streamable HTTP MCP servers require outbound network. With `network_access = false`, HTTP MCP servers will fail to connect — escalate the sandbox or disable the server.
- `required = true` causes hard failure of session startup if the server can't initialize within `startup_timeout_sec`. Prefer `required = false` for optional servers like local-rag.
- Project-scoped `.codex/config.toml` is **only loaded for trusted projects** (source 4). An untrusted project's MCP block is silently skipped. Pack-shipped per-project Codex MCP config will not load until the developer marks the project trusted.

---

## Part 6 — Open questions / unverifiable claims

1. **Stability of `experimental_use_rmcp_client`** — whether promoted to stable in the latest Codex release was not confirmed; verify against the shipped CLI version before recommending HTTP transport.
2. **Project vs. user precedence for same-named `[mcp_servers.*]` entries** — `docs/config.md` describes general merge rules but does not restate this for MCP. Inference: project overrides user (consistent with other tables); confirm before documenting.
3. **`codex mcp` write target** — source 1 mentions the CLI subcommand but does not state default write target. Likely `~/.codex/config.toml`; verify.
4. **Trust model UX for project `.codex/`** — source 4 confirms a trust gate exists but the exact mechanism (prompt? `codex trust .` command?) was not pinned down. Implementer should run Codex once in a fresh repo and document the flow in `supporting-docs/CLI-PM-SETUP.md`.
5. **Issue #13025 status** — project-scoped MCP loading in the IDE extension has had reliability issues. CLI path appears reliable; recheck if pack ever recommends the IDE extension.

---

## Implementer guidance (one paragraph)

BD-059 can resolve via path (a): Codex CLI supports MCP. Recommended approach — ship `project-template/.codex/config.toml.example` as a sibling to the existing live `project-template/.codex/config.toml`, containing a commented `[mcp_servers.local-rag]` block mirroring the Claude example, plus a note that the file only loads for trusted projects. The `.example` sibling pattern matches `.mcp.json.example` already used for Claude and keeps secret-bearing fields (`BASE_DIR` paths, bearer-token env-var names) out of the committed live config. Confirm open-question #1 (HTTP transport stability) before adding any HTTP examples to the template.
