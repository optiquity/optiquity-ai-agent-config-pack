# PACK-REVIEW-BD-197-PLAN-ADVERSARIAL-3 — final adversarial review of the converged execution plan + Check-36 carve-out

**Role:** pack-reviewer (fresh, adversarial, final pre-coder gate). **Mode:** read-only on the codebase; one report written (this file).
**Repo:** optiquity-ai-agent-config-pack-v11-dev · **Branch:** v11-dev · **HEAD at review:** `ae3d9325889c41f7cba7a4289437cf7a87d04292` (`ae3d932`).
**Date:** 2026-06-13.

## Read-in-full attestation

I read each NAMED input directly and in full (no skim, no summary, no crop, no derivation), and did NOT read any prior PACK-REVIEW (to avoid bias):
- `maintenance-docs/v11-implementation/PLAN-BD-197-WORKTREE-ISOLATION.md` (467 lines, the artifact under review — §A–§K + attestation + Rules-Applied block).
- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` (878 lines, the authority — incl. the NEW §17 carve-out 617–878, the Correction pass 12–60, §1 64–135, §3 160–196, §4 198–266, §5 270–313, §9 366–386, §11 411–483, §13 526–547).
- `scripts/validate-pack.py` Check 36 region (`_PROJECT_SIDE_PATH_PREFIXES`:4126; `_is_project_side_path`:4250; offender branches `pack_only`:4313 / `project_only`:4323 / `pack_chat_only`:4333; `check_commit_scope_honesty`:4264; `_commit_paths`:4194; Check-51 self-skip:2169; `_SANCTIONED_PACK_SIDE_SHIPPED`:4429).
- `scripts/tests/test-validate-pack-checks-36-37-38.sh` (`required` list 43–53; `assert_pside` block ~158–172).
- `backlog/BD-197.md` (all notes 1–11, incl. Note 11 PROBE+SCHEMA CORRECTION) + `backlog/BD-218.md`.
- `CLAUDE.md` `## Pack memory` in full.
- the memory file `project_bd197_user_design_direction.md` in full.

All load-bearing state-claims were INDEPENDENTLY re-measured live (commands + verbatim output in the Re-measurement table + Findings). No state-change git verb was run; the one `build.sh --all --clean` (run twice, plus one project-edit simulation) was each followed by a manifest restore; manifest + working tree confirmed clean afterward.

---

## VERDICT

**APPROVE.** The Check-36 carve-out is correctly sized to EXACTLY the measured forced-co-variant set `{test-fixtures/manifest.txt}` (independently proven by simulating a real `project-template/` edit: the build forces exactly `M PM-CHAT.md + M manifest.txt`, nothing else pack-side), it does not weaken Check 36 (a real cross-surface offender still fires, verified against the live module), and the restored 12-commit split is genuinely green-per-commit with every commit single-surface and a correct Check-36 keyword. No BLOCKER and no MUST defect; the few SHOULD/NIT items below are non-blocking and do not gate the C0 coder spawn.

---

## Findings (by severity)

### BLOCKER — none.

### MUST — none.

### SHOULD

**S3-1 — Guard-A's KEEP allowlist will be undersized by ONE at C5 commit-time: this very review (`PACK-REVIEW-BD-197-PLAN-ADVERSARIAL-3.md`) quotes the prohibition regex and will self-match.** Real defect (forward-looking), already half-anticipated by the plan but worth pinning.
- Location: plan §F EE-2 (line 266) + §K (line 433) — both enumerate the prohibition-matcher KEEP set as the 1st + 2nd PLAN-adversarial reviews and state "Any FUTURE review doc that quotes the regex joins the set."
- What's right: the plan's static count is **22** and I re-measured **22** live (the 22 do NOT yet include this 3rd review, which is untracked/unwritten at measurement time). The plan EXPLICITLY mandates re-measure-at-C5-commit-time and warns the set grows with each review pass. So this is captured in spirit.
- The residual risk: the C5 coder's allowlist must include `PACK-REVIEW-BD-197-PLAN-ADVERSARIAL-3.md` once it lands (it will quote `no worktree isolation` / `Do not pass .*isolation.*worktree` in this Findings section — confirmed: this very paragraph contains both literals). If the coder trusts the plan's static "22" / two-review enumeration instead of re-measuring, Guard-A self-REDs on this doc.
- Evidence: `rg -c 'no worktree isolation|Do not pass .*isolation.*worktree'` over this file at write time will return ≥2 (the two literals above). The live 22-file set did not include it because it did not exist when measured.
- Fix (no plan edit strictly required — already mandated): the C5 coder PREFLIGHT re-runs the matcher at commit-time and sizes the allowlist to the LIVE set, which by then includes THREE PLAN-adversarial reviews (1st=8, 2nd=3, 3rd=N). Recommend Pack Chat call this out explicitly in the C5 spawn prompt's "Rules in force" block so the coder does not anchor on the plan's two-review enumeration. Judgment call, not a plan error.

