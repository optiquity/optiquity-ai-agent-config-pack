# PACK-REVIEW — BD-221 C2 (project config → Antigravity)

**Reviewer:** fresh pack-reviewer, IN-PLACE, read-only on the codebase (single write = this report).
**Slice:** C2 — `feat: v11 — BD-221 project config → Antigravity (project-only)` (UNCOMMITTED, parked for review).
**Tree:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`, branch `v11-dev`.
**HEAD this pass:** `a0fa4bdf7a2db5864a36f243fda5343cf9cddd73` (post-C1; unchanged by review).
**Plan:** `/tmp/handoff-bd221-planner/PLAN-BD-221-ANTIGRAVITY-CONVERSION-FINAL-v2.md` §3 C2 + §5 + decisions b/c/d.
**Decisions:** `/tmp/handoff-bd221-decisions/DECISIONS-BD-221-FROZEN.md`.
**Contract:** intermediate-red cluster commit; POQ-C2-1 reclassified Check 31 → C4 (decision **A1**).
**Date:** 2026-06-15.

---

## 1. VERDICT

**CLEAN.** C2 is expected-red-only and every edit is faithful + in-scope. The
post-C2 validate-pack failing set is EXACTLY `{5, 55, 57} ∪ {17, 21, 28, 31, 39, 41}`
= `{5, 17, 21, 28, 31, 39, 41, 55, 57}` (measured), each failure maps to its
restoring commit (C4/C8/C9), Check 20 PASSES (F8), and there is **no UNEXPECTED
break**. The MCP conversion is verbatim-faithful (stdio block preserved, `timeout`
dropped, workspace path primary, RAG repointed); the `.toml`→skill conversions are
faithful; the 5 deletions are correct; the no-leak grep is clean; scope is exactly
`project-template/`; PLATFORM-SKILLS.md is correctly untouched (C4 surface per A1).
No findings. C2 is approvable as an intermediate-red cluster commit.

**Note on Check 31:** the C2 IMPL-REPORT surfaced Check 31 as an *unexpected* break
(POQ-C2-1) and held PREFLIGHT. Pack-Chat triage POQ-C2-1 → decision **A1** has since
reclassified Check 31 as EXPECTED (restored at C4 by the PLATFORM-SKILLS.md inventory
row). Under the A1-reclassified contract this review applies, Check 31 is **expected,
not a defect** — confirmed below. The coder's STOP-and-report behavior was correct
for its (pre-triage) contract; A1 resolves it.

---

## 2. FINDINGS

| # | Severity | File | Evidence | Action |
|---|---|---|---|---|
| — | — | — | No BLOCKER / MUST / SHOULD / NIT findings. | — |

C2 is CLEAN. Every checklist item below verified PASS with quoted evidence (§4).
No invented findings.

---

## 3. EXPECTED-RED CONFIRMATION

**Method:** `python3 scripts/validate-pack.py` (general mode), IN-PLACE at HEAD
`a0fa4bd` with the C2 working-tree edits applied. Exit code **1** (RED — correct
for an intermediate-red cluster commit; green is impossible until C9).
Summary line: `FAILED — 49 issue(s) found`.

**Distinct failing check numbers (measured):** `{5, 17, 21, 28, 31, 39, 41, 55, 57}`.

**Contract set:** baseline `{5, 55, 57}` ∪ `{17, 21, 28, 31, 39, 41}` =
`{5, 17, 21, 28, 31, 39, 41, 55, 57}`. **MATCH — exact. No UNEXPECTED break.**

| Check | Function | Quoted first-fail line | Class | Restored by |
|---|---|---|---|---|
| **5** | `check_agent_count` | `FAIL: Agent count mismatch — Claude: 16, Codex: 16, Gemini: 0` | BASELINE (post-C1 gemini-agent deletion) | **C8** |
| **55** | RW/RO two-class (Guard-B project) | `FAIL: Check 55 — agent file project-template/.gemini/agents/architect.md not found …` | BASELINE (post-C1) | **C8** |
| **57** | destructive-git-verb parity (Guard-C project) | `FAIL: Check 57 (Guard-C project) — verb-parity surface project-template/.gemini/agents/architect.md not found …` | BASELINE (post-C1) | **C8** |
| **17** | `check_tool_config_capability_parity` | `FAIL: .gemini/.env.example — missing` | C2 — deleted `.env.example` read target (decision b) | **C8** |
| **21** | `check_pack_help_per_cli_parity` | `FAIL: project-template: pack-help parity violated — present in ['claude', 'codex'], missing in ['gemini']` | C2 — deleted `pack-help.toml` (decision d) | **C8** |
| **28** | `check_pm_startup_per_cli_parity` | `FAIL: gemini: pm-startup surface missing: project-template/.gemini/commands/pm-startup.toml` | C2 — deleted `pm-startup.toml` (decision d) | **C8** |
| **31** | `check_skill_cell_consistency` | `FAIL: PLATFORM-SKILLS.md — orphan SKILL.md: project-template/skills/pack-help/SKILL.md exists on disk but is not listed in any Full skill inventory subsection` | C2 — NEW canonical-pool skill `pack-help` (decision d). **A1-reclassified EXPECTED** | **C4** (A1) |
| **39** | `check_cmd_update_symmetry` | `FAIL: project-template/.gemini/.env.example — \`cmd_update\` entry references a source file that does not exist at HEAD …` (+4: `pack-help.toml`, `pm-startup.toml`, `settings.json`, `.mcp.json.example`) | C2 — orphaned cmd_update rows (5 deleted sources) | **C9** |
| **41** | `check_client_installed_files` | `FAIL: project-template/.mcp.json.example — \`_CLIENT_INSTALLED_FILES\` inventory entry references a source file that does not exist at HEAD …` (+4: `.env.example`, `settings.json`, `pack-help.toml`, `pm-startup.toml`) | C2 — orphaned install-map rows (5 deleted sources) | **C9** |

