# PLAN — BD-228: Push-Time Manifest Regeneration Method + Enforcing Check

**Author:** pack-planner (read-only planning pass)
**Date:** 2026-06-17
**Regime:** IN-PLACE in MAIN checkout (`/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`), branch `v11-dev`.
**Pack repo HEAD at plan time:** `3bad276` (record below; design was authored at `1143267` — delta re-verified, see EB-0).
**Output:** this doc only; read-only otherwise; no git state changes.
**Implements:** the APPROVED design `/tmp/handoff-bd226-manifest-method/DESIGN-MANIFEST-PUSH-METHOD.md` (read in full). BD entry: `backlog/BD-228.md`.
**Scope discipline:** this is a PLAN of an approved design. I do NOT redesign. Two genuine gaps the design under-enumerated are FLAGGED in §9 (not silently changed) — both are mechanical cross-commit couplings, not design forks; I fold them into the commit sequence and call them out for the coder + user.

---

## 0. One-line goal

Ship `scripts/manifest-sync.sh` (push-time, regen-iff-a-fixture-input-changed), validate-pack Check 62 (cheap structural manifest screen), both test-covered; KEEP the existing CI `build.sh --verify` as the authoritative SHA gate; REMOVE the per-commit RC9 prose obligation across 6 surfaces, replaced by a one-line pointer at the tool+check.

---

## 1. Regime + delta self-verification (Empirical-Evidence Blocks)

### EB-0 — plan-time HEAD + design-time delta (design's EBs still hold)

- **Command:**
  ```
  pwd ; git rev-parse --short HEAD ; git rev-parse --abbrev-ref HEAD
  git log --format="%h|%s" 1143267..HEAD
  git log --format="%h|%s" 1143267..HEAD -- test-fixtures/manifest.txt
  ```
- **Output (verbatim):**
  ```
  /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev
  3bad276
  v11-dev
  3bad276|feat: v11 — BD-221 C11 — Gemini→Antigravity: client setup/migration docs (project-only)
  d32c238|feat: v11 — BD-221 C8 — Gemini→Antigravity: pack-ops docs + agent-migration prose (pack-only)
  62d689e|docs: v11 — BD-228 open: push-time manifest regeneration method + enforcing check (pack-only)
  (manifest range: empty — no commit since 1143267 touched test-fixtures/manifest.txt)
  ```
- **HEAD-SHA:** `3bad276`
- **Interpretation:** MAIN checkout confirmed (not a `worktree-agent-*` path). Three commits since the design's `1143267`; NONE touched the manifest, so the design's EB-1/EB-2/EB-4/EB-7 manifest facts are unchanged. The BD-228-open commit `62d689e` is the BD entry only. The two BD-221 commits touched `project-template/` (C11, project-only) and `pack-ops/` (C8, pack-only) — neither changes the validator structure this plan depends on.
- **Conclusion:** SUPPORTED — the design's grounding holds at `3bad276`; the plan proceeds on the live tree.

### EB-1 — baseline is GREEN (default validate-pack) at plan time

- **Command:** `python3 scripts/validate-pack.py ; echo exit=$?` (default, non-DEEP)
- **Output (verbatim, tail):**
  ```
  ============================================================
  PASSED — all checks clean
  validate-pack default exit=0
  ```
- **HEAD-SHA:** `3bad276`
- **Interpretation:** the tree is green before BD-228; every per-commit gate in this plan is measured against this clean baseline.
- **Conclusion:** SUPPORTED.

### EB-2 — highest check is 61; Check 62 is the next number; registry expected-count is 59 (runtime-confirmed)

- **Command:**
  ```
  grep -oE 'Check [0-9]+' scripts/validate-pack.py | grep -oE '[0-9]+' | sort -n | tail -1
  grep -n "CHECK_REGISTRY_EXPECTED_COUNT = " scripts/validate-pack.py
  python3 scripts/validate-pack.py --only-check 59
  ```
- **Output (verbatim, load-bearing):**
  ```
  61
  490:CHECK_REGISTRY_EXPECTED_COUNT = 59
  OK: Check 59 — CHECK_REGISTRY has 59 entr(y/ies) (== CHECK_REGISTRY_EXPECTED_COUNT); ...
  ```
- **HEAD-SHA:** `3bad276`
- **Interpretation:** the next free check number is **62** (matches the design). The registry holds **59** runtime entries (57 integer-numbered tuples + 2 `(None, "check_issue_template_forms"...)` / `(None, "check_template_archive_v11"...)` entries that my integer-regex first missed — recounted via the live `--only-check 59` run). Adding Check 62 to the registry makes 60, so **`CHECK_REGISTRY_EXPECTED_COUNT` MUST bump 59 → 60 in the SAME commit** or Check 59 fails. This coupling is NOT in the design §5 table — FLAGGED in §9 (G1) and folded into C2.
- **Conclusion:** SUPPORTED.

### EB-3 — helpers the design reuses all exist; the per-check-test wiring is a NAME convention swept by glob

- **Command:**
  ```
  grep -n "def _fixture_names_from_build_sh\|def _commits_to_walk\|def _commit_paths" scripts/validate-pack.py
  grep -n "def check_ci_workflow_wires_per_check_tests\|def check_check_registry_completeness" scripts/validate-pack.py
  ls scripts/tests/test-validate-pack-check-61.sh
  ```
- **Output (verbatim, load-bearing):**
  ```
  6714: _fixture_names_from_build_sh (parses readonly FIXTURE_NAMES=( ... ) in build.sh)
  4023: def _commits_to_walk()
  4072: def _commit_paths(sha)
  6553: def check_ci_workflow_wires_per_check_tests  (== Check 42; allowlist validity, NOT per-check-test presence)
  6879: def check_check_registry_completeness        (== Check 59; expected-count guard)
  scripts/tests/test-validate-pack-check-61.sh  (exists)
  ```
