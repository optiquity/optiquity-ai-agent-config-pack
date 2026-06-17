# PACK-REVIEW-C6 — BD-221 cluster commit C6 (build.sh EB-21 fix + comparator/fixture conversion)

**Reviewer:** pack-reviewer (read-only). **Date:** 2026-06-17.
**Worktree:** `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a1a6909a337744783` (isolated).
**HEAD:** `33ac5ac227e2f41b5cb48b3d347e774c1457a20c` (== expected `33ac5ac`).
**Diff scope:** exactly 5 uncommitted files — `scripts/compare-agent-trinity.py`, `scripts/test-compare-agent-trinity.sh`, `test-fixtures/README.md`, `test-fixtures/build.sh`, `test-fixtures/manifest.txt`. CONFIRMED (Section 0 check PASS).

---

## OVERALL VERDICT: **CLEAN** — ready to patch + commit.

C6 correctly fixes the `build.sh` EB-21 unconditional-`cp` bug via a `case "$ver"` version-branch, converts the trinity comparator's 3rd leg + its test fixtures to the Antigravity plugin-bundle roster (comparison logic untouched), converts the v11 fixture narration in `README.md` (v10 carve-out preserved), and regenerates `test-fixtures/manifest.txt`. validate-pack is GREEN in both modes; the full wired suite is 71/72 green with the **only** failure being the C7-owned `test-persona-contracts.sh` (expected/acceptable). Boundary is clean `pack-only`. grep-zero returns only KEEP-legitimate tokens. Both priority scrutiny points resolve favorably.

- **SCRUTINY-1 conclusion:** the v11 custom-agent placement is **CORRECT and consistent** with the C2-converted init-project + C3-converted detect. No finding.
- **SCRUTINY-2 conclusion:** C6 **did NOT** change the v11-flat-file / v11-tracker-on fixture content; their SHA change is **pre-existing manifest staleness** (last committed regen `b2f08d0`, BD-219) correctly refreshed by C6's mandated regen. C6-corruption RULED OUT. No finding.

No BLOCKER, MUST, SHOULD, or NIT findings.

---

## SECTION 2 — GATE + RE-GREEN (core deliverable) — PASS

