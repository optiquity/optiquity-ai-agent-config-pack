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

## Tracker integration (v11)

**Status** — v11.0+; opt-in per project. Default backend: `gh` (GitHub
Issues). Other backends (Forgejo / Linear / Jira) plug in via the
TrackerProvider abstraction but are not implemented in v11.

**What it is** — moves issue tracking out of `docs/project/BACKLOG.md`
flat-file format into GitHub Issues, with a one-shot forward migration
(`pack tracker init`) and idempotent reverse (`pack tracker disable`)
for opt-out or backup. The recommendation system observes signals from
your project (open BD count, BACKLOG size, 30-day growth) and offers
tracker opt-in only when those signals warrant.

**When it matters** — when your project's BD volume reaches the point
that GitHub-side cross-references, mentions, and CI-on-issue-state
become more valuable than the "everything in `git log`" property of
flat-file tracking. The recommendation system surfaces this naturally;
you do not have to track it yourself.

**How to enable** — from your project repo root:

```sh
bash scripts/pack-tracker.sh init       # writes tracker.toml + runs forward migration
bash scripts/pack-tracker.sh status     # mapping freshness report
bash scripts/pack-tracker.sh doctor     # config + integrity check
bash scripts/pack-tracker.sh disable    # reverse migration; back to flat-file
```

`tracker.toml` lives at your project root. The example template
`tracker.toml.example` is installed by `init-project.sh` at v11 — copy
it to `tracker.toml` and edit before running `pack tracker init`. Every
commonly-tuned field appears as a commented-out section with a default
value.

**Caveats**

- The forward migration is idempotent but rewrites issue bodies on
  every run; a heavily-edited issue body may need
  `customization-detected-needs-reconciliation` resolution (see Failure
  modes below).
- The `gh` backend requires `gh auth login` against the right account
  and `gh repo view` succeeding from your project root. CI-only tokens
  may lack required scopes.
- Reverse migration writes a sidecar `BACKLOG.md` from the live issues
  — it does NOT recover prior flat-file content. Use `git` for that.
- Tracker config is per-project, not pack-wide; each project opts in
  independently.

**When to skip** — if your BD volume is under ~50 open and
`docs/project/BACKLOG.md` search is comfortable, the tracker round-trip
is more friction than flat-file. The recommendation system will not nag
in this regime.

**How to disable** — the tracker is reversible at any time via
`bash scripts/pack-tracker.sh disable`, which reads live issue state,
writes a sidecar `BACKLOG.md` from current issues, and flips
`tracker.toml`'s `mode.state` back to flat-file. Atomic (restores
backup on failure), idempotent (safe to re-run). Existing GitHub issues
remain untouched.

**Failure modes** — when the migrator encounters a file with both
project-side and pack-side edits since the last baseline (real-merge
case), it surfaces the disposition
`customization-detected-needs-reconciliation` and writes a sidecar of
your pre-migration content. See `MERGE-STRATEGY.md` in the pack repo
for the per-file class matrix and sidecar conventions. Reconciliation
is manual: open the sidecar + the destination, merge, remove the
sidecar, commit.

---

## Adding new entries

If your project adopts a CLI-specific opt-in feature the pack does not
yet document, add a section here following the same shape as the Agent
Teams entry above: Status, What it is, When it matters, How to enable,
How to use the pack's pieces with it, Caveats, When to skip. Most
projects will not need to add entries — the pack ships the common
cross-CLI feature catalog.
