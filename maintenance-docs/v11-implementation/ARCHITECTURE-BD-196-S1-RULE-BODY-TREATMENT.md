# ARCHITECTURE — BD-196 S1: Treatment of the two un-split high-body `## Pack memory` rules

**Type:** Read-only architecture decision (pack-architect output). Resolves ONE BD-196 end-of-batch audit finding. No implementation here.
**Branch / HEAD:** `v11-dev`, `1da5376cc32f20eeb2f90421ddd95238e2d07693`. Measured 2026-05-31.
**Scope class:** STRUCTURAL (changes how `## Pack memory` rules are structured). A coder applies mechanically AFTER user approval; this doc is the strategy.
**Read-only:** every command below is read-only (`grep`/`awk`/`wc`/`sed -n`/`git`/`python3 scripts/validate-pack.py` for measurement). No source edited; the only Write is this doc.

---

## 0. The finding, restated precisely

The BD-196 work tagged **18** `## Pack memory` rules with `[rationale: <slug>]` and moved each one's Why / How-to-apply-worked-example / rejected-alternatives body out of the pack-root trinity into `pack-ops/PACK-MEMORY-RATIONALE.md` (one `## <slug>` section per rule). Check 45 asserts a 1:1 bijection (18 corpus pointers == 18 rationale sections). Two rules that the design's own scope statement classifies as **spawn-relevant** were NOT given this treatment and retain full multi-paragraph bodies inline, **untagged** (no `[roles:]`, no `[rationale:]`):

1. **"Agent prompt enumerates ALL applicable rules inline"** — `CLAUDE.md ## Pack memory` → `### Agent invocation rules` (35 inline lines).
2. **"Pack Chat NO coder review; bounded reviewer/fix cycle"** — `CLAUDE.md ## Pack memory` → `### Pack Chat scope` (66 inline lines — the single largest rule in the corpus).

Question posed: defect (incomplete split) or justified exception?

---

## 1. Challenge of Pack Chat's binary framing

Pack Chat's preliminary framing was a binary: (1) split them like the other 18, or (2) keep inline with a documented §9.8 exception. **I reject the binary** and replace it with the design's OWN governing test, which neither option in the binary invokes.

The split decision is NOT governed by "are they like the other 18" (a pattern-matching framing — explicitly an anti-pattern per the rule in force). It is governed by **`ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md` §5.1(i)/(ii)**, the authoritative split contract:

- **§5.1(i):** the inline imperative must stand alone for correct **APPLICATION**, authored to a two-clause `<DIRECTIVE>+<TRIGGER>` contract. *"The missing application detail moves UP into the imperative, not down into rationale. Rationale holds WHY + worked examples + rejected alternatives only — never load-bearing application detail."*
- **§5.1(ii):** `[rationale: slug]` is **OPTIONAL** — present only if the rule has a genuine Why / rejected-alternatives body. A fully self-contained rule carries `[roles:]` but no `[rationale:]`.

So the design already defines a **three-way** outcome space, not a binary:
- **(A) Split** — rule has a separable Why/worked-example body → two-clause imperative inline + body in rationale + `[rationale: slug]`.
- **(B) Tag-only** — rule is fully application-grade, no rationale body to move → `[roles:]` inline, NO `[rationale:]`. (3 corpus rules already in this state.)
- **(C) Stay-inline-untagged** — rule is NOT spawn-relevant (Pack-Chat-orchestration / repo-maintenance) → no tag, body stays. (The entire `### Pack Chat scope` orchestration set + several `### Agent invocation` rules are here.)

The binary collapses (B) and (C) into "keep inline with exception" and mis-frames the real decision, which is: **for each of the two rules, is its body load-bearing application that must move UP, or Why/worked-example that moves DOWN — and is the rule spawn-relevant at all?** That is a property-fit question, answered per-rule below.

