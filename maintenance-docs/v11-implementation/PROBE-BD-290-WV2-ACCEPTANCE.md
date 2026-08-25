# BD-290 W-V2 Acceptance Probe — IMPL-REPORT

Probe: RO agent under `isolation_mode: full`, spawned `isolation:"worktree"`.
Date: 2026-08-25. Injected canonical checkout:
`/Users/david/Developer/optiquity-ai-agent-config-pack`; injected canonical
HEAD: `e8aa585`.

## §1 Verdict (per amended-AC clause)

| AC clause | Verdict | One-line basis |
|---|---|---|
| S3 — Regime verification | **PASS** | pwd + toplevel = own agent worktree under canonical prefix; own HEAD `e8aa585…` == injected canonical HEAD; `git worktree list` shows canonical checkout at the same SHA `e8aa585 [main]` (baseRef:"head" proven). |
| S4 — Committed-state git in own worktree only | **PASS** | `git log -1`, `git grep -c`, `git diff --stat HEAD~1 HEAD` all exit 0 in own tree with results consistent with canonical HEAD state. |
| S6 — Canonical file read by absolute path | **PASS** | Read tool fetched `pack-ops/OPERATING-MODES.md` lines 34–45 from the canonical checkout by absolute path; the `full` row carries the repaired contract (quoted in §2). |
| S8 — Report to handoff dir | **PASS** | This file written to the owned dir after the PREFLIGHT line; no writes anywhere else. |

S9 is orchestrator-measured (delivery channel of this result); not measured here.

Guard/hook denials: **none observed** (expected: none). No step required a retry.

## §2 Per-step verbatim evidence

All bash calls executed with cwd = the agent worktree (the harness resets cwd
to the working directory, which IS the worktree):
`/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a79392161091b6957`

### S3 — Regime verification

Command: `pwd; echo "exit=$?"`

```
/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a79392161091b6957
exit=0
```

Expectation: agent worktree under the canonical prefix — MET.

Command: `git rev-parse --show-toplevel; echo "exit=$?"`

```
/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a79392161091b6957
exit=0
```

Expectation: toplevel is the own worktree, not the canonical checkout — MET.

Command: `git rev-parse HEAD; echo "exit=$?"`

```
e8aa58570abd01663db6fae2e6eb6bbc570f9ff6
exit=0
```

Expectation: own worktree HEAD == injected canonical HEAD `e8aa585` — MET
(`e8aa58570abd0…` abbreviates to `e8aa585`). This is the
`worktree.baseRef:"head"` proof: the worktree based at local HEAD, not
origin/main.

Command: `git worktree list; echo "exit=$?"` (sanctioned own-tree side-channel)

```
/Users/david/Developer/optiquity-ai-agent-config-pack                                            e8aa585 [main]
/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a79392161091b6957  e8aa585 [worktree-agent-a79392161091b6957] locked
exit=0
```

Expectation: lists the canonical checkout at the same SHA — MET (both trees at
`e8aa585`).

### S4 — Committed-state git in OWN worktree only

Command: `git log -1 --oneline; echo "exit=$?"`

```
e8aa585 docs: v11 — BD-291 open (v11.0, per-entry field-fidelity, launch-gating) + session-state (pack-only)
exit=0
```

Command: `git grep -c "only in its own worktree" -- pack-ops/OPERATING-MODES.md; echo "exit=$?"`

```
pack-ops/OPERATING-MODES.md:1
exit=0
```

Expectation: the repaired-contract phrase is present in the committed state
visible from the own worktree — MET (1 occurrence).

Command: `git diff --stat HEAD~1 HEAD | tail -1; echo "exit=$?"`

```
 3 files changed, 19 insertions(+), 6 deletions(-)
exit=0
```

All three S4 commands ran in the own worktree (cwd above); no `git -C`, no
`--git-dir`/`--work-tree` redirection, no git aimed at the canonical checkout
or anything under its `.claude/worktrees/` (other than my own cwd-native tree).

### S6 — Canonical file read by absolute path (Read tool)

Read tool, `file_path =
/Users/david/Developer/optiquity-ai-agent-config-pack/pack-ops/OPERATING-MODES.md`,
offset 34, limit 12 (lines 34–45). Returned content verbatim:

```
34	### Isolation mode — `isolation_mode` (default `read-write-only`, Claude-only)
35	
36	Governs which agent classes spawn into an isolated worktree. Worktree
37	isolation is a Claude-only capability, so this family is Claude-only.
38	
39	| Value | Behavior |
40	|---|---|
41	| `read-write-only` (default) | Only read-write agents (coders, fix-coders) spawn into an isolated worktree; read-only agents (reviewers, architects, planners, docs-researchers) spawn in the tree the work lives in. This is current behavior. |
42	| `full` | All agents — read-only included — spawn `isolation:"worktree"`. An isolated agent runs git only in its own worktree or the orchestrator-injected commit workspace; the platform refuses git aimed at the main checkout or any tree under its path. Canonical facts (HEAD, dirty summary) arrive orchestrator-injected; target-tree files are read by absolute path. Clean-channel opt-in: isolated spawns return on the async completion channel. |
44	
45	How `full` executes: the orchestrator injects the canonical facts — HEAD SHA,
```

