# BACKLOG — promote test fixture

## Active

**TD-031 — Refactor sidecar emitter for streaming**
Type: TODO(version)
Status: Open
Blockers: None
Unblocks: None
File/Symbol: `scripts/lib/tracker-sidecar.sh` — `tracker_sidecar_emit`
Description: The current emitter buffers the whole sidecar in memory before
  writing. For repos with thousands of issues, switch to streaming mode.
Context: Observed memory usage during BD-102 dog-food run.
Resolution: n/a

---

**TD-029 — Add cycle-graph dump verb**
Type: TODO(version)
Status: Open
Blockers: None
Unblocks: None
File/Symbol: `scripts/pack-tracker.sh`
Description: Inspecting the cycle-graph store today requires raw JSON;
  add a verb that pretty-prints the edge list with pack-ids.
Context: Surfaced during BD-108 review.
Resolution: n/a

---

**TD-040 — Schema bootstrap helper**
Type: TODO(version)
Status: Open
Blockers:
  - TD-029
  - phase-3.1
Unblocks: None
File/Symbol: `scripts/lib/tracker-schema.sh`
Description: Common schema-loader helper to deduplicate the four call sites.
Context: Repeated boilerplate noticed in BD-106/108 land.
Resolution: n/a

---
