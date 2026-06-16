# IMPL-REPORT — BD-221 C2 (project config → Antigravity)

**BD:** BD-221 (Gemini CLI → Antigravity CLI full conversion; v11.0 launch gate; resolves BD-201).
**Commit slice:** C2 — `feat: v11 — BD-221 project config → Antigravity (project-only)`.
**Coder:** fresh pack-coder, IN-PLACE regime.
**Tree:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`, branch `v11-dev`.
**Base HEAD (pre-flight + final, unchanged — agents never commit):** `a0fa4bdf7a2db5864a36f243fda5343cf9cddd73` (post-C1).
**Date:** 2026-06-15.
**Plan:** `/tmp/handoff-bd221-planner/PLAN-BD-221-ANTIGRAVITY-CONVERSION-FINAL-v2.md` §3 C2 (+ decisions b/c/d, §5 forward-looking register).
**`agy --version`:** NOT observed this slice — Antigravity CLI is not installed in this environment; C2 touches no `agy` invocation surface (agent-run.sh / install plumbing are C1/C9). The FL register's `agy --version` pin is a C1/C9 obligation; no C2 contract depends on it.

---

## ⚠️ TOP-LINE STATUS — one UNEXPECTED check break (NEW POQ); not a green PREFLIGHT

C2's edits are complete and faithful to the plan's literal §3-C2 directives.
The baseline-delta verification produced **one delta check OUTSIDE the plan's
C2 expected-break map: Check 31 (`check_skill_cell_consistency`)**, caused by
the plan-mandated creation of a NEW canonical-pool skill
`project-template/skills/pack-help/SKILL.md` that is not yet inventoried in
`project-template/docs/pack/PLATFORM-SKILLS.md`. The fix is a **C4-surface**
edit (PLATFORM-SKILLS.md) that **neither C4 nor C8/C9 enumerates** — a genuine
**plan gap**. Per the C2 contract ("If an unexpected check breaks, STOP and
report it; do NOT fix out-of-scope surfaces") I have NOT touched PLATFORM-
SKILLS.md and am reporting the break for Pack Chat triage **instead of a green
PREFLIGHT**. See § "NEW POQ — Check 31" below. All other delta checks
({17, 21, 28, 39, 41}) are EXPECTED and mapped to a C2 cause + restoring commit.

---

## 1. Per-file change list (the C2 edits)

| # | Path | Change | Rationale (plan §3 C2) |
|---|---|---|---|
| 1 | `project-template/.gemini/settings.json` | **DELETE** | Decision (b)/(c): Antigravity auto-writes settings.json; the pack must NOT ship a live settings file. The MCP block it carried moves to `.agents/mcp_config.json`. |
| 2 | `project-template/.gemini/.env.example` | **DELETE** | Decision (b) fail-loud: the `AGENT_CAPABILITIES` Gemini leg is retired; capability parity becomes a Claude↔Codex 2-way invariant. |
| 3 | `project-template/.mcp.json.example` | **DELETE** (converted → #4) | Decision (c): the MCP example is renamed/converted to the Antigravity workspace surface `.agents/mcp_config.json`. |
| 4 | `project-template/.agents/mcp_config.json` | **CREATE** | Decision (c): Antigravity workspace MCP example. `local-rag` stdio block VERBATIM (`command`/`args`/`env`); per-server `timeout` DROPPED; workspace path PRIMARY; `~/.gemini/config/mcp_config.json` mentioned as hedged global alternative behind the RE-VERIFY marker; RAG defaults repointed `→ ./.agents/rag-*`. Resolves the BD-201 `_tools` forward-notes by naming the concrete workspace path. |
| 5 | `project-template/.gemini/commands/pack-help.toml` | **DELETE** (re-expressed → #7) | Decision (d): the client `.toml` slash-command is re-expressed as a canonical-pool skill. |
| 6 | `project-template/.gemini/commands/pm-startup.toml` | **DELETE** (re-expressed → existing skill) | Decision (d): the client `.toml` slash-command's body already exists as the canonical-pool skill `project-template/skills/pm-startup/SKILL.md` (present at HEAD); the `.toml` is the removed Gemini surface. |
| 7 | `project-template/skills/pack-help/SKILL.md` | **CREATE** | Decision (d): re-express `pack-help.toml` as a skill under `project-template/skills/<name>/SKILL.md` (installs to `.agents/skills/`). Documents the skills install-target path move. |
| 8 | `project-template/skills/pm-startup/SKILL.md` | **MODIFY** (+9 lines, tail HTML-comment) | Decision (d): document the Antigravity skills install-target path move (`project-template/skills/<name>/SKILL.md` → `.agents/skills/<name>/SKILL.md`; replaces the deleted `.gemini/commands/pm-startup.toml`). Targeted in-place append only (edit-in-place-not-full-rewrite). |
| 9 | `project-template/.gemini/commands/` (dir) | **REMOVED** (now empty) | Mechanical: the directory held only the two deleted `.toml` files; removed the empty dir. Git does not track empty dirs. |

**Note on the architecture discovered (not a deviation — context for Pack Chat):**
The pre-C2 per-CLI command-surface architecture was:
- `pm-startup`: canonical-pool skill `project-template/skills/pm-startup/` (auto-distributed to `.claude`/`.codex`/`.gemini` via `stage_s4_skills()`) PLUS the Gemini `.toml` surface. ALREADY inventoried in PLATFORM-SKILLS.md "PM chat operational skill (1)".
- `pack-help`: NOT a canonical-pool skill — per-CLI copies only (`.claude/skills/pack-help/`, `.codex/skills/pack-help/`, identical) distributed via the explicit BD-077 copy block in `init-project.sh`, plus the Gemini `.toml`. NOT in the PLATFORM-SKILLS.md inventory.

Converting `pack-help`'s Gemini surface to a `project-template/skills/` skill per
the plan therefore introduces a BRAND-NEW canonical-pool member (37th dir;
inventory lists 36) — which is what trips Check 31. See § "NEW POQ".

---

## 2. Baseline → post-C2 validate-pack delta (the verification contract)

**Method:** baseline-delta (intermediate-red cluster commit). Both runs:
`python3 scripts/validate-pack.py` (general mode).

- **BASELINE (post-C1, before C2 edits):** exit 1; failing checks = **{Check 5, Check 55, Check 57}** (the moved/deleted agent dir from C1; restored at C8). Matches the prompt's stated baseline exactly.
- **POST-C2:** exit 1; failing checks = **{Check 5, 17, 21, 28, 31, 39, 41, 55, 57}**.
- **DELTA (new failing vs baseline):** **{Check 17, 21, 28, 31, 39, 41}**.
- **Checks that stopped failing:** none (baseline {5,55,57} all still failing — correct; C2 does not touch the agent dir).

### 2.1 EXPECTED delta — each mapped to a C2 cause + restoring commit

| Check | Function | First fail line (quoted) | C2 cause | Restored by |
|---|---|---|---|---|
| **17** | `check_tool_config_capability_parity` | `FAIL: .gemini/.env.example — missing` | Deleted `.gemini/.env.example` — the Gemini leg's capability read target is gone. | **C8** (Check 17 → Claude↔Codex 2-way, decision b). Matches prompt + plan §3 C2 content axis. |
| **21** | `check_pack_help_per_cli_parity` | `FAIL: project-template: pack-help parity violated — present in ['claude', 'codex'], missing in ['gemini']` | Deleted `pack-help.toml` (the Gemini pack-help surface). | **C8** (plan §3 C8 names `check_pack_help_per_cli_parity` in the path-token-convert cohort; the parity check is re-expressed for the Antigravity surface). |
| **28** | `check_pm_startup_per_cli_parity` | `FAIL: gemini: pm-startup surface missing: project-template/.gemini/commands/pm-startup.toml` | Deleted `pm-startup.toml` (the Gemini pm-startup surface). | **C8** (plan §3 C8 names `check_pm_startup_per_cli_parity` in the path-token-convert cohort). |
| **39** | `check_cmd_update_symmetry` (reverse-direction) | `FAIL: project-template/.gemini/.env.example — cmd_update entry references a source file that does not exist at HEAD …` (+ 4 more: `.gemini/commands/pack-help.toml`, `…/pm-startup.toml`, `.gemini/settings.json`, `.mcp.json.example`) | Deleted source files orphan their `cmd_update` `entries=()` rows in `init-project.sh` (L1236 `.mcp.json.example`, L1240 `.env.example`, L1241 `settings.json`, L1263 `pack-help.toml`, L1275 `pm-startup.toml`). | **C9** (E3 + cmd_update array edits; MUST-FIX). The C2→C9 orphaned-row window is cross-surface (C2 project-only / C9 pack-only) and unavoidable. |
| **41** | `check_client_installed_files` | `FAIL: project-template/.mcp.json.example — _CLIENT_INSTALLED_FILES inventory entry references a source file that does not exist at HEAD …` (+ 4 more: `.gemini/.env.example`, `.gemini/settings.json`, `.gemini/commands/pack-help.toml`, `…/pm-startup.toml`) | Deleted source files orphan their `_CLIENT_INSTALLED_FILES` START/END rows in `init-project.sh` (L1398 `.mcp.json.example`, L1402 `.env.example`, L1403 `settings.json`, L1414 `pack-help.toml`, L1417 `pm-startup.toml`). | **C9** (E3 install-map-row deletion; MUST-FIX). |

**Refinement to surface (plan EB-K under-count — same C9 class, not a new break class):**
The plan's EB-K enumerated **four** `.gemini/` orphaned rows for Checks 39/41
(`.env.example`, `settings.json`, the 2 `.toml`). C2 ALSO converts/deletes
`project-template/.mcp.json.example`, which has its OWN install-map row
(init-project.sh L1398) and cmd_update row (L1236, mapping
`.mcp.json.example:.mcp.json.example:claude-mcp-example`). So Checks 39 + 41
each fail on **FIVE** orphaned source files, not four — the `.mcp.json.example`
pair is the additional orphan from the MCP conversion (decision c). This is the
SAME class (orphaned install-map / cmd_update row) and the SAME restore point
(**C9** removes/updates the `.mcp.json.example` row alongside the `.gemini/`
rows). It does not change the green-restoration model; it widens the C9
install-map deletion set by one source file. Flagged so C9's coder removes the
`.mcp.json.example` row too (and so the Check 41/39 per-check tests' install-map
assertions repinned in C9 cover it).

### 2.2 UNEXPECTED delta — NEW POQ (see § "NEW POQ — Check 31")

| Check | Function | Fail line (quoted) | Why unexpected |
|---|---|---|---|
| **31** | `check_skill_cell_consistency` (BD-146) | `FAIL: PLATFORM-SKILLS.md — orphan SKILL.md: project-template/skills/pack-help/SKILL.md exists on disk but is not listed in any Full skill inventory subsection` | NOT a parity check and NOT a `.toml`-removal break (the plan's loose "per-CLI parity / .toml-related checks" phrasing). It is a skill-INVENTORY-consistency break triggered by CREATING a new canonical-pool skill (`pack-help`). NOT in the plan's C2 expected-break map; NOT restored by C8 or C9 (neither touches PLATFORM-SKILLS.md). Fix lives on a C4 surface the plan does not enumerate. |

### 2.3 F8 sanity (prompt NOTE) — confirmed

`Check 20 (check_gitignore_env_example_exception)` **PASSES** post-C2:
`OK: project-template/.gitignore — '.env.*' + '!.env.example' exception present`.
Deleting `.env.example` did NOT break Check 20 (it anchors on the bare gitignore
lines `.env.*` / `!.env.example`, not on the file's existence) — exactly as the
prompt's F8 NOTE predicted. Check 20 is NOT in the delta.

---

## 3. NEW POQ — Check 31 (`check_skill_cell_consistency`) plan gap

**POQ-C2-1 — Adding `pack-help` to the canonical skills pool breaks Check 31; the
PLATFORM-SKILLS.md inventory edit is not enumerated by any commit slice.**

**Situation.** Plan §3 C2 item 4 directs: ".toml commands … REMOVE → skill under
`project-template/skills/<name>/SKILL.md` (installs to `.agents/skills/`)". For
`pack-help` this means creating a NEW canonical-pool skill (`pack-help` was
per-CLI-only at HEAD, never in `project-template/skills/`). Check 31
(`check_skill_cell_consistency`, BD-146) requires every
`project-template/skills/<name>/SKILL.md` on disk to appear in exactly one "Full
skill inventory" subsection of `project-template/docs/pack/PLATFORM-SKILLS.md`
(canonical-cell contract). `pack-help` has no inventory row → orphan → `fail()`.

**Why it is a gap, not a coder error.** (a) The plan's C2 expected-break list
covers {17, 39, 41} + parity/.toml checks; it never names Check 31. (b) C8 (the
content-axis validator restore) and C9 (the install-map restore) do not touch
PLATFORM-SKILLS.md, so neither restores Check 31. (c) C4 OWNS PLATFORM-SKILLS.md
("C4: client docs conversion … PLATFORM-SKILLS.md") but its plan text only
mentions `.gemini/skills/`→`.agents/skills/` path conversion — it does NOT
enumerate adding a `pack-help` inventory row or bumping the totals (36→37 + a new
"command surface" subsection or extension of the "PM chat operational skill"
subsection). The inventory currently lists 36 skills across 4 subsections (Tier 0
14 / Dimensional 20 / Trigger-loaded 1 / PM chat operational 1=`pm-startup`); the
canonical pool now holds 37 dirs.

**Disposition taken (this slice).** I implemented the plan's LITERAL directive
(create the canonical-pool skill — Option A) and did NOT touch the C4 surface
(PLATFORM-SKILLS.md) — out of C2 scope per the SCOPE GUARD + the "do NOT fix
out-of-scope surfaces" contract clause. Check 31 is left RED and surfaced here.

**Options for Pack Chat triage (recommendation: A1):**
- **A1 (recommended) — assign the PLATFORM-SKILLS.md inventory row to C4 and
  document Check 31 as a C2-introduced / C4-restored break.** Add a `pack-help`
  row (and, for symmetry, confirm `pm-startup`'s existing row) under a "command
  surface" inventory subsection (or extend "PM chat operational skill"), bump the
  subsection count + the `**Total skills: NN**` line, in C4. This keeps the
  plan's `.toml`→canonical-pool-skill directive intact and routes the inventory
  consequence to the slice that already owns PLATFORM-SKILLS.md. C4's coder must
  then expect Check 31 GREEN post-C4 (and C2→C4 carries Check 31 as an additional
  red in the intermediate-red window). NOTE: this extends the content-axis
  red-window membership — Check 31 is RED from C2 and restored at **C4**, NOT C8.
- **A2 — re-scope so `pack-help` does NOT enter the canonical pool.** Keep the
  Antigravity pack-help surface as a per-CLI artifact outside
  `project-template/skills/` (the only dir Check 31 scans), preserving the
  pre-C2 per-CLI architecture. This avoids Check 31 entirely but CONTRADICTS the
  plan's literal "skill under `project-template/skills/<name>/SKILL.md`"
  directive — so it needs an architect/planner sign-off, not a coder decision.
- **A3 — add a transitional `_CHECK_31` allowance.** Self-defeating (needs its
  own removal commit); discouraged, mirrors the plan's own rejection of
  transitional exemptions for the install-map axis (§4 option c).

**Re-prompt needed?** Yes — minimally, Pack Chat should confirm A1 (route the
PLATFORM-SKILLS.md row to C4 + note Check 31 in C2's expected-break set restored
at C4) or escalate A2 to architect/planner. I did not pre-empt that decision.

---

## 4. Forward-looking markers placed

| Marker | File | Text (verbatim) | FL register item (plan §5) |
|---|---|---|---|
| Global CLI MCP path | `project-template/.agents/mcp_config.json` (`_global_alternative` key) | `<!-- RE-VERIFY at impl: global CLI MCP path doc conflict, antigravity.google/docs/{cli-plugins,mcp} -->` | §5 row "Global CLI MCP path"; decision (c). The pack DEPENDS only on the workspace `.agents/mcp_config.json`; the global path leads with `~/.gemini/config/mcp_config.json` per the v1.0.3 CHANGELOG signal, behind the marker. |

No other FL markers are C2-scoped (plugin schema / agent invocation = C1/C5;
worktree note = C4; install staging / `save_memory` / model IDs = C3/C6/C9/C11).
The marker is embedded in a JSON string value because JSON has no comment syntax
— consistent with the existing `_readme`/`_tools` convention in the source file.

---

## 5. BD-201 resolution note

Decision (c) "resolves BD-201 under BD-221". The BD-201 work (the MCP `_tools`
forward-notes that previously hedged "exact path per Antigravity migration docs")
is RESOLVED in C2 by naming the **concrete workspace path** `.agents/mcp_config.json`:

- The old `.mcp.json.example` `_tools` note (Claude surface) and the deleted
  `.gemini/settings.json` `_tools` note both carried the BD-201 forward-language
  ("Antigravity preserves MCP, relocating the mcpServers block from settings.json
  to a dedicated mcp_config.json — exact path per Antigravity migration docs").
- The new `.agents/mcp_config.json` `_tools` + `_readme` + `_global_alternative`
  keys now state the concrete primary path (`.agents/mcp_config.json`, workspace)
  and a hedged global alternative behind the RE-VERIFY marker — the forward-note
  is converted from "TBD path" to "named workspace path (+ hedged global)".

BD-201 status flip (Deferred→Resolved in `backlog/BD-201.md`) is **P5a**
(pack-chat-only bookkeeping), NOT this coder slice — not touched here (no BD
status flips during implementation).

---

## 6. Files-changed inventory (for Pack Chat to stage)

`git status --short` (final; HEAD unchanged at `a0fa4bd`):

```
 D project-template/.gemini/.env.example
 D project-template/.gemini/commands/pack-help.toml
 D project-template/.gemini/commands/pm-startup.toml
 D project-template/.gemini/settings.json
 D project-template/.mcp.json.example
 M project-template/skills/pm-startup/SKILL.md
