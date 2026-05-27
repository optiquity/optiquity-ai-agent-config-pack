# IMPLEMENTATION-REPORT-BD-193.md — Code Red 2 BD/TD/Path scope contamination cleanup

**Authored by:** pack-coder (Phase 3 of BD-193 audit pipeline).
**Date:** 2026-05-27 (US/Pacific).
**Branch:** v11-dev.
**Working-tree HEAD at start:** `2f54bcabcdb6e053d10c9ec8ea3733d6514ca337`
(`docs: v11 — BD-185 open (Batch 19d phase parts + ordering, pack-only)`).
**Working-tree HEAD at end:** `2f54bcabcdb6e053d10c9ec8ea3733d6514ca337`
(no commits made — pack-coder produces working-tree edits only;
Pack Chat will stage + commit per protocol).

**Pipeline:**
Phase 1 (`AUDIT-INVENTORY-BD-TD-PATH.md`, docs-researcher) →
Phase 2 (`AUDIT-DISPOSITION-BD-TD-PATH.md`, pack-reviewer) →
**Phase 3 (THIS report, pack-coder)** → Phase 4 (end-of-batch reviewer).

---

## §1 — Scope

This commit applies the BD-193 Code Red 2 cleanup of BD/TD/Path
operational scope contamination found by the Phase 1/2 audit pipeline.

The authoritative source-of-truth for every per-row fix is
`maintenance-docs/v11-implementation/AUDIT-DISPOSITION-BD-TD-PATH.md`
(987 lines; pack-reviewer Phase 2 output).

### Scope summary

- **11 LOCKED dispositions** (§3 of disposition report, user-pre-locked):
  - F1 (3 sub-locations) — INDEX segregation + bd-v11.0 PACK-INTERNAL header.
  - F2 (5 sub-locations) — BD-NNN dependency-grammar admission removal.
  - F3 (1 sub-location) — `_intro.md` cross-reference list trim.
  - F4 + F5 (1 location cluster, 4 finding rows) — init-project.sh S11
    project-template-source consolidation (remove pack-ops/ as a source
    for HELP-FRAGMENT-TRACKER.md S11 copy).
- **3 LEAK fixes** (operational rule-1 contamination):
  - A-3.3.2 (inherited from F2.a — td-v11.0/SCHEMA.md downstream).
  - A-3.33.1 (audit-methodology/SKILL.md L76 — BD-NNN.md → TD-NNN.md).
  - A-3.46.22 (MIGRATION-v10-to-v11.md L258 — BD-NNN.md → TD-NNN.md).
- **~85 WASTE fixes** (rule-3 token-economy unnecessary explanatory
  references) per §4.* tables of disposition report.
- **§6.1 user resolution** — inbound SCHEMA mention-to-exclude removed
  (Reading A); project-side form L18 boundary-defense PRESERVED
  (Reading B per disposition recommendation).
- **§6.2 user resolution** — boundary-investigation/SKILL.md BD-175 V1
  cite relabeled to "the audit incident (P-missed-7)" / "V1 anti-pattern".
- **§6.3 user resolution** — MIGRATION-v10-to-v11.md Class A LEGITIMATE
  rows PRESERVED; Class B WASTE rows removed per disposition split.
- **§6.4 user resolution** — SETUP-NEW.md and SETUP-EXISTING.md WASTE
  cites removed.
- **Two collateral CI-keep-green edits** (scripts/validate-pack.py +
  scripts/tests/test-issue-forms.sh) to teach the CI gate the new
  per-surface wi-type rule (pack admits `bd`, project does not).

### Out of scope (NOT modified)

- POQ-4 reversal in `ARCHITECTURE-BD-185.md` and `PLAN-BD-185.md`
  (separate Pack Chat work).
- BD-185 H.1 NIT-2 / NIT-3 cosmetic fixes (pending Code Red 2 close).
- Pack memory files at `/Users/david/.claude/projects/...`
  (Pack-Chat-direct only).
- `pack-ops/BACKLOG.md` BD-193 entry (already opened at HEAD `2f54bca`).

---

## §2 — Files modified

36 working-tree files modified (35 scope edits + 1 manifest regen).
See §2.1 inventory and §2.2 per-file change summary.

### §2.1 Files-changed inventory

