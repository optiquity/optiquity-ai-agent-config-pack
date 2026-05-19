# PACK-REVIEW — BD-175 Phase 5 Commit 8 (TASK-T6 METHODOLOGY REPLACE, A2)

**Reviewer:** pack-reviewer (per-commit cycle, ALPHA-EXPANDED parallel batch)
**Date:** 2026-05-19
**Scope under review:** `4120d19` (Commit 8: TASK-T6 METHODOLOGY REPLACE) + `6c48f88` (manifest-regen fix) + `e0dfa8e` (BD-176 scope expansion). Treated as ONE per-commit cycle because the manifest fix is the unavoidable CI-recovery half of Commit 8 and the BD-176 expansion captures the surfaced rule-spec gap.
**HEAD at review:** `e0dfa8e` (BD-176 expansion already in)
**Read-only:** YES (no source edits; no state-changing git verbs invoked)
**Inputs consulted:** `PLAN-BD-175-PHASE-5.md` §2.8; `ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md` §4 A2; `IMPLEMENTATION-REPORT-BD-175-COMMIT-8.md`; `supporting-docs/METHODOLOGY.md` @ HEAD; `test-fixtures/manifest.txt` @ HEAD; `pack-ops/BACKLOG.md` BD-176 entry; commit messages for `4120d19` / `6c48f88` / `e0dfa8e`; `gh run list` CI history. No prior PACK-REVIEW-*.md reports consulted per pack-memory.

---

## §0 — GO/NO-GO for next commit (Commit 9a)

**Verdict: GO.**

All A2 functional verifications PASS, manifest is restored to the three correct v11-* SHAs (d409ff7f8f / e522d9b424 / fe4c1d5bdf), CI on `e0dfa8e` is `success`, and BD-176 is expanded with precedent recorded. Commit 9a (TASK-T5 MERGE-STRATEGY audience-header in `pack-ops/MERGE-STRATEGY.md`) is unblocked. No blocker- or MUST-class defects found in Commit 8's executed scope. The CI failure on `4120d19` is classified as a rule-spec process gap (RC9 false-negative), not a coder defect — see §2.

---

## §1 — Per-check verdicts

### Check 1 — A2 L1509 REPLACE applied correctly

**PASS.**

- `grep -n "maintenance-docs/" supporting-docs/METHODOLOGY.md` → **zero hits** (exit 1, no output). Confirms the pack-internal path was removed.
- `grep -n "Claude-Assisted Project Methodology Guide v1" supporting-docs/METHODOLOGY.md` → **exactly 1 hit** at `1509:*Source: Claude-Assisted Project Methodology Guide v1 (pack-archived design source)*`. Attribution preserved with the post-edit phrasing per Architect §4 A2 recommendation.
- Spot-read of `supporting-docs/METHODOLOGY.md:1505-1511` confirms the three-line italic footer rhythm (version / source / maintenance note) is intact and reads cleanly at a client repo where the `maintenance-docs/` tree does not exist.
- `git diff 4120d19~1..4120d19 -- supporting-docs/METHODOLOGY.md` shows precisely the BEFORE→AFTER replacement at L1509 with one line removed and one added; surrounding context untouched.

The edit matches Architect A's §4 A2 recommended REPLACE wording verbatim and the Plan §2.8.2 EXACT EDIT spec verbatim.

### Check 2 — Manifest correctness post-fix

**PASS.**

`test-fixtures/manifest.txt` @ HEAD `e0dfa8e`:

| Fixture | SHA at HEAD | Expected (per spawn prompt) | Match |
|---|---|---|---|
| `v11-realistic-ot` | `d409ff7f8fb256db1948da1f35e65c832ba6637b` | `d409ff7f8f...` | YES |
| `v11-flat-file` | `e522d9b424a2db43aaa01e2148372f2b9c62a62b` | `e522d9b424...` | YES |
| `v11-tracker-on` | `fe4c1d5bdf7167b30636a05ad0c376424a65c684` | `fe4c1d5bdf...` | YES |
| `v10-minimal` | `19558cbac5...` | unchanged (tag-pinned) | preserved |
| `v10-realistic-ot` | `4c62945f72...` | unchanged (tag-pinned) | preserved |
| `existing-project-mid-dev` | `a54e081a9e...` | unchanged | preserved |

The manifest-fix commit `6c48f88` updated only the three v11-* lines (3 insertions / 3 deletions); v10-* and existing-project-mid-dev rows correctly preserved (they do not capture METHODOLOGY.md install).

CI confirms: run for `6c48f88` is `conclusion=success` (the `fixture manifest verify` step is back to green).

