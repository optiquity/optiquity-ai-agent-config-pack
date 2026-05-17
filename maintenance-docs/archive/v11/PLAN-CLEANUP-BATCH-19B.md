# PLAN-CLEANUP-BATCH-19B — Sequenced cleanup work for Batch 19b

**Author:** pack-planner (Batch 19b cleanup)
**Date:** 2026-05-17
**Branch:** v11-dev (HEAD `cd8246c`)
**Ship target:** v11.0
**Scope:** pack-self only (per OQ-3 — no project-template trinity edits)
**Architect input:** `maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19B-V2.md`
**Researcher input:** `maintenance-docs/v11-implementation/RESEARCH-CLEANUP-BATCH-19B-CROSS-CLI.md` (authoritative for per-CLI variant criteria in §3)
**Binding §L decisions:** L.1 INLINE (no BD-173); L.2 Option A (BD-169 wording) + PACK-CHAT action note; L.3 SKIP tightening (accept ~310 lines); L.4 pack-coder script per spec; L.5 pack-coder verifies CONCEPTUAL-REVIEW-METHODOLOGY.md sections; L.6 OQ-1 forward-only.
**Pack-Chat refinement (2026-05-17, binding):** §3 trinity rule enforcement uses bounded per-CLI variant criteria (NOT byte-identical diff). See §3 below.

This plan ingests V2 architect strategy as binding specification. No design decisions are introduced here. The planner's role is sequencing, file-touch boundaries, verification gates, and per-commit review/fix discipline. Per L.4, the script-based memory regen overrides V2 §H.3 "Pack Chat direct" for commit 19b-6.

---

## Summary

**Commits:** 8 (V2 §H proposed 7; planner adds one separation per L.2 action-item and shifts the L.4 script work into pack-coder territory — overall count is 7 substantive commits + 1 final archive commit; numbering stays 19b-1 through 19b-7 with no inserted commit).

**Total files touched (working tree):**
- Commit 19b-1: 3 files (CLAUDE.md, AGENTS.md, GEMINI.md — trinity)
- Commit 19b-2: 1 file (PACK-CHAT.md)
- Commit 19b-3: 1 file (PACK-AGENTS.md)
- Commit 19b-4: 1 file (EXECUTION-PLAN-V11.0.md)
- Commit 19b-5: 1-3 files (CONCEPTUAL-REVIEW-METHODOLOGY.md possibly; V11-15 grep target files — empirically zero non-historical hits per planner pre-check, so likely 0-1 file)
- Commit 19b-6: 30 files (~/.claude/projects/<slug>/memory/MEMORY.md + 29 memory files); script lives in /tmp and is NOT committed
- Commit 19b-7: 4-6 file moves via `git mv` (CLEANUP-INPUTS-SESSION-RULES.md, ARCHITECTURE-CLEANUP-BATCH-19B.md, ARCHITECTURE-CLEANUP-BATCH-19B-V2.md, RESEARCH-CLEANUP-BATCH-19B-CROSS-CLI.md, PLAN-CLEANUP-BATCH-19B.md, plus any IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-*.md the coder produces)

**Estimated batch size:** Substantive — trinity restructure alone is ~300+ added lines across 3 files. Total batch is well above mechanical-edit threshold; the architect-pass justification is the V2 strategy doc itself (per PACK-CHAT.md "No commit-staging beyond mechanical-edit threshold without architect justification" rule).

**Per-commit review/fix decisions** (rationale in §1 table):
- 19b-1: PER-COMMIT review/fix (trinity restructure — high blast-radius, must catch trinity-parity bugs)
- 19b-2: PER-COMMIT review/fix (PACK-CHAT.md is load-bearing for Pack Chat behavior; 7 new bullets warrant a reviewer pass)
- 19b-3: SKIP per-commit review (1-bullet addition pointing back to trinity; broad batch review at 19b-end covers it)
- 19b-4: PER-COMMIT review/fix (EXECUTION-PLAN §B rewrite is full-section replacement, ~50 lines; deserves a reviewer pass for OQ-1 fidelity)
- 19b-5: SKIP per-commit review IF coder reports "no edit needed" for V11-12/13/14 AND V11-15 grep returns 0 non-historical hits; otherwise PER-COMMIT review
- 19b-6: Pack-Chat-direct verification (no reviewer spawn per Pack-Chat decision; iterative script-fix-cycles allowed per L.4 — no one-cycle limit on this commit)
- 19b-7: SKIP per-commit review (pure `git mv` operations; reviewer adds no value)
- **End-of-batch broad reviewer pass:** YES, between 19b-7 and BD status flips (no BD status flips in this batch per V2 §H), so end-of-batch reviewer runs against the full 19b commit set as the cleanup-close audit.

---

## §1 — Commit sequence

| Commit ID | Commit message template | Scope | Files | Verification | Per-commit review? | Rationale-if-override-from-architect-§H |
|---|---|---|---|---|---|---|
| 19b-1 | `docs: v11 — Batch 19b cleanup — trinity ## Pack memory restructure + promotions` | Trinity `## Pack memory` full restructure per V2 §I.1. NEW `### Pack Chat scope` sub-section. RENAME `### Sub-agent isolation (Claude-only)` → `### Sub-agent behavior (Claude-only)`. ADD ~14 new bullets across `### Workflow` / `### Agent invocation rules` / `### Sub-agent behavior (Claude-only)` / `### Pack Chat scope` / `### Repo conventions`. STRENGTHEN PC-9 BD-numbering bullet + V11-9/L7 workflow-artifact list + V11-10 commit-format enumeration. Trinity rule: per §3 bounded per-CLI variant criteria — universal bullets byte-copied; tool-specific bullets get CLI-specific variants per the research-mapped table in §3. | `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` (pack-repo root only) | `python3 scripts/validate-pack.py` PASS; trinity consistency per §3 (universal-bullet diff + tool-specific-bullet substantive-rule table); manual section-by-section read against V2 §B/§F.1/§F.2/§F.3/§I.1 | YES — per-commit `pack-reviewer` against the diff | Same as V2 §H Commit 19b-1; trinity-rule enforcement strategy refined per Pack-Chat 2026-05-17 directive (see §3) |
| 19b-2 | `docs: v11 — Batch 19b cleanup — PACK-CHAT.md ## Behavioral rules extensions (PC-2/6/V11-1/2/5/7/8) + L.2 action-item note` | PACK-CHAT.md `## Behavioral rules` 7 new bullets per V2 §H.2 ordering. Adds L.2 action-item note (per planner extension below) flagging the BD-169-vs-architect-doc divergence. | `PACK-CHAT.md` | `python3 scripts/validate-pack.py` PASS; manual diff vs V2 §B (PC-2, PC-6, V11-1, V11-2, V11-5, V11-7, V11-8) | YES — per-commit `pack-reviewer` | Same as V2 §H Commit 19b-2 + L.2 action-item note added |
| 19b-3 | `docs: v11 — Batch 19b cleanup — PACK-AGENTS.md PREFLIGHT obligation addition (OQ-4)` | PACK-AGENTS.md `## Agent permission rules` — insert PREFLIGHT + STOP-MEANS-STOP obligation bullet per V2 §E.3. Insert BEFORE existing "Skill and agent maintenance" bullet (PACK-AGENTS.md line 189). | `PACK-AGENTS.md` | `python3 scripts/validate-pack.py` PASS; manual diff | SKIP per-commit review | Single short bullet addition pointing back to trinity (3-line cross-ref body); broad batch review at end covers it. Justification: per-commit review is overkill for a 10-15 line addition with no cross-file dependencies. |
| 19b-4 | `docs: v11 — Batch 19b cleanup — EXECUTION-PLAN-V11.0.md §B rewrite (OQ-1)` | EXECUTION-PLAN-V11.0.md §B FULL REPLACEMENT (lines 331-355 of current file → V2 §B (PC-1 row) replacement text). PC-3 audit-IS-the-review clarification is folded into the same §B rewrite (V2 §B PC-3 row). | `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md` | `python3 scripts/validate-pack.py` PASS; manual diff against V2 §B PC-1 replacement text | YES — per-commit `pack-reviewer` | Same as V2 §H Commit 19b-4 |
| 19b-5 | `docs: v11 — Batch 19b cleanup — V11-12/13/14 CONCEPTUAL-REVIEW-METHODOLOGY verification + V11-15 reviewer-prompt-template find-replace` | (1) Pack-coder verifies whether `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` existing sections cover V11-12 (File/Symbol scope), V11-13 (CI-step interrogation), V11-14 (convention/naming docs checklist). If any are missing the architect's specific wording per V2 §B (V11-12/13/14), extend with the V2 text. (2) V11-15 find-replace per V2 §B (V11-15 row) — execute the documented `grep -RIln 'IMPLEMENTATION-PLAN-V11.0.md'` across the named files; replace where non-historical; report historical-only retentions. **Planner pre-check (2026-05-17):** the live grep returned ONE non-architect-doc hit at `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md:245` which is empirical-context "historical why the rename happened" prose — LEAVE AS-IS per V2 V11-15 row "If the reference is historical ... leave it as-is and report." All other grep hits are in archived/RETRO docs and in the V2 architect doc itself; archived docs are immutable, V2 architect doc is PM-only and not edited here. Net effect: 0 source edits for V11-15. | `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` (V11-12/13/14 verification — likely 0-1 edits per planner's read of the live file showing V11-12 covered at lines 231-245, V11-13 covered at lines 104-112, V11-14 covered at lines 114-123); V11-15: empirically zero source edits given planner pre-check | `python3 scripts/validate-pack.py` PASS; pack-coder report names which sections cover the wording; final grep audit shows zero non-historical `IMPLEMENTATION-PLAN-V11.0.md` references in scope files | SKIP per-commit review IF coder reports zero edits OR zero substantive edits; otherwise PER-COMMIT review against the methodology extension diff | Same as V2 §H Commit 19b-5; planner pre-check confirms V11-15 is no-op-likely |
| 19b-6 | `docs: v11 — Batch 19b cleanup — Claude memory cache pointer reduction (§F) — pack-coder script-driven` | Reduce 26 memory files to Tier-1.5 pointer-only per V2 §D.3 template + §F per-file disposition. Preserve `feedback_no_prefix_chars` as STANDALONE. Preserve `feedback_review_fix_one_cycle` EDIT-IN-PLACE then POINTER (apply L3 §B strengthened wording first, then reduce to pointer). Update MEMORY.md index to Tier-1.5 pointer format per V2 §D.3. **L.4 override on V2 §H:** pack-coder writes a one-time-use Python script per §4 spec below; script lives in `/tmp/`, NOT in repo. Iterative script-fix-cycles allowed per L.4 (no one-cycle limit). Failure recovery via SendMessage + `cp` from `.bak-19b-cleanup`; pack-coder stays alive within commit lifecycle. | `~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/MEMORY.md` + 29 memory files (26 POINTER + 1 EDIT-IN-PLACE-then-POINTER + 2 already-determined as STANDALONE/POINTER per §F) | Pack Chat-direct verification (no reviewer spawn per Pack-Chat decision); Pack Chat reads MEMORY.md post-script; opens 2-3 random pointer files and verifies template fidelity; greps for any `trinity_anchor:` field absence in the YAML frontmatter of pointer files (every POINTER file MUST have it); `validate-pack.py` re-run for safety (should be unaffected by memory file changes) | Pack Chat-direct verification ONLY; no reviewer spawn | OVERRIDE of V2 §H 19b-6 "Pack Chat direct": per L.4, pack-coder writes the script per §4 spec; Pack Chat verifies output; script deleted post-success. Rationale: 29-file batch is error-prone hand-edit; script ensures consistent §D.3 template application. Per L.4 failure recovery: Pack Chat reverts broken files via `cp <file>.bak-19b-cleanup <file>` (memory files live OUTSIDE repo so `git checkout` does not apply). |
| 19b-7 | `docs: v11 — Batch 19b cleanup — archive workflow artifacts to maintenance-docs/archive/v11/ (Pattern B exception per OQ-6)` | `git mv` 5 docs into `maintenance-docs/archive/v11/`: (a) CLEANUP-INPUTS-SESSION-RULES.md, (b) ARCHITECTURE-CLEANUP-BATCH-19B.md (first architect), (c) RESEARCH-CLEANUP-BATCH-19B-CROSS-CLI.md, (d) ARCHITECTURE-CLEANUP-BATCH-19B-V2.md (second architect), (e) PLAN-CLEANUP-BATCH-19B.md (this doc). Also `git mv` any IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-*.md the pack-coder produced during 19b-1 through 19b-6. | 5+ file moves via `git mv` to preserve history | `python3 scripts/validate-pack.py` PASS; `ls maintenance-docs/archive/v11/ARCHITECTURE-CLEANUP-BATCH-19B*.md` lists both V1 + V2; `ls maintenance-docs/v11-implementation/CLEANUP-INPUTS*.md` returns empty | SKIP per-commit review (pure `git mv` operations, no content changes); end-of-batch broad reviewer covers archive completeness | Same as V2 §H Commit 19b-7 + adds PLAN-CLEANUP-BATCH-19B.md + IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-*.md per task spec |

