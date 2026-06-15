# RESEARCH-BD-221 — Antigravity Docs: Raw Playwright Captures

**This document is raw Playwright doc captures for the BD-221 architect —
primary-source text, not analysis.** Each section below is the rendered text
of a JS-gated documentation page that prior `curl`-based research could not
read (the pages return only an empty SPA shell to non-JS clients). Captured
with the Playwright MCP browser (`browser_navigate` + `browser_evaluate
(document.body.innerText)`); no screenshots were taken or saved.

- **Retrieval date:** 2026-06-15
- **Capture method:** Playwright MCP, rendered `document.body.innerText`
- **No images** were written to the repo; no screenshots were used.

Site-chrome nav text (Products / Use Cases / Pricing / the left doc-tree
`chevron_right` / `expand_more` markers / "On this Page" tails) has been
trimmed where it adds nothing; the substantive body text is transcribed
verbatim. Where a doc-tree listing is load-bearing (it reveals sibling pages),
it is noted.

---

## Page 1 (TOP PRIORITY) — Subagents

- **URL:** https://antigravity.google/docs/subagents
- **Title:** Google Antigravity Documentation
- **Doc-tree location:** Antigravity 2.0 > Agent Capabilities > Subagents
  (siblings under Agent Capabilities: Permissions, Subagents, Artifacts).
- **Retrieved:** 2026-06-15 — rendered fully.

### Key answer to the BD-221 question (custom-subagent authoring contract)

**There is NO file-based custom-subagent authoring contract on this page.**
The Antigravity 2.0 subagent model is **runtime / tool-based**, not a
`agent.json`-file or per-project markdown-file model:

- The parent agent spawns subagents at runtime via the **`invoke_subagent`**
  tool.
- Custom subagents are defined **dynamically at runtime** via the
  **`define_subagent`** tool — "Agents can define their own custom subagents
  dynamically using the `define_subagent` tool." Scope: "Once defined, the
  custom subagent can be invoked repeatedly for the remainder of the
  conversation" (i.e., conversation-scoped, NOT a persisted on-disk agent
  file).
- There is **no mention of `agent.json`, no markdown agent file, and no
  loose per-project agent directory** on this (Antigravity 2.0) page. (The
  separate CLI "Plugins & Skills" page — Page 3 — DOES list an optional
  `agents/` template directory INSIDE a plugin bundle; see that section. That
  is the only file-based "agents" surface found, and it lives inside a
  plugin, not as a loose per-project agent.)

### Transcribed body text

Asynchronous Subagents

Subagents are an excellent way to parallelize complex tasks and preserve the
context of your main agent. Instead of executing every step serially, an agent
can delegate tasks—such as running tests or performing extensive codebase
searches—to dedicated subagents. This architecture frees the parent agent to
continue working on other tasks in parallel and prevents its context window
from being polluted by the details of a subagent's work.

**Invoking Subagents**

The parent agent calls the `invoke_subagent` tool to spawn a new concurrent
session with a dedicated role and initial prompt.

- **Workspace Options:** The subagent can either inherit the same workspace as
  its parent or create an isolated Git worktree.
- **Context Isolation:** The subagent runs using the same model as its parent
  but does not inherit the parent's existing conversation history (context
  window), starting with a clean slate.
- **Execution:** Once invoked, the subagent immediately begins executing its
  task. A parent agent can invoke multiple subagents at any time.
- **Monitoring:** You can directly monitor the progress of any subagent by
  clicking into its conversation via the subagent panel.

**Subagent Lifecycle and States**

Subagents run asynchronously in the background, allowing the parent agent to
delegate a task and immediately resume its own work. At any point, a subagent
exists in one of three states:

1. **Running** — The subagent is actively executing its task, calling tools,
   and generating responses.
   - Cancellation: You can cancel a running subagent by clicking the Stop
     Subagent button in the subagent panel. This instantly cancels generation
     and transitions the subagent to an idle state.
   - Parent Control: The parent agent can also interrupt a subagent (by
     sending a message) or kill it entirely.
2. **Idle** — The subagent has completed its task, sent a message containing
   the results to its parent agent, and stopped execution.
   - Re-awakening: An idle agent can be awoken and return to the Running state
     upon receiving a message from another agent (it does not have to be its
     parent).
   - Context Retention: When awoken, the agent retains all context from its
     prior work.
3. **Killed** — The subagent is permanently terminated and cannot be
   re-awoken.
   - Cleanup: Any temporary Git worktrees generated for the subagent are
     automatically cleaned up.
   - Visibility: You and other agents can still view the historical
     conversation transcript of a killed subagent.

**Inter-Agent Communication**

Agents communicate by sending messages to each other using unique agent IDs.

- Flexible Routing: Agents can communicate not only with their direct parents
  or subagents, but also with any other active agent whose ID is known.
- Auto-Wake: If an idle agent receives a message, it is automatically
  re-awakened to process the new information.
- Shared Transcripts: Agents can view each other's conversation transcripts,
  providing a comprehensive view of the collaborative workflow.

**Built-In vs. Custom Subagents**

Built-In Subagents — Antigravity comes pre-packaged with several specialized
subagents:

- **research:** Optimized for codebase research, navigation, and exploration.
- **browser:** Operates sandboxed web browsers to perform interactive browser
  tasks (invoked exclusively via the `/browser` slash command).
- **self:** A direct clone of the calling agent, sharing the identical system
  prompt and toolsets.

Custom Subagents — Agents can define their own custom subagents dynamically
using the `define_subagent` tool.

- Configuration: Define a custom system prompt and specific toolsets for
  read-only, write (including running terminal commands), and subagent
  delegation capabilities.
- Scope: Once defined, the custom subagent can be invoked repeatedly for the
  remainder of the conversation.

**Delegation Hierarchy and Limits**

Subagents can invoke their own subagents, enabling multiple layers of
delegation and hierarchical team structures.

> warning — Nesting Depth Limit: A maximum nesting depth of 10 levels (layers
> of subagents beneath the main agent) is strictly enforced to prevent runaway
> resource exhaustion.

**Permissions and Configuration Inheritance**

