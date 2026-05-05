# IMPLEMENTATION-PLAN-ADDENDUM-4 — V3.3 integration

## §0. Status

- Date: 2026-05-05
- Author: pack-planner (V3.3 integration pass)
- Scope: integrates `ARCHITECTURE-V3.3-DELTA.md` into the v11 implementation plan. V3.2-DELTA is treated as historical record only (V3.3 §1 supersession table is authoritative).
- Adds: 5 new BDs (BD-106..BD-110); extensions to 12 existing BDs (BD-063, BD-064, BD-065, BD-067, BD-068, BD-069, BD-072, BD-076, BD-080, BD-082, BD-084, BD-094, BD-096, BD-098, BD-100, BD-105 — 16 enumerated rows; 4 deferable rows that touch existing BDs without new DoD changes are marked as such); 4 new validate-pack Checks (25, 26, 27, 28); textual updates to METHODOLOGY § Part 4 and § Part 7; prose extensions to MERGE-STRATEGY.md, MIGRATION-v10-to-v11.md, HELP-FRAGMENT.md, HELP-FRAGMENT-PACK.md, PM-CHAT.md, PACK-CHAT.md.
- Updates: base plan §3.3 (commit order; lettered insertions), §6 (MAINTAINER CHECK NEEDED items §6.M..§6.Q), §7 (release-readiness checkboxes for V3.3 features).
- Highest BD before this addendum: **BD-105** (verified — Addendum 3 §0 / final line; BACKLOG.md tops at BD-059 because BD-060..BD-105 are planned but not yet landed).
- Highest BD after this addendum: **BD-110**.
- Numbering verification: V3.3 §9.3 *recommends* BD-106..BD-110. Verified against BACKLOG.md and Addenda 1/2/3: highest existing planned BD is BD-105; BD-106..BD-110 are the next monotonic block. Numbering accepted.
- Project-side `auditor` fan-out shape verification: `project-template/.claude/agents/` lists 7 audit cluster files (`auditor-architecture`, `auditor-code`, `auditor-docs`, `auditor-ops`, `auditor-security`, `auditor-tests`, `auditor-ui`) plus the `auditor` parent. The fan-out is 7 clusters; V3.3 §8.2's "8th cluster" claim is correct. The existing per-CLI replication pattern is `.claude/agents/*.md` + `.codex/agents/*.toml` + `.gemini/agents/*.md` — `auditor-issue-tracking` ships in all three forms.
- Pack-side agent layout verification (relevant to BD-110 trinity): `.claude/agents/`, `.codex/agents/`, `.gemini/agents/` each contain 4 pack agent files (`pack-architect`, `pack-docs-researcher`, `pack-planner`, `pack-reviewer`). The pack-side IS already per-CLI replicated. **This contradicts V3.3 §8.4's claim that pack-side is "single-CLI (Claude-Code-primary)".** Surfaced as MAINTAINER CHECK §6.M; BD-110 plans for per-CLI replication of `pack-auditor` to match the existing pack-side layout, with the option to single-source if the maintainer determines V3.3 §8.4's intent overrides the existing pattern.

---

## §1. New BDs

### §1.1 BD-106 — Phase task entity model + identifier scheme + parser/emitter

**Title:** Phase task as first-class L2 entity — `phase-N.M` identifier, parser/emitter, label family, sidecar fields.

**Type:** TODO(version)

**Scope:** A (issue-tracker integration; lands tracker-mode mechanics for the new entity).

**Files (pack-relative):**