**End-of-batch broad pack-reviewer pass** (between 19b-7 and BD status flips, per `feedback_review_fix_one_cycle` — but this batch has NO BD status flips per V2 §H, so this is the final reviewer of the batch): scope = full diff `main..HEAD` of v11-dev showing all 7 commits combined. Catches cross-commit drift (e.g., trinity bullet text in 19b-1 diverging from PACK-AGENTS.md cross-ref in 19b-3).

---

## §2 — Per-commit detail

For each commit, this section names the EXACT bullet text to insert. Pack-coder pastes these from the V2 architect doc without rewriting. All bullet text is the V2 architect's verbatim text. Where line-number-based INSERT points are named, they reflect the CURRENT state of each file at HEAD `cd8246c`.

### 19b-1 — Trinity `## Pack memory` restructure

**Files:** `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` (pack-repo root); `scripts/validate-pack.py` IF trinity-parity check exists and trips on §3-refined edits (see §6.3); otherwise scope unchanged.

**Trinity rule strategy** (see §3 for full enforcement plan): per Pack-Chat 2026-05-17 directive, trinity bullets are NOT byte-identical across all 3 files by default. Each bullet is classified as UNIVERSAL (byte-copy) or TOOL-SPECIFIC (per-CLI variant produced from the research-mapped table in §3). Pack-coder authors the CLAUDE.md master, classifies each bullet, then produces AGENTS.md and GEMINI.md versions. The SUBSTANTIVE rule stays identical across CLIs; tool-specific machinery wording differs by CLI per the §3 mapping table. The IMPL-REPORT carries a per-bullet substantive-rule table (Pack Chat reads this at commit-approval review).

**Edits within `## Pack memory > ### Workflow`** (insert NEW bullets in this order; preserve existing 4 bullets):
- (existing) Agents never commit
- (existing) Pack Chat does not architect
- (existing) One review/fix cycle per batch
- (existing) Implicit BD status flip on batch completion
- NEW: Per-action approval extends to sub-agents — V2 §B (PC-uncertain-a) verbatim
- NEW: Deferred work needs a tracked anchor — V2 §B (PC-8) verbatim
- NEW: No deferral to v11.1+ without explicit user direction — V2 §B (V11-4) verbatim
- NEW: Deferral IS scope creep — V2 §B (L2) verbatim
- NEW: Per-BD review/fix runs INLINE, before next BD's coder spawns — V2 §B (L3) verbatim
- NEW: Pack Chat presents triage to user before fix-coder spawns — V2 §B (L5) verbatim
- NEW: Triage all reviewer findings; default fix-all; nits become tech debt — V2 §F.1 verbatim
- NEW: Planner output → user review → coder spawn — V2 §F.3 verbatim

**Edits within `## Pack memory > ### Agent invocation rules`** (insert NEW bullets in this order; preserve existing 4 bullets):
- (existing) Pack agent invocation
- (existing) Agent prompt requirements
- (existing) No solutions in agent prompts
- (existing) No prior reviews to pack-reviewer
- NEW: Researcher-first pipeline for substantive content — V2 §B (PC-11) verbatim
- NEW: Pack-coder PREFLIGHT + STOP-MEANS-STOP pattern — V2 §C.3 verbatim
  - **Important:** Per V2 §F.3 placement note, the F.3 "Planner output → user review → coder spawn" bullet is also in `### Agent invocation rules` per V2's own §F.3 text ("ADD as a bullet inside trinity `### Agent invocation rules` (after PC-11 bullet, before the L8 PREFLIGHT bullet)"). Pack-coder: insertion order in `### Agent invocation rules` after PC-11 is (a) F.3 planner-output-user-review, then (b) L8 PREFLIGHT. The V2 §I.1 ToC lists F.3 under `### Workflow`; the V2 §F.3 text places it in `### Agent invocation rules`. **Planner resolution:** authoritative text in §F.3 wins (it names "Agent invocation rules" explicitly twice and gives an ordering after PC-11 / before L8). The V2 §I.1 ToC entry under `### Workflow` is the architect's editorial inconsistency — flagged as OPEN QUESTION 6.1 below. Pack-coder follows §F.3 placement: F.3 lives in `### Agent invocation rules`.

**Edits within `## Pack memory > ### Sub-agent isolation (Claude-only)`** (RENAME the sub-section to `### Sub-agent behavior (Claude-only)`; preserve existing bullet + Trinity exemption note; insert NEW bullets):
- RENAME heading from `### Sub-agent isolation (Claude-only)` to `### Sub-agent behavior (Claude-only)`
- (existing) Spawn all sub-agents with no worktree isolation
- NEW: Default sub-agent spawns to background — V2 §B (PC-uncertain-b) verbatim
- NEW: Agent-team stage lifecycle + per-commit fresh-coder — V2 §B (V11-6 REVISED PC-4) verbatim
- (existing) Trinity exemption note — preserve

**Edits within `## Pack memory`** (CREATE NEW sub-section `### Pack Chat scope` BETWEEN `### Sub-agent behavior (Claude-only)` and `### Repo conventions`):
- NEW sub-section heading: `### Pack Chat scope`
- NEW bullet: Pack Chat does NO fixes (with the "What Pack Chat CAN edit directly" sub-list) — V2 §B (L1) verbatim
- NEW bullet: Commit-approval requests include next-steps plan — V2 §B (L6) verbatim
- NEW bullet: Pack-architect spawn protocol — V2 §B (PC-10 merged with L4) verbatim

**Edits within `## Pack memory > ### Repo conventions`** (preserve existing 5 bullets; STRENGTHEN one; insert 3 NEW):
- (existing) Per-entry trees vs mirrors
- (existing) BACKLOG.md has no Resolved section
- (existing) Separate pack ops from pack product
- (existing) Test infra is self-provisioned
- (existing) Skill and agent maintenance is mechanical by default — **STRENGTHEN per V2 §B (V11-9) BEFORE/AFTER** to add `IMPLEMENTATION-REPORT-*-RETRO-FIX.md`, `PACK-REVIEW-*-RETRO.md`, `CLEANUP-INPUTS-*.md` to the workflow-artifact pattern list
- NEW: Pack-repo code-comment deferrals — V2 §B (V11-19) verbatim
- NEW: Filename uniqueness heuristic — V2 §F.2 verbatim
- NEW: Architect-doc-vs-reality reconciliation — V2 §B (L9) verbatim