Subagents inherit their parent's safety configurations to maintain robust
security boundaries:

- Inherited Scopes: Subagents automatically inherit the parent's allowed
  terminal command prefixes and file read/write directory scopes. A subagent
  cannot perform any action that the user has not already approved for the
  parent.
- Workspace Access: Parent agents retain full access to their subagents'
  workspaces, including those operating on isolated Git worktrees.
- Permission Bubbling: If a subagent encounters a tool call that requires
  explicit user confirmation, the request is automatically bubbled up to the
  subagent panel UI for your approval.

**Multi-Agent Teamwork (Ultra Plan Only)**

Antigravity 2.0 introduces advanced multi-agent orchestration for extremely
complex tasks.

> star — Ultra Plan Exclusive: The `/teamwork-preview` slash command is
> currently in preview and is exclusive to users on the Ultra ($200/mo) plan.

Using `/teamwork-preview` prompts the main agent to launch a collaborative
multi-agent framework. This framework features built-in error recovery,
automatic retries, and coordination logic, allowing you to simply define the
high-level goal while the platform manages the overhead of a cooperative agent
team.

---

## Page 2 — Gemini → Antigravity Migration

- **URL:** https://antigravity.google/docs/gcli-migration
- **Title:** Google Antigravity Documentation
- **Doc-tree location:** Antigravity CLI > Gemini Migration.
- **Retrieved:** 2026-06-15 — rendered fully.

### Key answers to the BD-221 questions

- **Exact migration command:** `agy plugin import gemini`
  (manual conversion of legacy Gemini extensions → native Antigravity
  plugins). There is ALSO an automatic first-launch onboarding flow:
  running `agy` for the first time in an environment with legacy configs
  auto-detects existing profiles and shows an interactive migration
  checklist.
- **Old → new path-mapping table** (settles `~/.gemini/...` paths):

  | Configuration | Gemini CLI | Antigravity CLI |
  |---|---|---|
  | Global shared skills path | `~/.gemini/skills/` | `~/.gemini/antigravity-cli/skills/` |
  | Workspace project skills path | `.gemini/skills/` | `.agents/skills/` |
  | Global MCP servers | `~/.gemini/settings.json` (inline) | `~/.gemini/config/mcp_config.json` |
  | Workspace MCP servers | (inline in settings) | `.agents/mcp_config.json` |
  | Workspace context/rules files | `GEMINI.md`, `AGENTS.md` (unchanged) | `GEMINI.md`, `AGENTS.md` (unchanged) |
  | Global developer context | `~/.gemini/GEMINI.md` (unchanged) | `~/.gemini/GEMINI.md` (unchanged) |

  **IMPORTANT DISCREPANCY (flag for architect):** This migration page gives the
  global MCP path as **`~/.gemini/config/mcp_config.json`**, and the IDE/editor
  MCP page (Page 6) ALSO gives `~/.gemini/config/mcp_config.json`. BUT the CLI
  "Plugins & Skills" page (Page 3) and the CLI "Features" page give the CLI
  global MCP path as **`~/.gemini/antigravity-cli/mcp_config.json`**. The docs
  are internally inconsistent on the CLI-side global MCP path. The
  `~/.gemini/config/mcp_config.json` form appears on the migration page and the
  IDE page; the `~/.gemini/antigravity-cli/mcp_config.json` form appears on the
  CLI plugins + CLI features pages. See Pages 3 and 6 for verbatim text.

- **"Breaking behaviors" / Action-Required / Partial-parity callouts:**
  - **Partial Parity (info callout):** "While we preserve support for
    workspace skills, rules, and MCP servers, certain customized terminal
    themes or experimental visual overlays from Gemini CLI may not be
    supported."
  - **Action Required (warning callout) — workspace skills path move:** "If
    your project contains custom workspace skills defined in `.gemini/skills/`,
    you must manually rename or relocate the folder to `.agents/skills/` for
    the Antigravity agent to recognize them as active slash commands."
  - **MCP schema key change:** legacy `url` or `httpUrl` → modern `serverUrl`
    (must be updated manually when migrating remote websocket/SSE servers).

### Transcribed body text

Migrating from Gemini CLI

Convert your legacy configurations, import Gemini CLI extensions as native
plugins, adapt custom skills paths, and reformat Model Context Protocol
configurations.

**Overview** — Antigravity CLI preserves backward compatibility with the core
developer-experience constructs popularized by Gemini CLI. To ensure a seamless
upgrade, the CLI offers automatic onboarding conversion alongside explicit CLI
migration command sequences.

**First-launch onboarding** — When you execute `agy` for the first time in an
environment containing legacy configurations, the CLI automatically detects
your existing profiles. An interactive checklist prompts you to choose which
assets to migrate:

- Auto-conversion: Select the extensions and global configurations you wish to
  convert.
- Keyring storage: The CLI migrates your active session tokens securely into
  your operating system's native keyring storage.
- Settings alignment: Default visual parameters and rendering buffers map
  automatically to your new settings profile.

> info — Partial Parity: While we preserve support for workspace skills, rules,
> and MCP servers, certain customized terminal themes or experimental visual
> overlays from Gemini CLI may not be supported.

**Converting extensions to plugins** — Since Gemini CLI launched, the industry
has standardized on the term plugins. You can manually convert your legacy
Gemini extensions to native Antigravity plugins by executing:

```bash
agy plugin import gemini
```

This utility searches your legacy local directories, parses your extension
manifests, and converts files into native layout blocks.

Expected import output:

```text
[ok]   conductor-tools
       - skills     : skipped (none detected)
       - agents     : skipped (none detected)
       ✔ commands   : 4 legacy commands converted to skills
       - mcpServers : skipped (none detected)
[ok]   google-workspace
       ✔ skills     : 5 skills processed
       - agents     : skipped (none detected)
       ✔ commands   : 2 legacy commands converted to skills
       ✔ mcpServers : 1 server definition migrated to mcp_config.json
```

**Context files and workspace rules** — Both CLI platforms utilize identical
workspace context rules. No modifications are needed to your existing rule
documents:

- Workspace local context: The agent continues to parse and enforce rule
  constraints defined inside your active directory's `GEMINI.md` and
  `AGENTS.md` files.
- Global developer context: The agent automatically consults and enforces your
  global constraints located at `~/.gemini/GEMINI.md`.

**Updated skills paths** — While global shared skills remain in your user home
directory, the target folder path for local workspace-specific skills has been
updated.

| Configuration | Gemini CLI | Antigravity CLI |
|---|---|---|
| Global shared path | `~/.gemini/skills/` | `~/.gemini/antigravity-cli/skills/` |
| Workspace project path | `.gemini/skills/` | `.agents/skills/` |

> warning — Action Required: If your project contains custom workspace skills
> defined in `.gemini/skills/`, you must manually rename or relocate the folder
> to `.agents/skills/` for the Antigravity agent to recognize them as active
> slash commands.

**MCP config formatting changes** — Antigravity CLI separates Model Context
Protocol servers into dedicated, lightweight JSON profiles instead of nesting
them inside your primary preferences configuration.

Directory mapping:
- Legacy Gemini Config: Servers were declared inline within
  `~/.gemini/settings.json`.
- Antigravity CLI Config: Servers are defined inside a standalone
  `mcp_config.json` profile:
  - Global servers: `~/.gemini/config/mcp_config.json`
  - Workspace servers: `.agents/mcp_config.json`

Required schema updates — When manually migrating remote websocket or SSE
server definitions, update the URI key parameter to match the current standard:
- Legacy schema keys: `url` or `httpUrl`
- Modern schema key: `serverUrl`

```json
{
  "mcpServers": {
    "remote-indexer": {
      "serverUrl": "https://mcp.internal.enterprise.com/sse",
      "env": {
        "AUTH_TOKEN": "secure_alpha_token"
      }
    }
  }
}
```

Next steps: Settings/Rendering & Keybindings; Troubleshooting; CLI Reference.

---

## Page 3 — CLI Plugins & Skills (plugin.json manifest schema)

- **URL:** https://antigravity.google/docs/cli-plugins
- **Title:** Google Antigravity Documentation
- **Doc-tree location:** Antigravity CLI > Customizations > Plugins & Skills
  (siblings under Customizations: Plugins & Skills, Status Line, Window Title).
- **Retrieved:** 2026-06-15 — rendered fully.

### Key answers to the BD-221 questions (plugin bundle layout)

A plugin is a namespaced bundle staged at
`~/.gemini/antigravity-cli/plugins/<plugin_name>/`. Compliant layout:

```text
~/.gemini/antigravity-cli/plugins/<plugin_name>/
├── plugin.json                 # Required package marker file
├── mcp_config.json             # Optional Model Context Protocol servers
├── hooks.json                  # Optional pre/post tool event hooks
├── skills/                     # Optional specialized skills directory
├── agents/                     # Optional subagent definition templates
└── rules/                      # Optional custom codebase rules files
```

