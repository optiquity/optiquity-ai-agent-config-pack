# DESIGN — BD-243: strip historical/audit + bloat from operating docs; add anti-bloat governance rule

Architect: pack-architect (first, RO). Runtime HEAD `a847f12`, branch v11-dev, 2026-06-21. Build-on-research design. Adversarial pass to follow.

---

## OPEN QUESTIONS FOR USER (rule before the planner bounds the fix-set)

**OQ-1 — Check 44 vs the new Check 65: own the date axis where?** Check 44 (existing, `check_durable_doc_concision`) ALREADY hard-fails on `date` (`20\d{2}-\d{2}-\d{2}`) + SHA + Commit-N + Override-N + post-Commit + `will ` over EXACTLY 7 `pack-ops/` docs, with `pack-ops/.concision-allowlist.txt` (currently 4 `will` KEEPs; STRIP-class = 0 residue). The new history gate (Check 65) must add the **BD/TD-provenance axis** (P1-P3/P6-P8 — Check 44 has NO `BD-NNN` pattern) and **broaden scope to all ~145 IN docs**. Two clean designs: **(A)** Check 65 owns BD/TD-provenance ONLY, repo-IN-wide; Check 44 keeps its date/SHA teeth on its 7 (the 7 are then double-scanned for dates by 44 only, BD/TD by 65 — no overlap on a single pattern). **(B)** Check 65 owns the COMPLETE history axis (dates + BD/TD-provenance) repo-IN-wide and Check 44 is REDUCED to its `will`/length-advisory role (de-dup the date pattern). **Recommend (A)** — minimal blast radius, no edit to Check 44's shipped contract, no allowlist migration; the only cost is dates on the 7 docs are a 44-concern and BD/TD on the 7 are a 65-concern (orthogonal patterns, no double-fail on one line). Flag because it sets the gate topology. Designed provisionally to (A).

**OQ-2 — `backlog/_rules.md` L90 `(BD-001..019)` factual-range token.** It is neither P-provenance (no past-action verb) nor an L-live-pointer — it factually describes the real on-disk file set (`BD-001..019 are real BD-00N.md per-entry files`). Provisional: **KEEP** (contract-descriptive fact the agent acts on, like a format example). Confirm it is not in the strip set. Designed provisionally KEEP (allowlisted).

**OQ-3 — `pre-2026-05-15 batches` / `pre-2026-05-16 pattern` (CLAUDE/AGENTS/GEMINI, ×3 each).** These dated tokens are the EXCEPTION CARVE-OUT of a live rule (e.g. "per-BD reviews … never delay to end-of-batch retroactive recovery (Batch-21c-style); that is an exception for pre-2026-05-15 batches only"). Stripping the date naively would delete the carve-out's meaning. Provisional: **REWRITE to current-state** — the carve-out is now vestigial (all current work post-dates it), so the clause + its date both go, leaving the unconditional rule. This is a meaning-PRESERVING strip only if the carve-out is genuinely dead. Confirm the pre-DATE carve-outs are dead (no live work predates them). Designed provisionally as REWRITE-removing-the-dead-carve-out.

---

## EXECUTIVE SUMMARY

**Three deliverables, one BD: (1)** a SHAPE-TARGETED + ALLOWLISTED history strip of P1-P8 across the ~145 IN docs (concentrated in ~6 pack files; project-side ≈ 0); **(2)** an AGGRESSIVE bloat reduction (the dominant axis: ~13,450 project-side lines + the pack-root mega-rules — STRUCTURAL conversion, clause-preserving, NOT deletion); **(3)** ONE new governance rule (the sole sanctioned functional change) banning historical/audit text + bloat in operating docs going forward, in all 6 trinity files, with a matching RATIONALE.md `## slug` (Check 45 bijection) + a net-new grep-zero history gate **Check 65** (measure-then-bound).

**The pivotal reconciliation fact (re-measured):** Check 44 ALREADY hard-fails dates/SHAs/Commit-N/Override-N/`will ` over 7 `pack-ops/` docs (allowlist = 4 `will`, STRIP-class = 0 residue). BD-243 does NOT re-invent a date gate — it ADDS the BD/TD-provenance axis (Check 44 has none) and BROADENS scope from 7 docs to ~145 IN docs (Check 65). The new rule's anti-bloat clause is the governance layer over Check 44's already-shipped per-doc advisory-length mechanism.

**Next-free check number = 65** (highest registered = 64; `CHECK_REGISTRY_EXPECTED_COUNT = 62`, the count-vs-max gap is by design — Checks 16/18/19 register twice + 2 carry `number=None`). Check 65 ⇒ bump the constant 62→63.

**Success bar held:** NO meaning/functionality lost except the one new rule.

---

## A. FINAL OPERATING-vs-REFERENCE TAXONOMY (formalized — the scope definition for sweep + gate)

### Criterion (settled)
A doc is **OPERATING (IN)** iff an agent/chat EXECUTES it as live instruction at task time (rules, agent/skill defs, prompts, write-contracts). A doc is **EXEMPT** iff it DESCRIBES / sets up / records / self-governs (read for orientation or emitted as a deliverable). Tie-breakers, in order: (1) Execution — agent reads it AND changes behavior per it during a task → IN. (2) Audience — primary reader is a human for orientation/setup/history → EXEMPT. (3) Deliverable — template that EMITS an artifact, or a record of past work → EXEMPT. (4) History-home — the doc IS a history store (changelog/backlog entry, maintenance-doc, IMPL report) → EXEMPT.

