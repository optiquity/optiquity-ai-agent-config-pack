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
background to make edits, it isolates that agent in its own git worktree so
the agent's edits never touch the parent working tree directly. The agent
edits in the worktree, runs its verification, writes its report, and
returns — it does NOT emit a patch up front. The ENTIRE review/fix cycle for
that commit runs inside that one worktree (the reviewer reads the work
there; the fix-coder REUSES the same worktree). The patch is produced ONLY
after the reviewer confirms the work clean: Pack Chat SendMessage-s the
most-recent read-write agent to emit it, then `git apply`s the
reviewed-clean patch onto the parent branch and commits — the agent itself
never stages or commits (the `agents-never-commit` contract is preserved
end-to-end). Read-only agents (reviewers, architects, planners, researchers)
run in the tree the work lives in — the main checkout when the work is
committed, the commit's live worktree when the work is still uncommitted
there (they cd in + verify pwd/HEAD); they emit a report and no patch.

This isolation is the **default by agent class**, not an opt-in accelerator:
read-WRITE agents are isolated by class, read-ONLY agents run in the work's
tree. A read-write subagent must NOT pin `isolation:"worktree"` in its
definition frontmatter — the `isolation` parameter has only the value
`"worktree"` (there is no `"off"`; see below), so a frontmatter pin would
force a NEW worktree on EVERY spawn, and a fresh fix-coder could then not
cd-REUSE the first coder's worktree (breaking the per-commit-worktree reuse
that keeps the whole review/fix cycle in one tree). Isolation is decided
per-spawn by the orchestrator, never pinned in a definition.

**When this matters for the Config Pack.** Isolation is the class-keyed
default — every read-write agent runs in its own worktree so its
not-yet-reviewed edits never reach the canonical tree, and several
read-write agents can run in parallel without their edits colliding in one
shared working tree. The in-place (non-isolated) regime is NOT the default:
it is the DEGRADED fallback the agent self-detects at runtime (pwd/HEAD
ground-truth) when, despite the class default, isolation did not actually
take effect (a platform fall-to-main, or a CLI without worktree support).
When in-place is in force, the agent still keeps work out of the canonical
tree only through the prose deny-list + behavioral contract, not the
worktree boundary — which is why class-keyed isolation, not in-place, is the
intended posture.

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
  with unmerged commits can be silently deleted — which is why the worktree
  is HELD through the whole review/fix cycle and explicitly removed only
  AFTER the commit lands (the lifecycle rule: tear down a worktree only once
  its commit is confirmed landed; a failed commit KEEPS it), and the patch
  is produced post-review-clean, never pre-return. Pack Chat never relies on
  auto-removal, and agents never commit.
- **Best-effort isolation / silent fall-to-main.** Isolation can silently
  fall back to editing the main checkout. The agent therefore detects its
  ACTUAL regime from its own runtime pwd/HEAD ground-truth (a
  `worktree-agent-*` pwd/HEAD ⇒ isolated; otherwise the degraded in-place
  fallback), never from an assumed settings value — settings can lie, so the
  runtime self-detect is the only deterministic signal.
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
on both surfaces (`tracker_mode()` clamps to flat-file; the tracker flip
verbs refuse with a deferred message). Resumption is gated
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

---

## Graphify — knowledge-graph context (pack-dev)

**Status:** Pack-development only — NOT a client feature. Target binary
`graphify 0.8.39`. The graph and the initial build are a per-clone,
gitignored, MANUAL opt-in: a maintainer who does nothing gets exactly today's
behavior, and clients are entirely unaffected (nothing graphify ships in the
config pack; no `project-template/` file is touched). The refresh hook is a
TRACKED hook body (`scripts/hooks/graphify-pre-push.sh`) with a one-time
per-clone install (`bash scripts/install-graphify-hook.sh`) — only the
installed `.git/hooks/pre-push` copy is per-clone (BD-237). The committed
scaffolding is the repo-root `.graphifyignore`, the `.gitignore` entry for
`graphify-out/`, the pack-root-trinity graph-first rule (plus its
`graph-first-context` rationale section), CI Check 63, the tracked pre-push
hook body + installer (BD-237), and this runbook (BD-225/BD-237).

