# RESEARCH — BD-206 project-side monolith→per-entry no-mirror conversion

> **Audience:** Pack Chat + a future architect/planner/coder (the BD-206
> Track-B pipeline).
> **Purpose:** READ-ONLY research of the facts, the generalized design
> space, the blast radius, and an OT v10.3 stress-input census, for
> BD-206 (re-scoped flat-file-only, v11.0): convert the project streams
> (`project-template/docs/project/{backlog,implementation-plan,changelog}/`)
> to per-entry no-monolith, DELETE the project monoliths with NO mirror,
> CREATE `_index.md` for the implementation-plan stream, and reconcile
> the predesign to the BD-203 as-built shape.
> **Researcher does NOT design** — this doc enumerates options + facts +
> trade-offs; it does not prescribe.
> **HEAD:** `f858d90ec0bd12492944aba457bebb0b91285081` (branch `v11-dev`),
> 2026-06-13.
> **GENERALIZED-ONLY (user, repeated twice):** every design-space finding
> below derives from the corrected STANDARD, not from OT-shaped entries.
> OT content is a STRESS INPUT used to validate the generalized design
> handles real shapes — it is NEVER a spec.

---

## 0. TL;DR for the architect

1. **The standard already exists (BD-203, pack-side, Resolved).** BD-206
   is the project-side application of the EXACT same corrected standard:
   per-entry tree + generated `_toc.md` = sole SSOT + readable form; NO
   regenerated monolithic mirror; DELETE the monolith. The pack-side
   mechanism is in place and CI-enforced (Check 32′). BD-206 mirrors it
   onto project assets.
2. **The incoherence BD-206 fixes is REAL and enumerable.** The corrected
   "no monolithic mirror" convention SHIPS to clients (trinity, `_rules.md`),
   but the client tooling still GENERATES mirrors (init-project.sh S11,
   migrator S5d, `mirror-generate.sh`), the three project `_intro.md`
   files literally say "regenerated mirror," `supporting-docs/MIGRATION-v10-to-v11.md`
   says "monolith becomes a mirror," and the trinity Document-locations
   table calls BACKLOG/IMPLEMENTATION-PLAN/CHANGELOG "regenerated mirrors."
   Shipping BD-203's corrected convention WITHOUT BD-206 ships a product
   whose convention contradicts its own feature — the launch-coherence
   gate.
3. **`_index.md` is PREDESIGNED but UNBUILT — zero such files exist.** It
   must be CREATED for the implementation-plan stream (phase order is NOT
   numerically recoverable — proven by the OT census, §4). The predesign
   lives under the old name `_order`/`_order.md`; reconcile to the BD-203
   as-built meta-doc shape (audience+purpose header, `_rules.md` is sole
   rules SSOT).
4. **The OT census surfaced TWO generalized stress findings the architect
   MUST resolve** (§4): (a) the project-backlog decompose engine treats
   `## Phase N` H2s as section-breaks and **silently drops the phase
   grouping** of TD entries (the entries survive; the grouping is lost);
   (b) the implementation-plan file order is NOT numeric (executes
   0,1,…,29,43,30,…,35,58,59,60,36,… ) AND carries non-phase scaffolding
   H2s — so `_index.md` must capture an execution order the filename
   sort cannot reconstruct.

---

## 1. The BD-203 as-built reference (the standard BD-206 mirrors)

BD-203 (Resolved 2026-06-05; commits `a5a8ad8`, `11226a9`, Commit-3)
converted the PACK streams (`pack-ops/BACKLOG.md` + `CHANGELOG.md`) to
per-entry no-monolith. The as-built mechanism BD-206 mirrors:

### 1.1 The per-entry contract (the as-built shape)
- **Sole SSOT + readable form:** the per-entry tree (`/backlog/`,
  `/changelog/`) plus a generated `_toc.md` index. **No monolithic
  mirror** — the monolith is the CONVERSION INPUT ONLY, then DELETED
  (`git rm`), gated on a verified-complete tree (SAFE-before-DELETE).
- **Per-entry file shape:** line-1 HTML-comment back-pointer
  (`<!-- per-entry source: <path>; contract: <path> -->`) ABOVE the
  entry's bold/H2 header; the entry's content span begins at the anchor.
- **Sidecars per stream:** `_rules.md` (the SOLE rules SSOT — filename
  regex, lifecycle states, supporting-file basenames, ID-extraction rule,
  write-authority, no-mirror statement, all in one place), `_intro.md`
  (human-only orientation; agents may ignore; ZERO rules), `_toc.md`
  (generated index; DO NOT EDIT). Every meta-doc states AUDIENCE +
  PURPOSE at the top (the D1 doc-governance standard; see
  `ARCHITECTURE-BD-203-V3-AMENDMENT.md` §F).
- **`_toc.md` is regenerated, deterministic, idempotent** — no time/version
  stamp (would break byte-identical regeneration / Check 33).

