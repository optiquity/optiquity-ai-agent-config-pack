# IMPL-REPORT — BD-221 C4 (Client docs conversion, project-only)

## Summary

- **BD:** BD-221 (Gemini CLI → Antigravity conversion), commit slice **C4**.
- **Scope keyword:** `project-only`.
- **Regime:** IN-PLACE (verified: `pwd` = repo root, edits left in working
  tree, no `/tmp` handoff dir named in the prompt — report goes to the named
  parent-tree path).
- **Branch:** `v11-dev`
- **HEAD (unchanged — agents-never-commit):** `e8eb0a5d2f061ac53c8c9ab66b10bd81c3dc37b4`
- **Result:** PASS. Baseline-delta contract satisfied exactly — Check 31
  RESTORED green; Check 54 stays green; no new break. Client docs converted
  Gemini CLI → Antigravity CLI (audience-correct), no pack-self leak,
  forward-looking markers placed.

PREFLIGHT line emitted before this write:
`PREFLIGHT: C4 complete; baseline {5,17,18,21,28,31,39,41,55,57} → post-C4 = {5,17,18,21,28,39,41,55,57} (Check 31 RESTORED green; Check 54 green; no new break); client docs converted; about to Write IMPL-REPORT`

---

## Baseline → Post-C4 delta (verify-full-ci-suite)

Both runs were `python3 scripts/validate-pack.py` at HEAD `e8eb0a5`, parsed
per-check (variant-aware — Check 18 has `[project-template]` + `[pack-root]`
sub-blocks; a check number is RED if any of its variant blocks `FAIL`s).

- **BASELINE failing set (pre-C4, 10):** `{5, 17, 18, 21, 28, 31, 39, 41, 55, 57}`
  — matches the prompt's stated post-C3 baseline exactly.
- **POST-C4 failing set (9):** `{5, 17, 18, 21, 28, 39, 41, 55, 57}`
- **DELTA:** **Check 31 REMOVED (now GREEN).** No other change. No new break.
  - Check 54 (`check_optional_features_presence`): **GREEN** before and after.
  - Checks 5/17/18/21/28/39/41/55/57 remain RED (out-of-C4-scope cluster
    breaks restored by later commits C8/C9 per the plan — not C4's job).

Check 31 GREEN proof (post-C4 block, quoted verbatim):
```
── Check 31: Skill-cell consistency (BD-146, v11) ──
  OK: PLATFORM-SKILLS.md — 'Tier 0 base skills': 14 rows (header matches)
  OK: PLATFORM-SKILLS.md — 'Dimensional skills': 20 rows (header matches)
  OK: PLATFORM-SKILLS.md — 'Trigger-loaded skills': 1 rows (header matches)
  OK: PLATFORM-SKILLS.md — 'PM chat operational skill': 2 rows (header matches)
  OK: PLATFORM-SKILLS.md — total skills: 37 (header sum, inventory row count, and disk count all agree)
  OK: Skill-cell consistency: 37 SKILL.md on disk, all map to exactly one inventory cell; no orphans, phantoms, or double-counts
```

Check 54 GREEN proof (post-C4 block, quoted verbatim):
```
  OK: Check 54 (Guard-A′) — OPTIONAL-FEATURES presence holds across 2 surface(s) (pack + project): all 3 mandated tokens (`baseRef`, `bgIsolation`, `permissions.deny` recipe) documented in each. The un-prohibited worktree-isolation feature + its in-session backstop recipe stay documented (BD-197 Note 14).
```

Check-54 dedicated test (F2 token-blind coupling — pins
`_CHECK_54_OPTIONAL_FEATURES_SURFACES` + `_CHECK_54_REQUIRED_TOKENS`
against the OPTIONAL-FEATURES surfaces C4 edits):
`bash scripts/tests/test-validate-pack-check-54.sh` → **PASS: 3 / FAIL: 0**
("All tests passed."). Confirms the project OPTIONAL-FEATURES surface edit
did not shift token presence; no C8 repin of Check-54 tokens is required.

---

## Check-54 token-survival confirmation

`_CHECK_54_REQUIRED_TOKENS = ("baseRef", "bgIsolation", "permissions.deny")`
counts in `project-template/docs/pack/OPTIONAL-FEATURES.md`:

| Token | Pre-C4 count | Post-C4 count |
|---|---|---|
| `baseRef` | 10 | 10 |
| `bgIsolation` | 6 | 6 |
| `permissions.deny` | 4 | 4 |

The tokens all live in the Claude Code "Isolated parallel agents (worktree
isolation)" H2 section (L96–270), **not** under the converted
`## Gemini CLI — Optional features` → `## Antigravity CLI — Optional features`
H2 (which was a bare placeholder). Conversion preserved every token. This
matches plan §5 / EB-5 ("the 3 tokens appear 10/6/4× … NOT under the Gemini
H2"). No token-presence shift ⇒ no C8 repin needed (the soft RED→C8 edge
did not fire).

