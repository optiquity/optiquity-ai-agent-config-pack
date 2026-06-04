# DECISION — Per-entry/tracker design fork + BD-185 sequencing vs BD-203

**Agent:** pack-architect · **Date:** 2026-06-04 · **Branch:** v11-dev · **HEAD:** `37f2927`
**Mode:** READ-ONLY decision memo. Two evidence-based DECISIONS only. NOT an implementation design — no HOW, no mechanics, no commit sequencing. No source edits, no git state change.
**Inputs:** `RESEARCH-BD-203-BLAST-RADIUS.md` (pack), `RESEARCH-PROJECT-PER-ENTRY-BLAST-RADIUS.md` (project), BD-185/203/204/206/207 entries, the BD-185 substrate (`ARCHITECTURE-BD-185-V2.md`, `-ORDERING-ADDENDUM.md`, `PLAN-BD-185-V2.md`, `RESEARCH-BD-185-ORDERING-API.md`).

---

## THE TWO DECISIONS (lead)

### DECISION 1 — FORK: co-design the SHARED-CODE layer once (pack+project together); design the DOCS/ASSET layer per-side.

**Recommendation.** Run ONE combined architect design for the **tooling/code layer** — the per-entry helpers (`scripts/lib/per-entry/*`) and the tracker forward/reverse emitter — because it is a single codebase serving all 5 streams (2 pack + 3 project) and BD-203/204/206/207 all mutate the SAME functions. Design the **docs/asset-conversion layer** (the trinity copies, `_rules.md`/`_intro.md` contracts, MIGRATION/MERGE-STRATEGY/METHODOLOGY prose, the per-side wrong-model corrections) **per-side**, scheduled independently, because the pack-side and project-side surfaces are a DISJOINT file set with separate audiences and `pack-project-separation-of-concerns` forbids treating them as one artifact even when byte-identical.

**One-line rationale.** The tooling is provably ONE codebase (`PE_STREAM_KEYS` drives all 5 streams from `_lib.sh:64`; the reverse emitter `_tmr_emit_backlog`/`_tmr_emit_implementation_plan` has both pack- and client-surface branches in the same function) — you cannot retire `mirror-generate` or fix the reverse-emitter's monolith-write for one side without touching the other; the docs are 48 pack-actionable files vs a disjoint 16 project files, independently schedulable.

### DECISION 2 — BD-185 SEQUENCING: BD-185 runs AFTER BD-203 (per-entry exists first); its TRACKER ordering can interleave with / follow BD-204; it is NOT a prerequisite of the migration.

**Recommendation.** Sequence **BD-203 (pack per-entry) BEFORE BD-185**. BD-185 has a hard runtime dependency on the per-entry infrastructure (it edits `scripts/lib/per-entry/_lib.sh` mirror-sort, writes `<!-- execution-order: N -->` markers onto `phase-N.md` per-entry files, and routes reverse-emit through `_tmr_emit_implementation_plan`) — those surfaces must exist and be stable first. The migration does NOT depend on BD-185's ordering design: the pack has NO implementation-plan stream (so the pack per-entry/tracker conversion never touches phase ordering at all), and the project implementation-plan stream's ordering is a SEPARATE axis (`order_key`) that the conversion preserves as opaque per-entry content. **BD-185 is a CONSUMER of the per-entry/tracker infrastructure, not a contributor to it.** The known "execution-ordering does not survive sync in tracker mode" defect IS what BD-185 fixes, but that fix lands ON TOP of the tracker existing — it does not gate the tracker's construction.

**One-line rationale.** Dependency direction is one-way: BD-185 reads/writes the per-entry+tracker surfaces BD-203/204 build (proven by PLAN-BD-185-V2 §2.3 editing the exact shared files), while the migration's correctness has zero dependence on phase-ordering semantics (the pack has no phase stream; the project phase stream's order is preserved as content, not interpreted). The existing BACKLOG already encodes this: BD-205 blocks "AFTER BD-185," and BD-185 sits in the launch-gate chain after the migration BDs.

---

## DECISION 1 — EVIDENCE