### 1.2 The toc-regenerate mechanism (`scripts/lib/per-entry/toc-regenerate.sh`)
- `per_entry_regenerate_toc <stream_key> <stream_dir>` regenerates
  `<stream_dir>/_toc.md`. Per-stream axis: pack-backlog/project-backlog
  grouped by `Status:`; pack-changelog by major version; project-changelog
  by year-month descending; **project-implementation-plan grouped by phase
  number** (ascending). Group order for backlog streams is the ratified
  Open → Unblocked → Deferred → Resolved → Deprecated → Cancelled.
- The python helper inside ALREADY contains the
  `project-implementation-plan` axis (groups by `Phase N`, sorts ascending
  by phase number) — so the toc-regenerate side is project-aware today;
  BD-203 only repointed CALLERS + validators pack-side.

### 1.3 The deletion + reference-fix discipline
- BD-203 corrected ~16 "monolith = regenerated mirror" source surfaces to
  the new standard, then DELETED `pack-ops/BACKLOG.md` + `CHANGELOG.md`
  (no mirror — FAIL-LOUD: dangling refs BREAK + SURFACE + get fixed).
- The old "mirror-in-sync" Check 32 was INVERTED to **Check 32′** ("no
  pack monolith exists") in `scripts/validate-pack.py` (line ~3273,
  `── Check 32′: no pack monolith exists (BD-203) ──`). Check 33
  (`_toc.md` in-sync) was retained.

**Empirical evidence (BD-203 as-built):**
- Command: `Read /backlog/_rules.md` → "Source of truth — flat-file (no
  monolith)" section: *"The per-entry tree at `/backlog/` (plus its
  generated `/backlog/_toc.md` index) is the SOLE source of truth and
  readable form. There is no monolithic mirror — the former
  `pack-ops/BACKLOG.md` was deleted at BD-203; do not recreate it."*
- Command: `grep -n "Check 32′" scripts/validate-pack.py` → lines
  3273/3347/3374 confirm Check 32 inverted to 32′ (no pack monolith).
- Conclusion: SUPPORTED. The pack-side standard + mechanism + CI gate
  are in place; BD-206 applies the identical pattern to project assets.

---

## 2. Current project-side state + the mirror-incoherence surfaces

### 2.1 What the project streams contain TODAY
`find project-template/docs/project/{backlog,implementation-plan,changelog} -maxdepth 1 -type f`
(2026-06-13, HEAD f858d90):
```
backlog/_intro.md   backlog/_rules.md
changelog/_format.md   changelog/_intro.md   changelog/_rules.md
implementation-plan/_intro.md   implementation-plan/_rules.md
```
- **No per-entry files ship** (correct — these are empty greenfield
  skeleton dirs; entries appear post-init / post-migration in a client
  repo, not in the pack template).
- **No `_toc.md` ships** in the template dirs (generated at install).
- **No `_index.md` exists anywhere in the tree** (predesigned, unbuilt —
  measured: `find . -name _index.md` returns nothing; the
  `RESEARCH-ORDER-MD-RENAME-CENSUS.md` confirms zero built `_order.md`
  too).
- **Conclusion:** SUPPORTED — the project streams are sidecar-only
  skeletons today; the conversion target is the client-RUNTIME behavior
  (tooling) + the shipped docs/rules, not pre-existing per-entry files in
  the template.

### 2.2 The mirror-INCOHERENCE surfaces (the product contradiction BD-206 fixes)
Every surface below currently asserts or GENERATES a "regenerated mirror"
— contradicting the BD-203-corrected "no monolithic mirror" standard that
already ships to clients. Enumerated, categorized:

