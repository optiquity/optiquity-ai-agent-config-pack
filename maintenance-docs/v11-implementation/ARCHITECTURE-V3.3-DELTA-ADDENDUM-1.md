---
title: ARCHITECTURE-V3.3-DELTA-ADDENDUM-1
status: design — for V3.x corpus integration
parent: ARCHITECTURE-V3.3-DELTA.md
authoritative-design: V3.3-DELTA + this addendum
forerunners: IMPLEMENTATION-PLAN-ADDENDUM-4 §6.R (maintainer-resolved); ARCHITECTURE-REVIEW-PASS3 §4.6 (review-accepted)
date: 2026-05-14
author: pack-architect (BD-106 ratification pass)
scope: formalises V3.3-DELTA §6.R (sidecar `dependency_edges` per-task entry shape) so the schema is reachable from the live design without traversing IMPLEMENTATION-PLAN-ADDENDUM-4's MAINTAINER CHECK list.
---

# ARCHITECTURE-V3.3-DELTA-ADDENDUM-1 — sidecar `dependency_edges` per-task entry shape (the §6.R formalisation)

## §A.0 Why this addendum exists

ARCHITECTURE-V3.3-DELTA.md ships with §6.1 through §6.5. The BD-106
spec (BACKLOG.md line 889) and the BD-106 implementation report cite
"V3.3 §6.R" for the per-task `dependency_edges` shape. **§6.R does
not exist as a section heading in V3.3-DELTA.md.** It exists as
MAINTAINER CHECK §6.R in `IMPLEMENTATION-PLAN-ADDENDUM-4.md`
line 843, with a maintainer-recommended resolution (option (a)) and
PASS3 review-accepted status (`ARCHITECTURE-REVIEW-PASS3.md`
lines 20, 257).

The schema lives in three places today:

- V3.3 §4.3 line 201 — *"Per phase task: `dependency_edges:
  [{kind, target_pack_id}]` capturing the resolved tracker links so
  reverse → re-forward replays them deterministically."*
- V3.3 §5.3 lines 269-276 — codifies the flat-file `Dependencies`
  bullet grammar; admits `phase-N`, `phase-N.M`, `TD-NNN`, `BD-NNN`;
  states *"Prose annotations after the entry are permitted as
  free-text (e.g., `- phase-3.1 (must complete schema before this
  task)`); the parser captures only the matched ID prefix."*
- IMPLEMENTATION-PLAN-ADDENDUM-4 §6.R + §7.4 line 897 — *"Round-trip
  preserves the annotation text byte-for-byte (carried via the
  sidecar's `dependency_edges` field's optional `annotation`
  sub-field per MAINTAINER CHECK §6.R)."*

A future maintainer reading V3.3-DELTA.md alone — without the
IMPLEMENTATION-PLAN-ADDENDUM-4 cross-reference — would conclude the
sidecar entry has only two fields and that V3.3 §5.3's "parser
captures only the matched ID prefix" is the whole truth. Both
inferences would be wrong. Round-trip byte-identity on the
flat-file side requires the annotation prose to be preserved
somewhere; the sidecar `dependency_edges[]` entry is the only place
the maintainer-resolved design puts it.

This addendum formalises the resolution as a fully-authored §6.R
section that V3.3-DELTA can absorb (or, alternately, be linked to
from V3.3-DELTA's §6 ToC). After this addendum lands, future
maintainers see the schema directly.

This addendum does not introduce a new design decision. It writes
down a decision that has been made (maintainer-resolved + review-
accepted) but never authored into the V3.x corpus prose.

---

## §A.1 The schema — V3.3 §6.R (formalised)

### §6.R Sidecar `dependency_edges` per-task entry shape

The sidecar `phase_tasks` block (V3.2 §4.3 carried forward through
V3.3 §4.3) gains a `dependency_edges` per-task field. Each entry
in that list captures one cross-entity dependency the phase task
declares in its `Dependencies` bullet (V3.3 §5.3) plus the prose
annotation that accompanies it.

**Per-entry shape (canonical):**

```yaml
dependency_edges:
  - kind: blocked-by
    target: <pack-id>
    annotation: <free-text or empty string>
