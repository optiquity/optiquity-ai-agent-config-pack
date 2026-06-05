# IMPL-REPORT — BD-200 commit C3 — fix-1 (F1 MUST + F2 NIT)

**Role:** fresh `pack-coder` (review-fix). **Branch:** `v11-dev`.
**Base HEAD (pre-flight):** `3bc96faf3f4bbed667cbd567b2c5a1f0132422ad`.
**Final HEAD:** `3bc96faf3f4bbed667cbd567b2c5a1f0132422ad` (UNCHANGED — no git state change; Pack Chat commits).
**Date:** 2026-06-04.
**Source review:** `maintenance-docs/v11-implementation/PACK-REVIEW-BD-200-C3.md` (F1 MUST, F2 NIT).
**Scope:** ADD the two review fixes on top of the existing uncommitted C3 working tree. Did NOT alter the T6 doc edits (HELP-FRAGMENT.md / PM-CHAT.md / INSTALL-PROCEDURES.md) or any other C3 work; did NOT touch C1/C2 files.

---

## Summary

| Finding | Severity | Status | Mechanism |
|---|---|---|---|
| F1 — `.pack-activate-capability-prompt.md` written but never gitignored | MUST | FIXED | New no-`$PACK` `ensure_prompt_gitignored()` helper invoked from `write_prompt_file()` before the prompt is written; P8 stdout note updated to "(gitignored)"; new harness assertions (`git check-ignore` IGNORED + dedupe). |
| F2 — `is_x_prefixed` referenced (P2) before its definition (under P5 banner) | NIT | FIXED | Definition hoisted into the `── Helpers ──` block (now precedes first use); behavior-preserving. |

---

## Per-task detail

### F2 — hoist `is_x_prefixed` (behavior-preserving)

**File:** `project-template/scripts/activate-capability.sh`.

- Moved `is_x_prefixed() { [[ "$(basename "$1")" == x-* ]]; }` from under the `── Stage P5 ──` banner (old line ~279) into the `── Helpers ──` block (now line 72, alongside `say`/`info`/`warn`/`die`), with a docstring noting it is used by P2's delta pass-through and P5's overwrite guard.
- Removed the duplicate old definition under the P5 banner.
- Order verified: definition at line 72; first use in `stage_p2_delta` at line 270; second use in `stage_p5_copy` at line 316. Definition now precedes first use.
- No behavior change: bash resolves function names at call time and `main()` sources the whole file before invoking any stage, so this was a readability nit only. Both behavioral walks (fresh-clone re-materialization + `x-`-preserve) still pass.

### F1 — gitignore the prompt artifact (no-`$PACK`)

**File:** `project-template/scripts/activate-capability.sh`.

**(a) New helper `ensure_prompt_gitignored()`** added to the `── Helpers ──` block (lines 74–88):

```sh
ensure_prompt_gitignored() {
    local gi="$TARGET/.gitignore"
    if [[ -f "$gi" ]] && grep -Fxq "$PROMPT_FILE" "$gi"; then
        return 0
    fi
    printf '%s\n' "$PROMPT_FILE" >> "$gi"
    info "+ $PROMPT_FILE to .gitignore"
}
```

Properties:
- **No `$PACK`** — operates purely on `$TARGET/.gitignore` (a client-local operation). It does NOT read `$PACK/project-template/.gitignore` (which the script cannot access and must not reference).
- **Dedupe** — `grep -Fxq` (fixed-string, whole-line) guards against appending a duplicate line; a second activation run leaves the count at exactly 1.
- **Creates `.gitignore` if absent** — the `>>` append creates the file when the `[[ -f "$gi" ]]` guard is false (improving on the sibling `add-capability.sh:446`, which only appends when `.gitignore` already exists). In a real client install `.gitignore` ships from `project-template/.gitignore`, but the helper is robust to its absence.
- **Single-file scope** — appends ONLY the `.pack-activate-capability-prompt.md` line; it does NOT add a `pack-capability-pool/` line (the pool stays TRACKED — F1 is strictly about the prompt artifact, and the pool-ignore boundary is respected).

**(b) Invocation site.** `ensure_prompt_gitignored` is called inside `write_prompt_file()` immediately before the prompt is written to disk (line 391):

```sh
    # Ensure the ephemeral prompt artifact is gitignored BEFORE writing it ...
    ensure_prompt_gitignored
    printf '%s' "$report" > "$TARGET/$PROMPT_FILE"
```