- **HEAD-SHA:** `3bad276`
- **Interpretation:** `_fixture_names_from_build_sh()` (line 6714), `_commits_to_walk()` (4023), `_commit_paths()` (4072) all exist — Check 62 reuses `_fixture_names_from_build_sh()` (no new git calls; the structural screen needs no range walk). The per-check test is wired by the NAMING convention `scripts/tests/test-validate-pack-check-NN.sh` (swept by the `scripts/tests/*.sh` disk glob — EB-5); Check 42 validates the *allowlist*, not that each check HAS a per-check test (there is no presence-enforcing check — confirmed: no `test-validate-pack-check` presence check exists). So a Check-62 per-check test is a CONVENTION obligation (enumerate-encoding-surfaces), not a gate that fails without it. It still MUST be authored (the design §7.2 requires it).
- **Conclusion:** SUPPORTED.

### EB-4 — the manifest is scope-neutral for Check 36; pack-root trinity is pack-chat-only; bijection is Check 45

- **Command:**
  ```
  sed -n '4002,4005p' scripts/validate-pack.py          # _SCOPE_NEUTRAL_GENERATED_PATHS
  grep -n "def check_pack_memory_rationale_bijection" scripts/validate-pack.py
  grep -n "CLAUDE.md.*AGENTS.md.*GEMINI.md\|root and .project-template" pack-ops/PACK-AGENTS.md
  ```
- **Output (verbatim, load-bearing):**
  ```
  _SCOPE_NEUTRAL_GENERATED_PATHS = frozenset({ "test-fixtures/manifest.txt", })
  6995: def check_pack_memory_rationale_bijection   (== Check 45)
  PACK-AGENTS.md:175: - `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` (root and `project-template/`)  [pack-chat-only list]
  ```
- **HEAD-SHA:** `3bad276`
- **Interpretation:** (a) the regenerated `test-fixtures/manifest.txt` is exempt from Check 36 scope-honesty — so a manifest-bearing commit does NOT need to drop/qualify a `pack-only` keyword on the manifest's account. (b) Pack-root trinity (CLAUDE/AGENTS/GEMINI.md) is on the pack-chat-only list — but a SUBSTANTIVE rewrite of landed trinity content is MAJOR → coder (per `pack-chat-minor-edits-only`). (c) Check 45 enforces the rule↔rationale-section bijection: the RC9 bullet keeps its `[rationale: regenerate-manifest-v11-surface]` tag AND the rationale file keeps its `## regenerate-manifest-v11-surface` heading, so the bijection is NET-UNCHANGED across C3 (no slug added/removed) — confirmed safe.
- **Conclusion:** SUPPORTED.

### EB-5 — the new test auto-wires by glob; the new tool does NOT collide with the test glob

- **Command:**
  ```
  grep -n "parse_wired_tests\|test\*.sh\|fixture-dependent\|--emit-matrix" scripts/lib/ci-shard-plan.py | head
  cat scripts/ci-test-wiring-allowlist.txt   # (1 live entry: tracker-bd204 oracle)
  ```
- **Output (verbatim, load-bearing):**
  ```
  disk KEEP set = {scripts/test*.sh + scripts/tests/*.sh + scripts/tests/fixture-dependent/*.sh} − allowlist
  allowlist: exactly 1 entry (scripts/tests/tracker-bd204-lossless-roundtrip-test.sh, live-GH oracle)
  CI plan job: matrix=$(python3 scripts/lib/ci-shard-plan.py --emit-matrix)  (disk-derived at run time)
  ```
- **HEAD-SHA:** `3bad276`
- **Interpretation:** `scripts/tests/manifest-method-test.sh` matches `scripts/tests/*.sh` ⇒ auto-discovered + LPT-bin-packed into a shard on next push (no manual wiring, no allowlist edit). `scripts/tests/test-validate-pack-check-62.sh` likewise auto-wires. The tool `scripts/manifest-sync.sh` does NOT begin with `test` and is not under `scripts/tests/` ⇒ NOT swept into the test set (no allowlist entry needed). A shared lib at `scripts/lib/manifest-inputs.sh` is likewise not in the test glob. The CI shard matrix RE-SHARDS automatically on next push to absorb the 2 new tests (EB-9 of the design).
- **Conclusion:** SUPPORTED.

### EB-6 — the 6 RC9 prose surfaces exist at these exact locations (re-measured at plan HEAD)

- **Command:**
  ```
  grep -n "Regenerate test-fixtures/manifest.txt on every v11-surface" CLAUDE.md AGENTS.md GEMINI.md
  grep -n "## regenerate-manifest-v11-surface\|HELP-FRAGMENT-TRACKER" pack-ops/PACK-MEMORY-RATIONALE.md
  grep -n "manifest" pack-ops/PACK-CHAT.md
  ```
- **Output (verbatim, load-bearing):**
  ```
  CLAUDE.md:568  AGENTS.md:527  GEMINI.md:504   (RC9 bullet; byte-identical across all three — trinity parity intact)
  pack-ops/PACK-MEMORY-RATIONALE.md:509  ## regenerate-manifest-v11-surface
  pack-ops/PACK-MEMORY-RATIONALE.md:519  pack-ops/HELP-FRAGMENT-TRACKER.md (the STALE input claim, inside the RC9 section)
  pack-ops/PACK-CHAT.md:433  | 6 | `test-fixtures/manifest.txt` regen if a v11-surface path changed | existing manifest CI gate |
  pack-ops/PACK-CHAT.md:435  - **Order:** ... + manifest (5) ... → manifest regen (6) last.
  ```
- **HEAD-SHA:** `3bad276`
- **Interpretation:** all 6 in-scope surfaces are present and located. The trinity bullet is byte-identical in all three files (clean lock-step baseline). The rationale `HELP-FRAGMENT-TRACKER.md`-is-an-input claim sits at line 519 INSIDE the RC9 section (the design EB-5 proved this stale — it is `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` that init copies, not the `pack-ops/` copy). NOTE: there is ALSO a `HELP-FRAGMENT-TRACKER.md` mention at rationale line 170, but that is in a DIFFERENT bullet (the "run per-check tests" worked-example incident history) — it is NOT an RC9 surface and is NOT edited by this plan.
- **Conclusion:** SUPPORTED.

### EB-7 — no manifest-sync artifacts pre-exist; design dest doc absent

- **Command:** `ls scripts/manifest-sync.sh scripts/lib/manifest-inputs.sh scripts/tests/manifest-method-test.sh scripts/tests/test-validate-pack-check-62.sh maintenance-docs/v11-implementation/DESIGN-MANIFEST-PUSH-METHOD.md`
- **Output (verbatim):** all five report `No such file or directory`.
- **HEAD-SHA:** `3bad276`
- **Interpretation:** all new files are clean net-new ADDs; the design doc is not yet landed (archival is part of this BD — §5, C1).
- **Conclusion:** SUPPORTED.

