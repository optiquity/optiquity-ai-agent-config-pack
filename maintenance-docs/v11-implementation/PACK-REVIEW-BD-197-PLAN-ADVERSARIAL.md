# PACK-REVIEW — BD-197 worktree-isolation EXECUTION PLAN (adversarial)

**Role:** pack-reviewer (fresh, adversarial). **Mode:** read-only on the codebase; one report written (this file).
**Repo:** optiquity-ai-agent-config-pack-v11-dev · **Branch:** v11-dev · **HEAD at review:** `ae3d9325889c41f7cba7a4289437cf7a87d04292` (`ae3d932`).
**Date:** 2026-06-13.
**Artifact under review:** `maintenance-docs/v11-implementation/PLAN-BD-197-WORKTREE-ISOLATION.md` (371 lines).
**Authority the plan must execute faithfully:** `ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` (572 lines).

## Read-in-full + no-derivation attestation

I read each NAMED authoritative input DIRECTLY and IN FULL (no skim, no summary, no crop): the PLAN under review (371 lines, both pages); the RECONCILED architecture (572 lines, both pages); `backlog/BD-197.md` (all notes 1–10, D1–D6); `CLAUDE.md ## Pack memory` (full, via project-instructions context); and each curated memory file — `feedback_pack_project_separation_of_concerns.md`, `feedback_bd_pack_only_operational_rule.md`, `feedback_client_ref_delete_or_forward_look.md`, `feedback_verify_full_ci_suite.md`, `feedback_ci_guard_design_measure_then_bound.md`, `feedback_ci_check_runtime_compounding.md`, `feedback_commit_subject_keyword_token_trap.md`, `feedback_manifest_regen_on_v11_surface.md`, `project_bd197_user_design_direction.md`. I did NOT read any prior `PACK-REVIEW-*` for this plan (none exists). Every measurement-based finding below was re-run by me against live HEAD `ae3d932` (commands + verbatim output quoted), not derived from the plan's §F. Marking a rule COMPLIANT without reading its doc would be a mislabel; I do not do so.

---

## VERDICT

