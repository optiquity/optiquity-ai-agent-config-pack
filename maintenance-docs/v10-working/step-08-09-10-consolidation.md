# Step 08–09–10 — Consolidation (Touch-Point Inventory, Testing Matrix, Verification Plan)

*Report type: Phase-1 / Steps 8, 9, 10 combined deliverable for V10-DESIGN-PROCESS-PLAN.md.*
*Author: pack-planner (read-only session).*
*Date: 2026-04-21.*
*Scope: Consolidate the approved Step 3–7 design deliverables into three cross-cutting
artifacts: a complete touch-point inventory (Step 8), a migration testing matrix
(Step 9), and a verification plan (Step 10). These three artifacts feed Phase 3
implementation planning and Phase 4 implementation / test.*

---

## 0. Inputs

This report consolidates approved outputs from:

- Step 2 — CLI verification findings (maintenance-docs/v10-working/step-02-cli-verification.md)
- Step 3 — BD-045 capabilities drafts (step-03-bd045-capabilities.md)
- Step 4 — Prompt template reorg (step-04-prompt-reorg.md)
- Step 5 — Custom agent & skill support (step-05-custom-agents.md)
- Step 6 — Migration design v9.3 → v10.0 (step-06-migration.md)
- Step 7 — BD-044 init-project & QUICKSTART router (step-07-init-project.md)
- V10-PREDESIGN.md Part 4 (starting touch-point checklist), Part 7 (design requirements),
  Part 8 (V9 lessons), Part 9 (token budget), Part 10 (testing matrix dimensions).
- V9-DESIGN.md Parts 4 & 6 (format reference, stale-reference pattern).
- README.md Repository Layout section (authoritative pack structure).
- scripts/validate-pack.py and .github/workflows/validate-pack.yml (current CI shape).

No new design decisions are introduced. Every row/cell/item in this report is
traceable to one of the above inputs.

---

# Part 1 — Step 8: Touch-Point Inventory

*Replaces V10-PREDESIGN.md Part 4 in full. Tagged by BD and by actor so the
Phase 3 implementation planner can sequence by BD order (BD-045 → BD-046 →
BD-044). Trinity-rule notes are called out wherever CLAUDE/AGENTS/GEMINI
edits must move together.*

## 1.1 Legend

**BD tags.** BD-044 (init-project & router), BD-045 (capabilities pattern),
BD-046 (custom agents & prompt reorg). A file may carry multiple tags when
the same commit touches it for more than one BD — noted inline.

**Actors.** The actor is the entity that performs the write. Options:

- **pack chat** — direct pack-chat edits during Phase 4 implementation
- **init-project.sh** — writes on first project installation
- **migrate-v9-to-v10.sh** — writes during a v9.3 → v10.0 upgrade
- **PM chat** — writes in a running project after pack is installed
  (kickoff, Procedure 5, Procedure 5-R, phase-gate scan)
- **developer** — human manual edit (with approval gates)
- **CI** — pack-repo GitHub Actions workflow

**Trinity note.** "TRIO" means the row applies identically to CLAUDE.md,
AGENTS.md, GEMINI.md and must be edited in one commit; Step 3 §8 and Step 5
§16.2 establish when tool-specific deviations are justified.

---

## 1.2 Pack repository — files that change in v10.0

### 1.2.1 BD-045 — Capabilities pattern (10 files)

| # | File | Change | BD | Actor | Trinity | Source |
|---|---|---|---|---|---|---|
| 1 | `project-template/CLAUDE.md` | Insert new `## Capabilities pattern` section after `## Liskov Substitution Principle` (Step 3 §2.1). Append anti-pattern bullet to universal anti-patterns list (Step 3 §2.2). | BD-045 | pack chat | TRIO — identical wording in all three | Step 3 |
| 2 | `project-template/AGENTS.md` | Same edits as row 1. | BD-045 | pack chat | TRIO | Step 3 |
| 3 | `project-template/GEMINI.md` | Same edits as row 1. | BD-045 | pack chat | TRIO | Step 3 |
| 4 | `project-template/skills/apple-architecture-core/SKILL.md` | Insert new `## Capabilities pattern` section (rules 11–14) after `## Protocol abstractions`; renumber existing rules 11–23 → 15–27 (Step 3 §3). | BD-045 | pack chat | — | Step 3 |
| 5 | `project-template/skills/python-best-practices/SKILL.md` | Insert new `## Capabilities pattern` section (rules 14–17) after `## Error handling`; renumber existing rules 14–32 → 18–36 (Step 3 §4). | BD-045 | pack chat | — | Step 3 |
| 6 | `project-template/skills/architecture-review/SKILL.md` | Insert new `## Capabilities pattern` section (rules 14–17) after `## Abstraction quality`; renumber existing rules 14–15 → 18–19 (Step 3 §6). | BD-045 | pack chat | — | Step 3 |
| 7 | `project-template/.claude/agents/auditor-architecture.md` | Insert new `Capabilities pattern adherence` scope bullet after `LSP compliance` (Step 3 §7.1). | BD-045 | pack chat | TRIO of three auditor files — identical markdown wording across Claude & Gemini; Codex carries semantically identical text in plain-bullet style per §7.2. | Step 3 |
| 8 | `project-template/.codex/agents/auditor-architecture.toml` | Same as row 7, plain-bullet style inside the TOML triple-quoted `developer_instructions` block (Step 3 §7.2). | BD-045 | pack chat | See row 7 | Step 3 |
| 9 | `project-template/.gemini/agents/auditor-architecture.md` | Same as row 7 (Step 3 §7.3). | BD-045 | pack chat | See row 7 | Step 3 |
| 10 | *(design artifact — no file created yet)* Placeholder template for future language skills | Language-skill authoring template kept in V10-DESIGN.md Part 3 §5; applied when a new language skill is added in a future pack version. | BD-045 | (future pack chat) | — | Step 3 §5 |

**Renumbering sweeps.** Rows 4, 5, 6 shift existing rule numbers. Any file
that references these skills' rule numbers by number (e.g. "per rule 14 of
architecture-review") must be updated. Step 4 §6.2 stale-reference sweep
protocol applies. Grep targets: `rule 1[1-9]` and `rule [23][0-9]` across
`project-template/`, `supporting-docs/`, and `maintenance-docs/` during
Phase 4 verification.

**Back-reference check (Step 3 §10 handoff).** `audit-methodology/SKILL.md`
rule 15 references auditor-architecture scope; confirm no extension is
required there, or add one. Tagged as Phase 3 surfacing item — no file
change here unless Phase 3 decides otherwise.

---

### 1.2.2 BD-046 — Prompt template reorganization (new & removed files, plus stale-reference sweeps)

**New directory and files** (Step 4 §2.3):

| # | File | Change | BD | Actor | Trinity | Source |
|---|---|---|---|---|---|---|
| 11 | `project-template/docs/pack/prompts/` | Create directory. | BD-046 | pack chat | — | Step 4 §2.3 |
| 12 | `project-template/docs/pack/prompts/coder.md` | New per-agent prompt file. Frontmatter `agent: coder`, variants `standard`, `fix-cycle`. Content lifted from v9.3 Templates 2 + 4. | BD-046 | pack chat | — | Step 4 §1.2, §2.3 |
| 13 | `project-template/docs/pack/prompts/reviewer.md` | New. Frontmatter `agent: reviewer`, variants `standard`. From T3. | BD-046 | pack chat | — | Step 4 |
| 14 | `project-template/docs/pack/prompts/tester.md` | New. Variants `standard`. From T5. | BD-046 | pack chat | — | Step 4 |
| 15 | `project-template/docs/pack/prompts/planner.md` | New. Variants `standard`. From T7. | BD-046 | pack chat | — | Step 4 |
| 16 | `project-template/docs/pack/prompts/docs-researcher.md` | New. Variants `standard`. From T6. | BD-046 | pack chat | — | Step 4 |
| 17 | `project-template/docs/pack/prompts/architect.md` | New. Variants `mid-phase`. From T4b (reassigned from coder per Step 4 §2.1). | BD-046 | pack chat | — | Step 4 §2.1 |
| 18 | `project-template/docs/pack/prompts/grpc-schema.md` | New. Placeholder — zero variants. | BD-046 | pack chat | — | Step 4 §2.2 |
| 19 | `project-template/docs/pack/prompts/repo-ops.md` | New. Placeholder — zero variants. | BD-046 | pack chat | — | Step 4 §2.2 |
| 20 | `project-template/docs/pack/prompts/auditor.md` | New. Variants `standard` (from T9) plus trailing note on T10–12 supersession. | BD-046 | pack chat | — | Step 4 |
| 21 | `project-template/docs/pack/prompts/pm-chat.md` | New. PM chat operational templates. Variants `kickoff`, `backlog-status-update`, `generate-setup`, `generate-agent-kickoff` (from T1, T8, T13, T14). Reserved `agent: pm-chat` frontmatter identifier. | BD-046 | pack chat | — | Step 4 §2.3 |
| 22 | `project-template/docs/pack/prompts/README.md` | Short pointer file; points readers to METHODOLOGY.md §"Prompt Authoring Principles" as the single source for authoring rules (Step 4 §2.4). | BD-046 | pack chat | — | Step 4 §2.4 |

**Removed file:**

| # | File | Change | BD | Actor | Trinity | Source |
|---|---|---|---|---|---|---|
| 23 | `supporting-docs/PROMPT-TEMPLATES.md` | **Delete** at v10.0. Content has been split into rows 12–21. "Prompt Authoring Principles" already lives in METHODOLOGY.md and remains the single source. | BD-046 | pack chat | — | Step 4 §2.4, §6.2 |

**Operational stale-reference sweep — must update in v10.0:**

