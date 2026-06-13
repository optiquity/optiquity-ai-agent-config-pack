# ARCHITECTURE-BD-197 — SECOND ADVERSARIAL REVIEW of the RECONCILED worktree-isolation design

**Role:** pack-architect (FRESH, ADVERSARIAL — second adversarial pass, reviewing the RECONCILED design). **Mode:** design-review only (one doc written; everything else read-only).
**Repo:** optiquity-ai-agent-config-pack-v11-dev · **Branch:** v11-dev · **HEAD at review:** `3e3159ee8b5e97bf8775ecf67a76867d28933a3e`.
**Date:** 2026-06-13.
**Target under review:** `maintenance-docs/v11-implementation/ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` (claims `Status: PLANNER-READY`).
**Cross-checked against:** `ARCHITECTURE-BD-197-ADVERSARIAL-REVIEW.md` (first adversarial — to verify its 9 corrections landed), `backlog/BD-197.md` (D1–D6 LOCKED + notes 6–9 — FIXED inputs), `RESEARCH-BD-197-P1-WORKTREE-ISOLATION.md`, `RESEARCH-BD-197-AGENT-PERMISSION-INVENTORY.md`, `CLAUDE.md ## Pack memory` (full).
**Sealed pre-design discussion:** NOT sought, NOT referenced (UNBIASED rule).

This review treats the reconciled design as a hypothesis to BREAK. It re-runs the load-bearing probes independently, re-builds the 9-cell matrix from scratch, verifies each of the first adversarial's 9 corrections, and hunts for newly-introduced defects. It changes nothing but this file.

---

## 0. Headline verdicts (read this first)

| Area | Reconciled design's call | My second-adversarial verdict |
|---|---|---|
| Q-A `/tmp` write-escape | regime-dependent; `/tmp` is the escape; failed handoff = degradation signal | **AFFIRM** — re-proved `/tmp` writable by a spawned agent independently (§1). |
| Q-B no worktree-path return | NO structured return; Options 3/5 rejected | **AFFIRM** — re-confirmed; no `worktree-agent-*` artifact for an in-place spawn (§1). |
| Mode trigger = `bgIsolation` NOT `baseRef` (D6) | corrected; ground-truth runtime self-detect | **AFFIRM** — independently REFUTED `baseRef`-as-trigger live: `baseRef:"head"` set + TEAMS on, yet in-place (§1, §2). The decisive correction held. |
| 9-cell `bgIsolation`×`baseRef` matrix (§3.3) | complete, zero undefined/contradictory cells | **AFFIRM with one coder-ambiguity** — I rebuilt it cell-by-cell and it is correct; but "(isolating value)" in rows 7–9 leaves the per-spawn `isolation` parameter unverified, and §3.3's framing partly conflicts with §3.2 on WHAT the chat passes (§3 of this review). Not a blocker; a planner-flag. |
| Merge-back model 1+2+4 + `agents-never-commit` preserved | AFFIRMED | **AFFIRM** — independently re-derived (§4). Zero commit-ban gaps. |
| Conflict protocol + multi-RW atomic-per-patch (D3) | sharpened | **AFFIRM** — sound and complete (§5). |
| Git-permission denylist + principle (D5/note 8) | denylist + read-only-only principle + mechanical backstop | **AFFIRM with one gap** — `git diff > file` redirection is on the ALLOWED set but a naive `Bash(git diff:*)`-style backstop will not see the redirect; and the `apply`-denied / `diff`-allowed split needs the backstop to be verb-precise, not pattern-loose (§6). |
| RW/RO SSOT triple reinforcement (D1/D2) | pack Class column + project PM-CHAT + CI array + per-file | **AFFIRM** — measured 1RW+4RO / 2RW+14RO independently; native per surface (§7). |
| Graceful degradation matrix (§8) | complete incl. #39886 + default-flip | **AFFIRM** — exhaustive over {regime}×{TEAMS}; zero-failure cells correct (§8). |
| **P2 grep-ZERO gate (§11.5) vs Guard-A signature (§13.1)** | "regex HARDENED to include `bgIsolation`/`baseRef`" | **CHALLENGE — the two gate definitions CONTRADICT each other, and the §11.5 broad regex forbids the very tokens P3 is required to write.** This is a measure-then-bound defect + a coder-ambiguity (§9). The single remaining blocker. |
| P2 allowlist enumeration ("the 3 BD-197-process files") | enumerated | **CHALLENGE — the "3 process files" count is STALE/wrong against the live tree (now 5+ BD-197 artifacts carry the token).** Arithmetic carried verbatim from the first adversarial without re-measuring (§9). |
| NEW-FORK-1 (P3 launcher) | gate-then-probe-then-degrade | **AFFIRM** — sound; cwd-scoping risk correctly characterized (§10). |