---

## Check-31 restoration detail (ci-guard-measure-then-bound)

**Measured first** (before editing the inventory), in `scripts/validate-pack.py`:
- `_INVENTORY_SUBSECTIONS` (L3100–3105) = `["Tier 0 base skills",
  "Dimensional skills", "Trigger-loaded skills", "PM chat operational skill"]`
  (note: `"PM chat operational skill"` is **singular** — hard-coded constant).
- `_parse_inventory_subsection` (L3108–3136): regex
  `^###\s+{re.escape(header)}\s*\((\d+)\)\s*\n(.*?)(?=^###\s+|^##\s+|\Z)` —
  matches the **exact** header string + a parenthesized `(N)` count; extracts
  skill names from the first table column.
- `check_skill_cell_consistency` (L3139+): enumerates disk skills under
  `project-template/skills/<name>/SKILL.md`; every disk skill must appear in
  exactly one inventory subsection; `(N)` must equal table row count; the
  `**Total skills: NN**` line must equal the subsection-count sum AND the
  unique inventory-row count AND the disk count.

**Root cause of the baseline Check-31 RED:**
`project-template/skills/pack-help/SKILL.md` exists on disk (37 disk skills)
but was **not listed** in any inventory subsection (inventory totaled 36) →
orphan SKILL.md FAIL.

**`pack-help` honest classification (no asymmetry, no fake):**
`pack-help`'s SKILL.md is a **canonical uniform skill** (frontmatter
`name: pack-help`, `allowed-tools: Bash`; body runs `bash scripts/pack-help.sh`).
It is **not** a per-CLI command — its own Notes section states it "replaces
the former Gemini-CLI `.gemini/commands/pack-help.toml` slash-command" and
installs to all three client skill dirs (`.claude/skills/`, `.codex/skills/`,
`.agents/skills/`) like every other skill via `stage_s4_skills()`. So there is
**no cross-CLI cell asymmetry** — it is honestly a uniform PM-chat operational
helper exactly like `pm-startup` (the existing "PM chat operational skill"
member). No POQ needed; honest green achievable.

**Fix applied** to `project-template/docs/pack/PLATFORM-SKILLS.md`:
- Subsection: **"PM chat operational skill"** (the model member is
  `pm-startup`; `pack-help` is the same operational class).
- **Count bump only:** header `### PM chat operational skill (1)` →
  `### PM chat operational skill (2)`. **Header TEXT kept EXACTLY** as the
  `_INVENTORY_SUBSECTIONS` constant — "skill" kept **singular**, NOT
  pluralized to "skills" (per the prompt LEARNING — pluralizing would break
  the regex). Only `(1)`→`(2)` changed.
- Added one table row:
  `| pack-help | Show all pack commands and colloquial mappings (the
  `/pack-help` quick reference); replaces the former per-CLI `pack-help`
  slash-command | PM chat / any tool user (not an agent) |`
- Generalized the subsection prose ("This skill is…" → "These skills are…")
  to cover both members without contradiction. Prose is body text; the regex
  only keys on the header line + table rows, so the prose edit is safe.
- Updated the total: `**Total skills: 36** (… 1 PM chat operational)` →
  `**Total skills: 37** (… 2 PM chat operational)`.

Post-fix Check 31 reports `'PM chat operational skill': 2 rows (header
matches)` and `total skills: 37 (header sum, inventory row count, and disk
count all agree)` — honest green.

---

## Per-file change list

