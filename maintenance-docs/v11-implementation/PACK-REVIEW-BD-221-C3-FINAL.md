# PACK-REVIEW — BD-221 Commit C3 — FINAL (bounded-cycle close)

**Reviewer:** pack-reviewer (read-only)
**Scope:** FINAL review of the bounded review/fix cycle for C3 — confirm the
two prior findings (SHOULD-1, NIT-1) are correctly fixed in this worktree and
introduce no regression. NOT a re-litigation of the C3 conversion (already
reviewed CLEAN).
**Date:** 2026-06-17

---

## 0. Worktree regime (verified at startup)

| Item | Expected (per prompt) | Observed | Match |
|---|---|---|---|
| pwd | `…/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a1fb1306a7195401d` | same | ✅ |
| HEAD | d92e054 | `d92e05494883e3d529e552672db7f23d1e2f4d8c` | ✅ |
| branch | worktree-agent-a1fb1306a7195401d | `worktree-agent-a1fb1306a7195401d` | ✅ |
| uncommitted | 15 files under scripts/ | 15 files, all under `scripts/` | ✅ |

Every file read in this review is under the worktree path. The main checkout
at `…-v11-dev/` was NOT touched. Regime CONFIRMED — review proceeded.

The 15 modified files (all `M`, no untracked):
`scripts/add-capability.sh`, `scripts/lib/customization-preserve.sh`,
`scripts/lib/detect.sh`, `scripts/lib/migrator-core.sh`,
`scripts/migrate-v10-to-v11.sh`, `scripts/test-detect.sh`,
`scripts/test-migrator-core.sh`, `scripts/test-restore-from-backup.sh`,
`scripts/tests/fixtures/customization-preserve/language-heterogeneous/assertions.tsv`,
`scripts/tests/fixtures/customization-preserve/language-heterogeneous/manifest.tsv`,
`scripts/tests/fixtures/customization-preserve/v10-with-customization/assertions.tsv`,
`scripts/tests/fixtures/customization-preserve/v10-with-customization/manifest.tsv`,
`scripts/tests/test-customization-preserve.sh`,
`scripts/tests/test-migrate-v10-to-v11.sh`,
`scripts/validate-pack.py`.

---

## 1. Fix confirmation

### SHOULD-1 — stale `.mcp.json.example` migrator-manifest row removed — ✅ CORRECT

The C3 fix removed the stale migrator-manifest source-install row
`project-template/.mcp.json.example  .mcp.json.example  claude-mcp-example  transform`
from `migrator_manifest()` in `scripts/migrate-v10-to-v11.sh`.

Evidence:
- `grep -n 'mcp.json.example' scripts/migrate-v10-to-v11.sh` → **no match** for
  the old `.mcp.json.example` token (exit 1). The C3 replacement row
  `project-template/.agents/mcp_config.json.example  .agents/mcp_config.json
  claude-mcp-example  transform` is present (different substring — correct).
- The old source `project-template/.mcp.json.example` **does not exist**;
  the new source `project-template/.agents/mcp_config.json.example` **exists**
  (1619 bytes). The removed row pointed at a now-nonexistent pack source, so
  the removal is correct (a stale row, not a live install).
- Diff shows exactly the intended manifest deltas for this fix area: the
  `.mcp.json.example` row removed and the `.agents/mcp_config.json.example` row
  added (the latter is C3-conversion content, not SHOULD-1). No other
  `transform` row was disturbed by the fix.
- Every REMAINING manifest `transform` row whose source is a current pack file
  resolves to an existing source. (Two rows — `METHODOLOGY.md` and
  `PROMPT-TEMPLATES.md` — point at legacy docs not in the pack tree; that is a
  PRE-EXISTING, intentional legacy-continuity condition, see § 3 below.)

The non-manifest `.mcp.json.example` references that remain (in
`scripts/lib/customization-preserve.sh:155`, `scripts/merge-json.py:7`,
`scripts/validate-pack.py:5724`, `scripts/test-restore-from-backup.sh`,
`scripts/tests/test-customization-preserve.sh`) are the **customization
classifier leg + its tests** that classify a *client's existing*
`.mcp.json.example` file during migration — a legitimately different concern
from the migrator source-install manifest row. They are correctly left in
place.

### NIT-1 — carve-out comment at the `.gemini/agents/*` legacy-classify legs — ✅ CORRECT (comment-only)

