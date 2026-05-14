---
title: ARCHITECTURE-PER-ENTRY-SPLIT-ADDENDUM
status: design-only
parent: ARCHITECTURE-PER-ENTRY-SPLIT.md
authoritative-design: ARCHITECTURE-V3.md + V3.1/V3.2/V3.3-DELTA.md + IMPLEMENTATION-PLAN.md (v11-research)
audience: v11-implementation chat (Pack Chat, primary v11-dev) → planner pass next
date: 2026-05-13
---

# Per-entry split — architecture addendum

Addresses the Pack Chat addendum brief on
`ARCHITECTURE-PER-ENTRY-SPLIT.md` (1,649 lines). Six sections:
§1 version-target lock (v11.0), §2 phase decomposition reversal
(one file per phase, tasks inline), §3 one-entry-per-file rule +
supporting-file exceptions + explanatory-text home,
§4 bidirectional flat ↔ tracker contract for multi-entity files,
§5 identify-only inventory, §6 final-line marker.

This addendum **supersedes** the parent doc only where it
explicitly says so (§1 reverses parent §15.3 + §17;
§2 reverses parent §3.4 OQ-1; §3 extends parent §4.1 with a
sixth `_rules.md` contract item). All other parent design
decisions stand.

---

## §1 — Version-target lock: v11.0 mandatory + non-reversible

### §1.1 — Lock (reverses parent §15.3 and §17 placeholder)

Per-entry decomposition ships **in v11.0**, not v11.x or v12.0.
v11.0 is the final state for this design. The migrator that
performs the decomposition is the existing v10.1 → v11.0 adapter
at `scripts/migrate-v10-to-v11.sh`, NOT a hypothetical v11.0 →
v11.x migrator.

Three locked properties:

1. **Mandatory.** Every v10.1 client migrating to v11.0 gets
   per-entry decomposition. No opt-out flag, no opt-in flag, no
   escape hatch. Flat-file mode in v11.0 IS the per-entry-
   decomposed shape; the monolithic file is the regenerated
   mirror, not an alternative source of truth.
2. **Non-reversible.** Once a client migrates to v11.0, the
   per-entry tree is the source of truth from migration day
   forward. The monolithic mirror remains for read-site
   compatibility but it is NOT reversible state — it is
   generated state. Clients cannot revert per-entry → monolithic-
   as-source.
3. **v11.0 is the final state.** No "v11.0 → v11.x" deferrals
   in this design. All references to "planner picks the version
   target" or "v11.x or v12.0" in the parent doc are corrected by
   this addendum.

Contrast with tracker mode (per V1 §6.3, cited in parent §6.1
+ §8.1): tracker mode IS bidirectional — `pack tracker disable`
falls back to flat-file mode. Per-entry decomposition is
specifically NOT bidirectional with respect to the
monolithic-as-source past state. The bidirectionality that
remains is the flat-file ↔ tracker boundary (per V1 §6.3),
which §4 of this addendum extends for multi-entity files.

### §1.2 — Parent §15.3 correction (verbatim reversal)

Parent doc §15.3 reads (parent line 1167–1175):

> ### §15.3 — Decomposition is a v11.x feature, not v11.0
> This design is too large to ship in v11.0 alongside Batches 1–13
> of `EXECUTION-PLAN-V11.0.md`. It is a v11.x feature (v11.1 or
> later). The version target is the planner's call; this design
> is version-target placeholder per §0. If the planner pass
> elects to defer to v12.0, the design remains valid …

This paragraph is **reversed** by this addendum. Replace with:

> Decomposition ships in v11.0 as part of the v10.1 → v11.0
> migration. It is sequenced alongside the existing
> `migrate-v10-to-v11.sh` post-dispatch operations (BD-104
> rename, BD-042 relocation, v11 artifact installs, BD-144
> capability translation), per §1.3 below. Parent §15.1
> (sequencing relative to BD-104 — recommend AFTER) and
> parent §15.2 (sequencing relative to Batches 7–10 — hard
> constraint AFTER) still apply, both within v11.0 scope.

### §1.3 — BD-119 integration correction (refines parent §10)

Parent §10 names `migrator_post_dispatch_hook` as the host for
decomposition, citing the v10→v11 adapter precedent. Verified:
the adapter's hook currently runs 5 sub-operations at
`scripts/migrate-v10-to-v11.sh:144-148`:

```
_v10_to_v11_rename_implementation_plan       # BD-104
_v10_to_v11_relocate_legacy_docs              # BD-042
_v10_to_v11_install_v11_artifacts             # additive v11 installs
_v10_to_v11_rename_python_architecture_refs   # BD-144 etc.
_v10_to_v11_translate_capability_tokens       # BD-144 capability tokens
```

The hook has architectural room for a 6th sub-operation —
the function calls are sequential, idempotent under
`_migrator_is_dryrun` (lines 140–143), and follow a uniform
naming convention (`_v10_to_v11_<verb>`). The decomposition
step adds one new function at the same level —
provisional name `_v10_to_v11_decompose_streams` (planner-
owned naming; design-level reservation only). Sequencing
inside the hook:

1. `_v10_to_v11_rename_implementation_plan` — first, so the
   per-entry decomposition's project-side
   `implementation-plan/` source filename is already
   hyphenated when the decompose step reads it (resolves
   parent §15.1's BD-104 sequencing constraint within the
   hook itself).
2. `_v10_to_v11_relocate_legacy_docs` — second, current
   position.
3. `_v10_to_v11_install_v11_artifacts` — third, current
   position.
4. `_v10_to_v11_rename_python_architecture_refs` — fourth,
   current position.
5. `_v10_to_v11_translate_capability_tokens` — fifth,
   current position.
6. **NEW** `_v10_to_v11_decompose_streams` — sixth and last.
   Runs AFTER all monolithic-file mutations (rename,
   relocate, install, token translation) have settled, so
   the decompose step reads the final v11-shape monolithic
   files and emits the per-entry tree + regenerated mirror.

Rationale for last-in-sequence: anything upstream that
mutates monolithic content (e.g., capability-token translation
inside BACKLOG body text) must complete before the
decomposition reads, so the per-entry files capture the final
v11-translated text byte-for-byte.

The framework contract is unchanged (no new hook, no new
manifest entry, no new stage). Maintainability signal 8
("migrator behavior change") is the same conditionally-tripped
status as parent §13.4 — the post-report-hook advisory text
needs one new paragraph explaining the decomposition; that
paragraph is the only signal-8 footprint.

### §1.4 — Parent §17 final-line marker correction

