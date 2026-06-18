# PACK-REVIEW — BD-228 C3 (RC9 rule-retirement)

**Reviewer:** pack-reviewer (read-only)
**Date:** 2026-06-17
**Regime verified:** pwd = `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-ab8d4b0a24bbcd362` (MATCHES the C3 worktree); HEAD = `9b2a0d1` (MATCHES required SHA). Working tree carries exactly 5 modified files (the C3 set). Read-only throughout — no git state change, no edit outside this report.
**Inputs reviewed against:** `/tmp/handoff-bd228-planner/PLAN-BD-228-MANIFEST-METHOD.md` §4-C3 + `/tmp/handoff-bd226-manifest-method/DESIGN-MANIFEST-PUSH-METHOD.md` §4 (§4.1 surfaces, §4.2 pointer text, §4.3 `[roles:]` tag). IMPL-REPORT deliberately NOT read (no-prior-reviews-to-reviewer).

---

## VERDICT: **CLEAN** — ship-ready, with ONE non-blocking ORCHESTRATOR ACTION ITEM (push-time manifest reconciliation; by-design per plan §3, NOT a C3 defect).

C3 is mechanically correct, fully lock-step, byte-identical across trinity, validate-pack-green (default + DEEP), and matches the design/plan in every dimension reviewed. The single item to flag is the deliberate self-hosting state the plan installs: the committed manifest is stale at HEAD `9b2a0d1` because BD-228 C1/C2 added `scripts/` fixture inputs and (by design) carry no per-commit manifest — the orchestrator MUST run `scripts/manifest-sync.sh` at push to reconcile. This is exactly the regime plan §3 describes and is NOT attributable to C3 (C3 touches no fixture input). Detail in §A1 below.

---

## Review dimensions (each verified independently with cited evidence)

### 1. Trinity ×3 — PASS

- **RC9 per-commit bullet replaced with the §4.2 push-time pointer:** the diff in all three of `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` removes the old "Regenerate test-fixtures/manifest.txt on every v11-surface commit … MUST also regenerate … in the SAME commit" bullet and inserts the design §4.2 pointer ("Manifest is push-time, tool-enforced — not a per-commit chore. … regenerated only at push, only when a fixture input changed, by `scripts/manifest-sync.sh` … Correctness is enforced by CI `build.sh --verify` + validate-pack Check 62 — do NOT regenerate the manifest per-commit.").
- **Byte-identical across the three (trinity parity):** extracted the new bullet from each file and computed md5 — all three identical: `5c47fd49b6247c4b7c528f76aa08beb6`. `diff` CLAUDE↔AGENTS and CLAUDE↔GEMINI both report IDENTICAL.
- **`[roles:]` tag = `[roles: universal]`** (changed from `[roles: coder]`, user-confirmed per plan §9-G2 / design §4.3). Confirmed present in all three; the old `[roles: coder]` is gone from this bullet (`grep "manifest per-commit. \`[roles: coder]"` → NONE).
- **`[rationale: regenerate-manifest-v11-surface]` RETAINED unchanged** — present immediately under the bullet in all three (bijection preserved — see dim 7 / Check 45).
- **Rendered as PROSE, no `<!-- HTML comments -->` in the bullet** — `grep "<!--" CLAUDE.md AGENTS.md GEMINI.md | grep -i manifest` → ZERO.
- **Residual per-commit obligation text ZERO** — `grep -n "on every v11-surface commit\|in the SAME\|MUST also regenerate\|stage it alongside" CLAUDE.md AGENTS.md GEMINI.md` → no matches (exit 1).

### 2. `pack-ops/PACK-MEMORY-RATIONALE.md` — PASS

