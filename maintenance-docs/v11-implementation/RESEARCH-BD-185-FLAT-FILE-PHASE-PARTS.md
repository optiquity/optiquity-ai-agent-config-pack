# RESEARCH — BD-185 flat-file phase-parts lifecycle + deterministic serialization (v11.0)

> **Agent:** pack-docs-researcher (fresh) · **Mode:** READ-ONLY · **Date:** 2026-06-13
> **HEAD (measured):** `f858d90ec0bd12492944aba457bebb0b91285081` · **Branch:** `v11-dev`
> **Output:** this single file. Nothing else changed; no git verb run.
> **Role discipline:** this is a FACT BASE + OPTION SPACE for the architect. It does
> NOT pick the final serialization shape. Where the prompt asks for "candidate shapes,"
> they are presented as options with trade-offs, not a recommendation.

This pass covers the FLAT-FILE half of BD-185 (re-scoped 2026-06-13; tracker legs are
BD-216, deferred). It EXPANDS the pre-existing queued charter
(`BD-185-DOCS-RESEARCHER-QUEUED-PROMPT.md`) to add the two new obligations the 2026-06-13
re-scope introduced: (1) the SC-SER deterministic-serializability constraint that lets
BD-215 round-trip phase-parts, and (2) the `_index.md` reconciliation (the renamed,
broadened sidecar). It draws on the predesign chain (ARCHITECTURE-BD-185-V2 + its
ORDERING-ADDENDUM + BD-203-V3-AMENDMENT) and the rename census.

---

## §0 — Scope boundary (what this entry owns vs BD-216)

Measured from `backlog/BD-185.md` + `backlog/BD-216.md` (HEAD `f858d90`):

| Concern | Owner | Status |
|---|---|---|
| Flat-file phase split at creation (two phases, immutable numbers) | BD-185 (SC1) | v11.0, this pass |
| Flat-file mid-work phase→parts expansion (Phase N → Part 1..p) | BD-185 (SC2) | v11.0, this pass |
| No-renumber invariant across the transition (phase numbers + N.M task IDs) | BD-185 (SC3) | v11.0, this pass |
| Flat-file execution ordering via execution notes, deterministically serializable | BD-185 (SC4 flat leg) | v11.0, this pass |
| STATUS.md stays a dashboard (not promoted to ordering SSOT) | BD-185 (SC5) | v11.0, this pass |
| v10→v11 whole-number-phase pass-through | BD-185 (SC8 flat leg) | v11.0, this pass |
| ONE canonical machine-parseable serialization (no free-prose ambiguity) | BD-185 (SC-SER, US-4 HARD) | v11.0, this pass — the new constraint |
| Tracker form-family Part field + `part:M` label namespace | BD-216 (SC6) | DEFERRED — out of scope here |
| TrackerProvider bi-directional sync of part membership + order | BD-216 (SC7) | DEFERRED — out of scope here |
| Tracker-native execution ordering (Issue Fields / sub-issue reprioritize) | BD-216 (SC4-tracker, SC8-tracker) | DEFERRED — out of scope here |
| Lossless round-trip flat↔tracker | BD-216 (SC-RT) | DEFERRED — out of scope here |

**Consequence for the architect.** Much of the predesign chain (V2 §5.1/§5.2,
the entire ORDERING-ADDENDUM, V2 §4.2/§4.4 tracker form-family, V2 §6.2/§6.4 tracker
migration, V2 §7 TrackerProvider ops) is now BD-216 material and OUT OF SCOPE for
BD-185. BD-185 keeps only the flat-file slices: V2 §2.A semantics, §4.3 flat-file
Parts, §5.3 flat-file ordering marker, §5.4 STATUS.md, §6.1 Phase A, §6.3
execution-note handling. **The architect must NOT carry the tracker design forward
into BD-185** — that would re-merge the split. (See §5 blast radius for the precise
in-scope surface set.)

---

## §1 — CURRENT STATE: what METHODOLOGY codifies today vs the gaps

### §1.1 — Location correction (the BD entry's line cite has drifted)

