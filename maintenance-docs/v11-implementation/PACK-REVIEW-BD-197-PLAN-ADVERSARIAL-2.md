# PACK-REVIEW-BD-197-PLAN-ADVERSARIAL-2 — adversarial review of the UPDATED execution plan

**Role:** pack-reviewer (fresh, adversarial). **Mode:** read-only on the codebase; one report written (this file).
**Repo:** optiquity-ai-agent-config-pack-v11-dev · **Branch:** v11-dev · **HEAD at review:** `ae3d9325889c41f7cba7a4289437cf7a87d04292` (`ae3d932`).
**Date:** 2026-06-13.
**Artifact under review:** `maintenance-docs/v11-implementation/PLAN-BD-197-WORKTREE-ISOLATION.md` (UPDATE PASS, 11-commit split).
**Design authority:** `ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` (incl. Correction pass 2026-06-14).

## Read-in-full + no-derivation attestation

I read each NAMED authoritative input DIRECTLY and IN FULL (no skim, no summary, no crop, no derivation):
- `PLAN-BD-197-WORKTREE-ISOLATION.md` (424 lines, both pages — §A–§K + the two Rules-Applied blocks).
- `ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` (617 lines, both pages — Correction pass 2026-06-14 + §0/§1/§3/§5/§6/§7/§8/§9/§11/§13/§14/§15/§16).
- `backlog/BD-197.md` (all notes 1–11, incl. Note 11 PROBE+SCHEMA CORRECTION) + `backlog/BD-218.md` (full).
- `CLAUDE.md ## Pack memory` (full, via the project-instructions context).
- Curated memory, each in full: `feedback_pack_project_separation_of_concerns.md`, `feedback_bd_pack_only_operational_rule.md`, `feedback_client_ref_delete_or_forward_look.md`, `feedback_verify_full_ci_suite.md`, `feedback_ci_guard_design_measure_then_bound.md`, `feedback_ci_check_runtime_compounding.md`, `feedback_commit_subject_keyword_token_trap.md`, `feedback_manifest_regen_on_v11_surface.md`, `project_bd197_user_design_direction.md` (PROBE FINDINGS + decision ledger).

I did NOT read any prior `PACK-REVIEW-*` for this plan (the 1st adversarial plan review) — reviewed FRESH against the design + rules to avoid bias. I re-measured every load-bearing §F claim live against HEAD `ae3d932` (table below); I do not trust the plan's stated numbers.

---

## VERDICT

**APPROVE-WITH-FIXES.** The mode-model correction fully and faithfully landed and the §F numbers reproduce exactly — but the 11-commit split is NOT green-per-commit as claimed: the three `project-only` DATA commits (C6a/C7a/C8a) must each stage `test-fixtures/manifest.txt` (a pack-only path that genuinely changes when `project-template/` is edited), which makes the `project-only` Check-36 keyword FAIL on those very commits — a self-contradiction the plan asserts as "clean Check-36" without reconciling.

---

## Findings by severity

### BLOCKER

