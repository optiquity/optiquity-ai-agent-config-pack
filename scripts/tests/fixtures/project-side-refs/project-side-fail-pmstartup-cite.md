# Synthetic fixture — Check 43 FAIL path (LEAK CLASS E, pm-startup cluster)

This fixture exercises LEAK CLASS E per ARCHITECTURE-V11-GUARDRAILS-
CONTRACT.md §1.12 cross-walk row 4 (4 pm-startup cluster
`ARCHITECTURE-V3.md §28.1.5` cites). Check 43 MUST FAIL the bare ref
below with the "pack-internal target" verdict.

Per the pm-startup workflow design history captured in
`ARCHITECTURE-V3.md` §28.1.5 (resolves to
`maintenance-docs/v11-research/ARCHITECTURE-V3.md` → pack-only),
the startup procedure has a five-stage design.

This bare ref MUST FAIL Check 43 — `ARCHITECTURE-V3.md` is not on
the allowlist AND no anchor phrase is in the ±2-line window.
