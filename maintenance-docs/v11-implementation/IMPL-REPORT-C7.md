# IMPL-REPORT — BD-221 Commit C7 (persona-contracts Gemini→Antigravity conversion)

- **Regime:** ISOLATED WORKTREE (verified at runtime, not from settings).
- **Worktree path:** `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-af3fa4dbb6c6ecb18`
- **Branch:** `worktree-agent-af3fa4dbb6c6ecb18`
- **HEAD (base + final; no commit made):** `f945fb9b56e6796fdd5c355f673eada5ec8e7f14` (`f945fb9`)
- **Scope keyword:** `pack-only`
- **Patch emitted?** NO — per Section 1, edits left UNCOMMITTED in the worktree;
  awaiting post-review SendMessage to produce the patch. No state-changing git verb run.

---

## 1. Summary

C7 converts the 3 persona-contract scripts so they assert the v11 **Antigravity**
install shape instead of the retired Gemini shape. This re-greens the last red
wired test, `test-persona-contracts.sh` (0/3 at HEAD → **3/3** after C7). The
entire wired CI suite (72 tests across both validate-pack.yml jobs) is now GREEN.

The lockstep test wrapper `scripts/tests/fixture-dependent/test-persona-contracts.sh`
needed **NO** conversion (it carries zero gemini logic — it merely runs the 3
contracts and aggregates pass/fail). All conversion was in the 3 contract scripts.

**Install-shape verification method (no guessing):** every converted assertion was
checked against the ACTUAL output of the C2-converted `scripts/init-project.sh` and
the C3-converted `scripts/migrate-v10-to-v11.sh` by materializing real sandboxes
and inspecting the post-install / post-migrate trees (commands + outputs recorded
in §4). The contracts assert what init/migrate ACTUALLY produce.

---

## 2. Verified v11 install shape (ground-truth, against C2/C3)

| Surface | v10 (retired Gemini shape) | v11 (Antigravity shape) — VERIFIED |
|---|---|---|
| Pool skills (S4) | `.claude/.codex/.gemini/skills/<n>/SKILL.md` | `.claude/.codex/.agents/skills/<n>/SKILL.md` (`for tool in claude codex agents`, init-project.sh:522) |
| pack-help | `.gemini/commands/pack-help.toml` | pool skill → `.agents/skills/pack-help/SKILL.md` (init-project.sh S11 sub-stage 4 comment L980-984; migrator L318-333) |
| pack agents (loose) | `.claude/.codex/.gemini/agents/` | loose `.claude/agents/*.md` + `.codex/agents/*.toml` only |
| Antigravity agents | (Gemini loose dir) | plugin BUNDLE `.agents-plugin/optiquity-agents/agents/*.md` (init-project.sh S2 L448-454) |
| MCP config | (`.gemini/settings.json`) | `.agents/mcp_config.json` (init-project.sh S3 L495) |
| `project-template/.gemini/` | present | **DELETED** at C2 — does not exist (verified `ls` → No such file) |
| migrate: departing `.gemini/` | (lived on disk) | RETIRED whole-tree into `gemini-retired-docs/.gemini/` (C3 `_v10_to_v11_retire_gemini`, migrate-v10-to-v11.sh L456-487) |

**Key non-obvious facts that shaped the conversion (NOT blind `+agents`):**
1. Init creates `.agents/skills` but **NOT** `.agents/agents` (S1 skeleton, init-project.sh:423). Antigravity agents = the bundle. So agent-presence loops became `claude codex` + a separate bundle assertion.
2. The v10→v11 migrator does **NOT** install the Antigravity plugin bundle additively (`.agents-plugin/` absent post-migrate — verified). It only directory-sweeps loose `.claude/agents` + `.codex/agents` (migrator_directory_sweeps L111-117). So the migration contract's pack-agent assertion (assertion 2) is `claude codex` only — there is no loose third-CLI pack-agent surface to assert. **Surfaced, not fixed** (see §7 POQ-C7-1).
3. The v10 custom x-agent (`x-fakeot-domain`) third-CLI copy is in the v10 fixture's `.gemini/agents/` (carve-out i). Post-migrate it is **PRESERVED** in `gemini-retired-docs/.gemini/agents/x-fakeot-domain.md`, NOT relocated to `.agents/agents/`. BD-088/BD-119 forbid DELETION, not relocation into the preservation holding dir — so invariant 3b asserts preservation in the holding dir.
4. The v10→v11 migrator DOES install pack-help to all three CLI skill homes including `.agents/skills/pack-help/SKILL.md` (verified post-migrate). So the migration contract's pack-help skill loop was widened claude/codex → claude/codex/agents.

