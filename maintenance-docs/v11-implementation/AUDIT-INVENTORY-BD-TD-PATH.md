# AUDIT-INVENTORY-BD-TD-PATH.md — Code Red 2 raw inventory

**Authored by:** pack-docs-researcher (read-only inventory pass).
**Date:** 2026-05-26 (US/Pacific).
**Branch:** v11-dev.
**Repo HEAD at read time:** `8b4c6076dbc0488f57f44040a83dbf4fe8b1ab5a` (`docs: v11 — BD-185 open (Batch 19d phase parts + ordering, pack-only)`).
**Pipeline:** Phase 1 (inventory; THIS doc) → Phase 2 (pack-reviewer disposition).

---

> **CORRECTION (BD-195 S1, 2026-05-31):** This inventory treats
> `templates-archive/v11.1/` as a real "Surface A" client-facing audit target
> (§1, §2, §3.9, §3.10, and the tally/quick-scan rows) and records a
> phase-parts-as-v11.1 / "v11.1 archive cut is driven by BD-185" / "NEW v11.1
> Prerequisites grammar" / "structural shape frozen at 5 subdirs" (D16) framing.
> Those framings are **fictional contamination**, retired per BD-195 S1·C3 (the
> D16 "frozen at 5 subdirs" line is also tracked as reconciled-list P-31b /
> R8-F09). The phase-part SCHEMA was relocated to
> `maintenance-docs/v11-research/templates-archive/v11.0/phase-part-v11.0/SCHEMA.md`;
> the `templates-archive/v11.1/` directory no longer exists. Phase-parts was
> always **v11.0**; v11.0 is UNRELEASED and was never frozen. This is a tracked
> historical record — its body and findings are preserved unaltered as the
> record of what was inventoried at the time, but every affected `v11.1` path
> reference, "v11.1 cut" framing, and "frozen at 5 subdirs" wrapper below is
> **superseded** by the corrected v11.0 fact. See
> `AUDIT-BD-195-S1-INFO1-SWEEP.md` (surface G4).

## §1 — Scope

Code Red 2 raw inventory of BD-NNN / TD lifecycle / Path-promotion-path / TD→Part / pack-ops-copy-violation findings across two surfaces:

- **Surface A** — Client-facing content (audit-for-leaks): `project-template/**`, `supporting-docs/**`, `maintenance-docs/v11-research/templates-archive/v11.0/`, `maintenance-docs/v11-research/templates-archive/v11.1/`.
- **Surface B** — Pack-side scripts (audit-for-VIOLATIONS-of-Rule-5): `/scripts/` (root + `scripts/lib/`).

**Inventory ONLY.** No disposition. No correction proposal. Those land in Phase 2 (pack-reviewer).

---

## §2 — Methodology

### §2.1 — Inventory dimensions

| Dim | Name | Applies to | Description |
|---|---|---|---|
| 1 | BD-NNN literal string matches | Surface A | Text containing `BD-NNN` or `BD-<digits>`. |
| 2 | BD-NNN in SCHEMA / grammar admissions | Surface A | SCHEMA / contract grammar admitting BD-NNN as a dependency type, entity type, or label-namespace target. |
| 3 | TD lifecycle descriptions | Surface A | Doc describing how TDs become scheduled / promoted / interact with phases. |
| 4 | Path 1/2/3 references | Surface A | References to Path 1, Path 2, or Path 3 promotion paths. |
| 5 | TD→Part references | Surface A | Any reference suggesting TDs can promote to Parts or interact with Part hierarchy. |
| 6 | Cross-entity dependency grammars | Surface A | Entity types admitted as dependencies in each file's grammar definition. |
| 7 | pack-ops/ → project install copy violations | Surface B | Script code paths that copy `pack-ops/*` files to project install paths. |

### §2.2 — Tools used

- `grep -rn` on `BD-\|BD_`, `TD-\|TD-TBD`, `Path [123]`, `--fold-into`, `pack-ops` patterns.
- `find` for file enumeration.
- Direct `Read` against authoritative documents (SCHEMA.md, INDEX.md, METHODOLOGY.md, PM-CHAT.md, init-project.sh).
- Cross-reference against ARCHITECTURE-BD-185.md §1.4 Decision log and user-locked rules in this audit prompt.

### §2.3 — Surfaces searched

| Surface | Path | Files inventoried |
|---|---|---|
| A | `project-template/**` | 120 files (excluding `.DS_Store`) |
| A | `supporting-docs/**` | 10 files |
| A | `maintenance-docs/v11-research/templates-archive/v11.0/` | 8 files |
| A | `maintenance-docs/v11-research/templates-archive/v11.1/` | 2 files |
| B | `scripts/` root + `scripts/lib/` | ~40 scripts |

### §2.4 — Categorization vocabulary

Each finding tag:

- `Surface: A|B`
- `Dimension: 1|2|3|4|5|6|7`
- `File: <absolute path>`
- `Location: <section or line range>`
- `Context: <3-5 lines>`
- `Initial-category: literal-match | grammar-admission | lifecycle-description | path-reference | td-to-part | grammar-content | script-copy-violation | ambiguous`

NOTE: `Initial-category` is a CLASSIFICATION SHAPE only — NOT a disposition. Phase 2 reviewer makes the LEAK vs LEGITIMATE call.

---

## §3 — Surface A findings

Findings grouped by file. Each finding is one row of the table per dimension hit; multi-dimension hits at the same location are grouped.

### §3.1 — `maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.1.1 | 1, 2, 6 | L10 | `\| BD-NNN (pack-development backlog item) \| [bd-v11.0/SCHEMA.md](bd-v11.0/SCHEMA.md) \| `bd-v11.0` \| `template:bd-v11.0` \|` — BD-NNN listed as the 1st of 5 entry types in the v11.0 template-archive cut INDEX. | grammar-admission |

### §3.2 — `maintenance-docs/v11-research/templates-archive/v11.0/bd-v11.0/SCHEMA.md`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.2.1 | 1, 2 | L5 | "reverse) and `pack tracker update-templates` (BD-069) read this file" | literal-match |
| A-3.2.2 | 1, 2 | L11 | "BD-064 + Addendum 4 §2.2." | literal-match |
| A-3.2.3 | 1, 2, 6 | L15 | "Identifier: `BD-NNN`, three-digit zero-padded counter, owned by the pack repository." — DEFINES BD-NNN as an entity type at v11.0. | grammar-admission |
| A-3.2.4 | 1, 2, 6 | L20-21 | "Round-trip carrier: title prefix (`BD-NNN: <title>`) plus body / HTML-comment marker `<!-- pack-id: BD-NNN -->`." | grammar-admission |
| A-3.2.5 | 1, 2, 6 | L31 | "`<!-- pack-id: BD-NNN -->`" in body-marker-trio code block. | grammar-admission |
| A-3.2.6 | 1 | L37 | "submission; chat triage rewrites to `BD-NNN`." | literal-match |
| A-3.2.7 | 1, 2, 6 | L74 | "`<!-- pack-id: BD-NNN -->`" in body-section grammar code block. | grammar-admission |
| A-3.2.8 | 1, 2, 6 | L101 | "(V1 §2.7 + BD-111). Each line of the form `BD-NNN`, `TD-NNN`," — defines that Blocker entries may reference BD-NNN. | grammar-admission |
| A-3.2.9 | 1, 2, 6 | L114 | "`**BD-NNN — <title>**`" in reverse-emit grammar code block. | grammar-admission |
| A-3.2.10 | 1 | L125 | "The `**BD-NNN — <title>**` line uses the title prefix..." | literal-match |

### §3.3 — `maintenance-docs/v11-research/templates-archive/v11.0/td-v11.0/SCHEMA.md`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.3.1 | 3, 4 | L47 | "`promoted-to:phase-N` or `promoted-to:phase-N.M` \| chat (TD-promotion path) \| when TD is promoted into a phase" — declares Path 1 (phase-N) and Path 2 (phase-N.M) targets via label namespace; Path 2 target uses `phase-N.M` (task-style ID), NOT `Phase-N.Part-x` form. | path-reference + lifecycle-description |
| A-3.3.2 | 6 | L101 (V3.3 §5.3 cite chain) | TD dependencies grammar inherited from phase-task SCHEMA admits BD-NNN per §3.10 below. | grammar-admission |

### §3.4 — `maintenance-docs/v11-research/templates-archive/v11.0/phase-epic-v11.0/SCHEMA.md`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.4.1 | 1 | L11 | "IMPLEMENTATION-PLAN.md BD-064 + Addendum 4 §2.2." (header citation) | literal-match |
| A-3.4.2 | 3, 4 | L43 | "`derived-from:TD-NNN` \| chat (TD-promotion path 1) \| optional; one or more" — Path 1 (TD → phase-epic) carrier declared. | path-reference + lifecycle-description |
| A-3.4.3 | 6 | L114-117 | "`derived-from:TD-NNN` labels become a footer line per phase:" + `<!-- derived-from: TD-NNN, TD-NNN, ... -->` reverse-emit marker. | grammar-content |

### §3.5 — `maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.5.1 | 3, 4 | L44 | "`derived-from:TD-NNN` \| chat (TD-promotion path 2) \| optional; one or more" — Path 2 (TD → phase-task) carrier declared at SCHEMA level. Path 2 target is `phase-N.M` (task), NOT a Part. | path-reference + lifecycle-description |
| A-3.5.2 | 1, 2, 6 | L79 | "<one ID per line — optional; accepts phase-N, phase-N.M, TD-NNN, BD-NNN>" — Dependencies grammar admits BD-NNN as dep type for client-facing phase-task entity. | grammar-admission |
| A-3.5.3 | 1, 2, 6 | L91 | "`BD-NNN` — depends on a BD entry" — explicit BD-NNN dep type declared for phase-task. | grammar-admission |
| A-3.5.4 | 6 | L139-143 | "`derived-from:TD-NNN` labels emit at the foot of the task body" + `<!-- derived-from: TD-NNN, TD-NNN, ... -->`. | grammar-content |