The BD-185 entry cites METHODOLOGY "Part 3 § Multi-part phases (lines ~339-366)".
**Measured:** the "Multi-part phases" sub-section is under **Part 4 — Phase Structure**
(`## Part 4 — Phase Structure` at L366), and the sub-section header
`### Multi-part phases` is at **L414** (body L414–441). "Part 3" in METHODOLOGY is the
Agent Roster (L264). The V2 architect doc already noted this drift (V2 §1.3:
"current L414–441; the BD-185 entry's ~339–366 cite has drifted"). The architect
should anchor on the **section name** ("Multi-part phases" under "Part 4 — Phase
Structure"), never the line numbers.

### §1.2 — What the current "Multi-part phases" sub-section codifies (L414–441, quoted)

The entire current codification is a STATIC authoring convention, not a lifecycle:

```
### Multi-part phases

When a planning agent recommends splitting a phase into sequential implementation
chunks, use **Part** as the term for each chunk — never "pass." "Pass" is a reserved
term for the coder/reviewer cycle counter within a single coder or fix-cycle prompt.

**In IMPLEMENTATION-PLAN.md:** Label each chunk as a sub-section within the phase:

### Part 1 — [Subtitle]
...tasks, files, definition of done...

### Part 2 — [Subtitle]
...tasks, files, definition of done...

**Report headers for multi-part phases:** Append `, Part [M]` to the phase title
placeholder. The pass counter resets to 1 at the start of each new part.

| Report type | Header format | ... Part [M] ... |

A single-part phase uses the existing header format unchanged — do not append `, Part 1`
when there is only one part. ...
```

Plus two adjacent rules under `### Phase numbering rules` (L407–412, quoted):

```
- Never renumber phases — phase numbers are referenced in code comments, CHANGELOG, and BACKLOG.
- To reorder execution, use execution notes (`> **Execution note**:`), not renumbering.
- Insert new phases at the end of the plan.
- Fractional phases (2.1, 2.2) only during early architecture work — use whole numbers after that.
```

And the phase format (L368–405, quoted in part):

```
## Phase N — [Title]
**Goal**: One sentence ...
**Prerequisite**: Which prior phase must be complete.
> **Execution note**: (optional) deliberate deferral or ordering constraint.
### Tasks
#### N.1 — [Task title]
  ... **Dependencies**: ... phase-N / phase-N.M / TD-NNN ...
```

**What today's codification provides (FACTS):**
- A naming convention: chunks are **Parts** (`### Part M — [Subtitle]`), never "passes."
- Parts are authored as **H3 sub-sections inside the phase's H2** (`## Phase N`).
- A report-header convention (`, Part [M]`, pass counter resets per part).
- Single-part phases keep the un-suffixed format (no `, Part 1`).
- Ordering today = `> **Execution note**:` PROSE + "insert at end" + "never renumber."
- Tasks are `#### N.M` H4 sub-sections; their `**Dependencies**:` reference
  `phase-N` / `phase-N.M` / `TD-NNN` (parser regex L388:
  `^\s*-\s+(phase-\d+(\.\d+)?|TD-\d+)(\s+(.*))?$`).

### §1.3 — The GAPS (what is MISSING for BD-185 SC1–SC8 + SC-SER)

| # | Gap | Evidence it is missing |
|---|---|---|
| G1 | **Mid-work phase→parts EXPANSION mechanism** (lifecycle). The current text is an authoring convention for a phase that is *born* multi-part-ish; there is NO documented procedure for taking an EXISTING `## Phase N` with `#### N.1..N.k` tasks and grouping those existing tasks under new `### Part` sub-sections mid-work. | L414–441 only describes the static label format; no "how to expand" steps, no task-regrouping rule. |
| G2 | **parts-are-evolution-only semantic** is NOT stated. `[[reference_pack_entry_type_semantics]]`: phases are NEVER created with parts; parts are evolution-only; tasks are phase components; groupings contain phases only. METHODOLOGY never says a phase begins with ZERO parts, nor that a too-big-at-birth phase splits into TWO phases (not a born-split phase). | No "phases begin with zero parts" / "oversize-at-birth → two phases" rule in L407–441. The V2 doc §2.A states it as a FIXED input, but METHODOLOGY itself does not codify it. |
| G3 | **phase↔part↔task relationship rules.** No statement of: a Part belongs to exactly one phase; a task belongs to exactly one Part once split (re-parented from phase to Part); no empty Parts; no collapse/delete; no mid-life re-parenting; deferral is the only exit for an unused Part. | These invariants live ONLY in V2 §2.A as "FIXED inputs," not in the client-facing METHODOLOGY. |
| G4 | **no-renumber-across-transition INVARIANT** is stated for phases ("never renumber phases," L409) and for reorder-via-notes (L410), but NOT for the part-expansion transition specifically — i.e., when Phase N → Part 1..p, the existing N.1..N.k task IDs MUST survive unrenumbered (SC3). The current text never connects "never renumber" to the parts transition. | L409–410 covers phase renumbering + reorder; nothing covers task-ID preservation under part grouping. |
| G5 | **DETERMINISTIC SERIALIZABILITY (SC-SER)** is entirely absent. The current representation is FREE-PROSE: `### Part M — [Subtitle]` headings (free-text subtitle), `#### N.M` tasks, and `> **Execution note**:` prose ordering. There is no machine-parseable membership/ordering serialization; nothing pins a canonical order; nothing forbids ambiguous prose. SC-SER did not exist when L414–441 was authored. | No marker, no structured field, no ordering field, no canonical sort defined in METHODOLOGY for parts/membership. Ordering is prose (L410). |
| G6 | **execution ordering is non-deterministic + prose-only.** `> **Execution note**:` is free prose ("optional deliberate deferral or ordering constraint"). "Insert at end" + phase-number order is the implicit default, but there is no explicit, parseable per-phase ordering field. The V2/ADDENDUM predesign proposed `<!-- execution-order: N -->` but that is UNBUILT (no marker exists in any template; grep-confirmed §1.4). | L375, L410 — prose only. No structured order field exists in `phase-N.md` template or the stream `_rules.md`. |
| G7 | **the implementation-plan per-entry stream has no parts/ordering contract.** `project-template/docs/project/implementation-plan/_rules.md` (read in full) defines the phase-entry shape (H2 `## Phase N`, Goal, Prerequisite, `### Tasks` with `#### N.M`, Verification, Agent, Risks) but says NOTHING about Parts (`### Part M` sub-sections) or any ordering field. Filename regex is `^phase-\d+\.md$` — no part-file form, which is consistent with "Parts ride inside the phase entry," but the contract never states it. | `_rules.md` "Entry contract" + "Filename convention" + "Lifecycle states" sections — zero "Part" mentions. |

**Net:** today METHODOLOGY codifies a STATIC NAMING + REPORT-HEADER convention for
parts and a PROSE ordering mechanism. BD-185 must add (a) the mid-work expansion
LIFECYCLE (G1), (b) the evolution-only + relationship semantics (G2/G3), (c) the
no-renumber-across-transition invariant (G4), and (d) a DETERMINISTIC, machine-parseable
serialization of membership + ordering (G5/G6) plus the matching stream-contract
update (G7).

### §1.4 — Empirical confirmation that the predesigned ordering marker is UNBUILT

```
$ find . -path ./.git -prune -o \( -name '_order*' -o -name '_index*' \) -print   → EMPTY
$ grep -rn "execution-order" project-template/  supporting-docs/METHODOLOGY.md    → (no <!-- execution-order --> marker)
```
HEAD `f858d90`, 2026-06-13. The `<!-- execution-order: N -->` body marker proposed
in V2 §5.3 / ADDENDUM C7 is a PREDESIGN, not a built artifact. Likewise `_order.md`
(now to be renamed `_index.md`) is predesigned-but-unbuilt (rename census measured
0 built files; re-confirmed here). The architect designs against a greenfield
flat-file ordering surface — there is no built mechanism to preserve, only the prose
convention.

---

## §2 — DETERMINISTIC-SERIALIZABILITY: the option space (SC-SER)

SC-SER (US-4 HARD): the phase→part→task structure (MEMBERSHIP + ORDERING + LIFECYCLE)
must resolve to ONE canonical machine-parseable serialization — no free-prose
ambiguity, no nondeterministic ordering — so BD-215 can round-trip it. Below are the
candidate shapes the architect must weigh. **No shape is selected here.**

### §2.1 — What "deterministically serializable" decomposes into

Three sub-properties an architect must satisfy, independent of the carrier choice:

1. **Membership is structurally encoded, not prose-inferred.** "Task N.M belongs to
   Part x of Phase N" must be readable by a parser from structure (heading nesting,
   a marker, or a field) — never inferred from free-text subtitles.