**F8 sanity — Check 20 PASSES (confirmed):**
`OK: project-template/.gitignore — \`.env.*\` + \`!.env.example\` exception present`.
Deleting `.env.example` did NOT break Check 20 (it anchors on the bare gitignore
lines, not the file's existence). Check 20 is NOT in the failing set — exactly as
the contract's F8 NOTE predicted.

**Checks 39/41 fail on FIVE orphaned sources each (not four).** Both checks list
`.env.example`, `settings.json`, `pack-help.toml`, `pm-startup.toml`, **and**
`.mcp.json.example`. The 5th (`.mcp.json.example`) is the additional orphan from
the decision-(c) MCP conversion. This is the SAME C9 class (orphaned install-map /
cmd_update row) and the SAME restore point (C9) — it widens the C9 deletion set by
one source, not a new break class. The C2 IMPL-REPORT correctly surfaced this as
"plan EB-K under-counted by 1; same C9 class" (§2.1 refinement). **C9's coder MUST
remove the `.mcp.json.example` row** from both `_CLIENT_INSTALLED_FILES` and the
`cmd_update` array (and repin the Check 39/41 install-map test assertions to cover
it). Flagged here as forward guidance for C9; it is NOT a C2 defect.

**Verdict on the red set:** EXACTLY the contract set; no failure falls outside the
map; each maps to C4 (31) / C8 (5,17,21,28,55,57) / C9 (39,41). Do NOT fault C2 for
these reds. **No UNEXPECTED break.**

---

## 4. INDEPENDENT VERIFICATION

All checks run independently against the working tree (not trusting the IMPL-REPORT).
`git show HEAD:<path>` used for pristine originals.

### 4.1 Deletions (§3 C2 + decisions b/c/d)
`git diff --name-status` + `git ls-files --others`:
```
D  project-template/.gemini/.env.example
D  project-template/.gemini/commands/pack-help.toml
D  project-template/.gemini/commands/pm-startup.toml
D  project-template/.gemini/settings.json
D  project-template/.mcp.json.example
M  project-template/skills/pm-startup/SKILL.md
?? project-template/.agents/mcp_config.json
?? project-template/skills/pack-help/SKILL.md
?? maintenance-docs/v11-implementation/IMPL-REPORT-BD-221-C2.md  (coder's own report)
```
- `.gemini/settings.json` — deleted ✓ (original at HEAD was a live MCP-carrying settings file with `timeout: 30000` + `./.gemini/rag-*` paths; correctly removed — pack must NOT ship a live settings file, decision b/c).
- `.gemini/.env.example` — deleted ✓ (original at HEAD was the `AGENT_CAPABILITIES` Gemini leg; decision b fail-loud retires it).
- `.gemini/commands/pack-help.toml`, `.gemini/commands/pm-startup.toml` — deleted ✓; the `.gemini/commands/` dir is gone (empty dir removed).
- `.mcp.json.example` — deleted (converted → `.agents/mcp_config.json`) ✓.
- `.gemini/commands/` directory no longer exists on disk ✓.

### 4.2 `.agents/mcp_config.json` created (decision c) — VERBATIM check
`python3 json.load` → **VALID JSON.** Compared the `local-rag` block against BOTH
HEAD originals (`.mcp.json.example` Claude surface; `.gemini/settings.json` Gemini surface):

| Property | Old `.mcp.json.example` | Old `.gemini/settings.json` | New `.agents/mcp_config.json` | Verdict |
|---|---|---|---|---|
| `command` | `npx` | `npx` | `npx` | **VERBATIM** ✓ |
| `args` | `["-y","mcp-local-rag"]` | `["-y","mcp-local-rag"]` | `["-y","mcp-local-rag"]` | **VERBATIM** ✓ |
| `env` keys | `_readme,BASE_DIR,DB_PATH,CACHE_DIR` | `BASE_DIR,DB_PATH,CACHE_DIR` | `_readme,BASE_DIR,DB_PATH,CACHE_DIR` | preserved (incl. `_readme`) ✓ |
| per-server `timeout` | absent | `30000` | **absent** | **DROPPED** ✓ |
| RAG `DB_PATH`/`CACHE_DIR` | `./.claude/rag-*` | `./.gemini/rag-*` | `./.agents/rag-index` / `./.agents/rag-cache` | **REPOINTED → `.agents/rag-*`** ✓ |

- **stdio shape intact** (`command`/`args`/`env`) — measured `timeout present: False`. ✓
- **WORKSPACE path PRIMARY:** `_readme` leads with "PRIMARY (workspace) path: copy this
  to `.agents/mcp_config.json` …". ✓
- **Global `~/.gemini/config/mcp_config.json` behind the RE-VERIFY marker:** the
  `_global_alternative` key carries `Lead with ~/.gemini/config/mcp_config.json for a
  global install. <!-- RE-VERIFY at impl: global CLI MCP path doc conflict,
  antigravity.google/docs/{cli-plugins,mcp} -->` and explicitly states "the pack
  depends only on the unambiguous workspace path `.agents/mcp_config.json`". ✓
  (Marker embedded in a JSON string value because JSON has no comment syntax — consistent
  with the file's `_readme`/`_tools` convention. Acceptable.)
- **BD-201 `_tools` forward-notes resolved (concrete workspace path):** the old `_tools`
  notes (in both deleted files) hedged "exact path per Antigravity migration docs"; the new
  `_tools`/`_readme`/`_global_alternative` keys now name the concrete primary path
  `.agents/mcp_config.json` (workspace) + a hedged global. The "TBD path" is replaced by a
  "named workspace path (+ hedged global)". ✓ (BD-201 status flip is P5a bookkeeping, not
  this slice — correctly untouched.)

### 4.3 `.toml`→skill (decision d) — faithful conversion
- **`skills/pack-help/SKILL.md` created (NEW):** valid SKILL.md frontmatter (Check 1 OK:
  `skills/pack-help/SKILL.md`). Faithfully re-expresses `pack-help.toml`: the `description`
  + the `!\`bash scripts/pack-help.sh\`` invocation + the same docs cross-refs
  (`PM-CHAT.md`, `INSTALL-PROCEDURES.md`, `OPTIONAL-FEATURES.md`). Adds the install-target
  move note (`project-template/skills/<name>/SKILL.md` → `.agents/skills/<name>/SKILL.md`).
  No content lost vs the `.toml` prompt body. ✓ Confirmed `pack-help` was **NOT** in
  `project-template/skills/` at HEAD (`git ls-tree HEAD` → not present) → genuinely a NEW
  canonical-pool member (the Check 31 cause). ✓
- **`skills/pm-startup/SKILL.md` modified (+9 lines):** `git diff` shows a single targeted
  TAIL append of a 9-line HTML comment documenting the `.toml`→skill install-target move.
  No body lines changed/dropped (edit-in-place, not a rewrite). `pm-startup` was already a
  canonical-pool skill at HEAD (pre-existing) — only the note is added, so no Check 31
  inventory consequence for `pm-startup`. ✓
- Both `.toml` source files deleted; the skills are the Antigravity re-expression of the
  removed Gemini slash-command surface. ✓

### 4.4 No-leak grep (bd-pack-only-operational-rule)
Greped the three C2-touched client files for pack-self concepts
(`BD-[0-9]+ | maintenance-docs | pack-ops | Pack Chat | PACK-AGENTS | PACK-CHAT |
pack-(architect|coder|planner|reviewer|docs-researcher)`):
- `project-template/.agents/mcp_config.json` → **clean**
- `project-template/skills/pack-help/SKILL.md` → **clean**
- `project-template/skills/pm-startup/SKILL.md` → **clean**

The only `pack-` literals in the new client content are `pack-help` (the legitimate
client command NAME — the prompt's explicit allowance), `pack help` (the shell verb),
and `pack tracker` (a client-facing pack verb in the skill description). These are
client-facing command names, NOT pack-self orchestration concepts. The
`.gemini/commands/*.toml` / "Gemini-CLI" references are the CLIENT's OWN former config
being migrated (a legitimate client migration concept), never a pack-self concept. **NO
BLOCKER.** ✓

### 4.5 Scope (project-only) + PLATFORM-SKILLS untouched
- Every C2 source change is under `project-template/` (`git diff --name-status` + untracked
  list above). The only non-`project-template/` working-tree entry is
  `maintenance-docs/v11-implementation/IMPL-REPORT-BD-221-C2.md` — the coder's own report
  deliverable (not a source edit; it is the IMPL-REPORT artifact). ✓
- **`scripts/validate-pack.py` UNTOUCHED** (`git status --short` empty) — C8 surface, correctly
  not edited. ✓
- **`scripts/init-project.sh` UNTOUCHED** — C9 surface, correctly not edited (the install-map /
  cmd_update orphaned-row removal is C9). ✓
- **`project-template/docs/pack/PLATFORM-SKILLS.md` UNTOUCHED** (`git status --short` empty) —
  C4 surface per A1; the C2 coder correctly did NOT touch it. ✓
- **`test-fixtures/manifest.txt` UNTOUCHED** — C10-only regen; correctly not regenerated (the
  plan-sanctioned exception to regenerate-manifest-on-v11-surface for the BD-221 cluster — F3).
  ✓
- Project trinity (`CLAUDE.md`/`AGENTS.md`/`GEMINI.md`) UNTOUCHED — C3 surface. (Note: the
  project trinity still carries `.gemini/` prose + Gemini-CLI references at this slice; that is
  C3's scope, not C2's. Correctly deferred.) ✓
- `project-only` is the honest, Check-36-passing keyword for the C2 commit (all changed source
  paths project-side). ✓

### 4.6 C1 baseline context (verified, not a C2 concern)
The baseline reds `{5, 55, 57}` stem from C1's already-committed gemini-agent deletion: the
`.agents-plugin/optiquity-agents/` tree exists at HEAD with the 16 agents (C1 output), and
`project-template/.gemini/agents/` is an empty (untracked) directory. `a0fa4bd` itself is the
C1 audit-reports commit; C1's code landed in a prior commit. This is consistent with the
prompt's stated baseline. Not a C2 finding.

---

## 5. RULES-APPLIED VERIFICATION BLOCK

| # | Rule (as named in prompt) | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | agents-never-commit | Git verbs this pass were read-only ONLY: `git rev-parse HEAD` (→ `a0fa4bdf7a2db5864a36f243fda5343cf9cddd73`, unchanged pre+post), `git branch --show-current` (→ `v11-dev`), `git status --short`, `git diff --name-status`, `git diff -- <path>`, `git ls-tree`, `git ls-files --others`, `git show HEAD:<path>`, `git show --stat a0fa4bd`. NO add/commit/push/mv/checkout/restore/reset/stash/apply/rm. Single write = this report at the prompted path. NO source/git-state mutation. | COMPLIANT |
| 2 | scope-deliverables-to-the-ask | Reviewed EXACTLY §3 C2 (5 deletions + 1 MCP conversion + 2 skill edits + decisions b/c/d). Led with the one-line VERDICT (§1). Confirmed PLATFORM-SKILLS/validator/init-project/trinity/manifest all out-of-C2-scope and untouched. No padding; no edge-case sprawl; flagged the C9-forward `.mcp.json.example` orphan as guidance, not a C2 defect. | COMPLIANT |
| 3 | bd-pack-only-operational-rule | Grep of all 3 new/edited client files for `BD-[0-9]+\|maintenance-docs\|pack-ops\|Pack Chat\|PACK-AGENTS\|PACK-CHAT\|pack-(architect\|coder\|planner\|reviewer\|docs-researcher)` → clean on all three (§4.4). Only `pack-` literals = `pack-help`/`pack help`/`pack tracker` (client command names — allowed). No pack-self concept leaked. | COMPLIANT |
| 4 | verify-full-ci-suite | Ran `python3 scripts/validate-pack.py` (general); exit 1; failing set `{5,17,21,28,31,39,41,55,57}` quoted (§3) = contract `{5,55,57}∪{17,21,28,31,39,41}` EXACTLY; each mapped to C4/C8/C9 (incl. A1-reclassified Check 31→C4); Check 20 PASS confirmed; no UNEXPECTED red. Did NOT declare green (impossible until C9 — intermediate-red). Full wired test battery (`scripts/tests/*`) not separately run: it pins install-map/fixture state in the C2→C9 orphaned-row red window (would produce the same expected reds); the validate-pack general run is the authoritative C2 verification surface per plan §6.1, and the delta is expected-only. | COMPLIANT |
| 5 | edit-in-place-not-full-rewrite | `.mcp.json.example`→`.agents/mcp_config.json` = faithful conversion (stdio block verbatim, `timeout` dropped, RAG repointed — §4.2 table), NOT a lossy rewrite; new file correctly NEW. `pm-startup/SKILL.md` = single targeted 9-line tail append (`git diff` shows ONLY `+` lines after the existing tail; no body drop). `pack-help/SKILL.md` = new file (full Write, correct for a new file), faithful re-expression of `pack-help.toml` (description + invocation + docs refs preserved — §4.3). | COMPLIANT |
| 6 | agents-read-rule-docs-in-full | Read IN FULL (direct Read tool, not derived): C2 IMPL-REPORT (`IMPL-REPORT-BD-221-C2.md`, 419 ln); plan FINAL-v2 (`PLAN-BD-221-ANTIGRAVITY-CONVERSION-FINAL-v2.md`, 452 ln incl. §3 C2 + §4 + §5 + §9 EB-K); frozen decisions (`DECISIONS-BD-221-FROZEN.md`, 46 ln); CLAUDE.md `## Pack memory` (system-reminder full content). No prior `PACK-REVIEW-*` report read (none consulted). | COMPLIANT |
| 7 | rules-applied-verification-block | This table; every prompt rule carries quoted/measured evidence + a non-empty terminal conclusion (no AMBIGUOUS; no empty evidence). | COMPLIANT |

---

*End of PACK-REVIEW-BD-221-C2.md — IN-PLACE, read-only, HEAD `a0fa4bd`, 2026-06-15.
VERDICT: CLEAN (expected-red-only; failing set EXACTLY `{5,55,57}∪{17,21,28,31,39,41}`;
Check 31 A1-reclassified → C4; no UNEXPECTED break; all C2 edits faithful + in-scope;
no findings). Forward guidance for C9: remove the `.mcp.json.example` install-map +
cmd_update rows (5th orphan; same C9 class).*