```

Field semantics:

| Field | Type | Required | Domain |
|---|---|---|---|
| `kind` | string | yes | one of V1 §5.3 reserved `link.kind` values; v11.0 admits `blocked-by` only for phase-task `Dependencies` bullet (V3.3 §5.2 canonical direction); the open-string contract permits backend-specific values via `provider.capabilities()` for future extensions |
| `target` | string (pack-id) | yes | the upstream entity that blocks this task; one of `phase-N`, `phase-N.M`, `TD-NNN`, `BD-NNN` per V3.3 §5.3 grammar |
| `annotation` | string | yes (may be empty) | the trailing free-text prose that accompanies the matched ID in the source `Dependencies` bullet; preserved verbatim for byte-identical reverse-emit; empty string when no annotation was present |

The list is ordered. Order matches the source `Dependencies`
bullet order so reverse emit reconstructs the bullet in the
authored sequence.

### §6.R.1 Field name resolution: `target` vs `target_pack_id`

V3.3 §4.3 line 201 named the field `target_pack_id`. This addendum
adopts the shorter `target` for these reasons:

- **Provider parity.** V1 §2.1 names `link(id, other_id, kind)`'s
  second argument `other_id` and the canonical `Issue.links` shape
  (V1 §2.2 line 238) names the field `target`. The sidecar uses the
  same field name as the canonical Issue shape; the chat reads the
  same mental model whether walking sidecar entries or canonical
  Issue links.
- **Length.** `target` is shorter; the YAML emit is more compact
  without losing meaning.
- **Domain marker is in the value, not the name.** The value is
  always a pack-id by §6.R contract; the field name's `_pack_id`
  suffix is redundant.

V3.3 §4.3 line 201's `target_pack_id` text becomes `target` per this
addendum. The change is mechanical (rename of field name in one
prose line of V3.3-DELTA — see §A.5). No schema semantics change.

### §6.R.2 Annotation field — always present, always serialised

The `annotation` sub-field is always emitted, even when empty. The
empty case serialises as `annotation: ""` (YAML empty string).

Rationale:

- **Deterministic emit.** Conditional field presence (omit when
  empty) introduces a parser branch (does this entry have an
  `annotation` key?) and an emitter branch (do I emit the key?).
  Always-present is one path; the cost is two extra characters per
  edge with no annotation.
- **Schema stability.** Future migrators that introspect sidecar
  shape via JSON-schema-like tools see one consistent entry shape,
  not two.
- **Round-trip stability.** YAML emitters that round-trip through
  parse-emit cycles are sensitive to optional-key drift. Always-
  present eliminates the drift risk.
- **Diff clarity.** `git diff` on sidecars shows annotation
  additions / removals on a stable line position rather than as
  schema reshapes.

### §6.R.3 Annotation grammar — what counts as annotation

Per V3.3 §5.3 line 276 (corrected by this addendum — see §A.5):
the parser regex matches the `Dependencies` bullet entry as

```
^\s*-\s+(phase-\d+(\.\d+)?|TD-\d+|BD-\d+)(\s+(.*))?$
```

Group 1 captures the pack-id (the `target` field). The optional
group 4 captures the trailing prose (the `annotation` field).
Whitespace between the pack-id and the annotation is consumed by
group 3 (one or more spaces); the annotation itself is the
remainder of the line, trimmed of leading and trailing whitespace.

Annotation content rules:

- **Single-line only.** The grammar is line-based. Multi-line
  annotations are not representable in v10 grammar (the bullet
  syntax does not nest a paragraph under one entry). If a future
  v11.x extends the grammar, it ships as a separate addendum.
- **Any UTF-8 text permitted.** No reserved characters. The YAML
  emitter quotes when the annotation contains characters that
  would change YAML semantics (`:`, `#`, `"`, `'`, leading/trailing
  whitespace, embedded newlines from upstream tooling). Round-trip
  through `parse → emit → re-parse` returns the same string
  byte-for-byte.
- **Emit reconstruction.** The reverse-emit reproduces the source
  line as `  - <target> <annotation>` when annotation is non-empty,
  or `  - <target>` when empty. The two-space indent matches
  V3.3 §5.3's nested-bullet shape.

---

## §A.2 Why this schema (not the alternatives)

The §6.R MAINTAINER CHECK in IMPLEMENTATION-PLAN-ADDENDUM-4 §6.R
considered two options:

- (a) Add `annotation` sub-field to `dependency_edges` per-task
  entry. Maintainer-recommended.
- (b) Drop annotation on round-trip; document the loss in
  MIGRATION-v10-to-v11.md as advisory-prose acceptable trade-off.

The maintainer chose (a). This addendum ratifies (a) and rules out
two further alternatives that the MAINTAINER CHECK did not
enumerate but that the BD-106 architect-pass prompt called out:

- **(c) Parallel structure: `dependency_edges: [{kind, target}]`
  plus `dependency_annotations: [{target, annotation}]`.** Splits
  the canonical link representation from the prose preservation.
  Rejected: introduces two lists per task whose entries must be
  index-aligned; the cross-list invariant (every dependency_edge
  has at most one matching annotation entry) becomes an emitter
  invariant the parser must enforce; YAML readers see the
  relationship as accidental rather than intrinsic. The annotation
  belongs to the edge; the schema should reflect that.
- **(d) Per-task `body_carryover` field that preserves the entire
  source `Dependencies` bullet block verbatim.** Annotations
  preserved at the carryover level; sidecar `dependency_edges`
  stays the V3.3 §4.3 two-field shape. Rejected: the sidecar then
  carries two representations of the same data (the structured
  edges plus the verbatim block); divergence between them on
  edits introduces a "which is authoritative?" question that
  V1 §6.0 + V1 §6.6.1 already resolve in favour of the structured
  representation. The carryover field would be a second source of
  truth — exactly the anti-pattern V1 §6.3 (read-only mirror
  contract) exists to prevent.

The selected schema (annotation as a sub-field of the edge entry)
is intrinsic, indexed naturally with the edge, and preserves
single-source-of-truth.

---

## §A.3 Composition with V1 / V3 / V3.3 invariants

### §A.3.1 Bidirectionality contract (V1 §6.0)

The contract requires content-equivalence for v10 grammar. The
phase-task `Dependencies` bullet's free-text annotation is part of
the v10 grammar by V3.3 §5.3 line 276 (the bullet always permitted
trailing prose; v11 codifies what was already legal). The §6.R
schema preserves the annotation bidirectionally. Verdict: the
contract is honored.

The reverse direction's "byte-identical on the tracker side;
whitespace-tolerant on the flat-file side" guarantee (V1 §6.7) is
preserved: the tracker side sees the annotation only via the
sidecar (`provider.link()` does not carry annotation); the flat-
file side sees the annotation in the `Dependencies` bullet and the
sidecar `dependency_edges[].annotation` field — both kept in sync
by the parser/emitter pair.

### §A.3.2 Sidecar-only enrichment (V1 §6.6, §6.6.1)

The sidecar captures tracker-only-or-grammar-edge-case data
(reactions, comments, attachment URLs, audit log, template_version,
extra_fields; per V3.3 §4.3, also phase_tasks block). The
annotation is grammar-edge-case data (it is part of v10 grammar but
the tracker-side `provider.link()` operation has no `annotation`
argument). Routing the annotation to the sidecar is consistent with
V1 §6.6's "what the v10 grammar can't represent at the tracker
layer goes to the sidecar" pattern.

The `template_version: phase-task-v11.0` field on the per-task
sidecar block is the carrier per V1 §6.6.1 / D-18; the
`extra_fields: {}` placeholder is V1 §6.6.1 / A2's forward-
compatibility hook. Both compose with the §6.R `annotation`
addition unchanged.

### §A.3.3 Provider abstraction (V1 §2.1, V1 §5.3)

`provider.link(id, other_id, kind)` is unchanged — `annotation` is
not an argument. The v11.0 GH backend, future Linear backend,
future Jira backend all see the same three-arg signature. The
annotation is a flat-file-side concern realised in the sidecar; it
never reaches the provider.

The `kind = "blocked-by"` value is V1 §5.3 reserved (the open-
string family). v11.0 phase-task `Dependencies` bullets emit only
`blocked-by` (V3.3 §5.2 canonical direction). The §6.R schema
reserves `kind` as a field but does not mandate `blocked-by` only;
future v11.x extensions (e.g., `relates-to` annotations on a
phase task pair) compose without schema reshape.

### §A.3.4 V3.3 §5.3 grammar — corrected by §A.5 below

V3.3 §5.3 line 276's claim "the parser captures only the matched
ID prefix" was authored before the §6.R resolution. The §6.R
resolution requires the parser to additionally capture the trailing
annotation. The corrected text is in §A.5; the schema in §6.R is
the authoritative grammar.

### §A.3.5 Round-trip safety (V1 §6.7)

The §6.R schema makes round-trip identity on the `### Tasks`
block slice provable via SHA-256 over `parse → emit → re-parse`
cycles. This is stronger than V1 §6.7's "whitespace-tolerant zero
diff" — the schema enables byte-identical on the slice.

