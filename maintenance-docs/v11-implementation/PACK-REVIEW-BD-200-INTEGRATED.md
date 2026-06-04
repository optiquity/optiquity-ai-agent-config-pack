# PACK-REVIEW — BD-200 — INTEGRATED end-to-end review (C1–C4 as ONE deliverable)

**Role:** pack-reviewer (fresh, read-only, INTEGRATED close-out audit). **Branch:** `v11-dev`. **HEAD:** `291dd9e`.
**Diff under review:** `git diff 356afca..291dd9e` (4 commits: C1 `98b6a9b` single-source tables; C2 `3bc96fa` pool stage + S9 skip + detector exclusions; C3 `2d68077` `activate-capability.sh` + reference rework + test harness; C4 `291dd9e` Procedure 6 redesign).
**Authoritative design:** `ARCHITECTURE-BD-200-ADVERSARIAL-REVIEW.md` (§1–§10) + `PLAN-BD-200.md`. **Date:** 2026-06-04.
**Method:** independent re-measurement — full fresh-install + fresh-clone-no-`$PACK` activation walk on a self-provisioned `/tmp` scratch (provisioned + cleaned up per `test-infra-self-provisioned`); whole-surface boundary scan; cross-commit coherence; all five BD-200 test suites + `validate-pack.py`; manifest reproducibility. No prior `PACK-REVIEW`/`IMPL` report read (independence).

---

## OVERALL VERDICT — **findings-to-fix** (ONE SHOULD; the deliverable is otherwise CLEAN and acceptance-complete)

BD-200 coheres end-to-end across all four commits and meets every acceptance criterion I could measure. The fresh-clone-no-`$PACK` activation story works (verified by my own walk), the pool is tracked and travels with a clone, the single-source tables are drift-free by construction, the whole-surface boundary scan is clean on every BD-200-authored surface, every guard passes, all five test suites are green, the manifest is byte-reproducible, and the BD-202 deferral held across the whole diff.

The **one** finding is a cross-commit-coherence defect in a user-facing recovery message inside `activate-capability.sh` (a SHOULD): its P0 pool-absent message directs the user to `init-project.sh --update`, but `--update` does NOT populate the pool (S5b runs only on fresh install) — so the advised recovery does not work for the only population it targets (pre-BD-200 installs). This is a shipped-client-surface inaccuracy, not a functional break of the primary capability. Fixable with a one-line message edit; it does NOT gate the primary acceptance criteria.

---

## Per-acceptance-criterion PASS/FAIL