### §3.6 — `maintenance-docs/v11-research/templates-archive/v11.0/inbound-v11.0/SCHEMA.md`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.6.1 | 1, 2 | L12 | "BD-064 + Addendum 4 §2.2." (header citation) | literal-match |
| A-3.6.2 | 1, 2, 6 | L17 | "(no BD-NNN / TD-NNN). The GH issue number is the identifier." — inbound explicitly DOES NOT have BD-NNN ID. | grammar-admission (negative form) |
| A-3.6.3 | 1, 2 | L114 | "to `BD-NNN` / `TD-NNN`), inbound entries have no pack-side namespace" | grammar-admission (negative form) |
| A-3.6.4 | 1 | L119-121 | "Forward migration (BD-065) does not write inbound entries to flat files...Reverse migration (BD-067) excludes inbound entries..." | literal-match |

### §3.7 — `maintenance-docs/v11-research/templates-archive/v11.0/forms/work-item.yml`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.7.1 | 1, 2, 6 | L2 | "description: Pack-development backlog item (BD-NNN), project technical-debt item (TD-NNN), phase epic skeleton, or phase task skeleton." — form admits BD-NNN as entry type. | grammar-admission |
| A-3.7.2 | 1, 2, 6 | L3 | "title: \"BD-NNN: <short title>\"" — default title prefix is BD-NNN. | grammar-admission |
| A-3.7.3 | 1 | L13 | "chat at triage time renames the title (e.g. `BD-NNN:` becomes the assigned ID)," | literal-match |
| A-3.7.4 | 1, 2, 6 | L23 | `wi-type` dropdown option `bd` — BD as the first option in the entry-type dropdown for this form. | grammar-admission |
| A-3.7.5 | 1, 2, 6 | L105 | "One per line. Each line is either an issue id (BD-NNN, TD-NNN, #N)..." — Blockers grammar admits BD-NNN. | grammar-admission |
| A-3.7.6 | 1, 2, 6 | L169 | "One ID per line. Accepts `phase-N`, `phase-N.M`, `TD-NNN`, `BD-NNN`." — Dependencies grammar admits BD-NNN. | grammar-admission |

### §3.8 — `maintenance-docs/v11-research/templates-archive/v11.0/forms/inbound.yml`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.8.1 | — | — | No BD/TD/Path findings (file is the inbound form; uses GH issue numbers only per A-3.6.2). | (no findings) |

### §3.9 — `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.9.1 | 1 | L3 | "preserves the v11.1 form file (added in BD-185 H.2) and" — narrative pointer to architect doc. | literal-match |
| A-3.9.2 | 1 | L7 | "The v11.1 archive cut is driven by BD-185 (Multi-part phase mid-work" | literal-match |
| A-3.9.3 | 1, 2, 6 | L17 | `\| BD-NNN (pack-development backlog item) \| [../v11.0/bd-v11.0/SCHEMA.md](../v11.0/bd-v11.0/SCHEMA.md) \| `bd-v11.0` \| `template:bd-v11.0` \|` — v11.1 INDEX inherits the v11.0 BD-NNN entry type listing into the v11.1 cut. | grammar-admission |
| A-3.9.4 | 1 | L24 | "Reference: ARCHITECTURE-BD-185.md §4.1 (Part-id grammar) / §4.3" | literal-match |
| A-3.9.5 | 1 | L33 | "`inbound-v11.0`) per ARCHITECTURE-BD-185.md §10.1 Convention Y" | literal-match |
| A-3.9.6 | 1 | L39 | "by BD-185 mid-work phase expansion)." | literal-match |
| A-3.9.7 | 1 | L43 | "shape stays frozen at 5 subdirs). BD-185 exercises this convention" | literal-match |
| A-3.9.8 | 1 | L48-49 | "`cancelled` state addition; BD-185 §4.4a). This extension lands / in BD-185 H.13." | literal-match |
| A-3.9.9 | 1 | L51 | "v11.1 evolutions. This extension lands in BD-185 H.14." | literal-match |
| A-3.9.10 | 1 | L57 | "is byte-identical to the post-BD-185-H.2 live form" | literal-match |
| A-3.9.11 | 1 | L61 | "form is CREATED in BD-185 H.2 per POQ-1 resolution 2026-05-26" | literal-match |
| A-3.9.12 | 1 | L76 | "Per BD-185 §4.3 template-version delta table, only `work-item-v11.0`" | literal-match |
| A-3.9.13 | 1 | L84 | "See `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md` §1.4" | literal-match |

### §3.10 — `maintenance-docs/v11-research/templates-archive/v11.1/phase-part-v11.1/SCHEMA.md`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.10.1 | 1 | L5 | "introduced by mid-work phase expansion (BD-185). A Part groups one or" | literal-match |
| A-3.10.2 | 1 | L11 | "`pack tracker phase split` verb (BD-185 §4.5) when a phase needs to be" | literal-match |
| A-3.10.3 | 1 | L13 | "collapsed (BD-185 §4.7 D2 no-collapse rule)." | literal-match |
| A-3.10.4 | 1 | L15 | "Reference: ARCHITECTURE-BD-185.md §4.1 / §4.1a / §4.3 / §4.4 / §4.7 /" | literal-match |
| A-3.10.5 | 1 | L20 | "Identifier: `Phase-N.Part-x` per the C-1 grammar (BD-185 §4.1)." | literal-match |
| A-3.10.6 | 1 | L34 | "**Prohibited forms** (per BD-185 §4.1):" | literal-match |
| A-3.10.7 | 1 | L53 | "(BD-185 H.5 `tracker-phase-part.sh`) validates the trio at read and" | literal-match |
| A-3.10.8 | 1 | L59 | "form path (BD-185 §4.3 5th wi-type option), chat triage rewrites the" | literal-match |
| A-3.10.9 | 1 | L75 | "**Excluded labels** (per BD-185 §4.4 lifecycle invariant):" | literal-match |
| A-3.10.10 | 5 | L83-85 | "`derived-from:TD-NNN` — Parts are not derived from TD entries; the / TD-promotion paths (§6.5 D-18 carrier matrix) target phase-epic / (path 1) and phase-task (path 2), not phase-part." — EXPLICIT statement that TDs do NOT derive Parts (i.e., this is a NEGATIVE TD→Part reference; reinforces the user-locked rule). | td-to-part (negative form) + lifecycle-description |
| A-3.10.11 | 1 | L81 | "`phase-task-v11.0` only (BD-185 §4.4a). Parts do not have a cancelled" | literal-match |
| A-3.10.12 | 1 | L89 | "Per BD-185 §4.4 (LOAD-BEARING). Restrictive taxonomy: four states only." | literal-match |
| A-3.10.13 | 1 | L96 | "`status:deferred` \| closed \| `not_planned` \| Part deferred mid-work; member tasks stay assigned (re-parenting forbidden per D4 supersede-only rule, BD-185 §4.7)." | literal-match |
| A-3.10.14 | 1 | L98 | "**Lifecycle invariant** (BD-185 §4.4):" | literal-match |
| A-3.10.15 | 1 | L108 | "`pack task supersede` instead, per BD-185 §4.8)." | literal-match |
| A-3.10.16 | 1, 2, 6 | L129-130 | "<one ID per line — optional; accepts phase-N, Phase-N.Part-x, / Phase-N.Task-M, Phase-N.Part-x.Task-M, TD-NNN, BD-NNN>" — Prerequisites grammar admits BD-NNN as dep type. | grammar-admission |
| A-3.10.17 | 1 | L138 | "Member tasks. Parser/emitter (BD-185 H.5 `tracker-phase-part.sh`)" | literal-match |
| A-3.10.18 | 1 | L142 | "grammar; BD-185 §4.1 admits the additional Part-id forms):" | literal-match |
| A-3.10.19 | 1 | L150 | "BD-185 §4.1 backward-compat shim)" | literal-match |
| A-3.10.20 | 1, 2, 6 | L152 | "`BD-NNN` — depends on a BD entry" — explicit BD-NNN dep type for phase-part Prerequisites. | grammar-admission |
| A-3.10.21 | 1 | L180 | "`pack tracker phase split` (BD-185 §4.7); it uses the existing" | literal-match |
| A-3.10.22 | 1 | L189 | "**TBD — defined in BD-185 H.8 (`tracker-migrate-reverse.sh`" | literal-match |
| A-3.10.23 | 1 | L193 | "this SCHEMA via the BD-185 H.8 sequence." | literal-match |
| A-3.10.24 | 1 | L196 | "sub-sections inside `phase-N.md` per BD-185 §4.6 INLINE rule (no" | literal-match |
| A-3.10.25 | 1 | L219 | "(per BD-185 §6.3a / D8) is reserved for `phase-N.md` (the phase epic's" | literal-match |
| A-3.10.26 | 1 | L226 | "Cross-reference: ARCHITECTURE-BD-185.md §6.3a + D8 for the" | literal-match |

### §3.11 — `maintenance-docs/v11-research/templates-archive/README.md`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.11.1 | 1 | L48 | "directory once `pack tracker update-templates` ships (BD-069)." | literal-match |
| A-3.11.2 | 1 | L69 | "IMPLEMENTATION-PLAN.md BD-064 + Addendum 4 §2.2." | literal-match |

### §3.12 — `project-template/.github/ISSUE_TEMPLATE/work-item.yml`

