# IMPL-REPORT — BD-197 C1: P2 disposition of NON-RULE worktree-prohibition carriers

**Role:** pack-coder (fresh). **Commit:** C1 (`pack-only`; P2 phase). **Surface:** PACK-SELF only (`maintenance-docs/` + `pack-ops/`); ZERO client surface touched.
**Repo:** optiquity-ai-agent-config-pack-v11-dev · **Branch:** v11-dev.
**Base HEAD (pre-flight + final, unchanged — agents-never-commit):** `e7cefbe89eecb9c9ed4ff3d5d00f79f415d4b495`.
**Date:** 2026-06-14.

---

## Read attestation (no skim / no derivation)

I read each NAMED authoritative input DIRECTLY and IN FULL before editing — no skim, no summary, no crop, no derivation:

- `maintenance-docs/v11-implementation/PLAN-BD-197-WORKTREE-ISOLATION.md` — read in full across pages (lines 1-187, 188-337, 338-467). §B "C1" per-file disposition list (lines 62-77); §C green-per-commit (C1/C2 add no new guard); §D verification (C1/C2 emphasis line 205); §G manifest table (C1 row, line 336); §I C1 spawn row (line 383); §J-resolved-9 (decision 9 update-in-place, line 407); §K out-of-scope (S-1 re-measure mandate).
- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` — §11.1 disposition table (13 rows, lines 417-433), §11.2 operational mentions (LEAVE PACK-CHAT benign mention), §11.3 dangling-ref reconciliation (lines 442-448), §11.4 historical records LEAVE (line 450), §11.5 completeness gate (gate (a) prohibition-only matcher, lines 452-483). Plus the heading map (§0/§3/§9/§11/§12/§13/§17) to anchor the enabled-model wording (§12.1(a)).
- `backlog/BD-197.md` — all notes 1-12 read. Note 1 (Claude-only first; Codex/Gemini = BD-217); Note 2 (two agent classes, agents-never-commit retained); Note 7 D4 (leave the 4 archive dangling-refs); Note 11 (PROBE+SCHEMA CORRECTION — the enabled two-independent-mechanisms model: `isolation:"worktree"` param = subagent trigger; `baseRef:"head"` required base, `fresh`=origin/main wrong-base degradation; `bgIsolation` = background-session gate → BD-218).
- `CLAUDE.md` `## Pack memory` — read in full (incl. `fail-loud-delete-old-source` reconcile-in-place clause via the curated memory file, `edit-in-place-not-full-rewrite`, `regenerate-manifest-v11-surface`, `ci-guard-design-measure-then-bound`, `scope-deliverables-to-the-ask`, `enumerate-encoding-surfaces`, `verify-full-ci-suite`, `bd-pack-only-operational-rule`, `pack-project-separation`).
- The curated memory file `/Users/david/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/feedback_fail_loud_delete_old_source.md` — read in full. The load-bearing clause for C1: case (b) — "a still-ACTIVE doc (live inbound refs, mostly-current content) with a stale ELEMENT → reconcile the element IN PLACE (mark/correct it), do NOT delete the active doc." All 8 C1 targets are ACTIVE docs with a stale element → reconcile-in-place (NOT annotate-as-superseded, which is RETIRED; NOT wholesale delete).

---

## Fresh-audit note (live HEAD advanced beyond the plan's measurement)

The plan/design measured at HEAD `ae3d932` / `3e3159e`. The live tree at C1-commit-time is HEAD `e7cefbe` — ADVANCED. Per the design's mandatory fresh-audit instruction (§11) I re-measured both matchers LIVE. The advance added NEW BD-197-process docs that legitimately QUOTE the matchers and belong to the LEAVE set (allowlist), confirming the re-measure-at-commit mandate (§K / S-1): the process-artifact set grows with each pass.

**Live delta vs the plan's static enumeration (all in the LEAVE set — no action for C1):**
- Prohibition matcher gained `IMPL-REPORT-BD-197-FIX-SHOULDS.md` + `PACK-REVIEW-BD-197-FIX-SHOULDS.md` (2 NEW BD-197-process docs; LEAVE).
- Dangling-ref matcher gained `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-CLEANUP-BATCH-19B-19b-6.md` + `maintenance-docs/archive/v11/ARCHITECTURE-CLEANUP-BATCH-19B.md` (2 NEW archive matches; LEAVE per D4).

