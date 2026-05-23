# IMPLEMENTATION REPORT — BD-173 Batch 19c.4 (H.4) — Trinity STRENGTHEN: destructive-operations list extension (`git checkout --`)

**Batch:** 19c (BD-173 project-side cleanup, architect-led 16-commit batch)
**Commit:** H.4 (4th of 16 — first INLINE per-commit reviewer attached to this commit per V2 §I + Decision 4 α-sliding)
**BD:** BD-173
**Agent:** pack-coder
**Date:** 2026-05-23
**Branch:** v11-dev
**HEAD at start:** `bfa3a3317b8aecbee09fbd18c17449edc2effa56`
**HEAD at end:** `bfa3a3317b8aecbee09fbd18c17449edc2effa56` (no commits — coder never commits)

---

## §1 Scope

Apply V2 §C.6 AFTER text byte-identically to all three project-template trinity files. The STRENGTHEN extends the existing "No destructive operations without explicit approval" bullet's named list with `git checkout -- <path>` (with "on a file with uncommitted agent work" qualifier), and appends a trailing rationale sentence explaining why `git checkout --` is destructive.

**Files modified (in-scope):**
1. `project-template/CLAUDE.md`
2. `project-template/AGENTS.md`
3. `project-template/GEMINI.md`

**RC9 by-product (in-scope, unstaged for Pack Chat):**
4. `test-fixtures/manifest.txt` — three v11-* fixture row SHAs updated to reflect the v11-surface trinity edits.

**File count:** 3 trinity files + 1 manifest = 4 working-tree modifications attributable to H.4.