**What it is.** Graphify builds a compact knowledge graph of the repo
(structural code relationships + a semantic layer over docs/comments) that
agents and Pack Chat can QUERY for orientation / relationship / blast-radius
questions at roughly zero tokens, instead of broad tree reads. The graph-first
rule in the pack-root trinity (`### Repo conventions`, tagged
`[rationale: graph-first-context]`) governs WHEN to prefer the graph and when
to fall through to grep/Read; this section is the SETUP + PRIVACY + MAINTENANCE
runbook for the per-clone build.

**When it matters for the pack.** The pack repo is doc-, reference-, and
agent-heavy; agents repeatedly re-read the file tree for context, which is
token-expensive. A compact subgraph answers "what relates to X / where does Y
live / blast radius of Z" deterministically and locally. Querying is
read-only, deterministic, and ~0 tokens — only BUILDING or refreshing the
semantic doc layer costs the Claude subscription. Agents QUERY; they never
BUILD (build is a one-time main-session / orchestrator job).

### Privacy / secrets (read before you build — D3)

- **What leaves the machine.** The AST / code pass is 100% local and never
  leaves the machine. The SEMANTIC pass sends NON-CODE text (docs, PDFs,
  comments) to the model — code is not sent. Know this before the first build.
- **A classifier refusal is a CORRECT SAFETY STOP, not a bug.** Graphify's
  auto-mode classifier may REFUSE to run the semantic pass on a
  secrets-adjacent repo. Treat a refusal as the safety feature working:
  INVESTIGATE what tripped it; do NOT blindly override. This repo is less
  secrets-adjacent than dotfiles (only synthetic fixtures plus `.example`
  files), and the `.graphifyignore` (repo root) excludes all `.env` files,
  `.mcp.json`, and `.claude/settings.local.json`, which removes the
  secrets-shaped inputs from the semantic pass.
- **Backend = Claude subscription ONLY.** Pin `--backend claude-cli` on every
  `extract` invocation. THE STALE-ENUM CAVEAT (load-bearing): the top-level
  `graphify --help` `--backend` enum OMITS `claude-cli`, but `claude-cli` IS
  valid (it is surfaced by the invalid-backend error) and is the NO-KEY
  subscription path. Do NOT "fix" `claude-cli` → `claude` to match the help:
  `--backend claude` requires `ANTHROPIC_API_KEY` and is NOT the subscription
  path. Substituting `claude` for `claude-cli` is the single
  highest-consequence error in this integration.
- **The paid-API auto-route foot-gun.** If `GEMINI_API_KEY`, `GOOGLE_API_KEY`,
  or `OPENAI_API_KEY` is set in the environment, graphify routes the semantic
  pass to that PAID API. Defense-in-depth: the pre-push hook unsets all
  three in its own subshell AND every `extract` line pins `--backend
  claude-cli` explicitly. Keep no API key anywhere in pack config.
- **Ignore the SKILL.md "set `GEMINI_API_KEY`" tip** — it conflicts with the
  subscription-only policy. NO Ollama (a working no-key path, `claude-cli`,
  already exists). NO neo4j / falkordb / video extras — they are absent on the
  build machine and any such export would `ModuleNotFoundError`; out of scope.

### How to enable — one-time initial build (interactive, main session)

The first build is a one-time interactive main-session job; it produces NO
committed artifact (the graph is gitignored and per-clone) and cannot be fully
automated, because the corpus trips BOTH narrow-gates (1,373 indexable files >
500; ~2.65M `.md` words > 2,000,000). The irreducible MANUAL / permission
points:

1. **Narrow-gate decision.** Run the interactive `/graphify .` build; it warns
   and asks which subfolder to narrow to — answer **"proceed whole-repo"**
   (start big), with `--no-viz` ON and clustering ON. (`--no-viz` is a
   build/skill flag of the initial `/graphify .` build ONLY — see the §1.1
   caveat below; never pass it to `extract`.)
2. **First headless `claude -p` permission prompt.** The first time the
   semantic path runs headless, Claude Code may prompt for permission —
   confirm once per machine.
3. **Classifier refusal = correct safety stop.** If the classifier refuses,
   investigate; do NOT auto-override (see Privacy above).
4. **Per-clone / per-machine install.** `graphify-out/` and the global graph
   do NOT sync across clones or machines — each machine builds its own (the
   graph is gitignored). The refresh hook BODY *is* committed
   (`scripts/hooks/graphify-pre-push.sh`); only the INSTALLED
   `.git/hooks/pre-push` copy is per-clone — run `bash
   scripts/install-graphify-hook.sh` once per clone to wire it in (BD-237).
