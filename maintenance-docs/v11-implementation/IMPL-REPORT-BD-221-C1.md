# IMPL-REPORT — BD-221 C1 — `.agents/mcp_config.json` install-staging + client gitignore

## Runtime regime (verified at startup)
- **Regime:** ISOLATED git worktree (merge-back via /tmp handoff patch).
- **pwd:** `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a50b7af9080a19dd6`
- **HEAD at start + end (unchanged — agent never commits):** `114faf9f2e132edaac11639bec134797f1148378`
  (= `docs: v11 — BD-221 C0 audit reports (IMPL + review) (pack-only)` — the post-C0 tip)
- **Worktree branch:** `worktree-agent-a50b7af9080a19dd6`
- **Base correctness:** worktree based at parent's CURRENT local HEAD (post-C0); BASE validate-pack = 70 FAIL-lines (matches the prompt's stated ≈70 C1 base). Worktree clean at start (`git status --short` empty). No `.gemini/` product dirs on disk (the 8 found by `find` are legitimate `scripts/tests/fixtures/customization-preserve/**` test fixtures, NOT pack-product surfaces).

## Scope
- **Commit:** C1 (`project-only`) — confirmed: every touched path is under `project-template/` (`git diff HEAD --name-only | grep -vE "^project-template/"` returned nothing).
- Implemented EXACTLY the plan's C1 file set (FINAL2 §3 C1, lines 112–119); the design's OQ-D resolution (DESIGN §5.6) confirms the `.example` pattern.

## Files changed (inventory)
| Path | Change type | Notes |
|---|---|---|
| `project-template/.agents/mcp_config.json` → `project-template/.agents/mcp_config.json.example` | RENAME (100% similarity, byte-faithful) | The committed example; NO secrets. KEEPS the `~/.gemini/config/mcp_config.json` global hedge line behind `<!-- RE-VERIFY at impl ... -->`. |
| `project-template/.gitignore` | MODIFIED (+6 lines) | Added "Antigravity MCP config" section: ignore live `.agents/mcp_config.json`; `!.agents/mcp_config.json.example` keeps the template tracked. |
| `test-fixtures/manifest.txt` | UNCHANGED — DEFERRED to C2 | See "Manifest disposition" below. |

### Rename faithfulness evidence
`diff <(git show HEAD:project-template/.agents/mcp_config.json) project-template/.agents/mcp_config.json.example` → **identical** (no output). The patch records `similarity index 100%` / pure `rename from … rename to …` (zero content delta). The existing file was already example-shaped (placeholder `BASE_DIR: "/absolute/path/to/your-project"`, no real secrets) and its `_readme` already documents the `.example`→live copy-and-gitignore flow — so a byte-faithful rename is the correct, complete RE-AUTHOR.

### `.gitignore` diff (the only content addition)
```
+# ─── Antigravity MCP config ────────────────────────────────────────────────
+# The live workspace MCP config holds your filled-in paths/values; never commit
+# it. The committed template is .agents/mcp_config.json.example (no secrets).
+.agents/mcp_config.json
+!.agents/mcp_config.json.example
+
```
Mirrors the file's existing `.env` / `!.env.example` committed-template idiom (lines 13–16). Scoped tight to the plan's named deliverable — an earlier draft that also added `.agents/rag-index/` + `.agents/rag-cache/` ignores was trimmed back to the exact C1 spec (`scope-deliverables-to-the-ask`).

## No-secrets confirmation
The `.example` contains only documentation strings + placeholder values (`BASE_DIR: "/absolute/path/to/your-project"`, `DB_PATH`/`CACHE_DIR` relative paths). No tokens, keys, absolute machine paths, or credentials. The `~/.gemini/config/mcp_config.json` line is an Antigravity-own global-config path documented as a hedge with a `RE-VERIFY at impl` marker (KEEP per plan + design §5.6; it is a tool path, not a secret).

## Verification — fail-LINE `comm` set-difference (the criterion)
- BASE captured BEFORE edits: `python3 scripts/validate-pack.py` → exit 1, **70 unique `FAIL:` lines** (`/tmp/handoff-bd221-C1-base-faillines.txt`); summary `FAILED — 70 issue(s) found`.
- AFTER captured after edits: `python3 scripts/validate-pack.py` → exit 1, **70 unique `FAIL:` lines** (`/tmp/handoff-bd221-C1-after-faillines.txt`); summary `FAILED — 70 issue(s) found`.

### `comm` actual output
- **NEW = AFTER \ BASE** (`comm -13 base after`): **EMPTY** (no lines).
- **CLEARED = BASE \ AFTER** (`comm -23 base after`): **EMPTY** (no lines).
- **Net:** 70 → 70 (unchanged).

