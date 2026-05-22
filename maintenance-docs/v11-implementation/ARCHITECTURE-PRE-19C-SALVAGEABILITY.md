# ARCHITECTURE-PRE-19C-SALVAGEABILITY — V1 viability under post-BD-175 boundary

**Author:** pack-architect (read-only salvageability pass; not a redesign)
**Date:** 2026-05-21
**Branch:** `v11-dev` (HEAD `9da98a4`)
**Scope:** Element-by-element verdict on `ARCHITECTURE-CLEANUP-BATCH-19C.md` V1 (2026-05-17) plus its mid-V1 PRINCIPLE-CHECK sidecar and the G-1..G-9 research output. Test: does each element still respect the boundary discipline that BD-175 + BD-176..BD-184 hardened between 2026-05-18 and 2026-05-21?
**Authorities consulted:** `pack-ops/BOUNDARY-DEFINITION.md`, `pack-ops/PACK-AGENTS.md`, `pack-ops/PACK-CHAT.md`, `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`, `project-template/docs/pack/PM-CHAT.md`, `project-template/CLAUDE.md` `## Project memory`, pack-root `CLAUDE.md` `## Pack memory`, `.claude/skills/boundary-investigation/SKILL.md`, `maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md`, `maintenance-docs/v11-implementation/ARCHITECTURE-BD-176.md`, `maintenance-docs/v11-implementation/ARCHITECTURE-BD-182.md`.

**Output mandate (per prompt):** assess + verdicts only. No replacement designs. The user decides next pipeline step from this report.

PREFLIGHT: 12 §C placements + 5 §D decisions + 11 §F open questions + 9 §G research items + 8 §H commits assessed; 9 boundary risks identified; HEAD 9da98a44d9b7c2236f8dacd8632bca6e9b662963.

---

## §1 — What the post-BD-175 boundary changed (synthesis from authorities)

V1 was authored on 2026-05-17 against a pack/project boundary that had not yet been formally defined. BD-175 (2026-05-18) and its emergency-batch follow-ons BD-176..BD-184 (2026-05-18..2026-05-21) introduced the following load-bearing changes that any V1 element must now respect:

1. **Two-axis classification matrix (C1–C6).** `pack-ops/BOUNDARY-DEFINITION.md` §2 makes every file's audience+function classification deterministic. Mis-audience references (a PROJECT-audience file pointing at a PACK-only file or vice versa) are anti-patterns by construction (§7.7 worked example: the V1 anti-pattern where project trinity acquired a `PACK-AGENTS.md` reference).

2. **Pack-only directory `pack-ops/`.** PACK-CHAT.md, PACK-AGENTS.md, HELP-FRAGMENT-PACK.md, HELP-FRAGMENT-TRACKER.md, OPTIONAL-FEATURES.md, BACKLOG.md, CHANGELOG.md, BOUNDARY-DEFINITION.md, MERGE-STRATEGY.md, DRY-RUN-MIGRATION.md, CONCEPTUAL-REVIEW-METHODOLOGY.md all relocated from pack root to `pack-ops/`. None of these appear at a client install (no installer stage in `scripts/init-project.sh`).

3. **Project-side SSOT discipline (P-missed-7).** Pack-root `CLAUDE.md` `## Pack memory` codified P-missed-7: "project-side investigation precedes pack-style defaults." Project trinity (`project-template/CLAUDE.md/AGENTS.md/GEMINI.md`) and the project-side trinity `## Project memory` section both acquired SSOT-first wording. The project-side authoritative SSOT for the agent roster is `project-template/docs/pack/PM-CHAT.md` § "Pack agent roster" — NOT `PACK-AGENTS.md` (which is pack-internal and not present at client install).

4. **`boundary-investigation` skill is mandatory.** `.claude/skills/boundary-investigation/SKILL.md` is loaded by all pack agents (per `pack-ops/PACK-AGENTS.md` skill-load table). It contains an explicit deny-list (Step 4) of pack-only paths and file names that project-side files MUST NOT reference. Bare-filename refs to `PACK-AGENTS.md`, `PACK-CHAT.md`, `HELP-FRAGMENT-PACK.md`, `HELP-FRAGMENT-TRACKER.md`, `OPTIONAL-FEATURES.md` from project-side files are all denied. Path prefixes `maintenance-docs/`, `pack-ops/`, `scripts/`, `test-fixtures/` from project-side files are all denied.

5. **Cross-CLI reference normalization (BD-182 §4.1 canonical table).** Override 9 codified: "different audience = different wording; NO cross-trinity drift gate." Tool-specific references in trinity must use the audience-correct per-CLI canonical value, NOT byte-identical adoption from CLAUDE.md. Per-CLI settings paths: `.claude/settings.json` (Claude), `.codex/config.toml` (Codex), `.gemini/.env` + `.gemini/settings.json` (Gemini).

6. **Trinity is intentionally asymmetric across surfaces.** Pack-root trinity and project-template trinity carry DIFFERENT content by design. Both internally enforce within-trinity parity (Checks 16, 18, 19 — extended to pack-root by BD-181 + BD-183). Override 9 explicitly disallows a cross-trinity parity gate.

7. **`pack-ops/PACK-AGENTS.md` and `pack-ops/PACK-CHAT.md` are PACK-only SSOTs.** They are not installed to clients. They cannot be cited from any project-side file. The project-side orchestration SSOT is `project-template/docs/pack/PM-CHAT.md`.

8. **RC9 manifest-regen rule expanded to 4 directories (BD-176).** `v11-surface = files under project-template/, scripts/, pack-ops/, or supporting-docs/`. Any commit touching any of these directories must regenerate `test-fixtures/manifest.txt` in the same commit.

9. **New CI checks (BD-179, BD-180, BD-181, BD-182, BD-183, BD-184).** Check 40 (pack-ops/ bare cross-ref scanner), Check 39 expansion (cmd_update reverse direction → Check 41), Check 18 H2 extended to pack-root, Check 16/19 extended to pack-root, Check 42 (CI workflow wires all per-check tests). These are mechanical guards that any V1-derived change must satisfy.

10. **Project trinity `## Project memory` "Project SSOT-first" bullet.** The project trinity itself now carries explicit anti-pack-import wording (project-template/CLAUDE.md L385-401 visible at HEAD): "Files at the pack repo (PACK-AGENTS.md, PACK-CHAT.md, pack-* agent prompts, pack-repo `maintenance-docs/`, pack-repo `pack-ops/` — any file under `pack-ops/`, including BOUNDARY-DEFINITION.md, BACKLOG.md, CHANGELOG.md, etc.) are NOT part of the project SSOT and must not be referenced from project files — the pack repo is not present at this client install."

