# PACK-REVIEW-C3 — BD-221 cluster commit C3 (migrator subsystem `.gemini`→`.agents`)

**Reviewer:** pack-reviewer (READ-ONLY, in-place, main working tree). No file
written except this report; no stage/commit; no state-changing git verb run.
**Runtime regime (verified):** IN-PLACE. `pwd` =
`/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`; `git rev-parse
HEAD` = `d92e05494883e3d529e552672db7f23d1e2f4d8c` (post-C2); branch `v11-dev`.
**C3 state:** 15 modified files, ALL under `scripts/` (uncommitted). Verified
via `git status --short` + `git diff`.
**Date:** 2026-06-17.

## VERDICT: CLEAN — 1 SHOULD + 1 NIT (no BLOCKER, no MUST)

C3 is a correct, cohesive, lockstep-complete migrator-subsystem conversion. All
seven review-checklist axes pass; the four coder discrepancies are individually
validated; the comm delta is exactly as the plan specifies (net 52, NEW=∅,
CLEARED=∅, Check 25 GREEN); no C3-caused test break. ONE SHOULD finding
(discrepancy (d): a stale, unenumerated `.mcp.json.example` migrator-manifest
row — non-failing but a correctness/cleanliness gap) and ONE NIT.

---

## 1. Conversion completeness (checklist 1) — PASS

All C3 §5 loci converted; KEEP carve-outs correctly retained.

- **`detect.sh`** — current-layout legs converted: `detect_x_files` drops
  `.gemini/agents`/`.gemini/skills`, adds `.agents/skills` (L173-178);
  `detect_improperly_added_files` agent loop → `.claude .codex` only (bundle
  note, L220-224), skills loop → `.agents/skills` (L238). `detect_ai_config`
  adds `.agents/` marker (L151) and KEEPS the legacy `.gemini/` marker behind an
  explicit carve-out comment (L152-154). KEEP-FILE `GEMINI.md` (L154/863 region)
  untouched. KEEP-CARVE-OUT (ii) legacy-READ L922
  (`.gemini/commands/pack-help.toml`) retained. Correct.
- **`migrate-v10-to-v11.sh`** — manifest WRITE-NEW rows L98-99 converted to a
  single `.agents/mcp_config.json.example` row (L99); directory-sweep
  `.gemini/agents` row dropped (L106-115); skill-fan loops `.gemini`→`.agents`
  (L316 pack-help pool fan, L416 net-new-skill loop). KEEP-CARVE-OUT (ii): the
  new `_v10_to_v11_retire_gemini` helper READS/RELOCATES the departing
  `.gemini/` — all `.gemini` refs there are legacy-READ. KEEP trinity rows
  (GEMINI.md). Correct.
- **`migrator-core.sh`** — v11 surface case converted: `.gemini/agents` →
  `.agents-plugin/optiquity-agents/agents`; `.gemini/commands/pack-help.toml` →
  `.agents/skills/pack-help/SKILL.md` (L534/560 region). KEEP-FILE trinity rows.
  The v10 case correctly KEPT Gemini-shaped (discrepancy (a), §5a). Correct.
- **`customization-preserve.sh`** — `gemini-env` strategy fully removed (doc
  L18-19, classify case L161-162, `_cp_strategy_gemini_env()` function ~115
  lines, dispatch case). KEEP-FILE trinity classify (L150). KEEP legacy-READ
  agent classify L165/167 (carve-out ii — see §5b/SHOULD-2). Correct.
- **`add-capability.sh`** — banner converted; no `.gemini/.env` write exists at
  HEAD (discrepancy (c), §5c). `grep '\.gemini' scripts/add-capability.sh` → 0
  hits. Correct.

**WRITE-NEW `.gemini` residue:** none. Every remaining `.gemini` in the C3
source files is one of: legacy-READ carve-out (ii), the v10 departing-surface
case, the `_v10_to_v11_retire_gemini` relocate helper, `GEMINI.md` the FILE, or
an explanatory comment. Verified by per-file grep.

**cross-cli-reference-normalization:** audience-correct (pack-side migrator
prose names `.agents/skills/`, the bundle path, and `antigravity.google/docs`;
no byte-identical cross-trinity copy involved here — C3 touches no trinity
prose). COMPLIANT.

## 2. MUST-1 Check-25 fold (checklist 2) — PASS

The `gemini-env` strategy removal (`customization-preserve.sh`) AND the
Check-25 driver-fixture-row removal (`validate-pack.py`) landed in the SAME
commit (C3). The `validate-pack.py` edit is ONLY the Check-25 fixture block:

- docstring items 3 (gemini-env) deleted, 4→3, 5→4 renumbered (L2211-2215).
- driver fixture 2 (gemini-env) deleted; fixtures 3→2, 4→3 renumbered
  (L2244-2275 region).
- expected `.gemini/.env` row deleted (L2305-2308 region).
- count guard `4`→`3` (L2295-2296); `ok()` banner `4/4`→`3/3` (L2331).

No other check in `validate-pack.py` is touched (the 29-line diff is entirely
inside `check_customization_detection_regression_guard`). Check 25 is GREEN at
the C3-applied tree: `OK: 3/3 fixture rows recorded with expected disposition +
class`. No orphan red. **MUST-1 satisfied** — the strategy's third runtime
consumer moved in lockstep with the strategy, so Check 25 stays green through C3
(it was 4/4 GREEN at base, is 3/3 GREEN after).

## 3. OQ-3 existing-install detection (checklist 3) — PASS

New `detect_antigravity_skills_layout()` in `detect.sh` (L273-313) implements
the frozen OQ-3 spec deterministically:

- Loose `.agents/skills/` present → `loose` (early return; this also IS the
  BOTH-present tie-break → `loose`). Matches design §2.1 + the prompt's frozen
  OQ-3.
- `.agents-plugin/optiquity-agents/skills/` present (and no loose) → `bundled`
  — recognized ONLY for the pack's own `optiquity-agents` bundle.
- Any other (foreign/non-standard) plugin → falls through to `none` (the pack
  distributes loose alongside it). Matches the prompt's "foreign→loose."

Tested in `test-detect.sh` (L246-275): none / loose / bundled-own / foreign→none
/ both→loose — 5 cases, all PASS. `bash scripts/test-detect.sh` → **106 passed,
0 failed.**

## 4. SHOULD-1 move-not-delete (checklist 4) — PASS

`test-migrate-v10-to-v11.sh` Group 6 (L400-471) genuinely exercises the
never-delete guarantee by sourcing the migrator (source-guard) and calling
`_v10_to_v11_retire_gemini` directly:

- 6.1 `gemini-retired-docs/` created; 6.2/6.3 customized x- agent + project-edited
  `.env` preserved in holding dir; 6.4 retired `.env` content faithful
  (never-delete); 6.5 original `.gemini/` relocated (no stray legacy tree);
  6.6 idempotent no-op when no `.gemini/` present.
- Ran the test: **Group 6 = 6/6 PASS.** The helper itself (L457-492) does a
  whole-tree `mv` (with a timestamped sidecar fallback so a prior retirement is
  never overwritten — never delete), gated on `[[ ! -d "$legacy" ]]`
  idempotency. Implementation faithfully matches design §5.5 decision 8.

## 5. THE 4 CODER DISCREPANCIES — all validated

### 5a. (a) migrator-core.sh v10 case KEPT Gemini-shaped — CORRECT
`migrator_target_surface_for_version` v10 branch (L527-536) keeps `.gemini/agents`;
only the v11 branch (L537-561) converts to `.agents-plugin/optiquity-agents/agents`
+ `.agents/skills/pack-help/SKILL.md`. The v10 case is the DEPARTING surface the
migrator consumes for `FROM_VERSION=v10`; converting it would break
migration-from-v10 (the migrator could no longer recognize the departing tree).
Test `test-migrator-core.sh` recast to assert v11 has no `.gemini/` AND has the
bundle/loose paths (L384-406) — **19 passed, 0 failed.** Validated CORRECT.

### 5b. (b) fixture `.tsv` `.gemini/.env` rows: kept v10 source, class→generic — CORRECT
`v10-with-customization/{manifest,assertions}.tsv` +
`language-heterogeneous/{manifest,assertions}.tsv`: the `rel_path` stays
`.gemini/.env` (carve-out i — v10 source fixtures stay Gemini-shaped), but the
expected `class` flips `gemini-env`→`generic` and the assertions re-express the
generic-3-way-text semantics (project values preserved in **sidecar**; dest takes
pack/theirs). This is the exact behavioral consequence of `.gemini/.env` now
falling through `customization_classify` to `generic` →`_cp_strategy_text`. The
disposition `customization-detected-needs-reconciliation` is preserved (both
strategies emit it when both sides edit). `test-customization-preserve.sh` →
**223 passed, 0 failed.** Validated CORRECT.