**APPROVE-WITH-FIXES** — the plan faithfully executes the locked design, the commit sequence is green-per-commit on the load-bearing guard-ordering, and pack/project isolation is clean per commit; but one BLOCKER (Guard-A self-match: the validator source + its own check-53 test + the BD-197 docs all contain the prohibition-matcher regex literal and WILL self-match, yet the plan's §E allowlist scopes only `!.git !test-fixtures` and never categorizes `scripts/`) must be fixed before C5, plus a measurement DELTA and several MUSTs.

---

## Findings

### BLOCKER

**B-1 — Guard-A (Check 53) self-match: the matcher regex literal lives in the validator, its test, and every BD-197 doc; §E's allowlist scope (`!.git !test-fixtures`) leaves `scripts/` in-scope where the regex WILL self-match.**
- **Location:** PLAN §E "Guard A — Check 53" step 1 (line 175) + §F EE-2 (lines 211–216); design §13.1 / §11.5 gate (a).
- **What is wrong:** The plan's prohibition matcher is `'no worktree isolation|Do not pass .*isolation.*worktree'`, scoped `rg -l --hidden --no-ignore … -g '!.git' -g '!test-fixtures'`. `scripts/` is IN scope. Once C5 lands Guard-A, `scripts/validate-pack.py` will contain the regex literal as source, and the new `scripts/tests/test-validate-pack-check-53.sh` will contain it to exercise the check. Both will SELF-MATCH the matcher. The plan's measure-then-bound recipe (§E step 2) categorizes only "history IMPL-REPORT + BD-197-process artifacts + archive" as KEEP — it NEVER mentions `scripts/validate-pack.py` or the check-53 test. Furthermore the matcher hits files because they QUOTE THE REGEX, not because they reproduce prohibition PROSE — verified live: PLAN lines 89/175/212 match purely on the quoted pattern strings.
- **Evidence (live, HEAD `ae3d932`):**
  ```
  $ rg -n 'no worktree isolation|Do not pass .*isolation.*worktree' \
      maintenance-docs/v11-implementation/PLAN-BD-197-WORKTREE-ISOLATION.md
  40:- `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` — UPDATE the "no worktree isolation …"
  89:- `scripts/validate-pack.py` — NEW **Guard A** … PROHIBITION-ONLY signature
        (`no worktree isolation`, `Do not pass .*isolation.*worktree`) …
  175:1. Measure: `rg -l … 'no worktree isolation|Do not pass .*isolation.*worktree' …`
  212:- Command: `rg -l … 'no worktree isolation|Do not pass .*isolation.*worktree' …`
  ```
  Lines 89/175/212 match on the QUOTED regex, not prohibition prose.
  Precedent that this codebase already special-cases the validator's own file:
  ```
  $ grep -n '__file__\|validate-pack.py' scripts/validate-pack.py | head
  2169:        if entry.name == "validate-pack.py":
  ```
  Closest precedent (Check 51 flip-block) carries an EXPLICIT allowlist + `^`-anchoring + a runtime-compounding note for exactly this self-reference class:
  ```
  $ grep -n 'allowlist' scripts/validate-pack.py | sed -n '1,3p'
  #  allowlist {scripts/lib/recommendation.sh, scripts/tests/, …}
  #  the one BD-204:24 mid-line prose hit is excluded by the `^` anchor …
  ```
- **Why it is a BLOCKER:** This is precisely the `ci-guard-measure-then-bound` failure the rule forbids — a guard authored against an unmeasured projected-post-fix tree. C5 ships Guard-A; if its own source + test self-match and are not allowlisted, **C5 goes RED at its own boundary** (the guard fires on the validator that defines it), breaking green-per-commit. The plan's §K bullet only anticipates "the PLAN doc + BD-197-process docs will match" — it does NOT anticipate the VALIDATOR + its TEST self-matching, which is the harder, non-doc case.
- **Concrete fix:** Amend §E Guard-A step 2 to categorize `scripts/validate-pack.py` AND `scripts/tests/test-validate-pack-check-53.sh` as KEEP (or exclude `scripts/` from the matcher scope and anchor the pattern, per the Check-51 precedent: line-anchor or restrict the matcher to the doc/active-prose surfaces it actually polices). Mandate the C5 coder follow the Check-51 self-exclusion pattern (`entry.name == "validate-pack.py"` skip + `scripts/tests/` allowlist) verbatim. Add a PREFLIGHT assertion that the matcher returns clean INCLUDING the just-authored validator + test. This is a real defect, not a judgment call.

### MUST

**M-1 — EE-2 measurement DELTA: plan claims 19 files; live tree is 20 (the untracked PLAN doc itself).**
- **Location:** PLAN §F EE-2 (line 213, "Output (19 files)").
- **What is wrong:** The plan states the prohibition matcher returns 19 files. Live, it returns 20 — the extra is `maintenance-docs/v11-implementation/PLAN-BD-197-WORKTREE-ISOLATION.md`, which is **untracked** at HEAD `ae3d932` (the plan was being authored when EE-2 ran, so it excluded itself).
- **Evidence (live):**
  ```
  $ rg -l … 'no worktree isolation|Do not pass .*isolation.*worktree' … | wc -l
  20
  $ git status --short maintenance-docs/v11-implementation/PLAN-BD-197-WORKTREE-ISOLATION.md
  ?? maintenance-docs/v11-implementation/PLAN-BD-197-WORKTREE-ISOLATION.md
  $ rg -c 'no worktree isolation|Do not pass .*isolation.*worktree' \
      maintenance-docs/v11-implementation/PLAN-BD-197-WORKTREE-ISOLATION.md
  4
  ```
- **Why it matters:** The EE block is the plan's empirical-evidence anchor; an undercount (even of its own artifact) means the C5 allowlist sized off EE-2 is short by one. §K mitigates the CONSEQUENCE (re-measure mandate), but the EE block's stated count is factually wrong at the plan's own HEAD.
- **Concrete fix:** Correct EE-2 to "20 files (19 committed + the untracked PLAN doc, which matches 4× on the quoted matcher regex)"; confirm the C5 coder allowlists the PLAN doc + the RECONCILED/2nd-adversarial/RESEARCH-P1/RESEARCH-AGENT-PERMISSION/first-design carriers (the measured KEEP set) — verified live below (re-measurement table). Note this is judgment-adjacent (the re-measure mandate already covers it operationally) but the EE block must be factually right.

**M-2 — Guard-A KEEP allowlist enumeration is correct but the plan does not pin WHICH BD-197 docs match vs do not; risk of over-allowlisting BD-197.md / 1st-adversarial.**
- **Location:** PLAN §F EE-2 line 215 ("KEEP allowlist: IMPLEMENTATION-REPORT-BD-196-C9 … + the 5 BD-197-process prohibition-prose carriers …").
- **What is wrong:** The plan correctly states `BD-197.md` and the 1st adversarial do NOT match — but C1's §B bullet and §11 fresh-audit could lead a coder to reflexively allowlist all BD-197-process files. I verified the exact match-set so the coder allowlists ONLY the carriers.
- **Evidence (live, per-file `rg -c`):**
  ```
  backlog/BD-197.md: 0
  ARCHITECTURE-BD-197-WORKTREE-ISOLATION.md: 3        (KEEP)
  ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md: 6  (KEEP)
  ARCHITECTURE-BD-197-ADVERSARIAL-REVIEW.md: 0        (NOT in allowlist)
  ARCHITECTURE-BD-197-ADVERSARIAL-REVIEW-2.md: 6      (KEEP)
  RESEARCH-BD-197-P1-WORKTREE-ISOLATION.md: 5         (KEEP)
  RESEARCH-BD-197-AGENT-PERMISSION-INVENTORY.md: 1    (KEEP)
  PLAN-BD-197-WORKTREE-ISOLATION.md: 4                (KEEP — once committed)
  ```
  This matches design §11.5 exactly (5 carriers) PLUS the PLAN doc (the 6th, new at this HEAD) PLUS the history IMPL-REPORT-BD-196-C9. `BD-197.md` and 1st-adversarial = 0 → correctly excluded.
- **Concrete fix:** Add this per-file match-count to the C5 coder prompt (or §E) so the allowlist is sized to the carriers ONLY (no broader — `ci-guard-measure-then-bound`). Plus the B-1 additions (validator + test). This finding plus B-1 together fully bound Guard-A's allowlist.

**M-3 — `verify-full-ci-suite`: §D enumerates the battery but does NOT state the NEW per-check tests (52/53/54/55) are added to the SAME commit as their check AND run in that commit's PREFLIGHT; §H states it once but §D's per-commit emphasis omits it for C3/C5/C6.**
- **Location:** PLAN §D (lines 160–164) + §H footer (line 304).
- **What is wrong:** §H correctly says "NEW per-check tests MUST be added to the yml in the SAME commit as the check." But §D's "per-commit emphasis" lists the NEW tests as "MOST likely to catch" without restating that the coder's PREFLIGHT for C3/C5/C6 must RUN the just-authored test (a brand-new test file is not in the prior battery, so a coder enumerating "the wired set" could miss running its own new test before it is wired). The `verify-full-ci-suite` rule's sharpened form ("run EVERY script wired in the yml") has a gap for a test that is being wired in the same commit.
- **Evidence:** §D line 158 ends "PLUS the NEW per-check tests this BD adds (Check 52/53/54/55)" — good — but the per-commit emphasis block (160–164) and the §I coder prompts do not explicitly require running the new test in-commit before wiring. I confirmed the full wired set (54 distinct scripts) matches §D's enumeration; the gap is only the in-commit-new-test ordering.
- **Concrete fix:** In §D and each affected §I coder row (C3/C5/C6), add: "author the new per-check test, RUN it locally (quoting exit 0), wire it into `validate-pack.yml` `tests` job, then re-run the full battery — all in the same commit." Closes the enumerate-encoding-surfaces + verify-full-ci-suite seam.

**M-4 — C2 manifest "defensive run" reasoning is correct, but the plan should state the trinity `agents-never-commit` C4 edit could touch pack-root CLAUDE/AGENTS/GEMINI only (exempt) WHILE pack-ops/ is also touched — verify the manifest fires on the pack-ops/ leg, not the trinity leg.**
- **Location:** PLAN §G (line 285, C2) + §B C4 note (line 85).
- **What is wrong:** §G C2 says "RUN build to confirm; stage ONLY if diff non-empty (expected empty)." This is CORRECT (C2 touches only pack-root trinity [exempt] + `.claude/.codex/.gemini/` skills+agents [not v11-surface]). I verified the four v11-surface prefixes are `project-template/, scripts/, pack-ops/, supporting-docs/` and the dotdirs are none of these. The reasoning holds. The MUST is minor: C4 §B line 85 correctly notes pack-root trinity is manifest-exempt but pack-ops/ fires anyway — accurate. No defect; flagging for the coder to NOT skip the manifest on C4 by mis-reasoning "it's only trinity."
- **Evidence (live):** `manifest-regen` memory + trinity RC9: v11-surface = `{project-template/, scripts/, pack-ops/, supporting-docs/}`; pack-root trinity base-case exempt. C2 diff (CLAUDE.md + dotdirs) ⇒ no v11-surface ⇒ defensive run, stage if non-empty. Correct.
- **Concrete fix:** None required (reasoning is sound) — downgrade to confirmation. Keep §G as written; ensure the C4 coder regenerates because pack-ops/ is touched.

### SHOULD

**S-1 — EE-8 "exact-string excision" of the `checkout -- <path>` carve-out under-specifies the Codex variant, whose surrounding prose differs from `.claude`/`.gemini`.**
- **Location:** PLAN §F EE-8 (lines 253–258) + §B C4 (line 80).
- **What is wrong:** The plan directs "Excise the exact carve-out string" at 3 sites. But the carve-out is embedded differently per CLI: `.claude`/`.gemini` carry the literal `git checkout (except \`git checkout -- <path>\` to inspect …`; `.codex/agents/pack-coder.toml:21` embeds it mid-sentence in a longer prose block. An "exact-string" excision keyed to the `.claude` phrasing will not match Codex.
- **Evidence (live):**
  ```
  .claude/agents/pack-coder.md:37: `git stash`, `git checkout` (except `git checkout -- <path>` to inspect
  .gemini/agents/pack-coder.md:39: `git stash`, `git checkout` (except `git checkout -- <path>` to inspect
  .codex/agents/pack-coder.toml:21: … You MAY NOT run git add, git commit, … git checkout
       (except `git checkout -- <path>` to inspect file contents at a different ref). …
  ```
- **Concrete fix:** Reframe C4's EE-8 directive as "remove the carve-out per-CLI, audience-correct (cross-cli-reference-normalization) — the Codex `.toml` prose differs from the `.claude`/`.gemini` `.md` phrasing; excise the carve-out clause in each without assuming a byte-identical string." The plan already invokes cross-cli-normalization in §I C4; make EE-8 consistent with it.

**S-2 — Guard-A runtime-compounding budget: §E references "186×" but does not require the per-check runtime guard be benched against the precedent (Check 51 notes ~151; the matcher is a single whole-tree `rg`, cheap — but the budget number should be the one the coder asserts).**
- **Location:** PLAN §E intro (line 172) + Guard-A "Runtime" (line 180).
- **What is wrong:** The plan correctly identifies the single-`rg` design (cheap) and the 186 battery count (I confirmed: `tests/` sum = 186). The SHOULD is that §E should require the C5 coder to emit the measured per-check wall-time in the IMPL-REPORT against an explicit budget (the `ci-check-runtime-compounding` rule's durable-prevention clause — "time each check; FAIL/WARN on budget overrun"), not just assert "trivial."
- **Evidence (live):** `grep -rcE 'validate-pack\.py' scripts/tests/*.sh | sum = 186`. A single `rg -l` over the active tree is O(tree) once per invocation — safe at 186×, but unmeasured.
- **Concrete fix:** Add to §E: "C5 coder records each new check's wall-time in the IMPL-REPORT; Guard-A/A′/B/C each under a stated budget; a single whole-tree `rg`, no subprocess-per-entry (confirmed by design)." Mirrors Check-51's runtime note.

**S-3 — §J item 4 (backstop placement / dependency-direction) is correctly raised but the plan should pin that a NEW pack-side hook SCRIPT, if needed, is BLOCKED on architect+user sign-off BEFORE C4 codes — not resolved at "C4 architect-check" by the coder.**
- **Location:** PLAN §J item 4 (line 330) + §B C4 (line 82) + §I C4 row (line 317).
- **What is wrong:** §J item 4 correctly flags the Check-47 frozen allowlist `{detect.sh, pack-help.sh}` and architect+user sign-off. But §B C4 line 82 says "the coder identifies the exact pack-side config file at commit-time; if it requires a NEW pack-side script, see §I dependency-direction flag" — this risks a coder authoring a new pack-side script inline. The dependency-direction rule requires the placement decision to PRECEDE coding.
- **Evidence:** trinity `dependency-direction-placement`: growing `_SANCTIONED_PACK_SIDE_SHIPPED` requires architect+user sign-off; Check 47 enforces install-map↔constant set-equality. A net-new pack-side hook script that also ships would trip Check 47 if not on the frozen allowlist.
- **Concrete fix:** Strengthen §J item 4 + §I C4 to a hard GATE: "If C4's backstop needs a NEW pack-side file (vs editing existing config), STOP — Pack Chat escalates to architect+user BEFORE the C4 coder writes it; the coder may NOT author a new pack-side script on its own authority." This is consistent with `per-action-approval-sub-agents`.

### NIT

**N-1 — §A C7 subject contains the token `--disallowedTools` and prose "validate-pack is pack-side" — confirm no scope-keyword TOKEN leaks into C6/C7 neutral subjects.**
- **Location:** PLAN §A rows C6/C7 (lines 24–25, 29).
- **What is wrong:** The plan recommends NEUTRAL framing (no keyword) for C6/C7 — correct (verified Check 36 below). The example subject in line 29 includes "(cross-surface: project-template + validator)". I confirm this contains NO scope-keyword token (`pack-only`/`project-only`/`pack-chat-only`), so Check 36 SKIPS — safe. Flagging only so the C6/C7 coder/Pack-Chat keeps the literal tokens out of the eventual subject (the `commit-subject-keyword-token-trap` recurs on prose).
- **Evidence (live Check 36 logic, validate-pack.py:4301):** `if not (is_pack_only or is_project_only or is_pack_chat_only): skipped` — neutral framing ⇒ skipped ⇒ no false denial. Confirmed `_is_project_side_path` = startswith `("project-template/", "supporting-docs/")`; `scripts/` is NOT project-side, so a `project-only` C6/C7 WOULD fail — the plan's neutral-framing decision is correct.
- **Concrete fix:** None; keep neutral framing. Ensure the final subjects carry zero keyword tokens.

**N-2 — §C green-per-commit prose says "C5 ships Guard-A … green because C2 already removed the prohibition" — true for the PROSE carriers, but B-1's self-match is the uncovered case; reconcile §C with the B-1 fix.**
- **Location:** PLAN §C (lines 140, 145).
- **Concrete fix:** After fixing B-1, update §C's C5 bullet to state Guard-A is green because (a) C2 removed the prohibition prose AND (b) the allowlist includes the validator source + check-53 test + the measured BD-197 carriers.

---

## Re-measurement table (my live measurement vs the plan's §F)

| Claim | Plan §F | My live (HEAD `ae3d932`) | DELTA |
|---|---|---|---|
| HEAD | `ae3d932` | `ae3d932` | none |
| Branch | `v11-dev` | `v11-dev` | none |
| EE-1 battery validate-pack invocations | 186 | `grep -rcE 'validate-pack\.py' scripts/tests/*.sh` sum = **186** | none (design's ~155 stale; plan correct) |
| EE-2 prohibition-only matcher files | **19** (9 archive + 10 active) | **20** (9 archive + 11 active; +PLAN doc, untracked) | **+1 — see M-1** |
| EE-2 KEEP carriers (BD-197-process) | 5 | 5 committed (+PLAN doc = 6 once committed); BD-197.md & 1st-adversarial = 0 (correctly excluded) | confirmed — see M-2 |
| EE-3 dangling-ref active non-process | 3 (SURVEY, MAINTAINABILITY, 19C-G) | 3 — identical set | none |
| EE-4 OPTIONAL-FEATURES `bgIsolation\|baseRef` baseline | 0/0 (exit 1) | exit 1, no matches (both files exist) | none |
| EE-5 pack agents | 5 (1 RW + 4 RO) | 5 ×3 CLIs; pack-coder = Source-write, 4 Read-only | none |
| EE-5 project agents / READONLY_AGENTS | 16 / 14 | 16 `.md`; `READONLY_AGENTS` = exactly 14 entries | none |
| EE-6 highest Check number | 51 | `grep -oE 'Check [0-9]+'` max = **51** | none |
| EE-6 validate-pack green | exit 0 PASSED | `python3 scripts/validate-pack.py` → exit 0, "PASSED — all checks clean" | none |
| EE-7 root AGENTS/GEMINI worktree refs | 0/0 | AGENTS.md 0, GEMINI.md 0 | none |
| EE-7 project trinity worktree refs | 0/0/0 | project CLAUDE/AGENTS/GEMINI all 0 | none |
| EE-7 prohibition location | CLAUDE.md:325; `### Sub-agent behavior (Claude-only)` only in CLAUDE.md:323 | line 325 / heading line 323, CLAUDE.md only | none |
| EE-8 checkout carve-out sites | `.claude:37`, `.codex:21`, `.gemini:39` | all 3 present at those lines | none (but Codex prose differs — see S-1) |
| EE-9 manifest clean | empty | `git status --short test-fixtures/manifest.txt` empty | none |
| agent-run.sh stale comment | ~92–94 "Edit/Write excluded at agent-definition level" | line 94, exact text present (FALSE per BD-127) | none |
| agent-run.sh --disallowedTools | only `git commit`/`push` (line 98 + dispatch ~155) | line 98 + line 155, only commit/push | none |
| shipped settings.json `git add` allow | allowed, no worktree key | `project-template/.claude/settings.json:16 "Bash(git add *)"`, no worktree key | none |

**The one material DELTA is EE-2 (19→20), driven by the untracked PLAN doc — which also surfaces the B-1 self-match class (the matcher hits files that QUOTE the regex, including the validator + test C5 will author).**

---

## Three-axis assessment

### Axis 1 — Plan solidity / green-per-commit: **PASS with one BLOCKER (B-1) to fix before C5.**
- Commit ordering (C1→C8, pack-side C3–C5 before client-side C6–C8) is sound and matches the design's phase order. Verified.
- (a) Guard-A′ "ship in C8" resolution: **CORRECT.** Shipping it in C5 asserting both surfaces would red C5→C7 (project keys absent until C8 — EE-4 baseline 0/0 confirmed). C8 is the commit that satisfies it. Green-per-commit holds.
- (b) C6/C7 mixed-surface Check-36 framing: **CORRECT.** Verified Check 36 logic (validate-pack.py:4322 — `project-only` fails on any non-project-side path; `_PROJECT_SIDE_PATH_PREFIXES = ("project-template/", "supporting-docs/")`; `scripts/` is not project-side). A guard that co-lands with `scripts/validate-pack.py` cannot be `project-only`; neutral framing (no keyword → Check 36 skips) is the clean, correct path. The plan's option (i) reasoning is right.
- (c) C2 trinity Claude-only-exemption: **CORRECT.** Verified prohibition lives ONLY in CLAUDE.md:325 under `### Sub-agent behavior (Claude-only)` (CLAUDE.md:323); root AGENTS/GEMINI = 0, project trinity = 0. The C2 directive "do NOT propagate to root AGENTS/GEMINI" preserves the exemption.
- (d) Allowlist DRIFT once the plan's own docs commit: **THIS IS B-1.** The plan handles the DOC drift (§K re-measure) but NOT the validator-source + check-53-test self-match. BLOCKER.
- (e) Gaps / unowned surfaces: §H + §I cover the changed surfaces with validators + tests in lockstep; §D enumerates the full wired battery (I confirmed 54 distinct scripts match §D). M-3 closes the one seam (in-commit new-test run-before-wire ordering).

### Axis 2 — Pack/project isolation: **PASS.**
- P2 (C1/C2) is pack-only — verified EE-7 (zero prohibition on any client surface), so P3 client work is purely additive. The §11 prohibition-removal is correctly pack-side ONLY; the client carries no prohibition to remove.
- C3–C5 (pack) and C6–C8 (client) are split cleanly by surface. C6/C7's `scripts/validate-pack.py` leg is pack-side and is handled via neutral framing (not smuggled into a project-only claim).
- §B/§I require the client artifacts (PM-CHAT merge-back, project OPTIONAL-FEATURES, project agent files) to be authored client-NATIVE ("PM Chat" orchestrator, client paths, "NOT a byte-copy of PACK-CHAT.md", "ZERO pack-self refs"). This satisfies `pack-project-separation-of-concerns`, `bd-pack-only-operational-rule`, and `client-ref-delete-or-forward-look`. No commit smuggles BD-NNN / maintenance-docs/ / pack-* / Pack Chat into `project-template/`.
- The shipped `settings.json` reconciliation (no `worktree` key added; `git add` allow left for the human; agent ban via Hard rule + `agent-run.sh --disallowedTools`) is faithful to design §7 — verified the file allows `git add` and has no worktree key.

### Axis 3 — Rule capture both sides + no cross-contamination: **PASS.**
- `agents-never-commit` + full destructive-git-verb ban RETAINED for ALL agents incl. RW on both surfaces: §I states all agents READ-ONLY git; RW merge-back = `/tmp` patch → orchestrator applies. Faithful to design §4.1 + §5 + D5. The git-permission denylist (§5.1) propagates to both surfaces (pack: trinity ×3 + PACK-MEMORY-RATIONALE + commit-discipline ×3 + pack-coder ×3 + PreToolUse hook; project: trinity ×3 + 48 agent files + `agent-run.sh --disallowedTools`).
- RW/RO two-class model present on both surfaces with the right per-surface mechanism: pack = PACK-AGENTS `Class` column + Guard-B(pack) Check 52 (verified roster has Mode col at line 13, 5 rows); project = PM-CHAT profiles + `agent-run.sh READONLY_AGENTS` projection + Guard-B(project) Check 55 (verified READONLY_AGENTS = 14). Both bind the parity check to the PROSE header, never `tools:` (correct — `pack-reviewer` carries Write,Edit yet is RO).
- Merge-back preserves agents-never-commit on both (orchestrator-applies-patch; no committing agent class). Faithful.
- Cross-CLI normalization (NOT byte-copy) for trinity edits: §I C4/C7 invoke cross-cli-normalization and flag the GEMINI approval-mode line preservation. S-1 sharpens the Codex carve-out excision.
- Claude-only-first scope: Codex/Gemini correctly DEFERRED to BD-217 (§K), not pulled in, not blocking; the C2 exemption is preserved (not propagated to root AGENTS/GEMINI). Faithful to BD-197 note 1.

---

## Rules-Applied Verification Block

| # | Rule (as named in prompt) | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | pack-project-separation-of-concerns | §B/§I require client artifacts authored client-native ("NOT a byte-copy of PACK-CHAT.md", PM-Chat orchestrator, client paths); P2 pack-only (EE-7 client surfaces = 0); no commit treats a pack artifact as a client fallback. Verified `_PROJECT_SIDE_PATH_PREFIXES = ("project-template/","supporting-docs/")`. | COMPLIANT |
| 2 | bd-pack-only-operational-rule | §I C6/C7/C8 prompts require "ZERO pack-self refs in project-template/"; no client commit introduces BD-NNN/maintenance-docs/pack-*/Pack-Chat/pack-ops. | COMPLIANT |
| 3 | client-ref-delete-or-forward-look | Client OPTIONAL-FEATURES + PM-CHAT authored client-native (no pack-repo paths); §I C6 enumerates the rule. No client-shipped pack-path reference introduced. | COMPLIANT |
| 4 | verify-full-ci-suite | §D enumerates the full wired battery; I confirmed the 54 distinct scripts in `.github/workflows/validate-pack.yml` match §D. Gap (in-commit new-test run-before-wire) flagged M-3; not a violation of the plan's enumeration, a sharpening. | COMPLIANT (M-3 sharpens) |
| 5 | ci-guard-design-measure-then-bound | §E gives the 5-step recipe; BUT Guard-A allowlist omits the validator-source + check-53-test self-match (the matcher hits files QUOTING the regex — verified PLAN lines 89/175/212). That is an unmeasured KEEP-set member ⇒ the guard would fire on its own source. | VIOLATED — B-1 (allowlist not sized to the full measured KEEP set; `scripts/` left in matcher scope unanalyzed) |
| 6 | ci-check-runtime-compounding | §E sizes the budget to 186× (I confirmed `tests/` sum = 186), single whole-tree `rg`, no subprocess-per-entry. S-2 asks for an explicit measured wall-time in the IMPL-REPORT (durable-prevention clause) — sharpening, not a violation. | COMPLIANT (S-2 sharpens) |
| 7 | commit-subject-keyword-token-trap | §A C1–C5/C8 carry exactly one claimed keyword; C6/C7 use neutral framing (no token) — verified Check 36 skips no-keyword commits (validate-pack.py:4301). Example subjects carry no stray token. | COMPLIANT |
| 8 | enumerate-encoding-surfaces | §H tabulates each surface + validator(s) + test(s) + CI ref + cross-ref docs in lockstep; new per-check tests wired in the same commit as the check. M-3 closes the in-commit ordering seam. | COMPLIANT |
| 9 | regenerate-manifest-v11-surface | §G flags every commit; v11-surface = `{project-template/,scripts/,pack-ops/,supporting-docs/}` confirmed; C2 defensive-run-stage-if-nonempty reasoning correct (M-4 confirms, no defect). | COMPLIANT |
| 10 | agents-never-commit + full destructive-git-verb ban (ALL agents incl RW) | §I: all agents READ-ONLY git; RW merge-back = /tmp patch → orchestrator applies; denylist (§5.1) propagated both surfaces; merge-back model (design 1+2+4) preserves the ban. No task has any agent run a state-changing git verb. | COMPLIANT |
| 11 | cross-cli-reference-normalization | §I C4/C7 invoke normalization; GEMINI approval-mode line preservation flagged. S-1 sharpens the Codex `.toml` carve-out (differing prose) — the plan's "exact-string" framing under-specifies Codex. | COMPLIANT (S-1 sharpens) |
| 12 | dependency-direction-placement | §J item 4 + §I C4 raise the Check-47 frozen allowlist `{detect.sh,pack-help.sh}` + architect+user sign-off for a NEW pack-side hook script — correctly NOT silently resolved. S-3 hardens it to a pre-coding GATE. | COMPLIANT (S-3 hardens) |
| 13 | scope-deliverables-to-the-ask | The plan leads with the commit sequence (§A), is an execution artifact, fences out-of-scope items in §K, no design restatement/sprawl. | COMPLIANT |
| 14 | rules-applied-verification-block | This block addresses every rule with quoted/measured evidence; no empty cell; no AMBIGUOUS. | COMPLIANT |

**Reviewer git-state attestation:** I ran ONLY read-only git/CLI verbs (`git rev-parse`, `git status --short`, `grep`, `rg`, `sed`, `awk`, `ls`, `python3 scripts/validate-pack.py` [read-only validator]). No `add/commit/push/stash/reset/restore/checkout/mv/rm/apply` issued. Exactly ONE file written: this report at the prompted path.

---
*End of PACK-REVIEW-BD-197-PLAN-ADVERSARIAL.md*