**Out-of-scope (untouched):**
- `maintenance-docs/v11-research/EXTERNAL-RESEARCH.md` (sibling chat — pre-existing modification)
- `maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md` (sibling chat — pre-existing modification)
- `maintenance-docs/v11-research/HANDOFF-V11.1-ARCHITECT.md` (sibling chat — pre-existing untracked file)
- Pack-root trinity (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` at pack root) — H.15 is the pack-root trinity commit per PLAN; H.4 is project-template trinity only.

---

## §2 Edits applied

### 2.1 — V2 §C.6 AFTER text (canonical, applied byte-identically to all three trinity files)

The replacement text (V2 §C.6 L369-376 verbatim):

```
- **No destructive operations without explicit approval.** Before
  any `git rm`, `rm -rf`, file deletion, overwrite, `git reset
  --hard`, or `git checkout -- <path>` on a file with uncommitted
  agent work, state exactly what will be destroyed and wait for
  explicit approval — even when the overall task is approved.
  `git checkout --` is destructive because it discards
  working-tree changes irreversibly; never run it on files that
  contain coder-written changes without per-action user approval.
```

### 2.2 — `project-template/CLAUDE.md` (insertion anchor L365)

**Insertion anchor verified:** `grep -n "No destructive operations" project-template/CLAUDE.md` → `365:- **No destructive operations without explicit approval.** Before`. The bullet body spans L365-368 in BEFORE form (4 lines, ending at "even when the overall task is approved.").

**BEFORE (4 lines, L365-368):**

```
- **No destructive operations without explicit approval.** Before
  any `git rm`, `rm -rf`, file deletion, overwrite, or
  `git reset --hard`, state exactly what will be destroyed and wait
  for explicit approval — even when the overall task is approved.
```

**AFTER (8 lines, L365-372):** V2 §C.6 AFTER text applied verbatim (see §2.1).

**Line delta:** +8 lines added, -4 lines removed → net +4 lines.

### 2.3 — `project-template/AGENTS.md` (insertion anchor L342)

**Insertion anchor verified:** `grep -n "No destructive operations" project-template/AGENTS.md` → `342:- **No destructive operations without explicit approval.** Before`. The bullet body spans L342-345 in BEFORE form (4 lines).

**BEFORE (4 lines, L342-345):**

```
- **No destructive operations without explicit approval.** Before
  any `git rm`, `rm -rf`, file deletion, overwrite, or
  `git reset --hard`, state exactly what will be destroyed and wait
  for explicit approval — even when the overall task is approved.
```

**AFTER (8 lines, L342-349):** V2 §C.6 AFTER text applied verbatim (see §2.1).

**Line delta:** +8 lines added, -4 lines removed → net +4 lines.

### 2.4 — `project-template/GEMINI.md` (insertion anchor L361)

**Insertion anchor verified:** `grep -n "No destructive operations" project-template/GEMINI.md` → `361:- **No destructive operations without explicit approval.** Before`. The bullet body spans L361-364 in BEFORE form (4 lines).

**BEFORE (4 lines, L361-364):**

```
- **No destructive operations without explicit approval.** Before
  any `git rm`, `rm -rf`, file deletion, overwrite, or
  `git reset --hard`, state exactly what will be destroyed and wait
  for explicit approval — even when the overall task is approved.
```

**AFTER (8 lines, L361-368):** V2 §C.6 AFTER text applied verbatim (see §2.1).

**Line delta:** +8 lines added, -4 lines removed → net +4 lines.

### 2.5 — BD-178 baseline verification

V2 §C.6 (L362) requires the STRENGTHEN to apply to the BD-178-canonicalized HEAD form, NOT V1's pre-BD-178 form. Verification:

The BEFORE text in all three trinity files is byte-identical and matches the V2 baseline description (named list `git rm`, `rm -rf`, file deletion, overwrite, `git reset --hard`). This IS the BD-178-canonicalized form — confirmed by:
- All three files contain the exact same 4-line bullet body (cross-trinity byte-identity)
- The bullet body ends at `git reset --hard,` (the V2 baseline endpoint per L364)
- No V1 pre-BD-178 wording remnants present

Therefore the STRENGTHEN is applied to the correct baseline.

### 2.6 — Override 9 (cross-CLI canonicalization) non-applicability

Per V2 §C.6 L366 + V2 §C.6 L379 + PLAN H.4 step 5: this bullet contains NO CLI-specific references. All operations named (`git rm`, `rm -rf`, file deletion, overwrite, `git reset --hard`, `git checkout -- <path>`) are platform-neutral git verbs or shell commands. Override 9 (canonical-reference-table substitution per BD-182 §4.1) carve-out does NOT apply here. Byte-identical adoption across all three trinity files is the correct choice and is verified in §3.4 below.

---

## §3 Verification

### 3.1 — `python3 scripts/validate-pack.py` — PASS

All 42 CI checks PASSED. Key checks for this commit:

- **Check 16 — Trinity hash mechanics (BD-073):** OK (implicit — no failure raised)
- **Check 18 — H2 within-trinity body identity (BD-152):** OK (implicit — no failure raised)
- **Check 19 — Trinity rules:** OK (implicit — no failure raised)

Full output tail (last 30 checks visible): `PASSED — all checks clean`.

### 3.2 — `bash test-fixtures/build.sh --all --clean` — completes successfully

All six fixtures built deterministically:

```
── building v10-minimal ──            HEAD: 19558cbac58ed3e47642a6bbe64418a38c60bc16 (tag-pinned, unchanged)
── building v10-realistic-ot ──       HEAD: 4c62945f72b037908b38967d5d8f019745263258 (tag-pinned, unchanged)
── building v11-realistic-ot ──       HEAD: 66d960011d4973430c91b9523a5de89787ac8fd1 (DRIFT vs prior; v11-surface)
── building v11-flat-file ──          HEAD: 50ad26ea1cd2fef1c4b06062fafbfa2c82da2ff6 (DRIFT vs prior; v11-surface)
── building v11-tracker-on ──         HEAD: 5b753394b508443b0384b7e2db98b4986f057e61 (DRIFT vs prior; v11-surface)
── building existing-project-mid-dev ─ HEAD: a54e081a9e1d04f293bfb38fa0af77fd9f7f8619 (no v11-surface, unchanged)

manifest written: test-fixtures/manifest.txt
```

### 3.3 — `git diff --stat test-fixtures/manifest.txt` — expected v11-* row drift

```
test-fixtures/manifest.txt | 6 +++---
1 file changed, 3 insertions(+), 3 deletions(-)
```

Full diff:

```
-v11-realistic-ot  4aea81453147510623570f3c1beb923624e01319
-v11-flat-file  2771bee4e6f184b66a5d1422665dac41a957e304
-v11-tracker-on  a4ad96431f120bd9f038cf5f9d36bafc55b59d66
+v11-realistic-ot  66d960011d4973430c91b9523a5de89787ac8fd1
+v11-flat-file  50ad26ea1cd2fef1c4b06062fafbfa2c82da2ff6
+v11-tracker-on  5b753394b508443b0384b7e2db98b4986f057e61
```

Clean 1:1 row swap on the three v11-* fixtures only. v10-* rows tag-pinned (unchanged); `existing-project-mid-dev` row unchanged (no v11-surface dependency). Matches the documented expected drift pattern.

**Manifest left unstaged in working tree per coder rules** — Pack Chat will stage it alongside the trinity edits in the H.4 commit.

### 3.4 — Trinity byte-identical parity diffs — PASS

```bash
$ diff <(grep -A6 "No destructive operations" project-template/CLAUDE.md) \
       <(grep -A6 "No destructive operations" project-template/AGENTS.md)
# (empty output)
$ diff <(grep -A6 "No destructive operations" project-template/CLAUDE.md) \
       <(grep -A6 "No destructive operations" project-template/GEMINI.md)
# (empty output)
```

Both diffs empty → CLAUDE.md, AGENTS.md, GEMINI.md carry byte-identical "No destructive operations" bullet text. Override 9 non-applicability confirmed (no per-CLI divergence; identical-by-construction is correct here).

### 3.5 — Working-tree status — clean to scope

```
M maintenance-docs/v11-research/EXTERNAL-RESEARCH.md         (out-of-scope, pre-existing)
M maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md (out-of-scope, pre-existing)
M project-template/AGENTS.md                                  (in-scope, H.4)
M project-template/CLAUDE.md                                  (in-scope, H.4)
M project-template/GEMINI.md                                  (in-scope, H.4)
M test-fixtures/manifest.txt                                  (in-scope, RC9 by-product)
?? maintenance-docs/v11-research/HANDOFF-V11.1-ARCHITECT.md   (out-of-scope, pre-existing untracked)
```

No unintended modifications. The 3 `maintenance-docs/v11-research/` files were already in this state at session start and were never touched.

### 3.6 — Trinity diff stat — symmetric

```
project-template/AGENTS.md | 10 +++++++---
project-template/CLAUDE.md | 10 +++++++---
project-template/GEMINI.md | 10 +++++++---
3 files changed, 21 insertions(+), 9 deletions(-)
```

Symmetric line deltas across all three trinity files (7 insertions, 3 deletions each — 4-line BEFORE → 8-line AFTER, net +4 lines per file). Symmetry is expected for a byte-identical trinity STRENGTHEN.

---

## §4 Cross-references

- **V2 spec source:** `maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19C-V2.md` §C.6 L357-381
  - L366-377 — AFTER-text contract (canonical V2 §C.6 text applied byte-identically)
  - L362 — REVISED-WORDING per salvageability B5 — BD-178-canonicalized baseline contract
  - L379 — Trinity ripple + Override 9 non-applicability (BD-182 §4.1 cross-CLI reference table review)
  - L381 — D-11 cascade verdict — REFRAME-EXCEPTION (defense-in-depth retention at trinity)
- **V2 §D.6.3 — Defense-in-depth exception (one of two documented):** Per V2 §D.6 PM-chat omniscience obligation principle, the default rule-placement is single-source (PM-CHAT.md). The trinity STRENGTHEN STAYS at trinity per defense-in-depth exception. Rationale: `git checkout --` is a git verb that ALL agents must respect; trinity is the rules-agents-must-respect surface; PM-chat injection would be more brittle than every agent reading the rule from trinity at session start.
- **PLAN H.4:** `maintenance-docs/v11-implementation/PLAN-CLEANUP-BATCH-19C.md` L203-249
  - L207-211 — Files modified list (3 trinity files)
  - L213-218 — Edit specification (step-by-step)
  - L220-231 — Verification commands
  - L233 — RC9 manifest regen REQUIRED
  - L235-240 — Per-commit reviewer INLINE — sliding-window scope (H.1-H.4)
  - L242 — Commit subject scope keyword (mixed, no keyword)
  - L244 — Commit message: `feat: v11 — BD-173 trinity destructive-ops list extension (Batch 19c.4)`
  - L246 — PREFLIGHT line shape
- **BD-178 baseline:** Trinity canonical alignment baseline; the BEFORE form in all three trinity files matches the BD-178-canonicalized state (verified §2.5 above).

---

## §5 Success criteria checklist

| # | Criterion | Status |
|---|-----------|--------|
| 1 | Three project-template trinity files updated with V2 §C.6 AFTER text | PASS (§2.2, §2.3, §2.4) |
| 2 | Byte-identical across the three trinity files (diff outputs empty for the bullet) | PASS (§3.4) |
| 3 | `python3 scripts/validate-pack.py` PASS | PASS (§3.1) |
| 4 | `bash test-fixtures/build.sh --all --clean` completes; manifest diff non-empty and unstaged | PASS (§3.2, §3.3) |
| 5 | IMPL-REPORT written to `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.4.md` | PASS (this file) |

All five criteria met.

---

## §6 Out-of-scope confirmations

### 6.1 — Sibling research files untouched

Per H.4 prompt forbidden-actions list. Verified via §3.5 working-tree status:

- `maintenance-docs/v11-research/EXTERNAL-RESEARCH.md` — appears in `git status` as `M` because of a pre-existing sibling-chat modification. Not touched by H.4.
- `maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md` — same; pre-existing sibling-chat modification. Not touched by H.4.
- `maintenance-docs/v11-research/HANDOFF-V11.1-ARCHITECT.md` — appears as untracked (`??`); not present at session start in the prompt-noted state but consistent with sibling-chat activity. Not touched by H.4.

These three files match the "DO NOT touch" out-of-scope items in the prompt. They appear in `git status` only because the working tree carries pre-existing sibling-chat changes; H.4 contributed zero modifications to them.

### 6.2 — Pack-root trinity untouched

H.4 = `project-template/` trinity ONLY. The pack-repo-root trinity (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md` at repo root) was NOT modified — H.15 is the planned pack-root trinity commit per PLAN. Verification: no pack-root trinity files in `git diff --stat`.