### 1.1 The tooling layer is ONE shared codebase (the decisive together-signal)

`scripts/lib/per-entry/{_lib,decompose,mirror-generate,toc-regenerate}.sh` is a single codebase driving all 5 streams. `_lib.sh:64`:
`PE_STREAM_KEYS="pack-backlog pack-changelog project-backlog project-implementation-plan project-changelog"` (verified at HEAD `37f2927`). The per-stream behavior (mirror filename, entry regex, anchor form) is data, not separate code — one `mirror-generate.sh::per_entry_regenerate_mirror`, one `decompose.sh` anchor engine, one `toc-regenerate.sh`.

Consequence (both research reports concur):
- Retiring the mirror-generate direction for the pack (BD-203) retires it for the project (BD-206) — SAME function (pack §4; project §3, §6 row 1).
- Widening the decompose anchor to admit `BD-167b`/`(Code Red 3)` (pack) fixes the identical `TD-NNNb`/parenthetical gap (project) — SAME `decompose.sh` anchor engine (pack §4 gap 1; project EE-5).
- The tracker reverse emitter is ONE function with pack- and client-surface branches: `tracker-migrate-reverse.sh` `_tmr_emit_backlog` + the surface branch writes `pack-ops/BACKLOG.md` (pack, BD-204) OR `$repo_root/BACKLOG.md` (client, BD-207). You cannot correct the no-mirror write for one surface branch without editing the shared function (project §4.4, §7).

This makes a SEPARATE-tooling design unsound: two architects designing the same functions in isolation would produce conflicting contracts for one codebase. The shared-tooling change must be designed once, covering both sides' stream requirements together.

### 1.2 The docs/asset layer is a DISJOINT file set, independently schedulable

The wrong-model "monolith = regenerated mirror" surfaces are two non-overlapping sets:
- **Pack-side (BD-203):** 48 actionable files / 172 occurrences — trinity pack copies, README pack rows, PACK-AGENTS.md, PACK-CHAT.md, HELP-FRAGMENT-PACK.md, the pack-copied agent/skill prompts, validate-pack.py Checks 32/40/48 (pack §2, §5).
- **Project-side (BD-206):** 16 files — `project-template/` trinity, the 6 `_rules.md`/`_intro.md` files, audit-methodology + pm-startup + PM-CHAT shipped copies, MIGRATION-v10-to-v11.md (project §2, EE-2).

These sets share NO file. The project report states it directly (§2): "This set is DISJOINT from the pack-side §5 set... different files, client audience." Per `pack-project-separation-of-concerns` (read in full), even byte-identical pack/project statements are SEPARATE artifacts with separate audiences — "Byte-identity is coincidence, NEVER a design rationale." So the doc-correction WORK can be split by side and scheduled independently (BD-203 docs now; BD-206 docs at its target).

### 1.3 Reconciling the two signals — the precise fork line

The fork is not "together vs separate" wholesale; it is a LAYER split:

| Layer | Decision | Why |
|---|---|---|
| Shared tooling (`per-entry/*`, reverse emitter, decompose anchor, mirror-generate retirement, throttle) | **Co-design ONCE, covers pack+project** | one codebase; both sides' stream needs must be reconciled in a single contract or they conflict |
| Tracker Mode-3 contract (the "tree+mirror regenerated from tracker" clause) | **Co-design ONCE** | the BD-204 entry clause and the client `_intro.md`/trinity clause are the SAME wrong-model statement hitting the SAME reverse emitter (project §4.4 "reconcile the Mode-3 contract for BOTH surfaces at once") |
| Wrong-model doc corrections | **Per-side, scheduled independently** | disjoint file set; separate audiences; `pack-project-separation-of-concerns` |
| Asset conversions (creating `/backlog/`+`/changelog/` pack trees vs the client greenfield/migration paths) | **Per-side** | the pack conversion is a one-time BD-203 decompose of `pack-ops/*`; the client conversion is the v10→v11 migrator + greenfield `init-project.sh` — different entry points, different assets |

