# DESIGN-BD-238-RECONCILED — PACK-SIDE large-BD pipeline standard (size-tiered), reconciled

**Role:** pack-architect (RO), FRESH independent RECONCILER. Did NOT author DESIGN-BD-238; am NOT the adversarial reviewer. **BD:** BD-238 (LARGE; user-confirmed 2026-06-23). **Output:** this reconciled design only (sole Write, under `/tmp`). **Next stage:** planner. This doc carries the FULL design (not a diff) so the planner reads ONE coherent doc.

---

## 0. Runtime regime (RO; verified)

| Field | Value |
|---|---|
| `pwd` | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev` |
| `git rev-parse HEAD` | `67078627327d70f30d89d0f8500eb6e91993cffd` (= expected `6707862`) |
| branch | `v11-dev` |
| `git status --short` | ` M backlog/_toc.md` + `?? backlog/BD-245.md` — both UNRELATED to BD-238; I touch neither. The BD-238 work I reconcile is the uncommitted `/tmp` design + adversarial review; the live tree is at HEAD `6707862`. |
| graph | queried for DISCOVERY; operating-doc rules are not node-indexed (prior passes established this) → grep/Read for VERIFICATION (G2 fallback, sanctioned). |
| writes | EXACTLY ONE: this reconciled doc. No source edits. Read-only git only. No memory store read/written (user MEMORY PROHIBITION 2026-06-23 honored). |

---

## 1. Reconciliation summary

The adversarial review returned **NEEDS-REWORK (2 major)**. I independently re-measured every load-bearing claim and resolved each finding from evidence:

- **MAJOR-1 RESOLVED (anti-restate evidence retargeted).** The original EB-7 tested a property Check 46 never evaluates (a trinity-vs-trinity body-overlap diff). I read the actual Check 46 algorithm and re-stated the evidence correctly: Check 46 scans 6 fixed surfaces (PACK-AGENTS.md, PACK-CHAT.md, + 4 skills) for existing-rule-body leading-windows; the planner's verification step now targets those 6 surfaces + the two NEW reference one-liners this BD adds. (§7.2, EB-R1.)
- **MAJOR-2 RESOLVED (size-tiering criterion re-designed + measured against precedent).** The original criterion's structural signal fired on ANY rule edit, forcing BD-244-class work into LARGE-with-mandatory-adversarial. I demoted the consequence: a single non-launch signal alone does NOT mandate the adversarial passes; LARGE-with-mandatory-adversarial requires **launch-gate (alone) OR ≥2 signals.** Measured: this classifies **BD-244 = SMALL/base-flow** (one existing-rule clause amend) and **BD-243 = LARGE** (new rule + new CI checks + cross-surface + required census). The user-elective SMALL tier is preserved. (§3, EB-R2/EB-R3.)
- **MINOR (propagation rows) RESOLVED.** §5 rows 3-4 (manifest record + reference one-liners) re-labeled ELECTIVE (discoverability); only corpus ×3 + the rationale section are MANDATORY (Check 45 bidirectional bijection). (§5, EB-R4.)
- **MINOR (rule-10 reason) RESOLVED.** SERIAL verdict kept; rationale corrected — CI is `on: push` end-state, not per-commit; the serialization reason is propagation-atomicity (corpus + rationale same commit) + auditability discipline, not a CI gate. (§9, EB-R5.)
- **§10.1 (parity CI check) — DEFERRAL KEPT.** No new pack-root body-parity CI check in BD-238 (both prior architects agree; separate structural BD). The planner byte-parity verification step + coder PREFLIGHT ×3-byte-identity attestation are elevated to HARD, NAMED steps — the SOLE safeguard for pack-root trinity parity. The unsupported "bitten twice" framing is dropped. (§10.)
- **NIT-3 RESOLVED.** A one-sentence boundary note (umbrella NAMES the adversarial stages; `reconciliation-instance-independence` governs the fresh-instance reconciliation that follows) is added to the rationale-section spec. (§5 row 2.)

**Carried forward unchanged (adversary CONFIRMED accurate):** the re-baseline (§2, EB-1/EB-H — "adversarial" now lives in-repo via the reconciliation rule; gap intact; nothing to STRIP); placement anchors (§4.1, EB-G — CLAUDE.md 288/296, AGENTS.md 277/285, GEMINI.md 249/257); parity-is-discipline premise (§7.1, EB-E — Check 18 = H2 headings only, Check 45 = CLAUDE.md-representative, no body-parity check); the six NONE conflict claims (§8). The rule body is RE-WORDED for MAJOR-2 and re-measured at **1289 chars < 1300** (EB-R6).

---

## 2. Re-baselined measure-then-bound (carried forward — adversary confirmed)

BD-238 File/Symbol claims `grep -rln adversarial …` = NO matches at HEAD `62805a8`. **That baseline is STALE.** Re-measured at the live HEAD (EB-1):

- "adversarial" NOW appears in trinity ×3 (`CLAUDE.md:271,273` / `AGENTS.md:261,263` / `GEMINI.md:234,236`) and `PACK-MEMORY-RATIONALE.md:661,663,672,679` — **ALL inside the existing `reconciliation-instance-independence` rule + its rationale**, never as a standalone "adversarial review standard."
- The premise "adversarial is undocumented in-repo" is now **PARTIALLY satisfied**: the WORD entered via the reconciliation rule, but the adversarial review as a NAMED, SIZE-TIERED standard TIER is still absent. The gap BD-238 closes is intact; the edit-LOCATION set is unchanged.

**Bound (KEEP/STRIP):** every live "adversarial" occurrence is KEEP (legitimate — part of the reconciliation rule). NOTHING to STRIP. The new rule must COEXIST with the reconciliation rule (reference it; never duplicate the word's meaning). The design ADDS occurrences (the new umbrella rule + rationale), removes none.

---

## 3. The size-tiering criterion — REVISED (MAJOR-2 fix; measured against precedent)

### 3.1 The defect the adversary found (confirmed)

The original criterion (§3 of DESIGN-BD-238) made a BD LARGE — and thereby MANDATED the two adversarial reviews + reconciliation — if ANY of four signals fired, where the structural signal explicitly included "a trinity rule change." That structural signal fires on EVERY pack-memory rule add/change (every such BD is architect-first). So nearly every pack-memory BD would be LARGE-with-mandatory-adversarial, swallowing the SMALL tier the BD-238 premise explicitly demands ("the two adversarial reviews + reconciliation OPTIONAL (user-elective) for SMALLER BDs"). The criterion was DECLARED but never MEASURED against precedent — a measure-then-bound violation. I confirmed it against the immediately-prior pack-memory BD (BD-244): the original criterion classifies BD-244 LARGE, yet BD-244 shipped clean on the BASE (non-adversarial) pipeline (EB-R2).

### 3.2 The revised criterion (measure-then-bound, two-part: SIGNALS then CONSEQUENCE)

Keep the four coarse signals as a yes/no filter, but **decouple the consequence from any single signal.** The fix is the adversary's option (b) — demote the single-signal consequence — because it preserves the cheap-base-flow purpose AND keeps an objective, audit-clear test.

**Four size signals (each a yes/no test against repo state or the BD entry — not a vibe):**

| # | Signal | Concrete test (fires = yes) |
|---|---|---|
| L1 | **Launch-gate** | The BD's `Target:`/`Position:` marks it a launch blocker for the current major, or the user names it launch-gating. |
| L2 | **Cross-surface** | The BD's edit-set spans ≥2 of: trinity `## Pack memory` · `pack-ops/` operating docs · `scripts/`+validators · `project-template/` product · agent/skill definitions. (Measured from the BD's File/Symbol census.) |
| L3 | **Blast-radius** | The BD changes a rule/contract/validator that ≥3 surfaces ENCODE (per `enumerate-encoding-surfaces`), OR a researcher blast-radius census is REQUIRED before design. |
| L4 | **Structural** | The BD adds a **NEW** convention, a **NEW or changed** CI check, a file-tree-shape change, a migration path, or a **NEW** rule. (Note the tightening: amending a CLAUSE of an EXISTING rule, with no new check/convention/tree change, does NOT fire L4.) |