| # | File | Change | BD | Actor | Trinity | Source |
|---|---|---|---|---|---|---|
| 24 | `project-template/docs/pack/PM-CHAT.md` | Remove PROMPT-TEMPLATES.md row from File-access-strategy table; add `docs/pack/prompts/<agent>.md` row + `.claude/agents/…, .gemini/agents/…, docs/pack/prompts/` directory-listing row (Step 4 §5.5, Step 5 §13.3). Remove PROMPT-TEMPLATES.md from the mcp-local-rag recommendation sentence (Step 4 §5.5). **This row is also touched by BD-046 custom agents (row 38 below) — combine in one commit.** | BD-046 | pack chat | — | Step 4 §5.5, §6.2 |
| 25 | `project-template/skills/pm-startup/SKILL.md` | Drop `docs/pack/PROMPT-TEMPLATES.md` from Step 4 RAG-freshness check; METHODOLOGY.md remains. Step 2 core-state-files list: remove PROMPT-TEMPLATES.md if present (Step 4 §5.2). | BD-046 | pack chat | — | Step 4 §5.2 |
| 26 | `project-template/CLAUDE.md` | Update Document-locations table `docs/pack/` row — replace `PROMPT-TEMPLATES.md` literal with `prompts/` directory reference (Step 4 §6.2). **Also touched by BD-045 (row 1) and BD-046 Custom agents (row 39). Single-commit coordination required.** | BD-046 | pack chat | TRIO | Step 4 §6.2 |
| 27 | `project-template/AGENTS.md` | Same edit as row 26. **Combine with rows 2 and 40.** | BD-046 | pack chat | TRIO | Step 4 §6.2 |
| 28 | `project-template/GEMINI.md` | Same edit as row 26. **Combine with rows 3 and 41.** | BD-046 | pack chat | TRIO | Step 4 §6.2 |
| 29 | `project-template/README.md` | Sweep for any file-listing or path reference to `PROMPT-TEMPLATES.md` — update if present (Step 4 §6.2). | BD-046 | pack chat | — | Step 4 §6.2 |
| 30 | `supporting-docs/METHODOLOGY.md` | Replace any reference to PROMPT-TEMPLATES.md as the location of per-agent templates with `docs/pack/prompts/<agent>.md`. Do NOT modify the "Prompt Authoring Principles" section content. **Also touched by rows 48 (Procedure 5) and 63 (Procedure 5-R) — single-commit coordination required.** | BD-046 | pack chat | — | Step 4 §6.2 |
| 31 | `QUICKSTART.md` | Full rewrite as three-path router (Step 7 §8.2). PROMPT-TEMPLATES.md reference is dropped as part of the rewrite (Step 4 §6.2 + Step 7). **Also a BD-044 row — see row 64.** | BD-044, BD-046 | pack chat | — | Step 4 §6.2, Step 7 §8.2 |
| 32 | `supporting-docs/CLI-PM-SETUP.md` | Sweep for PROMPT-TEMPLATES.md references as a directly-paste-able resource; update to per-agent prompt files. Also sweep for `QUICKSTART.md Step N` number references (Step 7 §14.1). **BD-044 + BD-046 combined sweep.** | BD-044, BD-046 | pack chat | — | Step 4 §6.2, Step 7 §14.1 |
| 33 | `supporting-docs/SETUP_TEMPLATE.md` | (a) Replace `cp -r` and manual skill distribution with `bash "$PACK/scripts/init-project.sh"` (BD-044, Step 7 §9.4). (b) Rewrite QUICKSTART step-number cross-references to reference SETUP-NEW.md section names. (c) Replace any PROMPT-TEMPLATES.md reference (Step 4 §6.2). **BD-044 + BD-046 combined.** | BD-044, BD-046 | pack chat | — | Step 4 §6.2, Step 7 §9.4 |
| 34 | `supporting-docs/DEPENDENCIES.md` | Update only if it enumerates PROMPT-TEMPLATES.md as a shipped file; otherwise no-op (Step 4 §6.2). | BD-046 | pack chat | — | Step 4 §6.2 |
| 35 | `supporting-docs/MIGRATION-v8-to-v9.md` | No operational update required; historical record. A single one-line pointer to MIGRATION-v9-to-v10.md for forward upgrades is acceptable but not mandatory (Step 6 §10.2). | — (annotate only) | pack chat | — | Step 6 §10.2 |

**Annotate-but-do-not-mutate (historical records, per V9 Lesson 4 / Step 4 §6.2):**

| # | File | Annotation | BD | Actor | Trinity | Source |
|---|---|---|---|---|---|---|
| 36 | `maintenance-docs/V9-DESIGN.md` | Add a v10 supersession note next to Part 4 and Part 6 rows that reference `PROMPT-TEMPLATES.md` as a shipping artifact. Point to `project-template/docs/pack/prompts/`. Do not silently rewrite v9 content (V9 Lesson 4). Annotate Decision 7 (current "permitted project-level customization" language) to point at V10-DESIGN Part 5 custom-agent mechanism (Step 5 §16.3). | BD-046 | pack chat | — | Step 4 §6.2, Step 5 §16.3 |
| 37 | `maintenance-docs/V9-AUDIT-REPORT.md` (if present) | Same treatment as row 36. | BD-046 | pack chat | — | Step 4 §6.2 |

**No-action historical files** (listed to prevent accidental edits — Step 4 §6.2):
`maintenance-docs/origins/Claude-Assisted_Project_Methodology_Guide_v1.md`;
`maintenance-docs/guides/ai-agent-config-pack-v8-guide.md`;
`maintenance-docs/GEMINI-CLI-ANALYSIS.md`; `maintenance-docs/ANDROID-ANALYSIS.md`;
`CHANGELOG.md` (except a v10.0 entry, row 76); resolved `BACKLOG.md` items
(BD-027, BD-028, BD-029, BD-038) that describe what shipped at their
release time.

---

### 1.2.3 BD-046 — Custom agent & skill support (new sections, new files)

| # | File | Change | BD | Actor | Trinity | Source |
|---|---|---|---|---|---|---|
| 38 | `project-template/docs/pack/PM-CHAT.md` | Add `## Pack agent roster` section near top (16 pack agents, bulleted, Step 5 §7.2). Add `## Custom agent and skill workflow` section after `## Behavioral rules` pointing to METHODOLOGY.md Procedure 5 (Step 5 §13.2). Add new behavioral-rules bullets (Step 5 §13.4). File-access-strategy table additions (Step 5 §13.3) — **combine with row 24.** | BD-046 | pack chat | — | Step 5 §7.2, §13 |
| 39 | `project-template/CLAUDE.md` | Add `### Custom agents` sub-section at end of Phase routing table (Step 5 §14). **Combine with rows 1 and 26.** | BD-046 | pack chat | TRIO | Step 5 §14 |
| 40 | `project-template/AGENTS.md` | Same as row 39. **Combine with rows 2 and 27.** | BD-046 | pack chat | TRIO | Step 5 §14 |
| 41 | `project-template/GEMINI.md` | Same as row 39. **Combine with rows 3 and 28.** | BD-046 | pack chat | TRIO | Step 5 §14 |
| 42 | `project-template/docs/pack/PLATFORM-SKILLS.md` | Add `## Custom agents` section (header + column spec, Step 5 §12.1); add `## Custom skills` section (header + column spec, Step 5 §12.2). Both immediately after `## Full skill inventory`. Placeholder rows "No custom X defined for this project." | BD-046 | pack chat | — | Step 5 §12 |
| 43 | `supporting-docs/METHODOLOGY.md` | Add new **Procedure 5 — Custom agent and skill workflow** at the end of Part 7 (Step 5 §11): sub-procedures 5.1 creation, 5.2 skill-only creation, 5.3 partial-registration completion, 5.4 improperly-added adoption, 5.5 phase-gate integration (added as step 5a in Procedure 1), 5.6 reference tables. **Combine with rows 30 and 63 (Procedure 5-R).** | BD-046 | pack chat | — | Step 5 §11 |

---

### 1.2.4 BD-046 — Migration (v9.3 → v10.0) new files

| # | File | Change | BD | Actor | Trinity | Source |
|---|---|---|---|---|---|---|
| 44 | `supporting-docs/MIGRATION-v9-to-v10.md` | **New guide.** 15 sections per Step 6 §9.1 (title + banner; what changed; before you start; seven numbered migration steps; after-migration PM chat brief; rollback; project-type notes; troubleshooting; automatable paste-ready prompt). | BD-046 | pack chat | — | Step 6 §9 |
| 45 | `scripts/migrate-v9-to-v10.sh` | **New migration script.** Seven stages S0–S7 (Step 6 §7.2) with sentinel files `.pack-migration-backup/v9.3-to-v10.0/stage-S<N>.done`. Lives at pack-repo `scripts/`, not in `project-template/`. Sources `scripts/lib/detect.sh` (Step 7 §1.3). | BD-046 | pack chat | — | Step 6 §8.1 |
| 46 | `scripts/merge-platform-skills.py` | **New helper.** Positional splice at first `## Custom agents` or `## Custom skills` heading, Step 6 §4. | BD-046 | pack chat | — | Step 6 §4, §8.7 |
| 47 | `scripts/merge-trinity.py` | **New helper.** Two splices per trinity file: `### Custom agents` sub-section and `**Active skills:**` line (Step 6 §5). | BD-046 | pack chat | — | Step 6 §5, §8.7 |
| 48 | `supporting-docs/METHODOLOGY.md` | Add **Procedure 5-R — Prompt template reconciliation** alongside Procedure 5 (Step 6 §3.5). Triggered by presence of `docs/pack/prompts/_v9-backup.md`. **Combine with rows 30 and 43.** | BD-046 | pack chat | — | Step 6 §3.5 |

---

### 1.2.5 BD-044 — init-project.sh and router files

