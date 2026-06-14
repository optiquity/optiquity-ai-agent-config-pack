# ARCHITECTURE — BD-196 S1: Complete corpus-wide classification of `## Pack memory` bullets

**Type:** Read-only architecture decision (pack-architect output). Extends `ARCHITECTURE-BD-196-S1-RULE-BODY-TREATMENT.md` from the 2 flagged rules to ALL 45 `## Pack memory` bullets (user chose EE-7 option a: full-corpus reconciliation).
**Branch / HEAD:** `v11-dev`, `1da5376cc32f20eeb2f90421ddd95238e2d07693`. Measured 2026-05-31.
**Scope class:** STRUCTURAL (changes which rules carry tags / split bodies). A coder applies mechanically AFTER user approval.
**Read-only:** every command below is read-only (`grep`/`awk`/`wc`/`sed -n`/`git`/`python3 scripts/validate-pack.py`). The sole Write is this doc.
**Companion:** `ARCHITECTURE-BD-196-S1-RULE-BODY-TREATMENT.md` (S1 — the 2 pre-decided SPLIT rules; folded in here as rows 20 + 33).

---

## 1. The classification contract (the test applied to every bullet)

Every bullet receives EXACTLY ONE of four classifications, decided by two orthogonal property tests from `ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md` §5.1 / §9.3:

- **Test A — spawn-relevant?** §9.3: *"would Pack Chat paste this into a spawn prompt?"* YES iff the imperative is one an AGENT (architect/planner/coder/reviewer/docs-researcher) must obey while executing a spawned task. NO iff it governs Pack-Chat orchestration / routing / commit-staging / batch-bookkeeping (the §9.3 STAYS-AND-REFERENCES class).
- **Test B — separable rationale body?** §5.1(ii): does the bullet carry a genuine `**Why:**` / worked-example / rejected-alternatives body that could move to `PACK-MEMORY-RATIONALE.md` WITHOUT stripping load-bearing application detail from the imperative?

| | Test B = YES (separable body) | Test B = NO (self-contained) |
|---|---|---|
| **Test A = YES (spawn-relevant)** | **SPLIT** (`[roles:]` + `[rationale:]`, body→rationale) | **TAG-ONLY** (`[roles:]`, NO `[rationale:]`) |
| **Test A = NO (orchestration)** | **STAY-INLINE** (no tag; body is Pack-Chat procedure) | **STAY-INLINE** (no tag) |

**Anti-pattern guard (rule in force):** I do NOT split reflexively. A bullet lands SPLIT only if BOTH tests pass. Many bullets legitimately land TAG-ONLY (spawn-relevant but self-contained) or STAY-INLINE (orchestration). The goal is principled completeness, not maximal splitting.

**Note on subsection boundary:** the §9.3 "would Pack Chat paste this" test is content-driven, NOT subsection-driven — `### Pack Chat scope` bullets are mostly orchestration (STAY-INLINE) but the test is applied per-bullet, and the `### Repo conventions` bullets are mostly spawn-relevant. Subsection is descriptive, not determinative.

---

## 2. Measured baseline

> **Empirical-Evidence Block EE-1 — complete tag-state of all bullets.**
> - Command: `awk` over `CLAUDE.md ## Pack memory` extracting each `- **` bullet + whether its body contains `[roles:` and `[rationale:`. HEAD `1da5376`, 2026-05-31.
> - Output (counts): **45** `- **`-style bullets + **2** plain bullets (`### Project goals (v11)`). Tag-state distribution:
>   - roles=Y, rationale=Y: **18** (the ALREADY-DONE split set).
>   - roles=Y, rationale=N: **3** (per-entry-trees-vs-mirrors, separate-ops-from-product, test-infra-self-provisioned).
>   - roles=N, rationale=N: **24** (untagged).
> - Interpretation: the 3 roles=Y/rationale=N rules are EXACTLY the three worked-examples the design names in §5.1(ii) as the no-`[rationale:]` case (grep-confirmed: `ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md:146` lists `per-entry-trees-vs-mirrors`, `separate-ops-from-product`, `test-infra-self-provisioned`). So the implementation already produced 18 SPLIT + 3 TAG-ONLY = 21 tagged spawn-relevant rules — principled, not arbitrary. The reconciliation question is purely: how do the 24 untagged bullets + the 2 Project-goals bullets classify?
> - Conclusion: **SUPPORTED.**