**The CONSEQUENCE rule (the demotion — this is the MAJOR-2 fix):**

> A BD is **LARGE — the two adversarial reviews + reconciliation are the MINIMUM** — iff **L1 (launch-gate) fires alone, OR ≥2 of the four signals fire.**
>
> Otherwise the BD runs the **base flow** (optional researcher → architect → planner → coder + the bounded review/fix cycle); the two adversarial passes + reconciliation are **OPTIONAL at user election.** A single non-launch signal alone (e.g. a one-clause amend to an existing rule) does NOT mandate them.
>
> **Tie-break:** when genuinely in doubt between base-flow and mandatory-adversarial, treat as LARGE (the rigor is the conservative error). This mirrors the existing "when in doubt … it is MAJOR" disposition in the `pack-chat-minor-edits-only` rule.

**Why launch-gate stands alone:** a launch blocker is the one axis where a missed adversarial pass is irrecoverable (it ships into the cut). Every OTHER signal alone is recoverable at base-flow rigor (BD-244 proved this empirically). This is the measure-then-bound bound: calibrate the mandatory-adversarial trigger to the cost of being wrong, not to the mere presence of a structural touch.

### 3.3 Validation against precedent (EB-R2, EB-R3)

**BD-244** ("Adds a facet to the existing `ci-guard-measure-then-bound` rule", Resolved 2026-06-23 on the BASE pipeline — `pack-architect → pack-planner → pack-coder → pack-reviewer → fix-coder → post-fix reviewer CLEAN`; ZERO adversarial passes; CI green):

