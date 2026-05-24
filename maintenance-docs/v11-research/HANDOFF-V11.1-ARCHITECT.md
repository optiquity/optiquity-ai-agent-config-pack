# HANDOFF — v11.1+ groupings architect

**Purpose:** Single-page entry point for the future v11.1+ architect picking up the groupings feature. Points at the artifact set, surfaces critical-to-know items, and lays out the pipeline forward. Read THIS doc first; then the artifacts in the order below.

**Authored by:** Pack Chat (BD-186 sidecar wrap, 2026-05-23).
**Source BD:** BD-186 (Resolved 2026-05-23; closing commit `5e66836`).
**Successor BDs (parking-lot):** BD-187 (entry-type instruction doc), BD-188 (Phase-Iteration sprint view).

---

## Reading order

Read in this sequence; each builds on the prior:

1. **THIS doc** — orientation; ~5 min.
2. **`maintenance-docs/v11-research/REQUIREMENTS-GROUPINGS-V11.md`** — primary input. Problem / goal / success criteria per capability + user-approved design decisions + architect-level surfaces. 17 capabilities. **READ IN FULL.** ~30-40 min.
3. **`maintenance-docs/v11-research/RESEARCH-TRACKER-GROUPING-PRIMITIVES-PER-BACKEND.md`** — verified per-backend tracker facts (Pass-1 + Pass-2). 6 backends in full V1-V10 structure (GitHub Projects v2 / Linear / Jira Cloud / Redmine / GitLab / Forgejo+Gitea) + 4 Tier-1 backends in full (Azure DevOps / YouTrack / Asana / ClickUp) + 10 Tier-2 backends brief survey + 0-5 graded comparison matrix at §7. **READ §7 first for at-a-glance comparison; consult per-backend sections when designing #11 capability matrix.** ~20-30 min.
4. **`maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-GROUPINGS-V2.md`** — constraint enumeration of current v11 design + 14 observations + 7 break-points + 3 major-revision flags. Already triaged during BD-186 — each item has a resolution in REQUIREMENTS-GROUPINGS-V11.md. **SCAN for context; re-consult if a specific touch-point needs deeper detail.** ~10 min.
5. **`maintenance-docs/v11-research/V11.1-DISCUSSION-GITHUB-PROJECTS.md`** — original parking-lot brainstorm that initiated the groupings concept. Mostly superseded by REQUIREMENTS-GROUPINGS-V11.md, but §10's grouping doc shape example and §14 open questions remain useful context. **OPTIONAL.** ~10 min.
6. **`maintenance-docs/v11-research/IMPLEMENTATION-REPORT-RESEARCH-TRACKER-PRIMITIVES.md`** — methodology + open questions for the tracker primitives research. **OPTIONAL** unless you want to know how the research was conducted. ~5 min.
7. **`maintenance-docs/v11-research/INTAKE-GROUPINGS-V11.md`** — audit-trail capturing user-intent discussion that led to BD-186 design decisions. **FAITHFUL SUMMARY fidelity** (not verbatim; clearly labeled in the doc header); useful if you want to understand the discussion behind design decisions that the REQUIREMENTS doc carries in distilled form. Includes session brief, 5+2 design principles with discussion context, C1-C7 constraints with user reasoning, major design moments (filename correction, dual-SSOT rejection, STATUS.md major revision, etc.), process rules established, BD landscape evolution, and research commissioning rationale. **OPTIONAL.** ~10 min.

**Skip:** `EXTERNAL-RESEARCH.md` for tracker primitive details (superseded; see header note in that doc) — but consult §1-§8 + §10-§12 for GitHub Issues / gh CLI / MCP / CLI integration patterns / OSS abstraction patterns.

---

## What's locked vs what's yours to design

### Locked (user-approved; architect must respect)

**Per-capability design decisions** in REQUIREMENTS-GROUPINGS-V11.md §4 capabilities #1-#17. Notable highlights:

- **5-field grouping doc shape** (Title + Kind + Description + Member-phases + back-pointer) + 1 optional (PRD reference). Auto-include regex DROPPED. (#1)
- **Explicit-membership model**: phases carry no grouping metadata; reverse-lookup is verb-based; many-to-many. (#2)
- **Membership rules**: phases-only (C1); min-2 members with in-doc exception (C2); no max. (#3)
- **9-Kind extensible enum** via project-level `_rules.md` edit. (#4)
- **Per-entry tree** at `project-template/docs/project/groupings/` with `GRP-NNN.md` filename convention. **NO `GROUPINGS.md` mirror** (deviation from backlog/implementation-plan/changelog pattern — STATUS.md absorbs the convenience-reading role). (#5)
- **From-phases and from-external workflows** are PM-Chat-mediated (not standalone scripts). (#6, #7)
- **8-verb v11.1 set** with namespace split (`pack tracker groupings ...` for tracker-only; `pack groupings ...` for queries). (#9)
- **Single SSOT in pack repo**; tracker is mirror. (#10)
- **STATUS.md unified-dashboard design** with phase table + groupings table + cross-links + mode-aware rendering. **Substantially more complex generator than current STATUS.md.** (#14)
- **Migration is a separately-scoped architect/planner/coder pipeline** — NOT ad-hoc file copies. (#16 SC10)

### Open architect-level surfaces (yours to design)

Every capability lists "Architect-level surfaces." Most load-bearing across capabilities:

- **#10 — Bi-directional sync carrier mechanism.** Sidecar / inline / hybrid; conflict resolution algorithm; round-trip test fixture shape. The earlier "split-authority" recommendation was REJECTED for creating dual SSOTs. You decide the right shape.
- **#11 — Multi-grouping-per-issue mitigation strategy** for backends where it's not native (Jira / Redmine / Forgejo / Azure DevOps). Three candidate strategies surfaced in triage; user left this open.
- **#9 — Shared reverse-lookup library**: persisted derived artifact (matching `_toc.md` pattern) vs rebuild-every-time. User left this open; architect chooses based on scale.
- **#14 — STATUS.md generator** is substantial. Cross-tree read + reverse-lookup at regen time + mode-aware rendering + intra-doc anchor management. User acknowledged ~5-10x complexity increase as conscious UX investment.
- **#17 — Empty-state behavior** must be consistent across all per-entry streams (backlog / implementation-plan / changelog / groupings). Architect designs with full cross-stream context; gaps in existing streams open as separate BDs outside BD-186 scope.

---

## Critical time-sensitive items

Tracker API deprecations the v11.1 implementation MUST account for:

| Tracker | Deprecation | Deadline | Action |
|---|---|---|---|
| **Jira** | Sprint REST endpoints removal | **2026-11-01** | Target replacement API; verify timing |
| **Jira** | Points-based rate limits | **Enforced since 2026-03-02** | Adapt API call patterns; budget for points |
| **Jira** | Epic Link / Parent Link unification | Active | Use `parent` field, not legacy fields |
| **GitLab** | Epic REST API | Already removed | Target Epic GraphQL or Work Items API |
| **GitLab** | Epic GraphQL planned removal | **GitLab 19.0** | Target Work Items API as future-proof |
| **GitLab** | Project-level iterations | Already removed | Use group-level iterations only |
| **Bitbucket Issues** | Service sunset | **2026-08-20** | **EXCLUDE from v11.1 capability matrix entirely** |
| **Pivotal Tracker** | Service decommissioned | **2025-04-30** | Already gone; do not advertise as backend |

See RESEARCH-TRACKER-GROUPING-PRIMITIVES-PER-BACKEND.md §8 + §9 for full details + primary-source citations.

---

## Open questions across the artifact set

Items the architect should resolve during the pass (consult REQUIREMENTS-GROUPINGS-V11.md per-capability for full context):

- **#10:** Carrier mechanism for tracker-side extensions; conflict resolution algorithm; sidecar shape + location.
- **#11:** Multi-grouping mitigation strategy per backend (restrict / label-emulation / hybrid / per-backend).
- **#9:** Persisted index vs rebuild-every-time for reverse-lookup library.
- **#14:** Exact intra-doc anchor naming + collision handling; per-backend tracker URL format integration.
- **#17:** Cross-stream parity verification for empty-state handling; any existing-stream gaps surface as separate BDs.
- **GitHub Projects v2:** Webhook payload stability post-preview (open question P2.6 #1 in IMPL-REPORT).
- **Azure DevOps:** TSTU rate-limit model is composite cost-per-call; not pre-budgetable without empirical measurement.
- **Tier-2 trackers** (Notion / monday.com / OpenProject / Trello / Phorge / Bugzilla / Mantis / Taiga / Bitbucket Issues / Sourcehut Todo): user decides at architect-pass time which (if any) belong in v11.1 capability matrix at first ship; default is "deferred to v11.x or later."

---

## Pipeline forward

Per REQUIREMENTS-GROUPINGS-V11.md §6:

1. **Architect pass** — read this handoff + REQUIREMENTS-GROUPINGS-V11.md + RESEARCH-TRACKER-GROUPING-PRIMITIVES-PER-BACKEND.md. Produce ARCHITECTURE-GROUPINGS.md covering all 17 capabilities + cross-stream parity for #17.
2. **User review** of architect output (per pack memory `feedback_planner_user_review_before_coder`).
3. **Planner pass** — produce PLAN-GROUPINGS.md with BD breakdown + sequencing + verification strategy.
4. **User review** of planner output.
5. **Coder cycles** — per-BD implementation with reviewer cycles per pack memory `feedback_review_fix_one_cycle`.
6. **Migration architect/planner/coder pass** — SEPARATELY scoped per #16 SC10. Produce ARCHITECTURE-v11.0-to-v11.x-migration.md + PLAN-v11.0-to-v11.x-migration.md + implementation. Migration is NOT ad-hoc file copies.
7. **End-of-batch reviewer + BD status flip + MIGRATION doc landing + release pin.**

---

## Design principles (authoritative; from REQUIREMENTS-GROUPINGS-V11.md §1)

7 principles + considerations. Architect MUST respect; design decisions are bounded by them. Brief recap:

1. **Purpose-driven** — design based on what should be possible; usage data informs HOW not WHETHER.
2. **First-class entity** — groupings equivalent to backlog/implementation-plan/changelog.
3. **Reversibility** — no tracker-only state; single SSOT in pack repo.
4. **Tracker portability** — via BD-060 abstraction; grouping doc format provider-agnostic.
5. **Compatibility** — integrate with existing v11 design; minor mods OK; major need discussion.
6. **External-tool accommodation (C6)** — accept predetermined groupings from external tools via PM-Chat translation; no parsers.
7. **Graceful tracker degradation (C7)** — capable trackers not crippled to LCD; incapable trackers have documented mitigations.

Full text + rationale: REQUIREMENTS-GROUPINGS-V11.md §1.

Pack memory cache: `feedback_groupings_design_principles.md` (Claude Code only; trinity is the authoritative version at REQUIREMENTS-GROUPINGS-V11.md §1).

---

## BD landscape entry points

| BD | Status | Role |
|---|---|---|
| **BD-186** | Resolved 2026-05-23 (`5e66836`) | Requirements-gathering BD; produced the artifact set; CLOSED |
| **BD-187** | Open (TODO(version) parking-lot) | Standalone entry-type instruction doc for external-tool consumption; authoring unblocked at BD-186 close; scheduling recommend post-v11.1 ship |
| **BD-188** | Open (TODO(version) parking-lot) | Phase-Iteration sprint view = V11.1 §13 Y-6 optional capability; scheduling deferred until v11.1+ groupings ship + observed sprint-view demand |
| **NEW BDs from v11.1 architect** | TBD | Architect/planner deliverables produce them; expected ~7-10 BDs covering the 17 capabilities |

---

## Process notes for the architect

- **Per pack memory `feedback_pack_chat_does_not_architect`:** Pack Chat does NOT architect; the architect agent (or you, the architect) produces the ARCHITECTURE doc independently of Pack Chat's framing. THIS handoff doc is INPUT, not architecture.
- **Per pack memory `feedback_no_solutions_in_agent_prompts`:** REQUIREMENTS-GROUPINGS-V11.md was authored with this rule in mind — Problem / Goal / Success Criteria framing dominates. User-approved design decisions are recorded as constraints, not as proposed solutions.
- **Per pack memory `feedback_user_prescriptive_authority`:** the user retains decision-making authority. When you surface options, expect to provide evidence-based recommendations; the user will approve or redirect.
- **Per `feedback_review_fix_one_cycle`:** per-BD inline review + end-of-batch review; details in memory file.

---

## Quick-start recipe

If you're the v11.1 architect picking this up cold:

1. Read THIS doc (~5 min).
2. Read REQUIREMENTS-GROUPINGS-V11.md §1 + §2 + §3 + §4 + §5 + §6 + §7 (the 17 capabilities are in §4; expect 30-40 min).
3. Read RESEARCH-TRACKER-GROUPING-PRIMITIVES-PER-BACKEND.md §7 (matrix at a glance, ~5 min); per-backend sections as needed.
4. Spot-check TOUCH-POINT-INVENTORY-GROUPINGS-V2.md sections referenced by REQUIREMENTS-GROUPINGS-V11.md cross-refs (10 min).
5. Begin architect work: ARCHITECTURE-GROUPINGS.md following the artifact's per-capability problem/goal/SC structure; respect locked design decisions; resolve open architect-level surfaces.

Total prerequisite reading: ~60-90 minutes.

---

End of HANDOFF-V11.1-ARCHITECT.md.