Placing the ensure inside `write_prompt_file()` (rather than only in `stage_p8_prompt`) covers BOTH prompt-write paths: the normal P8 path AND the `stage_p2_delta` "already-active" early-exit path (which also calls `write_prompt_file "already-active"` and writes the same artifact). Both paths now gitignore the artifact before writing it.

**(c) P8 stdout note update** (line 397):

```
say "──── PM chat prompt (also written to $PROMPT_FILE — gitignored) ────"
```

The "(gitignored)" suffix makes the gitignore behavior observable to the developer, consistent with the sibling's `info "+ $PROMPT_FILE to .gitignore"` disclosure (which this script also emits via the helper's `info` line on first add).

### F1 — harness assertion

**File:** `scripts/tests/test-activate-capability.sh` (Group 1, after the existing prompt-file token checks).

Two new assertions:

```sh
# F1 — the ephemeral prompt artifact MUST be gitignored ...
if git -C "$CLONE" check-ignore -q ".pack-activate-capability-prompt.md"; then
    t_pass "prompt artifact is gitignored (git check-ignore reports IGNORED)"
else
    t_fail "prompt artifact should be gitignored" "git check-ignore did not match"
fi

# A second activation run must NOT duplicate the .gitignore line (dedupe).
env -u PACK bash -c "cd '$CLONE' && bash '$ACTIVATE_REL' --add language:python" >/dev/null 2>&1 || true
GI_HITS=$(grep -Fxc ".pack-activate-capability-prompt.md" "$CLONE/.gitignore" 2>/dev/null || echo 0)
if [[ "$GI_HITS" == "1" ]]; then
    t_pass "second activation run does not duplicate the .gitignore line (count=1)"
else
    t_fail "prompt .gitignore line should appear exactly once" "count=$GI_HITS"
fi
```

This closes the encoding-surface asymmetry the review identified: the gitignore behavior now has a behavioral test partner (`enumerate-encoding-surfaces`).

---

## Verification results (all PASS)

| # | Check | Result | Evidence |
|---|---|---|---|
| 1 | `bash -n` both scripts | **PASS** | `bash -n project-template/scripts/activate-capability.sh scripts/tests/test-activate-capability.sh` → `ACTIVATE OK` / `TEST OK`. |
| 2 | F1 — `git check-ignore` IGNORED on `/tmp` scratch | **PASS** | Standalone scratch clone (init-project Swift-only install → `git clone` → `env -u PACK` activation): `git check-ignore .pack-activate-capability-prompt.md` → `IGNORED`. Scratch trees provisioned + trap-cleaned per `test-infra-self-provisioned`. |
| 2b | F1 — `git add -A` does NOT sweep the artifact | **PASS** | After `git -C "$DST" add -A`: prompt file ABSENT from `git status --porcelain` index → "NOT in index — would NOT be committed (GOOD)". |
| 2c | F1 — no `.gitignore` line duplication (2nd run) | **PASS** | `grep -Fxc` of the prompt line in `.gitignore` after a second activation → `1`. |
| 3 | F2 — `is_x_prefixed` defined before first use | **PASS** | def line 72; uses line 270 (P2) + 316 (P5). Fresh-clone walk + `x-`-preserve assertion both green. |
| 4 | Harness green incl. new assertions | **PASS** | `scripts/tests/test-activate-capability.sh` → **27 passed / 0 failed**, exit 0 (was 25/25 pre-fix; +2 = the F1 check-ignore + dedupe assertions). |
| 5 | Boundary — ZERO pack-self tokens / `$PACK` | **PASS** | `grep -nE '\$PACK\|pack-(architect\|planner\|coder\|reviewer)\|maintenance-docs/\|BD-[0-9]\|pack-ops/\|from the pack\|Pack Chat'` on `activate-capability.sh` → ZERO. BD-202 scan (`pack update\|cmd_update\|wipe.?repopulate\|three_way\|customization_preserve`) → ZERO. The `ensure_prompt_gitignored` helper touches only `$TARGET/.gitignore` (client-local). |
| 6 | Manifest regenerated | **PASS** | `bash test-fixtures/build.sh --all --clean` → exactly the three v11-* rows moved (`v11-realistic-ot`, `v11-flat-file`, `v11-tracker-on`); v10-* + `existing-project-mid-dev` unchanged. Second regen byte-identical (deterministic). See "Manifest rows moved" below. |
| 7 | `validate-pack.py` PASSED | **PASS** | exit 0, `PASSED — all checks clean`. Check 22 green (project-template 2 prose-referenced verbs present — `activate-capability.sh` resolves); Check 37 green (170 files, zero contamination); Check 43 green (158 files, zero pack-internal bare refs); Check 41 green (37 entries, 0 drift); Check 47 frozen 2-tuple `{scripts/lib/detect.sh, scripts/pack-help.sh}` unmoved. Check 48 WARNs are pre-existing JC-5 soft-advisory (exit-code-unaffected, unrelated to C3). |