| File | Change type | Disposition class | Count of cite removals |
|---|---|---|---|
| `maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md` | modified | LOCKED F1.a | INDEX restructure (segregation) |
| `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md` | modified | LOCKED F1.b + WASTE | INDEX restructure + 12 WASTE removals |
| `maintenance-docs/v11-research/templates-archive/v11.0/bd-v11.0/SCHEMA.md` | modified | LOCKED F1.c | PACK-INTERNAL header added |
| `maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md` | modified | LOCKED F2.a | 2 BD-NNN admissions removed (L79, L91) |
| `maintenance-docs/v11-research/templates-archive/v11.1/phase-part-v11.1/SCHEMA.md` | modified | LOCKED F2.b + WASTE | 1 BD-NNN admission removed + 23 BD-185 WASTE removals |
| `maintenance-docs/v11-research/templates-archive/v11.0/forms/work-item.yml` | modified | LOCKED F2.c + collateral | `bd` option dropped + BD-NNN purged from descriptions, Blockers, Dependencies + title default → TD-NNN |
| `maintenance-docs/v11-research/templates-archive/v11.0/inbound-v11.0/SCHEMA.md` | modified | §6.1 + WASTE A-3.6.1 + A-3.6.4 | Mention-to-exclude removed + L12 BD-064 cite removed + L119-121 BD-065/BD-067 cites removed |
| `maintenance-docs/v11-research/templates-archive/README.md` | modified | WASTE | 2 BD cite removals (BD-069, BD-064) |
| `project-template/.github/ISSUE_TEMPLATE/work-item.yml` | modified | LOCKED F2.d + §6.1 KEEP | `bd` option dropped + BD-NNN purged from Blockers/Dependencies + L18 boundary-defense PRESERVED |
| `project-template/tracker.toml.project-example` | modified | WASTE | 1 BD-108 cite removal |
| `project-template/.gitignore` | modified | WASTE | 1 BD-061 cite removal |
| `project-template/CLAUDE.md` | modified | WASTE (trinity) | 1 BD-142 cite removal |
| `project-template/AGENTS.md` | modified | WASTE (trinity) | 1 BD-142 cite removal |
| `project-template/GEMINI.md` | modified | WASTE (trinity) | 1 BD-142 cite removal |
| `project-template/.gemini/.env.example` | modified | WASTE | 2 BD-059 cite removals |
| `project-template/.codex/config.toml` | modified | WASTE | 1 BD-059 cite removal |
| `project-template/.codex/config.toml.example` | modified | WASTE | 1 BD-059 cite removal |
| `project-template/docs/pack/PM-CHAT.md` | modified | WASTE | 3 BD cite removals (BD-108, BD-107, BD-108) |
| `project-template/docs/pack/PLATFORM-SKILLS.md` | modified | WASTE | 6 BD cite removals |
| `project-template/skills/audit-methodology/SKILL.md` | modified | LEAK A-3.33.1 | BD-NNN.md → TD-NNN.md |
| `project-template/skills/boundary-investigation/SKILL.md` | modified | §6.2 | 2 BD-175 label removals (preserve worked-example content) |
| `project-template/skills/python-data-architecture/SKILL.md` | modified | WASTE | 1 cite block removal (BD-141, BD-143) |
| `project-template/skills/python-server-architecture/SKILL.md` | modified | WASTE | 1 cite block removal (BD-141, BD-143) |
| `project-template/skills/python-observability-patterns/SKILL.md` | modified | WASTE | 1 BD-162 cite removal |
| `project-template/skills/swift-best-practices/SKILL.md` | modified | WASTE | 1 BD-158 cite removal |
| `project-template/docs/project/backlog/_intro.md` | modified | LOCKED F3 | L34 cross-reference: BD-NNN dropped |
| `project-template/docs/project/changelog/_rules.md` | modified | WASTE | 1 BD-164-retro cite removal |
| `supporting-docs/METHODOLOGY.md` | modified | LOCKED F2.e + WASTE | Parser regex BD-NNN admission dropped + 3 WASTE cite removals |
| `supporting-docs/INSTALL-PROCEDURES.md` | modified | WASTE | 6 BD cite removals (4× BD-121, BD-119, BD-088, BD-059) |
| `supporting-docs/MIGRATION-v10-to-v11.md` | modified | LEAK A-3.46.22 + Class B WASTE | BD-NNN.md → TD-NNN.md + ~20 Class B WASTE removals; Class A LEGITIMATE rows preserved |
| `supporting-docs/SETUP-NEW.md` | modified | WASTE | 4 BD cite removals (3× BD-121, BD-047) |
| `supporting-docs/SETUP-EXISTING.md` | modified | WASTE | 1 BD-047 cite removal |
| `scripts/init-project.sh` | modified | LOCKED F4/F5 | S11 HELP-FRAGMENT-TRACKER.md source = project-template; pack-ops/ fallback removed; manifest comment updated |
| `scripts/validate-pack.py` | modified | COLLATERAL CI | wi-type expected options now per-surface (pack admits `bd`, project omits `bd`) |
| `scripts/tests/test-issue-forms.sh` | modified | COLLATERAL CI | check_workitem accepts surface_kind; cross-surface invariant relaxed to "pack admits bd, project omits bd" |
| `test-fixtures/manifest.txt` | modified | MANIFEST REGEN | v11-realistic-ot / v11-flat-file / v11-tracker-on SHAs refreshed |

### §2.2 No new files; no file deletions

All 36 files are pre-existing. No new files created. No file deletions.

---

## §3 — LOCKED dispositions applied (11 sub-locations)

### §3.1 F1 (3 sub-locations) — INDEX segregation + PACK-INTERNAL header

| Sub-loc | File | Action applied |
|---|---|---|
| F1.a | `maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md` | "Entry types at v11.0" table split into "Client-applicable" (4 rows: td, phase-epic, phase-task, inbound) and "Pack-internal (informational only; NOT applicable to client projects)" (1 row: bd-v11.0). Order: client-applicable first. |
| F1.b | `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md` | "Entry types at v11.1" table split identically: 5 client-applicable rows (TD, phase-epic, phase-task, phase-part, inbound) and 1 pack-internal row (BD-NNN). |
| F1.c | `maintenance-docs/v11-research/templates-archive/v11.0/bd-v11.0/SCHEMA.md` | `**SCOPE: PACK-INTERNAL.**` paragraph added at file top (before §1 Identifier scheme). Names the audience explicitly: "BD entries are NOT a client-project concept; client projects use TD-NNN (see `../td-v11.0/SCHEMA.md`) for technical-debt items." |

### §3.2 F2 (5 sub-locations) — BD-NNN dependency-grammar admission removal