This is the LIVE client-installed form (mirrored byte-similar to v11.0 archive form per §3.7, but adapted for project audience with TD-NNN as default title prefix).

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.12.1 | 1, 2, 6 | L2 | "description: Project technical-debt item (TD-NNN), phase epic skeleton, or phase task skeleton. (Pack development BDs are filed against the pack repo, not here.)" — form description explicitly states BDs are NOT project-side, but admits `bd` dropdown value (L25). | grammar-admission + lifecycle-description |
| A-3.12.2 | 1 | L3 | "title: \"TD-NNN: <short title>\"" — default title prefix is TD-NNN (project-side correct). | literal-match |
| A-3.12.3 | 1 | L13 | "the chat at triage time renames the title (e.g. `TD-NNN:` becomes the assigned" | literal-match |
| A-3.12.4 | 1 | L18 | "Pack-development items (BD-NNN) belong in the pack repo, not in this project." — explicit boundary-respect statement (NEGATIVE form). | literal-match |
| A-3.12.5 | 1, 2, 6 | L25 | `wi-type` dropdown: `- bd` option present. Description (L23): "The bd option exists for parity with the pack-side form but is not used in projects." | grammar-admission |
| A-3.12.6 | 1, 2, 6 | L107 | "One per line. Each line is either an issue id (TD-NNN, #N)..." — Blockers grammar in PROJECT-side form admits TD-NNN only (BD-NNN NOT named here). | grammar-admission |
| A-3.12.7 | 1, 2, 6 | L171 | "One ID per line. Accepts `phase-N`, `phase-N.M`, `TD-NNN`, `BD-NNN`. The chat resolves each line to first-class `provider.link()` calls post-creation." — Dependencies grammar in PROJECT-side form admits BD-NNN as dep type. | grammar-admission |

### §3.13 — `project-template/tracker.toml.project-example`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.13.1 | 1 | L71 | "# Cross-entity dependency graph tuning (BD-108)." (comment in TOML example) | literal-match |

### §3.14 — `project-template/.gitignore`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.14.1 | 1 | L7 | "# ─── Tracker-mode local state (BD-061) ─────────────────────────────────────" (comment) | literal-match |

### §3.15 — `project-template/CLAUDE.md`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.15.1 | 1 | L195 | "project per BD-142. See `scripts/init-project.sh` `stage_s4_skills()` and the" — narrative cite to BD-142 in skill-loading section. | literal-match |
| A-3.15.2 | 3 | L309-310 (typed deferral block) | "// KNOWN GAP(severity): TD-TBD — Short title / // VERIFY(source): TD-TBD — Short title" — TD-TBD sentinel grammar for deferral comments. | lifecycle-description |
| A-3.15.3 | 3 | L321 | "Always write `TD-TBD` — never a real TD number. The PM chat assigns numbers after review." | lifecycle-description |

### §3.16 — `project-template/AGENTS.md`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.16.1 | 1 | L179 | "project per BD-142. See `scripts/init-project.sh` `stage_s4_skills()` and the" (trinity-mirror of §3.15.1) | literal-match |
| A-3.16.2 | 3 | L293-294 | TD-TBD typed-deferral block (mirror of §3.15.2). | lifecycle-description |
| A-3.16.3 | 3 | L296 | "Always write `TD-TBD`. Never invent a TD number." (mirror of §3.15.3) | lifecycle-description |
| A-3.16.4 | 3 | L309 | "\| `coder` \| Write TD-TBD comments; report in completion report \| Write to BACKLOG.md \|" (BACKLOG-write-permissions table). | lifecycle-description |

### §3.17 — `project-template/GEMINI.md`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.17.1 | 1 | L191 | "project per BD-142. See `scripts/init-project.sh` `stage_s4_skills()` and the" (trinity-mirror of §3.15.1 and §3.16.1) | literal-match |
| A-3.17.2 | 3 | L305-306 | TD-TBD typed-deferral block (mirror of §3.15.2). | lifecycle-description |
| A-3.17.3 | 3 | L317 | "Always write `TD-TBD` — never a real TD number." (mirror of §3.15.3) | lifecycle-description |

### §3.18 — `project-template/.gemini/.env.example`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.18.1 | 1 | L3 | "# Per BD-059, AGENT_CAPABILITIES is mirrored across the three tools:" | literal-match |
| A-3.18.2 | 1 | L11 | "# BD-059 success criterion)." | literal-match |

### §3.19 — `project-template/.codex/config.toml`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.19.1 | 1 | L20 | "# and `.gemini/.env` AGENT_CAPABILITIES per the BD-059 trinity rule for" | literal-match |

### §3.20 — `project-template/.codex/config.toml.example`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.20.1 | 1 | L10 | "# and the .gemini/settings.json MCP block (per BD-059 trinity-rule" | literal-match |

### §3.21 — `project-template/docs/pack/PM-CHAT.md`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.21.1 | 1 | L608 | "`tracker_links_create_blocked_by` (BD-108) to wire the" | literal-match |
| A-3.21.2 | 1 | L651 | "Orchestration library: `scripts/lib/tracker-promote.sh` (BD-107)." | literal-match |
| A-3.21.3 | 1 | L655 | "and the BD-108 `tracker_links_create_blocked_by` orchestrator; no new" | literal-match |
| A-3.21.4 | 3 | L295 | "(TD-TBD → TD-NNN replacement or rejected-comment removal). Any" | lifecycle-description |
| A-3.21.5 | 3, 4 | L540-550 | "When a TD-NNN becomes Unblocked..." through "Path 3 is forbidden..." — full TD resolution orchestration section with three outcomes: Direct close, Path 1 (TD → new phase epic), Path 2 (TD → new phase task under existing phase). Path 3 forbidden ("no `--fold-into` verb"). Heuristics described. | path-reference + lifecycle-description |
| A-3.21.6 | 4 | L546-547 | "**Path 1** (multi-task work; new phase warranted) \| Resolved with `promoted-to:phase-N` label \| `pack td promote --to=phase-N <td-id>` \| new phase epic at L1 \|" + "**Path 2** (single-task scope; fits as a new task in an existing phase) \| Resolved with `promoted-to:phase-N.M` label \| `pack td promote --to=phase-N.M <td-id>` \| new phase task at L2 \|" — Path 2 target is `phase-N.M` (task), NOT `Phase-N.Part-x` (consistent with user-locked rule). | path-reference |
| A-3.21.7 | 4 | L549-550 | "**Path 3 is forbidden.** There / is no `--fold-into` verb and no `folded-into:` label." | path-reference |
| A-3.21.8 | 4 | L554-555 | "Or use Path 2 with a `Dependencies` bullet pointing at the absorbing / task to express ordering without merging entities." | path-reference |
| A-3.21.9 | 4 | L563 | "Path 1." (in advisory-heuristic bullet) | path-reference |
| A-3.21.10 | 4 | L564-566 | "**File/Symbol field**. Single file/symbol → likely small (Path 2 or / direct close). Multiple files / cross-cutting → architectural / surface (Path 1)." | path-reference |
| A-3.21.11 | 4 | L568-569 | "→ bias toward Path 2. `KNOWN GAP(critical)` → bias toward Path 1 / for traceability. `VERIFY` → bias toward direct close." | path-reference |
| A-3.21.12 | 4 | L570 | "**Cluster of related TDs in the same area** → bias toward Path 1" | path-reference |
| A-3.21.13 | 4 | L577 | "TD-031 is unblocked. Suggested resolution: Path 2 — promote to phase-7.4" (example presentation) | path-reference |
| A-3.21.14 | 4 | L593-594 | "**Path 2 (`pack td promote --to=phase-N.M`).** PM Chat does not invoke / planner or architect by default." | path-reference |
| A-3.21.15 | 4 | L614 | "does NOT invoke the architect for Path 2 by default; architect" | path-reference |
| A-3.21.16 | 4 | L618-619 | "**Path 1 (`pack td promote --to=phase-N`).** PM Chat invokes the / **architect** (project-side `architect.md` agent) **by default**" | path-reference |
| A-3.21.17 | 4 | L636 | "for Path 1 is therefore explicit: **the architect's call decides**." | path-reference |
| A-3.21.18 | 4 | L641-647 | Verb shape block: `pack td promote --to=phase-N           # Path 1 — new phase` + `pack td promote --to=phase-N.M         # Path 2 — new phase task` + "NO `--fold-into`. NO third subcommand." | path-reference |

### §3.22 — `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.22.1 | 3, 4 | L17-32 | "## TD promotion (v11+)" section — `pack td <verb>` table with Path 1 (`--to=phase-N`) + Path 2 (`--to=phase-N.M`) + Path 3 forbidden ("There is / no `--fold-into` flag"). Path 2 target is `phase-N.M`, NOT `Phase-N.Part-x`. | path-reference + lifecycle-description |
| A-3.22.2 | 4 | L45-46 | Colloquial mappings: "promote this TD to a new phase" → Path 1, "promote this TD to a task in phase N" → Path 2. | path-reference |

### §3.23 — `project-template/docs/pack/HELP-FRAGMENT.md`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.23.1 | 3 | L11 | "/pm-startup ... run TD-TBD check, report." | lifecycle-description |
| A-3.23.2 | 3, 4 | L19 | "`pack td promote --to=phase-N` \| Promote a TD-NNN to a new phase epic (Path 1)." | path-reference |
| A-3.23.3 | 3, 4 | L20 | "`pack td promote --to=phase-N.M` \| Promote a TD-NNN to a new phase task under phase N (Path 2)." — Path 2 target is `phase-N.M`. | path-reference |