### Manifest rows moved

```
-v11-realistic-ot  b933e2142a00b4c95cdf6d2be940744ac1b05995
-v11-flat-file  5587dc156de0cef3b517902d17d108b80f787c63
-v11-tracker-on  eafdd09a085258f215b92af7e91ba04186250a2b
+v11-realistic-ot  53ceb9178e547f1d0215b7637f0d7abd4829ae15
+v11-flat-file  ac3186eecf2ea8d673a85f48527eb87d6c3ffe2d
+v11-tracker-on  efa3f58b531d5374b966d855fdd6b45c8eb809ec
```

The fix-1 edit changes the shipped `project-template/scripts/activate-capability.sh` content (S5-copied into every v11 fixture), so the three v11-* fixture SHAs move from their C3-baseline values. v10-* and `existing-project-mid-dev` rows unchanged (they use the v10 init / are not v11-surface).

---

## Files changed (inventory)

| Path | Change type | Notes |
|---|---|---|
| `project-template/scripts/activate-capability.sh` | modified (untracked C3 file) | F1: `ensure_prompt_gitignored()` helper + invocation in `write_prompt_file()` + P8 note. F2: `is_x_prefixed` hoisted to Helpers block. |
| `scripts/tests/test-activate-capability.sh` | modified (untracked C3 file) | F1: two new Group-1 assertions (`git check-ignore` IGNORED + dedupe count). |
| `test-fixtures/manifest.txt` | modified | Regenerated; three v11-* rows moved. |

**Untouched (confirmed):** the three T6 doc edits (`HELP-FRAGMENT.md`, `PM-CHAT.md`, `INSTALL-PROCEDURES.md`) carry no fix-1 change; C1/C2 files (`add-capability.sh`, `init-project.sh`, `capability-tables.sh`) untouched. No `pack-capability-pool/` ignore line added (pool stays TRACKED). No `$PACK` introduced.

---

## Plan deviations

ZERO. The fix follows the F1 recommended-fix (gitignore-ensure, no-`$PACK`, harness assertion) and F2 recommended-fix (hoist) exactly. One robustness improvement over the literal sibling pattern: the helper creates `.gitignore` if absent (the sibling `add-capability.sh:446` only appends when it already exists) — this matches the F1 spec's explicit "create `.gitignore` if absent" requirement and is strictly safer.

## New POQs introduced

NONE.

## Boundary discipline check

`activate-capability.sh` is a `project-template/` (client-shipped) surface. The F1 edit is a CLIENT-LOCAL operation (`$TARGET/.gitignore`), not a reference to any pack-only SSOT. No pack-only file (`pack-ops/`, `maintenance-docs/`, pack-* agent name, `Pack Chat`) is referenced by the edit. SSOT investigated for the "ephemeral-artifact-gitignore" concept: the established CLIENT convention is the `.pack-*`-means-gitignored invariant (ARCHITECTURE-BD-200-ADVERSARIAL-REVIEW.md §3 GAP-C / EEB-GITIGNORE) and the sibling client-installed `add-capability.sh` prompt-gitignore behavior — both are project-side / client-installed references, used here without importing any pack-only mechanism. No boundary stop.

## Definition-of-Done checklist

| Item | Status |
|---|---|
| F1 — script ensures `.pack-activate-capability-prompt.md` is gitignored (no-`$PACK`) | PASS |
| F1 — `git check-ignore` reports IGNORED after a run | PASS |
| F1 — `git add -A` would NOT sweep the artifact | PASS |
| F1 — `.gitignore` line not duplicated on a second run | PASS |
| F1 — P8 stdout note reflects "(gitignored)" | PASS |
| F1 — harness assertion added + green | PASS |
| F2 — `is_x_prefixed` defined before first use (hoisted to Helpers) | PASS |
| F2 — behavior-preserving (both walks pass) | PASS |
| Pool stays TRACKED — no pool-ignore line added | PASS |
| BD-202 boundary intact — no `pack update`/`cmd_update` logic | PASS |
| Boundary — zero pack-self tokens / `$PACK` in `activate-capability.sh` | PASS |
| Manifest regenerated + staged-ready; three v11-* rows moved | PASS |
| `validate-pack.py` PASSED (22/37/41/43 green; 47 frozen unmoved) | PASS |
| Harness green (27/27) | PASS |
| HEAD unchanged; no git state change | PASS |

