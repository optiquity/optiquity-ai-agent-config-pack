# ARCHITECTURE — Per-Entry Flat-Files: Pack-Self vs Client-Project Differentiation

**Author:** pack-architect (v11-dev)
**Date:** 2026-05-12
**Branch:** v11-dev
**Status:** Architecture follow-up; read-only deliverable; no implementation in this batch
**Output file:** `maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-PACK-VS-CLIENT.md`
**Parent:** `maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-FLAT-FILES.md`

---

## 0. Scope and posture

This document extends the parent ARCHITECTURE-PER-ENTRY-FLAT-FILES.md.
The locked shape (per-entry files + immutable `_rules.md` + mutable
`_toc.md`) is **not** revisited. Parent §§4-15 stand as-is.

This pass closes the gap the parent deferred in §19 Q1 + Q2 plus the
scattered hints at §4.3, §4.4, §15.7: **what is common to both targets
and what is unique to each — pack-self versus client projects.**

"Pack-self" = this repo at v11-dev tip; the pack maintainer's working
tree. "Client project" = a project that ran `scripts/init-project.sh`
and consumes the pack as a versioned dependency.

Every claim about current state is cited by file:line. Parent doc
references use anchor form (§4.3, §17.3, etc.).

The 11 H2 sections below match the 11 differentiation points enumerated
in the brief, in order. §12 is a common-vs-unique summary table. §13
is a BD-mapping table for parent §17.3's BD-X1..BD-X12. Any required
changes to the parent doc are flagged in §14 (`## Parent-doc deltas
required`).

---

## 1. Stream roster per target

### 1.1 What pack-self has today

The pack repo carries these stream-shaped artifacts at the root (cited
from current v11-dev tip):

- `BACKLOG.md` — 3,556 lines, 140 entries (parent §0).
- `CHANGELOG.md` — 590 lines (`wc -l CHANGELOG.md` → 590; parent §16.1).
- `PACK-CHAT.md` — 199 lines, PM-chat operating rules; not a stream.
- `PACK-AGENTS.md` — 180 lines, agent routing table; not a stream.

There is **no** `STATUS.md` at the pack root, and **no**
`IMPLEMENTATION_PLAN.md` or `IMPLEMENTATION-PLAN.md` at the pack root.
This was confirmed via `grep -n "STATUS\.md\|IMPLEMENTATION_PLAN\.md\|
IMPLEMENTATION-PLAN\.md" PACK-CHAT.md CLAUDE.md AGENTS.md GEMINI.md`
returning no matches against the pack-root trinity.

The plan-class artifacts that *would* sit in an `IMPLEMENTATION-PLAN.md`
live instead in `maintenance-docs/v11-research/` as
`IMPLEMENTATION-PLAN.md` (1,109 lines) + `IMPLEMENTATION-PLAN-ADDENDUM*.md`
(four addenda) + `ARCHITECTURE.md` (2,239 lines) +
`ARCHITECTURE-V2.md` / `V3*.md` / `REVIEW*.md` / `PACK-REVIEW-*.md`.
This is the v11-research carve-out (covered in §2 below).

### 1.2 What client projects have today

Per `project-template/CLAUDE.md:221-225` (the Document locations
table), a freshly-initialized client project carries
`docs/project/`:

```
| `docs/project/` | `ARCHITECTURE.md`, `IMPLEMENTATION-PLAN.md`,
                    `BACKLOG.md`, `STATUS.md`, `CHANGELOG.md` |
```

All four stream-shaped artifacts plus `ARCHITECTURE.md` (which is not
a stream — it's the project's design document).

`project-template/docs/pack/PM-CHAT.md:119-124` confirms the four
streams via the File access strategy table:

```
| `BACKLOG.md`        | Direct read | ... |
| `STATUS.md`         | Direct read | ... |
| `CHANGELOG.md`      | Direct read (last entry only) | ... |
| `IMPLEMENTATION-PLAN.md` | Direct read (current phase section only) | ... |
```

### 1.3 Asymmetry observed

Pack-self has 2 of 4 streams (backlog, changelog). Client has 4 of 4.
The two missing pack-side streams are **STATUS** and **IMPLEMENTATION-PLAN**.

The deferral has a structural reason, captured by the pack-memory rule
"Separate pack ops from pack product" (`CLAUDE.md:163-167`): pack
work-plans are *operational artifacts*, not pack product, so they live
under `maintenance-docs/`, not at root. By contrast, a client project's
plan-class doc *is* its primary work artifact and belongs at root.

### 1.4 Roster decision per target

**Pack-self in v11.1: stays at 2 streams.**

Recommended: pack-self adopts `backlog/` (replaces `BACKLOG.md`) and
`changelog/` (replaces `CHANGELOG.md`). It does **not** grow `status/`
or `implementation-plan/` at the root. Existing
`maintenance-docs/v11-research/IMPLEMENTATION-PLAN.md` remains where it
is, untouched by this proposal.

