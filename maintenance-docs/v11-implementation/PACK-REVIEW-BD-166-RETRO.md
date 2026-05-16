# PACK-REVIEW-BD-166-RETRO.md — retroactive per-BD review of `init-project.sh` greenfield per-entry tree install (S11 extension)

**Review subject:** BD-166 (commit `91e497c` — `feat: v11 — BD-166 init-project.sh greenfield per-entry tree install (S11 extension)`)
**Review type:** RETROACTIVE per-BD review (post-commit; pre-fix; commit landed in Batch 19 WITHOUT a per-BD review at the time)
**Reviewed against:**
- `maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` §8.17 (init-project.sh greenfield path disposition) + §9.3 (helper reuse pattern) + §9.7 (canonical templates ship from `project-template/docs/project/<stream>/`) + §18.1 #5 (planner-stage-extension recommendation)
- `maintenance-docs/v11-implementation/PLAN-PER-ENTRY-SPLIT-BATCH-19.md` §5.5 (BD-166 commit spec) + §10.6 R-6 (PLAN recommendation: extend S11 with `[[ -d project-template/docs/project/<stream> ]]` precondition check)
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-166.md` (commit 19d implementation report)

**Reviewer:** pack-reviewer (sub-agent)
**Date:** 2026-05-16
**Branch:** v11-dev (current HEAD `c0723b7`)
**Implementation HEAD:** `91e497c` (the commit under review)

---

## §1 — Summary

BD-166 extended `stage_s11_v11_artifacts` in `scripts/init-project.sh` with two new sub-steps (6 template install + 7 greenfield-only mirror+TOC regen) per architect-doc bindings §8.17 + §9.3 + §18.1 #5. Behavioral correctness verified by reproducing the smoke claims: greenfield install produces the expected per-entry tree skeleton, byte-identical empty mirrors, empty seed `_toc.md` files, idempotent helper-level re-invocation, and clean `bash -n` / `validate-pack.py` / `test-init-project.sh` 34/34. Architect bindings honored — stage extension preferred over new stage; helper-reuse pattern preserved (BD-164 helpers serve three call sites); project-side asymmetry correct (`_format.md` for changelog only); greenfield gating (`CLASS == new-*`) prevents existing-* clobber; `existing_classifier_copy` correctly routed for the new templates via `$copy_fn`. **However, the new functional surface is NOT covered by any CI-wired assertion.** `test-init-project.sh` Group 3 still stops at the pre-BD-166 surface (8 pre-existing S11 artifacts) and never asserts on `docs/project/<stream>/*.md` files, regenerated mirrors, or empty `_toc.md` outputs — so a regression in sub-step 6 OR sub-step 7 would land CI-green. The two persona-contract scripts `scripts/persona-contracts/contract-greenfield.sh` and `scripts/persona-contracts/contract-migration.sh` carry an explicit "keep in sync with `stage_s11_v11_artifacts()`" stay-in-sync comment (per BD-116 PACK-REVIEW NIT N1) and BOTH lists are now stale — neither covers the new BD-166 surface. The smoke test in the IMPL-REPORT §4.3 successfully proves the surface works today but is a one-shot manual artifact, not a CI gate. This is the same heuristic failure pattern (test-not-in-CI) that BD-165's retro review surfaced as critical.

**Finding totals: 2 MUST + 2 SHOULD + 2 NIT.**

---

## §2 — Findings

### MUST

- **Severity:** MUST
  **Location:** `scripts/tests/test-init-project.sh:140-202` (Group 3 — stage S11 v11 artifacts (fresh install))
  **Finding:** Group 3 of `test-init-project.sh` does NOT exercise BD-166's new sub-step 6 (canonical per-entry template copies into `docs/project/<stream>/`) OR sub-step 7 (greenfield empty mirror + TOC regen). The runner runs the full greenfield init (`bash $INIT_SH "$T" <<<"y"`) which DOES traverse the new code path, but asserts only on the 8 pre-BD-166 S11 artifacts (HELP-FRAGMENT, tracker.toml.example, issue forms, per-CLI pack-help, pack-help.sh + lib/detect.sh, byte-identity check). A regression in either new sub-step would land CI-green.
  **Evidence:**
  - `test-init-project.sh:148` confirms the test runs the full S11 path: `assert_contains "3.1 S11 stage ran" "$out" "S11 — v11 client artifacts"`.
  - The asserted file list (`test-init-project.sh:153-179`) contains zero references to `docs/project/backlog/`, `docs/project/changelog/`, `docs/project/implementation-plan/`, `docs/project/BACKLOG.md`, `docs/project/CHANGELOG.md`, or `docs/project/IMPLEMENTATION-PLAN.md`.
  - The validator `scripts/validate-pack.py` STREAMS constant (`scripts/validate-pack.py:189-193`) is pack-side scope only (`pack-backlog` + `pack-changelog`) per integration parent §10.6 — it intentionally does NOT validate the client-side `docs/project/<stream>/` outputs of BD-166, so Checks 32/33/34 cannot catch a BD-166 regression either.
  - IMPL-REPORT §4.3 verification items 1–7 prove the surface works today (reproduced by this review — see §3 below), but they are one-shot manual smoke commands, not a CI runner.
  - Same heuristic that flipped BD-165's retro review (`PACK-REVIEW-BD-165-RETRO.md` led to commit `c0723b7` — "new test suite 45/45"); the test-not-in-CI critical finding is repeated here.
  **Suggested remediation:** Extend `test-init-project.sh` Group 3 (or add a Group 4) with assertions for the seven canonical templates (per the three streams + project-changelog `_format.md` asymmetry), the three regenerated mirrors with byte-identity-vs-`_intro.md` for backlog/implementation-plan and `_intro.md+---+_format.md` shape for changelog, the three empty `_toc.md` files with the expected `(empty — no entries)` payload, and an idempotency assertion (re-running the regenerators yields zero mtime churn). The existing `make_target` + smoke-pattern from Group 3 supports the extension without scaffolding changes.

- **Severity:** MUST
  **Location:** `scripts/persona-contracts/contract-greenfield.sh:164-196` + `scripts/persona-contracts/contract-migration.sh:323-347`
  **Finding:** Both persona contracts carry an explicit "Keep the two in sync when adding/removing v11 client artifacts. (BD-116 PACK-REVIEW NIT N1.)" stay-in-sync comment that names `stage_s11_v11_artifacts()` as the source of truth. BD-166 added new artifacts to `stage_s11_v11_artifacts()` (seven canonical templates + three regenerated mirrors + three empty `_toc.md` files), but NEITHER `s11_files` array (greenfield contract) NOR `v11_artifacts` array (migration contract) was extended. Both arrays still list the same 8 entries they had pre-BD-166. These contracts run in CI (`.github/workflows/validate-pack.yml:235` — "persona contracts (BD-116, RELEASE-GATE item 3)"), so the stay-in-sync invariant they exist to enforce is currently violated.
  **Evidence:**
  - `contract-greenfield.sh:165-167` (verbatim): `# NOTE: this list mirrors the hardcoded enumeration in / # scripts/init-project.sh:stage_s11_v11_artifacts(). Keep the two in sync / # when adding/removing v11 client artifacts. (BD-116 PACK-REVIEW NIT N1.)`.
  - `contract-greenfield.sh:180-189` `s11_files` array: 8 entries (HELP-FRAGMENT, tracker.toml.example, scripts/pack-help.sh, scripts/lib/detect.sh, per-CLI pack-help × 3). Pre-BD-166 list; nothing under `docs/project/`.
  - `contract-migration.sh:331-340` `v11_artifacts` array: same 8 entries; same gap.
  - `contract-greenfield.sh:169-179` and `contract-migration.sh:327-329` "Mapping to stage_s11_v11_artifacts() sub-stages" comment enumerates sub-stages 1, 2, 3, 4, 5 — no mention of the new sub-stages 6 + 7.
  - The greenfield contract's CI invocation runs against a freshly-init'd sandbox per `scripts/test-persona-contracts.sh` (the BD-116 contract harness), so a regression that drops the per-entry tree from greenfield init would NOT trip either contract today.
  **Suggested remediation:** Extend both arrays (and the sub-stage mapping comment) to cover the seven canonical templates and the three regenerated mirrors per stream; the greenfield contract should also assert the three empty `_toc.md` files. The migration contract should assert the same surface post-migrate (BD-165 ships the same artifacts via the v10→v11 path). The two contracts now diverge: greenfield should assert the new tree post-init; migration should assert the same post-migrate. This is the precise scenario the BD-116 NIT N1 comment was added to prevent.

### SHOULD

- **Severity:** SHOULD
  **Location:** `scripts/init-project.sh:1009`
  **Finding:** The post-block `info` line is geographically inaccurate: it says `installed under docs/project/{backlog,implementation-plan,changelog}/` but the **mirrors** (`BACKLOG.md` / `IMPLEMENTATION-PLAN.md` / `CHANGELOG.md`) live at `docs/project/` (parent of those subdirectories), NOT inside them. The skeleton supporting files DO live under the named subdirs, so the line collapses two distinct destinations into one path expression that's wrong for half the artifacts. A user scanning the init log will look in the wrong place for the mirror.
  **Evidence:** Reproduced greenfield install shows mirrors at `/var/.../docs/project/BACKLOG.md` (not `/var/.../docs/project/backlog/BACKLOG.md`). `scripts/lib/per-entry/_lib.sh:87` (`project-backlog` mirror constant) returns `docs/project/BACKLOG.md`. Sub-step 7 writes via `pe_mirror_rel="docs/project/BACKLOG.md"` per `scripts/init-project.sh:987`.
  **Suggested remediation:** Reword the info line to distinguish the two surfaces, e.g. "per-entry skeleton installed under `docs/project/{backlog,implementation-plan,changelog}/`; empty mirrors at `docs/project/{BACKLOG.md,IMPLEMENTATION-PLAN.md,CHANGELOG.md}`". The wording is user-facing log output; correctness matters.

- **Severity:** SHOULD
  **Location:** `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-166.md` §4.3 verification item 7 + §5 B9.7 checklist row
  **Finding:** The "re-run safety: helpers idempotent (cmp -s short-circuit); classification gate STOPs at exit 20" claim conflates two distinct properties and the §7.5 commentary on the missing full-main() re-run proof is half-acknowledged. The helper-level mtime-unchanged proof is valid (and reproducible — verified by this review), but it does NOT prove that `main()` re-running over an already-installed greenfield is safe end-to-end; what it proves is that **if** the regenerators are called twice, neither regenerator churns the mirror. The classification gate (exit 20 at `scripts/init-project.sh:1271`) is correct, but it only fires if the project has the legacy AI config indicators (`detect_ai_config` returns non-`(none)` per `scripts/init-project.sh:189-193`) — for a project that has the per-entry tree installed but somehow lacks the indicators (theoretical, but the BD-166 install does NOT itself plant any AI config; the AI config comes from S1..S10), the gate would NOT fire and `stage_s11_v11_artifacts` would re-enter. In that pathological case the template `cp` is fine, but sub-step 7 would re-fire the regenerators — also fine by idempotency. So the claim is operationally true but the proof chain is partial; a "see also" cross-link to `test-init-project.sh:30-39 make_target` (the function that proves an empty git repo classifies as `new-*`) would close the loop.
  **Evidence:** `scripts/init-project.sh:189-193` `classify_project_state` — `detect_ai_config != (none)` → `already-configured`. The AI config indicators are CLAUDE.md / `.claude/` / AGENTS.md / `.codex/` / GEMINI.md / `.gemini/` per `detect.sh` (not re-read here; same pattern as `make_configured_target` at `test-init-project.sh:44-56`). The per-entry tree alone is not in that list. IMPL-REPORT §7.5 itself acknowledges "the canonical re-run path requires either a `git stash` of the freshly-installed files (forbidden under `feedback_agents_never_commit`) or a `git commit` (same prohibition)" — which is true for the agent, but a CI test runner is not subject to that rule.
  **Suggested remediation:** When fix-coder extends the test runner per the MUST finding above, include a Group 4 idempotency case that runs `init-project.sh` twice against a fixture (first invocation provisions; second invocation hits the classification gate and exits 20) and a Group 5 case that calls the BD-164 regenerators directly twice and asserts zero-mtime-churn. Both cases land the proof in CI rather than in a one-shot smoke report.

### NIT

- **Severity:** NIT
  **Location:** `scripts/init-project.sh:885-902` (sub-step 6 comment header)
  **Finding:** Comment cross-references `ARCHITECTURE-PER-ENTRY-SPLIT.md §3.5 + §11` for the project-side asymmetry, but the file that actually carries the project-side asymmetry binding the coder followed is `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §9.7` (and the parent `ARCHITECTURE-PER-ENTRY-SPLIT.md §3` for the asymmetry table). The bare `§3.5` reference points to a section in the parent doc that exists but doesn't directly bind this code. The integration-parent reference at §9.7 is the actually-load-bearing one for the project-side `_intro.md`/`_format.md` ship-from-`project-template/` contract and is missing from the comment.
  **Evidence:** Compare comment at `scripts/init-project.sh:891` (`per ARCHITECTURE-PER-ENTRY-SPLIT.md §3.5 + §11`) with the architect-doc binding `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md:2345-2346` ("Pack-product canonical templates (project-side): for greenfield projects (init-project.sh per §9.3), the `_intro.md` and `_format.md`..."). PLAN §5.5 binding (verified at `PLAN-PER-ENTRY-SPLIT-BATCH-19.md:730`): `_intro.md` and `_format.md` ship from `project-template/docs/project/<stream>/` per integration parent §9.7.
  **Suggested remediation:** Append the integration-parent `§9.7` reference to the existing comment, or replace the bare `ARCHITECTURE-PER-ENTRY-SPLIT.md` references with their integration-parent equivalents.

- **Severity:** NIT
  **Location:** `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-166.md` §3 design note 4
  **Finding:** Citation: "Every missing-canonical-template precondition and every helper-failure path calls `fail_stage S11` matching the existing S11 error pattern (e.g., line 825 / 827 / 881 / 883). Exit code = 20 + 11 (clamped to 30) per the existing scheme." The arithmetic claim is correct (`fail_stage` at `scripts/init-project.sh:62-72` clamps `code > 30` to 30, so `S11 → 20+11=31 → 30`), but the framing "20 + 11" is a magic-number trail. A more durable wording is "S11 fail → exit 30 (clamped from 31 by `fail_stage`'s `> 30` guard)".
  **Evidence:** `scripts/init-project.sh:62-72`: `local n="${stage#S}"; local code=$(( 20 + n )); (( code > 30 )) && code=30; ...; exit "$code"`. The clamp truncates everything ≥ S10 to exit 30.
  **Suggested remediation:** Non-blocking. The IMPL-REPORT is post-commit history; correct in spirit, just brittle wording. Leave or tweak at fix-coder's discretion.

---

## §3 — Test-coverage assessment

**No new test runner was added by BD-166.** No assertions were added to existing test surface. The IMPL-REPORT §4 inventory confirms only one file modified (`scripts/init-project.sh`) plus the IMPL-REPORT itself; nothing in `scripts/tests/`. The smoke test in IMPL-REPORT §4.3 is reproducible (this review re-ran items 1, 2, 3, 4, 5, 6, 7 against a fresh temp directory; all PASS — the implementation works correctly today) but is a one-shot manual proof, not a CI gate.

**What should be covered by CI:**

1. **Greenfield init lands the seven canonical templates.** Per-stream presence assertions for `docs/project/backlog/{_rules.md,_intro.md}`, `docs/project/implementation-plan/{_rules.md,_intro.md}`, `docs/project/changelog/{_rules.md,_intro.md,_format.md}` — explicitly verifying the project-side asymmetry (changelog has `_format.md`; backlog and implementation-plan do not).
2. **Greenfield init writes the three regenerated mirrors at the correct paths.** Presence assertions at `docs/project/{BACKLOG.md,IMPLEMENTATION-PLAN.md,CHANGELOG.md}` — at the parent of the stream subdirs, not inside them.
3. **Mirror byte-identity claim.** `cmp` between `docs/project/BACKLOG.md` and `docs/project/backlog/_intro.md` (and the same for implementation-plan). For changelog, an alternate shape assertion (mirror contains `_intro.md` content + `\n---\n\n` separator + `_format.md` content).
4. **Empty seed `_toc.md` claim.** Per-stream assertion that `docs/project/<stream>/_toc.md` exists and contains the expected `(empty — no entries)` payload.
5. **Greenfield-only gating.** Negative test: an existing-* class fixture (e.g., `make_configured_target` extended with a non-empty `CLAUDE.md`) must NOT have its `docs/project/*.md` mirrors overwritten if pre-populated. (Today's runner uses `make_configured_target` only for `--update` tests.)
6. **Idempotency.** Two invocations of the helpers against the installed tree produce zero mtime churn (`cmp -s` short-circuit at `mirror-generate.sh:233` and `toc-regenerate.sh`).
7. **Persona contracts re-aligned.** Per MUST finding 2: both `contract-greenfield.sh` and `contract-migration.sh` extended to cover the new surface — the BD-116 NIT N1 stay-in-sync invariant currently fails.

The MUST findings are sized for one fix-coder pass. The Group 3 extension is ~30–50 lines of additional assertions; the persona-contract array extensions are ~10 lines per file. No new test scaffolding required.

---

## §4 — Observations (informational; not findings)

- **Observation O1 — README Repository Layout omits `project-template/docs/project/`.** The Repository Layout block at `README.md:85-135` enumerates `project-template/docs/pack/`, `project-template/skills/`, etc., but does NOT mention the new `project-template/docs/project/{backlog,implementation-plan,changelog}/` canonical-template directories that BD-167 ships and that BD-166 reads from. This is properly a BD-167 ownership concern (BD-167 created the directories; BD-166 only consumes them), but flagged here so triage doesn't lose it — if BD-167's retro review already raised it, ignore. If not, it's a real freshness gap because the Repository Layout is the authoritative reference per `CLAUDE.md` "Quick reference" + Repo structure section.

- **Observation O2 — Comment about `pe_is_interactive` divergence is correct but slightly off-target for greenfield.** `scripts/init-project.sh:997-1001` design note 5 states `</dev/null` detaches stdin so the mirror regenerator's interactive divergence branch (`pe_is_interactive`) does not fire. This is correct as documented at `mirror-generate.sh:249` (the prompt requires BOTH `[[ -t 0 ]] && [[ -t 1 ]]` per `_lib.sh:388-390`). However, the greenfield code path NEVER reaches the divergence check at all — the mirror is absent on first install, so `mirror-generate.sh:226` (`if [[ ! -f "$mirror_path" ]]; then ... mv "$new_tmp" "$mirror_path"; return 0; fi`) short-circuits before any divergence detection. The `</dev/null` is defense-in-depth (correct), but the design note's framing ("so the prompt does not fire") implies the prompt is even reachable on greenfield, which it isn't. Not a defect — just a doc-clarity opportunity for any future reader who follows the comment back to `mirror-generate.sh`.

- **Observation O3 — `--update` mode does not install the per-entry tree.** IMPL-REPORT §7.1 already surfaces this as a Pack Chat decision. Confirmed by reading `cmd_update` at `scripts/init-project.sh:1042-1175` and the `entries` array at `scripts/init-project.sh:1098+`: the `--update` path iterates an explicit hardcoded list of trinity / pack-product entries via `customization_preserve`, and none of those entries point at the new `project-template/docs/project/<stream>/` templates. A v11 client that ran init BEFORE this commit landed (i.e., a v11 client from an earlier Batch 19 commit ordering, or a manually-bootstrapped one) would NOT pick up the per-entry tree on a future `--update`. Practically rare given the in-batch landing, but worth noting because v11.0 itself is unlaunched — there is no "old v11 client" in the wild. This is forward-pointing future-tech-debt observation, not a current defect.

- **Observation O4 — `existing_classifier_copy` on the new templates: correctness verified by code-walk.** Per IMPL-REPORT §5 A6 + design note 3 + comment at `scripts/init-project.sh:898-902`, an existing-* re-run that has a customized `_rules.md`/`_intro.md`/`_format.md` would route through `existing_classifier_copy` (the `$copy_fn` indirection at `scripts/init-project.sh:806-807`). Per `scripts/init-project.sh:98-123` + `scripts/lib/three-way.sh:99-101`: if `theirs` and `ours` both exist and differ (base absent), `three_way_classify` returns `project-shadows-new-pack`, which writes a `.pack-template` sidecar at `${dst}.pack-template` and surfaces an `info` line. BD-088 contract honored. No active defect. The defense is partial because (a) sub-step 7 is greenfield-only so the mirrors won't get clobbered on existing-* re-run, but (b) sub-step 6 DOES run for existing-* re-runs, so a customized `_rules.md` gets a sidecar — correct BD-088 behavior.

- **Observation O5 — `_intro.md` content itself says "DO NOT EDIT THIS FILE — it is regenerated".** Verified at `project-template/docs/project/backlog/_intro.md:1`. The file is concatenated verbatim into the mirror by `mirror-generate.sh:108-112`, so the regenerated mirror correctly carries the warning. But `_intro.md` *itself* is NOT regenerated — it's a pack-shipped canonical template. The line-1 warning is semantically wrong for readers of `_intro.md` (and right for readers of the mirror). This is a BD-167 concern (BD-167 ships the template content). Flagged here only because BD-166's smoke verification quotes the line back as part of the mirror byte-identity check (§4.3 item 4 of the IMPL-REPORT). Not a BD-166 defect.

- **Observation O6 — Sub-step 7's stream tuple definition mirrors BD-165 (`scripts/lib/migrate-v10-to-v11/decompose.sh:145-148`).** The triple-pipe-delimited tuple shape is intentional symmetry with the v10→v11 migrator per integration parent §9.3 (helper reuse — same call sites). The code comment at `scripts/init-project.sh:981-985` is accurate. No defect; the architect's "three call sites" promise (v10→v11 migrator + init-project.sh + future tracker transitions) is honored — confirmed by reading `_lib.sh` public API at `scripts/lib/per-entry/_lib.sh:26-34`: `per_entry_regenerate_mirror` and `per_entry_regenerate_toc` are exactly the public names BD-166 sources and invokes.

---

## §5 — Definition-of-Done verification

Per PLAN §5.5 "Verification gate":

1. **`bash scripts/validate-pack.py` PASSES (existing 31 checks).** PASS at HEAD `c0723b7` — confirmed by re-running (`PASSED — all checks clean`). Note: the check count is now 35 (Checks 32/33/34 added by BD-168 + Check 35 phase-task per BD-106), but the gate's intent (validator green) is satisfied.
2. **`bash scripts/test-init-project.sh` PASSES (existing test suite).** PASS — confirmed by re-running (`Passed: 34 / Failed: 0`). The 34/34 baseline is preserved, but this same passing status is exactly what MUST finding 1 highlights as insufficient: the runner doesn't cover the new functional surface.
3. **Manual integration test — `bash scripts/init-project.sh /tmp/test-greenfield-v11.0` produces:**
   - `docs/project/backlog/_rules.md`, `_intro.md`, `_toc.md` (empty seed) — no `TD-NNN.md` entry files. **PASS** (reproduced; see §3).
   - `docs/project/implementation-plan/_rules.md`, `_intro.md`, `_toc.md` — no `phase-N.md` files. **PASS**.
   - `docs/project/changelog/_rules.md`, `_intro.md`, `_format.md`, `_toc.md` — no entry files. **PASS**.
   - `docs/project/BACKLOG.md` regenerated empty mirror containing only `_intro.md` content. **PASS** (`cmp` byte-identical).
   - `docs/project/IMPLEMENTATION-PLAN.md` regenerated empty mirror. **PASS** (`cmp` byte-identical).
   - `docs/project/CHANGELOG.md` regenerated empty mirror (with project-changelog `_intro.md` + `\n---\n\n` + `_format.md` shape per `mirror-generate.sh:155-162`). **PASS** (separator at expected location; `_format.md` header present).

Per PLAN §5.5 "Constraints (architect-doc bindings)":

| # | Binding | Verified |
|---|---|---|
| C1 | Stage extension preferred over new stage per integration parent §8.17 + §18.1 #5 recommendation | **PASS** — `stage_s11_v11_artifacts` extended in place; no `stage_s11b_*` introduced. |
| C2 | Mirror regenerator MUST handle empty input naturally per integration parent §9.3 (no special "greenfield empty mirror" template) | **PASS** — BD-164 helpers untouched; greenfield empty input takes the "no prior mirror → write fresh" branch at `mirror-generate.sh:226-231`; the resulting byte-identical `_intro.md`-only mirror is exactly what §9.3 prescribed. |
| C3 | Helper reuse pattern preserved per integration parent §9.3 (same BD-164 helpers serve three call sites) | **PASS** — call-site code at `scripts/init-project.sh:968-979` sources `_lib.sh` + `mirror-generate.sh` + `toc-regenerate.sh` and invokes `per_entry_regenerate_mirror` + `per_entry_regenerate_toc` — public-API contract from `scripts/lib/per-entry/_lib.sh:26-34` honored verbatim. Three call sites now realized: v10→v11 migrator (BD-165), init-project.sh (this commit), test surface (BD-164 internal tests). Tracker-mode transitions per §5.6 remain a future call site. |
| C4 | `_intro.md` and `_format.md` ship from `project-template/docs/project/<stream>/` per integration parent §9.7 (init copies, does not generate) | **PASS** — sub-step 6 uses `$copy_fn` exclusively (`scripts/init-project.sh:916-936`); no template generation. The hard precondition checks at `scripts/init-project.sh:906-907` + per-file checks at `:912-915, :920-923, :928-933` honor PLAN §10.6 R-6 — fail-fast with `fail_stage S11` if BD-167's canonical templates are absent. |

Per PLAN §5.5 "Architect-doc planner-deferred items":

- **Disposition: fold into `stage_s11_v11_artifacts` or add `stage_s11b_per_entry_tree`.** Folded into `stage_s11_v11_artifacts` per planner final recommendation (PLAN §10.6 R-6). **CORRECT** — no defect.

**Definition-of-Done summary: BD-166's plan-level success criteria are functionally met. The shortfall is at the CI-coverage layer (test-not-in-CI heuristic) and the persona-contract stay-in-sync invariant, both captured in §2 MUST findings.**

---
