# BD-290 Diagnostic Probe — IMPL-REPORT
Probe: read-only diagnostic, spawned with `isolation:"worktree"`, 2026-08-25.
Spawn cwd: `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-af13ac8e7586d62a4`
Canonical target tree: `/Users/david/Developer/optiquity-ai-agent-config-pack` (expected HEAD 7d43b01)

## §1 Verdict summary (measurement only)

| Capability | Result |
|---|---|
| git (read-only verbs) in own worktree | WORKS (rev-parse, branch, status, worktree list all exit 0) |
| Worktree base == canonical HEAD | CONFIRMED — both trees at `7d43b01` (own `git rev-parse HEAD` + `git worktree list`) |
| `cd <canonical>` alone (non-git command) | WORKS (`cd … && pwd` printed the canonical path) |
| `cd <canonical> && git <read-only verb>` | BLOCKED — all 7 commands refused by a harness worktree-isolation guard, before execution |
| `git -C <canonical> <read-only verb>` | BLOCKED — both commands refused (distinct `-C`-specific denial text) |
| Read tool on a canonical-tree file | WORKS (returned OPERATING-MODES.md lines 34–42) |
| `echo "GIT_DIR=$GIT_DIR …"` (no git invocation) | BLOCKED (guard "too complex" variant) — while `env \| grep -iE 'git\|worktree'` and `printenv GIT_DIR …` ran fine |
| Gitignored `pack-ops/session-config.json`, `graphify-out/` in own worktree | ABSENT (expected — gitignored files are not materialized in the worktree) |

Net: the reported defect reproduces 100% for Bash git. Under `isolation:"worktree"`, EVERY cross-tree git invocation — read-only verbs included, via `cd` or via `-C` — is refused by the harness guard. Non-git access to the canonical tree (plain `cd`, Read tool) is unaffected. The denials are emitted by the harness's worktree-isolation guard, not by the repo's PreToolUse hooks (no hook script is named in any denial).

## §2 Environment capture (Step A, verbatim)

All commands ran with cwd = spawn cwd (no prior `cd`).

```
=== CMD: pwd ===
/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-af13ac8e7586d62a4
EXIT=0
=== CMD: git rev-parse --show-toplevel ===
/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-af13ac8e7586d62a4
EXIT=0
=== CMD: git rev-parse HEAD ===
7d43b01bfac2753ade44291b9ed3be2f32af4029
EXIT=0
=== CMD: git branch --show-current ===
worktree-agent-af13ac8e7586d62a4
EXIT=0
=== CMD: git status --porcelain=v1 | head -5 ===
EXIT=0
=== CMD: git worktree list ===
/Users/david/Developer/optiquity-ai-agent-config-pack                                            7d43b01 [main]
/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-af13ac8e7586d62a4  7d43b01 [worktree-agent-af13ac8e7586d62a4] locked
```

Worktree base check: own HEAD `7d43b01bfac2753ade44291b9ed3be2f32af4029` == canonical expected `7d43b01`. PASS. `git status` output empty (clean tree). `git worktree list` (run in own worktree — allowed) independently shows the canonical checkout at `7d43b01 [main]`.

Env-var probe — three attempts:
1. Compound `echo "GIT_DIR=$GIT_DIR …"; env | grep -iE 'git|worktree' | sort` → BLOCKED (denial verbatim in §4, event E1).
2. Plain `echo "GIT_DIR=$GIT_DIR GIT_WORK_TREE=$GIT_WORK_TREE GIT_INDEX_FILE=$GIT_INDEX_FILE"` → BLOCKED (§4, event E2). Standalone `env | grep -iE 'git|worktree' | sort` → exit 0:
```
GIT_EDITOR=true
OLDPWD=/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-af13ac8e7586d62a4
PATH=<long PATH value — no git/worktree-specific entries beyond plugin bins; elided for length; captured in transcript>
PWD=/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-af13ac8e7586d62a4
```
3. `printenv GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE` → ran (not blocked), exit 1, no output.

Conclusion (measured): `GIT_DIR`, `GIT_WORK_TREE`, `GIT_INDEX_FILE` are all UNSET in the spawn environment. Only `GIT_EDITOR=true` is set. Isolation is achieved purely by cwd placement plus the harness guard, not by git env vars.

Gitignored-file presence in own tree (cwd = spawn cwd):
```
=== CMD: ls -la pack-ops/session-config.json ===
ls: pack-ops/session-config.json: No such file or directory
EXIT=1
=== CMD: ls -la graphify-out/graph.json ===
ls: graphify-out/graph.json: No such file or directory
EXIT=1
=== CMD: ls -d graphify-out ===
ls: graphify-out: No such file or directory
EXIT=1
```
Both absent, as expected for gitignored content in a fresh worktree; the `graphify-out/` directory does not exist at all.