---

## 3. Files changed (inventory)

| Path | Change type | Line delta |
|---|---|---|
| `scripts/persona-contracts/contract-greenfield.sh` | modified | +67 / region |
| `scripts/persona-contracts/contract-mid-dev.sh` | modified | +20 / region |
| `scripts/persona-contracts/contract-migration.sh` | modified | +53 / region |
| `scripts/tests/fixture-dependent/test-persona-contracts.sh` | **NO change** (zero gemini logic) | — |
| `test-fixtures/manifest.txt` | **NO change** (persona-contracts are pack-dev scripts, not fixture inputs) | — |

`git diff --stat`: 3 files changed, 109 insertions(+), 31 deletions(-).
`git status --short` shows exactly the 3 contract files modified — no out-of-scope
edits, no manifest staging.

---

## 4. Per-task conversion detail (every loop / assert + how verified)

### 4a. contract-greenfield.sh
**Verified shape:** `bash test-fixtures/build.sh --for-contract greenfield` →
init produces `.claude/.codex/.agents/skills/<n>/SKILL.md`, the bundle, and
`.agents/skills/pack-help/SKILL.md` (no `.gemini/`).

Conversions:
- Header derivation comments (item 1 skill list, item 2 agent shape, item 4 pack-help): `.gemini/skills/` → `.agents/skills/`; `.gemini/agents/` narration → "Antigravity agents ship as a plugin BUNDLE … `.agents-plugin/optiquity-agents/agents/`"; pack-help `.gemini/commands/pack-help.toml` narration → "pool skill … `.agents/skills/pack-help/SKILL.md`".
- **Assertion 1 skill loop:** `for tool in claude codex gemini` → `for tool in claude codex agents` (skill-presence).
- **Count-sanity loop + its comment:** `for tool in claude codex gemini` → `claude codex agents`; comment "gemini ships pack-help as a command, not a skill — see project-template/.gemini/commands/pack-help.toml" → corrected to "pack-help and pm-startup are now ordinary pool skills … distributed to all three CLIs (claude/codex/agents)".
- **Assertion 2 agent loop:** split — loose loop now `for tool in claude codex`; **added** a new Antigravity bundle assertion block iterating `project-template/.agents-plugin/optiquity-agents/agents/*.md` vs the installed `.agents-plugin/optiquity-agents/agents/`.
- **Assertion 4 S11:** comment sub-stage-4 mapping updated; array entry `.gemini/commands/pack-help.toml` → `.agents/skills/pack-help/SKILL.md`.
- **KEPT (trinity FILE):** header L24 narration `GEMINI.md`; Assertion 3 loop `for f in CLAUDE.md AGENTS.md GEMINI.md` (greenfield 2 occurrences — both byte-identity trinity asserts).
- **Result:** `194 passed, 0 failed` (exit 0).

### 4b. contract-mid-dev.sh
**Verified shape:** `--for-contract mid-dev` → init creates `.agents/skills`,
`.agents/mcp_config.json`, the bundle `.agents-plugin/optiquity-agents/agents`;
**no** `.agents/agents`, **no** `.gemini`.

Conversions:
- Header comment item 3 `.gemini/ directories` → "Antigravity `.agents/skills/` + plugin bundle".
- **Per-CLI directory loop:** `for tool in claude codex gemini` → `for tool in claude codex` (asserts `.${tool}/agents` + `.${tool}/skills`); **added** a dedicated Antigravity block asserting `.agents/skills/` AND `.agents-plugin/optiquity-agents/agents/` (the bundle) — because Antigravity has no loose `.agents/agents` dir.
- **KEPT (trinity FILE):** trinity-present loop L174 `for f in CLAUDE.md AGENTS.md GEMINI.md` (mid-dev 1 occurrence).
- **Result:** `25 passed, 0 failed` (exit 0).