| # | File | Change | BD | Actor | Trinity | Source |
|---|---|---|---|---|---|---|
| 49 | `scripts/init-project.sh` | **New.** Detection pass; preview-and-confirm; 10 stages S0–S10 (Step 7 §4, §5); inline verification at every stage (Step 7 §6). Pack-repo `scripts/` — never copied into projects. | BD-044 | pack chat | — | Step 7 §1, §4 |
| 50 | `scripts/lib/` | **New directory** at pack-repo `scripts/` (Step 7 §1.6). | BD-044 | pack chat | — | Step 7 §1.6 |
| 51 | `scripts/lib/detect.sh` | **New shared detection library** sourced by `init-project.sh` and `migrate-v9-to-v10.sh`. Functions listed in Step 7 §1.3. | BD-044 | pack chat | — | Step 7 §1.3 |
| 52 | `supporting-docs/SETUP-NEW.md` | **New.** Full procedural guide for new projects (Step 7 §9). ~300–400 lines. Content lifted from v9 QUICKSTART.md §§1–12 minus the manual copy steps that init-project.sh replaces. Updates PROMPT-TEMPLATES.md references to `docs/pack/prompts/pm-chat.md` variants. | BD-044 | pack chat | — | Step 7 §9 |
| 53 | `supporting-docs/SETUP-EXISTING.md` | **New.** Procedural guide for existing projects with no AI tooling (Step 7 §10). Includes preview-walkthrough, developer transition notice, existing-docs pointer procedure, skill-gap follow-up. ~200–250 lines. | BD-044 | pack chat | — | Step 7 §10 |
| 54 | `QUICKSTART.md` | **Full rewrite** as ~30-line three-path router (Step 7 §8.2). New-project → SETUP-NEW.md; existing-project → SETUP-EXISTING.md; upgrade → MIGRATION-vN-to-vM.md. Migration-guide naming convention stated. **Combine with row 31 stale-reference sweep.** | BD-044 | pack chat | — | Step 7 §8.2 |
| 55 | `README.md` | Repository Layout section updated: add `scripts/lib/` entry; add `scripts/init-project.sh`, `scripts/migrate-v9-to-v10.sh`, `scripts/merge-*.py`; add `supporting-docs/SETUP-NEW.md`, `SETUP-EXISTING.md`, `MIGRATION-v9-to-v10.md`; add note under `supporting-docs/` about `MIGRATION-vN-to-vM.md` naming convention (Step 7 §11.2). Also add v10.0 version-table row (see row 74). | BD-044, BD-046 | pack chat | — | Step 7 §11.2, §14.1 |

---

### 1.2.6 validate-pack.py and CI workflow updates

| # | File | Change | BD | Actor | Trinity | Source |
|---|---|---|---|---|---|---|
| 56 | `scripts/validate-pack.py` | Add **Check 6 — Prompts directory format.** Iterate `project-template/docs/pack/prompts/*.md`; enforce YAML frontmatter, `agent` matches filename stem, each `variants:` slug has matching `## Variant: <slug>` H2 heading, reserved keys permitted, unknown frontmatter keys rejected. Accept zero-variant placeholder files. `x-<name>.md` files follow same rule set (Step 4 §4.5). | BD-046 | pack chat | — | Step 4 §4.5 |
| 57 | `scripts/validate-pack.py` | Add **Check 7 — Pack agent roster consistency.** Parse `project-template/docs/pack/PM-CHAT.md` `## Pack agent roster` bulleted list; compare to `.claude/agents/` stems; fail on mismatch (Step 5 §15.2). | BD-046 | pack chat | — | Step 5 §15.2 |
| 58 | `scripts/validate-pack.py` | Add **Check 8 — Reserved `x-` prefix.** Fail validation if any filename or directory in the seven pack template scan locations (Step 5 §15.3) begins with `x-`. Pack never ships `x-` files (Step 5 §9). | BD-046 | pack chat | — | Step 5 §15.3 |
| 59 | `scripts/validate-pack.py` | Add **Check 9 — BD-044 structure.** Confirm `scripts/init-project.sh` exists and is executable; `scripts/lib/detect.sh` exists and defines the Step 7 §1.3 functions (grep for function signatures); `QUICKSTART.md`, `SETUP-NEW.md`, `SETUP-EXISTING.md`, `MIGRATION-v9-to-v10.md` all exist; `README.md` Repository Layout mentions `scripts/lib/` and the migration-guide naming convention (Step 7 §14.1). | BD-044 | pack chat | — | Step 7 §14.1 |
| 60 | `scripts/validate-pack.py` | Update **Check 1 — SKILL.md frontmatter**: no semantic change, but tolerate newly-added skills `apple-architecture-core` / `python-best-practices` / `architecture-review` after the BD-045 renumbering sweep (Step 3 rows 4–6). Sanity-only — no code change expected. | BD-045 | pack chat | — | Step 3 |
| 61 | `.github/workflows/validate-pack.yml` | No workflow-level change required if Check 6–9 are added inside the existing `python3 scripts/validate-pack.py` invocation. Re-verify on the v10-dev branch that `Validate Pack` still runs cleanly. | BD-044, BD-046 | pack chat | — | Step 5 §15, Step 7 §14.1 |

---

### 1.2.7 Pack-operational files (version bookkeeping)

| # | File | Change | BD | Actor | Trinity | Source |
|---|---|---|---|---|---|---|
| 62 | `maintenance-docs/V10-DESIGN.md` | **New document.** Produced by Step 11 of the design process plan. Status header APPROVED at Step 13. | — | pack chat | — | V10-DESIGN-PROCESS-PLAN Step 11–13 |
| 63 | `maintenance-docs/V10-PREDESIGN.md` | Supersession banner at top pointing to V10-DESIGN.md (body retained as historical record per V9 Lesson 4, Step 13 of the design process plan). | — | pack chat | — | V10-DESIGN-PROCESS-PLAN Step 13 |
| 64 | `BACKLOG.md` | Clear BD-044, BD-045, BD-046 blockers at Step 13 (design approval). At v10.0 ship: update BD-044/045/046 to Resolved with commit hash + date. | — | pack chat | — | V10-DESIGN-PROCESS-PLAN Step 13 |
| 65 | `README.md` | Add v10.0 row to version table at ship time. **Combine with row 55.** | — | pack chat | — | CLAUDE.md versioning rules |
| 66 | `CHANGELOG.md` | Add v10.0 entry at ship time, per pack versioning rules. | — | pack chat | — | CLAUDE.md versioning rules |

---

## 1.3 Files in a v10 project (created or modified by init-project.sh, migration, or PM chat)

The pack-repo touch-points in §1.2 are the v10.0 deliverable. Separately,
once v10.0 ships, the following files are created or modified **inside a
project** by one of the runtime actors — this table is the reference for
what a v10 project looks like in the wild. These rows are *not* pack-repo
edits; they are what init-project.sh, migrate-v9-to-v10.sh, or the PM chat
produces in a project over time.

| # | Project path | Change | BD | Actor | Source |
|---|---|---|---|---|---|
| 67 | `docs/pack/prompts/` + 10 files + README.md | Copied from pack template. | BD-046 | init-project.sh (new projects); migrate-v9-to-v10.sh S4 (existing v9.3) | Step 4 §2.3; Step 6 §8.6; Step 7 §4.1 S6 |
| 68 | `docs/pack/prompts/_v9-backup.md` | **Conditional.** Written when project's v9.3 `docs/pack/PROMPT-TEMPLATES.md` differs from the v9.3 pack baseline (Step 6 §3.1). PM chat consumes at first post-migration pm-startup and then deletes after Procedure 5-R. | BD-046 | migrate-v9-to-v10.sh S6 (creates); PM chat (deletes) | Step 6 §3 |
| 69 | `docs/pack/PROMPT-TEMPLATES.md` (v9.3 project file) | **Deleted** at migration S6. | BD-046 | migrate-v9-to-v10.sh S6 | Step 6 §8.8 |
| 70 | `.claude/agents/x-<name>.md`, `.codex/agents/x-<name>.toml`, `.gemini/agents/x-<name>.md` | Created per Procedure 5.1. | BD-046 | PM chat | Step 5 §4.2, §11 |
| 71 | `.claude/skills/x-<name>/SKILL.md`, `.codex/skills/x-<name>/SKILL.md`, `.gemini/skills/x-<name>/SKILL.md` | Created per Procedure 5.2 (custom skill). | BD-046 | PM chat | Step 5 §4.6, §11 |
| 72 | `docs/pack/prompts/x-<name>.md` | Created per Procedure 5.1 (custom agent prompt). Same Step 4 §4 format as pack prompts. | BD-046 | PM chat | Step 4 §4.5; Step 5 §6 |
| 73 | `docs/pack/PLATFORM-SKILLS.md` `## Custom agents` + `## Custom skills` row additions | Rows added per Procedure 5.1 / 5.2. Project-owned section (Step 6 §4). | BD-046 | PM chat | Step 5 §12 |
| 74 | `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` `### Custom agents` sub-section rows | Rows added per Procedure 5.1. TRIO. Project-owned sub-section (Step 6 §5). | BD-046 | PM chat | Step 5 §14 |
| 75 | `docs/pack/PACK-FEEDBACK.md` | Skill-gap entry appended when init-project.sh reports a coverage gap and the PM chat runs its first kickoff (Step 7 §7.2). | BD-044 | PM chat | Step 7 §7 |
| 76 | `.gitignore` | Merged (append + dedupe) at init-project.sh S8. `.pack-migration-backup/` appended at migration S0. | BD-044, BD-046 | init-project.sh S8; migrate-v9-to-v10.sh S0 | Step 7 §5.2; Step 6 §6.6 |
| 77 | `.pack-migration-backup/v9.3-to-v10.0/*` | Migration backup directory (every pack-owned file replaced, manifest, stage sentinels, report.md). Gitignored. | BD-046 | migrate-v9-to-v10.sh | Step 6 §6, §8 |

**Removed rows from V10-PREDESIGN Part 4.** V10-PREDESIGN Part 4 listed
`project-template/.codex/config.toml — Custom agent registration
documentation`. This row is **removed** per Step 5 §8.1 (Codex
auto-discovers `.codex/agents/*.toml`; no `[agents.<name>]` entry exists
in documented Codex). The V10-PREDESIGN Part 5 PM-chat-workflow sub-step
"PM chat adds `[agents.x_name]` entry" is similarly removed.

---

## 1.4 Per-BD sequencing (for Phase 3)

Per Step 1 G1 decision: BD-045 → BD-046 → BD-044.

- **BD-045 commit batch.** Rows 1–9 (10 is a design artifact, no file).
  Touches trinity files in the LSP section only (no collision with row
  26–28's Document-locations edits or rows 39–41's Phase-routing edits;
  different sections of each trinity file).
