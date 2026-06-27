# Synthetic fixture — Check 43 FAIL path (LEAK CLASS A, per-entry skeleton)

This fixture exercises LEAK CLASS A per ARCHITECTURE-V11-GUARDRAILS-
CONTRACT.md §1.12 cross-walk row 1 (24 per-entry skeleton bare
`ARCHITECTURE-*` cites). Check 43 MUST FAIL the bare ref below with
the "pack-internal target" verdict.

The per-entry skeleton format is documented in
`ARCHITECTURE-PER-ENTRY-SPLIT.md` (resolves to
`maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT.md`
→ pack-only).

Remediation: drop the cite OR replace with a project-side SSOT
(e.g., `docs/project/backlog/_rules.md` for the per-entry skeleton
contract).