### 4c. contract-migration.sh
**Verified shape:** drove the real migrator on `--for-contract migration` +
auto-resolved sidecars + `--resume`. Post-migrate: `.claude/agents` = 17 (16 pack
+ 1 x-custom), `.codex/agents` x-custom kept, `.agents/skills/pack-help/SKILL.md`
present, `.agents-plugin/` ABSENT, `.agents/agents` ABSENT, x-fakeot-domain
preserved at `gemini-retired-docs/.gemini/agents/x-fakeot-domain.md`.

Conversions:
- **Assertion 2 pack-agent loop:** `for tool in claude codex gemini` → `for tool in claude codex` + comment explaining Antigravity agents ship as a bundle the v10→v11 migrator does not yet install additively (so no loose third-CLI surface to assert).
- **Skill responsibilities comment:** "gemini ships pack-help as a command — verified in assertion 4" → "pack-help is now an ordinary pool skill fanned out … to all three CLI skill homes (.claude/.codex/.agents)".
- **pack-help skill loop:** `for tool in claude codex` → `claude codex agents` (the migrator installs `.agents/skills/pack-help/SKILL.md` — verified).
- **Invariant 3b (x-agent preservation):** loose loop `for tool in claude codex gemini` → `claude codex` (on-disk); **added** a dedicated third-CLI assertion that the project-owned x-agent is PRESERVED under `gemini-retired-docs/` (via `find`), honoring BD-088/BD-119 "never DELETE" against the migrator's actual retirement-not-deletion behavior.
- **Assertion 4 v11_artifacts:** comment sub-stage-4 mapping updated; array entry `.gemini/commands/pack-help.toml` → `.agents/skills/pack-help/SKILL.md`.
- **KEPT (trinity FILE):** header L18 narration `GEMINI.md`; L148/L205/L246 `for f in CLAUDE.md AGENTS.md GEMINI.md` (migration 4 trinity-FILE asserts total incl. header narration).
- **KEPT (legitimate v11 surface refs):** the `gemini-retired-docs/` holding-dir name (real C3 migrator surface) at L285/L293/L295/L298, and the v10-source carve-out narration `.gemini/agents/`/`.gemini/` at L284-285 (describing the departing v10 tree the migrator retires).
- **Result:** `37 passed, 0 failed` (exit 0).

---

## 5. KEPT GEMINI.md trinity asserts (confirmation — Section 2 directive)

The prompt directed: KEEP all `GEMINI.md` trinity asserts (greenfield 2, mid-dev 1,
migration 4). Confirmed present and untouched:
- greenfield: header L24 narration + Assertion-3 loop L177 = 2 occurrences (the loop is one `GEMINI.md` token among CLAUDE/AGENTS/GEMINI; the header narration is the other).
- mid-dev: trinity-present loop L174 = 1 occurrence.
- migration: header L18 narration + L148 + L205 + L246 = 4 occurrences.

All `for f in CLAUDE.md AGENTS.md GEMINI.md` trinity-FILE loops are unchanged.

---

## 6. Did the test itself need conversion?

**No.** `scripts/tests/fixture-dependent/test-persona-contracts.sh` carries zero
gemini/Gemini/GEMINI/.agents tokens (grep returned nothing). It is a pure wrapper
that runs the 3 contracts and aggregates. No lockstep test edit was required.

---

## 7. POQs introduced

**POQ-C7-1 (surfaced, NOT fixed — out of C7 scope):** the v10→v11 migrator does
NOT install the Antigravity agent plugin bundle (`.agents-plugin/optiquity-agents/`)
additively into a migrated project. A v10→v11-migrated project therefore has
loose `.claude/agents` + `.codex/agents` pack agents but no Antigravity agent
bundle. The migration contract assertion 2 is scoped to `claude codex` to match
this ACTUAL behavior (the contract correctly verifies what the migrator does).
Whether the migrator SHOULD additively install the bundle is a migrator-design
question, not a persona-contract question. **Disposition:** documented here for
Pack Chat triage; C7 makes no migrator change. If the migrator is later changed
to install the bundle, this contract's assertion 2 should be widened in lockstep.

---

## 8. Definition-of-Done checklist

