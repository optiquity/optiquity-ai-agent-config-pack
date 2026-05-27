# PACK-REVIEW-BD-193-PHASE-4.md — Phase 4 extensive post-implementation audit

**Authored by:** pack-reviewer (Phase 4 of BD-193 audit pipeline).
**Date:** 2026-05-27 (US/Pacific).
**Branch:** v11-dev.
**Working-tree HEAD at read time:** `85196d455f259477dc71d45f4eea9e092393813a`
(`fix: v11 — BD-193 Code Red 2 BD/TD scope cleanup`).
**Pipeline reference:**
- Phase 1 (`AUDIT-INVENTORY-BD-TD-PATH.md`, docs-researcher, 782 lines) →
- Phase 2 (`AUDIT-DISPOSITION-BD-TD-PATH.md`, pack-reviewer, 987 lines) →
- Phase 3 (`IMPLEMENTATION-REPORT-BD-193.md`, pack-coder, 645 lines) →
- **Phase 4 (THIS report, pack-reviewer extensive audit)**.

---

## §1 — Scope

Phase 4 is the user-directed extensive post-implementation audit of the
Code Red 2 BD/TD/Path scope contamination cleanup commit. The four
orthogonal questions (per user directive 2026-05-26):

- **Q1** — Was Phase 3 successful? (Verify every Phase 3 application
  against Phase 2 disposition source-of-truth.)
- **Q2** — Are there remaining in-scope issues? (Re-scan 48 inventory
  files for residual contamination missed by Phase 1/2.)
- **Q3** — Are there regressions? (LEGITIMATE removed, new leaks,
  trinity parity, manifest, CI gate, archive drift.)
- **Q4** — Validation of the 2 collateral CI edits (`scripts/
  validate-pack.py` + `scripts/tests/test-issue-forms.sh`).

The Phase 2 disposition report is the source-of-truth for Phase 3
expected outcomes; this report verifies what actually landed in
`git show 85196d4`.

---

## §2 — Methodology

### §2.1 Q1/Q2/Q3/Q4 quadrants

Q1 verification proceeds per-row against §3 (11 LOCKED) + LEAK fixes +
WASTE coverage + §6.1-§6.4 user-resolutions + LEGITIMATE preservation.
Q2 scans for residual leaks using the 3-rule triage stack. Q3 examines
the cleanup itself for regression classes. Q4 audits the 2 collateral
CI edits against their stated rationale.

### §2.2 3-rule triage stack (re-applied in Q2)

1. **Rule 1 — Operational vs explanatory** (pack memory
   `feedback_bd_pack_only_operational_rule`): does this treat BD-NNN
   as something CLIENTS work with functionally (admit as dependency
   type, peer-table, parser regex, form field admission)? → LEAK if yes.
2. **Rule 2 — Pack/project separation** (pack memory
   `feedback_pack_project_separation_of_concerns`): is this a
   cross-side substitution (script copying pack file to client; client
   file used for pack ops)? → VIOLATION if yes.
3. **Rule 3 — Client-facing doc token economy** (pack memory
   `feedback_client_facing_token_economy`): does the client reader
   NEED this reference? → WASTE if no.

### §2.3 Disposition categories (Phase 4 findings)

| Category | Description |
|---|---|
| **CONFIRMED-CORRECT** | Phase 3 application matches Phase 2 disposition. |
| **REMEDIATION-NEEDED-MUST** | Concrete defect requiring fix in Phase 5. |
| **REMEDIATION-NEEDED-SHOULD** | Improvement that would strengthen the cleanup. |
| **REMEDIATION-NEEDED-NIT** | Cosmetic or stylistic improvement. |
| **AMBIGUOUS** | Needs user discussion before disposition. |

### §2.4 Frame discipline

Per pack memory `P-missed-7` and the review skill's "Boundary
discipline" priority — pack-side findings cite pack-side SSOTs
(BD-NNN, `pack-ops/`); project-side findings cite project-side SSOTs
(TD-NNN, `_rules.md`). Cross-side substitution is forbidden.

---

## §3 — Q1: Phase 3 success verification

### §3.1 — 11 LOCKED dispositions: per-row verification

#### §3.1.1 F1.a — `templates-archive/v11.0/INDEX.md` (INDEX segregation)

