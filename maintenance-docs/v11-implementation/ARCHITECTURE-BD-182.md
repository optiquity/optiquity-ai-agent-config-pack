# ARCHITECTURE-BD-182 — Cross-CLI reference normalization across `project-template/` trinity

**Branch:** `v11-dev`
**Pre-architecture HEAD:** `8368e40ac7817d94bd6f022599d65b0b3ee41a8a`
**Date:** 2026-05-20
**Architect:** `pack-architect` (Claude Code v11-dev session)
**Status:** Strategy proposal — awaiting Pack Chat user-approval before `pack-coder` spawn

---

## §1 Problem restatement

BD-178 SHOULD-1 (commit `fa605a9`, IMPL-REPORT at
`maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-178-SHOULD-1.md`)
aligned `project-template/GEMINI.md` body text byte-identically to
`project-template/CLAUDE.md` for four sections (iOS 26 / Architecture /
Security / Scripts) per the CLAUDE-first canonicalization heuristic. That
correctly closed the UNRESOLVED-DRIFT classified by archived
`maintenance-docs/v11-implementation/ARCHITECTURE-BATCH-19B-STRATEGIC-PRINCIPLES.md`
§D.4 L432-436 — BUT, per IMPLEMENTATION-REPORT-BD-178-SHOULD-1.md §3.1
"Note on `.claude/settings.json` reference," it side-cased a different
concern: the CLAUDE-canonical iOS-26 bullet now reads

> override in `.claude/settings.json` env block if Xcode is installed elsewhere

in all three of `project-template/CLAUDE.md` (line 65),
`project-template/AGENTS.md` (line **65 absent — see §4 below**) and
`project-template/GEMINI.md` (line 61). A Gemini-CLI-running user reading
GEMINI.md gets a wrong settings-file path: their actual Xcode-override
location is `.gemini/.env`, NOT `.claude/settings.json`.

This is a **different class of issue** than body-text drift (which
BD-178 SHOULD-1 correctly addressed):

| Class | Same conceptual content? | Same correct value? | Correct fix |
|---|---|---|---|
| **Body-text drift** (BD-178 SHOULD-1 scope) | Yes | Yes (same value) | Align to canonical (CLAUDE-first) |
| **Cross-CLI reference** (BD-182 scope) | Yes | **No** — value differs per CLI | Per-CLI canonical divergence (Override 9 authorized) |

Per User Override 9 (codified in `maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md` §4.1 and
re-cited throughout that doc's V8 fixes): "different audience = different
wording; NO cross-trinity drift gate." Tool-specific references ARE
legitimate divergence — each trinity file should reference its OWN CLI's
settings paths, commands, hook mechanisms, and operating notes.

The same class likely recurs across `project-template/` trinity for ALL
references that vary per CLI. BACKLOG BD-182 enumerates probable categories
but the scope demands empirical (not memory-based) inventory.

---

## §2 Scope decision: pack-root trinity inclusion

**Decision: pack-root trinity is OUT of BD-182 scope.**

**Rationale (empirical):**

1. **No body-text-drift parent BD applied to pack-root.** BD-178 SHOULD-1
   touched `project-template/GEMINI.md` ONLY — pack-root trinity was
   confirmed untouched per IMPLEMENTATION-REPORT-BD-178-SHOULD-1.md §2
   "Files explicitly NOT modified … Pack-root trinity files (CLAUDE.md /
   AGENTS.md / GEMINI.md at repo root) — UNCHANGED."