### IN set — the GATE SCOPE (~145: 33 pack + 112 project)
**Pack (33):** root trinity (3); `pack-ops/` (10: PACK-CHAT, PACK-AGENTS, MERGE-STRATEGY, PACK-MEMORY-RATIONALE, BOUNDARY-DEFINITION, OPTIONAL-FEATURES, CONCEPTUAL-REVIEW-METHODOLOGY, DRY-RUN-MIGRATION, HELP-FRAGMENT-PACK, HELP-FRAGMENT-TRACKER); bl/cl meta (4: backlog/_rules, backlog/_intro, changelog/_rules, changelog/_intro); `.claude/skills/*/SKILL.md` (11); `.claude/agents/pack-*.md` (5).
**Project (112, shipped):** trinity (3); `docs/pack/*.md` (6); `docs/pack/prompts/*.md` (10); `skills/*/SKILL.md` (37); `.claude/agents/*.md` (16); `.agents-plugin/optiquity-agents/agents/*.md` (16); `.agents-plugin/optiquity-agents/RUNTIME-SUBAGENT-PATTERN.md` (1); `.codex/agents/*.toml` (16, Q3 IN — TOML-serialized agent instruction bodies); `docs/project/*/_*.md` (7).

### EXEMPT set (history/orientation/deliverable — gate MUST NOT scan)
README.md / QUICKSTART.md / LICENSE.md / project-template/README.md; `supporting-docs/*.md` (9, Q2); `backlog/_toc.md` + `changelog/_toc.md` (generated); `backlog/BD-*.md` + `changelog/v*.md` (history store); `maintenance-docs/**`, all `PACK-REVIEW-*` / IMPL reports; `scripts/**` + all non-agent config/`.py` (BD-243 explicit script exemption).

### Tri-family agent-def lock (the 16 roles ×3 serialized families)
Each of the 16 agent roles exists in `.claude/*.md` + `.agents-plugin/*.md` + `.codex/*.toml`. Any per-role edit touches all 3 in lock-step (rule: enumerate-encoding-surfaces). 16×3 = 48 agent-def surfaces + RUNTIME-SUBAGENT-PATTERN.md = 49.

**Confirm (H):** the only intended functional change is the new rule. Every other edit is delete-history or restructure-bloat with zero behavior change.

---

## B. STRIP RECIPES (measure-then-bound) — P1-P8 strip, L1-L3 keep

### B.0 Pattern set (confirmed from research, re-verified @ a847f12)
**STRIP (P1-P8):** P1 BD/TD provenance tag on a rule `(BD-NNN …)`; P2 "BD-NNN deleted/added/renamed/introduced/removed/created/retired/broadened"; P3 "per BD-NNN" justification; P4 dated note / `User-locked YYYY-MM-DD`; P5 `pre-YYYY-MM-DD pattern`; P6 "carried from / carry-over"; P7 changelog-style past-event narration; P8 incident / commit-SHA references.
**KEEP (L1-L3 — live forward-pointers, measure-then-bound allowlist):** L1 `until BD-NNN` / `as of BD-NNN` (live transitional); L2 `deferred — BD-NNN` / `blocked on BD-NNN` / `coordinate BD-NNN` / `= BD-NNN` (live anchor); L3 `ARCHITECTURE-*.md` path ref (live doc cross-ref).

### B.1 THE MEASURED L1-L3 KEEP ALLOWLIST (sized EXACTLY to legitimate live pointers @ a847f12)
This is the gate's allowlist — NO broader. Measured occurrences in the IN set:

| Class | Occurrence (content-anchored, line drifts) | Files |
|---|---|---|
| L1 `until BD-206` | mirror "…until BD-206 retires" | CLAUDE.md:595, AGENTS.md:488, GEMINI.md:464 |
| L2 `deferred — BD-214` | tracker "deferred — BD-214" | CLAUDE.md:610, AGENTS.md:503, GEMINI.md:479, PACK-CHAT.md:53 |
| L2 `= BD-217` | Codex/Antigravity worktree "= BD-217" | CLAUDE.md:420, PACK-MEMORY-RATIONALE.md:196 |
| L2 `coordinate BD-217` | "coordinate BD-217" | CLAUDE.md:429 |
| L2 `blocked on BD-215` | backlog stream "Until then … BD-215" | backlog/_rules.md:33 |
| L2 `deferred … BD-214` | backlog stream "deferred indefinitely … (BD-214)" | backlog/_rules.md:28 |
| L3 `ARCHITECTURE-BD-119.md` | migrator framework ref | CLAUDE.md:39, AGENTS.md:41, GEMINI.md:40, PACK-MEMORY-RATIONALE.md:508 |
| L3 `ARCHITECTURE-BD-182.md` | cross-CLI canonical table | CLAUDE.md:674, AGENTS.md:567, GEMINI.md:543, PACK-MEMORY-RATIONALE.md:578 |
| L3 `ARCHITECTURE-BD-208.md` | rationale doc ref | PACK-MEMORY-RATIONALE.md:617 |
| L3 `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` | maintainability ref | PACK-CHAT.md:226, PACK-AGENTS.md:230/253, PACK-MEMORY-RATIONALE.md:469 |
| L3 `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` | per-entry ref | PACK-CHAT.md:415 |
| KEEP (format example, OQ-2) | `BD-167.md`, `^BD-\d+\.md$`, `(BD-001..019)` | backlog/_rules.md:38/44/45/48/90 |
| KEEP (project template token) | `TD-031` example, `TD-001` grammar | project PM-CHAT.md:764, project backlog/_rules.md:14 |

**Allowlist topology decision:** these L1-L3 anchors are points at LIVE work; once that BD lands, the pointer becomes history and is a future strip. The allowlist is therefore **content-anchored snippets** (like `.concision-allowlist.txt`), NOT line numbers — and each carries a `reason:` so a reviewer can re-verify it is still LIVE. The gate FAILS a P1-P8 hit NOT covered by an L-allowlist record.

### B.2 Per-doc strip recipes (history-heavy pack files)

