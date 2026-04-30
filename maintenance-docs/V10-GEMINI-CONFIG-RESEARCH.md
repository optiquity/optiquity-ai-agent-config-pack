# V10 Gemini CLI Config Research (BD-059 / BD-060)

**Audience:** Implementer of the v10 migration fix and any agent shipping
Gemini-side parity for the cross-tool capability surface (OQ-7).
**Status:** Read-only research, primary-source-cited.
**Sources used:**
- Official repo: <https://github.com/google-gemini/gemini-cli>
- Reference config (master, autogen schema): `docs/reference/configuration.md`
  (<https://github.com/google-gemini/gemini-cli/blob/main/docs/reference/configuration.md>)
- Settings UI doc: `docs/cli/settings.md`
  (<https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/settings.md>)
- Hooks reference: `docs/hooks/reference.md`
  (<https://github.com/google-gemini/gemini-cli/blob/main/docs/hooks/reference.md>)
- Sandbox doc: `docs/cli/sandbox.md`
  (<https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/sandbox.md>)
- Hosted JSON Schema:
  `https://raw.githubusercontent.com/google-gemini/gemini-cli/main/schemas/settings.schema.json`
  (cited in reference config but not directly inspected for this report;
  referenced if implementer wants strong validation).

---

## Part 1 — Config-file path and format

Gemini CLI uses **JSON `settings.json`** files. Four locations apply, in
ascending precedence (lowest → highest), with **environment variables and
CLI args** taking precedence over all four:

1. **System defaults** — `/Library/Application Support/GeminiCli/system-defaults.json`
   (macOS) / `/etc/gemini-cli/system-defaults.json` (Linux) /
   `C:\ProgramData\gemini-cli\system-defaults.json` (Windows).
   Override path: `GEMINI_CLI_SYSTEM_DEFAULTS_PATH`.
2. **User settings** — `~/.gemini/settings.json`.
3. **Project (workspace) settings** — `.gemini/settings.json` in the
   project root. **This is the file the pack ships.**
4. **System overrides** — `/Library/Application Support/GeminiCli/settings.json`
   (macOS, etc.). Override path: `GEMINI_CLI_SYSTEM_SETTINGS_PATH`.

Source: `docs/reference/configuration.md` § "Configuration layers" and
"Settings files".

**Format:** JSON. The repository ships a JSON Schema at
`schemas/settings.schema.json` for editor autocomplete / validation.

**v0.3.0 nesting note:** as of v0.3.0 Gemini CLI moved settings into a
nested-category structure (e.g. `general.vimMode`, `tools.sandbox`,
`security.toolSandboxing`). Older flat-key layouts will not match
current docs. The pack should target the nested form.

---

## Part 2 — Supported fields, organized by capability category

All fields below are **directly verified** against
`docs/reference/configuration.md` (the autogen schema mirror) and
`docs/cli/settings.md` (UI form). Top-level categories present today:
`general`, `output`, `ui`, `ide`, `privacy`, `billing`, `model`,
`modelConfigs`, `agents`, `context`, `tools`, `mcp`, `useWriteTodos`,
`security`, `advanced`, `experimental`, `skills`, `hooksConfig`, `hooks`,
`contextManagement`, `admin`, `mcpServers`, `telemetry`, plus top-level
`policyPaths` / `adminPolicyPaths`.

### 2.1 Permissions / tool gating

- `tools.allowed` (array) — tool names that bypass the confirmation
  dialog. Supports per-command shell matching, e.g.
  `"run_shell_command(git)"`, `"run_shell_command(npm test)"`.
- `tools.confirmationRequired` (array) — always-confirm allowlist.
  Takes precedence over `tools.allowed` and `tools.core`.
- `tools.exclude` (array) — tool names to exclude entirely from
  discovery.
- `tools.core` (array) — restrict the set of *built-in* tools by
  allowlist; matching semantics mirror `tools.allowed`.
- `general.defaultApprovalMode` (enum: `default | auto_edit | plan`) —
  the equivalent of Codex's `approval_policy`. YOLO is CLI-flag only.
- `security.disableYoloMode`, `security.disableAlwaysAllow`,
  `security.enablePermanentToolApproval`,
  `security.autoAddToPolicyByDefault`,
  `security.folderTrust.enabled` — security/permission posture.
- `policyPaths` / `adminPolicyPaths` — additional **policy-engine**
  files (separate file format; see `docs/reference/policy-engine.md`).

Source: `docs/reference/configuration.md` § `tools`, `general`,
`security`, top-level policyPaths.

### 2.2 Hooks

- Top-level `hooks` object with one array per event:
  `BeforeTool`, `AfterTool`, `BeforeAgent`, `AfterAgent`,
  `Notification`, `SessionStart`, `SessionEnd`, `PreCompress`,
  `BeforeModel`, `AfterModel`, `BeforeToolSelection`.
- Each entry: `{ matcher?: string, sequential?: boolean, hooks: [{ type: "command", command: string, name?, timeout?, description? }] }`.
- Master toggles: `hooksConfig.enabled` (default `true`),
  `hooksConfig.notifications` (default `true`).

Source: `docs/hooks/reference.md` § "Configuration schema" and
`docs/reference/configuration.md` § `hooks`, `hooksConfig`.

**Mapping note for OQ-7:** Claude's `hooks.PostToolUse` with matcher
`Edit|Write|MultiEdit` running `./scripts/agent-post-edit-check.sh`
maps cleanly to Gemini `hooks.AfterTool` with a regex matcher
(e.g. `"^(replace|write_file|edit)$"` — exact built-in tool names
should be confirmed against `docs/tools/file-system.md` before
shipping).

### 2.3 Environment variables

- Gemini does **not** support an arbitrary `env` object inside
  `settings.json` the way Claude does. Instead:
  - `.env` files are auto-loaded from the project root
    (walking up to `.git`, then `~/.env`).
  - `.gemini/.env` is a special location whose vars are never
    excluded by `advanced.excludedEnvVars`.
  - String values in `settings.json` can interpolate environment
    variables via `$VAR`, `${VAR}`, `${VAR:-DEFAULT}`.
- `advanced.excludedEnvVars` (array) — vars to drop when loading
  `.env` (defaults: `["DEBUG", "DEBUG_MODE"]`).
- Per-MCP-server `env` is supported inside `mcpServers.<name>.env`
  (object) — but that is server-scoped, not session-scoped.

Source: `docs/reference/configuration.md` § "Environment variables and
`.env` files", § `advanced`, § `mcpServers`.

**Implication for OQ-7:** Claude's
`env.AGENT_CAPABILITIES = "planning,..."` does **not** have a direct
`settings.json` analogue in Gemini. The closest equivalents are
(a) committing a project-level `.gemini/.env` setting
`AGENT_CAPABILITIES=...`, or (b) declaring capabilities in a Gemini
context file (e.g. `GEMINI.md`) where they are *informational* not
*config-typed*. Codex's `[agent_capabilities]` parity table will
still be Codex-only-against-Claude in v10 unless a `.gemini/.env`
parity entry is also shipped.

### 2.4 Agent capabilities / agents config

- `experimental.enableAgents` (boolean, default `true`) — master
  toggle for local and remote subagents.
- `agents.overrides` (object) — per-agent overrides (disable, custom
  model, run config). The top-level structure is `{ "<agent-name>":
  { ... } }` but the doc text is brief; the schema is the source of
  truth.
- `agents.browser.*` — browser-agent-specific (sessionMode, headless,
  profilePath, allowedDomains, confirmSensitiveActions, etc.).
- Skills: `skills.enabled` (boolean, default `true`),
  `admin.skills.enabled` (admin-side disable).

Source: `docs/reference/configuration.md` § `agents`, `experimental`,
`skills`, `admin`.

**Note:** Gemini has a real *agent override* surface
(`agents.overrides`) that Claude (`settings.json`) does not. Codex has
its own per-agent surface (`[agents.<name>]` blocks in `config.toml`
pointing to per-agent `.toml` files). All three tools therefore have a
*per-agent config* concept, but only Codex and Gemini express it
inside the tool config file — Claude's per-agent config is in
`.claude/agents/*.md` instead.

### 2.5 MCP servers

- `mcpServers.<NAME>` (object) — full MCP server config:
  `command`, `args`, `env`, `cwd`, `url`, `httpUrl`, `headers`,
  `timeout`, `trust`, `description`, `includeTools`, `excludeTools`.
  Precedence among transports: `httpUrl` > `url` > `command`.
- `mcp.allowed` / `mcp.excluded` (array) — server-level allow/block
  lists.
- `mcp.serverCommand` — single fallback command to start a server.
- `admin.mcp.enabled`, `admin.mcp.config`, `admin.mcp.requiredConfig` —
  admin-tier MCP gating.

Source: `docs/reference/configuration.md` § `mcpServers`, `mcp`,
`admin`.

### 2.6 Model selection

- `model.name` (string), `model.maxSessionTurns`,
  `model.compressionThreshold`, `model.disableLoopDetection`,
  `model.skipNextSpeakerCheck`.
- `modelConfigs` (object) — per-model overrides; large schema, see
  reference config lines 486–1373 for full surface.
- `general.plan.modelRouting` (boolean) — Pro-during-plan /
  Flash-during-implementation auto-switch.
- Env override: `GEMINI_MODEL`.

Source: `docs/reference/configuration.md` § `model`, `modelConfigs`,
§ "Environment variables" `GEMINI_MODEL`.

### 2.7 Sandboxing / approval

- `tools.sandbox` (legacy full-process; bool, profile path, or
  command name like `"docker"`, `"podman"`, `"lxc"`, `"windows-native"`).
- `tools.sandboxAllowedPaths` (array) — additional readable/writable
  paths.
- `tools.sandboxNetworkAccess` (boolean) — analogous to Codex
  `[sandbox_workspace_write].network_access`.
- `security.toolSandboxing` (boolean, default `false`) — newer
  per-tool sandboxing layer.
- `general.defaultApprovalMode` (`default | auto_edit | plan`) — see
  Permissions above.
- Custom sandbox profiles ship as separate files in `.gemini/`:
  `sandbox-macos-custom.sb`, `sandbox.Dockerfile`, etc.

Source: `docs/reference/configuration.md` § `tools` (`sandbox*`),
§ `security`, § "The `.gemini` directory in your project";
`docs/cli/sandbox.md`.

---

## Part 3 — Single file or split files?

**Single file.** Gemini's tool-level config is one JSON file
(`.gemini/settings.json`) plus optional **adjuncts** in the same
directory:

- `.gemini/.env` — secrets and `AGENT_CAPABILITIES`-style env vars
  (analogous to Claude `env` block).
- `.gemini/sandbox-macos-custom.sb`, `.gemini/sandbox.Dockerfile` —
  custom sandbox profiles when `tools.sandbox` is set to a profile.
- `.gemini/agents/` — already shipped by the pack (per-agent files,
  not part of `settings.json`).
- `.gemini/policy/*` — when `policyPaths` is used (separate
  policy-engine files; see `docs/reference/policy-engine.md`).
- `GEMINI.md` (root, not under `.gemini/`) — context file (analogous
  to `CLAUDE.md`/`AGENTS.md`).

There is **no** Gemini equivalent to Codex's split between
`config.toml` (runtime config) and `requirements.toml` (project
policies). All policy-style flags live under `settings.json` keys
(`session`, `policy`, etc. equivalents are all distributed across
`general`, `model`, `tools`, `security`, `policyPaths`).

Source: `docs/reference/configuration.md` § "The `.gemini` directory
in your project" and § "Configuration layers".

---

## Part 4 — Per-capability parity mapping

Legend: `—` = no equivalent in that tool. Cells cite the **field
name** only; consult parent docs for syntax.

| Capability                       | Claude `.claude/settings.json`                           | Codex `.codex/config.toml` / `requirements.toml`                          | Gemini `.gemini/settings.json` (+ adjuncts)                                         |
|----------------------------------|----------------------------------------------------------|---------------------------------------------------------------------------|--------------------------------------------------------------------------------------|
| Tool/command allowlist           | `permissions.allow`                                      | `sandbox_mode = "workspace-write"` + `[sandbox_workspace_write]`          | `tools.allowed` (with `run_shell_command(...)` matchers); `tools.core` for built-ins |
| Tool/command denylist            | `permissions.deny`                                       | (no explicit deny; sandbox enforces by default)                           | `tools.exclude`; `tools.confirmationRequired`                                        |
| Approval policy                  | (implicit per tool)                                      | `approval_policy = "on-request"`                                          | `general.defaultApprovalMode` (`default \| auto_edit \| plan`)                       |
| Network access in sandbox        | (Bash perms cover network indirectly)                    | `[sandbox_workspace_write].network_access = true`                         | `tools.sandboxNetworkAccess`                                                         |
| Writable roots                   | (whole repo by default)                                  | `[sandbox_workspace_write].writable_roots`                                | `tools.sandboxAllowedPaths`                                                          |
| Post-edit hook                   | `hooks.PostToolUse` matcher `Edit\|Write\|MultiEdit`     | `[sandbox_workspace_write].post_edit_command`                             | `hooks.AfterTool` with regex matcher on edit tool names                              |
| Pre-tool / pre-prompt hooks      | `hooks.PreToolUse`, `UserPromptSubmit` (Claude has more) | — (Codex has no hook system in `config.toml`)                             | `hooks.BeforeTool`, `hooks.BeforeAgent`, `hooks.BeforeModel`, etc. (full lifecycle)  |
| Session env vars                 | `env.AGENT_CAPABILITIES`, `env.XCODE_*`                  | (no top-level env; `[model_providers.*].env_key` is provider-specific)    | **No `env` block** — use `.gemini/.env` adjunct OR `${VAR}` interpolation in JSON    |
| Capability roster / agent caps   | `env.AGENT_CAPABILITIES = "planning,..."`                | (planned: `[agent_capabilities]` per OQ-7)                                | **No native field** — recommend `.gemini/.env` `AGENT_CAPABILITIES=...` for parity    |
| Model selection                  | (CLI flag / per-agent)                                   | `model = "gpt-5.4"`; `[profiles.*].model`                                 | `model.name`; `modelConfigs.*`; `general.plan.modelRouting`                          |
| Provider config                  | (CLI auth)                                               | `[model_providers.<name>]` with `name`/`base_url`/`env_key`               | `GEMINI_API_KEY` / `GOOGLE_*` env vars; `GOOGLE_GEMINI_BASE_URL`                     |
| Profiles / preset switching      | (no native)                                              | `profile = "cloud-default"`; `[profiles.*]`                               | (no native profile concept — `modelConfigs` is per-model, not per-preset)            |
| Per-agent registration           | `.claude/agents/*.md` files                              | `[agents.<name>] config_file = "agents/...toml"` (in `config.toml`)       | `.gemini/agents/*` files; `agents.overrides.<name>` for runtime overrides            |
| Subagent threading limits        | (CLI default)                                            | `[agents].max_threads`, `[agents].max_depth`                              | `experimental.enableAgents` (master toggle); no public thread-count field            |
| MCP server registration          | (separate `~/.claude.json` or CLI)                       | (not in shipped pack templates)                                           | `mcpServers.<NAME>` (full schema)                                                    |
| Allow/deny MCP servers           | —                                                        | —                                                                         | `mcp.allowed`, `mcp.excluded`, `admin.mcp.*`                                         |
| Web search toggle                | (CLI)                                                    | `web_search_mode = "on"`; per-profile                                     | (no single field; `experimental.directWebFetch` adjacent)                            |
| Local model / OSS provider       | —                                                        | `oss_provider = "lmstudio"`; `[model_providers.ollama/lmstudio]`          | `experimental.gemmaModelRouter.*` (Gemma local routing only)                         |
| Project requirements (policy)    | (lives in `CLAUDE.md` text)                              | `requirements.toml` `[session]`/`[policy]`/`[models]`                     | (no equivalent file; encode in `GEMINI.md` text + `policyPaths` for hard policy)     |
| Custom sandbox profile           | —                                                        | `sandbox_mode` only                                                       | `.gemini/sandbox-macos-custom.sb`, `.gemini/sandbox.Dockerfile` referenced from JSON |
| Read denial of secret files      | `permissions.deny` `Read(./.env)`                        | (file gating is sandbox-implicit)                                         | `context.fileFiltering.customIgnoreFilePaths`; `.geminiignore`                       |
| Developer instruction text       | (lives in `CLAUDE.md`)                                   | `developer_instructions = """..."""`                                      | (lives in `GEMINI.md`; no inline-string config field)                                |

**Three-tool clean-mapping count (Claude ↔ Codex ↔ Gemini all
present):** 5 — tool allowlist, post-edit hook, sandbox network
access, writable roots, model selection.

**Two-tool mapping (one tool gap):** ~10 — approval policy
(Codex+Gemini, Claude implicit), profiles (Codex-only), MCP servers
(Gemini-only in shipped templates), provider config (Codex+Gemini),
hook lifecycle breadth (Claude+Gemini, Codex absent), capability
roster (Claude+Codex-planned, Gemini gap unless `.gemini/.env` is
shipped), per-agent overrides (Codex+Gemini in config; Claude in
filesystem), denylist (Claude+Gemini), web-search toggle
(Codex-only), local-OSS provider (Codex-only).

**Single-tool with no parallel:** Codex `requirements.toml` policies
(no parallel in either Claude or Gemini config files); Gemini
`hooksConfig` master enable/disable toggle; Gemini `policyPaths`
external policy engine; Gemini `mcp.allowed/excluded` server-level
gating; Gemini `general.plan.*` plan-mode routing; Gemini
`context.fileFiltering` (closest analogue is Claude
`permissions.deny` `Read(...)`).

---

## Part 5 — Gemini-only capabilities that may surface Claude/Codex gaps

Items that exist in Gemini but the pack does not currently express on
the Claude or Codex side:

1. **Hook lifecycle breadth.** Gemini exposes `BeforeAgent`,
   `BeforeModel`, `AfterModel`, `BeforeToolSelection`, `PreCompress`,
   `SessionStart`, `SessionEnd`, `Notification`. Claude has hooks
   (`PostToolUse`, `PreToolUse`, `UserPromptSubmit`, etc.); Codex has
   only `post_edit_command`. **Gap:** Codex cannot mirror Claude's or
   Gemini's pre/post-prompt hooks.
2. **Policy engine** (`policyPaths` + `docs/reference/policy-engine.md`).
   Codex `requirements.toml` is the closest semantic match; Claude
   has no equivalent. If the pack ever wants enforced policies (vs.
   informational ones in CLAUDE.md), Claude is the gap.
3. **`mcpServers` config-file registration.** Codex pack templates
   ship no MCP block today; Claude registers MCP servers via
   `~/.claude.json` (user-scoped, not committed). The pack could ship
   a parallel project-scoped MCP registration on the Gemini side
   that has no equivalent in the other two tools' shipped configs.
4. **Plan mode** (`general.defaultApprovalMode = "plan"`,
   `general.plan.modelRouting`). Codex has `approval_policy` levels
   but no read-only plan mode; Claude has CLI plan mode but does not
   express it in `settings.json`.
5. **Per-tool sandbox** (`security.toolSandboxing`). Gemini-only —
   isolates individual tools, not whole process. Codex sandbox is
   process-wide; Claude has no in-config sandbox.
6. **Folder trust** (`security.folderTrust.enabled`). Gemini-only.

These are not blockers for OQ-7, but they identify where the trinity
rule "every capability one tool gains, the other two gain via their
own mechanisms" is *already* under-fulfilled and may surface as
future BD items.

---

## Part 6 — Open questions / unverifiable items

1. **Exact built-in tool names for `AfterTool` matcher.** The hooks
   reference says matchers regex-match against tool names and points
   to `docs/reference/tools.md`, but the v10 fixture work needs the
   precise names (`replace`, `write_file`, `edit`, etc.). Implementer
   should confirm against `docs/reference/tools.md` or the Tools
   Reference page (<https://geminicli.com/docs/reference/tools/>) before
   wiring `agent-post-edit-check.sh`.
2. **`agents.overrides` schema.** The reference config describes
   the field in prose only ("Override settings for specific agents,
   e.g. to disable the agent, set a custom model config, or run
   config"). The full schema lives in
   `schemas/settings.schema.json`. Implementer should fetch and
   inspect that schema before shipping a parity entry.
3. **Codex MCP support.** Codex docs (not researched here) may now
   support MCP server registration in `config.toml`. The pack's
   shipped `config.toml` does not include any MCP block, so this
   report treats Codex MCP as "not in pack templates" rather than
   "not supported by Codex." If Codex MCP support exists, the
   trinity gap closes naturally; if not, BD-060's scope expands.
4. **`AGENT_CAPABILITIES` parity mechanism.** Two viable designs for
   Gemini parity:
   - (a) Ship `.gemini/.env` containing
     `AGENT_CAPABILITIES=planning,architecture,...`. Pro: matches the
     env-var idiom. Con: `.env` files are not typically committed.
   - (b) Encode the roster in `GEMINI.md` text and rely on the
     in-repo trinity rule. Pro: no new file. Con: not
     programmatically queryable like Claude's `env` block.
   Architect decision required before BD-060 implementation.
5. **Version-pinning.** All findings reference `main` of
   `google-gemini/gemini-cli`. The `v0.3.0` migration note in the
   reference config is the only explicit version anchor. The pack
   should record the doc-revision SHA at the moment of shipping
   parity (e.g. cite the commit hash of `docs/reference/configuration.md`
   that the parity work was based on) so future audits can detect
   schema drift.