Justification:
1. The parent §4.3 explicitly carves this out: "the pack repo has no
   `IMPLEMENTATION_PLAN.md` at root today — the v11 plans live in
   `maintenance-docs/v11-research/`. The proposal does *not* relocate
   v11-research artifacts; they're a different class of doc per
   `CLAUDE.md` pack-memory `## Repo conventions` ['Separate pack ops
   from pack product']." This deferral becomes a permanent
   asymmetry, not a v11.1 todo.
2. Pack-self has no STATUS.md today; *adding* one to migrate it is a
   net-new artifact that introduces churn for no measurable benefit
   (pack uses commit messages + CHANGELOG entries for the same role
   per `CLAUDE.md:55-65` commit-message rules).
3. The rules-file shape handles absence cleanly: per-stream
   `_rules.md` only exists for streams that exist. The pack repo's
   filesystem carries `backlog/_rules.md` and `changelog/_rules.md`
   only. No `status/` and `implementation-plan/` directories exist on
   pack-side.

**Client projects in v11.1: 4 streams.**

`docs/project/{backlog,implementation-plan,status,changelog}/` per
parent §4.1, identical to parent design.

### 1.5 Handling of the absence in `_rules.md`

The pack-side `_rules.md` files reference cross-stream syntax (parent
§7.1). On pack-self, where `implementation-plan/` and `status/` do
not exist, the cross-reference syntax for those streams is **still
documented** in `_rules.md` for two reasons:

- The rules file is owned by the pack template and ships
  byte-identical (or near-identical, see §3 below) between
  pack-self's `backlog/_rules.md` and the client template's
  `project-template/docs/project/backlog/_rules.md`.
- A pack-self BD may still cite a v11-research plan section via a
  trailing path (`See maintenance-docs/v11-research/IMPLEMENTATION-PLAN.md
  §Phase 4`); that's existing prose-citation, not the per-entry
  cross-reference syntax.

The cross-reference syntax for `status/YYYY-MM-DD.md` and
`implementation-plan/phase-NN.md` is dead code on pack-side. The
rules-file documents it anyway because that documentation is the
template's contract, not a per-project-tailored statement. Cleaner
than maintaining two near-duplicate rules files.

---

## 2. The v11-research carve-out boundary

### 2.1 What lives in `maintenance-docs/v11-research/` today

`ls maintenance-docs/v11-research/` returned 27 files at session
start, including:

- `ARCHITECTURE.md` (2,239 lines), `ARCHITECTURE-V2.md`,
  `ARCHITECTURE-V3.md`, `ARCHITECTURE-V3.1-DELTA.md`,
  `ARCHITECTURE-V3.2-DELTA.md`, `ARCHITECTURE-V3.3-DELTA.md`,
  `ARCHITECTURE-REVIEW.md`, `ARCHITECTURE-REVIEW-PASS2.md`,
  `ARCHITECTURE-REVIEW-PASS3.md`.
- `IMPLEMENTATION-PLAN.md` (1,109 lines),
  `IMPLEMENTATION-PLAN-ADDENDUM.md` (and -2, -3, -4).
- `DESIGN-BRIEF.md`, `EXTERNAL-RESEARCH.md`, `INTERNAL-INVENTORY.md`,
  `MAINTAINER-CHECK-AUDIT-2026-05-07.md`, `RESEARCH-AUDIT.md`.
- `PACK-REVIEW-BDxxx-yyy.md` (7 of them), `PACK-REVIEW-CUMULATIVE-V11*.md` (2).
- `templates-archive/` directory.

These are all v11 design/research/review artifacts — workflow
ephemera per the pack-memory rule on "Workflow artifacts" in
`CLAUDE.md:171-184` (the exemption list:
`ARCHITECTURE-*.md`, `PLAN-*.md`, `IMPLEMENTATION-REPORT-*.md`,
`PACK-REVIEW-*.md`, `AUDIT-*.md`, `RESEARCH-*.md`,
`*-DISCOVERY.md` — these sweep to `maintenance-docs/archive/vN/`
at version ship per Pattern B).

### 2.2 Boundary statement

**`maintenance-docs/v11-research/` is pack-development workflow.
`implementation-plan/` (if it ever existed on pack-self) would be
pack-product cadence.**

The boundary, as drawn:

- v11-research/ — pack-self only. Authored by pack-architect / pack-planner
  / pack-reviewer during v11 development. Lives ~12 months
  (the lifespan of an in-flight major version). Swept to
  `maintenance-docs/archive/v11/` at v11-final ship per Pattern B.
  Never copied to client tree.
- `implementation-plan/` (parent §4) — client only. Lives at
  `docs/project/implementation-plan/` in client trees. Per-entry
  files for project phases. Persistent across the project's lifetime.

The boundary is structural: pack development plans (v11-research) are
maintainer-private workflow; client project plans
(`implementation-plan/`) are project-team-visible deliverables.
Conflating them would break "Separate pack ops from pack product"
(`CLAUDE.md:163-167`).

### 2.3 What if pack-self grew an `implementation-plan/` later?

Imagined future v12-self: pack-architect decides pack development
needs a persistent root-level plan. This is **not** the v11.1 design.
If that case ever materializes, the design choice would be:

- Move plan-class artifacts out of `maintenance-docs/v11-research/`
  into `implementation-plan/` at root, deletion of v11-research
  carve-out.
- This requires explicit pack-memory rule revision (the "Separate pack
  ops from pack product" rule would need re-scoping). That's a
  structural change requiring its own architect pass.

For v11.1 the answer is "no overlap by design"; v11-research stays
where it is; pack-self does not grow `implementation-plan/`.

### 2.4 What lives where — concrete doc-class table

| Doc class | Lives on pack-self at | Lives on client at |
|---|---|---|
| Architecture / design proposals | `maintenance-docs/v11-implementation/ARCHITECTURE-*.md`, `maintenance-docs/v11-research/ARCHITECTURE*.md` | `docs/project/ARCHITECTURE.md` (single file, not a stream) |
| Implementation plans | `maintenance-docs/v11-research/IMPLEMENTATION-PLAN.md` + addenda | `docs/project/implementation-plan/phase-NN.md` (per-entry stream) |
| Review / audit reports | `maintenance-docs/v11-implementation/PACK-REVIEW-*.md`, `AUDIT-*.md` | (not produced by clients; reviewer agent output is ephemeral) |
| Implementation reports | `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-NNN.md` | (not produced by clients) |
| Research / discovery | `maintenance-docs/RESEARCH-*.md`, `maintenance-docs/v11-research/RESEARCH-*.md`, `*-DISCOVERY.md` | (not produced by clients) |
| Open work items | `backlog/BD-NNN.md` (per-entry, v11.1+) | `docs/project/backlog/BD-NNN.md` or `TD-NNN.md` (per-entry, v11.1+) |
| Version history | `changelog/vN.M.md` (per-entry, v11.1+) | `docs/project/changelog/vN.M.md` (per-entry, v11.1+) |
| Phase state notes | (none — pack-self has no STATUS) | `docs/project/status/YYYY-MM-DD.md` (per-entry, v11.1+) |

Boundary is sharp: the per-entry streams under `docs/project/<stream>/`
on client are *project-team-visible* deliverables; everything under
`maintenance-docs/` on pack-self is *pack-maintainer-private*
workflow. No file class crosses the boundary.

---

## 3. `_rules.md` content: same or different

### 3.1 The three candidate models

The brief enumerates three positions:

(a) **Byte-identical** between pack-self and client template. Single
source of truth.

(b) **Structurally identical, content differs in examples.** Same H2
sections; pack version cites pack files (`scripts/lib/tracker-mirror.sh`)
in worked examples, client version cites Swift/Python files
(`Sources/Foo/Bar.swift`).

(c) **Structurally different.** Pack version carries fields the client
doesn't need (e.g., `Type: TODO(version)` flag, the v11-research
cross-link slot).

### 3.2 Recommendation: byte-identical, with reasoning

**Choose (a) byte-identical.** Pack-self's `backlog/_rules.md` is
literally the same file as `project-template/docs/project/backlog/_rules.md`
(modulo a single sentinel that names the file's owning pack version
per parent §5.2(a)).

Reasoning, ranked:

1. **The `_rules.md` is a rules file, not an examples file.** It
   declares the filename regex, required entry sections, lifecycle
   states, cross-reference syntax, TOC contract. None of these
   structurally differ between pack-self and client. The BD prefix
   regex `^[A-Z]{2}-\d{3}\.md$` accepts BD-001 (pack-self) and TD-001
   (client) equally. Lifecycle states (Open/Resolved/etc.) are
   identical.
2. **Defense-in-depth (parent §5.2) wants one mechanism, not two.**
   The sentinel + Check 31 + skill rule + chat rule guards a single
   immutable file class. Two near-identical rules files would force
   the validator to know which sentinel goes with which file —
   needless complexity.
3. **Migrator simplicity (parent §5.3).** `_rules.md` files ship
   from `project-template/docs/project/<stream>/_rules.md` into the
   client tree on `init-project.sh` and `migrate-vN-to-vM.sh` runs.
   If the pack repo's own copy is byte-identical, the pack repo just
   *uses* the template copy directly. Specifically: pack-self's
   `backlog/_rules.md` is a symlink to (or build-time copy from)
   `project-template/docs/project/backlog/_rules.md`. Single source of
   truth, single update locus.
4. **Worked examples don't belong in rules files.** If pack examples
   would naturally cite `scripts/lib/tracker-mirror.sh` and client
   examples would cite Swift/Python files, that's content for
   `METHODOLOGY.md`-class guidance, not the per-stream contract.
   Rules stay terse and declarative; examples live elsewhere.
5. **The "Type: TODO(version)" question (candidate c).** This field
   appears on five current pack-self BDs (BD-151..BD-155 per
   `BACKLOG.md` tail). It is in fact already valid client content —
   nothing prevents a client BD from carrying `Type: TODO(v12)`
   meaning "this is a future-version note." So this is not a
   pack-only field; it's an `_rules.md`-documented Type value that
   happens to be currently used only pack-side. The Type enum in
   `_rules.md` lists `TODO(version)` as one allowed value
   regardless of target.

### 3.3 Sentinel exception

Per parent §5.2(a), each `_rules.md` carries `<!-- PACK-IMMUTABLE:
v11.1 — do not edit. Updates ship via pack migration. -->`. The
version stamp is **identical** between pack-self's copy and the
client template's copy at any given moment — both name the pack
version that ships them. So even the sentinel doesn't break
byte-identity (the version is the pack version, not "pack-self vs
client").

### 3.4 Mechanism: how byte-identity is enforced

Validator Check 31 (parent §15.5) extends to assert byte-identity
between `backlog/_rules.md` (pack-self) and
`project-template/docs/project/backlog/_rules.md` (template) —
analogous to the existing Check 24 byte-identity assertion between
`HELP-FRAGMENT-TRACKER.md` (pack-root) and
`project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` (template)
referenced in parent §1.

This adds 4 byte-identity assertions to Check 31 (one per stream,
times the streams present on pack-self — 2 streams in v11.1, so 2
assertions: `backlog/_rules.md` and `changelog/_rules.md`). Adding
STATUS/IMPL-PLAN to pack-self in a future version would auto-extend
this check.

---

## 4. `_toc.md` content: same shape, different triggers

### 4.1 Shape — identical

The TOC table format (parent §6.1) is the same on both sides.
Stream-specific schemas (parent §6.1: backlog has `ID|Status|Title`;
implementation-plan has `Phase|State|Title`; status has
`Date|Phase|Summary`; changelog has `Version|Date|Summary`) are
fixed by stream type, not by target. Pack-self's `backlog/_toc.md`
and client's `docs/project/backlog/_toc.md` are structurally
identical.

The rebuild helper `scripts/lib/per-entry-toc.sh` (parent §6.2)
calls `per_entry_toc_rebuild <stream-dir>`. The function takes a
directory path; it doesn't know whether the directory is pack-self
or client. Same code, both targets.

### 4.2 Idempotency property — identical

Parent §6.4(a) idempotency (two consecutive rebuilds without
intervening edits → byte-equal output modulo timestamp) applies
unchanged.

### 4.3 Triggers — differ in cadence, identical in mechanism

Parent §6.3 lists three triggers:

1. Eager rebuild on entry add/remove/Status-change.
2. `/pack-startup` and `/pm-startup` reconciliation.
3. Tracker mirror writes.

All three apply to both targets. The cadence differs:

| Trigger | Pack-self cadence | Client cadence |
|---|---|---|
| Eager rebuild | Multiple times per day (active development churn) | Per PR batch (slower) |
| Startup reconcile | Every Pack Chat session start | Every PM Chat session start |
| Tracker mirror write | Only if pack-self opts into tracker mode (today: no; pack signals at `PACK-CHAT.md:110-129` show pack stays in flat-file by recommendation) | Whichever mode the client picked at init |

Mechanism is identical; the absolute frequency differs. Same code
path, different load profile. **No design implication** — the helper
doesn't care about cadence; idempotency means more frequent calls
are equivalent in output to fewer calls.

### 4.4 Custom merge driver — same

The gitattributes merge driver for `_toc.md` files (parent §6.4(a) —
"either timestamp, pick latest") applies to both targets. The
`.gitattributes` entry sits in the directory hosting the stream:

- Pack-self: `<root>/backlog/.gitattributes` (or top-level
  `.gitattributes` with `backlog/_toc.md` rule).
- Client: `docs/project/backlog/.gitattributes` (or top-level).

Same merge driver definition; configured once in the pack template,
ships into both contexts.

---

## 5. Trinity edits per surface

Pack-root trinity = `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` at pack
repo root. Client trinity = `project-template/CLAUDE.md`,
`project-template/AGENTS.md`, `project-template/GEMINI.md`.

Parent §15.1 says: "Symmetric edits required in all six files."
That's the default rule. This section decides **per file** whether
the edit is parallel-identical, parallel-but-different, or one-side-only.

### 5.1 The text changes parent §15.1 enumerates

Parent §15.1 lists three text changes:

(a) `## Document locations` table — replace `BACKLOG.md /
STATUS.md / CHANGELOG.md / IMPLEMENTATION-PLAN.md` references with
directory equivalents.

(b) `## Project memory` section — file refs become directory refs.

(c) Add one-line pointer: "Document streams use per-entry files;
see `<stream>/_rules.md` for each stream's contract."

### 5.2 Per-file decisions

| File | Change (a) Document locations | Change (b) Project memory | Change (c) per-entry pointer |
|---|---|---|---|
| `project-template/CLAUDE.md` | YES — `:221-225` table edit per parent §15.1 (all 4 streams) | YES | YES |
| `project-template/AGENTS.md` | YES — parallel edit (trinity rule) | YES | YES |
| `project-template/GEMINI.md` | YES — parallel edit (trinity rule) | YES | YES |
| `CLAUDE.md` (pack root) | **DIFFERENT EDIT** — pack-root has no "Document locations" table; instead at `:22-32` it lists "Key files to read before working on the pack" with `BACKLOG.md` / `CHANGELOG.md` entries. Those references update to `backlog/` and `changelog/` directories. STATUS and IMPL-PLAN do **not** appear because pack-self does not grow those streams (§1.4). | YES — `:55-65` commit-message rules and `:83-85` PM-only files block both reference `BACKLOG.md`; update to `backlog/`. CHANGELOG.md becomes `changelog/`. | YES — one-line pointer added |
| `AGENTS.md` (pack root) | DIFFERENT EDIT, parallel structure — pack-root AGENTS.md `:24-25` mirrors CLAUDE.md `:30-31` per session verification | YES (parallel) | YES (parallel) |
| `GEMINI.md` (pack root) | DIFFERENT EDIT, parallel structure | YES (parallel) | YES (parallel) |

### 5.3 Why pack-root trinity uses a different edit shape

Per the session-verified comparison:

- `CLAUDE.md` (pack root) §22-32 lists 4 key files: `README.md` /
  `BACKLOG.md` / `CHANGELOG.md` / `PACK-CHAT.md` / `PACK-AGENTS.md`.
  This is NOT the same as the project-template's "Document locations"
  table at `project-template/CLAUDE.md:208-225` which is a 3-row
  directory table.
- The pack-root trinity governs pack-development chats (Pack Chat +
  pack agents); the project-template trinity governs project-development
  chats (PM Chat + project agents). Different audience, different
  layout.

So change (a) is not a single edit replicated to six files. It's
two parallel edits:
- Project-template trinity: edit the `docs/project/` row of the
  Document locations table.
- Pack-root trinity: edit the key-files list at the top of CLAUDE.md
  / AGENTS.md / GEMINI.md.

Changes (b) and (c) replicate symmetrically across all six files;
change (a) is target-shape-specific.

### 5.4 Rules unique to the pack-root trinity, not the project-template

Three rules apply pack-root only:

- "Trinity rule" itself (`CLAUDE.md:68-79`). This describes how to
  edit CLAUDE.md/AGENTS.md/GEMINI.md and is pack-meta. The
  project-template's CLAUDE.md carries its own trinity rule at
  `project-template/CLAUDE.md` (own block, project-scoped). No edit
  needed for per-entry shape — the trinity rule itself is unchanged.
- "BD-NNN numbering" rule (`CLAUDE.md:60-62`): "Read BACKLOG.md, find
  the highest existing BD-NNN, increment by 1." This becomes "Read
  `backlog/_toc.md` last row" per parent §8.2. Pack-root only;
  project-template's equivalent (TD-NNN numbering) gets the parallel
  edit on the client side.
- "What agents may modify" / "What agents must never modify"
  (`CLAUDE.md:64-87`): references to `BACKLOG.md` / `CHANGELOG.md` /
  `README.md` become directory references. This is pack-root-only
  prose; project-template carries its own equivalent block at
  `project-template/CLAUDE.md` (the PM-only files list, parallel
  shape).

### 5.5 Symmetry verdict

The six trinity files do **not** receive byte-identical edits, but
they receive parallel-shape edits per the trinity rule. The
asymmetry is justified by the prior asymmetry in the layouts (pack-root
key-files vs. project-template Document locations table). No new
trinity exemption is required; the existing rule "asymmetry requires
justification" (`CLAUDE.md:68-79`) is satisfied by the structural
difference between key-file list and directory table.

---

## 6. Validator extension surface per target

Parent §15.5 introduces Check 31 (per-entry shape compliance) and
Check 32 (phase-completion invariant, soft warn), plus extends
Check 29 (tracker-config schema).

`scripts/validate-pack.py` runs from the pack repo root and audits
both pack-self files and the `project-template/` subtree (parent §1
cites this — Check 24 is the existing template-mirroring pattern).

### 6.1 Which path sets each check fires against

| Check | Fires against pack-self paths | Fires against project-template paths |
|---|---|---|
| **Check 31** core (filename regex, sentinel, TOC sync) | YES — `backlog/`, `changelog/` only (pack-self has 2 streams per §1) | YES — `project-template/docs/project/{backlog,implementation-plan,status,changelog}/` (all 4 streams; even seed empty directories) |
| **Check 31** byte-identity rules-file assertion | YES — asserts `backlog/_rules.md` byte-identical to `project-template/docs/project/backlog/_rules.md`; same for `changelog/_rules.md`. Two assertions in v11.1. | (asserted from the pack-self side; not a separate template assertion) |
| **Check 32** phase-completion invariant (soft warn) | NO — pack-self has no `implementation-plan/` stream | YES — `project-template/docs/project/implementation-plan/` checked when phase files exist (typically empty in seed state) |
| **Check 29** extension (`[mode].entry_shape` flag) | YES — pack-self's `tracker.toml.pack-example` carries the new flag | YES — `project-template/tracker.toml.project-example` carries the new flag |

### 6.2 Asymmetry origin

The asymmetry — Check 31 only fires `backlog/` + `changelog/` on
pack-self, but all 4 streams on project-template — is a direct
consequence of §1.4's roster decision. The check's logic:

```
for stream_dir in <pack-self stream dirs that exist>:
    enforce_check_31(stream_dir)
for stream_dir in <project-template stream dirs>:
    enforce_check_31(stream_dir)
```

Pack-self has 2 entries in the first loop; template has 4 in the
second. Same check, different input set per target. No special-case
branching needed in `validate-pack.py` — directory existence drives
iteration.

### 6.3 Seed-empty handling

Project-template's `implementation-plan/`, `status/` directories
ship as **bootstrapped seeds** per parent §4.3: the seed `_toc.md`
contains zero entries; no `phase-NN.md` / `YYYY-MM-DD.md` files exist
in the template. Check 31 against an empty stream directory verifies:

- `_rules.md` present + sentinel valid.
- `_toc.md` present + table has header rows + zero data rows.
- No stray entry files matching the regex.

This is well-defined; the check just iterates zero times over the
entry-file list.

### 6.4 New checks introduced by this differentiation

None. The parent's Check 31 / Check 32 / Check 29 extension fully
cover both targets when extended with directory-existence iteration.
The differentiation is implementation detail of the existing checks,
not new checks.

---

## 7. Agent-population implications

### 7.1 Pack-side roster

Per `PACK-AGENTS.md:13-19`, five pack agents live at
`.claude/agents/pack-*.md` plus `.codex/agents/` + `.gemini/agents/`:

- `pack-architect`, `pack-planner`, `pack-coder`, `pack-reviewer`,
  `pack-docs-researcher`.

Loaded skills (per `PACK-AGENTS.md:27-35`):
- `planning`, `architecture-review`, `documentation`, `review`,
  `dependency-intake`, `implementation-report`, `verification-harness`,
  `commit-discipline`, plus `pack-help`, `pack-startup` from
  `.claude/skills/` per `ls .claude/skills/`.

### 7.2 Client-side roster

Per `ls project-template/.claude/agents/`, the client-side roster
includes 15 agents: `architect.md`, `auditor*.md` (8 auditors),
`coder.md`, `docs-researcher.md`, `grpc-schema.md`, `planner.md`,
`repo-ops.md`, `reviewer.md`, `tester.md`.

Loaded skills: project-template ships 32 skills under
`project-template/skills/` (Tier 0 Apple/Python platform, Tier 1
language, Tier 2 patterns, plus methodology + planning skills) per
`ls project-template/skills/`.

Rosters are disjoint by namespace prefix: pack-* vs unprefixed.

### 7.3 Agents that need to know about per-entry shape

Three categories of agent need awareness:

(1) **Agents that read or grep streams.** These need the new
read-path semantics from parent §8.

Pack-side: All five pack agents may read `backlog/` / `changelog/`.
But per `PACK-AGENTS.md:102-105`, BD writes go to Pack Chat only;
reads are widespread. Each pack-* agent's prompt (`.claude/agents/
pack-*.md` + Codex/Gemini parallels) needs the parent §8.3 access-pattern
update.

Client-side: The 15 client agents that read BACKLOG today. Per
`grep -l BACKLOG.md project-template/.claude/agents/`, the touched
files are `repo-ops.md` and `coder.md`. The other 13 don't reference
the streams.

(2) **Agents that write streams.** Per pack-memory rules, only
Pack Chat / PM Chat may write streams; agents never do. So
write-path changes apply to chat-level skills (`pack-startup`,
`pm-startup`), not to agents directly.

(3) **Agents that lint or validate streams.** None of the pack
agents validate the stream shape directly; validation lives in
`scripts/validate-pack.py` (Check 31). So agent-side changes are
read-path only.

### 7.4 Skills that change on each side

Skill changes per parent §15.3:

| Skill | Pack-side change | Client-side change |
|---|---|---|
| `pack-help` (pack-side, `.claude/skills/pack-help/`) | Add row for `scripts/decompose-monolithic.sh` per parent §15.4 | N/A (skill is pack-side only) |
| `pack-startup` (pack-side, `.claude/skills/pack-startup/SKILL.md`, 108 lines) | Add Step-4-adjacent TOC reconcile per parent §15.3 | (parallel edit in client `pm-startup`) |
| `pm-startup` (client-side, `project-template/skills/pm-startup/SKILL.md`, 253 lines) | (parallel edit shipped from template) | Add Step-4-adjacent TOC reconcile per parent §15.3 |
| `commit-discipline` (both sides, byte-identical per maintainability principle) | Reference `backlog/`, `changelog/` directories in pre-flight check | Same edit (byte-identical mirror) |
| `documentation` (both sides) | Reference per-entry rules for stream writes | Same edit |
| Project-side agent prompts (15 files × 3 CLIs = 45) | N/A | 2 files (`repo-ops.md`, `coder.md`) × 3 CLIs = 6 files get BACKLOG → `backlog/` text update |
| Pack-side agent prompts (5 files × 3 CLIs = 15) | 3 files (`pack-coder.md`, `pack-architect.md`, `pack-planner.md`) × 3 CLIs = 9 files get the same text update | N/A |

The pack-startup vs pm-startup pair is **structurally identical**
(both skills have a Step 4 reconciliation flow); the edit is the
same paragraph in both. This is the "skill mirror, byte-identical"
class of edit per the maintainability principle.

### 7.5 Trinity ownership of skill copies

Skills copied to `.claude/skills/`, `.codex/skills/`, `.gemini/skills/`
on both sides are sourced from `project-template/skills/` per
`PACK-AGENTS.md:23-24`. So a single edit to
`project-template/skills/pm-startup/SKILL.md` propagates to:

- The 3 client-template copies (via init-project.sh).
- The 3 pack-side copies (via the per-CLI skill-mirror mechanism —
  but pack-side has `pack-startup`, not `pm-startup`, so this is
  parallel-shape not byte-identical).

The pack-startup skill at `.claude/skills/pack-startup/SKILL.md`
(108 lines) is shorter than the project-template's `pm-startup`
(253 lines) because pack-self has fewer streams (§1) and no
auditor-* agents to enumerate. So **same change-class, different
authoring locus**: pack-startup edits land directly in
`.claude/skills/pack-startup/`, pm-startup edits land in
`project-template/skills/pm-startup/` and migrate from there.

---

## 8. Migration sequencing and risk

### 8.1 The brief's question (parent §19 Q1)

"Does v11.1 dog-food the change on the pack repo first and ship
client-side support as a fast-follow, or do both ship together?"

### 8.2 Recommended sequence: pack-self first, then client, single version

**Stage A (early in v11.1 batch).** Decompose pack-self's
`BACKLOG.md` and `CHANGELOG.md` to `backlog/` and `changelog/`.
Run `scripts/decompose-monolithic.sh` against the pack repo
itself. Ship the new `scripts/lib/per-entry-toc.sh` and validator
Check 31 in this stage. Pack-self lives on per-entry shape from
this point forward.

**Stage B (later in same v11.1 batch).** Add seed `_rules.md` +
`_toc.md` to `project-template/docs/project/{backlog,
implementation-plan,status,changelog}/`. Update trinity files
(both pack-root and template), per-CLI agent prompts (the 2
client-side agents touched), pm-startup skill, METHODOLOGY.md
text edits. Ship migrator stage for v11.0→v11.1 that decomposes
client `BACKLOG.md` etc.

**Stage C (same v11.1 batch).** Update tracker libs
(`scripts/lib/tracker-{mirror,migrate-forward,migrate-reverse}.sh`)
per parent §9. Extend BD-068 round-trip fixtures.

Single version, three sequenced stages within the batch. **Not** a
multi-version rollout.

### 8.3 Reasoning for "pack-self first" within the batch

1. **Dog-food asymmetry.** Pack-self is one maintainer's working
   tree. Decompose error mode at worst: the maintainer reverts a
   single commit, restores from `_MIGRATOR_BACKUP_DIR`, fixes the
   decomposer, retries. Cost = one Pack Chat session. Client
   decompose error mode: every client project running
   `init-project.sh --update` against the released pack version
   inherits the bug; recall is impossible without a v11.1.1 hot-fix
   pin. Cost = blast radius across N projects.
2. **The decomposer is the highest-risk new code.** It reads
   3,556-line BACKLOG.md, emits 140 files, deletes the original.
   Verification (parent §14.1) is "byte-equal round-trip via
   `recompose-monolithic.sh`." But verification covers expected
   inputs; unexpected `BACKLOG.md` content shapes are tested first
   on pack-self where the maintainer has direct visibility.
3. **CI catches client-side regressions early.** Once pack-self is
   on per-entry shape, the `Validate Pack` workflow
   (`CLAUDE.md:90-94`) runs Check 31 against pack-self every push.
   Two weeks of pack-self churn-on-per-entry surfaces edge cases
   (sentinel drift, TOC merge conflict, weird whitespace in a BD)
   before client projects encounter them.
4. **Pack-self's BACKLOG is bigger than typical client BACKLOG.**
   140 entries pack-self vs 10-200 client (parent §19 Q1 estimate).
   So pack-self is also the **stress test** — if it works on 140,
   it works on smaller cases.

### 8.4 Gating signal: when Stage B unlocks

**Hard gates** (must pass before Stage B work begins):

(a) Decomposer ran successfully against pack-self BACKLOG.md +
CHANGELOG.md; both monolithic files are gone; 140 + ~12 per-entry
files exist; `_toc.md` rows total 140 / ~12 matching the
pre-decompose entry counts.

(b) `Validate Pack` workflow passes with the new Check 31 fired
against pack-self.

(c) Round-trip verifier (`scripts/decompose-monolithic.sh
--verify`) confirms recompose produces byte-equal monolithic
files modulo trailing whitespace.

(d) Pack Chat has used `backlog/BD-NNN.md` direct reads for at
least one batch's worth of BDs (informal "feels right" check
across read-path patterns from parent §8.2).

**Soft signals** (not blockers, but should be reviewed):

(e) The `_toc.md` merge-driver behavior under concurrent edits
has been observed once (intentionally simulated: two BD edits
land in two commits in quick succession with intervening TOC
rebuilds; verify no merge conflict).

(f) Sentinel-version mismatch test: temporarily edit a sentinel
to `v11.0`, confirm Check 31 fails with a clear error.

### 8.5 Risk asymmetry summary

| Risk dimension | Pack-self | Client |
|---|---|---|
| Blast radius if decomposer fails | 1 repo, maintainer-visible | N client repos, downstream invisibility |
| Recovery cost | One Pack Chat revert | Hot-fix release pin |
| Test surface | 140 BDs, 1 changelog history | 10-200 BDs, 1 changelog history, plus 0-K status/phase entries |
| Detect-to-fix loop | Same-session (Pack Chat sees it) | Hours-to-days (user reports it) |
| Reversion freedom | High — pack-memory rules permit revert | Low — clients may have already done downstream work |

Risk asymmetry is large; the "pack-self first within same batch"
ordering exploits it.

---

## 9. BD ownership per side

Parent §17.3 enumerates BD-X1..BD-X12 (placeholder IDs for the
v11.1 batch). This section maps each to {pack-self only, client
only, both, infrastructure}.

"Infrastructure" = cross-cutting code (validator, library helpers,
migrator framework) that serves both targets without being
target-specific.

| Parent BD-X | Description (parent §17.3) | Mapping | Reasoning |
|---|---|---|---|
| BD-X1 | `_rules.md` + `_toc.md` design + seed templates per stream | **Both** (seed lives in template; pack-self uses byte-identical via §3.4 symlink/copy) | Single source of truth in template; pack-self consumes via copy |
| BD-X2 | `scripts/lib/per-entry-toc.sh` helper + tests | **Infrastructure** | Pure code; both targets call it; no target-specific behavior |
| BD-X3 | Trinity + PM-CHAT.md edits for new Document locations | **Both** (asymmetric per §5.2 — six files, two parallel edits) | Pack-root trinity + project-template trinity both touched, different shape |
| BD-X4 | `scripts/lib/tracker-mirror.sh` directory-walker extension + tests | **Infrastructure** (with client emphasis) | Pack-self today does not run tracker mode; client-side is the dominant user; but code is target-agnostic |
| BD-X5 | `scripts/lib/tracker-migrate-forward.sh` per-entry refactor + extended round-trip fixtures | **Infrastructure** (with client emphasis) | Same rationale as X4 |
| BD-X6 | `scripts/lib/tracker-migrate-reverse.sh` per-entry refactor + sidecar adjustments | **Infrastructure** (with client emphasis) | Same rationale |
| BD-X7 | `scripts/decompose-monolithic.sh` migrator stage on BD-119 framework + tests | **Infrastructure** | The decomposer runs on either target; "migrate v11.0 → v11.1" is a v11.0-pack-version-aware stage |
| BD-X8 | `scripts/validate-pack.py` Check 31 + Check 32 + Check 29 extension | **Infrastructure** | Validator runs against both target path sets per §6.1 |
| BD-X9 | `HELP-FRAGMENT-PACK.md` + per-CLI skill updates | **Both** (HELP-FRAGMENT-PACK is pack-self; client copy is `HELP-FRAGMENT.md`; skill updates touch pm-startup template + pack-startup pack-side per §7.4) | Two artifacts in parallel |
| BD-X10 | `supporting-docs/MIGRATION-v11.0-to-v11.1.md` + dry-run + rollback docs | **Both** (the migration guide describes both pack-self decompose and client decompose) | The doc is single but covers both targets' migration paths |
| BD-X11 | `scripts/lib/per-entry-bulk.sh` for batch status flips | **Infrastructure** | Pack-self uses it for batch BD resolution per `CLAUDE.md` pack memory "Implicit BD status flip on batch completion"; clients could use it similarly |
| BD-X12 | Pack-repo decompose (pack's own BACKLOG.md + CHANGELOG.md) + commit-discipline cross-link | **Pack-self only** | This is the dog-food execution against pack-self per §8.2 Stage A |

### 9.1 Pack-self-only BDs (Stage A)

BD-X12 only. Single BD that is genuinely pack-self-only — the
execution of the decompose against the pack repo's own monolithic
files.

### 9.2 Client-only BDs

None. Every infrastructure or template change automatically applies
to clients via the standard pack-update mechanism. There is no
client-specific code path that needs its own BD.

### 9.3 Both-target BDs (asymmetric edits)

BD-X1, BD-X3, BD-X9, BD-X10. These touch artifacts on both sides
that differ in shape (rules-file vs template seed, pack-root trinity
vs template trinity, HELP-FRAGMENT-PACK vs HELP-FRAGMENT, pack-startup
skill vs pm-startup skill).

### 9.4 Infrastructure BDs

BD-X2, BD-X4, BD-X5, BD-X6, BD-X7, BD-X8, BD-X11. Code-only or
validator-only changes; target-agnostic.

### 9.5 Counts and shape

- Pack-self-only: 1 (BD-X12)
- Both-target asymmetric: 4 (BD-X1, X3, X9, X10)
- Infrastructure: 7 (BD-X2, X4, X5, X6, X7, X8, X11)
- Client-only: 0
- Total: 12 BDs (matching parent §17.3 count)

The mapping is decision-ready for pack-planner BD assignment.

---

## 10. Dog-food role for pack-self

### 10.1 What "dog-food passes" looks like

The BD-102 pattern (pack-repo dog-food before client release pin)
sets the precedent: a pack-side change ships into the pack repo
itself first, the maintainer uses it during the pack's own
development for some interval, observed signals tell the maintainer
"the change works on real maintenance traffic," and only then is
the change released for client consumption.

For per-entry shape, dog-food passes when **all** of these hold:

(a) **Stage A landed at least one batch ago.** Pack-self's
`backlog/` directory has been the live source of BACKLOG truth for
at least one complete batch of pack development (architect / planner
/ coder / reviewer cycle on one BD or batch of BDs, end to end).
This is roughly 2-5 working days of activity.

(b) **`/pack-startup` runs clean.** The Step-4-adjacent TOC
reconcile reports zero orphan rows and zero missing-in-index rows
across at least three startup runs. (Per `pack-startup/SKILL.md`,
startup runs at session boundaries; three runs ≈ three Pack Chat
sessions.)

(c) **No `_toc.md` merge conflicts have escaped the merge driver.**
The custom driver (parent §6.4(a) `.gitattributes`) resolves
timestamp drift; no file content disagreement should ever land at
HEAD. Verify via `git log -p backlog/_toc.md` — no manual conflict
markers in any commit body.

(d) **CI green on every push.** `Validate Pack` workflow with
Check 31 active passes on every push since Stage A. One failure is
acceptable if it surfaces a real bug fixed in the same batch; two
or more failures indicate the design is unstable and Stage B should
not unlock.

(e) **Bulk-flip helper used at least once.** When the v11.1 batch
itself completes and flips its own constituent BDs to Resolved per
the pack-memory "implicit status flip on batch completion" rule,
`per_entry_bulk_status_flip` (BD-X11) handles the flips. The
helper's first real use is on the BDs that introduced it — recursive
but observable.

(f) **Token-cost reduction observed.** Compare a "what's open in
v11.1?" lookup before and after — informally measured by Pack Chat
turn-token cost. Per parent §16.3, the projection is ~13× for the
list-open pattern and ~90× for single-BD lookup. If actual reduction
is in the 5-50× range across observed patterns, the design's
performance claim is validated.

### 10.2 The gating signal that unlocks client rollout

The simplest expressible gate is **(a) AND (d)**: one batch of
dog-food activity + clean CI history through it. The other signals
(b, c, e, f) are observation-and-confidence boosters but not
strict gates.

In the proposed Stage A → Stage B sequencing within v11.1 (§8.2):
- Stage A landed in the first or second commit of the batch.
- Stages B and C land in the same batch, after dog-food
  observation across the architect/planner/coder/reviewer cycles
  for the batch's own BDs.

So dog-food happens **during** the batch, not as a separate
release. The gate is "Stage B doesn't commit until Stage A's
in-batch dog-food signals (a, d) are green." Pack Chat enforces
this via the commit sequencing in pack-planner's batch plan.

### 10.3 BD-102 pattern cross-link

BD-102 is the pattern reference for "pack dog-foods before client
release." Per `BACKLOG.md` (search for BD-102), this established
the dog-food principle. The current proposal extends it: per-entry
shape decompose is the next case of "structural change dog-foods
on pack-self before client install."

If the pack-planner authors a BD for the per-entry-shape work, it
should cross-link `Blockers:` or `See:` references to BD-102 as the
methodological precedent. (Implementation detail for pack-planner;
not authored here.)

---

## 11. What can fail differently on each side

### 11.1 Concurrent-edit risk profile

**Pack-self.** One maintainer chat at a time (operationally:
typically a single Pack Chat session per workstation per branch).
The "two agents editing the same BD file" case is rare and
naturally serialized. Concurrent-edit risk is low.

**Client.** Multi-developer team scenario. Two developers may both
have local Pack/PM Chat sessions editing different BDs in parallel,
producing two commits that touch different `BD-NNN.md` files and
each rewriting `_toc.md`. The merge driver (parent §6.4(a))
resolves automatically.

**Asymmetry:** the merge-driver mechanism is *more critical* on the
client side. Pack-self could nominally function with naive
TOC-write-wins-latest; client cannot. This is captured in parent
§6.4 but worth flagging here.

### 11.2 Mirror-state-drift risk

**Pack-self.** Pack-self today is in flat-file mode (no
`tracker.toml` enabled per `PACK-CHAT.md:110-129` recommendation
flow defaulting to opt-out for the pack repo). So mirror drift —
the case where local edits and tracker state diverge — does not
apply on pack-self. (Could apply if pack-self opts in to tracker
mode for itself; that's an opt-in decision separate from per-entry
shape.)

**Client.** A client project that opted into tracker mode at v11.0
runs with `backlog/BD-NNN.md` as read-only mirrors. The risk of
"developer hand-edits a mirror file thinking it's source of truth"
is real and is addressed by the per-file mirror header (parent
§9.1).

**Asymmetry:** the mirror-header mechanism (parent §9.1) is
pack-product feature that benefits clients; pack-self does not
exercise it.

### 11.3 Sentinel-version drift risk

**Pack-self.** Sentinel version matches the working tree's pack
version directly — they're the same thing, since pack-self *is*
the working tree of the pack at its current version. Drift is
near-impossible.

**Client.** Sentinel version names the pack version that last
updated the file. A client project may be running an older pack
version locally while a newer pack is published. The sentinel
catches this: Check 31's sentinel-version validation surfaces the
mismatch and the client knows to run `pack init --update`.

**Asymmetry:** sentinel-version is a *client-protection* mechanism;
it provides no value pack-self-side (where the working tree's pack
version is by definition current).

### 11.4 Decomposer-mid-flight risk

**Pack-self.** If the decomposer crashes mid-run on pack-self,
recovery is direct: the maintainer reads `_MIGRATOR_BACKUP_DIR`,
restores manually, re-runs. Skill / experience is high.

**Client.** If the decomposer crashes mid-run on a client, the
client developer must follow the migration guide
(`supporting-docs/MIGRATION-v11.0-to-v11.1.md`, BD-X10). Lower
context, higher cost of error.

**Asymmetry:** the rollback documentation (BD-X10) is **client-
facing**; pack-self gets by with maintainer knowledge.

### 11.5 BD-numbering collision risk

**Pack-self.** Per `CLAUDE.md:60-62`: "Read BACKLOG.md, find the
highest existing BD-NNN, increment by 1." With per-entry shape,
this becomes "Read `backlog/_toc.md` last row." Single-maintainer
serial workflow makes collision impossible.

**Client.** Multi-developer scenario could have two developers
simultaneously each picking BD-N+1 against an out-of-date local
`_toc.md`. The risk profile is identical to the BACKLOG.md-shaped
problem today (two developers picking the same next BD number).
Mitigation: the project rule "Pack Chat assigns BDs; developers
propose, Pack Chat numbers" is unchanged. Not new with per-entry
shape.

**Asymmetry:** none structurally. Same risk on both sides; same
mitigation. Mentioned here because the parent doc doesn't address
it and the reader might wonder.

### 11.6 Status-flip propagation lag

**Pack-self.** Pack memory rule "Implicit BD status flip on batch
completion" (`CLAUDE.md:117-120`) means Pack Chat flips BDs to
Resolved at batch end. Operationally fast; same session.

**Client.** No equivalent implicit-flip rule. PM Chat flips
Resolved on commit-of-record. Lag is "developer remembers" vs
"agent rule fires." More variance on client side.

**Asymmetry:** the bulk-flip helper (BD-X11, parent §13.4) has
**different ergonomic value** on each side. Pack-self uses it
heavily (multiple BDs per batch); client may use it rarely (one
BD per PR is typical). Tooling cost is the same; usage cadence
differs.

### 11.7 The `_rules.md` immutability violation

**Pack-self.** A pack maintainer could in principle edit
`_rules.md` (sentinel + Check 31 + skill rule + chat rule all
guard against it). If the maintainer overrides all four guards,
they own the consequence directly.

**Client.** A client developer or rogue agent might edit
`_rules.md`. The customization-preserve report (parent §5.3,
BD-088 pattern) flags it on next pack update; the pack overwrites
the client edit per `pack_wins` disposition.

**Asymmetry:** the customization-preserve report is a
client-protection mechanism. Pack-self has no equivalent — the
maintainer is expected to follow their own rules.

### 11.8 Summary: where the asymmetries cluster

Most of the asymmetries cluster around "client needs explicit
protection mechanisms (sentinel-version validation, mirror header,
customization-preserve report, rollback docs) that pack-self gets
implicitly via the maintainer's direct context." This is structural,
not a defect — the pack-product surface is designed to protect
clients from failure modes that don't realistically arise on the
maintainer's own working tree.

The design implications:

1. Pack-self does not need to test every protection mechanism on
   itself, because pack-self is also the surface that *produces*
   those mechanisms. But Check 31's pack-self coverage (per §6.1)
   ensures the shape-compliance mechanism is exercised on pack-self
   too.
2. Stage A's dog-food signals (§10.1) are different from Stage B's
   release-readiness signals. Stage A passes on "pack-self uses it
   well"; Stage B (client release) requires the protection
   mechanisms to actually fire on client test fixtures.

---

## 12. Common-vs-unique summary table

Two columns: pack-self, client. Rows organized by design dimension.
Reader uses this to grep one column for everything a pack-side BD
touches, or the other for everything a client-side BD touches.

| Design dimension | Pack-self | Client |
|---|---|---|
| **Stream roster** | 2 streams: `backlog/`, `changelog/` | 4 streams: `backlog/`, `implementation-plan/`, `status/`, `changelog/` |
| **Stream location** | Pack repo root: `backlog/`, `changelog/` | `docs/project/<stream>/` per `project-template/CLAUDE.md:221-225` |
| **STATUS stream** | Absent (deliberately — uses git commits + CHANGELOG) | Present, `docs/project/status/YYYY-MM-DD.md` |
| **IMPLEMENTATION-PLAN stream** | Absent at root (v11-research carve-out per §2) | Present, `docs/project/implementation-plan/phase-NN.md` |
| **v11-research carve-out** | `maintenance-docs/v11-research/` for pack-development plan-class docs | N/A (no equivalent on client side) |
| **`_rules.md` content** | Byte-identical to template's (§3) via symlink/copy from `project-template/docs/project/<stream>/_rules.md` | Authoritative template at `project-template/docs/project/<stream>/_rules.md`; copied to project tree on init/update |
| **`_rules.md` immutability mechanism** | Sentinel + Check 31 + skill rule + Pack Chat rule (§5.4, §11.7) | Same four guards + customization-preserve `pack_wins` disposition |
| **`_toc.md` format** | Identical (parent §6.1 schemas by stream) | Identical |
| **`_toc.md` rebuild trigger cadence** | High (multiple times/day during active development per §4.3) | Lower (per PR batch, per phase boundary) |
| **`_toc.md` merge driver** | Same `.gitattributes` driver; rarely fires (single maintainer chat per §11.1) | Same driver; fires more often (multi-developer team) |
| **Trinity files** | Pack-root `CLAUDE.md` / `AGENTS.md` / `GEMINI.md`; key-files list shape | `project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md`; Document locations table shape |
| **Trinity edit for per-entry shape** | Key-files list at `:24-32` (CLAUDE) / parallel in AGENTS/GEMINI: `BACKLOG.md` → `backlog/`, `CHANGELOG.md` → `changelog/` | Document locations table at `:221-225` (CLAUDE) / parallel: all 4 stream rows update to directory refs |
| **Trinity-replicated rules touched** | "BD-NNN numbering" rule, "What agents may modify", "What agents must never modify" | "PM-only files" list, equivalent agent-modify rules |
| **PM-chat operating file** | `PACK-CHAT.md` (199 lines) | `project-template/docs/pack/PM-CHAT.md` (651 lines) |
| **PM-chat file-access table** | `PACK-CHAT.md:42-46` (5 rows: BACKLOG, CHANGELOG, README, METHODOLOGY, prompts) | `PM-CHAT.md:117-131` (15+ rows including all 4 streams) |
| **Agent roster** | 5 agents: `pack-architect`, `pack-planner`, `pack-coder`, `pack-reviewer`, `pack-docs-researcher` | 15 agents: `architect`, `planner`, `coder`, `reviewer`, `tester`, `repo-ops`, `docs-researcher`, `grpc-schema`, `auditor*` (8 of them) |
| **Agent files touched by per-entry shape** | 3 of 5 (`pack-coder.md`, `pack-architect.md`, `pack-planner.md`) × 3 CLIs = 9 files | 2 of 15 (`coder.md`, `repo-ops.md`) × 3 CLIs = 6 files |
| **Startup skill** | `pack-startup` (`.claude/skills/pack-startup/SKILL.md`, 108 lines) | `pm-startup` (`project-template/skills/pm-startup/SKILL.md`, 253 lines) |
| **Startup skill edit** | Step-4-adjacent TOC reconcile insertion | Parallel insertion in pm-startup template (ships from template) |
| **Skill catalog scope** | ~10 skills in `.claude/skills/` (pack-help, pack-startup, planning, architecture-review, etc.) | ~32 skills in `project-template/skills/` (Tier 0 Apple/Python platform, Tier 1 language, Tier 2 patterns) |
| **Validator: Check 31 firing scope** | `backlog/`, `changelog/` (2 streams) | `project-template/docs/project/{backlog,implementation-plan,status,changelog}/` (4 streams) |
| **Validator: Check 32 (phase-completion) firing scope** | No (pack-self has no `implementation-plan/`) | Yes (template + projects on update) |
| **Validator: Check 31 byte-identity assertion** | Asserts `<stream>/_rules.md` byte-identical to template copy | (audited from pack-self side) |
| **Tracker integration risk** | Low — pack-self is flat-file by default (per `PACK-CHAT.md:110-129`) | Medium — tracker opt-in is the v11 client feature; per-entry mirror writes are hot path |
| **Mirror header on entries** | Not applied (no tracker mode) | Applied in tracker mode per parent §9.1 |
| **Sentinel-version validation purpose** | Defensive — drift near-impossible since pack-self IS the working tree | Protective — catches stale client copies after pack-update |
| **Decomposer execution** | Stage A (early in v11.1 batch); dog-food before client release | Stage B (later in same batch, gated on Stage A signals per §8.4) |
| **Decomposer error blast radius** | 1 maintainer; same-session recovery | N client repos; hot-fix release pin needed |
| **Migration guide audience** | Maintainer (uses pack-memory knowledge directly) | Client developer (consumes `supporting-docs/MIGRATION-v11.0-to-v11.1.md` and `docs/pack/INSTALL-PROCEDURES.md`) |
| **Customization-preserve report relevance** | N/A (pack-self IS the source) | Active — catches client-side `_rules.md` edits per `pack_wins` disposition (parent §5.3) |
| **BD-numbering source-of-truth** | `backlog/_toc.md` last row (replaces "highest BD in BACKLOG.md") | `docs/project/backlog/_toc.md` last row (TD-NNN for client) |
| **Bulk-flip helper usage** | Heavy (implicit batch-completion status flips per `CLAUDE.md:117-120`) | Light (per-PR cadence) |
| **HELP-FRAGMENT** | `HELP-FRAGMENT-PACK.md` (pack-side verbs) + `HELP-FRAGMENT-TRACKER.md` (byte-identical canonical) | `project-template/docs/pack/HELP-FRAGMENT.md` + `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` (byte-identical mirror) |
| **Concurrent-edit risk** | Low (single maintainer chat) | Higher (multi-developer team) |
| **Workflow artifact location** | `maintenance-docs/v11-implementation/`, `maintenance-docs/v11-research/`, `maintenance-docs/archive/vN/` after Pattern B sweep | (no equivalent — review/audit/architect outputs are session-ephemeral) |
| **Owns the trinity rule itself** | Pack-root `CLAUDE.md:68-79` "Trinity rule" block; this file authoritative | Project-template `CLAUDE.md` trinity rule mirror; client-scoped scope |
| **Owns the "Pack agents never commit" rule** | `CLAUDE.md:96-101` pack-memory entry | (project-template has its own equivalent for project agents) |
| **Owns the maintainability principle** | `CLAUDE.md:171-184` Pack memory § Repo conventions | `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` referenced from both sides |
| **TODO(version) BD type usage** | Active today (BD-151..BD-155 per BACKLOG tail) | Potential — same Type enum applies but client typically uses Open/Resolved |

### 12.1 Grep-friendliness

Each row is one-line summary or short table cell, optimized for
`grep "pack-self" §12 | <process>` and the parallel for client. The
table has 38 rows covering the design surface.

---

## 13. BD-mapping table for parent §17.3 BD-X1..BD-X12

Decision-ready map for pack-planner. Each parent BD-X mapped to one
of {pack-self only, client only, both, infrastructure}. Reasoning
column ties each mapping to the differentiation point.

| Parent BD-X | Description (short) | Target | Reasoning (cross-references this doc + parent) |
|---|---|---|---|
| **BD-X1** | `_rules.md` + `_toc.md` design + seed templates per stream | **Both** | §3.2: byte-identical rules-file ships from `project-template/docs/project/<stream>/_rules.md` into both pack-self (via symlink/copy) and client (via init). Single authoring locus; consumed by both targets. Asymmetric edit: pack-self gets 2 streams; client gets 4. |
| **BD-X2** | `scripts/lib/per-entry-toc.sh` helper + tests | **Infrastructure** | §4.1: helper is target-agnostic; takes a directory path; no target-specific branching. Both pack-self and client call it. |
| **BD-X3** | Trinity + PM-CHAT.md edits for new Document locations | **Both** (asymmetric) | §5.2: six trinity files touched, two parallel edit shapes (pack-root key-files list vs project-template Document locations table). Plus PACK-CHAT.md (pack-self) and PM-CHAT.md (client-template) — two separate authoring loci. |
| **BD-X4** | `scripts/lib/tracker-mirror.sh` directory-walker extension + tests | **Infrastructure** | Parent §9.1: pure code change in pack scripts; runs against either pack-self (if pack opts in to tracker) or client tree. Pack-self today is flat-file (§11.2) so dominant user is client; but code is target-agnostic. |
| **BD-X5** | `scripts/lib/tracker-migrate-forward.sh` per-entry refactor + extended round-trip fixtures | **Infrastructure** | Parent §9.1 + §9.2: same rationale as X4. BD-068 fixture extension is test infrastructure — runs in CI which runs from pack-self but tests the migration both ways. |
| **BD-X6** | `scripts/lib/tracker-migrate-reverse.sh` per-entry refactor + sidecar adjustments | **Infrastructure** | Parent §9.1: same rationale. |
| **BD-X7** | `scripts/decompose-monolithic.sh` migrator stage on BD-119 framework + tests | **Infrastructure** | Parent §14.1, §14.5: stage runs on whatever monolithic-source tree is present (pack-self in Stage A, client in Stage B per §8.2). BD-119 framework is target-agnostic. |
| **BD-X8** | `scripts/validate-pack.py` Check 31 + Check 32 + Check 29 extension | **Infrastructure** | §6.1: same validator runs against both target path sets; firing scope differs (Check 31 hits both; Check 32 hits template only) but the code is one set of checks driven by directory existence. |
| **BD-X9** | `HELP-FRAGMENT-PACK.md` + per-CLI skill updates | **Both** (asymmetric) | §7.4: pack-startup skill (pack-side) edits at `.claude/skills/pack-startup/SKILL.md`; pm-startup skill (client-side template) edits at `project-template/skills/pm-startup/SKILL.md`. Same change-class, different authoring locus. HELP-FRAGMENT-PACK.md is pack-self; client equivalent is `project-template/docs/pack/HELP-FRAGMENT.md`. |
| **BD-X10** | `supporting-docs/MIGRATION-v11.0-to-v11.1.md` + dry-run + rollback docs | **Both** (single doc covering both targets) | §11.4: pack-self maintainer doesn't need this doc operationally (knows the framework directly); doc is primarily a client-facing protection mechanism. But the doc lives at `supporting-docs/` which ships to clients via the standard mechanism, so it's authored once and serves both. |
| **BD-X11** | `scripts/lib/per-entry-bulk.sh` for batch status flips | **Infrastructure** | §11.6: usage cadence differs (pack-self heavy, client light) but the code is target-agnostic. Pack-side use case is implicit batch-flip per `CLAUDE.md:117-120`. |
| **BD-X12** | Pack-repo decompose (pack's own BACKLOG.md + CHANGELOG.md) + commit-discipline cross-link | **Pack-self only** | §8.2 Stage A: the actual execution of decompose against pack-self. This BD is the dog-food run. Distinct from BD-X7 which is the *framework*; BD-X12 is the *invocation* against this repo's working tree. |

### 13.1 Counts confirmed

- Pack-self only: 1 (BD-X12).
- Both-target asymmetric: 4 (BD-X1, X3, X9, X10).
- Infrastructure: 7 (BD-X2, X4, X5, X6, X7, X8, X11).
- Client-only: 0.
- Total: 12. Matches parent §17.3.

### 13.2 BD ordering recommendation (for pack-planner)

Within v11.1, a defensible sequence is:

1. **Infrastructure first** — BD-X2 (per-entry-toc.sh), BD-X8 (validator),
   BD-X1 (rules-file + seed templates). These build the substrate.
2. **Pack-self dog-food** — BD-X12 (pack-repo decompose). Stage A
   gate per §8.2.
3. **Client-ready** — BD-X3 (trinity), BD-X9 (HELP-FRAGMENT + skills),
   BD-X10 (migration guide). Stage B.
4. **Migrator-stage** — BD-X7 (decomposer-as-migrator-stage on BD-119
   framework). Necessary for client init-update.
5. **Tracker integration** — BD-X4, BD-X5, BD-X6 (mirror libs).
   Stage C.
6. **Optional** — BD-X11 (bulk-flip helper) if scope tight; deferrable
   to v11.2 per parent §19 Q4.

The architect's preference for sequencing is recorded; pack-planner
owns final batch shape.

---

## 14. Parent-doc deltas required

The architect identified the following parent-doc places where the
differentiation above implies a change or clarification. None are
silent revisions; they are listed here for pack-planner / Pack Chat
to fold into a parent-doc revision pass if and when they want
parent-doc canonicity.

### 14.1 Parent §4.3 — pack-self stream roster ambiguity

Parent §4.3 says "the pack repo has no `IMPLEMENTATION_PLAN.md` at
root today" and "The proposal does *not* relocate v11-research
artifacts." But it does NOT explicitly state that the pack-self
target carries only 2 of 4 streams. A reader might infer all 4
streams ship to pack-root.

**Proposed delta:** Add a sentence to §4.3: "Pack-self adopts only
the streams it currently has — `backlog/` (replacing `BACKLOG.md`)
and `changelog/` (replacing `CHANGELOG.md`). Pack-self does not
grow `status/` or `implementation-plan/` directories; the v11-research
carve-out remains the authoritative location for pack development
plan-class artifacts."

### 14.2 Parent §15.1 — trinity edit shape asymmetry

Parent §15.1 lists "Symmetric edits required in all six files" and
proposes specific text changes that map to the project-template's
Document locations table. But pack-root trinity has a different
shape (key-files list, not Document locations table) — the same
text change literal cannot apply.

**Proposed delta:** Reframe §15.1 as "Parallel-shape edits in all
six files" with two sub-sections: §15.1a pack-root trinity (edit
key-files list at `CLAUDE.md:24-32`), §15.1b project-template trinity
(edit Document locations table at `:221-225`). Acknowledge the
asymmetry is structural, not a trinity exemption.

### 14.3 Parent §15.5 — Check 31 firing scope per target

Parent §15.5 defines Check 31 but does not specify the per-target
firing scope. The differentiation in §6.1 of this doc fills that
gap.

**Proposed delta:** Add a paragraph to §15.5: "Check 31 iterates
over the stream directories present at each audited path: pack-self
root (2 streams: backlog, changelog) and project-template/docs/project/
(4 streams: backlog, implementation-plan, status, changelog).
Iteration is driven by directory existence; no target-specific
branching."

### 14.4 Parent §19 Q1 — answer recorded externally

Parent §19 Q1 is "Pack-side vs client-side rollout timing." This
doc's §8.2 answers it: "pack-self first within the same v11.1 batch,
gated on Stage A signals."

**Proposed delta:** Mark §19 Q1 as "Answered in
ARCHITECTURE-PER-ENTRY-PACK-VS-CLIENT.md §8.2." (Not a re-write of
§19 Q1; just a cross-reference.)

### 14.5 Parent §19 Q2 — answer recorded externally

Parent §19 Q2 is "Pack-side STATUS / IMPLEMENTATION-PLAN — does
pack-self grow these in v11.1?" This doc's §1.4 answers: "No.
Pack-self stays at 2 streams (backlog, changelog) in v11.1 and
beyond unless a future architect pass revisits the rule."

**Proposed delta:** Mark §19 Q2 as "Answered in
ARCHITECTURE-PER-ENTRY-PACK-VS-CLIENT.md §1.4."

### 14.6 Parent §17.3 — BD-X target mapping

Parent §17.3 enumerates BD-X1..BD-X12 but does not map each to
target. This doc's §9 and §13 fill that gap.

**Proposed delta:** Mark §17.3 as "Target mapping in
ARCHITECTURE-PER-ENTRY-PACK-VS-CLIENT.md §9 and §13."

### 14.7 No semantic regressions

None of these deltas change a parent-doc decision. They are
clarifications, cross-references, and one structural reframe
(§14.2 trinity edit shape). The locked shape (per-entry files +
immutable `_rules.md` + mutable `_toc.md`) is unchanged.

---

## 15. Decision-ready summary

For pack-planner consuming this doc:

- Pack-self stream roster in v11.1: `backlog/` + `changelog/` only
  (§1.4).
- v11-research carve-out: stays as-is (§2.2).
- `_rules.md`: byte-identical pack-self ↔ template via symlink/copy
  (§3.2).
- `_toc.md`: identical shape; cadence differs (§4).
- Trinity edits: 6 files, two parallel shapes (§5.2).
- Validator: Check 31 fires both, Check 32 client-only (§6).
- Skills + agents: edits target only the agents/skills that
  read streams (§7.4).
- Migration sequence: Stage A pack-self decompose, then Stage B
  client release, same v11.1 batch (§8.2).
- BD ownership: 1 pack-self-only, 4 both-target asymmetric, 7
  infrastructure, 0 client-only (§9.5, §13.1).
- Dog-food gates: Stage A clean batch + clean CI history before
  Stage B unlocks (§10.2).
- Failure-mode asymmetries: client gets protection mechanisms
  (sentinel-version, mirror header, customization-preserve report,
  migration guide); pack-self gets implicit protection via the
  maintainer's direct context (§11.8).
- Parent-doc deltas: six small clarifications in §14, no
  semantic regressions.

---