| Signal | Fires? | Why |
|---|---|---|
| L1 launch-gate | NO | "small Pack-memory rule strengthening," not a launch blocker. |
| L2 cross-surface | YES | trinity `## Pack memory` + `scripts/validate-pack.py` (2 builder conversions) + tests = ≥2 families. |
| L3 blast-radius | NO | A targeted clause amend + 2 builder conversions; no required pre-design census (the in-BD census of file-enumeration sites is part of the rule's own application, not a researcher blast-radius gate). |
| L4 structural | NO (under the tightened L4) | Amends a CLAUSE of an EXISTING rule; adds NO new convention, NO new CI check (converts 2 existing builders), NO tree change, NO new rule. |

**Signals fired: L2 only (1).** Launch-gate did not fire. **→ Classification: base flow; adversarial OPTIONAL = SMALL.** This MATCHES BD-244's actual clean shipment on the base pipeline. ✓

**BD-243** ("STRUCTURAL cross-surface cleanup … adds ONE forward-looking governance rule … Large-BD standard … with adversarial passes", Resolved 2026-06-23 on the FULL pipeline — `docs-researcher → architect (+ adversarial) → planner (+ adversarial) → coder waves → reviewer`; 4 adversarial mentions; 16 commits; 7 new durable CI checks 65-71):

| Signal | Fires? | Why |
|---|---|---|
| L1 launch-gate | NO (not strictly) | "active priority while BD-206 paused"; not formally a hard launch gate. |
| L2 cross-surface | YES | trinity ×6 (pack + project) + `pack-ops/` + skills + agents + `scripts/` (7 new checks) = ≫2 families. |
| L3 blast-radius | YES | Required a docs-researcher 136-doc taxonomy census BEFORE design; changed a governance contract ≥3 surfaces encode. |
| L4 structural | YES | Adds a NEW rule (`operating-docs-no-history-no-bloat`) AND 7 NEW CI checks. |

**Signals fired: L2 + L3 + L4 (3).** ≥2 ⇒ **LARGE — mandatory adversarial.** This MATCHES BD-243's actual full-adversarial pipeline. ✓

**BD-238 itself** (this BD): L2 (trinity + pack-ops + manifest/rationale) + L4 (adds a NEW rule + a NEW `[rationale:]` slug). Signals fired = 2 ⇒ **LARGE — mandatory adversarial.** Consistent with the user's 2026-06-23 confirmation that BD-238 runs the full pipeline. ✓

**Conclusion:** the revised criterion classifies the precedent set correctly — BD-244 SMALL, BD-243 LARGE, BD-238 LARGE — and preserves the user-elective SMALL tier (a single structural/cross-surface signal no longer forces the heavyweight pipeline). A single "trinity-rule change" signal no longer triggers LARGE-with-mandatory-adversarial; only launch-gate-alone or ≥2-signals do.


---

## 4. The exact rule text (operating-doc style) + placement

### 4.1 The new umbrella rule — trinity `## Pack memory` `### Agent invocation rules`

**Placement (byte-identical ×3):** insert as a NEW bullet IMMEDIATELY AFTER the `Researcher-first pipeline for substantive content` rule and BEFORE `Planner output → user review → coder spawn`, so the chain reads in pipeline order. Exact anchor lines (EB-G, re-confirmed at live HEAD):

| File | Insert after (Researcher-first bullet) | Before (Planner-output bullet) |
|---|---|---|
| `CLAUDE.md` | L288 (Researcher-first starts) | L296 (`Planner output …`) |
| `AGENTS.md` | L277 | L285 (`Planner output …`) |
| `GEMINI.md` | L249 | L257 (`Planner output …`) |

**Rule text (the canonical body; byte-identical ×3 — fits the Check-66 1300-char cap; measured 1289 chars, EB-R6):**

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

**Body length: 1289 chars (whitespace-collapsed, the exact Check-66 measure) — UNDER the 1300 cap; no `.bullet-concision-allowlist.txt` record needed (verified EB-R6). Anti-restate-safe: the body's leading-120 window is absent from all 6 Check-46 scan surfaces (verified EB-R1).** The rule references each stage's own `## Pack memory` rule by category ("its own `## Pack memory` rule") rather than enumerating slugs inline — terse AND avoids reproducing any existing rule body.

**Design notes on the wording (vs the original):**
- The ONLY semantic change vs DESIGN-BD-238's body is the size-tiering clause: signals are listed, then the CONSEQUENCE is decoupled ("LARGE … if launch-gate fires OR ≥2 signals fire; else the base flow … (one non-launch signal alone … does NOT mandate them)"). This is the MAJOR-2 fix carried into the rule text.
- L4's structural list now says "a NEW convention, NEW/changed CI check, tree shape, migration, or a NEW rule" — the tightening that excludes a single-clause amend to an existing rule.
- ZERO history/provenance/dates (operating-docs-no-history-no-bloat). No "BD-237 ran it," no dated notes.
- `[roles: universal]` + `[rationale: large-bd-pipeline-standard]` satisfy the controlled-vocab + bijection gates.
- The Claude-only worktree-wave step is expressed GENERICALLY ("parallel worktree coder waves … off the rule-10 map") — byte-parity-safe ×3 because it REFERENCES the rule-10 map (itself Claude-only + Trinity-exempt) rather than RESTATING the worktree mechanics. (§8.2.)

### 4.2 The consolidated lifecycle anchor — `pack-ops/PACK-CHAT.md`

The orchestrator lifecycle the standard's step 8 needs ALREADY EXISTS in full at `pack-ops/PACK-CHAT.md` § "In-session sub-agent spawn + merge-back (worktree isolation)" (How-Pack-Chat-spawns, Merge-back, the Parallelization map (rule 10) prose, the Conflict protocol, Report preservation / audit-set). **Do NOT duplicate it.** Add a short consolidating ANCHOR at the TOP of that section (a 2-4 line pointer) framing the section as "the execution half of the large-BD pipeline standard," with a one-line reference to the trinity rule.

**Placement:** insert a sub-paragraph immediately under the H2 `## In-session sub-agent spawn + merge-back (worktree isolation)`, before the existing intro paragraph.

**Text:**
```
This section is the EXECUTION half of the large-BD pipeline standard
(trinity `## Pack memory` `[rationale: large-bd-pipeline-standard]`): it is
the orchestration the standard's step 8 (parallel worktree coder waves)
runs. The DESIGN half (researcher → architect → adversarial → reconciliation
→ planner → adversarial → user gates) is the trinity rule chain.
```

This is a one-line REFERENCE (no verbatim restatement of the canonical body), anti-restate-safe (Check 46) — verified EB-R1: the anchor carries zero existing-body leading-windows. It introduces NO new lifecycle content. **NOTE (MINOR-1):** this surface is ELECTIVE (discoverability), NOT Check-mandated — see §5.

### 4.3 The roster cross-reference — `pack-ops/PACK-AGENTS.md`

`pack-ops/PACK-AGENTS.md` § "Pack agents" (the roster + Class column) is where the pipeline stages route to agents. Add a single one-line pointer beneath the roster (or in its lead-in) naming the standard and its trinity home:

**Text (one line):**
```
The order these agents run in is the large-BD pipeline standard — see
trinity `## Pack memory` `[rationale: large-bd-pipeline-standard]`.
```

Anti-restate-safe (a pointer, not the body) — verified EB-R1: zero existing-body leading-windows. **NOTE (MINOR-1):** ELECTIVE (discoverability), NOT Check-mandated — see §5.

---

## 5. The propagation surface set — MANDATORY vs ELECTIVE (MINOR-1 fix)

The rule-change propagation procedure (`pack-ops/PACK-CHAT.md` § "Keeping CLAUDE.md, AGENTS.md, GEMINI.md, and PACK-AGENTS.md current", the 6-row table) governs the surfaces + order. The MINOR-1 finding (confirmed, EB-R4): only **corpus ×3 + the rationale section** are MANDATORY for a new tagged rule (Check 45 bidirectional bijection FAILs on an orphan corpus slug OR an orphan rationale heading); the manifest record + reference one-liners are **ELECTIVE** (Check 46 validates only manifest records that EXIST — it does NOT require a record per tagged rule; the manifest is a CURATED 7-slug subset of 29 tagged rules).

| Order | Surface | Exact edit | Mandatory? | Gating check |
|---|---|---|---|---|
| 1 | **Corpus ×3 trinity** — `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` `## Pack memory` `### Agent invocation rules` | Insert the §4.1 umbrella bullet, byte-identical, after Researcher-first (CLAUDE.md L288 / AGENTS.md L277 / GEMINI.md L249) | **MANDATORY** | Check 45 bijection (CLAUDE.md slug must map); Check 66 cap (1289 < 1300); Check 18 H2-parity (structure only — unaffected) |
| 2 | **`pack-ops/PACK-MEMORY-RATIONALE.md`** | Add a `## large-bd-pipeline-standard` section (Why / How / Rejected alternative — model on the `## reconciliation-instance-independence` entry). **Include the NIT-3 boundary sentence** (below). | **MANDATORY** | Check 45 bijection (slug-set equality vs CLAUDE.md); Check 66 (any `- ` sub-bullet ≤1300) |
| 3 | **`pack-ops/.spawn-rule-manifest.txt`** | Add a record: `slug: large-bd-pipeline-standard` / `canonical: ## Pack memory` / `corpus: ### Agent invocation rules — "Large-BD pipeline standard (size-tiered)"` / `references: PACK-AGENTS.md § "Pack agents"; PACK-CHAT.md § "In-session sub-agent spawn + merge-back"` | **ELECTIVE** (discoverability; no check requires a manifest record per tagged rule) | Check 46 reference-resolution (only IF this record is added: every named reference surface must exist + carry the `## Pack memory` pointer) |
| 4 | **Reference one-liners** — `pack-ops/PACK-AGENTS.md` (§4.3) + `pack-ops/PACK-CHAT.md` (§4.2) | Add the two one-line references named in the manifest record | **ELECTIVE** (only required IF row 3 names them; chosen for discoverability) | Check 46 reference-resolution + anti-restate (no ≥60-char verbatim body — verified clean EB-R1) |
| 5 | **Out-of-repo thin memory-cache pointer** | Pack-Chat upkeep: update the two adversarial-memory entries (§6) | N/A (no validator; trinity-wins) | none |
| 6 | `test-fixtures/manifest.txt` | NOT a propagation step. No agent-def/skill FIXTURE input changes here. Push-time `manifest-sync.sh` reconciles | N/A | CI `build.sh --verify` + Check 62 (push-time only) |

**Minimal green footprint:** rows 1 + 2 ONLY. Rows 3-4 are an elective discoverability bundle (recommended — the pipeline ORDER genuinely lives in PACK-AGENTS/PACK-CHAT, so the references aid a fresh session — but the planner/user may drop them to minimize footprint, and validate-pack stays green either way). The original design over-stated rows 3-4 as Check-mandated; this is corrected.

**NIT-3 boundary sentence (add to the row-2 rationale section):**
> "The umbrella NAMES the adversarial stages; `reconciliation-instance-independence` governs the fresh-instance reconciliation that follows a NEEDS-REWORK verdict — complementary, not overlapping."

**Spawn-rule-manifest decision (carried forward): ONE new umbrella slug, NOT re-tagging the three untagged rules.** The three existing pipeline rules (researcher-first, pack-architect-spawn, planner-to-coder) carry NO `[rationale:]` tag today. Re-tagging them would force new bijection rows + rationale sections for rules that already work untagged — scope creep beyond BD-238's ask (codify the CHAIN + tiering). The umbrella slug REFERENCES them by name in its body without requiring them tagged. **Bound:** exactly ONE new slug, ONE new rationale section, and (electively) ONE manifest record + two reference one-liners.

### 5.1 Surfaces explicitly NOT touched (with evidence)

Per `enumerate-encoding-surfaces`, the surfaces that do NOT encode the standard and stay untouched:

- **Pack agent defs** (`.claude` / `.codex` / `.agents-plugin` `pack-{architect,coder,docs-researcher,planner,reviewer}.md`) — grep-zero for pipeline-stage vocab (research B3). An OPTIONAL one-line pointer is NOT added (it would create 5×3=15 parity-maintained edits + Check 52 re-verification, for marginal value). DECISION: do NOT touch agent defs.
- **Pack skills** (11 skills ×3 mirrors) — grep-zero for the chain/tiering (research B4). The 4 spawn-relevant skills (`commit-discipline`, `review`, `planning`, `implementation-report`) are anti-restate TARGETS (Check 46) — they must NOT receive the canonical body. DECISION: do NOT add the rule body to any skill.
- **`pack-ops/DRY-RUN-MIGRATION.md` + `MERGE-STRATEGY.md`** — their "reconciliation" hits are the migrator file-merge state, NOT the pipeline (research B2). Out of blast radius. DECISION: do NOT touch.

### 5.2 Commit-scope keyword (NIT from the adversary's §5)

The BD-238 commit set is PACK-ONLY (no `project-template/` touch; research §d disjointness proof). The C1 + C3 commit subjects MAY carry the `pack-only` Check-36 keyword. The C2 step is out-of-repo memory upkeep (no commit). The planner should note the `pack-only` keyword choice in the commit-scope plan.


---

## 6. Reconciling the two out-of-repo adversarial memories

The two out-of-repo Pack-Chat memories are reconcile-TARGETS (not repo edits; no validator gates them; trinity-wins on any conflict). Locations (research B6):
```
/Users/david/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/
  feedback_adversarial_architect_review_on_major_gap.md
  feedback_adversarial_planner_review_major_plans.md
```

**NOTE on the MEMORY PROHIBITION:** the user's 2026-06-23 prohibition forbids ME (this reconciler agent) from reading/writing any memory store during THIS task. It does NOT forbid the BD-238 IMPLEMENTATION from reconciling these out-of-repo memory FILES — that is the BD's acceptance-criteria work, performed by Pack-Chat memory upkeep, not by a spawned agent's memory tool. I do not read these files; I specify the reconciliation from the research census (research B6) + the BD-238 acceptance criteria. The actual edit is a Pack-Chat upkeep step (§9 C2), gated by no validator.

**Reconciliation (Pack-Chat memory upkeep, step 5 of §5):** edit each memory's body to OPEN with a one-line pointer to the in-repo standard and reframe its situational guidance as a SUBORDINATE detail of the standard's adversarial tier:

- `feedback_adversarial_architect_review_on_major_gap` → prepend: "SUBORDINATE to the in-repo `large-bd-pipeline-standard` (trinity `## Pack memory`): the adversarial ARCHITECT review is the MINIMUM for a LARGE BD (not only 'on a major gap'). This memory adds the major-gap escalation detail. Trinity wins on any conflict."
- `feedback_adversarial_planner_review_major_plans` → prepend: "SUBORDINATE to the in-repo `large-bd-pipeline-standard`: the adversarial PLANNER review is the MINIMUM for a LARGE BD. This memory adds the major-plan detail. Trinity wins."

**Why reconcile rather than delete:** the standard makes the adversarial passes the large-BD MINIMUM (broader than "situational"); the two memories carry useful ESCALATION detail (when to add MORE rounds on a major gap / major plan) that the terse trinity rule intentionally omits (operating-docs-no-history-no-bloat). Pointing them at the standard removes the contradiction (situational vs minimum) while preserving the detail in the reference layer. **Trinity-wins** is stated explicitly in each, so a fresh session that reads only the memory is redirected to the SSOT.

**Index pointer:** the pack-side MEMORY.md index entries for these two files (listed under "Design discipline") get their one-line pointers updated to note the subordination. (Pack-Chat upkeep; no validator.)

---

## 7. Pack-root trinity parity-enforcement + gate fit

### 7.1 What enforces pack-root trinity `## Pack memory` parity (carried forward — adversary confirmed, EB-E)

Re-measured at the live HEAD:

- **Check 16** (`## Project addenda` H2) is pack-root-EXEMPT (short-circuits via `_CHECK_16_EXEMPT_SURFACES`). Correct — it gates a client-reconciliation mechanism with no purpose at pack-root.
- **Check 18** (H2 structure parity) RUNS at pack-root, BUT it compares ONLY `## ` heading LINES (`line.startswith("## ")`) — it asserts the three files share the same H2 set/order, NOT that the `## Pack memory` BODY is byte-identical.
- **Check 19** (no body scaffolding) RUNS at pack-root but only forbids stray HTML comments.
- **Check 45** bijection uses CLAUDE.md as the SOLE representative corpus (`corpus_path = REPO_ROOT / "CLAUDE.md"`); AGENTS/GEMINI slugs are not bijection-checked.
- **Check 66** caps each file's bullets independently but does not cross-compare.

**CONCLUSION — there is NO CI check that byte-compares the pack-root `## Pack memory` rule BODIES across CLAUDE/AGENTS/GEMINI.** Pack-root trinity body parity is a DISCIPLINE (the trinity-rule, which explicitly covers "the pack-repo copies of these three files," CLAUDE.md L113-114), not an auto-caught CI invariant. This is the load-bearing premise for §10.1.

### 7.2 Check 46 anti-restate — the CORRECT property (MAJOR-1 fix)

**What Check 46 anti-restate ACTUALLY does** (read at `scripts/validate-pack.py` L7469-7494, L7531-7566, L7715-7742):

1. It extracts **candidate needles** = the leading-120-char window (kept iff ≥60 chars) of every existing CLAUDE.md `## Pack memory` rule BODY (`_check_46_extract_pack_memory_imperative_bodies`; `normalized[:120]`).
2. It searches for those needles inside the **6 fixed haystack SURFACES** (`_CHECK_46_ANTI_RESTATE_SURFACES`):
```
pack-ops/PACK-AGENTS.md
pack-ops/PACK-CHAT.md
.claude/skills/commit-discipline/SKILL.md
.claude/skills/review/SKILL.md
.claude/skills/planning/SKILL.md
.claude/skills/implementation-report/SKILL.md
```

**The trinity files are NOT in the scan-surface set.** Check 46 NEVER compares the new rule body against existing rule bodies (the property the original EB-7 measured — that test was methodologically void, though its conclusion happened to be right). The REAL anti-restate risk for BD-238 is the two NEW reference surfaces this BD adds (§4.2 PACK-CHAT.md anchor, §4.3 PACK-AGENTS.md one-liner): if either reproduced a 60+-char existing-rule-body leading-window, Check 46 would FAIL.

**The CORRECT measurement (EB-R1):** (a) the NEW rule's leading-120 window is ABSENT from all 6 scan surfaces (so adding the rule to the trinity cannot trip the check — and the trinity isn't scanned anyway); (b) BOTH new reference one-liners (§4.2/§4.3), normalized, contain ZERO of the 53 existing-rule-body leading-windows. **→ Check 46 anti-restate PASSES post-implementation.**

