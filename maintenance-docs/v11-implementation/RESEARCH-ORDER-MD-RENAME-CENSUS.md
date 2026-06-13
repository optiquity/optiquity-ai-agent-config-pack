# RESEARCH — `_order.md` → `_index.md` rename + scope-broadening census

> **Audience:** Pack Chat + a future architect/coder.
> **Purpose:** READ-ONLY blast-radius census of every reference to the
> predesigned-but-unbuilt sidecar file `_order.md`, so a coder can later
> rename it `_index.md` and broaden its scope. This doc CHANGES nothing
> else; it CATEGORIZES, it does NOT decide.
> **HEAD:** `6d5ba2dfcfa65dc853b1b58c40e1f72560674b93` (branch `v11-dev`), 2026-06-13.

---

## 0. The intended change (framing only — NOT applied here)

`_order.md` → `_index.md`, with a broadened definition: `_index.md` is a
sidecar alongside `_intro.md` / `_rules.md` / `_toc.md` that may carry ONE OR
MORE indexes/graphs for the per-entry flat files — ORDER or GROUPINGS, and
OPTIONALLY a dependency graph (which MAY reference entries in another
directory, e.g. TD entries depending on phase/implementation-plan entries).
The dependency graph is NOT a default — created only if needed.

**Critical state fact (measured):** `_order.md` is PREDESIGNED but UNBUILT.
**Zero files named `_order.md` exist anywhere in the tree.** Every occurrence
below is a *textual reference in a design/entry/report doc*, never a built
sidecar. This makes the rename a pure documentation/text edit — there is no
built file to `git mv`, no validator/test that hardcodes the basename, no
generated content to migrate.

---

## 1. Headline counts (reconciled — see §6 for arithmetic)

| Metric | Value |
|---|---|
| Literal `_order.md` occurrences (lines), whole tree | **56** |
| Distinct files containing literal `_order.md` | **14** |
| Built files named `_order.md` (or `_order*`) | **0** |
| `_order-generate.sh` (the predesigned generator script) references | **12** (all in 1 archive doc) |
| Validator/test files hardcoding the basename | **0** |
| BD entries referencing `_order.md` | **3** (BD-202, BD-203, BD-206) |

---

## 2. Full occurrence list (path:line — surface class — what it says)

Surface classes:
- **ENTRY** = a `/backlog/BD-NNN.md` per-entry file (live SSOT).
- **PREDESIGN** = an architecture/decision/audit design doc in `maintenance-docs/v11-implementation/`.
- **PREDESIGN-ARCHIVE** = a design/report doc under `maintenance-docs/archive/v11/` (historical).
- **PLAN/REVIEW/IMPL** = a BD-214 pipeline plan / review / impl-report doc (recent, active pipeline).

### 2.1 ENTRY surface (3 files, 6 lines)

| path:line | what it says |
|---|---|
| `backlog/BD-202.md:14` | Reversal-trigger note: post-BD-206 the managed assets become "per-entry trees + `_order.md`"; re-assess `cmd_update` AC-1..AC-4 taxonomy against that asset set. |
| `backlog/BD-203.md:5` | D1 meta-doc governance: "every meta-doc (`_intro.md`/`_rules.md`/`_toc.md`/`_order.md`) states audience+purpose at the top." (`_order.md` listed as a prospective meta-doc.) |
| `backlog/BD-206.md:6` | RE-SCOPE finding: `_order.md` is the flat-file execution-ordering support-file, PREDESIGNED but UNBUILT (zero exist — measured); BD-206 must CREATE it for the project implementation-plan stream; reconcile predesign → BD-203 as-built. |
| `backlog/BD-206.md:13` | "ADD (US-6) — `_order.md` create/reconcile" clause; CREATE the support-file for the implementation-plan stream; predesign pointers (`ARCHITECTURE-BD-185-V2.md` §5.3, `-ORDERING-ADDENDUM` §A-1, `BD-203-V3-AMENDMENT` §F.3). |
| `backlog/BD-206.md:16` | "TRACK B: the conversion + `_order.md` IMPLEMENTATION is Track-B work." |
| `backlog/BD-206.md:18` | Acceptance criteria: "the project implementation-plan stream carries an `_order.md` execution-ordering support-file reconciled to the BD-203 as-built shape." |

