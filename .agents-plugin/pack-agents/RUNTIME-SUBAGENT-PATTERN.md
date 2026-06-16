<!-- RE-VERIFY at impl: runtime define_subagent invocation shape + plugin agents/ inner template schema, gemini-cli #27305, antigravity.google/docs/subagents, antigravity.google/docs/cli-plugins -->

# Runtime subagent pattern (fallback hedge) — pack-developer roster

This document is the **fallback** path for running the AI Agent Config
Pack's own developer agent roster on the Antigravity CLI (`agy`) while
the plugin `agents/` inner template schema remains undocumented. It is
**forward-looking** — re-verify every command below against
`antigravity.google/docs/subagents` and `antigravity.google/docs/cli-plugins`
before relying on it. The plugin bundle in this directory (`plugin.json`
+ `agents/`) is the **primary** contract; this runtime pattern is the
hedge for when the plugin install path is not yet available on your
`agy` version.

This is the **pack-self** bundle: the 5 `pack-*` agents used by people
developing the pack repository itself (pack-architect, pack-coder,
pack-docs-researcher, pack-planner, pack-reviewer). It is **never
shipped to client projects** — the client agent roster ships from the
separate `project-template/.agents-plugin/optiquity-agents/` bundle and
carries different (client-audience) role content.

## When to use this

Use the plugin bundle first:

```
agy plugin install ./.agents-plugin/pack-agents
```

If your `agy` version does not yet accept the plugin `agents/` template
schema (the inner per-agent format is undocumented while the upstream
schema issue is open), fall back to the **runtime `define_subagent`**
pattern below. This defines each agent inside a single conversation
rather than installing it as a persistent plugin.

## The pattern

Antigravity exposes a conversation-scoped subagent mechanism: you define
a subagent from a role description, then invoke it. The role text for
each of the pack's 5 developer agents lives in `agents/<name>.md` in this
directory — read the matching file and supply its body as the subagent's
role/system text.

```
# 1. Read the role text for the agent you want (e.g. the pack-reviewer):
#    agents/pack-reviewer.md  (the body below the frontmatter is the role/system text)
#
# 2. Define the subagent for this conversation:
#    define_subagent name="pack-reviewer" role="<paste the role text from agents/pack-reviewer.md>"
#
# 3. Invoke it with the task:
#    invoke_subagent name="pack-reviewer" task="<your task prompt>"
#
# RE-VERIFY at impl: exact define_subagent / invoke_subagent verb names,
# argument shapes, and whether the role text is passed inline or by file
# reference — antigravity.google/docs/subagents
```

## Headless / scripted use

For unattended runs, drive the same definitions through the headless
print mode:

```
agy -p "<task prompt that names the agent role and pastes its role text>"
# or: agy --print "<...>"
# RE-VERIFY at impl: headless subagent activation + --print semantics,
# antigravity.google/docs/subagents
```

The pack repo has no `agent-run.sh` — that is a project-template helper,
not a pack invocation method. Pack agents are invoked directly via the
Antigravity CLI (the plugin bundle above, or this runtime pattern), or
via the Claude Code Agent tool / Codex parallel-spawn when working from
those CLIs. See `pack-ops/PACK-AGENTS.md` for the pack agent routing
table and invocation methods.

## Read-only vs read-write agents (the two-class model)

The role text in each `agents/<name>.md` file declares the agent's
permission profile and its hard rules in prose. The pack roster has two
classes (see `pack-ops/PACK-AGENTS.md` § "Two agent classes"):

- **Read-only (RO)** — pack-architect, pack-docs-researcher,
  pack-planner, pack-reviewer. Their single permitted file write is the
  one caller-specified report; the codebase is read-only otherwise.
- **Read-write within scope (RW)** — pack-coder. May write/edit source
  files within the caller-scoped file set, then emit a patch + report.

When defining a subagent at runtime, preserve that permission-profile
prose verbatim — it is what makes a read-only agent read-only. Every
pack agent (RO and RW alike) runs **zero** state-changing git verbs;
only Pack Chat stages/commits, with explicit user approval. Pair the
role text with the appropriate `agy` permission flags (`--sandbox`, and
`--dangerously-skip-permissions` only for the RW pack-coder in
unattended runs). The Antigravity `permissions{allow,deny,ask}` block
(Deny > Ask > Allow) is the durable lever for denying state-changing git
verbs — see `pack-ops/OPTIONAL-FEATURES.md` for the example permissions
shape.
