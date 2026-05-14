---
title: REVIEW-ARCHITECTURE-PER-ENTRY-SPLIT
reviewer: primary-chat (v11-dev) — fresh pack-architect, no prior context on this work
target: maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-SPLIT.md (1,649 lines, dated 2026-05-13)
guard-rail spec: maintenance-docs/v11-implementation/REVIEW-RESEARCH-PER-ENTRY-SPLIT.md §5.4 + §5.5 (six guard rails) + REVIEW-RESEARCH-PER-ENTRY-SPLIT-ADDENDUM.md §5.2 (one new guard rail, total seven)
date: 2026-05-13
recommendation: APPROVE-WITH-MINOR-FOLLOWUPS (see §8)
---

# Review of ARCHITECTURE-PER-ENTRY-SPLIT.md

## §0 — TL;DR

The sidecar's architect produced a disciplined, well-cited design. The
central design decision (mirror-not-replace, §6.1) is sound and well
defended; it is the right call because it dissolves the "10+ read-shape
sites must be reworded" problem without sacrificing the per-entry
write surface the decomposition exists to provide. Six of the seven
prior-review guard rails are cleanly observed; one (signal 8 in the
maintainability principle, §13.4) is acknowledged as **conditionally
tripped** and left to the planner — that is the right boundary, not a
defect.

Two integration smoothness concerns rise above noise:

1. **§4.2 immutability mechanism for project-side `_rules.md` is
   under-specified.** The architect routes project-side `_rules.md`
   through customization-preserve's `generic` class and relies on the
   3-way merge plus the BD-088 truthful report to surface
   customizations. That works in principle, but `_rules.md` is the
   *contract* for the directory — a user-customized contract is a
   semantic conflict, not a text conflict, and the architect does not
   say what behavior is correct when `_rules.md` is locally edited
   (does the per-entry workflow refuse to load? warn? proceed?). This
   is a write-path semantics question the planner cannot answer
   without more guidance.

2. **§3.5 + §6.2 + §16.7 surface a `_format.md` design tension the
   architect should resolve, not defer.** Adding a third
   leading-underscore file in one stream only is justified, but the
   architect punts whether `_format.md` is ship-once or
   ship-every-migration to the planner (§16.7), while §3.5 implies
   it's pack-product (shipped from `project-template/`) and §4.2
   implies project-side `_rules.md` is also pack-product. If both
   files have the same shipping semantics, that should be stated
   once; if they differ, the architect needs to say why.

These do not block primary chat's own architect pass — they are surface
refinements the sidecar's architect can resolve via a short SendMessage
clarification or an addendum of ~100–200 lines.

**Architect-overreach scan: zero overreach found.** The architect held
discipline cleanly across all six §5.4 signals.

**Recommendation:** **APPROVE-WITH-MINOR-FOLLOWUPS.** Either path
(SendMessage clarifications or a short addendum) closes the gaps;
primary chat's own architect can then take a clean handoff.

---

## §1 — Design-quality assessment (per resolved open question)

### §1.1 — OQ-3 (mirror not replace) — RESOLVED, sound

The architect's resolution is the strongest part of the design.
§6.1 lays out the read-shape-blast-radius argument (10+ wording
sites if "replace" were chosen — pack-startup × 3 CLIs, pm-startup
× 3 CLIs, PACK-CHAT, PM-CHAT, agent files × 3 CLIs each) and the
pattern-parity argument (V1 §6.3 tracker mirror is precedent;
`_tmf_regen_mirror()` at `tracker-migrate-forward.sh:1172` is the
implementation). Both arguments are correct and cite-checked.

Strength: the design composes onto an existing pattern (tracker
mirror) instead of inventing a new one. This is the maintainability
principle paying off — fewer concepts, fewer special cases.

Tension the architect glossed: §6.4 says the mirror is regenerated
as the **last step** of any write to a per-entry file, but §7.3
says Pack Chat / PM Chat workflows need to be aware that the
mirror is regenerated, not edited. **Who runs the regenerator?**
The library helper exists in `scripts/lib/` (per §5.2 and §6.2),
but the design does not name the call site — does Pack Chat's
commit pre-flight invoke it? Does a git pre-commit hook? Does the
agent that wrote the per-entry file invoke it? §7.2's "atomic
commit" framing implies the writer (Pack Chat / PM Chat / agent /
migrator) invokes it before staging. That should be stated
explicitly so the planner knows whether to add a hook, a
verb, or a documented manual step. This is a minor gap, not a
flaw.

Alternatives visibility: §6.1 names "replace the file outright"
as the alternative and enumerates four costs (a)–(d). That is
adequate alternatives-visibility for the central decision.

### §1.2 — OQ-4 (tracker-mode composition: below tracker) — RESOLVED, sound

§8.1 frames three modes (flat-file monolithic = Mode 1; flat-file
decomposed = Mode 2 = THIS DESIGN; tracker = Mode 3) and places
per-entry decomposition **below** tracker as a "flat-file flavor."
This is the right composition — it preserves the V1 §6.3 mirror
contract that tracker-forward already depends on, and it means
forward migration to tracker reads the (per-entry-derived) mirror
without distinguishing the two flat-file modes.

Tension partially glossed in §8.2: when a user opts into tracker
mode (Mode 2 → Mode 3), the architect names two options (A: per-
entry tree becomes tracker-mirrored; B: per-entry tree left
untouched / stale) and recommends A but does not require it. This
is appropriate architect-pass restraint for a planner-owned
choice, but the recommendation has a real consequence: if the
planner picks B, a user who decomposed their flat-file then
enabled tracker has a stale per-entry tree on disk and a
correctly-mirrored monolithic file. Two-source-of-truth confusion
is a maintainability concern. The architect could strengthen the
recommendation to **A is required** and let the planner argue for
B if they have a reason — that would be a stronger design call
without overstepping. Minor.

§8.3 reverse-emit composition is sound: reverse-emit continues
to emit monolithic files; a separate post-emit step decomposes
them back into the per-entry tree; mirror regeneration verifies
byte-identity (§8.4). This composes cleanly onto BD-131..BD-134
tracker repair without redesigning the tracker contract.

### §1.3 — OQ-7 (customization-preserve: existing generic class) — RESOLVED, sound

§9.1 routes per-entry files through `customization-preserve.sh`'s
existing `generic` class fall-through (verified at
`scripts/lib/customization-preserve.sh:178` `*) printf 'generic\n'
;;`). No new classes, no new dispositions. The argument for "no
new classes" (§9.1 points 1–3) is well constructed — adding three
new classes would expand the classifier table without changing
text-dispatch semantics, since per-entry files are still text and
the 3-way text dispatch already handles them.

