# PACK-REVIEW — BD-200 — Commit C3 — review-2 (post-fix)

**Role:** pack-reviewer (fresh, read-only, independent). **Branch:** `v11-dev`.
**HEAD at review:** `3bc96faf3f4bbed667cbd567b2c5a1f0132422ad` (C1 + C2 already committed; C3 is the uncommitted working-tree change). **Date:** 2026-06-04.
**Cycle position (review-cycle-position-checkpoint):** coder → review-1 → fix-1 → **review-2 (this pass; pair 1 of max 2)**. CLEAN ⇒ commit; findings ⇒ fix-2 → review-3 (final).
**Scope reviewed:** the C3 working-tree change ONLY — NEW `project-template/scripts/activate-capability.sh`; NEW `scripts/tests/test-activate-capability.sh`; MODIFIED `project-template/docs/pack/HELP-FRAGMENT.md`, `project-template/docs/pack/PM-CHAT.md`, `supporting-docs/INSTALL-PROCEDURES.md`; regenerated `test-fixtures/manifest.txt`. (Prior `PACK-REVIEW-*`/`IMPL-*` reports NOT read — bias guard.)

---

## Overall verdict — **CLEAN (commit-ready)**

Both fix-targets are genuinely resolved and independently re-proven. The whole C3 change is commit-ready: `validate-pack.py` exits 0; the named per-checks (22/37/41/43/47) are green and measured; the fresh-clone no-`$PACK` activation walk re-materializes the Python set from the tracked pool; the `x-`-overwrite guard preserves a project-authored file; the pool stays TRACKED; BD-202 boundary is intact (zero update-path logic); the manifest is reproducible and moves exactly the v11-* rows; scope is exactly the expected files; C1/C2 files are untouched. No BLOCKER / MUST / SHOULD / NIT findings.

---

## Fix-target verification

### F1 (MUST) — `.pack-activate-capability-prompt.md` gitignored — **RESOLVED**

`ensure_prompt_gitignored()` (`project-template/scripts/activate-capability.sh:79-86`) is `$PACK`-free, appends `$PROMPT_FILE` to `$TARGET/.gitignore` (creating it via `>>` if absent), and de-dupes via `grep -Fxq` before appending. It is invoked from `write_prompt_file()` (line 391) BEFORE the prompt is written (line 392), so both the normal P8 path and the P2 `already-active` early-exit path (line 288) ensure the ignore line. The `nothing-to-activate` exit (line 283) writes no prompt, so no ignore is needed there — consistent.

Independently re-proven on a self-provisioned `/tmp` Swift-only install → no-`$PACK` clone (provisioned + cleaned up per `test-infra-self-provisioned`):

- `git check-ignore .pack-activate-capability-prompt.md` → matched (IGNORED).
- `git add -A` after activation → prompt artifact NOT staged (only the re-materialized Python files + `.gitignore` staged).
- `.gitignore` prompt-line count after 3 activation runs → `1` (dedupe holds).
- `.gitignore`-absent path: deleted `.gitignore`, committed, ran activation → `.gitignore` created with the line, artifact IGNORED via the freshly-created file.
- gitignore-ensure is `$PACK`-free (verified `ensure_prompt_gitignored` body).

The in-repo harness re-asserts the same: `scripts/tests/test-activate-capability.sh:167-180` (check-ignore IGNORED + second-run dedupe count=1) — both PASS.

### F2 (NIT) — `is_x_prefixed` defined before first use — **RESOLVED**

`is_x_prefixed()` defined at `activate-capability.sh:72`; first uses at line 270 (P2 delta pass-through) and line 316 (P5 overwrite guard). Definition precedes both uses. `bash -n` clean. The fresh-clone walk + `x-`-preserve test both pass (see VERIFY 2/4).

---

## VERIFY results (each independently measured)

