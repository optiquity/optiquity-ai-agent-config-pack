# ARCHITECTURE-BD-197 — RECONCILED authoritative design: worktree isolation (opt-in, isolated, safe parallel agent execution; Claude-only; pack-self + project-template)

**Role:** pack-architect (fresh, reconciling). **Mode:** design-only (one doc written; everything else read-only).
**Repo:** optiquity-ai-agent-config-pack-v11-dev · **Branch:** v11-dev · **HEAD at reconciliation:** `3e3159ee8b5e97bf8775ecf67a76867d28933a3e`.
**Date:** 2026-06-13.
**Status:** PLANNER-READY: YES (2nd-adversarial sole blocker fixed; see §15 + the Update log below). This doc SUPERSEDES `ARCHITECTURE-BD-197-WORKTREE-ISOLATION.md` (first design — kept as history/input) by folding in the `ARCHITECTURE-BD-197-ADVERSARIAL-REVIEW.md` corrections and the locked user decisions D1–D6 + the 2026-06-13 notes 6–9 in `backlog/BD-197.md`.

**Update log (2026-06-13) — post-2nd-adversarial reconciliation (BD-197 note 10; user-approved).** Two changes folded into this otherwise-affirmed design (no AFFIRMED architectural decision altered):
1. **P2 completeness-gate fix (the sole 2nd-adversarial blocker, G-1+G-2).** The single grep-ZERO gate that forbade `baseRef`/`bgIsolation` — the very setting keys P3 MUST write — is SPLIT into (a) a **prohibition-ONLY absence-gate** (matches the prohibition prose only, never the bare key names) and (b) a **separate presence-check** that OPTIONAL-FEATURES (both surfaces) DOES document `bgIsolation`/`baseRef`. The allowlist is re-MEASURED against the current tree (Empirical-Evidence Block §11.5) and sized exactly to the measured LEAVE set; the stale static "3 BD-197-process files" count is DROPPED everywhere (§10/§11.3/§11.5/§13.1). PLUS the two 2nd-adversarial git-backstop precision flags (G-4) are pinned in §5: the mechanical backstop is VERB-PRECISE (deny the patch-applying `git apply` form WITHOUT denying `git diff`/`git apply --check`), and the stale `checkout -- <path>` carve-out is DROPPED from pack-coder ×3.
2. **NEW-FORK-1 RESOLVED = (a) gate-then-probe-then-degrade** (user-decided, note 10). It is no longer an open fork; recorded in §2.2, §7, §10. It does NOT block the UC-1/P1 pipeline.

**Reconciliation contract used:** preserve what the first design got right (AFFIRMED by the adversarial pass), apply every adversarial CORRECTION, integrate every LOCKED user decision. Where the first design and the adversarial conflict, the **adversarial correction + the user's locked decision WIN**. No silent drift from the locked decisions.

**Inputs folded:** `backlog/BD-197.md` (full, incl. notes 1–9 + D1–D6), the first design (all 9 sections), the adversarial review (all 12 sections), `RESEARCH-BD-197-P1-WORKTREE-ISOLATION.md`, `RESEARCH-BD-197-AGENT-PERMISSION-INVENTORY.md`, `CLAUDE.md ## Pack memory` (full), `pack-ops/PACK-CHAT.md` §"Rule-change propagation procedure", `pack-ops/PACK-AGENTS.md`.

This document is a STRATEGY doc plus the P2 removal plan and the P3 implementation plan. It implements nothing. Line numbers in cited research/corpus drift; P2/P3 implementers re-audit by content.

---

## 0. Executive summary (the reconciled decisions)