| # | Surface | What it says / does today | Category |
|---|---|---|---|
| 1 | `project-template/docs/project/backlog/_rules.md` § Write authority | "The monolithic `docs/project/BACKLOG.md` is a regenerated mirror — read-stable but never source of truth" | DOC — correct to no-mirror |
| 2 | `…/implementation-plan/_rules.md` § Write authority | same "regenerated mirror" language for `IMPLEMENTATION-PLAN.md` | DOC — correct to no-mirror |
| 3 | `…/changelog/_rules.md` § Write authority | same for `CHANGELOG.md` | DOC — correct to no-mirror |
| 4 | `…/backlog/_intro.md` | DO-NOT-EDIT mirror preamble + "This file is the regenerated mirror …" (lines 1–5, 9–12, 26–41) | DOC — the `_intro.md` mirror framing must go |
| 5 | `…/implementation-plan/_intro.md` | same mirror framing (lines 1–6, 10–14, 33–39, 50) | DOC |
| 6 | `…/changelog/_intro.md` | same mirror framing (lines 1–5, 11–14, 33, 44–46) | DOC |
| 7 | `…/{backlog,implementation-plan,changelog}/_rules.md` § Supporting files | "The pack's per-entry **mirror generator** reads this list at runtime" | DOC — generator vocabulary |
| 8 | `project-template/CLAUDE.md` (+AGENTS+GEMINI trinity) "Document locations" table | row: "`CHANGELOG.md` (regenerated mirrors for BACKLOG/IMPLEMENTATION-PLAN/CHANGELOG — per-entry source in subdirs)" + the "Per-entry source-of-truth trees" paragraph "The monolithic … are regenerated mirrors" | DOC — TRINITY (parallel edit ×3) |
| 9 | `supporting-docs/MIGRATION-v10-to-v11.md` § "Per-entry decomposition" | "The pre-existing monolithic files become regenerated mirrors of the per-entry trees, not the source of truth" + the whole "Monolithic files become regenerated mirrors" + "`--force-overwrite-mirror`" + Check 32/33 narrative (lines ~244–344) | DOC — large narrative correction |
| 10 | `scripts/init-project.sh` S11 stanza (lines ~1083–1135) | sources `mirror-generate.sh`, calls `per_entry_regenerate_mirror` for all 3 project streams, prints "empty mirrors at docs/project/{BACKLOG.md,…}" | CODE — stop generating mirrors |
| 11 | `scripts/lib/migrate-v10-to-v11/decompose.sh` (lines ~145–200) | per-stream loop: `per_entry_decompose` THEN `per_entry_regenerate_mirror` THEN regen TOC; on absent monolith input handling | CODE — keep decompose (conversion input), drop the mirror-regen step |
| 12 | `scripts/lib/per-entry/mirror-generate.sh` | "retained physically ONLY because the project streams still call it" + `TODO(v11.0): TD-TBD — retire mirror-generate project-side at BD-206` (line 12) | CODE — the retirement target this BD realizes |
| 13 | `scripts/validate-pack.py` Check 43 `_CHECK_43_MIRROR_SKIP_BASENAMES = ("BACKLOG.md","CHANGELOG.md","IMPLEMENTATION-PLAN.md")` + project-mirror prose | mirror-skip basenames + comments treating project mirrors as legitimate-for-now | CODE — retire/update when the client mirror is removed (BD-203 fix-2 KEPT them as accurate-for-now) |
| 14 | `scripts/validate-pack.py` Check 32/33 (project-side) | the pack-side Check 32 was inverted to 32′; the PROJECT-side mirror-in-sync / TOC-in-sync semantics must be reconciled (no project monolith to keep in sync) | CODE — measure-then-bound (architect) |
| 15 | `scripts/lib/detect.sh` client-surface branch (lines ~65–75) | reads `docs/project/BACKLOG.md` / root `BACKLOG.md` with `^\*\*TD-` — BD-203 repointed ONLY the pack-surface branch to the tree; the CLIENT branch still reads a client monolith | CODE — repoint to the client `docs/project/backlog/` tree (dual-use file completion; `_SANCTIONED_PACK_SIDE_SHIPPED` + install map UNCHANGED, CI Check 47) |
| 16 | `project-template/skills/audit-methodology/SKILL.md`, `…/pm-startup/SKILL.md` | carry mirror/monolith prose; the pack `.claude/.codex/.gemini` COPIES were corrected by BD-203 C-3 but the project-template MASTERS are still divergent (the G-4 divergence) | DOC — correct masters to restore pack-copy↔master parity |