- **BD-046 commit batches.** Rows 11–23 (prompt reorg new + remove),
  then 24–37 (stale-reference sweep + annotations), then 38–43 (custom
  agent sections + PLATFORM-SKILLS + Procedure 5), then 44–48 (migration
  script + guide + Procedure 5-R), then 56–58, 60–61 (validate-pack
  checks 6–8).
- **BD-044 commit batch.** Rows 49–55 (init-project.sh + lib + SETUP-NEW
  + SETUP-EXISTING + QUICKSTART rewrite + README layout), 59, 61
  (validate-pack Check 9 + workflow).
- **Cross-BD rows requiring coordination.** Rows marked **Combine with…**
  in §1.2: 24 (BD-046 stale sweep + BD-046 custom-agent additions to
  PM-CHAT.md); 26–28 (BD-045 capabilities + BD-046 Document-locations
  + BD-046 Phase-routing custom-agents — three separate sections of each
  trinity file, single commit to honor trinity rule cleanly); 30 + 43 + 48
  (METHODOLOGY.md: PROMPT-TEMPLATES.md sweep + Procedure 5 + Procedure
  5-R); 31 (QUICKSTART.md: BD-046 sweep + BD-044 rewrite); 32, 33
  (CLI-PM-SETUP.md, SETUP_TEMPLATE.md: both BDs); 55 + 65 (README.md:
  BD-044 layout + pack chat v10.0 version row).

Phase 3 implementation planning resolves the exact commit boundaries.
This inventory ensures no file is forgotten and every cross-BD dependency
is surfaced.

---

## 1.5 Trinity-rule integrity audit

Trinity rule applies to `project-template/CLAUDE.md`, `AGENTS.md`,
`GEMINI.md` and to the three `auditor-architecture` agent files. Every
BD in v10 touches all three. Audit summary:

| Section | BD-045 edit | BD-046 edit | Notes |
|---|---|---|---|
| `## Capabilities pattern` (new) | Rows 1, 2, 3 | — | TRIO |
| Anti-patterns universal list | Rows 1, 2, 3 | — | TRIO |
| `## Document locations` / docs/pack row | — | Rows 26, 27, 28 | TRIO |
| `## Phase routing` → new `### Custom agents` sub-section | — | Rows 39, 40, 41 | TRIO |
| `## Skill loading` → Active skills line | — | Preserved by migration (Step 6 §5.8); no v10 pack edit | Project-owned |
| `auditor-architecture` scope bullet | Rows 7, 8, 9 | — | TRIO (Codex formatting deviation per Step 3 §7.2) |

No asymmetry introduced by v10. Every trinity-level change is
symmetric by design.

---

## 1.6 Stale-reference sweep — consolidated grep targets for Phase 4

Every BD carries a stale-reference risk. The following grep commands are
run during Phase 4 verification:

```bash
# PROMPT-TEMPLATES.md sweep (Step 4 §6.2 scope)
grep -rn "PROMPT-TEMPLATES" \
    project-template/ supporting-docs/ \
    maintenance-docs/V9-DESIGN.md maintenance-docs/V9-AUDIT-REPORT.md \
    QUICKSTART.md README.md PACK-CHAT.md PACK-AGENTS.md \
    CLAUDE.md AGENTS.md GEMINI.md

# QUICKSTART.md Step-N sweep (Step 7 §14.1)
grep -rnE "QUICKSTART\.md\s+Step\s+[0-9]+" \
    project-template/ supporting-docs/ maintenance-docs/

# cp -r setup-command sweep (Step 7 §14.1)
grep -rnE "cp\s+-r\s+.*project-template" \
    supporting-docs/ maintenance-docs/

# Codex config.toml custom-agent entry sweep (Step 5 §8.1 — removal target)
grep -rnE "\[agents\.(x_|x-)" \
    project-template/ supporting-docs/ maintenance-docs/

# Reserved x- prefix (Step 5 §15.3 — should return zero hits inside pack template)
ls project-template/.claude/agents/ project-template/.codex/agents/ \
   project-template/.gemini/agents/ project-template/skills/ \
   project-template/docs/pack/prompts/ 2>/dev/null | grep "^x-"

# BD-045 renumbering sweep (Step 3 §10 item 1)
grep -rnE "rule [1-9][0-9]" \
    project-template/skills/apple-architecture-core/ \
    project-template/skills/python-best-practices/ \
    project-template/skills/architecture-review/ \
    project-template/ supporting-docs/ maintenance-docs/
```

Each sweep's expected result is encoded in the verification plan (Part 3).

---

*End of Part 1 — Step 8 Touch-Point Inventory.*

---

# Part 2 — Step 9: Migration Testing Matrix

*Enumerates the Cartesian product of V10-PREDESIGN Part 10 dimensions.
Each cell is labeled as **critical-path** (must be tested in Phase 4),
**spot-check** (one representative case), **deferred** (documented but
not tested), or **out-of-scope** (documented with rationale).*

## 2.1 Dimensions and levels

| Dimension | Values |
|---|---|
| **D1 — Project type** | P1 Swift-only, P2 Python-only, P3 Swift+Python monorepo, P4 Swift+gRPC (Swift+Proto), P5 existing project with no AI tools (language-agnostic; exercised as P5-Swift and P5-Python instantiations) |
| **D2 — Migration path** | M1 v9.3 → v10.0 (migrate-v9-to-v10.sh), M2 new project via init-project.sh (new-empty / new-bare), M3 existing project via init-project.sh (existing-source / existing-bare) |
| **D3 — PM chat tool** | T1 Claude Code CLI, T2 Claude Desktop app (Projects), T3 Codex CLI, T4 Gemini CLI |
| **D4 — Custom file state** | C1 no custom files, C2 custom agents only, C3 custom skills only, C4 custom agents + skills |

Total combinatorial space = 5 × 3 × 4 × 4 = 240 cells. Not every cell is
meaningful — custom-file state C2–C4 only applies to M1 (projects that
have been running and accumulated customizations) and to a post-install
exercise of M2/M3 (the developer creates customizations after init and
before upgrading). Pruning collapses the practical space to ~60 cells.

## 2.2 Critical-path coverage rules (from V10-DESIGN-PROCESS-PLAN Step 9)

- At least one cell per D3 (PM chat tool) is critical-path.
- At least one cell per BD-scoped outcome is critical-path: custom agent
  created, custom skill created, init-project.sh new, init-project.sh
  existing, migration v9.3 → v10.0.
- Every critical-path cell cross-references a verification test in Part 3.

## 2.3 Matrix — migration path M1 (v9.3 → v10.0)

Columns = D3 × D4. Rows = D1 project types. Each cell shows `<label>[Vk]`
where Vk is the Part 3 verification test identifier.

| Project | T1·C1 | T1·C2 | T1·C3 | T1·C4 | T2·C1 | T2·C2 | T3·C1 | T3·C2 | T4·C1 | T4·C4 |
|---|---|---|---|---|---|---|---|---|---|---|
| P1 Swift-only | **CP**[V-M1-01] | CP[V-M1-02] | SC[V-M1-03] | CP[V-M1-04] | CP[V-M1-05] | SC[V-M1-06] | SC[V-M1-07] | SC[V-M1-08] | CP[V-M1-09] | DEF |
| P2 Python-only | SC[V-M1-10] | DEF | DEF | SC[V-M1-11] | DEF | DEF | CP[V-M1-12] | DEF | DEF | DEF |
| P3 Swift+Python | CP[V-M1-13] | DEF | DEF | SC[V-M1-14] | DEF | DEF | DEF | DEF | DEF | DEF |
| P4 Swift+gRPC | SC[V-M1-15] | DEF | DEF | DEF | DEF | DEF | DEF | DEF | DEF | DEF |
| P5 existing (N/A for M1) | OOS | OOS | OOS | OOS | OOS | OOS | OOS | OOS | OOS | OOS |

Rationale:
- P5 `existing-source with no AI tools` is by definition a not-yet-pack
  project and cannot be on v9.3 — M1 is out-of-scope for P5.
- C2, C3, C4 require a project that has run Procedure 5 — these exist only
  if the developer created custom agents / skills on v9.x using the
  pre-v10 "unsupported manual additions" path (V9-DESIGN Decision 7) or
  on a v10.x minor before v10.0's first major upgrade. For v10.0 launch,
  at least one instance of C2 and one of C4 on the primary Claude Code
  surface must be exercised (rows P1·T1·C2 and P1·T1·C4).
- The T4·C4 cell is deferred because custom-agent creation on Gemini CLI
  is structurally the same as on Claude Code at the PM-chat layer; a
  Gemini-specific x- agent test (T4·C1 with a post-migration custom
  creation) is sufficient.

## 2.4 Matrix — migration path M2 (new project via init-project.sh)

Columns = D3. Rows = D1. M2 interacts with C1 only (a fresh project
has no custom files). The variation across project types is what
init-project.sh copies and what it conditionally removes.

| Project | T1 | T2 | T3 | T4 |
|---|---|---|---|---|
| P1 Swift-only (new) | **CP**[V-M2-01] | CP[V-M2-02] | SC[V-M2-03] | CP[V-M2-04] |
| P2 Python-only (new) | CP[V-M2-05] | SC[V-M2-06] | SC[V-M2-07] | DEF |
| P3 Swift+Python (new) | CP[V-M2-08] | DEF | DEF | DEF |
| P4 Swift+gRPC (new) | SC[V-M2-09] | DEF | DEF | DEF |
| P5 (N/A for M2) | OOS | OOS | OOS | OOS |

- P5 "existing with no AI" is not a new project — M2 out-of-scope.
- `new-empty` and `new-bare` classes are covered inside V-M2-01 and
  V-M2-05 (two `git init`ed directories — one empty, one with only a
  README).

## 2.5 Matrix — migration path M3 (existing project via init-project.sh)

Columns = D3. Rows = D1 with P5 as the primary scenario, other project
types used as existing-source exemplars.

