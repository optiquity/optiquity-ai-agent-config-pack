# Optional Features and Settings

This file documents tool-specific features and settings that the Config Pack
can opt into but does not require. Each entry is independent — turning one
on does not affect the rest of the pack, and the standard
PM-Chat-coordinated workflow continues to work identically across Claude
Code, Codex CLI, and Gemini CLI.

These features tend to be:
- **Tool-specific** (only available in one CLI)
- **Experimental** (gated by an env var or a version requirement)
- **Higher-cost** (more tokens, more setup, or more moving parts)

The Config Pack stays cross-CLI by default. Opt in per-feature when the
benefit outweighs the asymmetry.

---

## Claude Code — Agent Teams

**Status:** Experimental in Claude Code v2.1.32+, gated by an environment
variable. Claude Code only — no Codex or Gemini CLI equivalent.

**What it is.** A native Claude Code feature that coordinates multiple Claude
Code instances working in parallel. One session acts as the team lead;
teammates each have their own context window, share a task list, and message
each other directly. Subagent definitions can be referenced as teammate
types — which means **the Config Pack's existing pack agents already work as
teammate types with no changes**.

Official documentation: <https://code.claude.com/docs/en/agent-teams>

**When this matters for the Config Pack.** Most pack workflows are
sequential and human-coordinated through the PM Chat: generate a prompt,
run an agent, paste output back, decide next step. That's deterministic and
identical across all three CLIs.

Agent Teams adds value when work is parallel and independent — for example:
- Multi-aspect code review (security + performance + test coverage in
  parallel)
- Cross-layer feature work (frontend + backend + tests, each owned by a
  different teammate)
- Investigation with competing hypotheses (parallel teammates challenge each
  other's theories)

For these cases, a Claude Code user can opt into Agent Teams without giving
up the pack's role definitions or skill library — the pack agents serve
double duty as Claude Code subagents and as Agent Teams teammate types.

**How to enable.** Add to `~/.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

Restart Claude Code (`claude --version` should report v2.1.32 or later).

**How to use the pack's agents as teammates.** Once Agent Teams is enabled,
spawn teammates by referencing pack agent names:

```text
Create an agent team to review PR #142. Spawn three teammates using the
pack agent types:
  - reviewer for security implications
  - reviewer for performance impact
  - tester for test coverage
Have them each review and report findings.
```

The pack agents at `.claude/agents/<name>.md` are subagent definitions with
proper YAML frontmatter, which Claude Code accepts as teammate definitions
per the [Agent Teams docs](https://code.claude.com/docs/en/agent-teams#use-subagent-definitions-for-teammates).
The teammate honors the pack agent's `tools` allowlist and `model`, and
loads `CLAUDE.md`, project skills, and MCP servers as a regular session
would. The PM Chat is not involved in this branch — Agent Teams is its own
coordination model.

**Caveats.**
- **Claude Code only.** A team session does not exist in Codex or Gemini.
  If your team or project requires cross-CLI parity, do not adopt Agent
  Teams as a primary mode — use it as a per-task acceleration on Claude
  Code only.
- **Experimental.** Per the official docs: no session resume for in-process
  teammates, one team per session, no nested teams, slow shutdown. These
  may be lifted in future Claude Code releases.
- **Higher token cost.** Each teammate is a full Claude Code session with
  its own context. The official docs warn this scales linearly with the
  number of teammates.
- **Project-level config not recognized.** A file like
  `.claude/teams/teams.json` in your project directory is treated as an
  ordinary file by Claude Code, per the official docs. The pack does not
  ship a team configuration; teams are created on demand by the lead
  session at `~/.claude/teams/{team-name}/config.json`.
- **Permissions are set at spawn.** All teammates start with the lead's
  permission mode. Pre-approve common operations in your permission
  settings before spawning to reduce interruption.

**When to skip Agent Teams.**
- The work is sequential or has many file dependencies (single session is
  more effective).
- Your project requires cross-CLI parity (use the PM Chat workflow
  instead).
- Token budget matters more than wall-clock parallelism.

---

## Codex CLI — Optional features

*Placeholder. The Config Pack will document Codex-specific opt-in features
here as they ship and prove useful.*

---

## Gemini CLI — Optional features

*Placeholder. The Config Pack will document Gemini-specific opt-in features
here as they ship and prove useful.*

---

## Tracker integration (v11)

**Status** — v11.0+; opt-in; per-surface (pack repo and per-project repo
opt-in independently). Default backend: `gh` (GitHub Issues). Other
backends (Forgejo / Linear / Jira) plug in via the TrackerProvider
abstraction in `scripts/lib/tracker-provider.sh` but are not implemented
in v11.

**What it is** — moves issue tracking out of `BACKLOG.md` flat-file
format into GitHub Issues (or another tracker), with a one-shot forward
migration (`pack tracker init`) and idempotent reverse
(`pack tracker disable`) for opt-out or backup. Adds an inflection-point
recommendation
system that observes pack/project signals (BD count, BACKLOG size,
30-day growth) and offers tracker opt-in only when the signals warrant.

**When it matters** — when the project's BD volume reaches the point
that GitHub-side cross-references, mentions, and CI-on-issue-state
become more valuable than the "everything in `git log`" property of
flat-file tracking. The recommendation system surfaces this naturally;
you do not have to track it yourself.

**How to enable** — from the pack repo or a pack-configured project:

```sh
bash scripts/pack-tracker.sh init       # writes tracker.toml + runs forward migration
bash scripts/pack-tracker.sh status     # mapping freshness report
bash scripts/pack-tracker.sh doctor     # config + integrity check
bash scripts/pack-tracker.sh disable    # reverse migration; back to flat-file
```

`tracker.toml` lives at the repo root (project) or pack root (pack
repo). The example template at `tracker.toml.example` is installed by
`init-project.sh` at v11.

**How to use the pack's pieces with it** — once opted in, every
`auditor-issue-tracking` agent run (pack-side or client-side) reads
issue state via the TrackerProvider, not by parsing `BACKLOG.md`. PM
chat / Pack chat queries route through the same provider so prompts
stay accurate as issues evolve.

**Caveats**

- The forward migration is idempotent but rewrites issue bodies on
  every run; a heavily-edited issue body may need
  `customization-detected-needs-reconciliation` resolution similar to
  BD-088's contract. See `MERGE-STRATEGY.md`.
- The `gh` backend requires `gh auth login` against the right account
  and `gh repo view` succeeding from the repo. CI-only tokens may lack
  required scopes.
- Reverse migration writes a sidecar BACKLOG.md from the live issues —
  it does NOT recover prior flat-file content. Use `git` for that.
- Multi-project: tracker config is per-repo, not pack-wide.

**When to skip** — if your BD volume is under ~50 open and BACKLOG.md
search is comfortable, the tracker round-trip is more friction than
flat-file. The recommendation system will not nag in this regime.

---

## Adding new entries

When a CLI ships an optional or experimental feature that the Config Pack
can plug into, add a section here following the same shape as the Agent
Teams entry above:

- **Status** — version requirement, experimental flag, supported tool
- **What it is** — one paragraph plus a link to official docs
- **When it matters** — what kinds of pack workflows benefit
- **How to enable** — config / env-var change
- **How to use the pack's pieces with it** — concrete example(s)
- **Caveats** — known limitations, scope boundaries, cost considerations
- **When to skip** — counter-cases where the feature does not help
