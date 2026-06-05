# PACK-REVIEW — BD-200 C4 — Procedure 6 redesign

**Role:** pack-reviewer (fresh, read-only). **Branch:** `v11-dev`. **HEAD:** `2d68077a1198a77921296017b972573f01bb498c`.
**Date:** 2026-06-04. **Cycle position:** review-1 on C4 (the final BD-200 commit). Per the literal trinity rule "Pack Chat NO coder review; bounded reviewer/fix cycle": this is pair-1 review. CLEAN ⇒ commit; findings ⇒ fix-1 → review-2.
**Subject:** the uncommitted C4 working-tree change — `supporting-docs/METHODOLOGY.md` Procedure 6 redesign + regenerated `test-fixtures/manifest.txt`.
**Method:** independent re-measurement of the working tree; no prior PACK-REVIEW/IMPL report read (bias avoidance).

---

## VERDICT: CLEAN

C4 is correct, complete, boundary-clean, and scope-faithful. The Procedure 6 redesign strips every pack-self token, preserves 100% of the load-bearing structure (all gates / steps / contracts / lists), is a coherent no-pack-clone client workflow keyed to the shipped `activate-capability.sh`, and the coder's two accuracy refinements (Step 6.5 + the Procedure-7 symmetry paragraph) are factually correct against the shipped script and minimal in scope. `validate-pack.py` PASSES; Checks 22/37/43/47 green; the manifest is reproducible and moves only the 3 expected v11-* rows. No findings to fix.

---

## Evidence by verification dimension

### 1 — Boundary (HIGHEST priority): zero pack-self tokens — PASS

Grep of the redesigned Procedure 6 (lines 1407–1465) for the full forbidden token set
(`add-capability`, `from the pack`, `stage A7`, `stage A8`, `A0–A8`, `BD-[0-9]`,
`capability_skills`, `capability_files`, `capability_install_checks`, `maintenance-docs/`,
`pack-ops/`, `pack-architect|pack-coder|pack-reviewer|pack-planner`, `$PACK`) →
**ZERO hits.** Whole-file rescan for `add-capability|.pack-add-capability|stage A[0-9]|capability_{skills,files,install_checks}` → **ZERO residual tokens anywhere in `METHODOLOGY.md`** (the EEB-PROC6-CONTAMINATED hits at old lines 1412/1415-1416/1432/1457/1463 are all gone).