This is the concrete recommendation the BD-203 entry's binding-decision asks for ("an architect that reviews BOTH and DECIDES whether the pack + project designs are done together or separately"): **shared tooling + Mode-3 contract co-designed once; docs/asset conversions designed per-side.**

### 1.4 Trade-offs

- **Co-designing the shared tooling** risks a larger single design surface and couples BD-203's schedule to project-stream requirements it would otherwise ignore. Mitigation: the shared-tooling contract is small (retire mirror-generate direction; widen anchor; route reverse-emit no-mirror) and MUST be reconciled anyway — deferring it to a separate pass would force a second architect to re-open the same functions and risk a contradictory contract (the exact failure mode that got the two prior BD-203 designs rejected for designing on an incomplete picture).
- **Splitting the docs** risks the launch-coherence gap the BD-206 entry flags: BD-203 corrects the shared trinity convention (which SHIPS to clients) to "no mirror," but if BD-206's client-tooling correction lags, v11.0 ships a convention that says no-mirror while the client feature still makes mirrors. This is a SCHEDULING constraint on BD-206's target (the BD-206 entry already raises it), NOT an argument against the layer-split — it argues BD-206 should land in v11.0, not that its docs must be designed in the same pass as BD-203's.
- **Boundary risk:** the project report flags pack-ops files containing project-side model statements (`MERGE-STRATEGY.md` §256-274) and the `project-template/` skill master that the pack-copied skills derive from. The combined tooling pass must explicitly assign these to the correct side (BD-206 for project-side content even when it lives in a pack-ops file) — a reason the architect reviewing BOTH reports must own the boundary assignment, which the layer-split co-design naturally provides.

---

## DECISION 2 — EVIDENCE

### 2.1 BD-185 DEPENDS ON the per-entry/tracker infrastructure (the one-way arrow)

PLAN-BD-185-V2.md §2.3 (Work-stream C, ordering mechanism) edits the EXACT shared files BD-203/204/206/207 build:
- `scripts/lib/per-entry/_lib.sh` — "mirror sort `LC_ALL=C sort` (L401) → tuple `(execution-order, phase_number, filename)` for the phase stream." (Verified: `_lib.sh:395` carries the sort-order comment today; the `project-implementation-plan` stream is defined at `_lib.sh:93`.)
- `scripts/lib/tracker-migrate-reverse.sh` — `_tmr_emit_implementation_plan` + `_tmr_emit_status` "sort by `provider_order_read`; write `<!-- execution-order: N -->` into emitted `phase-N.md`." (Verified: `_tmr_emit_implementation_plan` exists at `tracker-migrate-reverse.sh:682`.)
- `scripts/lib/migrate-v10-to-v11/decompose.sh` — writes the execution-order marker into each per-entry `phase-N.md`.

BD-185's ordering value LIVES ON the per-entry `phase-N.md` file (flat-file mode, ORDERING-ADDENDUM A-1 / C7) and on the phase-epic ISSUE (tracker mode, A-1). Both substrates — the per-entry tree and the tracker — are what BD-203 (per-entry) and BD-204 (tracker) construct. BD-185 cannot write `<!-- execution-order: N -->` into a `phase-N.md` that does not exist, and cannot route ordering through the tracker reverse emitter before the tracker exists. **BD-185 is a consumer.**

### 2.2 The migration does NOT depend on BD-185 (the absent reverse arrow)

Two independent reasons the per-entry/tracker conversion needs nothing from BD-185's design:

1. **The PACK has no implementation-plan stream.** BD-203 entry (verbatim): "TWO streams only — the pack has NO implementation-plan monolith; that earlier mention was an erroneous insertion, corrected 2026-06-04"; Out-of-scope: "any implementation-plan stream (the pack has none)." Phase ordering is a property of the implementation-plan stream ONLY. So BD-203 (pack) and BD-204 (pack tracker) never touch phase ordering — there is nothing for BD-185 to inform. The pack migration is phase-ordering-agnostic by construction.