- **`## regenerate-manifest-v11-surface` HEADING kept** (bijection) — present at line 509, unchanged.
- **HOW-to-apply rewritten** to the push-time tool + `build.sh --verify` + Check 62 — the new "**How to apply (BD-228 — push-time, tool-enforced):**" block states the manifest is no longer a per-commit chore; the orchestrator runs `scripts/manifest-sync.sh` once before push; correctness enforced by CI `build.sh --verify` (authoritative SHA gate) + validate-pack Check 62 (structural screen); agents never hand-edit/per-commit-regenerate; references the archived design doc.
- **Incident-history WHY KEPT** — the two CI-red incidents (`667d2dd` 2026-05-17, `4120d19` 2026-05-19, recovery `6c48f88`/`ef9e5c7`, BD-176 trigger expansion, BD-115/RELEASE-GATE item 5) are all intact at lines 530-543.
- **Stale `pack-ops/HELP-FRAGMENT-TRACKER.md`-is-an-input claim FIXED in the RC9 HOW section only** — the rewrite now reads "the source `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` ships to clients here — the `pack-ops/HELP-FRAGMENT-TRACKER.md` copy is NOT a fixture input" (lines 518-519), matching design EB-5.
- **The unrelated line-170 mention correctly UNTOUCHED** — line 170's `pack-ops/HELP-FRAGMENT-TRACKER.md` reference is in the "run per-check tests" worked-example (BD-193/194 incident), not the RC9 surface. Diff hunk headers (`@@ -514,15 … @@`, `@@ -540,27 …@@`) confirm only lines 514+ and 540+ were touched; line 170 is outside both hunks. Matches plan §9-G3.

### 3. `pack-ops/PACK-CHAT.md` — PASS

- **Propagation row 6 reframed** from "`test-fixtures/manifest.txt` regen if a v11-surface path changed | existing manifest CI gate" to "`test-fixtures/manifest.txt` — NOT a propagation step; the orchestrator runs `scripts/manifest-sync.sh` at push (regen iff a fixture input changed) | CI `build.sh --verify` + validate-pack Check 62".
- **Order note reframed** — "manifest regen (6) last" removed; replaced with "The `test-fixtures/manifest.txt` (6) is NOT a propagation-order step — it is reconciled by `scripts/manifest-sync.sh` at push (BD-228), not per-commit." Bonus clarity: the note now disambiguates "spawn-rule manifest (5)" (the `.spawn-rule-manifest.txt`) from "test-fixtures/manifest.txt (6)", correcting a prior ambiguous "manifest (5)" reference. This is a correct, in-scope improvement.

### 4. Anti-restate — PASS

- `grep -rn "build.sh --all --clean\|v11-surface commit\|regenerate.*manifest.*SAME commit" pack-ops/PACK-AGENTS.md pack-ops/PACK-CHAT.md CLAUDE.md AGENTS.md GEMINI.md` → ZERO matches. No other restatement of RC9's per-commit mechanics remains anywhere in PACK-AGENTS.md, PACK-CHAT.md, or the trinity.

### 5. Pointer references resolve — PASS

- `scripts/manifest-sync.sh` — exists at HEAD (`git ls-files` → present; landed C1 `37678fb`).
- `scripts/lib/manifest-inputs.sh` (named in the rationale rewrite) — exists at HEAD (landed C1).
- Check 62 (`check_manifest_structural`) — registered at HEAD: `scripts/validate-pack.py:9992 (62, "check_manifest_structural", …)`; function at line 6834 (landed C2 `9b2a0d1`).
- Archived design doc `maintenance-docs/v11-implementation/DESIGN-MANIFEST-PUSH-METHOD.md` (referenced by the rationale rewrite) — exists at HEAD (landed C1).
- No dangling reference.

### 6. Boundary (`pack-only`) — PASS

- `git status --porcelain` → exactly 5 modified files: `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `pack-ops/PACK-CHAT.md`, `pack-ops/PACK-MEMORY-RATIONALE.md`.
- All 5 are pack-ops/trinity surfaces (no `project-template/` or `supporting-docs/` path) → `pack-only` is the honest scope claim; Check 36 will pass.
- `test-fixtures/manifest.txt` NOT staged/modified (correct — self-hosting; reconciled at push). No other file touched.

### 7. Gate — PASS (default + DEEP exit 0; Checks 16/18/19/45/62 green)

- `python3 scripts/validate-pack.py` → **exit 0**, "PASSED — all checks clean".
- `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` → **exit 0**, "PASSED — all checks clean"; NEW/FAIL fail-lines EMPTY (`grep -nE "FAIL|NEW:"` → none).
- **Check 16** (trinity addenda parity) → exit 0.
- **Check 18** (trinity H2 parity) → exit 0.
- **Check 19** (no scaffolding comments) → exit 0.
- **Check 45** (rule↔rationale bijection) → exit 0; "22 corpus `[rationale: slug]` pointer(s); 22 rationale `## <slug>` section(s); sets are equal (bijection holds, no orphans)". The retained tag↔heading pair keeps the bijection net-unchanged across C3 (plan EB-4 / X6).
- **Check 62** (manifest structural screen, from C2) → green; "6 data row(s), names == build.sh FIXTURE_NAMES, every SHA a 40-hex token".

