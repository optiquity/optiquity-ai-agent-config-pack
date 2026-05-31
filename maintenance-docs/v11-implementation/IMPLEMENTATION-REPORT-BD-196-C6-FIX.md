# IMPLEMENTATION-REPORT-BD-196-C6-FIX — SHOULD-1 rationale correction

- **Branch:** v11-dev
- **HEAD (worktree base):** `0cbd6d5f70a6730da2023d8f2bcf45fc06cd9800`
- **Fix-coder pass:** 1 of max-2 (C6 of 12), BD-196
- **Scope:** ONE approved review fix — SHOULD-1 from
  `maintenance-docs/v11-implementation/PACK-REVIEW-BD-196-C6.md`. Prose/comment
  only; no logic change.

## The fix

SHOULD-1 found that the Check 46 anti-restate predicate's `>= 60`-char bound is
CORRECT but its STATED RATIONALE was factually wrong: both the source comment in
`scripts/validate-pack.py` and IMPL-REPORT §5 justified the bound with "longest
rule NAME is 56 chars." Measured reality (HEAD `0cbd6d5`): there are **5** rule
names ≥60 chars, the longest being **66** chars (`Regenerate
test-fixtures/manifest.txt on every v11-surface commit.`). The cited name is also
not 56 chars. The mechanism is unaffected — the predicate scans the imperative
BODY, never the NAME — but the name-length justification is misleading.

Corrected BOTH surfaces to state the TRUE, body-based rationale: rule-NAME length
is irrelevant because names are never scanned; the `>= 60` window is body-derived
and chosen empirically (every real imperative body's leading clause exceeds it →
no false-negative; a legitimate one-line name-reference cannot reach 60+
contiguous verbatim body chars → no false-positive).

### `scripts/validate-pack.py` — `_CHECK_46_ANTI_RESTATE_MIN_LEN` comment

OLD (wrong rationale):
> 60 chars is comfortably longer than any rule NAME (the longest, "Project-side
> concepts on pack-side surfaces — deliverable-only", is 56 chars and is a NAME
> not a BODY) yet short enough that any genuine multi-clause imperative
> restatement exceeds it.

NEW (correct, body-based rationale):
> The scan targets the whitespace-normalized imperative BODY (the text AFTER the
> bold rule name — see `_check_46_extract_pack_memory_imperative_bodies`, which
> discards the NAME group entirely), NOT the rule name. Rule-NAME length is
> therefore irrelevant to the bound: names are never scanned, so a long name
> cannot false-positive. The `>= 60`-char window is chosen empirically — every
> real `## Pack memory` imperative BODY's leading clause exceeds it (no
> false-negative …), while a legitimate one-line reference … cannot reach the
> threshold (no false-positive). The bound separates one-line NAME references
> from verbatim BODY restatements — it is body-derived, not name-derived.

### `IMPLEMENTATION-REPORT-BD-196-C6.md` §5 — Candidate B paragraph

OLD (wrong rationale):
> The 60-char bound is comfortably longer than any rule NAME (longest name = 56
> chars, and it is a NAME not a BODY) yet shorter than any genuine multi-clause
> imperative restatement …

NEW (correct, body-based rationale):
> The 60-char bound is **body-derived, not name-derived**: the predicate scans
> the imperative BODY (the text AFTER the bold rule name — the NAME group is
> discarded by `_check_46_extract_pack_memory_imperative_bodies`), so rule-NAME
> length is irrelevant (names are never scanned and cannot false-positive —
> measured: 5 rule names are themselves ≥60 chars, the longest being 66, yet
> none trip the check because the scan never sees a name). …

## Logic / value unchanged

- `_CHECK_46_ANTI_RESTATE_MIN_LEN = 60` — UNCHANGED.
- `_check_46_extract_pack_memory_imperative_bodies()` body-extraction regex and
  `min_len` filter — UNCHANGED.
