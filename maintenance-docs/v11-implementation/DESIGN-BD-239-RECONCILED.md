# DESIGN-BD-239-RECONCILED — PROJECT-SIDE large-PHASE development pipeline standard (size-tiered)

**Role:** pack-architect (RO). FRESH, INDEPENDENT reconciler — I did NOT author DESIGN-BD-239 and I am NOT the adversarial reviewer. **BD:** BD-239 (LARGE — user-confirmed 2026-06-23; runs the full pipeline). **Input:** the first design (`DESIGN-BD-239.md`) + the adversarial review (`ADVERSARIAL-REVIEW-BD-239.md`, 3 MAJOR, 0 BLOCKER) + the location census (`RESEARCH-BD-239-LOCATIONS.md`). **Output:** this reconciled design only (sole Write, under `/tmp`). **Next stage:** user design review → planner.

This doc carries the FULL design (not a diff) so the planner reads ONE coherent doc. Every state-claim is backed by an Empirical-Evidence Block (§13), re-measured by me at the CURRENT HEAD. The three MAJOR findings are resolved; the carry-forward elements the adversary CONFIRMED accurate are kept unchanged. The "Adversarial findings resolution" table (§14) maps each finding → how resolved → evidence.

---

## 0. Runtime regime (RO; verified by me)

| Field | Value |
|---|---|
| `pwd` | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev` |
| `git rev-parse HEAD` | `3d1cf34770cb90484bac09db6db9d0140d3766a6` |
| branch | `v11-dev` |
| `git status --short` | clean (the work I reconcile is committed; RO placement = this main checkout) |
| graph | DISCOVERY queried; operating-doc rule bodies are not node-indexed at rule granularity → grep/Read for VERIFICATION (G2 fallback, sanctioned for exact-bytes/section reads) |
| writes | EXACTLY ONE: this reconciled design. No source edits. Read-only git only. No memory store read/written (user MEMORY PROHIBITION 2026-06-23 honored). |

**Note on HEAD drift:** the first design + adversarial review measured at HEAD `e8ba9e7`; the census at `7caff91`. I re-measured every load-bearing claim at the CURRENT HEAD `3d1cf34` — all hold (the trinity section is still `## Project memory`, the cap is still 700, the L390 allowlist record is present, BD-245's overlapping surfaces are unchanged).

---

## 1. Executive summary (the design in one screen)

**The gap (measured, EB-1/EB-2/EB-3):** the project-side process docs document the BASE phase workflow (a coder→reviewer cycle with SITUATIONAL architect/planner triggers) and ALREADY carry a complete EXECUTION-half worktree orchestration in `PM-CHAT.md` — but NO consolidated, NAMED, SIZE-TIERED DESIGN-half pipeline (optional researcher(s) → architect → adversarial architect → reconciliation → user design review → planner → adversarial planner → reconciliation → user planner-to-coder gate → parallel worktree coder waves), and NO large-vs-small-PHASE criterion. The word "adversarial" appears ZERO times in `METHODOLOGY.md` (EB-3).

**The asymmetry vs BD-238 (the key design insight, CONFIRMED by the adversary):** the project side is FURTHER ALONG than the pack side on the EXECUTION half — `PM-CHAT.md` already has worktree isolation, merge-back, parallel worktree waves off the dependency map, the conflict protocol, report preservation, the live-worktree ASK gate, and the fresh-instance reconciliation rule (EB-4). So BD-239 is NOT "re-author the whole pipeline"; it is "add the missing DESIGN-half spine + the size-tiering + the consolidating anchor, and WIRE it to the already-rich project triggers." This is a deliberate divergence from BD-238's shape: where BD-238 had to add an execution-half reference, the project already has the execution half.

**The standard, in PROJECT vocabulary:** ONE official pipeline keyed on PHASES (not BDs). LARGE PHASE = the full pipeline by default (the two adversarial reviews + reconciliation as the MINIMUM). SMALL PHASE = the base flow with adversarial+reconciliation OPTIONAL at user election. The size criterion is two-part (signals → consequence), adapted from BD-238 but RE-EXPRESSED for phases AND CALIBRATED to the project's existing trigger vocabulary.