| Item | Status | Evidence |
|---|---|---|
| 3 contracts converted (loops + asserts + comments) | PASS | §4 |
| Install surfaces verified against init-project.sh (C2) | PASS | §2 ground-truth commands |
| Install surfaces verified against migrate-v10-to-v11.sh (C3) | PASS | §2 ground-truth migration run |
| `.gemini/commands/pack-help.toml` → `.agents/skills/pack-help/SKILL.md` | PASS | greenfield + migration array + comments |
| `for tool in claude codex gemini` → audience-correct (`agents` or split) | PASS | §4 (skill loops → `agents`; agent loops → `claude codex` + bundle) |
| All `GEMINI.md` trinity asserts KEPT (gf 2 / md 1 / mig 4) | PASS | §5 |
| test-persona-contracts 3/3 | PASS | `Persona contract summary: 3/3 passed` |
| validate-pack default exit 0; AFTER empty; NEW=0 | PASS | §9 |
| validate-pack DEEP exit 0 | PASS | `PASSED — all checks clean` |
| Full wired CI suite GREEN (both jobs) | PASS | 72 passed, 0 failed (of 72) |
| Manifest unchanged (not staged) | PASS | `git diff --stat test-fixtures/manifest.txt` empty after `build.sh --all --clean` |
| grep-zero: only KEEP-legitimate tokens remain | PASS | §9 |
| pack-only scope (no project-template/ / supporting-docs/) | PASS | `git status --short` = 3 scripts/ files |
| No state-changing git verb run | PASS | only `git rev-parse`/`status`/`diff`/`show` used |

---

## 9. Verification gate evidence (Section 4)

**Step 1 — BASE (before edits):**
```
$ python3 scripts/validate-pack.py 2>&1 | grep -E '^FAIL:' | sort > /tmp/c7-base.txt
(empty — HEAD green)
```

**Step 2 — AFTER + NEW + DEEP:**
```
$ python3 scripts/validate-pack.py 2>&1 | grep -E '^FAIL:' | sort > /tmp/c7-after.txt
(empty)
$ comm -13 /tmp/c7-base.txt /tmp/c7-after.txt
(empty — NEW=0)
$ python3 scripts/validate-pack.py ; echo $?    → 0
$ PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py | tail -1  → PASSED — all checks clean ; exit 0
```

**Step 3 — C7 deliverable:**
```
$ bash scripts/tests/fixture-dependent/test-persona-contracts.sh
Persona contract summary: 3/3 passed
  PASS: contract-greenfield.sh / contract-mid-dev.sh / contract-migration.sh
All persona contracts PASS.   (exit 0)
```
Per-contract: greenfield 194/0, mid-dev 25/0, migration 37/0.

**Step 4 — Full wired CI suite (every script in validate-pack.yml, both jobs):**
```
validate job:  validate-pack.py (exit 0) + PACK_VALIDATE_DEEP=1 (exit 0)
tests job:     72 wired tests (ci-shard-plan.py --print-partition, all 4 shards)
               → WIRED SUITE: 72 passed, 0 failed (of 72)
```
The `tests` job set is disk-derived via `ci-shard-plan.py` over
`{scripts/test*.sh + scripts/tests/*.sh + scripts/tests/fixture-dependent/*.sh}`
minus the 1-item allowlist = 72 KEEP. All 72 run + pass. Fixtures built via
`bash test-fixtures/build.sh --all --clean` before the run.

**Step 5 — grep-zero (rename-plans-measure-then-bound):**
```
$ grep -nE 'gemini|Gemini|GEMINI' <the 3 contracts + the wrapper test>
```
Remaining tokens, all KEEP-LEGITIMATE:
- mid-dev:174, greenfield:24/177, migration:18/148/205/246 → `GEMINI.md` trinity FILE.
- migration:284 → v10-SOURCE carve-out narration (`.gemini/agents/`; the v10 fixture is legitimately Gemini-shaped per carve-out i, retained per plan C6).
- migration:285 → describes the migrator RETIRING the departing `.gemini/` tree (real C3 behavior).
- migration:293/295/298 → `gemini-retired-docs/` — the migrator's actual v11 holding-dir NAME (a current surface, not stale install residue).

