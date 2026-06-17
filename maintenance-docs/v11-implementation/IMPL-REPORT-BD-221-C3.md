# IMPL-REPORT — BD-221 C3 (migrator-subsystem conversion, `pack-only`)

## Runtime regime (verified at startup + finish)
- **Regime:** ISOLATED git worktree (merge-back via `/tmp` patch).
- **pwd:** `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a1fb1306a7195401d`
- **HEAD (start = finish, agent never committed):** `d92e05494883e3d529e552672db7f23d1e2f4d8c`
- **branch:** `worktree-agent-a1fb1306a7195401d` (off `v11-dev`; post-C2 tip C0+C1+C2 landed)
- **Patch emitted:** `/tmp/handoff-bd221-C3/changes.patch` (1008 lines, 15 files, non-empty, valid `diff --git` headers). All changes are MODIFICATIONS (no new files) → `git diff HEAD` is a complete patch; ran `git add -A -N` defensively before the diff.
- **Git state changes by agent:** NONE (read-only `git diff` + `add -N` only; no stage/commit/apply).

## PREFLIGHT line
```
PREFLIGHT: 15/15 C3 edits complete; validate-pack delta NEW=∅ CLEARED=∅ (52 unchanged), Check 25 green (3/3 — MUST-1 fold worked); C3 lockstep tests PASS (detect 106/0, restore 36/0, migrator-core 19/0, migrator-manifest 12/0, capability-translation 12/0, customization-preserve 223/0, add-capability 10/0; migrate-v10-to-v11 + decompose/dry-run/gates rc=31-failures are Gate-2 validate-pack-red build-blocked→C4 (proven pre-existing); migrator-skills build-blocked→C6 fixture); move-not-delete assert PASS (Group 6 6/6); manifest deferred-to-C6; about to emit patch + IMPL-REPORT
```

## validate-pack delta (fail-LINE level `comm` vs the clean C3 BASE = 52)
- **BASE** (pre-edit, this clean worktree): `FAILED — 52 issue(s)`; Check 25 GREEN (`4/4` fixture rows).
- **AFTER** (post-edit): `FAILED — 52 issue(s)`; Check 25 GREEN (`3/3` fixture rows — MUST-1 fold).
- **NEW = AFTER \ BASE (`comm -13`): EMPTY** — zero new fail-lines introduced.
- **CLEARED = BASE \ AFTER (`comm -23`): EMPTY** — zero fail-lines cleared.
- **Check 25 STAYS GREEN through C3** — the `gemini-env` strategy removal (customization-preserve.sh) AND its Check-25 driver fixture-row removal (validate-pack.py) landed in lockstep in THIS commit, so no orphan red. The fixture count dropped 4/4 → 3/3 (decision b: no shipped env/permissions file → no Antigravity-equivalent customization scenario to replace it; the `gemini-env` fixture was dropped, not replaced).
- **Check 26** (migrator-framework inventory) GREEN — all four migrator libs pass `bash -n`; `migrator_target_surface_for_version` + all 6 public-API fns + 9 exit-code constants present.
- **Matches the plan's C3 expected-red EXACTLY:** "NONE NEW; clears NONE; Check 25 stays green; net after C3 = 52 (unchanged)."

## C3 lockstep test results
**Runnable at this HEAD (all PASS):**
| Test | Result |
|---|---|
| `scripts/test-detect.sh` | 106/0 PASS |
| `scripts/test-restore-from-backup.sh` | 36/0 PASS |
| `scripts/test-migrator-core.sh` | 19/0 PASS |
| `scripts/test-migrator-manifest.sh` | 12/0 PASS (no `.gemini` refs — unchanged) |
| `scripts/test-migrator-capability-translation.sh` | 12/0 PASS (no `.gemini` refs — unchanged) |
| `scripts/tests/test-customization-preserve.sh` | 223/0 PASS |
| `scripts/tests/fixture-dependent/test-add-capability.sh` | 10/0 PASS |