### 5c. (c) add-capability.sh: no `.gemini/.env` touch at HEAD; only banner converted — CORRECT
`grep -n '\.gemini' scripts/add-capability.sh` → **0 hits** post-edit. The diff
is the single banner-comment line (`.{claude,codex,gemini}/...` →
`.{claude,codex}/agents/, .{claude,codex,agents}/skills/`). The design grounding
naming a `.gemini/.env` touch was stale (no such touch exists at HEAD).
`test-add-capability.sh` (fixture-dependent) → **19 passed, 0 failed.** Validated
CORRECT.

### 5d. (d) migrate-v10-to-v11.sh `.mcp.json.example` manifest row L95 left UNCHANGED — **SHOULD (real gap, non-failing)**

**This IS a gap, but a low-severity one (no runtime failure, no CI red).**

Evidence:
- The row at `scripts/migrate-v10-to-v11.sh:95` is
  `project-template/.mcp.json.example<TAB>.mcp.json.example<TAB>claude-mcp-example<TAB>transform`.
- Its pack SOURCE (`project-template/.mcp.json.example`) **no longer exists** — it
  was DELETED at C2 (`5d47317`, confirmed: `git cat-file -e
  d92e054:project-template/.mcp.json.example` → "does not exist"; replaced by
  `.agents/mcp_config.json.example`, added at C1 `5675c21`). The C3 coder
  CONVERTED the two adjacent `.gemini` rows (L98-99) into the new
  `.agents/mcp_config.json.example` row (L99) but left the stale L95 row.
- **Is it a CONVERT surface the census/plan assigns?** NO. The census §3.4
  migrator table does not list it (it carries no `gemini` token, so the
  gemini-token census naturally missed it). The plan/design assign the
  `.mcp.json.example` removal ONLY to `init-project.sh`'s `_CLIENT_INSTALLED_FILES`
  + cmd_update rows (C2, Check 39/41) and to `SETUP-NEW.md` (C11) — **NOT** to the
  `migrate-v10-to-v11.sh` migrator manifest. It is an **unenumerated orphan
  surface**, stale-by-cascade from C2's delete.
- **Does it fail?** NO. `migrator-manifest.sh:285` (`[[ -f "$theirs" ]] || theirs=""`)
  gracefully nulls a missing pack source — no die, no test asserts it (`grep` of
  all migrate/migrator tests for `mcp.json.example`/`mcp_config` → 0 hits). It
  does NOT cause a migrator failure or a validate-pack/migrator-manifest red.
- **Why still a defect:** when migrating a v10 client that has `.mcp.json.example`,
  this stale `transform` row dispatches `customization_preserve` with an absent
  pack source (`theirs=""`), producing a "project-only-file"/"removed-by-pack"
  disposition for the departing `.mcp.json.example` instead of cleanly retiring it
  toward the v11 `.agents/mcp_config.json` pattern. It is a latent correctness
  defect (stale source pointing at a deleted pack file) and a cleanliness defect
  (a manifest row no migrator surface can satisfy).

**Owning commit:** **C3** is the natural owner. The row lives in
`migrate-v10-to-v11.sh` (a C3 file), C3 is the commit that converts the adjacent
migrator-manifest MCP rows (L98-99 → the new `.agents/mcp_config.json.example`
row), and `migrate-v10-to-v11.sh` is NOT re-touched in any later cluster commit.
**Fix:** delete the stale L95 row (the `.mcp.json.example` source is gone; the v11
MCP example is already represented by the L99 `.agents/mcp_config.json.example`
row). No test change needed (no test pins the row); re-run the migrator unit/full
tests after to confirm no regression. Severity **SHOULD** (not BLOCKER/MUST: it
does not break the build, CI, or the green-point; but it should be cleaned now per
`fail-loud/delete-old-source` — a manifest row whose source the cluster already
deleted should not silently persist).

## 6. comm delta (checklist 6) — PASS

Computed via `git archive d92e054 | tar` into `/tmp` (read-only base
materialization), `validate-pack.py` in each tree, `comm` over sorted `^FAIL:`
sets:

- BASE (d92e054, pre-C3): **52 FAIL**, Check 25 GREEN (4/4).
- AFTER (C3 working tree): **52 FAIL**, Check 25 GREEN (3/3).
- `NEW = AFTER \ BASE` = **∅ (0 lines).**
- `CLEARED = BASE \ AFTER` = **∅ (0 lines).**

