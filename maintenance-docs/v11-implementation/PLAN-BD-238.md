# PLAN-BD-238 — coder-ready implementation plan: PACK-SIDE large-BD pipeline standard (size-tiered)

**Role:** pack-planner (RO). FRESH independent planner. **BD:** BD-238 (LARGE — user-confirmed 2026-06-23; runs the full pipeline; THIS plan goes through an adversarial planner review next). **Primary input (sequence, do NOT redesign):** `DESIGN-BD-238-RECONCILED.md`. **Necessity verdict applied:** `DESIGN-BD-238-PARITY-CHECK.md` (parity CI check NOT NECESSARY — DROPPED entirely). **Output:** this plan only (sole Write, under `/tmp`). **Next stage:** adversarial planner review → user planner-to-coder gate → coder.

---

## 0. Runtime regime (RO; verified)

| Field | Value |
|---|---|
| `pwd` | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev` |
| `git rev-parse HEAD` | `e8ba9e7a4d1d3ea33ac3d4320d0aee77bf973381` (= expected `e8ba9e7`) |
| branch | `v11-dev` |
| `git status --short` | clean (no uncommitted work) |
| graph | DISCOVERY queried (`graphify query`); operating-doc rule bodies + check algorithms are NOT node-indexed at rule granularity (the graph returns agent-def fixtures, not the propagation procedure) → grep/Read for VERIFICATION (G2 fallback, sanctioned for exact-bytes/algorithm reads). |
| writes | EXACTLY ONE: this plan doc. No source edits. Read-only git only. No memory store read/written (user MEMORY PROHIBITION 2026-06-23 honored). |

**Re-verification at live HEAD (`e8ba9e7`):** the reconciled design measured anchors at `6707862`/`67078627`. I re-confirmed every load-bearing anchor at the live HEAD; ALL match (EB-P1…EB-P4 below). The plan is anchored to the live tree, not a stale measurement.

---

## 1. Goal + BD items addressed

**Goal:** codify the PACK-SIDE large-BD development flow as ONE official, size-tiered standard in the in-repo SSOT (trinity `## Pack memory`), with the two adversarial reviews + reconciliation as the MINIMUM for a LARGE BD and OPTIONAL (user-elective) for a SMALL BD; reconcile the two out-of-repo adversarial memories to point at the in-repo standard (trinity-wins); leave `validate-pack` green at the push end-state.

**BD in scope:** BD-238 (the sole entry). Acceptance criteria (from `backlog/BD-238.md` L29) decomposed → plan coverage:

| BD-238 acceptance clause | Plan section |
|---|---|
| pipeline documented as ONE official size-tiered standard (full chain incl. optional internal/external/both researcher first step + large/small criterion + adversarial-as-minimum-for-large / optional-for-small + reconciliation + parallel coder waves off the rule-10 map) | §3 C1 rule body (verbatim §4.1 design) |
| lives in in-repo SSOT (trinity `## Pack memory` + full propagation surfaces), not just out-of-repo memory | §4 propagation set (MANDATORY + ELECTIVE) |
| the two existing adversarial memories reconciled to point at the in-repo standard (no contradiction, trinity-wins) | §5 C2 (out-of-repo upkeep) |
| no conflict with researcher-first / spawn-protocol / planner-to-coder / worktree-isolation rules | design §8 (carried; no plan action — coexistence by reference, not override) |
| `validate-pack` green (bijection, anti-restate, trinity parity, manifest) | §6 verification plan |
| architect-designed (not Pack-Chat-authored) | satisfied — design pipeline ran (architect → adversarial → reconciliation → THIS planner) |

**Out of scope (explicitly):** a pack-root `## Pack memory` body-parity CI check — DROPPED entirely on measure-then-bound evidence (DESIGN-BD-238-PARITY-CHECK §1-§3); NOT deferred, NO follow-up BD. Registry count STAYS 69. See §7 (disposition edit) + §8 (risks).

---

## 2. Affected files — complete enumeration (enumerate-encoding-surfaces)

Every surface the plan touches + every verification gate. A missed surface is a plan gap.

### 2.1 C1 — the standard (one pack-coder commit, one worktree)

| # | File | Edit | Mandatory? | Gate |
|---|---|---|---|---|
| 1 | `CLAUDE.md` | insert §4.1 umbrella bullet after `Researcher-first pipeline` (L288), before `Planner output` (L296) | **MANDATORY** | Check 45 (CLAUDE.md corpus slug), Check 66 (1289<1300), Check 18 (H2 — unaffected), SAFEGUARD-1/-2 |
| 2 | `AGENTS.md` | insert the SAME byte-identical bullet after `Researcher-first` (L277), before `Planner output` (L285) | **MANDATORY** | trinity-rule byte-parity, SAFEGUARD-1/-2 |
| 3 | `GEMINI.md` | insert the SAME byte-identical bullet after `Researcher-first` (L249), before `Planner output` (L257) | **MANDATORY** | trinity-rule byte-parity, SAFEGUARD-1/-2 |
| 4 | `pack-ops/PACK-MEMORY-RATIONALE.md` | add `## large-bd-pipeline-standard` section (Why / How / Rejected alternative; model on `## reconciliation-instance-independence` at L659), INCLUDING the NIT-3 boundary sentence | **MANDATORY** | Check 45 bijection (slug-set equality vs CLAUDE.md), Check 66 (any `- ` sub-bullet ≤1300) |
| 5 | `pack-ops/.spawn-rule-manifest.txt` | add ONE record (slug/canonical/corpus/references) | **ELECTIVE** (recommended — §4.3) | Check 46 reference-resolution (only if added) |
| 6 | `pack-ops/PACK-AGENTS.md` | add the ONE-LINE reference under § "## Pack agents" (L8 section) | **ELECTIVE** (recommended) | Check 46 reference-resolution + anti-restate |
| 7 | `pack-ops/PACK-CHAT.md` | add the ANCHOR sub-paragraph under § "In-session sub-agent spawn + merge-back (worktree isolation)" (L228) | **ELECTIVE** (recommended) | Check 46 reference-resolution + anti-restate |