**Bottom line:** Every load-bearing ARCHITECTURAL choice is sound and I affirm it on independent evidence — the merge-back model, the `bgIsolation` correction, the runtime ground-truth contract, the RW/RO placement, the conflict protocol, and the degradation matrix all hold. All 9 of the first adversarial's corrections were applied. The design is **NOT YET planner-ready** for exactly one reason: the **P2 completeness-gate specification is self-contradictory and over-broad** (§9). It is a tight, bounded fix (one regex + one count), not a re-architecture. Fix §9 and the design is planner-ready.

---

## 1. Independent probes (read-only) — re-run this pass

All probes run at HEAD `3e3159e`, branch `v11-dev`, 2026-06-13. No git mutation. The only filesystem write outside this report was one `/tmp` scratch file (created + removed).

| Probe | Command | Verbatim key output | Conclusion |
|---|---|---|---|
| Runtime regime | `git rev-parse --abbrev-ref HEAD` | `v11-dev` | This agent runs IN-PLACE, not in a `worktree-agent-*`. |
| HEAD | `git rev-parse HEAD` | `3e3159ee8b5e97bf8775ecf67a76867d28933a3e` | matches review HEAD. |
| Worktree dirs | `ls .git/worktrees; ls .claude/worktrees` | `.git/worktrees: Not a directory` / `.claude/worktrees: No such file or directory` | NO isolated worktree for this spawn. |
| `git worktree list` | (as named) | only `…/optiquity-ai-agent-config-pack [main]` + `…-v11-dev [v11-dev]` | No `worktree-agent-*`; consistent with in-place. |
| **Q-A `/tmp` write** | `printf … > /tmp/bd197-adv2-probe-$$.txt; cat; rm` | `WROTE /tmp/bd197-adv2-probe-96253.txt` then `REMOVED …` | **`/tmp` IS writable by this spawned agent — proven, not inferred.** |
| **Live settings** | `python3 -c json.load(~/.claude/settings.json)['worktree']` | `{'baseRef': 'head'}`; `bgIsolation present: False`; `TEAMS env: 1` | `baseRef:"head"` set, NO `bgIsolation`, TEAMS on. |
| Env regime | `env | grep -iE claude/teams` | `AI_AGENT=claude-code_2-1-170_agent`, `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` | Claude Code v2.1.170; TEAMS on; still in-place. |
| `git apply` avail | `git --version; git apply --check /dev/null` | `git version 2.50.1`; `error: No valid patches in input` (verb exists) | orchestrator merge-back primitive available. |

**Empirical-Evidence Block — the decisive mode-refutation (re-run independently):**
- Command: `git rev-parse --abbrev-ref HEAD` → `v11-dev`; `ls .git/worktrees` → `Not a directory`; `python3 … json` → `worktree={'baseRef':'head'}`, `bgIsolation` absent; `env` → `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`.
- HEAD/date: `3e3159e` / 2026-06-13.
- Interpretation: live settings carry `worktree.baseRef:"head"` and NO `bgIsolation`, TEAMS ON — yet THIS agent runs IN-PLACE on `v11-dev`, no worktree created. The first design's "posture 3" (`baseRef:"head"` ⇒ isolated) is refuted a SECOND time, by a different agent instance.
- Conclusion: **NOT-SUPPORTED** for `baseRef` as a trigger. The reconciled design's central correction (D6) is INDEPENDENTLY CONFIRMED.

---

## 2. Did the first adversarial's 9 corrections actually land? (verified one-by-one)

The first adversarial review produced these corrections (its §0 table + §10 D-NEW set + §11). I checked each against the reconciled doc by content.