Tension the architect partially glossed: §9.1 point 2 says
"smaller files diff more cleanly; user customization within one
BD entry is more likely to remain confined to that one file." This
is true on average but **wrong in the worst case** — a user who
customizes the *partitioning* (e.g., adds a new pack-side BD that
spans across what would become two separate BD-NNN.md files via a
typo or convention drift) generates a 3-way merge conflict that's
*harder* to resolve under decomposition because the conflict is
split across multiple files instead of one. The architect's
"incidentally improves" framing is too optimistic. Acknowledging
the worst case (and noting BD-088's truthful report makes the
divergence visible) would be more honest. Minor.

§9.3 migration-time entry routing logic is correct: the migration
step decomposes the merged file (post-customization-preserve), so
user customizations land in the appropriate per-entry file. This
exactly matches the §10.4 sequencing decision (decompose runs in
post-dispatch hook, AFTER manifest dispatch's 3-way merge has
applied). The two sections are consistent.

**Sub-finding on `_rules.md` semantic conflict — see §3.1 below
for the integration-smoothness flag.** The architect's "_rules.md
routes through generic too" claim (§9.1 point 3) handles
text-level customization correctly but does not address the
**semantic** question of what happens when the contract itself
has been edited.

### §1.4 — OQ-1 + OQ-6 (pack/project asymmetry: 5 stream directories total — pack 2, project 3) — RESOLVED, sound

§11.1 frames the asymmetry as forced by existing pack-vs-project
structural differences (per V3 §28.1:603 the pack repo has no
IMPLEMENTATION_PLAN.md; per V3.3-DELTA §6.3 state vocabularies
differ; per the v10 grammar field names differ). The asymmetry is
defended, not eliminated. This is the correct call because
eliminating any of these differences would require harmonizing
field names / state vocabulary / pack-vs-project structure —
which §5.4 of the prior review explicitly named as overreach.

§11.2 surface table is clear and complete. Pack-side has two
streams + one extra `_v8-resolved-archive.md` historical file;
project-side has three streams + one extra `_format.md` (in
changelog). That is exactly six file classes:
(a) per-entry files, (b) `_rules.md`, (c) `_toc.md`,
(d) `_v8-resolved-archive.md` (pack-only), (e) `_format.md`
(project-only), and the shipped templates of (b) for project.

Tension partially glossed: the asymmetry is defended at the
stream-count level but the design adds two **leading-underscore
file classes** beyond `_rules.md` / `_toc.md`. The architect
defends each individually but does not address the question:
is the leading-underscore convention a generic "non-entry control
file" pattern, or specifically a `_rules.md` + `_toc.md` pair? If
it's a generic pattern, future streams could add more (e.g., a
hypothetical `_index.md`); if it's specifically a pair, then
`_v8-resolved-archive.md` and `_format.md` are exceptions
that need explicit naming-scheme rules in `_rules.md`'s
filename-convention regex (per §4.1 point 2). The §3.1 regex
example `^BD-\d+\.md$` would reject `_v8-resolved-archive.md`
without a special case. Minor; surfaces a regex-design
consideration the planner needs.

### §1.5 — OQ-5 (CLAUDE.md "no Resolved section" rule resolved without CLAUDE.md edit) — RESOLVED, sound

§12.1 reads the rule under decomposition without textual change:
"BACKLOG.md" reads as "the BACKLOG.md mirror"; "no Resolved
section" reads as "no Resolved H2 in the mirror"; "entries
resolve in place" reads as "entries resolve in their per-entry
file." This re-reading is consistent and does not require the
trinity (CLAUDE/AGENTS/GEMINI) to be edited.

§12.2 handles the v8 H2 conflict by preserving the historical
block via `_v8-resolved-archive.md` and emitting it through the
mirror generator. The conflict is "rendered inoperative" rather
than "resolved" — the architect names this honestly. Sound.

Tension glossed: the rule appears in **all three trinity files**
(verified at CLAUDE.md:157, AGENTS.md:134, GEMINI.md:112), not
just CLAUDE.md. The architect's §12 framing ("CLAUDE.md") could
be read narrowly. The trinity-rule re-reading must hold across
all three files identically. The architect's framing is correct
in substance (the rule is the same in all three), but the
section title could mislead the planner into editing only one
of the three if a future amendment is needed. Minor cosmetic
note.

### §1.6 — OQ-2 (where the per-entry tree lives in the repo) — RESOLVED, sound

The prior review's §4.2.2 listed four candidate locations (pack-
root `/.backlog/`, `/maintenance-docs/backlog/`, `/docs/backlog/`,
hidden `/.pack-state/backlog/`). The architect picks pack-root
`/.backlog/` (§3.1) with a parallel-to-`.pack-tracker/` argument:
both directories start with `.` because they are structured pack
state, not pack product. This is consistent and well grounded in
the existing pack convention.

Project-side `docs/project/backlog/` (§3.3, no leading dot) is
asymmetric to pack-side `/.backlog/` (with leading dot). The
architect defends the asymmetry implicitly via "project-side
sits beside the existing monolithic file at `docs/project/`" —
that is correct but the dot-vs-no-dot asymmetry is not
explicitly named. A reader could miss it. Minor.

### §1.7 — Decomposition unit choice for IMPLEMENTATION-PLAN (the addendum-review's new guard rail OQ) — RESOLVED, sound

The addendum review's §5.2 flagged a pack-side IMPLEMENTATION-
PLAN decomposition unit question (`## §` vs `### §N.M` vs
`**BD-NNN**`) and an asymmetry concern (pack: no phases; project:
phase-N + phase-N.M).

