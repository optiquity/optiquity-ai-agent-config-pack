<!-- RE-VERIFY at impl: runtime define_subagent invocation shape + plugin agents/ inner template schema, gemini-cli #27305, antigravity.google/docs/subagents, antigravity.google/docs/cli-plugins -->

# Runtime subagent pattern (fallback hedge)

This document is the **fallback** path for running this project's agent
roster on the Antigravity CLI (`agy`) while the plugin `agents/` inner
template schema remains undocumented. It is **forward-looking** — re-verify
every command below against `antigravity.google/docs/subagents` and
`antigravity.google/docs/cli-plugins` before relying on it. The plugin
bundle in this directory (`plugin.json` + `agents/`) is the **primary**
contract; this runtime pattern is the hedge for when the plugin install
path is not yet available on your `agy` version.

## When to use this

Use the plugin bundle first:

```
agy plugin install ./.agents-plugin/optiquity-agents
```

If your `agy` version does not yet accept the plugin `agents/` template
schema (the inner per-agent format is undocumented while the upstream
schema issue is open), fall back to the **runtime `define_subagent`**
pattern below. This defines each agent inside a single conversation rather
than installing it as a persistent plugin.

## The pattern

Antigravity exposes a conversation-scoped subagent mechanism: you define a
subagent from a role description, then invoke it. The role text for each of
this project's 16 agents lives in `agents/<name>.md` in this directory —
read the matching file and supply its body as the subagent's role/system
text.

```
# 1. Read the role text for the agent you want (e.g. the reviewer):
#    agents/reviewer.md  (the body below the frontmatter is the role/system text)
#
# 2. Define the subagent for this conversation:
#    define_subagent name="reviewer" role="<paste the role text from agents/reviewer.md>"
#
# 3. Invoke it with the task:
#    invoke_subagent name="reviewer" task="<your task prompt>"
#
# RE-VERIFY at impl: exact define_subagent / invoke_subagent verb names,
# argument shapes, and whether the role text is passed inline or by file
# reference — antigravity.google/docs/subagents
```

## Headless / scripted use

For unattended runs, drive the same definitions through the headless print
mode:

```
agy -p "<task prompt that names the agent role and pastes its role text>"
# or: agy --print "<...>"
# RE-VERIFY at impl: headless subagent activation + --print semantics,
# antigravity.google/docs/subagents
```

`agent-run.sh` in the project root automates the headless leg for the
`agy` CLI (the `agy` branch). See `./agent-run.sh --help`.

## Read-only vs read-write agents

The role text in each `agents/<name>.md` file declares the agent's
permission profile (Read-only vs Source-write within scope) and its hard
rules in prose. When defining a subagent at runtime, preserve that prose
verbatim — it is what makes a read-only agent read-only. Pair it with the
appropriate `agy` permission flags (`--sandbox`, and `--dangerously-skip-permissions`
only for write agents in unattended runs). The Antigravity
`permissions{allow,deny,ask}` block (Deny > Ask > Allow) is the durable
lever for denying state-changing git verbs — see
`docs/pack/OPTIONAL-FEATURES.md` for the example permissions shape.
