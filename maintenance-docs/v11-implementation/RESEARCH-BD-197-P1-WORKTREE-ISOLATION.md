# RESEARCH-BD-197-P1 — Worktree-isolation: current behavior, persist/merge-back option space, cross-CLI + TEAMS degradation, removal blast-radius

**Phase:** BD-197 Phase 1 (P1) RESEARCH — read-only. **Author:** pack-docs-researcher (fresh, unbiased).
**Tree:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev` (branch `v11-dev`).
**HEAD at research time:** `f858d90ec0bd12492944aba457bebb0b91285081` (v11-dev); main clone HEAD `fa817044ffaa6cc019f4cb975a4242be15060676`.
**Date:** 2026-06-13.
**Mandate:** Research the option space + verify facts so a later unbiased architect can design. This document does NOT pick a mechanism. All MUST-RE-VERIFY factual items were re-verified against authoritative online sources on 2026-06-13 (the prior in-repo probes are dated 2026-05-31 / 2026-06-01 and are now PARTIALLY STALE — see §1).

---

## 0. Headline findings (read this first)

1. **The factual ground has shifted since the 2026-06-01 probes.** Claude Code's worktree-isolation surface has materially evolved. Three behaviors the BD-197 entry treats as settled are now stale or incomplete:
   - **`worktree.baseRef` now has documented named values `"fresh"` (default) and `"head"`** — not just an on/off `"head"` flag. Confirmed in the official docs.
   - **A NEW setting `worktree.bgIsolation` (added ~v2.1.143)** governs whether background sessions / subagents isolate at all; `"none"` makes them edit the working copy directly with NO worktree. This is a second, independent lever the entry does not mention.
   - **Merge-back / persist is now PARTIALLY a first-class product feature**: the official docs describe keep-vs-remove prompts on exit and an "agent view" where deleting a session removes its worktree (with an explicit "merge or push first" warning). Problems (A) and (B) as stated in the entry are no longer absolute — they are conditional on settings + session-naming + clean-vs-dirty state.

2. **The entry's cross-CLI claim is now WRONG and must be corrected by the architect.** The entry and `CLAUDE.md` assert Codex and Gemini "NEITHER supports this isolation feature." As of 2026-06-13: **Gemini CLI ships experimental Git Worktrees** (`--worktree`/`-w` flag + `settings.json` opt-in, GA-tracked through v0.36.0) and **Codex (app) supports a worktree mode** plus a documented subagent-in-worktree pattern. The graceful-degradation design can no longer assume "Claude-only." (Both still have open bugs where the subagent's cwd/git is not reliably locked to the worktree — so "exists" ≠ "safe-to-rely-on." Per the `verify-availability-not-just-existence` memory, the architect must treat these as EXISTS-BUT-IMMATURE, not as drop-in parity.)

3. **The pack's prohibition is narrowly contained.** The active-tree worktree-isolation RULE carriers are a small, enumerable set (13 active-tree files; see §4). The prohibition does NOT appear in `AGENTS.md`/`GEMINI.md` (root), nor in any `project-template/` trinity or client surface — confirmed ZERO. The rule is Claude-only and pack-side-only today; P3's client-side additive work is genuinely net-new, not a removal.

4. **`agents-never-commit` does NOT have to be relaxed** to solve persist + merge-back. At least three of the option-space candidates (§2) preserve it fully. The entry's "last-resort, user-sign-off-only" framing for relaxation is sound and unforced by the facts.

---

## 1. VERIFIED current Agent-tool worktree behavior (MUST-RE-VERIFY items)

### 1.1 Method
Re-verified on 2026-06-13 via WebSearch against `code.claude.com` (official docs) and `github.com/anthropics/claude-code` (issue tracker). In-repo prior-probe evidence read from `maintenance-docs/v11-implementation/RESEARCH-19C-G-ITEMS-VERIFICATIONS.md` (G-1) and the BD-197 entry's References line. The in-repo probes are cited as historical, not authoritative-for-today.

### 1.2 Does `isolation:"worktree"` still check out at `origin/HEAD` regardless of parent branch?

**CONCLUSION: YES, that remains the documented DEFAULT — but it is now explicitly configurable, and there are open bugs where even the `"head"` override is ignored.**

- Official docs (Run parallel sessions with worktrees — `https://code.claude.com/docs/en/worktrees`, retrieved 2026-06-13): *"Worktrees branch from your repository's default branch, `origin/HEAD`, so they start from a clean tree matching the remote. To always branch from local HEAD instead, set `worktree.baseRef` to `head` in settings."* Subagent worktrees use the same base branch as `--worktree`.
- `baseRef` now has NAMED VALUES (docs + issue #60588, retrieved 2026-06-13): `"fresh"` (default) = branch from `origin/<default-branch>`; `"head"` = branch from local HEAD (carries unpushed commits + feature-branch state). This is a refinement over the 2026-06-01 probe's understanding of a bare `"head"` flag.
- Open bug — `anthropics/claude-code#45371` "Agent tool isolation:\"worktree\" forks from default branch instead of caller's current HEAD" (retrieved 2026-06-13): confirms the default-branch fork is still observed/reported recently.
- Open bug — `#60588` "EnterWorktree ignores `worktree.baseRef:\"fresh\"` — still branches from local HEAD (v2.1.144)": shows the baseRef plumbing is itself buggy in BOTH directions as of a v2.1.144 report — i.e., the setting is not yet a reliable guarantee.
- Prior in-repo probe (historical): 2026-05-31 agent landed at `origin/main` `7ccbba9`; 2026-06-01 with `baseRef:"head"` at user-global scope the agent landed at parent HEAD `3178fa4` (BD-197 References line; RESEARCH-19C-G-ITEMS-VERIFICATIONS.md G-1).

### 1.3 Does `worktree.baseRef:"head"` change it, and at what scope?

**CONCLUSION: YES it is the intended override; SCOPE is settings-file level (user-global `~/.claude/settings.json` confirmed sufficient by the 2026-06-01 probe; project-level `.claude/settings.json` also accepts it). It is NOT a per-agent / per-spawn parameter.** Caveat: #60588 shows the override is not 100% reliable on all versions — the architect must treat it as "best-effort, version-sensitive," not "guaranteed."

- Docs: set in "settings" (the docs page does not scope-restrict it; the settings reference treats `worktree.*` as ordinary settings keys, valid at user/project scope).
- In-repo probe (historical): user-global suffices (BD-197 References; the 2026-06-01 probe tried project-level then user-global).

### 1.4 NEW lever not in the entry: `worktree.bgIsolation`

**CONCLUSION: A second, independent setting exists that the entry/architect MUST account for.** `worktree.bgIsolation` (requires Claude Code v2.1.143+) controls whether background sessions AND subagent isolation happen at all. `"none"` = background sessions/subagents edit the working copy directly, no worktree created.

- Issue #59580 "[DOCS] `worktree.bgIsolation` setting missing from settings docs and agent-view still describes worktree isolation as unconditional" (retrieved 2026-06-13).
- Issue #62372 "`bgIsolation` guard recovery path is broken: error tells agents to call `EnterWorktree`, which is a deferred tool" — shows the feature is new and rough.
- Issue #59848 — interactive sessions misclassified as background post-2.1.139, firing bg-only guards on foreground work — a degradation-safety risk surface.
- **Design implication:** isolation is now governed by the CROSS PRODUCT of `bgIsolation` (isolate at all?) × `baseRef` (from where?). "No worktree isolation" can now be achieved by `bgIsolation:"none"` WITHOUT the per-spawn `isolation` parameter — directly relevant to the entry's "ship/auto-write NO settings file" constraint and to graceful degradation.

### 1.5 Are isolated worktrees + their `worktree-agent-*` branches auto-removed on return?

**CONCLUSION: CONDITIONAL — not unconditional auto-removal as the entry's Problem (A)/(B) imply.** Current documented behavior:
- **Clean exit** (no uncommitted changes, no untracked files, no new commits): worktree + branch auto-removed. If the session is NAMED, Claude prompts instead (keep-for-later).
- **Dirty exit** (uncommitted changes / untracked files / new commits): Claude PROMPTS keep-or-remove; KEEP preserves the directory and branch.
- **Agent view**: deleting a session removes its worktree "including any uncommitted changes, so merge or push the changes you want to keep first."
- Source: official worktrees docs (retrieved 2026-06-13).

**But silent data loss is still a live bug class:**
- Issue #38287 "Worktree cleanup silently deletes branches with unmerged commits" — commits become dangling, recoverable only via `git fsck`.
- Issue #51596 — stale-branch reuse on agentId-prefix collision (silent wrong-baseline).
- Issue #55435 — `.claude/worktrees/agent-*` not pruned on session/branch end (leftover accumulation).
- Issue #57767 — leftover visibility + Windows lock recovery.
- Issue #55708 — subagent's `git checkout` affects the PARENT repo's branch (isolation leak).
- Issue #39886 — `isolation:"worktree"` silently fails, agent runs in MAIN repo instead.

**Net:** Problems (A) work-not-persisted and (B) no-clean-merge-back are NO LONGER the absolute blockers the entry describes. They are now: (A') persist EXISTS via session-naming + keep-on-dirty-exit + agent-view, but is fragile (silent-delete bugs); (B') merge-back EXISTS as a manual "merge or push before deleting the session" workflow, but there is no automated, audited merge-back primitive and the auto-delete-with-unmerged-commits bug (#38287) is exactly the dangling-commit failure the entry's (B) names. The architect should re-state (A)/(B) as "fragile/unaudited" rather than "impossible."

---

## 2. Option space for persist + merge-back (problems A + B) — NO DECISION

Each option is presented with how it stands against `agents-never-commit` (CLAUDE.md `## Pack memory` → "Agents never commit"; challenged-not-relaxed per BD-197 hard constraint), against the "ship/auto-write NO settings file" constraint, and against graceful degradation. The architect picks; the user signs off on any `agents-never-commit` relaxation.

### Option 1 — Pack-Chat-mediated capture, no isolation (status quo mechanism, re-affirmed)
- **Shape:** Keep `bgIsolation:"none"` (or no isolation) → agents edit the parent working tree in place; Pack Chat reads the working-tree diff + the IMPL-REPORT and commits. This is exactly today's "no worktree isolation" model, now achievable via the documented `bgIsolation:"none"` setting rather than a per-spawn rule.
- **Persist (A):** SOLVED trivially — edits are already in the parent tree.
- **Merge-back (B):** SOLVED trivially — no separate branch to merge.
- **`agents-never-commit`:** FULLY PRESERVED.
- **Settings constraint:** needs `bgIsolation:"none"` documented in OPTIONAL-FEATURES (do not auto-write). NOTE: if a future Claude Code default flips `bgIsolation` to isolate-by-default for background subagents, the pack's current "in-place" assumption SILENTLY BREAKS unless this setting is documented. This is a degradation-safety reason to document it even though the pack prefers no isolation.
- **Cost:** no parallelism-with-isolation benefit (the thing the user wants). Concurrent in-place agents can collide on the same files — mitigated today by Pack-Chat file-ownership boundaries (PACK-CHAT.md "Chat-ownership boundaries on concurrent sessions").

### Option 2 — Designated report-write-by-absolute-path (IMPL reports for ALL agents)
- **Shape:** Even when an agent runs in an isolated worktree, it Writes its IMPL-REPORT to an absolute path OUTSIDE the worktree (e.g., a parent-tree `maintenance-docs/...` path or a `/tmp` handoff the parent ingests). Addresses the user's "IMPL reports for all agents land back in the parent" directive directly.
- **Persist (A) for reports:** SOLVED — report escapes the auto-removed worktree.
- **Merge-back (B) for code:** NOT solved by itself (only the report escapes; code edits still trapped in the worktree). Pairs with Option 3/4/5 for code.
- **`agents-never-commit`:** PRESERVED (a Write is not a git op).
- **Tension:** DIRECTLY CONFLICTS with the commit-discipline skill's "write-target rule" (§2 of `commit-discipline/SKILL.md`): "Every Write and Edit MUST go to a path under `pwd`." That rule is a bug-era artifact of the isolated-worktree write-rejection incident (BD-119 C-2). P2/P3 must reconcile: the write-target rule was designed to STOP cross-worktree writes; this option REQUIRES one. The architect must decide whether the report is a sanctioned exception (e.g., an allowlisted handoff dir) or whether Option 1 makes this moot.
- **Open question:** does the Agent tool / sandbox even PERMIT a Write outside `pwd` to the parent tree? The commit-discipline skill says such writes are rejected ("permission denied / file outside workspace"). The architect needs an empirical probe: can an isolated agent Write to an absolute parent-tree path, or only to `/tmp`? (Note: harness "Additional working directories" sometimes lists `/tmp` — see SKILL §2.)

### Option 3 — Read-write agent class commits to a throwaway branch the parent merges
- **Shape:** A distinguished read-write agent class is permitted to `git add` + `git commit` ONLY inside its isolated `worktree-agent-*` branch; Pack Chat then `git merge`/`cherry-pick`/`git am` the branch into the parent branch after review.
- **Persist (A):** SOLVED (commit persists the work).
- **Merge-back (B):** SOLVED *if* the branch survives — but the auto-delete-on-return bug (#38287) means the branch can vanish with the commit dangling. Requires session-naming + keep-on-exit (docs §1.5) OR Pack Chat capturing the SHA before return.
- **`agents-never-commit`:** RELAXED. This is the entry's ABSOLUTE-LAST-RESORT path — permitted only with explicit user sign-off + architect's exhaustion rationale. The folded git-permission-hardening scope (BD-197 adds `git stash`/`reset`/`restore --staged`/`checkout --` to the prohibited verbs) makes any relaxation here a CONTRADICTION that must be carved out very precisely (a single agent class, isolated-worktree-only, never the parent tree).
- **Risk:** the strongest of the entry's named concerns. Surfacing only.

### Option 4 — Patch-file handoff (agent emits a diff; parent applies)
- **Shape:** Isolated agent runs `git diff` (a READ-ONLY allowed verb per commit-discipline §3) and Writes the patch to a handoff path (same escape question as Option 2); Pack Chat `git apply`/`git am` it onto the parent branch after review.
- **Persist (A):** SOLVED (the patch is the persisted artifact).
- **Merge-back (B):** SOLVED via `git apply` by Pack Chat (Pack Chat may commit) — auditable, reviewable, no dangling-commit risk.
- **`agents-never-commit`:** FULLY PRESERVED — `git diff` is read-only; the agent never stages/commits; only Pack Chat applies + commits.
- **Tension:** same write-escape question as Option 2 (where does the patch land if the worktree auto-removes?). If the patch can be written to a parent/`/tmp` path, this is the cleanest `agents-never-commit`-preserving merge-back primitive in the option space.
- **Cost:** large diffs / binary changes / rename-heavy edits can be awkward as patches; `git apply` can fail on drift if the parent moved.

### Option 5 — Capture-before-return (Pack Chat reads the worktree before auto-removal)
- **Shape:** Pack Chat (which CAN commit) reads the isolated worktree's path + branch SHA from the agent's return metadata and `git diff`/`git cherry-pick`/`git merge`s BEFORE the auto-removal window, or names the session so removal prompts instead of auto-deleting.
- **Persist (A) / Merge-back (B):** SOLVED if the timing/naming works; depends on the keep-on-named-session docs behavior (§1.5) being reliable.
- **`agents-never-commit`:** PRESERVED (Pack Chat does the git ops).
- **Risk:** races the auto-removal; depends on the Agent tool surfacing the worktree path + branch to the parent (needs empirical confirmation — does the Agent tool return the `worktree-agent-*` branch name / path to the caller?).

### Cross-cutting open question for §2
The entire isolated-with-merge-back family (Options 2–5) hinges on **two unverified Agent-tool facts** the architect must probe empirically (read-only):
- (Q-A) Can an isolated agent Write to a path OUTSIDE its worktree `pwd` (parent tree or `/tmp`)? The commit-discipline skill says no for the parent tree.
- (Q-B) Does the Agent tool return the isolated worktree's path + `worktree-agent-*` branch name to the calling chat, so Pack Chat can capture/merge before removal?
If (Q-A) is "only `/tmp`" and (Q-B) is "no path returned," then Options 2/4/5 narrow to a `/tmp` handoff only, and Option 1 (no isolation) becomes the low-risk default with isolated-parallel as a documented opt-in for advanced users.

---

## 3. Cross-CLI + TEAMS behavior and graceful-degradation requirements

### 3.1 Claude Code — Agent Teams (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`) × worktree isolation
- Agent Teams is documented in `pack-ops/OPTIONAL-FEATURES.md` + `project-template/docs/pack/OPTIONAL-FEATURES.md` (experimental, v2.1.32+, env-gated, Claude-only). It is the EXISTING opt-in DOC PATTERN the BD-197 entry says to model the `baseRef` prerequisite on.
- **TEAMS × worktree interaction (open question — needs architect probe):** Agent Teams teammates are full Claude Code sessions; the worktrees docs say "running each Claude Code session in its own worktree means edits in one session never touch files in another." So TEAMS-on + isolation is the docs' intended parallel model — BUT the entry's hard constraint requires TEAMS-OFF to also work with no destructive surprises. With TEAMS off, the parallel-execution path is the Agent tool's `isolation` parameter / `bgIsolation`, which is the buggy surface (§1.5).
- **Degradation requirement (TEAMS-on AND TEAMS-off must both be safe):**
  - TEAMS-off + no `baseRef`/`bgIsolation` set → must fall back to in-place sequential agents with ZERO failures (Option 1 model). This is today's behavior and is safe.
  - TEAMS-on → teammates may isolate per the docs; the pack must not assume in-place editing if a future default isolates background subagents (the #59580/#59848 risk). Documenting `bgIsolation` is the safety hedge.
  - The "no destructive surprises" bar maps directly onto the silent-data-loss bugs (#38287, #51596, #55708): the pack's degradation design must ensure that if isolation IS active (by user setting or product default), work is never silently lost — i.e., the merge-back/capture primitive (§2) must be present whenever isolation is possible, not only when the user opts in.

### 3.2 Codex CLI — isolation support (entry says "NONE" — NOW PARTIALLY WRONG)
- **Finding:** The Codex APP supports a worktree mode to isolate changes in a Git worktree; a documented custom Codex skill pattern has a subagent create a worktree, run `codex exec` workspace-write inside it, then present a diff for review before applying (sources: `developers.openai.com/codex/*`, retrieved 2026-06-13). Codex CLI subagents are configured via `[agents]` in `config.toml` / `~/.codex/agents/` / `.codex/agents/`; there is NO native per-agent worktree-isolation key in core config — isolation is an architectural pattern, not a flag.
- **Prior in-repo finding (RESEARCH-19C-G-ITEMS-VERIFICATIONS.md G-2, still valid):** Codex has spawn/cap/close (`spawn_agent`/`wait_agent`/`close_agent`, `agents.max_threads`) but NO peer-messaging (issue #12462) — no Agent-Teams/SendMessage analog.
- **Per verify-availability-not-just-existence:** Codex worktree isolation EXISTS as a pattern (app + custom skill) but is NOT a drop-in CLI flag and is not the same surface as Claude's `isolation` parameter. Architect should treat as "available via pattern, not parity."

### 3.3 Gemini CLI — isolation support (entry says "NONE" — NOW WRONG)
- **Finding:** Gemini CLI ships **experimental Git Worktrees** (docs: `https://geminicli.com/docs/cli/git-worktrees/`, retrieved 2026-06-13). Enable via `/settings` "Enable Git Worktrees" = true or `settings.json`; use `--worktree`/`-w <name>` to create an isolated worktree+branch under `.gemini/worktrees/`. Landed via PR #22973 / issue #22945; shipped through release v0.36.0. Gemini deletes only "clean" worktrees (no uncommitted changes, no new commits) — same conditional-cleanup shape as Claude.
- **Subagent-isolation bug (open):** issue #22658 + PR #23275 (draft docs) + PR #22718 — when a subagent is dispatched with isolation, the agent's shell cwd / sandboxed git may NOT be locked to the worktree path → git ops can hit the parent repo (the same class of leak as Claude #55708).
- **Prior in-repo finding (G-2, still valid):** Gemini subagents are one-shot consolidated returns; no keep-alive/peer-messaging.
- **Per verify-availability-not-just-existence:** Gemini worktree isolation EXISTS (experimental, GA-tracked) but is IMMATURE (subagent-cwd-not-locked bug). Architect should treat as "available but not safe-to-rely-on for subagent isolation yet."

### 3.4 Degradation-model summary for the architect
| Surface | Isolation today | Safe to rely on? | Degradation rule |
|---|---|---|---|
| Claude Code, TEAMS-off, no settings | in-place (no isolation) | YES (today's model) | default; zero-failure baseline |
| Claude Code, `baseRef:"head"` set | isolate at parent HEAD | best-effort (buggy #60588) | opt-in; document, don't ship |
| Claude Code, `bgIsolation:"none"` | force in-place | YES | document as the explicit "stay in-place" lever |
| Claude Code, TEAMS-on | per-session worktrees (docs-intended) | partial (silent-loss bugs) | merge-back primitive must exist |
| Codex CLI | pattern-only (app worktree mode; custom skill) | not parity | native sequential fallback |
| Gemini CLI | experimental `--worktree` | immature (subagent cwd bug) | native sequential fallback |

The "no destructive surprises across TEAMS on/off" constraint is satisfiable ONLY if the design (a) documents `bgIsolation`/`baseRef` so the user's environment is explicit, and (b) provides a persist/merge-back path whenever isolation is even possible (not just when opted in), because product defaults can change under the pack.

---

## 4. Removal blast-radius (P2 prep) — EXHAUSTIVE, counts reconciled ≥2 ways

### 4.1 Search method
- Per-file count: `rg --hidden --no-ignore -ci 'worktree'` across the whole v11-dev tree (excl `.git`).
- Tight RULE-carrier set: `rg --hidden --no-ignore -l 'isolation: *"worktree"|worktree isolation|worktree.baseRef|baseRef|worktree-agent-'` excluding `.git`, `archive/`, `BD-197.md`, the PREWORK file, the 19C research file, and `test-fixtures/`.
- Dangling-ref set: `rg -c 'feedback_worktree_isolation_broken_from_v11_clone'`.
- All run at HEAD `f858d90` on 2026-06-13.

### 4.2 Category legend
- **REMOVE** — a prohibition rule / bug-era guidance that becomes obsolete when isolation is enabled.
- **UPDATE** — describes current behavior; must be rewritten to the new (enabled, settings-aware) model.
- **DISPOSITION** — historical record (IMPL-REPORT / PACK-REVIEW / archive); leave in place as history OR annotate; do NOT rewrite history. Architect decides annotate-vs-leave.
- **DANGLING-REF** — references the deleted `feedback_worktree_isolation_broken_from_v11_clone.md` memory file; the reference must be excised/repointed.

### 4.3 PRIMARY RULE CARRIERS (active tree — the P2 core target set; 13 files)

| # | File | What it carries | Category |
|---|---|---|---|
| 1 | `CLAUDE.md` (root) `## Pack memory` → `### Sub-agent behavior (Claude-only)`, lines ~325-334 | THE prohibition: "Spawn all sub-agents with no worktree isolation. Do not pass `isolation:\"worktree\"` … checks them out at `origin/main` …" | REMOVE/UPDATE (PM-chat/trinity-governed; PACK-CHAT.md §12 procedure per entry process-note) |
| 2 | `.claude/skills/commit-discipline/SKILL.md` | §1 pre-flight asserts `git rev-parse --abbrev-ref HEAD` "Must start with `worktree-agent-`"; §2 write-target rule "every Write under `pwd`" (built for isolated worktrees); `pwd` "Must end in worktree path"; §6 anti-pattern. Bug-era assumptions baked in. | UPDATE (the `worktree-agent-` precondition is FALSE under no-isolation today and must be reconciled with whatever P3 chooses) |
| 3 | `.codex/skills/commit-discipline/SKILL.md` | byte-mirror of #2 | UPDATE (trinity/quad mirror) |
| 4 | `.gemini/skills/commit-discipline/SKILL.md` | byte-mirror of #2 | UPDATE (trinity/quad mirror) |
| 5 | `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` line 194 | "Spawn sub-agents in background; no worktree isolation from non-main clones" (rule digest) | REMOVE/UPDATE |
| 6 | `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md` §D (lines ~415-424) | "D. Worktree / isolation (CLAUDE.md Pack memory)" — full reproduction of the prohibition + rationale | UPDATE or DISPOSITION (it's a plan doc; architect decides) |
| 7 | `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` (lines 923-929, 962, 1043-1047, 1294) | §4.8 "Worktree isolation broken from v11-dev clone"; multiple "Do not pass `isolation:\"worktree\"`" reproductions | UPDATE/DISPOSITION (plan doc) |
| 8 | `maintenance-docs/v11-implementation/PLAN-DOC-CONCISION-GUARDRAILS.md` line 187 | coder spawn template fragment "NO worktree isolation" | UPDATE/DISPOSITION |
| 9 | `maintenance-docs/v11-implementation/ARCHITECTURE-BD-196-S1-CORPUS-CLASSIFICATION.md` line 88 | classification row #24 "Spawn all sub-agents with no worktree isolation" with STALE line-range citation `L348-357` (entry calls this out explicitly) | UPDATE (excise/refresh the stale line-range) or DISPOSITION |
| 10 | `maintenance-docs/v11-research/RESEARCH-CLAUDE-REPOS-SURVEY.md` (lines 44,154,159,294-300,375) | describes the "isolation-broken-from-clone caveat" + 2× DANGLING-REF to deleted memory file | DANGLING-REF + UPDATE (the caveat is now stale) |
| 11 | `maintenance-docs/v11-implementation/IMPL-REPORT-BD-214-C5a-BD197.md` | references BD-197 / worktree (recent impl report) | DISPOSITION (history) |
| 12 | `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-196-C9.md` | reproduces the rule digest | DISPOSITION (history) |
| 13 | `maintenance-docs/v11-implementation/PLAN-DEPLOYMENT-PYTHON-OBSERVABILITY.md` | contains `baseRef`/worktree mention | DISPOSITION/UPDATE (verify in P2) |

### 4.4 OPERATIONAL "worktree" mentions that are NOT the prohibition but ARE bug-era-coupled (must reconcile in P2/P3)
These describe the EXISTING isolated-worktree pre-flight model and will be FALSE-or-incomplete under whatever P3 chooses. The architect must decide whether they stay (if P3 keeps in-place) or change (if P3 enables isolation):
- `.claude/skills/implementation-report/SKILL.md` (lines 14,21,43,48) + `.codex`/`.gemini` mirrors — "the worktree is lost," "diff against the worktree base," "does not commit, so the SHA is unchanged from the worktree base." (3 files)
- `.claude/agents/pack-coder.md` (lines 3,13,58,75) + `.codex`/`.gemini` mirrors — "makes the file changes in its worktree," "Branch + final HEAD SHA on your worktree." (3 files)
- `pack-ops/PACK-CHAT.md` line 116 — "multiple worktrees on the same clone" (concurrent-session ownership rule; benign, likely STAYS).

### 4.5 DANGLING-REF reconciliation (deleted `feedback_worktree_isolation_broken_from_v11_clone.md`)
**The entry says "4 dangling refs." Re-measured 2026-06-13, the count splits by tree:**
- **Active tree (non-archive): 3 files** — `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` (§6.11, 1 hit), `maintenance-docs/v11-implementation/RESEARCH-19C-G-ITEMS-VERIFICATIONS.md` (G-1, 1 hit), `maintenance-docs/v11-research/RESEARCH-CLAUDE-REPOS-SURVEY.md` (2 hits).
- **Archive tree: 4 files** — `archive/v11/ARCHITECTURE-CLEANUP-BATCH-19B-V2.md` (2), `archive/v11/ARCHITECTURE-CLEANUP-BATCH-19B.md` (1), `archive/v11/IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-19b-6.md` (3), `archive/v11/PLAN-CLEANUP-BATCH-19B.md` (1).
- **TOTAL 7 files carry the dangling reference** (3 active + 4 archive). The entry's "4" matches the set the prior audit chose to act on (the entry names exactly 3 active files: ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY, RESEARCH-CLAUDE-REPOS-SURVEY, RESEARCH-19C-G-ITEMS-VERIFICATIONS — note RESEARCH-19C is the file containing G-1 and is also a P2 target). **DISCREPANCY FLAG for the architect:** the entry's "4 dangling refs" and the measured 3-active/7-total do not cleanly reconcile; P2's fresh audit must rebuild this list. The reconciliation: entry-named active set = 3; the entry's "4th" is likely an archive file or counted RESEARCH-19C separately. Archive dangling-refs are DISPOSITION (history), per the fail-loud "delete superseded docs" memory the architect should decide delete-vs-leave.

### 4.6 ZERO-FINDINGS (confirmed clean — these surfaces carry NO prohibition; reconciliation cross-check)
- `AGENTS.md` (root), `GEMINI.md` (root): `rg -c 'worktree|isolation'` = NO HITS. The rule is Claude-only by design; trinity exemption is intact. **No P2 removal here.**
- `project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md`: `rg -c 'worktree'` = NO HITS. **The prohibition was NEVER shipped to clients.** P3's client-side additive work (the entry's "ADDITIVE surfaces") is genuinely net-new, not removal.
- `project-template/` worktree hits overall: ZERO (the broad `isolation` hits in project-template skills/agents are ACTOR/sandbox isolation, not worktree — excluded per the PREWORK Step-1 exclusion rule).
- `pack-ops/OPTIONAL-FEATURES.md` + `project-template/docs/pack/OPTIONAL-FEATURES.md`: NO worktree/baseRef hits today (only Agent Teams). These are the P3 ADDITIVE homes for the `baseRef`/`bgIsolation` opt-in doc, modeled on the Agent Teams section.

### 4.7 Count reconciliation (≥2 ways)
- **Way 1 (per-file `worktree` count, top of tree, active non-archive non-fixture):** matches the 13 primary carriers + the operational-mention files in §4.4 (commit-discipline ×3 at 11 hits each; CLAUDE.md 7; pack-coder/impl-report ×3 at ~4 each).
- **Way 2 (tight RULE-pattern `l`-list):** returns exactly the 13 files in §4.3 (after excluding BD-197/prework/19C/fixtures/archive) — confirming the primary set is bounded at 13.
- **Way 3 (dangling-ref `-c`):** 3 active + 4 archive = 7, cross-checked in §4.5.
The two independent methods agree on the 13-file primary RULE-carrier core; the §4.4 operational set (additional ~7 files) is the coupling surface the architect must consciously include.

---

## 5. Open questions for the architect / user (researcher does NOT decide these)

1. **(Q-A) Write-escape:** Can an isolated Agent-tool agent Write to a parent-tree absolute path, or only `/tmp`? Determines whether Options 2/4/5 are viable for IMPL-report-back. Needs an empirical read-only probe (the commit-discipline skill says parent-tree writes are rejected).
2. **(Q-B) Worktree path/branch return:** Does the Agent tool return the `worktree-agent-*` branch + path to the calling chat? Determines whether Pack-Chat capture/merge (Option 5) is possible.
3. **`bgIsolation` default trajectory:** If a future Claude Code default isolates background subagents, does the pack's in-place model silently break? Argues for documenting `bgIsolation:"none"` regardless of the chosen mechanism.
4. **`agents-never-commit` carve-out scope:** If the user signs off on Option 3 (last resort), how is the carve-out bounded against the FOLDED git-permission-hardening scope (which ADDS `git stash`/`reset`/`restore --staged`/`checkout --` to prohibited verbs)? The two pull in opposite directions and must be reconciled in one design.
5. **Cross-CLI correction:** Given Gemini (experimental) and Codex (pattern) now have worktree isolation, is the feature still framed "Claude-only / trinity-exempt," or does P3 document a per-CLI degradation matrix? (verify-availability-not-just-existence: both are EXISTS-BUT-IMMATURE.)
6. **commit-discipline reconciliation:** The write-target rule + `worktree-agent-` pre-flight precondition were built FOR isolated worktrees and are currently FALSE under no-isolation. Do they get removed, rewritten to settings-aware, or made conditional? This is the single highest-coupling P2/P3 edit (×3 mirrors).
7. **Dangling-ref count discrepancy:** entry says 4; measured 3 active / 7 total. P2's fresh audit reconciles; architect confirms which set is in scope (active-only vs incl-archive) and applies the fail-loud delete-vs-annotate decision.
8. **Settings-file constraint vs degradation safety:** the entry forbids shipping/auto-writing any settings file, but degradation safety may REQUIRE the user to set `bgIsolation`. Reconcile "document only, never write" with "the pack breaks if the user's environment isolates unexpectedly."

---

## 6. Rules-Applied Verification Block

| # | Rule (as named in prompt) | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | Agents never commit (git read-only) | Only git verbs run: `git rev-parse HEAD`, `git branch --show-current`, `git -C … rev-parse/branch`. No `add`/`commit`/`push`/`stash`/`checkout`/`merge`/`reset` issued. Report written via a single heredoc `cat >` (file write, not git). | COMPLIANT |
| 2 | Read-only mandate (write ONLY the one report) | Exactly one file created: `maintenance-docs/v11-implementation/RESEARCH-BD-197-P1-WORKTREE-ISOLATION.md`. All other tool calls were Read / Bash-grep / WebSearch. No edits to any existing file. | COMPLIANT |
| 3 | Researcher does not design | §2 presents 5 options with trade-offs and explicitly states "NO DECISION"; §5 lists 8 open questions deferred to architect/user; no mechanism selected. Headline §0.4 surfaces a fact ("`agents-never-commit` does not HAVE to be relaxed") without choosing the path. | COMPLIANT |
| 4 | Empirical-evidence / citation blocks | Every §1 claim carries URL + retrieval-date 2026-06-13 + issue numbers (#45371,#60588,#59580,#38287,#51596,#55708,#39886, etc.) + verbatim docs quotes; §4 counts carry the exact `rg` command + HEAD `f858d90` + date. | COMPLIANT |
| 5 | Exhaustive blast-radius, counts reconciled ≥2 ways | §4.3 (13 primary carriers) + §4.4 (operational coupling) + §4.5 (dangling-refs 3 active/7 total) + §4.6 (zero-findings cross-check) + §4.7 (reconciliation via per-file count, tight-pattern l-list, and dangling -c — three methods agreeing on the 13-file core). Discrepancy with entry's "4 dangling refs" explicitly flagged (§4.5, Q-7). | COMPLIANT |
| 6 | Rules-Applied Verification Block present | This table. | COMPLIANT |
| 7 | PREFLIGHT + STOP-MEANS-STOP | PREFLIGHT line emitted in chat immediately before this Write: "PREFLIGHT: P1 research complete; about to Write …". No parent stop received. | COMPLIANT |

---
*End of RESEARCH-BD-197-P1-WORKTREE-ISOLATION.md*