### 2.2 PREDESIGN surface — `maintenance-docs/v11-implementation/` (9 files, 39 lines)

| path:line | what it says |
|---|---|
| `ARCHITECTURE-BD-185-V2.md:379` | "`_order.md` convenience view is a regenerated view of the SSOT, never the [SSOT]." |
| `ARCHITECTURE-BD-185-V2.md:645` | "Any `_order.md` convenience view (if [used]) … display change, not an ownership change." |
| `ARCHITECTURE-BD-185-V2.md:1009` | "CR-8 (prior D7) — ordering SSOT on the phase entity; `_order.md` a view." |
| `ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md:111` | Ordering "NOT [owned] by any `_order.md` view, NOT by a flat-file mirror in tracker [mode]." |
| `ARCHITECTURE-BD-203-V3-AMENDMENT.md:181` | §F.3 D1 governance: meta-docs state audience+purpose "… and `_order.md` if ever used." (canonical predesign anchor BD-206 points to) |
| `AUDIT-BD-195-RETAINED-DECISIONS.md:568` | OQ-6 — `_order.md` separate-file decision (D7) header. |
| `AUDIT-BD-195-RETAINED-DECISIONS.md:569` | "D7 locked `_order.md` as a separate per-entry supporting file (POQ-3 'Option Y')." |
| `AUDIT-BD-195-RETAINED-DECISIONS.md:571` | "(ordering value owned by the phase entity; any `_order.md` is a [regenerated view])." |
| `AUDIT-BD-195-RETAINED-DECISIONS.md:572` | "treats whether an `_order.md` view file is [created as open]." |
| `AUDIT-BD-195-RETAINED-DECISIONS.md:577` | "`_order.md` separate-file decision (D7) retained as a hard requirement, or [revisit]." |
| `DECISION-PER-ENTRY-FORK-AND-BD185-SEQUENCING.md:91` | Quotes ORDERING-ADDENDUM A-1: "NOT [owned] by any `_order.md` view…" |
| `DECISION-PER-ENTRY-FORK-AND-BD185-SEQUENCING.md:171` | Same A-1 quote (un-backticked: "NOT owned by … any _order.md view…"). NOTE: bare `_order.md` inside a block-quote — easy to miss in a backtick-only grep. |
| `ARCHITECTURE-BD-214-TRACKER-DEFERRAL.md` (21 lines) | Lines 10, 22, 31, 32, 38, 76, 655, 680, 690, 713, 715, 717, 720, 733, 735, 751, 824, 831, 834, 842, 844. The US-6 finding + the §9 BD-206 row + §10.5 Track-B carve-out + Empirical-Evidence Block (831) measuring zero built files + Rules-Applied reconciliation row (834). This is the design doc that COINED the current "predesigned-but-unbuilt" framing the BD entries inherit. |

### 2.3 BD-214 PIPELINE — PLAN / REVIEW / IMPL (3 files, 6 lines)

| path:line | class | what it says |
|---|---|---|
| `PLAN-BD-214-TRACKER-DEFERRAL.md:62` | PLAN | Track-B list: "BD-206 conversion + `_order.md`, BD-216 tracker legs." |
| `PLAN-BD-214-TRACKER-DEFERRAL.md:67` | PLAN | "(… `_order.md`, work-item.yml Part field)." |
| `PLAN-BD-214-TRACKER-DEFERRAL.md:358` | PLAN | BD-206 row: "ADD … `_order.md` create/reconcile directive (predesigned-but-unbuilt…)." |
| `PACK-REVIEW-BD-214-C5a.md:106` | REVIEW | BD-206 row "… `_order.md` …; CORRECT." |
| `PACK-REVIEW-BD-214-C5a.md:158` | REVIEW | "`_order.md` create + reconcile-to-BD-203 directive ADDED …" |
| `IMPL-REPORT-BD-214-C5a.md:95` | IMPL | "CREATE `_order.md` + reconcile to BD-203 as-built: … clause with the predesign pointers …" |

### 2.4 PREDESIGN-ARCHIVE surface — `maintenance-docs/archive/v11/` (2 files, 11 lines)