### 6.3 — BD-178 baseline assumed (not pre-BD-178)

Per V2 §C.6 L362 contract: the STRENGTHEN was applied to the BD-178-canonicalized HEAD form (named list `git rm`, `rm -rf`, file deletion, overwrite, `git reset --hard`), NOT V1's pre-BD-178 recorded BEFORE text. Verified §2.5 above.

### 6.4 — Other Batch 19c commits untouched

Per PLAN H.4 scope: this commit applies ONLY §C.6 trinity half. The Batch 19c commits H.0 (baseline), H.1 (METHODOLOGY workflow callouts), H.2 (PM-CHAT.md behavioral rules), H.3 (PM-CHAT.md STRENGTHEN), H.5+ (METHODOLOGY substantive additions and beyond) are not in H.4's scope. They have separate planned commits.

### 6.5 — Per-commit reviewer INLINE (sliding-window) is Pack Chat's responsibility

PLAN H.4 L235-240 declares per-commit reviewer REQUIRED INLINE on this commit (first INLINE reviewer of Batch 19c, sliding-window scope H.0 → H.4 covering 4 commits). This is Pack Chat's responsibility (spawn pack-reviewer post-coder); the coder does not invoke the reviewer. Surfaced here for Pack Chat awareness.

### 6.6 — Forbidden git verbs not invoked

