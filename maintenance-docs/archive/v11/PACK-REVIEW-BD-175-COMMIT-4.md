# PACK-REVIEW — BD-175 Phase 5 Commit 4 (TASK-T1 trinity REPLACE+REVERT)

**Commit reviewed:** `f0d36c9` `feat: v11 — BD-175 TASK-T1 project-template trinity REPLACE + REVERT (V1 + T5-A + V8)`
**Coder IMPL-REPORT:** `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-4.md`
**Plan §:** §2.4 (Commit 4 detail) + §8.2 (parallel orchestration)
**Architect §:** §2 V1 + §2 T5-A + §2 V8 + §6.1 TASK-T1
**Pack-reviewer:** parallel batch, per-commit review (set ALPHA-EXPANDED, Commit 4 of 7)

---

## §0 — Executive summary

| Category | Count |
|---|---|
| VERIFIED | 14 |
| REMAINING ISSUE | 0 |
| NEW DEFECT | 0 |
| INFORMATIONAL (out-of-scope, surface only) | 2 |

**Verdict: GO for next commit / next stage.**

Commit 4 cleanly implements the TASK-T1 trinity REPLACE+REVERT per Architect A's §2 V1 + §2 T5-A + §2 V8 cluster. All 5 plan-prescribed grep checks pass with expected results (4 zero-hit checks, 1 single-hit-per-file check, byte-identical parity across CLAUDE/AGENTS/GEMINI at both edited blocks). Manifest regen lands in the same commit per RC9 (3 v11-* SHAs drifted; v10-* preserved). No plan deviations. Coder correctly punted `validate-pack.py` execution and manifest regen-execution per parallel-batch constraint — Pack Chat handled those serially per plan §8.7 (the manifest diff is in the actual commit).