| # | Acceptance criterion | Verdict | Evidence (summary) |
|---|---|---|---|
| 1 | Fresh-clone activation, the whole story (init Swift-only → clone no-`$PACK` → `activate --add language:python` → re-materialize from pool → Procedure 6 followable) | **PASS** | My `/tmp` walk: clone carries pool; `env -u PACK bash scripts/activate-capability.sh --add language:python` → exit 0; `pyproject.toml` + `server/src/app/__init__.py` + `scripts/bootstrap-python.sh` materialized; 0 `$PACK` refs in run; prompt gitignored; Procedure 6 verb/prompt/steps all match the shipped script. |
| 2 | `x-`-on-overwrite preserved end-to-end | **PASS** | `test-activate-capability.sh` Group 2: x- resolved dest preserved (not clobbered), warn emitted, non-x- dest still written. P5 `is_x_prefixed` guard at `activate-capability.sh` stage_p5_copy + the P2 pass-through. |
| 3 | Pool TRACKED + complete (incl. GAP-A root files) + no `.gitignore` line | **PASS** | Fresh install pool contains `pyproject.toml`, `pyrightconfig.json`, `server/**`, `proto/**` + all conditional scripts (18 files). `grep pack-capability-pool project-template/.gitignore` → ABSENT. |
| 4 | Single-source tables in EXACTLY one authored file, both consumers | **PASS** | The three functions defined only in `project-template/scripts/capability-tables.sh` (the test-harness redefinition is a per-clone `/tmp` override). `add-capability.sh` sources via `_load_capability_tables`; `activate-capability.sh` sources its sibling copy. |
| 5 | Whole-surface boundary — ZERO pack-self tokens; Check 43 + 37 green | **PASS** | Scan of all 6 BD-200-authored client surfaces: clean. Pre-existing `$PACK`/`pack-ops/` hits in METHODOLOGY/INSTALL-PROCEDURES/PM-CHAT are NOT BD-200 additions (verified) and pass Check 43/37 today. `validate-pack.py` PASSED. |
| 6 | Cross-commit coherence (verb / prompt / pool / tables / roster consistent) | **PASS w/ 1 SHOULD** | Verb `activate-capability.sh`, prompt `.pack-activate-capability-prompt.md`, pool `pack-capability-pool/`, tables file, S5b roster all consistent across script + HELP-FRAGMENT + PM-CHAT + INSTALL-PROCEDURES + Procedure 6 + init S5b. **Exception → F-1:** the P0 recovery message's `--update` advice is incoherent with S5b being fresh-install-only. |
| 7 | Detection completeness — every tree-walker excludes the pool | **PASS** | C2 added `pack-capability-pool/` exclusions to `detect_language_markers`, `detect_source_files`, and all four `detect.sh` marker detectors (python-data, protobuf, swiftdata, python-observability). `test-detect.sh`: 100 passed incl. 5 new pool-prune cases. |
| 8 | Guards (validate-pack all checks; Check 47 frozen; dependency-direction) + test suites | **PASS** | `validate-pack.py` → PASSED. Check 47 frozen 2-tuple `['scripts/lib/detect.sh','scripts/pack-help.sh']` UNMOVED. All five suites green: activate 27/0, add-cap 19/0, init 67/0, detect 100/0, check-41 4/0. No project-side file is a pack runtime dependency. |
| 9 | Manifest consistent + reproducible | **PASS** | `build.sh --all --clean` → manifest byte-identical to committed. |
| 10 | BD-202 boundary — no cross-version pool-refresh / update-engine logic | **PASS** | Only `wipe-repopulate` mention is a NEGATIVE deferral comment. S5b NOT in `cmd_update`. No delete-propagation / reconciler logic in the diff. |
| 11 | Scope discipline — confined to fenced scope; nothing from BD-202 leaked | **PASS** | 13 files, all in fenced scope. `detect.sh`/`test-detect.sh` are the load-bearing pool-exclusion fix (a Swift-only project would mis-detect Python off its own pool) — in-scope integration necessity, not creep. |

---

## Findings

### F-1 — SHOULD — P0 pool-absent recovery message advises a `--update` path that does not populate the pool

**Surface:** `project-template/scripts/activate-capability.sh`, `stage_p0_preflight()`, the `[[ ! -d "$POOL" ]]` arm (exit `EXIT_NO_POOL=22`). Client-shipped.

**Evidence (quoted):**

```
say "STOP — capability pool pack-capability-pool/ is absent."
say "It is a tracked directory created at project setup; if it is"
say "missing, your project was set up before capability activation"
say "was available. Re-run scripts/init-project.sh --update to"
say "materialize the pool, then re-run this script."
```

But `stage_s5b_populate_pool` is invoked ONLY from the fresh-install `main()` path (`scripts/init-project.sh:1547`), never from `cmd_update()`:

```
# awk '/^cmd_update\(\)/,/^}/' scripts/init-project.sh | grep -c "s5b\|populate_pool"
0   (--update never calls S5b)
```

And init-project.sh itself documents the gap as deliberate (BD-202): `init-project.sh:574 — "FRESH-INSTALL only — NO pack update refresh / wipe-repopulate (that is BD-202)."`

**Why this is a defect (not a nit):** The message is the recovery path for the exact population it names — a project "set up before capability activation was available" (a pre-BD-200 install with no pool). Such a user, following the advice, runs `--update`, gets NO pool created (S5b is unreachable from `cmd_update`), and re-hits exit 22 with no working recovery. A client-shipped recovery instruction that does not work for its stated audience is a coherence defect in shipped content (analogous in kind to the INSTALL-PROCEDURES `x-`-deleter inaccuracy that R3 corrected this very BD). It is SHOULD (not MUST/BLOCKER) because (a) the primary capability — activation on a fresh clone of a BD-200-era install — is fully functional and unaffected; (b) the genuine pool-on-`--update` capability is legitimately BD-202 scope, so the script cannot honestly promise it yet.