**`pack-ops/PACK-MEMORY-RATIONALE.md` (Q1 SURGICAL — 58 BD/TD, 12 dated, HEAVIEST).** The file's payload IS the conceptual Why; the DATED INCIDENT NARRATION is the strip target. Per `## slug` block: DELETE the dated incident lead (`**Why:** User-locked 2026-05-30 during BD-195 Step-7 recovery.` → DELETE the date+incident clause); REWRITE the remaining Why to the timeless principle; DELETE P8 incident/SHA lines (L208 `original incident BD-169 19g-pack, 2026-05-16`; L538 `the 2026-05-17 incident where commit 667d2dd shipped`; L545 `2026-05-19 incident where BD-175 Phase 5 Commit 8 4120d19`); L498 `BD-135 renamed the colliding tracker.toml.example` → state the rule without the renamer; L605 `the pre-BD-208 convention let …` → state the current convention. KEEP: every conceptual Why + How-to-apply; the L3 ARCHITECTURE-*.md refs; the L2 `= BD-217`. NOTE: this file is NOT a Check-44 doc (44 covers 7 docs; RATIONALE is not one) — Check 65 will scan it.

**`pack-ops/MERGE-STRATEGY.md` (23 BD/TD, 0 dated).** P2 L419 `BD-101 added three verification gates` → "Three verification gates ensure …" (state the gates, drop the adder). Sweep all 23 BD tags: each is P1/P2/P3 provenance unless it is an L-anchor — measure each; strip the provenance, keep the procedure. This IS a Check-44 doc (date/SHA already clean) + a Check-65 doc (BD/TD axis new).

**Root trinity `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` (20/11/11 BD/TD; 2/2/2 dated) — TRINITY-LOCKED, edit all 3 same commit.** STRIP: P2 `BD-203 deleted pack-ops/BACKLOG.md + CHANGELOG.md` (CLAUDE L34/L589, AGENTS L36, GEMINI L32) → "There is no monolithic mirror." (the FACT, not the deleter). P1 section anchors `(BD-119)` / `(BD-225)` / `(BD-226)` on `## ` headings → drop the tag, keep the heading (CAUTION: do NOT touch the `## Project addenda` H2 — Check 16/18/19). P5 `pre-2026-05-15 batches only` (L214) + `pre-2026-05-16 pattern … too much friction` (L221) → OQ-3 REWRITE-remove-dead-carve-out. KEEP: L1 `until BD-206` (L595), L2 `deferred — BD-214` (L598/610), L2 `= BD-217`/`coordinate BD-217` (L420/429), L3 `ARCHITECTURE-BD-119/182.md`.

**`pack-ops/OPTIONAL-FEATURES.md` (13 BD/TD, 0 dated; 576 lines vs Check-44 advisory ceiling 271 — BIGGEST bloat offender among the 7).** STRIP per-feature P1 BD provenance tags; KEEP the feature contract. Bloat: aggressive structural reduction (the 576→~271 advisory is the live signal). Check-44 doc (date clean) + Check-65 doc.

**`pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` (12 BD/TD, 0 dated; 298 vs ceiling 343 — within bloat ceiling).** STRIP P1 BD tags; keep methodology. Check-44 + Check-65 doc.

**`backlog/_rules.md` (12 BD/TD, 0 dated — EXAMPLE-vs-PROVENANCE split, verified).** STRIP: L23 `deleted at BD-203` (P2), L39/L48 `canonical per BD-211` (P3), L72 `per BD-203` (P3). KEEP: L28 `(BD-214)` deferred (L2), L33 `BD-215` blocked (L2), L38/44/45/48 format examples `BD-167.md`/`^BD-\d+\.md$`, L90 `(BD-001..019)` factual range (OQ-2). NOT a Check-44 doc; Check-65 doc.

**`pack-ops/PACK-CHAT.md` (8 BD/TD, 1 dated).** Strip the 1 dated note + P1/P3 provenance; KEEP L2 `deferred — BD-214` (L53), L3 ARCHITECTURE refs. Check-65 doc.

**`pack-ops/PACK-AGENTS.md` (4), `pack-ops/DRY-RUN-MIGRATION.md` (4), `changelog/_rules.md` (2), `backlog/_intro.md` (1), `HELP-FRAGMENT-*` (light).** Light P1 strips; verify each token P-vs-L; KEEP L3 ARCHITECTURE refs in PACK-AGENTS. DRY-RUN + HELP-FRAGMENT-* are Check-44 docs (already date-clean).

**`pack-ops/BOUNDARY-DEFINITION.md` (0 BD/TD, 0 dated).** CLEAN of history → bloat-axis only (135 lines, under ceiling 156).

### B.3 Project-side history strip ≈ EMPTY (re-verified @ a847f12)
`grep` of P2/P3/P4/P5/P6 across project trinity + docs + skills + all 3 agent families = **0 hits**. The only project BD/TD tokens are `TD-031` (PM-CHAT example) + `TD-001`/`^TD-\d+\.md$` (grammar) — KEEP. **Project-side BD-243 work is the BLOAT axis exclusively** (Section C).

---
## C. TERSENESS / STRUCTURE BAR (the dominant axis) — aggressive, meaning-preserving

### C.0 Reconciliation with ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md (rule 9)
That prior design (referenced by file: `maintenance-docs/v11-implementation/ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md`) shipped Check 44 (M4 concision gate) + Check 45 (rule↔rationale bijection) + the C1/C2 surface-separation contract: "dates/SHAs/Commit-N/Override-N belong in reports, NOT durable docs." BD-243 **EXTENDS, does not supersede, §5.2/§6**: (a) §6's forbidden-pattern teeth covered 7 `pack-ops/` docs — BD-243 broadens the *history* axis to ~145 IN docs via Check 65 (the BD/TD-provenance axis §6 never had); (b) §6's per-doc advisory-length ceiling (soft) becomes the *measurable* anchor for BD-243's anti-bloat clause; (c) §5.2's bijection is the lockstep mechanism the new rule's `[rationale: slug]` rides. **Explicit statement:** Check 65 does NOT duplicate Check 44's date/SHA teeth on the 7 docs (OQ-1 option A); it adds the orthogonal BD/TD axis + broader scope. The new governance rule is the human-readable codification of the contract Check 44/45 already enforce mechanically, plus the no-history-provenance clause.