The parent doc's §17 marker contains the phrase "version-target
placeholder (v11.x or v12.0; planner-owned)" — that clause is
**superseded** by this addendum. The intended state is "v11.0
mandatory, non-reversible, ships with the v10.1 → v11.0
migration via the existing `migrate-v10-to-v11.sh` adapter's
post-dispatch hook." The parent doc's §17 line is not edited
(architect prompt §0 forbids edits to any file other than this
addendum); this §1.4 is the authoritative correction the
planner pass reads.

---

## §2 — Phase decomposition unit reversal (one file per phase)

### §2.1 — Reversal of parent §3.4

Parent §3.4 resolved Open Question 1 as:
"project-side decomposition unit = phase epic + phase task. One
file per `phase-N` (e.g. `phase-0.md`) for the phase epic; one
file per `phase-N.M` (e.g. `phase-0.1.md`) for each phase task."

Pack Chat reverses this. The new decision:

**DECISION.** Project-side `implementation-plan/` decomposes
ONE FILE PER PHASE. The phase file contains the phase epic AND
all its phase tasks inline.

- One file per `phase-N` (e.g. `phase-0.md`).
- The phase file body contains the H2 phase heading
  (`## Phase 0 — <title>`), `**Goal**:`, `**Prerequisite**:`,
  the `---` separator, `### Tasks` with all `#### N.M — <title>`
  task content inline, then `### Verification`, `### Agent`,
  `### Risks` H3 sections.
- There are **NO** `phase-N.M.md` per-task files.

This matches the v10 OT shape verbatim (per
`RESEARCH-PER-ENTRY-SPLIT.md` §3 lines 348–401 and
`ADDENDUM` §3 lines 85–112): each `## Phase NN` block already
contains its `### Tasks` H3 with `#### N.M — <title>`
sub-headings inline. The decomposition unit is the
H2-bounded block, which is exactly one phase including all
its tasks.

### §2.2 — Reasoning

1. **Discoverability.** Per-task files fragment search and
   directory listing. With ~28 phases and an average of 4
   tasks per phase (OT live shape per
   `RESEARCH-PER-ENTRY-SPLIT.md` §3 lines 357–401), per-task
   decomposition would produce ~140 files in a single
   directory; per-phase decomposition produces ~28. The
   smaller listing is more navigable for humans and for
   `find`/`grep`/agent reads.
2. **Brittleness.** Each additional file is a failure mode
   for regenerators, `_toc.md`, validators (see identify-only
   item §5.h), and cross-references. Halving file count
   halves that surface.
3. **Flat files are not an issue tracker.** A flat file is
   for human reading and direct grep. Multi-issue tracker
   mapping (1 phase ↔ N tracker issues) is handled by the
   tracker forward/reverse contract, per §4 of this
   addendum. The flat-file shape should be optimized for
   the flat-file use case, not for tracker symmetry.
4. **Identifier scheme preserved.** V3.3-DELTA §6.4 (lines
   360–370) defines `phase-N` and `phase-N.M` as first-class
   identifiers. Under this revised decomposition, the
   `<!-- pack-id: phase-N.M -->` body marker (V1 §6.2,
   cited in V3.3-DELTA §6.4 line 369) still lives inside the
   phase file alongside the `#### N.M — <title>` heading.
   The identifier remains addressable; only the file
   granularity changes.
5. **Simple rule.** "Each entry in a flat file becomes one
   file in the per-entry tree." Phases are entries in
   `IMPLEMENTATION-PLAN.md`; tasks are sub-units within a
   phase entry. The rule is uniform across all 5 streams
   under this addendum — see §3.1 for the per-stream
   restatement.

### §2.3 — Filename convention (per phase only)

- Filename: `phase-N.md` (e.g. `phase-0.md`, `phase-12.md`).
- No `phase-N.M.md` files.
- Filename regex admitted in
  `implementation-plan/_rules.md`: `^phase-\d+\.md$`.

### §2.4 — Forward-parser implications

V3.3-DELTA §4.1 (lines 187–192) specifies the forward parser
for `IMPLEMENTATION-PLAN.md ### Tasks`. Under per-phase
decomposition:

- The forward parser today reads the monolithic
  `IMPLEMENTATION-PLAN.md` and walks `## Phase NN` H2 blocks,
  then walks `### Tasks` → `#### N.M` task sub-headings
  inside each block (per
  `RESEARCH-PER-ENTRY-SPLIT.md` §8 lines 793–797 + V3.3-DELTA
  §4.1).
- Under per-phase decomposition, the parser operates on the
  **regenerated monolithic mirror** (the same byte shape as
  v10) per parent §6.1, so the parser is unchanged. The
  per-phase file shape is invisible to the forward parser.
- Multi-issue emission (1 phase file → 1 phase-epic issue +
  N phase-task issues) is the existing V3.2 §2 / V3.3-DELTA
  §2 contract — one issue per phase epic, one issue per
  phase task — preserved verbatim. The 1-to-N mapping is
  identical to the v10 monolithic case because the mirror is
  byte-identical to v10.

This is the same "decomposition is invisible to existing
read paths" property parent §6.1 establishes for
BACKLOG.md. The per-phase shape is a write-side and human-
read-side concern; the tracker-forward parser does not see
it.

### §2.5 — Reverse-emitter implications

V3.3-DELTA §4.2 (lines 193–196) specifies the reverse
emitter. Per
`RESEARCH-PER-ENTRY-SPLIT.md` §8 lines 838–840,
`_tmr_emit_implementation_plan()` at
`scripts/lib/tracker-migrate-reverse.sh:485` emits the full
`IMPLEMENTATION-PLAN.md` skeleton.

Under per-phase decomposition, reverse-emit produces the
monolithic mirror (unchanged contract), and a post-emit
decomposition step splits it into `phase-N.md` files. The
split walks `## Phase NN` H2 blocks (each block = one
file). The split is byte-identity-preserving (parent §6.2
mirror generator contract): regenerate-mirror(split(mirror))
= mirror.

The 1-to-N tracker-issue → phase-file reconstitution is
detailed in §4 of this addendum.

### §2.6 — Cascading corrections to parent §3.4, §5.1, §11.1, §11.2

Parent §3.4 is reversed by this §2. Specifically:

- "phase-N.md + phase-N.M.md" → "phase-N.md only."
- "Per-entry contents — phase epic" + "Per-entry contents —
  phase task" sub-paragraphs collapse into one: the phase
  file IS the phase epic AND tasks inline.
- "The `### Tasks` H3 from the legacy file becomes an
  *index* in the phase epic body" — REMOVED. The
  `### Tasks` H3 remains inline with full task content,
  identical to v10 OT shape.

