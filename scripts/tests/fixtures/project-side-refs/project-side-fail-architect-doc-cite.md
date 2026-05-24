# Synthetic fixture — Check 43 FAIL path (LEAK CLASS A, architect doc cite)

This fixture exercises LEAK CLASS A per ARCHITECTURE-V11-GUARDRAILS-
CONTRACT.md §1.12 cross-walk row 3 (1 `PM-CHAT.md` `ARCHITECTURE-V3.3-DELTA.md`
cite). Check 43 MUST FAIL the bare ref below with the "pack-internal
target" verdict.

The pack-internal design history is documented in
`ARCHITECTURE-V3.3-DELTA.md` (resolves to
`maintenance-docs/v11-research/ARCHITECTURE-V3.3-DELTA.md` →
pack-only at the pack repo; not present at client install).

This bare ref MUST FAIL Check 43 even from a file that previously
held whole-file Check 37 exemption — Check 43's allowlist is
BASENAME-keyed, not FILE-keyed (per §1.12 row 3 NOTE).
