# PLAN — BD-221 CX1 RE-PLAN (remaining cluster after the agent-migration design correction)

**BD:** BD-221 — convert all Gemini-CLI support to Antigravity (full transition). **v11.0 LAUNCH GATE.**
**Author:** pack-planner (READ-ONLY in the MAIN checkout). This `/tmp` doc is the ONLY write — no repo edit, no git state change.
**Checkout (verified §0 below):** MAIN `v11-dev` at `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`, HEAD `c4beb8d`. NOT a worktree.
**Date:** 2026-06-17.
**Governing design docs (attribution table in §2):**
- **NEW** = `/tmp/handoff-bd221-agent-migration/DESIGN-AGENT-MIGRATION-MODEL.md` (the corrected agent-migration model).
- **FINAL2** = `/tmp/handoff-bd221-planner-final2/PLAN-BD-221-ANTIGRAVITY-COMPLETION-FINAL2.md` (the original cluster plan).

---

## 0. PLACEMENT + STATE-OF-WORLD CORRECTION (read this first)

### 0.1 Placement (verified)
`pwd` = `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`; `git rev-parse --short HEAD` = `c4beb8d`; branch `v11-dev`. This is the MAIN checkout, not a `.claude/worktrees/agent-…` path. Four held worktrees (all at `bc7e762`) exist and are NOT this plan's target.

### 0.2 IMPORTANT — the prompt's "committed code CX1 corrects" premise is NOT yet true (CX1 is UNWRITTEN)

The spawn prompt says "The committed code CX1 corrects: [7 files]." **Measured fact: CX1 is NOT committed.** There is no CX1 commit anywhere in history (EB-1). The 7 files still carry the C7 (defective) agent handling: the migrator bundle block is still non-clobber (`if [[ ! -f "$bundle_dest" ]]`, EB-2), and `customization-preserve.sh` still has NO `.agents-plugin` classifier leg (EB-2). **This plan therefore PLANS CX1 as a commit to be authored, not one already landed** — that is the correct reading of the prompt's §"PLAN THESE" item 1 ("CX1 … the 6-file correction per DESIGN §6.1"). The "committed code CX1 corrects" phrasing describes the FILES CX1 edits (their current pre-CX1 content), not a CX1 that already exists. Every downstream step (C8-redo, C11-redo, C12) treats CX1 as a prerequisite commit this plan sequences first.

### 0.3 IMPORTANT — validate-pack is ALREADY GREEN at HEAD; the FINAL2 "march to one green-point" regime is OVER

FINAL2 was authored at HEAD `9d8bf22` (before C0) with a 62-line clean baseline and an intermediate-red cluster marching to a single green-point at C11/C12. **That regime no longer applies.** Measured fact: `python3 scripts/validate-pack.py` at HEAD `c4beb8d` reports **PASSED — all checks clean** (EB-3). C0–C7 are committed AND validate-pack reached green at C4 (the green-maker) and stayed green through C5/C6/C7 + the two BD-189 docs commits. Consequence for THIS plan:

- The remaining commits (CX1, C8-redo, C9, C10, C11-redo) are NOT intermediate-red. **Each must KEEP validate-pack green** (NEW fail-line set EMPTY per commit). There is no "single green-point" to march to — the cluster is green NOW and must STAY green.
- The per-commit verification criterion simplifies to: **BASE (parent) validate-pack = green; AFTER (post-edit) validate-pack = green; NEW = ∅.** No `comm`-mapped-to-restore bookkeeping is needed because there are no expected reds to restore. (The FINAL2 §1 fail-LINE `comm` machinery still APPLIES as the measurement method — it just resolves to NEW = ∅ for every remaining commit.)
- **Push discipline (carried from FINAL2 CONFIRMED-C):** the whole cluster still PUSHES AS ONE UNIT after the last content commit is locally green + full-suite green. C0–C7 are committed-but-UNPUSHED; CX1/C8/C9/C10/C11/C13 ride the same single push.

### 0.4 The fix-forward posture (user-frozen)
C7 has 2 agent-handling defects (D1 non-clobber bundle; D2 custom `x-` retired-not-bundled, per NEW §4 EB-1/2/4). User chose **FIX-FORWARD**: a NEW commit **CX1** supersedes C7's agent handling. **C7 stays committed; NO rollback, NO history rewrite.** CX1 lands the corrected behavior on top of C7.

---

## 1. GOAL + BD ITEMS ADDRESSED

**Goal:** complete the remaining BD-221 cluster after the agent-migration design correction — land CX1 (the agent-migration fix-forward), commit the two review-CLEAN held patches (C9, C10), redo the two doc commits whose prose described the wrong agent behavior (C8, C11), verify the cluster green (C12), and book-keep (C13) — leaving the cluster ready for the single push.

**BD items:** BD-221 (the launch-gate conversion) + BD-201 (the MCP-config relocation, folded into BD-221 per EB-7) → both flip to Resolved at C13.

**Frozen constraints baked in (the 6 OQ resolutions — NOT re-opened):**
- **OQ-1:** bundle custom sourced from `.gemini/agents/x-*.md` → fallback `.claude/agents/x-*.md`; if the 3 copies diverged, the Gemini copy wins + flag divergence.
- **OQ-2:** customs coexisting in the pack bundle accepted; add an invariant note (`x-` reserved for client; pack agents never `x-`).
- **OQ-3:** "different" = `cmp -s` byte-identity (existing `three_way_classify` contract; no change).
- **OQ-4:** C8 + C11 abandoned + redone post-CX1; C9 + C10 committed from saved patches.
- **OQ-5:** `agy plugin install` runtime re-read = a `<!-- RE-VERIFY at impl -->` doc note (C11 docs).
- **OQ-6:** leave `init-project` fresh-init count guard as-is (do NOT make it a strict `==` that a custom-bearing bundle would fail).

---

## 2. DESIGN-DOC ATTRIBUTION TABLE (the user's #1 requirement — NO ambiguity about which doc governs which part)

| Commit | Part | Governing doc | Specific section |
|---|---|---|---|
| **CX1** | classifier legs (`.agents-plugin/*/agents/x-*`→custom-agent; `*.md`→pack-agent) + docstring | **NEW** | §5.1 "Engine-level fix" + §6.1 row 1 |
| **CX1** | migrator: bundle-via-engine (replace-if-different) + lift-Gemini-custom-into-bundle + retire-message rewrite | **NEW** | §5.3(A)/(B)/(C) + §6.1 row 2 |
| **CX1** | init-project `--update` bundle leg self-classify (drop forced `pack-agent`) | **NEW** | §5.2 + §6.1 row 3 |
| **CX1** | `three-way.sh` | **NEW** | §6.1 (NOT a change row — base-absent disposition §3.1; see §3.1 NOTE below: VERIFY-only) |
| **CX1** | persona-contract bundle-custom assertion | **NEW** | §6.1 row 6 |
| **CX1** | `test-migrate-v10-to-v11.sh` bundle-custom assertion | **NEW** | §6.1 row 7 |
| **CX1** | `test-customization-preserve.sh` bundle classify + replace/preserve cases | **NEW** | §6.1 row 8 + §5.1 ENCODING-SURFACE note |
| **CX1** | the agent-migration contract end-state (replace-if-different; custom→bundle) | **NEW** | §5.0 unified contract; §5.4 mapping table |
| **C8 redo** | `pack-ops/MERGE-STRATEGY.md` — the `.gemini`→`.agents` NON-AGENT conversion | **FINAL2** | §3 C8 + §5 table §7.3 |
| **C8 redo** | `pack-ops/MERGE-STRATEGY.md` — class 7/8 AGENT prose (custom→bundle, replace-if-different) | **NEW** | §5.1 ENCODING-SURFACE note (d); §5.4 mapping table |
| **C8 redo** | the other 5 pack-ops docs conversion + boundary/spawn manifests KEEP/verify | **FINAL2** | §3 C8 deltas 2/3/4; §5 table §7.3 |
| **C9** | pack-root prose + trinity verify + 3 shared pack-side skills | **FINAL2** | §3 C9 (committed from saved patch) |
| **C10** | client deliverables (project-template) + manifest | **FINAL2** | §3 C10 (committed from saved patch) |
| **C11 redo** | supporting-docs `.gemini`→`.agents` conversion + DELETE MIGRATION-v8-to-v9 | **FINAL2** | §3 C11 + §5 table §7.2 |
| **C11 redo** | migration-output narrative: customs AUTO-LIFTED into bundle; `gemini-retired-docs/` = BACKUP | **NEW** | §5.3(B)/(C); §5.4 mapping table |
| **C11 redo** | OQ-3 `.agents-plugin/` post-migration surface list + OQ-5 RE-VERIFY note + M-1 manifest regen | **FINAL2** | §3 C11 OQ-3 carry-forward; C11 review M-1 |
| **C12** | green-point verification checkpoint + grep-zero gate (A+B) | **FINAL2** | §6 + §8 all-green proof |
| **C12** | grep-zero allowlist class for mandated migration-source refs (POQ-C11-1) | **FINAL2** | §6 allowlist + C11 review POQ-C11-1 |
| **C13** | bookkeeping (BD-221/BD-201 → Resolved, `_toc.md`, README version row) | **FINAL2** | §3 C13 (CONFIRMED-D) |