Parent §5.1's `_toc.md` schema for project-implementation-
plan reads (parent lines 643–646):

> Project-implementation-plan: by phase number (`## Phase 0`,
> `## Phase 1`, …); each phase block lists the phase-epic file
> and its phase-task children in `phase-N.M` order with the
> V3.3-DELTA §6.3 marker (`🚧`, `✅`, `➡`).

Under this addendum, the `_toc.md` schema simplifies: each
phase file is listed once (`- phase-N — <title>` with file-
path link); phase tasks are not separately indexed in
`_toc.md` because they do not have their own files.
Per-phase status (from the `🚧` / `✅` / `➡` markers per
V3.3-DELTA §6.3 lines 351–356) on the H2 heading inside the
phase file is the index signal.

Parent §11.1 table row "Project-side `implementation-plan/`
decomposes by phase + phase task" → corrected to "decomposes
by phase only; phase tasks remain inline within the phase
file."

Parent §11.2 surface-count table row
"`implementation-plan/` Yes (phase-N + phase-N.M)" →
corrected to "Yes (phase-N only; phase tasks inline)."

These cascading corrections are stated here; the parent doc
is not edited.

---

## §3 — One-entry-per-file rule + supporting-file exceptions

### §3.1 — Operationalized rule per stream

The single uniform rule: **each entry in a flat file becomes one
file in the per-entry tree.** Restated per stream:

| Stream | Entry unit | Filename pattern |
|---|---|---|
| pack `backlog/` | one BD-NNN block | `BD-NNN.md` (e.g. `BD-156.md`) |
| pack `changelog/` | one version block (e.g. all of v11.0 incl. all scope buckets inline) | `vN.M.md` (e.g. `v11.0.md`) |
| project `backlog/` | one TD-NNN block | `TD-NNN.md` (e.g. `TD-001.md`) |
| project `implementation-plan/` | one phase (epic + tasks inline; per §2 of this addendum) | `phase-N.md` (e.g. `phase-0.md`) |
| project `changelog/` | one date-phase block | `YYYY-MM-DD-phase-NN.md` (e.g. `2026-04-20-phase-35.md`) |

**Confirmation — pack `changelog/` entry unit.** Parent §3.2
already chose "version block, not scope-bucket" as the entry
unit, with scope buckets remaining intra-entry. This addendum
confirms that decision under the uniform rule. Per
`ADDENDUM` §9 lines 309–313, the v11.0 block contains 3 scope
buckets (`**Scope A — …**` at line 12, `**Scope B — …**` at
line 43, `**Scope C — …**` at line 124 of `CHANGELOG.md`),
and scope buckets exist only in v11 per
`ADDENDUM` §9 lines 327–342 — so they are not a universal
unit. The version block is the universal unit. All scope
buckets for v11.0 live inline in `v11.0.md`.

### §3.2 — Supporting-file exceptions

Supporting files are NOT entries. They are leading-underscore
filenames in stream directories, admitted by `_rules.md` per
stream. The full list per stream:

| Stream | Supporting files admitted |
|---|---|
| pack `backlog/` | `_rules.md`, `_toc.md`, `_intro.md` (see §3.4), `_v8-resolved-archive.md` |
| pack `changelog/` | `_rules.md`, `_toc.md`, `_intro.md` |
| project `backlog/` | `_rules.md`, `_toc.md`, `_intro.md` |
| project `implementation-plan/` | `_rules.md`, `_toc.md`, `_intro.md` |
| project `changelog/` | `_rules.md`, `_toc.md`, `_intro.md`, `_format.md` |

Notes:
- `_v8-resolved-archive.md` is **pack-side `backlog/` only**, per
  parent §6.2 (the v8 historical `## Resolved — v8 (March 2026)`
  H2 at pack `BACKLOG.md:2248` per `ADDENDUM` §8 line 297 — the
  only such H2). No project-side analog.
- `_format.md` is **project-side `changelog/` only**, per parent
  §3.5 (the OT `## Format Rules` H2 at OT
  `docs/project/CHANGELOG.md:7` per
  `RESEARCH-PER-ENTRY-SPLIT.md` §3 lines 408–421). No pack-side
  analog.
- `_intro.md` is new — added by §3.4 below as the explanatory-
  text home (resolves Pack Chat Q2).

### §3.3 — Sixth `_rules.md` contract item (extends parent §4.1)

Parent §4.1 names five things `_rules.md` declares. This
addendum adds a **sixth**:

6. **Supporting-file basenames admitted in this directory.**
   The explicit list of leading-underscore filenames the
   stream admits. Generators (mirror generator + `_toc.md`
   regenerator) MUST treat the supporting-file list as
   distinct from the entry-file regex: supporting files are
   read for control state but are NOT enumerated as entries
   in the mirror or in `_toc.md`'s entry sections.

The supporting-file list per stream is exactly the table in
§3.2. `_rules.md` declares it as a literal basename list, not
a regex (the list is small and stable; regex would over-
generalize).

### §3.4 — Explanatory text home (Pack Chat Q2 resolved)

Pack Chat Q2 surfaced an unresolved storage question: parent
§6.2 said the monolithic preamble + "How to use this file"
block is preserved as "static generator templates (sourced
from `_rules.md`'s referenced authorities, not re-derived
per-run)" but did not name the storage file.

**Decision: option (b) — `_intro.md` per stream directory.**

Rationale:
- Preserves `_rules.md`'s pointer-only-and-short property
  from parent §4.1. Eliminating option (a).
- Keeps explanatory text version-controllable per stream
  (different streams have different intro shapes —
  pack `BACKLOG.md` preamble at `BACKLOG.md:1-7` cites
  METHODOLOGY Part 7; OT project `BACKLOG.md` preamble at
  `docs/project/BACKLOG.md:1-6` is project-specific). A
  shared per-stream `_intro.md` is the natural per-stream
  home. Eliminating option (c).
- The `_intro.md` is *part of pack product* on the project
  side (ships from `project-template/`) and *part of pack
  self* on the pack side (lives in the pack repo). It is
  not a planner-only build artifact.