> **Empirical-Evidence Block EE-2 — bijection currently holds at 18.**
> - Command: `python3 scripts/validate-pack.py 2>&1 | grep "Check 45"`. HEAD `1da5376`, 2026-05-31.
> - Output: "Check 45 — 18 corpus `[rationale: slug]` pointer(s); 18 rationale `## <slug>` section(s); sets are equal (bijection holds…)". Validator exit code 0.
> - Conclusion: **SUPPORTED.** Bijection baseline = 18==18; any SPLIT additions move both sides equally.

---

## 3. Complete classification table (all 45 + 2 bullets)

Tag-state legend: `R/r` = has `[roles:]` / has `[rationale:]`; `—` = absent.

### 3.1 `### Workflow` (12 bullets)

| # | Bullet | Tag-state | Class | Rationale (Test A / Test B) | Evidence |
|---|---|---|---|---|---|
| 1 | Agents never commit | R/r | ALREADY-DONE | split | slug `agents-never-commit` |
| 2 | Pack Chat does not architect | —/— | STAY-INLINE | A=NO: routing rule for Pack Chat (who-does-what); never pasted into an agent prompt. | L153-156; no Why-body, pure orchestration |
| 3 | One review/fix cycle per batch | —/— | STAY-INLINE | A=NO: Pack-Chat batch cadence (when to run reviewer); orchestration. | L157-161 |
| 4 | Implicit BD status flip on batch completion | —/— | STAY-INLINE | A=NO: BACKLOG-bookkeeping by Pack Chat; not an agent task rule. | L162-164 |
| 5 | Per-action approval extends to sub-agents | R/r | ALREADY-DONE | split | slug `per-action-approval-sub-agents` |
| 6 | Deferred work needs a tracked anchor | R/r | ALREADY-DONE | split | slug `deferred-work-tracked-anchor` |
| 7 | No deferral to v11.1+ without explicit user direction | R/r | ALREADY-DONE | split | slug `no-deferral-without-user-direction` |
| 8 | Deferral IS scope creep | R/r | ALREADY-DONE | split | slug `deferral-is-scope-creep` |
| 9 | Per-BD review/fix runs INLINE | —/— | STAY-INLINE | A=NO: Pack-Chat multi-BD cadence orchestration. | L190-196 |
| 10 | Pack Chat presents triage to user before fix-coder spawns | —/— | STAY-INLINE | A=NO: Pack-Chat triage-gate procedure; not pasted to an agent. | L197-205 |
| 11 | Triage all reviewer findings; default fix-all | —/— | STAY-INLINE | A=NO: Pack-Chat triage policy. | L206-214 |
| 12 | P-missed-7 — project-side investigation precedes pack-style defaults | R/r | ALREADY-DONE | split | slug `boundary-investigation-precedes-pack-defaults` |

### 3.2 `### Agent invocation rules` (11 bullets)

| # | Bullet | Tag-state | Class | Rationale (Test A / Test B) | Evidence |
|---|---|---|---|---|---|
| 13 | Pack agent invocation | —/— | STAY-INLINE | A=NO: how PACK CHAT invokes agents (CLI syntax); Pack-Chat operational, not an agent task rule. | L226-230 |
| 14 | Agent prompt requirements | —/— | AMBIGUOUS→flag | A: governs how Pack Chat CONSTRUCTS prompts (Pack-Chat-side) — but it is a prompt-authoring contract the architect/reviewer also check. B=NO (self-contained list, no Why-body). If spawn-relevant → TAG-ONLY; if pure Pack-Chat-construction → STAY-INLINE. See §5 flag F1. | L231-235 |
| 15 | No solutions in agent prompts | —/— | STAY-INLINE | A=NO: a Pack-Chat prompt-construction constraint (Pack Chat omits solutions). The agent never applies it; Pack Chat does. | L236-239 |
| 16 | No prior reviews to pack-reviewer | —/— | STAY-INLINE | A=NO: Pack-Chat prompt-construction constraint (what Pack Chat puts in a reviewer prompt). | L240-242 |
| 17 | Researcher-first pipeline for substantive content | —/— | AMBIGUOUS→flag | A: pipeline-ordering rule (researcher→architect→planner→coder). Mostly Pack-Chat sequencing (STAY-INLINE), but an architect must know "I run AFTER researcher, not before." B=NO. If spawn-relevant → TAG-ONLY. See §5 flag F2. | L243-250 |
| 18 | Planner output → user review → coder spawn | —/— | STAY-INLINE | A=NO: Pack-Chat gate (planner-to-coder approval); orchestration, never pasted. | L251-257 |
| 19 | Pack-coder PREFLIGHT + STOP-MEANS-STOP pattern | R/r | ALREADY-DONE | split | slug `preflight-stop-means-stop` |
| 20 | Agent prompt enumerates ALL applicable rules inline | —/— | **SPLIT** (pre-decided S1) | A=YES (binds Pack Chat at every spawn; the meta-rule). B=YES (BD-195 Why-body + 6-section recipe). New slug `enumerate-rules-inline`. | S1 doc §3; L268-302 (35 lines) |
| 21 | Agent output requires Rules-Applied Verification Block | R/r | ALREADY-DONE | split | slug `rules-applied-verification-block` |
| 22 | Architect/planner state-claims require Empirical-Evidence Blocks | R/r | ALREADY-DONE | split | slug `empirical-evidence-blocks` |
| 23 | CI guard design — measure-then-bound | R/r | ALREADY-DONE | split | slug `ci-guard-measure-then-bound` |