| Project | T1 | T2 | T3 | T4 |
|---|---|---|---|---|
| P5-Swift (existing Swift, no AI) | **CP**[V-M3-01] | SC[V-M3-02] | SC[V-M3-03] | CP[V-M3-04] |
| P5-Python (existing Python, no AI) | CP[V-M3-05] | DEF | SC[V-M3-06] | DEF |
| P5-monorepo (existing Swift+Python, no AI) | CP[V-M3-07] | DEF | DEF | DEF |
| P5-Kotlin (existing Kotlin, skill-gap scenario) | CP[V-M3-08] | DEF | DEF | DEF |
| P5-bare (existing docs only, no source) | SC[V-M3-09] | DEF | DEF | DEF |
| P1–P4 (already-configured) | OOS | OOS | OOS | OOS |
| P5 with partial AI config (`.claude/` only) | CP[V-M3-10] (stop condition) | DEF | DEF | DEF |

Custom-file state is N/A for M3 because the project has no AI tooling
before init; there is no prior custom file. Any custom-file testing on
M3 is a post-init-then-Procedure-5 exercise covered by V-PM5-\* (§2.7).

## 2.6 Per-tool coverage summary (D3 × BD scope)

The rule is "at least one cell per PM chat tool is critical-path."
Matrix verifies this:

| Tool | Critical-path cells (selected representatives) |
|---|---|
| T1 Claude Code CLI | V-M1-01 (P1 Swift-only, C1), V-M1-04 (P1, C4), V-M2-01 (P1 new), V-M3-01 (P5-Swift existing), V-M3-10 (stop condition) |
| T2 Claude Desktop app | V-M1-05 (P1, C1 on Desktop — filesystem MCP), V-M2-02 (P1 new) |
| T3 Codex CLI | V-M1-12 (P2 Python, C1), V-M2-03 / V-M2-07 |
| T4 Gemini CLI | V-M1-09 (P1, C1), V-M2-04, V-M3-04 |

Each row names at least one representative cell per tool, satisfying
the "one critical-path cell per PM chat tool" rule.

## 2.7 Per-BD-scoped outcome coverage (D2 × D4)

The rule is "at least one cell per BD-scoped outcome is critical-path":

| BD-scoped outcome | Critical-path cell(s) | Primary Part 3 test |
|---|---|---|
| Custom agent created | P1·T1·C2 (M1) → V-M1-02 + new Procedure 5.1 exercise | V-PM5-01 |
| Custom skill created | P1·T1·C3 (M1) → V-M1-03 + new Procedure 5.2 exercise | V-PM5-02 |
| init-project.sh new | P1·T1 M2 → V-M2-01 | V-INIT-NEW |
| init-project.sh existing | P5-Swift·T1 M3 → V-M3-01 | V-INIT-EXIST |
| Migration v9.3 → v10.0 | P1·T1·C1 M1 → V-M1-01 | V-MIG-BASELINE |

Each BD-scoped outcome has at least one critical-path cell. Every cell
cross-references a Part 3 test.

## 2.8 Deferred cells — documented rationale

- **T4 (Gemini CLI) × C4 (agents + skills).** Deferred. The Gemini CLI
  PM chat uses identical Procedure 5 workflow logic as Claude Code;
  T4·C1 plus a post-migration Procedure 5.1 custom-creation exercise
  (V-PM5-01 on Gemini) covers the Gemini-specific risk. A full C4
  migration rehearsal on Gemini adds no new coverage the tool-agnostic
  tests don't already provide.
- **P4 (Swift + gRPC) × all non-T1 tools.** Deferred. gRPC scaffolding
  is tested structurally by validate-pack.py; the human-facing PM chat
  interaction does not depend on gRPC vs. non-gRPC. One critical-path
  cell (P4·T1 M1 / M2) is sufficient.
- **P2 Python-only × C2/C3 custom customizations in M1.** Deferred.
  Custom-file handling is tool-agnostic and agnostic to project
  language. P1 custom-file coverage suffices; P2 custom-file is a pure
  repetition. Deferred to first real Python-project migration in
  production; surface gaps to PACK-FEEDBACK.md.
- **P5 with partial AI config on T2/T3/T4.** Deferred. Stop-condition
  logic in init-project.sh is tool-independent — verified by V-M3-10
  on T1 once.

## 2.9 Out-of-scope cells — documented rationale

- **M1 × P5.** Impossible by definition; P5 is "no AI tools", which
  contradicts the v9.3 baseline precondition of M1.
- **M2 × P5.** Impossible by definition; P5 is an existing project.
  New-project path is M2.
- **M3 × P1–P4 (already-configured).** init-project.sh stop condition
  fires before writing; exit 20. Covered by V-M3-10 on T1 as the
  representative tool test.

## 2.10 Coverage totals

| Category | Count |
|---|---|
| Critical-path cells | 16 |
| Spot-check cells | 17 |
| Deferred cells | 25 |
| Out-of-scope cells | ~150 (pruned) |
| Total meaningful cells | 58 |

The 16 critical-path cells are the Phase 4 mandatory test set. Spot-check
cells are exercised where capacity allows; their results are not
commit-blocking but failures surface as PACK-FEEDBACK.md entries.

---

*End of Part 2 — Step 9 Migration Testing Matrix.*

---

# Part 3 — Step 10: Verification Plan

*Defines the verification tests that prove each v10 deliverable is
correct. Every test names what to set up, what to run, what to check,
and what constitutes pass / fail. Organized by category so Phase 4 can
drive test execution from this section directly.*

*Every critical-path cell in Part 2 cross-references a test ID here.
Every validate-pack.py / workflow change from Steps 4, 5, 7 (Touch-Point
Inventory rows 56–61) has a verification entry.*

## 3.1 CI validation tests (V-CI-\*)

Each test is run automatically by `Validate Pack` on every push after
the corresponding validate-pack.py check is added.

| ID | Scope | Setup | Action | Pass condition | Fail condition |
|---|---|---|---|---|---|
| V-CI-01 | Check 6 — prompts-directory format (Step 4 §4.5) | Commit `project-template/docs/pack/prompts/*.md` with frontmatter and variants per Step 4 §4. | `python3 scripts/validate-pack.py` in CI | All 10 canonical prompt files pass frontmatter + variant-heading checks | Any rejection — missing frontmatter, wrong `agent:` stem, orphan variant slug, orphan `## Variant:` heading |
| V-CI-02 | Check 6 — negative cases | Deliberately commit a prompt file with `agent: reviewer` but filename `coder.md`; separate commit: missing closing `---`; separate commit: `variants: [foo]` with no matching `## Variant: foo` | `python3 scripts/validate-pack.py` | Each deliberate defect triggers the specific failure message | Silent pass |
| V-CI-03 | Check 7 — pack roster consistency (Step 5 §15.2) | Canonical `project-template/docs/pack/PM-CHAT.md` `## Pack agent roster` bulleted list matches `.claude/agents/*.md` stems | validate-pack.py | Roster-list set equals Claude agents stems set | Any drift — missing agent in list or extra entry |
| V-CI-04 | Check 7 — negative case | Temporarily add an entry to PM-CHAT.md roster that has no agent file; OR remove an entry that does | validate-pack.py | Fails with the specific mismatch message | Silent pass |
| V-CI-05 | Check 8 — reserved `x-` prefix (Step 5 §15.3) | Pack template directories contain no file or directory starting with `x-` | validate-pack.py | Zero `x-` files found in the seven scan locations | Any `x-` file in the pack template |
| V-CI-06 | Check 8 — negative case | Temporarily commit `project-template/.claude/agents/x-test.md`; OR `project-template/skills/x-test/SKILL.md`; OR `project-template/docs/pack/prompts/x-test.md` | validate-pack.py | Fails naming the file | Silent pass |
| V-CI-07 | Check 9 — BD-044 structure (Step 7 §14.1) | Pack repo has `scripts/init-project.sh` (executable), `scripts/lib/detect.sh` defining §1.3 functions, `QUICKSTART.md` + `SETUP-NEW.md` + `SETUP-EXISTING.md` + `MIGRATION-v9-to-v10.md` present, README Repository Layout names `scripts/lib/` and the `MIGRATION-vN-to-vM.md` convention | validate-pack.py | All five checks pass | Any missing file or missing layout note |
| V-CI-08 | Existing Check 1 — SKILL.md frontmatter after BD-045 renumbering (Touch-Point row 60) | After BD-045 edits to apple-architecture-core, python-best-practices, architecture-review | validate-pack.py Check 1 | No frontmatter drift; all skill files still pass | Drift — missing fields |
| V-CI-09 | Existing Check 2 — Codex TOML parsing after BD-045 edit to auditor-architecture.toml | After BD-045 scope-bullet insertion | validate-pack.py Check 2 | TOML still parses | Parse error |
| V-CI-10 | Existing Check 5 — agent-count parity after any BD-045/046 changes | Any commit touching `.claude/agents/`, `.codex/agents/`, `.gemini/agents/` | validate-pack.py Check 5 | Three directories still have identical stem sets | Divergence |

## 3.2 Manual migration tests (V-M1-\*)

One entry per Part 2 M1 critical-path cell. Each uses a seeded v9.3
fixture project.

**Shared setup for V-M1-\* tests.** A v9.3 fixture project (tagged
`fixture-v9.3-<project-type>`) checked out from a ref with the exact
v9.3 pack state. Pack repo checked out at v10-dev (or the approved v10.0
tag). Environment: `PACK=/path/to/pack`, working tree clean.

