# IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-19b-4 — EXECUTION-PLAN-V11.0.md §B FULL REPLACEMENT (OQ-1)

**Author:** pack-coder (commit 19b-4 of Batch 19b cleanup)
**Date:** 2026-05-17
**Branch:** v11-dev
**HEAD at start:** `35585253002d75a99b2b17ac1982528e87bd7d1a`
**HEAD at end:** `35585253002d75a99b2b17ac1982528e87bd7d1a` (no commits in this session — agents never commit)
**Scope:** Single-file replacement of EXECUTION-PLAN-V11.0.md `### B. Audit / review-fix protocol` section.
**Source-of-truth driver docs:**
- `maintenance-docs/v11-implementation/PLAN-CLEANUP-BATCH-19B.md` §1 (table line 51) + §2 19b-4 detail (lines 191-258)
- `maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19B-V2.md` §B PC-1 row (lines 149-203) + §B PC-3 row (lines 225-233)

---

## §1 — Summary

Per the binding §1-table row for commit 19b-4 and the planner §2 detail, EXECUTION-PLAN-V11.0.md §B has been FULLY REPLACED. The replacement substitutes the V2 architect's PC-1 §B rewrite (which absorbs and supersedes the pre-existing flat "No new BDs are opened" rule with a six-step protocol expressing OQ-1's fix-now-default-plus-discussion-and-approval-for-new-BDs nuance), plus the PC-3 audit-IS-the-review clarification folded into step 4 per V2 PC-3 row instruction, plus the planner's L.6 forward-only paragraph appended at the end per L.6 binding decision.

- **Pre-edit §B span:** lines 331-355 (heading + 5 numbered items + closing "BDs are reserved..." paragraph)
- **Post-edit §B span:** lines 331-381 (heading + 6 numbered items + Historical context paragraph + OQ-1 scope paragraph)
- **File line count:** 465 → 491 (+26 lines net)
- **Files modified:** 1 (`maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md`)
- **Files outside scope touched:** 0
- **v11-surface manifest regen:** NOT NEEDED. EXECUTION-PLAN-V11.0.md is under `maintenance-docs/` which is NOT v11-surface per the RC9 rule (`project-template/` and `scripts/` only). Verified via `git diff --name-only` on both globs returning empty.

The PC-3 fold-in structure: V2 §B PC-3 (line 231) explicitly instructs `Append to step 4 of the replacement §B: "An audit pass IS the review for that batch; no separate pack-reviewer is run on the audit-fix commit."` The planner correctly interpreted and pre-assembled this in PLAN-CLEANUP-BATCH-19B.md §2 (lines 218-219). The coder applied the planner's pre-assembled text, which exactly matches V2's instruction. No fresh structural decision was needed — the V2 architect chose to fold PC-3 inline within PC-1's step 4, not as a separate sub-section.

Verification: `python3 scripts/validate-pack.py` PASS (all checks 1-35 green); baseline tests `test-persona-contracts.sh` PASS (3/3 personas) and `tracker-config-test.sh` PASS (32/32 cases).

---

## §2 — Pre-edit §B content (lines 331-355 verbatim)

```
### B. Audit / review-fix protocol (user rule, 2026-05-11)

1. Every audit/review pass that produces findings is fixed *in the
   current session*. No fix-follow BDs are opened.

2. Pack Chat reports the findings to the user (severity-grouped),
   presents fix options per finding (including NITs), and asks
   permission to fix. Pack Chat does not start the fixes before
   approval.

3. With user approval, Pack Chat ships the fixes in the same batch's
   commit, or in a small follow-up commit Pack Chat proposes and the
   user approves.

4. After review fixes land and validator/CI is clean, status flips
   per the implicit-flip rule (§C.4).

5. If review surfaces defects beyond the audit scope, Pack Chat
   surfaces them to the user as findings — without proposing a BD
   or asking whether to open one. The user alone decides whether
   a defect becomes a BD.

**BDs are reserved for new scope, new features, and new architecture —
never for closing audit findings. Only the user can initiate a
BD-for-fix conversation; Pack Chat must not propose one.**
```

Line span: 331-355 (25 lines total, inclusive of heading + 5 numbered items + closing paragraph). End-of-section marker: blank line at 356, then `### C. Agent / commit lifecycle` at 357.

---

## §3 — Post-edit §B content (lines 331-381 verbatim — actual file contents)

```
### B. Audit / review-fix protocol (user rule, 2026-05-11; revised 2026-05-16 per OQ-1)

1. Every audit/review pass that produces findings is FIX-NOW by default
   in the current session. Pack Chat does not propose deferral (per
   `feedback-deferral-is-scope-creep` in `## Pack memory`).