2. **Ordering is an explicit, total, stable key — not prose.** Both phase-order and
   (if parts are ordered) part-order need an explicit key with a defined sort, so two
   independent serializers produce byte-identical output. "Insert at end" + lexical
   filename sort is NOT sufficient (lexical sorts `phase-10` before `phase-2` —
   measured concern in V2 §5.3; the current `toc-regenerate.sh` uses a numeric phase
   key already, see §3.3).
3. **The grammar is closed (no ambiguity).** Headings/markers/fields have a fixed,
   regex-checkable form; a validator can grep-zero on non-conforming patterns
   (the BD-215 "validator enforces the spec" property starts here).

### §2.2 — Candidate carriers for MEMBERSHIP (phase→part→task)

| Option | Shape | Pros | Cons / open issues |
|---|---|---|---|
| **M-A — Heading nesting (status quo, formalized)** | `## Phase N` → `### Part a — <sub>` → `#### N.M — <task>` inside `phase-N.md`. Membership = "which `### Part` heading the `#### N.M` falls under." | Zero new file types; matches the V2 §4.3/§6.4 decision (Parts as H3, tasks as H4 grouped under their Part); per-entry decompose already anchors on H2 so Parts ride inside the entry (measured §3.2); minimal client churn. | Heading SUBTITLE is free prose (must be excluded from the canonical key — the Part IDENTITY must be a closed token like `Part a`, not the subtitle); requires a strict regex on the `### Part <x> —` line; "which heading a task falls under" is position-dependent parsing (fragile if headings reorder) unless each task ALSO carries an explicit part token. |
| **M-B — Per-task explicit part token** | Each `#### N.M` task carries a structured membership token, e.g. an HTML marker `<!-- part: a -->` or a field line. Membership is read from the token, not heading position. | Position-independent; a parser reads membership directly; survives heading reordering; closed grammar (regex on the token). | Adds a per-task marker (more surface); duplicates info also implied by heading nesting (must define which wins — the architect picks the SSOT). |
| **M-C — Structured index in `_index.md`** | A machine-parseable membership graph lives in the renamed sidecar `_index.md` (see §3): e.g., a fenced block listing `phase-N: parts:[a,b]; part-a: tasks:[N.1,N.2]; part-b: tasks:[N.3]`. | One canonical serialization in ONE file (the BD-215 round-trip target is then a single artifact); membership + ordering co-located; decouples the human-readable phase file from the machine form. | `_index.md` is predesigned-but-UNBUILT and its build is largely BD-206 Track-B (rename census §4a, §4c); BD-185 would either (i) define the membership grammar `_index.md` carries (design-only, BD-206 builds) or (ii) pull `_index.md` build into BD-185 scope — a scoping question for the user/architect. Risk: two SSOTs (phase file + index) need a coherence rule (the exact defect class BD-215 problem statement warns about). |
| **M-D — Hybrid (heading nesting as human form + `_index.md`/marker as machine form, one designated SSOT)** | Human reads heading nesting; the canonical machine serialization is a marker or `_index.md`; the two are kept coherent by a regenerate step (one is generated from the other). | Best human ergonomics + a clean machine form. | Coherence obligation between the two representations (BD-215's stated dominant defect source in the tracker case) — must designate ONE as SSOT and GENERATE the other, never hand-maintain both. |

### §2.3 — Candidate carriers for ORDERING (phase order; optional part order)

| Option | Shape | Pros | Cons |
|---|---|---|---|
| **O-A — Implicit phase-number order (status quo default)** | Order = ascending phase number; "insert at end"; reorder forbidden (use notes). | Already deterministic IF the sort is numeric (it is — §3.3); zero new surface; matches SC8 whole-number pass-through (phase-number == execution-order for OT-style). | Cannot express an execution order that DIFFERS from phase-number order without renumbering (the exact P3/SC4 problem); "execution notes" prose is the escape hatch but is NON-deterministic (G6). |
| **O-B — Explicit per-phase order marker** | `<!-- execution-order: N -->` (V2 §5.3 predesign) in each `phase-N.md`. Sort key = `(execution-order, phase_number, filename)`; sparse values allowed (insert 2.5 between 2 and 3 without renumber). | Explicit, parseable, sparse-friendly (no renumber on insert — satisfies SC3 + SC4); default-to-phase-number when absent (greenfield/migrated sorts by phase number = current impl order, SC8); the V2/ADDENDUM already designed this as the flat-file `order_key`. | New marker = new surface + a validator + manifest churn; UNBUILT today; must define the canonical sort tie-break exactly. |
| **O-C — Order field in `_index.md`** | A single `order:` list in the sidecar, e.g. `phase-order: [3, 1, 2, ...]`. | One canonical ordering serialization; co-located with membership if M-C/M-D chosen. | Same `_index.md` build-scope question as M-C; ordering then lives OUTSIDE the phase file (the phase file is no longer self-describing for order). |
| **O-D — Keep `> **Execution note**:` as human rationale + a structured key elsewhere** | Prose note stays for the WHY; the machine order is O-B or O-C. | Preserves the existing human affordance; separates rationale (prose) from order (structured) — directly addresses G6. | Two things to keep consistent (note vs key); architect defines which is authoritative (the structured key MUST be). |

### §2.4 — Constraints that make any choice deterministic (architect must pin all)

- **Closed Part-identity token.** Part identity = a fixed token (`Part a`, `Part-a`,
  `a`), regex-checkable; the free-text subtitle is NEVER part of the canonical key.
  (The V2 §4.1 grammar uses `Phase-N.Part-x`, `Part-x ∈ [a-z]` — that is a tracker-form
  identifier; the flat-file canonical token must be chosen to match so BD-215 can map
  one canonical form across modes. This cross-mode identity choice is a key architect
  decision and a BD-185↔BD-215 contract point.)
- **Explicit total order with a defined tie-break.** e.g. `(order_key, phase_number,
  part_letter, task_number)` — fully specified so two serializers agree byte-for-byte.
- **One SSOT per fact.** If both a phase-file representation and `_index.md` exist,
  exactly ONE is source of truth and the other is GENERATED (fail-loud:
  hand-edits to the generated one are overwritten — the existing mirror discipline,
  `_rules.md` "regenerated mirror … hand-edits silently overwritten").
- **Grep-zero validator gate.** A validate-pack check must be able to prove no
  non-conforming pattern remains (closed grammar). This is the SC-SER ↔ BD-215
  "validator enforces the spec" bridge.
- **Round-trippability target.** The canonical form must be exactly what BD-215's
  format spec consumes; BD-216 then PROJECTS that same canonical form into the tracker
  (BD-216 SC-RT). So the flat-file canonical form BD-185 picks is the SHARED contract
  for all three (BD-185 owns it, BD-215 formats it, BD-216 projects it).

### §2.5 — Open question the architect must resolve (surfaced, not decided)

**OQ-SER-1 — Where does the canonical machine form LIVE: in the phase file (markers /
formalized heading nesting) or in `_index.md` (structured index)?** This is the central
SC-SER design fork. It is entangled with the `_index.md` build-scope question (§3.5):
if the canonical form lives in `_index.md`, BD-185 either designs-only (BD-206 builds)
or absorbs the `_index.md` build. If it lives in the phase file (M-A/M-B + O-B), BD-185
is self-contained in flat-file mode and `_index.md` becomes a regenerated VIEW. The
architect must measure the BD-185↔BD-206↔BD-215 scope seam before choosing. (See
§3.5 + §6 OQ list.)

---

## §3 — `_index.md` RECONCILIATION (renamed sidecar; broadened scope)

### §3.1 — What `_index.md` is (per the rename census + BD entries)

`_index.md` is the **renamed** (from `_order.md`, 2026-06-13) and **broadened**
predesigned sidecar. Per `RESEARCH-ORDER-MD-RENAME-CENSUS.md` §0 and `backlog/BD-206.md`:
- A sidecar alongside `_intro.md` / `_rules.md` / `_toc.md` for a per-entry stream.
- May carry ONE OR MORE indexes/graphs: ORDER and/or GROUPINGS, and OPTIONALLY a
  cross-directory dependency graph (e.g. TD entries depending on phase entries). The
  dependency graph is NOT a default — created only if needed.
- **PREDESIGNED but UNBUILT.** Zero `_order.md`/`_index.md` files exist (measured
  §1.4; census §6 measured 0 built files; census §1 measured 56 literal `_order.md`
  references across 14 docs, all textual, no built file).

### §3.2 — How flat-file ordering would live in `_index.md` vs the BD-203 as-built shape

**BD-203 as-built shape (measured).** The per-entry trees use a fixed sidecar set:
`_rules.md` (sole rules SSOT), `_intro.md` (human-only), `_toc.md` (generated index,
DO-NOT-EDIT). Confirmed in `project-template/docs/project/implementation-plan/`
(read: only `_intro.md` + `_rules.md` present today; `_toc.md` is generated at runtime;
NO `_index.md`). The per-entry **decompose** anchors each phase entry on the `## Phase N`
H2 (measured: `decompose.sh` `section_break_re = ^## `; the phase stream entry spans the
H2 block) — so **Part H3 sub-sections + task H4 sub-sections ride INSIDE the phase
entry file**, never as separate files. The filename regex is `^phase-\d+\.md$`
(stream `_rules.md` + `toc-regenerate.sh:90`) — no part-file or task-file form.

**Reconciliation findings:**
1. **`_index.md` is a NEW fourth sidecar basename.** It is NOT in any stream's
   "Supporting files" allowlist today. Census §4c measured: all five live `_rules.md`
   files (pack backlog, pack changelog, project backlog/changelog/implementation-plan)
   enumerate exactly `_rules.md` / `_intro.md` / `_toc.md`. The mirror generator reads
   that list at runtime; a file not matching the entry regex AND not in the list is
   SKIP. **So `_index.md` must be ADDED to the implementation-plan stream's
   Supporting-files list** or it is treated as an unrecognized SKIP file. This is a
   contract EXTENSION (not a rename — no `_order.md` string exists in any `_rules.md`).
2. **Whether `_index.md` is SSOT or a generated view.** The predesign chain
   (V2 §5.4, ADDENDUM A-1, BD-203-V3-AMENDMENT §F.3) is consistent: the ORDERING VALUE
   is owned by the phase ENTITY (the `phase-N.md` file), and any `_order.md`/`_index.md`
   is a "regenerated view of the SSOT, never the SSOT." If BD-185 follows that
   predesign, `_index.md` is GENERATED from per-phase markers (O-B) — it is NOT where
   order is authored. The alternative (O-C/M-C: `_index.md` IS the SSOT) CONTRADICTS
   the predesign and must be an explicit, justified architect reversal if chosen.
3. **The broadened scope (groupings + dependency graph) is largely v11.1+ / BD-206 /
   adjacent.** Groupings are BD-186/BD-189 (v11.1). The cross-directory dependency
   graph is "only if needed." For BD-185's flat-file SC-SER, the ONLY `_index.md`
   facet in play is the ORDER index (and possibly a membership index if M-C/M-D
   chosen). The architect should NOT pull groupings/dependency-graph into BD-185.

### §3.3 — Current sort behavior (the deterministic baseline already in place)

`toc-regenerate.sh` (measured) groups the implementation-plan stream by phase number
and sorts phase groups NUMERICALLY (`order_groups` → `Phase (\d+)` numeric key,
L226–230), not lexically. So the TOC is ALREADY deterministic by phase number. What is
MISSING is an execution-order that DIFFERS from phase-number order (O-B/O-C) and any
PART-level serialization. The architect builds on a numeric-sort baseline, not a
broken lexical one. (V2 §5.3's "LC_ALL=C lexical sort" concern referenced the
mirror generator, not toc-regenerate; the architect should re-verify the mirror
generator's phase sort specifically — `mirror-generate.sh` concatenation order is
"per sidecar," measured L17–20, and the exact phase sort there is the place an
execution-order key would plug in.)

### §3.4 — The predesign docs still carry the OLD `_order` name (deferred sweep)

Per the rename census, the predesign chain BD-185 reconciles against still says
`_order.md`, NOT `_index.md`: `ARCHITECTURE-BD-185-V2.md` (379, 645, 1009),
`ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md` (111), `ARCHITECTURE-BD-203-V3-AMENDMENT.md`
§F.3 (181). The rename is a documentation/text edit with NO file move and NO
code-constant flip (census §4d: zero validator/test hardcodes). **The architect must
read the predesign's `_order.md` references AS `_index.md`** (the concept is identical;
only the name + broadened scope changed). The census surfaced (did not decide) whether
the live predesign chain should be name-swept for forward-consistency — that is a
user/architect call; this pass simply flags that the predesign and the entries
currently use different names for the same concept.