Two informational items surfaced for completeness (§3), neither blocking — the well-documented pre-existing GEMINI bullet asymmetry (out-of-TASK-T1-scope per Architect A's explicit acknowledgement) and a pre-existing AGENTS.md tool-naming asymmetry (arguably tool-specific). User triage is needed on the GEMINI bullet asymmetry per the FIX-ALL default — Pack Chat presents both to user.

---

## §1 — Per-check verdicts with evidence

### Check 1 — V1 + T5-A REPLACE: ZERO `PACK-AGENTS` hits in project-template trinity

```
grep -n "PACK-AGENTS" project-template/CLAUDE.md project-template/AGENTS.md project-template/GEMINI.md
```

**Expected:** ZERO hits (exit 1). **Actual:** ZERO hits (exit 1).

**Verdict: VERIFIED.** The `see PACK-AGENTS.md for the full roster` reference is gone from all 3 trinity files. Wider sweep also confirms zero `PACK-AGENTS` hits in the entire `project-template/` tree.

### Check 2 — V1 + T5-A REPLACE: inline agent enumeration removed

```
grep -n "architect / planner / coder / reviewer / tester / auditor" \
  project-template/CLAUDE.md project-template/AGENTS.md project-template/GEMINI.md
```

**Expected:** ZERO hits (exit 1). **Actual:** ZERO hits (exit 1).

**Verdict: VERIFIED.** The T5-A inline enumeration anti-pattern is removed from all 3 trinity files. The collapsed prose "the corresponding agent" stands alone, with the SSOT pointer doing the enumeration work.

### Check 3 — V1 + T5-A REPLACE: SSOT pointer `docs/pack/PM-CHAT.md` present (1 per file)

```
grep -n "docs/pack/PM-CHAT.md" project-template/CLAUDE.md project-template/AGENTS.md project-template/GEMINI.md
```

**Expected:** 1 hit per file. **Actual:**
- `project-template/CLAUDE.md:364`
- `project-template/AGENTS.md:341`
- `project-template/GEMINI.md:356`

**Verdict: VERIFIED.** Bare path `docs/pack/PM-CHAT.md` (not a qualified pack-side path) — resolvable from a client repo root after install per A §2 V1 implementation hint.

### Check 4 — V1 + T5-A REPLACE: `Pack agent roster` reference present (1 per file)

```
grep -n "Pack agent roster" project-template/CLAUDE.md project-template/AGENTS.md project-template/GEMINI.md
```

**Expected:** 1 hit per file. **Actual:**
- `project-template/CLAUDE.md:365`
- `project-template/AGENTS.md:342`
- `project-template/GEMINI.md:357`

**Verdict: VERIFIED.** All 3 trinity files reference the project-side SSOT section by name.

### Check 5 — SSOT resolves at client install

`project-template/docs/pack/PM-CHAT.md:47` contains `## Pack agent roster` (verified by grep). Line 239 of the same file also contains the cross-reference "Pack roster is in `## Pack agent roster` above; do not infer it from any" — the SSOT discipline is self-reinforced.

**Verdict: VERIFIED.** The new pointer resolves at every client install (PM-CHAT.md ships via `init-project.sh`).

### Check 6 — V8 REVERT: ZERO `TOOL-COMPARISON` hits in project-template trinity

```
grep -n "TOOL-COMPARISON" project-template/CLAUDE.md project-template/AGENTS.md project-template/GEMINI.md
```

**Expected:** ZERO hits (exit 1). **Actual:** ZERO hits (exit 1).

**Verdict: VERIFIED.** The italicized paragraph is removed cleanly. Wider sweep also confirms zero `TOOL-COMPARISON` hits in the entire `project-template/` tree.

### Check 7 — V8 REVERT: ZERO `maintenance-docs` hits in project-template trinity

```
grep -n "maintenance-docs" project-template/CLAUDE.md project-template/AGENTS.md project-template/GEMINI.md
```

**Expected:** ZERO hits (exit 1). **Actual:** ZERO hits (exit 1).

**Verdict: VERIFIED.** No pack-only `maintenance-docs/...` paths remain in project-template trinity.

### Check 8 — Trinity parity at V1+T5-A REPLACE block

```
diff <(sed -n '362,368p' project-template/CLAUDE.md) <(sed -n '339,345p' project-template/AGENTS.md)  # exit 0
diff <(sed -n '362,368p' project-template/CLAUDE.md) <(sed -n '354,360p' project-template/GEMINI.md)  # exit 0
```

**Expected:** byte-identical AFTER block across all 3 CLI files (A §2 V1 specified one canonical AFTER wording). **Actual:** exit 0 on both pairs.

**Verdict: VERIFIED.** Trinity rule applied strictly at the REPLACE block. GEMINI's pre-existing shorter 5-line BEFORE shape (without the inline enumeration preamble) was harmonized to the canonical 7-line AFTER per A §2 V1 — this is correct behavior, not a regression.

### Check 9 — Trinity parity at V8 REVERT region

```
diff <(sed -n '385,405p' project-template/CLAUDE.md) <(sed -n '362,382p' project-template/AGENTS.md)  # exit 0
diff <(sed -n '385,405p' project-template/CLAUDE.md) <(sed -n '377,397p' project-template/GEMINI.md)  # exit 0
```

**Expected:** byte-identical at the post-routing-table → `### Custom agents` transition. **Actual:** exit 0 on both pairs.

**Verdict: VERIFIED.** Trinity rule applied strictly at the REVERT region. The italicized paragraph is removed identically in all 3 files; the blank-line spacing around `### Custom agents` is preserved consistently.

### Check 10 — Manifest regen (RC9 trigger)

```
git show f0d36c9 -- test-fixtures/manifest.txt
```

Shows 3 v11-* fixture SHAs drifted in the same commit:
- `v11-realistic-ot  cbab3ffc... → 175e24fc...`
- `v11-flat-file  b1d788ac... → 7e4960a3...`
- `v11-tracker-on  cce0f1ac... → a24201ad...`

`v10-minimal`, `v10-realistic-ot`, `existing-project-mid-dev` unchanged.

**Verdict: VERIFIED.** RC9 satisfied (project-template/ trinity is v11-surface; 3 v11-* rows drifted; v10-* tag-pinned rows unchanged as expected). Commit-message rationale block matches the actual manifest delta. Coder's PUNT-execution-but-Pack-Chat-handles-serially pattern (per plan §8.7 git-stash isolation) worked correctly.

### Check 11 — File inventory matches plan §2.4.2

Plan-prescribed: 3 trinity files + manifest = 4 files.
Actual `git show --stat`: `AGENTS.md` (16 lines), `CLAUDE.md` (16 lines), `GEMINI.md` (16 lines), `manifest.txt` (6 lines), `IMPLEMENTATION-REPORT-BD-175-COMMIT-4.md` (174 lines, new).

**Verdict: VERIFIED.** 4 in-scope files match plan exactly; IMPL-REPORT is the expected coder-deliverable artifact and is on-policy per skill-agent-maintainability §3 (workflow-artifact exemption during active batch development).

### Check 12 — Coder claim: zero plan deviations

Per IMPL-REPORT §5: "NONE. All edits match A §2 V1 + T5-A + V8 implementation hints verbatim and PLAN §2.4 exactly."

Independent verification by diffing the actual hunks against Plan §2.4.2 EXACT EDIT blocks: V1+T5-A AFTER matches Plan §2.4.2's canonical AFTER block character-for-character; V8 REVERT deletes the italicized paragraph (and its surrounding blank lines) cleanly with no replacement, matching A §2 V8 "Drop the pointer entirely … the routing-table itself is the project-side SSOT".

**Verdict: VERIFIED.** Coder's zero-deviation claim is correct.

### Check 13 — Override 9 informational consistency (plan §2.4.6)

Plan §2.4.6 notes: "Override 9 does not apply directly to this commit … But the principle (different audience = different wording) is consistent with this commit — project-side trinity gets project-side SSOT pointer; pack-side trinity (if it had an analogous reference) would point to pack-side SSOT."

The commit ships exactly that pattern: project-side trinity → `docs/pack/PM-CHAT.md` (project-side SSOT). Pack-root trinity is UNTOUCHED (legitimate pack-internal `PACK-AGENTS.md` reference per plan §2.4.5).

**Verdict: VERIFIED.** No Override 9 violation; the Override 9 principle is reflected consistently.

### Check 14 — No regression elsewhere in project-template trinity

Diff scope check (`git diff 21c1344..f0d36c9 -- project-template/`):
- 102 total lines of diff output across 3 trinity files
- 19 insertions / 29 deletions net
- All within the V1+T5-A REPLACE block and the V8 REVERT region — no spurious touches to phase-routing table, custom-agent section, project-memory section, or any other H2

**Verdict: VERIFIED.** No scope creep into other parts of the trinity. The `## Phase routing` table, `### Custom agents` section, `## Project memory` section, and all other H2s are byte-identical to HEAD-start.

---

## §2 — Defect classification

**NO DEFECTS introduced by Commit 4.** All 14 verified checks pass; both informational items in §3 are pre-existing trinity asymmetries that pre-date Commit 4 (last touched by `991d9e3` in v10.1).

No Commit-4-fix-pass required for any in-scope finding. The two informational items in §3 may produce a separate triage decision per the user's FIX-ALL default; recommendations are surfaced below.

---

## §3 — Pre-existing trinity asymmetry triage (this commit)

### §3.1 — Asymmetry A: "No destructive operations" bullet (coder-flagged)

**Location:** 2 lines ABOVE the V1+T5-A REPLACE block (so this asymmetry sits in the same trinity hunk-context that Commit 4 just edited).

**Precise diff** (CLAUDE/AGENTS vs GEMINI at the bullet's 3-line continuation):

| File | Wording |
|---|---|
| `project-template/CLAUDE.md:358-361` (mirrors AGENTS.md:335-338) | "any `git rm`, `rm -rf`, file deletion, overwrite, or<br>`git reset --hard`, state **exactly** what will be destroyed and wait<br>for explicit approval — even when the overall task is approved." |
| `project-template/GEMINI.md:350-353` | "any `git rm`, `rm -rf`, deletion, overwrite, or `git reset --hard`,<br>state what will be destroyed and wait for explicit approval — even<br>when the overall task is approved." |

**Three concrete differences:**
1. CLAUDE/AGENTS say "file deletion"; GEMINI says "deletion".
2. CLAUDE/AGENTS say "state **exactly** what will be destroyed"; GEMINI says "state what will be destroyed" (the word `exactly` is missing).
3. Line wrapping differs (CLAUDE/AGENTS use 4 lines; GEMINI uses 3 lines).

**Provenance:** Pre-existing at Commit 4's HEAD-start (`21c1344` `docs: v11 — BD-175 Commit 3 review report`). Verified by `git show 21c1344:project-template/GEMINI.md | grep -n "No destructive operations" -A 4`. Asymmetry originates from `991d9e3 docs: v10.1 — project trinity gains Project memory section` (v10.1 era; multiple commits prior to v11).

**Triage verdict: INFORMATIONAL (out-of-TASK-T1-scope) but recommends user triage per FIX-ALL default.**

**Rationale for OUT-OF-SCOPE classification:**
- Architect A §2 V1 EXPLICITLY anticipates this: "BEFORE (representative — trinity wording varies slightly across CLI files)". The trinity-wording-varies disclaimer was the architect's recognition that GEMINI had pre-existing variation in adjacent prose.
- TASK-T1's scope per A §6.1 is "V1 + T5-A + V8 together. All three findings edit the same trinity files." The destructive-operations bullet is NEITHER V1, T5-A, nor V8 — it is a separate trinity-rule item that pre-existed and was never claimed by the audit's §C boundary-violation enumeration.
- Per `feedback-deferral-is-scope-creep`, fixing it inline would be defensible (SIZE: trivial — 3 lines; LOGICAL FIT: same trinity block, 2 lines above the V1+T5-A hunk; BLOCKED: no). But adding it inline to Commit 4 AFTER the commit already landed would force `git commit --amend` (forbidden without explicit user request per `commit-discipline`) or a separate `fix:` commit.

**Severity if treated as a defect:** **LOW-to-MEDIUM** — semantic difference. The word `exactly` strengthens the rule's specificity requirement ("state EXACTLY what will be destroyed" demands the agent enumerate the exact paths; "state what will be destroyed" is weaker and could be satisfied by "I'll delete some files"). For an agent reading GEMINI.md to decide what level of approval-request specificity is required, the weaker GEMINI wording could materially change behavior. This is NOT a Trinity-Check-18 H2 parity violation (Check 18 only validates H2 names/order, not bullet wording — verified by reading `scripts/validate-pack.py:1230-1280`).

**Recommendation to Pack Chat (per FIX-ALL default):**
- **Option (preferred, per FIX-ALL):** Open a tracked anchor as a small new fix-up BD inserted IMMEDIATELY AFTER Commit 4 in the Phase 5 sequence per `feedback-deferral-is-scope-creep`, scoped to a 1-hunk-per-file trinity REPLACE of the destructive-operations bullet. SIZE: trivial. LOGICAL FIT: same trinity prose region. BLOCKED: no. Requires user approval per OQ-1.
- **Option (defer-with-anchor):** If user opts to defer, the anchor must be a live BD entry (per `feedback-deferred-work-tracking`); archived-report-only mention is not acceptable.

### §3.2 — Asymmetry B: "Both Codex and Claude Code" vs "All three tools" (NOT flagged in prompt — surfaced for completeness)

**Location:** `## Phase routing — default agent assignments` H2 sub-paragraph (also pre-existing).

**Precise diff:**

| File:line | Wording |
|---|---|
| `project-template/CLAUDE.md:372` | "All three tools (Claude Code, Codex, Gemini CLI) can execute any phase." |
| `project-template/GEMINI.md:364` | "All three tools (Claude Code, Codex, Gemini CLI) can execute any phase." |
| `project-template/AGENTS.md:349` | "Both Codex and Claude Code can execute any engineering phase in this repo." |

**Triage verdict: INFORMATIONAL — likely tool-specific (Codex CLI doesn't natively orchestrate Gemini), debatable whether it's truly justified.**

This asymmetry is OUT-OF-TASK-T1-scope and OUT-OF-Commit-4-touched-region (the V1+T5-A REPLACE block is 7 lines above this paragraph; Commit 4 did not touch this paragraph). It is surfaced only because the prompt asked the reviewer to triage the "pre-existing trinity asymmetry" — for completeness, the GEMINI bullet (§3.1) is the asymmetry the coder flagged; this one is adjacent.

**Recommendation:** No action required on this commit. If user wants comprehensive trinity-asymmetry sweep, a separate audit BD would be appropriate. Not blocking Commit 4 GO.

---

## §4 — PREFLIGHT line

```
PREFLIGHT: 14/14 in-scope verification checks PASS; 0 NEW DEFECTS; 0 REMAINING ISSUES; 2 INFORMATIONAL (pre-existing GEMINI bullet asymmetry + tool-naming asymmetry, both out-of-TASK-T1-scope per Architect A §2 V1 acknowledgement); HEAD f0d36c960c50dc9db611400e9b051cf46c8c9c8d; about to Write PACK-REVIEW to maintenance-docs/v11-implementation/PACK-REVIEW-BD-175-COMMIT-4.md; verdict GO for next commit
```
