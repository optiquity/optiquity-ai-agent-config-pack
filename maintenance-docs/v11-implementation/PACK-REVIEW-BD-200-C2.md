# PACK-REVIEW — BD-200 commit C2 (AUTHORITATIVE redo)

**Role:** pack-reviewer (fresh, authoritative). **Branch:** `v11-dev`. **HEAD:** `98b6a9b10e9d9e8b114995e3d416e708230c5bde` (unmoved). **Date:** 2026-06-04.
**Scope reviewed:** the C2 working-tree changes (uncommitted) — `scripts/init-project.sh` (T4 + the `detect_language_markers()` pool-exclusion), `scripts/lib/detect.sh` (F1 comment-only cross-ref fix), `test-fixtures/manifest.txt` (regenerated). READ-ONLY review; no source edits, no state-changing git verb. The prior `PACK-REVIEW-BD-200-C2*.md` was NOT read for content (avoids bias; only its title line was read to satisfy the Write tool's read-gate); this file is overwritten with an independent review.

---

## VERDICT (lead)

**findings-to-fix — 1 SHOULD + 2 NIT.** No BLOCKER, no MUST. The core T4 mechanism is correct and independently reproduced: pool complete (18 files incl. GAP-A root files), S9 live-tree behavior preserved, BD-202 boundary intact, all guards + test suites green, manifest reproducible, scope clean.

The one substantive finding (S-1) is a **completeness gap in the detection-ripple hunt**: the coder excluded the pool from `detect_language_markers()` in `init-project.sh`, but a **parallel detector family in `scripts/lib/detect.sh`** (`protobuf_marker_detected`, `python_data_marker_detected`, `python_observability_marker_detected`, `swiftdata_marker_detected`) ALSO walks the installed tree, is NOT pool-excluded, and **empirically mis-fires on the pool** (proven below: `protobuf-marker: yes` with pool present vs. `no` with pool moved aside). The harm is **latent, not active** on the fresh-install path (the only init-time consumer checks the coverage string for emptiness only), but these are the documented canonical predicates the PM chat / future tooling run against the project root to decide intersection-skill loading — so a Swift-only client now gets a false protobuf/python signal on any post-install consultation. Rate SHOULD.

---

## Findings

### S-1 (SHOULD) — Parallel detector family in `scripts/lib/detect.sh` is NOT pool-excluded and empirically mis-fires on the tracked pool

**Files:** `scripts/lib/detect.sh` — `protobuf_marker_detected()` (def ~L482), `python_data_marker_detected()` (~L362), `python_observability_marker_detected()` (~L715), `swiftdata_marker_detected()` (~L588). Consumed by `scripts/init-project.sh::pack_skill_coverage_for()` (L247) at S10, and — per `project-template/docs/pack/PLATFORM-SKILLS.md` (L100/222–225/267/278/362) — by the PM chat as the **canonical intersection-load predicates**.

**Evidence (independent A/B, Swift-only `/tmp` install, pool present vs moved aside):**
```
######## A: POOL PRESENT ########
python-data: no
python-observability-marker: no
protobuf-marker: yes        <-- mis-fire
swiftdata-marker: no
######## B: POOL MOVED ASIDE ########
python-data: no
python-observability-marker: no
protobuf-marker: no         <-- correct
swiftdata-marker: no
```
The pool ships `pack-capability-pool/proto/*.proto` + `proto/buf.yaml` + `proto/buf.gen.yaml` (trips `protobuf_marker_detected` marker (a)/(c)) and `pack-capability-pool/pyproject.toml` (contains `grpcio-testing` — within a hair of tripping the python-data/protobuf manifest scans) + `server/**/*.py`. These functions scan the WHOLE `$TARGET` (`find "$target" -name "*.py"`, `find "$target" ... -name '*.proto'`, `$target/pyproject.toml`) with NO `pack-capability-pool/` exclusion — unlike the patched `detect_language_markers()`.

**Why it's a real gap (`enumerate-encoding-surfaces`):** the pool is new permanent client-tree STATE; EVERY tree-scanning detector is an encoding surface that must handle it. The coder patched one detector function but missed the parallel family in the sibling library. Asymmetric handling = audit gap — exactly the rule's failure mode.

**Why SHOULD, not BLOCKER/MUST (harm is latent, not active on the fresh-install path):**
- The ONLY init-time runtime consumer is `pack_skill_coverage_for()` at S10 (`stage_s10_kickoff_prompt`, runs after S5b so the pool is present). Its result is used ONLY for an emptiness test: `[[ -z "$(pack_skill_coverage_for "$lang" "$TARGET")" ]] && gaps+=("$lang")`. The loop iterates only over `lm` (the pool-EXCLUDED language list). For a Swift-only project `lm=swift`, so only the `swift` arm runs (→ `swiftdata_marker_detected`, correctly `no`); the mis-firing `proto`/`python` arms are never reached. Even when `lm` legitimately contains `python`/`proto`, a predicate mis-fire can only ADD a skill to an already-non-empty coverage string, never empty it → it cannot create or suppress a gap. Verified: my Swift-only install's preview correctly reported `swift: FULL`, zero gaps.
- `detect_installed_capabilities()` reads CLAUDE.md's `**Active skills:**` line, NOT the tree → unaffected.
- `add-capability.sh` does not call these predicates against the live tree.
- `cmd_update` does not call `detect_language_markers`/S9 → no pool-present ripple there.
- The v10→v11 migrator populates NO pool (BD-200 is fresh-install init only) → no migrator ripple.

**Latent harm that justifies fixing now (not deferring):** PLATFORM-SKILLS.md designates these four functions as the canonical predicates the PM chat consults against the project root to decide which intersection skills to load (`protobuf-patterns`, `python-data-architecture`, `python-observability-patterns`, `apple-swiftdata-patterns`). Post-BD-200, EVERY installed client permanently carries a pool with proto + python masters, so any PM/tooling run of `protobuf_marker_detected "$PROJECT_ROOT"` on a Swift-only project returns a false `yes` → a spurious `protobuf-patterns` skill recommendation. This is a detection-correctness regression introduced by the tracked-pool decision; it is dormant only because no init-time code branches on the yes/no today.

**Recommended fix (minimal, in the same family-shaped style as the T4 patch):** add a `pack-capability-pool/` exclusion to the tree-walking finds in the four `*_marker_detected()` functions in `scripts/lib/detect.sh` (the `find "$target" ... -name '*.py'` / `'*.proto'` / `'*.swift'` walks), parallel to the existing `node_modules`/`.git`/`build`/`.venv` prune set and the `detect_language_markers()` `-not -path '*/pack-capability-pool/*'` exclusion. Manifest filename scans (`$target/pyproject.toml` etc.) read the live-tree root file directly and do not recurse into the pool, so they need no change — but adding the pool prune to the recursive `find`s closes the `.proto`/`.py`-count vectors. Because `detect.sh` is client-installed (S11) AND pack-side, the fix is pack-side and ships to clients; it is a behavioral change to a shared detector, so it lands via fix-coder with its own test coverage (extend `scripts/test-detect.sh` with a pool-present fixture asserting the markers do NOT fire on pool-only content — the encoding-surface test partner).

**Scope note for triage:** this fix edits `scripts/lib/detect.sh` substantively (runtime, not comment-only). It stays pack-side (no `project-template/`/`supporting-docs/`), so a `pack-only` C2 keyword remains valid if the fix is folded into C2; alternatively it can be its own follow-up commit. The fix-coder must re-regen `test-fixtures/manifest.txt` (detect.sh is S11-installed into v11 fixtures → v11-* SHAs move).

---

### N-1 (NIT) — `detect_source_files()` in `init-project.sh` is not pool-excluded (informational only; harmless today)

**File:** `scripts/init-project.sh::detect_source_files()` (L189) — `find "$target" -maxdepth 2 -name "*.swift"` / `"*.py"` with no pool exclusion.

Its output (`source-files: *.swift=N, *.py=M`) feeds ONLY the `print_preview` diagnostic banner, which runs in `main()` BEFORE the stage block — at preview time the pool does not yet exist, so the count is correct on the fresh-install path (verified: my install's preview reported `source-files: *.swift=1, *.py=0`). It is harmless today. Recommend adding the same `-not -path '*/pack-capability-pool/*'` exclusion for consistency / future-proofing (e.g., if this diagnostic is ever called post-install), folded into the S-1 fix. NIT because there is no current observable harm.

---

### N-2 (NIT) — C2 carries the F1 `detect.sh` fix beyond the PLAN's literal C2 (T4 only); audit-trail note

`PLAN-BD-200.md` §4 specifies C2 = T4 (`scripts/init-project.sh`) only. The actual C2 also includes the F1 `detect.sh` comment-only cross-ref fix (a carried-forward C1 review finding, per the IMPL-REPORT). This is benign and correctly disclosed in the IMPL-REPORT, and `detect.sh` is pack-side so the `pack-only` keyword stays valid. NIT only: the deviation from the plan's literal C2 file-set should be acknowledged at commit time (the commit subject / approval should note the F1 fix rides along), so the audit trail reflects that C2 ≠ the plan's literal T4-only scope. No correctness issue.

---

## Per-item verification results (independent measurement)

1. **Pool completeness + GAP-A — PASS.** Swift-only `/tmp` install: `find pack-capability-pool -type f` → 18 files incl. ROOT files (`pyproject.toml`, `pyrightconfig.json`, `server/`, `proto/`) sourced from `$PACK/project-template/`. GAP-A handled (root files have no live-tree source; sourced direct from the pack master).
2. **S9 preserved + pool survives — PASS.** Live tree: `pyproject.toml`/`server`/`proto`/`bootstrap-python.sh`/`validate-python.sh`/`proto-gen.sh` REMOVED; `bootstrap-swift.sh`/`validate-swift.sh` KEPT; pool's 18 files SURVIVE S9 (defensive `is_pool_path()` skip works).
3. **Pool-in-tree detection ripple — CORRECT but INCOMPLETE → S-1.** `detect_language_markers()` (the load-bearing S9 detector at L736) IS pool-excluded and correct. The parallel `detect.sh` `*_marker_detected()` family is NOT excluded and mis-fires (A/B proof above). Active harm: none on fresh-install (latent only). See S-1.
4. **Other pool-presence ripples — PASS (besides S-1).** `validate-pack` checks do not walk the client tree for these markers; manifest reproducible (regen == working tree); `.gitignore` has NO pool line and the pool is NOT git-ignored in the install (`git check-ignore` → not ignored — TRACKED invariant holds); no other stage iterates the pool destructively (`cmd_update` untouched; migrator has no pool).
5. **Check-41 NOTE + Check 47 frozen — PASS.** NOTE sits in the "Bulk-copied directories" comment block (L1359–1368), BEFORE the parsed `_CLIENT_INSTALLED_FILES_START` marker (L1381) → documentation, not a parsed entry. Content accurate (all sources `project-template/`; no sanctioned-set growth). Check 41 green (37 entries, 0 drift). `_SANCTIONED_PACK_SIDE_SHIPPED` UNCHANGED = `("scripts/lib/detect.sh", "scripts/pack-help.sh")`; Check 47 green.
6. **F1 fix — PASS.** `detect.sh` diff is a single comment line: `add-capability.sh::capability_skills()` → `capability-tables.sh::capability_skills()`. Verified the functions are now DEFINED in `project-template/scripts/capability-tables.sh` (L20/99/129) and NOT in `add-capability.sh` (which sources them) → old cite was stale, new cite correct. Zero remaining stale `add-capability.sh::capability` cites tree-wide. No runtime change.
7. **BD-202 boundary — PASS.** Diff grep for `cmd_update`/`customization`/`three_way`/`wipe`/`repopulate`/`refresh`/`removed-by-pack`/`delete-propagat` → the only hit is a COMMENT explicitly EXCLUDING that logic and pointing to BD-202. No update/refresh engine added. Boundary intact.
8. **Manifest — PASS.** Exactly the 3 v11-* rows moved (`v11-realistic-ot`, `v11-flat-file`, `v11-tracker-on`); `v10-minimal`/`v10-realistic-ot`/`existing-project-mid-dev` UNCHANGED. Independent `bash test-fixtures/build.sh --all --clean` reproduced the working-tree manifest byte-for-byte (idempotent).
9. **Guards + tests — PASS.** `python3 scripts/validate-pack.py` → `PASSED — all checks clean` (exit 0; Check 48 WARNs are pre-existing JC-5 advisory, not introduced by C2). `test-init-project.sh` 67/0; `test-detect.sh` 95/0; `test-validate-pack-check-41.sh` PASS 4/FAIL 0. All re-run by me.
10. **Scope — PASS (with N-2 note).** Exactly 3 modified files (`init-project.sh`, `detect.sh`, `manifest.txt`); no `project-template/`/`supporting-docs/` touched → `pack-only` keyword valid. The `detect_language_markers()` pool-exclusion is a necessary, minimal, correct T4 consequence (the IMPL-REPORT's disclosed deviation). N-2 notes the F1 fix rides beyond the plan's literal C2.

---

## Triage summary (for Pack Chat)

| ID | Severity | Disposition recommendation |
|---|---|---|
| S-1 | SHOULD | FIX — add pool exclusion to the four `*_marker_detected()` finds in `scripts/lib/detect.sh` + a pool-present `test-detect.sh` assertion; re-regen manifest. Latent detection-correctness regression on the canonical intersection-load predicates; fix-now per default-fix-all + the tracked-pool blast radius. Pack-side; `pack-only` stays valid. |
| N-1 | NIT | FIX (fold into S-1) — pool-exclude `detect_source_files()` for consistency; harmless today. |
| N-2 | NIT | ACKNOWLEDGE at commit — note in the C2 subject/approval that the F1 `detect.sh` fix rides with T4 (plan's literal C2 was T4-only). No code change. |

**Cycle position (`review-cycle-position-checkpoint`):** this is the authoritative review-1 on C2. Findings → triage → fix-coder (pass 1) → review-2 (mandatory post-fix reviewer, even for the small detect.sh edit; a fix is never terminal). Pack Chat does not self-review the fix.

---

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| READ-IN-FULL set | Read IN FULL via Read tool (per-file proof): `CLAUDE.md` (541 lines; first line `# CLAUDE.md — AI Agent Config Pack (Pack Repo)`, last line `OT itself is read-only for testing (use /tmp clones or scratch fixtures, never write to real OT).`); `pack-ops/PACK-AGENTS.md` (226 lines, full); `pack-ops/PACK-CHAT.md` (310 lines, full); `project-template/CLAUDE.md` (456 lines, full); `PLAN-BD-200.md` (235 lines, full); `ARCHITECTURE-BD-200-ADVERSARIAL-REVIEW.md` §3.2/§3.4/§4.1/§4.5 read in full (L76–195) + section map of the full 440-line doc; BD-200 entry `pack-ops/BACKLOG.md:3273–3306` (full) + BD-202 entry `:3310–3326` (full); curated memory (each full, via Read): `feedback_agents_read_rule_docs_in_full` (71 lines), `feedback_agent_output_rules_applied_block` (15 lines), `feedback_manifest_regen_on_v11_surface` (16 lines), `feedback_ci_guard_design_measure_then_bound` (15 lines), `feedback_bd_pack_only_operational_rule` (35 lines), `feedback_pack_project_separation_of_concerns` (33 lines), `feedback_review_cycle_position_checkpoint` (57 lines); `IMPL-BD-200-C2.md` read for context (210 lines), every claim independently re-verified. | COMPLIANT |
| enumerate-encoding-surfaces | Enumerated EVERY tree-scanning detector across both files: `init-project.sh` {`detect_language_markers` (patched), `detect_source_files` (N-1), S9 detection via `detect_language_markers` L736}; `detect.sh` {`detect_installed_capabilities` (reads CLAUDE.md, not tree — unaffected), `python_data_marker_detected`, `protobuf_marker_detected`, `swiftdata_marker_detected`, `python_observability_marker_detected` (S-1 — NOT pool-excluded)}. Traced all consumers (`pack_skill_coverage_for` L247 → S10; PLATFORM-SKILLS.md canonical predicates). Asymmetric handling found → S-1/N-1. | COMPLIANT |
| ci-guard-measure-then-bound | Measured Check 41 parser (only START/END `->` lines parsed; Bulk-copied block L1350–1379 is documentation, before START marker L1381) → NOTE bounded to the real S5b copy-site, all sources `project-template/`. Verified Check 41 green (37 entries, 0 drift) + Check 47 frozen 2-tuple unmoved (`sed` L4158–4162 quoted) against the post-edit tree. No allowlist widening. | COMPLIANT |
| empirical verification | Ran my own Swift-only `/tmp` install (provisioned + cleaned per test-infra-self-provisioned); captured pool `find` (18 files), S9 live-tree result, A/B detector scan (pool present vs aside — `protobuf-marker` flips yes→no), `validate-pack` PASSED, three test suites green, manifest regen-diff (reproducible). Every verdict backed by quoted command output above. | COMPLIANT |
| review-cycle-position-checkpoint | Stated cycle position: authoritative review-1 on C2; findings → fix-coder → mandatory review-2 (fix never terminal; Pack Chat no self-review). See Triage summary. | COMPLIANT |
| scope-deliverables-to-the-ask | Reviewed exactly C2; led with verdict + findings; no sprawl; out-of-scope (BD-202) confirmed absent, not re-litigated. | COMPLIANT |
| rules-applied-verification-block | This block: per-rule name + measured/quoted evidence + terminal verdict; READ-IN-FULL row carries per-file proof (line counts / first+last line); no empty-evidence rows. | COMPLIANT |
| agents-never-commit | Only read-only verbs (`git rev-parse`, `git branch`, `git status`, `git diff`, `git check-ignore`, `grep`, `sed`, `find`, `ls`) + `git init`/`commit` confined to a `/tmp` scratch repo (deleted after). No `git add`/`commit`/`push`/`tag` on the repo. HEAD `98b6a9b` unmoved. Single Write = this report at the prompted path. | COMPLIANT |