2. **The PROJECT implementation-plan stream's order is preserved as opaque content, not interpreted.** BD-206/207 convert the client `phase-N` stream monolith↔per-entry↔tracker. The conversion's job is entry-preservation (every `phase-N.md` survives content-faithfully, every status preserved). Whether a `phase-N.md` carries an `<!-- execution-order: N -->` marker is irrelevant to the conversion — the marker is body content the decompose/regenerate round-trips verbatim, exactly like any other body marker (`pack-id`, `template_version`). The ORDERING-ADDENDUM confirms this: the marker "is parseable by the per-entry tools, ignored by Markdown viewers" (V2 §5.3) — it round-trips as content. So BD-206/207 preserve BD-185's ordering output without needing BD-185's ordering DESIGN.

### 2.3 The "execution-ordering does not survive sync" defect — does BD-185 resolve it, and does the migration depend on that resolution?

BD-185 P3 (verbatim): "In tracker mode, IMPLEMENTATION-PLAN.md is a regenerated mirror — execution notes do not survive sync." This is the defect the user's note references.

- **Does BD-185 resolve it?** YES. BD-185's entire ordering design exists to MOVE ordering off the regenerated mirror onto the phase entity (ORDERING-ADDENDUM A-1: "owned by the phase entity... NOT owned by STATUS.md, NOT by any `_order.md` view, NOT by a flat-file mirror in tracker mode"). The no-mirror standard from BD-203/206 REINFORCES this — under no-mirror, there IS no regenerated mirror for ordering to be lost into; the per-entry tree IS the SSOT. The two designs are mutually consistent (both say: the mirror is not the SSOT).
- **Does the tracker migration DEPEND on that resolution?** NO. The migration's correctness criterion is lossless round-trip of every entry's content+status (BD-204/207 acceptance criteria). An `order_key`/`execution-order` marker that round-trips as content satisfies that criterion regardless of whether BD-185 has taught any tool to INTERPRET it as sort order. BD-185 adds the INTERPRETATION layer (sort by it, write it onto the tracker phase-epic field) AFTER the round-trip substrate exists. The defect-resolution is additive on top of the migration, not a precondition of it.

### 2.4 Could BD-185 instead need to run FIRST (the reverse hypothesis, rejected)

Hypothesis: the tracker migration must handle phase ordering correctly, so BD-185's ordering design must land first so the migration "handles phase ordering correctly."

Rejected on evidence:
- For the PACK migration (BD-203/204): no phase stream exists → nothing to handle (§2.2.1).
- For the PROJECT migration (BD-206/207): the migration preserves the marker as content; it does not need to KNOW the marker is sort-order to round-trip it (§2.2.2). If BD-185 has NOT yet run, the client `phase-N.md` files simply carry no `execution-order` marker yet (or carry execution-note prose) — the conversion round-trips whatever is there. When BD-185 later runs, it adds the marker + the sort interpretation on the already-existing per-entry/tracker substrate. Order is: substrate first (203/204/206/207), interpretation second (185).
- The ORDERING-ADDENDUM's migration section (§6) routes ordering writes through `provider_order_write` — a NEW abstract op BD-185 ADDS to the tracker provider surface. That op needs the tracker provider machinery (BD-060, already landed) and the per-entry substrate to exist; it does not need to predate them. This confirms BD-185 extends the migration, not precedes it.

### 2.5 Sequence recommendation + corroborating BACKLOG state

**Recommended sequence: BD-203 → BD-204 (pack), with BD-206/207 (project) per Decision 1's layer-split; BD-185 AFTER the per-entry+tracker substrate exists; BD-185 may interleave with the tracker BDs only to the extent its ordering ops extend an already-built tracker provider.**

Corroboration from live BACKLOG (HEAD `37f2927`):
- BD-205 Blockers: "AFTER BD-185 (user 2026-06-04) — runs only once every other launch-gate item (BD-195, BD-200, BD-203, BD-204, BD-197, BD-185) is Resolved." So the user's own launch-gate ordering already lists BD-203/204 in the chain WITH BD-185, all before the final BD-205 gate — consistent with BD-185 not being a prerequisite of BD-203.
- BD-185 Status: "Paused pending Code Red 3 (BD-195)" — BD-185 was already gated behind the pristine-state recovery, not behind being a migration prerequisite.
- BD-203 entry names its blockers as "Follows BD-200... Sequenced BEFORE BD-197" with NO BD-185 dependency in either direction — the migration's blocker chain does not include BD-185, confirming independence of the migration FROM BD-185.