- **Required vs optional:** `plugin.json` is the ONLY required file ("Required
  package marker file"). Everything else — `mcp_config.json`, `hooks.json`,
  `skills/`, `agents/`, `rules/` — is **Optional**.
- **How `agents/` templates are declared:** the `agents/` subdirectory is
  described only as "Optional subagent definition templates" — the page does
  NOT give an inner schema for an individual agent template file, nor a file
  extension, nor required fields for one. (No `agent.json` schema is given;
  the only schema-named file is the plugin-level `plugin.json`, whose internal
  field schema is ALSO not enumerated on this page — it is called a "marker
  file.")
- **Local workspace skills** live in `.agents/skills/` at project root, each a
  `.md` file with frontmatter (`name`, `description`); they auto-compile to
  slash commands (e.g., `/format-tests`).
- **Global skills** live in `~/.gemini/antigravity-cli/skills/`.
- **Plugin management subcommands:** `agy plugin list`,
  `agy plugin install /path/to/local/plugin`, `agy plugin disable <name>`,
  `agy plugin enable <name>`, `agy plugin uninstall <name>`.
- **CLI global MCP path stated here:** `~/.gemini/antigravity-cli/mcp_config.json`
  (NOTE: differs from the migration page's `~/.gemini/config/mcp_config.json`
  — see Page 2 discrepancy note).
- **Workspace MCP path:** `.agents/mcp_config.json`.
- **Remote MCP schema:** must use `serverUrl`; legacy `url`/`httpUrl` not
  supported.

### Transcribed body text

Plugins & skills — Extend agent capabilities, install third-party extension
bundles, package custom workflow skills, and interface with Model Context
Protocol (MCP) servers.

The extensibility model — Antigravity CLI is designed for limitless
customization. You can augment the shared agent harness by installing
structured package modules called Plugins or creating localized markdown
blueprints called Skills. These customizations allow agents to access
specialized proprietary commands, invoke domain-specific subagents, and consult
customized style constraints.

Antigravity plugins — Plugins are namespaced bundles that package custom
skills, background subagents, linting rules, Model Context Protocol
definitions, and event hooks into a single deployable asset.

Plugin filesystem structure — When you install or import a plugin, the CLI
stages the bundle files within your global configuration path:
`~/.gemini/antigravity-cli/plugins/<plugin_name>/` (layout box reproduced
above).

Managing plugins via CLI subcommands — The CLI exposes a `plugin` (or plural
`plugins`) subcommand pipeline to manage your extensions:
- List installed plugins: `agy plugin list`
- Install a local or remote plugin: `agy plugin install /path/to/local/plugin`
- Disable/Enable a plugin: `agy plugin disable <plugin_name>` /
  `agy plugin enable <plugin_name>`
- Uninstall a plugin: `agy plugin uninstall <plugin_name>`

Agent skills — Skills are declarative, human-readable markdown files that
outline explicit instruction protocols, scripts, and target resources for
specialized engineering tasks. Once registered, Skills convert automatically
into slash commands inside the TUI (e.g., `/refactor-ui`).

Creating local workspace skills:
1. Create a directory named `.agents/skills/` at your project root.
2. Inside, draft a markdown file with a `.md` extension (such as
   `format-tests.md`).
3. Define the skill's Frontmatter metadata:
   ```
   ---
   name: format-tests
   description: Standardize and re-format Python unittest assertions
   ---
   ```
   Below the metadata, write explicit instructions for the agent. When you run
   `agy` in this directory, the skill is compiled, and `/format-tests` becomes
   available in the prompt box.

Sharing global skills — place markdown files inside
`~/.gemini/antigravity-cli/skills/`; any markdown skill there is automatically
imported as a global slash command whenever you launch `agy` in any directory.

Managing hooks — Hooks intercept agent actions right before or immediately
after execution (e.g., running prettier after writing files). Hooks are defined
inside a plugin's `hooks.json` or configured inside your primary `settings.json`
file. Inspect loaded/active hooks in the TUI by typing `/hooks`.

Model Context Protocol (MCP) — Antigravity CLI supports both local processes
and remote host MCP server configurations. Type `/mcp` to open the interactive
MCP Manager Overlay (view live status rings; reload server configs; check
connection logs).

Global and workspace server configs:
- Global server setups: `~/.gemini/antigravity-cli/mcp_config.json`
- Workspace local setups: `.agents/mcp_config.json`

```json
{
  "mcpServers": {
    "sqlite-explorer": {
      "command": "node",
      "args": ["/usr/local/bin/sqlite-mcp-server.js"],
      "env": { "SQLITE_DB_PATH": "/var/data/app.db" }
    }
  }
}
```

> warning — Remote Connection Schema: When declaring remote SSE or
> websocket-based MCP connections, you must define the `serverUrl` field.
> Legacy fields like `url` or `httpUrl` are not supported.

---

## Page 4 — CLI Permissions (permissions schema + DENY git verbs)

- **URL:** https://antigravity.google/docs/cli-permissions
- **Title:** Google Antigravity Documentation
- **Doc-tree location:** Antigravity CLI > Agent Capabilities > Permissions
  (siblings: Subagents, Permissions, Sandbox).
- **Retrieved:** 2026-06-15 — rendered fully.

### Key answers to the BD-221 questions

- **Where the permissions schema lives:** global settings at
  `~/.gemini/antigravity-cli/settings.json`, under a top-level `permissions`
  object with three lists: `allow`, `deny`, `ask`.
- **Permission resource format:** `action(target)`.
- **Three access levels:** `deny` (blocked immediately), `ask` (pauses for
  explicit approval), `allow` (auto-approved).
- **Precedence:** **Deny > Ask > Allow** (a deny always wins; an ask beats an
  allow).
- **How to DENY commit/git verbs:** use the `command(prefix)` action in the
  `deny` list. Each whitespace-separated token is an anchored regex
  (`^(?:pattern)$`); matching is by token prefix. So:
  - `command(git commit)` denies `git commit ...`
  - `command(git push)` denies `git push ...`
  - To deny ALL git: `command(git)` (matches commands whose first token is
    `git`). The docs' own example uses `command(git)` in the ALLOW list to
    allow all git; placing `command(git)` in DENY blocks all git (Deny >
    Allow). The example config shows `command(rm -rf)`, `command(sudo)`,
    `command(curl .*)`, `write_file(.git/)` in the deny list.
  - NOTE: there is no dedicated "git" action type; git verbs are denied as
    `command(...)` prefixes, OR by denying writes to `.git/` via
    `write_file(.git/)` (deny-read-implies-deny-write applies).
- **Default fallbacks:** read_file/write_file = Ask (auto-allowed inside
  workspace); read_url/execute_url = Ask; command = Ask; unsandboxed = Ask;
  mcp = Ask. Unconfigured actions default to Ask.

### Supported actions table (verbatim columns: Action | Target Format | Matching Behavior | Default Fallback)

- **read_file** — `read_file(/path)`, `read_file(dir)`, or `read_file(*)` —
  Matches absolute paths or paths relative to workspace roots. Grants recursive
  read access to all contained files/folders. `read_file(*)` matches all files
  on the system. — Default: Ask (Auto-allowed in workspace).
- **write_file** — `write_file(/path)` or `write_file(*)` — Same as read_file.
  Implicitly grants read_file for the exact same target path. — Default: Ask
  (Auto-allowed in workspace).
- **read_url** — `read_url(domain)` or `read_url(*)` — Matches hostnames and
  subdomains (e.g., `google.com` covers `mail.google.com`). Ignores URL path
  segments. `read_url(*)` matches any domain. — Default: Ask.
- **execute_url** — `execute_url(domain)` or `execute_url(*)` — Actuating on
  web elements (clicking, typing) or driving interactive browser workflows on a
  domain. — Default: Ask.
- **command** — `command(prefix)`, `command(regex)`, or `command(*)` — Matches
  commands by exact word/token prefix. Each whitespace-separated token is
  evaluated as an anchored regular expression `^(?:pattern)$`. E.g.,
  `command(npm run (build|lint|test))` matches `npm run build` and
  `npm run test`. — Default: Ask.
- **unsandboxed** — `unsandboxed(prefix)` or `unsandboxed(*)` — Matches
  commands by exact word/token prefix. Commands matching this grant execute
  outside container isolation (only applicable when terminal sandboxing is
  enabled). — Default: Ask.
- **mcp** — `mcp(server/tool)` or `mcp(*)` — Matches exact MCP tools or all
  tools on a specified server (applies to local mcpl servers and remote
  connections). `mcp(*)` matches any tool. — Default: Ask.

Global wildcard `*` (e.g., `read_file(*)`, `command(*)`, `mcp(*)`) matches all
targets in that action namespace.

Implicit permission rules:
- Write implies Read: allowing `write_file` on a path auto-grants `read_file`.
- Deny Read implies Deny Write: denying `read_file` on a path blocks
  `write_file` on it.

Cross-platform path normalization: macOS/Linux use forward slashes; on Windows
Antigravity strips drive letters (`C:`) and converts backslashes to forward
slashes before rule evaluation.

Default system behaviors & guardrails:
- Workspaces are Auto-Allowed (read/write inside the active project dir).
- Web Browsing Defaults to Ask (read_url/execute_url).
- Unconfigured Actions Default to Ask (command, mcp, execute_url, non-workspace
  files).

Interactive permission prompts: an Ask-mode operation shows a prompt card in
the TUI. You may edit the target string to broaden scope (e.g.,
`/project/file.txt` → parent dir `/project`); the CLI validates the edited
target safely covers the operation. Scope editing is NOT supported for terminal
commands.

> Precedence Rule (warning callout): Conflicting rules are strictly evaluated
> in priority order: Deny > Ask > Allow. For example, if you configure
> `command(*)` in your ask list and `command(git)` in your allow list, the ask
> rule takes precedence and prompts before every command.

### Configuration example (verbatim — add to `~/.gemini/antigravity-cli/settings.json`)

```json
{
  "permissions": {
    "allow": [
      "command(git)",
      "command(npm run (build|lint|test))",
      "unsandboxed(git push)",
      "read_file(/var/log/app)",
      "write_file(src/)",
      "read_url(google.com)",
      "mcp(linter/*)"
    ],
    "deny": [
      "command(rm -rf)",
      "command(curl .*)",
      "command(sudo)",
      "write_file(.git/)",
      "write_file(/home/user/.ssh)"
    ],
    "ask": [
      "command(*)",
      "execute_url(aws.amazon.com)",
      "mcp(sql/execute_mutation)"
    ]
  }
}
```

---

## Page 5a — CLI Features (slash commands, plugins, subagents, sandbox)

- **URL:** https://antigravity.google/docs/cli-features
- **Title:** Google Antigravity Documentation
- **Doc-tree location:** Antigravity CLI > Features.
- **Retrieved:** 2026-06-15 — rendered fully.

### Key answers

- **Plugin layout (restated, with a `import_manifest.json` not shown on Page 3):**
  ```text
  ~/.gemini/antigravity-cli/
  ├── plugins/
  │   └── <plugin_name>/
  │       ├── plugin.json         # Required marker file
  │       ├── mcp_config.json     # Optional MCP server definitions
  │       ├── hooks.json          # Optional event hooks definition
  │       ├── skills/             # Optional skills
  │       ├── agents/             # Optional subagents
  │       └── rules/              # Optional rules
  └── import_manifest.json        # Tracking manifest
  ```
- **Terminal Sandbox:** native OS isolation — `nsjail` (Linux),
  `sandbox-exec` (macOS), `AppContainer` (Windows). Config key
  `enableTerminalSandbox` (boolean, default `false`) in
  `~/.gemini/antigravity-cli/settings.json`. Launch override `--sandbox`.
- **Subagents in the CLI:** the main agent automatically spawns subagents; "The
  main agent decides what tools and permissions subagents get, including
  whether they can use MCP tools and if they can write files." Manage via the
  `/agents` panel. Fast-path approval shortcuts: `ctrl+j` teleport to next
  subagent awaiting approval; `ctrl+k` approve a pending subagent permission.

### Slash command list (verbatim — Core Slash Commands table)

| Command | Category | Purpose |
|---|---|---|
| `/resume` (alias `/switch`) | Conversation | Open the conversation picker to resume or switch sessions. |
| `/rewind` (alias `/undo`) | Conversation | Roll back conversation history to a previous checkpoint. |
| `/rename <name>` | Conversation | Rename the active conversation thread. |
| `/permissions` | Configuration | Select agent autonomy level (request-review, always-proceed, or strict). |
| `/model` | Configuration | Select the default reasoning model (persists across sessions). |
| `/keybindings` | Configuration | Open the interactive keyboard shortcut editor. |
| `/statusline` | Configuration | Customize real-time indicators in the status bar. |
| `/tasks` | Tools & Monitoring | Monitor, view logs for, or terminate active background tasks. |
| `/skills` | Tools & Monitoring | Browse local and global encapsulated agent workflows. |
| `/mcp` | Tools & Monitoring | Open the panel to configure/manage MCP servers. |
| `/open <path>` | Utility | Open a file in your preferred external editor. |
| `/usage` | Utility | Open the inline interactive help manual in the terminal. |
| `/logout` | Account | Log out of your Google session and clear cached credentials. |

(Note: a fuller slash-command list including `/diff`, `/agents`, `/fork`,
`/btw`, `/add-dir`, `/config`, `/fast`, `/planning`, `/title` appears on the CLI
Reference page — see Page 5c.)

Advanced settings.json customization example (fine-grained permissions):
```
"permissions": {
  "allow": ["command(git)", "command(npm test)"],
  "deny": ["command(rm -rf)"]
}
```

---

## Page 5b — CLI Overview

- **URL:** https://antigravity.google/docs/cli-overview
- **Title:** Google Antigravity Documentation
- **Doc-tree location:** Antigravity CLI > Overview.
- **Retrieved:** 2026-06-15 — rendered fully.

### Key answers

- Conceptual page. Antigravity CLI = the keyboard-driven TUI surface; shares
  the same agent harness AND **shared settings sync** with Antigravity 2.0
  (desktop): "Updating a permission rule or standard configuration in one
  platform immediately updates the other." (Relevant: a permission rule set in
  the CLI also affects the desktop and vice versa.)
- Successor to Gemini CLI; one-time import migrates Gemini CLI extensions,
  skills, settings (links to the Gemini Migration page = Page 2).
- **No worktree text and no `agy` subcommand list on this page** (those live on
  the subagents page + the desktop Getting-Started page; see Page 5d).

### Transcribed (condensed) body text

The Antigravity CLI is the lightweight Terminal User Interface (TUI) surface of
Antigravity. It brings the same core agentic capabilities as Antigravity 2.0
(multi-step reasoning, multi-file editing, tool calling, conversation history)
to the terminal. Platform-comparison table contrasts CLI (keyboard TUI,
near-zero overhead, SSH/tmux/headless) vs Antigravity 2.0 (visual desktop
IDE). Integration features: Shared agent harness; Shared settings sync (core
preferences, permissions, security configs synchronize automatically across
both interfaces); Conversation export (move active conversations between
platforms). Migrating from Gemini CLI: one-time import of Gemini CLI
extensions, skills, settings.

---

## Page 5c — CLI Reference (full slash-command list + settings.json keys)

- **URL:** https://antigravity.google/docs/cli-reference
- **Title:** Google Antigravity Documentation
- **Doc-tree location:** Antigravity CLI > Reference. (Captured as a bonus page
  because it carries the authoritative slash-command + settings.json tables the
  prompt asked about.)
- **Retrieved:** 2026-06-15 — rendered fully.

### Full slash-command list (verbatim — Command | Category | Alias | Purpose)

| Command | Category | Alias | Purpose |
|---|---|---|---|
| `/add-dir <path>` | Utilities | — | Add a directory path to the active workspace. |
| `/agents` | Tools & Tasks | — | Open the Agent Manager Panel to monitor background subagents. |
| `/btw <query>` | Utilities | — | Ask a side question in the background without interrupting the main conversation. |
| `/clear` | Utilities | — | Clear the terminal and reset active conversation contexts. |
| `/config` | Configurations | `/settings` | Open the interactive Settings Editor Overlay. |
| `/diff` | Utilities | — | Show unified diff representations of all modified workspace files. |
| `/exit` | Core | — | Close the TUI session and restore your host shell. |
| `/fast` | Configurations | — | Enable fast mode (bypass reasoning plans) for quick actions. |
| `/fork` | Conversations | `/branch` | Clone the current conversation thread into a new parallel session. |
| `/hooks` | Tools & Tasks | — | Browse active pre-flight/post-format script hooks. |
| `/keybindings` | Configurations | — | Open the interactive Keyboard Shortcut Editor. |
| `/logout` | Account | — | Disconnect your profile and purge authentication tokens from the keyring. |
| `/mcp` | Tools & Tasks | — | Open the MCP server manager. |
| `/model` | Configurations | — | Choose your preferred reasoning model (persists across sessions). |
| `/open <path>` | Utilities | — | Force the path to open inside your default system editor. |
| `/permissions` | Configurations | — | Switch between global permission presets (request-review, always-proceed, strict). |
| `/planning` | Configurations | — | Enable multi-turn plan generation mode for complex tasks. |
| `/rename <name>` | Conversations | — | Rename the current session thread. |
| `/resume` | Conversations | `/switch`, `/conversation` | Open the conversation picker overlay. |
| `/rewind` | Conversations | `/undo` | Roll back conversation history to a previous message. |
| `/skills` | Tools & Tasks | — | Browse loaded local and global Agent Skills. |
| `/statusline` | Configurations | — | Open the Status Bar customization overlay. |
| `/tasks` | Tools & Tasks | — | Open the Task Manager Panel to monitor background shell execution logs. |
| `/title [on/off]` | Configurations | — | Toggle or set terminal window title updates. |
| `/usage` | Utilities | — | Launch the offline developer help manual inside the terminal. |

### settings.json configuration keys (verbatim — Key | Type | Default | Options)

- `colorScheme` — string — `"terminal"` — light / solarized light /
  colorblind-friendly light / dark / solarized dark / colorblind-friendly dark
  / tokyo night / terminal.
- `altScreenMode` — string — `"default"` — default (inline) / always
  (altscreen no-flicker buffer).
- `toolPermission` — string — `"request-review"` — **Global safety presets:**
  `request-review` (prompts for write/bash/web tools), `proceed-in-sandbox`
  (auto-proceed inside sandbox), `always-proceed` (never prompts), `strict`
  (prompts for ALL non-read tools).
- `artifactReviewPolicy` — string — `"asks-for-review"` — asks-for-review
  (always prompts before writing code) / agent-decides / always-proceed.
- `notifications` — boolean — `false`.
- `showTips` — boolean — `true`.
- `showFeedbackSurvey` — boolean — `true`.
- `editor` — string — `"auto"` — auto ($EDITOR) / vim / emacs / custom.
- `allowNonWorkspaceAccess` — boolean — `false` — permits file read/write
  outside Git/workspace roots.
- `enableTerminalSandbox` — boolean — `false` — OS containment for all local
  agent execution.
- `enableTelemetry` — boolean — `true`.
- `verbosity` — string — `"high"` — high / low.
- `runningLightSpeed` — string — `"medium"` — fast / medium / slow / off.

Launch flag overrides noted on the Using-AGY page: `--sandbox`,
`--dangerously-skip-permissions`.

---

## Page 5d — Getting Started with Antigravity 2.0 (Worktree feature)

- **URL requested:** https://antigravity.google/docs/cli-installation — this
  **redirected to** `https://antigravity.google/docs/getting-started` (the
  Antigravity 2.0 desktop Getting-Started page). Captured because it carries
  the **"New Worktree Mode"** text the prompt asked for.
- **Title:** Google Antigravity Documentation
- **Retrieved:** 2026-06-15 — rendered fully.

### Key answers (Worktree feature)

When you start an agent on a Project you choose a Mode in the setup modal:
- **Local Mode:** the agent operates directly in your active folders.
- **New Worktree Mode:** the agent operates in an **isolated Git worktree**.

(The subagents page — Page 1 — adds the auto-cleanup behavior: temporary Git
worktrees generated for a subagent are automatically cleaned up when the
subagent is killed; parent agents retain full access to subagents' worktree
workspaces. No explicit "diff post-back" wording was found on any captured
page; the closest surface is the `/diff` slash command on Page 5c, which shows
unified diffs of all modified workspace files, and the Ctrl+R "open_review"
Artifact Review Panel on Page 5e.)

### Transcribed (condensed) body text

Creating a Project — Agents work within Projects, which define the boundaries
of the folders and repositories they can access. (New Project; Add Folder for
one or more local folders/Git repos; Create; optional per-Project isolated
settings + security policies.)

Starting an Agent — Type your goal; choose a Mode in the setup modal: Local
Mode (agent operates directly in your active folders) or New Worktree Mode
(agent operates in an isolated Git worktree).

Desktop Slash Commands: `/goal` (run until task fully finished, no intermediate
input), `/grill-me` (ask clarifying questions before implementing), `/schedule`
(one-time future timer or recurring schedule via Scheduled Tasks), `/browser`
(explicit opt-in for browser use; requires Google Chrome + user-granted
debugging session).

---

## Page 5e — Using AGY CLI (settings/keybindings/quick tips)

- **URL:** https://antigravity.google/docs/cli-using
- **Title:** Google Antigravity Documentation
- **Doc-tree location:** Antigravity CLI > Using AGY CLI.
- **Retrieved:** 2026-06-15 — rendered fully.

### Key answers

- Settings file: `~/.gemini/antigravity-cli/settings.json`; settings panel via
  `/config` or `/settings`.
- Launch flag overrides: `--sandbox`, `--dangerously-skip-permissions`. The
  settings menu shows where an override came from.
- Keybindings file: `~/.gemini/antigravity-cli/keybindings.json` (edit via
  `/keybindings`; delete file to reset). `cli.exit` and `cli.enter` cannot be
  disabled.
- Quick tips: `@` triggers path suggestions; `esc esc` clears prompt; `!` at
  start of prompt runs a terminal command directly; `?` lists slash commands;
  `/fork` spins up a separate workspace and branches the conversation from an
  earlier point; `/clear`; `/resume`; auto-save resume prints the exact resume
  command on close.
- **No worktree section and no `agy` shell-subcommand list on this page.**

### `agy` shell-subcommand list — reconciled from all captured pages

The docs do NOT publish a single consolidated `agy <subcommand>` reference
table (the Reference page documents in-TUI SLASH commands, not shell
subcommands). The shell-level `agy` invocations actually found across pages:

- `agy` — launch the CLI TUI (and trigger first-launch onboarding/migration).
- `agy plugin import gemini` — migrate Gemini CLI extensions → plugins.
- `agy plugin list`
- `agy plugin install /path/to/local/plugin`
- `agy plugin disable <plugin_name>`
- `agy plugin enable <plugin_name>`
- `agy plugin uninstall <plugin_name>`
- (the alias `agy plugins ...` plural is mentioned as accepted)

Install (from DataCamp, Page 7): `curl -fsSL https://antigravity.google/cli/install.sh | bash`.

---

## Page 6 — MCP (Antigravity 2.0 EDITOR/IDE integration)

- **URL:** https://antigravity.google/docs/mcp
- **Title:** Google Antigravity Documentation
- **Doc-tree location:** Antigravity 2.0 > Customizations > MCP (siblings:
  MCP, Skills, Rules, Plugins, Hooks, Sidecars). **This is the EDITOR/IDE MCP
  page, NOT the CLI MCP page.**
- **Retrieved:** 2026-06-15 — rendered fully.

### Key answers to the BD-221 questions

- **Canonical global path (editor side):** "The configuration file is located
  at `~/.gemini/config/mcp_config.json`." This MATCHES the migration page's
  global path and CONFLICTS with the CLI plugins/features pages'
  `~/.gemini/antigravity-cli/mcp_config.json`. (Discrepancy flagged on Page 2.)
- **`serverUrl` vs `url` / transport rule:** Transport — exactly one required:
  `command` (string, stdio executable) OR `serverUrl` (string, URL for remote
  Streamable HTTP transport). The page uses `serverUrl` exclusively for remote
  servers; **no `url` or `httpUrl` field appears** (consistent with the
  migration page's "modern key is `serverUrl`").
- **Dropped `timeout` rule:** The full property list (below) contains **NO
  `timeout` field** — confirming `timeout` is not part of the Antigravity MCP
  schema (it was dropped vs older Gemini-era configs). Properties present:
  `command`, `serverUrl`, `args`, `env`, `cwd`, `headers`, `authProviderType`,
  `oauth`, `disabled`, `disabledTools`. No `timeout`.

### Configuration properties (verbatim)

Transport (one required):
- `command` (string): Path to the executable for stdio transport.
- `serverUrl` (string): URL for remote servers for Streamable HTTP transport.

Optional:
- `args` (string[]): Command-line arguments for stdio transport.
- `env` (object): Environment variables for the stdio server process.
- `cwd` (string): Working directory for stdio servers.
- `headers` (object): Custom HTTP headers for remote servers.
- `authProviderType` (string): Authentication provider. Supports
  `"google_credentials"` for ADC.
- `oauth` (object): OAuth client credentials (`clientId`, `clientSecret`).
- `disabled` (boolean): Temporarily disable a server without removing config.
- `disabledTools` (string[]): Tool names to not provide to the model.

Base config shape:
```json
{
  "mcpServers": {
    "serverName": {
      "command": "path/to/executable",
      "args": ["--arg1", "value1"],
      "env": { "API_KEY": "your-api-key" }
    }
  }
}
```

Authentication:
- Google Credentials: set `authProviderType` to `"google_credentials"` (uses
  ADC; run `gcloud auth application-default login`).
- OAuth: auto-handled for servers supporting dynamic client registration (DCR);
  otherwise supply `oauth.clientId` / `oauth.clientSecret`; manual-credential
  redirect URI = `https://antigravity.google/oauth-callback`. Access tokens
  stored in `~/.gemini/antigravity/mcp_oauth_tokens.json`.
- Custom Headers: add to `headers` (e.g., `Authorization: Bearer ...`).

(Editor-side connection is via the built-in MCP Store: "..." dropdown >
Manage MCP Servers > View raw config > edit `mcp_config.json`. Supported-server
list includes GitHub, GitLab Orbit, Linear, Notion, Stripe, Supabase, Neon,
BigQuery, Figma Dev Mode MCP, Chrome DevTools, Sequential Thinking, etc.)

---

## Page 7 — DataCamp tutorial (parallel subagents walkthrough)

- **URL:** https://www.datacamp.com/tutorial/antigravity-cli
- **Title:** Google Antigravity CLI: Orchestrating Parallel AI Agents | DataCamp
- **Author:** Aashi Dutt — Published May 22, 2026.
- **Retrieved:** 2026-06-15 — rendered FULLY (NOT blocked by Cloudflare;
  full article text returned via Playwright).

### Coverage note vs the BD-221 ask

The prompt expected a "parallel-subagents + worktree-isolation + permissions
walkthrough." The article DOES cover **parallel dynamic subagents** in depth
(an end-to-end `/goal` demo) and touches the **permissions human-in-the-loop**
model, but it does **NOT** contain a worktree-isolation walkthrough and does
NOT show `permissions` JSON config — its permission content is limited to the
one-time interactive approval prompt behavior under `/goal`. The strongest
value here is corroboration of the **runtime, orchestrator-defined** subagent
model (no on-disk subagent files), plus install/auth/version facts.

### Key extracted facts

- **CLI binary name:** `agy`. Self-identifies as **"Antigravity CLI 1.0.0"**.
  Default model: **Gemini 3.5 Flash (High)**.
- **Install (macOS/Linux):** `curl -fsSL https://antigravity.google/cli/install.sh | bash`
  - Windows PowerShell: `irm https://antigravity.google/cli/install.ps1 | iex`
  - Windows CMD: `curl -fsSL https://antigravity.google/cli/install.cmd -o install.cmd && install.cmd && del install.cmd`
- **Auth:** run `agy`, authenticate with a Google account or GCP project (paste
  secret key back into terminal).
- **Dynamic subagents are orchestrator-defined, NOT user-authored:**
  "Crucially, you don't define the subagents yourself. The CLI's orchestrator
  reasons about the task and decides the decomposition." The orchestrator uses
  a **`DefineSubagent`** action at runtime (the article's trace shows
  `DefineSubagent ("data_cleaner")`, `("data_analyzer")`, `("data_visualizer")`
  — names derived from the goal text). This corroborates Page 1's
  `define_subagent` runtime-tool model and the "no on-disk agent file"
  conclusion.
- **`/goal` semantics:** runs autonomously to completion without pausing for
  plan approval / intermediate confirmations. Even with `/goal`, the CLI still
  prompts ONCE for a class of bash operations (human-in-the-loop safety);
  approve once per class.
- **Other slash commands referenced:** `/grill-me` (ask clarifying questions
  first), `/schedule` (recurring auto-runs, desktop app), `/browser` (explicit
  browser opt-in), `/artifact` (open the artifact folder to review).
- **Internal scratch dir:** the orchestrator writes `implementation_plan.md` to
  an internal `~/.gemini/ant.../` scratch folder (the `.gemini` tree), NOT the
  user's project folder.
- **Ecosystem framing:** Antigravity CLI is "the successor to Gemini CLI";
  Antigravity 2.0 is an agent-first desktop platform; Managed Agents in the
  Gemini API run in persistent isolated Linux environments (Gemini 3.5 Flash).

---

## Cross-page summary of the BD-221 questions

1. **Custom-subagent authoring contract (#1):** Runtime/tool model, NOT a file
   model. Built-in subagents `research` / `browser` / `self`; custom subagents
   defined at runtime via `define_subagent` (conversation-scoped). The only
   file-based "agents" surface is the OPTIONAL `agents/` "subagent definition
   templates" directory INSIDE a plugin bundle
   (`~/.gemini/antigravity-cli/plugins/<name>/agents/`) — no `agent.json`
   schema and no loose per-project agent file is documented. Loose
   per-project agents are NOT supported; per-project customization is via
   `.agents/skills/*.md` (skills→slash commands) and `.agents/mcp_config.json`,
   plus `GEMINI.md`/`AGENTS.md` context rules.
2. **Migration (#2):** Command `agy plugin import gemini` (plus auto first-launch
   onboarding checklist on first `agy`). Path mapping table captured (Page 2).
   Breaking/parity callouts: terminal themes/visual overlays may not port
   (Partial Parity); `.gemini/skills/` MUST be moved to `.agents/skills/`
   (Action Required); MCP `url`/`httpUrl` → `serverUrl`.
   **UNRESOLVED:** global MCP path conflict —
   `~/.gemini/config/mcp_config.json` (migration + editor pages) vs
   `~/.gemini/antigravity-cli/mcp_config.json` (CLI plugins + features pages).
3. **plugin.json manifest (#3):** `plugin.json` is the ONLY required file (a
   "marker file"; its internal field schema is not enumerated in the docs). All
   of `mcp_config.json`, `hooks.json`, `skills/`, `agents/`, `rules/` are
   Optional. `agents/` = "Optional subagent definition templates" (no inner
   schema documented).
4. **Permissions (#4):** `permissions` object (`allow`/`deny`/`ask`) in
   `~/.gemini/antigravity-cli/settings.json`; `action(target)` schema; Deny >
   Ask > Allow; deny git via `command(git)` / `command(git commit)` /
   `command(git push)` (token-prefix anchored regex) and/or `write_file(.git/)`.
   Global preset key `toolPermission` (request-review / proceed-in-sandbox /
   always-proceed / strict).
5. **Slash commands / worktree / `agy` subcommands (#5):** Full slash list on
   Page 5c. Worktree = "New Worktree Mode" (isolated Git worktree) on the
   Project setup modal (Page 5d) + auto-cleanup on subagent kill (Page 1). No
   single `agy` shell-subcommand reference table exists; observed `agy`
   subcommands are the `plugin` family + bare `agy` launch.
6. **MCP (#6):** Editor global path `~/.gemini/config/mcp_config.json`;
   `command` (stdio) XOR `serverUrl` (remote); NO `timeout` field in the schema
   (dropped). (CLI-side path conflict noted in #2.)
7. **DataCamp (#7):** Rendered fully; corroborates runtime
   orchestrator-defined subagents (`DefineSubagent`), `agy` / "Antigravity CLI
   1.0.0" / Gemini 3.5 Flash (High), install command, `/goal` semantics. No
   worktree or permissions-JSON walkthrough.

### Pages that stayed unreadable

**None.** All 7 requested pages rendered fully via Playwright, plus 3 bonus
pages (CLI Reference, Getting Started/desktop, captured via the
`cli-installation` redirect). The `cli-installation` URL redirected to
`getting-started`; the Installation & Auth page itself was not separately
captured but is not load-bearing for the BD-221 questions.