| path:line | what it says |
|---|---|
| `IMPLEMENTATION-REPORT-BD-185-ARCHITECT-DOC-EDITS.md:130` | "§4.B6 — §5.3 LOCK `_order.md` + NEW §5.X SSOT subsection (D7)." |
| `IMPLEMENTATION-REPORT-BD-185-ARCHITECT-DOC-EDITS.md:132` | "§5.3 — locked `_order.md` as separate file (Option Y)…" |
| `IMPLEMENTATION-REPORT-BD-185-ARCHITECT-DOC-EDITS.md:134` | "`_order.md` is LOCKED as a separate per-entry supporting file … `_order.md` = regenerated view (never SSOT)…" |
| `IMPLEMENTATION-REPORT-BD-185-POST-PLANNER-POQS.md` (8 lines) | Lines 396, 403, 404, 413, 420, 431, 432, 585. POQ-5: the predesigned `_order-generate.sh` script that would EMIT `_order.md`; `mirror-generate.sh` orchestration; H.7 doc-edit framing. |

### 2.5 Related token — `_order-generate.sh` (the predesigned GENERATOR; 12 lines, all in 1 archive doc)

`maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-185-POST-PLANNER-POQS.md`
lines 18, 385, 403, 404, 405, 414, 420, 421, 432, 437, 585, 694. This is the
predesigned NEW script `scripts/lib/per-entry/_order-generate.sh` (+ its test
`scripts/tests/test-_order-generate.sh`) that would generate `_order.md`. It
is ALSO unbuilt (no such script exists — confirmed: zero hits in `scripts/`).
**Flag for user/architect:** if `_order.md`→`_index.md` AND the generator is
ever built, the generator would presumably be `_index-generate.sh`. This is a
PREDESIGN-ARCHIVE reference — see disposition (b).

---

## 3. The BD entries that reference `_order.md` (verbatim quotes)

Three BD entries reference it. Quotes are byte-faithful to HEAD `6d5ba2d`.

**BD-202** (`backlog/BD-202.md:14`):
> "NOTE: BD-206 (project-side per-entry no-mirror conversion) CHANGES the
> asset-class set this engine operates on (the project monoliths are deleted;
> per-entry trees + `_order.md` become the managed assets), so re-assess the
> AC-1..AC-4 taxonomy coverage against the post-BD-206 asset set."

**BD-203** (`backlog/BD-203.md:5`):
> "Meta-doc governance (D1): `_rules.md` = the SOLE rules SSOT (never
> duplicated/fragmented); `_intro.md` = human-only/agent-ignorable; every
> meta-doc (`_intro.md`/`_rules.md`/`_toc.md`/`_order.md`) states
> audience+purpose at the top — the pack adopts this now; BD-206 inherits it
> for project."

**BD-206** (`backlog/BD-206.md`, the PRIMARY home — 4 occurrences):
- L6: "`_order.md` FINDING: the flat-file execution-ordering support-file
  `_order.md` is PREDESIGNED but UNBUILT (zero `_order.md` files exist in the
  tree — measured); BD-206 must CREATE it for the project implementation-plan
  stream (phase order is NOT numerically recoverable from filenames the way
  `/backlog/` BD-NNN ordering is); if the predesign conflicts with the BD-203
  as-built per-entry shape, the predesign is UPDATED to match BD-203 (BD-203
  as-built wins)."
- L13: "**ADD (US-6) — `_order.md` create/reconcile:** CREATE the flat-file
  execution-ordering support-file `_order.md` for the project
  implementation-plan stream … `_order.md` is PREDESIGNED but UNBUILT … the
  predesign lives in `ARCHITECTURE-BD-185-V2.md` §5.3,
  `ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md` §A-1, and
  `ARCHITECTURE-BD-203-V3-AMENDMENT.md` §F.3."
- L16: "**TRACK B:** the conversion + `_order.md` IMPLEMENTATION is Track-B
  work."
- L18: "the project implementation-plan stream carries an `_order.md`
  execution-ordering support-file reconciled to the BD-203 as-built shape."

---

## 4. Per-occurrence disposition categories (propose, don't decide)