The whole-file (e.g., IMPLEMENTATION-PLAN.md with phase-epic body
content surrounding the `### Tasks` slice) remains whitespace-
tolerant per V1 §6.7. The slice-vs-whole distinction is intrinsic:
phase-epic body content (Goal / Prerequisite / `### Verification` /
`### Agent` / `### Risks`) is owned by the existing phase-epic
parser/emitter; phase-task `### Tasks` block content is owned by
the new BD-106 parser/emitter. Each owns its slice and preserves
byte-identity within it.

### §A.3.6 3-level cap and entity placement (V3.3 §2)

The schema is internal to the L2 phase-task entity's sidecar
representation; the L1 ↔ L2 hierarchy is unaffected. L3 reservation
is unaffected. The schema composes with `phase_tasks: phase-N:
tasks: phase-N.M:` (the V3.2 §4.3 hierarchy carried forward
through V3.3 §4.3) without introducing a new level.

### §A.3.7 Trinity rule

The schema is internal to scripts/lib/ + sidecar runtime data; the
trinity files (CLAUDE.md / AGENTS.md / GEMINI.md at pack root and
project-template) are NOT touched. Trinity rule does not engage.


---

## §A.4 Worked example — full sidecar block under §6.R

The IMPLEMENTATION-PLAN.md fixture under
`scripts/tests/fixtures/tracker-phase-task/IMPLEMENTATION-PLAN.md`
covers the cases V3.3 §4.4 enumerates. Composing with §6.R, the
sidecar `phase_tasks` block emits as:

```yaml
phase_tasks:
  phase-3:
    task_order: [3.1, 3.2, 3.3]
    tasks:
      phase-3.1:
        title: Schema bootstrap
        parent_phase: phase-3
        dependency_edges:
          - kind: blocked-by
            target: phase-2.4
            annotation: "(must complete migration scaffold first)"
          - kind: blocked-by
            target: TD-029
            annotation: ""
        template_version: phase-task-v11.0
        extra_fields: {}
      phase-3.2:
        title: Reverse emitter
        parent_phase: phase-3
        dependency_edges:
          - kind: blocked-by
            target: phase-3.1
            annotation: ""
        template_version: phase-task-v11.0
        extra_fields: {}
      phase-3.3:
        title: Cross-phase wiring
        parent_phase: phase-3
        dependency_edges:
          - kind: blocked-by
            target: phase-7.4
            annotation: ""
          - kind: blocked-by
            target: BD-108
            annotation: ""
        template_version: phase-task-v11.0
        extra_fields: {}
  phase-4:
    task_order: []
    tasks: {}
  phase-7:
    task_order: [7.1]
    tasks:
      phase-7.1:
        title: Consume phase-3 outputs
        parent_phase: phase-7
        dependency_edges:
          - kind: blocked-by
            target: phase-3.4
            annotation: ""
        template_version: phase-task-v11.0
        extra_fields: {}
```

Reverse-emit reproduces the source IMPLEMENTATION-PLAN.md
`### Tasks` slice with byte-identical content (the round-trip
fixture under `scripts/tests/fixtures/tracker-phase-task/
ROUNDTRIP.md` exercises this directly; SHA-256 identity proven in
BD-106 IMPLEMENTATION-REPORT §6.4).