### §3.5 — Open question (surfaced)

**OQ-IDX-1 — Is `_index.md` BUILT by BD-185 or only BD-206?** `backlog/BD-206.md`
(L6, L13, L16, L18) places the `_index.md` (still written `_order.md` there)
create/reconcile work in **BD-206 Track-B** (deferred). BD-185 owns the flat-file
phase-parts STRUCTURE + its serialization (SC-SER). If the canonical serialization
lives in per-phase markers (O-B/M-A/M-B), BD-185 is self-contained and `_index.md` is
a downstream generated view BD-206 builds. If the canonical serialization lives in
`_index.md` (O-C/M-C), the BD-185↔BD-206 seam must be re-cut (who builds it, in which
version). The architect must reconcile BD-185's SC-SER deliverable against BD-206's
Track-B `_index.md` directive so the two do not collide or double-own the file.

---

## §4 — MIGRATOR PASS-THROUGH + STATUS.md

### §4.1 — v10→v11 whole-number-phase pass-through (SC8 flat leg)

**Measured facts (HEAD `f858d90`):**
- `scripts/migrate-v10-to-v11.sh` itself contains NO phase-numbering / Part / renumber
  logic (grep: only BD-095 two-phase MODE dispatch + sourcing of gate scripts). The
  "phase" hits in the migrator are the migration's OWN two-phase workflow (Phase A /
  Phase B gates), NOT project phase numbers.
