# PACK-REVIEW-C2 — BD-221 completion cluster, commit C2

**Reviewer:** pack-reviewer (read-only, IN-PLACE, main working tree)
**Repo:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`
**Branch:** `v11-dev`  **HEAD (C2 base, post-C1):** `a36bdd3`
**C2 state:** applied + uncommitted in the working tree (3 modified files, all `scripts/`)
**Reviewed against:** PLAN-BD-221-ANTIGRAVITY-COMPLETION-FINAL2.md (C2 §, §5 crosswalk) + DESIGN-BD-221-ANTIGRAVITY-COMPLETION-v2.md (§5.1 locus table). No prior IMPL-REPORT or prior review read.

## VERDICT: CLEAN

C2 is a complete, correct, internally-lockstep `.gemini`→`.agents` conversion of the install engine. Every DESIGN §5.1 locus is converted; the one per-check test C2's edit BROKE (check-41) is fixed in-commit; the five other RED per-check tests are pre-existing intermediate-red (C4 surfaces), proven NOT C2-caused; the comm delta is exactly net 70→52 (CLEARED Check 39×9 + 41×9, NEW=0); scope is pack-only with no boundary leak; the manifest deferral is correctly present (not flagged). No BLOCKER / MUST / SHOULD findings. Two NITs below are observations, not fixes.

---

## 1. init-project.sh conversion completeness (checklist 1) — PASS

Every DESIGN §5.1 (lines 202-219) locus is converted. Verified line-by-line against `git diff scripts/init-project.sh`:

| §5.1 locus | Required conversion | Status |
|---|---|---|
| L393-397 help-text | `.gemini/`→`.agents/`; KEEP `GEMINI.md` line | DONE (L394 `.claude/, .codex/, .agents/`; `GEMINI.md` kept) |
| stage_s1_skeleton | drop `.gemini/{agents,skills}`, add `.agents/skills`; drop `.gemini/agents` verify leg | DONE |
| stage_s2_agents | loop `claude codex gemini`→`claude codex`; ADD plugin-bundle stage of `.agents-plugin/optiquity-agents/` + bundle-count verify | DONE (new `bundle_src`/`bundle_dst` stage + `bundle_count` check) |
| stage_s3 | REMOVE `.gemini/{settings.json,.env,.env.example}` copy+asserts; ADD `.agents/mcp_config.json` `.example`→live | DONE (`pack_template_for_proj_path` repointed; assert repointed) |
| stage_s4_skills (×2) | `claude codex gemini`→`claude codex agents`; existing-install exception §2.1 | DONE (both loops; classifier-aware branch added) |
| S11 explicit-copy block | REMOVE entire per-CLI pack-help + `.gemini/commands/*.toml` block; KEEP pack-help.sh+detect.sh script copies | DONE (block replaced with pool-skill comment; script copies kept) |
| L992 comment | `Claude/Codex/Gemini`→`Claude/Codex/Antigravity` | DONE |
| cmd_update rows | REMOVE `.mcp.json.example`, `.gemini/.env.example`, `.gemini/settings.json`, 4 per-CLI pack-help/pm-startup; ADD `.agents/mcp_config.json.example` | DONE |
| cmd_update agent loop | `claude codex gemini`→`claude codex` + ADD bundle `_cmd_update_iter_dir` leg | DONE |
| bulk-copy comment | `.{claude,codex,gemini}`→`.{claude,codex,agents}` + bundle note | DONE |
| `_CLIENT_INSTALLED_FILES` | REMOVE stale rows; ADD `.agents/mcp_config.json.example`; KEEP `GEMINI.md` | DONE |
| blast_radius_sweep | `scope_dirs` `.gemini`→`.agents .agents-plugin`; KEEP `GEMINI.md` in scope_files | DONE |

**Residue check (evidence):** `grep -n "\.gemini/" scripts/init-project.sh` → **0 hits**. `grep -niE "gemini" | grep -viE "GEMINI\.md"` → **0 hits**. `GEMINI.md` file refs (KEEP-LEGITIMATE) = 5. Conversion is exhaustive with zero `.gemini/` dir residue.

`bash -n scripts/init-project.sh` → syntax OK. The new S4 `existing-install` branch reuses the pre-existing `existing_classifier_copy()` (defined L101, already used at S3 L503 / S5 L559 / S11 L934) and the pre-existing `CLASS` var (set L1513) — both present at BASE; no new undefined-symbol dependency. This brings S4 into parity with the other stages' existing-install handling (design-sanctioned by §5.1 "existing-install exception per §2.1").

## 2. cross-cli-reference-normalization (checklist 2) — PASS

The new install-map row `project-template/.agents/mcp_config.json.example:.agents/mcp_config.json:generic` uses the audience-correct `generic` classifier (18 rows use it). It does NOT carry the retired `gemini-env` classifier (correctly — `gemini-env` is C3's removal target; reusing it here would couple C2 to a C3-retired token). The S3 docstring is rewritten to describe Antigravity's `.agents/mcp_config.json` workspace MCP config (not a byte-copy of the old Gemini `.env` prose). `.example` source exists (`project-template/.agents/mcp_config.json.example`, 1619 bytes, landed C1). Conversion is audience-correct, not mechanical byte-copy.

## 3. test-init-project.sh lockstep (checklist 3) — PASS

`git diff scripts/tests/test-init-project.sh`: `make_configured_target` `.gemini`→`.agents`; pack-help assertion repointed `.gemini/commands/pack-help.toml`→`.agents/skills/pack-help/SKILL.md`; ADDED `.agents/skills/` dir assertion; `GEMINI.md` trinity write KEPT. Note: the plan's "remove pm-startup `.gemini` asserts" was a contingency that did not apply — the base test had no standalone pm-startup `.gemini` assert (only the L47 mkdir + L179-181 pack-help.toml assert, both converted). No gap.

**Run result:** `bash scripts/tests/test-init-project.sh` → EXIT 0, **Passed: 68 / Failed: 0** (matches the prompt's expected 68/68). Residual `.gemini` refs in the test: 0 (1 `GEMINI.md` KEEP).

## 4. LOCKSTEP COMPLETENESS — the key check (checklist 4) — PASS, no gap

**Method:** ran every per-check / init-project-coupled wired test; for each RED, ran it against the C2 BASE tree (`git archive HEAD` → `/tmp/c2-base-tree`) to classify C2-CAUSED vs intermediate-red.

| Test | post-C2 | at BASE | Classification |
|---|---|---|---|
| check-39 | GREEN | RED | C2 CLEARED it (correct restore) |
| check-41 | GREEN | RED | C2 CLEARED it (correct restore) + **C2-CAUSED break FIXED** (see below) |
| check-40, 42, 43, 16, 19 | GREEN | — | unaffected / GEMINI.md-only |
| check-18 | RED | RED | intermediate-red (C4: `GEMINI_INTRINSIC_H2S`) — NOT C2-caused |
| check-52 | RED | RED | intermediate-red (C4: `_CHECK_52_AGENT_DIRS`) — NOT C2-caused |
| check-55 | RED | RED | intermediate-red (C4: `_CHECK_55_PROJECT_AGENTS`) — NOT C2-caused |
| check-56 | RED | RED | intermediate-red (C4: `_CHECK_56_VERB_PARITY_SURFACES` `.gemini/...`) — NOT C2-caused |
| check-57 | RED | RED | intermediate-red (C4: `_CHECK_57` `.gemini/agents/...`) — NOT C2-caused |
| checks-36-37-38 | RED | RED | intermediate-red (its 40 internal asserts PASS; only the "validate-pack exits non-zero on HEAD" leg fails because Check 55 is red) — NOT C2-caused |

**The C2-CAUSED break (check-41) — fixed correctly:** check-41 carries a `required_subset` pin that included `project-template/.gemini/commands/pm-startup.toml`. C2 removes that row from `_CLIENT_INSTALLED_FILES`, so the OLD assertion goes stale. Proof: running the pre-C2 check-41 assertion against the post-C2 tree FAILS with `required subset missing from real inventory: ['project-template/.gemini/commands/pm-startup.toml']`. C2 correctly repins it to `project-template/.agents/mcp_config.json.example` (the canonical install-map spot-check row) → check-41 GREEN. This is a genuine in-commit lockstep fix per enumerate-encoding-surfaces.

**check-39 correctly NOT edited:** its `required_subset` (test L84-94) pins only stable docs + trinity files — none of the rows C2 removes — so C2's removals do not break it. It clears purely because the underlying validator no longer sees the stale `cmd_update` rows. Leaving the test untouched is correct.

**Plan-vs-reality reconciliation (non-defect):** the plan's §5 crosswalk (line 325) nominally assigns `test-validate-pack-check-{39,41,43,56,57}.sh` to **C4** ("repoint `.gemini` surface asserts"). The prompt's checklist-4 premise that §5.4 names these as C2 surfaces does not match the plan text I read — the plan puts the per-check *surface-assert* repoints in C4. BUT check-41 ALSO carries a `required_subset` **install-map row pin** coupled to C2's row removal — a coupling the plan's crosswalk did not break out. C2's baseline-delta gate correctly caught this and fixed check-41 in C2 (the only valid choice — deferring it to C4 would have left check-41 CI-RED on the C2 push). The remaining surface-assert repoints in 39/41/43/56/57 (the `.gemini/agents` `drop_surface` strings, the GEMINI.md-only refs) stay for C4. C2 touched exactly the C2-coupled assertion and no more. **No gap, no premature C4 touch.**

## 5. comm delta (checklist 5) — PASS

- C2 BASE (`/tmp/c2-base-tree`, HEAD a36bdd3): `validate-pack.py` → **FAILED — 70 issue(s)**, 70 FAIL-lines.
- post-C2 (working tree): `validate-pack.py` → **FAILED — 52 issue(s)**, 52 FAIL-lines.
- `comm -23 base after` (CLEARED) = **18 lines** = Check 39 ×9 + Check 41 ×9. The 9 paths per check: 4 C0-orphaned (`.claude/.codex × pack-help/pm-startup SKILL.md`) + 5 pre-existing gemini/mcp (`.gemini/.env.example`, `.gemini/settings.json`, `.gemini/commands/pack-help.toml`, `.gemini/commands/pm-startup.toml`, `.mcp.json.example`). Exactly matches plan C2 §line 124 ("Check 39 (−9), Check 41 (−9) → 18 install-map fail-lines").
- `comm -13 base after` (NEW) = **0 lines**. No new red. The added `.agents/mcp_config.json.example` row produces no fail-line (the `.example` source exists at HEAD).
- Net = 70 − 18 = **52**, matching the expected scalar. Both Check 39 and Check 41 reach 0 stale rows (verified GREEN above).

## 6. Boundary / scope (checklist 6) — PASS

`git diff --name-only` = `scripts/init-project.sh`, `scripts/tests/test-init-project.sh`, `scripts/tests/test-validate-pack-check-41.sh` — all under `scripts/`. No `project-template/` or `supporting-docs/` edits → `pack-only` claim is CI-Check-36-clean. The per-check test fix in `scripts/tests/` is pack-only and plan-sanctioned (enumerate-encoding-surfaces lockstep). No pack/project separation violation; no P-missed-7 leak.

## 7. Manifest (checklist 7) — correctly NOT flagged

`test-fixtures/manifest.txt` is NOT in the C2 diff. Per the prompt, the manifest regen is intentionally deferred to C6 (build.sh blocked by its own EB-21 bug until C6). NOT flagged.

---

## Findings

- **NIT-1 (observation, no action):** The S4 conversion is not a pure rename — it ADDS an existing-install classifier-aware copy branch (`if [[ "$CLASS" == existing-* ]]; then existing_classifier_copy ...`). This is design-sanctioned (§5.1 L211 "existing-install exception per §2.1") and uses only pre-existing symbols, bringing S4 into parity with S3/S5/S11. Sound; noted only because it exceeds a mechanical rename.
- **NIT-2 (process note, no action on C2):** The plan §5 crosswalk under-broke the check-41 coupling (it lumped check-41 into the C4 "surface-assert repoint" bucket without flagging its C2-coupled `required_subset` install-map pin). C2 handled it correctly via baseline-delta. Worth a one-line plan note for C4 so the C4 coder does not expect to "first-convert" check-41 (its install-map row is already done; only any residual `.gemini` surface-assert, if present, remains — none found here).

---

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|
| enumerate-encoding-surfaces + verify-full-ci-suite | Ran the per-check + init-project-coupled wired tests; classified each RED against the BASE tree. check-41 (the ONLY C2-CAUSED break: `required subset missing from real inventory: ['project-template/.gemini/commands/pm-startup.toml']` under the old assert) is FIXED in C2. check-18/52/55/56/57/checks-36-37-38 are RED at BASE too (`BASE check-18 EXIT=1 … BASE check-57 EXIT=1`) → intermediate-red C4 surfaces, NOT C2-caused. No C2-caused break left unfixed. | COMPLIANT |
| cross-cli-reference-normalization | New row uses `:generic` (audience-correct), NOT the C3-retired `gemini-env`; S3 docstring rewritten for Antigravity MCP config, not byte-copied. | COMPLIANT |
| verification = fail-LINE comm vs C2 BASE (70) | `comm -23` = 18 CLEARED (39×9+41×9); `comm -13` = 0 NEW; net 52. Base 70 from `git archive HEAD` tree. | COMPLIANT |
| pack-vs-project separation + P-missed-7 | `git diff --name-only` = 3 files all under `scripts/`; `grep -E "^project-template/|^supporting-docs/"` → none. | COMPLIANT |
| scope-deliverables-to-the-ask | Review scoped to the 7 checklist items; findings lead with the verdict + key-check result; no edge-case sprawl. | COMPLIANT |
| agents-never-commit / read-only | No state-changing git verb run. Base reconstructed via read-only `git archive HEAD` (no checkout/stash/worktree). Probe artifacts written to `/tmp` only; no working-tree file modified. | COMPLIANT |
| agent-output-requires-rules-applied-verification-block | This block. | COMPLIANT |

## Files read in full

- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md` (604 lines; "## Pack memory" L140-603 read in full — first rule "Agents never commit", last subsection "Project goals (v11)").
- `/Users/david/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_verify_full_ci_suite.md` (58 lines; opens `name: verify-full-ci-suite-not-just-validate-pack`, closes with the 2026-06-13 BD-214 C1 recurrence note).
- `/Users/david/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_pack_project_separation_of_concerns.md` (33 lines; closes with the BD-185 Code Red 2 worked example + cross-refs).
- `/Users/david/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_scope_deliverables_to_the_ask.md` (35 lines; closes "Sharpens feedback_no_solutions_in_agent_prompts …").
- `/Users/david/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_agent_output_rules_applied_block.md` (15 lines; closes with `Related: [[agent-prompt-enumerates-rules]], [[architect-planner-empirical-evidence]]`).
- `/Users/david/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_agents_read_rule_docs_in_full.md` (134 lines; closes with the BD-203 Commit-1 no-cache-substitution clause).
- Plan C2 § + §5 crosswalk: `/tmp/handoff-bd221-planner-final2/PLAN-BD-221-ANTIGRAVITY-COMPLETION-FINAL2.md` (C2 lines 121-126; crosswalk lines 303-339).
- Design §5.1: `/tmp/handoff-bd221-architect-v3/DESIGN-BD-221-ANTIGRAVITY-COMPLETION-v2.md` (§5.1 locus table lines 202-219).