**Empirical evidence:**
- Command:
  `grep -niE "mirror|monolith|regenerat" project-template/docs/project/*/_intro.md`
  → 27 hits across the three `_intro.md` files (verbatim "regenerated
  mirror" framing). Conclusion: SUPPORTED (#4–#6).
- Command: `grep -rn "per_entry_regenerate_mirror" scripts/` → callers:
  `init-project.sh:1098/1100/1127`, `migrate-v10-to-v11/decompose.sh:93/95/195`,
  plus test files. Conclusion: SUPPORTED (#10–#11) — exactly two
  production callers generate project mirrors.
- Command: `grep -rln "monolith|regenerated mirror" project-template/skills/*/SKILL.md`
  → `audit-methodology/SKILL.md`, `pm-startup/SKILL.md`. Conclusion:
  SUPPORTED (#16) — the G-4 master divergence is real.

> **GENERALIZED-ONLY note:** every surface above is enumerated from the
> STANDARD ("no monolithic mirror") applied to the project's OWN assets —
> none is fitted to OT. OT is not referenced in §2.

---

## 3. The generalized decomposition design space (derived from the standard)

The decomposition machinery ALREADY EXISTS and is stream-parameterized
(`scripts/lib/per-entry/{decompose,mirror-generate,toc-regenerate}.sh`).
BD-206 does not invent a new engine; it (a) stops the project mirror legs
and (b) adds `_index.md`. The option space below is for the architect's
DECISIONS, each option derived from the standard, with OT only as a
stress validator.

### 3.1 General monolith→per-entry decomposition (already-built engine)
A monolith decomposes by: **entry-boundary detection** (a per-stream
anchor regex), **ID extraction** (filename = ID), **per-entry write**
(line-1 back-pointer + body span), **sidecar generation** (`_toc.md`).
The engine's stream-axis table:

| Stream | Anchor (entry boundary) | ID / filename | `_toc.md` axis |
|---|---|---|---|
| project-backlog | `^\*\*TD-\d+ — ` | `TD-NNN.md` | `Status:` group |
| project-implementation-plan | `^## Phase (\d+) — ` | `phase-N.md` | phase number |
| project-changelog | `^### YYYY-MM-DD(— Phase N)?(— slug)?` | `YYYY-MM-DD[-slug].md` | year-month desc |

**Section-break semantics (the engine's general rule):** any `^## `
that is NOT itself an anchor CLOSES the open entry and opens nothing
(intervening lines until the next anchor are dropped as
non-entry scaffolding). This is the rule that produces the OT
phase-grouping-loss stress finding (§4) — it is a GENERAL property of
the engine, surfaced (not caused) by OT's shape.

### 3.2 OPTION SPACE — DECISION D-A: the project-backlog phase grouping
The standard says "preserve every entry." TD entries survive
decomposition; what is at risk is the **phase grouping** under which TD
entries are filed in a real backlog (a `## Phase N` H2 over a block of
TDs). Options (architect decides; all generalized):
- **D-A1 — accept grouping loss (status-axis TOC only).** TD entries
  regroup by `Status:` in `_toc.md` (the existing axis); the phase
  grouping is not preserved. Simplest; matches pack-backlog (which has no
  phase grouping). Trade-off: a real backlog loses its
  "TDs-by-phase" view.
- **D-A2 — preserve grouping as an entry field.** Capture the enclosing
  `## Phase N` as a per-entry field/marker (e.g. an HTML marker or a
  `Phase:` field) during decomposition, so `_index.md` (or a second
  TOC axis) can regroup TDs by phase. Trade-off: requires a decompose
  engine change (the engine currently DROPS the H2); preserves the view.
- **D-A3 — `_index.md` grouping graph.** Record the phase→TD grouping in
  the backlog stream's `_index.md` (the broadened sidecar can carry
  GROUPINGS, per the BD-206 entry definition). Trade-off: a backlog
  `_index.md` is optional per the entry text; this makes it load-bearing
  for grouping fidelity.
- **Open question OQ-1:** is "TDs-grouped-by-phase" a REQUIRED view of the
  standard, or an OT-specific organizational habit? If the former, D-A2/
  D-A3; if the latter, D-A1. **Resolve against the standard, not OT.**

### 3.3 OPTION SPACE — DECISION D-B: `_index.md` for implementation-plan
The standard requires an index because phase order is not numerically
recoverable (proven §4). `_index.md` is a sidecar alongside `_intro.md`/
`_rules.md`/`_toc.md` carrying ONE OR MORE indexes/graphs (order,
groupings, optionally a dependency graph). Options:
- **D-B1 — execution-order index only.** `_index.md` carries the
  execution-ordering index (the minimum the BD-206 entry requires).
  Predesign mechanism (`ARCHITECTURE-BD-185-V2.md` §5.3): a per-phase
  `<!-- execution-order: N -->` HTML marker on each `phase-N.md`;
  `_index.md` and/or the TOC sort by `(execution-order, phase_number,
  filename)`, defaulting to phase number when markers absent. Trade-off:
  greenfield/migrated projects with no markers sort by phase number (=
  current behavior); marked projects sort by intent.
- **D-B2 — index + dependency graph.** Add the optional dependency graph
  (which MAY reference TD entries depending on phase entries). Trade-off:
  the entry says the graph is "created only if needed" — NOT a default;
  likely OUT for v11.0 unless a concrete need is shown.
- **D-B3 — where the ordering SSOT lives.** Predesign (§5.3/§5.4) is
  emphatic: the ordering SSOT is the phase entity's `execution-order`
  marker (flat-file) — `_index.md` is a REGENERATED VIEW with a "never
  source of truth" disclaimer, NOT the SSOT. The architect must decide
  whether `_index.md` is generated (from per-phase markers, like
  `_toc.md`) or hand-authored. **Generated-from-markers preserves the
  no-hand-edit-derived-index invariant the standard already enforces for
  `_toc.md`.**
- **Open question OQ-2:** does `_index.md` get its own regenerator
  (`_index-generate.sh`, predesigned but UNBUILT) + a CI in-sync check
  (parallel to Check 33), or is the ordering folded into the existing
  `toc-regenerate.sh` impl-plan axis? Measure-then-bound (architect).

### 3.4 STATUS.md — SPECIAL TREATMENT (census-only, never decomposed)
The standard: STATUS.md is a dashboard / convenience view, NEVER source
of truth, NEVER decomposed into per-entry files. The BD-206 obligation
(via BD-105, re-scoped flat-file-only): STATUS.md phase-row titles render
as a **single link to the phase entry/anchor in the per-entry
implementation-plan stream** — `[Phase Title](#anchor)`. The TRACKER
dual-link half (` · [#N](issue-URL)`) is DEFERRED with the tracker work
(BD-214). Options for the flat-file link target:
- **D-C1 — link to the per-entry file.** `[Phase Title](implementation-plan/phase-N.md)`
  (or `#anchor` within it) — the per-entry tree is the SSOT.
- **D-C2 — link to a TOC/index anchor.** Link into `_toc.md`/`_index.md`.
- **Constraint (proven by §4):** OT's STATUS.md today links
  `IMPLEMENTATION_PLAN.md#phase-N--slug` (the MONOLITH + anchor) — when
  the monolith is DELETED, these 63 links DANGLE. The flat-file renderer
  MUST repoint them to per-entry targets. **GENERALIZED:** the rule is
  "STATUS.md phase links resolve into the per-entry tree, never into a
  deleted monolith" — OT's 63 links merely STRESS-TEST that the renderer
  handles a real STATUS.md.
- **Open question OQ-3:** which symbol/anchor form is canonical for a
  per-entry phase link — the file path, or a `_toc.md`/`_index.md`
  anchor? Architect decides against the standard; the per-entry file is
  the SSOT so the file-path form is the natural candidate.

### 3.5 Greenfield vs migration paths (both must hold the no-mirror rule)
- **init-project.sh S11 (greenfield):** today seeds EMPTY mirrors +
  `_toc.md`. Under no-mirror it must seed `_toc.md` (and an empty/seeded
  `_index.md` for impl-plan) but NO mirror. The decompose/regenerate
  helpers must produce a valid empty-tree `_toc.md` without a mirror.
- **migrate-v10-to-v11 S5d (brownfield):** today decompose → regen mirror
  → regen TOC. Under no-mirror: decompose (the monolith is the conversion
  INPUT) → regen TOC (+ `_index.md`) → **DELETE the monolith** (gated on
  a verified-complete tree, SAFE-before-DELETE — the BD-203 discipline).
  Open question OQ-4: the migrator currently relies on the mirror
  round-trip for its byte-identity verification gate; with no mirror the
  verification must shift to a tree-vs-input completeness check (every
  anchor in the input monolith produced a per-entry file). Measure-then-
  bound.

> **GENERALIZED-ONLY note:** §3 options derive from the corrected
> standard + the existing engine. OT appears ONLY as a stress validator
> in the constraints (§3.2, §3.4), never as the source of an option.

---

## 4. OT v10.3 stress-input census (READ-ONLY; clone removed)

**Clone command (read-only, /tmp, removed after):**
`git clone --depth 50 https://github.com/DShaneNYC/OptiquityTrader.git /tmp/ot-bd206-census`
(the explicit `--branch v10.3` failed — *"Remote branch v10.3 not
found"*; the depth-50 default-branch clone succeeded). **The shallow
clone carried no v10 tags**, so the census surface is the clone HEAD
(`3a79a92 docs: relink 1326 WI citations from C monolith to per-entry
files`), NOT a pinned v10.3 — this is a fidelity caveat: OT HEAD is
post-v10.3 and already mid-its-own-per-entry-relink. The four monoliths
were present and intact at `docs/project/`. **Clone removed**
(`rm -rf /tmp/ot-bd206-census`). The real repo was NEVER written to.
The user confirmed OT monoliths carry no proprietary content yet —
**committed scrubbed fixtures are viable and PREFERRED for CI** (noted
for the architect; do not wire a live-OT clone into CI).

> **Caveat for the architect:** because the clone is post-v10.3 (no v10.3
> tag in a shallow clone), treat these numbers as a real-shape STRESS
> INPUT, not a v10.3-exact census. If a v10.3-exact census is required,
> re-clone full-depth and `git checkout v10.3` (or build a scrubbed
> committed fixture). The SHAPES below are what matter for the
> generalized design, and they are stable across OT's recent history.

### 4.1 BACKLOG.md (113 TD entries) — phase-grouping-loss stress
- 1478 lines; **113** `^\*\*TD-\d+ — ` anchors; **0** letter-suffix
  anchors (canonical, BD-211-clean).
- `Status:` distribution: **57 Open, 56 Resolved** (matches the project-
  backlog `_rules.md` two-state vocabulary Open/Resolved).
- Top-level fields are uniform across all 113: `Type` `Status` `Blockers`
  `Unblocks` `File/Symbol` `Description` `Context` (each ×113), plus
  `Resolution` ×56 (resolved entries). A handful of one-off fields
  (`Pending developer decisions:` ×2, `Design reference:` ×2, `Audit
  scope expansion:` ×1) — the field-faithful contract (per `_rules.md`
  "the contract does not gate on a field allowlist") handles these
  verbatim. **No field-census violation.**
- **STRESS FINDING SF-1 (generalized): phase grouping is silently
  dropped.** The 113 TDs are filed under `## Phase N` H2 grouping headers
  (`## Phase 10 — …`, `## Phase 11 — …`, … plus `## Simulation Layer`,
  `## How to use this file`, `## Full Codebase Audit — 2026-04-13`). The
  project-backlog anchor is `**TD-` — so every `## Phase N` line is a
  SECTION-BREAK that closes the current TD and opens nothing; the
  enclosing phase grouping is DROPPED. The 113 entries survive (good);
  the "which phase identified this TD" grouping view is LOST unless DECISION
  D-A (§3.2) preserves it. This is a property of the GENERAL engine,
  surfaced by a real backlog.

### 4.2 IMPLEMENTATION_PLAN.md (61 phases) — non-numeric-order + scaffolding stress
- 5342 lines; **61** `^## Phase (\d+) — ` anchors; underscore filename
  `IMPLEMENTATION_PLAN.md` (pre-BD-104 name, as the prompt anticipated).
- **0 duplicate phase numbers** (no decompose id-collision risk).
- **STRESS FINDING SF-2 (generalized): file order ≠ numeric order ≠
  execution order.** The phases appear in the file as
  0,1,2,…,24,25,26,27,28,29,**43**,30,31,32,33,34,35,**58,59,60**,36,37,
  38,**44**,39,40,41,42,**45,46,47,48,49,50,51,52** — i.e. later-numbered
  phases (43, 58–60, 44) are interleaved among lower numbers, reflecting
  EXECUTION/insertion order, not phase number. A filename sort
  (`phase-N.md`) recovers numeric order but NOT this execution order. **This
  is the concrete proof that `_index.md` is required** (the BD-206 entry's
  claim, validated). The predesigned `execution-order` HTML marker (§3.3
  D-B1) is the generalized mechanism.
- **STRESS FINDING SF-3 (generalized): non-phase scaffolding H2s.** Four
  `^## ` headers are NOT phases and would be DROPPED by decompose:
  `## Codebase Snapshot`, `## Cross-Phase Notes`, `## Phase Completion
  Checklist`, `## Updated Phase Completion Checklist (Phases 26–44)`. Per
  the standard these are non-entry scaffolding (legitimately dropped, like
  BD-203's section labels) — BUT the architect must CONFIRM none carries
  entry-state that would be lost (the BD-203 "when in doubt, preserve"
  rule). Also `## Phase Completion Checklist` LOOKS phase-ish but the
  anchor `^## Phase (\d+) — ` correctly does NOT match it (no number +
  em-dash) — no false-positive entry created. Good.

### 4.3 CHANGELOG.md (55 dated entries) — anchor-variant stress
- 2579 lines; **55** `^### \d{4}-\d{2}-\d{2}` anchors; one `## Format
  Rules` H2 (maps to the project-changelog `_format.md` sidecar — the
  engine already special-cases `_format.md`).
- Sample anchors: `### 2026-04-20 — Phase 35 — Live Broker Sandbox
  Verification` (date—Phase—title form) — all observed entries use the
  `— Phase N — Title` variant; the engine's regex
  `^### (\d{4}-\d{2}-\d{2})(?: — Phase (\d+))?(?: — (.+?))?$` handles
  date-only, date—phase—title, and date—slug. The `### Entry format` /
  `### YYYY-MM-DD — …` / `### Rules` lines inside `## Format Rules` are
  TEMPLATE TEXT under the Format-Rules H2 — they sit before the first
  real dated anchor and inside a non-anchor H2; the architect should
  CONFIRM they land in `_format.md` (not mis-parsed as entries). **No new
  stress finding** beyond the existing `_format.md` handling.

### 4.4 STATUS.md (141 lines, 63 links) — dangling-link stress
- H2 sections: `## Current Phase`, `## Phase Completion`, `## Active
  Backlog`, `## Key Metrics`, `## Next Actions`, `## How to Update This
  File`. **Not decomposed** (dashboard — special treatment, §3.4).
- **STRESS FINDING SF-4 (generalized): 63 phase links target the
  monolith.** Every phase link is
  `[Title](IMPLEMENTATION_PLAN.md#phase-N--slug)` — pointing at the
  monolith + a generated anchor. When BD-206 DELETES the monolith these
  63 links DANGLE. The BD-105 flat-file renderer must repoint them into
  the per-entry tree (`[Title](implementation-plan/phase-N.md)` or an
  `_index.md`/`_toc.md` anchor — DECISION D-C, §3.4). **GENERALIZED rule:
  STATUS links resolve into the per-entry tree, never a deleted
  monolith.** OT's 63 links stress-test the renderer's link-rewrite at
  realistic scale.

**OT census conclusion:** SUPPORTED as a STRESS INPUT. The generalized
engine + the proposed `_index.md` handle real OT shapes EXCEPT for the
four surfaced architect-decisions (SF-1 phase grouping, SF-2/SF-3
impl-plan order+scaffolding → `_index.md`, SF-4 STATUS link rewrite).
None of these decisions is fitted to OT — each is a general property of
the standard that OT made visible.

---

## 5. Blast radius (every client surface the conversion touches; counts reconciled)

### 5.1 By surface, categorized

**A. DOCS to correct to no-mirror (DOC; no behavior code):** 8 surfaces
- 3× project `_rules.md` (backlog / impl-plan / changelog) § Write
  authority + § Supporting files "mirror generator" vocabulary.
- 3× project `_intro.md` (the entire "regenerated mirror" framing).
- 1× trinity Document-locations table + per-entry paragraph
  (`project-template/{CLAUDE,AGENTS,GEMINI}.md` — TRINITY = parallel ×3,
  but counted as 1 logical surface / 3 files).
- 1× `supporting-docs/MIGRATION-v10-to-v11.md` § Per-entry decomposition
  (+ the `--force-overwrite-mirror` + Check 32/33 narrative).

**B. SKILL MASTERS to correct (DOC; G-4 parity):** 2 files
- `project-template/skills/audit-methodology/SKILL.md`,
  `project-template/skills/pm-startup/SKILL.md` (restore pack-copy↔master
  parity; BD-203 C-3 fixed the `.claude/.codex/.gemini` copies only).

**C. CODE — stop generating / start deleting mirrors:** 3 files
- `scripts/init-project.sh` S11 (drop the `per_entry_regenerate_mirror`
  leg; keep `_toc.md`; add `_index.md` seed for impl-plan).
- `scripts/lib/migrate-v10-to-v11/decompose.sh` S5d (keep `decompose`;
  drop the mirror-regen leg; ADD monolith DELETE gated on tree-complete;
  shift the verification gate off the mirror round-trip).
- `scripts/lib/per-entry/mirror-generate.sh` (the `TODO(v11.0): … retire
  mirror-generate project-side at BD-206` retirement target — retire or
  fully neutralize for project streams; check no remaining production
  caller).

**D. CODE — dual-use detection completion:** 1 file
- `scripts/lib/detect.sh` client-surface branch → repoint to
  `docs/project/backlog/` tree (`_SANCTIONED_PACK_SIDE_SHIPPED` + install
  map UNCHANGED — CI Check 47 must stay green).

**E. CODE — validators:** 2 logical checks in `scripts/validate-pack.py`
- Check 43 `_CHECK_43_MIRROR_SKIP_BASENAMES` + project-mirror prose
  (retire/update when the client mirror is removed).
- Check 32/33 PROJECT-side semantics (the pack-side Check 32 already
  inverted to 32′; the project-side mirror-in-sync / TOC-in-sync must be
  reconciled to "no project monolith"; add `_index.md` in-sync coverage
  per OQ-2). Measure-then-bound (architect).

**F. CODE — `_index.md` machinery (NEW):** 1–2 files
- A `_index.md` generator (predesigned `_order-generate.sh`, UNBUILT) OR
  fold into `toc-regenerate.sh`; per-phase `execution-order` marker
  parsing; a CI in-sync check. DECISION D-B / OQ-2.

**G. CODE — STATUS.md flat-file renderer (BD-105 flat-file half):** 1–2 files
- The STATUS.md phase-row link renderer (single-link `[Title](#anchor)`
  into the per-entry tree); `scripts/lib/tracker-doctor.sh` dead-path fix
  (BD-105 names `scripts/lib/pack-tracker/doctor.sh` which does not
  exist). The TRACKER dual-link half is DEFERRED (BD-214).

**H. TESTS (enumerate-encoding-surfaces):** ≥6 test files
- `scripts/tests/test-per-entry.sh`, `test-init-project.sh`,
  `test-migrate-v10-to-v11-decompose.sh`, `test-v11-realistic-ot.sh`,
  `test-validate-pack-checks-32-33-34.sh`, and any test asserting mirror
  presence / mirror round-trip / Check 32/33 banners. Each pins behavior
  that the no-mirror conversion changes — they MUST be updated in
  lock-step (per `feedback-verify-full-ci-suite`: the BD-203 C-1 banner
  rename broke a stale integration-test assertion the sweep missed).
- `test-fixtures/manifest.txt` MUST be regenerated (v11-surface commits
  touch `project-template/` + `scripts/` — trinity RC9 /
  `regenerate-manifest-v11-surface`).

**I. The `_order`→`_index.md` rename deferred-sweep (NON-BD-206-blocking):**
- `RESEARCH-ORDER-MD-RENAME-CENSUS.md`: **56** literal `_order.md`
  occurrences across **14** files (all design/entry/report TEXT; **0**
  built files; **0** validator/test hardcodes; **3** BD entries: BD-202,
  BD-203, BD-206). Pure text edit. The BD-206 entry's DEFERRED-SWEEP
  ANCHOR (2026-06-13) flags this for a thorough researcher+architect sweep
  WHEN `_index.md` usage+operations are implemented — i.e. it rides WITH
  the BD-206 Track-B implementation, not before.

### 5.2 Count reconciliation
- DOC surfaces (A+B): 8 + 2 = **10 files** (the trinity counts as 3
  physical files → 12 physical files if the trinity is expanded).
- CODE surfaces (C+D+E+F+G): 3 + 1 + 1(file, 2 checks) + 1–2 + 1–2 =
  **7–9 production files** touched.
- TEST surfaces (H): **≥6 test files** + `manifest.txt`.
- Rename-sweep (I): **14 files / 56 refs** — deferred, rides with Track-B.
- **Grand total production+doc touch: ~17–21 files**, plus ≥7 test/fixture
  files, plus the 14-file rename sweep (deferred). Reconciles two ways:
  (a) by the mirror-generation call sites (2 production callers →
  init-project + migrator) and (b) by the "regenerated mirror" doc-string
  census (the 3 `_intro.md` + 3 `_rules.md` + trinity + MIGRATION +
  2 skill masters = the doc set).

---

## 6. Open questions for the architect (not decided here)

- **OQ-1 (phase grouping):** is "TDs-grouped-by-phase" a REQUIRED view of
  the standard or an OT habit? Drives D-A1 vs D-A2/D-A3. Resolve against
  the standard, not OT.
- **OQ-2 (`_index.md` machinery):** own generator + own CI in-sync check,
  or fold into `toc-regenerate.sh`? Measure-then-bound.
- **OQ-3 (STATUS link target):** per-entry file path vs `_toc.md`/
  `_index.md` anchor as the canonical flat-file phase-link form.
- **OQ-4 (migrator verification gate):** with no mirror, how does S5d
  verify decomposition completeness (tree-vs-input anchor census replacing
  the mirror round-trip)?
- **OQ-5 (Check 32/33 project-side):** invert/retire like Check 32′, or a
  different project-side shape? Reconcile with `_index.md` in-sync.
- **OQ-6 (impl-plan non-phase scaffolding):** confirm the 4 OT non-phase
  H2s (and any general scaffolding) carry no entry-state before dropping
  (BD-203 "when in doubt, preserve").
- **OQ-7 (v10.3 fidelity):** is a v10.3-EXACT census required (full-depth
  clone + checkout, or a scrubbed committed fixture), or is the post-v10.3
  HEAD shape sufficient as a stress input? The user's "scrubbed committed
  fixtures preferred for CI" suggests building a fixture is the right
  long-term move.

---

## 7. Rules-Applied Verification Block

| Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|
| **Agents never commit / never write to real OT** | No `git add/commit/push/tag` run. OT accessed via `git clone --depth 50 … /tmp/ot-bd206-census` (read-only); `rm -rf /tmp/ot-bd206-census` ran → stdout `removed /tmp/ot-bd206-census`. No write to the remote (clone only). | COMPLIANT |
| **Read-only mandate (one report only)** | Sole filesystem write is this report at `maintenance-docs/v11-implementation/RESEARCH-BD-206-PROJECT-CONVERSION.md` (+ the transient /tmp clone, removed). No edits to any repo file. | COMPLIANT |
| **Generalized-only (OT is a stress input, never a spec)** | §2 enumerates surfaces from the STANDARD with zero OT references; §3 options each carry a "GENERALIZED-ONLY note" deriving from the standard + existing engine; §4 census labeled "STRESS INPUT" with SF-1..SF-4 framed as general engine properties OT made visible. | COMPLIANT |
| **Researcher does not design** | Header states "Researcher does NOT design"; §3 presents OPTION SPACES (D-A1/2/3, D-B1/2/3, D-C1/2) + §6 lists 7 open questions; no option is prescribed/selected. | COMPLIANT |
| **Empirical-Evidence blocks (command + verbatim output + HEAD/date + conclusion)** | §1.1/§2.1/§2.2 carry command + quoted output + `HEAD f858d90` / 2026-06-13 + SUPPORTED conclusions; §4 carries the clone command, the verbatim failure ("Remote branch v10.3 not found"), the HEAD `3a79a92`, counts (113/61/55/63), and conclusions. | COMPLIANT |
| **Exhaustive blast-radius, counts reconciled** | §5 enumerates groups A–I, categorizes every surface, and §5.2 reconciles counts TWO ways (call-sites + doc-string census). | COMPLIANT |
| **Rules-Applied Verification Block present** | This table. | COMPLIANT |
| **PREFLIGHT + STOP-MEANS-STOP** | Emitted `PREFLIGHT: BD-206 research complete; about to Write <path>` before this Write; no parent stop received. | COMPLIANT |