5. **Env-key hygiene.** One-time confirm that `GEMINI_API_KEY`,
   `GOOGLE_API_KEY`, and `OPENAI_API_KEY` are unset.

The initial build produces `graphify-out/cost.json` (the measured token-cost
tracker). That file is the input **BD-234** consumes to confirm or re-tune
cadence, knobs, and scope after burn-in. Cadence direction is LOCKED for now;
do NOT change cadence here — BD-234 re-tunes with measured numbers.

### How to keep it fresh — the pre-push hook (tracked body + one-time install, BD-237)

The maintenance mechanism is a TRACKED, self-installed, GUARDED, NON-BLOCKING,
doc-gated `pre-push` hook that auto-refreshes the graph IN THE BACKGROUND on
every `git push`. Unlike the old hand-installed `post-commit` recipe, the hook
BODY is versioned in the repo (`scripts/hooks/graphify-pre-push.sh`) so it
cannot rot from "nobody copied the recipe"; only the per-clone INSTALL is
manual (one command). Its LOAD-BEARING shape is: drain stdin + derive the
pushed-range doc-gate → resolve the push-invoking worktree
(`$(git rev-parse --show-toplevel)`) + an existence guard → a graphify-exec
guard → a `mkdir`-atomic skip-lock (a second concurrent push SKIPS, never
blocks) → a dual-signal next-run consult → a background-detached key-clean
subshell that `cd`s into the root and runs the chosen branch (semantic
`extract` for a doc change, else the free code-only `update`) with a single
self-retry and an atomic result record → an unconditional foreground `exit 0`
so a refresh problem NEVER blocks the push.

**Install (one-time, per clone):**

```bash
bash scripts/install-graphify-hook.sh
```

This copies `scripts/hooks/graphify-pre-push.sh` into this clone's shared
common git hooks dir (`$(git rev-parse --git-path hooks)/pre-push`), makes it
executable, and is idempotent (a byte-equal re-install is a no-op). One install
serves all linked worktrees of a clone (they share the common `.git/hooks`
dir). The installer is a `cp`+`chmod` (not a git verb), but it mutates the live
`.git/hooks` dir, so the orchestrator runs it with user approval — never an
agent.

**Worktree-safety (correct stamp, no cross-tree surprise).** The hook resolves
`ROOT="$(git rev-parse --show-toplevel)"` — the push-invoking worktree — and
silently no-ops (`exit 0`) if `$ROOT/graphify-out` does not exist (e.g. a
worktree with no graph). The refresh subshell `cd`s into `$ROOT` BEFORE
invoking graphify, because graphify's `_git_head()` runs `git rev-parse HEAD`
against the process CWD (no `-C`, no `chdir`): with CWD = `$ROOT`, the stamped
`built_at_commit` is `$ROOT`'s own HEAD. The two branches are pinned to
`$ROOT/graphify-out` differently:

- **Code branch** (`update`): `GRAPHIFY_OUT="$ROOT/graphify-out" graphify
  update "$ROOT"` — `update`/`_rebuild_code` HONORS `GRAPHIFY_OUT` (absolute)
  AND takes the explicit `"$ROOT"` scan-root arg; both pin the write. On a push
  whose range DELETED a file, `GRAPHIFY_FORCE=1` is added on THIS branch ONLY
  (it bypasses the node-shrink safety check after a delete; `update` reads it,
  `extract` does not).
- **Semantic branch** (`extract`): `GRAPHIFY_CLAUDE_CLI_PARALLEL=0 graphify
  extract "$ROOT" --backend claude-cli` — `extract`'s out-dir derives from the
  `"$ROOT"` target arg (it appends literal `graphify-out`). `GRAPHIFY_OUT` is
  INERT on `extract`, so it is NOT set on this line, and it does NOT pin
  `extract`'s output — the explicit `"$ROOT"` target arg and CWD = `$ROOT` do.
  NEVER `--backend claude` (paid API). NEVER `--no-viz` (`extract` has no such
  flag — unknown-option error). NEVER `GRAPHIFY_FORCE` on `extract`.

**Concurrency.** The skip-lock is a `mkdir`-atomic DIRECTORY at
`$ROOT/graphify-out/.pack-refresh.lock` (macOS has no `flock(1)`). A second
push while a refresh is in flight SKIPS (non-blocking); the background subshell
releases the lock via an `EXIT` trap (so the lock auto-clears even if the
refresh is killed).

