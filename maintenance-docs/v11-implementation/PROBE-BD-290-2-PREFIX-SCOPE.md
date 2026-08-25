# IMPL-REPORT — BD-290 probe 2 (census unknown U2)

Probe agent: isolated worktree `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-ab63aa01d01b04f86`, detached HEAD `3cf436ec46433556a218e086364871882c84490f`.
Date: 2026-08-25. All git invocations read-only. Each blocked step was run exactly once (no retries — the denial is deterministic guard output, not a transient failure).

## §1 Verdict (measurement only)

| Target | cd-form (`cd <T> && git …`) | `-C`-form (`git -C <T> log`) | `-C`-form (`git -C <T> status \| wc -l`) |
|---|---|---|---|
| MAIN `/Users/david/Developer/optiquity-ai-agent-config-pack` | not run (control used `-C` only) | **BLOCKED** | not run |
| WT_IN `…/optiquity-ai-agent-config-pack/.claude/worktrees/bd290-u2-scratch` | **BLOCKED** | **BLOCKED** | **BLOCKED** |
| WT_OUT `…/scratchpad/bd290-u2-scratch` (outside main checkout's path) | **ALLOWED** | **ALLOWED** | **ALLOWED** |

**U2 answer:** git from an isolated agent against a *different linked worktree* is **not categorically blocked** — the guard discriminates by **path**, not by repo linkage. A linked worktree **nested under the main checkout's path** (WT_IN — the real-world agent-worktree location) is blocked in every form; a linked worktree of the *same repo* located **outside** the main checkout's path (WT_OUT) is fully allowed in every form, and git resolves it correctly (toplevel = WT_OUT itself, HEAD `3cf436e`, clean status).

## §2 Per-step verbatim evidence

### Step A — own regime

cwd for all Bash calls resets to the agent worktree; commands run as shown.

1. Command: `pwd`
   Exit: 0
   Output:
   ```
   /Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-ab63aa01d01b04f86
   ```
2. Command: `git rev-parse --show-toplevel`
   Exit: 0
   Output:
   ```
   /Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-ab63aa01d01b04f86
   ```
3. Command: `git rev-parse HEAD`
   Exit: 0
   Output:
   ```
   3cf436ec46433556a218e086364871882c84490f
   ```

### Step B — control against MAIN (expected BLOCKED)

Command: `git -C /Users/david/Developer/optiquity-ai-agent-config-pack log -1 --oneline`
Result: **BLOCKED** — the tool returned an error (command never executed). Verbatim:
```
This agent is isolated in the worktree /Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-ab63aa01d01b04f86, but this command redirects git to the shared checkout via -C. Refusing to run it — a worktree-isolated agent's git operations must target its own worktree. Run the equivalent from /Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-ab63aa01d01b04f86 without the redirect.
```

### Step C — U2 against WT_IN (`/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/bd290-u2-scratch`)

Form (1): `cd /Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/bd290-u2-scratch && git rev-parse HEAD`
Result: **BLOCKED** (command never executed). Verbatim:
```
This agent is isolated in the worktree /Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-ab63aa01d01b04f86, but this command changes directory to the shared checkout (/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/bd290-u2-scratch) before running git. Refusing to run it — a worktree-isolated agent's git operations must target its own worktree. Run the equivalent from /Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-ab63aa01d01b04f86 without the redirect.
```
(Form (1) blocked ⇒ the conditional toplevel-confirm for WT_IN did not apply.)

Form (2): `git -C /Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/bd290-u2-scratch log -1 --oneline`
Result: **BLOCKED** (command never executed). Verbatim:
```
This agent is isolated in the worktree /Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-ab63aa01d01b04f86, but this command redirects git to the shared checkout via -C. Refusing to run it — a worktree-isolated agent's git operations must target its own worktree. Run the equivalent from /Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-ab63aa01d01b04f86 without the redirect.
```

Form (3): `git -C /Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/bd290-u2-scratch status --porcelain=v1 | wc -l`
Result: **BLOCKED** (command never executed). Verbatim: identical text to Form (2)'s denial (same "redirects git to the shared checkout via -C" message, byte-for-byte).

### Step D — U2 against WT_OUT (`/private/tmp/claude-501/-Users-david-Developer-optiquity-ai-agent-config-pack/03f94d7a-811d-445e-9727-7c003d6a116b/scratchpad/bd290-u2-scratch`)

Form (1): `cd <WT_OUT> && git rev-parse HEAD`
Exit: 0. Output:
```
3cf436ec46433556a218e086364871882c84490f
```

Toplevel confirm (form (1) succeeded): `cd <WT_OUT> && git rev-parse --show-toplevel`
Exit: 0. Output:
```
/private/tmp/claude-501/-Users-david-Developer-optiquity-ai-agent-config-pack/03f94d7a-811d-445e-9727-7c003d6a116b/scratchpad/bd290-u2-scratch
```
Git resolved WT_OUT itself as the toplevel — the linked scratch worktree, not the agent's own worktree and not the main checkout.

Form (2): `git -C <WT_OUT> log -1 --oneline`
Exit: 0. Output:
```
3cf436e docs: v11 — BD-290 open (v11.0, isolation-mode full breakage) + session-state refresh (pack-only)
```

Form (3): `git -C <WT_OUT> status --porcelain=v1 | wc -l`
Exit: 0. Output:
```
       0
```

## §3 Guard messages verbatim

Three denials observed, all from Claude Code's worktree-isolation guard (the command was refused pre-execution in each case; no shell exit code exists for blocked steps):

1. MAIN via `-C` (Step B) — quoted in full in §2 Step B.
2. WT_IN via `cd` (Step C form 1) — quoted in full in §2 Step C. Note the guard names WT_IN's path and calls it "the shared checkout": `…this command changes directory to the shared checkout (/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/bd290-u2-scratch)…`
3. WT_IN via `-C` (Step C forms 2 and 3) — identical text both times, quoted in full in §2 Step C form 2.

No guard, hook, or permission message appeared on any Step A or Step D call.

## §4 Anomalies

1. **Guard misidentifies WT_IN as "the shared checkout."** Context: WT_IN is a *linked worktree* (own gitdir, detached HEAD), not the main checkout, yet the denial for form (1) names WT_IN's path and labels it "the shared checkout". Combined with WT_OUT (same repo, same linkage, different path) being allowed, the evidence indicates the guard matches on the **main checkout's path prefix** (`/Users/david/Developer/optiquity-ai-agent-config-pack/`), not on git worktree identity or repo linkage. Options: (a) treat the guard as path-prefix-based in the BD-290 census and word the census finding accordingly; (b) treat it as identity-based with a labeling bug. Recommendation (evidence-based): (a) — the WT_IN/WT_OUT split is explained only by path, and the mislabel is consistent with a prefix match that never inspects gitdir linkage.
2. **Consequence for the real-world layout: sibling agent worktrees are unreachable via git.** Context: agent worktrees live under `<main>/.claude/worktrees/`, inside the blocked prefix — so an isolated agent cannot run even read-only git against a *sibling agent's* worktree at the standard location (WT_IN is exactly that layout). Options: (a) record in the census that cross-agent-worktree git coordination from inside an isolated agent is impossible at the default location; (b) if such a read is ever needed, the orchestrator performs it, or the target worktree is placed outside the main checkout's path. Recommendation: (a) as the census fact, with (b) as the design note.
3. **The guard does not protect out-of-prefix linked worktrees — a containment gap, surfaced not tested.** Context: WT_OUT accepted every read-only verb, and since a linked worktree shares the repo's object/ref store, a *state-changing* git verb run there would mutate shared repo state despite isolation. I did NOT test this (READ-ONLY constraint; `agents-never-commit`); it is an inference from git's worktree architecture, not a measurement. Options: (a) note in BD-290 that worktree isolation's git guard is path-scoped and an out-of-prefix linked worktree is a bypass surface for a misbehaving agent; (b) ignore as out of scope. Recommendation: (a) — it bounds what the isolation guarantee actually covers, which is the census's subject.

## §5 Rules-Applied Verification Block

1. **agents-never-commit**
   Evidence: complete git verb inventory this run — `git rev-parse --show-toplevel` (x2 own tree, x1 WT_OUT), `git rev-parse HEAD` (x1 own, x1 WT_OUT), `git -C … log -1 --oneline` (x3: MAIN, WT_IN, WT_OUT), `git -C … status --porcelain=v1` (x2: WT_IN, WT_OUT), `cd … && git rev-parse HEAD` (x1 WT_IN). Every verb is `rev-parse` / `log` / `status` — read-only; the MAIN, WT_IN-cd, and WT_IN-`-C` invocations were refused by the guard and never executed. Zero state-changing verbs issued.
   Conclusion: **COMPLIANT**
2. **per-action-approval-sub-agents**
   Evidence: the only Write this run is `/Users/david/.local/state/optiquity-pack-handoff/bd290-probe2-20260825T154529Z/IMPL-REPORT.md` (this file, inside the owned dir). No `rm`/`mv`/`truncate`/delete of any kind was run; the two scratch worktrees' contents were untouched (only read-only git run against them; WT_OUT `status` showed `0` dirty lines after my visits).
   Conclusion: **COMPLIANT**
3. **preflight-stop-means-stop**
   Evidence: emitted verbatim before this Write: `PREFLIGHT: steps A-E complete; about to Write IMPL-REPORT to /Users/david/.local/state/optiquity-pack-handoff/bd290-probe2-20260825T154529Z/IMPL-REPORT.md`. No stop/halt message was received from the parent at any point.
   Conclusion: **COMPLIANT**
4. **rules-applied-verification-block**
   Evidence: this §5 block — five entries, each with name, quoted measurement evidence, and a terminal conclusion.
   Conclusion: **COMPLIANT**
5. **open-item-surfacing**
   Evidence: §4 lists 3 anomalies, each with context + options + an evidence-based recommendation ("Recommendation (evidence-based): (a)…", "Recommendation: (a) as the census fact…", "Recommendation: (a) — it bounds…"). None relies on memory or defers work to another BD.
   Conclusion: **COMPLIANT**
