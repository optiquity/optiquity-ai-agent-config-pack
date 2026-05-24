# Synthetic fixture — Check 43 FAIL path (LEAK CLASS F, BD-175 self-leak class)

This fixture exercises LEAK CLASS F per ARCHITECTURE-V11-GUARDRAILS-
CONTRACT.md §1.12 cross-walk row 7 (1 boundary-investigation
`AUDIT-USER-CURATION.md` cite — the BD-175 self-leak). Check 43
MUST FAIL the bare ref below with the "pack-internal target" verdict.

Per the audit-vocabulary-gap incident captured in
`AUDIT-USER-CURATION.md` (resolves to
`maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md` →
pack-only), boundary-investigation skill content acquired a stray
audit cite that whole-file Check 37 exemption masked.

This is the exact class Check 43 + Guardrail 2 doubly-guard
against: Check 43 detects the bare `AUDIT-USER-CURATION.md` ref
AND the per-line fence stops the skill from acquiring whole-file
Check 37 exemption that would mask it.

Note: when this synthetic file is run through Check 43 in a
fixture context (no fence markers), the bare ref MUST FAIL.