**The planner's verification step (MAJOR-1 retarget):** after authoring the two reference one-liners, the planner/coder MUST verify them against the 6 `_CHECK_46_ANTI_RESTATE_SURFACES` — i.e. confirm neither one-liner contains a 60+-char leading-window of ANY existing `## Pack memory` rule body. This replaces the original's mis-targeted trinity-vs-trinity diff. The practical check: run `validate-pack` Check 46 (it does exactly this); a one-line reference of the form `<name> — see trinity \`## Pack memory\` \`[rationale: <slug>]\`` is the safe shape (it names + paraphrases, never restates a body).

### 7.3 Check 18 H2-parity is satisfied automatically

The new rule is a BULLET inside the EXISTING `### Agent invocation rules` subsection under the EXISTING `## Pack memory` H2. It adds NO new `## ` heading. Check 18 (H2 set/order) is unaffected ×3.

### 7.4 Check 66 bullet-concision fit (carried forward, re-measured for the revised body)

Check 66 caps each top-level `- ` bullet (rule + 2-space continuation lines, whitespace-collapsed) at **1300 chars** (`_CHECK_66_BULLET_CHAR_CAP = 1300`) over `(CLAUDE.md, AGENTS.md, GEMINI.md @ ## Pack memory)` + `PACK-MEMORY-RATIONALE.md`. The densest existing legitimate rule (`reconciliation-instance-independence`) = 1260 chars.

**The §4.1 revised rule body measured whitespace-collapsed (EB-R6): 1289 chars — UNDER the 1300 cap.** No allowlist record needed. (The MAJOR-2 re-wording first measured 1330 over cap; trimming the consequence clause + relocating the "more rounds on larger gaps" detail to the rationale section brought it to 1289 — the measure-then-bound reduction path, option (a), not an allowlist hole.) If the planner expands the wording past 1300, the options are (a) reduce (move detail to the rationale section — preferred), or (b) add a `.bullet-concision-allowlist.txt` record with a reviewer-verified reason. The design TARGETS option (a).

**Continuation-line discipline:** the body uses 2-space-indented continuation lines so `_check_66_iter_bullets` joins it as ONE bullet. The PACK-MEMORY-RATIONALE.md `## large-bd-pipeline-standard` section's Why/How/Rejected paragraphs are prose (not `- ` bullets, so uncapped), but any `- ` sub-bullet inside must stay ≤1300.

