# ARCHITECTURE-BD-197 — ADVERSARIAL REVIEW of the worktree-isolation design

**Role:** pack-architect (FRESH, ADVERSARIAL — second pass). **Mode:** design-review only (one doc written; everything else read-only).
**Repo:** optiquity-ai-agent-config-pack-v11-dev · **Branch:** v11-dev · **HEAD at review time:** `3e3159ee8b5e97bf8775ecf67a76867d28933a3e`.
**Date:** 2026-06-13.
**Target under review:** `maintenance-docs/v11-implementation/ARCHITECTURE-BD-197-WORKTREE-ISOLATION.md` (first design, uncommitted).
**Inputs re-read in full:** BD-197.md (incl. 2026-06-13 user-direction note + constraint 5 + adversarial mandate), RESEARCH-BD-197-P1, RESEARCH-BD-197-AGENT-PERMISSION-INVENTORY, CLAUDE.md `## Pack memory` (full), commit-discipline/SKILL.md, pack-ops/OPTIONAL-FEATURES.md, project-template/.claude/settings.json, ~/.claude/settings.json (read-only).
**Sealed pre-design discussion:** NOT sought, NOT referenced (UNBIASED rule).

This review CHALLENGES every load-bearing choice, RE-RUNS Q-A/Q-B independently, and BUILDS the complete mode-decision matrix the user mandated (constraint 5). It changes nothing but this file.

---

## 0. Headline verdicts (read this first)