**Recommended fix (pick one, no BD-202 scope pull):**
- (a) Re-point the recovery at the path that DOES populate the pool: re-run the fresh-install flow, OR state that pool back-fill for pre-BD-200 installs lands in a later pack update (BD-202) and is not yet available — i.e., make the message honest about the deferral rather than naming a no-op flag; OR
- (b) If the team wants `--update` to back-fill the pool for transitional installs, that is net-new behavior = a BD-202 (or explicitly-authorized BD-200 follow-up) work item, NOT an inline edit here. Default to (a) — a message correction — to keep BD-200 fenced.

This is the only finding. Everything below is confirmed-clean, recorded for the close-out audit trail.

---

## Confirmed-clean (no action)

- **Single-source refactor is behavior-preserving.** `add-capability.sh` resolves identically post-refactor; `_load_capability_tables` is lazy-sourced from `stage_a1_resolve` AFTER `stage_a0_preflight` validates `$PACK` — no PACK-unset regression. `EXIT_PACK_INVALID` (=10) is defined and used. `bash -n` clean on all five scripts.
- **BD-NNN comment strip is correct.** The capability-table comments carried `BD-141/156/157/158/162/144/048/047` citations in the pack-side `add-capability.sh`; the extracted `project-template/scripts/capability-tables.sh` (now client-shipped, Check-43-walked) strips them — required by boundary, and confirmed clean by the scan. `detect.sh`'s cross-ref was correctly retargeted from `scripts/add-capability.sh::capability_skills()` to `capability-tables.sh::capability_skills()`.
- **S9 pool-skip + detector exclusions.** `is_pool_path` guard added to every S9 removal arm (defensive; S9 names no pool path today). Detector pool-exclusions are LOAD-BEARING (the pool ships `.py`/`.proto` masters on every install) and correctly commented as such. `test-detect.sh` proves live-tree detection still wins when both pool + live markers are present.
- **Prompt-file gitignore.** `ensure_prompt_gitignored` writes `.pack-activate-capability-prompt.md` to `.gitignore` BEFORE emitting (de-duped); verified IGNORED in my clone walk. The `.pack-*` name correctly denotes gitignored local state (GAP-C property-fit honored — the tracked pool is NOT `.pack-*`).
- **Install-map NOTE.** The S5b bulk-copy NOTE is present in `_CLIENT_INSTALLED_FILES`, sourced from `project-template/` masters, explicitly NOT a `_SANCTIONED_PACK_SIDE_SHIPPED` entry — Check 41 green, Check 47 frozen.
- **INSTALL-PROCEDURES R3 correction.** `add-capability.sh` dropped from the "deletions skip `x-`" bullet (it deletes nothing); `activate-capability.sh` added to the "overwrites skip `x-`" bullet (its P5 is an overwrite site). Both bullets now factually match measured script behavior; the doc-encoding partner of the P5 `x-` guard is in lock-step (`enumerate-encoding-surfaces` satisfied).
- **Trinity.** BD-200 ships NO `project-template/` trinity (CLAUDE/AGENTS/GEMINI) content change — confirmed; trinity-parity rule does not fire (Procedure 6 only *describes* the PM-chat trinity edit performed at activation runtime).