`scripts/lib/customization-preserve.sh` `customization_classify()` gained a
carve-out comment (L164–166) directly above the two legacy `.gemini/agents/`
legs:

```
        # Per-CLI agents. The `.gemini/agents/` legs are a legacy-READ
        # carve-out (ii): the migrator must classify the departing v10
        # `.gemini` shape so it can relocate it (mirrors detect.sh).
        .claude/agents/x-*|.codex/agents/x-*|.gemini/agents/x-*)
            printf 'custom-agent\n' ;;
        .claude/agents/*.md|.codex/agents/*.md|.gemini/agents/*.md)
            printf 'pack-agent\n' ;;
```

Evidence the change is comment-only:
- The diff shows the prior `# Per-CLI agents` one-liner replaced by the 3-line
  carve-out comment; the two `case` legs themselves
  (`.gemini/agents/x-*` → `custom-agent`, `.gemini/agents/*.md` → `pack-agent`)
  are **byte-identical** before/after. No `printf` value or pattern changed.
- Behavior unchanged: classifier output for these legs is unaffected (Check 25
  exercises the classifier and is GREEN — see § 2).

The comment is accurate: it explains why a *departing* CLI's agent legs are
retained in the classifier (legacy-READ carve-out so the migrator can classify
and relocate the v10 `.gemini` shape), which is exactly what the new C3
`_v10_to_v11_retire_gemini` step consumes.

---

## 2. Regression / verification battery (all green)

| Verification | Expected | Observed | Verdict |
|---|---|---|---|
| `bash -n scripts/migrate-v10-to-v11.sh` | parse OK | `PARSE OK` | ✅ |
| `bash -n scripts/lib/customization-preserve.sh` | parse OK | `PARSE OK` | ✅ |
| `bash scripts/test-migrator-manifest.sh` | PASS | **12 passed, 0 failed**, exit 0 | ✅ |
| `bash scripts/tests/test-customization-preserve.sh` | PASS | **223 passed, 0 failed**, exit 0 | ✅ |
| `python3 scripts/validate-pack.py` | "52", Check 25 GREEN | **52 issue(s)**; failing checks == {52,55,56,57}; **Check 25 GREEN** | ✅ (see note) |

**validate-pack interpretation.** `validate-pack.py` exits 1 with
`FAILED — 52 issue(s) found`. The "52" in the prompt is the **issue count**
(exactly 52 FAIL lines). The distinct failing checks are precisely
**{52, 55, 56, 57}** — the BD-197 `.gemini/agents/*` two-class-consistency
(Check 52 pack / Check 55 project) and destructive-git-verb enumeration-parity
(Check 56 pack / Check 57 project) guards. Every FAIL is a
`agent file …/.gemini/agents/<name>.md not found` / `verb-parity surface
…/.gemini/… not found` — i.e. the guards still measure the now-removed Gemini
agent set. This is the **expected intermediate-red** for the BD-221 conversion
(the carry-forward map schedules {52, 55, 56, 57} for restoration at C8); it is
NOT a regression from C3 or the two fixes. validate-pack is *intended* to be
red until C8 in this conversion sequence.

**Check 25 (the one this review most cares about) is GREEN:**
```
── Check 25: Customization-detection regression guard (BD-089) ──
  OK: 3/3 fixture rows recorded with expected disposition + class
  OK: truthful-report contract: every fixture file appears in report.md
```
Check 25 directly exercises `customization-preserve.sh` (the NIT-1 file, also
the file where C3 removed the `gemini-env` class/strategy). Its GREEN status is
the empirical proof that neither the NIT-1 comment nor the C3 classifier
changes regressed customization detection.

---

## 3. Sanity-pass observations (NOT findings; out of fix-scope)

These are surfaced for completeness per `scope-deliverables-to-the-ask`
(surface, do not silently fix). None blocks the C3 close.

- **(INFO, pre-existing, not a regression)** Two migrator-manifest `transform`
  rows — `project-template/docs/pack/METHODOLOGY.md` and
  `project-template/docs/pack/PROMPT-TEMPLATES.md` — reference pack sources that
  do not exist in the tree. This is **PRE-EXISTING at the C3 baseline** (both
  rows present unchanged at HEAD d92e054; untouched by the C3 diff) and is
  **intentional**: `validate-pack.py:5664` explicitly allowlists
  `"PROMPT-TEMPLATES.md": "Legacy doc name; not in pack repo at HEAD (referenced
  for legacy continuity)"`, and `validate-pack.py:5131` documents it as "file
  retired in v10.0". These rows handle a *departing client v10 file* via the
  `transform` action; a missing pack source is supported by the framework. NOT
  introduced by C3 and NOT in scope. No action.

