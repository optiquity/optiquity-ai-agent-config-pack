# Synthetic fixture — Check 43 PASS path (cross-boundary product feature)

This fixture exercises the `_CHECK_43_ALLOWLIST` exemption tier
via the `PACK-FEEDBACK.md` entry (per ARCHITECTURE-V11-GUARDRAILS-
CONTRACT.md §1.4 Project-side cross-boundary feedback channel).

The PM chat writes to `PACK-FEEDBACK.md` in the client's
`docs/pack/` directory to surface pack-vs-project feedback. This
cross-boundary product feature is part of v10+ design — the file
IS client-installed (per `_CLIENT_INSTALLED_FILES`).

Every bare ref below MUST be admitted by the
`_CHECK_43_ALLOWLIST` entry (`PACK-FEEDBACK.md`) and PASS Check 43.

The pack feedback flow lives in `PACK-FEEDBACK.md` and the PM chat
maintains the append-only log there.