---

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **READ-IN-FULL set** | Read IN FULL (per-file proof): `CLAUDE.md ## Pack memory` (supplied complete in session context, read in full — trinity rule + dependency-direction + all `### ` subsections); `pack-ops/PACK-AGENTS.md` (226 lines, single Read); `pack-ops/PACK-CHAT.md` (310 lines, single Read); `project-template/CLAUDE.md` (456 lines, single Read — trinity rule 361-364, deny-list 390-400, confirmed no template-trinity change); `PLAN-BD-200.md` (235 lines, single Read); `ARCHITECTURE-BD-200-ADVERSARIAL-REVIEW.md` (§1–§10.8, full — page 1-336 + page 337-441); `pack-ops/BACKLOG.md` BD-200 entry (3273-3306, full) + BD-202 entry (3310-3326, full); curated memory (each single full Read): `feedback_agents_read_rule_docs_in_full`, `feedback_agent_output_rules_applied_block`, `feedback_manifest_regen_on_v11_surface`, `feedback_bd_pack_only_operational_rule`, `feedback_pack_project_separation_of_concerns`, `feedback_client_ref_delete_or_forward_look`, `feedback_ci_guard_design_measure_then_bound`. Source read in full: `project-template/scripts/activate-capability.sh` (424 lines), `project-template/scripts/capability-tables.sh` (217 lines); diffs of `add-capability.sh`, `init-project.sh`, `detect.sh`, the 4 docs; `init-project.sh` cmd_update 1165-1239 + run_stages 1520-1560. | **COMPLIANT** |
| **boundary / no-pack-self-in-project** | Whole-surface scan (item 5) of all 6 BD-200-authored client surfaces for `$PACK`/`pack-* agents`/`maintenance-docs/`/`pack-ops/`/`BD-NNN`/`from the pack`/stage-A7-A8/`.pack-add-capability`: every BD-200-authored surface CLEAN. Pre-existing hits (PM-CHAT:533, INSTALL-PROC, METHODOLOGY:1691) verified NOT BD-200 additions via `git diff ... | grep '^+'` (none). Check 43+37 green (validate-pack PASSED). | **COMPLIANT** |
| **enumerate-encoding-surfaces** | Verified verb/prompt/pool/tables/roster consistent across ALL 9 encoding surfaces (script, tables, Check-22 verb pairing HELP-FRAGMENT+PM-CHAT, Procedure 6, install-map NOTE, manifest, test harness, .gitignore-by-absence, INSTALL-PROC x- bullets). The ONE cross-commit mismatch found = F-1 (recovery message vs S5b reachability). | **COMPLIANT** |
| **pack-project separation + dependency-direction** | `capability-tables.sh` consumed by each side from its same-side copy (pack: `$PACK/project-template/...`; client: sibling `scripts/`); no cross-side substitution. No project-side file is a pack runtime dependency. Check 47 frozen 2-tuple UNMOVED (quoted from validate-pack output). | **COMPLIANT** |
| **empirical verification** | Every verdict backed by a command + quoted output: fresh-install pool `find` listing; fresh-clone `env -u PACK` activation walk (exit 0, files materialized, 0 `$PACK`); 5 test-suite tallies; `validate-pack.py` PASSED tail; manifest byte-identical diff; S5b-not-in-cmd_update grep count 0. | **COMPLIANT** |
| **ci-guard-measure-then-bound** | Guards measured green against the integrated tree (not asserted): validate-pack full run PASSED; Check 47 set-equality printed; Check 41 NOTE present; detector exclusions proven by test-detect 100/0 incl. pool-prune + live-wins cases. | **COMPLIANT** |
| **BD-202 boundary** | Confirmed deferral held across whole diff: only `wipe-repopulate` occurrence is a negative deferral comment; S5b absent from `cmd_update` (grep count 0); no reconciler/delete-propagation logic added. | **COMPLIANT** |
| **scope-deliverables-to-the-ask** | Review leads with verdict + per-criterion table; one substantive finding; confirmed-clean items recorded tersely for the close-out trail (no SUSPECTED/edge-case sprawl). | **COMPLIANT** |
| **rules-applied-verification-block** | This table — per-rule name + measured/quoted evidence + terminal verdict; no empty-evidence rows; READ-IN-FULL row carries per-file proof. | **COMPLIANT** |
| **agents-never-commit** | Read-only verbs only (`git diff`, `git log`, `grep`, `sed`, `find`, `bash -n`, test runs). Test infra self-provisioned in `/tmp` (`mktemp -d`) + cleaned up; no real repo touched. The single `git checkout -- test-fixtures/manifest.txt` restored a build-regenerated, byte-identical (unmodified) tracked file — no state change to tracked content; NO `git add/commit/push/tag`. | **COMPLIANT** |
