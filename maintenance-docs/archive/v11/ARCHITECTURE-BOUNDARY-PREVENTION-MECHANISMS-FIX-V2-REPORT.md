# Architect C — fix v2 implementation report (HELP-FRAGMENT-TRACKER row staleness)

**Role:** Architect C (v2 amendment)
**BD:** BD-175 (CODE RED — pack/project boundary remediation), Phase 3 fix-pass v2
**Source observation:** `maintenance-docs/v11-implementation/PACK-REVIEW-PHASE-2-DESIGNS-VERIFICATION.md` §2 "One mild observation (informational, not a defect)"
**Doc amended:** `maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md`
**Date:** 2026-05-19

---

## §1 — Line 584 area BEFORE/AFTER

**BEFORE (single row in §8.2 Check 37 deny-list table):**

```
| `HELP-FRAGMENT-TRACKER.md` (pack-root copy; project-side has its own copy at `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`) | Architect-B-conditional — depends on byte-identity status post-B |
```

**AFTER (single row, reworded in place):**

```
| `HELP-FRAGMENT-TRACKER.md` (bare filename; project-side has its own copy at `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`) | Pack-only at the bare-filename level. Post-B the pack-side copy lives at `pack-ops/HELP-FRAGMENT-TRACKER.md` (per Architect B §3 #9 + B's M2); CI Check 24 enforces byte-identity between the pack-ops copy and the project-side `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` copy. This bare-filename row catches project-side references that omit a path prefix; broader `pack-ops/` path-prefix coverage is the row below. |
```

**Design call — KEEP the row (do NOT delete):** The bare-filename row is retained because it catches project-side references that name `HELP-FRAGMENT-TRACKER.md` without a path prefix — a distinct grep shape from the `pack-ops/` path-prefix row at line 587. Deleting the row would weaken Check 37's coverage of bare-filename hits. The reworded cell makes the relationship to the `pack-ops/` row explicit so the Phase 5 coder understands the two rows are complementary, not redundant.

---

## §2 — §16 update

A new subsection `§16a — Phase 3 verification v2 amendment — HELP-FRAGMENT-TRACKER row staleness fix` was inserted directly after the existing `§16.6 — Unaffected sections` block and before the `## End of architecture design` separator. The new subsection contains five bullets:

- **Source:** Cites `PACK-REVIEW-PHASE-2-DESIGNS-VERIFICATION.md` §2 + the HEAD `8014186` line 584 location.
- **Why the prior wording was stale:** Cites Architect B's `ARCHITECTURE-DIRECTORY-REORGANIZATION.md` §3 row #9 (line 167) + B's §6.1 M2 row (line 527) as the unconditional finalization of the byte-identity contract; notes B-fix and B-fix v2 do not reopen the contract.
- **What was changed:** Documents the line 584 reword + retention rationale + cross-reference to the line 587 `pack-ops/` row (which is already present in this doc via the §16.1 M2 amendment).
- **Net effect on Phase 5 coder:** Identical to pre-amendment state; no fixture, check semantics, or order-of-land step changes.
- **Sections NOT touched:** Affirms §0-§15 and §16.1-§16.6 are unchanged.

The §16a placement preserves §16.6's "Unaffected sections" enumeration as the final summary of the prior fix-pass, then layers the v2 amendment as a clearly-labeled subsequent addition.

---

## §3 — Confirmation: other sections of C's design untouched

Verified by post-edit grep:

- Total file mutations: ONE row reword at line 584 area + ONE subsection insertion (§16a, 37 lines) before `## End of architecture design`.
- No other byte-level changes to §0-§15, §16.1-§16.6, or any cross-reference network.
- The remaining `Architect-B-conditional` hits in the doc (`OPTIONAL-FEATURES.md` row at line 585; pack-only keyword semantics at lines 480, 741; OQ at line 877) are in unrelated rows and sections; none were flagged by the reviewer and none were touched.
- The `pack-ops/` path-prefix row at line 587 (already added in §16.1 fix-pass per M2) is unchanged.

Reviewer's "mild observation (informational, not a defect)" is closed. Phase 4 planner spawn is unaffected — the verification verdict was already GO before this amendment; v2 simply removes the staleness noted in the observation.