| # | First-adversarial correction | Where it should land | Verified in reconciled? | Evidence |
|---|---|---|---|---|
| 1 | Mode trigger = `bgIsolation` NOT `baseRef`; runtime ground-truth, never trust settings | §3 | **YES — fully** | §3.1 two-axis truth; §3.4 three-point runtime contract; §1.1 re-run refutation. Matches D6. |
| 2 | The COMPLETE 9-cell matrix replaces "three postures" | §3.3 | **YES — verbatim** | §3.3 reproduces all 9 cells identically to the first adversarial's §3.3; §3.3 note explicitly says it "REPLACES the first design's §2.1 narrative." |
| 3 | COMPLETE graceful-degradation table incl. #39886 + default-flip | §8 | **YES** | §8 table has the `#39886 silent-fall-to-MAIN` row + the `default-flip` row; both marked failure-safe via ground-truth. |
| 4 | Multi-RW atomic-per-patch apply boundary explicit | §6 | **YES** | §6.1 "each patch is its own atomic check→apply→review→commit unit." |
| 5 | `/tmp` handoff = degradation signal on failure, not hard error | §1.2 | **YES** | §1.2 hardening + §4.1 step 2 fallback ("never hard-errors on a failed handoff Write"). |
| 6 | git-permission hardening also targets `agent-run.sh --disallowedTools` + reconcile shipped `git add` allow | §5.3 | **YES** | §5.3 "Mechanical backstop" bullet names `agent-run.sh --disallowedTools` + the shipped-settings `git add` reconciliation nuance. |
| 7 | P2 grep-ZERO gate regex includes `bgIsolation`; allowlist enumerates process files explicitly | §11.5 / §13.1 | **PARTIAL — landed but DEFECTIVE** | regex now includes `bgIsolation` (§11.5), BUT see §9 of this review: the enumeration is stale + the broad regex contradicts §13.1 + forbids legitimate post-P3 tokens. |
| 8 | Parity check binds to PROSE mandate header, never `tools:` | §4.3 / §13.2 | **YES** | §4.3 "The validator reads the PROSE header, NEVER `tools:`"; §13.2 Guard B repeats it; cites `pack-reviewer` Write,Edit-yet-RO. |
| 9 | (atomicity / `--3way` base-blob caveat) | §6.3 | **YES** | §6.3 states the `--3way` base-blob caveat for Rows 7–8 patches. |

**Verdict: 8 of 9 corrections held cleanly; correction #7 landed in form but is itself defective** (the regex was hardened but not measure-then-bound-verified against the tree — §9). Every other correction is faithfully and correctly integrated.

---

## 3. The 9-cell matrix — rebuilt independently + checked for contradiction

I reconstructed the `bgIsolation` × `baseRef` matrix from the two-axis truth WITHOUT reading the design's table first, then compared.

**Axis 1 (trigger):** `bgIsolation` — `"none"` ⇒ force in-place; unset ⇒ product default (today in-place per live probe §1); isolating value ⇒ isolate. The per-spawn `isolation` parameter is the OTHER trigger the chat controls.
**Axis 2 (base, NOT a trigger):** `baseRef` — `"fresh"` (=`origin/HEAD`, default) / `"head"` (=local HEAD). Inert unless Axis 1 isolates.

My independently-derived collapse:
- `bgIsolation ∈ {unset, "none"}` × `baseRef ∈ {unset, "fresh", "head"}` = 6 cells, ALL → IN-PLACE (baseRef inert). ✔ matches design rows 1–6.
- `bgIsolation = isolating` × `baseRef ∈ {unset, "fresh"}` → isolated @ `origin/HEAD` = ISOLATED-RISKY (wrong base). ✔ matches rows 7–8.
- `bgIsolation = isolating` × `baseRef = "head"` → isolated @ local HEAD = ISOLATED (intended). ✔ matches row 9.

**Cell-completeness:** 9/9 defined, 0 undefined, 0 contradictory. The "precedence when both keys present" worry correctly dissolves — `baseRef` has no mode authority, so there is no conflict to resolve. **AFFIRM the matrix.**

**One coder-ambiguity I surface (planner-flag, NOT a blocker):** §3.2 says "the chat controls per-task isolation via the per-spawn `isolation` parameter" and §3.3's header says the parameter is "held at the value the chat passes for the task (the pack's default-in-place tasks pass none/'none'; UC-1 parallel tasks pass the confirmed isolate value)." But §3.5 + the VERIFY-AT-IMPLEMENTATION criterion say the exact parameter name + accepted values are UNCONFIRMED until a P3 probe. So the matrix's rows 7–9 are reachable ONLY IF the per-spawn parameter (or `bgIsolation`) actually triggers isolation — which is exactly what the design honestly flags as unverified. This is internally consistent (the design does not claim it works; it gates it on the probe), but the planner MUST carry the gate forward: **rows 7–9 are PROVISIONAL until the §3.2 implementation probe confirms a working isolate trigger.** If the probe finds NO usable trigger on the live version, the design degrades to rows 1–6 only (in-place), and UC-1's "safe parallel" benefit is unrealized for v11.0. The design should state this contingency at the matrix, not only buried in §3.2/§10. Minor; the runtime ground-truth contract makes it failure-safe regardless.

**Runtime ground-truth determinism:** §3.4's three-point contract (developer sets / agent self-detects by pwd-HEAD / orchestrator detects from report) IS deterministic and coder-implementable — the agent's branch is a literal pwd/HEAD string test, the orchestrator's branch is "is there a `/tmp` patch path in the report." AFFIRM.

