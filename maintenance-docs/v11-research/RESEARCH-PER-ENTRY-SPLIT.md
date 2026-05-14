---
title: RESEARCH-PER-ENTRY-SPLIT
status: fact-finding-only
scope: BACKLOG / IMPLEMENTATION-PLAN / CHANGELOG
audience: pack-architect (next), v11-implementation reviewer
out-of-scope: STATUS.md, PACK-FEEDBACK.md, ARCHITECTURE.md (superseded), maintenance-docs/archive/v11/*
authoritative-design: ARCHITECTURE-V3.md + V3.1/V3.2/V3.3-DELTA.md + IMPLEMENTATION-PLAN.md (v11-research)
date: 2026-05-13
---

# Per-entry split — fact-finding research

Fact-finding-only research feeding the upcoming `ARCHITECTURE-PER-ENTRY-SPLIT.md`.
Scoped to the three entry-stream files: `BACKLOG.md`, `IMPLEMENTATION-PLAN.md`
(post-rename) / `IMPLEMENTATION_PLAN.md` (v10.x naming), and `CHANGELOG.md`.
`STATUS.md` and `PACK-FEEDBACK.md` are out of scope. The existing v11 design
(`ARCHITECTURE-V3.md` + the three V3.x DELTAs + `IMPLEMENTATION-PLAN.md` in
`maintenance-docs/v11-research/`) is authoritative and is not re-litigated.

---

## §1 — Authoritative v11 entry-shape design

Cited sections from the authoritative v11 design corpus that touch entry shape,
entry format, the three stream files, tracker forward/reverse migration of
entries, or BD/TD identifier conventions. Each bullet cites a single section by
heading text and line range; the architect can pull the full text of the
section when needed.

### `maintenance-docs/v11-research/ARCHITECTURE-V3.md`

Headings observed via `grep -n "^## \|^### "`; line ranges established against
the live file (3,049 lines total).

- §0.5 "Sections preserved verbatim from V2 (read V2 directly)" — lines 68–93.
  Names V2 sections that V3 inherits unchanged, including V2 §18 (lifecycle
  state machines) and V2 §22 (verb mappings; per V3 §27 traceability §27.5
  at lines 529–540 V2 §22 is the pack-verb catalog).
- §16 "Decisions (V3)" — lines 152–187. V3 decision register (D-1..D-23
  visible elsewhere); the rows include D-4-V2 (form-family, entries), D-18
  (`template_version` dual-carrier on issue forms), D-19 (inflection-point
  signals referencing BACKLOG / IMPLEMENTATION-PLAN / STATUS sizes).
- §28.1 "OQ-19 — inflection-point signals and thresholds" — lines 566–1032.
  Names `bd_count_active` / `bd_count_total` / `backlog_kb` /
  `backlog_growth_30d` (pack-side); `td_count_active` / `td_count_total`
  / `backlog_kb` / `phase_count` / `implementation_plan_kb` /
  `typed_deferral_count` (project-side). Signal-table rows at lines
  586–605 (pack) and 595–636 (project) define how the three streams are
  measured. Line 603 explicitly states "the pack repo has no
  `IMPLEMENTATION_PLAN.md`".
- §28.1.4 "Recommendation-state schema" — referenced from §28.1 (cited by
  D-19 at line 179). State file = `.pack-tracker/recommendation-state.json`.
- §28.2 "OQ-20 — help-verb scope" — lines 1033–1484. Not an entry-shape
  section but the verbs (`pack triage <id>`) at lines 1064 / 1087 operate
  on entry IDs.
- Appendix D "V3 design walkthroughs" — lines 1876–2275. D.1 (pack worked
  example, lines 1883–1923) and D.2 (OT client worked example, lines
  1924–2038) cite live counts: "BACKLOG.md has 49 BD entries" (line 1887),
  "BACKLOG.md has 113 TD entries" (line 1928), "IMPLEMENTATION_PLAN.md
  has 60 phases" (line 1929).
- Appendix I.5 "BD-NNN entries the planner will create" — lines 2879–2909.
  States the architect's hint that the planner is free to break the work
  into BD-NNN entries.

### `maintenance-docs/v11-research/ARCHITECTURE-V3.1-DELTA.md`

276 lines total. Headings via `grep -n "^## \|^### "`.

- §3 "Decision: §4.2 BACKLOG format drift in reverse migration — picked A2"
  — lines 180–255. Codifies the v10 BACKLOG grammar as the authoritative
  format for reverse-migration emission (option A2 chosen).

### `maintenance-docs/v11-research/ARCHITECTURE-V3.2-DELTA.md`

506 lines total.

- §2 "Decision D-21 — phase tasks are first-class L3 entities" — lines
  42–115. Sub-sections cover identifier scheme (§2.6, lines 101–109),
  state/status mapping (§2.5, lines 84–99), form-family composition with
  D-4-V2 (§2.4, lines 76–82), and the 3-level cap preservation (§2.3,
  lines 70–74).
- §3 "Decision D-22 — TD-NNN promotion paths" — lines 122–201. Three
  paths (TD→phase, TD→phase task, TD→part of a task) plus the
  promotion-path label family (§3.5, lines 186–200).
- §4 "Forward and reverse migration extensions" — lines 202–323.
  §4.1 forward parser for `IMPLEMENTATION_PLAN.md ### Tasks` (lines
  204–254); §4.2 reverse emit for `### Tasks` (lines 255–282); §4.3
  sidecar additions for phase tasks (lines 283–308); §4.4 round-trip
  test extension (lines 309–323).
- §5 "Cross-entity dependencies between TDs and phase work" — lines
  324–395. §5.3 flat-file syntax (v10 grammar preserved + extended;
  lines 345–364).

### `maintenance-docs/v11-research/ARCHITECTURE-V3.3-DELTA.md`

917 lines total.

- §1 "What V3.2-DELTA decisions are superseded vs reaffirmed" — lines
  20–37.
- §2 "D-21 (V3.3) — entity placement and the 3-level hierarchy" — lines
  38–100. §2.6 (lines 91–100) "Pack-side BD-NNN at L1 — V1 §5 line 859
  supersession" makes the pack-side BD identifier convention explicit.
- §3 "D-22 (V3.3) — two-path TD promotion plus direct-close" — lines
  101–184. Includes §3.2 direct-close (lines 121–134), §3.3 Path 1 —
  TD becomes a new phase (lines 135–153), §3.4 Path 2 — TD becomes a
  new phase task (lines 154–173), §3.5 label-family — two kinds (lines
  174–184).
- §4 "Forward / reverse / round-trip mechanics" — lines 185–222. §4.1
  forward parser for `IMPLEMENTATION-PLAN.md ### Tasks` (lines 187–192;
  note: hyphenated form already used in V3.3 prose); §4.2 reverse
  emitter (lines 193–196); §4.3 sidecar additions (lines 197–204);
  §4.4 round-trip test extensions (lines 205–222).
- §5 "Cross-entity dependencies — uniform model" — lines 224–323. §5.3
  "Flat-file syntax (v10 grammar — additive extensions)" lines 256–279
  cites METHODOLOGY § Part 7 lines 990-993 (BACKLOG `Blockers:`) and
  METHODOLOGY § Part 4 line 263 (phase task `Dependencies` bullet) as
  the v10 grammar slots being extended.
- §6 "Templates and dependency fields" — lines 308–386. §6.4
  "Identifier scheme summary" (lines 361–370) enumerates the v11
  identifier set including `phase-N.M` for L3 phase tasks. §6.3 "State /
  status mapping per entity type" (lines 341–360).
- §9 "Blast radius for the planner pass" — lines 778–902. §9.4
  validate-pack.py checks added (lines 838–848), §9.5 METHODOLOGY
  updates (lines 849–856), §9.6 other doc updates (lines 857–865).

### `maintenance-docs/v11-research/IMPLEMENTATION-PLAN.md`

1,109 lines total. Headings via `grep -n "^## \|^### "`.

- §1.2 "Form family + intake (D-4-V2, D-16, D-17, D-18)" — lines 85–126.
  BD-063 (issue forms `work-item.yml` / `inbound.yml` at both pack and
  client surfaces) and BD-064 (template-archive `bd-v11.0` schemas)
  fix the entry-form structure that maps to BACKLOG entries.
- §1.3 "Migration: forward (D-3, D-8)" — lines 127–166. BD-065 lands
  forward migration (`BACKLOG.md` → tracker issues).
- §1.4 "Migration: reverse (D-3, D-8) — mandatory" — lines 167–209.
  BD-067 lands reverse emission (tracker issues → `BACKLOG.md`,
  `IMPLEMENTATION-PLAN.md`, `CHANGELOG.md` skeleton, `STATUS.md`).
- §1.6 "Mirror file behavior (D-7) and trinity Source column (D-6)" —
  lines 231–236.
- §2.2 "README + CHANGELOG version cut" — lines 599–655. BD-085
  (`scripts/migrate-v10-to-v11.sh`), BD-086 (README version row),
  BD-087 (CHANGELOG.md v11.0 entry).
- §2.5 "BD-059 — v10 migration customization preservation" — lines
  738–785. The BD-088 customization-preservation contract referenced
  by `scripts/lib/customization-preserve.sh` line 32.

---

## §2 — Pack-side current state

Pack-root `BACKLOG.md` and `CHANGELOG.md` in the v11-dev tree at
`/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`. Pack repo has
no `IMPLEMENTATION-PLAN.md` / `IMPLEMENTATION_PLAN.md` at root (confirmed by
`ARCHITECTURE-V3.md` line 603: "The pack repo has no `IMPLEMENTATION_PLAN.md`
(per `INTERNAL-INVENTORY.md`)").

### `BACKLOG.md`

- Line count: 3,627 lines (`wc -l BACKLOG.md`).
- Byte count: 341,954 bytes (`ls -la` 2026-05-12 22:51).
- Section layout (H2 headings via `grep -n "^## "`):
  - `## How to use this file` at line 9
  - `## Active — v11 Scope` at line 23
  - `## Active — v10 Scope` at line 1975
  - `## Resolved — v8 (March 2026)` at line 2248
  - `## Deferred` at line 3457
- Preamble / front-matter at lines 1–7. The preamble explicitly cites
  METHODOLOGY: `BACKLOG.md:5: "Format follows the standard BACKLOG item
  format from METHODOLOGY.md Part 7."`
- `## How to use this file` (lines 9–20) enumerates use-rules: commit-
  message reference style (`feat: v9 — BD-020 description`), Status
  flip on resolution, Resolution-field fields for Cancelled/Deprecated,
  blocker-target-version pattern for deferred items, BD-NNN sequencing,
  "ships in the repo so agents can read it."
- Total BD entry headers (`^\*\*BD-` count): 144 entries.
- Entry separators (`^---$` count): 146 separators.
- Sample entry (BD-156 — recent Resolved, fully populated; lines 1443–1450):

```
**BD-156 — protobuf-patterns skill — extract Proto3 schema rules from grpc-patterns; standalone-usable via intersection table**
Type: TODO(version) — surfaced 2026-05-11 during BD-142 model-validation checkpoint discussion (gap in 5+3 model for standalone Protocol Buffers usage — Proto3 rules currently bundled inside `grpc-patterns` exclude non-gRPC scenarios); slotted before BD-149 per user direction so the `*-patterns` naming convention has a worked example AND so the standalone-protobuf gap closes before v11.0 ships
Status: Resolved
Blockers: BD-142 (PLATFORM-SKILLS.md intersection table must exist for the new skill row); BD-141 (predicate-helper precedent — `python_data_marker_detected()` pattern in `scripts/lib/detect.sh` that this BD's `protobuf_marker_detected()` mirrors)
Unblocks: BD-149 (naming-convention codification — `protobuf-patterns` is a worked example of the `*-patterns` convention; per user direction BD-156 is a hard blocker for BD-149 so the convention can be codified with a concrete reference and the standalone-protobuf gap is guaranteed to close before v11.0 ships); standalone Protocol Buffers usage in client projects (binary file format, IPC payloads, non-gRPC RPC frameworks like Twirp / Connect, persistent storage formats, log formats — currently uncovered by any skill)
File/Symbol: NEW `project-template/skills/protobuf-patterns/SKILL.md` (single canonical path per pack convention; per-CLI fan-out happens at install time via `init-project.sh stage_s4_skills`); MODIFIED `project-template/skills/grpc-patterns/SKILL.md` — Proto3 schema-design rules removed and cross-referenced to `protobuf-patterns`; gRPC-specific rules (servicers, interceptors, streaming, deadlines, error model, async handlers, grpc-swift-2 / grpc.aio specifics) retained; MODIFIED `project-template/docs/pack/PLATFORM-SKILLS.md` — new intersection-table row for `protobuf-patterns`; updated `grpc-patterns` description in dimensional-skills table to drop Proto3 schema language; updated `### Dimensional skills (16)` header to `(17)` and Full skill inventory totals (31 → 32 total); MODIFIED `scripts/lib/detect.sh` — new function `protobuf_marker_detected()` (markers: project tree contains any `.proto` files OR dependency manifests list any of `protobuf`, `swift-protobuf` / `SwiftProtobuf`, `grpc-tools`, `grpc-swift-2`, or `protoc` tooling); MODIFIED `scripts/init-project.sh` — wire `protobuf_marker_detected()` into `pack_skill_coverage_for()` for proto-marker detection at scaffold time; MODIFIED `scripts/add-capability.sh` — capability_skills row or comment cross-reference for protobuf-patterns intersection loading; MODIFIED `scripts/validate-pack.py` Check 31 (skill-cell consistency, added by BD-146) — must pass with new skill in intersection table
Description: Per the BD-142 model-validation checkpoint discussion (2026-05-11), the 5+3 dimension model has a gap for standalone Protocol Buffers usage. […full Description body continues at line 1449…]
Resolved: 2026-05-12 in commit af2f651 — NEW project-template/skills/protobuf-patterns/SKILL.md (234 lines, 9 sections, 45 numbered rules) at single canonical path (per pack convention; per-CLI fan-out happens via init-project.sh); grpc-patterns Proto3 rules stripped + companion-skill cross-reference + rule renumbering 44→33; PLATFORM-SKILLS.md intersection row + counts 16→17 / 31→32 + per-agent rows + worked examples; new protobuf_marker_detected() in detect.sh mirroring BD-141 pattern with literal "protobuf-marker: yes|no" tight-contract output; init-project.sh proto) case wired; add-capability.sh comment cross-reference at protocol:grpc; test-detect.sh +10 cases (42→52 PASS); validate-pack 30/30 PASS; reviewer APPROVE no nits.
```

- Entry-field labels observed across the file (line-prefix grep):
  `Type:`, `Status:`, `Blockers:`, `Unblocks:`, `File/Symbol:`,
  `Description:`, `Resolved:`. The bold-header line (`**BD-NNN — Title**`)
  starts the entry; the separator `---` ends it.
- Cross-reference syntax observed in entry bodies:
  - BD-NNN textual references (e.g. `BD-142`, `BD-141`, `BD-149` in
    BD-156's Blockers / Unblocks).
  - File-path references in backticks (e.g.
    `` `scripts/lib/detect.sh` ``, `` `project-template/docs/pack/PLATFORM-SKILLS.md` ``).
  - File:line references with no link wrapper, e.g. line 1471 cites
    `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md`
    `§4.4`.
  - Commit-hash references (e.g. `commit af2f651` in BD-156's Resolved
    line at 1450).
- Lifecycle states observed in pack BACKLOG (`grep -n "Status: "` →
  unique values): `Open`, `Resolved`, `Deferred`, `Cancelled`,
  `Deprecated`. (The grep also surfaces prose lines that contain
  "Status: " inside `Resolved:` narrative; the canonical state vocabulary
  is the five above.)
- `Type:` field values are open-vocabulary `TODO(<scope>)`. In pack
  BACKLOG every observed value is `TODO(version)` or
  `TODO(version) — <prose>` (no `KNOWN GAP` / `VERIFY` shapes observed
  pack-side).

### `CHANGELOG.md`

- Line count: 733 lines (`wc -l CHANGELOG.md`).
- Byte count: 46,117 bytes.
- Preamble at lines 1–6: "All notable changes to the AI Agent Config
  Pack are documented here. Each version is available as a git tag".
- Section layout (H2 / H3 headings via `grep -n "^## \|^### "`):
  - `## v11 — May 2026` at line 8
    - `### v11.0 — Issue-tracker integration + customization-preservation fix` at line 10
  - `## v10 — April 2026` at line 269
    - `### v10.0 (post-release patches) — April 2026` at line 271
    - `### v10.0 — April 2026` at line 357
  - `## v9 — April 2026` at line 421 with `### v9.3 — April 2026` at line 423
  - `## v8 — March 2026` at line 465 with `### v8.10 — April 2026`, `### v8.9 — April 9, 2026`, `### v8.8 — April 7, 2026` at lines 467 / 493 / 508
  - `### New files — methodology infrastructure`, `### New agents and skills`, `### Renamed`, `### Critical fix`, `### Updated — all three templates`, `### Updated — CLAUDE.md and AGENTS.md (apple, monorepo)`, `### Updated — QUICKSTART.md`, `### Updated — BACKLOG.md` at lines 548 / 570 / 576 / 580 / 586 / 600 / 609 / 614 (under earlier major-version sections)
  - `## v7 — March 23, 2026` at line 621
  - `## v6 — March 11, 2026` at line 641
  - `## v5 — March 9, 2026` at line 660
  - `## v4 — March 9, 2026` at line 676
- Version block sample — `### v11.0` (lines 10–80; partial body shown).
  The block begins with a bold heading enumerating scope buckets
  (`**Scope A — Issue-tracker integration (D-1..D-23)**` at line 12;
  `**Scope B — v11 version cut + ride-alongs**` at line 43) and is
  organized as nested bullet lists. BD references are inline
  parenthetical (e.g. `(BD-060)` at line 16, `(BD-065 / BD-068 / BD-070)`
  at line 20).
- The first 10 lines of the v11.0 entry:

```
## v11 — May 2026

### v11.0 — Issue-tracker integration + customization-preservation fix

**Scope A — Issue-tracker integration (D-1..D-23)**

- D-1..D-2 — TrackerProvider abstraction (V1 §2.1): 18 ops + raw +
  capabilities. Canonical `gh` backend (`scripts/lib/tracker-provider-gh.sh`)
  with future-extensibility for forgejo/linear/jira. (BD-060)
- D-3 — Forward and reverse migration libraries
```

---

## §3 — Project-side current state (OT as v10.1 client reference)

The OT project files live under `docs/project/` (not at repo root). `ls -la
/Users/david/Developer/OptiquityTrader/BACKLOG.md /Users/david/Developer/OptiquityTrader/IMPLEMENTATION_PLAN.md
/Users/david/Developer/OptiquityTrader/CHANGELOG.md` returns "No such file or
directory" for all three. `find /Users/david/Developer/OptiquityTrader
-maxdepth 3 -type f` locates them at:
- `/Users/david/Developer/OptiquityTrader/docs/project/BACKLOG.md`
- `/Users/david/Developer/OptiquityTrader/docs/project/IMPLEMENTATION_PLAN.md`
- `/Users/david/Developer/OptiquityTrader/docs/project/CHANGELOG.md`

All three exist; line counts via `wc -l`:
- `BACKLOG.md`: 1,478 lines
- `IMPLEMENTATION_PLAN.md`: 5,235 lines (underscore naming — v10.x convention)
- `CHANGELOG.md`: 2,579 lines

### `docs/project/BACKLOG.md`

- Preamble at lines 1–6: "OptiquityTrader — Backlog … Known issues, deferred
  improvements, and technical debt items tracked here. … Each item references
  the phase that identified it."
- Section layout (H2 via `grep -n "^## "`): the file is partitioned by
  Phase. Headings include `## Phase 10 — Public.com Broker Integration`
  (line 9), `## Phase 11 — E*Trade Broker Integration` (line 75),
  `## Phase 12 — Schwab Broker Integration` (line 151), `## Simulation
  Layer` (line 297), `## Phase 25 — Global LSP and Interface
  Uniformity` (line 343), `## Phase 27 — Persistence Round-Trip`
  (line 399), `## Phase 29 and Later — Broker Wiring, Persistence,
  and Stub Gaps` (line 445), `## How to use this file` (line 485),
  `## Phase 30 and Later — Additional Technical Debt` (line 494),
  `## Phase 33 — Resume State and Recovery` (line 813), `## Phase 34
  — OAuth and Credential Flows` (line 882), `## Phase 35 — Live
  Broker Sandbox Verification` (line 925), `## Phase 52 — TestClock
  and Timing Dependency Elimination` (line 953), `## Phase 35 §35.5
  — Broker Compliance Audit` (line 969), `## Full Codebase Audit —
  2026-04-13` (line 1198). Each H2 is followed by `### Technical
  Debt` H3 then TD-NNN entries.
- "How to use this file" mid-file at lines 485–490 (not at top —
  follows the first cluster of Phase 10–29 entries). Use-rules:
  "Add items here during phase reviews for ⚠️ findings that don't
  block commit", "Reference the item number in code comments where
  applicable (e.g. `// See BACKLOG TD-001`)", "Remove items here when
  they are resolved, noting the phase they were fixed in", "Items
  should be small enough to fix in a single focused session."
- Sample entry — TD-001 (lines 13–21):

```
**TD-001 — stopPrice missing from OrderRequest domain type** ✅ RESOLVED (Phase 14)
Type: KNOWN GAP(functional)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: `OptiquityTrader/Domain/Models/OrderTypes.swift` — `OrderRequest`
Description: OrderRequest lacked a stopPrice field. All broker data-layer mappers forwarded hardcoded nil for stop price regardless of the order request.
Context: stopPrice: Decimal? added to OrderRequest. All broker mappers (E*Trade, Schwab, Public.com) updated to forward order.stopPrice.
Resolution: 2026-03-27, completed, Phase 14 — stopPrice: Decimal? added to OrderRequest; all broker mapper tests updated.
```

- Entry-field labels: `Type:`, `Status:`, `Blockers:`, `Unblocks:`,
  `File/Symbol:`, `Description:`, `Context:`, `Resolution:`. The
  bold-header line ends in `✅ RESOLVED (Phase NN)` annotation when
  Resolved. (Pack BACKLOG uses `Resolved:` field instead of the
  inline `✅ RESOLVED` annotation.)
- Cross-reference syntax observed:
  - TD-NNN textual references (e.g. TD-019 cross-referenced at
    line 50 in TD-004's Context).
  - Phase references (Phase 14 / Phase 36 / Phase 34 in Resolution
    field).
  - File-path references in backticks with optional `— SymbolName`
    suffix (e.g. `` `…/OrderTypes.swift` — `OrderRequest` `` at
    line 18).
  - Bullet-style `Blockers:` (multi-line):

```
Blockers:
  - Phase 55 (Test Double Enhancement)
```

  at lines 56–57 (TD-005), vs single-line `Blockers: None` at line
  16 (TD-001). Both forms observed.
- Lifecycle states observed (`grep -n "Status: "` → unique):
  `Open`, `Resolved`. Two values only.
- `Type:` values observed (unique): `KNOWN GAP(critical)`,
  `KNOWN GAP(dependency)`, `KNOWN GAP(functional)`,
  `KNOWN GAP(polish)`, `TODO(architecture)`, `TODO(dependency)`,
  `TODO(feature)`, `TODO(phase-27)`, `TODO(phase-31)`,
  `TODO(phase-33)`, `TODO(phase-34)`, `TODO(phase-37)`,
  `TODO(phase-52)`, `VERIFY(etrade-api)`, `VERIFY(public-api)`,
  `VERIFY(schwab-api)`.

### `docs/project/IMPLEMENTATION_PLAN.md`

- Filename uses underscore (`IMPLEMENTATION_PLAN.md`) — v10.x naming
  convention. (V11 rename to hyphenated `IMPLEMENTATION-PLAN.md` is
  owned by another chat's BD; see §5.)
- Preamble at lines 1–7: title line `# IMPLEMENTATION_PLAN.md —
  OptiquityTrader`, `> **Generated**: 2026-03-20`, `> **Updated**:
  2026-03-20 (§2n–§2q architecture sync; Phase 0 inserted; Phases
  10–12 added)`, target platforms line.
- Section layout (H2 via `grep -n "^## "`):
  - `## Codebase Snapshot` at line 10
  - `## Phase 0 — Architecture Sync: Strategy Event Model and Broker Foundation` at line 34
  - `## Phase 1 — XCTest Target and Test Infrastructure` at line 302
  - `## Phase 2 — `AnyTransaction` Type Erasure …` at line 500
  - `## Phase 3 — `AppNavigator` Wiring` at line 635
  - `## Phase 4 — `TradingEngine` Tick Loop …` at line 794
  - `## Phase 5 — SwiftData Persistence Layer` at line 981
  - `## Phase 6 — App Shell UI` at line 1185
  - `## Phase 7 — Broker / Account Setup Screen` at line 1307
  - `## Phase 8 — Strategy Invocation Management Screen` at line 1439
  - `## Phase 9 — Dashboard with Stub Data` at line 1527
  - `## Phase 10..12` at lines 1634 / 1848 / 2032
  - `## Phase 13 — Feature Inventory` at line 2203
  - … continues through `## Phase 18 — Security and Contributing Docs`.
- Phase entries follow a structure (per Phase 0 at lines 34–301):
  H2 phase heading, then `**Goal**:`, `**Prerequisite**:`, `---`,
  `### Tasks`, then `#### N.M — <Task Title>` sub-headings, each
  task body being a bullet list with `- **What**:`,
  `- **Dependencies**:`, etc. After tasks: `### Verification`,
  `### Agent`, `### Risks` sections.
- Sample phase-task excerpt — Phase 0 Task 0.1 (lines 45–106 partial):

```
### Tasks

#### 0.1 — `StrategyLogic` Protocol Replacement

- **What**: Replace the `execute(context:)/shutdown(context:)` contract with the event/command
  model from §2n:

  1. In `Domain/Protocols/StrategyLogic.swift`:
     - Remove `func execute(context: StrategyExecutionContext) async throws`
     - Remove `func shutdown(context: StrategyExecutionContext) async throws`
     - Add `var apiVersion: Int { get }` (required value: `1`)
     - Add `func onEvent(_ event: StrategyEvent) async -> [StrategyCommand]`
     […]
- **Dependencies**: None.
```

  Subsequent tasks at 0.2 (line 109), 0.3 (line 134), 0.5 (line 192),
  0.6 (line 213), 0.7 (line 252) each carry `- **What**:` …
  `- **Dependencies**: <list>`. The phase task identifier convention
  `#### <phase>.<task> — <title>` matches V3.2 §4.1 / V3.3 §4.1's
  forward-parser regex contract.

### `docs/project/CHANGELOG.md`

- Preamble at lines 1–3: "OptiquityTrader — Change Log … Historical
  record of architectural decisions and phase completions. Current
  architecture is documented in ARCHITECTURE.md."
- Section layout (H2 via `grep -n "^## "`): only `## Format Rules`
  at line 7. The rest of the file is H3-organized version/phase
  entries.
- "Format Rules" at lines 7–39 inlines an entry-format spec
  (fenced code block at lines 13–28) and rules at lines 30–39:
  "**Append-only**: never edit prior entries. Add new entries at
  the top", "**One entry per phase** at phase completion, committed
  in the same PR as the phase work", "**Date** = the date the phase
  was committed to `main`", "**Separator** (`---`) precedes every
  entry — including the first one", "**Architecture Iteration**
  label for early-project architecture doc iterations", "**BACKLOG.md**:
  mark resolved TD items ✅ in the same commit as the phase",
  "**README.md**: update Known Limitations in the same commit when
  a TD that appears there is resolved."
- Sample version entry (lines 43–67 — Phase 35):

```
### 2026-04-20 — Phase 35 — Live Broker Sandbox Verification

**Summary**: Implemented the full OAuth callback architecture […]

**Tasks completed**:
- §35.0a — BrokerOAuthCallbackMode capability, BrokerUserInputProvider, CredentialFlowState.awaitingUserInput, AddBrokerCredentialViewModel refactor
- §35.0b — Schwab automaticIntercept via OAuthEmbeddedBrowserView (WKWebView), redirect URI unification to https://127.0.0.1
[…]

**Backlog items addressed**: TD-070 resolved. TD-003, TD-008, TD-017, TD-020, TD-022, TD-023, TD-024, TD-025, TD-076, TD-077 investigated and deferred with logging (blocked on live credentials). TD-098–TD-113 created from §35.5 audit.

**Files created**: OAuthEmbeddedBrowserView.swift, BrokerOAuthCallbackMode.swift, BrokerEnvironment.swift, inspect-app-data.sh, reset-app-data.sh
**Files modified**: ETradeOAuthFlowCoordinator.swift, SchwabOAuthFlowCoordinator.swift, […]
**Test count**: 805 passing, 0 failing
**Build warnings**: 0
```

- Entry-field labels per the Format Rules spec at line 20–27:
  `**Summary**:`, body sections, `**Files created**:`,
  `**Files modified**:`, `**Test count**:`, `**Build warnings**:`.
- Cross-reference syntax observed: TD-NNN inline (e.g.
  `TD-070 resolved`, `TD-098–TD-113 created` at line 61); Phase
  references in heading (`### 2026-04-20 — Phase 35 — Live Broker
  Sandbox Verification`).
- Lifecycle states: not applicable — CHANGELOG entries do not carry
  status fields; they are append-only historical records.

---

## §4 — Pack vs project entry-shape differences (observable only)

| Dimension | Pack (BD) | Project (TD) |
|---|---|---|
| Identifier prefix | `BD-NNN` (e.g. `BD-156` at `BACKLOG.md:1443`). V3.3-DELTA §2.6 (lines 91–100) makes pack-side L1 BD-NNN explicit. | `TD-NNN` (e.g. `TD-001` at `OptiquityTrader/docs/project/BACKLOG.md:13`). V3.3-DELTA §6.4 (lines 361–370) places TD-NNN in the client identifier scheme. |
| Identifier numbering authority | Sequential, no formal scheme stated in `BACKLOG.md:1-20` preamble (cites METHODOLOGY Part 7); pack `CLAUDE.md:50-52` rule "Read BACKLOG.md, find the highest existing BD-NNN, increment by 1." | Per-project sequential within the project's `BACKLOG.md`; observed numbering reaches TD-113 (cited at `OptiquityTrader/docs/project/CHANGELOG.md:61`) in OT. |
| Required fields observed | `Type:`, `Status:`, `Blockers:`, `Unblocks:`, `File/Symbol:`, `Description:`, `Resolved:` (when Status=Resolved). Sample at `BACKLOG.md:1443-1450`. | `Type:`, `Status:`, `Blockers:`, `Unblocks:`, `File/Symbol:`, `Description:`, `Context:`, `Resolution:` (when Status=Resolved). Sample at `OptiquityTrader/docs/project/BACKLOG.md:13-21`. Differences: `Context:` is project-only (lines 20, 50); `Resolved:` (pack) vs `Resolution:` (project) for the closure field. Project Resolved entries also carry an inline `✅ RESOLVED (Phase NN)` annotation in the bold-header line (e.g. `OptiquityTrader/docs/project/BACKLOG.md:13`) — pack BDs do not. |
| Cross-reference target style | BD-NNN literal in prose; commit-hash literal (e.g. `commit af2f651` at `BACKLOG.md:1450`); file-path in backticks (e.g. `` `scripts/lib/detect.sh` `` at `BACKLOG.md:1448`); architecture-doc section reference (e.g. `ARCHITECTURE-SKILL-DIMENSIONS.md` `§3.7` at `BACKLOG.md:1449`). | TD-NNN literal in prose (e.g. TD-019 cross-ref at `OptiquityTrader/docs/project/BACKLOG.md:50`); Phase-N literal (e.g. `Phase 14` in TD-001's Resolution at `:21`); file:line or file-and-symbol reference (e.g. `OptiquityTrader/Data/Brokers/Public/PublicBroker.swift` — `mapCapabilities(from:)` at `:39`); per V3.3-DELTA §5.3 (lines 256–279) the v11 grammar extension allows `phase-N`, `phase-N.M`, `TD-NNN`, `BD-NNN` in the `Blockers:` bullet of project BACKLOG. |
| Lifecycle states observed | `Open`, `Resolved`, `Deferred`, `Cancelled`, `Deprecated` (`grep -n "Status: " BACKLOG.md`). Pack `BACKLOG.md:9-20` "How to use this file" documents Resolved / Cancelled / Deprecated / Deferred semantics. | `Open`, `Resolved` only (`grep -n "Status: " OptiquityTrader/docs/project/BACKLOG.md`). V3.3-DELTA §6.3 (lines 341–360) specifies state/status mapping per entity type. |
| Section partitioning (active/resolved/etc.) | Two-axis partition: by version × activity. H2 sections `## Active — v11 Scope` (`BACKLOG.md:23`), `## Active — v10 Scope` (`BACKLOG.md:1975`), `## Resolved — v8 (March 2026)` (`BACKLOG.md:2248`), `## Deferred` (`BACKLOG.md:3457`). Pack rule (pack `CLAUDE.md:148-152`): "BACKLOG.md has no Resolved section. Entries resolve in place by flipping `Status: Open` to `Status: Resolved`" — note: this rule conflicts with the live file having a `## Resolved — v8` H2 at `BACKLOG.md:2248`; this is observable as a fact, not analyzed. | Single-axis partition: by Phase. Each `## Phase NN — <title>` H2 (e.g. line 9, 75, 151) contains an `### Technical Debt` H3 followed by TD entries. No separate "Resolved" section; Resolved entries remain under their Phase H2 with `✅ RESOLVED (Phase NN)` annotation. |

---

## §5 — v10.1 → v11.0 migration entry-shape touchpoints

### v10.1 pack source

Read from `/Users/david/Developer/optiquity-ai-agent-config-pack`.
`git -C /Users/david/Developer/optiquity-ai-agent-config-pack rev-parse HEAD`
→ `fa817044ffaa6cc019f4cb975a4242be15060676` (commit message: "docs: v10.1
retroactive README row + CHANGELOG entry"; `git describe --tags` → `v10`).

v10.1 source `scripts/lib/` contains only two files: `detect.sh` and
`three-way.sh`. No migrator framework, no customization-preservation
library, no tracker libs. The v11 framework, customization-preservation
library, and tracker libs are v11-new.

v10.1 source has `BACKLOG.md` (1,618 lines) and `CHANGELOG.md` (548 lines)
at pack root; no `IMPLEMENTATION_PLAN.md` / `IMPLEMENTATION-PLAN.md`
(consistent with `ARCHITECTURE-V3.md:603` "the pack repo has no
`IMPLEMENTATION_PLAN.md`").

### v11-dev migrator script and lib files

- `scripts/migrate-v10-to-v11.sh` (the v10→v11 adapter; v11-dev,
  v10.1 has no analog).
  - Declares `MIGRATOR_FROM_VERSION="v10"` / `MIGRATOR_TO_VERSION="v11"`
    / `MIGRATOR_BASELINE_TAG="${V10_TAG:-v10}"` /
    `MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"` at lines 73–76.
  - `migrator_manifest()` heredoc at lines 89–106 enumerates the
    per-file transforms. The manifest contains 13 rows — trinity files,
    `.claude/settings.json`, `.mcp.json.example`, `.codex/config.toml`
    + `.example` + `requirements.toml`, `.gemini/.env.example` +
    `settings.json`, `docs/pack/PM-CHAT.md` / `PLATFORM-SKILLS.md` /
    `PACK-FEEDBACK.md` / `PROMPT-TEMPLATES.md`. **`BACKLOG.md`,
    `IMPLEMENTATION-PLAN.md`, `IMPLEMENTATION_PLAN.md`, and `CHANGELOG.md`
    are NOT in this manifest.**
  - `migrator_directory_sweeps()` at lines 111–118 sweeps `scripts/`
    and the three per-CLI `agents/` dirs as `pack-script` /
    `pack-agent`.
  - `migrator_relocations()` and `migrator_artifact_installs()` at
    lines 123 / 128 are no-ops; the post-dispatch hook does the work.
  - `migrator_post_dispatch_hook()` at lines 134–149 calls
    `_v10_to_v11_rename_implementation_plan` (line 144),
    `_v10_to_v11_relocate_legacy_docs` (line 145),
    `_v10_to_v11_install_v11_artifacts` (line 146),
    `_v10_to_v11_rename_python_architecture_refs` (line 147),
    `_v10_to_v11_translate_capability_tokens` (line 148).
  - `_v10_to_v11_rename_implementation_plan()` at lines 167–219
    performs the `IMPLEMENTATION_PLAN.md` → `IMPLEMENTATION-PLAN.md`
    rename via `git mv` (line 201) with untracked-fallback (lines
    202–211). Collision case at lines 182–199 emits typed error
    `migration-rename-collision`. Banner is `── S4a (rename) — BD-104
    rename IMPLEMENTATION_PLAN.md → IMPLEMENTATION-PLAN.md ──` (line 175).
    **This rename is owned by BD-104; the rename mention here is
    factual.**

- `scripts/lib/migrator-core.sh` (v11-new; orchestrator for the BD-119
  framework).
  - Public-API contract at lines 1–34. Adapter env-vars `MIGRATOR_*`
    are read by core; `_MIGRATOR_*` is core-internal.
  - Required-vars list at lines 135–140: `MIGRATOR_FROM_VERSION`,
    `MIGRATOR_TO_VERSION`, `MIGRATOR_BASELINE_TAG`,
    `MIGRATOR_OWN_SIDECAR_SUFFIX`.
  - Required-hooks list at lines 147–153:
    `migrator_manifest`, `migrator_directory_sweeps`,
    `migrator_relocations`, `migrator_artifact_installs`,
    `migrator_post_report_hook`.
  - Optional hooks at lines 217–224: `migrator_pre_dispatch_hook`
    (line 217), `migrator_post_dispatch_hook` (line 222).
  - Stage order at lines 212–230: `_stage_preflight` →
    `_stage_backup` → `_stage_libs` → (pre-dispatch hook) →
    `_stage_dispatch` → (post-dispatch hook) → `_stage_relocations`
    → `_stage_artifact_installs` → `_stage_report` →
    (post-report hook).

- `scripts/lib/migrator-stages.sh` (v11-new). Functions:
  `_stage_preflight` (line 62), `_stage_backup` (146), `_stage_libs`
  (195), `_stage_dispatch` (228), `_stage_relocations` (260),
  `_stage_artifact_installs` (352), `_stage_report` (429),
  `_stage_report_stamp_tracker_version` (482). No `BACKLOG` /
  `CHANGELOG` / `IMPLEMENTATION.PLAN` references inside this file.

- `scripts/lib/migrator-manifest.sh` (v11-new). Functions:
  `_manifest_reset_storage` (42), `_manifest_parse` (64),
  `_manifest_validate_trinity` (147), `_manifest_iterate` (216),
  `_manifest_dispatch_transform` (269), `_manifest_dispatch_add`
  (308), `_manifest_dispatch_remove` (341), `_manifest_dispatch_relocate`
  (371), `_manifest_sweep_directories` (432). Manifest action
  vocabulary (line 118): `transform | add | remove | relocate-from`.
  No `BACKLOG` / `CHANGELOG` / `IMPLEMENTATION.PLAN` references.

- `scripts/lib/customization-preserve.sh` (v11-new — BD-088).
  - Disposition tokens documented at lines 32–48:
    `unchanged-pack`, `pack-update-applied`,
    `merged-with-customization`,
    `customization-detected-needs-reconciliation`,
    `removed-by-design`, `project-only-file`,
    `project-deleted-pack-kept`, `removed-everywhere`,
    `unknown-classification`, `library-error`.
  - `customization_classify()` at lines 145–179 — the 12-class
    classification. Classes: `trinity`, `claude-settings`,
    `claude-mcp-example`, `codex-config-example`, `codex-config`,
    `gemini-env`, `pm-chat`, `custom-agent`, `pack-agent`,
    `pack-script`, `generic`. **The classifier does NOT enumerate
    `BACKLOG.md`, `CHANGELOG.md`, `IMPLEMENTATION_PLAN.md`, or
    `IMPLEMENTATION-PLAN.md` as named classes.** Any of these paths
    falls through the `case` ladder to the `*) printf 'generic\n'`
    branch (line 176–177).
  - Strategy dispatcher at lines 514–558: classes `trinity` /
    `pack-agent` / `pack-script` / `pm-chat` / `generic` all route
    to `_cp_strategy_text` (3-way text dispatch), per lines 531–532.
  - The only intra-file BACKLOG.md references at lines 483 / 499 are
    inside an awk env-file key-union routine (unrelated — variable
    name collision in awk source, not a manifest entry).

### BD-088 manifest classes referencing the three streams

None. `customization-preserve.sh` `customization_classify()` (lines 145–179)
does not name any of `BACKLOG.md`, `CHANGELOG.md`, `IMPLEMENTATION_PLAN.md`,
or `IMPLEMENTATION-PLAN.md`. They fall to the `generic` class and route
through `_cp_strategy_text` per the dispatch table at lines 531–532.

### BD-119 framework hooks an entry-shape-aware stage would consume

The hook contract a future entry-shape-aware stage could plug into is
defined in `scripts/lib/migrator-core.sh`:
- `migrator_manifest()` (required; line 148) — adapter-emitted TSV
  declaring per-file transforms.
- `migrator_directory_sweeps()` (required; line 149) — adapter-emitted
  rows for whole-directory iteration.
- `migrator_relocations()` (required; line 150) — adapter-emitted
  relocate-from rows.
- `migrator_artifact_installs()` (required; line 151) — adapter-emitted
  additive add rows.
- `migrator_post_report_hook()` (required; line 152) — post-report
  guidance text.
- `migrator_pre_dispatch_hook()` (optional; line 217) — runs between
  `_stage_libs` and `_stage_dispatch`.
- `migrator_post_dispatch_hook()` (optional; line 222) — runs between
  `_stage_dispatch` and `_stage_relocations`. The v10→v11 adapter uses
  this hook for the BD-104 rename and BD-042 relocation (lines 134–149
  of `scripts/migrate-v10-to-v11.sh`).

### Rename: `IMPLEMENTATION_PLAN.md` → `IMPLEMENTATION-PLAN.md`

Owned by BD-104. Cited mentions:
- `scripts/migrate-v10-to-v11.sh:151-218` — the rename implementation.
- `scripts/migrate-v10-to-v11.sh:175` — banner `── S4a (rename) —
  BD-104 rename IMPLEMENTATION_PLAN.md → IMPLEMENTATION-PLAN.md ──`.
- `ARCHITECTURE-V3.3-DELTA.md:187` — V3.3 §4.1 uses the hyphenated
  form `IMPLEMENTATION-PLAN.md` in the forward parser spec.
- `ARCHITECTURE-V3.2-DELTA.md:204` — V3.2 §4.1 uses the underscore
  form `IMPLEMENTATION_PLAN.md` (predates V3.3).
- `IMPLEMENTATION-PLAN.md:79` (the project-template/docs/pack/PM-CHAT.md
  source line) — references `IMPLEMENTATION-PLAN.md` (hyphenated).
- OT live file at `/Users/david/Developer/OptiquityTrader/docs/project/IMPLEMENTATION_PLAN.md`
  still uses the underscore (v10.x) form.

---

## §6 — Workflow code paths that read or write entry data

### Pack-side surfaces

- `.claude/skills/pack-startup/SKILL.md` (Claude pack-startup skill).
  Line 19: `Read \`BACKLOG.md\` in full.`
  Line 21: `Read only the most recent dated entry from \`CHANGELOG.md\`.`
  Frontmatter `name: pack-startup` (line 2), `allowed-tools: Read, Bash,
  Grep` (line 4). Step 2 "Read core state files" heading at line 17.

- `.codex/skills/pack-startup/SKILL.md` (Codex pack-startup skill).
  Same content. Line 19: `Read \`BACKLOG.md\` in full.`; line 21:
  `Read only the most recent dated entry from \`CHANGELOG.md\`.`

- `.gemini/commands/pack-startup.toml` (Gemini pack-startup TOML).
  `prompt =` block contains the same step 2 wording: `Read \`BACKLOG.md\`
  in full.` and `Read only the most recent dated entry from
  \`CHANGELOG.md\`.` (per `grep -l "BACKLOG\|CHANGELOG"` hit on the
  file). No separate `.gemini/skills/pack-startup/` directory — Gemini
  uses the commands TOML at this path; the pack repo's `.gemini/skills/`
  contains the other shared skills (architecture-review, commit-discipline,
  dependency-intake, documentation, implementation-report, planning,
  review, verification-harness) but no pack-startup.

- `.claude/agents/pack-architect.md` (pack architect agent).
  Line 27: `- BACKLOG.md (open BD items and their constraints)`.

- `.claude/agents/pack-planner.md` (pack planner agent).
  Line 32: `- BACKLOG.md (BD items in scope)`.

- `.claude/agents/pack-coder.md` (pack coder agent).
  Line 34: `modify BACKLOG.md, CHANGELOG.md, README.md version table,
  PACK-CHAT.md,` (rule prose; pack-coder may not modify these).
  Line 38: `**No BD status flips.** BACKLOG.md \`Status:\` flips happen
  post-review`.

- `.claude/agents/pack-reviewer.md` (pack reviewer agent).
  Line 28–29: `- **BACKLOG accuracy.** If the change resolves or modifies
  a BD item, verify the BACKLOG entry is updated with the correct status
  and resolution.`

- `PACK-CHAT.md` (pack-root, file-access strategy table and rules).
  Line 15: `- Track open backlog items (BD-NNN format in BACKLOG.md)`.
  Line 16: `- Maintain CHANGELOG.md and README.md version history`.
  Lines 42–43 (file-access strategy table rows):
  `| \`BACKLOG.md\` | Direct read | Open BD-NNN items, current backlog state |`
  `| \`CHANGELOG.md\` | Direct read (last entry only) | Current version and recent changes |`
  Line 67: rule wording about pack ops files staying separate from product files.
  Lines 80–81: `Do not use pack agents for PM-level decisions (BACKLOG
  entries, CHANGELOG entries, version management) — those remain pack chat`.
  Line 89: `are fix-immediately items — never defer them to BACKLOG.`
  Line 114: `(active BD count, BACKLOG.md size, 30-day BD growth)`.
  Line 130: `consent. This mirrors the BACKLOG / CHANGELOG approval rule —`.

### Project-side surfaces

- `project-template/skills/pm-startup/SKILL.md` (Claude / multi-CLI
  canonical pm-startup skill source).
  Lines 69–70: `- BACKLOG entries (resolve via the trinity \`##
  Document locations\` table; reads \`BACKLOG.md\` in flat-file mode,
  the tracker in tracker mode)`.
  Line 76: `Read only the most recent dated section from \`CHANGELOG.md\`.`
  Line 79: `from \`IMPLEMENTATION-PLAN.md\`.`
  Lines 83–87: `Resolve every BACKLOG / STATUS / IMPLEMENTATION-PLAN /
  CHANGELOG read through` … `tracker mode the table points at the
  tracker (BACKLOG / STATUS / CHANGELOG / IMPLEMENTATION-PLAN are
  tracker-mirrored read-only files in that mode).`
  Line 191: `**Open BACKLOG items:** [count of Status: Open + Status:
  Unblocked]`.
  Line 192: `**Last TD number:** TD-NNN (or "none yet" if BACKLOG is
  empty)`.

- `project-template/.claude/skills/pm-startup/SKILL.md` and
  `project-template/.codex/skills/pm-startup/SKILL.md` — per-CLI
  copies. The Codex copy was confirmed to carry the same wording
  at lines 69–70, 76, 79, 83–87, 191–192 (`grep -n "BACKLOG\|CHANGELOG\|
  IMPLEMENTATION.PLAN"` matches). A Gemini per-CLI copy ships under
  `project-template/.gemini/` (find result confirms presence of the
  `pm-startup` skill dir at that path).

- `project-template/.claude/agents/repo-ops.md` (project repo-ops
  agent).
  Lines 69–70: `- **No PM-only file edits.** Do not modify
  \`BACKLOG.md\`, \`CHANGELOG.md\`, \`STATUS.md\`, \`PACK-FEEDBACK.md\`,
  or any \`.md\` file`.

- `project-template/.claude/agents/coder.md` (project coder agent).
  Line 81: `modify \`BACKLOG.md\`, \`CHANGELOG.md\`, \`STATUS.md\`,
  \`PACK-FEEDBACK.md\`,`.

- `project-template/.claude/agents/auditor.md` (project auditor agent).
  Line 42: `8. Append a \`## Next steps\` section listing Critical and
  Major findings in priority order, cross-referencing the PM chat's
  BACKLOG processing workflow.`

- `project-template/.claude/agents/auditor-docs.md` (project auditor-docs
  agent).
  Lines 28–29: `- **CHANGELOG drift** — CHANGELOG entries must match
  git history. A CHANGELOG entry claiming a security fix that was not
  actually committed`.
  Line 62: `CHANGELOG entry claiming a security fix that was not
  committed is Critical.`

- `project-template/docs/pack/PM-CHAT.md` (project PM-CHAT.md — the
  PM chat operating rules).
  Line 36: `- Maintain BACKLOG.md, STATUS.md, and CHANGELOG.md (after
  user approval)`.
  Lines 119, 121, 123 (file-access strategy table rows):
  `| \`BACKLOG.md\` | Direct read | Small, changes frequently, must
  always be current |`
  `| \`CHANGELOG.md\` | Direct read (last entry only) | Recent history
  only |`
  `| \`IMPLEMENTATION-PLAN.md\` | Direct read (current phase section
  only) | Full file is large |`
  Line 197: `- **BACKLOG and deferral comment rules.** Follow Part 7
  of METHODOLOGY.md exactly.`
  Line 201: `- **Source file edits.** You may write to BACKLOG.md,
  STATUS.md, and deferral`.
  Lines 205–206: `table must link to its heading in \`IMPLEMENTATION-
  PLAN.md\` using \`[Title](IMPLEMENTATION-PLAN.md#anchor)\` format.`
  Line 338: `- PM-only files (BACKLOG.md, CHANGELOG.md, STATUS.md,`.
  Lines 445–448: `Run \`/pm-startup\`. The skill reads BACKLOG entries,
  STATUS entries (resolve … BACKLOG.md / STATUS.md; tracker mode reads
  the tracker), PM-CHAT.md, CHANGELOG.md, IMPLEMENTATION-PLAN.md,
  METHODOLOGY.md, and PLATFORM-SKILLS.md.`

---

## §7 — validate-pack.py checks touching entry files

Searched `scripts/validate-pack.py` for `BACKLOG`, `CHANGELOG`,
`IMPLEMENTATION_PLAN`, `IMPLEMENTATION-PLAN` literals. Hits resolve to
a single numbered check:

- **Check 3 — TD-TBD sentinels in BACKLOG.md** (function
  `check_td_tbd_sentinels`).
  - Function defined at line 262.
  - Check banner at line 263: `print("\n── Check 3: TD-TBD sentinels
    in BACKLOG.md ──")`.
  - Reads `REPO_ROOT / "BACKLOG.md"` at line 264; returns early at
    266 if missing.
  - Body lines 264–281: scans BACKLOG.md for entry-header lines
    matching `^\*\*TD-TBD\s*—` (regex at line 276) and fails when
    found, per the comment at lines 269–271: "Check for TD-TBD in
    BACKLOG entry identifier lines (e.g., \"**TD-TBD — Title**\").
    This catches entries where the PM chat forgot to assign a real
    BD-NNN number."
  - File range: lines 262–281.

No other numbered check references `BACKLOG.md`, `CHANGELOG.md`,
`IMPLEMENTATION_PLAN.md`, or `IMPLEMENTATION-PLAN.md` directly. Checks
21–24 (BD-082 family) operate on pack-help fragments; Check 25 (BD-089)
is the customization-detection regression guard; Check 31 (BD-146) is
skill-cell consistency. (Function name list verified via `grep -n "^def
check_"`.)

---

## §8 — Tracker-mode entry-shape interaction (citations to V3.x)

### `scripts/lib/tracker-migrate-forward.sh`

Functions and stream touchpoints:
- `tmf_parse_backlog()` at line 268 — parses v10-shape BACKLOG.md
  into a JSON entries array. Module header line 234: "Parse a
  v10-shape BACKLOG.md and emit a JSON array of entries on stdout."
  Error path at line 271 emits `tracker_error_emit "not-found"
  "BACKLOG.md not found at $path"`.
- `tmf_parse_implementation_plan()` at line 399 — parses
  IMPLEMENTATION-PLAN.md into a phase-array JSON. Header at line
  391: "Parse IMPLEMENTATION-PLAN.md and emit a JSON array of phase
  entries". Error at line 402: "IMPLEMENTATION-PLAN.md not found at
  $path".
- `tmf_compose_issue_body()` at line 459 — composes the GH issue
  body for a parsed BACKLOG entry. Header at line 433: "Compose the
  issue body for a parsed BACKLOG entry (V1 §4.1".
- `tmf_mirror_header()` at line 498.
- `tmf_create_or_lookup()` at line 523.
- `tracker_migrate_forward_run()` at line 585. Orchestrator. Reads
  `backlog_path="$repo_root/BACKLOG.md"` at line 644 and
  `plan_path="$repo_root/IMPLEMENTATION-PLAN.md"` at line 645 (with
  fallback `[[ ! -f "$plan_path" ]] && plan_path="$repo_root/
  maintenance-docs/IMPLEMENTATION-PLAN.md"` at line 646).
- `_tmf_regen_mirror()` at line 1172 — regenerates the BACKLOG.md
  mirror in place per V1 §6.3 (mirror-header behavior referenced
  in the function block).
- `_tmf_verify_forward_complete()` at line 1452 — final completeness
  gate.

V3.x back-citations (from §1):
- V1 §4.1 (cited at tracker-migrate-forward.sh:433 as the contract
  source) is V2-preserved; V3.0 §0.5 lists V1/V2 sections preserved
  verbatim.
- V1 §6.3 (mirror-header) is referenced by tracker-mirror.sh:23 and
  is V2-preserved per V3.0 §0.5.
- V3.3-DELTA §4.1 at lines 187–192 specifies the forward parser for
  IMPLEMENTATION-PLAN.md `### Tasks`.

### `scripts/lib/tracker-migrate-reverse.sh`

Functions and stream touchpoints:
- `_tmr_decode_status` (135), `_tmr_decode_type` (205),
  `_tmr_decode_scope` (227), `_tmr_decode_severity` (234),
  `_tmr_extract_section` (245), `_tmr_decode_blockers` (276).
- `tracker_migrate_reverse_reconstruct()` at line 314 — reconstruct
  one BACKLOG entry from a normalized Issue JSON (header at line
  310).
- `_tmr_compute_unblocks()` at line 390.
- `_tmr_emit_backlog()` at line 409 — emits BACKLOG.md from a
  reconstructed entries array. Header note at lines 406–408: "Emit
  BACKLOG.md from a reconstructed entries array. Header line at top
  is `# BACKLOG`. Entries are sorted by pack_id (BD- before".
  Output at line 439: `lines = ["# BACKLOG", ""]`.
- `_tmr_emit_implementation_plan()` at line 485 — emits
  IMPLEMENTATION-PLAN.md skeleton (header note at line 483 / 501:
  `lines = ["# IMPLEMENTATION PLAN", "", "## Phases", ""]`).
- `_tmr_emit_status()` at line 514.
- `_tmr_emit_changelog()` at line 553 — emits CHANGELOG.md skeleton
  (note at lines 547–552: "Real audit-log walking … is deferred …
  CHANGELOG from tracker state in v11.0").
- `_tmr_update_tracker_toml()` at line 582.
- `tracker_migrate_reverse_run()` at line 638. Output paths at lines
  853–856: `backlog_out="$repo_root/BACKLOG.md"`,
  `plan_out="$repo_root/IMPLEMENTATION-PLAN.md"`,
  `changelog_out="$repo_root/CHANGELOG.md"`. Pre-write check list
  at line 871: `for f in BACKLOG.md IMPLEMENTATION-PLAN.md STATUS.md
  CHANGELOG.md; do`. Final write list at line 922: same four files.
  Doc line at 950: `files:      BACKLOG.md, IMPLEMENTATION-PLAN.md
  (if absent), STATUS.md, CHANGELOG.md (if absent)`.

V3.x back-citations:
- V3.1-DELTA §3 (lines 180–255) "Decision: §4.2 BACKLOG format drift
  in reverse migration — picked A2" — codifies the BACKLOG reverse-
  emission format.
- V3.3-DELTA §4.2 at lines 193–196 — reverse emitter spec.
- V3.0 §0.5 — V1/V2 preserved sections including V1 §6.5 (reverse
  migration step list).

### `scripts/lib/tracker-mirror.sh`

Functions: `tracker_mirror_header_emit` (33), `tracker_mirror_header_write`
(50), `tracker_mirror_header_strip` (85). Module header lines 1–24
documents V1 §6.3 contract: idempotent header rewrite around the
authoritative file content. No direct BACKLOG / CHANGELOG / IMPL-PLAN
literals — the mirror header functions take a generic path argument.

V3.x back-citation: V1 §6.3 / V1 §6.5 / V1 §6.7 cited at module-doc
lines 8 / 11 / 23.

### `scripts/lib/tracker-agent-read.sh`

Functions: `tracker_agent_read_mode` (57), `tracker_agent_read_entry`
(70), `_tar_read_entry_tracker` (100), `_tar_read_entry_flat` (153).
- `_tar_read_entry_flat()` at line 153 reads BACKLOG.md directly:
  `local backlog="$repo_root/BACKLOG.md"` at line 156; error at
  line 158–159: `"agent_read: BACKLOG.md not found at $backlog"`.
- Module header line 7: "flat-file mode: greps the BACKLOG.md mirror
  for the entry block".
- Stdout banner line 183: `print("Source: flat-file (BACKLOG.md)\n")`.

V3.x back-citation: V1 §8 / V1 §13 (agent-read pattern) and D-9 /
D-10 / D-11 (failure UX + typed error model) — cited in
`IMPLEMENTATION-PLAN.md` §1.7 at lines 237–281 (BD-066 / BD-069 /
BD-071).

### `scripts/lib/tracker-provider.sh`, `tracker-provider-gh.sh`, `tracker-config.sh`, `tracker-labels.sh`, `tracker-errors.sh`

`grep -n "BACKLOG\|CHANGELOG\|IMPLEMENTATION.PLAN"` against these five
files returns no hits. They are the provider abstraction layer,
config loader, label-vocabulary library, and typed-error library
respectively — none operate on stream-file text directly. They
back-cite V1 §2.1 (provider abstraction), V1 §2.5 (typed error
codes), and D-1 / D-2 / D-5 in `ARCHITECTURE-V3.md` §16 (line 152
heading; specific D-1 / D-2 row at line 152+).

---

## §9 — Out-of-scope confirmation (explicit)

- **`STATUS.md` is out of scope** (human-reference dashboard, not the
  per-entry stream this research enumerates). Live presence:
  `/Users/david/Developer/OptiquityTrader/docs/project/STATUS.md`
  exists (per `ls` of that directory). The pack repo has no
  `STATUS.md` (consistent with the pack having no
  `IMPLEMENTATION_PLAN.md` either; the pack tracks BD work in
  `BACKLOG.md` only). Reference in pack PM-CHAT source at
  `project-template/docs/pack/PM-CHAT.md:120`:
  `| \`STATUS.md\` | Direct read | Small, changes every phase, must
  always be current |`.

- **`PACK-FEEDBACK.md` is out of scope** (project-side outgoing
  staging buffer; pack-side feedback lives in GH issues per V3.x
  decision D-11 reaffirmed at `ARCHITECTURE-V3.md:171`:
  `| D-11 | 2026-04-30 | **reaffirmed in V3** | PACK-FEEDBACK
  upstream mechanism. | Unchanged. | OQ-11 | V1 §7.5 |`).
  Project-side reference at `project-template/docs/pack/PM-CHAT.md:37`:
  `- Maintain PACK-FEEDBACK.md as the running feedback log for the
  AI Agent Config Pack — observe, record, and deliver feedback
  batches at workflow boundaries (see METHODOLOGY.md Part 10)`.
  Pack-side: `PACK-CHAT.md` does not list `PACK-FEEDBACK.md` in its
  file-access strategy table at lines 42–43 (grep returns no hits
  for `PACK-FEEDBACK` in `PACK-CHAT.md`).

- **`METHODOLOGY.md` does not govern pack-self.** Anchor in pack
  trinity at `CLAUDE.md:160-162` (pack-memory rule):
  `- **Separate pack ops from pack product.** Pack ops files
  (CLAUDE.md,` — the rule continues to list pack-self governance
  files. Parallel rules at `AGENTS.md:137` and `GEMINI.md:115`
  (Trinity propagation). Pack BACKLOG line 5 does cite METHODOLOGY:
  `Format follows the standard BACKLOG item format from
  METHODOLOGY.md Part 7.` — this is a citation to the entry-shape
  spec, not a delegation of self-governance.

---

## §10 — Read-record

Files read and commands run during this research pass.

### Commands

- `git -C /Users/david/Developer/optiquity-ai-agent-config-pack rev-parse HEAD`
  → `fa817044ffaa6cc019f4cb975a4242be15060676`
- `git -C /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev rev-parse HEAD`
  → `6f9e6aa77e6ac401863f6ab2a06ad63dd02bc281`
- `git -C /Users/david/Developer/optiquity-ai-agent-config-pack describe --tags`
  → `v10`
- `wc -l` on:
  - `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/BACKLOG.md` → 3,627
  - `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CHANGELOG.md` → 733
  - `/Users/david/Developer/OptiquityTrader/docs/project/BACKLOG.md` → 1,478
  - `/Users/david/Developer/OptiquityTrader/docs/project/IMPLEMENTATION_PLAN.md` → 5,235
  - `/Users/david/Developer/OptiquityTrader/docs/project/CHANGELOG.md` → 2,579
  - `/Users/david/Developer/optiquity-ai-agent-config-pack/BACKLOG.md` → 1,618
  - `/Users/david/Developer/optiquity-ai-agent-config-pack/CHANGELOG.md` → 548
  - `ARCHITECTURE-V3.md` → 3,049
  - `ARCHITECTURE-V3.1-DELTA.md` → 276
  - `ARCHITECTURE-V3.2-DELTA.md` → 506
  - `ARCHITECTURE-V3.3-DELTA.md` → 917
  - `IMPLEMENTATION-PLAN.md` (v11-research) → 1,109
- `grep -n "^## "` / `grep -n "^### "` against each above file for
  H2 / H3 enumeration.
- `grep -n "Status: " BACKLOG.md` (both pack and OT) for lifecycle-state
  uniqueness check.
- `grep -n "Type: " BACKLOG.md` (both pack and OT) for Type-vocabulary
  uniqueness check.
- `grep -c "^\*\*BD-" BACKLOG.md` (pack) → 144 entry headers.
- `grep -c "^---$" BACKLOG.md` (pack) → 146 separators.
- `grep -n "BACKLOG\|CHANGELOG\|IMPLEMENTATION.PLAN"` against each of:
  - `scripts/migrate-v10-to-v11.sh`
  - `scripts/lib/migrator-core.sh`
  - `scripts/lib/migrator-stages.sh`
  - `scripts/lib/migrator-manifest.sh`
  - `scripts/lib/customization-preserve.sh`
  - `scripts/lib/tracker-migrate-forward.sh`
  - `scripts/lib/tracker-migrate-reverse.sh`
  - `scripts/lib/tracker-mirror.sh`
  - `scripts/lib/tracker-agent-read.sh`
  - `scripts/lib/tracker-provider.sh`
  - `scripts/lib/tracker-provider-gh.sh`
  - `scripts/lib/tracker-config.sh`
  - `scripts/lib/tracker-labels.sh`
  - `scripts/lib/tracker-errors.sh`
  - `scripts/validate-pack.py`
  - `PACK-CHAT.md`, `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`
  - `.claude/skills/pack-startup/SKILL.md`, `.codex/skills/pack-startup/SKILL.md`
  - `.claude/agents/pack-{architect,planner,coder,reviewer}.md`
  - `project-template/skills/pm-startup/SKILL.md`,
    `project-template/.codex/skills/pm-startup/SKILL.md`
  - `project-template/.claude/agents/{repo-ops,coder,auditor,auditor-docs}.md`
  - `project-template/docs/pack/PM-CHAT.md`

### Files read (Read tool, with line ranges)

- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/BACKLOG.md`
  — lines 1–35; 1443–1477.
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CHANGELOG.md`
  — lines 1–80.
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/migrate-v10-to-v11.sh`
  — lines 60–219 (manifest, hooks, BD-104 rename body).
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/migrator-core.sh`
  — lines 1–34 (header/contract); 130–230 (required vars + hooks + stage
  sequencer).
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/migrator-stages.sh`
  — lines 1–80 (header + stage list).
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/customization-preserve.sh`
  — lines 30–250 (header + classifier + dispositions); 470–558 (strategy
  dispatcher).
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/validate-pack.py`
  — lines 262–287 (Check 3).
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/tracker-mirror.sh`
  — lines 1–30 (header / public API).
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.claude/skills/pack-startup/SKILL.md`
  — lines 1–40.
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-research/ARCHITECTURE-V3.3-DELTA.md`
  — lines 185–284 (§4 + §5.3).
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-research/IMPLEMENTATION-PLAN.md`
  — lines 85–145 (§1.2); 599–660 (§2.2).
- `/Users/david/Developer/OptiquityTrader/docs/project/BACKLOG.md`
  — lines 1–60; 485–510.
- `/Users/david/Developer/OptiquityTrader/docs/project/IMPLEMENTATION_PLAN.md`
  — lines 1–80.
- `/Users/david/Developer/OptiquityTrader/docs/project/CHANGELOG.md`
  — lines 1–80.

### Files listed (Bash ls / find)

- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-research/`
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/`
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/`
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/migrate-v10-to-v11/`
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.claude/skills/`
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.gemini/`
  (recursive find for files; confirmed `.gemini/commands/pack-startup.toml`
  exists; no `.gemini/skills/pack-startup/` dir)
- `/Users/david/Developer/optiquity-ai-agent-config-pack/` (v10.1 root)
- `/Users/david/Developer/optiquity-ai-agent-config-pack/scripts/lib/`
  (only `detect.sh` + `three-way.sh`)
- `/Users/david/Developer/OptiquityTrader/` (root) and
  `/Users/david/Developer/OptiquityTrader/docs/project/`.

---

RESEARCH-PER-ENTRY-SPLIT-COMPLETE: 2026-05-13 — Enumerated v11 authoritative entry-shape sections, pack-side (BD) and project-side (TD) live entry structure, the v10→v11 migrator surface, customization-preserve classification (BACKLOG/CHANGELOG/IMPLEMENTATION-PLAN unclassified → generic), validate-pack Check 3 (the only entry-file check), and tracker-mode forward/reverse touchpoints — with file:line citations against the v11-dev tree, v10.1 source at SHA fa817044, and OT live project; no proposals, no analysis, fact-finding only.