| ID | Part 2 cell | Setup specifics | Action | Pass | Fail |
|---|---|---|---|---|---|
| V-M1-01 | P1·T1·C1 | Swift-only fixture, no customizations, Claude Code CLI as PM chat | `bash "$PACK/scripts/migrate-v9-to-v10.sh"`; confirm each stage S0–S7 sentinel written; commit; run `./scripts/validate.sh` | All 7 sentinels present; report.md shows `customization: none`; post-migration `docs/pack/prompts/` has 10 files passing Check 6; trinity files contain BD-045 section + `### Custom agents` stub; monolith deleted; `_v9-backup.md` absent; validate.sh passes | Any stage fails; any expected file missing; any unexpected file modified |
| V-M1-02 | P1·T1·C2 | Fixture + seeded `x-deployer` agent trio (3 files) | Same as V-M1-01 | All three `x-deployer.*` files byte-identical after migration (diff shows zero changes); report lists them under preserved-x-files | Any byte change in x- files |
| V-M1-03 | P1·T1·C3 | Fixture + seeded `x-brokerage-api` skill (three SKILL.md files) | Same as V-M1-01 | All three skill files byte-identical; directories preserved | Any byte change or directory loss |
| V-M1-04 | P1·T1·C4 | Fixture + `x-deployer` agent + `x-brokerage-api` skill + `x-deployer.md` prompt | Same as V-M1-01 | All seven x- artifacts byte-identical | Any change |
| V-M1-05 | P1·T2·C1 | Same as V-M1-01 but the developer drives migration through the Claude Desktop app + filesystem MCP. Uses the paste-ready automated prompt from Step 6 §9.2 | Developer pastes prompt in Desktop app; Desktop + filesystem MCP executes the script and pauses per-stage for approval | Every stage approval pause renders and completes; final state matches V-M1-01 | Desktop app cannot drive the shell script; per-stage pause not rendered |
| V-M1-06 | P1·T2·C2 | Spot check — same as V-M1-05 with one custom agent | As V-M1-05 + verify x- preservation | Preserved | Changed |
| V-M1-07 | P1·T3·C1 | Codex CLI drives the migration via the automated prompt (Step 6 §9.2) | Paste prompt; Codex executes stages | Migration completes; result matches V-M1-01 | Codex cannot drive; stage pause broken |
| V-M1-08 | P1·T3·C2 | Spot check — Codex + one custom agent | Same as V-M1-07 + preservation check | Preserved | Changed |
| V-M1-09 | P1·T4·C1 | Gemini CLI drives migration via prompt | Paste prompt; Gemini executes | Matches V-M1-01 | Gemini-specific failure |
| V-M1-10 | P2·T1·C1 | Python-only fixture; Claude Code CLI | Run migration | Matches V-M1-01 modulo Python-specific stage S3 scripts (format-python.sh, validate-python.sh …) present and executable | Python scripts missing or non-executable |
| V-M1-11 | P2·T1·C4 | Python fixture + `x-` agent + skill + prompt | Run migration | All x- files preserved | Change |
| V-M1-12 | P2·T3·C1 | Python fixture on Codex CLI | Migration | Matches V-M1-10 | Codex-specific failure |
| V-M1-13 | P3·T1·C1 | Swift+Python monorepo fixture | Migration | Both Swift and Python scripts present; bootstrap runs both | Script for either language missing |
| V-M1-14 | P3·T1·C4 | Monorepo + custom agent + skill | Migration | x- preserved; monorepo scripts intact | Any regression |
| V-M1-15 | P4·T1·C1 | Swift+gRPC fixture (proto/ directory) | Migration | proto-gen.sh + validate-proto.sh present post-migration; proto/ untouched | Any proto regression |

## 3.3 Rollback rehearsal test (V-M1-ROLLBACK)

| ID | Setup | Action | Pass | Fail |
|---|---|---|---|---|
| V-M1-ROLLBACK | Completed V-M1-01 migration, committed on branch `migration-v9-to-v10` | Execute Step 6 §6.3 rollback procedure verbatim: `git revert <hash>` (or `git reset --hard <parent>` pre-push), restore backups per documented `cp` / `rm -rf` sequence, remove `docs/pack/prompts/`, remove `.pack-migration-backup/` | Post-rollback tree matches `fixture-v9.3-swift-only` byte-identically (verified by `git diff fixture-v9.3-swift-only..HEAD` = empty). `docs/pack/PROMPT-TEMPLATES.md` present; no `docs/pack/prompts/` directory; trinity files match v9.3 | Any residual v10 artifact; any v9.3 file missing |

## 3.4 Customized-PROMPT-TEMPLATES.md tests (V-M1-CUSTOM-\*)

| ID | Setup | Action | Pass | Fail |
|---|---|---|---|---|
| V-M1-CUSTOM-01 | P1·T1 fixture with PROMPT-TEMPLATES.md identical to v9.3 baseline | Run migration | `report.md` shows `customization: none`; no `_v9-backup.md` written; monolith deleted | `_v9-backup.md` written in error; or monolith retained |
| V-M1-CUSTOM-02 | P1·T1 fixture with a one-sentence addition in Template 4 (fix-cycle) | Run migration | `report.md` shows `customization: divergence detected; reconciliation flag set`; `docs/pack/prompts/_v9-backup.md` created byte-equal to the project's original monolith; monolith deleted | Backup absent; or customization overwritten |
| V-M1-CUSTOM-03 | PM chat first-run after V-M1-CUSTOM-02 | Start PM chat (Claude Code CLI); trigger pm-startup | PM chat detects `_v9-backup.md`; invokes Procedure 5-R; surfaces the customization with proposed placement in `coder.md ## Variant: fix-cycle`; upon developer approval, writes the splice and deletes `_v9-backup.md` | PM chat ignores the backup; or auto-merges without approval; or deletes the backup without writing the splice |

## 3.5 Init-project tests — new projects (V-INIT-NEW-\*)

Correspond to Part 2 M2 critical-path cells.

| ID | Part 2 cell | Setup | Action | Pass | Fail |
|---|---|---|---|---|---|
| V-INIT-NEW-01 | P1·T1 M2 (V-M2-01) | Fresh `git init` directory with optional README | `bash "$PACK/scripts/init-project.sh"`; verify preview (§3.2 format); confirm `y`; let stages S0–S10 complete | Stage verification per Step 7 §6.2 passes at every stage; blast-radius sweep §6.3 returns zero matches for `PROMPT-TEMPLATES`; trinity files have placeholders intact; `docs/pack/prompts/` has 10 canonical files; pm-chat kickoff prompt printed with project absolute path | Stage assertion fires; blast-radius sweep finds a stale `PROMPT-TEMPLATES` reference; any expected file missing |
| V-INIT-NEW-02 | P1·T2 M2 (V-M2-02) | Same fixture, Desktop app driver via filesystem MCP | Run init-project.sh via shell; PM chat kickoff prompt pasted into Desktop app | Prompt executes; kickoff proceeds | Desktop cannot execute kickoff due to prompt incompatibility |
| V-INIT-NEW-03 | P1·T4 M2 (V-M2-04) | Gemini CLI | Same | Kickoff proceeds on Gemini | Gemini-specific failure |
| V-INIT-NEW-04 | P2·T1 M2 (V-M2-05) | Fresh `git init` + `pyproject.toml` seeded (so detection classifies as existing-source Python) | Run init-project.sh | Detection classifies as existing-source Python (not new-bare); conditional removal keeps Python files and removes Swift/Proto artifacts per Step 7 §4.5; stage S9 verification passes | Python-specific files missing |
| V-INIT-NEW-05 | P3·T1 M2 (V-M2-08) | Fresh repo with both `Package.swift` and `pyproject.toml` | init-project.sh | Classified as existing-source monorepo; both language conditional sets kept | Either language pruned |

## 3.6 Init-project tests — existing projects (V-INIT-EXIST-\*)

Correspond to Part 2 M3 critical-path cells.

| ID | Part 2 cell | Setup | Action | Pass | Fail |
|---|---|---|---|---|---|
| V-INIT-EXIST-01 | P5-Swift·T1 (V-M3-01) | Real Swift project with source, README, docs/ARCHITECTURE.md, no AI config | init-project.sh | Preview report shows existing files under [SKIP] (README, Package.swift, xcodeproj, docs/ARCHITECTURE.md); [MERGE] .gitignore; [ADD] pack files; detection report includes existing-docs pointer; developer transition notice present; end-of-run prompt names docs/ARCHITECTURE.md explicitly; no existing file overwritten (byte-identical before & after for skip-list files) | Any skip-list file changed; end-of-run prompt missing existing-docs pointer |
| V-INIT-EXIST-02 | P5-Swift·T4 (V-M3-04) | Same fixture; PM chat is Gemini CLI | init-project.sh runs as shell; Gemini reads end-of-run prompt | Kickoff proceeds on Gemini; existing-docs pointer honored by PM chat | Gemini-specific regression |
| V-INIT-EXIST-03 | P5-Python·T1 (V-M3-05) | Existing Python project | init-project.sh | existing-source Python; pack lands; Swift files pruned | Any Python file touched; any Swift file remains |
| V-INIT-EXIST-04 | P5-monorepo·T1 (V-M3-07) | Existing Swift+Python monorepo | init-project.sh | Both languages detected; monorepo conditional files kept | Either language pruned |
| V-INIT-EXIST-05 | P5-Kotlin·T1 (V-M3-08) | Kotlin project | init-project.sh | Detection reports Kotlin; skill coverage section shows `NO COVERAGE` for kotlin; end-of-run prompt contains skill-gap instruction naming `kotlin`; post-run PM chat appends to `docs/pack/PACK-FEEDBACK.md` | Skill gap not reported; prompt missing gap instruction |
| V-INIT-EXIST-06 | P5-bare·T1 (V-M3-09) | Repo with README + docs/ only, no source | init-project.sh | Classified as `existing-bare`; existing docs pointed to in prompt; source-free state does not trigger stop | Classified incorrectly |
| V-INIT-EXIST-07 | Stop-condition (V-M3-10) | Existing project with `.claude/` directory present | init-project.sh | Stop procedure fires (§2.6); exit 20; no files written | Script proceeds despite AI config |

## 3.7 Inline verification assertion tests (V-INIT-VERIFY-\*)

Maps to Step 7 §6.2, §6.3 and the design requirement "inline verification
at every stage of every process."