**Result-check / re-run.** Each refresh writes an ADVISORY result record
atomically (tmp + `mv`) to `$ROOT/graphify-out/.pack-refresh-status`
(`ok <HEAD-SHA> <ISO-8601>` or `fail …`). On the NEXT push the hook consults a
DUAL signal and surfaces a stale state on stderr: (a) a recorded `fail` token
from a completed-but-failed prior refresh, AND (b) `built_at_commit`-behind-HEAD
— which catches a refresh KILLED mid-run (no token written) that a token-only
check would miss. Both are LOCAL reads of the gitignored graph's own state; the
refresh re-runs regardless. The result record and the lock live INSIDE the
gitignored `graphify-out/`, so they are never committed (CI Check 63).

**Local freshness check.** `pack-startup` reports the graph's freshness on every
startup — a bounded `tail -c` read of `graphify-out/graph.json`'s
`built_at_commit` (the last JSON field) vs `git rev-parse HEAD`, plus whether
the pre-push hook is installed
(`graph: fresh` / `graph: STALE — built at <sha>, HEAD <sha>` and `pre-push
hook: installed` / `NOT installed — run scripts/install-graphify-hook.sh`). This
is a LOCAL human-facing surface only — there is no CI freshness gate, no
committed sentinel, and no commit-count tolerance. If `pack-startup` reports
STALE or NOT installed, run `bash scripts/install-graphify-hook.sh` (if needed)
then `git push` (the hook refreshes), or do a deliberate manual refresh.

### §1.1 backend caveat (do NOT "correct" it)

Pin `--backend claude-cli` on every `extract`. The top-level `--help` enum
OMITS `claude-cli`, but it is valid (verified via the invalid-backend error)
and is the no-key subscription path — do NOT substitute `claude`, which
demands `ANTHROPIC_API_KEY`. NEVER pass `--no-viz` to `extract`: `--no-viz` is
a flag of the initial interactive `/graphify .` build ONLY (it skips the HTML
render), and `extract` emits no HTML, so passing it there is an unknown-option
error.

**How to use the pack's pieces with it.** Agents and Pack Chat consume the
graph by querying it (read-only, ~0 tokens) per the graph-first rule in the
pack-root trinity (`### Repo conventions`). The rule + rationale live pack-side
(`maintenance-docs/v11-implementation/DESIGN-BD-225-GRAPHIFY-PACK-INTEGRATION.md`
is the design of record); the graph itself may index the WHOLE repo (including
`project-template/`) for context — consuming it to answer a deliverable
question is fine, because the RULE and the SETUP stay pack-side and nothing
ships to clients.

**Caveats.**
- **Pack-dev only; boundary-bound.** This is a pack-development accelerator,
  not a client deliverable. No `project-template/` file is touched; the
  graph-first rule lives ONLY in the pack-root trinity; nothing ships to
  clients.
- **Per-clone graph + one-time hook install.** The graph and the initial build
  are gitignored and do not sync across clones. The refresh hook BODY is tracked
  (`scripts/hooks/graphify-pre-push.sh`); only the installed
  `.git/hooks/pre-push` copy is per-clone — run `bash
  scripts/install-graphify-hook.sh` once. CI Check 63 enforces that
  `graphify-out/` is never tracked.
- **Subscription-only; no API keys.** Use `--backend claude-cli`; keep
  `GEMINI_API_KEY` / `GOOGLE_API_KEY` / `OPENAI_API_KEY` unset.
- **Best-effort accelerator.** If a query errors or returns nothing useful,
  fall back to file reads — never block on the graph.

**When to skip Graphify.**
- You are doing a one-off task and do not want to run the one-time build.
- The work is purely a VERIFICATION read at a surface you have already
  identified — exact bytes/counts, an authoritative SSOT-field VALUE (a BD
  `Status`, the README version table, a `_rules.md` contract), a
  freshly-changed/uncommitted file, whole-file content of a named file, or
  content the graph does not index — which falls through to grep / Read /
  `git diff`. (This is precision AFTER discovery, not a reason to skip
  graph-first DISCOVERY when the graph exists — see the graph-first rule's
  two-phase model.)
- You are on a fresh clone with no graph built — the graph-first rule degrades
  to ordinary grep/Read with zero friction.