### 2.2 C3 — audit-doc preservation (paired pack-only commit, immediately after C1)

| File-move | From | To |
|---|---|---|
| design + review + plan + coder/reviewer docs | `/tmp/pack-handoff-bd238-arch/` + `/tmp/pack-handoff-bd238-plan/` + the C1 coder/reviewer handoff dirs | `maintenance-docs/v11-implementation/` |

Exact set named in §5.

### 2.3 C2 — out-of-repo memory reconciliation (Pack-Chat upkeep — NOT a coder commit)

| File (out-of-repo; no validator) | Edit |
|---|---|
| `…/memory/feedback_adversarial_architect_review_on_major_gap.md` | prepend SUBORDINATE pointer (§5) |
| `…/memory/feedback_adversarial_planner_review_major_plans.md` | prepend SUBORDINATE pointer (§5) |
| `…/memory/MEMORY.md` index entries (Design discipline) | update the two one-line pointers |

### 2.4 Surfaces explicitly NOT touched (with evidence — design §5.1)

- **Pack agent defs** (`.claude`/`.codex`/`.agents-plugin` `pack-{architect,coder,docs-researcher,planner,reviewer}.md`) — grep-zero for pipeline-stage vocab; adding a pointer = 15 parity edits + Check 52 re-verify for marginal value. DO NOT touch.
- **Pack skills** (11 ×3 mirrors) — the 4 spawn-relevant skills (`commit-discipline`, `review`, `planning`, `implementation-report`) are anti-restate TARGETS (Check 46); they MUST NOT receive the canonical body. DO NOT touch.
- **`pack-ops/DRY-RUN-MIGRATION.md` + `MERGE-STRATEGY.md`** — their "reconciliation" hits are migrator file-merge state, not the pipeline. DO NOT touch.
- **`test-fixtures/manifest.txt`** — NO fixture input changes (trinity + pack-ops docs only; no `scripts/` change). Push-time `manifest-sync.sh` is a NOOP. The coder does NOT touch the manifest (§6.5).
- **`scripts/validate-pack.py` + check tests + registry count** — NO new check (parity check DROPPED). Count STAYS 69. NO lock-step churn.

---

## 3. C1 — the standard: file-by-file edits with exact anchors

**Commit subject (proposed):** `feat: v11 — BD-238 codify large-BD pipeline standard (pack-only)`. The `pack-only` Check-36 keyword is CORRECT (no `project-template/` touch — §6.4).

### 3.1 Edit 1-3: the umbrella bullet, byte-identical ×3 (corpus)

**Anchor (text anchors, re-confirmed at live HEAD — EB-P1):** insert the new bullet as a standalone top-level `- ` bullet IMMEDIATELY AFTER the `Researcher-first pipeline for substantive content` bullet's last continuation line and IMMEDIATELY BEFORE the `Planner output → user review → coder spawn` bullet, in each file:

| File | After (Researcher-first) | Before (Planner-output) |
|---|---|---|
| `CLAUDE.md` | L288 | L296 |
| `AGENTS.md` | L277 | L285 |
| `GEMINI.md` | L249 | L257 |

This keeps the chain in pipeline reading order (researcher → [new umbrella] → planner-to-coder gate) and adds NO `## ` heading (Check 18 unaffected — EB-P2).