---

## 2. Affected files (complete blast radius, categorized)

Mirrors design §5; columns add the committing actor + the commit it lands in.

| # | Path | Change | Category | Actor | Commit |
|---|------|--------|----------|-------|--------|
| 1 | `scripts/manifest-sync.sh` | create (~120-180 ln bash) | ADD | coder | C1 |
| 2 | `scripts/lib/manifest-inputs.sh` | create shared input SoT (~30 ln) | ADD | coder | C1 |
| 3 | `scripts/tests/manifest-method-test.sh` | create self-provisioned test | ADD | coder | C1 |
| 4 | `test-fixtures/manifest.txt` | regen ONCE at BD-228 push (this BD touches `scripts/`) | REGEN | orchestrator (runs the tool) | at push (see §3) |
| 5 | `maintenance-docs/v11-implementation/DESIGN-MANIFEST-PUSH-METHOD.md` | land the design doc | ADD | coder | C1 |
| 6 | `scripts/validate-pack.py` | add `check_manifest_structural()` + registry entry + bump `CHECK_REGISTRY_EXPECTED_COUNT` 59→60 | ADD/EDIT | coder | C2 |
| 7 | `scripts/tests/test-validate-pack-check-62.sh` | create per-check test | ADD | coder | C2 |
| 8 | `CLAUDE.md` (line 568-575) | shrink RC9 bullet → pointer | EDIT | coder | C3 |
| 9 | `AGENTS.md` (line 527-534) | same, lock-step | EDIT | coder | C3 |
| 10 | `GEMINI.md` (line 504-511) | same, lock-step | EDIT | coder | C3 |
| 11 | `pack-ops/PACK-MEMORY-RATIONALE.md` (§ 509-563) | rewrite HOW; keep WHY; fix stale input claim (line 519) | EDIT (MAJOR) | coder | C3 |
| 12 | `pack-ops/PACK-CHAT.md` (line 433, 435) | update propagation row 6 + order note | EDIT (MAJOR) | coder | C3 |
| 13 | out-of-repo memory cache `feedback_manifest_regen_on_v11_surface.md` | revise recall + pointer | EDIT | Pack-Chat-direct (NOT coder) | post-C3 upkeep |

