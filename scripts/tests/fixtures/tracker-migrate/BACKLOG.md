# BACKLOG — fixture for BD-065 forward-migration tests

## Active

**BD-001 — Add foo to bar**
Type: TODO(version)
Status: Open
Blockers: None
Unblocks: BD-002
File/Symbol: scripts/foo.sh
Description: Implements the foo behavior on the bar surface.
  Multi-line continuation here.
Resolved: n/a

---

**BD-002 — Refactor bar**
Type: TODO(version)
Status: Open
Blockers: BD-001, phase-1
Unblocks: None
File/Symbol: scripts/bar.sh
Description: Refactor bar after foo lands.
Resolved: n/a

---

**BD-003 — Fix baz crash**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: scripts/baz.sh
Description: Baz crashed on null input.
Resolved: 2026-04-01 — fixed in commit abc1234. Added regression test.

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

**TD-011 — Replace fizzbuzz lib**
Type: TODO(version)
Status: Cancelled
Blockers: None
Unblocks: None
File/Symbol: scripts/fizzbuzz.sh
Description: Considered replacing the fizzbuzz lib with stdlib.
Resolved: 2026-03-15 — not pursued; existing lib is sufficient.

---