### §3.24 — `project-template/docs/pack/PLATFORM-SKILLS.md`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.24.1 | 1 | L222 | "is the canonical predicate for the data-marker branch (see BD-141);" | literal-match |
| A-3.24.2 | 1 | L223 | "is the canonical predicate (see BD-156);" | literal-match |
| A-3.24.3 | 1 | L224 | "is the canonical predicate (see BD-162);" | literal-match |
| A-3.24.4 | 1 | L225 | "is the canonical predicate (see BD-157);" | literal-match |
| A-3.24.5 | 1 | L496 | "\| pm-startup \| PM chat session startup procedure: read state files, check TD-TBD sentinels, report ready status \| PM chat only (not an agent) \|" | lifecycle-description |
| A-3.24.6 | 1 | L582 | "enforcement migration is tracked under BD-155." | literal-match |
| A-3.24.7 | 1 | L599-601 | "v11.0 additions: `protobuf-patterns` (BD-156, Proto3 schema design / standalone of gRPC), `apple-swiftdata-patterns` (BD-157, SwiftData / object-store rules), and `swift-concurrency-patterns` (BD-158, modern" | literal-match |

### §3.25 — `project-template/docs/pack/prompts/reviewer.md`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.25.1 | 3 | L65 | "Run `grep -rn \"TD-TBD\" .` on all files modified in this phase. Any result is ❌ FAIL —" | lifecycle-description |
| A-3.25.2 | 3 | L71 | "For each TD-NNN found in reviewed files, confirm a matching BACKLOG entry" | lifecycle-description |

### §3.26 — `project-template/docs/pack/prompts/auditor.md`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.26.1 | 3 | L18 | "TD-NNN..TD-MMM.\"]" | lifecycle-description |

### §3.27 — `project-template/docs/pack/prompts/pm-chat.md`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.27.1 | 3 | L179-185 | "**TD-[NNN] — [Short title]** ... Unblocks: [TD-NNN, ...] or None" — BACKLOG entry format template. | lifecycle-description |
| A-3.27.2 | 3 | L193 | "Find TD-[NNN] and append the Resolution field:" | lifecycle-description |
| A-3.27.3 | 3 | L201 | "items whose Blockers list names this TD-NNN for user review before proceeding." | lifecycle-description |

### §3.28 — `project-template/docs/pack/prompts/coder.md`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.28.1 | 3 | L100-103 | TD-TBD typed-deferral block + "Always write `TD-TBD` — never invent a TD number. Report every deferral" | lifecycle-description |
| A-3.28.2 | 3 | L107 | "TD-TBD):** TD-[NNN]" | lifecycle-description |
| A-3.28.3 | 3 | L216-219 | TD-TBD typed-deferral block (second occurrence). | lifecycle-description |

### §3.29 — `project-template/.claude/agents/coder.md`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.29.1 | 3 | L83 | "explicitly lists those files in \"Files in scope.\" TD-TBD deferral" | lifecycle-description |

### §3.30 — `project-template/.gemini/agents/coder.md`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.30.1 | 3 | L82 | "explicitly lists those files in \"Files in scope.\" TD-TBD deferral" | lifecycle-description |

### §3.31 — `project-template/.codex/agents/coder.toml`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.31.1 | 3 | L48 | "...TD-TBD deferral comments inside source files are permitted; reports of deferred items go in the report's \"Deferred items\" section." | lifecycle-description |

### §3.32 — `project-template/.claude/skills/pm-startup/SKILL.md` + `project-template/.codex/skills/pm-startup/SKILL.md` + `project-template/skills/pm-startup/SKILL.md` + `project-template/.gemini/commands/pm-startup.toml`

These four files have identical TD-TBD-check content (mirrored Tier-0 skill / per-CLI surfaces).

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.32.1 | 3 | L178 / L175 / L178 / L175 | "## Step 5 — Check for TD-TBD sentinel" | lifecycle-description |
| A-3.32.2 | 3 | L181 / L178 / L181 / L178 | "grep -rn \"TD-TBD\" . --include=\"*.swift\" --include=\"*.py\" --include=\"*.md\" \\" | lifecycle-description |
| A-3.32.3 | 3 | L199-200 / L196-197 / L199-200 / L196-197 | "**Last TD number:** TD-NNN (or \"none yet\" if BACKLOG is empty) / **TD-TBD check:** [Clean / N instances found — [files]]" | lifecycle-description |

### §3.33 — `project-template/skills/audit-methodology/SKILL.md`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.33.1 | 1, 2, 6 | L76 | "Per-entry tree files (`docs/project/backlog/BD-NNN.md`, `docs/project/implementation-plan/phase-N.md`, `docs/project/changelog/YYYY-MM-DD-*.md`, including each stream's `_rules.md`, `_intro.md`, `_toc.md`, `_format.md` ..." — Skill explicitly lists `docs/project/backlog/BD-NNN.md` as a PROJECT-SIDE per-entry file shape (i.e., admits BD-NNN as a project-side entity-file pattern). NOTE: per user-locked rule, project-side `docs/project/backlog/` is the TD store; this BD-NNN.md cite is ambiguous re: whether it describes the pack-side mirror or admits BD-NNN to the project side. | grammar-admission |

### §3.34 — `project-template/skills/boundary-investigation/SKILL.md`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.34.1 | 1 | L33 | "The audit BD-175 (P-missed-7) documented the regression mechanism this" | literal-match |
| A-3.34.2 | 1 | L169 | "## Worked example (BD-175 V1 anti-pattern)" | literal-match |

### §3.35 — `project-template/skills/python-data-architecture/SKILL.md`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.35.1 | 1 | L27-28 | "skill, split in v11.0 by BD-141 (the `python_data_marker_detected()` / load predicate) and BD-143 (the trinity SKILL.md split into" | literal-match |

### §3.36 — `project-template/skills/python-server-architecture/SKILL.md`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.36.1 | 1 | L16-17 | "skill, split in v11.0 by BD-141 (the `python_data_marker_detected()` / load predicate) and BD-143 (the trinity SKILL.md split into" | literal-match |

### §3.37 — `project-template/skills/python-observability-patterns/SKILL.md`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.37.1 | 1 | L20 | "(see `docs/pack/PLATFORM-SKILLS.md` Intersection table; BD-162)." | literal-match |

### §3.38 — `project-template/skills/swift-best-practices/SKILL.md`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.38.1 | 1 | L92 | "*(AsyncStream payload design — relocated to `swift-concurrency-patterns` as part of the BD-158 split.)*" | literal-match |

### §3.39 — `project-template/skills/swift-concurrency-patterns/SKILL.md`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.39.1 | 3 | L188 | "a TD-TBD comment naming the upstream issue / version that" | lifecycle-description |

### §3.40 — `project-template/docs/project/backlog/_intro.md`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.40.1 | 1, 6 | L3 | "corresponding docs/project/backlog/<TD-NNN>.md per-entry file" — project-side per-entry shape uses TD-NNN. | grammar-admission |
| A-3.40.2 | 1, 6 | L10 | "tree at `docs/project/backlog/`. The per-entry tree is where TD-NNN" | grammar-admission |
| A-3.40.3 | 1, 6 | L16-18 | "Read this file for a full TD-NNN inventory. / For a single entry, read the per-entry file directly at / `docs/project/backlog/<TD-NNN>.md`." | grammar-admission |
| A-3.40.4 | 1, 6 | L24-26 | "Find the highest existing `TD-NNN`, / increment by 1, write a new per-entry file at / `docs/project/backlog/TD-NNN.md`." | grammar-admission |
| A-3.40.5 | 1, 6 | L34 | "**Cross-references.** TD-NNN, BD-NNN, phase-N, phase-N.M / identifiers may appear in `Blockers:` / `Unblocks:` / prose." — PROJECT-SIDE per-entry intro admits BD-NNN as a cross-reference identifier that "may appear" in Blockers/Unblocks/prose. | grammar-admission |

### §3.41 — `project-template/docs/project/backlog/_rules.md`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.41.1 | 1, 2, 6 | L14-15 | "Per-entry files match `^TD-\\d+\\.md$` (e.g., `TD-001.md`). Three- / digit zero-padded TD-NNN." — explicit filename regex bars BD-NNN.md from the project-side per-entry tree (positive boundary statement). | grammar-admission (negative form) |
| A-3.41.2 | 1, 2, 6 | L22 | "`**TD-NNN — <Title>**`." — entry header form is TD-NNN. | grammar-admission |

### §3.42 — `project-template/docs/project/changelog/_format.md`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.42.1 | 3 | L23 | "**Backlog items addressed**: TD-NNN resolved. TD-NNN, TD-NNN" — changelog format template. | lifecycle-description |
| A-3.42.2 | 3 | L25 | "TD-NNN–TD-NNN created from §N.M audit." | lifecycle-description |

### §3.43 — `project-template/docs/project/changelog/_rules.md`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.43.1 | 1 | L18 | "`scripts/lib/per-entry/_lib.sh` post-BD-164-retro Option B" | literal-match |

### §3.44 — `supporting-docs/METHODOLOGY.md`

