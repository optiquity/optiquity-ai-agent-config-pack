# Step 02 — CLI Tool Documentation Verification

*Report type: Phase-1 / Step 2 deliverable for V10-DESIGN-PROCESS-PLAN.md.*
*Author: pack-docs-researcher (read-only session).*
*Retrieval date for all citations: 2026-04-21.*
*Scope: verify six facts that V10-PREDESIGN.md candidate decisions depend on.*

---

## ⚠️ Findings that contradict or qualify V10-PREDESIGN.md

The following findings should be flagged in Step 1/G2 review before
downstream steps (4–7) rely on them.

### CONTRADICTION C-1 — Codex per-agent `[agents.<name>]` registration is not required and is not documented as a Codex feature

**V10-PREDESIGN.md claim (OQ-2, Part 4 touch-point inventory, Part 5 PM
chat workflow, CD-3 Step 5 of the process plan):**

> "Codex requires agents to be registered in `.codex/config.toml` in
> addition to existing as `.toml` files."
> "`.codex/config.toml` — PM chat adds `[agents.x_name]` entry"

**Actual behavior, per official docs:** Custom subagents in Codex are
defined by standalone TOML files in `.codex/agents/*.toml` (project) or
`~/.codex/agents/*.toml` (user). Codex *auto-discovers* them by scanning
those directories. The agent is identified by its `name` field inside
the TOML file; filename is convention only. **There is no requirement to
register each agent in `.codex/config.toml`, and the docs do not describe
any `[agents.<name>]` or `[agents.x_name]` per-agent registration entry
of the form the predesign describes.**

The `[agents]` table in `config.toml` exists, but it holds only
**global subagent settings**: `agents.max_threads`, `agents.max_depth`,
`agents.job_max_runtime_seconds`. It is not a per-agent registry.

- Source: "Subagents – Codex | OpenAI Developers",
  https://developers.openai.com/codex/subagents — sections "Global
  subagent settings" and "Custom agents / Agent definition files".
  Retrieved 2026-04-21.
- Quote: "To define custom agents, add standalone TOML files under
  `~/.codex/agents/` for personal agents or `.codex/agents/` for
  project-scoped agents. Each file defines one custom agent. … Codex
  identifies the custom agent by its `name` field. Matching the filename
  to the agent name is the simplest convention, but the `name` field is
  the source of truth."
- Quote: "Global subagent settings still live under `[agents]` in your
  configuration." Followed by the three global keys only.

**Implication for v10 design:**