### 3.3 `### Sub-agent behavior (Claude-only)` (4 bullets)

| # | Bullet | Tag-state | Class | Rationale (Test A / Test B) | Evidence |
|---|---|---|---|---|---|
| 24 | Sub-agent worktree isolation (opt-in; BD-197 replaced the prior bug-era prohibition) | —/— | STAY-INLINE | A=NO: Pack-Chat Agent-tool invocation parameter (Pack Chat sets `isolation`); the spawned agent does not apply it. Claude-only (trinity-exempt). | `### Sub-agent behavior (Claude-only)` worktree bullet (line numbers drift) |
| 25 | Default sub-agent spawns to background | —/— | STAY-INLINE | A=NO: Pack-Chat `run_in_background` parameter choice; orchestration. Claude-only. | L358-366 |
| 26 | Agent-team stage lifecycle + per-commit fresh-coder | —/— | STAY-INLINE | A=NO: Pack-Chat lifecycle management (spawn/close/respawn); orchestration. Claude-only. | L367-378 |
| 27 | Trinity exemption | —/— | STAY-INLINE | A=NO: a META-note explaining why §3.3 is Claude-only; not a rule at all, a documentation note. | L379-383 |

### 3.4 `### Pack Chat scope` (6 bullets)

| # | Bullet | Tag-state | Class | Rationale (Test A / Test B) | Evidence |
|---|---|---|---|---|---|
| 28 | Pack Chat does NO fixes | —/— | STAY-INLINE | A=NO: defines Pack-Chat's own role boundary (Pack Chat does not Edit/Write fixes); orchestration. | L387-397 |
| 29 | What Pack Chat CAN edit directly | —/— | STAY-INLINE | A=NO: enumerates Pack-Chat write-authority (memory/PM-only files); pure Pack-Chat data, not an agent rule. | L399-410 |
| 30 | Commit-approval requests include next-steps plan | —/— | STAY-INLINE | A=NO: Pack-Chat user-facing commit-approval format; orchestration. | L411-424 |
| 31 | Pack-architect spawn protocol | —/— | STAY-INLINE | A=NO: Pack-Chat decision rule (when to spawn architect + needs user approval); orchestration. | L425-436 |
| 32 | Batch-scope claims are enforced by CI, not honor system | —/— | STAY-INLINE | A=NO: Pack-Chat commit-subject framing rule (CI Check 36). Pack Chat writes commit subjects, not agents. | L437-447 |
| 33 | Pack Chat NO coder review; bounded reviewer/fix cycle | —/— | **SPLIT** (pre-decided S1) | A=YES (binds Pack Chat per commit; agents need the cycle-context when spawned). B=YES (BD-195 Why-body + 7-step procedure + escalation contract). New slug `bounded-review-fix-cycle`. | S1 doc §3; L449-514 (66 lines) |

### 3.5 `### Repo conventions` (12 bullets)