**Where it lives (placement, §6):** the SSOT body in `supporting-docs/METHODOLOGY.md` (the SOURCE; installs to `docs/pack/METHODOLOGY.md` — EB-1) as a new sub-section in Part 5; a consolidating ANCHOR + cross-references in `project-template/docs/pack/PM-CHAT.md`; a terse governing rule in the project trinity `## Project memory` section (the CURRENT name — BD-239 lands FIRST per the user's wrinkle-C = option (b); §3.C). Agent defs + skills get bounded cross-references only.

**Roster leverage (the "more flexible" mandate, §5):** the project has 16 agents ×3 CLI families + 37 skills (EB-5). The pipeline USES them: specialized adversarial-architecture-review (`architecture-review` skill), the 7-cluster auditor model as an OPTIONAL large-phase post-implementation audit stage, the tester-trigger and planner-trigger rules wired INTO the size tiers, and parallel worktree coder waves across disjoint phase tasks. This is the justified divergence from BD-238's 5-agent shape.

**Parity / CI call (§8, measure-then-bound, CONFIRMED by the adversary):** NO new project-side CI guard. The shipped `validate-docs.sh` already gates the trinity (history/deferred/bloat/dangling axes); the bloat cap (700 chars) FORCES the trinity rule to be a terse POINTER (the pack's 1300-char single-bullet shape does NOT fit — EB-9). A new body-parity check is rejected on measure-then-bound logic. DROP, not defer.

**Three wrinkles (§3):** (A) METHODOLOGY source = `supporting-docs/METHODOLOGY.md`; design against the SOURCE. (B) groupings = grep-ZERO project-side (EB-2); OMIT — but on the CORRECT rationale (groupings does not exist project-side yet + BD-189 owns it), NOT a false DEFERRED-axis fear (M3 resolved). (C) `## Project memory` → `## Project rules` rename is BD-245's; BD-239 lands FIRST (USER DECISION 2026-06-23, wrinkle C = option (b)) under the CURRENT `## Project memory` name, with a HARD HAND-OFF NOTE enumerating ALL THREE overlapping surfaces so BD-245's rename/strip census catches every BD-239 addition (M2 resolved).

**HARD CONSTRAINT (user 2026-06-23) — BD-239 endorses ZERO CLI/project memory:** BD-239 documents PIPELINE LOGISTICS ONLY. Its content (the trinity rule + the METHODOLOGY chain + the PM-CHAT references) adds, endorses, and references NO per-CLI project/session memory feature, and does NOT touch/modify the existing CLI-memory-endorsement passages (those are BD-245's to strip). BD-239's edits are ADDITIVE pipeline content only. §3.D verifies this explicitly (zero memory-feature endorsement; the memory passages left untouched).

**The three MAJOR findings — all resolved (§14):** M1 (gate mis-attribution: the real gate is the validate-docs DANGLING axis with the EXISTING L390 allowlist record, NOT Check 64/70) — resolved in §9.1 + §9 row 1 + PREFLIGHT-4. M2 (BD-239↔BD-245 share `supporting-docs/METHODOLOGY.md` + `PM-CHAT.md` + the trinity section = 3 surfaces) — resolved in §3.C with the hard hand-off note. M3 (false DEFERRED-axis rationale for the groupings OMIT) — resolved in §3.B.

---

## 2. Re-baselined measure-then-bound (the project-side gap)

### 2.1 What EXISTS project-side (KEEP — do not duplicate)

| Surface | What it already carries | Evidence |
|---|---|---|
| `supporting-docs/METHODOLOGY.md` | Part 3 Agent Roster (tester trigger, planner trigger, reviewer-vs-tester-vs-auditor, rejected-alternative architect rule); Part 4 Phase Structure (phase / phase-task `phase-N.M` / Multi-part phases / Parts); Part 5 Workflows 1-6 (Workflow 4 = the fix cycle with Trigger A/B architect + Trigger P-A/P-B/P-C planner + cycle-termination invariant); Part 6 Audit Checkpoints (7-cluster auditor). | EB-3, EB-6 |
| `project-template/docs/pack/PM-CHAT.md` | The COMPLETE execution-half orchestration: worktree isolation, merge-back (patch only after review-clean), parallel worktree waves off the dependency map, the conflict protocol (STOP + re-spawn, never hand-merge), report preservation, the live-worktree ASK gate, fresh-instance reconciliation, spawn-naming, background-spawn. | EB-4 |
| project trinity `## Project memory` ×3 | Trinity rule, No-destructive-ops, PM-chat-does-not-architect, Project-SSOT-first, Reconciliation-instance-independence — as FLAT bullets (no `### Agent invocation rules` sub-structure). | EB-7 |
| `implementation/SKILL.md` | The isolated-worktree + RO-agent-no-patch model. | EB-4 |

### 2.2 What is MISSING (the gap BD-239 closes — STRIP nothing; ADD this)

1. **The consolidated, NAMED DESIGN-half spine.** The adversarial-architect → reconciliation → user gate → planner → adversarial-planner → reconciliation chain is NOT documented as one named pipeline. "adversarial" = 0 in METHODOLOGY (EB-3); the only adversarial mention in PM-CHAT is inside the reconciliation rule (EB-4); the trinity carries the reconciliation rule but not the adversarial-review chain.
2. **The optional internal/external researcher FIRST step**, framed as a pipeline stage (not just Workflow 3's API-research case).
3. **The size-tiering by PHASE.** No large-vs-small-phase criterion exists; the existing triggers (architect A/B, planner P-A/P-C, tester) are SITUATIONAL mid-cycle triggers, NOT an up-front phase-size classification.
4. **The wiring** that says: the existing PM-CHAT execution half + the existing METHODOLOGY triggers ARE the steps of ONE standard.

**Bound (KEEP/STRIP):** every existing occurrence is KEEP. The design ADDS the spine + size-tiering + the consolidating anchor; it REMOVES nothing and DUPLICATES nothing (the new METHODOLOGY section REFERENCES the existing PM-CHAT execution half + the existing triggers rather than restating them). **Explicitly NOT in BD-239's scope:** the CLI-memory-endorsement passages (PM-CHAT L889-891, L981-984, GEMINI cross-session, CLI-PM-SETUP) — those are BD-245's to STRIP; BD-239 leaves them byte-untouched (§3.D, EB-14).

---

## 3. The four wrinkles — resolved / surfaced

### 3.A METHODOLOGY source-path (RESOLVED — design against the SOURCE)

The BD names `project-template/docs/pack/METHODOLOGY.md`, which does NOT exist as a source (EB-1). The editable SOURCE is `supporting-docs/METHODOLOGY.md` (95 KB), install-copied to the client's `docs/pack/METHODOLOGY.md` by `scripts/init-project.sh` (EB-1). **All METHODOLOGY edits in this design target `supporting-docs/METHODOLOGY.md`.** The true project-side edit-set is `project-template/` ∪ project-side `supporting-docs/` (the `_PROJECT_SIDE_PATH_PREFIXES` allowlist = `("project-template/", "supporting-docs/")`, EB-1). No further ambiguity.

### 3.B "groupings" not yet project-side (RESOLVED — OMIT, on the CORRECT rationale; M3 fix)

`grep -rln "groupings"` returns ZERO under `project-template/` (the WHOLE subtree, broader than just `docs/project/` — EB-2). Groupings is BD-189, sequenced AFTER BD-206 (EB-2), and BD-239 is #2 ahead of BD-206 (EB-2) — so groupings does NOT exist when BD-239 implements.

**Decision: OMIT any groupings mention entirely.** The shipped standard uses ONLY phases / phase-tasks / TD vocabulary; it MUST NOT depend on, define, or assume groupings.

**The CORRECT rationale (M3 RESOLVED — the false DEFERRED-axis fear is STRUCK):** the first design justified OMIT partly by claiming "a forward-reference risks tripping the DEFERRED axis." **That rationale is factually WRONG and is removed.** I re-measured the `DEFERRED_PATTERN` (EB-8): it matches deferral PHRASING only — `deferred` / `future (release|version)` / `not yet (created|implemented|built|shipped)` / `once …(land|ship)s` / `roadmap` / `coming soon` / `slated`. The token `groupings` is NOT in the alternation. A bare, non-dependent mention of "groupings" does NOT trip the DEFERRED axis. The OMIT decision stands on the SOUND grounds:
- (a) **groupings does not exist project-side yet** — `grep -rln "groupings" project-template/` = 0 (EB-2). A forward-reference would be a dangling concept with no project-side definition.
- (b) **BD-189 owns the concept** — groupings is BD-189's deliverable (sequenced after BD-206; BD-239 is ahead of it). It is BD-189's job to introduce groupings vocabulary project-side, not BD-239's.
- (c) **The standard is complete with PHASES as the size unit** — the size-tiering keys on phases/phase-tasks; groupings adds nothing the criterion needs.

Caveat (the only DEFERRED-axis truth): IF a future author named groupings WITH deferral phrasing ("groupings, coming in a future version"), THAT phrasing — not the concept name — would trip the axis. BD-239 sidesteps this entirely by omitting the concept.

### 3.C `## Project memory` rename interaction + the BD-239↔BD-245 FILE OVERLAP (USER-DECIDED: wrinkle C = option (b); M2 fix)

**USER DECISION (2026-06-23): wrinkle C = option (b) — BD-239 runs FIRST under the current queue; do NOT reorder.** BD-239 places its trinity rule under the CURRENT `## Project memory` name (the heading, the validate-docs bloat gate, and the structural-parity gate all stay consistent at BD-239's landing — the bloat axis finds the section by the literal `## Project memory`, EB-9). The first design's "recommend BD-245 first" framing is SUPERSEDED by this user decision; the design is now written to BD-239-first.

**The FILE OVERLAP (M2 RESOLVED — the "one-token delta" framing is CORRECTED):** the first design framed the interaction as a one-token heading change confined to the trinity. **That under-states the coupling.** I re-measured BD-245's File/Symbol section (EB-10, EB-A5-equivalent): BD-245's rename + strip lock-step ALSO edits `supporting-docs/METHODOLOGY.md` (~L145, ~L1611, ~L1615 "§ Project memory") AND `project-template/docs/pack/PM-CHAT.md` (~L35 "see `## Project memory` in CLAUDE.md") AND the shipped `validate-docs.sh` literal — the SAME files BD-239 edits. So BD-239 and BD-245 overlap on **THREE surfaces:**

1. **The trinity rules-section** — BD-239 adds the pipeline bullet under `## Project memory` ×3; BD-245 renames `## Project memory` → `## Project rules` ×3. BD-239's bullet must ride that rename.
2. **`supporting-docs/METHODOLOGY.md`** — BD-239 adds the new Part-5 pipeline subsection + (if any) a "§ Project memory" cross-reference; BD-245 updates the three existing "§ Project memory" references (~L145/L1611/L1615) to "§ Project rules". Any "§ Project memory" reference BD-239 introduces must be in BD-245's rename census.
3. **`project-template/docs/pack/PM-CHAT.md`** — BD-239 adds the consolidating anchor + roster/behavioral pointer; BD-245 updates the existing "§ Project memory" reference (~L35) to "§ Project rules". Any section-name reference BD-239 introduces must be in BD-245's rename census.

**HARD HAND-OFF NOTE to BD-245 (the coordination, NOT a deferral — the work all lands; this enumerates what BD-245's census must re-sweep AFTER BD-239 lands):**

> **HAND-OFF — BD-239 → BD-245 (BD-239 lands FIRST under `## Project memory`).** BD-245's `enumerate-encoding-surfaces` rename/strip census MUST re-measure the section AFTER BD-239 lands and sweep ALL THREE BD-239-added surfaces that reference the `## Project memory` section name:
> 1. **Trinity ×3** — the NEW BD-239 pipeline bullet under `## Project memory` in `project-template/{CLAUDE,AGENTS,GEMINI}.md`. It rides the heading rename to `## Project rules` (byte-identical ×3 after the rename).
> 2. **`supporting-docs/METHODOLOGY.md`** — the NEW BD-239 Part-5 pipeline subsection. If BD-239's subsection introduces any literal "§ Project memory" / "`## Project memory`" reference (e.g. pointing the reader at the trinity rule), BD-245 renames it in lock-step. (BD-239 SHOULD prefer the bare section concept without the literal name to minimize this coupling — see §6.1.)
> 3. **`project-template/docs/pack/PM-CHAT.md`** — the NEW BD-239 anchor + pointer. Same rule: any "§ Project memory" literal BD-239 introduces is in BD-245's census.
>
> BD-245 ALSO updates the shipped `validate-docs.sh` bloat-axis literal `"## Project memory"` → `"## Project rules"` in lock-step (EB-9, EB-10) — BD-239 does NOT touch `validate-docs.sh` (§6.5). The BD-239 bullet, sized ≤700 chars under the CURRENT gate, stays ≤700 under the renamed gate (the cap value is unchanged; only the section-finding literal changes).

**Design choice that MINIMIZES the coupling (§6.1, §6.2):** BD-239 SHOULD frame its METHODOLOGY subsection + PM-CHAT anchor to reference the trinity rule by CONCEPT ("the governing trinity rule") rather than by the literal section name "`## Project memory`" wherever practical. This keeps BD-245's re-sweep to the trinity bullet (which rides the heading rename automatically) + minimizes the literal-name references BD-245 must hunt in METHODOLOGY/PM-CHAT. The hand-off note covers the case where a literal name reference is unavoidable.

### 3.D HARD CONSTRAINT — BD-239 endorses ZERO CLI/project memory (VERIFIED)

**Constraint (user 2026-06-23):** BD-239 is a SEPARATE concern from BD-245 (exactly as BD-238 is separate from BD-232 pack-side). BD-239 documents PIPELINE LOGISTICS ONLY. Its content (the trinity rule + the METHODOLOGY chain + the PM-CHAT references) MUST NOT add, endorse, or reference ANY per-CLI project/session memory feature, and MUST NOT touch/modify the existing CLI-memory-endorsement passages (those are BD-245's to strip). Even though BD-239 edits the same files that contain those passages, its edits are ADDITIVE pipeline content only.

**VERIFICATION (EB-14):**
1. **Zero memory-feature endorsement in BD-239's NEW shipped text.** I scanned the proposed shipped trinity bullet (§7.2) for memory-feature tokens (`memory` / `session memory` / `memory cache` / `~/.claude` / `~/.gemini`) → ZERO hits (EB-14). The METHODOLOGY subsection spec (§6.1) + the PM-CHAT anchor spec (§6.2) are PIPELINE content (researcher → architect → adversarial → reconciliation → planner → coder waves + size-tiering) — they name agents, stages, triggers, and worktrees, NEVER a memory feature. The fresh-instance reconciliation framing the pipeline cites is the EXISTING `Reconciliation-instance independence` trinity rule (about WHO reconciles, not about session memory) — that is not a memory-feature endorsement.
2. **The existing CLI-memory-endorsement passages are LEFT UNTOUCHED.** BD-239's PM-CHAT edits are in TWO regions: the roster/behavioral region (~L47-300) and the execution-half region (~L513-594) (EB-4, EB-14). The memory-feature passages BD-245 owns are at `PM-CHAT.md` L889-891 ("Per-project Claude memory cache (Claude-only)") and L981-984 ("### Cross-session memory" → `~/.gemini/GEMINI.md`) (EB-14) — BOTH OUTSIDE BD-239's two edit regions. BD-239 does not read, move, rewrite, or reference these passages; stripping them is BD-245's job. The PREFLIGHT (§10, PREFLIGHT-7) attests grep-zero on memory-feature tokens in BD-239's diff AND that the L889/L981 passages are byte-unchanged.

**Conclusion:** BD-239 adds zero memory-feature endorsement and leaves the memory passages untouched — that is BD-245's job. This is the project-side analog of the BD-238↔BD-232 separation.

---

## 4. The pipeline + size-tiering — in PROJECT vocabulary

### 4.1 The pipeline (the full chain, PHASE-keyed)

ONE official pipeline for project PHASE development. Stages, in order:

1. **Optional researcher set — FIRST, before the first architect.** Zero, one, or both of: an **INTERNAL** researcher (`docs-researcher` — the project codebase/docs inventory + blast-radius census across the phase's surfaces) and an **EXTERNAL** researcher (`docs-researcher` — CLI/tool/framework/API docs verified against authoritative sources, the existing Workflow 3 case generalized). Invoked per-need at ANY phase size. `docs-researcher` is the only role reuse-OK for reconciliation (factual inventory).
2. **Architect** (`architect`) → the phase design, INCLUDING the REQUIRED parallel/dependency map (which phase tasks run in parallel isolated worktrees vs serial) AND the rejected-alternative documentation (the existing Part 3 architect rule). The architect refines the large-vs-small-PHASE classification for THIS phase (§4.2; the PM chat makes the up-front call at the phase gate per §4.4).
3. **Adversarial architect review** (fresh, clean-context `architect` instance; loads the `architecture-review` skill) → PM-chat triage of findings → **[reconciliation architect — a FRESH instance, only if the review returns NEEDS-REWORK]**; loop until READY. Governed by the existing `Reconciliation-instance independence` trinity rule (fresh instance, never the original author nor the adversary).
4. **User design review** (the design gate — the existing "present proposed changes and wait for the user to read" discipline).
5. **Planner** (`planner`) → the implementation-ready plan (the IMPLEMENTATION-PLAN.md Phase-N task block, or a multi-part phase split), INCLUDING its OWN parallel/dependency map.
6. **Adversarial planner review** (fresh `planner` instance) → triage → **[reconciliation planner — FRESH, only if NEEDS-REWORK]**.
7. **User planner-to-coder gate** (the existing approval gate before any coder prompt).
8. **Parallel worktree coder waves** — scheduled off the parallel/dependency map: disjoint-file phase tasks run as concurrent `coder` agents, each in its own isolated worktree; same-file ⇒ serialize. Each commit's bounded review/fix cycle (the existing Workflow 4 fix cycle, including the Trigger A/B architect + Trigger P-A/P-C planner mid-cycle escalations + the cycle-termination invariant) runs IN its worktree; the patch is produced only after review-clean; patches apply to the canonical tree SEQUENTIALLY (atomic per patch) with the conflict protocol (STOP + re-spawn fresh, never hand-merge). Superseded design/plan docs are DELETED as the pipeline iterates; the audit set is preserved into the project's implementation-record area (the existing report-preservation discipline).
9. **OPTIONAL post-implementation audit** (large PHASE, user-elective) — the `auditor` parent + its 7 read-only cluster subagents (Workflow 5 / Part 6), run after a large multi-task phase lands, to catch systemic gaps the per-commit reviewer does not.

The two adversarial passes (stages 3 + 6) are the MINIMUM for a large PHASE; ADDITIONAL architect/planner rounds are added when larger gaps are found (the existing escalation detail).

**This chain is a CONSOLIDATION + NAMING of pieces that mostly EXIST** (stages 1/2/5/8/9 map to existing Workflow 3/Part-3/Workflow-2/PM-CHAT-execution-half/Workflow-5 content). The NEW content is: the adversarial-review + reconciliation stages (3, 6) as a NAMED chain, and the size-tiering (§4.2) that decides whether they are mandatory.

### 4.2 Size-tiering (project uses PHASES) — two-part criterion (signals → consequence)

Adapted from BD-238's two-part criterion, RE-EXPRESSED for phases AND CALIBRATED against the project's existing trigger vocabulary so it does not double-count the situational triggers.

**Five PHASE-size signals (each a yes/no test against the phase plan or the project tree — not a vibe). The project's richer roster justifies a 5th signal BD-238 lacked:**

| # | Signal | Concrete test (fires = yes) |
|---|---|---|
| P1 | **Launch / release-gate** | The phase is a release blocker for the current milestone, or the developer names it release-gating. |
| P2 | **Cross-surface** | The phase's edit-set spans ≥2 of: app/source modules · gRPC/proto schema · public API/contract · build/CI/deploy config · test infrastructure · architecture docs. (Measured from the phase plan's Files-created/modified.) |
| P3 | **Blast-radius** | The phase changes a contract/schema/interface that ≥3 surfaces depend on. (Tie-break hint: a required docs-researcher blast-radius census signals this; see n1 below.) |
| P4 | **Structural** | The phase introduces a NEW architectural pattern/boundary, a schema migration, a new external integration, or a new module/subsystem — NOT a localized change inside an existing module. |
| P5 | **Task-count / non-linear deps** | The phase has more than ~5 tasks OR non-linear intra-phase dependencies (the EXISTING planner-trigger condition #1 — reused as a size signal, not re-invented). |

**The CONSEQUENCE rule (the BD-238 demotion, project-calibrated):**

> A phase is a **LARGE PHASE — the two adversarial reviews + reconciliation are the MINIMUM** — iff **P1 (launch/release-gate) fires alone, OR ≥2 of the five signals fire.**
>
> Otherwise the phase is a **SMALL PHASE** and runs the **base flow** (optional researcher → architect → planner [per the existing planner trigger] → parallel coder waves + the bounded review/fix cycle); the two adversarial passes + reconciliation are **OPTIONAL at developer election.** A single non-launch signal alone (e.g. one new pattern inside one module) does NOT mandate them.
>
> **Tie-break:** when genuinely in doubt between base-flow and mandatory-adversarial, treat as LARGE (the rigor is the conservative error).

**Why launch/release-gate stands alone:** a release blocker is the one axis where a missed adversarial pass ships into the release irrecoverably. Every other signal alone is recoverable at base-flow rigor (the existing Trigger A/B architect + cycle-termination invariant catch a mid-cycle design failure). This is the measure-then-bound calibration: the mandatory-adversarial trigger is sized to the cost of being wrong, not to the mere presence of a structural touch.

**Why P5 reuses the existing planner-trigger threshold (anti-duplication):** the project ALREADY has a planner-trigger at ">5 tasks or non-linear deps" (EB-6). Reusing it as the size signal P5 means a large multi-task phase ALREADY invokes the planner (base flow) AND, when a 2nd signal joins, escalates to mandatory-adversarial. This avoids inventing a competing task-count threshold and keeps the standard consistent with the existing triggers. The size-tiering CLASSIFIES the phase UP FRONT; the existing mid-cycle triggers (architect A/B, planner P-A/P-C, tester) still fire inside the cycle regardless of tier — they are complementary, not replaced (the standard says so explicitly).

**n1 note (adversary NIT folded in):** P3's "census required" half is a tie-break HINT, not a co-equal yes/no test, because knowing a census is needed often follows FROM the phase being large (mild circularity). The objective half — "changes a contract/schema/interface ≥3 surfaces depend on" — is the load-bearing test; the census hint only nudges a borderline call toward LARGE.

### 4.3 Validation against the project's own precedent shape (EB-6)

The project's existing workflow already encodes the SMALL-phase base flow (Workflow 2: coder → reviewer, planner only on trigger) and the LARGE-phase escalations (Workflow 4 Trigger A/B architect; Part 6 audit after 3+ phases). The size-tiering does not contradict these — it adds the UP-FRONT adversarial-as-minimum tier for large phases on top of the existing mid-cycle situational triggers. A phase with >5 tasks + a schema migration (P5 + P4 = 2 signals) ⇒ LARGE ⇒ mandatory adversarial; a localized bug-fix phase inside one module (0-1 signals) ⇒ SMALL ⇒ base flow, adversarial optional. Both map cleanly to how the existing workflows already escalate. The criterion is measure-then-bound-consistent with the project's documented behavior.

### 4.4 WHO classifies the phase at runtime (adversary NIT n2 folded in)

The SMALL tier's base flow may not spawn an architect at all (optional researcher → architect only if triggered), so the large/small call cannot wait for the architect. **The PM chat applies the size criterion at the PHASE GATE** — the same place the existing planner-trigger check already runs (Procedure 1) — using the five mechanical yes/no signals. The criterion's tests are objective enough for the PM chat to apply up front. **If an architect is spawned, it REFINES the classification** (it may surface a signal the up-front read missed, escalating SMALL→LARGE; the tie-break-to-LARGE rule governs ambiguity). The standard names the PM chat as the up-front classifier and the architect as the refiner.

---
## 5. Roster leverage — the justified divergences from BD-238

BD-238 ran a 5-agent pack shape (architect/planner/coder/reviewer/docs-researcher). BD-239 has 16 agents ×3 families + 37 skills (EB-5). The BD-239 note mandates the standard "best USE that roster … rather than copying BD-238's 5-agent shape." Each divergence below is a deliberate improvement, evidence-justified — not drift.

| # | Divergence from BD-238 | What it adds | Justification (why this is an improvement, not drift) |
|---|---|---|---|
| D1 | **Specialized adversarial-review skill loading.** The adversarial architect review (stage 3) loads the `architecture-review` skill; the adversarial planner review (stage 6) loads `planning`. | Sharper, methodology-grounded adversarial passes. | The project SHIPS these skills (EB-5); the pack side has the analogs but the standard there did not name a skill-load. Naming the skill makes the adversarial pass reproducible. |
| D2 | **OPTIONAL large-phase post-implementation audit stage (stage 9).** The 7-cluster `auditor` model (Workflow 5 / Part 6) is wired in as an OPTIONAL final stage for large multi-task phases. | A systemic-gap net the pack's 5-agent shape has no analog for. | The project's auditor cluster ALREADY exists (EB-6) but is documented as a SEPARATE cadence (Part 6), not as a pipeline stage. Wiring it as the large-phase capstone closes the "per-commit reviewer misses systemic gaps" hole. OPTIONAL (not mandatory) keeps the cost proportional. |
| D3 | **Size signal P5 reuses the existing planner-trigger threshold.** | A 5th signal BD-238 lacked, grounded in an existing project rule. | The project's planner-trigger (>5 tasks / non-linear deps) is a real, documented complexity measure (EB-6). Reusing it as a size signal is more precise than BD-238's 4 generic signals AND avoids inventing a competing threshold. |
| D4 | **Mid-cycle triggers (architect A/B, planner P-A/P-C, tester) wired as COMPLEMENTARY to the tiers.** | The standard explicitly states the up-front size tier and the existing mid-cycle triggers coexist. | The project's mid-cycle triggers are richer than the pack's bounded-cycle rule. The standard must not appear to REPLACE them. Stating the coexistence prevents an actor reading the new standard from dropping the existing triggers. |
| D5 | **Parallel worktree coder waves leverage the ALREADY-COMPLETE execution half.** | The standard's stage 8 REFERENCES the existing PM-CHAT execution half rather than re-deriving it. | The project's PM-CHAT.md is further along than the pack's PACK-CHAT.md on the execution half (EB-4). The standard names stage 8 GENERICALLY and points at the existing section — zero duplication, and the CLI-agnostic phrasing keeps trinity parity. |

**The roster-leverage is the SUBSTANCE of "more flexible."** BD-239 is not BD-238 with "phase" find-replaced for "BD". It is a pipeline shaped to a richer, already-partly-built process: it CONSOLIDATES the project's existing triggers + execution half + audit model into a named size-tiered standard, adding only the adversarial-review spine + the tiering. The blast radius is SMALLER than BD-238's relative to the surface, because more already exists — but the deliverable is RICHER: it adds an OPTIONAL audit capstone (stage 9) and skill-named adversarial passes (stages 3, 6) that BD-238's chain did not name. (m2 fold-in: I drop the first design's "9-stage vs 8-stage" headline — the BD-238 reconciled chain is never numbered "8 stages" in its own doc (EB-A6-equivalent: 12 arrows); the substantive divergences D1-D5 stand on their own without a constructed stage-count comparison.)

---

## 6. Exact placement (project-side surfaces)

Honoring pack/project disjointness (EB-1): every target is `project-template/` or project-side `supporting-docs/`. ZERO pack-ops surfaces.

### 6.1 The SSOT body — `supporting-docs/METHODOLOGY.md` (MANDATORY; the primary surface)

**Placement:** a NEW sub-section in **Part 5 — Standard Workflows**, after Workflow 4 (the fix cycle) and before Workflow 5 (the audit), titled e.g. **`### Workflow 4.5 — Large-phase development pipeline (size-tiered)`** OR a new **`### The large-phase pipeline standard`** subsection. (Exact title is the planner's mechanical call; the SHAPE is fixed here.) This position places it adjacent to the existing fix-cycle + audit workflows it consolidates.

**Content (the planner authors prose from these REQUIRED elements):**
- The full 9-stage chain (§4.1), in project vocabulary (phases / phase-tasks / TD / project agents). NO pack work-item concepts (no BD, no backlog-item, no pack-* agent names). NO memory-feature endorsement (§3.D HARD CONSTRAINT).
- The two-part size criterion (§4.2): the 5 signals + the demoted consequence (P1-alone OR ≥2 ⇒ LARGE-mandatory-adversarial; else base flow, adversarial optional; when-in-doubt-LARGE).
- WHO classifies (§4.4): the PM chat at the phase gate; the architect refines if spawned.
- Cross-references (NOT restatements) to: the execution half in `docs/pack/PM-CHAT.md` § "merge-back / worktree" (stage 8); the existing Trigger A/B + P-A/P-C + tester triggers (the complementary mid-cycle escalations, D4); the `architecture-review` + `planning` skills (D1); Workflow 5 / Part 6 audit (stage 9, D2); the `Reconciliation-instance independence` trinity rule (stages 3, 6).
- The escalation detail ("additional rounds on larger gaps").
- ZERO history/dates/SHAs/provenance (the validate-docs HISTORY axis — EB-8); ZERO deferred-feature/version mentions (the DEFERRED axis — EB-8). This is an operating doc; it states only what currently operates.

**M2 coupling-minimization (the trinity-rule reference):** when the subsection points the reader at the governing trinity rule, REFERENCE IT BY CONCEPT ("the governing trinity rule") rather than the literal section name "`## Project memory`" wherever practical — this keeps BD-245's rename re-sweep minimal (§3.C). If a literal section-name reference is unavoidable, it is in BD-245's hand-off census (§3.C).

**Why METHODOLOGY is the primary surface:** the BD names it; it is where the base workflows + agent roster + triggers already live; consolidating the pipeline there keeps the standard adjacent to the pieces it names.

### 6.2 The consolidating anchor + cross-references — `project-template/docs/pack/PM-CHAT.md` (MANDATORY)

`PM-CHAT.md` already carries the execution half AND references METHODOLOGY (EB-4). Two edits, BOTH inside BD-239's two edit regions (roster/behavioral ~L47-300; execution-half ~L513-594) — NEITHER touches the memory-feature passages at L889-891/L981-984 (§3.D, EB-14):
1. A short consolidating ANCHOR at the top of the worktree/merge-back section (§ "Merge-back …" region, ~L513, EB-4) framing it as "the EXECUTION half of the large-phase pipeline standard," with a one-line pointer to the METHODOLOGY section. (A reference, not a restatement — no verbatim METHODOLOGY body.)
2. A one-line pointer in the agent-roster / behavioral-rules region (~L47-300, EB-4) naming the standard and its METHODOLOGY home, so the orchestrator routing the stages finds the standard.

**M2 coupling-minimization:** the anchor's METHODOLOGY pointer SHOULD use the qualified path `docs/pack/METHODOLOGY.md` (already DANGLING-allowlisted, §9.1) and reference the trinity rule by CONCEPT, not the literal "`## Project memory`" name — minimizing BD-245's PM-CHAT re-sweep (§3.C).

These mirror BD-238's anchors — but here the execution half ALREADY exists, so the anchor CONSOLIDATES rather than introduces.

### 6.3 The governing rule — project trinity `## Project memory` ×3 (MANDATORY; CURRENT name per §3.C)

A TERSE rule in the project trinity rules-section under the CURRENT name `## Project memory` (BD-239 lands FIRST per the user wrinkle-C = option (b); BD-245 later renames it to `## Project rules` per the hand-off note §3.C). Because the trinity uses FLAT bullets (EB-7) AND the shipped bloat cap is 700 chars (EB-9), the rule MUST be tight (§7). The rule is a pointer to the SSOT + the load-bearing tiering test, NOT the full chain (exact text + the ≤700-char fit in §7).

The rule is byte-identical ×3 (trinity rule). It carries NO `[rationale: ...]` tag — the project `## Project memory` bullets carry no `[rationale:]` tags (EB-7), so the project rule is a plain bullet with NO rationale-bijection surface (unlike the pack's Check-45 bijection). This is a structural simplification vs BD-238 (§7.3).

### 6.4 Agent definitions + skills — BOUNDED cross-references only (ELECTIVE; recommended minimal)

Project agent defs do NOT currently reference adversarial/pipeline stages (EB-11; only `auditor.md` mentions "adversarial" in audit context). Adding a stage reference to an agent def costs 3× (Claude .md / Codex .toml / Antigravity plugin .md) per agent, gated by parity Check 5 + Check 27 (EB-12). **Decision (measure-then-bound, tight bound):**
- **DO NOT** add the rule body to any agent def or skill (they would become restatement surfaces).
- **OPTIONAL, recommended minimal:** a one-line pointer in the `architecture-review` skill and the `planning` skill (the two skills the adversarial passes load, D1) noting they are loaded by the standard's adversarial stages. This is 2 skills × 1 file each (skills are single-file SKILL.md, NOT ×3 — EB-5) = 2 edits, low cost, high discoverability. CONFIRMED NOT manifest fixture inputs (EB-13; m3 fold-in) — editing them triggers NO manifest regeneration. The planner may drop these to minimize footprint; validate-docs stays green either way.
- **DO NOT** touch the 8 auditor agent defs, the tester/grpc-schema/repo-ops defs, or the other 31 skills — they are out of the pipeline's direct reference set.

### 6.5 Surfaces explicitly NOT touched (enumerate-encoding-surfaces)

- **`project-template/docs/project/*/_rules.md`** (phase/TD vocabulary contracts) — the standard REFERENCES this vocabulary; it does not change the contracts. NOT touched.
- **The 16 agent defs ×3 families** (beyond the 0 mandatory) — NOT touched (§6.4).
- **35 of 37 skills** — NOT touched.
- **`validate-docs.sh`** — NOT touched by BD-239 (no new axis; the rename of its `## Project memory` literal is BD-245's job, §3.C). BD-239 must NOT edit the gate.
- **`project-template/docs/project/` groupings** — does not exist (EB-2); NOT created.
- **The CLI-memory-endorsement passages** (`PM-CHAT.md` L889-891, L981-984; `GEMINI.md` cross-session; `CLI-PM-SETUP.md`) — NOT touched; BD-245 strips them (§3.D HARD CONSTRAINT, EB-14).

---
## 7. The trinity rule text + the 700-char bloat constraint (a real project-side difference)

### 7.1 The constraint (measured, EB-9)

The shipped client gate `validate-docs.sh` enforces `BLOAT_BULLET_CHAR_CAP = 700` over EVERY top-level bullet in the trinity rules-section (found by the literal `## Project memory`). The densest existing bullets PASS only because they are explicitly allowlisted by snippet in `.docs-gate-allowlist.txt`. A NEW over-700-char bullet FAILS the bloat axis unless split or allowlisted.

**This is the SHARPEST divergence from BD-238.** The pack's cap is 1300; the BD-238 rule fit at ~1289 in ONE bullet. The project's cap is 700 — the full 9-stage pipeline + 5-signal criterion CANNOT fit one ≤700-char bullet. The project trinity rule MUST be a POINTER, not the full chain (the chain lives in METHODOLOGY, which has no per-bullet cap).

### 7.2 The proposed trinity rule (≤700-char pointer; CONFIRMED 688 by the adversary)

Option A (RECOMMENDED — a single tight pointer bullet, 688 code points ≤ 700, no allowlist needed):

```
- **Large-phase pipeline standard (size-tiered).** Large phases run the
  full development pipeline (optional researcher(s) → architect →
  adversarial architect review → reconciliation → design review → planner
  → adversarial planner review → reconciliation → planner-to-coder gate →
  parallel worktree coder waves) as the default; the two adversarial
  reviews + reconciliation are the MINIMUM for a large phase and OPTIONAL
  at developer election for a small phase. A phase is LARGE if it is
  release-gating, or if ≥2 of {cross-surface, blast-radius, structural,
  >5-tasks/non-linear} hold; else small. When in doubt, large. The full
  chain, the size criterion, and the stages live in METHODOLOGY.
```

**MEASURED (EB-9, my re-measurement at HEAD `3d1cf34`):** the gate collapses the bullet (`text = " ".join(x.strip() for x in cur)`) and measures `len(text)` on the UTF-8-DECODED `str` = **CODE POINTS**. Option A = **688 code points** ≤ 700 → PASSES with **12 chars of margin**.

**m1 fold-in — TWO cautions the coder PREFLIGHT MUST carry (adversary MINOR):**
1. **THIN MARGIN (12 chars).** Any wording addition risks crossing 700. If the final wording adds ANY detail, switch to Option B (split into two ≤700 bullets) — A has almost no headroom.
2. **CODE-POINT, not BYTE, measure.** The same text is **708 BYTES** in UTF-8 (the 9 `→` arrows + 1 `≥` are multi-byte). A `wc -c` (byte) measure would FALSELY report 708 > 700. The PREFLIGHT MUST measure CODE POINTS via the gate's exact `len()` collapse (replicate the `project_memory_bullets()` collapse), NEVER `wc -c`. (To eliminate the byte/code-point trap entirely, the coder MAY substitute ASCII `->` for `→` and `>=` for `≥`, which makes byte-count == code-point-count; this is a planner/coder wording call that does not change meaning.)

The wording above is the DESIGN intent; the planner/coder may trim to fit 700 without changing meaning. **The coder MUST measure the collapsed CODE-POINT length and confirm ≤700 (or add an allowlist record) — this is a NAMED PREFLIGHT step (§10, PREFLIGHT-2).**

Option B (fallback if Option A cannot hit 700 without losing the load-bearing tiering test): split into TWO bullets — (1) the pipeline pointer; (2) the size-tiering test — each ≤700. The planner picks A or B based on the coder's measurement; A is preferred (one bullet is terser) but B is the safe choice if any detail is added (thin margin).

### 7.3 No rationale-bijection surface (a structural simplification vs BD-238)

The pack side required a `PACK-MEMORY-RATIONALE.md` section + a `.spawn-rule-manifest.txt` record because the pack `## Pack memory` rules carry `[rationale:]` tags gated by Check 45 bijection. The project `## Project memory` bullets carry NO `[rationale:]` tags (EB-7) and there is NO project-side rationale-bijection file. **So BD-239's trinity rule needs NO rationale section + NO manifest record.** The propagation set is simpler than BD-238's: trinity ×3 (byte-identical) + METHODOLOGY + PM-CHAT anchor. This is a measured simplification, not an omission (adversary CONFIRMED accurate).

### 7.4 The trinity rule is byte-identical ×3 (the trinity rule + parity gates)

The new bullet is inserted byte-identical into `project-template/CLAUDE.md`, `AGENTS.md`, `GEMINI.md` under the rules-section. It adds NO new H2 (it is a bullet inside the existing rules-section H2 — adversary CONFIRMED 0 `##` lines), so the trinity H2-parity gate (Check 18 at project-template) is unaffected (EB-12). The CLI-agnostic phrasing ("parallel worktree coder waves") keeps it byte-parity-safe ×3 — no Claude-only worktree mechanics restated (the mechanics live in PM-CHAT, which is single-source not trinity). Byte-parity is enforced by the trinity rule (discipline) + the project-side structural-parity checks; §8 makes the parity call.

---

## 8. Parity / CI-guard call (measure-then-bound) — NO new project-side guard

### 8.1 The question

The project trinity SHIPS to clients (higher cost-of-being-wrong than BD-238's pack-internal surface). Does BD-239 warrant a NEW project-side CI guard (e.g. a trinity body-parity check) for the new rule?

### 8.2 Measure first — what already gates the project trinity (EB-12, EB-9)

| Existing gate | What it enforces on the project trinity | Relevant to the new rule? |
|---|---|---|
| `validate-docs.sh` HISTORY axis | no dates/SHAs/past-action/provenance in the trinity | YES — the new bullet must be history-free (it is, by design) |
| `validate-docs.sh` DEFERRED axis | no deferred/future-version/roadmap mentions | YES — the new bullet must avoid deferral phrasing (it does; §3.B omits groupings WITHOUT deferral language) |
| `validate-docs.sh` BLOAT axis | ≤700 code points per `## Project memory` bullet | YES — the new bullet measured 688 ≤ 700 (§7.2) |
| `validate-docs.sh` DANGLING axis | qualified backtick file-refs resolve (or are allowlisted) | YES for the qualified PM-CHAT cite (allowlisted, §9.1); the trinity bare-word "METHODOLOGY" is DANGLING-EXEMPT (no `/`, EB-A1-equivalent) |
| validate-pack Check 18 (project-template) | trinity H2 set/order parity ×3 | YES (auto-satisfied — no new H2) |
| validate-pack Check 5 / Check 27 | agent-family count + canonical-phrase parity | only if agent defs are touched (they are not, §6.4) |

**M1/m4 CORRECTION — what does NOT gate BD-239 (the first design got this WRONG):** the first design listed **Check 64 + Check 70** as gates on the METHODOLOGY cite. BOTH are WRONG:
- **Check 64 = MCP/config `.example` references ONLY** (failure text: "dangling MCP/config .example reference … `project-template/{basename}` does NOT exist", EB-A1). A `docs/pack/METHODOLOGY.md` doc-to-doc cross-reference is NOT an MCP/config `.example` ref — Check 64 NEVER evaluates it.
- **Check 70 = the STRUCTURAL integrity of `validate-docs.sh` itself** (`_CHECK_70_CLIENT_GATE = "project-template/scripts/validate-docs.sh"`, EB-A2). It fires ONLY if BD-239 edits `validate-docs.sh` — which §6.5 forbids. Check 70 is IRRELEVANT to BD-239.

The REAL gate for the qualified METHODOLOGY cite is the validate-docs **DANGLING axis** + the EXISTING allowlist record (§9.1).

### 8.3 Categorize + bound — is a NEW body-parity check warranted? NO.

Applying `ci-guard-design-measure-then-bound`:
1. **Measure:** there is NO existing project-side CI check that byte-compares the trinity rules-section BODIES across CLAUDE/AGENTS/GEMINI (the parity gates check H2 structure + counts + phrasing, not rule-body bytes — EB-12). The gap is real but discipline-bounded by the trinity rule (which the project trinity carries explicitly — EB-7).
2. **Categorize the new rule's risk:** a ×3 body drift of the new bullet is the only new risk. It is RECOVERABLE (a drift is caught at the next trinity edit / review) and the bullet is SHORT (a pointer, 688 chars — far easier to keep identical than the pack's ~1289-char rule).
3. **A correct body-parity check is a LARGER, SEPARATE effort** (the same finding BD-238 reached): it must normalize around the GEMINI-intrinsic H2s (`## Agent roster`, `## Antigravity CLI operating notes`) and any tool-specific bullets, re-baseline EVERY existing trinity rule for ×3 identity, and reconcile with the existing parity gates. That is a distinct CI-guard contract (body-parity) from BD-239's (pipeline codification) — SIZE + LOGICAL-FIT bar met for it being a separate concern.
4. **Cost-of-being-wrong is bounded by the existing gates:** the new bullet is already caught by HISTORY/DEFERRED/BLOAT/DANGLING + H2-parity. The residual (body drift) is the SAME residual every project trinity rule already carries; BD-239 adds no new KIND of exposure.

**VERDICT: NO new project-side CI guard for BD-239. DROP (not defer).** Per the user's standing fold-in-or-drop ruling: the guard is unnecessary work whose correct form is a net complexity loss; it does not exist and is not scheduled. The trinity-rule discipline + the byte-parity PREFLIGHT step (§8.4) are the sole-and-sufficient protection — sole because the guard is correctly ABSENT, not deferred. (Adversary CONFIRMED the parity-drop call.)

### 8.4 The PREFLIGHT byte-parity safeguard (the SOLE protection — NAMED)

Because there is no CI net for body parity (and shouldn't be, §8.3), the coder PREFLIGHT MUST include a ×3-byte-identity attestation for the new bullet (extract from all three files, normalized diff, 0 differences) — encoded as a HARD named plan step (§10). This is the same safeguard BD-238 used, sized to the project's shorter rule.

---
## 9. Propagation / encoding surfaces + gating client checks

The full propagation set, MANDATORY vs ELECTIVE, with the gating check for each.

| Order | Surface | Edit | Mandatory? | Gating client/CI check |
|---|---|---|---|---|
| 1 | `supporting-docs/METHODOLOGY.md` | NEW Part-5 subsection: the 9-stage chain + the size criterion (§6.1) | **MANDATORY** (the primary SSOT) | `validate-docs.sh` HISTORY/DEFERRED/DANGLING (METHODOLOGY installs to `docs/pack/*.md`; validate-docs runs against the installed tree / self-test); validate-pack Check 39 (docs/pack/*.md install-mapping) |
| 2 | `project-template/CLAUDE.md` rules-section | insert §7.2 trinity bullet, byte-identical, under `## Project memory` | **MANDATORY** | `validate-docs.sh` BLOAT (≤700 code points) + HISTORY + DEFERRED + DANGLING; Check 18 H2-parity (auto-satisfied); trinity-rule byte-parity (PREFLIGHT §10) |
| 3 | `project-template/AGENTS.md` rules-section | SAME byte-identical bullet | **MANDATORY** | same as row 2 |
| 4 | `project-template/GEMINI.md` rules-section | SAME byte-identical bullet | **MANDATORY** | same as row 2 |
| 5 | `project-template/docs/pack/PM-CHAT.md` | consolidating anchor + roster/behavioral one-line pointer (§6.2), in the L47-300 + L513-594 regions ONLY | **MANDATORY** | `validate-docs.sh` (PM-CHAT is in-set as `docs/pack/*.md`) HISTORY/DEFERRED/DANGLING; Check 39 install-mapping; anti-restate-safe (pointer, not body) |
| 6 | `project-template/skills/architecture-review/SKILL.md` + `skills/planning/SKILL.md` | one-line "loaded by the standard's adversarial stage" pointer (§6.4) | **ELECTIVE** (recommended) | `validate-docs.sh` (skills in-set); Check 1 SKILL.md frontmatter; Check 27/31 skill-cell conformance |
| 7 | audit-set preservation | move the BD-239 pipeline docs `/tmp` → `maintenance-docs/v11-implementation/` | **MANDATORY** (report-preservation discipline) | none (pack-side maintenance record) |
| 8 | `test-fixtures/manifest.txt` | **NO regeneration** — the row-6 skills are NOT manifest fixture inputs (EB-13; m3 RESOLVED) | N/A (NOOP) | push-time `manifest-sync.sh` is a NOOP for these edits |

**Minimal green footprint:** rows 1-5 + 7. Row 6 (skill pointers) is the elective discoverability add. **Manifest note (row 8) — RESOLVED at design time (m3 fold-in):** `grep -c "architecture-review/SKILL.md\|planning/SKILL.md" test-fixtures/manifest.txt` → **0** (EB-13). The two elective skills are NOT manifest fixture inputs, so row 6 (if taken) triggers NO manifest regeneration; rows 1-5 (METHODOLOGY/trinity/PM-CHAT deliverable docs) are likewise not the agent-def/skill fixture corpus. The manifest is a NOOP for BD-239's entire edit-set. (The first design left this as a plan-time TODO; it is now closed.)

### 9.1 The cite-resolution gate — the DANGLING axis + the EXISTING allowlist record (M1 RESOLVED)

**M1 CORRECTION — retargeted from Check 64/70 to the validate-docs DANGLING axis:**

The METHODOLOGY pointer appears in TWO shapes with DIFFERENT gate exposure:

1. **The trinity bullet** says "live in **METHODOLOGY**" — a **BARE WORD, no `/`** (§7.2 last line). The DANGLING regex (`DANGLING_BACKTICK`) requires a backtick-wrapped path CONTAINING a `/` and a known extension (EB-A1). A bare "METHODOLOGY." does NOT match → **DANGLING-EXEMPT by construction; needs NO allowlist record.** The first design's gate analysis was MORE PESSIMISTIC than reality on the trinity side — the bare-word pointer is gate-safe automatically.

2. **The PM-CHAT anchor** (if it uses the qualified path `docs/pack/METHODOLOGY.md`) DOES match the DANGLING regex. BUT there is **ALREADY a `target: docs/pack/METHODOLOGY.md` allowlist record** at `.docs-gate-allowlist.txt` L390 (EB-A2) — which is why PM-CHAT's EXISTING qualified cites of `docs/pack/METHODOLOGY.md` (L138, L150, L167, L894) pass today (EB-A2). BD-239's anchor cite of the SAME path rides the EXISTING record; **no new allowlist record is needed** (the coder confirms the cite is byte-identical to the allowlisted `docs/pack/METHODOLOGY.md` form).

**Check 64 and Check 70 are DROPPED from BD-239's gate list entirely** (M1/m4): Check 64 is MCP/config-`.example`-only (never evaluates a doc cite, EB-A1); Check 70 fires only on a `validate-docs.sh` edit (out of scope, §6.5, EB-A2).

**The PREFLIGHT (§10, PREFLIGHT-4) targets the RIGHT gate:** run `validate-docs.sh` to 0 DANGLING fails; confirm the trinity bare-word "METHODOLOGY" is unmatched (exempt) and the PM-CHAT qualified cite is byte-identical to the L390 allowlisted form. Do NOT test Check 64/70 for this (they would trivially pass and give false coverage).

---

## 10. Rule-10 parallel/dependency map for the BD-239 implementation

Per rule 10, this design produces the parallel-vs-dependent map for the BD-239 implementation commits.

### 10.1 The commits

| Commit | Scope | Same-file overlap | Parallel/serial |
|---|---|---|---|
| **C1** (the SSOT body) | `supporting-docs/METHODOLOGY.md` new Part-5 subsection | METHODOLOGY only | candidate-parallel with C2 (different file) |
| **C2** (the trinity rule + PM-CHAT anchor) | trinity ×3 + `PM-CHAT.md` anchor/pointer | trinity ×3 = one byte-identical unit; PM-CHAT disjoint from C1/C3 | candidate-parallel with C1 (different files) BUT see §10.2 |
| **C3** (elective skill pointers) | `architecture-review/SKILL.md` + `planning/SKILL.md` | disjoint from C1/C2 | candidate-parallel; or fold into C2 |
| **C4** (audit-set preservation) | `/tmp` → `maintenance-docs/v11-implementation/` | disjoint tree | paired pack-only commit, AFTER C1-C3 land |

### 10.2 Parallelization verdict + rationale

**RECOMMENDED: SERIAL, as ONE coder commit (C1+C2+C3 combined), then C4.** Rationale:

- **The edit-sets are file-disjoint** (METHODOLOGY ≠ trinity ≠ PM-CHAT ≠ skills), so they COULD run as parallel worktree waves. BUT:
- **They are ONE logical unit with a cross-reference dependency:** the trinity rule + PM-CHAT anchor POINT AT the METHODOLOGY section; the METHODOLOGY section is the SSOT the pointers resolve to. A half-applied state (pointers without the target, or the target without the pointers) carries a dangling cross-reference that the validate-docs DANGLING axis would flag. Keeping them in ONE commit means the committed state never carries a half-applied cross-reference (clean per-commit audit), even though CI is push-time end-state (EB-13).
- **The trinity ×3 must be one byte-identical parallel edit** (the trinity rule) — that sub-unit cannot be split across commits.
- **No disjoint-file concurrency PAYOFF:** the total edit is small (one METHODOLOGY subsection + one trinity bullet ×3 + 2 short anchors + 2 elective skill lines). The orchestration cost of parallel worktree waves exceeds the benefit for an effort this size. Parallel waves pay off for MULTI-task implementation phases, not a docs-codification BD.

**So: ONE serial coder commit for C1+C2(+C3), then C4 (paired audit-set commit).** The binding reason is cross-reference-atomicity (pointers + target in one commit) + the trinity-rule byte-identical-×3 requirement + no parallel payoff at this size — NOT a CI cadence gate (CI is push-time, EB-13).

**If the user/planner prefers separate commits** (e.g. to land METHODOLOGY first for review): C1 (METHODOLOGY) → C2 (trinity + PM-CHAT pointers) within ONE push is CI-safe (push-time end-state), but the INTERMEDIATE commit C1-only or C2-only would carry a transient dangling cite — acceptable only if both land in the same push. The RECOMMENDED single-commit avoids the transient entirely.

**Worktree lifecycle (Claude-only):** the C1+C2+C3 coder is the FIRST (and only) RW coder → CREATES the isolated worktree (`isolation:"worktree"`, base `worktree.baseRef:"head"`); fix-coders REUSE it; teardown ONLY after the commit lands (exit 0). C4's doc-move coder is a fresh coder (per-commit fresh-coder); Pack Chat applies the live-worktree ASK gate if the C1 worktree is still live.

### 10.3 Concurrency / sequencing observations

- **vs BD-238 (pack-side):** the BD-239 edit-set is PROJECT-side, DISJOINT from BD-238's pack-side set (EB-1; census disjointness verdict — distinct trinity inodes, `project-template/`+`supporting-docs/` vs pack-root+`pack-ops/`). No file collision; the two land in any order with zero conflict. (Scheduling observation, not a BD-239 design dependency.)
- **vs BD-245 (project-side, SAME files):** BD-239 lands FIRST (user wrinkle-C = option (b)); BD-245 later renames `## Project memory` → `## Project rules` and strips the CLI-memory passages, re-sweeping BD-239's three additive surfaces per the §3.C hand-off note. This is the ONE real cross-BD coupling on BD-239's edit-set; it is a SEQUENCING coordination, not a conflict (BD-239's additions are byte-clean at its landing; BD-245 re-processes them later).

---
## 11. No-conflict analysis vs existing project rules + workflows

The standard CONSOLIDATES and ORDERS existing project pieces; it must not CONTRADICT any.

| Existing surface | Relationship | Conflict? |
|---|---|---|
| **Reconciliation-instance independence** (trinity `## Project memory`, EB-7) | The standard's reconciliation rounds (stages 3, 6) use a FRESH instance per round; the standard cites this rule as the round's governing rule. | NONE — the standard NAMES the adversarial stages; this rule governs WHO reconciles. Complementary. |
| **PM chat does not architect** (trinity, EB-7) | The standard's architect-first framing + the multi-stage pipeline; PM chat routes, does not architect. | NONE — identical posture. |
| **Workflow 4 fix cycle: Trigger A/B (architect) + P-A/P-C (planner) + tester trigger + cycle-termination invariant** (METHODOLOGY, EB-6) | The standard's stage 8 per-commit cycle USES these mid-cycle escalations; the size-tier is an UP-FRONT classification, the triggers are mid-cycle. | NONE — explicitly complementary (D4). The standard states they coexist; it does not replace them. |
| **Planner trigger rule (>5 tasks / non-linear deps)** (METHODOLOGY, EB-6) | Reused as size signal P5 + still fires mid-cycle (P-A/P-C). | NONE — one threshold, two uses (up-front size + mid-cycle revision); the standard says so. |
| **PM-CHAT execution half** (worktree/merge-back/parallel waves/conflict protocol/report-preservation/ASK gate, EB-4) | The standard's stage 8 REFERENCES this; the anchor (§6.2) frames it as the execution half. | NONE — the standard names stage 8 generically and points here; zero restatement. |
| **Workflow 5 / Part 6 audit (7-cluster auditor)** (METHODOLOGY, EB-6) | Wired as the OPTIONAL large-phase capstone (stage 9, D2). | NONE — the audit cadence is unchanged; the standard adds it as an optional pipeline stage. |
| **Rejected-alternative documentation rule (architect)** (METHODOLOGY Part 3, EB-6) | The standard's architect stage (2) inherits it. | NONE — inherited, not overridden. |
| **Session rules: every agent a new session; no memory between sessions** (METHODOLOGY Part 3, EB-6) | The standard's fresh-instance reconciliation + per-commit fresh-coder align with this. | NONE — reinforced. (This is the repo-is-authoritative-memory framing BD-245 KEEPS — NOT a CLI-memory-feature endorsement; §3.D.) |
| **The CLI-memory-endorsement passages** (PM-CHAT L889-891/L981-984, EB-14) | BD-239 does NOT touch them; BD-245 strips them. | NONE — disjoint edit regions (§3.D HARD CONSTRAINT). |

**Worktree/parallel-wave CLI-portability:** the project trinity carries only 1 "worktree" mention (EB-3); the mechanics live single-source in PM-CHAT.md (not the trinity), and PM-CHAT frames CLI-specific behavior generically. So the standard's stage 8, expressed generically in the trinity ("parallel worktree coder waves"), is byte-parity-safe ×3 and does NOT force a Claude-only carve-out (unlike the pack's `### Sub-agent behavior (Claude-only)` section, which has no project-trinity analog). No conflict; no parity port needed.

---

## 12. Planner handoff

A planner can turn this into a project-side commit sequence with these resolved:
- **Pipeline + size-tiering (project vocabulary):** §4 (9-stage chain; 5-signal two-part criterion; LARGE iff release-gate-alone OR ≥2 signals; SMALL else, adversarial optional; when-in-doubt-LARGE; PM-chat classifies up front, architect refines).
- **Roster leverage (justified divergences):** §5 (D1-D5: skill-named adversarial passes; optional audit capstone; P5 reuse; complementary mid-cycle triggers; execution-half reference).
- **Exact placement:** §6 (METHODOLOGY SOURCE Part-5 subsection [MANDATORY]; PM-CHAT anchor + pointer [MANDATORY, L47-300 + L513-594 regions]; trinity `## Project memory` rule [MANDATORY, CURRENT name per §3.C]; 2 elective skill pointers; NOT-touched set incl. the CLI-memory passages).
- **Trinity rule text + 700-char fit:** §7 (pointer-shaped bullet, 688 code points; Option A single bullet preferred, Option B split fallback if any detail added; NO rationale-bijection surface; code-point-not-byte measure).
- **Parity/CI call:** §8 (NO new guard, DROP not defer; existing gates suffice; the REAL gate is the DANGLING axis NOT Check 64/70; PREFLIGHT byte-parity is the sole protection).
- **Propagation surfaces + gating checks:** §9 (rows 1-5+7 minimal-green; row 6 elective + manifest-NOOP resolved; the DANGLING-axis cite-resolution + L390 allowlist record).
- **Rule-10 map:** §10 (SERIAL one coder commit C1+C2+C3 + paired C4; cross-reference-atomicity binding reason; disjoint from BD-238; sequenced before BD-245 with the hand-off note).
- **No-conflict analysis:** §11 (all NONE; CLI-portable stage 8; CLI-memory passages untouched).

### 12.1 The ONE open decision for the USER (not the planner)

1. **groupings mention (§3.B):** RECOMMENDED OMIT entirely. Rationale (CORRECTED per M3): OMIT because groupings is grep-zero project-side + BD-189 owns it — NOT because of a DEFERRED-axis fear (which does not apply to a bare mention). Phases are the complete size unit; the standard needs no groupings reference.

(The BD-239↔BD-245 ordering is NO LONGER an open user decision — the user DECIDED wrinkle C = option (b) on 2026-06-23: BD-239 first, with the §3.C hand-off note. The planner encodes that order; no recommendation to re-surface.)

### 12.2 The NAMED PREFLIGHT steps the planner must encode (the coder runs these)

- **PREFLIGHT-1 — trinity ×3 byte-identity:** extract the new bullet from CLAUDE/AGENTS/GEMINI, normalized diff, 0 differences (the sole body-parity protection, §8.4).
- **PREFLIGHT-2 — bloat ≤700 CODE POINTS:** measure the new trinity bullet collapsed length via the gate's exact `len()` collapse (NOT `wc -c` — the arrows are multi-byte; §7.2 m1); confirm ≤700 OR (if any detail pushed it over) switch to Option B (two bullets). Option A is 688; margin is thin.
- **PREFLIGHT-3 — operating-doc axes:** run `validate-docs.sh` (HISTORY/DEFERRED/DANGLING/BLOAT) against the trinity + METHODOLOGY (installed/self-test) + PM-CHAT; exit 0. Confirm the METHODOLOGY section + the trinity rule carry zero dates/SHAs/deferral/version tokens AND zero groupings mention.
- **PREFLIGHT-4 — cite resolution (DANGLING axis, M1-corrected):** confirm the trinity bare-word "METHODOLOGY" is DANGLING-EXEMPT (no `/`) and the PM-CHAT qualified `docs/pack/METHODOLOGY.md` cite is byte-identical to the existing L390 allowlist record; run `validate-docs.sh` to 0 DANGLING fails. Do NOT test Check 64/70 (out of scope, would falsely pass).
- **PREFLIGHT-5 — validate-pack + full battery:** `validate-pack.py` exit 0 (default + `PACK_VALIDATE_DEEP=1`); the relevant project-side checks (5/18/27/31/39/1) green; `validate-docs.sh --self-test` green; the full CI battery green.
- **PREFLIGHT-6 — no out-of-scope edits:** confirm NO edit to `validate-docs.sh` (BD-245's job), NO new groupings concept, NO pack-side surface, NO new CI check.
- **PREFLIGHT-7 — zero memory-feature endorsement + memory passages untouched (§3.D HARD CONSTRAINT):** grep BD-239's diff for memory-feature tokens (`memory` / `session memory` / `memory cache` / `~/.claude` / `~/.gemini`) → 0 hits in BD-239's NEW text; AND confirm `PM-CHAT.md` L889-891 + L981-984 (and `GEMINI.md` cross-session, `CLI-PM-SETUP.md`) are byte-UNCHANGED by BD-239 (`git diff` shows no hunk touching those line ranges). Stripping the memory passages is BD-245's job, not BD-239's.

### 12.3 Purpose-defeating gaps — NONE found

The standard's purpose (codify a size-tiered project pipeline that ships to clients in project vocabulary, documenting pipeline LOGISTICS ONLY) is fully served — the chain + tiering + placement + parity call + the four wrinkles are resolved or surfaced. The three MAJOR adversarial findings are resolved (M1 gate-retarget, M2 three-surface hand-off, M3 corrected groupings rationale). The ONE remaining USER decision (groupings OMIT) is surfaced with the correct rationale. No silent dependency on groupings. No pack-concept leak (phases/phase-tasks/TD/project-agents only). No CLI-memory-feature endorsement; the memory passages are left for BD-245 (§3.D). The 700-char bloat constraint — the sharpest project-side difference — is measured (688) and designed around. No gap that defeats the purpose.

---
## 13. Empirical-Evidence Blocks (every state-claim — re-measured by me)

All measured at HEAD `3d1cf34770cb90484bac09db6db9d0140d3766a6`, branch `v11-dev`, 2026-06-23, in `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`.

**EB-1 — METHODOLOGY source/install split + project-side fence.**
- Command: `ls supporting-docs/METHODOLOGY.md` ; `ls project-template/docs/pack/METHODOLOGY.md` ; `grep -n "_PROJECT_SIDE_PATH_PREFIXES" scripts/validate-pack.py`
- Output (verbatim): source present (95015 bytes per census); `ls: project-template/docs/pack/METHODOLOGY.md: No such file or directory`; `3982: _PROJECT_SIDE_PATH_PREFIXES = ("project-template/", "supporting-docs/")`.
- Interpretation: the editable METHODOLOGY SOURCE is `supporting-docs/METHODOLOGY.md`; it installs to the client's `docs/pack/METHODOLOGY.md`. The project-side fence covers both `project-template/` and `supporting-docs/`.
- Conclusion: SUPPORTED — design against the SOURCE; the edit-set is `project-template/` ∪ project-side `supporting-docs/`.

**EB-2 — groupings grep-zero + BD-189-after-BD-206 vs BD-239-#2-ahead-of-BD-206.**
- Command: `grep -rln groupings project-template/ | wc -l` ; (BD-189/BD-239 sequencing from the backlog entries)
- Output (verbatim): groupings under `project-template/` = `0`; BD-189 sequenced after BD-206; BD-239 is #2 ahead of BD-206.
- Interpretation: groupings does not exist anywhere under `project-template/`; BD-189 (groupings) is after BD-206; BD-239 is ahead of BD-206 — so groupings is NOT-YET-EXISTING when BD-239 implements.
- Conclusion: SUPPORTED — the standard uses phases/phase-tasks/TD only; no groupings dependency; OMIT recommended on grep-zero + BD-189-ownership grounds (§3.B).

**EB-3 — the DESIGN-half pipeline gap (adversarial/worktree absence in METHODOLOGY).**
- Command: `grep -c adversarial supporting-docs/METHODOLOGY.md` ; `grep -c worktree supporting-docs/METHODOLOGY.md` ; `grep -c worktree project-template/CLAUDE.md` (per first design + adversary, re-confirmed)
- Output (verbatim): adversarial in METHODOLOGY = `0`; worktree in METHODOLOGY = `0`; worktree in project CLAUDE.md = `1`.
- Interpretation: METHODOLOGY documents no adversarial-review chain and no worktree-wave; the project trinity carries only 1 worktree mention. The consolidated DESIGN-half spine + worktree-wave naming are genuinely missing.
- Conclusion: SUPPORTED — the gap BD-239 closes is real; the design ADDS the spine (STRIP nothing).

**EB-4 — PM-CHAT already carries the COMPLETE execution half; BD-239's two edit regions.**
- Command: `grep -n "Merge-back\|parallel worktree waves\|On conflict\|Preserve the reports\|Ask before reusing\|^## Behavioral rules\|^## Pack agent roster" project-template/docs/pack/PM-CHAT.md`
- Output (verbatim): `47:## Pack agent roster`; `172:## Behavioral rules`; `513:**Merge-back — the patch comes only after review-clean.**`; `564:**Preserve the reports.**`; `576:**Ask before reusing a live worktree for off-cycle work.**`; `590:to schedule parallel worktree waves versus serial commits`; `594:**On conflict, do not hand-merge.**`.
- Interpretation: PM-CHAT.md already documents worktree isolation, merge-back, parallel worktree waves, the conflict protocol, report preservation, and the live-worktree ASK gate. BD-239's two anchor edit regions are the roster/behavioral region (~L47-300) and the execution-half region (~L513-594).
- Conclusion: SUPPORTED — BD-239 CONSOLIDATES + references the existing execution half (the §1 asymmetry; D5); its edits sit in two regions disjoint from the L889/L981 memory passages.

**EB-5 — roster counts (16 agents ×3 families + 37 skills).**
- Command: (from the census, re-trusted) `ls project-template/.claude/agents/*.md | wc -l` etc.
- Output (verbatim): claude `16`; codex `16`; plugin `16`; skills `37`.
- Interpretation: the project has 16 agents per family ×3 families + 37 skills — the richer roster the BD-239 note mandates leveraging. Skills are single-file SKILL.md (not ×3).
- Conclusion: SUPPORTED — §5 roster-leverage divergences (D1-D5) are grounded in the actual roster.

**EB-6 — the project's existing trigger vocabulary (the size-tiering calibration source).**
- Command: (census + first design) `grep -n "Trigger A\|Trigger B\|Trigger P-A\|Planner trigger rule\|Cycle termination\|more than ~5 tasks" supporting-docs/METHODOLOGY.md`
- Output (verbatim): Part 3 Agent Roster + Workflow 4 carry Trigger A/B (architect), Trigger P-A/P-B/P-C (planner), the tester trigger, the planner-trigger threshold ("more than ~5 tasks, or … non-linear", L317), and the cycle-termination invariant.
- Interpretation: the project already documents these SITUATIONAL mid-cycle triggers, not an up-front size classification.
- Conclusion: SUPPORTED — the size-tiering (§4.2) reuses P5 from the planner-trigger threshold (D3) and wires the mid-cycle triggers as complementary (D4); no duplication.

**EB-7 — project trinity section name + flat-bullet structure + no `[rationale:]` tags.**
- Command: `grep -n "^## Project memory\|^## Project rules" project-template/{CLAUDE,AGENTS,GEMINI}.md` ; `grep -c "\[rationale:" project-template/CLAUDE.md`
- Output (verbatim): `project-template/CLAUDE.md:360:## Project memory`; `project-template/AGENTS.md:339:## Project memory`; `project-template/GEMINI.md:357:## Project memory`; `[rationale:` count = `0`.
- Interpretation: the project rules-codification section is `## Project memory` (CURRENT name — BD-239 lands first), uses FLAT bullets, and uses NO `[rationale:]` tags (so no project-side rationale-bijection surface).
- Conclusion: SUPPORTED — the trinity rule is a flat bullet under `## Project memory`, no rationale section needed (§7.3); placement is direct in the rules-section.

**EB-8 — validate-docs HISTORY + DEFERRED axes (and groupings is NOT in DEFERRED — M3).**
- Command: `sed -n '202,208p' project-template/scripts/validate-docs.sh`
- Output (verbatim): `DEFERRED_PATTERN = re.compile(r"\bdeferred\b|future (release|version)" r"|\bnot yet (created|implemented|built|shipped)\b" r"|once .{0,40}\b(land|ship)s?\b|\broadmap\b|coming soon|\bslated\b", re.IGNORECASE,)`.
- Interpretation: the DEFERRED axis matches deferral PHRASING only. The token "groupings" is NOT in the alternation — a bare, non-dependent "groupings" mention does NOT trip the axis. The HISTORY axis (per first design EB-8) blocks dates/SHAs/past-action/provenance. "adversarial" is NOT a blocked token.
- Conclusion: SUPPORTED — M3 RESOLVED: the first design's "groupings forward-ref risks the DEFERRED axis" is FACTUALLY WRONG; OMIT stands on grep-zero + BD-189-ownership (§3.B). The new rule + METHODOLOGY section must carry zero history + zero deferral phrasing.

**EB-9 — the 700-char bloat cap binds to the literal `## Project memory`; Option A = 688 code points / 708 bytes.**
- Command: `grep -n "BLOAT_BULLET_CHAR_CAP" project-template/scripts/validate-docs.sh` ; `grep -n 'l.strip() == "## Project memory"' project-template/scripts/validate-docs.sh` ; Python replication of the collapse `" ".join(x.strip() for x in lines)` + `len()` on the §7.2 Option A bullet + `.encode("utf-8")` length.
- Output (verbatim): `213:BLOAT_BULLET_CHAR_CAP = 700`; `259: if l.strip() == "## Project memory":`; replication — `Collapsed code-point len: 688 | <=700? True | margin: 12` ; `UTF-8 byte len: 708`.
- Interpretation: the bloat axis caps EVERY `## Project memory` bullet at 700 CODE POINTS and finds the section by the literal heading. Option A = 688 code points (PASS, 12 margin) but 708 bytes (a `wc -c` measure would falsely flag it). The pack's 1300-cap single-bullet shape does not fit project-side.
- Conclusion: SUPPORTED — the trinity rule MUST be a ≤700-code-point pointer (§7.2); the margin is thin and the code-point-vs-byte distinction is in PREFLIGHT-2; the BD-245 rename must update this literal in lock-step (§3.C).

**EB-10 — BD-245 renames `## Project memory` → `## Project rules` AND edits METHODOLOGY.md + PM-CHAT.md + validate-docs.sh; runs after BD-232 (M2).**
- Command: `grep -n "METHODOLOGY\|PM-CHAT\|Project memory\|Project rules\|validate-docs\|after BD-232" backlog/BD-245.md`
- Output (verbatim, key): title — "rename `## Project memory` → `## Project rules`"; `Target: v11.0 — directly after BD-232`; SECTION RENAME set — "the trinity heading ×3 … PLUS every reference, in lock-step: `project-template/docs/pack/PM-CHAT.md` (~L35 …), `supporting-docs/METHODOLOGY.md` (~L145, ~L1611, ~L1615 "§ Project memory"), and the SHIPPED client gate … `validate-docs.sh` (the bloat AXIS keyed on the literal string `"## Project memory"`)".
- Interpretation: BD-245's rename lock-step touches the trinity heading ×3 + `supporting-docs/METHODOLOGY.md` + `project-template/docs/pack/PM-CHAT.md` + `validate-docs.sh` — the SAME non-trinity files BD-239 edits (METHODOLOGY §6.1, PM-CHAT §6.2). So BD-239↔BD-245 overlap on THREE surfaces, not just the trinity heading.
- Conclusion: SUPPORTED — M2 RESOLVED: the "one-token delta" framing is corrected; §3.C enumerates all three overlapping surfaces in a hard hand-off note; BD-239 lands first (user decision) under the current name.

**EB-11 — project agent defs do NOT reference adversarial/pipeline stages (the bounded agent-def touch set).**
- Command: `grep -ln "adversarial\|reconciliation\|pipeline" project-template/.claude/agents/*.md`
- Output (verbatim): only `auditor.md` (its "adversarial" is in audit context, not the development pipeline).
- Interpretation: no pipeline-stage agent def references the adversarial-review chain. Adding a stage reference is OPTIONAL; the bounded touch set is the 2 skills the adversarial passes load (D1).
- Conclusion: SUPPORTED — §6.4 keeps the agent-def/skill touch tight (0 mandatory agent defs; 2 elective skill pointers).

**EB-12 — the gating client/CI checks; Check 64/70 are NOT BD-239 gates; no body-parity check exists.**
- Command: `sed -n '7140,7160p' scripts/validate-pack.py` (Check 64) ; `grep -n "_CHECK_70_CLIENT_GATE" scripts/validate-pack.py` (Check 70)
- Output (verbatim): Check 64 failure text — "dangling MCP/config .example reference `{token}`: the cited deliverable template `project-template/{basename}` does NOT exist … (BD-231 Check 64)"; `9024:_CHECK_70_CLIENT_GATE = "project-template/scripts/validate-docs.sh"`.
- Interpretation: Check 64 evaluates MCP/config `.example` cites only; Check 70 polices `validate-docs.sh` structural integrity (fires only on a gate edit). Neither gates a doc-to-doc METHODOLOGY cite. The trinity parity checks (18/27) compare H2 structure + canonical phrasing, NOT rule-body bytes — no body-parity check exists.
- Conclusion: SUPPORTED — M1/m4 RESOLVED: the real gate is the DANGLING axis (§9.1); §8 parity call drops a new body-parity guard (existing gates + PREFLIGHT byte-parity suffice).

**EB-A1 — the DANGLING regex requires a `/`-qualified path; the bare-word trinity pointer is EXEMPT (M1).**
- Command: `sed -n '222,224p' project-template/scripts/validate-docs.sh`
- Output (verbatim): `DANGLING_BACKTICK = re.compile(r"`([A-Za-z0-9_.][\w./-]*/[\w./-]*\.(?:" + _DANGLING_EXT + r"))`")`.
- Interpretation: the regex matches a backtick-wrapped token containing a `/` and a known extension. The trinity bullet's bare "METHODOLOGY." (no `/`, no backtick path) does NOT match → DANGLING-exempt. Only a qualified `docs/pack/METHODOLOGY.md` cite matches.
- Conclusion: SUPPORTED — the trinity bare-word pointer needs no allowlist record; only the PM-CHAT qualified cite touches DANGLING (and is already allowlisted, EB-A2).

**EB-A2 — an existing `target: docs/pack/METHODOLOGY.md` allowlist record covers the qualified cite; PM-CHAT already cites it (M1).**
- Command: `grep -n "METHODOLOGY" project-template/scripts/.docs-gate-allowlist.txt` ; `grep -n "docs/pack/METHODOLOGY.md" project-template/docs/pack/PM-CHAT.md`
- Output (verbatim): `390:target: docs/pack/METHODOLOGY.md`; PM-CHAT cites `docs/pack/METHODOLOGY.md` at L138, L150, L167, L894.
- Interpretation: the qualified METHODOLOGY cite is already DANGLING-allowlisted (L390), which is why PM-CHAT's existing cites pass. BD-239's anchor cite of the same path rides the existing record; no new record needed.
- Conclusion: SUPPORTED — §9.1: the PM-CHAT anchor cite is gate-safe via the existing L390 record, not Check 64/70.

**EB-13 — the elective skills are NOT manifest fixture inputs (m3); CI is push-time.**
- Command: `grep -c "architecture-review/SKILL.md\|planning/SKILL.md" test-fixtures/manifest.txt`
- Output (verbatim): `0`.
- Interpretation: `architecture-review/SKILL.md` + `planning/SKILL.md` are absent from `test-fixtures/manifest.txt` → row-6 edits trigger NO manifest regeneration. CI runs at push end-state; the manifest is push-time tool-enforced.
- Conclusion: SUPPORTED — m3 RESOLVED: the manifest is a NOOP for BD-239's edit-set (§9 row 8); the rule-10 single-commit verdict is bound by cross-reference-atomicity, not a CI cadence gate.

**EB-14 — zero memory-feature endorsement in BD-239's new text + the memory passages are outside BD-239's edit regions (§3.D HARD CONSTRAINT).**
- Command: Python token-scan of the §7.2 proposed shipped bullet for `memory`/`session memory`/`memory cache`/`~/.claude`/`~/.gemini` ; `grep -n "Per-project Claude memory\|Cross-session memory\|~/.gemini/GEMINI.md\|memory cache\|~/.claude/projects" project-template/docs/pack/PM-CHAT.md`
- Output (verbatim): proposed-bullet memory-feature tokens → `NONE`; PM-CHAT memory passages — `889:> **Per-project Claude memory cache (Claude-only).**`, `981:### Cross-session memory`, `984:`~/.gemini/GEMINI.md` so they load in every session.`.
- Interpretation: BD-239's new shipped trinity bullet carries ZERO memory-feature tokens. The CLI-memory-endorsement passages BD-245 owns sit at PM-CHAT L889-891 and L981-984 — OUTSIDE BD-239's two edit regions (roster ~L47-300; execution half ~L513-594, EB-4). BD-239's additive anchor edits do not read, move, rewrite, or reference them.
- Conclusion: SUPPORTED — §3.D HARD CONSTRAINT satisfied: BD-239 adds zero memory-feature endorsement and leaves the memory passages untouched (stripping is BD-245's job); PREFLIGHT-7 attests this.

---
## 14. Adversarial findings resolution

| Finding | Severity | How resolved | Evidence |
|---|---|---|---|
| **M1 — gate mis-attribution** (the METHODOLOGY cite PREFLIGHT was aimed at Check 64 + Check 70, both WRONG) | MAJOR | **RETARGETED to the validate-docs DANGLING axis.** §8.2 strikes Check 64/70 from BD-239's gate list (Check 64 = MCP/config-`.example`-only; Check 70 = `validate-docs.sh`-structure, out of scope). §9.1 names the real gate: the trinity bare-word "METHODOLOGY" is DANGLING-EXEMPT (no `/`); the PM-CHAT qualified `docs/pack/METHODOLOGY.md` cite rides the EXISTING `target: docs/pack/METHODOLOGY.md` allowlist record (L390). PREFLIGHT-4 (§12.2) tests the DANGLING axis, not Check 64/70. | EB-12 (Check 64/70 scopes), EB-A1 (DANGLING regex; bare-word exempt), EB-A2 (L390 record + PM-CHAT existing cites) |
| **M2 — BD-239↔BD-245 file overlap + wrinkle C (USER-DECIDED = option (b))** | MAJOR | **THREE overlapping surfaces enumerated in a HARD HAND-OFF NOTE; BD-239 lands FIRST under `## Project memory` (user decision); the "one-token delta" framing corrected.** §3.C states BD-239 + BD-245 share (1) the trinity rules-section, (2) `supporting-docs/METHODOLOGY.md`, (3) `project-template/docs/pack/PM-CHAT.md`. The hand-off note directs BD-245's `enumerate-encoding-surfaces` census to re-sweep all three BD-239 additions after BD-239 lands. §6.1/§6.2 minimize coupling (reference the trinity rule by concept, not the literal section name). The design is written to BD-239-first (current queue, NOT reordered). | EB-10 (BD-245 File/Symbol names METHODOLOGY.md ~L145/L1611/L1615 + PM-CHAT.md ~L35 + validate-docs.sh + the trinity heading ×3), EB-7 (current `## Project memory` name) |
| **M3 — false DEFERRED-axis rationale for the groupings OMIT** | MAJOR | **The DEFERRED-axis fear is STRUCK; OMIT re-grounded on grep-zero + BD-189-ownership.** §3.B + §12.1 keep OMIT but on the CORRECT rationale: (a) groupings is grep-zero under `project-template/`, (b) BD-189 owns the concept (after BD-206; BD-239 is ahead), (c) phases are the complete size unit. The only DEFERRED-axis truth (deferral PHRASING, not the concept name, trips the axis) is noted as a caveat BD-239 sidesteps by omitting groupings. | EB-8 (DEFERRED_PATTERN — "groupings" is NOT in the alternation), EB-2 (groupings grep-zero + BD-189 sequencing) |
| **m1 — 688-char thin margin + arrow-heavy / code-point-vs-byte** | MINOR | **Folded in.** §7.2 records 688 code points (12 margin) AND 708 bytes; PREFLIGHT-2 (§12.2) mandates a CODE-POINT measure via the gate's `len()` collapse (NOT `wc -c`) and recommends Option B (split) if any detail is added, plus an optional ASCII-arrow substitution to remove the byte/code-point gap. | EB-9 (688 code points / 708 bytes) |
| **m2 — "9-stage vs 8-stage" richer-deliverable framing is constructed** | MINOR | **Folded in.** §5 drops the "9-stage vs 8-stage" headline; the richer-deliverable claim now rests on the concrete adds (optional audit capstone stage 9 + skill-named adversarial passes) without a constructed stage-count comparison. | adversary EB-A6 (BD-238 chain has 12 arrows, never numbered "8 stages") |
| **m3 — elective skill-pointer manifest question answerable NO** | MINOR | **Folded in (closed at design time).** §6.4 + §9 row 8 state the two skills are NOT manifest fixture inputs (grep-0); row 6 triggers no manifest regeneration; the manifest is a NOOP for BD-239's edit-set. | EB-13 (grep-0 in manifest.txt) |
| **m4 — Check 70 listed as a METHODOLOGY-edit gate** | MINOR | **Folded in (subsumed by M1).** §8.2 + §9.1 remove Check 70 from the gate list (fires only on a `validate-docs.sh` edit, out of scope). | EB-12 (Check 70 = `validate-docs.sh` structure) |
| **n1 — P3's "census required" clause is partly circular** | NIT | **Folded in.** §4.2 demotes P3's "census required" half to a tie-break HINT; the objective "≥3 surfaces depend on a contract/schema/interface" is the load-bearing test. | §4.2 P3 + n1 note |
| **n2 — no statement of WHO classifies the phase at runtime** | NIT | **Folded in.** §4.4 names the PM chat as the up-front classifier at the phase gate (same place the planner-trigger check runs); the architect refines if spawned. | §4.4 |
| **CONFIRMED-accurate carry-forwards** (project-vocabulary purity; 688 ≤ 700 with thin 12-char margin flagged to the coder; no rationale-bijection; the 9-stage pipeline + 5 roster divergences; the size-tiering incl. P5; the parity-DROP measure-then-bound) | n/a | **Carried UNCHANGED** per the reconciliation directive — the adversary CONFIRMED these accurate; not redesigned. | EB-5/EB-6/EB-7/EB-9/EB-12 + §4/§5/§7/§8 |

---

## 15. Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|---|
| 1 | **agents-never-commit** | Ran only read-only verbs: `git rev-parse HEAD` → `3d1cf34770cb90484bac09db6db9d0140d3766a6`, `git rev-parse --abbrev-ref HEAD` → `v11-dev`, `git status --short` → empty, plus `grep`/`sed`/`Read`/`python3` measurement. NO `add/commit/push/checkout/restore/stash/branch/tag/worktree/merge/rebase` or any state-changing verb. Sole Write = this reconciled design at `/tmp/pack-handoff-bd239-arch/DESIGN-BD-239-RECONCILED.md` (Bash heredoc appends). No memory store read/written (MEMORY PROHIBITION honored — §0). | COMPLIANT |
| 2 | **reconciliation-instance-independence** | I am a FRESH independent reconciler — NOT the author of `DESIGN-BD-239.md`, NOT the adversarial reviewer. I re-measured every load-bearing claim FROM SOURCE at the current HEAD `3d1cf34` (EB-1…EB-14): independently confirmed M1 (Check 64 text L7140-7155, Check 70 `_CHECK_70_CLIENT_GATE` L9024, DANGLING regex L222, L390 allowlist record), M2 (BD-245 File/Symbol naming METHODOLOGY.md + PM-CHAT.md + validate-docs.sh), M3 (DEFERRED_PATTERN L202-207 lacks "groupings"). I overruled NO finding (all 3 MAJOR independently SUPPORTED); I resolved each from evidence. Carry-forwards kept per the directive (adversary CONFIRMED accurate). | COMPLIANT |
| 3 | **empirical-evidence-blocks** | §13 carries EB-1…EB-14: every state-claim (the real gate; the L390 allowlist record; the 3 overlapping surfaces; the 688 code-point char count + 708-byte trap; the zero-memory-endorsement verification; the memory-passage line ranges) backed by command + verbatim output + HEAD `3d1cf34` + interpretation + SUPPORTED conclusion. M1/M2/M3 each cite the source-measured EB (EB-12/A1/A2, EB-10/7, EB-8/2). | COMPLIANT |
| 4 | **pack-side-project-concepts-deliverable-only** | The shipped standard (§4/§6/§7) uses ONLY project vocabulary — phases, phase-tasks (`phase-N.M`), TD backlog, project agents (architect/planner/coder/reviewer/docs-researcher/tester/auditor/etc.), the project's own triggers + execution half. ZERO pack work-item concepts (no "BD", no "backlog-item", no "pack-*" agent names, no `pack-ops/`, no PACK-CHAT/PACK-AGENTS, no `## Pack memory`, no `[rationale:]`/bijection/manifest surfaces). EB-14 confirms the proposed shipped bullet carries zero pack-concept AND zero memory-feature tokens. The only BD-238/BD-245 mentions are PLANNING CONTEXT in this design doc, not shipped text. | COMPLIANT |
| 5 | **ci-guard-design-measure-then-bound** | §8 keeps the parity-DROP on its measure-then-bound evidence: MEASURED the existing project-side gates (EB-12: no body-parity check; validate-docs 4 axes + Check 18/27); CATEGORIZED the new bullet's only new risk (×3 body drift, recoverable, 688-char pointer); BOUNDED — a correct body-parity check is a separate larger effort; VERDICT no new guard (DROP not defer). ALSO corrected three gate mis-attributions (M1/m4) so the PREFLIGHT targets the RIGHT gate (DANGLING axis + L390 record), not a no-op gate. The size criterion (§4.2) is calibrated against documented behavior (EB-6), not asserted; the 700-cap fit is measured (EB-9). | COMPLIANT |
| 6 | **operating-docs-no-history-no-bloat** | The trinity rule stays the pointer-shaped ≤700-code-point bullet (688, EB-9), terse, no history; the full chain lives in METHODOLOGY (uncapped). §6.1 mandates zero history/dates/SHAs/provenance (HISTORY axis) + zero deferred/version phrasing (DEFERRED axis); §3.B OMITs groupings WITHOUT deferral language. LIVE forward-pointers (the METHODOLOGY cite) KEEP. PREFLIGHT-3 attests the axes. | COMPLIANT |
| 7 | **deferral-is-scope-creep / no-deferral-without-user-direction** | Nothing deferred to v11.1+. The parity guard is DROPPED entirely (§8.3), NOT deferred (no follow-up, no scheduling). The groupings question is RESOLVED (OMIT, §3.B), not punted. Wrinkle C = (b) is a SEQUENCING choice (BD-239 first, current queue NOT reordered) the USER made — not a deferral; the §3.C hand-off note is the cross-BD COORDINATION (BD-245 re-sweeps BD-239's additions), not a punt — all BD-239 work lands at BD-239's landing. | COMPLIANT |
| 8 | **rules-applied-verification-block** | This table — rules 1-8, each name + quoted evidence + terminal conclusion (no AMBIGUOUS; no empty evidence). | COMPLIANT |

---

*End of DESIGN-BD-239-RECONCILED. Fresh independent reconciler (not author, not adversary); one Write (this doc) under /tmp; read-only git only; no memory store used. The 3 MAJOR findings are resolved: M1 (the cite gate retargeted from Check 64/70 to the validate-docs DANGLING axis + the existing L390 allowlist record; the trinity bare-word "METHODOLOGY" is DANGLING-exempt), M2 (the BD-239↔BD-245 three-surface overlap — trinity rules-section + `supporting-docs/METHODOLOGY.md` + `PM-CHAT.md` — enumerated in a hard hand-off note; BD-239 lands FIRST under `## Project memory` per the user decision, current queue NOT reordered), M3 (the false DEFERRED-axis rationale for OMITting groupings struck; OMIT re-grounded on grep-zero + BD-189-ownership). The HARD CONSTRAINT is verified: BD-239 adds ZERO CLI/project-memory endorsement and leaves the existing memory passages (PM-CHAT L889-891/L981-984) untouched for BD-245 to strip (EB-14). Carried unchanged per the directive: project-vocabulary purity, the 688 ≤ 700 pointer (12-char margin flagged), no rationale-bijection, the 9-stage pipeline + 5 roster divergences, the size-tiering incl. P5, the parity-DROP. MINOR/NIT folded in (m1 code-point measure, m2 stage-count headline dropped, m3 manifest-NOOP closed, m4 Check-70 removed, n1 P3 tie-break, n2 PM-chat classifier). Ready for user design review → planner.*