- The anti-restate scan in `check_boundary_and_spawn_pointer_manifests()` —
  UNCHANGED.
- Only comment prose (validate-pack.py) and report prose (IMPL-REPORT §5) changed.

## Verification

`python3 scripts/validate-pack.py` → **PASSED — all checks clean** (exit 0).
Check 46 line: `boundary manifest: 8 surface(s) resolve …; spawn manifest: 6
rule(s) resolve …; anti-restate: 0 verbatim imperative-body restatements across 6
spawn-relevant surface(s) (45 candidate bodies scanned, >= 60 chars).` Identical
to pre-fix behavior — confirming the change is prose-only.

(Note: this is a prose/comment change with no fixture-affecting bytes added or
removed beyond `scripts/validate-pack.py` comment text. `scripts/` is a
v11-surface directory; manifest regen is a Pack-Chat staging-time obligation per
the manifest-regen rule. validate-pack's `fixture manifest verify` is a separate
CI step; the working-tree validate-pack run above is green.)

## Files changed (inventory)

| Path | Change type |
|---|---|
| `scripts/validate-pack.py` | modified (comment prose only) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-196-C6.md` | modified (§5 prose only) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-196-C6-FIX.md` | new (this report) |

## Plan deviations

None. Applied exactly the one approved SHOULD-1 fix; no logic touched.

## New POQs

None.

## Definition-of-Done checklist

| Item | Result |
|---|---|
| validate-pack.py comment rationale corrected to body-based | PASS |
| IMPL-REPORT §5 rationale corrected to body-based | PASS |
| Predicate logic unchanged | PASS |
| `>= 60` value unchanged | PASS |
| `python3 scripts/validate-pack.py` PASS | PASS |
| Check 46 behavior unchanged (0 hits) | PASS |
| No git state changes | PASS |
| Scope limited to the one approved fix | PASS |

## Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| Agents never commit | No `git add/commit/push/tag/reset` run; only `git rev-parse`/`git status` (read-only) in this session. | COMPLIANT |
| Edit-in-place (targeted; only wrong-rationale prose; no logic change) | Two `Edit` calls touched only the comment block above `_CHECK_46_ANTI_RESTATE_MIN_LEN` and the §5 Candidate-B paragraph. `_CHECK_46_ANTI_RESTATE_MIN_LEN = 60` and the body-extraction regex are byte-for-byte unchanged. | COMPLIANT |
| Verification before PREFLIGHT (validate-pack PASS) | `python3 scripts/validate-pack.py` → `PASSED — all checks clean`, exit 0; Check 46 line identical to pre-fix. | COMPLIANT |
| PREFLIGHT before fix-report | PREFLIGHT line emitted in chat (`2/2 in-scope edits; verification PASS; HEAD 0cbd6d5…`) before this Write. | COMPLIANT |
| Output ends with Rules-Applied Verification Block | This block. | COMPLIANT |
| Architect/planner state-claims require Empirical-Evidence | The corrected rationale's empirical claim ("5 names ≥60, longest 66") was measured via `python3` against `CLAUDE.md` `## Pack memory` (output: Total 42, ≥60 = 5, longest 66) before writing. | COMPLIANT |
| CI guard / allowlist design — measure-then-bound | Bound unchanged; this fix only corrects the recorded justification of an already-measured bound. Measurement re-run confirms the bound's true (body-based) basis. | COMPLIANT (rationale aligned to measurement) |
| PRISON RULE (ignore maintenance-docs/prison/) | No file under `maintenance-docs/prison/` read or edited. | COMPLIANT |
| Concise / scope-to-the-ask | One fix, two surfaces, concise report. | COMPLIANT |
| Trinity rule | N/A — neither edited file is a trinity (CLAUDE/AGENTS/GEMINI) file. | N/A: no trinity surface touched |
| No destructive ops without approval | No `rm`, `git rm`, or overwrite of trusted files; only targeted Edits + one new report Write. | COMPLIANT |