The sidecar's annotation field with quoted value `"(must complete
migration scaffold first)"` round-trips to the bullet line `  -
phase-2.4 (must complete migration scaffold first)` exactly. The
empty-annotation cases round-trip to `  - <target>` with no
trailing prose.

---

## §A.5 Edits required to V3.x corpus

V3.x corpus is PM-only (per architect-pass scope constraints). The
edits below are specifications for Pack Chat to apply with user
approval. The architect does not edit V3.x prose directly.

### §A.5.1 V3.3-DELTA.md §4.3 — replace the per-task line

**Current text (V3.3-DELTA.md line 201):**

> - Per phase task: `dependency_edges: [{kind, target_pack_id}]`
>   capturing the resolved tracker links so reverse → re-forward
>   replays them deterministically. The flat-file `Dependencies`
>   bullet is the human-readable face; the sidecar field is the
>   queryable face.

**Replacement text (V3.3 §6.R-aligned):**

> - Per phase task: `dependency_edges: [{kind, target,
>   annotation}]` capturing the resolved tracker links plus the
>   trailing free-text prose from the source `Dependencies` bullet
>   (per §6.R below) so reverse → re-forward replays them
>   deterministically. The flat-file `Dependencies` bullet is the
>   human-readable face; the sidecar field is the queryable face.
>   The `annotation` sub-field is always emitted (empty string when
>   no annotation was present in the source bullet); see §6.R.2 for
>   rationale.

### §A.5.2 V3.3-DELTA.md §5.3 — correct the "captures only the matched ID prefix" claim

**Current text (V3.3-DELTA.md line 276):**

> The bullet's content shape is one entry per nested bullet; the
> parser regex matches `^\s*-\s+(phase-\d+(\.\d+)?|TD-\d+|BD-\d+)\s*$`.
> Prose annotations after the entry are permitted as free-text
> (e.g., `- phase-3.1 (must complete schema before this task)`);
> the parser captures only the matched ID prefix.

**Replacement text (§6.R-aligned):**

> The bullet's content shape is one entry per nested bullet; the
> parser regex matches
> `^\s*-\s+(phase-\d+(\.\d+)?|TD-\d+|BD-\d+)(\s+(.*))?$`.
> Prose annotations after the entry are permitted as free-text
> (e.g., `- phase-3.1 (must complete schema before this task)`);
> the parser captures the matched ID prefix as the link target and
> the trailing prose as the annotation. Both are stored in the
> sidecar's `dependency_edges` per-task entry per §6.R; reverse
> emit reproduces the bullet line byte-identically.

### §A.5.3 V3.3-DELTA.md §6 — add §6.R subsection

**Insertion location:** after §6.5 (line ~382), before the existing
§7 heading at line 386.

**New section text:** the body of §A.1 of this addendum (the four
parts: schema, §6.R.1 field name resolution, §6.R.2 annotation
field always present, §6.R.3 annotation grammar). Pack Chat may
inline the body verbatim from §A.1, or insert a short stub that
references this addendum:

> ### §6.R Sidecar `dependency_edges` per-task entry shape
>
> See `maintenance-docs/v11-implementation/
> ARCHITECTURE-V3.3-DELTA-ADDENDUM-1.md` §A.1 for the full
> schema + rationale. Summary: each per-task `dependency_edges`
> entry has three fields — `kind` (V1 §5.3 reserved value;
> v11.0 emits `blocked-by`), `target` (the upstream pack-id;
> one of `phase-N`, `phase-N.M`, `TD-NNN`, `BD-NNN`), and
> `annotation` (free-text from the source `Dependencies` bullet;
> empty string when absent). The annotation is always emitted —
> empty cases serialise as `annotation: ""`. Round-trip identity
> (parse → emit → diff = empty) is provable via SHA-256 on the
> `### Tasks` block slice.

Recommendation: inline the §A.1 body verbatim into V3.3-DELTA's
§6.R rather than the stub. Inlining keeps V3.3-DELTA self-contained;
the stub creates a forward reference to the addendum and a hop
the reader must follow. Inlining is consistent with how V3.3-DELTA
treats every other §6.X subsection. The addendum becomes
historical-record-only after inlining (the addendum file remains
in maintenance-docs/v11-implementation/ for the BD-106 audit
trail; V3.3-DELTA is the live spec).

### §A.5.4 IMPLEMENTATION-PLAN-ADDENDUM-4 §6.R — update status to RESOLVED-RATIFIED

**Current text (Addendum 4 line 843-846):**

> - **§6.R — Sidecar `dependency_edges` annotation preservation.**
>   V3.3 §4.3 specifies the sidecar `dependency_edges` per-task
>   entries as `[{kind, target_pack_id}]` only. V3.3 §5.3 permits
>   free-text annotations after the matched ID in the
>   `Dependencies` bullet grammar. If the annotation is dropped on
>   round-trip, the flat-file `Dependencies` bullet's annotation
>   text is lost on reverse. Options:
>   - (a) **Add `annotation` sub-field to `dependency_edges`
>     per-task entry (proposed).** Preserves free-text round-trip;
>     sidecar grows by one optional field per dependency.
>   - (b) Drop annotation on round-trip. Document the loss in
>     MIGRATION doc as an acceptable trade-off (annotations are
>     advisory prose, not load-bearing).
>   - **Recommendation: (a).** Maintainer confirms at BD-106 land-time.

**Replacement text (status flip):**

> - **§6.R — Sidecar `dependency_edges` annotation preservation.
>   RESOLVED-RATIFIED 2026-05-14 per V3.3-DELTA-ADDENDUM-1 §A.1
>   (or V3.3-DELTA §6.R after inline integration).** Maintainer
>   chose option (a) at BD-106 land-time; architect ratified the
>   schema as
>   `dependency_edges: [{kind, target, annotation}]` with the
>   field-name + always-emitted-annotation refinements per §6.R.1
>   and §6.R.2. The sidecar `phase_tasks` block emits all three
>   fields per dependency entry; reverse emit reproduces the source
>   bullet byte-identically. The §6.R MAINTAINER CHECK is now
>   permanently resolved; no further re-evaluation at later BD
>   land-times.