**Edits within `## Pack memory > ### Project goals (v11)`** (no changes; preserve both existing bullets).

**Edits OUTSIDE `## Pack memory`** (STRENGTHEN existing top-level rules):
- STRENGTHEN "BD-NNN numbering" section per V2 §B (PC-9) BEFORE/AFTER. CLAUDE.md current lines 61-63, AGENTS.md current lines 55-57, GEMINI.md current line 45-46 (where it's already condensed). The V2 doc provides specific Gemini tighter phrasing — use it for GEMINI.md.
- STRENGTHEN "Commit message format" section per V2 §B (V11-10) BEFORE/AFTER. CLAUDE.md current lines 47-53, AGENTS.md current lines 41-47, GEMINI.md current line 38 (where it's a single-line condensed form). For GEMINI.md, expand to include the approved-suffixes enumeration in the same compact style.

**Trinity-only exemption (per V2 §I.4):** The renamed `### Sub-agent behavior (Claude-only)` sub-section appears in CLAUDE.md ONLY. AGENTS.md and GEMINI.md DROP this sub-section. The existing Claude-only `### Sub-agent isolation (Claude-only)` is currently CLAUDE.md-only (not present in AGENTS.md or GEMINI.md per planner read above) — so the rename + bullet additions all stay Claude-only.

**Per-CLI variant classification:** see §3 for the universal-vs-tool-specific criteria and the research-mapped per-bullet variant text. Pack-coder applies §3 criteria to every bullet authored above, produces the per-bullet substantive-rule table, and includes the table in the IMPL-REPORT for Pack Chat review.

### 19b-2 — PACK-CHAT.md `## Behavioral rules` extensions

**File:** `PACK-CHAT.md`.

**Insertion point:** After the existing "Verify staged files before committing" bullet (current PACK-CHAT.md line 62, where the bullet ends at line 63: "...the staged file list / and approves before the commit command runs."). The 7 new bullets are inserted in V2 §H.2 theme-clustered order.

**Bullets to insert** (verbatim from V2 §B; per-bullet placement is sequential after the "Verify staged files" bullet):
1. PC-2 — Stop after every reviewer pass for triage discussion — V2 §B (PC-2) verbatim
2. PC-6 (consolidates PC-7 + V11-3) — Chat-ownership boundaries on concurrent sessions — V2 §B (PC-6) verbatim
3. V11-1 — Real fixes only — no green-the-test band-aids — V2 §B (V11-1) verbatim
4. V11-2 — Direct opinion, not validation — V2 §B (V11-2) verbatim
5. V11-5 — Push to v11-dev only during the v11-dev phase — V2 §B (V11-5) verbatim
6. V11-8 (NEW-HOME per §A.2 challenge, NOT BD-173 per L.1) — Batch close commit shapes — V2 §B (V11-8) verbatim
7. V11-7 — Scope-extension test for in-flight work — V2 §B (V11-7) verbatim

**Note on V11-8 ordering vs V2 §H.2:** V2 §H.2 lists ordering as "V11-5, V11-8, V11-7" (V11-8 BEFORE V11-7) under "branch / commit policy" cluster and "scope-extension test" cluster. The plan above mirrors V2 §H.2 ordering exactly.

**ADDITIONAL: L.2 action-item note** (per planner per L.2 binding decision). INSERT at the BOTTOM of PACK-CHAT.md `## Behavioral rules` section (after the existing "No commit-staging beyond mechanical-edit threshold" bullet at line 99 — i.e., as a NEW final bullet of the section, after all 7 new bullets above land). Text:

```
- **L.2 action item (architect-doc reconciliation, PM-owned).** The
  STATUS.md disclaimer wording at `maintenance-docs/v11-implementation/
  ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` §5.3 diverges from the
  Option A canonical wording (PLAN-PER-ENTRY-SPLIT-BATCH-19.md §5.8,
  followed at BD-169). Per Batch 19b cleanup L.2 decision: this batch
  does NOT edit the per-entry-split architect docs (PM-owned). Pack
  Chat is to surface this divergence to the user at PM-discussion time
  to pick the canonical wording and edit ARCHITECTURE-PER-ENTRY-SPLIT-
  INTEGRATION.md §5.3 to match. Tracked as a Pack-Chat-side coordination
  item; not a code defect.
```

### 19b-3 — PACK-AGENTS.md PREFLIGHT obligation addition

**File:** `PACK-AGENTS.md`.

**Insertion point:** Insert as a NEW bullet INSIDE `## Agent permission rules`, AFTER the existing "Forward-pointing note (Batch 19 → Batch 23):" paragraph (which ends at PACK-AGENTS.md line 187 in current file). Specifically: AFTER line 187 (the line ending `the references resolve at Batch 23.`), BEFORE the existing "Skill and agent maintenance" bullet (which currently starts at line 189). The new bullet sits BETWEEN those two.

**Bullet text** (verbatim from V2 §E.3):

```
**Pack-coder PREFLIGHT + STOP-MEANS-STOP obligation.** Every pack-coder
(or coder-style fix-coder) agent has two non-negotiable behavioral
obligations:

- **PREFLIGHT line BEFORE IMPL-REPORT.** After all in-scope edits +
  verification, emit a single plain-text line of the form `PREFLIGHT:
  N/N in-scope file edits complete; verification PASS; HEAD <SHA>;
  about to Write IMPL-REPORT to <path>` before any IMPL-REPORT write.
  This is the orchestrator's trust signal that the report-write
  starts from complete-and-green state.

- **STOP-MEANS-STOP on parent stop directives.** Any parent-session
  message containing stop / halt / revert / do not continue MUST
  trigger immediate halt of all work including in-progress Writes.
  Partial files are acceptable; do not append to "make consistent."
  Defying a parent stop directive is the worst possible failure
  mode (see worked example: BD-169 19g-pack incident, 2026-05-16).

Authoritative full text for both halves of the pattern (including
cross-CLI scope notes for Codex / Gemini): trinity `## Pack memory`
`### Agent invocation rules` "Pack-coder PREFLIGHT + STOP-MEANS-STOP
pattern" bullet.
```

### 19b-4 — EXECUTION-PLAN-V11.0.md §B rewrite

**File:** `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md`.

**Action:** REPLACE the full `### B. Audit / review-fix protocol (user rule, 2026-05-11)` section. Current section spans lines 331-355 (heading + 5 numbered items + closing paragraph "BDs are reserved..."). Replacement text spans about 50 lines.

**Replacement text** (verbatim from V2 §B (PC-1 row)):

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

(Note: the closing emphatic paragraph "BDs are reserved for new scope..." from the pre-rewrite §B is DROPPED — its content is fully absorbed into steps 1, 5, and 6 of the replacement.)

**PC-3 fold:** V2 §B (PC-3) clarification "An audit pass IS the review for that batch; no separate pack-reviewer is run on the audit-fix commit." is folded into step 4 above (per V2 §B PC-3 instruction).

**L.6 forward-only fold:** the closing "OQ-1 scope" paragraph above is the planner's addition per L.6 binding decision (architect's V2 §L.6 surfaced the question; L.6 binding answer is forward-only). The V2 architect doc does not propose this exact wording but does propose forward-only as architect recommendation in §L.6.

### 19b-5 — V11-12/13/14 verification + V11-15 find-replace

**File:** `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` (possibly extended; otherwise unmodified).

**Pack-coder steps for V11-12/13/14 verification** (per V2 §B V11-12/13/14 rows + L.5 binding):

1. Read `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` in full.
2. For V11-12 ("Retro-review prompts source File/Symbol from authoritative sources"): check if the existing section "File/Symbol scope from authoritative sources, not prose recall" (lines 231-245) names the RETRO case specifically (sourcing from BACKLOG `File/Symbol:` + `git diff --stat <SHA>`). **Planner pre-check:** existing wording at lines 231-245 names the generic case (BACKLOG `File/Symbol:` field + `git show --stat <commit-sha>`) and references the Batch 21c BD-112 retro incident as empirical basis. The wording covers RETRO use empirically but does NOT use the term "retro-review prompts" or call out the retro distinction explicitly. **Coder decision:** if coder judges this covers the retro case adequately, NO EDIT; otherwise extend per V2 §B (V11-12) text.
3. For V11-13 ("CI-touching work prompts"): check if section "CI-step interrogation heuristic" (lines 104-112) covers the "must-include-in-prompt" rule. **Planner pre-check:** line 112 reads "Reviewer prompt template for CI work MUST include the 'would this turn red?' requirement." This covers V11-13's requirement explicitly. **Coder decision:** no edit needed; coder confirms in report.
4. For V11-14 ("Convention/naming docs need finding-mode checklist"): check if section "Convention/naming docs review checklist" (lines 114-123) lists concrete checklist items. **Planner pre-check:** lines 114-123 enumerate 4 concrete checks (Procedure↔rule consistency; Column↔text consistency; Forward-compatibility for vN+1; Examples↔rule alignment) with empirical basis. **Coder decision:** existing wording covers V11-14 adequately; per V2 §B V11-14 row: "STRENGTHEN — but in this batch's scope, only flag for the user; do NOT extend it without an architect pass per L4." **Coder action:** read-and-report only; no edit.
5. Coder report names which sections cover which V11-12/13/14 items, what edits (if any) were made.

**Pack-coder steps for V11-15** (per V2 §B V11-15 row + planner pre-check):

1. Run the V2-documented `grep -RIln 'IMPLEMENTATION-PLAN-V11.0.md'` over the named files:
   ```bash
   grep -RIln 'IMPLEMENTATION-PLAN-V11.0.md' \
     /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/supporting-docs/ \
     /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/ \
     /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/PACK-CHAT.md \
     /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/PACK-AGENTS.md \
     /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md \
     /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/AGENTS.md \
     /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/GEMINI.md \
     2>/dev/null
   ```
2. **Planner pre-check (2026-05-17) results** — the live grep returns these files:
   - `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md:245` — empirical-context historical "the rename happened" prose → LEAVE AS-IS per V2 row "If the reference is historical, leave it as-is and report"
   - `maintenance-docs/v11-implementation/CLEANUP-INPUTS-SESSION-RULES.md:156` — being archived in 19b-7, archived state preserves the historical input → LEAVE AS-IS
   - `maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19B*.md` (lines 83, 85, 101, 710 of V2 doc; line 101 of V1 doc) — architect docs being archived in 19b-7 → LEAVE AS-IS
   - `maintenance-docs/v11-implementation/PACK-REVIEW-BD-116-RETRO.md:554` — RETRO review doc historical record → LEAVE AS-IS
   - `maintenance-docs/v11-implementation/PACK-REVIEW-BD-117-RETRO.md:469, 471, 472` — RETRO review historical → LEAVE AS-IS
   - `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-117-RETRO-FIX.md:448` — RETRO fix report historical → LEAVE AS-IS
3. Coder runs the grep, reports the file list with line-context for each, and confirms which are historical (LEAVE AS-IS) vs live-template-reference (REPLACE). **Expected outcome based on planner pre-check:** 0 source edits; coder confirms zero non-historical hits.
4. **If coder's grep returns any NEW non-historical hit not on planner's pre-check list:** coder triages per V2 row; if it should be replaced with `EXECUTION-PLAN-V11.0.md`, do so; reports in IMPL-REPORT.

### 19b-6 — Claude memory cache pointer reduction (pack-coder script-driven)

**Files:** `~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/MEMORY.md` + 29 memory files in same directory.

**Script execution model** (per L.4 binding + §4 spec below): pack-coder writes a Python script to `/tmp/<unique-name>.py`, tests on 1-2 files, verifies output matches §D.3 template, then runs on remaining 24. Script is DELETED after successful commit lands.

**Per-file dispositions** (verbatim from V2 §F, all 29 entries):

| # | Memory file | Disposition |
|---|---|---|
| 1 | `feedback_clarg_trinity.md` | POINTER → trinity `**Trinity rule**` section (top-level rules block, NOT `## Pack memory`) |
| 2 | `feedback_no_destructive_without_approval.md` | POINTER → trinity `### Workflow` > "Per-action approval extends to sub-agents" |
| 3 | `feedback_spawn_agents_in_background.md` | POINTER → trinity `### Sub-agent behavior (Claude-only)` > "Default sub-agent spawns to background" |
| 4 | `feedback_agent_teams_stage_lifecycle.md` | POINTER → trinity `### Sub-agent behavior (Claude-only)` > "Agent-team stage lifecycle + per-commit fresh-coder" |
| 5 | `feedback_no_prefix_chars.md` | **STANDALONE** — Claude-Code chat-tooling convention; no trinity equivalent; **preserve full body content** |
| 6 | `feedback_ops_product_separation.md` | POINTER → trinity `### Repo conventions` > "Separate pack ops from pack product" |
| 7 | `feedback_agent_prompt_rules.md` | POINTER → trinity `### Agent invocation rules` > "Agent prompt requirements" |
| 8 | `reference_pack_backlog_structure.md` | POINTER → trinity `### Repo conventions` > "BACKLOG.md has no Resolved section" |
| 9 | `feedback_chunk_long_outputs.md` | POINTER → trinity `### Agent invocation rules` > "Agent prompt requirements" (chunk-Write clause) |
| 10 | `reference_pack_agent_invocation.md` | POINTER → trinity `### Agent invocation rules` > "Pack agent invocation" |
| 11 | `feedback_pack_chat_does_not_architect.md` | POINTER → trinity `### Workflow` > "Pack Chat does not architect" |
| 12 | `feedback_no_solutions_in_agent_prompts.md` | POINTER → trinity `### Agent invocation rules` > "No solutions in agent prompts" |
| 13 | `feedback_no_prior_reviews_to_reviewer.md` | POINTER → trinity `### Agent invocation rules` > "No prior reviews to pack-reviewer" |
| 14 | `feedback_review_fix_one_cycle.md` | **EDIT-IN-PLACE then POINTER** — first apply V2 §B (L3) strengthened body wording per the EDIT-IN-PLACE row; then reduce to POINTER → trinity `### Workflow` > "Per-BD review/fix runs INLINE, before next BD's coder spawns". The body is reduced AFTER the strengthening is captured into the trinity bullet. |
| 15 | `feedback_fix_all_review_findings.md` | POINTER → trinity `### Workflow` > "Triage all reviewer findings; default fix-all" (V2 §F.1 NEW bullet) |
| 16 | `feedback_deferred_work_tracking.md` | POINTER → trinity `### Workflow` > "Deferred work needs a tracked anchor" |
| 17 | `feedback_no_deferral_without_user_direction.md` | POINTER → trinity `### Workflow` > "No deferral to v11.1+ without explicit user direction" |
| 18 | `feedback_deferral_is_scope_creep.md` | POINTER → trinity `### Workflow` > "Deferral IS scope creep" |
| 19 | `feedback_pack_chat_does_no_fixes.md` | POINTER → trinity `### Pack Chat scope` > "Pack Chat does NO fixes" |
| 20 | `feedback_implicit_status_flip.md` | POINTER → trinity `### Workflow` > "Implicit BD status flip on batch completion" |
| 21 | `project_v11_high_level_goals.md` | POINTER → trinity `### Project goals (v11)` (both bullets — pointer can name the sub-section, not an individual bullet) |
| 22 | `feedback_test_infra_self_provisioned.md` | POINTER → trinity `### Repo conventions` > "Test infra is self-provisioned" |
| 23 | `feedback_agents_never_commit.md` | POINTER → trinity `### Workflow` > "Agents never commit" |
| 24 | `feedback_worktree_isolation_broken_from_v11_clone.md` | POINTER → trinity `### Sub-agent behavior (Claude-only)` > "Spawn all sub-agents with no worktree isolation" |
| 25 | `feedback_filename_uniqueness.md` | POINTER → trinity `### Repo conventions` > "Filename uniqueness heuristic" (V2 §F.2 NEW bullet) |
| 26 | `feedback_pack_coder_preflight_pattern.md` | POINTER → trinity `### Agent invocation rules` > "Pack-coder PREFLIGHT + STOP-MEANS-STOP pattern" |
| 27 | `feedback_commit_approval_next_steps.md` | POINTER → trinity `### Pack Chat scope` > "Commit-approval requests include next-steps plan" |
| 28 | `feedback_researcher_architect_planner_pipeline.md` | POINTER → trinity `### Agent invocation rules` > "Researcher-first pipeline for substantive content" |
| 29 | `feedback_planner_user_review_before_coder.md` | POINTER → trinity `### Agent invocation rules` > "Planner output → user review → coder spawn" (V2 §F.3 NEW bullet) |

**MEMORY.md index reduction:** Replace the existing 29-bulleted-list with the V2 §D.3 template prelude + one-line entries per ACTIVE rule per disposition table (28 POINTER + 1 STANDALONE = 29 lines). See §4 spec for exact format.

**§D.3 template body for POINTER files** (verbatim from V2 §D.3):

```
---
name: <preserved from original frontmatter>
description: <preserved from original frontmatter>
metadata:
  node_type: memory
  type: feedback | reference
  trinity_anchor: <path/to/file.md>#<anchor-id>
  originSessionId: <preserved from original>
---

# <Human-readable title>

This memory entry is a Tier-1.5 pointer cache. The authoritative rule
lives in trinity:

→ `<absolute-path>/CLAUDE.md` `## Pack memory` > `### <sub-section>` >
  bullet "<bullet-title-or-first-N-words>"

If this pointer disagrees with trinity, TRINITY WINS. Update this
pointer file in the same commit as any trinity rule change.
```

**MEMORY.md index reduction template** (verbatim from V2 §D.3):

```
**Tier 1.5 (Claude-Code memory cache).** This index points to trinity
rules at `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md` `## Pack memory`. Trinity is the
single source of truth; this file is a Claude-Code convenience cache.
If this index disagrees with trinity, TRINITY WINS.

- [<title>](<trinity-anchor>) — <one-line summary>
...
```

(Substitute the absolute path to the pack repo `CLAUDE.md` per the local clone.)

### 19b-7 — Archive cleanup batch workflow artifacts

**Files:** `git mv` operations.

**Specific moves:**

```bash
git mv maintenance-docs/v11-implementation/CLEANUP-INPUTS-SESSION-RULES.md          maintenance-docs/archive/v11/CLEANUP-INPUTS-SESSION-RULES.md
git mv maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19B.md         maintenance-docs/archive/v11/ARCHITECTURE-CLEANUP-BATCH-19B.md
git mv maintenance-docs/v11-implementation/RESEARCH-CLEANUP-BATCH-19B-CROSS-CLI.md   maintenance-docs/archive/v11/RESEARCH-CLEANUP-BATCH-19B-CROSS-CLI.md
git mv maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19B-V2.md      maintenance-docs/archive/v11/ARCHITECTURE-CLEANUP-BATCH-19B-V2.md
git mv maintenance-docs/v11-implementation/PLAN-CLEANUP-BATCH-19B.md                 maintenance-docs/archive/v11/PLAN-CLEANUP-BATCH-19B.md
# Plus any IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-*.md the pack-coder produced:
git mv maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-*.md  maintenance-docs/archive/v11/
```

**IMPORTANT:** Per the binding "agents never commit" rule + planner constraints, pack-coder does NOT run `git mv`. Pack Chat runs `git mv` after staging is reviewed. The 6 moves above use `git mv` (NOT `mv`) so git history follows.

**Pre-move check:** Pack Chat verifies all source files exist BEFORE running the moves. The IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-*.md file(s) may not exist if pack-coder did not produce them (e.g., 19b-3 / 19b-7 had no pack-coder); only the ones that DO exist get moved.

---

## §3 — Trinity rule enforcement plan (REFINED per Pack-Chat 2026-05-17 directive)

**Applies to:** Commit 19b-1 (and through-cascade to 19b-2 / 19b-3 / 19b-4 which reference trinity bullets).

**Authoritative source for per-CLI variant data:** `maintenance-docs/v11-implementation/RESEARCH-CLEANUP-BATCH-19B-CROSS-CLI.md` (cited inline as "research §N" below).

**Refinement rationale (Pack-Chat 2026-05-17):** the trinity rule's existing exemption — "modify all three together UNLESS the change is provably tool-specific" — means some bullets SHOULD differ per CLI when they reference tool-specific machinery. The prior planner spec ("byte-identical Pack-memory content modulo Claude-only sub-section") was overly strict; it would have either (a) forced Claude-specific tool names into AGENTS.md / GEMINI.md (wrong — those tool names don't exist on other CLIs) or (b) suppressed the substantive rule for non-Claude CLIs (wrong — the rule applies to all CLIs, just via different machinery). The refinement uses BOUNDED CRITERIA (not pure coder judgment): the coder MAPS research-report data into per-CLI variant text per the table below, rather than inventing variants.

### §3.1 — Criteria for per-CLI variant requirement

**TOOL-SPECIFIC bullet — needs per-CLI variants.** A bullet requires per-CLI variants for AGENTS.md and GEMINI.md if its body references ANY of these Claude-specific surfaces:

- **Claude-specific tool names:**
  - `Task tool`
  - `SendMessage`
  - `AGENT_TEAMS=1` / `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
  - `run_in_background` (or `run_in_background: true`)
  - `subagent_type`
- **Claude-specific paths:**
  - `~/.claude/projects/<slug>/memory/...`
  - `~/.claude/...` (any user-level claude path)
  - `.claude/skills/`
  - `.claude/agents/`
- **Claude-specific mechanisms:**
  - SECURITY WARNING (transcript classifier per research §1.7)
  - Per-project memory cache as auto-loaded markdown (Claude-Code per research §1.2)
- **Claude-specific commands:**
  - `/agents` (Claude Code slash command)
  - Other Claude-Code-specific slash commands

**UNIVERSAL bullet — byte-copy across all 3 trinity files.** A bullet has identical wording across CLAUDE.md / AGENTS.md / GEMINI.md if its body does NOT reference any of the above AND the substantive rule is identical for all 3 CLIs. Most workflow / Pack Chat scope / Repo conventions / deferral-tracking rules are universal.

### §3.2 — Research-mapped per-CLI variant table

Pack-coder uses this table as the authoritative mapping for producing variant text. Source columns cite the relevant research-report section.

| Claude reference | Codex equivalent (research §2 + cited URLs) | Gemini equivalent (research §3 + cited URLs) |
|---|---|---|
| `SendMessage` tool / inter-agent peer messaging | **Confirmed absent** per Codex issue #12462 (research §2.5). Variant wording: "no Codex equivalent — peer messaging absent; parent stop is `/agent` slash command or natural-language directive (research §2.6 documents reliability caveats)" | **Confirmed absent** per Gemini hub-and-spoke docs (research §3.5). Variant wording: "no Gemini equivalent — peer messaging absent; parent stop is natural-language directive or `Ctrl+C` (terminates whole session per issue #3385; research §3.6 documents reliability caveats)" |
| `Task tool` + `subagent_type` | Codex custom-agent spawning via `~/.codex/agents/` or `.codex/agents/` `.toml` files (research §2.3). Variant wording: "Codex sub-agents are defined in TOML files at `~/.codex/agents/` (personal) or `.codex/agents/` (project); parent invokes by agent name" | Gemini sub-agent spawning via `.gemini/agents/` `.md` files invoked with `@agent-name` (research §3.3). Variant wording: "Gemini sub-agents are defined in markdown files at `.gemini/agents/` (project) or `~/.gemini/agents/` (user); parent invokes via `@agent-name` forcing syntax" |
| `run_in_background: true` (per-call Claude flag) | Codex parallel-by-default (capped by `agents.max_threads`, default 6); no per-call flag documented (research §2.4). Variant wording: "Codex sub-agents spawn in parallel by default (cap: `agents.max_threads` config, default 6); no per-call background flag" | Gemini parallel via `@` invocation; no documented async-background API (research §3.4). Variant wording: "Gemini sub-agents spawn in parallel via `@` invocation or natural-language request; async-background per-call API not documented (open issues #14963, #17749)" |
| `~/.claude/projects/<slug>/memory/*.md` (Claude memory cache) | **Per V2 §D decision — Codex has NO pack-shipped memory file.** Codex sees pack rules via `AGENTS.md` trinity only. The bullet should NOT reference a Codex memory path. Variant wording: omit the memory-cache reference; substantive rule stays "trinity is the authoritative rule surface" | **Per V2 §D decision — Gemini has NO pack-shipped memory file.** Gemini sees pack rules via `GEMINI.md` trinity only. The bullet should NOT reference a Gemini memory path. Variant wording: omit the memory-cache reference; substantive rule stays "trinity is the authoritative rule surface" |
| `AGENT_TEAMS=1` flag / Claude Code experimental | No equivalent — Codex sub-agents work without flag (research §2.3). Variant wording: omit flag reference; substantive rule stays "Codex sub-agents are enabled by default" | No equivalent — Gemini sub-agents work without flag (research §3.3). Variant wording: omit flag reference; substantive rule stays "Gemini sub-agents are enabled by default (toggle via `enableAgents: false` to disable)" |
| SECURITY WARNING (transcript classifier per research §1.7) | **Couldn't find documented Codex equivalent** per research §2.7. Variant wording: "Claude-Code-specific — no documented Codex equivalent at the transcript-classifier handoff-check level" | **Couldn't find documented Gemini equivalent** per research §3.7. Variant wording: "Claude-Code-specific — no documented Gemini equivalent at the transcript-classifier handoff-check level" |
| `/agents` slash command (Claude) | Codex `/agent` slash command (singular; per research §2.6). Variant wording: "Codex `/agent` slash command" | Gemini `/agents disable <name>` / `/agents enable <name>` (per research §3.6). Variant wording: "Gemini `/agents` slash commands (`disable`, `enable`)" |
| `.claude/skills/` | Codex skills directory: `.codex/skills/` (per PACK-AGENTS.md key conventions line 219). Variant wording: "`.codex/skills/`" | Gemini skills directory: `.gemini/skills/` (per PACK-AGENTS.md key conventions line 219). Variant wording: "`.gemini/skills/`" |
| `.claude/agents/` | Codex agents directory: `.codex/agents/` (research §2.3). Variant wording: "`.codex/agents/`" | Gemini agents directory: `.gemini/agents/` (research §3.3). Variant wording: "`.gemini/agents/`" |

### §3.3 — Per-bullet classification for trinity restructure (commit 19b-1)

Pack-coder applies §3.1 criteria to each new/modified trinity bullet. Below is the planner's classification per bullet — the coder verifies and may flag any classification disagreement in the IMPL-REPORT.

**`### Workflow` bullets:**

| Bullet | Classification | Reason |
|---|---|---|
| (existing) Agents never commit | UNIVERSAL | References git verbs only; no Claude-specific tooling |
| (existing) Pack Chat does not architect | UNIVERSAL | References pack-architect/pack-planner/pack-coder/pack-reviewer agent names — these are the pack's universal agent roster (PACK-AGENTS.md), not CLI-specific |
| (existing) One review/fix cycle per batch | UNIVERSAL | References pack-reviewer + BDs only |
| (existing) Implicit BD status flip on batch completion | UNIVERSAL | References BDs only |
| NEW: Per-action approval extends to sub-agents | UNIVERSAL | Substantive rule applies to all CLI sub-agents; references PACK-AGENTS.md (universal) |
| NEW: Deferred work needs a tracked anchor | UNIVERSAL | References BD + code-comment surfaces (universal) |
| NEW: No deferral to v11.1+ without explicit user direction | UNIVERSAL | References v11.0 / v11.1 / pack-development only |
| NEW: Deferral IS scope creep | UNIVERSAL | References BD lifecycle only |
| NEW: Per-BD review/fix runs INLINE | UNIVERSAL | References pack-reviewer + BDs only |
| NEW: Pack Chat presents triage to user before fix-coder spawns | UNIVERSAL | References fix-coder (pack agent name, universal); Pack-Chat decisions |
| NEW: Triage all reviewer findings; default fix-all | UNIVERSAL | References reviewer findings + tech-debt anchor (universal) |
| NEW: Planner output → user review → coder spawn | UNIVERSAL | References pack-planner / pack-coder (pack agent names, universal) |

**`### Agent invocation rules` bullets:**

| Bullet | Classification | Reason |
|---|---|---|
| (existing) Pack agent invocation | **TOOL-SPECIFIC** (already varied across files) | Existing CLAUDE.md cites `claude --agent`; AGENTS.md cites `codex --agent`; GEMINI.md cites `@pack-<name>`. The PACK-AGENTS.md row covers all three; trinity files cite each their own. Pack-coder preserves the existing variant pattern. |
| (existing) Agent prompt requirements | UNIVERSAL | Substantive rule (prompt content) is identical across CLIs |
| (existing) No solutions in agent prompts | UNIVERSAL | Substantive rule identical across CLIs |
| (existing) No prior reviews to pack-reviewer | UNIVERSAL | References pack-reviewer (universal) |
| NEW: Researcher-first pipeline for substantive content | UNIVERSAL | References pack-docs-researcher / pack-architect / pack-planner / pack-coder (universal) |
| NEW: Planner output → user review → coder spawn (per §F.3 placement) | UNIVERSAL | References pack-planner / pack-coder (universal) |
| NEW: Pack-coder PREFLIGHT + STOP-MEANS-STOP pattern | **TOOL-SPECIFIC** — bullet body already contains the cross-CLI scope notes per V2 §C.3 (Claude SendMessage + SECURITY WARNING + Codex `/agent` + Gemini `Ctrl+C`). The CLAUDE.md version carries all three CLI sub-bullets; AGENTS.md and GEMINI.md drop the OTHER two CLI sub-bullets and keep only their own + the platform-neutral PREFLIGHT half. PREFLIGHT (platform-neutral half) is UNIVERSAL; STOP-MEANS-STOP enforcement details are PER-CLI per the §3.2 table. |

**`### Sub-agent behavior (Claude-only)` bullets — Claude-only exemption per V2 §I.4:** sub-section appears in CLAUDE.md ONLY. Not subject to per-CLI variant criteria because AGENTS.md / GEMINI.md DROP the sub-section entirely. The Trinity exemption note inside the sub-section explains why.

**`### Pack Chat scope` (NEW) bullets:**

| Bullet | Classification | Reason |
|---|---|---|
| NEW: Pack Chat does NO fixes | UNIVERSAL (mostly) | Substantive rule is universal; the "What Pack Chat CAN edit directly" sub-list contains one TOOL-SPECIFIC element: `~/.claude/projects/<slug>/memory/*.md` (Claude memory cache path). For AGENTS.md / GEMINI.md variants, this sub-bullet is REPLACED with "Per V2 §D, no Codex/Gemini equivalent memory cache; Pack-Chat-direct memory editing applies to Claude only" (or equivalent — coder produces per the §3.2 table mapping for `~/.claude/projects/<slug>/memory/...`). |
| NEW: Commit-approval requests include next-steps plan | UNIVERSAL | References Pack Chat behavior only |
| NEW: Pack-architect spawn protocol | UNIVERSAL | References pack-architect / pack-planner / pack-coder / pack-reviewer / pack-docs-researcher (universal) |

**`### Repo conventions` bullets:**

| Bullet | Classification | Reason |
|---|---|---|
| (existing) Per-entry trees vs mirrors | UNIVERSAL | References per-entry directory paths only (universal pack layout) |
| (existing) BACKLOG.md has no Resolved section | UNIVERSAL | References BACKLOG only |
| (existing) Separate pack ops from pack product | UNIVERSAL | References pack file layout only |
| (existing) Test infra is self-provisioned | UNIVERSAL | References `gh` CLI (universal) |
| (existing, STRENGTHEN per V11-9) Skill and agent maintenance is mechanical by default | UNIVERSAL | References pack file patterns + workflow artifact names; substantive rule identical across CLIs |
| NEW: Pack-repo code-comment deferrals | UNIVERSAL | References project-template/CLAUDE.md as canonical for typed format; substantive rule applies to all CLIs. **Note:** the cross-reference text "project-template/CLAUDE.md § Deferral comments" appears identical in CLAUDE.md / AGENTS.md / GEMINI.md — UNIVERSAL holds. |
| NEW: Filename uniqueness heuristic | UNIVERSAL | References pack file layout + universal CI Check 24 |
| NEW: Architect-doc-vs-reality reconciliation | UNIVERSAL | References pack architect docs only |

**`### Project goals (v11)` bullets:** UNIVERSAL (no CLI references).

**Edits OUTSIDE `## Pack memory` (top-level rules):**

| Edit | Classification | Reason |
|---|---|---|
| STRENGTHEN BD-NNN numbering (PC-9) | UNIVERSAL substantive rule, but the existing GEMINI.md form is already a tighter phrasing (V2 §B PC-9 provides a Gemini-tighter version). Pack-coder uses V2's tighter Gemini phrasing for GEMINI.md; AGENTS.md and CLAUDE.md use the full V2 PC-9 BEFORE/AFTER. The substantive rule is identical; presentation differs (this is an editorial-style variant, not a TOOL-SPECIFIC variant). |  |
| STRENGTHEN Commit message format (V11-10) | UNIVERSAL substantive rule, but GEMINI.md uses condensed single-line form (per existing GEMINI.md line 38). Pack-coder expands GEMINI.md to include the V11-10 approved-suffixes enumeration in compact style; CLAUDE.md and AGENTS.md use the full V11-10 BEFORE/AFTER block. Substantive rule identical; presentation differs. |  |

### §3.4 — Implementation order

1. Pack-coder writes the master CLAUDE.md `## Pack memory` content per V2 §B / §C / §E / §F.1 / §F.2 / §F.3 (replaces lines 94-207 of current CLAUDE.md).
2. For each bullet, pack-coder applies §3.1 criteria + §3.3 classification table. Coder may flag any disagreement with the planner's §3.3 classification in the IMPL-REPORT (coder is the on-the-ground judge per the criteria — planner's classification is the starting point, not binding).
3. Pack-coder writes AGENTS.md `## Pack memory` content: universal bullets byte-copied from CLAUDE.md master; tool-specific bullets rewritten per the §3.2 research-mapped table. Preserve AGENTS.md preamble (lines 1-87) and any trailing content unchanged.
4. Pack-coder writes GEMINI.md `## Pack memory` content: same approach (universal byte-copy + per-CLI variant per §3.2). Preserve GEMINI.md preamble (lines 1-71) AND retain the existing "Gemini CLI operating notes" section at the bottom (lines 167-176) unchanged.
5. Pack-coder produces the per-bullet substantive-rule table for Pack Chat's commit-approval review (table goes in the IMPL-REPORT, NOT in the trinity files). Table columns: `Bullet title | Classification | Substantive rule (one-line summary) | CLAUDE.md wording differs from AGENTS.md? | CLAUDE.md wording differs from GEMINI.md?`. Pack Chat reads this table at commit-approval time to verify the substantive rule is preserved across all 3 trinity files even where machinery wording differs.

