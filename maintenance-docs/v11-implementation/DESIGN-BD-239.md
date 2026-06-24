# DESIGN-BD-239 — PROJECT-SIDE large-PHASE development pipeline standard (size-tiered)

**Role:** pack-architect (RO). FRESH instance; first architect pass for BD-239. **BD:** BD-239 (LARGE — user-confirmed 2026-06-23; runs the full pipeline; THIS design feeds an ADVERSARIAL architect review next). **Starting point (informs, does NOT cap):** the reconciled BD-238 pack-side design + plan. **Output:** this design only (sole Write, under `/tmp`). **Next stage:** adversarial architect review → reconciliation (if NEEDS-REWORK) → user design review → planner.

This doc carries the FULL design so the adversary + planner read ONE coherent doc. Every state-claim is backed by an Empirical-Evidence Block (§13).

---

## 0. Runtime regime (RO; verified)

| Field | Value |
|---|---|
| `pwd` | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev` |
| `git rev-parse HEAD` | `e8ba9e7a4d1d3ea33ac3d4320d0aee77bf973381` (= expected `e8ba9e7`) |
| branch | `v11-dev` |
| `git status --short` | clean (the concurrent BD-238 C1 coder runs in its OWN isolated worktree; my canonical HEAD shows no uncommitted project-side change) |
| graph | DISCOVERY queried (`graphify query … --graph …/graphify-out/graph.json --backend claude-cli --budget 1500`); operating-doc rule bodies + workflow prose are NOT node-indexed at rule granularity (the query returned only maintenance-doc review nodes) → grep/Read for VERIFICATION (G2 fallback, sanctioned for exact-bytes/section reads). |
| writes | EXACTLY ONE: this design doc. No source edits. Read-only git only. No memory store read/written (user MEMORY PROHIBITION 2026-06-23 honored). |

---

## 1. Executive summary (the design in one screen)

**The gap (measured, EB-1/EB-2/EB-3):** the project-side process docs document the BASE phase workflow (a coder→reviewer cycle with SITUATIONAL architect/planner triggers) and ALREADY carry a complete EXECUTION-half worktree orchestration in `PM-CHAT.md` — but NO consolidated, NAMED, SIZE-TIERED DESIGN-half pipeline (optional researcher(s) → architect → adversarial architect → reconciliation → user design review → planner → adversarial planner → reconciliation → user planner-to-coder gate → parallel worktree coder waves), and NO large-vs-small-PHASE criterion. The word "adversarial" appears ZERO times in `METHODOLOGY.md` (EB-3).

**The asymmetry vs BD-238 (the key design insight):** the project side is FURTHER ALONG than the pack side on the EXECUTION half — `PM-CHAT.md` already has worktree isolation, merge-back, parallel worktree waves off the dependency map, the conflict protocol, report preservation, the live-worktree ASK gate, and the fresh-instance reconciliation rule (EB-4). So BD-239 is NOT "re-author the whole pipeline"; it is "add the missing DESIGN-half spine + the size-tiering + the consolidating anchor, and WIRE it to the already-rich project triggers." This is a deliberate divergence from BD-238's shape: where BD-238 had to add an execution-half reference, the project already has the execution half.

**The standard, in PROJECT vocabulary:** ONE official pipeline keyed on PHASES (not BDs). LARGE PHASE = the full pipeline by default (the two adversarial reviews + reconciliation as the MINIMUM). SMALL PHASE = the base flow with adversarial+reconciliation OPTIONAL at user election. The size criterion is two-part (signals → consequence), adapted from BD-238 but RE-EXPRESSED for phases AND CALIBRATED to the project's existing trigger vocabulary.

**Where it lives (placement, §4):** the SSOT body in `supporting-docs/METHODOLOGY.md` (the SOURCE; installs to `docs/pack/METHODOLOGY.md` — EB-1) as a new sub-section in Part 5; a consolidating ANCHOR + cross-references in `project-template/docs/pack/PM-CHAT.md`; a terse governing rule in the project trinity `## Project rules` section (the BD-245 target name — §3 wrinkle C). Agent defs + skills get bounded cross-references only.

**Roster leverage (the "more flexible" mandate, §5):** the project has 16 agents ×3 CLI families + 37 skills (EB-5). The pipeline USES them: specialized adversarial-architecture-review (`architecture-review` skill), the 7-cluster auditor model as an OPTIONAL large-phase post-implementation audit stage, the tester-trigger and planner-trigger rules wired INTO the size tiers, and parallel worktree coder waves across disjoint phase tasks. This is the justified divergence from BD-238's 5-agent shape.