- The decompose that emits per-entry `phase-N.md` files is
  `scripts/lib/migrate-v10-to-v11/decompose.sh`. Measured: it streams
  `project-implementation-plan | docs/project/IMPLEMENTATION-PLAN.md |
  docs/project/implementation-plan` through the shared per-entry decompose; it contains
  NO renumber/rewrite/reorder/sed-on-phase logic (grep returned empty). It decomposes
  the monolith into per-entry files VERBATIM.
- **Conclusion: the migrator is ALREADY a clean whole-number pass-through.** Pre-existing
  whole-number phases decompose unchanged; no renumbering occurs because the decompose
  is content-faithful. SC8 (flat leg) is largely SATISFIED BY CONSTRUCTION today.

**What BD-185 ADDS to the migrator (the gap):** if BD-185 adopts an explicit
execution-order marker (O-B), the decompose step must ALSO write
`<!-- execution-order: N -->` into each emitted `phase-N.md`, value = the phase's
1-indexed position in the source `IMPLEMENTATION-PLAN.md` (= current implementation
order; = phase number for OT-style birth-order projects). This is the V2 §6.1 Phase A
design — and it is the ONLY migrator change in BD-185's flat-file scope (V2 §6.1
Phase B / §6.2 / §6.4 are tracker = BD-216). If BD-185 keeps the implicit
phase-number order (O-A), the migrator needs NO change at all and SC8 is satisfied as-is.