### §3.5 — Updated trinity consistency check

Replaces the prior "diff must return empty" check.

**Step 1 — Universal bullets** (per §3.3 classification): pack-coder extracts each universal-classified bullet's text from CLAUDE.md and from AGENTS.md and from GEMINI.md (via section/anchor matching — by bullet title). For each universal bullet, `diff` between CLAUDE.md version and AGENTS.md version MUST return empty; same for CLAUDE.md vs GEMINI.md. This check applies BULLET-BY-BULLET, not the full Pack-memory section at once.

Tooling: pack-coder writes a small helper script (Python or bash) that:
- Reads the §3.3 classification table from this plan doc
- For each UNIVERSAL bullet: extracts the bullet text from each trinity file by bullet-title match
- Diffs CLAUDE.md vs AGENTS.md and CLAUDE.md vs GEMINI.md per bullet
- Reports any non-empty diff

**Step 2 — Tool-specific bullets** (per §3.3 classification): pack-coder produces the per-bullet substantive-rule table per §3.4 step 5. Pack Chat reads this table during commit-approval review. No automatic `diff` check — variants WILL differ in body text by design. Verification is substantive-rule-match (human read), not byte-match.

**Step 3 — Claude-only sub-section** (`### Sub-agent behavior (Claude-only)`): present in CLAUDE.md ONLY. Verification: grep for `### Sub-agent behavior (Claude-only)` in AGENTS.md and GEMINI.md — both MUST return zero matches. Trinity exemption note within the sub-section explains why.