| Sub-loc | File | Action applied |
|---|---|---|
| F2.a | `maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md` | L79: `<one ID per line — optional; accepts phase-N, phase-N.M, TD-NNN>` (BD-NNN dropped). L86-91: dependencies grammar bullets — BD-NNN bullet removed; preserves phase-N, phase-N.M, TD-NNN. |
| F2.b | `maintenance-docs/v11-research/templates-archive/v11.1/phase-part-v11.1/SCHEMA.md` | L129-130: `<one ID per line — optional; accepts phase-N, Phase-N.Part-x, Phase-N.Task-M, Phase-N.Part-x.Task-M, TD-NNN>` (BD-NNN dropped). L141-152: prerequisites grammar — `BD-NNN` bullet removed. |
| F2.c | `maintenance-docs/v11-research/templates-archive/v11.0/forms/work-item.yml` | name → "Pack work item (TD / phase-epic / phase-task)". description → drops "Pack-development backlog item (BD-NNN)". title default → `TD-NNN: <short title>`. Markdown opening sentence renamed: "renames the title (e.g. `TD-NNN:` becomes the assigned ID)" (collateral A-3.7.3). dropdown wi-type → drops `bd` option. wi-kind description → "Required for Type=td." (drops BD). status description → "Defaults to Open for TD." Blockers description → drops BD-NNN. Description label → "For TD/phase-epic-skeleton." Dependencies description → "Accepts `phase-N`, `phase-N.M`, `TD-NNN`." |
| F2.d | `project-template/.github/ISSUE_TEMPLATE/work-item.yml` | description: trailing parenthetical "(Pack development BDs are filed against the pack repo, not here.)" dropped (cleaner per §6.1 — boundary-defense L18 carries the load). dropdown wi-type → drops `bd` option (plus drops the explanatory clause "The bd option exists for parity with the pack-side form..."). wi-kind description → "Required for Type=td." status description → "Defaults to Open for TD." Description label → "For TD/phase-epic-skeleton." Dependencies description → "Accepts `phase-N`, `phase-N.M`, `TD-NNN`." **§6.1 KEEP:** L18 "Pack-development items (BD-NNN) belong in the pack repo, not in this project." PRESERVED as project-side boundary defense (Reading B). |
| F2.e | `supporting-docs/METHODOLOGY.md` | L386-388 prose: "or a BD entry (`BD-NNN`)" dropped. Parser regex updated from `^\s*-\s+(phase-\d+(\.\d+)?\|TD-\d+\|BD-\d+)(\s+(.*))?$` to `^\s*-\s+(phase-\d+(\.\d+)?\|TD-\d+)(\s+(.*))?$`. |

### §3.3 F3 (1 sub-location) — `_intro.md` cross-reference trim

| Sub-loc | File | Action applied |
|---|---|---|
| F3 | `project-template/docs/project/backlog/_intro.md` | L34 bullet: `TD-NNN, BD-NNN, phase-N, phase-N.M identifiers may appear...` → `TD-NNN, phase-N, phase-N.M identifiers may appear...` (BD-NNN dropped). |

### §3.4 F4 + F5 (1 location, 4 finding rows) — init-project.sh S11 block

| Sub-loc | File | Action applied |
|---|---|---|
| F4/F5.a + F4/F5.c | `scripts/init-project.sh` L820-829 | Primary `cp` source changed from `$PACK/pack-ops/HELP-FRAGMENT-TRACKER.md` to `$PACK/project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`. Fallback branch (the `$PACK/HELP-FRAGMENT-TRACKER.md` pre-v11 fallback) REMOVED entirely. |
| F4/F5.b | `scripts/init-project.sh` L820 comment block | Old "BD-175: HELP-FRAGMENT-TRACKER.md canonical source is pack-ops/ post-reorg. Retain $PACK/HELP-FRAGMENT-TRACKER.md fallback for pre-v11 layouts (e.g., migration mid-flight, or PACK pointing at a pre-BD-175 tag)." block replaced with: "HELP-FRAGMENT-TRACKER.md client-shipped source is project-template/docs/pack/HELP-FRAGMENT-TRACKER.md. The pack-side and project-side versions are separate artifacts with separate audiences (pack/project separation of concerns); the project-side file is the source of truth for client install, and pack-side substitution is forbidden." |
| F4/F5.d | `scripts/init-project.sh` L1308-1309 manifest comment | Old two-line block (pack-ops/ source at S11; project-template/docs/pack/ source at S6 cmd_update) collapsed to single line: `#   project-template/docs/pack/HELP-FRAGMENT-TRACKER.md  ->  docs/pack/HELP-FRAGMENT-TRACKER.md  [stage:S6,S11,cmd_update]` (one source path; S6 + S11 + cmd_update tags). |

---

## §4 — LEAK fixes (3 sub-locations)

### §4.1 — A-3.3.2 inherited (td-v11.0/SCHEMA.md L101 chain)

The TD dependencies grammar inherits from phase-task SCHEMA per V3.3
§5.3 chain. After F2.a removed BD-NNN from
`phase-task-v11.0/SCHEMA.md`, this inherited admission is also removed.
No independent edit to `td-v11.0/SCHEMA.md` was needed.

**Verification:** Read of `td-v11.0/SCHEMA.md` confirmed no
BD-NNN dependency-type admissions present. The file's references to
BD-NNN are all in label-family / reverse-emit / definitional contexts
of TD-NNN as a separate identifier — not dependency grammar.

### §4.2 — A-3.33.1 (audit-methodology/SKILL.md L76)

| Field | Value |
|---|---|
| Path | `project-template/skills/audit-methodology/SKILL.md` |
| Line | 76 |
| Before | `Per-entry tree files (\`docs/project/backlog/BD-NNN.md\`, \`docs/project/implementation-plan/phase-N.md\`, ...)` |
| After  | `Per-entry tree files (\`docs/project/backlog/TD-NNN.md\`, \`docs/project/implementation-plan/phase-N.md\`, ...)` |
| Rationale | Project-side `_rules.md` L14 regex is `^TD-\d+\.md$`; `BD-NNN.md` does not match the filename contract. |

