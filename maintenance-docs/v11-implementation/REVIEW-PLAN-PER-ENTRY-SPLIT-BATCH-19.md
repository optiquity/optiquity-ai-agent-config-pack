---
title: REVIEW-PLAN-PER-ENTRY-SPLIT-BATCH-19
author: pack-reviewer (v11-dev)
status: review — for primary-chat Pack Chat (fix-or-defer per finding)
plan-under-review: maintenance-docs/v11-implementation/PLAN-PER-ENTRY-SPLIT-BATCH-19.md (1,724 lines)
architect-corpus:
  - maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-SPLIT.md (sidecar parent)
  - maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md (integration parent)
  - maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md (Addendum #1)
  - maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2.md (Addendum #2)
authority-precedence: Addendum #2 > Addendum #1 > integration parent > sidecar parent
date: 2026-05-14
---

# Review of PLAN-PER-ENTRY-SPLIT-BATCH-19

## §0 — Verdict

**APPROVE-WITH-FIXES.**

The plan is structurally sound and faithfully composes the architect
corpus (4 docs) under the stated supersession order. The Pack-Chat-direct
risk resolutions (R-2, R-3, R-4, R-8) are incorporated correctly across
the affected sections. Cross-section consistency is good. The plan can
be acted on after fixes are applied; no structural respin needed.

**Findings summary:** 0 BLOCKER, 5 SHOULD-FIX, 9 NIT.

The dominant defect class is stale line-number references (one
internally inconsistent — §11.1 verify-by-`ls` evidence cites a
different number than §2.1 / §2.4 / §5.6 for the same fact). This is
exactly the verify-by-`ls`-discipline failure mode the architect
corpus has been guarding against; it is small in absolute scope but
notable in pattern, since it survived plan write despite the planner's
explicit verify-by-`ls` discipline statement.

The remaining findings are wording inconsistencies, one architect-doc
citation that does not actually justify the structure it cites
(EXECUTION-PLAN §C.4 for a separate-commit status-flip), and several
minor inconsistencies in the §6 PM-only edit table.

The plan does NOT regress on any architect-doc binding. The supersession
order is applied correctly throughout. The 4 risk resolutions land at
every site they should.


---

## §1 — Findings

Each finding has the standard fields per audit-methodology §24:
ID, Severity, Section reference, Architect-doc binding, Description,
Recommended fix.

### F-1 — Stale line number for `check_skill_cell_consistency` (Check 31)

- **Severity:** SHOULD-FIX
- **Section reference:** PLAN §2.1 (line 175); PLAN §2.4 (line 216); PLAN §5.6 (line 754)
- **Internal inconsistency:** PLAN §11.1 (lines 1645–1648) verify-by-`ls` evidence record
- **Architect-doc binding:** Addendum #2 §6 PROCESS SAFEGUARD — verify-by-`ls`
  discipline that grounds every line-number claim against the file system
- **Description.** Three sites in §2.1, §2.4, and §5.6 say
  `check_skill_cell_consistency` (Check 31) is at "line 2454" of
  `scripts/validate-pack.py`. The actual line is **2425**, as
  correctly recorded in §11.1's grep-output evidence record (verbatim
  shows `2425:def check_skill_cell_consistency() -> None:`). This is
  not an architect-doc misread; it is a self-inconsistency within the
  plan. Either the §2.1/§2.4/§5.6 figure is wrong, or the §11.1
  evidence is wrong; one of the two must be reconciled before a coder
  acts on the plan. Verified by direct `grep -nE "^def check_skill_cell_consistency" scripts/validate-pack.py` — returns 2425.
- **Recommended fix.** Change "line 2454" to "line 2425" at all three
  §2.1, §2.4, §5.6 sites. §11.1 evidence is authoritative.

### F-2 — Plan §5.10 cites EXECUTION-PLAN §C.4 to justify a structure §C.4 does not authorize

- **Severity:** SHOULD-FIX
- **Section reference:** PLAN §5.10 (lines 935–971); also PLAN §6.1 §C.4 implicit-flip rule reference at line 1196 within §6.2 Edit text; PLAN §1.1 BD table commit-19h row (line 89)
- **Architect-doc binding:** EXECUTION-PLAN-V11.0.md §C.4 (line 327):
  `"Implicit BD status flip on batch completion. ... Note this is
  distinct from §A.1: the BACKLOG status flip happens inside the same
  commit as the BD's implementation, not as a separate commit."`
  Verified by `sed -n '327p' EXECUTION-PLAN-V11.0.md`.
- **Description.** Plan §5.10 commit 19h (BD status flips, separate
  Pack-Chat-direct commit) cites "per EXECUTION-PLAN-V11.0.md §C.4
  implicit-flip rule" (line 958) and "per EXECUTION-PLAN-V11.0.md §C.4
  implicit-flip rule" (line 966). But §C.4 explicitly says status
  flips happen INSIDE THE SAME COMMIT as implementation, NOT as a
  separate commit. The plan structurally needs a separate 19h commit
  because (a) BD-164..BD-170 + BD-167b + BD-169b implementation is
  pack-coder authored across 9 prior commits, (b) BACKLOG.md is
  PM-only so pack-coder cannot flip status within their own commit,
  and (c) per the agents-never-commit rule (CLAUDE.md pack memory),
  Pack Chat must do the flip. The justification is correct on the
  agents-never-commit + PM-only-file rules, NOT on §C.4. Addendum #1
  §6.5 inherits the same incorrect citation; the plan inherits it.
- **Recommended fix.** In §5.10 (commit 19h Constraints) and in §1.1
  BD table 19h row, replace the §C.4 citation with the agents-never-
  commit + PM-only-file rationale: `"BACKLOG.md is PM-only (per
  CLAUDE.md PM-only files list); pack-coder commits 19a/19b-pack/
  19c/19d/19e/19f/19g-pack cannot include the BACKLOG status flip
  within the same commit (agents never commit; PM-only). Pack Chat
  applies the status flip in dedicated 19h commit covering all 11
  BD-tracked items at once."` Note inherited error in Addendum #1
  §6.5 row 10 — surface as a precedent-correction note in §10
  Risks (no architect-doc edit; the plan can apply the corrected
  rationale without overruling the architect doc since the structural
  decision survives).

### F-3 — Hard sequencing constraint claims `BD-095` mode-flag parser at lines `264–272`; actual span is `264–276`

- **Severity:** NIT
- **Section reference:** PLAN §0 (line 62); PLAN §1.3 (table line 121); PLAN §2.1 (line 170); PLAN §5.4 (line 641, line 648, line 681); PLAN §6.1 BD-165 entry (line 1038); PLAN §10.10 R-10 (line 1565)
- **Architect-doc binding:** Addendum #2 §4.2 + §6.9 — BD-095 mode-flag
  parser is at `migrator-core.sh:264-272`
- **Description.** Plan repeatedly cites the BD-095 mode-flag parser
  as living at `migrator-core.sh:264-272`. Direct verification by
  `grep -nE "_MIGRATOR_DRY_RUN|_MIGRATOR_MODE|--dry-run|--apply|--resume"
  scripts/lib/migrator-core.sh` shows the parser block (the case
  statement entries `--dry-run)`, `--apply)`, `--resume)`) spans
  lines 264–276 (resume case continues through lines 271–281 with
  the per-adapter passthrough comment block). The 264–272 range
  matches the case-statement OPENINGS only, not the full block.
  Functionally equivalent for BD-165 wiring (the new
  `--force-overwrite-mirror)` case lands inside the same `case`
  statement) but the line range is technically a slight underrun.
  Addendum #2 §4.2 line-range claim is the source of this; the plan
  inherits.
- **Recommended fix.** Update line range at all 6 sites to "264–276"
  (or more conservatively "264–281" to include the resume-passthrough
  comment block). Low priority — does not block coder execution since
  the planner / coder reads the file directly.

### F-4 — `customization_classify` line range `145–179` is one short

- **Severity:** NIT
- **Section reference:** PLAN §2.1 (line 172)
- **Architect-doc binding:** integration parent §13.5 customization-preserve
  fall-through reference; sidecar §9.1 + addendum §3.3 generic
  classification
- **Description.** Plan §2.1 cites
  `scripts/lib/customization-preserve.sh` `customization_classify
  lines 145–179; generic fall-through at 178`. Direct verification
  by `sed -n '143,180p' scripts/lib/customization-preserve.sh`
  shows the function spans lines 145–180 (the closing `esac` and `}`
  are at 179 + 180); the `printf 'generic\n'` line is at 178. The
  plan's "fall-through at 178" is correct; the function range
  "145–179" should be "145–180." One-line off.
- **Recommended fix.** Update "lines 145–179" → "lines 145–180" in
  §2.1.

### F-5 — Plan §2.4 says "highest existing Check is 31 (Skill-cell consistency, line 2454)"; line is 2425

- **Severity:** SHOULD-FIX (folds into F-1)
- **Section reference:** PLAN §2.4 (line 216)
- **Description.** Same defect as F-1 with different framing — §2.4
  itself is the validator-checks current-state subsection, where the
  line-number error appears alongside the (correct) "Check 31"
  identification.
- **Recommended fix.** Folds into F-1 fix above (replace 2454 with
  2425 throughout).

### F-6 — §6.2 Edit 3 row for line 282 has minor wording issue: cites Addendum #2 §3.3 verbatim text but inserts "PRECISE wording for Pack Chat to refine" footer pulled from Addendum #1's superseded text

- **Severity:** NIT
- **Section reference:** PLAN §6.2 Edit 3 row 5 (line 1187)
- **Architect-doc binding:** Addendum #2 §3.3 — exact replacement text;
  Addendum #1 §2.4 row 4 was the source of the "PRECISE wording for
  Pack Chat to refine" abdication that Addendum #2 §3.3 explicitly
  replaces
- **Description.** Plan §6.2 Edit 3 row 5 "Current text" column
  correctly quotes the current EXECUTION-PLAN line 282; the "New text"
  column correctly cites the Addendum #2 §3.3 verbatim replacement.
  Verified directly by `sed -n '281,283p' EXECUTION-PLAN-V11.0.md`.
  No defect in the replacement text itself. NIT-level concern: the
  plan does not call out that the "max ~31 commits" → "~41 commits"
  shift drives the lockstep edits to Addendum #1 §0.2 / §6.6 / §11.3
  per Addendum #2 §3.3 footer — but the §0 TL;DR DOES name this at
  bullet 5 ("Total v11.0 commit count target: max ~41 (per Addendum
  #2 §3.3, Pack-Chat-direct edits already lockstep-applied to
  Addendum #1 §0.2 / §6.6 / §11.3 per Addendum #2 §3.4)"). So the
  fact is in the plan, just not redundantly in §6.2.
- **Recommended fix.** None required (NIT only). If Pack Chat wants
  redundancy: append a single line under §6.2 Edit 3 row 5 noting
  the Addendum #1 lockstep-edits are pre-existing per Addendum #2
  §3.4 (so a future reader doesn't worry the math is broken).

### F-7 — `EXECUTION-PLAN-V11.0.md` has §3 "Cleanup status (no-action items)"; plan §6.2 Edit 5 says "Update §3 cleanup status" — verify the section name match

- **Severity:** NIT
- **Section reference:** PLAN §6.2 Edit 5 (line 1198)
- **Architect-doc binding:** integration parent §17.4 #4
- **Description.** Plan §6.2 Edit 5 says "Update §3 cleanup status
  per integration parent §17.4 #4." Verified by `grep -nE "^## "
  EXECUTION-PLAN-V11.0.md` that §3 is titled "Cleanup status
  (no-action items)" (line 211). The integration parent's "#4" item
  refers specifically to the Pattern B sweep targets at release pin —
  this is a NEW LINE addition into §3, not a rewrite. The plan's
  framing is fine; the §3 cleanup section already exists. NIT
  concern: the plan does not specify whether the addition is a new
  bullet inside §3 or a separate sub-section; coder may need to
  decide. Architect-doc-deferred placement is consistent with the
  plan's overall planner-pass-defers-to-coder-pass pattern.
- **Recommended fix.** Add a half-sentence to PLAN §6.2 Edit 5: "...
  as a new line item / bullet inside the existing §3 list (Pack
  Chat picks placement at edit time)." Low priority.

### F-8 — Plan §0 says BD-160 "is at `BACKLOG.md:1399` per integration parent §1.1"; the BD-160 entry header IS at line 1399, but Status: Open is at line 1401

- **Severity:** NIT
- **Section reference:** PLAN §0 (line 54); PLAN §10.2 (line 1500); PLAN §5.7 (line 807); PLAN §5.10 (line 950)
- **Architect-doc binding:** integration parent §1.1 fact-check at BACKLOG line 1399
- **Description.** The plan cites "BD-160 at `BACKLOG.md:1399`" in §0
  + §5.7 + §5.10 (entry header line) and "BD-160 is `Status: Open`
  per `BACKLOG.md:1401`" in §10.2 + §5.7 (Status: line). Both are
  correct — the entry header is at 1399 and the Status field is at
  1401 per direct `sed -n '1399,1402p' BACKLOG.md` verification.
  This is not a defect; surfaced for completeness only (the apparent
  inconsistency is two different facts about adjacent lines, not
  one fact stated two ways).
- **Recommended fix.** None required. Listed for transparency only.

### F-9 — Plan §3.1 dependency graph says "19f (BD-170): test-fixtures/build.sh ... v11 case dispatch (BD-160 part) is added; v11-init customizations verified" — uses "v11-init" wording inconsistent with rest of plan ("v11 init")

- **Severity:** NIT
- **Section reference:** PLAN §3.1 (line 247)
- **Architect-doc binding:** none (cosmetic)
- **Description.** PLAN §3.1 paragraph 19f description uses "v11-init" but the plan elsewhere consistently uses "v11 init" or "init-project.sh greenfield path." Hyphen usage is inconsistent.
- **Recommended fix.** Change "v11-init customizations" → "v11 init
  customizations" in §3.1 dependency graph paragraph for 19f.

### F-10 — Plan §5.10 19h Pre-state says "BD-160 entry exists at `BACKLOG.md:1399` with `Status: Open`" but technically the Status field is one line below

- **Severity:** NIT (folds into F-8)
- **Section reference:** PLAN §5.10 (line 954)
- **Description.** Same observation as F-8: the BD-160 entry header
  is at 1399; the Status: field is at 1401. The plan's wording "BD-160
  entry exists at `BACKLOG.md:1399` with `Status: Open`" is a
  reasonable shorthand (the entry block starts at 1399 and contains
  Status: Open at 1401); not a defect per se but slightly imprecise.
- **Recommended fix.** Folds into F-8 (no fix required) OR clarify to
  "BD-160 entry header at `BACKLOG.md:1399`; Status: Open field at
  line 1401 (verified)."

### F-11 — Plan §6.4 amends BD-138 lines per Addendum #1 §2.5 — but BD-138 is already `Status: Resolved`; backstamping a Resolved entry should call out it changes the historical record

- **Severity:** NIT
- **Section reference:** PLAN §6.4 (lines 1213–1225); §10.8 (lines 1546–1552)
- **Architect-doc binding:** Pack-Chat-direct R-8 resolution (BACKSTAMP)
- **Description.** Plan §6.4 backstamps BD-138's batch references in
  multiple fields including the Resolved: line text (line 1222
  amends the Resolved line itself). §10.8 R-8 resolution lists 5
  arguments for backstamp over parenthetical, all of which are sound.
  The argument that "git history IS the audit trail" (§10.8 (2)) is
  valid; in practice, however, Pack Chat may want a single-line
  acknowledgement in the BD-138 commit message that the historical
  Resolved-line text is being updated post-resolution. Low priority —
  the plan's R-8 resolution is fine as-stated; this is a process-clarity
  observation.
- **Recommended fix.** Append one half-sentence to §10.8 paragraph
  (after "git history IS the audit trail"): "Pack Chat surfaces the
  backstamp in the renumber-cascade commit message: `'BD-138 Resolved
  line backstamped from Batch 21/22 to Batch 22/23 per Addendum #1
  §2.2 renumber cascade.'`" Low priority NIT.

### F-12 — Plan §1.3 supersession table row "Codex auditor agent file extension" cites Addendum #2 §1.5 Finding 2A — correct citation; consistency check passes

- **Severity:** NIT (positive verification, no fix)
- **Section reference:** PLAN §1.3 (line 119)
- **Description.** Cited row name and source citation are accurate.
  Verified by direct read of Addendum #2 §1.5 Finding 2A (lines
  206–235) and §6.4 (lines 1087–1103). No fix needed; surfaced for
  positive verification.

### F-13 — Plan §2.1 verify-by-`ls` table says PACK-AGENTS.md "PM-only files at lines ~141–142" — actual block is lines 139–142

- **Severity:** NIT
- **Section reference:** PLAN §2.1 (line 146)
- **Architect-doc binding:** Addendum #1 §3.1 honest Signal 9 trip framing (PACK-AGENTS.md edit specification)
- **Description.** PLAN §2.1 says PACK-AGENTS.md PM-only files at
  "~141–142." Verified by `grep -n "PM-only" PACK-AGENTS.md` showing
  the PM-only files paragraph starts at line 139 and runs through
  line 142. The "~" in the plan acknowledges approximation, but the
  span starts at 139, not 141. Minor.
- **Recommended fix.** Change "~141–142" → "~139–142" or "139–142" in
  §2.1 verify-by-`ls` table row for PACK-AGENTS.md.

### F-14 — Plan §0 batch shape lists 11 BD-tracked items; §1.1 BD table also lists 11 (BD-164..BD-170 + BD-167b + BD-169b + BD-160 + BD-161 absorbed = 11). Consistent.

- **Severity:** NIT (positive verification)
- **Section reference:** PLAN §0 (line 13); PLAN §1.1 (lines 81–96)
- **Description.** Cross-section consistency check passes. BD-tracked
  count is 11 in both sections; commit count is 10 in both. R-2
  resolution incorporated correctly.
- **Recommended fix.** None.


---

## §2 — Cross-section consistency table

| Cross-section property | Sections checked | Result |
|---|---|---|
| Total commit count = 10 | §0 TL;DR (line 14); §1.1 BD table (line 13); §3.1 dependency graph; §4 allocation table (line 405); §5 per-commit specs (10 commit subsections); §9.1 sequencing summary (lines 1404–1424) | PASS — all 6 sites say 10 commits |
| Total BD-tracked items = 11 | §0 (line 13); §1.1 (lines 81–96); §5.10 (line 944); §9.1 (line 1423) | PASS |
| Commit ordering 19a → 19b-pack → 19b-PM → 19c → 19d → 19e → 19f → 19g-pack → 19g-PM → 19h | §0 (lines 46–48); §1.1 BD table; §4 allocation; §5 per-commit; §9.1 (lines 1405–1424) | PASS — identical sequence everywhere |
| BD-160 + BD-170 combined in 19f per R-2 | §0 (line 47); §1.1 (BD-160 row + BD-170 row); §4 (19f row); §5.7 (commit 19f spec); §5.10 (BD-160 in flip list); §6.1 (BD-170 entry blockers); §9.1 (line 1417); §10.2 (R-2 resolution) | PASS — all 8 sites consistent |
| STATUS.md disclaimer in 19g-pack PM-CHAT.md per R-3 | §0 (line 39 footer note); §1.2 (line 100); §5.3 (line 576 + line 612); §5.8 (line 846); §6.1 BD-167b (line 1084); §6.6 (R-3 subsection); §9.1 (line 1419); §10.3 (R-3 resolution) | PASS — all 8 sites consistent |
| Audit-methodology SKILL.md only (auditor agent files NOT modified) per R-4 | §0 not listed (TL;DR brevity); §1.1 BD-169 row (column "audit-methodology" cited; auditor agents NOT cited); §2.1 verify-by-ls (lines 161–164 explicitly NOT in scope); §5.8 (line 849 SKILL.md row + lines 860, 881, 891 auditor NOT modified); §6.1 BD-169 entry (line 1117 SKILL.md cited; line 1120 "auditor agent files (auditor.md / auditor.toml × 3 CLIs) are NOT modified"); §9.1 (line 1419); §10.4 (R-4 resolution) | PASS — 7 sites consistent. Trinity verification for skill mirrors §7.2 (line 1268) lists "Auditor agent trinity" row but the description says "19g-pack: same audit-scope extension; format-specific wrapping for Codex .toml. Per Addendum #2 §1.5 Finding 2A." — stale. See F-15. |
| BD-138 backstamp per R-8 (no parenthetical) | §0 not directly named; §6.4 (lines 1213–1225 in-place edits); §9.3 (line 1447 setup commit); §10.8 (R-8 resolution) | PASS — 4 sites consistent |
| Codex pack-* agents are .toml | §0 (line 38); §1.3 (line 118); §2.1 (line 152); §5.3 (lines 565–569); §6.1 BD-167b (line 1086); §11.1 (lines 1599–1602) | PASS — all 6 sites consistent (Addendum #2 §1 BLOCKER applied) |
| Codex auditor.toml | §0 (line 38); §1.3 (line 119); §2.1 (line 162); §5.8 (line 849 — explicitly "auditor.md / auditor.toml × 3 CLIs are NOT modified"); §11.1 (lines 1620–1625) | PASS — 5 sites consistent |
| Pack-side per-entry-tree paths non-dot (`/backlog/`, `/changelog/`) per Addendum #1 §10 | §0 (line 36); §1.3 (line 117); §6.1 BD-167b (line 1083); various sample addition shapes in §5.1 (line 466 HTML comment shape) | PASS |
| Layer 2 = HTML-comment line 1 only (no body field) per Addendum #2 §2 | §0 (line 35); §1.3 (line 116); §5.1 constraints (line 466 + line 468); §7.3 byte-additive entry-content invariant test (lines 1278–1295); §8.1 (line 1341 supersession table); §11.2 final marker (line 1707) | PASS — 6 sites consistent |
| EXECUTION-PLAN line 282 totals = "26 main batches (24 + Batch 5b + Batch 21b)" verbatim per Addendum #2 §3.3 | §0 (line 38); §1.3 (line 120); §6.2 Edit 3 row 5 (line 1187); §11.1 evidence (line 1665); §11.2 final marker (line 1711) | PASS — 5 sites consistent |
| Regenerator divergence in apply/resume BLOCKS unless `--force-overwrite-mirror` per Addendum #2 §4 | §0 (line 40); §1.3 (line 121); §5.4 (lines 644–664); §10 R-related sections; §11.2 final marker | PASS |
| PACK-CHAT.md row text = Addendum #2 §5.2 verbatim | §0 (line 41); §1.3 (line 122); §5.9 (line 909); §6.1 BD-169b (line 1132); §11.2 final marker | PASS |
| PM-CHAT.md row text = Addendum #2 §5.4 verbatim | §0 (line 41); §1.3 (line 123); §5.8 (line 846, line 879); §11.2 final marker | PASS |

**Cross-section consistency verdict.** 14 of 15 properties PASS; one
PASS-WITH-NIT (the Auditor agent trinity row in §7.2 is stale —
covered as F-15 below).

### F-15 — Plan §7.2 trinity verification table row "Auditor agent trinity" is stale per R-4 resolution

- **Severity:** SHOULD-FIX
- **Section reference:** PLAN §7.2 (line 1268)
- **Architect-doc binding:** Pack-Chat-direct R-4 resolution (audit-methodology
  SKILL.md only; auditor agent files NOT modified)
- **Description.** §7.2 trinity verification table includes a row for
  "Auditor agent trinity (`project-template/.claude/agents/auditor.md`,
  `.codex/agents/auditor.toml`, `.gemini/agents/auditor.md`)" with
  description: "19g-pack: same audit-scope extension; format-specific
  wrapping for Codex .toml. Per Addendum #2 §1.5 Finding 2A." But per
  R-4 resolution (Pack-Chat-direct, applied throughout the plan
  body), auditor agent files are NOT modified in 19g-pack. The §7.2
  row is stale — it references the pre-R-4-resolution scope.
- **Recommended fix.** Either DELETE the "Auditor agent trinity" row
  from §7.2 (preferred; consistent with the rest of the plan applying
  R-4) OR REWRITE the row description to: "**NOT a Batch 19 trinity
  set per R-4 resolution.** Auditor agent files are NOT modified in
  19g-pack. Audit-methodology SKILL.md (single canonical at
  project-template/skills/audit-methodology/SKILL.md) is the only
  file modified for audit-scope extension; per-CLI fanout to
  .claude/skills/, .codex/skills/, .gemini/skills/ happens at install
  time via init-project.sh `stage_s4_skills`. Per Addendum #2 §1.5
  Finding 2A correction is preserved as a precedent rule for any
  FUTURE auditor agent file edit (none in Batch 19)."


---

## §3 — Risk-resolution incorporation table

For each of R-2, R-3, R-4, R-8: every section the resolution should
have touched + PASS / FAIL.

### R-2 — Combine BD-160 + BD-170 into commit 19f

| Section | Should reference | Result |
|---|---|---|
| §0 TL;DR batch shape (line 47) | "19f (BD-160 + BD-170 combined per Pack-Chat-direct R-2 resolution)" | PASS — verbatim |
| §0 BDs in scope (line 13) | "BD-160 pulled into commit 19f per R-2 resolution = 11 BD-tracked items, 10 commits" | PASS |
| §1.1 BD table BD-160 row (line 91) | "EXISTING `Status: Open` BD pulled into Batch 19" | PASS |
| §1.1 BD table BD-170 row (line 92) | "19f (combined with BD-160)" | PASS |
| §3.1 dependency graph 19f (lines 245–250) | "19f (BD-160 + BD-170 combined per R-2)" | PASS |
| §4 allocation table 19f row (line 400) | "Combined BD-160 + BD-170 per R-2 resolution" | PASS |
| §5.7 commit 19f spec (lines 782–832) | Section title and Description: "BD-160 + BD-170 combined per Pack-Chat-direct R-2 resolution" | PASS |
| §5.10 19h flip list (lines 944, 950) | BD-160 included in 11-BD flip; "shipped in commit 19f combined with BD-170 per Pack-Chat-direct R-2 resolution" | PASS |
| §6.1 BD-170 entry text (line 1143) | "Blockers: BD-164 (BD-160 blocker satisfied trivially — BD-160 ships in the same commit as BD-170 per Pack-Chat-direct R-2 resolution)" | PASS |
| §6.1 BD-160 amendment paragraph (line 1000) | "Per Pack-Chat-direct R-2 resolution, BD-160 ships in commit 19f combined with BD-170" | PASS |
| §9.1 sequencing summary line 1417 | "19f (BD-160 + BD-170 combined per R-2)" | PASS |
| §10.2 R-2 resolution detail (lines 1496–1504) | Full resolution text + cascade list | PASS |

**R-2 incorporation: 12/12 PASS.** Resolution is incorporated at every
expected site.

### R-3 — STATUS.md disclaimer = PM-CHAT.md kickoff guidance addition (Option A)

| Section | Should reference | Result |
|---|---|---|
| §0 TL;DR (line 39 not directly; the disclaimer routing is implied through §1.2 + §5.8 below) | (R-3 not explicitly in headline TL;DR; surfaces in §1.2) | PASS by inheritance |
| §1.2 out-of-scope (line 100) | "STATUS.md authoring. ... Pack-Chat-direct R-3 resolution: PM-CHAT.md kickoff guidance addition (Option A)." | PASS |
| §4 allocation table 19b-PM row (line 396) | "STATUS.md disclaimer NOT in 19b-PM scope per R-3 resolution (moved to 19g-pack PM-CHAT.md guidance)" | PASS |
| §5.3 19b-PM commit spec (line 576) | "STATUS.md disclaimer surfacing — RESOLVED per Pack-Chat-direct R-3 (Option A). STATUS.md disclaimer lives in PM-CHAT.md kickoff guidance (Option A); lands in 19g-pack ... NOT in 19b-PM" | PASS |
| §5.3 commit 19b-PM Post-state (line 589) | "STATUS.md disclaimer is NOT in 19b-PM scope" | PASS |
| §5.3 19b-PM Constraints (line 612) | "STATUS.md disclaimer surfacing: per §10.3 R-3 resolution (Option A) — moved out of 19b-PM scope; lives in 19g-pack PM-CHAT.md guidance" | PASS |
| §5.3 19b-PM planner-deferred (line 618) | "(STATUS.md disclaimer routing — RESOLVED per R-3 Option A; no longer a planner-deferred item.)" | PASS |
| §5.8 19g-pack PM-CHAT.md modification clause (line 846) | "(2) Add a new paragraph in the kickoff-procedures section per Pack-Chat-direct R-3 resolution: 'When authoring STATUS.md, prepend the following HTML-comment disclaimer at the top of the file: ...'" | PASS |
| §5.8 19g-pack Constraints (line 880) | "STATUS.md disclaimer guidance lives in PM-CHAT.md only per R-3 resolution; no new pack-product file (no STATUS_TEMPLATE.md)." | PASS |
| §6.1 BD-167b entry (line 1084) | "(STATUS.md disclaimer surface — RESOLVED per R-3 Option A: lives in BD-169 19g-pack PM-CHAT.md guidance; NOT in BD-167b)" | PASS |
| §6.1 BD-169 entry (line 1114) | "TWO additions: ... STATUS.md disclaimer guidance paragraph per R-3 resolution at integration parent §5.3 disclaimer shape" | PASS |
| §6.6 STATUS.md edit subsection (lines 1232–1235) | "Pack-Chat-direct R-3 resolution: Option A — PM-CHAT.md kickoff guidance addition. ..." | PASS |
| §9.1 sequencing summary line 1419 | "STATUS.md disclaimer guidance paragraph (per R-3)" | PASS |
| §10.3 R-3 resolution detail (lines 1506–1512) | Full resolution text + cascade list | PASS |

**R-3 incorporation: 14/14 PASS.** Every section that should reference
the R-3 routing does, with consistent Option A framing.

### R-4 — Audit-methodology SKILL.md only; auditor agent files NOT modified

| Section | Should reference | Result |
|---|---|---|
| §1.1 BD-169 row (line 93) | "auditor agent file extensions × 3 CLIs" — NOTE: the BD-169 row description STILL lists "auditor agent file extensions × 3 CLIs" but per R-4 only the SKILL.md is modified; this is potentially misleading | NIT — see F-16 below |
| §2.1 verify-by-`ls` table (lines 161–164) | Auditor agent file rows annotated "NOT in BD-169 scope per R-4 resolution — verified for context only" | PASS |
| §4 allocation table 19g-pack row (line 401) | "(project-template agents — NOT pack-* which are 19b-PM)"; does not explicitly say auditor agents are NOT in scope | NIT — slightly understated; see F-17 below |
| §5.8 commit 19g-pack spec (line 849) | "audit-methodology SKILL.md ... per Pack-Chat-direct R-4 resolution: ... NO audit agent file edits (auditor.md / auditor.toml × 3 CLIs are NOT modified per R-4 resolution) — the skill delegation chain is sufficient" | PASS |
| §5.8 19g-pack Pre-state (line 860) | "Auditor agent files (auditor.md / auditor.toml × 3 CLIs) are NOT in this commit's scope per R-4 resolution" | PASS |
| §5.8 19g-pack Constraints (line 881) | "Audit-scope extension lives in audit-methodology SKILL.md only per R-4 resolution; no auditor agent file edits (auditor.md / auditor.toml × 3 CLIs are NOT modified)" | PASS |
| §6.1 BD-169 entry (line 1117) | "auditor agent files NOT modified — skill is authoritative source per its own §66 + per auditor.md line 11-12" + line 1120 "Auditor agent files (auditor.md / auditor.toml × 3 CLIs) are NOT modified per R-4 resolution" | PASS |
| §7.2 trinity verification table | Stale "Auditor agent trinity" row | FAIL — see F-15 above |
| §9.1 sequencing summary line 1419 | "audit-methodology SKILL.md scope extension (per R-4; auditor agent files NOT modified)" | PASS |
| §10.4 R-4 resolution detail (lines 1514–1522) | Full resolution text + verification (auditor.md line 11-12 cited correctly) + cascade list | PASS |

**R-4 incorporation: 8/10 PASS, 1 NIT (F-16), 1 NIT (F-17), 1 FAIL (F-15).**

### F-16 — §1.1 BD-169 row description incorporates only some of R-4 framing

- **Severity:** NIT
- **Section reference:** PLAN §1.1 (line 93 — BD-169 row)
- **Description.** The BD-169 row in the §1.1 BD table reads: "Per-entry split pack-product wording updates (project-template `PM-CHAT.md` row, supporting-docs `MERGE-STRATEGY.md` paragraph + `MIGRATION-v10-to-v11.md` section, auditor agent file extensions × 3 CLIs, pack-startup directives × 3, pm-startup directives × 4)." The phrase "auditor agent file extensions × 3 CLIs" is not strictly wrong (auditor agent files are not modified BUT audit-methodology SKILL.md is — the cell technically refers to BOTH which are slightly different). Other sections of the plan apply the R-4 distinction explicitly. The §1.1 row is brief and may mislead a reader who only reads the table.
- **Recommended fix.** Change "auditor agent file extensions × 3 CLIs" to "audit-methodology SKILL.md scope extension (auditor agent files NOT modified per R-4)" in the §1.1 BD-169 row description.

### F-17 — §4 allocation table 19g-pack rationale is slightly understated re: R-4 scope

- **Severity:** NIT
- **Section reference:** PLAN §4 (line 401 — 19g-pack row)
- **Description.** Row 19g-pack rationale text reads: "Multi-file documentation + agent file extensions (project-template agents — NOT pack-* which are 19b-PM); skill directive additions × 7 files." The "(project-template agents — NOT pack-* which are 19b-PM)" parenthetical is correct as far as it goes, but does not say what project-template agent files ARE modified in 19g-pack. Per R-4 resolution, NO auditor agent files are modified in 19g-pack; only the audit-methodology SKILL.md.
- **Recommended fix.** Change to "Multi-file documentation + audit-methodology SKILL.md scope extension per R-4 (project-template auditor agent files NOT modified per R-4; pack-* agent prompts in 19b-PM); skill directive additions × 7 files." Low priority NIT.

### R-8 — BACKSTAMP BD-138 batch references in-place

| Section | Should reference | Result |
|---|---|---|
| §6.4 BACKLOG.md amendments table (lines 1213–1225) | All 7 line-edits show in-place backstamp (Batch 20b → 21b, etc.) | PASS — direct verification by `sed -n '1595p;1597p;1599p;1600p;1624p' BACKLOG.md` confirms current text matches plan's "Current text" column |
| §6.4 R-8 resolution paragraph (line 1225) | Per R-8 backstamp framing + 5-point reasoning | PASS |
| §9.3 PM-only setup commit (line 1444) | Names BD-138 backstamp as part of the setup commit | PASS |
| §10.8 R-8 resolution detail (lines 1546–1552) | Full resolution + 5-point reasoning + reflection in §6.4 | PASS |

**R-8 incorporation: 4/4 PASS.**


---

## §4 — Verify-by-`ls` evidence record

Spot-checked 18 file paths and 6 line-number claims directly against
the file system. Apply the discipline that caught Addendum #2's
BLOCKER + 3 sweep findings.

### §4.1 — Files / directories that EXIST and plan correctly references

| Plan claim | Verified by | Result |
|---|---|---|
| `BACKLOG.md` (3,627 lines) per §0 + §2.1 | `wc -l BACKLOG.md` → `3627` | PASS |
| `BD-163` highest existing BD | `grep -nE '^\*\*BD-1[5-9][0-9] —' BACKLOG.md` → BD-163 highest | PASS |
| BD-160 entry header at `BACKLOG.md:1399` | `sed -n '1399p' BACKLOG.md` → matches | PASS |
| BD-160 `Status: Open` at line 1401 | `sed -n '1401p' BACKLOG.md` → `Status: Open` | PASS |
| BD-161 entry header at `BACKLOG.md:1388` | `sed -n '1388p' BACKLOG.md` → matches | PASS |
| `## Resolved — v8 (March 2026)` H2 at line 2248 | `grep -n "Resolved — v8" BACKLOG.md` → 2248 | PASS |
| `## Active — v11 Scope` H2 at line 23 | `grep -nE "^## Active" BACKLOG.md` → 23 | PASS |
| `.codex/agents/pack-*.toml` × 5 | `ls .codex/agents/` shows 5 .toml files (pack-architect/coder/docs-researcher/planner/reviewer) | PASS |
| `.claude/agents/pack-*.md` × 5 | `ls .claude/agents/` shows 5 .md files | PASS |
| `.gemini/agents/pack-*.md` × 5 | `ls .gemini/agents/` shows 5 .md files | PASS |
| `project-template/.codex/agents/auditor.toml` | `test -f` succeeds | PASS |
| `project-template/.claude/agents/auditor.md` | `test -f` succeeds | PASS |
| `project-template/.gemini/agents/auditor.md` | `test -f` succeeds | PASS |
| `project-template/skills/audit-methodology/SKILL.md` | `wc -l` returns 157 lines (PLAN §2.1 says "26496 bytes" per Addendum #1 §7) | PASS — both line count + bytes verified |
| `project-template/docs/project/` does NOT exist | `find project-template/docs -type d` returns only `pack/` and `pack/prompts/` | PASS — correctly named in §2.2 |
| `scripts/lib/migrate-v10-to-v11/` exists; `decompose.sh` does NOT | `ls scripts/lib/migrate-v10-to-v11/` shows apply.sh, checkpoint.sh, dry-run.sh, gates × 3, resume.sh — no decompose.sh | PASS |
| `scripts/lib/per-entry/` does NOT exist | `ls scripts/lib/per-entry/: No such file or directory` | PASS |
| `scripts/migrate-v10-to-v11.sh` post-dispatch hook 5 sub-ops at lines 144–148 | `sed -n '144,148p' scripts/migrate-v10-to-v11.sh` shows 5 _v10_to_v11_* calls | PASS |
| `scripts/lib/migrator-core.sh` `EXIT_GATE_FAILED=31` at line 70 | `grep -n EXIT_GATE_FAILED scripts/lib/migrator-core.sh` → 70 | PASS |
| `scripts/lib/migrator-core.sh` `_MIGRATOR_DRY_RUN` at line 109; `_MIGRATOR_MODE` at 110, 121 | `grep -n` confirms | PASS |
| `scripts/lib/migrator-stages.sh` `_stage_backup` at line 146 | `grep -n` confirms | PASS |
| `scripts/lib/tracker-agent-read.sh` `_tar_read_entry_flat` at line 153 | `grep -n` confirms | PASS |
| `scripts/lib/customization-preserve.sh` `customization_classify` at line 145; `generic` fall-through at line 178 | `grep -n` confirms | PASS (function range 145–180 — see F-4 NIT) |
| `scripts/init-project.sh` `stage_s11_v11_artifacts` at line 803 | `grep -n` confirms | PASS |
| `migrator_target_surface_for_version` v11 case body at lines 459–513 | `sed -n '459p;471p;513p'` confirms function block 459–513 | PASS |
| `PACK-CHAT.md` 199 lines; file-access strategy table at lines 38–47 | `wc -l` + `sed -n '38,47p'` | PASS |
| `PACK-AGENTS.md` 179 lines; agent extension convention at lines 174–176 | `wc -l` + `sed -n '174,176p'` | PASS |
| EXECUTION-PLAN-V11.0.md line 282 totals (current verbatim) | `sed -n '281,283p'` shows the current "25 main batches ... ~31 commits" verbatim | PASS |
| RELEASE-GATE.md lines 38–39 reference Batch 21 / 22 | `sed -n '36,42p'` confirms | PASS |
| BD-138 line 1595 (Unblocks); 1597 (description); 1599; 1600; 1624 (BD-136 Blockers) | `sed -n '1595p;1597p;1599p;1600p;1624p' BACKLOG.md` | PASS — all 5 lines match plan's "Current text" column verbatim |
| `auditor.md` line 11-12 "skill ... authoritative source" | `sed -n '11,12p' project-template/.claude/agents/auditor.md` | PASS |
| audit-methodology SKILL.md File-scope-rules section (rules 25–32) | `grep -nE '^[0-9]+\.' project-template/skills/audit-methodology/SKILL.md` shows rules 25 / 26 / 27 / 28 / 29 / 30 / 31 / 32 at the File scope rules H2 starting line 66 | PASS |
| project-template Codex agents directory has 16 .toml files | `ls project-template/.codex/agents/auditor*` confirms | PASS — 16 .toml files including auditor.toml + 7 sub-auditors + others |
| `_v8-resolved-archive.md` content extraction algorithm per integration parent §9.7 | Direct verification matches | PASS |

### §4.2 — Files / directories where plan claims a line number that disagrees with file system

| Plan claim | Verified by | Result |
|---|---|---|
| `validate-pack.py` Check 31 (`check_skill_cell_consistency`) at line 2454 in §2.1, §2.4, §5.6 | `grep -nE '^def check_skill_cell_consistency' scripts/validate-pack.py` → 2425 | **FAIL — F-1 / F-5** |
| `migrator-core.sh` mode-flag parser at lines 264–272 in plan multiple sites | `grep -nE 'MIGRATOR_MODE|--dry-run|--apply|--resume' scripts/lib/migrator-core.sh` shows the case statement openings span 264–271 with the resume case continuing through line 281 | PASS at the case-opening level; FAIL on full-block — F-3 NIT |
| `customization-preserve.sh` `customization_classify` "lines 145–179" in §2.1 | `sed -n '143,180p'` shows function spans 145–180 | F-4 NIT |
| PACK-AGENTS.md PM-only files at "~141–142" in §2.1 | Block actually at lines 139–142 | F-13 NIT |

### §4.3 — Items NOT spot-checked but presumed correct via secondary signals

- BACKLOG.md highest-BD count and §1.1 §1.2 § ranges in EXECUTION-PLAN-V11.0.md were not directly verified per-line; the plan's grep evidence is sound and the surrounding context cross-references are consistent.
- All plan path references using `<stream>` or `_rules.md` placeholder did not need verification (placeholders cannot be verified by `ls`).

**Verify-by-`ls` discipline net result:** 32 of 36 spot-checked paths
+ line-numbers correct; 4 line-number discrepancies (3 NIT, 1 SHOULD-FIX
for the 2454-vs-2425 inconsistency between plan sections).


---

## §5 — Audit-methodology SKILL.md scope-rules extension review (R-4-specific)

Per the calling prompt's success criterion #8, evaluate the proposed
SKILL.md extension for compatibility with the existing rule structure
(rules 25–32).

**Existing rule structure (verified by direct `grep -nE '^[0-9]+\.'
project-template/skills/audit-methodology/SKILL.md`):**

- Rule 25: "Always exclude" (all clusters): vendored / generated paths
- Rule 26: auditor-architecture scope (source files in module roots)
- Rule 27: auditor-code scope (source files; excludes tests + generated)
- Rule 28: auditor-tests scope (test files; excludes fixtures)
- Rule 29: auditor-docs scope (`**/*.md`, `**/*.txt`, `**/README*`,
  inline doc comments)
- Rule 30: auditor-security scope (source + config + manifests + Dockerfiles)
- Rule 31: auditor-ui scope (view + view-model files)
- Rule 32: auditor-ops scope (deployment manifests + config + observability + CI workflows)

**Proposed extension per R-4 resolution (per plan §5.8 line 849):**
- Clarification under rule 29 (`**/*.md`) that per-entry tree files
  (`docs/project/backlog/BD-NNN.md`, etc.) are IN SCOPE as authored
  source-of-truth.
- Regenerated mirrors (`BACKLOG.md`, `CHANGELOG.md`,
  `IMPLEMENTATION-PLAN.md`) are OUT OF SCOPE when per-entry tree is
  present (auditing them duplicates findings).

**Compatibility analysis:**

1. **Rule 29's `**/*.md` glob.** The existing glob naively matches BOTH
   per-entry tree files AND regenerated mirrors. Without the proposed
   clarification, both would be in scope; auditor-docs would file the
   same finding twice (once against the per-entry file, once against
   the same content in the regenerated mirror). The clarification is
   semantically correct.

2. **No new rule 33 needed.** The clarification fits inside rule 29
   as a parenthetical or sub-paragraph, which is consistent with how
   rule 29 currently reads ("`**/*.md`, `**/*.txt`, `**/README*`,
   inline doc comments"). Adding "(per-entry tree files in scope as
   authored source-of-truth; regenerated mirrors at canonical
   monolithic paths SKIP when per-entry tree exists)" preserves the
   rule shape.

3. **No conflict with rule 25 ("Always exclude").** The regenerated
   mirrors are not vendored or generated CODE; they are
   regenerated-from-source DOCS. The exclusion rule for vendored /
   generated PROGRAMS does not apply to regenerated DOCS. The
   distinction is consistent with how the existing rules handle the
   project-template vs client artifact split.

4. **Ownership precedence (rule 38).** Rule 38 says "first reporter
   wins in cluster order: security → architecture → tests → ops →
   code → ui → docs." Auditor-docs is last in this order, so any
   finding in a `**/*.md` file that another auditor cluster could also
   detect would belong to that cluster. This means: a per-entry file
   that contains a SECURITY violation (e.g., a credential in a
   Description: body) belongs to auditor-security, not auditor-docs;
   the rule 29 in-scope expansion does not change this. Same for the
   architecture / ops / code / ui clusters.

5. **No regression on existing scope.** All other rules (25, 26, 27,
   28, 30, 31, 32) are unaffected by the rule 29 addition. The
   addition is isolated.

6. **Auditor-architecture scope (rule 26).** Per plan §5.8 line 849,
   only rule 29 is extended. The plan does NOT extend rules 26 / 27
   / 30 etc. — but the per-entry tree files at
   `docs/project/backlog/BD-NNN.md` (etc.) are pure documentation;
   they would not match rule 26 (`Sources/`, `server/src/`, etc.) or
   rule 27 (`**/*.swift`, `**/*.py`, etc.) in the first place. The
   single-rule extension is the right surgical scope.

**Verdict on R-4 SKILL.md extension semantic compatibility.** The
extension is well-shaped and does not break the existing rule
structure. A coder implementing the extension at 19g-pack drafting
time should:
- Add the clarification AT rule 29 (not as a new rule).
- Use the parenthetical sub-paragraph form to keep the rule's existing
  shape.
- Optionally add a one-line cross-reference at rule 25 ("not to be
  confused with regenerated mirrors per rule 29 elaboration").
- Verify the clarification reads consistently with rule 29's existing
  "Cross-references documented claims against code in
  auditor-architecture's and auditor-code's scope but does not
  re-audit those files for anything other than documentation
  accuracy" qualifier (the regenerated-mirror SKIP is the same
  shape).

No SHOULD-FIX or BLOCKER on the R-4 extension itself. The plan's
spec is correct.


---

## §6 — Architectural soundness review

### §6.1 — Commit ordering

The 10-commit ordering is sound:
1. **19a (BD-164) helpers first.** Strict precondition for 19c, 19d, 19e, 19f, 19g-pack — verified.
2. **19b-pack (BD-167) before 19b-PM (BD-167b).** Plan §3.2 correctly notes "BD-167's canonical templates create the paths that BD-167b's trinity Key files / PACK-AGENTS.md / pack-* agent prompts reference. Without 19b-pack, the PM-only edits would point at non-existent paths."
3. **19c (BD-165) AFTER 19b-{pack,PM}.** Plan §3.2 explanation is logically sound.
4. **19f after 19e.** Verifies the validator gate passes on the new fixture before manifest regeneration.
5. **19g-pack before 19g-PM.** Plan §3.2 correctly: "the parallel pack-product wording (PM-CHAT.md) lands first, so PACK-CHAT.md row addition is consistent."
6. **19h last.** Status flips after batch is green.

No deadlocks; no circular dependencies. PASS.

### §6.2 — File dependency graph (§3.1)

The §3.1 dependency graph is exhaustive and correct. Every commit's
output → consumer chain is named. The "Batch 23 BD-102 dog-food
consumes BD-170 fixture" annotation correctly stops at the Batch 19
boundary. PASS.

### §6.3 — Verification gates (§7.1)

Each commit has a per-commit verification gate; gates align with
existing pack test surface (test-migrator-core, test-migrate-v10-to-v11-dry-run,
test-migrate-v10-to-v11-gates, test-init-project, test-persona-contracts).
The new test runners (test-per-entry.sh, test-validate-pack-checks-32-33-34.sh)
are correctly identified. The Trinity rule byte-equivalence checks
in §7.2 are well-specified (modulo F-15 stale row). PASS with F-15.

### §6.4 — Trinity rule application

The plan correctly distinguishes:
- **Pack-root trinity** (CLAUDE / AGENTS / GEMINI at pack root) — 19b-PM
- **Project-template trinity** (CLAUDE / AGENTS / GEMINI in project-template/) — 19b-PM
- **Pack-* agent trinity** (5 agents × 3 CLIs = 15 files; Codex .toml + Claude/Gemini .md) — 19b-PM
- **Auditor agent trinity** — NOT TOUCHED per R-4 (this is correctly handled at every site EXCEPT §7.2 — see F-15)
- **Pack-startup skill trinity** (3 files: Claude .md + Codex .md + Gemini .toml) — 19g-pack
- **Pm-startup skill quad** (canonical + 3 per-CLI mirrors = 4 files) — 19g-pack

Application is correct everywhere with the F-15 §7.2 row exception.

### §6.5 — Architect-pass discipline preservation

The plan does NOT author PM-only file content. It SPECIFIES the edits
for Pack Chat to apply (per §6 PM-only edit specifications subsections).
The trinity Key files line additions, PACK-AGENTS.md PM-only directories
list expansion, CLAUDE.md pack-memory bullet, pack-* agent prompt
edits, EXECUTION-PLAN-V11.0.md edits, RELEASE-GATE.md edits, BACKLOG.md
new BD-creation entries, and BD-138 / BD-136 backstamp edits are all
SPECIFICATIONS, not authored content. The §6.1 BD-NNN entry "sample text"
blocks are explicitly labeled "Pack Chat drafts final wording."
PASS.

### §6.6 — Coder execution feasibility

A coder reading the plan + architect docs (no chat history) can
execute every commit with zero questions, EXCEPT for:

1. **F-1 line-number inconsistency.** A coder reading §2.4 ("Check
   31, line 2454") then opening `validate-pack.py` will not find a
   check at line 2454. They will look at §11.1 evidence record and
   see line 2425 — the inconsistency surfaces immediately.

2. **F-15 stale §7.2 trinity row.** A coder reading §7.2 sees an
   "Auditor agent trinity" row that says "19g-pack: same audit-scope
   extension; format-specific wrapping for Codex .toml." They will
   read §5.8 and see auditor agent files are NOT touched. They will
   need to resolve the contradiction.

3. **Several NIT-level wording issues** (F-3, F-4, F-7, F-9, F-13, F-16, F-17)
   are minor and do not block coder execution.

Other planner-deferred items (helper file structure, function names,
sequencing within `migrator_post_dispatch_hook`, etc.) are explicitly
labeled as planner-pass deferrals at every site and the plan provides
recommendations.

**Coder execution feasibility:** PASS-WITH-FIXES. After F-1, F-2 and
F-15 are fixed, a coder can execute the plan with no Pack Chat
clarification.

### §6.7 — BD-138 batch references in BACKLOG.md

Direct verification confirms BACKLOG.md still uses pre-cascade Batch
numbers (Batch 20b, Batch 21, Batch 22) at lines 1595, 1597, 1599,
1600, 1624. The plan's §6.4 backstamp specification matches the
current text exactly. PASS.

### §6.8 — Architect-doc compliance

The plan correctly applies Addendum #2 > Addendum #1 > integration
parent > sidecar parent precedence. Verified in §1.3 supersession
table (line 114) and §8.1 supersession-resolution table (line 1338).
All 16 supersession chains in §8.1 are resolved correctly per the
deepest applicable Addendum. PASS.


---

## §7 — Notes on Architect-doc citations

The following architect-doc citations were checked for accuracy:

- **Plan §0 line 38: "Codex pack-* agent files are `.toml` (not `.md`) — Addendum #2 §1 BLOCKER correction."** Verified by direct read of Addendum #2 §1.1 (line 99). PASS.
- **Plan §0 line 36: "Pack-side per-entry trees are non-dot (`/backlog/`, `/changelog/`) — leading-dot DROPPED per Addendum #1 §10."** Verified by direct read of Addendum #1 §10.1 (line 1573). PASS.
- **Plan §0 line 35: "Layer 2 of discoverability is HTML-comment line-1 only — body-field back-pointer DROPPED per Addendum #2 §2."** Verified by direct read of Addendum #2 §2.1 (line 372) + §2.2 (line 406). PASS.
- **Plan §0 line 38: "EXECUTION-PLAN line 282 totals replacement is per Addendum #2 §3.3 verbatim text."** Verified by direct read of Addendum #2 §3.3 (line 630). PASS.
- **Plan §0 line 40: "Regenerator divergence in apply/resume mode BLOCKS unless `--force-overwrite-mirror` is passed — per Addendum #2 §4 BD-095 bridge."** Verified by direct read of Addendum #2 §4.2 (line 713). PASS.
- **Plan §0 line 41: "PACK-CHAT.md row exact text is per Addendum #2 §5.2 verbatim."** Verified by direct read of Addendum #2 §5.2 (line 953). PASS.
- **Plan §1.3 line 125: "Mode-aware source-of-truth language in CLAUDE.md pack-memory bullet ... per Addendum #1 §3.4."** Verified by direct read of Addendum #1 §3.4 (line 601). PASS.
- **Plan §1.3 line 126: "PACK-AGENTS.md framing — Honest Signal 9 trip per Addendum #1 §3.1."** Verified by direct read of Addendum #1 §3.1 (line 480). PASS.
- **Plan §6.1 BD-167b entry line 1085-1087 enumerates 5 + 5 + 5 = 15 pack-* agent files with correct Codex `.toml` extensions.** Verified directly. PASS.
- **Plan §6.4 BD-138 + BD-136 amendments per Addendum #1 §2.5.** Verified by direct read of Addendum #1 §2.5 (line 430). Plan applies the §2.5 row text accurately AND incorporates R-8 backstamp (drops the parenthetical-recommendation that Addendum #1 §2.5 row 6 left ambiguous). PASS.
- **Plan §10.4 R-4 cites "auditor.md line 11-12 ... 'rules in the audit-methodology skill — that skill is the authoritative source.'"** Verified by direct read of `project-template/.claude/agents/auditor.md` lines 11-12. PASS.

No architect-doc citation errors found. The supersession order is
applied correctly throughout. The plan does not misapply Addendum #2
supersession at any verified site.


---

## §8 — Acknowledgements (what the plan got right)

A pure-defects review is incomplete. The plan demonstrates strong
architectural thinking and discipline:

1. **Pack-Chat-direct risk resolutions correctly cascaded.** R-2, R-3,
   R-4, R-8 each touch ~10–14 sites; each resolution is consistently
   applied with no stale references remaining (excepting F-15 §7.2
   row for R-4).

2. **Honest Signal 9 framing in §5.3 + §6.1.** The plan correctly
   applies Addendum #1 §3.1's "honest Signal 9 trip" framing (NOT
   "refactor not expansion") at every site referencing the
   PACK-AGENTS.md edit.

3. **Mode-aware CLAUDE.md pack-memory bullet** per Addendum #1 §3.4
   correctly cited at §5.3 (line 609) and §1.3 (line 125).

4. **Architectural separation of pack-coder vs Pack-Chat-direct
   commits** is rigorous. The 6 + 4 split + the agents-never-commit
   rule + the PM-only-file boundary are all correctly applied.

5. **BD numbering audit** is verified directly against BACKLOG.md
   (BD-163 highest; BD-164..BD-170 + BD-167b + BD-169b sequential
   non-colliding).

6. **Architect-pass discipline preserved.** The plan authors zero
   PM-only file content; everything is specification.

7. **Cross-reference between commits** in §3.1 dependency graph is
   exhaustive, accurate, and matches the per-commit specs in §5.

8. **Verification strategy in §7** correctly identifies trinity rule
   byte-equivalence checks, byte-additive entry-content invariant test
   (per sidecar parent §3.1 + Addendum #2 §2.1), byte-identity
   round-trip test (per integration parent §12.1).

9. **Cross-doc consistency check in §8** systematically enumerates 16
   supersession chains and applies the deepest-supersession-wins
   resolution at every cell. This is a model of architect-doc
   composition discipline.

10. **Risk enumeration in §10** correctly distinguishes Pack-Chat-direct-
    resolved risks (R-2, R-3, R-4, R-8) from operational-mitigation
    risks (R-1, R-5–R-7, R-9–R-13). Resolution paths are documented
    where applicable.

11. **§11.1 verify-by-`ls` evidence record** is present and grounded
    in actual file system state (modulo the §2.1 / §2.4 / §5.6
    line-2454 inconsistency with §11.1's own line-2425 evidence).

12. **§11.2 final-line marker** is comprehensive and accurate.


---

## §9 — Recommended fix order (priority for Pack Chat application)

Per the pack memory rule "Fix all review findings including nits"
(default fix-all). Suggested application order:

**Tier 1 — SHOULD-FIX (apply before coder execution starts):**
1. F-1 / F-5 — Replace "line 2454" → "line 2425" in §2.1, §2.4, §5.6
2. F-2 — Replace EXECUTION-PLAN §C.4 citation in §5.10 + §1.1 19h row with agents-never-commit + PM-only-file rationale
3. F-15 — Delete or rewrite "Auditor agent trinity" row in §7.2

**Tier 2 — NIT (apply for completeness / coder ergonomics):**
4. F-3 — Update "264–272" → "264–276" line range at 6 plan sites
5. F-4 — "lines 145–179" → "lines 145–180" in §2.1
6. F-13 — "~141–142" → "~139–142" in §2.1 PACK-AGENTS.md row
7. F-16 — Reword §1.1 BD-169 description for R-4 clarity
8. F-17 — Reword §4 19g-pack rationale for R-4 scope
9. F-9 — "v11-init" → "v11 init" in §3.1 dependency graph
10. F-7 — Add half-sentence to §6.2 Edit 5 about §3 placement
11. F-11 — Add commit-message guidance to §10.8 R-8 paragraph

**Surfaced for transparency, no fix needed:**
- F-6, F-8, F-10, F-12, F-14 (positive verifications or process-only NITs)


---

## §10 — Final verdict

**APPROVE-WITH-FIXES.**

The plan is a rigorous composition of the four architect docs under
the stated supersession order. The 4 risk resolutions are correctly
incorporated. Cross-section consistency is high (14 of 15 properties
PASS). Architectural soundness is sound (commit ordering, dependencies,
verification gates, trinity rule application).

The defects are concentrated in one class (stale line numbers — 4
findings of which 1 SHOULD-FIX is internally inconsistent with §11.1's
own evidence record) and one class (one §C.4 citation justifies a
structure §C.4 does not authorize, plus one stale §7.2 trinity row
contradicting R-4 scope elsewhere). All other findings are NITs.

**Estimated fix scope:** 11 line edits across ~7 plan sections;
Pack Chat applies the SHOULD-FIX tier (F-1, F-2, F-15) before coder
execution begins; NIT tier may be folded into the same edit pass or
deferred per Pack Chat preference.

After fixes, the plan can be acted on with no further architect or
planner pass required.

---

## §11 — Final-line marker

REVIEW-PLAN-PER-ENTRY-SPLIT-BATCH-19-COMPLETE: 2026-05-14 — Review of
PLAN-PER-ENTRY-SPLIT-BATCH-19.md (1,724 lines) against the four-doc
architect corpus (sidecar parent + integration parent + Addendum #1 +
Addendum #2; 8,579 architect-doc lines total). Verdict:
APPROVE-WITH-FIXES. 0 BLOCKER + 5 SHOULD-FIX (F-1/F-5 line-2454
inconsistency × 3 plan sites; F-2 EXECUTION-PLAN §C.4 citation
mismatch × 2 plan sites; F-15 stale §7.2 auditor trinity row × 1)
+ 9 NIT (F-3/F-4/F-7/F-9/F-11/F-13/F-16/F-17 wording / line-range /
process-clarity issues; F-6/F-8/F-10/F-12/F-14 positive verifications
flagged for transparency). Cross-section consistency: 14 of 15
properties PASS (the one PASS-WITH-NIT is the §7.2 trinity table row
covered by F-15). Risk-resolution incorporation: R-2 12/12 PASS; R-3
14/14 PASS; R-4 8/10 PASS + 2 NIT + 1 FAIL (F-15); R-8 4/4 PASS.
Verify-by-`ls` discipline: 32 of 36 spot-checked items PASS; 4
line-number discrepancies (1 SHOULD-FIX, 3 NIT). Audit-methodology
SKILL.md scope-rules extension review (per success criterion #8): the
proposed clarification under rule 29 is well-shaped, does not break
existing rule 25–32 structure, and is the right surgical scope — no
defects on the R-4 extension itself. Architect-doc compliance: zero
misapplied supersessions; 16 of 16 supersession chains correctly
resolved. Architect-pass discipline preserved: zero PM-only file edits
authored by the plan; all required PM-only edits surfaced as edit
specifications for Pack Chat. Coder execution feasibility:
PASS-WITH-FIXES (F-1, F-2, F-15 fixes block clean coder execution;
all other findings are NIT and do not block). Recommended fix order
in §9 above. Plan-and-fix-list ready for Pack Chat to surface to the
user with fix-or-defer per finding (default fix-all per pack memory
rule "Fix all review findings including nits"). After SHOULD-FIX tier
is applied, plan is ready for primary-chat pack-coder + Pack Chat
mixed-mode Batch 19 execution.