**Trinity-rule reporting in IMPL-REPORT:** pack-coder's IMPL-REPORT carries three artifacts:

1. The per-bullet substantive-rule table (§3.4 step 5).
2. The universal-bullet diff output (§3.5 step 1) — should be empty; any non-empty diff is a coder bug to fix before reviewer spawn.
3. The Claude-only-sub-section grep result (§3.5 step 3) — should be zero matches.

Pack Chat reviews all three at commit-approval time before staging 19b-1.

---

## §4 — L.4 script spec (commit 19b-6)

This section gives pack-coder enough detail to write the script without inventing design.

**Script language:** Python 3.12 (Python 3 stdlib only — no PyYAML or external deps, to keep the script standalone and self-contained).

**Script location during run:** `/tmp/cleanup-19b-memory-regen.py` (lives outside repo so it does NOT accidentally land in any commit). Pack-coder creates the script, runs it, verifies output, then deletes the script.

**Inputs:**
- Read directory: `~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/`
- Disposition table: hard-coded inside the script (29 entries from §2 / V2 §F)
- §D.3 template body: hard-coded inside the script
- MEMORY.md index template: hard-coded inside the script

**Script steps:**

1. **Enumerate files.** Read MEMORY.md to enumerate 29 memory files (or alternatively `os.listdir` the memory directory and filter for `*.md` files NOT named `MEMORY.md`).