**S3-2 — The plan's §17.7 / design runtime note still cites "~155 validate-pack invocations" while the rest of the plan correctly uses 186.** Minor stale-figure inconsistency between the design's §17.7 (line 867: "the ~155 validate-pack invocations") and the plan's corrected 186 (§E line 216, §F EE-1 line 261).
- Location: design `ARCHITECTURE-...-RECONCILED.md` §17.7 line 867 ("does not compound across the ~155 validate-pack invocations in the battery"). The plan §F EE-1 (line 261) explicitly records the delta ("design said ~155 … budget is set against 186, not 155"), so the plan is internally correct.
- What's wrong: the design doc (the authority) carries a stale count in §17.7. It is harmless for the carve-out (O(1) membership is negligible at any battery size), but it is a measurement the plan already re-measured and corrected elsewhere — leaving the design's §17.7 at 155 is a small lockstep gap.
- Evidence: live `grep -rcE 'validate-pack\.py' scripts/tests/*.sh | awk -F: '{s+=$2} END{print s}'` → `186`.
- Fix: not blocking (the carve-out cost is O(1) regardless). If the design is touched again, update §17.7's "~155" to "186". The plan already supersedes it with 186. SHOULD, not MUST, because the discrepancy cannot change any correctness or green-per-commit outcome.

### NIT

**N3-1 — The plan's commit-count hedge ("12 commits, 11 if C7b folds — J3") is correct but the §A table header still says "Total = 12 commits".** The fold-to-11 path (decision 8, coder's call) is well-documented in §A line 33, §C line 185, §I C7b, §J3. No defect; the dual count is intentional and surfaced to the user. No action needed.

**N3-2 — EE-2's "22" is a moving target by construction.** The plan acknowledges this (§K line 433–434). Each future BD-197-process doc that quotes the regex bumps the count. Not a defect — the re-measure mandate is the correct design. Flagged only so the user knows the "22" is a snapshot, not an invariant.

---

## Re-measurement table (my live measurement vs the plan's §F)

