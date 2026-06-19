# Optional Features and Settings

This file documents tool-specific features and settings that your project
can opt into without abandoning the cross-CLI parity the Config Pack
provides by default. Each entry is independent — turning one on does not
affect the rest of the pack, and the standard PM Chat workflow continues
to work identically across Claude Code, Codex CLI, and Antigravity CLI.

These features tend to be:
- **Tool-specific** (only available in one CLI)
- **Experimental** (gated by an env var or a version requirement)
- **Higher-cost** (more tokens, more setup, or more moving parts)

Your project stays cross-CLI by default. Opt in per-feature when the
benefit outweighs the asymmetry.

---

## Claude Code — Agent Teams

**Status:** Experimental in Claude Code v2.1.32+, gated by an environment
variable. Claude Code only — no Codex or Antigravity CLI equivalent.

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

## Claude Code — Isolated parallel agents (worktree isolation)

**Status:** Claude Code only — no Codex or Antigravity CLI equivalent yet (the
cross-CLI worktree story is tracked separately and is out of scope here). The
subagent-isolation trigger is a per-spawn Agent-tool parameter; the base
posture is a `settings.json` key you set manually. The pack ships NO settings
file — you add the keys to your OWN settings (see below).

**What it is.** When the PM chat spawns a read-write agent (your `coder`, or
`repo-ops` for scripted writes) in the background to make edits in parallel, it
isolates that agent in its own git worktree so the agent's edits never touch
your main working tree directly. The first coder of a commit creates the
worktree; the ENTIRE review/fix cycle for that commit runs inside it — the
read-only reviewer reads the work there and a fix-coder REUSES that same
worktree (never a new one). The read-write agent does NOT emit a patch up front
(the work may still be wrong); the patch is produced ONLY after the reviewer
confirms the work clean, by re-engaging the most-recent read-write agent (in
Claude Code, via the Agent-team peer-message path; if your CLI offers no
peer-messaging, re-spawn a fresh coder against the worktree to produce it). The
PM chat then applies that reviewed-clean patch onto your branch and commits —
the agent itself never stages or commits (the no-state-changing-git contract is
preserved end-to-end). Read-only agents (your `architect`, `reviewer`,
`planner`, the `auditor` family, and the other report-only profiles) run in the
tree the work lives in — your main tree when the work is committed, the live
worktree when the work is still uncommitted there (they cd in and verify
pwd/HEAD at runtime). They write a report and emit no patch. The in-session
spawn + merge-back procedure lives in `docs/pack/PM-CHAT.md` ("In-session agent
spawning").

**When this matters for your project.** Read-write agents run isolated by class,
so isolation always applies to your `coder`/`repo-ops` work; it especially
matters when the PM chat spawns SEVERAL read-write agents in parallel and you do
not want their edits to collide in one shared working tree, or when you want a
clean patch-handoff boundary for each coder. If isolation is unavailable (an
environment without worktree support), the in-place (non-isolated) regime is the
DEGRADED fallback — it still works without any settings, but it exposes
in-progress work to your main tree, which is exactly what the isolated default
avoids.

**How to enable isolated parallel subagents — TWO INDEPENDENT mechanisms.**
The feature is governed by two orthogonal knobs. Do not conflate them.

1. **TRIGGER (per task) — the per-spawn Agent-tool `isolation` parameter.**
   The PM chat passes the Agent-tool `isolation:"worktree"` parameter PER SPAWN
   when it isolates a read-write agent. `"worktree"` is the ONLY valid value for
   this parameter — `head` and `none` are SETTINGS values (see
   `baseRef`/`bgIsolation` below), NOT parameter values. This is a per-spawn
   decision the PM chat makes; it is not a `settings.json` key, and the PM chat
   does NOT isolate by writing settings (that would conflict with the
   no-write-settings posture and could surprise another session sharing the same
   checkout). Do NOT pin `isolation:"worktree"` in any read-write agent's
   definition frontmatter: because the parameter has only the single value
   `"worktree"`, a frontmatter pin forces a NEW worktree on EVERY spawn — so a
   fresh fix-coder could not cd into and REUSE the first coder's worktree, which
   breaks the reuse / in-worktree-cycle / lifecycle rules. Isolation is the
   PM chat's per-spawn choice, not a definition-level pin.

2. **BASE (REQUIRED setting) — `worktree.baseRef`.** Set
   `worktree.baseRef: "head"` in your `settings.json` so an isolated worktree
   branches from your LOCAL HEAD (the branch you are working on). The valid
   values are `"head"` and `"fresh"`.
   - **Consequence if unset:** `baseRef` defaults to `"fresh"`, which branches
     the worktree from `origin/<default>` (i.e. `origin/main`) — the historical
     "checks out main" wrong-base behavior. An isolated agent would then base
     its work at `origin/main`, NOT your current branch. The work still
     functions (the patch still applies onto your branch), but it is the wrong
     base — so `baseRef: "head"` is REQUIRED for branch work.
   - **Where it lives:** put `worktree.baseRef: "head"` in `settings.json` at
     PER-PROJECT scope (`.claude/settings.json` in your repo, recommended) OR at
     GLOBAL scope (`~/.claude/settings.json`, which affects every project on
     your machine — your choice).

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
`EnterWorktree`/`ExitWorktree` flow: `"worktree"` blocks Edit/Write in the main
checkout until `EnterWorktree` is called; `"none"` lets background jobs edit the
working copy directly. `bgIsolation` does NOT control Agent-tool subagents — it
is not the subagent-isolation trigger, and it is not a boolean
(`bgIsolation: true` is invalid). The background-session isolation story is a
separate concern slated for a future pack version; do not set `bgIsolation`
expecting it to isolate the agents the PM chat spawns.

**In-session destructive-git-verb backstop — the documented-optional
`permissions.deny` recipe.** The default protection for in-session sub-agents is
the always-on PROSE deny-list every agent reads (the no-state-changing-git rule
in your project trinity `CLAUDE.md`/`AGENTS.md`/`GEMINI.md`, the
`commit-discipline` skill, and each agent's own definition file) plus the
behavioral contract that agents never stage, commit, or run any other
working-tree- or ref-mutating git verb. On top of that, you can add an OPTIONAL
mechanical hard-deny that the pack DOES NOT ship — you add it to YOUR OWN
`settings.json` (user or project scope). In the Claude Code permission model, a
`permissions.deny` block is SESSION-SCOPED and INHERITED by all in-session
sub-agents (including background ones) and is deny-first (it is NOT bypassed by
`bypassPermissions`). It is the ONLY in-session mechanical layer available: an
agent-definition `tools:` field cannot deny a specific git sub-verb (it is
tool-name-level only), and there is no per-spawn tool-deny parameter. List the
destructive git verbs as scoped `Bash` rules:

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

This recipe is VERB-PRECISE: it denies `Bash(git apply:*)` (the patch-APPLYING
form, which only the PM chat runs) but NEVER `Bash(git diff:*)` — `git diff` is
the agent's read-only patch-emit and must stay allowed (the `git diff > file`
redirection is a shell-level construct, not a git verb, so it is not tripped). A
user `PreToolUse` hook (matcher `Bash`, returning `permissionDecision: "deny"`
for the same verbs) is a SECONDARY defence-in-depth option only — its
`if`-matcher fails OPEN, so `permissions.deny` is the documented-primary
mechanical layer. The pack ships neither the settings file nor the hook; this is
a recipe you opt into. Without it, the in-session protection degrades to the
always-on prose deny-list plus the behavioral contract (still load-bearing, just
not mechanically enforced).

**The `agent-run.sh --worktree` launcher (a SECONDARY path).** Separate from the
in-session spawn above, `agent-run.sh` carries an optional `--worktree [path]`
flag (claude only) that runs `claude --agent <name>` inside an isolated git
worktree for a human-driven parallel-agent run. It bases the worktree at your
CURRENT HEAD deterministically with `git worktree add --detach <path> HEAD`, so
it does NOT depend on the `worktree.baseRef` setting — it works on a fresh
client with no settings file, and your branch HEAD is always the base, never
`origin/main`. The launcher is SECONDARY/opt-in with a cwd-scoping caveat:
whether `claude --agent` launched with its cwd inside a worktree reliably keeps
ALL of its git operations scoped to that worktree (rather than leaking to the
parent repo) is environment- and version-dependent. Probe it ONCE before
relying on it — run `./agent-run.sh claude --agent coder --worktree`, then in
your main checkout run `git status` and confirm the main working tree is
unchanged. If the probe shows the agent's git leaked into the parent repo, do
NOT use `--worktree`; fall back to the manual procedure (below). Either way the
agent still never stages or commits — the PM chat runs the review/fix cycle in
the worktree and brings back the reviewed-clean patch, same merge-back model as
the in-session spawn path (`docs/pack/PM-CHAT.md`). See the `run_in_worktree`
comment in `agent-run.sh` for the full caveat.

**Caveats.**
- **Version-sensitive.** Worktree isolation behavior has shifted across Claude
  Code releases; confirm your version's behavior before relying on it.
- **Auto-removal can delete unmerged branches.** When an isolated subagent exits
  cleanly, Claude Code can auto-remove its worktree and branch — a branch with
  unmerged commits can be silently deleted. That mechanism is exactly why the PM
  chat does NOT rely on auto-removal: it HOLDS the commit's worktree through the
  whole review/fix cycle and removes it explicitly only AFTER the commit lands (a
  failed commit KEEPS the worktree). The patch is produced post-review-clean and
  applied at commit time, never captured pre-return, so reviewed-clean work
  reaches your branch and nothing in-progress is lost to a teardown.
- **Best-effort isolation / silent fall-to-main.** Isolation can silently fall
  back to editing the main checkout. Each agent therefore VERIFIES its actual
  regime from its own runtime pwd/HEAD ground-truth (where it is actually
  running, what its HEAD actually is), never from an assumed settings value or a
  patch-handoff signal.
- **`baseRef` unset/`fresh` wrong-base.** As above, an unset/`fresh` `baseRef`
  bases isolated work at `origin/main` rather than your branch — a documented
  degradation, surfaced by the PM chat, never silent.

**The pack ships NO settings file.** You add `worktree.baseRef`,
`worktree.bgIsolation` (if you use background sessions), and the
`permissions.deny` recipe to your OWN `settings.json`. The pack documents these
keys; it never writes a settings file into your repo.

**Claude-only note.** This feature is specific to Claude Code's Agent-tool
`isolation` parameter and `worktree` settings. Codex CLI and Antigravity CLI
have no equivalent at this time; their worktree story is tracked separately and
is out of scope here. There is no cross-CLI parity claim for this feature.

**Manual worktree (no pack mechanism needed).** If you simply want to work on
parallel branches yourself, run `git worktree add ../my-worktree <branch>` by
hand and open a separate session in that directory — that is plain git and needs
nothing from the pack; the pack only guarantees that nothing it ships breaks
inside a manual worktree.

---

## Codex CLI — Optional features

*Placeholder. The Config Pack will document Codex-specific opt-in
features here as they ship and prove useful.*

---

## Antigravity CLI — Optional features

<!-- RE-VERIFY at impl: Antigravity worktree feature, antigravity.google/docs/getting-started -->

**Status:** Forward-looking — no opt-in steps to run today.

**Worktree-based parallel agents.** Antigravity CLI is expected to offer a
worktree mode for running isolated parallel agents (analogous to the Claude
Code "Isolated parallel agents" entry above), with automatic worktree
cleanup. The cross-CLI worktree story — bringing Codex and Antigravity into
parity with the Claude Code isolation model — is tracked separately and is
out of scope for the base pack. There are no Antigravity-specific opt-in
settings to configure at this time; this section will document them once the
Antigravity worktree feature stabilizes (the feature and its CLI surface are
in preview and have open data-loss reports, so the pack ships nothing that
depends on it yet). Re-verify the worktree behavior against
`antigravity.google/docs/getting-started` before relying on it.

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

## CI test parallelization (GitHub Actions matrix)

**Status:** Standard GitHub Actions — available on all plan tiers (Free,
Team, Enterprise), all account types (personal and organization), and all
runner types (`ubuntu-latest` and self-hosted alike). Platform-agnostic —
works with any test framework and any language.

**What it is.** When your project's CI runs many independent test suites
sequentially in a single job, wall-clock time accumulates linearly with
the number of suites. GitHub Actions `strategy: matrix` distributes a set
of test scripts (or other tasks) across parallel runners, so total
wall-clock time drops from Σ(all suites) to max(slowest suite) — without
dropping any test or weakening any assertion. Combined with `fail-fast:
false`, every suite runs in every push even when an earlier one fails,
preserving full failure visibility. An aggregation job (`if: always()` +
an explicit success assertion on the matrix result) serves as the single
stable required status check regardless of shard count.

**When this matters for your project.** This is worth doing when: (a) your
CI has multiple independent test suites running in one job, (b) total
wall-clock time is causing friction (slow feedback, queue pile-ups), and
(c) the test suites can each run independently on a clean runner (no
hard inter-suite ordering dependency). A single-suite project or a project
whose CI already completes quickly does not benefit.

**How to enable.** No external service or paid feature is required — this
is a standard GitHub Actions workflow pattern. Add three jobs to your
workflow:

1. **`plan` job** — an upstream job that computes the test partition and
   writes it to `$GITHUB_OUTPUT` as JSON:
   ```yaml
   plan:
     runs-on: ubuntu-latest
     outputs:
       matrix: ${{ steps.plan.outputs.matrix }}
     steps:
       - uses: actions/checkout@v4
       - id: plan
         run: echo 'matrix={"include":[{"suite":"unit"},{"suite":"integration"}]}' >> "$GITHUB_OUTPUT"
   ```
   Replace the static `include` list with a dynamic generator script if
   your suite list grows or changes.

2. **`tests` job** — a matrix job that consumes the partition:
   ```yaml
   tests:
     needs: [plan]
     runs-on: ubuntu-latest
     strategy:
       fail-fast: false   # surface ALL failures, not just the first
       matrix: ${{ fromJSON(needs.plan.outputs.matrix) }}
     steps:
       - uses: actions/checkout@v4
       - name: run suite ${{ matrix.suite }}
         run: bash scripts/test-${{ matrix.suite }}.sh
   ```

3. **`tests-result` aggregation job** — the single required status check:
   ```yaml
   tests-result:
     needs: [plan, tests]
     if: always()
     runs-on: ubuntu-latest
     steps:
       - name: assert all suites passed
         run: |
           echo "tests result = ${{ needs.tests.result }}"
           test "${{ needs.tests.result }}" = "success"
   ```

**Required-status-check rename consideration.** If your branch protection
requires a check named `tests`, converting `tests` to a matrix renames
the check to `tests (suite-name)` per combination — the old `tests` check
disappears. Before merging the matrix change, update your branch
protection rule to require `tests-result` (the aggregation job) instead of
`tests`. This is a one-time admin step; `tests-result` then remains stable
regardless of how many suites you add or remove.

**No pack-specific setup needed.** Your project's existing test scripts
(`scripts/test.sh`, `scripts/test-swift.sh`, `scripts/test-python.sh`,
etc.) run inside the matrix exactly as they would in any shell step — no
changes to the scripts themselves. The matrix controls orchestration; the
scripts remain standalone and human-runnable locally without change.

**Caveats.**
- **Suite independence is required.** Each matrix combination runs on a
  fresh runner with a clean checkout. Suites that depend on shared mutable
  state (a running database, a network service, a shared file) need that
  state to be self-provisioned per runner (Docker service containers, or
  a setup step that creates the fixture from scratch).
- **Fixture build cost is paid per shard.** If a suite requires a
  build artifact (compiled binaries, generated files, test fixtures),
  each runner that needs it builds it independently unless you use GitHub
  Actions artifact upload/download between jobs. For short builds the
  overhead is acceptable; for long builds consider caching or a
  pre-build job.
- **Slow single test within a suite sets the floor.** Parallelizing
  suites helps only at the suite level. If one suite contains a single
  test that takes 90 s, that suite cannot finish faster than 90 s
  regardless of how many shards you add. Split long-running individual
  tests into separate suites to lower the floor.
- **`fail-fast: false` is required.** The default (`fail-fast: true`)
  cancels sibling matrix combinations when one fails — you lose failure
  visibility across suites. Always set `fail-fast: false` for test
  matrices.

**When to skip.** CI already fast or single-suite; test suites have
hard inter-suite ordering dependencies; project does not use GitHub
Actions.

---

## Adding new entries

If your project adopts a CLI-specific opt-in feature the pack does not
yet document, add a section here following the same shape as the Agent
Teams entry above: Status, What it is, When it matters, How to enable,
How to use the pack's pieces with it, Caveats, When to skip. Most
projects will not need to add entries — the pack ships the common
cross-CLI feature catalog.