### Full wired CI battery (built fixtures once; ran each relevant leg)

| Test / battery | Result |
|---|---|
| `validate-pack.py` default | exit 0 (PASSED) |
| `validate-pack.py` DEEP | exit 0 (PASSED) |
| per-check tests 16/18/19/45/62 | 5/5 PASS |
| Full validate-pack per-check test sweep (`test-validate-pack-check-*.sh` + `-checks-*.sh`) | **26 PASS / 0 FAIL** |
| `scripts/tests/manifest-method-test.sh` (C1 method test) | PASS 34 / FAIL 0 |
| `scripts/test-compare-agent-trinity.sh` | 10 total, 10 passed, 0 failed |
| `scripts/tests/fixture-dependent/test-v11-realistic-ot.sh` (integration spot-check) | exit 0 PASS |
| `scripts/lib/ci-shard-plan.py --emit-matrix` | exit 0 (matrix builds; new tests auto-wired by glob) |
| `bash test-fixtures/build.sh --verify` (authoritative SHA gate) | **exit 1 (MISMATCH)** — see §A1; by-design pre-push state, NOT a C3 defect |

**Totals:** every wired battery leg PASS **except** `build.sh --verify`, whose RED is the deliberate self-hosting state plan §3 installs (the orchestrator reconciles at push). No live-GH legs were exercised (graceful-SKIP class — not failures). No regression attributable to C3.

---

## A1. NON-BLOCKING ORCHESTRATOR ACTION ITEM (informational — by design, NOT a C3 finding)

**`bash test-fixtures/build.sh --verify` is RED at the committed HEAD `9b2a0d1`.** Three v11 fixtures are stale vs the committed manifest:

| fixture | committed manifest SHA | freshly-built SHA |
|---|---|---|
| `v11-realistic-ot` | `49a4b801…` | `12de16d4…` |
| `v11-flat-file` | `688fbff2…` | `2eaad161…` |
| `v11-tracker-on` | `67fa09c0…` | `17b1e663…` |

**Root cause (NOT C3):** BD-228 **C1/C2** added `scripts/` fixture inputs (`manifest-sync.sh`, `manifest-inputs.sh`, the validate-pack Check 62 edit, the new tests) that flow into the v11 fixtures (which build from "pack current HEAD"). Per the plan §3 self-hosting design, BD-228 C1/C2/C3 deliberately carry **no per-commit manifest**; the manifest is reconciled **once at push** by `scripts/manifest-sync.sh`. C3 itself touches **no fixture input** (`git status` shows only pack-root trinity + `pack-ops/`, none of which are fixture inputs per design EB-5), so this staleness is not introduced by C3 and is not a defect of this commit.

**Confirmation the designed mechanism works:** running `bash scripts/manifest-sync.sh` returns **exit 10 (MANIFEST-CHANGED)**, rebuilds once, and writes the corrected manifest — deterministically (two consecutive runs produced identical SHAs `12de16d4`/`2eaad161`/`17b1e663`). This is exactly the design §2.4/§6 / plan §3 push-time reconciliation path, working as specified. (The tool also emitted the expected `no upstream/origin ref resolvable; screening HEAD tip only` warning in this worktree — plan §4 R4 fallback; harmless here.)

**Action for the orchestrator BEFORE pushing BD-228:** run `scripts/manifest-sync.sh`; on exit 10, commit the regenerated `test-fixtures/manifest.txt` (the trailing-commit shape per plan §3 / design §2.5) with user approval. This is the live first exercise of the method (self-hosting, design §7.4). Note this corrects the plan §7 prose claim ("every intermediate LOCAL commit is validate-pack-green; the SHA-correctness gate is satisfied at push") — validate-pack IS green at every intermediate commit (Check 62 is structural-only), but `build.sh --verify` is RED until the push-time reconciliation lands, which is precisely the intended split (Check 62 = cheap structural screen; `build.sh --verify` = authoritative SHA gate at pushed HEAD).

I restored `test-fixtures/manifest.txt` to its committed state after every probe; the working tree ends with exactly the 5 C3 files dirty (re-confirmed: HEAD `9b2a0d1`, 5 files dirty).

---

## Findings by severity