| Claim | Plan §F value | My live measurement (HEAD `ae3d932`) | Command | Delta |
|---|---|---|---|---|
| HEAD | `ae3d932` | `ae3d9325889c41f7cba7a4289437cf7a87d04292` | `git rev-parse HEAD` | MATCH |
| Branch | v11-dev | v11-dev | `git rev-parse --abbrev-ref HEAD` | MATCH |
| Battery validate-pack invocations | 186 | 186 | `grep -rcE 'validate-pack\.py' scripts/tests/*.sh \| awk -F: '{s+=$2} END{print s}'` | MATCH |
| Highest Check number | 51 | 51 | `grep -oE 'Check [0-9]+' scripts/validate-pack.py \| grep -oE '[0-9]+' \| sort -n \| tail -1` | MATCH |
| validate-pack baseline | green (exit 0) | `PASSED — all checks clean`, exit 0 | `python3 scripts/validate-pack.py` | MATCH |
| Manifest clean | clean | clean (empty `git status --short`) | `git status --short test-fixtures/manifest.txt` | MATCH |
| Prohibition matcher file count | 22 | 22 | `rg -l --hidden --no-ignore 'no worktree isolation\|Do not pass .*isolation.*worktree' -g '!.git' -g '!test-fixtures'` | MATCH |
| Prohibition per-file counts | CLAUDE.md=1, BD-196-S1=1, CONCEPTUAL=1, SKILL-DIMENSIONS=2, RECONCILED=6, ADVERSARIAL-2=6, RESEARCH-P1=5, first design=3, AGENT-PERMISSION=1, BD-196-C9=1, PLAN=4, PLAN-ADV-1=8, PLAN-ADV-2=3 | IDENTICAL on all 13 | `rg -c ... <each file>` | MATCH (all 13) |
| Prohibition EXCLUDED set (0 matches) | BD-197.md=0, 1st adversarial=0, IMPL-REPORT-BD-214=0 | 0 / 0 / 0 | `rg -c ... <each>` | MATCH |
| Carve-out forced-co-variant set | `{test-fixtures/manifest.txt}` | `{test-fixtures/manifest.txt}` — proven by SIMULATED project edit → `M PM-CHAT.md + M manifest.txt`, nothing else pack-side | `printf >> PM-CHAT.md; build.sh --all --clean; git status --porcelain <5 dirs>; restore` | MATCH (strengthened) |
| Tracked test-fixtures files | 8 (.gitignore, README, build.sh, manifest, +4 snapshot) | 8 (identical) | `git ls-files test-fixtures/` | MATCH |
| Carve-out not-weakened (NC-4/5/6) | S1→[], S2→`[scripts/validate-pack.py]` | NC-4 [], NC-5 [], NC-6 `[scripts/validate-pack.py]`, EXTRA pack-only+project `[PM-CHAT.md]` | live module micro-eval | MATCH (strengthened) |
| Check-36 loci | 4126/4250/4313/4323/4333 | 4126/4250/4313/4323/4333 | `grep -n` | MATCH |
| Check-51 self-skip precedent | 2169 | 2169 (`entry.name == "validate-pack.py"`) | `grep -n` | MATCH |
| `_SANCTIONED_PACK_SIDE_SHIPPED` | 4429 = `{detect.sh, pack-help.sh}` | 4429 | `grep -n` | MATCH |
| Check-36 test wired in yml | yes | yes (validate-pack.yml:169) | `grep -n` | MATCH |
| Test `required` list / `assert_pside` | 43–53 / ~158–172 | `required` 43–53; `assert_pside` def ~158, asserts 165–172 | `sed -n` | MATCH |
| Dangling-ref EXCISE (active non-process) | 3 (SKILL-AGENT-MAINTAINABILITY, RESEARCH-19C-G, RESEARCH-CLAUDE-REPOS-SURVEY) | 3 (identical) | `rg -l 'feedback_worktree_isolation_broken_from_v11_clone' ... \| grep -vi archive` | MATCH |
| pack agents | 5 (×3 CLIs) | 5 (architect/coder/docs-researcher/planner/reviewer) | `ls .{claude,codex,gemini}/agents` | MATCH |
| project agents | 16 | 16 | `ls project-template/.claude/agents/*.md \| wc -l` | MATCH |
| READONLY_AGENTS | 14 (→ 2 RW) | 14 entries | `grep -nA20 'READONLY_AGENTS='` | MATCH |
| OPTIONAL-FEATURES baseline | 0/0 (both exist) | exit 1 (no matches); 6861 / 5490 bytes | `rg -c 'bgIsolation\|baseRef' <both>` | MATCH |
| pack-coder carve-out sites | 3 (.claude:37, .codex:21, .gemini:39) | 3 (identical lines) | `grep -n 'checkout -- <path>'` | MATCH |
| Codex `.toml` mid-sentence embed (M-2) | yes, differs from .md prose | confirmed: `.toml:21` is one long read-only block; `.md` files standalone `git checkout (except …)` | `sed -n` | MATCH |
| Root AGENTS/GEMINI worktree refs | 0/0 | 0/0 | `grep -c worktree` | MATCH |
| project trinity worktree refs | 0/0/0 | 0/0/0 | `grep -c worktree` | MATCH |
| Gemini project agents `tools:` | 0/16 | 0 files with `^tools:` | `grep -l '^tools:'` | MATCH |
| agents-never-commit section | trinity (### Workflow), parallel ×3 | CLAUDE.md:152, AGENTS.md:154, GEMINI.md:121 (all 3; ### Workflow, NOT Claude-only) | `grep -n 'Agents never commit'` | MATCH |
| CLAUDE.md prohibition bullet | :325 (Claude-only subsection) | :325 (### Sub-agent behavior (Claude-only) at :323) | `grep -n` | MATCH |

**Net: zero adverse deltas.** Every load-bearing number in the plan reproduced exactly on live measurement. Two measurements were STRENGTHENED beyond the plan's: (1) I proved the forced-co-variant causally (a real project-template edit forces exactly the manifest + nothing else pack-side) rather than only inferring it from a byte-identical rebuild; (2) I executed the NC-4/5/6 predicate eval against the live module, plus an extra pack-only+project case, all confirming the guard still fires on real cross-surface offenders.

---

## Three-axis assessment

### Axis 1 — Plan solidity / green-per-commit

**SOLID.** The carve-out is the correct fix to the manifest pincer and it restores a clean keyword-exclusive split.

- **C0 sizing (the crux).** Measure-then-bound is satisfied EXACTLY. I independently re-measured the forced-co-variant set TWICE: (a) `build.sh --all --clean` at clean HEAD → zero tracked changes (manifest already in sync); (b) the decisive causal test — append a temp line to `project-template/docs/pack/PM-CHAT.md`, rebuild → `git status --porcelain` over all five v11-surface dirs returned EXACTLY `M project-template/docs/pack/PM-CHAT.md` (project-side) + `M test-fixtures/manifest.txt` (the sole pack-side forced co-variant), and the manifest diff showed 3 fixture SHAs drifting (v11-realistic-ot, v11-flat-file, v11-tracker-on), proving project-template projects into the fixtures. NO other pack-side path was forced. The carve-out frozenset of one path is neither under- nor over-sized.
- **EXACT-PATH vs PREFIX.** Confirmed the carve-out must be set-membership, not a `test-fixtures/` prefix: the live `_is_project_side_path` returns False for `test-fixtures/v11-trinity-marker-prepped/CLAUDE.md`, `test-fixtures/build.sh`, `test-fixtures/README.md` — a prefix carve-out would wrongly exempt those REAL pack-side files. The design §17.4 + plan §B C0 + test NC-3 all correctly pin exact-string. Sound.
- **Not weakened.** Live module micro-eval: NC-6 (`[project, scripts/validate-pack.py, manifest]`) → offenders `['scripts/validate-pack.py']` (guard fires); an extra pack-only commit smuggling a project file → offenders `['project-template/docs/pack/PM-CHAT.md']` (guard fires). The manifest carries only fixture SHAs (verified: 6 data rows of `<name> <sha>`), and a hand-edited manifest is independently caught by `build.sh --verify` (wired in the battery, plan §D line 201). No content-smuggling channel.
- **Green-per-commit ordering.** C0 lands FIRST (carve-out-aware Check 36 evaluates every later `project-only` commit). C0 itself is cleanly `pack-only`: it touches only `scripts/validate-pack.py` + its already-wired test; neither projects into client fixtures → manifest diff EMPTY → no manifest stage (no self-referential pincer). Verified: validate-pack.py is not a fixture-projected file (the project-edit simulation drifted fixtures, but a scripts/ edit does not). Each `project-only` DATA half (C6a/C7a/C8a) = project content + carved manifest → Check 36 GREEN (NC-4 proven) AND `build.sh --verify` GREEN (manifest is the build-faithful regen). Each `pack-only` GUARD half (C6b/C7b/C8b) lands AFTER its data → green on arrival (measure-then-bound: asserts the post-data state). Guard-A′ ships ONCE in C8b after both surfaces carry the keys. Guard-A's NARROW self-exception (validator self-skip + only the check-53 test) prevents the C5 self-RED. No commit fires a guard on absent/wrong-state data; no keyword claim Check 36 would reject. The split is genuinely green-per-commit.
- **Test lockstep (C0).** The plan correctly treats C0 as the exception-that-proves-the-rule: the Check-36 test is ALREADY wired (validate-pack.yml:169), so there is no run-before-wire ceremony, but the validator edit + the test UPDATE (Group 0 `required += _is_scope_neutral_generated`; Group 1 NC-1..NC-6) land in the SAME commit, and the updated test is RUN + the full battery re-run before the IMPL-REPORT. enumerate-encoding-surfaces honored.

### Axis 2 — Pack/project isolation

**CLEAN.** No cross-contamination; the carve-out treats ONLY a generated artifact as scope-neutral.

- Every one of the 12 commits is single-surface with a CI-verified Check-36 keyword: C0 + C1–C5 + C6b/C7b/C8b = `pack-only` (`scripts/`/`pack-ops/` only); C6a/C7a/C8a = `project-only` (`project-template/` content + the scope-neutral manifest only). The carve-out does NOT blur real pack vs project content — the static `v11-trinity-marker-prepped/` snapshot + the recipe `build.sh`/`README.md` still count toward scope (verified: exact-set membership excludes them).
- §11 prohibition-removal is pack-side ONLY (verified: root AGENTS/GEMINI worktree refs = 0; project trinity worktree refs = 0; the prohibition lives only in CLAUDE.md:325's Claude-only subsection). P3 client work is net-new/additive.
- Client artifacts authored client-native: §B/§I require client OPTIONAL-FEATURES + PM-CHAT authored independently ("PM Chat" orchestrator, client paths, "NOT a byte-copy"); §I C6a/C7a/C8a rows enumerate ZERO pack-self refs (no BD-NNN, `maintenance-docs/`, `pack-*`, Pack Chat, `pack-ops/`) in any `project-template/` edit. bd-pack-only-operational-rule honored.
- The Claude-only exemption is preserved correctly (C2 does NOT propagate the worktree bullet to root AGENTS/GEMINI), while the `agents-never-commit` amendment (C4) IS correctly treated as a trinity rule (it lives in `### Workflow` at all 3 root files: CLAUDE.md:152 / AGENTS.md:154 / GEMINI.md:121 — verified). The plan distinguishes these two cases precisely; this is the highest-risk trinity nuance and it is handled correctly.

### Axis 3 — Rule capture, both sides

**COMPLETE.**

- agents-never-commit + full destructive-verb ban retained for ALL agents incl. RW: §I intro + every coder row require read-only git only; RW merge-back = orchestrator applies the agent's `/tmp` patch (`git apply` orchestrator-only; agent runs only `git diff > /tmp/...`). The "no platform safety net → RW must be spawned isolated; verb-ban load-bearing" reinforcement (Correction pass / FACT-4) is present in §I intro + C4 + C7a rows. Matches BD-197 note 2/11 + BD-218 inheritance.
- The M-2 fix (Codex `.toml` carve-out removal needs PROSE-COHERENCE, not just token-absence) is present in the C4 coder row (§B line 104, §I C4 line 386): "grep=0 is necessary-not-sufficient" + the read-back for the orphan `(except )` fragment + `git checkout` staying in the deny list with no exception. I confirmed the concern is real: `.toml:21` embeds the clause mid-sentence in a longer read-only-verbs block, while `.md` files carry it standalone (`git checkout (except git checkout -- <path> …)`). After excision `git checkout` must remain denied in all 3.
- The C4 new-pack-side-script GATE (J4 / decision 5 / dependency-direction-placement) is a pre-coding architect+user HARD STOP, correctly tied to the FROZEN Check-47 `_SANCTIONED_PACK_SIDE_SHIPPED = {detect.sh, pack-help.sh}` (verified at :4429). The coder may not author a new pack-side script on its own authority.
- Claude-only with Codex/Gemini → BD-217 and background-session → BD-218 are deferred (verified BD-218 is `Status: Deferred`, `Target: v11.1`, Blockers: BD-197) and NOT pulled in (§K is the only deferral block; user-authorized 2026-06-14). cross-cli-reference-normalization: trinity edits audience-correct; the Codex carve-out removal is per-CLI; the Claude-only exemption is not propagated to root AGENTS/GEMINI.
- The mode model is folded on the CORRECTED two-independent-mechanisms model (subagent `isolation:"worktree"` param × `baseRef`; background-session `bgIsolation` → BD-218; NO 9-cell matrix / NO bgIsolation-as-trigger) consistently across §B C2/C5/C8a + §I rows + design §3/§9/§13.1a + BD-197 note 11. No residual "bgIsolation is the trigger" or "9-cell matrix" language survives in the plan's prescriptive rows.

---

## Rules-Applied Verification Block

| # | Rule (as named in prompt) | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | ci-guard-design-measure-then-bound | Re-measured the forced-co-variant set myself: clean rebuild → 0 tracked changes; **causal** test (append to `project-template/docs/pack/PM-CHAT.md` + rebuild) → `git status --porcelain` over 5 v11-surface dirs = exactly `M PM-CHAT.md` + `M test-fixtures/manifest.txt`, nothing else pack-side; manifest diff = 3 fixture SHAs drifted. Carve-out = `frozenset({"test-fixtures/manifest.txt"})` — sized to EXACTLY this set; NOT a prefix (exact-set excludes `test-fixtures/build.sh`/`README.md`/snapshot — live `_is_project_side_path` = False for all, so a prefix would wrongly exempt them). Not-weakened: NC-6 live → offenders `['scripts/validate-pack.py']` (guard fires); extra pack-only+project → `['project-template/docs/pack/PM-CHAT.md']` (guard fires). | COMPLIANT |
| 2 | ci-check-runtime-compounding | Carve-out = O(1) `frozenset` membership per offender candidate on an already-materialized path-set (`_commit_paths`), no new subprocess/whole-tree scan — negligible across the **186** battery invocations (live `grep -rcE 'validate-pack\.py' scripts/tests/*.sh \| awk … = 186`). Each new guard scoped single-pass/runtime-guarded per §E. (Design §17.7 still says "~155"; S3-2 — harmless for O(1).) | COMPLIANT |
| 3 | pack-project-separation-of-concerns | Carve-out treats ONLY the generated manifest as scope-neutral (manifest content = hashes only, verified); real pack content (snapshot/recipe) still counts. Every commit single-surface (Axis 2); prohibition-removal pack-side only (root AGENTS/GEMINI + project trinity worktree refs = 0/0/0/0/0 live); client artifacts authored client-native (§B/§I). | COMPLIANT |
| 4 | bd-pack-only-operational-rule | §I C6a/C7a/C8a rows require ZERO pack-self refs (no BD-NNN/`maintenance-docs/`/`pack-*`/Pack-Chat/`pack-ops/`) in any `project-template/` edit; enumerated per client commit. | COMPLIANT |
| 5 | client-ref-delete-or-forward-look | §I C6a/C8a rows carry client-ref-delete-or-forward-look; no client-shipped pack-repo path introduced (client OPTIONAL-FEATURES/PM-CHAT are separate client artifacts, not pack-path references). | COMPLIANT |
| 6 | verify-full-ci-suite | §D enumerates every wired script (validate ×2 + the full tests-job list + the NEW per-check tests); C0 RUNS the UPDATED `test-validate-pack-checks-36-37-38.sh` (already wired — verified validate-pack.yml:169) + re-runs the FULL battery, SAME commit; run-before-wire for every NEW check (C3/C5/C6b/C7b/C8b); names `test-v11-realistic-ot.sh` as the banner-pin trap. | COMPLIANT |
| 7 | commit-subject-keyword-token-trap | Every commit keyword correct + single-surface: C0 + C1–C5 + C6b/C7b/C8b = `pack-only`; C6a/C7a/C8a = `project-only` (achievable via C0). §A subjects name other-scope in plain words ("(data)"/"(guard)"), no stray keyword token in prose. | COMPLIANT |
| 8 | enumerate-encoding-surfaces | §H lists each changed surface + validators + tests + CI refs + cross-ref docs across all 12 commits. C0 changes `scripts/validate-pack.py` + `test-validate-pack-checks-36-37-38.sh` in lockstep (Group 0 `required` += `_is_scope_neutral_generated` — verified the `required` block at lines 43–53 is the correct insertion point, mirroring `_is_project_side_path` at :49; Group 1 NC-1..NC-6 after the `assert_pside` block ~:172). M-2 prose-coherence read-back added to C4. | COMPLIANT |
| 9 | regenerate-manifest-v11-surface | §G's 12-row table: every v11-surface commit RUNS the build; STAGE fires on EXACTLY C6a/C7a/C8a (project-content; fixture SHAs drift — verified live the 3 v11 fixtures drift on a project edit); expected-EMPTY on the 9 pack-side commits incl. C0/C6b/C7b/C8b (validate-pack.py + pack docs do NOT project into fixtures — verified a clean rebuild yields 0 tracked changes). Carved manifest (C0) lets C6a/C7a/C8a stage it under `project-only`. | COMPLIANT |
| 10 | cross-cli-reference-normalization | §B C2/C4/C7a + §I rows: trinity edits audience-correct; `git checkout -- <path>` carve-out removal per-CLI (Codex `.toml:21` mid-sentence vs `.md` standalone — confirmed live) + M-2 prose-coherence read-back; Claude-only exemption NOT propagated to root AGENTS/GEMINI (worktree refs 0/0 live); Codex/Gemini = BD-217 (deferred). | COMPLIANT |
| 11 | dependency-direction-placement | §B C4 + §J4 + §I C4: C4 backstop NEW-pack-side-script GATE = pre-coding architect+user HARD STOP, Check-47 frozen allowlist `{detect.sh, pack-help.sh}` (verified :4429) — not coder-resolved. | COMPLIANT |
| 12 | agents-never-commit + destructive-verb ban (ALL agents incl RW) | §I intro + every row: read-only git only; RW merge-back = orchestrator applies the agent's `/tmp` patch (`git apply` orchestrator-only); "RW must be spawned isolated; verb-ban load-bearing" present (§I intro + C4/C7a). THIS REVIEW ran ZERO state-changing git verbs: only `git rev-parse`/`git status`/`git status --porcelain`/`git ls-files`/`git diff` reads + read-only `rg`/`grep`/`sed`/`ls`/`python3`/`bash build.sh`; the `build.sh --all --clean` runs (incl. the project-edit simulation) were each followed by file restore from `/tmp` backups; manifest + working tree confirmed clean afterward (`git status --porcelain <5 dirs>` = empty). | COMPLIANT |
| 13 | scope-deliverables-to-the-ask | Report leads with the carve-out-sizing + green-per-commit verdict; high-signal; only real findings surfaced (no invented nits); only BD-217/BD-218 deferrals confirmed. | COMPLIANT |
| 14 | rules-applied-verification-block | This block; every row quoted/measured evidence; no empty cell; no AMBIGUOUS terminal state. | COMPLIANT |

---

**Bottom line.** The Check-36 carve-out is correctly sized to EXACTLY the measured forced-co-variant set `{test-fixtures/manifest.txt}` (proven causally, not just inferred), is exact-path not prefix, and provably does not weaken Check 36 (real cross-surface offenders still fire against the live module). The restored 12-commit split is genuinely green-per-commit, every commit single-surface with a CI-verified keyword, with C0 landing first as the enabling commit. Pack/project isolation is clean and rule capture is complete on both sides. Every load-bearing number in the plan reproduced exactly on independent live measurement. **APPROVE** — the only items are a forward-looking re-measure reminder for Guard-A's allowlist (S3-1, already mandated by the plan) and a cosmetic stale "~155" in the design's §17.7 (S3-2, harmless for an O(1) check). Neither gates the C0 coder spawn.

*End of PACK-REVIEW-BD-197-PLAN-ADVERSARIAL-3.md*
