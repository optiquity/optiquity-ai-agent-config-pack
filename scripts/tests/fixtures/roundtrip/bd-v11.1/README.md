# roundtrip/bd-v11.1 — stub directory

Per V1 §6.6.1 multi-template-version round-trip readiness, this
directory is a stub at v11.0. When v11.1 ships with new template
fields (per V2 §19), drop a fixture set in here:

  - `BACKLOG.md` — entry written on the v11.1 template (one entry
    is enough; the round-trip test fixture-walks per-directory).
  - `IMPLEMENTATION_PLAN.md` — phases referenced from the entry, if any.
  - `tracker.toml` — `backend.name = "github"` + a fixture repo slug;
    `mode.state = "tracker"` + `migration.forward_complete = true`.
  - `extra_fields.json` — the v11.x-only fields the entry's body
    carries (e.g., new wi-priority field added at v11.1). One JSON
    object per entry, keyed by pack-id:
    ```json
    { "BD-001": { "wi-priority": "high" } }
    ```

## Reader contract

Two readers will consume this directory:

1. **`scripts/tests/tracker-migrate-roundtrip-test.sh`** — exercises
   the round-trip: forward → reverse → forward. Asserts the
   v11.x-only fields survive in the sidecar's `extra_fields` block
   on reverse and re-hydrate on re-forward.

2. **`pack tracker update-templates`** (BD-069 + the v11.1 BD that
   ships the real translation manifest) — reads the form-level
   template_version markers, resolves the translation chain, and
   applies the patch. The fixture's `extra_fields.json` documents
   what the v11.1 template added; the production manifest at
   `maintenance-docs/v11-research/templates-archive/translations.yaml`
   encodes the translation rules.

Until v11.1 ships, this directory contains only this README. The
round-trip test (Group 5) detects the stub state by checking for
the README's "stub" string and skips the directory.

PACK-REVIEW-BD066-068 Finding #15 closure.