**`scripts/tests/test-migrate-v10-to-v11.sh`: 43 PASS / 6 FAIL.**
- The 6 FAILs are ALL `rc=31` (`EXIT_GATE_FAILED`) from the migrator's **Gate 2 (post-Phase-A verify)**, which runs `validate-pack.py` against the PACK source. validate-pack is intermediate-RED (52, by cluster design) → Gate 2 fails → rc=31. **Build-blocked → C4** (when validate-pack goes green, Gate 2 PASSes).
- **PROOF these are pre-existing, NOT C3-introduced:** ran a full migration using the HEAD (pre-C3) `migrate-v10-to-v11.sh` (`git show HEAD:...` to a temp file) → ALSO non-zero (Gate-2 validate-pack-red). The lockstep assertion I converted (`2.4 .gemini pack-help` → `.agents/skills/pack-help/SKILL.md`) now PASSES (it was the ONE conversion-caused failure; fixed).
- **Group 6 (the SHOULD-1 move-not-delete deliverable) — ALL 6 PASS** (6.1–6.6).

**`-decompose` (42/3), `-dry-run` (57/4), `-gates` (80/7):** ALL 14 failures are the SAME `rc=31` Gate-2 validate-pack-red build-block ("Gate 2 PASS expected", "[OK] validate-pack expected but absent", "rc=0 expected got 31"). **Build-blocked → C4.** No conversion-logic failures among them.

**`scripts/tests/fixture-dependent/test-migrator-skills.sh`: build-blocked → C6** (exit 3 = fixture precondition; requires built `test-fixtures/v10-realistic-ot/`, which the C6 `build.sh` produces; fixtures unbuilt at this HEAD). NOT a test failure.

## move-not-delete assertion result (SHOULD-1 / OQ-2 deliverable)
**PASS.** Added Group 6 to `test-migrate-v10-to-v11.sh` exercising `_v10_to_v11_retire_gemini` directly (sourcing the migrator under a new source-guard, so it runs independent of the build-blocked Gate-2 path). A client-customized departing `.gemini/` (x- custom agent + project-edited `.env` + legacy `.toml` command) is:
- 6.1 `gemini-retired-docs/` holding dir created — PASS
- 6.2 customized x- agent preserved in holding dir — PASS
- 6.3 project-edited `.env` preserved in holding dir — PASS
- 6.4 retired `.env` content faithful (never-delete guarantee) — PASS
- 6.5 original `.gemini/` relocated (moved, not copied) — PASS
- 6.6 idempotent no-op when no `.gemini/` present (rc=0) — PASS