`_intro.md` contents per stream:
- **pack `backlog/_intro.md`** — captures pack
  `BACKLOG.md:1-7` preamble (`# Backlog` H1 + "All planned
  improvements …" + "Items use BD-NNN identifiers …" +
  "Format follows the standard BACKLOG item format from
  METHODOLOGY.md Part 7." reference) and pack
  `BACKLOG.md:9-20` "## How to use this file" H2 block
  (commit-message format, Status flip on resolution,
  Resolution-field rules for Cancelled/Deprecated, blocker-
  target-version pattern, BD-NNN sequencing, "ships in the
  repo so agents can read it").
- **pack `changelog/_intro.md`** — captures pack
  `CHANGELOG.md:1-6` preamble ("All notable changes to the
  AI Agent Config Pack are documented here. Each version is
  available as a git tag").
- **project `backlog/_intro.md`** — captures project
  `docs/project/BACKLOG.md:1-6` preamble +
  `docs/project/BACKLOG.md:485-490` "How to use this file"
  block (per `RESEARCH-PER-ENTRY-SPLIT.md` §3 lines 276–301).
  Note this is project-template canonical; client-project
  customizations route through BD-088 customization-preserve
  (parent §9.1).
- **project `implementation-plan/_intro.md`** — captures the
  preamble at OT `docs/project/IMPLEMENTATION_PLAN.md:1-7`
  per `RESEARCH-PER-ENTRY-SPLIT.md` §3 lines 351–356.
- **project `changelog/_intro.md`** — captures the preamble
  at OT `docs/project/CHANGELOG.md:1-3` per
  `RESEARCH-PER-ENTRY-SPLIT.md` §3 lines 405–407.
  (The `## Format Rules` H2 at OT
  `docs/project/CHANGELOG.md:7-39` lives separately in
  `_format.md` per parent §3.5 — `_format.md` is the rules
  block; `_intro.md` is the preamble.)

Mirror generator behavior:
- Reads `_intro.md` (if present) and emits its content
  verbatim at the top of the regenerated monolithic file,
  before any entry content.
- `_intro.md` is regenerated NEVER — it is hand-edited only,
  routed through BD-088 customization-preserve like any
  other generic text file (parent §9.1). Version-control
  applies normally.
- If `_intro.md` is missing, the generator emits a minimal
  default preamble (the H1 + a "see `_rules.md` for entry
  format" pointer) — degraded but functional.

### §3.5 — `_v8-resolved-archive.md` clarification

Parent §6.2 introduced `_v8-resolved-archive.md` (pack-side
`backlog/` only) as a frozen literal block sourced from a
one-time file. To prevent confusion with `_intro.md`:

- `_intro.md` is preamble + "how to use" — pre-entries.
- `_v8-resolved-archive.md` is the frozen `## Resolved — v8
  (March 2026)` H2 from pack `BACKLOG.md:2248`-onward — a
  mid-file historical section preserved verbatim.
- Both are supporting files (no entry shape, leading
  underscore).
- The mirror generator emits in this order: `_intro.md` content
  → all `BD-NNN.md` entries (sort order per `_toc.md`
  partitioning) → `_v8-resolved-archive.md` content as the
  trailing frozen-historical block.
- `_v8-resolved-archive.md` is never edited — the rule
  enforced via BD-088 customization-preserve catching any
  drift (per parent §6.2). At the v10.1 → v11.0 migration,
  the decompose step (per §1.3 of this addendum) extracts
  the v8 block verbatim and writes
  `_v8-resolved-archive.md`; subsequent regenerations are
  byte-stable.

### §3.6 — Generator contract update

The mirror generator emits the regenerated monolithic file
in this concatenation order (per stream):

```
[_intro.md content]
[entry files in sort order]
[_v8-resolved-archive.md content]    ← pack backlog/ only
```

The `_toc.md` regenerator emits the index over only the
entry files — supporting files are excluded from the entry
index. This is what the sixth `_rules.md` contract item
(§3.3) enforces.

---

## §4 — Bidirectional flat ↔ tracker contract for multi-entity files

### §4.1 — Problem statement

The per-entry-split migration is **one-way** (per §1 of this
addendum: v10.1 → v11.0 mandatory, non-reversible). The
flat-file ↔ tracker boundary, however, **remains bidirectional**
per V1 §6.3 (preserved per V3 §0.5; cited in parent §6.1
+ §8.1).

A multi-entity entry file (one phase file containing one phase
epic + N phase tasks inline per §2 of this addendum) maps to
**multiple tracker issues**: per V3.3-DELTA §6.3 (lines
341–360) and §6.4 (lines 360–370):

- One issue per phase epic (`<!-- pack-id: phase-N -->` body
  marker, `phase-epic` label).
- One issue per phase task (`<!-- pack-id: phase-N.M -->`
  body marker, `phase-task` + `phase-N` labels).

So `phase-0.md` (one flat file, one entry per the §3.1 rule)
↔ 1 phase-epic issue + N phase-task issues. This is the
canonical multi-entity case.

**Other multi-entity cases:**
- **Pack `changelog/v11.0.md` with N scope buckets.** Today
  no tracker tracks scope-buckets-as-issues per
  `RESEARCH-PER-ENTRY-SPLIT.md` §8 (function inventory) and
  `ADDENDUM` §7 lines 262–288. `_tmf_regen_mirror()` and the
  reverse-emit functions handle CHANGELOG as whole-file
  content, not per-bucket. So pack-changelog files are
  multi-bucket but NOT multi-entity from tracker's
  perspective. The contract below applies to project
  `implementation-plan/` only.
- **All other streams are 1-to-1.** Pack `backlog/BD-NNN.md`
  ↔ 1 issue. Project `backlog/TD-NNN.md` ↔ 1 issue. Pack
  `changelog/vN.M.md` ↔ no tracker mapping today (CHANGELOG
  is emitted as a skeleton per
  `_tmr_emit_changelog()` at `tracker-migrate-reverse.sh:553`
  per `RESEARCH-PER-ENTRY-SPLIT.md` §8 lines 842–844). Project
  `changelog/YYYY-MM-DD-phase-NN.md` ↔ no tracker mapping
  today (same).

The 1-to-N case is **scoped to project-side
`implementation-plan/phase-N.md` files only**.

### §4.2 — Forward contract (flat → tracker)

The forward emitter parses the regenerated monolithic
`IMPLEMENTATION-PLAN.md` mirror (per V3.3-DELTA §4.1 lines
187–192, implemented by `tmf_parse_implementation_plan()` at
`scripts/lib/tracker-migrate-forward.sh:399` per
`RESEARCH-PER-ENTRY-SPLIT.md` §8 lines 793–797). The mirror
is byte-identical to v10 shape (parent §6.1 + §6.2 contract),
so the parser is unchanged. Behavior:

1. Parser walks `## Phase NN` H2 blocks in the mirror.
2. For each H2 block, the parser identifies the phase-epic
   metadata (`**Goal**:`, `**Prerequisite**:`,
   `### Verification`, `### Agent`, `### Risks`) and the
   `### Tasks` H3 sub-block.
3. Emits 1 issue for the phase epic. Issue title = `Phase N
   — <title>`; body markers per V3.3-DELTA §6.4 (`<!--
   pack-id: phase-N -->`) and §6.5 (`<!-- template_version:
   phase-epic-v11.0 -->`); label `phase-epic`.
4. For each `#### N.M — <title>` task sub-heading inside
   `### Tasks`, emits 1 issue. Issue title = `Phase N.M —
   <title>`; body markers (`<!-- pack-id: phase-N.M -->`,
   `<!-- template_version: phase-task-v11.0 -->`); labels
   `phase-task`, `phase-N`.
5. Records the 1-to-N mapping in the tracker's id-map
   (today: `.pack-tracker/id-map.json` — name and exact
   schema is V1 §6.x contract, not respecified here).

The forward parser's existing per-phase walk already does
steps 1–4 today (per V3.3-DELTA §4.1 lines 187–192). Step 5
already records per-issue id-mapping. The new requirement
is making the mapping **explicitly 1-to-N-aware** so the
reverse emitter can reconstruct the source file (§4.3
below).

### §4.3 — Reverse contract (tracker → flat)

The reverse emitter today produces a monolithic
`IMPLEMENTATION-PLAN.md` skeleton via
`_tmr_emit_implementation_plan()` at
`scripts/lib/tracker-migrate-reverse.sh:485` per
`RESEARCH-PER-ENTRY-SPLIT.md` §8 lines 838–840. Per
V3.3-DELTA §4.2 (lines 193–196), it reconstructs the
hyphenated form. Behavior under per-phase decomposition:

1. Reverse emitter fetches all open + closed phase-epic
   issues + all phase-task issues from the tracker
   (filtered by `phase-epic` and `phase-task` labels per
   V3.3-DELTA §6.3 lines 351–356).
2. Groups phase-task issues by their `phase-N` label.
3. Emits the monolithic `IMPLEMENTATION-PLAN.md` mirror,
   one `## Phase NN` H2 block per phase-epic issue, with
   the grouped phase-task issues rendered inline as
   `#### N.M — <title>` sub-headings under `### Tasks`.
4. Post-emit, the decompose step (per §1.3 of this
   addendum) splits the mirror into per-phase files
   (`phase-N.md`).
5. Round-trip verification: regenerate-mirror(per-phase
   files) MUST equal the just-emitted mirror byte-for-byte.

### §4.4 — Round-trip byte-identity verification

Extends parent §8.4. The two round trips:

- **Flat ↔ tracker:** forward(parse(mirror))
  → tracker state → reverse(emit) → mirror'.
  mirror == mirror' for v10-grammar fields (V1 §6.7
  invariant, preserved by V3.1-DELTA §3 A2).
- **Monolithic ↔ per-entry:** decompose(mirror) →
  per-entry tree → regenerate-mirror(per-entry tree) →
  mirror'. mirror == mirror' (parent §6.2 + §8.4 contract).

Composed: starting from `phase-N.md` files,
regenerate-mirror → mirror, forward(parse(mirror)) →
tracker state, reverse(emit) → mirror'',
decompose(mirror'') → `phase-N.md`' files. The starting
and ending `phase-N.md` sets must be byte-identical. This is
the contract Pack Chat asks for: forward → reverse →
forward produces a phase file byte-identical to the original
input.

The verification harness extension is the same library
helper invoked by both round-trip tests (parent §5.2 / §6.2
library-helper pattern; V3.1-DELTA §3 line 246's
`scripts/tracker-migrate.sh roundtrip-test` extension is the
existing entry point).

### §4.5 — Existing tracker functions to extend (identify-only)

Per Pack Chat brief §4 — name, do not fix. These are the
existing functions whose behavior must be reviewed under the
1-to-N contract:

- `tmf_parse_implementation_plan()` at
  `scripts/lib/tracker-migrate-forward.sh:399`. Today
  parses the whole `IMPLEMENTATION-PLAN.md` into a phase-
  array JSON (per `RESEARCH-PER-ENTRY-SPLIT.md` §8 lines
  793–797). The JSON shape must be 1-to-N-aware (one phase
  array element per phase, with a nested tasks array per
  phase).
- `tmf_compose_issue_body()` at
  `scripts/lib/tracker-migrate-forward.sh:459` per
  `RESEARCH-PER-ENTRY-SPLIT.md` §8 lines 798–800. Today
  composes a single GH issue body for a parsed BACKLOG
  entry. Must extend to compose phase-epic-vs-phase-task
  bodies per V3.3-DELTA §6.5 D-18 carrier matrix (lines
  371–382).
- Downstream forward emitters (the chain that consumes
  `tmf_parse_implementation_plan()` output) — verify the
  1-to-N emission ordering is deterministic.
- `_tmr_emit_implementation_plan()` at
  `scripts/lib/tracker-migrate-reverse.sh:485`. Must
  reconstruct the phase-epic + inline-tasks shape (not
  a phase-epic-only skeleton as today's "skeleton" note at
  line 547–552 of that file suggests).
- The id-map schema (in `.pack-tracker/` per V1 §6.x
  contract; exact filename not respecified here). Must
  support 1-to-N: one flat-file entry (phase) ↔ one
  phase-epic tracker ID + N phase-task tracker IDs. Today
  the id-map shape per V1 / V3.x is 1-to-1 (entry ID ↔
  tracker issue ID); the 1-to-N case requires a phase →
  {epic-issue-id, [task-issue-id-1, task-issue-id-2, …]}
  shape. Schema specifics belong to the planner.

Per identify-only convention: these are named, not solved.
Fix-design ownership: primary chat v11-dev planner pass and
the BD-131..BD-134 tracker repair scope (parent §15.2).

### §4.6 — Scope-bucket sub-units (clarification)

Pack Chat brief asked: "Same shape may apply to other
multi-sub-unit entry files (pack-changelog versions with N
scope buckets, if any tracker tracks scope-buckets-as-issues
— verify and resolve)."

Verified. Per `RESEARCH-PER-ENTRY-SPLIT.md` §8 lines 842–844
and `ADDENDUM` §7 lines 262–288, the tracker reverse-emit
contract today treats CHANGELOG as a whole-file skeleton
emit (`_tmr_emit_changelog()` at line 553 of
`tracker-migrate-reverse.sh`; "Real audit-log walking … is
deferred … CHANGELOG from tracker state in v11.0" per the
function note at lines 547–552). Scope buckets are NOT
tracker-tracked. So `v11.0.md` (one entry, multiple scope
buckets inline) is 1-to-1 from tracker's perspective —
the buckets are intra-entry organization, not entities.

No 1-to-N contract needed for pack `changelog/`. The
1-to-N contract scope is project `implementation-plan/`
only, as stated in §4.1.

---

## §5 — Identify-only inventory

Per Pack Chat brief §5: describe each concern in 2–4 sentences
with file:line citations where applicable; do NOT propose
solutions; mark each "OWNED BY: primary chat v11-dev architect
/ planner pass." The purpose is inventory completeness.

### §5.a — Workflow discovery of `_rules.md`

How do agents, skills (pack-startup at `.claude/skills/pack-
startup/SKILL.md:17-21` and per-CLI mirrors;
project-template/skills/pm-startup/SKILL.md:69-87 and per-CLI
mirrors), `validate-pack.py` (the Check 3 `check_td_tbd_sentinels`
function at line 262 per `RESEARCH-PER-ENTRY-SPLIT.md` §7), and
other workflow code paths know to read `_rules.md` for
stream-contract resolution? Today these workflows hardcode the
monolithic file paths. Under decomposition the directory's
`_rules.md` is the authority on filename regex, supporting-file
list (§3.3), and entry contract — but nothing in the current
workflow surface discovers it.

OWNED BY: primary chat v11-dev architect / planner pass.

### §5.b — `_toc.md` runtime invocation

Parent §5.2 specifies the `_toc.md` regenerator contract
(input/output/idempotency/determinism) but does not name the
runtime trigger. Three plausible triggers: (1) writer-side
hook (every Pack Chat / PM Chat write fires the regenerator);
(2) pre-commit hook (`.git/hooks/pre-commit` in pack repo +
client projects); (3) migrator-only (regenerate at v10→v11
migration only). The choice affects when `_toc.md` is allowed
to drift and how stale-TOC is detected (see §5.d).

OWNED BY: primary chat v11-dev architect / planner pass.

### §5.c — Mirror generator runtime invocation

Same question as §5.b for the mirror generator contract in
parent §6.2. The mirror generator and `_toc.md` regenerator
share the same trigger surface — they fire together (parent
§7.2 atomicity) — so the trigger choice applies to both. Same
three plausible triggers (writer-side, pre-commit, migrator-
only) per §5.b. The choice has user-facing implications:
under writer-side, every per-entry edit immediately updates
the mirror in the working tree; under pre-commit, the mirror
lags edits until commit time; under migrator-only, the mirror
is fixed in shape between migrations (probably unworkable —
mentioned for completeness).

OWNED BY: primary chat v11-dev architect / planner pass.

### §5.d — Stale-mirror / stale-TOC detection

Parent §6.4 starts the staleness contract ("If the mirror is
stale … `validate-pack.py` can grow a new staleness check
… see §13 for the defense of NOT adding that check in
v11.0") but does not finish. What happens when a user hand-
edits the regenerated mirror (`/BACKLOG.md` or
`/CHANGELOG.md`) or hand-edits `_toc.md` between regenerations?
Three plausible responses: (1) silent overwrite at next
regenerator run (preserves contract; loses user intent); (2)
warning at next regenerator run (preserves contract; user
notices); (3) refuse to regenerate when mirror/TOC has
divergent edits (preserves user edits; breaks contract).

OWNED BY: primary chat v11-dev architect / planner pass.

### §5.e — Concurrent-write safety

Pack Chat and PM Chat may both write per-entry files (e.g.
the user has both chats open in different terminals, both
edit BACKLOG simultaneously). The regenerator could fire on
inconsistent intermediate state, producing a mirror that
reflects only one of the two writes. Today the monolithic
`BACKLOG.md` has the same risk (concurrent file-open in two
chats); under decomposition the surface widens to include the
regenerator timing. No file-lock, no atomic-snapshot, no
queue is specified by this design.

OWNED BY: primary chat v11-dev architect / planner pass.

### §5.f — Cross-reference integrity

Entries reference each other via `Blockers: BD-NNN` /
`Unblocks: TD-NNN` / inline prose references (per
`RESEARCH-PER-ENTRY-SPLIT.md` §2 lines 195–204 + §4 line 461
cross-reference syntax inventory). Today, since all
references live in one BACKLOG.md, dangling references are
grep-detectable in one pass. Under per-entry decomposition,
the references span N files; renames, moves, or deletes of
entry files silently break references. No validator covers
this today (`validate-pack.py` Check 3 only catches
TD-TBD sentinels per `RESEARCH-PER-ENTRY-SPLIT.md` §7).

OWNED BY: primary chat v11-dev architect / planner pass.

### §5.g — Test fixture migration

`test-fixtures/v10-realistic-ot/` per `README.md:230` ships a
monolithic v10-shape BACKLOG.md. Under v11.0 mandatory non-
reversible migration (§1 of this addendum), every fixture-
derived test path runs through the decomposition step. The
new v11-realistic-ot fixture per `README.md:232` (and
BD-160 in pack `BACKLOG.md:1399` per the BD-160 entry which
extends `_build_realistic_for_version v11` case dispatch)
should ship pre-decomposed. Existing fixture wiring
(BD-114 / BD-115 / BD-160 per the BD-160 Blockers line at
pack `BACKLOG.md:1402`) is impacted — the wiring depends
on the decomposition step running at migration time.

OWNED BY: primary chat v11-dev architect / planner pass.

### §5.h — Validator new-checks needed (candidate list)

Likely candidates for new `check_*` functions in
`scripts/validate-pack.py` (each is a maintainability-signal-4
trip per `ADDENDUM` §5 lines 152–182 verbatim citation;
this design defers all of them per parent §13.1):

- **Mirror-in-sync.** `BACKLOG.md` matches
  regenerate-mirror(`/.backlog/`) byte-for-byte. Similar for
  the other 4 streams. Five checks total or one
  parameterized check.
- **TOC-in-sync.** `_toc.md` matches regenerate-TOC(directory
  contents) byte-for-byte, per stream.
- **`_rules.md` exists per stream directory.** Each of the 5
  stream directories must have a `_rules.md`.
- **Per-entry filename conformance.** Every non-supporting
  file in a stream directory matches the
  `_rules.md`-declared filename regex.
- **Cross-reference integrity (per §5.f).** Every
  `Blockers:` / `Unblocks:` BD-NNN / TD-NNN reference
  resolves to an existing entry file.
- **`_v8-resolved-archive.md` byte-stable.** Per parent §6.2,
  the v8 archive is frozen; any drift surfaces as a
  validator failure.

OWNED BY: primary chat v11-dev architect / planner pass.

### §5.i — Read-site audit completeness

Parent §14 names the agent / skill / chat-doc read sites
(PACK-CHAT.md, PM-CHAT.md, pack-startup ×3, pm-startup ×3,
pack-* agents ×3 CLIs, project coder/repo-ops/auditor/auditor-
docs ×3 CLIs). The FULL inventory of monolithic-stream-file
references across the pack is broader. Plausibly affected
(MOST CAN STAY because mirror is byte-identical):
- `supporting-docs/MERGE-STRATEGY.md` (BD-088 per-file
  customization-preserve matrix; references BACKLOG /
  CHANGELOG / IMPLEMENTATION-PLAN by name)
- `supporting-docs/MIGRATION-v10-to-v11.md` (the upgrade
  guide)
- `README.md` (the version table and Repository Layout
  reference BACKLOG.md / CHANGELOG.md at pack root and the
  project-template tree)
- `project-template/docs/pack/PLATFORM-SKILLS.md`
- `supporting-docs/METHODOLOGY.md` Part 7 (BACKLOG entry
  format authority — referenced from pack `BACKLOG.md:5`)
- Audit-methodology rule scopes — any auditor agent or
  audit-methodology doc enumerating PM-only files
- `AUDIT-*.md`, `IMPLEMENTATION-REPORT-*.md`,
  `PACK-REVIEW-*.md` workflow artifacts (mostly in
  `maintenance-docs/v11-implementation/` and
  `maintenance-docs/v11-research/`) that cite specific
  BACKLOG / CHANGELOG entries by file name
- `.github/ISSUE_TEMPLATE/work-item.yml` /
  `inbound.yml` (issue forms that map to BD/TD entries
  per V3.3-DELTA §6.1)
- `scripts/init-project.sh` and `scripts/add-capability.sh`
  may reference the stream files at project-init time

The audit is to enumerate ALL such references, classify each
as "stays (reads mirror)" or "must update wording (reads
per-entry)." Most will stay.

OWNED BY: primary chat v11-dev architect / planner pass.

### §5.j — Skill update inventory (per-entry-targeted reads)

The pack-startup and pm-startup skills currently direct
agents to "Read `BACKLOG.md` in full." per
`.claude/skills/pack-startup/SKILL.md:19`,
`.codex/skills/pack-startup/SKILL.md:19`,
`.gemini/commands/pack-startup.toml:16`,
`project-template/skills/pm-startup/SKILL.md:69-70`, and the
per-CLI project mirrors (per `ADDENDUM` §6 lines 186–256).
Under decomposition, agents in context-budget-sensitive flows
(BD-triage, single-entry-edit, single-version-CHANGELOG-edit)
could read only the relevant per-entry file
(`/.backlog/BD-NNN.md`) instead of the full mirror. The
inventory is whether these skill directives should grow a
new "Or, when you only need one entry, read
`/.backlog/<ID>.md` directly" capability addition (per
parent §6.3 optional-row recommendation) and which skills
specifically should change wording. Parent §14.1 and §14.2
enumerate the read sites; this item is about which of those
sites grow per-entry-targeted wording, not whether the
mirror-read continues to work.

OWNED BY: primary chat v11-dev architect / planner pass.

### §5.k — STATUS.md interaction

STATUS.md is out of scope for decomposition per parent §2
locked-decisions list and per `RESEARCH-PER-ENTRY-SPLIT.md`
§9 lines 902–913 + `ADDENDUM` §12 lines 439–488. However,
STATUS.md update flows reference entry counts (e.g. OT
`docs/project/STATUS.md` `## Active Backlog` table at line
80 lists open TD-NNN entries grouped by category per
`ADDENDUM` §12 lines 458–464) and the inflection-point
recommendation system signals (`bd_count_active` /
`bd_count_total` / `backlog_kb` per V3 §28.1 lines 586–605)
derive counts from the BACKLOG stream. Under decomposition,
these counts are derivable either from the regenerated
mirror (preserves V3 §28.1's contract — recommended in
parent §16.5) or from the per-entry tree (`find /.backlog/
-name 'BD-*.md' | wc -l`). The identify-only question is
whether STATUS-update prose anywhere (PM-CHAT.md update
rubrics, auditor-agent count references, recommendation-
system signal-collection code paths) needs adjustment to
explicitly name the source-of-truth path under decomposition.

OWNED BY: primary chat v11-dev architect / planner pass.

### §5.l — Pattern B archive sweep impact

Pack memory at pack-root `CLAUDE.md:174-183` sweeps workflow
artifacts (`ARCHITECTURE-*.md` / `PLAN-*.md` /
`IMPLEMENTATION-REPORT-*.md` / `PACK-REVIEW-*.md` /
`AUDIT-*.md` / `RESEARCH-*.md` / `*-DISCOVERY.md`) to
`maintenance-docs/archive/vN/` at version ship per Pattern
B. Under decomposition, the stream directories themselves
carry version-tagged content (pack `changelog/v8.M.md` /
`v9.M.md` / `v10.M.md` historical version blocks; pack
`backlog/BD-NNN.md` Resolved entries from prior versions
plus the `_v8-resolved-archive.md` per parent §6.2 + §3.5
of this addendum). The identify-only question is whether
Pattern B sweeps any of these (recommended: no — the
stream directories are live state for the current pack
shape, not workflow artifacts) and whether any sweep rule
language in `CLAUDE.md:174-183` or
`maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md`
§3 needs clarification to exclude `/.backlog/` /
`/.changelog/` / `docs/project/backlog/` /
`docs/project/implementation-plan/` / `docs/project/changelog/`
explicitly.

OWNED BY: primary chat v11-dev architect / planner pass.

### §5.m — Customization-preserve at per-entry granularity verification

Parent §9.1 routes per-entry tree paths through the existing
`generic` class in `scripts/lib/customization-preserve.sh`
`customization_classify()` (lines 145–179 per
`RESEARCH-PER-ENTRY-SPLIT.md` §5) with 3-way text dispatch
via `_cp_strategy_text` (lines 514–558, dispatch table at
lines 531–532). The 3-way text dispatch operates on per-file
3-way diff; under decomposition each per-entry file is small
(a typical BD entry is 7–9 fielded lines plus a Description
body — observable in BD-156 sample at pack
`BACKLOG.md:1443-1450` per `RESEARCH-PER-ENTRY-SPLIT.md` §2
lines 179–189; a typical TD entry is 9 lines per OT
`docs/project/BACKLOG.md:13-21` per
`RESEARCH-PER-ENTRY-SPLIT.md` §3 lines 302–314). The
identify-only question is whether 3-way text dispatch's
diff-context window remains meaningful at this granularity
(small files diff cleaner — parent §9.1 argues this — but
small files also limit the merge tool's ability to anchor
on surrounding context). A concrete test scenario (user
customizes one field in one BD entry; pack ships an updated
BD entry with a different field changed; merge expected to
land both) is needed to validate. Parent §9.1's claim is
unproven at file scale; verification is needed.

OWNED BY: primary chat v11-dev architect / planner pass.

### §5.n — BD-161 absorption

BD-161 (per pack `BACKLOG.md:1388` "v10→v11 migrator: install
net-new v11 SKILL.md dirs (BD-156/157/158 + python-server-
architecture / python-data-architecture split)") was
scheduled to install net-new v11 SKILL.md directories via
the v10→v11 migrator's existing
`migrator_post_dispatch_hook` (per
`scripts/migrate-v10-to-v11.sh:144-148`). Under §1 of this
addendum, the same v10→v11 migrator hook now also performs
the per-entry decomposition step
(`_v10_to_v11_decompose_streams` per §1.3 of this addendum,
sequenced 6th and last in the hook). Both operations live
in the same hook on the same migration run. The identify-
only question is whether BD-161's work absorbs into the
per-entry-decomposition migrator step (e.g. the new SKILL.md
installs become an additive transform on the
`docs/project/` tree alongside the decomposition step) or
remains a separate `_v10_to_v11_install_v11_artifacts` /
adjacent adapter operation (current shape — line 146 of
`scripts/migrate-v10-to-v11.sh`). The two operations touch
different directories (BD-161 touches per-CLI `skills/`
trees; decomposition touches `/.backlog/`, `/.changelog/`,
`docs/project/*`) so they are not obviously conflicting; the
question is housekeeping / sequencing / report-text
attribution, not contract design.

OWNED BY: primary chat v11-dev architect / planner pass.

### §5.o — Diffability / git history for cross-entry refactors

Today a multi-BD refactor (e.g. flipping 6 BDs to Resolved
in one commit, or renumbering a BD range) is a single
`BACKLOG.md` diff that PR review can read in one place,
and `git blame BACKLOG.md` records the change against
one file. Under per-entry decomposition the same refactor
becomes N file edits (plus a mirror regeneration and a
`_toc.md` regeneration); PR review surface fans out across
N files; `git blame` for any individual entry's history is
cleaner (entry history is the file's history, not a
sub-region of a 3,627-line file), but cross-entry refactor
history is scattered. This is a structural tradeoff —
per-entry files are better for per-entry history and worse
for cross-entry refactor history. No fix proposed; the
tradeoff is inherent to the decomposition shape.

OWNED BY: primary chat v11-dev architect / planner pass.

### §5.p — `.pack-tracker/` vs `/.backlog/` namespace collision risk

Pack-side `/.backlog/` (parent §3.1) and `/.changelog/`
(parent §3.2) sit at pack root parallel to `.pack-tracker/`
(per V3 §28.1.4 referenced from §28.1 — the tracker state
directory). The names share the leading-dot convention so
they sort and gitignore consistently; however the
`tracker.toml` detection logic at
`scripts/lib/tracker-config.sh` (per
`RESEARCH-PER-ENTRY-SPLIT.md` §5 — BD-061 manifest area
around `BACKLOG.md:48-58`) reads `tracker.toml` to decide
flat-file vs tracker mode and does not look at `/.backlog/`.
Under decomposition the presence-of-`/.backlog/` is the
implicit signal that the client has migrated to v11.0+ and
is in decomposed-flat-file mode (Mode 2 per parent §8.1).
The identify-only question is whether any existing detection
code (`scripts/lib/detect.sh`, `tracker-config.sh`,
`recommendation.sh`) needs to know about `/.backlog/`
presence as a v11.0+ flag, or whether the `template_version`
mechanism in `tracker.toml` (per V3 D-18 / V3.3-DELTA §6.5
lines 371–382) and the README version table are sufficient
version signals.

OWNED BY: primary chat v11-dev architect / planner pass.

### §5.q — Init-project.sh greenfield path

`scripts/init-project.sh` initializes the pack in a new
project (per `README.md:181`). Under decomposition the
greenfield project receives the per-entry tree directly —
not the monolithic file with a post-init decomposition.
`init-project.sh stage_s11_v11_artifacts()` (referenced in
the BD-116 / BD-161 resolution prose at pack
`BACKLOG.md:1157`) installs v11 artifacts; under
decomposition the same stage installs the per-entry tree
shape (the project-template canonical files at
`project-template/docs/project/backlog/_rules.md` /
`_intro.md` plus empty seed `_toc.md` and an initial
canonical `TD-000.md`-style template, exact shape planner-
owned). The identify-only question is whether
`init-project.sh` needs a new stage or whether the existing
stage-S11 absorbs the per-entry-tree install. Parallel
concern on the pack-self side: nothing initializes pack-
side `/.backlog/` because the pack repo's per-entry tree is
created by the v10.1→v11.0 migration of pack-self, not by
`init-project.sh`.

OWNED BY: primary chat v11-dev architect / planner pass.

### §5.r — Backup and rollback under non-reversible migration

The v10→v11 migrator's `_stage_backup` step (per
`scripts/lib/migrator-core.sh:146` per
`RESEARCH-PER-ENTRY-SPLIT.md` §5 lines 534–538) creates a
backup before any transform. Under §1 non-reversible
decomposition, the backup IS the only way back to
monolithic-as-source state if the user disowns v11.0 after
migration. The identify-only question is whether the backup
contract is sufficient for this case (today the backup
restores files; under decomposition the restore must
specifically restore the monolithic file AND remove the
per-entry tree to avoid stale dual-state), and whether the
existing post-report-hook advisory text per parent §13.4
needs to mention the backup explicitly as the rollback
path.

OWNED BY: primary chat v11-dev architect / planner pass.

---

## §6 — Final-line marker

ARCHITECTURE-PER-ENTRY-SPLIT-ADDENDUM-COMPLETE: 2026-05-13 — Locked per-entry decomposition to v11.0 mandatory + non-reversible (delivered via existing `migrate-v10-to-v11.sh` post-dispatch hook as 6th sub-operation), reversed parent §3.4 to one-file-per-phase with phase tasks inline (per V3.3-DELTA §6.4 identifiers preserved inline), operationalized the one-entry-per-file rule across all 5 streams with supporting-file exceptions (`_rules.md` / `_toc.md` / `_intro.md` / `_v8-resolved-archive.md` / `_format.md`), resolved explanatory-text home as new per-stream `_intro.md` (Pack Chat Q2 option (b)), specified the bidirectional 1-to-N flat ↔ tracker contract for project `implementation-plan/phase-N.md` files (phase-epic issue + N phase-task issues with round-trip byte-identity), and inventoried 18 identify-only items (§5.a–§5.r) for the primary v11-dev chat's architect / planner pass.