1. **Use-case scope (BD-197 note 6).** PRIMARY = **UC-1/P1**: Pack Chat + PM Chat spawn agents IN-SESSION, in the BACKGROUND, with **opt-in worktree isolation for SAFE PARALLEL read-write agents (coders)**; merge-back via the `/tmp` patch the agent writes before return; **read-only background agents need no isolation** (they don't write the tree). SECONDARY (support IF FEASIBLE) = **P3-launcher**: an `agent-run.sh`-style launcher that `git worktree add` + runs `claude --agent` in it (human-driven parallel agents; clean standard-git merge). LOW priority / only-if-free = **P2-manual** (manual human worktree). P3-launcher feasibility is stated honestly in §7.

2. **Merge-back model (AFFIRMED by adversarial §2.3).** **Option 1 (in-place) = degradation FLOOR/default; Option 2 (report-write via `/tmp` for ALL agents); Option 4 (RW patch-file handoff via `/tmp`) = primary RW merge-back.** RW agent runs read-only `git diff` in its worktree, Writes patch + IMPL-report to a per-spawn `/tmp` handoff dir BEFORE return; orchestrator `git apply --check`/`--3way` + commits. **`agents-never-commit` is FULLY PRESERVED** — no committing agent class (Options 3 + 5 REJECTED on the Q-A/Q-B probes). ALL agents (RW + RO) land IMPL reports via the named path (`/tmp` when isolated; parent tree when in-place).

3. **Mode detection (CORRECTED — the decisive adversarial fix, D6).** **The isolation TRIGGER is `worktree.bgIsolation`, NOT `worktree.baseRef`.** `baseRef` only sets the BASE COMMIT of an already-isolated run; alone it produces in-place (proven live — §1.1). The system **VERIFIES the ACTUAL mode at RUNTIME by ground-truth** (did a `worktree-agent-*` worktree appear — `pwd`/HEAD self-check), and **never trusts `settings.json`** (platform bugs #39886/#59848 silently disagree with the declared setting). §3.3 gives the COMPLETE 9-cell `bgIsolation`×`baseRef` matrix (each cell → a defined mode/behavior). Safe default = in-place (unset); `bgIsolation:"none"` = the force-in-place hedge. **The chat controls per-task isolation via the per-spawn Agent-tool `isolation` parameter (BD-197 un-prohibits passing it) — NOT by writing `settings.json`.** ACCEPTANCE CRITERION (note 9): the EXACT per-spawn parameter name + accepted values are empirically TESTED at implementation (docs say `isolation:"worktree"`; `head`/`none` are `baseRef`/`bgIsolation` SETTINGS values, NOT parameter values — confirm by probe once the prohibition is lifted).

4. **RW/RO classification (D1+D2, AFFIRMED).** Declared per surface with TRIPLE reinforcement: pack SSOT = PACK-AGENTS `Class` column; project SSOT = PM-CHAT permission-profiles table + `agent-run.sh READONLY_AGENTS` as a CI-checked projection; PLUS per-agent-file reinforcement on EVERY agent (pack 5, project 16); PLUS the inline rules-in-force block in every spawn prompt. Pack + project designed NATIVELY (separate artifact sets, never byte-copies).

5. **Git-permission contract (D5 + note 8): BOTH a denylist AND the read-only-only principle.** Explicit denylist (commit/push/add/stage/stash/rm/mv/reset/restore/checkout + `clean`/merge/rebase/cherry-pick/revert/am/apply/branch -d/-D/switch/worktree/config/remote/update-ref/update-index/pull/gc/reflog expire/filter-branch — "including but not limited to") + the positive "read-only git verbs allowed only" principle line (catch-all closing the "never told me" gap). In prose (agent files + trinity ×3 + commit-discipline skill ×3 + rationale) AND a mechanical backstop (PreToolUse hook / `--disallowedTools` on the named verbs — pack-side hook; project-side `agent-run.sh` `--disallowedTools`). Propagated via the PACK-CHAT rule-change procedure for `## Pack memory` edits. Exact allowed/denied sets in §5.

6. **Conflict protocol (D3, AFFIRMED + sharpened §6).** `git apply --check`/`--3way`; on true conflict STOP + surface + re-spawn a fresh coder on current HEAD, NO orchestrator hand-merge; the multi-RW apply is atomic-per-patch (check→apply→review→commit per patch, never a half-applied set); both chats defensively scope parallel RW agents to non-overlapping files so conflicts are rare.

7. **Graceful degradation (CORRECTED — complete matrix §8).** Full table over {regime ground-truth} × {TEAMS on/off}, INCLUDING the bug cells the first design omitted (#39886 silent fall-to-MAIN while the pack believes it is isolated; the `bgIsolation` default-flip trajectory) — zero failures everywhere. The ground-truth runtime self-detect (item 3) is what makes the bug cells failure-safe. No settings file shipped/auto-written at any scope.

8. **OPTIONAL-FEATURES.md (both surfaces, separately authored, §9).** Documents ALL mode-setting ways — `settings.json` per-project (default/recommended) AND global, the per-spawn `isolation` parameter, CLI params, anything else — alongside the existing Agent-Teams opt-in; `/pack-help` + the chats describe it when unset.

9. **P2 removal plan (pack-side ONLY — project confirmed ZERO-shipped → P3 client work is additive, §4):** disposition the 13 primary carriers + ~7 operational-coupling mentions + the dangling-refs (3 active EXCISE / 4 archive LEAVE per D4); fresh-audit + a **prohibition-ONLY grep-ZERO completeness gate** (matches the prohibition PROSE only — never the `baseRef`/`bgIsolation` setting-key names, which P3 must legitimately write) plus a **separate OPTIONAL-FEATURES presence-check** (§11.5), allowlist MEASURED + sized to the LEAVE set. **P3 implementation plan (§5):** rules + mechanism + docs, pack-self AND client-native; commit-discipline ×3 redesigned regime-detecting; git-permission hardening propagation (VERB-PRECISE backstop — deny the patch-applying `git apply` form, not `git diff`/`git apply --check`); measure-then-bound CI guards.

10. **Decisions (§10).** D1–D6 are LOCKED (no re-open). The adversarial added D-NEW-1..4 (all integrated above). The single fork surfaced last pass — **the P3-launcher (UC-secondary) feasibility** — is now **RESOLVED = (a) gate-then-probe-then-degrade** (user decision, BD-197 note 10); see §2.2 + §7 + §10. No open fork remains.

**What changed from the first design (the adversarial corrections applied):** (a) mode-detection trigger moved from `baseRef` → `bgIsolation` + runtime ground-truth (first design's "posture 3" was a FALSE cell, refuted live); (b) the 9-cell matrix REPLACES the "three postures + cross-product" narrative; (c) the graceful-degradation matrix COMPLETED with the #39886 + default-flip cells; (d) multi-RW atomic-apply boundary made explicit; (e) `/tmp`-handoff-write treated as a degradation signal on failure, not a hard error; (f) git-permission hardening now also targets `agent-run.sh --disallowedTools` (project) reconciled against the shipped `settings.json` `git add` allow; (g) the P2 completeness gate is SPLIT into a prohibition-ONLY absence-gate (never forbids the `baseRef`/`bgIsolation` key names) + a separate OPTIONAL-FEATURES presence-check, with the allowlist re-MEASURED against the current tree and the stale static "3 process files" count dropped; (h) parity check binds to the PROSE mandate header, never `tools:` (`pack-reviewer` carries `Write,Edit` yet is RO); (i) use-case scope re-stated as UC-1/P1 PRIMARY per note 6.


---

## 1. Empirical probe results (Q-A, Q-B, mode-refutation) — reconciled, re-verified this pass

Both prior passes probed read-only. This reconciliation RE-VERIFIED the load-bearing claims at HEAD `3e3159e` on 2026-06-13 (commands below). All conclusions of the first design's §1 and the adversarial's §2 are CONFIRMED.

### 1.1 Mode-detection refutation (the decisive fix) — `baseRef` is NOT the trigger

**Empirical-Evidence Block (re-run this pass):**
- Command: `git rev-parse --abbrev-ref HEAD` → `v11-dev`; `ls .git/worktrees` → `Not a directory`; `ls .claude/worktrees` → `No such file or directory`; `python3 -c "json.load(~/.claude/settings.json)['worktree']"` → `{'baseRef': 'head'}`, with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`.
- HEAD/date: `3e3159e` / 2026-06-13.
- Interpretation: live settings carry `worktree.baseRef:"head"` and NO `bgIsolation` key, TEAMS is ON — **yet this very agent runs IN-PLACE on `v11-dev` with no worktree created.** Under the first design's "posture 3" (set `baseRef:"head"` ⇒ isolated opt-in), this agent should be isolated. It is not.
- Conclusion: **NOT-SUPPORTED** for `baseRef` as a TRIGGER. `baseRef` is necessary-but-not-sufficient for isolation; it only governs the base commit IF isolation happens. The isolation trigger is a SEPARATE decision (the per-spawn `isolation` parameter and/or `bgIsolation`). This is the single most important correction this reconciliation carries.

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

**Pack Chat + PM Chat spawn agents IN-SESSION, in the BACKGROUND, with opt-in worktree isolation (via `bgIsolation`) for SAFE PARALLEL read-write agents (coders).** Merge-back is the `/tmp` patch the agent writes before return — **auto-removal-bug-safe** because no branch-with-commits ever exists (agents-never-commit). Read-only background agents need NO isolation (they don't write the tree; they emit one report). This is the full mechanism of §1.4 + §3 + §6.

The "P1 is buggy" concern is RESOLVED (note 6): the platform's worktree auto-removal IS buggy, but the `/tmp`-patch design neutralizes it (work is safe in `/tmp` before removal). The adversarial challenge was to mode-DETECTION (which setting triggers isolation), not to merge-back safety — and that challenge is now fixed (§3).

### 2.2 UC-secondary / P3-launcher — SECONDARY (support IF FEASIBLE)

**A launcher (`agent-run.sh`-style, extended) that creates a `git worktree` then runs `claude --agent` in it** — human-driven parallel agents, clean STANDARD-GIT merge-back (the human, or the orchestrating chat, merges the worktree branch with ordinary git). Feasibility is assessed honestly in §7. SUMMARY: **feasible pack-side as a NEW thin launcher** (the pack has no `agent-run.sh` today — CLAUDE.md "The pack repo has no `agent-run.sh`"; it would be net-new), and **feasible project-side by extending the existing `project-template/agent-run.sh`**; BUT it is a SEPARATE merge-back path from UC-1 (standard-git, human-driven) and MUST NOT contaminate the UC-1 `/tmp`-patch path. **RESOLVED (BD-197 note 10, user decision NEW-FORK-1=(a) — gate-then-probe-then-degrade):** ship UC-1/P1 first; the P3 launcher is GATED on (a) UC-1 landing AND (b) a cwd-scoping probe (does `claude --agent` launched in a worktree keep its git scoped to that worktree — the #55708 / Gemini #22658 leak class). If the probe fails, the launcher DEGRADES to a documented manual procedure. It does NOT block the UC-1 pipeline — see §7 + §10. This is no longer an open fork.

### 2.3 UC-low / P2-manual — LOW (only if it falls out free)

**Manual human worktree** (developer runs `git worktree add` by hand and works in it). This needs NO pack mechanism — it is plain git. The pack's only obligation is that nothing it ships BREAKS in a manual worktree (covered by the graceful-degradation floor, §8). No dedicated deliverable; documented as a one-liner in OPTIONAL-FEATURES.


---

## 3. Mode detection (CORRECTED — D6; the decisive adversarial fix)

This section REPLACES the first design's §2.1 "three documented developer postures + cross-product" narrative, which contained a FALSE cell (the "set `baseRef:"head"` → isolated" claim, refuted live in §1.1).

### 3.1 The two-axis truth — `baseRef` is NEITHER trigger

Isolation is governed by TWO independent things, and `baseRef` is neither of the two triggers:

- **Axis 1 — DOES isolation happen? (the TRIGGER).** Determined by: the per-spawn Agent-tool `isolation` parameter, AND `worktree.bgIsolation` for background/subagent execution (`"none"` = force in-place; unset/other = product default, which today is in-place for the Agent-tool path per the live observation §1.1).
- **Axis 2 — IF isolated, from WHERE? (the BASE, NOT a trigger).** `worktree.baseRef`: `"fresh"` (default, `origin/HEAD`) vs `"head"` (local HEAD). Irrelevant when Axis 1 = no-isolation.

So `baseRef` is a MODIFIER of an already-isolated mode, not a mode selector. Any "detect the mode from `baseRef`" design detects the wrong key.

### 3.2 Per-task control vs persistent posture (D6 + note 9)

- **The chat controls per-task isolation via the per-spawn Agent-tool `isolation` parameter.** BD-197 UN-PROHIBITS passing it (the current CLAUDE.md prohibition "Do not pass `isolation:"worktree"`" is removed in P2). The chat does NOT control isolation by writing `settings.json` (that conflicts with the no-write-settings constraint AND risks concurrent-session surprises — another chat in the same clone would inherit the write).
- **The user controls the persistent POSTURE via `settings.json`** (manually, documented in OPTIONAL-FEATURES — never written by the pack).
- **VERIFY-AT-IMPLEMENTATION (acceptance criterion, note 9):** the EXACT per-spawn parameter name + accepted values MUST be empirically TESTED once the prohibition is lifted. Tool docs say `isolation:"worktree"`. `head`/`none` are SETTINGS values (`baseRef`/`bgIsolation`), NOT parameter values — do not assume the parameter accepts them. The P3 coder probes the live parameter surface (read the Agent-tool schema / a controlled spawn) and records the confirmed name+values in the IMPL-REPORT before any prose hardcodes them.

### 3.3 THE COMPLETE MODE-DECISION MATRIX (adopt verbatim)

Every `bgIsolation` × `baseRef` cell, with the per-spawn `isolation` parameter held at the value the chat passes for the task (the pack's default-in-place tasks pass none/"none"; UC-1 parallel tasks pass the confirmed isolate value from §3.2). "Active pack MODE" = what the pack must DO; "Merge-back path" = the concrete handoff the orchestrator expects. Crucially, the matrix is the SETTINGS landscape the developer lands in; the ACTUAL mode is then VERIFIED at runtime by ground-truth (§3.4), never trusted from this table.

| # | `bgIsolation` | `baseRef` | Resulting runtime regime | Active pack MODE | Merge-back path the orchestrator expects |
|---|---|---|---|---|---|
| 1 | unset | unset | in-place (product default today) | **IN-PLACE** | working-tree edits + report in parent tree |
| 2 | unset | `"fresh"` | in-place (baseRef inert; no isolation) | **IN-PLACE** | working-tree + parent-tree report |
| 3 | unset | `"head"` | in-place (baseRef inert) — **THE LIVE CASE (§1.1)** | **IN-PLACE** | working-tree + parent-tree report |
| 4 | `"none"` | unset | forced in-place | **IN-PLACE** | working-tree + parent-tree report |
| 5 | `"none"` | `"fresh"` | forced in-place (baseRef inert) | **IN-PLACE** | working-tree + parent-tree report |
| 6 | `"none"` | `"head"` | forced in-place (baseRef inert) | **IN-PLACE** | working-tree + parent-tree report |
| 7 | (isolating value) | unset | isolated @ `origin/HEAD` (WRONG-base bug surface #45371) | **ISOLATED-RISKY** | `/tmp` patch + `/tmp` report; WARN wrong-base |
| 8 | (isolating value) | `"fresh"` | isolated @ `origin/HEAD` | **ISOLATED-RISKY** | `/tmp` patch + `/tmp` report; WARN wrong-base |
| 9 | (isolating value) | `"head"` | isolated @ local HEAD (intended opt-in) | **ISOLATED** | `/tmp` patch + `/tmp` report |

Coder-proofing notes:
- **Rows 1–6 ALL collapse to IN-PLACE.** `baseRef` never changes the mode in rows 1–6 — inert without isolation. This is the cell-set the first design's narrative obscured.
- **"(isolating value)"** (rows 7–9) is whatever value the running Claude Code version uses for "do isolate background/subagents." The docs name `"none"` as the OFF value; the ON value is version-specific. **The pack MUST NOT hardcode the ON value** — it treats "not `none` AND a worktree was actually created" as the isolated trigger (ground-truth, §3.4/§3.5).
- **Row 9 is the only fully-intended opt-in.** Rows 7–8 are isolated-but-wrong-base (historic bug); the pack still FUNCTIONS (the patch still applies onto the parent), but the orchestrator surfaces a "your worktree branched from the default branch, not your feature branch" warning.
- **Precedence is trivial: there is no conflict.** `bgIsolation` is the only mode trigger among the two keys; `baseRef` has no mode-authority. Zero undefined cells, zero contradictory cells. The first design's worry about "precedence when both keys are present" dissolves once the axes are assigned correctly.

### 3.4 The runtime ground-truth contract (the only deterministic detection)

Settings do NOT deterministically tell you the runtime regime (the live case §1.1; #39886 silent fall-to-MAIN; #59848 misclassification). Therefore the ONLY deterministic detection is the runtime-regime self-detect. The coder contract:

1. **Settings are read by the DEVELOPER + documented in OPTIONAL-FEATURES, NOT parsed by the pack at runtime.** The pack ships/parses no settings file. "Settings-driven" means: the developer's settings choice DETERMINES which row of §3.3 they land in; OPTIONAL-FEATURES documents the rows so the developer can choose Row 9 knowingly.
2. **The agent detects its ACTUAL regime at runtime** (the §3.3 "resulting runtime regime" column) via a deterministic `pwd`/HEAD check — is `pwd` a `worktree-agent-*` worktree? is HEAD a `worktree-agent-*` branch? — and branches its write-target + handoff on THAT, never on settings values (which it cannot see and which can lie). Neither regime is an error.
3. **The orchestrator detects the regime from what the agent REPORTS** — a `/tmp` patch path ⇒ treat as isolated; in-place working-tree edits ⇒ treat as in-place — never from an assumption about the developer's settings.

This is strictly more robust than "detect the mode from settings," and is the only version that is deterministic AND coder-implementable.

### 3.5 Do NOT hardcode the `bgIsolation` "on" value

Define the regime by GROUND TRUTH (a `worktree-agent-*` worktree was actually created → isolated), not by guessing the enumerated "on" values (version-specific, v2.1.143+, may change). OPTIONAL-FEATURES describes `bgIsolation:"none"` as the explicit "force in-place" lever and describes Row 9 by the OUTCOME ("a `worktree-agent-*` checkout appears") rather than by an exact magic value.


---

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

**Mechanical backstop (adversarial D-NEW-2 — the load-bearing addition):**
- **Pack-side:** a **PreToolUse hook** (or `--disallowedTools` on the named `Bash(git <verb>:*)` patterns) for spawned agents. The matcher is VERB-PRECISE per §5.1 — it names `Bash(git apply:*)` in the deny set but NEVER `Bash(git diff:*)` (the patch-emit stays allowed; confirm the `git diff > file` redirect is not tripped). Pack Chat retains commit ability (the hook scopes to agent spawns, not the chat).
- **Project-side:** the hardening MUST also land in `agent-run.sh` `CLAUDE_READONLY_FLAGS` / `--disallowedTools` (add `Bash(git stash:*)`, `Bash(git reset:*)`, `Bash(git restore:*)`, `Bash(git checkout:*)`, `Bash(git apply:*)`, `Bash(git worktree:*)`, `Bash(git clean:*)`), NOT only in prose. **Reconciliation nuance (adversarial §7):** the shipped `project-template/.claude/settings.json` ALLOWS `"Bash(git add *)"` at the permission layer (for the human/PM). The `agents-never-commit` ban for agents is therefore enforced by the agent Hard rule + `agent-run.sh --disallowedTools`, NOT by the shipped settings.json. The prose ban and the launch-flag enforcement MUST NOT diverge — the launch flags are an encoding surface (enumerate-encoding-surfaces).

### 5.4 CI guard (verb-enumeration parity — measure-then-bound)
Assert the folded verb set appears in every surface that enumerates the ban (trinity, commit-discipline ×3, pack-coder ×3, project Hard rules, agent-run.sh flags). MAY fold into existing trinity-parity + bijection checks rather than a new check (prefer fewer checks — design-elegance). Measure the current enumeration coverage first; size the assertion to the measured surface set.


---

## 6. Conflict protocol (D3, AFFIRMED + sharpened) + multi-RW atomicity

Conflicts arise when (a) two parallel RW agents' patches touch the same hunks, or (b) a patch was cut against a base the main tree has since moved past. Protocol (orchestrator-run; agents never resolve):

1. **Order + dry-run, atomic per patch.** Apply patches SEQUENTIALLY (never concurrently). For EACH patch, the orchestrator runs the FULL cycle before touching the next: `git apply --check <patch>` → (clean) `git apply <patch>` → review → commit with user approval. **The tree is never left with a half-applied multi-patch set** — each patch is its own atomic check→apply→review→commit unit. Earlier-committed patches are safe; only the failing patch needs recovery.
2. **On `--check` failure (drift or collision):**
   a. **3-way attempt:** `git apply --3way <patch>` (uses blob context to auto-merge non-overlapping drift). If clean ⇒ proceed to review+commit.
   b. **Still conflicting ⇒ STOP and surface to the user.** The orchestrator presents: which two patches collide, the conflicting hunks, and a recommendation: **re-spawn the LATER agent FRESH against current HEAD** with the same scope (a fresh coder per fresh-agent-default) to regenerate a clean patch. The orchestrator does NOT hand-merge conflicting hunks (hand-merging IS a fix; Pack Chat / PM Chat does no fixes; the re-spawned coder regenerates).
3. **`--3way` base-blob caveat (adversarial §4):** `git apply --3way` requires the patch's base blobs to be present in the repo. For a patch cut in an isolated worktree branched at `origin/HEAD` (Rows 7–8), `--3way` context may not resolve — those patches may fail `--3way` more often, and the recovery is the same re-spawn (against current HEAD, in-place or Row-9). State this so the planner does not treat `--3way` as a guarantee.
4. **Anti-drift hygiene (both chats defensively):** parallel RW agents SHOULD be scoped to DISJOINT file sets by the orchestrator's prompt (the existing file-ownership-boundary discipline). Disjoint scoping makes (a)-class collisions structurally rare; (b)-class drift is handled by `--3way` + re-spawn. Conflict-resolution authority caps at the orchestrator + user, never the agent.

---

## 7. UC-secondary (P3-launcher) feasibility — stated honestly

The user asked for an honest, research-backed feasibility call on the launcher use-case (note 6 SECONDARY: a launcher that `git worktree add` + runs `claude --agent` in it). Assessment:

**Pack-side:** the pack has NO `agent-run.sh` today (CLAUDE.md: "The pack repo has no `agent-run.sh` — that's a project template helper"). A pack launcher would be net-new. Pack agents are invoked via `claude --agent pack-<name>` (separate session) or the Agent tool. A launcher that does `git worktree add <wt> && (cd <wt> && claude --agent pack-coder ...)` is mechanically plausible BUT introduces a SECOND merge-back path (standard-git human-driven) distinct from the UC-1 `/tmp`-patch path. **Feasibility: PLAUSIBLE but UNVERIFIED** — the load-bearing unknown is whether `claude --agent` launched with cwd inside a worktree reliably keeps its git operations scoped to that worktree (the same class of leak as #55708 "subagent git checkout affects parent repo" and Gemini #22658). This MUST be probed at P3 implementation before the launcher is committed.

**Project-side:** `project-template/agent-run.sh` EXISTS and already dispatches `claude --agent` with per-class flags. Extending it with an optional `--worktree` mode (`git worktree add` then run the agent in it, then the human/PM merges with standard git) is the lower-risk launcher path because the merge-back is plain git, human-gated. **Feasibility: FEASIBLE as an additive `--worktree` flag**, gated on the same cwd-scoping probe.

**Honest flag:** the P3-launcher is a SEPARATE merge-back regime from UC-1 and MUST NOT contaminate the UC-1 `/tmp`-patch path. **DECISION — RESOLVED (BD-197 note 10; user-decided NEW-FORK-1=(a) gate-then-probe-then-degrade):** ship UC-1 first; treat the launcher as a P3 sub-deliverable GATED on (a) UC-1 landing AND (b) the cwd-scoping probe passing. If the probe fails (the launched agent's git leaks to the parent), the launcher DEGRADES to a DOCUMENTED MANUAL PROCEDURE in OPTIONAL-FEATURES (developer runs `git worktree add` + `claude --agent` by hand, accepting the platform's behavior) rather than a pack-automated mechanism. It does NOT block the UC-1 pipeline. This is recorded as RESOLVED in §10 (no longer an open fork).

**Pack/project separation nuance (adversarial §7):** `project-template/.claude/settings.json` IS shipped and carries `"Bash(git add *)"` + a PostToolUse hook but NO `worktree` key. Constraint 6 ("ship no settings file for worktree") is satisfied today; **P3 must NOT add a `worktree` key to the shipped template** — the doc tells the developer to add it to THEIR settings, never the shipped file.

---

## 8. Graceful degradation (CORRECTED — complete matrix)

The first design's §2.2 listed the right principles but presented NO exhaustive cell table. Here is the complete table over {regime ground-truth} × {TEAMS on/off}, INCLUDING the bug cells the first design omitted. "Zero-failure" = the orchestrator finds the work and commits it; nothing is silently lost.

| TEAMS | Regime (GROUND TRUTH) | What the agent does | What the orchestrator does | Failure-safe? |
|---|---|---|---|---|
| off | IN-PLACE (Rows 1–6) | edits parent tree; report to parent path | reads working-tree diff + report; commits | YES (today's model) |
| off | ISOLATED (Rows 7–9) | edits worktree; `git diff` → `/tmp` patch + `/tmp` report | reads `/tmp` patch; `--check`/`--3way`/apply; commits | YES (patch survives auto-removal) |
| off | **ISOLATED-but-silently-fell-to-MAIN (#39886)** | THINKS isolated, actually edited parent tree | self-detect sees in-place regime → behaves as IN-PLACE row | YES (self-detect is ground-truth, not settings) |
| on | IN-PLACE | teammates edit shared tree (file-ownership boundaries) | per-teammate reports; commits | YES (disjoint scope) |
| on | ISOLATED (docs-intended per-session worktrees) | each teammate edits own worktree; `/tmp` patch each | sequential `--check`/apply per patch; conflict protocol §6 | YES if patches disjoint; conflict protocol if not |
| any | **settings declare isolate but product DEFAULT FLIPS later (#59580/#59848 trajectory)** | self-detect catches the ACTUAL regime regardless of setting drift | keys merge-back off the agent's REPORT, not the setting | YES (the whole point of ground-truth self-detect) |

The two cells the first design's narrative did NOT cover — **#39886 silent fall-to-MAIN** and the **`bgIsolation` default-flip trajectory** — are exactly the "no destructive surprises" cases the user named. They are failure-safe ONLY because of the ground-truth self-detect (§3.4), which is therefore load-bearing for degradation, not just for mode-detection. **No settings file is shipped or auto-written at any scope in any cell.**

Codex/Gemini are OUT of scope here (BD-217); their CLIs degrade to native sequential — the trinity-exemption note documents this without claiming parity. (P1 found both now have IMMATURE worktree support — EXISTS-BUT-IMMATURE per verify-availability-not-just-existence — but that is BD-217's problem, not a v11.0 parity claim.)


---

## 9. OPTIONAL-FEATURES.md (both surfaces, separately authored)

Both docs model the existing Agent-Teams opt-in section shape and document ALL mode-setting ways (note 9). NEITHER is a byte-copy; each is authored for its audience.

**Pack** (`pack-ops/OPTIONAL-FEATURES.md`) — new section "## Claude Code — Isolated parallel agents (worktree isolation)":
- **Status / What it is / When it matters.**
- **The complete way to set isolation modes:**
  - `settings.json` at PER-PROJECT scope (`.claude/settings.json`, default/recommended) AND GLOBAL scope (`~/.claude/settings.json`, affects both pack + project — the user chooses where it lives).
  - the per-spawn Agent-tool `isolation` parameter (the chat's per-task control — the CONFIRMED name+values from the §3.2 implementation probe; until confirmed, describe by behavior not by a guessed value).
  - any command-line params (probed at implementation).
  - the keys: `worktree.bgIsolation` (the TRIGGER — `"none"` = force in-place; the "on" value is version-specific, describe Row 9 by the OUTCOME "a `worktree-agent-*` checkout appears") and `worktree.baseRef` (the BASE modifier — `"head"` for feature-branch work; `"fresh"` default = `origin/HEAD`).
- **The 9-row landscape** (§3.3) summarized so the developer can choose Row 9 knowingly.
- **Caveats:** version-sensitive (#60588), silent-delete (#38287), best-effort, silent fall-to-MAIN (#39886).
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
- **D6** = mode-detection: trigger is `bgIsolation` NOT `baseRef`; VERIFY actual mode at RUNTIME (ground-truth pwd/HEAD); safe default = in-place (unset); `bgIsolation:"none"` = force-in-place hedge. [§3]

**Adversarial-added decisions (D-NEW-1..4) — INTEGRATED, recorded for traceability:**
- **D-NEW-1:** adopt the §3.3 complete matrix + §3.4 three-point runtime contract; the pack does NOT parse settings at runtime; `baseRef` is a base-modifier, never a trigger. [§3 — integrated]
- **D-NEW-2:** folded verb-hardening also lands in `agent-run.sh --disallowedTools` (project) + a pack PreToolUse hook, reconciled against the shipped `settings.json` `git add` allow. [§5.3 — integrated]
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

**(a) Replace the prohibition bullet** (`### Sub-agent behavior (Claude-only)`) with an ENABLE bullet: "Sub-agents run in-place by default (no isolation). A developer MAY opt into isolated parallel execution by setting `worktree.bgIsolation` to an isolating value (and `worktree.baseRef:"head"` for feature-branch work) — see OPTIONAL-FEATURES; the chat may pass the per-spawn `isolation` parameter for a single task. When isolation is active, RW agents emit a patch to the named `/tmp` handoff dir and the orchestrator applies it; agents never commit. The agent VERIFIES its actual regime at runtime (pwd/HEAD ground-truth), never trusting settings. Trinity-exempt (Claude-only; Codex/Gemini = BD-217)." Propagate ×3 trinity + new rationale slug.

**(b) Two-class principle one-liner** in trinity (the PRINCIPLE only; assignment lives in the PACK-AGENTS roster). New rationale slug `agent-two-class-model`. (anti-restate: principle in trinity, assignment in roster.)

**(c) Folded git-permission hardening** (§5.3) — amend the `agents-never-commit` bullet to ENUMERATE the denylist + add the read-only-only principle line; propagate via the ordered surfaces (corpus ×3 → rationale → references → manifest → cache → manifest regen). Project-side gap-closure surface-by-surface (enumerate-encoding-surfaces) INCLUDING `agent-run.sh --disallowedTools`.

### 12.2 Mechanism (the patch-handoff merge-back) — codified WHERE

- **Pack-side:** the merge-back flow (§4.1) codified in `pack-ops/PACK-CHAT.md` (orchestrator procedure: name handoff dir, read patch, `git apply --check`/`--3way`, conflict protocol §6) + the `implementation-report` skill ×3 (the agent's "emit patch + report to handoff dir" step) + `pack-coder` ×3 (the RW-emit step). The commit-discipline skill ×3 redesign (§12.4) carries the regime-detecting preflight. P3 PreToolUse hook + `--disallowedTools` for the mechanical backstop (§5.3).
- **Project-side (net-new):** the same flow authored INDEPENDENTLY into `project-template/docs/pack/PM-CHAT.md` (PM-Chat orchestrator procedure) + `project-template/.{claude,codex,gemini}/agents/coder.*` (the RW-emit step) + `project-template/skills/implementation-report/SKILL.md` (+ mirrors) + `project-template/agent-run.sh` (`--disallowedTools` hardening + optional `--worktree` launcher if §7 feasibility passes). NOT a byte-copy — audience-correct per cross-CLI-reference-normalization (orchestrator is "PM Chat," paths/commands are project-side canonical).

### 12.3 Docs — OPTIONAL-FEATURES additive homes (pack + client, separately authored)
Per §9. Pack: new section in `pack-ops/OPTIONAL-FEATURES.md` modeled on the Agent-Teams section shape. Client: the SAME section authored INDEPENDENTLY into `project-template/docs/pack/OPTIONAL-FEATURES.md`. Separate artifacts; not a fallback for each other.

### 12.4 commit-discipline skill ×3 redesign (regime-detecting, NOT regime-asserting)

The skill TODAY hard-asserts the isolated model (verified this pass: `pwd` "Must end in worktree path" + HEAD "Must start with `worktree-agent-`"). Under Rows 1–6 (in-place) BOTH are FALSE for a correctly-running agent — proven (this agent runs on `v11-dev`). Redesign:
- **§1 pre-flight — regime-DETECTING, non-fatal in BOTH directions.** Replace the hard asserts with: "Detect your regime: if `pwd`/HEAD indicate a `worktree-agent-*` worktree you are ISOLATED; otherwise IN-PLACE. Neither is an error. Branch your write-target + handoff on the regime." Give the coder the literal branch:
  - `pwd`/HEAD indicate `worktree-agent-*` ⇒ ISOLATED ⇒ code Writes under `pwd`; IMPL-report + `git diff` patch to the named `/tmp` handoff dir.
  - otherwise ⇒ IN-PLACE ⇒ Writes under the parent tree (today's deliverable); report to the named parent path.
  - Neither is an error; never retarget another agent's main checkout (keep the BD-119 C-2 guard as a CAUTIONARY note, NOT a blanket "every Write under pwd").
- **§2 write-target rule — regime-aware** (as above). Keep the absolute prohibition on retargeting another agent's main checkout.
- **§3 git-state-change ban — UNCHANGED in spirit; ensure it carries the §5.1 denylist + the read-only-only principle line** (add `restore --staged`, `apply`, `worktree`, `clean`, `branch -d/-D` if absent).
- **§6 anti-patterns — retire** the "wrote report to /tmp because the worktree write rejected → wrong path" anti-pattern (it is NOW correct isolated behavior); replace with regime-aware guidance.

### 12.5 Graceful degradation (verified, not assumed)
P3 acceptance includes the §8 verification matrix run end-to-end: (no setting), (`bgIsolation:"none"`), (isolating value + `baseRef:"head"`), (TEAMS on), (TEAMS off), AND the two bug cells (#39886 silent-fall-to-MAIN simulated; TEAMS-on isolated). Each must run a pack agent spawn → report-back with zero failures. Codex/Gemini explicitly out (BD-217); native sequential fallback documented via trinity-exemption without claiming parity.

### 12.6 New CI guards (P3) — measure-then-bound (§13).


---

## 13. New validators / CI guards — measure-then-bound contract

Each guard follows: (1) measure the tree first; (2) categorize every occurrence KEEP/STRIP; (3) fix-recipe per STRIP; (4) size the allowlist to KEEP only; (5) verify clean post-fix. The P3 coder MUST execute steps 1–2 against the real tree before authoring the guard — this design specifies the CONTRACT, not the allowlist contents (which need a measured tree at P3-time). Per CI-check-runtime-compounding: scope each check to the active tree, single whole-tree `rg`, no subprocess-per-entry storm, add a per-check runtime guard.

### 13.1 Guard A — prohibition-stays-removed (flip-block) — PROHIBITION-ONLY (matches §11.5 gate (a))
- **Asserts:** the worktree-isolation PROHIBITION PROSE does not reappear in active pack surfaces.
- **Measure-then-bound:** match the prohibition SIGNATURE ONLY (`no worktree isolation`, `Do not pass .*isolation.*worktree`) — **NEVER the bare setting-key names `baseRef`/`bgIsolation`** (those are legitimate post-P3 content P3 must write; forbidding them defeats the gate — 2nd-adversarial G-1/G-2). KEEP allowlist = the §11.5-MEASURED LEAVE set (the history IMPL-REPORT + the measured BD-197-process artifacts that carry the prohibition prose + archive), re-measured at guard-authoring time. STRIP = anything else (empty post-P2). Sized to the measured KEEP set only — **no static "3 process files" count** (it was stale; measured 5 BD-197-process prohibition-prose carriers + 1 history IMPL-REPORT + 9 archive at this HEAD; re-measure).
- **Runtime:** scope to active tree (exclude archive/test-fixtures), single whole-tree `rg`, per-check runtime guard.

### 13.1a Guard A′ — OPTIONAL-FEATURES presence-check (the separate POSITIVE gate, matches §11.5 gate (b))
- **Asserts (P3 acceptance):** BOTH OPTIONAL-FEATURES surfaces (`pack-ops/OPTIONAL-FEATURES.md` + `project-template/docs/pack/OPTIONAL-FEATURES.md`) DO mention `bgIsolation` AND `baseRef` — the keys are DOCUMENTED, not forbidden. This is the inverse of Guard A: a PRESENCE check on the legitimate key names, not an absence check.
- **Measure:** baseline at this HEAD = 0 mentions in either file (the keys do not exist pre-P3); the guard turns GREEN only after P3 authors the sections.
- **Runtime:** two single-file `rg -c` reads; trivial.

### 13.2 Guard B — RW/RO declaration consistency (×2, one per surface)
- **Pack:** set-equality {PACK-AGENTS roster `Class` cells} ↔ {agent-file PROSE mandate headers}. **Bind to the PROSE header, NEVER `tools:`** (`pack-reviewer` carries `Write,Edit` yet is RO — adversarial §8). Measure: 5 agents = 1 RW + 4 RO; any mismatch FAILS.
- **Project:** set-equality {PM-CHAT RO rows} ↔ {`agent-run.sh READONLY_AGENTS`} ↔ {per-file RO PROSE headers}. Measure: 14 RO + 2 RW; any drift FAILS.
- **Runtime:** single-pass file reads, no per-agent subprocess storm.

### 13.3 Guard C (optional, P3 architect call) — verb-enumeration parity
Asserts the §5.1 denylist + principle line appears in every surface that enumerates the ban (trinity, commit-discipline ×3, pack-coder ×3, project Hard rules, `agent-run.sh` flags). MAY fold into existing trinity-parity + bijection checks rather than a new check (prefer fewer checks — design-elegance). Measure current coverage first.

---

## 14. Architect-doc-vs-reality reconciliation

What the FIRST design got wrong, and how this reconciliation fixes it:

- **(FIXED) The mode-detection trigger.** The first design's §2.1 "posture 3" said setting `worktree.baseRef:"head"` opts into isolated parallel and the pack then uses the `/tmp` patch-handoff. This is a FALSE cell: live evidence (§1.1 — `baseRef:"head"` set, regime in-place) refutes it. An orchestrator built on the first design would look for a `/tmp` patch from an agent that actually edited the parent tree in place. **Fix:** §3 — the trigger is `bgIsolation` (Axis 1), `baseRef` is a base-modifier (Axis 2), and the ACTUAL mode is verified at runtime by ground-truth, never trusted from settings. The 9-cell matrix (§3.3) replaces the "three postures + cross-product" narrative.
- **(FIXED) The graceful-degradation matrix was incomplete.** The first design listed principles but omitted the #39886 silent-fall-to-MAIN cell and the `bgIsolation` default-flip trajectory — exactly the "no destructive surprises" cases the user named. **Fix:** §8 — the complete table over {regime ground-truth}×{TEAMS}, with those cells made failure-safe BY the ground-truth self-detect.
- **(FIXED) Multi-RW atomicity under-specified.** The first design implied sequential apply but did not nail the per-patch atomic check→apply→review→commit boundary. **Fix:** §6.1.
- **(FIXED) `/tmp` handoff treated as guaranteed.** **Fix:** §1.2 — a failed handoff Write is a degradation signal, not a hard error (the grant lives in the USER's settings).
- **(FIXED) git-permission hardening missed an encoding surface.** The first design routed hardening through prose + propagation but did not name `agent-run.sh --disallowedTools` (project) or reconcile the shipped `settings.json` `git add` allow. **Fix:** §5.3 (D-NEW-2).
- **(FIXED) P2 completeness gate was self-contradictory + over-broad** (2nd-adversarial G-1/G-2; the prior combined regex forbade `baseRef`/`bgIsolation` — the very keys P3 must write — and carried a stale "3 process files" count). **Fix:** §11.5 + §13.1 — SPLIT into a prohibition-ONLY absence-gate + a separate OPTIONAL-FEATURES presence-check; allowlist re-MEASURED + sized to the LEAVE set; static count dropped (revised D-NEW-3).
- **(FIXED) Parity check could bind to `tools:`.** `pack-reviewer` carries `Write,Edit` yet is RO. **Fix:** §4.3 / §13.2 — bind to the PROSE header.
- **(FIXED) Git-permission backstop was not verb-precise** (2nd-adversarial G-4). **Fix:** §5.1/§5.3 — deny the patch-applying `git apply` form WITHOUT denying `git diff` (the patch-emit) or the orchestrator-side `git apply --check`; confirm the `git diff > file` redirect is not tripped by the matcher; DROP the stale `checkout -- <path>` carve-out from pack-coder ×3 (plain `checkout` of a path is destructive and in the denylist).
- **(RESOLVED) NEW-FORK-1 (P3-launcher commit-vs-document)** was an open user fork last pass; **now RESOLVED = (a) gate-then-probe-then-degrade** (BD-197 note 10). **Recorded:** §2.2 / §7 / §10. It does not block the UC-1 pipeline.
- **(PRESERVED, AFFIRMED) The merge-back model (1+2+4), `agents-never-commit` preserved, RW/RO SSOT placement, the conflict ceiling.** These were correct in the first design and independently re-affirmed by the adversarial pass on fresh probes; carried forward unchanged.

**Realizes / invalidates / carves-out:**
- This design REALIZES the P1 option space (selects 1+2+4) and records the Q-A/Q-B + mode-refutation probes. When P3 lands, the IMPL-REPORT must cross-reference THIS doc (the realized consumer; name file + symbol, never line numbers) per architect-doc-reality-reconciliation.
- This design INVALIDATES the bug-era model in `commit-discipline/SKILL.md` §1/§2/§6 + the operational mentions in `implementation-report`/`pack-coder`; §12.4 + §11.2 name the exact redesign so the reconciliation chain is explicit.
- The BD-197 entry's stale "Codex/Gemini neither support isolation" framing is superseded by P1 §3.2/§3.3 and carved out to **BD-217** (out of scope); the trinity-exemption pattern is kept clean so BD-217 can adapt the same patch-handoff model per-platform.

**Addendum note for the first design:** `ARCHITECTURE-BD-197-WORKTREE-ISOLATION.md` is superseded by this RECONCILED doc; it remains as input/history. Its §2.1 "three postures" model is the FALSE-cell artifact corrected in §3 here.

---

## 15. Is the design planner-ready?

**PLANNER-READY: YES.** The 2nd-adversarial's SOLE blocker (G-1+G-2 — the self-contradictory, over-broad P2 completeness gate) is FIXED: §11.5 SPLITS the gate into a prohibition-ONLY absence-gate (never forbids the `baseRef`/`bgIsolation` key names) + a separate OPTIONAL-FEATURES presence-check, with the allowlist re-MEASURED against the current tree (Empirical-Evidence Block) and sized to the LEAVE set, and the stale "3 process files" count dropped across §10/§11.3/§11.5/§13.1. The two 2nd-adversarial git-backstop precision flags (G-4) are pinned in §5 (verb-precise `apply`-deny / `diff`-allow; `checkout -- <path>` carve-out dropped). The one open fork (NEW-FORK-1) is RESOLVED = (a) gate-then-probe-then-degrade (BD-197 note 10; §2.2/§7/§10) and no longer needs a user call.

Everything the 2nd-adversarial AFFIRMED is unchanged: the mode-decision contract is complete — §3.3 (9-cell matrix) + §3.4 (runtime ground-truth contract) + §3.5 (no-hardcode); §6.1 (multi-RW atomicity); §8 (complete degradation table); §5.3 (`agent-run.sh` hardening surface); §4.3/§13.2 (parity binds to prose). The merge-back architecture (1+2+4), RW/RO placement, P2 plan, conflict ceiling, and degradation matrix are all sound and affirmed on independent evidence. No AFFIRMED architectural decision was altered by this fix — only the P2 gate, the launcher-decision integration, and the two git-backstop precision flags. **The design is planner-ready.**

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

---
*End of ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md*