## Files changed inventory (all `pack-only`: `scripts/` + `scripts/lib/` + `scripts/tests/`)
| Path | Type | Change |
|---|---|---|
| `scripts/lib/detect.sh` | modified | CONVERT scan loops (drop `.gemini/agents`, `.gemini/skills`→`.agents/skills` in `detect_x_files` + `detect_improperly_added_files`); ADD `.agents/` marker to `detect_ai_config` (KEEP legacy `.gemini/` carve-out ii); ADD new `detect_antigravity_skills_layout` (OQ-E existing-install classify: loose-wins tie-break; bundled ONLY for the pack's own `optiquity-agents`; foreign plugin→none/loose). KEEP carve-out ii L154 marker + L922 legacy `pack-help.toml`; KEEP `GEMINI.md` FILE refs. |
| `scripts/migrate-v10-to-v11.sh` | modified | CONVERT manifest WRITE-NEW rows (drop `.gemini/.env.example gemini-env`; `.gemini/settings.json`→`.agents/mcp_config.json.example`→`.agents/mcp_config.json claude-mcp-example`); drop `.gemini/agents` directory-sweep; CONVERT pack-help install → pool-distributed loose to `.claude/.codex/.agents`; net-new-skill loop `.gemini`→`.agents`; ADD `_v10_to_v11_retire_gemini` (gemini-retired-docs move-not-delete + EITHER-Gemini-OR-Antigravity idempotency + BD-ref-free user note, no `agy plugin import`); ADD source-guard so the helper is unit-testable. KEEP `GEMINI.md` FILE + the legacy-READ retire logic (carve-out ii). |
| `scripts/lib/migrator-core.sh` | modified | CONVERT the **v11** `migrator_target_surface_for_version` case (`.gemini/agents`→`.agents-plugin/optiquity-agents/agents`; `.gemini/commands/pack-help.toml`→`.agents/skills/pack-help/SKILL.md`). KEEP the **v10** case Gemini-shaped (carve-out i — v10 IS the departing shape). KEEP `GEMINI.md` FILE rows (531/550). |
| `scripts/lib/customization-preserve.sh` | modified | REMOVE the `gemini-env` strategy (doc comment, classify case, `_cp_strategy_gemini_env` fn, dispatch case). KEEP the legacy-READ `.gemini/agents/x-*` + `.gemini/agents/*.md` classify legs (carve-out ii). KEEP `GEMINI.md` FILE classify. |
| `scripts/validate-pack.py` | modified | **MUST-1 fold ONLY:** remove the Check-25 `gemini-env` Fixture 2 (driver + expected-row), drop row count 4→3, update docstring/comment/OK message. NO other validate-pack edit (all other checks/constants = C4). |
| `scripts/add-capability.sh` | modified | CONVERT the forward-contract banner pack-controlled-dir list `.{claude,codex,gemini}/agents/` → `.{claude,codex}/agents/`, `.{claude,codex,gemini}/skills/` → `.{claude,codex,agents}/skills/` (box alignment preserved). (No `.gemini/.env touch` exists at this HEAD — design grounding was stale; measure-then-bound: only the L11 banner was present.) |
| `scripts/test-detect.sh` | modified | LOCKSTEP: `detect_ai_config` all-six fixture `.gemini`→`.agents` + assertion; ADD a legacy-`.gemini` detection test (carve-out ii); ADD a `detect_antigravity_skills_layout` test block (none/loose/bundled-own/foreign/both). |
| `scripts/test-migrator-core.sh` | modified | LOCKSTEP: v11-surface assertion `.gemini/agents`→`.agents-plugin/optiquity-agents/agents`, `.gemini/commands/pack-help.toml`→`.agents/skills/pack-help/SKILL.md`, asserts no `.gemini/`. KEEP the v10-surface assertion Gemini-shaped (carve-out i). |
| `scripts/test-restore-from-backup.sh` | modified | LOCKSTEP: backup fixture `.gemini/agents`→`.agents-plugin/optiquity-agents/agents`. KEEP `GEMINI.md` restore asserts. |
| `scripts/tests/test-customization-preserve.sh` | modified | LOCKSTEP: remove `gemini-env` classify assert (1.8); replace inline Group-5 `gemini-env` scenario with a legacy-`.gemini` classify group (carve-out ii) + a `.gemini/.env`→`generic` assert; fix the strategy-coverage comment (drop `gemini-env`). |
| `scripts/tests/test-migrate-v10-to-v11.sh` | modified | LOCKSTEP: pack-help install assert `.gemini/commands/pack-help.toml`→`.agents/skills/pack-help/SKILL.md`; ADD Group 6 move-not-delete deliverable (sources migrator under the source-guard). KEEP the Group-2b departing-`.gemini/.env` backup-capture asserts (carve-out i). |
| `scripts/tests/fixtures/customization-preserve/v10-with-customization/manifest.tsv` | modified | `.gemini/.env` class `gemini-env`→`generic` (strategy retired). |
| `scripts/tests/fixtures/customization-preserve/v10-with-customization/assertions.tsv` | modified | `.gemini/.env` dest→sidecar for the project value (generic text preserves ours in sidecar, dest=theirs). |
| `scripts/tests/fixtures/customization-preserve/language-heterogeneous/manifest.tsv` | modified | `.gemini/.env` class `gemini-env`→`generic`. |
| `scripts/tests/fixtures/customization-preserve/language-heterogeneous/assertions.tsv` | modified | `.gemini/.env` dest→sidecar adjustments for generic text strategy. |

`test-fixtures/manifest.txt`: **UNCHANGED** (not regenerated — deferred to C6 per the prompt; `git diff --stat` shows no manifest change).

## Plan deviations + discrepancies noted (design internal-contradiction reconciliations)
1. **`migrator-core.sh` v10 vs v11 surface (design line-list vs carve-out i).** Design §5.5 line-list says "CONVERT 534/553/560". L534 is the **v10** case (`.gemini/agents`); L553/560 the **v11** case. The plan §C3 qualifies them as "WRITE-NEW manifest rows" — L534 is NOT WRITE-NEW (it declares the *departing v10 customization surface*, consumed by `dry-run.sh` with `FROM_VERSION=v10`; converting it would make the migrator read the wrong surface for a v10 project). Per carve-out (i) ("v10 source fixtures stay Gemini-shaped (migration inputs)") + the plan's "WRITE-NEW" qualifier, I **KEPT L534 (v10) Gemini-shaped and CONVERTED only the v11 case**. `test-migrator-core.sh` v10 assertion still asserts `.gemini/agents` present (unchanged); v11 assertion converted. Check 26 only validates the function's *presence* (not content), so neither choice drives a validate fail-line — disposition governed by carve-out + grep-zero (C12).

2. **Fixture `.tsv` `.gemini/.env` rows (design §5.13 carve-out i vs gemini-env removal).** Design §5.13 lists "the 8 fixture `*.tsv` `.gemini` rows" as carve-out (i) KEEP, but those exact 8 rows assert the now-removed `gemini-env` CLASS+strategy — keeping them verbatim breaks the test. Reconciliation: **KEPT the v10 `.gemini/.env` source files (carve-out i — real v10 migration inputs)** but **UPDATED the manifest expected-class `gemini-env`→`generic` and the assertions to the generic-text behavior** (dest=theirs, ours preserved in sidecar; disposition `customization-detected-needs-reconciliation` unchanged). Empirically verified the generic strategy's output before writing the new assertions. This is the minimal change that honors BOTH carve-out (i) and the MUST-1/decision-b `gemini-env` removal.

3. **`add-capability.sh` `.gemini/.env touch` (design §5.4 / prompt grounding stale).** Design §5.4 / prompt said "drop the `.gemini/.env` touch". At this HEAD `add-capability.sh` has NO `.gemini/.env` touch — only the L11 forward-contract banner. Per measure-then-bound (grep is the authority on count), I converted only what exists (the L11 banner). `test-add-capability.sh` has no `.gemini` assertions; passes 10/0.

4. **`migrate-v10-to-v11.sh` `.mcp.json.example` manifest row (L94) out of C3 scope.** The manifest's `project-template/.mcp.json.example` transform row references a source deleted in an earlier commit; it is NOT a `.gemini` line and is NOT in the plan's C3 convert-list, so I left it unchanged (out of C3 scope). The transform is a no-op when the source/target is absent; surfaced here for visibility (a likely C4/later cleanup item — not a C3 deliverable).

No other deviations. No architecture changes. No POQs newly opened.

## Boundary discipline check (P-missed-7)
All 15 edited files are pack-side (`scripts/` tree). NO project-side (`project-template/`, `supporting-docs/`) file was touched — C3 is single-scope `pack-only`. The one client-facing surface produced by my code is the `_v10_to_v11_retire_gemini` user-facing note (migrator stdout that reaches the client): it is **BD-ref-free** (no `BD-NNN`), names NO pack-only file/agent/role, carries NO `agy plugin import gemini` recommendation, and points only to the public `https://antigravity.google/docs`. No project-side SSOT augmentation was needed (the note is implementing the design's decision-8 prose verbatim-intent). No pack-only reference was added to any client-facing surface → no boundary-discipline STOP.

## Definition-of-Done checklist
| Item | Status |
|---|---|
| `detect.sh` Antigravity tree-shape + existing-install classify (OQ-3: own-bundle-only, foreign→loose, both→loose) | PASS |
| `detect.sh` KEEP legacy-READ `.gemini` carve-out (ii) | PASS (L154 marker, L922 pack-help.toml) |
| Migrator stack WRITE-NEW `.gemini`→`.agents`; KEEP legacy-READ | PASS |
| `gemini-retired-docs/` holding dir (move-not-delete, idempotent EITHER/OR, BD-ref-free note) | PASS |
| MUST-1 fold: remove `gemini-env` strategy + Check-25 driver-row → Check 25 stays green | PASS (3/3) |
| `add-capability.sh` banner converted (`.gemini/.env touch` absent — measure-then-bound) | PASS |
| SHOULD-1 move-not-delete test deliverable + customized-`.gemini` fixture exercise | PASS (Group 6 6/6) |
| LOCKSTEP: every converted surface's test updated in THIS commit | PASS |
| validate-pack delta = expected-red (NEW=∅, CLEARED=∅, Check 25 green) | PASS |
| Runnable C3 lockstep tests green | PASS |
| Build-blocked tests mapped (migrate full-migration→C4; migrator-skills fixture→C6) | PASS (proven pre-existing / fixture-precondition) |
| Manifest NOT regenerated (deferred to C6) | PASS (unchanged) |
| Single-scope `pack-only` (no project-template/supporting-docs/pack-ops/maintenance-docs) | PASS |
| No git state change by agent | PASS (HEAD d92e0549 unchanged) |
| Patch emitted non-empty to `/tmp/handoff-bd221-C3/changes.patch` | PASS (1008 lines, 15 files) |

## Rules-Applied Verification Block
| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| `agents-never-commit` | Ran only `git status`, `git rev-parse`, `git show <ref>:<path>`, `git diff HEAD`, `git add -A -N`. HEAD unchanged: start=finish=`d92e05494883e3d529e552672db7f23d1e2f4d8c`. No commit/push/stage/apply. | COMPLIANT |
| `preflight-stop-means-stop` | Emitted the single PREFLIGHT line ONLY after all 15 edits + verification PASS; validate-pack delta empty + Check 25 green + lockstep tests green/build-blocked-mapped. No partial IMPL-REPORT. No parent stop signal received. | COMPLIANT |
| `worktree-isolation-mergeback` | Verified regime at startup (`pwd`=isolated worktree, HEAD=d92e0549). Edits made in-worktree; emitted `git diff HEAD > /tmp/handoff-bd221-C3/changes.patch` (non-empty, valid headers) + this report to `/tmp/handoff-bd221-C3/`. No commit; orchestrator applies. All-modifications patch (no new files) → complete diff. | COMPLIANT |
| verification = fail-LINE `comm` vs clean BASE (52); Check 25 stays green | BASE=52 (clean worktree, no empty/.gemini residue except carve-out i fixtures); AFTER=52; `comm -13`=∅, `comm -23`=∅; Check 25 `OK: 3/3 fixture rows`. | COMPLIANT |
| `regenerate-manifest-v11-surface` (DEFERRED to C6) | `git diff --stat` shows NO `test-fixtures/manifest.txt` change; did NOT run `build.sh`. Per prompt: manifest deferred to C6. | COMPLIANT (deferred per instruction) |
| `cross-cli-reference-normalization` | Conversions are audience-correct, not byte-identical: skills→`.agents/skills/` (Antigravity loose), agents→`.agents-plugin/optiquity-agents/agents` (bundle), commands DROPPED (Antigravity has no `.toml`), MCP→`.agents/mcp_config.json`. Matched against post-C2 init-project install shape (`for tool in claude codex agents`, `.agents-plugin/optiquity-agents`). | COMPLIANT |
| `fail-loud/delete-old-source` | Removed `gemini-env` strategy entirely (no mirror); dropped WRITE-NEW `.gemini` install refs entirely. KEPT only legacy-READ carve-out (ii) + `GEMINI.md` FILE refs. No dead-token mirror retained. | COMPLIANT |
| `pack-vs-project separation` + P-missed-7 | All edits pack-side (`scripts/` tree); the gemini-retired-docs note that ships to clients is BD-ref-free, names no pack-only file/role, points to public docs. See Boundary discipline check above. | COMPLIANT |
| `enumerate-encoding-surfaces` | Every converted surface's lockstep test updated in THIS commit: detect.sh↔test-detect.sh; migrator-core↔test-migrator-core; migrate↔test-migrate; customization-preserve↔test-customization-preserve + the 4 fixture `.tsv`; restore↔test-restore; validate-pack Check 25 (self-validated, no separate per-check test exists). | COMPLIANT |
| `scope-deliverables-to-the-ask` | Implemented ONLY C3 surfaces. Did NOT touch C4 validate-pack checks (except the single MUST-1 Check-25 fixture-row fold), build.sh (C6), pack-ops/supporting-docs (C8/C11), the manifest. | COMPLIANT |
| no-historical-narration | Scanned diff: `git diff | grep -iE 'replac.*gemini|formerly|previously|superseded|has been replaced'` → EMPTY after reframing the retire-gemini docstring + user note to operational phrasing ("v11 uses Antigravity. Your .gemini/ tree was moved …"). | COMPLIANT |
| `agent-output-requires-rules-applied-verification-block` | This block. | COMPLIANT |
| `agents-read-rule-docs-in-full` | Read directly+in-full: CLAUDE.md `## Pack memory` (worktree copy, L140-603); the 7 named memory files (worktree feedback_worktree_isolation_mergeback_ops L1-23; feedback_verify_full_ci_suite L1-58; feedback_fail_loud_delete_old_source L1-64; feedback_pack_project_separation_of_concerns L1-33; feedback_scope_deliverables_to_the_ask L1-35; feedback_agent_output_rules_applied_block L1-15; feedback_agents_read_rule_docs_in_full L1-134); plan FINAL-2 (§0–§5 C3 + §5 table); design v3 (§0,§1,§2.1,§5.0–5.13,§6). | COMPLIANT |

## Patch + report artifacts
- Patch: `/tmp/handoff-bd221-C3/changes.patch`
- Report: `/tmp/handoff-bd221-C3/IMPL-REPORT.md` (this file)