Script-fact alignment (the verb + prompt-file the procedure names must match the shipped script):
- Verb `scripts/activate-capability.sh` — matches `project-template/scripts/activate-capability.sh` usage lines 28-29.
- Prompt file `.pack-activate-capability-prompt.md` — matches `activate-capability.sh:53` `readonly PROMPT_FILE=".pack-activate-capability-prompt.md"` exactly (prompt's explicit confirmation target).
- "gitignored local state" claim in Step 6.1 — matches the script's `ensure_prompt_gitignored()` (lines 74-85) which appends `$PROMPT_FILE` to `.gitignore`.

CI catch-net confirms: **Check 43 OK** (158 client-installed files walked, zero pack-internal bare cross-refs) and **Check 37 OK** (170 project-side files walked, zero deny-list contamination) — both walk the installed `docs/pack/METHODOLOGY.md`.

### 2 — Structure preservation (no dropped content) — PASS

Old (`2d68077:`) vs new inventory, both measured:

| Element | Old | New |
|---|---|---|
| Gates G6-drafts / G6-install / G6-commit | present | present (verbatim) |
| 7-step table 6.1–6.7 | all 7 | all 7 |
| TRIO trinity-edit contract ("always TRIO … one commit") | present | present (verbatim) |
| Artifacts modified list | present | present (verbatim) |
| Artifacts never touched list | present | present (verbatim) |
| Symmetry with Procedure 7 subsection | present | present (refined, see #4) |

Nothing dropped. The change is **3 targeted hunks** (`@@ -1407 / -1415,9 / -1432,-1436 / -1456,12 @@`), all confined to the Procedure 6 region — a targeted in-place edit, not a section-dropping full rewrite. `edit-in-place-not-full-rewrite` satisfied. Procedure-heading count stable at 10 (old) → 10 (new).

### 3 — Self-contained / runnable no-pack-clone — PASS

End-to-end read of the redesigned procedure: trigger is the developer running
`scripts/activate-capability.sh --add <dimension>:<value>` (client-installed, no `$PACK`);
the new lead paragraph (lines 1419-1427) states the script "re-materializes the conditional
files … from the tracked `pack-capability-pool/` directory … No external clone is needed —
the pool travels with the project." Step 6.1 reads the script's own prompt; Steps 6.2-6.7
are PM-chat-side trinity/install/commit work with no pack-clone assumption. No residual
"run from the pack" framing anywhere. Coherent client workflow.

### 4 — Accuracy to the shipped script (the coder's flagged refinement) — PASS

**(a) Repoint is factually correct.** `activate-capability.sh` stage functions are
`stage_p0_preflight` / `p1_resolve` / `p2_delta` / `p5_copy` / `p8_prompt` — there is **no
P7/A7 tool-probe stage** and **no `probe_tool_present` / install-check discovery** (the single
`capability_install_checks` occurrence at line 92 is a sourcing comment, not a call). By
contrast the retired `add-capability.sh` genuinely HAD `stage_a7_install_check()` with
`probe_tool_present` (lines 464-499). So the old Procedure 6 claim that "discovery itself runs
script-side (`add-capability.sh` stage A7)" is now false for the new script, and the coder
correctly repointed:
- Step 6.5: from "for each missing tool listed in the prompt's install-hint block" → "Identify any machine-level tools the newly-activated dimension needs (from the dimension's `SKILL.md` … and `INSTALL-PROCEDURES.md`)" — i.e. PM-chat-side discovery, matching reality.
- Symmetry paragraph: from "discovery runs script-side (A7) … no G6-discovery gate" → "Tool discovery is PM-chat-side in step 6.5 … so no G6-discovery gate is needed."

**(b) Procedure-7 touch is minimal, not scope creep.** The edited paragraph is the **"Symmetry with Procedure 7" subsection of Procedure 6**, not Procedure 7 itself. Procedure 7 proper (its relocated stub at line 1466) is untouched in the diff (the `### Procedure 7` line appears only as diff *context*, no `+`/`-`). The edit is the minimum needed to keep the symmetry paragraph factually consistent with the new no-probe script. No overreach.

### 5 — No collateral changes — PASS

All diff hunks fall within lines 1404–1465 (Procedure 6). Procedure 5-S, Procedure 7
proper, "Cancelling or deprecating a BACKLOG item", "Agent BACKLOG write permissions",
and every other section are byte-stable. Only the intended Procedure 6 spans changed.

### 6 — Guards + manifest — PASS

- `python3 scripts/validate-pack.py` → **PASSED — all checks clean.** (Check 48 emits 14 advisory WARNs for removed-doc citations in `pack-ops/CHANGELOG.md` / `BACKLOG.md` — pre-existing, soft-advisory, exit-code-unaffected, and NOT touched by C4.)
- **Check 43** OK; **Check 37** OK; **Check 22** OK (pack-root: 8 prose verbs all present; the `activate-capability.sh` client verb resolves on the project-template surface).
- **Check 47** OK — frozen 2-tuple `['scripts/lib/detect.sh', 'scripts/pack-help.sh']` unmoved (METHODOLOGY is `supporting-docs/`, invisible to the membership gate).
- **Manifest:** the diff moves exactly the 3 v11-* rows (`v11-realistic-ot`, `v11-flat-file`, `v11-tracker-on`); `v10-minimal`, `v10-realistic-ot`, `existing-project-mid-dev` are unchanged (matches plan R4 — only v11 fixtures install `docs/pack/METHODOLOGY.md`). Reproducible: a fresh `bash test-fixtures/build.sh --all --clean` regenerates byte-identical row SHAs to the staged diff. `regenerate-manifest-v11-surface` satisfied (supporting-docs/ is v11-surface; non-empty manifest diff staged in the same change).

### 7 — Scope + BD-202 boundary — PASS

Exactly `supporting-docs/METHODOLOGY.md` + `test-fixtures/manifest.txt` are modified in the
tracked working tree (the `??` IMPL/PACK-REVIEW files are prior-commit report artifacts, not
C4 scope). No `pack update` / pool-refresh / wipe-repopulate / cross-version logic introduced
in Procedure 6 (grep → zero) — the BD-202 boundary holds. No C1/C2/C3 file (`capability-tables.sh`,
`activate-capability.sh`, `init-project.sh`, HELP-FRAGMENT/PM-CHAT/INSTALL-PROCEDURES) is
touched by C4.

---

## Findings

None. (No BLOCKER / MUST / SHOULD / NIT.)

---

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| READ-IN-FULL set | Read in full via Read calls: `CLAUDE.md` incl. `## Pack memory` (541 lines); `pack-ops/PACK-AGENTS.md` (226 lines); `pack-ops/PACK-CHAT.md` (310 lines); `project-template/CLAUDE.md` (456 lines); `PLAN-BD-200.md` (234 lines, full — incl. §2 T5, §5, §6, and EEB-PROC6-CONTAMINATED at line 210); `ARCHITECTURE-BD-200-ADVERSARIAL-REVIEW.md` (441 lines, full — two pages 1-336 + 337-441, incl. §4.3/§4.6 + §10.6 BD-202 boundary); BD-200 entry `pack-ops/BACKLOG.md:3273-3305` + BD-202 `:3310-3326` (full); curated memory (each full): `feedback_agents_read_rule_docs_in_full`, `feedback_agent_output_rules_applied_block`, `feedback_manifest_regen_on_v11_surface`, `feedback_bd_pack_only_operational_rule`, `feedback_edit_in_place_not_full_rewrite`, `feedback_client_ref_delete_or_forward_look`, `feedback_review_cycle_position_checkpoint`. Measured source: `supporting-docs/METHODOLOGY.md` (1404-1513), `project-template/scripts/activate-capability.sh` (verb/PROMPT_FILE/stage fns/comment 88-95), `scripts/add-capability.sh` (A7 stage 452-499), `test-fixtures/manifest.txt` (full), `git show 2d68077:` old Procedure 6. | COMPLIANT |
| boundary / no-pack-self-in-project | Procedure 6 grep for the 13-token forbidden set → ZERO; whole-file `METHODOLOGY.md` residual `add-capability`/A-stage/table-fn scan → ZERO; Check 43 OK (158 files, zero bare cross-refs), Check 37 OK (170 files, zero contamination). Op-vs-explanatory test N/A — no surviving pack-self reference of any kind. | COMPLIANT |
| edit-in-place-not-full-rewrite | `git diff -U0` → 3 hunks all within lines 1407-1464; every old gate/step/contract/list verified present in new via side-by-side inventory; Procedure-heading count 10→10 (no section dropped). Targeted in-place edit, not a rewrite. | COMPLIANT |
| client-ref delete-or-forward-look | Old refs to retired pack verb `add-capability.sh` / `.pack-add-capability-prompt.md` are REPLACED (not deleted-and-left-dangling) with the landed client verb `scripts/activate-capability.sh` + client prompt file `.pack-activate-capability-prompt.md` — forward-look to the installed client paths, confirmed against the shipped script (case 2: genuine project asset by its landed path). | COMPLIANT |
| empirical verification | Every verdict backed by a command + quoted output: boundary grep (ZERO), `validate-pack.py` (PASSED), Check 22/37/43/47 (OK quoted), manifest diff (3 v11-* rows), rebuild reproducibility (identical SHAs), old-vs-new inventory (`git show 2d68077:`), stage-fn grep of `activate-capability.sh`. No verdict from inference alone. | COMPLIANT |
| ci-guard-measure-then-bound | Measured each named guard against the actual post-edit tree before concluding: Check 43/37 walk counts captured; Check 22 verb-resolution captured; Check 47 frozen 2-tuple printed unchanged; Check 48 WARNs identified as pre-existing/out-of-scope (not a gate failure). No allowlist movement; no STRIP needed (zero contamination measured). | COMPLIANT |
| BD-202 boundary | Procedure 6 grep for `pack update|wipe|repopulate|refresh|update propagation|cross-version` → ZERO; no C1/C2/C3 file touched; tracked diff = METHODOLOGY.md + manifest only. No update-path logic introduced. | COMPLIANT |
| review-cycle-position-checkpoint | Stated at top: review-1 on C4 (pair-1); CLEAN ⇒ commit, findings ⇒ fix-1 → review-2. A clean verdict does not collapse the cycle — Pack Chat still surfaces this report for triage. Reviewer did no fixes (read-only). | COMPLIANT |
| scope-deliverables-to-the-ask | Reviewed exactly the C4 change (Procedure 6 + manifest); led with the verdict (CLEAN); no edge-case / SUSPECTED sprawl; out-of-scope items (Check 48 WARNs, `??` report artifacts) named as out-of-scope, not interleaved as findings. | COMPLIANT |
| rules-applied-verification-block | This block — per-rule name + measured/quoted evidence + terminal COMPLIANT verdict; no empty-evidence rows; no AMBIGUOUS terminal states; READ-IN-FULL row carries per-file proof. | COMPLIANT |
| agents-never-commit | Only read-only verbs used (`git rev-parse`, `git status`, `git diff`, `git show`, `grep`, `sed`, `python3 validate-pack.py`, `bash build.sh`) + a single Write of THIS report at the caller-specified path; NO `git add/commit/push/tag`. (Note: `build.sh --all --clean` regenerated the manifest to verify reproducibility; it left the working tree byte-identical to the pre-existing staged C4 manifest state — no net change introduced.) | COMPLIANT |