Exactly matches the plan's C3 expected delta (net 52 unchanged, NEW=∅,
CLEARED=∅, MUST-1 keeps Check 25 green). No unmapped NEW red. The Check-25
fixture count dropped 4/4→3/3 but the CHECK stays green (no orphan).

## 7. Lockstep completeness (checklist 7) — PASS

Ran every C3-wired test. RUNNABLE (not gate-blocked) all green:

| Test | Result |
|---|---|
| `test-detect.sh` | 106 passed, 0 failed |
| `test-migrator-core.sh` | 19 passed, 0 failed |
| `test-migrator-manifest.sh` | 12 passed, 0 failed |
| `test-restore-from-backup.sh` | 36 passed, 0 failed |
| `test-migrator-capability-translation.sh` | 12 passed, 0 failed |
| `tests/test-customization-preserve.sh` | 223 passed, 0 failed |
| `tests/fixture-dependent/test-migrator-skills.sh` | 19 passed, 0 failed |
| `tests/fixture-dependent/test-add-capability.sh` | 19 passed, 0 failed |
| `tests/test-migrate-v10-to-v11.sh` **Group 6 (SHOULD-1)** | 6 passed, 0 failed |

BUILD-BLOCKED (validate-pack-gate-red → restore at C4) — correctly mapped, NOT
C3-caused. The full-migration paths fail with rc=31 (`EXIT_GATE_FAILED`, the
BD-101 Phase-A validate-pack verification gate, which is red cluster-wide until
C4 the validator green-maker). **Spot-verified the mapping** by materializing the
C2 BASE and running the same tests there:

| Test | BASE (pre-C3) | AFTER (C3) | Direction |
|---|---|---|---|
| `test-migrate-v10-to-v11.sh` | 13P / 30F | 43P / 6F | improved |
| `-dry-run` | 30P / 25F | 57P / 4F | improved |
| `-decompose` | 22P / 19F | 42P / 3F | improved |
| `-gates` | 73P / 14F | 80P / 7F | improved |
| `test-detect.sh` | 99P / 1F | 106P / 0F | improved |
| `test-migrator-core.sh` | 17P / 2F | 19P / 0F | improved |

