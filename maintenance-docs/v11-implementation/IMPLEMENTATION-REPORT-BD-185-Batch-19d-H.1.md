# IMPLEMENTATION REPORT — BD-185 Batch 19d.H.1

**Commit:** H.1 — v11.1 templates-archive cut (phase-part-v11.1 schema + INDEX).
**Branch:** `v11-dev`.
**HEAD at start of work:** `0912a7e` (planner pass + POQ resolution
committed; CI green).
**HEAD at end of work:** `0912a7e` (no state-changing git verbs run by
this agent per Pack memory; commit is Pack Chat's responsibility).
**Date:** 2026-05-26.

---

## §1 Scope

Per PLAN-BD-185.md §H.1 (the first INLINE implementation commit of
Batch 19d). H.1 creates the v11.1 templates-archive subtree as the
schema foundation for all downstream BD-185 work. Two files CREATE,
no edits to existing files.

H.1 establishes:
- The `phase-part-v11.1` per-entry-type schema (NEW entity type
  introduced by BD-185 mid-work phase expansion).
- The `v11.1/INDEX.md` declaring 6 entry types (parallel to v11.0/INDEX.md
  which has 5).

Per D16 Convention Y (USER-LOCKED 2026-05-26), v11.0 archive remains
structurally frozen at 5 entry-type subdirs; v11.1 is the NEW archive
cut adding `phase-part-v11.1` as the 6th type. Intra-file additive
extensions to v11.0 SCHEMAs are permitted (BD-185 H.13 + H.14) but
land in later commits.

Per POQ-1 resolution 2026-05-26, the v11.1 `forms/work-item.yml` file
is INTENTIONALLY NOT created at H.1; it lands at H.2 byte-identically
with the live form, eliminating the H.16-refresh placeholder pattern.

Cross-references: ARCHITECTURE-BD-185.md §1.4 (16-decision log),
§4.1 (C-1 Part-id grammar), §4.3 (form-family extension + template-
version delta table), §4.4 (Part state taxonomy lifecycle invariant),
§4.7 (sub-issue parentage rules), §10.1 (Convention Y), §11.1 (SCHEMA
archive extensions); PLAN-BD-185.md §H.1.

---

## §2 Inputs read

| # | Path | Sections | HEAD SHA at read |
|---|---|---|---|
| 1 | `maintenance-docs/v11-implementation/PLAN-BD-185.md` | §H.1 (full) + plan-summary table rows for H.1 + H.2 + H.14 (ordering context) | 0912a7e |
| 2 | `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md` | §1.4 Decision log (16 USER-LOCKED decisions); §4.1 (C-1 grammar); §4.1a (D15 task numbering rule); §4.3 (form-family extension); §4.4 (Part state taxonomy + lifecycle invariant); §4.4a (D5 cancelled state — phase-task-only); §4.7 (re-parentage rules, D3 no-empty-Part, D4 supersede-only); §10.1 (Convention Y, D16); §11.1 (SCHEMA archive extensions) | 0912a7e |
| 3 | `maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md` | full (structural template — parallel grammar pattern for SCHEMA section structure, body-section grammar, dependency grammar) | 0912a7e |
| 4 | `maintenance-docs/v11-research/templates-archive/v11.0/phase-epic-v11.0/SCHEMA.md` | full (structural template — body marker trio shape, sub-issue parentage section structure) | 0912a7e |
| 5 | `maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md` | full (structural template — entry-type enumeration table format, cross-reference style) | 0912a7e |
| 6 | `maintenance-docs/v11-research/templates-archive/README.md` | full (archive contract; "Pack-repo only" rule; layout convention) | 0912a7e |

All authoritative inputs read in full. No deviations from
authoritative-input reads.

---

## §3 Files created

Two NEW files. Zero files modified. Zero files deleted.

### 3.1 `maintenance-docs/v11-research/templates-archive/v11.1/phase-part-v11.1/SCHEMA.md`

- **Status:** NEW (created at H.1).
- **Size:** 225 lines (~9.4 KB markdown).
- **Section structure** (H2 headings):
  1. Identifier scheme — C-1 grammar (`Phase-N.Part-x`), atom regex,
     uniqueness scope, identity owner, round-trip carrier, prohibited
     forms (4 rejected shapes per §4.1).
  2. Body marker trio — `<!-- pack-id: phase-N.Part-x -->`,
     `<!-- template_version: phase-part-v11.1 -->`,
     `<!-- pack-version: v11 -->`. Parser/emitter cross-reference to
     BD-185 H.5 `tracker-phase-part.sh`.
  3. Label family — provenance/parent/template/status labels;
     excluded labels with rationale (merged-into, superseded-by,
     cancelled, derived-from).
  4. State mapping — 4-state table (`pending / in-progress / done /
     deferred`); lifecycle invariant block (D2, D3, D4 cross-refs).
  5. Body section grammar — Goal (required) / Prerequisites
     (optional) / Member tasks (optional, informational). Prerequisite
     grammar admits all 7 ID forms per §4.1 + backward-compat shim.
  6. Sub-issue / hierarchy — depth-2 under phase epic, depth-3 parent
     of tasks; capability flags fallback; re-parentage cross-reference
     to BD-185 §4.7.
  7. Reverse-emit grammar — stubbed as TBD with H.8 cross-reference;
     anticipated H3 shape preview included for forward-context.
  8. Body marker reservations — execution-note-status historical
     marker is reserved for phase-N.md per D8; cross-reference to
     §6.3a included for completeness.

### 3.2 `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md`

- **Status:** NEW (created at H.1).
- **Size:** 78 lines (~3.7 KB markdown).
- **Section structure:**
  1. Heading + meta — H1 + pack-version note + BD-185 driver
     reference.
  2. Entry types at v11.1 — 6-row table enumerating all entry types
     (bd, td, phase-epic, phase-task, **phase-part NEW**, inbound)
     with relative-path schema links (5 link `../v11.0/...`; 1 links
     `phase-part-v11.1/SCHEMA.md` in-cut).
  3. v11.0 archive cross-reference — Convention Y (D16) reference;
     two enumerated intra-file additive extensions landing in H.13
     and H.14.
  4. v11.1 form file — POQ-1 resolution 2026-05-26 deferral note;
     describes post-H.2 form delta (5th wi-type option,
     wi-part-letter, description-text updates).
  5. Decision log cross-reference — explicit cross-reference to
     ARCHITECTURE-BD-185.md §1.4; enumerates 8 most-load-bearing
     decisions (D1, D2, D3, D4, D5, D11, D15, D16).

---

## §4 SCHEMA.md content highlights

### Identifier scheme (Section 1)

- Atom regex documented for `Phase-N` (`[1-9][0-9]*`; v10-compat for
  `Phase-0`) and `Part-x` (`[a-z]`; 26-Part cap stated as
  architect-pass review trigger, not default case).
- Per-project, per-phase uniqueness scope `(N, x)`.
- Identity owner = pack (`pack phase split` and
  `pack tracker phase split` verbs per BD-185 §4.5).
- Round-trip carrier = title prefix `Phase N.Part x — <part title>` +
  body marker `<!-- pack-id: phase-N.Part-x -->`.
- 4 prohibited forms with rationale: empty-separator (`Phase-2..Part-a`),
  lowercase atoms, numeric Part identifier, plus implicit prohibition
  by atom-regex on multi-character Part labels.

### Body marker trio (Section 2)

Exactly three markers, all required, in exact order matching
phase-epic-v11.0 and phase-task-v11.0 patterns:

```
<!-- pack-id: phase-N.Part-x -->
<!-- template_version: phase-part-v11.1 -->
<!-- pack-version: v11 -->
```

Parser/emitter (BD-185 H.5 `tracker-phase-part.sh`) cross-reference
embedded.

### Label family (Section 3)

5-column table with the 4 labels Parts carry (`phase-part`, `phase-N`,
`template:phase-part-v11.1`, `status:<pending|in-progress|done|deferred>`).

Explicit "Excluded labels" block enumerating 4 excluded label
patterns with per-pattern rationale:
- `status:merged-into:phase-N` — lifecycle merge is phase-epic
  responsibility.
- `status:superseded-by:phase-N.M` — same.
- `status:cancelled` — D5 extension applies to phase-task-v11.0 only
  per §4.4a.
- `derived-from:TD-NNN` — TD-promotion targets phase-epic / phase-task,
  not phase-part.

### State mapping (Section 4)

4-state restrictive taxonomy (pending / in-progress / done / deferred)
in 4-column table format paralleling phase-task-v11.0 Section 3.

State-mapping consequences:
- `pending` → open + no state_reason
- `in-progress` → open + no state_reason
- `done` → closed + `completed`
- `deferred` → closed + `not_planned` (with member-tasks-stay note
  per D4)

Lifecycle invariant block at end of section captures D2 (no-collapse),
D3 (no-empty-Part), D4 (no-mid-life-re-parent), and the deferral-as-
only-exit rule.

### Body section grammar (Section 5)

Fenced block showing:
- 3-marker body header
- `## Goal` (required, free-text)
- `## Prerequisites` (optional, ID-per-line)
- `## Member tasks` (optional, informational)

Section order is FIXED. Parser/emitter cross-reference to BD-185 H.5.

Prerequisite grammar admits the 7 ID forms per BD-185 §4.1:
- `phase-N` (phase-only)
- `Phase-N.Part-x` (Part-only)
- `Phase-N.Task-M` (null-Part task)
- `Phase-N.Part-x.Task-M` (Part-scoped task)
- `phase-N.M` (legacy task, backward-compat shim)
- `TD-NNN` (TD entry)
- `BD-NNN` (BD entry)

Explicit "INFORMATIONAL, not authoritative" note on Member tasks
section: the authoritative parent-child relationship is via sub-issue
parentage (Section 6), not the body bullet list.

### Sub-issue parentage (Section 6)

Phase parts are:
- CHILDREN of phase epic (`phase-N`) at sub-issue depth 2
- PARENTS of phase tasks at sub-issue depth 3

Capability-flag fallback (`parent:phase-N` label when
`hierarchy.supported = false`) included per V3.2 §2.7.

Re-parentage cross-reference: `pack tracker phase split`
(`provider_sub_issue_unlink` + `provider_sub_issue_create` op pair
per BD-185 §4.7).

Depth-cap preservation noted: 8-level cap respected; 100 children per
parent + 1 parent per child preserved.

### Reverse-emit grammar (Section 7)

Stubbed as TBD with explicit BD-185 H.8 cross-reference. Anticipated
H3/H4 shape preview included so forward-readers can see the intended
direction without committing to grammar pre-H.8.

### Body marker reservations (Section 8)

Documents that the optional `<!-- execution-note-status: historical -->`
marker (per D8 / BD-185 §6.3a) is reserved for phase-N.md and does
NOT apply to phase-part-v11.1. Included for completeness so SCHEMA
readers understand the intentional absence.

---

## §5 INDEX.md content highlights

### 6-entry-type enumeration

Table contains exactly 6 rows (parallel to v11.0/INDEX.md's 5 rows).
Each row carries: entry type name, schema link, body-marker
`template_version`, label.

The phase-part-v11.1 row is bolded with "NEW in v11.1" marker for
visual emphasis. Five rows link to `../v11.0/<entry-type>-v11.0/SCHEMA.md`;
the phase-part row links to in-cut `phase-part-v11.1/SCHEMA.md`.

### v11.0 cross-reference (Convention Y)

Explicit D16 / USER-LOCKED 2026-05-26 reference for Convention Y:
v11.0 archive structurally frozen at 5 subdirs; intra-file additive
extensions permitted under backward-compatible-content-evolution rule.

Two enumerated downstream extensions captured:
1. `../v11.0/phase-task-v11.0/SCHEMA.md` Section 3 extension (admit
   `status:cancelled`) — lands at H.13.
2. `../v11.0/INDEX.md` forward-reference footnote — lands at H.14.

### Form-family deferral note (POQ-1 resolution 2026-05-26)

Explicit acknowledgment that `forms/work-item.yml` is INTENTIONALLY
NOT created at H.1; lands at H.2 byte-identically with the live form.

Describes the post-H.2 live form delta:
- `wi-type` 5th option `phase-part-skeleton`
- NEW `wi-part-letter` input (conditional)
- description-text updates admitting `Phase-N.Part-x` and
  `Phase-N.Part-x.Task-M` forms in Blockers/Unblocks/Dependencies

Template-version delta context: only `work-item-v11.0` bumps to
`work-item-v11.1`; the 4 prior per-entry-type template_versions
remain unchanged; `phase-part-v11.1` is the only NEW per-entry-type
template_version.

### Decision log cross-reference

Explicit cross-reference to ARCHITECTURE-BD-185.md §1.4 (16-decision
log) with the 8 most-load-bearing decisions enumerated for this
archive cut: D1, D2, D3, D4, D5, D11, D15, D16.

---

## §6 Verification

### 6.1 `python3 scripts/validate-pack.py`

**Result:** PASS. All 43 checks clean. Tail of output:

```
── Check 43: Project-side bare cross-reference scanner (BD-173) ──
  OK: Check 43 — 152 project-side / client-installed file(s) walked; ...

PASSED — all checks clean
```

No new check failures introduced. The architect notes the NEW Check
`check_phase_part_schema_v11_1` (per §10.2) is planned for H.10 / H.11
sequencing, NOT at H.1; the schema exists and is well-formed but the
validator gate that asserts its existence has not yet been wired.
This is by ordering design (H.10 + H.11 land later in batch 19d).

### 6.2 Directory layout

```
$ ls maintenance-docs/v11-research/templates-archive/v11.1/
INDEX.md
phase-part-v11.1

$ ls maintenance-docs/v11-research/templates-archive/v11.1/phase-part-v11.1/
SCHEMA.md
```

Matches PLAN H.1 expected layout.

### 6.3 `forms/` NOT created at H.1

```
$ ls maintenance-docs/v11-research/templates-archive/v11.1/forms/ 2>&1
ls: maintenance-docs/v11-research/templates-archive/v11.1/forms/: No such file or directory
```

Confirms POQ-1 resolution: `forms/work-item.yml` deferred to H.2.

### 6.4 INDEX.md 6-entry-type enumeration grep

```
$ grep -cE "bd-v11.0|td-v11.0|phase-epic-v11.0|phase-task-v11.0|phase-part-v11.1|inbound-v11.0" maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md
16
```

Each of 6 entry types referenced multiple times (table row + cross-ref
sections). Threshold (≥6) satisfied.

### 6.5 SCHEMA.md required-section grep

```
$ grep -nE "^## " maintenance-docs/v11-research/templates-archive/v11.1/phase-part-v11.1/SCHEMA.md
18:## 1. Identifier scheme
42:## 2. Body marker trio
63:## 3. Label family
87:## 4. State mapping
112:## 5. Body section grammar
122:## Goal
127:## Prerequisites
132:## Member tasks
165:## 6. Sub-issue / hierarchy
187:## 7. Reverse-emit grammar
216:## 8. Body marker reservations
```

All 8 required sections present (1-8). Inner H2 sub-headings (Goal /
Prerequisites / Member tasks) appear in the fenced body-grammar block
at lines 122/127/132 — these are NOT structural sections of the SCHEMA
itself but illustrative content inside Section 5's grammar block.
Section ordering is correct (numbered 1-8 monotonic).

### 6.6 RC9 manifest regen

`bash test-fixtures/build.sh --all --clean` ran to completion. `git diff
--stat test-fixtures/manifest.txt` is empty. Confirms `maintenance-docs/`
is correctly outside the v11-surface 4-directory trigger (BD-176 rule).
No manifest staging required.

### 6.7 Filename uniqueness preserved

H.0 baseline checks confirmed zero matches:

```
$ find . -name "SCHEMA.md" -path "*phase-part-v11.1*" -not -path "./.git/*"
(no matches before H.1)

$ find . -name "INDEX.md" -path "*templates-archive/v11.1*" -not -path "./.git/*"
(no matches before H.1)
```

Post-H.1: only the two NEW files match these patterns. No collisions
with any existing file in the repo. The path-disambiguation rule per
CLAUDE.md filename uniqueness heuristic permits two `SCHEMA.md` files
in the templates archive because they are structurally required
(per-entry-type per-version pattern; same exemption as the 5 v11.0
SCHEMA.md files).

---

## §7 Cross-references

| Doc | Section | Purpose |
|---|---|---|
| ARCHITECTURE-BD-185.md | §1.4 | 16-decision log (D1-D16 USER-LOCKED) |
| ARCHITECTURE-BD-185.md | §4.1 | C-1 Part-id grammar (`Phase-N.Part-x`) |
| ARCHITECTURE-BD-185.md | §4.1a | D15 task numbering rule (Task-M integer only) |
| ARCHITECTURE-BD-185.md | §4.3 | Form-family extension + template-version delta table |
| ARCHITECTURE-BD-185.md | §4.4 | Part state taxonomy + lifecycle invariant |
| ARCHITECTURE-BD-185.md | §4.4a | D5 phase-task `cancelled` state (NOT applied to Parts) |
| ARCHITECTURE-BD-185.md | §4.7 | Re-parentage rules, D3 no-empty-Part, D4 supersede-only |
| ARCHITECTURE-BD-185.md | §10.1 | D16 Convention Y (v11.0 frozen / v11.1 NEW) |
| ARCHITECTURE-BD-185.md | §11.1 | SCHEMA archive extensions (H.13 + H.14 forward refs) |
| PLAN-BD-185.md | §H.1 | This commit specification |
| templates-archive/v11.0/phase-task-v11.0/SCHEMA.md | full | Structural template (parallel grammar pattern) |
| templates-archive/v11.0/phase-epic-v11.0/SCHEMA.md | full | Structural template (body marker trio shape) |
| templates-archive/v11.0/INDEX.md | full | Structural template (entry-type table format) |
| templates-archive/README.md | full | Archive contract; pack-repo-only rule |

---

## §8 Success criteria checklist

Per PLAN-BD-185.md §H.1 success criteria:

| # | Criterion | Status |
|---|---|---|
| 1 | `v11.1/phase-part-v11.1/SCHEMA.md` exists with C-1 grammar + body marker trio + state taxonomy per architect §4.3 + §4.4 | PASS |
| 2 | `v11.1/INDEX.md` declares 6 entry types with v11.0 cross-references | PASS |
| 3 | `v11.1/forms/work-item.yml` NOT created at H.1 (deferred to H.2 per POQ-1 resolution 2026-05-26) | PASS |
| 4 | `python3 scripts/validate-pack.py` exits 0 | PASS |
| 5 | No collision with any existing file in repo (filename uniqueness preserved) | PASS |

Per coder-prompt extended success criteria (§7 of prompt):

| # | Criterion | Status |
|---|---|---|
| 6 | No source code changed; only maintenance-docs/v11-research/ + maintenance-docs/v11-implementation/ paths touched | PASS |
| 7 | IMPL-REPORT written per contract above | PASS (this report) |

All 7 success criteria PASS.

---

## §9 Files touched inventory

| Path | Change | Lines | Why |
|---|---|---|---|
| `maintenance-docs/v11-research/templates-archive/v11.1/phase-part-v11.1/SCHEMA.md` | NEW | +225 | Per PLAN H.1 §1: declares phase-part-v11.1 schema |
| `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md` | NEW | +78 | Per PLAN H.1 §2: declares 6 entry types + v11.0 cross-references |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.1.md` | NEW | (this report) | Required IMPL-REPORT per pack-coder contract |

**Total:** 3 NEW files. Zero existing files modified. Zero files
deleted. All paths under `maintenance-docs/` (no v11-surface trigger
for RC9 manifest regen per BD-176).

---

## §10 Plan deviations

**None.** Zero deviations from PLAN-BD-185.md §H.1. The 8-section
SCHEMA structure prescribed by the coder prompt was implemented
exactly. The 5-section INDEX.md structure prescribed by the coder
prompt was implemented exactly. POQ-1 resolution honored (no
`forms/work-item.yml` at H.1). All 16 USER-LOCKED decisions D1-D16
respected.

---

## §11 New POQs introduced

**None.** No new POQs surfaced during H.1 implementation. The 7
planner POQs + 9 architect decisions + D15 + D16 = 16 USER-LOCKED
decisions covered all design choices needed for this commit.

---

## §12 Boundary discipline check

Per the pack-coder system-prompt boundary-discipline pre-flight
(P-missed-7):

H.1 touches `maintenance-docs/v11-research/templates-archive/v11.1/`
exclusively. This is a **pack-only** surface (the archive is
explicitly pack-repo-only per `templates-archive/README.md` §
"Pack-repo only" — client projects do not maintain their own archive).
No project-template/ or supporting-docs/ files were touched. No
project-side SSOT investigation triggered.

**Boundary discipline result:** PASS. All H.1 edits are pack-side; no
pack-only-content-leaking-into-project-side risk.

---

## §13 Definition-of-Done checklist

| # | DoD item | Status |
|---|---|---|
| 1 | All 2 in-scope file edits complete | PASS |
| 2 | All success criteria from PLAN §H.1 PASS (5/5) | PASS |
| 3 | `python3 scripts/validate-pack.py` exits 0 | PASS |
| 4 | RC9 manifest empty diff after `--all --clean` rebuild | PASS (maintenance-docs/ not v11-surface) |
| 5 | No state-changing git verbs run by this agent | PASS |
| 6 | No files outside scope edited | PASS |
| 7 | IMPL-REPORT written at prescribed path | PASS |
| 8 | Trinity rule N/A (no CLAUDE/AGENTS/GEMINI files touched) | N/A |
| 9 | Filename-uniqueness rule PASS (only structurally-required SCHEMA.md collision; per-entry-type-per-version pattern; archive-internal disambiguation by path) | PASS |
| 10 | Boundary discipline PASS (pack-only edits; no project-side SSOT needed) | PASS |

All DoD items PASS or N/A.

---

## §14 Next-step pointer

H.2 is the next implementation commit per PLAN §H.1 → §H.2 sequence.
H.2 creates the post-bump live form (5th wi-type option +
wi-part-letter input + description-text updates), the byte-identical
client-template mirror, AND the byte-identical archive copy at
`maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml`
(the file deferred from H.1 per POQ-1 resolution).

H.2 fires RC9 manifest regen (touches `.github/ISSUE_TEMPLATE/` +
`project-template/.github/ISSUE_TEMPLATE/` — both v11-surface).

This is purely an informational pointer; H.2 is not in scope for the
H.1 IMPL-REPORT. Pack Chat orchestrates the H.1 commit + downstream
H.2 spawn per the BD-185 19d execution plan.