---

## 8. No-conflict analysis vs existing trinity rules (carried forward — all six NONE confirmed by the adversary)

The umbrella standard CONSOLIDATES and ORDERS the existing rules; it must not CONTRADICT any. Per-rule analysis:

### 8.1 The five pipeline rules — REFERENCED, not overridden

| Existing rule | Relationship | Conflict? |
|---|---|---|
| **Researcher-first pipeline for substantive content** | The standard's optional-researcher step + base chain spine; widens "researcher" to internal+external. | NONE — does not reorder researcher↔architect; does not weaken "architect runs AFTER researcher." |
| **Planner output → user review → coder spawn** | The standard's user planner-to-coder gate. | NONE — identical gate, referenced not restated. |
| **Reconciliation-instance independence** | The standard's reconciliation rounds use a FRESH instance per round; the standard cites this rule as the round's governing rule. | NONE — the umbrella NAMES the adversarial STAGES; this rule governs WHO reconciles. Complementary (NIT-3 boundary sentence makes the adjacency explicit in the rationale). |
| **Pack-architect spawn protocol** | The standard's architect-first framing + the multi-stage pipeline commitment; the protocol's "architect-spawn requires user approval" governs entry INTO the standard. | NONE — the protocol gates the START; the standard names the SHAPE. |
| **Pack Chat NO coder review; bounded reviewer/fix cycle** | The standard's step-8 per-commit cycle (≤2 review/fix pairs + 1 final), run INSIDE each worktree. | NONE — the bound (2+1) is unchanged. |

### 8.2 The worktree rules incl. rule 10 — Claude-only, referenced not parity-ported

The worktree mechanics + **Parallelization map (rule 10)** live ONLY in `CLAUDE.md` `### Sub-agent behavior (Claude-only)` — grep-zero in AGENTS/GEMINI (research B1, EB-6). This section is **Trinity-exempt by documented design** (CLAUDE.md: "not mirrored in AGENTS.md / GEMINI.md because its rules are built against Claude Code's Agent-tool mechanism").

**Resolution:** the umbrella rule (parity ×3) expresses step 8 GENERICALLY as "parallel worktree coder waves (off the rule-10 map …)". This phrase is byte-IDENTICAL across the three files (it references the rule-10 map; it does not restate the worktree mechanics), and does NOT force a parity port of the Claude-only section (a port would VIOLATE the documented Trinity-exemption). For AGENTS/GEMINI readers, "worktree coder waves" maps to their platform's native parallel-spawn; their worktree story is a future pack version. **No conflict.**

### 8.3 Conflict protocol + audit-set + report preservation — already in PACK-CHAT.md

The standard's "patches applied sequentially under the conflict protocol; superseded docs deleted; audit set preserved" maps 1:1 to PACK-CHAT.md § Conflict protocol + Report preservation / Constraint 3. The umbrella rule references these via the §4.2 PACK-CHAT.md anchor. No new lifecycle content; no conflict.


---

## 9. Rule-10 parallel/dependency map for the BD-238 implementation (MINOR rule-10-reason fix)

Per rule 10, this design produces the parallel-vs-dependent map for the implementation commits.

### 9.1 The commits

| Commit | Scope | Same-file overlap | Parallel/serial |
|---|---|---|---|
| **C1** (the standard) | Corpus ×3 trinity (§4.1) + `PACK-MEMORY-RATIONALE.md` (row 2, MANDATORY) + electively `.spawn-rule-manifest.txt` (row 3) + `PACK-AGENTS.md` reference (§4.3) + `PACK-CHAT.md` anchor (§4.2) | The corpus ×3 + rationale form ONE bijection unit (Check 45) | **ONE serial commit.** |
| **C2** (out-of-repo memory reconciliation) | The two Pack-Chat memory files + the MEMORY.md index pointers (§6) | Out-of-repo; no validator; disjoint from C1's tracked files | **Pack-Chat upkeep, AFTER C1 lands.** Not a coder commit. |
| **C3** (audit-set preservation) | Move this reconciled design + DESIGN-BD-238 + the adversarial review + the planner/coder/reviewer reports from `/tmp` → `maintenance-docs/v11-implementation/` | Disjoint from C1 (different tree) | **Paired pack-only commit immediately after C1** (Report preservation / Constraint 3). |

### 9.2 Parallelization verdict + the CORRECTED rationale (MINOR-2 fix)

**SERIAL verdict (kept): C1 is a SINGLE serial commit; no parallel coder waves.** One fresh `pack-coder` in one isolated worktree applies all of C1's edits; the bounded review/fix cycle runs in that worktree; the patch is produced only after review-clean.