The 4 STRIP/UPDATE prohibition targets and the 3 dangling-ref EXCISE targets are UNCHANGED from the plan's enumeration.

---

## Per-file disposition (8 files modified; all reconcile-in-place, decision 9)

### Group 1 — UPDATE prohibition / bug-era model → enabled opt-in model

#### 1. `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` (digest bullet, was line 194) — `pack-only`, v11-surface (pack-ops/)
The pack-memory digest bullet carried the bug-era prohibition phrasing.
- **Before:** `- Spawn sub-agents in background; no worktree isolation from non-main clones`
- **After:** `- Spawn sub-agents in background; sub-agents run in-place by default, with opt-in worktree isolation (BD-197)`
- Drops out of the prohibition matcher (was 1 match → 0). Delta: 1/1.

#### 2. `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md` §D (lines 415-420) — UPDATE IN PLACE (decision 9)
The §D bug-era block (items 1-3 = the prohibition: "No `isolation: "worktree"`", "Never use Agent-tool worktree isolation"). Item 4 (parallel in-place agents allowed) is still accurate — preserved.
- **Before (items 1-3):** "No `isolation: "worktree"` on Agent calls … checks out `origin/main` regardless of parent cwd"; "Run agents in-place…"; "Never use Agent-tool worktree isolation."
- **After:** item 1 = "Sub-agents run in-place by default"; item 2 = the enabled opt-in model (per-spawn `isolation:"worktree"` param trigger; `worktree.baseRef:"head"` required base with the `fresh`=origin/main wrong-base degradation; RW agents emit a `/tmp` patch; Claude-only / trinity-exempt; Codex/Gemini = BD-217; pointer to `OPTIONAL-FEATURES.md`); item 3 = opt-in worktrees OR separate chat sessions. Item 4 unchanged.
- Drops out of the prohibition matcher (was 0 — the matcher's specific phrasings did not catch §D's wording; updated regardless because §D IS the real bug-era prohibition). Delta: 3/3.
- **§E line 424 LEFT untouched** — it references "the Sub-agent isolation rule in pack-root CLAUDE.md" as an example of a justified tool-specific trinity exemption. That rule still exists (becomes the enable rule, still Claude-only/trinity-exempt), so the citation remains accurate. Not in C1 scope to alter.

#### 3. `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §4.8 + reproductions — UPDATE IN PLACE (decision 9)
FOUR prohibition loci (matcher counted 2; the others use different phrasings — fresh-audit caught all 4):
- §4.8 heading + body (lines 923-932): heading was "Worktree isolation broken from v11-dev clone" + "Do not pass `isolation:"worktree"`…" → rewritten to "Worktree isolation (opt-in; BD-197)" with Default (in-place) + Opt-in (param trigger + `baseRef:"head"`, `fresh`=origin/main degradation, Claude-only, OPTIONAL-FEATURES pointer).
- §5 bullet (lines 962-963): "Do not pass `isolation:"worktree"`…" → "In-place by default; opt-in worktree isolation per BD-197…".
- §6.4 (lines 1042-1047): "do NOT pass `isolation:"worktree"` … worktree isolation lands at `origin/main`…" → in-place default + opt-in per BD-197 (param + `baseRef:"head"`).
- §8 summary (lines 1293-1294): "Do NOT pass `isolation:"worktree"` to the spawn." → in-place by default; opt-in per BD-197.
- Drops out of the prohibition matcher (was 2 → 0). Delta: 25/20.

#### 4. `maintenance-docs/v11-implementation/PLAN-DOC-CONCISION-GUARDRAILS.md` (coder-spawn-template fragment, line 187) — UPDATE
- **Before:** `… run_in_background:true; NO worktree isolation; rules-in-force …`
- **After:** `… run_in_background:true; in-place by default, with opt-in worktree isolation per BD-197; rules-in-force …`
- (Matcher counted 0 for this file — "NO worktree isolation" did not hit the regex; updated regardless per the plan §11.1 row 8 spec.) Delta: 1/1.