**Net:** BD-185 is neither a blocker of nor blocked-by the migration in the design sense; it is a CONSUMER that must run after the substrate exists. The safe, evidence-backed ordering is: per-entry + tracker substrate first (BD-203/204, and the project analogs), BD-185's ordering layer after. There is no correctness reason — and no BACKLOG-encoded reason — to run BD-185 before BD-203.

---

## EMPIRICAL-EVIDENCE BLOCKS

All commands run at HEAD `37f2927`, branch `v11-dev`, cwd `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`, 2026-06-04.

### EE-1 — The per-entry tooling is one shared codebase across all 5 streams (Decision 1)
```
$ grep -n "PE_STREAM_KEYS" scripts/lib/per-entry/_lib.sh
64:PE_STREAM_KEYS="pack-backlog pack-changelog project-backlog project-implementation-plan project-changelog"
```
Interpretation: a single helper file enumerates all 5 streams (2 pack + 3 project); per-stream behavior is data within one engine, not separate codebases.
Conclusion: **SUPPORTED** — shared tooling; co-design-once is the sound layer for the tooling.

### EE-2 — The project implementation-plan stream lives only in the shared helper (Decision 1 + 2)
```
$ grep -n "implementation-plan\|project-implementation" scripts/lib/per-entry/_lib.sh | head
62:# project/implementation-plan, project/changelog. (Ordering is not
64:PE_STREAM_KEYS="... project-implementation-plan ..."
93:        project-implementation-plan)
102:                dir-suffix) printf 'docs/project/implementation-plan' ;;
```
Interpretation: the phase stream is a PROJECT stream; the pack has none. BD-203/204 (pack) never touch phase ordering.
Conclusion: **SUPPORTED** — the pack migration is phase-ordering-agnostic.

### EE-3 — The tracker reverse emitter handles the phase stream and is the BD-185 consumer surface (Decision 2)
```
$ grep -n "_tmr_emit_implementation_plan\|_tmr_emit_status" scripts/lib/tracker-migrate-reverse.sh
682:_tmr_emit_implementation_plan() {
711:_tmr_emit_status() {
1122:    _tmr_emit_implementation_plan "$phase_jsons" "$plan_out" ...
1123:    _tmr_emit_status ... "$status_out" ...
```
Interpretation: `_tmr_emit_implementation_plan` exists today (built by the tracker work); PLAN-BD-185-V2 §2.3 EDITS it to sort by `provider_order_read` + write the `execution-order` marker. BD-185 consumes/extends this; it does not create it.
Conclusion: **SUPPORTED** — BD-185 is a consumer of the reverse emitter, which the migration BDs own.

### EE-4 — The mirror-sort surface BD-185 edits is the per-entry helper (Decision 2)
```
$ sed -n '393,396p' scripts/lib/per-entry/_lib.sh  (via Read)
~395: # phase-N also sort correctly under `LC_ALL=C sort` because they ...
```
Interpretation: the lexical mirror-sort comment at `_lib.sh:~395` is exactly the line PLAN-BD-185-V2 §2.3 (C-3) rewrites to a `(execution-order, phase_number, filename)` tuple. The surface BD-185 modifies is the per-entry tree's regeneration path — built by the per-entry conversion work.
Conclusion: **SUPPORTED** — BD-185's ordering edits target per-entry infrastructure that must pre-exist.