?? project-template/.agents/                       (new: mcp_config.json)
?? project-template/skills/pack-help/              (new: SKILL.md)
```

| Path | Change type |
|---|---|
| `project-template/.gemini/.env.example` | deleted |
| `project-template/.gemini/settings.json` | deleted |
| `project-template/.gemini/commands/pack-help.toml` | deleted |
| `project-template/.gemini/commands/pm-startup.toml` | deleted |
| `project-template/.mcp.json.example` | deleted (converted → `.agents/mcp_config.json`) |
| `project-template/.agents/mcp_config.json` | new |
| `project-template/skills/pack-help/SKILL.md` | new |
| `project-template/skills/pm-startup/SKILL.md` | modified (+9 lines) |

**Scope-keyword check (project-only):** every changed path is under
`project-template/` → exclusively project-side. No pack-only paths touched.
`project-only` is the honest, CI-Check-36-passing keyword for the C2 commit.

**Manifest:** `test-fixtures/manifest.txt` NOT regenerated (C10-only per plan F3
— `build.sh` is not Antigravity-aware until C10; C1–C9 cannot synthesize a
correct fixture tree). This is the plan-sanctioned exception to
regenerate-manifest-on-v11-surface for the BD-221 cluster.

---

## 7. Full contents of new files (for re-apply without re-derivation)

### `project-template/.agents/mcp_config.json`

```json
{
  "_readme": "Antigravity CLI MCP server configuration. PRIMARY (workspace) path: copy this to .agents/mcp_config.json at the project root and fill in your real values. .agents/mcp_config.json is gitignored — never commit it. Antigravity reads the workspace mcp_config.json when the CLI runs from this project root.",
  "_global_alternative": "As an alternative to the workspace file, MCP servers may be declared globally. Lead with ~/.gemini/config/mcp_config.json for a global install. <!-- RE-VERIFY at impl: global CLI MCP path doc conflict, antigravity.google/docs/{cli-plugins,mcp} --> The pack depends only on the unambiguous workspace path .agents/mcp_config.json; the global path is documented as a hedge.",
  "_tools": "mcp-local-rag provides semantic search over docs/pack/METHODOLOGY.md for PM chat sessions. The stdio server shape (command/args/env) is portable across MCP clients: this Antigravity workspace file is the primary surface; Codex reads its commented [mcp_servers.local-rag] block in .codex/config.toml.example using the same stdio command/args/env. Whether RAG is NEEDED depends on the project; the trinity context files (CLAUDE.md / AGENTS.md / GEMINI.md) already supply native context. Set BASE_DIR to the absolute path of this project.",
  "mcpServers": {
    "local-rag": {
      "command": "npx",
      "args": ["-y", "mcp-local-rag"],
      "env": {
        "_readme": "Set BASE_DIR to the absolute path of this project.",
        "BASE_DIR": "/absolute/path/to/your-project",
        "DB_PATH": "./.agents/rag-index",
        "CACHE_DIR": "./.agents/rag-cache"
      }
    }
  }
}
```

(Verified: parses as valid JSON; no `timeout`; workspace path primary; RAG
defaults `./.agents/rag-*`; global hedge behind the RE-VERIFY marker.)

### `project-template/skills/pack-help/SKILL.md`

```markdown
---
name: pack-help
description: Show all pack commands and colloquial mappings. Run when you need a quick reference for `pm-startup`, `pack tracker *`, `init-project.sh`, `agent-run.sh`, or any other top-level pack verb.
allowed-tools: Bash
---