The V1 author did not have authorities 1–10 to work against; the V0 architect doc had also been discarded. The salvageability question is per-element: does V1 propose changes that any of these post-BD-175 authorities would now reject?

---

## §2 — Element-by-element verdicts (§C placements)

For each §C placement, the verdict format: **VERDICT (keep / minor revision / major revision / discard)** with rationale citing the specific BD-175..BD-184 change and authority that drives the verdict.

### §C.1 — OT-T-1 always-reviewer-after-coder

- **V1 targets:** (a) `project-template/docs/pack/PM-CHAT.md` `## Behavioral rules` NEW bullet; (b) `supporting-docs/METHODOLOGY.md` Part 5 Workflow 2 NEW callout.
- **VERDICT: keep (minor revision for SSOT wording).** Both targets are project-side (C5 project × operations and C4 project × product respectively). PM-CHAT.md is the post-BD-175-confirmed project-side orchestration SSOT for PM-chat behavior. METHODOLOGY.md is installed to clients via `scripts/init-project.sh:565-570` — also project-side. No boundary risk in the placement.
- **Minor revision:** if the new PM-CHAT.md bullet text needs to cite an authority for the cycle rule, it MUST cite project-side sources only (`METHODOLOGY.md` Workflow 2, the project agent files at `.claude/agents/`, the project trinity `## Project memory`). It MUST NOT cite pack-side `feedback_review_fix_one_cycle` / `pack-ops/PACK-AGENTS.md` / pack-root trinity. V1's proposed text (lines 686-698) does not cite any pack-side reference, so it is clean as written.
- **RC9 implication:** PM-CHAT.md is under `project-template/` so RC9 fires; METHODOLOGY.md is under `supporting-docs/` and per BD-176's expanded trigger ALSO fires now (was not in V1's scope analysis). Any commit landing this placement must regenerate `test-fixtures/manifest.txt`.

### §C.2 — OT-T-2 architect-trigger surface-even-mechanical

- **V1 target:** `supporting-docs/METHODOLOGY.md` Part 5 Workflow 4 STRENGTHEN.
- **VERDICT: keep.** METHODOLOGY.md is project-side, installed to clients. The proposed text (V1 lines 740-749) names the architect-trigger surface-even-mechanical extension without any pack-side reference. G-3 research (lines 178-218) verified the rule is genuinely absent from pack source — categorization stands.
- **No boundary risk.** No pack-side citations; no pack-only path; no cross-CLI reference. RC9 fires (supporting-docs/ trigger per BD-176).

### §C.3 — OT-T-3 BACKLOG-between-phases proactive surfacing

- **V1 target:** `supporting-docs/METHODOLOGY.md` Part 7 Procedure 1 step 2 STRENGTHEN (CONDITIONAL per §F D-3).
- **VERDICT: keep.** Project-side surface; no pack-side citations; pure procedural-strengthen. The proposed text (V1 lines 770-773) is project-internal. RC9 fires (supporting-docs/).

### §C.4 — OT-T-4 closeout-sequence (present-before-write)

- **V1 target:** `project-template/docs/pack/PM-CHAT.md` `## Behavioral rules` NEW bullet.
- **VERDICT: keep (minor revision needed to verify against current PM-CHAT.md state).** PM-CHAT.md is the project-side orchestration SSOT. The proposed text (V1 lines 786-797) is PM-chat-orchestration, no pack-side citations. G-6 verified the rule is genuinely absent from pack source.
- **Minor revision:** PM-CHAT.md has been edited by BD-178 and BD-182 since V1 was authored. The "Source file edits" bullet that V1 references at line 203-205 is still at that location (verified at HEAD); the insertion anchor still resolves. Verify before commit.

### §C.5 — OT-T-5 no-chained-git-add

- **V1 target:** `project-template/docs/pack/PM-CHAT.md` `## Behavioral rules` STRENGTHEN to existing "Source file edits" bullet.
- **VERDICT: keep.** Project-side surface, PM-chat-orchestration content. No pack-side reference, no pack-only path. Proposed text (V1 lines 820-830) is self-contained. Insertion anchor still resolves at HEAD.

### §C.6 — OT-T-6 PM-chat-never-edits-source

- **V1 targets:** (a) `project-template/docs/pack/PM-CHAT.md` `## Behavioral rules` NEW bullet; (b) `project-template/{CLAUDE,AGENTS,GEMINI}.md` `## Project memory` STRENGTHEN of "No destructive operations" bullet.
- **VERDICT: keep (CHECK BD-178 + CHECK BD-182 alignment first).** Both targets are project-side. The PM-CHAT.md bullet is pure PM-chat-orchestration. The trinity STRENGTHEN extends the destructive-ops named list with `git checkout --` — a project-team rule that applies symmetrically across CLAUDE/AGENTS/GEMINI per the project trinity rule.
- **Two checks required before commit:**
  1. **BD-178 baseline check.** BD-178 already aligned the trinity "No destructive operations" bullet to the canonical CLAUDE.md form (`fa605a9` commit chain). V1's "BEFORE text" (V1 lines 874-881) reflects pre-BD-178 state. The current HEAD bullet at `project-template/CLAUDE.md` L381-384 is the BD-178-canonicalized form. The V1 STRENGTHEN edit must apply to the BD-178 form, not the V1-recorded form.
  2. **BD-182 cross-CLI reference check.** The destructive-ops bullet does not contain CLI-specific paths or commands, so BD-182 §4.1 canonical table does not require divergence here. The trinity rule (same change to all three) applies cleanly. Trinity asymmetry is NOT introduced by this STRENGTHEN.
- **No boundary risk in placement.** Both files are project-side. The STRENGTHEN does not introduce a pack-side citation.

### §C.7 — OT-T-7 re-read per-agent prompt file every time

- **V1 target:** `project-template/docs/pack/PM-CHAT.md` `## Behavioral rules` NEW bullet.
- **VERDICT: keep.** PM-CHAT.md is the project-side PM-chat orchestration SSOT. G-5 verified the rule is genuinely absent. Proposed text (V1 lines 911-928) references `docs/pack/prompts/<agent>.md` (a project-side path) and "REPORT FILE line" (a project-side convention codified in PM-CHAT.md `## Permission profiles`). No pack-side reference.

### §C.8 — OT-UT-2 pack-repo-is-read-only

