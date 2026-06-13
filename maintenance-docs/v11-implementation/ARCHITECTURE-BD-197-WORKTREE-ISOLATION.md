# ARCHITECTURE-BD-197 — Worktree isolation: opt-in, isolated, safe parallel agent execution (Claude-only; pack-self + project-template)

**Role:** pack-architect (fresh, unbiased). **Mode:** design-only (one doc written; everything else read-only).
**Repo:** optiquity-ai-agent-config-pack-v11-dev · **Branch:** v11-dev · **HEAD at design time:** `3e3159ee8b5e97bf8775ecf67a76867d28933a3e`.
**Date:** 2026-06-13.
**Inputs:** BD-197.md (incl. 2026-06-13 user-direction note), BD-217.md (OUT of scope), RESEARCH-BD-197-P1-WORKTREE-ISOLATION.md (P1), RESEARCH-BD-197-AGENT-PERMISSION-INVENTORY.md (inventory), CLAUDE.md `## Pack memory` (full), PACK-CHAT.md §12, PACK-AGENTS.md, commit-discipline/SKILL.md ×3, OPTIONAL-FEATURES.md (pack), and the Q-A/Q-B probes run in this session.
**Sealed pre-design discussion:** deliberately withheld — this design is independent (UNBIASED-DESIGN rule).

This document is a STRATEGY doc plus the P2 removal plan and the P3 implementation plan. It implements nothing. Line numbers in cited research drift; P2/P3 implementers re-audit.

---

## 0. Executive summary (the decisions)

1. **Chosen isolation model (both surfaces, Claude-only):** opt-in isolation governed by the documented cross-product `bgIsolation` × `baseRef`, with **in-place non-isolated sequential execution as the always-safe default** and graceful degradation that NEVER errors. We ship NO settings file at any scope; we DOCUMENT the two settings in the existing `OPTIONAL-FEATURES.md` Agent-Teams pattern (pack-side + client-side, separately authored).

2. **Chosen merge-back model:** **Option 4 (patch-file handoff via `/tmp`) as the primary RW merge-back primitive, layered on Option 2 (report-write-by-`/tmp`-path for ALL agents)**, with Option 1 (in-place, no isolation) as the degradation floor. `agents-never-commit` is **FULLY PRESERVED** — no relaxation, no committing agent class. RW agents run `git diff` (read-only) inside their worktree, Write the patch + IMPL-report to a `/tmp` handoff dir, and **Pack Chat** `git apply` + commits. Justified by the Q-A/Q-B probe results (below): isolated writes escape only via `/tmp`; the worktree path/branch is NOT reliably returned, so capture-before-return (Option 5) and throwaway-branch-commit (Option 3) are both rejected.

3. **Chosen RW/RO declaration model (per surface, declared TWICE):**
   - **Pack:** the per-agent file mandate header is authoritative; **PACK-AGENTS.md roster gains an explicit `Class` column (RW/RO)** as the human-readable per-surface SSOT index; a NEW `validate-pack.py` parity check binds {agent-file header} ↔ {roster Class cell}.
   - **Project:** the per-agent file mandate header is authoritative; **PM-CHAT.md `## Permission profiles` table is the human-readable per-surface SSOT**, and **`agent-run.sh READONLY_AGENTS` becomes a CI-checked projection of it** (set-equality validator). `repo-ops` is placed as a sub-label of RW ("Write-capable (script)"), not a third class.

4. **P2 (removal) is pack-side-only** — P1 confirmed ZERO prohibition shipped to clients. **P3 (additive) creates the client story net-new.** The two surfaces are designed separately throughout (separation-of-concerns rule).

5. **Folded git-permission hardening:** enumerate `git stash` / `git reset` / `git restore --staged` / `git checkout --` into the trinity `agents-never-commit` bullet (which today uses only a catch-all), propagated via PACK-CHAT §12. The commit-discipline skill ×3 and pack-coder ×3 already enumerate most of these; the gap is the trinity corpus line + rationale.

6. **commit-discipline skill ×3 redesign:** the skill currently HARD-ASSERTS the buggy auto-worktree model (`pwd` must end in a worktree path; HEAD must start with `worktree-agent-`). This is FALSE under the default in-place model and must become **mode-aware** (in-place vs isolated), not a hard precondition.

---

## 1. Empirical probe results (Q-A, Q-B) — the merge-back-decision drivers

### 1.1 Q-A — Write-escape (can an isolated agent Write to a parent-tree absolute path?)

**CONCLUSION: Write-escape is REGIME-DEPENDENT. In the NON-isolated regime, parent-tree absolute-path writes WORK (proven by this task). In the ISOLATED regime, parent-tree writes are REJECTED by the harness sandbox; `/tmp` (Additional working directories) is the only reliable cross-boundary write target.**

