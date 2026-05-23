# ARCHITECTURE-CLEANUP-BATCH-19C — V2 (integrated)

**Author:** pack-architect (V2; integrates V1 + PRINCIPLE-CHECK + salvageability + leak audit + leak-sweep strategy + guardrails contract).
**Date:** 2026-05-21
**Branch:** v11-dev (HEAD `7b1be5fc33315b24b2570d740b0857c4c5fa2d02`; post-BD-179 Phase 1; pre-19c-restart).
**Ship target:** v11.0 (unlaunched).
**Supersedes:** V1 at `maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19C.md` and its PRINCIPLE-CHECK sidecar at `ARCHITECTURE-CLEANUP-BATCH-19C-PRINCIPLE-CHECK.md`. V1 is retained as a historical input; V2 is the implementation-ready design from this point forward.
**Status:** V2 finalized for planner consumption. No further architect pass required before planner.

---

## §A — Preamble: what changed from V1, decisions applied

### A.1 — V1 inputs preserved verbatim

The following V1 outputs are CARRIED FORWARD into V2 without re-derivation:

- The 17-item OT memory inventory (V1 §A.3).
- The categorization vocabulary (V1 §A.4: ALREADY-COVERED / GENERALIZABLE-PROMOTE / OT-SPECIFIC-OOS / GAP-FILL / NEEDS-RESEARCH).
- The per-item disposition table (V1 §B).
- The §G research scope and the 9 G-item verdicts (per `RESEARCH-19C-G-ITEMS-VERIFICATIONS.md` + `ARCHITECTURE-PRE-19C-SALVAGEABILITY.md` §5 confirmation: ALL 9 STILL HOLD).
- The §E out-of-scope items (V1 §E.1 through E.6).
- The §J Batch-19b parity check axes (V1 §J.1 through J.6) — re-verified clean against post-BD-175 boundary.
- The §K risk surface enumeration (V1 §K.1 through K.6) — augmented in V2 §K with three new risks introduced by V2 integration.

### A.2 — Inputs accumulated AFTER V1 (driving V2 revisions)

V2 integrates the following inputs that did not exist when V1 was authored on 2026-05-17:

1. **`ARCHITECTURE-CLEANUP-BATCH-19C-PRINCIPLE-CHECK.md`** (PRINCIPLE-CHECK sidecar) — introduced D-11 (PM-chat omniscience obligation) and surfaced the cascade question (~12 §C placements need reframing under Alt-1).
2. **BD-175..BD-184 family closure** (2026-05-18..2026-05-21) — formalized the pack/project boundary discipline. Authorities now in force: `pack-ops/BOUNDARY-DEFINITION.md` (two-axis C1-C6 matrix), `pack-ops/PACK-AGENTS.md` (pack-internal SSOT), `pack-ops/PACK-CHAT.md` (Pack Chat operating rules), `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` (reviewer methodology), pack-root `CLAUDE.md` `## Pack memory` P-missed-7 + boundary-investigation skill bullets, project-template trinity `## Project memory` "Project SSOT-first" bullet (CLAUDE.md L376-392 + AGENTS / GEMINI parallel), the `.claude/skills/boundary-investigation/SKILL.md` skill (loaded by all pack agents).
3. **`AUDIT-PRE-19C-BOUNDARY-LEAKS.md`** — 36 confirmed boundary leaks at HEAD across the client-install surface; 32 v11-dev-only including 1 introduced BY BD-175 (the boundary-investigation skill's own `AUDIT-USER-CURATION.md` cite at line 124).
4. **`ARCHITECTURE-PRE-19C-SALVAGEABILITY.md`** — per-element V1 verdict matrix; all 12 §C and 5 §D elements salvageable with minor revision (NO discards, NO major revisions); 9 boundary risks B1-B9.
5. **`ARCHITECTURE-V11-LEAK-SWEEP-STRATEGY.md`** — 6 fix-shape categories A-F; recommended absorbing sweep into Batch 19c (Option b); prevention-gap analysis identifying the BD-175 guardrails' insufficiency.
6. **`ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md`** — implementation-ready contracts for Guardrails 1-4 (Check 43, per-line fence, scope expansion, PREFLIGHT extension).
7. **`AUDIT-USER-CURATION.md`** — 10 user overrides on BD-175 architect output; Override 9 is load-bearing for V2 ("different audience = different wording; NO cross-trinity drift gate" — applies to BD-182 cross-CLI references and any V2 trinity edit).
8. **`ARCHITECTURE-BD-182.md`** §4.1 — per-CLI canonical reference table (Claude vs Codex vs Gemini config / settings / hook / invocation paths) — applies to any V2 trinity edit that touches cross-CLI references.
9. **2026-05-23 — User-articulated decision presentation protocol (5-point meta-rule).** Lands as new §C.13 PM-CHAT.md bullet in commit H.2 per §B.1 + §I + §C.0 integration. Generalises §C.10 and §C.11 as sibling instances.

### A.3 — User decisions applied (NOT re-decided in V2)

The user has made the following decisions before V2 was spawned. These are CONSTRAINTS, not options:

| # | Decision | User-set value | Effect on V2 |
|---|---|---|---|
| Sequencing | leak sweep absorbed into Batch 19c | **Option (b)** — strategy doc §2.4 | V2 §H adds H.9 (Cat A+B), H.10 (Cat D+E+F), H.11 (Cat C-c) AFTER V1's H.1-H.8 and BEFORE end-of-batch reviewer. |
| Category C disposition | rewrite pm-chat self-prompt variants | **(C-c)** — strategy doc §1.3 | H.11 rewrites the three pm-chat variants (manual-fallback / generate-setup / generate-agent-kickoff) to use client-side equivalents (`docs/pack/INSTALL-PROCEDURES.md` Procedure 7 + project-trinity content + project-side methodology), not to ship the pre-install templates to clients. |
| D-11 | PM-chat omniscience principle | **Alt-1** — principle-check §6 | V2 §D.6 drafts the principle text for METHODOLOGY.md Part 1 "Tool Roles" as a NEW sub-section "PM chat omniscience obligation"; ~12 §C placements cascade-reframed per the principle (most reframed to PM-CHAT.md-authoritative + PM-chat-injection-into-prompts delivery; trinity STRENGTHEN at §C.6 retains trinity placement under documented defense-in-depth exception). H.16 lands the principle. |
| D-10 | per-BD reviewer | **per-BD INLINE reviewer is the DEFAULT for trinity-touching and boundary-sensitive commits** per post-BD-175 pattern; **END-OF-BATCH reviewer also runs** | V2 §H attaches per-commit inline reviewer to H.4 (trinity STRENGTHEN), H.5 (METHODOLOGY substantive), H.9 (per-entry sweep), H.10 (mixed boundary edits incl. boundary-investigation skill), H.11 (pm-chat variant rewrites), H.13 (per-line fence + 7 fenced files), H.14 (Check 43 new check), H.15 (PREFLIGHT extension — pack-root trinity edit; user-directed symmetric coverage with H.4 per Decision 4 (b) 2026-05-22), H.16 (METHODOLOGY.md principle landing). Non-boundary-sensitive commits (H.1, H.2, H.3, H.6, H.7, H.12) carry END-OF-BATCH-only review per V1's existing call. H.17 is the end-of-batch reviewer pass over the entire batch diff. |
| D-1 | Claude-only Sub-agent behavior sub-section in project-template CLAUDE.md | **fresh decision — see §D.7** | V2 §D.7 RE-CONFIRMS V1's recommendation NO with strengthened post-BD-175 rationale (Check 18 H2 within-trinity parity collision + project-side SSOT-first wording restrictiveness vs pack-side); the rule lands as a single informational paragraph in METHODOLOGY.md `## Part 1 — Tool Roles` "Claude Code CLI (agents)" sub-section instead (per V1 §F D-1 Alt-3 reframed; see §D.7 for full reasoning). No new trinity H3. |

### A.4 — V2 structural deltas vs V1

| Axis | V1 | V2 |
|---|---|---|
| §C placements | 12 | 12 (same set; 4 reframed under D-11 Alt-1; 5 word-level cleanups applied; 3 19c-plan-text leaks fixed) |
| §D decisions | 5 (D.1-D.5) | 7 (D.1-D.5 from V1 + new D.6 PM-chat omniscience principle + new D.7 D-1 disposition rationale) |
| §F open questions | 11 (D-1..D-11, with D-11 added by principle-check) | 0 (all closed; V2 §F lists resolutions, not open questions) |
| §G research | 9 items | 9 verdicts re-confirmed (carried as §G summary); no new research |
| §H commits | 8 (H.0 setup + H.1-H.7 implementation + H.8 end-of-batch) | 17 (H.0 setup; H.1-H.7 revised from V1; H.9-H.16 new for leak sweep + guardrails + D-11 principle; H.17 end-of-batch reviewer) |
| RC9 manifest regen | trigger set was {project-template/, scripts/} | trigger set is {project-template/, scripts/, pack-ops/, supporting-docs/} per BD-176 expansion; attached to every applicable commit |
| Cross-CLI references | trinity edits assumed parity | trinity edits respect BD-182 §4.1 canonical table; cross-CLI references diverge per CLI per Override 9 |
| Insertion-anchor freshness | line numbers from 2026-05-17 | re-verify against HEAD `7b1be5fc` at commit time; coder uses fresh reads, not V1's line numbers |

### A.5 — V2 reading order recommendation

For a planner consuming V2 to produce the per-commit task list, the recommended reading order is:

1. §A (this section) — V2 context + decisions applied
2. §H — commit sequencing (the planner's primary input)
3. §C — placement-by-placement BEFORE/AFTER text with reframings applied
4. §D — architecture decisions (esp. §D.6 PM-chat omniscience principle text and §D.7 D-1 rationale)
5. §I — summary table (all placements with V2 disposition)
6. §K — risk surface (V2 augmentations from leak-sweep + guardrails absorption)
7. §E (V1 §E carried over) — out-of-scope confirmation
8. §G, §J — research / parity-check confirmations (carried; no action needed)
9. §F — closed-question resolutions (read-only)

For a reviewer consuming V2 at end-of-batch (H.17), the recommended reading order is reversed: start at §I summary table to inventory expected changes, then drill into §C / §D / §H for any anomalous finding.

---

## §B — Per-item disposition table (V2 verdicts)

V2 carries V1's §B inventory verbatim (the 17 OT items + architect-derived rows). Each row is annotated with V2 verdict per the matrix below.

V2 verdict vocabulary:
- **UNCHANGED** — V1 disposition stands; placement, text, and target identical to V1.
- **REVISED-WORDING** — V1 placement target unchanged; text body revised for boundary-discipline (drops cross-side citations per salvageability B1/B2/B3/B9) or for cascade reframing (D-11 Alt-1).
- **REVISED-PLACEMENT** — V1 placement target changes per D-11 cascade (trinity STRENGTHEN → PM-CHAT.md authoritative + PM-chat-injection delivery, OR vice versa).
- **NEW** — Item added by V2 (not present in V1); typically the D-11 cascade reframings, the leak-sweep categories, or the guardrails.

### B.1 — OT-item disposition (V1 17 items + architect-derived rows)

| OT-ID | Title (short) | V1 disposition | V2 verdict | V2 target (if revised) |
|---|---|---|---|---|
| OT-T-1 | Always reviewer after coder | PM-CHAT.md NEW bullet + METHODOLOGY.md NEW callout | **UNCHANGED** | (same) |
| OT-T-2 | Architect trigger surface-even-mechanical | METHODOLOGY.md STRENGTHEN | **UNCHANGED** | (same) |
| OT-T-3 | BACKLOG between phases proactive | METHODOLOGY.md STRENGTHEN (CONDITIONAL per V1 D-3) | **UNCHANGED** — LAND per V1 D-3 = Alt-1 (architect recommendation; CONDITIONAL flag closed) | METHODOLOGY.md Part 7 Procedure 1 step 2 |
| OT-T-4 | Closeout approval before writing docs | PM-CHAT.md NEW bullet + METHODOLOGY.md cross-ref | **UNCHANGED** (insertion anchor re-verified against HEAD post-BD-178 — V1 anchor still resolves) | (same) |
| OT-T-5 | No chained `git add` after edits | PM-CHAT.md STRENGTHEN to "Source file edits" bullet | **UNCHANGED** | (same) |
| OT-T-6 (PM-CHAT.md half) | PM chat never edits source files | PM-CHAT.md NEW bullet | **UNCHANGED** | (same) |
| OT-T-6 (trinity half) | Trinity STRENGTHEN — destructive-ops list extension | Trinity STRENGTHEN | **REVISED-WORDING** — apply to BD-178-canonicalized baseline (NOT V1's pre-BD-178 recorded BEFORE text); per Override 9, the destructive-ops bullet does not contain CLI-specific paths so byte-identical application across trinity is correct (Override 9 applies to cross-CLI tool references like `.claude/settings.json`, NOT to platform-neutral content) | Trinity `## Project memory` "No destructive operations" bullet |
| OT-T-7 | Re-read per-agent prompt files + REPORT FILE check | PM-CHAT.md NEW bullet | **UNCHANGED** | (same) |
| OT-UT-1 | Agent Teams stage lifecycle (Claude-only) | CONDITIONAL per V1 D-1 (default NO) | **REVISED-PLACEMENT** — NOT in trinity; land as informational paragraph in METHODOLOGY.md `## Part 1 — Tool Roles` § "Claude Code CLI (agents)" sub-section (per V2 §D.7 disposition; V1 D-1 Alt-3 reframed) | METHODOLOGY.md Part 1 |
| OT-UT-2 | Pack repo is read-only from this project | PM-CHAT.md NEW bullet | **REVISED-WORDING** — drop the "supporting-docs/" example phrase from the bullet body (salvageability B2: project-side file naming a pack-repo path as an example is boundary-bias) | PM-CHAT.md `## Behavioral rules` |
| OT-UT-3 | Mid-pipeline working-tree intentional | PM-CHAT.md NEW bullet | **UNCHANGED** | (same) |
| OT-UT-4 | Only OPEN TDs in scope for v11 conversion | OOS | **UNCHANGED** (OOS) | (none) |
| OT-UT-5 | Phase 58b deferred until v11 lands | OOS | **UNCHANGED** (OOS) | (none) |
| OT-UT-6 | Architect output → user reads → next step waits | PM-CHAT.md NEW bullet + METHODOLOGY.md STRENGTHEN | **REVISED-WORDING** — drop the "project-side analog of the pack-side 'Planner output → user review → coder spawn' rule" cross-side citation from PM-CHAT.md bullet text (salvageability B1); assert the rule on its own merits + ADD one-line sibling annotation cross-referencing §C.13 (meta-rule) per user direction 2026-05-23 | PM-CHAT.md `## Behavioral rules` + METHODOLOGY.md Workflow 4 step 4 |
| OT-UT-7 | Feature prioritization deferred until after v11 | OOS | **UNCHANGED** (OOS) | (none) |
| OT-UT-8 (meta) | Open questions surface to user | PM-CHAT.md NEW bullet | **REVISED-WORDING** — ADD one-line sibling annotation cross-referencing §C.13 (meta-rule) per user direction 2026-05-23 | (same) |
| OT-UT-8 (specifics) | (OT-specific open questions) | OOS | **UNCHANGED** (OOS) | (none) |
| OT-UT-9 | Re-read prompts + verify REPORT FILE present | subsumed by OT-T-7 | **UNCHANGED** | (see OT-T-7) |
| OT-UT-10 | /tmp reports are ephemeral | METHODOLOGY.md NEW paragraph | **REVISED-WORDING** — replace "paste into Pack Chat for upstream debugging" with "for upstream debugging via PACK-FEEDBACK.md" (audit §3.1.12 + salvageability cross-side cite cleanup) | METHODOLOGY.md Part 9 |
| OT PM gap A | When to call planner mid-phase | METHODOLOGY.md NEW sub-section (CONDITIONAL per V1 D-6) | **UNCHANGED** — LAND per V1 D-6 = Alt-1 (architect recommendation; 3 triggers; CONDITIONAL flag closed) | METHODOLOGY.md Workflow 4 |
| OT PM gap B | Closeout commit-gating elevation | covered by §C.4 + §D.5 | **UNCHANGED** | (see §C.4 + §D.5) |
| OT PM gap C | No single "when to end fix cycle" clause | METHODOLOGY.md NEW callout (CONDITIONAL per V1 D-5) | **UNCHANGED** — LAND per V1 D-5 = Alt-1 (architect recommendation; CONDITIONAL flag closed) | METHODOLOGY.md Workflow 4 |
| Arch derived 1 | Rule placement: trinity vs PM-CHAT.md vs METHODOLOGY.md | METHODOLOGY.md NEW sub-section (CONDITIONAL per V1 D-4) | **REVISED-PLACEMENT** — LAND in METHODOLOGY.md Part 9 as SUBSIDIARY of the new D-11 PM-chat omniscience principle (per principle-check §6 + V2 §D.6 cascade); the placement rule becomes "where rules LIVE follows the omniscience principle, with two documented exceptions" | METHODOLOGY.md Part 9 |
| Arch derived 2 | Per-project Claude memory cache convention | PM-CHAT.md NEW paragraph (CONDITIONAL per V1 D-1) | **REVISED-WORDING** — LAND per V1 D-1 = Alt-1 reframed in §D.7; drop the "Tier 1.5 design as the pack repo (per pack memory pattern)" cross-side citation (audit §3.2.1 confirmed leak); describe the per-project Claude memory cache convention on its own merits | PM-CHAT.md "Tool-specific: Claude Code CLI" section |
| **NEW for V2** | PM-chat omniscience obligation principle | (did not exist in V1) | **NEW** (per D-11 Alt-1) | METHODOLOGY.md `## Part 1 — Tool Roles` NEW sub-section "PM chat omniscience obligation" |
| **NEW for V2** | Decision presentation protocol (5-point user-articulated meta-rule) | (did not exist in V1) | **NEW** (per user direction 2026-05-23) | `project-template/docs/pack/PM-CHAT.md` `## Behavioral rules` NEW bullet (§C.13) |

### B.2 — Leak-sweep additions (NEW for V2 — Option b absorption)

Per the leak-sweep strategy doc §1, six fix-shape categories absorb into Batch 19c. The 36 confirmed leaks distribute across these as commits H.9-H.11 (per V2 §H sequencing).

| Category | Leaks | Files | Fix shape | V2 commit |
|---|---|---|---|---|
| A — Drop architect-doc cite (per-entry skeletons) | 25 | 5 per-entry skeleton files under `project-template/docs/project/{backlog,implementation-plan,changelog}/` | Delete the cross-reference clause; preserve the rule wording | H.9 |
| B — Replace architect-doc cite with project-side equivalent (per-entry skeletons) | 5 | 2 per-entry skeleton files (`changelog/_intro.md`, `changelog/_format.md`) | Substitute the architect-doc cite with the sibling project-side `_rules.md` cite or with descriptive prose | H.9 |
| C — Restructure pm-chat variants (user direction: C-c) | 3 | `project-template/docs/pack/prompts/pm-chat.md` (3 variants: manual-fallback, generate-setup, generate-agent-kickoff) | Rewrite each variant to use client-installed equivalents (`docs/pack/INSTALL-PROCEDURES.md` Procedure 7 + project trinity content + project-side methodology) instead of the pre-install templates in `supporting-docs/` | H.11 |
| D — Drop cite entirely (detect.sh + PM-CHAT.md line 410) | 3 | `scripts/lib/detect.sh:335`, `scripts/lib/detect.sh:678`, `project-template/docs/pack/PM-CHAT.md:410` | Delete the cite; bare prose stands without the cross-reference | H.10 |
| E — pm-startup cluster (sibling sweep) | 4 | 3 SKILL.md files + 1 TOML command file (canonical at `project-template/skills/pm-startup/SKILL.md` + `.claude/`, `.codex/`, `.gemini/` siblings) | Single mechanical sweep — drop the `ARCHITECTURE-V3.md §28.1.5` cite tail | H.10 |
| F — BD-175 self-leak (boundary-investigation skill) | 1 | `project-template/skills/boundary-investigation/SKILL.md:124` | Replace `AUDIT-USER-CURATION.md Override 1` cite with descriptive prose ("STAYS at pack root per pack-repo audit finding; not installed at client") | H.10 |
| **Total** | **41** (audit's 36-leak count vs strategy's 41 cite-count: see strategy §1.7 note — same set of files, by-fix-shape unpack of adjacent cites) | **~13 distinct files** | | H.9, H.10, H.11 |

### B.3 — Guardrail additions (NEW for V2)

Per the guardrails contract doc, four new guardrails close the prevention gap diagnosed in the leak-sweep strategy §3.

| # | Guardrail | Implementation surface | V2 commit |
|---|---|---|---|
| G3 | `_PROJECT_SIDE_ROOTS` expansion to full client-installed surface | `scripts/validate-pack.py` (new `_iter_client_installed_files()` helper) + fixture-test extension at `scripts/tests/test-validate-pack-checks-36-37-38.sh` Group 7 | H.12 |
| G2 | Per-line exemption fence (Check 37 modification) | `scripts/validate-pack.py` (new `_has_per_line_fence()` + `_build_fence_skip_lineset()`) + fence markers in 7 files (boundary-investigation/SKILL.md, prompts/coder.md, prompts/reviewer.md, project-template trinity ×3, plus PM-CHAT.md per contract §2.3) + fixture-test extension Group 6 | H.13 |
| G1 | Check 43 (project-side bare cross-reference scanner — class-test) | `scripts/validate-pack.py` (new `check_project_side_bare_internal_refs` + `_CHECK_43_ALLOWLIST`) + new fixture-test file `scripts/tests/test-validate-pack-check-43.sh` + 13 fixture files under `scripts/tests/fixtures/project-side-refs/` + `.github/workflows/validate-pack.yml` test wiring | H.14 |
| G4 | PREFLIGHT extension (pack-coder pre-commit verification) | `pack-ops/PACK-AGENTS.md` PREFLIGHT spec edit + pack-root trinity (CLAUDE.md / AGENTS.md / GEMINI.md) `## Pack memory` PREFLIGHT bullet edit + `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` dimension (d) extension + Pack Chat applies memory-cache update | H.15 |

### B.4 — Summary count

| Source | V1 count | V2 count |
|---|---|---|
| OT-item dispositions | 17 items + 5 architect-derived rows = 22 rows in V1 §I | 23 rows in V2 §B.1 (1 OT-UT-1 reframed in place; 1 new D-11 principle row; 1 new §C.13 decision protocol row per user direction 2026-05-23) |
| Leak sweep | (not in V1) | 36 leaks across 6 categories |
| Guardrails | (not in V1) | 4 new guardrails |
| **V2 total scope** | 22 rows of OT cleanup | 23 + 6 sweep categories + 4 guardrails = 33 distinct units of work |


---

## §C — Placement decisions (V2; BEFORE/AFTER text with D-11 cascade applied)

This section produces the final concrete edit text for every GENERALIZABLE-PROMOTE and GAP-FILL item, with three V2-specific layers applied on top of V1's text:

1. **Word-level cleanups per salvageability** — drop cross-side citations identified in B1/B2/B3/B9; respect Override 9 cross-CLI canonical table per BD-182 §4.1.
2. **D-11 cascade reframing** — for each placement, identify whether the rule moves from "trinity STRENGTHEN + PM-CHAT.md mirrored content" to "PM-CHAT.md authoritative + PM-chat injects on demand," or stays at the original placement under a documented exception (defense-in-depth OR cross-CLI parity ergonomics, per §D.6).
3. **Insertion-anchor freshness** — coder verifies V1's anchor still resolves at HEAD before applying; if a BD-178 / BD-180 / BD-182 / BD-179 commit shifted the anchor, the coder uses the BD-178-canonicalized form.

### C.0 — D-11 cascade summary (which §C placements reframe)

Per the principle-check architect recommendation (§6, cited in V2 §D.6 below), most §C placements REFRAME under D-11 Alt-1: the rule lives authoritatively in PM-CHAT.md (the project-side PM-chat orchestration SSOT), and the PM chat INJECTS the relevant subset into agent prompts on demand — rather than mirroring the rule across multiple project-side surfaces.

| §C placement | V1 placement | V2 placement (after D-11 cascade) | Cascade verdict | Why |
|---|---|---|---|---|
| §C.1 (OT-T-1 always-reviewer-after-coder) | PM-CHAT.md NEW bullet + METHODOLOGY.md NEW callout | PM-CHAT.md NEW bullet + METHODOLOGY.md NEW callout | **NO REFRAME** | Both surfaces serve different audiences (PM-CHAT.md is PM-chat startup; METHODOLOGY.md Workflow 2 is the procedural reference read by developers running the cycle). Not a duplicate-with-divergence pattern; an audience-specific pair. Stays as V1. |
| §C.2 (OT-T-2 architect-trigger surface-even-mechanical) | METHODOLOGY.md STRENGTHEN | METHODOLOGY.md STRENGTHEN | **NO REFRAME** | Single-surface placement; no cascade. |
| §C.3 (OT-T-3 BACKLOG-between-phases proactive) | METHODOLOGY.md STRENGTHEN | METHODOLOGY.md STRENGTHEN | **NO REFRAME** | Single-surface placement; no cascade. |
| §C.4 (OT-T-4 closeout-sequence) | PM-CHAT.md NEW bullet | PM-CHAT.md NEW bullet (authoritative) | **NO REFRAME** | Already PM-CHAT.md-only. The METHODOLOGY.md Part 7 Procedure 4 cross-ref in §D.5 is a discoverability pointer, not a duplicate-content surface. |
| §C.5 (OT-T-5 no-chained-git-add) | PM-CHAT.md STRENGTHEN to "Source file edits" bullet | PM-CHAT.md STRENGTHEN to "Source file edits" bullet | **NO REFRAME** | Single-surface placement; no cascade. |
| §C.6 (OT-T-6 PM-chat-never-edits-source) | PM-CHAT.md NEW bullet + trinity STRENGTHEN ("destructive-ops" list extends with `git checkout --`) | PM-CHAT.md NEW bullet + trinity STRENGTHEN (UNCHANGED placement) | **REFRAME-EXCEPTION** — trinity STRENGTHEN stays as DEFENSE-IN-DEPTH documented exception per §D.6 | The trinity STRENGTHEN extends an EXISTING agent-affecting bullet (destructive-ops list); ALL agents (not just PM chat) read this. Under D-11, defense-in-depth applies when prompt-corruption resilience matters and the rule's audience extends beyond the PM chat. `git checkout --` on coder-touched files is a project-team rule, not a PM-chat-orchestration rule — trinity placement is correct under the exception. |
| §C.7 (OT-T-7 re-read per-agent prompt files) | PM-CHAT.md NEW bullet | PM-CHAT.md NEW bullet (authoritative) + PM chat INJECTS into per-agent prompt construction at prompt-generation time | **REFRAME-DELIVERY** | Rule lives at PM-CHAT.md SSOT. PM chat injects "re-read your-own-agent-prompt-file" into agent prompts as part of construction — NOT duplicated into agent definition files (which would force every project agent to repeat the rule). Pure delivery-mechanism reframe; placement target unchanged. |
| §C.8 (OT-UT-2 pack-repo-is-read-only) | PM-CHAT.md NEW bullet | PM-CHAT.md NEW bullet (authoritative) | **NO REFRAME** | Single-surface placement; no cascade. |
| §C.9 (OT-UT-3 mid-pipeline working-tree intentional) | PM-CHAT.md NEW bullet | PM-CHAT.md NEW bullet (authoritative) | **NO REFRAME** | Single-surface placement; no cascade. |
| §C.10 (OT-UT-6 architect-output → user-reads) | PM-CHAT.md NEW bullet + METHODOLOGY.md STRENGTHEN | PM-CHAT.md NEW bullet (authoritative) + METHODOLOGY.md STRENGTHEN (audience-specific pair, NOT a duplicate-with-divergence) | **NO REFRAME** | Same audience-specific-pair rationale as §C.1. |
| §C.11 (OT-UT-8 open-questions-surface) | PM-CHAT.md NEW bullet | PM-CHAT.md NEW bullet (authoritative) | **NO REFRAME** | Single-surface placement; no cascade. |
| §C.12 (OT-UT-10 /tmp reports are ephemeral) | METHODOLOGY.md NEW paragraph | METHODOLOGY.md NEW paragraph | **NO REFRAME** | Single-surface placement; no cascade. |
| §C.13 (decision presentation protocol — META) | (did not exist in V1) | PM-CHAT.md NEW bullet (authoritative) | **NO REFRAME** | Single-surface PM-chat orchestration meta-rule; new for V2 per user direction 2026-05-23. PM-CHAT.md is the authoritative SSOT per the omniscience principle's default; no trinity or METHODOLOGY.md duplication needed. |

**Cascade summary:** 1 REFRAME-EXCEPTION (§C.6 trinity STRENGTHEN documented as defense-in-depth), 1 REFRAME-DELIVERY (§C.7 PM-CHAT.md authoritative + injection delivery), 11 NO-REFRAME (now includes §C.13 decision presentation protocol). The "~12 reframings" estimate in the principle-check (§6.6) over-counted because V1 was already conservatively scoped — V1 had ALREADY been making PM-CHAT.md-only placements for most rules; the cascade primarily documents the exception (§C.6) and the delivery mechanism for §C.7. The other 10 placements were not duplicate-with-divergence patterns in V1, so no reframing applies.

The principle's value-add for V2 is therefore: (a) documenting WHY most §C placements are PM-CHAT.md-only (it follows from the principle, not from ad-hoc choices), (b) documenting the §C.6 exception with named rationale (defense-in-depth), (c) describing the §C.7 delivery mechanism (injection at prompt-construction time), and (d) the new principle text landing in METHODOLOGY.md Part 1 (commit H.16).


### C.1 — OT-T-1 (always-reviewer-after-coder) placement (V2: UNCHANGED from V1)

**Target file 1:** `project-template/docs/pack/PM-CHAT.md`
**Target section:** `## Behavioral rules`
**Insertion anchor:** After the existing "Fix cycle rules." bullet (V1 cited L201-202; coder verifies current line numbers at HEAD).
**Edit type:** NEW bullet.

**V2 text** (carried from V1 §C.1; no salvageability changes; no cascade reframe):

```
- **Always run reviewer after every coder report — no exceptions.**
  After every coder report, the next action is to generate a
  reviewer prompt. Never propose "approve to commit" directly
  after a coder report. Never say "this is small enough to skip
  review," "the coder confirmed it's correct," "the reviewer
  already approved the larger pass," or "tests pass, so it's
  fine." All of these are the conditions under which the reviewer
  is most needed — they are the conditions under which critical
  thinking stops. The cycle is coder → reviewer → user approval →
  commit. Always. The only bypass is an unprompted user
  instruction to skip the reviewer; PM chat never requests or
  suggests skipping.
```

**Target file 2:** `supporting-docs/METHODOLOGY.md`
**Target section:** Part 5 Workflow 2.
**Insertion anchor:** Immediately after the existing fenced code block at the end of Workflow 2 (V1 cited L410; coder verifies at HEAD).
**Edit type:** NEW callout block.

**V2 text** (carried from V1; no changes):

```
> **Cycle invariant — reviewer always runs.** Step 4 (reviewer)
> runs after every step-3 coder report without exception. The PM
> chat must not propose skipping the reviewer for any reason —
> "small change," "comment-only," "tests pass," "coder confirmed
> correct," or "prior reviewer already approved" are all the
> conditions under which the reviewer is most needed. The reviewer
> exists precisely to catch what "tests pass" does not:
> architecture compliance, security posture, intent alignment.
> The only bypass is an unprompted user instruction to skip;
> PM chat never suggests it.
```

**Trinity ripple:** None.

### C.2 — OT-T-2 (architect trigger surface-even-mechanical) placement (V2: UNCHANGED from V1)

**Target file:** `supporting-docs/METHODOLOGY.md`
**Target section:** Part 5 Workflow 4 → "#### Architect trigger conditions".
**Insertion anchor:** Immediately after the Trigger B paragraph (V1 cited L503; coder verifies at HEAD).
**Edit type:** NEW callout.

**V2 text** (carried from V1; no changes):

```
> **Surface mechanical-looking trigger hits explicitly.** Even
> when the trigger is technically met but the remaining issue
> looks clearly mechanical (e.g., a missing test with no
> architectural ambiguity), the PM chat must surface the
> trigger check explicitly to the user, state its assessment of
> whether a true architectural problem exists, and get explicit
> approval before proceeding with or waiving the architect pass.
> Never silently skip the check.
```

**Trinity ripple:** None.

### C.3 — OT-T-3 (BACKLOG-between-phases proactive) placement (V2: LAND per V1 D-3 = Alt-1; UNCHANGED from V1)

**Target file:** `supporting-docs/METHODOLOGY.md`
**Target section:** Part 7 Procedure 1 step 2.
**Insertion anchor:** Append to the end of step 2 (V1 cited L1083; coder verifies at HEAD).
**Edit type:** STRENGTHEN.

**V2 text** (carried from V1; CONDITIONAL flag closed per user decision applied):

```
   The PM chat reports newly-unblocked items to the user
   proactively at every phase gate — the user should not need
   to ask. ("TD-NNN is now unblocked by Phase N completion.")
```

### C.4 — OT-T-4 (closeout-sequence: present-before-write) placement (V2: UNCHANGED from V1; anchor verified post-BD-178)

**Target file:** `project-template/docs/pack/PM-CHAT.md`
**Target section:** `## Behavioral rules`
**Insertion anchor:** After the existing "Source file edits." bullet (V1 cited L203-205; salvageability §C.4 confirmed anchor still resolves at HEAD post-BD-178; coder verifies at commit time).
**Edit type:** NEW bullet.

**V2 text** (carried from V1; no changes):

```
- **Closeout sequence — present, wait, then write.** After every
  reviewer pass that ends in a READY TO COMMIT verdict, the
  sequence is mandatory and ordered: (1) check architect trigger
  conditions per Workflow 4; (2) present proposed BACKLOG entry,
  CHANGELOG entry, and STATUS changes as TEXT in chat — do NOT
  write any files yet; (3) wait for explicit user approval
  ("approved," "looks good," or equivalent affirmative); (4) only
  then write the files; (5) show the commit message and wait for
  approval before committing. Skipping step 2 or step 3 (writing
  files before the user has seen and approved the content) causes
  unauthorized state changes and requires manual revert.
```

**Trinity ripple:** None.

### C.5 — OT-T-5 (no-chained-git-add) placement (V2: UNCHANGED from V1)

**Target file:** `project-template/docs/pack/PM-CHAT.md`
**Target section:** `## Behavioral rules`
**Insertion anchor:** STRENGTHEN the existing "Source file edits" bullet.
**Edit type:** STRENGTHEN existing bullet.

**V2 BEFORE text** (current HEAD `7b1be5fc` — V1's recorded BEFORE form verified unchanged):

```
- **Source file edits.** You may write to BACKLOG.md, STATUS.md, and deferral
  comments in source files — but only after explicit user approval. Never write
  to source code files for any other reason.
```

**V2 AFTER text** (carried from V1; no changes):

```
- **Source file edits.** You may write to BACKLOG.md, STATUS.md, and deferral
  comments in source files — but only after explicit user approval. Never write
  to source code files for any other reason. Never chain `git add` into the
  same action as making an edit — always describe what was changed and pause
  for the user to review and approve before staging anything. This applies
  even to small/obvious changes (config files, scripts, one-line fixes); the
  user reviews each edit before it is staged. The words "approve to commit"
  (or equivalent affirmative) must appear AND the user must respond
  affirmatively before any state-changing git verb runs.
```

**Trinity ripple:** None at the PM-CHAT.md half. The trinity destructive-ops bullet extension lands separately in §C.6 below.

### C.6 — OT-T-6 (PM-chat-never-edits-source) placement (V2: REVISED-WORDING for trinity half — apply to BD-178 baseline; defense-in-depth exception documented)

**Target file 1:** `project-template/docs/pack/PM-CHAT.md`
**Target section:** `## Behavioral rules`
**Insertion anchor:** After the "Source file edits" bullet (post-§C.5 strengthening).
**Edit type:** NEW bullet.

**V2 text** (carried from V1; no changes):

```
- **PM chat never edits production source files.** PM chat must
  never directly edit any production source file — not code, not
  comments within source files (other than typed deferral
  comments, per the carve-out in METHODOLOGY.md Part 7 / Part 9),
  not variable names, not formatting. All source-file edits route
  through the coder agent — including one-line typo fixes,
  comment cleanups, and apparently-trivial changes. PM chat's
  file-editing scope is: docs/ files, scripts/, .claude/.codex/
  .gemini/ settings, memory files, and deferral comments
  (TD-TBD → TD-NNN replacement or rejected-comment removal). Any
  edit outside this scope MUST be routed through a coder agent
  with an explicit scoped prompt — no exceptions for size.
```

**Target file 2:** Trinity (`project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md`)
**Target section:** `## Project memory`
**Insertion anchor:** STRENGTHEN the existing "No destructive operations without explicit approval" bullet.
**Edit type:** STRENGTHEN existing bullet (extend named list of destructive operations).

**V2 baseline note (REVISED-WORDING per salvageability B5):** The current HEAD `7b1be5fc` form of the "No destructive operations" bullet is the BD-178-canonicalized form. V1's BEFORE text (V1 lines 874-881) reflects pre-BD-178 state. The coder MUST read the current HEAD form of each trinity file at commit time and apply the STRENGTHEN to the actual current text, NOT to V1's pre-BD-178 form.

**V2 BEFORE-text contract (each trinity file at HEAD as of commit time — coder verifies form):** The current bullet states the rule about destructive operations with a named list. The named list includes `git rm`, `rm -rf`, file deletion, overwrite, `git reset --hard`. (Exact wording may differ slightly across trinity per BD-178 alignment; coder reads each file and applies the STRENGTHEN consistently.)

**V2 AFTER-text contract** (per file; same content across all three trinity files per project trinity rule; cross-CLI canonical references — Override 9 — are not applicable here because `git checkout --` is a platform-neutral git verb, not a CLI-specific path):

```
- **No destructive operations without explicit approval.** Before
  any `git rm`, `rm -rf`, file deletion, overwrite, `git reset
  --hard`, or `git checkout -- <path>` on a file with uncommitted
  agent work, state exactly what will be destroyed and wait for
  explicit approval — even when the overall task is approved.
  `git checkout --` is destructive because it discards
  working-tree changes irreversibly; never run it on files that
  contain coder-written changes without per-action user approval.
```

**Trinity ripple:** Apply the same wording to all three trinity files in the same commit (project trinity rule). Per BD-182 §4.1 canonical table review: this bullet has no cross-CLI-specific references (`git rm`, `rm -rf`, `git reset --hard`, `git checkout --` are all git verbs — platform-neutral); no per-CLI divergence applies. Override 9 carve-out does NOT apply to this bullet.

**D-11 cascade verdict — REFRAME-EXCEPTION:** Per V2 §D.6 "PM chat omniscience obligation" principle and its documented exceptions (V2 §D.6.3), this trinity STRENGTHEN STAYS at trinity placement under the defense-in-depth exception. Rationale: `git checkout --` is a git verb that ALL agents (not just PM chat) must respect; trinity is the rules-agents-must-respect surface; the PM chat's omniscience principle's preferred delivery (PM-chat injection) would force every project agent to receive the rule by injection — that is more brittle than having every agent read the rule from trinity at session start. Defense-in-depth via duplication is the correct trade-off when the rule is agent-affecting and the prompt-corruption risk is non-trivial. This exception is one of two documented in §D.6.3.

### C.7 — OT-T-7 (re-read per-agent prompt file every time + verify REPORT FILE header) placement (V2: UNCHANGED placement; REFRAME-DELIVERY per D-11 — PM chat injects rule into agent prompts at construction time)

**Target file:** `project-template/docs/pack/PM-CHAT.md`
**Target section:** `## Behavioral rules`
**Insertion anchor:** After the existing "Follow Prompt Authoring Principles." bullet (V1 cited L188-189).
**Edit type:** NEW bullet.

**V2 text** (carried from V1; no changes — the bullet itself is PM-chat-orchestration):

```
- **Re-read the per-agent prompt file before generating any agent
  prompt — every time, no exceptions.** Before generating any
  agent prompt (coder, reviewer, architect, planner, tester,
  auditor, docs-researcher, repo-ops, grpc-schema, or any custom
  x-* agent), re-read the full per-agent prompt file from
  `docs/pack/prompts/<agent>.md`. Do this every single time, even
  if the file seems familiar or was recently read. "I remember
  the format" is not a substitute — the pack ships prompt-file
  updates between pack versions (new variants, new constraints,
  new completion-report sections), and a PM chat operating from
  memory misses them. Before handing the generated prompt to the
  developer, VERIFY the prompt includes the REPORT FILE line
  (per `## Permission profiles` requirements) — agents that do
  not receive a REPORT FILE line return findings inline instead
  of writing the deliverable, breaking the file-based-reporting
  contract.
```

**D-11 cascade verdict — REFRAME-DELIVERY:** The rule lives at PM-CHAT.md (authoritative). The PM chat is OBLIGATED to brief agents per the omniscience principle (§D.6), and that briefing includes the report-file-line requirement injected into the agent prompt at construction time. Agent definition files (`.claude/agents/*.md`, `.codex/agents/*.toml`, `.gemini/agents/*.md`) do NOT need to repeat the "you must accept a REPORT FILE line" instruction — the PM chat ensures it appears in every agent prompt by injection. This reframe is informational: it documents the delivery mechanism without changing the placement target.

### C.8 — OT-UT-2 (pack-repo-is-read-only) placement (V2: REVISED-WORDING per salvageability B2; drop "supporting-docs/" example)

**Target file:** `project-template/docs/pack/PM-CHAT.md`
**Target section:** `## Behavioral rules`
**Insertion anchor:** After "Pack feedback loop." (V1 cited L221-227).
**Edit type:** NEW bullet.

**V2 text** (REVISED-WORDING — dropped "supporting-docs/" example from V1's "(e.g., to read METHODOLOGY.md, prompts/, supporting-docs/ as upstream source)" parenthetical; substituted client-installed equivalents):

```
- **Pack repo is read-only from this project.** If a clone of the
  AI Agent Config Pack lives on this machine for reference, the
  PM chat MUST NOT modify any file inside that pack clone from
  this project's session. Read for reference only. Pack-side
  issues (rule clarifications, prompt template gaps,
  documentation errors) are recorded in PACK-FEEDBACK.md per
  METHODOLOGY.md Part 10, delivered to the pack maintainer at
  workflow boundaries — never patched into the upstream pack from
  within a project. This rule applies to agent sessions spawned
  from this project as well: scope all agent edits to this
  project's working tree.
```

**Note on the wording change vs V1:** V1's text named "METHODOLOGY.md, prompts/, supporting-docs/" as examples of what one might read from an upstream pack clone. The phrase "supporting-docs/" is a pack-repo path; per `boundary-investigation` skill Step 4 deny-list, including pack-repo path prefixes as examples in project-side prose is borderline. V2 drops the parenthetical example list entirely — the rule reads cleaner without naming specific files. Also: V1's text said "delivered to Pack Chat at workflow boundaries"; V2 substitutes "delivered to the pack maintainer at workflow boundaries" (per the audit §3.1.8 disposition note that "Pack Chat" as a literal audience cite is meaningless at a client install). The PACK-FEEDBACK.md product-feature cross-ref is retained because it points to a client-installed file with a documented cross-boundary product contract.


### C.9 — OT-UT-3 (mid-pipeline working-tree intentional) placement (V2: UNCHANGED from V1)

**Target file:** `project-template/docs/pack/PM-CHAT.md`
**Target section:** `## Behavioral rules`
**Insertion anchor:** After "Closeout sequence — present, wait, then write." (post-§C.4 insertion).
**Edit type:** NEW bullet.

**V2 text** (carried from V1; no changes):

```
- **Mid-pipeline working-tree state is intentional — no auto-
  commit at checkpoints.** When a multi-agent pipeline is in
  flight (researcher → architect → planner → coder → reviewer, or
  any multi-pass coder/reviewer sequence), the PM chat does NOT
  auto-commit at intermediate checkpoints — even when tests are
  green and the moment "feels like" a natural commit point.
  Intermediate working-tree state may be load-bearing for the
  next pass (e.g., the planner verifies the architect's
  proposed changes against the working tree; the next coder pass
  may extend the prior coder's working changes). Wait for explicit
  user direction ("commit and push," "stage and commit," or
  equivalent) before any state-changing git verb. Single-commit
  jobs proceed normally; multi-pass jobs wait.
```

### C.10 — OT-UT-6 (architect-output → user-reads → next-step-waits) placement (V2: REVISED-WORDING per salvageability B1; drop pack-side cross-side citation)

**Target file 1:** `project-template/docs/pack/PM-CHAT.md`
**Target section:** `## Behavioral rules`
**Insertion anchor:** After "Re-read the per-agent prompt file ..." (post-§C.7 insertion).
**Edit type:** NEW bullet.

**V2 text** (REVISED-WORDING — V1's "This is the project-side analog of the pack-side 'Planner output → user review → coder spawn' rule applied one step earlier in the pipeline" was a cross-side citation. V2 drops this clause; the rule stands on its own merits):

```
- **Architect output → user reads → next step waits.** When the
  architect agent's report lands (mid-phase architect pass per
  Workflow 4, or kickoff-time architect pass producing
  ARCHITECTURE.md content), the PM chat surfaces the report to
  the user and WAITS for the user to read it before suggesting
  any follow-on work. Do not auto-stage proposed doc changes; do
  not auto-spawn the next planner / coder pass; do not propose
  "ready to commit" until the user has signaled they have read
  the architect's output. The architect-to-next-step gate is the
  user's last cheap window to redirect before downstream work
  consumes hours of agent time and chat context.
  This is a specific application of the decision presentation protocol
  (see "Decision presentation protocol" bullet above) to the architect-
  output decision class.
```

**Target file 2:** `supporting-docs/METHODOLOGY.md`
**Target section:** Part 5 Workflow 4 step 4.
**Insertion anchor:** STRENGTHEN existing step 4 text (V1 cited L522-523).
**Edit type:** STRENGTHEN.

**V2 BEFORE text** (current HEAD; carried verbatim from V1):

```
4. **Present proposed doc changes** — show the user exactly what the architect proposes
   to change. Get explicit approval for each change before applying it.
```

**V2 AFTER text** (carried from V1; no changes — V1's METHODOLOGY.md text did not contain the cross-side citation):

```
4. **Present proposed doc changes and wait for the user to read.**
   Show the user exactly what the architect proposes to change.
   The PM chat WAITS for the user to read the architect's full
   report before suggesting any follow-on step — do not auto-
   advance to the next step, do not auto-stage changes, do not
   propose "ready to commit" until the user has signaled they
   have read the report. Get explicit approval for each change
   before applying it.
```

### C.11 — OT-UT-8 (open-questions-surface-to-user, meta-rule) placement (V2: UNCHANGED from V1)

**Target file:** `project-template/docs/pack/PM-CHAT.md`
**Target section:** `## Behavioral rules`
**Insertion anchor:** After "Plan before executing." (V1 cited L180-181); land early in the list as a high-level meta-rule.
**Edit type:** NEW bullet.

**V2 text** (carried from V1; no changes):

```
- **Open questions surface to user, never decided unilaterally.**
  When the PM chat encounters a question about cadence
  (audit/architect frequency, review checkpoints), concurrency
  (parallel agent spawns vs sequential), scope (what belongs in
  this phase vs the next), or any other decision that affects
  multi-phase ordering or project rhythm, flag it explicitly to
  the user. Do NOT decide unilaterally even when the question
  feels mechanical — multi-phase decisions compound, and a
  unilateral default that "works for the next step" can lock the
  project into a path the user would have steered away from.
  Surface, wait, decide together.
  This is a specific application of the decision presentation protocol
  (see "Decision presentation protocol" bullet below) to the open-
  questions decision class.
```

### C.12 — OT-UT-10 (/tmp reports are ephemeral) placement (V2: REVISED-WORDING per salvageability + audit §3.1.12; "Pack Chat" cross-side audience cite replaced with PACK-FEEDBACK.md channel)

**Target file:** `supporting-docs/METHODOLOGY.md`
**Target section:** Part 9 Document Authoring Rules → "What agents can and cannot modify" table (V1 cited L1384-1394).
**Insertion anchor:** Append a paragraph immediately AFTER the existing table (V1 cited ~L1395).
**Edit type:** NEW paragraph.

**V2 text** (REVISED-WORDING — V1's "paste into Pack Chat for upstream debugging" replaced with "for upstream debugging via PACK-FEEDBACK.md"; "Pack Chat" is a meaningless audience cite at a client install per audit §3.1.12):

```
> **/tmp reports are ephemeral.** When an agent prompt specifies
> a `REPORT FILE:` path under `/tmp/...` (typically used for
> docs-researcher reports, architect mid-phase reports, or any
> report the developer does not want committed to the repo),
> treat the file as ephemeral: it is safe to share externally
> (for upstream debugging via PACK-FEEDBACK.md per Part 10),
> nothing to revert if discarded, and never to be committed.
> Reports intended for the repo are written under `docs/project/`
> per the standard prompt templates.
```

**Trinity ripple:** None (METHODOLOGY.md scope, not trinity).

### C.13 — Decision presentation protocol (V2: NEW per user direction 2026-05-23; META-rule generalising §C.10 + §C.11 as sibling instances)

**Target file:** `project-template/docs/pack/PM-CHAT.md`
**Target section:** `## Behavioral rules`
**Insertion anchor:** Immediately after the §C.11 bullet ("Open questions surface to user, never decided unilaterally") inserted at H.2 step 1.
**Edit type:** NEW bullet.

**V2 text** (per user direction 2026-05-23; verbatim AFTER state):

```
- **Decision presentation protocol.** When the PM chat surfaces any
  decision to the developer — architect output review, planner output
  review, open question, agent triage outcome, multi-option fork — the
  presentation follows five points:
  (1) present decisions one at a time, never bundled;
  (2) include all context the developer needs to decide without
  switching to another document or chat — quote or summarise the
  relevant material inline;
  (3) always give a recommendation, but the recommendation must be
  evidence-based and logical, never a guess — if the evidence does not
  support a recommendation, say so and present the decision without
  one;
  (4) discuss with the developer before the developer decides — do
  not pre-commit either party to an outcome;
  (5) the PM chat is not an agent and does not do agent work,
  including proposing solutions — the PM chat may present solutions
  produced by an agent and may, with developer approval, spawn an
  agent to produce the work the right way.
```

**Cascade verdict (per §C.0):** NO REFRAME. Single-surface PM-chat orchestration meta-rule.

**Sibling instances:** §C.10 (architect-output → user-reads) and §C.11 (open-questions-surface) are specific applications of this protocol. Both bullets gain one-line sibling annotations cross-referencing §C.13 per user direction 2026-05-23.

**Trinity ripple:** None. PM-CHAT.md single-surface placement.

---

## §D — Architecture decisions (V1's §D.1-§D.5 carried over; V2 adds §D.6 PM-chat omniscience principle + §D.7 D-1 disposition rationale)

### D.1 — Per-project Claude memory cache for project-side (V2: REVISED-WORDING per salvageability B3 + audit §3.2.1)

**The question:** Should the pack ship convention / tooling for a per-project Claude memory cache under `~/.claude/projects/<project-slug>/memory/`, mirroring the pack-side cache established in Batch 19b?

**V2 decision:** YES (carried from V1 D.1 = Alt-1 recommendation; user confirmed). The pack ships convention but NOT auto-tooling. Specifically:

(a) Add a documentation paragraph to PM-CHAT.md "Tool-specific: Claude Code CLI" section explaining the per-project Claude memory cache convention.

(b) Do NOT ship a script that auto-creates a per-project memory cache.

(c) The OT memories themselves are NOT promoted to a "project-template default memory set" — only the rule CONTENT promotes (per §C); the memory entries themselves stay in OT's per-project cache.

**V2 wording cleanup per salvageability B3 + audit §3.2.1:** V1's proposed text contained two cross-side citation phrases:
- "Tier 1.5 design" — pack-internal pattern terminology not present at client install
- "same Tier 1.5 design as the pack repo (per pack memory pattern)" — references pack-side "pack memory" section name not present at client install

**V2 proposed text** (rewritten to drop cross-side citations; describe the convention on its own merits):

```
> **Per-project Claude memory cache (Claude-only).** Claude Code
> projects may use per-project memory at
> `~/.claude/projects/<slug>/memory/` as a convenience pointer
> index to project rules. Treat the directory as pure pointers
> — short one-line bullets that cite anchors in
> `docs/pack/PM-CHAT.md`, `docs/pack/METHODOLOGY.md`, or the
> project trinity (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` at
> project root). No body text in the cache; trinity / PM-CHAT.md
> / METHODOLOGY.md remain authoritative. If a cache pointer
> disagrees with the authoritative source, the source wins.
> Codex CLI and Gemini CLI have no equivalent per-project memory
> mechanism; PM chat sessions running under those CLIs read
> trinity / PM-CHAT.md / METHODOLOGY.md directly each session.
```

**Insertion target:** `project-template/docs/pack/PM-CHAT.md` "Tool-specific: Claude Code CLI" section (per V1 D.1; coder confirms section heading at HEAD — V1 cited around line 552; may have shifted).

### D.2 — Trinity surface vs PM-CHAT.md surface for behavioral rules (V2: SUBORDINATED to §D.6 PM-chat omniscience principle)

**The question:** When a new behavioral rule applies to the PM chat, does it go in trinity `## Project memory` (read by all agents and the PM chat directly) or in PM-CHAT.md `## Behavioral rules` (read only by the PM chat at startup)?

**V2 decision (REVISED-PLACEMENT per D-11 Alt-1 cascade):** The placement rule that V1 §D.2 articulated is REWRITTEN as a SUBSIDIARY of the new PM-chat omniscience principle (V2 §D.6). The mechanical placement rules become:

- **PM-chat orchestration rules** → PM-CHAT.md `## Behavioral rules` (authoritative). The PM chat may inject relevant subsets into agent prompts on demand at prompt-construction time per the omniscience principle's briefing obligation. Agents do NOT independently carry these rules.
- **Agent-affecting rules** → trinity `## Project memory` (authoritative for agents). These rules MUST be read by every agent invocation regardless of whether the PM chat is in the loop, so the trinity is the correct surface. Per §D.6.3 defense-in-depth exception, trinity placement is also correct when prompt-corruption resilience matters and the rule's audience extends beyond the PM chat.
- **Both-audience rules requiring duplication** → trinity `## Project memory` + PM-CHAT.md `## Behavioral rules` as an EXCEPTION pair (defense-in-depth documented). The default under §D.6 is single-source authoritative + PM-chat injection; the duplication pattern requires the §D.6.3 exception's justification.

**V2 wording for METHODOLOGY.md Part 9 placement rule** (this is the §D.4 architecture-derived row, REVISED-PLACEMENT per V2):

```
### Rule placement: trinity vs PM-CHAT.md vs METHODOLOGY.md

This placement rule is SUBSIDIARY to the PM chat omniscience
obligation (Part 1 — Tool Roles). The default is single-source
authoritative with PM-chat injection-into-agent-prompts as the
delivery mechanism; duplication across surfaces is the EXCEPTION
documented below.

New rules added during pack maintenance fall into one of three
categories based on audience:

- **PM-chat orchestration rules** (workflow ordering, when to
  spawn which agent, closeout sequence, prompt-generation
  discipline) → `docs/pack/PM-CHAT.md` § Behavioral rules
  (authoritative). The PM chat injects relevant subsets into
  agent prompts at prompt-construction time per the omniscience
  principle's briefing obligation. Agents do NOT independently
  carry these rules.
- **Agent-affecting rules** (no destructive operations, trinity
  rule, agent file authority, file scope) → trinity `CLAUDE.md`
  / `AGENTS.md` / `GEMINI.md` § Project memory (authoritative
  for agents). These rules apply to every agent invocation
  regardless of whether the PM chat is in the loop.
- **Both-audience rules requiring duplication** → trinity
  § Project memory + PM-CHAT.md § Behavioral rules. Use this
  duplication pattern ONLY when the rule meets one of the
  documented defense-in-depth conditions in Part 1 — Tool Roles
  (prompt-corruption resilience for high-risk rules; cross-CLI
  parity ergonomics until per-CLI injection logic exists).
  Otherwise, single-source authoritative placement applies.

This placement rule guides cleanup batches and pack-version
upgrades; it does not retroactively renumber existing rules.
Where a pre-existing duplicated rule still satisfies the
defense-in-depth conditions, leave it; where it does not,
schedule a single-source consolidation in a future cleanup batch.
```

### D.3 — Project-side audit / fix-cycle clarification (V2: LAND per V1 D-5 = Alt-1; UNCHANGED from V1)

V1 D.3 recommended adding a cycle-termination clarification paragraph to METHODOLOGY.md Workflow 4. User decision: LAND.

**V2 text** (carried from V1; no changes):

```
> **Cycle termination.** The fix cycle terminates when the
> reviewer returns Verdict: Ready to commit AND no architect
> trigger fires per the Trigger A / Trigger B checks. A cycle
> that fails to terminate after 3 coder passes against the same
> phase ALWAYS triggers Trigger A and the architect pass — the
> architect either resolves the root cause (allowing the cycle
> to converge in the next coder pass) or escalates to the user
> for re-scoping. There is no infinite-cycle path; either
> reviewer-PASS terminates, or the architect pass terminates by
> re-scoping the work.
```

**Insertion target:** `supporting-docs/METHODOLOGY.md` Workflow 4, after the fenced code block at V1-cited L449 (coder verifies at HEAD).

### D.4 — Project-side "when to call planner mid-phase" mid-phase planner triggers (V2: LAND per V1 D-6 = Alt-1; UNCHANGED from V1)

V1 D.4 recommended adding a "Planner trigger (mid-phase)" sub-section to METHODOLOGY.md Workflow 4 with three triggers (P-A: task-definition ambiguity from coder; P-B: architect output names "planning pass needed"; P-C: task-ordering revision discovered mid-phase). User decision: LAND with all 3 triggers.

**V2 text** (carried from V1's §D.4 substance; coder applies as new sub-section in METHODOLOGY.md Workflow 4, sibling to the existing architect trigger conditions):

```
#### Planner trigger conditions (mid-phase)

Sibling to the architect trigger conditions above, three
mid-phase planner triggers cover task-level revision needs:

- **Trigger P-A — Task-definition ambiguity surfaced by coder.**
  The coder's report names a task that "could not be completed
  as specified" because the task description is ambiguous — not
  missing data, not architectural issue, but a task-wording
  problem. PM chat surfaces the ambiguity to the user AND a
  candidate planner pass; user approves before the planner runs.
- **Trigger P-B — Architect output names "planning pass needed"
  as the follow-up.** When the architect pass concludes "the
  design is sound; the task breakdown needs revision," PM chat
  invokes the planner with the architect's output as input.
- **Trigger P-C — Task-ordering revision discovered mid-phase.**
  When coder mid-phase discovers that task B's preconditions
  require task A's output (and the original plan had them
  parallel or reversed), PM chat surfaces this to the user AND
  a candidate planner pass to re-sequence.

For each trigger, the planner pass produces an updated
IMPLEMENTATION-PLAN.md Phase N task block; PM chat presents to
user for approval before re-running the coder.

**Planner-vs-architect demarcation:** A "task-definition
ambiguity" (P-A) is a planning problem — the task wording is
unclear about the contract or the deliverable. A "design
problem" is an architecture problem — the contract itself is
wrong or incomplete. If a coder reports both, run the architect
trigger first (architect resolves the design problem; planner
then re-shapes tasks under the corrected design). Never run
P-A in parallel with an architect trigger — sequencing matters.
```

**Insertion target:** `supporting-docs/METHODOLOGY.md` Workflow 4, new sub-section after the existing architect trigger conditions (V1 cited around L510-533 for the architect triggers; coder picks the precise insertion).

### D.5 — Project-side closeout-gating elevation (V2: UNCHANGED from V1; combine with §C.4 commit per V1 sequencing)

V1 D.5 recommends placing the closeout-sequence rule in PM-CHAT.md per §C.4 plus adding a one-line cross-reference in METHODOLOGY.md Part 7 Procedure 4 pointing at the PM-CHAT.md bullet.

**V2 cross-reference text** (carried from V1; no changes):

```
> **Closeout-sequence rule.** Procedure 4 step 3 ("PM chat marks
> Status: Resolved") and step 4 ("Run disposition scan") MUST
> be preceded by the closeout sequence defined in PM-CHAT.md
> `## Behavioral rules` ("Closeout sequence — present, wait,
> then write."): trigger check → present content → wait for
> approval → write → show commit message → wait for approval →
> commit. Never write closeout files before presenting their
> content and receiving approval.
```

**Insertion target:** `supporting-docs/METHODOLOGY.md` Part 7 Procedure 4, after step 4 area (V1 cited L1198; coder verifies).


### D.6 — PM chat omniscience obligation (NEW for V2; lands per D-11 Alt-1; principle text drafted)

#### D.6.1 — Background

User articulated mid-V1-review (captured in `ARCHITECTURE-CLEANUP-BATCH-19C-PRINCIPLE-CHECK.md` §1, 2026-05-17):

> The PM chat is the Project Manager, thus PM, and therefore is obligated to have a bird's eye view of all workflows and processes. Agents may know about other agents, but they are not obligated to, while the PM chat is obligated to. This means, that the PM chat is obligated to give agents all the information, rules, guardrails, and structure they need to do their work effectively AND so it integrates smoothly with other agent work they may not know about. This is a fundamental principle.

The principle decomposes into two halves:
- **(a)** PM chat has a bird's-eye view of all workflows and processes; agents do not.
- **(b)** PM chat is OBLIGATED to brief agents with the rules, guardrails, and integration context they need.

PRINCIPLE-CHECK §3 (V1 architect's analysis): half (a) is implicit-strong across pack source; half (b) is implicit-weak and never named as a unified principle. The V1 architect's recommendation: codify the principle in METHODOLOGY.md Part 1 "Tool Roles" as a NEW sub-section, then cascade-reframe ~12 §C placements under it. User decision = Alt-1 (LAND + cascade).

#### D.6.2 — Proposed METHODOLOGY.md Part 1 sub-section text (the V2 principle landing)

**Target file:** `supporting-docs/METHODOLOGY.md`
**Target section:** `## Part 1 — Tool Roles`
**Insertion anchor:** After the existing "Separation rule" sub-section at L98 (which establishes "Planning and decisions: Claude Chat only. Execution and file changes: CLI agents only. Pasting results from CLI back to Claude Chat: developer only."). Land the new sub-section IMMEDIATELY after Separation rule, before Part 2.
**Edit type:** NEW sub-section.

**Proposed text** (drafted per the salvageability §4 D-11 + B9 guidance — boundary-discipline cleanup applied; cites only project-side surfaces; no pack-side memory references):

```
### PM chat omniscience obligation

The Separation rule above describes the WHAT — who does what
work. This sub-section describes the WHY — why the PM chat is
positioned as the brain.

The PM chat operates with a bird's-eye view of ALL workflows
and processes in the project: every agent's role and capability,
every methodology rule, every active phase, every standing
constraint, every cross-agent integration point. Agents,
by contrast, operate with a focused view of their assigned
task and the prompt context the PM chat provides — they may
know about other agents incidentally, but they are not
obligated to. The PM chat is.

This positioning creates an OBLIGATION: when constructing any
agent prompt, the PM chat must give the agent all the
information, rules, guardrails, and structure that agent needs
to do its work effectively AND to integrate cleanly with other
agent work it may not know about. This includes:

- Citing the project-side rules the agent must respect (from
  `docs/pack/PM-CHAT.md` § Behavioral rules, the project trinity
  § Project memory, and this methodology document).
- Naming the specific files the agent reads, writes, or must
  avoid (per the per-prompt File-in-scope / Out-of-scope lists
  in § Prompt Authoring Principles).
- Injecting per-agent prompt-template content the agent has no
  way to discover otherwise (REPORT FILE line, completion-
  report shape, chunked-Write instruction).
- Providing the integration context the agent needs to produce
  output that fits with upstream and downstream agent work
  (e.g., a coder receives the architect's relevant decisions;
  a reviewer receives the planner's task contract).

This obligation has two documented exceptions where duplication
across surfaces is the correct trade-off (see Part 9 § Rule
placement for the full taxonomy):

- **Defense-in-depth duplication for high-blast-radius rules.**
  When a rule is agent-affecting AND prompt-corruption risk is
  non-trivial (e.g., destructive git verbs that ALL agents must
  respect), the rule lives in the project trinity § Project
  memory in addition to wherever else it might be invoked.
  Trinity is read by every agent at session start regardless
  of prompt content; this is the strongest available delivery.
- **Cross-CLI parity ergonomics.** Where the pack ships content
  to all three CLI tools (Claude Code, Codex CLI, Gemini CLI)
  and per-CLI prompt-injection logic does not yet exist, the
  shipped content may carry the rule directly to reduce
  per-CLI implementation overhead. This exception narrows as
  per-CLI injection mechanisms become available.

When in doubt, default to single-source authoritative + PM-chat
injection. Duplication requires a documented exception.
```

**Trinity ripple:** None directly (METHODOLOGY.md is not trinity). The principle has downstream effects on §D.2 placement rule (REVISED-PLACEMENT per V2 §D.2 above) and §C.6 / §C.7 reframings (per V2 §C.0 cascade summary), but the principle text itself lands in one place.

#### D.6.3 — Documented exceptions to the principle (mirror surface — single-paragraph callout)

This list is referenced from §D.2 placement rule and from individual §C placement notes (e.g., §C.6 REFRAME-EXCEPTION).

| Exception | When it applies | Worked example in V2 |
|---|---|---|
| Defense-in-depth via trinity duplication | Rule is agent-affecting (all agents must respect, not just PM chat) AND prompt-corruption risk is non-trivial. Trinity placement IS the duplication; the PM chat's preferred injection delivery is brittle for this class. | §C.6 trinity STRENGTHEN (destructive-ops list extension with `git checkout --`). |
| Cross-CLI parity ergonomics | Pack ships content to all three CLI tools; per-CLI prompt-injection logic does not exist yet; per-CLI implementation cost would exceed the duplication cost. Narrows as per-CLI injection mechanisms become available. | Agent definition files (`.claude/agents/`, `.codex/agents/`, `.gemini/agents/`) currently repeat "No state-changing git operations" verbatim across 16 agents × 3 CLIs. Under D-11, the rule would live at PM-CHAT.md and inject per agent — but per-CLI injection isn't implemented; the duplication stays under this exception until per-CLI injection ships. |

**Worked anti-pattern:** A rule that lives in BOTH PM-CHAT.md § Behavioral rules AND project trinity § Project memory because the author defaulted to mirroring without invoking an exception. Per §D.6, this is duplicate-with-divergence-risk and should be consolidated to single-source. Future cleanup batches may schedule consolidation; V2 does not consolidate pre-existing duplications unless they are introduced in V2 itself (none are).

### D.7 — D-1 disposition: NO Claude-only Sub-agent behavior sub-section in project-template CLAUDE.md (FRESH V2 DECISION)

#### D.7.1 — The question

V1 §F D-1 asked: should the project-template trinity carry a `### Sub-agent behavior (Claude-only)` sub-section analogous to the pack-root trinity's existing CLAUDE-only sub-section (which covers worktree-isolation, sub-agent backgrounding, and Agent Teams stage lifecycle)? V1's recommendation was Alt-1 NO; salvageability §4 D-1 flagged the question for re-evaluation under post-BD-175 Check 18 H2 parity implications.

#### D.7.2 — V2 disposition: NO (re-confirmed with strengthened post-BD-175 rationale)

V2 confirms V1's NO recommendation, with three reinforcing post-BD-175 considerations:

**Consideration 1 — Check 18 H2 within-trinity body parity (BD-181 + BD-183).** CI Check 18 verifies the H2 body content across `project-template/{CLAUDE,AGENTS,GEMINI}.md` is identical, modulo a documented allow-list for Gemini-intrinsic H2 sections (`## Gemini CLI operating notes`, `## Agent roster`). The allow-list mechanism is H2-level, not H3-level: it allows entire H2 sections to be Gemini-only, but it does NOT allow H3 sub-sections within shared H2s to differ. A new H3 `### Sub-agent behavior (Claude-only)` under the SHARED `## Project memory` H2 would create body-content divergence in a SHARED H2 — Check 18 would fail. To land this sub-section without CI failure, V2 would need to either (a) extend Check 18's allow-list mechanism to H3-level (a structural CI change requiring its own BD + architect-pass + planner + coder), or (b) duplicate the sub-section across all three trinity files (defeating the "Claude-only" semantic and creating wrong-CLI noise for Codex/Gemini readers).

**Consideration 2 — Project-side SSOT-first wording is more restrictive than pack-side's.** The project trinity rule wording (per `project-template/CLAUDE.md` L376-379: "Symmetry is the default; asymmetry requires justification as provably tool-specific") is functionally similar to pack-side's "Trinity rule," but the project-side trinity ships to clients who may or may not use Claude. A Claude-only sub-section in `project-template/CLAUDE.md` would be a no-op for Codex / Gemini client teams reading their respective trinity files (which would not have the sub-section), creating an asymmetry between what a Claude-using client team sees vs what a Codex / Gemini client team sees. Pack-side trinity does not have this concern (pack maintainers use whichever CLI they choose to operate on the pack itself; the asymmetry is internal).

**Consideration 3 — The rule's content is informational, not a behavioral guardrail.** The OT-UT-1 content (Agent Teams stage lifecycle: keep sub-agents alive within a stage, SendMessage for follow-ups, close at commit) is operationally useful for a Claude-using project team but it is NOT a project-team behavioral rule of the trinity class. The trinity `## Project memory` carries rules like "trinity rule," "no destructive operations," "PM chat does not architect," "Project SSOT-first" — these are project-team behavioral guardrails. Agent Teams stage lifecycle is a CLI-runtime convention. Different surface category.

#### D.7.3 — V2 placement of the OT-UT-1 content: METHODOLOGY.md Part 1 "Tool Roles" → "Claude Code CLI (agents)" sub-section (per V1 D-1 Alt-3 reframed)

The OT-UT-1 content lands as a single informational paragraph in `supporting-docs/METHODOLOGY.md` `## Part 1 — Tool Roles` under the existing `### Claude Code CLI (agents)` sub-section (V1 cited L78-83 area). The paragraph names the convention as Claude-Code-specific operating notes for Claude-using client teams; Codex and Gemini client teams reading their respective trinity files see no asymmetric Claude-only sub-section in trinity, and the Claude-only convention is documented in METHODOLOGY.md (project-side, but not trinity).

**Proposed text** (INFORMATIONAL paragraph, Claude-specific operating notes):

```
> **Claude-only operating convention — Agent Teams stage
> lifecycle.** When the developer enables Claude Code's Agent
> Teams flag (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`),
> sub-agents spawned for a phase stage (architect → planner →
> coder → reviewer) stay alive within the stage; the PM chat
> uses SendMessage to send follow-up directives to the same
> sub-agent instance. After the stage's commit lands, close
> all stage sub-agents and respawn fresh for the next stage.
> Additionally, each coder commit should use a FRESH coder
> instance — never reuse a coder across commits, even within
> the same stage. This convention is Claude-Code-specific:
> Codex CLI's `/agent` slash command provides similar
> long-lived-thread behavior but no peer-messaging analog;
> Gemini CLI's `@agent` invocation is one-shot per delegation
> (no parent-controlled keep-alive across multiple parent
> turns). Codex / Gemini project teams: this convention does
> not apply to your CLI's runtime behavior.
```

**Insertion target:** `supporting-docs/METHODOLOGY.md` Part 1 → `### Claude Code CLI (agents)` sub-section. Insert as a `>` callout immediately after the existing bullet list of Claude Code CLI capabilities (around V1-cited L83; coder verifies at HEAD).

**Trinity ripple:** None. No new H3 in trinity. No Check 18 H2 parity collision. No project-side trinity asymmetry.

**Cross-CLI reference check per BD-182 §4.1:** The paragraph names Claude Code's Agent Teams flag, SendMessage, Codex's `/agent` slash command, and Gemini's `@agent` invocation — these are CLI-specific surfaces. Per Override 9, a single METHODOLOGY.md paragraph naming all three is correct (METHODOLOGY.md is read by PM chats running on any of the three CLIs and benefits from naming all three for cross-CLI reader contextualization). This is the TOOL-NEUTRAL enumeration pattern from BD-182 §3.1 R3-R7 — enumeration across all three CLIs in a shared document is correct per-audience for any of the three readers.

#### D.7.4 — Surfacing for user confirmation in §F (closed-question section)

D-7's disposition is "re-confirm V1's NO recommendation with strengthened post-BD-175 rationale + reframe to METHODOLOGY.md Part 1 placement." This is the call architect makes per V1 D-1 Alt-1 + Alt-3 hybrid; surfaced for user confirmation at V2 review. If the user wants a different disposition (e.g., extend Check 18's allow-list to H3-level and land the Claude-only sub-section in project-template/CLAUDE.md), that requires its own BD, architect-pass, planner, and coder cycle — NOT a V2 in-batch change. V2 default is the disposition above.

---


## §E — Out of scope (V1 §E carried over verbatim)

V1 §E.1 through E.6 are carried into V2 unchanged. The OOS rationale below summarizes; coder + planner consume V1 §E.1-E.6 directly for full reasoning.

### E.1 — Pack-side files (Batch 19b territory + post-BD-175 pack-ops/)

OOS surfaces:
- Pack-root `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` `## Pack memory` section.
- `pack-ops/PACK-CHAT.md`, `pack-ops/PACK-AGENTS.md`, `pack-ops/BOUNDARY-DEFINITION.md`, `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`, all other `pack-ops/` files.
- `maintenance-docs/` (this V2 doc itself lives here as pack-internal authoring artifact).
- `scripts/` general directory (pack-internal scripts). EXCEPTION: V2 H.10 touches `scripts/lib/detect.sh` (Category D leak sweep), H.12 modifies `scripts/validate-pack.py` (Guardrail 3), H.14 modifies `scripts/validate-pack.py` + adds `scripts/tests/test-validate-pack-check-43.sh` (Guardrail 1). These are EXPLICIT in-scope additions per V2 leak-sweep + guardrails absorption; the general scripts/ tree is otherwise untouched.

### E.2 — OT-specific rules (V1 §E.2 unchanged)

OOS items: OT-UT-4 (only OPEN TDs in scope for v11 conversion), OT-UT-5 (Phase 58b deferred), OT-UT-7 (feature prioritization deferred), OT-UT-8 specifics (specific OT open questions).

The OT-UT-8 META-rule (open-questions-surface-to-user) IS promoted per §C.11.

### E.3 — Test fixtures, CI workflows, GH MCP integration

V1 §E.3 carried over: `test-fixtures/`, `.github/workflows/`, GitHub MCP server setup (`.mcp.json.example`) — no content changes in Batch 19c.

**V2 caveat:** H.14 (Guardrail 1 / Check 43) adds a single line to `.github/workflows/validate-pack.yml` to wire the new per-check test file. This is the minimal CI workflow change to make Check 43 fire; it is NOT a workflow-architecture change.

### E.4 — Skills and agent definitions content (frontmatter only)

V1 §E.4 carried over. No content changes to `project-template/.claude/agents/*.md`, `.codex/agents/*.toml`, `.gemini/agents/*.md` agent definitions (except H.13's fence-marker placement, which is mechanical and doesn't change rule content; see §H.13).

### E.5 — Project-template trinity NEW sub-sections

V1 §E.5 carried over with V2 strengthening per §D.7: Batch 19c does NOT propose new H3 sub-sections under `## Project memory` in the project-template trinity. The conditional V1 H.7 (Claude-only sub-section) is DROPPED per V2 §D.7 disposition (NO new sub-section; OT-UT-1 content lands as METHODOLOGY.md Part 1 paragraph instead).

### E.6 — Project-side prompt files (agent prompts)

V1 §E.6 carried over: no content changes to `project-template/docs/pack/prompts/<agent>.md` files UNLESS required by H.13 fence marker placement (mechanical) or H.11 Category C pm-chat variant rewrite (in-scope per absorbed leak sweep).

**Specifically in scope per V2 absorbed work:**
- H.11 rewrites `project-template/docs/pack/prompts/pm-chat.md` three variants (manual-fallback, generate-setup, generate-agent-kickoff) per Category C-c direction.
- H.13 places fence markers in `project-template/docs/pack/prompts/coder.md` and `reviewer.md` per Guardrail 2 contract.

These are EXPLICIT in-scope per V2 leak-sweep + guardrails absorption; all other prompt files remain untouched.

---

## §F — Closed-question resolutions (V1 §F D-1..D-10 + PRINCIPLE-CHECK D-11; ALL CLOSED)

V1 §F surfaced 11 open questions (D-1 through D-10 + D-11 added by PRINCIPLE-CHECK). User decisions have closed all 11 before V2 was spawned. This section documents the resolutions.

| ID | Question (short) | V1 architect recommendation | V2 resolution |
|---|---|---|---|
| D-1 | Claude-only Sub-agent behavior sub-section in project-template/CLAUDE.md | NO (Alt-1) | **NO — RE-CONFIRMED V2 §D.7** with strengthened post-BD-175 rationale; OT-UT-1 content lands as METHODOLOGY.md Part 1 paragraph (per V1 Alt-3 reframed) |
| D-2 | Trinity placement of always-reviewer rule (§C.1) | NO trinity placement (Alt-1) | **NO trinity placement** — confirmed per V1 D-2 + V2 §C.0 cascade analysis (PM-CHAT.md + METHODOLOGY.md is audience-specific pair, not duplicate-with-divergence) |
| D-3 | Should §C.3 OT-T-3 BACKLOG-proactive STRENGTHEN land | LAND (Alt-1) | **LAND** — per V1 recommendation; CONDITIONAL flag closed |
| D-4 | Land trinity-vs-PM-CHAT.md placement rule in METHODOLOGY.md Part 9 | LAND (Alt-1) | **LAND as SUBSIDIARY of D-11 PM-chat omniscience principle** — per V2 §D.2 REVISED-PLACEMENT |
| D-5 | Should §D.3 cycle-termination clarification land | LAND (Alt-1) | **LAND** — per V1 recommendation; CONDITIONAL flag closed |
| D-6 | Should §D.4 mid-phase planner P-A/P-B/P-C triggers land | LAND with all 3 triggers (Alt-1) | **LAND with all 3 triggers** — per V1 recommendation; CONDITIONAL flag closed |
| D-7 | Prescriptiveness of closeout-sequence rule (§C.4) | LAND as written (Alt-1) | **LAND as written** — per V1 recommendation |
| D-8 | Ship trinity STRENGTHEN for `git checkout --` in this batch | SHIP (Alt-1) | **SHIP, REVISED to apply to BD-178-canonicalized baseline** (per salvageability B5 / V2 §C.6); defense-in-depth exception documented per V2 §D.6.3 |
| D-9 | Group by RULE vs FILE in commits | GROUP BY RULE (Alt-1) | **GROUP BY RULE** — V1 recommendation preserved; V2 §H sequencing follows the rule-grouping pattern |
| D-10 | Per-commit reviewer vs end-of-batch only | END-OF-BATCH ONLY (Alt-1) | **HYBRID — per-BD INLINE reviewer for trinity / boundary-sensitive commits; END-OF-BATCH for non-boundary-sensitive + cross-batch surface** per user direction citing post-BD-175 per-BD-INLINE default. V2 §H attaches per-commit reviewer to H.4, H.5, H.9, H.10, H.11, H.13, H.14, H.15, H.16 (H.15 added per Decision 4 (b) 2026-05-22 user-directed symmetric trinity coverage; H.5 alignment with §I + §H.5 + §J.6). Reviewer scope refined per Decision 4 (α-sliding) 2026-05-22: each INLINE reviewer covers the diff from prior INLINE commit (or H.0 baseline) through current commit, ensuring no commits are unreviewed before H.17 end-of-batch. Coverage windows: H.4 covers H.1-H.4; H.9 covers H.6+H.7+H.9; H.13 covers H.12+H.13; other INLINE commits cover their own diff only. |
| D-11 | PM-chat omniscience principle (added by PRINCIPLE-CHECK §6) | LAND in METHODOLOGY.md Part 1 + cascade (Alt-1) | **LAND in METHODOLOGY.md Part 1 + cascade applied** per V2 §D.6 + V2 §C.0 cascade summary |

**No open questions remain in V2.** The architect-doc-to-planner gate is fully resolved. Planner consumes V2 directly; no further architect pass.

---

## §G — Research needs (V1 G-1..G-9 carried; ALL VERDICTS RECONFIRMED per salvageability)

Per `ARCHITECTURE-PRE-19C-SALVAGEABILITY.md` §5: all 9 G-item research verdicts still hold post-BD-175. V2 carries the verdicts without re-derivation; cited from `RESEARCH-19C-G-ITEMS-VERIFICATIONS.md` + salvageability §5 confirmation.

| ID | Verdict | Architect-decision dependency | V2 status |
|---|---|---|---|
| G-1 | Y — Claude Code worktree-isolation issue applies universally to client-project sub-agent spawns (official docs + issues #50850, #41680, #43535) | V2 §D.7 D-1 disposition (NO new trinity sub-section; informational paragraph in METHODOLOGY.md instead) | RECONFIRMED |
| G-2 | Y (with nuance) — Codex/Gemini have spawn/cap/close but NO true keep-alive-across-phase-close-at-commit analog to Claude Agent Teams + SendMessage. `agent-run.sh` doesn't manage lifecycle on either CLI | V2 §D.7 paragraph names all three CLIs per-audience contextualization | RECONFIRMED |
| G-3 | N — architect-trigger surface-even-mechanical rule absent from pack source (METHODOLOGY.md L489-533, PM-CHAT.md 201-202, trinity files all checked) | V2 §C.2 placement confirmed | RECONFIRMED |
| G-4 | Y (partial) — PM-chat-never-edits-source rule partially in PM-CHAT.md "Source file edits" bullet + METHODOLOGY Part 9 table; no explicit "never edits source" negative bullet | V2 §C.6 placement confirmed | RECONFIRMED |
| G-5 | Y — re-read PRINCIPLES rule exists at PM-CHAT.md L188-189; re-read per-agent prompt FILE rule absent | V2 §C.7 placement confirmed | RECONFIRMED |
| G-6 | Y — closeout sequence fragments scattered (PM-CHAT.md "Source file edits" + METHODOLOGY Part 7 Procedure 4 + Part 9); no single 5-step ordered bullet | V2 §C.4 + V2 §D.5 placement confirmed | RECONFIRMED |
| G-7 | Y — mid-phase planner triggers absent; Planner trigger rule at METHODOLOGY.md L236-248 covers phase-design-time only | V2 §D.4 placement confirmed | RECONFIRMED |
| G-8 | N — no significant overlap with planning / architecture-review / review / pm-startup skills | V2 §C placements stand without skill-redirection | RECONFIRMED |
| G-9 | N — pack ships nothing for per-project Claude memory cache tooling | V2 §D.1 / §C-derived placement confirmed (convention only; no tooling) | RECONFIRMED |

**No re-research needed for V2.** Planner consumes the V1 G verdicts as-is.

---


## §H — Commit sequencing (V2 INTEGRATED — 17 commits total)

This section is the planner's primary input. The planner refines each commit's task list with exact file paths and verification commands per commit; the structure below names commit purpose, scope, RC9 trigger status, per-commit reviewer decision, and ordering rationale.

### H.0 — Pre-commit setup

- **HEAD baseline:** `7b1be5fc33315b24b2570d740b0857c4c5fa2d02` (post-BD-179 Phase 1). Coder verifies HEAD has not advanced before commit 1.
- **Branch:** `v11-dev`.
- **Working-tree baseline:** Per `git status` at architect-pass start: 7 modified files in `pack-ops/` + `scripts/` (BD-179 in-flight) + 2 new files in `maintenance-docs/v11-implementation/`. **Planner / coder MUST coordinate with BD-179 status before commit 1** — if BD-179 has not closed (status flip to Resolved + manifest-clean), Batch 19c commits cannot land cleanly. Assume BD-179 closes before Batch 19c restarts; if not, the per-batch BD ordering per `BACKLOG.md` § BD-179 entry overrides V2 sequencing.
- **BD-173 status:** Open (to be flipped after all commits land and end-of-batch reviewer is clean — per single-BD batch close commit shape, the BD-173 status flip is combined with the end-of-batch fix commit in H.17).

### H.1 — METHODOLOGY.md Workflow cycle additions

**Scope:** §C.1 METHODOLOGY callout (always-reviewer cycle invariant) + §C.2 STRENGTHEN (Trigger A/B surface-even-mechanical) + §D.3 cycle-termination clarification + §C.10 Workflow 4 step 4 STRENGTHEN (architect-output user-reads).

**Files modified:**
- `supporting-docs/METHODOLOGY.md`

**Per-commit reviewer:** SKIP (non-boundary-sensitive; pure methodology additions on a single file).

**RC9 manifest regen:** **REQUIRED** (`supporting-docs/` in v11-surface per BD-176 expansion).

**Commit message:** `feat: v11 — BD-173 METHODOLOGY.md workflow clarifications (Batch 19c.1)`

**Rationale:** METHODOLOGY.md is the PM-chat's authoritative methodology reference; landing the cycle-invariant + trigger-extension + cycle-termination + architect-output-reads content here first ensures the PM-CHAT.md bullets in H.2 can cite the new METHODOLOGY.md anchors.

### H.2 — PM-CHAT.md `## Behavioral rules` additions (PM-chat orchestration rules)

**Scope:** §C.1 PM-CHAT.md bullet (always-reviewer) + §C.4 (closeout-sequence) + §C.7 (re-read per-agent prompt files) + §C.8 (pack-repo-read-only — REVISED-WORDING per V2 §C.8) + §C.9 (mid-pipeline working-tree intentional) + §C.10 PM-CHAT.md bullet (architect-output user-reads — REVISED-WORDING per V2 §C.10) + §C.11 (open-questions surface) + §C.13 (decision presentation protocol — NEW per user direction 2026-05-23) + §D.5 (METHODOLOGY.md Part 7 Procedure 4 cross-reference to PM-CHAT.md closeout-sequence rule).

**Files modified:**
- `project-template/docs/pack/PM-CHAT.md`
- `supporting-docs/METHODOLOGY.md` (Part 7 Procedure 4 cross-ref only — small)

**Per-commit reviewer:** SKIP (non-boundary-sensitive; PM-CHAT.md is project-side SSOT for PM-chat orchestration).

**RC9 manifest regen:** **REQUIRED** (both `project-template/` and `supporting-docs/` in v11-surface).

**Commit message:** `feat: v11 — BD-173 PM-CHAT.md behavioral rules consolidation (Batch 19c.2)`

**Rationale:** Most additions are PM-CHAT.md, single file dominates the diff. Includes the cross-ref back to METHODOLOGY.md so the closeout-sequence rule has both home + cross-reference together.

### H.3 — PM-CHAT.md STRENGTHEN (existing-bullet extensions)

**Scope:** §C.5 (STRENGTHEN "Source file edits" with no-chained-git-add and "approve to commit" wording) + §C.6 PM-CHAT.md bullet (PM-chat-never-edits-source).

**Files modified:**
- `project-template/docs/pack/PM-CHAT.md`

**Per-commit reviewer:** SKIP (non-boundary-sensitive; PM-CHAT.md STRENGTHEN + NEW bullet).

**RC9 manifest regen:** **REQUIRED** (`project-template/` in v11-surface).

**Commit message:** `feat: v11 — BD-173 PM-CHAT.md source-edit discipline (Batch 19c.3)`

**Rationale:** Source-edit discipline is a related cluster — the STRENGTHEN on "Source file edits" naturally precedes the new "PM chat never edits production source files" bullet. Splitting from H.2 keeps the "new bullets" vs "existing bullet STRENGTHEN" diffs visually separable.

### H.4 — Trinity STRENGTHEN — destructive-operations list extension

**Scope:** §C.6 trinity STRENGTHEN (extend "No destructive operations" bullet with `git checkout --`). REVISED-WORDING per V2 §C.6 — apply to BD-178-canonicalized baseline.

**Files modified:**
- `project-template/CLAUDE.md`
- `project-template/AGENTS.md`
- `project-template/GEMINI.md`

**Per-commit reviewer:** **REQUIRED INLINE — sliding-window scope per Decision 4 (α-sliding) 2026-05-22.** Reviews the diff from the H.0 baseline through end of this commit — i.e., H.1 + H.2 + H.3 + H.4 (4 commits). Scope expands to include the H.1 METHODOLOGY workflow additions, H.2 PM-CHAT.md behavioral rules, and H.3 PM-CHAT.md STRENGTHEN in addition to this commit's trinity edit. Trinity edit; boundary-sensitive per post-BD-175 default; reviewer verifies trinity parity + BD-178 baseline correctness + Override 9 non-applicability.

**RC9 manifest regen:** **REQUIRED** (`project-template/` in v11-surface; trinity edits trigger).

**Commit message:** `feat: v11 — BD-173 trinity destructive-ops list extension (Batch 19c.4)`

**Rationale:** Trinity edits land separate from PM-CHAT.md / METHODOLOGY.md to keep the trinity-ripple commit clean and reviewable. Per the project trinity rule, all three files in one commit. Defense-in-depth exception documented per V2 §D.6.3 + §C.6 REFRAME-EXCEPTION.

### H.5 — METHODOLOGY.md substantive additions (D-4 mid-phase planner + D-2 placement rule reframed + D-11 cascade documented in placement rule + C.12 /tmp ephemerality)

**Scope:** §D.4 (NEW METHODOLOGY.md Workflow 4 sub-section "Planner trigger conditions (mid-phase)" with P-A/P-B/P-C) + §D.2 REVISED-PLACEMENT (NEW METHODOLOGY.md Part 9 sub-section "Rule placement: trinity vs PM-CHAT.md vs METHODOLOGY.md" SUBSIDIARY to D-11 principle) + §C.12 (METHODOLOGY.md Part 9 appended paragraph "/tmp reports are ephemeral" — REVISED-WORDING per V2 §C.12).

**Files modified:**
- `supporting-docs/METHODOLOGY.md`

**Per-commit reviewer:** **REQUIRED INLINE — sliding-window scope per Decision 4 (α-sliding) 2026-05-22.** Reviews this commit's diff only (sliding window = H.5 alone; prior INLINE reviewer was H.4 covering H.1-H.4). Substantive methodology additions; §D.4 introduces 3 new mid-phase planner triggers — non-trivial procedural surface; reviewer verifies trigger boundaries vs architect-trigger demarcation.

**RC9 manifest regen:** **REQUIRED** (`supporting-docs/` in v11-surface).

**Commit message:** `feat: v11 — BD-173 METHODOLOGY.md substantive additions (mid-phase planner, rule placement subsidiary to PM-chat omniscience, /tmp ephemerality) (Batch 19c.5)`

**Rationale:** Substantive procedural additions warrant inline review per post-BD-175 default. Single METHODOLOGY.md file scope.

### H.6 — METHODOLOGY.md Procedure 1 BACKLOG-proactive-surfacing STRENGTHEN

**Scope:** §C.3 (LAND per V1 D-3 = Alt-1; CONDITIONAL flag closed).

**Files modified:**
- `supporting-docs/METHODOLOGY.md`

**Per-commit reviewer:** SKIP (small STRENGTHEN; single sentence appended; not boundary-sensitive).

**RC9 manifest regen:** **REQUIRED** (`supporting-docs/` in v11-surface).

**Commit message:** `feat: v11 — BD-173 METHODOLOGY.md proactive BACKLOG surfacing (Batch 19c.6)`

**Rationale:** Procedure 1 (Part 7) is far from the prior commit's edit sites; cleaner diff to keep isolated.

### H.7 — PM-CHAT.md per-project Claude memory cache convention (§D.1 placement, REVISED-WORDING per V2 §D.1)

**Scope:** §D.1 (NEW paragraph in PM-CHAT.md "Tool-specific: Claude Code CLI" section; per V1 D-1 = Alt-1 confirmed; REVISED-WORDING per V2 §D.1 + salvageability B3 — drop "Tier 1.5 design" and "pack memory pattern" cross-side citations).

**Files modified:**
- `project-template/docs/pack/PM-CHAT.md`

**Per-commit reviewer:** SKIP (NEW paragraph; project-side; single file).

**RC9 manifest regen:** **REQUIRED** (`project-template/` in v11-surface).

**Commit message:** `feat: v11 — BD-173 PM-CHAT.md per-project Claude memory cache convention (Batch 19c.7)`

**Rationale:** PM-CHAT.md is the project-side PM-chat orchestration SSOT; the Claude-only convention paragraph lands in the existing "Tool-specific: Claude Code CLI" section per V1 §D.1.

**Note on V1's CONDITIONAL H.7:** V1's H.7 was the conditional Claude-only sub-section in `project-template/CLAUDE.md` (D-1 Alt-2). V2 §D.7 DROPS this conditional — the OT-UT-1 content lands instead in METHODOLOGY.md Part 1 paragraph (covered by H.16 below — see V2 §D.7.3 + H.16 scope). V2's H.7 is REPURPOSED to land the §D.1 per-project Claude memory cache convention.

### H.8 — (REMOVED — V1's H.8 was end-of-batch; V2 renumbers end-of-batch to H.17)

V1's H.8 was the end-of-batch reviewer + status flip. V2 renumbers this to H.17 to accommodate H.9-H.16 inserted between V1's H.7 and V1's H.8.

### H.9 — Leak sweep Categories A + B (per-entry skeleton sweep)

**Scope:** 30 leaks across 7 per-entry-tree skeleton files under `project-template/docs/project/{backlog,implementation-plan,changelog}/`. Category A (25 leaks): delete the architect-doc cite clause; preserve the surrounding rule wording. Category B (5 leaks): substitute the architect-doc cite with the sibling `_rules.md` reference or descriptive prose.

**Files modified (7 distinct files):**
- `project-template/docs/project/backlog/_rules.md`
- `project-template/docs/project/backlog/_intro.md`
- `project-template/docs/project/implementation-plan/_rules.md`
- `project-template/docs/project/implementation-plan/_intro.md`
- `project-template/docs/project/changelog/_rules.md`
- `project-template/docs/project/changelog/_intro.md` (Category B)
- `project-template/docs/project/changelog/_format.md` (Category B)

**Per-commit reviewer:** **REQUIRED INLINE — sliding-window scope per Decision 4 (α-sliding) 2026-05-22.** Reviews the diff from the prior INLINE commit (H.5) through end of this commit — i.e., H.6 + H.7 + H.9 (3 commits; H.8 was removed and renumbered to H.17). Scope expands to include the H.6 METHODOLOGY Procedure 1 STRENGTHEN and H.7 PM-CHAT.md per-project Claude memory cache addition in addition to this commit's leak sweep. Boundary-sensitive; reviewer verifies each cite is correctly dropped OR replaced; reviewer scans the 7 files for any new leaks introduced.

**RC9 manifest regen:** **REQUIRED** (`project-template/` in v11-surface).

**Commit subject scope keyword:** `project-only` (all edits under `project-template/`).

**Commit message:** `feat: v11 — BD-173 leak sweep Categories A + B — per-entry skeleton boundary cleanup (Batch 19c.9)`

**Rationale:** Single mechanical commit per fix-shape per the leak-sweep strategy doc §2.4. Per-entry skeletons share a tight file-set and uniform fix-shape; sequencing them together keeps the diff coherent for review.

### H.10 — Leak sweep Categories D + E + F (mechanical sweep — detect.sh + pm-startup cluster + boundary-investigation skill cite)

**Scope:** 8 leaks across 6 files. Category D (3 leaks): drop the cite entirely (detect.sh:335, detect.sh:678, PM-CHAT.md:410). Category E (4 leaks): pm-startup cluster sibling sweep — drop `ARCHITECTURE-V3.md §28.1.5` cite tail from 4 sibling files. Category F (1 leak): BD-175 self-leak — replace `AUDIT-USER-CURATION.md Override 1` cite with descriptive prose.

**Files modified (6 distinct files):**
- `scripts/lib/detect.sh` (2 cites dropped)
- `project-template/docs/pack/PM-CHAT.md` (1 cite dropped)
- `project-template/skills/pm-startup/SKILL.md` (cite tail dropped)
- `project-template/.claude/skills/pm-startup/SKILL.md` (cite tail dropped)
- `project-template/.codex/skills/pm-startup/SKILL.md` (cite tail dropped)
- `project-template/.gemini/commands/pm-startup.toml` (cite tail dropped)
- `project-template/skills/boundary-investigation/SKILL.md` (Category F — cite replaced with prose)

**Per-commit reviewer:** **REQUIRED INLINE — sliding-window scope per Decision 4 (α-sliding) 2026-05-22.** Reviews this commit's diff only (sliding window = H.10 alone; prior INLINE reviewer was H.9 covering H.6+H.7+H.9). Boundary-sensitive; reviewer verifies each cite removal preserves surrounding prose intelligibility; reviewer verifies the pm-startup cluster sibling sweep is byte-identical across the 4 sibling files where appropriate per pack-shipped distribution pattern; reviewer specifically checks boundary-investigation skill's replacement prose — the BD-175 self-leak fix must not re-introduce a different leak.

**RC9 manifest regen:** **REQUIRED** (`project-template/` + `scripts/` both in v11-surface).

**Commit subject scope keyword:** (mixed — no keyword; touches `project-template/` AND `scripts/`).

**Commit message:** `feat: v11 — BD-173 leak sweep Categories D + E + F — mechanical cite cleanup + BD-175 self-leak fix (Batch 19c.10)`

**Rationale:** Multiple file types (`.md`, `.sh`, `.toml`) — mechanical sweep across heterogeneous surfaces grouped by fix-shape ("drop the cite") + the BD-175 self-leak fix that is structurally identical (replace cite with prose). The pm-startup cluster sibling sweep closes 4 cites in one mechanical pass per leak-sweep strategy §1.5.

### H.11 — Leak sweep Category C — pm-chat variant rewrites (C-c direction)

**Scope:** 3 leaks. Rewrite 3 pm-chat self-prompt variants per user direction (C-c): manual-fallback, generate-setup, generate-agent-kickoff. Each variant currently requires a pre-install template file in `supporting-docs/` (SETUP-NEW.md, SETUP_TEMPLATE.md, AGENT_KICKOFF_TEMPLATE.md) NOT shipped to clients. Rewrite to use client-installed equivalents:

- **Manual-fallback variant** (currently cites `supporting-docs/SETUP-NEW.md` Manual fallback Steps 5.A-5.D): rewrite to cite `docs/pack/INSTALL-PROCEDURES.md` Procedure 7 (manual install equivalent) — which IS client-installed.
- **Generate-setup variant** (currently cites `supporting-docs/SETUP_TEMPLATE.md`): rewrite to inline the setup template content as prose, OR reference `docs/pack/SETUP-EXISTING.md` if it has equivalent content, OR rewrite the variant to construct a setup template from project trinity (CLAUDE.md / AGENTS.md / GEMINI.md) + METHODOLOGY.md inputs.
- **Generate-agent-kickoff variant** (currently cites `supporting-docs/AGENT_KICKOFF_TEMPLATE.md`): rewrite to inline the agent-kickoff template content as prose, OR reference project-side prompt files at `docs/pack/prompts/<agent>.md` for per-agent kickoff scaffolding.

**Files modified:**
- `project-template/docs/pack/prompts/pm-chat.md` (three variants rewritten)

**Per-commit reviewer:** **REQUIRED INLINE — sliding-window scope per Decision 4 (α-sliding) 2026-05-22.** Reviews this commit's diff only (sliding window = H.11 alone; prior INLINE reviewer was H.10 covering H.10). Boundary-sensitive; substantive content rewrite for 3 variants; reviewer verifies each variant's rewrite achieves the same user-facing contract — generating a setup, generating an agent-kickoff, completing manual fallback — without citing pre-install template files; reviewer also verifies no new leaks are introduced in the rewritten content.

**RC9 manifest regen:** **REQUIRED** (`project-template/` in v11-surface).

**Commit subject scope keyword:** `project-only` (single project-template file).

**Commit message:** `feat: v11 — BD-173 leak sweep Category C — pm-chat variant rewrites to client-side equivalents (Batch 19c.11)`

**Rationale:** Per leak-sweep strategy §1.3 + §5.2: Category C requires architect-level design rather than mechanical replacement. User direction is C-c (rewrite to client-side equivalents). The rewrite is contained to a single file (`pm-chat.md`) but is substantive — each variant's contract must be preserved through different mechanics. Per-commit reviewer is essential.


### H.12 — Guardrail 3 implementation (`_PROJECT_SIDE_ROOTS` scope expansion to client-installed surface)

**Scope:** Per `ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md` §3. Replace `_PROJECT_SIDE_ROOTS` constant (currently `("project-template",)` at validate-pack.py L3762) with `_iter_client_installed_files()` helper that returns the union of (a) all files under `project-template/` and (b) explicit non-project-template entries from `_CLIENT_INSTALLED_FILES` (parsed via Check 41's existing helper). Add Group 7 fixture-test cases to `scripts/tests/test-validate-pack-checks-36-37-38.sh`.

**Files modified:**
- `scripts/validate-pack.py`
- `scripts/tests/test-validate-pack-checks-36-37-38.sh`

**Per-commit reviewer:** SKIP (mechanical scope expansion; test coverage added; validate-pack.py PASSES at HEAD post-H.10 leak-sweep clearing leaks under detect.sh which would now be in scope).

**RC9 manifest regen:** **REQUIRED** (`scripts/` in v11-surface).

**Commit subject scope keyword:** `pack-only` (only `scripts/` edits).

**Commit message:** `feat: v11 — BD-173 Guardrail 3 — _PROJECT_SIDE_ROOTS expansion to full client-installed surface (Batch 19c.12)`

**Rationale:** Scope expansion is the foundation for Guardrails 1 + 2. Must land AFTER H.10 (Category D detect.sh fixes) — otherwise validate-pack.py FAILs at H.12 commit head because the expanded scope surfaces the pre-existing detect.sh leaks. Per the "self-validating change" principle in guardrails contract §3.3, the leak sweep must clear the existing leaks BEFORE scope expansion ratifies the cleaned state.

### H.13 — Guardrail 2 implementation (per-line exemption fence; Check 37 modification)

**Scope:** Per guardrails contract §2. Replace `_is_legitimate_deny_list_doc()` whole-file exemption with per-line `<!-- DENY-LIST-CONTENT-START -->` / `<!-- DENY-LIST-CONTENT-END -->` fence support. Place fence markers in 7 files (per `_CHECK_37_PER_LINE_FENCE_FILES` enumeration): boundary-investigation/SKILL.md, prompts/coder.md, prompts/reviewer.md, project-template trinity ×3, PM-CHAT.md. Add Group 6 fixture-test cases.

**Files modified:**
- `scripts/validate-pack.py`
- `project-template/skills/boundary-investigation/SKILL.md` (fence markers around Step 4 enumeration block)
- `project-template/docs/pack/prompts/coder.md` (fence markers around deny-list block at current L83-89 + L195-202)
- `project-template/docs/pack/prompts/reviewer.md` (fence markers around deny-list block at current L102-107)
- `project-template/CLAUDE.md` (fence markers around "Project SSOT-first" pack-only-files enumeration in `## Project memory`)
- `project-template/AGENTS.md` (parallel fence markers per project trinity rule)
- `project-template/GEMINI.md` (parallel fence markers per project trinity rule)
- `project-template/docs/pack/PM-CHAT.md` (if `_CHECK_37_PER_LINE_FENCE_FILES` includes per contract §2.3 — verify scope per coder)
- `scripts/tests/test-validate-pack-checks-36-37-38.sh` (Group 6 test cases)

**Per-commit reviewer:** **REQUIRED INLINE — sliding-window scope per Decision 4 (α-sliding) 2026-05-22.** Reviews the diff from the prior INLINE commit (H.11) through end of this commit — i.e., H.12 + H.13 (2 commits). Scope expands to include the H.12 Guardrail 3 `_PROJECT_SIDE_ROOTS` scope expansion + new validate-pack.py test cases in addition to this commit's fence work. Boundary-sensitive; touches project-side trinity AND prompts AND skill; reviewer verifies fence placement preserves intended exempt-content scope AND outside-fence content does NOT contain pack-internal cites — H.10 Category F should have cleared the boundary-investigation skill's `AUDIT-USER-CURATION.md` cite first; fence ratifies the cleaned state.

**RC9 manifest regen:** **REQUIRED** (`project-template/` + `scripts/` both in v11-surface).

**Commit subject scope keyword:** (mixed — no keyword; touches `project-template/` AND `scripts/`).

**Commit message:** `feat: v11 — BD-173 Guardrail 2 — per-line deny-list fence (Check 37 modification + 7 files fenced) (Batch 19c.13)`

**Rationale:** Per guardrails contract §5.1, Guardrail 2 must land AFTER H.10 (Category F removes the BD-175 self-leak from boundary-investigation/SKILL.md) — otherwise the fence would ratify a still-leaking state. Fence placement is mechanical once H.10 clears the cite.

### H.14 — Guardrail 1 implementation (Check 43 — project-side bare cross-reference scanner)

**Scope:** Per guardrails contract §1. Add `check_project_side_bare_internal_refs()` function in `scripts/validate-pack.py` reusing Check 40's basename-index + allowlist + anchor-phrases + code-block-stripping mechanism. Add `_CHECK_43_ALLOWLIST` constant (~25 entries per contract §1.4). Add new fixture test file `scripts/tests/test-validate-pack-check-43.sh` with 7 test groups + 13 fixture files under `scripts/tests/fixtures/project-side-refs/`. Wire the test in `.github/workflows/validate-pack.yml`.

**Files modified:**
- `scripts/validate-pack.py` (new Check 43 function + allowlist)
- `scripts/tests/test-validate-pack-check-43.sh` (NEW file)
- `scripts/tests/fixtures/project-side-refs/` (NEW directory with 13 fixture files: 7 FAIL + 5 PASS + 1 README per contract §1.10)
- `.github/workflows/validate-pack.yml` (single new test-invocation line per contract §1.11)

**Per-commit reviewer:** **REQUIRED INLINE — sliding-window scope per Decision 4 (α-sliding) 2026-05-22.** Reviews this commit's diff only (sliding window = H.14 alone; prior INLINE reviewer was H.13 covering H.12+H.13). NEW CI check; reviewer verifies the contract §1 implementation matches the spec — class-test allowlist; supporting-docs/ subset rule; FAIL-condition coverage; fixture-test enumeration; CI wiring.

**RC9 manifest regen:** **REQUIRED** (`scripts/` in v11-surface; `.github/workflows/` is NOT in RC9 trigger but `scripts/` change forces regen).

**Commit subject scope keyword:** (mixed — no keyword; touches `scripts/` AND `.github/`).

**Commit message:** `feat: v11 — BD-173 Guardrail 1 — Check 43 (project-side bare cross-reference scanner; V11 leak-sweep prevention) (Batch 19c.14)`

**Rationale:** Check 43 is the load-bearing addition per leak-sweep strategy §4.5 — catches all 36 leak classes mechanically. Per guardrails contract §5.1, Check 43 lands AFTER Guardrail 3 (H.12 provides `_iter_client_installed_files()`) AND AFTER Guardrail 2 (H.13 per-line fence interacts with Check 37 exemption logic; Check 43 has its own allowlist but the per-file scope coordination matters).

### H.15 — Guardrail 4 implementation (PREFLIGHT extension — pre-commit defense-in-depth)

**Scope:** Per guardrails contract §4. Extend pack-coder PREFLIGHT spec to include Check 43 verification step. Modifications:
- `pack-ops/PACK-AGENTS.md` PREFLIGHT spec (insert Check 43 line after the existing PREFLIGHT description per contract §4.1 anchor).
- Pack-root trinity (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md` at pack root) `## Pack memory` "Pack-coder PREFLIGHT + STOP-MEANS-STOP pattern" bullet — append the Check 43 verification step. Trinity rule applies (PREFLIGHT spec content is platform-neutral — same text in all three files; cross-CLI ENFORCEMENT mechanism is platform-conditional per pack-side existing wording).
- `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` dimension (d) extension per contract §4.2.
- (Pack Chat applies the memory-cache update separately per contract §4.3 — outside this commit; user-local file `feedback_pack_coder_preflight_pattern.md` lives outside the repo.)

**Files modified:**
- `pack-ops/PACK-AGENTS.md`
- `CLAUDE.md` (pack root)
- `AGENTS.md` (pack root)
- `GEMINI.md` (pack root)
- `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`

**Per-commit reviewer:** **REQUIRED INLINE — sliding-window scope per Decision 4 (α-sliding) 2026-05-22.** Reviews this commit's diff only (sliding window = H.15 alone; prior INLINE reviewer was H.14 covering H.14). Decision 4 (b) 2026-05-22 user-directed symmetric trinity coverage with H.4 — pack-root trinity edit warrants per-commit review by parity with project-template trinity edit; mechanical CI parity guards (Check 18 + 16 + 19 + 42) are necessary but reviewer also verifies PREFLIGHT contract fidelity + appropriate Check 43 wording across all three pack-root trinity files + PACK-AGENTS.md + CONCEPTUAL-REVIEW-METHODOLOGY.md.

**RC9 manifest regen:** **REQUIRED** (`pack-ops/` in v11-surface per BD-176 expansion; pack-root trinity is also in v11-surface — note: pack-root trinity is in `project-template/` only per RC9 directory list? No — pack-root trinity at `/CLAUDE.md` is NOT under `project-template/`; it lives at the pack repo root. Per BD-176 expansion, the v11-surface set is {project-template/, scripts/, pack-ops/, supporting-docs/}; pack-root trinity at the repo ROOT is NOT in this set by directory listing — BUT the pack-root trinity may be a fixture-affecting target if `test-fixtures/build.sh` reads it. Coder verifies before commit by running `bash test-fixtures/build.sh --all --clean` and inspecting the manifest diff; if non-empty, stage the manifest in the same commit; if empty, the trinity edit didn't affect fixtures.).

**Commit subject scope keyword:** `PM-only` (PACK-AGENTS.md + pack-root trinity + pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md are all PM-only files per `CLAUDE.md` § "Rules for agents working on this repo" "PM-only files and directories" list).

**Commit message:** `feat: v11 — BD-173 Guardrail 4 — pack-coder PREFLIGHT extension (Check 43 verification step) (Batch 19c.15)`

**Rationale:** Per guardrails contract §5.1, Guardrail 4 lands AFTER Guardrail 1 (Check 43 exists for PREFLIGHT to invoke). PM-only commit per contract §4.4 trinity rule application notes.

### H.16 — D-11 PM-chat omniscience principle landing (METHODOLOGY.md Part 1 NEW sub-section) + V2 §D.7 OT-UT-1 paragraph

**Scope:** Per V2 §D.6 + V2 §D.7. Two related METHODOLOGY.md Part 1 edits:

1. **D-11 principle landing.** Insert NEW sub-section "PM chat omniscience obligation" in `supporting-docs/METHODOLOGY.md` `## Part 1 — Tool Roles` immediately after the existing "Separation rule" sub-section (V1 cited L98; coder verifies at HEAD). Full text per V2 §D.6.2.

2. **OT-UT-1 informational paragraph (per V2 §D.7.3).** Insert a `>` callout paragraph in the existing `### Claude Code CLI (agents)` sub-section after the existing bullet list of Claude Code CLI capabilities (V1 cited L83 area; coder verifies). Full text per V2 §D.7.3.

**Files modified:**
- `supporting-docs/METHODOLOGY.md`

**Per-commit reviewer:** **REQUIRED INLINE — sliding-window scope per Decision 4 (α-sliding) 2026-05-22.** Reviews this commit's diff only (sliding window = H.16 alone; prior INLINE reviewer was H.15 covering H.15). Substantive methodology addition; D-11 principle is the load-bearing architectural principle for V2; reviewer verifies the principle wording does NOT cite pack-side memory entries — salvageability B9 — and verifies the OT-UT-1 paragraph names all three CLIs per BD-182 §4.1 cross-CLI canonical pattern for shared documents.

**RC9 manifest regen:** **REQUIRED** (`supporting-docs/` in v11-surface).

**Commit subject scope keyword:** `project-only` (single supporting-docs/ file; project-side content).

**Commit message:** `feat: v11 — BD-173 METHODOLOGY.md Part 1 — PM chat omniscience principle + Claude Code Agent Teams operating note (Batch 19c.16)`

**Rationale:** The principle is the foundational architecture decision that subordinates §D.2 (V2 H.5 placement rule lands as subsidiary). The OT-UT-1 paragraph captures the Claude-only operating convention without introducing project-template trinity asymmetry (per V2 §D.7). Both edits live in METHODOLOGY.md Part 1 and naturally group together as "Part 1 enhancements."

**Ordering rationale:** H.16 lands AFTER the leak sweep (H.9-H.11) and AFTER the guardrails (H.12-H.15) because:
- The principle's cascade has already been APPLIED throughout V2's §C placements (via §C.0 cascade summary) — the principle text is the LAST-LANDING ratification of work already done.
- §D.2 placement rule subsidiary text (V2 H.5) is already in the methodology; H.16 lands the parent principle that the subsidiary references back to. This ordering creates a brief forward-pointing reference in H.5 (subsidiary rule references the principle that doesn't yet exist) — acceptable for one inter-commit forward reference within the same batch; H.16's content resolves the forward pointer.
- Alternative ordering (land H.16 first; then H.5 subsidiary) was considered: it creates a tidier forward-reference shape (the subsidiary always references an already-landed principle), but it splits the METHODOLOGY.md Part 1 + Part 9 edits across the batch, making the cascade harder to reason about. V2 chooses the trade-off in favor of preserving the per-commit content cohesion (H.5 = METHODOLOGY.md substantive procedural additions; H.16 = METHODOLOGY.md Part 1 principle + Claude-only operating note).

### H.17 — End-of-batch reviewer + BD-173 status flip

**Scope:**
1. Run `pack-reviewer` on the full batch diff (HEAD at H.0 baseline → HEAD at end of H.16).
2. Triage findings per Pack Chat protocol (default fix-all per `feedback_fix_all_review_findings`).
3. Apply fix-coder if findings exist.
4. Per single-BD batch close commit shape: COMBINE the fix commit and the BD-173 status flip into ONE final commit per `pack-ops/PACK-CHAT.md` `## Behavioral rules` "Batch close commit shapes" rule.
5. If no fix findings: ship the BD-173 status flip as a standalone `docs: v11 — flip BD-173 to Resolved` commit.

**Reviewer scope:** Full batch diff covers ~17 commits (H.1-H.16). Reviewer dimensions per `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`. Dimension (d) Pack rule adherence MUST verify Check 43 PASSES against the working tree post-H.14 (Guardrail 1 + leak sweep should produce a clean validate-pack run).

**RC9 manifest regen:** Required if fix-commit modifies any v11-surface file. Pack Chat verifies before staging.

**BD-173 status flip:** Per `pack-ops/BACKLOG.md` BD-173 entry, mark `Status: Open` → `Status: Resolved`; fill the `Resolved:` line with date + batch close commit SHA + summary of work delivered (per V2 scope: 17-item OT memory promotion + 36-leak boundary sweep + 4 guardrails + D-11 PM-chat omniscience principle + ~7 V2 word-level cleanups).

**Commit subject scope keyword:** (commit-shape-dependent — if combined fix + status flip, use no keyword (mixed); if standalone status flip on `pack-ops/BACKLOG.md` only, `PM-only`).

**Commit message:**
- If combined fix + status flip: `fix: v11 — BD-173 broad batch review/fix + status flip (Batch 19c)`
- If standalone status flip: `docs: v11 — flip BD-173 to Resolved`

**Note on V1 H.8 manifest regen footnote:** V1 H.8 incorrectly stated "supporting-docs/METHODOLOGY.md is NOT v11-surface." Per BD-176 expansion (2026-05-19), supporting-docs/ IS v11-surface. V2 H.17 reflects the updated rule — every METHODOLOGY.md-touching commit in V2 (H.1, H.2, H.5, H.6, H.16) requires manifest regen, as do every project-template/-touching commit (H.2, H.3, H.4, H.7, H.9, H.10, H.11, H.13) and every scripts/-touching commit (H.10, H.12, H.14) and every pack-ops/-touching commit (H.15).

---


## §I — Summary table (V2 — every item with disposition)

This table is the planner's lookup index. Each row names the source (OT-item, leak category, guardrail, or principle), the V2 commit it lands in, the target file(s), the V2 verdict, and whether RC9 manifest regen fires for the landing commit.

| Source | V2 commit | Target file(s) | V2 verdict | RC9 fires? | Per-commit reviewer? |
|---|---|---|---|---|---|
| OT-T-1 PM-CHAT.md half (always-reviewer-after-coder) | H.2 | PM-CHAT.md | UNCHANGED | YES | covered by H.4 |
| OT-T-1 METHODOLOGY.md half (cycle invariant callout) | H.1 | METHODOLOGY.md | UNCHANGED | YES (post-BD-176) | covered by H.4 |
| OT-T-2 (architect-trigger surface-even-mechanical) | H.1 | METHODOLOGY.md | UNCHANGED | YES | covered by H.4 |
| OT-T-3 (BACKLOG-between-phases proactive) | H.6 | METHODOLOGY.md | UNCHANGED (LAND per D-3) | YES | covered by H.9 |
| OT-T-4 PM-CHAT.md half (closeout-sequence) | H.2 | PM-CHAT.md | UNCHANGED | YES | covered by H.4 |
| OT-T-4 METHODOLOGY.md cross-ref (D-5) | H.2 | METHODOLOGY.md | UNCHANGED | YES | covered by H.4 |
| OT-T-5 (no-chained-git-add — STRENGTHEN "Source file edits") | H.3 | PM-CHAT.md | UNCHANGED | YES | covered by H.4 |
| OT-T-6 PM-CHAT.md half (PM-chat-never-edits-source) | H.3 | PM-CHAT.md | UNCHANGED | YES | covered by H.4 |
| OT-T-6 trinity half (destructive-ops list `git checkout --` extension) | H.4 | project-template/ trinity ×3 | REVISED-WORDING (BD-178 baseline; defense-in-depth exception per §D.6.3) | YES | **INLINE (sliding from H.1)** |
| OT-T-7 (re-read per-agent prompt file + REPORT FILE verify) | H.2 | PM-CHAT.md | UNCHANGED placement; REFRAME-DELIVERY via PM-chat injection | YES | covered by H.4 |
| OT-UT-1 (Agent Teams stage lifecycle) | H.16 | METHODOLOGY.md Part 1 (Claude Code CLI sub-section) | REVISED-PLACEMENT per V2 §D.7 (NOT in trinity; informational paragraph in METHODOLOGY) | YES | INLINE (this commit only) |
| OT-UT-2 (pack-repo-is-read-only) | H.2 | PM-CHAT.md | REVISED-WORDING per V2 §C.8 (drop "supporting-docs/" example + "Pack Chat" cite) | YES | covered by H.4 |
| OT-UT-3 (mid-pipeline working-tree intentional) | H.2 | PM-CHAT.md | UNCHANGED | YES | covered by H.4 |
| OT-UT-4 (OPEN TDs in scope) | (none — OOS) | (none) | UNCHANGED OOS | n/a | n/a |
| OT-UT-5 (Phase 58b deferred) | (none — OOS) | (none) | UNCHANGED OOS | n/a | n/a |
| OT-UT-6 PM-CHAT.md half (architect-output user-reads) | H.2 | PM-CHAT.md | REVISED-WORDING per V2 §C.10 (drop pack-side cross-cite + add §C.13 sibling annotation per user direction 2026-05-23) | YES | covered by H.4 |
| OT-UT-6 METHODOLOGY.md half (Workflow 4 step 4 STRENGTHEN) | H.1 | METHODOLOGY.md | UNCHANGED | YES | covered by H.4 |
| OT-UT-7 (feature prioritization deferred) | (none — OOS) | (none) | UNCHANGED OOS | n/a | n/a |
| OT-UT-8 meta (open-questions surface) | H.2 | PM-CHAT.md | REVISED-WORDING per V2 §C.11 (add §C.13 sibling annotation per user direction 2026-05-23) | YES | covered by H.4 |
| **NEW (V2)** — Decision presentation protocol (§C.13) | H.2 | PM-CHAT.md | NEW per user direction 2026-05-23 | YES | covered by H.4 |
| OT-UT-8 specifics (cadence/concurrency) | (none — OOS) | (none) | UNCHANGED OOS | n/a | n/a |
| OT-UT-9 (subsumed by OT-T-7) | H.2 | PM-CHAT.md | UNCHANGED (via OT-T-7) | YES | covered by H.4 |
| OT-UT-10 (/tmp reports ephemeral) | H.5 | METHODOLOGY.md Part 9 | REVISED-WORDING per V2 §C.12 ("Pack Chat" → "PACK-FEEDBACK.md per Part 10") | YES | INLINE (this commit only) |
| OT PM gap A (mid-phase planner P-A/P-B/P-C) | H.5 | METHODOLOGY.md Workflow 4 (new sub-section) | UNCHANGED (LAND per D-6) | YES | INLINE (this commit only) |
| OT PM gap B (closeout elevation) | (combined with OT-T-4) | (see OT-T-4) | UNCHANGED | (see OT-T-4) | (see OT-T-4) |
| OT PM gap C (cycle-termination) | H.1 | METHODOLOGY.md | UNCHANGED (LAND per D-5) | YES | covered by H.4 |
| Arch derived 1 (rule placement: trinity vs PM-CHAT.md vs METHODOLOGY.md) | H.5 | METHODOLOGY.md Part 9 (new sub-section) | REVISED-PLACEMENT per V2 §D.2 (SUBSIDIARY of D-11 principle) | YES | INLINE (this commit only) |
| Arch derived 2 (per-project Claude memory cache convention) | H.7 | PM-CHAT.md "Tool-specific: Claude Code CLI" | REVISED-WORDING per V2 §D.1 (drop "Tier 1.5" + "pack memory" cross-cites) | YES | covered by H.9 |
| **NEW (V2)** — D-11 PM-chat omniscience principle | H.16 | METHODOLOGY.md Part 1 (new sub-section) | NEW per V2 §D.6 | YES | INLINE (this commit only) |
| **NEW (V2)** — Leak sweep Category A+B per-entry skeletons | H.9 | 7 per-entry skeleton files under project-template/docs/project/ | NEW | YES | INLINE (sliding from H.6) |
| **NEW (V2)** — Leak sweep Category D+E+F mechanical sweep | H.10 | scripts/lib/detect.sh + PM-CHAT.md + 4 pm-startup cluster files + boundary-investigation/SKILL.md | NEW | YES | INLINE (this commit only) |
| **NEW (V2)** — Leak sweep Category C pm-chat variants rewrite | H.11 | prompts/pm-chat.md | NEW (per user C-c) | YES | INLINE (this commit only) |
| **NEW (V2)** — Guardrail 3 scope expansion (`_iter_client_installed_files`) | H.12 | scripts/validate-pack.py + scripts/tests/ | NEW | YES | covered by H.13 |
| **NEW (V2)** — Guardrail 2 per-line fence (Check 37 mod + 7 fenced files) | H.13 | scripts/validate-pack.py + 7 project-template/ files + scripts/tests/ | NEW | YES | INLINE (sliding from H.12) |
| **NEW (V2)** — Guardrail 1 Check 43 (project-side bare-cross-ref scanner) | H.14 | scripts/validate-pack.py + scripts/tests/test-validate-pack-check-43.sh (NEW) + scripts/tests/fixtures/project-side-refs/ (NEW) + .github/workflows/validate-pack.yml | NEW | YES | INLINE (this commit only) |
| **NEW (V2)** — Guardrail 4 PREFLIGHT extension (Check 43 verification) | H.15 | pack-ops/PACK-AGENTS.md + pack-root trinity ×3 + pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md (+ memory cache via Pack Chat direct edit, outside commit) | NEW | YES | INLINE (this commit only) |
| End-of-batch reviewer + BD-173 status flip | H.17 | (review pass; status flip in pack-ops/BACKLOG.md) | NEW (replaces V1 H.8) | possible (depends on fix-commit content) | n/a |

**Net commit count:** 16 implementation commits (H.1-H.16) + 1 review/close commit (H.17) = 17 commits.

**Net per-commit reviewer breakdown:**
- INLINE reviewer commits (sliding-window per Decision 4 (α-sliding) 2026-05-22): H.4 (covers H.1-H.4), H.5 (covers H.5), H.9 (covers H.6+H.7+H.9), H.10 (covers H.10), H.11 (covers H.11), H.13 (covers H.12+H.13), H.14 (covers H.14), H.15 (covers H.15), H.16 (covers H.16) — **9 sliding-window passes covering all 16 implementation commits with no gaps before H.17**.
- End-of-batch reviewer: H.17 — 1 pass over full batch diff (H.0 → end of H.16) as backstop.

**Total reviewer passes = 9 sliding-window INLINE + 1 END-OF-BATCH = 10 passes total. Every implementation commit is reviewed at least once before H.17; H.17 provides cross-cutting integration coverage.** Each INLINE pass triggers a potential fix-coder cycle (default fix-all per Pack Chat protocol; user triages per finding); the end-of-batch pass covers the cumulative batch state.

---

## §J — Batch 19b parity check (V1 §J carried; V2 augmentations noted)

V1 §J.1-J.6 axes are preserved. V2 augments where post-BD-175 work creates new parity considerations.

### J.1 — Trinity-first / single-tier-of-truth design (UNCHANGED FROM V1)

Trinity (project-template/ CLAUDE.md / AGENTS.md / GEMINI.md) is the authoritative project-team surface; PM-CHAT.md is the authoritative PM-chat orchestration surface; METHODOLOGY.md is the authoritative methodology reference; per-project Claude memory cache is an OPTIONAL Tier 1.5 convenience pointer (per V2 §D.1; convention only). **No conflict.**

### J.2 — Pack-side vs project-side rule separation (REINFORCED post-BD-175)

V2 absorbs the leak sweep + guardrails in addition to V1's OT cleanup scope. The guardrails specifically target the project-side / pack-side boundary (Check 43 is a project-side bare-cross-ref scanner enforcing the very rule this section codifies). The pack-side surfaces explicitly out of scope:
- Pack-root trinity (`/CLAUDE.md`, `/AGENTS.md`, `/GEMINI.md`) — **EXCEPT** H.15 Guardrail 4 trinity edit (the PREFLIGHT spec is platform-neutral content the pack-root trinity already houses; H.15 appends to the existing PREFLIGHT bullet per project trinity rule; this is the ONE pack-root trinity touchpoint in V2).
- `pack-ops/PACK-CHAT.md`, `pack-ops/PACK-AGENTS.md`, `pack-ops/BOUNDARY-DEFINITION.md`, all other `pack-ops/` files — **EXCEPT** H.15 (PACK-AGENTS.md PREFLIGHT spec edit) and H.15 (`pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` dimension (d) extension).
- `scripts/` general scripts — **EXCEPT** H.10 (Category D detect.sh cleanup), H.12 (Guardrail 3 in validate-pack.py), H.14 (Guardrail 1 Check 43 in validate-pack.py + new test file).
- `maintenance-docs/` — pack-internal authoring artifacts; V2 itself lives here.

**No conflict** — the pack-side touchpoints are explicit, scoped (PREFLIGHT spec, guardrail implementations, methodology dimension addition), and have user-approved direction (Option b absorb sweep + guardrails into Batch 19c).

### J.3 — Mechanical-edit-vs-structural-change threshold (V2 augments)

V1's posture was "no new H3 sub-sections in trinity `## Project memory`" (structural change avoidance). V2 maintains this posture:
- H.4 trinity STRENGTHEN extends an EXISTING bullet's named list (no new H3, no new bullet).
- H.13 trinity fence-marker placement is a mechanical edit to existing content (no semantic change to the rule text).
- V2 §D.7 explicitly DROPS V1's CONDITIONAL H.7 (Claude-only sub-section) — no new H3.

V2 ADDS METHODOLOGY.md substantive additions (H.1, H.5, H.16) — these ARE structural (new sub-sections in Part 1 and Workflow 4 and Part 9). METHODOLOGY.md is the appropriate surface for procedural / principle additions per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` §3.

**Post-BD-175 augmentation:** BD-181 + BD-183 + BD-184 strengthened the CI parity guards (Check 18 / 16 / 19 extended to pack-root; Check 42 wires per-check tests). V2 trinity edits (H.4, H.13, H.15 pack-root) respect these guards: H.4 preserves byte-identical content across project-template trinity; H.13 places fences identically across project-template trinity ×3 + parallel marker placement in PM-CHAT.md / prompts (per Guardrail 2 §2.4 plan); H.15 pack-root trinity edits respect Override 9 (per-CLI ENFORCEMENT mechanism differs in the existing PREFLIGHT bullet; V2 appends Check 43 verification as platform-neutral content to the same bullet, NOT diverging per-CLI).

**No conflict.**

### J.4 — Single-BD batch close commit shape (UNCHANGED FROM V1)

Batch 19c is a single-BD batch (BD-173 only). Per `pack-ops/PACK-CHAT.md` `## Behavioral rules` "Batch close commit shapes" rule, single-BD batches combine the fix commit and the status flip into ONE final commit. V2 H.17 follows this shape.

**No conflict.**

### J.5 — Researcher-first pipeline (V2 OBSERVATION)

V1 anticipated a `pack-docs-researcher` pass between V1 and V2. The G-1..G-9 research was completed (per `RESEARCH-19C-G-ITEMS-VERIFICATIONS.md`); the salvageability + leak-audit + leak-sweep-strategy + guardrails-contract passes were architect-passes (not researcher passes) — substantive but not requiring external CLI verification beyond what G-1..G-9 already covered. V2 is the final architect pass; planner runs next.

**No conflict.** The pipeline order (researcher → architect → planner → coder) is preserved.

### J.6 — Per-BD review/fix inline vs end-of-batch (V2 REVISED PER POST-BD-175 DEFAULT)

V1 §F D-10 recommended END-OF-BATCH ONLY for the single-BD batch. V2 §F D-10 resolution: HYBRID — INLINE for trinity / boundary-sensitive commits (H.4, H.5, H.9, H.10, H.11, H.13, H.14, H.15, H.16); END-OF-BATCH for non-boundary-sensitive commits + the cumulative batch surface (H.17).

**Augmentation rationale:** Post-BD-175 per-BD-INLINE review pattern is the default for trinity-touching and boundary-sensitive work. The hybrid is conservative — boundary-sensitive commits get inline coverage to catch leak regressions before they stack, AND the end-of-batch reviewer covers cross-cutting concerns the per-commit reviewers might miss.

**Sliding-window refinement (Decision 4 (α-sliding) 2026-05-22):** Each INLINE reviewer's scope is the diff from the prior INLINE commit (or H.0 baseline) through end of its own commit, NOT just its own commit's diff. This ensures the 6 commits marked `covered by H.N` (H.1, H.2, H.3, H.6, H.7, H.12) are reviewed before H.17 rather than only at end-of-batch — closes the gap between per-BD-INLINE intent and per-commit coverage. Coverage windows: H.4 covers H.1-H.4 (4 commits); H.5 covers H.5 only; H.9 covers H.6+H.7+H.9 (3 commits); H.10/H.11/H.14/H.15/H.16 each cover own diff only; H.13 covers H.12+H.13 (2 commits). H.17 end-of-batch reviewer remains as backstop for cross-cutting integration.

**No conflict** with Batch 19b precedent — Batch 19b was multi-BD and ran per-BD inline reviews per the same default. V2 applies the default to V2's boundary-sensitive commits.

---


## §K — Risk surface (V1 §K.1-K.6 carried + V2 K.7-K.9 introduced by V2 integration)

### K.1 — Risk: V2 placement decisions diverge from a future re-architecture (UNCHANGED FROM V1)

**Likelihood:** Low. V2 integrates V1 + PRINCIPLE-CHECK + salvageability + leak-audit + leak-sweep-strategy + guardrails-contract. The placements have been independently re-evaluated by multiple architect passes and converged.

**Impact:** Per-item adjustment if a future BD finds a better placement.

**Mitigation:** V2 §I summary table documents every placement; future re-architecture has a single lookup index.

### K.2 — Risk: Pack-source state changes invalidate insertion anchors (V1 §K.2 carried; V2 augments)

**Likelihood:** Low-Medium. V1's line-number anchors are 4 days old (V1: 2026-05-17; V2: 2026-05-21). Multiple intervening BDs (BD-175..BD-184 + BD-179 in-flight) have touched PM-CHAT.md, METHODOLOGY.md, project-template trinity, scripts/, pack-ops/.

**Impact:** Coder must verify anchors at commit time using fresh reads, NOT V1's recorded line numbers.

**Mitigation:** Salvageability §C.4 explicitly verified V1's PM-CHAT.md "Source file edits" anchor still resolves at HEAD; salvageability §C.6 flagged BD-178 trinity baseline alignment; V2 §C.5 BEFORE text re-verified against current HEAD. Coder reads each target file fresh at commit time and adjusts insertion anchor to the current text neighborhood.

### K.3 — Risk: Trinity STRENGTHEN (§C.6 `git checkout --` extension) ripples to agent-file destructive-ops lists (UNCHANGED FROM V1)

**Likelihood:** Low. The trinity STRENGTHEN extends an existing bullet's named list.

**Impact:** If a ripple appears (e.g., an agent definition file's git-verb prohibition list needs the same extension), a separate edit lands in a follow-up commit or new BD.

**Mitigation:** V2 §E.4 explicitly excludes agent-file content changes. If V2 reviewer (H.4 inline or H.17 end-of-batch) identifies an agent-file change as required, surface as a new BD per Pack Chat triage protocol.

### K.4 — Risk: PM-CHAT.md grows beyond maintainable size (V1 §K.4 carried; V2 augments)

**Likelihood:** Medium. V1 estimated ~80-100 lines added; V2 confirms this scope (~7 new bullets + 1 STRENGTHEN to "Source file edits" + 1 new paragraph in "Tool-specific: Claude Code CLI" section). PM-CHAT.md ends up ~870-900 lines — within reasonable PM-chat-startup read budget.

**Impact:** PM-CHAT.md becomes harder to scan; PM chat may take longer to load at startup.

**Mitigation:** Per V1 §K.4. If size becomes a concern, a future cleanup batch may split PM-CHAT.md by topic — OUT of Batch 19c scope.

### K.5 — Risk: Trinity files diverge across CLAUDE/AGENTS/GEMINI (V1 §K.5 carried)

**Likelihood:** Low. The only trinity-content edit is §C.6 STRENGTHEN (applied symmetrically across all three files). H.13 places fence markers symmetrically; H.15 pack-root trinity edits are PREFLIGHT spec content (platform-neutral per existing bullet structure).

**Impact:** Trinity-rule violation in commit if coder fails to apply edits identically across all three files; CI Check 18 would FAIL.

**Mitigation:** Per-commit reviewer on H.4 and H.13 + end-of-batch reviewer on H.17. CI Check 18 H2 parity catches at PR.

### K.6 — Risk: OT project consumes the rules and finds them duplicative or conflicting (V1 §K.6 carried)

**Likelihood:** Low. OT memories ARE the OT-side equivalent of the §C bullets; post-V2 they become Tier 1.5 pointers to project-template surface.

**Impact:** Possible cognitive overhead for OT PM chat reading the same rule twice.

**Mitigation:** Per V1 §K.6. Tier 1.5 design (per V2 §D.1) is pure pointers; convergence with project-template surface is automatic.

### K.7 — NEW V2 RISK: Scope expansion via leak-sweep + guardrails absorption violates `feedback_deferral_is_scope_creep`

**Likelihood:** LOW — surfaced and explicitly mitigated by user direction. Per leak-sweep strategy doc §2.4 + §5.4, the user explicitly chose Option (b) — absorb sweep into Batch 19c — citing the size/blocked/fit defense: the sweep's "fit" with Batch 19c is concrete same-file-set fit (PM-CHAT.md, prompts/pm-chat.md, project-template trinity overlap §C and the leak sweep). The guardrails absorption follows the same logic — they prevent recurrence of the very leak class being swept.

**Impact:** Batch 19c grows from V1's 8 commits to V2's 17 commits. End-of-batch reviewer scope is substantial but bounded by the per-commit inline reviewers firing on every boundary-sensitive commit.

**Mitigation:** Per-commit inline reviewer on H.4, H.5, H.9, H.10, H.11, H.13, H.14, H.15, H.16 catches per-commit issues before they stack. End-of-batch reviewer on H.17 covers cross-cutting concerns. The deferral-is-scope-creep rule cuts both ways here: deferring 36 already-identified leaks behind a new BD-185 pipeline would be a worse violation (per leak-sweep strategy §2.4 + §5.4). The user's Option (b) decision is the documented defense.

Per Decision 4 (α-sliding) 2026-05-22, each INLINE reviewer covers a sliding window (prior INLINE or H.0 → current commit), so SKIP-per-commit commits H.1/H.2/H.3 (covered by H.4), H.6/H.7 (covered by H.9), H.12 (covered by H.13) are reviewed before H.17 — no gaps in pre-H.17 coverage.

### K.8 — NEW V2 RISK: Guardrail 4 PREFLIGHT extension requires PM-only edits to pack-side surfaces from a single-BD batch

**Likelihood:** LOW. H.15 is the only pack-side surface edit in V2 (excluding the validate-pack.py + scripts/tests/ work in H.12 + H.14 which are pack-only by surface but mechanically scoped). The PM-only commit shape is well-established per `CLAUDE.md` § "PM-only files and directories" list.

**Impact:** If Pack Chat applies the H.15 edits directly (per "What Pack Chat CAN edit directly" rule), no agent involvement; if a pack-coder is spawned, the coder must verify PM-only scope boundaries (only PACK-AGENTS.md / pack-root trinity / CONCEPTUAL-REVIEW-METHODOLOGY.md touched; no project-side touchpoints).

**Mitigation:** H.15 commit subject uses `PM-only` scope keyword per CI Check 36 (which enforces PM-only commits don't touch project-side files). Coder/Pack Chat verifies before commit.

### K.9 — NEW V2 RISK: D-11 principle landing in METHODOLOGY.md Part 1 creates downstream documentation evolution pressure

**Likelihood:** Medium (foreseeable). The PM-chat omniscience principle is a foundational architectural claim; once landed, future cleanup batches will be measured against it, and the documented exceptions (defense-in-depth, cross-CLI parity ergonomics) will need maintenance as the pack evolves.

**Impact:** Future cleanup batches may need to revisit existing duplications across trinity / PM-CHAT.md / agent files (per V2 §D.6.3 worked-example: 16 agents × 3 CLIs duplicating "No state-changing git operations"). Each consolidation is its own BD with architect / planner / coder cycle.

**Mitigation:** V2 explicitly does NOT consolidate pre-existing duplications. The principle text in V2 §D.6.2 names the two exceptions and clarifies that pre-existing duplications stay unless a cleanup batch is scheduled. Future BDs are scoped per `pack-ops/BACKLOG.md` planning conventions; no immediate v11.0 work depends on consolidation.

---

## §L — Success-criteria self-check (V1 §L augmented for V2)

| Success criterion | V2 status | Cite |
|---|---|---|
| 1. Every rule in OT memory dump is categorized (no TBD items) | YES — 17 items + 5 architect-derived rows = 22 row inventory carried from V1 §B and verified by V2 §B.1 | §B.1 + V1 §A.3 + V1 §B |
| 2. Per-item disposition table covers every placement candidate with exact target + insertion anchor | YES — V2 §C.1-§C.12 BEFORE/AFTER text + V2 §I summary table | §C + §I |
| 3. Open questions are resolved (V2 has NO open questions) | YES — V2 §F closes all 11 V1 questions (D-1..D-10 + D-11) | §F |
| 4. Placement decisions name exact files + sections | YES — every V2 §C placement names file + section + insertion anchor + edit type | §C |
| 5. Research-need flags are confirmed (G-1..G-9 verdicts) | YES — all 9 G verdicts reconfirmed per V2 §G | §G + salvageability §5 + research doc |
| 6. Commit sequencing has realistic granularity | YES — 17 commits with rule-grouping; INLINE reviewer on 9 boundary-sensitive commits; END-OF-BATCH on H.17 | §H |
| 7. Out-of-scope items are explicit and rationale-justified | YES — V1 §E carried verbatim + V2 §E.6 caveat for in-scope absorbed work | §E |
| 8. OT PM's flagged gaps are addressed (YES/NO/RESEARCH per item) | YES — D-3 LAND, D-5 LAND, D-6 LAND (CONDITIONAL flags closed per V2 §B.1) | §C.3 + §D.3 + §D.4 + §C.4/§D.5 combined |
| 9. Leak sweep absorbed with category-distinct fix-shapes | YES — Categories A+B in H.9, D+E+F in H.10, C-c in H.11 per V2 §H | §B.2 + §H.9-H.11 |
| 10. Guardrails implementation-ready per contract | YES — G3 H.12, G2 H.13, G1 H.14, G4 H.15 per guardrails contract doc | §B.3 + §H.12-H.15 + ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md |
| 11. D-11 PM-chat omniscience principle text drafted | YES — V2 §D.6.2 full prose text for METHODOLOGY.md Part 1 sub-section + V2 §D.6.3 documented exceptions | §D.6 + §H.16 |
| 12. D-1 disposition with rationale | YES — V2 §D.7 NO with three strengthened post-BD-175 considerations + OT-UT-1 alternative placement | §D.7 + §H.16 |
| 13. RC9 attachment per commit per BD-176 4-directory trigger | YES — V2 §H every commit explicitly notes RC9 status; V2 §I summary table includes RC9 fires? column | §H + §I |
| 14. Cross-CLI references respect BD-182 §4.1 canonical table | YES — V2 §C.6 explicitly notes Override 9 non-applicability (platform-neutral git verb); V2 §D.7.3 explicitly notes TOOL-NEUTRAL enumeration pattern for the METHODOLOGY paragraph naming all 3 CLIs; H.15 pack-root trinity edits respect existing per-CLI ENFORCEMENT divergence | §C.6 + §D.7.3 + §H.15 |
| 15. Per-BD INLINE reviewer default applied to boundary-sensitive commits | YES — V2 §F D-10 resolution + V2 §H per-commit reviewer assignments | §F + §H |
| 16. Word-level cleanups applied (not deferred to coder) | YES — V2 §C.6 (BD-178 baseline), §C.8 (drop pack-repo example), §C.10 (drop pack-side cross-cite), §C.12 (Pack Chat → PACK-FEEDBACK.md), §D.1 (drop Tier 1.5 + pack memory cross-cites) | §C.6, §C.8, §C.10, §C.12, §D.1 |
| 17. Doc structure is well-organized | YES — V2 §A-§L per user prompt + V2 §M architect-review gate omitted (V2 has NO open questions; gate handoff moves directly to planner) | §A-§L |
| 18. §C.13 user-articulated decision protocol absorbed | YES — V2 §C.13 PM-CHAT.md bullet drafted per user direction 2026-05-23; lands in commit H.2; §B.1 + §I + §C.0 + §H.2 updated; §C.10 + §C.11 sibling annotations added | §C.13 + §B.1 + §I + §C.0 + §H.2 |


---

## §M — Planner consumption handoff (V2 → planner)

V2 is implementation-ready. The planner pass produces the per-commit ordered task list with exact file paths, content diffs, verification commands, and per-commit checklists. V2 does not need a further architect pass before the planner.

### M.1 — Planner inputs

- V2 itself (`ARCHITECTURE-CLEANUP-BATCH-19C-V2.md` — this doc).
- `ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md` — full guardrail implementation contracts for H.12, H.13, H.14, H.15.
- `AUDIT-PRE-19C-BOUNDARY-LEAKS.md` §1.19 + §2 — full per-file leak inventory for H.9, H.10, H.11 fixture-spec validation.
- `ARCHITECTURE-V11-LEAK-SWEEP-STRATEGY.md` §1 — per-category fix-shape spec for H.9, H.10, H.11.
- `pack-ops/BOUNDARY-DEFINITION.md` — boundary classification authority (for any planner-time boundary verification).
- `pack-ops/PACK-AGENTS.md` PREFLIGHT + reviewer dimensions — for H.15 implementation contract reference.
- `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` — reviewer dimensions; for H.17 end-of-batch reviewer prompt construction.
- Current HEAD of every file V2 targets — planner verifies insertion anchors against fresh HEAD.

### M.2 — Planner output

The planner produces (per `pack-ops/PACK-CHAT.md` + `pack-ops/PACK-AGENTS.md` planner spec):
- Per-commit task list with exact file paths and content diffs.
- Verification commands per commit (e.g., `python3 scripts/validate-pack.py` for H.12/H.13/H.14; `bash test-fixtures/build.sh --all --clean && git diff test-fixtures/manifest.txt` for RC9-trigger verification; `bash scripts/tests/test-validate-pack-check-43.sh` for H.14).
- Per-commit reviewer scope (which dimensions apply per `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`).
- End-of-batch reviewer scope.
- Manifest-regen step assignments per commit (already enumerated in V2 §H and §I; planner verifies and assigns to the per-commit task list).
- Per-commit checklist for pack-coder.

### M.3 — Pack-coder consumption (after planner approves)

After planner output lands and user approves, a FRESH pack-coder per commit applies the planner's task list mechanically. Each coder PREFLIGHT line confirms in-scope edits complete + verification PASS + HEAD SHA before writing the IMPL-REPORT. The PREFLIGHT verification step includes Check 43 PASS for any commit touching project-template/, pack-ops/, supporting-docs/, or scripts/ (per H.15 PREFLIGHT extension; for commits H.1-H.14 that land BEFORE H.15, the Check 43 PREFLIGHT step is forward-compatible — the coder can run validate-pack.py manually; for commits H.15-H.17 the PREFLIGHT step is canonical).

Each coder writes IMPL-REPORT to:
`maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-<commit-id>.md`

(Where `<commit-id>` is the planner-assigned identifier like `H.1` / `H.9` / `H.16`.)

### M.4 — End-of-batch flow (H.17)

After all 16 implementation commits land:
1. `pack-reviewer` runs on full batch diff (HEAD at H.0 baseline → HEAD at end of H.16).
2. Pack Chat triages findings (default fix-all; user triages per finding before fix-coder spawns).
3. Fresh pack-coder applies fixes (if any).
4. Per single-BD batch close commit shape: fix commit + BD-173 status flip ship in ONE commit (`fix: v11 — BD-173 broad batch review/fix + status flip (Batch 19c)`).
5. If no fixes: standalone `docs: v11 — flip BD-173 to Resolved` commit closes the batch.

### M.5 — Post-batch verification

After H.17 lands:
- `python3 scripts/validate-pack.py` PASSES at the batch-close HEAD (Check 43 from H.14 is now active; all 36 leak-sweep leaks closed by H.9-H.11; Guardrails 2-4 active per H.13-H.15).
- `bash test-fixtures/build.sh --verify` PASSES (manifest matches all per-commit regenerations).
- `bash scripts/tests/test-validate-pack-check-43.sh` PASSES (new test file from H.14).
- `bash scripts/tests/test-validate-pack-checks-36-37-38.sh` PASSES (Groups 6 + 7 from H.13 + H.12 active).
- BD-173 status: `Resolved`; `Resolved:` line filled with date + close commit SHA + summary.
- `pack-ops/CHANGELOG.md` may receive a Batch 19c summary entry at the version-boundary close (per Pack Chat protocol; not necessarily in H.17 itself).

---

*End of ARCHITECTURE-CLEANUP-BATCH-19C V2.*