### Check 3 — Original Commit 8 + fix-commit progression

**PASS.**

- `git log --oneline 4120d19~..6c48f88` returns exactly 2 commits in order:
  - `4120d19` "feat: v11 — BD-175 TASK-T6 METHODOLOGY REPLACE (A2)"
  - `6c48f88` "fix: v11 — BD-175 Commit 8 manifest regen (METHODOLOGY.md is client-installed)"
- Commit message for `4120d19` correctly states **"NOT v11-surface (supporting-docs/) — no manifest regen per RC9."** This was the *correct* statement under the current RC9 rule wording (RC9 says "v11-surface = files under `project-template/` or `scripts/`"); it did not falsely claim a regen had happened. The rule itself was the trigger for the false-negative.
- The fix commit's `fix:` suffix is approved per `CLAUDE.md` § "Approved suffixes for the `fix:` form" (per-BD inline fix in current batch). Form: `fix: vN — BD-NNN brief description`. No invented commit shape.
- Per `CLAUDE.md` git safety protocol the fix landed as a NEW commit rather than amending `4120d19`. Correct.

### Check 4 — BD-176 scope expansion

**PASS.**

- BD-176 title at `pack-ops/BACKLOG.md:1419` now reads:
  > "BD-176 — Expand RC9 manifest-regen trigger to cover all fixture-affecting surfaces (pack-ops/ + supporting-docs/install-to-client files)"
  
  Title accurately reflects the expanded scope.
- `Unblocks` list at L1423-1425 enumerates both classes as separate bullets:
  - (a) defensive future-proofing for pack-ops/ additions
  - (b) confirmed false-negative for supporting-docs/install-to-client files (METHODOLOGY.md cited explicitly with `init-project.sh:565-570` anchor)
- Description body at L1430-1438 splits into bolded subsections **(a) pack-ops/ (defensive, currently empirical zero-impact)** and **(b) supporting-docs/ files that install to clients (CONFIRMED FALSE-NEGATIVE — CI failure 2026-05-19)**; the (b) subsection cites `4120d19` and recovery commit `6c48f88` as precedent.
- The "Note: not ALL supporting-docs/ files install to clients" qualifier at L1436 correctly distinguishes METHODOLOGY.md + INSTALL-PROCEDURES.md (install) vs MIGRATION-v10-to-v11.md (no install), preserving the install-to-client subset framing for the architect spawn.
- `Type:` line at L1420 records "SCOPE EXPANDED 2026-05-19 during BD-175 Phase 5 Commit 8 CI failure" — the expansion provenance is auditable.
- Implementation pattern (L1446) correctly routes through `pack-architect` spawn per the pack-memory pack-architect-spawn protocol (RC9 is a Pack-memory trinity rule).
- Position (L1448) remains "immediately after BD-175" per user direction.

### Check 5 — Trinity rule

**N/A.** No trinity files (`project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md`, nor pack-root copies) touched in any of the three commits under review. The IMPL-REPORT also notes "Trinity rule N/A" in §6. Confirmed by inspection of `git diff --stat` for all three commits.

### Check 6 — Cross-reference integrity

**PASS.**

- The only live cross-reference impacted is the citation prose itself, which is now self-contained ("Claude-Assisted Project Methodology Guide v1 (pack-archived design source)") and does not point at any pack path. No dangling reference to the deleted `maintenance-docs/origins/...` path was found elsewhere in the pack via spot-check.
- The IMPL-REPORT's §2 BEFORE/AFTER and §3 verification table line numbers match the actual file state at HEAD.
- The pack-memory bullet in `CLAUDE.md` § "Regenerate test-fixtures/manifest.txt on every v11-surface commit" still describes the *current* RC9 rule (v11-surface = `project-template/` or `scripts/`) — correctly *not* edited by this batch, because the rule update belongs to BD-176 (architect-pass). No stale reference introduced.

### Check 7 — IMPL-REPORT integrity

**PASS.**

The IMPL-REPORT at `IMPLEMENTATION-REPORT-BD-175-COMMIT-8.md`:
- Records `Final worktree HEAD = 21c134443aab...` (parent commit of `4120d19`) — consistent with "agents never commit" rule.
- §3 verification table shows 6 PASS rows with concrete commands and results.
- §4 Plan deviations: NONE (correct — see §2 below for why this is true *despite* the CI failure).
- §5 PREFLIGHT line is present in the report (the in-band line was emitted to parent before the report write).
- §7 file-changes inventory correctly lists 1 in-scope modification + the report artifact itself.