Evidence:
- This pack-architect session runs in the parent tree itself (`git rev-parse --abbrev-ref HEAD` = `v11-dev`, NOT `worktree-agent-*`), and its sole deliverable is a Write to the parent-tree absolute path `maintenance-docs/v11-implementation/ARCHITECTURE-BD-197-WORKTREE-ISOLATION.md`. The Write succeeded (this file). ⇒ non-isolated parent-tree write WORKS.
- The commit-discipline skill §2 (`/Users/.../.claude/skills/commit-discipline/SKILL.md`, lines 44–62) documents the ISOLATED-regime behavior verbatim: *"Writing to … the main checkout is FORBIDDEN … If a `Write` returns 'permission denied' or 'file outside workspace,' the path is wrong."* and *"The 'Additional working directories' note in the harness environment (e.g., `/tmp/...`, `/private/tmp/...`) lists paths the agent may also write to for scratch work."*
- A read-only A/B test of the isolated regime is NOT possible without a git-mutating spawn (creating a worktree), which the read-only mandate forbids. The conclusion therefore rests on the documented harness behavior, not a fresh in-isolation write attempt — flagged honestly.

**Design implication:** the IMPL-report-back and patch-handoff for ISOLATED RW agents MUST target `/tmp` (a per-spawn handoff dir Pack Chat names in the prompt and reads after return), NOT a parent-tree path. In the NON-isolated regime, agents write reports to the parent tree as today.

### 1.2 Q-B — Worktree-path/branch return (does the Agent tool return the worktree path/branch before auto-removal?)

**CONCLUSION: NO reliable structured return of the `worktree-agent-*` path/branch to the caller; the worktree+branch auto-remove on clean return, and capture-before-return RACES that removal. Capture-before-return is NOT a dependable primitive.**

Evidence:
- P1 §1.5 (RESEARCH-BD-197-P1, lines 57–73): clean exit auto-removes worktree + branch; dirty exit prompts (interactive, not a structured return value to a sub-agent caller). Open bug #38287 "Worktree cleanup silently deletes branches with unmerged commits" ⇒ commits become dangling, recoverable only via `git fsck`. #55435 leftover `.claude/worktrees/agent-*` not pruned. #51596 stale-branch reuse on agentId-prefix collision.
- `git worktree list` in this session shows only the two real checkouts (`…/optiquity-ai-agent-config-pack` [main], `…-v11-dev` [v11-dev]) and NO `worktree-agent-*` entries, and `.git/worktrees/` is absent — consistent with the non-isolated spawn model (the agent is in-place; there is no isolated worktree to return a path for).
- The Agent tool's documented return is the agent's textual report, not a structured `{worktree_path, branch}` tuple the parent can rely on for a git operation.

**Design implication:** Option 5 (capture-before-return) and Option 3 (throwaway-branch-commit-then-merge) both depend on a reliable surviving branch/path. With Q-B negative + #38287 live, both are REJECTED. The patch artifact (Option 4) must be the persisted handoff — it survives auto-removal because it lives in `/tmp`, outside the worktree that gets removed.

### 1.3 Joint conclusion → mechanism selection