2. **Per file: parse frontmatter.** Each `feedback_*.md` and `reference_*.md` has a YAML frontmatter block bracketed by `---` lines. Parse with a simple state-machine (no PyYAML needed): split on `\n---\n` (or first/second `---` line) to extract frontmatter and body. Within frontmatter, extract `name`, `description`, `metadata.type`, `metadata.originSessionId` (or `originSessionId` at top level — actual file format varies; planner observed both top-level `originSessionId` and nested `metadata.originSessionId` in the wild).

3. **Backup.** Before writing the transformed file, copy current file to `<file>.bak-19b-cleanup` in the same directory. Used for L.4 failure-recovery rollback.

4. **Per file: apply disposition** (from hard-coded table):
   - **POINTER:** write new file body per V2 §D.3 template:
     - Frontmatter: preserve `name`, `description`, `originSessionId`. Add `metadata.node_type = memory`, `metadata.type = feedback|reference` (preserve original `type` if present), `metadata.trinity_anchor = <V2 §F disposition path/section/bullet>`.
     - Body: §D.3 boilerplate. The trinity_anchor placeholder is replaced with the live anchor string from the disposition table (e.g., for file 1 `feedback_clarg_trinity.md`, the anchor is `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md#trinity-rule-claudemd-agentsmd-geminimd`; bullet name "Trinity rule").
   - **STANDALONE:** no transform; leave file unchanged. Only file with this disposition is `feedback_no_prefix_chars.md`.
   - **EDIT-IN-PLACE-then-POINTER:** for `feedback_review_fix_one_cycle.md`: STEP A — apply the V2 §B (L3) BEFORE/AFTER edit to the existing body (modifies the existing body line 8 wording per the V2 BEFORE/AFTER). STEP B — apply POINTER reduction. Result: file ends up as POINTER (the EDIT-IN-PLACE is intermediate; the final state is POINTER per §F row 14). Net: same as a POINTER reduction, but the architect's EDIT-IN-PLACE wording is captured into the trinity bullet text (which already lands as part of commit 19b-1 via V2 §B L3 trinity bullet text — that bullet IS the strengthened wording promoted, so the memory file's strengthened body content is captured at the trinity anchor and the pointer file is the post-strengthening pointer). **Practical:** treat row 14 as identical to POINTER for the script's purposes, because the strengthened wording is already in the trinity bullet (commit 19b-1) and the pointer just points to that bullet.