**B-1 — C6a/C7a/C8a cannot be `project-only` AND stage the regenerated manifest; the split is not green-per-commit as claimed.**
- **Location:** §A commit table rows C6a/C7a/C8a (lines 25/27/29, keyword `project-only`); §B per-commit footers (lines 106/123/134: "`project-only` (clean Check-36) … manifest regen required"); §G rows C6a/C7a/C8a (lines 307/309/311: "YES (`project-template/`) | YES"); §I rows (lines 352/354/356: "single-surface: `project-template/` ONLY → `project-only` clean" + "regenerate-manifest"); Rules-Applied row 9 (line 410) claims COMPLIANT.
- **What's wrong:** Each of C6a/C7a/C8a edits `project-template/` files (agent files, `PM-CHAT.md`, `OPTIONAL-FEATURES.md`, `agent-run.sh`) that PROJECT INTO the v11 test fixtures (`v11-realistic-ot`, `v11-flat-file`, `v11-tracker-on`). Editing them changes fixture content → changes the fixture git-commit SHA → changes a `test-fixtures/manifest.txt` row → the manifest diff is non-empty → the manifest-regen rule REQUIRES staging `test-fixtures/manifest.txt` in the SAME commit. But `test-fixtures/manifest.txt` is NOT under `project-template/`/`supporting-docs/`, so Check 36's `project-only` offender test (`offenders = [p for p in paths if not _is_project_side_path(p)]`) flags it and FAILS the commit. The plan asserts "clean Check-36" for these commits while ALSO mandating the manifest stage — the two are mutually exclusive. This is exactly the trap the `commit-subject-keyword-token-trap` memory names ("a `project-only` commit that stages `test-fixtures/manifest.txt` can't be `project-only` — that file is outside project-side prefixes; use no-keyword"). The plan's whole green-per-commit + keyword-exclusive claim (§C lines 166/170, §J1) rests on these halves being clean; they are not.
- **Evidence (live, HEAD `ae3d932`):**
  - Check 36 logic confirms `project-only` denies any non-project-side path:
    `scripts/validate-pack.py:4126` → `_PROJECT_SIDE_PATH_PREFIXES = ("project-template/", "supporting-docs/")`; `:4322-4331` → `if is_project_only: offenders = [p for p in paths if not _is_project_side_path(p)]`; fails if non-empty. `_commit_paths` (`:4194`) returns ALL `git show --name-only` paths including a staged manifest.
  - Manifest tracks fixture SHAs that drift on project-template edits: `test-fixtures/manifest.txt` lines 5-10 are `<fixture> <sha>`; `test-fixtures/build.sh:905-906` (authoritative): *"v11-* row SHAs drift naturally with any pack-product change to v11 surface (template files, scripts, skills, agents, etc.)"*.
  - The edited files ARE committed in the fixture (so editing them changes the SHA):
    `git -C test-fixtures/v11-flat-file ls-files | grep -E 'agents/|PM-CHAT|OPTIONAL-FEATURES|agent-run'` → `.claude/agents/coder.md`, `docs/pack/PM-CHAT.md`, `docs/pack/OPTIONAL-FEATURES.md`, `agent-run.sh` all present; fixture HEAD `1d39609` == manifest line 8.
  - Contrast (proves it is the project-template projection, not all v11-surface): pack-side `.claude/.codex/.gemini` agents/skills do NOT project into fixtures — `find test-fixtures -path '*/agents/pack-*'` → empty; `find test-fixtures -path '*skills/commit-discipline*'` → empty. That is why the plan's C2 ("expected empty manifest") is correct but C6a/C7a/C8a's "manifest regen required + project-only clean" is not.