**Architect note (BD-119 framework).** Per CLAUDE.md, a migrator edit sources
`scripts/lib/migrator-core.sh` and uses the adapter hooks — the decompose lives in the
`migrate-v10-to-v11/` adapter, NOT in a hand-rewritten migrator. The execution-order
emit (if adopted) is a decompose-hook addition, not a new migrator.

### §4.2 — STATUS.md stays a dashboard (SC5)

**Measured:** STATUS.md is described throughout METHODOLOGY as a dashboard, never an
ordering SSOT:
- L190 (Standard Project Documents table): `STATUS.md | Current phase, phase table,
  next actions, key metrics | PM chat or developer | After every phase completion`.
- L202: "STATUS.md is updated after every phase — stale status is worse than no status."
- L1556 (Document Authoring Rules table): agents never write it; updated after phase
  completion.
- L1241 (Audit Checkpoints): "has that phase been committed and marked ✅ in STATUS.md?"

It is a DISPLAY surface (current phase, phase table, ✅/🚧 markers, metrics). The V2
§5.4 + ADDENDUM C2 design keeps it a dashboard: when regenerated it DISPLAYS phases in
execution order (sorted by the read ordering key), a display change, not an ownership
change. **SC5 is preserved by NOT moving the ordering SSOT into STATUS.md.** The
architect's only obligation is the negative one: do not promote STATUS.md to own order.
If an execution-order key (O-B/O-C) is introduced, STATUS.md's phase table MAY sort by
it for display — but the SSOT is the phase file / `_index.md`, never STATUS.md.

---

## §5 — BLAST RADIUS (every flat-file surface a phase-parts codification touches)

Categorized. IN-SCOPE = BD-185 flat-file. OUT = BD-216/BD-206/v11.1. All measured at
HEAD `f858d90`.

### §5.1 — IN-SCOPE surfaces (BD-185 flat-file)

| # | Surface | Why it is touched | Encoding class |
|---|---|---|---|
| B1 | `supporting-docs/METHODOLOGY.md` § "Multi-part phases" (under Part 4, L414–441) | Add the mid-work expansion lifecycle (G1), evolution-only + relationship semantics (G2/G3), no-renumber-across-transition invariant (G4). | Primary doc (client-installed) |
| B2 | `supporting-docs/METHODOLOGY.md` § "Phase numbering rules" (L407–412) + phase format (L368–405) + `> **Execution note**:` (L375) | Connect "never renumber" to the parts transition (G4); define the deterministic ordering relationship between execution notes (prose rationale) and the structured order key (G6). | Primary doc |
| B3 | `project-template/docs/project/implementation-plan/_rules.md` | Add the Part sub-section to the Entry contract (G7); add `_index.md` to Supporting-files IF the index is adopted (§3.2); state membership/ordering grammar pointer. | Stream contract (SSOT for the stream shape) |
| B4 | `project-template/docs/project/implementation-plan/_intro.md` | Human-orientation update for parts/ordering (human-only; no rules). | Stream meta (human-only) |
| B5 | per-phase serialization carrier — IF O-B/M-B adopted: the `phase-N.md` body (the `### Part` H3 grammar + `<!-- execution-order: N -->` and/or `<!-- part: x -->` markers) | The canonical machine form (SC-SER). | Entry body grammar |
| B6 | `scripts/validate-pack.py` | New check(s): part-membership invariant + no-renumber + deterministic-serialization grep-zero gate (closed grammar). MEASURE-THEN-BOUND required (see §5.4). Existing phase-part refs already present (`phase-part-skeleton` in `check_issue_template_forms` L1217/1252/1258 + `check_template_archive_v11` L1346/1368) — those are the tracker FORM (BD-216 territory); BD-185's flat-file check is NEW and distinct. | Validator (encoding surface) |
| B7 | `scripts/tests/` — a new per-check test for B6 | Tests pin the validator's output (banners/SKIP wording) — enumerate-encoding-surfaces requires test + validator in lock-step. | Test (encoding surface) |
| B8 | `project-template/docs/pack/PM-CHAT.md` | PM-chat orchestration text for the mid-work phase→parts expansion procedure (BD-185 File/Symbol line names it; architect determines specifics). | Project-side ops doc (client-installed) |
| B9 | `scripts/lib/migrate-v10-to-v11/decompose.sh` | ONLY if O-B adopted: emit `<!-- execution-order: N -->` per phase (Phase A; §4.1). Otherwise NO change. | Migrator adapter (pack-side) |
| B10 | `scripts/lib/per-entry/mirror-generate.sh` + `toc-regenerate.sh` | IF an execution-order key is adopted: the phase sort key changes from phase-number to `(order_key, phase_number, filename)` (V2 §5.3). toc-regenerate already sorts numerically (§3.3); mirror-generate's phase sort is the precise plug point. | Per-entry tooling (pack-side) |
| B11 | `test-fixtures/manifest.txt` + the three fixtures (`v11-flat-file`, `v11-realistic-ot`, `v11-tracker-on`) | Any commit touching `project-template/`/`scripts/`/`supporting-docs/` regenerates the manifest (pack rule); fixtures that should carry parts/`_index.md` need the addition (census §4c noted 9 fixture `_rules.md` copies). | Fixtures (test infra) |
| B12 | `project-template/STATUS.md` | CONFIRM-ONLY: role does NOT change (SC5). Possibly the phase table sorts-for-display by order key — display only. | Client deliverable (confirm, not expand) |

### §5.2 — OUT-OF-SCOPE surfaces (do NOT touch in BD-185)

