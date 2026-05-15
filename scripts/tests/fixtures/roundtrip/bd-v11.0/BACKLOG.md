**BD-001 — Add foo to bar**
Type: TODO(version)
Status: Open
Blockers: None
Unblocks: BD-002
File/Symbol: scripts/foo.sh
Description: Implements the foo behavior on the bar surface.
Resolved: n/a

---

**BD-002 — Refactor bar after foo lands**
Type: TODO(version)
Status: Unblocked
Blockers: BD-001
Unblocks: None
File/Symbol: scripts/bar.sh
Description: Refactor bar after foo lands.
Resolved: n/a

---

**TD-010 — Document quux**
Type: TODO(scope)
Status: Open
Blockers: None
Unblocks: None
File/Symbol: docs/quux.md
Description: The quux subsystem lacks user-facing documentation.
Resolved: n/a

---

**TD-040 — Cross-phase TD blocked by phase task (BD-108 F5)**
Type: TODO(version)
Status: Open
Blockers: phase-1.2, TD-010
Unblocks: None
File/Symbol: scripts/cross-phase.sh
Description: Exercises the v11.0 phase-N.M Blockers grammar through
  the full forward → state-file → reverse round-trip. The phase-1.2
  pack-id rides through tmf_parse_backlog (shape-agnostic
  parse_id_list) and through _tmr_emit_backlog (joins with `, `
  preserving source order). V3.3 §5.3 additive grammar.
Resolved: n/a

---