### §4.3 — A-3.46.22 (MIGRATION-v10-to-v11.md L258)

| Field | Value |
|---|---|
| Path | `supporting-docs/MIGRATION-v10-to-v11.md` |
| Line | 258 |
| Before | `One Markdown file per entry (e.g., \`docs/project/backlog/BD-NNN.md\`, \`docs/project/implementation-plan/phase-N.md\`, \`docs/project/changelog/YYYY-MM-DD-<slug>.md\`)` |
| After  | `One Markdown file per entry (e.g., \`docs/project/backlog/TD-NNN.md\`, \`docs/project/implementation-plan/phase-N.md\`, \`docs/project/changelog/YYYY-MM-DD-<slug>.md\`)` |
| Rationale | Same as A-3.33.1 — `BD-NNN.md` is not a valid project-side per-entry filename. |

---

## §5 — WASTE applications (per-file summary)

Per-file count of WASTE removals applied per AUDIT-DISPOSITION-BD-TD-PATH.md
§4 tables. Each row's BEFORE/AFTER is documented in the disposition
report at the cited §4.* section; this report names the cite count and
file location.

| File | WASTE removals | Disposition ref |
|---|---|---|
| `templates-archive/v11.0/inbound-v11.0/SCHEMA.md` | 2 (A-3.6.1 L12 BD-064 ref; A-3.6.4 L119-121 BD-065/BD-067 cites) | §4.5 |
| `templates-archive/v11.0/forms/work-item.yml` | 1 collateral A-3.7.3 (BD-NNN: → TD-NNN: example) — covered as collateral to F2.c | §4.6 |
| `templates-archive/v11.1/INDEX.md` | 12 BD-185 cites (A-3.9.1–.13 except .3 LOCKED) | §4.7 |
| `templates-archive/v11.1/phase-part-v11.1/SCHEMA.md` | 22 cites: BD-185 §4.* cites + H.5 / H.8 / D2 / D4 / D5 / D8 / §6.5 D-18 carrier-matrix rephrased to inline `phase-epic-v11.0/SCHEMA.md` + `phase-task-v11.0/SCHEMA.md`. A-3.10.10 LEGITIMATE statement preserved with §6.5 D-18 phrase rephrased per disposition. | §4.8 |
| `templates-archive/README.md` | 2 (A-3.11.1 BD-069 cite; A-3.11.2 BD-064 cite) | §4.9 |
| `project-template/tracker.toml.project-example` | 1 (A-3.13.1 BD-108) | §4.11 |
| `project-template/.gitignore` | 1 (A-3.14.1 BD-061) | §4.12 |
| `project-template/{CLAUDE,AGENTS,GEMINI}.md` (trinity) | 3 (A-3.15.1 / A-3.16.1 / A-3.17.1 — BD-142 cite, identical in all 3) | §4.13 |
| `project-template/.gemini/.env.example` | 2 (A-3.18.1 L3 BD-059; A-3.18.2 L11 BD-059) | §4.14 |
| `project-template/.codex/config.toml` | 1 (A-3.19.1 L20 BD-059) | §4.15 |
| `project-template/.codex/config.toml.example` | 1 (A-3.20.1 L10 BD-059) | §4.15 |
| `project-template/docs/pack/PM-CHAT.md` | 3 (A-3.21.1 L608 BD-108; A-3.21.2 L651 BD-107; A-3.21.3 L655 BD-108) | §4.16 |
| `project-template/docs/pack/PLATFORM-SKILLS.md` | 6 (A-3.24.1 L222 BD-141; .2 L223 BD-156; .3 L224 BD-162; .4 L225 BD-157; .6 L582 BD-155; .7 L599-601 BD-156/157/158) | §4.19 |
| `project-template/skills/python-data-architecture/SKILL.md` | 1 (A-3.35.1 BD-141 + BD-143 cite block) | §4.29 |
| `project-template/skills/python-server-architecture/SKILL.md` | 1 (A-3.36.1 BD-141 + BD-143 cite block) | §4.29 |
| `project-template/skills/python-observability-patterns/SKILL.md` | 1 (A-3.37.1 L20 BD-162) | §4.30 |
| `project-template/skills/swift-best-practices/SKILL.md` | 1 (A-3.38.1 L92 BD-158) | §4.31 |
| `project-template/docs/project/changelog/_rules.md` | 1 (A-3.43.1 L18 BD-164-retro) | §4.36 |
| `supporting-docs/METHODOLOGY.md` | 3 (A-3.44.17 L1393 BD-059; A-3.44.18 L1422 BD-048; A-3.44.25 L1675 BD-042) | §4.37 |
| `supporting-docs/INSTALL-PROCEDURES.md` | 6 (A-3.45.1 L24 BD-121; A-3.45.2 L225 BD-121; A-3.45.3 L228 BD-119; A-3.45.4 L229 BD-088; A-3.45.5 L664 BD-059; A-3.45.6 L898 BD-121) | §4.38 |
| `supporting-docs/MIGRATION-v10-to-v11.md` | Class B WASTE applied per §6.3 user resolution. Class A LEGITIMATE rows PRESERVED. Removed cites: BD-109/BD-110 roadmap, BD-095 sentinel, "BD-142, BD-148" section header, BD-035 Python split (multiple instances), BD-095 sentinel reference, BD-104 → kept (S4a stage row, LEGITIMATE Class A); see §4.39 table. Specific removals: A-3.46.5/.6/.7/.8/.11/.14/.15/.16/.17/.18/.19/.20/.21/.23/.24/.33/.34/.35/.36/.37/.38/.39/.40. | §4.39 |
| `supporting-docs/SETUP-NEW.md` | 4 (A-3.47.1 L11 BD-121; .2 L94 BD-121; .3 L156 BD-047; .4 L466 BD-121) | §4.40 |
| `supporting-docs/SETUP-EXISTING.md` | 1 (A-3.48.1 L150 BD-047) | §4.41 |