2. **Pack-root trinity ALREADY carries per-CLI tool-specific divergence
   by design.** Empirical evidence:
   - Pack-root `CLAUDE.md` § "Pack memory" "Pack-coder PREFLIGHT +
     STOP-MEANS-STOP pattern" bullet documents Claude-Code-specific
     enforcement (SendMessage / Agent Teams / SECURITY WARNING
     classifier) and explicitly cross-references Codex / Gemini variants.
   - Pack-root `AGENTS.md` § "Pack memory" same bullet documents Codex-
     specific enforcement (`/agent` slash command; issue #12462 absence
     note) and cross-references Claude / Gemini variants.
   - Pack-root `GEMINI.md` § "Pack memory" same bullet documents Gemini-
     specific enforcement (natural-language directive; `Ctrl+C` issue
     #3385; hub-and-spoke; issues #21052 / #21409 / #14043 / #4323) and
     cross-references Claude / Codex variants.
   - Pack-root `AGENTS.md:309` and `pack-root GEMINI.md:276` literally
     contain the phrase "Claude Code's SECURITY WARNING" because the doc
     for the OTHER CLI's audience tells them what the Claude-side
     enforcement looks like — Override 9 already in active practice.
   - Pack-root `AGENTS.md:343-350` and pack-root `GEMINI.md:314-322`
     explicitly call out the Codex- and Gemini-side **absence** of
     per-project memory caches (the only Claude-Code-specific Pack Chat
     directly-edit surface), again per-CLI-specific content by design.

3. **Pack-root H2 set is intentionally MUCH smaller than project-template
   H2 set.** Pack-root H2s per `grep -n '^## '` per file:
   - Pack-root CLAUDE.md: 6 H2s (Quick reference / What this repo is /
     Repo structure / Rules for agents working on this repo / Pack memory
     (project-local learnings))
   - Pack-root AGENTS.md: same 6 H2s (Check 18 [pack-root] enforces)
   - Pack-root GEMINI.md: same 6 H2s + 1 Gemini-intrinsic (`## Gemini
     CLI operating notes`)
   - The "Rules" + "Pack memory" sections are where per-CLI divergence
     legitimately concentrates, and the existing content already does
     so deliberately.

4. **No equivalent empirical-trigger evidence at pack-root.** BD-178
   SHOULD-1's incident was that a project-template GEMINI.md user
   would read the wrong settings path. Pack-root trinity is read by
   **agents working on the pack repo itself** — they do not consume
   project-side `.claude/settings.json`/etc references; they consume
   pack-repo-operational instructions. No analogous user-impact
   incident has been reported, and the pack-root content already
   distinguishes per-CLI tooling per bullet 2.

5. **Symmetry consideration acknowledged.** BD-183 (already opened)
   extends Check 16 + Check 19 to pack-root trinity, mirroring BD-181's
   Check 18 pack-root extension. The pattern there is "if a parity
   guard applies at project-template, mechanically extend to pack-root."
   That pattern does NOT extend to BD-182 because (a) BD-182 is content-
   normalization, not parity-guard extension, and (b) pack-root content
   ALREADY does what BD-182 is enacting (per-CLI divergence by design),
   so there is nothing to normalize.

**Reviewer-pass note:** A subsequent reviewer can re-test pack-root scope
by running the §4 empirical inventory against pack-root trinity. If a
genuine cross-CLI tool-specific reference that contradicts pack-root's
own audience-conventions surfaces, file a follow-up BD; do NOT widen
BD-182 mid-flight.

---

## §3 Cross-CLI reference inventory (D1: empirical, per-file, evidence-cited)

Methodology: grep `project-template/{CLAUDE,AGENTS,GEMINI}.md` for the
union of patterns `\.claude/`, `\.codex/`, `\.gemini/`, `claude code`,
`codex cli`, `gemini cli`, `claude help`, `codex help`, `gemini help`,
`/agent`, `claude-code`, `@agent`, `settings\.json`, `config\.toml` (case-
insensitive), plus a manual sweep for `Xcode` / `PostToolUse` /
`post_edit_command` / `hook` / `save_memory` / `/chat` / `/compress` /
operating-notes-style mentions.

Each row is classified `TOOL-SPECIFIC` (per-CLI canonical value;
Override 9 carve-out applies) or `TOOL-NEUTRAL` (CLAUDE-first canonical
applies; same value across all three CLIs).

### §3.1 — Inventory table

For brevity, "C" = `project-template/CLAUDE.md`, "A" =
`project-template/AGENTS.md`, "G" = `project-template/GEMINI.md`. Symbol
references use the H2 section name, not line numbers (per pack convention).

| # | Reference | Files affected | Classification | Notes |
|---|---|---|---|---|
| R1 | `.claude/settings.json` env block (Xcode override) | C § `[CONDITIONAL] iOS 26 / Xcode 26.3 platform features`; G § same H2 (A § same H2 lacks the bullet — see §4) | **TOOL-SPECIFIC** | The empirical trigger for BD-182. Each CLI has its own env-var setting surface. |
| R2 | `.claude/skills/<name>/SKILL.md` (skill loading path) | C § `Skill loading` (`.claude/`); A § same H2 (`.codex/`); G § same H2 (`.gemini/`) | **TOOL-SPECIFIC** — ALREADY correctly diverged per CLI | Confirmed by inspection: C says `.claude/skills/`, A says `.codex/skills/`, G says `.gemini/skills/`. No edit needed. Audit-row only. |
| R3 | Three-CLI auto-distribution paragraph | All three § `Skill loading` "Tier 0 installation note" paragraph (`.claude/skills/`, `.codex/skills/`, `.gemini/skills/` enumerated together) | **TOOL-NEUTRAL** (enumeration of all three) — leave as-is | Each file enumerates all three CLI dot-dirs together because the Tier 0 distribution affects all three regardless of which CLI is reading the file. Correct per-document audience: an actor on any CLI benefits from knowing the full distribution. |
| R4 | `x-` custom-skill paths enumeration | All three § `Skill loading` `x-` paragraph (`.claude/skills/x-<name>/`, `.codex/skills/x-<name>/`, `.gemini/skills/x-<name>/`) | **TOOL-NEUTRAL** (enumeration of all three) — leave as-is | Same rationale as R3. |
| R5 | Agent definition path enumeration | All three § `Project memory` (`.claude/agents/<agent>.md`, `.codex/agents/<agent>.toml`, `.gemini/agents/<agent>.md`) | **TOOL-NEUTRAL** (enumeration of all three) — leave as-is | The paragraph names ALL three CLI agent locations because the universal collaboration rule references the per-agent operating-rules surface across the trinity. Correct per-document audience. |
| R6 | Phase-routing table "Default" column lists "Claude Code" / "Codex" tags | All three § `Phase routing — default agent assignments` table | **TOOL-NEUTRAL** — leave as-is | The defaults are inherent to the routing matrix; they identify the better system per phase regardless of which CLI is reading. Already byte-identical across trinity per Check 18. |
| R7 | "All three tools (Claude Code, Codex, Gemini CLI) can execute any phase" sentence | All three § `Phase routing — default agent assignments` opening paragraph | **TOOL-NEUTRAL** — leave as-is | Enumeration of all three; correct per any audience. |
| R8 | `./agent-run.sh <cli> --agent <name>` invocation example | All three § `Phase routing — default agent assignments` post-table paragraph | **TOOL-NEUTRAL** — leave as-is | The `agent-run.sh` script accepts a CLI arg (`claude` / `codex` / `gemini`); the example is universal. |
| R9 | "For Gemini CLI, `agent-run.sh` translates `--agent` to Gemini's native `@agent-name` syntax" sentence | All three § `Phase routing — default agent assignments` post-table paragraph | **TOOL-NEUTRAL** — leave as-is | The translation behavior is `agent-run.sh`'s contract; documenting it cross-CLI is correct per-audience. |
| R10 | `agent-post-edit-check.sh` row "fires automatically via Claude Code PostToolUse hook and Codex post_edit_command" | C § `Scripts` (current form: "Claude Code PostToolUse hook and Codex post_edit_command"); G § `Scripts` (same form after BD-178 SHOULD-1 alignment); A § `Scripts` (current form: "fires via Codex post_edit_command and Claude Code PostToolUse hook") | **DECISION POINT** — see §5 OQ-1 | A names Codex hook FIRST (Codex-audience-first); C/G name Claude FIRST. Could be (a) leave-as-is (per-audience-first ordering), (b) align all three to single canonical order, or (c) per-CLI mention only the audience's own CLI hook with parenthetical "and the other tools' equivalents." Substantive class similar to R1. |
| R11 | "GEMINI.md `## Gemini CLI operating notes`" H2 + body | G § `Gemini CLI operating notes` (single occurrence; this H2 doesn't exist in C/A by design — it's a Check 18 documented Gemini-intrinsic) | **TOOL-SPECIFIC** — by design; no edit | The H2 itself is part of the Check 18 allow-list (`GEMINI_INTRINSIC_H2S` in `scripts/validate-pack.py:check_trinity_h2_parity`). |
| R12 | GEMINI's `## Agent roster` H2 + body (Gemini-intrinsic auto-discovery aid) | G § `Agent roster` (single occurrence; the other Check 18 allow-list intrinsic) | **TOOL-SPECIFIC** — by design; no edit | Same Check 18 allow-list entry. |
| R13 | HOW-TO-USE preamble HTML comment: "This file is the X equivalent of Y" cross-reference | C preamble (lines 14-17); A preamble (lines 12-16); G preamble (lines 12-13) | **TOOL-NEUTRAL by present form** (each preamble already names its own CLI as the audience) — leave as-is | Each file's preamble already correctly identifies ITS OWN CLI; no edit needed. |
| R14 | `## Capability policy` opening sentence: "Claude may" / "Codex may" / "Gemini CLI may" | C: "Claude may perform"; A: "Codex may perform"; G: "Gemini CLI may perform" | **TOOL-SPECIFIC** — ALREADY correctly diverged per CLI | No edit needed. Audit-row only. |
| R15 | `## Quick reference` "or `/pack-help` in your CLI" sentence | All three § `Quick reference` (byte-identical) | **TOOL-NEUTRAL** — leave as-is | Phrase is correctly generic; "your CLI" resolves per-audience. |

### §3.2 — Inventory totals

| Class | Count | Action |
|---|---|---|
| TOOL-SPECIFIC requiring edit (R1) | 1 row × 1 file edit (G only — C / A correct per-audience already) | §6 D4 |
| TOOL-SPECIFIC decision-point (R10) | 1 row × variable | §5 OQ-1 |
| TOOL-SPECIFIC already-correct (R2, R14) | 2 rows × 0 edits | No-op (audit row) |
| TOOL-SPECIFIC by-design (R11, R12) | 2 rows × 0 edits | No-op |
| TOOL-NEUTRAL leave-as-is (R3, R4, R5, R6, R7, R8, R9, R13, R15) | 9 rows × 0 edits | No-op |

**Empirical conclusion:** the inventory is narrow. The BACKLOG framing
("the same issue likely exists across the trinity for ALL CLI-specific
references") OVER-states the actual scope; the empirical inventory finds
exactly one definite edit (R1 → GEMINI.md) plus one decision-point
(R10 across all three). The empirical reduction is meaningful: most
trinity content correctly mirrors all three CLIs by enumeration (R3 / R4
/ R5), or correctly diverges per CLI already (R2 / R14).


---

## §4 Per-CLI canonical reference table (D2)

The empirical-evidence per-CLI canonical values, derived from
`scripts/init-project.sh` stage S3 (`stage_s3_config_files` per file
manifest at lines 458-481, 1127-1136, 1278-1300), the actual contents
of `project-template/.{claude,codex,gemini}/`, and
`supporting-docs/INSTALL-PROCEDURES.md` § Procedure 5-C.5 lines 655-666.

### §4.1 — Per-CLI canonical reference table

| Concept | Claude Code canonical | Codex CLI canonical | Gemini CLI canonical | Evidence |
|---|---|---|---|---|
| Per-project agent definitions directory | `.claude/agents/<agent>.md` | `.codex/agents/<agent>.toml` | `.gemini/agents/<agent>.md` | `init-project.sh:402-403` (mkdir); `project-template/.{claude,codex,gemini}/agents/` (verified by `ls`) |
| Per-project skills directory | `.claude/skills/<name>/SKILL.md` | `.codex/skills/<name>/SKILL.md` | `.gemini/skills/<name>/SKILL.md` | `init-project.sh:402-403, 484+` (`stage_s4_skills()`); confirmed in `project-template/.{claude,codex,gemini}/skills/` |
| Per-project tool config file (settings / env / capabilities) | `.claude/settings.json` (JSON; `env` block) | `.codex/config.toml` (TOML; `[env]` table, or `[agent_capabilities]` for capability flags); optional `.codex/requirements.toml` | `.gemini/.env` (env vars) AND `.gemini/settings.json` (JSON; MCP config) | `init-project.sh:458-464, 478-481` (S3 file copies); `supporting-docs/INSTALL-PROCEDURES.md:625, 662-664`; `project-template/.{claude,codex,gemini}/` ls output (see §4.1.1 below) |
| Environment-variable override surface (e.g., `XCODE_APP`) | `.claude/settings.json` `env` block | `.codex/config.toml` `[env]` table (mirrored per BD-059 trinity rule) | `.gemini/.env` (key=value lines mirrored per BD-059 trinity rule) | `project-template/.codex/config.toml:19-20` ("mirrors `.claude/settings.json` env.AGENT_CAPABILITIES and `.gemini/.env` AGENT_CAPABILITIES per the BD-059 trinity rule") |
| Per-CLI slash-command or session-control surface | `/pack-help`, `pack help` (via the `pack-help` skill) | `/pack-help`, `pack help` (via the `pack-help` skill); `/agent` for sub-agent control | `/pack-help` (via the `.gemini/commands/pack-help.toml` slash command); `/chat save <tag>`, `/chat resume <tag>`, `/compress`, `save_memory` | `init-project.sh:857-881` (stage S11 per-CLI installs); `project-template/GEMINI.md:460-464` (Gemini-intrinsic operating notes) |
| Per-CLI custom-skill `x-` prefix path | `.claude/skills/x-<name>/SKILL.md` | `.codex/skills/x-<name>/SKILL.md` | `.gemini/skills/x-<name>/SKILL.md` | `project-template/{CLAUDE,AGENTS,GEMINI}.md` § Skill loading `x-` paragraph (already enumerates all three correctly per R4) |
| Per-CLI agent-invocation native surface | `/agent` (Claude Code Agent tool / Agent Teams) and `claude --agent <name>` (CLI subcommand spawn) | `codex --agent <name>` and `/agent` slash command | `@agent-name` (in interactive session) and `gemini` then `@agent-name`; or `agent-run.sh gemini --agent <name>` wrapper | Pack-root `CLAUDE.md` § Pack memory "Pack agent invocation" bullet (line 256 region); pack-root `AGENTS.md` § Pack memory (line 255-258); pack-root `GEMINI.md` § Pack memory (line 222-225); also `project-template/GEMINI.md:432-441` (Agent roster section, Gemini-intrinsic) |
| Per-CLI hook firing mechanism (post-edit / equivalent) | `PostToolUse` hook (Claude Code) | `post_edit_command` (Codex CLI) | (no documented equivalent; Gemini relies on explicit user invocation of `agent-post-edit-check.sh`, OR per-prompt instruction) | `project-template/{CLAUDE,AGENTS,GEMINI}.md:269/253/265` § Scripts → `agent-post-edit-check.sh` row; `init-project.sh` post-edit-check copy; `supporting-docs/INSTALL-PROCEDURES.md` (verify pre-implementation per §5 OQ-1) |
| Per-CLI memory-cache surface (pack-shipped) | `~/.claude/projects/<slug>/memory/*.md` (Pack Chat operating state, per pack-root `CLAUDE.md:382-383`) | NONE (Codex memories are opt-in + regionally restricted + opaque per pack-root `AGENTS.md:344-349`; pack does not ship a Codex memory file) | NONE (Gemini's "memory" IS the `GEMINI.md` hierarchy itself; pack-root `GEMINI.md:314-319` confirms no separate generated state) | Pack-root trinity § Pack memory "What Pack Chat CAN edit directly" bullet across all three files |

### §4.1.1 — Empirical inventory of `project-template/.{claude,codex,gemini}/` (verified by `ls`)

```
project-template/.claude/:
  agents/, settings.json, settings.local.example.json, skills/

project-template/.codex/:
  agents/, config.toml, config.toml.example, requirements.toml, skills/

project-template/.gemini/:
  agents/, commands/, settings.json
  (.env is GENERATED from .env.example at stage S3 — see init-project.sh:451)
```

### §4.2 — Source for any cell marked uncertain

All cells in the table are sourced from in-repo evidence (file inventory,
script logic, or pack-root canonical trinity documentation). No external
documentation lookup was performed. The only cell with mild uncertainty
is the "Per-CLI hook firing mechanism" row for Gemini — Gemini's
documented hook mechanism (if any) is not surfaced in the in-repo
evidence, and the empirical state per `project-template/{CLAUDE,AGENTS,
GEMINI}.md` is silence. §5 OQ-1 surfaces this.

---

## §5 Decision criteria: TOOL-SPECIFIC vs TOOL-NEUTRAL (D3)

A reference is **TOOL-SPECIFIC** (per-CLI canonical value applies;
Override 9 carve-out authorizes divergence) when ALL THREE of:

1. **Concept varies per CLI.** The underlying mechanism (file path,
   command syntax, hook name, session-control verb) has a different
   correct value for each of the three CLIs per the §4.1 canonical
   table. NOT "could be different" — IS different per established
   empirical canonical.
2. **Single-audience read context.** A user reading the file is on
   ONE specific CLI (Claude Code reads CLAUDE.md; Codex reads AGENTS.md;
   Gemini reads GEMINI.md). They want THEIR CLI's correct value, not a
   menu of all three.
3. **Operational impact when wrong.** If the user follows the printed
   reference and the path/command/hook is wrong for their CLI, they
   will hit a real error (file not found, command not recognized, hook
   never fires). The reference is load-bearing, not informational.

A reference is **TOOL-NEUTRAL** (CLAUDE-first canonical, byte-identical
across trinity) when ANY of:

1. **Enumeration of all three.** The reference INTENTIONALLY names all
   three CLI paths/commands together because the rule applies across
   the trinity (R3 / R4 / R5 examples). Reading audience benefits from
   the full enumeration regardless of which CLI they are on.
2. **Universal concept.** The reference is a project-level concept that
   is the same regardless of CLI (e.g., `pack help` is the universal
   pack-command verb; `agent-run.sh <cli>` is the universal launcher
   with a CLI arg; the phase-routing-defaults table identifies the
   better system per phase regardless of caller-CLI).
3. **Generic placeholder.** Phrases like "your CLI" / "your tool" /
   "the CLI you're using" intentionally avoid naming a specific CLI
   because per-audience resolution happens at read time.

### §5.1 — Worked examples

**Worked example 1 (TOOL-SPECIFIC):** R1 — `.claude/settings.json` env
block. Concept: per-CLI environment-variable override surface. Per §5
criteria: (1) varies per CLI (Claude: `.claude/settings.json` env;
Codex: `.codex/config.toml` `[env]`; Gemini: `.gemini/.env`); (2)
single-audience read context (a Gemini user is the one consulting
GEMINI.md for the override); (3) operational impact (a Gemini user
writing to `.claude/settings.json` produces no effect for Gemini —
silent functional failure). → TOOL-SPECIFIC; per-CLI canonical value
applies; GEMINI.md needs `.gemini/.env`; AGENTS.md needs `.codex/config.toml`
`[env]` table.

**Worked example 2 (TOOL-NEUTRAL):** R3 — the Tier 0 installation
note's `.claude/skills/`, `.codex/skills/`, `.gemini/skills/` triple.
Per §5 criteria: this is an enumeration of all three (criterion N1).
The reason is that `stage_s4_skills()` distributes Tier 0 skills to ALL
THREE per-CLI skill directories at once, regardless of which CLI is
reading the doc. A reader on any CLI benefits from knowing the full
distribution. → TOOL-NEUTRAL; leave byte-identical across trinity.

**Worked example 3 (DECISION-POINT):** R10 — `agent-post-edit-check.sh`
row "fires via … PostToolUse hook and Codex post_edit_command." Concept:
which CLI's hook fires the post-edit-check. Per §5 criteria:
(1) HALF-meets criterion S1 — Claude has PostToolUse, Codex has
post_edit_command; Gemini has no documented equivalent and the script
must be invoked some other way; (2) single-audience reads (a Codex user
wants to know post_edit_command fires it; a Gemini user wants to know
HOW IT FIRES FOR THEM — and the doc is currently silent for Gemini even
in GEMINI.md after BD-178 SHOULD-1 byte-identicalized to CLAUDE form);
(3) operational impact is LOW because the user isn't asked to invoke the
script themselves (it's `**Never call manually**`), so a slightly wrong
attribution doesn't break functionality. Net: it COULD be normalized
per-CLI for clarity, BUT the cross-CLI enumeration form is also
defensible because the script IS configured to fire from multiple CLIs
in any project install. **Surface as OQ-1 to user.**

---


## §6 Trinity edit plan (D4: mechanical for pack-coder)

Each row below names the file, the H2 section anchor, the BEFORE text
(verbatim quoted from current HEAD `8368e40`), and the AFTER text. Edits
are mechanical — pack-coder applies them without design judgment.

### §6.1 — R1 edit: `.claude/settings.json` env block (Xcode override)

**Files affected:** `project-template/AGENTS.md`, `project-template/GEMINI.md`
(NOT `project-template/CLAUDE.md` — CLAUDE.md is the canonical-correct
form for its own audience).

#### §6.1.1 — `project-template/CLAUDE.md` § `[CONDITIONAL] iOS 26 / Xcode 26.3 platform features`

**Action:** NO EDIT. Current form is correct for Claude-audience:

```
- For implementation details on any iOS 26 API, the `docs-researcher` agent reads directly from the Xcode documentation bundle at `$XCODE_APP/Contents/PlugIns/IDEIntelligenceChat.framework/Versions/A/Resources/AdditionalDocumentation/` (where `$XCODE_APP` defaults to `/Applications/Xcode.app` — override in `.claude/settings.json` env block if Xcode is installed elsewhere). If the path does not exist, fall back to web search.
```

#### §6.1.2 — `project-template/AGENTS.md` § `[CONDITIONAL] iOS 26 / Xcode 26.3 platform features`

**Current form (CONCISE per AGENTS-conciseness contract preamble L13-17;
LACKS the env-override clause entirely):**

```
- For iOS 26 API details, read directly from the Xcode documentation bundle at `/Applications/Xcode.app/Contents/PlugIns/IDEIntelligenceChat.framework/Versions/A/Resources/AdditionalDocumentation/`. If the path does not exist, fall back to web search.
```

**Action:** **NO EDIT — see §6.1.2.1 below.** The AGENTS.md form
intentionally lacks the env-var indirection (per the AGENTS-conciseness
contract documented in `project-template/AGENTS.md:13-17`: "bodies may
be more concise here, since the loaded skills carry the full detail").
The current AGENTS.md form hardcodes the default `/Applications/Xcode.app`
path with no override mechanism. Per pack memory General canonicalization
heuristic (CLAUDE-first), the alternative-fix-shape would be to expand
AGENTS.md to the full CLAUDE-form with `.codex/config.toml [env]` table
substituted — but that would (a) violate the AGENTS-conciseness contract
explicitly documented in the file's preamble, and (b) introduce a new
edit-shape not directed by BD-182's empirical trigger.

##### §6.1.2.1 — Surface as **OQ-2** to user

Two viable shapes for AGENTS.md:
- **Shape A** (no edit, retain current concise form): preserves AGENTS-
  conciseness contract; means Codex users get hardcoded
  `/Applications/Xcode.app` with no documented override; downstream
  Codex-user-on-non-standard-Xcode-install must consult CLAUDE.md or
  GEMINI.md for the env-var mechanism, or read `.codex/config.toml`
  themselves. Operationally the override STILL works (it's based on the
  `$XCODE_APP` env var which any CLI honors if set at process level);
  AGENTS.md just doesn't document it.
- **Shape B** (expand AGENTS.md to match CLAUDE-form structure, with
  per-CLI canonical substitution): violates the AGENTS-conciseness
  contract; produces a fuller AGENTS.md bullet documenting `.codex/config.toml
  [env]` table as the override surface. Architectural correctness wins;
  contract-compliance loses.

→ See §13 OQ-2.

#### §6.1.3 — `project-template/GEMINI.md` § `[CONDITIONAL] iOS 26 / Xcode 26.3 platform features`

**Current form (byte-identical to CLAUDE form per BD-178 SHOULD-1):**

```
- For implementation details on any iOS 26 API, the `docs-researcher` agent reads directly from the Xcode documentation bundle at `$XCODE_APP/Contents/PlugIns/IDEIntelligenceChat.framework/Versions/A/Resources/AdditionalDocumentation/` (where `$XCODE_APP` defaults to `/Applications/Xcode.app` — override in `.claude/settings.json` env block if Xcode is installed elsewhere). If the path does not exist, fall back to web search.
```

**Required AFTER form** (substitute Gemini-canonical override surface):

```
- For implementation details on any iOS 26 API, the `docs-researcher` agent reads directly from the Xcode documentation bundle at `$XCODE_APP/Contents/PlugIns/IDEIntelligenceChat.framework/Versions/A/Resources/AdditionalDocumentation/` (where `$XCODE_APP` defaults to `/Applications/Xcode.app` — override in `.gemini/.env` if Xcode is installed elsewhere). If the path does not exist, fall back to web search.
```

**Diff (substantive change):** `.claude/settings.json env block` →
`.gemini/.env`.

**Rationale:** Per §4.1 canonical table, Gemini's env-variable override
surface is `.gemini/.env` (not `.gemini/settings.json` — the latter is
the MCP-tool config; `.env` is the env-var surface, per
`project-template/.codex/config.toml:20` "mirrors `.claude/settings.json`
env.AGENT_CAPABILITIES and `.gemini/.env` AGENT_CAPABILITIES per the
BD-059 trinity rule"). A Gemini user setting `XCODE_APP` for non-standard
Xcode location adds `XCODE_APP=/path/to/Xcode.app` to `.gemini/.env`.

**Mechanical edit instruction for pack-coder:** in
`project-template/GEMINI.md`, locate the H2 `## [CONDITIONAL] iOS 26 /
Xcode 26.3 platform features` and within the bullet starting "For
implementation details on any iOS 26 API," replace the substring `\`.claude/settings.json\` env block` with `\`.gemini/.env\``. Single-line
single-substring replacement.

### §6.2 — R10 edit: `agent-post-edit-check.sh` row hook firing attribution

→ See §13 OQ-1. Architect recommendation: leave-as-is at this BD (NO
EDIT, audit row only), surface to user as OQ-1 in case user prefers
shape (b) or (c). Pack-coder should NOT touch this row absent user
direction.

### §6.3 — All other inventory rows: NO EDIT

Per §3.1 inventory: R2, R3, R4, R5, R6, R7, R8, R9, R11, R12, R13, R14,
R15 are no-op. The BD-182 trinity-edit-plan thus has exactly ONE
mechanical edit (R1 in GEMINI.md) PLUS the OQ-1 decision (R10) PLUS the
OQ-2 decision (AGENTS.md R1 shape).

### §6.4 — Summary of mechanical edits (post-OQ resolution)

| If user chooses … | GEMINI.md edits | AGENTS.md edits | CLAUDE.md edits |
|---|---|---|---|
| OQ-1 (a) "leave R10 as-is" + OQ-2 Shape A | 1 (R1) | 0 | 0 |
| OQ-1 (a) + OQ-2 Shape B | 1 (R1) | 1 (R1 expand) | 0 |
| OQ-1 (b) "align all three to single canonical R10 order" + OQ-2 Shape A | 1 (R1) + 1 (R10) | 1 (R10) | 1 (R10) |
| OQ-1 (b) + OQ-2 Shape B | 1 (R1) + 1 (R10) | 1 (R1 expand) + 1 (R10) | 1 (R10) |
| OQ-1 (c) "per-CLI mention own-CLI hook with parenthetical" + OQ-2 Shape A | 1 (R1) + 1 (R10) | 1 (R10) | 1 (R10) |
| OQ-1 (c) + OQ-2 Shape B | 1 (R1) + 1 (R10) | 1 (R1 expand) + 1 (R10) | 1 (R10) |

Maximum edit count across all OQ-resolution combinations: **6 single-
line edits across 3 files** (worst case OQ-1 (c) + Shape B). Minimum
edit count: **1 single-line edit in 1 file** (architect-recommended
OQ-1 (a) + Shape A). All edits are mechanical (no design judgment
required by pack-coder once OQs are resolved).

---

## §7 Install-time path-adjustment audit (D5)

**Empirical question:** does `scripts/init-project.sh` perform per-CLI
substitutions on trinity files when copying from `project-template/` to
client install?

**Answer: NO.** Evidence:

1. `scripts/init-project.sh:1127-1129` (file manifest for trinity copy):
   ```
   "project-template/CLAUDE.md:CLAUDE.md:trinity"
   "project-template/AGENTS.md:AGENTS.md:trinity"
   "project-template/GEMINI.md:GEMINI.md:trinity"
   ```
   The manifest entries are byte-copies (source:dest:kind). No `sed`
   transformation hook is registered for the `trinity` kind.

2. The actual copy mechanism is `cp_fn` (the `copy_fn` variable per
   `init-project.sh:858+`). All trinity copy operations across stages
   S7 (`stage_s7_trinity`) and the cmd_update path (`stage_s1+` glob
   walks) use byte-identical `cp`-equivalent.

3. No `sed`-rewriting or template-variable substitution functions exist
   for the trinity files in `init-project.sh`. (Confirmed by grep
   `'sed\|substitut\|template_var\|\$\$'` against the file — only
   placeholder-style markers like `[PROJECT_NAME]` are left for the PM
   chat to fill in manually post-install per
   `project-template/CLAUDE.md:9-12` "Fill in [PROJECT_NAME]…".)

**Conclusion:** trinity files arrive at client install byte-identical
to `project-template/`. The per-CLI canonical values BD-182 establishes
must therefore live in the pack-source-of-truth `project-template/`
trinity itself, NOT in install-time substitution logic. This is exactly
how Override 9 is designed to work: per-CLI divergence lives in the
source files, by audience.

**Consequence for BD-182 scope:** install-time substitution is OUT of
BD-182 scope. The trinity-edit plan in §6 is the entire surface; no
script changes required.

**Carry-forward check:** the "BD-182 should also add install-time
substitution" framing would be a CARRY-FORWARD violation per
`.claude/skills/review/SKILL.md` § Carry-forward discipline. It fails
the SIZE test (no architect-pass design surface is open), it fails the
BLOCKED test (no dependency artifact), and it fails the LOGICAL-FIT
test (substitution would be a fundamentally different design from
per-source-file divergence, not a same-contract-fit). Drop.

---

## §8 Check 18 / new-check decision (D6)

**Empirical context:** Check 18 (`check_trinity_h2_parity` in
`scripts/validate-pack.py`) enforces H2-skeleton parity within each
trinity location independently per BD-181 (Override 9 compliance per
docstring lines 1349-1354). It does NOT scan body text; BD-181 + the
Override 9 paragraph in the docstring explicitly carve out body-text
divergence as out-of-scope.

**Question:** does BD-182's tool-specific reference work need a CI
guard?

### §8.1 — Three options

**(a) NO new check; rely on Override 9 + reviewer attention.**
The per-CLI canonical reference table in §4.1 is the documentary record.
Future trinity edits that touch the same references must consult §4.1
(via a pointer in pack-root `CLAUDE.md` § Pack memory or a memory pointer)
and apply the per-CLI substitution mechanically.

- Pro: minimal CI surface; no new test fixtures; consistent with Override
  9 principle that explicitly forbids cross-trinity drift gates on body
  text.
- Con: pure reviewer-attention dependence; the carry-forward discipline
  warns against this in the review-skill.

**(b) NEW check enforcing per-CLI canonical reference table values.**
Add a new validate-pack.py check that scans `project-template/{CLAUDE,
AGENTS,GEMINI}.md` for the union of `.claude/`, `.codex/`, `.gemini/`,
`settings.json`, `config.toml`, `.env` patterns. For each match, verify
the surrounding context indicates audience-correct canonical (e.g.,
CLAUDE.md may NOT contain `.gemini/.env` outside an enumeration context;
GEMINI.md may NOT contain `.claude/settings.json` outside an enumeration
context).

- Pro: mechanical CI guard against the exact BD-182 incident class.
- Con: regex-context-distinguishing is fragile (enumeration paragraphs
  like R3 / R4 / R5 legitimately contain ALL THREE paths; the check
  must NOT false-positive there). The "enumeration vs single-reference"
  distinction is hard to mechanize without a long allowlist that drifts.
  Check 18-style false-negative is also possible (a per-CLI substitution
  that's wrong-for-its-audience would still match the audience's grep
  pattern). Architecturally, this is a "complex check guarding
  documentation prose" — out of pattern with the simpler structural
  checks 16/18/19.

**(c) EXTEND Check 18 to include a structured comment scanner.**
Modify Check 18 to additionally verify presence of an audience-conformance
comment at the top of each trinity file (e.g., `<!-- AUDIENCE: claude -->`).
The presence/absence of the comment is mechanical; the check just verifies
each file declares its audience and that audience matches the filename.

- Pro: cheap; mechanical; integrates with existing Check 18.
- Con: doesn't catch the actual BD-182 incident class. The comment just
  says "this is the CLAUDE file"; it doesn't verify the BODY references
  the correct CLI's paths.

### §8.2 — Architect recommendation

**Option (a) — NO new check.** Rationale:

1. **Empirical scope is narrow** (per §3.2: 1 definite edit + 2
   decision-points). The class of issue is genuinely small; the
   reviewer-attention failure mode is correspondingly low-probability.
   Investing CI surface to guard against a recurrence that requires the
   exact same review-skill failure as BD-178 SHOULD-1 (canonicalizing
   by byte-identity without per-audience awareness) is over-engineering.

2. **Memory-pointer codification suffices.** The §4.1 canonical reference
   table can be referenced from pack-root `CLAUDE.md` § Pack memory in
   a one-line bullet: "Cross-CLI reference normalization — when editing
   `project-template/` trinity references to per-CLI paths/commands,
   consult `ARCHITECTURE-BD-182.md` §4.1 canonical table; per-CLI
   divergence is Override 9-authorized." Future actors will surface the
   table on read; this is the same pattern used for `architect-doc-vs-
   reality reconciliation` and `regenerate-test-fixtures-manifest`.

3. **Carry-forward discipline applied.** The reviewer-attention concern
   is forward-looking conjecture (a forbidden carry-forward shape per
   `.claude/skills/review/SKILL.md` § Carry-forward discipline). Without
   concrete evidence of a CURRENT defect (which BD-182's trinity-edit
   plan resolves), surfacing a "this could drift again" finding fails
   the in-scope-finding bar.

4. **Pack memory entry is the architecturally-aligned fix.** The
   §4.1 table belongs in a place where pack-coder agents will read it
   when modifying trinity references. The natural location is a Pack
   memory bullet in pack-root `CLAUDE.md` (trinity rule applies to
   AGENTS.md + GEMINI.md as well — see §6.5 below).

→ Architect recommends option (a). Surface as **OQ-3** if user prefers
(b) or (c).

### §8.3 — Pack memory bullet draft (if option (a) chosen)

A draft bullet for pack-root trinity § Pack memory (subject to user
approval at §13 OQ-3):

> **Cross-CLI reference normalization in `project-template/` trinity.**
> When editing references to per-CLI paths or commands in
> `project-template/{CLAUDE,AGENTS,GEMINI}.md`, substitute the
> audience-correct canonical value per `maintenance-docs/v11-
> implementation/ARCHITECTURE-BD-182.md` §4.1 canonical reference
> table. Per Override 9, byte-identical cross-trinity adoption of
> CLI-specific paths is WRONG even when it visually closes drift —
> body-text drift and cross-CLI references are different classes
> (see ARCHITECTURE-BD-182.md §1 table). Worked example: BD-178
> SHOULD-1 byte-identically aligned GEMINI.md's `.claude/settings.json`
> reference (correct for CLAUDE form, wrong for Gemini-audience);
> BD-182 corrected to `.gemini/.env` per §4.1.

This bullet would be added to all three pack-root trinity files (per
the pack-side trinity rule). Per pack memory pack-architect-spawn
protocol, the bullet itself becomes a directed mechanical edit for
pack-coder (added under § Repo conventions or § Workflow — Pack Chat
to direct the exact insertion point).

### §8.4 — Note on BD-183 relationship

BD-183 extends Check 16 + Check 19 to pack-root trinity. BD-183 is
NOT related to BD-182's "should there be a new check?" question — BD-183
is a parity-guard-extension (existing checks at additional locations),
not a new-class-of-check. The two BDs are independent design surfaces.

---


## §9 RC9 manifest implications (D7)

`project-template/` is in the v11-surface trigger glob (pack-root
`CLAUDE.md` § Repo conventions "Regenerate test-fixtures/manifest.txt
on every v11-surface commit" bullet, lines 471-535). Per the bullet,
ANY commit whose diff touches `project-template/**` MUST regenerate
`test-fixtures/manifest.txt` and stage it alongside the scope edits in
the same commit.

### §9.1 — Expected manifest drift per OQ-resolution combination

All BD-182 OQ-resolution combinations touch `project-template/`
trinity files (at least `project-template/GEMINI.md` for the R1 edit).
Expected manifest drift:

- **v11-realistic-ot, v11-flat-file, v11-tracker-on rows DRIFT.** All
  three v11-* fixtures include project-template trinity per
  `test-fixtures/README.md` § Determinism.
- **v10-minimal, v10-realistic-ot rows UNCHANGED.** Tag-pinned per the
  README; only drift if the v10 tag moves, which is not in BD-182 scope.
- **existing-project-mid-dev row UNCHANGED.** Pre-pack-install
  synthetic; no trinity present.

This matches the BD-178 SHOULD-1 IMPL-REPORT §6 evidence pattern
(3 v11-* SHAs drift; 2 v10-* + 1 existing-* unchanged).

### §9.2 — Staging plan

Pack-coder PREFLIGHT runs `bash test-fixtures/build.sh --all --clean`
after all R1 (+ R10 / R1-expand if OQ-resolutions add them) edits land.
Pack-coder reports manifest diff in IMPL-REPORT §6 (matching BD-178
SHOULD-1 §6 format). Pack Chat stages the manifest alongside the
trinity edits + IMPL-REPORT + (if option (a) chosen) the pack-root
trinity Pack-memory bullet additions, then commits.

### §9.3 — Commit-scope keyword

Per pack-root `CLAUDE.md` § Rules → commit-subject scope-keyword
convention:

- If OQ-resolutions land ONLY trinity-file edits (no pack-root trinity
  Pack-memory bullet for option (a)): scope is `project-template/` only,
  which is per PM-only keyword `Permitted touched paths` (PM-only
  PERMITS `project-template/` trinity). Keyword: `PM-only` viable.
- If pack-root trinity Pack-memory bullet is added (option (a) chosen)
  AND scripts/test-fixtures/* outside `project-template/` are touched:
  scope is mixed (pack-root trinity + project-template trinity +
  test-fixtures); use NO keyword (Check 36 skipped).
- The conservative default is NO keyword. Pack Chat selects at commit
  time after seeing the final diff.

---

## §10 Override 9 compliance proof (D8)

### §10.1 — Trinity rule "symmetry by default" preserved

The trinity rule (pack-root `CLAUDE.md:107-112` and `project-template/
CLAUDE.md:361-364`) requires "When modifying CLAUDE.md, AGENTS.md, or
GEMINI.md, the same change applies to all three in the same set of
edits. Symmetry is the default; asymmetry requires justification as
provably tool-specific."

BD-182's edits PRESERVE H2-skeleton parity (Check 18 continues to pass
post-edit because §6 edits are body-content-only, not H2-skeleton).
The "asymmetry requires justification" half is met by §4.1 + §5
(per-CLI canonical reference table + decision criteria are the
documentary justification per Override 9's "different audience =
different wording").

### §10.2 — Check 18 [project-template] expected behavior

Pre-BD-182 Check 18 [project-template] result: PASS (per
IMPLEMENTATION-REPORT-BD-178-SHOULD-1.md §7.1 "all 39 checks PASS").
Post-BD-182 Check 18 [project-template] expected result: STILL PASS.
Reason: Check 18 inspects H2 names + order only; body-text edits in §6
do not affect H2 structure.

### §10.3 — Check 18 [pack-root] expected behavior

Pre-BD-182 Check 18 [pack-root] result: PASS (per BD-181 PRECONDITION
report). Post-BD-182 Check 18 [pack-root] expected result: STILL PASS
even if option (a) is chosen and a Pack-memory bullet is added to all
three pack-root trinity files (the bullet is added to existing § Pack
memory; no new H2 introduced). If OQ-3 (a) is chosen but Pack Chat
elects to NOT add a pack-root Pack-memory bullet (a viable user-choice
sub-option of option (a)), Check 18 [pack-root] still passes (no edit).

### §10.4 — Override 9 explicit citation

The §1 problem-restatement table, §4.1 canonical reference table, §5
decision criteria, and §8.3 draft pack-memory bullet ALL explicitly cite
Override 9 as the authority for per-CLI divergence. This satisfies
the `ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md` §4.1 fix-shape
requirement (explicit Override 9 citation prevents reviewer
mis-interpretation that BD-182 is creating drift; it is enacting
authorized per-CLI divergence).

---

## §11 Implementation sequence (D9)

The pack-coder spawn applies the following sequence mechanically once
OQ-1 / OQ-2 / OQ-3 resolutions are user-approved.

### §11.1 — Pre-flight (pack-coder)

1. `git rev-parse HEAD` → record SHA in IMPL-REPORT §11
2. `git status --short` → confirm clean working tree (only this
   ARCHITECTURE-BD-182.md doc + PACK-REVIEW-BD-181.md untracked, no
   modified files)
3. Read this strategy doc end-to-end
4. Read user-approved OQ resolutions (OQ-1 / OQ-2 / OQ-3 user choices)

### §11.2 — Edit application (mechanical)

5. Apply R1 edit to `project-template/GEMINI.md` per §6.1.3
   (single-line single-substring substitution)
6. If OQ-2 Shape B chosen: apply R1 expansion to
   `project-template/AGENTS.md` per §6.1.2.1 Shape B
7. If OQ-1 (b) or (c) chosen: apply R10 edits to all three trinity
   files per §6.2 details (drafted by pack-coder based on user-chosen
   shape)
8. If OQ-3 (a) chosen AND user approves the Pack-memory bullet:
   apply the §8.3 draft bullet to all three pack-root trinity files
   (pack-root `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`) at an insertion
   point Pack Chat directs (typically end of § Repo conventions)
9. If OQ-3 (b) or (c) chosen: requires pack-architect re-spawn or
   pack-planner spawn to design the new check — NOT in this BD's
   pack-coder scope; surface back to Pack Chat for re-routing

### §11.3 — Verification (pack-coder)

10. `python3 scripts/validate-pack.py` → expect exit 0 (all 40 checks
    PASS post-BD-181; Check 18 [project-template] and Check 18 [pack-root]
    both PASS); record output in IMPL-REPORT §7
11. `bash scripts/persona-contracts/contract-greenfield.sh` → expect 191/191
12. `bash scripts/persona-contracts/contract-mid-dev.sh` → expect 25/25
13. `bash scripts/persona-contracts/contract-migration.sh` → expect 37/37
14. Within-trinity diff verification for R1 (per §6.1.3): after edit,
    verify GEMINI.md iOS-26-bullet substring is `.gemini/.env` (not
    `.claude/settings.json`) by grep; record evidence in IMPL-REPORT §5
15. `bash test-fixtures/build.sh --all --clean` → regen manifest;
    record `git diff test-fixtures/manifest.txt` output in IMPL-REPORT §6

### §11.4 — PREFLIGHT line + IMPL-REPORT write

16. Emit PREFLIGHT line (verbatim format per pack memory):
    `PREFLIGHT: N/N in-scope file edits complete; verification PASS;
    HEAD <SHA>; about to Write IMPL-REPORT to
    maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-182.md`
17. Write IMPL-REPORT mirroring the BD-178 SHOULD-1 report's section
    structure (§1-§12). Chunk Writes if > 300 lines.

### §11.5 — Commit shape (Pack Chat, NOT pack-coder)

After pack-coder IMPL-REPORT and Pack Chat triage + user approval:

- Stage trinity edits + manifest + IMPL-REPORT + (option (a) chosen)
  pack-root Pack-memory bullet
- Commit subject: `fix: v11 — BD-182 normalize cross-CLI references in
  project-template trinity per Override 9 (Batch BD-175)` (or
  Pack-Chat-equivalent shape; pack memory approved-suffixes list permits
  per-BD inline fix in current batch).
- Commit-scope keyword decision per §9.3 (default: NO keyword unless
  Pack Chat confirms project-template-only scope including the
  Pack-memory bullet decision).

---

## §12 BD-182 vs adjacent BDs (relationship matrix)

| BD | Relationship | Notes |
|---|---|---|
| BD-178 (parent — SHOULD-1) | BD-182 closes the side-case that SHOULD-1 surfaced | The same trinity file (GEMINI.md) is the primary edit target; the byte-identical-to-CLAUDE pattern from SHOULD-1 is the precise mechanism BD-182 corrects for CLI-specific references. |
| BD-181 | Independent (parity-guard generalization for Check 18) | BD-181's Check 18 [project-template] + [pack-root] invocations continue to pass post-BD-182 (per §10.2 + §10.3). |
| BD-183 | Independent (Check 16 + Check 19 pack-root parity-guard extension) | BD-183's mechanical-extension pattern does NOT apply to BD-182 (per §2.5 scope-decision rationale). |
| BD-119 (migrator framework) | Unrelated | Trinity edits do not affect the migrator-core adapter contract. |
| BD-115 (CI release-gate manifest verify) | Indirectly related | RC9 manifest regen per §9 satisfies the BD-115 release-gate item 5. |

---

## §13 Open Questions for Pack Chat user-approval

Per pack memory pack-architect-spawn protocol, these OQs MUST be
surfaced to the user before pack-coder is spawned. Each OQ presents
options + an architect recommendation per `feedback-no-solutions-in-
agent-prompts` (this is an architect strategy doc, not an agent prompt
— recommendations are permitted and useful here per pack memory
`feedback-triage-workflow-protocol` "evidence-based recommendations
allowed").

All OQs are evaluated against the §13.4 carry-forward discipline.

### §13.1 — OQ-1 (R10 — `agent-post-edit-check.sh` hook firing attribution)

**Context:** §3.1 R10 + §5.1 worked example 3. Current state: CLAUDE.md
and GEMINI.md (post-BD-178 SHOULD-1) read "fires automatically via
Claude Code PostToolUse hook and Codex post_edit_command after every
agent file edit"; AGENTS.md reads "fires via Codex post_edit_command
and Claude Code PostToolUse hook" (Codex first, no "automatically", no
"after every agent file edit" tail).

**Options:**

- **(a) NO EDIT.** Accept the existing minor divergence (AGENTS-conciseness
  + ordering reflects AGENTS-audience-first; CLAUDE/GEMINI byte-identical
  per BD-178 SHOULD-1). Operationally low-impact (the script is "Never
  call manually" per the **Note** in the cell, so attribution is
  informational only).
- **(b) Align all three to a single canonical R10 form (CLAUDE-first
  byte identical).** Substitute AGENTS.md's R10 row with the CLAUDE
  form ("fires automatically via Claude Code PostToolUse hook and
  Codex post_edit_command after every agent file edit"). This violates
  the AGENTS-conciseness contract (preamble L13-17) — a fresh
  Architecture concern that BD-178 SHOULD-1 explicitly preserved.
- **(c) Per-CLI mention own-CLI's hook ONLY, with cross-CLI
  parenthetical.** CLAUDE.md: "fires automatically via Claude Code
  PostToolUse hook (and Codex `post_edit_command` for that CLI; no
  Gemini equivalent)"; AGENTS.md: "fires via Codex `post_edit_command`
  (and Claude PostToolUse for that CLI; no Gemini equivalent)";
  GEMINI.md: "fires automatically only when explicitly wired
  (no native hook; rely on per-prompt invocation or PostToolUse /
  post_edit_command in other CLIs)."

**Architect recommendation: (a).** Rationale: (1) operational impact
is genuinely low — `**Never call manually**` is the load-bearing
content. (2) The current per-file forms each address their own audience
correctly (Codex user reading AGENTS.md sees Codex first; Claude user
sees Claude first). (3) Option (c) introduces NEW per-CLI cross-
references that aren't currently there and would need future maintenance
(every CLI's hook-mechanism update would touch all three files); (a)
preserves the simpler current state. (4) The Gemini-has-no-hook gap
(noted in §4.1 row "Per-CLI hook firing mechanism") is real but is
NOT a BD-182 trigger — it's a separate documentation-gap concern that
deserves its own BD if surfaced.

**Carry-forward discipline applied:** Option (a) treats R10 as
non-finding (no carry-forward). Option (c) would surface the Gemini-
hook gap as in-scope, which would expand BD-182's scope without
empirical trigger — that expansion fails the LOGICAL-FIT test (the
Gemini-hook gap is a different concept from cross-CLI reference
normalization). Defer to a separate BD if the user wants it tracked.

### §13.2 — OQ-2 (AGENTS.md R1 shape — Shape A vs Shape B)

**Context:** §6.1.2 + §6.1.2.1.

**Options:**

- **Shape A: NO EDIT to AGENTS.md.** Retain the current concise form
  ("For iOS 26 API details, read directly from the Xcode documentation
  bundle at `/Applications/Xcode.app/…`. If the path does not exist,
  fall back to web search."). Codex user with non-standard Xcode path
  consults CLAUDE.md, GEMINI.md, or `.codex/config.toml` directly to
  learn the env-override mechanism.
- **Shape B: EXPAND AGENTS.md to match CLAUDE-form structure with
  per-CLI canonical substitution.** AGENTS.md would gain a
  fuller-form bullet documenting `.codex/config.toml [env]` table as
  the Codex-canonical override surface. Violates the AGENTS-conciseness
  contract.

**Architect recommendation: Shape A.** Rationale: (1) the AGENTS-
conciseness contract is documented in the file's own preamble and was
explicitly preserved by BD-178 SHOULD-1 (§4 of that IMPL-REPORT). (2)
Expanding AGENTS.md to match CLAUDE/GEMINI body fullness is a
SEPARATE architectural decision (reverse the conciseness contract; or
amend it; or carve out an exception) that does NOT belong in BD-182's
cross-CLI normalization scope. (3) Operationally, the override STILL
works in Codex via `$XCODE_APP` env at process level OR via `.codex/
config.toml [env]` table; AGENTS.md just doesn't document the
override mechanism. (4) The hardcoded `/Applications/Xcode.app` path
in AGENTS.md works for the overwhelming majority of clients; the
minority with non-standard Xcode paths can read CLAUDE.md (in the
same repo) or `supporting-docs/INSTALL-PROCEDURES.md` for the
mechanism.

**Carry-forward discipline applied:** Shape A treats AGENTS-conciseness
contract reversal as out-of-scope (which it is — different concept,
different design decision, fails SIZE + LOGICAL-FIT tests for in-scope
BD-182 inclusion). If user wants to revisit the AGENTS-conciseness
contract, surface as a new BD with architect-pass.

### §13.3 — OQ-3 (Check 18 / new-check decision + Pack memory bullet)

**Context:** §8.

**Options:**

- **(a) NO new check + ADD pack-memory bullet** per §8.3 draft.
  Documentary record + future-actor reminder via Pack memory.
- **(b) NEW check enforcing per-CLI canonical reference table values.**
  Requires pack-architect or pack-planner pass to design the regex/AST
  approach (Pack Chat re-routes BD-182 implementation post-architect-
  reapproval).
- **(c) EXTEND Check 18 to verify per-file audience-declaration comment
  presence.** Lightweight; doesn't catch the actual incident class.
- **(d) NO new check + NO pack-memory bullet.** Even narrower than (a) —
  the §4.1 canonical reference table lives only in this architect doc,
  with no forward-pointing reminder in trinity Pack memory.

**Architect recommendation: (a).** Rationale: see §8.2. The empirical
scope is narrow enough that CI surface is over-engineering; reviewer-
attention dependence is mitigated by the Pack memory bullet that
codifies the §4.1 canonical reference table as a standing rule.
Pack memory is a higher-quality forward-pointing surface than a CI
check for low-frequency text-normalization classes because (i) actors
read it before editing rather than after submitting, and (ii) it
doesn't carry false-positive risk that a regex-based check would.

**Carry-forward discipline applied:** Option (a) is a fix-now action
(the pack-memory bullet is mechanical pack-coder work bundled with
§6 trinity edits in the same commit). Option (b)'s design pass and
implementation would be a separate architect → planner → coder cycle
— if user prefers option (b), Pack Chat re-routes (and BD-182's
trinity-edit scope still ships in this BD; check-design is a follow-up
BD or this-BD-scope-expansion per user direction).

### §13.4 — Carry-forward discipline self-check

Per `.claude/skills/review/SKILL.md` § Carry-forward discipline, every
OQ presented above is evaluated against the SIZE / BLOCKED / LOGICAL-
FIT high-bar tests. None of the OQs themselves attempt to defer
in-scope work; each is a user-direction request for resolving a
specific design point that genuinely belongs in BD-182 scope. The
options within each OQ that would EXPAND scope (OQ-1 (c) Gemini-hook
gap; OQ-2 Shape B AGENTS-conciseness reversal; OQ-3 (b) new check
design) are flagged as scope-expansion and would re-route through Pack
Chat for user-approval per pack memory OQ-1 (new-BD-open requires
user-discussion-and-approval).

**Forbidden carry-forward shapes evaluated:**

- "This is a broader pattern than just this commit" — NOT used. §3.1
  inventory is empirical and bounded.
- "End-of-batch reviewer might consider…" / "Worth ~N minutes of
  attention before the batch closes" — NOT used. All in-scope work
  ships in BD-182's commit(s).
- "Forward-looking conjecture" — flagged and rejected in §8.2
  rationale point 3 (re: reviewer-attention dependence claim).
- "Design ratification" — NOT used.
- "Pack memory rule X recommends fix-now stated as the rationale but
  presented as carry-forward" — NOT used.

All OQ options either fix-now within BD-182 OR explicitly route through
new-BD-open user-discussion-and-approval per OQ-1.

---

## §14 Carry-forward observations

Per pack memory `feedback-deferral-is-scope-creep` and the architect
skill's carry-forward discipline, this section enumerates any
scope-adjacent observations surfaced during BD-182 analysis and their
SIZE / BLOCKED / LOGICAL-FIT evaluation. These are NOT recommendations
to defer; they are recommendations to FIX-NOW or to open new BDs with
user-discussion-and-approval per OQ-1 (no silent carry-forwards).

### §14.1 — Observation 1: Gemini has no documented post-edit hook

**Surfaced in:** §4.1 row "Per-CLI hook firing mechanism," §5.1 worked
example 3, §13.1 OQ-1 architect rationale point 4.

**Evaluation:**

- SIZE: small (documentation-only). FAILS the SIZE bar for deferral-
  justification.
- BLOCKED: not blocked. FAILS the BLOCKED bar.
- LOGICAL-FIT: different concept from cross-CLI reference normalization
  (which is about correcting WRONG references; this is about FILLING
  a GAP). LOGICAL-FIT fit with BD-182 is weak.

**Recommended action:** FIX-NOW if user accepts in-scope expansion;
otherwise OPEN NEW BD with user-discussion-and-approval. The
documentation gap is real and would benefit a Gemini user wondering
why the post-edit hook never fires for them. Open as `BD-NNN` per
pack memory BD-NNN numbering protocol (read the live BACKLOG for next
number, do not guess from this doc).

### §14.2 — Observation 2: AGENTS-conciseness contract documents the
intentional asymmetry but is not codified in Check 18

**Surfaced in:** §3.1 row R10 + §6.1.2 + §13.2 OQ-2.

**Evaluation:**

- SIZE: small (potentially a new check or a Check 18 extension —
  architect-pass material).
- BLOCKED: not blocked.
- LOGICAL-FIT: weak fit with BD-182 (cross-CLI reference normalization
  is different from AGENTS-conciseness enforcement).

**Recommended action:** OPEN NEW BD if user wants the AGENTS-conciseness
contract mechanically enforced. The current state is honor-system + per-
reviewer attention (which the carry-forward discipline warns against).
But this is outside BD-182's scope; do NOT expand BD-182 to cover it.

### §14.3 — Observation 3: `agent-run.sh` exists at `project-template/`
trees but invocation reference patterns vary

**Surfaced in:** §3.1 rows R8 + R9.

**Evaluation:**

- SIZE: small (documentation-only).
- BLOCKED: not blocked.
- LOGICAL-FIT: fits with the "Phase routing" H2 in trinity, distinct
  from BD-182's cross-CLI references.

**Recommended action:** NO ACTION. The current `agent-run.sh <cli>`
form is correctly cross-CLI-neutral. No defect, no follow-up BD.

### §14.4 — Observation 4: pack-root trinity scope decision (§2) could
be re-tested by a follow-up reviewer

**Surfaced in:** §2 closing reviewer-pass note.

**Evaluation:**

- SIZE: small (re-running §3 inventory at pack-root).
- BLOCKED: not blocked.
- LOGICAL-FIT: cleanly extends BD-182 if a pack-root issue is found;
  otherwise no-op.

**Recommended action:** the end-of-batch pack-reviewer (already
scheduled per the BD-175 emergency batch sequence) will re-test
empirically. If pack-root trinity has a genuine cross-CLI reference
defect surfaced, file a follow-up BD; do NOT expand BD-182 mid-flight.
This is the §2 explicit boundary; the reviewer's authority to surface
a finding is intact.

### §14.5 — No silent carry-forwards

No observation in this section is being silently deferred. Each is
either FIX-NOW (within BD-182 via OQ resolution) OR explicitly
recommends OPEN NEW BD with user-discussion-and-approval per pack
memory OQ-1. The forbidden carry-forward shapes are not used.

---

## §15 Strategy-doc audit checklist

| Criterion | Status | Evidence |
|---|---|---|
| Strategy doc enumerates the cross-CLI reference inventory empirically (cite each reference's file location) | DONE | §3.1 (15 inventory rows with file:H2-section citations) |
| Per-CLI canonical reference table is concrete (each cell specific) | DONE | §4.1 (8 concept rows × 3 CLI columns, all cells specific with empirical-source citations) |
| Decision tree for tool-specific vs tool-neutral is precise | DONE | §5 (3-criterion test for each class + 3 worked examples in §5.1) |
| Trinity edit plan is mechanical for pack-coder | DONE | §6 (single-line substring substitution for R1; per-OQ-resolution branching for R10 / R1 expand) |
| Pack-root scope decision is justified | DONE | §2 (5-point empirical-evidence rationale for pack-root OUT-of-scope) |
| Check 18 / new-check decision is justified | DONE | §8 (3 options + architect recommendation (a) with 4-point rationale; OQ-3 surfaces all 4 options to user) |
| Install-time path-adjustment audit performed | DONE | §7 (3-point empirical evidence that init-project.sh does not substitute) |
| RC9 implications documented | DONE | §9 (expected manifest drift pattern + staging plan + commit-scope keyword) |
| OQs surfaced for Pack Chat user-approval | DONE | §13 (OQ-1, OQ-2, OQ-3 with options + architect recommendations + carry-forward-discipline check) |
| Carry-forward discipline applied to OQs | DONE | §13.4 + §14 (each OQ evaluated against SIZE / BLOCKED / LOGICAL-FIT; forbidden carry-forward shapes enumerated and not used) |
| Override 9 compliance proof | DONE | §10 (4 sub-sections: trinity rule preservation, Check 18 expected behavior at both locations, explicit Override 9 citation) |
| Implementation sequence enumerated for pack-coder | DONE | §11 (4 phases: pre-flight, edit application, verification, PREFLIGHT + IMPL-REPORT write; commit-shape for Pack Chat) |
| File:symbol references only (NOT line numbers) | DONE | All file references use H2 section anchors, function names, or symbol names; line numbers cited only for archived/historical context (BD-178 SHOULD-1 IMPL-REPORT structure references) and within direct quotes from existing scripts where the surrounding context is the load-bearing claim |

---

## §16 Pack-coder spawn handoff summary

When Pack Chat user-approves this strategy and the OQ-1 / OQ-2 / OQ-3
resolutions, the pack-coder spawn prompt should include:

1. **Context:** "Apply ARCHITECTURE-BD-182.md mechanically per
   user-approved OQ resolutions: OQ-1=<a|b|c>, OQ-2=<Shape A|Shape B>,
   OQ-3=<a|b|c|d>."
2. **Output file path:** `maintenance-docs/v11-implementation/
   IMPLEMENTATION-REPORT-BD-182.md`
3. **Read-only flags:** none — this is a write-scoped coder task
4. **Markdown-only directive:** for the IMPL-REPORT
5. **Problem / goal / success criteria:** point at this strategy doc;
   pack-coder reads §11 implementation sequence + §15 audit checklist
6. **STOP-MEANS-STOP + PREFLIGHT preamble:** per pack memory pack-coder
   PREFLIGHT + STOP-MEANS-STOP pattern (load-bearing for IMPL-REPORT
   trust)
7. **Chunk long writes:** instruction per pack memory
8. **No new POQ-surfacing:** the OQs are already resolved at user-
   approval gate; coder does NOT introduce new OQs (any newly-surfaced
   concerns go in the IMPL-REPORT "Carry-forward observations" section
   per §14 pattern, NOT as fix-coder decisions)

---

End of ARCHITECTURE-BD-182 strategy doc.