**Reading rule (state in every coder/reviewer prompt):** where NEW and FINAL2 disagree about agent handling, **NEW WINS** (it post-dates and corrects FINAL2's agent model). FINAL2 governs everything that is NOT agent-migration behavior (the `.gemini`→`.agents` rename, the green-point gate, the grep-zero allowlist, the scope keywords, bookkeeping). The split is clean: NEW = the agent-update model (how the migrator/engine handle pack vs `x-` agents on the bundle surface); FINAL2 = the surface-rename + cluster mechanics.

---

## 3. AFFECTED FILES (complete list, per commit)

### 3.1 CX1 (`pack-only`) — agent-migration fix-forward (governing doc: NEW §5/§6.1)

| # | File | Change (NEW §) | Cross-ref / encoding-surface |
|---|---|---|---|
| 1 | `scripts/lib/customization-preserve.sh` | ADD 2 classifier legs (`.agents-plugin/*/agents/x-*`→`custom-agent`; `.agents-plugin/*/agents/*.md`→`pack-agent`), `x-` BEFORE `*.md`; update the classifier docstring class list | NEW §5.1; EB-2 (legs absent now) |
| 2 | `scripts/migrate-v10-to-v11.sh` | (A) REPLACE the non-clobber bundle block (~L362-389) with an engine-routed install per pack-source file (`customization_preserve "" "$ours" "$theirs" "$rel" "$dest"`, self-classify — NEW §5.3(A) Option A2); (B) ADD a step BEFORE `_v10_to_v11_retire_gemini` that lifts `.gemini/agents/x-*` (fallback `.claude/agents/x-*.md` per OQ-1) INTO the bundle, non-clobber for a same-named bundle custom, flag divergence; (C) REWRITE the retire user-message (~L530-535) to say customs were COPIED INTO the bundle + `.gemini/` retired to `gemini-retired-docs/` as BACKUP (not "manually re-create as skills"); fix the "installed additively" comments | NEW §5.3(A)/(B)/(C); EB-2 (non-clobber present now) |
| 3 | `scripts/init-project.sh` | The `cmd_update` bundle leg (L1316-1317 `_cmd_update_iter_dir ".../agents" pack-agent`): drop the forced `pack-agent` class so each bundle file self-classifies (a bundle `x-` is preserved on bump). **Fresh-init `stage_s2_agents` (L433-466) UNCHANGED** (NEW §5.2; EB-5: fresh-init builds the fixtures, so leaving it unchanged is what keeps the manifest empty). OQ-6: do NOT touch the fresh-init count guard. | NEW §5.2; EB-4/EB-5 |
| 4 | `scripts/lib/three-way.sh` | **VERIFY-ONLY (likely NO edit).** NEW §6.1's change rows (1,2,3,6,7,8) do NOT list `three-way.sh`; its `pack-update-applied`/`new-file-in-pack`/`project-shadows-new-pack` dispositions are correct as-is (EB-6) and CX1 relies on them UNCHANGED (NEW §3.1, §5.0). The prompt's 7-file list includes it; the coder VERIFIES no change is needed and states so in the IMPL-REPORT (if a base-absent leg genuinely needs adjustment, that is a surfaced finding, not a silent edit). | NEW §3.1 EB-9; EB-6 |
| 5 | `scripts/persona-contracts/contract-migration.sh` | The bundle block (L184-214) currently asserts the bundle is installed **additively** (C7 behavior). CHANGE to assert the corrected behavior: (a) pack bundle agents present (KEEP, optionally strengthen to freshness/replace-if-different); (b) ADD a leg asserting the Gemini custom `x-fakeot-domain.md` LANDS in `.agents-plugin/optiquity-agents/agents/` (NEW §6.1 row 6) | NEW §6.1 row 6; EB-6 (current additive assertion) |
| 6 | `scripts/tests/test-migrate-v10-to-v11.sh` | Group 6 (L421-456): KEEP the `gemini-retired-docs/.gemini/agents/x-ot-domain.md` backup assertion (L447 — backup still made) BUT ADD an assertion that the custom ALSO landed in `.agents-plugin/optiquity-agents/agents/x-ot-domain.md` (NEW §6.1 row 7) | NEW §6.1 row 7; EB-6 (L447 present) |
| 7 | `scripts/tests/test-customization-preserve.sh` | ADD bundle-path classify cases (`.agents-plugin/.../x-*`→`custom-agent`; `.../*.md`→`pack-agent`) + a replace-if-different case + a preserve-`x-` case for the bundle (NEW §6.1 row 8) | NEW §6.1 row 8; §5.1 ENCODING note |
| (m) | `test-fixtures/manifest.txt` | RC9-VERIFY-EMPTY: run `bash test-fixtures/build.sh --all --clean`; CX1 touches only the `--update` leg of init-project (fresh-init unchanged, EB-5), so the fixture SHAs do NOT change → manifest diff EMPTY → do NOT stage. If non-empty, STOP and surface (an unexpected fresh-init impact). | EB-5; RC9 |

**Pack-ops MERGE-STRATEGY.md is NOT in CX1.** The class 7/8 prose lives in `pack-ops/` (`project-only`-vs-`pack-only` scope; it is `pack-only` but a DOC, not a script/test) and is handled in **C8-redo** (NEW §5.1 ENCODING note (d) names MERGE-STRATEGY.md as the class-model SSOT to update in lock-step — but in a SEPARATE commit to keep CX1 a coherent code+test unit and C8 a coherent doc unit; see §4 sequence rationale).

### 3.2 C9 (`pack-only`) — committed from saved patch (governing doc: FINAL2 §3 C9)
Files (from `/tmp/handoff-bd221-C9/C9-final.patch`, EB-8): `README.md`, `QUICKSTART.md`, `LICENSE.md`, and the 3 shared pack-side skills × 3 CLIs (`.claude/.codex/.agents/skills/{commit-discipline,boundary-investigation,implementation-report}/SKILL.md`). Also REMOVES the MIGRATION-v8-to-v9 README:153 row (paired with C11's delete — FINAL2 §3.2 SPLIT). NO `test-fixtures/manifest.txt` (these are not fixture inputs — patch carries none; EB-8). Review-CLEAN (PACK-REVIEW-C9 — saved patch).

### 3.3 C10 (`project-only`) — committed from saved patch (governing doc: FINAL2 §3 C10)
Files (from `/tmp/handoff-bd221-C10/C10-final.patch`, EB-8): `project-template/README.md`, `project-template/scripts/activate-capability.sh`, `project-template/skills/{audit-methodology,boundary-investigation}/SKILL.md`, `project-template/.codex/config.toml` + `config.toml.example`, **`test-fixtures/manifest.txt`** (the 3 v11 fixture SHAs — C10 IS a fixture-input commit via project-template; PACK-REVIEW-C10 confirmed manifest changes only the 3 v11 SHAs, v10 unchanged). Review-CLEAN (PACK-REVIEW-C10.md verdict CLEAN).

### 3.4 C8 redo (`pack-only`) — abandoned worktree, fresh redo post-CX1 (governing docs: FINAL2 §3 C8 + NEW for agent prose)
Files (FINAL2 §5 table §7.3, 7 CONVERT): `pack-ops/PACK-AGENTS.md`, `MERGE-STRATEGY.md`, `OPTIONAL-FEATURES.md`, `PACK-MEMORY-RATIONALE.md`, `DRY-RUN-MIGRATION.md`, `BOUNDARY-DEFINITION.md`, `CONCEPTUAL-REVIEW-METHODOLOGY.md`. KEEP/verify-only: `.boundary-pointer-manifest.txt`, `.spawn-rule-manifest.txt` (FINAL2 delta 2). `test-fixtures/manifest.txt` regen (pack-ops/ touched; expected EMPTY — pack-ops is not a fixture input; stage only if non-empty). **The MERGE-STRATEGY.md class-7/8 prose MUST describe CX1's CORRECTED behavior** (custom→bundle, replace-if-different) — this directly fixes the C8 review SHOULD finding (PACK-REVIEW-C8 §3(c): the held C8 said "relocate into the Antigravity bundle" which was wrong under C7 but is NOW TRUE under CX1; under CX1 the prose is correct as the held draft wrote it, so the redo must verify the prose matches CX1, not the C7 code).

### 3.5 C11 redo (`project-only`) — abandoned worktree, fresh redo post-CX1 (governing docs: FINAL2 §3 C11 + NEW for migration narrative)
Files (FINAL2 §5 table §7.2, 7 CONVERT + 1 DELETE): CONVERT `INSTALL-PROCEDURES.md`, `METHODOLOGY.md`, `SETUP-NEW.md`, `CLI-PM-SETUP.md`, `SETUP-EXISTING.md`, `DEPENDENCIES.md`, `MIGRATION-v10-to-v11.md`; DELETE `MIGRATION-v8-to-v9.md`. **M-1 (C11 review BLOCKER): regen + stage `test-fixtures/manifest.txt`** — `METHODOLOGY.md` + `INSTALL-PROCEDURES.md` are copied into the v11 fixtures by init-project S6 (L677-693), so C11 edits change the 3 v11 fixture SHAs. **NARRATIVE under NEW:** the post-migration surface lists must say customs are AUTO-LIFTED into `.agents-plugin/optiquity-agents/` (NOT "manually re-create as skills"); `gemini-retired-docs/` is a BACKUP; OQ-3 names `.agents-plugin/optiquity-agents/`; OQ-5 `agy plugin install` carries a `<!-- RE-VERIFY at impl -->` note (S-1 from C11 review).

### 3.6 C12 (verification checkpoint, NEUTRAL if a residual fix is needed) (governing doc: FINAL2 §6/§8)
NONE in the clean case. Residual case: whatever the grep-zero gate flags + manifest if v11-surface.

### 3.7 C13 (`pack-chat-only`) — bookkeeping (governing doc: FINAL2 §3 C13, CONFIRMED-D)
`backlog/BD-221.md` (Open→Resolved + Resolved: line); `backlog/BD-201.md` (Deferred→Resolved-under-BD-221, EB-7); regenerate `backlog/_toc.md`; README.md version-table row if a version bump attaches. Pack-Chat-direct (per `pack-chat-minor-edits-only`).

---

## 4. COMMIT SEQUENCE (ordered, with deps + scope keyword + green-state + manifest handling)

The dependency-driven order is: **CX1 first** (the code/test correction; everything else's prose must describe it); **C9 + C10** any time after CX1 (independent of it — disjoint paths, EB-8); **C10 BEFORE C11** (cumulative manifest co-ownership, §5); **C8-redo + C11-redo after CX1** (their prose describes CX1's behavior); **C12 last content** (verification); **C13 last** (bookkeeping). Each commit = fresh `pack-coder` → bounded review/fix cycle (max 2 review/fix pairs + 1 final reviewer; architect escalation if dirty after final) → user commit-gate. C9/C10 are apply-from-saved-patch (no fresh coder needed for the EDIT — the patches are review-CLEAN; a fresh reviewer re-verifies post-apply against current HEAD).

| Step | Commit | Scope keyword | Deps | validate-pack expectation | Manifest handling |
|---|---|---|---|---|---|
| 1 | **CX1** | `pack-only` | C7 (HEAD) | GREEN before, GREEN after (NEW = ∅) | RC9-verify-EMPTY (fresh-init unchanged); do NOT stage |
| 2 | **C9** | `pack-only` | CX1 (or HEAD — disjoint) | GREEN after (NEW = ∅) | none (patch carries none; verify build.sh empty) |
| 3 | **C10** | `project-only` | CX1/C9 (disjoint) | GREEN after (NEW = ∅) | C10 commits its post-C10 manifest (3 v11 SHAs; in the saved patch) |
| 4 | **C8 redo** | `pack-only` | CX1 (prose describes CX1 behavior) | GREEN after (NEW = ∅; Check 40/44/45/46/56 stay green) | regen; expect EMPTY (pack-ops not a fixture input); stage only if non-empty |
| 5 | **C11 redo** | `project-only` | CX1 (NEW narrative), C10 (cumulative manifest) | GREEN after (NEW = ∅) | **M-1: regen in MAIN post-C10+C11; stage the cumulative manifest** (§5) |
| 6 | **C12** | NEUTRAL (only if a residual commit) | ALL of CX1/C8/C9/C10/C11 | GREEN; both grep-zero gates = KEEP allowlist; full suite green | residual case only |
| 7 | **C13** | `pack-chat-only` | C12 green | GREEN (status flip + `_toc.md` regen) | none |
| — | **PUSH** the whole cluster (C0…C13) as ONE unit | — | C12/C13 green | — | — |

**Ordering notes:**
- CX1 MUST precede C8-redo and C11-redo: both describe agent-migration behavior in prose, and that prose must match CX1's CODE, not C7's. Writing the docs first would re-introduce the C7-vs-doc mismatch the C8 review caught.
- C9 and C10 are independent of CX1 (disjoint paths — EB-8: C9 = pack-root prose/skills/LICENSE/QUICKSTART/README; C10 = project-template/config + manifest; CX1 = `scripts/`). They may land in any position after CX1. Recommended position: right after CX1 (clean `pack-only` then `project-only` blocks), and C10 BEFORE C11 for the cumulative manifest.
- C10 BEFORE C11 is REQUIRED by the manifest co-ownership (§5): both change the v11 fixtures; C10 commits its manifest, then C11 regenerates the cumulative (post-C10+C11) manifest in main and stages it.

---

## 5. MANIFEST CO-OWNERSHIP (C10 AND C11 both change the v11 fixtures)

**The problem (C11 review M-1 + out-of-scope tracker §B):** the v11 fixtures are init-built (EB-5, build.sh L126 `init-project.sh "$target"`). C10 changes the v11 fixtures via `project-template/` edits (init-project copies project-template into the fixture). C11 changes the v11 fixtures via `supporting-docs/{METHODOLOGY,INSTALL-PROCEDURES}.md` (init-project S6 L677-693 copies these two into each fixture's `docs/pack/`). So BOTH commits drive the 3 v11 fixture SHAs → the manifest is CO-OWNED.

**The handling (cumulative, in MAIN — do NOT trust isolated-worktree manifests):**
1. **C10** commits its saved patch, which INCLUDES `test-fixtures/manifest.txt` reflecting the post-C10 fixture state (the C10 patch carries the manifest, EB-8; PACK-REVIEW-C10 confirmed it changes only the 3 v11 SHAs).
2. **C11** (which lands AFTER C10): after the C11 prose edits are applied in main, run `bash test-fixtures/build.sh --all --clean` IN MAIN (post-C10+C11 tree) and stage the resulting `test-fixtures/manifest.txt` into the C11 commit. This captures the CUMULATIVE C10+C11 fixture state. The C11 isolated-worktree manifest (if any) is based at `bc7e762` without C10's project-template edits and is STALE — discard it; regenerate in main.
3. CX1, C8 also run `build.sh --all --clean` (RC9), but expect EMPTY diffs (CX1's fresh-init is unchanged, EB-5; pack-ops is not a fixture input) — stage only if non-empty.

**Scope-neutral ride:** `test-fixtures/manifest.txt` is in `_SCOPE_NEUTRAL_GENERATED_PATHS` (FINAL2 EB-P2), so it rides BOTH `project-only` (C10/C11) and `pack-only` (CX1/C8) commits without tripping Check 36.

---

## 6. CX1 IN DETAIL (the fix-forward — NEW §5/§6.1)

### 6.1 The corrected contract (NEW §5.0)
"On any pack version event (fresh init / `--update` bump / vN→vM migrate), for each agent surface: ADD pack agents the client lacks; REPLACE pack agents the client has but that DIFFER from the new pack version; KEEP (never overwrite) `x-` custom agents; surface a sidecar when a pack agent was BOTH client-edited AND pack-changed." One engine (`customization_preserve` + `three_way_classify`), three call sites (fresh init / `cmd_update` / migrate), two surface shapes (loose `.claude/.codex/agents/` + the `.agents-plugin/.../agents/` bundle).

### 6.2 The keystone fix (NEW §5.1) — classifier legs
`customization_classify` gains (ordered `x-` first):
```
.agents-plugin/*/agents/x-*           -> custom-agent
.agents-plugin/*/agents/*.md          -> pack-agent
```
Use a glob matching the plugin-namespace dir (`.agents-plugin/*/agents/...`) so the leg does not hard-code `optiquity-agents`. ENCODING-SURFACE lock-step (NEW §5.1): (a) the classifier branch, (b) the classifier docstring class list, (c) `test-customization-preserve.sh` (pins the classifier set), (d) `pack-ops/MERGE-STRATEGY.md` class 7/8 prose — but (d) lands in C8-redo, NOT CX1 (separate scope-coherent commits; the C8 redo is sequenced after CX1 specifically so the prose describes the landed code).

### 6.3 The migrator changes (NEW §5.3)
- **(A)** Replace the non-clobber bundle block (EB-2, current `if [[ ! -f "$bundle_dest" ]]`) with a per-pack-source-file call `customization_preserve "" "$ours" "$theirs" "$rel" "$dest"` (Option A2 — base "" net-new surface; self-classify via §6.2). On v10→v11 `ours` is absent → clean add (NEW §3.1 EB-9).
- **(B)** Before `_v10_to_v11_retire_gemini`, lift each `.gemini/agents/x-*` (fallback `.claude/agents/x-*.md` per OQ-1) into `.agents-plugin/optiquity-agents/agents/<name>` IFF not already present (non-clobber a same-named bundle custom). On divergence of the 3 copies, the Gemini copy wins + flag (OQ-1).
- **(C)** Retire-message rewrite: customs were COPIED INTO the bundle; `.gemini/` retired to `gemini-retired-docs/` as a BACKUP (NOT "manually re-create"). The `.gemini/` STANDARD skill mirrors stay retired-only (only AGENTS are lifted — NEW §5.3 note).

### 6.4 base-absent benignity (NEW §3.1)
The bundle is net-new in v11 → no v10 baseline. On v10→v11 migration `ours` is always absent → `new-file-in-pack` → clean add, no sidecar (EB-9). The base-absent ambiguity only bites a v11→v11 re-bump and is handled conservatively (sidecar) — pre-existing and accepted (matches how `init-project.sh --update` already passes base="").

### 6.5 CX1 manifest claim (EB-5)
CX1's init-project edit is confined to the `cmd_update` `--update` leg (L1316). Fresh-init `stage_s2_agents` (L433-466) is UNCHANGED (NEW §5.2). The committed v11 fixtures are built by FRESH init (build.sh L126 → `stage_s2_agents` at L1540), NOT the `--update` leg and NOT the migrator (manifest tracks 0 `agents-plugin`/migrator lines, EB-5). Therefore CX1 changes NO committed fixture → manifest diff EMPTY. RC9 still requires running `build.sh --all --clean` and staging IF non-empty (expect empty; STOP+surface if not).

---

## 7. VERIFICATION PLAN

### 7.1 Per-commit (every remaining commit)
Validate-pack is GREEN at the parent and MUST stay GREEN. Coder PREFLIGHT (per FINAL2 §7, simplified to the green-stays-green regime):
0. Confirm `git status --short` EMPTY at the commit's parent; `python3 scripts/validate-pack.py` exit 0 (BASE green; capture `BASE = validate-pack 2>&1 | grep -E '^FAIL:' | sort` → expect EMPTY).
1. All in-scope edits complete.
2. Run the commit's LOCKSTEP tests (CX1: every migrator/detect/customization/persona test — they are CI-wired; quote each exit status). C8/C11: the relevant stay-green checks.
3. Run the FULL wired test suite (every script in `.github/workflows/validate-pack.yml` `tests`-job shard matrix + `validate-pack.py` general + `PACK_VALIDATE_DEEP=1`). Sampling is the defect (`verify-full-ci-suite`).
4. Baseline-delta: capture `AFTER = validate-pack 2>&1 | grep -E '^FAIL:' | sort`; `NEW = comm -13 base.txt after.txt` MUST be EMPTY (the cluster is green; no expected reds remain). Any NEW line = UNEXPECTED red → STOP, no partial IMPL-REPORT, surface it.
5. Manifest per §5 (RC9): CX1/C8 expect empty; C10 carries its manifest; C11 regenerates the cumulative post-C10+C11 manifest in main.
6. Emit `PREFLIGHT: N/N in-scope edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to <path>`, then the IMPL-REPORT.

### 7.2 CX1-specific verification (the agent-migration behavior)
- Run `test-migrate-v10-to-v11.sh` Group 6 — confirm BOTH the `gemini-retired-docs/.gemini/agents/x-ot-domain.md` BACKUP assertion AND the new `.agents-plugin/optiquity-agents/agents/x-ot-domain.md` LIFTED assertion pass.
- Run `test-customization-preserve.sh` — confirm the bundle classify cases (`x-`→custom-agent; `*.md`→pack-agent) + replace-if-different + preserve-`x-` cases pass.
- Run `test-persona-contracts.sh` (fixture-dependent shard) — confirm `contract-migration.sh`'s new bundle-custom-landed leg passes.
- HARD behavioral check (NEW §4 reproduction reversed): run the migrator against a `/tmp` clone of `test-fixtures/v10-realistic-ot` (NEVER the real fixture); confirm post-migrate the bundle CONTAINS `x-fakeot-domain.md` (D2 fixed) AND a changed pack bundle agent is REPLACED (D1 fixed). Use `/tmp` scratch only; clean up.

### 7.3 C8/C11 redo verification (stay-green)
- **C8 stay-green set (reviewer checklist):** Check 40 (pack-ops bare-cross-ref, 10 docs), 44 (concision), 45 (bijection), 46 (manifests verify-only, unedited), 56 (verb parity). All must stay green (FINAL2 §3 C8). Verify MERGE-STRATEGY class 7/8 prose now MATCHES CX1's landed code (the C8 review SHOULD inverts: under CX1, "relocate into the Antigravity bundle" is TRUE).
- **C11 stay-green:** Check 2 unaffected (supporting-docs prose); Check 48 soft-advisory (delete trips no gate, C11 review confirmed). Verify OQ-3 (both SETUP-EXISTING + MIGRATION-v10-to-v11 name `.agents-plugin/optiquity-agents/`), M-1 manifest staged (cumulative), OQ-5 RE-VERIFY note on `agy plugin install`.

### 7.4 C12 green-point gate (FINAL2 §6/§8)
- `python3 scripts/validate-pack.py` exit 0; `PACK_VALIDATE_DEEP=1` exit 0.
- Every script in the validate-pack.yml `tests`-job shard matrix exit 0.
- `python3 scripts/lib/ci-shard-plan.py --assert-coverage` green.
- Gate A (`.gemini/` PATH) + Gate B (bare `gemini` TOKEN, widened to prose docs) return EXACTLY the KEEP allowlist (§8).
- `bash test-fixtures/build.sh --verify` green against the regenerated (cumulative) manifest.

### 7.5 grep audits
Gate A/B per FINAL2 §6 over `scripts project-template supporting-docs pack-ops .claude .codex .agents .agents-plugin README.md QUICKSTART.md LICENSE.md GEMINI.md AGENTS.md CLAUDE.md test-fixtures/build.sh test-fixtures/README.md`.

---

## 8. C12 GREP-ZERO KEEP ALLOWLIST (measure-then-bound; POQ-C11-1 sized exactly)

Per `ci-guard-measure-then-bound` + `rename-plans-measure-then-bound`. The C12 gate must return ONLY the KEEP classes. The FINAL2 §6 allowlist classes 1-8 carry over UNCHANGED. **The NEW class required by the redo (POQ-C11-1, sized measure-then-bound from PACK-REVIEW-C11 §3):**

- **Class POQ-C11-1a — mandated migration-source `.gemini/` PATH refs (Gate A + B), exactly 13 lines:**
  `supporting-docs/MIGRATION-v10-to-v11.md:61,361,382,385,388,404,462,603` (8) +
  `supporting-docs/SETUP-EXISTING.md:316,319,322,341,359` (5).
  These are the `.gemini/` directory the migrator narrative describes retiring — MANDATED by OQ-3 + the migration narrative, not residue.
- **Class POQ-C11-1b — `gemini-retired-docs/` holding-dir name (Gate B; bare token, no `.gemini/` path), 10 occurrences** across `MIGRATION-v10-to-v11.md` (:62,389,404,462,603 etc.) + `SETUP-EXISTING.md` (:342,345,359). The holding-dir name the migrator creates — mandated.

**SIZING CAVEAT (state in the C12 coder/reviewer prompt):** these exact file:line counts are from PACK-REVIEW-C11 at `bc7e762` (the ABANDONED C11 worktree). The C11 **redo** re-authors these docs, so the line numbers WILL drift and the count may change (the NEW migration narrative is similar but re-written). **Therefore size the C12 allowlist measure-then-bound at C12 TIME against the ACTUAL redone C11 content** — do NOT hard-code the 13/10 counts. The bound is: every `.gemini/`/`gemini-retired-docs/` hit in the redone supporting-docs must be a migration-source reference (KEEP); any hit that is NOT a migration-source ref is residue (STRIP → fix in C12 residual or push back to C11). The 13+10 are the EXPECTED magnitude, not a frozen allowlist.

**Standing KEEP classes (FINAL2 §6, verify-only):** `~/.gemini/GEMINI.md` global (CLI-PM-SETUP.md:164); `GEMINI.md` trinity FILE tokens; `#27305` hedges in `.agents-plugin/optiquity-agents/**`; v10 fixture carve-out; migrator/detect legacy-READ carve-out; version-history rows (README:62,65). **No allowlist GROWS** beyond the POQ-C11-1 class (which admits only mandated migration-source refs). The Check 47 `_SANCTIONED_PACK_SIDE_SHIPPED` stays at exactly 2 (no new pack-side-shipped file); `_CHECK_43_ALLOWLIST` stays at exactly 8.

---

## 9. OUT-OF-SCOPE FINDINGS (tracked elsewhere — NOT part of this plan)

These exist in `/tmp/handoff-bd221-outofscope/OUT-OF-SCOPE-FINDINGS.md` §C and are addressed AFTER the cluster (user directive). NOTED here only so the coders surface-not-fix them if encountered:
- **POQ-C9-1** — stale "(4)" agent count → 5 (pack-root surfaces + wider grep). NOT in C9's saved patch scope.
- **F-2** — 5 genuine BD-214 leaks in client docs (4× DEPENDENCIES.md + 1× METHODOLOGY.md). Pre-existing; the C11 redo MUST NOT introduce net-new BD refs but is NOT chartered to FIX the pre-existing 5.
- **F-3** — stale `.mcp.json.example` ref at `project-template/docs/pack/PM-CHAT.md:824`. NOT in C10/C11 diff scope; the C12 Gate A (scans `project-template`) may surface it as a residual — if so, it becomes a C12 NEUTRAL residual fix OR is pushed to the post-cluster cleanup (user directive: out-of-scope findings handled after the cluster).

If C12's Gate A flags F-3, surface it to the user for the keep-in-C12-vs-defer-to-post-cluster decision (do NOT silently fold a pre-existing out-of-scope fix into C12).

---

## 10. OPEN RISKS / UNKNOWNS

- **RISK-1 — CX1 is the load-bearing agent-migration fix; if the engine-routing (A2) mis-handles base-absent, a v10→v11 migration could sidecar instead of clean-add.** Mitigation: NEW §3.1 EB-9 proves base-absent + ours-absent → `new-file-in-pack` (clean add) on v10→v11; CX1's `test-migrate-v10-to-v11.sh` Group 6 + the HARD `/tmp`-clone behavioral check (§7.2) verify the actual end state. Bounded review/fix cycle guards it.
- **RISK-2 — `three-way.sh` in the prompt's 7-file set but not in NEW's change rows.** Mitigation: CX1 treats it VERIFY-ONLY (§3.1 row 4); the coder states explicitly in the IMPL-REPORT whether any edit was needed. If the coder finds a genuine base-absent leg needing adjustment, that is a SURFACED finding for user triage, not a silent edit. **MAINTAINER CHECK NEEDED if the coder finds three-way.sh needs a real edit** — that would mean NEW §6.1 under-enumerated and the design needs a re-look.
- **RISK-3 — C8-redo MERGE-STRATEGY prose vs the held C8 draft.** The held C8 worktree's prose ("relocate into the Antigravity bundle") was a SHOULD finding under C7 (wrong) but is CORRECT under CX1. The redo MUST verify the prose matches the LANDED CX1 code, not re-introduce a mismatch. Mitigation: C8-redo is sequenced strictly after CX1; the coder reads the landed CX1 migrator/classifier before writing the class 7/8 prose.
- **RISK-4 — manifest co-ownership (C10+C11).** Mitigation: §5 — C10 commits its manifest; C11 regenerates the cumulative manifest in MAIN post-C10+C11 (never trust the isolated-worktree manifest). The C11 coder runs `build.sh --all --clean` in main.
- **RISK-5 — C9/C10 saved patches drift if other commits land between now and apply.** Mitigation: EB-8 confirms both apply CLEAN against current HEAD `c4beb8d`; they touch paths disjoint from CX1/C8/C11. RE-RUN `git apply --check` immediately before applying each (if CX1 or C8 landed first, re-check — but they touch `scripts/`/`pack-ops/`, disjoint from C9's pack-root-prose/C10's project-template).
- **RISK-6 — C11 redo line-number drift breaks the POQ-C11-1 hard-coded allowlist.** Mitigation: §8 SIZING CAVEAT — size the C12 allowlist at C12 time against the actual redone content, not the `bc7e762` counts.
- **RISK-7 — held worktrees + abandonment.** The 4 held worktrees (all at `bc7e762`) are stale relative to HEAD `c4beb8d` (BD-189 docs landed since). C8/C11 worktrees are ABANDONED (OQ-4) — the orchestrator removes them (`git worktree remove`, a state-changing verb = orchestrator-only; agents never run it). C9/C10 are apply-from-saved-patch (the worktrees can be removed too; the saved patches are the source of truth). **MAINTAINER CHECK NEEDED: orchestrator confirms the 4 worktrees are removed before/after the redo** (agents cannot remove them).
- **RISK-8 — scope-keyword token trap (Check 36).** Each commit subject carries AT MOST its claimed keyword in trailing position; no keyword token in prose. CX1/C8 = `pack-only`; C9 = `pack-only`; C10/C11 = `project-only`; C12 = NEUTRAL (residual case); C13 = `pack-chat-only`. The manifest rides scope-neutral (§5).

---

## 11. WORKTREE PLAN (isolation regime — orchestrator actions; agents never run git state-changers)

| Commit | Worktree action | Rationale |
|---|---|---|
| **CX1** | FRESH worktree off HEAD `c4beb8d` (`worktree.baseRef:head`); coder emits patch to `/tmp` handoff; orchestrator `git apply` → commit; remove worktree | Code+test correction; needs its own review cycle (NEW §6.4 Option-1) |
| **C9** | NO fresh coder; apply `/tmp/handoff-bd221-C9/C9-final.patch` in MAIN (or a fresh worktree); fresh reviewer re-verifies post-apply; remove any worktree | Review-CLEAN saved patch; applies clean (EB-8) |
| **C10** | NO fresh coder; apply `/tmp/handoff-bd221-C10/C10-final.patch`; fresh reviewer re-verifies; remove any worktree | Review-CLEAN saved patch; applies clean (EB-8) |
| **C8 redo** | FRESH worktree off post-CX1 HEAD; fresh coder; review cycle; remove worktree | Held C8 worktree ABANDONED (OQ-4); redo against CX1's landed code |
| **C11 redo** | FRESH worktree off post-C10 HEAD (for cumulative manifest); fresh coder; review cycle; remove worktree | Held C11 worktree ABANDONED (OQ-4); redo against CX1 narrative + C10 manifest |
| **C12** | verification in MAIN (no worktree); residual fix → fresh worktree if needed | green-point gate |
| **C13** | Pack-Chat-direct in MAIN (no coder, no worktree) | bookkeeping (CONFIRMED-D) |

**Standing isolation gotchas (from live BD-219 use):** isolated worktree bases at parent HEAD (`baseRef:head`); coder emits `/tmp` patch; orchestrator runs `git update-index -q --refresh` BEFORE `git apply` (stat-cache noise else fails); worktrees do NOT auto-remove (orchestrator removes explicitly); reviewer runs IN-PLACE. The 4 abandoned/held worktrees must be removed by the orchestrator.


---

## 12. EMPIRICAL-EVIDENCE BLOCKS

All commands run read-only on 2026-06-17 in the MAIN checkout at HEAD `c4beb8d` (branch `v11-dev`). No state-changing git verb.

**EB-1 — CX1 is NOT committed (the prompt's "committed code" premise is the pre-CX1 file state, not a landed commit).**
- **Command:** `git log --oneline -15`; `git log --all --oneline | grep -iE "CX1|fix-forward|non-clobber|replace-if-diff|bundle.custom"`.
- **Output (verbatim, key):** HEAD = `c4beb8d docs: v11 — BD-189 split audit trail … (pack-only)`; the most recent BD-221 migrator commit = `3ebbeaa feat: v11 — BD-221 C7 persona-contracts Antigravity conversion + migrator Antigravity-bundle install (pack-only)`; the `grep` for CX1-style commits returned EMPTY (no output).
- **HEAD/date:** `c4beb8d`, 2026-06-17.
- **Interpretation:** there is no CX1 commit. C7 (`3ebbeaa` + audit `bc7e762`) is the latest BD-221 migrator work. CX1 is UNWRITTEN — this plan sequences it as the first remaining commit.
- **Conclusion:** SUPPORTED (the "committed CX1" premise is NOT-SUPPORTED; CX1 must be authored).

**EB-2 — the C7 agent-handling defects (D1 non-clobber; classifier-leg absence) are STILL PRESENT at HEAD (so CX1 has work to do).**
- **Command:** `grep -nE "agents-plugin" scripts/lib/customization-preserve.sh`; `grep -nE "bundle_dest|! -f .*bundle" scripts/migrate-v10-to-v11.sh`.
- **Output (verbatim, key):** `customization-preserve.sh` → "NO .agents-plugin classifier leg present" (grep empty); `migrate-v10-to-v11.sh:368  if [[ ! -f "$bundle_dest" ]]; then` + L367 `bundle_dest="$_MIGRATOR_TARGET/.agents-plugin/optiquity-agents/$rel"` + L376 comment "Assert every PACK bundle agent is …".
- **HEAD/date:** `c4beb8d`, 2026-06-17.
- **Interpretation:** D1 (non-clobber `if [[ ! -f ]]`) and the missing classifier legs (D2 root cause) are both live in the committed code — CX1's NEW §5.1/§5.3 changes are real, not no-ops.
- **Conclusion:** SUPPORTED.

**EB-3 — validate-pack is ALREADY GREEN at HEAD (the cluster has reached green; no march-to-green-point remains).**
- **Command:** `python3 scripts/validate-pack.py 2>&1 | tail -3`.
- **Output (verbatim):** `============================================================` / `PASSED — all checks clean`.
- **HEAD/date:** `c4beb8d`, 2026-06-17.
- **Interpretation:** C0–C7 are committed AND validate-pack is green (C4 was the green-maker; C5/C6/C7 + BD-189 docs kept it green). Every remaining commit must KEEP green (NEW = ∅), not march to a single green-point. The FINAL2 62-line baseline + intermediate-red model is superseded by the current state.
- **Conclusion:** SUPPORTED.

**EB-4 — CX1's init-project change is the `--update` (cmd_update) leg; fresh-init `stage_s2_agents` is separate.**
- **Command:** `grep -n "_cmd_update_iter_dir" scripts/init-project.sh | grep optiquity-agents`; `grep -n "stage_s2_agents\|bundle_count == pack_count\|cp -R" scripts/init-project.sh`.
- **Output (verbatim, key):** `1316:    _cmd_update_iter_dir "project-template/.agents-plugin/optiquity-agents/agents" \`; `433:stage_s2_agents() {`; `454:    cp -R "$bundle_src" "$TARGET/.agents-plugin/"`; `466:    (( bundle_count == pack_count )) || \`; `1540:    stage_s2_agents`.
- **HEAD/date:** `c4beb8d`, 2026-06-17.
- **Interpretation:** the CX1 init-project edit (NEW §5.2, drop forced `pack-agent`) is at L1316 in `cmd_update` (the `--update` bump leg). Fresh-init `stage_s2_agents` (L433-466, whole-bundle `cp -R` + count guard) is UNCHANGED by CX1 and is the path that runs at fresh install (called at L1540).
- **Conclusion:** SUPPORTED.

**EB-5 — v11 fixtures are FRESH-INIT-built (not migrator-built, not `--update`-built); manifest tracks no migrator output → CX1 manifest diff is EMPTY.**
- **Command:** `grep -nE "init-project|migrate-v10" test-fixtures/build.sh`; `grep -c "agents-plugin" test-fixtures/manifest.txt`.
- **Output (verbatim, key):** build.sh L119 `PACK="$v10_src" bash "$v10_src/scripts/init-project.sh" "$target"` (v10 fixtures); L126 `PACK="$PACK_ROOT" bash "$PACK_ROOT/scripts/init-project.sh" "$target"` (v11 fixtures); no `migrate-v10-to-v11` build invocation; `grep -c agents-plugin manifest.txt` → `0`.
- **HEAD/date:** `c4beb8d`, 2026-06-17.
- **Interpretation:** the committed fixtures are produced by FRESH `init-project.sh "$target"` (→ `stage_s2_agents`, the path CX1 does NOT touch — EB-4), never the migrator and never the `--update` leg. The manifest tracks 0 `agents-plugin`/migrator lines. So CX1 (which touches only the `--update` leg + the migrator + tests) changes NO committed fixture → manifest diff EMPTY (RC9-verify-empty).
- **Conclusion:** SUPPORTED.

**EB-6 — the CX1 test/contract files currently encode the C7 (additive/retire) behavior CX1 must correct.**
- **Command:** `grep -nE "agents-plugin|x-ot-domain|x-fakeot|gemini-retired|additively" scripts/persona-contracts/contract-migration.sh scripts/tests/test-migrate-v10-to-v11.sh`; `grep -nE "pack-update-applied|new-file-in-pack|project-shadows-new-pack" scripts/lib/three-way.sh`.
- **Output (verbatim, key):** contract-migration.sh L184 "plugin bundle additively (.agents-plugin/optiquity-agents/ —", L202 `t_pass "all .agents-plugin/optiquity-agents/agents/ present post-migrate"` (presence only, no replace-if-different, no custom-lift leg); test-migrate-v10-to-v11.sh L447 `[[ -f "$G6T/gemini-retired-docs/.gemini/agents/x-ot-domain.md" ]]` (backup-only assertion, no bundle-lift assertion); three-way.sh L30 `pack-update-applied … (adopt v10)`, L35 `new-file-in-pack … base absent, ours absent, theirs present`, L39-40 `project-shadows-new-pack … base absent, ours present`.
- **HEAD/date:** `c4beb8d`, 2026-06-17.
- **Interpretation:** `contract-migration.sh` asserts ADDITIVE presence (C7 behavior — must change to assert custom-lift + replace-if-different, NEW §6.1 row 6); `test-migrate-v10-to-v11.sh` asserts only the backup copy (must ADD the bundle-lift assertion, row 7). `three-way.sh` dispositions are correct as-is for CX1's base-absent path (`new-file-in-pack` on v10→v11) — confirming it is VERIFY-ONLY (§3.1 row 4), NOT a change row.
- **Conclusion:** SUPPORTED.

**EB-7 — BD-201 is currently Status: Deferred, folded into BD-221 (C13 flips it to Resolved-under-BD-221).**
- **Command:** `grep -nE "^Status:|^Resolved:|FOLDED|folded" backlog/BD-201.md`; `grep -nE "^Status:|^Resolved:" backlog/BD-221.md`.
- **Output (verbatim, key):** BD-201 `4:Status: Deferred`; L10 "it is FOLDED INTO BD-221 and lands in v11.0 with it … Track/resolve it under BD-221"; `11:Resolved: n/a`. BD-221 `4:Status: Open`; `22:Resolved: n/a`.
- **HEAD/date:** `c4beb8d`, 2026-06-17.
- **Interpretation:** C13 flips BD-201 Deferred→Resolved-under-BD-221 and BD-221 Open→Resolved (on batch completion).
- **Conclusion:** SUPPORTED.

**EB-8 — the C9 + C10 saved patches APPLY CLEAN against current HEAD `c4beb8d` and touch paths DISJOINT from CX1's `scripts/`.**
- **Command:** `git apply --check /tmp/handoff-bd221-C9/C9-final.patch`; `git apply --check /tmp/handoff-bd221-C10/C10-final.patch`; `grep "^diff --git" <each patch>`; `git diff --name-only bc7e762 c4beb8d`.
- **Output (verbatim, key):** "C9 APPLIES CLEAN"; "C10 APPLIES CLEAN". C9 patch files = `.agents/.claude/.codex/skills/{boundary-investigation,commit-discipline,implementation-report}/SKILL.md`, `LICENSE.md`, `QUICKSTART.md`, `README.md` (12 files, no manifest). C10 patch files = `project-template/.codex/config.toml` + `config.toml.example`, `project-template/README.md`, `project-template/scripts/activate-capability.sh`, `project-template/skills/{audit-methodology,boundary-investigation}/SKILL.md`, `test-fixtures/manifest.txt`. The `bc7e762..c4beb8d` diff = only `backlog/*` + `maintenance-docs/*` (BD-189/186/227 docs — disjoint from both patches).
- **HEAD/date:** `c4beb8d`, 2026-06-17.
- **Interpretation:** both patches apply CLEAN at current HEAD; the BD-189 commits since `bc7e762` touched only backlog/maintenance-docs (no overlap). C9 (pack-root prose/skills) and C10 (project-template + manifest) are disjoint from CX1 (`scripts/lib`, `scripts/migrate…`, `scripts/init-project.sh`, `scripts/persona-contracts`, `scripts/tests`). So applying CX1 first does NOT break the C9/C10 patches (no shared files). RE-CHECK with `git apply --check` immediately before each apply (cheap insurance).
- **Conclusion:** SUPPORTED.

**EB-9 — C10 IS a fixture-input commit (carries the manifest); C11 is a fixture-input commit (METHODOLOGY+INSTALL-PROCEDURES via init-project S6) → manifest co-ownership.**
- **Command:** C10 patch file list (EB-8) shows `test-fixtures/manifest.txt`; PACK-REVIEW-C10.md verdict; PACK-REVIEW-C11.md M-1 root-cause trace (init-project S6 L677-693 copies METHODOLOGY+INSTALL-PROCEDURES into v11 fixtures).
- **Output (verbatim, key):** C10 patch includes `diff --git a/test-fixtures/manifest.txt b/test-fixtures/manifest.txt`; PACK-REVIEW-C10 "the manifest changes only the 3 v11 fixture SHAs (v10 UNCHANGED)"; PACK-REVIEW-C11 M-1 "init-project.sh S6 (lines 677–693) copies supporting-docs/METHODOLOGY.md and supporting-docs/INSTALL-PROCEDURES.md into each fixture's docs/pack/ … all three v11 fixtures' SHAs changed".
- **HEAD/date:** `c4beb8d`, 2026-06-17.
- **Interpretation:** both C10 (via project-template) and C11 (via the 2 copied supporting-docs) drive the 3 v11 fixture SHAs → the manifest is CO-OWNED. C10 commits its post-C10 manifest; C11 regenerates the CUMULATIVE post-C10+C11 manifest in MAIN and stages it (§5).
- **Conclusion:** SUPPORTED.

---

## 13. RULES-APPLIED VERIFICATION BLOCK

| # | Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | empirical-evidence-blocks [planner] | §12 EB-1..EB-9: every state-claim carries the actual command + verbatim output + HEAD `c4beb8d` + date 2026-06-17 + interpretation + SUPPORTED/NOT-SUPPORTED. The two flagged state-corrections — CX1-not-committed (EB-1, the prompt premise NOT-SUPPORTED) and validate-pack-already-green (EB-3) — are backed by live `git log`/`grep`/`validate-pack` runs in the MAIN checkout. The C9/C10-apply-clean claim is backed by actual `git apply --check` (EB-8); the manifest co-ownership by the patch file list + the two reviews (EB-9); the CX1-fresh-init-unchanged claim by EB-4/EB-5. | COMPLIANT |
| 2 | ci-guard-measure-then-bound [architect/planner] | §8 sizes the C12 grep-zero allowlist to the EXACT migration-source refs (POQ-C11-1a 13 lines + 1b 10 occurrences, measured in PACK-REVIEW-C11), with an explicit SIZING CAVEAT that the redone C11 content will drift the line numbers → the allowlist is re-measured at C12 time against actual redone content, not hard-coded; the bound admits ONLY mandated migration-source refs (KEEP), every other hit is STRIP. No allowlist widened: Check 47 stays at 2, `_CHECK_43_ALLOWLIST` at 8. The standing KEEP classes (FINAL2 §6) are verify-only. | COMPLIANT |
| 3 | rename-plans-measure-then-bound | §7.5 + §7.4 + §8: the C12 completeness gate is the grep-ZERO Gate A (`.gemini/` PATH) + Gate B (bare `gemini` TOKEN, widened to prose) over the full in-scope set, returning EXACTLY the KEEP allowlist; every old-token hit must be a documented KEEP or it is residue → STRIP. The per-commit PREFLIGHT (§7.1) runs the gate at C12; the cluster's green-stays-green criterion (NEW = ∅) is the validate-pack backstop. | COMPLIANT |
| 4 | no-deferral-without-user-direction | CX1 + C8/C11 redo all land in v11.0 (the cluster); no part deferred. The only forward-looking item is the OQ-5 `agy plugin install` runtime re-read, which is a `<!-- RE-VERIFY at impl -->` doc-marker hedge per the BD-221 convention (not deferred work). The out-of-scope findings (§9) are addressed AFTER the cluster per EXPLICIT user directive (OUT-OF-SCOPE-FINDINGS.md §C) — that is user-directed scheduling, not unilateral deferral; they are surfaced-not-chased, not dropped. | COMPLIANT |
| 5 | user-prescriptive-authority (the 6 frozen OQs) | §1 bakes in OQ-1..OQ-6 as binding constraints, NOT re-opened: OQ-1 (Gemini-copy source + fallback + divergence-flag) in §3.1 row 5 / §6.3(B); OQ-2 (customs coexist + invariant note) in §6.2; OQ-3 (`cmp -s` byte-identity) in §6.1 (existing three_way contract, no change); OQ-4 (C8/C11 redo, C9/C10 from patch) in §4/§11; OQ-5 (`agy plugin install` RE-VERIFY note) in §3.5/§7.3; OQ-6 (leave fresh-init count guard as-is) in §3.1 row 3. The planner designed only the HOW within these frozen WHATs; genuine unknowns (three-way.sh edit need; worktree removal) are surfaced as MAINTAINER CHECK NEEDED (§10 RISK-2/RISK-7), not decided unilaterally. | COMPLIANT |
| 6 | agents-never-commit / read-only | All git verbs read-only: `git rev-parse`, `git log`, `git worktree list`, `git status --short`, `git diff --name-only`, `git apply --check` (the CHECK form — no apply). Plus reads/greps + ONE read-only `python3 scripts/validate-pack.py` run. The SOLE write is this plan doc to `/tmp/handoff-bd221-cx1-replan/PLAN-BD-221-CX1-REPLAN.md` (outside the repo). NO source edit; NO add/commit/push/stash/checkout/merge/reset/restore/worktree-mutate/branch/tag/apply(-the-applying-form)/config. | COMPLIANT |
| 7 | agent-output-requires-rules-applied-verification-block [universal] | This table; every rule has quoted/measured evidence + a non-empty terminal conclusion (no AMBIGUOUS terminal state; no empty rows). | COMPLIANT |
| 8 | agents-read-rule-docs-in-full [universal] | Read IN FULL via the Read tool: the NEW design (DESIGN-AGENT-MIGRATION-MODEL.md, full), the FINAL2 plan (PLAN-BD-221-ANTIGRAVITY-COMPLETION-FINAL2.md, all 599 lines across paged reads), PACK-REVIEW-C8.md, PACK-REVIEW-C11.md, PACK-REVIEW-C10.md (head), OUT-OF-SCOPE-FINDINGS.md, and CLAUDE.md `## Pack memory` (via system-reminder context). The committed CX1-target files were inspected directly via grep/Read at HEAD. No derivation. | COMPLIANT |

---

## 14. FILES READ IN FULL / INSPECTED + RUNTIME REGIME

**Read in full (direct Read tool):**
- `/tmp/handoff-bd221-agent-migration/DESIGN-AGENT-MIGRATION-MODEL.md` (577 ln — the NEW design; ends "the reproduction is fully captured in EB-1/2/3/4 above").
- `/tmp/handoff-bd221-planner-final2/PLAN-BD-221-ANTIGRAVITY-COMPLETION-FINAL2.md` (599 ln, all pages — the FINAL2 plan).
- `/tmp/handoff-bd221-C8/PACK-REVIEW-C8.md` (291 ln — the SHOULD finding on MERGE-STRATEGY class 7).
- `/tmp/handoff-bd221-C11/PACK-REVIEW-C11.md` (345 ln — M-1 manifest BLOCKER, POQ-C11-1, F-2/F-3, S-1).
- `/tmp/handoff-bd221-C10/PACK-REVIEW-C10.md` (head — CLEAN verdict + manifest-3-SHAs confirmation).
- `/tmp/handoff-bd221-outofscope/OUT-OF-SCOPE-FINDINGS.md` (34 ln — the tracked out-of-scope items + manifest co-ownership note).
- `CLAUDE.md` `## Pack memory` (full, via system-reminder + project-instructions context).

**Live tree inspected (read-only, this pass):** `git log`/`git worktree list`/`git status`/`git diff --name-only`/`git apply --check` (EB-1/EB-8), `scripts/lib/customization-preserve.sh` (EB-2), `scripts/migrate-v10-to-v11.sh` (EB-2), `scripts/init-project.sh` (EB-4), `test-fixtures/build.sh` + `manifest.txt` (EB-5), `scripts/persona-contracts/contract-migration.sh` + `scripts/tests/test-migrate-v10-to-v11.sh` + `scripts/lib/three-way.sh` (EB-6), `backlog/BD-201.md` + `BD-221.md` (EB-7), `python3 scripts/validate-pack.py` (EB-3).

**Runtime regime:** pwd `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`; HEAD `c4beb8d`; branch `v11-dev` (MAIN checkout, NOT a worktree — §0.1). All writes confined to `/tmp/handoff-bd221-cx1-replan/`.

*End of PLAN-BD-221-CX1-REPLAN.md — read-only pack-planner pass, MAIN checkout HEAD `c4beb8d`, 2026-06-17. CX1 is the first remaining commit (unwritten); validate-pack is already GREEN so the cluster is green-stays-green, not march-to-green-point; NEW governs agent-migration behavior, FINAL2 governs the surface rename + cluster mechanics. Ready for the user planner-to-coder review gate.*