### (a) ENTRY references — RENAME `_order.md`→`_index.md` + broaden scope
These are live SSOT entries; they carry the directive a future Track-B coder
executes, so they MUST reflect the new name + broadened definition.
- `backlog/BD-206.md` (L6, L13, L16, L18) — PRIMARY. The create/reconcile
  directive. Beyond the rename, the broadened definition (one-or-more
  indexes/graphs incl. optional cross-directory dependency graph) materially
  changes what BD-206 must build — this is a **scope edit**, not just a token
  swap. Flag: editing a landed BD's substance = MAJOR per pack rules (route to
  coder under Pack Chat scoping; new wording is governance the user approves).
- `backlog/BD-203.md:5` — the D1 meta-doc-governance list. Rename
  `_order.md`→`_index.md` in the meta-doc enumeration (or generalize wording).
- `backlog/BD-202.md:14` — incidental "managed assets" mention; rename for
  consistency.

### (b) PREDESIGN / PREDESIGN-ARCHIVE references — SURFACE for user/architect, do NOT auto-edit
Historical design/decision/report docs. Two sub-questions the user/architect
must answer (this census does NOT resolve them):
1. Should these be updated to the new name for forward-consistency, OR left
   as as-was history (the docs record decisions made under the old name)?
2. If the dependency-graph broadening lands, the "ordering convenience view"
   framing in `ARCHITECTURE-BD-185-V2.md` (379/645/1009) and the
   ORDERING-ADDENDUM become semantically narrow — they describe `_order.md`
   as an ORDER view only, not a multi-index/graph sidecar.
   - PREDESIGN (active design docs): `ARCHITECTURE-BD-185-V2.md` (3),
     `ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md` (1),
     `ARCHITECTURE-BD-203-V3-AMENDMENT.md` §F.3 (1 — the canonical anchor
     BD-206 cites; if this is NOT updated, BD-206's pointer still resolves but
     to old-name text), `AUDIT-BD-195-RETAINED-DECISIONS.md` (5),
     `DECISION-PER-ENTRY-FORK-AND-BD185-SEQUENCING.md` (2),
     `ARCHITECTURE-BD-214-TRACKER-DEFERRAL.md` (21).
   - PIPELINE PLAN/REVIEW/IMPL: `PLAN-BD-214-TRACKER-DEFERRAL.md` (3),
     `PACK-REVIEW-BD-214-C5a.md` (2), `IMPL-REPORT-BD-214-C5a.md` (1) —
     completed-pipeline records; almost certainly as-was history.
   - PREDESIGN-ARCHIVE: both `archive/v11/` docs (11) + the 12
     `_order-generate.sh` lines — archived; default as-was history.
   - **Recommendation surfaced (not decided):** the BD-203/BD-185-V2/
     ORDERING-ADDENDUM/BD-203-V3-AMENDMENT chain is the live PREDESIGN that
     BD-206's Track-B will reconcile against — if these keep the old name, the
     Track-B coder reads `_order.md` from the predesign and `_index.md` from
     the entry, a name mismatch. The `archive/v11/` and completed
     BD-214-pipeline records are far better left as history. The decision is
     the user/architect's per the predesign-doc-vs-entry split.

### (c) Stream-contract (`_rules.md`) "Supporting files" lists — ADD `_index.md` where the sidecar will live
**No `_rules.md` file contains the string `_order.md` today** (so none is a
RENAME occurrence). They are instead the CONTRACT surfaces that must be
EXTENDED if `_index.md` becomes a sanctioned sidecar basename — otherwise the
"Supporting files" allowlist treats `_index.md` as a SKIP-unrecognized file.
All five LIVE stream `_rules.md` files enumerate exactly `_rules.md` /
`_intro.md` / `_toc.md`:
- `backlog/_rules.md:82-86` (pack backlog) — "## Supporting files" list.
- `changelog/_rules.md:57-61` (pack changelog).
- `project-template/docs/project/backlog/_rules.md:32-36`.
- `project-template/docs/project/changelog/_rules.md:33-37`.
- `project-template/docs/project/implementation-plan/_rules.md:33-37`
  — **THE stream BD-206 must add the sidecar to** (phase order isn't
  filename-recoverable). This is the one `_rules.md` that DEFINITELY needs
  `_index.md` added to its Supporting-files list.
