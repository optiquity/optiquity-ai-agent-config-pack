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

**BD-003 — Drop-set + prose stress (BD-204 §3.3 carrier)**
Type: TODO(version)
Status: Open
Target: v11.0
Scope: Exercise the field-faithful gz64 carrier end to end.
Problem: The pre-fix migrator dropped every non-carry field on
  forward and re-projected a lossy fixed-order body on reverse.
Position: after BD-002
References: BD-204, RESEARCH-BD-204-GH-ISSUES-RULES.md
File/Symbol: scripts/lib/tracker-migrate-forward.sh
Description: A multi-paragraph description with an interior blank line.

  This second paragraph and the top-level drop-set fields above
  (Target/Scope/Problem/Position/References) must survive the
  forward → tracker → reverse round-trip BYTE-FOR-BYTE via the
  pack-entry-body-gz64 blob — none are in the 9-field carry set.
Out of scope: anything BD-207 owns on the client surface.

---

**BD-004 — Cancelled close round-trip (BD-204 C-8 read-back casing)**
Type: TODO(version)
Status: Cancelled
Blockers: None
Unblocks: None
File/Symbol: scripts/cancelled-surface.sh
Description: Exercises the closed-status forward path end to end —
  step-8 close (interface token not_planned → gh CLI "not planned"),
  the fake gh's live read-back storage (CLOSED/NOT_PLANNED), and the
  production normalize→decode chain back to Cancelled on reverse.
Resolved: n/a

---