| Surface | Why out | Owner |
|---|---|---|
| `project-template/.github/ISSUE_TEMPLATE/work-item.yml` Part field + `part:M` label | Tracker form-family | BD-216 |
| `scripts/lib/tracker-provider*.sh`, `tracker-phase-part.sh`, ordering ops, resolver | Tracker projection + sync + ordering mechanism | BD-216 |
| `scripts/lib/tracker-init.sh` `[execution_order]` section, doctor | Tracker-mode ordering policy gate | BD-216 |
| V2 §5.1/§5.2 + the entire ORDERING-ADDENDUM (Issue Fields / sub-issue reprioritize / capability-availability selection) | Tracker ordering mechanism | BD-216 |
| `maintenance-docs/v11-research/templates-archive/...` phase-part SCHEMA / INDEX / form snapshot | Tracker GRAMMAR archive (V2 §10 corrections) | BD-216 (the archived grammar feeds the tracker form) |
| `_index.md` BUILD + generator (`_index-generate.sh`) | Project-side conversion | BD-206 Track-B (see OQ-IDX-1) |
| Groupings index facet of `_index.md`; cross-directory dependency graph | v11.1 / only-if-needed | BD-186/BD-189; BD-206 |

### §5.3 — Boundary notes (pack/project)

- METHODOLOGY (B1/B2), `_rules.md`/`_intro.md` (B3/B4), PM-CHAT.md (B8), STATUS.md (B12)
  are CLIENT-INSTALLED project-side surfaces (`docs/pack/`, `docs/project/`). Per
  P-missed-7 + V2 §8.2, the architect EXTENDS the existing project-side SSOT
  (METHODOLOGY "Multi-part phases"), NEVER imports a pack-style mechanism. No BD refs
  operationally; no pack-ops refs (token economy).
- `validate-pack.py` / migrator / per-entry tooling (B6/B7/B9/B10) are pack-side scripts
  that CONSTRUCT/CHECK the project-side deliverable — deliverable-only rule PASS
  (V2 §8.4 reasoning), provided they carry no pack-self-management semantics.

### §5.4 — CI-guard discipline reminder for the architect (measure-then-bound)

The new validate-pack check(s) (B6) MUST follow measure-then-bound: run the matching
logic against the actual current fixtures/templates first; categorize every occurrence
KEEP/STRIP; size any allowlist to the legitimate set; verify clean post-design. Also
the CI-runtime-compounding caution: scope the check to the caller's target tree
(no whole-real-tree scan, no subprocess-per-entry storm) — validate-pack is invoked
~155× per test battery.

### §5.5 — Blast-radius count reconciliation

IN-SCOPE surfaces: **12** (B1–B12), of which B5/B9/B10/B11 are CONDITIONAL on the O-B
explicit-marker choice and B12 is confirm-only. OUT-OF-SCOPE surface classes: **7**
(tracker form, tracker provider/ordering, tracker init/doctor, ORDERING-ADDENDUM
mechanism, templates-archive grammar, `_index.md` build, groupings/dep-graph). Two
independent reconciliations agree: (a) by file/group enumeration above = 12 in + 7 out;
(b) by BD-185 File/Symbol line (flat-file half), which names exactly METHODOLOGY ×2,
migrate-v10-to-v11.sh, validate-pack.py, PM-CHAT.md, STATUS.md (6 named) — and this
pass EXPANDS to the encoding surfaces those imply (stream `_rules.md`/`_intro.md`,
tests, per-entry tooling, fixtures/manifest, the per-phase carrier) per
enumerate-encoding-surfaces = 12. The +6 are the encoding surfaces the BD line's 6
named surfaces require in lock-step.

---

## §6 — OPEN QUESTIONS (surfaced for the architect; not decided)

1. **OQ-SER-1 (central fork).** Canonical machine form in the PHASE FILE (markers /
   formalized heading nesting: M-A/M-B + O-B) vs in `_index.md` (structured index:
   M-C/O-C). The predesign chain leans phase-file-SSOT + `_index.md`-as-view; choosing
   `_index.md`-as-SSOT contradicts the predesign and needs explicit justification (§2.5).
2. **OQ-IDX-1.** Does BD-185 BUILD `_index.md` or only DESIGN the order/membership
   grammar it will carry (BD-206 Track-B builds)? Re-cut the BD-185↔BD-206 seam so the
   file is single-owned (§3.5).
3. **OQ-ID-1 (cross-mode identity).** What is the flat-file canonical Part-identity
   token, and does it MATCH the tracker `Phase-N.Part-x` form (V2 §4.1) so BD-215 maps
   one canonical identity across modes? This is a BD-185↔BD-215↔BD-216 contract point.
4. **OQ-ORD-1.** Adopt the explicit `<!-- execution-order: N -->` marker (O-B — adds
   surface, enables differ-from-phase-number ordering + sparse insert) vs keep implicit
   phase-number order (O-A — zero new surface, cannot reorder without notes)? SC4 (flat
   leg) requires ordering be "expressible" AND "deterministically serializable" — O-A's
   prose escape hatch (`> **Execution note**:`) is NOT deterministic, so SC4+SC-SER
   together likely force O-B (or O-C), but the architect confirms.
5. **OQ-SUB-1.** Is PART order itself significant/serialized, or only phase order?
   (Parts are sequential chunks; their `### Part a/b/c` letter order may suffice as the
   part-order key, or an explicit part-order field may be needed.)