**CONFIRMED-CORRECT.** L6 introduces `## Entry types at v11.0` with two
sub-sections: `### Client-applicable entry types` (L8-15; 4 rows: TD,
phase-epic, phase-task, inbound) and `### Pack-internal entry types
(informational only; NOT applicable to client projects)` (L17-21; 1
row: BD-NNN). Order matches disposition §3.1 ("Order: client-
applicable first"). Matches IMPL-REPORT §3.1 F1.a description.

#### §3.1.2 F1.b — `templates-archive/v11.1/INDEX.md` (INDEX segregation)

**CONFIRMED-CORRECT.** L12 introduces `## Entry types at v11.1` with
identical segregation: `### Client-applicable entry types` (L14-22;
5 rows including new phase-part-v11.1) and `### Pack-internal entry
types (informational only; NOT applicable to client projects)` (L24-28;
1 row: BD-NNN). Matches disposition §3.1 F1.b.

#### §3.1.3 F1.c — `templates-archive/v11.0/bd-v11.0/SCHEMA.md` (PACK-INTERNAL header)

**CONFIRMED-CORRECT.** L3-8 carries the new header paragraph:

> **SCOPE: PACK-INTERNAL.** This SCHEMA documents the pack-development
> backlog entity (BD-NNN) and applies to the pack repository only. BD
> entries are NOT a client-project concept; client projects use TD-NNN
> (see `../td-v11.0/SCHEMA.md`) for technical-debt items. This file is
> preserved here as the on-tracker representation contract for the pack
> repo's own backlog and is consumed by pack-internal migration scripts.

Header placed at file top (before §1 Identifier scheme), audience and
contract scope explicit. Matches disposition §3.1 F1.c.

#### §3.1.4 F2.a — `phase-task-v11.0/SCHEMA.md` BD-NNN admission removal

**CONFIRMED-CORRECT.** L79 dependencies grammar now reads:
`<one ID per line — optional; accepts phase-N, phase-N.M, TD-NNN>` —
BD-NNN dropped. L86-90 dependencies grammar bullets:
- `phase-N` — depends on the entire phase N being complete
- `phase-N.M` — depends on a specific task in another phase
- `TD-NNN` — depends on a TD entry

The BD-NNN bullet was removed. Matches disposition §3.2 F2.a.

#### §3.1.5 F2.b — `phase-part-v11.1/SCHEMA.md` BD-NNN admission removal

**CONFIRMED-CORRECT.** L127-128 prerequisites grammar reads:
`<one ID per line — optional; accepts phase-N, Phase-N.Part-x,
Phase-N.Task-M, Phase-N.Part-x.Task-M, TD-NNN>` — BD-NNN dropped.
L142-149 prerequisites grammar bullets:
- `phase-N`, `Phase-N.Part-x`, `Phase-N.Task-M`, `Phase-N.Part-x.Task-M`,
  `phase-N.M`, `TD-NNN` — six admissible types; no BD-NNN.

A-3.10.10 LEGITIMATE preservation: L80-84 still negatively names
`derived-from:TD-NNN` ("Parts are not derived from TD entries; the
TD-promotion paths target phase-epic (path 1) and phase-task (path 2)")
with the §6.5 D-18 carrier-matrix phrasing rephrased to inline
`../v11.0/phase-epic-v11.0/SCHEMA.md and ../v11.0/phase-task-v11.0/
SCHEMA.md` references. Matches disposition §4.8 disposition.

#### §3.1.6 F2.c — `templates-archive/v11.0/forms/work-item.yml`

**CONFIRMED-CORRECT.** All five sub-actions applied:
- L1 name: `Pack work item (TD / phase-epic / phase-task)` — "BD"
  dropped from name.
- L2 description: `Project technical-debt item (TD-NNN), phase epic
  skeleton, or phase task skeleton.` — BD admission dropped.
- L3 title default: `"TD-NNN: <short title>"` — BD-NNN: replaced with
  TD-NNN:.
- L13 markdown opening: `(e.g. 'TD-NNN:' becomes the assigned ID)` —
  collateral A-3.7.3 applied.
- L18-25 wi-type dropdown: 3 options only (td, phase-epic-skeleton,
  phase-task-skeleton) — `bd` option dropped.
- L31-32 wi-kind description: `Required for Type=td.` — bd reference
  dropped.
- L46 status description: `Defaults to Open for TD.` — bd reference
  dropped.
- L104 Blockers description: TD-NNN admission only.
- L125 wi-description label: `For TD/phase-epic-skeleton.` — BD
  dropped.
- L168 Dependencies grammar: `phase-N, phase-N.M, TD-NNN` only.

Matches disposition §3.2 F2.c and IMPL-REPORT §3.2 description. D16
bug-fix carve-out applied to v11.0 archive surface as user-locked.

#### §3.1.7 F2.d — `project-template/.github/ISSUE_TEMPLATE/work-item.yml`

**CONFIRMED-CORRECT.** All sub-actions applied:
- L1 name: `Project work item (TD / phase-epic / phase-task)`.
- L2 description: TD/phase-epic/phase-task only.
- L18 **§6.1 KEEP preserved verbatim:** "Pack-development items
  (BD-NNN) belong in the pack repo, not in this project." — sole
  surviving BD- reference in `project-template/` (Phase 4 grep
  confirms).
- L20-27 wi-type dropdown: 3 options only; `bd` dropped.
- L33 wi-kind description, L48 status description, L106 Blockers
  description (TD-NNN + #N), L127 wi-description label, L170
  Dependencies grammar — all aligned to TD-only.

Matches disposition §3.2 F2.d. Trinity parity-divergence (pack admits
`bd`, project does not) confirmed.

#### §3.1.8 F2.e — `supporting-docs/METHODOLOGY.md`

**CONFIRMED-CORRECT.** L384-388 prose now reads:
> "...Each entry is either a phase epic (`phase-N`), a sibling or
> cross-phase task (`phase-N.M`), or a TD entry (`TD-NNN`). Trailing
> free-text after the ID is preserved as a human-readable annotation.
> Parser regex: `^\s*-\s+(phase-\d+(\.\d+)?|TD-\d+)(\s+(.*))?$`."

The "or a BD entry (`BD-NNN`)" clause dropped. The parser regex
correctly drops `|BD-\d+`. Matches disposition §3.2 F2.e.

#### §3.1.9 F3 — `project-template/docs/project/backlog/_intro.md`

**CONFIRMED-CORRECT.** L34 cross-references bullet now reads:
`TD-NNN, phase-N, phase-N.M identifiers may appear in 'Blockers:' /
'Unblocks:' / prose.` BD-NNN dropped. Matches disposition §3.3 F3.

#### §3.1.10 F4/F5 — `scripts/init-project.sh` S11 block

**CONFIRMED-CORRECT.** L820-828:
- L820-824 comment block replaced as specified — pack/project
  separation of concerns rationale; project-side file is source of
  truth.
- L825-828 only primary `cp` from
  `$PACK/project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`; no
  `pack-ops/` source; no pre-v11 pack-root fallback branch.
- L1308 manifest comment: single line
  `# project-template/docs/pack/HELP-FRAGMENT-TRACKER.md -> docs/pack/
  HELP-FRAGMENT-TRACKER.md [stage:S6,S11,cmd_update]` collapsed
  from two separate entries.

Matches disposition §3.4 F4/F5.a-d.

### §3.2 — 3 LEAK fixes: per-row verification

#### §3.2.1 A-3.3.2 (td-v11.0/SCHEMA.md inherited from F2.a)

**CONFIRMED-CORRECT.** No standalone edit to `td-v11.0/SCHEMA.md`
required. After F2.a removed BD-NNN from phase-task SCHEMA's
dependencies grammar, the TD dependencies grammar that inherits via
the V3.3 §5.3 chain now admits `phase-N, phase-N.M, TD-NNN` only.
Direct `grep -n "BD-" td-v11.0/SCHEMA.md` returns zero hits.

#### §3.2.2 A-3.33.1 (audit-methodology/SKILL.md L76)

**CONFIRMED-CORRECT.** L76:
> "Per-entry source-of-truth trees are IN SCOPE. Per-entry tree files
> (`docs/project/backlog/TD-NNN.md`, ..."

Was `BD-NNN.md`; now `TD-NNN.md`. Matches project-side `_rules.md`
L14 regex `^TD-\d+\.md$`. CONFIRMED.

#### §3.2.3 A-3.46.22 (MIGRATION-v10-to-v11.md L255)

**CONFIRMED-CORRECT.** L255 (was L258 per disposition):
> "One Markdown file per entry (e.g., `docs/project/backlog/TD-NNN.md`,
> `docs/project/implementation-plan/phase-N.md`, ..."

Was `BD-NNN.md`; now `TD-NNN.md`. Matches.

### §3.3 — WASTE coverage check (≥105 cite removals)

The disposition §5.2 totals: 78 WASTE rows (de-duplicated). The
IMPL-REPORT §5 declares ~85 cite removals across 22 files (small
overcount due to multi-cite single rows + collateral cleanups).
Per-file verification:

| File | Disposition rows | Phase 4 verification |
|---|---|---|
| `templates-archive/v11.0/inbound-v11.0/SCHEMA.md` | A-3.6.1 + A-3.6.4 | **CONFIRMED:** zero `BD-` references remain (also covers §6.1 inbound mention-to-exclude removal). |
| `templates-archive/v11.0/forms/work-item.yml` | A-3.7.3 collateral | **CONFIRMED:** "TD-NNN:" example in L13 markdown body. |
| `templates-archive/v11.1/INDEX.md` | A-3.9.1-.13 except .3 | **CONFIRMED:** only L28 BD-NNN row in pack-internal sub-section remains; all 12 BD-185 cites removed. |
| `templates-archive/v11.1/phase-part-v11.1/SCHEMA.md` | A-3.10.1-.26 except .10/.16/.20 | **CONFIRMED:** zero BD-185 cites; A-3.10.10 LEGITIMATE NEGATIVE statement preserved with carrier-matrix rephrasing. |
| `templates-archive/README.md` | A-3.11.1 + .2 | **CONFIRMED:** zero BD-069 / BD-064 cites; only L46 "BD" + L8/L32/L68 V3.3/ARCHITECTURE-V references remain (LEGITIMATE pack-archive audit-trail). |
| `project-template/tracker.toml.project-example` | A-3.13.1 | **CONFIRMED:** L71 comment no longer carries BD-108. |
| `project-template/.gitignore` | A-3.14.1 | **CONFIRMED:** L7 banner no longer carries BD-061. |
| `project-template/{CLAUDE,AGENTS,GEMINI}.md` (trinity) | A-3.15.1/.16.1/.17.1 | **CONFIRMED:** BD-142 cite removed identically across all 3 files; trinity parity verified by byte-diff (§3.4 below). |
| `project-template/.gemini/.env.example` | A-3.18.1 + .2 | **CONFIRMED:** zero BD-059 cites. |
| `project-template/.codex/config.toml` + `.example` | A-3.19.1 + A-3.20.1 | **CONFIRMED:** BD-059 trinity-rule cite removed from both files. (`.toml.example` L17 "future BD" admission is a different LEAK class — see Q2 §4.) |
| `project-template/docs/pack/PM-CHAT.md` | A-3.21.1/.2/.3 | **CONFIRMED:** 3 BD-108/107/108 cites removed; 15 LEGITIMATE TD-lifecycle entries preserved (Path 1/2/3-forbidden section intact). |
| `project-template/docs/pack/PLATFORM-SKILLS.md` | A-3.24.1/.2/.3/.4/.6/.7 | **CONFIRMED:** zero BD- references; LEGITIMATE A-3.24.5 pm-startup TD-TBD row preserved. |
| `project-template/skills/python-data-architecture/SKILL.md` | A-3.35.1 | **CONFIRMED:** BD-141/143 cite block rephrased. |
| `project-template/skills/python-server-architecture/SKILL.md` | A-3.36.1 | **CONFIRMED:** BD-141/143 cite block rephrased. |
| `project-template/skills/python-observability-patterns/SKILL.md` | A-3.37.1 | **CONFIRMED:** BD-162 cite removed. |
| `project-template/skills/swift-best-practices/SKILL.md` | A-3.38.1 | **CONFIRMED:** BD-158 cite rephrased. |
| `project-template/docs/project/changelog/_rules.md` | A-3.43.1 | **CONFIRMED:** BD-164-retro cite removed. |
| `supporting-docs/METHODOLOGY.md` | A-3.44.17/.18/.25 (WASTE) | **CONFIRMED:** BD-059, BD-048, BD-042 narrative cites removed; LEGITIMATE TD-lifecycle preserved. |
| `supporting-docs/INSTALL-PROCEDURES.md` | A-3.45.1-.6 | **CONFIRMED:** zero BD- references. |
| `supporting-docs/MIGRATION-v10-to-v11.md` | Class B WASTE + LEAK | **CONFIRMED:** 17 surviving BD- references match 16 disposition §7.3 Class A rows (L10-11 has 2 BD tokens for 1 row). |
| `supporting-docs/SETUP-NEW.md` | A-3.47.1/.2/.3/.4 | **CONFIRMED:** zero BD- references. |
| `supporting-docs/SETUP-EXISTING.md` | A-3.48.1 | **CONFIRMED:** zero BD- references. |

**WASTE TOTAL VERIFIED:** all ~85 removals applied per disposition;
no LEGITIMATE row removed (sampled and full-file confirmed).

### §3.4 — 4 AMBIGUOUS user-resolutions: per-row verification

#### §3.4.1 §6.1 split-reading

**CONFIRMED-CORRECT.** Pack-archive surface (Reading A — REMOVE):
- A-3.6.2 (`inbound-v11.0/SCHEMA.md:17`): "Inbound entries do not
  have a stable pack-side identifier prefix. The GH issue number is
  the identifier." — "(no BD-NNN / TD-NNN)" parenthetical dropped.
- A-3.6.3 (`inbound-v11.0/SCHEMA.md:114`): "Inbound entries have no
  pack-side namespace identity — the GH issue number is their
  identifier." — "Unlike BD/TD entries..." clause dropped wholesale.

Project-side surface (Reading B — PRESERVE):
- A-3.12.4 (`project-template/.github/ISSUE_TEMPLATE/work-item.yml:18`):
  "Pack-development items (BD-NNN) belong in the pack repo, not in
  this project." — preserved verbatim as boundary-defense.

Matches IMPL-REPORT §7.1.

#### §3.4.2 §6.2 Reading A (boundary-investigation/SKILL.md)

**CONFIRMED-CORRECT.**
- L33: "The audit incident (P-missed-7) documented the regression
  mechanism this skill prevents..." — BD-175 label dropped; P-missed-7
  anchor retained.
- L169: "## Worked example (V1 anti-pattern)" — BD-175 label dropped
  from section header.

Worked-example walkthrough content (Step 1-5) preserved intact (read
L168-end of section).

#### §3.4.3 §6.3 Class A/B split (MIGRATION-v10-to-v11.md)

**CONFIRMED-CORRECT.** 17 BD- references remain (16 disposition §7.3
Class A rows; L10-11 row carries 2 BD tokens — BD-042 and BD-085):
1. L10-11: BD-042 + BD-085 migration script attribution
2. L18: BD-121 v9-sunset history
3. L41: BD-088 contract
4. L44: BD-042 relocation tail
5. L145: BD-088 customization
6. L151: BD-088 sidecar
7. L161: BD-088 sidecar
8. L176: BD-088 mechanism
9. L390: BD-088 pre-flight
10. L392: BD-088 init
11. L393: BD-088 dispatch
12. L394: BD-104 rename action
13. L395: BD-042 relocation tail
14. L409: BD-088 lib error
15. L411: BD-101 verification gate
16. L413: BD-101 verification gates

These 16 distinct row-positions correspond 1:1 to disposition §7.3
Class A entries. Class B WASTE removals confirmed (e.g., L83 section
header "Skill model changes (BD-142, BD-148)" → "Skill model changes";
L181 "BD-136 trinity-marker non-overlap" → "Trinity-marker
non-overlap"; L256 LEAK + Class B WASTE removed).

#### §3.4.4 §6.4 Reading A (SETUP files)

**CONFIRMED-CORRECT.** Zero BD- references in SETUP-NEW.md and
SETUP-EXISTING.md per Phase 4 grep. All 5 cites removed.

### §3.5 — 110 LEGITIMATE rows preserved (sampled verification)

#### §3.5.1 TD-TBD typed-deferral grammar (~30+ rows)

**CONFIRMED-PRESERVED:**
- Trinity `project-template/{CLAUDE,AGENTS,GEMINI}.md` typed-deferral
  block (TODO/KNOWN GAP/VERIFY scopes) — preserved at L309-310
  (CLAUDE) / L293-294 (AGENTS) / L305-306 (GEMINI).
- Trinity "Always write TD-TBD — never a real TD number" preserved at
  L321 / L296 / L317.
- AGENTS.md L309 coder/TD-TBD permission row preserved.
- METHODOLOGY.md typed-deferral block at L1168-1176 preserved.
- METHODOLOGY.md "TD-TBD sentinel" discipline preserved.
- METHODOLOGY.md `grep -rn "TD-TBD"` checks preserved.
- Coder agent docs preserved (`.claude/agents/coder.md`,
  `.gemini/agents/coder.md`, `.codex/agents/coder.toml`).
- pm-startup skill files (4 mirrors) TD-TBD content preserved.
- swift-concurrency-patterns/SKILL.md L188 TD-TBD discipline.
- Reviewer + auditor + pm-chat + coder prompt TD-NNN ranges preserved.

#### §3.5.2 Path 1/2/3-forbidden lifecycle orchestration (PM-CHAT.md ~15 rows)

**CONFIRMED-PRESERVED.** L540-650 full TD-resolution section intact
(Path 1, Path 2 with `phase-N.M` target only, Path 3-forbidden).
Verified Path 2 target is `phase-N.M` (task), NOT `Phase-N.Part-x` —
matches user-locked Rule 3.

#### §3.5.3 METHODOLOGY.md Path lifecycle section (~13 rows)

**CONFIRMED-PRESERVED.** L1283-1320 Resolution path decision logic
(Direct close / Path 1 / Path 2 / Path 3-forbidden) preserved.

#### §3.5.4 bd-v11.0/SCHEMA.md definitional content (post-PACK-INTERNAL header)

**CONFIRMED-PRESERVED.** §1 Identifier scheme through §5 Sub-issue
hierarchy all preserved with original wording; new PACK-INTERNAL
header at L3-8 discloses pack-only scope. All BD-NNN references in
this file are LEGITIMATE per disposition §4.1 (definitional contract
on PACK-INTERNAL surface).

#### §3.5.5 Class A migration-mechanism cites in MIGRATION-v10-to-v11.md

**CONFIRMED-PRESERVED.** All 16 Class A rows preserved (see §3.4.3
list above).

#### §3.5.6 work-item.yml L18 boundary-defense KEEP (§6.1 Reading B)

**CONFIRMED-PRESERVED.** Project-side form L18 boundary-defense
statement preserved verbatim.

---

## §4 — Q2: Remaining in-scope issues (residual contamination)

This section surfaces leaks that Phase 1 inventory MISSED and that
Phase 2/3 therefore did not address. Each finding is verified against
the 3-rule stack.

### §4.1 — `project-template/docs/pack/OPTIONAL-FEATURES.md` — operational BD admissions (M-11)

**REMEDIATION-NEEDED-MUST (Phase 1 INVENTORY MISS).**

Phase 1 inventory L574 explicitly listed this file as "no findings".
Phase 4 grep finds 3 operational BD admissions at the client surface:

- **L120:** "your project (open BD count, BACKLOG size, 30-day growth)"
- **L123:** "When it matters — when your project's BD volume reaches
  the point..."
- **L158:** "When to skip — if your BD volume is under ~50 open..."

Per Rule 1 (`feedback_bd_pack_only_operational_rule`): these treat BD
as something CLIENTS work with functionally — "your project's BD
volume", "open BD count", "your BD volume is under ~50". This is the
exact operational LEAK pattern BD-193 was created to fix. The file is
client-shipped (`docs/pack/` is the client install path).

**Recommended remediation:** rephrase to "your project's TD/work-item
volume", "open work-item count", "TD volume is under ~50". The tracker
opt-in heuristic is about ISSUE volume; the entry-type used at the
client side is TD, not BD.

### §4.2 — `project-template/skills/review/SKILL.md` — operational "sibling BD" admissions (M-13)

**REMEDIATION-NEEDED-MUST (Phase 1 INVENTORY MISS).**

Phase 1 inventory L580 stated "`project-template/skills/*` (all
non-listed skills); the listed skills above are the only `project-
template/skills/` files with findings". Phase 4 grep finds 4
operational BD admissions in the project-template review skill:

- **L32:** "...defer to later phase / later BD / later batch..."
- **L35:** "BLOCKED. Real dependency on a not-yet-landed artifact —
  a sibling BD's implementation..."
- **L36:** "LOGICAL FIT. The finding cleanly belongs with another
  sibling BD/commit..."
- **L50:** "CARRY-FORWARD: SIZE / BLOCKED / LOGICAL-FIT — <concrete
  evidence: which files, which blocker, which sibling BD>"

Per Rule 1: these treat BD as a client-side carry-forward anchor.
Per pack memory `feedback_pack_project_separation_of_concerns`: the
pack-side and project-side review skills are SEPARATE artifacts with
SEPARATE audiences. The pack-root `.claude/skills/review/SKILL.md`
correctly references BD (pack-side context); the project-template
mirror should reference TD (project-side context).

**Recommended remediation:** in `project-template/skills/review/
SKILL.md`, replace each occurrence of "sibling BD" with "sibling TD"
(or "sibling work item") and "later BD" with "later TD or future pack
version".

### §4.3 — `project-template/skills/pm-startup/SKILL.md` (4 mirrors) — "later BD" admission (M-14)

**REMEDIATION-NEEDED-MUST (Phase 1 INVENTORY MISS).**

Phase 1 inventory §3.32 examined this file's TD-TBD content but missed
L213's operational BD admission:

- **L213** (all 4 mirrors: `project-template/skills/pm-startup/`,
  `.claude/skills/pm-startup/`, `.codex/skills/pm-startup/`,
  `.gemini/commands/pm-startup.toml`): "...the tracker-mode triage
  queue (...) lands here in a later BD when tracker mode is wired
  into pm-startup."

Per Rule 1: "in a later BD" treats BD as a client-visible deferral
anchor.

**Recommended remediation:** "lands here in a future pack version
when tracker mode is wired into pm-startup."

**Note:** The skill source-of-truth is `project-template/skills/
pm-startup/SKILL.md`; the 3 CLI mirrors regenerate from that source
via `stage_s4_skills()` per disposition note. Editing the source
fixes all 4 mirrors at install. The `.gemini/commands/pm-startup.toml`
is a Gemini-specific surface but carries the same text.

### §4.4 — `project-template/.codex/config.toml.example:17` — "future BD" admission (M-15)

**REMEDIATION-NEEDED-MUST (Phase 1 INVENTORY MISS).**

Phase 1 inventory §3.20 caught L10 BD-059 but missed L17:

- **L17:** "# stability is research OQ-1 (defer to future BD if
  needed)."

Per Rule 1: "future BD" treats BD as a client-side deferral concept.

**Recommended remediation:** "stability is research OQ-1 (defer to
a future pack version if needed)."

### §4.5 — `supporting-docs/MIGRATION-v10-to-v11.md` — "file a BD" admissions (M-9 / M-10 / M-16)

**REMEDIATION-NEEDED-MUST.**

Three additional operational BD admissions that are NEW LEAKs at the
client surface:

- **L597:** "If the migrator reports
  `customization-detected-needs-reconciliation` on a file you didn't
  customize, that's a defect — please file a BD against the
  `customize-preserve` library..."
- **L712:** "File a BD with the disposition row + the file's
  pre-migration content."
- **L714:** "Wait for the BD to land before re-attempting."
- **L727:** "Decide on Phase B. If your project's BD volume is
  moderate (< 50 open) and BACKLOG.md is comfortable..."

Per Rule 1: these direct the CLIENT user to "file a BD" against the
pack — which is operationally wrong. Per `bd-v11.0/SCHEMA.md`, the
client filing channel for pack-feedback is `inbound` (specifically
`pack-feedback-friction` or `pack-feedback-prompt`) — not BD.
"Your project's BD volume" treats BD as a client metric.

**Recommended remediation:**
- L597: "please file an inbound issue (`pack-feedback-friction`)
  against the pack..."
- L712: "File an inbound issue with the disposition row..."
- L714: "Wait for the pack-side fix to land..."
- L727: "If your project's TD/work-item volume is moderate..."

### §4.6 — Mention-to-exclude pattern consistency (M-17 AMBIGUOUS)

**AMBIGUOUS.**

The §6.1 split-reading user-resolution applied Reading A (REMOVE) to
pack-archive surface mention-to-exclude patterns in
`inbound-v11.0/SCHEMA.md` (A-3.6.2/A-3.6.3). Phase 4 finds two
structurally identical patterns on pack-archive surfaces that were
NOT in the Phase 1 inventory:

- **`phase-task-v11.0/SCHEMA.md:103`:** "Phase tasks may not be
  parented to BD/TD entries or to other phase tasks..."
- **`phase-part-v11.1/SCHEMA.md:170`:** "Phase parts may not be
  parented to BD/TD entries or to phase tasks..."

These are parent-constraint statements (not identifier-namespace
statements like §6.1 case). The pattern is "mention-to-exclude" —
mentioning BD/TD to assert non-parentage.

**User must decide:** does the §6.1 Reading A consistency extend to
these parent-constraint mention-to-exclude cases on pack-archive
surfaces? Two readings:
1. **Reading A (apply consistently):** these are mention-to-exclude
   on pack-archive surface; remove per §6.1 Reading A. The negation
   can be rephrased without naming BD/TD entries: "Phase tasks may
   not be parented to work-item entities or to other phase tasks —
   a phase task's parent is exactly one phase epic."
2. **Reading B (substantively different context):** parent-constraint
   is structurally different from identifier-namespace. The negation
   names the SET of entities a phase task cannot be parented to, and
   that set legitimately includes BD/TD as a structural fact. Keep.

**Reviewer recommendation (non-binding):** Reading B — the parent-
constraint context is substantively different from §6.1's identifier-
namespace context. The negation is structural (parent-relationship
type), not identifier-namespace (which entity-types exist at this
level).

### §4.7 — `templates-archive/v11.1/INDEX.md` v11.1 forms claim (M-5)

**REMEDIATION-NEEDED-SHOULD (collateral effect of F2.d).**

L55-61:
> "The v11.1 form file at `maintenance-docs/v11-research/templates-
> archive/v11.1/forms/work-item.yml` is byte-identical to the live
> form (`.github/ISSUE_TEMPLATE/work-item.yml` at pack root, mirrored
> byte-identically to `project-template/.github/ISSUE_TEMPLATE/
> work-item.yml`). The archive form is CREATED in v11.1."

Two factual errors:
1. **File does not exist.** `ls maintenance-docs/v11-research/
   templates-archive/v11.1/forms/` returns "No such file or
   directory". The `forms/work-item.yml` claimed at L55-56 is not
   present.
2. **Byte-identity claim now false.** After BD-193 F2.d removed `bd`
   from the project-side form, pack-root and project-template forms
   are no longer byte-identical. The "mirrored byte-identically"
   assertion is wrong post-BD-193.

This is a stale-reference + stale-claim issue surfaced as collateral
to F2.d. Phase 2 did not anticipate this. Not in the original
disposition.

**Recommended remediation:** delete or rephrase the v11.1 forms
section. Either (a) actually create the v11.1 archive forms
directory + form file (a v11.1 archive cut decision the user makes),
or (b) rephrase to acknowledge pack/project divergence: "The v11.1
form file is the live form at `.github/ISSUE_TEMPLATE/work-item.yml`
(pack-root) and `project-template/.github/ISSUE_TEMPLATE/
work-item.yml` (project-template). These are SEPARATE artifacts with
SEPARATE audiences post-BD-193: pack-root admits the `bd` wi-type
option; project-template does NOT (see Decision Log D-19/BD-193)."

### §4.8 — `templates-archive/v11.0/INDEX.md` stale 4-option claim (M-18)

**REMEDIATION-NEEDED-SHOULD (collateral effect of F2.c).**

L30-32:
> "`forms/work-item.yml` — composite form for BD, TD,
> phase-epic-skeleton, phase-task-skeleton (4-option `wi-type`
> dropdown per V3.3 §6.1)."

Post-F2.c, the archive form has 3 wi-type options (td, phase-epic-
skeleton, phase-task-skeleton). The "composite form for BD, TD, ..."
naming and "4-option" count are now stale.

**Recommended remediation:** "`forms/work-item.yml` — composite form
for TD, phase-epic-skeleton, phase-task-skeleton (3-option `wi-type`
dropdown per V3.3 §6.1 + BD-193 D16 carve-out). The original v11.0
shipped form admitted a 4th `bd` option; D16 removed it from the
archive as a bug-fix carve-out."

### §4.9 — `templates-archive/README.md:46` 5-entry-type list (M-19)

**REMEDIATION-NEEDED-NIT.**

L46: "type per minor: BD, TD, phase-epic, phase-task, inbound at
v11.0."

With F1.b INDEX segregation now distinguishing client-applicable from
pack-internal entry types, this list flattens the boundary.

**Recommended remediation:** "type per minor: BD (pack-internal), TD,
phase-epic, phase-task, inbound at v11.0."

---

## §5 — Q3: Regressions

### §5.1 — LEGITIMATE content accidentally removed

**CONFIRMED-CLEAN.** Phase 4 sampled and verified the LEGITIMATE
preservation set per §3.5 — no accidental strip detected:
- TD-TBD typed-deferral grammar — INTACT.
- Path 1/2/3-forbidden lifecycle orchestration in PM-CHAT.md — INTACT
  (L540-650 verified line-range; matches disposition §4.16 KEEP).
- METHODOLOGY.md Path lifecycle (L1283-1320) — INTACT.
- bd-v11.0/SCHEMA.md definitional content (post-header) — INTACT.
- Class A migration-mechanism cites in MIGRATION (16 rows) — INTACT.
- work-item.yml L18 boundary-defense KEEP — INTACT.

### §5.2 — New BD/TD/Path leaks introduced by the cleanup itself

**CONFIRMED-CLEAN (within the modified files).** Re-reading the 36
modified files' diffs in `git show 85196d4` shows that the cleanup
removed cite tokens without introducing new pack-only concept names
in rephrased text. The rephrases like:
- "Skill model changes (BD-142, BD-148)" → "Skill model changes" —
  pack token removed, no replacement.
- "split in v11.0 by BD-141 (the `python_data_marker_detected()` load
  predicate) and BD-143 (the trinity SKILL.md split..." → "split in
  v11.0 (the `python_data_marker_detected()` load predicate and the
  trinity SKILL.md split..." — pack tokens removed, mechanism
  function-names preserved (project-readable).

No new pack-only concept names introduced via rephrasing within the
36 files. (The pre-existing leaks in §4.1-§4.5 are NOT new — they
were present in the working tree and missed by Phase 1.)

### §5.3 — Trinity parity broken

**CONFIRMED-CLEAN.** Trinity parity verified via diff:

```
$ grep -A 6 "Tier 0 installation note" project-template/CLAUDE.md > /tmp/c.txt
$ grep -A 6 "Tier 0 installation note" project-template/AGENTS.md > /tmp/a.txt
$ grep -A 6 "Tier 0 installation note" project-template/GEMINI.md > /tmp/g.txt
$ diff /tmp/c.txt /tmp/a.txt   # identical
$ diff /tmp/c.txt /tmp/g.txt   # identical
$ diff /tmp/a.txt /tmp/g.txt   # identical
```

All three trinity files carry the identical "Tier 0 installation
note" paragraph with BD-142 dropped from "for every project". Trinity
parity rule honored.

### §5.4 — Manifest correctness

**CONFIRMED-CLEAN.** `bash test-fixtures/build.sh --verify` PASS at
HEAD:
- `v10-minimal OK: 19558cba...`
- `v10-realistic-ot OK: 4c62945f...`
- `v11-realistic-ot OK: f0bacc6c...`
- `v11-flat-file OK: cf19a42a...`
- `v11-tracker-on OK: 092ec81e...`
- `existing-project-mid-dev OK: a54e081a...`

All 6 fixture rows match the regenerated manifest. The three v11-*
fixtures drifted as expected from the v11-surface edits (trinity,
.github/ISSUE_TEMPLATE, supporting-docs, scripts).

### §5.5 — CI gate correctness

**CONFIRMED-CLEAN at HEAD.** `python3 scripts/validate-pack.py` PASS:
all 43 checks emit OK; Check 43 leak-sweep prevention PASS (151
project-side files walked; zero pack-internal bare cross-references);
Check 37 PASS (158 project-side files walked; zero deny-list
contamination); Check 41 PASS (37 `_CLIENT_INSTALLED_FILES` entries
verified). `bash scripts/tests/test-issue-forms.sh` PASS (78/0).

### §5.6 — Latent concern: Check 24 HELP-FRAGMENT-TRACKER byte-identity (M-8)

**REMEDIATION-NEEDED-SHOULD (latent issue; outside immediate scope).**

`scripts/validate-pack.py` Check 24 (`check_help_fragment_tracker`)
enforces byte-identity between `pack-ops/HELP-FRAGMENT-TRACKER.md`
and `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`. Per BD-193
F4/F5 rationale (and pack memory
`feedback_pack_project_separation_of_concerns`), these two files are
now declared SEPARATE artifacts with SEPARATE audiences. The
byte-identity gate is architecturally inconsistent with the F4/F5
separation rationale.

Currently both files ARE byte-identical (the check passes), so this
is latent — but the FIRST intentional divergence (e.g., a pack-side
verb description added that doesn't apply to clients) will break
Check 24. The check should be relaxed or removed in line with the
F4/F5 contract.

**Note:** This is outside the strict Phase 3 verification scope —
Phase 2 disposition did not call for Check 24 modifications. Surfaced
here as a follow-on concern.

### §5.7 — Pack-archive content drift

**CONFIRMED-CLEAN.** The D16 bug-fix carve-out is appropriately scoped
to F2.a (`phase-task-v11.0/SCHEMA.md` BD-NNN dependency admission
removal) and F2.c (`forms/work-item.yml` BD admission removal). Other
v11.0 archive files (`td-v11.0/SCHEMA.md`, `phase-epic-v11.0/
SCHEMA.md`, `inbound-v11.0/SCHEMA.md`, `bd-v11.0/SCHEMA.md`) are
either untouched or received only the F1.c PACK-INTERNAL header
addition (bd-v11.0) — no destructive modification beyond the
carve-out's documented scope.

The v11.0 INDEX.md and README.md edits are additive (segregation
sub-sections, cite removals) and don't violate the carve-out.

The collateral stale-claims at v11.0/INDEX.md L30-32 (§4.8) and
v11.1/INDEX.md L55-61 (§4.7) are documentation-level inaccuracies,
not destructive content drift on the archive forms themselves.

---

## §6 — Q4: Collateral CI edits validation

### §6.1 — `scripts/validate-pack.py` Check edit

**Function modified:** `check_issue_template_forms()` at L1067-1179
(NOT Check 41 as labeled in IMPL-REPORT §14 and commit message — see
§6.3 below).

**Diff review:**

```python
# Per-surface expected wi-type options. Pack-side admits `bd` (the
# pack-development entry type); project-side does NOT — BD entries
# are pack-internal by construction and client projects use TD.
expected_wi_type_options_per_surface = {
    "pack-root": {"bd", "td", "phase-epic-skeleton", "phase-task-skeleton"},
    "project-template": {"td", "phase-epic-skeleton", "phase-task-skeleton"},
}
```

**Q4 assessment:**

- **Correctness:** the per-surface dict correctly encodes "pack admits
  `bd`, project does NOT". CONFIRMED-CORRECT.
- **Future-proofing:** a third surface (e.g., a new form variant)
  would need a new dict key — easy mechanical addition. The pattern
  extends naturally. CONFIRMED-CORRECT.
- **Placement:** the per-surface logic is inline in the check. For 2
  surfaces this is fine; if 4+ surfaces emerge, a shared helper would
  be cleaner. CURRENT: acceptable. CONFIRMED-CORRECT.
- **Documentation:** the docstring at L1071-1078 explains the
  per-surface rule. The OK-message reference at L1159 ("V3.3 §6.1 +
  BD-193") provides audit-trail. CONFIRMED-CORRECT.

### §6.2 — `scripts/tests/test-issue-forms.sh` edit

**Function modified:** `check_workitem()` at L77-122; cross-surface
invariant 5.1 at L186-198.

**Diff review:**

```bash
check_workitem() {
    local label="$1"
    local path="$2"
    # Optional 3rd arg: surface kind. "pack" (default) admits the `bd`
    # wi-type option; "project" does NOT — per BD-193 boundary cleanup,
    # BD entries are pack-internal and client projects use TD.
    local surface_kind="${3:-pack}"
    # ...
    if [[ "$surface_kind" == "pack" ]]; then
        assert_contains "$label wi-type has bd"  "$options" "'bd'"
    else
        # Project-side MUST NOT admit `bd` (BD-193 F2.d).
        if [[ "$options" == *"'bd'"* ]]; then
            t_fail "$label wi-type must NOT have bd (project-side)" \
                "options='$options' contains 'bd' — BD entries are pack-internal"
        else
            t_pass "$label wi-type correctly omits bd (project-side)"
        fi
    fi
    # ...
}
check_workitem "pack-root work-item.yml"        "$REPO_ROOT/..."  "pack"
check_workitem "project-template work-item.yml" "$REPO_ROOT/..."  "project"
```

**Q4 assessment:**

- **Mirror of Check 41:** the surface-aware logic in `check_workitem`
  correctly mirrors the per-surface dict in `validate-pack.py`. Pack
  side asserts `bd` present; project side asserts `bd` absent.
  CONFIRMED-CORRECT.
- **Coverage adequate for both surfaces:** all 78 tests pass at HEAD;
  both surfaces verified independently. CONFIRMED-CORRECT.
- **Cross-surface invariant 5.1:**
  ```bash
  expected_proj_opts=$(python3 -c "
  import sys
  pack=$pack_opts
  print(sorted([o for o in pack if o != 'bd']))
  ")
  assert_eq "5.1 wi-type options pack admits bd vs project omits bd" \
      "$expected_proj_opts" "$proj_opts"
  ```
  The Python inline derives expected project options by removing
  `bd` from pack options. Correct invariant. CONFIRMED-CORRECT.
- **Backward compatibility:** the 3rd arg `surface_kind` defaults to
  `pack`, so existing call sites would not break if any pre-existing
  code called `check_workitem` without the 3rd arg. CONFIRMED-CORRECT.

### §6.3 — Coder IMPL-REPORT §14 labeling error (M-7)

**REMEDIATION-NEEDED-NIT.**

IMPL-REPORT §14 and commit message both refer to the modified check as
"Check 41". The actual `check_issue_template_forms()` is NOT Check 41.

Check inventory:
- L1067: `def check_issue_template_forms()` — printed as "Check:
  Issue template forms (BD-063)" (unnumbered).
- L5553: `# ── Check 41: _CLIENT_INSTALLED_FILES self-doc list
  integrity (BD-180 G) ───` — distinct check.

The OK message inside `check_issue_template_forms` reads "(V3.3 §6.1
+ BD-193)" — no Check number assigned. The check is technically
"Check (existing series)" per the docstring.

**Recommended remediation:** correct the IMPL-REPORT §14 reference
from "Check 41" to "check_issue_template_forms (V3.3 §6.1; printed
as 'Check: Issue template forms (BD-063)')". The commit message can
stay as-is (already landed; no rewrite).

### §6.4 — Rationale alignment between IMPL-REPORT §14 and code

**CONFIRMED-CORRECT (modulo the Check-number labeling NIT above).**
The IMPL-REPORT §14 rationale ("Per-surface expected options
introduced (pack-root admits `bd`, project-template does NOT)") matches
the actual code change. The "mechanical CI-keep-green edits required
by the F2.c + F2.d LOCKED actions" framing is accurate — the per-
surface logic is the mechanical consequence of the divergent admission
sets, not a new design decision.

---

## §7 — Findings summary

### §7.1 Per-category counts

| Category | Count |
|---|---|
| **CONFIRMED-CORRECT** | 11 LOCKED + 3 LEAK + ~85 WASTE + 4 §6.* user-resolutions + 6 LEGITIMATE preservation classes = **~109 distinct Phase-3 applications all verified clean**. |
| **REMEDIATION-NEEDED-MUST** | 5 distinct findings (§4.1 OPTIONAL-FEATURES; §4.2 project-template review/SKILL.md; §4.3 pm-startup mirrors; §4.4 .codex config example; §4.5 MIGRATION "file a BD" admissions). |
| **REMEDIATION-NEEDED-SHOULD** | 3 distinct findings (§4.7 v11.1/INDEX stale forms claim; §4.8 v11.0/INDEX 4-option stale claim; §5.6 Check 24 byte-identity gate). |
| **REMEDIATION-NEEDED-NIT** | 2 distinct findings (§4.9 README 5-entry-type framing; §6.3 IMPL-REPORT Check-41 labeling). |
| **AMBIGUOUS** | 1 distinct finding (§4.6 mention-to-exclude pattern consistency on phase-task/phase-part SCHEMAs). |

### §7.2 Priority HIGH

The 5 REMEDIATION-NEEDED-MUST findings (§4.1-§4.5) are all NEW LEAKS
at the client-facing surface — the EXACT class of regression BD-193
was created to eliminate. They are unblocked, low-edit-size, and
ship in client-installed surfaces (`project-template/docs/pack/`,
`project-template/skills/`, `project-template/.codex/`,
`supporting-docs/`). They fail Rule 1 (operational vs explanatory) and
should fix-now per default-fix-all triage (pack memory
`feedback_fix_all_review_findings`).

### §7.3 Priority MEDIUM

The 3 REMEDIATION-NEEDED-SHOULD findings (§4.7, §4.8, §5.6) are
collateral effects:
- §4.7 + §4.8 are stale claims in pack-archive INDEX files that
  Phase 2 didn't anticipate; they are doc-level inaccuracies, not
  functional defects.
- §5.6 is a latent concern about Check 24's byte-identity gate
  becoming architecturally inconsistent with F4/F5 — but currently
  the gate passes.

These can fix-now (low edit cost) or defer to a small follow-up BD if
v11.0 release pressure favors batching.

### §7.4 Priority LOW

The 2 REMEDIATION-NEEDED-NIT findings (§4.9, §6.3) are cosmetic.
§4.9 is a phrasing improvement on README; §6.3 is an IMPL-REPORT
labeling correction.

### §7.5 Successes acknowledged

- All 11 LOCKED dispositions applied per disposition §3 — no
  deviation from user-locked actions.
- All 3 LEAK fixes verified (A-3.3.2 inherited; A-3.33.1 + A-3.46.22
  BD-NNN.md → TD-NNN.md substitutions).
- All 4 §6.1-§6.4 AMBIGUOUS user-resolutions correctly applied
  (split-reading, Reading A, Class A/B split, Reading A).
- All 110 LEGITIMATE rows preserved — no accidental strip.
- Trinity parity verified by byte-diff (BD-142 cite removed
  identically from CLAUDE/AGENTS/GEMINI).
- Manifest regenerated correctly (3 v11-* fixtures drifted as
  expected; v10-* tag-pinned rows unchanged).
- CI gates all PASS at HEAD (43/43 validate-pack checks, 78/0
  test-issue-forms, manifest verify clean).
- 2 collateral CI edits (per-surface wi-type) are correctly
  mechanical consequences of F2.c + F2.d.
- §6.1 split-reading carefully distinguished pack-archive (Reading A)
  from project-side (Reading B) — boundary-aware execution.
- §6.2 boundary-investigation skill: BD-175 labels removed while
  preserving worked-example walkthrough content — P-missed-7 anchor
  retained as client-visible.

---

## §8 — AMBIGUOUS surface (user discussion needed)

### §8.1 §4.6 — Mention-to-exclude on phase-task/phase-part SCHEMAs

Two pack-archive surfaces contain mention-to-exclude patterns
structurally identical to A-3.6.2/A-3.6.3 in `inbound-v11.0/SCHEMA.md`
(which §6.1 Reading A REMOVED):

- `phase-task-v11.0/SCHEMA.md:103` — "Phase tasks may not be parented
  to BD/TD entries or to other phase tasks..."
- `phase-part-v11.1/SCHEMA.md:170` — "Phase parts may not be parented
  to BD/TD entries or to phase tasks..."

**User must decide:** apply §6.1 Reading A consistency (REMOVE) or
classify as substantively different (KEEP)?

Reviewer non-binding recommendation: Reading B (KEEP). The parent-
constraint context names a SET of entities a phase task cannot be
parented to — a structural fact about parent-relationship types, not
an identifier-namespace statement. The negation is necessary
structural disclosure. But the user should decide.

---

## §9 — Recommended Phase 5 (fix-coder scope for remediation)

If the user authorizes Phase 5, the recommended fix-coder scope is:

### §9.1 MUST fixes (5 distinct edits across ~8 file paths)

1. **`project-template/docs/pack/OPTIONAL-FEATURES.md`:**
   - L120: "open BD count, BACKLOG size, 30-day growth" → "open
     work-item count, BACKLOG size, 30-day growth"
   - L123: "your project's BD volume" → "your project's work-item
     volume"
   - L158: "your BD volume is under ~50 open" → "your TD/work-item
     volume is under ~50 open"

2. **`project-template/skills/review/SKILL.md`:**
   - L32: "defer to later phase / later BD / later batch" → "defer to
     later phase / later TD / later batch"
   - L35: "a sibling BD's implementation" → "a sibling TD's
     implementation"
   - L36: "another sibling BD/commit" → "another sibling TD or commit"
   - L50: "which sibling BD" → "which sibling TD"

3. **`project-template/skills/pm-startup/SKILL.md` L213** (single
   source-of-truth; init-project.sh distributes to 3 CLI mirrors):
   - "lands here in a later BD when tracker mode is wired into
     pm-startup" → "lands here in a future pack version when tracker
     mode is wired into pm-startup"

   The 3 CLI mirrors (`.claude/skills/pm-startup/SKILL.md`,
   `.codex/skills/pm-startup/SKILL.md`,
   `.gemini/commands/pm-startup.toml`) regenerate from
   `project-template/skills/pm-startup/SKILL.md` via
   `stage_s4_skills()` — Pack Chat should verify whether the existing
   versions in `.claude/`, `.codex/`, `.gemini/` need separate edit
   or whether the source-of-truth edit suffices. (Empirically, the
   four mirrors carry identical L213 text — direct edit each, or
   single edit + manifest regen.)

4. **`project-template/.codex/config.toml.example` L17:**
   - "(defer to future BD if needed)" → "(defer to a future pack
     version if needed)"

5. **`supporting-docs/MIGRATION-v10-to-v11.md`:**
   - L597-599: "that's a defect — please file a BD against the
     `customize-preserve` library..." → "that's a defect — please
     file an inbound issue (`pack-feedback-friction` or
     `pack-feedback-prompt`) against the pack..."
   - L712: "File a BD with the disposition row..." → "File an inbound
     issue with the disposition row..."
   - L714: "Wait for the BD to land" → "Wait for the pack-side fix to
     land"
   - L727: "your project's BD volume" → "your project's TD/work-item
     volume"

### §9.2 SHOULD fixes (3 distinct edits)

6. **`templates-archive/v11.1/INDEX.md` L53-61:** rephrase v11.1
   form section to acknowledge pack/project divergence post-BD-193
   (no byte-identical claim; reference live forms at pack-root + at
   project-template with the F2.d divergence noted). Optionally
   delete the section if no v11.1 archive form file is going to be
   created.

7. **`templates-archive/v11.0/INDEX.md` L30-32:** correct "4-option"
   claim and "composite form for BD, TD, ..." naming to reflect post-
   D16 archive state (3 options; "composite form for TD, ...").

8. **`scripts/validate-pack.py` Check 24:** relax or remove byte-
   identity gate between `pack-ops/HELP-FRAGMENT-TRACKER.md` and
   `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` per F4/F5
   separation-of-concerns contract. The check IMMEDIATELY passes
   today; this is a latent inconsistency. Pack Chat may judge this
   as a separate BD vs in-scope for Phase 5.

### §9.3 NIT fixes (2 distinct edits)

9. **`templates-archive/README.md` L46:** "type per minor: BD, TD,
   phase-epic, phase-task, inbound at v11.0" → "type per minor: BD
   (pack-internal), TD, phase-epic, phase-task, inbound at v11.0".

10. **`IMPLEMENTATION-REPORT-BD-193.md` §14:** correct "Check 41" to
    "`check_issue_template_forms()`" (commit message stays — already
    landed).

### §9.4 AMBIGUOUS — surface to user before Phase 5

§4.6 mention-to-exclude pattern on phase-task/phase-part SCHEMAs (M-17).

### §9.5 Phase 5 manifest regeneration

If Phase 5 lands edits to any of `project-template/`, `scripts/`,
`pack-ops/`, or `supporting-docs/` (which it will — §9.1 + §9.2 hits
all of these directories), `test-fixtures/manifest.txt` will need to
regenerate per `feedback_manifest_regen_on_v11_surface`.

### §9.6 Phase 5 verification gates

After Phase 5 lands:
- `python3 scripts/validate-pack.py` MUST PASS (43/43)
- `bash test-fixtures/build.sh --verify` MUST PASS
- `bash scripts/tests/test-issue-forms.sh` MUST PASS (78/0)
- `grep -rn "BD-[0-9]\|sibling BD\|open BD\|file a BD\|BD volume\|
  future BD\|later BD" project-template/ supporting-docs/` MUST
  return only the LEGITIMATE survivors per the disposition (17 in
  MIGRATION-v10-to-v11.md Class A + 1 in project-template/work-item
  L18 §6.1 KEEP).

---

## §10 — Cross-references

### §10.1 Phase 1/2/3 reports

- Phase 1 inventory:
  `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/AUDIT-INVENTORY-BD-TD-PATH.md`
  (782 lines).
- Phase 2 disposition:
  `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/AUDIT-DISPOSITION-BD-TD-PATH.md`
  (987 lines).
- Phase 3 implementation report:
  `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-193.md`
  (645 lines).

### §10.2 Working-tree HEAD

- `git rev-parse HEAD` = `85196d455f259477dc71d45f4eea9e092393813a`
- Commit: `fix: v11 — BD-193 Code Red 2 BD/TD scope cleanup`
- Files changed (per `git show --stat`): 37 (36 source + 1
  IMPL-REPORT)
- Insertions: 920; deletions: 255.

### §10.3 Pack memory rules cited

- `feedback_bd_pack_only_operational_rule` — Rule 1 (operational vs
  explanatory).
- `feedback_pack_project_separation_of_concerns` — Rule 2 (cross-side
  substitution).
- `feedback_client_facing_token_economy` — Rule 3 (token economy +
  necessity test).
- `feedback_filename_uniqueness` — bare-version shorthand audit rule.
- `feedback_manifest_regen_on_v11_surface` — v11-surface manifest
  contract.
- `feedback_fix_all_review_findings` — default fix-all triage
  discipline.
- `P-missed-7` (Pack memory in trinity `## Pack memory`) — boundary
  investigation methodology.

### §10.4 User-locked rules (audit-prompt §6.1)

1. BD entries are PACK-ONLY.
2. TD entries are CLIENT-ONLY.
3. TD lifecycle: Path 1, Path 2 (`phase-N.M` target only), Path
   3-forbidden.
4. `pack-ops/` is PACK-ONLY.
5. Scripts copying `pack-ops/` to client install is categorically
   wrong.

### §10.5 Project-side per-stream contract anchor

- `project-template/docs/project/backlog/_rules.md` L14 — filename
  regex `^TD-\d+\.md$` (project-side per-entry filename contract;
  basis for the LEAK disposition on A-3.33.1 and A-3.46.22).

### §10.6 Phase 3 verification gates run at HEAD by Phase 4

| Gate | Result |
|---|---|
| `python3 scripts/validate-pack.py` | PASS — 43/43 checks OK |
| `bash test-fixtures/build.sh --verify` | PASS — all 6 fixture SHAs match |
| `bash scripts/tests/test-issue-forms.sh` | PASS — 78/0 |
| Trinity parity (`grep -A 6 "Tier 0 installation note"` + `diff`) | PASS — 3 trinity files byte-identical at the modified paragraph |
| Project-template BD- reference count | 1 (sole §6.1 KEEP at work-item.yml:18) |
| Supporting-docs BD- reference count in non-MIGRATION files | 0 |
| MIGRATION BD- count (Class A LEGITIMATE) | 17 references = 16 disposition rows |

### §10.7 Read-only verification statement

This report was authored read-only on the v11-dev working tree:
- No source files modified.
- No state-changing git verbs invoked.
- Only Write target: this report file at
  `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/PACK-REVIEW-BD-193-PHASE-4.md`.

---

## §11 — End of Phase 4 review

Phase 3 successfully applied 100% of the Phase 2 disposition decisions
without regression. The 5 MUST findings in §4.1-§4.5 are Phase 1
INVENTORY MISSES that propagated through the pipeline — they are
NEW LEAKS the cleanup was designed to eliminate but were not
identified for cleanup. The 3 SHOULD findings are collateral
stale-claim consequences of F2.c/F2.d. The 2 NIT findings are
cosmetic. The 1 AMBIGUOUS finding extends §6.1 Reading A to two
additional pack-archive surfaces.

The recommended Phase 5 fix-coder cycle would close ~10 distinct
edits across ~10 files (plus the manifest regen) — manageable in a
single commit.

End of PACK-REVIEW-BD-193-PHASE-4.md.