- **V1 target:** `project-template/docs/pack/PM-CHAT.md` `## Behavioral rules` NEW bullet.
- **VERDICT: keep (MINOR REVISION — the bullet must avoid the boundary-bias trap).** This is the highest-boundary-attention element of §C because its content is ABOUT the pack repo from the project side.
- **Why it survives:** The intent is to tell the PROJECT-side PM chat "do not modify the pack clone from this project." That is a legitimate project-side rule. The PROJECT-AUDIENCE file (PM-CHAT.md) names the PACK as a read-only entity — that is talking ABOUT the pack, not citing IT as a SSOT.
- **Minor revision needed:** V1's proposed text (lines 941-953) cites `PACK-FEEDBACK.md` correctly (project-side, installed). It cites `METHODOLOGY.md Part 10` correctly (project-side, installed). It does NOT cite pack-side paths like `PACK-AGENTS.md`, `pack-ops/`, or `maintenance-docs/`. Per the `boundary-investigation` skill Step 4 deny-list, naming the pack repo at all from a project-side file is permitted ONLY when discussing it as an external entity (not citing it as a SSOT). The V1 text does the former cleanly.
- **One nit:** the bullet text says "If a clone of the AI Agent Config Pack lives on this machine for reference (e.g., to read METHODOLOGY.md, prompts/, supporting-docs/ as upstream source)" — the phrase "supporting-docs/" is a pack-repo path. Per the deny-list, this phrase in a project-side file is a borderline case. The cleaner form would be to drop the "supporting-docs/" example and reference only project-side installed paths (`docs/pack/METHODOLOGY.md`, `docs/pack/prompts/`). Coder/architect should apply this nit when landing.

### §C.9 — OT-UT-3 mid-pipeline working-tree state intentional

- **V1 target:** `project-template/docs/pack/PM-CHAT.md` `## Behavioral rules` NEW bullet.
- **VERDICT: keep.** Project-side PM-chat-orchestration content. No pack-side citations. The proposed text (V1 lines 967-979) is self-contained.

### §C.10 — OT-UT-6 architect-output → user-reads → next-step-waits

- **V1 targets:** (a) PM-CHAT.md `## Behavioral rules` NEW bullet; (b) METHODOLOGY.md Workflow 4 step 4 STRENGTHEN.
- **VERDICT: keep.** Both project-side. No pack-side citations. The V1-proposed wording (lines 994-1007 + 1025-1032) cites pack-side memory `feedback-planner-user-review-before-coder` as a PRECEDENT in the rationale text. Per `boundary-investigation` Step 4, citing pack-side memory entries as PRECEDENT in project-side prose is NOT in the deny-list, but it is an audience-mismatch smell — a project-side reader does not have access to the pack-side memory file. Cleaner: drop the cross-side citation; assert the rule on its own.
- **Minor revision:** rewrite the "This is the project-side analog of the pack-side..." clause to remove the cross-side citation. The rule stands on its own merits without anchoring to a pack-side mechanism.

### §C.11 — OT-UT-8 open-questions-surface-to-user (meta-rule)

- **V1 target:** `project-template/docs/pack/PM-CHAT.md` `## Behavioral rules` NEW bullet.
- **VERDICT: keep.** PM-chat-orchestration content, project-side. No pack-side citations in proposed text (V1 lines 1046-1057).

### §C.12 — OT-UT-10 /tmp reports are ephemeral

- **V1 target:** `supporting-docs/METHODOLOGY.md` Part 9 Document Authoring Rules NEW paragraph.
- **VERDICT: keep.** METHODOLOGY.md is project-side (installed). Proposed text (V1 lines 1072-1080) is self-contained. RC9 fires (supporting-docs/ per BD-176).

### §C summary

All 12 §C placements survive the post-BD-175 boundary. **0 require discard. 5 require minor revision** (§C.4, §C.6, §C.8, §C.10 — boundary-bias word-level cleanup; §C.1 — RC9 trigger awareness). **7 keep as written.**

The reason no §C placement requires major revision: V1's targets — PM-CHAT.md (project-side SSOT), METHODOLOGY.md (project-side installed), project-template trinity (project-side TOOL-CONFIG) — are all correctly classified as PROJECT-side by `pack-ops/BOUNDARY-DEFINITION.md` §2 (C5, C4, C6 respectively). V1 did not propose putting project-side content into pack-only surfaces or vice versa for any §C item.

---

## §3 — Element-by-element verdicts (§D architecture decisions)

### §D.1 — Per-project Claude memory cache for project-side

- **V1 recommendation:** ship the convention in PM-CHAT.md "Tool-specific: Claude Code CLI" section; do not ship auto-tooling.
- **VERDICT: keep.** PM-CHAT.md "Tool-specific: Claude Code CLI" section is project-side, Claude-specific by section heading. The convention describes a per-project Claude memory cache directory pattern. G-9 confirmed no pack tooling currently ships this. No boundary risk: the rule lives on the project side, references project-side surface only.
- **One adjustment:** the V1 text refers to "the Tier 1.5 pointer index in the pack-side design (per pack memory pattern)." This is a cross-side citation. The cleaner project-side framing: describe the pointer-index pattern without citing the pack-side precedent — name it as a project-side convention on its own merits.

### §D.2 — Trinity surface vs PM-CHAT.md surface for behavioral rules

- **V1 recommendation:** placement rule — PM-chat-orchestration → PM-CHAT.md; agent-affecting → trinity; both-audience → mirror.
- **VERDICT: keep with one minor caveat.** This is a placement-meta-rule for project-side documentation. The mirror-across-both-surfaces pattern in V1 §D.2 conflicts with the PRINCIPLE-CHECK's "PM-chat omniscience" critique (mirroring duplicates rather than PM-injects). But that critique is about a different concern (where rules LIVE vs where they DELIVER), and it does not introduce a boundary violation.
- **The principle-check's recommended cascade** (move ~12 §C items to PM-CHAT.md-only, drop trinity STRENGTHEN where possible) is a SEPARATE design question from the post-BD-175 boundary salvageability — neither answer creates a boundary violation; both stay on the project side.

### §D.3 — Project-side audit/fix-cycle clarification

- **V1 recommendation:** add cycle-termination paragraph to METHODOLOGY.md Workflow 4.
- **VERDICT: keep.** Pure project-side methodology-doc clarification. No boundary risk.

### §D.4 — Project-side mid-phase planner triggers (P-A/P-B/P-C)

- **V1 recommendation:** new METHODOLOGY.md Workflow 4 sub-section.
- **VERDICT: keep (verify Trigger A definition still matches METHODOLOGY at HEAD).** Project-side methodology addition. The triggers cite project-side agents (coder, architect, planner) only. No pack-side citations. G-7 verified the rule is absent. Minor verification: METHODOLOGY.md Workflow 4 was untouched by BD-175..BD-184 (Workflow 4 lives at lines 435+; no BD in that range modified it), so V1's line-anchor at line 510-533 still resolves.

### §D.5 — Project-side closeout-gating elevation

- **V1 recommendation:** combined with §C.4 (PM-CHAT.md bullet) plus a one-line METHODOLOGY.md cross-reference in Part 7 Procedure 4.
- **VERDICT: keep.** Both surfaces project-side. The cross-reference between PM-CHAT.md and METHODOLOGY.md is internal to the project-side trinity-pair, not a cross-side citation.