### C.1 The four bloat types + the per-rule meaning-preservation contract
| Type | Definition | Reduction method | Meaning-preservation rule |
|---|---|---|---|
| **B1 mega-bullet run-on** | one bullet packs N clauses + parentheticals (e.g. `graph-first-context` = 5,274 chars; 52 rules / 768-line CLAUDE.md) | prose → nested sub-bullets / table; one clause per row | EVERY clause survives as a row; reviewer diffs clause-set before/after = equal |
| **B2 prose-that-should-be-a-table** | enumerable cases narrated in prose (e.g. ~30 denied git verbs as a comma-run) | convert to list/table | every enumerated item present in the table |
| **B3 verbosity / hedging / restatement** | persuasive padding, repeated parentheticals, imperative restated then re-argued | delete the padding, keep the directive + trigger | the DIRECTIVE + its TRIGGER (when/on-what-surface) survive verbatim-equivalent |
| **B4 cross-file duplication** | same boilerplate ×3 tri-family / ×2 trinity | NOT dedup-able (parity by design); terseness multiplies ×3 savings, parity-locked | each copy stays byte-parallel post-terseness (trinity/tri-family rule) |

### C.2 The Q4 trinity mega-rule method (SAFE structural conversion, clause-preserving)
The pack-root `## Pack memory` mega-rules encode load-bearing contracts; aggressive terseness = biggest win AND biggest meaning-loss risk. **Method (mandatory for any rule >~800 chars):**
1. **Clause-enumerate first.** Before editing, the coder lists every distinct CLAUSE in the rule (a directive, a trigger, an exception, a cross-CLI note, a Trinity-exemption note). This list is the meaning-invariant.
2. **Convert prose → structured** (sub-bullets or a small table), ONE clause per row. NO clause deletion — only re-shaping.
3. **Re-enumerate after.** The post-edit clause-set MUST equal the pre-edit set. A dropped clause = a behavior change = FAIL.
4. **B3 padding within a clause** (a redundant parenthetical, a hedge) MAY be trimmed — but only padding, never a directive/trigger/exception/cross-CLI-semantic.
5. **Trinity-lock:** the same structural conversion applies byte-parallel to AGENTS.md + GEMINI.md in the SAME commit (Checks 16/18/19 + trinity rule).

### C.3 Reviewer no-behavior-change verification (rule-by-rule)
For EVERY swept rule the reviewer produces a **before/after clause-set diff**: enumerate clauses in the pre-edit rule (from `git show HEAD:<file>`) and the post-edit rule; assert set-equality (modulo B3 padding, which the reviewer flags individually). A non-empty asymmetric diff that is NOT a flagged-padding trim = a meaning-loss BLOCKER. For the history strip, the reviewer additionally runs the grep-zero gate (Check 65) + confirms each KEEP allowlist entry still points at LIVE work.

### C.4 Project-side bloat sizing (the bulk — ~13,450 lines)
trinity 1,446; docs/pack 2,738; prompts 1,316; skills (37) 3,635; .claude agents (16) 1,818; .agents-plugin agents (16) 1,613; .codex toml (16) 884. The B1/B3 reduction here is the largest token-per-read payoff; tri-family parity (B4) locks the ×3 agent-def edits. Pack-side bloat: root trinity 2,043; RATIONALE 764; OPTIONAL-FEATURES 576; PACK-CHAT 515; MERGE-STRATEGY 505.

---

## D. THE NEW GOVERNANCE RULE (the one sanctioned functional change)

### D.1 Exact text (itself terse — complies with its own no-bloat clause)
Inserted in `## Pack memory` → `### Repo conventions` (pack-root trinity) and the project-template trinity's equivalent rules block:

```
- **Operating docs carry NO history; stay terse + structured.** An
  operating doc (a doc an agent/chat EXECUTES as live instruction — rules,
  agent/skill defs, prompts, write-contracts) carries ZERO historical/
  audit-trail text (dated notes, `User-locked YYYY-MM-DD`, "BD-NNN did X"
  past-action narration, "per BD-NNN" / "carried from" provenance,
  incident/SHA refs) and is kept terse + structured (no mega-bullet
  run-ons, prose-that-should-be-a-table, or padding). LIVE forward-pointers
  KEEP (`until BD-NNN`, `deferred — BD-NNN`, `= BD-NNN`, an
  `ARCHITECTURE-*.md` path). History BELONGS in changelog/backlog entries,
  maintenance-docs, and IMPL reports (reference docs) — never copied into an
  operating doc. `[roles: universal] [rationale: operating-docs-no-history-no-bloat]`
```

The project-template trinity copy carries the SAME rule with project-audience anchors per cross-cli-reference-normalization (`docs/project/...` history homes, not `changelog/backlog` pack trees) — the substance is identical; the path nouns are audience-correct.

### D.2 Locations (6 trinity + justified additions)
- **Mandatory (6):** pack-root `CLAUDE.md` / `AGENTS.md` / `GEMINI.md`; `project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md`. Trinity-locked ×2 surfaces.
- **Additional — RATIONALE.md `## slug` (REQUIRED by Check 45 bijection).** Because the rule carries `[rationale: operating-docs-no-history-no-bloat]`, a matching `## operating-docs-no-history-no-bloat` section MUST exist in `pack-ops/PACK-MEMORY-RATIONALE.md` in the same commit (else Check 45 FAILS). This is not an "extra location" by choice — it is the bijection contract.
- **NO other locations.** PACK-CHAT/PACK-AGENTS get NO restatement (anti-restate; the rule is enumerated INLINE into spawn prompts when applicable). The project-template trinity already IS the client-facing home — no `docs/pack/` restatement.

