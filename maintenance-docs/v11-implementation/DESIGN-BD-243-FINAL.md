# DESIGN (FINAL) — BD-243: strip historical/audit + deferred-feature mentions + bloat from operating docs; add anti-bloat governance rule

Architect: FRESH reconciliation instance (pack-architect, RO). NOT the first designer; NOT the adversarial reviewer.
Runtime HEAD `a847f120e4ada06456bec4e2bf6d275fdd8c0742`, branch v11-dev, 2026-06-21.
Supersedes `/tmp/pack-handoff-bd243-arch/DESIGN-BD-243.md` (provisional Option A). Folds USER RULINGS (OQ-1=B / OQ-2=c / OQ-3=rewrite / OQ-A-expanded / OQ-B) + all adversarial findings (BLOCKER-1/2, MAJOR-1/2, MINOR-1/2) + the §0 overriding directive (operating docs describe only what currently exists and operates — every mention of a deferred/unimplemented/off-by-default feature is bloat and is REMOVED).

---

## OPEN QUESTIONS FOR USER (mechanism-vs-mention borderlines — do not guess)

The §0 boundary: BD-243 removes doc MENTIONS / prose bloat; it does NOT remove dormant tracker CODE/mechanism (BD-214 standing decision). Where a doc is MECHANISM-INSTRUCTION (an actual operating STEP an agent executes), it is surfaced here rather than stripped.