## §3 Per-step evidence (B, C, D)

### Step B — cross-tree git via cd
Each command ran as its own Bash call (`cd` fused with the command; cwd resets between calls).

| # | Command | cwd at invocation | Exit/outcome | Output |
|---|---|---|---|---|
| B1 | `cd /Users/david/Developer/optiquity-ai-agent-config-pack && pwd` | spawn cwd | 0 (ran) | `/Users/david/Developer/optiquity-ai-agent-config-pack` |
| B2 | `… && git rev-parse --show-toplevel` | spawn cwd | BLOCKED pre-exec | denial D-cd (verbatim below) |
| B3 | `… && git rev-parse HEAD` | spawn cwd | BLOCKED pre-exec | denial D-cd |
| B4 | `… && git status --porcelain=v1 \| wc -l` | spawn cwd | BLOCKED pre-exec | denial D-cd |
| B5 | `… && git log -1 --oneline` | spawn cwd | BLOCKED pre-exec | denial D-cd |
| B6 | `… && git diff --stat \| tail -3` | spawn cwd | BLOCKED pre-exec | denial D-cd |
| B7 | `… && git ls-files \| wc -l` | spawn cwd | BLOCKED pre-exec | denial D-cd |
| B8 | `… && git grep -c isolation_mode -- pack-ops/OPERATING-MODES.md` | spawn cwd | BLOCKED pre-exec | denial D-cd |

Denial D-cd, byte-identical for B2–B8, verbatim:
```
This agent is isolated in the worktree /Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-af13ac8e7586d62a4, but this command changes directory to the shared checkout (/Users/david/Developer/optiquity-ai-agent-config-pack) before running git. Refusing to run it — a worktree-isolated agent's git operations must target its own worktree. Run the equivalent from /Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-af13ac8e7586d62a4 without the redirect.
```
No retries performed on B2–B8 (deterministic guard; the block IS the measurement).

### Step C — cross-tree git via -C (cwd = spawn cwd, auto-reset)

| # | Command | Outcome |
|---|---|---|
| C1 | `git -C /Users/david/Developer/optiquity-ai-agent-config-pack log -1 --oneline` | BLOCKED pre-exec |
| C2 | `git -C /Users/david/Developer/optiquity-ai-agent-config-pack status --porcelain=v1 \| wc -l` | BLOCKED pre-exec |

Denial D-C, byte-identical for C1–C2, verbatim:
```
This agent is isolated in the worktree /Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-af13ac8e7586d62a4, but this command redirects git to the shared checkout via -C. Refusing to run it — a worktree-isolated agent's git operations must target its own worktree. Run the equivalent from /Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-af13ac8e7586d62a4 without the redirect.
```

### Step D — Read tool cross-tree
Read `/Users/david/Developer/optiquity-ai-agent-config-pack/pack-ops/OPERATING-MODES.md` offset 34, limit 9 → SUCCESS. Returned lines 34–42, including the isolation-mode table; line 42 verbatim:
```
| `full` | All agents (read-only included) spawn into an isolated worktree, then `cd` to the target tree. |
```
The Read tool reaches the canonical tree without restriction.

## §4 Hook/permission events (verbatim)

11 blocked Bash calls total, three distinct denial texts, all sharing the "worktree-isolated agent" wording. NONE names any repo PreToolUse hook (modes-enforce.py / modes-commit-gate.py / deletion-boundary.py); the wording and pre-execution timing indicate the harness/session worktree-isolation guard on the Bash tool. No other permission prompts, hook messages, or blocked non-Bash tool calls were observed in any step.

E1 — Step A compound env probe (`echo "GIT_DIR=$GIT_DIR …"; env | grep -iE 'git|worktree' | sort`), verbatim:
```
This agent is isolated in the worktree /Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-af13ac8e7586d62a4, but this command is too complex to verify that it stays inside the worktree. Refusing to run it — a worktree-isolated agent's git operations must target its own worktree. Split it into plain, separate commands and run them from /Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-af13ac8e7586d62a4.
```
E2 — Step A retry, plain `echo "GIT_DIR=$GIT_DIR GIT_WORK_TREE=$GIT_WORK_TREE GIT_INDEX_FILE=$GIT_INDEX_FILE"`: byte-identical to E1.
E3–E9 — Step B commands B2–B8: denial D-cd (§3, verbatim above), 7 occurrences.
E10–E11 — Step C commands C1–C2: denial D-C (§3, verbatim above), 2 occurrences.

Not blocked (contrast set): all own-worktree git read verbs; `cd <canonical> && pwd`; `env | grep -iE 'git|worktree' | sort`; `printenv GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE`; the cross-tree Read tool call; `ls` of paths in own tree.

