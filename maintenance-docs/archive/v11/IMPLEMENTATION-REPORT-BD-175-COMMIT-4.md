# IMPLEMENTATION REPORT — BD-175 Commit 4 (TASK-T1 trinity REPLACE+REVERT)

**Branch:** v11-dev
**Worktree HEAD at start:** `21c134443aab09d00895b410e6587ce8d37f615d`
**Coder:** pack-coder (parallel batch, set ALPHA-EXPANDED, Commit 4 of 7)
**Plan §:** §2.4 (Commit 4 detail) + §8.2.1 (parallel orchestration)
**Architect §:** §2 V1 + §2 T5-A + §2 V8 + §6.1 TASK-T1

## §1 Summary

Executed the TASK-T1 trinity REPLACE+REVERT per Architect A §2 V1 (TYPE-2
pack-bias contamination), §2 T5-A (HIGH heuristic — inline-enumeration
anti-pattern, coupled to V1), and §2 V8 (TYPE-4 TOOL-COMPARISON pointer).

Trinity rule applied strictly: 3 CLI files (`project-template/CLAUDE.md` +
`AGENTS.md` + `GEMINI.md`) edited in lockstep, 2 hunks each = 6 total
edits. The V1+T5-A REPLACE collapses the inline agent enumeration plus
the `PACK-AGENTS.md` reference into a single project-side SSOT pointer
to `docs/pack/PM-CHAT.md` § Pack agent roster (verified to resolve at
`project-template/docs/pack/PM-CHAT.md:47`). The V8 REVERT deletes the
italicized `TOOL-COMPARISON.md` paragraph below the routing table — no
replacement (per A §2 V8: "Drop the pointer entirely … the routing-table
itself is the project-side SSOT").

Manifest regeneration intentionally NOT executed — Pack Chat handles
serially per-commit during the commit loop with git-stash isolation
(plan §8.7), per parallel-batch constraint.

## §2 Per-file edits

### §2.1 — `project-template/CLAUDE.md`

**Hunk 1: V1 + T5-A REPLACE (was L362-368; now L362-368)**

BEFORE:
```
- **PM chat does not architect.** Architecture, planning,
  implementation, and review work goes to the corresponding agent
  (architect / planner / coder / reviewer / tester / auditor /
  docs-researcher / grpc-schema / repo-ops) — `auditor` covers the
  7 variant agents; see `PACK-AGENTS.md` for the full roster. The
  PM chat handles BACKLOG, STATUS, CHANGELOG, routing, approvals,
  and prompt construction — not the work the agents do.
```

AFTER:
```
- **PM chat does not architect.** Architecture, planning,
  implementation, and review work goes to the corresponding agent.
  The full pack agent roster is at `docs/pack/PM-CHAT.md` §
  Pack agent roster — that section is the project-side SSOT; do
  not infer the roster from any other source. The PM chat handles
  BACKLOG, STATUS, CHANGELOG, routing, approvals, and prompt
  construction — not the work the agents do.
```

**Hunk 2: V8 REVERT (was L395-397; now deleted — file shrinks by 4 lines including blank-line trim)**

BEFORE (4 lines, immediately above `### Custom agents`):
```

*This table reflects quality-optimized defaults. For cost-optimized routing
alternatives (e.g., using Gemini CLI Flash for reviewer, tester, and
docs-researcher), see `TOOL-COMPARISON.md` in the pack's `maintenance-docs/`.*

```

AFTER: deleted entirely (no replacement); `### Custom agents` heading now
follows the `agent-run.sh` paragraph after a single blank line.

### §2.2 — `project-template/AGENTS.md`

**Hunk 1: V1 + T5-A REPLACE (was L339-345; now L339-345)** — byte-identical
to CLAUDE.md hunk 1 (verified via `diff -u` — exit=0).

BEFORE / AFTER: same blocks as §2.1 hunk 1.

**Hunk 2: V8 REVERT (was L372-374; now deleted)** — byte-identical
to CLAUDE.md hunk 2 (verified via `diff -u` — exit=0).

BEFORE / AFTER: same blocks as §2.1 hunk 2.

### §2.3 — `project-template/GEMINI.md`

**Hunk 1: V1 + T5-A REPLACE (was L354-358; now L354-360)** — GEMINI's
BEFORE wording was already a collapsed variant (no inline enumeration
preamble; only `(`auditor` covers the 7 variant agents; see
`PACK-AGENTS.md` ...)` parenthetical). A §2 V1 noted "trinity wording
varies slightly across CLI files"; my REPLACE produces the canonical
unified AFTER wording — Gemini's PM-chat-does-not-architect block now
matches CLAUDE/AGENTS byte-for-byte.

BEFORE (Gemini-specific 5-line shape):
```
- **PM chat does not architect.** Architecture, planning, implementation,
  and review work goes to the corresponding agent (`auditor` covers the
  7 variant agents; see `PACK-AGENTS.md` for the full roster). The PM
  chat handles BACKLOG, STATUS, CHANGELOG, routing, approvals, and
  prompt construction — not the work the agents do.
```

AFTER: same canonical 7-line block as §2.1 hunk 1.

**Hunk 2: V8 REVERT (was L385-387; now deleted)** — byte-identical
to CLAUDE.md hunk 2 (verified via `diff -u` — exit=0).

BEFORE / AFTER: same blocks as §2.1 hunk 2.

## §3 Trinity parity confirmation

| Hunk | CLAUDE↔AGENTS diff | CLAUDE↔GEMINI diff |
|---|---|---|
| V1+T5-A REPLACE | exit=0 (byte-identical) | exit=1 (only pre-existing `git reset --hard` wording variation 2 lines ABOVE the edited block — OUTSIDE my scope; PM-chat block itself is byte-identical) |
| V8 REVERT (post-routing-table → `### Custom agents`) | exit=0 (byte-identical) | exit=0 (byte-identical) |

Pre-existing trinity wording variation in GEMINI's "No destructive
operations" bullet (lines L351-353 vs L335-338 / L358-361 in
AGENTS/CLAUDE) is documented in A §2 V1 ("trinity wording varies
slightly across CLI files") and is OUTSIDE my edit scope — not a
regression. The PM-chat-does-not-architect block IS now in lockstep
across all 3 trinity files.

## §4 Verification results

All 4 plan-prescribed grep checks (PLAN §2.4.4) PASS:

| # | Check | Expected | Actual | Result |
|---|---|---|---|---|
| 1 | `grep -n "PACK-AGENTS\|TOOL-COMPARISON\|maintenance-docs" project-template/{CLAUDE,AGENTS,GEMINI}.md` | ZERO hits (exit=1) | ZERO hits (exit=1) | PASS |
| 2 | `grep -n "Pack agent roster"` same files | 1 hit per file (parity) | CLAUDE:365, AGENTS:342, GEMINI:357 | PASS (3/3) |
| 3a | `grep -n "architect / planner / coder / reviewer / tester / auditor"` same files | ZERO hits (V1+T5-A enumeration removed) | ZERO hits (exit=1) | PASS |
| 3b | `grep -n "docs/pack/PM-CHAT.md"` same files | 1 hit per file (SSOT pointer present) | CLAUDE:364, AGENTS:341, GEMINI:356 | PASS (3/3) |
| 4 | Trinity diff parity (CLAUDE↔AGENTS, CLAUDE↔GEMINI) at edited blocks | identical at hunks | exit=0 for V1+T5-A REPLACE (CLAUDE↔AGENTS); exit=0 for V8 REVERT (both pairs); GEMINI V1+T5-A REPLACE matches CLAUDE/AGENTS byte-for-byte (pre-existing variation in adjacent bullet is OUT-OF-SCOPE) | PASS |
| 5 | Project-side SSOT exists at client install | `project-template/docs/pack/PM-CHAT.md` contains `## Pack agent roster` | confirmed at L47 (also L239 cross-ref) | PASS |

`validate-pack.py` (Trinity Check 18 H2) intentionally NOT run by this
coder — parallel-batch siblings are concurrently editing other files in
the same worktree; running it now would conflict with their in-flight
edits. Pack Chat runs it after all 7 commits land (per plan §8.6
push-then-wait CI cascade).

Manifest regen intentionally NOT executed (parallel-batch constraint;
Pack Chat handles serially per-commit with git-stash isolation per plan
§8.7).

## §5 Plan deviations

NONE. All edits match A §2 V1 + T5-A + V8 implementation hints verbatim
and PLAN §2.4 exactly. Trinity rule applied strictly. No out-of-scope
edits. No state-changing git verbs invoked. No manifest regen (per
parallel-batch constraint).

GEMINI's pre-existing wording variation in the "No destructive
operations" bullet (2 lines ABOVE the V1+T5-A REPLACE block) was
documented in A §2 V1 as expected and is not a defect to fix in this
commit. Re-litigating that bullet would be scope creep (out of TASK-T1).

## §6 Files inventory

| Path | Change type | Lines delta |
|---|---|---|
| `project-template/CLAUDE.md` | modified (2 hunks) | -8 / +6 net = -2 lines (V1+T5-A: -7/+7 net 0; V8: -4/+0 = -4; blank-line trim recovers 2) |
| `project-template/AGENTS.md` | modified (2 hunks) | same shape as CLAUDE.md |
| `project-template/GEMINI.md` | modified (2 hunks) | V1+T5-A: -5/+7 = +2; V8: -4/+0 = -4; net -2 |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-4.md` | new (this report) | +~150 |

No other files touched. Sibling coders (Commits 5, 6, 7, 8, 9a, 11)
are concurrently editing file-disjoint scopes in the same worktree.

## §7 PREFLIGHT line

```
PREFLIGHT: 6/6 in-scope file edits complete; verification PASS; HEAD 21c134443aab09d00895b410e6587ce8d37f615d; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-4.md
```