ZERO tool-`gemini` loop tokens, ZERO `.gemini/commands/pack-help.toml` asserts,
ZERO `.gemini/skills`/`.gemini/agents` install asserts remain.

**Section 3 — manifest:**
```
$ bash test-fixtures/build.sh --all --clean   (exit 0)
$ git diff --stat test-fixtures/manifest.txt
(empty — UNCHANGED; not staged, not modified)
```

---

## 10. Plan deviations

**ZERO sequencing/scope deviations.** All edits are within the plan §3 C7 file set
(`scripts/persona-contracts/*.sh` + the lockstep test). One plan-anticipated
judgment call resolved per the plan's own instruction ("do NOT blindly add `agents`
if the surrounding asserts are claude/codex-specific"): agent-presence assertions
became `claude codex` + a separate Antigravity bundle / holding-dir assertion,
because Antigravity agents are not a loose per-CLI dir. The plan's "expected: empty
unless a persona fixture is rebuilt" manifest prediction held — manifest unchanged.

---

## 11. Boundary discipline check

C7 is `pack-only` and touches ONLY pack-dev scripts under
`scripts/persona-contracts/` — no `project-template/`, `supporting-docs/`, or any
client-shipped surface. Therefore the project-side SSOT pre-flight (P-missed-7)
does not engage: no project-side file was edited, no pack-only reference was added
to a client surface. No boundary-discipline stop.

---

## 12. Isolation-model behavior (Section 1)

- Verified regime at runtime: `pwd` = the `.claude/worktrees/agent-…` path; `git rev-parse HEAD` = `f945fb9`. Confirmed isolated worktree, did not trust settings.
- All edits via Edit tool in THIS worktree; the main checkout was not touched.
- NO patch emitted; edits left UNCOMMITTED. NO `git add`/commit/apply/stash/checkout/restore or any state-changing git verb. Only `git rev-parse`, `git status`, `git diff`, `git show` (read-only) + `test-fixtures/build.sh` (build/verify, allowed) were run.
- Awaiting the post-review SendMessage to produce the patch.

---

## 13. Rules-Applied Verification Block

| Rule | Evidence | Conclusion |
|---|---|---|
| **agents-never-commit** | Only `git rev-parse`/`status`/`diff`/`show` run; edits via Edit tool; `git status --short` shows 3 unstaged files; no commit/add/apply. | COMPLIANT |
| **per-action-approval-sub-agents** | No destructive op run on own authority; unexpected migrator behavior (no bundle install) SURFACED as POQ-C7-1, not "fixed". Sandboxes created in `/tmp` + self-cleaned by contract traps. | COMPLIANT |
| **preflight-stop-means-stop** | Single PREFLIGHT line emitted only after all Section-4 gates PASS (validate default+DEEP NEW=0, persona 3/3, wired 72/72, manifest unchanged). No stop message received. | COMPLIANT |
| **verify-full-ci-suite** | Ran EVERY wired script (72) from `ci-shard-plan.py --print-partition` (both validate-pack.yml jobs), not a sample → 72 passed, 0 failed. validate default + DEEP both exit 0. | COMPLIANT |
| **manifest-regen-on-v11-surface** | C7 touches `scripts/`; ran `bash test-fixtures/build.sh --all --clean`; `git diff --stat test-fixtures/manifest.txt` empty → persona-contracts are not fixture inputs; manifest NOT staged (correct — stage only if non-empty). | COMPLIANT |
| **edit-in-place-not-full-rewrite** | All changes via targeted Edit calls (old_string/new_string), never a full-file Write; touched regions re-read where needed; no section dropped (greenfield went 0 fails before/after across 194 asserts; diff = +109/-31 localized). | COMPLIANT |
| **rename-plans-measure-then-bound** | Post-edit `grep -nE 'gemini\|Gemini\|GEMINI'` over the exact in-scope file set returned EXACTLY the documented KEEP allowlist (§9 step 5): `GEMINI.md` trinity + `gemini-retired-docs/` real surface + v10-source carve-out narration. Zero tool-gemini/`.gemini/`-install residue. | COMPLIANT |
| **rules-applied-verification-block** | This block; each rule has quoted evidence + terminal conclusion; isolation-model behavior recorded (§12). | COMPLIANT |