| Option | Needs Q-A=parent-write? | Needs Q-B=path-returned? | `agents-never-commit`? | Verdict |
|---|---|---|---|---|
| 1 — in-place, no isolation | n/a (writes to parent tree, non-isolated) | no | PRESERVED | **KEEP as degradation floor / default** |
| 2 — report-write-by-path (all agents) | `/tmp` suffices | no | PRESERVED | **ADOPT (via `/tmp` handoff for isolated; parent-tree for in-place)** |
| 3 — RW class commits to throwaway branch | no | YES (branch must survive) | RELAXED | **REJECT** (Q-B negative; relaxation off the table per user) |
| 4 — patch-file handoff (`git diff` → parent `git apply`) | `/tmp` suffices | no | PRESERVED | **ADOPT as primary RW merge-back** |
| 5 — capture-before-return | no | YES | PRESERVED | **REJECT** (Q-B negative; races #38287) |

Selected: **1 (floor) + 2 (reports, all agents) + 4 (RW code merge-back)** — the only combination that preserves `agents-never-commit`, survives the auto-removal bug, and needs neither relaxation nor a returned branch. Property-fit, not precedent: chosen because each unverified dependency (parent-write, returned-branch) is removed from the critical path, not because patches are a familiar idiom.

---

## 2. The chosen isolation + merge-back model (both surfaces)

### 2.1 The opt-in isolation mechanism (documented, never shipped)

Isolation in Claude Code is the **cross-product of two settings** (P1 §1.4/§1.5), both DOCUMENTED in `OPTIONAL-FEATURES.md`, NEITHER shipped/auto-written:

- **`worktree.bgIsolation`** (Claude Code v2.1.143+) — does background/subagent execution isolate at all? `"none"` = edit the working copy directly (no worktree). This is the explicit "stay in-place" lever.
- **`worktree.baseRef`** — when isolation DOES happen, from where does the worktree branch? `"fresh"` (default) = `origin/<default-branch>` (the historic bug surface — wrong baseline for a feature branch); `"head"` = local HEAD (correct for v11-dev-style work). Version-sensitive/buggy (#60588) ⇒ documented as "best-effort," not "guaranteed."

**Three documented developer postures** (the OPTIONAL-FEATURES walkthrough presents exactly these):
1. **Default / unset** → in-place sequential agents (Option 1). Zero failures. No setting required. This is what the pack assumes.
2. **Force in-place** → set `worktree.bgIsolation:"none"` — the safety hedge if a future Claude Code default flips background subagents to isolate. Documented so the developer can pin the pack's assumption.
3. **Opt into isolated parallel** → set `worktree.baseRef:"head"` (and ensure `bgIsolation` is not `"none"`). The pack then uses the patch-handoff merge-back (§2.3). Advanced/opt-in; the developer accepts the platform's bug surface knowingly.

### 2.2 Graceful degradation (REQUIRED — zero failures in every posture)

The pack MUST run cleanly with no setting, with Agent Teams ON or OFF, and on each posture above. The degradation contract:

- **The agent NEVER assumes it is isolated.** Every agent's first-step preflight DETECTS its regime (is `pwd` a `worktree-agent-*` worktree? is HEAD a `worktree-agent-*` branch?) and BRANCHES its report/merge-back path accordingly — it never HARD-FAILS on "not in a worktree" (the current skill bug) and never hard-fails on "in a worktree."
- **Pack Chat NEVER assumes isolation succeeded.** The merge-back path is keyed off what the agent actually reports (a `/tmp` patch path if isolated; in-place working-tree edits if not). If the platform silently fell back to in-place (#39886 "isolation silently fails, agent runs in MAIN repo"), Pack Chat finds the edits in the working tree — still safe.
- **"No destructive surprises":** because the persisted artifact (patch in `/tmp` OR in-place working-tree edits) is read by Pack Chat regardless of whether the worktree was auto-removed, the silent-delete bug class (#38287/#55435/#51596) cannot lose work — the work was never solely inside the removable worktree. This is the structural defense the user's "no destructive surprises" requires.
- **Agent Teams interaction:** documented as orthogonal — TEAMS-on may isolate teammates per the docs; the same patch-handoff/in-place-detection applies; TEAMS-off uses the Agent tool path. Neither requires a settings file from the pack.

### 2.3 The RW-agent edit → patch → Pack-Chat-apply flow (preserves `agents-never-commit`)

This is the merge-back primitive. It is IDENTICAL in shape on both surfaces; only the orchestrator name differs (Pack Chat pack-side; PM Chat project-side).

```
1. Orchestrator (Pack/PM Chat) spawns an RW agent (coder), naming in the prompt:
     - the scope (files the agent may edit)
     - a per-spawn HANDOFF DIR: an absolute /tmp path, e.g. /tmp/pack-handoff-<bd>-<ts>/
     - the IMPL-report path: <handoff>/IMPL-REPORT.md
     - the patch path:       <handoff>/changes.patch
2. The RW agent (whether isolated or in-place) does its edits, runs in-scope
   verification, then — using ONLY read-only git — emits the patch:
        git diff > <handoff>/changes.patch          # git diff is read-only
   and Writes IMPL-REPORT.md to <handoff>/.
   The agent runs NO state-changing git verb. (In-place regime: it MAY instead
   leave edits in the working tree AND still emit the diff for auditability;
   the patch is the canonical handoff.)
3. The agent returns. Its worktree (if any) may auto-remove — irrelevant: the
   patch + report live in /tmp, outside it.
4. Orchestrator reads <handoff>/IMPL-REPORT.md, runs the bounded review/fix
   cycle (reviewer reads the patch + report), then APPLIES:
        git apply --check <handoff>/changes.patch    # dry-run first
        git apply <handoff>/changes.patch            # orchestrator-only
   and commits with user approval. The ORCHESTRATOR does the only git-state
   change — agents never commit, never stage, never apply.
5. Conflict path: §2.5.
```

Why this preserves the rule absolutely: `git diff` and `Write` are read-only / non-git operations (commit-discipline §3 allowed list). The agent performs ZERO git-state changes. Only the orchestrator (which has always been permitted to commit) applies + commits. There is NO committing agent class — Option 3 is not adopted.

### 2.4 The all-agents IMPL-report-back flow (RW and RO)

ALL agents (RW coder AND every RO agent) Write their IMPL/report to the per-spawn handoff path the orchestrator names:
- **In-place regime (default):** the report path is a parent-tree absolute path (today's behavior — e.g., `maintenance-docs/...` or the project report dir). Works per Q-A.
- **Isolated regime (opt-in):** the report path is `<handoff>/...` under `/tmp` (Q-A: only `/tmp` escapes). The orchestrator copies/reads it from `/tmp` after return.

The orchestrator's prompt-construction rule becomes: **always name an absolute report path; when isolation is opted-in, that path is under the `/tmp` handoff dir.** This is one prompt-template change, regime-parameterized, on each surface.

### 2.5 The Pack-Chat-mediated conflict/merge protocol

Conflicts arise when (a) two parallel RW agents' patches touch the same hunks, or (b) a patch was cut against a base the main tree has since moved past. Protocol (orchestrator-run; agents never resolve):

1. **Order + dry-run.** Apply patches sequentially (never concurrently). For each: `git apply --check <patch>` FIRST. A clean check ⇒ apply + (after review) commit.
2. **On `--check` failure (drift or collision):**
   a. **3-way attempt:** `git apply --3way <patch>` (uses blob context to auto-merge non-overlapping drift). If clean ⇒ proceed.
   b. **Still conflicting ⇒ STOP and surface to the user.** The orchestrator presents: which two patches collide, the conflicting hunks, and a recommendation (re-spawn the LATER agent fresh against current HEAD with the same scope — a fresh coder per the fresh-agent-default rule — to regenerate a clean patch). The orchestrator does NOT hand-merge conflicting hunks itself (that is a fix, and Pack Chat does no fixes; the re-spawned coder regenerates).
3. **Anti-drift hygiene:** parallel RW agents SHOULD be scoped to disjoint file sets by the orchestrator's prompt (the existing file-ownership-boundary discipline, PACK-CHAT "Chat-ownership boundaries"). Disjoint scoping makes (a)-class collisions structurally rare; (b)-class drift is handled by `--3way` + re-spawn. This caps the conflict-resolution authority at the orchestrator + user, never the agent.

### 2.6 Why isolation is worth enabling at all (the user's goal)

The benefit the user wants is SAFE PARALLELISM: multiple RW agents editing disjoint scopes simultaneously without trampling each other's working tree. In-place parallelism (Option 1) risks same-tree collisions on concurrent writes; isolation gives each agent its own checkout. The patch-handoff brings the isolated edits back without relaxing the commit ban. The default stays in-place (safe, simple); isolation is the opt-in accelerator.

---

## 3. RW/RO two-class declaration design (per surface — declared TWICE)

The two-class model is declared independently on each surface. There is NO shared cross-surface file (separation-of-concerns rule; inventory §4.1).

### 3.1 PACK side

**Authoritative source:** each pack agent file's prose mandate header (`**Source-write within scope.**` for RW vs `**Read-only.**` for RO) — "the agent file is the thing the runtime loads."

**Human-readable per-surface SSOT (index):** **extend the `pack-ops/PACK-AGENTS.md` roster with an explicit `Class` column** (values `RW` / `RO`), replacing reliance on the prose-only `Mode` cell as the class signal. The roster already lists all 5 agents and agents already read PACK-AGENTS.md every session (Option PA from inventory §4.2). The roster gains a short "## Two agent classes" subsection under `## Agent permission rules` stating:
- **RW (read-write):** `pack-coder` — Write/Edit source within the caller-scoped file set; emits a patch + report; NEVER runs a state-changing git verb.
- **RO (read-only):** `pack-architect`, `pack-planner`, `pack-reviewer`, `pack-docs-researcher` — Write ONLY their single caller-specified report; read-only on the codebase otherwise.
- BOTH classes: `agents-never-commit` + full destructive-verb ban applies identically.

**Why NOT trinity `## Pack memory` (Option PC):** trinity carries UNIVERSAL rules; a per-agent roster is not universal and would duplicate the PACK-AGENTS roster (anti-restate). The class-PRINCIPLE (two classes exist; both obey the verb ban) belongs in trinity as a one-liner; the class-ASSIGNMENT (which agent is which) belongs in the PACK-AGENTS roster. This split respects anti-restate.

**New CI guard (measure-then-bound, §6):** a `validate-pack.py` check asserting set-equality between {PACK-AGENTS roster `Class` cells} and {agent-file mandate headers}, so the two never drift.

### 3.2 PROJECT side

**Authoritative source:** each project agent file's mandate header (`**Write-capable (scoped).**` / `**Read-only.**`) — already the stated model (PM-CHAT 406–409 "the agent file is authoritative").

**Human-readable per-surface SSOT:** **PM-CHAT.md `## Permission profiles` table** (the 14 RO + `coder` + `repo-ops` table, inventory C4). It already exists and is already labelled authoritative-reinforcement. Keep it as the authored list.

**Runtime projection:** **`agent-run.sh READONLY_AGENTS` becomes a CI-checked PROJECTION of the PM-CHAT table** (Option CA) — a `validate-pack.py` set-equality check binds {PM-CHAT RO rows} ↔ {`READONLY_AGENTS` array} ↔ {per-file RO headers}. Today they agree by hand (inventory §1.2) but nothing enforces it.

**`repo-ops` placement:** it is RW, with a sub-label "Write-capable (script)" (scripted/generated edits only, no hand-written source). It is NOT a third class — the two-class model is RW/RO; `repo-ops` is an RW agent whose scope is narrowed by its own agent-file Hard rules. This avoids inventing a "scripted-write" class that would complicate both the table and the validator.

**Stale-comment fix (inventory §3.1, agent-run.sh lines ~92–94):** the comment "Edit/Write tools are excluded at the agent-definition level" is FALSE for the project side (BD-127 kept Write for reports). P3 corrects it to describe launch-time flag enforcement instead.

### 3.3 Surfacing the two classes in agent prompts

The orchestrator's rules-in-force block already enumerates agent rules inline. P3 adds: every RW-agent spawn names the handoff dir + patch path; every RO-agent spawn names the report path. The class drives which prompt template the orchestrator uses.

---

## 4. P2 — Removal plan (pack-side only; client side carries NO prohibition)

**Scope:** REMOVE the prohibition + all bug-era worktree content from pack-side surfaces. P1 §4.6 confirmed ZERO prohibition in `AGENTS.md`/`GEMINI.md` (root), in any `project-template/` trinity, or any client surface — so P2 is pack-only. P3 is where the client story is built net-new.

**Fresh-audit instruction (mandatory before any edit):** the P2 coder re-runs the blast-radius audit at P2-time HEAD with `rg --hidden --no-ignore` across the v11-dev tree AND the main clone, excluding `.git`/`test-fixtures`/`BD-197.md`/the PREWORK file. Line numbers in the table below WILL have drifted — re-locate by content, not line. The audit must reconcile counts ≥2 ways (per the measure-then-bound + researcher-blast-radius rules) and resolve the dangling-ref count discrepancy (entry says 4; P1 measured 3 active / 7 total).

### 4.1 Disposition table — 13 PRIMARY rule carriers (from P1 §4.3)

| # | File | Disposition | Notes |
|---|---|---|---|
| 1 | `CLAUDE.md` (root) `### Sub-agent behavior (Claude-only)` worktree bullet | **REPLACE** the prohibition with the new opt-in model one-liner (pointer to OPTIONAL-FEATURES) | PM-chat/trinity-governed; PACK-CHAT §12. Trinity ×3 (CLAUDE/AGENTS/GEMINI) in lockstep — but note this bullet is in the Claude-only sub-section + carries a trinity-exemption; preserve the exemption framing for BD-217 to adapt. |
| 2 | `.claude/skills/commit-discipline/SKILL.md` | **REDESIGN** (mode-aware; §5) | The single highest-coupling edit. |
| 3 | `.codex/skills/commit-discipline/SKILL.md` | **REDESIGN** (mirror of #2) | quad/trinity mirror. |
| 4 | `.gemini/skills/commit-discipline/SKILL.md` | **REDESIGN** (mirror of #2) | quad/trinity mirror. |
| 5 | `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` | **UPDATE** the "no worktree isolation" rule digest to the new model | |
| 6 | `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md` §D | **UPDATE** to the enabled model OR annotate as superseded | plan doc; architect-at-P2 decides update-vs-annotate. |
| 7 | `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §4.8 + reproductions | **UPDATE/ANNOTATE** | plan doc. |
| 8 | `maintenance-docs/v11-implementation/PLAN-DOC-CONCISION-GUARDRAILS.md` coder-spawn fragment | **UPDATE** "NO worktree isolation" fragment | |
| 9 | `maintenance-docs/v11-implementation/ARCHITECTURE-BD-196-S1-CORPUS-CLASSIFICATION.md` row #24 | **UPDATE** — excise the stale `L348-357` line-range citation; reflect the rule change | entry calls out the stale line-range explicitly. |
| 10 | `maintenance-docs/v11-research/RESEARCH-CLAUDE-REPOS-SURVEY.md` | **UPDATE** stale caveat + **EXCISE** 2× dangling-ref | DANGLING-REF + UPDATE. |
| 11 | `maintenance-docs/v11-implementation/IMPL-REPORT-BD-214-C5a-BD197.md` | **DISPOSITION** (history — leave) | do not rewrite history. |
| 12 | `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-196-C9.md` | **DISPOSITION** (history — leave) | |
| 13 | `maintenance-docs/v11-implementation/PLAN-DEPLOYMENT-PYTHON-OBSERVABILITY.md` | **VERIFY at P2** then UPDATE/leave | confirm it's a real worktree-prohibition mention vs incidental `baseRef` token. |

### 4.2 ~7 OPERATIONAL-coupling mentions (P1 §4.4) — reconcile WITH the chosen model

These describe the bug-era auto-worktree pre-flight and become FALSE/incomplete under the chosen default-in-place + opt-in-isolated model:
- `.claude/.codex/.gemini/skills/implementation-report/SKILL.md` (×3) — "the worktree is lost," "diff against the worktree base," "SHA unchanged from the worktree base." → **REDESIGN mode-aware:** in-place ⇒ diff against parent base; isolated ⇒ the patch is the persisted artifact in `/tmp`.
- `.claude/.codex/.gemini/agents/pack-coder.{md,toml}` (×3) — "makes the file changes in its worktree," "Branch + final HEAD SHA on your worktree." → **UPDATE** to "in its scoped working tree (or isolated worktree when opted-in); emits a patch + report."
- `pack-ops/PACK-CHAT.md` line ~116 "multiple worktrees on the same clone" — **LEAVE** (concurrent-session ownership rule; benign, still true).

### 4.3 Dangling-ref reconciliation (entry "4"; P1 measured 3 active / 7 total)

- **Active (non-archive) 3 files** — `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md`, `RESEARCH-19C-G-ITEMS-VERIFICATIONS.md`, `RESEARCH-CLAUDE-REPOS-SURVEY.md`: **EXCISE/repoint** the dangling `feedback_worktree_isolation_broken_from_v11_clone` ref.
- **Archive 4 files** (`archive/v11/...`): **DISPOSITION (leave as history)** per the fail-loud "delete superseded docs / don't rewrite history" balance — archive is frozen history; a dangling ref inside frozen history is acceptable. The P2 audit confirms whether the architect-at-P2 wants delete-vs-leave per the fail-loud memory; default LEAVE (archive is not an active surface).
- The entry's "4" is not authoritative; **the fresh P2 audit's reconciled count wins** and the entry is updated to match (a pack-chat-only bookkeeping edit).

### 4.4 4 historical decision-records — DISPOSITION per audit (leave as history; do not rewrite).

### 4.5 P2 completeness gate (measure-then-bound)
P2 coder PREFLIGHT + reviewer both assert a **grep-ZERO completeness gate**: after edits, `rg --hidden --no-ignore 'no worktree isolation|isolation: *"worktree"|worktree-agent-|baseRef'` returns ONLY (a) the new enabled-model text, (b) OPTIONAL-FEATURES doc, (c) BD-197/BD-217/this-doc/research/PREWORK, (d) archive (frozen) — a documented allowlist. Any other hit ⇒ incomplete. This is the rename-plans-are-measure-then-bound contract applied to a removal.

---

## 5. P3 — Implementation plan (rules + mechanism + docs; pack AND client)

P3 builds the enabled model. It is additive on the client side (net-new). Pipeline: planner → coder → bounded review/fix per commit.

### 5.1 Rules (trinity `## Pack memory`) — via PACK-CHAT §12 propagation

**(a) Replace the prohibition bullet** (`### Sub-agent behavior (Claude-only)`) with an ENABLE bullet: "Sub-agents run in-place by default (no isolation); a developer MAY opt into isolated parallel execution by setting `worktree.baseRef:"head"` (and not forcing `bgIsolation:"none"`) — see OPTIONAL-FEATURES. When isolation is active, RW agents emit a patch to the named `/tmp` handoff dir and Pack Chat applies it; agents never commit. Trinity-exempt (Claude-only; Codex/Gemini = BD-217)." Propagate ×3 trinity + rationale slug.

**(b) Two-class principle one-liner** in trinity (the PRINCIPLE only; assignment lives in PACK-AGENTS roster). New rationale slug, e.g. `agent-two-class-model`.

**(c) Folded git-permission hardening** — amend the `agents-never-commit` bullet to ENUMERATE `git stash`, `git reset`, `git restore --staged`, `git checkout --` alongside the existing catch-all "or any other state-changing git verb." Propagate via §12 ordered surfaces:
   1. corpus ×3 trinity (`agents-never-commit` bullet) — add the enumeration.
   2. `PACK-MEMORY-RATIONALE.md` `## agents-never-commit` — update the verb list.
   3. cache pointer (Pack-Chat upkeep).
   4. references: `PACK-AGENTS.md § Agent permission rules` (one-line, already points to trinity — verify still accurate).
   5. `.spawn-rule-manifest.txt` — verify slug→canonical still resolves.
   6. `test-fixtures/manifest.txt` regen (v11-surface touched).
   Project-side: the project trinity `## Project memory` "No destructive operations" rule + the 48 agent files' Hard rules + Codex `## Permission profile` blocks already mostly enumerate reset/stash (inventory §3.2/C8); P3 closes any gap surface-by-surface (enumerate-encoding-surfaces).

### 5.2 Mechanism (the patch-handoff merge-back) — codified WHERE

- **Pack-side:** the merge-back flow (§2.3) is codified in `pack-ops/PACK-CHAT.md` (orchestrator procedure: name handoff dir, read patch, `git apply --check`/`--3way`, conflict protocol) + the `implementation-report` skill ×3 (the agent's "emit patch + report to handoff dir" step) + `pack-coder` ×3 (the RW-emit step). The commit-discipline skill ×3 redesign (§5.4) carries the mode-aware preflight.
- **Project-side (net-new):** the same flow is authored INDEPENDENTLY into `project-template/docs/pack/PM-CHAT.md` (PM-Chat orchestrator procedure) + `project-template/.{claude,codex,gemini}/agents/coder.*` (the RW-emit step) + `project-template/skills/implementation-report/SKILL.md` (+ quad mirrors). NOT a byte-copy of the pack text — audience-correct per cross-CLI-reference-normalization (the project orchestrator is "PM Chat," paths/commands are project-side canonical).

### 5.3 Docs — OPTIONAL-FEATURES additive homes (pack + client, separately authored)

- **Pack:** new section in `pack-ops/OPTIONAL-FEATURES.md` — "## Claude Code — Isolated parallel agents (worktree isolation)" modeled on the Agent-Teams section shape (Status / What it is / When it matters / How to enable [`baseRef:"head"`, optionally `bgIsolation`] / How to use with the pack [the patch-handoff is automatic; you only set the setting] / Caveats [version-sensitive #60588, silent-delete #38287, best-effort] / When to skip). Explicitly: "the pack ships NO settings file; you add these keys to your own `~/.claude/settings.json`." Trinity-exempt note (Claude-only; Codex/Gemini = BD-217).
- **Client:** the SAME section authored INDEPENDENTLY into `project-template/docs/pack/OPTIONAL-FEATURES.md` — client audience (the developer of a downstream project), client paths/orchestrator. Separate artifact; not a fallback for the pack version.

### 5.4 commit-discipline skill ×3 redesign (mode-aware)

The skill currently HARD-ASSERTS the isolated model (a bug-era artifact). Redesign:
- **§1 pre-flight:** make it **regime-detecting, not regime-asserting**. Replace "`pwd` Must end in worktree path" + "HEAD Must start with `worktree-agent-`" with: "Detect your regime: if `pwd`/HEAD indicate a `worktree-agent-*` worktree you are ISOLATED; otherwise you are IN-PLACE. Neither is an error. Branch your write-target + handoff behavior on the regime (§2)."
- **§2 write-target rule:** make it **regime-aware**. In-place ⇒ Writes go under the parent tree (today's allowed deliverable). Isolated ⇒ Writes go under `pwd` (the worktree) for code, and the IMPL-report + patch go to the named `/tmp` handoff dir (the ONLY escape, per Q-A). Keep the absolute prohibition on retargeting another agent's main checkout. The BD-119 C-2 anti-pattern stays as a cautionary note but is no longer a blanket "every write under pwd."
- **§3 git-state-change ban:** UNCHANGED in spirit; ensure the enumeration includes the folded verbs (`git stash`/`reset`/`restore --staged`/`checkout --`) — already present in the skill (lines 74–80), so verify-and-keep; add `git restore --staged` precision if absent.
- **§6 anti-patterns:** retire the "wrote report to /tmp because the worktree write rejected once → wrong path" anti-pattern (it is NOW the correct isolated behavior) and replace with the regime-aware guidance.

### 5.5 Graceful degradation (verified, not assumed)
P3 acceptance includes a verification matrix: (no setting), (`bgIsolation:"none"`), (`baseRef:"head"`), (TEAMS on), (TEAMS off) — each must run a pack agent spawn → report-back with zero failures. Codex/Gemini explicitly out (BD-217); their CLIs degrade to native sequential — the trinity-exemption note documents this without claiming parity.

### 5.6 New CI guards (P3) — measure-then-bound applied (see §6).

---

## 6. New validators / CI guards — measure-then-bound contract

Each new guard follows: (1) measure the tree first; (2) categorize every occurrence KEEP/STRIP; (3) fix-recipe per STRIP; (4) size the allowlist to KEEP only; (5) verify clean post-fix. The P3 coder MUST execute steps 1–2 against the real tree before authoring the guard — this design specifies the guard's CONTRACT, not its allowlist contents (which require a measured tree at P3-time).

### 6.1 Guard A — prohibition-stays-removed (flip-block)
- **Asserts:** the worktree-isolation PROHIBITION text does not reappear in active pack surfaces.
- **Measure-then-bound:** match the prohibition signature (`no worktree isolation`, `Do not pass .*isolation.*worktree`); the KEEP allowlist = {OPTIONAL-FEATURES new section, BD-197/BD-217/this-doc, research, PREWORK, archive}. STRIP = anything else (should be empty post-P2). Sized to KEEP only.
- **Runtime guard:** scope to the active tree (exclude archive/test-fixtures), no subprocess-per-entry, single whole-tree `rg` (per the CI-runtime-compounding memory).

### 6.2 Guard B — RW/RO declaration consistency (×2, one per surface)
- **Pack:** set-equality {PACK-AGENTS roster `Class` cells} ↔ {agent-file mandate headers (RW/RO)}. Measure: 5 agents; KEEP = the measured 1-RW/4-RO assignment; any mismatch FAILS.
- **Project:** set-equality {PM-CHAT RO rows} ↔ {`agent-run.sh READONLY_AGENTS`} ↔ {per-file RO headers}. Measure: 14 RO + 2 RW; any drift FAILS.
- **Runtime:** single-pass file reads, no per-agent subprocess storm.

### 6.3 Guard C (optional, P3 architect call) — verb-enumeration parity
- Asserts the folded verb set (`stash`/`reset`/`restore --staged`/`checkout --`) appears in every surface that enumerates the ban (trinity, commit-discipline ×3, pack-coder ×3, project Hard rules). This is an enumerate-encoding-surfaces hedge; may be folded into existing trinity-parity + bijection checks rather than a new check (prefer fewer checks — design-elegance).

---

## 7. Decisions to surface to the user (with recommendations + evidence)

**D1 — Pack-side RW/RO SSOT home.** RECOMMEND: PACK-AGENTS roster `Class` column + a two-class subsection (Option PA), authoritative source = agent-file header, bound by a new parity check. *Evidence:* agents already read PACK-AGENTS every session (PACK-AGENTS §"Agent behavior expectations" step 1); trinity (Option PC) would duplicate the roster (anti-restate); per-file-only (Option PB) has no human-readable index. *Alternative:* PB if the user wants zero new roster columns.

**D2 — Project-side RW/RO SSOT home + runtime projection.** RECOMMEND: PM-CHAT table as SSOT, `agent-run.sh READONLY_AGENTS` as a CI-checked projection (Option CA). *Evidence:* the four current forms agree only by hand (inventory §1.2) — a set-equality check removes the silent-drift risk that nothing guards today (inventory §4.3 Q3). *Alternative:* CC (drift-detect only, no re-homing) if the user wants minimal disruption.

**D3 — `git apply` 3-way + re-spawn as the conflict ceiling (no orchestrator hand-merge).** RECOMMEND: yes — orchestrator does `--check`/`--3way` then re-spawns a fresh coder on unresolved conflict; never hand-merges. *Evidence:* Pack Chat does no fixes (pack-memory); hand-merging conflicting hunks IS a fix. *This is the one place the model could feel heavy* — surfacing so the user can accept the re-spawn cost vs. an alternative (accept that parallel RW is rare and serialize on conflict).

**D4 — Archive dangling-refs: leave (don't rewrite history).** RECOMMEND: leave the 4 archive refs; excise only the 3 active. *Evidence:* fail-loud memory balances "delete superseded" against "don't rewrite frozen history"; archive is frozen. *User may override* to delete-archive per a stricter fail-loud reading.

**D5 — `agents-never-commit` is NOT relaxed (confirm).** RECOMMEND: confirm — Option 3 rejected; no committing agent class. *Evidence:* Q-B negative + #38287 make Option 3 both unnecessary and unsafe; the patch-handoff (Option 4) fully solves merge-back with the rule intact. No user sign-off for relaxation is requested because none is needed (the BD-197 hard-constraint's "last-resort exception" is NOT invoked).

**D6 — Document `bgIsolation:"none"` even though the pack prefers in-place.** RECOMMEND: yes — it is the safety hedge if a future Claude Code default isolates background subagents under the pack (#59580/#59848 risk). *Evidence:* P1 §3.4. Tension with "document only, never write" is resolved: we DOCUMENT the key, we never WRITE it.

---

## 8. Architect-doc-vs-reality reconciliation

- This design **realizes** the option space P1 §2 enumerated without deciding — it selects 1+2+4 and records the Q-A/Q-B probe results P1 §5 deferred to the architect. When P3 lands, the IMPL-REPORT should cross-reference this doc (the realized consumer) per the architect-doc-reality-reconciliation rule.
- This design **invalidates** the bug-era model encoded in `commit-discipline/SKILL.md` §1/§2/§6 and the operational mentions in `implementation-report`/`pack-coder` (P1 §4.4); §5.4 names the exact redesign so the reconciliation chain is explicit.
- BD-197 entry's stale "Codex/Gemini neither support isolation" framing is superseded by P1 §3.2/§3.3 and carved out to **BD-217** (out of scope here); this design keeps the trinity-exemption pattern clean so BD-217 can adapt the same patch-handoff model per-platform.

---

## 9. Rules-Applied Verification Block

| # | Rule (as named in prompt) | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | Agents never commit | Only read-only git verbs run this session: `git rev-parse HEAD` (`3e3159e…`), `git rev-parse --abbrev-ref HEAD` (`v11-dev`), `git worktree list`. No `add/commit/push/stash/reset/mv/rm/apply` issued. The design itself preserves the rule (§2.3: only the orchestrator applies+commits; Option 3 rejected, §1.3). | COMPLIANT |
| 2 | Read-only mandate (write ONLY the design doc) | Exactly one file written: `maintenance-docs/v11-implementation/ARCHITECTURE-BD-197-WORKTREE-ISOLATION.md` (the caller-specified path, confirmed absent pre-write). Probes were read-only: `pwd`, `git rev-parse`, `git worktree list`, `ls -ld`, `env|grep`. No git mutation; no `/tmp` file created (probes inspected dirs, did not write). | COMPLIANT |
| 3 | Empirical-Evidence Blocks (incl. probes) | §1.1/§1.2 carry command + verbatim output + HEAD `3e3159e` + date 2026-06-13 + conclusion for Q-A/Q-B; §4 dispositions cite P1 §4 measured counts; cross-CLI claims cite P1 §3 issue numbers. | COMPLIANT |
| 4 | Pattern-matching out of context is an anti-pattern | §1.3 selects 1+2+4 by PROPERTY-FIT (each removes an unverified Q-A/Q-B dependency from the critical path), explicitly "not because patches are a familiar idiom." Option 3/5 rejected on measured Q-B + #38287, not by reflex. | COMPLIANT |
| 5 | CI-guard measure-then-bound | §6 specifies the 5-step contract for Guards A/B/C and requires the P3 coder to MEASURE the tree before sizing the allowlist; §4.5 applies the grep-ZERO completeness gate to P2 removal. Allowlist contents deferred to measured P3-time tree (not pre-sized broad). | COMPLIANT |
| 6 | Pack/project separation + trinity parity + cross-CLI normalization + §12 propagation | §3.1 (pack) and §3.2 (project) designed as SEPARATE artifact sets; §5.3 authors OPTIONAL-FEATURES homes independently (not byte-copy); §5.1(c) routes the verb-hardening through PACK-CHAT §12 ordered surfaces; §5.2 invokes cross-CLI-reference-normalization for the project mechanism. | COMPLIANT |
| 7 | Architect-doc-vs-reality reconciliation | §8 names what this design realizes (P1 option space, Q-A/Q-B), invalidates (commit-discipline bug-era model — exact redesign in §5.4), and carves out (BD-217). | COMPLIANT |
| 8 | Unbiased-design (sealed discussion withheld) | Design derived only from BD-197/BD-217, P1 + inventory research, CLAUDE.md/PACK-CHAT/PACK-AGENTS/skill reads, the user's prescriptive constraints, and the Q-A/Q-B probes. The sealed discussion was neither sought nor referenced. | COMPLIANT |
| 9 | Rules-Applied Verification Block present | This table. | COMPLIANT |
| 10 | PREFLIGHT + STOP-MEANS-STOP | PREFLIGHT line emitted in chat immediately before this Write ("PREFLIGHT: design complete; Q-A/Q-B probed; about to Write …"). No parent stop received. | COMPLIANT |

---
*End of ARCHITECTURE-BD-197-WORKTREE-ISOLATION.md*