| ID | Stage | Setup | Action | Pass | Fail |
|---|---|---|---|---|---|
| V-INIT-VERIFY-01 | S1 (directory skeleton) | Normal init run | During init | S1 check: all expected directories exist and no unexpected dirs created | Missing dir |
| V-INIT-VERIFY-02 | S2 (agent files) | Normal init | During init | `.claude/agents/`, `.codex/agents/`, `.gemini/agents/` counts equal pack template counts; stems match across three dirs | Any mismatch |
| V-INIT-VERIFY-03 | S4 (skills) | Normal init | During init | For every pack skill, three tool-dir SKILL.md present; Claude-skill body byte-identical to pack | Any missing or differing |
| V-INIT-VERIFY-04 | S5 (scripts) | Normal init | During init | All pack scripts (after §4.5 conditional removal) present and `-x` | Any non-executable |
| V-INIT-VERIFY-05 | S6 (docs/pack) | Normal init | During init | 10 prompt files + README.md + 4 other pack docs present; Step 4 §4.5 format check passes on each prompt; PLATFORM-SKILLS.md contains `## Custom agents` + `## Custom skills` headers | Any missing; any format failure |
| V-INIT-VERIFY-06 | S7 (trinity) | Normal init | During init | All three trinity files exist with at least one `[PLACEHOLDER]`; identical top-level heading set across three | Trinity asymmetry |
| V-INIT-VERIFY-07 | S8 (.gitignore) | Existing project with `.gitignore` that has 3 pack-identical lines | During init | Dedup count reports 3; pack additions section appended once; every pack line present exactly once | Duplicates; missing line |
| V-INIT-VERIFY-08 | S9 (conditional removal) | Swift-only existing-source | During init | No Python files present post-removal; all Swift files kept | Python file remains |
| V-INIT-VERIFY-09 | S10 (end-of-run prompt) | Existing-source with docs + Kotlin gap | During init | Prompt contains project absolute path, pack version string, existing-docs pointer with real filenames, skill-gap instruction naming `kotlin`, `docs/pack/prompts/pm-chat.md` variant reference | Any component missing |
| V-INIT-VERIFY-10 | Blast-radius sweep | Normal init | End of S6 and S10 | `grep -r PROMPT-TEMPLATES` in the scoped directories returns zero matches; every referenced skill/prompt/script exists; trinity routing-table parity | Any stale reference; any missing target; any trinity drift |

## 3.8 Inline verification failure-injection tests

| ID | Failure mode | Setup | Action | Pass | Fail |
|---|---|---|---|---|---|
| V-INIT-FAIL-01 | Missing pack skill between S3 and S4 | Doctor `$PACK/project-template/skills/` to remove one skill mid-run (simulated) | init-project.sh | S4 verification fails; exit 24 (= 20 + 4); diagnostic names the missing skill | Silent pass |
| V-INIT-FAIL-02 | Stale `PROMPT-TEMPLATES` reference in a pack file | Doctor a pack template to contain `PROMPT-TEMPLATES.md` reference | init-project.sh | Blast-radius sweep fails at S6 or S10; exit 31; diagnostic names the file and line | Silent pass |
| V-INIT-FAIL-03 | Trinity routing table divergence | Doctor `project-template/GEMINI.md` phase-routing agent list | init-project.sh | Blast-radius sweep trinity-parity check fails; exit 31 | Silent pass |
| V-INIT-FAIL-04 | Script collision with existing project script | Existing project has `scripts/bootstrap.sh` with different content | init-project.sh | S5 reports collision under [SKIP]; pack script skipped; script exits non-zero with clear diagnostic, OR completes with collision surfaced | Pack script silently overwrites |

## 3.9 PM chat workflow tests (V-PM5-\*)

Scripted scenarios for Procedure 5 creation, detection, and repair. Run
against a fresh v10.0 project.

| ID | Scenario | Setup | Action | Pass | Fail |
|---|---|---|---|---|---|
| V-PM5-01 | Custom agent creation — describe path (CD-4 path 1) | Fresh v10.0 project; developer tells PM chat "add a custom deployer agent for staging releases" | PM chat runs Procedure 5.1: clarifying questions (G-design), drafts three agent files + prompt file (G-files), proposes PLATFORM-SKILLS.md + trinity routing-table additions (G-registration), presents git-add list (G-commit), commits on approval | All seven artifacts created (3 agent files + prompt file + PLATFORM-SKILLS row + 3 trinity routing-table rows); all pass validate-pack.py Check 6, 7 (x- exempt per CD-5), 8 (project, not pack — exempt); .codex/config.toml untouched (Step 5 §4.2); single commit `feat: vN — add custom agent x-deployer` | Any artifact missing; config.toml modified; multiple commits |
| V-PM5-02 | Custom skill creation (Procedure 5.2) | Fresh v10.0 project; developer asks for custom `x-brokerage-api` skill for an existing pack agent | Procedure 5.2: clarifying questions, three SKILL.md drafts, PLATFORM-SKILLS.md `## Custom skills` row, commit | Three SKILL.md files byte-identical frontmatter and body; PLATFORM-SKILLS.md row correct; single commit | Drift; missing row |
| V-PM5-03 | Custom agent creation — one-tool-format seed (CD-4 path 2) | Developer provides a Claude `.md` agent file | Procedure 5.1 path 2: PM chat normalizes to pack conventions, generates Codex TOML and Gemini `.md`, generates prompt file, continues with G-registration + G-commit | Two derived files created; all three names match; commit succeeds | Asymmetry between derived files |
| V-PM5-04 | Custom agent creation — existing-file adoption (CD-4 path 3) | Developer provides a non-convention file | Procedure 5.1 path 3: PM chat reviews, presents deviations, rewrites, then path-2 workflow | Rewritten file normalized; full registration set committed | Rewrite diverges from conventions |
| V-PM5-05 | Improperly-added file detection (Procedure 5.4) | Developer hand-drops `.claude/agents/weirdagent.md` (not x-, not in pack roster); restarts PM chat | pm-startup scan classifies as Improperly added; PM chat surfaces with §10.6 phrasing; developer chooses Adopt → Procedure 5.4 routes to 5.3; file renamed to `x-weirdagent.md`; full registration completed | Classification correct; adoption completes | Missed detection; wrong classification |
| V-PM5-06 | Unregistered custom detection (Procedure 5.3) | Developer hand-drops `.claude/agents/x-deployer.md` only (missing codex, gemini, prompt, registration); restarts PM chat | pm-startup scan classifies as Unregistered custom; PM chat lists missing artifacts per §10.4; developer approves reconstruction; Procedure 5.3 completes | Missing artifacts enumerated correctly; reconstruction produces full set | False classification; missing items |
| V-PM5-07 | Registration-repair deferral | As V-PM5-06 but developer chooses Defer | PM chat flags, continues; next pm-startup re-flags | Flag persists across sessions | Flag disappears silently |
| V-PM5-08 | Codex config.toml non-edit confirmation | V-PM5-01 completed | Inspect `.codex/config.toml` | File byte-identical to pack template copy; no `[agents.*]` lines added | Any edit |
| V-PM5-09 | Pack roster drift detection | Hand-edit `docs/pack/PM-CHAT.md` roster to list a non-existent agent | validate-pack.py in pack CI | Check 7 fails | Silent pass |
| V-PM5-10 | Phase-gate detection scan | Mid-phase, developer drops an x- file between sessions; next phase gate runs Procedure 5 §10.7 | PM chat phase-gate step 5a | Scan surfaces the new file; pauses for decision before prompt generation | Phase proceeds silently |

## 3.10 Prompt template migration correctness (V-PROMPT-\*)

Proves that every v9.3 template ends up in the right per-agent file with
no content lost.

| ID | What it checks | Setup | Action | Pass | Fail |
|---|---|---|---|---|---|
| V-PROMPT-01 | Before/after token count | v9.3 monolith (6,482 proxy tokens per Step 4 §1.1) vs. sum of the 10 v10 per-agent file proxy tokens | `wc -w` × 1.3 on both | Total content size matches within ±5% (slight drop due to hoisting Prompt Authoring Principles per Step 4 §2.4) | Drift > 5%; content loss |
| V-PROMPT-02 | Every v9.3 Template 1–14 accounted for | v9.3 `PROMPT-TEMPLATES.md` vs. v10 `docs/pack/prompts/` | Manual line-by-line check using Step 4 §1.2 destination map | Every template's content present in the mapped per-agent file under the mapped variant slug; T10–T12 supersession note present in auditor.md | Any template content missing from destination |
| V-PROMPT-03 | v9.x incremental additions carried forward | v9.3 baseline | Manual check | T1 BD-038 active-skills instruction present in `pm-chat.md ## Variant: kickoff`; T8 STATUS.md phase-title linking rule present in `pm-chat.md ## Variant: backlog-status-update`; BD-043 Gemini references preserved throughout | Any v9.x addition lost |
| V-PROMPT-04 | No content corruption | v10 pack prompts | Each file passes validate-pack.py Check 6 | All 10 files plus `README.md` pass | Any file fails |
| V-PROMPT-05 | Custom prompt format parity | Fixture with v10 pack + a PM-chat-created `x-deployer.md` (Step 5 §6.2 worked example) | validate-pack.py Check 6 | x- file passes identical format check | Fails on x- file |

## 3.11 x- file preservation test (V-X-PRESERVE)