---

## 4. Merge-back + conflict protocol + `agents-never-commit` — re-derived

**Merge-back (1 floor + 2 reports + 4 patch):** I independently re-ran the option-fit analysis. Q-A=`/tmp`-only (proven §1), Q-B=no-return (proven §1). With those two facts, Option 3 (commit-to-throwaway-branch) needs a surviving branch (Q-B negative + #38287 live) → REJECT; Option 5 (capture-before-return) needs the returned path (Q-B negative) → REJECT. Only 1+2+4 survives and preserves `agents-never-commit`. **AFFIRM — identical conclusion, independently reached.**

**`agents-never-commit` gap-hunt:** the agent runs `git diff > /tmp/…` (read-only) + `Write` (non-git). The orchestrator alone runs `git apply` + commit. I traced every step of §4.1 and §6.1: no step has an agent run a state-changing verb. `git apply` is correctly on the DENIED set for agents (§5.1) and reserved to the orchestrator. **Zero commit-ban gaps.** AFFIRM.

**Conflict protocol (§6):** atomic-per-patch (check→apply→review→commit per patch) means the tree is never half-applied; on `--check`/`--3way` failure → STOP + surface + re-spawn fresh coder on current HEAD (no orchestrator hand-merge, consistent with "Pack Chat does no fixes"). The `--3way` base-blob caveat for Rows 7–8 is honestly stated. Partial-apply, stale-base (rows 7–8), and multiple-collision are all covered. **AFFIRM — sound + complete.**

---

## 5. (folded into §4) — conflict completeness confirmed. No separate finding.

---

## 6. Git-permission contract (denylist + principle + backstop) — AFFIRM with one precision gap

**Denylist completeness (§5.1):** I checked the enumerated set against the note-8 list. All note-8 verbs present: commit/push/add/stage/stash/rm/mv/reset/restore/checkout/clean/merge/rebase/cherry-pick/revert/am/apply/branch -d/-D/switch/worktree/config/remote/update-ref/update-index/pull/gc/reflog expire/filter-branch. The design ADDS tag/notes/replace + the "including but not limited to" catch-all + the positive read-only-only principle line. **Denylist is complete + superset of note 8.** AFFIRM.

**Allowed set (§5.2):** read-only verbs only; `git diff` (incl. `diff > file`) allowed as the patch-emit; `apply` correctly EXCLUDED for agents. Correct.

**The precision gap (MECHANICAL BACKSTOP — planner-flag):** the design says the backstop is a PreToolUse hook / `--disallowedTools` on "the named `Bash(git <verb>:*)` patterns." Two precision problems the planner must hand the coder:
1. **`git diff > /tmp/file` redirection** is the agent's load-bearing patch-emit, and it is ALLOWED. A backstop that denies broadly (e.g. blocks any `Bash(git …)` not on an allowlist) would block the patch-emit; a backstop that allows `Bash(git diff:*)` is fine, but the REDIRECTION (`> file`) is shell-level, not a git verb — confirm the `--disallowedTools` matcher does not trip on the redirect. The design's allowed-set lists it but the backstop spec does not reconcile the shell-redirect-vs-verb-matcher question. (`agent-run.sh` currently denies only `Bash(git commit:*)`/`push`/`add`/`mv` per the inventory — adding stash/reset/restore/checkout/apply/worktree/clean is correct, but `apply` must be denied for agents WITHOUT denying `diff`.)
2. **`restore --staged` vs `restore`** and **`checkout --` vs `checkout <branch>`**: the denylist denies the whole verb, which is SAFER (no read-only form of restore/checkout the agent needs), so this is fine — but the §5.1 ALLOWED note "`checkout` (incl. `checkout --`, branch switch)" is in the DENIED column while pack-coder's CURRENT prose (inventory P12) allows `git checkout -- <path>` as an exception. The design's tightening REMOVES that exception (good, consistent with D5), but the planner must ensure the pack-coder ×3 edit DROPS the `checkout -- <path>` carve-out rather than leaving it — an enumerate-encoding-surfaces lock-step item the design names but does not pin to the exact stale string. Minor.

These are precision items for the planner/coder, not architectural defects. The contract is sound. **AFFIRM with the two precision flags carried forward.**

---

## 7. RW/RO SSOT + triple reinforcement — AFFIRM (measured independently)

- **Pack:** measured 5 agent files per CLI (`pack-architect/coder/docs-researcher/planner/reviewer`); 1 RW (`pack-coder`) + 4 RO. `pack-reviewer` carries `tools: Read, Grep, Glob, Bash, Write, Edit` yet is RO — independently confirmed the validator MUST bind to the prose header, never `tools:`. The design's Guard B does exactly this. AFFIRM.
- **Project:** measured 16 agent files per CLI; `agent-run.sh READONLY_AGENTS` array = exactly 14 entries (architect/reviewer/planner/tester/docs-researcher/grpc-schema/auditor + 7 auditor-* incl. auditor-ops); `coder`+`repo-ops` absent ⇒ 2 RW. Matches the design's 14 RO + 2 RW. The set-equality guard {PM-CHAT rows}↔{READONLY_AGENTS}↔{per-file headers} closes a real un-enforced drift. AFFIRM.
- **Gemini project files have no `tools:` field** — independently confirmed (0 of 16 carry `tools:`). The design's reliance on prose header + `agent-run.sh` mode flags for Gemini RO/RW is therefore correct (cannot tool-gate Gemini). AFFIRM.
- **Native, not byte-copies:** pack uses a PACK-AGENTS `Class` column; project uses PM-CHAT table + runtime array — genuinely different artifact sets. AFFIRM separation.

**Drift-proofness:** triple reinforcement (SSOT + per-file + inline rules-in-force) plus the CI set-equality guard is enforceable. The one caveat: the inline rules-in-force block is a per-spawn human/orchestrator action, NOT CI-enforced — so it is reinforcement, not a guard. The design correctly treats the CI guard (SSOT↔per-file) as the enforcement layer and the inline block as reinforcement. Honest. AFFIRM.

---

## 8. Graceful degradation matrix — AFFIRM (exhaustive, zero-failure)

I enumerated {IN-PLACE, ISOLATED, ISOLATED-but-fell-to-MAIN(#39886)} × {TEAMS off, on} + the default-flip trajectory cell. The design's §8 table covers all of them. Each cell is failure-safe BECAUSE the orchestrator keys merge-back off the agent's REPORT (ground-truth), never off settings — so the #39886 silent-fall-to-MAIN cell (agent thinks isolated, actually edited parent) is caught by the agent's own pwd/HEAD self-detect resolving to IN-PLACE. The default-flip cell is caught the same way. **No cell can silently lose work** — the "no destructive surprises" bar is met. Codex/Gemini correctly carved to BD-217 (native sequential fallback, no parity claim). AFFIRM as exhaustive + zero-failure.

---

## 9. THE REMAINING BLOCKER — P2 completeness gate is self-contradictory + over-broad

This is the one place the reconciled design is NOT planner-ready. It has THREE coupled defects, all measure-then-bound failures.

### 9.1 The two gate definitions contradict each other

- **§11.5 P2 gate regex:** `'no worktree isolation|isolation: *"worktree"|worktree-agent-|baseRef|bgIsolation'` — INCLUDES `baseRef` and `bgIsolation` as forbidden tokens.
- **§13.1 Guard A "Measure-then-bound":** match the prohibition signature `'no worktree isolation'`, `'Do not pass .*isolation.*worktree'` — a NARROW prohibition-only signature — then the SAME bullet appends "Regex includes `bgIsolation` (D-NEW-3)."

So §11.5 forbids `baseRef`+`bgIsolation`; §13.1 first defines a narrow prohibition-only signature and then bolts on `bgIsolation`. A coder handed both cannot tell whether `baseRef`/`bgIsolation` are forbidden tokens or legitimate. **The two sections disagree.**

### 9.2 The broad regex forbids tokens P3 is REQUIRED to write

`baseRef` and `bgIsolation` are the LEGITIMATE setting-key names that the post-P3 enabled-model text + BOTH OPTIONAL-FEATURES docs MUST contain (§3.3, §9, §12.1(a) all instruct the coder to write `worktree.bgIsolation` / `worktree.baseRef`). A grep-ZERO gate that treats `baseRef`/`bgIsolation` as prohibition signatures will FIRE on the very documents P3 must author — unless they are allowlisted, which means the allowlist must enumerate every file that legitimately documents the keys. That is a self-defeating gate: the prohibition SIGNATURE is the *prohibition prose* (`no worktree isolation`, `Do not pass isolation:"worktree"`), NOT the setting-key names. Per ci-guard-measure-then-bound, the gate must match the contamination (the prohibition), not legitimate content (the key names). **The §11.5 regex mis-classifies legitimate content as contamination by default — the exact anti-pattern the measure-then-bound rule forbids.**

**Empirical-Evidence Block:**
- Command: `rg -l --hidden --no-ignore 'no worktree isolation|isolation: *"worktree"|worktree-agent-|baseRef|bgIsolation' -g '!.git' -g '!test-fixtures'` (the design's exact §11.5 regex, pre-P2 tree).
- Output: 40 files matched. Active-tree non-archive = 18 files; active non-archive AND non-(BD-197/RESEARCH-BD-197/OPTIONAL-FEATURES) = 11 files: the 3 commit-discipline mirrors, CLAUDE.md, ARCHITECTURE-BD-196-S1-CORPUS-CLASSIFICATION, EXECUTION-PLAN-V11.0, IMPLEMENTATION-REPORT-BD-196-C9, PLAN-DEPLOYMENT-PYTHON-OBSERVABILITY, PLAN-SKILL-DIMENSIONS, RESEARCH-19C-G-ITEMS-VERIFICATIONS, CONCEPTUAL-REVIEW-METHODOLOGY.
- HEAD/date: `3e3159e` / 2026-06-13.
- Interpretation: of the 11, the design's disposition table (§11.1) handles 1, 5, 6, 7, 8, 9, 12 — but `IMPLEMENTATION-REPORT-BD-196-C9` (row 12, "DISPOSITION — leave as history") and `PLAN-DEPLOYMENT-PYTHON-OBSERVABILITY` (row 13, "VERIFY then UPDATE/leave") and `PREWORK-BD-197-…` (named in the §11 audit-exclusion but NOT in the §11.5 allowlist) will STILL carry a `baseRef`/`worktree` token after P2 if "left as history" — yet they are NOT in the §11.5 grep-gate allowlist. The gate as written would FAIL on its own LEAVE-as-history dispositions.
- Conclusion: **NOT-SUPPORTED** that the §11.5 gate runs clean against the projected post-P2 tree. The gate is not sized to the KEEP set; left-as-history files matching `baseRef` are unaccounted contamination by the gate's own logic.

### 9.3 The "3 BD-197-process files" count is stale

§11.3, §10 D-NEW-3, and §13.1 all say "the 3 BD-197-process files (BD-197.md, the first design, RESEARCH-BD-197-P1)." This is copied verbatim from the first adversarial's §5, which measured BEFORE the reconciled doc and the adversarial-review doc existed.

**Empirical-Evidence Block:**
- Command: `rg -l 'feedback_worktree_isolation_broken_from_v11_clone' | grep -vi archive | grep -E 'BD-197|RESEARCH-BD-197'`.
- Output: FIVE files — `BD-197.md`, `ARCHITECTURE-BD-197-WORKTREE-ISOLATION.md` (first design), `ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` (this design), `ARCHITECTURE-BD-197-ADVERSARIAL-REVIEW.md` (first adversarial), `RESEARCH-BD-197-P1-WORKTREE-ISOLATION.md`.
- HEAD/date: `3e3159e` / 2026-06-13.
- Interpretation: the BD-197-process allowlist is now FIVE for the dangling-ref token (and this SECOND adversarial review adds a sixth once committed). The §11.5 PROSE actually expands to "the 3 BD-197-process files + this doc + the first design + the adversarial review + the two research docs" — which double-counts (the "3 process files" already includes BD-197.md + first design + RESEARCH-P1, then re-names "the first design" again) AND omits THIS second adversarial review. The label "3" is arithmetically inconsistent with its own expansion and with the tree.
- Conclusion: **NOT-SUPPORTED.** The count must be re-derived at P2-time (the design's own fresh-audit instruction covers this) AND the static label "3" must be removed from §11.3/§10/§13.1 to avoid encoding a wrong number the planner/coder might trust.

### 9.4 The fix (bounded — names the shape, not the prose)

This is a tight fix, well within reconciliation scope:
1. **Split the gate into two regexes by concern.** (a) PROHIBITION-removal gate (the grep-ZERO gate): match ONLY the prohibition signature — `no worktree isolation`, `Do not pass .*isolation.*worktree`, `worktree-agent-` in an ASSERTION context — NOT the bare setting-key names. (b) A SEPARATE positive check (if wanted) that the enabled-model text + OPTIONAL-FEATURES DO mention `bgIsolation`/`baseRef` (presence, not absence). Do not put `baseRef`/`bgIsolation` in an absence-gate.
2. **Allowlist by the LEAVE-disposition set, measured at P2-time.** The allowlist = exactly the files the disposition table marks LEAVE/DISPOSITION that still legitimately carry a matched token (archive + the history IMPL-REPORTs + BD-197 process artifacts + OPTIONAL-FEATURES) — sized to the measured KEEP set, per ci-guard-measure-then-bound, not a hand-copied "3."
3. **Drop the static "3 BD-197-process files" label** everywhere; replace with "the BD-197-process artifact set, enumerated by the P2-time measurement."

Until §11.5/§13.1/§11.3/§10-D-NEW-3 are reconciled to a single, measure-then-bound, prohibition-only gate, the design hands the P2 coder a gate that (a) contradicts itself and (b) would fail on its own LEAVE dispositions. **That is a coder-ambiguous spec → NOT planner-ready.**

---

## 10. NEW-FORK-1 (P3 launcher) — AFFIRM

The gate-then-probe-then-degrade recommendation is sound: ship UC-1 first; gate the launcher on (a) UC-1 landing + (b) a cwd-scoping probe (does `claude --agent` launched in a worktree keep its git scoped there — the #55708 / Gemini #22658 leak class); degrade to a documented manual procedure if the probe fails. The cwd-scoping risk is correctly characterized as the load-bearing unknown and is correctly NOT settled read-only (it needs a git-mutating probe at P3). The pack-side "no `agent-run.sh` today → net-new" vs project-side "extend existing `agent-run.sh`" split is accurate (CLAUDE.md confirms the pack has no `agent-run.sh`). NEW-FORK-1 is correctly surfaced as a user call at the planner gate and does NOT block UC-1. AFFIRM.

---

## 11. P2 removal + P3 implementation plans — completeness re-check

- **P2 disposition table (§11.1):** I spot-verified the carriers independently — `CONCEPTUAL-REVIEW-METHODOLOGY.md:194` carries "no worktree isolation from non-main clones"; `EXECUTION-PLAN-V11.0.md:417/419` carries the full prohibition reproduction; commit-discipline ×3 carry the `worktree-agent-` HEAD assertion (line 22) + "Must end in worktree path" (line 20). All present as the design claims. The disposition table is correct AS A LIST; its only defect is the gate that checks it (§9).
- **P3 propagation (§12.1):** the `## Pack memory` edits route through the PACK-CHAT §"Rule-change propagation procedure" with the ordered surfaces (corpus ×3 → rationale → references → manifest → cache → manifest regen). This matches the procedure CLAUDE.md references. The trinity-exemption framing for the Claude-only sub-section is preserved (correct — the worktree bullet lives in `### Sub-agent behavior (Claude-only)`, which is already trinity-exempt). AFFIRM the propagation shape.
- **Missed carrier re-grep:** my §9.2 grep surfaced `PLAN-DEPLOYMENT-PYTHON-OBSERVABILITY.md` (design row 13, VERIFY-at-P2 — acknowledged) and `PREWORK-BD-197-…` (in the audit-exclusion but not the gate allowlist). No NEW unlisted prohibition carrier beyond what the design enumerates — the disposition LIST is complete; the GATE is the problem. AFFIRM list-completeness.
- **commit-discipline ×3 redesign (§12.4):** regime-detecting, non-fatal both directions, literal coder branch — independently confirmed the skill TODAY hard-asserts `worktree-agent-` (line 22) which is FALSE for an in-place agent (this agent). The redesign direction is correct + coder-proof. AFFIRM.
- **`agent-run.sh` stale-comment fix (§4.3):** the design notes lines ~92–94 "Edit/Write excluded at agent-definition level" is false for the project side — confirmed against the inventory. Correctly scheduled for P3. AFFIRM.

---

## 12. Remaining gaps / contradictions (consolidated)

| ID | Severity | Finding | §ref |
|---|---|---|---|
| G-1 | **BLOCKER** | P2 gate §11.5 (broad regex incl. `baseRef`/`bgIsolation`) CONTRADICTS Guard-A §13.1 (narrow prohibition signature); the broad gate forbids legitimate post-P3 setting-key tokens — measure-then-bound violation. | §9.1/§9.2 |
| G-2 | **BLOCKER (same fix)** | The "3 BD-197-process files" count is stale (measured 5+); the §11.5 allowlist double-counts + omits the LEAVE-disposition history files (`IMPLEMENTATION-REPORT-BD-196-C9`, `PREWORK-…`, `PLAN-DEPLOYMENT-…`) that still match `baseRef`. | §9.3 |
| G-3 | minor (planner-flag) | Rows 7–9 reachability is PROVISIONAL pending the §3.2 isolate-trigger probe; state the "degrade to rows 1–6 only if no usable trigger" contingency AT the matrix. | §3 |
| G-4 | minor (planner-flag) | Mechanical backstop must be verb-precise: deny `git apply` for agents WITHOUT denying `git diff`; confirm `git diff > file` redirect is not tripped by the matcher; drop the stale `checkout -- <path>` carve-out in pack-coder ×3. | §6 |

G-1 + G-2 are one bounded fix (reconcile the gate to a single prohibition-only, measure-then-bound regex + drop the static count). G-3 + G-4 are planner-carry flags, not re-architecture.

---

## 13. PLANNER-READY verdict

**NO — blocked on G-1 + G-2 only.** Every architectural choice is sound and independently affirmed: the merge-back model (1+2+4), the `bgIsolation` mode-trigger correction + runtime ground-truth contract, the 9-cell matrix, the conflict protocol, the git-permission denylist+principle, the RW/RO triple-reinforcement SSOT, the complete degradation matrix, and the NEW-FORK-1 launcher recommendation. All 9 first-adversarial corrections landed (8 cleanly; #7 landed-but-defective = G-1). The design is ONE bounded fix away from planner-ready: reconcile the self-contradictory, over-broad P2 completeness gate (§11.5 vs §13.1) into a single prohibition-only, measure-then-bound regex with an allowlist sized to the P2-time-measured LEAVE set, and drop the stale "3 process files" count. That fix is a reconciliation-pass edit (one regex + one count + the cross-refs in §10/§11.3/§13.1), not a redesign. After it lands, PLANNER-READY: YES.

---

## 14. Rules-Applied Verification Block

| # | Rule (as named in prompt) | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | Agents never commit (git read-only; probes read-only, /tmp only) | Only read-only git verbs run: `git rev-parse HEAD` (`3e3159e…`), `git rev-parse --abbrev-ref HEAD` (`v11-dev`), `git --version` (`2.50.1`), `git apply --check /dev/null` (parse-only, errored "No valid patches"), `git worktree list` (read), `ls`. No add/commit/push/stash/reset/mv/rm/apply mutation. One /tmp scratch file created+removed; no repo/git mutation. | COMPLIANT |
| 2 | Read-only mandate (write ONLY this report) | Exactly one repo file written: `maintenance-docs/v11-implementation/ARCHITECTURE-BD-197-ADVERSARIAL-REVIEW-2.md` (caller-specified path), via heredoc. All else Read / Bash-grep / python-json-read / ls. No existing file edited. | COMPLIANT |
| 3 | Empirical-Evidence Blocks (incl. re-run probes) | §1 probe table + §1 mode-refutation block + §3 matrix re-derivation + §9.2/§9.3 each carry command + verbatim output + HEAD `3e3159e` + date 2026-06-13 + interpretation + SUPPORTED/NOT-SUPPORTED conclusion. | COMPLIANT |
| 4 | Adversarial rigor; matrix-completeness re-check shown | §0 challenges by default; §3 rebuilds the 9-cell matrix INDEPENDENTLY before comparing; affirmations (§2,§4,§7,§8,§10,§11) each cite independent measurement; the one CHALLENGE (§9) carries a better alternative (§9.4). | COMPLIANT |
| 5 | CI-guard measure-then-bound | §9 applies measure-then-bound to the P2 gate: ran the design's exact regex (40 files), categorized KEEP vs contamination, showed the broad regex admits legitimate content (`baseRef`/`bgIsolation` key names) = the anti-pattern the rule forbids; §9.4 prescribes a prohibition-only signature sized to the measured KEEP set. §7 sizes RW/RO guards to measured 5 / 14+2. | COMPLIANT |
| 6 | Pack/project separation + trinity parity + cross-CLI normalization + PACK-CHAT §12 propagation | §7 confirms pack (Class column) vs project (PM-CHAT + array) are separate native artifact sets; §2/§11 confirm the worktree bullet is in the trinity-exempt `### Sub-agent behavior (Claude-only)` sub-section; §11 confirms §12.1 routes `## Pack memory` edits through the PACK-CHAT §-propagation ordered surfaces; Gemini-no-`tools:` handled per surface. | COMPLIANT |
| 7 | Architect-doc-vs-reality reconciliation | §2 reconciles each claimed first-adversarial correction against the reconciled doc's content; §9 reconciles the design's gate/count claims against the LIVE tree measurement; §13 names exactly what must change before the planner consumes the doc. | COMPLIANT |
| 8 | Unbiased re: sealed discussion | The sealed pre-design discussion was neither sought nor referenced; all conclusions derive from BD-197 (D1–D6 + notes 6–9), the research docs, the reconciled + first-adversarial docs, CLAUDE.md, and my own read-only probes. | COMPLIANT |
| 9 | Rules-Applied Verification Block present | This table; every row carries quoted/measured evidence. | COMPLIANT |
| 10 | PREFLIGHT + STOP-MEANS-STOP | PREFLIGHT line emitted in chat immediately before this Write ("PREFLIGHT: 2nd adversarial review complete; matrix re-built; probes re-run; about to Write …"). No parent stop received. | COMPLIANT |

---
*End of ARCHITECTURE-BD-197-ADVERSARIAL-REVIEW-2.md*