| Choice | First design's call | My adversarial verdict |
|---|---|---|
| Merge-back = 1 (floor) + 2 (reports) + 4 (patch via /tmp) | ADOPT | **AFFIRM** — with independent Q-A/Q-B evidence (§2). The /tmp-handoff is the only rule-preserving primitive that survives the platform bugs. |
| `agents-never-commit` NOT relaxed | confirm | **AFFIRM** — Option 3/5 correctly rejected; no committing class. |
| **Mode-decision model (constraint 5)** | `bgIsolation` × `baseRef` cross-product, three "postures" | **CHALLENGE — INCOMPLETE + CONTAINS A FALSE CELL.** The model is NOT a complete matrix, is NOT deterministic as written, and its central claim ("set `baseRef:"head"` → isolated parallel") is **REFUTED by the live system** (§3). This is the single biggest gap and is NOT coder-implementable as written. |
| Detection = agent self-detects regime from `pwd`/HEAD | primary mechanism | **CHALLENGE** — the design conflates two different "detections" (settings-mode vs runtime-regime) and never specifies the settings read precisely. The runtime-regime self-detect is sound and should be KEPT as the load-bearing mechanism; the settings-mode "detection" is largely illusory (§3.4). |
| Conflict protocol (--check → --3way → re-spawn) | ADOPT | **AFFIRM with one gap** — partial-apply / patch-staleness handled; **multiple-RW atomicity + the all-or-nothing apply guarantee is under-specified** (§4). |
| Pack RW/RO SSOT = PACK-AGENTS Class column + parity check | RECOMMEND | **AFFIRM** — correct, enforceable, measured. |
| Project RW/RO SSOT = PM-CHAT table + CI-checked agent-run.sh projection | RECOMMEND | **AFFIRM** — correct; the set-equality guard closes a real un-guarded drift. |
| P2 removal plan + blast radius | 13 primary + ~7 operational | **AFFIRM with a measured correction** — my independent grep reconciles, BUT the §4.5 dangling-ref count needs the BD-197-process-file exclusion stated explicitly (§5). |
| Graceful-degradation matrix (TEAMS × settings) | "exhaustive" | **CHALLENGE — NOT exhaustive.** It omits the live failure-relevant cells (#39886 silent in-place fallback WHILE the pack believes it is isolated; the `bgIsolation` default-flip). My corrected matrix in §6. |
| Pack/project separation | "designed separately throughout" | **AFFIRM** — genuinely native on both surfaces; not a byte-copy. One nuance about the shipped `project-template/.claude/settings.json` (§7). |

**Bottom line:** The merge-back architecture is SOUND and I affirm it on independent evidence. The design is **NOT ready for the planner** because constraint 5 — the explicit, deterministic, coder-proof mode-decision contract that was the WHOLE point of this adversarial pass — is incomplete and contains a factually false cell. §3 supplies the complete matrix the design must adopt before the planner runs.

---

## 1. Method — independent probes (read-only)

All probes run at HEAD `3e3159e`, branch `v11-dev`, on 2026-06-13. No git mutation. The only writes were a single /tmp scratch file (created + removed) to test the write-escape path, and this report.

| Probe | Command | Verbatim output (key lines) | HEAD/date | Conclusion |
|---|---|---|---|---|
| Runtime regime | `git rev-parse --abbrev-ref HEAD` | `v11-dev` | 3e3159e / 06-13 | This agent runs IN-PLACE, not in `worktree-agent-*`. |
| Worktree dirs | `ls .git/worktrees; ls .claude/worktrees` | `.git/worktrees: Not a directory` / `.claude/worktrees: No such file or directory` | 3e3159e / 06-13 | NO isolated worktree exists for this spawn. |
| `git worktree list` | (as named) | only `…/optiquity-ai-agent-config-pack [main]` + `…-v11-dev [v11-dev]` | 3e3159e / 06-13 | No `worktree-agent-*`; consistent with in-place spawn. |
| **Q-A write-escape** | `printf … > /tmp/bd197-…; cat; rm` | `WROTE: /tmp/bd197-adversarial-probe-46588.txt` then content echoed | 3e3159e / 06-13 | /tmp IS writable by a spawned agent. (See §2.1 for the regime caveat.) |
| **Live settings** | read `~/.claude/settings.json` | `"worktree": { "baseRef": "head" }`; `env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS:"1"` | 3e3159e / 06-13 | **`baseRef:"head"` IS SET and TEAMS IS ON — yet I run in-place.** Decisive counter-example to the first design's mode model. |
| Env regime | `env \| grep -iE 'claude\|teams'` | `AI_AGENT=claude-code_2-1-170_agent`, `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` | 3e3159e / 06-13 | Running Claude Code v2.1.170; TEAMS on; still in-place. |
| Shipped settings | `grep worktree project-template/.claude/settings.json …` | NO worktree keys in any shipped settings file | 3e3159e / 06-13 | Constraint 6 ("ship no settings file") currently satisfied; P3 must NOT regress it. |
| `git apply` avail | `git --version; git apply --help` | `git version 2.50.1`; `YES git apply is available` | 3e3159e / 06-13 | Pack-Chat merge-back primitive is available. |

---

## 2. Q-A / Q-B re-probe — merge-back drivers

### 2.1 Q-A (write-escape) — AFFIRM the first design, with a sharper boundary

**First design's conclusion:** non-isolated parent-tree writes work; isolated writes escape only via /tmp.

**My independent finding:** PARTIALLY CONFIRMED, and I can prove the /tmp half directly where the first design could only infer it. I am a spawned agent; I wrote to `/tmp/bd197-adversarial-probe-46588.txt` and read it back successfully. So **/tmp is a writable escape for a spawned agent — proven, not inferred.** The first design flagged honestly that it could not test the isolated-regime parent-tree rejection without a git-mutating spawn; that limitation is real and I inherit it. The conclusion stands on (a) the proven /tmp-writability + (b) the documented isolated-regime rejection (commit-discipline §2) + (c) the live observation that `~/.claude/settings.json` ALSO carries `"Write(/tmp/*)"` in its permissions allowlist — i.e., /tmp-write is an explicitly granted path on this machine.

**VERDICT: AFFIRM.** The /tmp handoff is the correct escape. One hardening note the first design missed: because /tmp-write is granted in the USER'S settings (not the pack's), the design must NOT assume the handoff dir is writable by construction — it must treat a failed handoff Write as a degradation signal (fall back to in-place report), not a hard error.

### 2.2 Q-B (worktree path/branch return) — AFFIRM

**First design's conclusion:** no reliable structured return of `{worktree_path, branch}`; auto-removal races capture; Option 5/3 rejected.

