# ADVERSARIAL-REVIEW-BD-238 — fresh independent pack-architect adversarial review of DESIGN-BD-238

**Role:** pack-architect (RO), FRESH adversary. Did NOT author the design. **BD:** BD-238 (LARGE; user-confirmed 2026-06-23). **Mandate:** challenge the design hard, re-measure independently, find what is wrong/weak/missing/mis-scoped/purpose-defeating. **Output:** this review doc only (the sole Write; under `/tmp`). Read-only git only; no memory store consulted (user MEMORY PROHIBITION 2026-06-23).

---

## 0. Runtime regime (RO; verified)

| Field | Value |
|---|---|
| `pwd` | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev` |
| `git rev-parse HEAD` | `67078627327d70f30d89d0f8500eb6e91993cffd` (= expected `6707862`) |
| branch | `v11-dev` |
| `git status --short` | ` M backlog/_toc.md` + `?? backlog/BD-245.md` — both UNRELATED to BD-238 (the BD-238 work under review is the uncommitted /tmp design). I read the design + research from `/tmp`, the live tree at HEAD `6707862`. |
| graph | queried for DISCOVERY; operating-doc rules are not node-indexed (the research already established this) → grep/Read used for VERIFICATION (G2 fallback, sanctioned). |
| writes | EXACTLY ONE: this review doc. No source edits. Read-only git only. No memory read/write. |

---

## 1. Summary verdict

The design is **substantially sound and largely implementable** — the rule text genuinely fits the gates I re-measured (1203 chars < 1300; placement anchors exact; the slug propagation is real), the no-conflict analysis holds, and the §10.1 scope call is **defensible and I AGREE with it** (with a caveat). BUT I found **two MAJOR defects** that must be fixed before the planner runs, plus several MINORs:

- **MAJOR-1 — the anti-restate evidence (EB-7) measures the WRONG check.** The design's anti-restate self-check tests a property Check 46 never evaluates. The conclusion (anti-restate passes) happens to be correct for a DIFFERENT reason, but the evidence is methodologically void — a reviewer relying on EB-7 would be misled about what protects the implementation.
- **MAJOR-2 — the size-tiering L4 signal over-classifies routine rule tweaks as LARGE, contradicting live precedent (BD-244).** L4 ("trinity-rule change") fires on ANY pack-memory rule edit; under the criterion BD-244 is LARGE and would have MANDATED two adversarial reviews + reconciliation — yet BD-244 actually shipped clean on the BASE (non-adversarial) pipeline three days ago. The criterion as written makes nearly every pack-memory BD LARGE, which dilutes the tier and over-spends the adversarial budget.

Neither is purpose-defeating; both are fixable in reconciliation. There are also two places where the design **over-scopes** (claims surfaces are Check-mandated when they are elective) and one place where the **rule-10 SERIAL reasoning is wrong** (though the verdict is right).

**VERDICT: NEEDS-REWORK (2 major)**

---

## 2. Findings

### BLOCKER — none.

I found no purpose-defeating gap. The standard's spine exists, the two genuine gaps (chaining+tiering, adversarial-as-named-tier) are real and closeable, the rule fits the cap, placement is byte-parity-feasible.

---

### MAJOR-1 — EB-7 anti-restate self-check measures a property Check 46 does NOT test (evidence is void; conclusion right by accident)

**The design's claim (EB-7, §4.1):** "every ≥60-char window of each existing CLAUDE.md `## Pack memory` imperative body tested as a substring of the whitespace-normalized final rule body … 0 hits … Check 46 anti-restate will pass."

**What Check 46 anti-restate ACTUALLY does** (re-read `scripts/validate-pack.py` L7469-7494, L7531-7566, L7715-7742):

1. It extracts **candidate needles** = the leading 120-char window (kept iff ≥60 chars) of every existing CLAUDE.md `## Pack memory` rule BODY (`_check_46_extract_pack_memory_imperative_bodies`, L7531; `normalized[:120]`, L7563).
2. It searches for those needles inside the **haystack SURFACES** = `_CHECK_46_ANTI_RESTATE_SURFACES` (L7469-7476):

```
pack-ops/PACK-AGENTS.md
pack-ops/PACK-CHAT.md
.claude/skills/commit-discipline/SKILL.md
.claude/skills/review/SKILL.md
.claude/skills/planning/SKILL.md
.claude/skills/implementation-report/SKILL.md
```

**The trinity files are NOT in the scan surface set.** Check 46 NEVER compares the new rule body against existing rule bodies. So EB-7's test ("does the new rule body reproduce an existing body") is a property Check 46 does not evaluate in either direction. EB-7 is measuring an invented check.

**What Check 46 anti-restate WILL test post-implementation** (re-measured by me — replicating the exact candidate-extraction + substring scan):