**The CORRECTED rationale (the original's reason was wrong):** The original design claimed C1 "cannot be split — bijection/anti-restate would fail on a half-applied state." That is INCORRECT: CI is `on: push` end-state (`.github/workflows/validate-pack.yml:103`), NOT per-commit (EB-R5), and the propagation procedure states explicitly (`pack-ops/PACK-CHAT.md`): "Order is documented, not gate-sequenced: a commit is atomic; the propagation order is verified by END-STATE checks (bijection / anti-restate / trinity-parity / manifest), not a hard-enforced step sequence" — and permits the propagation to land "in the same commit as the structural change, **or in the immediately following commit**." So a split across two commits WITHIN one push would NOT fail CI.

**What ACTUALLY forces the single serial commit:** (a) **propagation-atomicity discipline** — the corpus + rationale (the Check-45 bijection unit) are kept in the SAME commit so the committed state never carries a half-applied bijection (clean per-commit audit), even though CI only checks the push end-state; (b) the **trinity rule** mandates the ×3 trinity edit be a single byte-identical parallel edit; (c) there is no disjoint-file concurrency available — the corpus + rationale + references are one logical unit best kept atomic. The binding reason is propagation-atomicity + auditability discipline, NOT a CI cadence gate.

**Conclusion:** the BD-238 implementation is SERIAL (one coder commit C1 + one paired report commit C3 + out-of-repo upkeep C2), not a parallel-wave effort. Sequence: C1 (coder in worktree → bounded review/fix cycle → patch after review-clean → user-approved commit) → C3 (paired report commit) → C2 (Pack-Chat memory upkeep). C2 and C3 both depend only on C1's slug existing.

---

## 10. §10.1 — pack-root `## Pack memory` body-parity CI check: DROPPED on evidence + hard safeguards named

### 10.1 The disposition (DROPPED entirely on measure-then-bound evidence — not deferred)

**Question:** is leaving pack-root `## Pack memory` body parity discipline-only (no CI gate) a purpose-defeating gap for BD-238, or is a new parity check a separate structural BD?

**Verdict (final, post-measure): DROP the new CI check entirely — NOT defer it.** A dedicated measure-then-bound pass (archived as `DESIGN-BD-238-PARITY-CHECK.md`) established the check is not warranted; registry count stays 69; §10.2's two safeguards are the sufficient protection. (The original reasoning that argued for deferral is retained below for the audit trail, but its conclusion is superseded by the DROP disposition.) Reasoning, measure-then-bound:

1. **No CI check byte-compares pack-root `## Pack memory` bodies today** (EB-E): Check 18 = H2 headings only; Check 45 = CLAUDE.md-representative; Check 66 = per-file cap. The gap is real but discipline-bounded by the trinity rule (which covers the pack-repo copies).
2. **A body-parity check is genuinely a larger, separate effort (SIZE + LOGICAL-FIT bar met).** It would have to (a) decide a normalization that does NOT false-positive on the legitimately-Claude-only `### Sub-agent behavior` section and GEMINI-intrinsic H2s (a naive ×3 byte-diff is WRONG); (b) re-baseline every existing pack-root `## Pack memory` rule for ×3 identity, including intentionally-Claude-only rules; (c) reconcile with Check 45's deliberate CLAUDE.md-representative design. That is a measure-then-bound CI-guard design with its own blast radius — a DIFFERENT contract (parity-of-bodies) from BD-238's (chaining + tiering codification).
3. **Final disposition (post-measure): DROPPED entirely — NOT deferred to a follow-up BD.** A dedicated measure-then-bound pass on the proposed pack-root body-parity CI check (archived alongside this doc as `DESIGN-BD-238-PARITY-CHECK.md`) found the check is not warranted: the registry count stays 69 (no new check is added), and §10.2's two HARD safeguards (SAFEGUARD-1 planner byte-parity diff + SAFEGUARD-2 coder PREFLIGHT ×3 attestation) remain the sufficient protection for pack-root trinity body parity. No tracked follow-up BD is opened; the deferral is retired on evidence.

**Framing correction (adversary's caveat, adopted):** the original's "bitten twice" framing is DROPPED as unsupported. What "bit" BD-244 was the Check-66 CHAR CAP (a concision gate, caught by an EXISTING check, fixed by the reviewer — the system working), NOT a body-PARITY drift. There is NO recorded incident of a pack-root `## Pack memory` body-parity drift shipping undetected. BD-244's pipeline explicitly recorded a "trinity-parity-is-discipline correction" — the 3-day-old resolved call that parity is discipline-enforced; re-litigating it here without new evidence is unwarranted.

### 10.2 The HARD parity safeguards (the SOLE protection — NAMED, load-bearing)

Because there is NO CI net, the following are NOT optional niceties — they are the ONLY thing between a silent ×3 body drift and the tree. The planner MUST encode BOTH as HARD, NAMED steps in the plan-ready output:

**SAFEGUARD-1 — Planner byte-parity verification step (in the plan, run by the coder during C1):**
> After inserting the §4.1 umbrella bullet into all three trinity files, EXTRACT the new bullet from each of `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` (the `- **Large-BD pipeline standard …**` bullet through its `[rationale:]` tail) and run a normalized `diff` across the three extractions. The step PASSES iff all three are byte-identical (after stripping only trailing whitespace). Any difference HALTS C1 — the coder fixes the divergent file before proceeding. This is a NAMED, REQUIRED plan step, not advisory.

**SAFEGUARD-2 — Coder PREFLIGHT ×3-byte-identity attestation (in the coder's PREFLIGHT line, before the IMPL-REPORT):**
> The C1 coder's PREFLIGHT line MUST include an explicit ×3-byte-identity attestation, e.g.: `PREFLIGHT: … the new umbrella bullet is BYTE-IDENTICAL across CLAUDE.md/AGENTS.md/GEMINI.md (verified by extract+diff, 0 differences); body=1289 chars < 1300 (Check 66); leading-window absent from all 6 Check-46 surfaces (anti-restate clean) …`. An IMPL-REPORT lacking this attestation is incomplete and is rejected.

These two safeguards REPLACE the absent CI guard for THIS BD. The planner must carry both verbatim into the plan; the reviewer must confirm both ran (the extract+diff result + the PREFLIGHT attestation line).

---

## 11. Planner handoff — open design questions: NONE

A planner can turn this into a commit sequence with zero open design questions:
- **Exact rule text + placement:** §4.1 (rule body, 1289 chars verified, anti-restate-safe; insert after Researcher-first at CLAUDE.md L288 / AGENTS.md L277 / GEMINI.md L249) + §4.2 (PACK-CHAT.md anchor, ELECTIVE) + §4.3 (PACK-AGENTS.md one-liner, ELECTIVE).
- **Size-tiering criterion:** §3 (four signals + the demoted CONSEQUENCE: LARGE-mandatory-adversarial iff launch-gate-alone OR ≥2 signals; proven BD-244=SMALL, BD-243=LARGE).
- **Propagation surface set:** §5 (MANDATORY = corpus ×3 + rationale section; ELECTIVE = manifest + two references; minimal green footprint = rows 1+2) + §5.1 (surfaces NOT touched) + §5.2 (pack-only keyword).
- **Out-of-repo memory reconciliation:** §6 (prepend pointers, trinity-wins, preserve escalation detail; Pack-Chat upkeep).
- **Rule-10 map:** §9 (SERIAL; one coder commit C1 + paired report C3 + upkeep C2; rationale = propagation-atomicity + auditability, NOT CI cadence).
- **No-conflict analysis:** §8 (per-rule, all NONE; Claude-only worktree handled by generic reference; NIT-3 boundary sentence in the rationale).
- **Anti-restate verification (MAJOR-1):** §7.2 (Check 46 scans the 6 surfaces; the planner verifies the two reference one-liners carry no 60+-char existing-body window — verified clean EB-R1).
- **Parity safeguards (§10.2):** SAFEGUARD-1 (planner byte-parity diff step) + SAFEGUARD-2 (coder PREFLIGHT ×3 attestation) are HARD, NAMED, load-bearing steps — the sole protection for pack-root parity.
- **Check-66 fit:** §7.4 (1289 < 1300; no allowlist).
- **Deferral:** §10.1 (no new body-parity CI check in BD-238; tracked follow-up BD).


---

## 12. Empirical-Evidence Blocks (every state-claim)

**EB-1 — "adversarial" re-baseline at live HEAD (carried forward).**
- Command: `grep -rn "adversarial" CLAUDE.md AGENTS.md GEMINI.md pack-ops/PACK-MEMORY-RATIONALE.md supporting-docs/`
- Output (key lines): `CLAUDE.md:271,273` / `AGENTS.md:261,263` / `GEMINI.md:234,236` (all inside `Reconciliation-instance independence`); `PACK-MEMORY-RATIONALE.md:661,663,672,679`; zero in supporting-docs.
- HEAD/date: `67078627…` / 2026-06-23.
- Interpretation: every occurrence is part of the existing reconciliation rule + rationale. The stale `62805a8`=zero baseline no longer holds.
- Conclusion: SUPPORTED — the WORD exists in-repo via the reconciliation rule but NOT as a named size-tiered tier; the gap is intact; nothing to STRIP.

**EB-R1 — Check 46 anti-restate, the CORRECT measurement (MAJOR-1 fix).**
- Command: Python replication of `_check_46_extract_pack_memory_imperative_bodies(60)` (53 existing-body leading-120 candidates) + substring scan of the two NEW reference one-liners (§4.2/§4.3) and the NEW rule's leading-120 window against the 6 `_CHECK_46_ANTI_RESTATE_SURFACES`.
- Output (verbatim): `existing candidate count: 53`; `PACK-AGENTS one-liner: existing-body windows present? 0 -> CLEAN`; `PACK-CHAT anchor: existing-body windows present? 0 -> CLEAN`; the NEW rule window `'Pack-side BD development runs ONE official pipeline: optional researcher(s) (internal census and/or external docs verifi'` → `present? False` in each of the 6 surfaces. Surface tuple verbatim from `scripts/validate-pack.py` L7469-7476: `("pack-ops/PACK-AGENTS.md","pack-ops/PACK-CHAT.md",".claude/skills/commit-discipline/SKILL.md",".claude/skills/review/SKILL.md",".claude/skills/planning/SKILL.md",".claude/skills/implementation-report/SKILL.md")`; candidate extractor reads `corpus_path = REPO_ROOT / "CLAUDE.md"` (the trinity is NOT in the surface set).
- HEAD/date: `67078627…` / 2026-06-23.
- Interpretation: Check 46 tests whether existing-rule-body leading-windows leak into the 6 reference/skill surfaces — NOT a trinity-vs-trinity body diff (the void property the original EB-7 measured). The two NEW reference surfaces carry zero such windows; the NEW rule's window is absent from all 6.
- Conclusion: SUPPORTED — the original EB-7 measured a non-existent check; the real Check 46 PASSES post-implementation; the planner's verification step is retargeted to the 6 surfaces + the two new one-liners.

**EB-R2 — the original criterion over-classifies BD-244 (MAJOR-2 confirmation).**
- Command: `Read backlog/BD-244.md` Type + Resolved + apply the original §3 disjunction (ANY signal ⇒ LARGE-mandatory).
- Output (verbatim): Type — "Adds a facet to the existing `ci-guard-measure-then-bound` rule (pack-root trinity ×3)"; Resolved Pipeline — "pack-architect → pack-planner (...) → pack-coder → pack-reviewer (1 SHOULD: …Check 66's 1300-char cap) → fix-coder → post-fix reviewer CLEAN"; `grep -c "adversarial" backlog/BD-244.md` → `0`; CI green (run 28039394721).
- HEAD/date: `67078627…` / 2026-06-23.
- Interpretation: the original criterion (structural fires on any rule edit) classifies BD-244 LARGE-mandatory-adversarial, yet BD-244 shipped clean on the BASE pipeline with ZERO adversarial passes. The original criterion over-spends the adversarial budget on routine rule tweaks.
- Conclusion: SUPPORTED — measure-then-bound was not applied to the original criterion; the demotion (§3.2) is required.

**EB-R3 — the REVISED criterion classifies BD-244=SMALL and BD-243=LARGE (MAJOR-2 validation).**
- Command: `Read backlog/BD-244.md` + `backlog/BD-243.md` (Type, Resolved pipeline, surface counts) + `grep -c "adversarial"` each + apply the §3.2 revised criterion (LARGE-mandatory iff launch-gate-alone OR ≥2 signals; tightened L4).
- Output (verbatim): BD-244 — `grep -c adversarial` = `0`; signals fired = L2 only (trinity + scripts/validators + tests); L4 does NOT fire under the tightened definition (amends a CLAUSE of an EXISTING rule, no new check/convention/tree/rule); launch-gate NO → 1 non-launch signal → **base flow / SMALL**, matching its actual clean base-pipeline shipment. BD-243 — `grep -c adversarial` = `4`; Type "STRUCTURAL cross-surface … adds ONE forward-looking governance rule … Large-BD standard … with adversarial passes"; signals fired = L2 (trinity ×6 + pack-ops + skills + agents + scripts) + L3 (required docs-researcher 136-doc census) + L4 (NEW rule + 7 NEW CI checks 65-71) = 3 → **LARGE-mandatory**, matching its actual `docs-researcher → architect (+ adversarial) → planner (+ adversarial) → coder waves → reviewer` pipeline (16 commits).
- HEAD/date: `67078627…` / 2026-06-23.
- Interpretation: the revised criterion's classification of both precedent BDs MATCHES the pipeline each actually ran. BD-238 itself = L2 + L4 = 2 signals → LARGE-mandatory (matches user 2026-06-23). The user-elective SMALL tier is preserved (a single non-launch signal no longer mandates the adversarial passes).
- Conclusion: SUPPORTED — the revised criterion is measure-then-bound-validated against the live precedent set.

**EB-R4 — propagation MANDATORY vs ELECTIVE (MINOR-1 fix).**
- Command: `grep -c "^slug:" pack-ops/.spawn-rule-manifest.txt` ; `grep -c "^## " pack-ops/PACK-MEMORY-RATIONALE.md` ; read Check 45 (`orphan_corpus_slugs = corpus_set - rationale_set`, FAIL if nonempty, AND `orphan_rationale_headings = rationale_set - corpus_set`) + Check 46 (`_parse_manifest_records` iterates only records that EXIST).
- Output (verbatim): manifest slug count = `7`; rationale heading count = `29`; manifest slugs = `{agents-never-commit, role-write-scope, preflight-stop-means-stop, presents-triage-before-fix-coder, triage-all-fix-all, bounded-review-fix-cycle, pack-chat-minor-edits-only}` (a curated subset of the 29 tagged rules).
- HEAD/date: `67078627…` / 2026-06-23.
- Interpretation: Check 45 (bidirectional) REQUIRES a rationale section for the new tagged slug (corpus ↔ rationale set-equality). Check 46 validates only manifest records that exist; it does NOT require a record per tagged rule (only 7 of 29 tagged rules have one). So mandatory = corpus ×3 + rationale section; manifest record + reference one-liners are elective.
- Conclusion: SUPPORTED — §5 rows 3-4 relabeled ELECTIVE; minimal green footprint = rows 1+2.

**EB-R5 — CI is push-time end-state, not per-commit (MINOR-2 / rule-10-reason fix).**
- Command: `grep -n "^on:" .github/workflows/validate-pack.yml` ; `grep -n "same commit\|immediately following\|gate-sequenced\|END-STATE\|atomic" pack-ops/PACK-CHAT.md`.
- Output (verbatim): `.github/workflows/validate-pack.yml:103: on: push`; PACK-CHAT.md: "Update in the same commit as the structural change, or in the immediately following commit"; "Order is documented, not gate-sequenced: a commit is atomic; the propagation order is verified by END-STATE checks (bijection / anti-restate / trinity-parity / manifest), not a hard-enforced step sequence."
- HEAD/date: `67078627…` / 2026-06-23.
- Interpretation: a propagation split across commits within one push does not fail CI; the binding one-commit constraint is propagation-atomicity (corpus+rationale = one bijection unit) + trinity-rule + auditability discipline, NOT a CI gate. The SERIAL verdict is right; the original's stated reason was wrong.
- Conclusion: SUPPORTED — §9 rationale corrected, verdict kept.

**EB-R6 — revised rule body length under the exact Check-66 measure.**
- Command: Python replication of `_check_66_iter_bullets` (whitespace-collapsed join of the `- ` line + 2-space continuation lines) over the §4.1 revised body; cap constant `_CHECK_66_BULLET_CHAR_CAP = 1300`.
- Output (verbatim): intermediate re-wordings measured `1317`, then `1330`, then the final `FINAL body char_len (Check-66 measure): 1289 UNDER`. The carried-forward original body measured `1203`.
- HEAD/date: `67078627…` / 2026-06-23.
- Interpretation: the MAJOR-2 re-wording (decoupled consequence + tightened L4) lands at 1289 < 1300 after relocating the "more rounds on larger gaps" detail to the rationale section — no allowlist hole.
- Conclusion: SUPPORTED — the §4.1 revised rule passes Check 66 with no allowlist; over-cap intermediates recorded honestly (not hidden).

**EB-E — no CI byte-compares pack-root `## Pack memory` bodies (§7.1/§10.1 premise, carried forward).**
- Command: read `scripts/validate-pack.py` Check 18 body (collects `line.startswith("## ")` only) + registry (Check 18 runs at pack-root) + Check 45 (`corpus_path = REPO_ROOT / "CLAUDE.md"` sole corpus); `grep "This rule also applies" CLAUDE.md`.
- Output (verbatim): Check 18 compares `## `-heading lists only; Check 45 corpus = CLAUDE.md; `CLAUDE.md:113-114: … This rule also applies to the pack-repo copies of these three files.`
- HEAD/date: `67078627…` / 2026-06-23.
- Interpretation: Check 18 at pack-root compares only H2 headings; Check 45 uses CLAUDE.md only; no body-parity check exists. The trinity rule obligation covers pack-repo copies but is discipline-enforced.
- Conclusion: SUPPORTED — the §10.1 deferral premise is correct; the gap is real but discipline-bounded; the §10.2 safeguards are the sole protection.

**EB-G — placement anchors at live HEAD (carried forward).**
- Command: `grep -n "Researcher-first pipeline\|Planner output → user review" CLAUDE.md AGENTS.md GEMINI.md`.
- Output (verbatim): `CLAUDE.md:288 / :296`, `AGENTS.md:277 / :285`, `GEMINI.md:249 / :257`.
- HEAD/date: `67078627…` / 2026-06-23.
- Interpretation: insertion after Researcher-first, before Planner output, is mid-`### Agent invocation rules` ×3 identical; adds no H2.
- Conclusion: SUPPORTED — Check 18 unaffected; byte-parity-feasible.

**EB-H — design EB-6 (Claude-only worktree grep-zero) re-confirmed via research B1.**
- Command (research-provided, re-read): `grep -rn "Sub-agent behavior (Claude-only)\|Parallelization map (rule 10)" CLAUDE.md AGENTS.md GEMINI.md`.
- Output (verbatim): only `CLAUDE.md:381` (section) + `CLAUDE.md:416` (rule 10); zero in AGENTS.md / GEMINI.md.
- HEAD/date: `67078627…` / 2026-06-23 (research census B1 at `7caff91`; section unchanged at live HEAD per the carried-forward design EB-6).
- Interpretation: the worktree mechanics + rule 10 are Claude-only, Trinity-exempt.
- Conclusion: SUPPORTED — the umbrella rule references (does not restate/port) the worktree-wave step to stay byte-parity-safe ×3.

---

## 13. Adversarial findings resolution table

| Finding | Severity | How resolved | Evidence |
|---|---|---|---|
| MAJOR-1 — EB-7 anti-restate measured the wrong check (trinity-vs-trinity diff; Check 46 never tests that) | MAJOR | Re-stated the evidence against the ACTUAL Check 46 algorithm (scans 6 fixed surfaces for existing-body leading-windows). Retargeted the planner verification step to verify the two NEW reference one-liners carry no 60+-char existing-body window. | EB-R1 (53 candidates; both new refs CLEAN; new-rule window absent from all 6 surfaces); §7.2 |
| MAJOR-2 — L4 over-classifies routine rule tweaks LARGE; contradicts BD-244 precedent | MAJOR | Redesigned the criterion: kept 4 signals, DEMOTED the consequence — LARGE-mandatory-adversarial iff launch-gate-alone OR ≥2 signals; tightened L4 to NEW convention/check/rule (a single-clause amend to an existing rule no longer fires L4). Re-worded the rule text accordingly. | EB-R2 (orig over-classifies BD-244), EB-R3 (revised → BD-244 SMALL, BD-243 LARGE, BD-238 LARGE), EB-R6 (body 1289 < cap); §3 |
| MINOR-1 — §5 rows 3-4 framed as Check-46-mandated; they are elective | MINOR | Relabeled rows 3-4 ELECTIVE (discoverability); stated MANDATORY = corpus ×3 + rationale section (Check 45 bidirectional); minimal green footprint = rows 1+2. | EB-R4 (manifest = 7-slug curated subset of 29 tagged rules; Check 45 bidirectional); §5 |
| MINOR-2 — rule-10 SERIAL reason wrong (claimed per-commit CI gate) | MINOR | Kept SERIAL verdict; corrected rationale — CI is `on: push` end-state; the binding reason is propagation-atomicity (corpus+rationale one bijection unit) + trinity-rule + auditability, not a CI cadence gate. | EB-R5 (`on: push`; "Order is documented, not gate-sequenced"); §9.2 |
| NIT-3 — add reconciliation-rule boundary sentence | NIT | Added the one-sentence boundary note to the row-2 rationale-section spec (umbrella NAMES the stages; reconciliation-instance-independence governs the fresh-instance reconciliation that follows). | §5 row 2; §8.1 |
| §10.1 — discipline-vs-CI-guard for pack-root parity; "bitten twice" framing | scope | DEFERRAL KEPT (no new body-parity CI check in BD-238; separate structural BD; tracked follow-up). Elevated SAFEGUARD-1 (planner byte-parity diff) + SAFEGUARD-2 (coder PREFLIGHT ×3 attestation) to HARD, NAMED, load-bearing steps. Dropped the unsupported "bitten twice" framing (BD-244 was a Check-66 cap finding, not a parity drift). | EB-E (no body-parity check); §10.1, §10.2 |

---

## 14. Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|---|
| 1 | **agents-never-commit** | Only Write = `/tmp/pack-handoff-bd238-arch/DESIGN-BD-238-RECONCILED.md` (chunked Bash heredoc appends + `mkdir -p` on the handoff dir). All git read-only: `git rev-parse HEAD` → `67078627…`, `git status --short` → ` M backlog/_toc.md` + `?? backlog/BD-245.md` (untouched), `git ls-files`/`grep` only. No `add/commit/push/checkout/restore/stash/any` state-changing verb. No memory store read/written. | COMPLIANT |
| 2 | **reconciliation-instance-independence** | I am a FRESH reconciler — NOT the original author (DESIGN-BD-238) NOR the adversary (ADVERSARIAL-REVIEW). I resolved from independent measurement, not deference: I OVERRULED the original EB-7 (EB-R1), RE-WORDED the original rule body for MAJOR-2 (EB-R6), and re-derived the criterion against precedent (EB-R3). I ADOPTED adversary findings only where my own measurement confirmed them (EB-R2/R4/R5/E) and stated so. | COMPLIANT |
| 3 | **empirical-evidence-blocks** | §12 carries EB-1, EB-R1…EB-R6, EB-E, EB-G, EB-H: every state-claim (the BD-244/BD-243 classifications, the Check 45/46 algorithm behavior, the CI trigger, the body char count, the placement anchors) backed by command + verbatim output + HEAD `67078627…` + interpretation + SUPPORTED conclusion. EB-R6 records the FAILED 1317/1330 intermediates honestly. | COMPLIANT |
| 4 | **ci-guard-design-measure-then-bound** | The revised size-tiering criterion is MEASURED against the actual precedent set, not asserted: BD-244 (EB-R2 over-classified by the original; EB-R3 → SMALL under the revised) and BD-243 (EB-R3 → LARGE). KEEP/STRIP applied to the "adversarial" baseline (§2: all KEEP, nothing to STRIP). The §10.1 parity-check deferral measured the actual checks (EB-E) before ruling. | COMPLIANT |
| 5 | **operating-docs-no-history-no-bloat** | The §4.1 rule body carries ZERO history/provenance/dates; terse + structured; re-measured at 1289 chars < the Check-66 1300 cap (EB-R6). The two reference one-liners are pointers. No deferred-feature mentions (the Claude-only worktree-wave is CURRENT, a live reference). | COMPLIANT |
| 6 | **deferral-is-scope-creep / no-deferral-without-user-direction** | The design lands wholly in v11.0. The ONE deferral (§10.1, a new pack-root body-parity CI check) is justified by SIZE + LOGICAL-FIT (distinct contract; non-trivial Claude-only/GEMINI-intrinsic normalization; would re-baseline every pack-root rule) and routed to a tracked follow-up BD — not silently dropped. Nothing else is deferred; MAJOR-1/MAJOR-2/MINORs are all resolved in-design. | COMPLIANT |
| 7 | **rules-applied-verification-block** | This table — rules 1-7, each with name + quoted evidence + terminal conclusion (no AMBIGUOUS; no empty evidence). | COMPLIANT |

---

*End of DESIGN-BD-238-RECONCILED. Fresh independent reconciliation pass; one Write (this doc) under /tmp; read-only git only; no memory store used. The 2 MAJOR + 2 MINOR + NIT-3 + the §10.1 framing are resolved; the §10.1 deferral is kept with hard parity safeguards named. Ready for the planner.*