No state-changing git verbs executed during this session. Only read-only verbs (`git rev-parse`, `git status`, `git diff`) were used.

---

## §7 Open questions / deferrals

**None.**

The H.4 commit is fully scoped by V2 §C.6 + PLAN H.4. No new POQs encountered; no architectural ambiguity surfaced during execution. The spec was unambiguous (V2 §C.6 AFTER text was given verbatim; insertion anchors verified mechanically). No deferrals introduced.

---

## §8 Files changed inventory

| Path | Change type | In-scope? | Reason |
|------|-------------|-----------|--------|
| `project-template/CLAUDE.md` | Modified | Yes (H.4) | Trinity STRENGTHEN per V2 §C.6 |
| `project-template/AGENTS.md` | Modified | Yes (H.4) | Trinity STRENGTHEN per V2 §C.6 |
| `project-template/GEMINI.md` | Modified | Yes (H.4) | Trinity STRENGTHEN per V2 §C.6 |
| `test-fixtures/manifest.txt` | Modified | Yes (H.4 RC9) | v11-* fixture row drift from trinity edits |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.4.md` | New | Yes (H.4 IMPL-REPORT) | This file |
| `maintenance-docs/v11-research/EXTERNAL-RESEARCH.md` | Modified | NO (sibling chat) | Pre-existing; not touched by H.4 |
| `maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md` | Modified | NO (sibling chat) | Pre-existing; not touched by H.4 |
| `maintenance-docs/v11-research/HANDOFF-V11.1-ARCHITECT.md` | Untracked | NO (sibling chat) | Pre-existing untracked; not touched by H.4 |

**In-scope files for Pack Chat to stage in the H.4 commit:**
1. `project-template/CLAUDE.md`
2. `project-template/AGENTS.md`
3. `project-template/GEMINI.md`
4. `test-fixtures/manifest.txt`
5. `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.4.md`

The three `maintenance-docs/v11-research/` files (2 modified + 1 untracked) are sibling-chat work and MUST NOT be staged as part of H.4.

---

## §9 Plan deviations

**Zero deviations.** Every step of PLAN H.4 was executed mechanically per spec:
- Step 1 (read current HEAD form) → done (§2.5)
- Step 2 (apply STRENGTHEN to CLAUDE.md) → done (§2.2)
- Step 3 (apply STRENGTHEN to AGENTS.md) → done (§2.3)
- Step 4 (apply STRENGTHEN to GEMINI.md) → done (§2.4)
- Step 5 (verify cross-CLI parity / Override 9 non-applicability) → done (§3.4, §2.6)
- Verification commands per L222-231 → all run and PASS (§3.1, §3.2, §3.3, §3.4)
- RC9 manifest regen → done; left unstaged (§3.3)
- PREFLIGHT line emitted before this IMPL-REPORT write → done

One environmental note: the prompt anticipated HEAD `6753f59`, but actual HEAD at session start was `bfa3a3317b8aecbee09fbd18c17449edc2effa56`. This is expected drift between Pack Chat's prompt construction time and coder spawn time in a multi-chat workflow. The BD-178-canonicalized BEFORE form verified correct at the actual HEAD (§2.5), so the drift does not affect H.4 correctness. The actual HEAD SHA is recorded in the PREFLIGHT line and in this report's header.

---

## §10 Boundary discipline check (P-missed-7)

This commit edits project-side files (`project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md`). Per the pack-coder system prompt's "Boundary discipline pre-flight" section, the SSOT investigation:

**Concept being changed:** Project-side rule about destructive operations requiring explicit approval — applies to ALL project-side agents (Claude Code, Codex, Gemini CLI; PM chat, sub-agents).

**Project-side SSOT investigated:** Project trinity (`project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md`) `## Project memory` section. This IS the correct SSOT for project-side agent behavioral rules — verified by V2 §C.6 L381 D-11 cascade verdict "REFRAME-EXCEPTION" (defense-in-depth retention at trinity). The alternate placement (PM-CHAT.md per D-11 omniscience default) was explicitly rejected by the architect with documented rationale (trinity is the rules-agents-must-respect surface; PM-chat injection would force every agent to receive the rule by injection, more brittle than reading from trinity at session start).