(Line 43 is a blank line consumed by the table rendering in the Read window;
the `full` row is line 42.) The `full` row's text, quoted verbatim:

> `full` | All agents — read-only included — spawn `isolation:"worktree"`. An
> isolated agent runs git only in its own worktree or the
> orchestrator-injected commit workspace; the platform refuses git aimed at
> the main checkout or any tree under its path. Canonical facts (HEAD, dirty
> summary) arrive orchestrator-injected; target-tree files are read by
> absolute path. Clean-channel opt-in: isolated spawns return on the async
> completion channel.

This carries the repaired contract (own-worktree-only git; injected canonical
facts; absolute-path reads; refusal of git aimed at the main checkout) — MET.

### S8 — Report write

`mkdir -p /Users/david/.local/state/optiquity-pack-handoff/bd290-wv2-20260825T203216Z`
→ `exit=0`. PREFLIGHT line emitted (`PREFLIGHT: S3/S4/S6 complete; about to
Write IMPL-REPORT to <owned dir>/IMPL-REPORT.md`), then this file written via
a single Write to the owned dir. No other file writes anywhere.

## §3 Guard/hook events

None observed. No permission prompts, no hook denials, no platform refusals
at any step. (Expected: none — and none would have been worked around; a
denial would have been recorded as a FAIL finding.)

## §4 Anomalies

1. **Stale git-status snapshot in spawn environment (informational, no AC
   impact).** The harness-provided startup git-status snapshot showed
   `Current branch: main` and a recent-commit head of `7d43b01`, while the
   live runtime measurements show the worktree branch
   `worktree-agent-a79392161091b6957` at `e8aa585`. The snapshot is
   explicitly documented as a point-in-time capture and the runtime regime
   verification (S3) is the ground truth per rule 8, so this is expected
   behavior, not a defect. Context: probes MUST verify pwd/HEAD at runtime
   precisely because injected/ambient snapshots can lag. Options: (a) treat
   as expected and rely on runtime verification (status quo), (b) ask the
   platform to refresh the snapshot at worktree materialization.
   Recommendation (logic-based): (a) — the existing runtime-verification
   rule already neutralizes it, and (b) is a platform-side change outside
   pack control. No AC clause is affected.

No other anomalies. No open questions, gaps, expansions, or decisions
surfaced beyond the informational item above.

## §5 Rules-Applied Verification Block

1. **agents-never-commit** — Evidence: the complete git verb set executed
   this session, quoted from §2: `git rev-parse --show-toplevel`,
   `git rev-parse HEAD`, `git worktree list` (list subcommand only — no
   add/remove/move/prune), `git log -1 --oneline`,
   `git grep -c … -- pack-ops/OPERATING-MODES.md`,
   `git diff --stat HEAD~1 HEAD`. Every verb is read-only; zero
   state-changing verbs (no add/commit/push/stash/reset/checkout/worktree
   add/etc.); all executed with cwd =
   `…/.claude/worktrees/agent-a79392161091b6957` (own worktree), none aimed
   at the canonical checkout. Conclusion: **COMPLIANT**.
2. **per-action-approval-sub-agents** — Evidence: writes this session:
   `mkdir -p …/bd290-wv2-20260825T203216Z` (exit=0) and one Write of
   `…/bd290-wv2-20260825T203216Z/IMPL-REPORT.md` — both inside the owned dir
   `/Users/david/.local/state/optiquity-pack-handoff/bd290-wv2-20260825T203216Z`.
   Zero deletions, zero destructive ops, zero writes outside the owned dir
   or $TMPDIR. Conclusion: **COMPLIANT**.
3. **preflight-stop-means-stop** — Evidence: the line
   `PREFLIGHT: S3/S4/S6 complete; about to Write IMPL-REPORT to /Users/david/.local/state/optiquity-pack-handoff/bd290-wv2-20260825T203216Z/IMPL-REPORT.md`
   was emitted as a plain assistant line immediately before this Write; no
   parent stop/halt message was received at any point (none to honor).
   Conclusion: **COMPLIANT**.
4. **rules-applied-verification-block** — Evidence: this §5 block itself —
   five entries, each with rule name, quoted measurement, and a terminal
   conclusion; no AMBIGUOUS state used. Conclusion: **COMPLIANT**.
5. **open-item-surfacing** — Evidence: §4 surfaces the single item hit
   (stale spawn-time git snapshot) with context, two options, and a
   logic-based recommendation; no item was deferred to another/new BD and no
   recommendation relies on memory (all evidence quoted from this session's
   command output). Conclusion: **COMPLIANT**.

---

## Orchestrator addendum — S9 channel record (plan W4-1 step 4)

Recorded by the orchestrator at delivery, 2026-08-25, CLI 2.1.245: the probe's
result arrived as a clean async completion notification (task-notification) —
no mailbox routing, no peer-message boilerplate. S9 PASS. With S3/S4/S6/S8
PASS in the probe's own report above, the amended BD-290 acceptance criterion
("no failure, async-task channel preserved") is met in full. This record
doubles as the post-upgrade re-check recipe: repeat the S3–S8 probe under
`isolation_mode: full` after any CLI upgrade and confirm the delivery is a
completion notification, not a mailbox message.