**My independent finding:** CONFIRMED. `git worktree list` and the absent `.git/worktrees`/`.claude/worktrees` dirs show no `worktree-agent-*` artifact exists for an in-place spawn, so there is nothing to return in the common case; and the Agent tool's documented return is textual, not a structured tuple. P1 §1.5's bug citations (#38287 silent-delete of unmerged branches; #55435 leftover prune-failure) make any "capture the branch before removal" primitive a race against a known-buggy cleanup. **VERDICT: AFFIRM** — Option 3 (commit-to-throwaway-branch) and Option 5 (capture-before-return) are correctly rejected. The patch-in-/tmp artifact survives auto-removal because it lives outside the removable worktree; that is the right property to depend on.

### 2.3 Joint mechanism selection — AFFIRM (property-fit, not precedent)

1 (floor) + 2 (reports for all agents via /tmp when isolated) + 4 (RW patch merge-back) is the only combination that (a) preserves `agents-never-commit` absolutely, (b) survives the silent-delete bug class, (c) needs neither a relaxation nor a returned branch. I independently reach the same selection. **AFFIRM.**

---

## 3. CONSTRAINT 5 — the mode-decision contract: CHALLENGE (the core finding)

This is the part the user mandated I verify + harden hardest. The first design's §2.1 presents `bgIsolation` × `baseRef` as a "cross-product" and lists "three documented developer postures." That is a narrative, NOT a decision matrix, and it has three defects: (A) it is **incomplete** (not every value combination has a defined cell); (B) it contains a **false cell** (the central "baseRef:head → isolated" claim is refuted by the live system); (C) it **conflates two distinct detections** and never states the exact keys/values/precedence a coder reads. A coder handed §2.1 CANNOT get it right. Below I build the complete matrix and show what the design must say instead.

### 3.1 The decisive empirical refutation

My live `~/.claude/settings.json` contains exactly `"worktree": { "baseRef": "head" }` with NO `bgIsolation` key. Per the first design's "posture 3" (§2.1 / §0.0.3), setting `baseRef:"head"` (with `bgIsolation` not `"none"`) is the OPT-IN-TO-ISOLATED posture. **Yet this very agent — spawned under exactly that settings state — runs IN-PLACE on branch `v11-dev` with no worktree created.** 

Empirical-Evidence Block:
- Command: `git rev-parse --abbrev-ref HEAD` → `v11-dev`; `ls .git/worktrees` → `Not a directory`; `python3 -c "...json..."` on `~/.claude/settings.json` → `worktree value: {"baseRef": "head"}`, `bgIsolation` absent.
- HEAD/date: 3e3159e / 2026-06-13.
- Interpretation: **`baseRef` does NOT trigger isolation. `baseRef` only governs the BASE REF *if and when* isolation happens.** Isolation is gated by a SEPARATE decision (the per-spawn `isolation` parameter and/or `bgIsolation`, and/or the Agent-tool default), which here resolved to "no isolation." 
- Conclusion: **NOT-SUPPORTED** for the first design's "posture 3" as a *trigger*. `baseRef:"head"` is necessary-but-not-sufficient for isolated mode; alone it produces in-place.

This matters enormously for constraint 5: the user's sharpened requirement is that the SYSTEM detects the mode from settings. The first design says "set `baseRef:"head"` → the pack uses patch-handoff merge-back" (§2.1 posture 3, §5.1(a) bullet). **That inference is false.** A developer who sets `baseRef:"head"` and nothing else is STILL in-place (as I am). If the pack keyed its merge-back behavior off "`baseRef` is set," it would wrongly expect a /tmp patch handoff from an agent that actually edited the parent tree in place.

### 3.2 The two-axis truth (corrected model)

Isolation is governed by TWO independent things, and `baseRef` is NEITHER of the two triggers:

- **Axis 1 — DOES isolation happen? (the trigger)** Determined by: the per-spawn Agent-tool `isolation` parameter (which the pack's own rule forbids passing — CLAUDE.md "no `isolation:"worktree"`"), AND `worktree.bgIsolation` for background/subagent execution (`"none"` = force in-place; other/unset = product default, which today is in-place for the Agent-tool path per my live observation). 
- **Axis 2 — IF isolated, from WHERE? (the base, NOT a trigger)** `worktree.baseRef`: `"fresh"` (default, `origin/HEAD`) vs `"head"` (local HEAD). Irrelevant when Axis 1 = no-isolation.

So `baseRef` is a *modifier of an already-isolated mode*, not a mode selector. Any "detect the mode from `baseRef`" design is detecting the wrong key.

### 3.3 THE COMPLETE MODE-DECISION MATRIX (what the design must adopt)

Every `bgIsolation` × `baseRef` cell, with the per-spawn `isolation` parameter held at the pack's mandated value (NOT passed / "none"), since the pack rule forbids passing `isolation:"worktree"`. "Active mode" = what the pack must DO; "merge-back path" = the concrete handoff the orchestrator expects.

| # | `bgIsolation` | `baseRef` | Resulting runtime regime | Active pack MODE | Merge-back path the orchestrator expects |
|---|---|---|---|---|---|
| 1 | unset | unset | in-place (product default today) | **IN-PLACE** | working-tree edits + report in parent tree |
| 2 | unset | `"fresh"` | in-place (baseRef inert; no isolation) | **IN-PLACE** | working-tree + parent-tree report |
| 3 | unset | `"head"` | in-place (baseRef inert) — **THIS IS MY LIVE CASE** | **IN-PLACE** | working-tree + parent-tree report |
| 4 | `"none"` | unset | forced in-place | **IN-PLACE** | working-tree + parent-tree report |
| 5 | `"none"` | `"fresh"` | forced in-place (baseRef inert) | **IN-PLACE** | working-tree + parent-tree report |
| 6 | `"none"` | `"head"` | forced in-place (baseRef inert) | **IN-PLACE** | working-tree + parent-tree report |
| 7 | (isolating value) | unset | isolated @ `origin/HEAD` (WRONG-base bug surface #45371) | **ISOLATED-RISKY** | /tmp patch + /tmp report; WARN wrong-base |
| 8 | (isolating value) | `"fresh"` | isolated @ `origin/HEAD` | **ISOLATED-RISKY** | /tmp patch + /tmp report; WARN wrong-base |
| 9 | (isolating value) | `"head"` | isolated @ local HEAD (intended opt-in) | **ISOLATED** | /tmp patch + /tmp report |

Notes that make it coder-proof:
- **Rows 1–6 ALL collapse to IN-PLACE.** `baseRef` never changes the mode in rows 1–6 — it is inert without isolation. This is the cell-set the first design's narrative obscures.
- **"(isolating value)"** for `bgIsolation` in rows 7–9 is whatever value(s) the running Claude Code version uses to mean "do isolate background/subagents" (the docs name `"none"` as the off value; the on value(s) are version-specific and the pack must NOT hardcode a guess — see §3.5). The pack treats "not `none` AND a worktree was actually created" as the isolated trigger.
- **Row 9 is the only fully-intended opt-in.** Rows 7–8 are isolated-but-wrong-base (the historic bug); the pack must still function (the patch still applies onto the parent), but the orchestrator surfaces a "your worktree branched from the default branch, not your feature branch" warning.
- **Precedence is now trivial because there is no conflict to resolve:** `bgIsolation` is the ONLY mode trigger among the two keys; `baseRef` never competes with it. The first design's worry about "precedence when both keys are present" dissolves once the axes are correctly assigned — there is no contradictory cell because `baseRef` has no mode-authority. The matrix has zero undefined and zero contradictory cells.

### 3.4 Why "settings-driven detection" is mostly illusory — and what to do instead

The user's constraint 5 wants the system to DETECT the mode from `settings.json`. The hard truth my probe exposes: **settings do NOT deterministically tell you the runtime regime.** Counter-examples, all live or bug-cited:
- Rows 1–9 show `baseRef` tells you nothing about the mode.
- `bgIsolation` *intends* to gate isolation, but #39886 (isolation silently fails → runs in MAIN) and #59848 (interactive sessions misclassified as background) mean the *declared* setting can disagree with the *actual* regime.
- I am the proof: settings say `baseRef:"head"`; regime is in-place.

Therefore the ONLY deterministic detection is the **runtime-regime self-detect** the first design already proposes (is `pwd` a `worktree-agent-*` worktree? is HEAD a `worktree-agent-*` branch?). That is ground-truth; settings are at best a hint. The corrected contract for the coder:

1. **Settings are read by the DEVELOPER + documented in OPTIONAL-FEATURES, not parsed by the pack at runtime.** The pack ships/parses no settings file (constraint 6). "Settings-driven" means: the developer's settings choice DETERMINES which row of §3.3 they land in; OPTIONAL-FEATURES documents the rows so the developer can choose Row 9 knowingly.
2. **The agent detects its ACTUAL regime at runtime** (the §3.3 "resulting runtime regime" column), via the deterministic `pwd`/HEAD check, and branches its write-target + handoff on that — never on the settings values, which it cannot see and which can lie.
3. **The orchestrator detects the regime from what the agent REPORTS** (a /tmp patch path ⇒ treat as isolated; in-place working-tree edits ⇒ treat as in-place), never from an assumption about the developer's settings.

This is strictly more robust than "detect the mode from settings," and it is the only version that is deterministic AND coder-implementable. The design must replace its §2.1 "three postures + cross-product" prose with the §3.3 matrix + this three-point runtime contract. **Without this correction the planner would encode a false trigger.**

### 3.5 Hardening: do NOT hardcode the `bgIsolation` "on" value

The first design says `bgIsolation:"none"` = in-place and treats everything else as isolating. The docs only firmly define `"none"`. The pack must define the regime by GROUND TRUTH (a worktree was actually created → isolated), not by guessing the enumerated "on" values, which are version-specific (v2.1.143+) and may change. The runtime self-detect already does this correctly; the OPTIONAL-FEATURES doc should describe `bgIsolation:"none"` as the explicit "force in-place" lever and describe Row 9 by the OUTCOME ("a `worktree-agent-*` checkout appears") rather than by an exact magic value.

---

## 4. Conflict protocol — AFFIRM with one under-specified guarantee

§2.5 (--check → --3way → STOP+re-spawn, orchestrator never hand-merges) is sound and rule-consistent (hand-merging IS a fix; Pack Chat does no fixes). The re-spawn-fresh-coder choice is correct per fresh-agent-default. I AFFIRM the ceiling.

**Gap to close before the planner:** the protocol does not state an **atomic-apply guarantee for the multi-RW case.** `git apply` on patch A can partially succeed then patch B fails `--check`; the design must specify: apply patches one at a time, each as `git apply --check` THEN `git apply` THEN review THEN commit, so the tree is never left with a half-applied multi-patch set; and on any `--check`/`--3way` failure, the orchestrator STOPS before applying that patch (the already-committed earlier patches are fine; the failing one re-spawns). The first design implies sequential apply ("apply patches sequentially, never concurrently") but does not nail the commit-between-patches boundary that makes partial-apply recoverable. Also missing: a `git apply --3way` requires the patch's base blobs to be present in the repo; for a patch cut in an isolated worktree branched at `origin/HEAD` (Rows 7–8), `--3way` context may not resolve — the design should note that Rows 7–8 patches may fail `--3way` more often and that the re-spawn (against current HEAD, in-place or Row-9) is the recovery, which is already the protocol. Minor, but state it.

---

## 5. P2 removal plan + blast radius — AFFIRM with measured reconciliation

My independent `rg --hidden --no-ignore` at HEAD 3e3159e:
- The prohibition/worktree pattern hits the 3 commit-discipline mirrors + CLAUDE.md + CONCEPTUAL-REVIEW-METHODOLOGY + the maintenance-docs plan/research set + archive — consistent with the first design's 13-primary + ~7-operational split. I confirmed each disputed file individually: `PLAN-DOC-CONCISION-GUARDRAILS.md:187` carries "NO worktree isolation" (real carrier); `RESEARCH-CLAUDE-REPOS-SURVEY.md` has 7 worktree/isolation/baseRef hits (real carrier); the implementation-report skill (lines 14/21/43/48) and pack-coder.md (lines 3/13/58/75) carry the operational coupling the first design's §4.2 names. **All §4.1/§4.2 dispositions check out.**
- **Dangling-ref reconciliation (corrected, explicit):** `feedback_worktree_isolation_broken_from_v11_clone` appears in 10 files = 4 archive + 6 active. Of the 6 active, **3 are BD-197-process files** (BD-197.md, ARCHITECTURE-BD-197-WORKTREE-ISOLATION.md, RESEARCH-BD-197-P1) which are the allowlist, leaving **exactly 3 active non-process carriers**: ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md, RESEARCH-19C-G-ITEMS-VERIFICATIONS.md, RESEARCH-CLAUDE-REPOS-SURVEY.md. **This is the first design's "3 active / 7 total" — CONFIRMED**, with the previously-unstated detail that the 7-total = 3-non-process-active + 4-archive (and the 3 process files are excluded as allowlist, not counted as carriers). The first design should state the process-file exclusion explicitly so the P2 grep-ZERO gate's allowlist is unambiguous. The entry's "4" remains the stale figure; the measured set wins (a pack-chat-only bookkeeping update).

**P2.5 completeness gate (§4.5):** AFFIRM — the grep-ZERO gate with a documented allowlist is the right measure-then-bound shape. Harden: the allowlist MUST enumerate the 3 BD-197-process files + OPTIONAL-FEATURES + archive explicitly, and the gate regex must include `baseRef` and `bgIsolation` (the first design's gate regex omits `bgIsolation`).

---

## 6. Graceful-degradation matrix — CHALLENGE (not exhaustive); corrected below

The first design's §2.2 lists the right principles ("agent never assumes isolated"; "orchestrator never assumes isolation succeeded") but presents NO exhaustive cell table, and the user requires "TEAMS on/off × settings present/absent, zero failures." Here is the corrected exhaustive matrix. Rows are the §3.3 regime collapsed to {IN-PLACE, ISOLATED} × {TEAMS off, TEAMS on}. "Zero-failure" = the orchestrator finds the work and commits it; nothing is silently lost.

| TEAMS | Regime (ground truth) | What the agent does | What the orchestrator does | Failure-safe? |
|---|---|---|---|---|
| off | IN-PLACE (Rows 1–6) | edits parent tree; report to parent path | reads working-tree diff + report; commits | YES (today's model) |
| off | ISOLATED (Rows 7–9) | edits worktree; `git diff` → /tmp patch + /tmp report | reads /tmp patch; `--check`/`--3way`/apply; commits | YES (patch survives auto-removal) |
| off | ISOLATED-but-silently-fell-to-MAIN (#39886) | THINKS isolated, actually edited parent tree | self-detect sees in-place regime → behaves as IN-PLACE row | YES (self-detect is ground-truth, not settings) |
| on | IN-PLACE | teammates edit shared tree (file-ownership boundaries) | per-teammate reports; commits | YES (disjoint scope) |
| on | ISOLATED (docs-intended per-session worktrees) | each teammate edits own worktree; /tmp patch each | sequential `--check`/apply per patch; conflict protocol §4 | YES if patches disjoint; conflict protocol if not |
| any | settings declare isolate but product default flips later (#59580 trajectory) | self-detect catches the ACTUAL regime regardless of the setting drift | keys merge-back off the agent's report, not the setting | YES (the whole point of ground-truth self-detect) |

The two cells the first design's narrative does NOT explicitly cover — **#39886 silent fall-to-MAIN** and the **`bgIsolation` default-flip trajectory** — are exactly the "no destructive surprises" cases the user named. They are failure-safe ONLY because of the ground-truth self-detect (§3.4), which is the reason §3.4's correction is load-bearing for degradation, not just for mode-detection. The design must show this table.

---

## 7. Pack/project separation — AFFIRM, with one shipped-settings nuance

§3.1 (pack: PACK-AGENTS Class column) and §3.2 (project: PM-CHAT table + agent-run.sh projection) are genuinely native per surface; §5.3 authors the two OPTIONAL-FEATURES homes independently (the project doc already exists — I confirmed `project-template/docs/pack/OPTIONAL-FEATURES.md` is present, 5490 bytes). Not a byte-copy. **AFFIRM.**

**Nuance the first design missed:** `project-template/.claude/settings.json` IS shipped and currently carries `"Bash(git add *)"` in its permissions allowlist + a PostToolUse hook. Two consequences for P3: (1) constraint 6 ("ship no settings file for worktree") is satisfied today because that shipped file has NO `worktree` key — P3 must NOT add one (the doc tells the developer to add it to THEIR settings, never the shipped template); (2) the project-side merge-back doc must reconcile with the fact that the client `coder` runs under a settings file that ALLOWS `git add` at the Bash-permission layer — the `agents-never-commit` ban is enforced by the agent's Hard rule + agent-run.sh `--disallowedTools`, NOT by the shipped settings.json (which permits `git add` for the human/PM). The folded verb-hardening (§5.1c) must therefore land in agent-run.sh `--disallowedTools` (add `git stash`/`reset`/`restore --staged`/`checkout`), not only in prose — otherwise the prose ban and the launch-flag enforcement diverge. The first design routes hardening through PACK-CHAT §12 + prose surfaces but does NOT name the `agent-run.sh` `CLAUDE_READONLY_FLAGS` / `--disallowedTools` enforcement surface as a hardening target. That is an enumerate-encoding-surfaces gap.

---

## 8. RW/RO SSOT placement — AFFIRM both

- **Pack (PACK-AGENTS Class column + parity check):** correct. Measured: 5 agents, 1 RW (`pack-coder`) + 4 RO. The parity check {roster Class} ↔ {agent-file header} is measure-then-bound-able (the set is exactly 5). AFFIRM. One note: `pack-reviewer` carries `Write, Edit` in `tools:` yet is RO — so the parity check MUST bind to the PROSE mandate header, never to the `tools:` list (the first design says "agent-file header is authoritative" — correct; just make the validator read the header, not tools).
- **Project (PM-CHAT table SSOT + agent-run.sh `READONLY_AGENTS` projection, CI set-equality):** correct and closes a real gap — the inventory confirms the 4 forms agree only by hand today with nothing enforcing it. Measured: 14 RO + 2 RW; `READONLY_AGENTS` has exactly the 14. AFFIRM. The stale `agent-run.sh` comment (lines ~92–94 "Edit/Write excluded at agent-definition level") must be fixed in P3 as the first design notes.

**`repo-ops` as RW sub-label, not a third class:** AFFIRM — inventing a "scripted-write" class would complicate the validator for no benefit; the agent-file Hard rules already narrow it.

---

## 9. commit-discipline skill redesign — AFFIRM the direction, sharpen one line

The skill TODAY hard-asserts (verified lines 20 + 22): `pwd` "Must end in worktree path" and HEAD "Must start with `worktree-agent-`". Under Rows 1–6 (in-place) BOTH assertions are FALSE for a correctly-running agent — confirmed: I am such an agent (HEAD `v11-dev`). The first design's §5.4 "make it regime-DETECTING not regime-ASSERTING" is exactly right. Sharpen: the redesigned §1 must say the detection is **non-fatal in both directions** AND must give the coder the literal branch:
- `pwd`/HEAD indicate `worktree-agent-*` ⇒ ISOLATED ⇒ code Writes under `pwd`, IMPL-report + `git diff` patch to the named /tmp handoff dir.
- otherwise ⇒ IN-PLACE ⇒ Writes under the parent tree (today's deliverable), report to the named parent path.
- Neither is an error; never retarget another agent's main checkout (keep the BD-119 C-2 guard as a cautionary note, NOT a blanket "every Write under pwd" — that blanket is the bug-era artifact).
This is coder-proof. AFFIRM with the literal-branch addition.

---

## 10. Decisions to surface to the user (delta from the first design's §7)

The first design's D1–D6 are reasonable. My adversarial pass ADDS / CHANGES:

- **D-NEW-1 (supersedes the first design's "settings-driven detection" framing):** Adopt §3.3's complete matrix + §3.4's three-point runtime contract. The pack does NOT parse settings at runtime; it detects the ACTUAL regime via the agent's `pwd`/HEAD self-check and the orchestrator's read of the agent's report. `baseRef` is documented as a base-modifier, never a mode-trigger. **Recommend: adopt — it is the only deterministic, coder-proof, bug-resilient reading of constraint 5.** Evidence: my live `baseRef:"head"` + in-place regime (§3.1).
- **D-NEW-2:** Folded verb-hardening must also land in `agent-run.sh` `--disallowedTools` (project) and be reconciled with the shipped `project-template/.claude/settings.json` `"git add *"` allow, not only in prose. Recommend: yes (enumerate-encoding-surfaces). Evidence: §7.
- **D-NEW-3:** P2 grep-ZERO gate regex must include `bgIsolation` (first design omitted it) and the allowlist must enumerate the 3 BD-197-process files explicitly. Recommend: yes. Evidence: §5.
- **D-NEW-4:** Graceful-degradation acceptance must test the #39886 silent-fall-to-MAIN cell and the TEAMS-on isolated cell, not just the happy paths. Recommend: yes. Evidence: §6.
- **AFFIRMED unchanged:** D3 (conflict ceiling — with §4's atomic-apply sharpening), D5 (`agents-never-commit` not relaxed — strongly affirmed on independent Q-B), D1/D2 (SSOT homes).

---

## 11. Is the design ready for the planner?

**NO — not until §3 is folded in.** The merge-back architecture, RW/RO placement, P2 plan, and conflict ceiling are all sound and I affirm them on independent evidence. But constraint 5 — the explicit deterministic mode-decision contract that was the entire reason for this adversarial pass — is incomplete and contains a false trigger cell in the first design. A planner handed the first design as-is would encode "`baseRef:"head"` ⇒ isolated ⇒ expect /tmp patch," which my live system proves wrong, producing an orchestrator that looks for a /tmp patch from an agent that edited the parent tree in place. Fold §3.3 (matrix) + §3.4 (runtime contract) + §6 (degradation table) + the §4/§5/§7 sharpenings into the first design, then proceed to the planner.

---

## 12. Rules-Applied Verification Block

| # | Rule (as named in prompt) | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | Agents never commit (git read-only; probes read-only, /tmp only) | Only read-only git verbs run: `git rev-parse HEAD/--abbrev-ref`, `git worktree list`, `git --version`, `git apply --help`. No add/commit/push/stash/reset/mv/rm/apply. The one mutation was a /tmp scratch file (created+removed), not a repo/git op. | COMPLIANT |
| 2 | Read-only mandate (write ONLY this report) | Exactly one repo file written: `maintenance-docs/v11-implementation/ARCHITECTURE-BD-197-ADVERSARIAL-REVIEW.md`. All else Read/Bash-grep. | COMPLIANT |
| 3 | Empirical-Evidence Blocks (incl. re-run probes) | §1 probe table + §2.1/§2.2 Q-A/Q-B + §3.1 refutation block + §5 reconciliation each carry command + verbatim output + HEAD `3e3159e` + date 2026-06-13 + conclusion. | COMPLIANT |
| 4 | Adversarial rigor; mode-matrix completeness shown | §0 challenges by default; agreements (§2,§5,§7,§8) cite independent evidence; the COMPLETE 9-cell mode matrix is built (§3.3) and the first design's model shown incomplete + false-celled (§3.1–3.4). | COMPLIANT |
| 5 | CI-guard measure-then-bound | §5 (P2 grep-ZERO gate: measured tree, allowlist sized to KEEP = 3 process files + OPTIONAL-FEATURES + archive, regex hardened to include bgIsolation); §8 (RW/RO parity checks sized to measured 5 / 14+2 sets). | COMPLIANT |
| 6 | Pack/project separation + trinity parity + cross-CLI normalization | §7 affirms separate native artifact sets + flags the shipped-settings/agent-run.sh enforcement nuance; §9 keeps trinity-quad for commit-discipline; cross-CLI handled per surface. | COMPLIANT |
| 7 | Architect-doc-vs-reality reconciliation | §3.1 reconciles the first design's claimed model against the LIVE system (settings vs regime); §5 reconciles claimed counts against measured tree; §11 names exactly what must change before the planner consumes the doc. | COMPLIANT |
| 8 | Unbiased re: sealed discussion | The sealed pre-design discussion was neither sought nor referenced; all conclusions derive from BD-197, P1/inventory research, the read corpus, and my own probes. | COMPLIANT |
| 9 | Rules-Applied Verification Block present | This table. | COMPLIANT |
| 10 | PREFLIGHT + STOP-MEANS-STOP | PREFLIGHT line emitted in chat immediately before this Write ("PREFLIGHT: adversarial review complete; mode-matrix built; Q-A/Q-B re-probed; about to Write …"). No parent stop received. | COMPLIANT |

---
*End of ARCHITECTURE-BD-197-ADVERSARIAL-REVIEW.md*
