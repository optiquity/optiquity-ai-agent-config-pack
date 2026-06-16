# IMPL-REPORT — BD-221 C4 review fix (bd-pack-only-operational-rule leak)

**Regime:** in-place (parent working tree).
**Branch:** `v11-dev`.
**HEAD at start and end:** `e8eb0a5d2f061ac53c8c9ab66b10bd81c3dc37b4` (no commit made — agents-never-commit).
**Scope:** project-only. Applied ONE fix on top of the parked (uncommitted) C4 working-tree edits.

## The finding (C4 reviewer MUST)

C4's forward-looking markers introduced a `BD-217 coordination` token into
CLIENT `project-template/` content — a pack-self BD-NNN reference in
client-shipped docs, which violates `bd-pack-only-operational-rule` (client
content carries no pack-self concept: no BD-NNN, maintenance-docs, pack-*
names, Pack-Chat role). Two occurrences confirmed by the reviewer:

- `project-template/docs/pack/OPTIONAL-FEATURES.md` (line 283)
- `project-template/docs/pack/PM-CHAT.md` (line 878)

## The fix — before → after

Removed only the `BD-217 coordination` phrase from each marker. KEPT the
substantive forward-looking content and the `antigravity.google/docs/*`
re-verify pointer. The worktree/CLI note and the antigravity URL are
unchanged.

### `project-template/docs/pack/OPTIONAL-FEATURES.md` (line 283)

Before:
```
<!-- RE-VERIFY at impl: Antigravity worktree feature, BD-217 coordination, antigravity.google/docs/getting-started -->
```
After:
```
<!-- RE-VERIFY at impl: Antigravity worktree feature, antigravity.google/docs/getting-started -->
```

### `project-template/docs/pack/PM-CHAT.md` (line 878)

Before:
```
<!-- RE-VERIFY at impl: Antigravity CLI session/context/memory commands, BD-217 coordination, antigravity.google/docs/getting-started — the preview CLI verb names below are unconfirmed -->
```
After:
```
<!-- RE-VERIFY at impl: Antigravity CLI session/context/memory commands, antigravity.google/docs/getting-started — the preview CLI verb names below are unconfirmed -->
```