- Plus 9 test-fixture `_rules.md` copies (3 streams × 3 fixtures under
  `test-fixtures/v11-flat-file|v11-realistic-ot|v11-tracker-on/docs/project/
  .../_rules.md`) — same 3-item list; would need the same addition wherever
  the fixture is expected to carry the sidecar. (Whether fixtures carry
  `_index.md` is a Track-B fixture-design call.)
- **Flag:** whether to add `_index.md` to backlog/changelog Supporting-files
  lists too (not just implementation-plan) depends on whether the broadened
  `_index.md` (groupings/dependency-graph) is intended for those streams. The
  broadened definition explicitly allows cross-directory dependency graphs
  (TD→phase), which implies `_index.md` could live in MORE than just
  implementation-plan. **Surface for architect** — do not assume.

### (d) Validator / test hardcoding the basename — NONE
`grep _order.md|_order-generate` across `scripts/` and `test-fixtures/`
returns ZERO. No validator (`validate-pack.py`, per-check tests), no
per-entry library script, no test fixture references the basename. The
"Supporting files" allowlist is enforced by the stream `_rules.md` contract
prose + the per-entry tooling, but the tooling does not hardcode
`_order.md`/`_index.md` today. The future coder adds `_index.md` to the
contract lists (category c); there is no code constant to flip.

---

## 5. Disposition summary table

| Category | Files | Lines | Action class |
|---|---|---|---|
| (a) ENTRY — rename + broaden | 3 (BD-202/203/206) | 6 | RENAME + scope edit (BD-206 = MAJOR scope edit) |
| (b) PREDESIGN/ARCHIVE/PIPELINE — surface, don't auto-edit | 11 | 50 | USER/ARCHITECT decision (consistency-update vs as-was history) |
| (c) `_rules.md` Supporting-files lists — ADD `_index.md` | 5 live (+9 fixtures) | 0 `_order.md` hits | EXTEND contract (not a rename; an addition) |
| (d) validator/test hardcoded basename | 0 | 0 | none |

(a)+(b) line totals: 6 + 50 = 56 = the whole-tree literal count. ✓

---

## 6. Count reconciliation (≥2 independent ways — arithmetic shown)

**Way 1 — whole-tree single grep:**
`grep -rn "_order\.md" . --exclude-dir=.git | wc -l` → **56**.
`grep -rl "_order\.md" . --exclude-dir=.git | wc -l` → **14** distinct files.
(HEAD `6d5ba2d`, 2026-06-13.)

**Way 2 — per-file sum (`grep -rc`, zero-lines filtered):**
backlog/BD-202.md=1, backlog/BD-203.md=1, backlog/BD-206.md=4,
archive/…BD-185-ARCHITECT-DOC-EDITS=3, archive/…BD-185-POST-PLANNER-POQS=8,
ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM=1, ARCHITECTURE-BD-185-V2=3,
ARCHITECTURE-BD-203-V3-AMENDMENT=1, ARCHITECTURE-BD-214-TRACKER-DEFERRAL=21,
AUDIT-BD-195-RETAINED-DECISIONS=5, DECISION-PER-ENTRY-FORK…=2,
IMPL-REPORT-BD-214-C5a=1, PACK-REVIEW-BD-214-C5a=2,
PLAN-BD-214-TRACKER-DEFERRAL=3.
Sum = 1+1+4+3+8+1+3+1+21+5+2+1+2+3 = **56**. File count = **14**. ✓

**Way 3 — per-top-level-directory file + line totals:**
Files: backlog=3, maintenance-docs/archive/v11=2, maintenance-docs/v11-implementation=9 → 3+2+9 = **14**. ✓
Lines: backlog=(1+1+4)=6, archive=(3+8)=11, v11-implementation=(1+3+1+21+5+2+1+2+3)=39 → 6+11+39 = **56**. ✓

All three ways agree: **56 lines across 14 files.**

**Built-file count:**
`find . -path ./.git -prune -o -name '_order*' -print` → EMPTY → **0** built
files. Corroborated by BD-206/BD-214 Empirical-Evidence Blocks
(`ARCHITECTURE-BD-214-TRACKER-DEFERRAL.md:831`) which measured the same.

---

## 7. Completeness self-check — what could still hide a reference, and why none remain

