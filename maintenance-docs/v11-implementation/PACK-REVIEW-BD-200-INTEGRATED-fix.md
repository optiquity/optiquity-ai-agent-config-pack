# PACK-REVIEW — BD-200 — INTEGRATED fix F-1 (post-fix review)

**Role:** pack-reviewer (fresh, read-only, post-fix review of integrated-review finding F-1). **Branch:** `v11-dev`. **HEAD:** `291dd9e`. **Date:** 2026-06-04.
**Change under review (uncommitted working tree):** MODIFIED `project-template/scripts/activate-capability.sh` (the P0 pool-absent message in `stage_p0_preflight`) + regenerated `test-fixtures/manifest.txt`.
**Method:** independent re-measurement of the message truth-claim against `init-project.sh` source; whole-file boundary scan; full `validate-pack.py`; `test-activate-capability.sh` re-run; manifest regen + byte-compare. No prior `PACK-REVIEW`/`IMPL` report read (independence preserved).

---

## OVERALL VERDICT — **CLEAN**

The F-1 fix is correct, truthful, boundary-clean, regression-free, and scoped exactly to the message + the manifest it moves. The new P0 pool-absent message no longer advises `scripts/init-project.sh --update` as a way to materialize the pool (the prior defect). It now states the truthful path — the pool is materialized only at fresh project setup — and is explicitly honest that no in-place back-fill exists yet, without fabricating a working recovery command. Every VERIFY item passes against my own measurement. No findings.

---

## VERIFY results (each independently measured)

### 1. Message accuracy — **PASS**
The new message (`activate-capability.sh:150-157`) reads:

```
say "STOP — capability pool pack-capability-pool/ is absent."
say "The pool is a tracked directory materialized only at fresh"
say "project setup, by scripts/init-project.sh with a version that"
say "supports capability activation. If it is missing, this project"
say "was set up before that support existed."
say "No in-place back-fill into an existing project exists yet:"
say "scripts/init-project.sh --update does NOT create the pool. The"
say "only path that populates it today is a fresh project setup."
```

Independently confirmed the underlying truth it must reflect:
- `stage_s5b_populate_pool` is invoked from exactly ONE site: `scripts/init-project.sh:1547`, inside `main()` → `run_stages` (the fresh-install path). Nearest enclosing function def before 1547 is `main()` at 1467.
- `cmd_update()` does NOT call S5b nor `run_stages`: `awk '/^cmd_update\(\)/,/^}/' | grep -c "s5b\|populate_pool"` → `0`; `... | grep -n "run_stages"` → no hits; `... | grep -E 'pack-capability-pool|populate_pool|s5b'` → NONE.
- The gap is documented as deliberate at `init-project.sh:574` — "FRESH-INSTALL only — NO `pack update` refresh / wipe-repopulate (that is BD-202)."
- No other production entrypoint creates the pool (only test-fixture `mkdir` hits in `test-detect.sh` / `test-activate-capability.sh`).

So `--update` genuinely does not populate the pool, and the message correctly says so. The message states the truthful path (fresh project setup), is honest that no in-place back-fill exists yet, and fabricates no working recovery command. The exact defect R3/F-1 flagged (advising a no-op `--update` flag) is gone.

### 2. Boundary — **PASS**
Message arm (lines 148-159) scanned for `$PACK | pack-ops | maintenance-docs | BD-[0-9] | BD-202 | pack-architect/coder/reviewer | from the pack | .pack-`: **CLEAN**. Whole-file scan: **zero pack-self tokens**. `pack-capability-pool/`, `init-project.sh`, and `--update` are client-installed artifact/verb names, not pack-self tokens. No `$PACK`; no BD-202 reference. Check 43 (158 files, zero pack-internal bare cross-refs) and Check 37 (zero deny-list contamination) both OK.

### 3. No regression — **PASS**
- Exit code unchanged: `exit "$EXIT_NO_POOL"` retained; `EXIT_NO_POOL=22` at line 59.
- `bash -n project-template/scripts/activate-capability.sh` → PASS.
- `scripts/tests/test-activate-capability.sh` re-run: **27 passed, 0 failed** — including the fresh-clone no-`$PACK` activation walk (P0/P5/P8, pyproject + server/ + 4 `*-python.sh` re-materialized, prompt gitignored, pack-self-clean prompt) and the `x-`-preserve-on-activate guard.
- No test asserts the pool-absent message text, so the wording change creates no stale assertion (verified: no `--update`/pool-absent string assertions in the harness; the old wording is referenced only in untracked maintenance-docs reports that legitimately quote the prior defect).

### 4. BD-202 boundary — **PASS**
Diff is message-only. `git diff` on the script adds 7 / removes 4 lines, all inside the existing `say` block; the only `+` line matching `cmd_update|populate|copy|cp|mkdir|rm` is a `say` prose line (`"only path that populates it today is a fresh project setup."`), not logic. `cmd_update()` gains zero pool-population logic. No update-path / wipe-repopulate code added. BD-202 fence held.