1. **F1 re-prove (independent /tmp scratch)** — PASS. See F1 above: check-ignore IGNORED; `git add -A` does not stage the prompt; dedupe (count=1 across runs); `.gitignore`-absent create path works; gitignore-ensure is `$PACK`-free.
2. **F2 ordering + syntax** — PASS. Def line 72 < use lines 270/316; `bash -n` clean on all three scripts (`activate-capability.sh`, `test-activate-capability.sh`, `capability-tables.sh`); fresh-clone walk + `x-`-preserve pass.
3. **Pool still TRACKED** — PASS. `project-template/.gitignore` is NOT in the C3 diff and carries no `pack-capability-pool` line. The script's only `>> .gitignore` write is `$PROMPT_FILE` (line 84); all `pack-capability-pool/` mentions in the script are pool-PATH references (the tracked dir it reads), never an ignore line. Pool stays tracked.
4. **Whole-C3 commit-readiness** — PASS:
   - `activate-capability.sh` carries ZERO pack-self tokens and no `$PACK` (grep clean).
   - Fresh-clone no-`$PACK` activation walk (run by reviewer): P0 passes with no `$PACK`; P5 re-materializes `pyproject.toml` + `pyrightconfig.json` + `server/` + the four `*-python.sh` FROM `pack-capability-pool/`; re-materialized scripts are executable; P8 emits a Procedure-6 prompt free of `$PACK`/"from the pack".
   - `x-`-on-overwrite guard (run by reviewer via harness Group 2): a project-authored `x-`-basename dest is preserved byte-for-byte + warned ("preserving project-authored file"); a non-`x-` resolved file in the same run IS written. Guard is path-faithful.
   - HELP-FRAGMENT has the `activate-capability.sh` verb row (`add-capability.sh` verb removed); PM-CHAT names the client `scripts/activate-capability.sh`, no "from the pack"; INSTALL-PROCEDURES R3 applied (8a: `add-capability.sh` dropped from the deletions bullet; 8b: `activate-capability.sh` added to the overwrites bullet). R3 backing re-measured: `add-capability.sh` has ZERO `rm`/`unlink`/`git rm`; `init-project.sh` (6 rm sites) + active `migrate-v10-to-v11.sh` remain the genuine deleters; `activate-capability.sh` P5 is a `cp`/`cp -R` overwrite site with the `x-` guard. Edits are factually accurate vs. measured behavior; the script basenames are client-installed verbs, not pack-self tokens.
   - Check 22 resolves (project-template: 2 verbs all present in fragment; `activate-capability.sh` in PM-CHAT + HELP-FRAGMENT + on disk).
   - Check 43 OK (158 files; zero pack-internal bare cross-refs); Check 37 OK (170 files; zero deny-list contamination); Check 41 OK (37 entries resolve, 0 drift); Check 47 frozen 2-tuple `{scripts/lib/detect.sh, scripts/pack-help.sh}` unmoved.
   - Harness green: 27/27 PASS (Group 1 fresh-clone walk; Group 2 `x-`-preserve). `scripts/tests/test-activate-capability.sh` is pack-side test infra, NOT under `project-template/`, not a fixture row → does not itself move the manifest.
   - Manifest = exactly the v11-* rows moved (v10-minimal / v10-realistic-ot / existing-project-mid-dev unchanged — confirms R4); reproducible: regen via `bash test-fixtures/build.sh --all --clean` produced byte-identical output to the working-tree manifest.
   - Scope = exactly `activate-capability.sh` (new) + `test-activate-capability.sh` (new) + `manifest.txt` (regen) + the 3 doc edits. C1/C2 files (`capability-tables.sh`, `add-capability.sh`, `init-project.sh`) NOT in the C3 working-tree change.
   - BD-202 boundary intact: zero `cmd_update`/`pack update`/`wipe`/`repopulate`/`refresh`/`three_way`/`customization_preserve`/`populate_pool` logic in `activate-capability.sh` — it reads the pool at activation time only, no update-path engine.
   - No C1/C2 regression: existing `scripts/tests/test-add-capability.sh` green (19/19 PASS).
5. **Guards** — `python3 scripts/validate-pack.py` exit code 0 — PASSED. (Check 48 emits 14 advisory-only removed-doc WARNs in `pack-ops/BACKLOG.md` + `pack-ops/CHANGELOG.md` — pre-existing, JC-5 accurate-history, NOT a gate failure, unrelated to C3.)

---

## Findings

None. No BLOCKER / MUST / SHOULD / NIT.