The relevant tier (per the architect-challenge discipline): this is a **boundary-with-existing-design** (the C1/M2 split contract + Check 45 bijection + §5.1 two-clause rule) → **HIGH bar** for any change. The HIGH bar is met by the empirical evidence below, not by analogy to the other 18.

---

## 2. Measured evidence

### 2.1 Body sizes and decomposition

> **Empirical-Evidence Block EE-1 — inline body sizes of the two rules vs. the split-rule baseline.**
> - Command: `sed -n '<range>p' CLAUDE.md | wc -l` for each rule and several split rules. HEAD `1da5376`, 2026-05-31.
> - Output (inline lines, `CLAUDE.md`):
>   - Rule 1 enumerate-inline (L268–302) = **35**; decomposes as imperative (L268–276, 9) + `**Why:**` (L278–287, 10) + `**How to apply:**` (L289–302, 14).
>   - Rule 2 NO-coder-review (L449–514) = **66**; decomposes as imperative (L449–456, 8) + 7-step Cycle procedure (L458–477, 20) + `**Why:**` (L479–491, 13) + `**How to apply:**` (L493–500, 8) + Architect-escalation contract (L502–507, 6) + Final-reviewer-pass note (L509–512, 4) + "Sharpens…" pointer (L514, 1).
>   - Split-rule inline footprints (post-split, for comparison): rules-applied (L304–314) = 11; empirical-evidence (L316–327) = 12; ci-guard (L329–344) = 16; **preflight-stop-means-stop (L258–267) = 10**.
> - Interpretation: both flagged rules carry a `**Why:**` block that is, verbatim, BD-195 history ("**Why:** User-locked 2026-05-30 during BD-195 Step-7 recovery…") — the canonical rationale-doc content per §5.1(ii). Rule 2's bulk is dominated by an operational procedure (the 7-step cycle + escalation contract), not by Why.
> - Conclusion: **SUPPORTED.** Each rule contains a clearly separable Why-body; Rule 2 additionally contains a multi-step procedure whose split-ability is established in EE-2.

### 2.2 The preflight rule proves a multi-step procedure IS split-able

> **Empirical-Evidence Block EE-2 — preflight-stop-means-stop is a split procedure-rule.**
> - Command: `sed -n '258,267p' CLAUDE.md | wc -l` (inline) and `awk '/^## preflight-stop-means-stop/,/^## rules-applied/' pack-ops/PACK-MEMORY-RATIONALE.md | wc -l` (rationale body). HEAD `1da5376`, 2026-05-31.
> - Output: inline imperative = **10 lines** (two-clause: DIRECTIVE = emit the PREFLIGHT line after edits+verification PASS; TRIGGER = before any IMPL-REPORT write / at any parent stop). Rationale body = **68 lines** carrying a multi-part procedure: the PREFLIGHT line format spec, the `**Per-check test runs.**` sub-procedure, the `**STOP-MEANS-STOP preamble**` with per-CLI enforcement, and a BD-193/BD-194 worked example.
> - Interpretation: this rule is structurally the same shape as Rule 2 (an operational procedure with format/steps + history). It was SPLIT successfully: the application-grade essentials compress into a 10-line two-clause imperative; the full step-by-step detail + worked examples + per-CLI notes live in rationale. The agent applying the rule reads the inline imperative; it follows `[rationale: preflight-stop-means-stop]` only on an AMBIGUOUS Rules-Applied row.
> - Conclusion: **SUPPORTED.** "The How-to-apply is a multi-step procedure" is NOT a property that blocks the split — the corpus already contains a split procedure-rule of equal complexity. The property that drives the split is *separable Why/worked-example body present*, which both flagged rules have (EE-1).

### 2.3 Trinity parity and tag state

