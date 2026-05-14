---
title: ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION
author: primary-chat (v11-dev) integration architect
status: design — for primary-chat reviewer, then planner
parent-design: maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-SPLIT.md (sidecar) + ARCHITECTURE-PER-ENTRY-SPLIT-ADDENDUM.md (sidecar)
prior-reviews: maintenance-docs/v11-implementation/REVIEW-ARCHITECTURE-PER-ENTRY-SPLIT.md + REVIEW-ARCHITECTURE-PER-ENTRY-SPLIT-ADDENDUM.md
authoritative-corpus: ARCHITECTURE-V3.md + V3.{1,2,3}-DELTA.md (v11-research)
v11.0-scope: locks per-entry decomposition into v11.0 mandatory + non-reversible (per sidecar §1)
audience: primary-chat reviewer (next), then primary-chat planner, then primary-chat coder
date: 2026-05-13
---

# Per-entry split — integration architecture

## §0 — TL;DR + recommendation summary

This integration pass takes the sidecar's locked design (parent +
addendum) and resolves what crosses into integration scope:
discoverability, source-of-truth invariant, read/write rules audit,
the regenerator invocation model, the 18 identify-only items
§5.a–§5.r, the three reviewer-flagged frictions, the v11.0 batch
positioning, BD absorption / new BD opens, and the sidecar core
decisions that need redesign for integration to hold.

**One sidecar core decision is overturned (REDESIGN-CORE).**
Sidecar §6.4 + §7.2 specify "regenerate after every per-entry write."
That model is rejected here as integration-incompatible: it back-
pressures every Pack-Chat / PM-Chat write loop (Goal 1 discoverability
fail when an agent forgets the trigger), it breaks Goal 2 source-of-
truth invariant the moment any single write skips the regen step, and
it scales O(N) reads × M writes per session at v12 entry counts of
500–1,000. The replacement model is **commit-time regeneration via a
tracked, idempotent shell helper invoked by Pack Chat / PM Chat as the
last step before staging**, with a `validate-pack.py` mirror-staleness
gate (Check 32) and an idempotent re-run as the recovery path. Full
treatment in §7.