### 5. Guards + manifest — **PASS**
- `python3 scripts/validate-pack.py` → **PASSED — all checks clean** (exit 0). Check 48 emits 14 advisory WARNs (JC-5 accurate-history citations; advisory only, not a gate failure, unrelated to this fix).
- Check 43 OK; Check 37 OK; Check 22 ran clean (verb resolution intact); Check 47 frozen 2-tuple **`['scripts/lib/detect.sh', 'scripts/pack-help.sh']` UNMOVED** (install-map subset == sanctioned set).
- Manifest reproducible: `bash test-fixtures/build.sh --all --clean` regenerates a manifest **byte-identical** to the working-tree manifest under review. Delta vs committed HEAD is exactly the three v11-* rows (`v11-realistic-ot`, `v11-flat-file`, `v11-tracker-on`); v10-* and `existing-project-mid-dev` rows unchanged — correct, since the message edit ships into v11 fixtures via S5 and nowhere else.

### 6. Scope — **PASS**
Tracked changes are exactly `project-template/scripts/activate-capability.sh` (message) + `test-fixtures/manifest.txt`. No C1–C4 file altered. (The untracked `IMPL-*` / `PACK-REVIEW-*` docs in `maintenance-docs/` are prior reports, not part of the F-1 fix diff, and were not read for independence.)

---

## Findings

None. The fix is CLEAN.

---

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **agents-read-rule-docs-in-full (+ no-derivation clause)** | Read DIRECTLY + IN FULL via Read tool (per-file proof): `CLAUDE.md` (541 lines; first line `# CLAUDE.md — AI Agent Config Pack (Pack Repo)`, last line `- OT-style v10→v11 migration is automated...`); `pack-ops/PACK-AGENTS.md` (226 lines; last line `Always run \`git add -A && git status\`...`); `pack-ops/PACK-CHAT.md` (310 lines; last line `...not a hard-enforced step sequence.`); `project-template/CLAUDE.md` (456 lines; last line `...New projects start with this H2 empty. The marker is preserved...`); `PACK-REVIEW-BD-200-INTEGRATED.md` (97 lines; F-1 detail §38-67); `PLAN-BD-200.md` (235 lines; §2 T3 lines 59-67 + §6 lines 156-171); BD-200 entry read DIRECTLY in `pack-ops/BACKLOG.md:3273-3306`; BD-202 entry `pack-ops/BACKLOG.md:3310-3326` (boundary: pool-on-update = BD-202, line 3317 AC-1, 3318 scope); curated memory each single full Read: `feedback_agents_read_rule_docs_in_full` (97 lines), `feedback_agent_output_rules_applied_block` (15 lines), `feedback_bd_pack_only_operational_rule` (35 lines), `feedback_manifest_regen_on_v11_surface` (16 lines), `feedback_client_ref_delete_or_forward_look` (41 lines). No named doc derived; all read directly. | **COMPLIANT** |
| **boundary / no-pack-self-in-project** | Message arm + whole-file scan for `$PACK\|pack-ops\|maintenance-docs\|BD-[0-9]\|BD-202\|pack-* agents\|from the pack\|.pack-` → CLEAN / zero tokens (quoted in VERIFY 2). Check 43 OK (158 files), Check 37 OK (zero contamination). | **COMPLIANT** |
| **empirical verification** | Every verdict backed by a command + quoted output: S5b-only-at-1547 grep; `cmd_update` grep-count 0 for s5b/populate_pool/run_stages; `init-project.sh:574` BD-202 deferral comment; `EXIT_NO_POOL=22` grep; `bash -n` PASS; test tally 27/0; validate-pack PASSED exit 0; Check 47 set-equality printed; manifest byte-identical diff. | **COMPLIANT** |
| **BD-202 boundary** | Diff message-only (7+/4−, all `say` lines); zero `cmd_update`/copy/mkdir/populate logic added (the one matching `+` line is `say` prose); `cmd_update` pool-population grep → NONE. | **COMPLIANT** |
| **ci-guard-measure-then-bound** | Guards measured green against the fixed tree (not asserted): validate-pack full run PASSED; Check 43/37/22 OK; Check 47 frozen 2-tuple `['scripts/lib/detect.sh','scripts/pack-help.sh']` UNMOVED; manifest regen byte-identical, only v11-* rows moved. | **COMPLIANT** |
| **review-cycle-position-checkpoint** | This is the post-fix review of F-1. Verdict CLEAN ⇒ proceed to commit (no further fix/re-review cycle needed). | **COMPLIANT** |
| **scope-deliverables-to-the-ask** | Reviewed exactly the F-1 fix (message + manifest); led with verdict; no sprawl; one Findings section stating None. | **COMPLIANT** |
| **rules-applied-verification-block** | This table — per-rule name + measured/quoted evidence + terminal verdict; no empty-evidence rows; READ-IN-FULL row carries per-file proof (line count + first/last line). | **COMPLIANT** |
| **agents-never-commit** | Read-only verbs only (`git status`, `git diff`, `git rev-parse`, `git branch`, `grep`, `awk`, `sed`, `bash -n`, test run, `validate-pack.py`, `build.sh`). The manifest regen + byte-compare wrote only to `/tmp` and reproduced the existing working-tree manifest (no tracked-content change beyond what was already staged for review). NO `git add/commit/push/tag`. | **COMPLIANT** |