> **Empirical-Evidence Block EE-3 — both rules are present ×3 (trinity) and carry NO tags.**
> - Command: `grep -c "<imperative>" CLAUDE.md AGENTS.md GEMINI.md`; `sed -n '<range>p' CLAUDE.md | grep -oE '\[roles:[^]]*\]|\[rationale:[^]]*\]'`. HEAD `1da5376`, 2026-05-31.
> - Output: enumerate-inline present 1/1/1 across CLAUDE/AGENTS/GEMINI; NO-coder-review present 1/1/1. Both ranges return **NO TAGS** (no `[roles:]`, no `[rationale:]`).
> - Interpretation: the rules are trinity-replicated (parity holds), and both are entirely outside the tagged set — neither was given the C1 two-clause + `[roles:]` + `[rationale:]` treatment, nor the `[roles:]`-only treatment.
> - Conclusion: **SUPPORTED.**

### 2.4 The design SCOPED these two rules for the split; the implementation did not apply it

> **Empirical-Evidence Block EE-4 — both rules are in the design's spawn-relevant set, hence in C1 scope.**
> - Command: `grep -n "enumerate-inline\|bounded review\|review/fix cadence" ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md` + read PLAN §3 C1. HEAD `1da5376`, 2026-05-31.
> - Output:
>   - `ARCHITECTURE-…-GUARDRAILS.md` §9.3 lists, verbatim, as examples of **CONSOLIDATES (spawn-relevant RULE STATEMENT)**: "git-ban, PREFLIGHT, permissions, **review/fix cadence**, Rules-Applied/Empirical-Evidence obligations, **enumerate-inline**."
>   - `PLAN-DOC-CONCISION-GUARDRAILS.md` §3 commit C1: *"For each spawn-relevant imperative bullet (~22 of 45 per EE-6), (a) rewrite … two-clause …; (b) append `[roles: …]`; (c) append `[rationale: <slug>]`. Why/example bodies STAY in place this commit (they leave in C2)…"*
> - Interpretation: the approved plan scoped **~22** rules for the C1/C2 treatment and named BOTH flagged rules (review/fix cadence = Rule 2; enumerate-inline = Rule 1) as spawn-relevant. The implementation tagged/split only **18**. The two flagged rules are within the ~22 the plan committed to, and were not treated.
> - Conclusion: **SUPPORTED.** Leaving them inline-untagged is a deviation from the approved plan, not a designed exception. No carve-out exists: a whole-doc `grep` for "exception / keep inline / cannot split / procedure-rule" across both design docs returns only the unrelated Ban-C deliverable-only exception (`ARCHITECTURE-…-GUARDRAILS.md:104`).

### 2.5 No CI gate forces this; the M2 intent is design discipline for the trinity

> **Empirical-Evidence Block EE-5 — Check 44 (M4 concision) does NOT scan the trinity.**
> - Command: read `_CHECK_44_DURABLE_DOCS` in `scripts/validate-pack.py` (L6582–6590); `python3 scripts/validate-pack.py` exit code + Check 44/45 lines. HEAD `1da5376`, 2026-05-31.
> - Output: Check 44's M4 class = the 7 `pack-ops/` non-mirror docs (BOUNDARY-DEFINITION, CONCEPTUAL-REVIEW-METHODOLOGY, DRY-RUN-MIGRATION, HELP-FRAGMENT-PACK, HELP-FRAGMENT-TRACKER, MERGE-STRATEGY, OPTIONAL-FEATURES). `CLAUDE.md`/`AGENTS.md`/`GEMINI.md` are NOT in the set. Validator exit code = **0**; Check 45 reports "18 corpus … 18 rationale … sets are equal"; Check 44 reports "0 forbidden pattern(s) outside the allowlist".
> - Interpretation: there is NO CI gate forcing the trinity `## Pack memory` corpus to be concise or forcing these two rules to split. The M2 corpus-split intent is enforced for the 7 pack-ops docs (M4/Check 44) but is a **design discipline** for the trinity corpus, backed only by the §5.1 authoring contract and by Check 45's bijection (which only checks that *present* slugs balance — it does not require any given rule to carry a slug).
> - Conclusion: **SUPPORTED.** The finding is a discipline/consistency defect against the approved C1/C2 scope, not a CI-failing state. The tree is green today; this is a quality decision, not a break-fix.