### vs the plan's C1 expected-red (FINAL2 line 118)
Plan: *"C1 introduces **NO new validate fail-line** … C1 is internally clean (net 70 unchanged)."* Expected NEW red → restore: **NONE.**
- **MATCH — EXACT.** NEW is empty (plan says none); CLEARED is empty (plan clears none at C1); net 70 unchanged (plan says net 70 unchanged). **Zero UNMAPPED reds.** No deviation.

### Directly-relevant check spot-confirmation (no regression on the surfaces I touched)
- **Check 20** (Pack `.gitignore` `!.env.example` exception, the check that reads the file I edited): `OK: project-template/.gitignore — `.env.*` + `!.env.example` exception present`. My added section did not disturb it.
- **Check 39/41/20/2** (install-map / toml — the checks the design names for the mcp_config rows): unaffected — EB-L confirmed init-project stages NO mcp_config today, so there are no install-map rows referencing the old path to break (grep `agents/mcp_config.json` in `scripts/` returned ZERO matches). The `.example`→live install-map row is C2's work (Check 39/41 consume it there).

## Manifest disposition — DEFERRED to C2 (build blocked)
`test-fixtures/manifest.txt` is left **UNCHANGED**. `regenerate-manifest-v11-surface` requires a regen on `project-template/` commits, BUT `bash test-fixtures/build.sh --all --clean` is BLOCKED at this HEAD: `scripts/init-project.sh` L422/L428 still `mkdir`/iterate `.gemini/agents`, and `project-template/.gemini/agents` does NOT exist (verified: `ls project-template/.gemini/agents` → No such file or directory). C2 converts init-project.sh's skeleton to `.agents`. Per the prompt's user-authorized deferral I did NOT attempt a regen and did NOT hand-edit/fabricate the manifest. Disposition: **manifest deferred to C2 (build blocked).** Expected, not a defect.

## Plan deviations
- **One documented discrepancy (NOT a deviation in edits):** the plan's C1 file set line 116 lists `test-fixtures/manifest.txt regen` as part of C1; the spawn prompt (runtime-verified) defers the manifest regen to C2 because `build.sh` is blocked at this HEAD. I followed the prompt (deferral) and confirmed the block empirically (init-project.sh L422/428 vs absent `project-template/.gemini/agents`). This is the prompt's explicit instruction (§7) and is reconciled by C2 doing the regen once init-project is converted. No edit deviation otherwise — the two content edits match the plan + design exactly.

## New POQs introduced
None.

## Patch emission (merge-back handoff)
- **Patch:** `/tmp/handoff-bd221-C1/changes.patch` (1193 bytes, non-empty).
- Emitted with read-only git only: `git add -A -N` (intent-to-add so the new `.example` appears) → `git diff HEAD > /tmp/handoff-bd221-C1/changes.patch`. NO stage/commit/push/apply.
- **Applyability:** `git apply --check` in THIS worktree fails with the documented index-refresh/stat-cache artifact (the `add -N` already mutated the worktree index — `feedback-worktree-isolation-mergeback-ops` GOTCHA). Verified the patch applies cleanly against a PRISTINE HEAD-state tree: extracted `git archive HEAD` of the two paths to `/tmp/c1-applytest`, ran `git apply --check changes.patch` there → **SUCCEEDS**. The orchestrator applies to the clean main tree at HEAD `114faf9` (run `git update-index -q --refresh` first per the memory gotcha if the main tree shows stat-cache noise).
- **Patch contents:** (1) pure rename `mcp_config.json` → `mcp_config.json.example` (similarity 100%); (2) `project-template/.gitignore` +6 lines.

## Definition-of-Done checklist
| Item | Status |
|---|---|
| `.agents/mcp_config.json.example` added (committed example, no secrets, global hedge kept) | PASS |
| Original `.agents/mcp_config.json` removed (rename complete, byte-faithful) | PASS |
| `project-template/.gitignore` ignores live `.agents/mcp_config.json`, NOT the `.example` | PASS |
| No install-map row added here (that is C2) | PASS (none added; none existed to break) |
| Scope = `project-only` (all paths under `project-template/`) | PASS |
| validate-pack `comm` delta matches plan C1 expected-red (NEW empty, CLEARED empty, net 70) | PASS |
| Zero UNMAPPED new reds | PASS |
| Manifest deferred to C2 (build blocked) — unchanged, not fabricated | PASS (per prompt §7) |
| Patch emitted to /tmp handoff dir, non-empty, applies to pristine HEAD | PASS |
| No git state-changing verb run | PASS |