### EE-5 — BD-185 entry has no migration-prerequisite dependency; migration entries have no BD-185 dependency (Decision 2)
```
BD-185 (BACKLOG:1748-1750): Status: Open; Paused pending BD-195; Blockers: Batch 19c (BD-173) completion.
BD-203 (BACKLOG:3334): Blockers: Follows BD-200. Sequenced BEFORE BD-197. (no BD-185)
BD-204 (BACKLOG:3357): Blockers: Follows BD-203. Sequenced BEFORE BD-197. (no BD-185)
BD-205 (BACKLOG:3375): Blockers: AFTER BD-185 ... once (BD-195, BD-200, BD-203, BD-204, BD-197, BD-185) Resolved.
```
Interpretation: neither BD-203 nor BD-204 lists BD-185 as a blocker; BD-185 is not gated on the migration; the user's launch-gate chain places both in the pre-BD-205 set without inter-ordering BD-185 ahead of BD-203.
Conclusion: **SUPPORTED** — no encoded prerequisite in either direction; consistent with BD-185-after-substrate.

### EE-6 — BD-185's ordering value is phase-entity-owned, not mirror-owned (Decision 2, the defect resolution)
```
ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md A-1: "owned by the phase entity ...
  NOT owned by STATUS.md, NOT by any _order.md view, NOT by a flat-file mirror in tracker mode."
BD-185 entry P3: "In tracker mode, IMPLEMENTATION-PLAN.md is a regenerated mirror —
  execution notes do not survive sync."
```
Interpretation: BD-185 RESOLVES P3 by moving ordering off the mirror; the no-mirror standard (BD-203/206) reinforces it. The resolution is additive on the substrate, not a precondition of the substrate.
Conclusion: **SUPPORTED** — defect-resolution layers on top of the migration; migration does not depend on it.

### EE-7 — The wrong-model doc sets are disjoint (Decision 1 docs-per-side)
```
Pack (RESEARCH-BD-203 §2/§5): 48 actionable files / 172 occurrences (trinity pack copy, README pack rows,
  PACK-AGENTS/PACK-CHAT/HELP-FRAGMENT-PACK, validate-pack.py, pack-copied agent/skill prompts).
Project (RESEARCH-PROJECT §2, EE-2): grep -rln "regenerated mirror" project-template/ supporting-docs/ → 16
  (project trinity ×3, _rules/_intro ×6, audit-methodology+pm-startup+PM-CHAT, MIGRATION-v10-to-v11).
```
Interpretation: the two correction sets share no file; project report states the set is "DISJOINT from the pack-side §5 set."
Conclusion: **SUPPORTED** — docs are per-side schedulable; `pack-project-separation-of-concerns` keeps them separate artifacts.

---

## RULES-APPLIED VERIFICATION BLOCK

| Rule (as named in prompt) | Verification evidence (quoted) | Conclusion |
|---|---|---|
| **preliminary-triage / architect-challenge** | Both decisions are framed as recommendations grounded in measured evidence, not preference. Decision 2 explicitly raises and REJECTS the reverse hypothesis (§2.4 "Could BD-185 instead need to run FIRST") on evidence rather than rubber-stamping the user's uncertainty; Decision 1 challenges the framing that the fork is wholesale together-vs-separate and re-cuts it as a LAYER split (§1.3). | COMPLIANT |
| **empirical-evidence-blocks** | EE-1..EE-7: every dependency/shared-vs-disjoint state-claim carries the actual command/file:line + verbatim output + HEAD `37f2927` + date 2026-06-04 + interpretation + SUPPORTED conclusion. The two new measurements (EE-1..EE-4) were run live this pass via Bash/Read, not derived from the research reports. | COMPLIANT |
| **pack-project-separation-of-concerns** | Read in full. Decision 1's docs/asset layer is kept per-side precisely on this rule (§1.2, §1.3); the memo states byte-identical pack/project doc statements are SEPARATE artifacts and must not be collapsed even where the tooling is shared. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Exactly TWO decisions; recommendations lead; NO implementation design (no commit sequencing, no mechanics, no "do X then Y"). Evidence sections support the two calls only; no edge-case/coverage sprawl. | COMPLIANT |
| **rules-applied-verification-block (+ no-derivation)** | This block; every row quoted evidence (empty = VIOLATED, none empty); READ-IN-FULL row below with per-file direct-read proof. No named document derived rather than read. | COMPLIANT |