### D.3 Check-45 handling (rule↔rationale bijection, lockstep)
Author the RATIONALE.md `## operating-docs-no-history-no-bloat` section TERSE (it must itself comply): Why (history in operating docs costs context every read, buries the rule, has no operational purpose; bloat compounds ×155 reads); How-to-apply (the P1-P8 strip + L1-L3 keep + the C.2 clause-preserving structural method); the permits-in-reports carve-out. Check 45 scans only `## ` slug headings — the section heading MUST be exactly `## operating-docs-no-history-no-bloat` (kebab, matches `^##\s+([a-z0-9][a-z0-9-]*)\s*$`). Lockstep: rule line ×3 trinity + the one `## slug` = one commit. (Slug is repo-unique — `grep` confirms no existing `## operating-docs` heading.)

---
## D.4 Surface-asymmetry note (project-template trinity has NO `## Pack memory`)
The project-template trinity uses TOPICAL H2s (`## Document locations` L215, `## Deferral comments and BACKLOG hygiene` L301, `## Project memory` L349), NOT a `## Pack memory` corpus. So the rule lands asymmetrically by surface (substance-identical, audience-correct — this is the sanctioned trinity asymmetry, not a parity break):
- **Pack-root:** a bullet in `## Pack memory` → `### Repo conventions`, WITH `[roles:][rationale:]` tags (Check 45 bijection applies).
- **Project-template:** a rule under `## Document locations` (recommended — it governs doc content/placement) — NO `[rationale:]` tag (that pack-only mechanism does not exist client-side). The rule's history-homes are the project streams (`docs/project/{backlog,changelog}/`, IMPL reports), not the pack trees.
This asymmetry is parity-CORRECT: trinity parity means the 3 files at ONE location agree, not that pack-root and project-template are byte-identical (they carry different audiences/rules by design — per the CLAUDE.md trinity note).

---

## E. THE NET-NEW grep-zero HISTORY GATE — Check 65 (measure-then-bound)