The methodology document is byte-copied to client `docs/pack/METHODOLOGY.md` at S6 (per init-project.sh stage S6).

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.44.1 | 3 | L211 | "or language-equivalent) must have a corresponding BACKLOG.md entry. `TD-TBD` in any" | lifecycle-description |
| A-3.44.2 | 1, 2, 6 | L386-388 | "TD entry (`TD-NNN`), or a BD entry (`BD-NNN`). Trailing free-text after the ID / is preserved as a human-readable annotation. Parser regex: / `^\\s*-\\s+(phase-\\d+(\\.\\d+)?\|TD-\\d+\|BD-\\d+)(\\s+(.*))?$`." — Dependencies grammar in client-shipped METHODOLOGY admits BD-NNN. Parser regex bakes BD-NNN admission into client-side phase-task Dependencies semantic. | grammar-admission |
| A-3.44.3 | 6 | L394 | "- TD-029" (example in the Dependencies bullet form). | grammar-content |
| A-3.44.4 | 1 | L1168-1176 | Typed-deferral block (`// TODO(scope): TD-TBD`, `// KNOWN GAP(severity): TD-TBD`, `// VERIFY(source): TD-TBD`) for Swift and Python. | lifecycle-description |
| A-3.44.5 | 3 | L1190-1192 | "**The TD-TBD sentinel:** The coder always writes `TD-TBD` in deferral comments — never a / real number. The PM chat replaces `TD-TBD` with a real `TD-NNN` when the BACKLOG entry is / created after user approval." | lifecycle-description |
| A-3.44.6 | 3 | L1202-1208 | BACKLOG-item-format template: "**TD-NNN — [Short title]** ... Blockers: ... [Named specific dependency — phase N, phase N.M (v11.0 additive), TD-NNN, or external condition]" | lifecycle-description |
| A-3.44.7 | 3 | L1248 | "TD-NNN blocker: does that item have Status: Resolved?" | lifecycle-description |
| A-3.44.8 | 3 | L1255 | "to ask. (\"TD-NNN is now unblocked by Phase N completion.\")" | lifecycle-description |
| A-3.44.9 | 3 | L1260-1261 | "Run TD-TBD grep check: / Swift/C/C++/ObjC: grep -rn \"TD-TBD\" ." | lifecycle-description |
| A-3.44.10 | 3, 4 | L1283-1320 | "**Resolution path decision logic**" full section — describes direct close, Path 1 (`pack td promote --to=phase-N`; new phase epic at L1), Path 2 (`pack td promote --to=phase-N.M`; new phase task at L2 under existing phase). Path 2 target is `phase-N.M` (task), NOT `Phase-N.Part-x` (consistent with user-locked rule). "**Path 3 is forbidden** (supersedes the v10 fold-into-existing-task shape)." L1313. NO `--fold-into` flag. | path-reference + lifecycle-description |
| A-3.44.11 | 4 | L1295-1307 | Explicit Path 1 / Path 2 verbs + carriers: "Path 1 — promote to a new phase epic / (verb: `pack td promote --to=phase-N`; / new phase epic at L1; `derived-from:TD-NNN` on phase / epic; `promoted-to:phase-N` on closed TD;" + "Path 2 — promote to a new phase task under existing phase / (verb: `pack td promote --to=phase-N.M`; / new phase task at L2 child of phase-N epic; / `derived-from:TD-NNN` on task; `promoted-to:phase-N.M`" | path-reference |
| A-3.44.12 | 4 | L1313-1320 | "**Path 3 is forbidden** ... the user edits the absorbing task body manually via PM / Chat ... OR uses Path 2 with a `Dependencies` bullet pointing at the / absorbing task ... The / `pack td promote` verb has no `--fold-into` flag." | path-reference |
| A-3.44.13 | 3 | L1325-1338 | Procedure 2 Post-session processing: "Read the \"Deferred items\" section..." through "Confirm no TD-TBD remains in any file touched this session" | lifecycle-description |
| A-3.44.14 | 3 | L1348-1349 | "grep -rn \"TD-TBD\" . / 3. For each TD-NNN found in comments:" (Procedure 3 orphan audit) | lifecycle-description |
| A-3.44.15 | 3 | L1375 | "TD-NNN; set those to Unblocked if all their other blockers are also resolved" | lifecycle-description |
| A-3.44.16 | 3 | L1377 | "TD-NNN; flag each one for user review — do not automatically set to Unblocked." | lifecycle-description |
| A-3.44.17 | 1 | L1393 | "*Relocated to [`INSTALL-PROCEDURES.md`](INSTALL-PROCEDURES.md) per BD-059. See that file for Procedure 5 and its sub-procedures (5.1–5.6).*" | literal-match |
| A-3.44.18 | 1 | L1422 | "active dimension and (as of BD-048) drives Form-I follow-ups for any" | literal-match |
| A-3.44.19 | 3 | L1475 | "Tell the PM chat in conversation: \"Cancel TD-NNN\" or \"Deprecate TD-NNN — [brief reason].\"" | lifecycle-description |
| A-3.44.20 | 3 | L1483 | "names this TD-NNN; present each to you for a decision — do not automatically" | lifecycle-description |
| A-3.44.21 | 3 | L1492 | "\| `coder` \| Write TD-TBD deferral comments in code; report deferred items in completion report \| Write to BACKLOG.md; resolve or modify existing entries \|" | lifecycle-description |
| A-3.44.22 | 3 | L1496 | "\| PM chat \| Write and update BACKLOG.md after user approval; replace TD-TBD with TD-NNN or remove rejected comments in source files \| Any other source code changes \|" | lifecycle-description |
| A-3.44.23 | 3 | L1564 | "\| Deferral comments in source \| Writes TD-TBD only \| Never \| Replaces TD-TBD with TD-NNN or removes \| See Part 7 \|" | lifecycle-description |
| A-3.44.24 | 3 | L1583 | "Adding, modifying, or removing deferral comments in source files (TD-TBD → TD-NNN," | lifecycle-description |
| A-3.44.25 | 1 | L1675 | "(post-BD-042 relocation), with `BACKLOG.md` and `STATUS.md` remaining" | literal-match |
| A-3.44.26 | 3 | L1712 | "items, run TD-TBD grep, run orphan audit, run skill gap check — resolve all" | lifecycle-description |

### §3.45 — `supporting-docs/INSTALL-PROCEDURES.md`

Client-shipped at S6.

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.45.1 | 1 | L24 | "retired in v11 per BD-121). The project-side canonical location is" | literal-match |
| A-3.45.2 | 1 | L225 | "> **HISTORICAL — sunset in v11 (BD-121).** The v9->v10 migrator and" | literal-match |
| A-3.45.3 | 1 | L228 | "> migrator framework (BD-119, `scripts/lib/migrator-core.sh` +" | literal-match |
| A-3.45.4 | 1 | L229 | "> the BD-088 customization-preservation library) handles" | literal-match |
| A-3.45.5 | 1 | L664 | "4. **Apply trinity rule for tool-config parity (per BD-059 success" | literal-match |
| A-3.45.6 | 1 | L898 | "> **HISTORICAL — sunset in v11 (BD-121).** This procedure was" | literal-match |

### §3.46 — `supporting-docs/MIGRATION-v10-to-v11.md`

NOT client-shipped (per pack memory: "supporting-docs/MIGRATION-v10-to-v11.md edit which is a pre-install reference not copied to clients"). Listed here for completeness; Surface A boundary admits this file.

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.46.1 | 1 | L10-11 | "BD-042 doc relocation tail. Driven by `scripts/migrate-v10-to-v11.sh` / (BD-085)." | literal-match |
| A-3.46.2 | 1 | L18 | "in v11 (BD-121); v9 is no longer supported. Reach out to the pack" | literal-match |
| A-3.46.3 | 1 | L41 | "- BD-088 customization-preservation contract: `init-project.sh --update`" | literal-match |
| A-3.46.4 | 1 | L44 | "- BD-042 relocation tail: any v9-era reference docs still at project" | literal-match |
| A-3.46.5 | 1 | L68 | "(BD-109 client-side, BD-110 pack-side) is on the v11.x roadmap; the" | literal-match |
| A-3.46.6 | 1 | L76 | "v11.0 by BD-095. Bare invocation defaults to `--apply` and" | literal-match |
| A-3.46.7 | 1 | L83 | "## Skill model changes (BD-142, BD-148)" | literal-match |
| A-3.46.8 | 1 | L114 | "Python skill split shipped as BD-035 and handled by Stage S5b of" | literal-match |
| A-3.46.9 | 1 | L146 | "`docs/pack/PLATFORM-SKILLS.md.v10-customized` (per the BD-088" | literal-match |
| A-3.46.10 | 1 | L152 | "preserved by the BD-088 customization-preserve sidecar mechanism" | literal-match |
| A-3.46.11 | 1 | L156 | "4. **Custom agents column header rename (BD-142 F3 / BD-148).**" | literal-match |
| A-3.46.12 | 1 | L162 | "deprecated headers, the BD-088 sidecar mechanism preserves the" | literal-match |
| A-3.46.13 | 1 | L177 | "ships the v11 PLATFORM-SKILLS.md template and the BD-088 mechanism" | literal-match |
| A-3.46.14 | 1 | L181 | "The one skill *rename* in v11 — the BD-035 Python split" | literal-match |
| A-3.46.15 | 1 | L186 | "of the dimension reframe (it landed in v11.0 with BD-035). See" | literal-match |
| A-3.46.16 | 1 | L188 | "`PLAN-SKILL-DIMENSIONS.md` BD-147 for the planned extraction into" | literal-match |
| A-3.46.17 | 1 | L191-194 | "### BD-136 trinity-marker non-overlap / / The dimension reframe and the BD-136 trinity-marker / preservation mechanism are **non-overlapping**: BD-136 introduces" | literal-match |
| A-3.46.18 | 1 | L199 | "at `docs/pack/`, not at project root) and does NOT use the BD-136" | literal-match |
| A-3.46.19 | 1 | L203 | "BD-143 to describe the 5+3 model and to point at PLATFORM-SKILLS.md" | literal-match |
| A-3.46.20 | 1 | L209 | "list change only for the BD-035 Python split case (handled by S5b" | literal-match |
| A-3.46.21 | 1 | L213-214 | "The two mechanisms — BD-088 PLATFORM-SKILLS.md customization- / preservation (sidecar-based) and BD-136 trinity-marker preservation" | literal-match |
| A-3.46.22 | 1, 2, 6 | L258 | "- One Markdown file per entry (e.g., `docs/project/backlog/BD-NNN.md`," — describes a per-entry file path shape using BD-NNN.md. (Same ambiguity as §3.33.1.) | grammar-admission |
| A-3.46.23 | 1 | L343 | "mirror-vs-source treatment in the BD-088 customization-preserve" | literal-match |
| A-3.46.24 | 1 | L389 | "framework's single S4 stage and share the BD-095 sentinel" | literal-match |
| A-3.46.25 | 1 | L394 | "\| S0 \| Pre-flight (pack valid, BD-088 lib present, target git, clean tree, v10-shaped, v10 tag resolves) \|" | literal-match |
| A-3.46.26 | 1 | L396 | "\| S2 \| Initialize BD-088 customization-preserve state \|" | literal-match |
| A-3.46.27 | 1 | L397 | "\| S3 \| Dispatch v10 → v11 changes via BD-088 (trinity / configs / scripts / agents / docs) \|" | literal-match |
| A-3.46.28 | 1 | L398 | "\| S4a \| BD-104 rename `IMPLEMENTATION_PLAN.md` → `IMPLEMENTATION-PLAN.md`..." | literal-match |
| A-3.46.29 | 1 | L399 | "\| S4b \| BD-042 relocation tail (legacy root docs → `docs/pack/`) \|" | literal-match |
| A-3.46.30 | 1 | L413 | "\| 15 \| BD-088 library missing under pack \| The pack repo is corrupt or incomplete; re-clone. \|" | literal-match |
| A-3.46.31 | 1 | L415 | "\| 31 \| `EXIT_GATE_FAILED` — BD-101 verification gate ..." | literal-match |
| A-3.46.32 | 1 | L417 | "**BD-101 verification gates.** During `--dry-run` and `--apply` the" | literal-match |
| A-3.46.33 | 1 | L445 | "The report is **truthful** (BD-059 / BD-088 contract): every file the" | literal-match |
| A-3.46.34 | 1 | L576 | "## BD-059 lessons learned — customization preservation" | literal-match |
| A-3.46.35 | 1 | L579-581 | "BD-121) had a defect class that / shapes (BD-059 in the BACKLOG). v11 fixes this with the BD-088" | literal-match |
| A-3.46.36 | 1 | L595-596 | "4. **CI regression guard.** validate-pack Check 25 (BD-089) runs a / 4-fixture synthetic on every push to fail-closed if BD-088" | literal-match |
| A-3.46.37 | 1 | L599 | "BD-083." | literal-match |
| A-3.46.38 | 1 | L656 | "are preserved unchanged (BD-088 `claude-settings` allowlist)." | literal-match |
| A-3.46.39 | 1 | L711 | "### My customizations weren't preserved (BD-059 class regression)" | literal-match |
| A-3.46.40 | 1 | L722 | "guards against this; if either is silenced or removed, BD-059 class" | literal-match |