| # | Bullet | Tag-state | Class | Rationale (Test A / Test B) | Evidence |
|---|---|---|---|---|---|
| 34 | Per-entry trees vs mirrors — mode-dependent source of truth | R/— | ALREADY-TAG-ONLY | A=YES, B=NO (the §5.1(ii) named example). Already correct. | `[roles: universal]`, no rationale; named at GUARDRAILS L146 |
| 35 | `pack-ops/BACKLOG.md` has no Resolved section | —/— | TAG-ONLY (add `[roles:]`) | A=YES (a coder/architect editing BACKLOG must obey the resolve-in-place form). B=NO (self-contained, no Why-body). MISSING `[roles:]` → add `[roles: universal]`. See §5 flag F3 (borderline — mostly Pack-Chat-side). | L534-536 |
| 36 | Separate pack ops from pack product | R/— | ALREADY-TAG-ONLY | A=YES, B=NO (the §5.1(ii) named example). Already correct. | `[roles: universal]`, no rationale; named at GUARDRAILS L146 |
| 37 | Project-side concepts on pack-side surfaces — deliverable-only | R/r | ALREADY-DONE | split | slug `pack-side-project-concepts-deliverable-only` |
| 38 | Enumerate ENCODING surfaces in pack-side audits | R/r | ALREADY-DONE | split | slug `enumerate-encoding-surfaces` |
| 39 | Test infra is self-provisioned | R/— | ALREADY-TAG-ONLY | A=YES, B=NO (the §5.1(ii) named example). Already correct. | `[roles: universal]`, no rationale; named at GUARDRAILS L146 |
| 40 | Skill and agent maintenance is mechanical by default | R/r | ALREADY-DONE | split | slug `skill-agent-maintenance-mechanical` |
| 41 | Pack-repo code-comment deferrals | R/r | ALREADY-DONE | split | slug `pack-repo-code-comment-deferrals` |
| 42 | Filename uniqueness heuristic | R/r | ALREADY-DONE | split | slug `filename-uniqueness-heuristic` |
| 43 | Architect-doc-vs-reality reconciliation | R/r | ALREADY-DONE | split | slug `architect-doc-reality-reconciliation` |
| 44 | Regenerate test-fixtures/manifest.txt on every v11-surface commit | R/r | ALREADY-DONE | split | slug `regenerate-manifest-v11-surface` |
| 45 | Cross-CLI reference normalization in `project-template/` trinity | R/r | ALREADY-DONE | split | slug `cross-cli-reference-normalization` |

### 3.6 `### Project goals (v11)` (2 plain bullets)