- **Concrete fix (one of):** (i) Drop the `project-only` keyword on C6a/C7a/C8a and use NEUTRAL framing (no keyword → Check 36 skips) for the data halves — this is precisely what the prior plan recommended and what decision 6 over-rode; the over-ride is unsafe given the manifest. The user chose SPLIT to get an exclusive keyword on every commit, but the manifest makes an exclusive `project-only` keyword IMPOSSIBLE on any commit that edits project-template and regenerates the manifest. Re-surface decision 6 to the user with this constraint. OR (ii) Split each data half AGAIN into a `project-only` content commit (no manifest) + a separate `pack-only` manifest commit — but a `project-only` commit that changes project-template WITHOUT regenerating the manifest VIOLATES the manifest-regen rule (the manifest would be stale at that commit boundary, and CI's `build.sh --verify` step would go RED). So (ii) does not work either. The only green options are NEUTRAL framing on the data halves, or folding the manifest regen + the project data into a single neutral-keyword commit. The plan must pick and the user must approve, because it reverses decision 6 for the project halves.
- **Note:** This is a real defect, not a judgment call — Check 36's denial of non-project-side paths in a `project-only` commit is deterministic and the manifest change is deterministic.

### MUST

**M-1 — §C/§J declare "every commit single-surface + keyword-exclusive" as a settled invariant; B-1 breaks the invariant for 3 of 11 commits and the plan offers no fallback.**
- **Location:** §A line 32 ("Each carries an EXCLUSIVE Check-36 keyword … no commit is neutral-framed"); §C line 170 (load-bearing decision 1); §J1 line 375 ("Every commit MUST carry an exclusive CI-verified Check-36 keyword … This is a binding constraint").
- **What's wrong:** The plan elevates "exclusive keyword on every commit" to a STANDING binding constraint (J1) and bases green-per-commit on it. Because B-1 shows that is unachievable for C6a/C7a/C8a, the binding constraint is itself unsatisfiable as written. The plan must either relax J1 (neutral framing permitted where the manifest forces a cross-prefix stage) or re-architect the split. Leaving J1 as an absolute will send a coder into a guaranteed Check-36 failure with no escape, since the bounded review/fix cycle cannot "fix" a keyword that is structurally impossible.
- **Fix:** Amend J1 to: "Every commit carries an exclusive keyword EXCEPT a `project-template/`-editing commit that must also stage the regenerated `test-fixtures/manifest.txt`, which uses NEUTRAL framing (Check 36 skips) — the manifest path is pack-only and cannot co-exist with `project-only`." Reconcile §A/§C/§G/§I accordingly. User must approve (reverses decision 6 for the project halves).

**M-2 — `git checkout -- <path>` carve-out removal: the plan's `grep -c 'checkout -- <path>'` PREFLIGHT is necessary but not SUFFICIENT for the Codex `.toml` audience-correct excision.**
- **Location:** §B C4 (lines 87/350); §F EE-8 (line 284); §D manual check (e) (line 191).
- **What's wrong (judgment-call-adjacent, but real):** The plan's completeness gate is `grep -c 'checkout -- <path>' == 0` across the 3 pack-coder files. Live, the Codex `.toml:21` embeds the clause mid-sentence inside a longer read-only-verbs prose block: *"… git checkout (except `git checkout -- <path>` to inspect file contents at a different ref). These are forbidden …"*. A naive excision of just the parenthetical leaves the sentence grammatically intact, but the SURROUNDING prose ("You MAY NOT run … git checkout (except …)") must also be reconciled so the removed exception does not leave a dangling "(except )" or a now-false "git checkout" listing. `grep -c == 0` would pass on a grammatically-broken or semantically-stale excision. The plan correctly says "per-CLI audience-correct, NOT byte-identical" (decision 3) but the gate it specifies only proves the TOKEN is gone, not that the prose is coherent and the verb-list correct.
- **Evidence:** `grep -n 'checkout -- <path>'` → `.codex/agents/pack-coder.toml:21` (mid-sentence, distinct prose) vs `.claude/agents/pack-coder.md:37` / `.gemini/agents/pack-coder.md:39` (a `git stash`, `git checkout` (except … list item). Confirmed the Codex prose differs structurally.
- **Fix:** Add to the C4 PREFLIGHT/reviewer gate (beyond `grep -c == 0`): a manual read-back of each of the 3 excised sentences confirming (a) no orphan "(except)" fragment, (b) `git checkout` either stays in the deny enumeration with NO exception or is handled per §5.1 (plain `checkout` of a path IS destructive → it stays DENIED, no carve-out). This is an enumerate-encoding-surfaces lock-step nuance the plan under-specifies.

### SHOULD

**S-1 — Guard-A allowlist will grow by this very review doc once committed; the plan's re-measure mandate is present but the per-file static enumeration in §F EE-2 omits this file.**
- **Location:** §F EE-2 (line 240/242); §K bullets (lines 391-392).
- **What's wrong:** This review doc (`PACK-REVIEW-BD-197-PLAN-ADVERSARIAL-2.md`) QUOTES the prohibition regex (`no worktree isolation|Do not pass .*isolation.*worktree`) verbatim in B-1 and in the Guard-A regex sanity test — so once committed it WILL match the prohibition-only matcher and must be added to the Guard-A allowlist (a 22nd file). The plan's static EE-2 enumeration (21 files) predates this doc and does not list it. The plan DOES carry the correct mitigation ("the process-artifact set keeps growing; the C5 coder re-measures at commit-time, never trusting this static enumeration" — §F EE-2 / §K), so this is not a blocker — but the C5 coder must be explicitly reminded that BOTH adversarial PLAN reviews (this one + the 1st) are KEEP allowlist carriers, not just the 1st.
- **Evidence:** This doc quotes the regex; by construction it will `rg -c > 0`. The 1st adversarial plan review already matches at 8 (live-confirmed). The matcher will return 22 after this doc commits.
- **Fix:** No plan edit strictly required (the re-measure mandate covers it), but tighten §K bullet to name "BOTH PLAN-adversarial reviews" as KEEP carriers so the C5 coder's allowlist is complete.

**S-2 — §G/§D manifest handling for the `pack-only` GUARD halves (C6b/C7b/C8b) is correct, but the plan should state that those scripts-only commits ALSO regenerate the manifest (the v11-* fixture SHAs do NOT change for a pure `scripts/validate-pack.py` edit, so the manifest diff is likely EMPTY).**
- **Location:** §G rows C6b/C7b/C8b (lines 308/310/312: "YES (`scripts/`) | YES").
- **What's wrong (precision):** `scripts/validate-pack.py` is not projected into the fixtures (it is a pack operation, not client content), so editing ONLY `scripts/validate-pack.py` + adding a `scripts/tests/test-*.sh` does NOT change any fixture SHA → the manifest diff is EMPTY for C6b/C7b/C8b. The plan says "manifest regen required: YES" for them, which is true as a RUN obligation (the four-dir trigger includes `scripts/`), but the STAGE is conditional on a non-empty diff (which will be empty). The plan's general rule (§G line 314 "stage if diff non-empty") covers this, but the per-row "YES" without the "expected-empty" caveat (which C2 correctly gets) is inconsistent. Minor, but the coder should not be surprised when the C6b/C7b/C8b manifest stage is a no-op.
- **Fix:** Mirror C2's "RUN build to confirm; stage ONLY if diff non-empty (expected empty)" caveat onto C6b/C7b/C8b rows.

### NIT

**N-1 — §A C7b "may drop to 10 commits" interacts with the manifest precision (S-2): if C7b is dropped AND C6b/C7b/C8b have empty manifest diffs, the §G "10–11 of 11 regen" count (line 314) is loose.** Cosmetic; the §G rule is correct, only the prose count is imprecise. No fix required.

**N-2 — §F EE-1 interpretation says the design "said ~155" invocations vs the live 186.** Confirmed live = 186; the ci-check-runtime-compounding memory's "~155" is the older figure. The plan correctly budgets against 186. No defect; noting the delta is handled.

---

## Re-measurement table (my live measurement vs the plan's §F, HEAD `ae3d932`)

| Claim | Plan §F value | My live measurement | Command | Delta |
|---|---|---|---|---|
| HEAD | `ae3d932` | `ae3d9325889c41f7cba7a4289437cf7a87d04292` | `git rev-parse HEAD` | NONE |
| Branch | `v11-dev` | `v11-dev` | `git rev-parse --abbrev-ref HEAD` | NONE |
| Battery validate-pack invocations | 186 (EE-1) | 186 | `grep -rcE 'validate-pack\.py' scripts/tests/*.sh \| awk -F: '{s+=$2}END{print s}'` | NONE |
| Highest existing Check | 51 (EE-6) | 51 | `grep -oE 'Check [0-9]+' scripts/validate-pack.py \| grep -oE '[0-9]+' \| sort -n \| tail -1` | NONE |
| Prohibition-only matcher file count | 21 (EE-2) | 21 (does NOT yet include this review doc) | `rg -l 'no worktree isolation\|Do not pass .*isolation.*worktree' -g '!.git' -g '!test-fixtures' \| wc -l` | NONE (this doc will make it 22 — see S-1) |
| Per-file STRIP counts | CLAUDE.md=1, BD-196-S1=1, CONCEPTUAL-REVIEW=1, PLAN-SKILL-DIM=2 | identical | `rg -c …` per file | NONE |
| Per-file KEEP counts | RECONCILED=6, ADVERSARIAL-2=6, RESEARCH-P1=5, first-design=3, AGENT-PERMISSION=1, IMPL-BD-196-C9=1, PLAN=4, PACK-REVIEW-PLAN-ADVERSARIAL=8 | identical | `rg -c …` per file | NONE |
| EXCLUDED (0 matches): BD-197.md, 1st adversarial, IMPL-BD-214-C5a | 0/0/0 | 0/0/0 | `rg -c …` per file | NONE — correctly EXCLUDED |
| Dangling-ref active non-process EXCISE targets | 3 (EE-3) | 3 (ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY, RESEARCH-19C-G-ITEMS-VERIFICATIONS, RESEARCH-CLAUDE-REPOS-SURVEY) | `rg -l 'feedback_worktree_isolation_broken_from_v11_clone' … \| grep -vi archive` (10 total: 7 process + 3 excise) | NONE |
| OPTIONAL-FEATURES baseline (baseRef/bgIsolation) | 0/0 (EE-4) | 0/0 (rg exit 1, both files exist 6861/5490 B) | `rg -c 'bgIsolation\|baseRef' pack-ops/OPTIONAL-FEATURES.md project-template/docs/pack/OPTIONAL-FEATURES.md` | NONE |
| Trinity placement (root AGENTS/GEMINI + project trinity) | all 0 (EE-7) | AGENTS=0, GEMINI=0, project trinity ×3 = 0; prohibition only at CLAUDE.md:325; Sub-agent heading only in CLAUDE.md | `grep -c 'worktree' …`; `grep -n 'Sub-agent behavior' …` | NONE |
| RW/RO counts | pack 5 (1RW+4RO); project 16 (2RW+14RO); READONLY_AGENTS=14 (EE-5) | pack 5 ×3 CLIs; project 16; READONLY_AGENTS=14 entries; coder+repo-ops absent → 2 RW | `ls …/agents`; `ls project-template/.claude/agents/*.md \| wc -l`; `grep -nA20 READONLY_AGENTS=` | NONE |
| Carve-out sites | 3 (EE-8) | 3 — `.codex/…toml:21` (mid-sentence, distinct prose), `.gemini/…md:39`, `.claude/…md:37` | `grep -n 'checkout -- <path>' …` | NONE; per-CLI prose difference CONFIRMED (supports decision 3) |
| validate-pack green baseline | exit 0 PASSED (EE-6) | exit 0, "PASSED — all checks clean" | `python3 scripts/validate-pack.py; echo $?` | NONE |
| Manifest baseline clean | clean (EE-9) | clean (git status empty) | `git status --short test-fixtures/manifest.txt` | NONE |
| Check 47 sanctioned set (J4 gate) | `{detect.sh, pack-help.sh}` | `_SANCTIONED_PACK_SIDE_SHIPPED = ("scripts/lib/detect.sh","scripts/pack-help.sh")` (`:4429`), set-equality enforced | `grep -n _SANCTIONED_PACK_SIDE_SHIPPED …` | NONE |
| Check-51 self-skip precedent | `:2169` | `scripts/validate-pack.py:2169` → `if entry.name == "validate-pack.py":` | `grep -n 'entry.name == "validate-pack.py"'` | NONE |
| §D wired-test list vs validate-pack.yml | full enumeration | matches the 60 wired invocations extracted from the yml | `grep -oE 'scripts/tests/…\.sh' .github/workflows/validate-pack.yml` | NONE |
| Guard-A regex false-positive on new enable text | (implied no) | NO match on the §12.1(a) / §9 enable-bullet test strings; DOES match the current prohibition | `printf … \| rg 'no worktree isolation\|Do not pass .*isolation.*worktree'` | NONE — G-1/G-2 fix sound |

**Conclusion:** EVERY §F number reproduces EXACTLY at live HEAD — the plan's measurement is trustworthy. The one un-recorded delta is forward-looking (this review doc will make the prohibition matcher 22, covered by the plan's re-measure mandate, S-1). The defects are NOT measurement errors; they are a logic gap (B-1/M-1) the measurements actually EXPOSE (the manifest-vs-Check-36 collision the plan measured around but did not reconcile).

---

## Three-axis assessment

### Axis 1 — Plan solidity / green-per-commit: **FAIL (fixable).**
- Mode-model correction: **PASS.** No residue of the wrong model survives as current fact. `9-cell` / `matrix` appear only in the design+plan as REMOVED/superseded ("9-cell matrix removed", "those are REMOVED from the design (§3)"). `bgIsolation` is consistently described as the background-SESSION gate → BD-218, never the subagent trigger. `baseRef` is the BASE (`head` required, `fresh`=origin/main consequence stated). `trigger` hits all correctly point to the `isolation:"worktree"` PARAMETER. The OPTIONAL-FEATURES content (C5 pack / C8a project) instructs `baseRef:"head"` with the fresh=origin/main consequence and points `bgIsolation` to BD-218. The Guard-A regex provably does NOT false-positive on the new enable text (live-tested). This axis of the correction is fully landed and faithful to the RECONCILED design.
- Green-per-commit: **FAIL** on B-1 — the three `project-only` DATA halves cannot be both keyword-exclusive and manifest-correct. The data-first ordering (guards land after data) IS sound; Guard-A′ shipping once in C8b IS sound; the Guard-A NARROW self-exception IS correctly sized (allowlist = measured KEEP only, validator self-skip + ONLY the check-53 test, BD-197.md + 1st adversarial correctly EXCLUDED). But the per-commit Check-36 cleanliness — the explicit point of the split — is broken for C6a/C7a/C8a.

### Axis 2 — Pack/project isolation + Check-36 correctness: **PASS on isolation, FAIL on Check-36 keyword.**
- Surface isolation: **PASS.** Every commit is genuinely single-surface in CONTENT: C1–C5 + C6b/C7b/C8b touch only pack-self (`pack-ops/`/`scripts/`/pack-root trinity/skills/agents); C6a/C7a/C8a touch only `project-template/`. No pack-self concept (BD-NNN, `maintenance-docs/`, `pack-*`, Pack Chat, `pack-ops/`) is smuggled into `project-template/` — §I rows 352/354/356 explicitly enumerate ZERO pack-self refs for every client commit. Client artifacts (PM-CHAT merge-back, project OPTIONAL-FEATURES, project agent files) are authored client-NATIVE ("PM Chat" orchestrator, client paths, "NOT a byte-copy") — §B C6a/C7a/C8a + §9 design. The §11 prohibition-removal is pack-side ONLY (EE-7 confirms project trinity + root AGENTS/GEMINI carry zero worktree refs; client carries no prohibition). The Claude-only trinity exemption is preserved (C2 NOT propagated to root AGENTS/GEMINI).
- Check-36 keyword correctness: **FAIL** — the manifest stage breaks `project-only` on C6a/C7a/C8a (B-1/M-1). The pack-only halves' keywords are correct (they touch only `scripts/`).

### Axis 3 — Rule capture both sides + no cross-contamination: **PASS.**
- agents-never-commit + full destructive-verb ban RETAINED for ALL agents incl. RW on BOTH surfaces: §I intro + every row; RW merge-back = orchestrator /tmp-patch apply (`git apply` orchestrator-only; agent runs only `git diff > /tmp/...`). The "no platform safety net for subagents → RW must be spawned isolated; verb-ban load-bearing" reinforcement is present (§I intro, §B C4/C7a) and faithful to FACT-4 in the design.
- RW/RO two-class model present on both with the right per-surface mechanism: pack = PACK-AGENTS `Class` column + per-agent prose headers + Guard-B(pack) Check 52 bound to PROSE header (not `tools:`); project = PM-CHAT table + `agent-run.sh READONLY_AGENTS` projection + per-agent headers + Guard-B(project) Check 55. Counts measured correct (pack 1+4; project 2+14).
- Claude-only scope with Codex/Gemini deferred to BD-217 (not pulled in; exemption preserved — §K, §B C2). Background-session axis deferred to BD-218 (only deferral; user-authorized; BD-218 confirms scope). cross-CLI normalization for trinity edits + the per-CLI Codex carve-out removal (decision 3) is captured (M-2 is a sufficiency tightening, not a capture gap).

---

## Rules-Applied Verification Block

| # | Rule (as named in prompt) | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | pack-project-separation-of-concerns | §B/§I require client OPTIONAL-FEATURES/PM-CHAT/agent files authored client-native ("PM Chat" orchestrator, client paths, "NOT a byte-copy of pack" — §B C7a line 115, §9 design); pack and project OPTIONAL-FEATURES are SEPARATE artifacts, neither a fallback. No cross-side substitution found. | COMPLIANT |
| 2 | bd-pack-only-operational-rule | §I C6a/C7a/C8a (lines 352/354/356) each enumerate "ZERO pack-self refs in project-template/ — no BD-NNN/maintenance-docs/pack-*/Pack-Chat/pack-ops"; directory-based; no leak found in the planned client commits. EE-7 confirms project trinity carries 0 worktree/prohibition content today. | COMPLIANT |
| 3 | client-ref-delete-or-forward-look | §I C6a/C8a list the rule; no client-shipped pack-repo path is introduced by the planned client commits (client OPTIONAL-FEATURES references client `agent-run.sh`/`.claude/settings.json`, not pack paths). | COMPLIANT |
| 4 | verify-full-ci-suite | §D enumerates every wired script; I extracted the live yml (60 invocations) and confirmed the §D list matches (test-detect, all tracker-*, per-entry, all test-validate-pack-check-*, template-translations, test-v11-realistic-ot, migrator tests, build.sh). Run-before-wire mandate (author→run→wire→re-run battery same commit) present for every new check. | COMPLIANT |
| 5 | ci-guard-design-measure-then-bound | Live-verified: prohibition matcher = 21 with exact per-file KEEP/STRIP; allowlist sized to measured KEEP only (validator self-skip `:2169` precedent + ONLY check-53 test + measured doc carriers); BD-197.md + 1st adversarial correctly EXCLUDED (0 matches). Guard-A′ tokens sized to exactly `baseRef`+`bgIsolation`. Guard-A regex live-tested: NO false-positive on the new enable text. Challenged the allowlist — it does NOT admit more than the measured legitimate set; it does NOT self-match after the narrow fix. | COMPLIANT |
| 6 | ci-check-runtime-compounding | §E bounds each guard single-pass/scoped/runtime-guarded; budget vs the live-confirmed 186 invocations (EE-1 = 186, I reproduced 186); each coder records wall-time vs budget (decision 4). | COMPLIANT |
| 7 | commit-subject-keyword-token-trap | Applied as the LENS for B-1: the memory's explicit manifest-staging warning ("a `project-only` commit that stages `test-fixtures/manifest.txt` can't be `project-only`") is the exact defect — flagged BLOCKER. No stray keyword tokens in the planned subjects observed beyond the intended ones; mixed commits forbidden under the split (but B-1 shows the split cannot deliver an exclusive keyword on the project halves). | COMPLIANT (rule applied; defect surfaced) |
| 8 | enumerate-encoding-surfaces | §H lists each changed surface + validators + tests + CI refs in lockstep; every new check's test wired same commit. M-2 raised a sufficiency gap in the carve-out completeness gate (token-grep proves token-absence but not prose coherence). | COMPLIANT (with M-2 tightening) |
| 9 | regenerate-manifest-v11-surface | §G's 11-row table reviewed against live fixture-projection facts: C6a/C7a/C8a DO change the manifest (project-template projects into fixtures — `git -C test-fixtures/v11-flat-file ls-files` confirms; build.sh:905-906 authoritative). That correct manifest obligation is what COLLIDES with their `project-only` keyword (B-1). C2/C6b/C7b/C8b manifest handling reviewed (S-2 precision). | COMPLIANT (rule applied; B-1/S-2 surfaced) |
| 10 | agents-never-commit + destructive-verb ban (ALL agents incl RW) | §I intro + rows: all agents read-only git; RW merge-back = orchestrator /tmp-patch apply; "RW must be spawned isolated / no safety net" reinforcement present (faithful to FACT-4). This review ran ZERO state-changing git verbs (only `git rev-parse`/`git status`/`git show`/`git log`/`git ls-files` reads + `rg`/`grep`/`ls`/`python3 validate-pack.py`); the only write is this report doc. | COMPLIANT |
| 11 | cross-cli-reference-normalization | §B C2/C4/C7a + §I: trinity edits audience-correct per-CLI; Codex carve-out removal per-CLI (decision 3 — live-confirmed the Codex `.toml` prose differs); Claude-only exemption NOT propagated to root AGENTS/GEMINI (EE-7); Codex/Gemini = BD-217 deferred (§K). | COMPLIANT |
| 12 | dependency-direction-placement | §J4 + §I C4: the C4 new-pack-side-script GATE is a pre-coding architect+user HARD STOP (decision 5); Check-47 `_SANCTIONED_PACK_SIDE_SHIPPED` live-confirmed frozen to `{detect.sh, pack-help.sh}` with set-equality enforcement — a net-new shipped pack-side file would trip it, motivating the gate correctly. | COMPLIANT |
| 13 | scope-deliverables-to-the-ask | Plan is an execution artifact (leads with the 11-commit sequence §A); no design restatement; only the background-session axis deferred (BD-218, §K). | COMPLIANT |
| 14 | rules-applied-verification-block | This block; every row carries quoted/measured evidence; no empty cell; no AMBIGUOUS terminal state. | COMPLIANT |

---

**Bottom line.** The mode-model correction landed cleanly and the §F measurements are exact and trustworthy. The plan is one logic gap away from APPROVE: the 11-commit split's central promise (an exclusive Check-36 keyword on every commit) is structurally unachievable for the three `project-only` data halves, because editing `project-template/` forces a `test-fixtures/manifest.txt` stage that is a pack-only path and therefore denies `project-only`. Resolve B-1/M-1 (neutral framing on the project data halves, with user sign-off since it reverses decision 6 for those commits), tighten the carve-out gate (M-2), and the plan is coder-ready.

*End of PACK-REVIEW-BD-197-PLAN-ADVERSARIAL-2.md*