---

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| READ-IN-FULL set | Read IN FULL via Read tool: `CLAUDE.md` (541 lines, incl. `## Pack memory`); `pack-ops/PACK-AGENTS.md` (226 lines); `pack-ops/PACK-CHAT.md` (310 lines); `project-template/CLAUDE.md` (456 lines); `maintenance-docs/v11-implementation/PLAN-BD-200.md` (235 lines, incl. §2 T3/T6, §3, §5, §6, R3/R5); `ARCHITECTURE-BD-200-ADVERSARIAL-REVIEW.md` (441 lines, two pages 1-336 + 337-441 — incl. §3.1/§3.7/§4.2/§4.4/§4.6, GAP-C, EEB-GITIGNORE, §10 BD-202 boundary); BD-200 entry `pack-ops/BACKLOG.md:3273-3305` + BD-202 entry `:3310-3323`; curated memory files (each via Read, in full): `feedback_agents_read_rule_docs_in_full.md` (72 lines), `feedback_agent_output_rules_applied_block.md` (15 lines), `feedback_manifest_regen_on_v11_surface.md` (16 lines), `feedback_bd_pack_only_operational_rule.md` (35 lines), `feedback_pack_project_separation_of_concerns.md` (33 lines), `feedback_client_ref_delete_or_forward_look.md` (41 lines), `feedback_review_cycle_position_checkpoint.md` (57 lines). Reviewed-target files read in full: `activate-capability.sh` (424 lines), `test-activate-capability.sh` (264 lines), and the diffs of the 3 modified docs + manifest. | COMPLIANT |
| boundary / no-pack-self-in-project | `grep -nE 'maintenance-docs/|pack-ops/|pack-architect|pack-planner|pack-coder|pack-reviewer|BD-[0-9]|from the pack|.pack-add-capability' project-template/scripts/activate-capability.sh` → NONE; `grep -n PACK` → NONE; the 3 modified docs' added lines → clean (no pack-self tokens). | COMPLIANT |
| enumerate-encoding-surfaces | F1 gitignore-encoding partner present (`ensure_prompt_gitignored`) + harness assertion present (`test-activate-capability.sh:167-180`); script + harness + behavior consistent (27/27 PASS); pool-tracked invariant intact (`.gitignore` not edited, no pool line); INSTALL-PROCEDURES prose-encoding lock-step with script behavior (8a/8b accurate vs measured `rm`/`cp`). | COMPLIANT |
| client-ref delete-or-forward-look | HELP-FRAGMENT verb flipped `add-capability.sh` → `activate-capability.sh` (a real client-installed verb, on disk); PM-CHAT names client `scripts/activate-capability.sh` (removed "from the pack"); INSTALL-PROCEDURES script basenames are client-installed verbs. No client-shipped ref to a pack-only path. | COMPLIANT |
| empirical verification | Every verdict backed by a command + quoted output: ran `bash -n` x3; ran the harness (27/27); ran an independent /tmp scratch F1 walk (check-ignore IGNORED, `git add -A` non-staging, dedupe count=1, absent-path create); ran `validate-pack.py` (exit 0) + per-check grep (22/37/41/43/47); regenerated manifest (byte-identical); grepped BD-202 tokens (NONE); ran existing add-cap test (19/19). | COMPLIANT |
| ci-guard-measure-then-bound | Checks 22/37/41/43 measured green from a fresh `validate-pack.py` run; Check 47 frozen 2-tuple measured unmoved (`scripts/validate-pack.py:4158-4161`); no allowlist widening; manifest bounded to the v11-* rows that legitimately moved (v10/existing unchanged). | COMPLIANT |
| BD-202 boundary | `grep -nE 'cmd_update|pack update|wipe|repopulate|refresh|three_way|customization_preserve|stage_s5b|populate_pool' project-template/scripts/activate-capability.sh` → NONE. Script reads the pool at activation time only; no update-propagation engine (correct per ARCH §10.6 INDEPENDENT partition + BD-200 acceptance excluding cross-version refresh). | COMPLIANT |
| review-cycle-position-checkpoint | Stated position at top: coder → review-1 → fix-1 → review-2 (pair 1 of max 2); CLEAN ⇒ commit. This is review-2; verdict CLEAN. | COMPLIANT |
| scope-deliverables-to-the-ask | Reviewed exactly the C3 working-tree change; led with verdict; no sprawl; no invented findings; out-of-C3 items (Check 48 advisory WARNs) noted as pre-existing/unrelated, not flagged as findings. | COMPLIANT |
| rules-applied-verification-block | This table — per-rule name + measured/quoted evidence + terminal conclusion; no empty-evidence rows; READ-IN-FULL row with per-file line-count proof. | COMPLIANT |
| agents-never-commit | Only read-only verbs used (`git rev-parse`, `git branch`, `git status`, `git diff`, `grep`, `sed`, `cat`, `bash -n`, harness runs) + self-provisioned `/tmp` scratch repos (`git init`/`clone`/`add`/`commit` on disposable scratch trees ONLY, cleaned up) + this single report Write at the caller-specified path. NO `git add/commit/push/tag` on the pack repo. | COMPLIANT |
