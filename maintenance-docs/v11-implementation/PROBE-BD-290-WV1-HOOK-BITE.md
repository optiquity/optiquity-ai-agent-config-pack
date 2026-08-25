# PROBE-BD-290-WV1 — hook deny-path bite + payload-field proof (orchestrator-run)

Evidence record for the BD-290 W-V1 verification, executed by the orchestrator
(Pack Chat) in the canonical checkout on 2026-08-25, CLI 2.1.245, with
`isolation_mode: full` written for the measurement window and restored to
`read-write-only` afterwards. This record is authored by the orchestrator from
the captured live results (the three legs ran as orchestrator actions, not as a
reporting agent), preserved per the BD-290 plan §5 W4-4 artifact set.

## Leg 1 — deny-path (BITE proven)

Spawn attempted: Agent tool, `subagent_type: pack-docs-researcher` (RO class),
`name: probe-bd290-wv1-noiso`, NO `isolation` parameter, under
`isolation_mode: full`.

Result (verbatim tool error, the hook's own deny message):

> RO spawn under isolation_mode=full must set isolation:"worktree"; re-spawn
> with the isolation parameter

Interpretation: `scripts/hooks/modes-enforce.py` receives the live
PreToolUse[Agent] payload, classifies the RO type, detects the absent
parameter, and denies pre-execution. The deny-path bites on real spawns, not
only on synthetic test payloads.

## Leg 2 — allow-path (payload field proven; resolves census unknown U1)

Spawn attempted: identical to Leg 1 plus `isolation: "worktree"`.

Result: spawn ALLOWED; the agent ran and reported
`pwd = <canonical>/.claude/worktrees/agent-<id>` (a real isolated worktree)
and its result was delivered as an async completion notification.

Interpretation: `tool_input.isolation` is present in the live hook payload and
matched by the hook (an absent field would have denied as in Leg 1). Census
unknown U1 is resolved behaviorally.

## Leg 3 — pinned-def leg (pin NOT honored; measured, narrow scope)

A temporary untracked scratch agent definition
(`.claude/agents/pack-wv1-pinned.md`, created and removed by the orchestrator
with per-action user approval) carried `isolation: worktree` in frontmatter.
Spawned via `subagent_type: pack-wv1-pinned` WITHOUT the per-spawn parameter.

Result (agent's own verbatim report): `pwd` and `git rev-parse
--show-toplevel` both resolved to the canonical checkout (in-place, no
worktree); delivery arrived on the mailbox/teammate channel.

Interpretation, scoped narrowly: on the Agent-tool `subagent_type` spawn path
at CLI 2.1.245, a frontmatter isolation pin is NOT honored — only the
per-spawn `isolation:"worktree"` parameter isolates. Other invocation paths
(direct `claude --agent` sessions, `--agents` JSON) were not measured. This
measurement is the basis for the no-pin wording landed in W1 (the operating
surfaces carry only this measured claim).

## Channel side-observation

Leg 2 (isolated) delivered via async completion notification; Leg 3
(non-isolated) delivered via the mailbox/teammate channel — consistent with
the stage-1 A/B measurement and with the W-V2 channel record
(`PROBE-BD-290-WV2-ACCEPTANCE.md`).