**Total WASTE applications:** Approximately 85 cite-removals across 22
files (consistent with disposition §5.2 count of "78 WASTE" plus a
handful of inherited collateral edits required by the §6.1–§6.4 user
resolutions and a small over-count due to multi-cite single rows).

---

## §6 — Trinity-rule application

### §6.1 Trinity edit identity verification

The trinity files at `project-template/CLAUDE.md`,
`project-template/AGENTS.md`, and `project-template/GEMINI.md` each
received the IDENTICAL edit at the "Tier 0 installation note"
paragraph:

| File | Line of BD-142 cite | After edit |
|---|---|---|
| `project-template/CLAUDE.md` | L195 | `at install time; the Tier 0 base list is then loaded by every agent for every project. See \`scripts/init-project.sh\` \`stage_s4_skills()\` and the` |
| `project-template/AGENTS.md` | L179 | (identical text) |
| `project-template/GEMINI.md` | L191 | (identical text) |

Edit pattern: deletion of " per BD-142" from after "project". The
surrounding sentence remains structurally identical across trinity.

### §6.2 Trinity-parity verification

Verified via:

```
$ grep -A 5 "Tier 0 installation note" \
    project-template/CLAUDE.md \
    project-template/AGENTS.md \
    project-template/GEMINI.md
```

Result: identical 5-line trailing context after the section header
across all 3 files (verified manually in §9.4 below).

Edit is provably non-tool-specific (it's prose narrative, no
CLI-specific syntax). Trinity rule honored.

---

## §7 — Special-handling user resolutions applied

### §7.1 §6.1 (mention-to-exclude) — Reading A for pack-archive; Reading B for project-side

Per disposition §6.1 user resolution: project-side keeps boundary
defense (Reading B); pack-archive surface drops mention-to-exclude
(Reading A).

**A-3.6.2 (`templates-archive/v11.0/inbound-v11.0/SCHEMA.md:17`):**

| Before | After |
|---|---|
| `Inbound entries do not have a stable pack-side identifier prefix (no BD-NNN / TD-NNN). The GH issue number is the identifier.` | `Inbound entries do not have a stable pack-side identifier prefix. The GH issue number is the identifier.` |

Mention-to-exclude parenthetical dropped. Pack-archive surface;
reading A applied.

**A-3.6.3 (`templates-archive/v11.0/inbound-v11.0/SCHEMA.md:114`):**

| Before | After |
|---|---|
| `Unlike BD/TD entries (where chat triage rewrites \`PENDING\` to \`BD-NNN\` / \`TD-NNN\`), inbound entries have no pack-side namespace identity — the GH issue number is their identifier.` | `Inbound entries have no pack-side namespace identity — the GH issue number is their identifier.` |

The "Unlike BD/TD entries..." clause dropped wholesale; inbound's
positive identity statement stays. Same forward migration / reverse
migration paragraph also drops BD-065 / BD-067 pack-history (covered
by §4.5 A-3.6.4 in §5 above).

**A-3.12.4 (`project-template/.github/ISSUE_TEMPLATE/work-item.yml:18`):**

| Before | After |
|---|---|
| `Pack-development items (BD-NNN) belong in the pack repo, not in this project.` | `Pack-development items (BD-NNN) belong in the pack repo, not in this project.` |

**PRESERVED VERBATIM.** Project-side form; boundary-defense statement;
Reading B applied (KEEP). The `bd` dropdown option is removed (F2.d
LOCKED), so the boundary defense is the sole channel telling project
users that BD-NNN belongs in the pack repo.

### §7.2 §6.2 (boundary-investigation SKILL.md BD-175 V1) — relabel without losing teaching content

**A-3.34.1 (L33):**

| Before | After |
|---|---|
| `The audit BD-175 (P-missed-7) documented the regression mechanism this skill prevents...` | `The audit incident (P-missed-7) documented the regression mechanism this skill prevents...` |

**A-3.34.2 (L169 section header):**

| Before | After |
|---|---|
| `## Worked example (BD-175 V1 anti-pattern)` | `## Worked example (V1 anti-pattern)` |

The P-missed-7 label is preserved (pack-memory anchor; visible to
clients via the trinity Pack memory section reference in the skill).
BD-175 label dropped; "V1 anti-pattern" carries the worked-example
identity now. The worked-example content body (Step 1–5 walkthrough)
is preserved intact.

### §7.3 §6.3 (MIGRATION-v10-to-v11.md Class A/B split)

Class A (LEGITIMATE) rows preserved unchanged:

- A-3.46.1 (L10-11 BD-042 / BD-085 migration script attribution).
- A-3.46.2 (L18 BD-121 v9-sunset history).
- A-3.46.3 (L41 BD-088 contract).
- A-3.46.4 (L44 BD-042 relocation tail).
- A-3.46.9 (L146 BD-088 mechanism).
- A-3.46.10 (L152 BD-088 sidecar).
- A-3.46.12 (L162 BD-088 sidecar).
- A-3.46.13 (L177 BD-088 mechanism).
- A-3.46.25 (L394 BD-088 pre-flight).
- A-3.46.26 (L396 BD-088 init).
- A-3.46.27 (L397 BD-088 dispatch).
- A-3.46.28 (L398 BD-104 rename action).
- A-3.46.29 (L399 BD-042 relocation tail).
- A-3.46.30 (L413 BD-088 lib error).
- A-3.46.31 (L415 BD-101 verification gate).
- A-3.46.32 (L417 BD-101 verification gates).