5. **Verification subset.** Run on the FIRST 2 files of the disposition table (file 1 `feedback_clarg_trinity.md` and file 2 `feedback_no_destructive_without_approval.md`). Pack-coder writes a hand-written REFERENCE file for these 2 files matching the §D.3 template (1-time hand-write, ~10 minutes of effort, against the V2 §F dispositions). Diff script output against the hand-written reference using `diff`. If diffs match: continue with remaining 24 files. If diffs differ: pack-coder fixes script; re-runs against the same 2 files; repeats verification until diff is clean. Then runs on all 27 remaining files.

6. **MEMORY.md index regeneration.** After all per-file transforms succeed: regenerate MEMORY.md per V2 §D.3 template. Index entries one line per file in the same order as the current MEMORY.md (preserves enumeration order). Each line: `[<title>](<filename>) — <description from frontmatter>`. STANDALONE entries (only `feedback_no_prefix_chars.md`) get the same format but without the trinity-anchor implication.

7. **Script self-deletion preparation.** Script does NOT self-delete. Pack-coder runs script, verifies output, reports the script path to Pack Chat. Pack Chat deletes script via `rm /tmp/cleanup-19b-memory-regen.py` AFTER commit 19b-6 lands and is approved.

**Verification gates pack-coder runs:**

```bash
# 1. Every POINTER file has trinity_anchor field
grep -L 'trinity_anchor:' ~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_*.md ~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/reference_*.md ~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/project_*.md
# Expected: only feedback_no_prefix_chars.md returned (the sole STANDALONE)

# 2. Every POINTER file has the boilerplate "Tier-1.5 pointer cache" phrase
grep -L 'Tier-1.5 pointer cache' ~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_*.md ~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/reference_*.md ~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/project_*.md
# Expected: only feedback_no_prefix_chars.md returned

# 3. MEMORY.md index has 29 entries (28 POINTER + 1 STANDALONE)
grep -c '^- \[' ~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/MEMORY.md
# Expected: 29
```

**Failure recovery per L.4 (iterative; no one-cycle limit on this commit):** if any verification fails OR script run produces broken files, Pack Chat issues `cp <file>.bak-19b-cleanup <file>` for each broken file (NOT `git checkout HEAD -- <files>` — memory files live OUTSIDE repo so `git checkout` does not apply). Pack Chat then SendMessages the same pack-coder instance with the failure detail; coder fixes script; re-runs. The `.bak-19b-cleanup` files exist as a result of script step 3. Loop until clean — per Pack-Chat 2026-05-17 directive, no one-cycle limit applies to this commit. After successful commit lands, Pack Chat deletes all `.bak-19b-cleanup` files via `rm ~/.claude/projects/.../memory/*.bak-19b-cleanup`.

**Pack-coder stays alive within the commit lifecycle** per L.4 binding: Pack Chat does NOT close the pack-coder agent between script-write, script-test, script-run, and verification. The pack-coder agent is closed AFTER commit 19b-6 lands and before commit 19b-7 spawns (the next coder).

---

## §5 — Verification matrix

| Commit | `python3 scripts/validate-pack.py` | Trinity-consistency check (refined per §3.5) | Other verification |
|---|---|---|---|
| 19b-1 | PASS required | MANDATORY per §3.5 — (a) universal-bullet diffs MUST return empty per §3.5 step 1; (b) tool-specific-bullet substantive-rule table MUST be present in IMPL-REPORT per §3.5 step 2; (c) Claude-only sub-section grep MUST return zero matches in AGENTS.md / GEMINI.md per §3.5 step 3. Pack Chat reads all three artifacts at commit-approval. | Manual section-by-section diff against V2 §I.1 ToC; spot-check 3 new bullets in CLAUDE.md against V2 §B verbatim text; coder may flag §3.3 classification disagreements in IMPL-REPORT; pack-reviewer spawn AFTER §3.5 checks pass. **Validator update verification (if applied per §6.3):** `validate-pack.py` PASS on the new §3-refined trinity content; existing trinity tests still PASS; net check-count unchanged (the trinity check is REFINED, not REMOVED). |
| 19b-2 | PASS required | n/a (PACK-CHAT.md is not trinity) | Manual diff vs V2 §B (PC-2/PC-6/V11-1/V11-2/V11-5/V11-7/V11-8) verbatim; manual diff of L.2 action-item note vs planner spec above; pack-reviewer spawn |
| 19b-3 | PASS required | n/a | Manual diff of inserted bullet vs V2 §E.3 verbatim; visual confirmation that bullet sits between "Forward-pointing note" (line 187) and "Skill and agent maintenance" (line 189); no per-commit reviewer |
| 19b-4 | PASS required | n/a | Manual diff of replacement §B vs V2 §B (PC-1) verbatim + L.6 forward-only addition; pack-reviewer spawn |
| 19b-5 | PASS required | n/a | Pack-coder report enumerates V11-12/13/14 outcomes (edit / no-edit) per L.5; V11-15 grep audit confirms zero non-historical hits; if edits made, manual diff vs V2 verbatim; per-commit reviewer ONLY if substantive edits made |
| 19b-6 | PASS required (rerun for safety; should be unaffected by memory file changes) | n/a (memory files are outside repo) | Pack Chat reads MEMORY.md post-script; opens 2-3 random pointer files; runs grep checks per §4; verifies `.bak-19b-cleanup` files removed; verifies `/tmp/cleanup-19b-memory-regen.py` removed. Pack-Chat-direct verification only; no reviewer spawn. Iterative script-fix-cycles allowed per L.4 (no one-cycle limit). |
| 19b-7 | PASS required | n/a | `ls maintenance-docs/archive/v11/ARCHITECTURE-CLEANUP-BATCH-19B*.md` returns both V1 + V2; `ls maintenance-docs/v11-implementation/CLEANUP-INPUTS*.md` returns empty; `ls maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19B*.md` returns empty; `ls maintenance-docs/v11-implementation/PLAN-CLEANUP-BATCH-19B.md` returns "file not found" (it has been moved); no per-commit reviewer |
| End-of-batch broad reviewer | n/a | n/a | Reviewer reviews `git diff main..HEAD` covering all 7 commits; finds cross-commit drift if any (including any per-CLI variant drift from §3 expected mapping); mandatory before "batch close" |

**`validate-pack.py` failure modes most likely to fire** (per Check enumeration in scripts/validate-pack.py):
- Trinity-parity check (if validate-pack has one for pack-root trinity — confirm via running the validator). Pack-coder runs the validator after each commit's staged edits to catch this early.
- Reference-doc-exists checks (if any new reference paths in inserted bullets — e.g., the V11-19 bullet references `project-template/CLAUDE.md` § "Deferral comments and BACKLOG hygiene"; the L9 bullet references `maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md`; pack-coder confirms those paths exist).
- Workflow-artifact pattern check (CLAUDE.md "Skill and agent maintenance is mechanical by default" STRENGTHEN edit adds new patterns to the enumerated list; validate-pack may or may not parse this — pack-coder runs it to confirm).

**Important on validate-pack trinity check:** if `validate-pack.py` has a built-in trinity-parity check that does byte-comparison of all 3 files' `## Pack memory` sections, that check WILL FAIL after the §3-refined edits land (because tool-specific bullets are intentionally different by design). Resolution path is PRE-DETERMINED per §6.3 — coder updates the validator within commit 19b-1 scope to match §3.5 refined consistency semantics. See §6.3 for the binding direction and rationale.

---

## §6 — Open questions

**6.1 — V2 §F.3 vs V2 §I.1 placement of `feedback_planner_user_review_before_coder` trinity bullet.**

V2 §F.3 explicit text says "ADD as a bullet inside trinity `### Agent invocation rules` (after PC-11 bullet, before the L8 PREFLIGHT bullet)." V2 §I.1 ToC lists "Planner output → user review → coder spawn [F.3 — NEW]" under `### Workflow` (line 1470 of V2). These conflict. **Planner resolution applied:** follow §F.3 explicit placement (Agent invocation rules), not the §I.1 ToC. Rationale: §F.3 is the authoritative text-and-placement directive; §I.1 is a summary ToC that may have minor editorial inconsistency.

