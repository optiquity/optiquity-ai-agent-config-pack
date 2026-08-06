---
title: ARCHITECTURE-PER-ENTRY-SPLIT
status: design-only
parent: RESEARCH-PER-ENTRY-SPLIT.md (+ ADDENDUM)
authoritative-design: ARCHITECTURE-V3.md + V3.1/V3.2/V3.3-DELTA.md + IMPLEMENTATION-PLAN.md (v11-research)
audience: v11-implementation chat (reviewer, then planner)
out-of-scope: STATUS.md, PACK-FEEDBACK.md, ARCHITECTURE.md (superseded), maintenance-docs/archive/v11/*, METHODOLOGY.md as pack-self governance
date: 2026-05-13
---

# Per-entry split — architecture

## §0 — TL;DR

**Problem.** Three monolithic project-management documents — pack-side
`BACKLOG.md` (3,627 lines / 144 BD entries), pack-side `CHANGELOG.md`
(733 lines / 11 version blocks / 3 v11.0 scope buckets), and project-side
`BACKLOG.md` / `IMPLEMENTATION_PLAN.md` / `CHANGELOG.md` (the OT v10.x
shapes: 1,478 / 5,235 / 2,579 lines, phase-organized) — are read,
written, parsed, and emitted as single units across every workflow
surface (`RESEARCH-PER-ENTRY-SPLIT.md` §6; `ADDENDUM` §6). This design
decomposes those streams into per-entry files plus, per stream
directory, an immutable `_rules.md` contract and a mutable `_toc.md`
index, while preserving the v10 entry grammar byte-for-byte (per
V3.1-DELTA §3 A2 decision, lines 180–255).

**Shape.** One file per BD entry (pack-side `backlog/`); one file per
TD entry (project-side `backlog/`); one file per CHANGELOG version
block (both sides); one file per IMPLEMENTATION-PLAN decomposition
unit, asymmetric pack/project (pack-side: per-§-section unit;
project-side: per-phase + per-phase-task unit, composing onto
V3.3-DELTA §6.4 identifier scheme at lines 360–370). Existing files
remain on disk as **generated mirrors** (analogous to the tracker
mirror per V1 §6.3, referenced from `scripts/lib/tracker-mirror.sh`
module header lines 1–24); per-entry files are the source of truth,
read paths stay (almost) unchanged because the mirror is always
current. This is the central design decision and is defended in §6.

**Scope boundary.** Five stream directories total:
- pack-side `backlog/`
- pack-side `changelog/`
- project-side `backlog/`
- project-side `implementation-plan/`
- project-side `changelog/`

STATUS.md and PACK-FEEDBACK.md are out of scope, confirmed against
`RESEARCH-PER-ENTRY-SPLIT.md` §9 (lines 902–937) and the architect
prompt's locked decisions. `IMPLEMENTATION-PLAN` decomposition does
not exist on the pack side because the pack repo has no
`IMPLEMENTATION-PLAN.md` at root — V3 §28.1 line 603 confirms ("the
pack repo has no `IMPLEMENTATION_PLAN.md`"); the pack-side
`maintenance-docs/v11-research/IMPLEMENTATION-PLAN.md` is the
*planning corpus* for v11, not a project-management stream file.
That document remains a single-file workflow artifact and is not
decomposed by this design.

**Version target.** Placeholder — the v11-implementation chat's
planner picks the version. This design is sequencing-agnostic with
respect to `EXECUTION-PLAN-V11.0.md` Batches 7–10 (BD-131..BD-134
tracker repairs) and Batch 12 (BD-104 rename); sequencing
constraints flagged in §15.

**Single non-negotiable invariant.** The v10 BACKLOG entry grammar is
the authoritative entry shape (V3.1-DELTA §3 A2, lines 180–255). Per-entry
decomposition is byte-additive on entry format. The bold-header line
(`**BD-NNN — Title**` / `**TD-NNN — Title**`), the field labels
(`Type:` / `Status:` / `Blockers:` / `Unblocks:` / `File/Symbol:` /
`Description:` / `Resolved:` pack-side; same plus `Context:` /
`Resolution:` project-side per `RESEARCH-PER-ENTRY-SPLIT.md` §4), and
the `---` separator are preserved verbatim inside each per-entry file.
The cross-reference syntax (BD-NNN textual, commit hash, backtick file
path, file:line reference) is preserved verbatim per
`RESEARCH-PER-ENTRY-SPLIT.md` §2.

---

## §1 — Cited reading + authority map

### V3.x authority by surface

| Surface | Authority | Citation |
|---|---|---|
| Entry grammar (BD-NNN, TD-NNN field labels) | V3.1-DELTA §3 (A2 decision) | `ARCHITECTURE-V3.1-DELTA.md:180-255` |
| Identifier scheme (BD/TD/phase-N/phase-N.M) | V3.3-DELTA §6.4 | `ARCHITECTURE-V3.3-DELTA.md:360-370` |
| State / status mapping per entity type | V3.3-DELTA §6.3 | `ARCHITECTURE-V3.3-DELTA.md:341-360` |
| TD-NNN promotion paths (direct-close, Path 1, Path 2) | V3.3-DELTA §3 | `ARCHITECTURE-V3.3-DELTA.md:101-184` |
| Cross-entity dependencies (Blockers field grammar) | V3.3-DELTA §5.3 | `ARCHITECTURE-V3.3-DELTA.md:256-279` |
| Forward parser `### Tasks` (project IMPL-PLAN) | V3.3-DELTA §4.1 | `ARCHITECTURE-V3.3-DELTA.md:187-192` |
| Reverse emitter (BACKLOG / IMPL-PLAN / CHANGELOG / STATUS) | V3.3-DELTA §4.2 + V3.1-DELTA §3 (A2) | `ARCHITECTURE-V3.3-DELTA.md:193-196` + `V3.1-DELTA:180-255` |
| Sidecar — `template_version` + `extra_fields` round-trip | V3.1-DELTA §3 (V1 §6.6.1 extension) | `ARCHITECTURE-V3.1-DELTA.md:194-252` |
| Mirror contract (tracker mode regenerates flat file in place) | V1 §6.3 (V2-preserved per V3 §0.5) | `scripts/lib/tracker-mirror.sh:1-24` cites V1 §6.3 |
| Inflection-point signals — backlog_kb, bd_count_active, growth_30d | V3 §28.1 | `ARCHITECTURE-V3.md:566-1032` |
| Pack-repo has no `IMPLEMENTATION_PLAN.md` | V3 §28.1 | `ARCHITECTURE-V3.md:603` |
| Pack-side BD-NNN at L1 — V1 §5 line 859 supersession | V3.3-DELTA §2.6 | `ARCHITECTURE-V3.3-DELTA.md:91-100` |
| Customization-preserve contract (BD-088) | V3-research IMPL-PLAN §2.5 | `maintenance-docs/v11-research/IMPLEMENTATION-PLAN.md:738-785` |
| Recommendation-state schema | V3 §28.1.4 (referenced from §28.1) | `ARCHITECTURE-V3.md` D-19 row at line 179 |

### Research authority by surface

| Surface | Authority |
|---|---|
| Pack-side `BACKLOG.md` H2 layout + 144 entries | `RESEARCH-PER-ENTRY-SPLIT.md` §2 lines 158–214 |
| Pack-side `CHANGELOG.md` H2 layout + scope buckets | `RESEARCH-PER-ENTRY-SPLIT.md` §2 lines 215–254 + `ADDENDUM` §9 lines 306–343 |
| Project-side OT `BACKLOG.md` phase partition + TD entries | `RESEARCH-PER-ENTRY-SPLIT.md` §3 lines 258–346 + `ADDENDUM` §3 lines 52–124 |
| Project-side OT `IMPLEMENTATION_PLAN.md` phase + tasks | `RESEARCH-PER-ENTRY-SPLIT.md` §3 lines 348–401 + `ADDENDUM` §3 lines 85–112 |
| Project-side OT `CHANGELOG.md` Format Rules + entries | `RESEARCH-PER-ENTRY-SPLIT.md` §3 lines 403–450 |
| Pack vs project entry-shape table | `RESEARCH-PER-ENTRY-SPLIT.md` §4 lines 454–463 |
| Migrator manifest (no entry-file rows) | `RESEARCH-PER-ENTRY-SPLIT.md` §5 lines 486–519 |
| `customization-preserve.sh` classes (none for streams) | `RESEARCH-PER-ENTRY-SPLIT.md` §5 lines 556–585 |
| BD-119 hook contract (5 required + 2 optional) | `RESEARCH-PER-ENTRY-SPLIT.md` §5 lines 587–606 |
| BD-104 rename position (Batch 12) | `ADDENDUM` §4 lines 128–148 |
| Read-shape change surface (10+ sites) | `RESEARCH-PER-ENTRY-SPLIT.md` §6 lines 627–749 + `ADDENDUM` §6 lines 186–256 |
| `validate-pack.py` Check 3 = TD-TBD sentinels | `RESEARCH-PER-ENTRY-SPLIT.md` §7 lines 753–779 |
| Tracker forward/reverse function-by-shape | `RESEARCH-PER-ENTRY-SPLIT.md` §8 lines 785–897 + `ADDENDUM` §7 lines 262–288 |
| Pack `## Resolved — v8` is the only Resolved H2 | `ADDENDUM` §8 lines 292–301 |
| Maintainability signals 4 / 5 / 6 / 8 verbatim | `ADDENDUM` §5 lines 152–182 |
| OT STATUS.md is dashboard-shaped (out of scope) | `ADDENDUM` §12 lines 439–488 |

---

## §2 — Locked decisions + scope boundary

### Locked from the architect brief (restated for the planner)

1. **Per-entry files are the chosen shape.** One file per BD entry,
   one file per TD entry, one file per CHANGELOG version block, one
   file per IMPLEMENTATION-PLAN decomposition unit (unit choice
   below).
2. **`_rules.md` per stream directory is immutable.** Changes only
   on pack version bump via the existing overwrite-from-template
   mechanism. No `pack rules-sync` verb.
3. **`_toc.md` per stream directory is mutable.** Index regenerated
   automatically; never source of truth.
4. **Five stream directories total.** Pack-side `backlog/` + `changelog/`;
   project-side `backlog/` + `implementation-plan/` + `changelog/`.
5. **STATUS.md + PACK-FEEDBACK.md out of scope.**
6. **Pack/project boundary is absolute.** Pack self-governance lives
   in pack-root CLAUDE / AGENTS / GEMINI / PACK-CHAT / PACK-AGENTS;
   project governance lives in METHODOLOGY.md + project-template
   trinity. Never blended. `RESEARCH-PER-ENTRY-SPLIT.md` §9 lines
   928–937 cite the relevant pack-memory rule.
7. **Entry format is byte-additive only.** Per V3.1-DELTA §3 A2
   (lines 180–255), the v10 grammar is authoritative.
8. **`IMPLEMENTATION_PLAN.md` → `IMPLEMENTATION-PLAN.md` rename is
   owned by BD-104.** This design cites both names where they
   already appear; does not propose how/when the rename happens. Per
   `ADDENDUM` §4 lines 128–148, BD-104 lives at Batch 12 of
   `EXECUTION-PLAN-V11.0.md`.

### Scope boundary — what this design does NOT do

- Does not change the field labels (`Type:` / `Status:` / `Blockers:` /
  `Unblocks:` / `File/Symbol:` / `Description:` / `Resolved:` /
  `Context:` / `Resolution:`). The field-name asymmetry between pack
  (`Resolved:`) and project (`Resolution:` plus inline
  `✅ RESOLVED (Phase NN)` annotation per `RESEARCH-PER-ENTRY-SPLIT.md`
  §4 line 460) persists — this is an architect-overreach signal per
  the brief; harmonization is out of scope and governed by V3.3-DELTA
  §6.3 state-machine asymmetry (the project side has only
  Open/Resolved; the pack side has the full 5-state vocabulary).
- Does not redesign the state vocabulary. Pack-side states
  (Open / Resolved / Deferred / Cancelled / Deprecated per
  `RESEARCH-PER-ENTRY-SPLIT.md` §2 lines 205–209) and project-side
  states (Open / Resolved per §3 line 339) remain as-is.
- Does not add a new BD-119 framework hook (per architect prompt
  guard rail 5).
- Does not extend the `customization-preserve.sh` 12-class
  classification with new named classes for the streams; the
  decomposed per-entry tree continues to fall through to the
  `generic` dispatch (`RESEARCH-PER-ENTRY-SPLIT.md` §5 lines 568–578).
  This is defended in §9.
- Does not change `validate-pack.py` Check 3 contract — Check 3 still
  operates on the (now-regenerated) `BACKLOG.md` mirror per the
  same regex (`^\*\*TD-TBD\s*—`, line 276 of `validate-pack.py` per
  `RESEARCH-PER-ENTRY-SPLIT.md` §7 lines 753–779). Defended in §13.
- Does not propose edits to PM-only / primary-chat-owned files
  (BACKLOG.md, CHANGELOG.md, README.md version table, PACK-CHAT.md,
  PACK-AGENTS.md, pack-root and project-template CLAUDE / AGENTS /
  GEMINI, `EXECUTION-PLAN-V11.0.md`, any `PLAN-*.md` in
  `maintenance-docs/v11-implementation/`, and the v11-research
  authoritative corpus).
- Does not propose specific edits to pack-product script / skill /
  agent files; those edits belong to the planner / coder passes the
  v11-implementation chat owns. The design names integration points
  (§14) without writing the new content.

### Conflict flag (single, surfaced not resolved)

The pack-memory rule "BACKLOG.md has no Resolved section" (pack-root
`CLAUDE.md:157-159`) and the live `## Resolved — v8 (March 2026)` H2 at
pack `BACKLOG.md:2248` (the only such H2 in the file per `ADDENDUM`
§8 line 297) co-exist today. Per-entry decomposition makes this
conflict largely vacuous: in the decomposed shape, "Resolved" is a
`Status:` field on each per-entry file, not an H2 section, so the
rule reads trivially-true in the per-entry world. The H2 in the
generated mirror is a faithful echo of the legacy v8 section and
remains under PM Chat's control (it is rendered into the mirror by
the regenerator from a frozen-historical block — see §6 mirror
generation rules). This design does not propose an edit to the rule
or to the legacy v8 H2; it flags both as PM-owned. The
v11-implementation chat may consult §12 for the worked statement of
the rule under decomposition.

---

## §3 — Per-entry directory shape (one section per stream)

### §3.0 — Common shape (all five streams)

Each stream lives at a single directory containing:

1. `_rules.md` — immutable contract for the directory (see §4).
2. `_toc.md` — mutable index of current entries (see §5).
3. One file per entry, with a stream-specific naming convention
   (per-stream subsections below).

The leading underscore on `_rules.md` and `_toc.md` is deliberate:
it sorts them to the top of a directory listing under standard
lexical ordering, separates them visually from per-entry files, and
makes them trivially greppable as "this is not an entry; this is a
control file." The leading-underscore convention does not collide
with the v10 entry grammar (no entry filename can start with `_`
because entry filenames carry an ID prefix like `BD-` / `TD-` /
`v11.0` / `phase-N` / `phase-N.M`).

### §3.1 — Pack-side `backlog/`

**Location.** `/.backlog/` at pack root. The `.backlog` name parallels
`.pack-tracker/` (per V3.3-DELTA §6.3 references the `.pack-tracker/`
state directory; per `ARCHITECTURE-V3.md` §28.1.4 the
`recommendation-state.json` lives there). Both names start with `.`
because the directory is structured pack state, not pack product.
This places per-entry storage at pack-root — distinct from
`maintenance-docs/` (which holds maintainer docs and design records)
and from `supporting-docs/` (which holds pack product copied or
consumed by projects). The decision is defended in §11.

**Per-entry filename convention.** `BD-NNN.md` (e.g. `BD-156.md`).
Three-digit zero-padded number per the existing BD-NNN identifier
convention (V3.3-DELTA §6.4 line 365; observable in pack BACKLOG
sample at `BACKLOG.md:1443`). No title in the filename — title lives
inside the file as the bold-header line. Rationale: filename
stability under title edits (titles get refined; numbers do not),
filename uniqueness heuristic per pack memory (`feedback_filename_uniqueness`),
and trivial `BD-NNN` → filename mapping for any tool, agent prompt,
commit message, or cross-reference.

**Per-entry contents.** A single per-entry file contains exactly one
v10-grammar entry. The bold-header line is the H1-equivalent (it is
not an H1 — it is the v10 bold header per V3.1-DELTA §3 A2), then
the field labels (`Type:`, `Status:`, etc.), then the `Description:`
body, then `Resolved:` if Status=Resolved. No `---` separator at the
top or bottom of the file — the file boundary is the separator. This
is byte-additive on entry format: the file content from `**BD-NNN —`
through the last narrative line of the entry is byte-identical to
the corresponding span in the legacy monolithic `BACKLOG.md`.

**Partitioning.** No subdirectories — flat `BD-NNN.md` files
directly under `/.backlog/`. The pack BACKLOG today partitions by
version-and-activity (`## Active — v11 Scope`, `## Active — v10 Scope`,
`## Resolved — v8 (March 2026)`, `## Deferred` per
`RESEARCH-PER-ENTRY-SPLIT.md` §2 lines 162–167); under per-entry
decomposition this partition becomes a function of `Status:` and an
implicit `Version:` field-equivalent that the `_toc.md` and the
regenerated mirror can sort on. The `Version:` axis is not a new
required field — it is derivable from the `Resolved:` line (commit
hash + date + version prose in pack convention) or from the
`Blockers:` line (which carries the deferred target-version per
`BACKLOG.md:17` "Items deferred to a future version: set Blockers to
the target version"). No schema change.

### §3.2 — Pack-side `changelog/`

**Location.** `/.changelog/` at pack root, parallel to `/.backlog/`.

**Per-entry filename convention.** `vN.M.md` (e.g. `v11.0.md`,
`v10.0.md`, `v9.3.md`). The unit is the version block, not the
scope-bucket. Rationale: the H2/H3 layout in pack `CHANGELOG.md`
(per `RESEARCH-PER-ENTRY-SPLIT.md` §2 lines 222–254) treats the H2
version heading as the entry boundary; scope buckets
(`**Scope A — …**`, `**Scope B — …**`, `**Scope C — …**` per
`ADDENDUM` §9 lines 309–313) are an *intra-entry* organization
device inside `v11.0` only. Across all 11 version blocks (v1..v11)
only v11 has scope buckets per `ADDENDUM` §9 lines 327–342 — so the
scope-bucket level is not a universal decomposition unit and would
introduce a one-version-only file pattern. The version block is the
universal unit.

**Per-entry contents.** A single file contains exactly one version
block — the H2 heading (`## v11 — May 2026`), the H3 sub-headings
(`### v11.0 — …`), the scope-bucket bold lines (`**Scope A — …**`),
and the bullet-list body — byte-identical to the corresponding span
in the legacy monolithic `CHANGELOG.md`. The mirror regenerator
emits these in date-descending order (latest first), preserving the
existing CHANGELOG convention.

**Partitioning.** Flat `vN.M.md` files directly under
`/.changelog/`. The major-version grouping (the `## v11 — May 2026`
H2 that encompasses multiple `### v11.0` / `### v11.1` H3s in the
current file) emerges from the filename — `v11.0.md`, `v11.1.md`,
`v11.0-post-release.md` (for the existing v10.0-post-release-patches
pattern at `CHANGELOG.md:271`) — all sort together lexically. The
mirror generator groups them under the existing `## vN — <date>` H2
at emit time. The author of a CHANGELOG entry writes a single
`vN.M.md` file; the mirror generator handles the H2 grouping.

### §3.3 — Project-side `backlog/`

**Location.** `docs/project/backlog/` in the project tree. This is
the same `docs/project/` directory that today holds the monolithic
`BACKLOG.md` / `IMPLEMENTATION_PLAN.md` / `CHANGELOG.md` per
`RESEARCH-PER-ENTRY-SPLIT.md` §3 lines 263–267. The decomposed
directory sits beside the (now-generated-mirror) monolithic file.

**Per-entry filename convention.** `TD-NNN.md`. Three-digit
zero-padded per the existing TD-NNN identifier convention
(V3.3-DELTA §6.4 line 364; observable in OT BACKLOG sample at
`<target-project>/docs/project/BACKLOG.md:13`).

**Per-entry contents.** Single v10-grammar TD entry per file. The
project-specific fields persist verbatim: `Type:` is open-vocabulary
(`KNOWN GAP(...)`, `TODO(...)`, `VERIFY(...)` per
`RESEARCH-PER-ENTRY-SPLIT.md` §3 lines 340–346); `Context:` is
project-only (line 460 of §4); `Resolution:` replaces the pack-side
`Resolved:` (line 460 of §4); the inline
`✅ RESOLVED (Phase NN)` annotation on the bold-header line for
Resolved entries persists. None of these change.

**Partitioning.** Flat `TD-NNN.md` files. The project-side phase
partition observable today (each `## Phase NN — <title>` H2 in OT
`BACKLOG.md` contains a `### Technical Debt` H3 then TD entries, per
`RESEARCH-PER-ENTRY-SPLIT.md` §3 lines 279–294) becomes implicit
in the TD entry's `Resolution:` line (which names the phase that
fixed it) and in cross-references to `phase-N` / `phase-N.M`
identifiers per V3.3-DELTA §5.3 lines 256–279. The mirror
regenerator reconstructs the phase-grouped H2 layout from
per-entry `Resolution:` / `Blockers:` fields at emit time. No new
required field.

### §3.4 — Project-side `implementation-plan/`

**Location.** `docs/project/implementation-plan/` in the project
tree. Parallel to `backlog/`.

**Per-entry filename convention — asymmetric per the brief's guard
rail 7.** Pack/project decomposition asymmetry applies here. This
design resolves Open Question 1 with option (c) per the brief's
guard rail 7 framing — but composed onto two different surface
shapes:

- **Pack side: no decomposition.** The pack repo has no
  `IMPLEMENTATION-PLAN.md` at root per V3 §28.1 line 603. The
  pack-side `maintenance-docs/v11-research/IMPLEMENTATION-PLAN.md`
  is the v11 planning corpus — a single-file workflow artifact owned
  by the planner pass — and is NOT decomposed by this design. The
  pack `/.implementation-plan/` directory does **not** exist. This
  resolves Open Question 1 by restricting IMPLEMENTATION-PLAN
  decomposition to project-side only (brief's option (b) for this
  one stream; the pack-side `BACKLOG.md` and `CHANGELOG.md` still
  decompose per §3.1 and §3.2).

  Rationale: per `ADDENDUM` §10 lines 346–384, the pack-side
  `maintenance-docs/v11-research/IMPLEMENTATION-PLAN.md` is
  `## §`-section organized (8 H2 sections, 34 `**BD-NNN**`
  entries) and is a v11-planning-corpus document, not a
  project-management stream file. It is not read in flat-file or
  tracker mode by any user-facing workflow path
  (`tracker-migrate-forward.sh:644-646` looks at
  `$repo_root/IMPLEMENTATION-PLAN.md` and falls back to
  `$repo_root/maintenance-docs/IMPLEMENTATION-PLAN.md` — neither
  resolves to the `v11-research/` path); per
  `RESEARCH-PER-ENTRY-SPLIT.md` §5 lines 488–500 it is not in the
  v10→v11 migrator manifest. It will sweep to `maintenance-docs/
  archive/v11/` at v11 ship per the Pattern B convention (pack
  memory `CLAUDE.md:174-183`), so decomposing it would create
  churn for a file that is about to archive. Out of scope.

- **Project side: decomposition unit = phase epic + phase task.**
  One file per `phase-N` (e.g. `phase-0.md`) for the phase epic;
  one file per `phase-N.M` (e.g. `phase-0.1.md`) for each phase task.
  This composes onto V3.3-DELTA §6.4's identifier scheme (lines
  360–370) — `phase-N` and `phase-N.M` are first-class entity
  identifiers carrying their own `<!-- pack-id: phase-N -->` body
  markers per V1 §6.2.

**Per-entry contents — phase epic (`phase-N.md`).** Contains the
H2 phase heading (`## Phase 0 — <title>`), `**Goal**:`,
`**Prerequisite**:`, the `---` separator, then `### Verification`,
`### Agent`, `### Risks` H3 sections (per
`RESEARCH-PER-ENTRY-SPLIT.md` §3 lines 372–401). The `### Tasks`
H3 from the legacy file becomes an *index* in the phase epic body
(a bullet list of `phase-N.M` IDs with titles); the task content
lives in the per-task files.

**Per-entry contents — phase task (`phase-N.M.md`).** Contains the
`#### N.M — <title>` H4 heading, then the bullet body — `- **What**:`,
`- **Dependencies**:`, and other content fields. Byte-additive on
V3.3-DELTA §4.1's forward parser contract (lines 187–192): the
forward parser today consumes `#### N.M — <title>` headings inside
an `IMPLEMENTATION-PLAN.md` `### Tasks` section. Under per-entry
decomposition, the mirror regenerator emits the same shape — the
parser does not change. See §6 for the parser's read path.

**Partitioning.** Flat files under `implementation-plan/`. The H2
phase ordering observable today (`## Phase 0` through `## Phase 28+`)
emerges from the filename — `phase-0.md`, `phase-0.1.md`,
`phase-1.md`, `phase-1.1.md`, ... — and the mirror generator emits
them in numerical-phase order. Phase tasks are co-located with their
phase epic in the same directory (no per-phase subdirectories),
which keeps the directory listing greppable and matches the flat
shape of pack-side `backlog/` and `changelog/`.

### §3.5 — Project-side `changelog/`

**Location.** `docs/project/changelog/` in the project tree.

**Per-entry filename convention.** `YYYY-MM-DD-phase-NN.md` (e.g.
`2026-04-20-phase-35.md`). Date-first for lexical sorting; phase
suffix for human readability. Per
`RESEARCH-PER-ENTRY-SPLIT.md` §3 lines 422–448, project CHANGELOG
entries are dated phase-completion records of the form
`### YYYY-MM-DD — Phase N — <title>`; the filename mirrors the
heading. Where an entry is not phase-tied (e.g. "Architecture
Iteration" labels per `RESEARCH-PER-ENTRY-SPLIT.md` §3 line 417),
the filename is `YYYY-MM-DD-<slug>.md`.

**Per-entry contents.** Single v10-grammar CHANGELOG entry per
file. The Format Rules H2 (project `CHANGELOG.md:7` per
`RESEARCH-PER-ENTRY-SPLIT.md` §3 lines 408–421) is preserved as a
non-entry file: `docs/project/changelog/_format.md` — alongside
`_rules.md` and `_toc.md` — because Format Rules is project-side
content not pack-side and lives only in project CHANGELOG (no
pack analog). Rationale for adding a third leading-underscore file
in this one stream only: Format Rules is observed in OT but is a
project-side convention from before v11, not part of the
`_rules.md` contract; preserving it as `_format.md` keeps it
visible to project users without conflating it with the pack
contract. Defended in §11 as a project-side asymmetry.

**Partitioning.** Flat `YYYY-MM-DD-*.md` files. Date-descending
ordering in the mirror is straightforward from the filename;
append-only-historical semantics persist.

---

## §4 — `_rules.md` contents + immutability mechanism

### §4.1 — What `_rules.md` contains (per stream directory)

`_rules.md` is the **per-directory contract**. Every stream
directory's `_rules.md` declares exactly five things:

1. **Stream identity.** The stream name (e.g. "pack-backlog",
   "project-implementation-plan") and the pack version that minted
   this `_rules.md` shape.
2. **Filename convention.** The regex or glob pattern admitted in
   the directory (e.g. `^BD-\d+\.md$` for pack-backlog;
   `^(phase-\d+|phase-\d+\.\d+)\.md$` for project-implementation-plan).
3. **Entry contract.** Pointer to the v10 grammar authority for
   each stream — for `backlog/`, V3.1-DELTA §3 A2 (`ARCHITECTURE-V3.1-DELTA.md:180-255`);
   for `implementation-plan/`, V3.3-DELTA §4.1 (`ARCHITECTURE-V3.3-DELTA.md:187-192`);
   for `changelog/`, the existing Format Rules block in OT
   `CHANGELOG.md:7-39` (project-side) and the existing pack
   `CHANGELOG.md` conventions (pack-side). `_rules.md` does not
   restate the grammar — it points.
4. **Lifecycle states admitted.** Pack-backlog: `Open`, `Resolved`,
   `Deferred`, `Cancelled`, `Deprecated` (per
   `RESEARCH-PER-ENTRY-SPLIT.md` §2 lines 205–209). Project-backlog:
   `Open`, `Resolved` (per §3 line 339). Project-implementation-plan:
   the V3.3-DELTA §6.3 phase-state vocabulary at lines 351–356
   (pending / in-progress / done / deferred / merged-into / superseded-by,
   marked in the heading per `🚧` / `✅` / `➡`). Changelog streams
   have no lifecycle (append-only-historical per
   `RESEARCH-PER-ENTRY-SPLIT.md` §3 line 449).
5. **PM/Pack-Chat write-authority pointer.** A pointer to the
   authority that controls writes (pack-side: PACK-CHAT.md /
   PACK-AGENTS.md; project-side: PM-CHAT.md and METHODOLOGY.md Part
   7 for BACKLOG, Part 4 for IMPLEMENTATION-PLAN). `_rules.md` does
   not restate write-authority rules — it points.

`_rules.md` is **short by design** — pointer-heavy, not
content-heavy. Target length per file is roughly 30–60 lines. It
exists so that an agent reading the directory cold (no prior
context, no other files loaded) can resolve the directory's
contract in one Read call. Anything that needs more than a pointer
lives in the v11-research authoritative corpus or in
PACK-CHAT.md / PM-CHAT.md / METHODOLOGY.md — the existing homes.

### §4.2 — Immutability mechanism

`_rules.md` is immutable from the perspective of Pack Chat / PM
Chat / pack agents. Changes happen only at pack version bump via
the existing overwrite-from-template mechanism:

- **Pack-side `/.backlog/_rules.md` and `/.changelog/_rules.md`.**
  The pack-self versions of these files ship in the pack repo and
  evolve with the pack. They are not under Pack Chat write
  authority — they are PM-only per the same rules that govern
  CLAUDE / AGENTS / GEMINI (pack-root). The architect prompt's
  "files agents must not modify without explicit instruction"
  list (pack `CLAUDE.md:82-86`) implicitly covers them under the
  pack-ops-vs-pack-product separation rule.

- **Project-side `docs/project/backlog/_rules.md` /
  `implementation-plan/_rules.md` / `changelog/_rules.md`.** These
  are pack product — they ship from `project-template/` into each
  client project. The pack repo stores the canonical versions at
  `project-template/docs/project/backlog/_rules.md` (and so on for
  the other two streams); `init-project.sh` copies them on project
  init; `migrate-vN-to-vM.sh` overwrites them on every minor
  version bump that touches them. The customization-preservation
  classifier (`scripts/lib/customization-preserve.sh`
  `customization_classify()` at lines 145–179 per
  `RESEARCH-PER-ENTRY-SPLIT.md` §5) routes them through the
  existing `generic` class. Because `_rules.md` is designed to be
  pointer-only and short, the user-customization probability is
  low; the truthful-report mechanism (BD-088) will surface any
  divergence. See §9.

- **The "no `pack rules-sync` verb" decision.** The architect brief
  locks this out. The overwrite-from-template mechanism is the
  enforcement: a user who edits `_rules.md` will see their edit
  marked `merged-with-customization` or
  `customization-detected-needs-reconciliation` in the BD-088
  truthful migration report at the next pack version bump, and can
  decide per the existing pack-update process. No new verb
  required.

### §4.3 — Trinity considerations for `_rules.md`

`_rules.md` is a single file per stream directory. It is **not**
trinity-replicated across Claude / Codex / Gemini, because the
streams themselves are not per-CLI artifacts — they are pack/project
data files that all three CLIs read identically via their
tool-native context file (CLAUDE.md / AGENTS.md / GEMINI.md). The
trinity rule applies to the *governance file that references the
stream* (CLAUDE / AGENTS / GEMINI / PACK-CHAT / PM-CHAT mirrors),
not to the stream `_rules.md` itself. This is the same convention
the existing BACKLOG.md / CHANGELOG.md observe today (one file per
stream, not three).

---

## §5 — `_toc.md` shape + generation contract

### §5.1 — What `_toc.md` contains

`_toc.md` is the **per-directory index**. It is regenerated by a
generator (see §5.2) and is never source of truth. It contains:

1. A single H1 / H2 heading (`# Table of contents — <stream name>`).
2. A grouped list of entries, organized by primary axis per stream:
   - Pack-backlog: by `Status:` value (`## Open`, `## Resolved`,
     `## Deferred`, `## Cancelled`, `## Deprecated`), entries listed
     `- BD-NNN — <title>` with file-path link.
   - Pack-changelog: by major version (`## v11`, `## v10`, …),
     entries listed `- vN.M — <date> — <one-line summary>` with
     file-path link.
   - Project-backlog: by `Status:` value (`## Open`, `## Resolved`),
     entries listed `- TD-NNN — <title>` with file-path link;
     within each Status bucket sub-grouped by primary phase
     reference (derived from the entry's `Resolution:` or
     `Blockers:` phase token per V3.3-DELTA §5.3 lines 256–279).
   - Project-implementation-plan: by phase number (`## Phase 0`,
     `## Phase 1`, …); each phase block lists the phase-epic file
     and its phase-task children in `phase-N.M` order with the
     V3.3-DELTA §6.3 marker (`🚧`, `✅`, `➡`).
   - Project-changelog: by year-month, descending; entries listed
     `- YYYY-MM-DD — Phase N — <title>` with file-path link.
3. A trailer line stamping the regeneration time and the generator
   version, so agents reading `_toc.md` know whether the index is
   current relative to the directory contents.

`_toc.md` is mutable in the sense that it is regenerated, not in
the sense that humans hand-edit it. Hand edits to `_toc.md` are
overwritten on the next regeneration.

### §5.2 — Generation contract

A `_toc.md` regenerator is run after every per-entry-file write
(by Pack Chat or PM Chat or the migrator) and emits the index
deterministically from the current state of the per-entry files.
This design names the regenerator as a **library helper** (it
belongs in `scripts/lib/`, per the architect prompt's reading of
the pack-script vs pack-lib distinction in maintainability signal
6 at `ADDENDUM` §5 line 170 — "helpers in `scripts/lib/` are not
new scripts; they are library extensions"). Naming the specific
function name, its CLI entry point, or its file path is the
planner's job; this design only names the contract:

- **Input:** the directory path of a stream (e.g.
  `/.backlog/` or `docs/project/implementation-plan/`).
- **Output:** the `_toc.md` file at that directory, overwritten in
  place.
- **Idempotency:** running the regenerator twice without
  intervening edits produces a byte-identical `_toc.md`.
- **Determinism:** entries are sorted by stable keys (ID for
  BD/TD; version+date for changelog; phase number for
  implementation-plan). No timestamp-based reordering.

The regenerator is **also** invoked by the mirror generator (§6),
so the `_toc.md` and the regenerated monolithic mirror are always
in sync — both derived from the same per-entry source. The mirror
generator and the `_toc.md` regenerator share parsing logic
(library extension, not duplication).

### §5.3 — Trinity considerations for `_toc.md`

`_toc.md` is the same single-file-per-stream-directory shape as
`_rules.md` — not trinity-replicated. Same rationale.

---

## §6 — Read-path contract (mirror, not replace)

### §6.1 — Decision (Open Question 3 resolved)

The monolithic file is **retained as a generated mirror**, not
abolished. This is the central design decision. Two reasons:

1. **Minimum read-shape change surface.** Per
   `RESEARCH-PER-ENTRY-SPLIT.md` §6 lines 627–749 and `ADDENDUM` §6
   lines 186–256, at least 10 wording surfaces today read `BACKLOG.md`
   (and another 3 read `CHANGELOG.md` / `IMPLEMENTATION-PLAN.md`) as
   single units. Replacing the monolithic file would force every one
   of those surfaces to change wording in the same release. Retaining
   the file as a mirror means agent prompts, skills, file-access
   strategy tables, and PM/Pack chat prose continue to read the
   single file as today, while writes flow through the per-entry
   tree.
2. **Pattern parity with tracker mode.** Tracker mode already
   establishes the mirror pattern: V1 §6.3 (preserved per V3 §0.5)
   specifies that the tracker keeps an in-place `BACKLOG.md` mirror;
   `scripts/lib/tracker-mirror.sh` module header at lines 1–24
   implements the idempotent header rewrite. Per-entry decomposition
   reuses this pattern: the per-entry tree is the new write source;
   the monolithic file is the new read mirror; the regenerator is the
   bridge — directly analogous to how `_tmf_regen_mirror()` at
   `scripts/lib/tracker-migrate-forward.sh:1172` regenerates the
   `BACKLOG.md` mirror from tracker state.

The alternative ("replace the file outright") would: (a) require
edits to PACK-CHAT.md / PM-CHAT.md file-access strategy tables, (b)
require the pack-startup and pm-startup skill directives ("Read
`BACKLOG.md` in full") to be rewritten for all three CLIs, (c)
require new agent-prompt wordings in pack-architect / pack-planner /
pack-coder / pack-reviewer (Claude / Codex / Gemini × 5 = 15
files), (d) break the v10→v11 migrator's atomic write contract
(reverse migration writes the file; users with the file open in an
editor would observe the deletion). The mirror approach makes the
decomposition invisible to read paths.

### §6.2 — Mirror generator contract

A mirror generator regenerates the monolithic file from the
per-entry tree. Like the `_toc.md` regenerator (§5.2), this is a
library helper in `scripts/lib/`, not a new top-level script (avoids
maintainability signal 6). The contract:

- **Input:** the directory path of a stream
  (`/.backlog/`, `/.changelog/`, `docs/project/backlog/`, etc.).
- **Output:** the monolithic file at the canonical location
  (`/BACKLOG.md`, `/CHANGELOG.md`, `docs/project/BACKLOG.md`,
  `docs/project/IMPLEMENTATION-PLAN.md` post-BD-104 /
  `IMPLEMENTATION_PLAN.md` pre-BD-104, `docs/project/CHANGELOG.md`),
  overwritten atomically in place.
- **Idempotency:** running the generator twice without intervening
  edits produces a byte-identical monolithic file.
- **Determinism:** entries are emitted in the same sort order as
  the corresponding `_toc.md` section. The section partitioning
  (e.g. pack-backlog `## Active — v11 Scope` / `## Active — v10
  Scope` / `## Resolved — v8 (March 2026)` / `## Deferred` per
  `RESEARCH-PER-ENTRY-SPLIT.md` §2 lines 162–167) is reconstructed
  from per-entry `Status:` + derived version axis.
- **Header preservation.** The legacy preamble at
  `BACKLOG.md:1-7` ("All planned improvements … METHODOLOGY.md
  Part 7"), the `## How to use this file` block at `:9-20`, and
  any other non-entry top-matter are preserved as static
  generator templates (sourced from `_rules.md`'s referenced
  authorities, not re-derived per-run).
- **Frozen-historical preservation.** The pack `## Resolved — v8
  (March 2026)` H2 at `BACKLOG.md:2248` (the only such H2 per
  `ADDENDUM` §8 line 297) is a v8 historical block from before
  the "no Resolved section" pack-memory rule. The generator
  emits it as a frozen literal block, sourced from a one-time
  `_v8-resolved-archive.md` per-stream file under `/.backlog/`
  (a non-entry file like `_rules.md` / `_toc.md`, named with the
  same leading-underscore convention). This avoids:
  (a) editing the pack-memory rule (off-limits per the architect
  prompt), and (b) re-litigating the conflict between rule and
  live content. The per-entry decomposition leaves the v8 H2
  exactly where it is, sourced from one frozen file. See §12 for
  the rule statement under decomposition.
- **No silent loss.** Anything in the legacy monolithic file
  that the generator cannot round-trip (an inline note that
  doesn't fit any entry, an orphaned `---` separator, a
  whitespace-only line) is preserved by being passed through to
  the mirror as-is via `_rules.md`'s "ignore-lines" pointer
  block in the migrator (see §10).

### §6.3 — Read sites under the mirror contract

Per the read-shape change surface enumerated in
`RESEARCH-PER-ENTRY-SPLIT.md` §6 + `ADDENDUM` §6:

- All single-file readers continue to read the same file path. No
  prompt-wording change is required to make decomposition work.
  This includes: pack-startup skills × 3 CLIs (Claude / Codex /
  Gemini), pm-startup skills × 3 CLIs, PACK-CHAT.md file-access
  strategy table, PM-CHAT.md file-access strategy table, the
  pack-architect / pack-planner / pack-coder / pack-reviewer agent
  files × 3 CLIs, and the project-side coder / repo-ops / auditor /
  auditor-docs agent files × 3 CLIs.

- **One optional wording change is recommended.** PACK-CHAT.md and
  PM-CHAT.md file-access strategy tables (`PACK-CHAT.md:42-43`,
  `project-template/docs/pack/PM-CHAT.md:119-123`) currently say
  "Direct read" and "Direct read (last entry only)". Under
  decomposition, agents that want to read a specific entry can
  read the per-entry file directly (skipping the mirror) for
  smaller token footprint. This is a *capability addition*, not a
  contract change. The mirror remains for full-file reads. The
  planner pass can add a new row "Direct read of per-entry file
  (e.g. `BD-NNN.md`) when only one entry is needed" without
  changing any existing row. This is the only suggested wording
  change at design time — the planner pass owns whether to ship it.

- **Tracker mode read path is unchanged.** Tracker mode reads
  tracker state (per `tracker-agent-read.sh` `_tar_read_entry_tracker`
  at line 100); flat-file mode reads the BACKLOG.md mirror (per
  `_tar_read_entry_flat` at line 153 — directly reads
  `$repo_root/BACKLOG.md`). The mirror generator regenerates the
  mirror after every per-entry write, so flat-file mode reads
  always see current state. See §8 for the tracker-mode interaction.

### §6.4 — Write-path / mirror-staleness contract

The mirror is regenerated as the **last step** of any write to a
per-entry file. The write order is:

1. Agent / Pack Chat / PM Chat / migrator writes a per-entry file
   (e.g. `/.backlog/BD-160.md`).
2. The mirror generator regenerates the canonical monolithic file
   from the per-entry tree (e.g. `/BACKLOG.md`).
3. The `_toc.md` regenerator regenerates the directory index.
4. Git sees both the per-entry file change AND the mirror change
   AND the `_toc.md` change in a single commit. (Per
   `RESEARCH-PER-ENTRY-SPLIT.md` §5 line 519 and `ADDENDUM` §4
   lines 128–148, BD-104's atomic-commit pattern is precedent.)

The agent and the user always see a current mirror. If the
mirror is stale (an agent edited a per-entry file without running
the regenerator — possible if a future workflow bug or a partial
agent run), `validate-pack.py` can grow a new staleness check
(this would be a maintainability-signal-4 structural change; see
§13 for the defense of NOT adding that check in v11.0).

---

## §7 — Write-path contract (Pack Chat / PM Chat integration)

### §7.1 — Write authority

Write authority is unchanged from today:

- **Pack-side `backlog/` + `changelog/`.** Pack Chat only, after
  explicit user approval. Pack agents (`pack-architect`, `pack-planner`,
  `pack-coder`, `pack-reviewer`, `pack-docs-researcher`) MAY NOT
  write to per-entry files under `/.backlog/` or `/.changelog/` —
  these inherit the PM-only restriction from BACKLOG.md /
  CHANGELOG.md per PACK-AGENTS.md lines 102–105 ("Writing BACKLOG.md
  entries / Writing CHANGELOG.md entries — Pack chat only").
- **Project-side `backlog/` + `implementation-plan/` + `changelog/`.**
  PM Chat only, after user approval. Project agents inherit the
  PM-only restriction from BACKLOG.md / CHANGELOG.md / STATUS.md
  per `project-template/.claude/agents/coder.md:80-81` and
  `repo-ops.md:66-67` per `RESEARCH-PER-ENTRY-SPLIT.md` §6 lines
  707–714.

The PM-only list expansion to include `backlog/` / `changelog/` /
`implementation-plan/` directories is a maintainability-signal-9
("PM-only file expansion") consideration — see §13.

### §7.2 — Write atomicity

A "write" to a stream is a multi-file change:

- Edit one or more per-entry files.
- Regenerate the mirror (single file per stream).
- Regenerate `_toc.md` (single file per stream).

These three files (or N+2, for N edited per-entry files) compose a
single atomic commit. Pack Chat / PM Chat stage all of them
together. This is consistent with existing pack-coder workflow
discipline: pack-coder produces working-tree edits + a report
file, and Pack Chat verifies-then-commits-atomically per pack
memory in pack-root CLAUDE.md lines 102–107.

### §7.3 — Pack Chat / PM Chat workflow integration (no edit specifics)

Pack Chat and PM Chat workflows need to be aware of three new
operational facts under decomposition:

1. The per-entry file is the source of truth — `Status:` flips,
   `Resolved:` field additions, and new BD-NNN / TD-NNN entries
   land in the per-entry file, not in the monolithic mirror.
2. The mirror is regenerated, not edited. Edits to the mirror are
   not allowed; if a workflow accidentally edits the mirror, the
   next regenerator run overwrites the change.
3. The `_toc.md` is regenerated, not edited.

The specific wording for PACK-CHAT.md (`/PACK-CHAT.md` at pack
root) and PM-CHAT.md (`project-template/docs/pack/PM-CHAT.md`) is
the planner pass's job — those files are PM-only and outside this
design's edit authority per the architect prompt. Pack-startup and
pm-startup skill directives ("Read `BACKLOG.md` in full" per
`.claude/skills/pack-startup/SKILL.md:19` and the per-CLI mirrors)
similarly stay as-is unless the planner pass elects to add a per-
entry-read capability. See §14 for the integration-point file list.

---

## §8 — Integration with tracker mode

### §8.1 — Decision (Open Question 4 resolved)

Per-entry decomposition sits **below** tracker mode in the
flat-file flavor, not beside or inside it. This resolves Open
Question 4 with the "below tracker" option. The full mode picture:

- **Mode 1: flat-file, monolithic source-of-truth** (v10 and
  v10.1 client behavior; pack repo today). The monolithic file
  is the source of truth.
- **Mode 2: flat-file, decomposed source-of-truth (THIS DESIGN).**
  The per-entry tree is the source of truth; the monolithic file
  is a generated mirror. Tracker is not enabled. From a tracker-
  surface perspective, this mode looks identical to Mode 1: the
  monolithic file is current and correctly shaped.
- **Mode 3: tracker mode (v11 design — per V3.x).** The tracker
  is the source of truth; both the per-entry tree (if present)
  and the monolithic file are mirrors regenerated from tracker
  state.

The forward migration contract is unchanged. Forward migration
reads the monolithic file (or, after this design lands, the
mirror — which is byte-identical to what the monolithic file
would be under Mode 1). Per `RESEARCH-PER-ENTRY-SPLIT.md` §8
lines 788–812:
- `tmf_parse_backlog()` at `tracker-migrate-forward.sh:268` reads
  the BACKLOG.md mirror — works identically.
- `tmf_parse_implementation_plan()` at line 399 reads the
  IMPLEMENTATION-PLAN.md mirror — works identically.
- `_tmf_regen_mirror()` at line 1172 regenerates the BACKLOG.md
  mirror — under decomposition, this regeneration must ALSO
  regenerate the per-entry tree (or skip it, see §8.2).

### §8.2 — Tracker enable interaction with per-entry tree

When a user opts into tracker mode (Mode 2 → Mode 3), the
existing tracker-enable flow reads the monolithic file (mirror)
and emits tracker state. Two behaviors are possible for the
per-entry tree at that point:

- **Option A (recommended): the per-entry tree becomes a tracker-
  mirrored read-only tree, in addition to the monolithic file.**
  Both the monolithic mirror and the per-entry tree are
  regenerated from tracker state by the tracker-mirror flow. This
  preserves the per-entry shape so users who like it keep it;
  agents that read per-entry files (if the planner pass adds that
  capability per §6.3) still find them.
- **Option B: the per-entry tree is left untouched as a stale
  flat-file-mode artifact.** The monolithic mirror is regenerated
  from tracker state; the per-entry tree gets out of sync; reads
  are advised to go through the monolithic mirror.

This design recommends Option A but does not require it. The
v11-implementation chat's planner pass owns the call.

### §8.3 — Tracker reverse interaction with per-entry tree

The tracker reverse-emit contract is frozen per architect prompt
guard rail 6 — repaired by BD-131..BD-134 in v11.0, not redesigned
by this design. Per `RESEARCH-PER-ENTRY-SPLIT.md` §8 lines 824–853:
- `_tmr_emit_backlog()` at `tracker-migrate-reverse.sh:409` emits
  the full BACKLOG.md.
- `_tmr_emit_implementation_plan()` at line 485 emits the full
  IMPLEMENTATION-PLAN.md skeleton.
- `_tmr_emit_changelog()` at line 553 emits the full CHANGELOG.md
  skeleton.
- `_tmr_emit_status()` at line 514 emits STATUS.md (out of scope
  for this design).

Under decomposition, reverse-emit continues to emit the
monolithic files. A separate post-emit step decomposes those
monolithic files into the per-entry tree, regenerates the mirror
(which should be byte-identical to the just-emitted file — that
byte-identity is the reverse-emit's verification probe; see §8.4),
and regenerates `_toc.md`. The reverse-emit functions themselves
do not change shape — only what follows them changes.

The post-emit decomposition is a library helper (per the §5.2 /
§6.2 pattern). Its name and call site belong to the planner.

### §8.4 — Round-trip verification

The V3.1-DELTA §3 A2 decision (lines 180–255) plus its
V1 §6.7-extension contract (forward → reverse → forward is a
no-op for v10-grammar fields; v11.x-introduced fields survive
via sidecar) is preserved. Per-entry decomposition adds a third
round-trip: **mirror generation must be the inverse of mirror
decomposition.** That is:

- Decompose(`BACKLOG.md`) → per-entry tree.
- Regenerate-mirror(per-entry tree) → `BACKLOG.md`'.
- `BACKLOG.md` and `BACKLOG.md`' must be byte-identical.

This is the same byte-identity contract V1 §6.7 establishes for
the forward/reverse round trip, applied to the
monolithic↔per-entry transformation. The verification harness
(`scripts/tracker-migrate.sh roundtrip-test` extension per
V3.1-DELTA §3 line 246) extends to cover this round trip — same
pattern, same library, no new contract.

---

## §9 — Integration with customization-preserve (BD-088)

### §9.1 — Decision (Open Question 7 resolved)

The decomposed per-entry tree continues to fall through to the
existing **`generic` class** in
`scripts/lib/customization-preserve.sh` `customization_classify()`
(lines 145–179 per `RESEARCH-PER-ENTRY-SPLIT.md` §5). No new
classes are added. This resolves Open Question 7 with the
"generic-with-shape" framing — the per-entry paths route through
the existing `_cp_strategy_text` 3-way text dispatch (lines
514–558, dispatch table at lines 531–532).

Rationale:

1. **No invasive class-table changes.** Adding three new classes
   (`backlog-entry`, `changelog-version-block`,
   `implementation-plan-entry`) would expand the 12-class
   classifier table and force a corresponding expansion in the
   strategy dispatcher. The existing dispatch already handles the
   text-shape — extending the class table without changing
   semantics is churn for no benefit.
2. **Per-entry files are smaller than the monolithic files.** The
   3-way text dispatch operates on per-file 3-way diff. Smaller
   files diff more cleanly; user customization within one BD entry
   is more likely to remain confined to that one file. The
   decomposition incidentally *improves* customization-preservation
   diff resolution without changing the classification.
3. **`_rules.md` and `_toc.md` route to `generic` too.** No special
   classification needed for the control files either — they are
   text, they get 3-way merged with the truthful report (BD-088
   contract) noting any customization. Because `_rules.md` is
   pointer-only and short by design, user customizations to it
   should be rare; when they happen, the truthful report makes
   them visible and the user resolves manually. `_toc.md` is
   regenerated, so customizations are overwritten — the truthful
   report will mark this as expected behavior (the planner pass
   can opt to add a `.gitignore` line for `_toc.md` in client
   projects, since it is purely derived; this is a planner
   decision, not an architect decision).

### §9.2 — Customization-preserve manifest implications

Today the customization-preservation library does not manifest-list
BACKLOG.md / CHANGELOG.md / IMPLEMENTATION_PLAN.md / IMPLEMENTATION-
PLAN.md — they are not in `customization_classify()` and fall to
`generic`. This is the explicit finding at
`RESEARCH-PER-ENTRY-SPLIT.md` §5 lines 568–578 and 580–585.

Under decomposition, the per-entry files inherit the same
non-manifest-listed status. The customization-preserve workflow at
migration time:

- Identifies each per-entry file by path (e.g.
  `docs/project/backlog/TD-001.md`).
- Routes via the path-to-class classifier → `generic`.
- Runs 3-way text dispatch — same as it does for any other
  generic text file today.
- Reports `unchanged-pack` / `pack-update-applied` /
  `merged-with-customization` /
  `customization-detected-needs-reconciliation` per the existing
  disposition vocabulary at `customization-preserve.sh:32-48`.

No new dispositions. No new classes. The contract is unchanged.

### §9.3 — Migration-time entry routing

The v11.0 → v11.1 (or v11.x) migrator that lands per-entry
decomposition is the one that initially creates the per-entry tree
from the monolithic file in the client project. This is a migrator-
behavior change (maintainability-signal-8 per `ADDENDUM` §5 lines
178–182) — see §10. From customization-preserve's perspective:

- The monolithic file in the client (which may contain user
  customizations to BD entries the user added to their fork of the
  pack BACKLOG, though pack BACKLOG is pack-only — this scenario is
  more realistic for project-side `docs/project/BACKLOG.md`) is
  classified `generic` today.
- The migration step that decomposes it splits the file into
  per-entry files. The split is byte-additive (per §6.2 the
  split-then-recompose is byte-identity-preserving), so the
  user's customizations are preserved at the entry level. The
  truthful report stamps each per-entry file with its disposition
  per the existing contract.

This is BD-088's existing strength — see V3-research IMPLEMENTATION-
PLAN.md §2.5 (lines 738–785) on the customization-preservation
contract.

---

## §10 — Integration with BD-119 migrator framework

### §10.1 — Contract preservation

Per architect prompt guard rail 5, the BD-119 migrator framework
contract is frozen for v11.0. Required hooks (per
`scripts/lib/migrator-core.sh:147-153` and
`RESEARCH-PER-ENTRY-SPLIT.md` §5 lines 587–600):

- `migrator_manifest` (line 148)
- `migrator_directory_sweeps` (line 149)
- `migrator_relocations` (line 150)
- `migrator_artifact_installs` (line 151)
- `migrator_post_report_hook` (line 152)

Optional hooks (lines 217–224):

- `migrator_pre_dispatch_hook` (line 217)
- `migrator_post_dispatch_hook` (line 222)

**This design does not add a new hook.** Per-entry decomposition,
when shipped, plugs into the **existing** hook surface.

### §10.2 — Which hook(s) consume per-entry shape

The v11.0 → v11.x migrator that initially lands per-entry
decomposition uses the existing `migrator_post_dispatch_hook`
(optional, line 222) to perform the one-shot
"decompose monolithic → per-entry tree + regenerate mirror"
operation. This is precedent: the v10→v11 adapter already uses
this hook for the BD-104 rename (`scripts/migrate-v10-to-v11.sh:134-149`)
and BD-042 relocation per `ADDENDUM` §4 lines 128–148. The
decompose-and-regenerate operation has the same shape: an
adapter-private operation that runs once at the version boundary,
outside the manifest/sweep/relocate/artifact-install vocabulary.

The adapter-private helper functions live under
`scripts/lib/migrate-vN-to-vM/` (per the existing
`scripts/lib/migrate-v10-to-v11/` precedent in README.md repo
layout). They invoke the same library-helper mirror generator
and `_toc.md` regenerator described in §5.2 and §6.2 — so the
migrator and the runtime workflows share parsing code, not
duplicated logic. The library helper is added to `scripts/lib/`
(not a new top-level script — avoids maintainability signal 6 per
the §13 defense).

### §10.3 — Manifest implications

`migrator_manifest()` enumerates per-file transforms (per
`migrator-manifest.sh:118` vocabulary `transform | add | remove |
relocate-from`). The migration step that decomposes the
monolithic file ALSO sees the file in the manifest as a
`transform` operation, with the legacy file path on the v10/v11.0
side and the same path (now the regenerated mirror) on the v11.x
side. The manifest entry's content classifier is `generic`
(per §9.1); the transform-time decomposition runs in the
post-dispatch hook adapter helper before the manifest's
3-way text dispatch sees the file. This sequencing is the
adapter's responsibility, not the framework's — same as the
v10→v11 rename precedent.

### §10.4 — Pre-dispatch vs post-dispatch

Per `scripts/lib/migrator-core.sh:212-230` stage order:

```
_stage_preflight → _stage_backup → _stage_libs →
  (pre-dispatch hook) → _stage_dispatch →
  (post-dispatch hook) → _stage_relocations →
  _stage_artifact_installs → _stage_report →
  (post-report hook)
```

The per-entry decomposition fits cleanly in
`migrator_post_dispatch_hook`: after the manifest dispatch has
done its 3-way text merge on the monolithic file (preserving
customizations), the decomposition splits the merged file into
per-entry pieces. This sequence means user customizations are
preserved through the decomposition: anything the user customized
in the monolithic file ends up in the appropriate per-entry file
because the split operates on the merged file, not on the pack
shipped file.

---

## §11 — Pack vs project asymmetry resolution

### §11.1 — Decisions (Open Questions 1 and 6 resolved)

**Open Question 1 (uniform vs per-stream decomposition philosophy):**
This design adopts **per-stream decomposition with shared common
shape**. The common shape is `_rules.md` + `_toc.md` +
flat-directory-of-per-entry-files (§3.0). The stream-specific
units differ — BD-NNN / TD-NNN entries, vN.M version blocks,
phase-N + phase-N.M epic+task pairs, YYYY-MM-DD-phase-NN dated
records. Three streams, three unit shapes, one common directory
contract. This is the architect prompt's option (c) framing for
guard rail 7 (compose a single decomposition philosophy onto
three different surface shapes via different per-stream units),
extended to all three streams not just IMPLEMENTATION-PLAN.

**Open Question 6 (does decomposition propagate to project-template):**
Yes — for `backlog/` and `implementation-plan/` and `changelog/`,
project-side decomposition ships in `project-template/docs/project/`
and propagates to client projects via `init-project.sh` (greenfield)
and `migrate-vN-to-vM.sh` (existing v10.1 / v11.0 clients). The
pack-side `/.backlog/` and `/.changelog/` decomposition is
pack-self only — these directories do not ship in
`project-template/`. Project-side decomposition is NOT a pure
mirror of pack-side because:

- Project-side has three stream directories (`backlog/` +
  `implementation-plan/` + `changelog/`); pack-side has two
  (`backlog/` + `changelog/`), per V3 §28.1 line 603.
- Project-side `backlog/` uses TD-NNN; pack-side uses BD-NNN —
  per V3.3-DELTA §6.4 lines 360–370.
- Project-side `changelog/` has the `_format.md` extra non-entry
  file (per §3.5); pack-side does not (no analogous Format Rules
  block in pack `CHANGELOG.md`).
- Project-side `implementation-plan/` decomposes by phase + phase
  task (per §3.4); pack-side has no implementation-plan stream
  (per V3 §28.1 line 603).
- Project-side `backlog/` entry-format fields differ from
  pack-side: `Context:` / `Resolution:` (project) vs `Resolved:`
  (pack); inline `✅ RESOLVED (Phase NN)` annotation on bold-header
  for project Resolved entries; 2-state vs 5-state lifecycle —
  all per `RESEARCH-PER-ENTRY-SPLIT.md` §4 line 460 and the
  state-vocabulary architect-overreach signal per the brief.

This asymmetry is **defended**, not eliminated. Each difference
traces to either a V3.3-DELTA section that explicitly
distinguishes pack from project (e.g. §6.3 state mapping per
entity type at lines 341–360), or to a project-side legacy
convention preserved for consistency with v10 (the `✅ RESOLVED`
annotation, Format Rules block). Eliminating the asymmetry would
require either harmonizing state vocabularies (the brief's
architect-overreach signal 2, out of scope) or harmonizing field
names (the brief's architect-overreach signal 1, out of scope).

### §11.2 — Surface count per side

| Surface | Pack-side | Project-side |
|---|---|---|
| `backlog/` | Yes (BD-NNN) | Yes (TD-NNN) |
| `changelog/` | Yes (vN.M) | Yes (YYYY-MM-DD-phase-NN + `_format.md`) |
| `implementation-plan/` | **No** (pack has none per V3 §28.1:603) | Yes (phase-N + phase-N.M) |
| `_rules.md` (per-stream) | Yes (× 2) | Yes (× 3) |
| `_toc.md` (per-stream) | Yes (× 2) | Yes (× 3) |
| `_v8-resolved-archive.md` | Yes (in `/.backlog/`) | N/A (no analog in OT project-side BACKLOG) |
| `_format.md` | N/A (no Format Rules H2 in pack CHANGELOG) | Yes (in `changelog/`) |

The pack/project split is intentional. Pack-side has
fewer streams (2 vs 3), one extra one-time legacy archive file
(v8 Resolved H2 preservation), and no Format Rules file. These
are not gratuitous asymmetries — each is forced by an existing
pack-vs-project structural difference.

---

## §12 — CLAUDE.md "no Resolved section" rule under decomposition

### §12.1 — Statement (Open Question 5 resolved, no edit)

Per architect prompt guard rails 3 + overreach signal 3 + hard-
stop rules, this design does **not** propose any edit to pack-
root or project-template CLAUDE / AGENTS / GEMINI. It only
states what the existing rule means under decomposition.

The current rule at pack-root `CLAUDE.md:157-159`:

> **BACKLOG.md has no Resolved section.** Entries resolve in place
> by flipping `Status: Open` to `Status: Resolved` and filling the
> `Resolved:` line. Do not propose moving entries to a separate
> section.

Under per-entry decomposition (Mode 2 per §8.1):

- "BACKLOG.md" in the rule reads as "the BACKLOG.md mirror," per
  §6.1.
- "No Resolved section" reads as "no Resolved H2 in the mirror."
- "Entries resolve in place" reads as "entries resolve in their
  per-entry file by flipping `Status:` in that file."
- "Filling the `Resolved:` line" is unchanged — the per-entry
  file is where the `Resolved:` line is filled.
- "Do not propose moving entries to a separate section" reads as
  "do not propose moving entries to a separate directory or
  subdirectory" — since per-entry files are flat under `/.backlog/`
  with no Status-named subdirectories, this is trivially
  satisfied.

The rule remains correct under decomposition without textual
change. The only thing that changes is the implicit referent
("the file" → "the mirror"), and that referent change is
absorbed by the mirror contract in §6.

### §12.2 — The `## Resolved — v8` H2 conflict

Per `ADDENDUM` §8 lines 292–301, there is exactly one
`## Resolved — vN` H2 in pack `BACKLOG.md` (at line 2248,
v8 historical block). The rule says "no Resolved section";
the file has one. Under decomposition:

- The v8 historical block is preserved via the
  `_v8-resolved-archive.md` frozen literal under
  `/.backlog/` (per §6.2).
- The mirror generator emits the v8 H2 from that frozen file
  into the regenerated `BACKLOG.md` byte-identically.
- The rule's "no Resolved section" statement becomes
  trivially true in the per-entry tree (there is no Status-
  named directory or subdirectory; entries with
  `Status: Resolved` live as `BD-NNN.md` files alongside
  Open entries, sorted into status buckets only in
  `_toc.md` and only as a derived index).

The conflict is not resolved by this design — the rule and the
v8 H2 still co-exist. But the conflict is **rendered
inoperative** under decomposition: the rule applies to write
operations (don't create new Resolved sections); the v8 H2 is
frozen-historical (no new Resolved sections will be created
because v9..v11 history is encoded in per-entry `Resolved:`
lines, not in any new H2). The user / PM Chat may decide to
unify the convention in a future pack version, but the present
design preserves both as-is.

---

## §13 — Maintainability principle defense (signals 4 / 5 / 6 / 8)

Per `ADDENDUM` §5 lines 152–182 (citing
`maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md`
§3.2 lines 274–311), per-entry decomposition trips structural
signals 4 / 5 / 6 / 8. This section defends each.

### §13.1 — Signal 4 (new validator check)

Verbatim trigger: "Any addition to `scripts/validate-pack.py`
that introduces a new `check_*` function, regardless of triggering
BD" (§3.2 lines 285–287).

**Defense.** This design does **not** propose a new validator
check. Today's Check 3 (TD-TBD sentinels per
`RESEARCH-PER-ENTRY-SPLIT.md` §7 lines 753–779) operates on the
monolithic `BACKLOG.md` mirror; under decomposition, the mirror
continues to exist (§6) and Check 3 continues to operate on it
with the same regex (`^\*\*TD-TBD\s*—` at line 276). No new
`check_*` function is required for the per-entry tree itself —
the round-trip byte-identity verification (§8.4) is a CI-time
test, not a `check_*` function in `validate-pack.py`.

A future planner pass MAY decide to add a `check_per_entry_*`
function (mirror-staleness gate; per-entry file naming
conformance; etc.). That is a separate architect pass. This design
does not require it. The v11.0 ship surface is unchanged.

### §13.2 — Signal 5 (new top-level doc)

Verbatim trigger: "Adding a new `.md` in pack root,
`supporting-docs/`, `project-template/docs/`, or
`maintenance-docs/v11-implementation/` that is not an
`ARCHITECTURE-*.md` / `PLAN-*.md` / `IMPLEMENTATION-REPORT-*.md` /
`PACK-REVIEW-*.md` / `AUDIT-*.md` / `RESEARCH-*.md` /
`*-DISCOVERY.md` produced by the existing architect / planner /
coder / reviewer / auditor / docs-researcher workflow" (§3.2 lines
288–294).

**Defense.** This architecture doc itself
(`ARCHITECTURE-PER-ENTRY-SPLIT.md`) and its parent research
(`RESEARCH-PER-ENTRY-SPLIT.md` + `ADDENDUM`) are workflow
artifacts in the `ARCHITECTURE-*.md` / `RESEARCH-*.md` extension
allow-list (per the workflow-artifact exemption at pack memory
`CLAUDE.md:174-183`). They sweep to `maintenance-docs/archive/v11/`
at version ship per Pattern B (same `CLAUDE.md:174-183` block).
No structural signal triggered.

The per-entry decomposition adds new files (per-entry BD-NNN.md,
TD-NNN.md, vN.M.md, phase-N.md, phase-N.M.md,
YYYY-MM-DD-phase-NN.md plus `_rules.md` / `_toc.md` /
`_v8-resolved-archive.md` / `_format.md`) — these are pack
*data* / pack *product*, not top-level docs. They live in
`/.backlog/` / `/.changelog/` / `docs/project/backlog/` etc.,
not in the pack-root / supporting-docs / project-template/docs/
/ maintenance-docs/v11-implementation/ list that signal 5
enumerates. The signal-5 location filter explicitly omits
`/.backlog/` and `/.changelog/` because they are pack-state
directories, not doc directories. No structural signal
triggered.

The `_rules.md` is a *contract-pointer* file (§4.1), not a
narrative doc — it doesn't fit any of the seven enumerated
workflow-artifact suffixes, but it also doesn't fit signal 5's
location filter. It is structurally novel as a file class, and
this design defends adding it as one architect pass (this
pass): the file class is justified by the immutability mechanism
and the read-cold-resolve-contract requirement; it ships per-
stream-directory; it sweeps with neither the workflow-artifact
allow-list nor the pack-root-doc deny-list because it lives
inside the stream directory itself, not at any of signal 5's
enumerated paths. This is the structural-signal defense — the
architect pass IS this doc; the planner pass / reviewer pass /
coder pass will land the convention.

### §13.3 — Signal 6 (new script)

Verbatim trigger: "Adding a new top-level `scripts/*.sh` or
`scripts/*.py` (helpers in `scripts/lib/` are not new scripts;
they are library extensions)" (§3.2 lines 295–297).

**Defense.** This design names two library helpers — the
mirror generator (§6.2) and the `_toc.md` regenerator (§5.2).
Both live in `scripts/lib/`, not as top-level
`scripts/*.sh` / `scripts/*.py`. They are library extensions per
the signal-6 verbatim carve-out. The migrator-adapter helper
that initially decomposes the monolithic file lives in
`scripts/lib/migrate-vN-to-vM/` (per existing
`scripts/lib/migrate-v10-to-v11/` convention per README.md repo
layout). No new top-level script. No structural signal
triggered.

If the v11-implementation chat's planner pass elects to add a
user-facing CLI entry point (`pack backlog decompose` or
similar verb), that adds a *verb* to an existing top-level
script (`scripts/pack-tracker.sh` or a new sibling), and
trips signal 6 only if it materializes as a new top-level
script file. The planner pass owns whether that is needed.

### §13.4 — Signal 8 (migrator behavior change)

Verbatim trigger: "Any change that requires a new migrator
stage, a new manifest entry, or a new advisory file in
`migrate-vN-to-vM.sh` — these touch BD-119 framework
contracts (`maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md`)"
(§3.2 lines 301–304).

**Defense.** Per §10 above:
- **No new migrator stage.** The decomposition runs in the
  existing optional `migrator_post_dispatch_hook` (already
  optional, already used by v10→v11 adapter for the BD-104
  rename). No new stage in the `_stage_*` sequence at
  `migrator-core.sh:212-230`.
- **No new manifest entry beyond what manifest already
  admits.** The transform of the monolithic file remains a
  `generic` 3-way text dispatch (per §9.1); the decomposition
  is adapter-private, not manifest-level.
- **Possibly new advisory text in the post-report hook.**
  When per-entry decomposition lands in a v11.x migrator,
  `migrator_post_report_hook()` will need a paragraph
  explaining to the user that the per-entry tree was
  generated and the monolithic file is now a regenerated
  mirror. Whether this constitutes a "new advisory file"
  per signal 8 is a planner-pass judgment; this design
  flags it as a likely signal-8 trip but argues it is the
  minimum-invasive option: a single advisory paragraph,
  not a new advisory file. The truthful BD-088 report
  (`scripts/lib/customization-report.sh`) covers the
  per-file disposition narrative; the post-report hook
  references the existing report mechanism.

Signal 8 is **conditionally tripped** (depends on the
planner's choice of advisory delivery). This architect pass
acknowledges that and surfaces the choice to the planner.
The framework contract itself (`migrator-core.sh` public API)
is preserved without change.

---

## §14 — Read-shape change surface (integration points)

Per `ADDENDUM` §6 lines 186–256 the wording surfaces today read
the relevant stream file as a single unit. Under the mirror
contract (§6.1), **none of these wordings need to change for
decomposition to work**. The planner pass MAY elect to update
some of them to mention the per-entry-read capability (§6.3
optional row), but that is a planner decision, not an
architect requirement.

This design enumerates the surfaces the planner pass will need
to reference (NOT edit specifics — that is the planner's job).
Each surface is cited with file:line so the planner sees the
exact current wording.

### §14.1 — Pack-side (5 surfaces + 4 agent files)

- `PACK-CHAT.md:42-43` — file-access strategy table rows for
  `BACKLOG.md` and `CHANGELOG.md`. (PACK-CHAT.md is PM-only per
  the architect prompt's "do not propose edits to" list. The
  planner pass owns whether to add a per-entry row.)
- `.claude/skills/pack-startup/SKILL.md:19-21` — "Read
  `BACKLOG.md` in full." and "Read only the most recent dated
  entry from `CHANGELOG.md`."
- `.codex/skills/pack-startup/SKILL.md:19-21` — same wording per
  trinity rule.
- `.gemini/commands/pack-startup.toml:16-18` — same wording.
- `.claude/agents/pack-architect.md:27` — "- BACKLOG.md (open BD
  items and their constraints)". Per-CLI trinity mirrors in
  `.codex/agents/` and `.gemini/agents/`.
- `.claude/agents/pack-planner.md:32`, `pack-coder.md:34, 38`,
  `pack-reviewer.md:28-29` — agent-side BACKLOG / CHANGELOG
  references; trinity-mirrored.

### §14.2 — Project-side (5 surfaces + 4 agent files)

- `project-template/docs/pack/PM-CHAT.md:119-123` — file-access
  strategy table rows for BACKLOG / CHANGELOG / IMPLEMENTATION-
  PLAN. PM-only per the architect prompt; planner owns.
- `project-template/skills/pm-startup/SKILL.md:69-79, 83-87,
  191-192` — multiple read directives covering BACKLOG entries,
  CHANGELOG most-recent section, IMPLEMENTATION-PLAN current
  phase section, plus trinity `## Document locations` reference.
- `project-template/.claude/skills/pm-startup/SKILL.md` —
  per-CLI mirror.
- `project-template/.codex/skills/pm-startup/SKILL.md` —
  per-CLI mirror.
- `project-template/.gemini/commands/pm-startup.toml:66-67, 73,
  76, 80, 83-84, 188-189` — Gemini surface.
- `project-template/.claude/agents/coder.md:80-81`,
  `repo-ops.md:66-67`, `auditor.md:42`,
  `auditor-docs.md:28-31, 62` — project agent references.
  Trinity-mirrored to `.codex/` and `.gemini/`.

### §14.3 — Library / script integration points

These are pack-product files that this design names as integration
points without specifying edits:

- `scripts/lib/tracker-mirror.sh` — V1 §6.3 mirror contract that
  per-entry decomposition reuses.
- `scripts/lib/tracker-migrate-forward.sh` —
  `tmf_parse_backlog()` / `tmf_parse_implementation_plan()` /
  `_tmf_regen_mirror()` per `RESEARCH-PER-ENTRY-SPLIT.md` §8.
- `scripts/lib/tracker-migrate-reverse.sh` —
  `_tmr_emit_backlog()` / `_tmr_emit_implementation_plan()` /
  `_tmr_emit_changelog()`.
- `scripts/lib/tracker-agent-read.sh` —
  `_tar_read_entry_flat()` reads BACKLOG.md mirror directly.
- `scripts/lib/customization-preserve.sh` — `customization_classify()`
  routes per-entry files to `generic`.
- `scripts/lib/migrator-core.sh` — `migrator_post_dispatch_hook`
  used by adapter for one-shot decomposition.
- `scripts/migrate-v10-to-v11.sh` — precedent for post-dispatch
  hook usage.
- `scripts/validate-pack.py` — Check 3 (`check_td_tbd_sentinels`)
  continues to operate on the regenerated mirror.

These are the planner's working set when scheduling the
implementation BDs. This design DOES NOT propose specific edits
to any of them.

---

## §15 — Sequencing constraints (flagged, not pre-resolved)

Per architect prompt guard rail 6, sequencing with
`EXECUTION-PLAN-V11.0.md` Batches 7–10 (BD-131..BD-134 tracker
repairs) and Batch 12 (BD-104 rename) is owned by the primary
v11-dev chat's planner pass. This design is sequencing-agnostic
but flags two constraints:

### §15.1 — Per-entry decomposition relative to BD-104

Per `ADDENDUM` §4 lines 128–148, BD-104 renames
`IMPLEMENTATION_PLAN.md` → `IMPLEMENTATION-PLAN.md` at Batch 12,
executed in `migrator_post_dispatch_hook` of the v10→v11
adapter. Per-entry decomposition of project-side
implementation-plan touches the same file. Two valid sequences:

- Decomposition AFTER BD-104. Per-entry tree is
  `docs/project/implementation-plan/` containing
  `phase-N.md` / `phase-N.M.md` files; mirror is the hyphenated
  `IMPLEMENTATION-PLAN.md`. This is the cleaner sequence and
  matches V3.3-DELTA §4.1's hyphenated forward-parser contract.
- Decomposition BEFORE BD-104. Decomposition operates on the
  underscore-named `IMPLEMENTATION_PLAN.md`; mirror is the
  underscore file; BD-104 renames the mirror. The decomposition
  is sequencing-blind because the per-entry tree filenames
  (`phase-N.md` / `phase-N.M.md`) don't reference the parent
  filename. Either sequence is correct.

**Recommendation: after BD-104.** Avoids carrying the
underscore name into per-entry shipping prose. Planner-owned.

### §15.2 — Per-entry decomposition relative to Batches 7–10

Per architect prompt guard rail 6, the tracker surface is being
repaired by BD-131..BD-134 in v11.0 (Batches 7–10). Per-entry
decomposition reuses the V1 §6.3 mirror contract that the
tracker surface depends on. This design must compose against
the **repaired** tracker surface — i.e., decomposition lands
after Batches 7–10. This is a hard constraint, not a soft
recommendation. Decomposition before Batches 7–10 would risk
landing on top of code that the repair batches will replace.

**Recommendation: after Batches 7–10 complete.** Planner-owned.

### §15.3 — Decomposition is a v11.x feature, not v11.0

This design is too large to ship in v11.0 alongside Batches
1–13 of `EXECUTION-PLAN-V11.0.md`. It is a v11.x feature
(v11.1 or later). The version target is the planner's call;
this design is version-target placeholder per §0.

If the planner pass elects to defer to v12.0, the design
remains valid (it is byte-additive on the v10 grammar and
composes onto the v11 tracker surface).

---

## §16 — Open questions for the v11-implementation chat

These are questions this design surfaces for the v11-implementation
chat to answer (different from the 7 open design questions in the
architect brief, which are resolved in §3–§12 above).

### §16.1 — Mirror generator failure UX

If the mirror generator fails mid-run (parse error in a per-entry
file, disk full, etc.), the monolithic mirror could end up in a
stale state. Two options:
- **Fail-loud:** generator writes nothing on partial failure,
  leaving the previous mirror. User sees a generator-error
  banner.
- **Fail-soft:** generator writes a partial mirror with a banner
  warning "regeneration partial — N entries skipped." User
  proceeds with degraded read state.

Per V3.x typed-error convention (D-9 / D-10 / D-11), fail-loud is
the precedent. This design recommends fail-loud but flags the
choice for planner / coder.

### §16.2 — `_toc.md` in `.gitignore`?

`_toc.md` is regenerated. Two options:
- **Tracked:** lives in git, regenerated on every write,
  diffs visible in PRs. Verifies regeneration determinism.
- **Gitignored:** lives only in working tree, regenerated on
  demand, not in PRs. Smaller commits.

For pack-side, the regeneration is part of every Pack-Chat commit
and PR review benefits from seeing the index change. Recommend
tracked. For project-side, projects vary — recommend the planner
pass settle this via `project-template/.gitignore` or
`init-project.sh` flag.

### §16.3 — Migration messaging

When the v11.x migrator decomposes a v11.0 client's monolithic
files into per-entry trees, the user sees a large directory
appear. The truthful BD-088 report covers per-file dispositions,
but the *transformation* itself (split monolithic → per-entry +
mirror) is not in the customization vocabulary today. Question
for the planner: does this need a new disposition token (e.g.
`decomposed`)?

This design recommends **no** — the per-entry files are byte-
additive content from the user's perspective (their entries
land in per-entry files; the mirror is byte-identical to the
previous monolithic shape). The disposition vocabulary handles
text changes; this is a structural-shape change but with zero
text drift. The post-report hook (§10.4) carries the
explanatory paragraph instead. Planner-owned.

### §16.4 — Per-entry permission scoping in PM-only lists

PACK-AGENTS.md "PM-only files" list (lines 139–142, the agents-
never-modify list — per `RESEARCH-PER-ENTRY-SPLIT.md` §6 line
145 area implies this list) names individual files:
BACKLOG.md, CHANGELOG.md, README.md version table, PACK-CHAT.md,
PACK-AGENTS.md, CLAUDE / AGENTS / GEMINI (root +
`project-template/`). Under decomposition, the equivalent list
would name directories: `/.backlog/`, `/.changelog/`,
`docs/project/backlog/`, etc.

Per architect prompt guard rail 3, this design does not propose
PACK-AGENTS.md edits. The planner pass owns the wording. This
design flags it as a maintainability-signal-9 trip ("PM-only
file expansion") if the planner's edit explicitly broadens the
list — though it might be argued the directory-level reference
is a refactor of the file-level reference, not an expansion.

### §16.5 — Does per-entry decomposition affect inflection-point
        signals?

Per V3 §28.1 (lines 566–1032) the recommendation system uses
signals including `bd_count_active` / `backlog_kb` /
`backlog_growth_30d`. Under decomposition:

- `bd_count_active` is trivially derivable from a `find
  /.backlog/ -name 'BD-*.md'` + grep for `Status: Open` — no
  contract change.
- `backlog_kb` could be measured against the mirror (preserves
  meaning) or against the sum of per-entry files (slightly
  larger because of front-matter / separator overhead per file).
  Recommend the mirror.
- `backlog_growth_30d` is a `git log` diff over time; the
  monolithic mirror gives the same shape as today.

Recommend measuring against the mirror to preserve V3 §28.1's
contract. Planner-owned.

### §16.6 — Do trinity context files (CLAUDE / AGENTS / GEMINI)
        need to mention `/.backlog/` / `/.changelog/`?

The pack-root trinity files reference BACKLOG.md / CHANGELOG.md
implicitly via the "Key files to read before working on the
pack" block at pack `CLAUDE.md:28-33`. Under decomposition,
should the trinity files name the directories explicitly or
keep the file-level references? Per the mirror contract (§6),
file-level references continue to work. Per the per-entry-read
capability (§6.3 optional), directory-level references would
unlock per-entry reads in agent prompts.

Recommend keeping file-level references for v11.x; add
directory-level references only if/when per-entry-read becomes
an agent-prompt convention. Planner-owned.

### §16.7 — Project-side `_format.md` collision risk

`project-template/docs/project/changelog/_format.md` (per §3.5)
captures the project CHANGELOG Format Rules block. If a client
project's CHANGELOG diverges from OT's (different Format Rules
shape), the `_format.md` is the only place that needs reconciling.
But it ships from the pack via `init-project.sh` — so it
overwrites at install. Should `_format.md` be ship-once
(install-only) or ship-every-migration (overwrite per BD-088)?

Recommend ship-every-migration with the BD-088 customization-
preservation 3-way text dispatch. Same handling as
`_rules.md`. Planner-owned.

---

## §17 — Final-line marker

ARCHITECTURE-PER-ENTRY-SPLIT-COMPLETE: 2026-05-13 — Per-stream decomposition with shared common shape (`_rules.md` + `_toc.md` + flat per-entry files), monolithic files retained as generated mirrors (V1 §6.3 pattern), v10 entry grammar byte-additive (V3.1-DELTA §3 A2), five stream directories (pack `backlog/` + `changelog/`, project `backlog/` + `implementation-plan/` + `changelog/`), pack-side has no `implementation-plan/` (V3 §28.1:603), project-side `implementation-plan/` decomposes by phase + phase task (V3.3-DELTA §6.4), customization-preserve routes per-entry files to existing `generic` class (no new class), BD-119 framework contract preserved (no new hook; adapter uses existing `migrator_post_dispatch_hook` per v10→v11 precedent), CLAUDE.md "no Resolved section" rule reads trivially under decomposition (no edit proposed), pack `## Resolved — v8` H2 preserved as frozen `_v8-resolved-archive.md`, sequencing constraints flagged (after BD-104 and after BD-131..BD-134 — Batches 7–10 of EXECUTION-PLAN-V11.0.md), maintainability signals 4/5/6 untripped + signal 8 conditionally tripped (advisory wording), version-target placeholder (v11.x or v12.0; planner-owned).
