# Optional Features and Settings

This file documents tool-specific features and settings that the Config Pack
can opt into but does not require. Each entry is independent — turning one
on does not affect the rest of the pack, and the standard
PM-Chat-coordinated workflow continues to work identically across Claude
Code, Codex CLI, and Antigravity.

These features tend to be:
- **Tool-specific** (only available in one CLI)
- **Experimental** (gated by an env var or a version requirement)
- **Higher-cost** (more tokens, more setup, or more moving parts)

The Config Pack stays cross-CLI by default. Opt in per-feature when the
benefit outweighs the asymmetry.

---

## Claude Code — Agent Teams

**Status:** Experimental in Claude Code v2.1.32+, gated by an environment
variable. Claude Code only — no Codex or Antigravity equivalent.

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
- **Claude Code only.** A team session does not exist in Codex or Antigravity.
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

## Claude Code — Isolated parallel agents (worktree isolation)

**Status:** Claude Code only — no Codex or Antigravity equivalent yet (the
cross-CLI story is tracked separately and is out of scope here). The
subagent-isolation trigger is a per-spawn Agent-tool parameter; the base
posture is a `settings.json` key the developer sets manually. The pack ships
NO settings file — you add the keys to your OWN settings (see below).

**What it is.** When Pack Chat spawns a read-write agent (a coder) in the
background to make edits in parallel, it can isolate that agent in its own
git worktree so the agent's edits never touch the parent working tree
directly. The agent edits in the worktree, emits a `git diff` patch to a
named handoff directory, and returns; Pack Chat reads the patch, runs the
review/fix cycle, applies it onto the parent branch, and commits — the agent
itself never stages or commits (the `agents-never-commit` contract is
preserved end-to-end). Read-only agents (reviewers, architects, planners,
researchers) need NO isolation — they emit a report and write nothing to the
tree.

**When this matters for the Config Pack.** Isolation matters when you spawn
SEVERAL read-write agents in parallel and do not want their edits to collide
in one shared working tree, or when you want a clean patch-handoff boundary
for each coder. For a single sequential coder it is optional; the in-place
(non-isolated) regime is the default floor and works without any settings.

**How to enable isolated parallel subagents — TWO INDEPENDENT mechanisms.**
The feature is governed by two orthogonal knobs. Do not conflate them.

1. **TRIGGER (per task) — the per-spawn Agent-tool `isolation` parameter.**
   The orchestrator chat (Pack Chat) decides per spawn whether an agent runs
   isolated, by passing the Agent-tool `isolation:"worktree"` parameter.
   `"worktree"` is the ONLY valid value for this parameter — `head` and
   `none` are SETTINGS values (see `baseRef`/`bgIsolation` below), NOT
   parameter values. Omit the parameter to run the agent in-place (the
   default). This is a per-spawn decision the chat makes; it is not a
   `settings.json` key, and the chat does NOT isolate by writing settings
   (that would conflict with the no-write-settings posture and could surprise
   another chat sharing the same clone).

2. **BASE (REQUIRED setting) — `worktree.baseRef`.** Set
   `worktree.baseRef: "head"` in your `settings.json` so an isolated worktree
   branches from your LOCAL HEAD (your current feature branch). The valid
   values are `"head"` and `"fresh"`.
   - **Consequence if unset:** `baseRef` defaults to `"fresh"`, which
     branches the worktree from `origin/<default>` (i.e. `origin/main`) — the
     historical "checks out main" wrong-base behavior. An isolated agent
     would then base its work at `origin/main`, NOT your feature branch.
     The work still functions (the patch still applies onto the parent), but
     it is the wrong base — so `baseRef: "head"` is REQUIRED for
     feature-branch work.
   - **Where it lives:** put `worktree.baseRef: "head"` in `settings.json`
     at PER-PROJECT scope (`.claude/settings.json` in the repo, recommended)
     OR at GLOBAL scope (`~/.claude/settings.json`, which affects both the
     pack repo and any project — your choice).

   ```json
   {
     "worktree": {
       "baseRef": "head"
     }
   }
   ```

**Background sessions are a SEPARATE mechanism (not this feature).**
`worktree.bgIsolation` (enum `["worktree", "none"]`, default `"worktree"`)
governs TOP-LEVEL background `claude` sessions via the
`EnterWorktree`/`ExitWorktree` flow: `"worktree"` blocks Edit/Write in the
main checkout until `EnterWorktree` is called; `"none"` lets background jobs
edit the working copy directly. `bgIsolation` does NOT control Agent-tool
subagents — it is not the subagent-isolation trigger, and it is not a
boolean (`bgIsolation: true` is invalid). The background-session isolation
story is tracked under BD-218 (v11.1); do not set `bgIsolation` expecting it
to isolate subagents.