### E.1 Identity + registration
- **Number = 65** (measured: highest registered = 64 `check_cross_cli_mcp_config`; next free integer = 65).
- **`CHECK_REGISTRY_EXPECTED_COUNT`: 62 → 63** (+1 entry; the constant is the entry COUNT, not the max number — Checks 16/18/19 register twice + 2 carry `number=None`, so count lags max by design; Check 59 asserts `len(registry)==constant`).
- BD-206's paused design "eyed Check 65": confirmed BD-206 is NOT landed (no Check 65 in the registry @ a847f12), so **65 is genuinely free** for BD-243. (If BD-206 resumes after BD-243 lands, it takes the next free number then — a coordination note for the planner, not a blocker.)
- Function name (repo-unique): `check_operating_doc_no_history`. Per-check test (repo-unique filename): `scripts/tests/test-check-operating-doc-history.sh` (or the project's per-check test convention — planner confirms). Allowlist file (repo-unique): `pack-ops/.operating-doc-history-allowlist.txt` (modeled on `.concision-allowlist.txt`).

### E.2 Scope (measure-then-bound) — the IN set ONLY
Scan EXACTLY the ~145 IN docs (Section A). EXEMPT docs (README, supporting-docs, maintenance-docs, _toc, BD/v* entries, scripts) are NOT scanned (they legitimately hold history). The scan list is a frozen constant in the check (like Check 44's `_CHECK_44_DURABLE_DOCS`) OR derived by the same glob logic that enumerates the IN families — planner picks; the frozen-constant form is auditable and matches the Check-44 precedent.

### E.3 Detect (P1-P8 shapes) + allowlist (L1-L3, sized EXACTLY to B.1)
**Forbidden patterns (the BD/TD-provenance axis Check 44 lacks):**
- `P2` `BD-\d+\s+(deleted|added|renamed|introduced|removed|created|retired|broadened|did)` (past-action narration)
- `P3` `per\s+BD-\d+` (provenance justification)
- `P4`/`P5`/`P8` dates `20\d{2}-\d{2}-\d{2}` + `pre-20\d{2}-\d{2}-\d{2}` + `User-locked` + `incident` (OQ-1 option A: on docs NOT in Check 44's 7, Check 65 owns dates; on the 7, Check 44 already owns dates — Check 65's date pattern is suppressed for those 7 to avoid double-fail, OR planner adopts OQ-1 option B).
- `P6` `carried from|carry-over`
- `P1` bare `(BD-\d+)` provenance tag — **CAUTION:** this shape overlaps format examples + L-anchors; it is allowlisted heavily (B.1) so the gate must be ANCHOR-EXEMPT first (skip allowlisted snippets) THEN flag residue.
**Allowlist (KEEP, sized EXACTLY to the B.1 measured set):** content-anchored `snippet` records (`doc:`/`pattern:`/`snippet:`/`reason:`) for every L1-L3 live pointer + the OQ-2 format examples + the project template tokens. NO broader. A reviewer re-verifies each `reason:` still names LIVE work.
**FAIL** on any P1-P8 hit NOT covered by an allowlist snippet. **Lenient:** a missing IN doc SKIPs that doc; a missing allowlist file = empty allowlist (every hit FAILs — fail-loud, matches Check 44).

### E.4 Measure-then-bound proof (verify gate runs clean on PROJECTED post-strip state)
1. **Measured now (@ a847f12):** P1-P8 hits concentrated in ~6 pack files (RATIONALE 58, MERGE 23, CLAUDE 20, OPTIONAL 13, CONCEPTUAL 12, backlog/_rules 12, …); project-side P1-P8 = 0. L1-L3 KEEP set = the B.1 table (exhaustive).
2. **Categorize:** every P1-P8 occurrence → STRIP (B.2 recipes); every L1-L3 → allowlist record (B.1).
3. **Size allowlist = B.1 EXACTLY** — no unclassified hit admitted.
4. **Projected post-strip state:** after B.2 strips land, the only surviving BD/TD/date tokens in IN docs are the B.1 allowlist set ⇒ Check 65 scans clean (every survivor is an allowlist snippet). This is the coder's PREFLIGHT obligation (the 0-outside-allowlist proof cannot be discharged read-only — coder runs Check 65 green before IMPL-REPORT).

### E.5 CI runtime (rule: ci-check-runtime-compounding)
The scan is ~145 files × a handful of compiled regexes, in-process (no subprocess-per-file) — bounded, matches Check 44's whole-doc-line scan cost. NO whole-tree walk (scoped to the frozen IN list). Acceptable per the ×155-invocation cost model.

---

## F. ENCODING-SURFACE LOCKSTEP PLAN (rule: enumerate-encoding-surfaces)

| Surface | What it constrains | How the sweep stays in lockstep |
|---|---|---|
| **Check 45** (rule↔rationale bijection) | corpus `[rationale: slug]` set == RATIONALE.md `## slug` set | New rule's `[rationale: operating-docs-no-history-no-bloat]` + its `## slug` land SAME commit. Stripping any OTHER rule's history does NOT change its slug → bijection unaffected unless a whole rule is removed (none are). |
| **Check 16/18/19** (trinity H2 / parity / no body-scaffolding) | `## Project addenda` H2 presence + H2 parity + no scaffolding, per location | Strip P1 `(BD-NNN)` tags from `## ` headings WITHOUT dropping/renaming an H2; NEVER touch `## Project addenda`. Structural bloat conversion keeps H2 set identical ×3. |
| **Check 11** (pack agent trinity-rule symmetry, informational) | pack agent files express trinity rule symmetrically | Agent-def terseness pass keeps the symmetry statement. |
| **Check 1** (SKILL.md frontmatter) | required frontmatter fields per skill | Terseness pass on SKILL bodies NEVER strips frontmatter fields (name/description/etc.). |
| **Check 44** (M4 concision gate, 7 docs) | dates/SHA/Commit-N/Override-N/`will ` = 0 outside `.concision-allowlist.txt` | History strip on the 7 (RATIONALE is NOT one; MERGE/OPTIONAL/CONCEPTUAL/DRY-RUN/HELP-* ARE) keeps Check 44 green; bloat reduction may DROP lines under the advisory ceiling (improvement). Do NOT widen `.concision-allowlist.txt`. |
| **Trinity parity ×2 locations** | CLAUDE/AGENTS/GEMINI agree at pack-root AND at project-template | Every memory-rule / H2 / structural edit serializes across the 3 files at that location, same commit. |
| **Tri-family agent-def lock** | 16 roles ×3 families (.claude .md / .agents-plugin .md / .codex .toml) | Every per-role terseness edit touches all 3 family files for that role, same commit. |
| **ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md** (prior design, rule 9) | §5.2 bijection + §6 M4 contract | BD-243 EXTENDS it (E.1 history axis + ~145 scope); add an addendum cross-referencing Check 65 as the history-axis extension of §6 (architect-doc-reality-reconciliation). |

**Asymmetric-coverage guard:** any surface whose CONTENT the sweep changes must update its validator AND its per-check TEST in lockstep (e.g. if Check 65's frozen IN-list is edited, its per-check test's expected set updates same commit).

---

## G. RULE-10 PARALLEL-vs-DEPENDENT WAVE MAP (~145 files)

**Serialization constraints:** (a) trinity sets (3 files) serialize within a location; (b) tri-family agent sets (3 files per role) serialize per role; (c) same-file edits serialize; (d) the new-rule commit (trinity ×2 + RATIONALE slug + Check 65 + allowlist + EXPECTED_COUNT bump + per-check test) is ONE atomic commit (Check 45 + Check 59 must hold at commit time).

| Wave | Content | Parallel? | Lock |
|---|---|---|---|
| **W0 (gate first)** | Check 65 + allowlist (sized to B.1) + EXPECTED_COUNT 62→63 + per-check test + CONCISION-GUARDRAILS addendum | serial, ONE commit | validate-pack green incl. Check 59 |
| **W1 new rule** | new rule ×6 trinity (pack-root 3 + project-template 3) + RATIONALE `## slug` | serial, ONE commit (trinity ×2 + bijection) | Check 45 + 16/18/19 |
| **W2 pack history-heavy** | RATIONALE (surgical Q1); MERGE-STRATEGY; OPTIONAL-FEATURES; CONCEPTUAL-REVIEW; backlog/_rules; PACK-CHAT; PACK-AGENTS; DRY-RUN; changelog/_rules; backlog/_intro | PARALLEL across distinct files (each its own worktree wave); but root-trinity strip is its OWN serial trinity commit | per-file; Check 44/65 green |
| **W3 root-trinity history+bloat** | CLAUDE/AGENTS/GEMINI strip P2/P5 + structural mega-rule conversion (C.2) | serial, ONE trinity commit | trinity parity + Check 16/18/19 + 45 |
| **W4 project bloat — trinity** | project-template CLAUDE/AGENTS/GEMINI structural reduction | serial, ONE trinity commit | trinity parity (project loc) + 16/18/19 |
| **W5 project bloat — agent defs** | 16 roles ×3 families | PARALLEL across roles; each role = ONE serial tri-family commit (3 files) | tri-family lock per role |
| **W6 project bloat — skills + docs/pack + prompts** | 37 skills + 6 docs/pack + 10 prompts + 7 stream-meta + RUNTIME | PARALLEL (independent files) | Check 1 (skill frontmatter); same-file serialize |

W0 + W1 are the functional spine (gate then rule) and run first/serial so every later history-strip wave is gate-verified as it lands. W2/W5/W6 are the high-parallelism waves (distinct files). W3/W4 are the trinity serial bottlenecks. The new-rule's anti-bloat clause's blast radius (ongoing) exceeds its no-history clause — but the one-time sweep's volume is project-side bloat (W4-W6).

---

## H. SUCCESS CONFIRMATION
NO meaning or functionality lost — the SOLE intended functional change is the new governance rule (D). History strip is delete-only + allowlisted (no live pointer lost); bloat reduction is clause-preserving structural conversion (C.2/C.3 reviewer clause-set diff proves it). Project-side history strip ≈ 0 (already clean). All encoding surfaces (F) stay in lockstep. The gate (E) is measure-then-bound, sized exactly to the B.1 KEEP set, verified clean against the projected post-strip state.

---
## EMPIRICAL-EVIDENCE BLOCK

Runtime: HEAD `a847f120e4ada06456bec4e2bf6d275fdd8c0742`, branch v11-dev, 2026-06-21, repo `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`. Graph queried for discovery (`graphify query … --graph …/graphify-out/graph.json --backend claude-cli --budget 1500`) — returned IMPL-reports + test scripts, STALE/not-useful for encoding-surface discovery → fell through to grep/Read for every exact-state claim (G2 fallback, per rule).

**EE-1 — Next-free check number = 65; EXPECTED_COUNT 62→63.**
Cmd: `grep -oE '^\s*\(6[0-9],' scripts/validate-pack.py` ; `grep -n CHECK_REGISTRY_EXPECTED_COUNT scripts/validate-pack.py`.
Output (verbatim): registry first-fields include `(60, (61, (62, (63, (64,` — highest = 64; `CHECK_REGISTRY_EXPECTED_COUNT = 62` (line 500); comment (L478-498): "BD-231 … ADDED Check 64 … the new check's NUMBER is 64 … but this constant is the registry ENTRY COUNT — bump it 61 -> 62, NOT to 64. Numbers != entry count (Checks 16/18/19 each register TWICE and 2 checks carry number=None)."
Interpretation: next free check NUMBER = 65; the entry-count constant bumps +1 (62→63) per added entry, independent of the number.
Conclusion: **SUPPORTED.**

**EE-2 — Pack-side history density (re-measured, matches research EE-2).**
Cmd: per-file `grep -coE 'BD-[0-9]+|TD-[0-9]+'` + `grep -coE '20[0-9]{2}-[0-9]{2}-[0-9]{2}'`.
Output (verbatim): RATIONALE 58/12; MERGE-STRATEGY 23/0; CLAUDE.md 20/2; AGENTS 11/2; GEMINI 11/2; OPTIONAL-FEATURES 13/0; CONCEPTUAL-REVIEW 12/0; backlog/_rules 12/0; PACK-CHAT 8/1; PACK-AGENTS 4/0; DRY-RUN 4/0; BOUNDARY-DEFINITION 0/0; changelog/_rules 2/0; backlog/_intro 1/0.
Interpretation: history concentrated in ~6 pack files; RATIONALE heaviest; BOUNDARY clean.
Conclusion: **SUPPORTED** (independent re-measure equals research).

**EE-3 — L1-L3 live-pointer allowlist (the EXACT KEEP set).**
Cmd: `grep -rnoE '(until|as of) BD-[0-9]+' …`; `grep -rnoE '(deferred [—-]+ ?BD|blocked on BD|coordinate BD|= BD-[0-9]+)' …`; `grep -rnoE 'ARCHITECTURE-[A-Z0-9-]+\.md' …` over the pack IN set.
Output (verbatim): L1 `until BD-206` (CLAUDE 595/AGENTS 488/GEMINI 464); L2 `deferred — BD-214` (CLAUDE 610/AGENTS 503/GEMINI 479/PACK-CHAT 53), `= BD-217` (CLAUDE 420/RATIONALE 196), `coordinate BD-217` (CLAUDE 429); L3 `ARCHITECTURE-BD-119.md` (CLAUDE 39/AGENTS 41/GEMINI 40/RATIONALE 508), `ARCHITECTURE-BD-182.md` (CLAUDE 674/AGENTS 567/GEMINI 543/RATIONALE 578), `ARCHITECTURE-BD-208.md` (RATIONALE 617), `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` (PACK-CHAT 226/PACK-AGENTS 230,253/RATIONALE 469), `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` (PACK-CHAT 415).
Interpretation: the complete LIVE forward-pointer set = the B.1 table; allowlist sized exactly to it.
Conclusion: **SUPPORTED** (measure-then-bound allowlist bounded).

**EE-4 — backlog/_rules.md example-vs-provenance split.**
Cmd: `grep -nE 'BD-[0-9]+|TD-[0-9]+' backlog/_rules.md`.
Output (verbatim): L23 `deleted at BD-203` (P2 STRIP); L28 `(BD-214)` deferred (L2 KEEP); L33 `BD-215 landing first. Until then` (L2 KEEP); L38 `^BD-\d+\.md$` (KEEP example); L39 `canonical per BD-211` (P3 STRIP); L44/45 `BD-167.md` (KEEP example); L48 `canonical per BD-211` (P3 STRIP); L72 `per BD-203` (P3 STRIP); L90 `(BD-001..019) … real BD-00N.md` (KEEP factual range, OQ-2).
Interpretation: same file mixes STRIP-provenance + KEEP-examples + KEEP-live — confirms the gate must be shape-targeted + allowlisted, never blanket.
Conclusion: **SUPPORTED.**

**EE-5 — Check 44 already enforces dates/SHA on 7 pack-ops docs (the reconciliation pivot).**
Cmd: `sed -n '7746,7920p' scripts/validate-pack.py`; `python3 scripts/validate-pack.py --only-check 44`.
Output (verbatim): `_CHECK_44_FORBIDDEN_PATTERNS` = date/sha/Commit-N/Override-N/post-Commit/`will `; `_CHECK_44_DURABLE_DOCS` = 7 (BOUNDARY/CONCEPTUAL-REVIEW/DRY-RUN/HELP-PACK/HELP-TRACKER/MERGE/OPTIONAL); allowlist `pack-ops/.concision-allowlist.txt`; run = "PASSED … 0 forbidden pattern(s) outside the allowlist … 4 allowlisted operational occurrence(s)"; OPTIONAL-FEATURES advisory: 576 lines > ceiling 271. NO `BD-NNN` pattern in the set.
Interpretation: Check 65 must ADD the BD/TD axis + broaden scope; it must NOT re-invent the date gate (OQ-1). Bloat axis live + unenforced (advisory only).
Conclusion: **SUPPORTED.**

**EE-6 — Check 45 bijection mechanics + slug uniqueness.**
Cmd: `sed -n '7312,7410p' scripts/validate-pack.py`; `grep -c '^##\s+[a-z0-9-]*\s*$' RATIONALE`; `grep -oE '\[rationale:…\]' CLAUDE.md|sort -u|wc -l`; `grep -rn '## operating-docs' …`.
Output (verbatim): bijection scans `[rationale: slug]` within `## Pack memory` ↔ `^##\s+([a-z0-9][a-z0-9-]*)\s*$` headings in RATIONALE; current sets balanced at 26↔26; `## operating-docs` heading = none (slug unique).
Interpretation: new rule's `[rationale:]` + `## slug` land lockstep one commit; slug `operating-docs-no-history-no-bloat` is repo-unique.
Conclusion: **SUPPORTED.**

**EE-7 — project-template trinity has NO `## Pack memory` (surface asymmetry).**
Cmd: `grep -nE '^## ' project-template/CLAUDE.md`.
Output (verbatim): topical H2s — `## Quick reference … ## Document locations (L215) … ## Deferral comments and BACKLOG hygiene (L301) … ## Project memory (L349) … ## Project addenda (L471)`; no `## Pack memory`.
Interpretation: the new rule lands as a topical rule under `## Document locations` on the project surface (no `[rationale:]`), vs a `## Pack memory` bullet (with tags) on pack-root — sanctioned trinity asymmetry.
Conclusion: **SUPPORTED.**

**EE-8 — project-side history strip ≈ 0.**
Cmd: `grep -rnE 'BD-[0-9]+ (deleted|added|…)|per BD-[0-9]+|User-locked|pre-20…|carried from' project-template/{trinity,docs,skills,.claude,.agents-plugin,.codex}`.
Output (verbatim): 0 hits; only `TD-031` (project PM-CHAT.md:764 example) + `TD-001` (project backlog/_rules.md:14 grammar) present.
Interpretation: project-side BD-243 work is the bloat axis exclusively.
Conclusion: **SUPPORTED.**

---

## RULES-APPLIED VERIFICATION BLOCK

| Rule | Evidence (quoted/measured) | Conclusion |
|---|---|---|
| **agents-never-commit** | Only git verb run: `git rev-parse HEAD/--abbrev-ref/status --short` (read-only). Sole write = this design doc via `cat >>` to `/tmp/pack-handoff-bd243-arch/DESIGN-BD-243.md`. No repo-file edit; no patch; no OptiquityTrader write. | COMPLIANT |
| **empirical-evidence-blocks** | EE-1…EE-8 each: command + verbatim output + HEAD `a847f12` + 2026-06-21 + interpretation + SUPPORTED. Re-measured research counts (EE-2 equals research EE-2); MEASURED the L1-L3 allowlist (EE-3) + next-free check number (EE-1). | COMPLIANT |
| **ci-guard-measure-then-bound** | E.4: measured the tree (EE-2/EE-3/EE-4), categorized every occurrence P1-P8 STRIP vs L1-L3 KEEP, sized the allowlist EXACTLY to B.1 (EE-3), verified the gate runs clean on the projected post-strip state (coder PREFLIGHT). EE-5 confirms Check 65 does not widen Check 44's allowlist. | COMPLIANT |
| **rules-applied-verification-block** | This table. | COMPLIANT |
| **enumerate-encoding-surfaces** | Section F enumerates Checks 45/16/18/19/11/1/44 + trinity parity ×2 + tri-family lock + the CONCISION-GUARDRAILS doc; asymmetric-coverage guard stated (validator + per-check test update lockstep). EE-5/EE-6/EE-7 measured the constraining surfaces. | COMPLIANT |
| **graph-first-context** | Discovery query run FIRST (`graphify query … --graph /Users/.../graphify-out/graph.json --backend claude-cli --budget 1500`); STALE/unhelpful (returned IMPL-reports + test scripts) → G2 fallback to grep/Read for every exact-state claim. Injected absolute path used verbatim; QUERY only, never built. | COMPLIANT |
| **filename-uniqueness-heuristic** | New names proposed repo-unique: function `check_operating_doc_no_history`; test `test-check-operating-doc-history.sh`; allowlist `pack-ops/.operating-doc-history-allowlist.txt`; rationale slug `operating-docs-no-history-no-bloat` (EE-6 confirms no collision). Output doc `DESIGN-BD-243.md` BD-243-unique. | COMPLIANT |
| **deferral-is-scope-creep + no-deferral-without-user-direction** | Full design delivered now (taxonomy + strip recipes + bar + rule + gate + encoding + waves). The ONLY functional change is the new rule (sanctioned). 3 genuine ambiguities surfaced as OQ-1/2/3 (designed-around provisionally, not self-authorized) — no work deferred to v11.1+. | COMPLIANT |
| **architect-doc-reality-reconciliation** | Reconciled with `maintenance-docs/v11-implementation/ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md` BY FILE (C.0 + F): Check 65 EXTENDS its §6 M4 contract (adds BD/TD axis + ~145 scope) and rides its §5.2 bijection; F mandates an addendum cross-referencing Check 65 as the realized history-axis extension. | COMPLIANT |

**END — DESIGN-BD-243.md**