The user wants to see the full pack verb list and colloquial phrasings. Run
the help script and present its output verbatim to the user.

## Help fragment

!`bash scripts/pack-help.sh`

## Notes

For full documentation, see `docs/pack/PM-CHAT.md`,
`docs/pack/INSTALL-PROCEDURES.md`, and `docs/pack/OPTIONAL-FEATURES.md`.
The shell verb `pack help` (LCD floor) prints the same content as this skill.

This skill replaces the former Gemini-CLI `.gemini/commands/pack-help.toml`
slash-command. Under Antigravity CLI, slash-command behavior is expressed as
a skill: skills in `project-template/skills/<name>/SKILL.md` install to the
workspace skills directory `.agents/skills/<name>/SKILL.md` (the Antigravity
workspace skills path) rather than to `.gemini/commands/*.toml`.
```

### `project-template/skills/pm-startup/SKILL.md` — appended tail (the +9-line MODIFY)

```markdown

<!--
This skill replaces the former Gemini-CLI `.gemini/commands/pm-startup.toml`
slash-command. Under Antigravity CLI, slash-command behavior is expressed as
a skill: skills in `project-template/skills/<name>/SKILL.md` install to the
workspace skills directory `.agents/skills/<name>/SKILL.md` (the Antigravity
workspace skills path) rather than to `.gemini/commands/*.toml`.
-->
```

---

## 8. Plan deviations

**One deviation surfaced as a POQ, NOT silently absorbed:** the plan's literal
§3-C2 directive ("re-express `.toml` → skill under
`project-template/skills/<name>/SKILL.md`") was implemented exactly, but its
Check-31 consequence (a NEW canonical-pool skill requires a PLATFORM-SKILLS.md
inventory row) is not enumerated by any commit slice. I implemented the plan's
recommended default (Option A — create the canonical-pool skill) and documented
the gap as POQ-C2-1 (§3). No design change made; no out-of-scope surface edited.

No other deviations. Every other C2 directive (b/c/d) implemented verbatim.

---

## 9. Boundary discipline check (project-side edits)

All C2 edits are on project-side surfaces (`project-template/`). Per the
P-missed-7 / bd-pack-only-operational-rule pre-flight:

| Project-side file | Project-side SSOT investigated | Result |
|---|---|---|
| `project-template/.agents/mcp_config.json` (new) | No project-side SSOT for the MCP-example concept beyond the deleted `.mcp.json.example` it converts; decision (c) is the design authority. | Implemented per plan; NO pack-self concept (grep clean). |
| `project-template/skills/pack-help/SKILL.md` (new) | The existing `project-template/.claude/skills/pack-help/SKILL.md` is the project-side content SSOT for the pack-help surface; the new skill faithfully re-expresses it. PLATFORM-SKILLS.md is the project-side SSOT for the skill inventory (Check 31) — surfaced as POQ-C2-1, NOT edited (C4 surface). | Implemented per plan; POQ raised. |
| `project-template/skills/pm-startup/SKILL.md` (modified) | The skill body is itself the project-side SSOT for the pm-startup procedure; the `.toml` was the parallel Gemini surface. | Targeted in-place append only. |

**Boundary leak grep (bd-pack-only-operational-rule):** all new/edited client
content greps **clean** for pack-self concepts — no `BD-NNN`, no
`maintenance-docs`, no `pack-ops`, no `Pack Chat`, no `pack-*` agent name, no
`PACK-AGENTS`/`PACK-CHAT`. The skills reference `.gemini/commands/*.toml` and
"Gemini-CLI" only as the CLIENT's own former config being migrated (a legitimate
client-side migration concept), never a pack-self concept.

**No boundary-discipline STOP triggered:** no C2 edit adds a reference to a
pack-only file or a Pack-Chat orchestrator role.

---

## 10. Definition-of-Done checklist

| Item | Status | Evidence |
|---|---|---|
| `.gemini/settings.json` removed (no live settings shipped) | PASS | `git status`: ` D project-template/.gemini/settings.json` |
| `.gemini/.env.example` deleted (decision b) | PASS | ` D project-template/.gemini/.env.example` |
| `.mcp.json.example` → `.agents/mcp_config.json` (decision c) | PASS | old deleted; new created + valid JSON |
| `local-rag` stdio block VERBATIM (`command`/`args`/`env`) | PASS | command `npx`, args `["-y","mcp-local-rag"]`, env preserved |
| per-server `timeout` DROPPED | PASS | `grep timeout` → 0 hits in new file |
| workspace `.agents/mcp_config.json` PRIMARY | PASS | `_readme` leads with workspace path |
| global `~/.gemini/config/mcp_config.json` hedged + RE-VERIFY marker | PASS | `_global_alternative` key carries both |
| RAG defaults → `./.agents/rag-*` | PASS | `DB_PATH`/`CACHE_DIR` = `./.agents/rag-{index,cache}` |
| `.toml` commands removed → skills (decision d) | PASS | both `.toml` deleted; `pack-help` skill created; `pm-startup` skill present |
| skills install-target path move documented | PASS | tail note in pack-help + pm-startup SKILL.md |
| BD-201 `_tools` forward-notes resolved (concrete workspace path) | PASS | §5; `_tools`/`_global_alternative` name the path |
| BD-201 status flip | N/A (P5a) | not a coder task |
| manifest NOT regenerated (C10-only) | PASS | manifest untouched (plan F3) |
| validator NOT edited (C8) | PASS | `scripts/validate-pack.py` not in `git status` |
| install map NOT edited (C9) | PASS | `scripts/init-project.sh` not in `git status` |
| project trinity NOT edited (C3) | PASS | `CLAUDE/AGENTS/GEMINI.md` not in `git status` |
| no pack-self leak (bd-pack-only-operational-rule) | PASS | §9 grep clean |
| baseline-delta verification run + delta mapped | PASS | §2 |
| every EXPECTED delta check mapped to C2 cause + restore commit | PASS | §2.1 ({17,21,28}→C8; {39,41}→C9) |
| NO unexplained break | **FAIL → surfaced** | Check 31 unexpected → POQ-C2-1 (§3); not silently fixed; reported instead of green PREFLIGHT |
| no git state-changing verb run | PASS | only `git rev-parse`/`status`/`diff`/`show`/`branch` (read-only) |
| HEAD unchanged | PASS | `a0fa4bd` pre + post |

**DoD verdict:** C2 EDITS complete + plan-faithful; **one DoD item (NO
unexplained break) is FAIL by design-surfacing** — Check 31 is an unexpected
break routed to Pack Chat triage (POQ-C2-1), per the C2 contract's STOP-and-
report clause for unexpected breaks. C2 is NOT independently green-clean (it is
an intermediate-red cluster commit; expected reds {17,21,28,39,41} restore at
C8/C9), and additionally carries the unexpected Check 31 needing a triage
decision before the C2 commit lands.

---

## 11. PREFLIGHT (modified per contract — unexpected break reported, NOT a green claim)

Per the C2 contract step 4 ("If an unexpected check breaks, STOP and report it")
and preflight-stop-means-stop ("if an unexpected check breaks … report INSTEAD
of a partial IMPL-REPORT"), I do NOT emit the success PREFLIGHT line. Reported
status:

```
PREFLIGHT-HELD: C2 edits complete (settings.json + .env.example deleted;
MCP → .agents/mcp_config.json [timeout dropped, workspace primary, RAG → .agents/rag-*];
.toml → skill [pack-help created, pm-startup present]; BD-201 resolved;
manifest NOT regen [C10-only]); HEAD a0fa4bd (unchanged).
BASELINE {Check 5,55,57} → post-C2 adds {17,21,28,31,39,41}.
EXPECTED (mapped): 17→C8, 21→C8, 28→C8, 39→C9, 41→C9 (39/41 each on 5 orphaned
source files incl. .mcp.json.example — plan EB-K under-counted by 1; same C9 class).
UNEXPECTED: Check 31 (check_skill_cell_consistency) — new canonical-pool skill
pack-help not in PLATFORM-SKILLS.md inventory; NOT restored by C8/C9; fix is a
C4 surface the plan does not enumerate → POQ-C2-1, surfaced for Pack Chat triage,
NOT fixed (out of C2 scope). Reporting instead of a green PREFLIGHT.
```

---

## 12. Rules-Applied Verification Block

| # | Rule (as named in prompt) | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | agents-never-commit | Edits IN-PLACE; deletions via filesystem `rm -f` (working-tree edits, NOT git verbs). Git verbs run this slice were read-only ONLY: `git rev-parse HEAD` (→ `a0fa4bdf7a2db5864a36f243fda5343cf9cddd73` pre + post, unchanged), `git status`, `git diff --stat`, `git show HEAD:<path>` (pristine reads), `git branch --show-current`. NO add/commit/push/mv/checkout/restore/reset/stash/apply. | COMPLIANT |
| 2 | preflight-stop-means-stop | An UNEXPECTED check (31) broke; per the rule I did NOT emit the green PREFLIGHT line — §11 reports `PREFLIGHT-HELD` with the unexpected break surfaced (POQ-C2-1) INSTEAD of a clean claim. No parent stop/halt/revert message was received during the slice. | COMPLIANT |
| 3 | edit-in-place-not-full-rewrite | `.mcp.json.example` converted by faithful re-expression (stdio block verbatim) into a new `.agents/mcp_config.json`; `pm-startup` SKILL.md changed via a single targeted tail append (Edit, +9 lines — full content unread-rewrite avoided); deletions are deletions; new files (`pack-help/SKILL.md`, `mcp_config.json`) are full Writes (correct — new files). No silent section drops. | COMPLIANT |
| 4 | bd-pack-only-operational-rule | Grep of all new/edited client files for `BD-[0-9]+\|maintenance-docs\|pack-ops\|Pack Chat\|pack-(architect\|coder\|planner\|reviewer\|docs-researcher)\|PACK-AGENTS\|PACK-CHAT` → `(clean — no pack-self concept)` on all three (§9). The `.gemini`/Gemini-CLI references are CLIENT-own former config (migration concept), not pack-self. | COMPLIANT |
| 5 | scope-deliverables-to-the-ask | Implemented EXACTLY §3 C2 (b/c/d): 5 deletions + 1 conversion + 2 skill edits. Did NOT touch validator (C8), install map (C9), project trinity (C3), or manifest (C10). The out-of-scope Check-31 fix (PLATFORM-SKILLS.md, C4) was SURFACED (POQ-C2-1), not fixed. No edge-case sprawl. | COMPLIANT |
| 6 | verify-full-ci-suite | Ran `python3 scripts/validate-pack.py` baseline (post-C1) AND post-C2; both failing sets quoted (§2); delta {17,21,28,31,39,41} computed + each mapped (§2.1/§2.2); green is NOT expected at C2 (intermediate-red). Full-battery wired tests (`scripts/tests/*`) NOT run this slice — they pin install-map/fixture state that is in the C2→C9 orphaned-row red window; the authoritative per-commit + reviewer full-battery run is the in-place reviewer's obligation (per plan §6.1). The validate-pack general run IS the C2 verification surface; the delta confirms expected-only EXCEPT Check 31. | COMPLIANT |
| 7 | rules-applied-verification-block | This table; every prompt rule carries quoted/measured evidence + a non-empty terminal conclusion (no AMBIGUOUS; no empty evidence). | COMPLIANT |

---

*End of IMPL-REPORT-BD-221-C2.md — IN-PLACE, base/final HEAD `a0fa4bd`, 2026-06-15. C2 edits complete + plan-faithful; one UNEXPECTED validate-pack delta (Check 31) surfaced as POQ-C2-1 for Pack Chat triage; reported instead of a green PREFLIGHT per the intermediate-red contract's STOP-and-report clause.*
