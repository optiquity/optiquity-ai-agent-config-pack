# PACK-REVIEW — BD-203 C-1 fix1 (`test-v11-realistic-ot.sh` stale-needle fix)

**Reviewer:** pack-reviewer
**Branch:** v11-dev
**HEAD:** `2cc92b92e49e95799e44ffe4113d38ae634a85ba` (fix UNCOMMITTED in working tree)
**Scope reviewed:** `scripts/tests/test-v11-realistic-ot.sh` diff ONLY (other working-tree changes — BD-208/BD-200 IMPL/REVIEW docs, PLAN-BD-203.md, trinity/ops files — ignored per prompt; they belong to concurrent commits).

---

## VERDICT: CLEAN — APPROVE (one NIT, non-blocking)

The fix is correct, byte-accurate, necessary (NOT scope-creep), in-scope, and
regression-free. The C.3/C.4 discrepancy resolves in favor of the fix-coder:
the change was NECESSARY. One cosmetic NIT (display-only echo label) noted.

---

## 1. Green now (assess #1) — PASS

`bash scripts/tests/test-v11-realistic-ot.sh` → **PASS: 33 / FAIL: 0**
("All v11-realistic-ot integration tests PASSED (33/33).") Fixtures rebuilt
(`build.sh --all --clean` rc=0) before the run.

## 2. Byte-accuracy (assess #2) — PASS

Live validator output (`python3 scripts/validate-pack.py`) at this HEAD:

```
── Check 32′: no pack monolith exists (BD-203) ──
  OK: backlog/ — not present (skipping; pre-conversion pack-self or pre-v11.0 client)
  OK: changelog/ — not present (skipping; pre-conversion pack-self or pre-v11.0 client)
```

Source: `validate-pack.py:3191` (banner), `:3208–3209` (SKIP msg). Each new
needle is a verified `grep -F` substring of the live output:

| Needle | line | Result |
|---|---|---|
| C.2 `── Check 32′: no pack monolith exists (BD-203) ──` | 339 | FOUND (byte-exact, incl. `′` prime + `──`) |
| C.3 `backlog/ — not present (skipping; pre-conversion pack-self or pre-v11.0 client)` | 341 | FOUND |
| C.4 `changelog/ — not present (skipping; pre-conversion pack-self or pre-v11.0 client)` | 343 | FOUND |

## 3. DISCREPANCY RESOLUTION (assess #3) — fix NECESSARY / CORRECT

The CI run showed C.3/C.4 PASSING at the pushed (pre-fix) state, yet the
fix-coder changed them. Root cause established by measurement:

- `assert_contains` is a **whole-text substring** match
  (`test-v11-realistic-ot.sh:87` → `[[ "$2" == *"$3"* ]]`), matching against
  the validator's ENTIRE stdout, not a per-check slice.
- The OLD C.3/C.4 needle `backlog/ — not present (skipping; pre-v11.0 client
  or pre-BD-102 dog-food pack-self` is a substring of the CURRENT output —
  but **only of the Check 33 line** (`validate-pack.py:3284` →
  `:282` in printed output), NOT of Check 32′'s line.
- So at push, OLD C.3/C.4 passed by **accidentally matching the Check 33
  output** while purporting to assert Check 32′. C-1 did change Check 32′'s
  SKIP wording (`pre-BD-102 dog-food pack-self` → `pre-conversion pack-self`),
  so the OLD needles no longer described what Check 32′ actually prints.