## PREFLIGHT line
`PREFLIGHT: 2/2 C1 edits complete; validate-pack delta = NEW empty + CLEARED empty (net 70 unchanged, matches plan C1 "NO new validate fail-line"); manifest deferred-to-C2 (build blocked: init-project.sh L422/428 still expect absent project-template/.gemini/agents); about to emit patch + IMPL-REPORT`

---

## Rules-Applied Verification Block
| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| `agents-never-commit` | Only read-only git verbs used: `git rev-parse`, `git status`, `git log`, `git show`, `git diff`, `git archive`, `git add -A -N` (intent-to-add, non-staging), `git apply --check` (check-only, in a /tmp throwaway). No commit/stage/push/apply-to-tree/reset/checkout/restore run. HEAD unchanged at `114faf9…` start→end. | COMPLIANT |
| `preflight-stop-means-stop` | All edits + verification PASS before the single PREFLIGHT line was emitted; `comm` delta exactly matches plan (no UNMAPPED red), so a full IMPL-REPORT (not a STOP-report) is correct. No stop/halt signal received. | COMPLIANT |
| `worktree-isolation-mergeback` | Verified ISOLATED regime at runtime (pwd under `.claude/worktrees/agent-…`, branch `worktree-agent-…`, HEAD = post-C0 tip). Patch emitted to named `/tmp/handoff-bd221-C1/changes.patch`; orchestrator applies. Applied the memory's index-refresh GOTCHA reasoning to explain the in-worktree `apply --check` artifact + verified against pristine HEAD instead. | COMPLIANT |
| verification = fail-LINE `comm` set-difference vs clean BASE | BASE 70 lines, AFTER 70 lines; `comm -13` (NEW) empty, `comm -23` (CLEARED) empty. Only UNMAPPED new lines would stop; there are zero new lines. | COMPLIANT |
| `regenerate-manifest-v11-surface` | C1 touches `project-template/` (v11-surface) so the rule applies, BUT `build.sh --all` is BLOCKED at this HEAD (init-project.sh L422/428 reference absent `project-template/.gemini/agents`; `ls` confirms absent). Per prompt §7 user-authorized deferral, manifest left UNCHANGED, regen deferred to C2 (which converts init-project). Empirically grounded, not assumed. | N/A: deferred-to-C2 per user-authorized build-blocked deferral (rule satisfied by C2) |
| pack-vs-project separation + P-missed-7 | C1 edits are project-side client deliverables only (`project-template/.agents/`, `project-template/.gitignore`). No pack-self leak: grepped the `.example` + `.gitignore` for `BD-`, `pack-ops`, `maintenance-docs`, `Pack Chat`, `pack-*` agent names → none. The `~/.gemini/config/mcp_config.json` is an Antigravity tool global path (KEEP per design §5.6), not a pack-self ref. `.example` carries NO secrets (placeholder paths only). | COMPLIANT |
| `scope-deliverables-to-the-ask` | Implemented ONLY C1's 2 content edits. Trimmed the initial `.gitignore` draft (which over-added `.agents/rag-index/` + `.agents/rag-cache/`) back to the exact plan-named deliverable (live `mcp_config.json` ignore + `.example` negation). Nothing outside C1 touched. | COMPLIANT |
| no-historical-narration | Report states current state + verification; the `.example` + `.gitignore` carry no narration. The `_global_alternative` `RE-VERIFY at impl` marker is a forward-looking hedge (per design), not historical narration. | COMPLIANT |
| `agent-output-requires-rules-applied-verification-block` | This block, with per-rule quoted evidence + terminal conclusion (no AMBIGUOUS). | COMPLIANT |
| `agents-read-rule-docs-in-full` | Read directly + in full via the Read tool: pack-root `CLAUDE.md` (604 lines, incl. entire `## Pack memory`); `feedback_worktree_isolation_mergeback_ops.md` (23 lines, first line `---`, last line ends `…reviewer always runs IN-PLACE (2026-06-15)`); `feedback_manifest_regen_on_v11_surface.md` (16 lines, last line `Related: test-infra self-provisioning (distinct concern).`); `feedback_pack_project_separation_of_concerns.md` (33 lines, last line cross-refs `[[bd-pack-only-operational-rule]]`); `feedback_scope_deliverables_to_the_ask.md` (35 lines, last line `…the user's standing preference for terse, exactly-scoped work.`); `feedback_agent_output_rules_applied_block.md` (15 lines, last line `Related: [[agent-prompt-enumerates-rules]], [[architect-planner-empirical-evidence]].`); `feedback_agents_read_rule_docs_in_full.md` (134 lines, last line ends `…the very standard that catches the dangerous cases.`). Plan C1 section + design §5.6 OQ-D read directly. | COMPLIANT |