This update flips §6.R from "deferred to BD-106 land-time" to
"resolved." The summary table at line 367 of PASS3 (which lists
§6.R as the last entry under "deferred (correctly per land-time)"
implicitly — actually the table shows §6.Q resolved and §6.R
absent; check the row presence) should gain the §6.R row showing
resolved. PASS3 is a review document and is also PM-only; Pack
Chat applies the table edit.

---

## §A.6 The coder's BD-106 working tree — MATCH / DIVERGE table

The coder synthesised an interpretation under the §6.R-citation
gap and implemented BD-106 against that synthesis. Comparing the
coder's realised schema (from `scripts/lib/tracker-phase-task.sh`
+ `scripts/lib/tracker-sidecar.sh` extension + IMPLEMENTATION-
REPORT-BD-106 §3 sample) against the architect's independent §6.R
recommendation:

| # | Design decision | Architect recommendation (§6.R) | Coder realisation | Verdict |
|---|---|---|---|---|
| 1 | Per-entry shape | `{kind, target, annotation}` | `{kind, target, annotation}` | **MATCH** |
| 2 | Field name for the upstream identifier | `target` (per V1 §2.2 canonical Issue.links field name; §6.R.1) | `target` | **MATCH** |
| 3 | Annotation field presence | always emitted; empty cases serialise as `annotation: ""` (§6.R.2) | always emitted; empty cases emit as `annotation: ""` (per `tracker_sidecar_compose_phase_tasks_block` lines 365-371; per `tracker_phase_task_parse` flush-task path setting `annotation: ''` when no trailing text) | **MATCH** |
| 4 | Annotation grammar regex | `^\s*-\s+(phase-\d+(\.\d+)?|TD-\d+|BD-\d+)(\s+(.*))?$` (§6.R.3) | identical regex in `tracker_phase_task_dependency_re` (line 112) and in the parser's DEP_ENTRY (line 184-186) | **MATCH** |
| 5 | Annotation trim semantics | trimmed of leading and trailing whitespace; preserved verbatim otherwise (§6.R.3) | trimmed via `.strip()` in `flush_task` (line 236) | **MATCH** |
| 6 | YAML quoting strategy | quote when content contains semantic-changing characters; otherwise plain (§A.4 worked example shows quoted parens-form) | `yaml_quote()` helper checks for `:`, `#`, `"`, `'`, `\n`, `\t`, leading/trailing whitespace, and empty string; quotes when any present | **MATCH** |
| 7 | `kind` field value for `Dependencies` bullet entries | `blocked-by` (V3.3 §5.2 canonical direction) | hardcoded `blocked-by` in flush_task line 238 | **MATCH** |
| 8 | Edge ordering in sidecar list | matches source bullet order so reverse emit reconstructs the bullet sequence | parser appends in source order; emitter walks in list order; verified by Test 4.2 ("kind: blocked-by emitted") + 3.1 (round-trip identity) | **MATCH** |
| 9 | Per-task `parent_phase` field | implied by V3.3 §4.3 hierarchy (per V3.3 §4.3 the `phase_tasks: phase-N: tasks: phase-N.M:` structure carries the parent through nesting) — explicit `parent_phase: phase-N` on each task is acceptable redundancy that aids queryability | explicit `parent_phase: phase-N` on each task | **MATCH** (acceptable redundancy; aids direct task-key lookup) |
| 10 | Per-task `title` field | required for round-trip (the title is part of the source `#### N.M — <title>` heading; without it, reverse emit cannot reconstruct the heading) | explicit `title:` on each task | **MATCH** |
| 11 | Per-task `template_version` | per V3.2 §4.3 + V3.3 §4.3 carry-forward; `phase-task-v11.0` per D-18 / V3.3 §6.5 | `template_version: phase-task-v11.0` | **MATCH** |
| 12 | Per-task `extra_fields` | per V1 §6.6.1 / A2 forward-compatibility hook; `{}` placeholder at v11.0 | `extra_fields: {}` | **MATCH** |
| 13 | Sparse phase representation | `task_order: []` + `tasks: {}` | `task_order: []` + `tasks: {}` (line 351-353) | **MATCH** |
| 14 | Round-trip identity proof | byte-identical on `### Tasks` block slice via SHA-256; whitespace-tolerant on whole IMPLEMENTATION-PLAN.md | proven via SHA-256 in BD-106 IMPLEMENTATION-REPORT §6.4 (slice fixture); broader fixture exercises semantic round-trip via re-parse | **MATCH** |
| 15 | Path 3 forbidden — no `folded-into:` label, no inline `(from TD-NNN)` body marker recognition | absent from schema | absent from schema; Test 5.6 asserts non-existence of `tracker_labels_folded_into` helper at runtime | **MATCH** |
| 16 | Provider operation surface | `provider.link()` unchanged; `annotation` is sidecar-only (V1 §6.6 routing) | no provider operation extension; annotation lives in sidecar only | **MATCH** |