The resulting markers match the established legitimate pattern already in
`project-template/CLAUDE.md` ("Re-verify the Antigravity agent-invocation
mechanism against `antigravity.google/docs/subagents` before relying on it")
— a forward-looking re-verify pointer with NO BD-NNN reference.

## VERIFY — grep-zero-BD proof

Command: `grep -rn "BD-" project-template/docs/pack/`
Result: no match (exit=1) — **ZERO BD-NNN tokens** in the client docs tree.

Both targets after fix (`grep -n "BD-217\|BD-" <both files>`): no match (exit=1).

### Other pack-self leak re-grep (no NEW concept introduced)

- `grep -rn "maintenance-docs" project-template/docs/pack/` → only
  PRE-EXISTING matches in `prompts/reviewer.md` (L104) and `prompts/coder.md`
  (L87, L206). These are DENY-LIST CONTENT — they enumerate
  `maintenance-docs/` / `pack-*` / `Pack Chat` as forbidden tokens to teach
  agents what NOT to reference (meta-references inside a deny-list, not real
  pack-self references). Pre-existing, unrelated to this fix.
- `grep -rn "Pack Chat" project-template/docs/pack/` → only PRE-EXISTING
  matches in `PACK-FEEDBACK.md` (the legitimate project→pack upstream
  feedback channel — this file's documented purpose), `PM-CHAT.md` (L342/344,
  feedback-batch delivery prose, pre-existing), and the same deny-list lines
  in `prompts/`. No NEW occurrence.
- `grep -rEn "pack-(coder|architect|planner|reviewer|docs-researcher|chat)" project-template/docs/pack/`
  → no match (exit=1). Pre-existing legitimate command names (`pack-help`,
  `pack help`) intentionally retained; no new pack-* agent name.

No new pack-self concept was introduced by the fix.

## VERIFY — validate-pack unchanged-failing-set proof

Command: `python3 scripts/validate-pack.py`
Summary: `FAILED — 50 issue(s) found` (exit=1).

Distinct failing-check set (each FAIL line mapped to its enclosing
`── Check N ──` header):

```
5 17 18 21 28 39 41 55 57
```

This is **IDENTICAL** to the expected post-C4 failing set
**`{5, 17, 18, 21, 28, 39, 41, 55, 57}`**. The fix is doc-prose-only and
introduced no new break:

- Check 31 stays GREEN (not in the failing set).
- Check 54 stays GREEN (not in the failing set).

The 50 issues are all pre-existing C4-baseline failures from the in-progress
Gemini→Antigravity transition (missing `project-template/.gemini/agents/*`
files, stale `cmd_update` / `_CLIENT_INSTALLED_FILES` mappings for `.gemini/`
surfaces, GEMINI.md H2 divergence). None relate to the two doc-prose marker
edits.

## Files changed

| Path | Change type |
|---|---|
| `project-template/docs/pack/OPTIONAL-FEATURES.md` | modified (1 marker line; on top of parked C4 edits) |
| `project-template/docs/pack/PM-CHAT.md` | modified (1 marker line; on top of parked C4 edits) |

No other files touched. No new files. No deletions. No git state change.

## Plan deviations

None. Applied exactly the one fix specified; touched nothing else.

## New POQs

None.

## Definition-of-Done checklist

| Item | Result |
|---|---|
| BD-217 token removed from OPTIONAL-FEATURES.md marker | PASS |
| BD-217 token removed from PM-CHAT.md marker | PASS |
| Antigravity re-verify pointer (URL + worktree/CLI note) kept in both | PASS |
| `grep -rn "BD-" project-template/docs/pack/` → zero matches | PASS |
| No NEW pack-self concept (maintenance-docs / Pack Chat / pack-* agent) | PASS |
| validate-pack failing set unchanged `{5,17,18,21,28,39,41,55,57}` | PASS |
| Check 31 + Check 54 stay green (no new break) | PASS |
| Scope limited to the 2 named files | PASS |
| No git state change (agents-never-commit) | PASS |

## Rules-Applied Verification Block

| Rule | Verification evidence (measured/quoted) | Conclusion |
|---|---|---|
| **agents-never-commit** | All work done via Edit (in-place) + read-only git only (`git rev-parse HEAD`, `git status --short`, `git diff --stat`). HEAD unchanged: `e8eb0a5d2f061ac53c8c9ab66b10bd81c3dc37b4`. No `git add`/`commit`/`apply` run. | COMPLIANT |
| **bd-pack-only-operational-rule** | `grep -rn "BD-" project-template/docs/pack/` → no output (exit=1). Both markers now read `<!-- RE-VERIFY at impl: Antigravity ... antigravity.google/docs/getting-started ... -->` with no BD-NNN. No new maintenance-docs/Pack-Chat/pack-* agent token introduced (re-grep matches are all pre-existing deny-list/feedback-channel content). | COMPLIANT |
| **edit-in-place-not-full-rewrite** | Two targeted single-line Edit calls (one comment line each); surrounding content unchanged. `git diff` marker grep shows only the two `+` re-verify lines as net change. | COMPLIANT |
| **scope-deliverables-to-the-ask** | `git diff --stat` lists exactly the 2 named files; no other file edited; no report-adjacent changes. | COMPLIANT |
| **verify-full-ci-suite** | Ran `python3 scripts/validate-pack.py` (full battery, 61 checks). Failing set extracted by mapping each FAIL line to its check header = `5 17 18 21 28 39 41 55 57` = expected post-C4 set; `FAILED — 50 issue(s)` summary; Check 31 + 54 absent from failing set (green). | COMPLIANT |
| **rules-applied-verification-block** | This table; every rule has quoted/measured evidence and a terminal COMPLIANT conclusion (no empty evidence, no AMBIGUOUS). | COMPLIANT |