**OQ-FINAL-1 — `pack-ops/HELP-FRAGMENT-TRACKER.md` (whole file): mention or mechanism?**
This IN doc (57 lines) is help text emitted by `pack help` describing tracker-mode commands/usage. Under §0, help text DESCRIBING a deferred (BLOCKED, off-by-default) feature is a deferred-feature mention ⇒ candidate STRIP/removal of the whole fragment. BUT it may be wired as the live OUTPUT of a `pack help <verb>` branch (a mechanism the help command executes), in which case removing it changes `pack help` behavior (out of BD-243's mention-only boundary). MEASURE-AND-SURFACE: the architect found it is an IN help-fragment, but did NOT trace whether a live `pack help` code path emits it. **Recommend: the planner's first coder traces the emit path; if NO live `pack help` branch references it → STRIP the fragment (deferred-feature doc); if a live branch emits it → it is mechanism, KEEP the file and surface the wider "should `pack help` advertise a BLOCKED feature?" question to the user as a SEPARATE concern (not BD-243).** Defaulting to: trace-then-decide, do not strip blind.

**OQ-FINAL-2 — `pack-startup` skill tracker-detection step (if any).**
The §0 worked example explicitly calls out "a pack-startup tracker-detection STEP" as mechanism, not mention. MEASURED: no tracker-detection step found in `.claude/skills/pack-startup/SKILL.md` on a token scan, BUT the architect did not exhaustively read all 11 pack skills + 5 pack agents for a tracker-MODE detection/branch instruction. **Recommend: the coder wave that touches pack skills/agents greps each for a tracker-mode CONDITIONAL/STEP (`if tracker`, `tracker mode`, `detect tracker`); a prose mention ⇒ STRIP; an executable step ⇒ SURFACE, do not strip.** This is the standing mechanism-vs-mention guard for every wave, not a one-time check.

**OQ-FINAL-3 — `backlog/_rules.md` + `changelog/_rules.md` tracker-deferral clauses: mention or write-contract mechanism?**
`backlog/_rules.md:28/33` and `changelog/_rules.md` carry "tracker mode is deferred … flat-file is the mode (BD-214/BD-215)". These are WRITE-CONTRACT docs (an agent executes them when editing entries). The clause "this stream is flat-file" IS operative mechanism (it tells the agent which mode to write in); the clause "tracker is deferred — BD-214/BD-215 landing first" is the deferred-feature MENTION wrapped around it. **Recommend: REWRITE to the operative-only form** — "This stream is flat-file per-entry." — dropping the deferred-tracker contrast + the BD-214 provenance, but KEEP the `BD-215`-blocked live pointer ONLY IF the user judges the entry-format redesign a live transitional dependency the write-contract must still name (see MAJOR-2 census BD-215 row — provisionally STRIP under §0 as a deferred-feature mention). Surfacing because it is the write-contract boundary the §0 directive's "precise boundary" paragraph flags.

If the user rules "strip blind, these are all mentions," the design degrades cleanly to maximal removal. Absent a ruling, the planner applies trace-then-decide for OQ-FINAL-1/2 and the provisional STRIP for OQ-FINAL-3.

---

## EXECUTIVE SUMMARY

**Three deliverables, one BD.**
1. **History + deferred-feature strip** across the ~145 IN docs: P1-P8 historical/audit shapes (concentrated pack-side, ~6 heavy files) PLUS the §0 deferred-feature MENTION cut (the big OQ-A expansion — every tracker-mode and other not-yet-shipped-feature mention, INCLUDING in the project-template trinity). DELETE-only; allowlist sized to the genuine-LIVE-and-CURRENT set EXACTLY.
2. **Aggressive terseness/structure** (the dominant volume axis: ~13,450 project-side IN lines + the pack-root mega-rules) — clause-preserving structural conversion, NOT deletion.
3. **ONE new governance rule** (the sole sanctioned functional change) banning (a) historical/audit text, (b) bloat, AND (c) describing deferred/unimplemented features in operating docs; permitting all three in IMPL reports + reference docs. In all 6 trinity files (+ the Check-45 RATIONALE bijection section).

**The gate consolidation (USER OQ-1=B).** A net-new grep-zero history gate **Check 65** owns the COMPLETE history axis (dates + SHA + Commit-N + Override-N + post-Commit + BD/TD-provenance + User-locked + incident + carried-from + pre-DATE) across ALL ~145 IN docs with ONE history allowlist. Existing **Check 44 is REDUCED** to its non-history role (the `will` pattern + the advisory-length ceiling); its 5 history patterns MOVE to Check 65. This is a 5-surface lockstep change (BLOCKER-1), not a no-op.

**The §0 reversal (do NOT under-apply).** The first design + adversarial both KEPT "tracker mode is deferred" in the trinity and trimmed only a citation — WRONG. The FINAL design REMOVES every deferred-feature mention entirely. The trinity states only that flat-file per-entry IS the mode, with NO contrast against a non-existent tracker alternative. This is delete-of-bloat, not behavior change: the dormant tracker CODE stays (BD-214); only the doc MENTION goes.

**Numbers (re-measured @ a847f12).** Next-free check number = **65** (highest registered = 64; verified). `CHECK_REGISTRY_EXPECTED_COUNT` **62 → 63** (+1 from Check 65 ONLY; the Check-44 reduction changes the pattern TUPLE, not the entry count — MINOR-2). Project-side history-provenance strip ≈ 0 (the only project-side deferred-feature hits are tracker mentions, now in scope under OQ-A).

**Success bar:** NO meaning/functionality lost EXCEPT the one new rule. Deferred-feature mention removal is a no-op (an agent never operates a deferred feature today; the mention is re-added when the feature ships).

---

## A. OPERATING-vs-REFERENCE TAXONOMY (the gate scope — ~145 IN)

### Criterion (settled, from research Task A + BD-243 spec)
A doc is **OPERATING (IN)** iff an agent/chat EXECUTES it as live instruction at task time (rules, agent/skill defs, prompts, write-contracts). A doc is **EXEMPT** iff it DESCRIBES / sets up / records / self-governs. Tie-breakers in order: (1) Execution → IN; (2) human-orientation audience → EXEMPT; (3) deliverable/record → EXEMPT; (4) history-home → EXEMPT.

### IN set — GATE SCOPE (~145: 33 pack + 112 project)
- **Pack (33):** root trinity (3); `pack-ops/` (10: PACK-CHAT, PACK-AGENTS, MERGE-STRATEGY, PACK-MEMORY-RATIONALE, BOUNDARY-DEFINITION, OPTIONAL-FEATURES, CONCEPTUAL-REVIEW-METHODOLOGY, DRY-RUN-MIGRATION, HELP-FRAGMENT-PACK, HELP-FRAGMENT-TRACKER); bl/cl meta (4: backlog/_rules, backlog/_intro, changelog/_rules, changelog/_intro); `.claude/skills/*/SKILL.md` (11); `.claude/agents/pack-*.md` (5).
- **Project (112, shipped):** trinity (3); `docs/pack/*.md` (6); `docs/pack/prompts/*.md` (10); `skills/*/SKILL.md` (37); `.claude/agents/*.md` (16); `.agents-plugin/optiquity-agents/agents/*.md` (16); `.agents-plugin/.../RUNTIME-SUBAGENT-PATTERN.md` (1); `.codex/agents/*.toml` (16); `docs/project/*/_*.md` (7).

### EXEMPT set (gate MUST NOT scan)
README/QUICKSTART/LICENSE/project-template README; `supporting-docs/*.md` (9); `backlog/_toc.md` + `changelog/_toc.md` (generated); `backlog/BD-*.md` + `changelog/v*.md` (history store); `maintenance-docs/**`, all `PACK-REVIEW-*`/IMPL reports; `scripts/**` + all non-agent config/`.py` (BD-243 script exemption — historical/audit text MAY remain in script comments).

### Tri-family agent-def lock
16 roles × 3 families (`.claude/*.md` + `.agents-plugin/*.md` + `.codex/*.toml`) = 48 + RUNTIME-SUBAGENT-PATTERN.md = 49 agent-def surfaces; any per-role edit touches all 3 family files in lock-step (enumerate-encoding-surfaces).

**Confirm (H):** the only intended functional change is the new rule. Every other edit is delete-history / delete-deferred-feature-mention / restructure-bloat with zero behavior change.

---

## B. STRIP RECIPES (measure-then-bound)

### B.0 Pattern set (STRIP) — the COMPLETE history axis (Check 65 owns all of it under OQ-1=B)
- **P1** BD/TD provenance tag on a rule/section `(BD-NNN …)` / inline `(BD-NNN)` anchor.
- **P2** "BD-NNN deleted/added/renamed/introduced/removed/created/retired/broadened/did" past-action narration.
- **P3** "per BD-NNN" provenance justification.
- **P4** dated note `(YYYY-MM-DD …)` / `User-locked YYYY-MM-DD`.
- **P5** `pre-YYYY-MM-DD pattern` / "the pre-DATE …" carve-out date.
- **P6** "carried from" / "carry-over" provenance.
- **P7** changelog-style past-event narration ("X was added because…").
- **P8** incident / commit-SHA references (`commit <sha>`, `incident`, `19g-pack`).
- **P-DEF (§0 deferred-feature MENTION cut — the OQ-A expansion):** any prose that DESCRIBES a deferred / unimplemented / off-by-default feature, EVEN to say it is deferred. The canonical instance is the whole tracker-mode passage. Remove the mention; state only what currently operates. (Not a grep regex shape — a content judgement per the no-describing-deferred-features test; the gate cannot regex "is this feature shipped?", so P-DEF is enforced by the new rule + reviewer, NOT by Check 65. Check 65 catches the date/BD residue a P-DEF strip leaves behind.)

### B.1 KEEP allowlist (L1-L3 + the 6 date examples) — sized EXACTLY @ a847f12
The gate's allowlist — NO broader. Two tests gate every KEEP: **(T-live)** does the token point at LIVE PENDING work the agent must act on? AND **(T-def)** does keeping it require DESCRIBING a deferred/unimplemented feature? A KEEP must pass T-live AND fail T-def (i.e. it is a live pointer that is NOT itself a deferred-feature description).

| # | Class | Snippet (content-anchored; line drifts) | Sites | KEEP basis |
|---|---|---|---|---|
| K1 | L1 `until BD-206` | "…until BD-206 retires the … mirror" | CLAUDE.md, AGENTS.md, GEMINI.md | BD-206 **Open**; live transitional pointer to the per-entry no-mirror conversion (a CURRENT in-flight migration, not a deferred feature). |
| K2 | L3 `ARCHITECTURE-BD-119.md` | migrator-framework doc ref | CLAUDE/AGENTS/GEMINI, RATIONALE | live doc cross-ref (the doc exists + is read at task time). |
| K3 | L3 `ARCHITECTURE-BD-182.md` | cross-CLI canonical table ref | CLAUDE/AGENTS/GEMINI, RATIONALE | live doc cross-ref. |
| K4 | L3 `ARCHITECTURE-BD-208.md` | rationale doc ref | RATIONALE | live doc cross-ref. |
| K5 | L3 `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` | maintainability ref | PACK-CHAT, PACK-AGENTS, RATIONALE | live doc cross-ref. |
| K6 | L3 `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` | per-entry ref | PACK-CHAT | live doc cross-ref. |
| K7 | KEEP (format example) | `BD-167.md`, `^BD-\d+\.md$` | backlog/_rules.md | filename-grammar example the write-contract acts on (not provenance). |
| K8 | KEEP (project template token) | `TD-031` example; `TD-001` / `^TD-\d+\.md$` grammar | project PM-CHAT.md, project backlog/_rules.md | illustrative/grammar token (not provenance). |
| K9 | DATE example (MAJOR-1) | `2026-04-20`, `2026-03-20` filename/heading format spec | project changelog/_format.md (4 lines) | changelog filename/heading FORMAT spec the write-contract emits. |
| K10 | DATE example (MAJOR-1) | `2026-04-20-phase-35.md` / `bare 2026-04-20.md` | project changelog/_rules.md (1) | filename grammar. |
| K11 | DATE example (MAJOR-1) | `Status: Ready (2026-06-15)` | project docs/pack/PACK-FEEDBACK.md (1) | status-line FORMAT example. |

**Allowlist topology:** content-anchored `snippet` records (like `.concision-allowlist.txt`), each with a `reason:`; a reviewer re-verifies each is still LIVE-and-CURRENT. The gate FAILS any P1-P8 hit NOT covered.

**DROPPED from KEEP vs the first design (the §0/OQ-A reversal — these were KEEP, now STRIP):**
- **BD-214 (all 5 sites: CLAUDE/AGENTS/GEMINI/PACK-CHAT + backlog/_rules):** Resolved + the whole tracker passage is a deferred-feature mention (T-def fails). STRIP the passage, not just the citation.
- **`= BD-217` / `coordinate BD-217` (CLAUDE, RATIONALE):** see B.2 census — Codex/Antigravity worktree is a v11.1 DEFERRED feature; the cross-CLI worktree-deferral note is a deferred-feature mention. STRIP (re-classified from first-design KEEP).
- **BD-215 (OPTIONAL, backlog/_rules):** the entry-format redesign is a deferred dependency of a deferred (tracker) feature — provenance to a deferred chain. STRIP (see OQ-FINAL-3).

### B.2 FULL categorized per-IN-doc BD/TD census (MAJOR-2 — every distinct token, with Status, KEEP/STRIP)
Status from `backlog/BD-NNN.md` @ a847f12. Verdict by T-live AND T-def (NOT by Status alone — a Resolved token can be a live doc-ref KEEP; an Open token can be a deferred-feature-mention STRIP).

**Root trinity `CLAUDE.md` (10 distinct; AGENTS/GEMINI mirror — trinity-locked):**
| Token | Status | Site/role | Verdict |
|---|---|---|---|
| BD-217 ×5 | Deferred | `= BD-217` / `coordinate BD-217` (Codex/Antigravity worktree, v11.1 deferred) | **STRIP** — deferred-feature mention (T-def fails). State the Claude-only worktree fact without the cross-CLI deferral note. |
| BD-214 ×3 | Resolved | tracker-deferred passage | **STRIP** — deferred-feature mention + provenance. |
| BD-226 ×2 | Resolved | path-injection / spawn-registry provenance | **STRIP** — P1/P3 provenance (rule stands without it). |
| BD-225 ×2 | Resolved | graph-first provenance | **STRIP** — P1/P3 provenance. |
| BD-203 ×2 | Resolved | "BD-203 deleted pack-ops/BACKLOG.md + CHANGELOG.md" | **STRIP** — P2 past-action (state "There is no monolithic mirror"). |
| BD-119 ×2 | Resolved | `ARCHITECTURE-BD-119.md` doc-ref | **KEEP (K2)** — live doc cross-ref. |
| BD-241 ×1 | Resolved | "the BD-241 discoverability mechanism" | **STRIP** — P3 provenance ("the mechanism" stands without the BD). |
| BD-218 ×1 | Deferred | "background SESSIONS only — BD-218" | **STRIP** — provenance/origin tag on a current rule (the rule operates today; the `— BD-218` is the tag). NB the rule itself stays; only the tag goes. |
| BD-206 ×1 | Open | `until BD-206 retires the mirror` | **KEEP (K1)** — live transitional pointer. |
| BD-182 ×1 | Resolved | `ARCHITECTURE-BD-182.md` doc-ref | **KEEP (K3)** — live doc cross-ref. |
| BD-233 ×1 (AGENTS/GEMINI only) | Deferred | "verified separately under BD-233" (cross-CLI effectiveness, deferred) | **STRIP** — deferred-work provenance/cross-ref. |

NOTE (correction to first design B.2): there are **no `## `/`### ` headings carrying `(BD-NNN)` anchors** in CLAUDE.md (grep `^##.*BD` / `^###.*BD` = 0). The BD tokens live in rule-body prose, not headings — so the Check-16/18/19 H2 caution about "don't strip a `(BD-NNN)` off a heading" does NOT apply here; there is no such heading to protect.

**`pack-ops/MERGE-STRATEGY.md` (13 distinct):**
| Token | Status | Verdict | Note |
|---|---|---|---|
| BD-088 ×6, BD-221 ×2, BD-148 ×2, BD-095 ×2, BD-085 ×2, BD-080 ×2, BD-091, BD-042, BD-142, BD-231 | all Resolved | **STRIP** | P1/P2/P3 provenance on the merge procedure (e.g. L419 "BD-101 added three verification gates" → "Three verification gates ensure …"). Each: state the procedure, drop the adder/origin. |
| BD-101 ×1 | Resolved | **STRIP** | P2 ("BD-101 added …"). |
| BD-110 ×1, BD-109 ×1 | **Open** | **STRIP (deferred-feature mention)** | L218 "`auditor-issue-tracking` agent (BD-109/BD-110) is on the v11.x [roadmap]" — describes a NOT-YET-SHIPPED agent. Under §0 a roadmap mention of an unbuilt feature is bloat ⇒ remove the sentence (it instructs nothing today). |

**`pack-ops/OPTIONAL-FEATURES.md` (7 distinct):**
| Token | Status | Verdict | Note |
|---|---|---|---|
| BD-237 ×5 | Resolved | **STRIP** | P1/P3 provenance on the graph-refresh pre-push hook feature (the feature is SHIPPED; the `(BD-237)` tags are provenance — state the operative behavior, drop the tags). |
| BD-234 ×2 | **Open** | **STRIP (deferred-feature mention)** | L445/447 "BD-234 consumes … re-tunes with measured numbers" — describes a NOT-YET-DONE re-tuning. Remove the forward-promise; keep the current cadence statement. |
| BD-225 ×2 | Resolved | **STRIP** | P1 provenance (graphify). |
| BD-218 ×1 | Deferred | **STRIP (deferred-feature mention)** | L204 "story is tracked under BD-218 (v11.1); do not set bgIsolation expecting it" — the "do not set X expecting [the unbuilt feature]" is a deferred-feature description. Rewrite to the current operative fact only ("bgIsolation governs background sessions"); drop the v11.1 forward-look. |
| BD-217 ×1 | Deferred | **STRIP** | deferred-feature (Codex/Antigravity worktree). |
| BD-215 ×1 | Deferred | **STRIP** | deferred entry-format-redesign mention. |
| BD-214 ×1 | Resolved | **STRIP** | tracker deferred-feature mention. |

**`pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` (7 distinct):**
| Token | Status | Verdict | Note |
|---|---|---|---|
| BD-110 ×5 | **Open** | **STRIP (deferred-feature mention)** | The doc's whole "Status: folds into audit-methodology SKILL when BD-110 lands … fallback before BD-110 lands … when BD-110 lands the pack-auditor agent" framing DESCRIBES an unbuilt agent + a future migration. Under §0: state the doc IS the canonical working methodology TODAY; remove the "when BD-110 lands" future-migration scaffolding entirely (it is the deferred-feature mention). The `pack-auditor`-preferred / `pack-architect`-fallback INSTRUCTION is operative today → REWRITE to name only the current path (architect-with-conceptual-prompt), dropping the unbuilt-agent preference. |
| BD-136 ×2 | **Open** | **STRIP** | L122 "see Batch 21c BD-122 ↔ BD-136 M-8 carry-forward in BD-136 File/Symbol" = P6 carry-over + provenance. Remove the cross-ref; keep the forward-compat principle. |
| BD-122 ×1, BD-118, BD-107, BD-106 | Resolved | **STRIP** | P1/P3 provenance (contract-touch-point examples). Keep the example's SHAPE, drop the BD anchors. |
| BD-226 ×1 | Resolved | **STRIP** | P1 provenance. |

**`backlog/_rules.md` (8 distinct — example-vs-provenance-vs-deferred split):**
| Token | Status | Verdict | Note |
|---|---|---|---|
| BD-167 ×3 | Resolved | **KEEP (K7)** | `BD-167.md` filename example. |
| BD-211 ×2 | Resolved | **STRIP** | P3 "canonical per BD-211" (L39/L48). |
| BD-203 ×2 | Resolved | **STRIP** | P2 "deleted at BD-203" (L23) + "per BD-203" (L72). |
| BD-215 ×1 | Deferred | **STRIP (deferred-feature mention)** | L33 "BD-215 landing first. Until then this stream is flat-file" — OQ-FINAL-3: rewrite to "This stream is flat-file per-entry." (drop the deferred entry-format-redesign dependency). |
| BD-214 ×1 | Resolved | **STRIP** | L28 tracker deferred-feature mention. |
| BD-060 ×1 | Resolved | **STRIP** | P3 provenance (TrackerProvider) — also a deferred-tracker reference. |
| BD-001 ×1, "BD-00" (the `BD-001..019` range, OQ-2) | Resolved | **STRIP whole v8 clause (OQ-2=c)** | The vestigial v8 clause "There is no `_v8-resolved-archive.md`: the former v8 summary-table rows (BD-001..019) are real `BD-00N.md` …" (~L89-91) — the entry regex `^BD-\d+\.md$` already handles BD-001..019, so the clause describes a non-existent file + dead history. STRIP entirely. |

**`pack-ops/PACK-MEMORY-RATIONALE.md` (23 distinct, 12 dated — HEAVIEST; SURGICAL):**
The file's payload IS the conceptual Why. STRIP target = dated incident narration + BD provenance; KEEP the timeless principle + How-to-apply + the L3 doc-refs. Verdicts:
- **KEEP (L3 doc-refs):** BD-119 (ARCHITECTURE-BD-119.md), BD-182 (ARCHITECTURE-BD-182.md), BD-208 (ARCHITECTURE-BD-208.md) — K2/K3/K4.
- **STRIP (deferred-feature mention):** BD-217 ×2, BD-233 ×1 (L752 "Codex/Antigravity is BD-233") — cross-CLI worktree/effectiveness deferral.
- **STRIP (P4/P8 incident narration):** BD-195 ×12 (`User-locked 2026-05-30 during BD-195 Step-7 recovery`), BD-193/194 (`BD-193 commit 85196d4 removed …` L172), BD-169 ×4 (`original incident BD-169 19g-pack, 2026-05-16` L208, `the BD-169 incident` L190), BD-175 ×2 (`2026-05-19 incident where BD-175 Phase 5 Commit 8 4120d19` L545), `the 2026-05-17 incident where commit 667d2dd shipped` (L538), BD-135 (`BD-135 renamed the colliding tracker.toml.example` L498 → state the rule without the renamer), BD-160/176/178/173/115/228/206/203/221/185/136 — all P1/P2/P3/P8 provenance on the rationale Why. REWRITE each Why to the timeless principle.
- Method: per `## slug` block, DELETE the dated-incident lead clause; REWRITE the Why to the principle; KEEP How-to-apply. RATIONALE is NOT a Check-44 doc → Check 65 scans it (all 12 SHA hits live here, all STRIP).

**`pack-ops/PACK-CHAT.md` (6 distinct, 1 dated):**
| Token | Status | Verdict |
|---|---|---|
| BD-214 ×3 | Resolved | **STRIP** — tracker deferred-feature mention (incl. L53). |
| BD-237, BD-228, BD-226, BD-225, BD-169 | Resolved | **STRIP** — P1/P3 provenance. |
| date `2026-05-16` (L151, a verbatim quote) | — | **STRIP** — P4 dated note (the quote's date is provenance; keep the directive if operative, drop the date attribution). |
| `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` / `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` | — | **KEEP (K5/K6)** — live doc cross-refs. |

**`pack-ops/PACK-AGENTS.md` (4 distinct):** BD-226/225/203/198 all Resolved → **STRIP** P1/P3 provenance; **KEEP** the `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` doc-ref (K5).

**`pack-ops/DRY-RUN-MIGRATION.md` (4 distinct):** BD-125/114/088/042 Resolved → **STRIP** P1 provenance. (Check-44 doc — already date/SHA-clean; the `will` allowlist entries stay.)

**`changelog/_rules.md` (2):** BD-214 (deferred-feature mention) + BD-203 (P2) → **STRIP** both. **`backlog/_intro.md` (1):** BD-214 → **STRIP** (deferred-feature mention).

**`pack-ops/BOUNDARY-DEFINITION.md` (0 BD/TD, 0 dated):** CLEAN of history → bloat-axis only (135 lines, under ceiling 156).

**`pack-ops/HELP-FRAGMENT-PACK.md` / `HELP-FRAGMENT-TRACKER.md`:** HELP-PACK light P1 strips. HELP-TRACKER → OQ-FINAL-1 (whole-file mention-vs-mechanism trace).

### B.3 Project-side strip
- **History-provenance ≈ 0** (re-confirmed: P2/P3/P4/P5/P6 across project trinity + docs + skills + all 3 agent families = 0 hits). The only project BD/TD tokens are `TD-031` / `TD-001` — KEEP (K8).
- **Deferred-feature mentions (OQ-A — the NEW project-side strip):** the project-template trinity carries the tracker-mode deferred-feature passage at **6 sites** (CLAUDE.md L222-223 + L241-243; AGENTS.md L206-207 + L225-227; GEMINI.md L219-220 + L238-240). **STRIP** per §0 — state only "Flat-file per-entry is the sole supported mode." with NO tracker contrast. Trinity-locked (project location) ×3.
- **Otherwise project-side BD-243 work is the BLOAT axis** (Section C).

---

## C. TERSENESS / STRUCTURE BAR (the dominant volume axis) — aggressive, meaning-preserving

### C.0 Reconciliation with ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md (rule 9 + architect-doc-reality-reconciliation)
The prior design (file: `maintenance-docs/v11-implementation/ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md`) shipped Check 44 (M4 concision gate, §6) + Check 45 (rule↔rationale bijection, §5.2) + the C2 surface-separation rule ("SHAs/dates/Commit-N/Override-N belong in reports, NOT durable docs"). BD-243 under OQ-1=B:
- **The date/SHA/Commit-N/Override-N/post-Commit history axis MOVES from §6/Check 44 to Check 65** (it is a MOVE, not an "extends" — BLOCKER-1.e). The CONCISION-GUARDRAILS addendum states this MOVE by file (F-row + §F addendum spec below).
- **Check 44 RETAINS its `will` pattern + per-doc advisory-length ceiling** (its non-history role) over its 7 docs.
- **Check 45's bijection is the lockstep mechanism the new rule's `[rationale: slug]` rides** (unchanged).
The new governance rule is the human-readable codification of the contract Check 44/45/65 enforce mechanically, plus the no-deferred-feature clause (which has no regex gate — reviewer-enforced).
DESIGN, page 1 of 2 — continues in DESIGN-BD-243-FINAL.md (Section C.1 onward).

### C.1 The four bloat types + per-rule meaning-preservation contract
| Type | Definition | Reduction method | Meaning-preservation rule |
|---|---|---|---|
| **B1 mega-bullet run-on** | one bullet packs N clauses + parentheticals (e.g. `graph-first-context` = 5,274 chars in a 768-line CLAUDE.md) | prose → nested sub-bullets / table; one clause per row | EVERY clause survives as a row; reviewer diffs clause-set before/after = equal |
| **B2 prose-that-should-be-a-table** | enumerable cases narrated in prose (e.g. ~30 denied git verbs as a comma-run) | convert to list/table | every enumerated item present in the table |
| **B3 verbosity / hedging / restatement** | persuasive padding, repeated parentheticals, imperative restated then re-argued | delete the padding; keep directive + trigger | the DIRECTIVE + its TRIGGER survive verbatim-equivalent |
| **B4 cross-file duplication** | same boilerplate ×3 tri-family / ×2 trinity | NOT dedup-able (parity by design); terseness multiplies ×3, parity-locked | each copy stays byte-parallel post-terseness |

### C.2 The trinity mega-rule method (SAFE structural conversion, clause-preserving) — mandatory for any rule >~800 chars
1. **Clause-enumerate first.** List every distinct CLAUSE (directive / trigger / exception / cross-CLI note / Trinity-exemption note). This list is the meaning-invariant.
2. **Convert prose → structured** (sub-bullets / small table), ONE clause per row. NO clause deletion — only re-shaping.
3. **Re-enumerate after.** Post-edit clause-set MUST EQUAL pre-edit set. A dropped clause = behavior change = FAIL.
4. **B3 padding within a clause** (a redundant parenthetical, a hedge) MAY be trimmed — padding only, never a directive/trigger/exception/cross-CLI semantic.
5. **Trinity-lock:** identical structural conversion to AGENTS.md + GEMINI.md in the SAME commit (Checks 16/18/19 + trinity rule).

### C.3 Reviewer no-behavior-change verification (rule-by-rule)
For EVERY swept rule the reviewer produces a **before/after clause-set diff** (from `git show HEAD:<file>` vs post-edit), asserting set-equality (modulo flagged B3 padding). A non-empty asymmetric diff that is NOT a flagged-padding trim = a meaning-loss BLOCKER. For the history/deferred-feature strip, the reviewer additionally runs Check 65 grep-zero + confirms each KEEP allowlist entry still points at LIVE-and-CURRENT work + confirms each P-DEF removal left no surviving deferred-feature description.

### C.4 Sizing (the bulk)
Project-side ≈ 13,450 IN lines (trinity 1,446; docs/pack 2,738; prompts 1,316; skills(37) 3,635; .claude agents(16) 1,818; .agents-plugin agents(16) 1,613; .codex toml(16) 884). Pack-side: root trinity 2,043; RATIONALE 764; OPTIONAL-FEATURES 576; PACK-CHAT 515; MERGE-STRATEGY 505. B1/B3 reduction is the largest payoff; tri-family parity (B4) locks the ×3 agent-def edits.

---

## D. THE NEW GOVERNANCE RULE (the one sanctioned functional change) — EXPANDED to 3 bans

### D.1 Exact text (terse — itself complies; LITERAL placeholders only, MINOR-1)
Inserted in pack-root `## Pack memory` → `### Repo conventions`:
```
- **Operating docs carry NO history, NO deferred-feature mentions; stay
  terse + structured.** An operating doc (a doc an agent/chat EXECUTES as
  live instruction — rules, agent/skill defs, prompts, write-contracts)
  carries (a) ZERO historical/audit-trail text (dated notes,
  `User-locked YYYY-MM-DD`, "BD-NNN did X" past-action narration,
  "per BD-NNN" / "carried from" provenance, incident/SHA refs); (b) ZERO
  description of a DEFERRED / unimplemented / off-by-default feature — even
  to say it is deferred (state only what currently exists and operates; the
  mention is re-added when the feature ships); and (c) is kept terse +
  structured (no mega-bullet run-ons, prose-that-should-be-a-table, or
  padding). LIVE forward-pointers to CURRENT in-flight work KEEP
  (`until BD-NNN`, an `ARCHITECTURE-*.md` path). History + roadmap belong in
  changelog/backlog entries, maintenance-docs, and IMPL reports (reference
  docs) — never copied into an operating doc.
  `[roles: universal] [rationale: operating-docs-no-history-no-bloat]`
```
The placeholders `BD-NNN` / `YYYY-MM-DD` carry NO real digits, so the rule self-satisfies Check 65 (date regex needs `20\d{2}-\d{2}-\d{2}`; `BD-\d+` needs digits). The coder PREFLIGHT verifies the rule text + the RATIONALE section trip neither pattern.

### D.2 Locations (6 trinity + the bijection-required RATIONALE section)
- **Mandatory (6):** pack-root CLAUDE/AGENTS/GEMINI.md (in `## Pack memory` → `### Repo conventions`, WITH `[roles:][rationale:]` tags) + project-template CLAUDE/AGENTS/GEMINI.md (under `## Document locations` — it governs doc content/placement — NO `[rationale:]` tag; that pack-only mechanism does not exist client-side). Trinity-locked ×2 surfaces.
- **RATIONALE.md `## operating-docs-no-history-no-bloat` (REQUIRED by Check 45 bijection).** Because the pack-root rule carries `[rationale: operating-docs-no-history-no-bloat]`, a matching `## operating-docs-no-history-no-bloat` section MUST exist in `pack-ops/PACK-MEMORY-RATIONALE.md` in the same commit (else Check 45 FAILS). Author it TERSE (it itself complies) + LITERAL placeholders only: Why (history+roadmap in operating docs costs context every read ×~155 invocations, buries the rule, has no operational purpose) ; How-to-apply (the P1-P8 strip + the §0 deferred-feature cut + the C.2 clause-preserving method + the K1-K11 KEEP set) ; the permits-in-reports carve-out.
- **NO other locations.** PACK-CHAT/PACK-AGENTS get NO restatement (anti-restate; the rule is enumerated INLINE into spawn prompts when applicable).

### D.3 Surface-asymmetry (project-template trinity has NO `## Pack memory`)
Project-template uses topical H2s (`## Document locations`, `## Deferral comments and BACKLOG hygiene`, `## Project memory`), not a `## Pack memory` corpus. The rule lands asymmetrically by surface (substance-identical, audience-correct — sanctioned trinity asymmetry): pack-root = a tagged bullet in `## Pack memory`; project-template = a rule under `## Document locations`, history-homes = the project streams (`docs/project/{backlog,changelog}/`) + IMPL reports, NO `[rationale:]` tag. Per cross-cli-reference-normalization, the path nouns are audience-correct, not byte-copied.

### D.4 Check-45 bijection lockstep + slug uniqueness
Check 45 scans `[rationale: slug]` in `## Pack memory` ↔ `^##\s+([a-z0-9][a-z0-9-]*)\s*$` headings in RATIONALE. The slug `operating-docs-no-history-no-bloat` is repo-unique (grep `## operating-docs` = none). Lockstep: the rule line ×3 pack-root trinity + the one `## slug` = ONE commit (W1). The current bijection is balanced 26↔26; the new rule moves it to 27↔27.

---

## E. THE GATE CHANGES — Check 44 REDUCTION (BLOCKER-1) + Check 65 (net-new, measure-then-bound)

### E.1 Check 44 REDUCTION (5 lockstep surfaces — BLOCKER-1; this is NOT a no-op)
Under OQ-1=B, Check 44 LOSES its 5 history patterns (they MOVE to Check 65) and RETAINS only `will` + advisory-length. Five surfaces ENCODE the moved patterns and change in lock-step (W0):
- **(a) `scripts/validate-pack.py` — `_CHECK_44_FORBIDDEN_PATTERNS`** (L7780-7787): reduce the 6-tuple to `(("will", re.compile(r"\bwill ")),)`. Remove the `date` / `sha` / `commit-N` / `override-N` / `post-Commit` entries. `_CHECK_44_DURABLE_DOCS` (the 7 docs + advisory ceilings) is UNCHANGED.
- **(b) `scripts/tests/test-validate-pack-check-44.sh`** — rewrite: KEEP Group 0 import (the 4 symbols still exist), T1 (clean-PASS), T3 (allowlisted `will`-PASS), T4 (advisory-soft), and the Group 2 HEAD exit-status case. **MOVE** T2 (injects `2026-05-30` date, asserts FAIL — L155-167) and T5's SHA half (injects `deadbeef1234`, asserts FAIL — L194-205) INTO the new `test-validate-pack-check-65.sh` as Check-65 FAIL cases. T5's "allowlist-is-not-a-blanket" intent re-homes to Check 65 (a different forbidden hit on an allowlisted doc still FAILs). NB: under reduced Check 44, a `will`-only allowlist + a `will`-only pattern means T5's SHA injection no longer fails Check 44 — so T5 MUST move, not stay.
- **(c) `pack-ops/.concision-allowlist.txt`** — rewrite the HEADER (drop the L9-13 + L26-32 documentation of dates/SHAs/Commit-N/Override-N/post-Commit as Check-44-forbidden; the file now allowlists ONLY `will`). The 6 `will` records STAY unchanged. State the date/SHA/etc. axis now lives in Check 65's allowlist (`.operating-doc-history-allowlist.txt`).
- **(d) `scripts/validate-pack.py` Check-44 comment/docstring/fail-message** (L7746-7772 comment block, L7829-7852 docstring, L7887-7900 fail-message) — rewrite to describe ONLY the `will` teeth + advisory length; remove the dates/SHAs/Commit-N/Override-N/post-Commit enumeration; point the history axis at Check 65.
- **(e) `maintenance-docs/v11-implementation/ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md` addendum** (architect-doc-reality-reconciliation) — append an addendum stating the date/sha/Commit-N/Override-N/post-Commit history axis **MOVED from §6/Check 44 to Check 65** (a MOVE, not "Check 65 extends §6"), naming the realized consumer by file+symbol (`scripts/validate-pack.py` `check_operating_doc_no_history` / Check 65). §6 M4's `will` + advisory-length role is retained on Check 44.

**Registry impact:** Check 44 stays ONE registry entry (a pattern-tuple reduction does not change entry count). Check 59 unaffected by (a)-(e); the +1 to `CHECK_REGISTRY_EXPECTED_COUNT` is solely Check 65 (MINOR-2).

**BLOCKER-2 fix (dead Option-A logic deleted):** the first design's "suppress dates on the 7 docs to avoid double-fail" (Section E.3) is DELETED. Measured: the 7 Check-44 docs are date/sha/Commit-N/Override-N/post-Commit CLEAN (0 hits each) → Check 65 owning those patterns on the 7 yields ZERO new failures, and there is NO double-fail to suppress (Check 44 no longer owns them). Check 65's pattern set is UNIFORM across all ~145 IN docs — no per-doc suppression.

### E.2 Check 65 — identity + registration
- **Number = 65** (highest registered = 64 `check_dangling_example_deliverable_refs`; next free integer = 65, verified).
- **`CHECK_REGISTRY_EXPECTED_COUNT`: 62 → 63** (+1 entry; the constant is the entry COUNT, not the max number — 16/18/19 register twice + 2 carry `number=None`, so count lags max by design; Check 59 asserts `len(registry) == constant`). Run @ a847f12: "62 entries == constant" → bump to 63.
- **Function name (repo-unique):** `check_operating_doc_no_history`. **Per-check test (repo-unique):** `scripts/tests/test-validate-pack-check-65.sh`. **Allowlist file (repo-unique):** `pack-ops/.operating-doc-history-allowlist.txt` (modeled on `.concision-allowlist.txt`). (planner confirms the per-check test filename matches the project convention.)
- **Registry wiring:** add `(65, "check_operating_doc_no_history", check_operating_doc_no_history, W)` to `_build_check_registry()`; Check 43 enforces the per-check-test wiring.

### E.3 Check 65 — scope (measure-then-bound), the IN set ONLY
Scan EXACTLY the ~145 IN docs (Section A). EXEMPT docs are NOT scanned (they legitimately hold history). The scan list is a FROZEN constant `_CHECK_65_OPERATING_DOCS` (auditable; matches the Check-44 `_CHECK_44_DURABLE_DOCS` precedent) OR the glob logic that enumerates the IN families — planner picks; the frozen-constant form is the auditable default. CI runtime: ~145 files × a handful of compiled regexes, in-process (no subprocess-per-file), scoped to the frozen list (NO whole-tree walk) — bounded, matches Check 44's cost; acceptable per the ×~155-invocation cost model (ci-check-runtime-compounding).

### E.4 Check 65 — detect (the COMPLETE history axis) + allowlist (sized EXACTLY to B.1)
**Forbidden patterns (uniform across all IN docs — the 5 moved-from-44 + the BD/TD axis 44 never had):**
- `date` `20[0-9]{2}-[0-9]{2}-[0-9]{2}` ; `sha` `\b[0-9a-f]{7,40}\b` ; `commit-N` `Commit [0-9]` ; `override-N` `Override [0-9]` ; `post-Commit` `post-Commit` (the 5 moved from Check 44).
- `P2` `BD-\d+\s+(deleted|added|renamed|introduced|removed|created|retired|broadened|did)` (past-action).
- `P3` `per\s+BD-\d+` (provenance justification).
- `P5` `pre-20[0-9]{2}-[0-9]{2}-[0-9]{2}` ; `User-locked` ; `incident` ; `carried from|carry-over` (P5/P6/P8 textual).
- `P1` bare `\(BD-\d+\)` / inline `BD-\d+` provenance tag — **CAUTION:** overlaps format examples (K7) + live anchors (K1) + doc-refs (K2-K6); the gate is ANCHOR-EXEMPT FIRST (skip allowlisted snippets) THEN flags residue.
**Allowlist (KEEP — sized EXACTLY to the B.1 K1-K11 set):** content-anchored records (`doc:`/`pattern:`/`snippet:`/`reason:`) for K1-K11 — the live doc-refs (K2-K6), the live `until BD-206` (K1), the format examples (K7/K8), AND the 6 date examples (K9/K10/K11 — MAJOR-1). NO broader. A reviewer re-verifies each `reason:` still names LIVE-and-CURRENT work.
**FAIL** on any forbidden hit NOT covered by an allowlist snippet. **Lenient:** a missing IN doc SKIPs that doc; a missing allowlist file = empty allowlist (every hit FAILs — fail-loud, matches Check 44).
**NB the deferred-feature MENTION cut (P-DEF) is NOT a Check-65 regex** — the gate cannot regex "is this feature shipped?". P-DEF is enforced by the new rule (D) + the reviewer (C.3). Check 65 catches the date/BD RESIDUE a P-DEF strip leaves behind (e.g. a stripped tracker passage that left a `(BD-214)` token).

### E.5 Check 65 — measure-then-bound proof (verify gate runs clean on projected post-strip state)
1. **Measured @ a847f12:** P1-P8 hits concentrated in ~6 pack files (RATIONALE 23 distinct BD + 12 dated; MERGE 13; CLAUDE 10; OPTIONAL 7; CONCEPTUAL 7; backlog/_rules 8); project-side history-provenance = 0; project-side date EXAMPLES = 6 (K9-K11). SHA-pattern hits: pack-side only RATIONALE (12, all STRIP incidents); project-side 0.
2. **Categorize:** every P1-P8 occurrence → STRIP (B.2 recipes) or KEEP (K1-K11 allowlist). Every Open/Deferred token re-judged by FUNCTION (T-live AND T-def): BD-206 KEEP (live current migration); BD-110/109/234/136/215/217/218/233 STRIP (deferred-feature mentions / provenance), NOT KEEP despite Open/Deferred status.
3. **Size allowlist = K1-K11 EXACTLY** — no unclassified hit admitted; no widening to borderline.
4. **Projected post-strip state:** after B.2 strips + the §0 deferred-feature cuts land, the only surviving forbidden tokens in IN docs are K1-K11 ⇒ Check 65 scans clean. The 0-outside-allowlist proof is the coder's PREFLIGHT obligation (cannot be discharged read-only — coder runs Check 65 green before IMPL-REPORT). The 7 Check-44 docs stay green (measured 0 history hits) when Check 65 takes their date/SHA patterns.

---

## F. ENCODING-SURFACE LOCKSTEP PLAN (enumerate-encoding-surfaces — asymmetric coverage = defect)

| Surface | What it constrains | Lockstep action |
|---|---|---|
| **Check 44 (REDUCED)** | `will` + advisory over 7 docs | W0: reduce `_CHECK_44_FORBIDDEN_PATTERNS` to `("will",)`; rewrite its comment/docstring/fail-message; the `.concision-allowlist.txt` header; MOVE its test's date+SHA FAIL cases to Check-65's test (E.1.a-d). |
| **Check 44 per-check TEST** | `test-validate-pack-check-44.sh` asserts date/SHA FAIL | W0: rewrite — keep `will`/advisory/clean cases; MOVE T2 (date) + T5-SHA to `test-validate-pack-check-65.sh` (E.1.b). |
| **`.concision-allowlist.txt`** | header docs the forbidden set | W0: rewrite header to `will`-only; 6 `will` records unchanged (E.1.c). |
| **Check 65 (NEW) + its test + allowlist** | history axis over ~145 IN | W0: add `check_operating_doc_no_history` (65) + `.operating-doc-history-allowlist.txt` (K1-K11) + `test-validate-pack-check-65.sh` (incl. moved date+SHA cases) + EXPECTED_COUNT 62→63 (E.2-E.5). |
| **Check 59 (registry count)** | `len(registry) == EXPECTED_COUNT` | W0: EXPECTED_COUNT 62→63 (Check 65 +1; Check-44 reduction is +0). Same commit as the registry add. |
| **Check 45 (rule↔rationale bijection)** | corpus `[rationale: slug]` set == RATIONALE `## slug` set | W1: new rule's `[rationale: operating-docs-no-history-no-bloat]` + its `## slug` land SAME commit (26↔26 → 27↔27). Stripping any OTHER rule's history does NOT remove its slug (no whole rule is removed) → bijection unaffected by the strip waves. |
| **Check 16/18/19 (trinity H2 / parity / no scaffolding)** | `## Project addenda` presence + H2 parity + no scaffolding, per location | W1/W3/W4: keep the H2 set identical ×3; NEVER touch `## Project addenda`. (Measured: no `(BD-NNN)` lives on any `## `/`### ` heading in CLAUDE.md, so the strip does not touch an H2.) |
| **Check 11 (pack agent trinity-rule symmetry, informational)** | pack agents express trinity rule symmetrically | W (pack agents): terseness keeps the symmetry statement. |
| **Check 1 (SKILL frontmatter)** | required frontmatter fields per skill | W6: terseness on SKILL bodies NEVER strips frontmatter. |
| **CONCISION-GUARDRAILS.md (prior design)** | §6 M4 contract + §5.2 bijection | W0: append the MOVE addendum (E.1.e); §6 M4 = `will`+advisory only; the history axis names Check 65 (architect-doc-reality-reconciliation). |
| **Trinity parity ×2 locations** | CLAUDE/AGENTS/GEMINI agree at pack-root AND project-template | Every memory-rule / H2 / structural / strip edit serializes across the 3 files at that location, same commit. |
| **Tri-family agent-def lock** | 16 roles ×3 families | Every per-role terseness edit touches all 3 family files for that role, same commit. |

**Asymmetric-coverage guard:** any surface whose CONTENT a wave changes updates its validator AND its per-check TEST in lock-step (e.g. editing Check 65's frozen IN-list updates the Check-65 test's expected set same commit; the Check-44 reduction updates the Check-44 test same commit).

---

## G. RULE-10 PARALLEL-vs-DEPENDENT WAVE MAP (~145 files)

**Serialization constraints:** (a) trinity sets (3 files) serialize within a location; (b) tri-family agent sets (3 files/role) serialize per role; (c) same-file edits serialize; (d) the new-rule commit (W1) is ONE atomic commit (Check 45 + Check 59 must hold at commit time); (e) the gate commit (W0) is ONE atomic commit (Check 59 + Check 43 + both per-check tests green).

| Wave | Content | Parallel? | Lock |
|---|---|---|---|
| **W0 (gate first — now includes the Check 44 REDUCTION)** | Check 44 reduction (5 surfaces: pattern tuple + test + allowlist header + comment/docstring/fail-message + CONCISION-GUARDRAILS addendum) + Check 65 (`check_operating_doc_no_history` + `.operating-doc-history-allowlist.txt` sized to K1-K11 + `test-validate-pack-check-65.sh` incl. the MOVED date+SHA cases) + EXPECTED_COUNT 62→63 | serial, ONE commit | validate-pack green incl. Check 59 + Check 43; Check 44 + Check 65 tests pass |
| **W1 (new rule)** | new rule ×6 trinity (pack-root 3 + project-template 3) + RATIONALE `## operating-docs-no-history-no-bloat` | serial, ONE commit (trinity ×2 + bijection) | Check 45 + 16/18/19 |
| **W2 (pack history-heavy strip)** | RATIONALE (surgical); MERGE-STRATEGY; OPTIONAL-FEATURES; CONCEPTUAL-REVIEW; backlog/_rules (incl. OQ-2=c v8 clause); PACK-CHAT; PACK-AGENTS; DRY-RUN; changelog/_rules; backlog/_intro; HELP-FRAGMENT-PACK; HELP-FRAGMENT-TRACKER (per OQ-FINAL-1 trace) | PARALLEL across distinct files (each its own worktree wave) | per-file; Check 44/65 green |
| **W3 (root-trinity strip + bloat)** | CLAUDE/AGENTS/GEMINI: STRIP P2/P3 provenance + the §0 deferred-feature mentions (tracker BD-214, BD-217/233 cross-CLI worktree, BD-218/241/225/226 tags) + OQ-3 carve-out REWRITES + structural mega-rule conversion (C.2) | serial, ONE trinity commit | trinity parity + Check 16/18/19 + 45 |
| **W4 (project bloat + deferred-feature strip — trinity)** | project-template CLAUDE/AGENTS/GEMINI: STRIP the 6-site tracker deferred-feature passages (OQ-A) + structural reduction | serial, ONE trinity commit | trinity parity (project loc) + 16/18/19 |
| **W5 (project bloat — agent defs)** | 16 roles ×3 families + RUNTIME-SUBAGENT-PATTERN | PARALLEL across roles; each role = ONE serial tri-family commit (3 files) | tri-family lock per role |
| **W6 (project bloat — skills + docs/pack + prompts + stream-meta)** | 37 skills + 6 docs/pack + 10 prompts + 7 stream-meta (incl. OQ-B `audit-methodology/SKILL.md:76` `_v8-resolved-archive.md` strip) | PARALLEL (independent files) | Check 1 (skill frontmatter); same-file serialize |

W0 + W1 are the functional spine (gate then rule) and run FIRST/serial so every later strip wave is gate-verified as it lands. W2/W5/W6 are high-parallelism (distinct files). W3/W4 are the trinity serial bottlenecks. OQ-3 (CLAUDE/AGENTS/GEMINI carve-out rewrites — "Never delay per-BD reviews to end-of-batch retroactive recovery." keeping the unconditional rule, dropping "that is an exception for pre-2026-05-15 batches only"; and "User approves the resulting fix commit." dropping "not per-finding approval — that was the pre-2026-05-16 pattern…") rides W3. OQ-B (`audit-methodology/SKILL.md:76`) rides W6. The mechanism-vs-mention OQ-FINAL-1/2/3 borderlines resolve at the planner's trace step before their wave's coder runs.

**BD-206 coordination note (not a blocker):** BD-206 (PAUSED) handles the per-entry no-mirror FUNCTIONAL conversion; BD-243 handles operating-doc history/bloat/deferred-feature mentions. When BD-206 resumes it coordinates against BD-243's as-landed docs. Check 65 (number 65) is taken by BD-243; if BD-206's paused design eyed 65, it takes the next free number on resume.

---

## H. SUCCESS CONFIRMATION
NO meaning or functionality lost — the SOLE intended functional change is the new governance rule (D). History strip is delete-only + allowlisted (no live pointer lost; K1-K11 are content-anchored + reviewer-re-verified LIVE). The §0 deferred-feature mention removal is a no-op (an agent never operates a deferred feature today; the mention re-adds when the feature ships; the dormant tracker CODE is untouched — BD-214's standing decision). Bloat reduction is clause-preserving structural conversion (C.2/C.3 reviewer clause-set diff proves it). Project-side history-provenance ≈ 0; project-side BD-243 work = the bloat axis + the 6-site tracker deferred-feature strip. All encoding surfaces (F) stay in lockstep (Check 44 reduced across 5 surfaces; Check 65 added with its test + allowlist; EXPECTED_COUNT +1). The gates (E) are measure-then-bound, sized exactly to K1-K11, verified clean against the projected post-strip state.

---

## EMPIRICAL-EVIDENCE BLOCK

Runtime: HEAD `a847f120e4ada06456bec4e2bf6d275fdd8c0742`, branch v11-dev, 2026-06-21, repo `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`. Graph queried for discovery; STALE for BD-243-era surfaces → grep/Read/git for every exact-state claim (G2 fallback, per rule).

**EE-1 — runtime HEAD = BD-243 commit.** Cmd: `git rev-parse HEAD; git branch --show-current`. Output: `a847f120e4ada06456bec4e2bf6d275fdd8c0742` ; `v11-dev`. Conclusion: **SUPPORTED.**

**EE-2 — next-free check number = 65; registry count = 62; EXPECTED_COUNT 62→63.** Cmd: `grep -nE '^\s+\(6[0-9], "check_' scripts/validate-pack.py` ; `python3 scripts/validate-pack.py --only-check 59`. Output (verbatim): registry numbers `(60..64)` present, highest `(64, "check_dangling_example_deliverable_refs"`; Check 59 "CHECK_REGISTRY has 62 entr(y/ies) (== CHECK_REGISTRY_EXPECTED_COUNT)". Interpretation: next-free NUMBER = 65; the entry-count constant bumps +1 (62→63) for Check 65; the Check-44 pattern reduction does NOT change the count. Conclusion: **SUPPORTED** (MINOR-2 confirmed).

**EE-3 — Check 44 pattern set + the 5 history patterns to MOVE.** Cmd: `sed -n '7780,7805p' scripts/validate-pack.py`. Output (verbatim): `_CHECK_44_FORBIDDEN_PATTERNS = (("date", 20[0-9]{2}-…), ("sha", \b[0-9a-f]{7,40}\b), ("commit-N", Commit [0-9]), ("override-N", Override [0-9]), ("post-Commit", post-Commit), ("will", \bwill ))` ; `_CHECK_44_DURABLE_DOCS` = 7 (BOUNDARY 156, CONCEPTUAL 343, DRY-RUN 229, HELP-PACK 49, HELP-TRACKER 57, MERGE 557, OPTIONAL 271). No `BD-NNN` pattern. Interpretation: 5 of 6 patterns are history-class (move to 65); `will` stays on 44. Conclusion: **SUPPORTED** (BLOCKER-1 basis).

**EE-4 — Check 44 per-check test breaks under the reduction (test surfaces to MOVE).** Cmd: read `scripts/tests/test-validate-pack-check-44.sh`. Output (verbatim): L56-57 import the 4 symbols; T2 (L155-167) injects `This rule was locked on 2026-05-30`, asserts `fc>=1` + "OUTSIDE the allowlist" + "2026-05-30"; T5 (L193-206) injects `commit deadbeef1234`, asserts `fc>=1` + "deadbeef1234". Interpretation: T2 + T5-SHA break under reduced Check 44 (no longer owns date/sha) → MOVE both to the Check-65 test. T1/T3/T4/Group-0/Group-2 stay. Conclusion: **SUPPORTED** (BLOCKER-1.b).

**EE-5 — allowlist has 0 history entries to migrate (all 6 are `will`).** Cmd: read `pack-ops/.concision-allowlist.txt`. Output (verbatim): 6 records, all `pattern: will` (DRY-RUN ×2, MERGE ×2, OPTIONAL ×2); header L9-13 + L26-32 document dates/SHAs/Commit-N/Override-N/post-Commit as forbidden. Interpretation: under the reduction the 6 `will` records STAY; ZERO history records migrate; the header rewrites to `will`-only. Conclusion: **SUPPORTED** (A.ii confirmed).

**EE-6 — the 7 Check-44 docs are history-clean (BLOCKER-2 basis — no double-fail to suppress).** Per the adversarial EE-3 (re-confirmed by inspection that none of the 7 carry a `2026-…` date / 7-40-hex SHA / `Commit N` / `Override N` / `post-Commit`): all 7 return 0 on each history pattern. Interpretation: Check 65 owning those patterns on the 7 yields ZERO new failures; the first design's "suppress for the 7" logic is dead. Conclusion: **SUPPORTED** (BLOCKER-2 fix justified).

**EE-7 — the 6 legitimate date EXAMPLE sites (MAJOR-1, allowlist K9-K11).** Cmd: `grep -nE '20[0-9]{2}-[0-9]{2}-[0-9]{2}' project-template/docs/project/changelog/_format.md project-template/docs/project/changelog/_rules.md project-template/docs/pack/PACK-FEEDBACK.md` ; `grep -cE` on _format.md. Output (verbatim): `_format.md` 4 hits (L62 `### 2026-04-20 — Phase 35 …`, L63 `→ 2026-04-20-phase-35.md`, L64 `### 2026-03-20 — Architecture Iteration …`, L65 `→ 2026-03-20-architecture-iteration.md`); `_rules.md` 1 (L15 `2026-04-20-phase-35.md or bare 2026-04-20.md`); `PACK-FEEDBACK.md` 1 (L156 `Status: Ready (2026-06-15)`). Interpretation: 6 legitimate format-spec examples ⇒ K9-K11 allowlist, sized exactly. Conclusion: **SUPPORTED** (MAJOR-1).

**EE-8 — FULL per-IN-doc BD/TD census with Status (MAJOR-2).** Cmd: per-doc `grep -oE 'BD-[0-9]+|TD-[0-9]+' | sort | uniq -c` over the heavy docs; per-token `grep -m1 '^Status:' backlog/BD-NNN.md`. Output (verbatim, distinct tokens): CLAUDE 10 (BD-217×5,214×3,226×2,225×2,203×2,119×2,241,218,206,182); AGENTS/GEMINI add BD-233; MERGE 13 (BD-088×6,221,148,095,085,080×2 each,231,142,110,109,101,091,042); OPTIONAL 7 (BD-237×5,234×2,225×2,218,217,215,214); CONCEPTUAL 7 (BD-110×5,136×2,226,122,118,107,106); backlog/_rules 8 (BD-167×3,211×2,203×2,215,214,060,001,"BD-00"); RATIONALE 23 (BD-195×12,193×6,208×4,169×4,194×3,185×3,160×3,228,225,217,182,176,175,119,115×2 each,233,221,206,203,178,173,135); PACK-CHAT 6 (BD-214×3,237,228,226,225,169); PACK-AGENTS 4 (BD-226,225,203,198); DRY-RUN 4 (BD-125,114,088,042); changelog/_rules 2 (BD-214,203); backlog/_intro 1 (BD-214). Statuses: BD-206/110/109/136/234 **Open**; BD-215/217/218/233 **Deferred**; all others **Resolved**. Interpretation: categorized in B.2 by FUNCTION (T-live AND T-def) — only BD-206 (K1) + the ARCHITECTURE-doc-refs BD-119/182/208 (K2-K4) + BD-167 example (K7) KEEP; the Open/Deferred BD-110/109/136/234/215/217/218/233 are deferred-feature mentions/provenance → STRIP (NOT KEEP despite status). Conclusion: **SUPPORTED** (MAJOR-2 exhaustive census).

**EE-9 — OQ-A tracker deferred-feature mentions (pack + project trinity).** Cmd: `grep -n -i tracker CLAUDE.md` ; `sed -n '585,611p' CLAUDE.md` ; `grep -rn -i 'tracker\|deferred\|dormant' project-template/{CLAUDE,AGENTS,GEMINI}.md`. Output (verbatim): pack CLAUDE.md L597-600 "Tracker (GH Issues) integration is DEFERRED indefinitely … the tracker code is retained DORMANT", L610 "tracker mode is deferred — BD-214", L765 "tracker integration is deferred"; project-template CLAUDE.md L222-223 + L241-243, AGENTS.md L206-207 + L225-227, GEMINI.md L219-220 + L238-240 — all "tracker mode is deferred indefinitely … tracker code retained dormant". Interpretation: 6 project-trinity sites + 3 pack-trinity passages describe a deferred feature ⇒ §0 STRIP entirely (state only "Flat-file per-entry is the sole supported mode"). Conclusion: **SUPPORTED** (OQ-A expansion).

**EE-10 — OQ-2=c v8 clause + OQ-B dangling ref.** Cmd: `sed -n '86,92p' backlog/_rules.md` ; `grep -n '_v8-resolved-archive' project-template/skills/audit-methodology/SKILL.md`. Output (verbatim): backlog/_rules.md ~L89-91 "There is no `_v8-resolved-archive.md`: the former v8 summary-table rows (BD-001..019) are real `BD-00N.md` …" ; `audit-methodology/SKILL.md:76` asserts `_v8-resolved-archive.md` exists ("pack `/backlog/` only per integration parent §2.6"). Interpretation: OQ-2=c strips the whole v8 clause (entry regex `^BD-\d+\.md$` already handles BD-001..019); OQ-B strips/corrects SKILL.md:76 (references a non-existent file). Conclusion: **SUPPORTED.**

**EE-11 — OQ-3 carve-outs dead + trinity ×3; rewrite meaning-preserving.** Cmd: `grep -nE 'pre-20[0-9]{2}-[0-9]{2}-[0-9]{2}' CLAUDE.md AGENTS.md GEMINI.md` ; `sed -n '205,222p' CLAUDE.md`. Output (verbatim): carve-out 1 "that is an exception for pre-2026-05-15 batches only" (CLAUDE L214, AGENTS L216, GEMINI L183) on rule "Never delay per-BD reviews to end-of-batch retroactive recovery"; carve-out 2 "was the pre-2026-05-16 pattern and produced too much friction" (CLAUDE L221, AGENTS L223, GEMINI L190) on rule "User approves the resulting fix commit". Interpretation: both dated carve-outs are vestigial (all current work post-dates them); REWRITE keeps the unconditional operative directive, drops the dead carve-out + date — trinity-locked ×3. Conclusion: **SUPPORTED** (OQ-3).

**EE-12 — project-side history-provenance ≈ 0; slug unique; new-rule self-safe.** Cmd: `grep -rnE 'BD-[0-9]+ (deleted|added|…)|per BD-[0-9]+|User-locked|pre-20…|carried from|carry-over'` over project IN families (minus tracker) ; `grep -rn '## operating-docs' CLAUDE.md pack-ops/PACK-MEMORY-RATIONALE.md`. Output (verbatim): 0 non-tracker provenance hits project-side; `## operating-docs` heading = none. Interpretation: project-side strip = the bloat axis + the OQ-A tracker mentions only; slug `operating-docs-no-history-no-bloat` is repo-unique; the D.1 rule text uses literal `BD-NNN`/`YYYY-MM-DD` (no digits) → self-safe vs Check 65. Conclusion: **SUPPORTED** (MAJOR-2 project half + MINOR-1).

**EE-13 — no `(BD-NNN)` on any CLAUDE.md heading (correction to first design B.2).** Cmd: `grep -nE '^## .*BD-[0-9]+|^### .*BD-[0-9]+' CLAUDE.md`. Output (verbatim): (empty). Interpretation: the first design's claim "P1 section anchors (BD-119)/(BD-225)/(BD-226) on `## ` headings" is WRONG — the BD tokens live in rule-body prose, not headings; the Check-16/18/19 H2-protection caution does not apply to a heading anchor (there is none). Conclusion: **SUPPORTED** (challenge to first design, evidence-based).

---

## RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **reconciliation-instance-independence** | Fresh reconciliation instance; did NOT author DESIGN-BD-243.md, am NOT the adversarial reviewer. Folded all USER RULINGS (OQ-1=B/OQ-2=c/OQ-3/OQ-A-expanded/OQ-B) + all adversarial findings (BLOCKER-1/2, MAJOR-1/2, MINOR-1/2). One evidence-based CHALLENGE recorded (EE-13: first design's "(BD-NNN) on headings" claim refuted by `grep ^##.*BD = empty`); all other rulings/findings adopted as binding. | COMPLIANT |
| **agents-never-commit** | Only git verbs run: `git rev-parse HEAD`, `git branch --show-current` (read-only). Sole write = this design doc via `cat >>` to `/tmp/pack-handoff-bd243-arch/DESIGN-BD-243-FINAL.md`. No repo-file edit; no patch; no OptiquityTrader write. | COMPLIANT |
| **empirical-evidence-blocks** | EE-1…EE-13 each: command + verbatim output + HEAD `a847f12` + 2026-06-21 + interpretation + SUPPORTED. RE-MEASURED: the FULL per-IN-doc BD/TD census with statuses (EE-8, MAJOR-2); the 6 date examples (EE-7, MAJOR-1); the Check-44 reduction surfaces (EE-3/EE-4/EE-5, BLOCKER-1); the tracker-mention sites pack+project (EE-9, OQ-A); next-free number + EXPECTED_COUNT (EE-2, MINOR-2). | COMPLIANT |
| **ci-guard-measure-then-bound** | Check 65 + reduced Check 44 + allowlist: measured the tree FIRST (EE-7/EE-8/EE-9); categorized EVERY occurrence STRIP (history/deferred-feature) vs KEEP (K1-K11 live-pointer/legit-example) by FUNCTION not status; sized the allowlist EXACTLY to K1-K11 (incl. the 6 date examples, NO widening to borderline Open/Deferred tokens); verified the gate runs clean on the projected post-strip state (E.5, coder PREFLIGHT) incl. the 7 Check-44 docs staying green (EE-6). | COMPLIANT |
| **rules-applied-verification-block** | This table. | COMPLIANT |
| **enumerate-encoding-surfaces** | Section F enumerates EVERY surface the Check-44 reduction touches (its pattern tuple + test + allowlist header + comment/docstring/fail-message + CONCISION-GUARDRAILS addendum — 5) + Check 65 + its test + its allowlist + Check 59 (EXPECTED_COUNT) + Checks 45/16/18/19/11/1 + trinity parity ×2 + tri-family lock; asymmetric-coverage guard stated (validator + per-check test update lock-step). EE-3/EE-4/EE-5 measured the Check-44 surfaces. | COMPLIANT |
| **graph-first-context** | Discovery query attempted FIRST; STALE for BD-243-era surfaces → G2 fallback to grep/Read/git for every exact-state claim. Injected absolute path form used; QUERY only, never built. | COMPLIANT |
| **deferral-is-scope-creep + no-deferral-without-user-direction** | Full final design delivered now (taxonomy + full census + recipes + bar + rule + both gate changes + encoding + waves). The ONLY functional change is the new rule (sanctioned). The dormant tracker-CODE retention is a STANDING BD-214 decision (not a deferral introduced here). Genuine mechanism-vs-mention ambiguities surfaced as OQ-FINAL-1/2/3 (trace-then-decide), not self-authorized; no work deferred to v11.1+. | COMPLIANT |
| **architect-doc-reality-reconciliation** | E.1.e + the F-row: the CONCISION-GUARDRAILS addendum states the date/sha/Commit-N/Override-N/post-Commit axis MOVED from §6/Check 44 to Check 65 (a MOVE, not "extends"), naming the realized consumer by file+symbol (`scripts/validate-pack.py` `check_operating_doc_no_history` / Check 65). | COMPLIANT |
| **filename-uniqueness-heuristic** | New names proposed repo-unique: function `check_operating_doc_no_history`; test `test-validate-pack-check-65.sh`; allowlist `pack-ops/.operating-doc-history-allowlist.txt`; rationale slug `operating-docs-no-history-no-bloat` (EE-12 confirms no `## operating-docs` collision). Output doc `DESIGN-BD-243-FINAL.md` BD-243-unique. | COMPLIANT |

**END — DESIGN-BD-243-FINAL.md**