**In-session destructive-git-verb backstop — the documented-optional
`permissions.deny` recipe.** The pack's load-bearing default protection for
in-session sub-agents is the always-on PROSE deny-list (the
`agents-never-commit` rule + the destructive-verb enumeration carried in the
trinity, the `commit-discipline` skill, and the agent files) plus the
`agents-never-commit` behavioral contract. On top of that, you can add an
OPTIONAL mechanical hard-deny that the pack DOES NOT ship — you add it to
YOUR OWN `settings.json` (user or project scope). Per the Claude Code
permission model, a `permissions.deny` block is SESSION-SCOPED and INHERITED
by all in-session sub-agents (including background ones) and is deny-first
(it is NOT bypassed by `bypassPermissions`). It is the ONLY in-session
mechanical layer available: an agent-definition `tools:` field cannot deny a
specific git sub-verb (it is tool-name-level only), and there is no per-spawn
tool-deny parameter. List the destructive git verbs as scoped Bash rules:

```json
{
  "permissions": {
    "deny": [
      "Bash(git commit:*)",
      "Bash(git push:*)",
      "Bash(git add:*)",
      "Bash(git stash:*)",
      "Bash(git reset:*)",
      "Bash(git restore:*)",
      "Bash(git checkout:*)",
      "Bash(git apply:*)",
      "Bash(git worktree:*)",
      "Bash(git clean:*)",
      "Bash(git merge:*)",
      "Bash(git rebase:*)"
    ]
  }
}
```

This recipe is VERB-PRECISE: it denies `Bash(git apply:*)` (the
patch-APPLYING form, which only the orchestrator runs) but NEVER
`Bash(git diff:*)` — `git diff` is the agent's read-only patch-emit and must
stay allowed (the `git diff > file` redirection is a shell-level construct,
not a git verb, so it is not tripped). A user `PreToolUse` hook (matcher
`Bash`, returning `permissionDecision: "deny"` for the same verbs) is a
SECONDARY defence-in-depth option only — its `if`-matcher fails OPEN, so
`permissions.deny` is the documented-primary mechanical layer. The pack
ships neither the settings file nor the hook; this is a recipe you opt into.
Without it, the in-session protection degrades to the always-on prose
deny-list plus the behavioral contract (still load-bearing, just not
mechanically enforced).

**Caveats.**
- **Version-sensitive.** Worktree isolation behavior has shifted across
  Claude Code releases; confirm your version's behavior before relying on it.
- **Auto-removal can delete unmerged branches.** When an isolated subagent
  exits cleanly, Claude Code auto-removes its worktree and branch. A branch
  with unmerged commits can be silently deleted — which is why the pack's
  merge-back model captures the agent's work as a patch in the handoff
  directory BEFORE return (the patch survives auto-removal), and why agents
  never commit.
- **Best-effort isolation / silent fall-to-main.** Isolation can silently
  fall back to editing the main checkout. The orchestrator therefore detects
  the ACTUAL regime from what the agent reports (a patch handoff ⇒ isolated;
  in-place edits ⇒ in-place), never from an assumed settings value.
- **`baseRef` unset/`fresh` wrong-base.** As above, an unset/`fresh`
  `baseRef` bases isolated work at `origin/main` rather than your branch —
  documented degradation, surfaced by the orchestrator, never silent.

**The pack ships NO settings file.** You add `worktree.baseRef`,
`worktree.bgIsolation` (if you use background sessions), and the
`permissions.deny` recipe to your OWN `settings.json`. The pack documents
these keys; it never writes a settings file into the repo.

**Trinity-exempt note (Claude-only).** This feature is specific to Claude
Code's Agent-tool `isolation` parameter and `worktree` settings. Codex CLI
and Antigravity have no equivalent at this time; their worktree story is
tracked under BD-217 (v11.1). There is no cross-CLI parity claim here.

**Manual worktree (no pack mechanism needed).** If you simply want to work
on parallel branches yourself, run `git worktree add ../my-worktree
<branch>` by hand and open a separate session in that directory — that is
plain git and needs nothing from the pack; the pack only guarantees nothing
it ships breaks inside a manual worktree.

---

## Codex CLI — Optional features

*Placeholder. The Config Pack documents Codex-specific opt-in features
here once they ship and prove useful.*

---

## Antigravity — Optional features

*Placeholder. The Config Pack documents Antigravity-specific opt-in features
here once they ship and prove useful.*

---

## Tracker integration (deferred)

**Status** — DEFERRED indefinitely, with no release version (BD-214).
**Flat-file per-entry is the sole supported mode.** There are no opt-in
steps.

**What it was** — a planned, opt-in mode that would move issue tracking
out of the `/backlog/` flat-file format into GitHub Issues (or another
tracker via the TrackerProvider abstraction), with forward / reverse
migration and an inflection-point recommendation system. The design
shipped as DORMANT code (`scripts/lib/tracker-*.sh`,
`scripts/pack-tracker.sh`, `scripts/lib/recommendation.sh`,
`scripts/tracker-migrate.sh`) and is retained, test-covered, for a
future resumption.

**Why it is deferred** — the ability to flip to tracker mode is BLOCKED
on both surfaces (`tracker_mode()` clamps to flat-file; the
`pack tracker` flip verbs refuse with a deferred message). Resumption is gated
on the entry-format redesign (BD-215) landing first.

**What ships today** — the dormant code and the committed example
templates (`tracker.toml.pack-example`,
`project-template/tracker.toml.project-example`) remain in the tree as a
record of the dormant feature. No surface opts any repo into tracker
mode, and even a hand-copied `tracker.toml` is inert under the
flat-file clamp.

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