- **(INFO, C3-conversion content, already CLEAN)** The
  `v10-with-customization` fixture's `.gemini/.env` assertions were updated so
  `.gemini/.env` now routes through the **generic text** strategy (it classifies
  as `generic` after C3 removed the `gemini-env` class), with project values
  preserved in a sidecar. Verified: `customization_classify ".gemini/.env"` →
  `generic`; the fixture assertions were updated in lock-step and the test
  suite passes (223/0). This is part of the C3 conversion (already reviewed
  CLEAN), confirmed consistent here — not a fix-scope item.

---

## 4. Scope check — pack-only

All 15 modified files are under `scripts/`. Zero files outside `scripts/`; zero
untracked files. `scripts/` is a pack-side directory (not `project-template/`
nor `supporting-docs/`), so the commit is correctly **pack-only**. Consistent
with the C3 framing.

---

## 5. Rules-Applied Verification Block

| Rule (as named) | Verification evidence | Conclusion |
|---|---|---|
| operate-only-in-the-named-worktree | `pwd` = `…/.claude/worktrees/agent-a1fb1306a7195401d`; `git rev-parse HEAD` = `d92e054…`; branch `worktree-agent-a1fb1306a7195401d`; every Read/Bash path under the worktree; main `…-v11-dev/` never touched. | COMPLIANT |
| verification = fixes correct + no regression | `bash -n` both scripts PARSE OK; `test-migrator-manifest.sh` 12/0 exit 0; `test-customization-preserve.sh` 223/0 exit 0; validate-pack 52 issues == expected {52,55,56,57} intermediate-red; **Check 25 GREEN** (3/3 + truthful-report). | COMPLIANT |
| scope-deliverables-to-the-ask | Reviewed ONLY the 2 fixes + sanity pass; did NOT re-litigate the C3 conversion; the 2 INFO observations are surfaced (not silently fixed, not silently dropped) and explicitly marked out-of-scope/non-regressions. | COMPLIANT |
| agents-never-commit / read-only | No state-changing git verb run; no Edit on codebase; only file write is this report at `/tmp/handoff-bd221-C3/PACK-REVIEW-C3-FINAL.md`; all other tool calls are Read/grep/test-run (read-only). | COMPLIANT |
| agent-output-requires-rules-applied-verification-block | This block present; every in-force rule carries quoted evidence + a terminal conclusion (no AMBIGUOUS, no empty rows). | COMPLIANT |
| READ-IN-FULL named docs | Read directly via Read tool, in full: `CLAUDE.md ## Pack memory` (offset 140, lines 140–539, the section start to past § Repo conventions — covers Workflow / Agent-invocation / Sub-agent / Pack-Chat-scope / Repo-conventions); `feedback_agent_output_rules_applied_block.md` (15 lines; first `---`/last `Related: …`); `feedback_agents_read_rule_docs_in_full.md` (134 lines; first `---`/last `… catches the dangerous cases.`). No content derived from cache. | COMPLIANT |

---

## VERDICT: **CLEAN**

Both prior findings are correctly resolved in this worktree:
- **SHOULD-1** — the stale `.mcp.json.example` migrator-manifest row is GONE
  (grep-zero for the old token); the `.agents/mcp_config.json.example` row
  remains; only that one row removed; the removed source genuinely no longer
  exists in the pack tree.
- **NIT-1** — a comment-only carve-out was added at the `.gemini/agents/*`
  legacy-classify legs; the `case` legs are byte-identical (no behavior
  change).

No regression: both scripts `bash -n` clean; `test-migrator-manifest.sh`
PASS (12/0); `test-customization-preserve.sh` PASS (223/0); validate-pack
shows exactly the expected BD-221 intermediate-red set {52,55,56,57}
(restored at C8) with **Check 25 GREEN**. Scope is pack-only (15 files, all
under `scripts/`). Nothing changed beyond the C3 conversion + these 2 fixes.
The two sanity-pass INFO items are pre-existing/conversion-consistent and out
of fix-scope. The bounded review/fix cycle for C3 may close.