**Exact rule body (byte-identical ×3; 1289 chars whitespace-collapsed < 1300 — EB-P3; DO NOT re-word — this is the design's canonical body):**

```
- **Large-BD pipeline standard (size-tiered).** Pack-side BD development
  runs ONE official pipeline: optional researcher(s) (internal census and/or
  external docs verification, per-need) → architect → adversarial architect
  review → [reconciliation if NEEDS-REWORK] → user design review → planner →
  adversarial planner review → [reconciliation if NEEDS-REWORK] → user
  planner-to-coder gate → parallel worktree coder waves (off the rule-10 map;
  each commit's bounded review/fix cycle in its worktree; patches applied
  sequentially under the conflict protocol; superseded docs deleted; audit set
  preserved). Size signals: launch-gate / cross-surface (≥2 families) /
  blast-radius (≥3 encoding surfaces or a required census) / structural (a NEW
  convention, NEW/changed CI check, tree shape, migration, or a NEW rule). A BD
  is LARGE — the two adversarial reviews + reconciliation the MINIMUM — if
  launch-gate fires OR ≥2 signals fire; else the base flow (researcher →
  architect → planner → coder + the bounded cycle), adversarial passes OPTIONAL
  at user election (one non-launch signal alone — e.g. a single-clause amend to
  an existing rule — does NOT mandate them). When in doubt, LARGE. Each stage
  obeys its own `## Pack memory` rule.
  `[roles: universal] [rationale: large-bd-pipeline-standard]`
```

**Coder authoring discipline:**
- The body uses 2-space-indented continuation lines so `_check_66_iter_bullets` joins it as ONE bullet. Preserve the indentation exactly.
- The en-dash arrows (`→`), em-dashes (`—`), and `≥` are UTF-8 literals — copy them byte-for-byte; do not ASCII-substitute (a substitution breaks byte-parity AND changes the char count).
- `[roles: universal]` + `[rationale: large-bd-pipeline-standard]` are the controlled-vocab + bijection tags. The `[rationale:]` slug `large-bd-pipeline-standard` is the bijection key (Check 45) and the rationale-section heading (Edit 4) MUST match it exactly.
- This is the SOLE semantic content; ZERO history/provenance/dates (operating-docs-no-history-no-bloat).

### 3.2 Edit 4: `pack-ops/PACK-MEMORY-RATIONALE.md` rationale section (MANDATORY)

**Anchor:** add a new `## large-bd-pipeline-standard` section. Model its shape (Why / How / Rejected alternative) on the existing `## reconciliation-instance-independence` section (L659 — EB-P4). Place it in slug order consistent with the file's existing ordering convention; the coder reads the surrounding sections to match placement style (the bijection is set-equality, NOT order-sensitive, so any in-file position is Check-45-valid).

**Content requirements (the coder authors the prose; these are the REQUIRED elements):**
- **Why:** the rigorous large-BD flow ran in practice (worked precedent) but was scatter-documented / out-of-repo-only; codifying ONE size-tiered standard lets a fresh session/agent rely on it.
- **How:** the chain (optional researcher(s) → architect → adversarial architect → [reconciliation] → user design review → planner → adversarial planner → [reconciliation] → user planner-to-coder gate → parallel worktree coder waves off the rule-10 map); the size-tiering test (launch-gate-alone OR ≥2 signals ⇒ LARGE-mandatory-adversarial; else base flow, adversarial optional at user election; when-in-doubt-LARGE tie-break); the four signals (L1 launch-gate / L2 cross-surface ≥2 families / L3 blast-radius ≥3 encoding surfaces or required census / L4 structural — NEW convention/check/tree/migration/rule, NOT a single-clause amend); the "additional rounds on larger gaps" escalation detail (relocated here from the rule body to keep the body under the Check-66 cap).
- **Rejected alternative:** re-tagging the three existing untagged pipeline rules (researcher-first, pack-architect-spawn, planner-to-coder) — rejected as scope creep (forces new bijection rows + rationale sections for rules that already work untagged); the umbrella REFERENCES them by category instead.
- **NIT-3 boundary sentence (REQUIRED, verbatim intent):** "The umbrella NAMES the adversarial stages; `reconciliation-instance-independence` governs the fresh-instance reconciliation that follows a NEEDS-REWORK verdict — complementary, not overlapping."

**Check-66 discipline:** the Why/How/Rejected paragraphs are PROSE (not `- ` bullets, so uncapped), but any `- ` sub-bullet inside the section MUST stay ≤1300 chars.

### 3.3 Edit 5: `pack-ops/.spawn-rule-manifest.txt` record (ELECTIVE — recommended; §4.3)

**Anchor:** append a new record matching the file's existing record shape. Content:
```
slug: large-bd-pipeline-standard
canonical: ## Pack memory
corpus: ### Agent invocation rules — "Large-BD pipeline standard (size-tiered)"
references: PACK-AGENTS.md § "Pack agents"; PACK-CHAT.md § "In-session sub-agent spawn + merge-back"
```
The coder reads an existing record (e.g. the 7 present slugs) to match the exact field syntax/whitespace.

**INCLUDE-vs-DROP decision (planner): INCLUDE.** The pipeline ORDER genuinely lives in PACK-AGENTS (the roster) + PACK-CHAT (the execution half); a manifest record + the two references aid a fresh session's discoverability of the standard's two halves. The design "leans include" (§5 minimal-vs-recommended). The cost is bounded (one record + two one-liners, all Check-46-clean per EB-P5), and the discoverability payoff is real (the standard spans DESIGN-half = trinity rule + EXECUTION-half = PACK-CHAT.md). If C1 must be minimized for any reason, rows 5-7 may be dropped and validate-pack stays green (rows 1-4 are the minimal-green footprint) — but the RECOMMENDED footprint is rows 1-7.

### 3.4 Edit 6: `pack-ops/PACK-AGENTS.md` one-line reference (ELECTIVE — recommended)

**Anchor:** under § "## Pack agents" (L8), beneath the roster or in its lead-in. **Text (one line; a pointer, NOT a body restatement):**
```
The order these agents run in is the large-BD pipeline standard — see
trinity `## Pack memory` `[rationale: large-bd-pipeline-standard]`.
```

### 3.5 Edit 7: `pack-ops/PACK-CHAT.md` anchor sub-paragraph (ELECTIVE — recommended)

**Anchor:** insert a sub-paragraph IMMEDIATELY UNDER the H2 `## In-session sub-agent spawn + merge-back (worktree isolation)` (L228), BEFORE the existing intro paragraph. **Text (a reference, NOT a verbatim body restatement):**
```
This section is the EXECUTION half of the large-BD pipeline standard
(trinity `## Pack memory` `[rationale: large-bd-pipeline-standard]`): it is
the orchestration the standard's step 8 (parallel worktree coder waves)
runs. The DESIGN half (researcher → architect → adversarial → reconciliation
→ planner → adversarial → user gates) is the trinity rule chain.
```

Both §3.4 + §3.5 are anti-restate-safe (a pointer/paraphrase, never a 60+-char existing-body window — verified EB-P5).

---

## 4. Propagation set — MANDATORY vs ELECTIVE (footprints)

Governed by `pack-ops/PACK-CHAT.md` § "Keeping CLAUDE.md, AGENTS.md, GEMINI.md, and PACK-AGENTS.md current" (L465; the 6-row procedure).

### 4.1 The split (design §5, EB-R4 carried; re-confirmed EB-P6)

| Surface | Mandatory? | Gating check | Why |
|---|---|---|---|
| Corpus ×3 trinity (Edits 1-3) | **MANDATORY** | Check 45 (CLAUDE.md corpus slug must map), Check 66 (1289<1300), Check 18 (H2 — auto-satisfied) | a new tagged rule's corpus slug must exist |
| `PACK-MEMORY-RATIONALE.md` section (Edit 4) | **MANDATORY** | Check 45 bidirectional bijection (orphan corpus slug OR orphan rationale heading ⇒ FAIL) | Check 45 is bidirectional — the tagged slug REQUIRES a rationale section |
| `.spawn-rule-manifest.txt` record (Edit 5) | **ELECTIVE** | Check 46 (validates only records that EXIST; does NOT require a record per tagged rule — 7 of 29 tagged rules have one) | discoverability |
| 2 reference one-liners (Edits 6-7) | **ELECTIVE** | Check 46 reference-resolution + anti-restate | discoverability; only required IF Edit 5 names them |
| out-of-repo memory pointers (C2) | N/A (no validator; trinity-wins) | none | acceptance-criteria reconciliation |
| `test-fixtures/manifest.txt` | NOT a propagation step | CI `build.sh --verify` + Check 62 (push-time) | no fixture input changed |

### 4.2 The two footprints

- **MINIMAL GREEN footprint = Edits 1-4 only** (corpus ×3 + rationale section). validate-pack passes at the push end-state with just these.
- **RECOMMENDED footprint = Edits 1-7** (adds the manifest record + two references). This is the planner's recommendation (§3.3 rationale). Either footprint is green; the user/adversarial-reviewer may elect the minimal one.

### 4.3 Manifest-slug decision (carried forward): ONE new umbrella slug, NOT re-tagging the three untagged rules

The three existing pipeline rules (researcher-first, pack-architect-spawn, planner-to-coder) carry NO `[rationale:]` tag today. Re-tagging them would force new bijection rows + rationale sections for rules that already work untagged — scope creep beyond BD-238's ask. The umbrella slug REFERENCES them by category in its body ("Each stage obeys its own `## Pack memory` rule") without requiring them tagged. **Bound:** exactly ONE new slug, ONE new rationale section, and (electively) ONE manifest record + two reference one-liners.

---

## 5. C2 + C3 — out-of-repo reconciliation and audit-doc preservation

### 5.1 C2 — out-of-repo memory reconciliation (Pack-Chat upkeep; AFTER C1 lands; NOT a coder commit)

This is the BD-238 acceptance-criteria reconciliation of the two existing adversarial memories. It is performed by **Pack-Chat memory upkeep** (Pack Chat's own out-of-repo operating state), NOT by a spawned coder and NOT by any agent's memory tool. No validator gates it; trinity-wins on any conflict. (The planner does NOT read or write these files — the MEMORY PROHIBITION binds the planner; the reconciliation is specified from the design's research census.)

**Locations:**
```
/Users/david/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/
  feedback_adversarial_architect_review_on_major_gap.md
  feedback_adversarial_planner_review_major_plans.md
  MEMORY.md   (index — "Design discipline" entries for the two above)
```

**Edits (prepend a one-line subordination pointer to each body; update the two MEMORY.md index pointers):**
- `feedback_adversarial_architect_review_on_major_gap` → prepend: "SUBORDINATE to the in-repo `large-bd-pipeline-standard` (trinity `## Pack memory`): the adversarial ARCHITECT review is the MINIMUM for a LARGE BD (not only 'on a major gap'). This memory adds the major-gap escalation detail. Trinity wins on any conflict."
- `feedback_adversarial_planner_review_major_plans` → prepend: "SUBORDINATE to the in-repo `large-bd-pipeline-standard`: the adversarial PLANNER review is the MINIMUM for a LARGE BD. This memory adds the major-plan detail. Trinity wins."
- MEMORY.md "Design discipline" index lines for both → note the subordination.

**Why reconcile (not delete):** the standard makes the adversarial passes the large-BD MINIMUM (broader than "situational"); the two memories carry useful ESCALATION detail (when to add MORE rounds) that the terse trinity rule intentionally omits. Pointing them at the standard removes the contradiction while preserving the escalation detail in the reference layer; "trinity wins" redirects a memory-only read back to the SSOT.

### 5.2 C3 — audit-doc preservation (paired pack-only coder commit, immediately after C1)

Per the Report-preservation / Constraint-3 discipline, the BD-238 pipeline's audit set is moved from `/tmp` into `maintenance-docs/v11-implementation/`. This is a paired coder commit (file moves only; disjoint tree from C1).

**Audit set to move (the BD-238 pipeline docs):**
- `/tmp/pack-handoff-bd238-arch/DESIGN-BD-238.md` (first design)
- `/tmp/pack-handoff-bd238-arch/` adversarial architect review doc(s)
- `/tmp/pack-handoff-bd238-arch/DESIGN-BD-238-RECONCILED.md` (the reconciled design)
- `/tmp/pack-handoff-bd238-arch/DESIGN-BD-238-PARITY-CHECK.md` (the necessity verdict)
- `/tmp/pack-handoff-bd238-plan/PLAN-BD-238.md` (this plan)
- the adversarial planner review doc (produced next, after this plan)
- the C1 coder IMPL-REPORT + the C1 reviewer report(s) + any fix-coder reports

**Coder action:** the coder copies (Write, since the source is `/tmp`) each doc into `maintenance-docs/v11-implementation/` preserving its filename (filenames already carry `BD-238` — filename-uniqueness OK). The actual `git mv`/`git rm` of `/tmp` is N/A (`/tmp` is untracked); the canonical-tree edit is the new files under `maintenance-docs/`. Pack Chat stages + commits with user approval (agents-never-commit).

**Commit subject (proposed):** `docs: v11 — BD-238 audit-set preservation → maintenance-docs (pack-only)`.

**Note:** C3 depends ONLY on the docs existing; it does NOT depend on C1's content (different tree). It is scheduled immediately after C1 lands so the audit trail is captured while fresh.

---

## 6. Verification plan

### 6.1 C1 coder PREFLIGHT verification (run inside the C1 worktree, before the IMPL-REPORT)

The C1 coder runs ALL of the following and reports PASS/FAIL; a FAIL halts the IMPL-REPORT (report what went wrong instead):

1. **SAFEGUARD-1 — byte-parity diff ×3 (HARD, NAMED — §6.3 below).** Extract + normalized-diff the new bullet across CLAUDE/AGENTS/GEMINI; 0 differences required.
2. **Anti-restate retarget (MAJOR-1).** Verify the two reference one-liners (Edits 6-7) carry NO 60+-char leading-window of ANY existing `## Pack memory` rule body, against the 6 `_CHECK_46_ANTI_RESTATE_SURFACES` (`pack-ops/PACK-AGENTS.md`, `pack-ops/PACK-CHAT.md`, `.claude/skills/{commit-discipline,review,planning,implementation-report}/SKILL.md`). The practical check is running validate-pack Check 46 (it does exactly this); the safe shape is `<name> — see trinity \`## Pack memory\` \`[rationale: <slug>]\``.
3. **Check 66 fit.** The umbrella body measures 1289 chars (whitespace-collapsed) < 1300 — no `.bullet-concision-allowlist.txt` record needed. Re-measure if the coder edits the wording (it must NOT — the body is canonical).
4. **Check 45 bijection.** The new corpus slug `large-bd-pipeline-standard` maps to the new `## large-bd-pipeline-standard` rationale heading (bidirectional set-equality).
5. **validate-pack default + deep.** `python3 scripts/validate-pack.py` exit 0 AND `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` exit 0.
6. **Relevant per-check tests:** Check 45 (bijection), Check 18 (H2-parity), Check 46 (anti-restate), Check 66 (concision) — run the `scripts/tests/test-validate-pack-check-{45,18,46,66}.sh` (or the harness's equivalent) and confirm green.
7. **Full battery (verify-full-ci-suite).** Run the FULL validate-pack + the integration test suite the repo's CI runs, not just validate-pack — confirm green before the IMPL-REPORT.

### 6.2 Registry count is UNCHANGED

The parity check is DROPPED. NO new check, NO new per-check test, NO `CHECK_REGISTRY_EXPECTED_COUNT` change. Count STAYS 69 (verified EB-P7). The coder MUST NOT touch `scripts/validate-pack.py`, `CHECK_REGISTRY_EXPECTED_COUNT`, or `scripts/tests/test-validate-pack-check-64.sh`'s `69` literals. If a fix-coder finds itself editing the registry count for BD-238, that is a scope error — halt and surface.

### 6.3 SAFEGUARD-1 — byte-parity verification step (HARD, NAMED — encode verbatim)

> After inserting the §3.1 umbrella bullet into all three trinity files, EXTRACT the new bullet from each of `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` (the `- **Large-BD pipeline standard …**` bullet through its `[rationale:]` tail) and run a normalized `diff` across the three extractions. The step PASSES iff all three are byte-identical (after stripping only trailing whitespace). Any difference HALTS C1 — the coder fixes the divergent file before proceeding. This is a NAMED, REQUIRED plan step, not advisory.

Concrete mechanic the coder may use (read-only; awk/sed/diff, no git state change): extract the bullet block from each file (from the `- **Large-BD pipeline standard` line through the `[rationale: large-bd-pipeline-standard]\`` line inclusive), write each to a `/tmp` scratch file, `diff` pairwise; require 0 diff output ×3.

### 6.4 SAFEGUARD-2 — coder PREFLIGHT ×3-byte-identity attestation (HARD, NAMED — encode verbatim)

> The C1 coder's PREFLIGHT line MUST include an explicit ×3-byte-identity attestation, e.g.: `PREFLIGHT: … the new umbrella bullet is BYTE-IDENTICAL across CLAUDE.md/AGENTS.md/GEMINI.md (verified by extract+diff, 0 differences); body=1289 chars < 1300 (Check 66); leading-window absent from all 6 Check-46 surfaces (anti-restate clean); Check 45 bijection maps large-bd-pipeline-standard ↔ rationale section; validate-pack default + PACK_VALIDATE_DEEP=1 exit 0; full battery green …`. An IMPL-REPORT lacking the ×3-byte-identity attestation is incomplete and is rejected.

The reviewer MUST confirm BOTH safeguards ran: the extract+diff result (SAFEGUARD-1) AND the PREFLIGHT attestation line (SAFEGUARD-2).

### 6.5 Manifest is push-time + a NOOP here (regenerate-manifest-v11-surface)

BD-238 touches NO fixture input — only trinity + pack-ops docs; NO `scripts/` change, NO agent-def/skill FIXTURE change. `test-fixtures/manifest.txt` is regenerated ONLY at push, ONLY when a fixture input changed, by `scripts/manifest-sync.sh` (orchestrator-run before `git push`). For BD-238 it is a NOOP (manifest-sync exits 0, no diff). The coder does NOT touch the manifest; it is not a per-commit chore.

### 6.6 Commit-scope keyword (Check-36) per commit

- **C1:** `pack-only` — touches only trinity (pack-root) + `pack-ops/` docs; NO `project-template/`, NO `supporting-docs/` (design §5.2 disjointness proof; re-confirmed EB-P8). The keyword is verified by Check 36 against the commit's `git diff --name-only`.
- **C3:** `pack-only` — touches only `maintenance-docs/v11-implementation/` (pack-side); NO `project-template/`/`supporting-docs/`.
- **C2:** out-of-repo Pack-Chat upkeep — NO commit, NO keyword.

**Keyword-trap caution (commit-subject keyword-token trap):** the words `pack-only`/`project-only`/`pack-chat-only` are Check-36 claim tokens ANYWHERE in the subject. The proposed subjects use `pack-only` deliberately; do NOT let a denying token (`project-template`) appear in the subject prose.

---

## 7. The §10.1 disposition edit (apply the PARITY-CHECK §5 verdict)

The reconciled design's §10.1 currently routes the pack-root body-parity CI check to "a tracked follow-up BD." The DESIGN-BD-238-PARITY-CHECK §5 verdict OVERRIDES this: the check is **DROPPED entirely (not deferred)**. This plan applies that disposition:

**§10.1 disposition (as it stands in THIS plan — the binding version):**
> A pack-root `## Pack memory` body-parity CI check is DROPPED entirely (NOT deferred) — DESIGN-BD-238-PARITY-CHECK §1-§3 shows a correct check cannot be bounded to the legitimate ×3-divergence set without ADDING discipline surfaces (a hand-maintained per-slug divergence-allowlist), has a structural blind spot on the unslugged consolidated rules, guards a pack-INTERNAL (non-shipping) surface, and covers a zero-current-exposure recoverable risk. NO follow-up BD. Registry count STAYS 69. The trinity-rule discipline + SAFEGUARD-1/-2 (§6.3/§6.4) are the SOLE-and-SUFFICIENT protection (sole because the check is correctly ABSENT, not because it is deferred).

**§10.2 (the two safeguards) STAYS verbatim** — SAFEGUARD-1 + SAFEGUARD-2 are the correct-and-sufficient protection, encoded as HARD NAMED steps in §6.3/§6.4 of this plan.

**This is NOT a deferral** (deferral-is-scope-creep / no-deferral-without-user-direction honored): the check is unnecessary work whose correct form is a net complexity loss; it does not exist, it is not scheduled. No reintroduction anywhere in the plan.

---

## 8. Rule-10 parallel/dependency map + commit sequence

### 8.1 The commits

| Commit | Scope | Same-file overlap | Parallel/serial |
|---|---|---|---|
| **C1** (the standard) | Corpus ×3 trinity (Edits 1-3, MANDATORY) + `PACK-MEMORY-RATIONALE.md` (Edit 4, MANDATORY) + electively `.spawn-rule-manifest.txt` (Edit 5) + `PACK-AGENTS.md` ref (Edit 6) + `PACK-CHAT.md` anchor (Edit 7) | corpus ×3 + rationale form ONE Check-45 bijection unit | **ONE serial coder commit** |
| **C3** (audit-set preservation) | move BD-238 pipeline docs `/tmp` → `maintenance-docs/v11-implementation/` | disjoint tree from C1 | **paired pack-only coder commit, immediately after C1** |
| **C2** (out-of-repo memory reconciliation) | the two Pack-Chat memory files + MEMORY.md index | out-of-repo; no validator; disjoint from tracked files | **Pack-Chat upkeep, AFTER C1 — NOT a coder commit** |

### 8.2 SERIAL verdict + the CORRECTED rationale (my own rule-10 map)

**SERIAL — C1 is a SINGLE serial commit; no parallel coder waves.** One fresh `pack-coder` in one isolated worktree applies all C1 edits; the bounded review/fix cycle (≤2 review/fix pairs + 1 final reviewer) runs IN that worktree; the patch is produced ONLY after review-clean; Pack Chat applies + commits with user approval.

**The binding reason (NOT a CI cadence gate):** CI is `on: push` end-state (`.github/workflows/validate-pack.yml`), NOT per-commit; the propagation procedure states "Order is documented, not gate-sequenced: a commit is atomic; the propagation order is verified by END-STATE checks … not a hard-enforced step sequence" and permits propagation "in the same commit as the structural change, or in the immediately following commit." So a split WITHIN one push would NOT fail CI. What ACTUALLY forces the single serial commit:
- **(a) propagation-atomicity discipline** — the corpus + rationale (the Check-45 bijection unit) stay in the SAME commit so the committed state never carries a half-applied bijection (clean per-commit audit);
- **(b) the trinity rule** mandates the ×3 trinity edit be one byte-identical parallel edit;
- **(c) no disjoint-file concurrency is available** — the corpus + rationale + references are one logical unit best kept atomic.

**Parallel-wave applicability:** NONE. BD-238 is not a multi-disjoint-file-commit effort; there are no concurrent coder waves to schedule. The single C1 commit + the paired C3 doc commit + the out-of-repo C2 upkeep are the whole effort.

**Sequence:** C1 (coder in worktree → bounded review/fix cycle → patch after review-clean → user-approved commit) → C3 (paired pack-only doc commit, includes the adversarial-planner-review + C1 coder/reviewer reports once they exist) → C2 (Pack-Chat memory upkeep). C2 and C3 depend only on C1's slug existing.

**Worktree lifecycle (Claude-only):** the C1 coder is the FIRST (and only) RW coder of the commit → it CREATES the isolated worktree (`isolation:"worktree"`, base `worktree.baseRef:"head"`). Every fix-coder in the C1 cycle REUSES that worktree. Tear down ONLY after C1 is CONFIRMED landed (exit 0); a failed commit KEEPS the worktree as recovery fallback. C3's doc-move coder is a fresh coder (per-commit fresh-coder) — Pack Chat decides its placement per the live-worktree ASK gate if C1's worktree is still live.

---

## 9. Open risks / unknowns (named)

| Risk | Severity | Mitigation in this plan |
|---|---|---|
| **×3 body drift** (the SOLE unguarded surface — no CI net) | HIGH if unmitigated | SAFEGUARD-1 (extract+diff ×3, HALT on diff) + SAFEGUARD-2 (PREFLIGHT attestation) + reviewer-confirms-both (§6.3/§6.4). These ARE the protection (the parity check is correctly absent). |
| **Check 66 over-cap if the coder re-words** | MED | The body is CANONICAL (1289<1300, EB-P3) — the coder MUST copy it verbatim; do NOT re-word. If a future edit pushes over, the design's option (a) (move detail to the rationale section) is preferred over an allowlist record. |
| **Anti-restate trip on a reference one-liner** | LOW | Both one-liners verified clean (EB-P5); the safe shape (`<name> — see trinity …`) is specified. The coder re-runs Check 46 in PREFLIGHT. |
| **Bijection orphan** (corpus slug without rationale section, or vice versa) | MED | Check 45 is bidirectional — Edits 1-3 (corpus) + Edit 4 (rationale) are BOTH mandatory and BOTH in C1. The coder confirms set-equality in PREFLIGHT. |
| **UTF-8 char substitution** (→ — ≥) breaking byte-parity + char count | MED | §3.1 authoring discipline: copy the arrows/dashes/≥ byte-for-byte; SAFEGUARD-1 catches a ×3 divergence. |
| **Stale cross-reference** if Edit 5 names references that Edits 6-7 omit (or vice versa) | LOW | Edits 5-7 are an all-or-nothing ELECTIVE bundle — include all three or none (§3.3); Check 46 reference-resolution catches a record naming a missing reference. |
| **C3 captures an incomplete audit set** (adversarial-planner-review not yet written when C3 runs) | LOW | C3 is scheduled AFTER the adversarial planner review + C1 cycle complete, so all docs exist. The audit set (§5.2) lists every doc explicitly. |
| **MEMORY PROHIBITION boundary** — C2 edits memory files | N/A (not a defect) | The planner does NOT touch memory (prohibition binds the planner). C2 is Pack-Chat upkeep = the BD's acceptance-criteria work, performed by Pack Chat, not a spawned agent's memory tool. |

**No open DESIGN questions.** The reconciled design + parity-check verdict resolve every choice; this plan sequences them. The single include/drop decision (the ELECTIVE bundle) is decided INCLUDE from the design's stated lean + the bounded-cost evidence (§3.3).

---

## 10. Empirical-Evidence Blocks (NEW state-claims beyond the design's)

All measured at HEAD `e8ba9e7a4d1d3ea33ac3d4320d0aee77bf973381`, 2026-06-23, branch `v11-dev`.

**EB-P1 — placement anchors re-confirmed at live HEAD (design measured at 6707862).**
- Command: `grep -n "Researcher-first pipeline\|Planner output → user review" CLAUDE.md AGENTS.md GEMINI.md`
- Output (verbatim): `CLAUDE.md:288 / :296`, `AGENTS.md:277 / :285`, `GEMINI.md:249 / :257`.
- Interpretation: the insert-after-Researcher-first / before-Planner-output anchors are IDENTICAL to the design's measured values at the live HEAD; the section is mid-`### Agent invocation rules` ×3.
- Conclusion: SUPPORTED — the plan's anchors are live-current, not stale.

**EB-P2 — insertion adds NO H2 (Check 18 unaffected).**
- Command: the new bullet (§3.1) is a `- ` top-level bullet inside the existing `### Agent invocation rules` subsection under the existing `## Pack memory` H2 (placement EB-P1).
- Output (verbatim): the body contains no `## ` line; it is one `- ` bullet + 2-space continuations + the `[rationale:]` tail.
- Interpretation: Check 18 (H2 set/order) compares only `line.startswith("## ")`; adding a bullet changes no H2.
- Conclusion: SUPPORTED — Check 18 H2-parity is auto-satisfied ×3.

**EB-P3 — umbrella body char count under the Check-66 cap (re-measured).**
- Command: Python replication of the Check-66 measure (join the `- ` line + 2-space continuations, whitespace-collapse) over the §3.1 body; cap `_CHECK_66_BULLET_CHAR_CAP = 1300` (grep-confirmed at `scripts/validate-pack.py:7989`).
- Output (verbatim): `char_len (whitespace-collapsed): 1289` ; `cap: 1300 -> UNDER`.
- Interpretation: the canonical body is 1289 chars, 11 under the cap; no `.bullet-concision-allowlist.txt` record needed. Reproduces the design's EB-R6 = 1289.
- Conclusion: SUPPORTED — Check 66 fit confirmed at the live HEAD.

**EB-P4 — rationale-section model + bijection target present.**
- Command: `grep -n "^## reconciliation-instance-independence" pack-ops/PACK-MEMORY-RATIONALE.md`
- Output (verbatim): `659:## reconciliation-instance-independence`
- Interpretation: the model section the new `## large-bd-pipeline-standard` section copies its Why/How/Rejected shape from exists at L659.
- Conclusion: SUPPORTED — Edit 4 has a concrete model.

**EB-P5 — the 6 Check-46 surfaces verbatim; the two reference one-liners are anti-restate-safe.**
- Command: `Read scripts/validate-pack.py L7469-7476` (the `_CHECK_46_ANTI_RESTATE_SURFACES` tuple).
- Output (verbatim): `("pack-ops/PACK-AGENTS.md", "pack-ops/PACK-CHAT.md", ".claude/skills/commit-discipline/SKILL.md", ".claude/skills/review/SKILL.md", ".claude/skills/planning/SKILL.md", ".claude/skills/implementation-report/SKILL.md")`. The trinity files are NOT in the tuple.
- Interpretation: Check 46 scans these 6 surfaces for existing-rule-body leading-windows; the two NEW reference one-liners (§3.4/§3.5) land in PACK-AGENTS.md + PACK-CHAT.md (2 of the 6) and use the pointer/paraphrase shape (`<name> — see trinity …`), carrying no 60+-char existing-body window (design EB-R1 measured both CLEAN). The retargeted PREFLIGHT verification re-runs Check 46.
- Conclusion: SUPPORTED — the anti-restate retarget (MAJOR-1) is correct; the one-liners are Check-46-safe; the coder confirms in PREFLIGHT.

**EB-P6 — propagation MANDATORY/ELECTIVE split confirmed (manifest is a curated subset).**
- Command: `grep -c "^slug:" pack-ops/.spawn-rule-manifest.txt`
- Output (verbatim): `7`
- Interpretation: the manifest carries 7 slug records; the rationale file carries 29 `## ` headings (design EB-R4). Check 46 validates only records that exist (it does NOT require a record per tagged rule), so the manifest record + references are ELECTIVE; Check 45 (bidirectional) requires the rationale section, so corpus ×3 + rationale are MANDATORY.
- Conclusion: SUPPORTED — minimal-green = Edits 1-4; recommended = Edits 1-7.

**EB-P7 — registry count is 69 (parity check DROPPED; no churn).**
- Command: `grep -n "CHECK_REGISTRY_EXPECTED_COUNT = " scripts/validate-pack.py | head -3`
- Output (verbatim): `504:CHECK_REGISTRY_EXPECTED_COUNT = 69`
- Interpretation: the count is 69; the parity check is dropped entirely; the plan adds NO check, NO test, NO count change.
- Conclusion: SUPPORTED — count STAYS 69; no lock-step surface churn.

**EB-P8 — BD-238 edit set is PACK-ONLY (no project-template touch — Check-36 keyword).**
- Command: enumeration of the plan's edit set (§2.1-§2.2): `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` (pack-root), `pack-ops/{PACK-MEMORY-RATIONALE.md, .spawn-rule-manifest.txt, PACK-AGENTS.md, PACK-CHAT.md}`, `maintenance-docs/v11-implementation/*` (C3). No path under `project-template/` or `supporting-docs/`.
- Output (verbatim): every C1/C3 path is pack-root trinity, `pack-ops/`, or `maintenance-docs/` — all DENIED-set-clear for `pack-only` (Check 36 denies `project-template/` + `supporting-docs/` for `pack-only`).
- Interpretation: the `pack-only` Check-36 keyword is correct for both C1 and C3.
- Conclusion: SUPPORTED — C1 + C3 carry `pack-only`; C2 is out-of-repo (no commit/keyword).

---

## 11. Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|---|
| 1 | **agents-never-commit** | Sole Write = `/tmp/pack-handoff-bd238-plan/PLAN-BD-238.md` (Bash heredoc appends + `mkdir -p`). All git read-only: `git rev-parse HEAD` → `e8ba9e7a4d1d3ea33ac3d4320d0aee77bf973381`, `git branch --show-current` → `v11-dev`, `git status --short` → clean. No `add/commit/push/checkout/restore/stash/branch/tag/worktree/merge/rebase` or any state-changing verb. No memory store read/written (MEMORY PROHIBITION honored — §0). | COMPLIANT |
| 2 | **no-solutions-injected** | The plan SEQUENCES the reconciled design; zero redesign. The rule body (§3.1) is copied verbatim from design §4.1; anchors, propagation split, safeguards, size-tiering are the design's. The ONE planner decision (ELECTIVE bundle include/drop) is decided INCLUDE from the design's stated lean (§5 "leans include") + the bounded-cost evidence (EB-P5/EB-P6), not invented. | COMPLIANT |
| 3 | **empirical-evidence-blocks** | §10 carries EB-P1…EB-P8: every NEW state-claim (live-HEAD anchors, no-H2, 1289-char body, rationale model present, the 6 Check-46 surfaces, manifest=7, count=69, pack-only edit set) backed by command + verbatim output + HEAD `e8ba9e7` + interpretation + SUPPORTED conclusion. | COMPLIANT |
| 4 | **operating-docs-no-history-no-bloat** | The §3.1 rule body carried into the plan is the design's terse 1289-char body — ZERO history/dates/provenance; under the Check-66 1300 cap (EB-P3). The plan itself is a reference doc (not an operating doc), so its own structure is unconstrained, but the RULE TEXT it prescribes is clean. | COMPLIANT |
| 5 | **trinity-rule** | The plan mandates the umbrella bullet byte-identical ×3 (Edits 1-3); SAFEGUARD-1 (extract+diff ×3, HALT on diff — §6.3) + SAFEGUARD-2 (PREFLIGHT ×3 attestation — §6.4) are the mechanism, encoded verbatim as HARD steps. No tool-specific deviation — step 8's Claude-only worktree wave is expressed GENERICALLY (references the rule-10 map, does not restate it), byte-parity-safe ×3 (design §8.2). | COMPLIANT |
| 6 | **enumerate-encoding-surfaces** | §2 enumerates every touched surface (corpus ×3 + rationale [MANDATORY], manifest + 2 refs [ELECTIVE], C3 maintenance-docs, C2 out-of-repo) + every verification gate (Check 45/18/46/66 + safeguards + full battery) + every surface NOT touched with evidence (§2.4: agent defs, skills, migration docs, manifest, validate-pack/count). | COMPLIANT |
| 7 | **deferral-is-scope-creep / no-deferral-without-user-direction** | The parity check is DROPPED entirely (§7), NOT deferred — no follow-up BD, no scheduling, no reintroduction; the §10.1 disposition edit (PARITY-CHECK §5) is applied verbatim. All BD-238 work lands in v11.0. Nothing else is deferred. | COMPLIANT |
| 8 | **regenerate-manifest-v11-surface** | §6.5: BD-238 touches NO fixture input (trinity + pack-ops docs only; no `scripts/` change) → push-time `manifest-sync.sh` is a NOOP; the coder does NOT touch `test-fixtures/manifest.txt`; correctness is enforced at push by `build.sh --verify` + Check 62, not per-commit. | COMPLIANT |
| 9 | **rules-applied-verification-block** | This table — rules 1-9, each name + quoted evidence + terminal conclusion (no AMBIGUOUS; no empty evidence). | COMPLIANT |

---

*End of PLAN-BD-238. Fresh independent pack-planner; one Write (this plan) under /tmp; read-only git only; no memory store used. The reconciled design is sequenced into C1 (the standard, one serial coder commit) + C3 (audit-set preservation, paired pack-only doc commit) + C2 (out-of-repo memory reconciliation, Pack-Chat upkeep); the parity CI check is DROPPED (§7, §10.1 disposition applied); SAFEGUARD-1/-2 are encoded verbatim as the SOLE-and-sufficient pack-root parity protection (§6.3/§6.4); the anti-restate verification is retargeted to the 6 Check-46 surfaces + the two new reference one-liners (§6.1); the ELECTIVE discoverability bundle is RECOMMENDED include (§3.3); commit-scope keyword = pack-only for C1 + C3 (§6.6); the manifest is a push-time NOOP (§6.5). Ready for the adversarial planner review.*