**Result: 16 / 16 MATCH.** The coder's synthesis is byte-aligned
with the architect's independent §6.R recommendation across every
schema decision. No DIVERGE rows.

The coder's interpretation note in IMPLEMENTATION-REPORT-BD-106
§3 ("This interpretation is flagged here as a planner-deferred-to-
coder decision; if the architect later authors a real V3.3 §6.R
that contradicts this shape, the field can be renamed without
changing the round-trip semantics") is a correctly-cautious
disclaimer. The architect's §6.R does not contradict; it ratifies.


---

## §A.7 Recommendation to Pack Chat

The architect's recommendation: **ratify the coder's BD-106
working tree as the BD-106 implementation; commit on user approval
without re-spinning the coder.**

Rationale:

- The coder's schema is 16 / 16 MATCH against the independent
  architect §6.R recommendation. There is no schema decision that
  needs re-implementation.
- The coder's tests (60 / 60 PASS; SHA-256 byte-identity proof on
  the slice fixture; full tracker-* test sweep 720 / 720 PASS;
  validate-pack PASS; customization-preserve 233 / 233 PASS) cover
  the §6.R round-trip contract.
- The coder's interpretation note (IMPLEMENTATION-REPORT §3) is
  honest and correct in its uncertainty about whether a future
  §6.R might contradict; the architect's §6.R does not
  contradict, so the disclaimer becomes inert on commit.

The single architectural action that remains is a documentation
correction to V3.x corpus, not a code change. Specifically:

1. **Pack Chat applies §A.5.1 + §A.5.2 + §A.5.3 to V3.3-DELTA.md
   in the same commit as the BD-106 work** (or in the immediately-
   preceding commit, with BD-106 referencing the now-existing
   §6.R). The trinity rule does not engage; V3.3-DELTA is single-
   file in v11-research/.

2. **Pack Chat applies §A.5.4 to IMPLEMENTATION-PLAN-ADDENDUM-4
   §6.R** (status flip from "deferred to BD-106 land-time" to
   "RESOLVED-RATIFIED 2026-05-14"). Same commit or follow-up;
   independent of BD-106 code.

3. **Pack Chat updates BD-106's BACKLOG entry File/Symbol prose
   to reference the now-existing §6.R** (a one-prose-line edit;
   replaces "per V3.3 §6.R" with "per V3.3 §6.R (formalised in
   ARCHITECTURE-V3.3-DELTA-ADDENDUM-1.md)" or, after §A.5.3
   inlining, just "per V3.3 §6.R"). The §6.R citation in the
   BACKLOG entry becomes valid.

4. **The coder's IMPLEMENTATION-REPORT §3 interpretation note can
   stand as-is** — it's an accurate record of the coder's
   reasoning at synthesis time, and the architect's ratification
   is recorded in this addendum + the V3.3-DELTA inlining. Pack
   Chat does not need to edit the IMPLEMENTATION-REPORT
   retroactively; the addendum + the BD-106 commit message
   together provide the after-the-fact ratification trail.

The alternative paths the prompt named — "coder respin against
architect schema" and "architecturally fix the working tree
directly via Pack Chat edits" — are not warranted. Both presume a
schema divergence that does not exist.

---

## §A.8 Decision audit — what this addendum does NOT do

To make the architect-pass scope crisp:

- **Does not introduce a new design decision.** §6.R was decided
  by the maintainer in IMPLEMENTATION-PLAN-ADDENDUM-4; this
  addendum writes the decision into the V3.x corpus where it
  belongs. The schema was already fixed; the architect's role is
  ratification + corpus integration.