**6.2 — `feedback_clarg_trinity.md` trinity anchor.**

V2 §F row 1 says POINTER points to "trinity `**Trinity rule**` section (not in `## Pack memory` — it is in the top-level rules block)." The `**Trinity rule**` text in CLAUDE.md is at lines 71-77 in the current file. The pointer-file template requires a `<anchor-id>` after the `#`; markdown headers normally use kebab-case slugs but `**Trinity rule**` is bold text, not a header. The script will use the symbol pointer "`**Trinity rule —**`" (full first-line context) rather than a markdown anchor; pack-coder produces an anchor string that resolves UNAMBIGUOUSLY in human reading (e.g., `→ /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md Rules-for-agents section > "Trinity rule — CLAUDE.md / AGENTS.md / GEMINI.md" bullet`). This is a minor textual detail; not a blocker.

**Resolution:** pack-coder applies judgment per the §4 spec; script generates a human-readable anchor string (not a HTML anchor); resolves unambiguously.

**6.3 — validate-pack.py trinity-parity check vs §3 per-CLI variants (PRE-DETERMINED per Pack-Chat 2026-05-17 directive).**

**Direction (binding):** during commit 19b-1, pack-coder discovers whether `validate-pack.py` has a trinity-parity check that does byte-comparison on `## Pack memory` content (or anywhere else affected by §3-refined per-CLI variants). If such a check exists AND it trips on the §3-refined edits, the coder updates the validator within commit 19b-1 scope to match the §3.5 refined consistency semantics:

1. **Universal bullets** byte-identical across CLAUDE.md / AGENTS.md / GEMINI.md.
2. **Tool-specific bullets** carry the same substantive rule across all 3 files but body wording may differ.
3. **The Claude-only sub-section** (`### Sub-agent behavior (Claude-only)`) is present in CLAUDE.md only and absent from AGENTS.md / GEMINI.md.

The validator's check should enforce these three semantics, NOT pure byte-comparison.

**Sub-commit split if substantial:** if the validator update is substantial (more than ~20 lines or affects other check call sites), the coder splits it into a sub-commit (19b-1a validator update + 19b-1b trinity restructure) and reports rationale in the IMPL-REPORT. Pack Chat surfaces both sub-commits for separate user approval.

**Rationale (why the three-option framing was rejected — for future readers):**

- **(a) accept validator failure as the §3 refinement's expected cost — REJECTED.** Violates the pack rule that CI must be green (trinity `## Pack memory > ### Repo conventions` standing rule "CI validation: The `Validate Pack` GitHub Actions workflow runs on every push. If it fails, fix before proceeding."). Not an option.
- **(c) tighten the §3 mapping to preserve byte-identity — REJECTED.** Would warp the correct design (per-CLI variants for tool-specific bullets) to fit a flawed validator. The §3 refinement reflects the trinity rule's actual semantics with its tool-specific exemption (`feedback_clarg_trinity`: "modify all three together UNLESS the change is provably tool-specific"). The validator must match the rule, not vice versa.
- **(b) loosen the validator — the only acceptable resolution.** The validator update is small-scope (refine one check's logic from byte-comparison to substantive-parity per §3.5 semantics); falls within pack-coder edit scope as part of commit 19b-1 (or split per the sub-commit rule above).

**Underlying principle:** a validator's purpose is to enforce the actual design rule. If a validator enforces a stricter rule than the actual design (here: byte-identity ignoring the tool-specific exemption), the validator is incorrect. §3 refinement is correct work; the check updates to match — not the work.

**6.1 and 6.2 are RESOLVED — planner has chosen disposition. 6.3 is PRE-DETERMINED — coder updates validator per the binding direction above; no Pack-Chat surfacing required unless the validator update exceeds the sub-commit threshold (in which case the sub-commit split is the surfacing). NO escalation to Pack Chat needed pre-spawn.**

---

## §7 — Estimated commit count + per-commit work-size

| Commit | Architect §H | Planner | Per-commit work-size | Justification for any delta |
|---|---|---|---|---|
| 19b-1 | Commit 19b-1 | 19b-1 | LARGE — ~300 added/changed lines × 3 trinity files = ~900 line-diff; high risk of trinity-parity bugs; per-CLI variant production adds ~30 minutes of coder effort | Same scope; refinement per §3 (per-CLI variant strategy replaces byte-identical strategy) |
| 19b-2 | Commit 19b-2 | 19b-2 | MEDIUM — 7 bullets × ~10 lines = ~70 added lines + 1 action-item note ~15 lines = ~85 line-diff | Added L.2 action-item note per planner spec; ~15 line additional |
| 19b-3 | Commit 19b-3 | 19b-3 | SMALL — 15-line PREFLIGHT obligation addition | Same |
| 19b-4 | Commit 19b-4 | 19b-4 | MEDIUM — ~50-line §B full replacement | Same + L.6 forward-only addition (~5 lines) |
| 19b-5 | Commit 19b-5 | 19b-5 | SMALL — empirically zero source edits expected per planner pre-check | Same |
| 19b-6 | Commit 19b-6 (Pack Chat direct) | 19b-6 (pack-coder script-driven) | LARGE — 29 memory files transformed; script lives in `/tmp` outside repo | Override per L.4 — pack-coder runs script, not Pack Chat hand-edits |
| 19b-7 | Commit 19b-7 (FINAL) | 19b-7 | SMALL — 5-6 `git mv` operations | Same + added PLAN-CLEANUP-BATCH-19B.md + IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-*.md per task spec |

**Total: 7 commits.** Matches V2 §H count exactly. No commits added or removed; only the overrides above (per L.4 + L.2 + L.6 + Pack-Chat 2026-05-17 §3 refinement) are reflected within existing commit boundaries.

---

## §8 — Dependencies between commits

```
19b-1 (trinity restructure with §3 per-CLI variants)
   ↓ MUST PRECEDE
19b-2 (PACK-CHAT.md additions — some bullets reference trinity sections by name; if 19b-2 commits first, the references are dangling)
19b-3 (PACK-AGENTS.md addition — references trinity bullet by name; if 19b-3 commits first, the reference is dangling)
19b-4 (EXECUTION-PLAN-V11.0.md §B rewrite — references `## Pack memory` memory anchors by slug name)
19b-6 (memory file pointer reduction — every pointer file's trinity_anchor field must resolve to a live trinity bullet; 19b-1 establishes those anchors)
   ↓
19b-5 (V11-12/13/14/15 — no dependency on 19b-1..19b-4 trinity edits; can run in any order after 19b-1)
   ↓
19b-6 (pack-coder script-driven memory regen — DEPENDS on 19b-1 for trinity bullet titles; per-CLI variant bullets in CLAUDE.md are the authoritative trinity anchors for the Claude memory cache)
   ↓
19b-7 (FINAL — archives all batch artifacts including PLAN-CLEANUP-BATCH-19B.md itself + IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-*.md; depends on all prior commits being landed)
```

**Strict ordering required:** 19b-1 BEFORE 19b-2, 19b-3, 19b-4, 19b-6. Within that constraint, 19b-2, 19b-3, 19b-4, 19b-5 can run in any order (no inter-dependencies). 19b-6 MUST run after 19b-1 (uses trinity anchors). 19b-7 MUST run last (archives this PLAN doc itself).

**Recommended order** (V2 §H order, retained):

```
19b-1 → 19b-2 → 19b-3 → 19b-4 → 19b-5 → 19b-6 → 19b-7
```

**Why this order:** matches V2 §H exactly; landings build naturally from "core trinity rules" outward to "memory cache pointer-reduction" to "archive workflow artifacts." End-of-batch broad reviewer pass runs after 19b-7 (against the full `main..HEAD` diff) and before any user-initiated final audit.

---

## §9 — What this plan does NOT do

Per task constraints, this plan:

- Does NOT introduce new design decisions. All design is the V2 architect's; §3 refinement is per Pack-Chat 2026-05-17 binding directive (research-mapped, not invented).
- Does NOT modify the V2 architect's BEFORE/AFTER text. Bullets are pasted verbatim per the V2 doc; per-CLI variants for tool-specific bullets are derived mechanically from the §3.2 research-mapped table, not invented.
- Does NOT change V2 §B disposition codes. KEEP/STRENGTHEN/CONSOLIDATE/REDIRECT/PROMOTE/DISCARD/NEW-HOME/NEW-BD per V2 §B all preserved.
- Does NOT propose new BDs. Per OQ-1 + L.1, this batch opens NO new BDs.
- Does NOT modify the per-entry-split architect docs (PM-owned). L.2 surfaces the divergence as a Pack-Chat action-item note in PACK-CHAT.md.
- Does NOT modify project-template trinity. Per OQ-3 + V2 §A.8 / §A.9, pack-self only.
- Does NOT add a per-commit reviewer where the commit is mechanical or trivial. Per L.3 binding + planner judgment + Pack-Chat 2026-05-17 directive on 19b-6, 19b-3 / 19b-5 (if no-edit) / 19b-6 / 19b-7 skip per-commit review and rely on the end-of-batch broad reviewer pass.
- Does NOT pre-decide V11-12/13/14 outcomes; pack-coder verifies and reports per L.5.
- Does NOT modify line counts to reduce trinity size below the 200-line soft cap. Per L.3, accept ~310-line CLAUDE.md.
- Does NOT pre-resolve the validate-pack-trinity-parity question (OPEN QUESTION 6.3); coder surfaces at IMPL-REPORT time.

End of PLAN-CLEANUP-BATCH-19B.md.
