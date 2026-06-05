# PACK-REVIEW — BD-200 C2 — review-2 (post-fix)

**Role:** pack-reviewer (fresh, read-only). **Branch:** `v11-dev`. **HEAD:** `98b6a9b10e9d9e8b114995e3d416e708230c5bde`. **Date:** 2026-06-04.
**Cycle position:** review-2 of the bounded cycle (coder → review-1 → fix-1 → **review-2 ← here**; pair 1 of max 2). Per `review-cycle-position-checkpoint`: CLEAN ⇒ commit; findings ⇒ fix-2 → review-3 (final).
**Scope reviewed:** the full C2 working-tree change (uncommitted): `scripts/init-project.sh`, `scripts/lib/detect.sh`, `scripts/test-detect.sh`, `test-fixtures/manifest.txt`. Prior `PACK-REVIEW-*`/`IMPL-*` reports NOT read (bias-avoidance per prompt + `no-prior-reviews-to-reviewer`).

---

## OVERALL VERDICT: **CLEAN (commit-ready)**

The fix-1 targets (S-1: the four tree-scanning marker detectors in `detect.sh` exclude `pack-capability-pool/`; N-1: `detect_source_files()` carries the same exclusion; a `test-detect.sh` assertion proves the markers don't mis-fire on the pool) are each **correctly and completely** done. The detection-completeness re-verification — the priority of this review — found **zero** tree-scanning detector that could see the pool left unexcluded. Whole-C2 commit-readiness re-confirmed independently. BD-202 boundary intact. `validate-pack.py` PASSED. No findings of any severity.

---

## Fix-target verification (each independently measured)

### S-1 — the four tree-scanning marker detectors in `detect.sh` exclude the pool — **COMPLETE**

All four `find "$target"` walks in `scripts/lib/detect.sh` carry `-o -path '*/pack-capability-pool/*'` (in the `\( ... \) -prune` group) or `-not -path "*/pack-capability-pool/*"`:
- `python_data_marker_detected()` marker (b) — `find "$target" -name "*.py" ... -not -path "*/pack-capability-pool/*"` (~line 410).
- `protobuf_marker_detected()` marker (a) — pool added to the `-prune` group (~line 503).
- `swiftdata_marker_detected()` — pool added to the `-prune` group (~line 618).
- `python_observability_marker_detected()` — pool added to the `-prune` group (~line 779).

`grep -nE '\bfind "\$target"' scripts/lib/detect.sh` returns exactly these 4 sites; each carries the exclusion. The three LOAD-BEARING comments (protobuf / python-data / observability) and the one defensive note (swiftdata: pool ships `*-swift.sh`, may carry `.swift`) are accurate.

### N-1 — `detect_source_files()` (init-project.sh) carries the exclusion — **COMPLETE**

`detect_source_files()` both finds (`*.swift`, `*.py`) carry `-not -path '*/pack-capability-pool/*'` (lines 197–198). The accompanying comment correctly labels it parity/forward-safety (the helper runs at preview time, before S5b populates the pool).

### Test assertion proving no mis-fire — **COMPLETE + strong**

`scripts/test-detect.sh` adds a `pool-exclusion-swift-only` fixture whose ONLY proto/python content lives inside `pack-capability-pool/`, asserting `protobuf-marker: no`, `python-data: no`, `python-observability-marker: no`, plus two controls: live-tree `import SwiftData` still detected, and a `pool-exclusion-live-proto` fixture proving a REAL live-tree `.proto` still fires `yes` with the pool present. `bash scripts/test-detect.sh` → **100 passed, 0 failed**.

---

## VERIFY items (each with own measurement)

**1. Fix correctness + COMPLETENESS (detection-completeness hunt — the priority).**
Independently enumerated EVERY tree-scanning walk across both files:
- `detect.sh`: exactly 4 `find "$target"` walks (the 4 markers) — ALL excluded. Non-tree-scanners confirmed out of scope: `detect_installed_capabilities()` reads the trinity `Active skills:` line (no find/grep over the tree); `detect_x_files()`/`detect_improperly_added_files()`/`detect_pack_surface()` scan FIXED paths (`.claude/agents`, `x-*` globs in CLI dirs, `pack-ops/BACKLOG.md`) that the root-level pool can never inhabit — they cannot mis-fire on the pool.
- `init-project.sh`: `detect_language_markers()` has 7 tree walks (swift, python, kotlin, typescript, proto, weak-swift, weak-python) + `detect_source_files()` has 2 = 9 `-path '*/pack-capability-pool/*'` predicates, ALL present (verified at lines 143–198). The proto walk is keyed on `$target/proto` (live-tree only) with a defensive exclusion — correct.

No tree-scanning detector that could see the pool is left unexcluded.

**2. A/B re-proof (load-bearing, not cosmetic).** On a freshly-installed Swift-only `/tmp` scratch tree (provisioned via `git init` + `init-project.sh`, cleaned up after, per `test-infra-self-provisioned`):
- Pool populated: 14 masters copied, 0 absent (incl. GAP-A root files `pyproject.toml`, `pyrightconfig.json`, `server/`, `proto/`).
- **WITH** C2's exclusion (current `detect.sh`): `protobuf-marker: no`, `python-data: no`, `python-observability-marker: no` — correct for a Swift-only project.
- **WITHOUT** the exclusion (committed pre-C2 `detect.sh` via `git show HEAD:scripts/lib/detect.sh`): `protobuf-marker: **yes**` mis-fires off the pool's `proto/*.proto` masters. After scaling the pool to ≥5 `.py` + an `import opentelemetry`: `python-data: **yes**` and `python-observability-marker: **yes**` mis-fire. → All three exclusions are **load-bearing** (the protobuf one off the real installed pool; python ones at realistic pool scale). swiftdata is correctly defensive (no `.swift` masters in the pool today).

**3. No regression.** A real Python-source live tree (≥5 `.py` + `opentelemetry`/`sqlalchemy`) WITH the pool present detects `python-data: yes` + `python-observability-marker: yes`. The `pool-exclusion-live-proto` test fixture proves a genuine live-tree `.proto` + pool both present still fires `protobuf-marker: yes`. The exclusion narrows strictly to the pool; genuine live-tree markers are untouched.

**4. Tests.** `scripts/test-detect.sh` → 100 passed / 0 failed (incl. the new pool block). `scripts/tests/test-init-project.sh` → 67 passed / 0 failed. (Note: the init-project test lives at `scripts/tests/test-init-project.sh`, not `scripts/test-init-project.sh`.) Both green.

**5. Whole-C2 commit-readiness.**
- **Pool completeness incl. GAP-A root files:** `find pack-capability-pool -type f` on the Swift-only install lists `pyproject.toml`, `pyrightconfig.json`, `server/...`, `proto/...`, and all conditional `*-python.sh`/`*-swift.sh`/`proto-gen.sh`/`validate-proto.sh`. Root files (no live-tree install path) are present — GAP-A corrected.
- **S9 live-tree removal preserved + pool survives:** on the Swift-only install, live `pyproject.toml`/`pyrightconfig.json`/`server`/`proto`/`*-python.sh` were removed by S9; `pack-capability-pool/` (incl. its python files) survived. The `is_pool_path()` defensive guard is wired into every S9 removal loop.
- **Check-41 NOTE:** present + correct in the `_CLIENT_INSTALLED_FILES` Bulk-copied block (`<conditional masters> ... -> pack-capability-pool/* [stage:S5b]`), with the explicit "NOT a `_SANCTIONED_PACK_SIDE_SHIPPED` entry; Check 47 frozen 2-tuple UNMOVED" disclosure and the `capability_files()` single-source pointer.
- **`_SANCTIONED_PACK_SIDE_SHIPPED` frozen 2-tuple UNMOVED:** `("scripts/lib/detect.sh", "scripts/pack-help.sh")` — unchanged.
- **Manifest = exactly the expected v11-* rows, reproducible:** staged diff moves only `v11-realistic-ot`/`v11-flat-file`/`v11-tracker-on` SHAs (S5b adds the pool to v11 fixtures); v10-* + `existing-project-mid-dev` rows unchanged. `bash test-fixtures/build.sh --all --clean` reproduces a byte-identical manifest.
- **F1 comment correct:** `detect.sh:302` now reads `capability-tables.sh::capability_skills()` (was `scripts/add-capability.sh::...`); resolves to the C1-landed `project-template/scripts/capability-tables.sh` (defines `capability_skills()` at line 20). C1 is committed at HEAD `98b6a9b`.
- **`project-template/.gitignore` has NO pool line:** TRACKED invariant preserved (grep clean).
- **Scope = exactly the 4 expected files:** `git status --short` (tracked) = `scripts/init-project.sh`, `scripts/lib/detect.sh`, `scripts/test-detect.sh`, `test-fixtures/manifest.txt`. (The untracked `IMPL-*`/`PACK-REVIEW-*` docs are agent reports, not C2 scope.)

**6. BD-202 boundary.** `stage_s5b_populate_pool` is registered ONLY in `main()` (line 1547, FRESH-INSTALL). `cmd_update()` contains NO pool/S5b reference. The C2 diff contains NO `cmd_update`/`_cmd_update_iter_dir`/`customization-preserve`/`three-way`/wipe-repopulate/delete-propagation/refresh/reconcile logic. The S5b docstring explicitly fences "FRESH-INSTALL only — NO `pack update` refresh ... (that is BD-202)." Boundary intact.

**7. Guards.** `python3 scripts/validate-pack.py` → **PASSED — all checks clean** (Check 41 green with the pool NOTE; Check 47 frozen 2-tuple intact; Check 48 WARNs are pre-existing advisory-only BACKLOG/CHANGELOG history citations, unrelated to C2, exit code unaffected). `bash -n` clean on all three edited scripts.

---

## Findings

None. No BLOCKER / MUST / SHOULD / NIT.

(Observation, not a finding: the protobuf marker `no` on one ad-hoc python+proto install was traced to pre-existing init-project language classification removing the live `proto/` at S9 — independent of C2, which only adds pool exclusions. The `pool-exclusion-live-proto` test fixture confirms genuine live-tree proto detection works with the pool present. No defect.)

---

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **READ-IN-FULL set** (agents-read-rule-docs-in-full) | Read IN FULL via Read tool: `CLAUDE.md` incl. `## Pack memory` (541 lines; first `# CLAUDE.md — AI Agent Config Pack (Pack Repo)` … last `…OT itself is read-only for testing…`); `pack-ops/PACK-AGENTS.md` (226 lines; first `# PACK-AGENTS.md` … last `…confirm staged files before any commit.`); `pack-ops/PACK-CHAT.md` (310 lines; first `# PACK-CHAT.md` … last `…not a hard-enforced step sequence.`); `project-template/CLAUDE.md` (456 lines; first `# CLAUDE.md` … last `…New projects start with this H2 empty. The marker is preserved…`); `PLAN-BD-200.md` (235 lines, full — §2 T4 + §5 + EEBs + RAV); `ARCHITECTURE-BD-200-ADVERSARIAL-REVIEW.md` (441 lines, full — both pages 1-336 + 337-441; §3.2/§3.4/§4.1/§4.5/§10.6 confirmed); BD-200 (BACKLOG 3273-3306) + BD-202 (3310-3327) full; curated memory in full: `feedback_agents_read_rule_docs_in_full.md` (72 ln), `feedback_agent_output_rules_applied_block.md` (15 ln), `feedback_manifest_regen_on_v11_surface.md` (16 ln), `feedback_ci_guard_design_measure_then_bound.md` (15 ln), `feedback_bd_pack_only_operational_rule.md` (35 ln), `feedback_review_cycle_position_checkpoint.md` (57 ln). | **COMPLIANT** |
| **enumerate-encoding-surfaces** (reviewer — completeness hunt) | Independently enumerated ALL tree-scanning detectors: `detect.sh` 4 `find "$target"` walks (all excluded) + non-scanners (`detect_installed_capabilities`/`detect_x_files`/`detect_improperly_added_files`/`detect_pack_surface`) confirmed out of scope (fixed-path, not recursive); `init-project.sh` 9 predicates across `detect_language_markers()` (7) + `detect_source_files()` (2), all present. No unexcluded pool-visible scanner. | **COMPLIANT** |
| **empirical verification** | Every verdict backed by a command + quoted output: `git show HEAD:scripts/lib/detect.sh` A/B (`protobuf-marker: yes`→`no`; scaled-pool `python-data: yes`→`no`, `observability: yes`→`no`); fresh Swift-only `/tmp` install (`14 master(s) copied`); `find pack-capability-pool -type f` (GAP-A root files present); S9 removal + pool survival; `build.sh --all --clean` reproducibility; `validate-pack.py` PASSED. Scratch repos provisioned + cleaned per `test-infra-self-provisioned`. | **COMPLIANT** |
| **ci-guard-measure-then-bound** | Check 41 measured green with the pool NOTE (sources all `project-template/`); Check 47 frozen 2-tuple measured UNMOVED; no allowlist growth; `.gitignore` TRACKED invariant measured (no pool line). | **COMPLIANT** |
| **BD-202 boundary** | Measured: S5b only in `main()` (line 1547); `cmd_update` has no pool/S5b ref; C2 diff has zero update-path tokens (cmd_update/customization-preserve/three-way/wipe-repopulate/delete-propagation/refresh/reconcile). No leak. | **COMPLIANT** |
| **review-cycle-position-checkpoint** | This is review-2 (post-fix, pair 1 of max 2); verdict CLEAN ⇒ next mandated step is commit (not a self-review, not a third reviewer). Stated at the top of the report. Reviewer read the actual working-tree diff independently, not a prior design/review. | **COMPLIANT** |
| **scope-deliverables-to-the-ask** | Reviewed exactly C2's 4 files; led with the verdict; fix-targets + 7 VERIFY items + findings; no edge-case/coverage sprawl; the one non-finding observation explicitly fenced as not-a-finding. | **COMPLIANT** |
| **rules-applied-verification-block** | This table — per-rule name + quoted/measured evidence + terminal verdict; no empty-evidence rows; READ-IN-FULL row with per-file proof (line counts + first/last lines). | **COMPLIANT** |
| **agents-never-commit** | Only read-only verbs used (`git status`/`diff`/`show`/`rev-parse`/`branch`/`log`, `grep`, `sed`, `find`, `bash -n`, test scripts, `validate-pack.py`, `build.sh`) + `/tmp` scratch provisioning + this single report Write. NO `git add`/`commit`/`push`/`tag`; nothing staged (`git diff --cached` empty). | **COMPLIANT** |

**End of review — CLEAN (commit-ready).**