Class B (WASTE) rows removed per §5 table. See §5 row for
`supporting-docs/MIGRATION-v10-to-v11.md`.

### §7.4 §6.4 (SETUP files) — WASTE

SETUP-NEW.md and SETUP-EXISTING.md cite removals applied per §5 table.
All BD-121 / BD-047 cites removed; surrounding prose preserved.

---

## §8 — Manifest regeneration

The commit touches `project-template/`, `supporting-docs/`, AND
`scripts/` — three of the four v11-surface trigger directories per
pack memory `feedback_manifest_regen_on_v11_surface`. Manifest
regenerated via:

```
$ bash test-fixtures/build.sh --all --clean
```

### §8.1 Manifest rows changed

| Fixture | Old SHA | New SHA |
|---|---|---|
| `v10-minimal` | `19558cbac58ed3e47642a6bbe64418a38c60bc16` | (unchanged — v10 tag pin) |
| `v10-realistic-ot` | `4c62945f72b037908b38967d5d8f019745263258` | (unchanged — v10 tag pin) |
| `v11-realistic-ot` | `52f34126f73a6276bebf68e92f4180f2c169a81c` | `f0bacc6c08be16bd59351648383d53b70800b24f` |
| `v11-flat-file` | `825b0061551e621b3b25793f16504609f70747d5` | `cf19a42aa67f309b47e4aecef2d993225e4b76ee` |
| `v11-tracker-on` | `0c9bffb0c2e7a9af3bec55312873a9604bdfd20a` | `092ec81e7917eb978b7992ed4fd413e02c8fef39` |
| `existing-project-mid-dev` | `a54e081a9e1d04f293bfb38fa0af77fd9f7f8619` | (unchanged — pack-independent fixture) |

All three v11-* fixtures drifted as expected (v11-surface edits include
trinity, .github/ISSUE_TEMPLATE, supporting-docs, scripts, all of which
copy into the v11-* fixtures via `scripts/init-project.sh`).

### §8.2 Manifest staged in working tree

`test-fixtures/manifest.txt` is staged (modified). Pack Chat will
include it in the BD-193 commit per the v11-surface manifest contract.

---

## §9 — Verification

### §9.1 validate-pack.py — PASS

```
$ python3 scripts/validate-pack.py
... [all 43 checks emit OK] ...
============================================================
PASSED — all checks clean
```

Check 43 (Project-side bare cross-reference scanner / V11 leak-sweep
prevention): PASS. 151 project-side / client-installed files walked;
zero pack-internal bare cross-references.

Check 37 (Project-side pack-only deny-list): PASS. 158 project-side
files walked; zero deny-list contamination.

Check 41 (`_CLIENT_INSTALLED_FILES` self-doc list integrity): PASS.
37 entries (one fewer than the pre-edit count of 38 because the
pack-ops/HELP-FRAGMENT-TRACKER.md entry was merged with the
project-template/docs/pack one into a single S6+S11 entry).

### §9.2 Manifest verification — PASS

```
$ bash test-fixtures/build.sh --verify
  v10-minimal OK: 19558cba...
  v10-realistic-ot OK: 4c62945f...
  v11-realistic-ot OK: f0bacc6c...
  v11-flat-file OK: cf19a42a...
  v11-tracker-on OK: 092ec81e...
  existing-project-mid-dev OK: a54e081a...
```

All fixture SHAs match the regenerated manifest.

### §9.3 test-issue-forms.sh — PASS (post-update)

```
$ bash scripts/tests/test-issue-forms.sh
=== Summary ===
Passed: 78
Failed: 0
All tests passed.
```

The check_workitem function now accepts a `surface_kind` argument
(`"pack"` for pack-root, `"project"` for project-template). Pack-root
must include `bd`; project-template must NOT. Cross-surface invariant
5.1 relaxed to "pack admits bd, project omits bd" with a derived
expected value.

### §9.4 Trinity-parity verification — PASS

```
$ grep -c "BD-142" project-template/CLAUDE.md project-template/AGENTS.md project-template/GEMINI.md
project-template/CLAUDE.md:0
project-template/AGENTS.md:0
project-template/GEMINI.md:0
```

All 3 trinity files have 0 BD-142 cites post-edit.

The "Tier 0 installation note" paragraph content is identical across
all 3 trinity files (verified by grep -A 5).

### §9.5 Per-file BD-NNN grep verification

**Project-template clean:**

```
$ grep -rn "BD-" project-template/
project-template/.github/ISSUE_TEMPLATE/work-item.yml:18:        Pack-development items (BD-NNN) belong in the pack repo, not in this project.
```

Exactly 1 surviving BD- reference — the §6.1 user-locked KEEP
(boundary-defense statement on the project-side form).

**Supporting-docs clean (MIGRATION-v10-to-v11.md remains LEGITIMATE
Class A cites only):**

```
$ grep -n "BD-" supporting-docs/INSTALL-PROCEDURES.md supporting-docs/SETUP-NEW.md supporting-docs/SETUP-EXISTING.md
(no output — all WASTE cites removed)

$ grep -n "BD-" supporting-docs/MIGRATION-v10-to-v11.md | head
... [Class A LEGITIMATE rows only — BD-042/BD-085/BD-088/BD-101/BD-104/BD-121 in migration-mechanism descriptions] ...
```