The architect resolves this with restraint: §3.4 names "pack-side:
no decomposition" (the pack-side `maintenance-docs/v11-research/
IMPLEMENTATION-PLAN.md` is a workflow artifact owned by the
planner pass and sweeps to archive at v11 ship; decomposing it
would create churn for a file about to archive). Project-side
decomposes by phase-N + phase-N.M.

This is sound and elegant: it eliminates the asymmetry-defense
burden by simply not decomposing the pack-side artifact. The
addendum-review guard rail's option (b) is taken. Cleanly
resolved.


---

## §2 — Guard-rail compliance verification (seven guard rails)

### §2.1 — Guard rail 1: Output is one architecture doc; no edits to other files

**Architect claim:** implicit; the doc is one file.
**Verification:** Confirmed. The architect produced a single
`ARCHITECTURE-PER-ENTRY-SPLIT.md` under `maintenance-docs/v11-research/`
(per the doc's `parent:` and `audience:` front-matter at lines 4–6).
No other file was edited by the architect pass.
**Status: COMPLIANT.**

### §2.2 — Guard rail 2: Do not change the format of any existing entry; v10 grammar is byte-additive

**Architect claim:** §0 ("Single non-negotiable invariant"), §2 locked
decision 7, §3.1 "byte-identical to the corresponding span," §3.2
"byte-identical to the corresponding span," §3.3 "field labels persist
verbatim."
**Verification:** Confirmed. The design preserves every v10 grammar
element verbatim inside per-entry files: the bold-header line, the
field labels (Type, Status, Blockers, Unblocks, File/Symbol,
Description, Resolved on pack side; same plus Context, Resolution on
project side), the `---` separator, the `✅ RESOLVED (Phase NN)`
annotation. The only structural change is that the file boundary
replaces the `---` separator at the top/bottom of each entry. This is
byte-additive on entry format; the cited V3.1-DELTA §3 A2 contract
(lines 180–255) is preserved.
**Status: COMPLIANT.**

### §2.3 — Guard rail 3: Do not propose edits to PM-only files

**Architect claim:** §2 ("Does not propose edits to PM-only / primary-
chat-owned files (BACKLOG.md, CHANGELOG.md, README.md version table,
PACK-CHAT.md, PACK-AGENTS.md, pack-root and project-template CLAUDE /
AGENTS / GEMINI, EXECUTION-PLAN-V11.0.md, any PLAN-*.md in
maintenance-docs/v11-implementation/, and the v11-research authoritative
corpus).")
**Verification:** Confirmed. Reading every section, the architect
**references** PM-only files as integration points (§14.1 enumerates
PACK-CHAT.md:42-43, the pack-startup skills, the pack-architect agent
files, etc.; §14.2 enumerates the project-side equivalents) but
**proposes no edits to any of them**. §6.3 explicitly says "no
prompt-wording change is required to make decomposition work" and
§6.3's "one optional wording change is recommended" passage names
the wording as the *planner pass's job*, not the architect's.
§7.3 confirms "the specific wording for PACK-CHAT.md and PM-CHAT.md
is the planner pass's job — those files are PM-only and outside this
design's edit authority." §12 holds the "no CLAUDE.md edit" line for
the trinity rule. §16.4 explicitly defers PACK-AGENTS.md PM-only-list
expansion to the planner.
**Status: COMPLIANT.** (Strong — the architect repeats the boundary
in five places, which makes accidental violation by future readers
of the doc unlikely.)

### §2.4 — Guard rail 4: Maintainability principle §3.2 applies; defend each structural signal explicitly

**Architect claim:** §13 defends signals 4 / 5 / 6 / 8 individually.
**Verification:** Walking each:

- **Signal 4 (new validator check):** §13.1 — DEFENDED. The architect
  argues no new `check_*` is required because Check 3 continues to
  operate on the regenerated mirror with the same regex
  (`^\*\*TD-TBD\s*—` at validate-pack.py:276 — verified). A future
  planner MAY add a check, but this design does not require one.
  Sound defense.
- **Signal 5 (new top-level doc):** §13.2 — DEFENDED, with one
  honest acknowledgment. The architect doc itself fits the
  ARCHITECTURE-*.md / RESEARCH-*.md workflow-artifact exemption
  (per pack-memory CLAUDE.md:174-183). The per-entry data files
  live in `/.backlog/` / `/.changelog/` / `docs/project/...` which
  are NOT in signal-5's location filter (pack root,
  supporting-docs, project-template/docs, maintenance-docs/v11-
  implementation). The architect names `_rules.md` as
  "structurally novel as a file class" (§13.2 final paragraph)
  and treats this architect pass AS the structural defense for
  introducing the file class. This is exactly the right honest
  framing — the principle requires an architect pass for new
  file classes; this IS that architect pass; the file class is
  defended by §4.1 (immutability, contract-pointer role).
- **Signal 6 (new script):** §13.3 — DEFENDED. The mirror generator
  and `_toc.md` regenerator live in `scripts/lib/`, not as
  top-level scripts. The signal-6 verbatim carve-out
  ("helpers in `scripts/lib/` are not new scripts; they are
  library extensions") covers them. Sound.
- **Signal 8 (migrator behavior change):** §13.4 — DEFENDED with
  one **honest conditional**. The architect argues no new stage
  (uses existing `migrator_post_dispatch_hook`), no new manifest
  entry beyond what the manifest already admits, but **flags
  signal 8 as conditionally tripped** because the planner may
  add post-report-hook advisory text explaining the
  decomposition. This is the right place to leave the call —
  the planner owns the advisory delivery, and "advisory
  paragraph" vs "advisory file" is a planner-judgment line.
  The architect's "minimum-invasive option" framing is
  appropriate.

**Status: COMPLIANT.** (All four signals explicitly defended. Signal
8's conditional trip is correctly surfaced rather than glossed.)

### §2.5 — Guard rail 5: BD-119 framework contract is frozen for v11.0

**Architect claim:** §10.1 ("This design does not add a new hook"),
§10.2 ("uses the existing `migrator_post_dispatch_hook` (optional,
line 222)"), §10.4 stage-order diagram preserves the existing
`_stage_*` sequence at migrator-core.sh:212-230.
**Verification:** Confirmed against the actual source.
`scripts/lib/migrator-core.sh` lines 217–224 show the existing
optional hook gate (`if declare -F migrator_post_dispatch_hook
>/dev/null 2>&1; then; migrator_post_dispatch_hook; fi`).
`scripts/migrate-v10-to-v11.sh` lines 134–149 show the existing
adapter using this exact hook for BD-104 rename + BD-042
relocation + multiple v11 artifact installs — the architect's
claim of "v10→v11 precedent for post-dispatch usage" is accurate.
Per-entry decomposition slots into the same hook with the same
shape. **No new required hook. No new optional hook. No change to
the framework contract.**
**Status: COMPLIANT.** (Strong — the architect's design composes
onto an existing pattern that is already in production use.)

### §2.6 — Guard rail 6: Sequencing into EXECUTION-PLAN-V11.0.md Batches 7–10 + Batch 12 is planner-owned; design must be sequencing-agnostic; flag constraints, do not pre-resolve them

**Architect claim:** §0 ("This design is sequencing-agnostic with
respect to EXECUTION-PLAN-V11.0.md Batches 7–10 (BD-131..BD-134
tracker repairs) and Batch 12 (BD-104 rename); sequencing
constraints flagged in §15"), §15.1 + §15.2 flag the constraints,
§15.3 names this as a v11.x feature not v11.0.
**Verification:**

- §15.1 (BD-104 ordering) names two valid sequences and
  recommends after-BD-104 (cleaner naming), but explicitly says
  "Either sequence is correct" and "Planner-owned." That is
  flag-not-resolve discipline.
- §15.2 (BD-131..BD-134 ordering) is a HARDER constraint — the
  architect calls it "a hard constraint, not a soft
  recommendation" because tracker mode reuses the V1 §6.3 mirror
  contract that BD-131..BD-134 repair. This is honestly named: a
  hard constraint IS a constraint, and naming it does not
  pre-resolve sequencing — it scopes the planner's choice space
  correctly. The planner can still decide the version target
  (v11.x vs v12.0); the constraint just says "after the
  repairs land."
- §15.3 clearly defers version-target choice to the planner.

**Status: COMPLIANT.** (The architect names sequencing constraints
honestly as constraints rather than fudging them — that is the right
discipline. A constraint that's-actually-a-constraint is not
sequencing pre-resolution; it's truthful scoping.)

### §2.7 — Guard rail 7 (added by addendum review §5.2): Pack vs project decomposition asymmetry — must be explicitly defended OR restricted to one side OR composed onto a single unit

**Architect claim:** §3.4 ("pack-side: no decomposition" for
IMPLEMENTATION-PLAN); §11 (pack-side has 2 streams, project-side has
3 streams; defended in §11.1 + §11.2).
**Verification:**

- For IMPLEMENTATION-PLAN: the architect takes addendum-review
  §5.2's option (b) — restrict decomposition to project-side
  only, leave pack-side untouched (§3.4). The justification (the
  pack-side maintenance-docs/v11-research file is a workflow
  artifact about to archive at v11 ship) is sound and grounded
  in pack-memory Pattern B (CLAUDE.md:174-183). This eliminates
  the asymmetry-defense burden cleanly.
- For BACKLOG and CHANGELOG: the architect takes the asymmetry
  head-on (§11.1 + §11.2), defending each stream's pack-vs-project
  difference by citing V3.x sections or v10 grammar conventions.
  Each difference traces to an existing pack/project structural
  divergence. No new asymmetry is introduced.

**Status: COMPLIANT.** (Cleanly handled — option (b) for
IMPLEMENTATION-PLAN, explicit defense for BACKLOG/CHANGELOG.)

---

## §3 — Integration-smoothness assessment

### §3.1 — BD-119 framework integration

The architect's claim that no new BD-119 hook is needed is
**verifiable and correct**. The existing optional
`migrator_post_dispatch_hook` (gated at `migrator-core.sh:222`)
already runs between dispatch and relocations stages — exactly
the right place for the one-shot decompose-monolithic-into-tree
operation.

The v10→v11 adapter (`scripts/migrate-v10-to-v11.sh:134-149`)
already uses this hook for five different operations (BD-104
rename, BD-042 relocation, v11 artifact install, python-
architecture skill rename, BD-144 capability-token translation).
Adding a sixth operation (decompose) for the v11.x migrator that
lands per-entry decomposition fits the established pattern
without any contract change.

The architect's claim that "the adapter-private helper functions
live under `scripts/lib/migrate-vN-to-vM/`" (§10.2) is correct
per the existing `scripts/lib/migrate-v10-to-v11/` precedent.

**Integration smoothness: HIGH.** The design fits cleanly into
existing infrastructure.

### §3.2 — BD-088 customization-preserve integration

The architect's claim that per-entry tree paths route through the
existing `generic` class is **verified** (`customization-preserve.sh`
lines 147–179: the `case "$rel" in` block ends with `*) printf
'generic\n' ;;` — paths under `/.backlog/`, `/.changelog/`,
`docs/project/backlog/`, `docs/project/implementation-plan/`,
`docs/project/changelog/` will all fall through to `generic`).

**Tension flagged: `_rules.md` semantic conflict — what happens when
a client edits `_rules.md`?** The architect's §4.2 says "the
overwrite-from-template mechanism is the enforcement: a user who
edits `_rules.md` will see their edit marked
`merged-with-customization` or
`customization-detected-needs-reconciliation` in the BD-088
truthful migration report at the next pack version bump, and can
decide per the existing pack-update process."

That handles the *text-merge* outcome, but `_rules.md` is the
**directory contract**. A user who customizes the filename-convention
regex (e.g., changes `^BD-\d+\.md$` to `^B-\d+\.md$`) creates a
contract that the mirror generator and `_toc.md` regenerator
**must read** to do their job. Two unanswered questions:

1. Do the library helpers (`scripts/lib/` mirror generator and
   `_toc.md` regenerator) **load `_rules.md`** as a config file at
   runtime, or do they hard-code the filename conventions?
2. If they load it, what happens when the user's customization
   makes the contract internally inconsistent (e.g., regex admits
   files the mirror generator can't parse)?

§4.1 says `_rules.md` declares the regex/glob pattern admitted;
that's load-bearing if the helpers consume it. If the helpers
hard-code, then `_rules.md` is documentation-only and the
customization-preserve text-merge is fine. The architect should
say which.

This is a **minor follow-up** — the planner can resolve it, but the
architect's design choice has a downstream consequence the
architect should make explicit. See §8 recommendation.

**Otherwise integration smoothness: HIGH.** The "no new classes"
decision avoids classifier-table churn; the per-entry files fall
through cleanly to the existing 3-way text dispatch.

### §3.3 — BD-159 maintainability integration (signals 4/5/6/8)

Verified per §2.4 above. Signals 4, 5, 6 are explicitly defended
as untripped. Signal 8 is honestly flagged as conditionally
tripped (advisory wording delivery is the contingency). The
architect's defenses are sound and consistent with the principle
text at `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` lines
274–311.

**One subtle observation about signal 5 + signal 9:** The architect
adds a new file class (`_rules.md`) and another (`_toc.md`) and
one-off files (`_v8-resolved-archive.md`, `_format.md`). The
maintainability principle's signal 5 catches new doc files in
named locations; these new files live in `/.backlog/` etc., which
isn't in signal 5's location filter, so signal 5 doesn't trigger.
But the principle intends "any new file class needs an architect
pass," and the architect handles this in §13.2 by saying "this
architect pass IS the structural defense for the file class."
That's correct architect-pass discipline.

**Signal 9 (PM-only file expansion)** is implicitly tripped: when
the planner pass adds `/.backlog/`, `/.changelog/`,
`docs/project/backlog/`, etc. to PACK-AGENTS.md's PM-only-files
list, that's a PM-only-list expansion. §16.4 flags this for the
planner. The architect honestly names it as a likely trip and
defers to the planner. That is correct discipline — the
architect's design implies the expansion but does not write it.

**Integration smoothness: HIGH** for signals 4/5/6/8;
**flagged** for signal 9 (planner work surface, not architect
defect).

### §3.4 — Tracker mode (forward + reverse) integration

Verified per §1.2 above. Forward migration reads the
(per-entry-derived) mirror — same code path as today since the
mirror is byte-identical to what the monolithic file would be in
Mode 1 (cited at `tracker-migrate-forward.sh:268`
`tmf_parse_backlog`, line 399 `tmf_parse_implementation_plan`,
line 1172 `_tmf_regen_mirror`). Reverse-emit also continues to
emit monolithic files (`tracker-migrate-reverse.sh:409`
`_tmr_emit_backlog`, line 485 `_tmr_emit_implementation_plan`,
line 553 `_tmr_emit_changelog`); a separate post-emit decompose
step regenerates the per-entry tree.

**Round-trip verification (§8.4) is the key correctness invariant**
and the architect names it explicitly: decompose then regenerate
must be byte-identical to the input file. This is the same
byte-identity contract V1 §6.7 establishes for forward/reverse
round-trip, applied to monolithic↔per-entry transformation. The
verification harness (cited at `scripts/tracker-migrate.sh
roundtrip-test`) extends to cover this round trip.

**Integration smoothness: HIGH.** The design composes onto the
existing tracker contracts without redesigning either the forward
or reverse surface.

### §3.5 — validate-pack Check 3 integration

Verified at `scripts/validate-pack.py:262-281`. Check 3
(`check_td_tbd_sentinels`) reads `BACKLOG.md` line-by-line and
matches `^\*\*TD-TBD\s*—` to detect unprocessed sentinels. Under
decomposition the regenerated mirror is byte-identical to today's
BACKLOG.md, so the same regex finds the same sentinels in the
same lines. **No change required.** The architect's claim
is correct.

A latent concern the architect does not address: if the per-entry
file is the source of truth, a TD-TBD sentinel can also live in a
per-entry file directly. Check 3 reads the mirror, so it would
catch the sentinel after regeneration — but only if the
regenerator ran. Practically: the write-path contract (§6.4) says
the mirror is regenerated as the last step of any per-entry
write, so the lag window is one git commit. Check 3 runs in CI
on a committed state; the regenerator ran before the commit;
Check 3 sees the sentinel. Sound.

**Integration smoothness: HIGH.**

### §3.6 — pack-startup / pm-startup / agent-prompt read directives

Verified at `.claude/skills/pack-startup/SKILL.md:19` ("Read
`BACKLOG.md` in full."), and at PACK-CHAT.md:42-43. The architect's
claim that **no wording change is needed** for decomposition to
work (§6.3) is correct because the mirror exists and is current.
The architect names one optional wording change (per-entry-read
capability for smaller token footprint) and explicitly defers it
to the planner. That is the right boundary.

**Integration smoothness: HIGH.** Zero forced wording changes;
one optional addition the planner can choose to ship.

### §3.7 — BD-104 sequencing collision — flagged not pre-resolved

Verified per §2.6 above. §15.1 names two valid sequences (decompose
before BD-104; decompose after BD-104) and recommends after but
explicitly says either is correct. The recommendation is grounded
in V3.3-DELTA §4.1's hyphenated forward-parser contract. The
planner pass owns the call.

**Integration smoothness: HIGH.** Cleanly flagged.


---

## §4 — Architect-overreach scan (six §5.4 signals)

The prior review (REVIEW-RESEARCH-PER-ENTRY-SPLIT.md §5.4) enumerated
six signals an architect could misread as license to expand scope.

### §4.1 — Signal 1: harmonize Resolved: vs Resolution: field names

**Could the architect have proposed harmonization?** Yes (the §4
research row showing different field names is the prompt-bait).
**Did the architect harmonize?** No. §2 ("Scope boundary — what this
design does NOT do") explicitly says: "Does not change the field
labels (`Type:` / `Status:` / `Blockers:` / `Unblocks:` /
`File/Symbol:` / `Description:` / `Resolved:` / `Context:` /
`Resolution:`). The field-name asymmetry between pack (`Resolved:`)
and project (`Resolution:` plus inline `✅ RESOLVED (Phase NN)`
annotation per RESEARCH-PER-ENTRY-SPLIT.md §4 line 460) persists —
this is an architect-overreach signal per the brief; harmonization is
out of scope and governed by V3.3-DELTA §6.3 state-machine asymmetry."

The architect literally cites the overreach signal by name and refuses
the bait. **No overreach.**

### §4.2 — Signal 2: redesign the state vocabulary (5 vs 2)

**Could the architect have redesigned?** Yes (the §4 research row
showing 5 pack-states vs 2 project-states is the prompt-bait).
**Did the architect redesign?** No. §2 ("Does not redesign the state
vocabulary. Pack-side states (Open / Resolved / Deferred / Cancelled
/ Deprecated per RESEARCH-PER-ENTRY-SPLIT.md §2 lines 205–209) and
project-side states (Open / Resolved per §3 line 339) remain as-is.").

§4.1 point 4 (lifecycle states admitted by `_rules.md`) preserves
the 5-state vocabulary on pack-side and 2-state on project-side
unchanged. **No overreach.**

### §4.3 — Signal 3: edit CLAUDE.md to "fix" the no-Resolved-section rule

**Could the architect have proposed editing the rule?** Yes (the
research's documentation of the conflict is the prompt-bait).
**Did the architect propose editing it?** No. §12.1 ("Per architect
prompt guard rails 3 + overreach signal 3 + hard-stop rules, this
design does not propose any edit to pack-root or project-template
CLAUDE / AGENTS / GEMINI. It only states what the existing rule
means under decomposition.").

§12.2 acknowledges the conflict persists ("the rule and the v8 H2
still co-exist") and renders it inoperative through frozen-historical
preservation rather than rule edit. **No overreach.**

### §4.4 — Signal 4: add a new BD-119 framework hook

**Could the architect have added a new hook?** Yes (the §5 research
row enumerating 5 required + 2 optional hooks is the prompt-bait).
**Did the architect add a hook?** No. §10.1 ("This design does not
add a new hook. Per-entry decomposition, when shipped, plugs into the
**existing** hook surface."), §10.2 (uses
`migrator_post_dispatch_hook`, already optional, already in
production use by v10→v11 adapter).

The architect goes further and explicitly reuses the existing pattern
rather than even *naming* a hypothetical new hook as an alternative.
**No overreach. Strong restraint.**

### §4.5 — Signal 5: redesign the pack-startup / agent-file read flow

**Could the architect have redesigned read flow?** Yes (the §6
research row enumerating 10+ read sites is the prompt-bait).
**Did the architect redesign?** No. §6.3 ("All single-file readers
continue to read the same file path. No prompt-wording change is
required to make decomposition work."), §7.3 ("The specific wording
for PACK-CHAT.md and PM-CHAT.md is the planner pass's job — those
files are PM-only and outside this design's edit authority per the
architect prompt."), §14.1 + §14.2 enumerate the integration-point
files **without writing the new content**.

The "one optional wording change" recommended in §6.3 is explicitly
deferred to the planner. **No overreach.**

### §4.6 — Signal 6: redesign the tracker reverse-emit contract

**Could the architect have redesigned reverse-emit?** Yes (the §8
research row enumerating reverse-emit functions is the prompt-bait).
**Did the architect redesign?** No. §8.3 ("The tracker reverse-emit
contract is frozen per architect prompt guard rail 6 — repaired by
BD-131..BD-134 in v11.0, not redesigned by this design. ... Under
decomposition, reverse-emit continues to emit the monolithic files. A
separate post-emit step decomposes those monolithic files into the
per-entry tree, regenerates the mirror ... and regenerates `_toc.md`.
The reverse-emit functions themselves do not change shape — only what
follows them changes.").

The architect adds a post-emit step (a new operation, not a contract
change) and preserves the reverse-emit function shape unchanged.
**No overreach.**

### §4.7 — Cross-cutting overreach scan: PM-only-files edits proposed?

Walking the doc end-to-end for any "edit X" proposal where X is a
PM-only file:

- BACKLOG.md / CHANGELOG.md / README.md — no edits proposed; only
  the regenerated-mirror behavior described.
- PACK-CHAT.md / PM-CHAT.md — explicitly deferred to planner (§6.3,
  §7.3, §14.1, §14.2).
- PACK-AGENTS.md — explicitly deferred to planner (§16.4).
- pack-root + project-template CLAUDE/AGENTS/GEMINI — explicitly
  not edited (§12, §16.6 deferred to planner).
- EXECUTION-PLAN-V11.0.md — sequencing flagged, not pre-resolved
  (§15).
- PLAN-*.md in maintenance-docs/v11-implementation — none touched.
- v11-research authoritative corpus (V3 / V3.1 / V3.2 / V3.3 deltas
  / IMPLEMENTATION-PLAN.md) — referenced extensively (§1 cites
  every one with file:line); no edits proposed.

**Cross-cutting overreach: ZERO.** The architect held the line
cleanly across every PM-only file the prior review §5.1 enumerated.

### §4.8 — Cross-cutting overreach scan: v10 entry-format grammar changes?

Walking the doc for any change to:
- The bold-header line (`**BD-NNN — Title**` / `**TD-NNN — Title**`)
- The field labels (Type, Status, Blockers, Unblocks, File/Symbol,
  Description, Resolved, Context, Resolution)
- The `---` separator
- The cross-reference syntax (BD-NNN textual, commit hash, backtick
  file path, file:line reference)

§0 ("Single non-negotiable invariant"), §2 locked decision 7, §3.1
"byte-additive on entry format," §3.3 "field labels persist
verbatim." All four bullets above are preserved verbatim inside each
per-entry file. The only structural change is that the file boundary
absorbs the role of the `---` separator at the top/bottom of each
entry — and that does not change the entry shape, only its container.

**Grammar overreach: ZERO.**

---

## §5 — Primary-chat-architect work surface

The architect doc surfaces seven open questions in §16 that they
explicitly defer to the v11-implementation chat. Walking each to
verify it is a real open question vs a design decision the sidecar's
architect should have made themselves:

### §5.1 — §16.1 (mirror generator failure UX) — REAL open question

This is a UX policy choice (fail-loud vs fail-soft) that affects
runtime user experience. The architect recommends fail-loud per V3.x
typed-error convention (D-9 / D-10 / D-11) but says the choice is
the planner's. **This is genuinely a planner-level call** because it
intersects with the existing typed-error system the planner pass owns
when scheduling implementation BDs. Properly deferred.

### §5.2 — §16.2 (`_toc.md` in `.gitignore`?) — REAL open question

This is a packaging policy choice (tracked vs gitignored) that
affects PR review surface and commit size. The architect recommends
tracked for pack-side, defers project-side to planner. **Properly
deferred** — packaging policy crosses into project-template
shipping convention which the planner owns when writing the
init-project / migration scripts.

### §5.3 — §16.3 (migration messaging) — REAL open question

The architect recommends NO new disposition token (the per-entry
files are byte-additive content from the user's perspective; the
post-report hook carries the explanatory paragraph). **Properly
deferred** — this is a customization-vocabulary decision the
planner owns when writing the post-report-hook advisory text.

### §5.4 — §16.4 (PM-only file expansion to directories) — REAL open question

The architect explicitly will not propose PACK-AGENTS.md edits per
guard rail 3 + signal 9 of the maintainability principle.
**Properly deferred** — PACK-AGENTS.md is PM-only.

### §5.5 — §16.5 (inflection-point signal effect) — REAL open question

The architect recommends measuring against the mirror to preserve V3
§28.1's contract. **Properly deferred** — inflection-point signal
contract is V3-corpus territory; the planner pass needs to confirm
recommendation-state schema implications.

### §5.6 — §16.6 (trinity context files mention `/.backlog/`?) — REAL open question

The architect recommends keeping file-level references for v11.x.
**Properly deferred** — trinity edits are PM-only (signal 7 of the
maintainability principle).

### §5.7 — §16.7 (`_format.md` shipping policy) — BORDERLINE

The architect recommends ship-every-migration with BD-088 3-way
text dispatch, "same handling as `_rules.md`." This *could* be
called a real open question (the planner ratifies), but the
recommendation is sound and the rationale (parity with `_rules.md`
shipping) is internal to the design. The architect could have
**stated** this as a design decision rather than an open question
without overstepping. Borderline — see §6 follow-up.

### §5.8 — Additional gaps not surfaced by §16

Three gaps the primary-chat architect will need to address that the
sidecar's architect did not surface:

**Gap A: `_rules.md` runtime semantics — config or documentation?**
Per §3.2 above, the architect does not say whether the library
helpers (mirror generator, `_toc.md` regenerator, migrator
post-dispatch decompose helper) **load** `_rules.md` at runtime
to read the filename-convention regex / lifecycle states / etc.,
or whether `_rules.md` is documentation-only and the helpers
hard-code the conventions. This affects:
  - What happens when a client edits `_rules.md` (does the
    workflow misbehave or just ignore the edit?)
  - Whether the project-side overwrite-from-template mechanism
    must check for client edits (semantic conflict, not text
    conflict)
  - Whether `_rules.md`'s filename-convention regex (§4.1 point
    2) can in principle be customized per-project
The primary-chat architect must resolve this to scope the helper
implementation BDs.

**Gap B: regenerator call site — who invokes it?**
Per §1.1 above, the design names the mirror regenerator and the
`_toc.md` regenerator as library helpers in `scripts/lib/`, but
does not name **who calls them** in normal operation. Pack Chat /
PM Chat after staging? A git pre-commit hook (and if so, shipped
via the trinity pre-commit framework or a new mechanism)? The
agent that wrote the per-entry file (and if so, what protects
against agents that don't know to call it)? The migrator at
version-bump time (clear from §10.4) — but what about runtime?
The primary-chat architect should resolve the call-site question
or explicitly defer it.

**Gap C: leading-underscore filename convention — generic pattern or specific list?**
Per §1.4 above, the design adds two file classes beyond `_rules.md`
/ `_toc.md` (`_v8-resolved-archive.md`, `_format.md`). If the
filename-convention regex in `_rules.md` is `^BD-\d+\.md$` (per
§4.1 example), it rejects `_v8-resolved-archive.md`. Either:
  (a) the convention is "non-entry files start with `_` and are
      named by extension to a known list" (then `_rules.md` needs
      to list them), or
  (b) the convention is "entry-file-regex OR
      leading-underscore" (then the regex grammar needs to express
      the OR), or
  (c) the convention is "entry-file-regex; non-matching files are
      ignored as control files" (then `_rules.md` documents
      filename-shape but doesn't enforce it).
The primary-chat architect should pick one. Minor but real.


---

## §6 — Comments / suggestions / questions for the sidecar's architect

These are surface-level refinements the sidecar's architect could act
on via SendMessage if a clarifying refinement would tighten the
design. Not alternative designs — the sidecar's architect retains
design ownership.

### §6.1 — Question: does the mirror generator load `_rules.md` at runtime?

(See Gap A in §5.8.) The architect could answer this in one
paragraph. If "yes, it loads `_rules.md`," then the design needs to
say what happens when client `_rules.md` is internally inconsistent.
If "no, `_rules.md` is documentation-only and helpers hard-code,"
then `_rules.md`'s role narrows to "human + agent-readable
contract pointer" and the BD-088 text-merge handling is fully
adequate. Either answer is valid; the design needs one.

### §6.2 — Suggestion: name the regenerator call site explicitly (or defer explicitly)

(See Gap B in §5.8.) The design names the regenerator and its
contract but not its trigger. A one-paragraph note in §6.4 or §7.2
saying "the regenerator is invoked by the writer (Pack Chat / PM
Chat / agent / migrator) before staging, with the planner pass
owning whether to ship a git pre-commit hook as a safety net" would
close this without overreaching.

### §6.3 — Suggestion: clarify the leading-underscore filename convention

(See Gap C in §5.8.) `_rules.md`'s filename-convention regex needs
to admit non-entry control files. A one-sentence resolution in §4.1
point 2 would close this — e.g., "the regex matches entry filenames;
control files (leading-underscore) are enumerated separately in
`_rules.md`'s 'control files' block."

### §6.4 — Question: §3.5 `_format.md` — should this be hoisted to a §3.0 generic concept?

§3.0 declares the common shape as `_rules.md` + `_toc.md` +
per-entry files. §3.5 introduces a third file class
(`_format.md`) for one stream only. If `_format.md` is "a place
for stream-specific extra documentation that doesn't fit
`_rules.md`," that's a generic pattern other streams might
adopt later (e.g., a hypothetical pack-side `_releases.md`
documenting CHANGELOG release semantics). If `_format.md` is
strictly "preserve OT's existing Format Rules block,"
that's a one-off. The architect should say which. (This is a
borderline-design / borderline-clarification — option (a) the
sidecar resolves; option (b) the primary-chat architect can
resolve.)

### §6.5 — Suggestion: §8.2 strengthen the Mode-2-→Mode-3 recommendation

The architect recommends Option A (per-entry tree becomes
tracker-mirrored) but does not require it. As argued in §1.2,
Option B creates a two-source-of-truth confusion that maintainability
would prefer to avoid. The architect could strengthen the
recommendation to "A is required, B is rejected because it
creates two-source-of-truth confusion" without overstepping
(this is a design call within the architect's territory; the
planner ratifies but the architect picks).

### §6.6 — Suggestion: §9.1 honestly note the worst-case for customization-preserve diff

Per §1.3 above, §9.1 point 2 says "user customization within one BD
entry is more likely to remain confined to that one file." The
worst case (cross-file customization spanning what would become
multiple per-entry files) is harder to resolve under decomposition,
not easier. The architect could add one honest sentence
acknowledging the worst case without changing the design.

### §6.7 — Comment: §16.7 `_format.md` recommendation could be promoted to §3.5 design decision

Per §5.7 above, the architect recommends ship-every-migration with
parity to `_rules.md`. This is sound and within architect territory.
Moving it from §16 (open question) to §3.5 (design decision) would
reduce the planner's open-question load. Optional refinement.

---

## §7 — Addendum decision

**An addendum is NOT required.** The design is solid enough that
primary chat's own architect can pick it up cleanly. The three
substantive gaps (A: `_rules.md` runtime semantics; B: regenerator
call site; C: leading-underscore convention) are surface-level
refinements that can be resolved by:

- **Path A (preferred): SendMessage clarifications to the sidecar's
  architect at UUID `a24f716efec12fd53`.** The questions in §6.1,
  §6.2, §6.3 each take one paragraph to answer. Total round-trip:
  ~30 minutes. The architect doc gets a small revision (in-place or
  via a short ADDENDUM section appended to the existing doc).

- **Path B (acceptable): primary-chat architect resolves them
  directly.** The gaps are within the primary-chat architect's
  territory anyway (the planner integration pass needs them
  resolved). Cost: the primary-chat architect spends ~30 minutes on
  questions the sidecar's architect could answer faster, and the
  sidecar architect's design ownership is slightly narrowed
  (acceptable; the sidecar pass is closing).

Both paths are acceptable. **Path A is the cleaner choice** because it
preserves sidecar ownership and gives the primary-chat architect a
fully-resolved input. Recommend Path A unless the v11-implementation
chat schedule favors immediate primary-chat-architect spawn.

If Path A is taken, the sidecar's architect's revision should
cover (at minimum):
1. `_rules.md` runtime role (config or documentation).
2. Mirror / `_toc.md` regenerator call site (writer-invoked +
   planner-owned hook decision).
3. Leading-underscore filename convention (entry-regex vs control-
   file enumeration).

The other refinements (§6.4 — `_format.md` generic vs one-off;
§6.5 — Mode-2-→Mode-3 strengthening; §6.6 — worst-case
honesty; §6.7 — §16.7 promotion) are nice-to-haves and can be
left to the sidecar's discretion.

---

## §8 — Recommendation

**APPROVE-WITH-MINOR-FOLLOWUPS.**

**Rationale:**

1. **Design quality is high.** Every one of the seven open questions
   in the architect brief is resolved with sound reasoning,
   explicit alternatives where appropriate, and honest tension-
   naming where decisions cross planner-owned territory.

2. **Guard-rail compliance is complete.** All seven prior-review
   guard rails are observed. Six are strongly compliant with no
   ambiguity; one (signal 8) is correctly named as conditionally
   tripped (the planner owns the contingent advisory wording
   choice).

3. **Architect-overreach scan is clean.** Zero overreach. The
   architect held the line cleanly across all six §5.4 signals
   AND across the cross-cutting checks (no PM-only file edits;
   no v10 grammar changes).

4. **Integration smoothness is high.** Every cited integration
   point (BD-119, BD-088, BD-159 signals 4/5/6/8, tracker mode,
   validate-pack Check 3, pack-startup / pm-startup directives,
   BD-104 sequencing) composes cleanly onto existing pack
   infrastructure or is honestly flagged for the planner.

5. **Three minor follow-up gaps** (Gap A: `_rules.md` runtime
   role; Gap B: regenerator call site; Gap C: leading-
   underscore filename convention) are resolvable via short
   SendMessage exchanges with the sidecar's architect. None
   block primary-chat's own architect pass.

**Recommendation specifically:** primary chat should send the
sidecar's architect (UUID `a24f716efec12fd53`) a SendMessage
covering questions §6.1, §6.2, §6.3 (Gaps A/B/C) with a request
for a short revision or ADDENDUM appended to the existing doc.
After that revision lands, primary chat can spawn its own
architect to address gaps and integration points (the §16
planner-owned questions are correctly scoped for that pass), and
then a planner to integrate the per-entry design into the v11
implementation plan.

If schedule does not favor SendMessage, **APPROVE-FOR-PRIMARY-
CHAT-ARCHITECT** is also acceptable; the gaps fall to the primary-
chat architect's territory and they can resolve them directly.

---

## §9 — Read-record

This review consumed:

- `maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-SPLIT.md`
  (1,649 lines) — read in full across four chunks.
- `maintenance-docs/v11-implementation/REVIEW-RESEARCH-PER-ENTRY-
  SPLIT.md` (479 lines) — §5.4 + §5.5 + §6 read in full for the
  six original guard rails and overreach signals.
- `maintenance-docs/v11-implementation/REVIEW-RESEARCH-PER-ENTRY-
  SPLIT-ADDENDUM.md` (276 lines) — §5.2 (new guard rail) + §2.1
  (concretization of pack/project asymmetry) + §4 spot-checks
  read in full.
- `scripts/lib/customization-preserve.sh` lines 147–179 (verified
  generic-class fall-through at line 178).
- `scripts/lib/migrator-core.sh` lines 210–232 (verified existing
  optional `migrator_post_dispatch_hook` gate at line 222).
- `scripts/migrate-v10-to-v11.sh` lines 125–155 (verified the
  v10→v11 adapter already uses post-dispatch-hook for five
  operations including BD-104 rename — strong precedent for
  per-entry decompose adapter slot).
- `scripts/validate-pack.py` lines 260–281 (verified Check 3
  TD-TBD sentinel scan reads BACKLOG.md and matches
  `^\*\*TD-TBD\s*—` at line 276).
- `scripts/lib/tracker-migrate-forward.sh` and
  `scripts/lib/tracker-migrate-reverse.sh` line numbers
  (`tmf_parse_backlog`:268, `_tmf_regen_mirror`:1172,
  `_tmr_emit_backlog`:409 — verified).
- `.claude/skills/pack-startup/SKILL.md:19` (verified "Read
  `BACKLOG.md` in full." wording).
- `PACK-CHAT.md:42-43` (verified file-access strategy table
  rows for BACKLOG.md / CHANGELOG.md).
- `PACK-AGENTS.md:102-103` (verified Pack-Chat-only authority for
  BACKLOG/CHANGELOG writes).
- `CLAUDE.md:157-159`, `AGENTS.md:134-136`, `GEMINI.md:112-114`
  (verified the no-Resolved-section rule lives in all three
  trinity files identically — slight refinement to architect's
  §12 framing).
- `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-
  MAINTAINABILITY.md:274-311` (verified §3.2 signals 4/5/6/8/9
  verbatim text).
- Pack-root `ls` (confirmed `/.backlog/` does not yet exist;
  confirmed `BACKLOG.md` is 343,859 bytes / ~3,627 lines).

No design or implementation files were edited by this review.

---

## §10 — Final-line marker

REVIEW-ARCHITECTURE-PER-ENTRY-SPLIT-COMPLETE: 2026-05-13 —
APPROVE-WITH-MINOR-FOLLOWUPS. Seven open-question resolutions
explicitly evaluated (all sound, with minor tensions noted on §8.2
Mode-2→Mode-3 strengthening, §9.1 customization-preserve worst-case
honesty, §11 dot-vs-no-dot pack/project asymmetry naming). Seven
prior-review guard rails explicitly verified (all compliant; signal
8 correctly conditionally-flagged). Architect-overreach scan
explicit and zero (six §5.4 signals + cross-cutting PM-only-files +
v10 grammar checks all clean). Three minor follow-up gaps surfaced
(Gap A `_rules.md` runtime role; Gap B regenerator call site; Gap C
leading-underscore filename convention) — resolvable via SendMessage
to sidecar architect UUID `a24f716efec12fd53` or by primary-chat
architect directly. No addendum required. Recommendation: primary
chat sends short clarifying message to sidecar architect for Gaps
A/B/C, then spawns primary-chat architect for the §16 planner-owned
gaps + integration into v11 implementation plan.
