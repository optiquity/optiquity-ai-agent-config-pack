# Optional Features and Settings

This file documents tool-specific features and settings that your project
can opt into without abandoning the cross-CLI parity the Config Pack
provides by default. Each entry is independent — turning one on does not
affect the rest of the pack, and the standard PM Chat workflow continues
to work identically across Claude Code, Codex CLI, and Gemini CLI.

These features tend to be:
- **Tool-specific** (only available in one CLI)
- **Experimental** (gated by an env var or a version requirement)
- **Higher-cost** (more tokens, more setup, or more moving parts)

Your project stays cross-CLI by default. Opt in per-feature when the
benefit outweighs the asymmetry.

---

## Claude Code — Agent Teams

**Status:** Experimental in Claude Code v2.1.32+, gated by an environment
variable. Claude Code only — no Codex or Gemini CLI equivalent.

**What it is.** A native Claude Code feature that coordinates multiple
Claude Code instances working in parallel. One session acts as the team
lead; teammates each have their own context window, share a task list,
and message each other directly. Your project's existing pack agents (at
`.claude/agents/<name>.md`) already work as teammate types with no
changes.

Official documentation: <https://code.claude.com/docs/en/agent-teams>

**When this matters for your project.** Most workflows are sequential
and human-coordinated through the PM Chat — deterministic and
identical across all three CLIs. Agent Teams adds value when work is
parallel and independent: multi-aspect code review (security +
performance + test coverage), cross-layer feature work (frontend +
backend + tests, each owned by a different teammate), or investigation
with competing hypotheses. For these cases, your existing project
agents (`.claude/agents/coder.md`, `.claude/agents/reviewer.md`, etc.)
serve double duty as Claude Code subagents and as Agent Teams teammate
types — no extra setup needed.

**How to enable.** Add to `~/.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

Restart Claude Code (`claude --version` should report v2.1.32 or later).

**How to use your project's agents as teammates.** Once Agent Teams is
enabled, spawn teammates by referencing project agent names:

```text
Create an agent team to review PR #142. Spawn three teammates using the
project agent types:
  - reviewer for security implications
  - reviewer for performance impact
  - tester for test coverage
Have them each review and report findings.
```

Project agents are subagent definitions with proper YAML frontmatter,
which Claude Code accepts as teammate definitions per the
[Agent Teams docs](https://code.claude.com/docs/en/agent-teams#use-subagent-definitions-for-teammates).
Each teammate honors the agent's `tools` allowlist and `model` and
loads `CLAUDE.md`, project skills, and MCP servers as a regular session
would. The PM Chat is not involved in this branch — Agent Teams is its
own coordination model.

**Caveats.**
- **Claude Code only.** If your team requires cross-CLI parity, use
  Agent Teams as a per-task acceleration on Claude Code only.
- **Experimental.** No session resume, one team per session, no nested
  teams, slow shutdown.
- **Higher token cost.** Each teammate is a full Claude Code session;
  cost scales linearly with teammate count.
- **Teams config is per-team, not per-project.** Teams live at
  `~/.claude/teams/{team-name}/config.json`; the pack does not ship a
  team configuration.
- **Permissions are set at spawn.** All teammates start with the lead's
  permission mode. Pre-approve common operations before spawning.

**When to skip Agent Teams.** Sequential work or many file dependencies
(single session is more effective); cross-CLI parity requirements (use
the PM Chat workflow instead); token budget more constrained than
wall-clock time.

---

## Codex CLI — Optional features

*Placeholder. The Config Pack will document Codex-specific opt-in
features here as they ship and prove useful.*

---

## Gemini CLI — Optional features

*Placeholder. The Config Pack will document Gemini-specific opt-in
features here as they ship and prove useful.*

---

## Tracker integration (deferred)

**Status** — DEFERRED indefinitely (no release version).

**What it was** — an opt-in per-project mode that would move issue
tracking out of `docs/project/BACKLOG.md` flat-file format into a
tracker backend (default `gh` / GitHub Issues), with a forward
migration and an idempotent reverse, plus a recommendation system that
suggested opting in based on project signals.

**Current state** — tracker integration is deferred and flat-file
per-entry is the sole supported mode. The ability to flip to tracker
mode is blocked, and the recommendation system surfaces nothing. The
tracker code (the TrackerProvider abstraction, migrators, and verbs) is
retained dormant and test-covered for a possible future resumption;
there are no opt-in steps to run at this time. Continue to use the
flat-file per-entry trees under `docs/project/`.

---

## Adding new entries

If your project adopts a CLI-specific opt-in feature the pack does not
yet document, add a section here following the same shape as the Agent
Teams entry above: Status, What it is, When it matters, How to enable,
How to use the pack's pieces with it, Caveats, When to skip. Most
projects will not need to add entries — the pack ships the common
cross-CLI feature catalog.