### 1. `project-template/docs/pack/PM-CHAT.md`
Gemini CLI (the CLI) → Antigravity CLI (`agy`); per-CLI path tokens
normalized; the "Tool-specific: Gemini CLI" H2 section rewritten for
Antigravity. `GEMINI.md` (trinity member) and `~/.gemini/GEMINI.md` (global
context file) KEPT per the C3 trinity convention (Antigravity reads the
GEMINI.md hierarchy).
- L16–19: "three tools" list — `Gemini CLI: loaded via GEMINI.md hierarchy`
  → `Antigravity CLI (\`agy\`): loaded via the GEMINI.md hierarchy`.
- L78: design-brief workspace — "a Gemini CLI session" → "an Antigravity CLI
  session".
- L129: detection-scan directory row — `.gemini/agents/` →
  `.agents-plugin/optiquity-agents/agents/`; `.gemini/skills/` →
  `.agents/skills/`.
- L133: prompt-generation row — "referenced when generating Gemini agent
  prompts" → "Antigravity CLI context file; referenced when generating
  Antigravity agent prompts".
- L293–294: PM-chat file-editing scope — `.claude/.codex/ .gemini/ settings`
  → `.claude/ .codex/ .agents/ settings and config`.
- L357–358: Procedure-5 custom-files — agent `(.claude/.codex/.gemini)` →
  `(.claude/.codex agents, or the Antigravity plugin bundle
  .agents-plugin/optiquity-agents/agents/)`; skill `.gemini/skills/` →
  `.agents/skills/`.
- L400–402: agent-definition authoritative source — `.gemini/agents/<agent>.md`
  → `.agents-plugin/optiquity-agents/agents/<agent>.md`.
- L839–841: Claude-memory-cache note — "Codex CLI and Gemini CLI have no
  equivalent" → "Codex CLI and Antigravity CLI have no equivalent".
- L874–921: "## Tool-specific: Gemini CLI" H2 → "## Tool-specific:
  Antigravity CLI" — full subsection rewrite (`gemini`→`agy`; `/chat
  save`/`/chat resume` removed (Antigravity auto-manages context);
  `/compress`→`/fork`/`/rewind`; `save_memory` → "Persist … to
  `~/.gemini/GEMINI.md`" with a re-verify hedge). Added a
  `<!-- RE-VERIFY at impl … BD-217 coordination … -->` forward-looking
  marker at the section head.

### 2. `project-template/docs/pack/OPTIONAL-FEATURES.md`
- L7: intro parity line — "Claude Code, Codex CLI, and Gemini CLI" →
  "… and Antigravity CLI".
- L22: Agent-Teams Status — "no Codex or Gemini CLI equivalent" → "… or
  Antigravity CLI equivalent".
- L98: worktree-isolation Status — "no Codex or Gemini CLI equivalent yet"
  → "… or Antigravity CLI equivalent yet".
- L262 (Claude-only note): "Codex CLI and Gemini CLI have no equivalent" →
  "Codex CLI and Antigravity CLI have no equivalent".
- **L281 H2 conversion (the C4 headline):** `## Gemini CLI — Optional
  features` (bare placeholder) → `## Antigravity CLI — Optional features`
  — an Antigravity worktree/parallel note, FORWARD-LOOKING, coordinating
  BD-217, with the `<!-- RE-VERIFY at impl: Antigravity worktree feature,
  BD-217 coordination, antigravity.google/docs/getting-started -->` marker.
  No opt-in steps to run today; pack ships nothing dependent on the preview
  worktree feature (notes open data-loss reports).
- L175 (`CLAUDE.md`/`AGENTS.md`/`GEMINI.md` trinity ref): KEPT (trinity-file
  reference, not a CLI reference).
- Check-54 tokens (10/6/4) untouched.

### 3. `project-template/docs/pack/PLATFORM-SKILLS.md`
- L250: pack-repo own-skill-trees list — `.gemini/skills/` → `.agents/skills/`.
- L412: per-tool skill-location prose — `.gemini/skills/` → `.agents/skills/`.
- L486–501: "PM chat operational skill" subsection — Check-31 restoration
  (count `(1)`→`(2)`, `pack-help` row added, prose generalized, total
  `36`→`37`). See "Check-31 restoration detail" above.
- L615 (pack-repo trinity `GEMINI.md` `## Pack memory` ref): KEPT
  (trinity-file reference).