### §3.47 — `supporting-docs/SETUP-NEW.md`

Client-relevant pre-install reference (NOT client-shipped per S6 list; user-facing setup doc.)

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.47.1 | 1 | L11 | "v9->v10 migrator was sunset in v11 per BD-121; v9.x is no longer" | literal-match |
| A-3.47.2 | 1 | L94 | "guide; v9.x is no longer supported per BD-121)." | literal-match |
| A-3.47.3 | 1 | L156 | "this Step 5 by BD-047 (Phase 3-B). Step numbering is preserved for cross-doc" | literal-match |
| A-3.47.4 | 1 | L466 | "migrator was sunset in v11 per BD-121); reach out to the pack" | literal-match |

### §3.48 — `supporting-docs/SETUP-EXISTING.md`

Client-relevant pre-install reference (NOT client-shipped per S6 list.)

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| A-3.48.1 | 1 | L150 | "Step 5 by BD-047 (Phase 3-B). Step numbering is preserved for cross-doc" | literal-match |

### §3.49 — Other Surface A files with no BD/TD/Path findings

The following Surface A files were scanned and contain no findings against the 6 dimensions:

- `project-template/README.md`
- `project-template/pyproject.toml`, `project-template/pyrightconfig.json`, `project-template/.mcp.json.example`
- `project-template/agent-run.sh`
- `project-template/.claude/settings.json`, `.claude/settings.local.example.json`
- `project-template/.codex/requirements.toml`
- `project-template/.gemini/settings.json`
- `project-template/proto/buf.yaml`, `proto/buf.gen.yaml`, `proto/common/v1/common.proto`, `proto/example/v1/example_service.proto`
- `project-template/scripts/*.sh` (build / format / test scripts; no BD/TD references in shell logic)
- `project-template/server/src/app/__init__.py`, `project-template/server/tests/test_smoke.py`
- `project-template/docs/pack/OPTIONAL-FEATURES.md`, `docs/pack/PACK-FEEDBACK.md`
- `project-template/.codex/agents/{architect,planner,reviewer,repo-ops,docs-researcher,grpc-schema,auditor,auditor-architecture,auditor-code,auditor-docs,auditor-ops,auditor-security,auditor-tests,auditor-ui,tester}.toml`
- `project-template/.claude/agents/{architect,planner,reviewer,repo-ops,docs-researcher,grpc-schema,auditor,auditor-architecture,auditor-code,auditor-docs,auditor-ops,auditor-security,auditor-tests,auditor-ui,tester}.md` (only `coder.md` has findings; see §3.29)
- `project-template/.gemini/agents/*.md` (only `coder.md` has findings; see §3.30)
- `project-template/.gemini/commands/pack-help.toml`
- `project-template/.claude/skills/pack-help/SKILL.md`, `.codex/skills/pack-help/SKILL.md`
- `project-template/skills/*` (all non-listed skills); the listed skills above are the only `project-template/skills/` files with findings
- `project-template/docs/pack/prompts/{architect,planner,docs-researcher,grpc-schema,repo-ops,tester}.md` (no BD/TD/Path findings)
- `project-template/docs/project/implementation-plan/{_intro,_rules}.md`
- `project-template/docs/project/changelog/_intro.md`
- `supporting-docs/AGENT_KICKOFF_TEMPLATE.md`
- `supporting-docs/CLI-PM-SETUP.md`
- `supporting-docs/DEPENDENCIES.md`
- `supporting-docs/SETUP_TEMPLATE.md`
- `supporting-docs/MIGRATION-v8-to-v9.md`
- `maintenance-docs/v11-research/templates-archive/translations.yaml`

---

## §4 — Surface B findings