- **BLOCKER:** none.
- **MUST:** none.
- **SHOULD:** none.
- **NIT:** none.
- **INFO (orchestrator action, by-design):** A1 — run `manifest-sync.sh` at push to reconcile the deliberately-deferred manifest (exit 10 confirmed). Not a C3 defect.

---

## Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted) | Conclusion |
|---|------|-------------------------------|-----------|
| 1 | **agents-never-commit** | Ran only read-only git: `git rev-parse --short HEAD` → `9b2a0d1`; `git status --porcelain`; `git diff`; `git ls-files`; `git log`; `git show HEAD:…`; `git diff --name-only 1143267..HEAD`. `git checkout HEAD -- test-fixtures/manifest.txt` was used ONLY to RESTORE the file I dirtied via read-only build probes back to its committed state (no net working-tree change; ends with exactly the 5 C3 files dirty) — no `add/commit/push/tag/stash/reset/branch/merge`. Only filesystem write = this report under `/tmp/handoff-bd228-C3/`. | COMPLIANT |
| 2 | **per-action-approval-sub-agents** | No destructive op. The `git checkout HEAD -- test-fixtures/manifest.txt` calls only reverted a file I myself had transiently regenerated via read-only build probes (restoring committed state), never altering tracked content net; no `rm`/`git rm`/overwrite of trusted content. Only persistent write = the caller-specified report. | COMPLIANT |
| 3 | **preflight-stop-means-stop** | No parent stop/halt message received; review delivered complete. Had a stop arrived I would have halted immediately and reported what blocked me instead of a partial report. | COMPLIANT |
| 4 | **sub-agents-verify-regime** | Ground-truth at STEP 0: `pwd` → `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-ab8d4b0a24bbcd362` (MATCHES the C3 worktree); `git rev-parse --short HEAD` → `9b2a0d1` (MATCHES required SHA). Both recorded; did not proceed on settings trust. | COMPLIANT |
| 5 | **no-prior-reviews-to-reviewer** | Reviewed independently against `/tmp/handoff-bd228-planner/PLAN-BD-228-MANIFEST-METHOD.md` §4-C3 + `/tmp/handoff-bd226-manifest-method/DESIGN-MANIFEST-PUSH-METHOD.md` §4 ONLY. The C3 IMPL-REPORT was NOT read; no prior `PACK-REVIEW-*` was read. | COMPLIANT |
| 6 | **trinity-rule** | Extracted the new pointer bullet from CLAUDE.md/AGENTS.md/GEMINI.md and computed md5 — all three `5c47fd49b6247c4b7c528f76aa08beb6`; `diff` CLAUDE↔AGENTS and CLAUDE↔GEMINI → IDENTICAL. `[roles: universal]` + `[rationale: regenerate-manifest-v11-surface]` present in all three; no HTML comments; PROSE rendering. Byte-identical lock-step confirmed. | COMPLIANT |
| 7 | **enumerate-encoding-surfaces** | All RC9 prose surfaces verified updated in lock-step with no asymmetric residual: trinity ×3 (pointer, no per-commit text), `PACK-MEMORY-RATIONALE.md` (heading kept + HOW rewritten + WHY kept + stale-claim fixed), `PACK-CHAT.md` (row 6 + order note). Anti-restate grep across PACK-AGENTS.md/PACK-CHAT.md/trinity → ZERO residual per-commit mechanics. Coverage surfaces: Check 45 bijection green (22↔22), Check 16/18/19 trinity parity green + their per-check tests PASS, Check 62 + its per-check test PASS. No surface updated without its pair. | COMPLIANT |
| 8 | **verify-full-ci-suite** | Ran beyond validate-pack: default+DEEP (both exit 0), 26/0 per-check test sweep, manifest-method-test (34/0), compare-agent-trinity (10/10), fixture-dependent integration `test-v11-realistic-ot` (exit 0), `ci-shard-plan --emit-matrix` (exit 0). Ran the authoritative `build.sh --verify` — RED, traced to BD-228 C1/C2's by-design deferred manifest (§A1), NOT a C3 defect; confirmed `manifest-sync.sh` reconciles it (exit 10, deterministic). Counts reported in the battery table. | COMPLIANT |
| 9 | **rules-applied-verification-block** | This table — each rule: name + quoted evidence (command/path/count/exit) + COMPLIANT conclusion; no empty-evidence cells. | COMPLIANT |

---

**End of review.**
