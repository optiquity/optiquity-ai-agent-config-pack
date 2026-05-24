# Synthetic fixture — Check 43 PASS path (anchor-phrase exemption)

This fixture exercises the `_CHECK_43_ANCHOR_PHRASES` exemption
tier via the "in the pack repo" anchor phrase (aliased from
`_CHECK_40_ANCHOR_PHRASES` per ARCHITECTURE-V11-GUARDRAILS-
CONTRACT.md §1.5).

In the pack repo, `ARCHITECTURE-FOO.md` describes the foo design.
This bare ref is admitted by the "in the pack repo" anchor in
the matched line.

(Note: the bare-ref-shaped basename here is irrelevant to the
exemption — the anchor admission is what's under test. Even if
`ARCHITECTURE-FOO.md` resolved to pack-only territory in the
real repo, the anchor phrase makes the bareness legitimate.)

Per the post-install convention, the PM chat workflow reads
`PM-CHAT.md` — the anchor `post-install` (within 2 lines of this
line) also admits any bare ref in this paragraph.

The archived `ARCHITECTURE-V1.md` describes the pre-2025 design
— the `archived` anchor admits this bare ref too.