2. Pack Chat reports findings to the user (severity-grouped: MUST /
   SHOULD / NIT), presents a fix-vs-skip triage per finding (with
   rationale for SKIPs), and waits for triage approval. Per
   `feedback-pack-chat-does-no-fixes`, Pack Chat does NOT apply the
   fixes itself — a fix-coder agent does, running in the background
   after user approves the triage.

3. With user approval, fix-coder lands the fixes in the same batch's
   commit, or in a small follow-up commit Pack Chat proposes and the
   user approves.

4. After review fixes land and validator/CI is clean, status flips
   per the implicit-flip rule (§C.4). An audit pass IS the review for
   that batch; no separate pack-reviewer is run on the audit-fix commit.

5. **New-BD-opens require user-discussion-and-approval.** When a
   review/audit finding might warrant a new BD, Pack Chat surfaces the
   finding AND its candidacy for a new BD to the user — but does NOT
   open the BD. New BDs are opened only when (a) the work is too large
   for in-place fix (architect-pass material), (b) blocked by a
   not-yet-landed dependency, or (c) belongs cleanly with an existing
   BD (in which case the existing BD is EDITED, not a new one opened).
   In all three cases, user discussion and approval is required before
   any BD is opened or edited. Pack Chat must not pre-frame "should we
   open a BD?" as a default choice — the default remains fix-now.

6. If a new BD IS opened with user approval per (5), it is inserted
   IMMEDIATELY AFTER the current BD or batch (unblocked) or at the
   unblock point (blocked) — never parked at the end of v11.0, never
   "next batch" with no anchor.

**Historical context:** the prior §B text (pre-2026-05-16) said "No
new BDs are opened for audit findings" as a flat rule. Per the
`feedback-deferral-is-scope-creep` memory revision, the rule narrowed:
unblocked-new-scope from audits DOES open a BD inserted-immediately-
after. Per the OQ-1 nuance (2026-05-16), the new-BD-open additionally
requires user-discussion-and-approval. Together: fix-now default; new
BDs are an exception requiring (size or block or fit) AND user
approval.

**OQ-1 scope (per L.6 forward-only decision, 2026-05-16):** this
revised §B applies to items surfaced AFTER the rewrite commit lands.
Items already triaged under the prior §B (e.g., Batches 1-19, Batch
19h status-flip review) stay under their original triage; the
new "user-discussion-and-approval" clause is not retroactive.
```

Line span: 331-381 (51 lines total, inclusive of heading + 6 numbered items + Historical context paragraph + OQ-1 scope paragraph). End-of-section marker: blank line at 382, then `### C. Agent / commit lifecycle` at 383.

---

## §4 — V2 §B PC-1 + PC-3 fidelity verification

### §4.1 — PC-1 fidelity (V2 §B lines 156-201)

The V2 architect's PC-1 §B replacement text is reproduced verbatim from V2 lines 156-201 (the fenced block opening at line 156 with `### B. Audit / review-fix protocol (user rule, 2026-05-11; revised 2026-05-16 per OQ-1)` and closing at line 201).

**Byte-level fidelity check of post-edit §B (file lines 331-381) vs V2 §B PC-1 fenced block (V2 lines 156-201):**

- **Heading (file 331 vs V2 157):** IDENTICAL — `### B. Audit / review-fix protocol (user rule, 2026-05-11; revised 2026-05-16 per OQ-1)`
- **Step 1 (file 333-335 vs V2 159-161):** IDENTICAL
- **Step 2 (file 337-342 vs V2 163-168):** IDENTICAL
- **Step 3 (file 344-346 vs V2 170-172):** IDENTICAL
- **Step 4 (file 348-350 vs V2 174-175 + PC-3 appended sentence per V2 line 231):** Step 4 in the V2 PC-1 fenced block reads:
  ```
  4. After review fixes land and validator/CI is clean, status flips
     per the implicit-flip rule (§C.4).
  ```
  Post-edit step 4 includes the PC-3-appended sentence (per V2 PC-3 row line 231 explicit instruction: `Append to step 4 of the replacement §B: An audit pass IS the review for that batch; no separate pack-reviewer is run on the audit-fix commit.`). The planner's pre-assembled text at PLAN line 218-219 correctly performs this append. Coder applied as instructed. PC-3 fold-in fidelity: VERBATIM per V2 PC-3 row.