### §D summary

All 5 §D decisions survive the post-BD-175 boundary. **0 require discard. 0 require major revision. 1 has a minor cross-side citation cleanup (§D.1).** The remaining 4 are clean as proposed.

---

## §4 — Element-by-element verdicts (§F open questions)

### D-1 — Project-template trinity Claude-only Agent Teams sub-section

- **V1 recommendation:** NO new sub-section.
- **VERDICT: still relevant, framing intact.** The question is still open. The architect recommendation (NO) aligns with the post-BD-175 maintainability principle (avoid trinity structural additions). G-1 confirmed the worktree-isolation issue applies project-side; G-2 confirmed Codex/Gemini have no peer-messaging equivalent.
- **One post-BD-175 consideration:** BD-181 + BD-183 extended Check 18/16/19 to enforce within-trinity parity at pack-root. A new H3 sub-section in `project-template/CLAUDE.md` that does NOT exist in AGENTS.md/GEMINI.md would NOT trigger a parity failure (Check 18 H2 parity uses an allow-list for Gemini-intrinsic H2s — and CLAUDE-intrinsic could be added). But it WOULD violate the project trinity rule's "Symmetry is the default; asymmetry requires justification as provably tool-specific" (project-template/CLAUDE.md L376-379). The Trinity exemption framing V1 inherits from pack-side may still work, but the project-side trinity rule wording is more restrictive than pack-side's.

### D-2 — Trinity placement of always-reviewer rule

- **V1 recommendation:** NO trinity placement; keep in PM-CHAT.md + METHODOLOGY.md.
- **VERDICT: keep recommendation.** No boundary effect; PM-CHAT.md and METHODOLOGY.md are both project-side appropriate.

### D-3 — Should §C.3 land?

- **V1 recommendation:** YES (architect recommends LAND).
- **VERDICT: keep.** Pure procedural-strengthen on project-side surface; no boundary effect.

### D-4 — Trinity-vs-PM-CHAT.md placement rule as project-template architecture principle

- **V1 recommendation:** YES, land in METHODOLOGY.md Part 9.
- **VERDICT: keep (REFRAME under P-missed-7 + project SSOT-first).** Project-side methodology addition. The placement rule V1 proposes is a documentation-architecture rule scoped to the project-template; it is project-internal.
- **Post-BD-175 reframe:** the project trinity now carries an explicit "Project SSOT-first" bullet (project-template/CLAUDE.md L385-401) that is partly orthogonal to V1 §D.2's placement rule. The placement rule is about "which project-side surface hosts which rule type" — internal to project-side. The Project SSOT-first rule is about "don't import from pack-side" — cross-boundary. They coexist cleanly. The §D.4 wording (V1 lines 1561-1582) does NOT contradict the project trinity SSOT-first rule.

### D-5 — §D.3 cycle-termination clarification

- **V1 recommendation:** YES, LAND.
- **VERDICT: keep.** Project-side; no boundary effect.

### D-6 — §D.4 mid-phase planner triggers

- **V1 recommendation:** YES, all 3 triggers (with caveats).
- **VERDICT: keep.** Project-side methodology addition; no boundary effect.

### D-7 — Prescriptiveness of closeout-sequence

- **V1 recommendation:** YES, prescriptive as written.
- **VERDICT: keep.** Pure project-side content question; no boundary effect.

### D-8 — Trinity STRENGTHEN for `git checkout --` ships in this batch

- **V1 recommendation:** YES, SHIP.
- **VERDICT: keep (BUT check BD-178 baseline + RC9 trigger).** The trinity STRENGTHEN target is the destructive-ops bullet — that bullet is the BD-178-canonicalized form at HEAD (see §C.6 verdict above). The STRENGTHEN edit MUST apply to the current BD-178 form, not V1's pre-BD-178 form. RC9 also fires (project-template/ is v11-surface).

### D-9 — Group by rule vs by file in commits

- **V1 recommendation:** GROUP BY RULE.
- **VERDICT: keep.** Pure sequencing/process question; no boundary effect.

### D-10 — Per-commit vs end-of-batch reviewer

- **V1 recommendation:** END-OF-BATCH ONLY.
- **VERDICT: re-evaluate under post-BD-175 per-BD-review discipline.** This recommendation aligns with V1's pre-BD-175 understanding of "one cycle per batch" — but BD-175 (and the BD-175 batch chain BD-176..BD-184) was a single-BD batch that ran 12 per-commit reviewers + 2 fix-passes + end-of-batch reviewer. The per-BD-inline-review pattern is now the default for any batch touching boundary-sensitive surfaces (per pack-root `## Pack memory` `### Workflow` "Per-BD review/fix runs INLINE" bullet — added 2026-05-15 and re-confirmed 2026-05-19+).
- **Post-BD-175 recommendation for V2:** the user should re-decide D-10 given that V1's §C touches project-side trinity (§C.6), PM-CHAT.md (7 placements), and METHODOLOGY.md (5 placements). The per-commit reviewer on trinity-edit commits is now the conservative default; V1's "END-OF-BATCH ONLY" was a pre-BD-175 simplification.

### D-11 (PRINCIPLE-CHECK addition) — PM-chat omniscience obligation