- Step 5 resolution of OQ-2 should be revised: the "consistency scan"
  the predesign imagines ("`.toml` file exists but `[agents.x_name]`
  entry is missing, or vice versa") is chasing a non-existent
  requirement. Remove that scan from the PM-chat startup detection
  scope.
- Part 4 touch-point inventory row for `.codex/config.toml` custom agent
  registration should be revised or removed.
- The PM-chat workflow (Part 5) "adds `[agents.x_name]` entry" step
  should be removed.
- **What *is* worth specifying** in the design is a much lighter rule:
  (a) PM chat drops a `.codex/agents/x-<name>.toml` file, (b) the file
  contains a `name = "…"` field that the PM chat uses as the canonical
  agent identifier for that tool, (c) optional global-tuning changes
  in `[agents]` (max_threads/max_depth) are a separate concern, not
  per-agent.

### CONTRADICTION C-2 — Codex agent `name` field character rules are UNVERIFIED; `x-<name>` may or may not work

**Predesign/design plan assumption (implicit in CD-1):** The `x-`
prefix rule applies uniformly across Claude / Codex / Gemini, with the
only potential deviation being a possible `x_` rewrite for Codex TOML
keys.

**What docs actually say:** The only official Codex docs text about
character rules for subagent `name` is silent on allowed characters.
`nickname_candidates` is explicitly "ASCII letters, digits, spaces,
hyphens, and underscores" — but `nickname_candidates` is display-only,
not the identifier used by Codex to spawn the agent. **All documented
examples of the `name` field use `lowercase_with_underscores`
(`reviewer`, `pr_explorer`, `code_mapper`, `browser_debugger`,
`ui_fixer`, `docs_researcher`, `ui_fixer`).** No example uses a hyphen.

Separately, on TOML key conventions elsewhere in Codex config, hyphens
in *key names* are reported to cause silent failures (e.g. the
documented `mcp_servers` key; using `mcp-servers` is ignored). But the
subagent `name` is a *string value*, not a TOML key, so that constraint
does not directly apply. The question is whether Codex's runtime
accepts a hyphen inside the `name` value.

- Source: "Subagents – Codex | OpenAI Developers",
  https://developers.openai.com/codex/subagents — "Configuration
  schema" and all code examples. Retrieved 2026-04-21.
- Source (TOML key underscore convention): Vladimir Siedykh blog on
  Codex MCP config, https://vladimirsiedykh.com/blog/codex-mcp-config-toml-shared-configuration-cli-vscode-setup-2025
  — secondary source, cited only for the `mcp_servers` underscore
  requirement. Retrieved 2026-04-21.

**Status:** UNVERIFIED from official docs.

**Recommendation (empirical verification):** Before G2 is closed, run
a Codex CLI smoke test with a minimal `.codex/agents/x-test.toml`
containing `name = "x-test"`, and a parallel test with `name = "x_test"`.
Observe whether Codex discovers and invokes each variant. If the
hyphenated `name` fails:

- Option A: For Codex only, require the *filename* to be
  `x-<name>.toml` (matching Claude / Gemini) but the internal
  `name = "x_<name>"` with an underscore. Document the rewrite.
- Option B: Adopt `x_<name>` everywhere Codex is involved and accept
  asymmetry with Claude/Gemini (`x-<name>`).
- Option C: Use `x-<name>` everywhere at the filename level (which is
  documented to work for all three tools) and just note that Codex's
  internal `name =` field uses an underscore-converted form.

The three-tool trinity design should pick deliberately; the current
predesign is silent.

### CONTRADICTION C-3 — "Codex `post_edit_command`" does not exist

**V10-PREDESIGN.md / Step-2 prompt wording (Fact 6):** "Codex
`post_edit_command` and hook mechanisms."

**Actual behavior:** There is no `post_edit_command` configuration key
documented anywhere in the Codex CLI config reference, config-advanced,
subagents, or hooks pages. The closest existing mechanisms are:

- `notify` — runs an external program on events. Currently only one
  event type exists (`agent-turn-complete`). Does not fire on file
  edits or agent-file creation.
- **Experimental Hooks** (`.codex/hooks.json` or `~/.codex/hooks.json`,
  enabled with `codex_hooks = true`). Events: `SessionStart`,
  `PreToolUse`, `PermissionRequest`, `PostToolUse`, `UserPromptSubmit`,
  `Stop`. **Critically: the current runtime only emits `PreToolUse`,
  `PermissionRequest`, and `PostToolUse` for the Bash tool** — not for
  `ApplyPatch`, `Write`, or any file-edit tool (confirmed on the docs
  page and reflected in an open GitHub issue against openai/codex).

- Sources:
  - "Advanced Configuration – Codex | OpenAI Developers",
    https://developers.openai.com/codex/config-advanced — "Hooks
    (experimental)" and "notify" sections. Retrieved 2026-04-21.
  - "Hooks – Codex | OpenAI Developers",
    https://developers.openai.com/codex/hooks — events reference table
    and per-event JSON schemas. Retrieved 2026-04-21.
  - Quote (matcher/events table): "PermissionRequest: tool name.
    Current Codex runtime only emits Bash. PostToolUse: tool name.
    Current Codex runtime only emits Bash. PreToolUse: tool name.
    Current Codex runtime only emits Bash."
  - Open issue confirming the Bash-only limitation:
    https://github.com/openai/codex/issues/16732 ("ApplyPatchHandler
    doesn't emit PreToolUse/PostToolUse hook event. Hooks only fire
    for Bash tool."). Retrieved 2026-04-21.

**Implication for v10 design:**

- If the design envisions a hook that fires when a custom agent file
  is *created or modified* on disk, **no such Codex mechanism exists
  today**. The PM-chat-driven creation model (CD-3, CD-4) is the right
  model; it should not be relaxed to "the developer drops a file and
  Codex notifies the PM chat."
- Detection of manual additions (V10-PREDESIGN Part 5) must continue
  to rely on the PM-chat startup scan and phase-gate scan, not on any
  tool-emitted event. Update OQ-7 discussion accordingly.
- Cross-tool asymmetry: Claude Code has mature PostToolUse/PreToolUse
  hooks that *do* fire on Write/Edit; Codex does not; Gemini has its
  own Hooks system (see Fact 6 below). Any design that assumes
  symmetry here will misbuild one or two of the three tools.

---

## Fact-by-fact findings

### Fact 1 — Codex `config.toml` agent registration

**Question (from Step 2 prompt):** Does Codex CLI require an explicit
`[agents.<name>]` entry in `.codex/config.toml` in addition to the
`.toml` file existing in `.codex/agents/`? What are the naming rules
for agent keys (is `x_name` or `x-name` canonical in TOML keys)? What
is the failure mode if the `.toml` file exists without the config.toml
entry, and vice versa?

**Verified answers.**

1. **Registration in `config.toml` is NOT required.** Codex
   auto-discovers standalone TOML files placed in `~/.codex/agents/`
   (user) or `.codex/agents/` (project). One file per agent. The
   agent's canonical identifier is its `name` field.
   - Source: https://developers.openai.com/codex/subagents — section
     "Custom agents / Agent definition files". Quote: "To define
     custom agents, add standalone TOML files under `~/.codex/agents/`
     … Codex identifies the custom agent by its `name` field."
     Retrieved 2026-04-21.

2. **The `[agents]` section in `config.toml` exists but is for global
   subagent tuning only.** Fields: `agents.max_threads` (default 6),
   `agents.max_depth` (default 1), `agents.job_max_runtime_seconds`
   (default 1800).
   - Source: same page, section "Global subagent settings".

3. **Naming rules for the `name` field inside the agent TOML file:**
   not documented. All official examples use
   `lowercase_with_underscores`. Whether `x-foo` (hyphenated) is
   accepted at runtime is **UNVERIFIED** from docs.
   - Rec: empirical test before G2 closes. See Contradiction C-2 above.

4. **Failure modes.**
   - File in `.codex/agents/` without a matching `[agents.<name>]`
     entry in `config.toml`: *not a failure.* The agent is
     discovered and usable.
   - `[agents.<name>]` entry in `config.toml` without a corresponding
     standalone TOML file: *no such shape is documented.* The
     `[agents.<name>]` form for per-agent registration is not a
     documented Codex pattern. The predesign appears to be
     extrapolating from Claude Code's `.claude/settings.json` or
     similar — which is a different mechanism.
   - Malformed TOML in `.codex/agents/*.toml`: not explicitly
     documented; standard expectation is Codex will skip the file or
     error, but this is unverified.

**Source summary:**
- https://developers.openai.com/codex/subagents (authoritative).
- https://developers.openai.com/codex/config-advanced — confirms
  `[agents]` is global-only (section "Agent roles (`[agents]` in
  config.toml)" — explicit cross-reference: "For subagent role
  configuration (`[agents]` in config.toml), see Subagents.").

Retrieval date: 2026-04-21.

---

### Fact 2 — Claude Code skill loading

**Question:** When and how does Claude Code discover a new skill in
`.claude/skills/<name>/SKILL.md` — at session start only, or
continuously during a session? Are there any filename or directory
naming rules that would prevent an `x-` prefix from working?

**Verified answers.**

1. **Continuous (live change detection) *within* an existing
   watched directory.** Claude Code watches skill directories and
   adding/editing/removing a skill inside an already-watched directory
   takes effect within the current session without restart.
   - Source: "Extend Claude with skills – Claude Code Docs",
     https://code.claude.com/docs/en/skills — section "Live change
     detection". Retrieved 2026-04-21.
   - Quote: "Claude Code watches skill directories for file changes."

2. **One exception — top-level new directory requires restart.**
   "Creating a top-level skills directory that did not exist when the
   session started requires restarting Claude Code so the new
   directory can be watched." — same page, same section.

3. **Automatic discovery from nested directories.** Claude Code also
   scans `.claude/skills/` in subdirectories relative to the working
   directory (for monorepo packages). Same page, section "Automatic
   discovery from nested directories".

4. **Progressive disclosure at session start.** Frontmatter
   (name/description) of every discovered SKILL.md is loaded into the
   system prompt at startup; the SKILL.md body loads only when the
   skill is invoked/triggered.
   - Source: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
     — section "Progressive disclosure" and skill-authoring guidelines.
     Retrieved 2026-04-21. (Also summarized on
     https://code.claude.com/docs/en/skills.)

5. **Filename and directory naming rules.**
   - The directory name is the skill's identifier-hint; the `name`
     field in SKILL.md frontmatter is authoritative. The `name` field
     is restricted to **maximum 64 characters, lowercase letters,
     numbers, and hyphens**.
   - The markdown file must be named exactly `SKILL.md` (case-sensitive
     uppercase; `.md` only).
   - Source: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
     — frontmatter reference. Retrieved 2026-04-21.

6. **Does `x-` prefix work?** Yes — lowercase + hyphens are the
   documented allowed set, so `x-trade-analysis` satisfies the rules.
   For subagents in `.claude/agents/*.md`, the documented convention is
   also lowercase-with-hyphens (examples: `code-reviewer.md`), so
   `x-deployer.md` is well-formed.
   - Source: "Create custom subagents - Claude Code Docs",
     https://code.claude.com/docs/en/sub-agents — naming guidance.
     Retrieved 2026-04-21.

**Implication for v10 design:**
- CD-6 (custom skills load the same way as pack skills) is verified
  for Claude Code.
- The PM-chat detection scan can, for Claude Code, assume that new
  files under `.claude/skills/` and `.claude/agents/` are picked up
  live — no restart needed unless the top-level directory is being
  created for the first time (irrelevant to v10 since the pack ships
  those directories).

---

### Fact 3 — Gemini CLI subagent and skill loading

**Question:** How are subagents in `.gemini/agents/*.md` discovered
and invoked? How are skills in `.gemini/skills/<name>/SKILL.md`
loaded? Are there any filename or directory naming rules that would
prevent an `x-` prefix from working?

**Verified answers.**

1. **Subagent file format and location.** Custom subagents are
   Markdown files with *required* YAML frontmatter, placed in
   `.gemini/agents/*.md` (project, team-shared) or `~/.gemini/agents/*.md`
   (user). The frontmatter is mandatory; the markdown body becomes the
   agent's system prompt.
   - Source: "Subagents | Gemini CLI",
     https://geminicli.com/docs/core/subagents/ — section "Agent
     definition files". Retrieved 2026-04-21.
   - Quote: "Custom agents are defined as Markdown files (.md) with
     YAML frontmatter. You can place them in: Project-level:
     `.gemini/agents/*.md` (Shared with your team); User-level:
     `~/.gemini/agents/*.md` (Personal agents). The file MUST start
     with YAML frontmatter enclosed in triple-dashes `---`."

2. **Agent `name` field rules.** Explicitly documented:
   > "**Unique identifier (slug) used as the tool name for the agent.
   > Only lowercase letters, numbers, hyphens, and underscores.**"
   - Source: same page, "Configuration schema" table.

3. **Invocation.** Subagents are exposed to the main agent as a tool of
   the same name. The user can force invocation with `@agent-name`.
   There is **no `--agent` CLI flag** (V9 Lesson 2).
   - Source: same page, section "How to use subagents" and "Forcing a
     subagent (@ syntax)". Retrieved 2026-04-21.

4. **Skill location and structure.** Skills are directories containing
   `SKILL.md`. Discovery tiers:
   - Workspace (project): `.gemini/skills/` or `.agents/skills/`
     (alias; the `.agents/skills/` alias takes precedence within the
     same tier).
   - User: `~/.gemini/skills/` or `~/.agents/skills/`.
   - Extension skills bundled with installed extensions.
   - Precedence: Workspace > User > Extension.
   - Source: "Agent Skills | Gemini CLI",
     https://geminicli.com/docs/cli/skills/ — "Skill Discovery Tiers".
     Retrieved 2026-04-21.

5. **Skill loading behavior.** Skills are discovered at session start;
   only metadata (name, description) is loaded initially; full body
   + directory contents are loaded when the skill is *activated*
   (progressive disclosure). A runtime `/skills reload` slash command
   refreshes the discovered skills without restarting the CLI.
   - Source: same page, "How it Works / Skill activation" and
     "Managing Skills / In an Interactive Session".

6. **Does `x-` prefix work?** Yes. The `name` slug explicitly allows
   hyphens, so `x-deployer` (agent) and `x-trade-analysis` (skill
   directory) are well-formed. The SKILL.md `name` must match the
   directory name.

**Implication for v10 design:**
- CD-1 (x- prefix) is compatible with Gemini.
- Gemini subagents require YAML frontmatter — so a PM-chat-generated
  `x-<name>.md` for Gemini must include a valid frontmatter block; this
  is a material difference from Claude agent files (which also use
  frontmatter but differently) and from Codex TOML. The per-tool
  translator (CD-4 path) must be aware of this.
- Gemini has no concept of "registration in config.toml" — consistent
  with the correction in Contradiction C-1.

---

### Fact 4 — Claude Desktop app project knowledge and file access

**Question:** What file access patterns are available to a Claude
Desktop PM chat for reading per-agent prompt files from a project?
Does it read files on demand from the filesystem, or must files be
explicitly added to project knowledge? How does this affect a design
that splits one large file into many small files in a directory?

**Verified answers.**

1. **Two primary access patterns.**

   **(a) Project knowledge (Projects feature).** Files are uploaded
   into a Project's knowledge panel. Up to 30 MB per file, unlimited
   file count. These are snapshots; re-uploads are required when the
   files change.
   - Source: "Retrieval augmented generation (RAG) for projects",
     https://support.claude.com/en/articles/11473015-retrieval-augmented-generation-rag-for-projects.
     Retrieved 2026-04-21.
   - Source: Claude Help Center, "Uploading files to Claude",
     https://support.claude.com/en/articles/8241126-uploading-files-to-claude.
     Retrieved 2026-04-21.

   **(b) Filesystem MCP server** (`@modelcontextprotocol/server-filesystem`).
   The Claude Desktop app loads this MCP and Claude can read the live
   files from a configured directory on demand. Writes are allowed if
   the filesystem MCP is configured for write access. This is the
   pattern closest to what Claude Code / Codex / Gemini CLI do
   natively.
   - Source: "Connect to local MCP servers",
     https://modelcontextprotocol.io/docs/develop/connect-local-servers.
     Retrieved 2026-04-21.

2. **Projects context-window behavior (RAG).** Claude's 200K-token
   context window acts as a soft cap on how much Project knowledge is
   inlined per turn. When total knowledge exceeds that window, Claude
   Projects automatically switches to RAG mode — Claude retrieves
   relevant chunks of the uploaded files rather than inlining them all.
   - Source: "How large is the context window on paid Claude plans?",
     https://support.claude.com/en/articles/8606394-how-large-is-the-context-window-on-paid-claude-plans.
     Retrieved 2026-04-21.
   - Note: an open bug (https://github.com/anthropics/claude-code/issues/25759)
     reports that RAG activation in Projects has sometimes triggered
     based on file count rather than token size, at surprisingly low
     thresholds. This is a *reliability caveat* for any design that
     depends on predictable inlining behavior.

3. **Implication for a "split one large file into many small files"
   design.**

   - Via **filesystem MCP**: the Desktop PM chat can read each small
     per-agent file on demand. This is effectively identical to how
     Claude Code CLI behaves. The split reduces tokens per read. No
     design concern.
   - Via **Project knowledge** (no filesystem MCP): Claude Desktop
     does not "open a specific file from disk by path"; it retrieves
     across the uploaded knowledge blob using RAG semantics. Splitting
     one 765-line file into ~15 per-agent files changes the RAG chunk
     boundaries and may *improve* retrieval precision (more focused
     chunks) but the PM chat does not gain explicit "read one file"
     semantics from the split. The benefit is different from the CLI
     case and harder to quantify without empirical testing.
   - For v10: if Desktop PM chat is a supported surface (it is —
     Design Requirement "PM Chat tool flexibility"), the design should
     *recommend* enabling the filesystem MCP for the project, so the
     per-agent prompt files can be read the same way on all PM chat
     surfaces. If filesystem MCP is not enabled, Project knowledge
     upload remains viable but requires periodic re-uploads as the
     pack is upgraded or custom prompts are added.
   - This should be made explicit in Step 4 and Step 5 outputs
     (affecting the CD-8 directory design and the CD-4 PM-chat
     workflow, both of which must work identically across all PM chat
     surfaces).

4. **Does "files on demand from the filesystem" work in the Desktop
   app without MCP?** No. The Desktop app has no native filesystem
   access outside of Project knowledge uploads. The MCP server is the
   documented path to live disk access.

**Status:** Verified. No contradiction with V10-PREDESIGN, but the
predesign does not currently specify which Desktop access pattern is
assumed. Step 5 and Step 7 should make that explicit.

---

### Fact 5 — File size heuristics (direct read vs. RAG/search)

**Question:** What is a reasonable upper bound for a file that each
tool can "direct read" efficiently in a single operation vs. files
that should be accessed via RAG or search? Provide any documented
limits or practical thresholds per tool.

**Verified / documented thresholds.**

| Tool / surface | Documented limit | Notes |
|---|---|---|
| Claude Code CLI | Context window 200K (Sonnet) / 1M (Opus 4.6) tokens. No documented per-file read limit. | Read tool has a default read of first 2000 lines; larger files can be read by range. No "file too large to read" threshold surfaced in the docs; the practical cap is the context window. |
| Claude Desktop (Projects) | 30 MB per file. Unlimited files. 200K token context window triggers RAG. | Switch from inlined to RAG-retrieved is automatic and approximate. |
| Claude Desktop (filesystem MCP) | MCP filesystem server streams file contents; no documented per-file cap beyond model context window. | Effectively equivalent to CLI for sizing decisions. |
| Codex CLI | Reads files via Shell/Apply Patch; `project_doc_max_bytes` controls how much of AGENTS.md is inlined at session start (default documented in config-advanced). Model context is GPT-5.1 Max scale ("Large"); no documented per-file hard cap. | `project_doc_max_bytes` is the only config knob that explicitly bounds a read; it applies to AGENTS.md only, not to arbitrary files. |
| Gemini CLI | 1M token context window (Flash and Pro). No documented per-file read limit. | Skill progressive disclosure is the only documented content-sizing feature; it applies to skills, not arbitrary files. |
| Claude Skills (SKILL.md body) | **Authoring guideline**: target ~50 lines, max ~150 lines, recommended <1,000 words, max 5,000 words, token budget ≤ ~6,500. | Secondary source (claude-mem, analyticsvidhya, deepwiki) summarizing progressive-disclosure authoring guidance; official docs state the principle but not the exact numeric bounds. Treat numeric thresholds as guidance, not hard limits. |
| Claude frontmatter "description" field for skills | **15K character** rollup budget across all installed skills for startup context | Secondary source. Cited as a rule-of-thumb for total frontmatter across skills. |

**Sources (primary):**
- Claude Code context windows and limits:
  https://code.claude.com/docs/en/costs and
  https://platform.claude.com/docs/en/build-with-claude/context-windows.
  Retrieved 2026-04-21.
- Claude Projects file + context-window behavior:
  https://support.claude.com/en/articles/8606394-how-large-is-the-context-window-on-paid-claude-plans,
  https://support.claude.com/en/articles/8241126-uploading-files-to-claude,
  https://support.claude.com/en/articles/11473015-retrieval-augmented-generation-rag-for-projects.
  Retrieved 2026-04-21.
- Codex `project_doc_max_bytes` and `project_doc_fallback_filenames`:
  https://developers.openai.com/codex/config-advanced — section
  "AGENTS.md". Retrieved 2026-04-21.
- Gemini CLI model / context window: pack's own TOOL-COMPARISON.md
  Part 5 (referenced; not re-verified here).
- Claude skill progressive disclosure: official docs at
  https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
  (principle only) plus secondary-source numeric targets (cited above
  in the table).

**Sources (secondary, for numeric thresholds only):**
- https://docs.claude-mem.ai/progressive-disclosure
- https://deepwiki.com/spences10/claude-skills-cli/5.3-progressive-disclosure-guidelines
- https://www.analyticsvidhya.com/blog/2026/03/claude-skills-custom-skills-on-claude-code/

**Status and caveats.**

- The **authoritative** answer is only: "each tool's context window is
  the effective cap; there is no documented per-file hard limit
  (outside of `project_doc_max_bytes` for AGENTS.md in Codex, and
  30 MB per file for Claude Projects uploads)."
- The **practical thresholds** used in the community (~50–150 lines
  per SKILL.md body, one per-agent prompt file sized under ~1K–5K
  words) are **secondary-source guidance**, not documented hard
  limits. Treat them as heuristics for the Step 4 token budget
  analysis, not as invariants.
- For the V10 design, the useful rule of thumb is: **per-agent prompt
  files and SKILL.md bodies should fit comfortably under the
  progressive-disclosure budgets** (a few thousand tokens each). Any
  file whose body approaches ~10K tokens should be split or reviewed.
  The current monolithic `PROMPT-TEMPLATES.md` at ~765 lines is well
  beyond comfortable for a per-invocation read, even though no tool
  will fail to read it — which is what the Step 4 token budget
  analysis is meant to quantify.

---

### Fact 6 — Codex `post_edit_command` and hook mechanisms

**Question:** Does Codex CLI have hook mechanisms (equivalent to Claude
Code's PostToolUse hooks) that could be relevant to detecting when a
custom agent file is created or modified? What is the
`post_edit_command` mechanism and what events trigger it?

**Verified answers.**

1. **`post_edit_command` does not exist in Codex CLI.** No
   configuration key by that name is documented in Codex's config
   reference, config basics, config advanced, hooks, subagents, or CLI
   reference pages. See Contradiction C-3 above.

2. **Codex does have two external-script mechanisms**, neither of
   which fires on file edits:

   **(a) `notify`** (stable). Runs an external program on supported
   events. Currently only `agent-turn-complete` is supported.
   - Source:
     https://developers.openai.com/codex/config-advanced — section
     "notify". Retrieved 2026-04-21.
   - Quote: "Codex can run an external program via the `notify`
     configuration, which is triggered whenever Codex emits supported
     events (currently only `agent-turn-complete`)."

   **(b) Hooks** (experimental). Loaded from `~/.codex/hooks.json`
   and/or `<repo>/.codex/hooks.json`. Must be turned on explicitly
   with `codex_hooks = true`. Event types: `SessionStart`,
   `PreToolUse`, `PermissionRequest`, `PostToolUse`,
   `UserPromptSubmit`, `Stop`.
   - Source:
     https://developers.openai.com/codex/hooks — all sections.
     Retrieved 2026-04-21.
   - Quote: "Hooks are under active development. Windows support
     temporarily …" and "`codex_hooks = true`".

3. **Current runtime limitation — Bash-only.** `PreToolUse`,
   `PermissionRequest`, and `PostToolUse` hooks **only fire for the
   `Bash` tool** in the current runtime. They do **not** fire on
   `ApplyPatch`, `Write`, or any file-edit tool. This is documented on
   the Hooks page itself and confirmed by an open GitHub issue.
   - Source quote (Hooks page matcher/events table):
     > "PermissionRequest: tool name. Current Codex runtime only emits
     > Bash. PostToolUse: tool name. Current Codex runtime only emits
     > Bash. PreToolUse: tool name. Current Codex runtime only emits
     > Bash."
   - Source (issue tracker): openai/codex issue #16732,
     "ApplyPatchHandler doesn't emit PreToolUse/PostToolUse hook
     event. Hooks only fire for Bash tool.". Retrieved 2026-04-21.
   - Source (issue tracker): openai/codex issue #14754, "Add
     PreToolUse and PostToolUse hook events for code quality
     enforcement." Retrieved 2026-04-21.

4. **Claude Code, for comparison, does have file-editing hooks.**
   `PreToolUse` and `PostToolUse` on Claude Code fire on `Write`,
   `Edit`, `MultiEdit`, `Read`, `Glob`, `Grep`, `Bash`, and `Agent`.
   Configured in `.claude/settings.json` under `hooks`. Reference:
   https://code.claude.com/docs/en/hooks. Retrieved 2026-04-21.

5. **Gemini CLI Hooks** also exist (separate mechanism, documented
   at https://geminicli.com/docs/cli/hooks — listed in the Gemini
   sidebar as "Hooks Overview / Reference"). Not deeply inspected
   in this pass — they were not mentioned in the Step-2 prompt. If
   the v10 design ends up depending on Gemini hooks, a follow-up
   verification pass is warranted.

**Implication for v10 design:**

- **Do not design on the assumption that any Codex hook fires when a
  `.codex/agents/x-*.toml` file is created or edited.** It does not.
- The PM-chat startup-scan / phase-gate detection in Part 5 remains
  the only cross-tool-consistent detection mechanism.
- If a future design pass wants a per-tool "hook on file edit", that
  is achievable today on Claude Code and Gemini CLI but not on Codex.
  Cross-tool asymmetry must be accepted or the feature must be built
  at the PM-chat level (which is tool-agnostic).
- V9 Lesson 2 applies: do not extrapolate a Codex feature from
  Claude Code's hook model. The feature does not exist.

---

## Summary table — V10-PREDESIGN artifacts affected by findings

| Predesign artifact | Impact |
|---|---|
| CD-1 (`x-` prefix) | Verified compatible with Claude Code and Gemini CLI naming rules. **UNVERIFIED** for Codex subagent `name =` field. Recommend empirical test. See C-2. |
| CD-2 (identical structure) | Compatible for file placement. YAML frontmatter is mandatory on Gemini; the "identical structure" rule must recognize this as a per-tool difference, not be literal. |
| CD-3 (PM chat as only creation mechanism) | Verified as the only cross-tool-consistent mechanism — no Codex file-edit hook exists. See C-3. |
| CD-4 (three creation paths) | Workable. Translator per tool must handle: Claude markdown + hyphen-name, Codex TOML + (probably) underscore-name, Gemini markdown + YAML frontmatter + hyphen-OR-underscore name. |
| CD-5 (migration preserves x- files) | No CLI-doc dependency. Verified there are no filename collisions with reserved pack names. |
| CD-6 (custom skills load same way) | Verified for Claude Code (live detection) and Gemini (progressive disclosure + `/skills reload`). No change needed. |
| CD-7 (PLATFORM-SKILLS.md `## Custom skills` section) | Unaffected by CLI docs. |
| CD-8 (prompt reorg) | File-size heuristics (Fact 5) support the reorg. Desktop PM chat implications (Fact 4) require the design to specify filesystem MCP expectations. |
| CD-9 (custom prompts in prompts/) | Unaffected by CLI docs. |
| **OQ-2 (Codex config.toml registration)** | **Reframe.** No `[agents.<name>]` registration entry exists in documented Codex. The "consistency scan" is chasing a non-existent requirement. See C-1. |
| OQ-7 (manual escape hatch) | Unaffected by CLI docs; remains a design question. |
| OQ-8 (x- prefix collision) | Unaffected by CLI docs; remains a design question. |
| Part 4 touch-point inventory row for `.codex/config.toml` | Revise or remove; see C-1. |
| Part 5 PM-chat workflow "adds `[agents.x_name]` entry" | Revise or remove; see C-1. |

---

## Unverified / follow-up items

1. **Codex `name` field hyphen acceptance.** Whether
   `name = "x-deployer"` is accepted at runtime, or whether Codex
   requires `name = "x_deployer"` (while the file is still
   `x-deployer.toml`). Recommend: empirical test before G2.
2. **Gemini Hooks.** Not deeply inspected in this pass. If v10 design
   touches Gemini hook events, a follow-up verification is required.
   Source page exists:
   https://geminicli.com/docs/cli/hooks — Retrieved 2026-04-21 (page
   acknowledged in sidebar; contents not enumerated).
3. **Codex skill loading semantics.** Step 2 prompt asked about skill
   loading for Claude and Gemini specifically. Codex skill loading was
   not in scope but is worth verifying before BD-046 finalizes
   (TOOL-COMPARISON.md says "Codex skills require `--enable skills`
   flag" — needs re-verification). Source:
   https://developers.openai.com/codex/skills — not fetched in this
   pass.
4. **Claude Code `.claude/agents/` live reload behavior.** The "Live
   change detection" section of the skills docs explicitly covers
   skills. Whether `.claude/agents/*.md` edits are also picked up
   without restart was not explicitly confirmed on the skills page. The
   subagents doc page (https://code.claude.com/docs/en/sub-agents)
   should be re-read for this specific point before G5 is closed.
5. **Codex `[agents]` *per-agent* entry — is there a lesser-documented
   form?** The docs read as authoritative that `[agents]` is
   global-only, but the predesign's belief is strong enough that a
   direct empirical check (drop a file, grep `config.toml` for
   auto-written entries) is cheap insurance.

---

## Source inventory (primary URLs, retrieved 2026-04-21)

Codex:
- https://developers.openai.com/codex/subagents
- https://developers.openai.com/codex/config-advanced
- https://developers.openai.com/codex/config-reference
- https://developers.openai.com/codex/hooks
- https://developers.openai.com/codex/skills (not fetched this pass)
- https://developers.openai.com/codex/cli/reference
- https://github.com/openai/codex/issues/16732 (PostToolUse Bash-only)
- https://github.com/openai/codex/issues/14754 (feature request for
  file-edit hook events)

Claude Code / Claude Desktop / Claude Projects:
- https://code.claude.com/docs/en/skills
- https://code.claude.com/docs/en/sub-agents
- https://code.claude.com/docs/en/hooks
- https://code.claude.com/docs/en/costs
- https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview
- https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
- https://platform.claude.com/docs/en/build-with-claude/context-windows
- https://support.claude.com/en/articles/8606394-how-large-is-the-context-window-on-paid-claude-plans
- https://support.claude.com/en/articles/8241126-uploading-files-to-claude
- https://support.claude.com/en/articles/11473015-retrieval-augmented-generation-rag-for-projects
- https://modelcontextprotocol.io/docs/develop/connect-local-servers

Gemini CLI:
- https://geminicli.com/docs/core/subagents/
- https://geminicli.com/docs/cli/skills/
- https://geminicli.com/docs/cli/hooks (not fetched in depth; sidebar
  entry acknowledged)

Secondary (cited only where marked):
- https://docs.claude-mem.ai/progressive-disclosure
- https://deepwiki.com/spences10/claude-skills-cli/5.3-progressive-disclosure-guidelines
- https://www.analyticsvidhya.com/blog/2026/03/claude-skills-custom-skills-on-claude-code/
- https://vladimirsiedykh.com/blog/codex-mcp-config-toml-shared-configuration-cli-vscode-setup-2025
- https://github.com/anthropics/claude-code/issues/25759 (Projects RAG
  activation behavior)

---

*End of step-02-cli-verification.md.*