| Check | Command | Result |
|---|---|---|
| validate-pack normal | `python3 scripts/validate-pack.py` | exit **0**; `PASSED — all checks clean`; FAIL lines = **0** |
| validate-pack DEEP | `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | exit **0**; `PASSED`; FAIL count = **0** |
| Fail-line `comm` (NEW) | AFTER fail-line set empty | **NEW = 0** — no C6 regression vs the GREEN BASE at `33ac5ac` |
| `build.sh --verify` | read-only verify | exit **0**; all 6 fixtures `OK` (incl. the 3 changed SHAs) |

**Fixture shard re-green (the C6 deliverable) — all PASS:**
- `scripts/tests/fixture-dependent/test-v11-realistic-ot.sh` → exit 0 (`PASS: 33 / FAIL: 0`)
- `scripts/tests/fixture-dependent/test-migrator-skills.sh` → exit 0
- `scripts/tests/fixture-dependent/test-dry-run-migration.sh` → exit 0
- `scripts/test-compare-agent-trinity.sh` → exit 0

**Full wired suite (72 disk-derived wired tests − allowlist, per validate-pack.yml):** **71 PASS / 1 FAIL.** The single failure is `scripts/tests/fixture-dependent/test-persona-contracts.sh` (`Persona contract summary: 0/3 passed`) — the **C7-owned** test and the only acceptable remaining wired failure per the C6 spec. No OTHER wired test fails. `verify-full-ci-suite` satisfied.

---

## SECTION 3 — PRIORITY SCRUTINY POINTS

### SCRUTINY-1 — v11 custom-agent surface decision — **CORRECT / consistent (no finding)**

The coder version-branched the custom-agent write in `_build_realistic_for_version()`:
- **v10** → `cp ... "$target/.gemini/agents/x-fakeot-domain.md"` (carve-out i, preserved).
- **v11** → `mkdir -p "$target/.agents-plugin/optiquity-agents/agents"; cp ... "$target/.agents-plugin/optiquity-agents/agents/x-fakeot-domain.md"`.

**(a) Is the bundle placement correct for the Antigravity model?** YES. `scripts/init-project.sh` `stage_s2_agents()` (L433–467) stages Antigravity agents as the plugin BUNDLE: `cp -R "$PACK/project-template/.agents-plugin/optiquity-agents" "$TARGET/.agents-plugin/"` — i.e. the only v11 Antigravity agent surface is `.agents-plugin/optiquity-agents/agents/`. `scripts/lib/detect.sh` (C3-converted) L223–225 documents and enforces this: *"Antigravity agents ship as a plugin bundle (.agents-plugin/), not a loose per-CLI dir, so only the Claude/Codex loose dirs are scanned"* — its `detect_improperly_added_files` loose-agent scan loop is exactly `for loc in ".claude/agents" ".codex/agents"`. There is **no loose `.agents/agents/`** anywhere. Placing the project-owned `x-` custom agent in the bundle's `agents/` roster is therefore the correct and only consistent choice. The `x-` file is also safe across updates: `_cmd_update_iter_dir` iterates only over PACK files, so a project-added `x-` agent with no pack counterpart is never touched (plus the `is_x_prefixed` defensive guard at L777–782).

**(b) Does it match what init-project produces for a v11 project?** YES. The built `test-fixtures/v11-realistic-ot` fixture contains the custom agent at exactly the three install-correct surfaces:
`.claude/agents/x-fakeot-domain.md`, `.codex/agents/x-fakeot-domain.toml`, `.agents-plugin/optiquity-agents/agents/x-fakeot-domain.md` — and **no `.gemini/`** anywhere in the v11 fixture (verified via `find`).

**(c) Is the v10 carve-out preserved?** YES. The built `test-fixtures/v10-realistic-ot` keeps the custom agent at `.gemini/agents/x-fakeot-domain.md` (+ `.claude/agents/` + `.codex/agents/`). The v10-realistic-ot manifest SHA is **unchanged** (`4c62945f...`), confirming v10 output is byte-stable.

The build.sh comment block (L301–317) accurately documents this decision, cross-references `init-project.sh:stage_s2_agents` and `detect.sh:detect_improperly_added_files` by file+symbol (not line numbers — `architect-doc-reality-reconciliation` honored), and adds NO "formerly Gemini" historical narration (cross-cutting directive honored).

### SCRUTINY-2 — v11-flat-file / v11-tracker-on manifest SHA change — **staleness-refresh, NOT C6 corruption (no finding)**

Manifest diff shows **three** SHAs changed (v11-realistic-ot, v11-flat-file, v11-tracker-on); v10-minimal / v10-realistic-ot / existing-project-mid-dev unchanged.

**(a) C6 cannot have changed v11-flat-file / v11-tracker-on content.** Build-function tracing (`_build_one` dispatch, L911–923): `v11-flat-file` → `_build_v11_flat_file` (L589); `v11-tracker-on` → `_build_v11_tracker_on` (L599). Both call `_run_v11_init`, which runs `$PACK_ROOT/scripts/init-project.sh` — their content is a function of init-project + `project-template/`, **not** of `_build_realistic_for_version`. The `git diff -U0 test-fixtures/build.sh` hunk ranges are exactly three: `@@ +301,17 @@` and `@@ +332,13 @@` (both inside the `_build_realistic_for_version` custom-agent block) and `@@ +645 @@` (the existing-project comment `.gemini/`→`.agents/`). **No hunk touches** `_build_v11_flat_file`, `_build_v11_tracker_on`, `_run_v11_init`, or `_build_existing_project_mid_dev`. The only behavioral change is the v10/v11 branch in `_build_realistic_for_version` (+ comment/README text), exactly as the plan specifies.

**(b) The new SHAs are correct.** `bash test-fixtures/build.sh --verify` → exit 0; all 6 recorded SHAs (including v11-flat-file `8176d319...` and v11-tracker-on `6f41c7eb...`) match the actual current built fixtures.

**(c) The staleness predates C6.** `git log --oneline -- test-fixtures/manifest.txt` shows the last committed regen at **`b2f08d0`** (BD-219 C4). `git log b2f08d0..HEAD -- test-fixtures/manifest.txt` is **EMPTY** — no committed manifest regen since; C6's working-tree manifest IS the regen. Meanwhile `git log b2f08d0..HEAD -- project-template/ scripts/init-project.sh` lists numerous in-cluster + pre-cluster commits that changed what init-project stages — e.g. `b840900` (C2 init-project), `5675c21` (C1 `.agents/mcp_config.json.example`), `f68f655` (C0 project skills re-land), and the project-side conversion commits `e9baa04`/`5d47317`/`d23ae7d`/`23dede6`/`3429f0d` — none of which regenerated the manifest. These commits changed the v11-flat-file / v11-tracker-on CONTENT without a manifest regen, leaving the recorded SHAs stale. C6's mandated `regenerate-manifest-v11-surface` regen correctly refreshes them. **Both possible origins (in-cluster deferred-due-to-EB21, or BD-219-era) are acceptable; C6 is the correct regen point.** I have RULED OUT C6 itself corrupting/changing those fixtures' content: C6's edited files do not feed those build paths (proven in (a)), and `--verify` confirms the SHAs are the true current builds (b).

---

## SECTION 4 — BOUNDARY, GREP-ZERO, EDIT DISCIPLINE — PASS

**Boundary (pack-only):** `git diff --name-only` = exactly the 5 files, all under `scripts/` + `test-fixtures/`. No `project-template/`, no `supporting-docs/`. `scripts/merge-trinity.py` is NOT in the diff (correctly untouched — it is `GEMINI.md`-FILE-only KEEP). PASS.

**grep-zero (`rename-plans-measure-then-bound`):** every remaining `gemini`/`Gemini`/`.gemini` token in the 5 files is KEEP-legitimate:
- `compare-agent-trinity.py`, `test-compare-agent-trinity.sh`, `manifest.txt` — **zero** tokens (fully converted).
- `README.md:29` — `Claude/Codex/Gemini` in the **v10-realistic-ot** row → v10 fixture narration, carve-out (i) KEEP (design §5.12).
- `README.md:33,34` — `GEMINI.md` + `CLAUDE/AGENTS/GEMINI` trinity FILE names (existing-project + v11-trinity-marker rows) → KEEP (allowlist class 3; design §5.12 "KEEP `GEMINI.md` trinity-FILE").
- `build.sh:183,273,646` — `CLAUDE/AGENTS/GEMINI` / `GEMINI.md` trinity FILE names → KEEP (design §5.12 "L183, L273 ... KEEP (trinity FILE)").
- `build.sh:306,307,334,336` — the v10 carve-out path `.gemini/agents/x-fakeot-domain.md` + "Gemini-shaped" explanatory comment → KEEP (carve-out i, allowlist classes 1/2).

No STRIP token remains. grep-zero PASS.

**edit-in-place (`edit-in-place-not-full-rewrite`):** all edits are focused hunks (numstat: comparator 41/19, test 21/12, README 2/2, build.sh 31/3, manifest 3/3). `compare-agent-trinity.py` change is leg-path + variable-rename (`gemini`→`agents`) + docstrings only — the comparison LOGIC (`name_field_match`, `bodies_match`, `norm` equality, `read_agent` body normalization) is structurally identical. `build.sh` is a `case "$ver"` version-branch (uses the in-scope `local ver="${1:?...}"`), not a rewrite. No silent section drops. PASS.

**comparator logic unchanged / `model` excluded:** confirmed. `model` appears only at `compare-agent-trinity.py:34` (the docstring listing tool-specific fields NOT compared); it is never read into `name_field` or `norm` and never enters `bodies_match`. The test correctly drops the `model: gemini-2.5-pro` fixture string (OQ-4) since the Antigravity bundle pins no model — and because the comparator ignores it, dropping it is behavior-neutral. PASS.

---

## OUT-OF-SCOPE (surfaced, not chased — `scope-deliverables-to-the-ask`)

- `test-persona-contracts.sh` red is C7-owned and expected; not a C6 concern. No action.
- The broader cluster's grep-zero gate (Gate A/B over the full tree) is the C12 backstop, not C6's responsibility; C6's 5-file scope is clean.

---

## Rules-Applied Verification Block

| Rule | Evidence | Conclusion |
|---|---|---|
| **agents-never-commit** | No state-changing git verb run; only `git diff`/`git log`/`git rev-parse`/`git status` (read-only), `build.sh --verify` (read-only), and test runs. No `build.sh --all --clean`. Single write = this report at `/tmp/handoff-bd221-C6/PACK-REVIEW-C6.md`. | COMPLIANT |
| **verify-full-ci-suite** | Ran validate-pack (normal + DEEP, both exit 0) AND the full 72-script disk-derived wired suite (71 PASS / 1 expected C7 FAIL), not just validate-pack. Output quoted in Section 2. | COMPLIANT |
| **manifest-regen-on-v11-surface** | `test-fixtures/manifest.txt` regenerated in the same working tree; `build.sh --verify` exit 0 confirms consistency; v10 SHAs unchanged; the 3 v11 SHA changes justified (SCRUTINY-2). `git log b2f08d0..HEAD -- manifest.txt` empty (C6 is the regen). | COMPLIANT |
| **rename-plans-measure-then-bound** | Enumerated EVERY `gemini` token in all 5 changed files (Section 4); each categorized KEEP-legitimate against the §6 allowlist; comparator/test/manifest are grep-ZERO. | COMPLIANT |
| **edit-in-place-not-full-rewrite** | numstat shows small targeted hunks; comparator logic structurally identical; build.sh is a version-branch; no section drops. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Reviewed exactly C6's 5 files; out-of-scope items (C7 persona red, C12 gate) surfaced, not chased. | COMPLIANT |
| **rules-applied-verification-block** | This block. | COMPLIANT |