**Parity / CI call (§8, measure-then-bound):** NO new project-side CI guard. The shipped `validate-docs.sh` already gates the trinity (history/deferred/bloat/dangling axes); the bloat cap (700 chars) FORCES the trinity rule to be SPLIT into terse bullets (the pack's 1300-char single-bullet shape does NOT fit — EB-9). A new body-parity check is rejected on the same measure-then-bound logic BD-238 used, PLUS the project side already lacks one and the trinity rule is discipline-enforced by validate-docs structural parity (Check 18/57). Drop, not defer.

**Three wrinkles (§3):** (A) METHODOLOGY source = `supporting-docs/METHODOLOGY.md`; design against the SOURCE. (B) groupings = grep-ZERO project-side (EB-2); the standard uses phases/phase-tasks/TD ONLY, with at most a NON-DEPENDENT forward-reference. (C) `## Project memory` → `## Project rules` rename (BD-245) lands AFTER BD-239 — surfaced as a finding with a recommended ordering (§3.C), NOT silently picked.

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

**Bound (KEEP/STRIP):** every existing occurrence is KEEP. The design ADDS the spine + size-tiering + the consolidating anchor; it REMOVES nothing and DUPLICATES nothing (the new METHODOLOGY section REFERENCES the existing PM-CHAT execution half + the existing triggers rather than restating them).

---

## 3. The three wrinkles — resolved / surfaced

### 3.A METHODOLOGY source-path (RESOLVED — design against the SOURCE)

The BD names `project-template/docs/pack/METHODOLOGY.md`, which does NOT exist as a source (EB-1). The editable SOURCE is `supporting-docs/METHODOLOGY.md` (95 KB), install-copied to the client's `docs/pack/METHODOLOGY.md` by `scripts/init-project.sh` (EB-1). **All METHODOLOGY edits in this design target `supporting-docs/METHODOLOGY.md`.** The true project-side edit-set is `project-template/` ∪ project-side `supporting-docs/` (the `_PROJECT_SIDE_PATH_PREFIXES` allowlist = `("project-template/", "supporting-docs/")`, EB-1). No further ambiguity.

### 3.B "groupings" not yet project-side (RESOLVED — phases/phase-tasks/TD only; non-dependent forward-ref at most)

`grep -rln "groupings"` returns ZERO under `project-template/` (the WHOLE subtree, broader than just `docs/project/` — EB-2). Groupings is BD-189, sequenced AFTER BD-206 (EB-2), and BD-239 is #2 ahead of BD-206 (EB-2) — so groupings does NOT exist when BD-239 implements. **Decision:** the shipped standard uses ONLY phases / phase-tasks / TD vocabulary. It MUST NOT depend on, define, or assume groupings. A single OPTIONAL non-dependent forward-pointer is permissible IF and only IF it does not break the operating-docs-no-deferred-feature gate (validate-docs DEFERRED axis blocks "future version"/"not yet"/"roadmap"/"slated" — EB-8). **Recommendation: OMIT any groupings mention entirely** — a forward-reference risks tripping the DEFERRED axis and adds a dangling concept; the standard is complete with phases as the size unit. If the user wants groupings named later, BD-189 adds it. (This is the conservative, gate-safe choice; the adversary may challenge.)

### 3.C `## Project memory` → `## Project rules` rename + the BD-239↔BD-245 ordering interaction (SURFACED as a finding — NOT silently picked)

**The facts (EB-7, EB-10):**
- The project trinity rules-codification section is currently `## Project memory` (CLAUDE.md:360, AGENTS.md:339, GEMINI.md:357).
- BD-245 (Open; sequenced directly after BD-232) renames `## Project memory` → `## Project rules` AND updates every reference IN LOCK-STEP, including the SHIPPED client gate `project-template/scripts/validate-docs.sh`, whose **bloat axis hard-binds to the literal string `## Project memory`** (`project_memory_bullets()` matches `l.strip() == "## Project memory"`, EB-9). BD-245 also reserves "project memory" exclusively for the (forbidden) per-CLI memory feature.
- BD-239 is #2 (ahead of BD-206); BD-245 runs after BD-232. **The queue order of BD-239 vs BD-245 is not pinned in the entries** — BD-239 is "after BD-238, before BD-242"; BD-245 is "after BD-232". Both are v11.0 lead-block work. **The interaction is real regardless of which runs first**, because BD-239 must place a rule in the trinity rules-section whose NAME BD-245 is about to change.

**The interaction (the load-bearing risk):**
- If BD-239 places its trinity rule under the CURRENT name `## Project memory` and BD-245 runs LATER, BD-245's rename + reference-update sweep MUST carry BD-239's new rule across to `## Project rules` (BD-245's lock-step rename already covers "every reference" + the validate-docs gate, so the new rule rides along — but ONLY if BD-245's measure-then-bound census re-measures the section AFTER BD-239 lands).
- If BD-239 places its rule under `## Project rules` BEFORE BD-245 renames the heading, the heading and the gate still say `## Project memory` — the rule would be ORPHANED under a non-existent heading, and `validate-docs.sh`'s bloat axis (which finds the section by the literal `## Project memory`) would NOT cap the new bullet (false-negative on the gate), AND the trinity structural-parity gate (validate-docs IN-set + any H2-parity check) could flag a heading mismatch.

**Recommendation (surfaced for the user — not silently chosen):**

> **RECOMMENDED: run BD-245 BEFORE BD-239** (re-sequence so the rename lands first), so BD-239 places its rule directly under the final `## Project rules` name against an already-updated `validate-docs.sh` gate. Rationale: BD-239's deliverable is a NEW rule + a NEW METHODOLOGY section; placing it once, under the final name, against the final gate, is a clean single-pass landing. The alternative (BD-239 first, under `## Project memory`, then BD-245 catches it) forces BD-245's rename census to include a rule that did not exist when BD-245 was scoped — a moving target that risks an incomplete lock-step sweep.
>
> **FALLBACK (if the user keeps BD-239 before BD-245):** BD-239 places its trinity rule under the CURRENT `## Project memory` name (so the heading, the validate-docs bloat gate, and the structural-parity gate all stay consistent at BD-239's landing), and this design EXPLICITLY flags — as a hard hand-off note to BD-245 — that BD-245's rename census MUST include the BD-239 rule when it sweeps `## Project memory` → `## Project rules` references. The fallback keeps every gate green at each BD's landing but adds a cross-BD dependency.

**This is a SEQUENCING DECISION for the user.** This design is written to the RECOMMENDED order (rule placed under `## Project rules`) but the rule TEXT and placement are name-agnostic — a one-token heading change is the only delta between the two orders. The planner encodes whichever order the user picks; either is a clean landing if the gate-name and the heading-name agree at BD-239's commit.


---

## 4. The pipeline + size-tiering — in PROJECT vocabulary

### 4.1 The pipeline (the full chain, PHASE-keyed)

ONE official pipeline for project PHASE development. Stages, in order:

1. **Optional researcher set — FIRST, before the first architect.** Zero, one, or both of: an **INTERNAL** researcher (`docs-researcher` — the project codebase/docs inventory + blast-radius census across the phase's surfaces) and an **EXTERNAL** researcher (`docs-researcher` — CLI/tool/framework/API docs verified against authoritative sources, the existing Workflow 3 case generalized). Invoked per-need at ANY phase size. `docs-researcher` is the only role reuse-OK for reconciliation (factual inventory).
2. **Architect** (`architect`) → the phase design, INCLUDING the REQUIRED parallel/dependency map (which phase tasks run in parallel isolated worktrees vs serial) AND the rejected-alternative documentation (the existing Part 3 architect rule). The architect defines the large-vs-small-PHASE classification for THIS phase (§4.2).
3. **Adversarial architect review** (fresh, clean-context `architect` instance; loads the `architecture-review` skill) → PM-chat triage of findings → **[reconciliation architect — a FRESH instance, only if the review returns NEEDS-REWORK]**; loop until READY. Governed by the existing `Reconciliation-instance independence` trinity rule (fresh instance, never the original author nor the adversary).
4. **User design review** (the design gate — the existing "present proposed changes and wait for the user to read" discipline).
5. **Planner** (`planner`) → the implementation-ready plan (the IMPLEMENTATION-PLAN.md Phase-N task block, or a multi-part phase split), INCLUDING its OWN parallel/dependency map.
6. **Adversarial planner review** (fresh `planner` instance) → triage → **[reconciliation planner — FRESH, only if NEEDS-REWORK]**.
7. **User planner-to-coder gate** (the existing approval gate before any coder prompt).
8. **Parallel worktree coder waves** — scheduled off the parallel/dependency map: disjoint-file phase tasks run as concurrent `coder` agents, each in its own isolated worktree; same-file ⇒ serialize. Each commit's bounded review/fix cycle (the existing Workflow 4 fix cycle, including the Trigger A/B architect + Trigger P-A/P-C planner mid-cycle escalations + the cycle-termination invariant) runs IN its worktree; the patch is produced only after review-clean; patches apply to the canonical tree SEQUENTIALLY (atomic per patch) with the conflict protocol (STOP + re-spawn fresh, never hand-merge). Superseded design/plan docs are DELETED as the pipeline iterates; the audit set is preserved into `docs/impl-reports/<current-phase>/` (the existing report-preservation discipline).
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
| P3 | **Blast-radius** | The phase changes a contract/schema/interface that ≥3 surfaces depend on, OR a docs-researcher blast-radius census is REQUIRED before design. |
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

### 4.3 Validation against the project's own precedent shape (EB-6)

The project's existing workflow already encodes the SMALL-phase base flow (Workflow 2: coder → reviewer, planner only on trigger) and the LARGE-phase escalations (Workflow 4 Trigger A/B architect; Part 6 audit after 3+ phases). The size-tiering does not contradict these — it adds the UP-FRONT adversarial-as-minimum tier for large phases on top of the existing mid-cycle situational triggers. A phase with >5 tasks + a schema migration (P5 + P4 = 2 signals) ⇒ LARGE ⇒ mandatory adversarial; a localized bug-fix phase inside one module (0-1 signals) ⇒ SMALL ⇒ base flow, adversarial optional. Both map cleanly to how the existing workflows already escalate. The criterion is measure-then-bound-consistent with the project's documented behavior.

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

**The roster-leverage is the SUBSTANCE of "more flexible."** BD-239 is not BD-238 with "phase" find-replaced for "BD". It is a pipeline shaped to a richer, already-partly-built process: it CONSOLIDATES the project's existing triggers + execution half + audit model into a named size-tiered standard, adding only the adversarial-review spine + the tiering. The blast radius is SMALLER than BD-238's relative to the surface, because more already exists — but the deliverable is RICHER (a 9-stage pipeline with an optional audit capstone and skill-named adversarial passes vs BD-238's 8-stage chain).

---

## 6. Exact placement (project-side surfaces)

Honoring pack/project disjointness (EB-1): every target is `project-template/` or project-side `supporting-docs/`. ZERO pack-ops surfaces.

### 6.1 The SSOT body — `supporting-docs/METHODOLOGY.md` (MANDATORY; the primary surface)

**Placement:** a NEW sub-section in **Part 5 — Standard Workflows**, after Workflow 4 (the fix cycle) and before Workflow 5 (the audit), titled e.g. **`### Workflow 4.5 — Large-phase development pipeline (size-tiered)`** OR a new **`### The large-phase pipeline standard`** subsection. (Exact title is the planner's mechanical call; the SHAPE is fixed here.) This position places it adjacent to the existing fix-cycle + audit workflows it consolidates.

**Content (the planner authors prose from these REQUIRED elements):**
- The full 9-stage chain (§4.1), in project vocabulary (phases / phase-tasks / TD / project agents). NO pack work-item concepts (no BD, no backlog-item, no pack-* agent names).
- The two-part size criterion (§4.2): the 5 signals + the demoted consequence (P1-alone OR ≥2 ⇒ LARGE-mandatory-adversarial; else base flow, adversarial optional; when-in-doubt-LARGE).
- Cross-references (NOT restatements) to: the execution half in `docs/pack/PM-CHAT.md` § "merge-back / worktree" (stage 8); the existing Trigger A/B + P-A/P-C + tester triggers (the complementary mid-cycle escalations, D4); the `architecture-review` + `planning` skills (D1); Workflow 5 / Part 6 audit (stage 9, D2); the `Reconciliation-instance independence` trinity rule (stages 3, 6).
- The escalation detail ("additional rounds on larger gaps").
- ZERO history/dates/SHAs/provenance (the validate-docs HISTORY axis — EB-8); ZERO deferred-feature/version mentions (the DEFERRED axis — EB-8). This is an operating doc; it states only what currently operates.

**Why METHODOLOGY is the primary surface:** the BD names it; it is where the base workflows + agent roster + triggers already live; consolidating the pipeline there keeps the standard adjacent to the pieces it names.

### 6.2 The consolidating anchor + cross-references — `project-template/docs/pack/PM-CHAT.md` (MANDATORY)

`PM-CHAT.md` already carries the execution half AND references METHODOLOGY ~30 times (EB-4 context). Two edits:
1. A short consolidating ANCHOR at the top of the worktree/merge-back section (§ "Merge-back …" region, EB-4) framing it as "the EXECUTION half of the large-phase pipeline standard," with a one-line pointer to the METHODOLOGY section. (A reference, not a restatement — no verbatim METHODOLOGY body.)
2. A one-line pointer in the agent-roster / behavioral-rules region naming the standard and its METHODOLOGY home, so the orchestrator routing the stages finds the standard.

These mirror BD-238's §4.2/§4.3 anchors — but here the execution half ALREADY exists, so the anchor CONSOLIDATES rather than introduces.

### 6.3 The governing rule — project trinity `## Project rules` ×3 (MANDATORY; subject to §3.C ordering)

A TERSE rule in the project trinity rules-section (target name `## Project rules` per BD-245; fallback `## Project memory` per §3.C). Because the trinity uses FLAT bullets (EB-7) AND the shipped bloat cap is 700 chars (EB-9), the rule MUST be split or kept tight (§7). Proposed rule (a pointer to the SSOT + the load-bearing tiering test, NOT the full chain):

> The standard's full chain lives in METHODOLOGY; the trinity rule states only the size-tiering decision + that the standard is the default for large phases, pointing at METHODOLOGY for the chain. (Exact text + the ≤700-char fit in §7.)

The rule is byte-identical ×3 (trinity rule). It carries `[rationale: ...]`-style tagging ONLY if the project trinity uses that convention — it does NOT (the project `## Project memory` bullets carry no `[rationale:]` tags, EB-7). So the project rule is a plain bullet, NO rationale-bijection surface (unlike the pack's Check-45 bijection). This is a structural difference from BD-238 (§7).

### 6.4 Agent definitions + skills — BOUNDED cross-references only (ELECTIVE; recommended minimal)

Project agent defs do NOT currently reference adversarial/pipeline stages (EB-11; only `auditor.md` mentions "adversarial" in audit context). Adding a stage reference to an agent def costs 3× (Claude .md / Codex .toml / Antigravity plugin .md) per agent, gated by parity Check 5 + Check 27 (EB-12). **Decision (measure-then-bound, tight bound):**
- **DO NOT** add the rule body to any agent def or skill (they would become restatement surfaces).
- **OPTIONAL, recommended minimal:** a one-line pointer in the `architecture-review` skill and the `planning` skill (the two skills the adversarial passes load, D1) noting they are loaded by the standard's adversarial stages. This is 2 skills × 1 file each (skills are single-file SKILL.md, NOT ×3 — EB-5) = 2 edits, low cost, high discoverability. The planner may drop these to minimize footprint; validate-docs stays green either way.
- **DO NOT** touch the 8 auditor agent defs, the tester/grpc-schema/repo-ops defs, or the other 31 skills — they are out of the pipeline's direct reference set.

### 6.5 Surfaces explicitly NOT touched (enumerate-encoding-surfaces)

- **`project-template/docs/project/*/_rules.md`** (phase/TD vocabulary contracts) — the standard REFERENCES this vocabulary; it does not change the contracts. NOT touched.
- **The 16 agent defs ×3 families** (beyond the 0 mandatory) — NOT touched (§6.4).
- **35 of 37 skills** — NOT touched.
- **`validate-docs.sh`** — NOT touched by BD-239 (no new axis; the rename of its `## Project memory` literal is BD-245's job, §3.C). BD-239 must NOT edit the gate.
- **`project-template/docs/project/` groupings** — does not exist (EB-2); NOT created.

---

## 7. The trinity rule text + the 700-char bloat constraint (a real project-side difference)

### 7.1 The constraint (measured, EB-9)

The shipped client gate `validate-docs.sh` enforces `BLOAT_BULLET_CHAR_CAP = 700` over EVERY top-level bullet in the trinity rules-section (found by the literal `## Project memory`). The densest existing bullets (`**No destructive operations…**` and `**Project SSOT-first.**`, both 1096 chars collapsed) PASS only because they are explicitly allowlisted by snippet in `.docs-gate-allowlist.txt` (6 records, 2 bullets ×3 files — EB-9). A NEW over-700-char bullet FAILS the bloat axis unless split or allowlisted.

**This is the SHARPEST divergence from BD-238.** The pack's cap is 1300; the BD-238 rule fit at 1289 in ONE bullet. The project's cap is 700 — the full 9-stage pipeline + 5-signal criterion CANNOT fit one ≤700-char bullet. The project trinity rule MUST be a POINTER, not the full chain (the chain lives in METHODOLOGY, which has no per-bullet cap).

### 7.2 The proposed trinity rule (split into ≤700-char bullets; pointer-shaped)

Option A (RECOMMENDED — a single tight pointer bullet, ≤700 chars, no allowlist needed):

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

This must be MEASURED by the coder against the 700-char collapsed cap (the planner encodes a PREFLIGHT measurement step; if it exceeds 700 after final wording, either tighten OR add a `.docs-gate-allowlist.txt` bloat record with a reviewer-verified reason — tighten preferred). The wording above is the DESIGN intent; the planner/coder may trim to fit 700 without changing meaning. **The coder MUST measure the collapsed length and confirm ≤700 (or add an allowlist record) — this is a NAMED PREFLIGHT step (§10).**

Option B (fallback if Option A cannot hit 700 without losing the load-bearing tiering test): split into TWO bullets — (1) the pipeline pointer; (2) the size-tiering test — each ≤700. The planner picks A or B based on the coder's measurement; A is preferred (one bullet is terser).

### 7.3 No rationale-bijection surface (a structural simplification vs BD-238)

The pack side required a `PACK-MEMORY-RATIONALE.md` section + a `.spawn-rule-manifest.txt` record because the pack `## Pack memory` rules carry `[rationale:]` tags gated by Check 45 bijection. The project `## Project memory` bullets carry NO `[rationale:]` tags (EB-7) and there is NO project-side rationale-bijection file. **So BD-239's trinity rule needs NO rationale section + NO manifest record.** The propagation set is simpler than BD-238's: trinity ×3 (byte-identical) + METHODOLOGY + PM-CHAT anchor. This is a measured simplification, not an omission.

### 7.4 The trinity rule is byte-identical ×3 (the trinity rule + parity gates)

The new bullet is inserted byte-identical into `project-template/CLAUDE.md`, `AGENTS.md`, `GEMINI.md` under the rules-section. It adds NO new H2 (it is a bullet inside the existing rules-section H2), so the trinity H2-parity gate (Check 18 at project-template + the project-side analog) is unaffected (EB-12). The CLI-agnostic phrasing ("parallel worktree coder waves") keeps it byte-parity-safe ×3 — no Claude-only worktree mechanics restated (the project trinity has only 1 "worktree" mention, EB-3; the mechanics live in PM-CHAT, which is single-source not trinity). Byte-parity is enforced by the trinity rule (discipline) + the project-side structural-parity checks; §8 makes the parity call.

---

## 8. Parity / CI-guard call (measure-then-bound) — NO new project-side guard

### 8.1 The question

The project trinity SHIPS to clients (higher cost-of-being-wrong than BD-238's pack-internal surface). Does BD-239 warrant a NEW project-side CI guard (e.g. a trinity body-parity check) for the new rule?

### 8.2 Measure first — what already gates the project trinity (EB-12, EB-9)

| Existing gate | What it enforces on the project trinity | Relevant to the new rule? |
|---|---|---|
| `validate-docs.sh` HISTORY axis | no dates/SHAs/past-action/provenance in the trinity | YES — the new bullet must be history-free (it is, by design) |
| `validate-docs.sh` DEFERRED axis | no deferred/future-version/roadmap mentions | YES — the new bullet must avoid deferral phrasing (it does; §3.B omits groupings) |
| `validate-docs.sh` BLOAT axis | ≤700 chars per `## Project memory` bullet | YES — the new bullet measured ≤700 (§7.2) or allowlisted |
| `validate-docs.sh` DANGLING axis | trinity file-refs resolve | YES — the METHODOLOGY pointer resolves (`docs/pack/METHODOLOGY.md` is installed) |
| validate-pack Check 18 (project-template) + the H2-parity analog | trinity H2 set/order parity ×3 | YES (auto-satisfied — no new H2) |
| validate-pack Check 5 / Check 27 | agent-family count + canonical-phrase parity | only if agent defs are touched (they are not, §6.4) |
| validate-pack Check 64 / Check 70 | shipped-doc cite-resolution + doc-gate structural parity | YES — the METHODOLOGY pointer must resolve under `project-template/<basename>` or be a valid install target |

### 8.3 Categorize + bound — is a NEW body-parity check warranted? NO.

Applying `ci-guard-design-measure-then-bound`:
1. **Measure:** there is NO existing project-side CI check that byte-compares the trinity rules-section BODIES across CLAUDE/AGENTS/GEMINI (same as the pack side; the parity gates check H2 structure + counts + phrasing, not rule-body bytes — EB-12). The gap is real but discipline-bounded by the trinity rule (which the project trinity carries explicitly — EB-7).
2. **Categorize the new rule's risk:** a ×3 body drift of the new bullet is the only new risk. It is RECOVERABLE (a drift is caught at the next trinity edit / review) and the bullet is SHORT (a pointer, ≤700 chars — far easier to keep identical than the pack's 1289-char rule).
3. **A correct body-parity check is a LARGER, SEPARATE effort** (the same finding BD-238 reached): it must normalize around the GEMINI-intrinsic H2s (`## Agent roster`, `## Antigravity CLI operating notes`) and any tool-specific bullets, re-baseline EVERY existing trinity rule for ×3 identity, and reconcile with the existing parity gates. That is a distinct CI-guard contract (body-parity) from BD-239's (pipeline codification) — SIZE + LOGICAL-FIT bar met for it being a separate concern.
4. **Cost-of-being-wrong is bounded by the existing gates:** the new bullet is already caught by HISTORY/DEFERRED/BLOAT/DANGLING + H2-parity. The residual (body drift) is the SAME residual every project trinity rule already carries; BD-239 adds no new KIND of exposure.

**VERDICT: NO new project-side CI guard for BD-239. DROP (not defer).** Per the user's standing fold-in-or-drop ruling: the guard is unnecessary work whose correct form is a net complexity loss; it does not exist and is not scheduled. The trinity-rule discipline + the byte-parity PREFLIGHT step (§10) are the sole-and-sufficient protection — sole because the guard is correctly ABSENT, not deferred.

### 8.4 The PREFLIGHT byte-parity safeguard (the SOLE protection — NAMED)

Because there is no CI net for body parity (and shouldn't be, §8.3), the coder PREFLIGHT MUST include a ×3-byte-identity attestation for the new bullet (extract from all three files, normalized diff, 0 differences) — encoded as a HARD named plan step (§10). This is the same safeguard BD-238 used, sized to the project's shorter rule.

---

## 9. Propagation / encoding surfaces + gating client checks

The full propagation set, MANDATORY vs ELECTIVE, with the gating check for each.

| Order | Surface | Edit | Mandatory? | Gating client/CI check |
|---|---|---|---|---|
| 1 | `supporting-docs/METHODOLOGY.md` | NEW Part-5 subsection: the 9-stage chain + the size criterion (§6.1) | **MANDATORY** (the primary SSOT) | `validate-docs.sh` HISTORY/DEFERRED/DANGLING (METHODOLOGY is in-set as `docs/pack/*.md` after install — but the SOURCE is `supporting-docs/`; validate-docs runs against the INSTALLED tree, so the source edit is gated at install/self-test); validate-pack Check 39 (docs/pack/*.md install-mapping), Check 64/70 (cite-resolution + doc-gate parity) |
| 2 | `project-template/CLAUDE.md` rules-section | insert §7.2 trinity bullet, byte-identical | **MANDATORY** | `validate-docs.sh` BLOAT (≤700) + HISTORY + DEFERRED + DANGLING; Check 18 H2-parity (auto-satisfied); trinity-rule byte-parity (PREFLIGHT §10) |
| 3 | `project-template/AGENTS.md` rules-section | SAME byte-identical bullet | **MANDATORY** | same as row 2 |
| 4 | `project-template/GEMINI.md` rules-section | SAME byte-identical bullet | **MANDATORY** | same as row 2 |
| 5 | `project-template/docs/pack/PM-CHAT.md` | consolidating anchor + roster/behavioral one-line pointer (§6.2) | **MANDATORY** | `validate-docs.sh` (PM-CHAT is in-set as `docs/pack/*.md`) HISTORY/DEFERRED/DANGLING; Check 39 install-mapping; anti-restate-safe (pointer, not body) |
| 6 | `project-template/skills/architecture-review/SKILL.md` + `skills/planning/SKILL.md` | one-line "loaded by the standard's adversarial stage" pointer (§6.4) | **ELECTIVE** (recommended) | `validate-docs.sh` (skills in-set); Check 1 SKILL.md frontmatter; Check 27/31 skill-cell conformance |
| 7 | audit-set preservation | move the BD-239 pipeline docs `/tmp` → `maintenance-docs/v11-implementation/` | **MANDATORY** (report-preservation discipline) | none (pack-side maintenance record) |
| 8 | `test-fixtures/manifest.txt` | NOT a propagation step UNLESS an agent-def/skill FIXTURE input changes | N/A (row 6 skills MAY be fixtures — see note) | push-time `manifest-sync.sh` + `build.sh --verify` + Check 62 |

**Minimal green footprint:** rows 1-5 + 7. Row 6 (skill pointers) is the elective discoverability add. **Manifest note (row 8):** if the row-6 skills are fixture inputs (the skills mirror into test fixtures), editing them changes a fixture input → push-time `manifest-sync.sh` regenerates `test-fixtures/manifest.txt` (the orchestrator runs it before push; NOT a per-commit chore — EB-13). If row 6 is dropped, the manifest is a NOOP. The planner verifies whether `skills/*/SKILL.md` is a fixture input before deciding row 6 (the coder runs `manifest-sync.sh` at push and commits any regenerated manifest with approval). Rows 2-4 (trinity) + row 5 (PM-CHAT) + row 1 (METHODOLOGY source) are NOT fixture inputs in the manifest sense (they are deliverable docs, not the agent-def/skill fixture corpus) — confirm at plan time.

### 9.1 The cite-resolution gate (Check 64/70 — the cross-reference must resolve)

The METHODOLOGY pointer in the trinity rule + the PM-CHAT anchor cite `docs/pack/METHODOLOGY.md` (the INSTALLED path). Check 64 requires a cite to resolve to `project-template/<basename>` or be a valid install target; Check 70 enforces shipped-doc-gate structural parity (EB-12). The METHODOLOGY source is `supporting-docs/METHODOLOGY.md` which installs to `docs/pack/METHODOLOGY.md` (EB-1) — so a trinity reference to `docs/pack/METHODOLOGY.md` is a valid will-exist-at-install target; the coder confirms the cite shape passes Check 64 + the validate-docs DANGLING axis (the DANGLING axis has `target:` allowlist records + the "installed by" anchor carve-out — EB-9). The planner encodes a cite-resolution PREFLIGHT check.

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
- **They are ONE logical unit with a cross-reference dependency:** the trinity rule + PM-CHAT anchor POINT AT the METHODOLOGY section; the METHODOLOGY section is the SSOT the pointers resolve to. A half-applied state (pointers without the target, or the target without the pointers) carries a dangling cross-reference that the validate-docs DANGLING axis + Check 64 would flag. Keeping them in ONE commit means the committed state never carries a half-applied cross-reference (clean per-commit audit), even though CI is push-time end-state (EB-13).
- **The trinity ×3 must be one byte-identical parallel edit** (the trinity rule) — that sub-unit cannot be split across commits.
- **No disjoint-file concurrency PAYOFF:** the total edit is small (one METHODOLOGY subsection + one trinity bullet ×3 + 2 short anchors + 2 elective skill lines). The orchestration cost of parallel worktree waves exceeds the benefit for an effort this size. Parallel waves pay off for MULTI-task implementation phases, not a docs-codification BD.

**So: ONE serial coder commit for C1+C2(+C3), then C4 (paired audit-set commit).** The binding reason is cross-reference-atomicity (pointers + target in one commit) + the trinity-rule byte-identical-×3 requirement + no parallel payoff at this size — NOT a CI cadence gate (CI is push-time, EB-13).

**If the user/planner prefers separate commits** (e.g. to land METHODOLOGY first for review): C1 (METHODOLOGY) → C2 (trinity + PM-CHAT pointers) within ONE push is CI-safe (push-time end-state), but the INTERMEDIATE commit C1-only or C2-only would carry a transient dangling cite — acceptable only if both land in the same push. The RECOMMENDED single-commit avoids the transient entirely.

**Worktree lifecycle (Claude-only):** the C1+C2+C3 coder is the FIRST (and only) RW coder → CREATES the isolated worktree (`isolation:"worktree"`, base `worktree.baseRef:"head"`); fix-coders REUSE it; teardown ONLY after the commit lands (exit 0). C4's doc-move coder is a fresh coder (per-commit fresh-coder); Pack Chat applies the live-worktree ASK gate if the C1 worktree is still live.

### 10.3 Concurrency with the BD-238 C1 coder (the concurrent worktree note)

The prompt notes a BD-238 C1 coder is concurrently editing PACK-side trinity in its own isolated worktree. The BD-239 edit-set is PROJECT-side (DISJOINT from BD-238's pack-side set — EB-1, the research census disjointness verdict). There is NO file collision: BD-238 touches `/CLAUDE.md` (pack-root, inode distinct from `/project-template/CLAUDE.md` per the census), `pack-ops/*`, `.claude/*`; BD-239 touches `project-template/*` + `supporting-docs/*`. The two efforts can land in any order or concurrently with zero conflict. (This is a SCHEDULING observation, not a BD-239 design dependency.)

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
| **Rejected-alternative documentation rule (architect)** (METHODOLOGY Part 3, EB-6) | The standard's architect stage (2) inherits it (the architect documents rejected alternatives in ARCHITECTURE.md). | NONE — inherited, not overridden. |
| **Session rules: every agent a new session; no memory between sessions** (METHODOLOGY Part 3, EB-6) | The standard's fresh-instance reconciliation + per-commit fresh-coder align with this. | NONE — reinforced. |

**Worktree/parallel-wave CLI-portability:** the project trinity carries only 1 "worktree" mention (EB-3); the mechanics live single-source in PM-CHAT.md (not the trinity), and PM-CHAT frames CLI-specific behavior generically ("the exact way to background a spawn is CLI-specific" — EB-4). So the standard's stage 8, expressed generically in the trinity ("parallel worktree coder waves"), is byte-parity-safe ×3 and does NOT force a Claude-only carve-out (unlike the pack's `### Sub-agent behavior (Claude-only)` section, which has no project-trinity analog). No conflict; no parity port needed.

---

## 12. Planner handoff — open design questions

A planner can turn this into a project-side commit sequence with these resolved:
- **Pipeline + size-tiering (project vocabulary):** §4 (9-stage chain; 5-signal two-part criterion; LARGE iff release-gate-alone OR ≥2 signals; SMALL else, adversarial optional; when-in-doubt-LARGE).
- **Roster leverage (justified divergences):** §5 (D1-D5: skill-named adversarial passes; optional audit capstone; P5 reuse; complementary mid-cycle triggers; execution-half reference).
- **Exact placement:** §6 (METHODOLOGY SOURCE Part-5 subsection [MANDATORY]; PM-CHAT anchor + pointer [MANDATORY]; trinity `## Project rules` rule [MANDATORY, §3.C ordering]; 2 elective skill pointers; NOT-touched set).
- **Trinity rule text + 700-char fit:** §7 (pointer-shaped bullet, ≤700 or allowlisted; NO rationale-bijection surface; Option A single bullet preferred, Option B split fallback).
- **Parity/CI call:** §8 (NO new guard, DROP not defer; existing gates suffice; PREFLIGHT byte-parity is the sole protection).
- **Propagation surfaces + gating checks:** §9 (rows 1-5+7 minimal-green; row 6 elective; manifest note; cite-resolution Check 64/70).
- **Rule-10 map:** §10 (SERIAL one coder commit C1+C2+C3 + paired C4; cross-reference-atomicity binding reason; disjoint from concurrent BD-238).
- **No-conflict analysis:** §11 (all NONE; CLI-portable stage 8).

### 12.1 The TWO open decisions for the USER (not the planner)

1. **BD-239↔BD-245 ordering (§3.C):** RECOMMENDED run BD-245 first (rule placed once under final `## Project rules` name). FALLBACK BD-239 first under `## Project memory` + a hard hand-off note to BD-245's rename census. The planner encodes whichever the user picks; the rule text is name-agnostic (one-token delta).
2. **groupings mention (§3.B):** RECOMMENDED OMIT entirely (gate-safe; phases are the complete size unit). The user may direct a forward-reference, but it risks the DEFERRED axis.

### 12.2 The NAMED PREFLIGHT steps the planner must encode (the coder runs these)

- **PREFLIGHT-1 — trinity ×3 byte-identity:** extract the new bullet from CLAUDE/AGENTS/GEMINI, normalized diff, 0 differences (the sole body-parity protection, §8.4).
- **PREFLIGHT-2 — bloat ≤700:** measure the new trinity bullet collapsed length; confirm ≤700 OR add a `.docs-gate-allowlist.txt` bloat record with a reviewer-verified reason (§7.2).
- **PREFLIGHT-3 — operating-doc axes:** run `validate-docs.sh` (HISTORY/DEFERRED/DANGLING/BLOAT) against the trinity + METHODOLOGY (installed) + PM-CHAT; exit 0. Confirm the METHODOLOGY section + the trinity rule carry zero dates/SHAs/deferral/version tokens.
- **PREFLIGHT-4 — cite resolution:** the METHODOLOGY pointer + PM-CHAT anchor cites resolve (Check 64 + DANGLING axis); `docs/pack/METHODOLOGY.md` is a valid install target.
- **PREFLIGHT-5 — validate-pack + full battery:** `validate-pack.py` exit 0 (default + `PACK_VALIDATE_DEEP=1`); the relevant project-side checks (5/18/27/31/39/64/70/1) green; `validate-docs.sh --self-test` green; the full CI battery green.
- **PREFLIGHT-6 — no out-of-scope edits:** confirm NO edit to `validate-docs.sh` (BD-245's job), NO new groupings concept, NO pack-side surface, NO new CI check / registry count change.

### 12.3 Purpose-defeating gaps — NONE found

I checked for a purpose-defeating gap (adversarial-architect-review-on-major-gap): the standard's purpose (codify a size-tiered project pipeline that ships to clients in project vocabulary) is fully served — the chain + tiering + placement + parity call + the three wrinkles are resolved or surfaced. The ONE thing that is genuinely a USER decision (the BD-239↔BD-245 ordering) is surfaced, not silently picked, with a recommended order and a gate-safe fallback. No silent dependency on groupings. No pack-concept leak (the deliverable uses phases/phase-tasks/TD/project-agents only). The 700-char bloat constraint — the sharpest project-side difference — is measured and designed around (pointer-shaped rule). No gap that defeats the purpose.

---

## 13. Empirical-Evidence Blocks (every state-claim)

All measured at HEAD `e8ba9e7a4d1d3ea33ac3d4320d0aee77bf973381`, branch `v11-dev`, 2026-06-23.

**EB-1 — METHODOLOGY source/install split + project-side fence.**
- Command: `ls supporting-docs/METHODOLOGY.md` ; `ls project-template/docs/pack/METHODOLOGY.md` ; `grep -n "_PROJECT_SIDE_PATH_PREFIXES = " scripts/validate-pack.py`
- Output (verbatim): `supporting-docs/METHODOLOGY.md` (exists, 95015 bytes per earlier `ls -la`); `ls: project-template/docs/pack/METHODOLOGY.md: No such file or directory`; `3982:_PROJECT_SIDE_PATH_PREFIXES = ("project-template/", "supporting-docs/")`. (init-project.sh L680/L683 copies `$PACK/supporting-docs/METHODOLOGY.md` → `$TARGET/docs/pack/METHODOLOGY.md`.)
- Interpretation: the editable METHODOLOGY SOURCE is `supporting-docs/METHODOLOGY.md`; it installs to the client's `docs/pack/METHODOLOGY.md`. The project-side fence covers both `project-template/` and `supporting-docs/`.
- Conclusion: SUPPORTED — design against the SOURCE; the edit-set is `project-template/` ∪ project-side `supporting-docs/`.

**EB-2 — groupings grep-zero + BD-189-after-BD-206 vs BD-239-#2-ahead-of-BD-206.**
- Command: `grep -rln groupings project-template/ | wc -l` ; `grep -n Target backlog/BD-189.md` ; `grep -n "#2 in the v11.0 lead block" backlog/BD-239.md`
- Output (verbatim): groupings under `project-template/` = `0`; BD-189 `Target: v11.0 — sequenced directly after BD-206 …`; BD-239 `#2 in the v11.0 lead block — after BD-238, before BD-242, all ahead of BD-206`.
- Interpretation: groupings does not exist anywhere under `project-template/` (the whole subtree, broader than `docs/project/`); BD-189 (groupings) is after BD-206; BD-239 is ahead of BD-206 — so groupings is NOT-YET-EXISTING when BD-239 implements.
- Conclusion: SUPPORTED — the standard uses phases/phase-tasks/TD only; no groupings dependency; OMIT recommended (§3.B).

**EB-3 — the DESIGN-half pipeline gap (adversarial/worktree absence in METHODOLOGY).**
- Command: `grep -c adversarial supporting-docs/METHODOLOGY.md` ; `grep -c worktree supporting-docs/METHODOLOGY.md` ; `grep -c worktree project-template/CLAUDE.md`
- Output (verbatim): adversarial in METHODOLOGY = `0`; worktree in METHODOLOGY = `0`; worktree in project CLAUDE.md = `1`.
- Interpretation: METHODOLOGY documents no adversarial-review chain and no worktree-wave; the project trinity carries only 1 worktree mention. The consolidated DESIGN-half spine + the worktree-wave naming are genuinely missing from the primary SSOT.
- Conclusion: SUPPORTED — the gap BD-239 closes is real; the design ADDS the spine (STRIP nothing).

**EB-4 — PM-CHAT already carries the COMPLETE execution half (the BD-238 asymmetry).**
- Command: `grep -c worktree project-template/docs/pack/PM-CHAT.md` ; `grep -c adversarial project-template/docs/pack/PM-CHAT.md` ; `grep -n "Merge-back\|parallel worktree waves\|On conflict\|Preserve the reports\|Ask before reusing" project-template/docs/pack/PM-CHAT.md`
- Output (verbatim): worktree in PM-CHAT = `31`; adversarial in PM-CHAT = `2`; `513:**Merge-back — the patch comes only after review-clean.**`, `590:to schedule parallel worktree waves versus serial commits`, `594:**On conflict, do not hand-merge.**`, `564:**Preserve the reports.**`, `576:**Ask before reusing a live worktree for off-cycle work.**`.
- Interpretation: PM-CHAT.md already documents worktree isolation, merge-back (patch only after review-clean), parallel worktree waves off the dependency map, the conflict protocol, report preservation, and the live-worktree ASK gate. The only adversarial mentions are inside the reconciliation rule. The project side is FURTHER along than the pack on the execution half.
- Conclusion: SUPPORTED — BD-239 CONSOLIDATES + references the existing execution half rather than introducing it (the §1 asymmetry; D5).

**EB-5 — roster counts (16 agents ×3 families + 37 skills).**
- Command: `ls project-template/.claude/agents/*.md | wc -l` ; `… .codex/agents/*.toml …` ; `… .agents-plugin/optiquity-agents/agents/*.md …` ; `ls -d project-template/skills/*/ | wc -l`
- Output (verbatim): claude `16`; codex `16`; plugin `16`; skills `37`. (Roster names: architect, planner, coder, reviewer, docs-researcher, tester, grpc-schema, repo-ops, auditor + auditor-{architecture,code,docs,ops,security,tests,ui}.)
- Interpretation: the project has 16 agents per family ×3 families (48 files) + 37 skills — the richer roster the BD-239 note mandates leveraging. Skills are single-file SKILL.md (not ×3).
- Conclusion: SUPPORTED — §5 roster-leverage divergences (D1-D5) are grounded in the actual roster.

**EB-6 — the project's existing trigger vocabulary (the size-tiering calibration source).**
- Command: `grep -n "Trigger A\|Trigger B\|Trigger P-A\|tester trigger\|Planner trigger rule\|Cycle termination" supporting-docs/METHODOLOGY.md`
- Output (verbatim): `274:| Mid-phase design correction (Trigger A or B met in Workflow 4) | architect |`; `311:### Planner trigger rule`; `535:6. PM chat also checks for planner trigger (Trigger P-A / P-B / P-C …)`; `547:> **Cycle termination.**`; `549/551:… the Trigger A / Trigger B checks. A cycle … ALWAYS triggers Trigger A and the architect pass`.
- Interpretation: the project already documents Trigger A/B (architect), Trigger P-A/P-B/P-C (planner), the tester trigger, the planner-trigger threshold (>5 tasks/non-linear deps, L317-319 per earlier read), and the cycle-termination invariant. These are SITUATIONAL mid-cycle triggers, not an up-front size classification.
- Conclusion: SUPPORTED — the size-tiering (§4.2) reuses P5 from the planner-trigger threshold (D3) and wires the mid-cycle triggers as complementary (D4); no duplication.

**EB-7 — project trinity section name + flat-bullet structure + no `[rationale:]` tags.**
- Command: `grep -n "^## Project memory\|Reconciliation-instance independence\|rationale:" project-template/CLAUDE.md` ; `sed -n '360,428p' project-template/CLAUDE.md | grep "^### "`
- Output (verbatim): `360:## Project memory`; `418:- **Reconciliation-instance independence.**`; ZERO `rationale:` matches in the section; ZERO `### ` sub-headings inside the section (flat bullets). (AGENTS.md:339, GEMINI.md:357 carry `## Project memory` per the earlier 3-file grep.)
- Interpretation: the project rules-codification section is `## Project memory`, uses FLAT bullets (no `### Agent invocation rules` sub-structure like the pack), carries the Reconciliation-instance-independence rule, and uses NO `[rationale:]` tags (so no project-side rationale-bijection surface).
- Conclusion: SUPPORTED — the trinity rule is a flat bullet, no rationale section needed (§7.3); placement is direct in the rules-section.

**EB-8 — validate-docs HISTORY + DEFERRED axes (the operating-doc gates the rule text must satisfy).**
- Command: `grep -n "HISTORY_PATTERNS\|DEFERRED_PATTERN = " project-template/scripts/validate-docs.sh`
- Output (verbatim): `186:HISTORY_PATTERNS = [` (patterns: date `20\d\d-\d\d-\d\d`, sha, Commit-N, Override-N, carry-over, incident, td-past-action, per-TD); `202:DEFERRED_PATTERN = re.compile(r"\bdeferred\b|future (release|version)|\bnot yet …|\broadmap\b|coming soon|\bslated\b", IGNORECASE)`.
- Interpretation: the shipped gate blocks dates/SHAs/past-action/provenance (HISTORY) and deferred/future-version/roadmap/slated (DEFERRED) in operating docs incl. the trinity + docs/pack/*.md. "adversarial" is NOT a blocked token. The new rule + METHODOLOGY section must carry zero history + zero deferral/version phrasing; a groupings forward-reference risks the DEFERRED axis.
- Conclusion: SUPPORTED — operating-docs-no-history-no-bloat is enforced by validate-docs; §3.B OMIT-groupings + §6.1 history-free text are gate-driven.

**EB-9 — the 700-char bloat cap binds to the literal `## Project memory`; densest existing bullets are allowlisted.**
- Command: `grep -n "BLOAT_BULLET_CHAR_CAP = " project-template/scripts/validate-docs.sh` ; the `project_memory_bullets()` matcher; a Python collapse-measure of the existing bullets; `grep -c "snippet: **No destructive\|snippet: **Project SSOT" .docs-gate-allowlist.txt`
- Output (verbatim): `213:BLOAT_BULLET_CHAR_CAP = 700`; `project_memory_bullets()` finds the section via `if l.strip() == "## Project memory"`; the densest existing trinity bullet measures `1096` chars collapsed in all 3 files; the allowlist carries `6` bloat snippet records (`**No destructive operations…**` + `**Project SSOT-first.**`, 2 bullets ×3 files); `[validate-docs] PASS — operating docs clean.` (current green).
- Interpretation: the bloat axis caps EVERY `## Project memory` bullet at 700 chars and finds the section by the literal heading. The two >700-char existing bullets pass only via allowlist snippets. A NEW over-700 bullet FAILS unless split or allowlisted. The pack's 1300-cap single-bullet shape does not fit project-side.
- Conclusion: SUPPORTED — the trinity rule MUST be a ≤700-char pointer (§7.2) or allowlisted; this is the sharpest divergence from BD-238; the BD-245 rename must update this literal in lock-step (§3.C).

**EB-10 — BD-245 renames `## Project memory` → `## Project rules` + updates validate-docs.sh; runs after BD-232; reserves "project memory" for the feature.**
- Command: `grep -n "validate-docs.sh\|## Project rules\|## Project memory\|after BD-232" backlog/BD-245.md`
- Output (verbatim): title — "rename `## Project memory` → `## Project rules`"; `Target: v11.0 — directly after BD-232`; File/Symbol — "the SHIPPED client gate `project-template/scripts/validate-docs.sh` (the bloat AXIS keyed on the literal string `## Project memory` …). Renaming the section REQUIRES updating this gate in lock-step"; Unblocks — "the term 'project memory' is reserved EXCLUSIVELY for a CLI memory feature".
- Interpretation: BD-245 renames the trinity rules-section + every reference incl. the validate-docs bloat gate, in lock-step, and reserves "project memory" for the (forbidden) feature. BD-239 must place its rule in this section whose name BD-245 is changing — the ordering interaction is real.
- Conclusion: SUPPORTED — §3.C surfaces the interaction with a recommended order (BD-245 first) + a gate-safe fallback (BD-239 first under the current name + a hand-off note); NOT silently picked.

**EB-11 — project agent defs do NOT reference adversarial/pipeline stages (the bounded agent-def touch set).**
- Command: `grep -ln "adversarial\|reconciliation\|pipeline" project-template/.claude/agents/*.md`
- Output (verbatim): only `project-template/.claude/agents/auditor.md` (its "adversarial" is in audit context, not the development pipeline).
- Interpretation: no pipeline-stage agent def (architect/planner/coder/reviewer/docs-researcher) references the adversarial-review chain. Adding a stage reference is OPTIONAL; the bounded touch set is the 2 skills the adversarial passes load (D1), not the agent defs.
- Conclusion: SUPPORTED — §6.4 keeps the agent-def/skill touch tight (0 mandatory agent defs; 2 elective skill pointers).

**EB-12 — the gating client/CI checks on the project trinity + shipped docs; no body-parity check exists.**
- Command: `grep -n "Check 64\|Check 70" scripts/validate-pack.py` (+ the research census enumeration of Checks 5/18/16/19/27/31/39/64/70/1)
- Output (verbatim): Check 64 (BD-231) = "no dangling MCP/config `.example` reference in deliverable docs"; the cite-resolution rule "`project-template/{basename}` OR drop the cite. (BD-231 Check 64)"; Check 70 = shipped client doc-gate structural parity (research census L159). The trinity parity checks (18/27) compare H2 structure + canonical phrasing, NOT rule-body bytes.
- Interpretation: the project trinity + shipped docs are gated by validate-docs (4 axes) + Check 18/27 (structure/phrasing parity) + Check 64/70 (cite-resolution + doc-gate parity) + Check 39 (install-mapping). NO check byte-compares the trinity rule BODIES ×3 — the same gap the pack side has.
- Conclusion: SUPPORTED — §8 parity call: no new body-parity guard (DROP); existing gates + the PREFLIGHT byte-parity step are sufficient.

**EB-13 — CI is push-time end-state; the manifest is push-time tool-enforced.**
- Command: `grep -n "^on:" .github/workflows/validate-pack.yml` ; `ls scripts/manifest-sync.sh`
- Output (verbatim): `103:on: push`; `scripts/manifest-sync.sh` (exists).
- Interpretation: CI runs at push end-state, not per-commit; the manifest is regenerated only at push by manifest-sync.sh, only when a fixture input changed. The rule-10 single-commit verdict (§10.2) is bound by cross-reference-atomicity + trinity-byte-identity, NOT a CI cadence gate; the manifest is a NOOP unless the elective skill pointers are fixture inputs (§9 row 8).
- Conclusion: SUPPORTED — §10.2 SERIAL rationale + §9 manifest note are CI-accurate.

---

## 14. Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|---|
| 1 | **agents-never-commit** | Sole Write = `/tmp/pack-handoff-bd239-arch/DESIGN-BD-239.md` (Bash heredoc appends + `mkdir -p` on the handoff dir). All git read-only: `git rev-parse HEAD` → `e8ba9e7a4d1d3ea33ac3d4320d0aee77bf973381`, `git rev-parse --abbrev-ref HEAD` → `v11-dev`, `git status --short` → empty. No `add/commit/push/checkout/restore/stash/branch/tag/worktree/merge/rebase` or any state-changing verb. No memory store read/written (MEMORY PROHIBITION honored — §0). | COMPLIANT |
| 2 | **no-solutions-beyond-the-premise** | The user-approved premise (pipeline shape + project vocabulary + more-flexible-than-BD-238) is taken as given; the wording, placement, the project size criterion (P1-P5 + the demoted consequence), the roster-leverage design (D1-D5), and the parity call are DERIVED from evidence (EB-3/EB-4/EB-6/EB-9/EB-12), not asserted. The two genuinely-user decisions (BD-239↔BD-245 ordering §3.C; groupings §3.B) are SURFACED with recommendations, not silently chosen. No premise flaw found that defeats the purpose (§12.3). | COMPLIANT |
| 3 | **empirical-evidence-blocks** | §13 carries EB-1…EB-13: every state-claim (the METHODOLOGY source/install split; groupings grep-zero + BD-189/BD-239 ordering; the adversarial/worktree absence; PM-CHAT execution-half presence; roster counts; the existing triggers; the trinity section name + flat bullets + no rationale tags; the validate-docs HISTORY/DEFERRED axes; the 700-char bloat cap + allowlist; BD-245's rename + validate-docs lock-step; agent-def absence; the gating checks; CI push-time + manifest) backed by command + verbatim output + HEAD `e8ba9e7` + interpretation + SUPPORTED conclusion. | COMPLIANT |
| 4 | **pack-side-project-concepts-deliverable-only / project vocabulary** | The shipped standard (§4/§6/§7) uses ONLY project vocabulary — phases, phase-tasks (`phase-N.M`), TD backlog, project agents (architect/planner/coder/reviewer/docs-researcher/tester/auditor/etc.), the project's own triggers + execution half. ZERO pack work-item concepts: no "BD", no "backlog-item", no "pack-*" agent names, no `pack-ops/`, no PACK-CHAT/PACK-AGENTS, no `## Pack memory`, no `[rationale:]`/bijection/manifest surfaces (explicitly NOT carried over, §7.3). The deliverable surfaces are `project-template/` ∪ project-side `supporting-docs/` only (EB-1). | COMPLIANT |
| 5 | **ci-guard-design-measure-then-bound** | §8 applies the contract to the parity call: MEASURED the existing project-side gates first (EB-12: no body-parity check; validate-docs 4 axes + Check 18/27/64/70/39); CATEGORIZED the new rule's only new risk (×3 body drift, recoverable, short pointer); BOUNDED — a correct body-parity check is a separate larger effort; VERDICT no new guard (DROP not defer); the PREFLIGHT byte-parity step is the sized-to-fit protection. The size criterion (§4.2) is calibrated against the project's documented behavior (EB-6), not asserted. The 700-cap rule-fit is measured (EB-9, §7.2). | COMPLIANT |
| 6 | **operating-docs-no-history-no-bloat** | The trinity rule text (§7.2) + METHODOLOGY section spec (§6.1) carry ZERO history/dates/SHAs/provenance + ZERO deferred-feature/version mentions (gated by validate-docs HISTORY/DEFERRED axes — EB-8); §3.B OMITs groupings to avoid the DEFERRED axis. The trinity bullet is designed terse + ≤700 chars (the BLOAT axis — EB-9), pointer-shaped (the chain lives in METHODOLOGY, which has no per-bullet cap). LIVE forward-pointers (the METHODOLOGY cite) KEEP. | COMPLIANT |
| 7 | **deferral-is-scope-creep / no-deferral-without-user-direction** | The design lands wholly in v11.0. The parity check is DROPPED entirely (§8.3), NOT deferred (no follow-up, no scheduling). The BD-239↔BD-245 ordering is SURFACED as a user decision with a recommended order + a gate-safe fallback (§3.C) — not deferred around. The groupings question is resolved (OMIT, §3.B), not punted. Nothing is deferred to v11.1+. | COMPLIANT |
| 8 | **adversarial-architect-review-on-major-gap** | §12.3 explicitly checks for a purpose-defeating gap and finds NONE: the chain + tiering + placement + parity call are complete; the user decisions are surfaced not picked; no groupings dependency; no pack-concept leak; the 700-char constraint is measured + designed around. The doc is written to feed the fresh adversarial architect review (the next stage). Any residual risk (the BD-239↔BD-245 ordering) is flagged for the user, not hidden. | COMPLIANT |
| 9 | **rules-applied-verification-block** | This table — rules 1-9, each name + quoted evidence + terminal conclusion (no AMBIGUOUS; no empty evidence). | COMPLIANT |

---

*End of DESIGN-BD-239. Fresh first-architect pass; one Write (this doc) under /tmp; read-only git only; no memory store used. The standard re-applies BD-238's pipeline SHAPE to the project's PHASE lifecycle, MORE FLEXIBLY: a 9-stage chain (incl. an optional 7-cluster audit capstone + skill-named adversarial passes) + a 5-signal two-part size criterion calibrated against the project's existing triggers; placed in the METHODOLOGY SOURCE + the project trinity `## Project rules` (BD-245 target) + the PM-CHAT consolidating anchor; the trinity rule is a ≤700-char pointer (the bloat-cap divergence from BD-238); NO new project-side CI guard (measure-then-bound DROP); the rule-10 map is SERIAL one-coder-commit + paired audit commit, disjoint from the concurrent BD-238 work; the three wrinkles are resolved (METHODOLOGY source, groupings-omit) or surfaced as user decisions (BD-239↔BD-245 ordering). Ready for the adversarial architect review.*
