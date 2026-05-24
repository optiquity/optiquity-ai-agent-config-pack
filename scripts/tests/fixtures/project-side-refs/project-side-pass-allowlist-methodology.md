# Synthetic fixture — Check 43 PASS path (client-installed supporting-docs/)

This fixture exercises the `_CHECK_43_ALLOWLIST` exemption tier
via the `METHODOLOGY.md` entry (per ARCHITECTURE-V11-GUARDRAILS-
CONTRACT.md §1.4 "Project-side docs/pack/METHODOLOGY.md (client-
installed)").

The methodology document at `METHODOLOGY.md` is client-installed
per `_CLIENT_INSTALLED_FILES` (resolves to
`docs/pack/METHODOLOGY.md` post-install). Bare refs to
`METHODOLOGY.md` MUST PASS via the allowlist entry.

Per §1.6 "Supporting-docs subset rule": `METHODOLOGY.md` and
`INSTALL-PROCEDURES.md` are LEGITIMATE resolution targets (both
in `_CHECK_43_ALLOWLIST`); other supporting-docs/ files like
`SETUP-NEW.md` / `CLI-PM-SETUP.md` / `MIGRATION-v10-to-v11.md`
are FORBIDDEN resolution targets.

The bare ref `METHODOLOGY.md` MUST PASS this check.
The bare ref `INSTALL-PROCEDURES.md` MUST also PASS (also on
the allowlist).
