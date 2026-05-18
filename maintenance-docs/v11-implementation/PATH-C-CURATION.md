# Path C — User curation

**Source:** `ARCHITECTURE-BATCH-19B-STRATEGIC-PRINCIPLES.md` (Path C architect synthesis, 766 lines).

**Purpose:** User's curated priorities (HIGH / MEDIUM / DROP) for each Path C item, plus notes. This doc is INPUT to V2 architect's scaffolding (Step 4 of today's plan).

**Date:** 2026-05-18.

**How to read:** Tags reflect the user's priority for landing the item in V2 architect's scope, NOT the user's assessment of correctness. A MEDIUM tag means "land it but it's not the top priority." A DROP tag means "do not land in this batch."

---

## §1 — Load-bearing strategic principles (7 total, all tagged)

| ID | Principle | Tag | Notes |
|---|---|---|---|
| P1 | Authority by construction over discipline by convention | **HIGH** | Path C calls this the DOMINANT design move per §5 hierarchy |
| P2 | Honest platform scoping (ship the strongest rule each platform actually supports) | MEDIUM | |
| P3 | Single source of truth with regenerable mirrors | **HIGH** | Intersects with user's D-4 (no mirrors by default) and D-11 (PM-chat-injection); user's D-4 sharpens to "no mirrors, only PM-injection unless rigorously defended + drift mitigated" |
| P4 | Actor-and-gate orchestration (every rule names WHO does the work and WHO approves) | **HIGH** | |
| P5 | Empirical anchoring (every rule cites its incident) | MEDIUM | Path C calls this the META-principle per §5 hierarchy; user's MEDIUM tag means land but not top priority |
| P6 | Fix-now-default with structural friction against deferral | **HIGH** | Intersects with user's D-3 strategic rules (backlog as tech debt; backlog only if blocked/huge); PACK vs PROJECT distinction adds nuance Path C didn't capture |
| P7 | Boundary separation by structural firewall (seven instances) | MEDIUM | |

**Summary:** 4 HIGH / 3 MEDIUM / 0 DROP.

**HIGH-tagged principles (V2 architect's primary focus):** P1, P3, P4, P6.

---

## §3 — Strategic principles researcher missed (6 total, all tagged)

| ID | Principle | Tag | Notes |
|---|---|---|---|
| P-missed-1 | Observation/recording separation from solution/decision | **HIGH** | User emphasis: "very high" — does NOT prohibit coders reading architect docs; constrains role boundaries at the moment of CREATING WORK PRODUCT, not what inputs an actor can read |
| P-missed-2 | Bidirectionality and round-trip safety | **HIGH** | Note: bidirectionality must be deterministic even when fields are derived or have multiple sources |
| P-missed-3 | Composition over special cases | **HIGH** | Note: nudges toward better discoverability |
| P-missed-4 | Mode-agnostic CORE operational logic (rewritten) | **HIGH** | **Rewritten statement:** Core CRUD/lifecycle/entry-content logic shared between flat-file and tracker modes; only the resolver differs at the core layer. Tracker mode MAY add features (hooks/workflows/automations) that flat-file mode cannot support, AS LONG AS they do not break the bidirectionality guarantee (P-missed-2). The resolver is the BASE seam, not the ONLY seam — tracker-mode-only logic is admissible in a separate layer |
| P-missed-5 | Idempotency for orchestration verbs | **HIGH** | |
| P-missed-6 | Symbols not line numbers (durable cross-references) | MEDIUM | |

**Summary:** 5 HIGH / 1 MEDIUM / 0 DROP.

**HIGH-tagged researcher-missed principles:** P-missed-1, P-missed-2, P-missed-3, P-missed-4 (rewritten), P-missed-5.

**Notable signal:** User valued researcher-missed principles MORE than Path C's own (5 of 6 HIGH vs 4 of 7 in §1) — suggests Path C's §3 surfaces the principles most aligned with user's actual priorities for V2.

## §4 — Conflicts re-judged (pending)

To be filled during walk-through.

## §5 — Hierarchy (pending)

To be filled during walk-through.

## §6 — Meta-notes (pending)

To be filled during walk-through.