- **Step 5 (file 352-361 vs V2 177-186):** IDENTICAL
- **Step 6 (file 363-366 vs V2 188-191):** IDENTICAL
- **Historical context paragraph (file 368-375 vs V2 193-200):** IDENTICAL
- **OQ-1 scope paragraph (file 377-381):** This paragraph is NOT in the V2 §B PC-1 fenced block. It is the planner's addition per L.6 binding decision (PLAN line 256-257: `L.6 forward-only fold: the closing "OQ-1 scope" paragraph above is the planner's addition per L.6 binding decision (architect's V2 §L.6 surfaced the question; L.6 binding answer is forward-only).`) The planner's pre-assembled text in PLAN §2 (lines 246-250) is the source. Coder applied as instructed. Fidelity: VERBATIM per PLAN-CLEANUP-BATCH-19B.md §2.

### §4.2 — PC-3 fold-in structure decision

V2 PC-3 row (lines 225-233) was unambiguous about fold-in structure:

> **Action:** Add one clarifying sentence inside the rewritten §B (PC-1) step 4.
>
> **Specific text (already folded into the PC-1 §B replacement above, but isolating the addition here):**
>
> Append to step 4 of the replacement §B: `An audit pass IS the review for that batch; no separate pack-reviewer is run on the audit-fix commit.`
>
> This goes inside the same §B rewrite as PC-1.

The V2 architect's instruction left no structural ambiguity:
- **PC-3 is NOT a separate sub-section** within §B
- **PC-3 IS a one-sentence append** to PC-1's step 4
- The V2 architect's own fenced block at line 174-175 omits the PC-3 sentence; the PC-3 row at line 231 names the precise append point

The planner correctly interpreted this (PLAN line 218-219) and pre-assembled the merged step-4 text. Coder applied the planner's pre-assembled text. Structural decision: no coder discretion exercised — the V2 architect's instruction was binding.

### §4.3 — Ambiguity / open-question flags

- **No PC-1 ambiguities.** The V2 PC-1 fenced block is self-contained; the AFTER text is the complete replacement; the BEFORE text is identified by line range (V2 PC-1 row line 151: "EXECUTION-PLAN-V11.0.md lines 331-355"). Coder verified pre-edit content matched the V2 BEFORE description.
- **No PC-3 ambiguities.** V2 PC-3 row line 231 names the exact append point ("step 4 of the replacement §B") and exact text. The planner's pre-assembled merge is the obvious mechanical execution.
- **L.6 OQ-1-scope paragraph is planner-added, not architect-original.** The closing "OQ-1 scope" paragraph (post-edit file lines 377-381) is NOT in the V2 architect's PC-1 fenced block. It is the planner's L.6 binding-decision-derived addition per PLAN §2 lines 256-257. PLAN line 257 explicitly states: `The V2 architect doc does not propose this exact wording but does propose forward-only as architect recommendation in §L.6.` The coder applied the planner's text per the planner's L.6 binding decision (which the architect surfaced as L.6 and the user resolved as "forward-only" per binding decisions cited at PLAN line 10). This is the planner doing planner-work (sequencing + boundaries + binding-decision-honoring), not architect-work — Pack Chat should be aware this paragraph traces to planner+L.6-binding, not directly to V2 §B PC-1 AFTER text.

---

## §5 — Verification evidence

### §5.1 — `python3 scripts/validate-pack.py` (final 20 lines)

```
  OK: Skill-cell consistency: 35 SKILL.md on disk, all map to exactly one inventory cell; no orphans, phantoms, or double-counts

── Check 32: per-entry mirror is in-sync with per-entry tree (BD-168) ──
  OK: backlog/ — not present (skipping; pre-v11.0 client or pre-BD-102 dog-food pack-self per integration parent §10.5)
  OK: changelog/ — not present (skipping; pre-v11.0 client or pre-BD-102 dog-food pack-self per integration parent §10.5)

── Check 33: per-entry _toc.md is in-sync with per-entry tree (BD-168) ──
  OK: backlog/ — not present (skipping; pre-v11.0 client or pre-BD-102 dog-food pack-self per integration parent §10.5)
  OK: changelog/ — not present (skipping; pre-v11.0 client or pre-BD-102 dog-food pack-self per integration parent §10.5)

── Check 34: cross-reference integrity (BD-168) ──
  OK: no per-entry trees present (skipping; pre-v11.0 client or pre-BD-102 dog-food pack-self per integration parent §10.5)

── Check 35: Phase-task lib invariants (BD-106) ──
  OK: scripts/lib/tracker-phase-task.sh present
  OK: scripts/lib/tracker-labels.sh — no tracker_labels_folded_into helper definition (Path 3 forbidden)
  OK: scripts/lib/ — no `folded-into` literal in executable code (V3.3 §3 line 27); comment-only references allowed

============================================================
PASSED — all checks clean
```

Verdict: PASS.

### §5.2 — `test-persona-contracts.sh` (final lines)

```
  PASS v11 artifact docs/project/changelog/_rules.md installed by migrator
  PASS v11 artifact docs/project/changelog/_intro.md installed by migrator
  PASS v11 artifact docs/project/changelog/_format.md installed by migrator
  PASS all .github/ISSUE_TEMPLATE/*.yml installed by migrator

=== migration contract: 37 passed, 0 failed ===

============================================================
Persona contract summary: 3/3 passed
  PASS:
    - contract-greenfield.sh
    - contract-mid-dev.sh
    - contract-migration.sh

All persona contracts PASS.
```

Verdict: PASS. Three personas (greenfield, mid-dev, migration) all green; the embedded migration sub-suite is 37/37.

### §5.3 — `tracker-config-test.sh` (final lines)

```
=== Group 3: schema_version + dispatcher integration ===
  PASS 3.1 schema_version_check pass on schema_version=1
  PASS 3.2 schema_version_check on schema_version=99 → validation
  PASS 3.2 schema_version_check error names actual version
  PASS 3.3 schema_version_check missing key → validation
  PASS 3.4a no env var → github (default)
  PASS 3.4b _TRACKER_PROVIDER_CONFIG_PATH set → backend.name=stub
  PASS 3.4c override wins absolutely
  PASS 3.5 missing config file → github fallback

=== Summary ===
Passed: 32
Failed: 0
All tests passed.
```

Verdict: PASS. 32/32 cases.

### §5.4 — `wc -l` EXECUTION-PLAN-V11.0.md before vs after

- **Before edit:** 465 lines (per earlier read)
- **After edit:** 491 lines
- **Delta:** +26 lines net (replaced 25-line §B with 51-line §B)

The growth is dominated by:
- Step 5 (new) — 10 lines
- Step 6 (new) — 4 lines
- Historical context paragraph (new) — 8 lines
- OQ-1 scope paragraph (new) — 5 lines
- PC-3 fold sentence appended to step 4 — 2 lines
- Net offset by removed pre-edit step 5 (4 lines) and pre-edit closing "BDs are reserved..." paragraph (3 lines)

---

## §6 — Out-of-scope check

`git status --short` immediately after edit:

```
 M maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md
?? maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19B-MANIFEST-REGEN-RULE.md
?? maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19B-V2.md
?? maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19B.md
?? maintenance-docs/v11-implementation/CLEANUP-INPUTS-SESSION-RULES.md
?? maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-19b-1.md
?? maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-19b-2-RC9.md
?? maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-19b-2.md
?? maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-19b-3.md
?? maintenance-docs/v11-implementation/PACK-REVIEW-CLEANUP-BATCH-19B-19b-1.md
?? maintenance-docs/v11-implementation/PACK-REVIEW-CLEANUP-BATCH-19B-19b-2-RC9.md
?? maintenance-docs/v11-implementation/PACK-REVIEW-CLEANUP-BATCH-19B-19b-2.md
?? maintenance-docs/v11-implementation/PLAN-CLEANUP-BATCH-19B.md
?? maintenance-docs/v11-implementation/RESEARCH-CLEANUP-BATCH-19B-CROSS-CLI.md
```

`git diff --name-only`:
```
maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md
```

- **Single modified (M) file:** `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md` — the only authorized scope per the §1 table row 19b-4
- **14 untracked (??) files:** ALL are pre-existing maintenance-docs from prior 19b commits or earlier preparatory work (CLEANUP-INPUTS-SESSION-RULES, both ARCHITECTURE-CLEANUP-BATCH-19B docs, PLAN-CLEANUP-BATCH-19B, RESEARCH-CLEANUP-BATCH-19B-CROSS-CLI, the manifest-regen-rule architect doc from 19b-2-RC9, plus PACK-REVIEW and IMPL-REPORT artifacts from 19b-1 / 19b-2 / 19b-2-RC9 / 19b-3). None were created or modified by this coder session. They will be archived in 19b-7 per PLAN §1 table.
- **No deletions, no renames, no new files created during the edit phase** (this IMPL-REPORT file is the only new file from this session and is the final write).

Verdict: out-of-scope check PASS — exactly one in-scope file modified, zero out-of-scope edits.

---

## §7 — RC9 recursive base case verification

Per the RC9 rule established in 19b-2-RC9 (architect doc `ARCHITECTURE-CLEANUP-BATCH-19B-MANIFEST-REGEN-RULE.md`), manifest regen is required only when v11-surface files (`project-template/` or `scripts/`) are modified.

```
--- project-template/ glob ---
(empty)
--- scripts/ glob ---
(empty)
--- end ---
```

Both globs returned empty: `git diff --name-only -- 'project-template/'` and `git diff --name-only -- 'scripts/'` both produce zero output. EXECUTION-PLAN-V11.0.md lives at `maintenance-docs/v11-implementation/` which is OUTSIDE the v11-surface globs.

Verdict: RC9 recursive base case satisfied. Manifest regen is NOT needed for this commit.

---

## §8 — Coder flags / open questions for Pack Chat

### §8.1 — L.6 OQ-1-scope paragraph traces to planner+L.6 binding, not V2 architect text

The closing "OQ-1 scope (per L.6 forward-only decision, 2026-05-16)" paragraph at post-edit file lines 377-381 is the planner's addition derived from the L.6 binding decision (PLAN §1 line 10: `L.6 OQ-1 forward-only`). The V2 architect's PC-1 fenced block does NOT contain this paragraph; the planner added it per PLAN §2 lines 256-257 with explicit note: `The V2 architect doc does not propose this exact wording but does propose forward-only as architect recommendation in §L.6.`

The coder applied the planner's pre-assembled text per the planner's L.6 binding interpretation. This is normal planner-work (binding-decision-honoring during plan assembly) and not a coder deviation, but Pack Chat may wish to verify the L.6 forward-only wording matches user intent at commit-approval review since this paragraph traces through the planner-binding layer rather than directly to the V2 architect AFTER text.

### §8.2 — No other open questions

The PC-1 + PC-3 fold-in was unambiguous; the §B section boundary was clean (heading at 331, next section heading at 357 pre-edit / 383 post-edit, with blank-line separation preserved); validator and baseline tests all green; no out-of-scope edits.

### §8.3 — No new POQs introduced

This commit raised no new POQs / decisions / blockers beyond the standard L.6 traceability note above.

### §8.4 — No plan deviations

The coder implemented exactly what the planner specified in PLAN §2 19b-4 (lines 191-258). All structural decisions (PC-3 fold into step 4, OQ-1 scope paragraph append) follow the planner's pre-assembled text verbatim. Zero deviations.

---

## Definition-of-Done checklist

| Item | Status | Evidence |
|---|---|---|
| V2 §B PC-1 row read in full | PASS | §4.1 fidelity check below |
| V2 §B PC-3 row read in full | PASS | §4.2 structure decision below |
| Pre-edit §B located and boundaries verified | PASS | §2 pre-edit content; lines 331-355 |
| Full section replacement applied (not inline edit) | PASS | §3 post-edit content; lines 331-381 |
| §B heading preserved (or updated per V2) | PASS | V2 explicitly updated heading to include `; revised 2026-05-16 per OQ-1`; coder applied |
| No edits to §A / §C / §D / any other section | PASS | §6 git diff shows single-file diff confined to §B span |
| No edits to other files | PASS | §6 git status shows only `M EXECUTION-PLAN-V11.0.md` |
| `python3 scripts/validate-pack.py` PASS | PASS | §5.1 tail output: `PASSED — all checks clean` |
| Baseline test spot-check (test-persona-contracts.sh) | PASS | §5.2 tail output: `All persona contracts PASS` |
| Baseline test spot-check (tracker-config-test.sh) | PASS | §5.3 tail output: `All tests passed` |
| RC9 base case satisfied (no v11-surface changes) | PASS | §7 both globs empty |
| Manifest regen NOT performed (per RC9) | PASS | No manifest changes; no script invoked |
| IMPL-REPORT written | PASS | This file |
| Markdown-only report | PASS | No code execution; pure markdown |
| No emojis | PASS | Visual inspection |
| No state-changing git verbs run | PASS | Only `git status`, `git diff`, `git rev-parse` used (all read-only) |
| HEAD unchanged | PASS | §1 — start `35585253...`; end `35585253...` |

All Definition-of-Done items PASS.

---

## Files inventory

| File | Change type | Notes |
|---|---|---|
| `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md` | modified | §B fully replaced (lines 331-355 → 331-381); +26 lines net; no other section touched |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-19b-4.md` | new | This report |

No other files created, deleted, modified, or renamed.

---

End of IMPL-REPORT 19b-4.