```
NEW rule leading-window candidate (<=120 chars, len=120):
'Pack-side BD development runs ONE official pipeline: optional researcher(s) (internal census and/or external docs verifi'
  pack-ops/PACK-AGENTS.md: new-rule-window present? False
  pack-ops/PACK-CHAT.md: new-rule-window present? False
  .claude/skills/commit-discipline/SKILL.md: new-rule-window present? False
  .claude/skills/review/SKILL.md: new-rule-window present? False
  .claude/skills/planning/SKILL.md: new-rule-window present? False
  .claude/skills/implementation-report/SKILL.md: new-rule-window present? False
```

So Check 46 will pass — because (a) the NEW rule's body window does not leak into any scan surface, and (b) the design's two added reference one-liners (§4.2/§4.3) are short paraphrases, not 60+-char body copies. The CONCLUSION ("anti-restate passes") is correct, but EB-7 proves it for the wrong reason.

**Why this matters adversarially:** the real anti-restate risk for THIS BD is the two NEW reference surfaces the design adds (§4.2 PACK-CHAT.md anchor, §4.3 PACK-AGENTS.md one-liner). EB-7 does not test those at all. A planner/coder who trusts EB-7 will not verify the actual gated property — that the §4.2/§4.3 texts (and the new rule's own leading window) stay out of the 6 scan surfaces.

**Fix:** REPLACE EB-7 with the correct measurement: (1) extract the new rule's leading-120 body window; (2) confirm it is absent from all 6 `_CHECK_46_ANTI_RESTATE_SURFACES`; (3) confirm the §4.2/§4.3 reference texts contain no 60+-char leading-window of any existing rule body. The planner's verification step must target the 6 scan surfaces, not a trinity-vs-trinity diff. (Evidence: EB-A below.)

---

### MAJOR-2 — the L4 size-tiering signal over-classifies routine pack-memory rule tweaks as LARGE; contradicts the BD-244 precedent (measure-then-bound failure)

**The design's L4 signal (§3):** "Structural — the BD adds/changes a convention, a CI check, a file-tree shape, a migration path, **or a trinity rule** (i.e. it is architect-first per the pack-architect-spawn-protocol)." Any one of L1-L4 ⇒ LARGE ⇒ the two adversarial reviews + reconciliation are the MINIMUM.

**The measure-then-bound test the design SKIPPED:** run the criterion against the actual recent precedent set and check whether its classification matches what the pipeline actually did. I ran it against **BD-244** (Resolved 2026-06-23, the immediately-prior pack-memory rule BD):

- BD-244 "Adds a facet to the existing `ci-guard-measure-then-bound` rule (pack-root trinity ×3)" → **L4 fires** (a trinity-rule change; explicitly named in L4).
- BD-244 touched trinity `## Pack memory` + `PACK-MEMORY-RATIONALE.md` + `scripts/validate-pack.py` (converted 2 builders + a shared helper) + tests → spans `trinity` + `scripts/+validators` ⇒ **L2 fires (≥2 families).**
- ⇒ The criterion classifies **BD-244 as LARGE**, mandating two adversarial reviews + reconciliation as the MINIMUM.

**But BD-244's actual pipeline (from its Resolved line) was the BASE flow, NOT the adversarial flow:**

```
Pipeline: pack-architect → pack-planner (...) → pack-coder → pack-reviewer
(1 SHOULD: Check 66 cap) → fix-coder → post-fix reviewer CLEAN.
```

No adversarial architect, no adversarial planner, no reconciliation round — and it shipped clean (CI run 28039394721 green). So the criterion, applied literally, would have FORCED two adversarial passes on a BD that the base pipeline handled correctly. Worse: **L4 fires on EVERY pack-memory rule add/change** (every such BD is architect-first per the spawn-protocol), so under this criterion essentially every pack-memory BD is LARGE. The LARGE tier swallows the SMALL tier for the most common pack work class — which defeats the size-tiering's purpose (the whole point is that SMALL BDs get the cheaper base flow).

**This is a measure-then-bound violation:** the design DECLARED the criterion ("each signal is a yes/no test … not a vibe", §3) but never MEASURED it against the precedent set to check the bound. Had it measured BD-244, the over-trigger would have surfaced.

**Counter-argument I considered (steelmanning the design):** the design's tie-break is "when in doubt, LARGE … the rigor is cheap insurance," and BD-238 itself is confirmed LARGE. One could argue over-classification is the SAFE error. I reject this as a sufficient defense: (a) the user's BD-238 premise EXPLICITLY wants the adversarial passes "OPTIONAL (user-elective) for SMALLER BDs" — a criterion that makes nearly all pack-memory BDs LARGE removes the user-elective small tier the premise demands; (b) "cheap insurance" is false for adversarial passes — each is a full fresh architect/planner spawn + reconciliation round + triage gate, i.e. the most expensive rigor the pack has; auto-mandating it on single-clause rule tweaks is exactly the over-spend the tiering exists to prevent.

**Fix (one of):**
- (a) **Tighten L4** so a single-facet/single-clause amendment to an EXISTING rule is NOT automatically LARGE — reserve L4-structural for a NEW rule, a NEW convention, a NEW/changed CI check, a tree-shape/migration change, or a rule change that ALSO fires L2/L3. A pure ×3 byte-parallel clause-add to one existing rule, with no validator/tree change, is the canonical SMALL pack-memory edit. OR
- (b) Keep L4 broad but **demote the consequence**: a BD that fires ONLY L4 (and no other signal) gets the base flow with adversarial passes OPTIONAL; LARGE-with-mandatory-adversarial requires ≥2 signals OR L1 (launch-gate) alone. This is a true measure-then-bound disjunction calibrated to the precedent (BD-244 = L2+L4 but base-flow-sufficient; BD-243 = L2+L3+L4 structural cross-surface = correctly LARGE).

Either fix must be re-validated against BD-244 (should land SMALL or base-flow-optional) and BD-243 (should stay LARGE). (Evidence: EB-B below.)

---

### MINOR-1 — §5 rows 3 & 4 (spawn-rule-manifest record + two reference one-liners) are presented as Check-46-MANDATED; they are ELECTIVE (over-scope claim)

**The design's framing (§5 table, rows 3-4; §10.1; acceptance):** the spawn-rule-manifest record and the two reference one-liners are listed with "Gating check: Check 46 reference-resolution," implying they are required for validate-pack green.

**Re-measured:** the spawn-rule-manifest is a CURATED SUBSET, not an all-tagged-rules set. There are 29 `## ` rationale headings but only 7 manifest slugs:

```
slug: agents-never-commit / role-write-scope / preflight-stop-means-stop /
presents-triage-before-fix-coder / triage-all-fix-all / bounded-review-fix-cycle /
pack-chat-minor-edits-only
```

Tagged rules NOT in the manifest include `reconciliation-instance-independence`, `graph-first-context`, `spawn-unique-naming`, `enumerate-encoding-surfaces`, and 21 others. Check 46 only validates manifest records that EXIST (it iterates `_parse_manifest_records` over the file's records; it does NOT require a record per tagged rule). Therefore adding a `large-bd-pipeline-standard` manifest record + the two reference one-liners it points at is a **design CHOICE**, not a Check-46 requirement.

**The genuinely MANDATORY surfaces** for a new `[rationale: large-bd-pipeline-standard]`-tagged rule are exactly: **corpus ×3 (row 1)** + **the `## large-bd-pipeline-standard` rationale section (row 2)** — because Check 45 bijection is bidirectional and mandatory (L7401-7415: an orphan corpus slug FAILs). Rows 3-5 are elective.

**Why this matters:** the design adds the manifest row + two reference surfaces partly to discharge a check that does not require them. That is mild scope creep (two extra reference edits + a manifest record + their own anti-restate exposure). It is DEFENSIBLE on discoverability grounds (the pipeline order genuinely lives in PACK-AGENTS/PACK-CHAT), but the design should label rows 3-4 as "elective discoverability references (NOT Check-mandated)" so the planner/user can choose to drop them to minimize footprint. **Fix:** relabel rows 3-4 gating column to "elective (no check requires it); chosen for discoverability" and state plainly that the minimal green footprint is rows 1+2 only. (Evidence: EB-C below.)

---

### MINOR-2 — the rule-10 SERIAL verdict is CORRECT, but its stated REASON ("C1 cannot be split — bijection/anti-restate would fail on a half-applied state") is wrong

**The design's reasoning (§9.1/§9.2):** "Cannot be split (bijection/anti-restate would fail on a half-applied state)."

**Re-measured:** CI is `on: push` (`.github/workflows/validate-pack.yml:103`), NOT per-commit. And the propagation procedure states explicitly (`pack-ops/PACK-CHAT.md:489`): "Order is documented, not gate-sequenced: a commit is atomic; the propagation order is verified by END-STATE checks (bijection / anti-restate / trinity-parity / manifest), not a hard-enforced step sequence." L472 even permits the propagation to land "in the same commit as the structural change, **or in the immediately following commit**." So a split across two commits WITHIN one push would NOT fail CI — the checks see only the push end-state.

**What actually forces one commit:** (a) the trinity rule mandates the ×3 trinity edit be a single parallel edit (good practice + parity discipline, NOT a per-commit gate); (b) cleanliness/auditability. The SERIAL verdict is right (one coder, one worktree, no parallel waves — no disjoint-file concurrency available because the bijection set is a single logical unit best kept atomic), but the design overstates the binding constraint as a CI gate when it is a discipline/end-state matter. **Fix:** correct §9.1/§9.2 reasoning to "atomic by trinity-rule + auditability discipline; CI is end-state at push so a split would not fail, but a single atomic commit is the correct practice" — keep the SERIAL verdict. (Evidence: EB-D below.)

---

### MINOR-3 — EB-3 / §7.1 parity claim is CORRECT and well-evidenced (no defect) — recording the independent re-confirmation

I independently re-verified the load-bearing parity claim (it underpins §10.1):
- Check 18 (`check_trinity_h2_parity`) IS registered at pack-root (L11356-11357) but collects ONLY `## ` heading lines (L1634-1638) and compares those lists — it does NOT compare rule BODIES.
- Check 45 bijection scans `corpus_path = REPO_ROOT / "CLAUDE.md"` ONLY (L7359); AGENTS/GEMINI `[rationale:]` slugs are never bijection-checked.
- No check byte-compares pack-root `## Pack memory` rule BODIES across the trinity.

So the design's central premise for §10.1 is SOUND. The trinity rule explicitly covers pack-repo copies (`CLAUDE.md:113-114`: "This rule also applies to the pack-repo copies of these three files"), so the parity OBLIGATION exists but is discipline-enforced. **No fix needed** — recorded because §10.1's verdict depends on it. (Evidence: EB-E below.)

---

### NIT-1 — EB-4/EB-5 char measurements are accurate; densest legitimate rule is 1260, new rule 1203 — comfortable, no fix

Independently re-measured under the exact Check-66 algorithm: new rule body = **1203 chars** (matches the design); densest non-allowlisted existing rule (`reconciliation-instance-independence`) = **1260**; `ci-guard-measure-then-bound` (the BD-244 fix-coder result) = **1231**; allowlisted over-cap rules: Graph-first 4275, Sub-agent isolation 2426, Pack-Chat-MINOR 2341. The new rule at 1203 sits below even the densest legitimate rule. EB-4/EB-5 are accurate. **No fix.** (Evidence: EB-F below.)

### NIT-2 — placement anchors (EB-2) re-confirmed exact

`Researcher-first pipeline` / `Planner output → user review` at CLAUDE.md L288/L296, AGENTS.md L277/L285, GEMINI.md L249/L257 — matches the design's EB-2 byte-for-byte. The insertion is mid-`### Agent invocation rules` (no new H2 ⇒ Check 18 unaffected). **No fix.**

### NIT-3 — out-of-repo memory reconciliation is sound; one residual to tighten

The trinity-wins prepend approach (§6) is sound and removes the situational-vs-minimum contradiction. ONE residual: the design subordinates the two memories to the new `large-bd-pipeline-standard` but does NOT address that the existing IN-REPO `reconciliation-instance-independence` rule ALREADY uses the phrase "an adversarial review" presupposing the stage exists. After this BD, "adversarial architect/planner review" is defined in two in-repo places conceptually adjacent (the new umbrella names the STAGE; the reconciliation rule governs WHO reconciles AFTER it). This is not a contradiction (they are complementary), but the rationale section for the new slug should explicitly state the boundary ("the umbrella NAMES the adversarial stages; `reconciliation-instance-independence` governs the fresh-instance reconciliation that follows a NEEDS-REWORK") so a future reader does not perceive overlap. **Fix:** add that one-sentence boundary note to the §5-row-2 rationale section spec.

---

## 3. Explicit verdict on the §10.1 scope question (new pack-root `## Pack memory` body-parity CI check)

**The question:** is leaving pack-root `## Pack memory` body parity discipline-only (no CI gate) a purpose-defeating gap given it has "bitten twice" (BD-244 Check 66, this BD), or is the design right to defer a new parity check to a separate structural BD?

**My adversarial verdict: I AGREE with the design — do NOT add a body-parity CI check in BD-238 — but the design's "bitten twice" framing is imprecise and should be corrected.**

Reasoning, measure-then-bound:

1. **The "bitten twice" claim is mis-stated.** What "bit" BD-244 and threatens this BD is the **Check-66 char cap** (a per-FILE concision gate), NOT a body-PARITY drift. BD-244's Resolved line: "1 SHOULD: the new rule text pushed the bullet over Check 66's 1300-char cap." That is a concision finding, caught by an EXISTING check, fixed by the reviewer — it is the system WORKING, not a parity gap escaping. There is NO recorded incident of a pack-root `## Pack memory` BODY-PARITY drift shipping undetected. So the premise that body-parity has "bitten twice" is unsupported; the design should drop that framing (it overstates the gap to justify even raising the question).

2. **Live precedent says discipline is the accepted answer.** BD-244 (Resolved 2026-06-23, the immediately-prior trinity rule change) explicitly recorded that its planner "caught a … trinity-parity-is-discipline correction" — i.e. the prior pipeline on this exact surface CONCLUDED parity is discipline-enforced and shipped clean on that basis. Re-deciding it here would re-litigate a 3-day-old resolved call without new evidence.

3. **A new body-parity check is genuinely a larger, separate BD (SIZE + LOGICAL-FIT bar met).** A pack-root `## Pack memory` body-parity check would have to: (a) decide the normalization (the Claude-only `### Sub-agent behavior` section + the GEMINI-intrinsic H2s mean a naive ×3 byte-diff is WRONG — it would false-positive on the legitimately-Claude-only and GEMINI-intrinsic content); (b) re-baseline every existing pack-root `## Pack memory` rule for ×3 identity, including the rules that are intentionally Claude-only; (c) reconcile with Check 45's deliberate CLAUDE.md-representative design. That is a real measure-then-bound CI-guard design effort with its own blast radius — exactly the kind of work the `deferral-is-scope-creep` rule's LOGICAL-FIT carve-out permits deferring (it is a DIFFERENT contract: parity-of-bodies vs the chaining/tiering codification BD-238 is about).

4. **Therefore the deferral is NOT scope creep** under the SIZE/BLOCKED/LOGICAL-FIT bar: it is a logically distinct check with a non-trivial design (the Claude-only/GEMINI-intrinsic normalization problem), not unblocked work being punted. The design's mitigation (atomic ×3 edit + planner byte-parity verification step + coder PREFLIGHT attestation) is the correct discipline-layer backstop for THIS BD.

**One caveat I attach:** because there is NO CI net, the planner's byte-parity verification step and the coder PREFLIGHT attestation are not optional niceties — they are the ONLY thing standing between a silent ×3 drift and the tree. The reconciliation/planner MUST make them HARD, NAMED steps (extract the new bullet from each of the three files; normalized-diff all three; PREFLIGHT line attesting byte-identity). The design already calls for this (§7.1, §10) — I am elevating it from "should" to "must, and it is load-bearing because it is the sole safeguard."

**Net:** §10.1 verdict — **deferral CORRECT; mitigation must be hard; "bitten twice" framing must be dropped as unsupported.**

---

## 4. Re-verification of the design's "NONE" conflict claims (§8)

I independently re-read each existing rule and re-tested the conflict claims:

| Existing rule | Design says | My verdict |
|---|---|---|
| Researcher-first pipeline (L288-296) | NONE — widens to internal+external, does not weaken architect-after-researcher | CONFIRMED NONE. The new rule's "optional researcher(s) (internal census and/or external)" is consistent; it does not reorder researcher↔architect. |
| Planner output → user review → coder spawn (L296-306) | NONE — identical gate | CONFIRMED NONE. The umbrella's "user planner-to-coder gate" is the same gate, referenced not restated. |
| Reconciliation-instance independence (L258-287) | NONE — umbrella does not name WHO reconciles | CONFIRMED NONE, with NIT-3 caveat (add a boundary sentence in the rationale so the conceptual adjacency is explicit). The new rule names the adversarial STAGES; this rule governs the fresh-instance reconciliation that follows — complementary, not contradictory. |
| Pack-architect spawn protocol (L556-569) | NONE — protocol gates the START, umbrella names the SHAPE | CONFIRMED NONE. |
| Bounded reviewer/fix cycle (L580-587) | NONE — cycle runs inside each worktree, bound unchanged | CONFIRMED NONE. |
| Worktree rules incl. rule 10 (Claude-only, L381+) | NONE — referenced generically, not parity-ported | CONFIRMED NONE. The Claude-only section is grep-zero in AGENTS/GEMINI and Trinity-exempt by documented design; the umbrella's generic "parallel worktree coder waves (off the rule-10 map)" is byte-identical ×3 and does not force a port. |

**All "NONE" conflict claims hold.** The one addition is NIT-3 (a clarifying boundary sentence vs the reconciliation rule), not a conflict.

---

## 5. Propagation completeness re-check (§5 — any encoding surface missed?)

I re-enumerated the encoding surfaces against the propagation procedure (PACK-CHAT.md L479-489) and the gating checks:

- **Check 45 (bijection):** requires the rationale section (row 2) — design HAS it. Bidirectional + mandatory — CONFIRMED required.
- **Check 46 (reference-resolution + anti-restate):** manifest record + references (rows 3-4) — design HAS them but they are ELECTIVE not mandated (MINOR-1).
- **Check 66 (concision):** new rule 1203 < 1300, and the rationale section's prose paragraphs are not `- ` bullets (uncapped) but any `- ` sub-bullet in the rationale must stay ≤1300 — design FLAGS this (§7.3). CONFIRMED handled.
- **Check 18 (H2 parity):** no new H2 — unaffected. CONFIRMED.
- **Check 36 (commit scope):** BD-238 is pack-only (no project-template touch, research §d) — the commit may carry `pack-only`. The design does not call this out in §5 but the research did. MINOR gap: §5 should note the commit-scope keyword choice.
- **Rationale bijection vs spawn-manifest are DIFFERENT sets** (Check 45 = all tagged slugs ⇄ rationale; Check 46 = curated manifest subset). The design's §5 conflates the necessity (treats both as required). This is the MINOR-1 finding.

**No MANDATORY encoding surface is missed.** The mandatory set (corpus ×3 + rationale section) is covered. The design ADDS elective surfaces (manifest + references) — over-inclusion, not omission. The one true omission is a §5 note on the Check-36 commit-scope keyword (NIT-grade).

---

## 6. Overall verdict

The design closes the two genuine gaps with a correctly-sized, cap-fitting, placement-feasible rule; the no-conflict analysis is sound; the §10.1 deferral is the right call. But it ships with a void anti-restate evidence block (MAJOR-1) and an un-measured size-tiering criterion that contradicts live precedent (MAJOR-2), plus over-scoped propagation framing (MINOR-1), wrong serial-verdict reasoning (MINOR-2), and a clarifying boundary omission (NIT-3). These are reconciliation-fixable; none defeats the design's purpose.

**VERDICT: NEEDS-REWORK (2 blocking/major)**

Required before the planner:
1. Fix MAJOR-1: replace EB-7 with the correct Check-46 anti-restate measurement (new-rule window absent from the 6 scan surfaces; references carry no 60+-char body) and retarget the planner's verification step to the scan surfaces.
2. Fix MAJOR-2: tighten L4 (or demote the L4-only consequence) so a single-clause amendment to an existing rule is not auto-LARGE-with-mandatory-adversarial; re-validate the criterion against BD-244 (→ SMALL/base-optional) and BD-243 (→ stays LARGE).
3. Fix MINOR-1: relabel §5 rows 3-4 as elective (no check mandates them); state the minimal green footprint is rows 1+2.
4. Fix MINOR-2: correct the §9 serial-verdict reasoning (atomic by discipline/auditability + end-state CI, not a per-commit gate); keep the SERIAL verdict.
5. Fix NIT-3 + the §10.1 framing: add the reconciliation-rule boundary sentence to the rationale spec; drop the unsupported "bitten twice" framing and re-state §10.1 as "discipline correct; mitigation is load-bearing because it is the sole safeguard."

---

## 7. Empirical-Evidence Blocks

**EB-A — Check 46 anti-restate scans surfaces, not trinity bodies (MAJOR-1).**
- Command: `Read scripts/validate-pack.py L7464-7494` (surface tuple + min-len) + `L7531-7566` (candidate extraction `normalized[:120]`) + `L7715-7742` (scan loop); plus a Python replication of candidate-extraction + substring scan over the 6 surfaces using the proposed rule's leading window.
- Output (verbatim, replication): `NEW rule leading-window candidate (<=120 chars, len=120): 'Pack-side BD development runs ONE official pipeline: optional researcher(s) (internal census and/or external docs verifi'` and for each of `pack-ops/PACK-AGENTS.md`, `pack-ops/PACK-CHAT.md`, `.claude/skills/{commit-discipline,review,planning,implementation-report}/SKILL.md`: `new-rule-window present? False`. Surface tuple verbatim: `_CHECK_46_ANTI_RESTATE_SURFACES = ("pack-ops/PACK-AGENTS.md","pack-ops/PACK-CHAT.md",".claude/skills/commit-discipline/SKILL.md",".claude/skills/review/SKILL.md",".claude/skills/planning/SKILL.md",".claude/skills/implementation-report/SKILL.md")`. Candidate extractor reads `corpus_path = REPO_ROOT / "CLAUDE.md"` and the scan haystack is each `surface` in that tuple — the trinity files are absent from the tuple.
- HEAD/date: `67078627…` / 2026-06-23.
- Interpretation: Check 46 anti-restate tests whether existing rule-body leading-windows leak into the 6 reference/skill surfaces — NOT whether the new rule body overlaps existing bodies (the property EB-7 measured). The new rule's window is absent from all 6 surfaces.
- Conclusion: SUPPORTED — EB-7 measures a check that does not exist; the real Check 46 passes for a different reason; the design's evidence must be replaced and the planner's verification retargeted to the 6 surfaces.

**EB-B — L4 over-classifies BD-244 (MAJOR-2).**
- Command: `Read backlog/BD-244.md` (Type + Resolved lines) + apply §3 L1-L4 to it.
- Output (verbatim): Type line — "Adds a facet to the existing `ci-guard-measure-then-bound` rule (pack-root trinity ×3)". Resolved line — "across the 3 pack-root trinity files + the `PACK-MEMORY-RATIONALE.md` … Converted the 2 verdict-bearing presence builders in `scripts/validate-pack.py` … Pipeline: pack-architect → pack-planner (...) → pack-coder → pack-reviewer (1 SHOULD: …Check 66's 1300-char cap) → fix-coder → post-fix reviewer CLEAN."
- HEAD/date: `67078627…` / 2026-06-23.
- Interpretation: BD-244 fires L4 (trinity-rule change) AND L2 (trinity + scripts/validators) → criterion says LARGE → mandatory two adversarial reviews + reconciliation. Actual pipeline was base flow (single reviewer, no adversarial, no reconciliation) and shipped clean.
- Conclusion: SUPPORTED — the criterion over-classifies a routine rule tweak that the base pipeline handled; L4 fires on every pack-memory rule edit; the LARGE tier as written dilutes to near-universal for pack-memory work. Measure-then-bound was not applied to the criterion itself.

**EB-C — spawn-rule-manifest is a curated 7-slug subset, not all-tagged (MINOR-1).**
- Command: `grep -c "^slug:" pack-ops/.spawn-rule-manifest.txt` ; `grep -c "^## " pack-ops/PACK-MEMORY-RATIONALE.md` ; `comm -23` of the two sets.
- Output (verbatim): manifest slug count = `7`; rationale heading count = `29`; rationale slugs NOT in manifest include `reconciliation-instance-independence`, `graph-first-context`, `spawn-unique-naming`, `enumerate-encoding-surfaces`, `empirical-evidence-blocks`, `ci-guard-measure-then-bound`, … (25 listed). Check 45 orphan logic: `orphan_corpus_slugs = sorted(corpus_set - rationale_set)` → FAIL if nonempty (L7401-7406).
- HEAD/date: `67078627…` / 2026-06-23.
- Interpretation: Check 46 validates only manifest records that exist; it does NOT require a record per tagged rule. Check 45 (bidirectional) DOES require a rationale section for the tagged slug. So mandatory surfaces = corpus ×3 + rationale section; manifest record + reference one-liners are elective.
- Conclusion: SUPPORTED — §5 rows 3-4 are design choices, not Check-mandated; design over-states their necessity.

**EB-D — CI is push-time end-state, not per-commit (MINOR-2).**
- Command: `grep "on:\|push:" .github/workflows/validate-pack.yml` ; `Read pack-ops/PACK-CHAT.md L471-489`.
- Output (verbatim): `.github/workflows/validate-pack.yml:103: on: push`. PACK-CHAT.md L472: "Update in the same commit as the structural change, or in the immediately following commit". L489: "Order is documented, not gate-sequenced: a commit is atomic; the propagation order is verified by END-STATE checks (bijection / anti-restate / trinity-parity / manifest), not a hard-enforced step sequence."
- HEAD/date: `67078627…` / 2026-06-23.
- Interpretation: a propagation split across commits within one push does not fail CI; the binding constraint on one-commit is the trinity rule + auditability discipline, not a CI gate. The SERIAL verdict is right; its stated reason is wrong.
- Conclusion: SUPPORTED — fix the §9 reasoning, keep the verdict.

**EB-E — no CI byte-compares pack-root `## Pack memory` bodies (§10.1 premise).**
- Command: `Read scripts/validate-pack.py` Check 18 body (L1623-1681, collects `line.startswith("## ")` only) + registry (L11354-11357, Check 18 runs at both project-template and pack-root) + Check 45 (`corpus_path = REPO_ROOT / "CLAUDE.md"`, L7359) ; `grep "This rule also applies" CLAUDE.md`.
- Output (verbatim): Check 18 `h2_lists[name] = [line.rstrip() for line in path.read_text().splitlines() if line.startswith("## ")]` (L1634-1638), compares `claude != agents` and `gemini_filtered != claude` (H2 lists only). Registry: `(18, "check_trinity_h2_parity[pack-root]", lambda: check_trinity_h2_parity(REPO_ROOT, "pack-root"), W)`. Check 45 corpus = CLAUDE.md sole. `CLAUDE.md:113-114: … This rule also applies to the pack-repo copies of these three files.`
- HEAD/date: `67078627…` / 2026-06-23.
- Interpretation: Check 18 at pack-root compares only H2 headings; Check 45 uses CLAUDE.md only; no body-parity check exists. The trinity rule obligation covers pack-repo copies but is discipline-enforced.
- Conclusion: SUPPORTED — the §10.1 premise is correct; the deferral verdict rests on a true gap that is discipline-bounded.

**EB-F — Check-66 char measurements (NIT-1).**
- Command: Python replication of `_check_66_iter_bullets` (whitespace-collapsed join) over the proposed rule body and over CLAUDE.md `## Pack memory` bullets.
- Output (verbatim): proposed rule `CHAR_LEN (Check-66 measure): 1203 … UNDER`; CLAUDE.md top bullets — `4275 Graph-first context`, `2426 Sub-agent isolation`, `2341 Pack Chat does MINOR edits`, `1260 Reconciliation-instance independence`, `1259 Agents never commit`, `1231 CI guard design — measure-then-bound`. Cap constant: `_CHECK_66_BULLET_CHAR_CAP = 1300` (L7989).
- HEAD/date: `67078627…` / 2026-06-23.
- Interpretation: new rule 1203 < densest non-allowlisted 1260 < cap 1300; over-cap rules are allowlisted.
- Conclusion: SUPPORTED — EB-4/EB-5 accurate; no Check-66 risk for the new rule.

**EB-G — placement anchors (NIT-2).**
- Command: `grep -n "Researcher-first pipeline\|Planner output → user review" CLAUDE.md AGENTS.md GEMINI.md`.
- Output (verbatim): `CLAUDE.md:288 / :296`, `AGENTS.md:277 / :285`, `GEMINI.md:249 / :257`.
- HEAD/date: `67078627…` / 2026-06-23.
- Interpretation: insertion after Researcher-first, before Planner output, is mid-`### Agent invocation rules` ×3 identical; adds no H2.
- Conclusion: SUPPORTED — design EB-2 exact; Check 18 unaffected.

**EB-H — adversarial re-baseline (design EB-1 re-confirmed).**
- Command: `grep -rn "adversarial" CLAUDE.md AGENTS.md GEMINI.md pack-ops/PACK-MEMORY-RATIONALE.md supporting-docs/`.
- Output (verbatim): `CLAUDE.md:271,273`, `AGENTS.md:261,263`, `GEMINI.md:234,236` (all inside `Reconciliation-instance independence`), `PACK-MEMORY-RATIONALE.md:661,663,672,679`; zero in supporting-docs.
- HEAD/date: `67078627…` / 2026-06-23.
- Interpretation: "adversarial" exists in-repo only via the reconciliation rule; the named size-tiered standard tier is still absent. The gap is intact; nothing to STRIP.
- Conclusion: SUPPORTED — design EB-1 accurate; new rule must coexist with (reference, not duplicate) the reconciliation rule (see NIT-3).

---

## 8. Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|---|
| 1 | **agents-never-commit** | Only Write = `/tmp/pack-handoff-bd238-arch/ADVERSARIAL-REVIEW-BD-238.md`. All git read-only: `git rev-parse HEAD` → `67078627…`, `git status --short` → ` M backlog/_toc.md` + `?? backlog/BD-245.md` (unrelated). No `add/commit/push/checkout/restore/stash/any` state-changing verb issued. No memory store read/written (user MEMORY PROHIBITION honored). | COMPLIANT |
| 2 | **reconciliation-instance-independence / fresh-agent-default** | I am a FRESH adversary; I did NOT author DESIGN-BD-238 and did not defer to its conclusions — I re-measured EVERY load-bearing claim independently (EB-A replicated the Check-46 algorithm and overturned EB-7; EB-B re-applied the criterion to BD-244 and overturned the implicit "criterion is fine" claim; EB-C re-counted the manifest set; EB-D re-read the CI trigger; EB-E/F/G/H re-confirmed). Two of the design's own conclusions are CONTRADICTED (MAJOR-1, MAJOR-2). | COMPLIANT |
| 3 | **empirical-evidence-blocks** | §7 EB-A…EB-H: every finding backed by command + verbatim output + HEAD `67078627…`/date + interpretation + SUPPORTED conclusion. Each MAJOR/MINOR cites its EB. No finding rests on assertion alone. | COMPLIANT |
| 4 | **ci-guard-design-measure-then-bound** | Applied to BOTH judgment targets: (a) the size-tiering criterion — I MEASURED it against the precedent set (BD-244 LARGE-but-base-sufficient, BD-243 correctly LARGE) and found the L4 over-trigger (MAJOR-2), the exact measure-then-bound step the design skipped; (b) the §10.1 parity-check question — I measured the actual checks (EB-E: Check 18 H2-only, Check 45 CLAUDE-only) and the precedent (BD-244 "trinity-parity-is-discipline" resolved 3 days prior) before ruling the deferral correct. | COMPLIANT |
| 5 | **operating-docs-no-history-no-bloat** | Judged the rule text against it: 1203 chars (EB-F) under the 1300 cap; zero history/dates/provenance in the proposed body; terse + structured. Flagged the design's UNSUPPORTED "bitten twice" framing (§3 verdict) which, if copied anywhere operational, would be exactly the history-as-justification this rule forbids. | COMPLIANT |
| 6 | **deferral-is-scope-creep / no-deferral-without-user-direction** | Scrutinized the §10.1 deferral against SIZE/BLOCKED/LOGICAL-FIT: ruled it a VALID deferral (distinct contract — body-parity vs chaining/tiering; non-trivial CI-guard design with the Claude-only/GEMINI-intrinsic normalization problem; re-litigating a 3-day-old resolved call without new evidence is unwarranted). NOT a weak deferral. Separately flagged MINOR-1 (the design ADDS elective surfaces rather than deferring required ones — over-inclusion, the opposite failure, also surfaced). | COMPLIANT |
| 7 | **rules-applied-verification-block** | This table — rules 1-7, each with (a) name, (b) quoted evidence, (c) terminal conclusion (no AMBIGUOUS, no empty evidence). | COMPLIANT |

---

*End of ADVERSARIAL-REVIEW-BD-238. Fresh independent adversarial architect pass; one Write (this doc) under /tmp; read-only git only; no memory store used. VERDICT: NEEDS-REWORK (2 major).*
