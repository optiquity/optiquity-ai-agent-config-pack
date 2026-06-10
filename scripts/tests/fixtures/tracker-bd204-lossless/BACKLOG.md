**BD-901 — Drop-set fields interleaved with carried fields**
Type: TODO(version)
Target: v11.0
Status: Open
Position: after BD-902
Blockers: None
Scope: Every top-level drop-set field must ride the gz64 blob verbatim,
  in original order, interleaved between carried fields.
Unblocks: BD-907
Problem: The pre-fix parser whitelist silently discarded the
  Target/Position/Scope/Problem/References/Out-of-scope lines on forward.
Description: Order-faithful drop-set stress entry; the carried and
  dropped fields alternate so a fixed-order re-projection cannot
  reproduce the original ordering.
References: BD-902; the gz64 verbatim-body carrier design (§3.3).
Out of scope: Entry rewrites; the project-side TD namespace.
Resolved: n/a

---

**BD-902 — No-Description worst case**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: BD-901
File/Symbol: scripts/lib/tracker-migrate-reverse.sh
Resolved: Landed with the carrier; this entry deliberately carries no
  Description field at all (the worst-case cohort migrates to a
  near-empty projection but a complete blob).

---

**BD-903 — Sub-blocks inside Description**
Type: TODO(version)
Status: Open
Blockers: None
Unblocks: None
Description: The sub-blocks below live INSIDE the Description field as
  continuation lines (the BD-903 case the original C-7 fixture carried).
  Segments:
  - segment one (parse-order)
  - segment two (verbatim ride)
  Steps:
  1. forward composes the blob
  2. reverse decodes it byte-identical
Resolved: n/a

---

**BD-904 — Autolink trigger forms (all four)**
Type: TODO(version)
Status: Unblocked
Blockers: None
Unblocks: None
Description: Triggers: issue ref #123, mention @pack-bd204-nobody,
  commit deadbeefcafe1234567890abcdef12345678dead, and
  https://example.invalid/bd204 — the composed H2 must neutralize all
  four forms (inline-code span, no live link); the blob must decode
  every trigger token verbatim.
Resolved: n/a

---

**BD-905 — Parenthetical title stress (Qualifier Three)**
Type: TODO(version)
Status: Open
Blockers: None
Unblocks: None
Description: The parenthetical is admissible TITLE TEXT after the
  em-dash (the BD-195 exemplar shape). Post-BD-211 there is no suffix
  case — a BD-NNNb filename/header or a pre-em-dash parenthetical is a
  validator failure, not a fixture.
Resolved: n/a

---

**BD-906 — Deferred status canary**
Type: TODO(version)
Status: Deferred
Blockers: None
Unblocks: None
Description: The Deferred count is the round-trip canary — forward maps
  Status to the status:deferred label, reverse decodes it back, and the
  blob carries the verbatim Status line regardless.
Resolved: n/a

---

**BD-907 — Large multi-block entry**
Type: TODO(version)
Status: Open
Blockers: BD-901
Unblocks: None
Goal: Round-trip a large multi-block body byte-identically.
Segments:
- A: the top-level Segments block is a drop-set field (not whitelisted)
- B: it rides the blob verbatim with its bullets intact
- C: ordering across blocks is load-bearing
Steps:
1. decompose the fixture monolith into the per-entry tree
2. forward-migrate the tree to the scratch repo
3. reverse-migrate and byte-compare against the baseline tree
State: authored for the rebuilt C-7 oracle; exercised on every rehearsal.
Scope: Top-level Segments/Steps/State/Goal/Scope blocks interleaved with
  carried fields; a fenced code span `like this` and the interior blank
  line below stress the verbatim capture.

  The interior blank line above and this trailing paragraph are part of
  the Scope continuation; the projection parser drops them, the blob
  carries them verbatim.
Description: The large multi-block exemplar (BD-195-shaped) for the
  content-faithfulness leg.
Resolved: n/a

---