Verdict: the C.3/C.4 change is **NECESSARY** — it re-points the assertions at
Check 32′'s real wording and removes a false-positive cross-check coupling
(C.3/C.4 silently asserting Check 33's text). This is correct per
`enumerate-encoding-surfaces` (banner + SKIP are two encoding surfaces of the
same C-1 change). NOT minimal-diff scope-creep. The fix-coder's §2/§3
discrepancy analysis is sound and matches the measured evidence.

## 4. No regression (assess #4) — PASS

| Command | Result |
|---|---|
| `python3 scripts/validate-pack.py` | rc=0 ("PASSED — all checks clean") |
| `bash scripts/tests/test-validate-pack-checks-32-33-34.sh` | FAIL: 0 (70/70 PASSED) |
| `bash scripts/tests/test-per-entry.sh` | FAIL: 0 (58/58 PASSED) |

## 5. Comments (assess #5) — PASS

Updated comments (lines 24–40, 291–318) are accurate and minimal — no
over-rewrite, no stale "mirror is in-sync" pack-side wording left in the
Check 32′ regions. The retained `pre-BD-102 dog-food pack-self` references at
lines 35, 308, 349, 351, 357 are CORRECT: they describe/assert Check 33/34,
which genuinely keep that wording (verified against `validate-pack.py:3284`).
C.6/C.7/C.9 needles (Check 33/34) correctly left untouched.

## 6. Scope (assess #6) — PASS

`git diff --name-only -- scripts/validate-pack.py` is EMPTY — validator NOT
touched. The only fix-relevant change in the working tree is
`scripts/tests/test-v11-realistic-ot.sh`. All other modified/untracked paths
are the concurrent BD-208/BD-200 docs and ops files explicitly out of scope.

---

## Findings

### NIT-1 — group-label echo not renamed for parity (display-only)
`scripts/tests/test-v11-realistic-ot.sh:325`
The runtime echo header still reads `Group C: validate-pack.py Check 32/33/34
pack-side SKIP behavior` while the adjacent comment header (line 294) and the
assertion labels were renamed to `Check 32′`. This is display text with no
assertion behind it, so it does not affect correctness or CI.
**Concrete fix (optional, minimal-diff):** change the echo to
`=== Group C: validate-pack.py Check 32′/33/34 pack-side SKIP behavior ===`
for parity with line 294. SKIP is also defensible (group spans three checks;
`32/33/34` reads as a range). Non-blocking.

No BLOCKER, MUST, or SHOULD findings. IMPL-REPORT
(`IMPL-BD-203-C1-fix1.md`) is accurate against the live tree, including its
manifest-byte-identical disposition (verified: `scripts/tests/` content does
not move `test-fixtures/manifest.txt`).

---

## Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| read-in-full + NO-DERIVATION | Read DIRECTLY via Read tool: `test-v11-realistic-ot.sh` diff (git diff, full) + regions (lines 330–369); `validate-pack.py:3180–3299` (Check 32′ banner/SKIP/Check 33); `IMPL-BD-203-C1-fix1.md` (full, 142 lines); `CLAUDE.md ## Pack memory` (full, in project-instructions context); memory files in full: `feedback_review_fix_cycle.md`, `feedback_scope_deliverables_to_the_ask.md`, `feedback_agent_output_rules_applied_block.md`, `feedback_verify_full_ci_suite.md`, `feedback_agents_read_rule_docs_in_full.md`. No named doc derived. | COMPLIANT |
| no-prior-reviews-to-reviewer | The earlier C-1 review (`PACK-REVIEW-BD-203-C1.md`) was NOT opened or referenced; verdict reached from the diff + live validator + IMPL-REPORT only. | COMPLIANT |
| scope-deliverables-to-the-ask | Reviewed exactly this one-file fix; led with the verdict; the 6 assess items + 1 NIT, no edge-case sprawl. | COMPLIANT |
| agents-never-commit | Only read-only verbs run (`rev-parse`, `status`, `diff --name-only`, `diff`); no `add`/`commit`/`push`/`tag`/`mv`/`rm`; build.sh writes only fixtures (not staged). No source edits. | COMPLIANT |
| verify-full-ci-suite-not-just-validate-pack | Ran the integration test (`test-v11-realistic-ot.sh` 33/33) AND validate-pack (rc=0) AND the two unit/per-entry batteries (70/70, 58/58) — not validate-pack alone. | COMPLIANT |
| rules-applied-verification-block | This per-rule table with quoted evidence + COMPLIANT terminals is the final section. | COMPLIANT |

### READ-IN-FULL per-file proof

| Document | Read method | Extent |
|---|---|---|
| `scripts/tests/test-v11-realistic-ot.sh` (diff + regions) | `git diff` + Read | Full diff + lines 330–369, helper 85–97 |
| `scripts/validate-pack.py` | Read | Lines 3180–3299 (Check 32′/33 regions) |
| `maintenance-docs/.../IMPL-BD-203-C1-fix1.md` | Read | Full (1–142) |
| `CLAUDE.md ## Pack memory` | project-instructions context | Full |
| `feedback_review_fix_cycle.md` | Read | Full |
| `feedback_scope_deliverables_to_the_ask.md` | Read | Full |
| `feedback_agent_output_rules_applied_block.md` | Read | Full |
| `feedback_verify_full_ci_suite.md` | Read | Full |
| `feedback_agents_read_rule_docs_in_full.md` | Read | Full |