**Templates-archive — only LEGITIMATE references remain:**

- `bd-v11.0/SCHEMA.md`: BD-NNN references in pack-internal definitional
  context (preserved per §4.1 disposition; PACK-INTERNAL header
  disclosure attached).
- `INDEX.md` (both v11.0 and v11.1): BD-NNN row in segregated
  "Pack-internal entry types (informational only)" sub-section.
- `phase-task-v11.0/SCHEMA.md`: zero BD-NNN admissions in dependency
  grammar; `derived-from:TD-NNN` etc. references preserved.
- `phase-part-v11.1/SCHEMA.md`: zero BD-185 cites; zero BD-NNN
  prerequisite-grammar admissions. `derived-from:TD-NNN` NEGATIVE
  statement preserved with §6.5 D-18 carrier-matrix phrase rephrased
  to inline `phase-epic-v11.0/SCHEMA.md and phase-task-v11.0/SCHEMA.md`.
- `phase-epic-v11.0/SCHEMA.md`: L11 reference line preserved as
  LEGITIMATE per §4.3 disposition.
- `forms/work-item.yml`: zero `bd` dropdown option; zero BD-NNN in
  field descriptions.

### §9.6 Init-project.sh S11 verification

```
$ grep -n "HELP-FRAGMENT-TRACKER" scripts/init-project.sh
14:# (HELP-FRAGMENT.md + HELP-FRAGMENT-TRACKER.md, tracker.toml.example
820:    # HELP-FRAGMENT-TRACKER.md client-shipped source is project-template/
826:    if [[ -f "$PACK/project-template/docs/pack/HELP-FRAGMENT-TRACKER.md" ]]; then
827:        cp -f "$PACK/project-template/docs/pack/HELP-FRAGMENT-TRACKER.md" \
828:            "$TARGET/docs/pack/HELP-FRAGMENT-TRACKER.md"
832:    [[ -f "$TARGET/docs/pack/HELP-FRAGMENT-TRACKER.md" ]] \
833:        || fail_stage S11 "docs/pack/HELP-FRAGMENT-TRACKER.md missing after copy"
1146:        "project-template/docs/pack/HELP-FRAGMENT-TRACKER.md:docs/pack/HELP-FRAGMENT-TRACKER.md:generic"
1308:#   project-template/docs/pack/HELP-FRAGMENT-TRACKER.md  ->  docs/pack/HELP-FRAGMENT-TRACKER.md  [stage:S6,S11,cmd_update]
```

- L820-829: project-template source path; pack-ops/ fallback removed;
  pack-root fallback removed.
- L1308: single manifest entry (was two, merged) with `[stage:S6,S11,cmd_update]`.
- L1146: cmd_update entry unchanged (already correctly pointed at
  project-template).

---

## §10 — Out-of-scope confirmation

The following were intentionally NOT modified per the implementation
prompt's "Out of scope" section:

1. **POQ-4 reversal** in `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md`
   and `maintenance-docs/v11-implementation/PLAN-BD-185.md` — separate
   Pack Chat work; not touched.
2. **BD-185 H.1 NIT-2 / NIT-3 cosmetic fixes** — pending Code Red 2
   close; not touched.
3. **Pack memory files** at
   `/Users/david/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/` —
   Pack-Chat-direct only; not touched.
4. **`pack-ops/BACKLOG.md`** — BD-193 entry already opened at HEAD
   `2f54bca`; not touched.
5. **`pack-ops/CHANGELOG.md`** — not touched (version boundary only;
   no PM-only edits).
6. **Trinity rule files at pack-repo root** — not touched (pack-root
   trinity is a different surface; this commit is project-side
   trinity + pack-research-archive + supporting-docs + scripts).

---

## §11 — PREFLIGHT line

```
PREFLIGHT: 36 in-scope file edits complete (11 LOCKED + 3 LEAK + ~85 WASTE
applied across 30 source files, plus 2 collateral CI-keep-green edits to
scripts/validate-pack.py and scripts/tests/test-issue-forms.sh, plus
test-fixtures/manifest.txt regen);
verification PASS (validate-pack.py incl Check 43, manifest --verify, test-
issue-forms.sh 78/0); trinity parity verified;
HEAD 2f54bcabcdb6e053d10c9ec8ea3733d6514ca337;
about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-193.md
```

---

## §12 — Boundary discipline check (project-side edits)

Per Pack memory `P-missed-7` and the `boundary-investigation` skill,
project-side edits investigated against project-side SSOTs:

| Project-side edit | Concept | Project-side SSOT consulted |
|---|---|---|
| `project-template/CLAUDE.md` BD-142 cite removal | "agent skill loading" | The surrounding paragraph names `scripts/init-project.sh` `stage_s4_skills()` and the `boundary-investigation` Tier 0 skill — these are project-readable references. Removing the BD-142 cite leaves the project-readable references intact. No pack-only target introduced. |
| `project-template/AGENTS.md` BD-142 cite removal | (same — trinity parallel) | (same SSOT) |
| `project-template/GEMINI.md` BD-142 cite removal | (same — trinity parallel) | (same SSOT) |
| `project-template/skills/audit-methodology/SKILL.md` BD-NNN.md → TD-NNN.md | "project-side per-entry tree filename" | Project-side SSOT: `project-template/docs/project/backlog/_rules.md` L14 regex `^TD-\d+\.md$`. The skill's example string was project-side-incorrect (BD-NNN.md does not match the regex); TD-NNN.md is project-side correct. |
| `project-template/skills/boundary-investigation/SKILL.md` BD-175 → audit-incident | "the audit incident that motivated this skill" | Pack memory `P-missed-7` is the project-readable anchor (visible to clients via the trinity Pack memory section). The BD-175 label is a pack-internal anchor that does not exist at client install. The relabeled phrase ("the audit incident (P-missed-7)") points only at the client-visible P-missed-7 label. |
| `project-template/.github/ISSUE_TEMPLATE/work-item.yml` `bd` dropdown removal + L18 boundary defense kept | "client work-item form's entry types" | Project-side SSOT: the form itself is the project-side authority; the v11.0 archive `templates-archive/v11.0/forms/work-item.yml` is the pack-side mirror. The cleanup makes them divergent intentionally — pack-side admits `bd`, project-side does NOT (per BD-193 F2.d). Boundary-defense statement at L18 is preserved as project-side affordance for the client agent encountering a BD reference. |
| `project-template/docs/pack/PM-CHAT.md` BD cite removals | "tracker-promote orchestration library" | Project-side SSOT: the file itself documents the client-side TD-promotion verb dispatch; BD-107/108 are pack-implementation history (not present at client install). Removing the cites leaves the `tracker-promote.sh` / `tracker_links_create_blocked_by` references which are project-readable. |
| `project-template/docs/pack/PLATFORM-SKILLS.md` BD cite removals | "skill predicate authority" | Project-side SSOT: the predicate function names (`python_data_marker_detected()` etc.) in `scripts/lib/detect.sh` (project-installed). Removing the "(see BD-141)" parenthetical leaves the function reference, which is the project-readable authority. |
| `project-template/skills/python-*/SKILL.md` BD-141/143 split-history removals | "v11.0 Python skill split" | Project-side SSOT: the two skill files themselves (`python-server-architecture/SKILL.md`, `python-data-architecture/SKILL.md`) demonstrate the split. The "v11.0 by BD-141 and BD-143" pack-history detail is unnecessary; the rephrase "split in v11.0 (the `python_data_marker_detected()` load predicate and the trinity SKILL.md split...)" preserves the project-visible mechanism. |
| `project-template/docs/project/backlog/_intro.md` BD-NNN cross-reference removal | "client backlog cross-reference grammar" | Project-side SSOT: `project-template/docs/project/backlog/_rules.md`. Project clients have no BD entries (per the user-locked rule); removing BD-NNN from the cross-references list aligns with the project-side per-entry contract. |

No "Boundary discipline stop" was triggered — none of the edits would
introduce a project-side reference to a pack-only file.

---

## §13 — Definition-of-Done checklist

| Item | Status | Evidence |
|---|---|---|
| All 11 LOCKED dispositions applied per §3 of disposition report | PASS | §3 above; per-row applied edits documented |
| All 3 LEAK fixes applied (or verified inherited) | PASS | §4.1 inherited (verified); §4.2 audit-methodology fix; §4.3 MIGRATION fix |
| All WASTE fixes applied per §4 disposition tables | PASS | §5 above per-file count; ~85 cite removals across 22 files |
| §6.1, §6.2 user-resolution applied (split readings / removal) | PASS | §7 above |
| Trinity-rule parity for BD-142 cite removal | PASS | §6 + §9.4 verification |
| Manifest regenerated; staged in working tree | PASS | §8 above; `--verify` clean |
| validate-pack.py PASS (esp. Check 43) | PASS | §9.1 above |
| Per-file grep verification confirms only LEGITIMATE rows remain | PASS | §9.5 above |
| PREFLIGHT line emitted before IMPL-REPORT write | PASS | §11 above (emitted prior to this report's Write call) |
| IMPL-REPORT written; no state-changing git verbs invoked | PASS | This file. No `git add` / `commit` / `push` / `tag` / `reset` / `mv` / `rm` invoked. |

---

## §14 — Plan deviations

**Zero structural plan deviations.**

The following two collateral edits were required to keep CI green
under the F2.c + F2.d locked actions, and were applied per disposition
report §2.3 ("the LOCKED dispositions") since they are direct
consequences of the locked changes — not new structural decisions:

1. **`scripts/validate-pack.py`** — `check_issue_template_forms()`
   (printed label "Check: Issue template forms (BD-063)") was
   hard-coded to expect identical `wi-type` options on
   both pack-root and project-template forms. With F2.d removing `bd`
   from the project-side form, the check would fail. Per-surface
   expected options introduced (pack-root admits `bd`, project-template
   does NOT). Rationale documented in the function's docstring as
   "Per V3.3 §6.1 + BD-193 boundary cleanup".

2. **`scripts/tests/test-issue-forms.sh`** — Two failures emerged:
   (a) `check_workitem` asserted `bd` membership on project-side; now
   gated by an optional `surface_kind` argument with the project-side
   variant asserting `bd` is ABSENT. (b) Cross-surface invariant 5.1
   asserted identical options; relaxed to "project options = pack
   options minus `bd`" with a derived expected value.

These are not plan deviations — they are mechanical CI-keep-green
edits required by the F2.c + F2.d LOCKED actions. The disposition
report did not enumerate them because they live outside its "in
report content" surface (scripts/ is Surface B and was triaged at
disposition §4.42 "all Surface B findings covered by F4/F5 lock").
The F2.c + F2.d edits expose script-side dependencies that the
disposition phase could not anticipate without a working-tree pass
through the actual tests.

---

## §15 — New POQs introduced

**Zero new POQs introduced.**

The two collateral CI edits in §14 are mechanical consequences of
LOCKED dispositions, not new design questions. No architecture
material surfaced.

---

End of IMPLEMENTATION-REPORT-BD-193.md.