#### 5. `maintenance-docs/v11-implementation/ARCHITECTURE-BD-196-S1-CORPUS-CLASSIFICATION.md` row #24 — excise stale line-range + reflect rule change
Row #24 is a classification-inventory record (what bullets existed at BD-196-S1 time + how they were classified).
- **Before:** `| 24 | Spawn all sub-agents with no worktree isolation | … | L348-357 |`
- **After:** `| 24 | Sub-agent worktree isolation (opt-in; BD-197 replaced the prior bug-era prohibition) | … | `### Sub-agent behavior (Claude-only)` worktree bullet (line numbers drift) |`
- **DISPOSITION (recorded per plan §11.1 row 9 / design §11.1 row 9):** I did NOT retain the old rule-name prohibition prose. The Bullet cell now uses the NEW rule name + a supersession note; the stale `L348-357` Evidence line-range is excised and replaced with a symbol-anchored reference (line numbers drift). **Consequence for C5's Guard-A allowlist:** because the old prohibition phrasing is GONE, this file DROPS OUT of the prohibition matcher (was 1 → 0) and therefore does NOT need to be added to Guard-A's allowlist — consistent with the EXECUTION-PLAN/SKILL-DIMENSIONS treatment (the plan's preferred outcome: the file leaves the matcher entirely rather than being allowlisted). Delta: 1/1.

### Group 2 — EXCISE the dangling-ref `feedback_worktree_isolation_broken_from_v11_clone` (3 active non-process carriers, design §11.3)

#### 6. `maintenance-docs/v11-research/RESEARCH-CLAUDE-REPOS-SURVEY.md` — UPDATE stale caveat + EXCISE dangling-ref (also a Group-1 update target)
Five stale loci updated; 2 dangling-ref tokens excised:
- L44 (claude-squad summary): "breaks the isolation-broken-from-clone caveat already known in v11" → "redundant against Claude Code's Agent Teams and the pack's own opt-in worktree isolation (BD-197), both documented in OPTIONAL-FEATURES.md".
- L159 (superpowers integration shape): EXCISED the dangling-ref `feedback_worktree_isolation_broken_from_v11_clone.md`; "already discussed in pack memory" → "now supported as the pack's own opt-in worktree isolation (BD-197)".
- L299 (claude-squad integration shape): EXCISED the dangling-ref; "documents that worktree isolation already lands under the main clone's HEAD … that bug would bite harder" → enabled-model framing (the base-branch behavior BD-197 addresses via `worktree.baseRef:"head"`).
- L300 (Risks/friction): "a real pack bug to keep clear of" → "overlaps the pack's own opt-in worktree isolation (BD-197) and its `worktree.baseRef:"head"` base-branch requirement".
- L375 (cross-cutting summary): "known worktree-isolation bug" → "the pack's own opt-in worktree isolation (BD-197)".
- Dangling-ref token count: 2 → 0. Delta: 5/5.

#### 7. `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` §6.11 — EXCISE dangling-ref
- **Before:** heading "Worktree isolation broken from v11-dev clone (`feedback_worktree_isolation_broken_from_v11_clone.md`)" + "**No conflict.** Orthogonal — that rule governs sub-agent spawning mechanics."
- **After:** heading "Worktree isolation (opt-in; BD-197)" + "**No conflict.** Orthogonal — the worktree-isolation rule governs sub-agent spawning mechanics (sub-agents run in-place by default; a chat MAY opt a sub-agent into an isolated worktree per BD-197)."
- The "no conflict" analysis is preserved (still orthogonal to skill-agent maintainability); only the dead memory-file pointer + the bug-era rule name are corrected. Token count: 1 → 0. Delta: 4/4.

#### 8. `maintenance-docs/v11-implementation/RESEARCH-19C-G-ITEMS-VERIFICATIONS.md` — EXCISE dangling-ref
The research-evidence list (GitHub issues #50850/#41680/#43535 + the `worktree.baseRef="head"` workaround) describes real, current Claude Code behavior foundational to the enabled model — PRESERVED. Only the "Pack-side memory pointer" bullet citing the deleted memory file was excised.
- **Before (bullet):** "Pack-side memory pointer (cross-reference, not authority): `~/.claude/.../feedback_worktree_isolation_broken_from_v11_clone.md` — empirically established by the pack repo …".
- **After:** "Pack-side: BD-197 enables safe, opt-in worktree isolation — sub-agents run in-place by default, and a chat MAY opt a sub-agent into an isolated worktree (with `worktree.baseRef = "head"` so the worktree bases at local HEAD). The web evidence above shows the underlying base-branch mechanism is general."
- The "Architect implication" prose below (still-accurate: "unless `worktree.baseRef = "head"` is set or no-isolation sequential agents are used") LEFT untouched. Token count: 1 → 0. Delta: 5/4.

---

## PLAN-DEPLOYMENT-PYTHON-OBSERVABILITY.md — real-vs-incidental determination (plan §11.1 row 13)

**Determination: INCIDENTAL → LEAVE (not edited).**

Evidence: `rg -n 'worktree|isolation|baseRef' maintenance-docs/v11-implementation/PLAN-DEPLOYMENT-PYTHON-OBSERVABILITY.md` returns exactly two hits, both in the Step-S0 pre-flight checklist (lines 266, 268):
```
pwd                                    # Must end in worktree path or v11-dev cwd
git rev-parse --abbrev-ref HEAD        # Verify v11-dev (or worktree-agent-* if running under worktree isolation)
```
These are runtime ground-truth checks that ACCOMMODATE worktree isolation as a legitimate regime ("or worktree-agent-* if running under worktree isolation"). They do NOT carry the prohibition (the file has 0 prohibition-matcher hits) and there is NO `baseRef` token at all (the plan's hypothesized "incidental `baseRef` token" does not exist here). The content is fully consistent with the enabled opt-in model — it anticipates isolation as a valid state — so per plan §11.1 row 13 ("UPDATE if real, LEAVE if incidental"), this file is LEFT untouched.

---

## Strip-completeness gate (ci-guard-design-measure-then-bound: before/after)

### Prohibition matcher — `rg -l --hidden --no-ignore 'no worktree isolation|Do not pass .*isolation.*worktree' -g '!.git' -g '!test-fixtures'`

**BEFORE (live, HEAD e7cefbe) — 24 files:** `CLAUDE.md`, `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`, `…/ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md`, 9× `maintenance-docs/archive/v11/*`, `…/ARCHITECTURE-BD-197-WORKTREE-ISOLATION.md`, `…/PLAN-SKILL-DIMENSIONS.md`, `…/PACK-REVIEW-BD-197-PLAN-ADVERSARIAL-3.md`, `…/PACK-REVIEW-BD-197-PLAN-ADVERSARIAL.md`, `…/ARCHITECTURE-BD-196-S1-CORPUS-CLASSIFICATION.md`, `…/PACK-REVIEW-BD-197-PLAN-ADVERSARIAL-2.md`, `…/RESEARCH-BD-197-P1-WORKTREE-ISOLATION.md`, `…/PLAN-BD-197-WORKTREE-ISOLATION.md`, `…/PACK-REVIEW-BD-197-FIX-SHOULDS.md`, `…/ARCHITECTURE-BD-197-ADVERSARIAL-REVIEW-2.md`, `…/RESEARCH-BD-197-AGENT-PERMISSION-INVENTORY.md`, `…/IMPL-REPORT-BD-197-FIX-SHOULDS.md`, `…/IMPLEMENTATION-REPORT-BD-196-C9.md`.

**AFTER (live, post-C1-edits) — 21 files:**
- `CLAUDE.md` — **the actual trinity rule (C2's job; EXPECTED to remain after C1).**
- 9× `maintenance-docs/archive/v11/*` — archive history (LEAVE per D4).
- 11× BD-197-process docs + history (LEAVE / allowlist): RECONCILED, first design (`ARCHITECTURE-BD-197-WORKTREE-ISOLATION.md`), `ADVERSARIAL-REVIEW-2`, `RESEARCH-BD-197-P1`, `RESEARCH-BD-197-AGENT-PERMISSION-INVENTORY`, this PLAN, the 3 `PACK-REVIEW-BD-197-PLAN-ADVERSARIAL{,-2,-3}.md`, `PACK-REVIEW-BD-197-FIX-SHOULDS.md`, `IMPL-REPORT-BD-197-FIX-SHOULDS.md`, `IMPLEMENTATION-REPORT-BD-196-C9.md` (history).

**Δ = 3 files removed** (the 3 STRIP targets that the matcher caught: `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`, `PLAN-SKILL-DIMENSIONS.md`, `ARCHITECTURE-BD-196-S1-CORPUS-CLASSIFICATION.md`). Remaining set = EXACTLY {trinity rule (C2) + archive + BD-197-process/history}. **No active non-rule non-process carrier still matches.** GATE CLEAN.

### Dangling-ref matcher — `rg -l 'feedback_worktree_isolation_broken_from_v11_clone' -g '!.git'`

**BEFORE (live) — 16 files:** the 3 EXCISE targets (`RESEARCH-CLAUDE-REPOS-SURVEY.md`, `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md`, `RESEARCH-19C-G-ITEMS-VERIFICATIONS.md`) + `backlog/BD-197.md` + 8 BD-197-process docs + 4 archive.

**AFTER (live, post-C1-edits) — 13 files:** `backlog/BD-197.md` (BD-197 entry, LEAVE — Pack-Chat bookkeeping, not coder scope) + 8 BD-197-process docs (RECONCILED, first design, `ADVERSARIAL-REVIEW`, `ADVERSARIAL-REVIEW-2`, `RESEARCH-BD-197-P1`, this PLAN, `PACK-REVIEW-BD-197-PLAN-ADVERSARIAL-2`, `PACK-REVIEW-BD-197-PLAN-ADVERSARIAL-3`) + 4 archive (LEAVE per D4).

**Δ = 3 files removed** = EXACTLY the 3 active non-process EXCISE targets. **No active non-process carrier still matches.** GATE CLEAN. (Did NOT touch the BD-197-process docs that quote the token as part of BD-197, nor `backlog/BD-197.md`, nor archive history — per the scoping instruction.)

---

## Full CI suite results (verify-full-ci-suite — EVERY wired script; no sampling)

All commands run at HEAD `e7cefbe`, 2026-06-14, after the C1 edits. Every script wired in `.github/workflows/validate-pack.yml` was run; exit statuses quoted.

### validate job (2/2)
| Step | Command | EXIT |
|---|---|---|
| Run pack validation | `python3 scripts/validate-pack.py` → "PASSED — all checks clean" | **0** |
| Run pack validation (DEEP) | `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` → "PASSED — all checks clean" | **0** |

### tests job (all scripts, yml order — all EXIT 0)
- **Part 1 (14):** test-detect.sh, tracker-provider-test.sh, tracker-config-test.sh, tracker-init-test.sh, tracker-agent-read-test.sh, tracker-migrate-forward-test.sh, tracker-migrate-reverse-test.sh, tracker-migrate-roundtrip-test.sh, test-tracker-phase-task.sh, test-tracker-links.sh, test-tracker-cycle-check.sh, tracker-errors-test.sh, tracker-config-schema-test.sh, recommendation-state-schema-test.sh — **all EXIT 0**.
- **Part 2 (18):** test-per-entry.sh, test-validate-pack-checks-32-33-34.sh, test-validate-pack-checks-36-37-38.sh, test-validate-pack-check-39.sh, -40, -41, -18, -16, -19, -42, -43, -44, -45, -46, test-validate-pack-check-removed-doc-advisory.sh, test-validate-pack-check-49-field-faithfulness.sh, test-validate-pack-check-50-codec-single-source.sh, test-validate-pack-check-51-flip-block.sh — **all EXIT 0**.
- **Part 3 (17):** tracker-deferral-gate-test.sh, tracker-bd129-gh-repo-test.sh, tracker-bd130-doctor-wired-test.sh, tracker-bd132-race-test.sh, tracker-bd133-header-preservation-test.sh, tracker-bd134-close-retry-test.sh, recommendation-test.sh, pack-help-test.sh, test-customization-preserve.sh, test-init-project.sh, test-migrate-v10-to-v11.sh, test-migrate-v10-to-v11-dry-run.sh, test-migrate-v10-to-v11-gates.sh, test-migrate-v10-to-v11-decompose.sh, test-migrator-core.sh, test-migrator-manifest.sh, test-migrator-capability-translation.sh — **all EXIT 0**.
- **Part 4 (fixtures + integration, 9):** `build.sh --all --clean` (EXIT 0) → `git checkout HEAD -- test-fixtures/manifest.txt` (read-only checkout-of-path; EXIT 0; BD-118 CI sequence) → `build.sh --verify` (EXIT 0, all 7 fixtures OK) → test-v11-realistic-ot.sh (EXIT 0, the BD-203/BD-214 banner-pin trap — clean), test-migrator-skills.sh (EXIT 0), test-persona-contracts.sh (EXIT 0), template-translations-test.sh (EXIT 0, trinity/skill parity), template-version-test.sh (EXIT 0), test-issue-forms.sh (EXIT 0).

**Total: 2 validate + 49 tests-job invocations = ALL EXIT 0. FULL BATTERY GREEN.**

Per-commit emphasis (plan §D C1/C2): `test-v11-realistic-ot.sh` (validator OUTPUT/banner pins — the BD-203/BD-214 trap) and `template-translations-test.sh` (trinity/skill parity) both pass — no banner or parity regression from the doc edits.

---

## Manifest determination (regenerate-manifest-v11-surface)

C1 touches `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` → `pack-ops/` is a v11-surface dir → the manifest build RUN obligation fires.
- Command: `bash test-fixtures/build.sh --all --clean` → EXIT 0.
- `git status --short test-fixtures/manifest.txt` → **EMPTY** (no diff).
- **Determination:** manifest diff is EMPTY (pack-ops/ docs do not project into the client fixtures — exactly as plan §G predicted for C1). **Nothing staged.** The post-battery re-run + restore confirms manifest.txt remains clean.

---

## Plan deviations

**One documented deviation (forced by the live HEAD advance; consistent with the design's fresh-audit + re-measure mandate):**

1. **Live HEAD is `e7cefbe`, not the plan's `ae3d932`.** Per the design §11 fresh-audit instruction I re-measured both matchers live. The LEAVE set is larger than the plan's static enumeration (2 new BD-197-process docs in the prohibition matcher; 2 new archive docs in the dangling-ref matcher). This is NOT a scope deviation — it is the design's explicit "re-measure at commit-time; the process-artifact set grows" contract (plan §K / S-1). The 4 STRIP/UPDATE prohibition targets + 3 dangling-ref EXCISE targets are UNCHANGED from the plan. No C1 action changed.

No other deviations. C1 did exactly the plan §B C1 disposition list; did NOT touch C2's trinity rule or commit-discipline skills; did NOT touch any client surface; did NOT touch `PLAN-DEPLOYMENT-PYTHON-OBSERVABILITY.md` (incidental, LEAVE); did NOT touch the BD-197-process docs / history / archive / benign PACK-CHAT mention.

---

## New POQs introduced

None. All edits followed the locked plan/design with no design gap encountered.

---

## Out-of-scope items surfaced (not silently fixed; scope-deliverables-to-the-ask)

1. **Pack-Chat bookkeeping owed (NOT coder scope):** `backlog/BD-197.md` Description (line 9) + Acceptance criterion (line 36) still say "4 dangling refs / 4 historical decision-records". The measured active EXCISE set is **3** non-process carriers (excised in C1). Per plan §B C1 line 75, updating the BD entry's stale "4" figure is a Pack-Chat-direct bookkeeping edit, not C1's commit. Flagged for Pack Chat.
2. **Known minor nit (already tracked, BD-197 Note 12):** `test-validate-pack-checks-36-37-38.sh` emits cosmetic shell-stderr noise from a pre-existing unquoted-heredoc path expansion. It exits 0 (confirmed above). Disposition is accept-for-now per Note 12; not touched (cosmetic, pre-existing, out of C1 scope).

---

## Definition-of-Done checklist

| Item | Status |
|---|---|
| All NON-RULE non-process active carriers updated in place to the enabled model (no annotate-as-superseded) | **PASS** (5 prohibition/bug-era carriers UPDATED in place: CONCEPTUAL-REVIEW-METHODOLOGY, EXECUTION-PLAN §D, PLAN-SKILL-DIMENSIONS ×4 loci, PLAN-DOC-CONCISION-GUARDRAILS, ARCHITECTURE-BD-196-S1 row #24) |
| 3 dangling-ref active non-process carriers excised | **PASS** (RESEARCH-CLAUDE-REPOS-SURVEY, ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY, RESEARCH-19C-G-ITEMS-VERIFICATIONS) |
| Strip completeness gate clean (only LEAVE-set remains) | **PASS** (prohibition: only trinity-rule[C2]+archive+process/history; dangling-ref: only BD-197 entry+process+archive) |
| PLAN-DEPLOYMENT real-vs-incidental determination recorded | **PASS** (INCIDENTAL → LEAVE) |
| FULL CI suite green (no sampling) | **PASS** (2 validate + 49 tests-job, all EXIT 0) |
| Manifest: build run; staged only if non-empty | **PASS** (built EXIT 0; diff EMPTY; nothing staged) |
| No client surface touched (`pack-only`) | **PASS** (0 project-template/ or supporting-docs/ paths) |
| No C2 work done (trinity rule + commit-discipline skills untouched) | **PASS** (CLAUDE.md line 325 prohibition intact; skills' 11 worktree refs each intact) |
| No state-changing git verb run (agents-never-commit) | **PASS** (read-only git only; the one `git checkout HEAD -- test-fixtures/manifest.txt` is the read-only path-restore form, identical to the CI BD-118 step — no branch state mutated) |
| Section maps intact (edit-in-place-not-full-rewrite) | **PASS** (heading counts verified post-edit; targeted `old→new` edits only) |
| HEAD unchanged | **PASS** (`e7cefbe…` pre + post) |

**DoD: ALL PASS.**

---

## Files changed inventory

| Path | Change type | Δ (add/del) |
|---|---|---|
| `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` | modified | 1/1 |
| `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md` | modified | 3/3 |
| `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` | modified | 25/20 |
| `maintenance-docs/v11-implementation/PLAN-DOC-CONCISION-GUARDRAILS.md` | modified | 1/1 |
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-196-S1-CORPUS-CLASSIFICATION.md` | modified | 1/1 |
| `maintenance-docs/v11-research/RESEARCH-CLAUDE-REPOS-SURVEY.md` | modified | 5/5 |
| `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` | modified | 4/4 |
| `maintenance-docs/v11-implementation/RESEARCH-19C-G-ITEMS-VERIFICATIONS.md` | modified | 5/4 |
| `maintenance-docs/v11-implementation/IMPL-REPORT-BD-197-C1.md` | new (this report) | — |

No new files except this IMPL-REPORT. No deletions. `test-fixtures/manifest.txt` NOT changed (empty diff). No files touched outside the C1 disposition list.

---

## Rules-Applied Verification Block

| # | Rule (as named in prompt) | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | fail-loud-delete-old-source (reconcile-in-place clause) | All 8 targets are ACTIVE docs with a stale element → reconciled IN PLACE via targeted `old→new` edits. NO annotate-as-superseded note added anywhere (RETIRED pattern); NO active doc deleted wholesale. The §6.11 heading + the §4.8 heading + row #24 were CORRECTED in place, not marked "(superseded)". `git diff --numstat` shows small symmetric deltas (1/1, 3/3, 1/1, 5/5, 4/4 …), not full-file rewrites. | COMPLIANT |
| 2 | edit-in-place-not-full-rewrite | Every change was a unique `old_string→new_string` Edit (each verified unique before applying). Section-map re-counted AFTER edits: EXECUTION-PLAN=26 headings, PLAN-SKILL-DIMENSIONS=37, RESEARCH-CLAUDE-REPOS-SURVEY=27, ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY=68 (all intact, no section dropped). No wholesale Write of any target. | COMPLIANT |
| 3 | ci-guard-design-measure-then-bound | Measured BOTH matchers BEFORE (prohibition 24 files; dangling-ref 16) and AFTER (prohibition 21; dangling-ref 13). Categorized every occurrence. Remaining set is EXACTLY the documented LEAVE set: trinity rule (C2's CLAUDE.md), archive (D4), BD-197-process/history docs (allowlist, grows per re-measure mandate), `backlog/BD-197.md`. Δ = exactly the 3 prohibition STRIP + 3 dangling-ref EXCISE targets. No active non-rule non-process carrier remains. | COMPLIANT |
| 4 | verify-full-ci-suite | Ran EVERY script wired in `.github/workflows/validate-pack.yml`: validate job ×2 (incl. `PACK_VALIDATE_DEEP=1`) + the entire tests job (49 invocations incl. the fixture build/restore/verify sequence + test-v11-realistic-ot.sh banner-pin + template-translations parity). All EXIT 0; statuses quoted in the Full CI suite section. No sampling. | COMPLIANT |
| 5 | regenerate-manifest-v11-surface | C1 touches `pack-ops/` (v11-surface) → ran `bash test-fixtures/build.sh --all --clean` (EXIT 0). `git status --short test-fixtures/manifest.txt` = EMPTY → staged nothing (correct — pack-ops/ docs do not project into fixtures). | COMPLIANT |
| 6 | empirical-evidence-blocks | Every state-claim backed by command + verbatim output + HEAD `e7cefbe` + date 2026-06-14: the per-file before/after match counts (`rg -c`), the matcher before/after `rg -l` lists, the full-battery EXIT statuses, the manifest-empty `git status --short`, the PLAN-DEPLOYMENT incidental-determination grep, the section-map heading counts, the `git diff --numstat` deltas. | COMPLIANT |
| 7 | preflight-stop-means-stop | Emitted the single PREFLIGHT line `PREFLIGHT: C1 dispositions complete; strip gate clean (only LEAVE-set remains); full CI battery PASS; manifest empty; HEAD e7cefbe…; about to Write IMPL-REPORT to …` ONLY after all 8 edits + the full battery PASSED. No partial report. No parent stop/halt message received. | COMPLIANT |
| 8 | agents-never-commit | Ran ZERO state-changing git verbs. Only read-only git (`git rev-parse`, `git status`, `git diff --numstat`) + the doc Edits + the manifest build (EMPTY diff → left UNSTAGED, nothing to stage). The single `git checkout HEAD -- test-fixtures/manifest.txt` is the read-only path-restore form (CI's own BD-118 step) — no branch/index/commit state mutated. HEAD `e7cefbe` unchanged pre/post. | COMPLIANT |
| 9 | scope-deliverables-to-the-ask | ONLY the C1 dispositions done. Did NOT do C2's trinity/skill removal (CLAUDE.md prohibition + commit-discipline skills verified intact). Did NOT touch client surfaces (0 project-template/supporting-docs paths). Surfaced (not fixed): the BD-197 entry's stale "4 dangling refs" figure (Pack-Chat bookkeeping) + the pre-existing test-36/37/38 cosmetic nit (BD-197 Note 12). | COMPLIANT |
| 10 | rules-applied-verification-block | This block addresses every rule in the prompt's Rules-in-force with quoted/measured evidence; no empty cell; no AMBIGUOUS terminal state. | COMPLIANT |

---

**C1 COMPLETE.** 8 NON-RULE non-process active carriers dispositioned in place to the enabled opt-in model (5 prohibition/bug-era UPDATEs + 3 dangling-ref EXCISEs; RESEARCH-CLAUDE-REPOS-SURVEY is both). Strip-completeness gate CLEAN on both matchers (only the LEAVE set — trinity rule for C2 + process + history + archive — remains). FULL CI battery GREEN (2 validate + 49 tests, all EXIT 0). Manifest diff EMPTY (nothing staged). HEAD unchanged `e7cefbe89eecb9c9ed4ff3d5d00f79f415d4b495`. No client surface touched; C2 surfaces untouched. Ready for the bounded review/fix cycle.

*End of IMPL-REPORT-BD-197-C1.md*
