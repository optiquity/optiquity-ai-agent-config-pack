# ARCHITECTURE-BD-197 — RECONCILED authoritative design: worktree isolation (opt-in, isolated, safe parallel agent execution; Claude-only; pack-self + project-template)

**Role:** pack-architect (fresh, reconciling). **Mode:** design-only (one doc written; everything else read-only).
**Repo:** optiquity-ai-agent-config-pack-v11-dev · **Branch:** v11-dev · **HEAD at reconciliation:** `3e3159ee8b5e97bf8775ecf67a76867d28933a3e`.
**Date:** 2026-06-13.
**Status:** PLANNER-READY: YES (2nd-adversarial sole blocker fixed; mode-model corrected from empirical probe + official schema — see the Correction pass (2026-06-14) note below, §15, and the Update log). This doc SUPERSEDES `ARCHITECTURE-BD-197-WORKTREE-ISOLATION.md` (first design — kept as history/input) by folding in the `ARCHITECTURE-BD-197-ADVERSARIAL-REVIEW.md` corrections and the locked user decisions D1–D6 + the 2026-06-13 notes 6–9 in `backlog/BD-197.md`.

**Update log (2026-06-13) — post-2nd-adversarial reconciliation (BD-197 note 10; user-approved).** Two changes folded into this otherwise-affirmed design (no AFFIRMED architectural decision altered):
1. **P2 completeness-gate fix (the sole 2nd-adversarial blocker, G-1+G-2).** The single grep-ZERO gate that forbade `baseRef`/`bgIsolation` — the very setting keys P3 MUST write — is SPLIT into (a) a **prohibition-ONLY absence-gate** (matches the prohibition prose only, never the bare key names) and (b) a **separate presence-check** that OPTIONAL-FEATURES (both surfaces) DOES document `bgIsolation`/`baseRef`. The allowlist is re-MEASURED against the current tree (Empirical-Evidence Block §11.5) and sized exactly to the measured LEAVE set; the stale static "3 BD-197-process files" count is DROPPED everywhere (§10/§11.3/§11.5/§13.1). PLUS the two 2nd-adversarial git-backstop precision flags (G-4) are pinned in §5: the mechanical backstop is VERB-PRECISE (deny the patch-applying `git apply` form WITHOUT denying `git diff`/`git apply --check`), and the stale `checkout -- <path>` carve-out is DROPPED from pack-coder ×3.
2. **NEW-FORK-1 RESOLVED = (a) gate-then-probe-then-degrade** (user-decided, note 10). It is no longer an open fork; recorded in §2.2, §7, §10. It does NOT block the UC-1/P1 pipeline.

## Correction pass (2026-06-14) — mode model re-documented from empirical probe + official settings schema