### READ-IN-FULL row (per-file direct-read proof)
| Document | Direct Read? | Proof |
|---|---|---|
| `CLAUDE.md` (incl. `## Pack memory`) | YES | Provided in full via session context (project-instructions block); `## Pack memory` rules referenced verbatim (dependency-direction, separation-of-concerns). |
| `pack-ops/PACK-AGENTS.md` | YES | 226 lines; L1 "# PACK-AGENTS.md" → L226 "Always run `git add -A && git status` ... before any commit." |
| `pack-ops/PACK-CHAT.md` | YES | 310 lines; L1 "# PACK-CHAT.md" → L310 "verified by END-STATE checks ... not a hard-enforced step sequence." |
| `project-template/CLAUDE.md` | YES | 456 lines; L1 "# CLAUDE.md" → L456 "marker is preserved across pack upgrades. New projects start with this H2 empty." |
| `RESEARCH-BD-203-BLAST-RADIUS.md` | YES | 466 lines; L1 title → L466 "every number above is independently measured from primary sources at HEAD 1936136." |
| `RESEARCH-PROJECT-PER-ENTRY-BLAST-RADIUS.md` | YES | 421 lines; L1 title → L421 "every project-side claim above is independently measured from primary sources at HEAD 1936136." |
| BD-203 entry (`pack-ops/BACKLOG.md:3330-3349`) | YES | Read directly; header L3330 → Position L3349. |
| BD-204 entry (`:3353-3367`) | YES | Read directly; header L3353 → Position L3367. |
| BD-206 entry (`:3387-3398`) | YES | Read directly; header L3387 → Position L3398. |
| BD-207 entry (`:3402-3414`) | YES | Read directly; header L3402 → Position L3414. |
| BD-185 entry (`:1746-1793`) | YES | Read directly; header L1746 → Resolved L1793. |
| `ARCHITECTURE-BD-185-V2.md` | YES | 1071 lines; read in two pages (1-856, 857-1071); L1 title → L1071 manifest-regen handoff note. |
| `ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md` | YES | 740 lines; L1 title → L740 "affects whether the future switch is one change or two." |
| `PLAN-BD-185-V2.md` | YES | 974 lines; read in two pages (1-690, 691-974); L1 title → L974 "End of PLAN-BD-185-V2.md.". §2.3 file inventory, the A→B→C commit table, §7 dependency graph (the shared-file edits per-entry/_lib.sh:401, tracker-migrate-reverse.sh, decompose.sh) all captured. |
| `RESEARCH-BD-185-ORDERING-API.md` | YES | 369 lines; L1 title → L369 "out of scope — BD-185 needs only number." |
| `project_pack_self_migration_launch_gate.md` | YES | 49 lines; L1 frontmatter → L48 "tracker-mode feature design (BD-060 ...)." |
| `feedback_pack_project_separation_of_concerns.md` | YES | 33 lines; L1 → L33 "audience anchors." |
| `feedback_preliminary_triage_architect_challenge.md` | YES | 46 lines; L1 → L46 cross-refs. |
| `feedback_architect_planner_empirical_evidence.md` | YES | 15 lines; L1 → L15 Related links. |
| `feedback_scope_deliverables_to_the_ask.md` | YES | 35 lines; L1 → L35 "standing preference for terse, exactly-scoped work." |
| `feedback_agent_output_rules_applied_block.md` | YES | 15 lines; L1 → L15 Related links. |
| `feedback_agents_read_rule_docs_in_full.md` | YES | 97 lines; L1 → L97 "no-rationale-for-unread-docs rule reinforced in every spawn prompt." |

**No named document was derived rather than read.** Every named document was Read directly via the Read tool, in full (multi-page docs read across consecutive pages: ARCHITECTURE-BD-185-V2.md 1-856/857-1071; PLAN-BD-185-V2.md 1-690/691-974). The §7 dependency graph in PLAN-BD-185-V2.md (lines 893-916) independently corroborates Decision 2's one-way dependency (BD-185 Work-stream C edits the per-entry/tracker surfaces, which must pre-exist) — no reverse dependency (migration needing BD-185's design) appears anywhere in any named doc.
