# Synthetic fixture — Check 40 PASS path (same-dir-legit)

This fixture exercises the same-dir-legitimate PASS tier. Each bare
ref below resolves to exactly one file in the same directory as the
referencing doc (when the fixture is loaded as a pack-ops/*.md file
in a synthetic repo per the test harness).

In a real pack-ops/ context, bare refs to sibling pack-ops/ docs
PASS by same-dir-legit: `PACK-CHAT.md`, `PACK-AGENTS.md`,
`MERGE-STRATEGY.md`, `BOUNDARY-DEFINITION.md`,
`CONCEPTUAL-REVIEW-METHODOLOGY.md`, `DRY-RUN-MIGRATION.md`,
`HELP-FRAGMENT-PACK.md`, `HELP-FRAGMENT-TRACKER.md`,
`OPTIONAL-FEATURES.md`, `BACKLOG.md`, `CHANGELOG.md`. These are
analogous to programming-language sibling-import semantics.