| # | Bullet | Tag-state | Class | Rationale | Evidence |
|---|---|---|---|---|---|
| 46 | Pack tracker opt-in works with little/no user intervention | n/a | STAY-INLINE | NOT a rule — a project GOAL statement (aspirational scope, not an obeyable imperative). Tagging a goal is a category error. | L606-607 |
| 47 | OT-style v10→v11 migration is automated; OT read-only for testing | n/a | STAY-INLINE | NOT a rule — project goal. (The "OT read-only" half overlaps the spawn-relevant `test-infra-self-provisioned` rule #39, which already carries the obeyable form; this bullet is the goal, not the rule.) | L608-609 |

---

## 4. Resulting counts + bijection delta

> **Empirical-Evidence Block EE-3 — classification tally.**
> - Method: count each classification from the §3 table. HEAD `1da5376`, 2026-05-31.
> - Output:
>   - **ALREADY-DONE (split):** 18 (rows 1,5,6,7,8,12,19,21,22,23,37,38,40,41,42,43,44,45). Matches Check 45 bijection (EE-2).
>   - **ALREADY-TAG-ONLY (correct):** 3 (rows 34,36,39 — the §5.1(ii) named examples).
>   - **SPLIT (new work):** 2 (rows 20,33 — the S1 pre-decided rules). NO other bullet qualifies for SPLIT (no other untagged bullet is both spawn-relevant AND carries a separable Why-body).
>   - **TAG-ONLY (new work — add `[roles:]`, no rationale):** 1 (row 35 — borderline, flag F3) + the 2 AMBIGUOUS-if-spawn-relevant (rows 14,17) which become TAG-ONLY ONLY if the user rules them spawn-relevant.
>   - **STAY-INLINE:** 21 of the `- **` bullets (rows 2,3,4,9,10,11,13,15,16,18,24,25,26,27,28,29,30,31,32) + rows 14,17 if user rules them orchestration + the 2 Project-goals bullets (46,47).
> - Interpretation: of 24 untagged `- **` bullets, only **2 are clearly SPLIT** (the S1 pair), **1 is a TAG-ONLY fix** (row 35), **2 are AMBIGUOUS** (rows 14,17), and **19 are clearly STAY-INLINE orchestration**. The corpus is overwhelmingly correctly classified already; the reconciliation surfaces a SMALL, principled delta — not a mass re-tagging.
> - Conclusion: **SUPPORTED.** The point is confirmed: do NOT over-split. 19/24 untagged bullets are legitimately untagged orchestration.

**Bijection delta:** 18 → **20** (the 2 SPLIT rules add one slug each to both corpus and rationale sides; TAG-ONLY additions carry NO `[rationale:]`, so they do NOT touch the bijection). Check 45 target = 20==20.

**Definitive count (excluding the 2 user-judgment AMBIGUOUS rows):**
| Class | Count | Action |
|---|---|---|
| ALREADY-DONE | 18 | none |
| ALREADY-TAG-ONLY | 3 | none |
| SPLIT | 2 | new slug + body→rationale + `[roles:]` |
| TAG-ONLY (new) | 1 | add `[roles: universal]` only |
| STAY-INLINE | 21 `- **` + 2 goals | none |
| AMBIGUOUS (user decides) | 2 | TAG-ONLY if spawn-relevant, else STAY-INLINE |

---

## 5. AMBIGUOUS bullets flagged for user judgment

These three are flagged rather than forced (per "flag genuinely ambiguous rather than force"):

- **F1 — row 14 "Agent prompt requirements."** It is a prompt-AUTHORING contract. Pack Chat applies it when constructing prompts (→ STAY-INLINE, like rows 15/16). BUT an architect/reviewer also verifies prompts meet it. RECOMMENDATION: **STAY-INLINE** — it governs Pack-Chat prompt CONSTRUCTION, and rows 15/16 (sibling prompt-construction rules) are uncontroversially STAY-INLINE; consistency favors grouping all three as Pack-Chat-construction orchestration. User may override to TAG-ONLY if they want it pasted into reviewer spawns.
- **F2 — row 17 "Researcher-first pipeline."** Pipeline ORDERING is Pack-Chat sequencing (→ STAY-INLINE), but it contains one agent-facing clause ("Architect runs AFTER researcher, not before, not skipped"). RECOMMENDATION: **STAY-INLINE** — the ordering decision is Pack Chat's; the architect does not self-sequence. If the user wants architects to self-check "was a researcher run before me?", reclassify TAG-ONLY (`[roles: architect]`).
- **F3 — row 35 "`pack-ops/BACKLOG.md` has no Resolved section."** Spawn-relevance is weak: BACKLOG.md is PM-only (Pack-Chat-direct), so an AGENT rarely edits it — but a coder scoped into a per-entry tree could. RECOMMENDATION: **TAG-ONLY `[roles: universal]`** for completeness (it IS an obeyable form-rule, B=NO so no rationale needed), OR leave STAY-INLINE if the user treats BACKLOG hygiene as purely Pack-Chat. Low stakes either way (no bijection impact; no body move).

If the user accepts all three RECOMMENDATIONS, the new work reduces to: **2 SPLIT + 1 TAG-ONLY** (F3 to TAG-ONLY), with F1/F2 staying inline.

---

## 6. Mechanical implementation strategy (ONE trinity-lock-step commit)

A coder applies this in a SINGLE commit (trinity lock-step across `CLAUDE.md`/`AGENTS.md`/`GEMINI.md` + the rationale doc). Follows the §12 rule-change propagation procedure.

**Step 1 — SPLIT the 2 rules (rows 20, 33)** — exactly per `ARCHITECTURE-BD-196-S1-RULE-BODY-TREATMENT.md` §4:
- Row 20 → two-clause imperative + `[roles: universal] [rationale: enumerate-rules-inline]`; move Why + 6-section recipe to a new `## enumerate-rules-inline` section in `PACK-MEMORY-RATIONALE.md`.
- Row 33 → two-clause imperative + `[roles: universal] [rationale: bounded-review-fix-cycle]`; move Why + 7-step Cycle + escalation contract + Final-reviewer-note + progress-marker examples to a new `## bounded-review-fix-cycle` section.
- Both new sections inserted in corpus order; edit-in-place (do NOT rewrite the rationale file); re-confirm section map after edit.

**Step 2 — TAG-ONLY the approved bullets (NO body move, NO rationale section):**
- Row 35 (if user approves F3) → append `[roles: universal]` to the bullet's last line. Imperative text unchanged.
- Rows 14 / 17 → ONLY if the user reclassifies them TAG-ONLY: append `[roles: …]` (14: `[roles: universal]`; 17: `[roles: architect]`). Default = no change (STAY-INLINE).
- Trinity lock-step: the same `[roles:]` append lands in all three trinity files.

**Step 3 — STAY-INLINE:** 19 `- **` bullets + 2 goals — NO change. (Explicitly: do NOT tag them. They are orchestration / goals.)

**Step 4 — Verify bijection:** after Step 1, corpus = 20 `[rationale: slug]`; rationale doc = 20 `## <slug>`. `python3 scripts/validate-pack.py` → Check 45 "20 … 20 … equal". (TAG-ONLY additions in Step 2 carry no `[rationale:]`, so do not affect Check 45.)

**Step 5 — Blast-radius sweep (7b):** grep the repo (excl. `prison/`, `archive/`) for inbound cites of the 2 split rules' old inline bodies; repoint to the new `[rationale: slug]`. Update `pack-ops/.spawn-rule-manifest.txt` rows if present (§9.6 reference-resolution).

**Step 6 — Manifest regen:** the commit touches `pack-ops/PACK-MEMORY-RATIONALE.md` (v11-surface). Run `bash test-fixtures/build.sh --all --clean`; stage `test-fixtures/manifest.txt` if diff non-empty (likely empty — RATIONALE.md not client-installed). Pack-root trinity files are NOT v11-surface.

**Step 7 — Per-check tests:** run `scripts/tests/test-validate-pack-check-45.sh` + trinity-parity check tests. ALL green before PREFLIGHT.

**Working-state invariant:** validator green at commit boundary; Steps 1+2 land together so the bijection never sees a half-applied state.

---

## 7. Blast radius

| Surface | Delta | Mechanism |
|---|---|---|
| Trinity `## Pack memory` ×3 | 2 bodies removed (~101 lines/file → ~22) + 0-to-3 `[roles:]` appends (rows 35 + maybe 14/17). Trinity lock-step. | Trinity-parity Checks 16/18/19 (assert structure, not tag content — stay green). |
| `pack-ops/PACK-MEMORY-RATIONALE.md` | +2 `## <slug>` sections (~134 lines). | Edit-in-place insert. |
| Check 45 bijection | 18 → 20 both sides. | Data-driven; no code change. |
| `pack-ops/.spawn-rule-manifest.txt` | Possible 2-row update. | §9.6 reference-resolution. |
| `test-fixtures/manifest.txt` | Regen mandated; diff likely empty. | manifest-regen-v11-surface. |
| CI gate | NONE forces this (Check 44/M4 does not scan the trinity — S1 EE-5). Tree green before/after. | — |

No project-side surface, client-installed file, migrator, or agent definition touched. Pure pack-ops + pack-root-trinity.

---

## 8. Rules-Applied Verification Block

| Rule (Rules-in-force) | Verification evidence | Conclusion |
|---|---|---|
| Architect/planner state-claims require Empirical-Evidence Blocks | EE-1 (tag-state distribution: 18/3/24 + the §5.1(ii) named-example confirmation), EE-2 (bijection=18), EE-3 (classification tally) — each with command + verbatim output + HEAD `1da5376` + 2026-05-31 + SUPPORTED. | COMPLIANT |
| Pattern-matching out of context is an anti-pattern | §1 applies a TWO-test contract (spawn-relevance × separable-body) per-bullet; §4/EE-3 explicitly confirm 19/24 untagged bullets stay STAY-INLINE — only 2 SPLIT + 1 TAG-ONLY result. No reflexive splitting; the §3 table records a per-bullet rationale. | COMPLIANT |
| Preliminary triage + architect-challenge discipline | The "split the un-split rules like the rest" instinct is challenged: most untagged bullets are correctly untagged orchestration. 3 genuinely ambiguous bullets (F1/F2/F3) are FLAGGED for user judgment, not forced. HIGH bar (boundary-with-existing-design) cleared by the §5.1 two-test contract. | COMPLIANT |
| Skill/agent + rule maintenance: structural changes escalate | Top-matter marks STRUCTURAL; §6 states a coder applies AFTER user approval; architect does not implement. | COMPLIANT |
| Trinity + bijection awareness | §4 bijection delta 18→20 (only SPLIT touches it; TAG-ONLY does not); §7 quantifies trinity lock-step + manifest + spawn-manifest blast radius. | COMPLIANT |
| Agent output requires Rules-Applied Verification Block | This table. | COMPLIANT |
| Agents never commit / no destructive ops | Read-only commands only (`awk`/`grep`/`sed -n`/`wc`/`git`/`python3 validate-pack.py`); sole Write = this doc at caller-specified path; no git state change; `prison/` not read. | COMPLIANT |

**End of ARCHITECTURE-BD-196-S1-CORPUS-CLASSIFICATION.md.**