- **V1 architect recommendation (from PRINCIPLE-CHECK §6):** YES, land in METHODOLOGY.md Part 1 "Tool Roles" + cascade through §D.2 and §C.
- **VERDICT: still relevant, but the cascade scope needs re-examination under P-missed-7.** The principle itself (PM chat has bird's-eye view, is OBLIGATED to brief agents) is project-side content; no boundary risk in the principle itself.
- **Post-BD-175 consideration:** the PRINCIPLE-CHECK's recommended cascade (move ~12 §C items to PM-CHAT.md-only, mark trinity STRENGTHEN as defense-in-depth exception) interacts with the project SSOT-first rule. If §C items move to PM-CHAT.md-only with "PM chat injects relevant subsets into agent prompts on demand," PM-CHAT.md becomes the SSOT for those rules and the agent files DO NOT independently carry them. That is consistent with project SSOT-first (PM-CHAT.md is the project-side SSOT for PM-chat orchestration). The principle's framing does NOT introduce a boundary violation; it tightens the project-side internal architecture.
- **Important nuance the PRINCIPLE-CHECK introduced that V2 must honor:** the principle-check architect cited the pack-side `feedback_no_solutions_in_agent_prompts` and pack-side memory entries in their answer (PRINCIPLE-CHECK §3). When V2 ports the principle to METHODOLOGY.md Part 1, the wording MUST NOT cite pack-side memory entries — the project-side METHODOLOGY.md is installed to clients, who do not have the pack memory cache. This is a per-project SSOT-first concern, not a content disagreement.

### §F summary

All 11 §F open questions remain coherent and answerable post-BD-175. **0 questions are obsolete. 0 questions have been implicitly answered by BD-175..BD-184.** Two questions need a re-examination of recommendations under the new boundary: D-10 (per-commit reviewer default has shifted) and D-1 (project-side trinity asymmetry framing is more restrictive than pack-side's). The other 9 are unchanged in framing and recommendation.

---

## §5 — Element-by-element verdicts (§G research items)

The G items are external-CLI factual verifications and pack-source-presence checks. Per the prompt: "if all still hold, say so explicitly (avoid re-deriving the research)."

### Verdicts

- **G-1 (Claude Code worktree-isolation issue on project-side):** Y. Confirmed by official Claude Code Worktrees docs + issues #50850, #41680, #43535. Mechanism is universal at the worktree-creation layer. Still valid.
- **G-2 (Codex/Gemini have no Agent Teams analog):** Y (with nuance). Codex closest via `/agent` long-lived threads + `close_agent`; Gemini one-shot per delegation. `agent-run.sh` does not manage lifecycle on either. Cited evidence: Codex #18335 #19475 #12462 #11965 #12844; Gemini official subagents docs + deepwiki. Still valid.
- **G-3 (architect-trigger surface-even-mechanical absent from pack source):** N — not in pack source. Confirmed by direct file reads of METHODOLOGY.md lines 489-533, PM-CHAT.md 201-202, trinity files. Still valid.
- **G-4 (PM-chat-never-edits-source rule partially in PM-CHAT.md):** Y (partial). Buried in "Source file edits" bullet trailing sentence + METHODOLOGY Part 9 table cell. Still valid.
- **G-5 (re-read per-agent prompt file every time absent from PM-CHAT.md):** Y — the PRINCIPLES re-read rule exists at PM-CHAT.md L188-189 but per-agent prompt FILE re-read is absent. Still valid.
- **G-6 (closeout-sequence ordered rule absent):** Y — fragments scattered, but no single 5-step ordered bullet. Still valid.
- **G-7 (mid-phase planner triggers absent):** Y — Planner trigger rule at METHODOLOGY.md L236-248 covers phase-design-time only. Still valid.
- **G-8 (project-template skills carry OT-promotion content):** N — no significant overlap with planning / architecture-review / review / pm-startup skills. Still valid.
- **G-9 (per-project Claude memory cache tooling already shipped):** N — pack ships nothing. Still valid.

### §G summary

**All 9 research verdicts still hold.** None depended on pre-BD-175 pack state in a way that BD-175..BD-184 invalidated. The CLI-external verifications (G-1, G-2) are about Claude Code / Codex / Gemini behavior — orthogonal to pack-internal reorganization. The pack-source-presence verifications (G-3 through G-9) targeted PM-CHAT.md / METHODOLOGY.md / agent definitions / skills — and while BD-175..BD-184 modified some of these files (PM-CHAT.md by BD-178 + BD-180, METHODOLOGY.md by BD-175 Commit 8), the specific spots G-3 through G-9 checked were not where BD-175..BD-184 wrote. The verdicts are intact.

**No re-research needed for V2.** V2 architect can cite the G-1..G-9 verdicts as-is.

---

## §6 — Element-by-element verdicts (§H commit sequencing)

### H.0 — Pre-commit setup

- **V1 baseline:** HEAD `3d8cc8b` (Batch 19b close). 
- **POST-BD-175 STATUS: superseded.** HEAD at the time V1 was authored was `3d8cc8b`; HEAD today is `9da98a4` (after 12+ BD-175 commits + BD-176 through BD-184). Any commit sequencing baseline must be re-established at the actual pre-19c HEAD when V2 / planner runs.
- **Verdict: minor revision** — refresh baseline SHA + re-verify working tree clean state.

### H.1 — Commit 1: METHODOLOGY.md Workflow cycle additions

- **V1 scope:** §C.1 callout + §C.2 STRENGTHEN + §D.3 cycle-termination + §C.10 step 4 STRENGTHEN.
- **VERDICT: keep (with RC9 attachment).** All edits to METHODOLOGY.md; project-side. Post-BD-176, supporting-docs/ is v11-surface. The commit MUST regenerate `test-fixtures/manifest.txt` per RC9. V1's H.1 description does not mention RC9 (which was not yet in v11-surface for supporting-docs/ at V1 time). V2 / planner must add manifest-regen step.

### H.2 — Commit 2: PM-CHAT.md `## Behavioral rules` additions

- **V1 scope:** §C.1 PM-CHAT.md + §C.4 + §C.7 + §C.8 + §C.9 + §C.10 PM-CHAT.md + §C.11 + §D.5 cross-ref.
- **VERDICT: keep (with RC9 attachment).** PM-CHAT.md is under project-template/ — v11-surface — RC9 fires. METHODOLOGY.md cross-ref also triggers RC9 (now supporting-docs/ per BD-176). V1's H.2 already names the manifest-regen consideration in H.8 footnote (lines 2189-2196), but with BD-176 expansion the trigger now also applies to METHODOLOGY.md edits in H.2 / H.5 / H.6.

### H.3 — Commit 3: PM-CHAT.md STRENGTHEN

- **V1 scope:** §C.5 + §C.6 PM-CHAT.md bullet.
- **VERDICT: keep (with RC9 attachment).** project-template/; RC9 fires.

### H.4 — Commit 4: Trinity STRENGTHEN — destructive-operations list extension

- **V1 scope:** §C.6 trinity STRENGTHEN.
- **VERDICT: keep (CRITICAL: must apply to BD-178-canonicalized baseline; RC9 fires; per-commit reviewer recommended).** 
- **Post-BD-175 considerations:**
  1. BD-178 already canonicalized the destructive-ops bullet to the CLAUDE.md form across all three trinity files (`fa605a9` commit). V1's BEFORE text reflects pre-BD-178 state. The §C.6 STRENGTHEN MUST apply to the current HEAD form.
  2. BD-181 + BD-183 extended Check 18/16/19 to verify within-trinity parity at project-template (and pack-root, but project-template is what matters here). The STRENGTHEN must produce identical content in all three trinity files; CI Check 18 H2 parity will fail if not.
  3. RC9 fires (project-template/ trigger).
  4. Per-commit reviewer is now the default for any trinity-touching commit (per the post-BD-175 per-BD-review-INLINE pattern). V1's "SKIP per-commit reviewer" recommendation should be reversed.

### H.5 — Commit 5: METHODOLOGY.md substantive additions

- **V1 scope:** §D.4 mid-phase planner sub-section + §D.2 / §F D-4 placement rule sub-section + §C.12 /tmp ephemerality.
- **VERDICT: keep (with RC9 attachment).** supporting-docs/; RC9 fires post-BD-176. V1 already proposes per-commit reviewer for this commit due to §D.4 substantive size; that recommendation aligns with post-BD-175 default.

### H.6 — Commit 6 (CONDITIONAL): Procedure 1 BACKLOG-proactive STRENGTHEN

- **V1 scope:** §C.3 (conditional on §F D-3).
- **VERDICT: keep (with RC9 attachment).** supporting-docs/; RC9 fires post-BD-176.

### H.7 — Commit 7 (CONDITIONAL): Project-template trinity Claude-only sub-section

- **V1 scope:** §F D-1 (if = YES per Alt-2).
- **VERDICT: keep (with NEW post-BD-175 verifications if landed).**
- **Post-BD-175 considerations if D-1 = YES:**
  1. The Claude-only sub-section in `project-template/CLAUDE.md` only — by design Trinity-exempt — produces trinity asymmetry. Check 18 H2 parity will fail unless the new H3 is below an existing H2 whose body content is allowed to differ (it isn't — Check 18 enforces H2 body parity by default; the allow-list mechanism in BD-181's Check 18 generalization was for Gemini-intrinsic H2s, not for new CLAUDE-only sub-content).
  2. Per the project trinity rule wording (project-template/CLAUDE.md L376-379: "Symmetry is the default; asymmetry requires justification as provably tool-specific"), CLAUDE-only content needs documented justification. The pack-root Trinity exemption framing has precedent (per pack-root `CLAUDE.md` `### Sub-agent behavior (Claude-only)`); applying it project-side is parallel but not identical (project-side trinity is consumed at client install, where the client may or may not use Claude).
  3. Per-commit reviewer for this commit (V1 already recommends it) — aligns with post-BD-175 default.

### H.8 — End-of-batch reviewer + BD status flip

- **V1 scope:** end-of-batch reviewer + fix + status flip (single-BD batch close commit shape).
- **VERDICT: keep (single-BD batch close commit shape unchanged).** Per `pack-ops/PACK-CHAT.md` `## Behavioral rules` "Batch close commit shapes" — single-BD batches combine fix + status flip into ONE commit. That rule is intact. V1's H.8 wording correctly cites it.
- **Manifest-regen note in V1 H.8 (lines 2189-2196) is incomplete:** V1 says "supporting-docs/METHODOLOGY.md is NOT v11-surface." This was true PRE-BD-176; it is FALSE post-BD-176. V2 must update.

### §H summary

All 8 §H commits survive the post-BD-175 boundary. **0 require discard. 0 require major revision. 8 require RC9 / per-commit-reviewer / baseline-SHA refresh** — that is, every commit needs minor revision to attach the post-BD-176 manifest-regen trigger and (for trinity-touching commits) re-evaluate the per-commit-reviewer default.

The single material change is RC9 expansion (BD-176): V1's commit sequencing was authored against a 2-directory RC9 trigger (project-template/ + scripts/); the 4-directory trigger (BD-176: + pack-ops/ + supporting-docs/) means METHODOLOGY.md-touching commits in H.1, H.2, H.5, H.6 ALL need manifest regen now.

---

## §7 — §I Summary table — post-BD-175 dispositions

The V1 §I summary table can be augmented with a "post-BD-175 disposition" column. The mapping per row:

| OT-ID (V1 row) | V1 Target | V1 disposition | Post-BD-175 disposition |
|---|---|---|---|
| OT-T-1 (PM-CHAT.md) | PM-CHAT.md NEW bullet | KEEP | KEEP — no boundary risk; RC9 fires |
| OT-T-1 (METHODOLOGY.md) | METHODOLOGY.md NEW callout | KEEP | KEEP — RC9 newly fires per BD-176 |
| OT-T-2 | METHODOLOGY.md STRENGTHEN | KEEP | KEEP — RC9 newly fires per BD-176 |
| OT-T-3 | METHODOLOGY.md STRENGTHEN | KEEP (CONDITIONAL) | KEEP — RC9 newly fires per BD-176 |
| OT-T-4 (PM-CHAT.md) | PM-CHAT.md NEW bullet | KEEP | KEEP — verify insertion anchor post-BD-178 |
| OT-T-4 (METHODOLOGY.md cross-ref) | METHODOLOGY.md NEW callout | KEEP | KEEP — RC9 newly fires per BD-176 |
| OT-T-5 | PM-CHAT.md STRENGTHEN | KEEP | KEEP |
| OT-T-6 (PM-CHAT.md) | PM-CHAT.md NEW bullet | KEEP | KEEP |
| OT-T-6 (trinity STRENGTHEN) | project-template/ trinity STRENGTHEN | KEEP | KEEP — apply to BD-178 baseline; RC9 fires |
| OT-T-7 | PM-CHAT.md NEW bullet | KEEP | KEEP |
| OT-UT-1 | project-template/CLAUDE.md (conditional) | CONDITIONAL per D-1 | KEEP CONDITIONAL — Check 18 H2 implications must be re-examined if D-1 = YES |
| OT-UT-2 | PM-CHAT.md NEW bullet | KEEP | KEEP — minor wording cleanup (drop "supporting-docs/" example) |
| OT-UT-3 | PM-CHAT.md NEW bullet | KEEP | KEEP |
| OT-UT-4 | (none) | OOS | OOS — unchanged |
| OT-UT-5 | (none) | OOS | OOS — unchanged |
| OT-UT-6 (PM-CHAT.md) | PM-CHAT.md NEW bullet | KEEP | KEEP — minor wording cleanup (drop cross-side citation) |
| OT-UT-6 (METHODOLOGY.md) | METHODOLOGY.md STRENGTHEN | KEEP | KEEP — RC9 newly fires per BD-176 |
| OT-UT-7 | (none) | OOS | OOS — unchanged |
| OT-UT-8 (meta) | PM-CHAT.md NEW bullet | KEEP | KEEP |
| OT-UT-8 (specifics) | (none) | OOS | OOS — unchanged |
| OT-UT-9 | (subsumed by OT-T-7) | KEEP | KEEP |
| OT-UT-10 | METHODOLOGY.md NEW paragraph | KEEP | KEEP — RC9 newly fires per BD-176 |
| OT PM gap A (mid-phase planner) | METHODOLOGY.md NEW sub-section | KEEP (CONDITIONAL) | KEEP — RC9 newly fires per BD-176 |
| OT PM gap B (closeout elevation) | (see §C.4 + §D.5) | KEEP | KEEP |
| OT PM gap C (cycle-termination) | METHODOLOGY.md NEW callout | KEEP (CONDITIONAL) | KEEP — RC9 newly fires per BD-176 |
| Arch derived 1 (placement rule) | METHODOLOGY.md NEW sub-section | KEEP (CONDITIONAL) | KEEP — interacts with project SSOT-first; no contradiction |
| Arch derived 2 (per-project memory) | PM-CHAT.md NEW paragraph | KEEP (CONDITIONAL) | KEEP — drop pack-side precedent citation |

**Net mapping:** 26 rows total. **0 DISCARD. 0 MAJOR REVISION. 5 KEEP-with-minor-wording-revision (§C.4, §C.6 BD-178 baseline check, §C.8 wording, §C.10 wording, §D.1 wording). 21 KEEP unchanged in placement or content (RC9 trigger attachment is procedural, not content-changing).**

---

## §8 — Boundary risks (highest priority — ranked)

This section enumerates every spot where V1 would re-introduce a violation BD-175..BD-184 just remediated. These are surfaced separately so the user can triage them ahead of the per-element verdicts.

**The good news upfront:** V1's overall design is consistently project-side-oriented. V1's §A.2 distinction table (V1 lines 46-54) correctly identifies project-side as the scope. V1's §E.1 explicitly excludes pack-side surface. V1's §C placements all target project-side files (PM-CHAT.md, METHODOLOGY.md, project-template trinity). **V1 does NOT propose moving pack-side content to project-side, nor vice versa, in any §C placement.** The boundary risks below are word-level, citation-level, and one structural-asymmetry risk — not placement-level.

### Boundary-risk ranking

**B1 — V1 §C.10 OT-UT-6 cites pack-side memory `feedback-planner-user-review-before-coder` as precedent in project-side prose.** Severity: LOW–MEDIUM (wording, not placement). V1 line 1002-1004: "This is the project-side analog of the pack-side 'Planner output → user review → coder spawn' rule applied one step earlier..." A project-side reader (PM chat at a client install) has no access to the pack-side memory. Per `boundary-investigation` Step 4 deny-list, citing pack memory entries from project-side files is borderline (not in the strict deny-list but mismatched audience). FIX: drop the cross-side citation; assert the rule on its own merits.

**B2 — V1 §C.8 OT-UT-2 includes the phrase "supporting-docs/" as an example of pack-side reference content.** Severity: LOW (wording). V1 lines 943-944: "...read METHODOLOGY.md, prompts/, supporting-docs/ as upstream source." `supporting-docs/` is a pack-repo path (per `pack-ops/BOUNDARY-DEFINITION.md` §3 placement, supporting-docs/ is C4 PROJECT × PRODUCT but its NAME at the pack-repo path is a pack-internal path). Per `boundary-investigation` Step 4 deny-list, path prefixes like `supporting-docs/` from project-side files are borderline. FIX: use project-side post-install paths only (`docs/pack/METHODOLOGY.md`, `docs/pack/prompts/`).

**B3 — V1 §D.1 cites pack-side memory pattern as precedent in project-side METHODOLOGY context.** Severity: LOW (wording). V1 lines 1102-1110 describe the Tier 1.5 design "established in Batch 19b" — a pack-side history reference. The project-side reader does not need or have access to that history. FIX: describe the per-project Claude memory cache convention on its own merits; do not anchor to pack-side Tier 1.5 design.

**B4 — V1 §H.1 / H.2 / H.5 / H.6 commit sequencing omits supporting-docs/ RC9 trigger.** Severity: MEDIUM (CI-impact). V1 was authored when RC9 was 2 directories (project-template/ + scripts/); BD-176 extended to 4 (added pack-ops/ + supporting-docs/). V1's H.1-H.6 commits edit METHODOLOGY.md (under supporting-docs/) without manifest regen. Without RC9 attachment, every one of these commits will FAIL the `fixture manifest verify` CI step — same incident class BD-176 closed (BD-175 Phase 5 Commit 8 `4120d19` CI failure). FIX: V2 / planner attaches manifest-regen step to every METHODOLOGY-touching commit.

**B5 — V1 §C.6 trinity STRENGTHEN assumes pre-BD-178 baseline.** Severity: MEDIUM (correctness). V1's BEFORE text (V1 lines 874-881) shows the pre-BD-178 form of the destructive-ops bullet. BD-178 canonicalized this bullet across all three project-template trinity files (`fa605a9`). V1's STRENGTHEN edit, applied mechanically to V1's recorded BEFORE text, will fail to match the current HEAD content. FIX: V2 / coder reads current HEAD trinity content and applies the STRENGTHEN to the BD-178-canonicalized form.

**B6 — V1 §F D-10 "END-OF-BATCH ONLY" recommendation predates post-BD-175 per-BD-INLINE-review pattern.** Severity: MEDIUM (process). The per-BD review/fix runs INLINE pattern (pack-root `CLAUDE.md` `## Pack memory` `### Workflow`, post-BD-175 reaffirmed) is the new default. V1's recommendation reflects the older "one cycle per batch" framing. For a batch touching trinity (§C.6) and PM-CHAT.md / METHODOLOGY.md extensively, per-commit reviewer on at least the trinity-touching commit (§H.4) is now the default. FIX: V2 / user re-decides D-10 under the new default.

**B7 — V1 §F D-1 Conditional H.7 (Claude-only sub-section in project-template/CLAUDE.md) may collide with Check 18 H2 parity if landed.** Severity: MEDIUM (CI-impact, conditional). If D-1 = YES (architect recommends NO), a new H3 under `## Project memory` only in CLAUDE.md (not in AGENTS.md or GEMINI.md) creates a within-trinity body asymmetry that the Check 18 parity check (post-BD-181 + BD-183) may flag. The pack-root Trinity-exemption framing for CLAUDE-only sub-sections has a paired Check 18 allow-list mechanism; project-side has parallel infrastructure but the allow-list mechanism is for H2-level Gemini intrinsics, not for H3-level CLAUDE-only sub-sections. FIX (if D-1 = YES): V2 / architect re-examines Check 18 H2 parity semantics and adds CLAUDE-intrinsic H3 to the allow-list mechanism if needed.

**B8 — V1 §J.3 parity check cites the maintainability principle for trinity structural changes; the post-BD-175 + BD-181 + BD-183 + BD-184 work added stricter CI guards.** Severity: LOW (process). V1's §J.3 (lines 2284-2301) correctly notes "No new H3 sub-sections in trinity `## Project memory`" as the V1 posture. Post-BD-175, the Check 18 / 16 / 19 parity guards at pack-root (BD-181, BD-183) and Check 42 (BD-184) tighten the CI enforcement. The V1 posture aligns; no inconsistency. FIX: V2 cites the post-BD-175 strengthened parity guards as the rationale, not the pre-BD-175 architect doc.

**B9 — PRINCIPLE-CHECK §3 cites pack-side memory entries (`feedback_no_solutions_in_agent_prompts`, pack-side trinity Pack memory) as evidence for project-side principle.** Severity: LOW–MEDIUM (wording when the principle lands). The architect's principle-check answer cites pack-side surfaces extensively as evidence for the omniscience principle. If V2 ports the principle to METHODOLOGY.md Part 1 "Tool Roles" verbatim, the cross-side citations will leak into a project-side installed file. FIX: V2 architect rewords the principle in METHODOLOGY-appropriate language, asserts the principle on its own merits, citing only project-side surfaces (PM-CHAT.md `## Behavioral rules`, METHODOLOGY.md `## Prompt Authoring Principles`, project-template trinity `## Project memory`).

### Boundary-risk summary

**0 risks require V1 discard. 0 risks are "V1 would put pack-side content into project-side surface" (the most severe class — none present). All 9 risks are wording-level, citation-level, or process-level adjustments that V2 / planner can apply.**

The reason V1 has so few boundary risks despite predating BD-175: V1's §A.2 distinction table (lines 46-54), its §E.1 explicit exclusion of pack-side, and its §C placement choices were all consistent with the boundary BD-175 later codified formally. V1 anticipated the boundary correctly even without the formal authority.

---

## §9 — Salvageability tier ranking

### Tier 1 — Keep as written (no change)

These elements have ZERO boundary risk and no post-BD-175 procedural changes:

- §C.2, §C.3, §C.5, §C.7, §C.9, §C.11, §C.12 (7 of 12 §C placements)
- §D.2, §D.3, §D.4, §D.5 (4 of 5 §D decisions)
- F D-2, D-3, D-5, D-6, D-7, D-9 (6 of 11 §F questions)
- All 9 §G research items
- §J.1, J.2, J.4, J.5, J.6 parity checks (5 of 6)
- §K risk surface section (6 risks, all still apply)

### Tier 2 — Minor revision (word-level cleanup or procedural attachment)

These elements require ≤30 minutes of editorial cleanup per element:

- §C.1 (RC9 trigger attachment — supporting-docs/ now in v11-surface)
- §C.4 (verify insertion anchor post-BD-178)
- §C.6 (apply STRENGTHEN to BD-178 canonicalized baseline)
- §C.8 (drop "supporting-docs/" example from wording — boundary-risk B2)
- §C.10 (drop pack-side cross-side citation — boundary-risk B1)
- §D.1 (drop pack-side Batch 19b precedent citation — boundary-risk B3)
- §F D-1 (re-examine Check 18 H2 implications if YES — boundary-risk B7)
- §F D-8 (CHECK BD-178 baseline)
- §F D-10 (re-decide under post-BD-175 per-BD-INLINE default — boundary-risk B6)
- §F D-11 (drop pack-side memory citations from principle wording — boundary-risk B9)
- §H.0 (refresh baseline SHA)
- §H.1, H.2, H.5, H.6 (attach manifest-regen step — boundary-risk B4)
- §H.4 (apply to BD-178 baseline; per-commit reviewer recommended — boundary-risks B5 + B6)
- §H.7 (per-commit reviewer recommended; Check 18 H2 implication if landed)
- §H.8 (correct V1's "supporting-docs/ is NOT v11-surface" footnote)
- §I summary table (add post-BD-175 disposition column — per §7 above)
- §J.3 mechanical-edit threshold parity check (cite post-BD-175 strengthened guards)

### Tier 3 — Major revision (requires substantive re-design)

**None.** No element falls in Tier 3.

### Tier 4 — Discard (cannot be salvaged)

**None.** No element falls in Tier 4.

---

## §10 — Overall verdict

**FULLY SALVAGEABLE WITH MINOR REVISION.**

V1 is sound at the placement level. The 17-item OT inventory, the per-item categorization (§B), the placement decisions (§C), the architecture decisions (§D), the open questions (§F), and the research scoping (§G) are all consistent with the post-BD-175 boundary discipline. **No §C placement, no §D decision, and no §F question requires re-litigation under the new boundary.**

The mid-V1 PRINCIPLE-CHECK introduced a real and orthogonal concern (PM-chat omniscience as foundational principle) that interacts with V1's §D.2 placement rule. The PRINCIPLE-CHECK is well-framed and surfaces a legitimate cascade question — but that cascade is INTERNAL to project-side architecture (move ~12 §C items between PM-CHAT.md and trinity; document defense-in-depth exceptions). It is NOT a boundary-discipline question; it is a project-side-doc-architecture question. Post-BD-175 does not predetermine the cascade's answer either way.

The G-1..G-9 research verdicts all still hold. **No re-research is needed.**

The §H commit sequencing needs procedural attachment (manifest-regen step per RC9 expansion, per-commit reviewer default re-evaluation per per-BD-INLINE pattern) but no commit restructuring. V1's "group by rule" recommendation is still valid; V1's commit count (5 mandatory + 2 conditional + 1 end-of-batch) is still appropriate.

**Recommendation form for the user-decision gate:**

**Option (a) — Proceed with V1 unchanged.** Not recommended. The 5 minor wording revisions and the procedural attachments are easy to land in V2 / planner; landing them with V1 would carry low-grade boundary-bias artifacts into v11.0.

**Option (b) — Revise V1 in place.** Viable. Pack Chat (or a fresh architect tightly scoped to "apply the salvageability assessment") can edit V1 in place. Estimated effort: 1-2 hours.

**Option (c) — Discard V1 and re-architect (V2 fresh pass).** Not necessary. V1's underlying analysis is sound; a fresh V2 would re-derive the same §B categorizations, the same §C placements, and the same §F open questions, then encounter the same PRINCIPLE-CHECK question. The fresh-eyes value is low compared to the time cost. **The exception:** if the user wants to make a substantive PRINCIPLE-CHECK decision (D-11) before V2 lands, a fresh V2 architect reading V1 + PRINCIPLE-CHECK + research + user resolutions is well-positioned to apply the principle's cascade through §C and produce the §D.2 rewrite atomically.

**Option (d) — Defer 19c.** Not recommended. V1's salvageability is high; the underlying user direction (per BD-173 entry) was to land 19c BEFORE Batch 20 so every subsequent batch acts as a validation pass for the new project-side rules. Deferring 19c defeats that purpose.

**The most efficient pipeline given the assessment:**

1. User reads this assessment.
2. User decides on D-1, D-3, D-5, D-6, D-7, D-8 at V1's recommendation (architect recommended each); decides on D-2, D-4, D-9, D-10, D-11 with the post-BD-175 considerations in mind.
3. User decides between option (b) "revise V1 in place" and option (c) "spawn V2 fresh."
4. Either way, the resulting V2 (or revised V1) is consumed by planner → coder per the standard pipeline.

The G-1..G-9 research output is durable and does not need re-running.

---

*End of ARCHITECTURE-PRE-19C-SALVAGEABILITY.md.*
