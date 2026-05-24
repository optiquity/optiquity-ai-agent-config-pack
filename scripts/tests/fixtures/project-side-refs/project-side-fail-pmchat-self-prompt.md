# Synthetic fixture — Check 43 FAIL path (LEAK CLASS C, pm-chat self-prompt)

This fixture exercises LEAK CLASS C per ARCHITECTURE-V11-GUARDRAILS-
CONTRACT.md §1.12 cross-walk row 5 (3 pm-chat.md self-prompt
`supporting-docs/SETUP*` cites). Check 43 MUST FAIL the qualified
reference below with the "pre-install-only" verdict.

The PM chat self-prompt assembles a project-specific `SETUP.md`
from the planning conversation. The procedure originally cited
`supporting-docs/SETUP-NEW.md` Step 10 — that qualified path is
NOT in the `_CLIENT_INSTALLED_FILES` inventory (per audit §0.3 Note
2), so it is a pre-install-only reference that cannot resolve at
client install time.

Remediation: drop the cite OR replace with a project-side SSOT.