**Every affected test IMPROVES under C3 (no regression).** The remaining
failures are all rc=31 gate-red (→C4). **No test C3 broke that it left
unfixed.** (enumerate-encoding-surfaces + verify-full-ci-suite satisfied: each
converted surface's lockstep test moved in THIS commit.)

## 8. Boundary / scope (checklist 8) — PASS

- **pack-only:** all 15 changed files are under `scripts/` — zero
  `project-template/` or `supporting-docs/` paths. `pack-only` scope keyword
  will pass Check 36. COMPLIANT.
- **`migrate-v10-to-v11.sh` is NOT client-shipped:** it is NOT in
  `_SANCTIONED_PACK_SIDE_SHIPPED` (`{scripts/lib/detect.sh, scripts/pack-help.sh}`
  only) — it runs FROM the pack against a client tree, never copied into the
  client repo. So its content is pack-internal, not a client deliverable.
- **The user-facing `gemini-retired-docs/` note IS BD-ref-free** (L487-491:
  "v11 uses Antigravity. Your .gemini/ tree was moved to gemini-retired-docs/…"
  — no BD-NNN, keeps the `antigravity.google/docs` pointer). Exactly satisfies
  design §5.5 / plan C3 "emit the BD-ref-free note." COMPLIANT.

---

## FINDINGS (severity-tagged)

### SHOULD-1 — stale `.mcp.json.example` migrator-manifest row (discrepancy d)
- **File:** `scripts/migrate-v10-to-v11.sh:95`
- **Evidence:** row source `project-template/.mcp.json.example` deleted at C2
  (`5d47317`); `git cat-file -e d92e054:project-template/.mcp.json.example` →
  "does not exist." `migrator-manifest.sh:285` nulls the missing source (no
  failure); no test pins it; census/plan do not enumerate it (unassigned orphan).
- **Impact:** non-failing, but a latent migration-correctness defect (a v10
  client's departing `.mcp.json.example` gets a stale disposition instead of
  clean retirement) and a stale row pointing at a cluster-deleted pack file.
- **Fix (owner C3):** delete the L95 row; the v11 MCP example is already covered
  by the L99 `.agents/mcp_config.json.example` row. No test change; re-run
  migrator tests to confirm no regression.

### NIT-1 — `customization-preserve.sh` legacy-classify legs lack an inline carve-out comment
- **File:** `scripts/lib/customization-preserve.sh:165,167`
- **Evidence:** L165 `.gemini/agents/x-*` → `custom-agent`, L167
  `.gemini/agents/*.md` → `pack-agent` were KEPT (census §3.6 lumped these with
  the removed `.env` case as "CONVERT"). The coder correctly treats them as
  legacy-READ carve-out (ii) — the migrator classifies a DEPARTING v10
  `.gemini/agents` tree — and DOCUMENTS this in `test-customization-preserve.sh`
  Group 5 (L287-303, "legacy-READ carve-out ii" comment + 5.1/5.2/5.3 asserts).
  But the classifier function itself has no inline carve-out comment (unlike
  `detect.sh` L152-154 which does).
- **Impact:** cosmetic / future-maintainer clarity only. The behavior + test
  coverage are correct.
- **Fix (optional):** add a one-line `# legacy-READ carve-out (ii): departing
  v10 .gemini/agents classify` comment above L164.

---

## Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| enumerate-encoding-surfaces + verify-full-ci-suite | Ran all 8 runnable C3-wired tests (all green) + Group 6 + spot-verified the gate-blocked tests against the materialized C2 BASE (every test IMPROVES under C3; remaining reds are rc=31 validate-pack-gate → C4, not C3-caused). Each converted surface's lockstep test moved in this commit. | COMPLIANT |
| fail-loud/delete-old-source | WRITE-NEW `.gemini` removed everywhere; only legacy-READ carve-out (ii) + the v10 departing case + `GEMINI.md` FILE + the relocate helper retained (per-file grep). One exception found: the stale `.mcp.json.example:95` row (a manifest row whose source the cluster already deleted) was NOT deleted — surfaced as SHOULD-1 per this exact rule (delete the old source). | COMPLIANT (with SHOULD-1 raised under this rule) |
| cross-cli-reference-normalization | C3 touches no trinity prose; migrator prose uses audience-correct `.agents/skills/`, the bundle path, `antigravity.google/docs`; no byte-identical cross-trinity copy. | COMPLIANT |
| verification = fail-LINE comm vs C2 BASE (52); only UNMAPPED new red is a defect; Check 25 green | `comm` over sorted `^FAIL:` sets (BASE materialized via `git archive d92e054`): NEW=∅, CLEARED=∅, both trees 52; Check 25 GREEN (3/3 after, 4/4 base). No unmapped NEW red. | COMPLIANT |
| pack-vs-project separation + P-missed-7 | All 15 files under `scripts/` (pack-only); `migrate-v10-to-v11.sh` not in `_SANCTIONED_PACK_SIDE_SHIPPED`; client-facing note BD-ref-free (L487-491). | COMPLIANT |
| scope-deliverables-to-the-ask | Report scoped to the 8 checklist axes + 4 discrepancies + the stated rules; no edge-case sprawl. | COMPLIANT |
| agents-never-commit / read-only | Ran only read-only git verbs (`status`, `diff`, `log`, `cat-file`, `archive`, `rev-parse`); no stage/commit/stash/checkout/worktree; single file write = this report. | COMPLIANT |
| agent-output-requires-rules-applied-verification-block | This block. | COMPLIANT |

## Files read in full
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md` — entire `## Pack memory` section (604 lines; first line "# CLAUDE.md — AI Agent Config Pack (Pack Repo)", last "OT itself is read-only for testing…").
- `/Users/david/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_verify_full_ci_suite.md` (58 lines).
- `/Users/david/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_fail_loud_delete_old_source.md` (63 lines).
- `/Users/david/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_pack_project_separation_of_concerns.md` (32 lines).
- `/Users/david/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_scope_deliverables_to_the_ask.md` (35 lines).
- `/Users/david/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_agent_output_rules_applied_block.md` (15 lines).
- `/Users/david/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_agents_read_rule_docs_in_full.md` (134 lines).
- `/tmp/handoff-bd221-planner-final2/PLAN-BD-221-ANTIGRAVITY-COMPLETION-FINAL2.md` (C3 section + §1/§2/§3/§5 cross-reference table read directly; 598 lines total, C3-relevant ranges read in full).
- `/tmp/handoff-bd221-architect-v3/DESIGN-BD-221-ANTIGRAVITY-COMPLETION-v2.md` (§2.1, §5.0–§5.9 loci read directly).
- `/tmp/handoff-bd221-gemini-census/CENSUS-BD-221-GEMINI-BLAST-RADIUS.md` (§3.3/§3.4/§3.6/§4/§5/§6 read directly).