**Pack-only-reference check:** The added text contains no pack-only references. Specifically NOT present:
- No mention of `pack-ops/PACK-AGENTS.md`, `pack-ops/PACK-CHAT.md`, or any `pack-ops/` path
- No mention of `maintenance-docs/`
- No `pack-*` agent names (no `pack-coder`, no `pack-reviewer`, etc.)
- No capitalized "Pack Chat" orchestrator role
- Generic "coder-written changes" / "agent work" language is correct — these are project-side abstractions

**Result:** Boundary discipline check PASS. The edit is project-side-correct; SSOT investigation confirms trinity is the appropriate surface; no pack-only contamination introduced. Validate-pack.py Check 37 (project-side pack-only deny-list) PASSED (146 project-side files walked; zero deny-list contamination per §3.1).

---

## §11 Definition-of-Done checklist

| Item | Status | Evidence |
|------|--------|----------|
| Pre-flight: `git rev-parse HEAD` + `git status` + spec file existence | PASS | Session-start checks |
| All 3 trinity files modified with V2 §C.6 AFTER text | PASS | §2.2-§2.4 |
| Byte-identical trinity parity verified | PASS | §3.4 |
| BD-178-canonicalized baseline (not pre-BD-178) | PASS | §2.5 |
| Override 9 non-applicability documented + verified | PASS | §2.6, §3.4 |
| `validate-pack.py` PASS (incl. Checks 16/18/19) | PASS | §3.1 |
| Fixture rebuild + manifest drift expected pattern | PASS | §3.2, §3.3 |
| Manifest left unstaged (Pack Chat will stage) | PASS | §3.3 |
| No forbidden git verbs invoked | PASS | §6.6 |
| Out-of-scope files untouched | PASS | §3.5, §6.1 |
| Pack-root trinity untouched (H.15 scope) | PASS | §6.2 |
| Trinity rule respected (parallel edits in same session) | PASS | All three trinity files edited; §3.4 byte-identical verified |
| Boundary discipline check (P-missed-7) | PASS | §10 |
| Zero plan deviations | PASS | §9 |
| Zero new POQs | PASS | §7 |
| IMPL-REPORT written to specified path | PASS | This file |
| PREFLIGHT line emitted before IMPL-REPORT write | PASS | Pre-Write console output |

All Definition-of-Done items PASS. H.4 implementation complete; ready for Pack Chat to stage and commit per PLAN L244 commit message.