6. **OQ-PREDESIGN-1.** Should the live predesign chain (V2/ADDENDUM/V3-AMENDMENT) be
   name-swept `_order.md`→`_index.md` for forward-consistency with the entries, or left
   as as-was history? (Census §4b surfaced this; it is a user/architect call. The
   architect at minimum reads the predesign's `_order.md` as `_index.md`.)
7. **OQ-SPLIT-AT-CREATION-1 (SC1).** SC1 (split-at-creation = two phases) is currently
   only an unstated semantic (V2 §2.A FIXED input, not in METHODOLOGY). Confirm the
   architect codifies "oversize-at-birth → two phases (new immutable numbers), never a
   born-split phase" in METHODOLOGY (G2) — it is in BD-185 scope but absent from the
   doc today.

---

## §7 — Rules-Applied Verification Block

| # | Rule (as named in the prompt) | Verification evidence (quoted / measured) | Conclusion |
|---|---|---|---|
| 1 | Agents never commit (git read-only) | Only read-only git run: `git rev-parse HEAD` → `f858d90ec0bd12492944aba457bebb0b91285081`; `git branch --show-current` → `v11-dev`. No `git add/commit/push/tag`. | COMPLIANT |
| 2 | Read-only mandate (Write ONLY this one report) | Sole filesystem write is this report at `maintenance-docs/v11-implementation/RESEARCH-BD-185-FLAT-FILE-PHASE-PARTS.md` (non-existent before this run). All other tools `Read`/`grep`/`find`/`ls`/`cat`-to-read. No source, no entry, no other file edited. | COMPLIANT |
| 3 | Researcher does not design (options + facts + trade-offs; flag OQs; do not prescribe final shape) | §2.2/§2.3 present 4 membership + 4 ordering CANDIDATES with pros/cons, none selected ("No shape is selected here," §2 intro). §6 lists 7 OPEN QUESTIONS surfaced, not resolved. SC-SER fork left to architect (OQ-SER-1). | COMPLIANT |
| 4 | Empirical-Evidence blocks (command + verbatim output + HEAD/date + conclusion) per state-claim | §1.4 (`find … -name '_order*'/'_index*'` → EMPTY; `grep execution-order` → none; HEAD `f858d90`, 2026-06-13). §3.2/§3.3 (toc-regenerate numeric sort L226–230; decompose `section_break_re=^## `; impl-plan regex `^phase-\d+\.md$`). §4.1 (migrator grep: no renumber/rewrite/reorder in decompose — empty). §4.2 (STATUS.md L190/L202/L1556/L1241 quoted). §5.5 count reconciled 2 ways. All measured at HEAD `f858d90`. | COMPLIANT |
| 5 | Exhaustive blast-radius, counts reconciled | §5 enumerates 12 in-scope (B1–B12) + 7 out-of-scope surface classes; §5.5 reconciles 2 independent ways (file/group enumeration = 12+7; BD-185 File/Symbol line's 6 named surfaces + 6 implied encoding surfaces = 12) and they agree. | COMPLIANT |
| 6 | Rules-Applied Verification Block (per rule, evidence + COMPLIANT/N/A/VIOLATED) | This table; every row carries measured/quoted evidence (none empty) + a terminal conclusion (no AMBIGUOUS). | COMPLIANT |
| 7 | PREFLIGHT + STOP-MEANS-STOP | Emitted `PREFLIGHT: BD-185 flat-file phase-parts research complete; about to Write …` in the turn immediately before this Write. No parent stop/halt message received. | COMPLIANT |

### Read-in-full proof (mandatory reads)

| Document | Read directly? | Proof |
|---|---|---|
| `CLAUDE.md` (entire incl. ## Pack memory) | YES | L1 "# CLAUDE.md — AI Agent Config Pack" → L583 "OT itself is read-only…". |
| `backlog/BD-185.md` | YES | 52 lines; L2 "BD-185 — Phase-parts hierarchy + flat-file execution ordering" → L52 "Resolved: n/a". RE-SCOPE 2026-06-13 + SC-SER captured. |
| `backlog/BD-215.md` | YES | 16 lines; "Tracker-agnostic canonical entry format" → "Blocked on BD-185". |
| `backlog/BD-216.md` | YES | 25 lines; "Phase-parts tracker representation … (tracker legs of BD-185)" → Position line. |
| `supporting-docs/METHODOLOGY.md` Part 4 Phase Structure + Multi-part phases + execution-notes | YES | Read L366–455; "Multi-part phases" L414–441 quoted; phase numbering L407–412 + execution note L375 quoted. STATUS.md lines grepped + read (L190/202/1241/1556). |
| `maintenance-docs/v11-research/BD-185-DOCS-RESEARCHER-QUEUED-PROMPT.md` | YES | 88 lines; QUEUED charter; predates 2026-06-13 (P1–P4 unsplit, cites `pack-ops/BACKLOG.md` which BD-203 deleted) — EXPANDED here for SC-SER + `_index.md`. |
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-V2.md` | YES | 1071 lines, read in 2 pages (1–856, 857–1071); L1 title → L1071 manifest note. |
| `…/ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md` | YES | 740 lines; §0 supersession → §11 OQ-A1. (Tracker = BD-216, flagged out of scope.) |
| `…/ARCHITECTURE-BD-203-V3-AMENDMENT.md` | YES | 245 lines; A1 pre-normalize → end; §F.3 `_order.md` governance anchor noted. |
| `…/RESEARCH-ORDER-MD-RENAME-CENSUS.md` | YES | 318 lines; §0 framing → §8 RAB; 56 refs / 14 files / 0 built confirmed; still old `_order` name flagged. |

**No named document was derived rather than read.** Every mandatory input was Read
directly; every count (0 built sidecars; toc numeric sort; impl-plan regex; migrator
no-renumber; 12 in / 7 out surfaces) was independently measured this pass at HEAD
`f858d90`.

**End of RESEARCH-BD-185-FLAT-FILE-PHASE-PARTS.md**