1. **Case / spacing variants.** `_order.md` is a fixed snake_case basename;
   no plausible case variant. The bare-`_order` grep (51KB output) surfaced
   only `task_order`, `execution_order`, `provider_order_*`, `group_order`,
   `ours_order`, `pack_only_order`, `process_order`, `phase_execution_order`
   — all unrelated identifiers/fields, NOT the sidecar concept. The ONLY
   sidecar-adjacent non-`.md` token is `_order-generate.sh` (§2.5), captured.
2. **Block-quote / un-backticked prose.** Caught
   `DECISION-PER-ENTRY-FORK…:171` ("any _order.md view") which lacks
   backticks — the literal `_order.md` grep (no backtick requirement) caught
   it. No backtick-only filter was used.
3. **Binary / generated files.** None: `manifest.txt`, fixtures, and scripts
   were grepped; zero hits outside the 14 markdown docs.
4. **Other surfaces explicitly checked = ZERO:** `pack-ops/`,
   `supporting-docs/`, `README.md`, the pack-root + `project-template`
   trinity (`CLAUDE/AGENTS/GEMINI.md`), all `_rules.md`/`_intro.md`/`_toc.md`
   sidecars, `maintenance-docs/v11-research/` (incl. TOUCH-POINT-INVENTORY).
5. **`.git/` excluded by mandate** — not in scope.
6. **The 14 files were each read in surrounding context** to characterize
   what each occurrence claims `_order.md` is/does.

**Conclusion:** the census is exhaustive for the sidecar-file concept. 56
literal occurrences across 14 files + 12 `_order-generate.sh` lines in 1
archive doc; 0 built files; 0 validator/test hardcodes; 3 BD entries
(BD-202/203/206, BD-206 primary). The rename is a documentation/text edit
with NO file move and NO code-constant flip.

---

## 8. Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| 1. Agents never commit | No `git add/commit/push/tag` run. Only `git rev-parse HEAD` (→ `6d5ba2d…`), `git status --short`, `git branch --show-current` (→ `v11-dev`) — all read-only. | COMPLIANT |
| 2. Read-only mandate (Write ONLY the report) | Sole filesystem write is this report at `maintenance-docs/v11-implementation/RESEARCH-ORDER-MD-RENAME-CENSUS.md` (a non-existent path before this run). All other tools were `Read`/`grep`/`find` (read-only). No other file edited. | COMPLIANT |
| 3. Exhaustive blast-radius census; counts reconciled ≥2 ways with arithmetic | §6 shows 3 independent reconciliations (whole-tree grep `wc -l`=56/files=14; per-file `grep -rc` sum=56/14; per-dir totals 6+11+39=56, 3+2+9=14) — all agree. Built-file count 0 via `find … -name '_order*'` → EMPTY. Every occurrence enumerated in §2 with path:line + class. | COMPLIANT |
| 4. Empirical-Evidence Blocks (command + verbatim output + HEAD-SHA + interpretation + conclusion) | Each count carries its exact command (`grep -rn "_order\.md" . --exclude-dir=.git \| wc -l` → 56; `grep -rl … \| wc -l` → 14; `find … -name '_order*'` → EMPTY; per-file `grep -rc`), captured output, HEAD `6d5ba2dfcfa65dc853b1b58c40e1f72560674b93`, date 2026-06-13, and a SUPPORTED conclusion (§1, §5, §6). | COMPLIANT |
| 5. Categorize, don't decide | §4 proposes disposition CLASSES (a)/(b)/(c)/(d); the predesign-doc-vs-entry consistency question (§4b), the which-streams-get-`_index.md` question (§4c), and the `_order-generate.sh`→`_index-generate.sh` question (§2.5) are all explicitly SURFACED for user/architect, not resolved. No unilateral edit decision made. | COMPLIANT |
| 6. Rules-Applied Verification Block present | This table. Each row: rule name + quoted/measured evidence + terminal conclusion (no empty evidence; no AMBIGUOUS). | COMPLIANT |
| 7. PREFLIGHT + STOP-MEANS-STOP | Emitted `PREFLIGHT: census complete; about to Write <path>` in the assistant turn immediately before this Write. No parent stop/halt message was received. | COMPLIANT |