## §5 Anomalies / unknowns

1. **Guard blocks read-only cross-tree git wholesale — the reported defect, reproduced.**
   Context: OPERATING-MODES.md line 42 defines `full` mode as "spawn into an isolated worktree, then `cd` to the target tree" — but the harness guard refuses every `cd <target> && git …` and every `git -C <target> …`, read-only or not, making the full-mode RO contract unexecutable for git verbs. Options I see: (a) full-mode RO agents run git only in their OWN worktree — with `worktree.baseRef:"head"` the base equals canonical HEAD (measured: both at 7d43b01), so all COMMITTED-state git queries are equivalent; canonical-tree dirty/uncommitted state is reachable via Read/ls but not via git; (b) the orchestrator pre-computes and injects any needed canonical-tree git facts (HEAD, status count) into the spawn prompt, as already done for the graph path; (c) rewrite the OPERATING-MODES `full`-mode contract to document the git-verb limitation. Recommendation (evidence-based): (a)+(b) combined — own-worktree git covers committed state exactly (measured equivalence), and prompt injection covers the dirty-state gap the guard closes; (c) is the doc-side companion. Choice among them is BD-290 design work, out of probe scope.
2. **Guard false-positive on a git-free command.** `echo "GIT_DIR=$GIT_DIR …"` (no git invocation, no cd) was blocked twice with the "too complex" denial, while `env | grep -iE 'git|worktree'` and `printenv GIT_DIR …` passed. Interpretation (marked as such, not measurement): the matcher appears to trigger on `GIT_DIR=`-shaped tokens (a `GIT_DIR=` assignment CAN redirect git, so the pattern is defensible) rather than on the word "git". Unknown: exact matcher rules — not probeable further within read-only constraints. No recommendation beyond noting it for BD-290's guard-behavior inventory.
3. **`git worktree list` is an allowed side-channel.** It runs in the own worktree yet reports the canonical checkout's HEAD and branch (`7d43b01 [main]`) — the only git-sourced cross-tree fact obtainable under the guard. Context: useful as a sanctioned base-equality check; recommendation: treat as legitimate (read-only, own-tree invocation).
4. **Gitignored operating files are absent in the worktree** (`pack-ops/session-config.json`, `graphify-out/`): expected per CLAUDE.md, but under `full` isolation an RO agent told to read `isolation_mode` from "the current worktree" cannot — the config must come from the orchestrator's canonical checkout (which the existing rule already assigns to Pack Chat at spawn time). Absent-by-design; flagged because it compounds anomaly 1 for any spawned agent asked to self-orient. No further recommendation.
5. **Unknown:** whether the guard also blocks cross-tree git toward a SECOND, unrelated repo (not the shared checkout). Not tested — out of the probe's scoped steps and would touch trees outside the task. No recommendation possible from evidence gathered.

## §6 Rules-Applied Verification Block

1. **agents-never-commit** — Evidence: every git command issued, exhaustive: `git rev-parse --show-toplevel`, `git rev-parse HEAD`, `git branch --show-current`, `git status --porcelain=v1`, `git worktree list` (list subcommand only — no add/remove/move/prune), `git log -1 --oneline` (blocked), `git diff --stat` (blocked), `git ls-files` (blocked), `git grep` (blocked), `git -C … log/status` (blocked). All read-only verbs; zero state-changing verbs attempted in any tree. Conclusion: COMPLIANT.
2. **per-action-approval-sub-agents** — Evidence: sole filesystem write this session is this file: `/Users/david/.local/state/optiquity-pack-handoff/bd290-probe-20260825T125529Z/IMPL-REPORT.md` (inside the owned dir). No `rm`/`mv`/deletion/overwrite anywhere; no writes outside the owned dir; $TMPDIR untouched. Conclusion: COMPLIANT.
3. **preflight-stop-means-stop** — Evidence: emitted verbatim before this Write: `PREFLIGHT: steps A-E complete; about to Write IMPL-REPORT to /Users/david/.local/state/optiquity-pack-handoff/bd290-probe-20260825T125529Z/IMPL-REPORT.md`. No stop/halt message was received from the parent at any point (none present in the transcript). Conclusion: COMPLIANT.
4. **rules-applied-verification-block** — Evidence: this block, with per-rule quoted measurements (command lists, file path, PREFLIGHT line) rather than bare assertions. Conclusion: COMPLIANT.
5. **open-item-surfacing** — Evidence: §5 items 1–5 each carry context + options + an evidence-based recommendation, or an explicit no-recommendation ("No recommendation possible from evidence gathered" — item 5; "No recommendation beyond noting it" — item 2). Conclusion: COMPLIANT.