- **Does not introduce a new BD.** No BD-NNN is needed for the
  V3.3-DELTA edits (§A.5.1, §A.5.2, §A.5.3). They are corpus
  hygiene + a forward reference repair. Pack Chat applies them in
  the BD-106 commit (or an adjacent docs commit) per existing
  v11-dev cadence.
- **Does not introduce a new POQ / OQ.** No question is deferred.
  The §6.R schema is complete; the corpus edits are mechanical.
- **Does not modify code.** The BD-106 working tree is correct
  per the architect's independent §6.R; no code change is
  recommended. The coder's tests prove the schema; the architect's
  text proves the schema is the right one.
- **Does not engage trinity rule.** No CLAUDE.md / AGENTS.md /
  GEMINI.md edits at pack root or project-template. V3.3-DELTA is
  single-file in v11-research/; trinity rule does not apply
  file-wise.
- **Does not engage validate-pack.** No new check; no schema check
  on sidecar YAML at v11.0 (V3.3 §6.2 declares "no JSON schema
  validation in v11.0"). The check that does exist at land-time
  (per BD-106 BACKLOG entry's DoD) is the test runner under
  `scripts/tests/test-tracker-phase-task.sh` 60 / 60 PASS, which
  exercises the schema directly.
- **Does not change the §6.R MAINTAINER CHECK location convention.**
  Future maintainer-check items in IMPLEMENTATION-PLAN addenda
  continue the §6.X letter convention. When a §6.X resolves with
  schema-bearing content (as §6.R did), the architect-pass
  produces a corpus addendum (this file's pattern) and Pack Chat
  inlines into the live spec. The MAINTAINER CHECK list is the
  staging area; the V3.x corpus is the live spec.

---

## §A.9 Cross-impact with other open V3.3 decisions

§6.R interacts with two other §6.X items still in flight per
IMPLEMENTATION-PLAN-ADDENDUM-4:

- **§6.O (Check 28 redundancy)** — independent. §6.R is
  schema-internal; §6.O is validate-pack check numbering. No
  interaction.
- **§6.O.1 (Check 25 numbering collision)** — independent. The
  numbering audit happens at BD-082 land-time. No interaction
  with sidecar schema.
- **§6.N (BD-074 vs BD-110 skill-shipping)** — independent.
  Skill-file ship is orthogonal to phase-task sidecar shape.
- **§6.M (resolved — pack-auditor per-CLI replication)** —
  independent. Agent-file layout is orthogonal to sidecar shape.
- **§6.P (Architect-default for Path 1) — resolved (a)** —
  independent. PM Chat orchestration policy is orthogonal to
  sidecar shape.
- **§6.Q (Cycle-check K-value) — resolved (a)** — independent.
  Cycle check operates on resolved tracker IDs; it does not
  inspect the `annotation` field.

§6.R is the smallest of the §6.X items by design surface and the
last to ratify before BD-106 commit. After §6.R resolves, the
remaining §6.X items (§6.N, §6.O, §6.O.1) are all land-time
deferred per the §6.C audit framework — none block BD-106.

---

## §A.10 Summary

The §6.R schema is `dependency_edges: [{kind, target,
annotation}]` with the always-emitted-annotation convention and
the V3.3 §5.3 grammar regex extended to capture the trailing
prose. The schema is grounded in V1 §6.0 (bidirectionality), V1
§6.6 (sidecar routing), V1 §2.1 / §2.2 (provider link operation +
canonical Issue.links field name), V1 §5.3 (link.kind reserved
values), V3.3 §4.3 (sidecar phase_tasks block carry-forward), and
V3.3 §5.3 (Dependencies bullet grammar). It is the resolution
recorded in IMPLEMENTATION-PLAN-ADDENDUM-4 §6.R option (a), with
two refinements (`target` field name; always-emitted annotation)
that the maintainer-check did not enumerate but the architect-pass
ratifies.

The coder's BD-106 working tree implements this schema exactly
(16 / 16 MATCH; no DIVERGE). The architect recommends ratification
of the working tree as-is, with three V3.x corpus documentation
edits (§A.5.1, §A.5.2, §A.5.3) and one MAINTAINER CHECK status
flip (§A.5.4) applied by Pack Chat.

After the corpus edits land, V3.3-DELTA.md ships with §6.1..§6.5
plus §6.R as authored sections, the §5.3 grammar text reflects the
annotation-capturing parser regex, and IMPLEMENTATION-PLAN-
ADDENDUM-4 §6.R shows resolved-ratified status. BD-106's spec
citation of §6.R becomes valid; future readers reach the schema
directly without traversing the maintainer-check list.

**End of addendum.**

