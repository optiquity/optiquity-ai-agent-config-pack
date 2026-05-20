# Synthetic fixture — Check 40 PASS path (anchor-phrase exemption)

This fixture exercises the `_CHECK_40_ANCHOR_PHRASES` exemption tier.
Each bare ref below MUST be admitted by an anchor in the ±2-line
window. (Note: the actual basenames matter only for matching the
regex; the anchor-phrase admission is what's under test.)

The tracker example template (`tracker.toml.pack-example` in the pack repo,
or `tracker.toml.example` at a client project root) and the
`OPTIONAL-FEATURES.md` walkthrough document the opt-in flow.

The migrator runs post-install at the client and consumes
`docs/pack/OPTIONAL-FEATURES.md` from the installed location. The
`OPTIONAL-FEATURES.md` reference here is admitted by the
`post-install` anchor in this ±2-line window.

**Historical citation (does not exist anchor):** five prior reviewer
prompts cited `IMPLEMENTATION-PLAN-V11.0.md` (does not exist);
canonical filename is `EXECUTION-PLAN-V11.0.md`.

**Archived doc citation (archived anchor):** from the now-archived
`ARCHITECTURE-V1.md` and `V3.3-DELTA.md` the path-3-forbidden rule
originated.
