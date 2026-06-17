# IMPL-REPORT — BD-221 C3 review fixes (SHOULD-1 + NIT-1)

## Regime

- **Worktree (isolated regime):** `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a1fb1306a7195401d`
- **pwd verified:** yes (matches the named C3 worktree)
- **HEAD:** `d92e05494883e3d529e552672db7f23d1e2f4d8c` (== d92e054, as expected)
- **Branch:** `worktree-agent-a1fb1306a7195401d`
- **Base status confirmed:** 15 uncommitted C3 files present at startup (add-capability.sh, customization-preserve.sh, detect.sh, migrator-core.sh, migrate-v10-to-v11.sh, test-detect.sh, test-migrator-core.sh, test-restore-from-backup.sh, 4 fixture .tsv, test-customization-preserve.sh, test-migrate-v10-to-v11.sh, validate-pack.py). Match — proceeded.
- **Main checkout NEVER touched.**

## The two fixes (applied on top of existing C3 changes)

### SHOULD-1 — stale migrator-manifest row removed
- **File:** `scripts/migrate-v10-to-v11.sh`, `migrator_manifest()` heredoc (was ~L95).
- **Action:** DELETED the one stale row:
  `project-template/.mcp.json.example<TAB>.mcp.json.example<TAB>claude-mcp-example<TAB>transform`
  Its pack source was deleted at original C2; the v11 MCP example is already
  covered by the adjacent row at L98:
  `project-template/.agents/mcp_config.json.example<TAB>.agents/mcp_config.json<TAB>claude-mcp-example<TAB>transform`.
- **Scope:** removed ONLY that one row; nothing else changed in the file.

### NIT-1 — legacy-READ carve-out comment added
- **File:** `scripts/lib/customization-preserve.sh`, `_cp_classify` case (the
  `.gemini/agents/x-*` + `.gemini/agents/*.md` legs, was ~L165/L167).
- **Action:** added a 3-line inline comment above the per-CLI-agents legs,
  mirroring the carve-out comment style in `detect.sh` (L152–153):
  ```
  # Per-CLI agents. The `.gemini/agents/` legs are a legacy-READ
  # carve-out (ii): the migrator must classify the departing v10
  # `.gemini` shape so it can relocate it (mirrors detect.sh).
  ```
- **Scope:** comment only — zero behavior change.

## Verification results (run in the C3 worktree)

| Command | Result |
|---|---|
| `python3 scripts/validate-pack.py` | **FAILED — 52 issue(s)** (matches expected 52; fixes don't change validate state) |
| Check 25 (Customization-detection regression guard, BD-089) | **GREEN** — `OK: 3/3 fixture rows recorded` + `OK: truthful-report contract` |
| `bash scripts/test-migrator-manifest.sh` | **PASS** — 12 passed, 0 failed |
| `bash scripts/tests/test-customization-preserve.sh` | **PASS** — 223 passed, 0 failed |
| `grep -n 'mcp.json.example' scripts/migrate-v10-to-v11.sh` | **empty** — stale row gone; `.agents/mcp_config.json.example` row (L98) remains (does not contain the literal `mcp.json.example` substring — it is `mcp_config.json.example`) |

## Combined patch

- **Path:** `/tmp/handoff-bd221-C3/changes-with-fixes.patch`
- **Emit method:** `git add -A -N` (register new files, no staging) → `git diff HEAD > <patch>` (read-only patch-emit only)
- **Size:** 1019 lines / 52566 bytes (non-empty)
- **Files (15, all C3):** add-capability.sh, lib/customization-preserve.sh,
  lib/detect.sh, lib/migrator-core.sh, migrate-v10-to-v11.sh, test-detect.sh,
  test-migrator-core.sh, test-restore-from-backup.sh, 2× fixture dirs
  (language-heterogeneous + v10-with-customization: assertions.tsv + manifest.tsv each),
  tests/test-customization-preserve.sh, tests/test-migrate-v10-to-v11.sh, validate-pack.py.
- **Both fix hunks present:**
  - SHOULD-1: patch line 351 `-project-template/.mcp.json.example	.mcp.json.example	claude-mcp-example	transform`
  - NIT-1: patch line 37 `+        # Per-CLI agents. The `.gemini/agents/` legs are a legacy-READ`

## Files changed inventory

| Path | Change type | My edit |
|---|---|---|
| scripts/migrate-v10-to-v11.sh | modified (C3 + SHOULD-1) | deleted 1 stale manifest row |
| scripts/lib/customization-preserve.sh | modified (C3 + NIT-1) | added 3-line carve-out comment |
| (13 other C3 files) | modified (C3 only) | untouched by me |

## Plan deviations

None. Only the two named fixes applied; no other C3 content touched.

## New POQs

None.

## Definition-of-Done checklist

| Item | Status |
|---|---|
| Operated only in the named C3 worktree (pwd + HEAD verified) | PASS |
| Main checkout never touched | PASS |
| SHOULD-1: stale `.mcp.json.example` row removed (only that row) | PASS |
| NIT-1: carve-out comment added (comment only, no behavior change) | PASS |
| validate-pack still 52 issues; Check 25 GREEN | PASS |
| test-migrator-manifest PASS | PASS |
| test-customization-preserve PASS | PASS |
| grep confirms stale row gone | PASS |
| Combined patch emitted (15 C3 files + 2 fix hunks), non-empty | PASS |
| No state-changing git verb run (diff + add -N only) | PASS |

## PREFLIGHT

PREFLIGHT: 2/2 fixes (SHOULD-1 stale .mcp.json.example row removed; NIT-1 carve-out comment added) in the C3 worktree; validate-pack 52 + Check 25 green; test-migrator-manifest + test-customization-preserve PASS; combined patch emitted; never touched main tree

## Rules-Applied Verification Block

| Rule | Evidence | Conclusion |
|---|---|---|
| agents-never-commit / never-apply / read-only-git-only | Only ran `git rev-parse`, `git status`, `git add -A -N` (index intent-to-add registration, no content staged), `git diff HEAD`. No commit/push/apply/restore/checkout/reset/stash run. | COMPLIANT |
| operate-only-in-the-named-worktree | `pwd` = `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a1fb1306a7195401d`; HEAD `d92e054`; branch `worktree-agent-a1fb1306a7195401d`. Every Read/Edit path under that worktree. Main checkout `optiquity-ai-agent-config-pack-v11-dev/` never referenced in any edit. | COMPLIANT |
| preflight-stop-means-stop | PREFLIGHT line emitted only after both edits + all 4 verifications PASS (validate-pack 52 / Check 25 green / 2 tests PASS / grep clean). No stop signal received. | COMPLIANT |
| scope-deliverables-to-the-ask | Exactly 2 edits made (1 line deleted in migrate-v10-to-v11.sh; 3-line comment added in customization-preserve.sh). `git diff HEAD --stat` shows only those 2 files carry my deltas beyond the pre-existing C3 changes. | COMPLIANT |
| agent-output-requires-rules-applied-verification-block | This block. | COMPLIANT |