**Explicitly UNCHANGED (bounded out — design §5):** `test-fixtures/build.sh` (the `--all --clean` + `--verify` already do the job); `.github/workflows/validate-pack.yml` (the `build.sh --verify` step already exists; manifest-sync runs at the ORCHESTRATOR's push, never in CI); `scripts/lib/ci-shard-plan.py` (new test auto-wires; new tool is not a test); `scripts/ci-test-wiring-allowlist.txt` (no new allowlist entry — the new test is WIRED, not stripped); `_SANCTIONED_PACK_SIDE_SHIPPED` / install-map (tool does not ship); determinism pins; shard matrix; the worktree model.

---

## 3. Self-hosting manifest handling (the chicken-and-egg — exact procedure)

BD-228 touches `scripts/` (a fixture input under the new predicate). Under the new regime the manifest is regenerated AT PUSH by the tool — but BD-228 IS the commit that introduces the tool. Resolution:

- **DURING BD-228's commits (C1/C2/C3): do NOT carry a per-commit manifest.** The coder does NOT run `build.sh --all --clean` per commit and does NOT stage `test-fixtures/manifest.txt` in C1/C2/C3. (This is the whole point — BD-228 retires the per-commit chore; dog-fooding it means BD-228 itself stops doing the per-commit regen.) RC9 prose is still technically live until C3 lands, but the user-directed self-hosting transition (rule `regenerate-manifest-v11-surface` §9-R9) authorizes BD-228 to use the replacement on its own push. State this explicitly to the coder so no coder "helpfully" regenerates per-commit.
- **AT BD-228's PUSH (orchestrator, after C1/C2/C3 are all locally committed):** the tool exists (landed in C1). The orchestrator runs:
  ```
  bash scripts/manifest-sync.sh            # over the unpushed range = C1..C3 (+ any batch siblings)
  #  scripts/ changed (C1 tool/test, C2 validator) ⇒ regen_needed = true
  #  → build.sh --all --clean runs ONCE; if manifest.txt changed on disk → exit 10 (MANIFEST-CHANGED)
  ```
  - If exit 10: orchestrator commits the regenerated manifest with user approval — a SEPARATE trailing commit `chore: v11 — regen test-fixtures/manifest.txt at push (BD-228 fixture inputs changed)` (the batch-of-3 shape; design §2.5 amend-vs-trailing is an orchestrator choice — recommend the trailing commit here because the push batches 3 commits and the manifest reflects their cumulative state). The manifest is scope-neutral for Check 36 (EB-4), so the trailing commit may carry no keyword or `pack-only` safely.
  - If exit 0 (MANIFEST-NOOP — the scripts edits happen not to change any fixture SHA, e.g. a new top-level `scripts/manifest-sync.sh` that init-project.sh does NOT copy into fixtures): NO manifest commit needed; push as-is.
- **The coder must NEVER hand-edit `test-fixtures/manifest.txt`.** Run the tool; commit its output.

**Likely outcome prediction (informational, not a gate):** the BD-228 new files are `scripts/manifest-sync.sh`, `scripts/lib/manifest-inputs.sh`, `scripts/tests/manifest-method-test.sh`, `scripts/tests/test-validate-pack-check-62.sh`, and an EDIT to `scripts/validate-pack.py`. Of these, `init-project.sh` copies only `scripts/pack-help.sh` + `scripts/lib/detect.sh` (+ `scripts/lib/per-entry/*.sh` sourced by build.sh) into fixtures (design EB-5/EB-9). NONE of BD-228's new/edited scripts are in that copied set. **So the most likely result is MANIFEST-NOOP (exit 0) — no manifest commit.** BUT: the tool's PREDICATE (all-`scripts/`-minus-tests-minus-the-tool) WILL match `scripts/validate-pack.py` and `scripts/manifest-sync.sh`, so the tool WILL run `build.sh --all --clean` once and then find an empty diff ⇒ MANIFEST-NOOP. This is the designed "input matched, manifest unchanged" path and is correct. The orchestrator follows whichever exit the tool reports; do not assume.

---

## 4. Commit sequence (finalized)

Three commits, strict dependency order C1 → C2 → C3. Each is independently `validate-pack`-green AND keeps the full CI battery green at its HEAD. The design's §8 draft grouping is adopted with the couplings folded in.

### C1 — the method + shared SoT + its test + the design doc  · scope: `pack-only`

**Files:** `scripts/manifest-sync.sh` (NEW), `scripts/lib/manifest-inputs.sh` (NEW), `scripts/tests/manifest-method-test.sh` (NEW), `maintenance-docs/v11-implementation/DESIGN-MANIFEST-PUSH-METHOD.md` (NEW — archival per success-criterion 6).

**What the coder builds (mechanical, from design §2 + §7.1):**
- `scripts/lib/manifest-inputs.sh` — the SINGLE source of truth for the fixture-input predicate. A small sourceable lib exposing the input globs + deny globs as shell arrays (or a function `manifest_input_globs` / `manifest_deny_globs`), so BOTH `manifest-sync.sh` AND Check 62 can reference the same set. **Decision (design §2.3): the predicate is the EXACT input set — `project-template/**`, `scripts/**` MINUS the test set (`scripts/test*.sh`, `scripts/tests/**`) MINUS the tool itself (`scripts/manifest-sync.sh`) and the SoT lib (`scripts/lib/manifest-inputs.sh`), `test-fixtures/build.sh`, and exactly `supporting-docs/METHODOLOGY.md` + `supporting-docs/INSTALL-PROCEDURES.md`.** Pick = all-`scripts/`-minus-tests-minus-tool (design's resolved fork; do NOT re-litigate). Excludes `pack-ops/` and `maintenance-docs/` (NOT inputs — design EB-5).
- `scripts/manifest-sync.sh` — functions `_resolve_push_range` (`@{upstream}..HEAD`; fallback `origin/<branch>..HEAD`; fallback `HEAD` tip + warn), `_fixture_inputs_changed` (union `git diff --name-only <range>` ∩ input globs − deny globs; set test, commit-count-agnostic), `_regen_manifest` (`bash test-fixtures/build.sh --all --clean` ONCE, then `git diff --quiet -- test-fixtures/manifest.txt`), `main`. Exit contract (design §2.7): `0`=SKIP(no input changed)/NOOP(input changed, manifest unchanged); `10`=MANIFEST-CHANGED; `1`=error. NEVER stages/commits/pushes (agents/tools never commit). Stdout tokens: `MANIFEST-SKIP` / `MANIFEST-NOOP` / `MANIFEST-CHANGED` / error.
- Pack-repo code-comment deferrals (if any) use the typed `# TODO(scope): TD-TBD — title` format — no plain `# TODO/FIXME` (rule `pack-repo-code-comment-deferrals`).
- `scripts/tests/manifest-method-test.sh` — self-provisioned scratch `/tmp` clone (rule "Test infra is self-provisioned"; never touch the real tree/manifest). Cases (design §7.1): POSITIVE (input change → exit 10 + MANIFEST-CHANGED + manifest differs); NEGATIVE no-input (`maintenance-docs/`/`pack-ops/`-only commit → exit 0 + MANIFEST-SKIP + build.sh NOT invoked, asserted via a spy/sentinel); NEGATIVE comment-only input edit → exit 0 + MANIFEST-NOOP; IDEMPOTENCY (twice → both 0, unchanged); RANGE/commit-count-agnostic (1 vs 3 input commits → same final manifest + build.sh ran exactly once in the 3-commit case); PREDICATE-DRIFT screen (assert the globs include `project-template/`, `scripts/`-minus-tests, `test-fixtures/build.sh`, the 2 named `supporting-docs/` files; EXCLUDE `pack-ops/` + `maintenance-docs/`).
- Archive the design doc verbatim to `maintenance-docs/v11-implementation/DESIGN-MANIFEST-PUSH-METHOD.md` (the BD entry References already points here — EB-6/BD-228 line 20).

**Dependency order:** C1 first — C2's Check 62 sources `manifest-inputs.sh` (the shared SoT), so the SoT must exist before C2. (If the coder prefers, the SoT could land in C2; but the tool in C1 also needs it, so C1 is the natural home — keep it in C1.)

**Independently verifiable because:** the tool + test are self-contained; `manifest-method-test.sh` passes standalone; `validate-pack` stays green (no validator change yet — the new tool/lib/test are not test-glob-swept into any check that would change a count, except the registry/shard which auto-derive — see coupling X3). No manifest staged in C1 (self-hosting — §3).

**C1 gate (verify-full-ci-suite):**
- `bash scripts/tests/manifest-method-test.sh` → PASS.
- `python3 scripts/validate-pack.py` (default) → exit 0; `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` (DEEP) → exit 0.
- Confirm Check 42 still green (the new test is WIRED by glob, not stripped → allowlist unchanged → Check 42 passes; the new tool is not test-glob-shaped → no allowlist needed).
- Confirm Check 60 / `ci-shard-plan.py --emit-matrix` re-shards cleanly with the new `manifest-method-test.sh` present (no manual wiring; coverage assertion green).
- Run the FULL wired battery as CI would (the 3 new-test glob members + existing) — or at minimum run `ci-shard-plan.py --emit-matrix` to confirm the matrix builds, plus the per-check + integration tests already in the tree to confirm no regression.

### C2 — Check 62 + per-check test + expected-count bump  · scope: `pack-only`

**Files:** `scripts/validate-pack.py` (EDIT: add `check_manifest_structural()`, register as Check 62, bump `CHECK_REGISTRY_EXPECTED_COUNT` 59→60), `scripts/tests/test-validate-pack-check-62.sh` (NEW).

**What the coder builds (mechanical, from design §3.2 + §7.2):**
- `check_manifest_structural()` — Check 62, a CHEAP structural well-formedness screen on `test-fixtures/manifest.txt`: (a) exactly 6 data rows (skipping comment/blank lines); (b) row names == `_fixture_names_from_build_sh()` (existing helper, line 6714) as a SET; (c) each row's SHA matches `^[0-9a-f]{40}$` (or a documented sentinel). Pure file-read + regex; NO fixture rebuild, NO subprocess, NO subprocess-per-entry, NO whole-real-tree scan. Lenient SKIP if build.sh / FIXTURE_NAMES absent (mirror the existing Check 61 lenient pattern). Route through `run_check` (per-check WARN budget) like every other check. **It does NOT assert SHA-correctness** — that authority stays `build.sh --verify` in CI (design §3.1; avoids the comment-only-edit false positive).
- **Registry + count (the FLAGGED coupling G1):** add `(62, "check_manifest_structural", check_manifest_structural, W),` to `_build_check_registry()` (alongside 58/59/60/61 at the registry tail) AND bump `CHECK_REGISTRY_EXPECTED_COUNT = 59` → `60` (EB-2). Both edits in C2, same commit. Missing the count bump fails Check 59 immediately.
- `scripts/tests/test-validate-pack-check-62.sh` — per-check test (design §7.2): build a malformed manifest in a scratch fixture (5 rows; OR a garbage SHA; OR a wrong/missing fixture name) and assert Check 62 FAILs; build a well-formed manifest and assert Check 62 PASSes. Use the `--only-check 62` selector (BD-219 C1) so the test exercises Check 62 in isolation. Follow the existing `test-validate-pack-check-NN.sh` convention (model on `test-validate-pack-check-61.sh`). Auto-wires by glob (EB-5) — no allowlist/shard edit.

**Dependency order:** C2 after C1 (Check 62 sources `scripts/lib/manifest-inputs.sh`? — design §3.2 says Check 62 reuses the SAME `manifest-inputs` SoT for its predicate *concept*, BUT the chosen Check-62 = structural-screen does NOT actually evaluate the input predicate (it only checks the manifest's own shape). So Check 62 does NOT strictly need `manifest-inputs.sh`. KEEP C1-before-C2 anyway for logical cohesion + so the tool/SoT exist when the validator references them in comments. If the coder finds Check 62 needs no `manifest-inputs.sh` import, that is fine — the SoT is still used by the tool + the predicate-drift test.)

**Independently verifiable because:** Check 62 + its per-check test are self-proving (`--only-check 62` PASS on well-formed, FAIL on malformed); Check 59 passes with the bumped count; the full default+DEEP run stays green.

**C2 gate (verify-full-ci-suite):**
- `python3 scripts/validate-pack.py --only-check 62` → exit 0 on the real (well-formed) manifest.
- `bash scripts/tests/test-validate-pack-check-62.sh` → PASS (both malformed-FAIL and well-formed-PASS legs).
- `python3 scripts/validate-pack.py --only-check 59` → still OK (count == 60).
- `python3 scripts/validate-pack.py` (default) + `PACK_VALIDATE_DEEP=1 ...` (DEEP) → exit 0.
- Re-confirm the per-check WARN budget: Check 62 must not exceed the per-check timing budget (it is a 6-row file read — trivially under). `run_check` times it (`ci-check-runtime-compounding`).
- Full wired battery green (the new per-check test auto-sharded).

### C3 — RC9 prose removal/replacement  · scope: `pack-only`

**Files:** `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` (trinity lock-step), `pack-ops/PACK-MEMORY-RATIONALE.md`, `pack-ops/PACK-CHAT.md`.

**Scope-keyword decision:** **`pack-only`.** All five files are pack-ops surfaces (no `project-template/` or `supporting-docs/` paths touched) ⇒ Check 36 `pack-only` passes. (NOT `pack-chat-only`: while these files ARE on the pack-chat-only LIST, the commit is authored by a coder — the `pack-chat-only` keyword asserts a Pack-Chat-direct edit, which this is not; and the keyword's permitted-paths gate is about WHICH files, both keywords would pass the path test, but `pack-only` is the honest scope claim for a coder commit touching pack-ops files. Use `pack-only`.)

**What the coder builds (mechanical, from design §4):**
- Trinity ×3 — replace the per-commit RC9 bullet (CLAUDE.md 568-575 / AGENTS.md 527-534 / GEMINI.md 504-511) with the §4.2 pointer, BYTE-IDENTICAL across all three (trinity rule; the baseline is already byte-identical — EB-6). The pointer keeps the `[rationale: regenerate-manifest-v11-surface]` tag (bijection — EB-4/Check 45). Pointer text (design §4.2): manifest is push-time + tool-enforced, NOT a per-commit chore; regenerated only at push only when a fixture input changed by `scripts/manifest-sync.sh`; correctness enforced by CI `build.sh --verify` + validate-pack Check 62; do NOT regenerate per-commit.
  - `[roles:]` tag — design §4.3 recommends `[roles: universal]` (the push-time regen is an orchestrator action, no longer a coder chore) but FLAGS it for planner/user. **PLANNER DECISION: use `[roles: universal]`** (any actor should know not to regen per-commit; the old `[roles: coder]` no longer fits since coders no longer do it). This is a mechanical token change inside the pointer; FLAGGED to user in §9-G2 for confirmation but not blocking (either value is internally consistent).
- `pack-ops/PACK-MEMORY-RATIONALE.md` (§ 509-563) — REWRITE the HOW-to-apply: from "before staging a commit … run `build.sh --all --clean` … stage the manifest" to "the push-time `manifest-sync.sh` regenerates iff a fixture input changed; correctness is enforced by CI `build.sh --verify` (authoritative SHA gate) + validate-pack Check 62 (cheap structural screen)." KEEP the incident WHY (the two CI-red incidents `667d2dd`/`4120d19` — valuable provenance; do NOT delete). FIX the stale input claim at line 519 (`pack-ops/HELP-FRAGMENT-TRACKER.md` is NOT an input — it is `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` that init copies; design EB-5). Keep the `## regenerate-manifest-v11-surface` heading verbatim (bijection — EB-4). Edit IN PLACE (rule `edit-in-place-not-full-rewrite`) — targeted section edits, not a file rewrite.
- `pack-ops/PACK-CHAT.md` (line 433, 435) — UPDATE propagation row 6 to reference `manifest-sync.sh` at push (not a per-commit regen step) and adjust the order note at line 435 (the "manifest regen (6) last" becomes "manifest is push-time via `manifest-sync.sh`, not a propagation-order step"). Targeted edit.

**Dependency order:** C3 last — the prose now POINTS AT the tool (C1) + the check (C2), so both must exist first for the pointer to be truthful. C3 also removes the obligation that BD-228 itself is dog-fooding away from (§3).

**Independently verifiable because:** prose-only pack-ops edits; trinity parity validated by Check 16/18/19; bijection by Check 45; no functional surface changes.

**C3 gate (verify-full-ci-suite):**
- `python3 scripts/validate-pack.py` (default) + DEEP → exit 0.
- Confirm Check 16 (trinity addenda H2) / Check 18 (trinity H2 parity) / Check 19 (no scaffolding comments) green — the pointer must be byte-identical across the three trinity files; run `bash scripts/tests/test-validate-pack-check-16.sh` + `-18.sh` + `-19.sh`.
- Confirm Check 45 (rule↔rationale bijection) green — `bash scripts/tests/test-validate-pack-check-45.sh` (the `[rationale: regenerate-manifest-v11-surface]` tag ↔ `## regenerate-manifest-v11-surface` heading both retained ⇒ net-unchanged).
- Full wired battery green.

### Post-C3 — Pack-Chat-direct memory-cache upkeep (NOT a coder commit, NOT in BD-228's commits)

The out-of-repo memory cache `~/.claude/projects/<slug>/memory/feedback_manifest_regen_on_v11_surface.md` is Pack Chat's OWN state (not pack-repo content) — Pack-Chat-direct edit, not a coder file (design §4.1 row 5; rule "What Pack Chat CAN edit directly → Memory files"). Pack Chat revises the recall line + MUST-READ pointer to aim at the tool+check (not the per-commit run) as upkeep AFTER C3 lands. This is an encoding surface (enumerate-encoding-surfaces) but lives outside the repo, so it is NOT a BD-228 commit — it is bookkeeping Pack Chat performs in lock-step. **List it for Pack Chat so it is not forgotten.**

---

## 5. Cross-commit couplings (exhaustive — the BD-221-lesson sweep)

| # | Coupling | Where it bites | Handled in |
|---|----------|----------------|------------|
| X1 | **Check 62 registry entry ⇒ `CHECK_REGISTRY_EXPECTED_COUNT` 59→60** | Check 59 FAILs if the count is not bumped in the same commit as the registry add (EB-2). | C2 — both edits same commit. FLAGGED G1 (design omitted this). |
| X2 | **Shared `manifest-inputs.sh` SoT** | The tool (C1), the predicate-drift test (C1), and the Check-62 design-intent (C2) reference one SoT; if it lived in two places they would drift. | C1 — single lib `scripts/lib/manifest-inputs.sh`; both consumers source it. |
| X3 | **New test ⇒ CI shard matrix re-derives** | `manifest-method-test.sh` (C1) + `test-validate-pack-check-62.sh` (C2) are swept by `scripts/tests/*.sh`; `ci-shard-plan.py --emit-matrix` re-shards on next push; Check 60 (shard coverage mirror) + the `tests-result` job must stay green. | Auto (no edit). Confirm green at C1 + C2 gates (EB-5). |
| X4 | **No allowlist edit** | The 2 new tests are WIRED (KEEP), not stripped; adding them to `ci-test-wiring-allowlist.txt` would be the forbidden "dodge a failing KEEP" anti-pattern. Check 42 validates the allowlist (entries must exist + be glob-shaped; KEEP set non-empty) — unchanged. | No edit. Confirm Check 42 green at C1/C2. |
| X5 | **Manifest regen self-hosting** | BD-228 touches `scripts/` ⇒ its own push must reconcile the manifest VIA THE NEW TOOL (not per-commit, not by hand). | At push (§3); orchestrator runs `manifest-sync.sh`, commits output iff exit 10. |
| X6 | **Rationale bijection (Check 45)** | The trinity pointer keeps `[rationale: regenerate-manifest-v11-surface]`; the rationale file keeps the `## regenerate-manifest-v11-surface` heading. Net slugs unchanged ⇒ bijection holds. If either side dropped the tag/heading, Check 45 FAILs. | C3 — both sides edited in the same commit; tag + heading retained. |
| X7 | **Trinity parity (Check 16/18/19)** | The pointer must be byte-identical across CLAUDE/AGENTS/GEMINI.md. | C3 — lock-step edit; gated by the three trinity per-check tests. |
| X8 | **Per-check-test convention (NOT a gate, but enumerate-encoding-surfaces)** | Check 62 must get `test-validate-pack-check-62.sh`. No check FAILs without it (EB-3), but the convention + reviewer enforce it. | C2 — authored with the check. |
| X9 | **Out-of-repo memory cache** | `feedback_manifest_regen_on_v11_surface.md` encodes the retired behavior; if not updated it drifts from trinity (trinity wins, but the cache misleads Pack Chat). | Post-C3 Pack-Chat-direct upkeep (§4). |
| X10 | **`maintenance-docs/` design-doc archival is NOT a fixture input** | Landing the design doc (C1) under `maintenance-docs/` does NOT trip the manifest predicate (EB-5: `maintenance-docs/` excluded) — so the doc archival does not, by itself, force a manifest regen. The `scripts/` edits in C1/C2 are what (may) trigger the push-time regen. | Informational — no action; confirms C1's doc archival is manifest-neutral. |

---

## 6. Encoding-surfaces lock-step (no asymmetric coverage)

Every surface that ENCODES the new behavior, paired with its coverage, all landed within BD-228:

| Behavior encoded | Primary surface | Coverage / parity surface | Commit |
|---|---|---|---|
| The push-time method | `scripts/manifest-sync.sh` | `scripts/tests/manifest-method-test.sh` | C1 |
| The fixture-input predicate (SoT) | `scripts/lib/manifest-inputs.sh` | predicate-drift case in `manifest-method-test.sh` | C1 |
| The structural screen | `check_manifest_structural()` (Check 62) | `scripts/tests/test-validate-pack-check-62.sh` | C2 |
| The registry membership | registry entry (62) | `CHECK_REGISTRY_EXPECTED_COUNT` bump + Check 59 | C2 |
| The retired per-commit rule | trinity ×3 pointer | Check 16/18/19 parity + their per-check tests | C3 |
| The WHY/provenance + corrected input claim | `PACK-MEMORY-RATIONALE.md` § | Check 45 bijection (tag ↔ heading) | C3 |
| The propagation order | `PACK-CHAT.md` row 6 + order note | (no automated check — reviewer verifies) | C3 |
| The memory recall (out-of-repo) | `feedback_manifest_regen_on_v11_surface.md` | (Pack-Chat-direct; reviewer/Pack-Chat verifies) | post-C3 |

The reviewer's job: confirm NO surface is updated without its pair (e.g., a check without its per-check test; a trinity edit not mirrored; a rationale rewrite that drops the heading).

---

## 7. Per-commit verification strategy (summary)

Every commit's gate runs, at minimum: `python3 scripts/validate-pack.py` (default) AND `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` (DEEP) → both exit 0; PLUS the new/affected per-check + method tests; PLUS the FULL wired CI battery (per `verify-full-ci-suite` — integration tests `test-v11-*.sh` + fixture-dependent tests, not only validate-pack). The new tests auto-wire into the CI shard matrix by glob (EB-5) — confirm `ci-shard-plan.py --emit-matrix` builds and Check 60 / `tests-result` stays green at C1 + C2.

- **C1:** `manifest-method-test.sh` PASS; default+DEEP green; matrix re-derives clean; Check 42/60 green.
- **C2:** `--only-check 62` green on real manifest; `test-validate-pack-check-62.sh` PASS (FAIL-on-malformed + PASS-on-wellformed); `--only-check 59` OK (count 60); default+DEEP green; Check-62 per-check WARN budget not exceeded.
- **C3:** default+DEEP green; trinity Check 16/18/19 per-check tests PASS; Check 45 bijection test PASS.

The coder emits its `PREFLIGHT: N/N ... HEAD <SHA> ...` line only after the in-scope edits + verification PASS (rule `preflight-stop-means-stop`).

**Note on the manifest at intermediate commits:** because BD-228 does NOT carry a per-commit manifest (self-hosting — §3), the COMMITTED manifest is unchanged through C1/C2/C3. Check 62 (structural) passes on the existing well-formed 6-row manifest at every intermediate commit. The authoritative SHA gate `build.sh --verify` runs only in CI at the PUSHED HEAD — which is correct after the orchestrator's push-time `manifest-sync.sh` reconciliation (§3). So every intermediate LOCAL commit is validate-pack-green; the SHA-correctness gate is satisfied at push. (This is exactly the regime BD-228 installs.)

---

## 8. Risks & open unknowns

- **R1 — Check 62 false-confidence.** Check 62 is a STRUCTURAL screen only; it does NOT prove SHA-correctness. The design is explicit that `build.sh --verify` remains the authority (§3.1). RISK: a reviewer/coder mistakes Check 62 for the correctness gate and weakens `build.sh --verify`. MITIGATION: the plan + check docstring state plainly that Check 62 is a screen, not the authority; do NOT touch the CI `build.sh --verify` step.
- **R2 — push-time tool is orchestrator-run, untested in CI.** `manifest-sync.sh` runs at the orchestrator's push, never in CI (it needs the unpushed range). Its correctness rides on `manifest-method-test.sh` (scratch-clone) + the `build.sh --verify` backstop catching any miss (design §6). RISK: a tool bug that under-detects an input change ships a stale manifest — but `build.sh --verify` catches it RED at push (design §6.2/6.3). Acceptable; the gate is the backstop.
- **R3 — predicate drift.** If `init-project.sh` later grows a copy site outside the declared input set, a commit touching only that new input would skip regen under the exact predicate → stale manifest → `build.sh --verify` RED (loud, attributable; remediation = add the dir to `manifest-inputs.sh`). Design §2.3b/§6.3 — accepted measure-then-bound posture.
- **R4 — `@{upstream}` unresolved.** On a branch with no upstream, `_resolve_push_range` falls back to `origin/<branch>..HEAD`, then to `HEAD` tip + warn. RISK: the tip-only fallback under-scopes a multi-commit push. MITIGATION: the warn surfaces it; `build.sh --verify` is the backstop. The test covers the range cases.
- **U1 — exact `CHECK_REGISTRY_EXPECTED_COUNT` post-value.** Measured 59 → bump to **60** (EB-2, runtime-confirmed). No unknown remains.
- **U2 — `[roles:]` tag on the new pointer.** Planner picks `[roles: universal]` (§4 / §9-G2); user confirmation requested but non-blocking.

---

## 9. Design-gap flags for the user (NOT silently changed)

Per the hard constraint, I flag genuine gaps rather than redesign. Both are mechanical couplings the design's §5 blast-radius table omitted; I have folded them into the commit sequence and surface them here for the user.

- **G1 (must-fix, folded into C2) — `CHECK_REGISTRY_EXPECTED_COUNT` bump is missing from the design.** The design §5/§8 add Check 62 to the registry but never mention bumping `CHECK_REGISTRY_EXPECTED_COUNT` (currently 59 → must be 60). Check 59 (`check_check_registry_completeness`) FAILs without the bump. This is not a design fork — it is a known lock-step bookkeeping edit (the design's own EB referenced the constant pattern indirectly). FOLDED into C2; no user decision needed beyond awareness.
- **G2 (non-blocking, planner-decided) — the `[roles:]` tag value on the retired bullet's pointer.** The design §4.3 recommends `[roles: universal]` but explicitly defers to planner/user. PLANNER DECISION: `[roles: universal]`. Either value is internally consistent (it is a mechanical token); surfaced for the user to override if desired.
- **G3 (clarification, no change) — the rationale file has a SECOND `HELP-FRAGMENT-TRACKER.md` mention (line 170) outside the RC9 section.** It is in the "run per-check tests" worked-example incident history, NOT the RC9 surface. The design's "fix the stale input claim" applies ONLY to the RC9-section mention at line 519. The line-170 mention is correct-as-history and is NOT edited. Flagged so the coder does not over-reach.

No design fork is opened; the design's resolved PICKs (exact predicate; all-`scripts/`-minus-tests; Check 62 = structural screen; `build.sh --verify` = authoritative SHA gate; amend-or-trailing at orchestrator discretion) are carried unchanged.

---

## 10. Mechanical-apply readiness checklist (no open decisions for the coder)

- [x] Exact files per commit (§2, §4).
- [x] Scope keywords: C1 `pack-only`, C2 `pack-only`, C3 `pack-only`; push-time manifest commit (if any) `pack-only`/none (manifest is Check-36-neutral).
- [x] Dependency order C1 → C2 → C3 (tool/SoT → check/count → prose pointer).
- [x] Predicate resolved: exact input set, all-`scripts/`-minus-tests-minus-tool (§4 C1).
- [x] Check 62 = structural screen; `_fixture_names_from_build_sh()` reuse; 6-row/40-hex assertions; lenient SKIP.
- [x] `CHECK_REGISTRY_EXPECTED_COUNT` 59 → 60 in C2.
- [x] Both new tests auto-wire by glob; no allowlist/shard edits.
- [x] Self-hosting: no per-commit manifest in C1/C2/C3; orchestrator runs `manifest-sync.sh` at push; commit output iff exit 10 (§3).
- [x] Design doc archived to `maintenance-docs/v11-implementation/DESIGN-MANIFEST-PUSH-METHOD.md` in C1.
- [x] Trinity pointer byte-identical; `[rationale:]` + heading retained (bijection); `[roles: universal]`.
- [x] Memory-cache upkeep is Pack-Chat-direct post-C3 (not a coder file).
- [x] Per-commit gates enumerated (§7), full CI battery per `verify-full-ci-suite`.


---

## 11. Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted) | Conclusion |
|---|------|-------------------------------|-----------|
| 1 | **agents-never-commit** | This pass ran only read-only git: `git rev-parse --short HEAD` → `3bad276`; `git rev-parse --abbrev-ref HEAD` → `v11-dev`; `git log` (inspection); `python3 scripts/validate-pack.py` (read-only) → exit 0. No `git add/commit/push/tag/stash/checkout/rm/mv/reset`/etc. Only filesystem write = this plan doc under `/tmp/handoff-bd228-planner/`. The plan instructs the ORCHESTRATOR (not agents) to commit + run the push-time tool (§3, §4). | COMPLIANT |
| 2 | **per-action-approval-sub-agents** | No destructive op performed. Only write is the single caller-specified plan doc. No `rm`, no `git rm`, no overwrite of a tracked file. All inspection was read-only (`grep`, `sed -n`, `ls`, `cat`, `python3 validate-pack.py`, `--only-check 59`). | COMPLIANT |
| 3 | **preflight-stop-means-stop** | No parent stop/halt message received; plan delivered complete. Had a stop arrived, I would have halted immediately and reported what blocked me instead of a partial doc. | COMPLIANT |
| 4 | **sub-agents-verify-regime** | Verified at STEP 0 + EB-0: `pwd` → `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev` (MAIN, not a `worktree-agent-*` path); `git rev-parse --abbrev-ref HEAD` → `v11-dev`; HEAD `3bad276` (design-time `1143267` delta re-verified, EB-0). Both pwd + HEAD reported. | COMPLIANT |
| 5 | **empirical-evidence-blocks** | Every state-claim carries an Empirical-Evidence Block EB-0…EB-7 (§1) + the §2 table (line numbers re-measured) + §5 couplings (each tied to a measured fact). Each EB: actual command, verbatim output, HEAD-SHA `3bad276`, interpretation, SUPPORTED conclusion. Examples: EB-2 (`--only-check 59` → "CHECK_REGISTRY has 59 entr(y/ies)"); EB-6 (`grep -n` → `CLAUDE.md:568 AGENTS.md:527 GEMINI.md:504`). | COMPLIANT |
| 6 | **ci-check-runtime-compounding** | Plan pins Check 62 as pure file-read + regex over the 6-row `test-fixtures/manifest.txt` + reuse of existing `_fixture_names_from_build_sh()` (line 6714) — NO fixture rebuild, NO subprocess, NO subprocess-per-entry, NO whole-real-tree scan (§4 C2, §5 X3, §7 R1). The expensive authoritative gate stays the EXISTING push-time `build.sh --verify` (not multiplied across the battery). C2 gate explicitly re-confirms the per-check WARN budget via `run_check`. Across the ~155-202 validate-pack battery invocations the added cost is a 6-line read — negligible. | COMPLIANT |
| 7 | **verify-full-ci-suite** | Every per-commit gate (§4, §7) runs default `validate-pack.py` AND `PACK_VALIDATE_DEEP=1` AND the new per-check/method tests AND the FULL wired battery incl. integration tests (`test-v11-*.sh`) + fixture-dependent tests + the auto-resharded matrix — not validate-pack alone. §5 X3 confirms the new tests re-shard into the CI matrix and the `tests-result` aggregate job + Check 60 stay green. | COMPLIANT |
| 8 | **enumerate-encoding-surfaces** | §2 blast-radius table (13 surfaces, categorized + actor + commit) + §6 lock-step matrix pair EVERY encoding surface with its coverage/parity surface (tool↔test, SoT↔drift-test, Check 62↔per-check-test, registry↔count-bump+Check 59, trinity pointer↔Check 16/18/19, rationale↔Check 45 bijection, propagation row↔reviewer, out-of-repo cache↔Pack-Chat upkeep). §5 X1/X6/X7/X8/X9 are the cross-commit couplings that prevent asymmetric coverage. | COMPLIANT |
| 9 | **regenerate-manifest-v11-surface** | §3 plans the self-hosting transition explicitly: BD-228 touches `scripts/` (a fixture input under RC9), but BD-228 IS the commit introducing the replacement — so C1/C2/C3 carry NO per-commit manifest, and the orchestrator runs the new `manifest-sync.sh` ONCE at BD-228's push (commit output iff exit 10), dog-fooding the replacement. §3 predicts the likely MANIFEST-NOOP outcome (BD-228's new scripts are not init-copied into fixtures) while instructing the orchestrator to follow the tool's actual exit, never hand-edit the manifest. §5 X5/X10 enumerate the coupling. RC9 stays bound until C3 lands the pointer. | COMPLIANT |
| 10 | **rules-applied-verification-block** | This table. Each rule: name + quoted evidence (command/path/count/exit) + COMPLIANT/N-A/VIOLATED conclusion; no empty-evidence cells. | COMPLIANT |

---

**End of plan.**