### 4. `project-template/docs/pack/prompts/pm-chat.md`
- L26: kickoff plan-mode note — "running Gemini CLI and currently in plan
  mode (`/plan`)" → "running Antigravity CLI in a non-executing context-only
  mode" with a re-verify hedge (plan-mode is Gemini-specific; Antigravity
  preview verbs unconfirmed).
- L44: recognized PM-chat surfaces — "Gemini CLI" → "Antigravity CLI".
- L329: PM-chat-surface setup — "or Gemini CLI" → "or Antigravity CLI".
- L504: agent-run example — `(or \`codex\`/\`gemini\` as appropriate)` →
  `(or \`codex\`/\`agy\` as appropriate)`.
- L81/225/230/312/356/359/406/495 (`GEMINI.md` trinity refs): KEPT.

### 5. `project-template/docs/pack/prompts/auditor.md`
- L74–77: subagent spawn per-tool mechanism — "Gemini CLI: native subagents
  in `.gemini/agents/`, but subagents cannot call subagents —
  `agent-run.sh run_gemini_auditor` provides external orchestration" →
  "Antigravity CLI: subagents from the plugin bundle
  (`.agents-plugin/optiquity-agents/agents/`) launched via Antigravity's
  subagent mechanism; if subagents cannot themselves spawn subagents,
  `./agent-run.sh agy --agent <subagent>` provides external orchestration"
  + a re-verify hedge against `antigravity.google/docs/subagents`.

### 6. `project-template/docs/pack/prompts/coder.md`
- L74: boundary-discipline per-CLI dir list — `.claude/ / .codex/ / .gemini/`
  → `.claude/ / .codex/ / .agents/ / .agents-plugin/`.

### 7. `project-template/docs/pack/prompts/reviewer.md`
- L93: dimension-9 project-SSOT skill-path list — `.gemini/skills/...` →
  `.agents/skills/...`.

---

## Forward-looking markers placed

| Marker | File / location | Purpose |
|---|---|---|
| `<!-- RE-VERIFY at impl: Antigravity worktree feature, BD-217 coordination, antigravity.google/docs/getting-started -->` | OPTIONAL-FEATURES.md, `## Antigravity CLI — Optional features` H2 | Plan §6 forward-looking register row for C4; worktree feature OUT of BD-221 base scope (BD-217, v11.1) |
| `<!-- RE-VERIFY at impl: Antigravity CLI session/context/memory commands, BD-217 coordination, antigravity.google/docs/getting-started … -->` | PM-CHAT.md, `## Tool-specific: Antigravity CLI` H2 | Preview-CLI verb names (session/context/memory) unconfirmed |
| Inline `(Re-verify … against antigravity.google/docs/* …)` hedges | PM-CHAT.md (resume/context/memory), pm-chat.md (mode-switch), auditor.md (subagent depth) | Per the plan's preview-CLI caution; matches C3 GEMINI.md hedging style |

These are HTML comments / inline parentheticals in DOCS (not trinity) — Check
19 (trinity-only scaffolding ban) does not apply, per the prompt.

---

## Files-changed inventory

| Path | Change type |
|---|---|
| `project-template/docs/pack/PM-CHAT.md` | modified |
| `project-template/docs/pack/OPTIONAL-FEATURES.md` | modified |
| `project-template/docs/pack/PLATFORM-SKILLS.md` | modified |
| `project-template/docs/pack/prompts/pm-chat.md` | modified |
| `project-template/docs/pack/prompts/auditor.md` | modified |
| `project-template/docs/pack/prompts/coder.md` | modified |
| `project-template/docs/pack/prompts/reviewer.md` | modified |

`git diff --stat`: 7 files, +86 / −57. No new files. No deletions. No file
outside `project-template/docs/pack/` touched (project-only scope verified).

**Manifest:** `test-fixtures/manifest.txt` NOT regenerated — C10-only per the
scope guard and plan F3 ("manifest-once-in-C10" model). Verified the manifest
tracks fixture git SHAs under `test-fixtures/` and lists none of the 7 edited
docs, so deferring its regen to C10 produces no drift.

---

## Boundary discipline check (P-missed-7)