### §4.1 — `scripts/init-project.sh`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| B-4.1.1 | 7 | L823-825 | `if [[ -f "$PACK/pack-ops/HELP-FRAGMENT-TRACKER.md" ]]; then` / `cp -f "$PACK/pack-ops/HELP-FRAGMENT-TRACKER.md" \` / `"$TARGET/docs/pack/HELP-FRAGMENT-TRACKER.md"` — DIRECT copy of `pack-ops/HELP-FRAGMENT-TRACKER.md` to client `docs/pack/HELP-FRAGMENT-TRACKER.md`. This is the canonical violation cited in the audit prompt Rule 5. | script-copy-violation |
| B-4.1.2 | 7 | L820-822 (preceding-comment context) | "# BD-175: HELP-FRAGMENT-TRACKER.md canonical source is pack-ops/ post-reorg. / # Retain $PACK/HELP-FRAGMENT-TRACKER.md fallback for pre-v11 layouts / # (e.g., migration mid-flight, or PACK pointing at a pre-BD-175 tag)." — comment documents the BD-175 design intent. | script-copy-violation (rationale comment) |
| B-4.1.3 | 7 | L826-828 (fallback branch) | `elif [[ -f "$PACK/HELP-FRAGMENT-TRACKER.md" ]]; then` / `cp -f "$PACK/HELP-FRAGMENT-TRACKER.md" \` / `"$TARGET/docs/pack/HELP-FRAGMENT-TRACKER.md"` — FALLBACK branch copies `$PACK/HELP-FRAGMENT-TRACKER.md` (pack-root, pre-BD-175 layout) to client `docs/pack/HELP-FRAGMENT-TRACKER.md`. Also constitutes a pack-internal-source-to-client copy. | script-copy-violation |
| B-4.1.4 | — | L1308-1309 (trailing manifest comment) | "#   pack-ops/HELP-FRAGMENT-TRACKER.md  ->  docs/pack/HELP-FRAGMENT-TRACKER.md  [stage:S11]" + "#   project-template/docs/pack/HELP-FRAGMENT-TRACKER.md  ->  docs/pack/HELP-FRAGMENT-TRACKER.md  [stage:S6,cmd_update]" — documents both copy paths in the file-pair manifest comment block. (NOTE: the S6 copy from `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` is the alternate source path; per audit Rule 5, this is the CORRECT source. The S11 copy from `pack-ops/` violates Rule 5.) | script-copy-violation (manifest comment) |
| B-4.1.5 | — | L1146 | "project-template/docs/pack/HELP-FRAGMENT-TRACKER.md:docs/pack/HELP-FRAGMENT-TRACKER.md:generic" — file-pair table entry naming the project-template source for the file-pair manifest. This is the CORRECT-source row per Rule 5 (project-template, NOT pack-ops). Coexists with the S11 violation at L823-825. | (cross-reference: confirms a project-template source exists; coexistence with §B-4.1.1 violation) |

**Coverage note:** the audit prompt names L823-825 as one KNOWN instance and asks "find all others." Scanning `scripts/init-project.sh` exhaustively (grep for `pack-ops`, lines L1-end): only the cluster at L820-833 is a pack-ops→client copy. No other `pack-ops/*` → `$TARGET/*` copy was found in this file.

### §4.2 — `scripts/pack-help.sh`

`scripts/pack-help.sh` READS pack-ops/ fragments for emission to the user's terminal but does NOT COPY them to the project install path. Per Rule 5 (which targets script-copy-to-install-path violations specifically), reads are not violations.

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| B-4.2.1 | — (read-only, not a copy violation) | L117-118, L124-125, L140, L143, L162 | `if [[ -f "$root/pack-ops/HELP-FRAGMENT-PACK.md" ]]; then / echo "$root/pack-ops/HELP-FRAGMENT-PACK.md"` etc. — pack-help.sh resolves pack-ops paths at READ time when running inside the pack repo. No cp/mv to a client target path. | (NOT a script-copy-violation; read-only resolution) |

NOTE: Phase 2 reviewer may consider whether pack-help.sh's READ of `pack-ops/HELP-FRAGMENT-TRACKER.md` (when invoked from a CLIENT install) is a downstream consequence of the L823-825 copy violation (i.e., the client has the file at `docs/pack/HELP-FRAGMENT-TRACKER.md`, sourced from `pack-ops/` per S11). This is OUT OF DIMENSION 7 SCOPE (which targets COPY violations only); flagged here for Phase 2 context.

### §4.3 — `scripts/migrate-v10-to-v11.sh` + `scripts/lib/migrate-v10-to-v11/*`

Scanned for `pack-ops/*` → client copy patterns. None found.

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| B-4.3.1 | — | (no findings) | No pack-ops→client copy in migration script. | (no findings) |

### §4.4 — `scripts/pack-tracker.sh` + `scripts/pack-td.sh` + `scripts/add-capability.sh` + other root scripts

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| B-4.4.1 | — (read-only) | `scripts/pack-tracker.sh:369` | "# Surface auto-detected from pack-ops/ directory (pack) or docs/pack/" — pack-tracker.sh detects which surface (pack vs project) it's running in by checking pack-ops/ presence. No copy. | (NOT a script-copy-violation; surface-detection only) |
| B-4.4.2 | — | scripts/dry-run-migration.sh, scripts/restore-from-backup.sh, scripts/validate-pack.py, scripts/compare-agent-trinity.py, scripts/merge-*.py, scripts/tracker-migrate.sh | No pack-ops→client copy patterns found. | (no findings) |

### §4.5 — `scripts/lib/*.sh`

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| B-4.5.1 | — | (lib scripts) | `scripts/lib/*.sh` are pack-internal libraries sourced by pack-tracker.sh / migrate-v10-to-v11.sh / etc. None copy pack-ops/* to a client install path. | (no findings) |

### §4.6 — `scripts/tests/*.sh`

Test scripts populate scratch repos with synthetic fixtures; they copy `pack-ops/*` content INTO `$test_repo/pack-ops/*` (i.e., into a TEST-FIXTURE pack-ops directory inside the synthetic pack root), NOT into a client install path. These are NOT Rule 5 violations.

| # | Dim | Location | Context | Initial-category |
|---|---|---|---|---|
| B-4.6.1 | — (test-fixture, not client install) | `scripts/tests/pack-help-test.sh:196-197` | `cp "$REPO_ROOT/pack-ops/HELP-FRAGMENT-PACK.md" "$TR_OV/pack-ops/"` + `cp "$REPO_ROOT/pack-ops/HELP-FRAGMENT-TRACKER.md" "$TR_OV/pack-ops/"` — test fixture setup, NOT a client install path. | (NOT a script-copy-violation; test-fixture provisioning) |
| B-4.6.2 | — (test-fixture) | `scripts/tests/tracker-migrate-roundtrip-test.sh:349`, `scripts/tests/tracker-migrate-forward-test.sh:288,401,429,509,633,668,756,952,1061`, `scripts/tests/recommendation-test.sh:38`, `scripts/tests/tracker-init-test.sh:77` | All copy fixture content INTO a synthetic test repo's `pack-ops/` directory (a scratch pack root), not to a client install target. | (NOT a script-copy-violation) |

**Surface B summary:** the ONLY direct pack-ops→client-install copy violations are in `scripts/init-project.sh` L820-833 (cluster: primary cp at L823-825 + fallback cp at L826-828 + supporting comments at L820-822 and L1308-1309). All other `pack-ops` references in scripts are either (a) reads for surface detection / help emission, (b) test-fixture provisioning, or (c) pack-internal library code that does not touch client install paths. The S6 file-pair manifest at L1146 documents the CORRECT-source (project-template) parallel path that coexists with the violating S11 path.

---

## §5 — Summary tables

### §5.1 — Count per dimension per surface

| Surface | Dim 1 | Dim 2 | Dim 3 | Dim 4 | Dim 5 | Dim 6 | Dim 7 | Total findings |
|---|---|---|---|---|---|---|---|---|
| A (project-template/) | ~30 | ~5 | ~25 | ~10 | 0 | ~10 | — | ~60 |
| A (supporting-docs/) | ~50 | 1 | ~25 | ~5 | 0 | 1 | — | ~70 |
| A (templates-archive/v11.0/) | ~12 | ~10 | ~3 | 1 | 0 | ~8 | — | ~25 |
| A (templates-archive/v11.1/) | ~30 | ~3 | ~2 | 0 | 1 (negative form) | ~3 | — | ~35 |
| B (scripts/) | — | — | — | — | — | — | 4 finding rows (1 site cluster + supporting rows) | 4 rows; 1 violation cluster |

NOTE: Counts are approximate (some findings hit multiple dimensions and are counted once per dimension). The "Total findings" column counts distinct finding rows above.

### §5.2 — Quick-scan: high-signal findings

| Quick-scan ID | Surface / Dim | File / Location | Note |
|---|---|---|---|
| QS-1 | A / Dim 1+2+6 | `templates-archive/v11.0/INDEX.md:10` | BD-NNN listed as 1st entry type in client-facing-grammar INDEX (v11.0 cut). |
| QS-2 | A / Dim 1+2+6 | `templates-archive/v11.0/bd-v11.0/SCHEMA.md` (entire file) | Defines BD-NNN as a SCHEMA entry type (with body marker, label family, body section grammar, reverse-emit). |
| QS-3 | A / Dim 1+2+6 | `templates-archive/v11.0/phase-task-v11.0/SCHEMA.md:79,91` | Dependencies grammar admits BD-NNN as dep type. |
| QS-4 | A / Dim 1+2+6 | `templates-archive/v11.0/forms/work-item.yml:2,3,23,105,169` | Form grammar admits BD-NNN as entry type AND in Blockers/Dependencies. |
| QS-5 | A / Dim 1+2+6 | `templates-archive/v11.1/INDEX.md:17` | v11.1 INDEX inherits BD-NNN as entry type into v11.1 cut. |
| QS-6 | A / Dim 1+2+6 | `templates-archive/v11.1/phase-part-v11.1/SCHEMA.md:129-130,152` | NEW v11.1 Prerequisites grammar admits BD-NNN as dep type. |
| QS-7 | A / Dim 5 (negative form) | `templates-archive/v11.1/phase-part-v11.1/SCHEMA.md:83-85` | EXPLICIT statement that TDs do NOT derive Parts — consistent with user-locked rule. |
| QS-8 | A / Dim 1+2+6 | `project-template/.github/ISSUE_TEMPLATE/work-item.yml:25,171` | PROJECT-side form admits `bd` dropdown value AND BD-NNN in Dependencies grammar. |
| QS-9 | A / Dim 1+2+6 | `project-template/docs/project/backlog/_intro.md:34` | PROJECT-side per-entry intro admits BD-NNN as cross-reference identifier. |
| QS-10 | A / Dim 1+2+6 | `supporting-docs/METHODOLOGY.md:386-388` | Client-shipped Dependencies grammar parser regex admits `BD-\d+`. |
| QS-11 | A / Dim 3+4 | `project-template/docs/pack/PM-CHAT.md:540-650` | Full TD resolution orchestration section (Path 1 / Path 2 / Path 3-forbidden) — describes TD lifecycle paths. Path 2 target is `phase-N.M` (task), NOT `Phase-N.Part-x` (consistent with user-locked rule). |
| QS-12 | A / Dim 3+4 | `supporting-docs/METHODOLOGY.md:1283-1320` | Full Resolution path decision logic (Direct close / Path 1 / Path 2 / Path 3-forbidden) — client-shipped. Path 2 target is `phase-N.M`. |
| QS-13 | A / Dim 3+4 | `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md:17-46` | Path 1 / Path 2 / Path 3-forbidden in client-shipped help fragment. |
| QS-14 | A / Dim 3+4 | `project-template/docs/pack/HELP-FRAGMENT.md:19-20` | Path 1 / Path 2 in client-shipped verb manifest. |
| QS-15 | B / Dim 7 | `scripts/init-project.sh:823-825` | **PRIMARY VIOLATION** — cp `$PACK/pack-ops/HELP-FRAGMENT-TRACKER.md` → `$TARGET/docs/pack/HELP-FRAGMENT-TRACKER.md` at S11. |
| QS-16 | B / Dim 7 | `scripts/init-project.sh:826-828` | **SECONDARY VIOLATION** — fallback cp `$PACK/HELP-FRAGMENT-TRACKER.md` (pre-v11 layout) → `$TARGET/docs/pack/HELP-FRAGMENT-TRACKER.md`. |
| QS-17 | A / Dim 1+2 | `project-template/skills/audit-methodology/SKILL.md:76` | PROJECT-side skill names `docs/project/backlog/BD-NNN.md` as a per-entry file pattern (ambiguous — does it describe the pack mirror or admit BD-NNN as project-side per-entry pattern?). |
| QS-18 | A / Dim 1+2 | `supporting-docs/MIGRATION-v10-to-v11.md:258` | "- One Markdown file per entry (e.g., `docs/project/backlog/BD-NNN.md`," — same ambiguity pattern as QS-17. |

### §5.3 — Count per file (top contributors by finding density)

| File | Count |
|---|---|
| `supporting-docs/MIGRATION-v10-to-v11.md` | ~40 findings (Dim 1 dominant, no Path/TD-lifecycle since this is a migration scope) |
| `templates-archive/v11.1/phase-part-v11.1/SCHEMA.md` | ~26 findings (Dim 1 dominant — heavy BD-185 cross-refs; ~3 grammar-admission) |
| `supporting-docs/METHODOLOGY.md` | ~26 findings (mix of Dim 1, Dim 3, Dim 4, Dim 6) |
| `project-template/docs/pack/PM-CHAT.md` | ~18 findings (Path 1/2/3 + TD lifecycle + Dim 1) |
| `templates-archive/v11.1/INDEX.md` | ~13 findings (Dim 1 dominant) |
| `templates-archive/v11.0/bd-v11.0/SCHEMA.md` | ~10 findings (Dim 1+2 grammar-admission) |
| `supporting-docs/INSTALL-PROCEDURES.md` | 6 findings (Dim 1) |
| `scripts/init-project.sh` (Surface B) | 4 finding rows, 1 violation cluster |

### §5.4 — Distribution of Path-references (Dim 4)

| Path | Files referencing it | Notable contexts |
|---|---|---|
| Path 1 (TD → new phase epic; `pack td promote --to=phase-N`) | PM-CHAT.md, HELP-FRAGMENT-TRACKER.md, HELP-FRAGMENT.md, METHODOLOGY.md, phase-epic-v11.0/SCHEMA.md (carrier label), td-v11.0/SCHEMA.md (carrier label) | Path 1 target is the new phase EPIC. |
| Path 2 (TD → new phase task; `pack td promote --to=phase-N.M`) | PM-CHAT.md, HELP-FRAGMENT-TRACKER.md, HELP-FRAGMENT.md, METHODOLOGY.md, phase-task-v11.0/SCHEMA.md (carrier label), td-v11.0/SCHEMA.md (carrier label) | Path 2 target is `phase-N.M` (existing-phase task). NO file admits `Phase-N.Part-x` as a Path 2 target (consistent with user-locked rule). |
| Path 3 (FORBIDDEN; `--fold-into` no-op) | PM-CHAT.md, HELP-FRAGMENT-TRACKER.md, METHODOLOGY.md | Explicit "forbidden" statements; consistent across files. |
| Direct close (no promotion; `pack td resolve`) | PM-CHAT.md, HELP-FRAGMENT-TRACKER.md, HELP-FRAGMENT.md, METHODOLOGY.md | Wrapper around v10 lifecycle. |

---

## §6 — Cross-references

### §6.1 — User-locked rules (from audit prompt; verbatim summary)

1. **BD entries are PACK-ONLY.** BDs live in `pack-ops/BACKLOG.md` and pack-internal contexts. BDs MUST NOT appear as a client-facing concept in:
   - `project-template/**` (client install)
   - `supporting-docs/**` (client-shipped at S6)
   - `maintenance-docs/v11-research/templates-archive/v11.0/`, `v11.1/` SCHEMAs that describe client-facing entity formats (BD-NNN MUST NOT be admitted as a dependency type for client entities; bd-v11.0 enumeration as a client entity type is wrong)

2. **TD entries are CLIENT-ONLY.** TDs live in client `docs/project/backlog/`. TDs interact ONLY with phases (not Parts).

3. **TD lifecycle rules (user-locked 2026-05-26):**
   - TDs are NOT in the implementation plan by default
   - TDs become scheduled via user choice OR backlog triage
   - Large TD that doesn't fit existing phase → NEW PHASE (Path 1)
   - Small TD that fits existing phase → NEW TASK in existing phase (Path 2 with `Phase-N` target ONLY)
   - Small TD that doesn't fit any phase → NEW small phase (variant of Path 1)
   - **TDs MUST NOT promote to Parts** (POQ-4 reversed; Path 2 target is `Phase-N` ONLY, not `Phase-N.Part-x`)
   - Path 3 (TD --fold-into=phase-N.M) is FORBIDDEN per INV-6

4. **Pack-ops/ is PACK-ONLY (USER DIRECTIVE 2026-05-26).** Files in `pack-ops/` are pack-internal artifacts. Even if init-project.sh currently copies some pack-ops/ files to client install, that is a VIOLATION.

5. **SCRIPTS/ COPY VIOLATION RULE (user-locked 2026-05-26):** Any script in root `/scripts/` (or anywhere else) that COPIES pack-ops/ files into a project install path is CATEGORICALLY WRONG.

### §6.2 — ARCHITECTURE-BD-185.md §1.4 Decision log

The 16 USER-LOCKED decisions D1-D16 are recorded in
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md` §1.4.
Key decisions relevant to this inventory:

- **D15** (User-driven 2026-05-26): Task letter-suffix REJECTED grammar-wide; Task-M integer-only; new tasks get next integer; **task number ≠ execution order**; cross-refs strict.
- **D16** (User-driven 2026-05-26): Convention Y — v11.0 archive intra-file additive-extension allowed; structural shape frozen at 5 subdirs. *(Annotation — BD-195 S1 CR-1, 2026-05-31: the "frozen at 5 subdirs" wrapper recorded here is **rejected**. The v11.0 archive is **mutable while v11.0 is unshipped** — v11.0 has no release tag, so the archive is not frozen; the intra-file additive-extension permission stands, but the "frozen structural shape" framing is contamination corrected per BD-195 S1. See top-of-file CORRECTION banner.)*

### §6.3 — PLAN-BD-185.md §6a

PLAN-BD-185 §6a captures the 7 planner POQs surfaced 2026-05-26 and their resolution in the Pack Chat decision-review session 2026-05-26. The two decisions D15 + D16 above emerged from that session. The user-locked rule in §6.1.3 above ("TDs MUST NOT promote to Parts; Path 2 target is `Phase-N` ONLY") is a Code-Red-2-era refinement that may not be reflected in PLAN-BD-185.md §6a's planner-output state.

PLAN-BD-185.md path: `maintenance-docs/v11-implementation/PLAN-BD-185.md`

### §6.4 — Related authoritative documents

| Document | Path | Role |
|---|---|---|
| BD-185 entry | `pack-ops/BACKLOG.md` (BD-185 lines) | Source BD; status Open. |
| Architect doc | `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md` | §1.4 Decision log; §4.1 grammar; §4.1a task numbering rule. |
| Plan doc | `maintenance-docs/v11-implementation/PLAN-BD-185.md` | Implementation plan; §6a planner POQ resolution. |
| Inventory (research) | `maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-PARTS-AND-ORDERING.md` | Primary fact base for BD-185. |
| Init script | `scripts/init-project.sh` | Surface B Rule 5 audit target. |
| Current SCHEMA (entity contract) | `maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md` | Reference cited in audit prompt. |

### §6.5 — Audit-vocabulary boundary considerations (Phase 2 input)

The following CLASSES of finding exist in this inventory and Phase 2 should weigh each on its own:

- **Narrative cites to pack BDs in client-shipped prose** (e.g., "see BD-142", "per BD-088"). These are pack-internal references inside client-shipped files. Whether they LEAK depends on whether the reference is load-bearing to client understanding or whether it's an audit-trail-only cite (Phase 2 to decide).
- **SCHEMA grammar admissions for BD-NNN in client-facing entities** (Dim 2 + Dim 6). The user-locked Rule 1 declares these violations.
- **TD lifecycle Path references** (Dim 4). The user-locked Rule 3 declares Path 1 / Path 2 / Path 3-forbidden as the lifecycle vocabulary. Where the docs already say Path 2 target is `Phase-N.M` (task, NOT Part), the doc is consistent with Rule 3. Where the docs say or imply TD → Part, the doc violates Rule 3. This inventory found ZERO positive TD→Part references in Surface A; the one explicit reference (QS-7 / §3.10.10) is a NEGATIVE statement consistent with the user-locked rule.
- **Negative-form admissions / boundary statements** (e.g., A-3.12.4: "Pack-development items (BD-NNN) belong in the pack repo, not in this project"). These are explicit BOUNDARY ENFORCEMENT statements in client-facing docs. They mention BD-NNN to declare it OUT of scope. Phase 2 should consider whether mention-to-exclude is permissible or itself a leak.
- **Filename / per-entry-pattern admissions** (e.g., QS-17 audit-methodology/SKILL.md L76, QS-18 MIGRATION-v10-to-v11.md L258). These reference `docs/project/backlog/BD-NNN.md` as a path pattern. The user-locked Rule 1 implies the project-side per-entry tree is `docs/project/backlog/TD-NNN.md` only (Rule 2: TDs are CLIENT-ONLY). The `BD-NNN.md` pattern admission is ambiguous: it may describe pack-side per-entry mirror only, or admit BD-NNN as a project-side per-entry pattern. Phase 2 to disambiguate.

### §6.6 — End of inventory

This inventory is COMPLETE per §2 methodology and §6.4 success criteria of the audit prompt:

1. Surface A inventoried across `project-template/`, `supporting-docs/`, `templates-archive/v11.0/`, `templates-archive/v11.1/` — DONE.
2. Surface B inventoried across `scripts/` — DONE.
3. All 7 dimensions covered with concrete findings (or explicit zero-findings note in §4.2/§4.3/§4.4/§4.5/§4.6) — DONE.
4. Inventory written to `maintenance-docs/v11-implementation/AUDIT-INVENTORY-BD-TD-PATH.md` — THIS DOCUMENT.
5. No source modified; no state-changing git verbs — VERIFIED (read-only pass).

Phase 2 (pack-reviewer) takes over from here for LEAK / LEGITIMATE disposition and Phase 3 (coder) for correction implementation.