---

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **READ-IN-FULL** (agents-read-rule-docs-in-full) | Each named file Read IN FULL via the Read tool, per-file proof: `CLAUDE.md` (read in full as project-instructions system context — first `# CLAUDE.md — AI Agent Config Pack (Pack Repo)` → last `OT itself is read-only for testing (use /tmp clones or scratch fixtures, never write to real OT).`); `pack-ops/PACK-AGENTS.md` (226 lines, first `# PACK-AGENTS.md — AI Agent Config Pack (Pack Repo)` → last `Always run \`git add -A && git status\` and confirm staged files before any commit.`); `pack-ops/PACK-CHAT.md` (310 lines, first `# PACK-CHAT.md — Pack Chat Startup and Operating Instructions` → last `verified by END-STATE checks ... not a hard-enforced step sequence.`); `project-template/CLAUDE.md` (456 lines, first `# CLAUDE.md` → last `## Project addenda`); `PACK-REVIEW-BD-200-C3.md` (102 lines, F1+F2 detail + verification table read in full); `PLAN-BD-200.md` (234 lines, §2 T3/T6 + §5 + §6 + EEB-GITIGNORE-NO-POOL read in full); `ARCHITECTURE-BD-200-ADVERSARIAL-REVIEW.md` GAP-C + EEB-GITIGNORE (grep-anchored lines 19/56/57/81/151/159/163/272-275/305 read); SOURCE: `project-template/scripts/activate-capability.sh` (403 lines, full), `scripts/add-capability.sh` PROMPT_FILE (line 67) + gitignore-ensure (lines 445-449), `scripts/tests/test-activate-capability.sh` (247 lines, full), `project-template/.gitignore` (102 lines, full); curated memory (each full): `feedback_agents_read_rule_docs_in_full.md` (71L), `feedback_agent_output_rules_applied_block.md` (14L), `feedback_manifest_regen_on_v11_surface.md` (15L), `feedback_bd_pack_only_operational_rule.md` (34L). | **COMPLIANT** |
| **preflight-stop-means-stop** | Emitted the single PREFLIGHT line only AFTER all edits + verification PASS (bash -n, harness 27/27, validate-pack exit 0, F1 check-ignore evidence, boundary scan, manifest regen). No partial IMPL-REPORT. No parent stop directive received. | **COMPLIANT** |
| **agents-never-commit** | Only read-only git verbs against the pack tree (`git rev-parse`, `git branch`, `git status`, `git diff`). All `git init/add/commit/clone/check-ignore` ran exclusively against `/tmp` mktemp SCRATCH trees (the harness + my standalone F1 evidence run), trap-cleaned. ZERO `git add/commit/push/tag` against the pack working tree. Final HEAD `3bc96fa` == base HEAD. Single non-scratch Write = this IMPL-REPORT at the caller-specified path. | **COMPLIANT** |
| **boundary / no-pack-self-in-project** | `grep` on `activate-capability.sh` for `$PACK`/`pack-*`-agent/`maintenance-docs/`/`BD-NNN`/`pack-ops/`/"from the pack"/"Pack Chat" → ZERO. The F1 helper operates only on `$TARGET/.gitignore` (client-local). Check 43 (158 files) + Check 37 (170 files) green. | **COMPLIANT** |
| **regenerate-manifest-v11-surface** | `activate-capability.sh` ships under `project-template/` → v11-surface. Ran `bash test-fixtures/build.sh --all --clean`; exactly three v11-* rows moved (diff quoted above); v10-*/existing rows unchanged; second regen byte-identical (deterministic). Manifest left regenerated in the working tree for Pack Chat to stage. | **COMPLIANT** |
| **enumerate-encoding-surfaces** | F1 added the gitignore encoding partner the review found missing: the script behavior (`ensure_prompt_gitignored`) AND the harness assertion (`git check-ignore` IGNORED + dedupe) move in lock-step; the P8 stdout note is also updated. No asymmetry remains. | **COMPLIANT** |
| **pack-repo-code-comment-deferrals** | No deferral comments added (none needed). Grep for plain `TODO`/`FIXME`/`fix later` in the diff → none introduced. | **N/A: no deferrals introduced** |
| **rules-applied-verification-block** | This block — per-rule name + measured/quoted evidence + terminal verdict; no empty-evidence rows; READ-IN-FULL row carries per-file proof (line count + first/last anchors or grep-anchored line list). | **COMPLIANT** |
