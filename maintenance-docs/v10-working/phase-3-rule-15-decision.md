# Phase 3 — C-045-04 rule 15 decision record

**Status:** resolved — Outcome A (extension).
**Date:** 2026-04-22.
**Scope:** `project-template/skills/audit-methodology/SKILL.md` rule 15
(the `auditor-architecture` cluster scope summary line).
**Context:** V10-IMPLEMENTATION-PLAN.md §6.1 C-045-04; V10-DESIGN.md
§3.10 and §13.4.

---

## Rule 15 verbatim (pre-edit)

Quoted from `project-template/skills/audit-methodology/SKILL.md:43` as
of v10-dev HEAD immediately before this commit:

> 15. **auditor-architecture** — architecture compliance, layer
> discipline, design quality, module coupling, interface uniformity,
> LSP compliance, SOLID adherence, observability infrastructure
> completeness (are logs/metrics/traces wired up at the right layers?).

## Criteria evaluation

Per V10-IMPLEMENTATION-PLAN §6.1 C-045-04 decision procedure:

**(i) Does rule 15 reference `auditor-architecture` scope authority
(an "LSP compliance" or equivalent phrase that establishes what that
auditor covers)?**

Yes. Rule 15 *is* the scope enumeration for the `auditor-architecture`
cluster. It explicitly lists "LSP compliance" as a scope bullet and is
the authoritative single-line summary that the three
`auditor-architecture` agent files cite ("Scope (per
`audit-methodology` rule 15):"). The `## Subagent clusters (7)` H2 at
line 38 frames rules 15–21 collectively as cluster scope definitions.

**(ii) Does rule 15 read as a general architectural rule not tied to
the auditor scope list?**

No. It is the scope list entry, not a general rule.

## Decision

**Outcome A — extend.** Rule 15 is updated to add `capabilities
pattern adherence (LSP required; capabilities recommended)` immediately
after `LSP compliance`, keeping the two findings categories adjacent
and the LSP-required / capabilities-recommended framing inline.

Rationale: C-045-03 added a parallel **Capabilities pattern
adherence** scope bullet to each of the three auditor-architecture
agent files (Claude md, Gemini md, Codex TOML). The agent files cite
rule 15 as their scope authority; if rule 15 enumerates only
"LSP compliance" while the agent files enumerate both LSP and
capabilities, the authority chain is broken and an auditor reader
will see inconsistency between skill and agent scope. Extending rule
15 preserves the chain. The parenthetical `(LSP required; capabilities
recommended)` mirrors the language used throughout Part 3 of
V10-DESIGN and in the C-045-03 auditor scope bullets.

## Revisit conditions

Revisit this decision if:

- **BD-032** (auditor observability refinement) restructures the
  auditor-architecture cluster scope.
- A future BD item modifies the relationship between LSP and
  capabilities as documented in V10-DESIGN §3.9.
- The scope enumeration format in rule 15 is changed (e.g. split into
  multiple rules one-per-bullet) in a later version, in which case
  the capabilities entry becomes its own rule rather than an inline
  bullet.

## Rule 15 verbatim (post-edit, for traceability)

> 15. **auditor-architecture** — architecture compliance, layer
> discipline, design quality, module coupling, interface uniformity,
> LSP compliance, capabilities pattern adherence (LSP required;
> capabilities recommended), SOLID adherence, observability
> infrastructure completeness (are logs/metrics/traces wired up at
> the right layers?).