**Two sidecar locked decisions are ratified with refinement.**
Sidecar Friction 1 (§1.3 hard-orders the v10→v11 hook into 6
sub-operations): ratified as architect-pass output, downgraded in
prose to a **constraint statement** rather than a hard literal call
list — because the planner pass will pick the actual function name
and Bash wiring; the sequencing constraint ("decompose runs after all
monolithic-content mutations have settled") is the architect-pass
contribution. See §3.1.

Sidecar §3.4 + §4.4 silent on `_intro.md` flat ↔ tracker round-trip:
ratified as Pack Chat clarified — `_intro.md` is pack-shipped
immutable like `_rules.md`, updates only on pack version bump
(or pack minor for organizational changes), tracker forward / reverse
does NOT touch it. See §3.3.

**One sidecar citation is corrected.** Sidecar §5.r cites
`scripts/lib/migrator-core.sh:146` for `_stage_backup`. The correct
location is `scripts/lib/migrator-stages.sh:146`. This integration
doc cites it correctly throughout. See §3.2.

**Discoverability (Pack Chat Goal 1) — designed in §4.** Agents,
skills, and scripts discover `_rules.md` / `_intro.md` / `_toc.md`
through three mechanisms layered together: (a) the trinity context
file's "Key files" block names the stream directories explicitly,
(b) every per-entry file carries an HTML-comment header pointing
back to its directory's `_rules.md`, and (c) a single new skill
fragment (`stream-discovery`) is loaded by pack-startup and pm-startup
that documents the contract resolution path. Recovery from
context-window drop is a single-line read of the per-entry file's
header comment; that single line cites `_rules.md` so the agent can
re-anchor in one Read call.

**Source-of-truth invariant (Pack Chat Goal 2) — designed in §5.**
The per-entry file is the source of truth for entry content, full
stop. The mirror is derived. The `_toc.md` is derived. STATUS.md (and
any other convenience view) carries an HTML-comment disclaimer
declaring itself never-source-of-truth. A new validator check
(Check 32) enforces mirror-in-sync at CI time so the invariant cannot
silently drift. The disclaimer text is surfaced as a PM-only edit
that Pack Chat applies (this integration architect does not edit
STATUS.md).

**Read/write rules invariant (Pack Chat Goal 3) — verified in §6.**
End-to-end audit confirms that no agent other than Pack Chat / PM
Chat writes entries under decomposition. Mirror generator + TOC
regenerator are tooling-as-helpers invoked by Pack Chat / PM Chat /
migrator — they are not agent capabilities. The PACK-AGENTS.md
"PM-only files" list expansion is a maintainability-signal-9 trip
that is **defended as a refactor, not an expansion**: the existing
PM-only list names files; under decomposition, the per-entry tree
directories become the files-equivalent and the list extends in
shape, not in semantics. Defended in §6.4.

**18 identify-only items disposition (§8 detail).**
- DESIGN (here is the resolution): §5.a (workflow discovery),
  §5.b (`_toc.md` runtime invocation), §5.c (mirror generator
  runtime invocation), §5.d (stale-mirror detection),
  §5.e (concurrent-write safety), §5.f (cross-reference integrity),
  §5.h (validator new-checks), §5.i (read-site audit completeness),
  §5.j (skill update inventory), §5.k (STATUS.md interaction),
  §5.l (Pattern B archive sweep impact),
  §5.n (BD-161 absorption), §5.p (`.pack-tracker/` vs `/.backlog/`
  namespace collision risk), §5.q (init-project.sh greenfield path),
  §5.r (backup and rollback under non-reversible migration).
- INVENTORY (here is the complete list): §5.g (test fixture
  migration impact — pre-decomposed v11-realistic-ot inventory).
- TRADEOFF (here is the cost we accept): §5.m (customization-preserve
  at per-entry granularity — the worst-case is acknowledged but the
  generic-class fall-through is correct), §5.o (diffability / git
  history — per-entry history is cleaner, cross-entry refactor
  history fans out — accepted).
- REDESIGN-CORE: regenerator invocation model (§7) — overturns
  sidecar §6.4 + §7.2 "after every write" semantics in favor of
  commit-time regeneration with CI gate.

**Integration into v11.0 execution plan (§17).** Per-entry split
slots in as **Batch 18 (NEW)** between Batch 17 (BD-106 / BD-107 /
BD-108 — tracker entity model) and Batch 19 (BD-105 / BD-103 —
STATUS.md dual-link rendering + tracker reset). Batch 18 ships seven
new BDs (BD-164 through BD-170) plus BD-161 absorbed into BD-167.
Hard sequencing constraints: AFTER BD-104 (Batch 12), AFTER
BD-131..BD-134 (Batches 7–10), AFTER BD-128 CI repair (Batch 6),
AFTER BD-101 client-migration validation gates (Batch 13). BEFORE
Batch 21 (final audit), BEFORE Batch 22 (dog-food run). Detail in §17.

**New BDs to open (planner schedules; Pack Chat opens):**
- BD-164 — per-entry split implementation (decomposition + mirror
  generator + `_toc.md` regenerator + supporting-file generators)
- BD-165 — `_v10_to_v11_decompose_streams` 6th sub-operation in
  v10→v11 post-dispatch hook (mandatory, non-reversible execution)
- BD-166 — `init-project.sh` greenfield per-entry tree install (S11b
  stage or S11 absorption — planner picks)
- BD-167 — Per-entry split client artifact installs (absorbs BD-161
  net-new SKILL.md installs into the same v11.0 install batch +
  installs `_rules.md` / `_intro.md` / seed `_toc.md` per stream
  on project side)
- BD-168 — `validate-pack.py` Check 32 (mirror-in-sync) + Check 33
  (TOC-in-sync) + Check 34 (cross-reference integrity)
- BD-169 — Read-site audit + targeted wording updates (one
  prose-tightening commit covering all the surfaces this design
  flags as "stays" vs "needs targeted update")
- BD-170 — Pre-decomposed `v11-realistic-ot` fixture extension
  (BD-160 dependency)

The planner schedules these into Batch 18. BD-161 is **absorbed**
into BD-167 (same migrator hook, same install moment, same
post-report advisory paragraph) — see §17.2.

**Out of scope acknowledgments.** This integration doc does NOT:
- Edit any PM-only file (BACKLOG / CHANGELOG / README / PACK-CHAT /
  PACK-AGENTS / CLAUDE / AGENTS / GEMINI / EXECUTION-PLAN-V11.0).
- Edit pack-product files (project-template/, supporting-docs/,
  scripts/).
- Edit the sidecar's design doc, its addendum, or the prior reviews.
- Spawn sub-agents.
- Pre-empt the planner's choice of function names, Bash wiring, or
  per-batch commit composition.

Pack Chat handles all PM-only edits the planner / coder need (per
§17.3 stops); the planner picks names; the coder ships.


---

## §1 — Inputs read + authority map

### §1.1 — Inputs consumed (read-only)

**Sidecar's design corpus:**
- `maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-SPLIT.md`
  (1,649 lines) — original sidecar architect output.
- `maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-SPLIT-ADDENDUM.md`
  (1,101 lines) — sidecar architect addendum (locks v11.0,
  one-file-per-phase, one-entry-per-file, supporting files,
  bidirectional flat ↔ tracker for multi-entity files,
  18-item §5.a–§5.r identify-only inventory).
- `maintenance-docs/v11-research/RESEARCH-PER-ENTRY-SPLIT.md`
  (1,048 lines) — sidecar docs-researcher output (factual base).
- `maintenance-docs/v11-research/RESEARCH-PER-ENTRY-SPLIT-ADDENDUM.md`
  (562 lines) — sidecar docs-researcher addendum.

**Primary-chat reviewer output (guard rail context):**
- `maintenance-docs/v11-implementation/REVIEW-ARCHITECTURE-PER-ENTRY-SPLIT.md`
  (1,096 lines) — first reviewer pass on parent design;
  APPROVE-WITH-MINOR-FOLLOWUPS; surfaced Gaps A/B/C.
- `maintenance-docs/v11-implementation/REVIEW-ARCHITECTURE-PER-ENTRY-SPLIT-ADDENDUM.md`
  (958 lines) — second reviewer pass on addendum;
  APPROVE-FOR-PRIMARY-CHAT-ARCHITECT-INTEGRATION; flagged 3
  frictions for this integration architect.

**Current v11 architecture corpus (must align with):**
- `maintenance-docs/v11-research/ARCHITECTURE-V3.md` (3,049 lines) —
  V3 baseline tracker design.
- `maintenance-docs/v11-research/ARCHITECTURE-V3.1-DELTA.md`
  (276 lines) — A2 byte-additive entry grammar lock.
- `maintenance-docs/v11-research/ARCHITECTURE-V3.2-DELTA.md` (506 lines).
- `maintenance-docs/v11-research/ARCHITECTURE-V3.3-DELTA.md`
  (917 lines) — phase-task entity model, identifier scheme,
  forward parser / reverse emitter contract.

**Files to be decomposed (entry-format authority):**
- `BACKLOG.md` (3,627 lines, 144 BD entries pack-side).
- `CHANGELOG.md` (733 lines, 11 version blocks pack-side).
- Plus the project-side OT analogs sized in
  `RESEARCH-PER-ENTRY-SPLIT.md` §3.

**Integration points (must verify or redesign):**
- `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md`
  (431 lines) — current 23-batch v11.0 ship plan.
- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md`
  (830 lines) — migrator framework adapter contract.
- `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md`
  (1,028 lines) — mechanical-vs-structural threshold §3.
- `scripts/migrate-v10-to-v11.sh` — verified post-dispatch hook
  at lines 134–149 currently runs 5 sub-ops; sidecar §1.3 +
  this design propose adding a 6th.
- `scripts/lib/migrator-core.sh` — verified `_migrator_run_stages`
  at line 212; optional `migrator_post_dispatch_hook` gate at
  line 222.
- `scripts/lib/migrator-stages.sh` — `_stage_backup` at line 146
  (correction to sidecar §5.r citation).
- `scripts/lib/migrator-manifest.sh` — manifest parser/dispatch
  vocabulary (`transform | add | remove | relocate-from`).
- `scripts/lib/customization-preserve.sh` — `customization_classify`
  at lines 145–179; `generic` fall-through at line 178.
- `scripts/lib/tracker-migrate-forward.sh` — `tmf_parse_backlog`
  (line 268), `tmf_parse_implementation_plan` (line 399),
  `tmf_compose_issue_body` (line 459), `_tmf_regen_mirror`
  (line 1172).
- `scripts/lib/tracker-migrate-reverse.sh` — `_tmr_emit_backlog`
  (line 409), `_tmr_emit_implementation_plan` (line 485),
  `_tmr_emit_changelog` (line 553).
- `scripts/lib/tracker-mirror.sh` — V1 §6.3 mirror precedent
  (idempotent header rewrite).
- `scripts/lib/tracker-agent-read.sh` — `_tar_read_entry_flat`
  (line 153) reads `BACKLOG.md` mirror.
- `scripts/lib/detect.sh` — surface detection helpers.
- `scripts/validate-pack.py` — Check 3
  (`check_td_tbd_sentinels`, lines 262–281).
- `CLAUDE.md` (pack root) — pack memory + key files block.
- `README.md` — Repository Layout reference.
- `PACK-CHAT.md` — file-access strategy table at lines 42–43.
- `PACK-AGENTS.md` — PM-only files list at lines 139–142.
- `project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md` —
  project trinity, `## Document locations` + key files.
- `project-template/.claude/skills/pack-startup/SKILL.md`,
  `.codex/skills/pack-startup/SKILL.md`,
  `.gemini/commands/pack-startup.toml` — pack-startup directives.
- `project-template/skills/pm-startup/SKILL.md` (canonical) +
  `.claude/skills/pm-startup/SKILL.md` + `.codex/skills/pm-startup/SKILL.md` +
  `.gemini/commands/pm-startup.toml` — pm-startup directives
  (verified line 71 cites `STATUS.md` and lines 69–87 cite
  BACKLOG / CHANGELOG / IMPLEMENTATION-PLAN).
- `project-template/.claude/agents/*.md` (project-side agents),
  `.codex/agents/*.md`, `.gemini/agents/*.md`.
- `.claude/agents/pack-*.md` (pack-side agents).
- `project-template/docs/pack/PM-CHAT.md` — PM chat startup +
  operating instructions (verified file-access strategy table
  at lines 119–123 per sidecar reference).
- `project-template/docs/pack/PLATFORM-SKILLS.md`.
- `supporting-docs/SETUP-NEW.md`, `SETUP-EXISTING.md`,
  `MIGRATION-v10-to-v11.md`, `METHODOLOGY.md`, `MERGE-STRATEGY.md`.
- `audit-methodology/SKILL.md` (auditor scope rules) — searched;
  no current `audit-methodology` skill exists in pack repo at
  this name; the audit methodology lives in the auditor agent files
  (project-template/.claude/agents/auditor.md and per-CLI mirrors).
- `BACKLOG.md` highest BD verified at BD-163; next available is
  BD-164.

### §1.2 — Authority map

This integration doc holds authority over:
- Integration of per-entry split into `EXECUTION-PLAN-V11.0.md`
  Batch sequence (proposes Batch 18; Pack Chat ratifies).
- Resolution of the 18 identify-only items §5.a–§5.r per the
  DESIGN / INVENTORY / TRADEOFF / REDESIGN-CORE per-item disposition.
- Redesign of the regenerator invocation model (REDESIGN-CORE
  §7) — overturning sidecar §6.4 "after every write" semantics.
- Discoverability design (Pack Chat Goal 1).
- Source-of-truth invariant + STATUS.md disclaimer requirement
  surfacing (Pack Chat Goal 2).
- Read/write rules audit (Pack Chat Goal 3).
- New BD opens (BD-164..BD-170 — proposed; Pack Chat opens after
  ratification).
- Scope of BD-161 absorption (proposed: into BD-167; Pack Chat
  ratifies).

This integration doc does NOT hold authority over:
- Pack-shipped file edits (planner schedules; coder executes).
- BACKLOG / CHANGELOG / README / PACK-CHAT / PACK-AGENTS / CLAUDE
  / AGENTS / GEMINI edits (PM-only — Pack Chat owns).
- The sidecar's locked design decisions where integration analysis
  does NOT surface a problem (parent §3.1 file naming, §6.1
  mirror-not-replace, §11.x asymmetry defenses, etc. are
  unmodified).
- Function names, Bash wiring details, exact commit boundaries
  (planner / coder).
- v11.0 vs v11.x version target — the addendum §1.1 already locks
  v11.0; this integration ratifies that lock.

### §1.3 — Sidecar authority preserved (re-litigation policy)

Per the architect prompt: the sidecar's design is approved at sidecar
level. This integration architect re-litigates a sidecar core decision
ONLY where integration analysis surfaces an unresolved problem.

The integration architect re-litigates exactly **one** core decision
(§7 — regenerator invocation model). All other sidecar decisions
ratified or refined without overturn:
- Per-entry files = source of truth (sidecar §6 + addendum §1) — RATIFIED.
- v11.0 lock-in mandatory + non-reversible (addendum §1) — RATIFIED.
- One file per phase, tasks inline (addendum §2) — RATIFIED.
- Five stream directories (sidecar §0) — RATIFIED.
- Customization-preserve generic-class fall-through
  (sidecar §9.1) — RATIFIED with a worst-case acknowledgment
  added (per reviewer §6.6 suggestion); see §13 of this doc.
- v10 entry grammar byte-additive (sidecar §0 + V3.1-DELTA §3 A2) —
  RATIFIED.
- Mirror-not-replace (sidecar §6.1) — RATIFIED.
- BD-119 framework hook contract preserved (sidecar §10.1) — RATIFIED.
- `_intro.md` per stream (addendum §3.4) — RATIFIED with the
  pack-shipped-immutable behavior clarified per Pack Chat Q3 (§3.3 of
  this doc).
- One-entry-per-file rule across all 5 streams (addendum §3.1) —
  RATIFIED.
- Supporting files (`_rules.md`, `_toc.md`, `_intro.md`,
  `_v8-resolved-archive.md`, `_format.md`) per addendum §3.2 —
  RATIFIED with the round-trip clarification in §3.3 of this doc.
- 1-to-N flat ↔ tracker contract for project `implementation-plan/`
  (addendum §4) — RATIFIED.
- Pack `changelog/` is 1-to-1 with tracker (addendum §4.6) —
  RATIFIED.

---

## §2 — Locked decisions inherited from sidecar (restated for the planner)

Restated in one place so the planner reading this doc does not have to
reconstruct from the parent + addendum + reviews. Every item in this
section is the sidecar's decision, ratified by this integration pass.

### §2.1 — Stream shape and naming

1. **Five stream directories total** (sidecar §0; addendum §3.1):
   - **Pack-side:** `/.backlog/`, `/.changelog/` (at pack repo root,
     leading-dot for "structured pack state, not pack product",
     parallel to `.pack-tracker/`).
   - **Project-side:** `docs/project/backlog/`,
     `docs/project/implementation-plan/`, `docs/project/changelog/`
     (under existing `docs/project/`, no leading-dot — they are pack
     product shipped from `project-template/`).
2. **Pack repo has no `implementation-plan/`** stream (sidecar §3.4
   citing V3 §28.1:603). The pack-side
   `maintenance-docs/v11-research/IMPLEMENTATION-PLAN.md` is a
   workflow artifact, not a stream — it sweeps to
   `maintenance-docs/archive/v11/` at v11 ship per Pattern B.
3. **Per-entry filename conventions** (addendum §3.1):
   - `BD-NNN.md` (pack `backlog/`)
   - `vN.M.md` (pack `changelog/`)
   - `TD-NNN.md` (project `backlog/`)
   - `phase-N.md` (project `implementation-plan/` — phase epic +
     phase tasks INLINE; no per-task files; addendum §2)
   - `YYYY-MM-DD-phase-NN.md` or `YYYY-MM-DD-<slug>.md` (project
     `changelog/`)
4. **Supporting files per stream** (addendum §3.2):
   - All five streams: `_rules.md`, `_toc.md`, `_intro.md`.
   - Pack `backlog/` only: `_v8-resolved-archive.md`.
   - Project `changelog/` only: `_format.md`.
5. **`_rules.md` immutability** (sidecar §4): pack version-bump only;
   project-side `_rules.md` is pack product shipped from
   `project-template/`, evolved via the existing overwrite-from-
   template mechanism through BD-088 customization-preserve generic
   class. Same for `_intro.md` and `_format.md` — see §3.3 of this doc.

### §2.2 — Mirror contract

1. **Per-entry tree is source of truth** (sidecar §6.1; addendum §1).
   Monolithic file at canonical location is the **regenerated
   mirror** — read sites continue to read it.
2. **Byte-identity invariant** (sidecar §6.2 + §8.4): the regenerated
   mirror is byte-identical to what the file would have been before
   decomposition. Round-trip:
   `decompose(monolithic) → per-entry-tree`,
   `regenerate(per-entry-tree) → monolithic'`,
   `monolithic == monolithic'`.
3. **Mirror generator** is a library helper in `scripts/lib/` (sidecar
   §6.2) — name and exact filename owned by the planner / coder pass.
   This integration architect calls it the "mirror generator" through-
   out for prose continuity.
4. **`_toc.md` regenerator** is a sibling library helper in
   `scripts/lib/` (sidecar §5.2). Both helpers share parsing logic;
   the coder pass owns the source-organization (one file or two; the
   architect-pass call is "library helpers in `scripts/lib/`, no new
   top-level scripts").

### §2.3 — Migrator integration

1. **Mandatory + non-reversible at v10.1 → v11.0** (addendum §1).
2. **No new BD-119 framework hook** (sidecar §10.1). Decomposition
   plugs into the existing optional `migrator_post_dispatch_hook`
   gated at `scripts/lib/migrator-core.sh:222`.
3. **Decompose runs after all monolithic-content mutations have
   settled** within the post-dispatch hook (this integration's
   downgrade of sidecar §1.3 — see §3.1 below). The planner picks the
   exact function name and call-list position; the constraint is that
   the decompose step must read the final v11-shape monolithic files.
4. **Customization-preserve routes per-entry tree paths through the
   `generic` class** (sidecar §9.1; verified at
   `scripts/lib/customization-preserve.sh:147-179` with `*) printf
   'generic\n' ;;` fall-through at line 178). No new classifier rows.
   Worst-case acknowledged in §13 of this doc.
5. **`migrator_manifest()` does NOT add per-entry-file rows** (sidecar
   §10.3). The monolithic file remains the manifest entry; the
   adapter-private decompose helper splits the merged file
   post-dispatch.

### §2.4 — Tracker integration

1. **Per-entry decomposition sits BELOW tracker mode** (sidecar §8.1).
   Three modes:
   - Mode 1: flat-file, monolithic source-of-truth (v10.1 baseline).
   - Mode 2: flat-file, decomposed source-of-truth (THIS DESIGN at
     v11.0 lock-in).
   - Mode 3: tracker mode (V3.x).
2. **Mode 2 → Mode 3 transition Option A** (sidecar §8.2 recommends
   A; reviewer §6.5 suggested strengthening to "A is required"):
   ratified here as **A is required** under v11.0 lock — the per-entry
   tree becomes a tracker-mirrored read-only tree alongside the
   monolithic mirror; both are regenerated from tracker state. Two-
   source-of-truth confusion would otherwise violate Goal 2. See §5.5.
3. **1-to-N flat ↔ tracker for project `implementation-plan/`
   `phase-N.md` files** (addendum §4): one phase file ↔ one
   phase-epic issue + N phase-task issues, with round-trip byte-
   identity verification per addendum §4.4.
4. **Pack `changelog/` is 1-to-1 with tracker** (addendum §4.6):
   scope buckets are intra-entry organization, not tracker entities.
5. **Tracker reverse-emit functions are unchanged in shape** (sidecar
   §8.3): they emit the monolithic mirror; a separate post-emit
   decompose step regenerates the per-entry tree. The reverse-emit
   contract is repaired by BD-131..BD-134 in v11.0 (Batches 7–10) —
   per-entry decomposition lands AFTER those repairs (sidecar §15.2).

### §2.5 — Entry grammar invariant

1. **v10 entry grammar is byte-additive**, no field-label changes,
   no state-vocabulary changes (sidecar §0 single non-negotiable
   invariant + V3.1-DELTA §3 A2 contract at lines 180–255).
2. **Pack/project asymmetry is defended, not eliminated** (sidecar
   §11.1): pack uses `Resolved:`, project uses `Resolution:`; pack
   has 5 states, project has 2; pack has no Format Rules H2, project
   has one. Each difference traces to V3.x or v10 grammar authority.
3. **Cross-reference syntax preserved verbatim** (sidecar §0):
   BD-NNN textual references, commit hash references, backtick file
   path references, file:line references continue unchanged.

### §2.6 — `_v8-resolved-archive.md` and the no-Resolved-section rule

1. **The pack-memory rule "BACKLOG.md has no Resolved section"** at
   `CLAUDE.md:157-159` (and trinity mirrors at `AGENTS.md:134-136`,
   `GEMINI.md:112-114` per reviewer first pass §1.5) is preserved
   without textual change (sidecar §12.1).
2. **The legacy v8 `## Resolved — v8 (March 2026)` H2** at
   `BACKLOG.md:2248` is preserved as `_v8-resolved-archive.md`
   (sidecar §6.2; addendum §3.5). The mirror generator emits it
   verbatim as the trailing frozen-historical block in the
   regenerated mirror.
3. **The conflict is rendered inoperative** under decomposition
   (sidecar §12.2), not resolved by edit. The rule is correctly
   re-read as "no new Resolved H2 in the mirror"; the legacy v8 H2
   is the only Resolved H2 and is frozen-historical.

### §2.7 — Generator concatenation order (per stream, per-stream mirror)

Per addendum §3.6:
```
[_intro.md content]
[entry files in sort order]
[_v8-resolved-archive.md content]    ← pack backlog/ only
```

The `_toc.md` regenerator emits the index over only the entry files;
supporting files are excluded from the entry index per addendum §3.3
(sixth `_rules.md` contract item: supporting-file basenames
admitted, treated as control state, not enumerated as entries).


---

## §3 — Three frictions resolved (with §5.r typo correction)

The reviewer's second-pass APPROVE recommendation flagged three
frictions for this integration architect. Each is resolved here.

### §3.1 — Friction 1: §1.3 hook-sequencing scope boundary

**Reviewer flag** (REVIEW-ARCHITECTURE-PER-ENTRY-SPLIT-ADDENDUM.md
§3 / §4.1 / §8 Friction 1): Sidecar §1.3 hard-orders the
v10→v11 post-dispatch hook into 6 numbered sub-operations:

```
1. _v10_to_v11_rename_implementation_plan       # BD-104
2. _v10_to_v11_relocate_legacy_docs              # BD-042
3. _v10_to_v11_install_v11_artifacts             # additive v11
4. _v10_to_v11_rename_python_architecture_refs   # BD-144
5. _v10_to_v11_translate_capability_tokens       # BD-144
6. NEW _v10_to_v11_decompose_streams             # decompose (sidecar §1.3)
```

The first 5 are verified at `scripts/migrate-v10-to-v11.sh:144-148`
(this integration verified the file directly — confirms the reviewer's
finding). The 6th is the new addition.

Reviewer's framing: "mild scope-creep into planner territory but
defensible." Pack Chat asked this integration architect to
ratify, downgrade, or redesign.

**Resolution: RATIFY-AS-CONSTRAINT (downgrade in prose).** The
architect-pass output is a **constraint statement**, not a hard
literal call list. The constraint:

> The decompose step MUST run after all monolithic-content mutations
> have settled in the same migrator run. Concretely: it must run
> after BD-104 rename (so it reads the hyphenated filename), after
> BD-042 relocation (so it operates on the final root-level files),
> after the v11 artifact installs (so any net-new monolithic content
> is present and translatable), and after BD-144 capability-token
> translation (so the per-entry files capture the translated text
> byte-for-byte).

The planner picks: function name, exact position in the call list,
whether to add intermediate logging, and whether the function lives
in `scripts/lib/migrate-v10-to-v11/decompose.sh` (under the existing
adapter-private lib subdirectory per `README.md` Repository Layout)
or as inline content in `migrate-v10-to-v11.sh`.

**Why downgrade rather than ratify literally.** The literal six-item
list is a planner-pass call (it is implementation ordering inside an
adapter-private hook, not a framework or trinity contract). The
sequencing **constraint** is the architect-pass call (it expresses
the data-flow requirement that determines correctness). This split
preserves the sidecar's design intent (the decompose step reads the
final v11-translated text) without binding the planner to literal
function-name and position decisions that may need adjustment under
implementation pressure.

**Why not REDESIGN-CORE.** The constraint itself is sound — anything
that decomposes BEFORE one of the upstream mutations would produce
per-entry files that don't reflect the final v11 content; subsequent
regenerator runs would have to re-decompose, violating the
"decompose runs once at migration" property. The planner has zero
freedom to put the decompose step BEFORE any of items 1–5 without
breaking byte-identity. So the constraint binds; the literal list
does not.

### §3.2 — Friction 2: §5.r citation slip

**Reviewer flag** (REVIEW-ARCHITECTURE-PER-ENTRY-SPLIT-ADDENDUM.md
§5.5): Sidecar §5.r cites `scripts/lib/migrator-core.sh:146` for
`_stage_backup`. Verified incorrect; correct location is
`scripts/lib/migrator-stages.sh:146` (this integration verified
directly via `Read scripts/lib/migrator-stages.sh:146`, which shows
`_stage_backup() {` at that line). `migrator-core.sh:214` invokes
`_stage_backup` from `_migrator_run_stages` but does not define it.

**Correction acknowledgement (verbatim, for future readers):**

> Correction: addendum §5.r cites `migrator-core.sh:146`; correct
> location is `migrator-stages.sh:146`. Cited correctly herein.

Every reference to the backup-stage function in the rest of this
integration doc points at the correct file. See §9.4 below for the
full §5.r treatment with the corrected citation.

### §3.3 — Friction 3: `_intro.md` flat ↔ tracker round-trip silence

**Reviewer flag** (REVIEW-ARCHITECTURE-PER-ENTRY-SPLIT-ADDENDUM.md
§3.3 / §8 Friction 3): Sidecar §3.4 (`_intro.md` decision) and
addendum §4.4 (round-trip byte-identity) are silent on whether
`_intro.md` content survives the flat ↔ tracker round trip.
Forward-emit discards `_intro.md` (the tracker has no analog);
reverse-emit must re-introduce `_intro.md` from somewhere.

**Resolution per Pack Chat user clarification (binding):**
`_intro.md` is **pack-shipped immutable** — same shipping/lifecycle
class as `_rules.md`. It updates only on pack version bump (or pack
minor for organizational changes). Tracker forward / reverse does
NOT touch it (tracker operates on entries, not on supporting metadata
files).

This means:
- **Forward emit (flat → tracker):** `_intro.md` is invisible to the
  forward emitter. The forward emitter walks per-entry files (or
  the regenerated monolithic mirror — same output by sidecar §6.1)
  and emits one tracker issue per entry. Supporting files
  (`_intro.md`, `_rules.md`, `_v8-resolved-archive.md`,
  `_format.md`) are NEVER emitted to the tracker. They are not
  entries.
- **Reverse emit (tracker → flat):** the reverse emitter does NOT
  touch `_intro.md`. Reverse-emit produces the monolithic mirror
  skeleton from tracker state (per sidecar §8.3); the
  post-emit decompose step splits the mirror into per-entry files;
  the `_intro.md` file already on disk (placed by the original
  v10.1 → v11.0 migration of the client, or refreshed by a later
  pack version-bump migration) is preserved. The mirror generator
  reads `_intro.md` from disk at every regeneration to compose the
  monolithic mirror's preamble.

**Pack vs project copies treated separately.** Even when the
content is similar, the pack-side `/.backlog/_intro.md` and the
project-side `docs/project/backlog/_intro.md` are different files
on different lifecycles:
- Pack-side: lives in pack repo; updated by pack-version-bump in
  pack repo (Pack Chat applies the edit when shipping a pack
  version that organizes the intro differently).
- Project-side: lives in `project-template/docs/project/backlog/`
  in pack repo; ships into client projects via `init-project.sh`
  (greenfield) and `migrate-v10-to-v11.sh` (existing v10.1 clients);
  routed through BD-088 customization-preserve `generic` class on
  every subsequent pack version-bump (sidecar §9.1) so client edits
  surface in the truthful report rather than being silently
  overwritten.

**Round-trip statement (resolves silence):**
- Flat ↔ tracker round trip preserves entry content via the V1
  §6.7 contract (byte-identity for v10-grammar fields). Supporting
  files (`_intro.md`, `_rules.md`, `_v8-resolved-archive.md`,
  `_format.md`) are NOT round-tripped — they are not part of the
  flat ↔ tracker contract surface. This is correct behavior, not a
  gap.
- Monolithic ↔ per-entry round trip (parent §6.2 + addendum §4.4)
  preserves the regenerated monolithic file's full content
  (`_intro.md` content emitted at the top, entries in sort order,
  `_v8-resolved-archive.md` at the bottom for pack `backlog/`) via
  the byte-identity contract. The supporting files survive this
  round trip because they are part of the per-entry tree on disk;
  they survive because the regenerator reads them.
- Composed: tracker → reverse-emit → monolithic mirror → decompose
  → per-entry tree → regenerate-mirror → monolithic mirror'. The
  starting and ending mirrors are byte-identical for entries; the
  `_intro.md` and `_v8-resolved-archive.md` survive because they
  were on disk throughout.

**State this explicitly so it does not get re-litigated.** Recorded
in §2.4 of this doc and propagated into BD-167's entry text in
§17 below.


---

## §4 — Discoverability design (Pack Chat Goal 1)

> Pack Chat Goal 1, verbatim: "The design for both pack and project
> must ensure that workflows, scripts, configs, and docs make all
> aspects of rules, intros, TOCs, entries, and related items EASY TO
> FIND for chats and agents when needed. Pointers getting dropped
> from the context window without instructions or workflows with a
> way to get them back is an immediate fail."

This section addresses identify-only items §5.a (workflow discovery
of `_rules.md`), §5.j (skill update inventory), and §5.i (read-site
audit completeness) in a single unified treatment, then enumerates the
specific design surface this integration architect commits to.

### §4.1 — The discoverability problem

Under the v11.0 lock, every chat / agent / script that operates on a
stream needs to know:
1. The directory exists and where it is.
2. The directory has supporting files (`_rules.md`, `_intro.md`,
   `_toc.md` plus stream-specific ones).
3. `_rules.md` declares the contract (filename regex, lifecycle
   states admitted, supporting-file basenames admitted, write-
   authority pointers).
4. Reads route through the regenerated mirror by default (zero
   wording change), but per-entry reads are available for token-
   efficient single-entry operations.
5. Writes go to the per-entry file, not the mirror, never the TOC.
6. After a write, the mirror + TOC must be regenerated before commit
   (per §7 of this doc — commit-time regeneration model).

Without explicit discoverability, items 3–6 are systematically
forgettable: an agent that loses context drops the per-entry pattern
and either edits the mirror (which the next regenerator overwrites,
violating Goal 2) or hand-edits `_toc.md` (same outcome). Goal 1
demands a recovery path that does not require memorizing the
contract.

### §4.2 — Three layered discoverability mechanisms

This integration architect designs **three mechanisms layered together**.
Any one of them is sufficient for an agent to recover the contract;
having three means the recovery path is robust against context drops,
agent-prompt drift, and skill-load failure.

#### Layer 1 — Trinity context file "Key files" pointer

The pack-root trinity (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`) and
the project-template trinity name the stream directories explicitly
in the "Key files to read before working on the pack" / "Key files"
section. The current pack-root `CLAUDE.md:28-33` shows the existing
shape:

```
Key files to read before working on the pack:
- README.md — version history and layout
- BACKLOG.md — open BD-NNN items
- CHANGELOG.md — version history details
- PACK-CHAT.md — PM chat operating rules
- PACK-AGENTS.md — agent routing table for pack development work
```

Under decomposition, this expands by a single line per side
(pack and project) — naming the per-entry tree and pointing at
`_rules.md` as the contract:

```
- /.backlog/, /.changelog/ — per-entry source-of-truth trees
  (read /.backlog/_rules.md and /.changelog/_rules.md for the
  per-stream contract; BACKLOG.md and CHANGELOG.md are the
  regenerated mirrors)
```

Project-template trinity adds the analog line naming
`docs/project/backlog/`, `docs/project/implementation-plan/`,
`docs/project/changelog/` and the project-side `_rules.md` paths.

**This is a PM-only trinity edit.** The integration architect does
NOT write the trinity edit. Pack Chat applies it when ratifying this
design. The planner pass schedules the edit as part of BD-167
(client artifact installs) — the trinity edit lands in the same
batch that ships the per-entry tree, so the documented references
resolve from day one.

**Trinity rule applies:** the same line shape ships in CLAUDE.md +
AGENTS.md + GEMINI.md (pack-root); separately in
`project-template/CLAUDE.md` + `AGENTS.md` + `GEMINI.md` (project
trinity). Per the existing CLAUDE.md trinity rule.

#### Layer 2 — Per-entry file header comment back-pointer

Every per-entry file carries a single-line HTML comment as the first
line (above the bold-header `**BD-NNN — Title**` line):

```
<!-- per-entry source: /.backlog/BD-NNN.md; contract: /.backlog/_rules.md -->
```

This is byte-additive on the v10 grammar (the v10 grammar rule per
V3.1-DELTA §3 A2 is "the entry STARTS with `**ID — Title**`"; the
HTML-comment line is invisible to readers and to the v10 parser
because HTML comments are not v10-entry tokens). It satisfies Goal 1
recovery: an agent that reads the per-entry file in isolation —
without prior context, without trinity-context loaded — sees the
back-pointer in line 1 and knows to read `_rules.md` to resolve the
directory contract. Single Read call, single line, no skill needed.

**Why HTML comment, not Markdown text.**
- HTML comments are invisible in rendered Markdown (GitHub web,
  IDE preview), preserving the existing "human reads the entry, sees
  the bold header" property.
- HTML comments are byte-additive on the v10 grammar; no field
  label changes (sidecar §0 invariant respected).
- HTML comments compose with the existing tracker convention: V3.x
  uses HTML comments for body markers (`<!-- pack-id: BD-NNN -->`,
  `<!-- template_version: bd-v11.0 -->`). The back-pointer comment
  is the same pattern, applied to the per-entry-tree-membership
  metadata.

**Mirror generator behavior with the back-pointer.** When the mirror
generator emits the per-entry content into the regenerated monolithic
mirror, the back-pointer comment is **stripped** — it is meaningful
only on the per-entry file (where it serves as a recovery anchor),
not in the mirror (where the directory context is implicit from the
file path). Stripping happens via a single regex match (`^<!-- per-
entry source: .* -->$` removed when emitting); idempotent.

**Reverse case — decompose split adds the back-pointer.** When the
v10→v11 migrator's decompose step (or a future regenerator that
re-creates per-entry files from a regenerated mirror — should that
ever be needed) writes per-entry files, it adds the back-pointer
comment as the first line. Idempotent: re-decomposing an already-
decomposed entry preserves the same comment.

#### Layer 3 — `stream-discovery` skill loaded by pack-startup and pm-startup

A single new skill fragment named `stream-discovery` is added to the
canonical skill library (`project-template/skills/stream-discovery/SKILL.md`)
and distributed to `.claude/skills/`, `.codex/skills/`,
`.gemini/skills/` per the existing skill copy convention (per
`README.md:101-104` skill-distribution note). The skill is loaded
by **both** pack-startup and pm-startup at session start.

Skill content (one short SKILL.md, ~40 lines):
- One-paragraph statement: "Pack-side and project-side state docs
  use a per-entry tree under `/.backlog/` etc. plus a regenerated
  mirror at the canonical filename. The per-entry tree is source of
  truth; the mirror is derived. To resolve the per-stream contract,
  read `<stream>/_rules.md` once per session."
- Per-stream `_rules.md` paths enumerated for both pack-side and
  project-side (the five directories).
- Recovery instruction: "If you read a per-entry file in isolation,
  the first line is an HTML-comment back-pointer to `_rules.md`."
- Pointer to PACK-CHAT.md / PM-CHAT.md for write-authority rules
  (those files don't change shape; they reference the per-entry tree
  via the file-access strategy table — see §4.4 below).

**Why a skill, not just trinity prose.** Skills load deterministically
at session start (per pack-startup / pm-startup contract); trinity
prose loads but is one block among many. The skill is a deterministic
trigger ensuring every session has the contract resolution path
loaded BEFORE any per-entry read.

**Cross-tool parity (trinity rule for skills).** The
`stream-discovery` skill ships in the canonical
`project-template/skills/` directory; init-project.sh and
migrate-v10-to-v11.sh distribute identical SKILL.md content to the
three per-CLI skill homes. Existing pack-startup / pm-startup skills
follow this same shape and need a one-line addition naming
`stream-discovery` in their `Active skills` list (per the BD-038
Active-skills-line convention from v9.1).

**This is one new skill, not three.** The skill content is identical
across the three CLIs (sidecar §3.0 + §4.3 establishes that streams
are not per-CLI artifacts). The trinity rule for skill content is
inherent to the existing skill-distribution mechanism.

### §4.3 — Recovery from context-window drop

> Pack Chat Goal 1, verbatim: "Pointers getting dropped from the
> context window without instructions or workflows with a way to get
> them back is an immediate fail."

The recovery scenarios this design must handle:

| Scenario | Recovery path | Cost |
|---|---|---|
| Agent reads a single per-entry file and has no other context | Read line 1 (HTML-comment back-pointer) → Read `_rules.md` | 2 Read calls, ~50 lines total |
| Agent loses pack-startup / pm-startup skill load mid-session | Read `_rules.md` directly via the trinity "Key files" line OR via the back-pointer if any per-entry file is in context | 1–2 Read calls |
| Agent reads the regenerated mirror without per-entry-tree context | Mirror's preamble (sourced from `_intro.md`) names the per-entry tree explicitly via a 1-line "Per-entry source-of-truth tree at: `/.backlog/`" pointer | 0 extra Read calls (the preamble is already in context with the mirror read) |
| Skill-discovery skill itself is missing from the session | Trinity "Key files" entry names the per-entry tree directly | 1 Read call (the trinity is read at session start anyway) |
| All three layers fail (trinity not loaded, no per-entry file in context, skill missing) | Pack-startup / pm-startup explicit `_rules.md` read directive | 1 Read call (the explicit directive in the startup skill) |

**Triple redundancy is the design.** Layers 1 + 2 + 3 each
independently resolve the recovery path. Failure of any single layer
does not break Goal 1.

### §4.4 — Read-site update inventory (resolves §5.i and §5.j)

Sidecar §14.1 + §14.2 enumerated the 10+ wording surfaces; addendum
§5.i broadened the inventory to include MERGE-STRATEGY.md,
MIGRATION-v10-to-v11.md, README.md, PLATFORM-SKILLS.md, METHODOLOGY.md
Part 7, audit-methodology rule scopes, AUDIT/IMPLEMENTATION-REPORT/
PACK-REVIEW workflow artifacts, ISSUE_TEMPLATE forms, init-project.sh,
add-capability.sh.

**The complete inventory, classified per surface.**

#### §4.4.1 — Surfaces that STAY (zero wording change required)

These all read the regenerated mirror, which is byte-identical to
v10. The mirror contract makes decomposition invisible to them.

**Pack-side (skills, agents, chat docs):**
- `.claude/skills/pack-startup/SKILL.md:19-21`,
  `.codex/skills/pack-startup/SKILL.md:19-21`,
  `.gemini/commands/pack-startup.toml:16-18` — "Read `BACKLOG.md` in
  full." stays. The mirror is current. (One-line addition naming
  `stream-discovery` skill is the EXCEPTION — see §4.4.2.)
- `.claude/agents/pack-architect.md:27`,
  `.claude/agents/pack-planner.md:32`,
  `.claude/agents/pack-coder.md:34, 38`,
  `.claude/agents/pack-reviewer.md:28-29` (verified at line numbers
  in the read-record above). Plus `.codex/agents/` and
  `.gemini/agents/` trinity mirrors. All stay — they reference
  BACKLOG.md / CHANGELOG.md by name; the mirror exists at those names.
- `PACK-CHAT.md:42-43` — file-access strategy table rows
  stay. (One-row addition for the per-entry-read capability is the
  EXCEPTION — see §4.4.3.)

**Project-side (skills, agents, chat docs):**
- `project-template/skills/pm-startup/SKILL.md:69-87` and per-CLI
  mirrors — stay, with the `stream-discovery` skill added to the
  Active skills line (EXCEPTION §4.4.2).
- `project-template/.claude/agents/coder.md:80-81`,
  `repo-ops.md:66-67`, `auditor.md:42`,
  `auditor-docs.md:28-31, 62` and per-CLI mirrors — stay.
- `project-template/docs/pack/PM-CHAT.md:119-123` — file-access
  strategy table stays (one-row addition is the EXCEPTION §4.4.3).

**Documentation surfaces:**
- `supporting-docs/MERGE-STRATEGY.md` — references BACKLOG /
  CHANGELOG / IMPLEMENTATION-PLAN by file name; the BD-088
  per-file customization-preservation matrix entries stay because
  per-entry files route through the same `generic` class. One
  paragraph addition explaining "BACKLOG.md / CHANGELOG.md /
  IMPLEMENTATION-PLAN.md are regenerated mirrors of per-entry trees
  at `/.backlog/`, `/.changelog/`, `docs/project/implementation-
  plan/` from v11.0 forward; same `generic` class applies to both
  the per-entry files and the mirrors" is the EXCEPTION
  §4.4.3.
- `supporting-docs/MIGRATION-v10-to-v11.md` — needs a section
  explaining the decomposition step (BD-167 / BD-165 advisory
  paragraph). EXCEPTION §4.4.3.
- `README.md` — version table row for v11.0 mentions
  per-entry-split (PM-only edit; Pack Chat applies). The
  Repository Layout section needs new entries for `/.backlog/`,
  `/.changelog/`, and the project-template equivalents. EXCEPTION
  §4.4.3.
- `project-template/docs/pack/PLATFORM-SKILLS.md` — references
  BACKLOG / IMPLEMENTATION-PLAN as artifact names; stays.
- `supporting-docs/METHODOLOGY.md` Part 7 (BACKLOG entry format
  authority) — stays. The per-entry decomposition does NOT change
  entry format (V3.1-DELTA §3 A2 invariant).
- `audit-methodology` references in
  `project-template/.claude/agents/auditor.md` (and trinity mirrors)
  — these list PM-only files. Need to extend the list to include
  the per-entry-tree directories (per §6 of this doc, defended as
  refactor-not-expansion). EXCEPTION §4.4.3.
- `AUDIT-*.md`, `IMPLEMENTATION-REPORT-*.md`, `PACK-REVIEW-*.md`
  workflow artifacts in `maintenance-docs/v11-implementation/` and
  `maintenance-docs/v11-research/` — stay. They cite specific
  BD-NNN entries by name; the per-entry-tree decomposition makes
  the cited entries *easier* to find (one file per BD-NNN), not
  harder. No wording change.
- `.github/ISSUE_TEMPLATE/work-item.yml` and `inbound.yml` —
  stay. Issue forms map to BD/TD entries via V3.3-DELTA §6.1
  contract; that contract is unaffected by per-entry decomposition
  (the form output is one new entry; whether it lands as a new
  per-entry file or as a new BACKLOG.md entry depends on the mode,
  not on the form shape).

**Scripts:**
- `scripts/init-project.sh` — needs a new stage (or extension of
  S11) to install per-entry tree on greenfield projects. EXCEPTION
  §4.4.3, owned by BD-166.
- `scripts/add-capability.sh` — does NOT touch state docs; stays.
- `scripts/pack-tracker.sh` and tracker libs — composed onto the
  Mode 2 → Mode 3 transition per §2.4 + §5.5; specific changes are
  identify-only items §5.b/§5.c resolved in §7 below.

#### §4.4.2 — Surfaces that gain ONE LINE (skill-discovery directive)

These get a single Active skills line addition, no other change:
- `project-template/skills/pack-startup/SKILL.md` (canonical) +
  `.claude/skills/pack-startup/SKILL.md` +
  `.codex/skills/pack-startup/SKILL.md` +
  `.gemini/commands/pack-startup.toml` —
  add `stream-discovery` to the Active skills enumeration.
- `project-template/skills/pm-startup/SKILL.md` (canonical) +
  per-CLI mirrors — add `stream-discovery` to Active skills.

#### §4.4.3 — Surfaces that gain a TARGETED PROSE addition

- `PACK-CHAT.md` file-access strategy table (lines 42–43) — one new
  row: "`/.backlog/<ID>.md` (per-entry direct read for single-entry
  operations) | direct read | smaller token footprint than mirror
  for one-entry edits". PM-only file; Pack Chat applies.
- `project-template/docs/pack/PM-CHAT.md` file-access strategy
  table (lines 119–123) — analog row for project-side
  `docs/project/backlog/<ID>.md`. PM-only file; Pack Chat applies.
- `supporting-docs/MERGE-STRATEGY.md` — one paragraph in the
  catch-all classifier section explaining v11.0 per-entry-tree
  mirror-vs-source distinction.
- `supporting-docs/MIGRATION-v10-to-v11.md` — new "Per-entry
  decomposition" section (~30 lines) covering: what changes
  (per-entry tree appears under `/.backlog/` etc.; monolithic
  files become regenerated mirrors), why mandatory + non-reversible
  (Pack Chat user direction per addendum §1), what the user does
  (nothing — the migrator handles it), backup + rollback (per §9.4
  of this doc).
- `README.md` Repository Layout — new entries naming `/.backlog/`,
  `/.changelog/`, and the project-template `docs/project/backlog/`,
  `docs/project/implementation-plan/`, `docs/project/changelog/`
  trees. PM-only; Pack Chat applies in the v11.0 release pin batch.
- `auditor.md` (and trinity mirrors at `.codex/agents/auditor.md`,
  `.gemini/agents/auditor.md`) — extend the audit-scope list to
  include per-entry tree directories alongside the existing
  monolithic file references. Same scope semantics; refactor of the
  list shape (per §6 below).
- Pack-root and project-template trinity (`CLAUDE.md` /
  `AGENTS.md` / `GEMINI.md`) "Key files" block — Layer 1
  discoverability addition per §4.2 above. PM-only; Pack Chat
  applies (trinity rule applies — three files, identical edit).

**Total wording-change surfaces: 8 prose additions + 6
skill-list-line additions + 6 trinity-key-files lines (3 pack +
3 project) = 20 distinct edit sites, all small.** All of them
are scheduled into BD-169 (the read-site audit + targeted wording
update BD opened in §17). The trinity edits are PM-only; Pack
Chat applies them. The PACK-CHAT.md / PM-CHAT.md edits are
PM-only; Pack Chat applies. The remaining edits go through
BD-169's coder-pass.

### §4.5 — Discovery for scripts (validate-pack, migrator, init-project, detect, customization-preserve)

**`validate-pack.py`** — Discovers `_rules.md` only insofar as the new
checks (Check 32 mirror-in-sync, Check 33 TOC-in-sync, Check 34
cross-reference integrity per §10 below) need to know the stream
directory paths. Hardcoded constants at the top of `validate-pack.py`
(adjacent to the existing `BACKLOG_FILE` / `REPO_ROOT` constants) name
the five stream directories and the supporting-file basenames. The
script does NOT load `_rules.md` at runtime — `_rules.md` is
documentation-for-humans-and-agents, not a config file the validator
parses. This resolves Reviewer Gap A: `_rules.md` is read-at-runtime
by the **mirror generator and `_toc.md` regenerator**, but NOT by
`validate-pack.py`. See §7.5 of this doc for runtime-read scope.

**`scripts/migrate-v10-to-v11.sh`** — The decompose step (BD-165)
calls the mirror generator and decompose helpers; those helpers know
the stream directory paths via shared constants in
`scripts/lib/migrate-v10-to-v11/decompose.sh` (or wherever the planner
locates them). No `_rules.md` parsing.

**`scripts/init-project.sh`** — BD-166 extends S11 (or adds S11b) to
install the per-entry-tree skeleton (`_rules.md` from
`project-template/docs/project/<stream>/_rules.md`, `_intro.md`
analog, empty seed `_toc.md`, no entry files for greenfield project).
Stream paths are constants in init-project.sh; no `_rules.md`
runtime-read.

**`scripts/lib/detect.sh`** — Discovers `_rules.md` only via §5.p
(presence-of-`/.backlog/` as v11.0+ flag — see §8.16 below) IF the
planner picks that signal. This integration architect's
recommendation in §8.16 is to NOT make `/.backlog/` presence a
detection signal — `tracker.toml` and the README version table are
sufficient. So `detect.sh` does NOT need to know about `_rules.md`.

**`scripts/lib/customization-preserve.sh`** — Discovers per-entry
files via the path-based `customization_classify` function (verified
at lines 145–179). Per-entry files fall through to `generic` class
(line 178) without explicit case-arm matching. The classifier does
NOT need to read `_rules.md`. This resolves the Reviewer Gap A
runtime-read question for customization-preserve: NO, it does not
load `_rules.md`.


---

## §5 — Source-of-truth invariant + STATUS.md disclaimer (Pack Chat Goal 2)

> Pack Chat Goal 2, verbatim: "No duplication / fragmentation; one
> source of truth. TOCs and lists of entries are mutable and
> derived. Keeping them in sync via duplication is bad design.
> There must be only one source of truth used by every workflow,
> doc, script, or config that needs it. Different docs / workflows
> must NOT rely on different sources of truth for the same
> information. Convenience views (like STATUS.md) are fine, but if
> they get stale they should not negatively impact work — because
> they are NOT used as source of truth. STATUS.md (and any other
> convenience view) must explicitly disclaim itself as
> never-source-of-truth — surface this requirement; Pack Chat
> handles the PM-only edit on ratification."

This section addresses identify-only items §5.d (stale-mirror /
stale-TOC detection) and §5.k (STATUS.md interaction) in a unified
treatment, plus the explicit disclaimer requirement.

### §5.1 — Source-of-truth declaration per data class

**Per-entry file is source of truth for entry content.** All entry
fields (`Type:`, `Status:`, `Blockers:`, `Unblocks:`,
`File/Symbol:`, `Description:`, `Resolved:` / `Resolution:` /
`Context:`) live in the per-entry file. The mirror is a derived
view; `_toc.md` is a derived view; STATUS.md is a derived view;
recommendation-state signals are derived views.

**`_rules.md` is source of truth for the per-stream contract.**
Filename regex, lifecycle states admitted, supporting-file basenames
admitted, write-authority pointer. Per addendum §3.3 sixth contract
item.

**`_intro.md` is source of truth for stream preamble + how-to-use
text.** Pack-shipped immutable per §3.3 of this doc; updates only on
pack version bump. Reverse-emit + tracker forward DO NOT touch it.

**`_v8-resolved-archive.md` is source of truth for the legacy v8
Resolved H2 block** (pack `backlog/` only, addendum §3.5).

**`_format.md` is source of truth for the project-side CHANGELOG
Format Rules block** (project `changelog/` only, sidecar §3.5).

**The regenerated mirror is NOT source of truth** for any entry
field. It is byte-equivalent to what the file would contain in the
v10.1 monolithic shape, computed deterministically from the
per-entry tree + supporting files. Edits to the mirror are silently
overwritten on the next regeneration (§7).

**`_toc.md` is NOT source of truth** for any data. It is a derived
index, regenerated deterministically from the per-entry files and
the supporting-file metadata. Edits to `_toc.md` are silently
overwritten on the next regeneration.

### §5.2 — Workflow source-of-truth resolution rule

**Rule:** every workflow (script, agent prompt, skill, doc) that
needs to know an entry's `Status:`, `Blockers:`, or any other field
MUST resolve it through one of two paths:
1. **Tracker mode (Mode 3):** read tracker state via the existing
   `tracker_agent_read.sh` `_tar_read_entry_tracker` path (line 100).
2. **Flat-file mode (Mode 2 = v11.0 lock):** read from the per-entry
   file `<stream>/<ID>.md`, NOT from the regenerated mirror, and NOT
   from `_toc.md`.

**Rationale.** The mirror is byte-equivalent to per-entry truth via
the regeneration contract, but resolving through the per-entry file
directly:
- Makes the source-of-truth path explicit at the read site.
- Reduces token footprint (one entry vs full mirror).
- Surfaces source-of-truth divergence (an out-of-sync mirror would
  be detected by Check 32, but the workflow that read the per-entry
  file got the truth even before Check 32 catches the drift).

**Existing read sites continue to work.** Sidecar §6.3 establishes
that no read-site wording change is REQUIRED for decomposition to
work — the mirror exists and is current. The new "source-of-truth
resolution rule" applies to NEW workflows (and to existing workflows
that opt into the per-entry-read capability per §4.4.3 PACK-CHAT.md
new row addition). Existing workflows that read the mirror continue
to do so; the validator gate (Check 32) ensures the mirror is not
stale.

**`tracker-agent-read.sh` `_tar_read_entry_flat` extension.** Today
this function (line 153) reads the BACKLOG.md mirror. Under v11.0
lock, the function should be extended to **prefer the per-entry file**
when the per-entry tree exists (i.e., when `/.backlog/` exists), and
**fall back to the mirror** for backward compatibility. This is a
single planner-pass refinement to one function; lands in BD-167's
client artifact installs (the function definition is in pack-shipped
`scripts/lib/tracker-agent-read.sh` per `README.md:202`).

### §5.3 — STATUS.md disclaimer requirement (PM-only edit)

**Requirement (binding, surfaced for Pack Chat to apply on
ratification):**

`project-template/docs/project/STATUS.md` (where it exists in the
client project — STATUS.md is project-side per
`RESEARCH-PER-ENTRY-SPLIT.md` §9 and addendum §12 — pack-side has
no STATUS.md per the same research) MUST carry an explicit HTML-
comment disclaimer at the top of the file:

```
<!-- STATUS.md is a CONVENIENCE VIEW. It is NEVER source of truth.
     Counts and links may be stale; if they disagree with the
     per-entry tree at docs/project/backlog/ or the regenerated
     BACKLOG.md mirror, the per-entry tree wins. Workflows must
     not depend on STATUS.md being current; depend on the per-
     entry tree. -->
```

The disclaimer:
- Is invisible in rendered Markdown (HTML comment).
- Is grep-discoverable for any agent/script that wants to verify
  STATUS.md classification.
- Is byte-additive on the existing STATUS.md (no other content
  change).

**Pack Chat applies this disclaimer.** STATUS.md in
`project-template/` is PM-only territory per the existing rule set.
This integration architect surfaces the requirement; Pack Chat
applies the edit when ratifying this design (or schedules it into
the same Batch 18 commit as the trinity edits per §17.3).

**Disclaimer template for any future convenience view.** If a
future PM-only convenience view is added (a hypothetical
`STATUS-pack.md`, a `RECOMMENDATIONS.md` snapshot file, etc.), the
same disclaimer pattern applies: HTML comment at top, "convenience
view, never source of truth, per-entry tree wins on disagreement."
This is recorded as a Pack-memory-class convention in §6.5 below
(surfaced as a CLAUDE.md addition, PM-only).

### §5.4 — Stale-mirror / stale-TOC detection (resolves §5.d)

The sidecar deferred this to identify-only. The integration
architect resolves it as DESIGN.

**Two detection mechanisms layered:**

**Mechanism 1 — `validate-pack.py` Check 32 (mirror-in-sync).**
Runs in CI on every push (per existing CI baseline). For each of the
five streams:
1. Re-run the mirror generator against the per-entry tree to a
   temporary file.
2. `diff` the temporary file against the on-disk mirror.
3. If any difference: FAIL with file:line of the divergence and a
   recovery instruction ("run the mirror regenerator to refresh:
   `bash scripts/lib/<helper>.sh regenerate <stream>`").

**Mechanism 2 — `validate-pack.py` Check 33 (TOC-in-sync).** Same
shape for `_toc.md`. Runs in CI; FAILs on divergence.

**Both checks are STRUCTURAL signal-4 trips per the maintainability
principle.** Per
`maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md`
§3.2 line 285–287 ("Any addition to `scripts/validate-pack.py` that
introduces a new `check_*` function, regardless of triggering BD"),
adding new validator checks is a structural signal that requires an
architect pass. **THIS architect pass IS that defense** — Check 32
and Check 33 are required to enforce Goal 2's source-of-truth
invariant. Without them, the invariant is enforced only by trust;
with them, the invariant is enforced by CI gate.

**Why CI gate, not silent-overwrite at next regeneration.** The
sidecar's §5.d named three plausible behaviors:
1. Silent overwrite at next regenerator run.
2. Warning at next regenerator run.
3. Refuse to regenerate when divergent edits exist.

This integration architect picks **(1) silent overwrite, plus
CI-gate detection.** Rationale: the silent overwrite preserves the
"mirror is derived" invariant (Goal 2) without requiring user
intervention on every regeneration. The CI gate prevents committed
divergence — if a developer manually edits the mirror between
regenerations, the next regeneration overwrites the edit, and if
they commit before regenerating, Check 32 fires in CI. The
combination preserves Goal 2 strictly without making the regenerator
into a confirmation prompt.

**Hand-edits to `_toc.md` between regenerations:** same behavior.
Silent overwrite + Check 33 catches divergence on the next
regeneration.

### §5.5 — Convenience views and the inflection-point recommendation system

§5.k named the question of whether STATUS.md update flows or the
recommendation-system signal-collection paths need adjustment under
decomposition.

**Resolution: NO functional change required; ONE prose update.**
Sidecar §16.5 recommended measuring `bd_count_active` /
`bd_count_total` / `backlog_kb` against the regenerated mirror to
preserve V3 §28.1's contract. This integration architect ratifies
that choice — measuring against the mirror keeps the existing
contract intact.

The prose update is the disclaimer in §5.3 above. The
recommendation-system signal-collection code paths read the mirror
(per the existing implementation in
`scripts/lib/recommendation.sh`); under decomposition, the mirror is
guaranteed current by Check 32. So signals stay as-is.

**Special case — `bd_count_active`.** Sidecar §16.5 noted this is
"trivially derivable from a `find /.backlog/ -name 'BD-*.md'` +
grep for `Status: Open`." This integration architect notes that
**either path produces the same number** under the source-of-truth
invariant: the per-entry count = the mirror count (because the
mirror is derived). The recommendation system continues to read the
mirror; the per-entry-tree count is available for any future
convenience-view that wants to source from the per-entry tree
directly. Both are mathematically equivalent under Check 32 and
Goal 2.

### §5.6 — Mode-2 → Mode-3 transition (sidecar §8.2 strengthening)

Sidecar §8.2 named two options for the per-entry tree when the user
opts into tracker mode:
- Option A: per-entry tree becomes a tracker-mirrored read-only
  tree alongside the monolithic mirror.
- Option B: per-entry tree left untouched as a stale flat-file-mode
  artifact.

The reviewer first pass §6.5 suggested strengthening to "A is
required" because Option B creates two-source-of-truth confusion.

**Resolution: A IS REQUIRED under v11.0 lock + Goal 2.** Option B
violates Goal 2 directly: the per-entry tree on disk would diverge
from tracker state, giving any agent that reads the per-entry tree a
stale view. Goal 2 forbids this.

The implementation: when `pack tracker init` flips Mode 2 → Mode 3,
the existing tracker-mirror flow regenerates the monolithic mirror
from tracker state (per V1 §6.3 + `scripts/lib/tracker-mirror.sh`);
**the same flow ALSO regenerates the per-entry tree from tracker
state** by running the decompose helper against the tracker-derived
mirror. Symmetric: when `pack tracker disable` flips Mode 3 → Mode
2, the reverse-emit produces the monolithic mirror, and the
post-emit decompose step regenerates the per-entry tree.

**This adds one operation to the tracker-init / tracker-disable
flow.** The operation reuses the same decompose helper used by the
v10→v11 migrator (BD-165) — no new helper, no new contract. The
planner pass schedules the wiring as part of the BD-164
implementation (the decompose helper is one library helper called
by both paths).

**One concrete planner item:** verify that the Mode-3 case where the
client manually deletes the per-entry tree on disk (e.g., `rm -rf
/.backlog/`) is recoverable — a `pack tracker doctor` extension
should detect missing per-entry-tree-but-tracker-mode and offer to
regenerate from tracker state. Identify-only for the planner, named
here so it does not get lost. (Sidecar §8.2 owns the contract; this
integration adds the recovery surface name.)


---

## §6 — Read/write rules audit (Pack Chat Goal 3)

> Pack Chat Goal 3, verbatim: "The only entities with permission to
> write entries are Pack Chat (pack scope) and PM Chat (project
> scope). This must NOT change. If your design requires a different
> agent or workflow to write entries, your design is wrong. Mirror
> generator / TOC regenerator / migrator MAY write — but only when
> triggered by Pack Chat / PM Chat / migrator (which is Pack Chat's
> tooling)."

This section audits the design end-to-end for Goal 3 compliance.

### §6.1 — Write authority by surface (audit walk-through)

| Surface | Who may write | Per existing rule | Under decomposition |
|---|---|---|---|
| Pack `BACKLOG.md` (mirror) | Pack Chat only | `PACK-AGENTS.md:102-103` "Writing BACKLOG.md entries — Pack chat only" | UNCHANGED — but Pack Chat writes the per-entry file, not the mirror; the mirror is a regeneration output |
| Pack `CHANGELOG.md` (mirror) | Pack Chat only | `PACK-AGENTS.md:103-104` | UNCHANGED — same; Pack Chat writes per-entry file |
| Pack `/.backlog/BD-NNN.md` (per-entry source) | Pack Chat only | NEW — extends the BACKLOG.md rule to the per-entry directory | Pack Chat writes; pack agents (`pack-architect`, `pack-planner`, `pack-coder`, `pack-reviewer`, `pack-docs-researcher`) MUST NOT write |
| Pack `/.backlog/_rules.md` | Pack version-bump only (PM-class) | NEW — pack-shipped immutable per addendum §4 + sidecar §4.2 | Same as CLAUDE.md / AGENTS.md / GEMINI.md (root) — PM-only files list |
| Pack `/.backlog/_intro.md` | Pack version-bump only (PM-class) | NEW — pack-shipped immutable per §3.3 of this doc | Same shipping class as `_rules.md` |
| Pack `/.backlog/_toc.md` | Mirror generator + `_toc.md` regenerator (Pack Chat / PM Chat / migrator-invoked tooling) | NEW — derived; never source of truth | NOT a Pack-Chat-write surface; agents MUST NOT hand-edit |
| Pack `/.backlog/_v8-resolved-archive.md` | Pack Chat only (pack version-bump update; otherwise frozen) | NEW — frozen-historical per sidecar §6.2 | Pack Chat applies pack-version-bump updates; routine is read-only |
| Pack `/.changelog/vN.M.md` (per-entry source) | Pack Chat only | Same as pack BACKLOG | Pack Chat writes; pack agents MUST NOT |
| Pack `/.changelog/_rules.md`, `_intro.md`, `_toc.md` | Same shipping/derivation classes as backlog | Same | Same |
| Project `docs/project/BACKLOG.md` (mirror) | PM Chat only | `project-template/.claude/agents/coder.md:80-81` write-prohibition | UNCHANGED — PM Chat writes per-entry file |
| Project `docs/project/backlog/TD-NNN.md` (per-entry source) | PM Chat only | NEW — extends the BACKLOG.md rule | PM Chat writes; project agents (`coder`, `repo-ops`, `auditor`, `auditor-docs`) MUST NOT write |
| Project `docs/project/backlog/_rules.md`, `_intro.md`, `_toc.md` | Pack version-bump only for `_rules.md` + `_intro.md`; derived for `_toc.md` | NEW — pack product shipped from `project-template/`; routed through BD-088 | Pack version-bump propagation via init-project.sh / migrate-vN-to-vM.sh; client edits surface in BD-088 truthful report |
| Project `docs/project/implementation-plan/phase-N.md` | PM Chat only | Same as TD-NNN | PM Chat writes |
| Project `docs/project/implementation-plan/_rules.md`, `_intro.md`, `_toc.md` | Same shipping classes | Same | Same |
| Project `docs/project/changelog/YYYY-MM-DD-*.md` | PM Chat only | Same | PM Chat writes; agents MUST NOT |
| Project `docs/project/changelog/_format.md` | Pack version-bump only (PM-class, project-side) | NEW — pack-shipped immutable like `_rules.md` | Same shipping class |
| Project `docs/project/changelog/_rules.md`, `_intro.md`, `_toc.md` | Same shipping classes | Same | Same |

**Audit result: every per-entry write goes through Pack Chat or PM
Chat.** No exceptions. Mirror generator and `_toc.md` regenerator
write to derived files; they are tooling invoked by Pack Chat / PM
Chat / migrator (which is Pack Chat's tooling). Goal 3 holds.

### §6.2 — Pack agent permission verification

The five pack agents are: `pack-architect`, `pack-planner`,
`pack-coder`, `pack-reviewer`, `pack-docs-researcher` (per
`PACK-AGENTS.md` table at lines 13–19). All five are listed as
"Read-only" except `pack-coder` which is "Source-write within scope;
**never** stages or commits."

Per `PACK-AGENTS.md:139-142` (PM-only files list):
> **PM-only files** are off-limits to all agents unless the caller's
> prompt explicitly scopes them in: BACKLOG.md, CHANGELOG.md,
> README.md version table, PACK-CHAT.md, PACK-AGENTS.md, CLAUDE.md /
> AGENTS.md / GEMINI.md (root and `project-template/`).

**Under decomposition, this list extends** to include:
- Pack `/.backlog/`, `/.changelog/` (entire directories — PM-only).
- Project-template `project-template/docs/project/backlog/`,
  `project-template/docs/project/implementation-plan/`,
  `project-template/docs/project/changelog/` (entire directories —
  the canonical templates that ship into client projects).

The extension is a **refactor in shape, not an expansion in
semantics**:
- **Today (file-level):** "BACKLOG.md, CHANGELOG.md" name two files.
- **Tomorrow (directory-level):** "the per-entry tree directories
  PLUS the regenerated mirrors at the canonical filenames" name the
  same scope expressed at a different granularity.

The mirror at `BACKLOG.md` is still in the PM-only list (it's a
regeneration output that Pack Chat triggers; agents don't edit it).
The per-entry directory `/.backlog/` is added to the list because
that's the new write surface.

**Defense vs maintainability signal 9 ("PM-only file expansion").**
Per
`maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md`
§3.2 line 305–306, signal 9 is "Any addition to the agents-never-
modify list or the PM-only file list in PACK-AGENTS.md." Strictly
read, the directory addition IS an addition to the list.

**This integration architect's defense:** the addition is
required by Goal 3 — the per-entry tree IS the new entry-write
surface, and entry-writes are PM-only. Not extending the list would
violate Goal 3 (agents could write entries by writing per-entry
files). The architect-pass is THIS integration architect; the
defense is recorded here. The PACK-AGENTS.md edit is PM-only; Pack
Chat applies it as part of Batch 18 setup (per §17.3).

### §6.3 — Mirror generator and `_toc.md` regenerator: tooling-not-agent

Per the Goal 3 binding: "Mirror generator / TOC regenerator /
migrator MAY write — but only when triggered by Pack Chat / PM Chat
/ migrator."

The mirror generator and `_toc.md` regenerator are **library
helpers** in `scripts/lib/` (sidecar §5.2 + §6.2). They are NOT
agents. They have no LLM session, no agent prompt, no autonomy. They
are deterministic shell functions invoked by:
- Pack Chat / PM Chat (commit-time invocation per §7 of this doc).
- Migrator (`migrate-v10-to-v11.sh`'s `_v10_to_v11_decompose_streams`
  invocation per §3.1 of this doc).
- Tracker init / disable (per §5.6 above).

In all three invocation paths, the trigger is Pack Chat / PM Chat /
their tooling. Agents cannot invoke the helpers (agents are
read-only on source for `pack-architect` / `pack-planner` /
`pack-reviewer` / `pack-docs-researcher`; `pack-coder` may modify
source within scope its caller defines, and Pack Chat's caller-scope
policy excludes the per-entry tree directories per §6.2 above).

**Goal 3 preserved.**

### §6.4 — PACK-AGENTS.md edit specification (PM-only — Pack Chat applies)

**This integration architect surfaces the edit specification, NOT
the edit text.** Pack Chat owns PACK-AGENTS.md and applies the edit
as part of Batch 18 setup.

The specification:

1. The "PM-only files" block at `PACK-AGENTS.md:139-142` extends
   from naming files to naming files + directories. The shape becomes:

```
PM-only files and directories are off-limits to all agents unless
the caller's prompt explicitly scopes them in:

Files:
- BACKLOG.md (regenerated mirror; per-entry source at /.backlog/)
- CHANGELOG.md (regenerated mirror; per-entry source at /.changelog/)
- README.md version table
- PACK-CHAT.md
- PACK-AGENTS.md
- CLAUDE.md / AGENTS.md / GEMINI.md (root and project-template/)

Directories:
- /.backlog/ (pack per-entry tree — entries; supporting files
  pack-shipped via version-bump only)
- /.changelog/ (pack per-entry tree)
- project-template/docs/project/backlog/ (project per-entry tree —
  canonical templates that ship into client projects)
- project-template/docs/project/implementation-plan/
- project-template/docs/project/changelog/
```

2. Add a one-paragraph note explaining that `_rules.md`, `_intro.md`,
   `_v8-resolved-archive.md`, `_format.md` within these directories
   are pack-shipped immutable (version-bump only); `_toc.md` is
   derived (regenerator-only); per-entry files are PM-only writes.

3. Add a one-line note that pack-coder CAN scope the per-entry tree
   in for an explicit BD if Pack Chat's prompt scopes it — same
   exception clause that applies to other PM-only files today.

**Trinity rule applies:** the same rule lives in `PACK-AGENTS.md` at
the pack-repo level; the project-template-side analog is in PM-CHAT.md
write-authority section (project-template-side). Pack Chat applies
both edits in lockstep.

### §6.5 — CLAUDE.md pack-memory addition (PM-only — Pack Chat applies)

Surfaces a Pack-memory-class convention this integration architect
identifies as needed but cannot apply directly.

**Surfaced text** (Pack Chat reviews and applies — exact wording is
Pack Chat's call):

```
- **Per-entry trees are source of truth; mirrors are derived.**
  The pack `/.backlog/` and `/.changelog/` trees, and the project
  `docs/project/backlog/` / `implementation-plan/` / `changelog/`
  trees, are the source of truth for entry content. The monolithic
  `BACKLOG.md` / `CHANGELOG.md` / `IMPLEMENTATION-PLAN.md` files at
  the canonical locations are regenerated mirrors — read-stable but
  never source of truth. STATUS.md and any other convenience view
  carry an explicit "never source of truth" disclaimer; if a
  convenience view drifts, the per-entry tree wins. Read more at
  `<stream>/_rules.md`.
```

This is a Pack-memory entry shape (per the existing Pack-memory
section at `CLAUDE.md:93-191`); the trinity rule applies; Pack Chat
applies the edit in CLAUDE.md / AGENTS.md / GEMINI.md (pack root)
identically.


---

## §7 — Regenerator cost / invocation redesign (REDESIGN-CORE)

This section overturns one sidecar locked decision. The sidecar's
§6.4 + §7.2 specify "regenerate after every per-entry write." The
integration analysis surfaces three failures in that model that
require an architect-pass redesign.

### §7.1 — The problem with sidecar §6.4 + §7.2

**Sidecar §6.4 — Write-path / mirror-staleness contract:**
> "The mirror is regenerated as the **last step** of any write to a
> per-entry file. The write order is:
> 1. Agent / Pack Chat / PM Chat / migrator writes a per-entry file
>    (e.g. `/.backlog/BD-160.md`).
> 2. The mirror generator regenerates the canonical monolithic file
>    from the per-entry tree (e.g. `/BACKLOG.md`).
> 3. The `_toc.md` regenerator regenerates the directory index."

**Sidecar §7.2 — Write atomicity:**
> "A 'write' to a stream is a multi-file change: Edit one or more
> per-entry files. Regenerate the mirror (single file per stream).
> Regenerate `_toc.md` (single file per stream). These three files
> compose a single atomic commit."

**Three failures of this model:**

**Failure 1 — Goal 1 discoverability fail.** "Run the regenerator
after every write" is a memorizable rule that an agent or Pack Chat
operator WILL forget. Pack Chat user direction in the brief: "Pointers
getting dropped from the context window without instructions or
workflows with a way to get them back is an immediate fail." A workflow
that demands "remember to invoke the regenerator after each write" is
exactly such a fail mode. Agents lose context, Pack Chat operators
batch edits, the regenerator gets skipped, the mirror diverges.

**Failure 2 — Goal 2 source-of-truth invariant fail.** The moment any
single write skips step 2 or step 3, the mirror diverges from per-
entry truth. Any subsequent read of the mirror (which sidecar §6.3
explicitly says continues at all the existing read sites) sees stale
content. The invariant — "mirror is always current" — is enforced
purely by trust. There is no detection mechanism; there is no
recovery; there is no CI gate. The first divergence is invisible
until it surfaces as a contradiction someone notices.

**Failure 3 — Scaling cost at v12+ entry counts.** At v11.0 baseline:
144 BD entries pack-side; ~50 TD entries project-side OT; ~12
phase-files project-side; ~93 changelog entries pack+project. The
mirror generator parses the entire per-entry tree on every write to
produce one byte of output (the regenerated mirror) — O(N) reads per
write where N is the entry count. A typical Pack Chat session ships
3–5 entries (status flips, new opens) and ends with one commit. Per
sidecar §6.4 the regenerator runs 3–5 times in that session; each
run reads ~150 files. At v11.0 baseline this is ~750 reads per
session, ~10ms per file = ~7.5 sec total. Tolerable.

At projected v12 scale (500 entries pack + project combined,
estimated by extrapolating the v9→v10→v11 growth rate of ~30
entries/major-version): 5 writes × 500 reads × 10ms = 25 sec per
session. At v13 scale (1000 entries): 50 sec per session. The
regenerator becomes the longest single operation in a Pack Chat
session.

This back-pressure is the operational cause of Failure 1: at
50-second regenerator runs, agents and operators WILL skip the
regenerator ("I'll batch and regenerate later"), and Failure 1 becomes
Failure 2 deterministically.

### §7.2 — Cost calculation (v11.0 baseline + v12 + v13 projections)

| Scenario | Entries N | Writes per session W | Regenerator runs | Reads per regen | Total reads | Time @ 10ms/read |
|---|---|---|---|---|---|---|
| v11.0 baseline (sidecar §6.4 model) | ~150 | 3–5 | 3–5 | 150 | 450–750 | 4.5–7.5 sec |
| v11.0 baseline (commit-time model — proposed §7.3) | ~150 | 3–5 | 1 | 150 | 150 | 1.5 sec |
| v12 projected (sidecar model) | 500 | 3–5 | 3–5 | 500 | 1500–2500 | 15–25 sec |
| v12 projected (commit-time model) | 500 | 3–5 | 1 | 500 | 500 | 5 sec |
| v13 projected (sidecar model) | 1000 | 3–5 | 3–5 | 1000 | 3000–5000 | 30–50 sec |
| v13 projected (commit-time model) | 1000 | 3–5 | 1 | 1000 | 1000 | 10 sec |

Commit-time regeneration is **3.3× faster on average** at every
scale (the W=3-to-5 sessions are the common case; W=1 sessions are
parity).

### §7.3 — Replacement model: commit-time regeneration with CI gate

**Design:** the mirror generator and `_toc.md` regenerator run **once
at commit time**, invoked by Pack Chat / PM Chat as the LAST step
before staging. The validator gate (Check 32 + Check 33 per §5.4)
catches any commit where the regeneration was skipped.

**Invocation sequence (per Pack Chat / PM Chat session):**

1. Pack Chat / PM Chat (or Pack-Chat-spawned agent under explicit
   scope) writes one or more per-entry files. No regeneration fires.
2. Pack Chat / PM Chat finishes the batch of edits.
3. Pack Chat / PM Chat invokes the mirror regenerator for the
   affected stream(s) — single explicit command line. Sample shape:
   `bash scripts/lib/<helper>.sh regenerate-mirror /.backlog/`
   (planner picks exact name).
4. Pack Chat / PM Chat invokes the `_toc.md` regenerator for the
   affected stream(s). Same shape.
5. Pack Chat verifies (per §A.1 of `EXECUTION-PLAN-V11.0.md`
   stop-before-commit): shows the staged file list (per-entry
   edits + regenerated mirror + regenerated TOC); confirms.
6. Pack Chat stages and commits per §A.1 protocol.
7. CI fires `validate-pack.py` on push; Check 32 confirms mirror is
   in sync; Check 33 confirms TOC is in sync.

**Migrator path (separate from the per-session path):**

The v10→v11 migrator's `_v10_to_v11_decompose_streams` step (BD-165)
runs the regenerator at the END of the post-dispatch hook (per §3.1
above). The migrator already operates atomically (the
post-dispatch hook completes before the post-report hook); the
regenerator at the end of the hook produces the mirror in the same
atomic operation. Same pattern applies to tracker init / disable
(per §5.6 above) — the tracker-mirror flow runs the regenerator as
its last step.

**Why "commit time" not "after every write."**
- Resolves Failure 1: Pack Chat and PM Chat have a deterministic
  commit-time discipline (per `PACK-CHAT.md:50-99` behavioral rules
  + `EXECUTION-PLAN-V11.0.md:290-296` stop-before-commit). Adding
  one explicit step ("invoke regenerator before staging") fits the
  existing discipline without requiring per-write memorization.
- Resolves Failure 2: Check 32 + Check 33 in CI catch any commit
  where the regenerator was skipped. The invariant is enforced by
  CI, not trust.
- Resolves Failure 3: regeneration cost scales with COMMITS per
  session (typically 1–3), not WRITES per session (typically 3–10).
  At v13 scale, this is 10 sec per commit instead of 50 sec per
  session.

**Why NOT "writer-side hook" (sidecar §5.b option 1).** Writer-side
hooks (file-system watchers, git pre-commit, agent post-action
triggers) require infrastructure agents and Pack Chat operators
don't have to deal with today. Adding the infrastructure is itself
new operational complexity. Commit-time-explicit-call is the
minimum-infrastructure model that meets Goals 1 and 2.

**Why NOT "git pre-commit hook" (sidecar §5.b option 2).** Git
pre-commit hooks in pack repo and client projects:
- Must be installed manually by every developer (not auto-shipped).
- Must be skipped sometimes (e.g., when committing partial work for
  review) — `--no-verify` flag exists for this; CI exists to catch
  the skip-with-no-verify case anyway.
- Add a layer of "did the hook fire?" debugging when the mirror
  diverges.
- Are ALSO shipping work this design would have to author.

The CI gate is sufficient. A pre-commit hook is an optional planner-
pass enhancement (the planner can ship a `scripts/install-pre-commit.sh`
that wires up git pre-commit hooks for developers who want the
local-time gate; same pattern as existing `scripts/install-git-hooks/`
patterns in other projects). Out of scope for THIS architect pass.

**Why NOT "lazy / on-read regeneration."** Lazy regeneration means
the mirror is regenerated when read, not when the per-entry file is
written. Two killers:
1. Read sites are non-uniform — agent prompts, validate-pack, the
   mirror generator itself when called by tracker mode. They would
   each have to either invoke the regenerator or read from a stale
   mirror. The "stale mirror" path violates Goal 2.
2. The regenerator output itself becomes write-on-read, which means
   read operations have side effects on disk and on git status. This
   breaks the existing read-only invariant for read sites.

Rejected.

**Why NOT "incremental regeneration" (sidecar §B option)."** Incremental
regeneration means re-emitting only affected sections. Killer: the
mirror's section partitioning is derived from per-entry `Status:` +
version axis (per sidecar §6.2); a single Status flip can move an
entry between sections (Open → Resolved bucket move), invalidating
the "affected sections" calculation. Full regeneration is simpler
and the cost (per §7.2) is acceptable at v13 scale under the
commit-time model. The complexity of incremental regeneration would
be premature optimization with bug surface.

### §7.4 — Concurrent-write safety (resolves §5.e)

**Sidecar §5.e** named the concurrent-write risk: Pack Chat and PM
Chat may both write per-entry files simultaneously; the regenerator
fires on inconsistent intermediate state.

**Resolution under the commit-time model:** the risk is bounded to
the same risk that exists for the v10.1 monolithic BACKLOG.md today.

- **Two Pack Chats in two terminals on the same pack repo, both
  editing per-entry files simultaneously:** today (with monolithic
  BACKLOG.md), git's normal merge-conflict mechanism fires when
  both try to commit. Under decomposition, the same applies — git
  detects the per-entry file conflicts AND the mirror conflict at
  commit time. Each Pack Chat regenerates the mirror against its
  own working tree; both regenerations are deterministic; the
  resulting mirrors will conflict in git only if the per-entry
  files conflicted. The regenerator does NOT introduce a new
  conflict surface beyond what git already provides.
- **Pack Chat and PM Chat in separate repos (pack vs project):**
  no shared file system, no concurrency risk (they edit different
  trees).
- **Migrator running while Pack Chat tries to write:** today's
  migrator already serializes against the working tree (per
  `migrator-stages.sh` `_stage_backup` at line 146 — it requires a
  clean working tree per `_stage_preflight` per
  `migrate-v10-to-v11.sh` adapter). Pack Chat cannot write during a
  migrator run because the working tree is dirty mid-migration; the
  migrator owns the tree until it completes.

**No file-lock, no atomic-snapshot, no queue is required.** The
existing git-merge-conflict mechanism is sufficient. This matches
the v10.1 baseline behavior; no regression.

**One subtle note:** the regenerator is deterministic
(idempotent — same per-entry tree input produces same mirror
output). If two Pack Chat sessions independently regenerate the
mirror after independent edits, the mirrors will only conflict on
the entries that were independently edited. Cross-entry-only
conflicts (one session edits BD-100, the other edits BD-200) merge
cleanly because the mirror diff is partitioned by entry. This is a
side benefit of decomposition — concurrent-write merge resolution
is finer-grained than today's monolithic merge.

### §7.5 — `_rules.md` runtime-read scope (resolves Reviewer Gap A)

The reviewer first pass §5.8 Gap A asked: do the library helpers
(mirror generator, `_toc.md` regenerator) load `_rules.md` at
runtime, or hard-code the conventions?

**Resolution:** the helpers read `_rules.md` AT RUNTIME for two
specific values, and HARD-CODE the rest.

**Read at runtime:**
- The supporting-file basenames admitted (sidecar addendum §3.3
  sixth contract item). The helpers must know which leading-
  underscore files to treat as control-state-not-entries; this
  list is in `_rules.md`. Reading it at runtime allows future
  pack version-bumps to add a supporting file (e.g., a hypothetical
  `_releases.md` per reviewer first pass §6.4) without recompiling
  every helper.

**Hard-coded:**
- The filename regex for entry files (e.g., `^BD-\d+\.md$`). Hard-
  coded because the regex is part of the v10 grammar and changes
  trip V3.1-DELTA §3 A2.
- The lifecycle states admitted (e.g., Open / Resolved / Deferred /
  Cancelled / Deprecated for pack BD). Hard-coded because the state
  vocabulary is V3.3-DELTA §6.3 territory and changes are out of
  scope for this design.
- The entry-grammar field labels (Type / Status / etc.). Hard-coded
  by V3.1-DELTA §3 A2.

**Rationale for split:** the supporting-file list is the only part
of `_rules.md` that is plausibly project-extensible (a client might
add a `_format.md` analog for their own backlog convention; the
helpers would tolerate it). The other parts of `_rules.md` are
contract-stable; hard-coding them prevents accidental client
divergence from breaking the helpers.

**Behavior when `_rules.md` is internally inconsistent:** the
helpers consume the supporting-file basename list. If a client edits
the list to declare a basename the helpers don't know how to handle
(e.g., a hypothetical `_quotas.md` with no generator path), the
helpers SKIP the unknown basename — they do not crash, they do not
emit it into the mirror; they treat it as "extra file in the
directory, not part of any contract path." This is the same
"non-matching file ignored" behavior reviewer first pass §5.8 Gap C
option (c) suggested for entries; applying it to supporting files
is consistent.

**This integration architect's commitment:** the planner pass
schedules the planner-implementation in BD-164; this design names
the runtime-read scope (supporting-file basenames only) so the
planner does not over-build. The hard-coded values live in shared
constants near the top of `scripts/lib/<helper>.sh` (planner picks
the file name).

### §7.6 — Updated write-path contract

**Replaces sidecar §7.2.** A "write" to a stream is now defined as:

1. Pack Chat / PM Chat (or scoped agent) writes one or more
   per-entry files in a session.
2. Pack Chat / PM Chat invokes the regenerator (mirror + TOC)
   explicitly before staging.
3. Pack Chat verifies and stages all changed files atomically
   (per-entry edits + regenerated mirror + regenerated TOC).
4. Pack Chat commits per existing protocol.
5. CI gate (Check 32 + Check 33) enforces mirror+TOC in-sync at push
   time.

**The atomicity property is preserved** (sidecar §7.2's intent —
mirror and per-entry edits land in the same commit) — the
mechanism shifts from "after-every-write" automation to "before-
staging" explicit invocation.

**Side benefit:** Pack Chat retains explicit awareness of the
regenerator step, which makes it discoverable in the commit log
(the commit message can name "regenerated /.backlog/_toc.md +
/BACKLOG.md mirror" as part of the change description). This
strengthens Goal 1 discoverability — agents reading recent commits
see the regeneration pattern explicitly.


---

## §8 — Identify-only items §5.a–§5.r (disposition + per-item detail)

The sidecar addendum §5 enumerated 18 identify-only items the
sidecar architect deferred to this integration architect. This
section disposes each: DESIGN (resolution), INVENTORY (complete
list), TRADEOFF (cost we accept), or REDESIGN-CORE (overturn a
sidecar locked decision).

### §8.0 — Disposition table

| Item | Topic | Disposition | Section |
|---|---|---|---|
| §5.a | Workflow discovery of `_rules.md` | DESIGN | §4 unified treatment + §8.1 |
| §5.b | `_toc.md` runtime invocation | REDESIGN-CORE (commit-time) | §7 + §8.2 |
| §5.c | Mirror generator runtime invocation | REDESIGN-CORE (commit-time) | §7 + §8.3 |
| §5.d | Stale-mirror / stale-TOC detection | DESIGN | §5.4 + §8.4 |
| §5.e | Concurrent-write safety | DESIGN | §7.4 + §8.5 |
| §5.f | Cross-reference integrity | DESIGN | §11 + §8.6 |
| §5.g | Test fixture migration impact | INVENTORY | §12 + §8.7 |
| §5.h | Validator new-checks needed | DESIGN | §10 + §8.8 |
| §5.i | Read-site audit completeness | DESIGN | §4.4 + §8.9 |
| §5.j | Skill update inventory | DESIGN | §4.4 + §8.10 |
| §5.k | STATUS.md interaction | DESIGN | §5.3 + §5.5 + §8.11 |
| §5.l | Pattern B archive sweep impact | DESIGN | §14 + §8.12 |
| §5.m | Customization-preserve at per-entry | TRADEOFF | §13 + §8.13 |
| §5.n | BD-161 absorption | DESIGN | §17.2 + §8.14 |
| §5.o | Diffability / git history | TRADEOFF | §15 + §8.15 |
| §5.p | `.pack-tracker/` vs `/.backlog/` namespace collision | DESIGN | §8.16 |
| §5.q | init-project.sh greenfield path | DESIGN | §9.5 + §8.17 |
| §5.r | Backup and rollback under non-reversible migration | DESIGN | §9.4 + §8.18 (with §3.2 typo correction) |

### §8.1 — §5.a (Workflow discovery of `_rules.md`)

**Disposition: DESIGN.** Treated in §4 unified treatment.

Three layered discoverability mechanisms (§4.2): trinity Key files
pointer + per-entry HTML-comment back-pointer + `stream-discovery`
skill loaded by pack-startup / pm-startup. Recovery from context-
window drop (§4.3): triple redundancy ensures recovery via 1–2 Read
calls regardless of which mechanism failed.

`_rules.md` is read at runtime by the mirror generator and `_toc.md`
regenerator for the supporting-file basename list ONLY (§7.5). All
other contract values are hard-coded.

### §8.2 — §5.b (`_toc.md` runtime invocation)

**Disposition: REDESIGN-CORE.** Sidecar §5.b enumerated three
plausible triggers (writer-side / pre-commit / migrator-only) and
deferred to planner. This integration architect picks **commit-time
explicit invocation by Pack Chat / PM Chat** per §7.3.

Rationale per §7.1: writer-side fails Goal 1 (memorizable rule that
will be forgotten) and Goal 2 (no detection mechanism). Pre-commit
hook adds infrastructure complexity. Migrator-only is unworkable
for inter-migration sessions (sidecar §5.c noted this).

### §8.3 — §5.c (Mirror generator runtime invocation)

**Disposition: REDESIGN-CORE.** Same model as §8.2 — commit-time
explicit invocation. Both mirror generator and `_toc.md` regenerator
share the same trigger surface (per sidecar §5.c) and fire together
(per sidecar §7.2 atomicity, preserved in §7.6 of this doc).

### §8.4 — §5.d (Stale-mirror / stale-TOC detection)

**Disposition: DESIGN.** Treated in §5.4. Two-mechanism solution:
- `validate-pack.py` Check 32 (mirror-in-sync) + Check 33
  (TOC-in-sync) at CI time enforce the invariant.
- Silent overwrite at next regeneration (per sidecar §5.d option 1)
  preserves Goal 2 without user-confirmation prompts.

The combination preserves Goal 2 strictly. See §10 below for full
Check 32 + 33 + 34 specifications.

### §8.5 — §5.e (Concurrent-write safety)

**Disposition: DESIGN.** Treated in §7.4. No new mechanism required:
git's normal merge-conflict mechanism handles the per-entry case
identically to (and finer-grained than) the v10.1 monolithic case.
The migrator already serializes against the working tree.

### §8.6 — §5.f (Cross-reference integrity)

**Disposition: DESIGN.** Treated in §11. New `validate-pack.py`
Check 34 (cross-reference integrity) detects dangling
`Blockers: BD-NNN` / `Unblocks: TD-NNN` / inline cross-reference
syntax that points at non-existent entry files. CI-time gate.

The sidecar addendum §5.f noted that today, dangling references in
the monolithic BACKLOG.md are grep-detectable in one pass; under
decomposition, the grep happens across N files but the operation is
the same shape (single grep pattern, all matches). Check 34 makes
this CI-enforced rather than ad-hoc.

### §8.7 — §5.g (Test fixture migration impact)

**Disposition: INVENTORY.** Treated in §12.

The pre-decomposed `v11-realistic-ot` fixture (BD-160 dependency)
needs to ship with:
- A pre-decomposed `docs/project/backlog/` directory containing
  TD-NNN.md per-entry files corresponding to the OT v10 BACKLOG
  entries.
- A pre-decomposed `docs/project/implementation-plan/` directory
  containing `phase-N.md` per-phase files (no per-task files per
  addendum §2).
- A pre-decomposed `docs/project/changelog/` directory containing
  `YYYY-MM-DD-phase-NN.md` per-entry files.
- The supporting files (`_rules.md`, `_intro.md`, `_format.md`,
  empty seed `_toc.md`) per stream.
- The regenerated mirrors at `docs/project/BACKLOG.md`,
  `IMPLEMENTATION-PLAN.md`, `CHANGELOG.md` byte-identical to the
  v11.0-shape monolithic files.

`test-fixtures/build.sh` (per `README.md:227`) extends with a
`v11-realistic-ot` builder case that:
1. Reads the v10-realistic-ot monolithic shape.
2. Runs the decompose helper against it (the same library helper
   the v10→v11 migrator's `_v10_to_v11_decompose_streams` uses —
   per BD-165).
3. Writes the per-entry tree + supporting files + regenerated
   mirrors.
4. Verifies byte-identity round-trip.

This is mechanically the same operation BD-160 already needed to do
(extend `_build_realistic_for_version v11` per pack `BACKLOG.md:1399`).
BD-170 owns the extension and its blocker is BD-164 (the decompose
helper must exist before the fixture builder can call it).

**No fixture deletion needed.** The v10-realistic-ot fixture stays;
it represents the v10.1 source state for the v10→v11 migrator
behavior-preservation harness. The v11-realistic-ot fixture is the
target state.

### §8.8 — §5.h (Validator new-checks)

**Disposition: DESIGN.** Treated in §10. Three new checks: Check 32
(mirror-in-sync), Check 33 (TOC-in-sync), Check 34 (cross-reference
integrity). All three are STRUCTURAL signal-4 trips per the
maintainability principle; THIS architect pass IS the defense per
the principle's "architect-pass-then-add" requirement.

The sidecar's addendum §5.h candidate list also named:
- `_rules.md` exists per stream directory — folded into Check 32's
  pre-check (the mirror generator can't run without `_rules.md` per
  stream per §7.5; missing `_rules.md` is detected at the start of
  Check 32, FAIL with "missing `_rules.md` for stream X").
- Per-entry filename conformance — folded into Check 32's pre-check
  (the mirror generator parses files matching the entry-regex; any
  file in the stream directory that doesn't match the regex AND
  isn't in the supporting-file basename list is FAIL with
  "non-conforming filename").
- `_v8-resolved-archive.md` byte-stable — folded into Check 32
  (the v8 archive is part of the regenerated mirror's frozen tail
  per addendum §3.6; if it differs from the on-disk archive, Check
  32 catches it as a mirror-divergence on the trailing block).

**Net: three new check functions, not six.** Three is the minimum to
enforce the invariants; folding the rest reduces validator surface
without losing coverage.

### §8.9 — §5.i (Read-site audit completeness)

**Disposition: DESIGN.** Treated in §4.4. Complete inventory across
20 distinct edit sites; classified into "stays" / "one-line addition"
/ "targeted prose addition." All scheduled into BD-169.

### §8.10 — §5.j (Skill update inventory)

**Disposition: DESIGN.** Treated in §4.4.2. Six skill files
(canonical pack-startup + per-CLI mirrors × 2 paths; canonical
pm-startup + per-CLI mirrors × 2 paths) plus the new
`stream-discovery` skill (one canonical SKILL.md plus per-CLI
distribution). Active-skills line additions only; no other change.

### §8.11 — §5.k (STATUS.md interaction)

**Disposition: DESIGN.** Treated in §5.3 (disclaimer requirement)
and §5.5 (recommendation-system signal collection). STATUS.md does
not source-of-truth; the disclaimer makes it explicit; the
recommendation-system continues to read the regenerated mirror per
sidecar §16.5 ratification.

### §8.12 — §5.l (Pattern B archive sweep impact)

**Disposition: DESIGN.** Treated in §14.

Pattern B sweeps workflow artifacts (`ARCHITECTURE-*.md` /
`PLAN-*.md` etc.) to `maintenance-docs/archive/vN/` at version
ship. The per-entry tree directories `/.backlog/`, `/.changelog/`,
`docs/project/backlog/`, etc. are NOT workflow artifacts — they are
live-state directories carrying the current pack/project shape.
**Pattern B does NOT sweep them.** The sweep rule's location filter
already excludes them (per the existing CLAUDE.md:174-183 wording —
the rule names file-suffix patterns, not directories), so no rule
edit is required. This integration architect verifies the existing
rule does not accidentally apply.

The pack `_v8-resolved-archive.md` file inside `/.backlog/` is
**not** swept (it lives inside a non-archive directory; Pattern B
operates at the maintenance-docs/ scope per the rule's intent
expressed in `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` §3
worked examples).

**No CLAUDE.md edit required for Pattern B.** Confirmed in §14
treatment.

### §8.13 — §5.m (Customization-preserve at per-entry granularity)

**Disposition: TRADEOFF.** Treated in §13.

Sidecar §9.1 routes per-entry files through the existing `generic`
class. The reviewer first pass §1.3 / §6.6 noted the worst-case
scenario: a user's customization spanning what would become two
separate per-entry files generates a harder merge under
decomposition than under monolithic.

**This integration architect ratifies the sidecar's `generic` class
choice and acknowledges the worst-case as accepted cost.** The
worst case is rare in practice (cross-entry customizations are
unusual; per-entry customizations are the common case and decompose
*better* under per-entry granularity per sidecar §9.1 point 2). The
truthful BD-088 report surfaces any merge that the user must
reconcile — the user has visibility, even if the visibility is
"diff is split across two files" rather than "diff is in one file."

The cost we accept: cross-entry refactor merges fan out across
multiple files. The benefit we get: per-entry merges are cleaner.
The fan-out is worse-case for refactors that intentionally span
entries; the cleanness is better-case for the common single-entry
edit. Net positive on average; acknowledged worst-case loss for
refactors.

### §8.14 — §5.n (BD-161 absorption)

**Disposition: DESIGN.** Treated in §17.2.

BD-161 (per pack `BACKLOG.md:1388` "v10→v11 migrator: install
net-new v11 SKILL.md dirs (BD-156/157/158 + python-server-
architecture / python-data-architecture split)") is **absorbed
into BD-167** in the new v11.0 batch (Batch 18). Both touch the
v10→v11 migrator's post-dispatch hook; both ship in the same
commit; the post-report advisory paragraph names both
operations together.

The two operations remain distinct in the implementation:
- BD-161's net-new SKILL.md dirs install via the existing
  `_v10_to_v11_install_v11_artifacts` step (per
  `migrate-v10-to-v11.sh:146`, currently 3rd in the sequence).
- BD-165's decompose step is the new 6th step per §3.1 above.

They are absorbed at the BD-tracking level (one BD covers both
client artifact installs in v11.0 — BD-167) but remain separate
implementation steps in the migrator.

### §8.15 — §5.o (Diffability / git history)

**Disposition: TRADEOFF.** Treated in §15.

Per-entry decomposition trades:
- BETTER per-entry git blame: an entry's full edit history is the
  file's history, not a sub-region of a 3,627-line file.
- BETTER per-entry PR review: each entry edit is one file diff,
  reviewable in isolation.
- WORSE cross-entry refactor history: a multi-BD refactor is N
  file edits + 1 mirror regeneration + 1 TOC regeneration; PR
  review surface fans out; `git log --follow` per entry works but
  cross-entry queries require multi-file walking.

This is structural to the decomposition shape; no fix is possible
without re-monolithic-izing. The trade-off is accepted per Pack
Chat user direction (v11.0 lock + non-reversible).

**One recovery path for cross-entry refactor PR review:** the
regenerated mirror's diff in any commit IS the cross-entry view
(since it includes every entry change in deterministic sort order).
A reviewer who wants the cross-entry refactor view reads the mirror
diff in that commit. The view exists; it's in the regenerated file
rather than in a single source file.

### §8.16 — §5.p (`.pack-tracker/` vs `/.backlog/` namespace collision risk)

**Disposition: DESIGN.** Resolved here.

Sidecar §5.p named the question: should `/.backlog/` presence be a
detection signal for v11.0+ status, or do `tracker.toml`
template_version + README version table suffice?

**Resolution: `tracker.toml` template_version + README version table
ARE sufficient.** No new detection signal required.

Rationale:
- The v11.0 lock + non-reversible migration property (addendum §1)
  means: any client at v11.0+ has been through the v10→v11 migrator,
  which sets `[migration] forward_complete = true` (per BD-131) and
  installs v11 artifacts (per BD-161 / BD-167). Both signals already
  flag v11.0+ status reliably.
- Adding `/.backlog/` presence as a detection signal would create a
  new code path in `scripts/lib/detect.sh` that would have to be
  cross-validated against the existing signals — extra surface, no
  new detection capability.
- Per-entry tree is INSIDE the v11.0+ install; checking for the
  install (existing detection) implies the per-entry tree is
  present.

**No `detect.sh` change.** Existing detection paths in
`scripts/lib/detect.sh`, `tracker-config.sh`, `recommendation.sh`
are unchanged.

**Namespace collision check.** `/.backlog/` and `.pack-tracker/`
are both leading-dot pack-state directories; both gitignore-
relevant per the existing patterns. No collision: different names,
different purposes. The leading-dot convention applies consistently.

### §8.17 — §5.q (init-project.sh greenfield path)

**Disposition: DESIGN.** Treated in §9.5.

`scripts/init-project.sh` extends to install the per-entry tree
skeleton on greenfield projects via BD-166. The planner picks
between extending the existing `stage_s11_v11_artifacts` (line 803
per direct verification) or adding a new `stage_s11b_per_entry_tree`.
This integration architect's recommendation is **extend S11** —
the per-entry tree is one more set of v11 client artifacts, fits
the existing stage's purpose, and avoids adding a new stage (one
fewer stage in the init flow is one less thing to reason about).
Planner-final.

The greenfield install ships:
- `docs/project/backlog/_rules.md`, `_intro.md`, empty seed
  `_toc.md`. No entry files (greenfield project starts empty).
- `docs/project/implementation-plan/_rules.md`, `_intro.md`, empty
  seed `_toc.md`. No phase files.
- `docs/project/changelog/_rules.md`, `_intro.md`, `_format.md`,
  empty seed `_toc.md`. No entry files.
- The regenerated empty mirrors at `docs/project/BACKLOG.md`,
  `IMPLEMENTATION-PLAN.md`, `CHANGELOG.md` — each containing only
  `_intro.md` content (the entry sort order is empty; the v8-archive
  and format-rules concatenations apply per stream).

The mirror regenerator runs as the final step of the stage to
produce the empty mirrors. No special "greenfield empty mirror"
template — the regenerator handles empty input naturally.

**Pack-self side parallel concern (sidecar §5.q):** the pack
repo's `/.backlog/` is created by the v10.1→v11.0 migration of
pack-self, NOT by `init-project.sh`. Sidecar correctly named this;
this integration architect confirms: pack-self migration uses the
same v10→v11 migrator (Pack Chat runs `bash scripts/migrate-v10-to-v11.sh`
against the pack repo itself per Batch 22 of `EXECUTION-PLAN-V11.0.md`
— BD-102 dog-food). Same code path; no separate pack-self bootstrap.

### §8.18 — §5.r (Backup and rollback under non-reversible migration)

**Disposition: DESIGN.** Treated in §9.4.

**Citation correction acknowledgement:** sidecar §5.r cites
`scripts/lib/migrator-core.sh:146`; correct location is
`scripts/lib/migrator-stages.sh:146` (verified). Cited correctly
herein.

The `_stage_backup` step at `migrator-stages.sh:146` creates a
full working-tree backup before any mutation (per the function
body at `migrator-stages.sh:146-185` — verified). Under the v11.0
non-reversible decomposition, the backup is the only path back to
monolithic-as-source state.

**Resolution:** the existing backup contract IS sufficient with
ONE prose addition.

The existing backup mechanism (`_stage_backup` at
`migrator-stages.sh:146`) preserves the entire working tree
(excluding `.git/`, state dirs, backup dirs, `.pack-update`).
That includes the monolithic `BACKLOG.md` / `CHANGELOG.md` /
`IMPLEMENTATION-PLAN.md` files at their pre-migration shape.
A user who wants to revert to monolithic-as-source state:
1. Discards the v11 working tree
   (`git reset --hard <pre-migration-commit>` if working in git, OR
   restore from `.pack-migrate-v10-to-v11-backup/`).
2. Restores from the backup directory (the framework documents this
   in the post-report hook per the existing v10→v11 adapter shape).

The ONE prose addition: the post-report hook (per
`scripts/lib/migrator-core.sh` — required hook
`migrator_post_report_hook`) needs a paragraph explaining that
v11.0 decomposition is non-reversible and the backup is the
rollback path. Sample shape (planner refines):

```
v11.0 introduces per-entry decomposition of BACKLOG / CHANGELOG /
IMPLEMENTATION-PLAN. The per-entry tree under /.backlog/, /.changelog/,
docs/project/<stream>/ is the new source of truth from this
migration forward. The monolithic files (BACKLOG.md, CHANGELOG.md,
IMPLEMENTATION-PLAN.md) are now regenerated mirrors — read-stable
but not source-of-truth.

If you want to revert to the v10 monolithic-as-source shape:
1. Remove the v11 per-entry trees and the regenerated mirrors:
   rm -rf /.backlog /.changelog docs/project/backlog
   docs/project/implementation-plan docs/project/changelog
   BACKLOG.md CHANGELOG.md docs/project/BACKLOG.md
   docs/project/IMPLEMENTATION-PLAN.md docs/project/CHANGELOG.md
2. Restore from the backup:
   cp -R .pack-migrate-v10-to-v11-backup/* .
3. The pre-migration v10 state is restored. Re-running
   migrate-v10-to-v11.sh will re-decompose.
```

This text lives in the v10→v11 adapter's `migrator_post_report_hook`
(which already exists per the framework contract at
`scripts/lib/migrator-core.sh:229-231` — required hook). The planner
schedules the addition as part of BD-165's post-dispatch+post-report
implementation.

**Backup directory naming under v11.0 decomposition.** The existing
backup directory naming (`.pack-migrate-v10-to-v11-backup/` per the
framework convention) is unaffected. The backup's contents now
include the monolithic files; the v11 install creates the per-entry
tree on top. Restore is the inverse.


---

## §9 — Migrator integration (v10→v11.0 mandatory non-reversible)

### §9.1 — Hook integration restated for the planner

Per §3.1 of this doc, the v10→v11 migrator's existing
`migrator_post_dispatch_hook` at
`scripts/migrate-v10-to-v11.sh:134-149` gains a 6th sub-operation
performing the per-entry decomposition + initial mirror+TOC
regeneration. Constraint: must run AFTER the existing 5
sub-operations (BD-104 rename, BD-042 relocation, v11 artifact
install, BD-144 capability-token translation, python-architecture
ref rename) so the decompose step reads the final v11-shape
monolithic files.

The planner picks: function name (provisional `_v10_to_v11_decompose_streams`
per sidecar §1.3), exact position in the call list, file location
(under `scripts/lib/migrate-v10-to-v11/decompose.sh` per the
existing adapter-private lib subdirectory convention).

The framework contract (`scripts/lib/migrator-core.sh`,
`migrator-stages.sh`, `migrator-manifest.sh`) is **unchanged**.
The sidecar §10.1 promise is preserved: "This design does not add a
new hook." The new sub-operation lives inside the existing optional
post-dispatch hook.

### §9.2 — Manifest implications

The migrator manifest (per `migrator-manifest.sh:118` vocabulary
`transform | add | remove | relocate-from`) does NOT change.

Per sidecar §10.3, the monolithic file remains the manifest entry
(class `generic`); the decompose helper runs adapter-private,
post-dispatch, after the manifest's 3-way text dispatch has
preserved the user's customizations on the monolithic file. The
decomposition then operates on the merged monolithic file (the
output of 3-way dispatch), so customizations land in the
appropriate per-entry files automatically.

**No new manifest entries.** The per-entry files are not in the
manifest; they are produced by the decompose step's output. The
mirror is regenerated by the decompose step's final regenerator
call.

### §9.3 — `init-project.sh` greenfield path

Per §8.17 above. BD-166 extends `stage_s11_v11_artifacts` (per
init-project.sh line 803) to install the empty per-entry tree
skeleton + supporting files + regenerated empty mirrors.

The greenfield install is symmetric to the v10→v11 migration: same
helper (`scripts/lib/<helper>.sh` mirror generator + `_toc.md`
regenerator + decompose helper called against an empty input). The
helper reuse is the architect-pass payoff — one decompose helper
serves three call sites (v10→v11 migrator, init-project.sh,
tracker mode transitions).

### §9.4 — Backup and rollback (resolves §5.r)

Per §8.18 above. The existing `_stage_backup` at
`migrator-stages.sh:146` creates the backup (verified — the
function captures the entire working tree excluding `.git/` +
state dirs). The post-report-hook advisory paragraph (sample text
in §8.18) explains the rollback path under v11.0 non-reversible
decomposition.

**Citation correction acknowledgement:** addendum §5.r cites
`migrator-core.sh:146`; correct location is
`migrator-stages.sh:146`. Cited correctly herein. (Repeated for
emphasis; future readers see the corrected citation in any of
§3.2, §8.18, or this section.)

### §9.5 — Namespace collision risk (§5.p) — resolved no-op

Per §8.16 above. `tracker.toml` template_version + README version
table are sufficient v11.0+ detection signals. No `detect.sh`
change required. `/.backlog/` and `.pack-tracker/` are
non-colliding leading-dot directory names with distinct purposes.

### §9.6 — Sequencing inside the v10→v11 hook

Restated for the planner (per §3.1):

The architect-pass constraint is: decompose runs AFTER all
monolithic-content mutations have settled. Concretely the planner
implementation order is:

1. `_v10_to_v11_rename_implementation_plan` (BD-104 rename)
2. `_v10_to_v11_relocate_legacy_docs` (BD-042 relocation)
3. `_v10_to_v11_install_v11_artifacts` (additive v11 installs incl.
   BD-161 net-new SKILL.md dirs absorbed via BD-167)
4. `_v10_to_v11_rename_python_architecture_refs` (BD-144 part 1)
5. `_v10_to_v11_translate_capability_tokens` (BD-144 part 2)
6. NEW `_v10_to_v11_decompose_streams` (this design — BD-165) —
   reads the final v11-shape monolithic files; emits per-entry
   tree + supporting files + regenerated mirrors.

Steps 1–5 are verified at `migrate-v10-to-v11.sh:144-148` in this
exact order. Step 6 is the addition.

The planner chooses the function name; the integration architect
provides the constraint statement and the sequencing requirement.

### §9.7 — `_intro.md` and `_v8-resolved-archive.md` initial install

Per §3.3 of this doc, `_intro.md` is pack-shipped immutable. On the
v10→v11 migration:
- The decompose step reads the source monolithic file's preamble
  (e.g., pack `BACKLOG.md:1-7` "All planned improvements …" + lines
  9-20 "How to use this file") AND extracts that content to write
  `_intro.md` AT THE FIRST MIGRATION ONLY.
- Subsequent pack version-bump migrations (a hypothetical
  v11→v12) ship a fresh `_intro.md` from the pack template via
  the existing `customization-preserve.sh` `generic` class — the
  user's edits surface in the truthful BD-088 report.

**Concretely on v10→v11:** the source content for pack
`/.backlog/_intro.md` IS `BACKLOG.md:1-20` from v10. The decompose
step extracts those 20 lines into `_intro.md`; subsequent
regenerations re-emit them at the top of the regenerated mirror.
Byte-identity preserved: `BACKLOG.md:1-20` (v10) ==
`_intro.md` (v11) → regenerated `BACKLOG.md:1-20` (v11).

For pack `/.backlog/_v8-resolved-archive.md`: the decompose step
reads the source `BACKLOG.md` from the `## Resolved — v8 (March
2026)` H2 line through the next H2 (or EOF) and writes it to
`_v8-resolved-archive.md`. Subsequent regenerations re-emit it
at the trailing position of the regenerated mirror. Byte-identity
preserved.

For project-side `_intro.md` and `_format.md` (the project-side
case), the decompose step's source content comes from the project's
`docs/project/BACKLOG.md` / `IMPLEMENTATION_PLAN.md` /
`CHANGELOG.md` preambles (per `RESEARCH-PER-ENTRY-SPLIT.md` §3
analogous line ranges). Extraction shape is identical.

**Pack-product canonical templates (project-side):** for greenfield
projects (init-project.sh per §9.3), the `_intro.md` and `_format.md`
ship from `project-template/docs/project/<stream>/_intro.md` and
`_format.md`. These canonical templates are written into the pack
repo as part of BD-167 implementation (the planner schedules; the
coder authors the canonical template content based on the
v10-realistic-ot project preambles per `RESEARCH-PER-ENTRY-SPLIT.md`
§3 sample inventory).


---

## §10 — Validator new-checks (resolves §5.h)

This integration architect commits the design to three new
`validate-pack.py` checks. Each is a STRUCTURAL signal-4 trip per
the maintainability principle; THIS architect pass IS the defense.

### §10.1 — Check 32 (mirror-in-sync)

**Purpose:** enforce Goal 2 source-of-truth invariant — the
regenerated mirror is byte-identical to what the mirror generator
would produce from the per-entry tree.

**Function shape:**
```python
def check_mirror_in_sync() -> None:
    print("\n── Check 32: per-entry mirror is in-sync with per-entry tree ──")
    for stream in STREAMS:  # 5 streams: pack/.backlog, pack/.changelog,
                             # project/docs/project/{backlog,implementation-plan,changelog}
        if not (REPO_ROOT / stream).exists():
            ok(f"{stream} — not present (skipping; may be pre-v11.0 client)")
            continue
        # Pre-check: _rules.md exists.
        rules = REPO_ROOT / stream / "_rules.md"
        if not rules.exists():
            fail(f"{stream}/_rules.md missing — required for v11.0 per-entry contract")
            continue
        # Pre-check: every non-supporting file matches the entry-regex.
        # (Hard-coded entry regex per stream, per §7.5; supporting-file
        # basename list ALSO hard-coded for the validator path because
        # the validator is not the runtime-extension surface.)
        unknown = list_unknown_files(stream)
        if unknown:
            fail(f"{stream}: non-conforming filenames: {unknown}")
            continue
        # Main check: regenerate mirror to a temp file; diff against
        # the on-disk mirror at the canonical path.
        temp_mirror = regenerate_mirror_to_temp(stream)
        canonical_mirror = canonical_mirror_path(stream)
        if not files_byte_identical(temp_mirror, canonical_mirror):
            fail(f"{canonical_mirror} is out of sync with {stream}/ —"
                 f" run mirror regenerator before committing")
            continue
        ok(f"{stream} → {canonical_mirror.name} byte-identical")
```

**Failure mode:** developer hand-edited the mirror, OR forgot to
invoke the regenerator before committing.

**Recovery:** run the mirror regenerator (named in the FAIL message)
and re-commit.

**Cost:** runs the regenerator once per stream (5 streams) at CI
time. Per §7.2 cost calculation, ~1.5 sec for v11.0 baseline; ~10
sec at v13 scale. CI tolerable.

**Defense vs maintainability signal 4:** required to enforce Goal 2.
THIS architect pass is the defense. Pre-check folding (no separate
checks for `_rules.md` existence or filename conformance) keeps the
validator surface minimal.

### §10.2 — Check 33 (TOC-in-sync)

**Purpose:** enforce that `_toc.md` is in-sync with the per-entry
tree.

**Function shape:** same as Check 32 but for `_toc.md`. Regenerate
to temp, diff against on-disk, FAIL on divergence.

**Failure mode:** developer hand-edited `_toc.md`, OR forgot to
invoke the TOC regenerator.

**Recovery:** run the TOC regenerator and re-commit.

**Cost:** parses the per-entry tree once per stream at CI time.
Same shape as Check 32.

### §10.3 — Check 34 (cross-reference integrity)

**Purpose:** detect dangling cross-references in entry content.

Per addendum §5.f, entries reference each other via:
- `Blockers: BD-NNN, TD-NNN` (per V3.3-DELTA §5.3 lines 256–279)
- `Unblocks: BD-NNN, TD-NNN`
- Inline prose references (e.g., "per BD-160" or "see BD-088")

**Function shape:**
```python
def check_cross_reference_integrity() -> None:
    print("\n── Check 34: cross-reference integrity ──")
    # Collect all defined IDs across all 5 streams' entry files.
    defined = collect_all_entry_ids()  # set of "BD-160", "TD-001",
                                        # "v11.0", "phase-3", etc.
    # Walk every per-entry file; extract Blockers / Unblocks / inline
    # references; report any reference that is not in `defined`.
    # Skip references in v8-archive (that block is frozen-historical).
    for stream in STREAMS:
        for entry_file in list_entry_files(stream):
            refs = extract_references(entry_file)
            for ref, line_no in refs:
                if ref not in defined:
                    fail(f"{entry_file}:{line_no} references {ref} —"
                         f" no matching entry file found")
```

**Defined IDs:** every entry file's filename (without `.md`) is the
ID — `BD-160.md` → `BD-160`. The set includes BD-NNN, TD-NNN,
vN.M, phase-N. Project-side IDs are scoped to the project tree;
pack-side to the pack tree. Cross-stream references (e.g., a pack
BD referencing a project TD) are out of scope — the project tree
isn't loaded by the pack-repo validator.

**Failure mode:** developer renamed a file, deleted an entry, or
typo'd an ID in a cross-reference.

**Recovery:** fix the reference (or restore the missing entry).

**Cost:** O(N) entry files per stream, O(M) refs per entry — at
v11.0 baseline ~150 files × ~3 refs = 450 refs to check, each one
an O(1) set lookup. Sub-second total. CI tolerable at every scale.

**Defense vs maintainability signal 4:** required because addendum
§5.f explicitly named the integrity question as identify-only and
this integration architect's resolution is "validate at CI time."
THIS architect pass is the defense.

### §10.4 — Why three checks, not one parameterized check

The sidecar §5.h candidate list named six possible checks (mirror-
in-sync, TOC-in-sync, _rules.md exists, per-entry filename
conformance, cross-reference integrity, _v8-resolved-archive.md
byte-stable).

This integration architect folds to three by:
- `_rules.md` exists → Check 32 pre-check.
- Per-entry filename conformance → Check 32 pre-check.
- `_v8-resolved-archive.md` byte-stable → covered by Check 32
  (the v8 archive is part of the regenerated mirror's trailing
  block; if it differs, Check 32 catches the mirror divergence).

Three function definitions; each one focused on a distinct
invariant. Easier to read, easier to debug, easier to extend.

### §10.5 — Validator behavior on missing per-entry tree

If a client repo at v10.1 baseline (no per-entry tree) is
validated, Checks 32/33/34 SKIP gracefully (the `if not (REPO_ROOT
/ stream).exists():` guard returns "not present (skipping; may be
pre-v11.0 client)"). This preserves backward-compatibility for
pre-v11.0 clients. After v11.0 migration, the per-entry trees
exist and the checks fire.

For the pack repo itself: pack-self goes through the v10→v11
dog-food migration in Batch 22 of `EXECUTION-PLAN-V11.0.md`. After
that batch, `/.backlog/` and `/.changelog/` exist; Checks 32/33/34
fire on every push thereafter. Before Batch 22, the checks SKIP
(no per-entry trees yet on pack repo).

### §10.6 — Pack-side vs project-side validator scope

`validate-pack.py` runs in pack repo CI. Pack-side streams
(`/.backlog/`, `/.changelog/`) are validated. Project-side streams
(`docs/project/<stream>/`) are NOT validated by `validate-pack.py`
because the validator runs in the pack repo, not in client projects.

Client projects' per-entry trees are validated by:
- The mirror regenerator's idempotency (the planner-pass
  implementation of the regenerator includes a self-check: re-run
  produces byte-identical output; this is implicit at every
  invocation).
- The CI of the client project itself (if the client project ships
  its own validator, which is project-decision territory).

This is consistent with the v10.1 baseline: `validate-pack.py`
validates pack-shipped content, not client-customized content.
Decomposition does not change the validator scope.


---

## §11 — Cross-reference integrity (resolves §5.f)

### §11.1 — The integrity question under decomposition

Today (v10.1): all entry cross-references live in one file
(`BACKLOG.md`); `grep -E '\bBD-[0-9]{3}\b'` finds every reference;
human review catches dangling references.

Under v11.0 decomposition: references span N files. A rename, move,
or delete of a per-entry file silently breaks references unless
detection fires.

Sidecar §5.f named the question; this integration architect
resolves with Check 34 above (§10.3) — CI gate on dangling
references.

### §11.2 — Reference forms in scope

Per V3.3-DELTA §5.3 lines 256–279 + sidecar §5.f, the references in
scope are:
- `Blockers: BD-NNN, TD-NNN` (field; comma-separated list of IDs)
- `Unblocks: BD-NNN, TD-NNN` (field; same shape)
- `Resolved: <hash> — <date> — <prose ... BD-NNN ...>` (prose
  references inside the Resolved line)
- Inline prose references in the `Description:` body (e.g., "per
  BD-088", "see TD-001")
- Pack-side: references to `phase-N` (project-side identifier;
  out-of-scope for pack-side validation per §10.6)

Check 34 extracts these via a regex (`(?:BD|TD|phase|v)-[\d.]+`)
across each entry file's body and validates against the defined-IDs
set. Conservative: false positives (matches in code blocks or
quoted text) are tolerated; the user can suppress via a backtick-
escape if needed (planner refines).

### §11.3 — `_v8-resolved-archive.md` exception

The v8 archive contains historical references to BD-NNN entries
that may not exist in the current pack tree (those entries were
also deleted at v8 ship and are part of the frozen-historical
block). Check 34 SKIPS the v8 archive — references inside it are
historical and not subject to integrity validation.

### §11.4 — Mirror-time reference validation

Sidecar §5.f noted that today's grep happens against one file (the
monolithic mirror). This still works under v11.0: the regenerated
mirror contains all entries' content, so grep against the mirror
catches the same references as Check 34 does against the
per-entry tree. They are equivalent.

The advantage of Check 34 over "rely on the mirror grep" is that
Check 34 fires automatically in CI on every push; manual grep relies
on human discipline. Check 34 is the enforcement layer.

### §11.5 — TRADEOFF acknowledgement

The integrity check does NOT detect:
- References in commit messages (out of scope; commit messages are
  not entry content).
- References in workflow artifacts (`AUDIT-*.md`,
  `IMPLEMENTATION-REPORT-*.md`, etc.) — these reference entries by
  name but the artifacts archive at version-ship per Pattern B; a
  dangling reference in an archived artifact is acceptable.
- Cross-pack-and-project references (a pack BD referencing a
  project TD) — out of scope per §10.6.

These tradeoffs are accepted. The CI gate covers the entry-content
surface, which is the load-bearing surface. Commit messages and
workflow artifacts are reviewed at PR time (human discipline).

---

## §12 — Test fixture migration (resolves §5.g)

### §12.1 — Pre-decomposed v11-realistic-ot fixture

Per §8.7 above. The `v11-realistic-ot` fixture (per `README.md:232`,
gitignored built directory) extends to ship the per-entry tree
shape. BD-160 (per pack `BACKLOG.md:1399`) currently extends
`_build_realistic_for_version v11` to handle the v11 case dispatch;
that BD picks up the per-entry tree install as part of its work.

**This integration architect proposes BD-170** (a new BD that
explicitly extends BD-160's scope to include the per-entry tree
install). BD-170 is BLOCKED by BD-164 (the decompose helper must
exist before the fixture builder can call it) and BLOCKED by BD-160
(which lands first to set up the v11 case dispatch).

Sequencing:
1. BD-164 ships the decompose helper.
2. BD-160 ships the v11 case dispatch in `_build_realistic_for_version`.
3. BD-170 extends BD-160's v11 case to call the decompose helper
   per stream + write supporting files + regenerate mirrors.

All three land in Batch 18 (per §17 below).

### §12.2 — Existing fixtures preserved

`v10-minimal/`, `v10-realistic-ot/`, `v11-flat-file/`,
`v11-tracker-on/`, `existing-project-mid-dev/` (per `README.md:230-233`)
all stay. Their semantics:
- `v10-minimal/` and `v10-realistic-ot/` represent the v10.1
  source state for v10→v11 migrator behavior preservation.
- `v11-flat-file/` and `v11-tracker-on/` represent the v11.0 target
  state. Under v11.0 decomposition, `v11-flat-file/` ships with the
  per-entry tree present. `v11-tracker-on/` ships with the per-entry
  tree present + tracker enabled (per Mode 3, the per-entry tree is
  tracker-mirrored read-only per §5.6).
- `existing-project-mid-dev/` represents a non-pack-shipped client
  project; greenfield init applies; no decomposition impact (the
  fixture is for testing init-project.sh's existing-project path).

### §12.3 — Fixture build command

Per `README.md:227`, `test-fixtures/build.sh --all --clean` rebuilds
all fixtures deterministically. Under v11.0:
- Building `v11-realistic-ot/` invokes the decompose helper as part
  of the per-entry tree install.
- Building `v11-flat-file/` does the same against an empty source
  (greenfield path).
- Building `v11-tracker-on/` invokes both the decompose helper and
  the tracker init flow.

The build script's deterministic-rebuild property is preserved
because the decompose helper is deterministic (sidecar §6.2
idempotency contract).

### §12.4 — Manifest expectations

`test-fixtures/manifest.txt` (per `README.md:228`) carries expected
git SHAs per fixture. Under v11.0, the v11-realistic-ot fixture's
SHA changes when the decompose helper changes (which it might,
during BD-164's iteration). The manifest is regenerated as part of
the fixture build; the planner schedules manifest re-generation
into BD-170's verification step.

### §12.5 — BD-128 CI repair interaction

`EXECUTION-PLAN-V11.0.md` Batch 6 (BD-128) repairs CI test-suite —
including the v10-realistic-ot fixture build path. BD-128 lands
BEFORE Batch 18 per the existing batch sequence (Batch 6 < Batch
18). When Batch 18 fires, the v10-realistic-ot build path is
green; the v11-realistic-ot extension (BD-170) builds on top of a
known-good v10-realistic-ot.


---

## §13 — Customization-preserve verification (resolves §5.m)

### §13.1 — Sidecar §9.1 ratified

The integration architect ratifies sidecar §9.1: per-entry tree
paths route through the existing `generic` class in
`scripts/lib/customization-preserve.sh` (verified at lines 145–179
with `*) printf 'generic\n' ;;` fall-through at line 178). No new
classifier rows. No new dispositions.

### §13.2 — Worst-case acknowledgement (per reviewer §6.6)

The reviewer first pass §6.6 noted that sidecar §9.1's
"smaller files diff more cleanly" framing is true on average but
wrong in the worst case. The integration architect explicitly
acknowledges:

**Worst case:** a user's customization spans what would become two
separate per-entry files (e.g., the user added prose to BD-100's
Description that references BD-200's Resolved line, AND
hand-formatted both as a coherent block in the v10.1 monolithic
BACKLOG.md). Under decomposition, that single human-coherent
customization is split across BD-100.md and BD-200.md;
customization-preserve's 3-way text dispatch operates on each file
independently; reconciling the cross-file customization requires
manual intervention.

**Frequency:** rare. Cross-entry customizations are unusual in
practice; most customizations are confined to one entry. The
v10.1 monolithic case has the same difficulty in the opposite
direction (single-entry merges happen in a 3,627-line file context
window, which is harder to navigate than a 30-line single-file
context).

**Mitigation:** the BD-088 truthful migration report surfaces both
files' merge state. The user has visibility into both per-entry
files as
`merged-with-customization` or
`customization-detected-needs-reconciliation` per
`scripts/lib/customization-preserve.sh:32-48`. The user can
manually reconcile across the two files.

**Cost we accept:** cross-entry refactor merges fan out across
multiple per-entry files; the user must reconcile multiple files
where v10.1 had one. The benefit we get: per-entry merges are
cleaner (smaller diff, smaller context); single-entry edits (the
common case) are improved.

### §13.3 — Per-entry granularity verification scenario

Per addendum §5.m, a concrete test scenario validates the sidecar's
claim:

**Scenario:** the user customized one field in BD-100 (e.g.,
appended their own sub-Description text); the pack ships an updated
BD-100 with a different field changed (e.g., flipped
`Status: Open` → `Status: Resolved`). Expected merge outcome: both
changes preserved.

**Under decomposition:** the per-entry file `BD-100.md` carries
both the user's appended prose AND the new Status. The 3-way text
dispatch's diff context is the small per-entry file (~30 lines);
the merge resolves cleanly because the changes are on different
lines.

**Verification:** BD-167's coder-pass implementation includes a
test fixture exercising this scenario (per the existing
`scripts/tests/test-customization-*.sh` pattern). The test asserts
the merge outcome matches expectation.

**This integration architect's claim:** the per-entry granularity
verification will PASS for the common single-entry scenario. The
worst-case cross-entry scenario will FAIL the merge in the sense
that it produces `customization-detected-needs-reconciliation`
disposition — which is the correct outcome (the user must
manually reconcile cross-entry customizations under any
shape).

### §13.4 — `_rules.md`, `_intro.md`, `_v8-resolved-archive.md`,
`_format.md` customization handling

Per §3.3 of this doc, `_rules.md` and `_intro.md` are pack-shipped
immutable; `_v8-resolved-archive.md` is frozen-historical;
`_format.md` is project-side pack-shipped. All four route through
`generic` class; the BD-088 truthful report surfaces any
customization.

The expected client behavior:
- Most clients: zero customization on these files; `unchanged-pack`
  disposition; silent.
- A client that customizes `_intro.md` (e.g., adds project-specific
  backlog rules to the preamble): `merged-with-customization`
  disposition; truthful report surfaces; user reconciles per the
  existing pack-update process.
- A client that customizes `_rules.md` to admit a new
  supporting-file basename (e.g., `_quotas.md`): the helpers SKIP
  the unknown basename per §7.5; the client's customization stands;
  the file is ignored by generators (which is the correct behavior —
  the helpers don't know what to do with `_quotas.md` so they don't
  emit it).
- A client that customizes `_v8-resolved-archive.md`: this is
  surfaced by Check 32 (the regenerated mirror would diverge from
  on-disk because the v8 archive content differs); FAIL with
  recovery instruction.

All cases preserve Goal 2 (per-entry tree wins source-of-truth
calls) and Goal 1 (the customization is visible via the truthful
report).

### §13.5 — Customization-preserve does NOT need a new dispatch path

Sidecar §9.1 point 3 noted "_rules.md and _toc.md route to generic
too." The integration architect ratifies. The 3-way text dispatch
at `scripts/lib/customization-preserve.sh:514-558` (cited by
`RESEARCH-PER-ENTRY-SPLIT.md` §5) handles every per-entry and
supporting file uniformly. No new classifier row, no new dispatch
path, no new disposition vocabulary.

The customization-preserve contract is preserved end-to-end. The
integration architect makes one small recommendation for the
planner: when adding the per-entry tree to the v10→v11 migrator's
manifest (which it ISN'T — the manifest entries stay at the
monolithic-file level per §9.2), no manifest changes are needed.
The decompose step is adapter-private and runs after the manifest
dispatch.


---

## §14 — Pattern B archive sweep impact (resolves §5.l)

### §14.1 — Pattern B rule scope

Pack memory at `CLAUDE.md:174-183` (verified) sweeps workflow
artifacts to `maintenance-docs/archive/vN/` at version ship per
Pattern B. The artifacts in scope:
- `ARCHITECTURE-*.md`
- `PLAN-*.md`
- `IMPLEMENTATION-REPORT-*.md`
- `PACK-REVIEW-*.md`
- `AUDIT-*.md`
- `RESEARCH-*.md`
- `*-DISCOVERY.md`

These are produced by the architect / planner / coder / reviewer /
auditor / docs-researcher workflow during a version's active
development. At version ship, they sweep to archive.

### §14.2 — Per-entry trees are NOT workflow artifacts

The pack `/.backlog/` and `/.changelog/` directories carry **live
state** — current pack BDs, current pack version blocks. They are
NOT swept by Pattern B because:
- They are not in any of the seven enumerated suffix patterns
  (BD-NNN.md, vN.M.md, etc. don't match `*-*.md` workflow patterns).
- They live OUTSIDE `maintenance-docs/` (Pattern B's archive
  destination scope).
- They represent the current pack/project shape, not a record of
  past work.

The same applies to project-side `docs/project/backlog/`,
`docs/project/implementation-plan/`, `docs/project/changelog/`.

### §14.3 — `_v8-resolved-archive.md` is NOT swept

The pack `/.backlog/_v8-resolved-archive.md` file (the
v8 historical block per sidecar §6.2 + addendum §3.5) lives inside
`/.backlog/`, which is not a Pattern B sweep target. It stays in
place across all future pack versions — the same way the
`## Resolved — v8 (March 2026)` H2 has stayed in `BACKLOG.md` from
v9 through v11.

### §14.4 — No CLAUDE.md edit required

Sidecar §5.l asked whether the Pattern B rule language at
`CLAUDE.md:174-183` needs clarification to exclude the new
directories explicitly. The integration architect's answer: NO.

The existing rule wording does not need clarification because:
- The rule's location filter scopes to
  `maintenance-docs/v11-implementation/` and the seven workflow-
  artifact suffix patterns. `/.backlog/` and `/.changelog/` are
  outside both scopes.
- Adding explicit "don't sweep `/.backlog/`" wording would make the
  rule longer without changing its operational meaning. The
  principle of "pointer-only-and-short" applies to the Pattern B
  rule the same way it applies to `_rules.md`.

If a future Pack Chat operator misreads the rule and mistakenly
proposes sweeping per-entry tree directories, the
maintainability-principle architect-pass-gate (any structural change
requires architect pass) catches the mistake before the proposal
ships. The principle is self-enforcing.

### §14.5 — Workflow artifact sweep timing for v11.0 ship

The current per-entry-split design corpus —
`ARCHITECTURE-PER-ENTRY-SPLIT.md`,
`ARCHITECTURE-PER-ENTRY-SPLIT-ADDENDUM.md`,
`REVIEW-ARCHITECTURE-PER-ENTRY-SPLIT.md`,
`REVIEW-ARCHITECTURE-PER-ENTRY-SPLIT-ADDENDUM.md`,
`RESEARCH-PER-ENTRY-SPLIT.md`,
`RESEARCH-PER-ENTRY-SPLIT-ADDENDUM.md`, and THIS
`ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` — are all Pattern B
sweep targets at v11.0 ship per the existing rule (workflow
artifacts produced by the architect / reviewer / planner / coder
workflow).

They sweep to `maintenance-docs/archive/v11/` as part of Batch 23
(release pin) per `EXECUTION-PLAN-V11.0.md` §A.1 stop-before-commit
protocol. Pack Chat handles the sweep; this integration architect
acknowledges the sweep target.

The post-sweep state has the architecture corpus accessible at
`maintenance-docs/archive/v11/<filename>.md` for future readers.


---

## §15 — Diffability / git history tradeoff (resolves §5.o)

### §15.1 — The structural tradeoff

Per addendum §5.o + §8.15 above, decomposition trades:

**Better:**
- Per-entry git blame: `git log --follow /.backlog/BD-160.md` shows
  every edit to BD-160 with full history; today the same query
  against BACKLOG.md returns the entire file's history with BD-160
  changes mixed in.
- Per-entry PR review: a PR that touches BD-160 shows
  `/.backlog/BD-160.md` as one file diff; reviewer reads ~30 lines
  in isolation.
- Conflict isolation: concurrent edits to different entries don't
  conflict (per §7.4); v10.1 monolithic was conflict-prone for
  multi-developer pack work.

**Worse:**
- Cross-entry refactor PR review: a refactor flipping 6 BDs to
  Resolved is 6 file edits + mirror regeneration + TOC regeneration
  = 8 file changes in one commit; reviewer surface fans out.
- Cross-entry git blame: `git log --follow` per entry works but a
  query like "show me all BD status flips in v10" requires walking
  multiple files.
- Cross-entry rename: renumbering a BD range (BD-100..BD-110
  shifted to BD-200..BD-210) is now N file renames in git, not one
  multi-line BACKLOG.md edit.

### §15.2 — Why the tradeoff is accepted

Per Pack Chat user direction (v11.0 lock + non-reversible per
addendum §1):
- The decomposition is the chosen direction.
- The tradeoff is structural; no fix is possible without
  re-monolithic-izing.
- The "better" outcomes outweigh the "worse" outcomes for the
  common case (single-entry edit), where v10.1 monolithic was
  noisy and decomposition is clean.

The "worse" outcomes are localized to refactor scenarios that
happen at version-boundary frequency (1–2 times per pack version,
not per session). The cost is borne by Pack Chat at those moments;
the benefit is borne by every session.

### §15.3 — Recovery for cross-entry refactor reviewers

The regenerated mirror in any commit IS the cross-entry view (per
§8.15 above). A reviewer who wants the cross-entry refactor view
reads the mirror diff in that commit:

```bash
git diff <commit>~1..<commit> -- BACKLOG.md
```

The mirror diff shows every BD changed in deterministic sort order;
the reviewer sees the full refactor in one diff. The view exists;
it's in the regenerated file rather than in a single source file.

### §15.4 — Cross-entry rename / renumber ergonomics

For BD renumbering (the worst-case refactor):
- v10.1 (monolithic): one BACKLOG.md edit, multi-line `s/BD-100/BD-200/g`-style.
- v11.0 (decomposed): N file renames + N file content edits + 1
  mirror regeneration + 1 TOC regeneration.

The v11.0 path is more ceremony but is scriptable: a one-time
helper `bash scripts/rename-bd-range.sh BD-100 BD-200` can do the
N file renames + content updates atomically. This integration
architect does NOT propose shipping such a helper at v11.0 (the
refactor is rare enough; ad-hoc shell scripting suffices). If
demand emerges, a future BD opens the helper.

### §15.5 — Acknowledged cost

The tradeoff is structural; no fix; accepted per Pack Chat user
direction.


---

## §16 — Sidecar core-redesign proposals

This section enumerates every place THIS integration architect
overturns a sidecar locked decision. There is exactly ONE such
place.

### §16.1 — REDESIGN-CORE: regenerator invocation model

**Sidecar locked decision:** §6.4 + §7.2 specify
"regenerate-after-every-write" semantics. The mirror generator and
`_toc.md` regenerator fire as the LAST step of any per-entry-file
write; all writes compose into one atomic commit.

**Why integration breaks it:** three failures detailed in §7.1:
- Goal 1 fail: memorizable rule that agents and operators will
  forget.
- Goal 2 fail: no detection mechanism; invariant enforced by trust.
- Scaling cost fail: O(N) reads per write fans out at v12+ entry
  counts.

**Proposed alternative (this design — §7.3):** commit-time explicit
invocation by Pack Chat / PM Chat as the LAST step before staging,
with `validate-pack.py` Check 32 + Check 33 in CI as the gate.
Migrator path uses the same invocation as a single end-of-hook
operation.

**Why the alternative resolves the failures:**
- Goal 1 resolved: commit-time discipline is already memorized
  (Pack Chat / PM Chat already invoke regenerators at commit time
  for other artifacts; one more is consistent).
- Goal 2 resolved: Check 32 + Check 33 in CI catch any commit that
  bypasses the regenerator.
- Scaling cost resolved: regeneration runs once per commit (1) not
  per write (3–10).

**Architect-pass scope of this redesign:** the call is bounded to
the invocation model. The mirror generator and `_toc.md` regenerator
contracts (idempotent, deterministic, library helpers in
`scripts/lib/`) are sidecar §5.2 + §6.2 — RATIFIED. The byte-
identity property, the supporting-file admission via `_rules.md`
(per addendum §3.3), the concatenation order (per addendum §3.6) —
all RATIFIED. Only the trigger mechanism changes.

**Cascade impact:** sidecar §7.2 atomicity property is preserved
under §7.6 above (the new write-path contract). All other sidecar
sections that reference the regenerator (§5.2, §6.2, §6.3, §8.2,
§8.3, §10.4, §16.1) are unaffected — they describe the
regenerator's contract, not its invocation.

**This integration architect owns the redesign.** Pack Chat
ratifies; planner schedules implementation in BD-164.

### §16.2 — Other sidecar decisions reviewed and RATIFIED

For completeness — every other sidecar locked decision was reviewed
during this integration pass and RATIFIED without overturn:

| Sidecar decision | Source | Status |
|---|---|---|
| Per-entry files = source of truth | parent §6 + addendum §1 | RATIFIED |
| v11.0 lock-in mandatory + non-reversible | addendum §1 | RATIFIED |
| One file per phase, tasks inline | addendum §2 | RATIFIED |
| Five stream directories total | parent §0 | RATIFIED |
| Per-stream supporting-file lists | addendum §3.2 | RATIFIED |
| `_intro.md` per stream (Pack Chat Q2 option (b)) | addendum §3.4 | RATIFIED with §3.3 round-trip clarification |
| One-entry-per-file rule across all 5 streams | addendum §3.1 | RATIFIED |
| Customization-preserve generic-class fall-through | parent §9.1 | RATIFIED with §13.2 worst-case acknowledgement |
| v10 entry grammar byte-additive | parent §0 + V3.1-DELTA §3 A2 | RATIFIED |
| Mirror-not-replace | parent §6.1 | RATIFIED |
| BD-119 framework hook contract preserved | parent §10.1 | RATIFIED |
| 1-to-N flat ↔ tracker for project `implementation-plan/` | addendum §4 | RATIFIED |
| Pack `changelog/` is 1-to-1 with tracker | addendum §4.6 | RATIFIED |
| Pack-side `/.backlog/` + `/.changelog/` at pack root | parent §3.1 + §3.2 | RATIFIED |
| Project-side `docs/project/<stream>/` | parent §3.3 + §3.4 + §3.5 | RATIFIED |
| `_v8-resolved-archive.md` pack-side only | parent §6.2 + addendum §3.5 | RATIFIED |
| `_format.md` project-side only | parent §3.5 | RATIFIED |
| Sixth `_rules.md` contract item (supporting-file basenames admitted) | addendum §3.3 | RATIFIED |
| Mode 2 → Mode 3 transition Option A | parent §8.2 + reviewer §6.5 strengthening | STRENGTHENED to "A is required" per §5.6 |
| Concatenation order: intro → entries → v8-archive | addendum §3.6 | RATIFIED |
| Pack/project asymmetry defended | parent §11 | RATIFIED |
| CLAUDE.md "no Resolved section" rule unchanged | parent §12 | RATIFIED |
| Sidecar §1.3 hard-orders the 6 sub-operations | addendum §1.3 | DOWNGRADED to constraint statement per §3.1 |
| Sidecar §5.r `_stage_backup` citation | addendum §5.r | CORRECTED per §3.2 (`migrator-stages.sh:146` not `migrator-core.sh:146`) |


---

## §17 — Integration into v11.0 execution plan

This section proposes the per-entry-split integration into
`EXECUTION-PLAN-V11.0.md`. The PLAN doc is PM-only (per the
architect prompt's explicit list); this integration architect
SURFACES the proposal; Pack Chat applies the EXECUTION-PLAN-V11.0.md
edit on ratification.

### §17.1 — Batch positioning

**Proposed: NEW Batch 18 between Batch 17 (BD-106 / BD-107 / BD-108
tracker entity model) and Batch 19 (BD-105 / BD-103 STATUS.md +
tracker reset).**

The current `EXECUTION-PLAN-V11.0.md` batch sequence (per the doc
`§4` table) lands the per-entry split right at the point where the
tracker entity model is ready and BEFORE the project-side STATUS.md
dual-link rendering picks up tracker awareness. Sequencing
constraints (per sidecar §15 + addendum §1.2):

**Hard sequencing constraints (must precede Batch 18):**
- AFTER Batch 6 (BD-128, CI repair) — green CI for the new Check
  32+33+34 to land cleanly. (Batch 6 already lands per current
  plan.)
- AFTER Batches 7–10 (BD-131..BD-134, tracker repairs per sidecar
  §15.2). The reverse-emit + mirror flow that decomposition reuses
  must be repaired first.
- AFTER Batch 12 (BD-104, IMPLEMENTATION_PLAN.md → IMPLEMENTATION-
  PLAN.md rename per sidecar §15.1 recommendation). The
  hyphenated filename is the v11 standard; decompose reads it.
- AFTER Batch 13 (BD-095, two-phase migrator + BD-101 client-
  migration validation gates). The v10→v11 migrator's two-phase
  flow is the host for the new `_v10_to_v11_decompose_streams`
  step; the validation gates verify the migration is correct.
- AFTER Batch 17 (BD-106 / BD-107 / BD-108, tracker entity model).
  The 1-to-N flat ↔ tracker contract per addendum §4 depends on
  the phase-task entity model being live (BD-106 in particular).

**Hard sequencing constraints (must follow Batch 18):**
- BEFORE Batch 21 (BD-100 final milestone audit). The audit reads
  the v11.0 final state including the per-entry decomposition; the
  audit cannot complete before decomposition lands.
- BEFORE Batch 22 (BD-102 dog-food migration). The dog-food run
  exercises the v10→v11 migrator against the pack-self repo,
  including the new decompose step.

Batch 18 sits cleanly between Batch 17 and Batch 19. No swap with
existing batches required.

### §17.2 — Batch 18 BDs (proposed; Pack Chat opens after ratification)

This integration architect proposes seven new BDs for Batch 18. Pack
Chat opens them; the planner schedules within the batch; the coder
ships.

| BD | Topic | File/Symbol | Blockers | Unblocks |
|---|---|---|---|---|
| BD-164 | Per-entry split implementation: decompose helper + mirror generator + `_toc.md` regenerator + supporting-file generators | `scripts/lib/per-entry/decompose.sh`, `mirror-generate.sh`, `toc-regenerate.sh` (planner picks file structure); helpers shared by BD-165, BD-166, BD-170 | BD-104 (rename), BD-128 (CI green), BD-131..BD-134 (tracker repairs) | BD-165, BD-166, BD-167, BD-168, BD-170 |
| BD-165 | `_v10_to_v11_decompose_streams` 6th sub-operation in v10→v11 post-dispatch hook | `scripts/migrate-v10-to-v11.sh` post-dispatch hook addition; `scripts/lib/migrate-v10-to-v11/decompose.sh` adapter-private helper | BD-164 | BD-167 |
| BD-166 | `init-project.sh` greenfield per-entry tree install (S11 extension) | `scripts/init-project.sh` `stage_s11_v11_artifacts` extension; new `_intro.md` + `_rules.md` + `_format.md` reads from `project-template/docs/project/<stream>/` | BD-164, BD-167 (canonical templates must exist first) | none |
| BD-167 | Per-entry split client artifact installs (absorbs BD-161) | `project-template/docs/project/{backlog,implementation-plan,changelog}/_rules.md`, `_intro.md`, `_format.md` (project changelog only); `migrate-v10-to-v11.sh` install step extension; `tracker-agent-read.sh` per-entry-prefer-mirror-fallback extension; trinity "Key files" line addition + `stream-discovery` skill ship + PACK-AGENTS.md PM-only directories list expansion (PM-only edits — Pack Chat applies); BD-161's net-new SKILL.md installs land in same v11.0 install batch | BD-164 | BD-165, BD-166, BD-168 |
| BD-168 | `validate-pack.py` Check 32 (mirror-in-sync) + Check 33 (TOC-in-sync) + Check 34 (cross-reference integrity) | `scripts/validate-pack.py` three new check functions + STREAMS constant | BD-164, BD-167 | none |
| BD-169 | Read-site audit + targeted wording updates (one prose-tightening commit) | `PACK-CHAT.md` row addition + project-template `PM-CHAT.md` row addition (PM-only); `MERGE-STRATEGY.md` paragraph; `MIGRATION-v10-to-v11.md` section; `README.md` Repository Layout entries (PM-only); auditor agent file extensions; pack-startup + pm-startup `stream-discovery` skill loads | BD-167 | none |
| BD-170 | Pre-decomposed `v11-realistic-ot` fixture extension | `test-fixtures/build.sh` `_build_realistic_for_version v11` case extension to call decompose helper; `test-fixtures/manifest.txt` regeneration | BD-164, BD-160 | BD-102 dog-food (Batch 22) |

**BD-161 absorption confirmed:** BD-161 (per pack `BACKLOG.md:1388`)
is absorbed into BD-167. BD-161 stays in the BACKLOG (its existing
File/Symbol references are preserved in the resolution prose); its
Status flips when BD-167 ships, with the Resolved line citing
"merged into BD-167 v11.0 client artifact install batch". Pack Chat
handles the BACKLOG status flip per §C.4 implicit-flip rule.

**Total BD count for Batch 18: 7 new + 1 absorbed = 8 entries
tracked.** This is in line with the 4–8 BD/batch sizing observed
in current `EXECUTION-PLAN-V11.0.md` Batches 7–17.

### §17.3 — Batch 18 commit ordering (proposed; planner refines)

The planner picks exact commit sequence. This integration architect
proposes a logical ordering:

1. **Commit 18a — BD-164** (decompose / mirror / TOC helpers
   + tests). Standalone library work; no migrator wiring yet.
2. **Commit 18b — BD-167** (canonical templates, trinity edits,
   PACK-AGENTS.md edit, `stream-discovery` skill, STATUS.md
   disclaimer). Multi-file but cohesive; PM-only edits in this
   commit (Pack Chat applies them).
3. **Commit 18c — BD-165** (v10→v11 migrator post-dispatch
   step). Wires the helpers from 18a into the migrator.
4. **Commit 18d — BD-166** (init-project.sh greenfield). Wires
   the helpers into init-project.sh.
5. **Commit 18e — BD-168** (validator Checks 32/33/34). Adds CI
   gates.
6. **Commit 18f — BD-170** (test fixture extension). Builds v11-
   realistic-ot per-decomposed; verifies round-trip.
7. **Commit 18g — BD-169** (read-site audit + wording updates).
   Final wording-only commit.
8. **Commit 18h — BD status flips (Pack Chat direct)** — flips
   BD-164..BD-170 to Resolved + flips BD-161 to Resolved with
   "absorbed into BD-167" Resolution. Per `EXECUTION-PLAN-V11.0.md`
   §C.4 implicit-flip rule.

**8 commits.** This is in line with current Batches 5b (1 commit),
20b (4 commits), and the multi-commit 17 batch sequence. Total
v11.0 commit count from `EXECUTION-PLAN-V11.0.md` increases by ~7
(from "max 31" to "max ~38").

### §17.4 — `EXECUTION-PLAN-V11.0.md` edit specification (PM-only — Pack Chat applies)

The integration architect surfaces the edit specification, NOT the
literal text:

1. **Insert Batch 18 row** in the §4 batch table between current
   Batch 17 and Batch 19. The row name: "Per-entry split (mandatory
   v11.0)".
2. **Update §1 in-scope inventory:** add 7 new BDs (BD-164..BD-170)
   to a new sub-section "Group 5 — per-entry split (added during
   integration architect pass)". Bump the "Total" count
   accordingly.
3. **Update §2 new-BD-entries section:** add BD-164..BD-170 entry
   text (Pack Chat drafts the BACKLOG-paste text using this doc's
   §17.2 table as the source).
4. **Update §3 cleanup status:** mention the per-entry-split
   integration corpus (this doc + sidecar parent + addendum +
   reviews + research) as Pattern B sweep targets at Batch 23
   release pin.
5. **Update §7 verification gates:** add a row for "Mirror+TOC
   in-sync (Check 32+33)" with "After every code-change batch in
   Batch 18+; before commit" + "validate-pack.py PASSED" / "Fix
   regenerator and re-stage".
6. **No edit to §6 open questions:** none of the §6 Q1/Q2/Q3
   questions overlap with per-entry split.
7. **Update §8 pre-flight checklist:** add a "Q4 — per-entry split
   integration scope reviewed; ready to fire Batch 18 after Batch
   17 lands" item.

Pack Chat applies this edit before Batch 18 fires.

### §17.5 — Sequencing relative to existing v11.0 work

The current `EXECUTION-PLAN-V11.0.md` sequence (per the 2026-05-11
re-sequencing note in §4) is:

1. Skill-dimensions reframe (BD-140..BD-150) — `PLAN-SKILL-DIMENSIONS.md`
2. Phase 2A architect → 2B planner → Phase 3
3. Phase 3.5 — Batches 3 + 4
4. Batches 14b → 23

Batch 18 (per-entry split) lives in step 4. It does NOT interfere
with steps 1–3. Specifically:
- Skill-dimensions reframe is a different surface (skill files, not
  state docs); zero overlap.
- Phase 2A/2B/3 SKILL.md commits are different surface; zero overlap.
- Phase 3.5 (BD-120 / BD-116 / BD-117 / BD-118) is fixture builder
  + persona contracts + RELEASE-GATE; BD-170 in Batch 18 builds on
  BD-120 (parameterized fixture builder); BD-170 is BLOCKED by
  BD-120.

Sequencing is clean.

### §17.6 — BD-numbering audit

The integration architect verified the highest existing BD in pack
`BACKLOG.md` is BD-163 (per `Bash grep` confirmation in the Inputs
read step). The new BDs BD-164..BD-170 are sequential and
non-colliding. Pack Chat opens them via the standard sequential-
numbering rule per `CLAUDE.md:60-62` ("Read BACKLOG.md, find the
highest existing BD-NNN, increment by 1").

### §17.7 — Other v11.0 BDs blocked / unblocked by per-entry split

**Blocked by per-entry split (must wait):**
- None. The per-entry split lands AFTER all currently-blocked
  v11.0 BDs (Batch 17 tracker entity model is the latest dependency
  in the current plan).

**Unblocked by per-entry split (becomes possible only after):**
- BD-102 dog-food (Batch 22) gains a new exercise surface (verifies
  the v10→v11 migrator's decompose step works end-to-end on
  pack-self).
- BD-100 final milestone audit (Batch 21) gains a new audit surface
  (verifies the v11.0 per-entry shape is consistent end-to-end).

### §17.8 — Total v11.0 BD count after integration

Current `EXECUTION-PLAN-V11.0.md` §1 total: 41 BDs in-scope + 1
verify-and-close + 4 untracked items folded.

Integration adds: 7 new BDs (BD-164..BD-170) + 0 new verify-and-
close + 0 new untracked.

**Updated total: 48 BDs in-scope + 1 verify-and-close + 4
untracked = 53 items.** (BD-161 absorption into BD-167 keeps the
BD-161 BACKLOG entry; total entries go up by 7, not by 6.)


---

## §18 — Open items for the planner / coder

These are concrete items the planner will need to schedule and the
coder will need to address, named with file:line where applicable.
Each is a planner-pass / coder-pass call that this integration
architect explicitly defers (with the design context the planner
needs).

### §18.1 — Planner items

1. **Function names for the helpers (BD-164).** The mirror generator,
   `_toc.md` regenerator, decompose helper need names. Sample shapes:
   `regenerate_mirror`, `regenerate_toc`, `decompose_streams`. The
   planner picks names; the architect-pass output is the contract
   shape per sidecar §5.2 / §6.2 + §7 of this doc.

2. **File structure under `scripts/lib/per-entry/`.** One file or
   multiple? The sidecar §5.2 + §6.2 noted "library helper(s) in
   `scripts/lib/`"; the maintainability principle (signal 6 carve-
   out) says helpers in `scripts/lib/` are not new top-level
   scripts. The planner picks: one file (`scripts/lib/per-entry.sh`)
   or a sub-directory (`scripts/lib/per-entry/{decompose,mirror,toc}.sh`).
   Reading suggests a sub-directory because three helpers have
   distinct surfaces and shared parsing logic suggests a `_lib.sh`
   helper too. Planner-final.

3. **Adapter-private decompose helper location (BD-165).** Per
   sidecar §10.2, lives under `scripts/lib/migrate-v10-to-v11/`.
   Recommended name: `scripts/lib/migrate-v10-to-v11/decompose.sh`.
   Planner-final.

4. **Sequencing of the 6 sub-operations within
   `migrator_post_dispatch_hook` (BD-165).** Per §3.1, decompose
   runs LAST. The planner picks the literal call-list position
   (likely line ~149 of `migrate-v10-to-v11.sh` per the existing
   pattern at lines 144–148).

5. **`init-project.sh` stage extension vs new stage (BD-166).** Per
   §8.17, recommend extending S11 (`stage_s11_v11_artifacts` at
   line 803). Planner picks final.

6. **Pre-commit hook shipping (optional).** Per §7.3, shipping a
   git pre-commit hook that auto-invokes the regenerator before
   commit is OUT OF SCOPE for this design. The CI gate (Check
   32+33) is sufficient. The planner can opt to add a
   `scripts/install-pre-commit.sh` as a planner-decision optional
   enhancement; not blocking.

7. **STATUS.md disclaimer text refinement (PM-only — Pack Chat
   applies but planner can refine wording).** The §5.3 sample
   disclaimer is a starting shape; the planner can refine the exact
   wording before Pack Chat applies it.

8. **`_intro.md` content extraction shape (BD-167).** The planner
   decides the extraction algorithm (regex match for
   "first non-entry preamble"; or hardcoded line-range per
   v10 source layout). Recommended: regex match for "everything
   before the first `**BD-NNN —` or `**TD-NNN —` or
   `### vN.M —` line", which handles both pack-side and project-
   side preambles uniformly.

9. **`_v8-resolved-archive.md` content extraction shape (BD-167).**
   Same kind of decision as #8. Recommended: regex match for "the
   `## Resolved — vN ...` H2 line through the next H2 (or EOF)".

10. **Tracker mode `_tar_read_entry_flat` extension (BD-167).** Per
    §5.2, `_tar_read_entry_flat` (line 153 of
    `tracker-agent-read.sh`) extends to prefer the per-entry file
    when the per-entry tree exists. Planner decides whether to
    fold this into the existing function or add a sibling
    `_tar_read_entry_per_entry`. Recommended: extend existing
    function with a presence-check.

### §18.2 — Coder items

1. **Test fixtures for the helpers (BD-164).** Test cases:
   - Round-trip identity: decompose(mirror) → tree;
     regenerate(tree) → mirror'; mirror == mirror' byte-identical.
   - Empty-tree behavior: regenerate over empty stream produces
     mirror with only `_intro.md` content.
   - Supporting-file admission: `_quotas.md` (unknown) is skipped;
     `_v8-resolved-archive.md` (known) is emitted.
   - Cross-reference resolution: Check 34 detects `Blockers: BD-999`
     when BD-999 has no entry file.

2. **Backward-compatibility shim for v10.1 read sites (BD-167).**
   `scripts/lib/tracker-agent-read.sh` `_tar_read_entry_flat`
   should detect "per-entry tree present" via `[[ -d /.backlog/ ]]`
   check and route accordingly. The shim ensures pre-v11.0
   client repos continue to work (they have monolithic-as-source;
   mirror is the same file).

3. **Per-entry HTML-comment back-pointer add/strip (BD-164 +
   BD-165).** The decompose helper ADDS the back-pointer comment
   when emitting per-entry files; the mirror generator STRIPS it
   when emitting per-entry content into the mirror. Idempotent on
   both sides.

4. **`_intro.md` and `_v8-resolved-archive.md` initial
   migration write (BD-165).** First v10→v11 migration writes
   these files from extracted content (per §9.7); subsequent
   regenerations preserve them on disk and use them as inputs.

5. **Validate-pack.py STREAMS constant (BD-168).** Define the
   five stream tuples at the top of validate-pack.py:
   `STREAMS = [("/.backlog/", "/BACKLOG.md", "BD-NNN"),
   ("/.changelog/", "/CHANGELOG.md", "vN.M"), ...]`. Planner
   picks the exact tuple shape based on what Check 32/33/34 need.

6. **Test fixtures for Check 32/33/34 (BD-168).** Synthetic
   per-entry trees that pass and fail each check. Lives under
   `scripts/tests/fixtures/per-entry/`.

### §18.3 — Items deferred to v11.x or later

Per `EXECUTION-PLAN-V11.0.md` §1.6 conventions, items not in v11.0
scope:

1. **Cross-entry refactor helper script** (per §15.4). If demand
   emerges, a v11.x BD opens
   `scripts/rename-bd-range.sh`. Not v11.0.

2. **Lazy / on-read regeneration** (per §7.3 rejected
   alternative). Not v11.0; rejected for v11.x as well unless a
   specific scenario forces it.

3. **Incremental regeneration** (per §7.3 rejected alternative).
   Not v11.0; full regeneration is sufficient at projected v13
   scale.

4. **Per-entry-tree presence as v11.0+ detection signal** (per
   §8.16 rejected). Not v11.0; not v11.x; `tracker.toml`
   template_version + README version table are sufficient.

5. **Validator coverage of cross-pack-and-project references**
   (per §11.5 rejected scope). Not v11.0; pack-and-project
   reference checking would require loading both trees in the
   pack-repo CI; out of scope.


---

## §19 — Final-line marker

ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-COMPLETE: 2026-05-13 —
Integration architect pass over sidecar parent
(`ARCHITECTURE-PER-ENTRY-SPLIT.md`, 1,649 lines) +
addendum (`ARCHITECTURE-PER-ENTRY-SPLIT-ADDENDUM.md`, 1,101 lines)
+ two primary-chat reviewer passes
(`REVIEW-ARCHITECTURE-PER-ENTRY-SPLIT.md` 1,096 lines +
`REVIEW-ARCHITECTURE-PER-ENTRY-SPLIT-ADDENDUM.md` 958 lines).
Three reviewer-flagged frictions resolved (§3): Friction 1 §1.3
hook-sequencing downgraded to constraint statement; Friction 2 §5.r
citation slip corrected (`migrator-stages.sh:146`, not
`migrator-core.sh:146`); Friction 3 `_intro.md` flat ↔ tracker
round-trip resolved per Pack Chat user clarification (pack-shipped
immutable, never tracker-touched, pack and project copies separate).
Pack Chat Goals 1/2/3 designed (§§4–6): Goal 1 discoverability via
trinity Key files pointer + per-entry HTML-comment back-pointer +
new `stream-discovery` skill (triple-redundancy recovery); Goal 2
source-of-truth invariant via per-entry-as-truth declaration +
STATUS.md disclaimer requirement (PM-only edit Pack Chat applies)
+ `validate-pack.py` Check 32 mirror-in-sync gate; Goal 3 read/write
audit confirms no agent other than Pack/PM Chat writes entries +
PACK-AGENTS.md PM-only directories list extension defended as
refactor-not-expansion + CLAUDE.md pack-memory entry surfaced for
Pack Chat to apply. ONE sidecar core decision overturned
(REDESIGN-CORE §7): regenerator invocation model from
"after-every-write" to "commit-time explicit invocation by Pack/PM
Chat with CI gate (Check 32+33)" — resolves Goal 1 fail
(memorizable-rule fail), Goal 2 fail (no detection mechanism), and
scaling-cost fail (O(N) reads × M writes at v12+ scale; commit-time
is 3.3× faster on average). All other sidecar decisions ratified
(§16.2 table). 18 identify-only items §5.a–§5.r dispositioned (§8):
15 DESIGN, 1 INVENTORY, 2 TRADEOFF, 2 REDESIGN-CORE (§5.b + §5.c
both into the §7 commit-time model). Three new validator checks
(§10): Check 32 mirror-in-sync, Check 33 TOC-in-sync, Check 34
cross-reference integrity — each defended as required-by-Goal-2
under maintainability signal-4 architect-pass requirement. Migrator
integration (§9): existing `migrator_post_dispatch_hook` gains a
6th sub-operation (`_v10_to_v11_decompose_streams`); BD-119
framework contract unchanged; backup/rollback contract sufficient
under non-reversible v11.0 lock with one new advisory paragraph in
post-report-hook. Customization-preserve generic-class fall-through
ratified (§13) with worst-case acknowledgement (cross-entry
customizations fan out across multiple per-entry files). Pattern B
archive sweep (§14): per-entry trees are NOT swept (live state, not
workflow artifacts); existing rule wording unchanged. Diffability
tradeoff (§15) accepted: per-entry git blame is cleaner;
cross-entry refactor PR review fans out; the regenerated mirror is
the cross-entry view if needed. Integration into v11.0 execution
plan (§17): NEW Batch 18 between current Batch 17 (tracker entity
model) and Batch 19 (STATUS.md + tracker reset); 7 new BDs
(BD-164..BD-170 — sequential from current highest BD-163);
BD-161 absorbed into BD-167; 8 commits; total v11.0 commit count
goes from max 31 to max ~38. Open planner/coder items enumerated
(§18) with explicit deferral and design context for each. THIS
integration architect's authority: regenerator invocation model
redesign, 18 identify-only item dispositions, batch positioning
proposal, new BD opens; PM-only edits surfaced for Pack Chat to
apply (CLAUDE.md pack-memory addition, PACK-AGENTS.md PM-only
directories list extension, STATUS.md disclaimer, EXECUTION-PLAN-
V11.0.md Batch 18 insertion, README.md Repository Layout entries,
trinity Key files line additions, BACKLOG.md new BD entries
BD-164..BD-170). No PM-only edits made by this integration; no
sidecar design files touched; no pack-product files touched; ready
for primary-chat reviewer to evaluate before primary-chat planner
spawns.