No coder defect surfaces in the IMPL-REPORT. The V6 row explicitly states "Skip per RC9 base case — `supporting-docs/` not v11-surface" — this is the coder honestly applying the rule as written, which is the desired behavior of a mechanical coder.

---

## §2 — Defect classification

**Defect-class summary: 0 BLOCKER, 0 MUST, 0 SHOULD, 0 NIT against the executed scope.**

The CI failure on `4120d19` is a **process gap**, not a coder defect. Specifically:

- **Coder behavior was correct.** The pack-coder applied Architect §4 A2 and Plan §2.8 verbatim, including Plan §2.8.4's explicit "NO manifest regen check" and Plan §2.8.2's "NONE — supporting-docs/ is NOT v11-surface per RC9 base case." A mechanical coder that contradicted the plan would itself be a defect.
- **Planner behavior was correct against the rule as written.** Plan §2.8 follows RC9's literal trigger ("v11-surface = files under `project-template/` or `scripts/`") to conclude no regen is needed. The empirical fact that METHODOLOGY.md gets installed to clients via `init-project.sh:565-570` and therefore captures into v11-* fixture SHAs is *not* encoded in RC9.
- **The defect lives in RC9 itself** (the `CLAUDE.md` § "Regenerate test-fixtures/manifest.txt on every v11-surface commit" bullet trigger glob). It is now captured in BD-176 (b) with the 2026-05-19 incident as precedent and an architect-pass routing in place.
- **Recovery was clean.** `6c48f88` landed as a separate NEW `fix:` commit per `CLAUDE.md` git safety protocol; pack-memory RC9 inline-fix pattern honored; manifest now matches CI expectations. CI on `6c48f88` is `conclusion=success`.

**Per the spawn prompt's classification guidance: NOT a coder deviation; rule-spec gap captured by BD-176.** I concur.

**Triage recommendations for Pack Chat (FIX-ALL default per user policy):**

There is nothing to fix in the executed scope of Commit 8. The rule-spec gap is already routed to BD-176 with architect-pass discipline. The only action remaining for this batch is to continue with Commit 9a per the plan; the RC9 trigger expansion will land post-BD-175 per user direction.

One forward-looking observation (NOT a finding against Commit 8 — flagged for Pack Chat awareness, not blocking):

- **Forward-watch (informational).** Commit 7 (TASK-T4 MIGRATION-v10-to-v11.md) was the immediately-prior commit in this batch and is also a `supporting-docs/` edit. Per the BD-176 note at L1436, `MIGRATION-v10-to-v11.md` does NOT install to clients, so the current RC9 rule was a true-negative for Commit 7 (no manifest drift expected). This is consistent with no CI failure between Commit 7 and Commit 8. No retro action required, but a useful confirmation that the (b) class is specifically *install-to-client* supporting-docs files, not all supporting-docs files.

---

## §3 — BD-176 scope expansion verification

Already covered in §1 Check 4 (PASS). Summary of expansion completeness for the prompt's success criteria:

| Requirement | Status |
|---|---|
| BD-176 entry now lists supporting-docs/install-to-client class as a separate (b) bullet | YES — L1425 and L1434 |
| BD-176 title reflects expanded scope ("cover all fixture-affecting surfaces") | YES — L1419 |
| 2026-05-19 BD-175 Commit 8 incident cited as precedent for the (b) class | YES — L1434, L1442 |
| install-to-client subset qualifier (METHODOLOGY.md and INSTALL-PROCEDURES.md install; MIGRATION-v10-to-v11.md does not) | YES — L1436 |
| Architect-pass routing per pack-memory pack-architect-spawn protocol | YES — L1446 |
| Trinity-rule scope flagged (RC9 lives in the three pack-root CLI files) | YES — L1427 |
| User-memory cache file flagged for sync (feedback_manifest_regen_on_v11_surface.md) | YES — L1428 |
| Position retained at immediately-after-BD-175 | YES — L1448 |

The expansion is complete and architect-pass-ready. No additional BD-176 edits required from this review.

---

## §4 — PREFLIGHT

I read but did not modify any source file. I wrote exactly one file: this report at the prompt-specified path `maintenance-docs/v11-implementation/PACK-REVIEW-BD-175-COMMIT-8.md`. No state-changing git verbs invoked. No solutions or implementation work performed; findings only.

**PREFLIGHT: per-commit review complete; verdict GO for Commit 9a; HEAD at review e0dfa8e; report written to maintenance-docs/v11-implementation/PACK-REVIEW-BD-175-COMMIT-8.md.**
