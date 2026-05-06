# roundtrip/bd-v11.1 — stub directory

Per V1 §6.6.1 multi-template-version round-trip readiness, this
directory is a stub at v11.0. When v11.1 ships with new
template fields (per V2 §19), drop a fixture set in here:

  - BACKLOG.md       — entry written on the v11.1 template
  - IMPLEMENTATION_PLAN.md
  - tracker.toml     — backend.name + repo
  - extra_fields.json — v11.x-only fields the entry's body carries
                        (e.g., new wi-priority field added at v11.1)

`scripts/tests/tracker-migrate-roundtrip-test.sh` already iterates
over every `bd-v11.x/` directory in this tree; once a fixture is
present here, the round-trip test exercises forward → reverse →
forward against it, asserting that v11.x-only fields survive in
the sidecar's `extra_fields` block on reverse and re-hydrate on
re-forward.

Until v11.1 ships, this directory contains only this README.