### 2.6 Property-fit verdict per rule

> **Empirical-Evidence Block EE-6 — per-rule decomposition into MOVE-UP (application) vs MOVE-DOWN (rationale).**
> - Method: read each rule body (L268–302; L449–514) and classify each sub-block by §5.1(i) (load-bearing application → inline) vs §5.1(ii) (Why / worked-example / rejected-alternatives → rationale). HEAD `1da5376`, 2026-05-31.
> - **Rule 1 (enumerate-inline):**
>   - Imperative (9 lines): load-bearing → INLINE. Already application-grade ("MUST enumerate ALL applicable pack-memory rules and trinity sections INLINE … the LITERAL rule text — name + Why + How-to-apply paragraphs — is pasted").
>   - `**How to apply:**` (14 lines): the 6-section prompt-assembly recipe (sections 1–6). This is load-bearing application detail per §5.1(i) → its ESSENTIALS belong in the two-clause imperative (the TRIGGER clause names "before spawning ANY sub-agent, assemble the Rules-in-force block"); the full 6-section enumeration is a worked recipe → MOVE-DOWN to rationale (mirrors how preflight's format-spec lives in rationale, EE-2).
>   - `**Why:**` (10 lines, BD-195 C6/C7 history + token-cost note): pure rationale → MOVE-DOWN.
> - **Rule 2 (NO-coder-review):**
>   - Imperative (8 lines): load-bearing → INLINE (DIRECTIVE = Pack Chat never reviews coder output, every coder run gets a bounded review/fix cycle; TRIGGER = max 2 review/fix pairs + 1 final reviewer = 3 reviewer / 2 fix-coder per commit, else architect escalation).
>   - 7-step Cycle (20 lines) + Architect-escalation contract (6 lines) + Final-reviewer-pass note (4 lines): operational procedure + worked steps. Per EE-2 this is split-able exactly as preflight's procedure was → MOVE-DOWN to rationale, with the bound + the escalation TRIGGER stated in the inline two-clause imperative.
>   - `**How to apply:**` (8 lines, progress-marker formatting + "no Read/Edit/Bash to verify coder edits"): the "no independent verification" clause is load-bearing → fold into imperative; the progress-marker string examples → MOVE-DOWN.
>   - `**Why:**` (13 lines, BD-195 judgment-compromise history): pure rationale → MOVE-DOWN.
>   - "Sharpens 'Pack Chat does NO fixes'" (1 line): a cross-pointer → keep as a one-line inline note or fold into rationale.
> - Conclusion: **SUPPORTED.** Both rules fit outcome **(A) Split**: each has a substantial separable Why + worked-procedure body (MOVE-DOWN) and a compressible application-grade imperative (the load-bearing TRIGGER/DIRECTIVE essentials MOVE-UP into a two-clause line). Neither fits (B) tag-only (both have genuine rationale bodies) and neither fits (C) stay-inline-untagged (both are spawn-relevant per EE-4, both governed by the C1 scope).

---

## 3. DECISION

**SPLIT both rules** (outcome A), bringing them into conformance with the approved C1/C2 contract the implementation under-applied. This is the completion of an incomplete split, not a new design and not an exception.

**Rationale (measured, not by analogy):**
1. **Property-fit (EE-6):** both rules contain a separable Why-body (verbatim BD-195 history) plus, for Rule 2, a multi-step procedure — exactly the content §5.1(i)/(ii) routes to the rationale doc. Their imperatives are compressible to an application-grade two-clause form.
2. **The "procedure can't be split" objection is empirically false (EE-2):** `preflight-stop-means-stop` is an equally procedure-heavy rule that was split (10-line inline imperative / 68-line rationale body). The corpus already contains the precedent; not splitting these two is the inconsistency.
3. **It is the approved plan (EE-4):** PLAN C1 scoped ~22 rules including both of these by name; the implementation applied it to 18. SPLIT closes that gap.
4. **HIGH-bar boundary cleared:** the change touches the C1/M2 split contract + Check 45 bijection — the HIGH-bar surface — and the evidence (EE-1…EE-6) clears it: the split is property-justified, precedented, and plan-mandated; the bijection delta is mechanical and balanced (§5).
5. **It serves the M2 concision intent (EE-1):** removes ~237 trinity-wide lines (101 inline/file × 3 → ~22/file × 3) of duplicated body from the every-session-loaded trinity, relocating ~134 lines to one read-on-demand rationale doc.

**This decision IMPLIES coder work** (mechanical, per §4). It does NOT require an exception record, because there is no exception — the rules join the existing split contract.

**Tier-aware note:** because this is a STRUCTURAL change to rule structure, the mechanical strategy in §4 is for a coder to apply AFTER user approval; the architect does not implement.

---

## 4. Mechanical implementation strategy (a coder applies without judgment)

Two new slugs join the corpus: `enumerate-rules-inline` (Rule 1) and `bounded-review-fix-cycle` (Rule 2). (Slug names are the coder's to finalize within the kebab-case controlled-vocab; these are the recommended forms. Avoid collision with existing 18 — grep-checked: neither exists.)

This follows the EXISTING rule-change propagation procedure (`ARCHITECTURE-…-GUARDRAILS.md` §12 / `PACK-CHAT.md` "Keeping … current"). One commit, trinity lock-step.

**Step 1 — Corpus edit ×3 trinity (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`, `## Pack memory` only; SAME commit, trinity lock-step):**
- **Rule 1** → replace the 35-line block with a two-clause imperative line ending in `[roles: universal] [rationale: enumerate-rules-inline]`. DIRECTIVE: "Every sub-agent prompt Pack Chat constructs MUST enumerate ALL applicable pack-memory rules + trinity sections INLINE as literal rule text (name + Why + How-to-apply), never by reference." TRIGGER: "before spawning ANY sub-agent — assemble a Rules-in-force block selecting rules tagged for the spawn's role + universal." (`[roles: universal]` because it binds Pack Chat for every spawn; if the coder/reviewer judge it Pack-Chat-only, `[roles: universal]` is still the safe controlled-vocab value — it is not a per-agent in-task rule, so no narrower tag applies. The tag choice is a coder/reviewer call within the controlled vocab, surfaced in the IMPL-REPORT.)
- **Rule 2** → replace the 66-line block with a two-clause imperative line ending in `[roles: universal] [rationale: bounded-review-fix-cycle]`. DIRECTIVE: "Pack Chat NEVER reviews coder output directly; every coder run is followed by a BOUNDED review/fix cycle and Pack Chat does NO fixes itself." TRIGGER: "max 2 review/fix pairs + 1 final reviewer pass = 3 reviewer / 2 fix-coder spawns per commit; if dirty after the final reviewer pass, STOP and spawn pack-architect for diagnosis — no fix-coder pass 3." Keep the one-line "Sharpens 'Pack Chat does NO fixes'" pointer inline OR fold to rationale (coder's call; note in IMPL-REPORT).

**Step 2 — Rationale doc (`pack-ops/PACK-MEMORY-RATIONALE.md`; SAME commit):** add two `## <slug>` sections in corpus order:
- `## enumerate-rules-inline` — the moved `**Why:**` (BD-195 C6/C7 + token-cost) + the `**How to apply:**` 6-section prompt-assembly recipe (the worked example), verbatim from the current inline body.
- `## bounded-review-fix-cycle` — the moved `**Why:**` (judgment-compromise history) + the 7-step Cycle + Architect-escalation contract + Final-reviewer-pass note + the progress-marker string examples from `**How to apply:**`, verbatim.
- Edit-in-place: insert the two sections; do NOT rewrite the file. Re-confirm the section map after the edit.

**Step 3 — Verify bijection:** after Steps 1–2, the corpus carries 20 `[rationale: slug]` pointers and the rationale doc carries 20 `## <slug>` sections. Run `python3 scripts/validate-pack.py`; Check 45 must report "20 … 20 … sets are equal." (No Check 45 code change — it is data-driven.)

**Step 4 — Reference/manifest surfaces:** grep the repo (excl. `prison/`, `archive/`) for inbound cites of either rule's old inline body (e.g., "see the bounded review/fix cycle in `## Pack memory`", "enumerate-inline rule's How-to"). If `pack-ops/.spawn-rule-manifest.txt` has entries for these two rules, update per §9.6 (reference-resolution). Fix-or-repoint each dangling cite to the new `[rationale: slug]` (7b blast-radius sweep — completion criterion of the commit).

**Step 5 — Manifest regen:** the commit touches `CLAUDE.md`/`AGENTS.md`/`GEMINI.md` at pack-root (NOT v11-surface — not under `project-template/`/`scripts/`/`pack-ops/`/`supporting-docs/`) AND `pack-ops/PACK-MEMORY-RATIONALE.md` (IS v11-surface — under `pack-ops/`). Per the `regenerate-manifest-v11-surface` rule, run `bash test-fixtures/build.sh --all --clean`; stage `test-fixtures/manifest.txt` if the diff is non-empty (likely empty — RATIONALE.md is not installed by `init-project.sh` — but the rebuild+check is mandatory).

**Step 6 — Per-check tests:** run `scripts/tests/test-validate-pack-check-45.sh` (bijection) and the trinity-parity checks' tests if touched. ALL must pass before the PREFLIGHT line.

**Working-state invariant:** `validate-pack.py` (all checks) green at the commit boundary. This commit only ADDS two balanced slug pairs — bijection never sees a half-applied state because Steps 1+2 land together.

---

## 5. Blast-radius / bijection delta

| Surface | Delta | Mechanism |
|---|---|---|
| Trinity `## Pack memory` ×3 | Rule 1: 35→~10 lines; Rule 2: 66→~12 lines. ~237 lines removed trinity-wide. Trinity lock-step (3 files, 1 commit). | Trinity-parity Checks 16/18/19 (assert H2 structure/scaffolding/addenda, not tag content — stay green). |
| `pack-ops/PACK-MEMORY-RATIONALE.md` | +2 `## <slug>` sections (~134 lines body total). | Edit-in-place insert. |
| Check 45 bijection | **18 → 20** on BOTH sides (corpus pointers and rationale sections). Stays balanced. | Data-driven; no code change. |
| `pack-ops/.spawn-rule-manifest.txt` (if it has rows for these rules) | Possible reference-row update. | §9.6 reference-resolution. |
| The enumerate-inline rule's OWN how-to (the meta-loop) | None special. Pack Chat already reads the rationale doc to paste a rule (one-hop, same as all 18). After the split, when Pack Chat enumerates THIS rule into a prompt, it pastes the inline two-clause imperative + follows `[rationale: enumerate-rules-inline]` on ambiguity — identical to every other split rule. No recursion hazard. | C1-(ii) one-hop guarantee. |
| `test-fixtures/manifest.txt` | Regen mandated; diff likely empty (RATIONALE.md not client-installed). | manifest-regen-v11-surface rule. |
| CI gate | NONE forces this (EE-5). Tree green before and after. | — |

No project-side surface, no client-installed file, no migrator, no agent definition is touched. Pure pack-ops + pack-root-trinity change.

---

## 6. Second-order finding (FLAGGED — out of scope; do NOT fix here)

> **Empirical-Evidence Block EE-7 — other untagged rules in the corpus.**
> - Command: `awk` count of `## Pack memory` bullets (45 total); `grep -oE '\[roles:'` count (21) and `\[rationale:'` count (18); enumerate `### Pack Chat scope` bullets. HEAD `1da5376`, 2026-05-31.
> - Output: 45 bullets total; 18 carry `[rationale:]`; **21 carry `[roles:]`** (so 3 carry `[roles:]` without `[rationale:]` — the §5.1(ii) self-contained cases: e.g., per-entry-trees, separate-ops-from-product, test-infra-self-provisioned). The remaining ~24 bullets carry NEITHER tag. The entire `### Pack Chat scope` subsection (Pack-Chat-does-NO-fixes, What-Pack-Chat-CAN-edit, Commit-approval-next-steps-plan, Pack-architect-spawn-protocol, Batch-scope-CI) is untagged; several `### Agent invocation` rules (Pack-agent-invocation, Agent-prompt-requirements, No-solutions, No-prior-reviews, Researcher-first, Planner-output) are untagged.
> - Interpretation: most untagged rules are Pack-Chat-orchestration or repo-maintenance, NOT agent-spawn rules — they correctly sit in outcome (C) stay-inline-untagged (the design's §9.3 STAYS-AND-REFERENCES class). A FEW may be spawn-relevant and in the same incomplete-split situation as the two flagged here (e.g., "Researcher-first pipeline", "Planner output → user review → coder spawn" arguably bind spawn ordering). EE-4's "~22 spawn-relevant" vs the 18-actually-split gap is consistent with the two flagged rules accounting for most of it, but a complete reconciliation of all 45 against the (A)/(B)/(C) outcomes was NOT performed here.
> - Conclusion: **PARTIAL.** The two flagged rules are the clear, largest, plan-named cases. Whether any OTHER untagged rule should be tagged-or-split is a separate, corpus-wide audit. I FLAG it for the user; I do NOT expand this decision's scope to it (per scope-to-the-ask). Recommendation: if the user wants completeness, a follow-up pass reconciles all 45 bullets against (A)/(B)/(C) — but that is its own BD-scoped task, not part of resolving this finding.

---

## 7. Rules-Applied Verification Block

| Rule (as named in the prompt's Rules-in-force) | Verification evidence | Conclusion |
|---|---|---|
| Architect/planner state-claims require Empirical-Evidence Blocks | Every state-claim (body sizes, preflight-split precedent, trinity parity, design-scoped-22, no-CI-gate, property-fit, bijection delta, second-order survey) carries EE-1…EE-7 with command + verbatim output + HEAD `1da5376` + 2026-05-31 + SUPPORTED/PARTIAL. | COMPLIANT |
| Pattern-matching out of context is an anti-pattern | §1 explicitly REJECTS the "are they like the other 18" framing and substitutes the §5.1(i)/(ii) property-fit test; the split conclusion is reached from EE-6 property decomposition + EE-2 precedent, not from analogy. | COMPLIANT |
| Preliminary triage + architect-challenge discipline | §1 treats Pack Chat's binary as PRELIMINARY and challenges it — replaces it with a three-way (A)/(B)/(C) outcome space and applies the HIGH bar (boundary-with-existing-design) cleared by measured evidence. | COMPLIANT |
| Skill/agent + rule maintenance: structural changes escalate | Doc top-matter marks this STRUCTURAL; §3/§4 explicitly state a coder applies mechanically AFTER user approval; the architect does not implement. | COMPLIANT |
| Trinity + bijection awareness | §5 quantifies the blast radius: trinity lock-step (3 files), Check 45 bijection 18→20 (balanced), 2 new rationale sections, manifest regen, the enumerate-inline meta-loop one-hop (no recursion). | COMPLIANT |
| Agent output requires Rules-Applied Verification Block | This table. | COMPLIANT |
| Agents never commit / no destructive ops | Only read-only commands run (`grep`/`awk`/`wc`/`sed -n`/`git rev-parse`/`python3 scripts/validate-pack.py`); the sole Write is this design doc at the caller-specified path; no git state change; `maintenance-docs/prison/` not read. | COMPLIANT |

**End of ARCHITECTURE-BD-196-S1-RULE-BODY-TREATMENT.md.**