**What forced the change.** After this doc was reconciled (2026-06-13) and twice-adversarially validated, an exhaustive empirical probe matrix on **Claude Code 2.1.173** plus the **official Claude Code settings schema** (https://www.schemastore.org/claude-code-settings.json, the `worktree` object, verified 2026-06-14) OVERTURNED the doc's mode-detection model. The merge-back model, RW/RO classification, git-permission contract, conflict protocol, use-case scope (P1/P3/P2), D1–D6, and the P2/P3 plans are NOT touched — only the mode-detection re-documentation, the sections that cited the overturned model, and the cross-references. Probe HEADs: v11-dev=`ae3d932`, local main=`fa81704`, origin/main=`7ccbba9`.

**What was WRONG (removed/corrected):**
- The claim **"the isolation TRIGGER is `worktree.bgIsolation`"** is FALSE. `bgIsolation` governs TOP-LEVEL BACKGROUND SESSIONS only (the `EnterWorktree`/`ExitWorktree` flow), NOT Agent-tool subagents. The subagent TRIGGER is the Agent-tool **`isolation` PARAMETER** (only valid value `"worktree"`).
- The **9-cell `bgIsolation`×`baseRef` matrix** is WRONG (it multiplied two INDEPENDENT mechanisms into one table). It is REPLACED by the two-independent-mechanisms model (§3).
- `bgIsolation` is **NOT a boolean** — it is enum `["worktree","none"]`, default `"worktree"`; any `bgIsolation:true` is invalid.

**What is now ESTABLISHED (folded in):**
- **(A) Subagent isolation** = the per-spawn Agent-tool `isolation:"worktree"` PARAMETER (the trigger) × `worktree.baseRef` (the BASE). `baseRef` enum is `["fresh","head"]`, default `"fresh"`; `fresh`=origin/<default> (the historical "checks out main" bug), `head`=local HEAD (the fix). `baseRef:"head"` is REQUIRED for HEAD-basing; a fresh client (the pack ships NO settings file) defaults to `fresh`=origin/main.
- **(B) Background-session isolation** = `worktree.bgIsolation` + `EnterWorktree`/`ExitWorktree`. SCOPED OUT to **BD-218** (Deferred, v11.1, opened 2026-06-14 per user) — referenced here, NOT designed here.
- **No platform safety net for subagents.** A non-isolated BACKGROUND Agent-tool subagent wrote to the main checkout FREELY (the `bgIsolation` gate does NOT apply to subagents). So RW-agent safety rests entirely on (a) always spawning RW agents with `isolation:"worktree"` and (b) the agents-never-commit + destructive-verb ban — making the RW/RO classification + "RW must be spawned isolated" LOAD-BEARING, not advisory.
- **UC-1 PROVEN.** Agent-tool `isolation:"worktree"` (foreground + background) created an isolated worktree based at the PARENT HEAD (because `baseRef:"head"` was set); the tool RETURNS `worktreePath`+`worktreeBranch`; orchestrator `git -C <wt> add -N` + `git diff HEAD` → patch → `git apply --check` onto the parent branch = CLEAN (agent never staged/committed). The launcher path (`git worktree add --detach <path> HEAD`) bases at the parent HEAD DETERMINISTICALLY with zero settings dependence (settles §7's settings-independent-HEAD-basing claim).

**Sections touched by this pass:** §0 (decision 3 + change-summary), §1 (re-documented as §1.1 from the established facts), §3 (two-independent-mechanisms model; 9-cell matrix removed), §7 (launcher HEAD-basing now PROVEN), §8 (degradation re-stated on the corrected model; `fresh`=origin/main caveat surfaced), §9 (OPTIONAL-FEATURES content corrected), §13 (Guard-A′ asserted tokens reconciled), §14/§15 (reconciliation + readiness). The reconciliation chain for the realized facts cross-references BD-218 for the scoped-out background-session axis (architect-doc-reality-reconciliation).

**Reconciliation contract used:** preserve what the first design got right (AFFIRMED by the adversarial pass), apply every adversarial CORRECTION, integrate every LOCKED user decision. Where the first design and the adversarial conflict, the **adversarial correction + the user's locked decision WIN**. No silent drift from the locked decisions.

**Inputs folded:** `backlog/BD-197.md` (full, incl. notes 1–9 + D1–D6), the first design (all 9 sections), the adversarial review (all 12 sections), `RESEARCH-BD-197-P1-WORKTREE-ISOLATION.md`, `RESEARCH-BD-197-AGENT-PERMISSION-INVENTORY.md`, `CLAUDE.md ## Pack memory` (full), `pack-ops/PACK-CHAT.md` §"Rule-change propagation procedure", `pack-ops/PACK-AGENTS.md`.

This document is a STRATEGY doc plus the P2 removal plan and the P3 implementation plan. It implements nothing. Line numbers in cited research/corpus drift; P2/P3 implementers re-audit by content.

## Reconciliation pass (2026-06-14, BD-197 Note-15 gate)

**Why.** Per the `architect-doc-reality-reconciliation` rule, before BD-197 is flipped Resolved, this design doc (and any stale plan references) must be reconciled to the AS-BUILT reality of the landed C0–C8b implementation. This note records the AS-BUILT reconciliations folded into this doc; it cross-references **`backlog/BD-197.md` Note 15** (the authoritative delta list). All as-built facts below were confirmed by `grep` of `scripts/validate-pack.py` (the realized SSOT for check numbers + guard names).

**AS-BUILT reconciliations folded into this doc (BD-197 Note 15(a)–(d)):**

1. **Guard-C realized as TWO checks, not one (Note 15(a)).** §13.3 previously named a single conceptual Guard-C with a fold-vs-standalone coder's-call. AS-BUILT it is **Check 56 (Guard-C pack, C5 — the full §5.1 28-verb set across 10 pack surfaces)** + **Check 57 (Guard-C project, C7b — an 8-verb intersection + a trinity-only catch-all across 52 project surfaces)**. The split is the correct measure-then-bound outcome (the pack and project surface families are structurally different); the decision-8 "may drop to 11 commits if folded" branch did NOT apply — C7b is PRESENT, the realized count is 12 commits. §13.3 now documents the 56+57 split + the reason. (Source: C7b reviewer NIT-2.)

2. **Realized CI check numbers (Note 15(b)).** The design's earlier reserved/placeholder numbering is SUPERSEDED by the as-built map, now reflected in §13.1 / §13.1a / §13.2 / §13.3:
   - Guard-B-pack = **Check 52** (C3); Guard-A (flip-block) = **Check 53** (C5); Guard-A′ (OPTIONAL-FEATURES presence) = **Check 54** (C8b); Guard-B-project = **Check 55** (C6b); Guard-C-pack (verb-parity) = **Check 56** (C5); Guard-C-project (verb-parity) = **Check 57** (C7b).
   - Note: number order ≠ commit order — Guard-A′ keeps its assigned Check 54 even though it lands last (C8b).

3. **C7a D-1 — project skill-name correction (Note 15(c), P-missed-7).** §12.2's project-side bullet previously named `project-template/skills/implementation-report/SKILL.md` — a pack-style name reached for a project surface. The regime-aware report step actually landed at the real project SSOT **`project-template/skills/implementation/SKILL.md`** (there is NO project-side `implementation-report` skill; that name exists only on the pack side). §12.2 is corrected. (The pack-side `.claude/.codex/.gemini/skills/implementation-report/SKILL.md` references in §11.2 / §12.2 pack bullet / §14 are the legitimate pack skill and are unchanged.)

4. **C7b NIT-1 disposition (Note 15(d)).** §13.3 records the harmless WON'T-FIX disposition for Check 57's slash-run matcher: its ≥4-member slash-run rule can theoretically false-positive on a benign 4-segment lowercase path, but it can only make a surface look MORE compliant (never spurious-fail), and no real surface relies on it — accepted as harmless.

**Reconciliation chain (architect-doc-reality-reconciliation).** (a) The in-code docstrings in `scripts/validate-pack.py` (Checks 52–57) already name the realized consumers + cross-reference this design (§13.1/§13.1a/§13.2/§13.3/§5.4); (b) THIS note + the §13 updates are the architect-doc addendum naming the realized consumers (Check 52–57, the project `implementation` skill); (c) `IMPL-REPORT-BD-197-RECONCILIATION.md` cross-references both. No line numbers cited (they drift) — files + symbols only.

---

## 0. Executive summary (the reconciled decisions)

1. **Use-case scope (BD-197 note 6).** PRIMARY = **UC-1/P1**: Pack Chat + PM Chat spawn agents IN-SESSION, in the BACKGROUND, with **opt-in worktree isolation for SAFE PARALLEL read-write agents (coders)**; merge-back via the `/tmp` patch the agent writes before return; **read-only background agents need no isolation** (they don't write the tree). SECONDARY (support IF FEASIBLE) = **P3-launcher**: an `agent-run.sh`-style launcher that `git worktree add` + runs `claude --agent` in it (human-driven parallel agents; clean standard-git merge). LOW priority / only-if-free = **P2-manual** (manual human worktree). P3-launcher feasibility is stated honestly in §7.

2. **Merge-back model (AFFIRMED by adversarial §2.3).** **Option 1 (in-place) = degradation FLOOR/default; Option 2 (report-write via `/tmp` for ALL agents); Option 4 (RW patch-file handoff via `/tmp`) = primary RW merge-back.** RW agent runs read-only `git diff` in its worktree, Writes patch + IMPL-report to a per-spawn `/tmp` handoff dir BEFORE return; orchestrator `git apply --check`/`--3way` + commits. **`agents-never-commit` is FULLY PRESERVED** — no committing agent class (Options 3 + 5 REJECTED on the Q-A/Q-B probes). ALL agents (RW + RO) land IMPL reports via the named path (`/tmp` when isolated; parent tree when in-place).

3. **Mode detection (CORRECTED 2026-06-14 from empirical probe + official schema; supersedes the earlier "bgIsolation is the trigger" framing of D6).** Isolation is governed by **TWO INDEPENDENT mechanisms**, not one matrix. **(A) SUBAGENT isolation** — the trigger is the per-spawn Agent-tool **`isolation` PARAMETER** (only valid value `"worktree"`; BD-197 un-prohibits passing it), and the BASE is set by `worktree.baseRef` (enum `["fresh","head"]`, default `"fresh"`=origin/<default>; `"head"`=local HEAD = REQUIRED for feature-branch work — proven §1.1/FACT-1). **(B) BACKGROUND-SESSION isolation** — `worktree.bgIsolation` (enum `["worktree","none"]`, default `"worktree"`) + the `EnterWorktree`/`ExitWorktree` flow; it governs TOP-LEVEL background sessions ONLY and does NOT gate Agent-tool subagents (FACT-3/FACT-4) → SCOPED OUT to **BD-218** (v11.1). There is therefore **NO platform safety net for subagents** (FACT-4): RW-agent safety rests entirely on always spawning RW agents with `isolation:"worktree"` + the agents-never-commit/verb-ban — making the RW/RO classification LOAD-BEARING. The system still **VERIFIES the ACTUAL regime at RUNTIME by ground-truth** (did a `worktree-agent-*` worktree appear — `pwd`/HEAD self-check), and **never trusts `settings.json`** (platform bugs #39886/#59848 can silently disagree). Safe default = in-place. The note-9 "VERIFY exact param" is RESOLVED: the param is `isolation:"worktree"` (head/none are `baseRef`/`bgIsolation` SETTINGS values, NOT param values).

4. **RW/RO classification (D1+D2, AFFIRMED).** Declared per surface with TRIPLE reinforcement: pack SSOT = PACK-AGENTS `Class` column; project SSOT = PM-CHAT permission-profiles table + `agent-run.sh READONLY_AGENTS` as a CI-checked projection; PLUS per-agent-file reinforcement on EVERY agent (pack 5, project 16); PLUS the inline rules-in-force block in every spawn prompt. Pack + project designed NATIVELY (separate artifact sets, never byte-copies).

5. **Git-permission contract (D5 + note 8): BOTH a denylist AND the read-only-only principle.** Explicit denylist (commit/push/add/stage/stash/rm/mv/reset/restore/checkout + `clean`/merge/rebase/cherry-pick/revert/am/apply/branch -d/-D/switch/worktree/config/remote/update-ref/update-index/pull/gc/reflog expire/filter-branch — "including but not limited to") + the positive "read-only git verbs allowed only" principle line (catch-all closing the "never told me" gap). In prose (agent files + trinity ×3 + commit-discipline skill ×3 + rationale) AND a mechanical backstop (PreToolUse hook / `--disallowedTools` on the named verbs — pack-side hook; project-side `agent-run.sh` `--disallowedTools`). Propagated via the PACK-CHAT rule-change procedure for `## Pack memory` edits. Exact allowed/denied sets in §5.

6. **Conflict protocol (D3, AFFIRMED + sharpened §6).** `git apply --check`/`--3way`; on true conflict STOP + surface + re-spawn a fresh coder on current HEAD, NO orchestrator hand-merge; the multi-RW apply is atomic-per-patch (check→apply→review→commit per patch, never a half-applied set); both chats defensively scope parallel RW agents to non-overlapping files so conflicts are rare.

7. **Graceful degradation (CORRECTED — complete matrix §8).** Full table over {regime ground-truth} × {TEAMS on/off}, INCLUDING the bug cells the first design omitted (#39886 silent fall-to-MAIN while the pack believes it is isolated; the wrong-base `fresh`=origin/main caveat surfaced, NOT silent) — zero failures everywhere. The ground-truth runtime self-detect (item 3) is what makes the bug cells failure-safe. No settings file shipped/auto-written at any scope (so a fresh client defaults to `baseRef:"fresh"`=origin/main — a documented degradation, §8).

8. **OPTIONAL-FEATURES.md (both surfaces, separately authored, §9).** Documents ALL mode-setting ways — `settings.json` per-project (default/recommended) AND global, the per-spawn `isolation` parameter, CLI params, anything else — alongside the existing Agent-Teams opt-in; `/pack-help` + the chats describe it when unset.

9. **P2 removal plan (pack-side ONLY — project confirmed ZERO-shipped → P3 client work is additive, §4):** disposition the 13 primary carriers + ~7 operational-coupling mentions + the dangling-refs (3 active EXCISE / 4 archive LEAVE per D4); fresh-audit + a **prohibition-ONLY grep-ZERO completeness gate** (matches the prohibition PROSE only — never the `baseRef`/`bgIsolation` setting-key names, which P3 must legitimately write) plus a **separate OPTIONAL-FEATURES presence-check** (§11.5), allowlist MEASURED + sized to the LEAVE set. **P3 implementation plan (§5):** rules + mechanism + docs, pack-self AND client-native; commit-discipline ×3 redesigned regime-detecting; git-permission hardening propagation (VERB-PRECISE backstop — deny the patch-applying `git apply` form, not `git diff`/`git apply --check`); measure-then-bound CI guards.

10. **Decisions (§10).** D1–D6 are LOCKED (no re-open). The adversarial added D-NEW-1..4 (all integrated above). The single fork surfaced last pass — **the P3-launcher (UC-secondary) feasibility** — is now **RESOLVED = (a) gate-then-probe-then-degrade** (user decision, BD-197 note 10); see §2.2 + §7 + §10. No open fork remains.

**What changed from the first design (the adversarial corrections applied):** (a) mode-detection corrected to TWO INDEPENDENT mechanisms — subagent isolation triggered by the Agent-tool `isolation:"worktree"` PARAMETER (base from `baseRef`) vs background-session isolation via `bgIsolation`/EnterWorktree (BD-218) + runtime ground-truth (first design's "posture 3" was a FALSE cell, refuted live; the earlier "bgIsolation is the trigger" reconciliation framing also corrected 2026-06-14 per the Correction-pass note); (b) the two-independent-mechanisms model REPLACES both the "three postures + cross-product" narrative AND the 9-cell `bgIsolation`×`baseRef` matrix (which wrongly multiplied two independent axes); (c) the graceful-degradation matrix COMPLETED with the #39886 cell + the `fresh`=origin/main wrong-base caveat (surfaced, not silent); (d) multi-RW atomic-apply boundary made explicit; (e) `/tmp`-handoff-write treated as a degradation signal on failure, not a hard error; (f) git-permission hardening now also targets `agent-run.sh --disallowedTools` (project) reconciled against the shipped `settings.json` `git add` allow; (g) the P2 completeness gate is SPLIT into a prohibition-ONLY absence-gate (never forbids the `baseRef`/`bgIsolation` key names) + a separate OPTIONAL-FEATURES presence-check, with the allowlist re-MEASURED against the current tree and the stale static "3 process files" count dropped; (h) parity check binds to the PROSE mandate header, never `tools:` (`pack-reviewer` carries `Write,Edit` yet is RO); (i) use-case scope re-stated as UC-1/P1 PRIMARY per note 6.


---

## 1. Empirical probe results (UC-1, the mechanisms, Q-A, Q-B) — established 2026-06-14

The mode model below is now established by an EXHAUSTIVE empirical probe matrix on **Claude Code 2.1.173** plus the **official Claude Code settings schema** (https://www.schemastore.org/claude-code-settings.json, the `worktree` object), both verified 2026-06-14. The v11-dev checkout is itself a linked git worktree of the main clone; probe HEADs: v11-dev=`ae3d932`, local main=`fa81704`, origin/main=`7ccbba9`. **Probing is COMPLETE — these facts are ground truth and supersede the earlier "re-verified this pass" §1.1 framing.** §1.2–§1.5 (Q-A/Q-B/joint-selection/git-apply) remain AFFIRMED.

### 1.1 The mode model — established facts (FACT-1..5)

**Empirical-Evidence Block (FACT-1 — UC-1 works):**
- Source: probe P1 (foreground) + P2 (background), Claude Code 2.1.173, 2026-06-14.
- Value (verbatim outcome): Agent-tool `isolation:"worktree"` created an isolated worktree based at the PARENT HEAD `ae3d932` (NOT main) BECAUSE `worktree.baseRef:"head"` was set. The Agent tool RETURNS `worktreePath`+`worktreeBranch` to the orchestrator. Merge-back PROVEN: orchestrator runs `git -C <wt> add -N` + `git diff HEAD` → patch → `git apply --check` onto the parent branch = CLEAN; the agent never staged/committed. Auto-removal is a non-issue because the patch is captured. The launcher path (`git worktree add --detach <path> HEAD`) bases at `ae3d932` DETERMINISTICALLY with zero settings dependence.
- Date/HEAD: 2026-06-14 / v11-dev `ae3d932`.
- Interpretation: the subagent isolation + merge-back pipeline (UC-1) is empirically proven end-to-end; agents-never-commit is preserved.
- Conclusion: **SUPPORTED.**

**Empirical-Evidence Block (FACT-2 — `worktree.baseRef`):**
- Source: official settings schema (https://www.schemastore.org/claude-code-settings.json), `worktree.baseRef`, 2026-06-14.
- Value (verbatim): enum EXACTLY `["fresh","head"]`, default `"fresh"`. Schema description: *"Whether to branch worktrees from origin/<default> (fresh) or local HEAD (head). Default: fresh. Set to 'head' to preserve unpushed commits in new worktrees."*
- Date: 2026-06-14.
- Interpretation: `fresh` (default) = branch from origin/main = the HISTORICAL "checks out main" bug; `head` = local HEAD = the fix. `"main"` is NOT a valid value (that was a probe error). `baseRef:"head"` is REQUIRED for HEAD-basing; a fresh client (the pack ships NO settings file) gets `fresh`=origin/main, so isolation would silently base at origin/main unless the user sets `baseRef:"head"`.
- Conclusion: **SUPPORTED.**

**Empirical-Evidence Block (FACT-3 — `worktree.bgIsolation`):**
- Source: official settings schema (same URL), `worktree.bgIsolation`, 2026-06-14.
- Value (verbatim): enum EXACTLY `["worktree","none"]`, default `"worktree"`. Schema description: *"Isolation mode for background sessions. 'worktree' blocks Edit/Write in main checkout until EnterWorktree is called; 'none' lets background jobs edit the working copy directly without EnterWorktree, for repos where worktrees are impractical."*
- Date: 2026-06-14.
- Interpretation: `bgIsolation` governs TOP-LEVEL BACKGROUND SESSIONS (detached `claude` jobs) via the `EnterWorktree`/`ExitWorktree` tool flow. It is NOT a boolean and NOT the subagent-isolation trigger; `bgIsolation:true` is INVALID.
- Conclusion: **SUPPORTED.**

**Empirical-Evidence Block (FACT-4 — subagents are NOT gated by bgIsolation):**
- Source: probe A (a non-isolated BACKGROUND Agent-tool subagent), Claude Code 2.1.173, 2026-06-14.
- Value (verbatim outcome): the subagent wrote to the main checkout FREELY (Write tool AND bash), no block.
- Date/HEAD: 2026-06-14 / v11-dev `ae3d932`.
- Interpretation: the `bgIsolation:"worktree"` gate does NOT apply to Agent-tool subagents; they run in-place and CAN mutate the parent working tree. There is NO platform safety net for subagents — RW-agent safety rests entirely on (a) always spawning RW agents with `isolation:"worktree"` and (b) the agents-never-commit + destructive-verb ban. This makes the RW/RO classification + "RW must be spawned isolated" LOAD-BEARING, not advisory.
- Conclusion: **SUPPORTED.**

**Empirical-Evidence Block (FACT-5 — the real model = TWO INDEPENDENT mechanisms):**
- Source: synthesis of FACT-1..4 + the schema, 2026-06-14.
- Value (verbatim): **(A) SUBAGENT isolation** — triggered by the Agent-tool `isolation` PARAMETER whose ONLY valid value is `"worktree"` (head/none are SETTINGS values, NOT param values — this RESOLVES note-9 "VERIFY exact param"); base controlled by `worktree.baseRef`. **(B) BACKGROUND-SESSION isolation** — `worktree.bgIsolation` + `EnterWorktree`/`ExitWorktree`. These do NOT multiply into a "9-cell bgIsolation×baseRef matrix"; that matrix and any "bgIsolation is the trigger" statement are WRONG and removed (§3). Background-session isolation is SCOPED OUT to **BD-218** (Deferred, v11.1, opened 2026-06-14 per user).
- Date: 2026-06-14.
- Interpretation: mode detection is two orthogonal axes, not one cross-product; the subagent trigger is a PARAM, not a SETTING.
- Conclusion: **SUPPORTED.**

**Mode-detection refutation (re-documented).** The decisive correction is NOT "baseRef vs bgIsolation as the trigger." The subagent TRIGGER is the Agent-tool `isolation` PARAMETER; `baseRef` is the BASE; `bgIsolation` is a SEPARATE background-session axis (BD-218). The earlier reconciliation framing ("`bgIsolation` is the trigger") is corrected here — it conflated the background-session axis with subagent isolation. The first design's "posture 3" (`baseRef:"head"` ⇒ isolated) remains a FALSE cell: `baseRef` is necessary-but-not-sufficient (it only sets the base IF isolation happens via the `isolation` param).

### 1.2 Q-A — Write-escape (can an isolated agent Write to a parent-tree absolute path?)

**CONCLUSION (AFFIRMED both passes): Write-escape is REGIME-DEPENDENT.** Non-isolated regime → parent-tree absolute-path writes WORK (proven: this session writes its deliverable to a parent-tree path). Isolated regime → parent-tree writes are REJECTED by the harness sandbox; `/tmp` ("Additional working directories") is the only reliable cross-boundary write target. The adversarial proved the `/tmp` half DIRECTLY (it wrote+read `/tmp/bd197-adversarial-probe-46588.txt` as a spawned agent). The isolated-regime parent-tree REJECTION rests on the documented harness behavior (commit-discipline §2) + the inability to A/B-test it without a git-mutating spawn — flagged honestly; not a fresh in-isolation write.

**Hardening (adversarial §2.1, integrated):** because `/tmp`-write is granted in the USER's settings (`"Write(/tmp/*)"`), not the pack's, the design MUST NOT assume the handoff dir is writable by construction — a failed handoff Write is a **degradation signal** (fall back to in-place report), NOT a hard error.

**Design implication:** ISOLATED RW agents target a per-spawn `/tmp` handoff dir the orchestrator names + reads after return; IN-PLACE agents write reports to the parent tree as today.

### 1.3 Q-B — Worktree-path/branch return (does the Agent tool return the worktree path/branch before auto-removal?)

**CONCLUSION (AFFIRMED both passes): NO reliable structured return** of the `worktree-agent-*` path/branch. Clean exit auto-removes worktree+branch; #38287 silently deletes branches with unmerged commits (recoverable only via `git fsck`); #55435 leftover prune-failure; #51596 stale-branch reuse. `git worktree list` this session shows only the two real checkouts, no `worktree-agent-*`. The Agent tool's documented return is textual, not a structured `{worktree_path, branch}` tuple.

**Design implication:** Option 5 (capture-before-return) and Option 3 (throwaway-branch-commit-then-merge) both REQUIRE a surviving branch/path. With Q-B negative + #38287 live, both are REJECTED. The patch in `/tmp` survives auto-removal because it lives OUTSIDE the removable worktree.

### 1.4 Joint mechanism selection (AFFIRMED — property-fit, not precedent)

| Option | Needs Q-A=parent-write? | Needs Q-B=path-returned? | `agents-never-commit`? | Verdict |
|---|---|---|---|---|
| 1 — in-place, no isolation | n/a (parent-tree, non-isolated) | no | PRESERVED | **KEEP as degradation FLOOR / default** |
| 2 — report-write-by-path (all agents) | `/tmp` suffices | no | PRESERVED | **ADOPT (`/tmp` for isolated; parent-tree for in-place)** |
| 3 — RW class commits to throwaway branch | no | YES (branch must survive) | RELAXED | **REJECT** (Q-B negative; relaxation off the table per D5) |
| 4 — patch-file handoff (`git diff` → parent `git apply`) | `/tmp` suffices | no | PRESERVED | **ADOPT as primary RW merge-back** |
| 5 — capture-before-return | no | YES | PRESERVED | **REJECT** (Q-B negative; races #38287) |

Selected: **1 (floor) + 2 (reports, all agents) + 4 (RW code merge-back)** — the only combination that preserves `agents-never-commit`, survives the auto-removal bug, and needs neither a relaxation nor a returned branch. Chosen by PROPERTY-FIT (each unverified dependency removed from the critical path), not because patches are a familiar idiom.

### 1.5 git apply availability
`git --version` → `2.50.1`; `git apply` parses input (`git apply --check /dev/null` → "No valid patches in input", i.e. the verb exists). The Pack-Chat / PM-Chat merge-back primitive is available on the host.


---

## 2. Use-case scope (BD-197 note 6) — PRIMARY / SECONDARY / LOW

The user's note 6 fixes the priority order. The design serves them in this order:

### 2.1 UC-1 / P1 — PRIMARY (the thing to get right)

**Pack Chat + PM Chat spawn agents IN-SESSION, in the BACKGROUND, with opt-in worktree isolation (via the per-spawn Agent-tool `isolation:"worktree"` PARAMETER — the subagent trigger; `bgIsolation` is the SEPARATE background-SESSION gate, BD-218, NOT this trigger) for SAFE PARALLEL read-write agents (coders).** Merge-back is the `/tmp` patch the agent writes before return — **auto-removal-bug-safe** because no branch-with-commits ever exists (agents-never-commit). Read-only background agents need NO isolation (they don't write the tree; they emit one report). This is the full mechanism of §1.4 + §3 + §6.

The "P1 is buggy" concern is RESOLVED (note 6): the platform's worktree auto-removal IS buggy, but the `/tmp`-patch design neutralizes it (work is safe in `/tmp` before removal). The adversarial challenge was to mode-DETECTION (the trigger), not to merge-back safety — and that challenge is now fixed (§3): the subagent trigger is the Agent-tool `isolation:"worktree"` PARAMETER, not a `bgIsolation`/`baseRef` setting (Correction pass 2026-06-14, FACT-5).

### 2.2 UC-secondary / P3-launcher — SECONDARY (support IF FEASIBLE)

**A launcher (`agent-run.sh`-style, extended) that creates a `git worktree` then runs `claude --agent` in it** — human-driven parallel agents, clean STANDARD-GIT merge-back (the human, or the orchestrating chat, merges the worktree branch with ordinary git). Feasibility is assessed honestly in §7. SUMMARY: **feasible pack-side as a NEW thin launcher** (the pack has no `agent-run.sh` today — CLAUDE.md "The pack repo has no `agent-run.sh`"; it would be net-new), and **feasible project-side by extending the existing `project-template/agent-run.sh`**; BUT it is a SEPARATE merge-back path from UC-1 (standard-git, human-driven) and MUST NOT contaminate the UC-1 `/tmp`-patch path. **RESOLVED (BD-197 note 10, user decision NEW-FORK-1=(a) — gate-then-probe-then-degrade):** ship UC-1/P1 first; the P3 launcher is GATED on (a) UC-1 landing AND (b) a cwd-scoping probe (does `claude --agent` launched in a worktree keep its git scoped to that worktree — the #55708 / Gemini #22658 leak class). If the probe fails, the launcher DEGRADES to a documented manual procedure. It does NOT block the UC-1 pipeline — see §7 + §10. This is no longer an open fork.

### 2.3 UC-low / P2-manual — LOW (only if it falls out free)

**Manual human worktree** (developer runs `git worktree add` by hand and works in it). This needs NO pack mechanism — it is plain git. The pack's only obligation is that nothing it ships BREAKS in a manual worktree (covered by the graceful-degradation floor, §8). No dedicated deliverable; documented as a one-liner in OPTIONAL-FEATURES.


---

## 3. Mode detection (CORRECTED 2026-06-14 — TWO INDEPENDENT MECHANISMS; the 9-cell matrix removed)

This section REPLACES BOTH the first design's §2.1 "three documented developer postures + cross-product" narrative AND the earlier reconciliation's "9-cell `bgIsolation`×`baseRef` matrix / `bgIsolation` is the trigger" framing. The empirical probe + official schema (FACT-1..5, §1.1, 2026-06-14) established that isolation is governed by TWO INDEPENDENT mechanisms that do NOT multiply into a single matrix. The first design's "set `baseRef:"head"` → isolated" cell remains FALSE; the reconciliation's "bgIsolation is the subagent trigger" cell is ALSO false (bgIsolation gates background SESSIONS, not subagents — FACT-3/FACT-4).

### 3.1 The two INDEPENDENT mechanisms (FACT-5)

Isolation is NOT one decision over a `bgIsolation`×`baseRef` cross-product. It is two orthogonal mechanisms:

- **Mechanism (A) — SUBAGENT isolation (the BD-197 mechanism).**
  - **TRIGGER:** the per-spawn Agent-tool **`isolation` PARAMETER**. Its ONLY valid value is `"worktree"` (FACT-5). `head`/`none` are SETTINGS values (`baseRef`/`bgIsolation`), NOT parameter values. Pass `isolation:"worktree"` to isolate a subagent; omit it to run in-place. This RESOLVES note-9's "VERIFY exact param" acceptance criterion.
  - **BASE (modifier, not a trigger):** `worktree.baseRef` — enum `["fresh","head"]`, default `"fresh"` (FACT-2). `"fresh"`=branch from origin/<default> (the historical "checks out main" bug); `"head"`=local HEAD (REQUIRED for feature-branch work). `baseRef` only sets WHERE an already-isolated subagent branches; it never decides WHETHER isolation happens. A fresh client ships NO settings file → defaults to `fresh`=origin/main.
  - **NO platform safety net (FACT-4):** the `bgIsolation` gate does NOT apply to subagents — a non-isolated background subagent can write the parent tree freely. So safety rests entirely on (a) always spawning RW agents with `isolation:"worktree"` and (b) the agents-never-commit + destructive-verb ban. RW/RO classification + "RW must be spawned isolated" is therefore LOAD-BEARING (§4.3, §5).

- **Mechanism (B) — BACKGROUND-SESSION isolation (scoped OUT to BD-218).**
  - `worktree.bgIsolation` — enum `["worktree","none"]`, default `"worktree"` (FACT-3) — governs TOP-LEVEL background `claude` sessions via the `EnterWorktree`/`ExitWorktree` flow: `"worktree"` blocks Edit/Write in the main checkout until `EnterWorktree` is called; `"none"` lets background jobs edit the working copy directly. It is NOT a boolean and NOT the subagent trigger. This mechanism is **scoped OUT to BD-218** (Deferred, v11.1, opened 2026-06-14 per user) — referenced here, NOT designed here.

The two mechanisms are independent: BD-197 ships (A); (B) is BD-218. There is no `bgIsolation`×`baseRef` cell-set to enumerate for subagents — `bgIsolation` simply does not participate in subagent isolation.

### 3.2 Per-task control vs persistent posture (D6 + note 9, corrected)

- **The chat controls per-task subagent isolation via the per-spawn Agent-tool `isolation:"worktree"` parameter.** BD-197 UN-PROHIBITS passing it (the current CLAUDE.md prohibition "Do not pass `isolation:"worktree"`" is removed in P2). The chat does NOT control isolation by writing `settings.json` (that conflicts with the no-write-settings constraint AND risks concurrent-session surprises — another chat in the same clone would inherit the write).
- **The user controls the persistent BASE posture via `settings.json`** (`worktree.baseRef:"head"`, manually, documented in OPTIONAL-FEATURES — never written by the pack). Without it, isolated subagents base at `fresh`=origin/main (a documented degradation, §8).
- **note-9 "VERIFY exact param" — RESOLVED (FACT-5):** the param is `isolation:"worktree"`; `head`/`none` are SETTINGS values, NOT param values. No further probe is required; the P3 coder records this confirmed name+value in the IMPL-REPORT.

### 3.3 The runtime ground-truth contract (the only deterministic detection — RETAINED)

Settings do NOT deterministically tell the agent its runtime regime (platform bugs #39886 silent fall-to-MAIN; #59848 misclassification; and the `baseRef`-unset → origin/main base). Therefore the ONLY deterministic detection is the runtime-regime self-detect (UNCHANGED by the 2026-06-14 correction — it never depended on the 9-cell matrix). The coder contract:

1. **Settings are set by the DEVELOPER + documented in OPTIONAL-FEATURES, NOT parsed by the pack at runtime.** The pack ships/parses no settings file. "Settings-driven" means: the developer's `baseRef` choice DETERMINES the base of an isolated run; OPTIONAL-FEATURES documents it so the developer can set `baseRef:"head"` knowingly. Whether isolation happens at all is the per-spawn `isolation` PARAM (Mechanism A), not a setting.
2. **The agent detects its ACTUAL regime at runtime** via a deterministic `pwd`/HEAD check — is `pwd` a `worktree-agent-*` worktree? is HEAD a `worktree-agent-*` branch? — and branches its write-target + handoff on THAT, never on settings values (which it cannot see and which can lie). Neither regime is an error.
3. **The orchestrator detects the regime from what the agent REPORTS** — a `/tmp` patch path ⇒ treat as isolated; in-place working-tree edits ⇒ treat as in-place — never from an assumption about the developer's settings. (For the proven UC-1 path, the Agent tool ALSO returns `worktreePath`+`worktreeBranch` to the orchestrator — FACT-1 — so the orchestrator can read the worktree directly; the `/tmp` patch remains the auto-removal-safe canonical handoff.)

This is strictly more robust than "detect the mode from settings," and is the only version that is deterministic AND coder-implementable.

### 3.4 Do NOT hardcode magic settings values; key on ground truth + the `isolation` param

Define the runtime regime by GROUND TRUTH (a `worktree-agent-*` worktree was actually created → isolated), not by guessing settings values. The subagent isolation DECISION is explicit: the orchestrator passes `isolation:"worktree"` (Mechanism A). OPTIONAL-FEATURES describes `baseRef:"head"` as the REQUIRED base lever and describes the isolated outcome by what appears ("a `worktree-agent-*` checkout") rather than by any magic value. `bgIsolation` is described accurately as the background-SESSION gate with a pointer to BD-218 — never claimed as a subagent control.

## 4. The merge-back model (AFFIRMED) + RW/RO classification (D1+D2)

### 4.1 The RW-agent edit → patch → orchestrator-apply flow (preserves `agents-never-commit`)

The merge-back primitive. IDENTICAL in shape on both surfaces; only the orchestrator name differs (Pack Chat pack-side; PM Chat project-side).

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
   If the /tmp Write FAILS (handoff dir not writable — §1.2 hardening), the
   agent FALLS BACK to the in-place report path and reports the degradation;
   it never hard-errors on a failed handoff Write.
3. The agent returns. Its worktree (if any) may auto-remove — irrelevant: the
   patch + report live in /tmp, outside it.
4. Orchestrator reads <handoff>/IMPL-REPORT.md, runs the bounded review/fix
   cycle (reviewer reads the patch + report), then APPLIES:
        git apply --check <handoff>/changes.patch    # dry-run first
        git apply <handoff>/changes.patch            # orchestrator-only
   and commits with user approval. The ORCHESTRATOR does the only git-state
   change — agents never commit, never stage, never apply.
5. Conflict path: §6.
```

Why this preserves the rule absolutely: `git diff` and `Write` are read-only / non-git operations. The agent performs ZERO git-state changes. Only the orchestrator (always permitted to commit) applies + commits. There is NO committing agent class — Option 3 is not adopted.

### 4.2 The all-agents IMPL-report-back flow (RW and RO)

ALL agents (RW coder AND every RO agent) Write their IMPL/report to the per-spawn path the orchestrator names:
- **In-place regime (default):** the report path is a parent-tree absolute path (today's behavior). Works per Q-A.
- **Isolated regime (opt-in):** the report path is `<handoff>/...` under `/tmp` (Q-A: only `/tmp` escapes). The orchestrator reads it from `/tmp` after return.

Prompt-construction rule: **always name an absolute report path; when isolation is opted-in, that path is under the `/tmp` handoff dir.** One regime-parameterized prompt-template change per surface.

### 4.3 RW/RO classification — triple reinforcement, per surface (D1+D2)

The two-class model is declared INDEPENDENTLY on each surface (separation-of-concerns). There is NO shared cross-surface file.

**PACK side (D1=(a)):**
- **SSOT (index):** extend the `pack-ops/PACK-AGENTS.md` roster with an explicit **`Class` column** (values `RW` / `RO`). A short "## Two agent classes" subsection under `## Agent permission rules`:
  - **RW:** `pack-coder` — Write/Edit source within the caller-scoped file set; emits a patch + report; NEVER runs a state-changing git verb.
  - **RO:** `pack-architect`, `pack-planner`, `pack-reviewer`, `pack-docs-researcher` — Write ONLY their single caller-specified report; read-only on the codebase otherwise.
  - BOTH classes: `agents-never-commit` + full destructive-verb ban (§5) applies identically.
- **Per-agent-file reinforcement** on all 5 pack agent files (×3 CLIs = 15): the prose mandate header (`**Source-write within scope.**` RW / `**Read-only.**` RO).
- **Inline rules-in-force block** in every spawn prompt (existing mechanism).
- **CI guard:** a `validate-pack.py` set-equality check {PACK-AGENTS roster `Class` cells} ↔ {agent-file PROSE mandate headers}. **The validator reads the PROSE header, NEVER `tools:`** — `pack-reviewer` carries `Write,Edit` in `tools:` yet is RO (adversarial §8). Measured set: 1 RW + 4 RO.

**PROJECT side (D2=(a)):**
- **SSOT (human-readable):** the `project-template/docs/pack/PM-CHAT.md` `## Permission profiles` table (14 RO + `coder` + `repo-ops`). Keep as the authored list.
- **Runtime projection (CI-checked):** `agent-run.sh READONLY_AGENTS` becomes a CI-checked PROJECTION of the PM-CHAT table — a `validate-pack.py` set-equality check binding {PM-CHAT RO rows} ↔ {`READONLY_AGENTS` array} ↔ {per-file RO headers}. Today they agree by hand (inventory §1.2) but nothing enforces it. Measured: 14 RO + 2 RW; `READONLY_AGENTS` has exactly the 14.
- **Per-agent-file reinforcement** on all 16 project agent files (×3 CLIs = 48): the prose mandate header (`**Write-capable (scoped).**` / `**Read-only.**`).
- **`repo-ops` placement:** RW with a sub-label "Write-capable (script)" (scripted/generated edits only). NOT a third class — inventing a "scripted-write" class would complicate the validator for no benefit; the agent-file Hard rules already narrow it.
- **Stale-comment fix:** `agent-run.sh` lines ~92–94 "Edit/Write tools are excluded at the agent-definition level" is FALSE for the project side (BD-127 kept Write for reports). P3 corrects it to describe launch-time flag enforcement.

**Surfacing the classes in prompts:** the orchestrator's rules-in-force block already enumerates agent rules inline. P3 adds: every RW-agent spawn names the handoff dir + patch path; every RO-agent spawn names the report path. The class drives the prompt template.

### 4.4 Why isolation is worth enabling (the user's goal)

SAFE PARALLELISM: multiple RW agents editing disjoint scopes simultaneously without trampling each other's working tree. In-place parallelism risks same-tree collisions on concurrent writes; isolation gives each agent its own checkout. The patch-handoff brings the isolated edits back without relaxing the commit ban. Default stays in-place (safe, simple); isolation is the opt-in accelerator.


---

## 5. Git-permission contract (D5 + note 8) — denylist AND read-only-only principle

The user chose **denylist-primary** over allowlist (an allowlist-by-omission risks a non-deterministic agent forgetting a verb), with the **positive principle line as reinforcement** (the catch-all closing the "never told me" gap).

### 5.1 The exact DENIED set (explicit denylist — "including but not limited to")

State-changing git verbs no agent (RW or RO) may run, at any point:

`commit`, `push`, `add` / stage (`add`, `stage`, `add -p`, `restore --staged`), `stash` (all subcommands), `rm`, `mv`, `reset` (all modes), `restore`, `checkout` (incl. `checkout --`, branch switch), `clean`, `merge`, `rebase`, `cherry-pick`, `revert`, `am`, `apply`, `branch -d` / `branch -D` / branch create, `switch`, `worktree` (add/remove/move/prune), `config` (write), `remote` (add/set/remove), `update-ref`, `update-index`, `pull`, `gc`, `reflog expire`, `filter-branch`, `tag` (create/delete), `notes` (write), `replace`, `fetch --prune`-style ref mutations — **including but not limited to** the above.

Note: `git apply` (the patch-APPLYING form) is on the DENIED list for AGENTS (only the orchestrator applies patches). `git diff` is the agent's patch-emit verb and is ALLOWED (read-only).

**Backstop verb-precision (2nd-adversarial G-4, pinned for the coder):** the mechanical backstop MUST be VERB-PRECISE, not pattern-loose. Specifically:
- **Deny the patch-applying `git apply` form** for agents (`Bash(git apply:*)`), but DO NOT deny `git diff` — `git diff` is the agent's load-bearing patch-emit and stays ALLOWED. (`git apply --check` is a read-only dry-run; agents never invoke it — only the orchestrator does — so denying `Bash(git apply:*)` for agents is correct and does not impair the read-only check, which runs on the orchestrator side outside the agent backstop.)
- **`git diff > /tmp/file` is the agent's patch-emit and is ALLOWED.** The `> file` redirection is SHELL-level, not a git verb — the planner/coder MUST confirm the `--disallowedTools` / PreToolUse matcher keys on the git VERB (`diff` allowed, `apply` denied) and is not tripped by the shell redirect. A backstop that denies any `Bash(git …)` not on an allowlist would wrongly block the patch-emit; the design's contract is deny-by-named-verb (the §5.1 denylist), allow otherwise — with `apply` explicitly named in the deny set and `diff` never named.

### 5.2 The exact ALLOWED set (read-only git verbs only)

Read-only git verbs an agent MAY run: `status`, `diff` (incl. `diff > file` redirection — the patch-emit), `log`, `show`, `rev-parse`, `branch` (list only, no `-d/-D/create`), `worktree list` (read-only listing), `ls-files`, `ls-tree`, `cat-file`, `blame`, `describe`, `for-each-ref`, `merge-base`, `rev-list`, `shortlog`, `grep`, `config --get` / `--list` (read), `remote -v` / `remote show` (read), `tag` (list only), `reflog` (read, NOT `expire`), `fsck`, `count-objects`.

**The positive principle line (verbatim shape for the corpus):** *"Read-only git verbs are allowed only; any git verb that changes repository, index, working-tree, ref, or config state is forbidden — including but not limited to the enumerated denylist."* This line closes the gap for any unlisted future verb.

### 5.3 Where it lands (prose + mechanical backstop)

**Prose surfaces (via the PACK-CHAT rule-change propagation procedure):**
- trinity `## Pack memory` `agents-never-commit` bullet ×3 (CLAUDE/AGENTS/GEMINI, pack root) — ADD the enumeration + principle line (today it carries only the catch-all "or any other state-changing git verb").
- `pack-ops/PACK-MEMORY-RATIONALE.md` `## agents-never-commit` — update the verb list + record the principle.
- thin memory-cache pointer (Pack-Chat upkeep).
- references: `PACK-AGENTS.md § Agent permission rules` (one-line; verify still accurate).
- `pack-ops/.spawn-rule-manifest.txt` — verify slug→canonical still resolves.
- commit-discipline skill ×3 (`.claude`/`.codex`/`.gemini`) — verb list (already lists most; add `restore --staged`, `apply`, `worktree`, `clean`, `branch -d/-D`, the principle line).
- `pack-coder` ×3 — verb list reinforcement; **DROP the stale `checkout -- <path>` carve-out** (2nd-adversarial G-4): plain `checkout` of a path is destructive and is in the §5.1 denylist, so the prior pack-coder exception permitting `git checkout -- <path>` MUST be removed (it contradicts D5). Pin this as an enumerate-encoding-surfaces lock-step item: the exact stale carve-out string is excised, not left in place.
- `test-fixtures/manifest.txt` regen (v11-surface touched).

**Order** (per the propagation procedure): corpus (1) → rationale (2) → references (4) + manifest (5) in the SAME commit → cache (3) upkeep → manifest regen (6) last.

**Project-side (separate artifacts):** the project trinity `## Project memory` "No destructive operations" rule + the 48 agent files' Hard rules + Codex `## Permission profile` blocks already mostly enumerate reset/stash; P3 closes any gap surface-by-surface (enumerate-encoding-surfaces).

**Mechanical backstop (adversarial D-NEW-2; RECONCILED to §18.2 — the in-session backstop model).** The §18.2 layer-map is the authoritative resolution; this bullet states it for the §5.3 surface. The pack ships NO settings file and NO new pack-side file (J4 = NO; §18.2 EB-D), so the IN-SESSION mechanical layer is NOT a shipped pack PreToolUse hook:
- **Pack-side (in-session Agent-tool path, BOTH Pack Chat and PM Chat).** The always-on layer is (i) the shipped PROSE deny-list (§5.1/§5.2 — carried in the trinity/skill/agent surfaces below). The in-session MECHANICAL hard-deny is (ii) the **documented-OPTIONAL user-configured `permissions.deny` recipe** — session-scoped + sub-agent-inherited + deny-first per F2 — which the pack DOCUMENTS in OPTIONAL-FEATURES (pack §9 / project §12.3) for the user to add to THEIR OWN `settings.json`; the pack does NOT ship it (§18.2(ii)). A user-configured **PreToolUse hook is SECONDARY defence-in-depth** whose `if`-matcher FAILS OPEN (F2), so `permissions.deny` is the documented-primary mechanical layer and the hook is explicitly secondary — and like `permissions.deny`, the hook is NOT shipped by the pack (the user adds it). Any such recipe/hook is VERB-PRECISE per §5.1 — it names `Bash(git apply:*)` in the deny set but NEVER `Bash(git diff:*)` (the patch-emit stays allowed; confirm the `git diff > file` redirect is not tripped). Pack Chat retains commit ability (a `permissions.deny`/hook the user scopes to agent work, not the chat). **No new shipped pack-side file** (§18.2 EB-D; Check-47 `_SANCTIONED_PACK_SIDE_SHIPPED` frozen).
- **Project-side (LAUNCHER path, layer iii).** The launcher hardening lands in `agent-run.sh` `CLAUDE_READONLY_FLAGS` / `--disallowedTools` (add `Bash(git stash:*)`, `Bash(git reset:*)`, `Bash(git restore:*)`, `Bash(git checkout:*)`, `Bash(git apply:*)`, `Bash(git worktree:*)`, `Bash(git clean:*)`), NOT only in prose — this covers the `claude --agent` launcher path ONLY (NOT the in-session Agent-tool path, which is layer ii). **Reconciliation nuance (adversarial §7):** the shipped `project-template/.claude/settings.json` ALLOWS `"Bash(git add *)"` at the permission layer (for the human/PM). The `agents-never-commit` ban for agents is therefore enforced by the agent Hard rule + `agent-run.sh --disallowedTools` (launcher) + the documented-optional user `permissions.deny` (in-session), NOT by the shipped settings.json. The prose ban and the launch-flag enforcement MUST NOT diverge — the launch flags are an encoding surface (enumerate-encoding-surfaces).

### 5.4 CI guard (verb-enumeration parity — measure-then-bound)
Assert the folded verb set appears in every surface that enumerates the ban (trinity, commit-discipline ×3, pack-coder ×3, project Hard rules, agent-run.sh flags). MAY fold into existing trinity-parity + bijection checks rather than a new check (prefer fewer checks — design-elegance). Measure the current enumeration coverage first; size the assertion to the measured surface set.


---

## 6. Conflict protocol (D3, AFFIRMED + sharpened) + multi-RW atomicity

Conflicts arise when (a) two parallel RW agents' patches touch the same hunks, or (b) a patch was cut against a base the main tree has since moved past. Protocol (orchestrator-run; agents never resolve):

1. **Order + dry-run, atomic per patch.** Apply patches SEQUENTIALLY (never concurrently). For EACH patch, the orchestrator runs the FULL cycle before touching the next: `git apply --check <patch>` → (clean) `git apply <patch>` → review → commit with user approval. **The tree is never left with a half-applied multi-patch set** — each patch is its own atomic check→apply→review→commit unit. Earlier-committed patches are safe; only the failing patch needs recovery.
2. **On `--check` failure (drift or collision):**
   a. **3-way attempt:** `git apply --3way <patch>` (uses blob context to auto-merge non-overlapping drift). If clean ⇒ proceed to review+commit.
   b. **Still conflicting ⇒ STOP and surface to the user.** The orchestrator presents: which two patches collide, the conflicting hunks, and a recommendation: **re-spawn the LATER agent FRESH against current HEAD** with the same scope (a fresh coder per fresh-agent-default) to regenerate a clean patch. The orchestrator does NOT hand-merge conflicting hunks (hand-merging IS a fix; Pack Chat / PM Chat does no fixes; the re-spawned coder regenerates).
3. **`--3way` base-blob caveat (adversarial §4):** `git apply --3way` requires the patch's base blobs to be present in the repo. For a patch cut in an isolated worktree branched at `origin/HEAD` (the `baseRef` unset/`fresh` wrong-base case, §8), `--3way` context may not resolve — those patches may fail `--3way` more often, and the recovery is the same re-spawn (against current HEAD, in-place or isolated @ `baseRef:"head"`). State this so the planner does not treat `--3way` as a guarantee.
4. **Anti-drift hygiene (both chats defensively):** parallel RW agents SHOULD be scoped to DISJOINT file sets by the orchestrator's prompt (the existing file-ownership-boundary discipline). Disjoint scoping makes (a)-class collisions structurally rare; (b)-class drift is handled by `--3way` + re-spawn. Conflict-resolution authority caps at the orchestrator + user, never the agent.

---

## 7. UC-secondary (P3-launcher) feasibility — stated honestly

The user asked for an honest, research-backed feasibility call on the launcher use-case (note 6 SECONDARY: a launcher that `git worktree add` + runs `claude --agent` in it). Assessment:

**Pack-side:** the pack has NO `agent-run.sh` today (CLAUDE.md: "The pack repo has no `agent-run.sh` — that's a project template helper"). A pack launcher would be net-new. Pack agents are invoked via `claude --agent pack-<name>` (separate session) or the Agent tool. A launcher that does `git worktree add <wt> && (cd <wt> && claude --agent pack-coder ...)` is mechanically plausible BUT introduces a SECOND merge-back path (standard-git human-driven) distinct from the UC-1 `/tmp`-patch path. **Launcher HEAD-basing is now PROVEN settings-independent (FACT-1, 2026-06-14):** `git worktree add --detach <path> HEAD` bases at the parent HEAD `ae3d932` DETERMINISTICALLY with zero `baseRef` dependence (unlike the Agent-tool path, which needs `baseRef:"head"`) and the merge-back applies clean. **Feasibility: PLAUSIBLE; HEAD-basing PROVEN, cwd-scoping still UNVERIFIED** — the remaining load-bearing unknown is whether `claude --agent` launched with cwd inside a worktree reliably keeps its git operations scoped to that worktree (the same class of leak as #55708 "subagent git checkout affects parent repo" and Gemini #22658). This MUST be probed at P3 implementation before the launcher is committed.

**Project-side:** `project-template/agent-run.sh` EXISTS and already dispatches `claude --agent` with per-class flags. Extending it with an optional `--worktree` mode (`git worktree add` then run the agent in it, then the human/PM merges with standard git) is the lower-risk launcher path because the merge-back is plain git, human-gated. **Feasibility: FEASIBLE as an additive `--worktree` flag**, gated on the same cwd-scoping probe.

**Honest flag:** the P3-launcher is a SEPARATE merge-back regime from UC-1 and MUST NOT contaminate the UC-1 `/tmp`-patch path. **DECISION — RESOLVED (BD-197 note 10; user-decided NEW-FORK-1=(a) gate-then-probe-then-degrade):** ship UC-1 first; treat the launcher as a P3 sub-deliverable GATED on (a) UC-1 landing AND (b) the cwd-scoping probe passing. If the probe fails (the launched agent's git leaks to the parent), the launcher DEGRADES to a DOCUMENTED MANUAL PROCEDURE in OPTIONAL-FEATURES (developer runs `git worktree add` + `claude --agent` by hand, accepting the platform's behavior) rather than a pack-automated mechanism. It does NOT block the UC-1 pipeline. This is recorded as RESOLVED in §10 (no longer an open fork).

**Pack/project separation nuance (adversarial §7):** `project-template/.claude/settings.json` IS shipped and carries `"Bash(git add *)"` + a PostToolUse hook but NO `worktree` key. Constraint 6 ("ship no settings file for worktree") is satisfied today; **P3 must NOT add a `worktree` key to the shipped template** — the doc tells the developer to add it to THEIR settings, never the shipped file.

---

## 8. Graceful degradation (CORRECTED — complete matrix)

The first design's §2.2 listed the right principles but presented NO exhaustive cell table. Here is the complete table over {regime ground-truth} × {TEAMS on/off}, restated on the corrected model (§3): the regime is set by the per-spawn `isolation:"worktree"` PARAM (isolated) or its absence (in-place), and the BASE of an isolated run is set by `worktree.baseRef` (`head` = parent HEAD; `fresh`/unset = origin/main). "Zero-failure" = the orchestrator finds the work and commits it; nothing is silently lost.

| TEAMS | Regime (GROUND TRUTH) | What the agent does | What the orchestrator does | Failure-safe? |
|---|---|---|---|---|
| off | IN-PLACE (no `isolation` param) | edits parent tree; report to parent path | reads working-tree diff + report; commits | YES (today's model) |
| off | ISOLATED, `baseRef:"head"` (`isolation:"worktree"` param) | edits worktree based at parent HEAD; `git diff` → `/tmp` patch + `/tmp` report | reads `/tmp` patch (also has returned `worktreePath`); `--check`/`--3way`/apply; commits | YES (patch survives auto-removal — FACT-1) |
| off | **ISOLATED, `baseRef` unset/`fresh` (wrong-base = origin/main)** | edits worktree based at origin/main, NOT parent HEAD; `/tmp` patch | reads patch; applies onto parent; **SURFACES the wrong-base caveat** (documented, NOT silent) | YES (patch still applies; degradation is surfaced) |
| off | **ISOLATED-but-silently-fell-to-MAIN (#39886)** | THINKS isolated, actually edited parent tree | self-detect sees in-place regime → behaves as IN-PLACE row | YES (self-detect is ground-truth, not settings) |
| on | IN-PLACE | teammates edit shared tree (file-ownership boundaries) | per-teammate reports; commits | YES (disjoint scope) |
| on | ISOLATED (`isolation:"worktree"` per teammate) | each teammate edits own worktree; `/tmp` patch each | sequential `--check`/apply per patch; conflict protocol §6 | YES if patches disjoint; conflict protocol if not |
| any | **settings drift / platform bug (#59848 misclassification)** | self-detect catches the ACTUAL regime regardless of setting drift | keys merge-back off the agent's REPORT (and returned worktree path), not the setting | YES (the whole point of ground-truth self-detect) |

The cells the first design's narrative did NOT cover — **#39886 silent fall-to-MAIN** and the **`baseRef` unset/`fresh` wrong-base (origin/main)** — are exactly the "no destructive surprises" cases the user named. The wrong-base cell is the DEGRADATION a fresh client lands in (the pack ships NO settings file → `baseRef` defaults to `fresh`=origin/main, FACT-2): the run still functions (the patch applies onto the parent) and the orchestrator SURFACES the wrong-base caveat — it is documented, not silent. Both cells are failure-safe because of the ground-truth self-detect (§3.3), which is therefore load-bearing for degradation, not just for mode-detection. **No settings file is shipped or auto-written at any scope in any cell** — so the SAFE behavior a fresh client gets without the `baseRef:"head"` setting is the documented wrong-base degradation, never silent data loss. (Background-session `bgIsolation` degradation is BD-218's concern, not this table's.)

Codex/Gemini are OUT of scope here (BD-217); their CLIs degrade to native sequential — the trinity-exemption note documents this without claiming parity. (P1 found both now have IMMATURE worktree support — EXISTS-BUT-IMMATURE per verify-availability-not-just-existence — but that is BD-217's problem, not a v11.0 parity claim.)


---

## 9. OPTIONAL-FEATURES.md (both surfaces, separately authored)

Both docs model the existing Agent-Teams opt-in section shape and document ALL mode-setting ways (note 9). NEITHER is a byte-copy; each is authored for its audience.

**Pack** (`pack-ops/OPTIONAL-FEATURES.md`) — new section "## Claude Code — Isolated parallel agents (worktree isolation)":
- **Status / What it is / When it matters.**
- **How to enable isolated parallel subagents (the two mechanisms, §3):**
  - **TRIGGER (per task):** the chat passes the per-spawn Agent-tool `isolation:"worktree"` parameter. This is the chat's per-task control and is the ONLY valid parameter value (`head`/`none` are SETTINGS values, NOT param values). Omit it to run in-place.
  - **BASE (REQUIRED setting):** set `worktree.baseRef:"head"` in `settings.json` so isolated worktrees branch from your LOCAL HEAD (your feature branch). **Consequence if unset:** `baseRef` defaults to `"fresh"` = branch from `origin/<default>` (origin/main) — the historical "checks out main" base; your isolated work would then be based at origin/main, not your branch (still functional but wrong-base — see Caveats). So `baseRef:"head"` is REQUIRED for feature-branch work.
  - **WHERE the `baseRef` setting lives:** `settings.json` at PER-PROJECT scope (`.claude/settings.json`, recommended) OR GLOBAL scope (`~/.claude/settings.json`, affects both pack + project — you choose).
  - **Background sessions (separate, NOT this feature):** `worktree.bgIsolation` (enum `["worktree","none"]`, default `"worktree"`) governs TOP-LEVEL background `claude` sessions via the `EnterWorktree`/`ExitWorktree` flow — it does NOT control Agent-tool subagents. The background-session isolation story is tracked under **BD-218** (v11.1); do not set `bgIsolation` expecting it to isolate subagents.
  - any command-line params (probed at implementation).
- **Caveats:** version-sensitive (#60588), silent-delete (#38287), best-effort, silent fall-to-MAIN (#39886), and the `baseRef` unset/`fresh` wrong-base (origin/main) degradation above.
- **Explicit:** "the pack ships NO settings file; you add these keys to your OWN settings.json."
- **Trinity-exempt note** (Claude-only; Codex/Gemini = BD-217).
- The manual-worktree one-liner (UC-low, §2.3).

**Client** (`project-template/docs/pack/OPTIONAL-FEATURES.md`, confirmed present, 5490 bytes) — the SAME section authored INDEPENDENTLY: client audience (the downstream-project developer), client paths/orchestrator ("PM Chat"), the project `agent-run.sh --worktree` launcher (if §7 feasibility passes) or the manual procedure (if it does not). Separate artifact; not a fallback for the pack version.

**Discoverability:** `/pack-help` + the chats describe the feature when unset (note 9).

---

## 10. Decisions to surface to the user

**D1–D6 are LOCKED (BD-197 note 7) — recorded here for the planner, NOT re-opened:**
- **D1** = pack SSOT = PACK-AGENTS `Class` column (+ per-agent-file reinforcement + inline rules-in-force = triple reinforcement). [§4.3]
- **D2** = project SSOT = PM-CHAT permission-profiles table + `agent-run.sh READONLY_AGENTS` CI-checked projection (+ per-agent-file reinforcement on all 16). [§4.3]
- **D3** = conflict: `git apply --check`/`--3way`, STOP+surface+re-spawn fresh coder on current HEAD, NO hand-merge; disjoint defensive scoping. [§6]
- **D4** = leave the 4 archive dangling-refs (history; no CI impact). [§4 / §4-removal table]
- **D5** = `agents-never-commit` + all destructive git verbs prohibited (NOT relaxed — Option 3/5 rejected; the BD-197 hard-constraint "last-resort exception" is NOT invoked because the patch-handoff fully solves merge-back). [§5]
- **D6** = mode-detection (the DECISION INTENT — "isolation is opt-in, settings-driven, runtime-verified, safe-default-in-place"; the exact mechanism is RE-DOCUMENTED 2026-06-14, §3): TWO INDEPENDENT mechanisms — (A) SUBAGENT isolation triggered by the Agent-tool `isolation:"worktree"` PARAMETER, base from `baseRef` (`head` required, default `fresh`=origin/main); (B) BACKGROUND-SESSION isolation via `bgIsolation`+EnterWorktree → BD-218. VERIFY actual regime at RUNTIME (ground-truth pwd/HEAD); safe default = in-place (no `isolation` param). The original D6 phrasing "trigger is `bgIsolation`" is superseded by the probe/schema (FACT-3/FACT-4); the decision INTENT is unchanged. [§3]

**Adversarial-added decisions (D-NEW-1..4) — INTEGRATED, recorded for traceability:**
- **D-NEW-1 (re-documented 2026-06-14):** adopt the §3 two-independent-mechanisms model + the §3.3 three-point runtime ground-truth contract; the pack does NOT parse settings at runtime; `baseRef` is a base-modifier, never a trigger; the subagent trigger is the `isolation:"worktree"` PARAMETER. (The earlier "§3.3 complete [9-cell] matrix" is removed.) [§3 — integrated]
- **D-NEW-2 (RECONCILED to §18.2, 2026-06-14):** folded verb-hardening lands in (project, launcher) `agent-run.sh --disallowedTools` + (in-session, both surfaces) the documented-OPTIONAL user `permissions.deny` recipe (NOT shipped; a user-configured PreToolUse hook is SECONDARY/fails-open, also NOT shipped) — reconciled against the shipped `settings.json` `git add` allow. The pack ships NO PreToolUse hook and NO settings file (J4 = NO; §18.2 EB-D). [§5.3 / §18.2 — integrated]
- **D-NEW-3 (REVISED by the 2nd-adversarial fix):** the P2 completeness gate is a **prohibition-ONLY absence-gate** (matches the prohibition PROSE only — never the `baseRef`/`bgIsolation` setting-key names, which P3 must legitimately write) PLUS a **separate OPTIONAL-FEATURES presence-check**; the allowlist is MEASURED against the current tree and sized exactly to the LEAVE set; the stale static "3 BD-197-process files" count is DROPPED. (The original D-NEW-3 "regex includes `bgIsolation`" was self-defeating — it forbade the design's own deliverable; corrected here per BD-197 note 10.) [§11.5 / §13.1 — integrated]
- **D-NEW-4:** graceful-degradation acceptance tests the #39886 silent-fall-to-MAIN cell + the TEAMS-on isolated cell, not just happy paths. [§8 — integrated]

**NEW-FORK-1 — RESOLVED (BD-197 note 10, user decision 2026-06-13; NO LONGER an open fork):**
- **NEW-FORK-1 — P3-launcher (UC-secondary) commit-vs-document. RESOLVED = (a) gate-then-probe-then-degrade.** The launcher's load-bearing unknown (does `claude --agent` launched in a worktree keep its git scoped to that worktree? — #55708-class risk) cannot be settled read-only; it needs a P3-time probe. **USER DECISION (a):** ship UC-1/P1 first; gate the launcher on (a) UC-1 landing + (b) the cwd-scoping probe passing; if the probe fails, the launcher DEGRADES to a DOCUMENTED MANUAL PROCEDURE, not a pack-automated mechanism. It does NOT block the UC-1 PRIMARY pipeline. **Evidence:** §7 (pack has no `agent-run.sh`; project `agent-run.sh` extensible; #55708 / Gemini #22658 leak class). The planner carries this as a settled constraint (the launcher is a probe-gated P3 sub-deliverable with a documented-manual fallback), not as an open user call.


---

## 11. P2 — Removal plan (pack-side ONLY; client side carries NO prohibition)

**Scope:** REMOVE the prohibition + all bug-era worktree content from pack-side surfaces. P1 §4.6 confirmed ZERO prohibition in `AGENTS.md`/`GEMINI.md` (root), in any `project-template/` trinity, or any client surface — **P2 is pack-only**; P3 builds the client story net-new (additive).

**Fresh-audit instruction (mandatory before any edit):** the P2 coder re-runs the blast-radius audit at P2-time HEAD with `rg --hidden --no-ignore` across the v11-dev tree AND the main clone, excluding `.git`/`test-fixtures`/`BD-197.md`/the PREWORK file/this doc/the first design/the adversarial review/the two research docs. Line numbers WILL have drifted — re-locate by content. Reconcile counts ≥2 ways (measure-then-bound + researcher-blast-radius).

### 11.1 Disposition table — 13 PRIMARY rule carriers (from P1 §4.3, adversarial §5 confirmed each)

| # | File | Disposition | Notes |
|---|---|---|---|
| 1 | `CLAUDE.md` (root) `### Sub-agent behavior (Claude-only)` worktree bullet | **REPLACE** prohibition with the opt-in model one-liner (pointer to OPTIONAL-FEATURES) | PM-chat/trinity-governed; propagation procedure. Trinity ×3 in lockstep; preserve the trinity-exemption framing for BD-217. |
| 2 | `.claude/skills/commit-discipline/SKILL.md` | **REDESIGN** (regime-detecting; §12.4) | Highest-coupling edit. |
| 3 | `.codex/skills/commit-discipline/SKILL.md` | **REDESIGN** (mirror of #2) | quad/trinity mirror. |
| 4 | `.gemini/skills/commit-discipline/SKILL.md` | **REDESIGN** (mirror of #2) | quad/trinity mirror. |
| 5 | `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` | **UPDATE** the "no worktree isolation" digest to the new model | |
| 6 | `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md` §D | **UPDATE** to enabled model OR annotate superseded | plan doc; P2 architect decides update-vs-annotate. |
| 7 | `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §4.8 + reproductions | **UPDATE/ANNOTATE** | plan doc. |
| 8 | `maintenance-docs/v11-implementation/PLAN-DOC-CONCISION-GUARDRAILS.md` | **UPDATE** "NO worktree isolation" fragment | confirmed at ~line 187 (adversarial §5). |
| 9 | `maintenance-docs/v11-implementation/ARCHITECTURE-BD-196-S1-CORPUS-CLASSIFICATION.md` row #24 | **UPDATE** — excise the stale `L348-357` line-range; reflect the rule change | entry calls out the stale line-range. |
| 10 | `maintenance-docs/v11-research/RESEARCH-CLAUDE-REPOS-SURVEY.md` | **UPDATE** stale caveat + **EXCISE** dangling-ref | DANGLING-REF + UPDATE (7 hits, adversarial §5). |
| 11 | `maintenance-docs/v11-implementation/IMPL-REPORT-BD-214-C5a-BD197.md` | **DISPOSITION** (history — leave) | do not rewrite history. |
| 12 | `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-196-C9.md` | **DISPOSITION** (history — leave) | |
| 13 | `maintenance-docs/v11-implementation/PLAN-DEPLOYMENT-PYTHON-OBSERVABILITY.md` | **VERIFY at P2** then UPDATE/leave | confirm real prohibition vs incidental `baseRef` token. |

### 11.2 ~7 OPERATIONAL-coupling mentions (P1 §4.4) — reconcile WITH the chosen model

FALSE/incomplete under the default-in-place + opt-in-isolated model:
- `.claude/.codex/.gemini/skills/implementation-report/SKILL.md` (×3) — "the worktree is lost," "diff against the worktree base," "SHA unchanged from the worktree base." → **REDESIGN regime-aware:** in-place ⇒ diff against parent base; isolated ⇒ the patch is the persisted `/tmp` artifact.
- `.claude/.codex/.gemini/agents/pack-coder.{md,toml}` (×3) — "makes the file changes in its worktree," "Branch + final HEAD SHA on your worktree." → **UPDATE** to "in its scoped working tree (or isolated worktree when opted-in); emits a patch + report."
- `pack-ops/PACK-CHAT.md` "multiple worktrees on the same clone" — **LEAVE** (concurrent-session ownership rule; benign, still true).

### 11.3 Dangling-ref reconciliation (D4; adversarial §5 corrected count)

The dangling-ref token `feedback_worktree_isolation_broken_from_v11_clone` is a SEPARATE matcher from the prohibition gate (§11.5) — it is the deleted-memory-pointer token, not the prohibition prose. **Do NOT fold it into the prohibition gate; do NOT hard-code a static count here** — the BD-197-process artifact set grows with each design/adversarial pass (measured 6 at this HEAD, will be 6+ once this fix commits). The P2 coder MUST re-MEASURE both matchers at P2-time (fresh-audit instruction, §11) and size each allowlist to its own measured set.
- **BD-197-process allowlist (the dangling-ref token, MEASURED at this HEAD = 6):** `backlog/BD-197.md`, `ARCHITECTURE-BD-197-WORKTREE-ISOLATION.md` (first design), `ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` (this doc), `ARCHITECTURE-BD-197-ADVERSARIAL-REVIEW.md` (1st adversarial), `ARCHITECTURE-BD-197-ADVERSARIAL-REVIEW-2.md` (2nd adversarial), `RESEARCH-BD-197-P1-WORKTREE-ISOLATION.md`. Re-measure at P2-time — do not trust this static enumeration.
- **EXCISE/repoint** the active non-process carriers (measured at P2-time; the prior measurement named `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md`, `RESEARCH-19C-G-ITEMS-VERIFICATIONS.md`, `RESEARCH-CLAUDE-REPOS-SURVEY.md` — re-confirm).
- **LEAVE** the 4 archive refs (D4 — frozen history; no CI impact).
- The entry's "4" is the stale figure; the measured set wins (a pack-chat-only bookkeeping update — done by Pack Chat, not the coder).

### 11.4 4 historical decision-records — DISPOSITION (leave as history; do not rewrite).

### 11.5 P2 completeness gate — SPLIT into a prohibition-ONLY absence-gate + a separate OPTIONAL-FEATURES presence-check (measure-then-bound)

**Why the single combined gate was wrong (2nd-adversarial G-1/G-2, user-approved fix).** The prior gate's regex forbade the tokens `baseRef`/`bgIsolation` — but those are exactly the setting keys P3 MUST write into the enabled-model text + BOTH OPTIONAL-FEATURES docs. A grep-ZERO gate over those tokens would FIRE on the design's own deliverable. That mis-classifies legitimate content as contamination — the exact anti-pattern `ci-guard-measure-then-bound` forbids. The fix: match the CONTAMINATION (the prohibition PROSE) only, and check the legitimate key NAMES with a SEPARATE presence check.

**Gate (a) — PROHIBITION-ONLY absence-gate (the grep-ZERO gate).** P2 coder PREFLIGHT + reviewer both assert: after edits,
```
rg --hidden --no-ignore 'no worktree isolation|Do not pass .*isolation.*worktree' -g '!.git' -g '!test-fixtures'
```
returns ONLY the MEASURED allowlist below. It matches the PROHIBITION PHRASINGS only — it does NOT match the bare setting-key names `baseRef`/`bgIsolation` (those are legitimate post-P3 content, never contamination). The `worktree-agent-` token is checked only in an ASSERTION context by the commit-discipline redesign (§12.4), not by this prohibition gate (it is a legitimate ground-truth probe value, not a prohibition).

**Gate (b) — OPTIONAL-FEATURES presence-check (separate, POSITIVE).** Assert that BOTH OPTIONAL-FEATURES surfaces (`pack-ops/OPTIONAL-FEATURES.md` + `project-template/docs/pack/OPTIONAL-FEATURES.md`) DO mention `bgIsolation` AND `baseRef` after P3 lands (the keys MUST be documented, not forbidden). This is a P3 acceptance check (the keys do not exist in either file pre-P3 — measured below), distinct from the P2 absence-gate.

**Measure-then-bound — the allowlist for gate (a), MEASURED at this HEAD (re-measure at P2-time).**

**Empirical-Evidence Block (prohibition-only matcher, current tree):**
- Command: `rg -l --hidden --no-ignore 'no worktree isolation|Do not pass .*isolation.*worktree' -g '!.git' -g '!test-fixtures'`
- Output (HEAD `3e3159e`, 2026-06-13): **19 files** — 9 archive + 10 active-non-archive. The 10 active:
  - **STRIP (P2 rewrites the prohibition prose → non-matching post-P2):** `CLAUDE.md` (§11.1 row 1, line 325 — the prohibition bullet), `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` (row 5, line 194), `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` (row 7, lines 929/962), `maintenance-docs/v11-implementation/ARCHITECTURE-BD-196-S1-CORPUS-CLASSIFICATION.md` (row 9, line 88 — IF the P2 update strips the old-rule-name row label; if it retains the rule-name as a classification record, this file moves to the KEEP allowlist — P2 architect's update-vs-annotate call decides).
  - **KEEP (allowlist — legitimately carry the prohibition prose post-P2):**
    - history IMPL-REPORT (LEAVE-as-history, row 12): `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-196-C9.md`.
    - BD-197-process artifacts that match the prohibition-only matcher (5): `ARCHITECTURE-BD-197-WORKTREE-ISOLATION.md` (first design), `ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` (this doc), `ARCHITECTURE-BD-197-ADVERSARIAL-REVIEW-2.md` (2nd adversarial), `RESEARCH-BD-197-P1-WORKTREE-ISOLATION.md`, `RESEARCH-BD-197-AGENT-PERMISSION-INVENTORY.md`. (Note: `backlog/BD-197.md`, `ARCHITECTURE-BD-197-ADVERSARIAL-REVIEW.md`, and `IMPL-REPORT-BD-214-C5a-BD197.md` do NOT match the prohibition-only matcher — they reference the topic without reproducing the prohibition prose — so they are NOT in this gate's allowlist; verified by `rg -c`.)
  - **KEEP (archive, frozen — D4):** the 9 `maintenance-docs/archive/v11/*` matches (ARCHITECTURE-CLEANUP-BATCH-19B-V2, IMPLEMENTATION-REPORT-BD-180-FIX-2, IMPLEMENTATION-REPORT-BD-181-PRECONDITION, IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-19b-1, PACK-REVIEW-BD-181-PRECONDITION, PACK-REVIEW-CLEANUP-BATCH-19B-19b-1, PACK-REVIEW-V10.1-BACKPORT, PLAN-BD-175-PHASE-5, PLAN-CLEANUP-BATCH-19B).
- Interpretation: the prohibition-only matcher is sized to the CONTAMINATION; the KEEP allowlist (history IMPL-REPORT + the 5 measured BD-197-process artifacts + the 9 archive files) is the LEAVE set. Post-P2, the 3–4 STRIP files no longer match, so gate (a) runs clean against EXACTLY the measured allowlist.
- Conclusion: **SUPPORTED** that the prohibition-only gate runs clean against the projected post-P2 tree, with the allowlist sized exactly to the measured LEAVE set (no broader). The `baseRef`/`bgIsolation` key names are NOT in this matcher, so the gate cannot fire on P3's legitimate deliverable.

**Empirical-Evidence Block (presence-check baseline, gate (b)):**
- Command: `rg -c 'bgIsolation|baseRef' pack-ops/OPTIONAL-FEATURES.md project-template/docs/pack/OPTIONAL-FEATURES.md`
- Output (HEAD `3e3159e`, 2026-06-13): pack `0`, project `0` (both files exist — 6861 / 5490 bytes — but neither mentions the keys yet).
- Interpretation: the keys are absent pre-P3; gate (b) becomes GREEN only after P3 authors the OPTIONAL-FEATURES sections, confirming the keys are DOCUMENTED.
- Conclusion: **SUPPORTED** — gate (b) is a P3 acceptance check, correctly orthogonal to the P2 absence-gate.

**Re-measure mandate.** Both allowlists are sized to THIS HEAD; line numbers and the process-artifact set drift. The P2 coder re-runs both matchers at P2-time HEAD (fresh-audit instruction, §11) and re-sizes each allowlist to its own measured set — never trusting the static enumerations above. This is the rename-plans-are-measure-then-bound + ci-guard-measure-then-bound contract applied to a removal.

---

## 12. P3 — Implementation plan (rules + mechanism + docs; pack AND client)

P3 builds the enabled model. Additive on the client side (net-new). Pipeline: planner → coder → bounded review/fix per commit.

### 12.1 Rules (trinity `## Pack memory`) — via the rule-change propagation procedure

**(a) Replace the prohibition bullet** (`### Sub-agent behavior (Claude-only)`) with an ENABLE bullet: "Sub-agents run in-place by default (no isolation). A chat MAY opt a subagent into isolated parallel execution by passing the per-spawn Agent-tool `isolation:"worktree"` parameter (the TRIGGER; only valid value); the developer should set `worktree.baseRef:"head"` in settings so the worktree bases at local HEAD (unset/`fresh` bases at origin/main — a documented wrong-base degradation) — see OPTIONAL-FEATURES. When isolation is active, RW agents emit a patch to the named `/tmp` handoff dir and the orchestrator applies it; agents never commit. The agent VERIFIES its actual regime at runtime (pwd/HEAD ground-truth), never trusting settings. `worktree.bgIsolation` governs background SESSIONS only (not subagents) — BD-218. Trinity-exempt (Claude-only; Codex/Gemini = BD-217)." Propagate ×3 trinity + new rationale slug.

**(b) Two-class principle one-liner** in trinity (the PRINCIPLE only; assignment lives in the PACK-AGENTS roster). New rationale slug `agent-two-class-model`. (anti-restate: principle in trinity, assignment in roster.)

**(c) Folded git-permission hardening** (§5.3) — amend the `agents-never-commit` bullet to ENUMERATE the denylist + add the read-only-only principle line; propagate via the ordered surfaces (corpus ×3 → rationale → references → manifest → cache → manifest regen). Project-side gap-closure surface-by-surface (enumerate-encoding-surfaces) INCLUDING `agent-run.sh --disallowedTools`.

### 12.2 Mechanism (the patch-handoff merge-back) — codified WHERE

- **Pack-side:** the merge-back flow (§4.1) codified in `pack-ops/PACK-CHAT.md` (orchestrator procedure: name handoff dir, read patch, `git apply --check`/`--3way`, conflict protocol §6) + the `implementation-report` skill ×3 (the agent's "emit patch + report to handoff dir" step) + `pack-coder` ×3 (the RW-emit step). The commit-discipline skill ×3 redesign (§12.4) carries the regime-detecting preflight. P3 PreToolUse hook + `--disallowedTools` for the mechanical backstop (§5.3).
- **Project-side (net-new):** the same flow authored INDEPENDENTLY into `project-template/docs/pack/PM-CHAT.md` (PM-Chat orchestrator procedure) + `project-template/.{claude,codex,gemini}/agents/coder.*` (the RW-emit step) + `project-template/skills/implementation/SKILL.md` (the regime-aware report step) + `project-template/agent-run.sh` (`--disallowedTools` hardening + optional `--worktree` launcher if §7 feasibility passes). NOT a byte-copy — audience-correct per cross-CLI-reference-normalization (orchestrator is "PM Chat," paths/commands are project-side canonical). **AS-BUILT correction (2026-06-14, BD-197 Note 15(c) / C7a D-1, P-missed-7):** the regime-aware report step landed at the real project SSOT `project-template/skills/implementation/SKILL.md` — there is NO project-side `implementation-report` skill (that name exists ONLY on the pack side); the earlier `project-template/skills/implementation-report/SKILL.md` reference was a pack-style name reached for a project surface, corrected to the project's own report-step SSOT.

### 12.3 Docs — OPTIONAL-FEATURES additive homes (pack + client, separately authored)
Per §9. Pack: new section in `pack-ops/OPTIONAL-FEATURES.md` modeled on the Agent-Teams section shape. Client: the SAME section authored INDEPENDENTLY into `project-template/docs/pack/OPTIONAL-FEATURES.md`. Separate artifacts; not a fallback for each other.

### 12.4 commit-discipline skill ×3 redesign (regime-detecting, NOT regime-asserting)

The skill TODAY hard-asserts the isolated model (`pwd` "Must end in worktree path" + HEAD "Must start with `worktree-agent-`"). In the IN-PLACE regime (no `isolation` param — the default) BOTH are FALSE for a correctly-running agent — proven (FACT-1/FACT-4; a non-isolated agent runs on the parent branch). Redesign:
- **§1 pre-flight — regime-DETECTING, non-fatal in BOTH directions.** Replace the hard asserts with: "Detect your regime: if `pwd`/HEAD indicate a `worktree-agent-*` worktree you are ISOLATED; otherwise IN-PLACE. Neither is an error. Branch your write-target + handoff on the regime." Give the coder the literal branch:
  - `pwd`/HEAD indicate `worktree-agent-*` ⇒ ISOLATED ⇒ code Writes under `pwd`; IMPL-report + `git diff` patch to the named `/tmp` handoff dir.
  - otherwise ⇒ IN-PLACE ⇒ Writes under the parent tree (today's deliverable); report to the named parent path.
  - Neither is an error; never retarget another agent's main checkout (keep the BD-119 C-2 guard as a CAUTIONARY note, NOT a blanket "every Write under pwd").
- **§2 write-target rule — regime-aware** (as above). Keep the absolute prohibition on retargeting another agent's main checkout.
- **§3 git-state-change ban — UNCHANGED in spirit; ensure it carries the §5.1 denylist + the read-only-only principle line** (add `restore --staged`, `apply`, `worktree`, `clean`, `branch -d/-D` if absent).
- **§6 anti-patterns — retire** the "wrote report to /tmp because the worktree write rejected → wrong path" anti-pattern (it is NOW correct isolated behavior); replace with regime-aware guidance.

### 12.5 Graceful degradation (verified, not assumed)
P3 acceptance includes the §8 verification matrix run end-to-end: (no `isolation` param ⇒ in-place), (`isolation:"worktree"` + `baseRef:"head"` ⇒ isolated @ parent HEAD), (`isolation:"worktree"` + `baseRef` unset/`fresh` ⇒ isolated @ origin/main wrong-base, caveat surfaced), (TEAMS on), (TEAMS off), AND the bug cell (#39886 silent-fall-to-MAIN simulated). Each must run a pack agent spawn → report-back with zero failures. Background-session `bgIsolation` cases are BD-218's acceptance, NOT this matrix. Codex/Gemini explicitly out (BD-217); native sequential fallback documented via trinity-exemption without claiming parity.

### 12.6 New CI guards (P3) — measure-then-bound (§13).


---

## 13. New validators / CI guards — measure-then-bound contract

Each guard follows: (1) measure the tree first; (2) categorize every occurrence KEEP/STRIP; (3) fix-recipe per STRIP; (4) size the allowlist to KEEP only; (5) verify clean post-fix. The P3 coder MUST execute steps 1–2 against the real tree before authoring the guard — this design specifies the CONTRACT, not the allowlist contents (which need a measured tree at P3-time). Per CI-check-runtime-compounding: scope each check to the active tree, single whole-tree `rg`, no subprocess-per-entry storm, add a per-check runtime guard.

### 13.1 Guard A — prohibition-stays-removed (flip-block) — PROHIBITION-ONLY (matches §11.5 gate (a))
- **AS-BUILT: realized as `Check 53` (`check_worktree_isolation_prohibition_flip_block`), shipped in C5** (BD-197 Note 15(b); confirmed by `grep` of `scripts/validate-pack.py`).
- **Asserts:** the worktree-isolation PROHIBITION PROSE does not reappear in active pack surfaces.
- **Measure-then-bound:** match the prohibition SIGNATURE ONLY (`no worktree isolation`, `Do not pass .*isolation.*worktree`) — **NEVER the bare setting-key names `baseRef`/`bgIsolation`** (those are legitimate post-P3 content P3 must write; forbidding them defeats the gate — 2nd-adversarial G-1/G-2). KEEP allowlist = the §11.5-MEASURED LEAVE set (the history IMPL-REPORT + the measured BD-197-process artifacts that carry the prohibition prose + archive), re-measured at guard-authoring time. STRIP = anything else (empty post-P2). Sized to the measured KEEP set only — **no static "3 process files" count** (it was stale; measured 5 BD-197-process prohibition-prose carriers + 1 history IMPL-REPORT + 9 archive at this HEAD; re-measure).
- **Runtime:** scope to active tree (exclude archive/test-fixtures), single whole-tree `rg`, per-check runtime guard.

### 13.1a Guard A′ — OPTIONAL-FEATURES presence-check (the separate POSITIVE gate, matches §11.5 gate (b))
- **AS-BUILT: realized as `Check 54` (`check_optional_features_presence`), shipped in C8b** (BD-197 Note 15(b); confirmed by `grep` of `scripts/validate-pack.py`). Note Check 54 lands LAST commit-wise (C8b) despite a lower number than Check 55/56/57 — numbers are assigned at authoring; commit order ≠ number order.
- **Asserts (P3 acceptance):** BOTH OPTIONAL-FEATURES surfaces (`pack-ops/OPTIONAL-FEATURES.md` + `project-template/docs/pack/OPTIONAL-FEATURES.md`) DO mention `baseRef` AND `bgIsolation` AND the `permissions.deny` recipe token — the keys + the in-session backstop recipe are DOCUMENTED, not forbidden. This is the inverse of Guard A: a PRESENCE check on the legitimate key/recipe names, not an absence check. The `permissions.deny`-token assertion is **MANDATED (user-approved 2026-06-14; see BD-197 Note 14; §18.4)**, not an optional architect call.
- **Asserted tokens reconciled to the corrected §9 content + §18.2(ii) (measure-then-bound):** the corrected OPTIONAL-FEATURES content (§9) documents `baseRef` as the REQUIRED base key (`"head"`, with the `fresh`=origin/main consequence) and `bgIsolation` accurately as the background-SESSION gate with a pointer to BD-218 (NOT a subagent control); §18.2(ii) adds the documented-optional `permissions.deny` recipe (the in-session mechanical backstop). So all THREE tokens — `baseRef`, `bgIsolation`, and the `permissions.deny` recipe token — legitimately appear in each file after P3, and the presence-check is sized to EXACTLY those three (the third token = the exact `permissions.deny` recipe string C5/C8a author, RE-MEASURED at C8b commit-time, NOT a broad pattern). The check does NOT assert `bgIsolation` is a subagent trigger — only that the key is documented (in its correct background-session role). It also does NOT require the per-spawn `isolation` param token (that is prose, not a settings key) — the bounded presence-check stays sized to the two settings keys + the one recipe token, no broader.
- **Measure:** baseline at this HEAD = 0 mentions of any of the three tokens in either file (measured §11.5 gate (b): `baseRef`/`bgIsolation` pack 0 / project 0; the `permissions.deny` recipe token also 0 / 0 — none exist pre-P3); the guard turns GREEN only after P3 authors the sections (pack `baseRef`+`bgIsolation`+recipe in C5; project in C8a).
- **Runtime:** six single-file `rg -c` reads (3 tokens × 2 files); trivial.

### 13.2 Guard B — RW/RO declaration consistency (×2, one per surface)
- **AS-BUILT: realized as `Check 52` (Guard-B pack, `check_pack_rw_ro_two_class`, shipped in C3) + `Check 55` (Guard-B project, `check_project_rw_ro_two_class`, shipped in C6b)** (BD-197 Note 15(b); confirmed by `grep` of `scripts/validate-pack.py`).
- **Pack (Check 52):** set-equality {PACK-AGENTS roster `Class` cells} ↔ {agent-file PROSE mandate headers}. **Bind to the PROSE header, NEVER `tools:`** (`pack-reviewer` carries `Write,Edit` yet is RO — adversarial §8). Measure: 5 agents = 1 RW + 4 RO; any mismatch FAILS.
- **Project (Check 55):** set-equality {PM-CHAT RO rows} ↔ {`agent-run.sh READONLY_AGENTS`} ↔ {per-file RO PROSE headers}. Measure: 14 RO + 2 RW; any drift FAILS.
- **Runtime:** single-pass file reads, no per-agent subprocess storm.

### 13.3 Guard C — verb-enumeration parity — REALIZED AS TWO CHECKS (Check 56 pack + Check 57 project)

**Design intent (single conceptual guard):** assert the §5.1 denylist + principle line appears in every surface that enumerates the ban (trinity, commit-discipline ×3, pack-coder ×3, project Hard rules, `agent-run.sh` flags). The design left fold-vs-standalone to the P3 coder (decision 8 / §J3 — prefer folding into an existing parity check; author a standalone check ONLY if folding over-complicates).

**AS-BUILT (reconciled 2026-06-14, BD-197 Note 15(a)/(b) — confirmed by `grep` of `scripts/validate-pack.py`).** Guard-C realized as **TWO standalone checks**, not one, because the measure-then-bound step found the pack and project surface families are structurally different (`ci-guard-design-measure-then-bound` — the same escape hatch that decision 8 sanctions):

- **Check 56 — Guard-C pack (`check_destructive_git_verb_parity`, shipped in C5).** Asserts the FULL §5.1 **28-verb** denylist + the catch-all principle phrase `including but not limited to` across the **10 pack surfaces** that all carry the AGENT ABSOLUTE ban (a closed enumeration): trinity ×3 (`CLAUDE.md`/`AGENTS.md`/`GEMINI.md`), `pack-ops/PACK-MEMORY-RATIONALE.md`, commit-discipline `SKILL.md` ×3, `pack-coder.{md,toml}` ×3. `apply` is INCLUDED (the verb-precise deny; §5.1 G-4 — denied for agents while `git diff` stays allowed).
- **Check 57 — Guard-C project (`check_project_destructive_git_verb_parity`, shipped in C7b).** Asserts a measured **8-verb INTERSECTION** (`checkout, clean, merge, rebase, reset, restore, stash, worktree`) + a **trinity-only catch-all** across the **52 project surfaces** (project trinity ×3 + 48 agent files [16 agents × 3 CLIs] + `agent-run.sh`).

**Why two, not one (the measure-then-bound reason).** The pack surfaces all carry one closed 28-verb absolute ban; the project surfaces are HETEROGENEOUS: the project trinity carries the human/PM "No destructive operations — needs approval" rule (a SUBSET — working-tree/ref mutators only, with the `including but not limited to` catch-all), while the 48 agent files + launcher carry the agent ban as a CLOSED enumeration with no catch-all. So (i) the project-consistent verb set is the measured 8-verb intersection, NOT the 28-verb pack set; and (ii) the catch-all principle phrase is TRINITY-ONLY (asserting it on the agent files / launcher would FALSE-FAIL a legitimately closed enumeration). Folding two different canonical verb sets + a surface-conditional principle-phrase assertion into ONE check would force it to model two structurally-different surface families — over-complication. The C7b coder therefore authored a separate single-responsibility Check 57 (decision 8 escape hatch), so **C7b was PRESENT (not dropped to 11 commits)** — the plan's "may drop to 11 if Guard-C folds" branch did NOT apply. The realized count is 12 commits.

**C7b NIT-1 disposition (BD-197 Note 15(d) — recorded HARMLESS won't-fix).** Check 57's format-agnostic matcher (`_check_57_verb_present`) uses a ≥4-member slash-run branch (`(?:[a-z][a-z-]*/){3,}[a-z][a-z-]*`) to recognize the Codex `Forbidden: a/b/c/d` deny-list shape. That branch can THEORETICALLY false-positive on a benign 4-segment lowercase path (e.g. `docs/pack/changelog/reset` would report `reset` "present"). Disposition: **WON'T-FIX, accepted as harmless** — (i) a false-positive here can only make a surface look MORE compliant, never cause a spurious FAIL; (ii) verified no real surface relies on a benign slash-path to satisfy a verb (the entire slash-only contribution for every canonical verb comes from the 6 legitimate Codex `Forbidden:` lists, nothing else). The risk is purely theoretical at current tree state; anchoring the slash-list to a `Forbidden:`/deny-context token would tighten it, but that is gold-plating, not a defect.

---

## 14. Architect-doc-vs-reality reconciliation

What the FIRST design got wrong, and how this reconciliation fixes it:

- **(FIXED, then RE-CORRECTED 2026-06-14) The mode-detection trigger.** The first design's §2.1 "posture 3" said setting `worktree.baseRef:"head"` opts into isolated parallel — a FALSE cell (`baseRef` is necessary-but-not-sufficient). The first reconciliation corrected this to "`bgIsolation` is the trigger" — but the 2026-06-14 empirical probe + official schema (FACT-3/FACT-4/FACT-5) proved THAT framing ALSO wrong: `bgIsolation` gates background SESSIONS, not subagents. **Final fix:** §3 — TWO INDEPENDENT mechanisms: (A) SUBAGENT isolation is triggered by the Agent-tool `isolation:"worktree"` PARAMETER (base from `baseRef`; `head` required, `fresh`/unset=origin/main); (B) BACKGROUND-SESSION isolation is `bgIsolation`+EnterWorktree → BD-218. The 9-cell `bgIsolation`×`baseRef` matrix is REMOVED (it multiplied two independent axes). The runtime ground-truth self-detect is retained.
- **(FIXED, refined 2026-06-14) The graceful-degradation matrix was incomplete.** The first design listed principles but omitted the #39886 silent-fall-to-MAIN cell. The 2026-06-14 correction replaces the (wrong) `bgIsolation` default-flip cell with the real degradation a fresh client lands in: `baseRef` unset/`fresh`=origin/main (wrong-base, SURFACED not silent — the pack ships no settings file). **Fix:** §8 — the complete table over {regime ground-truth}×{TEAMS}, failure-safe BY the ground-truth self-detect; background-session degradation is BD-218's concern.
- **(FIXED) Multi-RW atomicity under-specified.** The first design implied sequential apply but did not nail the per-patch atomic check→apply→review→commit boundary. **Fix:** §6.1.
- **(FIXED) `/tmp` handoff treated as guaranteed.** **Fix:** §1.2 — a failed handoff Write is a degradation signal, not a hard error (the grant lives in the USER's settings).
- **(FIXED) git-permission hardening missed an encoding surface.** The first design routed hardening through prose + propagation but did not name `agent-run.sh --disallowedTools` (project) or reconcile the shipped `settings.json` `git add` allow. **Fix:** §5.3 (D-NEW-2).
- **(FIXED) P2 completeness gate was self-contradictory + over-broad** (2nd-adversarial G-1/G-2; the prior combined regex forbade `baseRef`/`bgIsolation` — the very keys P3 must write — and carried a stale "3 process files" count). **Fix:** §11.5 + §13.1 — SPLIT into a prohibition-ONLY absence-gate + a separate OPTIONAL-FEATURES presence-check; allowlist re-MEASURED + sized to the LEAVE set; static count dropped (revised D-NEW-3).
- **(FIXED) Parity check could bind to `tools:`.** `pack-reviewer` carries `Write,Edit` yet is RO. **Fix:** §4.3 / §13.2 — bind to the PROSE header.
- **(FIXED) Git-permission backstop was not verb-precise** (2nd-adversarial G-4). **Fix:** §5.1/§5.3 — deny the patch-applying `git apply` form WITHOUT denying `git diff` (the patch-emit) or the orchestrator-side `git apply --check`; confirm the `git diff > file` redirect is not tripped by the matcher; DROP the stale `checkout -- <path>` carve-out from pack-coder ×3 (plain `checkout` of a path is destructive and in the denylist).
- **(RESOLVED) NEW-FORK-1 (P3-launcher commit-vs-document)** was an open user fork last pass; **now RESOLVED = (a) gate-then-probe-then-degrade** (BD-197 note 10). **Recorded:** §2.2 / §7 / §10. It does not block the UC-1 pipeline.
- **(CORRECTION PASS 2026-06-14) The mode model re-documented from empirical probe + official schema.** Reality (the Claude Code 2.1.173 probe matrix + the schemastore `worktree` object, both verified 2026-06-14) forced the two-mechanisms re-documentation above. The background-session axis (`bgIsolation`/EnterWorktree) reality surfaced is scoped OUT to **BD-218** (Deferred, v11.1, opened 2026-06-14) — the cross-reference for the realized-but-deferred axis (architect-doc-reality-reconciliation). See the "Correction pass (2026-06-14)" note near the top of this doc for the full what/why.
- **(PRESERVED, AFFIRMED) The merge-back model (1+2+4), `agents-never-commit` preserved, RW/RO SSOT placement, the conflict ceiling.** These were correct in the first design and independently re-affirmed by the adversarial pass on fresh probes; carried forward unchanged. (UC-1's full pipeline is now ALSO empirically PROVEN end-to-end — FACT-1.)

**Realizes / invalidates / carves-out:**
- This design REALIZES the P1 option space (selects 1+2+4) and records the Q-A/Q-B + the established mode facts (FACT-1..5, §1.1). When P3 lands, the IMPL-REPORT must cross-reference THIS doc (the realized consumer; name file + symbol, never line numbers) per architect-doc-reality-reconciliation.
- This design INVALIDATES the bug-era model in `commit-discipline/SKILL.md` §1/§2/§6 + the operational mentions in `implementation-report`/`pack-coder`; §12.4 + §11.2 name the exact redesign so the reconciliation chain is explicit.
- The BD-197 entry's stale "Codex/Gemini neither support isolation" framing is superseded by P1 §3.2/§3.3 and carved out to **BD-217** (out of scope); the trinity-exemption pattern is kept clean so BD-217 can adapt the same patch-handoff model per-platform.

**Addendum note for the first design:** `ARCHITECTURE-BD-197-WORKTREE-ISOLATION.md` is superseded by this RECONCILED doc; it remains as input/history. Its §2.1 "three postures" model is the FALSE-cell artifact; and the first reconciliation's "9-cell `bgIsolation`×`baseRef` matrix / `bgIsolation`-as-trigger" framing is ALSO superseded — both are corrected to the two-independent-mechanisms model in §3 here (2026-06-14).

---

## 15. Is the design planner-ready?

**PLANNER-READY: YES.** The 2nd-adversarial's SOLE blocker (G-1+G-2 — the self-contradictory, over-broad P2 completeness gate) is FIXED: §11.5 SPLITS the gate into a prohibition-ONLY absence-gate (never forbids the `baseRef`/`bgIsolation` key names) + a separate OPTIONAL-FEATURES presence-check, with the allowlist re-MEASURED against the current tree (Empirical-Evidence Block) and sized to the LEAVE set, and the stale "3 process files" count dropped across §10/§11.3/§11.5/§13.1. The two 2nd-adversarial git-backstop precision flags (G-4) are pinned in §5 (verb-precise `apply`-deny / `diff`-allow; `checkout -- <path>` carve-out dropped). The one open fork (NEW-FORK-1) is RESOLVED = (a) gate-then-probe-then-degrade (BD-197 note 10; §2.2/§7/§10) and no longer needs a user call.

The mode-decision contract is now complete on the CORRECTED model (Correction pass 2026-06-14): §3.1 (two independent mechanisms — subagent `isolation:"worktree"` param × `baseRef`; background-session `bgIsolation` → BD-218) + §3.2 (per-task vs persistent posture; note-9 param RESOLVED) + §3.3 (runtime ground-truth contract) + §3.4 (no-hardcode; key on the param + ground truth). The 9-cell matrix is REMOVED; nothing downstream depended on enumerating it. The other 2nd-adversarial-AFFIRMED items are unchanged: §6.1 (multi-RW atomicity); §8 (complete degradation table, restated on the corrected model); §5.3 (`agent-run.sh` hardening surface); §4.3/§13.2 (parity binds to prose). The merge-back architecture (1+2+4) is sound AND now empirically PROVEN end-to-end (FACT-1); RW/RO placement, P2 plan, and conflict ceiling are affirmed on independent evidence. The 2026-06-14 correction altered ONLY the mode-detection re-documentation, the sections that cited it, and the cross-references — no settled decision (use-case scope, merge-back, RW/RO, git-permission, conflict protocol, the 11-commit sequence, D1–D6) was changed. **The design is planner-ready.**

---

## 16. Rules-Applied Verification Block

**Block A — original reconciliation pass (preserved for audit; this pass did not invalidate it).** The reconciliation-pass verification (agents-never-commit, read-only mandate, Empirical-Evidence Blocks for the §1 probes, fidelity, pack/project separation, measure-then-bound, architect-doc-vs-reality) was recorded COMPLIANT and is unchanged; the targeted edits below did not touch §1, §3, §4, §6, §8, §9, §12 substantive content.

**Block B — this fix pass (2026-06-13 post-2nd-adversarial; the 8 rules-in-force from the calling prompt):**

| # | Rule (as named in prompt) | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | Agents never commit (git read-only only) | Only read-only git verbs run this pass: `git rev-parse HEAD` → `3e3159ee8b5e97bf8775ecf67a76867d28933a3e`, `git rev-parse --abbrev-ref HEAD` → `v11-dev`. All other commands were `rg`/`ls`/`python3` reads. No `add/commit/push/stash/reset/restore/checkout/mv/rm/apply` issued. | COMPLIANT |
| 2 | Read-only mandate (write ONLY the reconciled design doc) | Exactly ONE file written this pass: `maintenance-docs/v11-implementation/ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md`, via in-place `python3` string-replacement (each edit asserted exactly 1 occurrence before replacing). No other file created or edited; the measurement commands were read-only `rg`/`ls`. | COMPLIANT |
| 3 | Edit in place, not rewrite; 16-section map intact | All changes were targeted `old→new` replacements (14 edits, each occurrence-count-asserted), never a rewrite. Section map verified before (16 sections §0–§16) and re-counted after via `rg '^## '` (16 headings: §0–§16 present, unchanged order). No AFFIRMED section (§1/§3/§4/§6/§8/§9 mode-matrix, merge-back, RW/RO, conflict, degradation) altered beyond the named git-backstop precision flags in §5. | COMPLIANT |
| 4 | CI-guard measure-then-bound (new gate measured; allowlist sized to LEAVE set) | §11.5 Empirical-Evidence Block: ran `rg -l 'no worktree isolation|Do not pass .*isolation.*worktree'` → 19 files (9 archive + 10 active); categorized each KEEP/STRIP; allowlist = the measured LEAVE set (1 history IMPL-REPORT + 5 BD-197-process prohibition-prose carriers + 9 archive); post-P2 clean-run projection stated. Presence-check baseline measured (`rg -c bgIsolation\|baseRef` → pack 0 / project 0). | COMPLIANT |
| 5 | Empirical-Evidence Blocks (measurement + state-claims) | §11.5 carries TWO Empirical-Evidence Blocks (prohibition-only matcher + presence-check baseline), each with command + verbatim output + HEAD `3e3159e` + date 2026-06-13 + interpretation + SUPPORTED conclusion. §11.3 records the dangling-ref measured set (6 at this HEAD) with a re-measure mandate. | COMPLIANT |
| 6 | Fidelity (apply ONLY the approved fixes; no re-open of locked/AFFIRMED) | Edits confined to: the P2 gate (§0/§10/§11.3/§11.5/§13.1/§14), the two git-backstop precision flags (§5.1/§5.3/§14), NEW-FORK-1 integration (§0/§2.2/§7/§10/§14), the readiness sections (§15/Status/top Update-log), and §16. D1–D6 LOCKED and all AFFIRMED architectural choices (mode-matrix §3, merge-back §4, conflict §6, degradation §8) untouched. | COMPLIANT |
| 7 | Rules-Applied Verification Block present (per rule: name, quoted evidence, conclusion) | This Block B table; every row carries quoted/measured evidence; no empty cell. | COMPLIANT |
| 8 | PREFLIGHT + STOP-MEANS-STOP | PREFLIGHT line emitted in chat immediately before this finalization (`PREFLIGHT: P2-gate fix + NEW-FORK-1 integrated; gate measured; section map intact; about to finalize`). No parent stop received during the edit pass. | COMPLIANT |

**Block C — correction pass (2026-06-14; mode model re-documented from empirical probe + official schema; the 8 rules-in-force from the calling prompt).** This pass DID substantively re-document §1.1 + §3 (the overturned mode model) and the sections that cited it — distinct from Block B (which preserved §3). Blocks A and B remain as audit history.

| # | Rule (as named in prompt) | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | edit-in-place-not-full-rewrite | All changes were targeted `old→new` `python3` replacements (each asserted exactly 1 occurrence before replacing; 21 edits). NO wholesale rewrite. Section map re-counted after via `grep -c '^## '` = 17 top-level headings (§0 + §1–§16), unchanged order. The only structural change is §3's INTERNAL sub-headings (was §3.1–§3.5 with the 9-cell matrix; now §3.1–§3.4 — a sub-section consolidation INSIDE §3, not a top-level section loss). Before/after top-level map identical. | COMPLIANT |
| 2 | empirical-evidence-blocks | §1.1 carries FIVE Empirical-Evidence Blocks (FACT-1..5), each with source (probe / schemastore URL), verbatim value (the schema enums + descriptions), date 2026-06-14, interpretation, and SUPPORTED conclusion. Repo-state claims (HEAD `ae3d9325...`, branch `v11-dev`) confirmed via `git rev-parse`. No Agent-tool re-probe was run (probing complete). | COMPLIANT |
| 3 | architect-doc-reality-reconciliation | The "## Correction pass (2026-06-14)" note (near top) names what reality (the 2.1.173 probe + schemastore `worktree` object) forced which change; §14 carries a dedicated correction-pass bullet cross-referencing **BD-218** for the scoped-out background-session axis. | COMPLIANT |
| 4 | pack-project-separation-of-concerns | §9 keeps pack (`pack-ops/OPTIONAL-FEATURES.md`) and client (`project-template/docs/pack/OPTIONAL-FEATURES.md`) as SEPARATE, independently-authored, client-native artifacts ("Separate artifact; not a fallback for the pack version" — unchanged). The corrected mode-setting bullets were applied to the PACK section only; the client paragraph's separate-authoring directive is intact. No pack-self concept bled into client content. | COMPLIANT |
| 5 | ci-guard-design-measure-then-bound | §13.1a Guard-A′ asserted tokens reconciled to the corrected §9 content + §18.2(ii): `baseRef` (required key), `bgIsolation` (background-session gate / BD-218 pointer), and the MANDATED (user-approved 2026-06-14; see BD-197 Note 14; §18.4) `permissions.deny` recipe token all legitimately appear in each OPTIONAL-FEATURES file post-P3, so the presence-check is sized to exactly those three tokens (no broader; the third = the exact recipe string C5/C8a author, re-measured at C8b commit-time; the prose `isolation` param is explicitly NOT folded into the bounded check). §11.5 gate (b) baseline (`baseRef`/`bgIsolation` pack 0 / project 0; `permissions.deny` token 0 / 0) unchanged and still valid. | COMPLIANT |
| 6 | no-deferral-without-user-direction | ONLY background-session isolation is deferred — to BD-218 (Deferred, v11.1, user-authorized 2026-06-14; confirmed in `backlog/BD-218.md`). UC-1 subagent isolation + the launcher stay in v11.0; nothing else deferred. The wrong-base degradation is documented in v11.0, not deferred. | COMPLIANT |
| 7 | scope-deliverables-to-the-ask | Focused correction: edits confined to the overturned mode model (§0 decisions 3/7 + change-summary, §1.1, §3, §7 launcher-proof, §8, §9 pack bullets, §10 D6/D-NEW-1, §6.3 row-labels, §12.1a/§12.5, §13.1a, §14, §15, §16, Status, Correction-pass note). Validated sections (§2, §4, §5, §6 protocol, §11 plan, §12.2/12.3) preserved verbatim except sentences stating the wrong mode model. No re-design. | COMPLIANT |
| 8 | agents-never-commit | Only read-only git verbs run this pass: `git rev-parse HEAD` → `ae3d9325889c41f7cba7a4289437cf7a87d04292`, `git rev-parse --abbrev-ref HEAD` → `v11-dev`; all other commands were `grep`/`python3`/`Read`. No `add/commit/push/stash/reset/restore/checkout/mv/rm/apply` issued. Exactly ONE file edited: this reconciled design doc. | COMPLIANT |
| 9 | rules-applied-verification-block | This Block C table; every row carries quoted/measured evidence; no empty cell. | COMPLIANT |

---

## 17. Check 36 manifest carve-out (BD-197 enabling commit)

**This is BD-197's FIRST commit — a `pack-only` commit landed BEFORE C1.** It
adds a one-path scope-neutral carve-out to CI Check 36 so the C6a/C7a/C8a
`project-only` "DATA halves" (§ plan C6a/C7a/C8a) — which edit only
`project-template/` but are FORCED by the `regenerate-manifest-v11-surface`
rule to also stage the pack-side `test-fixtures/manifest.txt` — can carry a
CI-verified `project-only` keyword. Without it, the §11/§13 commit-split plan
(11-commit sequence; user decision 6 "SPLIT over neutral framing") is
internally infeasible: a `project-only` DATA half that stages the manifest
fails Check 36.

### 17.1 The conflict (measured fact)

Two pack rules collide on every project-content commit:

1. **Check 36 (`scope-keyword convention`).** A `project-only` commit's diff
   must contain ONLY project-side paths (`project-template/`,
   `supporting-docs/`); any other path is an offender → gate fails. Symmetric
   for `pack-only` (project-side paths are offenders).
2. **`regenerate-manifest-v11-surface`.** Any commit whose diff touches
   `project-template/`, `scripts/`, `pack-ops/`, or `supporting-docs/` MUST
   regenerate + stage `test-fixtures/manifest.txt` (a PACK-side path) in the
   SAME commit when the manifest diff is non-empty (else `build.sh --verify`
   goes CI-RED on a stale manifest).

A `project-template/`-only content edit changes a v11 fixture's installed-HEAD
SHA → the manifest row changes → the rule FORCES staging the pack-side
`test-fixtures/manifest.txt`. Under current Check 36 that staged manifest is a
`project-only` offender. So the commit can NEITHER be cleanly `project-only`
(Check 36 flags the manifest) NOR omit the manifest (`build.sh --verify` goes
red). The rules are in genuine conflict. This blocks plan rows C6a/C7a/C8a and
will recur for EVERY future project-content commit.

**Empirical-Evidence Block (EB-1 — the conflict is real, current Check 36 flags the manifest):**
- Command: read the `project-only` offender predicate at `scripts/validate-pack.py:4322-4324` + evaluate `_is_project_side_path('test-fixtures/manifest.txt')` against the current module.
- Output (HEAD `ae3d932`, 2026-06-13):
  - Offender predicate (line 4323): `offenders = [p for p in paths if not _is_project_side_path(p)]`.
  - `_PROJECT_SIDE_PATH_PREFIXES` (line 4126): `("project-template/", "supporting-docs/")`.
  - `_is_project_side_path("test-fixtures/manifest.txt")` → `False` (it starts with neither prefix).
- Interpretation: since the manifest path is NOT project-side, the `project-only` predicate marks it `not _is_project_side_path` = `True` ⇒ it is collected as an offender ⇒ Check 36 FAILS a `project-only` commit that stages it.
- Conclusion: **SUPPORTED** — the conflict is real, not hypothetical.

### 17.2 MEASURE 1 — the current Check 36 logic (verbatim)

**Locus.** `scripts/validate-pack.py`: the check function
`check_commit_scope_honesty()` at lines **4264–4349**; the project-side
predicate `_is_project_side_path()` at **4250–4253**; the project-side prefix
constant `_PROJECT_SIDE_PATH_PREFIXES` at **4126**. (Line numbers drift; the
coder re-locates by symbol.)

The two offender branches (verbatim, lines 4312–4331):
```
if is_pack_only:
    offenders = [p for p in paths if _is_project_side_path(p)]
    ...
if is_project_only:
    offenders = [p for p in paths if not _is_project_side_path(p)]
    ...
```
`_is_project_side_path` (verbatim, 4250–4253):
```
def _is_project_side_path(path: str) -> bool:
    # A path is project-side if it lives under one of the project-side
    # path prefixes.
    return path.startswith(_PROJECT_SIDE_PATH_PREFIXES)
```
`_PROJECT_SIDE_PATH_PREFIXES` (verbatim, 4126):
```
_PROJECT_SIDE_PATH_PREFIXES = ("project-template/", "supporting-docs/")
```
The `pack_chat_only` branch (4332–4343) uses a separate predicate
(`_is_pack_chat_only_permitted`) and is OUT OF SCOPE for this carve-out
(scope-deliverables-to-the-ask).

### 17.3 MEASURE 2 — the FULL forced-co-variant set (it is EXACTLY the manifest)

The question the measure-then-bound contract demands: which pack-side files
does a `project-template/`-only CONTENT change FORCE into the same commit?
ONLY the artifact(s) `build.sh --all --clean` regenerates in the *tracked*
tree.

**Empirical-Evidence Block (EB-2 — build.sh regenerates ONLY the manifest in the tracked tree):**
- Command sequence (HEAD `ae3d932`, 2026-06-13; manifest backed up to `/tmp` and restored afterward — no git-state change): `cp test-fixtures/manifest.txt /tmp/...` → `bash test-fixtures/build.sh --all --clean` → `git status --porcelain test-fixtures/ scripts/ project-template/ pack-ops/ supporting-docs/` → restore.
- Output (verbatim): build exit `0`; post-build `git status --porcelain` over all five v11-surface dirs = **EMPTY** (the manifest regenerated to byte-identical content at this HEAD; the built fixture dirs produced ZERO tracked changes).
- Interpretation: the ONLY tracked path `build.sh` writes is `test-fixtures/manifest.txt` (written by `_update_manifest()`, lines 913–933, to exactly `$THIS_DIR/manifest.txt`). Every built fixture dir (`v10-minimal`, `v11-realistic-ot`, `v11-flat-file`, …) is gitignored.
- Conclusion: **SUPPORTED.**

**Empirical-Evidence Block (EB-3 — the gitignore proves the fixture dirs are NOT tracked):**
- Command: `git ls-files test-fixtures/` + `cat test-fixtures/.gitignore`.
- Output (HEAD `ae3d932`, 2026-06-13): tracked under `test-fixtures/` = **8 files** — `.gitignore`, `README.md`, `build.sh`, `manifest.txt`, and the 4-file static snapshot `v11-trinity-marker-prepped/{AGENTS,CLAUDE,GEMINI,README}.md`. The `.gitignore` body: `*` then `!.gitignore`, `!README.md`, `!build.sh`, `!manifest.txt`, `!v11-trinity-marker-prepped/**`.
- Interpretation: everything under `test-fixtures/` is ignored EXCEPT the recipe/manifest and the static snapshot. The build-output fixture dirs are never staged, so they can never be forced into a project-content commit. The static `v11-trinity-marker-prepped/` snapshot is NOT regenerated by `build.sh` (it has no recipe), so a `project-template/` edit never forces it either.
- Conclusion: **SUPPORTED.**

**Empirical-Evidence Block (EB-4 — a project-template edit causally forces the manifest, and the rule names ONLY the manifest):**
- Command: read the `_update_manifest` header comment in `test-fixtures/build.sh` + the `CLAUDE.md` `regenerate-manifest-v11-surface` rule body (lines 547–554).
- Output (verbatim): build.sh comment — *"v11-* row SHAs drift naturally with any pack-product change to v11 surface (template files, scripts, skills, agents, etc.)"*. CLAUDE.md rule — *"Any commit whose diff includes a file under any of these four directories MUST also regenerate `test-fixtures/manifest.txt` … and stage it … when the manifest diff is non-empty."*
- Interpretation: a `project-template/` content edit changes a v11 fixture's installed HEAD → its manifest row → forces `test-fixtures/manifest.txt` to be re-staged. The rule names exactly ONE artifact: `test-fixtures/manifest.txt`. No other manifest, generated index, `_toc.md`/`_index.md`, or lockfile under any v11-surface dir is keyed off `project-template/` content (the per-entry `_toc.md` indices are pack-chat-only-permitted bookkeeping that Pack Chat regenerates for `/backlog//changelog/` edits — NOT triggered by a `project-template/`-only content edit, and not part of the manifest-regen rule).
- Conclusion: **SUPPORTED.**

**Result of MEASURE 2:** the forced-co-variant set is EXACTLY
`{ test-fixtures/manifest.txt }` — manifest-only. The carve-out is sized to
this one path. It is NOT widened to the `test-fixtures/` directory (that dir
holds the static `v11-trinity-marker-prepped/` snapshot — REAL content that
SHOULD count toward scope — and the recipe `build.sh`/`README.md`, which are
real pack-side source); only the single generated `manifest.txt` is
scope-neutral.

### 17.4 DESIGN — the carve-out (precise, one path)

**New constant** (placed beside `_PROJECT_SIDE_PATH_PREFIXES`, ~line 4127),
shown as repo code (`#`-comment form to avoid a docstring delimiter inside
this design block):
```
# Scope-neutral generated artifact(s): auto-generated files that the
# `regenerate-manifest-v11-surface` rule FORCES to co-vary with a v11-surface
# edit on EITHER surface. They carry no surface-specific semantic content, so
# they are permitted in BOTH `project-only` and `pack-only` commits without
# counting as an offender. Sized EXACTLY to the measured forced-co-variant set
# (ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md §17.3): manifest only.
# A hand-edited manifest is independently caught by `build.sh --verify`, so
# admitting it here does NOT let content smuggle past the boundary.
_SCOPE_NEUTRAL_GENERATED_PATHS = frozenset({
    "test-fixtures/manifest.txt",
})
```
**New predicate** (beside `_is_project_side_path`, ~line 4254 — the real code
uses a `"""docstring"""`; rendered here with a `#`-comment to avoid closing
this section's code fence):
```
def _is_scope_neutral_generated(path: str) -> bool:
    # True if `path` is an auto-generated, scope-neutral artifact that the
    # regenerate-manifest rule forces to co-vary with v11-surface edits on
    # EITHER surface (section 17). Such paths are not offenders in either
    # `project-only` or `pack-only` commits.
    return path in _SCOPE_NEUTRAL_GENERATED_PATHS
```
**Both offender branches** filter the carved-out path out of the offender
list (the EXACT edit; lines 4312–4331):
```
if is_pack_only:
    offenders = [
        p for p in paths
        if _is_project_side_path(p)
        and not _is_scope_neutral_generated(p)
    ]
    ...
if is_project_only:
    offenders = [
        p for p in paths
        if not _is_project_side_path(p)
        and not _is_scope_neutral_generated(p)
    ]
    ...
```
The `is_pack_chat_only` branch is UNCHANGED (out of scope). The carve-out is a
single exact-string set-membership predicate — it admits ONLY
`test-fixtures/manifest.txt`; every other non-matching path remains an
offender in both branches.

**Why a set-membership carve-out, not a `test-fixtures/` prefix.** A prefix
carve-out would also exempt the static `v11-trinity-marker-prepped/` snapshot
and the recipe/README — real pack-side content that SHOULD count toward scope
(pack-project-separation-of-concerns). The frozenset of exactly one path
keeps the carve-out sized to the measured generated set (measure-then-bound:
no broader, no narrower).

### 17.5 VERIFY — the guard is NOT weakened

- **(a) A genuinely cross-surface commit still FAILS.** A `project-only`
  commit whose diff = `project-template/docs/pack/PM-CHAT.md` (project) +
  `scripts/validate-pack.py` (real pack source) + `test-fixtures/manifest.txt`
  (carved-out): the carve-out removes only the manifest from the offender
  list; `scripts/validate-pack.py` is still `not _is_project_side_path` AND
  `not _is_scope_neutral_generated` ⇒ STILL an offender ⇒ Check 36 FAILS.
  Symmetric for a `pack-only` commit that touches a real `project-template/`
  file — that file is still flagged. The meaningful guarantee (any OTHER
  cross-surface path is an offender) is intact.
- **(b) The carve-out cannot smuggle content.** `test-fixtures/manifest.txt`
  is a per-fixture checksum list — 6 data rows of `<fixture-name>  <sha>` + 4
  comment/format lines at this HEAD; it carries NO surface-specific semantic
  content, only hashes. A hand-edited manifest (rows that do NOT match the
  freshly-built fixtures) is independently caught by
  `bash test-fixtures/build.sh --verify` (the `_verify_manifest` path, build.sh
  ~line 937), which is wired into CI. So admitting the manifest to Check 36
  does not create a content-smuggling channel: the only legitimate manifest is
  the build-faithful one, and any other is caught by a different gate.
- **(c) The restored-split is feasible.** With the carve-out, a `project-only`
  commit = `project-template/` content (project-side, not an offender) + the
  carved-out `test-fixtures/manifest.txt` (carved out, not an offender) ⇒
  Check 36 GREEN; and because the staged manifest is the build-faithful
  regeneration, `build.sh --verify` is GREEN. Both gates pass on the same
  commit. This is exactly what C6a/C7a/C8a need.

**Empirical-Evidence Block (EB-5 — the not-weakened claim, verified against the projected patched predicate):**
- Command (HEAD `ae3d932`, 2026-06-13): a Python micro-evaluation importing the current module and applying the PROJECTED `project-only` predicate `[p for p in paths if not _is_project_side_path(p) and p not in {"test-fixtures/manifest.txt"}]` against two path-sets — S1 = `["project-template/docs/pack/PM-CHAT.md", "test-fixtures/manifest.txt"]` (the C6a/C7a/C8a shape); S2 = `["project-template/docs/pack/PM-CHAT.md", "scripts/validate-pack.py", "test-fixtures/manifest.txt"]` (a real cross-surface offender).
- Output (verbatim): S1 → offenders `[]` (GREEN — the restored split passes). S2 → offenders `["scripts/validate-pack.py"]` (FAILS — the real pack source still caught). The existing `_is_project_side_path` returns `True` for `project-template/...`, `False` for `scripts/...`, `False` for `test-fixtures/manifest.txt`.
- Interpretation: the carve-out admits the manifest in S1 (split feasible) while STILL flagging `scripts/validate-pack.py` in S2 (guard not weakened). Exactly the measure-then-bound outcome: sized to the one generated path, every other cross-surface path still an offender.
- Conclusion: **SUPPORTED.**

### 17.6 SPECIFY — the test update (enumerate-encoding-surfaces; lockstep)

**Encoding surfaces that change in lockstep:** (1) the check source
`scripts/validate-pack.py` (§17.4); (2) its test
`scripts/tests/test-validate-pack-checks-36-37-38.sh`. Both change in the
SAME commit (the first BD-197 `pack-only` commit).

**Test file:** `scripts/tests/test-validate-pack-checks-36-37-38.sh`.

**Group 0 (module-registration) addition:** add `_is_scope_neutral_generated`
to the `required` symbol list (lines 43–53) so the new predicate is asserted
present (mirrors how `_is_project_side_path` is asserted there).

**Group 1 (scope-rule unit tests) NEW cases** — add to the Group-1 Python
block (after the `assert_pside` block, ~line 172), exercising the carve-out at
the PREDICATE level + the OFFENDER level:
- **NC-1 — predicate admits the manifest:**
  `_is_scope_neutral_generated("test-fixtures/manifest.txt")` is `True`.
- **NC-2 — predicate rejects a non-carved pack path:**
  `_is_scope_neutral_generated("scripts/validate-pack.py")` is `False`.
- **NC-3 — predicate rejects a sibling test-fixtures path (no prefix widening):**
  `_is_scope_neutral_generated("test-fixtures/v11-trinity-marker-prepped/CLAUDE.md")`
  is `False` AND `_is_scope_neutral_generated("test-fixtures/build.sh")` is
  `False` (proves the carve-out is exact-string, not a `test-fixtures/` prefix).
- **NC-4 — `project-only` commit = project content + manifest PASSES:** build
  the projected offender list with the patched comprehension over
  `["project-template/docs/pack/PM-CHAT.md", "test-fixtures/manifest.txt"]`
  and assert it is empty.
- **NC-5 — `pack-only` commit = pack content + manifest PASSES:** offender
  list over `["pack-ops/PACK-CHAT.md", "test-fixtures/manifest.txt"]` with the
  patched `pack-only` comprehension (`_is_project_side_path(p) and not
  _is_scope_neutral_generated(p)`) is empty.
- **NC-6 — real cross-surface offender STILL FAILS:** offender list over
  `["project-template/docs/pack/PM-CHAT.md", "scripts/validate-pack.py",
  "test-fixtures/manifest.txt"]` with the patched `project-only` comprehension
  = `["scripts/validate-pack.py"]` (non-empty ⇒ the guard still fires).

These cases assert BOTH directions the task requires: (i) a `project-only`
commit including the manifest PASSES (NC-4); (ii) a `pack-only` commit
including it PASSES (NC-5); (iii) a real cross-surface offender still FAILS
(NC-6); plus the exactness controls (NC-1..3). The Group 4 end-to-end
(`validate-pack.py` exits 0 on HEAD) continues to gate the integration.

### 17.7 Runtime (ci-check-runtime-compounding)

The carve-out adds ONE `frozenset` membership test per offender candidate
inside the existing list comprehension — O(1) per path, on a path-set that is
already materialized (`_commit_paths`). No new subprocess, no per-entry storm,
no whole-tree scan; Check 36 still walks only the commits in its range
(default = HEAD only). Added cost is negligible and does not compound across
the 186 validate-pack invocations in the battery.

### 17.8 Bottom line

**With this carve-out, project-content commits can be cleanly `project-only`
(content + carved-out `test-fixtures/manifest.txt`) → the Decision-6 split
(plan rows C6a/C7a/C8a; user decision 6, SPLIT over neutral framing) is
restored.**

## 18. In-session spawn symmetry + unified backstop (BD-197 scope correction, 2026-06-14)

**What forced this section (architect-doc-reality-reconciliation).** A user-caught
gap: BD-197's PRIMARY use case (§2.1, UC-1) is the orchestrator chat spawning
sub-agents **IN-SESSION via the Agent/Task tool** with `isolation:"worktree"` +
`/tmp`-patch merge-back — for **BOTH Pack Chat (pack) AND PM Chat (project)**. The
plan under-scoped the PROJECT side: `project-template/docs/pack/PM-CHAT.md`
documents agent spawning ONLY via `agent-run.sh` flag profiles (the SECONDARY
launcher) — it carries NO in-session Agent/Task-tool spawn instruction (measured
§18.E EB-A). And the in-session destructive-git-verb BACKSTOP was treated as
"solved by `agent-run.sh --disallowedTools`," which covers only the LAUNCHER; the
in-session Agent-tool path (both surfaces) has no `--disallowedTools` and needs its
own backstop story. This section corrects/extends THREE items — (a) in-session spawn
symmetry pack↔project, (b) a unified in-session backstop model, (c) the §2.1 scrub —
on the verified facts F1–F5 in `RESEARCH-BD-197-INSESSION-BACKSTOP.md` (HEAD
`05ad61b`, 2026-06-14). It changes NO validated decision (use-case scope §2, merge-back
§4, RW/RO §4.3, conflict §6, degradation §8, D1–D6, the 12-commit sequence). It only
makes the PROJECT in-session path explicit (symmetric to pack) and pins the in-session
backstop the research established.

**F1–F5 (cited; design ONLY on these — do not re-research).** From
`RESEARCH-BD-197-INSESSION-BACKSTOP.md` (GA, verified 2026-06-14):
- **F1.** Agent-definition frontmatter `tools:`/`disallowedTools:` is TOOL-NAME-level
  only — it CANNOT deny a specific Bash git verb (cannot deny `git commit` while
  allowing `git diff`). The in-session mechanical deny CANNOT come from agent files.
- **F2 (decisive).** `permissions.deny` (e.g. `Bash(git commit:*)`) is SESSION-SCOPED
  and INHERITED by sub-agents (incl. background); PreToolUse hooks FIRE inside
  sub-agent calls. ONE user-configured `permissions.deny` block mechanically covers
  ALL in-session sub-agents on a surface. PreToolUse `if`-matchers FAIL OPEN →
  `permissions.deny` is the authoritative hard-deny layer; a hook is secondary.
- **F3.** The pack ships NO settings file (hard constraint). So the in-session
  mechanical backstop is USER-ACTIVATED: the pack DOCUMENTS a `permissions.deny`
  recipe (in OPTIONAL-FEATURES) for the user to add to THEIR settings; out-of-box,
  only the always-on PROSE deny-list + agents-never-commit behavior apply. This
  "prose (shipped) + documented-optional user `permissions.deny` (not shipped)" model
  is VIABLE and is the answer — **NO new shipped pack-side file is needed (J4 = NO).**
- **F4.** The launcher backstop is `claude --agent … --disallowedTools
  'Bash(git <verb>:*)'` (one rule per verb; GA; project `agent-run.sh` already uses it
  for commit/push — extend to the full §5.1 verb set).
- **F5.** WorktreeCreate/WorktreeRemove hooks fire on worktree lifecycle, NOT on
  git-verb attempts — NOT usable to enforce the ban.

### 18.1 (a) In-session spawn symmetry (pack ↔ project)

**Pack-side status (PACK-CHAT.md) — IN-SESSION spawn is NOT yet documented; C4 adds it.**
PACK-CHAT.md TODAY documents delegation to pack agents via the Task tool for "focused
bounded questions" (`## Behavioral rules` → "Delegate to pack agents when appropriate")
and a separate-terminal `claude --agent` path, but it does NOT document the in-session
`isolation:"worktree"` + RW/RO + background + `/tmp`-patch merge-back contract
(measured §18.E EB-B: zero `isolation`/`/tmp`/handoff/merge-back hits in PACK-CHAT.md).
That contract is the §12.2 pack-side deliverable codified in C4 ("the merge-back flow
(§4.1) codified in `pack-ops/PACK-CHAT.md`"). **So C4 is the commit that ADDS the
pack-side in-session spawn treatment** — this section makes explicit that C4's
PACK-CHAT.md edit is the orchestrator IN-SESSION spawn procedure (not only the
post-return apply procedure): it must state that Pack Chat spawns RW agents (coders)
IN-SESSION via the Agent tool with `isolation:"worktree"`, RO agents without
isolation, in the background, and names the per-spawn `/tmp` handoff dir. The
merge-back/apply half (§4.1 steps 3–5, §6 conflict) is the same C4 edit. The plan's
C4 scope already lists PACK-CHAT.md — this is a CONTENT clarification, not a new commit.

**Project-side gap (PM-CHAT.md) — MUST be added, SYMMETRIC, client-native.** PM-CHAT.md
must document, for PM Chat, the SAME in-session spawn model the pack side gets — authored
CLIENT-NATIVE ("PM Chat", client paths, the project agent roster), NOT a byte-copy of
PACK-CHAT.md (pack-project-separation). Specifically, a new in-session-spawn subsection
(natural home: alongside `## Permission profiles`, where the only spawn mechanism today
is the per-profile `agent-run.sh` flag block) must state:

1. **Two spawn paths, both documented.** (i) PRIMARY — IN-SESSION via the Agent/Task
   tool from PM Chat (symmetric to Pack Chat); (ii) SECONDARY — the existing
   `agent-run.sh <cli> --agent <name>` launcher (the human-driven path the
   `## Permission profiles` flag blocks already describe). The launcher remains the
   documented secondary path; the in-session path is the new primary.
2. **`isolation:"worktree"` for RW agents only.** PM Chat spawns the RW agent
   (`coder`; `repo-ops` is RW-script) IN-SESSION with the Agent-tool `isolation:"worktree"`
   parameter (the subagent trigger; only valid value); RO agents (the 14 read-only
   profiles) are spawned WITHOUT isolation (they don't write the tree — they emit one
   report). This keys off the `## Permission profiles` RW/RO classification already in
   PM-CHAT.md (the project SSOT, D2) — RW ⇒ isolate; RO ⇒ in-place.
3. **Background spawning.** Spawn in the background so PM Chat stays interactive (the
   client-native analog of the pack-side default-background rule; client-native phrasing
   per cross-CLI-reference-normalization — no pack-self `run_in_background` rule citation).
4. **The orchestrator `/tmp`-patch merge-back.** PM Chat names a per-spawn absolute
   `/tmp` handoff dir + the IMPL-report path + the patch path; the RW agent (isolated or
   in-place) edits, runs in-scope verification, emits a read-only `git diff` patch +
   writes its report to the handoff dir, and returns; PM Chat reads the report, runs the
   review/fix cycle, `git apply --check`/`--3way`, applies, and commits with developer
   approval — the agent performs ZERO git-state changes (agents-never-commit). This is
   §4.1 authored client-native (orchestrator = "PM Chat"; the project's own merge-back
   procedure, NOT a reference to the pack flow).
5. **Conflict + degradation** point at the project's own §6/§8 client-native homes (the
   PM-CHAT merge-back procedure + project OPTIONAL-FEATURES) — no pack-self references.

**Symmetry, not copy.** The pack and project in-session spawn treatments express the
SAME mechanism (Agent-tool `isolation:"worktree"` for RW, background, `/tmp`-patch
merge-back) but are SEPARATE artifacts authored for their own audiences — Pack Chat /
pack agents / `pack-ops/` paths on one side; PM Chat / project agents / client paths on
the other. Neither is a fallback for the other (pack-project-separation-of-concerns).
The plan already routes PM-CHAT.md through C7a (§12.2 project: "the same flow authored
INDEPENDENTLY into `project-template/docs/pack/PM-CHAT.md`"); this section makes explicit
that C7a's PM-CHAT.md content MUST include the in-session Agent-tool spawn instruction
(paths 1–5 above), not merely the post-return merge-back procedure — closing the
under-scope.

### 18.2 (b) Unified in-session backstop model (both surfaces) + launcher

The destructive-git-verb ban for in-session sub-agents (both Pack Chat and PM Chat
spawns) is enforced by THREE layers, derived from F1–F5. F1 establishes the layer that
does NOT exist (no per-agent-file or per-spawn mechanical verb-deny), so the model rests
on the session-level layers + prose.

**(i) Always-on PROSE deny-list — OUT-OF-BOX (shipped).** The §5.1 verb set + the §5.2
read-only-only principle line, carried in:
- PACK side: the trinity `## Pack memory` `agents-never-commit` bullet ×3, the
  commit-discipline skill ×3, `pack-coder` ×3, PACK-MEMORY-RATIONALE, PACK-AGENTS
  reference (§5.3 prose surfaces — already the plan's C2/C4 scope).
- PROJECT side: the project trinity `## Project memory` "No destructive operations"
  rule ×3, the 48 agent-file Hard rules + Codex `## Permission profile` blocks, the
  project commit-discipline/implementation-report skills (§5.3 project — already the
  plan's C7a scope).
This is the LOAD-BEARING default: with no user settings, this prose + the
agents-never-commit behavioral contract are the ONLY active deny layers for in-session
sub-agents (F3 honest limit). It is shipped; it covers BOTH spawn paths because the
agents read it regardless of how they were launched.

**(ii) DOCUMENTED-OPTIONAL user-configured `permissions.deny` recipe — the in-session
mechanical hard-deny (NOT shipped; user-activated).** Per F2, ONE `permissions.deny`
block in the user's own `settings.json` (user or project scope) listing the §5.1 verbs
as scoped Bash rules (e.g. `"Bash(git commit:*)"`, `"Bash(git push:*)"`,
`"Bash(git add:*)"`, `"Bash(git reset:*)"`, `"Bash(git restore:*)"`,
`"Bash(git checkout:*)"`, `"Bash(git apply:*)"`, `"Bash(git worktree:*)"`,
`"Bash(git clean:*)"`, …) is SESSION-SCOPED and INHERITED by ALL in-session sub-agents
(including background ones) and is deny-first (not bypassed by `bypassPermissions`). This
is the authoritative hard-deny for the in-session Agent-tool path — the ONLY in-session
mechanical layer (F1: agent files cannot do verb-granular deny; no per-spawn param). The
pack DOCUMENTS this recipe in OPTIONAL-FEATURES (pack + project, separately authored,
client-native), NOT a shipped settings file. A PreToolUse hook (matcher `Bash`,
returning `permissionDecision:"deny"` for the §5.1 verbs) is noted as a SECONDARY
defence-in-depth option — but its `if`-matcher FAILS OPEN (F2), so `permissions.deny` is
the documented-primary mechanical layer and the hook is explicitly secondary. **WHERE it
lands:** an addition to BOTH OPTIONAL-FEATURES isolation sections (§9 / §12.3) — the
PACK section in `pack-ops/OPTIONAL-FEATURES.md` (plan C5) and the CLIENT section in
`project-template/docs/pack/OPTIONAL-FEATURES.md` (plan C8a), each authored for its
audience. This is additive to the existing OPTIONAL-FEATURES content the plan already
specifies for C5/C8a; it documents the optional in-session mechanical backstop alongside
the `baseRef`/`bgIsolation` mode-setting content.

**(iii) Launcher `--disallowedTools` — the LAUNCHER mechanical backstop (project
`agent-run.sh`).** Per F4, the launcher path (`claude --agent <name>` run by
`agent-run.sh`) is hardened with `--disallowedTools` carrying one scoped
`Bash(git <verb>:*)` rule per §5.1 verb. The project `agent-run.sh` already passes
`Bash(git commit:*)`/`Bash(git push:*)` (+ `add`/`mv` in the per-profile flag blocks);
C7a extends it to the full §5.1 set (`stash`, `reset`, `restore`, `checkout`, `apply`,
`worktree`, `clean`, …) — VERB-PRECISE: deny `Bash(git apply:*)`, NEVER `Bash(git diff:*)`
(the agent's patch-emit; §5.1/§5.3 G-4). This layer is INDEPENDENT of the in-session
path (it covers `claude --agent` launches only) and is ALREADY in §5.3 / plan C7a.

**Layer-to-path map (the gap this closes).**

| Spawn path | Layer (i) prose | Layer (ii) `permissions.deny` (optional) | Layer (iii) `--disallowedTools` |
|---|---|---|---|
| IN-SESSION Agent-tool (Pack Chat) | YES (shipped) | YES, if user configures (F2 inheritance) | N/A (not a launcher) |
| IN-SESSION Agent-tool (PM Chat) | YES (shipped) | YES, if user configures (F2 inheritance) | N/A (not a launcher) |
| LAUNCHER `claude --agent` (project `agent-run.sh`) | YES (shipped) | (also inherited if configured) | YES (project `agent-run.sh`, C7a) |

The pre-correction model wrongly assumed `--disallowedTools` covered the in-session path;
the corrected model: the in-session path's mechanical layer is (ii) (`permissions.deny`,
F2), documented-optional; (iii) covers only the launcher. Both spawn paths always carry
(i) the shipped prose.

**J4 = NO new shipped pack-side file.** Per F3, the in-session backstop is "shipped prose
+ documented-optional user `permissions.deny`." None of the three layers introduces a NEW
shipped pack-side file: (i) edits EXISTING prose surfaces; (ii) is DOCUMENTATION in
EXISTING OPTIONAL-FEATURES files (the user authors the actual `settings.json`, which the
pack never ships — BD-197 hard constraint); (iii) edits the EXISTING project
`agent-run.sh`. Therefore the frozen Check-47 `_SANCTIONED_PACK_SIDE_SHIPPED` allowlist
(`{scripts/lib/detect.sh, scripts/pack-help.sh}`) is UNTOUCHED — no architect+user
sign-off for a new shipped file is required (dependency-direction-placement). If any
future implementer finds a layer that WOULD need a new shipped pack-side file, that is a
STOP-and-escalate (architect + user sign-off + Check-47 allowlist growth) — but the F1–F5
model does not.

### 18.3 (c) §2.1 stale-residue scrub (applied this pass)

The §2.1 UC-1 paragraph still framed isolation as "(via `bgIsolation`)" — WRONG per the
2026-06-14 Correction pass (the subagent trigger is the `isolation:"worktree"` PARAMETER;
`bgIsolation` is the background-SESSION gate → BD-218). Applied in §2.1:
- Line 145: "opt-in worktree isolation (via `bgIsolation`)" → "opt-in worktree isolation
  (via the per-spawn Agent-tool `isolation:"worktree"` PARAMETER — the subagent trigger;
  `bgIsolation` is the SEPARATE background-SESSION gate, BD-218, NOT this trigger)".
- Line 147: "(which setting triggers isolation)" → "(the trigger)" + an explicit
  clarifier that the subagent trigger is the `isolation:"worktree"` PARAMETER, not a
  `bgIsolation`/`baseRef` setting (FACT-5).

A whole-design re-grep for residual `bgIsolation`-as-subagent-trigger phrasing
(`isolation \(via .?bgIsolation`, `which setting triggers isolation`,
`bgIsolation.*trigger` / `trigger.*bgIsolation` as an assertion) returns ZERO active hits
post-scrub (§18.E EB-C). Every other `bgIsolation` mention in the design correctly
describes it as the background-SESSION axis (BD-218) or explicitly labels the old framing
as superseded (the Correction-pass note, §3, §10 D6, §14) — those are NOT residue and are
LEFT intact (architect-doc-reality-reconciliation: the supersession record stays).

### 18.4 Commit-scope implications for the planner (C4 / C5 / C7a / C8a)

This section adds NO new commit. It SHARPENS the CONTENT of four already-planned commits.
The planner re-plans the content scope; the commit sequence (C0–C8b) is unchanged.

- **C4 (pack; `pack-only`).** Its PACK-CHAT.md edit MUST be the IN-SESSION orchestrator
  spawn procedure, not only the post-return apply procedure: Pack Chat spawns RW agents
  IN-SESSION via the Agent tool with `isolation:"worktree"`, RO agents without isolation,
  in the background, naming the `/tmp` handoff dir (§18.1 pack-side). The §5.3 prose
  deny-list (layer i) is already C2/C4 scope — unchanged. No new pack-side file (J4=NO).
- **C5 (pack OPTIONAL-FEATURES; `pack-only`).** The pack OPTIONAL-FEATURES isolation
  section gains the layer-(ii) `permissions.deny` recipe as the documented-optional
  in-session mechanical backstop (§18.2(ii)), authored alongside the `baseRef`/`bgIsolation`
  mode-setting content already specified. Note the PreToolUse hook as secondary
  (fails-open). This is additive prose in the EXISTING file — no shipped settings file.
- **C7a (project; `project-only`).** Its PM-CHAT.md edit MUST include the in-session
  Agent-tool spawn instruction (§18.1 paths 1–5: two spawn paths documented;
  `isolation:"worktree"` for RW only; background; `/tmp`-patch merge-back; client-native;
  conflict/degradation point at project homes) — symmetric to C4's pack-side treatment,
  authored client-native. The launcher `--disallowedTools` extension (layer iii, F4) is
  already C7a scope (§5.3 project) — unchanged. The launcher remains the documented
  SECONDARY path; the in-session path is the new PRIMARY documented path. No pack-self
  references.
- **C8a (project OPTIONAL-FEATURES; `project-only`).** The client OPTIONAL-FEATURES
  isolation section gains the layer-(ii) `permissions.deny` recipe authored CLIENT-NATIVE
  (separate artifact from the pack version; not a fallback), alongside the
  `baseRef`/`bgIsolation` mode-setting content already specified. Note the hook as
  secondary.

Guard implications: Guard-A′ (C8b) already asserts both OPTIONAL-FEATURES
surfaces document `baseRef` + `bgIsolation`; the bounded presence-check is **MANDATED
(user-approved 2026-06-14; see BD-197 Note 14)** to ALSO assert the `permissions.deny`
recipe token in both OPTIONAL-FEATURES files (the user approved extending Guard-A′ so the
in-session backstop recipe cannot silently vanish — this SUPERSEDES this section's
earlier "optional (P3-architect call)" framing). It remains a measure-then-bound decision
at guard-author time (the C8b coder sizes the third asserted token to EXACTLY the
`permissions.deny` recipe string C5/C8a author, re-measured at C8b commit-time — not a
broad pattern), but the EXTENSION ITSELF is now binding, not an architect's call. The
prose deny-list verb-parity (Guard-C, §13.3) is unchanged.

### 18.E Empirical-Evidence Blocks (this pass)

**EB-A — PM-CHAT.md documents spawning ONLY via `agent-run.sh`, no in-session Agent-tool path.**
- Command: `grep -niE "agent-run\.sh|agent tool|in-session|isolation|worktree|/tmp|handoff|merge-back|Task tool" project-template/docs/pack/PM-CHAT.md`
- Output (HEAD `05ad61b`, 2026-06-14): the only spawn-mechanism hits are the three
  `agent-run.sh` flag-profile blocks (`agent-run.sh flag profile (Claude Code)`:455;
  `(Codex CLI)`:484; `(same as coder)`:501) + incidental prose ("parallel agent spawns
  vs sequential":185; "spawn an agent to produce the work":212; "agent sessions spawned
  from this project":354). ZERO hits for `isolation`, `worktree`, `/tmp`, `handoff`,
  `merge-back`, or "Agent tool"/"Task tool" as a spawn mechanism.
- Interpretation: PM-CHAT.md's documented spawn mechanism is exclusively the
  `agent-run.sh` launcher; it carries NO in-session Agent/Task-tool spawn instruction and
  NO `isolation:"worktree"`/merge-back contract. The under-scope is real.
- Conclusion: **SUPPORTED.**

**EB-B — PACK-CHAT.md does NOT yet document the in-session isolation/merge-back contract.**
- Command: `grep -niE "isolation|agent tool|in-session|run_in_background|/tmp|handoff|merge-back|patch" pack-ops/PACK-CHAT.md`
- Output (HEAD `05ad61b`, 2026-06-14): ZERO hits for `isolation`, `/tmp`, `handoff`,
  `merge-back`, `run_in_background`, or "Agent tool" as a spawn contract; the only
  related hits are "multiple worktrees on the same clone":116 (concurrent-session
  ownership, benign — §11.2 LEAVE) and "patch":130 (the no-band-aid rule, unrelated).
  PACK-CHAT.md DOES document Task-tool delegation in prose (`## Behavioral rules` →
  "Use sub-agent invocation (Task tool) for focused bounded questions"), but NOT the
  `isolation:"worktree"` + RW/RO + background + `/tmp`-patch contract.
- Interpretation: the pack-side in-session spawn contract is NOT yet in PACK-CHAT.md; it
  is the C4 deliverable (§12.2 pack-side). C4 ADDS it; this section clarifies C4's content.
- Conclusion: **SUPPORTED.**

**EB-C — §2.1 residue scrubbed; zero active residual subagent-trigger phrasing.**
- Command: `grep -niE "isolation \(via .?bgIsolation|opt-in worktree isolation \(via .?bgIsolation|which setting triggers isolation" maintenance-docs/v11-implementation/ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md`
- Output (HEAD `05ad61b`, 2026-06-14, post-scrub): ZERO hits (pre-scrub: 1 hit at line 145
  + 1 at line 147). The §2.1 line now reads "via the per-spawn Agent-tool
  `isolation:"worktree"` PARAMETER — the subagent trigger; `bgIsolation` is the SEPARATE
  background-SESSION gate, BD-218, NOT this trigger".
- Interpretation: the lone Correction-pass-missed residue is fixed; remaining `bgIsolation`
  mentions are the correct background-session axis or the explicit supersession record.
- Conclusion: **SUPPORTED.**

**EB-D — J4 = NO new shipped pack-side file; Check-47 allowlist untouched.**
- Command/source: F3 (`RESEARCH-BD-197-INSESSION-BACKSTOP.md` Q3 bottom-line) + the
  Check-47 `_SANCTIONED_PACK_SIDE_SHIPPED` allowlist per `CLAUDE.md` §
  dependency-direction-placement (frozen set `{scripts/lib/detect.sh, scripts/pack-help.sh}`).
- Output (verbatim, F3): "The pack ships NEITHER — it DOCUMENTS the recommended
  `permissions.deny` block (and optional hook) in OPTIONAL-FEATURES for the user to add."
  The three backstop layers edit only EXISTING surfaces (prose; OPTIONAL-FEATURES docs;
  `agent-run.sh`); none creates a new shipped pack-side file.
- Interpretation: no new entry in `_SANCTIONED_PACK_SIDE_SHIPPED`; no Check-47 growth; no
  architect+user sign-off for a new shipped file required (dependency-direction-placement).
- Conclusion: **SUPPORTED (J4 = NO).**

### 18.R Rules-Applied Verification Block (§18 pass)

| Rule (as named in prompt) | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| empirical-evidence-blocks [architect] | §18.E EB-A..EB-D: each state-claim (PM-CHAT.md lacks in-session spawn; PACK-CHAT.md current treatment; §2.1 residue location; J4=NO) backed by the actual command + verbatim output + HEAD `05ad61b` + date 2026-06-14 + interpretation + SUPPORTED conclusion. F1–F5 cite `RESEARCH-BD-197-INSESSION-BACKSTOP.md`. | COMPLIANT |
| verify-availability-not-just-existence [architect] | The backstop model is designed ONLY on F1–F5 (GA, cited). Layer (i) prose (always available), (ii) `permissions.deny` GA + session-inherited (F2), (iii) `--disallowedTools` GA-local-confirmed (F4). The fails-open PreToolUse `if`-matcher is marked SECONDARY (F2), not relied on. No capability assumed outside F1–F5; PreToolUse-hook self-contained-validator robustness is noted-not-required. | COMPLIANT |
| pack-project-separation-of-concerns [universal] | §18.1 mandates PM-CHAT.md authored CLIENT-NATIVE ("PM Chat", client paths), NOT a byte-copy of PACK-CHAT.md; §18.2(ii) keeps pack vs project OPTIONAL-FEATURES as SEPARATE artifacts (C5 pack / C8a project), "not a fallback"; §18.4 forbids pack-self references in the project commits. No pack-self concept imported into client content. | COMPLIANT |
| edit-in-place-not-full-rewrite [universal] | ONE new additive section (§18) appended before the End marker (asserted End-marker count = 1) + two targeted §2.1 string replacements (each asserted exactly 1 occurrence). No §0–§17 content modified or dropped. Section map re-counted post-edit: §18.F EB shows §0–§18 intact (see final-message §6). | COMPLIANT |
| dependency-direction-placement [architect] | §18.2 J4=NO (EB-D): all three layers edit EXISTING surfaces; none creates a new shipped pack-side file; the frozen Check-47 `_SANCTIONED_PACK_SIDE_SHIPPED` set is untouched; any future new-shipped-file layer is flagged as STOP+escalate (architect+user sign-off + allowlist growth). | COMPLIANT |
| architect-doc-reality-reconciliation [architect] | §18 opening names what the user-caught gap + the verified research forced; cross-references `RESEARCH-BD-197-INSESSION-BACKSTOP.md` (F1–F5) + BD-218 (the `bgIsolation` background-session axis) at the §2.1 scrub and the layer-map. | COMPLIANT |
| scope-deliverables-to-the-ask [universal] | Delivered exactly (a) in-session spawn symmetry, (b) unified backstop, (c) §2.1 scrub + the C4/C5/C7a/C8a commit-scope implications. No redesign of validated decisions; the Guard-A′ `permissions.deny`-token extension is MANDATED (user-approved 2026-06-14; see BD-197 Note 14) — sized measure-then-bound to the authored recipe token at C8b commit-time. | COMPLIANT |
| no-deferral-without-user-direction [universal] | Everything (in-session spawn for BOTH surfaces + the prose deny-list + the documented-optional `permissions.deny` + the launcher `--disallowedTools`) stays v11.0; ONLY background-session isolation (`bgIsolation`/EnterWorktree) remains deferred to BD-218 (user-authorized 2026-06-14). | COMPLIANT |
| agents-never-commit [universal] | No state-changing git verb run this pass (only `git rev-parse`, `grep`, `sed -n`, `python3`, Read). Exactly ONE file edited: this reconciled design doc. | COMPLIANT |
| rules-applied-verification-block [universal] | This §18.R table; every row carries quoted/measured evidence; no empty cell. | COMPLIANT |

---

---
*End of ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md*