- `scripts/lib/pack-tracker/phase-task-parser.py` (new) — reads `### Tasks` blocks under `## Phase N` headings in `IMPLEMENTATION-PLAN.md`. Recognises `#### N.M — <title>` headings; captures four bullets (`Problem / Goal / Success`, `Files created/modified`, `Definition of done`, `Dependencies`). Emits `pack-id: phase-N.M`.
- `scripts/lib/pack-tracker/phase-task-emitter.py` (new) — sibling reverse module: reads tracker phase-task issues + sidecar `task_order` and emits `### Tasks` subsections in IMPLEMENTATION-PLAN.md.
- `scripts/lib/pack-tracker/sidecar-schema.py` (extend) — add `phase_tasks` block per V3.2 §4.3 (carried forward in V3.3 §4.3); add per-task `dependency_edges: [{kind, target_pack_id}]` field per V3.3 §4.3.
- `scripts/lib/pack-tracker/labels.py` (extend) — register the two new label families: `derived-from:TD-NNN` and `promoted-to:phase-N` / `promoted-to:phase-N.M`. (V3.2's `folded-into:` is NOT registered.)
- `scripts/lib/pack-tracker/id-map.py` (extend) — `task_order` field per phase per V3.2 §4.3. The mapping file gains a `phase_tasks` section keyed by `phase-N.M` resolving to issue ID + parent phase.
- `scripts/tests/test-phase-task-parser.sh` (new) — fixtures: well-formed `### Tasks` block (3 tasks); sparse phase (no `### Tasks`); malformed `#### N.M` heading (warning, not failure); phase-task with `Dependencies` bullet referencing `phase-N.M`, `TD-NNN`, `BD-NNN`.

**Description:**

- **Problem:** v11.0 introduces phase tasks as first-class L2 entities (V3.3 §2 D-21). The pack must parse them out of `IMPLEMENTATION-PLAN.md`, create them as tracker issues parented to the phase epic at L1, preserve task order through the round-trip, and represent the new label family on entities born of TD promotion.
- **Goal:** Forward migration emits a tracker issue per `#### N.M` heading; reverse migration reconstructs the heading + four bullets from tracker state + sidecar; round-trip is byte-equivalent on tracker side and whitespace-tolerant on flat-file side.
- **Success criteria:**
  - Parser recognises every legal v10 form (no breakage of v10 grammar) plus the v11.0 `#### N.M` block; round-trip fixture (BD-068 extension) covers all V3.3 §4.4 cases.
  - `pack-id: phase-N.M` body marker appears in every created issue; `template:phase-task-v11.0` label applied; `phase-N` parent label applied.
  - Sidecar `phase_tasks` block carries `task_order` and `dependency_edges` faithfully through serialise/deserialise; deterministic on re-forward.
  - Label family is closed: only `derived-from:` and `promoted-to:` registered for the promotion-linkage role; `folded-into:` is not present anywhere in the pack code or fixtures.

**Blockers:** BD-063 (forms must admit `phase-task-skeleton`); BD-064 (template-archive must include phase-task schema); BD-065 (forward migration is the host for the parser); BD-067 (reverse migration is the host for the emitter).

**Verification:**

- `bash scripts/tests/test-phase-task-parser.sh` green.
- `bash scripts/tests/tracker-migrate-roundtrip-test.sh` (BD-068; extended in §2.5 below) covers the 8 cases V3.3 §4.4 names.
- `bash scripts/validate-pack.py` exits 0 with Check 25 (BD-082 extension) green against a tracker-mode fixture project.

**Definition of done:**

- Parser + emitter modules in `scripts/lib/pack-tracker/` exist and are imported by BD-065 / BD-067.
- Sidecar schema accepts `phase_tasks` block; round-trip test (BD-068 extended) green.
- Labels module registers exactly two promotion-linkage label kinds.
- `id-map.json` schema accommodates the new `phase_tasks` section.
- No reference to `folded-into:` or `(from TD-NNN)` inline marker anywhere in pack code or fixtures (grep returns zero hits).

---

### §1.2 BD-107 — TD-NNN promotion-path tooling (Path 1 + Path 2 + direct close)

**Title:** PM Chat orchestration for `pack td promote --to=phase-N` (Path 1) and `pack td promote --to=phase-N.M` (Path 2); direct close honoured as v10 lifecycle.

**Type:** TODO(version)

**Scope:** A.

**Files (pack-relative):**

- `scripts/lib/pack-tracker/promote.sh` (new) — implements the two verb forms. Dispatches on `--to=` argument grammar (`phase-N` vs `phase-N.M`). Calls into BD-106 parser/emitter and BD-108 link orchestrator.
- `scripts/lib/pack-tracker/promote.py` (new sibling, Python helpers) — TD body sourcing, draft generation of phase shell (Path 1) or phase task body (Path 2), label emission (`derived-from:` on new entity; `promoted-to:` on closed TD).
- `project-template/docs/pack/PM-CHAT.md` (extend; single-file — trinity does not apply file-wise here) — adds the §7.1 advisory heuristic and §7.2 execution workflow per V3.3 §7. Architect-by-default for Path 1; planner-conditional-on-architect for Path 1; Path 2 typically goes direct.
- `project-template/docs/pack/METHODOLOGY.md` (extend; § Part 7 lines 1057-1064) — replaces the three resolution-path bullets with the two-path-plus-direct-close shape per V3.3 §9.5. Names the verbs.
- `project-template/HELP-FRAGMENT.md` (extend; under BD-076 surface) — adds `pack td promote --to=phase-N` and `pack td promote --to=phase-N.M` rows (§5 below).
- `scripts/tests/test-td-promote-path1.sh` (new) — fixture: TD with multi-task scope; verb invocation creates phase epic; TD closes with `promoted-to:phase-N`; phase epic carries `derived-from:TD-NNN`.
- `scripts/tests/test-td-promote-path2.sh` (new) — fixture: TD with single-task scope; verb invocation creates phase task at L2 parented to phase-N epic; labels checked.
- `scripts/tests/test-td-direct-close.sh` (new) — fixture: TD goes direct close (no verb); BACKLOG entry transitions Open → Resolved with Resolution naming a commit; no `promoted-to:` label anywhere; no new tracker entity.

**Description:**

- **Problem:** TD-NNN entries that become unblocked (METHODOLOGY § Part 7 Procedure 1 step 3) need a deterministic resolution mechanism. V3.3 §3 specifies two paths plus direct close; the tooling must honour the path 3 prohibition and the verb shape exactly.
- **Goal:** Two verb forms exist (`pack td promote --to=phase-N`, `pack td promote --to=phase-N.M`); each leaves the original TD as a closed historical record with `promoted-to:` label and the new entity gets `derived-from:TD-NNN`. Direct close uses the existing `pack td resolve` (or BACKLOG-edit) verbs unchanged from v10.
- **Success criteria:**
  - Verb dispatch: `--to=phase-N` produces a new phase epic at L1; `--to=phase-N.M` produces a new phase task at L2 parented to the named phase epic.
  - PM Chat advisory presents `(yes / change-to-path-1 / change-to-direct-close / show-details)` per V3.3 §7.1; user can override.
  - Path 1 default workflow: PM Chat invokes `architect.md` (project-side); planner is invoked only when architect's output names "planner pass needed."
  - Path 2 default workflow: PM Chat does the orchestration directly; planner / architect are user-explicit.
  - Direct close: byte-identical to v10 lifecycle; no new label anywhere.
  - METHODOLOGY § Part 7 lines 1057-1064 reflect the two-path-plus-direct shape per §4 below.

**Blockers:** BD-106 (parser/emitter must exist); BD-108 (link orchestration is invoked when promotion has `Dependencies`).

**Verification:**

- All three new test scripts green.
- `bash scripts/validate-pack.py` exits 0 with Check 27 (promotion-path label consistency) green against a fixture that has both Path 1 and Path 2 promotions.
- Manual: invoking `pack td promote --to=phase-9.99` against a non-existent phase target surfaces a typed error per V3.3 §5.6 (cross-references V1 §9 / D-7).
- METHODOLOGY § Part 7 lines 1057-1064 contain the two-path-plus-direct text; `grep "Path 3" project-template/docs/pack/METHODOLOGY.md` returns zero hits; `grep "fold-into" project-template/docs/pack/METHODOLOGY.md` returns zero hits.

**Definition of done:**

- Verbs land in `scripts/lib/pack-tracker/promote.sh` and are wired into the top-level `pack` dispatcher.
- PM-CHAT.md gains §7.1 advisory section and §7.2 execution-workflow section (referenced by name in the doc).
- METHODOLOGY § Part 7 Procedure 1 lines 1057-1064 carry the V3.3 §3 shape (two paths + direct close); old three-path text removed.
- HELP-FRAGMENT row added (lands at the BD-076 extension commit; see §3 commit-order integration).
- Three test scripts wired into CI runner (`scripts/tests/run-all.sh`).
- Path 3 references absent from pack code, fixtures, METHODOLOGY, MIGRATION doc, MERGE-STRATEGY, HELP-FRAGMENT, OPTIONAL-FEATURES.

---

### §1.3 BD-108 — Cross-entity dependency link orchestration + cycle check + gate-check extension

**Title:** Uniform cross-entity dependency model: TD ↔ phase epic, TD ↔ phase task, phase task ↔ phase task (same/cross-phase), TD ↔ TD, TD ↔ BD. Cycle check at link-creation time; Procedure 1 gate check extended.

**Type:** TODO(version)

**Scope:** A.

**Files (pack-relative):**

- `scripts/lib/pack-tracker/links.py` (new) — for each entity-pair in V3.3 §5.1, issues `provider.link(source=..., target=..., kind="blocked-by")` against V1 §5.3's reserved `link.kind` family. No new provider operation.
- `scripts/lib/pack-tracker/cycle-check.py` (new) — at link-creation time, traverse `blocked-by` from new edge's source for K hops. K is configurable; default K=10 (V1 §6.1 GraphQL one-shot capacity, carried forward by V3.3 §5.5). Refuse the link and surface a typed error per V1 §9 / D-7 if target appears in closure.
- `scripts/lib/pack-tracker/dependencies-bullet-parser.py` (new) — regex `^\s*-\s+(phase-\d+(\.\d+)?|TD-\d+|BD-\d+)\s*$` per V3.3 §5.3. Captures matched ID prefix; permits free-text annotation after the ID.
- `scripts/lib/pack-tracker/blockers-grammar.py` (extend) — admit `phase-N.M` form in the BACKLOG `Blockers:` field (METHODOLOGY § Part 7 line 990-993; V3.3 §5.3). Every legal v10 form remains legal.
- `project-template/docs/pack/METHODOLOGY.md` (extend; § Part 4 line 263 + § Part 7 lines 990-993, 1025-1029):
  - § Part 4 line 263 codifies `Dependencies` bullet grammar admitting `phase-N`, `phase-N.M`, `TD-NNN`, `BD-NNN`.
  - § Part 7 lines 990-993 admit `phase-N.M` in Blockers.
  - § Part 7 lines 1025-1029 extend Procedure 1 step 2 with `phase-N.M` blocker branch + phase-task-A-blocked-by-phase-task-B branch.
- `scripts/tests/test-cross-entity-links.sh` (new) — covers 6 entity-pair forward-link cases from V3.3 §5.2; covers reverse → re-forward replay.
- `scripts/tests/test-cycle-check.sh` (new) — fixture: A blocks B blocks C blocks A; cycle-check refuses the third edge with typed error.

**Description:**

- **Problem:** V3.3 §5 unifies dependency representation across six entity-pair types using V1 §5.3's existing `link.kind` family. Forward / reverse / round-trip mechanics, cycle detection, and gate-check logic must absorb the new pairs uniformly.
- **Goal:** PM Chat creates `blocked-by` links for every cross-entity pair using the same provider call. Cycle check runs at link creation. METHODOLOGY § Part 7 Procedure 1 gate check uses the trinity Document-locations resolver (D-6 / V1 §8.5) to read status mode-agnostically.
- **Success criteria:**
  - Forward step 7 (V1 §6.2) reads phase-task `Dependencies` bullets (in addition to TD `Blockers:`) and emits `provider.link()` calls.
  - Reverse step 5 (V1 §6.5) reads `blocked-by` links from phase tasks and emits `Dependencies` bullets in the four-bullet block.
  - Cycle check runs for every new edge across the full graph (TD ↔ TD; TD ↔ phase epic; TD ↔ phase task; phase task ↔ phase task same/cross-phase).
  - K=10 default; configurable via `tracker.toml` field `[graph] cycle_check_k = 10` (additive to existing `tracker.toml` schema).
  - Procedure 1 gate check resolves status via the trinity Document-locations resolver; flat-file mode reads the `.md`; tracker mode reads the issue label.

**Blockers:** BD-106 (parser/emitter must exist); BD-070 (typed errors are the substrate for cycle-check error surface).

**Verification:**

- `bash scripts/tests/test-cross-entity-links.sh` green for all 6 entity-pair forms.
- `bash scripts/tests/test-cycle-check.sh` green; refusal surfaces typed error `tracker-cycle-detected` (or equivalent — name matches `scripts/lib/pack-tracker/errors.py` registered constants from BD-070).
- Round-trip: `bash scripts/tests/tracker-migrate-roundtrip-test.sh` (BD-068 extension) covers the cross-phase Dependencies fixture.
- `bash scripts/validate-pack.py` exits 0 with Check 26 (Blocker / Dependencies cross-entity reference resolution) green.
- METHODOLOGY § Part 4 line 263 and § Part 7 lines 990-993, 1025-1029 reflect the V3.3 §5.3 / §5.4 grammar.

**Definition of done:**

- Links module wired into BD-065 forward (step 7) and BD-067 reverse (step 5).
- Cycle check active; K=10 default; configurable.
- Dependencies bullet parser exists and is invoked by BD-106.
- METHODOLOGY § Part 4 line 263, § Part 7 lines 990-993, lines 1025-1029 carry the V3.3 grammar.
- Tests wired into CI runner.
- Bidirectionality contract honoured: every legal v10 Blockers form remains legal (regression-tested by including v10-only fixture cases in `test-cross-entity-links.sh`).

---

### §1.4 BD-109 — Project-side `auditor-issue-tracking` sub-agent

**Title:** New 8th audit cluster under the project-side `auditor` parent fan-out — issue-tracking surface health (BACKLOG / IMPLEMENTATION-PLAN / tracker entries; dependency graph; syntax; semantics; drift).

**Type:** TODO(version)

**Scope:** A.

**Files (pack-relative; per-CLI replicated for trinity-rule compliance):**

- `project-template/.claude/agents/auditor-issue-tracking.md` (new)
- `project-template/.codex/agents/auditor-issue-tracking.toml` (new — TOML form per existing `.codex/agents/*.toml` pattern; same prompt content body inside `prompt = """..."""`)
- `project-template/.gemini/agents/auditor-issue-tracking.md` (new)
- `project-template/.claude/agents/auditor.md` (extend) — Subagents table grows from 7 rows to 8; the new row is `auditor-issue-tracking | Issue-tracking surface health: BACKLOG / IMPLEMENTATION-PLAN / tracker entries; dependencies, syntax, semantics; drift`. Coordination prose in the file's "Coordination" section gets one extra sentence in step 1 naming the new skip rule (skip when project has no BACKLOG.md and no IMPLEMENTATION-PLAN.md).
- `project-template/.codex/agents/auditor.toml` (extend; trinity-replicated content edit)
- `project-template/.gemini/agents/auditor.md` (extend; trinity-replicated content edit)
- `project-template/.claude/skills/audit-methodology/SKILL.md` (extend) — cluster definitions list grows from 7 to 8; rule 29 (file-scope rules) extends to name `BACKLOG.md`, `IMPLEMENTATION-PLAN.md`, `STATUS.md`, `CHANGELOG.md`, `.pack-tracker/id-map.json` for the new cluster's scope. Rules 25-32, 33-39, 44-47, 48-55 unchanged in shape; the new cluster slots into the existing skip-rule and ownership-precedence framework.
- `project-template/.codex/skills/audit-methodology/SKILL.md` and `project-template/.gemini/skills/audit-methodology/SKILL.md` — trinity-replicated edits (skill files are trinity-replicated per the existing `project-template/.{claude,codex,gemini}/skills/` layout).
- `scripts/tests/test-auditor-issue-tracking.sh` (new) — fixture: project tree with deliberately broken Blockers reference, deliberately orphan phase epic, deliberately stale `template_version`, deliberately broken promotion linkage; invoke `auditor-issue-tracking` (via the agent file's Bash tool surface; or simulate the prompt input/output cycle); assert each finding appears at the correct severity per V3.3 §8.2's severity-guidance table.

**Description:**

- **Problem:** No agent currently audits issue-tracking-surface health (BACKLOG dependency graph integrity, BD/TD entry semantic consistency, drift between flat-file and tracker representation, promotion-linkage health). V3.3 §8 introduces this as audit-state work — distinct from `pack-reviewer` (per-commit change review) and the existing 7 cluster sub-agents (full-codebase quality audit).
- **Goal:** A read-only sub-agent under the `auditor` parent fan-out that loads `audit-methodology`; produces severity-grouped findings (Critical / Major / Minor / Info) per V3.3 §8.2 severity-guidance table; integrates with the existing fan-out's parallel-Task spawn pattern; respects the existing skip-rule framework (skip when project has no BACKLOG.md and no IMPLEMENTATION-PLAN.md).
- **Success criteria:**
  - Sub-agent file exists in all three per-CLI directories with identical prompt content.
  - `auditor.md` parent file's Subagents table includes the new cluster.
  - `audit-methodology` skill's cluster-definitions list includes the new cluster; rule 29 names the new file scope.
  - Severity classification per V3.3 §8.2 (Critical / Major / Minor / Info guidance lists).
  - Skip rule honoured: brand-new project (no BACKLOG.md and no IMPLEMENTATION-PLAN.md) skips this cluster gracefully.
  - When invoked directly via `agent-run.sh claude --agent auditor-issue-tracking`, the sub-agent produces a standalone report (not consolidated by parent).

**Blockers:** None on V3.3 critical path. Independent of BD-106..108 (the agent reads pack state but does not depend on phase-task tooling existing — when no phase tasks exist, the cluster simply has no phase-task findings to report). Recommended sequencing: lands paired with the BD-082 extension that introduces Check 28 (step 23b in §6.1 commit order); the agent files at step 23a and the parity check at step 23b land as paired commits, keeping CI green at the boundary.

**Verification:**

- All three per-CLI agent files exist; `bash scripts/validate-pack.py` Check 28 (per-CLI parity) green.
- `bash scripts/tests/test-auditor-issue-tracking.sh` green: fixture project produces findings at expected severities.
- Invoking `auditor` parent on the fixture project includes the new cluster's findings in the consolidated report.
- Skip rule honoured: brand-new fixture (no BACKLOG.md, no IMPLEMENTATION-PLAN.md) → parent skips this cluster without error.

**Definition of done:**

- Three per-CLI agent files land in one commit (trinity rule, file-wise).
- `auditor.md` (× 3 CLIs) Subagents table extended in same commit.
- `audit-methodology/SKILL.md` (× 3 CLIs) cluster-definitions and rule-29 file-scope edits land in same commit.
- Test script wired into CI.
- HELP-FRAGMENT.md gains an invocation row for the sub-agent (lands at BD-076 extension commit; see §5).
- Trinity rule: file-wise on the per-CLI agent files (Check 28 enforces); content-wise on the trinity files at project-template root if the planner determines a verb reference is warranted (recommendation: NO trinity-file edit at v11.0; the agent invocation is documented in HELP-FRAGMENT, not in trinity files — parallel to the existing 7 cluster sub-agents which are not named individually in trinity files).

**Trigger / cadence:**

- Verb-invoked via `auditor` parent fan-out (primary path).
- Verb-invoked directly via `agent-run.sh claude --agent auditor-issue-tracking` (or per-CLI equivalent).
- Periodic via `pm-startup` Step 8 extension (V3 §28.1 recommendation system): if the project has not run `auditor-issue-tracking` in the last N=10 sessions, `pm-startup` proactively offers to invoke it (refusal-respecting per V3 §28.1.6). Documented in pm-startup skill prose; not load-bearing — verb-invoked is primary.

**Output shape:**

- Inline severity-grouped report to invoker (parent `auditor` consolidates with other clusters; direct invocation routes to the human / PM Chat).
- No file writes.

**Skills loaded:**

- `audit-methodology` (only). No platform skills (parallel to existing cluster sub-agents).

**Tools:** `Read, Grep, Glob, Bash` (mirror existing cluster sub-agents).

**Trinity rule applicability:**

- File-wise: yes (per-CLI agent files; per-CLI skill files for `audit-methodology` extension; per-CLI `auditor.md` parent extension). Validate-pack Check 28 enforces.
- Content-wise: no engagement at v11.0. Trinity files at project-template root (CLAUDE.md / AGENTS.md / GEMINI.md) are not edited as part of BD-109; they reference the `auditor` parent generally, which already exists.

---

### §1.5 BD-110 — Pack-side `pack-auditor` agent

**Title:** New pack-side ongoing-state-audit agent — peer of `pack-reviewer`, distinct role: BACKLOG dependency-graph health, BD entry semantic consistency, drift over time, pack-product/pack-ops separation, version-table consistency, issue-tracking-mode health (when tracker enabled).

**Type:** TODO(version)

**Scope:** A.

**Files (pack-relative):**

- `.claude/agents/pack-auditor.md` (new) — Claude form of the pack-side agent. Prompt body per V3.3 §8.3 (full content reproduced in the architecture delta; the maintainer copies it into the file at land time).
- `.codex/agents/pack-auditor.toml` (new) — Codex form. Same prompt content inside `prompt = """..."""`; tool surface translated to Codex shape (`Read, Grep, Glob, Bash` per existing pack-side `.toml` agents). **MAINTAINER CHECK §6.M:** V3.3 §8.4 says pack-side is single-CLI; the actual layout (`ls .codex/agents/` shows `pack-architect.toml`, `pack-docs-researcher.toml`, `pack-planner.toml`, `pack-reviewer.toml`) is per-CLI replicated. Plan adopts per-CLI replication to match existing layout; maintainer can override.
- `.gemini/agents/pack-auditor.md` (new) — Gemini form. Same prompt content.
- `PACK-CHAT.md` (extend) — adds a new "Audit cadence" section per V3.3 §8.3 / §9.6: names `pack-auditor` and its triggers (before major version implementation pass; after every minor version cut; on demand). Cross-references BD-100 milestone checkpoints (CP1 / CP2 / CP3) where `pack-auditor` is invoked.
- `.claude/skills/audit-methodology/SKILL.md` (pack-side; new — see §6 below for the directory creation question; also tracked under BD-074): the pack repo currently does not have `.claude/skills/`. **MAINTAINER CHECK §6.N:** the pack-side skill files for `audit-methodology` and `architecture-review` are required by `pack-auditor`. Are they:
  - (a) New skill files at pack root (`.claude/skills/audit-methodology/SKILL.md`, `.codex/skills/audit-methodology/SKILL.md`, `.gemini/skills/audit-methodology/SKILL.md`; same for `architecture-review`).
  - (b) Loaded from `project-template/skills/` via a path reference (the pack-side agent reads project-template skills as its source).
  - **Recommendation: (a)**, but only if BD-074 (V3 §I.2 skill placement at PACK-ROOT) has already created `.claude/skills/`, `.codex/skills/`, `.gemini/skills/`. Verify at land-time. If BD-074's skill set does not include `audit-methodology` and `architecture-review`, BD-110 ships them at pack root.
- `scripts/tests/test-pack-auditor.sh` (new) — fixture: pack repo state with deliberately broken: README version-table row out of order; pack-product/pack-ops boundary crossing (a file under `project-template/` that contains pack-ops content); trinity asymmetry (rule in CLAUDE.md not present in AGENTS.md). Invoke `pack-auditor`; assert each finding appears at the correct severity.

**Description:**

- **Problem:** No agent currently audits pack-state ongoing health. `pack-reviewer` covers per-commit / per-PR change review (modified-BDs only). The pack-state surface (full BACKLOG, version table, trinity, pack-product/pack-ops separation, tracker-mode health if enabled) is not audited as a system in its current state.
- **Goal:** A read-only pack-side agent invoked at maintainer discretion (cadence: per major version pass; per minor version cut; on demand). Loads `audit-methodology` and `architecture-review`. Produces severity-grouped findings inline. Distinct from `pack-reviewer` by trigger (ongoing-state vs pre-commit) and surface (full pack vs modified diff).
- **Success criteria:**
  - Three per-CLI agent files exist (`.claude`, `.codex`, `.gemini`) with identical prompt content.
  - PACK-CHAT.md gains "Audit cadence" section.
  - Agent invocation pattern: `claude --agent pack-auditor` (per the maintainer's MEMORY rule "pack agents use `claude --agent pack-<name>` directly").
  - BD-100 CP1 / CP2 / CP3 audit prompts reference `pack-auditor` invocation as part of each checkpoint (extension to BD-100; see §2 below).
  - Severity guidance per V3.3 §8.3 (Critical / Major / Minor / Info).

**Skill-load decision (planner-side):**

V3.3 §8.3 names `audit-methodology` AND `architecture-review` as the skills `pack-auditor` loads. The pre-planning input (architecture-review skill assessment) flagged that the architecture-review skill's actual content covers ~20% of `pack-auditor`'s checklist (only the pack-product/pack-ops separation overlaps with the skill's layer-discipline section); the other ~80% is state audit, not source-code architecture review.

**Decision:** Load `audit-methodology` always; load `architecture-review` conditionally — specifically, when the pack-state findings include candidate layer-discipline issues (boundary crossings between pack-product and pack-ops; abstraction quality concerns in the pack's shipped architecture). The agent's prompt instructs:

> Load `audit-methodology` first. If during analysis you find boundary-crossing or layer-discipline issues (e.g., pack-product files containing pack-ops rules; project-template files importing maintenance-docs paths), load `architecture-review` and apply its layer-discipline rules to the findings. Otherwise, do not load `architecture-review` — its source-code-focused methodology does not apply to ongoing-state audit work.

**Rationale:** The skill's prerequisite is "documented ARCHITECTURE.md and platform-skill rules from companion skills" — neither prerequisite is satisfied by the pack repo (the pack ships maintenance-docs/ARCHITECTURE drafts, not a load-bearing project-level ARCHITECTURE.md; no platform skills apply to the pack itself). Conditional load avoids loading a skill whose prerequisites are not met. The maintainer reviews this decision at BD-110 land-time; the skill-load rule is a one-line edit if the maintainer prefers always-load or never-load.

**Blockers:** BD-074 (pack-side skills directory creation; required for `audit-methodology` skill to exist at pack root). If BD-074 does not ship `audit-methodology` or `architecture-review` skills at pack root, BD-110 ships them.

**Verification:**

- `bash scripts/tests/test-pack-auditor.sh` green; severity classifications match.
- Manual: `claude --agent pack-auditor` returns a report against current pack state; report has executive-summary header + severity-grouped sections.
- BD-100 CP1 / CP2 / CP3 prompts reference `pack-auditor` invocation (verified at BD-100 update commit).

**Definition of done:**

- Three per-CLI agent files (`.claude/agents/pack-auditor.md`, `.codex/agents/pack-auditor.toml`, `.gemini/agents/pack-auditor.md`).
- PACK-CHAT.md "Audit cadence" section authored.
- `audit-methodology` skill exists at pack root in all three CLI variants (lands here if not landed by BD-074).
- Test wired into CI runner.
- HELP-FRAGMENT-PACK.md gains a row for `claude --agent pack-auditor` invocation (BD-076 extension; see §5).
- Trinity rule applicability:
  - File-wise: yes — per-CLI replicated to match existing pack-side agent layout. **MAINTAINER CHECK §6.M** flags the V3.3 §8.4 contradiction; if maintainer chooses single-CLI, BD-110 reduces to one file at land-time.
  - Content-wise: no engagement at v11.0.

**Trigger / cadence:**

- Verb-invoked via `claude --agent pack-auditor` (primary path).
- Recommended cadence (PACK-CHAT.md "Audit cadence" prose):
  - Before starting a major version's implementation pass (after architect + planner; before BDs land).
  - After every minor version cut.
  - On demand when maintainer suspects drift.
- Invoked at BD-100 CP1, CP2, CP3 strategic checkpoints (each CP audit prompt extends to "invoke `pack-auditor` and include findings in CP report").

**Output shape:**

- Inline severity-grouped report to invoker. Same format as project-side sub-agent.
- No file writes (read-only agent).

---

## §2. Extensions to existing BDs

### §2.1 BD-063 — Issue forms (`work-item.yml`, `inbound.yml`)

**Changes:**

- `wi-type` dropdown (in `.github/ISSUE_TEMPLATE/work-item.yml`) gains `phase-task-skeleton` option. Total: 4 options (`bd`, `td`, `phase-epic-skeleton`, `phase-task-skeleton`). Per V3.3 §6.1 and D-4-V2 reaffirmation (R11 V2 §17 noisiness still under soft cap of ~6 options).
- Conditional fields revealed when `wi-type = phase-task-skeleton` per V2 §4.2 form-family conditional-fields mechanism (V3.3 §6.1 table):
  - `wi-phase-number` (input regex `^\d+$`, required) — maps to label `phase-N`; body `pack-id: phase-N.M`.
  - `wi-task-title` (input free-text, required) — maps to title `Phase N.M — <task title>`.
  - `wi-status` (dropdown `[Done, In Progress, Pending, Deferred]`, required, default `Pending`) — maps to status label per V3.2 §2.5 carried-forward taxonomy.
  - `wi-problem-goal-success` (textarea, required) — body section.
  - `wi-files` (textarea, optional) — body section.
  - `wi-definition-of-done` (textarea, required) — body section.
  - `wi-dependencies` (textarea, optional, regex per §5.3 — one ID per line) — body section + post-create `provider.link()` calls.
- Form emits `template:phase-task-v11.0` label on form submission.
- For BD/TD types: existing `bd-blockers` / `td-blockers` textareas gain one line of help text: `Blockers may name 'phase-N' (entire phase) or 'phase-N.M' (specific task) — both forms are recognized.`

**Files affected:** `project-template/.github/ISSUE_TEMPLATE/work-item.yml` (extend); pack-repo equivalent at `.github/ISSUE_TEMPLATE/work-item.yml` (extend; trinity-applies file-wise across the two surfaces — V2 R-form-trinity).

**Tests updated:**

- `scripts/tests/test-issue-forms.sh` (existing from BD-063) gains a case for `wi-type = phase-task-skeleton`; verifies conditional-field reveal logic; verifies form submission emits the new label.

**New DoD line added:** "`wi-type` dropdown has 4 options (bd / td / phase-epic-skeleton / phase-task-skeleton); phase-task-skeleton conditional fields revealed correctly; `template:phase-task-v11.0` label emitted on submission."

---

### §2.2 BD-064 — Template-archive directory

**Changes:**

- Add `maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md` per V3.3 §6.5. Mirrors the existing `bd-v11.0/SCHEMA.md` structure: identifier scheme, body marker trio, label family, four bullet sections, reverse-emit grammar.
- Update `templates-archive/v11.0/INDEX.md` to list phase-task-v11.0 alongside existing entries.

**Files affected:** `maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md` (new); `maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md` (extend).

**Tests updated:** None (template archive is documentation-only; consumed by validate-pack Check 19 / 20).

**New DoD line added:** "`phase-task-v11.0/SCHEMA.md` exists in template archive; INDEX.md lists it."

---

### §2.3 BD-065 — Forward migration

**Changes:**

- Step 5 (parse): invoke BD-106's phase-task parser on `IMPLEMENTATION-PLAN.md`; for each `#### N.M` heading, create a phase task issue parented to the phase epic at L2.
- Step 7 (links): invoke BD-108's links module twice per task — once for the v10 `Blockers:` field (existing logic) extended to admit `phase-N.M`, and once new for the phase-task `Dependencies` bullet (new in V3.3).
- Sidecar emission: write `phase_tasks` block + per-task `dependency_edges` field per BD-106 sidecar schema.

**Files affected:** `scripts/lib/pack-tracker/forward-migrate.sh` (extend); `scripts/lib/pack-tracker/forward-migrate.py` (extend if Python helpers exist).

**Tests updated:**

- `scripts/tests/test-forward-migrate.sh` (existing from BD-065) gains assertions for phase-task issue creation, parent-edge presence (sub_issue or label fallback per V3.2 §2.7 capability flag), label set including `phase-N` + `template:phase-task-v11.0`, sidecar `phase_tasks` + `dependency_edges` populated.

**New DoD line added:** "Forward migration creates phase-task issues at L2 parented to phase epic; emits `dependency_edges` in sidecar; resolves `phase-N.M` Blockers and Dependencies bullet entries via BD-108 links module."

---

### §2.4 BD-067 — Reverse migration

**Changes:**

- Step 5 (emit): emit `### Tasks` block under each `## Phase N` heading per BD-106's emitter; preserve `task_order` from sidecar; emit `Dependencies` bullet per task from `provider.list_links(kind="blocked-by")`.
- Emit `phase-N.M` form in BACKLOG `Blockers:` field where the source TD entry's blocker is a phase task.

**Files affected:** `scripts/lib/pack-tracker/reverse-migrate.sh` (extend); `scripts/lib/pack-tracker/reverse-migrate.py` (extend).

**Tests updated:**

- `scripts/tests/test-reverse-migrate.sh` (existing from BD-067) gains assertions for `### Tasks` emission, task ordering, `Dependencies` bullet emission, `phase-N.M` form in Blockers.

**New DoD line added:** "Reverse migration emits `### Tasks` blocks with `task_order` preservation; emits `Dependencies` bullets from tracker links; emits `phase-N.M` Blockers form in BACKLOG entries."

---

### §2.5 BD-068 — Round-trip test fixture

**Changes (per V3.3 §4.4):**

- Existing fixture cases retained (3-task ordering, sparse phase, malformed heading, Path 1 derived-from, Path 2 derived-from).
- **Add:** TD that closed via direct close (status Resolved, Resolution naming a commit, no `promoted-to:` label, no new entity).
- **Add:** phase task `Dependencies` bullet referencing another phase task in a different phase (e.g., phase-7.1 names phase-3.4).
- **Add:** phase task `Dependencies` bullet referencing a TD-NNN.
- **Remove:** any V3.2 Path 3 fixture (the `(from TD-NNN)` inline marker case). It has no representation in V3.3 grammar.

**Files affected:** `scripts/tests/fixtures/roundtrip/bd-v11.0/` (extend with the new fixture cases); `scripts/tests/tracker-migrate-roundtrip-test.sh` (extend assertion set).

**Tests updated:** the same script; assertion set grows.

**New DoD line added:** "Round-trip fixture covers 8 cases (including direct-close TD, cross-phase Dependencies, TD-as-dependency); zero V3.2 Path 3 fixtures present; forward → reverse → forward produces zero diff on tracker side, whitespace-tolerant zero diff on flat-file side."

---

### §2.6 BD-069 — `template_version` dual carrier

**Changes:**

- D-18 carrier matrix gains a row for phase-task entry-type (V3.3 §6.5):
  - Body HTML comment: `<!-- template_version: phase-task-v11.0 -->`
  - Label: `template:phase-task-v11.0`
- The dual-carrier-emitter helper (existing in BD-069) extends to recognise phase-task as a fourth entry type.

**Files affected:** `scripts/lib/pack-tracker/template-version-carrier.py` (extend); `scripts/tests/test-template-version-dual-carrier.sh` (extend).

**Tests updated:** test gains a phase-task fixture case asserting both carriers present.

**New DoD line added:** "Dual-carrier matrix covers 4 entry types (BD, TD, phase-epic, phase-task); test asserts both carriers present for each."

---

### §2.7 BD-072 — recommendation.sh signal computation

**Changes:**

- Add one signal: phase-task count threshold (parallel to entry count). Per V3.3 §9.2: deferable to v11.1.
- **Plan:** mark as "v11.1 deferable" extension; v11.0 BD-072 ships unchanged. The phase-task count signal lands in v11.1 alongside any tuning adjustments.

**Files affected:** None at v11.0. (At v11.1: `scripts/lib/pack-tracker/recommendation.sh` gains the signal.)

**Tests updated:** None at v11.0.

**New DoD line added:** None at v11.0. (Document the deferral in CHANGELOG v11.0 entry: "phase-task count signal deferred to v11.1.")

---

### §2.8 BD-076 — HELP-FRAGMENT files

**Changes:**

- `project-template/HELP-FRAGMENT.md` (client surface) gains:
  - Two rows under verb section: `pack td promote --to=phase-N` (Path 1) and `pack td promote --to=phase-N.M` (Path 2). Brief description per V3.3 §3.1.
  - Sub-agent invocation row: `agent-run.sh claude --agent auditor-issue-tracking` — "Run the issue-tracking-surface health audit (sub-agent under `auditor`)."
- `HELP-FRAGMENT-PACK.md` (pack-surface, pack-root) gains:
  - Pack-side agent invocation row: `claude --agent pack-auditor` — "Run the ongoing-state audit of pack repository (BACKLOG dependency graph, BD semantic consistency, drift, version-table consistency, trinity)."
- Both fragments updated at the BD-076 ship commit.

**Files affected:** `project-template/HELP-FRAGMENT.md` (extend); `HELP-FRAGMENT-PACK.md` at pack root (extend).

**Tests updated:** `scripts/validate-pack.py` Check 22 (help-fragment freshness from BD-082) verifies both fragments contain the new entries.

**New DoD line added:** "Client fragment lists `pack td promote` verbs and `auditor-issue-tracking` invocation; pack fragment lists `pack-auditor` invocation."

---

### §2.9 BD-080 — `init-project.sh` v11 extensions

**Changes:**

- `init-project.sh` installs the new project-side per-CLI agent files (`auditor-issue-tracking.md` × 3 CLIs) at project init time.
- `init-project.sh` updates the project's `auditor.md` parent's Subagents table to list the new cluster.
- `init-project.sh` updates the project's `audit-methodology` skill's cluster definitions.

**Files affected:** `scripts/init-project.sh` (extend); fixture project at `scripts/tests/fixtures/init-project-output/` (regenerate).

**Tests updated:** `scripts/tests/test-init-project.sh` gains assertions for the new agent files and the parent's Subagents table presence.

**New DoD line added:** "`init-project.sh` installs the `auditor-issue-tracking` sub-agent at project init across all three CLIs; updates `auditor.md` parent Subagents table; updates `audit-methodology` skill's cluster list."

---

### §2.10 BD-082 — validate-pack Checks 21-24

**Changes:**

- Add Checks 25, 26, 27, 28 per §3 below. The check definitions are reproduced in §3 with full per-check spec; this BD's extension is the host for landing them.

**Files affected:** `scripts/validate-pack.py` (extend with `check_25_phase_task_coverage`, `check_26_cross_entity_reference_resolution`, `check_27_promotion_label_consistency`, `check_28_per_cli_auditor_issue_tracking_parity`); `scripts/tests/test-validate-pack.sh` (extend).

**Tests updated:** Per-check fixtures land alongside the check (see §3).

**New DoD line added:** "validate-pack.py registers Checks 25-28; each has a fail-path fixture; each check's diagnostic shape matches §3 spec."

---

### §2.11 BD-084 — `MIGRATION-v10-to-v11.md`

**Changes (per V3.3 §9.6):**

- Add §X "Phase task model" section — describes `#### N.M` heading shape; four-bullet block; the v11.0 ship of phase tasks at L2.
- Add §X+1 "Resolving open TDs at v11.0 cut" section — describes Path 1, Path 2, direct close (V3.3 §3); names the verbs; cross-references PM-CHAT.md advisory heuristic.
- Add §X+2 "Blockers and Dependencies grammar" section — codifies the additive `phase-N.M` extension to BACKLOG `Blockers:`; codifies the `Dependencies` bullet grammar per V3.3 §5.3.
- Add §X+3 "New auditor agents" section — names `auditor-issue-tracking` (project-side sub-agent) and `pack-auditor` (pack-side); explains the role boundary vs `pack-reviewer` and the existing 7 cluster sub-agents (V3.3 §8.1 boundary table).

**Files affected:** `supporting-docs/MIGRATION-v10-to-v11.md` (extend; structure spec from BD-084).

**Tests updated:** `scripts/validate-pack.py` Check 23 (cross-reference integrity from BD-082) verifies new internal refs resolve.

**New DoD line added:** "MIGRATION doc covers phase-task model, two-path-plus-direct promotion, Blockers/Dependencies grammar extensions, and the two new auditor agents."

---

### §2.12 BD-094 — `MERGE-STRATEGY.md`

**Changes:**

- Add `IMPLEMENTATION-PLAN.md` row to the per-file matrix (Addendum 1 §2.1). Strategy: prose-aware merge; phase tasks treated as additive blocks (new `#### N.M` headings under existing `### Tasks` are appended; existing `#### N.M` blocks are preserved with body merge applied per the existing prose-aware merge strategy). A1 UX applies: on body conflict in a phase task block, write `<file>.merge-conflict` and `<file>.upstream`; user resolves; user re-runs `--resume`.

**Files affected:** `supporting-docs/MERGE-STRATEGY.md` (extend; lands at BD-094 ship commit).

**Tests updated:** `scripts/tests/test-customization-preserve.sh` (BD-088) gains a fixture case where a project has hand-edited `IMPLEMENTATION-PLAN.md` and the migrator preserves the edits.

**New DoD line added:** "MERGE-STRATEGY.md covers IMPLEMENTATION-PLAN.md preservation; phase-task-block merge semantics defined; A1 UX described for body conflicts."

---

### §2.13 BD-096 — Synthetic-fixture set

**Changes (per V3.3 §9.2):**

- Add multi-task phase fixture (≥3 phases each with 2-5 phase tasks).
- Add sparse phase fixture (phase with no `### Tasks` block).
- Add malformed task heading fixture (negative case).
- Add promotion-path TD fixtures: one TD that promoted via Path 1; one TD that promoted via Path 2.
- Add direct-close TD fixture (Resolved with no `promoted-to:` label).
- Add cross-phase dependency fixture (phase-7.1 names phase-3.4 in `Dependencies`).
- **Remove:** any V3.2 Path 3 fixture if present (the inline `(from TD-NNN)` marker case).

**Files affected:** `scripts/tests/fixtures/synthetic/` (extend with new fixture trees); `scripts/tests/test-customization-preserve.sh` (extend assertions).

**Tests updated:** Same script.

**New DoD line added:** "Synthetic-fixture set covers phase-task fixtures (multi-task, sparse, malformed, Path 1, Path 2, direct close, cross-phase dep); zero Path 3 fixtures present."

---

### §2.14 BD-098 — `OPTIONAL-FEATURES.md` tracker walkthrough

**Changes (per V3.3 §9.6):**

- Add subsection "Phase task tracker workflow" describing the L2 placement, parent-edge mechanism, `pack-id: phase-N.M`, label set.
- Add subsection "The two new auditor agents" describing `auditor-issue-tracking` and `pack-auditor`; cross-references `MIGRATION-v10-to-v11.md` and PM-CHAT.md / PACK-CHAT.md.

**Files affected:** `supporting-docs/OPTIONAL-FEATURES.md` (extend).

**Tests updated:** None mechanical.

**New DoD line added:** "OPTIONAL-FEATURES.md covers phase-task tracker workflow and the two new auditor agents."

---

### §2.15 BD-100 — Pack-implementation milestone checkpoints

**Changes (per V3.3 §9.2):**

- Each of CP1, CP2, CP3 audit prompts gains a step: "Invoke `claude --agent pack-auditor` and include findings in the CP report." The CP report template gains a "pack-auditor findings" subsection.

**Files affected:** `maintenance-docs/v11-implementation/CHECKPOINT-1-PROMPT.md`, `CHECKPOINT-2-PROMPT.md`, `CHECKPOINT-3-PROMPT.md` (extend; each gains the pack-auditor invocation step); the CP report templates (similar extension).

**Tests updated:** None mechanical. CP1 / CP2 / CP3 reports are maintainer-driven artifacts.

**New DoD line added:** "Each CP prompt invokes `pack-auditor` and includes the agent's findings in the CP report."

---

### §2.16 BD-105 — STATUS.md phase-row dual-link rendering

**Changes (per V3.3 §9.2):**

- The phase-row link in tracker mode optionally includes a child-link to the phase-task issue list (parallel to the existing parent-link to the phase epic).
- **Plan:** mark as "v11.1 deferable" — v11.0 BD-105 ships dual-link (phase epic only); the child-link to phase-task list is a v11.1 incremental extension. Document deferral in CHANGELOG v11.0.

**Files affected:** None at v11.0. (At v11.1: `scripts/lib/pack-tracker/status-md-renderer.py`.)

**Tests updated:** None at v11.0.

**New DoD line added:** None at v11.0.

---

## §3. validate-pack Checks 25-28

Each check is added to `scripts/validate-pack.py` under BD-082 extension (§2.10).

### §3.1 Check 25 — Phase-task entity coverage

- **Number:** 25.
- **Mode applicability:** tracker-mode-only (no-op when `tracker.toml` absent or `mode.state != "tracker"`).
- **Trigger condition:** every CI run; every `pack tracker doctor` invocation.
- **Pass criteria:** for every `#### N.M` heading in `IMPLEMENTATION-PLAN.md`, a tracker issue exists with body marker `<!-- pack-id: phase-N.M -->` and label set including `phase-task` + `phase-N` + `template:phase-task-v11.0`.
- **Fail diagnostic shape:** `Check 25 FAIL: phase-N.M heading at IMPLEMENTATION-PLAN.md line LLL has no corresponding tracker issue (or issue lacks pack-id marker / required labels). Detail: <missing-attribute>.`
- **Fixture (fail path):** `scripts/tests/fixtures/validate-pack/check-25-fail/` — project tree with a `#### 3.1` heading in IMPLEMENTATION-PLAN.md but no corresponding tracker issue (sidecar id-map.json lacks the phase-3.1 entry). Expected: Check 25 fails with the diagnostic naming `phase-3.1`.

### §3.2 Check 26 — Blocker / Dependencies cross-entity reference resolution

- **Number:** 26.
- **Mode applicability:** always-on (flat-file mode reads .md files; tracker mode also reads tracker state).
- **Trigger condition:** every CI run; every `pack tracker doctor` invocation.
- **Pass criteria:** every `phase-N`, `phase-N.M`, `TD-NNN`, `BD-NNN` reference in any BACKLOG `Blockers:` field or any phase-task `Dependencies` bullet resolves to an existing entity. Tracker mode: reads issue state. Flat-file mode: reads the `.md`.
- **Fail diagnostic shape:** `Check 26 FAIL: <file>:<line> references <ID> which does not exist as a <expected-type>.` Severity: warning if reference target is plausibly future-state (e.g., a phase number higher than the current max), error if reference target is in the past or never-existed.
- **Fixture (fail path):** `scripts/tests/fixtures/validate-pack/check-26-fail/` — BACKLOG entry with `Blockers: - phase-99.99` (does not exist). Expected: Check 26 fails (or warns) per the rule.

### §3.3 Check 27 — Promotion-path label consistency

- **Number:** 27.
- **Mode applicability:** tracker-mode-only.
- **Trigger condition:** every CI run; every `pack tracker doctor` invocation.
- **Pass criteria:** every `derived-from:TD-NNN` label has a corresponding closed TD-NNN issue with `promoted-to:` label naming this entity, and vice versa. The two label kinds are paired bidirectionally.
- **Fail diagnostic shape:** `Check 27 FAIL: orphan promotion linkage. Issue <ID> has label '<derived-from|promoted-to>' but the paired entity does not carry the matching label. Expected: <other-label>.`
- **Fixture (fail path):** `scripts/tests/fixtures/validate-pack/check-27-fail/` — phase epic with `derived-from:TD-031` label but TD-031 issue does not have `promoted-to:phase-N` label (the BD-067 reverse migration is incomplete). Expected: Check 27 fails naming the orphan.

### §3.4 Check 28 — Per-CLI parity for `auditor-issue-tracking.md`

- **Number:** 28.
- **Mode applicability:** always-on (the agent files exist regardless of tracker mode).
- **Trigger condition:** every CI run.
- **Pass criteria:** the three per-CLI agent files (`project-template/.claude/agents/auditor-issue-tracking.md`, `project-template/.codex/agents/auditor-issue-tracking.toml`, `project-template/.gemini/agents/auditor-issue-tracking.md`) all exist; the prompt body content is equivalent across the three (line-comparison or normalized-content hash; the `.toml` form's `prompt = """..."""` block content matches the `.md` body content of the other two).
- **Fail diagnostic shape:** `Check 28 FAIL: per-CLI parity violated for auditor-issue-tracking. Missing file: <path>` OR `Check 28 FAIL: per-CLI prompt body diverges between <fileA> and <fileB>. Diff: <first-divergence-line>`.
- **Fixture (fail path):** `scripts/tests/fixtures/validate-pack/check-28-fail/` — project tree with `.claude/agents/auditor-issue-tracking.md` present but `.codex/agents/auditor-issue-tracking.toml` absent. Expected: Check 28 fails naming the missing file.

**Note on Check 28 vs the existing per-CLI agent parity check.** V3.3 §9.4 says "Check 28 — per-CLI parity for the new `auditor-issue-tracking.md` agent file." V3.3 §8.4 also says "validate-pack's existing per-CLI agent parity check (existing) covers `auditor-issue-tracking` automatically (the check is generic, not per-agent)." These two statements appear inconsistent. Resolution: Check 28 is a NEW check specific to `auditor-issue-tracking.md`. If a generic per-CLI agent parity check already exists in validate-pack at v11.0 cut, Check 28 may be redundant; in that case, Check 28 lands as a one-line addition to the generic check's name list (no new function). **MAINTAINER CHECK §6.O:** verify at BD-082 land-time whether the generic per-CLI parity check exists. If yes, Check 28 reduces to a list-extension; if no, Check 28 is a new function per the spec above.

---

## §4. METHODOLOGY updates

All METHODOLOGY edits land at BD-107 (Path 1/2 verb shape) and BD-108 (Blockers/Dependencies grammar) commits respectively. Single file: `project-template/docs/pack/METHODOLOGY.md` (trinity does not apply file-wise — METHODOLOGY is a single-file doc under `docs/pack/`).

### §4.1 § Part 4 line 257-264 — Phase task format spec

**Current text shape (per V3.3 §9.5):** the phase-task four-bullet block is described in METHODOLOGY § Part 4 around lines 257-264. The `Dependencies` bullet's content is currently free-form prose ("other tasks within this phase or external work the task awaits").

**Replacement shape:**

> The four required bullets per phase task:
> - **Problem / Goal / Success**: ... (unchanged)
> - **Files created/modified**: ... (unchanged)
> - **Definition of done**: ... (unchanged)
> - **Dependencies**: nested bullets, one entry per line. Each entry references another work item by its ID: `phase-N` (entire phase), `phase-N.M` (specific phase task), `TD-NNN`, or `BD-NNN`. Free-text annotation after the ID is permitted (e.g., `- phase-3.1 (must complete schema before this task)`); the parser captures only the matched ID prefix. Regex: `^\s*-\s+(phase-\d+(\.\d+)?|TD-\d+|BD-\d+)\s*$`.

**Lands at:** BD-108 commit.

### §4.2 § Part 4 line 263 — `Dependencies` bullet grammar codification

Subsumed by §4.1 above.

### §4.3 § Part 7 line 990-993 — Blockers grammar extension

**Current text shape:** Blockers field admits `phase-N`, `TD-NNN`, `BD-NNN`, free-text external conditions.

**Replacement shape:**

> The `Blockers:` field is a nested bullet list. Each entry references a blocker by ID or names a free-text external condition. Recognised IDs:
> - `phase-N` — entire phase (resolves when phase epic is Done).
> - `phase-N.M` — specific phase task (resolves when phase task is Done). **NEW in v11.0.**
> - `TD-NNN` — a Tracking-Deferred entry.
> - `BD-NNN` — a Backlog-of-the-pack entry (cross-namespace; rare in client repos).
> - Free-text — an external condition (e.g., "Apple framework available", "user decision pending"). Free-text entries are surfaced for human review; they do not auto-resolve.

Every legal v10 form continues to parse.

**Lands at:** BD-108 commit.

### §4.4 § Part 7 lines 1025-1029 — Procedure 1 step 2 extension

**Current text shape:** Procedure 1 step 2 distinguishes phase blocker, TD blocker, external condition.

**Replacement shape:**

> Step 2 — for each blocker, determine status:
> - **Phase N blocker**: tracker mode reads `status:done` label on phase epic; flat-file mode reads `✅` marker on `## Phase N` heading.
> - **Phase N.M blocker** (NEW v11.0): tracker mode reads `status:done` label on phase task; flat-file mode reads `✅` marker on `#### N.M` heading.
> - **Phase task A blocked by phase task B** (NEW v11.0; appears in `Dependencies` bullet, not Blockers): same resolution mechanism — read target task's status.
> - **TD blocker**: tracker mode reads `status:resolved` label on TD issue; flat-file mode reads BACKLOG entry Status.
> - **External condition**: surfaced for human review; no automatic resolution.

The gate-check is mode-agnostic: chat resolves status via the trinity Document-locations resolver (D-6 / V1 §8.5).

**Lands at:** BD-108 commit.

### §4.5 § Part 7 lines 1057-1064 — resolution-path replacement

**Current text shape:** three bullets — addendum task within current phase / dedicated cleanup phase / separate pass of current phase.

**Replacement shape:**

> When a TD-NNN becomes unblocked (step 3), three outcomes are possible:
> - **Direct close** — the TD's work is small (≤ ~30 minutes), unblocked, and fits in the current chat session. Close via `pack td resolve` (or BACKLOG-edit). No new tracker entity is created. Resolution field names the commit / change that closed the TD. This is the v10 lifecycle, unchanged.
> - **Path 1** — the TD's work spans multiple tasks and warrants its own phase. Verb: `pack td promote --to=phase-N`. PM Chat invokes the architect by default to design the new phase shell (Goal / Prerequisite / Tasks / Verification / Risks). The architect's output decides whether the planner is invoked next.
> - **Path 2** — the TD's work fits as a single task within an existing phase. Verb: `pack td promote --to=phase-N.M`. PM Chat does the orchestration directly; planner / architect are invoked only on user-explicit request.
>
> Both Path 1 and Path 2 leave the original TD as a closed historical record (Resolution names the new entity; tracker label `promoted-to:phase-N` or `promoted-to:phase-N.M`); the new entity carries `derived-from:TD-NNN` label. PM Chat advises the path per the heuristic in PM-CHAT.md §7.1; the user can always override.

**Lands at:** BD-107 commit.

---

## §5. Other doc updates (MERGE-STRATEGY, MIGRATION, HELP-FRAGMENT, PM-CHAT, PACK-CHAT)

### §5.1 MERGE-STRATEGY.md (BD-094 extension)

Per §2.12 above. Lands at BD-094 ship commit (step 19a).

### §5.2 MIGRATION-v10-to-v11.md (BD-084 extension)

Per §2.11 above. Lands at BD-084 ship commit (step 30).

### §5.3 HELP-FRAGMENT.md and HELP-FRAGMENT-PACK.md (BD-076 extension)

Per §2.8 above. The two `pack td promote` rows + `auditor-issue-tracking` invocation row land in the client fragment; the `pack-auditor` invocation row lands in the pack fragment. Both at BD-076 ship commit (step 16).

### §5.4 PM-CHAT.md (project-template/docs/pack/)

**Additions:**

- New §X "TD resolution at unblocked time" section per V3.3 §7.1 advisory heuristic — the table mapping signal → advised path; the user-presentation prompt format `(yes / change-to-path-1 / change-to-direct-close / show-details)`.
- New §X+1 "TD promotion execution workflow" section per V3.3 §7.2 — Path 1 invokes architect by default; planner conditional on architect's call. Path 2 PM Chat does direct work; planner / architect user-explicit.
- New §X+2 "Routing the issue-tracking auditor" section — when to invoke `auditor-issue-tracking` (verb-invoked via parent `auditor`, or pm-startup Step 8 periodic offer). Cross-references HELP-FRAGMENT.

**Files affected:** `project-template/docs/pack/PM-CHAT.md` (extend; single-file — trinity does not apply).

**Lands at:** BD-107 commit (the verb shape and the workflow are intertwined; landing them together avoids stale prose).

### §5.5 PACK-CHAT.md (pack root)

**Additions:**

- New "Audit cadence" section per V3.3 §8.3 / §9.6:
  - Names `pack-auditor` as the agent for ongoing-state pack audit.
  - Triggers: before major version implementation pass (after architect + planner; before BDs land); after every minor version cut; on demand when drift is suspected.
  - Cross-references BD-100 milestone checkpoints (CP1 / CP2 / CP3).
  - Distinguishes from `pack-reviewer` (per-commit / per-PR change review; modified-BDs only).

**Files affected:** `PACK-CHAT.md` at pack root (extend; single-file — trinity does not apply).

**Lands at:** BD-110 commit.

---

## §6. Updates to base plan

### §6.1 §3.3 commit-order integration

The base plan §3.3 sequence is steps 1..34. Addenda 1, 2, 3 inserted lettered steps (19a, 20a, 22a, 22b, 22c, 30a, 30b, 33a, 33b, 33c, 9a). Addendum 4 inserts:

- **After step 9a (BD-105 STATUS.md dual-link), insert step 9b: BD-106 — phase-task entity model + parser/emitter + sidecar fields + label family.** Rationale: BD-106 extends BD-063 (forms; step 3), BD-064 (templates; step 4), BD-065 (forward; step 6), BD-067 (reverse; step 8), BD-068 (round-trip; step 9). All blockers landed by step 9. BD-106 lands as a coherent extension to all five at once. Same-commit landing of BD-063/064/065/067 extensions described in §2 with BD-106 itself; alternative is splitting across each existing-BD's commit (rejected — would force CI-green at intermediate boundaries that contradict V3.3's atomic mechanism).
- **After step 9b (BD-106), insert step 9c: BD-108 — cross-entity dependency link orchestration + cycle check + Procedure 1 gate-check extension.** Rationale: BD-108 extends BD-070 (typed errors; step 5) and BD-106 (just landed). METHODOLOGY § Part 4 line 263 + § Part 7 lines 990-993, 1025-1029 land in this commit.
- **After step 9c (BD-108), insert step 9d: BD-107 — TD promotion verb tooling (Path 1 + Path 2) + PM-CHAT.md advisory & workflow + METHODOLOGY § Part 7 lines 1057-1064 update.** Rationale: BD-107 depends on BD-106 (parser/emitter) + BD-108 (link orchestrator). PM-CHAT.md §7.1 / §7.2 lands in this commit. METHODOLOGY § Part 7 lines 1057-1064 lands in this commit.
- **After step 24 (BD-082 validate-pack Checks 21-24), insert step 24a: extension of BD-082 to add Checks 25-27.** Rationale: Checks 25-27 are tracker-mode-only and depend on BD-106 / BD-107 / BD-108 having landed. They land here as a ride-along extension to BD-082.
- **After step 23 (BD-081 trinity addenda), insert step 23a: BD-109 — `auditor-issue-tracking` sub-agent + `auditor.md` parent table extension + `audit-methodology` skill extension.** Rationale: BD-109 is independent of BD-106..108 critical path but lands after BD-081 to share the trinity-replicated commit cadence. Validate-pack Check 28 lands in the same commit as the agent files (per the V3.3 §6 rule that fixture-and-check land together).
- **After step 23a (BD-109), insert step 23b: BD-082 extension to add Check 28.** Rationale: Check 28 is the per-CLI parity check for the agent file landed in step 23a; landing them as paired commits keeps validate-pack green. Alternative (collapse into single commit): acceptable; the lettered-step convention notates the pairing.
- **After step 33c (BD-102 dog-food), insert step 33d: BD-110 — `pack-auditor` agent + PACK-CHAT.md "Audit cadence" section + BD-100 CP-prompt extensions.** Rationale: BD-110 is independent of the v11 critical path; lands late in the sequence so PACK-CHAT.md gains the "Audit cadence" section after the bulk of v11 is in place. The BD-100 CP-prompt extensions are textual; CP1/CP2/CP3 reports themselves are maintainer-driven and re-run incorporates the new step on next invocation.

**Updated tail of §3.3 (illustrative):**

```
... 9. BD-068 — round-trip test
    9a. BD-105 — STATUS.md dual-link rendering
    9b. BD-106 — phase-task entity model + parser/emitter
    9c. BD-108 — cross-entity dependency links + cycle check
    9d. BD-107 — TD promotion verbs (Path 1 + Path 2)
10. BD-069
... 23. BD-081
    23a. BD-109 — auditor-issue-tracking sub-agent (+ auditor.md parent + audit-methodology skill)
    23b. BD-082 ext — Check 28 (per-CLI parity)
24. BD-082 — Checks 21-24
    24a. BD-082 ext — Checks 25-27 (tracker-mode-only)
... 33c. BD-102 — pack-repo dog-food migration
    33d. BD-110 — pack-auditor agent + PACK-CHAT audit cadence + BD-100 CP-prompt extensions
34. BD-093 — release pin
```

CI green at every numbered + lettered boundary. Specifically:

- After 9b: validate-pack green; phase-task parser tests green; round-trip test (BD-068) extended cases green. Check 25 not yet active (lands at 24a).
- After 9c: cycle-check tests green; cross-entity-links tests green; METHODOLOGY § Part 4 line 263 and § Part 7 lines 990-993, 1025-1029 reflect new grammar.
- After 9d: promote-path1 / promote-path2 / direct-close tests green; PM-CHAT.md updated; METHODOLOGY § Part 7 lines 1057-1064 reflect two-path-plus-direct shape.
- After 23a: per-CLI agent files exist in three forms; auditor.md parent table extended; audit-methodology skill cluster list extended; test-auditor-issue-tracking.sh green.
- After 23b: validate-pack Check 28 active; per-CLI parity verified.
- After 24a: validate-pack Checks 25-27 active; Checks pass against existing fixture set.
- After 33d: pack-auditor agent files exist; PACK-CHAT.md "Audit cadence" section present; CP prompts updated.

### §6.2 §7 release-readiness checklist additions

Append to §7 of the base plan (after Addenda 1/2/3 additions):

- [ ] **BD-106 phase-task entity model**: `bash scripts/tests/test-phase-task-parser.sh` green; round-trip fixture (BD-068 extended) covers all 8 V3.3 §4.4 cases; sidecar `phase_tasks` block + per-task `dependency_edges` populated faithfully through round-trip.
- [ ] **BD-107 promotion-path tooling**: `pack td promote --to=phase-N` and `pack td promote --to=phase-N.M` verbs functional; direct-close path is identical to v10 lifecycle (no new label); PM-CHAT.md §7.1 advisory + §7.2 workflow sections present; METHODOLOGY § Part 7 lines 1057-1064 carry two-path-plus-direct shape; `grep "Path 3" project-template/` returns zero hits; `grep "fold-into" project-template/ scripts/` returns zero hits.
- [ ] **BD-108 cross-entity dependency model**: cycle-check green at K=10 default; tests cover all 6 entity-pair forms; METHODOLOGY § Part 4 line 263 and § Part 7 lines 990-993, 1025-1029 reflect new grammar; `phase-N.M` form parses in BACKLOG `Blockers:`; `Dependencies` bullet grammar codified.
- [ ] **BD-109 auditor-issue-tracking sub-agent**: three per-CLI files exist with identical prompt content; `auditor.md` parent's Subagents table has 8 rows; `audit-methodology` skill's cluster definitions list has 8 entries; rule 29 file-scope names BACKLOG.md / IMPLEMENTATION-PLAN.md / STATUS.md / CHANGELOG.md / .pack-tracker/id-map.json; `bash scripts/tests/test-auditor-issue-tracking.sh` green; skip rule honoured for brand-new fixture.
- [ ] **BD-110 pack-auditor agent**: three per-CLI files exist (or one, per MAINTAINER CHECK §6.M outcome) with prompt content per V3.3 §8.3; PACK-CHAT.md "Audit cadence" section present; `claude --agent pack-auditor` returns severity-grouped report against current pack state; BD-100 CP1/CP2/CP3 prompts reference `pack-auditor` invocation.
- [ ] **validate-pack Checks 25-28**: each registered; each has fail-path fixture; CI run shows all four green against the v11.0 reference state.
- [ ] **HELP-FRAGMENT updates**: client fragment lists `pack td promote --to=phase-N` + `pack td promote --to=phase-N.M` + `auditor-issue-tracking` invocation; pack fragment lists `pack-auditor` invocation; Check 22 (help-fragment freshness) green.
- [ ] **General-use audit (Addendum 4 scope)**: `grep -i "OT\|Optiquity"` returns zero hits in V3.3-introduced prose (METHODOLOGY updates, PM-CHAT.md additions, PACK-CHAT.md audit-cadence section, MIGRATION extensions, OPTIONAL-FEATURES extensions, HELP-FRAGMENT additions, agent prompts).
- [ ] **V3.2-DELTA artifacts removed/superseded**: V3.2-DELTA file remains as historical record; no live design references it; `grep "V3.2-DELTA" maintenance-docs/v11-research/` returns hits only in the file itself and in V3.3-DELTA's supersession table.
- [ ] **Bidirectionality regression check**: `bash scripts/tests/test-v10-grammar-regression.sh` (BD-068 extension or sibling) confirms every legal v10 BACKLOG and IMPLEMENTATION-PLAN form continues to parse.

### §6.3 §6 MAINTAINER CHECK NEEDED additions

Append to §6 of the base plan (Addendum 3 ends at §6.L):

- **§6.M — Pack-side `pack-auditor` per-CLI replication.** V3.3 §8.4 says "pack-side `pack-auditor.md` is single-CLI (pack development is Claude-Code-primary)." The actual pack-side layout has all four existing pack agents replicated across `.claude/agents/`, `.codex/agents/`, `.gemini/agents/` (12 files total). Plan adopts per-CLI replication for `pack-auditor` to match the existing layout. Options:
  - (a) **Per-CLI replication, three files (proposed).** Matches existing pack-side layout; symmetric with existing `pack-architect`, `pack-planner`, `pack-reviewer`, `pack-docs-researcher`.
  - (b) Single-CLI per V3.3 §8.4. Inconsistent with existing layout; would warrant either deleting the other agents' Codex/Gemini variants or special-casing `pack-auditor`.
  - (c) Single-CLI `pack-auditor` AND retire the other agents' Codex/Gemini variants. Contradicts the existing per-CLI invocation patterns documented in PACK-AGENTS.md.
  - **Recommendation: (a).** Maintainer confirms at BD-110 land-time. If (a), V3.3 §8.4's claim is documented as superseded by the existing layout.

- **§6.N — Pack-side skill provenance for `pack-auditor`.** `pack-auditor` loads `audit-methodology` (always) and `architecture-review` (conditionally). The pack root `.claude/skills/`, `.codex/skills/`, `.gemini/skills/` are introduced by BD-074 (V3 §I.2 placement at PACK-ROOT, per §6.F of the base plan). Options:
  - (a) **BD-074 ships `audit-methodology` and `architecture-review` skills at pack root (proposed).** Pack-root skills directory is created by BD-074; the two skills land in that commit alongside `pack-startup`. BD-110 has no skill-file work; only the agent file references the skills.
  - (b) BD-110 ships the two skill files at pack root. Adds skill-file authoring to BD-110's scope.
  - (c) `pack-auditor` references the skills from `project-template/skills/` (the source-of-truth location) via path. Asymmetric with other pack agents (which presumably load from pack root once BD-074 lands).
  - **Recommendation: (a) — verify at BD-074 land-time.** If BD-074's skill set already includes both, BD-110 has no extra work. If BD-074's set is `pack-startup` only, BD-110 ships `audit-methodology` and `architecture-review` at pack root.

- **§6.O — Check 28 redundancy with existing per-CLI parity check.** V3.3 §9.4 says Check 28 is per-CLI parity for `auditor-issue-tracking.md`; V3.3 §8.4 says the existing per-CLI parity check covers `auditor-issue-tracking` automatically. Options:
  - (a) **New Check 28 specific to `auditor-issue-tracking.md` (per V3.3 §9.4 spec; proposed).** Adds explicit coverage; redundant if the generic check exists.
  - (b) Generic per-CLI parity check at v11.0 cut covers `auditor-issue-tracking` automatically; Check 28 becomes a no-op stub or a list-extension.
  - **Recommendation: audit at BD-082 land-time.** Run `grep "def check_" scripts/validate-pack.py` and inspect the generic per-CLI parity check. If it already iterates the per-CLI agent set, Check 28 reduces to one-line addition (filename to the iteration set). If not, Check 28 is a new function. Either way, the DoD line is satisfied.

- **§6.O.1 — Check 25 numbering collision: BD-089 (base plan) vs Addendum 4 §3.1.** Base plan BD-089 (`IMPLEMENTATION-PLAN.md`) ships **Check 25 (`check_customization_detection_regression_guard`, BD-059 fix)**. Addendum 4 §3.1 also numbers the phase-task entity-coverage check as Check 25. Two distinct functions cannot share the same Check number. Per §6.C audit framework, the planner runs `grep "def check_" scripts/validate-pack.py` at BD-078 land-time; the actual next-free integer absorbs the v11 Checks contiguously. The same renumbering applies at BD-082 ext (step 24a) for the V3.3 Checks 25–28: they become Checks N..N+3 where N is the next free integer after BD-089's customization-detection check (which itself may renumber under §6.C).
  - **Recommendation:** explicit acknowledgement that the V3.3 Checks 25/26/27/28 are NOT guaranteed to be 25/26/27/28 in `validate-pack.py`; the numbers are pedagogical references in this addendum and in V3.3-DELTA. The planner re-numbers contiguously at BD-082 land-time per §6.C. The check NAMES (`check_phase_task_coverage`, `check_cross_entity_reference_resolution`, `check_promotion_label_consistency`, `check_per_cli_auditor_issue_tracking_parity`) are stable; the numbers are not. Same applies to BD-089's Check 25 name (`check_customization_detection_regression_guard`).

- **§6.P — Architect-default for Path 1 and the `## Phase` body shape.** V3.3 §7.2 says PM Chat invokes the architect by default for Path 1 because the phase format requires Goal / Prerequisite / `### Tasks` / `### Verification` / `### Agent` / `### Risks`. The plan honours this. Options:
  - (a) **Architect-by-default (proposed).** Honours V3.3 §7.2; aligns with METHODOLOGY § Part 4 phase format.
  - (b) PM Chat does Path 1 directly with a template skeleton; architect invoked only on user request. Simpler; loses the architectural-decision review for new phases.
  - **Recommendation: (a).** Maintainer confirms at BD-107 land-time. The trade-off (architect time cost vs phase-quality) favours (a).

- **§6.Q — Cycle-check K-value.** V3.3 §5.5 names K=10 default with configurability. The plan exposes `tracker.toml [graph] cycle_check_k = 10` as a new configuration field. Options:
  - (a) **K=10 default, configurable via tracker.toml (proposed).** V3.3-aligned; field is additive (existing tracker.toml schemas continue to load); 10 covers V1 §6.1 GraphQL one-shot capacity.
  - (b) K=10 default, hardcoded (not configurable). Simpler; cannot tune without code change.
  - (c) K=20 default. Larger search; more complete cycle detection at edge of GraphQL one-shot.
  - **Recommendation: (a).** Maintainer confirms at BD-108 land-time. If `tracker.toml` schema-extension is rejected, fall back to (b).

- **§6.R — Sidecar `dependency_edges` annotation preservation.** V3.3 §4.3 specifies the sidecar `dependency_edges` per-task entries as `[{kind, target_pack_id}]` only. V3.3 §5.3 permits free-text annotations after the matched ID in the `Dependencies` bullet grammar. If the annotation is dropped on round-trip, the flat-file `Dependencies` bullet's annotation text is lost on reverse. Options:
  - (a) **Add `annotation` sub-field to `dependency_edges` per-task entry (proposed).** Preserves free-text round-trip; sidecar grows by one optional field per dependency.
  - (b) Drop annotation on round-trip. Document the loss in MIGRATION doc as an acceptable trade-off (annotations are advisory prose, not load-bearing).
  - **Recommendation: (a).** Maintainer confirms at BD-106 land-time.

---

## §7. Cross-impact

### §7.1 V3.3 design element → BD/extension/doc mapping

| V3.3 element | Addressed by |
|---|---|
| §1 supersession (Path 3 / `--fold-into` / L3-typology removed) | BD-106 (no `folded-into:` label registered); BD-107 (no third verb); BD-108 (no inline marker parser); BD-068 fixture removal (§2.5); §6.2 release-readiness grep checks |
| §2 D-21 entity placement (L1 = phase epic + TD/BD peers; L2 = phase task; L3 reserved) | BD-106 (L2 placement); BD-063 (form-family `phase-task-skeleton`); BD-069 (D-18 carrier matrix) |
| §2.6 pack BDs at L1 (V1 §5 line 859 supersession) | Documented in MIGRATION-v10-to-v11.md (BD-084 extension) and OPTIONAL-FEATURES.md (BD-098 extension); no code change at v11.0 (pack BDs are flat L1 entities by default) |
| §3 D-22 two-path promotion + direct close | BD-107 |
| §3.5 label family (two kinds: `derived-from:`, `promoted-to:`; drop `folded-into:`) | BD-106 (label registration); release-readiness grep |
| §4 forward / reverse / round-trip mechanics | BD-065 ext (§2.3); BD-067 ext (§2.4); BD-068 ext (§2.5) |
| §5 cross-entity dependency model | BD-108 |
| §5.3 v10 grammar additive extensions | BD-108 (METHODOLOGY § Part 4 line 263, § Part 7 lines 990-993) |
| §5.4 Procedure 1 gate-check extension | BD-108 (METHODOLOGY § Part 7 lines 1025-1029) |
| §5.5 cycle detection (K=10 default) | BD-108; MAINTAINER CHECK §6.Q |
| §5.6 A1 failure-mode UX | BD-070 (typed errors; existing); BD-108 (link-failure routing); release-readiness check |
| §6 templates and dependency fields | BD-063 ext (§2.1); BD-064 ext (§2.2); BD-069 ext (§2.6) |
| §7 PM Chat advisory and execution workflow | BD-107 (PM-CHAT.md §7.1 + §7.2) |
| §8 D-23 issue-tracking auditor agents | BD-109 (project-side); BD-110 (pack-side) |
| §8.1 role boundary (pack-reviewer vs auditor vs auditor-issue-tracking vs pack-auditor) | Documented in MIGRATION-v10-to-v11.md (BD-084 ext §2.11); OPTIONAL-FEATURES.md (BD-098 ext §2.14); PM-CHAT.md (BD-107 ext §5.4); PACK-CHAT.md (BD-110 ext §5.5) |
| §9.1 architecture-doc amendments | Out of plan scope (architect maintains those docs); plan references the live design as V3.3 |
| §9.2 existing-BD extensions | §2 of this addendum |
| §9.3 new sibling BDs | §1 of this addendum (BD-106..BD-110) |
| §9.4 validate-pack checks 25-28 | §3 of this addendum; landed via BD-082 ext (§2.10) |
| §9.5 METHODOLOGY updates | §4 of this addendum; landed via BD-107 + BD-108 |
| §9.6 other doc updates | §5 of this addendum |
| §9.7 trinity rule applicability | BD-109 (file-wise on per-CLI agent files; Check 28); BD-110 (file-wise per §6.M outcome); MAINTAINER CHECK §6.M |
| §10 cross-impact check (D-1..D-20 reopened? 3-level cap? bidirectionality? trinity? CLI parity? A1 UX?) | All reaffirmed by §1-§5 above; no new OQs; no design reopened |

### §7.2 Trinity-rule audit

- File-wise trinity engagement: BD-109 (3 per-CLI agent files + 3 per-CLI auditor.md parent files + 3 per-CLI audit-methodology skill files = 9 files in one commit at step 23a); BD-110 (3 per-CLI agent files in one commit at step 33d, per §6.M decision); BD-107 (HELP-FRAGMENT × 2 surfaces — same as existing BD-076 baseline).
- Content-wise trinity engagement (CLAUDE.md / AGENTS.md / GEMINI.md): NONE introduced by V3.3 at v11.0. The new agent invocations are documented in HELP-FRAGMENT, PM-CHAT.md, PACK-CHAT.md — none of which are trinity files. If the maintainer determines a one-line trinity reference is warranted (parallel to V3 D-20 "Pack commands"), it lands in TRIO across all three files in one commit. Recommendation: NO trinity edit at v11.0; the agent invocations are sufficiently surfaced via HELP-FRAGMENT.
- Validate-pack Check 28 enforces file-wise parity for `auditor-issue-tracking.md` automatically.

### §7.3 A1 failure-mode UX preservation

- Cross-entity link failures (BD-108): typed error per V1 §9 / D-7; verb name (`pack tracker doctor`); chat preserves in-memory edit; retry on auth refresh.
- Cycle-check refusal (BD-108): typed error `tracker-cycle-detected`; in-memory edit preserved; user can manually break the cycle and retry.
- Promotion target missing (BD-107): typed error `promote-target-not-found` (e.g., `pack td promote --to=phase-99` against non-existent phase 99); in-memory edit preserved; user can supply correct target.
- Phase-task parser failure on malformed `### Tasks` (BD-106): warning (per V3.2 §4.1 carry-forward), not error; migration continues; the malformed heading is surfaced in the migrator report for human review.
- Auditor agents (BD-109, BD-110): read-only; do not introduce write-failure surface.

### §7.4 Bidirectionality contract (V1 §6.0) audit

- BACKLOG `Blockers:` field grammar: every legal v10 form continues to parse (verified by BD-068 round-trip and BD-108 regression cases).
- Phase-task `Dependencies` bullet grammar: prior to v11.0 this was free-form prose; v11.0 codifies a parser-recognised subset. Free-text annotation after the matched ID prefix is preserved (regex captures only the ID; annotation passes through). Round-trip preserves the annotation text byte-for-byte (carried via the sidecar's `dependency_edges` field's optional `annotation` sub-field per MAINTAINER CHECK §6.R).

### §7.5 Pack-vs-PM-Chat workflow distinction (Addendum 2 §2)

- `pack-auditor` (BD-110) is **Pack-Chat-direct invocation** — pack-side artifact; maintainer invokes via `claude --agent pack-auditor` directly (per the maintainer's MEMORY rule "pack agents use `claude --agent pack-<name>` directly; agent-run.sh is for project agents only").
- `auditor-issue-tracking` (BD-109) is **PM-Chat-mediated invocation** — client-side artifact; PM Chat routes the invocation through the existing `auditor` parent fan-out (which uses `agent-run.sh claude --agent auditor`).
- The two new agents respect the existing routing distinction; no new routing rule introduced.

### §7.6 Dry-run / apply / resume (Addendum 1 §1.2 / BD-095) extension

- BD-106 forward migration extension: writes phase-task entities; subject to existing dry-run preview. No new destructive operation.
- BD-107 promotion verbs: `pack td promote --to=phase-N` and `--to=phase-N.M` are NOT migration verbs; they are interactive PM-Chat-driven verbs. Not subject to dry-run/apply/resume mode (orthogonal to migration). The verbs surface their planned writes via the user-confirmation prompt (§7.1) before executing.
- BD-108 link orchestrator: writes `blocked-by` links; subject to existing dry-run preview. Cycle-check refusal is non-destructive (the link is rejected before write).
- BD-109 / BD-110: read-only; not subject to dry-run/apply/resume.

### §7.7 General-use prose audit

All V3.3-introduced user-facing prose (METHODOLOGY updates, PM-CHAT.md additions, PACK-CHAT.md audit-cadence, MIGRATION extensions, OPTIONAL-FEATURES extensions, HELP-FRAGMENT additions, agent prompts) authored without OT-specific assumptions. The pack-auditor prompt (V3.3 §8.3) references "OT" implicitly via the maintainer's working context but the prompt body itself is general-purpose. Verified at the §6.2 release-readiness grep step (`grep -i "OT\|Optiquity"` returns zero hits in V3.3-introduced prose).

### §7.8 Unknowns / open risks

- **(R-Add4.1)** Existing per-CLI parity check shape (validate-pack at v11.0 baseline) — see MAINTAINER CHECK §6.O. Until BD-082 ships, the relationship between Check 28 and any existing generic check is unknown. Plan accommodates both outcomes.
- **(R-Add4.2)** Pack-side `audit-methodology` and `architecture-review` skill presence at pack root — see MAINTAINER CHECK §6.N. Depends on BD-074's actual skill set. Plan accommodates ship-here vs ship-at-BD-074.
- **(R-Add4.3)** Pack-side `pack-auditor` per-CLI replication choice — see MAINTAINER CHECK §6.M. Plan adopts per-CLI by default; maintainer can override.
- **(R-Add4.4)** Sidecar `dependency_edges` annotation preservation — see MAINTAINER CHECK §6.R. Plan recommends preserve; maintainer confirms.
- **(R-Add4.5)** `pm-startup` Step 8 periodic `auditor-issue-tracking` offer — V3.3 §8.2 says "documented but not load-bearing." If the periodic-offer mechanism conflicts with V3 §28.1.6 refusal-respecting behavior (e.g., the user repeatedly refuses), the offer must back off. Surfaced here; resolution is in BD-109 prompt content (the agent itself doesn't manage the periodic schedule; that lives in pm-startup).
- **No new design decisions invented.** All six MAINTAINER CHECK items are flagged with options framed as the planner's open questions.

---

**End of Addendum 4.** Total: 5 BDs added (BD-106 entity model; BD-107 promotion verbs; BD-108 cross-entity links; BD-109 project-side sub-agent; BD-110 pack-side auditor). Highest BD now BD-110. Base plan §3.3 gains 7 lettered insertions (9b, 9c, 9d, 23a, 23b, 24a, 33d). §6 gains 6 MAINTAINER CHECK items (§6.M, §6.N, §6.O, §6.P, §6.Q, §6.R). §7 gains 9 release-readiness checkboxes. validate-pack gains Checks 25/26/27/28. METHODOLOGY § Part 4 lines 257-264 + 263 and § Part 7 lines 990-993, 1025-1029, 1057-1064 receive textual updates. MERGE-STRATEGY.md, MIGRATION-v10-to-v11.md, OPTIONAL-FEATURES.md, HELP-FRAGMENT.md, HELP-FRAGMENT-PACK.md, PM-CHAT.md, PACK-CHAT.md receive prose extensions per §5.