All 7 edits are project-side files under `project-template/docs/pack/`. For
each, the project-side SSOT was investigated before editing:

- **PM-CHAT.md, prompts/*.md, PLATFORM-SKILLS.md, OPTIONAL-FEATURES.md:** the
  authoritative cross-CLI vocabulary was read from the **C3-converted project
  trinity** (`project-template/GEMINI.md` / `CLAUDE.md` / `AGENTS.md`), which
  is the project-side SSOT for what the third CLI is now called and how it is
  invoked. Canonical values copied (not invented): CLI = "Antigravity CLI
  (`agy`)"; trinity third member file = `GEMINI.md` (kept — Antigravity reads
  the GEMINI.md hierarchy); skills dir = `.agents/skills/`; project agents =
  plugin bundle `.agents-plugin/optiquity-agents/agents/`; global memory =
  `~/.gemini/GEMINI.md`; invocation = `./agent-run.sh agy --agent <name>`.
  This is the `cross-cli-reference-normalization` discipline — audience-correct
  canonical substitution, not byte-copy.
- **No pack-only reference introduced.** No `pack-ops/`, no `maintenance-docs/`,
  no `pack-*` agent name, no capitalized `Pack Chat` orchestrator role, no
  pack-self concept (BD numbers, pack BACKLOG) appears in any client doc. The
  `bd-pack-only-operational-rule` is honored — the only "BD-217" mentions are
  in HTML-comment forward-looking RE-VERIFY markers, which are impl-time
  coordination notes consistent with the plan's forward-looking register; they
  do not import a pack operational rule into client runtime content. (Note:
  these mirror the plan's own C4 register row verbatim. If Pack-Chat triage
  prefers zero BD-token in client docs, the comment can drop "BD-217
  coordination" and keep only the `antigravity.google/docs/*` re-verify
  pointer — flagged here for visibility, not a blocker.)
- **No Boundary-discipline STOP triggered** — no edit needed a pack-only
  target; the project-side trinity SSOT supplied every value.

---

## Plan deviations

Zero substantive deviations from plan §3 C4 + the A1 inventory carry-forward.

Notes (not deviations):
- Plan §3 C4 surface lists `PLATFORM-SKILLS.md (.gemini/skills/→.agents/skills/)`;
  the `pack-help` inventory-row addition is the **A1 carry-forward** named in
  the prompt (restores Check 31). Both done.
- The plan's C4 row also enumerates the prompt-file set
  `{pm-chat, auditor, coder, reviewer}` for "incidental cross-CLI refs" — all
  four converted (no others in scope had Gemini-CLI tokens).

---

## New POQs introduced

None. The `pack-help` cross-CLI classification resolved honestly (it is a
uniform canonical skill, not a per-CLI command) — no asymmetry POQ required.

One **visibility flag** (not a POQ, not a blocker): the forward-looking HTML
comments carry "BD-217 coordination" tokens, sourced verbatim from the plan's
C4 forward-looking register. If Pack-Chat triage wants client docs entirely
free of BD tokens, the coordination phrase can be dropped, keeping only the
`antigravity.google/docs/*` re-verify pointer. Surfaced for decision.

---

## Definition-of-Done checklist

| Item | Status | Evidence |
|---|---|---|
| Baseline captured (expect 10) | PASS | `{5,17,18,21,28,31,39,41,55,57}` (matches prompt) |
| Post-C4 = baseline MINUS Check 31 | PASS | `{5,17,18,21,28,39,41,55,57}` |
| Check 31 GREEN | PASS | "2 rows (header matches)" + "37 … all agree" + "no orphans/phantoms/double-counts" |
| Check 54 STAYS GREEN | PASS | "presence holds across 2 surface(s) … all 3 mandated tokens" |
| Check-54 token survival (10/6/4) | PASS | counts identical pre/post |
| Check-54 dedicated test | PASS | `test-validate-pack-check-54.sh` 3/0 |
| No new break introduced | PASS | post-set ⊂ baseline-set; only 31 removed |
| Header TEXT kept exact (singular "skill") | PASS | `### PM chat operational skill (2)` — only `(N)` bumped |
| Client docs converted Gemini→Antigravity | PASS | strict grep: 0 "Gemini CLI", 0 `.gemini/` path tokens (legit `GEMINI.md` + `~/.gemini/GEMINI.md` kept) |
| Forward-looking markers placed | PASS | OPTIONAL-FEATURES + PM-CHAT H2 markers + inline hedges |
| No pack-self leak (bd-pack-only) | PASS | no pack-ops/maintenance-docs/pack-* in client docs |
| project-only scope (no leak) | PASS | `git diff --name-only` = 7 files all under `project-template/docs/pack/` |
| Manifest deferred to C10 | PASS (by design) | scope guard + plan F3; no manifest entry for edited docs |
| No git state change | PASS | HEAD = `e8eb0a5` unchanged; `git status` shows only the 7 modified docs |

---

## Rules-Applied Verification Block

| Rule | Verification evidence (measured/quoted) | Conclusion |
|---|---|---|
| **agents-never-commit** | `git rev-parse HEAD` before and after = `e8eb0a5d2f061ac53c8c9ab66b10bd81c3dc37b4`; only read-only git verbs used (`rev-parse`, `status`, `diff`, `log`); `git status --short` shows 7 ` M` modified files, no staged/committed change. Read pristine state via `validate-pack.py` runs, not via mutating verbs. | COMPLIANT |
| **ci-guard-design-measure-then-bound** | Measured `_INVENTORY_SUBSECTIONS` (L3100), `_parse_inventory_subsection` (L3108), `check_skill_cell_consistency` (L3139) + disk-skill enumeration (37 dirs) + the orphan FAIL ("pack-help … not listed") BEFORE editing. Classified pack-help as a uniform canonical skill (KEEP → add to inventory), sized the bump to exactly the one orphan, verified post-fix Check 31 green. No fake; honest green. | COMPLIANT |
| **preflight-stop-means-stop** | Emitted ONE PREFLIGHT line only after all edits + verification passed (Check 31 green, Check 54 green, no new break, project-only scope). No parent stop/halt received. Efficient — avoided redundant re-reads (the prior attempt's stall was infra, not approach). | COMPLIANT |
| **edit-in-place-not-full-rewrite** | All 18 changes were targeted `Edit` calls (old_string→new_string) on existing files; zero full-file `Write` to any of the 7 source docs. Re-confirmed section maps via grep after edits (e.g. inventory headers 14/20/1/2; residual-gemini sweep). | COMPLIANT |
| **scope-deliverables-to-the-ask** | Implemented EXACTLY plan §3 C4 (7 files) + the A1 inventory row. No out-of-scope edits — `git diff --name-only` = the 7 named files only; no validate-pack.py / trinity / config / manifest / pack-self touched. | COMPLIANT |
| **verify-full-ci-suite** | Ran `python3 scripts/validate-pack.py` baseline + post-C4 (full battery, all 61 checks, no `--only-check`); parsed per-check (variant-aware); quoted both failing sets + delta; ran the integration-adjacent `test-validate-pack-check-54.sh` (3/0). Check 31 green + Check 54 green + no new break confirmed. | COMPLIANT |
| **rules-applied-verification-block** | This block — per-rule, quoted/measured evidence, COMPLIANT terminal state for each; no AMBIGUOUS; no empty evidence. | COMPLIANT |
| **cross-cli-reference-normalization** (trinity RC for `project-template/` cross-CLI refs) | Substituted audience-correct canonical values read from the C3-converted project trinity (`GEMINI.md` L6–8/L430–470/L487–493): CLI="Antigravity CLI (`agy`)", skills=`.agents/skills/`, agents=plugin bundle, memory=`~/.gemini/GEMINI.md`, invocation=`agy --agent`. NOT byte-identical cross-trinity copy. | COMPLIANT |
| **bd-pack-only-operational-rule** (no pack-self in client content) | Strict grep across the 7 files: 0 `pack-ops/`, 0 `maintenance-docs/`, 0 `pack-*` agent name, 0 capitalized `Pack Chat`. Only BD token is "BD-217" inside forward-looking HTML comments (impl coordination, flagged for triage). | COMPLIANT |
| **P-missed-7 boundary-investigation-precedes-pack-defaults** | For every project-side edit, investigated the project-side SSOT (C3 project trinity) first; copied its canonical values; introduced no pack-only mechanism. See "Boundary discipline check". | COMPLIANT |