| ID | Setup | Action | Pass | Fail |
|---|---|---|---|---|
| V-X-PRESERVE-01 | v9.3 fixture with 3 x- agent files (trio), 3 x- skill directories, 0 x- prompt files (directory didn't exist in v9.3) | Run migrate-v9-to-v10.sh | All six x- artifacts byte-identical before and after migration (`diff` returns empty); `docs/pack/prompts/` is created and populated with 10 canonical pack prompts; no `x-` prompt is created spuriously | Any byte change |
| V-X-PRESERVE-02 | Synthetic v10.x fixture with x- prompt | Upgrade to a later v10.y | x- prompt preserved byte-identical | Change |
| V-X-PRESERVE-03 | Stray x- file inside pack skill dir (`.claude/skills/planning/x-extra.md`) | Run migration | Pre-flight stops per Step 6 §1.6; developer guidance printed; no write | Silent pass or partial write |

## 3.12 BD-045 content review tests (V-BD045-\*)

| ID | Scope | Action | Pass | Fail |
|---|---|---|---|---|
| V-BD045-01 | Trinity-rule diff | `diff` the `## Capabilities pattern` section across CLAUDE.md / AGENTS.md / GEMINI.md in the v10 pack template | Section text byte-identical across the three files | Any semantic divergence |
| V-BD045-02 | Trinity-rule diff on anti-pattern bullet | `diff` the "Branching on concrete types…" bullet across three trinity files | Byte-identical | Any divergence |
| V-BD045-03 | Language-agnostic review of anti-pattern wording | Read the trinity `## Capabilities pattern` section and the anti-pattern bullet | No language-specific syntax in the trinity wording (no `OptionSet`, no `Protocol`, no `isinstance`, etc.); pattern intent stated in language-agnostic terms | Any language-specific example in trinity-scope text |
| V-BD045-04 | Per-language skill coverage | Read apple-architecture-core rules 11–14, python-best-practices rules 14–17, architecture-review rules 14–17 | Each rule set names both value-based and interface-based forms using idiomatic language examples; each names where capability validation belongs | Missing form; missing placement rule |
| V-BD045-05 | Auditor-architecture trio — scope bullet symmetry | `diff` the bullet text across the three auditor-architecture files | Claude & Gemini markdown bullets byte-identical; Codex plain-bullet semantically identical to Step 3 §7.2 text | Semantic divergence |
| V-BD045-06 | LSP-vs-capabilities statement accuracy | Read every location where the relationship is stated (Step 3 §9) | Each location uses BD-045 formulation verbatim or closely paraphrased; never softens to "capabilities is LSP escape hatch"; always states "both required, independently" | Any location misstates the relationship |
| V-BD045-07 | Renumbering integrity | Grep for rule-number references across the three modified skills and across every file that could reference them | Every numeric rule reference still points at the intended content post-renumber | Stale reference after renumber |

## 3.13 init-project.sh inline verification assertions (V-INIT-ASSERT-\*)

Every Step 7 §6.2 row and §6.3 blast-radius sweep is a testable
assertion. Below is the consolidated assertion list (grouped by stage
for Phase 4 to exercise in sequence). Most rows map to a V-INIT-VERIFY-\*
test above; this section is the canonical list of assertions as
implemented inside init-project.sh itself.

| Stage | Assertion (from Step 7 §6.2) | Tested by |
|---|---|---|
| S0 | Confirmation was explicit `y/Y/yes`; `$PACK` valid; target is git repo; AI config still empty | V-INIT-NEW-01 setup check |
| S1 | All expected directories created; no extras | V-INIT-VERIFY-01 |
| S2 | Claude / Codex / Gemini agent counts equal pack counts; trinity stem parity | V-INIT-VERIFY-02 |
| S3 | `config.toml`, `settings.json`, `.mcp.json.example` exist non-empty; `config.toml` contains `[profile` header | Embedded in V-INIT-NEW-01 |
| S4 | Every pack skill has SKILL.md in three tool dirs; Claude-skill body byte-identical | V-INIT-VERIFY-03 |
| S5 | All post-conditional-removal scripts present with `-x`; `agent-run.sh` executable | V-INIT-VERIFY-04 |
| S6 | 10 prompt files present + 4 docs; each prompt passes Step 4 §4.5 check; PLATFORM-SKILLS.md has custom sections | V-INIT-VERIFY-05 |
| S7 | Trinity exists; placeholders present; top-level heading set identical across three | V-INIT-VERIFY-06 |
| S8 | Every pack-.gitignore line present verbatim; dup-count accurate | V-INIT-VERIFY-07 |
| S9 | For each non-detected language, no pack file for that language exists | V-INIT-VERIFY-08 |
| S10 | Generated prompt contains all required components per Step 7 §6.2 S10 | V-INIT-VERIFY-09 |

## 3.14 Blast-radius sweep assertion (V-BLAST-\*)

From Step 7 §6.3. Each row is a testable assertion with an expected
zero-match result against a correctly-installed v10 pack.

| ID | Sweep | Expected result on correct pack | Failing result |
|---|---|---|---|
| V-BLAST-01 | `grep -r PROMPT-TEMPLATES` across `.claude/ .codex/ .gemini/ docs/pack/ CLAUDE.md AGENTS.md GEMINI.md agent-run.sh scripts/` | Zero matches | Any hit |
| V-BLAST-02 | Placeholder baseline — record `[PLACEHOLDER]` counts in files the script should NOT have filled | Diagnostic only; captures baseline | Only fails if baseline regression (e.g., a file the pack should ship with no placeholders gains one) |
| V-BLAST-03 | Every skill referenced in PLATFORM-SKILLS.md exists in `.claude/skills/`, `.codex/skills/`, `.gemini/skills/` | All present | Any missing |
| V-BLAST-04 | Every prompt file referenced from PM-CHAT.md / CLAUDE.md / AGENTS.md / GEMINI.md exists in `docs/pack/prompts/` | All present | Any missing |
| V-BLAST-05 | Every script referenced from trinity "Scripts" tables exists in `scripts/` (accounting for conditional removal) | All present | Any missing |
| V-BLAST-06 | Trinity routing-table agent set parity | Three sets identical | Any divergence |

The blast-radius sweep also runs once at pack-repo CI time (as the
touch-point inventory rows 56–61 CI checks) to prevent the pack itself
from ever shipping a stale cross-reference. V-CI-01 through V-CI-10
are the CI counterparts.

## 3.15 Incremental-testability contract verification (V-INC-\*)

Every migration stage leaves the project in a testable state
(Step 6 §7).

| ID | Stage | Test |
|---|---|---|
| V-INC-01 | S0 pre-flight | `git status` shows only `.pack-migration-backup/` untracked |
| V-INC-02 | After S1 | `./agent-run.sh --help` runs; each pack agent invocation succeeds on a trivial task |
| V-INC-03 | After S2 | Skills visible to each tool (Claude live detection; Gemini `/skills reload`; Codex next session) |
| V-INC-04 | After S3 | `./scripts/bootstrap.sh` runs; `./scripts/validate.sh` runs |
| V-INC-05 | After S4 | `docs/pack/prompts/` exists; Step 4 §4.5 check passes on all 10 files |
| V-INC-06 | After S5 | Trinity-rule CI check passes locally; `git diff` shows only pack-owned region changes |
| V-INC-07 | After S6 | Migration report shows `customization: none` or `divergence detected`; backup exists |
| V-INC-08 | After S7 | Report file written with every required section (Step 6 §8.9) |
| V-INC-09 | Resumability | Kill the script mid-stage; re-invoke; verify it reads sentinel files and resumes correctly |

## 3.16 Verification plan maintenance rule (V9 Lesson 4)

Per V9 Lesson 4 — "the verification plan is prescriptive and must be
kept current":

> **If any v10 design decision is reversed in a v10.x patch, update
> this verification plan, not only the operational docs.**

Concretely: any commit that modifies V10-DESIGN.md, METHODOLOGY.md
Procedure 5 / 5-R, migrate-v9-to-v10.sh, init-project.sh, the format
rules in Step 4 §4, or the preservation rules in Step 6 §4–5 must also
update the corresponding V-\* test(s) in this Part 3 in the same commit.
Pack CI should include a soft-check (not hard-fail) that flags commits
touching those files without a matching edit to `maintenance-docs/v10-working/step-08-09-10-consolidation.md`
or its successor verification doc in V10-DESIGN.md.

This rule is itself promoted into V10-DESIGN.md Part 10 at Step 11
assembly.

## 3.17 Coverage summary — Part 2 cells to Part 3 tests

Every critical-path cell in Part 2 has at least one Part 3 verification
test. The mapping is embedded in Part 2 (cell content of form
`CP[V-M1-01]` etc.). Consolidated back-reference:

| Part 3 test group | Part 2 cells covered |
|---|---|
| V-M1-\* | 16 critical-path M1 cells |
| V-M2-\* → V-INIT-NEW-\* | 5 critical-path M2 cells |
| V-M3-\* → V-INIT-EXIST-\* | 7 critical-path M3 cells |
| V-PM5-\* | Custom-agent-creation outcome (all four PM chat tools via sub-tests) |
| V-BD045-\* | Non-matrix BD-045 content coverage |
| V-PROMPT-\* | Non-matrix prompt-migration coverage |
| V-X-PRESERVE-\* | Custom-file-state × M1 coverage |
| V-M1-ROLLBACK | Rollback design requirement coverage |
| V-CI-\* | validate-pack.py + workflow (Steps 4, 5, 7) |
| V-INIT-VERIFY-\*, V-INIT-FAIL-\*, V-INIT-ASSERT-\* | Step 7 §6 per-stage + blast-radius + failure-injection |
| V-INC-\* | Step 6 §7 incremental testability |
| V-BLAST-\* | Step 7 §6.3 blast-radius sweep |

No critical-path cell is unmapped.

---

## 3.18 Summary

- **CI validation (§3.1).** Ten tests cover Checks 1 (unchanged), 2 (unchanged), 5 (unchanged), 6 (new, prompts format), 7 (new, pack roster), 8 (new, reserved x-), 9 (new, BD-044 structure).
- **Manual migration (§3.2).** Fifteen tests; 16 critical-path cells from Part 2 M1; rollback rehearsal (§3.3); customized-PROMPT-TEMPLATES handling (§3.4).
- **Init-project tests (§3.5, §3.6).** Twelve tests cover M2 and M3 critical-path cells including stop condition and skill-gap reporting.
- **Inline verification (§3.7, §3.8, §3.13).** Per-stage assertions and failure-injection tests exercise Step 7 §6 at every stage.
- **PM chat workflow (§3.9).** Ten scripted scenarios cover all three CD-4 creation paths, custom skill creation, manual-add detection, registration repair, Codex config.toml non-edit confirmation, phase-gate scan.
- **Prompt migration correctness (§3.10).** Token count before/after; every Template 1–14 accounted for; v9.x additions carried forward; no corruption.
- **x- preservation (§3.11).** Byte-identical preservation through migration.
- **BD-045 content review (§3.12).** Trinity diff; language-agnostic audit; LSP-vs-capabilities statement audit; renumbering integrity.
- **Blast-radius sweep (§3.14).** Testable zero-match assertions for stale references.
- **Incremental testability (§3.15).** Per-stage migration state verification.
- **V9 Lesson 4 rule (§3.16).** Verification plan maintenance is a first-class commit obligation.
- **Coverage (§3.17).** Every Part 2 critical-path cell maps to at least one Part 3 test.

---

*End of Part 3 — Step 10 Verification Plan.*

---

*End of step-08-09-10-consolidation.md.*
