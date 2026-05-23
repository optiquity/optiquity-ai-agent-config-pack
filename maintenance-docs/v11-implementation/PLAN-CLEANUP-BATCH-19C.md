# PLAN-CLEANUP-BATCH-19C — per-commit task list (Batch 19c / BD-173)

**Author:** pack-planner
**Date:** 2026-05-22
**Branch:** v11-dev
**HEAD at plan time:** `9a95bfaf9ec6687cad36566df50853731970c7a4`
**Architect input:** `maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19C-V2.md` (1565 lines, post-5-decision triage 2026-05-22)
**Supporting inputs:** `ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md` (749L), `ARCHITECTURE-V11-LEAK-SWEEP-STRATEGY.md` (439L), `AUDIT-PRE-19C-BOUNDARY-LEAKS.md` (910L), `ARCHITECTURE-PRE-19C-SALVAGEABILITY.md` (470L).
**Status:** implementation-ready. Pack-coder consumes commit-by-commit; reviewer attaches per V2 §I (9 INLINE sliding-window passes / 6 SKIP-per-commit but covered / 1 END-OF-BATCH); see (α-sliding) note before §3 for the canonical coverage mapping.

---

## §0 — How to use this plan

1. Each `H.N` section below is self-contained — a fresh pack-coder reading only that section plus the cited V2 §C.N / §D.N / §H.N text can execute the commit mechanically.
2. Verify the **insertion anchor** against fresh HEAD at commit time. Section headers + surrounding-line cues are the durable anchor; line numbers listed below are HEAD-as-of-plan-time and WILL drift.
3. **RC9 manifest regeneration** per BD-176 4-directory v11-surface trigger (`project-template/`, `scripts/`, `pack-ops/`, `supporting-docs/`). Every applicable commit lists the exact regen step.
4. **Per-commit reviewer:** 9 commits carry INLINE reviewer (H.4, H.5, H.9, H.10, H.11, H.13, H.14, H.15, H.16); 6 SKIP-per-commit (H.1, H.2, H.3, H.6, H.7, H.12); 1 END-OF-BATCH (H.17). Per Decision 4 (α-sliding) 2026-05-22, each INLINE reviewer covers a sliding window from the prior INLINE commit (or H.0 baseline) through its own commit, so the 6 SKIP-per-commit commits are covered by the next INLINE reviewer (see §3 each INLINE commit's per-commit reviewer block + §4 reviewer column + the (α-sliding) note immediately before §3 for the canonical mapping).
5. **Validation contract:** at each commit head, `python3 scripts/validate-pack.py` exits 0 AND `bash scripts/tests/test-validate-pack-check-*.sh` (for any touched test file) exits 0. Per V2 §M.5 + GUARDRAILS-CONTRACT §5.3.
6. **NO git state changes by any agent** (read-only verbs only). Pack Chat stages + commits with user approval.

---

## §1 — Insertion-anchor cross-walk (V2 text vs current HEAD)

V2 cites V1's line numbers (recorded 2026-05-17). Multiple BDs have landed since (BD-175..BD-184 + BD-185 V2 docs). Verified anchors at HEAD `9a95bfa`:

| V2 cite | V2 line ref | Current HEAD location | Status |
|---|---|---|---|
| PM-CHAT.md `## Behavioral rules` | V1 L201 area | `project-template/docs/pack/PM-CHAT.md:176` | RESOLVED — section H2 at L176; first bullet "Plan before executing" at L180; "Source file edits" at L203; "Fix cycle rules" at L201; "Pack feedback loop" at L221; "Follow Prompt Authoring Principles" at L188 |
| PM-CHAT.md "Tool-specific: Claude Code CLI" | V1 L552 | `PM-CHAT.md:552` | RESOLVED — unchanged |
| PM-CHAT.md `ARCHITECTURE-V3.3-DELTA.md §3.1:` (Cat D leak) | V1 L410 | `PM-CHAT.md:410` | RESOLVED — unchanged |
| METHODOLOGY.md Part 1 Separation rule | V1 L98 | `supporting-docs/METHODOLOGY.md:98` | RESOLVED |
| METHODOLOGY.md Part 1 Claude Code CLI sub-section | V1 L78-83 | `METHODOLOGY.md:78-83` | RESOLVED |
| METHODOLOGY.md Part 5 Workflow 2 end | V1 L410 | `METHODOLOGY.md:398-420` (Workflow 2 block) | RESOLVED — coder inserts callout immediately after L410 closing fence (block ends L410, blank line L411) |
| METHODOLOGY.md Workflow 4 fenced block | V1 L449 | `METHODOLOGY.md:435-449` (fenced block ends L449) | RESOLVED — cycle-termination callout lands after L449 fence close |
| METHODOLOGY.md Workflow 4 Trigger A/B section | V1 L503 area | `METHODOLOGY.md:489-508` (Architect trigger conditions block) | RESOLVED — Trigger B paragraph ends L503; new architect-trigger callout lands after L503 |
| METHODOLOGY.md Workflow 4 step 4 | V1 L522-523 | `METHODOLOGY.md:441-446` Workflow 4 fenced steps — note V2 text references "step 4" abstractly; the Workflow 4 fenced block is the STRENGTHEN target; the actual rendered prose-strengthen is the new architect-output-user-reads callout AFTER fence-close — see H.1 note | RESOLVED — §3 H.1 step 4 + §5 Observation 3 now mutually aligned per user direction 2026-05-23 (M-2 fix) |
| METHODOLOGY.md Part 7 Procedure 1 step 2 | V1 L1083 | `METHODOLOGY.md:1082-1094` (Procedure 1 step 2 block) | RESOLVED — step 2 ends L1094 with "(When all blockers resolve...)"; STRENGTHEN appends inside step 2 around L1094 |
| METHODOLOGY.md Part 7 Procedure 4 step 4 | V1 L1198 | `METHODOLOGY.md:1198-1219` (Procedure 4 fenced block) | RESOLVED — cross-ref callout lands after Procedure 4 fenced block close (L1219) |
| METHODOLOGY.md Part 9 table | V1 L1384-1394 | `METHODOLOGY.md:1380-1394` (Part 9 + table) | RESOLVED — /tmp paragraph lands after L1394 table close |
| project-template CLAUDE.md "No destructive operations" | V1 L874-881 (pre-BD-178) | `project-template/CLAUDE.md:365-369` (post-BD-178 baseline at HEAD) | DRIFTED — V2 §C.6 explicitly notes "apply to BD-178-canonicalized baseline, NOT V1's pre-BD-178 form" — coder reads HEAD form first |
| project-template AGENTS.md / GEMINI.md destructive-ops | parallel | `AGENTS.md` + `GEMINI.md` post-BD-178 forms (matching by `## Project memory` H2 + "No destructive operations" bullet) | DRIFTED — same as CLAUDE.md |
| pack-root CLAUDE.md PREFLIGHT bullet | (no V1 line cite) | `/CLAUDE.md:286-322` (Pack-coder PREFLIGHT + STOP-MEANS-STOP pattern bullet) | RESOLVED |
| pack-root AGENTS.md PREFLIGHT | parallel | `/AGENTS.md:286-322` | RESOLVED |
| pack-root GEMINI.md PREFLIGHT | parallel | `/GEMINI.md:253-291` | RESOLVED |
| pack-ops/PACK-AGENTS.md PREFLIGHT spec | (V2 cite L190-211) | `pack-ops/PACK-AGENTS.md:190-211` | RESOLVED |
| pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md (d) Pack rule adherence | (V2 cite L37) | `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md:37` | RESOLVED |
| boundary-investigation/SKILL.md Step 4 deny-list | V1 L94-126 | `project-template/skills/boundary-investigation/SKILL.md:94-126` | RESOLVED; fence-open before L97 marker (line "The pack-only deny-list..." at L96), fence-close after L126 |
| boundary-investigation/SKILL.md AUDIT-USER-CURATION.md cite (Cat F) | V1 L124 | `skills/boundary-investigation/SKILL.md:124` | RESOLVED — bare-prose replacement applied per V2 §B.2 Cat F before fence placement |
| scripts/lib/detect.sh Cat D cites | (V2 cite L335 + L678) | `scripts/lib/detect.sh:335` + `:678` | RESOLVED |
| pm-startup cluster Cat E cites | (V2 cite L258) | 4 files at L258 (canonical `project-template/skills/pm-startup/SKILL.md`, `.claude/skills/pm-startup/SKILL.md`, `.codex/skills/pm-startup/SKILL.md`, `.gemini/commands/pm-startup.toml`) | RESOLVED |
| prompts/coder.md deny-list block | (V2 cite L83-89, L195-202) | `project-template/docs/pack/prompts/coder.md:83-89` + `:195-202` | RESOLVED |
| prompts/reviewer.md deny-list block | (V2 cite L102-107) | `project-template/docs/pack/prompts/reviewer.md:102-107` | RESOLVED |
| prompts/pm-chat.md three variants (Cat C) | (V2 cite L94-96, L182-189, L227-234) | `project-template/docs/pack/prompts/pm-chat.md:94-96`, `:182-189`, `:227-234` | RESOLVED |
| project-template trinity Project SSOT-first bullet (H.13 fence) | (no V1 line cite) | `project-template/CLAUDE.md` "Project SSOT-first" bullet at ~L381-410 (multi-line bullet ending "boundary-investigation skill for the SSOT-investigation methodology"); parallel in AGENTS / GEMINI | RESOLVED |
| `_PROJECT_SIDE_ROOTS` | `validate-pack.py:3762` | `scripts/validate-pack.py:3762` | RESOLVED |
| `_is_legitimate_deny_list_doc` | `validate-pack.py:4084` | `scripts/validate-pack.py:4084` | RESOLVED |
| `check_project_side_deny_list` | `validate-pack.py:4136` | `scripts/validate-pack.py:4136` | RESOLVED |
| `_CHECK_40_ALLOWLIST` | `validate-pack.py:4574` | `scripts/validate-pack.py:4574` | RESOLVED |
| `.github/workflows/validate-pack.yml` Check 42 wiring | (V2 cite L183) | `.github/workflows/validate-pack.yml:183` | RESOLVED |
| `scripts/init-project.sh` `_CLIENT_INSTALLED_FILES_START`/`_END` | (V2 cite L1275-1314) | `scripts/init-project.sh:1275-1314` | RESOLVED |

Note: V1's pre-BD-178 line numbers for trinity destructive-ops (V1 L874-881) DO NOT MATCH HEAD. Per V2 §C.6 the coder reads the BD-178-canonicalized HEAD form and applies STRENGTHEN to that text. See H.4 below for the actual HEAD form.

---

## §2 — Pre-commit setup (H.0)

### H.0 — Baseline verification

**Coder actions** (read-only; no edits):

1. Verify HEAD: `git rev-parse HEAD` should match the plan's recorded HEAD `9a95bfa` or a descendant. If HEAD advanced, the planner verifies any new commits did not invalidate anchors before H.1 begins.
2. Verify working tree clean: `git status` — no uncommitted edits except plan output (`PLAN-CLEANUP-BATCH-19C.md`) and the V2 architect work products under `maintenance-docs/v11-implementation/`.
3. Verify validate-pack baseline: `python3 scripts/validate-pack.py` — record PASS status. Note: at H.0 baseline, validate-pack PASSES with all 36 leaks present (whole-file exemptions + narrow deny-list per V2 §A.2 input §6 prevention-gap analysis).
4. Verify BD-173 status: `grep -A2 "BD-173" pack-ops/BACKLOG.md | head -5` confirms `Status: Open`.
5. Verify BD-179 closure: per V2 H.0, BD-179 must be closed before Batch 19c restarts. BD-179 status at HEAD `9a95bfa`: confirm via `grep -B1 -A3 "^\*\*BD-179" pack-ops/BACKLOG.md | head -10`. If BD-179 still Open, escalate to Pack Chat for sequencing decision per V2 §H.0 caveat.

**Output:** no commit. H.0 is a pre-flight checklist for the coder's PREFLIGHT line at H.1.

**Per-commit reviewer:** n/a (no commit).

**RC9 manifest regen:** n/a.


---

## §3 — Per-commit tasks

Each H.N below carries: scope summary | files modified | edit specification | verification commands | RC9 manifest-regen attachment | per-commit reviewer scope | commit message.

**(α-sliding) reviewer-scope interpretation (per Decision 4 (α-sliding) 2026-05-22).** Each INLINE reviewer's scope is the diff from the prior INLINE commit (or H.0 baseline) through end of its own commit. Reviewers therefore cover ALL implementation commits at least once before H.17, not just the INLINE-marked commits. See V2 §J.6 sliding-window refinement paragraph and V2 §I "Net per-commit reviewer breakdown" for the canonical mapping. SKIP-per-commit commits (H.1, H.2, H.3, H.6, H.7, H.12) are explicitly covered by the next INLINE reviewer's sliding window — they are not unreviewed. Sliding-window mapping summary: H.4 covers H.1-H.4 (4 commits); H.5 covers H.5 only; H.9 covers H.6+H.7+H.9 (3 commits; H.8 was removed); H.10/H.11/H.14/H.15/H.16 each cover own diff only; H.13 covers H.12+H.13 (2 commits); H.17 end-of-batch reviewer covers the full H.0 → end of H.16 diff as backstop.

---

### H.1 — METHODOLOGY.md workflow cycle additions

**Scope:** §C.1 METHODOLOGY callout (always-reviewer cycle invariant) + §C.2 STRENGTHEN (architect-trigger surface-even-mechanical) + §D.3 cycle-termination clarification + §C.10 Workflow 4 step 4 STRENGTHEN (architect-output user-reads).

**Files modified:**
- `supporting-docs/METHODOLOGY.md` (4 edits, all in Part 5 Workflow 2 + Workflow 4)

**Edit specification:**

1. **§C.1 callout — always-reviewer cycle invariant.** Per V2 §C.1 second text block (verbatim). Insert as `>` callout block at end of Workflow 2 block, immediately after the fenced code block closing at `METHODOLOGY.md:410`. Anchor: line "Developer updates STATUS.md, syncs GitHub connector" inside fence at L409; insert blank line + callout block AFTER fence-close. Insertion ordering: at HEAD post-pre-existing-changes, between the Workflow 2 fence-close (L410) and Workflow 3 header (L433) there is a pre-existing `> **agent-run.sh ...**` callout block (L412-420). The new `Cycle invariant — reviewer always runs.` callout lands IMMEDIATELY AFTER the `agent-run.sh` callout, before Workflow 3 header. Logical-flow rationale: `agent-run.sh` is annotation; `Cycle invariant` is behavioral assertion — annotation reads first, behavioral assertion follows.
2. **§C.2 STRENGTHEN — architect-trigger surface-even-mechanical.** Per V2 §C.2 verbatim. Insert as `>` callout block immediately after Trigger B paragraph closing at L503 ("...whichever count is larger"). The next existing block is the "Why this matters" `>` callout starting at L504; insert the new callout BETWEEN Trigger B (L498-503) and the "Why this matters" callout (L504-508).
3. **§D.3 cycle-termination callout.** Per V2 §D.3 verbatim. Insert as `>` callout block immediately after the Workflow 4 fenced code block (closes at L449), BEFORE the existing "The PM chat does not execute fix passes directly." callout at L451-453.
4. **§C.10 METHODOLOGY half (Workflow 4 step 4) — per planner Observation 3 (b) approved by user 2026-05-23.** Per V2 §C.10 second text block (the AFTER text for the step 4 STRENGTHEN). Per Observation 3 (b): land V2 §C.10 AFTER text as a NEW `>` callout block AFTER the fenced Workflow 4 block closes (paralleling the existing "PM chat does not execute fix passes directly." callout at L451-453), NOT as an in-fence step 4 STRENGTHEN. Substantive content preserved verbatim; rendering shape converted from V2's numbered-step format (`4. **Present proposed doc changes...**`) to `>` callout block (`> **Present proposed doc changes...**`). Insertion anchor: immediately AFTER the fenced Workflow 4 block closes (around L460 post-§D.3 insertion).

**Verification commands** (sequential, all must PASS):

```bash
python3 scripts/validate-pack.py
bash test-fixtures/build.sh --all --clean
git diff --stat test-fixtures/manifest.txt
```

**RC9 manifest regen:** REQUIRED (`supporting-docs/` in v11-surface per BD-176). Stage `test-fixtures/manifest.txt` alongside scope edits.

**Per-commit reviewer:** SKIP (per V2 §I; non-boundary-sensitive; single-file METHODOLOGY.md additions).

**Commit subject scope keyword:** (mixed — no keyword; touches supporting-docs/ + maintenance-docs/IMPL-REPORT + test-fixtures/manifest).

**Commit message:** `feat: v11 — BD-173 METHODOLOGY.md workflow clarifications (Batch 19c.1)`

**Pack-coder PREFLIGHT line shape:** `PREFLIGHT: 4/4 in-scope file edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.1.md`

---

### H.2 — PM-CHAT.md `## Behavioral rules` additions (PM-chat orchestration rules)

**Scope:** Multi-bullet addition to PM-CHAT.md `## Behavioral rules` section (V2 §C.1 PM-CHAT.md half + §C.4 + §C.7 + §C.8 REVISED-WORDING + §C.9 + §C.10 PM-CHAT.md half REVISED-WORDING + §C.11) PLUS one cross-reference callout in METHODOLOGY.md (V2 §D.5 Procedure 4 cross-ref).

**Files modified:**
- `project-template/docs/pack/PM-CHAT.md` (7 new bullets in `## Behavioral rules`)
- `supporting-docs/METHODOLOGY.md` (1 new cross-ref callout in Part 7 Procedure 4)

**Edit specification:**

1. **§C.11 (open-questions-surface) — NEW bullet, high-level meta-rule.** Per V2 §C.11 verbatim. Insert as NEW bullet in `## Behavioral rules` immediately after the "Plan before executing." bullet (currently L180). Position rationale: V2 §C.11 says "land early in the list as a high-level meta-rule." Include sibling annotation cross-referencing §C.13 per user direction 2026-05-23 (see V2 §C.11 AFTER text trailing sentence).
2. **§C.13 (decision presentation protocol) — NEW bullet, meta-rule per user direction 2026-05-23.** Per V2 §C.13 verbatim. Insert immediately after the §C.11 bullet inserted in step 1 above. §C.13 is the meta-rule generalising §C.10 + §C.11 as sibling instances; landing adjacent to §C.11 establishes the meta-rule next to its closest specific instance.
3. **§C.7 (re-read per-agent prompt files + REPORT FILE verify) — NEW bullet.** Per V2 §C.7 verbatim. Insert immediately after the existing "Follow Prompt Authoring Principles." bullet at L188.
4. **§C.1 PM-CHAT.md half (always-reviewer-after-coder) — NEW bullet.** Per V2 §C.1 first text block (verbatim). Insert immediately after the existing "Fix cycle rules." bullet at L201-202.
5. **§C.4 (closeout-sequence: present-before-write) — NEW bullet.** Per V2 §C.4 verbatim. Insert immediately after the existing "Source file edits." bullet at L203-205.
6. **§C.9 (mid-pipeline working-tree intentional) — NEW bullet.** Per V2 §C.9 verbatim. Insert immediately after §C.4 closeout-sequence bullet (above).
7. **§C.10 PM-CHAT.md half (architect-output → user-reads) — NEW bullet, REVISED-WORDING per V2 §C.10.** Per V2 §C.10 first text block (V1 cross-side citation dropped per salvageability B1). Insert immediately after the §C.7 (re-read per-agent prompt files) bullet inserted in step 3 above. Include sibling annotation cross-referencing §C.13 per user direction 2026-05-23 (see V2 §C.10 PM-CHAT.md AFTER text trailing sentence).
8. **§C.8 (pack-repo-is-read-only) — NEW bullet, REVISED-WORDING per V2 §C.8.** Per V2 §C.8 verbatim (V1's "supporting-docs/" parenthetical example DROPPED; "Pack Chat" audience cite REPLACED with "the pack maintainer"; PACK-FEEDBACK.md product-feature cross-ref RETAINED). Insert immediately after the existing "Pack feedback loop." bullet at L221-227.
9. **§D.5 METHODOLOGY.md cross-ref to PM-CHAT.md closeout-sequence rule — NEW callout block.** Per V2 §D.5 verbatim. Insert as `>` callout block in `supporting-docs/METHODOLOGY.md` Part 7 Procedure 4 area, immediately AFTER the Procedure 4 fenced code block close (L1219). The callout points readers from Procedure 4 step 3/4 back to PM-CHAT.md `## Behavioral rules` "Closeout sequence — present, wait, then write."

**Verification commands:**

```bash
python3 scripts/validate-pack.py
bash test-fixtures/build.sh --all --clean
git diff --stat test-fixtures/manifest.txt
```

**RC9 manifest regen:** REQUIRED (`project-template/` AND `supporting-docs/` in v11-surface).

**Per-commit reviewer:** SKIP (per V2 §I; PM-CHAT.md is project-side SSOT for PM-chat orchestration; multi-bullet block additions are non-boundary-sensitive).

**Commit subject scope keyword:** (mixed — no keyword; project-template/ + supporting-docs/ + maintenance-docs/IMPL-REPORT + test-fixtures/manifest).

**Commit message:** `feat: v11 — BD-173 PM-CHAT.md behavioral rules consolidation (Batch 19c.2)`

**Pack-coder PREFLIGHT line shape:** `PREFLIGHT: 9/9 in-scope file edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.2.md`

---

### H.3 — PM-CHAT.md STRENGTHEN — source-edit discipline

**Scope:** §C.5 STRENGTHEN existing "Source file edits" bullet (no-chained-git-add wording) + §C.6 PM-CHAT.md NEW bullet (PM-chat-never-edits-source).

**Files modified:**
- `project-template/docs/pack/PM-CHAT.md` (1 STRENGTHEN + 1 NEW bullet)

**Edit specification:**

1. **§C.5 STRENGTHEN — "Source file edits" bullet.** Per V2 §C.5 BEFORE/AFTER. V2 BEFORE matches HEAD at L203-205 verbatim. V2 AFTER replaces the bullet body with the expanded text (V2 §C.5 AFTER block) — adds no-chained-git-add wording + "approve to commit" affirmative requirement.
2. **§C.6 PM-CHAT.md half — NEW bullet (PM-chat-never-edits-source).** Per V2 §C.6 first text block (verbatim). Insert immediately AFTER the strengthened "Source file edits" bullet (which post-H.3 ends with the "approve to commit" wording).

**Verification commands:**

```bash
python3 scripts/validate-pack.py
bash test-fixtures/build.sh --all --clean
git diff --stat test-fixtures/manifest.txt
```

**RC9 manifest regen:** REQUIRED (`project-template/` in v11-surface).

**Per-commit reviewer:** SKIP (per V2 §I; PM-CHAT.md STRENGTHEN + NEW bullet; tightly related "source-edit discipline" cluster).

**Commit subject scope keyword:** (mixed — no keyword; project-template/ + maintenance-docs/IMPL-REPORT + test-fixtures/manifest).

**Commit message:** `feat: v11 — BD-173 PM-CHAT.md source-edit discipline (Batch 19c.3)`

**Pack-coder PREFLIGHT line shape:** `PREFLIGHT: 2/2 in-scope file edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.3.md`

---

### H.4 — Trinity STRENGTHEN — destructive-operations list extension (`git checkout --`)

**Scope:** §C.6 trinity half — extend the existing "No destructive operations" bullet's named list with `git checkout --`. REVISED-WORDING per V2 §C.6 — apply to BD-178-canonicalized baseline at HEAD (NOT V1's pre-BD-178 form).

**Files modified:**
- `project-template/CLAUDE.md`
- `project-template/AGENTS.md`
- `project-template/GEMINI.md`

**Edit specification:**

1. **Read current HEAD form first.** Coder reads `project-template/CLAUDE.md` `## Project memory` "No destructive operations without explicit approval" bullet at L365-369. This is the BD-178-canonicalized form; verify it matches the AFTER-edit form in V2 §C.6 (V2 §C.6 AFTER reads "Before any `git rm`, `rm -rf`, file deletion, overwrite, `git reset --hard`, or `git checkout -- <path>` on a file with uncommitted agent work, state exactly..."). The current HEAD form at L365-369 stops at `git reset --hard,` — the STRENGTHEN ADDS `or git checkout -- <path> on a file with uncommitted agent work,` to the named list AND extends the rule body with the trailing rationale sentence ("`git checkout --` is destructive because it discards working-tree changes irreversibly; never run it on files that contain coder-written changes without per-action user approval.").
2. **Apply STRENGTHEN to CLAUDE.md.** Replace the existing bullet body (L365-369 area) with V2 §C.6 AFTER text verbatim.
3. **Apply STRENGTHEN to AGENTS.md.** Locate the parallel bullet (per `## Project memory` H2 + "No destructive operations" bullet — line numbers differ; use header + bullet-first-word match). Apply same V2 §C.6 AFTER text byte-identically.
4. **Apply STRENGTHEN to GEMINI.md.** Locate the parallel bullet; apply same V2 §C.6 AFTER text byte-identically.
5. **Verify cross-CLI parity.** Per V2 §C.6 + Override 9 verification: the new bullet contains no CLI-specific paths (`git rm`, `rm -rf`, `git reset --hard`, `git checkout --` are platform-neutral git verbs). Override 9 carve-out DOES NOT apply; same byte-identical wording across all three trinity files.

**Verification commands:**

```bash
python3 scripts/validate-pack.py
# Verify CI Check 18 H2 parity PASSES (within-trinity body identity for shared H2s).
# Verify CI Check 16/19 parity PASSES (trinity-rule mechanics).
bash test-fixtures/build.sh --all --clean
git diff --stat test-fixtures/manifest.txt
# Spot-check the three trinity files for byte-identical AFTER text:
diff <(grep -A6 "No destructive operations" project-template/CLAUDE.md) <(grep -A6 "No destructive operations" project-template/AGENTS.md)
diff <(grep -A6 "No destructive operations" project-template/CLAUDE.md) <(grep -A6 "No destructive operations" project-template/GEMINI.md)
```

**RC9 manifest regen:** REQUIRED (`project-template/` in v11-surface; trinity edits affect fixtures).

**Per-commit reviewer:** REQUIRED INLINE — sliding-window scope per Decision 4 (α-sliding) 2026-05-22. Covers the diff from H.0 baseline through this commit's HEAD: H.1 + H.2 + H.3 + H.4 (4 commits; H.4 is the first INLINE reviewer in the batch). Reviewer's scope explicitly includes the H.1 METHODOLOGY workflow additions + H.2 PM-CHAT.md behavioral rules + H.3 PM-CHAT.md STRENGTHEN + this commit's trinity STRENGTHEN. Boundary-sensitive surface for reviewer focus (per V2 §I + §H.4):
- **Trinity parity.** Verify byte-identical AFTER text across CLAUDE.md / AGENTS.md / GEMINI.md (project trinity rule).
- **BD-178 baseline correctness.** Verify the STRENGTHEN applied to the post-BD-178 HEAD form, not to V1's pre-BD-178 recorded BEFORE text.
- **Override 9 non-applicability.** Verify the bullet contains no CLI-specific paths; byte-identical application is correct here.
- **Defense-in-depth exception.** Verify the trinity placement is documented as defense-in-depth per V2 §D.6.3 (the rule is agent-affecting; trinity is the correct surface despite D-11 omniscience-principle default of single-source).
- **Sliding-window — H.1/H.2/H.3 coverage.** Verify the H.1 METHODOLOGY callouts, H.2 PM-CHAT.md behavioral-rules block, and H.3 PM-CHAT.md STRENGTHEN are reviewed by the same dimensions applicable to those commits (rule placement vs trinity vs PM-CHAT.md per D-11; cross-CLI / Override 9 considerations where applicable; manifest-regen attachment).

**Commit subject scope keyword:** (mixed — no keyword; project-template/ trinity + maintenance-docs/IMPL-REPORT + test-fixtures/manifest).

**Commit message:** `feat: v11 — BD-173 trinity destructive-ops list extension (Batch 19c.4)`

**Pack-coder PREFLIGHT line shape:** `PREFLIGHT: 3/3 in-scope file edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.4.md`


---

### H.5 — METHODOLOGY.md substantive additions (mid-phase planner triggers + rule-placement subsidiary + /tmp ephemerality)

**Scope:** §D.4 NEW METHODOLOGY.md Workflow 4 sub-section "Planner trigger conditions (mid-phase)" with P-A/P-B/P-C triggers + §D.2 REVISED-PLACEMENT NEW METHODOLOGY.md Part 9 sub-section "Rule placement: trinity vs PM-CHAT.md vs METHODOLOGY.md" (SUBSIDIARY to D-11 omniscience principle, with explicit forward reference to Part 1 — see Planner Observations §1 for the forward-reference rationale) + §C.12 NEW METHODOLOGY.md Part 9 appended paragraph "/tmp reports are ephemeral" REVISED-WORDING.

**Files modified:**
- `supporting-docs/METHODOLOGY.md` (3 substantive additions in Workflow 4 + Part 9)

**Edit specification:**

1. **§D.4 NEW sub-section — "Planner trigger conditions (mid-phase)".** Per V2 §D.4 text block verbatim. Insert as a new H4 sub-section in METHODOLOGY.md `## Part 5` → "Workflow 4" area, AFTER the existing "Architect trigger conditions" H4 sub-section (currently L489-508) AND its sibling "What the PM chat does when a trigger fires" H4 sub-section (currently L510-533). Insertion anchor: append after the architect-trigger H4 cluster as a new H4 `#### Planner trigger conditions (mid-phase)` block. The new sub-section is a sibling to the architect trigger conditions per V2 §D.4.
2. **§D.2 REVISED-PLACEMENT NEW sub-section — "Rule placement: trinity vs PM-CHAT.md vs METHODOLOGY.md".** Per V2 §D.2 text block verbatim. Insert as a new H3 sub-section in `## Part 9 — Document Authoring Rules` AFTER the existing "Desktop Commander scope for PM chat" sub-section (currently L1396-1412). Anchor: insert new H3 `### Rule placement: trinity vs PM-CHAT.md vs METHODOLOGY.md` between L1412 (end of Desktop Commander block) and L1414 (existing `---` separator before Part 10).
3. **§C.12 NEW paragraph — "/tmp reports are ephemeral".** Per V2 §C.12 text block verbatim (REVISED-WORDING — "paste into Pack Chat" → "for upstream debugging via PACK-FEEDBACK.md per Part 10"). Insert as a `>` callout paragraph IMMEDIATELY AFTER the "What agents can and cannot modify" table close (at L1394, the last row's closing `|`). Anchor: insert blank line + `>` callout block + blank line BEFORE the "Desktop Commander scope for PM chat" sub-section at L1396.

**Verification commands:**

```bash
python3 scripts/validate-pack.py
bash test-fixtures/build.sh --all --clean
git diff --stat test-fixtures/manifest.txt
# Verify the new sub-sections render as expected:
grep -n "^### Rule placement\|^#### Planner trigger conditions\|/tmp reports are ephemeral" supporting-docs/METHODOLOGY.md
```

**RC9 manifest regen:** REQUIRED (`supporting-docs/` in v11-surface).

**Per-commit reviewer:** REQUIRED INLINE — sliding-window scope per Decision 4 (α-sliding) 2026-05-22. Covers this commit's diff only (sliding window = H.5 alone; prior INLINE reviewer was H.4 covering H.1-H.4). Flipped from SKIP to INLINE per Decision 4 (b) 2026-05-22 + alignment with V2 §I + §J.6. Boundary-sensitive surface for reviewer focus (per V2 §I + §H.5):
- **Mid-phase planner triggers boundaries vs architect trigger demarcation.** Verify §D.4 P-A/P-B/P-C triggers do not overlap or conflict with the existing architect Trigger A/B (V2 §D.4 final paragraph "Planner-vs-architect demarcation" is the rule).
- **§D.2 subsidiary reference clarity.** Verify the new Part 9 sub-section's forward-reference to Part 1 "PM chat omniscience obligation" reads cleanly even though H.16 has not landed yet (one inter-commit forward reference per V2 §H.16 Ordering rationale; H.16 closes the forward-pointer).
- **§C.12 PACK-FEEDBACK.md cross-ref correctness.** Verify the rewrite drops "Pack Chat" audience cite per audit §3.1.12 and the PACK-FEEDBACK.md product-feature cross-ref resolves at client install.

**Commit subject scope keyword:** (mixed — no keyword; supporting-docs/ + maintenance-docs/IMPL-REPORT + test-fixtures/manifest).

**Commit message:** `feat: v11 — BD-173 METHODOLOGY.md substantive additions (mid-phase planner, rule placement subsidiary to PM-chat omniscience, /tmp ephemerality) (Batch 19c.5)`

**Pack-coder PREFLIGHT line shape:** `PREFLIGHT: 3/3 in-scope file edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.5.md`

---

### H.6 — METHODOLOGY.md Procedure 1 BACKLOG-proactive-surfacing STRENGTHEN

**Scope:** §C.3 STRENGTHEN — LAND per V1 D-3 = Alt-1 (CONDITIONAL flag closed).

**Files modified:**
- `supporting-docs/METHODOLOGY.md` (1 STRENGTHEN — single sentence appended to Procedure 1 step 2)

**Edit specification:**

1. **§C.3 STRENGTHEN — Procedure 1 step 2.** Per V2 §C.3 text block verbatim. Append to the end of Procedure 1 step 2 in the fenced code block at L1082-1094. Anchor: insert the new paragraph AFTER the existing parenthetical at L1093-1094 "(When all blockers resolve, the TD becomes Unblocked — see the resolution-path decision logic later in this Part for the V3.3 §3 promotion paths.)" and BEFORE the step 3 line (currently L1095 "3. For every Unblocked item:"). The appended text is the V2 §C.3 block (3 indented lines starting "The PM chat reports newly-unblocked items..."), formatted to match the fenced-block step-2 indent pattern.

**Verification commands:**

```bash
python3 scripts/validate-pack.py
bash test-fixtures/build.sh --all --clean
git diff --stat test-fixtures/manifest.txt
```

**RC9 manifest regen:** REQUIRED (`supporting-docs/` in v11-surface).

**Per-commit reviewer:** SKIP (per V2 §I; small STRENGTHEN; single sentence appended; not boundary-sensitive).

**Commit subject scope keyword:** (mixed — no keyword; supporting-docs/ + maintenance-docs/IMPL-REPORT + test-fixtures/manifest).

**Commit message:** `feat: v11 — BD-173 METHODOLOGY.md proactive BACKLOG surfacing (Batch 19c.6)`

**Pack-coder PREFLIGHT line shape:** `PREFLIGHT: 1/1 in-scope file edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.6.md`

---

### H.7 — PM-CHAT.md per-project Claude memory cache convention (§D.1 REVISED-WORDING)

**Scope:** §D.1 NEW paragraph in PM-CHAT.md "Tool-specific: Claude Code CLI" section. REVISED-WORDING per V2 §D.1 + salvageability B3 — drops "Tier 1.5 design" and "pack memory pattern" cross-side citations.

**Files modified:**
- `project-template/docs/pack/PM-CHAT.md` (1 NEW paragraph in `## Tool-specific: Claude Code CLI` section)

**Edit specification:**

1. **§D.1 NEW paragraph — per-project Claude memory cache convention.** Per V2 §D.1 text block verbatim. Insert as `>` callout block in `## Tool-specific: Claude Code CLI` section (currently L552), placement: after the existing "Compaction handling" sub-section at L592-595 and BEFORE the next `---` separator at L597 (which precedes the `## Tool-specific: Claude Web Projects` section). The new paragraph adds the Claude-only per-project memory convention without introducing pack-side terminology.

**Verification commands:**

```bash
python3 scripts/validate-pack.py
bash test-fixtures/build.sh --all --clean
git diff --stat test-fixtures/manifest.txt
# Verify the new paragraph contains no "Tier 1.5" or "pack memory" cross-side cites:
grep -nE "Tier 1\.5|pack memory" project-template/docs/pack/PM-CHAT.md | grep -v "^\s*<!--"
# Expected: no matches outside HTML comments (or grep returns no matches at all)
```

**RC9 manifest regen:** REQUIRED (`project-template/` in v11-surface).

**Per-commit reviewer:** SKIP (per V2 §I; NEW paragraph; project-side; single file).

**Commit subject scope keyword:** (mixed — no keyword; project-template/ + maintenance-docs/IMPL-REPORT + test-fixtures/manifest).

**Commit message:** `feat: v11 — BD-173 PM-CHAT.md per-project Claude memory cache convention (Batch 19c.7)`

**Pack-coder PREFLIGHT line shape:** `PREFLIGHT: 1/1 in-scope file edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.7.md`

---

### H.8 — (REMOVED — V1's H.8 was end-of-batch; V2 renumbers to H.17)

V1's H.8 was the end-of-batch reviewer + status flip. V2 renumbers to H.17 to accommodate H.9-H.16 (leak sweep + guardrails + D-11 principle landing) inserted between V1's H.7 and V1's H.8. **No commit at this slot.**

---

### H.9 — Leak sweep Categories A + B (per-entry skeleton sweep)

**Scope:** 30 leaks across 7 per-entry-tree skeleton files under `project-template/docs/project/{backlog,implementation-plan,changelog}/`. Per V2 §B.2 + leak-sweep-strategy §1.1 + §1.2.
- **Category A (25 leaks):** Delete the architect-doc cite clause; preserve the surrounding rule wording. Per AUDIT-PRE-19C-BOUNDARY-LEAKS.md §1.19.
- **Category B (5 leaks):** Substitute the architect-doc cite with sibling `_rules.md` reference or descriptive prose.

**Files modified (7 distinct files):**
- `project-template/docs/project/backlog/_rules.md` (Cat A: lines 5, 16, 21, 23, 25, 33, 36, 45)
- `project-template/docs/project/backlog/_intro.md` (Cat A: lines 32, 37, 51)
- `project-template/docs/project/implementation-plan/_rules.md` (Cat A: lines 5, 18, 23, 28, 29, 33, 45)
- `project-template/docs/project/implementation-plan/_intro.md` (Cat A: lines 42, 59)
- `project-template/docs/project/changelog/_rules.md` (Cat A: lines 5, 19, 30, 45, 48)
- `project-template/docs/project/changelog/_intro.md` (Cat B: line 53)
- `project-template/docs/project/changelog/_format.md` (Cat B: lines 5, 7, 50, 56)

**Edit specification:**

For each line in each Category A file: delete the parenthetical clause that names the pack-internal `ARCHITECTURE-*.md` cite. Examples (verbatim BEFORE forms at HEAD):
- `backlog/_rules.md:5` — BEFORE: `... per ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §3.3).` → AFTER: delete the cited clause; close the sentence naturally without the cite reference.
- `backlog/_rules.md:16` — BEFORE: `... digit zero-padded TD-NNN per ARCHITECTURE-V3.3-DELTA.md §6.4.` → AFTER: drop "per ARCHITECTURE-V3.3-DELTA.md §6.4" and end the sentence at "TD-NNN."

For Cat A lines, follow this mechanical pattern: scan each line for ` per ARCHITECTURE-*.md §<X>` OR ` (per ARCHITECTURE-*.md §<X>)` clause; delete the clause; restore terminal punctuation if needed. The surrounding RULE TEXT is preserved verbatim — only the cite clause drops.

For each line in each Category B file: substitute the cite with one of two replacement shapes per leak-sweep-strategy §1.2:
- **Shape B-1 (sibling `_rules.md` reference):** when the cited content's project-side analog is in the sibling `_rules.md` (same directory), substitute `per ARCHITECTURE-PER-ENTRY-SPLIT.md §3.5` → `per the sibling _rules.md` or similar phrasing per the surrounding prose.
- **Shape B-2 (descriptive prose):** when no clean sibling cite exists, substitute the cite with descriptive prose stating the rule directly. Per V2 §B.2 the Cat B substitutions land in `changelog/_intro.md:53` and `changelog/_format.md:5,7,50,56` — coder examines each line and picks B-1 or B-2 based on local prose context; both are acceptable per V2.

**Verification commands:**

```bash
# Verify zero pack-internal ARCHITECTURE-*.md cites remain in the 7 files:
grep -nE "ARCHITECTURE-PER-ENTRY-SPLIT|ARCHITECTURE-V3\.[13]-DELTA|ARCHITECTURE-V3\.md" project-template/docs/project/backlog/_rules.md project-template/docs/project/backlog/_intro.md project-template/docs/project/implementation-plan/_rules.md project-template/docs/project/implementation-plan/_intro.md project-template/docs/project/changelog/_rules.md project-template/docs/project/changelog/_intro.md project-template/docs/project/changelog/_format.md
# Expected: NO MATCHES.
python3 scripts/validate-pack.py
bash test-fixtures/build.sh --all --clean
git diff --stat test-fixtures/manifest.txt
```

**RC9 manifest regen:** REQUIRED (`project-template/` in v11-surface).

**Per-commit reviewer:** REQUIRED INLINE — sliding-window scope per Decision 4 (α-sliding) 2026-05-22. Covers the diff from the prior INLINE commit (H.5) through this commit's HEAD: H.6 + H.7 + H.9 (3 commits; H.8 was removed and renumbered to H.17). Reviewer's scope explicitly includes the H.6 METHODOLOGY Procedure 1 BACKLOG-proactive-surfacing STRENGTHEN + H.7 PM-CHAT.md per-project Claude memory cache addition + this commit's leak sweep. Boundary-sensitive surface for reviewer focus (per V2 §I + §H.9):
- **Each cite correctly dropped OR replaced.** Verify each of the 30 cites named in audit §1.19 has been remediated (Cat A drop; Cat B substitute). Spot-check 5 lines randomly.
- **Rule wording preserved.** Verify the surrounding RULE TEXT is unchanged — only the cite clause drops. Diff each file's prose for unintended edits.
- **No new leaks introduced.** Scan the 7 files for any newly-added bare `ARCHITECTURE-*` / `AUDIT-*` / `maintenance-docs/` reference that the rewrite might have introduced inadvertently.
- **Sliding-window — H.6/H.7 coverage.** Verify the H.6 Procedure 1 BACKLOG-surface STRENGTHEN and H.7 PM-CHAT.md per-project memory cache paragraph are reviewed by the dimensions applicable to those commits (rule placement, project-side SSOT correctness, REVISED-WORDING per V2 §D.1 drop of "Tier 1.5" / "pack memory" cross-cites).

**Commit subject scope keyword:** (mixed — no keyword; project-template/ + maintenance-docs/IMPL-REPORT + test-fixtures/manifest).

**Commit message:** `feat: v11 — BD-173 leak sweep Categories A + B — per-entry skeleton boundary cleanup (Batch 19c.9)`

**Pack-coder PREFLIGHT line shape:** `PREFLIGHT: 7/7 in-scope file edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.9.md`


---

### H.10 — Leak sweep Categories D + E + F (mechanical sweep: detect.sh + pm-startup cluster + boundary-investigation skill cite)

**Scope:** 8 leaks across 6 files. Per V2 §B.2 + leak-sweep-strategy §1.4 + §1.5 + §1.6.
- **Category D (3 leaks):** Drop the cite entirely; bare prose stands.
- **Category E (4 leaks):** pm-startup cluster sibling sweep — drop `ARCHITECTURE-V3.md §28.1.5` cite tail across 4 sibling files.
- **Category F (1 leak):** BD-175 self-leak — replace `AUDIT-USER-CURATION.md Override 1` cite with descriptive prose.

**Files modified (7 distinct files):**
- `scripts/lib/detect.sh` (Cat D — 2 cites dropped: lines 335 + 678)
- `project-template/docs/pack/PM-CHAT.md` (Cat D — 1 cite dropped: line 410)
- `project-template/skills/pm-startup/SKILL.md` (Cat E — line 258 cite tail dropped)
- `project-template/.claude/skills/pm-startup/SKILL.md` (Cat E — line 258 cite tail dropped)
- `project-template/.codex/skills/pm-startup/SKILL.md` (Cat E — line 258 cite tail dropped)
- `project-template/.gemini/commands/pm-startup.toml` (Cat E — line 255 cite tail dropped)
- `project-template/skills/boundary-investigation/SKILL.md` (Cat F — line 124 cite replaced with prose)

**Edit specification:**

1. **Cat D — `scripts/lib/detect.sh:335`.** BEFORE: `# (maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md):` → AFTER: delete the comment line OR rewrite the comment to drop the path-prefix cite (e.g., generic explanatory comment without the file reference). Per leak-sweep-strategy §1.4 the comment was footnote-style provenance; deletion is cleanest.
2. **Cat D — `scripts/lib/detect.sh:678`.** BEFORE: `# maintenance-docs/v11-implementation/ARCHITECTURE-DEPLOYMENT-PYTHON-OBSERVABILITY.md:` → AFTER: same treatment as item 1.
3. **Cat D — `project-template/docs/pack/PM-CHAT.md:410`.** BEFORE: `ARCHITECTURE-V3.3-DELTA.md §3.1:` (cite within prose) → AFTER: delete the cite phrase; if the surrounding prose loses meaning, restore a brief descriptive replacement that resolves at client install. Coder reads ±5 lines context first.
4. **Cat E — pm-startup cluster sibling sweep.** Four files have `Reference: ARCHITECTURE-V3.md §28.1.5 (should-recommend test),` at lines 258 (canonical + `.claude/` + `.codex/` mirrors) and 255 (`.gemini/` toml). For each: drop the `Reference: ARCHITECTURE-V3.md §28.1.5 (should-recommend test),` tail OR rewrite the surrounding prose to omit the cite while preserving the "should-recommend test" semantic. Per leak-sweep-strategy §1.5 recommended shape: drop the cite entirely (footnote provenance not load-bearing). Apply byte-identically across the 4 files (pack-shipped distribution pattern).
5. **Cat F — boundary-investigation skill self-leak.** `project-template/skills/boundary-investigation/SKILL.md:124` BEFORE: `pack root per AUDIT-USER-CURATION.md Override 1; not installed at` → AFTER: replace with descriptive prose per V2 §B.2 Cat F: `STAYS at pack root per pack-repo audit finding; not installed at`. Coder reads ±3 lines context for natural insertion. The replacement removes the pack-internal `AUDIT-USER-CURATION.md` cite while preserving the rule (the file STAYS at pack root for a documented reason).

**Verification commands:**

```bash
# Verify zero remaining Cat D/E/F leaks:
grep -nE "maintenance-docs|ARCHITECTURE-V3\.md|AUDIT-USER-CURATION" scripts/lib/detect.sh project-template/docs/pack/PM-CHAT.md project-template/skills/pm-startup/SKILL.md project-template/.claude/skills/pm-startup/SKILL.md project-template/.codex/skills/pm-startup/SKILL.md project-template/.gemini/commands/pm-startup.toml project-template/skills/boundary-investigation/SKILL.md
# Expected: NO MATCHES (or matches only inside intentional fenced-content per H.13).
python3 scripts/validate-pack.py
bash test-fixtures/build.sh --all --clean
git diff --stat test-fixtures/manifest.txt
# Verify pm-startup cluster siblings remain byte-identical at line ~258 area:
diff <(sed -n '256,260p' project-template/skills/pm-startup/SKILL.md) <(sed -n '256,260p' project-template/.claude/skills/pm-startup/SKILL.md)
diff <(sed -n '256,260p' project-template/skills/pm-startup/SKILL.md) <(sed -n '256,260p' project-template/.codex/skills/pm-startup/SKILL.md)
```

**RC9 manifest regen:** REQUIRED (`project-template/` + `scripts/` both in v11-surface).

**Per-commit reviewer:** REQUIRED INLINE — sliding-window scope per Decision 4 (α-sliding) 2026-05-22. Covers this commit's diff only (sliding window = H.10 alone; prior INLINE reviewer was H.9 covering H.6+H.7+H.9). Boundary-sensitive surface for reviewer focus (per V2 §I + §H.10):
- **Each cite removal preserves surrounding prose intelligibility.** Verify each Cat D / Cat E drop reads cleanly without the cite.
- **pm-startup cluster sibling sweep byte-identical.** Verify the 4 sibling files (canonical + 3 mirrors) have parallel edits — per pack-shipped distribution pattern.
- **Cat F boundary-investigation skill replacement does NOT re-introduce a different leak.** Verify the new descriptive prose does not name another pack-internal target (`maintenance-docs/...`, other audit doc, etc.). The replacement prose per V2 §B.2 Cat F is "STAYS at pack root per pack-repo audit finding; not installed at client" — this names no specific pack file and is correct.

**Commit subject scope keyword:** (mixed — no keyword; touches `project-template/` AND `scripts/`).

**Commit message:** `feat: v11 — BD-173 leak sweep Categories D + E + F — mechanical cite cleanup + BD-175 self-leak fix (Batch 19c.10)`

**Pack-coder PREFLIGHT line shape:** `PREFLIGHT: 7/7 in-scope file edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.10.md`

---

### H.11 — Leak sweep Category C — pm-chat variant rewrites (C-c direction)

**Scope:** 3 leaks. Rewrite 3 pm-chat self-prompt variants per V2 §B.2 + user direction C-c (rewrite to client-side equivalents). Variants: manual-fallback (cite `supporting-docs/SETUP-NEW.md`), generate-setup (cite `supporting-docs/SETUP_TEMPLATE.md`), generate-agent-kickoff (cite `supporting-docs/AGENT_KICKOFF_TEMPLATE.md`). All three cited files are NOT shipped to clients per AUDIT-PRE-19C-BOUNDARY-LEAKS.md §0.3 Note 2.

**Files modified:**
- `project-template/docs/pack/prompts/pm-chat.md` (3 variant rewrites at lines 94-96, 182-189, 227-234)

**Edit specification:**

1. **Manual-fallback variant (currently lines 94-96).** BEFORE: cites `supporting-docs/SETUP-NEW.md § Manual fallback (sub-sections 5.A-5.D)`. AFTER per V2 §H.11: rewrite to cite `docs/pack/INSTALL-PROCEDURES.md` Procedure 7 (manual install equivalent; verified client-installed per `init-project.sh` `_CLIENT_INSTALLED_FILES_START`/`_END` — `supporting-docs/INSTALL-PROCEDURES.md` is copied to `docs/pack/INSTALL-PROCEDURES.md`). Coder reads `supporting-docs/INSTALL-PROCEDURES.md` Procedure 7 to confirm it carries equivalent manual-install steps; if Procedure 7 is the wrong target, escalate to Pack Chat for re-scope.
2. **Generate-setup variant (currently lines 182-189).** BEFORE: cites `supporting-docs/SETUP_TEMPLATE.md`. AFTER per V2 §H.11 has 3 sub-options ordered by preference:
   - (a) **Inline the setup template content as prose** within the variant body (the variant generates the setup; no template-file pre-existence needed at client install).
   - (b) **Reference `docs/pack/SETUP-EXISTING.md` if it has equivalent content.** Coder verifies `project-template/docs/pack/SETUP-EXISTING.md` exists at HEAD; if YES, use it as the template source; if NO, fall back to (a).
   - (c) **Rewrite the variant to construct a setup template from project trinity + METHODOLOGY.md inputs.** This is the C-c-pure form: the variant assembles a setup template from already-installed project content.
   - Coder picks based on `docs/pack/SETUP-EXISTING.md` presence and content fitness. Default to (a) if (b) doesn't fit.
3. **Generate-agent-kickoff variant (currently lines 227-234).** BEFORE: cites `supporting-docs/AGENT_KICKOFF_TEMPLATE.md`. AFTER per V2 §H.11 has 2 sub-options:
   - (a) **Inline the agent-kickoff template content as prose** within the variant body.
   - (b) **Reference project-side prompt files at `docs/pack/prompts/<agent>.md`** for per-agent kickoff scaffolding (each agent's prompt file IS the kickoff template at client install).
   - Coder picks per fitness; default to (b) since the per-agent prompt files exist client-side and are the natural kickoff source.

**Verification commands:**

```bash
# Verify zero supporting-docs/SETUP-NEW.md / SETUP_TEMPLATE.md / AGENT_KICKOFF_TEMPLATE.md cites in pm-chat.md:
grep -nE "supporting-docs/SETUP|supporting-docs/AGENT_KICKOFF" project-template/docs/pack/prompts/pm-chat.md
# Expected: NO MATCHES.
python3 scripts/validate-pack.py
bash test-fixtures/build.sh --all --clean
git diff --stat test-fixtures/manifest.txt
```

**RC9 manifest regen:** REQUIRED (`project-template/` in v11-surface).

**Per-commit reviewer:** REQUIRED INLINE — sliding-window scope per Decision 4 (α-sliding) 2026-05-22. Covers this commit's diff only (sliding window = H.11 alone; prior INLINE reviewer was H.10 covering H.10). Boundary-sensitive surface for reviewer focus (per V2 §I + §H.11):
- **Each variant's user-facing contract preserved.** Manual-fallback still completes manual install; generate-setup still produces a setup; generate-agent-kickoff still produces agent-kickoff scaffolding. The MECHANICS differ; the OUTCOME contract must match.
- **No new leaks introduced in rewritten content.** Verify the rewrites do not cite any pack-internal file (`supporting-docs/X.md` where `X` is not client-installed; `maintenance-docs/`; `pack-ops/`; etc.).
- **References resolve at client install.** Verify cited files (e.g., `docs/pack/INSTALL-PROCEDURES.md`, `docs/pack/SETUP-EXISTING.md`, `docs/pack/prompts/<agent>.md`) all exist post-`init-project.sh` install (per `_CLIENT_INSTALLED_FILES_START`/`_END` + mass-copied `project-template/` tree).

**Commit subject scope keyword:** (mixed — no keyword; project-template/ + maintenance-docs/IMPL-REPORT + test-fixtures/manifest).

**Commit message:** `feat: v11 — BD-173 leak sweep Category C — pm-chat variant rewrites to client-side equivalents (Batch 19c.11)`

**Pack-coder PREFLIGHT line shape:** `PREFLIGHT: 1/1 in-scope file edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.11.md`

---

### H.12 — Guardrail 3 implementation (`_PROJECT_SIDE_ROOTS` scope expansion to full client-installed surface)

**Scope:** Per ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md §3. Replace `_PROJECT_SIDE_ROOTS = ("project-template",)` (currently `scripts/validate-pack.py:3762`) with `_iter_client_installed_files()` helper that returns the union of (a) all files under `project-template/` and (b) explicit non-project-template entries from `_CLIENT_INSTALLED_FILES`. Add Group 7 fixture-test cases to `scripts/tests/test-validate-pack-checks-36-37-38.sh`.

**Files modified:**
- `scripts/validate-pack.py` (new helper + delegation rewrite)
- `scripts/tests/test-validate-pack-checks-36-37-38.sh` (new Group 7 test cases)

**Edit specification:**

Per GUARDRAILS-CONTRACT.md §3.1 + §3.2 + §3.3 + §3.4.

1. **Add new helper `_iter_client_installed_files()` to `scripts/validate-pack.py`.** Per GUARDRAILS-CONTRACT.md §3.1 verbatim function body. Position: near the existing `_iter_project_side_files()` at L4059. The new helper parses `_CLIENT_INSTALLED_FILES_START`/`_END` from `scripts/init-project.sh` via the existing `_parse_client_installed_files()` helper (used by Check 41).
2. **Replace `_PROJECT_SIDE_ROOTS` constant.** Per GUARDRAILS-CONTRACT.md §3.2 verbatim replacement comment block at L3762. The constant is REMOVED; a documentation comment notes the rationale.
3. **Update `_iter_project_side_files()` to delegate.** Per GUARDRAILS-CONTRACT.md §3.2 caller-update plan: change the body at L4059-end to delegate into `_iter_client_installed_files()` (thin alias; documented as deprecated; preserves call-site at L4173 without change).
4. **Add Group 7 fixture-test cases.** Per GUARDRAILS-CONTRACT.md §3.4 T1-T4 verbatim test cases. Append to `scripts/tests/test-validate-pack-checks-36-37-38.sh` after the existing Group 5 (currently at line 289 area). The Group 6 from H.13 is NOT yet present — Group 7 lands now, Group 6 lands in H.13 (slight numbering inversion; planned per GUARDRAILS-CONTRACT.md §3.4 vs §2.6 — see Planner Observations §2).

**Verification commands:**

```bash
python3 scripts/validate-pack.py
# Verify Check 37 expanded scope catches the H.10-cleared leaks would now FAIL pre-H.10 (but post-H.10 PASSES):
bash scripts/tests/test-validate-pack-checks-36-37-38.sh
bash test-fixtures/build.sh --all --clean
git diff --stat test-fixtures/manifest.txt
```

**RC9 manifest regen:** REQUIRED (`scripts/` in v11-surface per BD-176).

**Per-commit reviewer:** SKIP (per V2 §I + §H.12; mechanical scope expansion; test coverage added; pure pack-side validate-pack.py changes with no project-side surface impact beyond cleared-leak ratification).

**Commit subject scope keyword:** `pack-only` (only `scripts/` edits).

**Commit message:** `feat: v11 — BD-173 Guardrail 3 — _PROJECT_SIDE_ROOTS expansion to full client-installed surface (Batch 19c.12)`

**Pack-coder PREFLIGHT line shape:** `PREFLIGHT: 2/2 in-scope file edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.12.md`

**Ordering dependency:** MUST land AFTER H.10 (Cat D detect.sh fixes). Pre-H.10, validate-pack.py with expanded scope FAILs on detect.sh:335 + detect.sh:678 (the qualified `maintenance-docs/` prefix triggers Check 37's path-prefix detection). Per GUARDRAILS-CONTRACT.md §3.3 "self-validating change" principle: leak sweep MUST clear the existing leaks BEFORE scope expansion ratifies the cleaned state.


---

### H.13 — Guardrail 2 implementation (per-line exemption fence; Check 37 modification)

**Scope:** Per ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md §2. Replace `_is_legitimate_deny_list_doc()` whole-file exemption with per-line `<!-- DENY-LIST-CONTENT-START -->` / `<!-- DENY-LIST-CONTENT-END -->` fence support. Place fence markers in 7 files per `_CHECK_37_PER_LINE_FENCE_FILES` enumeration. Add Group 6 fixture-test cases.

**Files modified:**
- `scripts/validate-pack.py` (helper add + function replacement)
- `project-template/skills/boundary-investigation/SKILL.md` (fence markers around Step 4 enumeration block)
- `project-template/docs/pack/prompts/coder.md` (fence markers around deny-list blocks at lines 83-89 + 195-202)
- `project-template/docs/pack/prompts/reviewer.md` (fence markers around deny-list block at lines 102-107)
- `project-template/CLAUDE.md` (fence markers around the "Project SSOT-first" pack-only-files enumeration in `## Project memory`)
- `project-template/AGENTS.md` (parallel fence markers per project trinity rule)
- `project-template/GEMINI.md` (parallel fence markers per project trinity rule)
- `project-template/docs/pack/PM-CHAT.md` (per GUARDRAILS-CONTRACT.md §2.3 — verify scope; if PM-CHAT.md is in `_CHECK_37_PER_LINE_FENCE_FILES` per contract, fence markers go here too)
- `scripts/tests/test-validate-pack-checks-36-37-38.sh` (Group 6 test cases)

**Edit specification:**

Per GUARDRAILS-CONTRACT.md §2.1 + §2.2 + §2.3 + §2.4 + §2.5 + §2.6.

1. **Add new helpers to `scripts/validate-pack.py`.** Per GUARDRAILS-CONTRACT.md §2.3 verbatim:
   - `_has_per_line_fence(rel_path: Path) -> bool` (new function)
   - `_build_fence_skip_lineset(text: str) -> set[int]` (new function — parses paired markers; FAIL on unbalanced / nested per §2.5)
2. **Add new constant `_CHECK_37_PER_LINE_FENCE_FILES`.** Per GUARDRAILS-CONTRACT.md §2.3 verbatim 7-entry tuple.
3. **REMOVE `_is_legitimate_deny_list_doc()` function (currently L4084-4133).** Function deleted entirely.
4. **Modify `check_project_side_deny_list()` body at L4136.** Per GUARDRAILS-CONTRACT.md §2.3 BEFORE/AFTER body diff verbatim: replace the call-site at L4173-4174 with the new fence-aware loop body.
5. **Place fence markers in `project-template/skills/boundary-investigation/SKILL.md`.** Per GUARDRAILS-CONTRACT.md §2.2 exact placement:
   - Insert `<!-- DENY-LIST-CONTENT-START -->` between current L97 and L98 (AFTER "The pack-only deny-list (not exhaustive; CI Check 37 enforces the canonical list):" line + blank line, BEFORE the bulleted list at L99).
   - Insert `<!-- DENY-LIST-CONTENT-END -->` between current L126 and L128 (AFTER the last bullet about `tracker.toml.pack-example` exemption at L126, BEFORE the next blank line / next H3 "### Step 5" at L128).
   - Note: line numbers will shift slightly after the Cat F edit at L124 from H.10. Coder reads fresh HEAD form and pins fence-open to the line BEFORE the bulleted deny-list begins, fence-close to the line AFTER the last bullet about `tracker.toml.pack-example`.
6. **Place fence markers in `project-template/docs/pack/prompts/coder.md`.** Per GUARDRAILS-CONTRACT.md §2.4: TWO fence pairs needed.
   - Pair 1: around the deny-list block at L83-89 (the standard-variant boundary-discipline block). Fence-open BEFORE L83 ("If the change would introduce a reference..."); fence-close AFTER L89 ("...pollute project intent.").
   - Pair 2: around the parallel block at L195-202 (the fix-cycle variant). Fence-open BEFORE L199 ("If the fix would introduce a reference..."); fence-close AFTER L202 ("...do not improvise a fix.").
   - Coder reads ±5 lines context for both pairs; the fence wraps only the deny-list-enumeration substring, NOT the surrounding instructional prose.
7. **Place fence markers in `project-template/docs/pack/prompts/reviewer.md`.** Per GUARDRAILS-CONTRACT.md §2.4: single fence pair around the deny-list block at L102-107. Fence-open BEFORE L101 ("If the change would cross-reference a file outside the project..."); fence-close AFTER L107 ("...with rationale).").
8. **Place fence markers in project-template trinity (CLAUDE.md / AGENTS.md / GEMINI.md).** Per GUARDRAILS-CONTRACT.md §2.4: fence around the "Project SSOT-first" pack-only-files enumeration in `## Project memory`. Coder reads the bullet (currently in CLAUDE.md ~L381-410 area) — the bullet text starts with "When making any change to a project file..." and ends with "...the boundary-investigation skill for the SSOT-investigation methodology." Within the bullet, the deny-list ENUMERATION is the parenthetical (`PACK-AGENTS.md, PACK-CHAT.md, pack-* agent prompts, pack-repo maintenance-docs/, pack-repo pack-ops/ — any file under pack-ops/, including BOUNDARY-DEFINITION.md, BACKLOG.md, CHANGELOG.md, etc.`). Place fence markers around this parenthetical specifically — fence-open BEFORE the parenthetical's first character, fence-close AFTER the closing paren `etc.)`. Apply byte-identically across all three trinity files per project trinity rule.
9. **Place fence markers in `project-template/docs/pack/PM-CHAT.md`** (per GUARDRAILS-CONTRACT.md §2.3 the file IS in `_CHECK_37_PER_LINE_FENCE_FILES`; coder verifies the constant and applies fences IF PM-CHAT.md has deny-list-pattern enumeration content. Per current HEAD examination, PM-CHAT.md does not have an explicit deny-list-enumeration block — fence is OPTIONAL per §2.5 invariant "At least one START + END pair per fence-allowlisted file at HEAD." If PM-CHAT.md has no deny-list-enumeration substring, coder places an EMPTY fence pair (START immediately followed by END per §2.5) at a defensible location, OR Pack Chat re-scopes PM-CHAT.md OFF `_CHECK_37_PER_LINE_FENCE_FILES`. Default: place empty fence pair near the existing Part 10 PACK-FEEDBACK reference area to satisfy the §2.5 invariant. See Planner Observations §4.)
10. **Add Group 6 fixture-test cases to `scripts/tests/test-validate-pack-checks-36-37-38.sh`.** Per GUARDRAILS-CONTRACT.md §2.6 T1-T8 verbatim — 8 test cases covering balanced/unbalanced/nested/empty/outside-fence/multi-fence scenarios. Append Group 6 after Group 5 at line 289 area; the previously-added Group 7 from H.12 lands AFTER Group 6 (planner notes the §2.6 vs §3.4 ordering inversion — Group 7 lands first via H.12, Group 6 lands via H.13 between Group 5 and Group 7; sequencing matches GUARDRAILS-CONTRACT.md §5.1 commit order).

**Verification commands:**

```bash
python3 scripts/validate-pack.py
bash scripts/tests/test-validate-pack-checks-36-37-38.sh
# Verify fence markers placed in all 7+ files:
grep -nE "DENY-LIST-CONTENT-START|DENY-LIST-CONTENT-END" project-template/skills/boundary-investigation/SKILL.md project-template/docs/pack/prompts/coder.md project-template/docs/pack/prompts/reviewer.md project-template/CLAUDE.md project-template/AGENTS.md project-template/GEMINI.md project-template/docs/pack/PM-CHAT.md
# Verify outside-fence content does NOT contain pack-internal cites (H.10 Cat F cleared the boundary-investigation skill's AUDIT-USER-CURATION.md cite):
python3 -c "import subprocess; r = subprocess.run(['grep', '-nE', 'AUDIT-|maintenance-docs/', 'project-template/skills/boundary-investigation/SKILL.md'], capture_output=True, text=True); print(r.stdout)"
bash test-fixtures/build.sh --all --clean
git diff --stat test-fixtures/manifest.txt
```

**RC9 manifest regen:** REQUIRED (`project-template/` + `scripts/` both in v11-surface).

**Per-commit reviewer:** REQUIRED INLINE — sliding-window scope per Decision 4 (α-sliding) 2026-05-22. Covers the diff from the prior INLINE commit (H.11) through this commit's HEAD: H.12 + H.13 (2 commits). Reviewer's scope explicitly includes the H.12 Guardrail 3 `_PROJECT_SIDE_ROOTS` scope expansion + new validate-pack.py test cases + this commit's fence implementation. Boundary-sensitive surface for reviewer focus (per V2 §I + §H.13):
- **Fence placement preserves intended exempt-content scope.** Verify each fence pair wraps ONLY the deny-list-enumeration substring, NOT surrounding instructional prose.
- **Outside-fence content does NOT contain pack-internal cites.** H.10 Cat F should have cleared the boundary-investigation skill's `AUDIT-USER-CURATION.md` cite first. Verify by grep — outside-fence lines should be clean of `AUDIT-*` / `maintenance-docs/` / pack-only-target patterns.
- **Trinity fence parity.** Verify the three trinity files have identical fence placement around the "Project SSOT-first" parenthetical (per project trinity rule).
- **`_is_legitimate_deny_list_doc()` callers updated.** Verify no stray references to the deleted function remain in `validate-pack.py`.
- **Empty fence handling for PM-CHAT.md.** If coder placed empty fence pair (per item 9 above), verify it satisfies §2.5 invariant and does not mask any legitimate content.
- **Sliding-window — H.12 coverage.** Verify H.12 Guardrail 3 `_iter_client_installed_files()` helper, `_PROJECT_SIDE_ROOTS` constant replacement / delegation, and Group 7 fixture-test cases are reviewed by the dimensions applicable to that commit (contract §3 fidelity; self-validating-change correctness; test coverage completeness; manifest-regen attachment).

**Commit subject scope keyword:** (mixed — no keyword; touches `project-template/` AND `scripts/`).

**Commit message:** `feat: v11 — BD-173 Guardrail 2 — per-line deny-list fence (Check 37 modification + 7 files fenced) (Batch 19c.13)`

**Pack-coder PREFLIGHT line shape:** `PREFLIGHT: 9/9 in-scope file edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.13.md`

**Ordering dependency:** MUST land AFTER H.10 (Cat F removes the BD-175 self-leak from boundary-investigation/SKILL.md:124). Otherwise the fence would ratify a still-leaking state. Per GUARDRAILS-CONTRACT.md §5.1.

---

### H.14 — Guardrail 1 implementation (Check 43 — project-side bare cross-reference scanner)

**Scope:** Per ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md §1. Add `check_project_side_bare_internal_refs()` function in `scripts/validate-pack.py` reusing Check 40's basename-index + allowlist + anchor-phrases + code-block-stripping mechanism. Add `_CHECK_43_ALLOWLIST` constant (~25-30 entries per §1.4). Add new fixture test file `scripts/tests/test-validate-pack-check-43.sh` with 7 test groups + 13 fixture files. Wire the test in `.github/workflows/validate-pack.yml`.

**Files modified:**
- `scripts/validate-pack.py` (new Check 43 function + allowlist + anchor-phrase aliases)
- `scripts/tests/test-validate-pack-check-43.sh` (NEW file)
- `scripts/tests/fixtures/project-side-refs/` (NEW directory; 13 fixture files: 7 FAIL + 5 PASS + 1 README)
- `.github/workflows/validate-pack.yml` (1 new test-invocation line)

**Edit specification:**

Per GUARDRAILS-CONTRACT.md §1.1 through §1.12.

1. **Add `check_project_side_bare_internal_refs()` function to `scripts/validate-pack.py`.** Per §1.1 signature + §1.2 walked file set + §1.3 basename-index reuse + §1.7 fail/pass conditions + §1.8 failure-message format + §1.9 mirror-skip exclusions verbatim. The function reuses Check 40's `_build_basename_index()`, `_strip_code_blocks()`, `_CHECK_40_BARE_REF_PATTERN`, `_CHECK_40_HYPERLINK_PATTERN` mechanisms (NO new regex). Position: after the existing Check 40 function in `validate-pack.py`.
2. **Add `_CHECK_43_ALLOWLIST` constant.** Per §1.4 verbatim — ~30 entries with one-line rationale per entry (Check 40 §6.5 self-documenting convention).
3. **Add `_CHECK_43_ANCHOR_PHRASES = _CHECK_40_ANCHOR_PHRASES` and `_CHECK_43_ANCHOR_WINDOW = _CHECK_40_ANCHOR_WINDOW` aliases.** Per §1.5 verbatim.
4. **Wire `check_project_side_bare_internal_refs()` into the main check sequence.** At `validate-pack.py:5463` area where existing checks are invoked (e.g., `check_project_side_deny_list()`), add a call to the new Check 43 function.
5. **Create `scripts/tests/test-validate-pack-check-43.sh`.** Follow the structural pattern of existing `test-validate-pack-check-40.sh`. Per §1.10 — 7 test groups (Group 0-6) + 13 fixture files referenced from `scripts/tests/fixtures/project-side-refs/`.
6. **Create fixture directory `scripts/tests/fixtures/project-side-refs/` with 13 files.** Per §1.10 enumeration verbatim — 7 FAIL fixtures (per LEAK CLASS A/C/D/E/F coverage), 5 PASS fixtures (allowlist + anchor + same-dir + code-block + cross-boundary), 1 README.
7. **Wire the new test in `.github/workflows/validate-pack.yml`.** Per §1.11 verbatim YAML block. Insert AFTER the existing Check 42 wiring at L183. Per Check 42 contract — wiring the new test file makes Check 42 PASS for `test-validate-pack-check-43.sh`.

**Verification commands:**

```bash
python3 scripts/validate-pack.py
# Check 43 must PASS at HEAD post-H.9 + H.10 + H.11 + H.12 + H.13 (all leak-sweep + scope expansion + fence work landed):
bash scripts/tests/test-validate-pack-check-43.sh
# Check 42 PASSES because the new test file is wired into CI:
bash scripts/tests/test-validate-pack-check-42.sh
bash test-fixtures/build.sh --all --clean
git diff --stat test-fixtures/manifest.txt
# Verify 13 fixture files exist:
ls scripts/tests/fixtures/project-side-refs/ | wc -l
# Expected: 13
```

**RC9 manifest regen:** REQUIRED (`scripts/` in v11-surface; `.github/workflows/` is NOT in RC9 trigger set, but the `scripts/` change forces regen).

**Per-commit reviewer:** REQUIRED INLINE — sliding-window scope per Decision 4 (α-sliding) 2026-05-22. Covers this commit's diff only (sliding window = H.14 alone; prior INLINE reviewer was H.13 covering H.12+H.13). Boundary-sensitive surface for reviewer focus (per V2 §I + §H.14):
- **Check 43 implementation matches §1 contract.** Verify class-test (basename-index resolution into pack-only territory) vs name-enumeration semantic; verify allowlist (~30 entries with rationale); verify supporting-docs/ subset rule (FAIL on `supporting-docs/<X>` where `<X>` not in client-install set).
- **Fail-condition coverage.** Verify the 4 FAIL classes per §1.7: pack-internal target, pre-install-only `supporting-docs/`, broken, ambiguous.
- **Fixture-test enumeration.** Verify 13 fixture files exist + 7 test groups + 9 synthetic-tree cases per §1.10.
- **CI wiring.** Verify Check 42 PASSES — the new test file has a corresponding `bash scripts/tests/test-validate-pack-check-43.sh` invocation in the workflow.
- **All 36 audit leaks would FAIL Check 43.** Per §1.12 cross-walk — verify mechanically by running Check 43 against a synthetic state where the leak sweep had not landed; expect 36 failures. (Optional spot-check; the leak-sweep H.9-H.11 + H.13 fence already cleared the leaks at HEAD.)

**Commit subject scope keyword:** (mixed — no keyword; touches `scripts/` AND `.github/`).

**Commit message:** `feat: v11 — BD-173 Guardrail 1 — Check 43 (project-side bare cross-reference scanner; V11 leak-sweep prevention) (Batch 19c.14)`

**Pack-coder PREFLIGHT line shape:** `PREFLIGHT: 17/17 in-scope file edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.14.md`

**Ordering dependency:** MUST land AFTER H.12 (Guardrail 3 provides `_iter_client_installed_files()` helper that Check 43 walks) AND AFTER H.13 (per-line fence interacts with the Check 37 exemption logic that Check 43's allowlist coordinates with). Per GUARDRAILS-CONTRACT.md §5.1.


---

### H.15 — Guardrail 4 implementation (PREFLIGHT extension — pre-commit defense-in-depth)

**Scope:** Per ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md §4. Extend pack-coder PREFLIGHT spec to include Check 43 verification step. Modifications across PACK-AGENTS.md PREFLIGHT spec + pack-root trinity PREFLIGHT bullets + pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md dimension (d).

**Files modified:**
- `pack-ops/PACK-AGENTS.md` (PREFLIGHT spec edit at L190-211 area)
- `CLAUDE.md` (pack-root; PREFLIGHT bullet at L286-322 — append Check 43 verification step)
- `AGENTS.md` (pack-root; PREFLIGHT bullet at L286-322 — same append)
- `GEMINI.md` (pack-root; PREFLIGHT bullet at L253-291 — same append)
- `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` (dimension (d) extension at L37 area)

(Pack Chat applies the memory-cache update at `~/.claude/projects/<slug>/memory/feedback_pack_coder_preflight_pattern.md` SEPARATELY per GUARDRAILS-CONTRACT.md §4.3 — outside this commit; user-local file lives outside the repo.)

**Edit specification:**

Per GUARDRAILS-CONTRACT.md §4.1 + §4.2 + §4.4.

1. **PACK-AGENTS.md PREFLIGHT spec edit.** Per §4.1 verbatim. Insert the new Check 43 verification paragraph AFTER the existing PREFLIGHT line description at `pack-ops/PACK-AGENTS.md:199` ("complete-and-green state.") and BEFORE the STOP-MEANS-STOP sub-bullet at L201. The inserted text describes Check 43 invocation, trigger surface (v11-surface 4-directory trigger), failure-report-instead-of-IMPL-REPORT behavior.
2. **Pack-root trinity PREFLIGHT bullet edits.** Apply the same Check 43 verification step content to the pack-root trinity PREFLIGHT bullets. Read each file:
   - `/CLAUDE.md` "Pack-coder PREFLIGHT + STOP-MEANS-STOP pattern" bullet at L286-322. Append the Check 43 verification step content within the PREFLIGHT (platform-neutral, REQUIRED for all CLIs) sub-bullet — same text as PACK-AGENTS.md PREFLIGHT edit (PREFLIGHT is platform-neutral; Override 9 does NOT diverge per-CLI for this content).
   - `/AGENTS.md` parallel bullet at L286-322. Same content append.
   - `/GEMINI.md` parallel bullet at L253-291. Same content append.
   - Apply byte-identically across all three pack-root trinity files per pack-repo trinity rule (`CLAUDE.md` § "Trinity rule").
3. **CONCEPTUAL-REVIEW-METHODOLOGY.md dimension (d) extension.** Per §4.2 verbatim. Append the boundary-discipline-note sentence to the existing `### (d) Pack rule adherence` paragraph at L37. The new text adds the "when reviewing changes that touch project-side surfaces ... verify Check 43 ... flag as a (d) finding with file:line + matched basename" guidance. Optionally also append the bullet to the "Pack rules to reference (for dimension d)" list at lines 173-203 area per §4.2 alternative placement.

**Verification commands:**

```bash
python3 scripts/validate-pack.py
# Verify all 4 trinity-equivalent files (PACK-AGENTS.md + pack-root trinity) carry the Check 43 verification content:
grep -l "Check 43" pack-ops/PACK-AGENTS.md CLAUDE.md AGENTS.md GEMINI.md pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md
# Expected: ALL 5 FILES MATCH.
# Verify pack-root trinity parity (Check 18 H2 + Check 16/19 parity for pack-root):
diff <(grep -A30 "Pack-coder PREFLIGHT" CLAUDE.md) <(grep -A30 "Pack-coder PREFLIGHT" AGENTS.md)
# Expected: only known platform-conditional ENFORCEMENT-mechanism divergences (Claude SendMessage / Codex /agent / Gemini Ctrl+C); the PREFLIGHT verification content itself should be byte-identical content in all three.
bash test-fixtures/build.sh --all --clean
git diff --stat test-fixtures/manifest.txt
```

**RC9 manifest regen:** REQUIRED (`pack-ops/` in v11-surface per BD-176 expansion). Pack-root trinity at the repo ROOT (`/CLAUDE.md`, `/AGENTS.md`, `/GEMINI.md`) is NOT in the 4-directory trigger set by directory listing — coder runs `bash test-fixtures/build.sh --all --clean` and inspects `git diff test-fixtures/manifest.txt`: if non-empty (pack-root trinity is fixture-affecting in any way), stage `test-fixtures/manifest.txt`; if empty, skip manifest staging. The `pack-ops/` edits ALONE force manifest regen per BD-176.

**Per-commit reviewer:** REQUIRED INLINE — sliding-window scope per Decision 4 (α-sliding) 2026-05-22. Covers this commit's diff only (sliding window = H.15 alone; prior INLINE reviewer was H.14 covering H.14). Decision 4 (b) 2026-05-22 user-directed symmetric trinity coverage with H.4 — pack-root trinity edit warrants per-commit review by parity with project-template trinity edit. Boundary-sensitive surface for reviewer focus (per V2 §I + §H.15):
- **PREFLIGHT contract fidelity.** Verify the Check 43 verification step is correctly described — trigger surface (v11-surface 4 directories), failure-handling (report-instead-of-IMPL-REPORT), invocation timing (BEFORE the PREFLIGHT line emit).
- **Pack-root trinity parity.** Verify the PREFLIGHT extension lands byte-identically across CLAUDE.md / AGENTS.md / GEMINI.md (modulo existing platform-conditional ENFORCEMENT-mechanism divergence per CLAUDE-CODE-SPECIFIC ENFORCEMENT vs platform-neutral PREFLIGHT half).
- **Override 9 non-applicability for the PREFLIGHT content.** Per BD-182 §4.1 + §C.6 reasoning: PREFLIGHT verification content is platform-neutral (Python invocation `python3 scripts/validate-pack.py` is the same across CLIs). Override 9 carve-out applies only to per-CLI configuration paths (e.g., `.claude/settings.json` vs `.gemini/.env`); not to platform-neutral content.
- **CONCEPTUAL-REVIEW-METHODOLOGY.md dimension (d) addition correctness.** Verify the appended sentence preserves the existing dimension (d) framing and correctly references Check 43.

**Commit subject scope keyword:** (mixed — no keyword; pack-ops/ + pack-root trinity + maintenance-docs/IMPL-REPORT + test-fixtures/manifest; IMPL-REPORT is not on PM-only list per PACK-AGENTS.md L143-149).

**Commit message:** `feat: v11 — BD-173 Guardrail 4 — pack-coder PREFLIGHT extension (Check 43 verification step) (Batch 19c.15)`

**Pack-coder PREFLIGHT line shape:** `PREFLIGHT: 5/5 in-scope file edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.15.md`

**Ordering dependency:** MUST land AFTER H.14 (Check 43 exists for PREFLIGHT to invoke). Per GUARDRAILS-CONTRACT.md §5.1.

---

### H.16 — D-11 PM-chat omniscience principle landing (METHODOLOGY.md Part 1) + OT-UT-1 informational paragraph

**Scope:** Per V2 §D.6 + V2 §D.7. Two related METHODOLOGY.md Part 1 edits land in one commit:
1. NEW sub-section "PM chat omniscience obligation" in `## Part 1 — Tool Roles`.
2. OT-UT-1 informational paragraph in `### Claude Code CLI (agents)` sub-section (per V2 §D.7.3).

**Files modified:**
- `supporting-docs/METHODOLOGY.md` (2 edits in Part 1)

**Edit specification:**

1. **D-11 principle landing — NEW sub-section "PM chat omniscience obligation".** Per V2 §D.6.2 verbatim text (the full prose block; multi-paragraph principle text + two-exception block + closing default rule). Insert as a new H3 sub-section in `## Part 1 — Tool Roles` IMMEDIATELY AFTER the existing "Separation rule" sub-section at L98-102, BEFORE the existing `## Part 2` H2 boundary.
   - Anchor: insert blank line + `### PM chat omniscience obligation` heading + the V2 §D.6.2 text block + blank line, between the Separation rule sub-section close at L102 and the next H2 boundary.
   - Note: V2 §D.6.3 documents two exceptions (defense-in-depth duplication for high-blast-radius rules; cross-CLI parity ergonomics). The full exception text is part of V2 §D.6.2 prose; the §D.6.3 table is documentation-of-the-prose, not a separate insert.
2. **OT-UT-1 paragraph (per V2 §D.7.3) — NEW `>` callout paragraph in `### Claude Code CLI (agents)` sub-section.** Per V2 §D.7.3 verbatim. Insert immediately after the existing 4-bullet list at L80-83 (the Claude Code CLI capabilities list), BEFORE the next H3 `### Xcode Coding Agent` at L85.
   - Anchor: insert blank line + V2 §D.7.3 `>` callout block + blank line, between L83 (last bullet "Receives complete instructions...") and L85 (next H3 heading).
   - The paragraph names Claude Code Agent Teams + SendMessage + Codex `/agent` slash + Gemini `@agent` invocation per TOOL-NEUTRAL enumeration pattern (BD-182 §3.1 R3-R7); correct cross-CLI parity for shared documents.

**Verification commands:**

```bash
python3 scripts/validate-pack.py
# Verify the new sub-section + paragraph render as expected:
grep -nA2 "^### PM chat omniscience obligation\|Claude-only operating convention — Agent Teams" supporting-docs/METHODOLOGY.md
# Verify D-11 principle text contains NO pack-side memory entries (per V2 H.16 reviewer focus + salvageability B9):
grep -nE "pack memory|Tier 1\.5|MEMORY\.md" supporting-docs/METHODOLOGY.md | grep -v "^\s*<!--"
# Expected: no matches outside HTML comments.
bash test-fixtures/build.sh --all --clean
git diff --stat test-fixtures/manifest.txt
```

**RC9 manifest regen:** REQUIRED (`supporting-docs/` in v11-surface per BD-176).

**Per-commit reviewer:** REQUIRED INLINE — sliding-window scope per Decision 4 (α-sliding) 2026-05-22. Covers this commit's diff only (sliding window = H.16 alone; prior INLINE reviewer was H.15 covering H.15). Boundary-sensitive surface for reviewer focus (per V2 §I + §H.16):
- **D-11 principle wording cites only project-side surfaces.** Per V2 §H.16 reviewer rationale + salvageability B9: the principle text must NOT cite pack-side memory entries, `pack-ops/`, or `maintenance-docs/`. The principle stands on its own project-side merits.
- **OT-UT-1 paragraph cross-CLI enumeration.** Verify the paragraph names all three CLIs per BD-182 §4.1 TOOL-NEUTRAL enumeration pattern (shared-document audience benefits from cross-CLI contextualization).
- **§D.6.3 exception text presence.** Verify the principle text includes the two documented exceptions (defense-in-depth; cross-CLI parity ergonomics) — these are load-bearing for the §C.6 + §D.7 cascade decisions already landed in H.4 + H.16.
- **Forward-reference closure with H.5.** H.5 landed §D.2 placement rule referencing this principle; H.16's principle landing closes the forward-pointer. Verify by reading §D.2 (now landed) + new §D.6 (this commit) together — they read consistently.

**Commit subject scope keyword:** (mixed — no keyword; supporting-docs/ + maintenance-docs/IMPL-REPORT + test-fixtures/manifest).

**Commit message:** `feat: v11 — BD-173 METHODOLOGY.md Part 1 — PM chat omniscience principle + Claude Code Agent Teams operating note (Batch 19c.16)`

**Pack-coder PREFLIGHT line shape:** `PREFLIGHT: 2/2 in-scope file edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.16.md`

---

### H.17 — End-of-batch reviewer + BD-173 status flip (single-BD batch close commit shape)

**Scope:** Per V2 §H.17 + V2 §M.4 end-of-batch flow.

1. Run `pack-reviewer` (background spawn from Pack Chat) on full batch diff (HEAD at H.0 baseline `9a95bfa` → HEAD at end of H.16).
2. Pack Chat triages findings per `feedback_fix_all_review_findings` (default fix-all; user triages per finding before fix-coder spawns).
3. If findings exist: spawn fresh fix-coder (background) per Pack Chat protocol; coder applies fixes and emits PREFLIGHT line + IMPL-REPORT.
4. Per single-BD batch close commit shape (`pack-ops/PACK-CHAT.md` `## Behavioral rules` "Batch close commit shapes"): COMBINE the fix commit and the BD-173 status flip into ONE final commit.
5. If NO fix findings: ship the BD-173 status flip as a standalone `docs: v11 — flip BD-173 to Resolved` commit.

**Reviewer prompt construction notes** (for Pack Chat — not for the coder):
- Reviewer reads ARCHITECTURE-CLEANUP-BATCH-19C-V2.md as the design reference, NOT prior PACK-REVIEW-*.md reports (per `feedback_no_prior_reviews_to_reviewer`).
- Reviewer scope: full batch diff covers ~16 commits (H.1-H.16). Reviewer applies dimensions per `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` including the H.15-extended dimension (d) Pack rule adherence with Check 43 verification.
- Dimension (d) Pack rule adherence MUST verify Check 43 PASSES against the working tree post-H.14 (Guardrail 1 + leak sweep should produce a clean validate-pack run).
- Per `feedback_no_prior_reviews_to_reviewer`: reviewer prompt references V2 ARCHITECTURE doc only; no prior reviews.

**BD-173 status flip mechanics:** Per `pack-ops/BACKLOG.md` BD-173 entry, change `Status: Open` → `Status: Resolved`; fill the `Resolved:` line with date + batch close commit SHA + summary of work delivered.

Summary text suggestion: `Resolved: 2026-05-DD — Batch 19c. 17-item OT memory promotion + 36-leak boundary sweep (Categories A+B+C+D+E+F) + 4 guardrails (G1 Check 43 + G2 per-line fence + G3 scope expansion + G4 PREFLIGHT extension) + D-11 PM-chat omniscience principle landed in METHODOLOGY.md Part 1 + word-level cleanups per salvageability B1/B2/B3/B5/B9.` Pack Chat customizes per actual close-date + commit SHA.

**Verification commands** (run by Pack Chat / reviewer; per V2 §M.5):

```bash
# Final batch verification at HEAD after H.17 commits land:
python3 scripts/validate-pack.py
# Check 43 from H.14 is now active; all 36 leak-sweep leaks closed by H.9-H.11; Guardrails 2-4 active per H.13-H.15.

bash test-fixtures/build.sh --verify
# Manifest matches all per-commit regenerations.

bash scripts/tests/test-validate-pack-check-43.sh
# New test file from H.14.

bash scripts/tests/test-validate-pack-checks-36-37-38.sh
# Groups 6 + 7 from H.13 + H.12 active.

bash scripts/tests/test-validate-pack-check-42.sh
# Check 42 PASSES — new test file from H.14 is CI-wired per H.14 .github/workflows/validate-pack.yml edit.

# Verify BD-173 status:
grep -B1 -A3 "BD-173" pack-ops/BACKLOG.md | head -8
# Expected: Status: Resolved; Resolved: <date + SHA + summary>
```

**RC9 manifest regen:** Required IF the fix-commit modifies any v11-surface file (i.e., the fix touches `project-template/`, `scripts/`, `pack-ops/`, or `supporting-docs/`). Pack Chat verifies via `git diff test-fixtures/manifest.txt` after `bash test-fixtures/build.sh --all --clean`; if non-empty, stage the manifest in the H.17 commit.

If H.17 is standalone status flip (no fixes), the commit touches only `pack-ops/BACKLOG.md` — RC9 fires per BD-176 4-directory trigger (`pack-ops/` in v11-surface). Coder/Pack Chat runs `bash test-fixtures/build.sh --all --clean`; if manifest diff is empty (BACKLOG.md is not fixture-affecting), no staging needed; if non-empty, stage the manifest. (The directory-wide trigger is defensive — false positives produce no incorrect manifest change per BD-176 rationale.)

**Per-commit reviewer:** END-OF-BATCH (this IS the end-of-batch reviewer pass). No further inline review attaches to H.17 — the reviewer pass at H.17 IS the inline review of the H.17 fix-commit (single review covers fix + the batch cumulative state).

**Commit subject scope keyword (commit-shape-dependent):**
- **If combined fix + status flip:** mixed scope likely (fixes may touch `project-template/` + `supporting-docs/` + `scripts/` + `pack-ops/`); use no keyword. Pack Chat verifies actual files touched. Note: no scope keyword if IMPL-REPORT included (IMPL-REPORTs live under `maintenance-docs/` which is not on PM-only list per PACK-AGENTS.md L143-149).
- **If standalone status flip on `pack-ops/BACKLOG.md` only:** `PM-only` (BACKLOG.md is PM-only).

**Commit message (commit-shape-dependent):**
- **If combined fix + status flip:** `fix: v11 — BD-173 broad batch review/fix + status flip (Batch 19c)`
- **If standalone status flip:** `docs: v11 — flip BD-173 to Resolved`

**Pack-coder PREFLIGHT line shape (if fix-coder spawns):** `PREFLIGHT: <N>/<N> in-scope file edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.17-FIX.md`

(If H.17 is standalone status flip with no fix-coder spawn, Pack Chat applies the BACKLOG edit directly per PM-only files rule — no PREFLIGHT line required.)

**Ordering dependency:** RUN AFTER H.16. This IS the batch close. No subsequent commits in Batch 19c.


---

## §4 — Per-commit summary table (planner lookup)

| Commit | Scope summary | Files | RC9 fires? | Per-commit reviewer | Scope keyword | Commit msg |
|---|---|---|---|---|---|---|
| H.0 | Baseline verification (no commit) | n/a | n/a | n/a | n/a | (none) |
| H.1 | METHODOLOGY workflow callouts (§C.1 + §C.2 + §D.3 + §C.10 half) | METHODOLOGY.md | YES | covered by H.4 | (mixed) | `feat: v11 — BD-173 METHODOLOGY.md workflow clarifications (Batch 19c.1)` |
| H.2 | PM-CHAT.md behavioral rules consolidation (§C.1+§C.4+§C.7+§C.8+§C.9+§C.10+§C.11+§C.13 + §D.5 cross-ref) | PM-CHAT.md + METHODOLOGY.md | YES | covered by H.4 | (mixed) | `feat: v11 — BD-173 PM-CHAT.md behavioral rules consolidation (Batch 19c.2)` |
| H.3 | PM-CHAT.md source-edit discipline (§C.5 STRENGTHEN + §C.6 PM-CHAT.md half) | PM-CHAT.md | YES | covered by H.4 | (mixed) | `feat: v11 — BD-173 PM-CHAT.md source-edit discipline (Batch 19c.3)` |
| H.4 | Trinity destructive-ops list extension (§C.6 trinity half) | CLAUDE.md + AGENTS.md + GEMINI.md (project-template) | YES | **INLINE (sliding from H.1)** | (mixed) | `feat: v11 — BD-173 trinity destructive-ops list extension (Batch 19c.4)` |
| H.5 | METHODOLOGY substantive additions (§D.4 + §D.2 + §C.12) | METHODOLOGY.md | YES | **INLINE (this commit only)** | (mixed) | `feat: v11 — BD-173 METHODOLOGY.md substantive additions (mid-phase planner, rule placement subsidiary to PM-chat omniscience, /tmp ephemerality) (Batch 19c.5)` |
| H.6 | METHODOLOGY Procedure 1 BACKLOG-surface STRENGTHEN (§C.3) | METHODOLOGY.md | YES | covered by H.9 | (mixed) | `feat: v11 — BD-173 METHODOLOGY.md proactive BACKLOG surfacing (Batch 19c.6)` |
| H.7 | PM-CHAT per-project memory cache (§D.1 REVISED) | PM-CHAT.md | YES | covered by H.9 | (mixed) | `feat: v11 — BD-173 PM-CHAT.md per-project Claude memory cache convention (Batch 19c.7)` |
| H.8 | (REMOVED — V1's H.8 → V2's H.17) | n/a | n/a | n/a | n/a | (none) |
| H.9 | Leak sweep Cat A+B per-entry skeletons (30 leaks, 7 files) | 7 per-entry skeleton files | YES | **INLINE (sliding from H.6)** | (mixed) | `feat: v11 — BD-173 leak sweep Categories A + B — per-entry skeleton boundary cleanup (Batch 19c.9)` |
| H.10 | Leak sweep Cat D+E+F (detect.sh + pm-startup cluster + boundary-investigation cite; 8 leaks across 7 files) | detect.sh + PM-CHAT.md + pm-startup ×4 + boundary-investigation/SKILL.md | YES | **INLINE (this commit only)** | mixed (none) | `feat: v11 — BD-173 leak sweep Categories D + E + F — mechanical cite cleanup + BD-175 self-leak fix (Batch 19c.10)` |
| H.11 | Leak sweep Cat C pm-chat variants rewrite (3 leaks, C-c direction) | prompts/pm-chat.md | YES | **INLINE (this commit only)** | (mixed) | `feat: v11 — BD-173 leak sweep Category C — pm-chat variant rewrites to client-side equivalents (Batch 19c.11)` |
| H.12 | Guardrail 3 `_PROJECT_SIDE_ROOTS` scope expansion + Group 7 tests | validate-pack.py + scripts/tests/test-validate-pack-checks-36-37-38.sh | YES | covered by H.13 | `pack-only` | `feat: v11 — BD-173 Guardrail 3 — _PROJECT_SIDE_ROOTS expansion to full client-installed surface (Batch 19c.12)` |
| H.13 | Guardrail 2 per-line fence + Group 6 tests + 7 fenced files | validate-pack.py + 7 fenced files + scripts/tests/ | YES | **INLINE (sliding from H.12)** | mixed (none) | `feat: v11 — BD-173 Guardrail 2 — per-line deny-list fence (Check 37 modification + 7 files fenced) (Batch 19c.13)` |
| H.14 | Guardrail 1 Check 43 new check + 13 fixtures + CI wire | validate-pack.py + test-validate-pack-check-43.sh + fixtures/project-side-refs/ + validate-pack.yml | YES | **INLINE (this commit only)** | mixed (none) | `feat: v11 — BD-173 Guardrail 1 — Check 43 (project-side bare cross-reference scanner; V11 leak-sweep prevention) (Batch 19c.14)` |
| H.15 | Guardrail 4 PREFLIGHT extension (pack-side PM-only) | PACK-AGENTS.md + pack-root trinity ×3 + CONCEPTUAL-REVIEW-METHODOLOGY.md | YES | **INLINE (this commit only)** | (mixed) | `feat: v11 — BD-173 Guardrail 4 — pack-coder PREFLIGHT extension (Check 43 verification step) (Batch 19c.15)` |
| H.16 | D-11 omniscience principle + OT-UT-1 paragraph (Part 1 landing) | METHODOLOGY.md | YES | **INLINE (this commit only)** | (mixed) | `feat: v11 — BD-173 METHODOLOGY.md Part 1 — PM chat omniscience principle + Claude Code Agent Teams operating note (Batch 19c.16)` |
| H.17 | End-of-batch reviewer + BD-173 status flip (combined fix+flip OR standalone flip) | (varies) | conditional | END-OF-BATCH | mixed or `PM-only` | `fix: v11 — BD-173 broad batch review/fix + status flip (Batch 19c)` OR `docs: v11 — flip BD-173 to Resolved` |

**Total commits:** 16 implementation (H.1-H.16) + 1 close (H.17) = **17 commits**.

**Per-commit reviewer breakdown:** 9 INLINE sliding-window passes (H.4 covers H.1-H.4; H.5 covers H.5; H.9 covers H.6+H.7+H.9; H.10 covers H.10; H.11 covers H.11; H.13 covers H.12+H.13; H.14 covers H.14; H.15 covers H.15; H.16 covers H.16) / 6 SKIP-per-commit but covered by sliding window (H.1, H.2, H.3 covered by H.4; H.6, H.7 covered by H.9; H.12 covered by H.13) / 1 END-OF-BATCH (H.17 backstop over full batch diff). Matches V2 §I summary exactly; every implementation commit is reviewed at least once before H.17.

**RC9 manifest regen attachment:** ALL 16 implementation commits fire RC9 per the BD-176 4-directory trigger; H.17 RC9 is conditional on fix-commit content. Every commit's verification step includes `bash test-fixtures/build.sh --all --clean` + manifest-staging.

---

## §5 — Planner observations for Pack Chat triage

These are tensions or open questions surfaced during planning. Per the planner-output → user review gate (`feedback_planner_user_review_before_coder`), the user reads these BEFORE Pack Chat spawns the first pack-coder. None auto-resolved; Pack Chat surfaces to user for direction before H.1.

### Observation 1 — H.5 forward-reference to H.16 principle

V2 §H.16 Ordering rationale documents this trade-off: H.5 lands the §D.2 placement rule that subordinates to the D-11 omniscience principle, but the principle text itself lands later in H.16. H.5's prose contains a forward reference to "Part 1 — PM chat omniscience obligation" that does not yet exist at H.5's commit head.

**Trade-off documented in V2:**
- Alternative order (land H.16 principle FIRST, then H.5 subsidiary) creates tidier forward-reference shape but splits METHODOLOGY.md Part 1 + Part 9 edits across the batch, weakening cascade reasoning.
- V2's chosen order preserves per-commit content cohesion (H.5 = procedural; H.16 = principle).

**Status:** V2 explicitly chose this trade-off. **Surfacing for user awareness, NOT a request to re-litigate.** If user wants to flip H.5/H.16 ordering, planner would re-plan; but V2's choice stands by default.

### Observation 2 — Group 6/7 fixture-test numbering inversion

GUARDRAILS-CONTRACT.md §3.4 places "Group 7" for Guardrail 3 tests; §2.6 places "Group 6" for Guardrail 2 tests. H.12 lands Guardrail 3 BEFORE H.13 lands Guardrail 2 (per the dependency chain — Guardrail 2 fence requires the leak sweep to have cleared the boundary-investigation skill's L124 cite; Guardrail 3 scope expansion is foundational for Guardrails 1+2). Result: Group 7 lands first (in H.12), Group 6 lands second (in H.13), final test file has groups in order Group 5 → Group 7 → Group 6, which is unusual.

**Two resolution paths:**
- **(a) Preserve V2's commit-ordering H.12 then H.13:** test file gets out-of-numeric-order group sequence. Cosmetically suboptimal but matches the dependency chain.
- **(b) Renumber: rename "Group 6" → "Group 6" (Guardrail 3, lands in H.12), "Group 7" → "Group 7" (Guardrail 2, lands in H.13).** This swaps the contract doc's group numbering to match commit order. Requires editing GUARDRAILS-CONTRACT.md §2.6 + §3.4 group labels (architect-doc change). Cleaner numeric sequence in the test file.

**Status:** Planner default is (a) — preserve V2's commit ordering AS-WRITTEN, accept cosmetic out-of-order group sequence. The numbering choice is internal to the test file and doesn't affect functional coverage. **Surfacing for user direction:** keep (a), or switch to (b) which requires architect-doc fix-up?

### Observation 3 — V2 §C.10 METHODOLOGY half placement vs Workflow 4 step 4 anchor

V2 §C.10 BEFORE/AFTER for the METHODOLOGY half cites "STRENGTHEN existing step 4 text (V1 cited L522-523)" and gives the AFTER text. The current Workflow 4 fenced block at L435-449 has step 4 INSIDE the fenced code block at L441 ("If NO trigger: PM chat presents fix plan → developer approves → coder fix pass → reviewer (step 1)"). The V2 §C.10 AFTER text reads as English prose, not as fenced-block-step pseudocode.

Two interpretations:
- **(a) Strengthen step 4 INSIDE the fenced block.** Replace L441 fenced step 4 line with the V2 §C.10 AFTER prose, breaking the fenced-block code style. Awkward fit.
- **(b) Land V2 §C.10 AFTER text as a NEW `>` callout block AFTER the fenced block closes at L449.** The callout adds the "PM chat presents and waits for user to read" guidance as a sibling to the existing "The PM chat does not execute fix passes directly." callout at L451-453. Cleaner fit.

**Status:** Planner default is **(b) — land V2 §C.10 AFTER as a new callout block after the fenced Workflow 4 block** (paralleling the existing callout pattern at L451-453). V2's "STRENGTHEN" framing is preserved (the rule is reinforced relative to the workflow); only the rendering shape is a callout vs in-fence prose. **Surfacing for user direction:** confirm (b), or apply V2's literal "STRENGTHEN step 4" reading (a)?

### Observation 4 — H.13 PM-CHAT.md fence placement when no enumeration content exists

GUARDRAILS-CONTRACT.md §2.3 includes `project-template/docs/pack/PM-CHAT.md` in `_CHECK_37_PER_LINE_FENCE_FILES`. §2.5 invariant: "At least one START + END pair per fence-allowlisted file at HEAD." But PM-CHAT.md does not have an obvious deny-list-enumeration block at HEAD (the legitimate Pack Chat references are anchor-phrase-legitimate per audit §1.2, not deny-list-enumeration).

Two paths per H.13 spec item 9:
- **(a) Empty fence pair** placed at a defensible location (e.g., near Part 10 PACK-FEEDBACK reference). Satisfies §2.5 invariant; coder picks defensible insertion.
- **(b) Re-scope PM-CHAT.md OFF `_CHECK_37_PER_LINE_FENCE_FILES`.** Edits GUARDRAILS-CONTRACT.md §2.3 (architect-doc change) to remove PM-CHAT.md from the per-line-fence allowlist. PM-CHAT.md stays whole-file-exempt OR loses exemption (and the Pack Chat anchor-phrase patterns continue handling via anchor-phrase mechanism per V2 §B.3 / contract §2.3 note).

**Status:** Planner default is (a) — empty fence pair. V2 explicitly includes PM-CHAT.md in the contract's fence-allowlist set; honor that. **Surfacing for user direction:** confirm (a), or re-scope per (b)?

### Observation 5 — H.7 V2 placement of per-project Claude memory cache vs V2 §B.1's stated "REVISED-WORDING" verdict on Arch derived 2

V2 §B.1 row "Arch derived 2 (per-project Claude memory cache convention)" lists V1 disposition as "PM-CHAT.md NEW paragraph (CONDITIONAL per V1 D-1)" and V2 verdict as "REVISED-WORDING — LAND per V1 D-1 = Alt-1 reframed in §D.7." V2 §H.7 lands the paragraph per §D.1 (architecture-decision §D.1 carries the verbatim V2 prose; H.7 commit lands it). V2 §H.7 also has a "Note on V1's CONDITIONAL H.7" stating V1's H.7 was the conditional Claude-only sub-section dropped per V2 §D.7; V2's H.7 is REPURPOSED to land §D.1.

Cross-walk check: §B.1 + §D.1 + §H.7 are internally consistent. The "Arch derived 2" row's "CONDITIONAL per V1 D-1" reads as if the §D.1 paragraph was conditional, but per V2 §F D-1 resolution (LAND with §D.7 disposition + OT-UT-1 in METHODOLOGY paragraph; §D.1 ALWAYS LANDS as part of V1 D.1 = Alt-1 architect recommendation; user confirmed). No conditionality at V2.

**Status:** internally consistent at V2. **No user direction needed**; planner notes for cross-walk completeness.

### Observation 6 — BD-179 closure prerequisite per V2 §H.0

V2 §H.0 caveat: "Planner / coder MUST coordinate with BD-179 status before commit 1 — if BD-179 has not closed (status flip to Resolved + manifest-clean), Batch 19c commits cannot land cleanly." V2 was authored at HEAD `7b1be5fc` (post-BD-179 Phase 1). Plan HEAD is `9a95bfa`, which has commits `70edb97` (Batch 19d phase parts + ordering BD-185 open), `7b1be5f` (parking-lot for v11.1 GitHub Projects), `9da98a4` (BD-175 batch archive). BD-179 status at HEAD `9a95bfa`: check via `grep -A3 "^\*\*BD-179" pack-ops/BACKLOG.md`. If BD-179 still Open with in-flight work, Batch 19c restart blocked per V2 §H.0.

**Status:** This is a sequencing prerequisite that **Pack Chat must verify before H.1 begins**, not a planning decision. Planner cannot resolve from the read-only state. **Surfacing for user direction:** confirm BD-179 closure (or accept the risk of BD-179 in-flight contamination of the H.1 baseline).

### Observation 7 — V2's H.0 working-tree baseline note

V2 §H.0 notes: "Working-tree baseline: Per `git status` at architect-pass start: 7 modified files in `pack-ops/` + `scripts/` (BD-179 in-flight) + 2 new files in `maintenance-docs/v11-implementation/`."

At plan time HEAD `9a95bfa`, `git status` shows new untracked files (6 maintenance-docs/v11-implementation/ + v11-research/ files from V2 architect-pass artifacts). These are V2 architect-pass work products that landed in commit `9a95bfa` (per problem statement: "Architect-pass work products committed at HEAD 9a95bfa").

**Status:** untracked maintenance-docs/ files at plan time are V2-architect-output products NOT YET committed (planner output is one of them — the PLAN-CLEANUP-BATCH-19C.md file this plan writes); Pack Chat may commit these as PM-only / pack-only maintenance-docs commits separately from the H.1-H.17 sequence per pack-internal-docs commit-shape conventions. Not a blocker for H.1.

### Observation 8 — Cross-cutting cite to maintenance-docs/v11-implementation/ARCHITECTURE-V11-LEAK-SWEEP-STRATEGY.md in CONCEPTUAL-REVIEW-METHODOLOGY.md (§4.2)

GUARDRAILS-CONTRACT.md §4.2 suggests the dimension (d) extension text in `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` should cite `maintenance-docs/v11-implementation/ARCHITECTURE-V11-LEAK-SWEEP-STRATEGY.md §4.1` as the boundary-leak-class authority. CONCEPTUAL-REVIEW-METHODOLOGY.md lives at `pack-ops/` (pack-internal — never client-installed). Citing `maintenance-docs/` from a pack-only file IS LEGITIMATE (no boundary leak risk; the doc is pack-internal context).

**Status:** No boundary-leak concern. Confirming for cross-walk completeness that this in-content cite is legitimate per the boundary rules. Pack-internal → pack-internal cite is allowed.

### Observation 9 — H.13 trinity fence-marker placement under `## Project memory` "Project SSOT-first" bullet

GUARDRAILS-CONTRACT.md §2.4 says fence the deny-list parenthetical inside the "Project SSOT-first" bullet (currently at CLAUDE.md ~L381-410). Inserting HTML-comment fence markers INSIDE a multi-line bullet body is unusual — markdown renderers may or may not preserve them cleanly inside list-item prose. The HTML-comment form `<!-- ... -->` is invisible in rendered markdown (per §2.1 design rationale), but bullet-item formatting may interact with the comment placement.

**Status:** Planner default is to apply the fence markers AS LITERAL LINES on their own (not embedded inline within the bullet's running prose). Each marker is on its own line per §2.5 invariant ("Each marker MUST be on its own line"). Within a bullet, this creates: bullet-opener → ... → marker line → enumeration content → marker line → ... → bullet body continues. Markdown renderers handle this acceptably (HTML comments inside bullets are common). **Surfacing for user awareness; no user direction needed unless rendering issues surface during H.13 review.**

---

## §6 — Final verification per V2 §M.5

After H.17 lands successfully:

```bash
python3 scripts/validate-pack.py
# Expected exit code: 0 (Check 43 from H.14 active; 36 leak-sweep leaks closed by H.9-H.11; Guardrails 2-4 active per H.13-H.15).

bash test-fixtures/build.sh --verify
# Expected: manifest matches all per-commit regenerations.

bash scripts/tests/test-validate-pack-check-43.sh
# Expected exit code: 0 (new test file from H.14).

bash scripts/tests/test-validate-pack-checks-36-37-38.sh
# Expected exit code: 0 (Groups 6 + 7 from H.13 + H.12 active).

bash scripts/tests/test-validate-pack-check-42.sh
# Expected exit code: 0 (Check 42 PASSES — new test file from H.14 is CI-wired per H.14 workflow edit).

# BD-173 status:
grep -A3 "^\*\*BD-173" pack-ops/BACKLOG.md
# Expected: Status: Resolved; Resolved: <date + close commit SHA + summary>.

# CI run (manual trigger or auto on push):
gh run list --workflow validate-pack.yml --limit 1
# Expected: latest run conclusion = success.
```

`pack-ops/CHANGELOG.md` may receive a Batch 19c summary entry at the version-boundary close per Pack Chat protocol; not necessarily in H.17 itself.

---

## §7 — Risks carried from V2 §K (not re-litigated)

V2 §K.1-K.9 enumerate the risk surface (K.1-K.6 carried from V1, K.7-K.9 introduced by V2 integration; all user-accepted per the 2026-05-22 triage). Planner does not re-litigate. Reference: V2 §K.1-K.9.

---

*End of PLAN-CLEANUP-BATCH-19C.*

