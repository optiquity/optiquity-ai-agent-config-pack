# IMPLEMENTATION-REPORT-BD-157

**BD:** BD-157 — `apple-swiftdata-patterns` skill — SwiftData object-store
rules for Apple platforms
**Branch:** `v11-dev`
**Pre-flight HEAD SHA:** `4d93862a283e8f8290d758fa3d04bad903ef9efe`
**Post-implementation HEAD SHA:** `4d93862a283e8f8290d758fa3d04bad903ef9efe`
(no commits; agents do not commit per pack memory rule)
**Worktree:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`
**Date:** 2026-05-12

---

## 1. Pre-flight state

- `git rev-parse HEAD`: `4d93862a283e8f8290d758fa3d04bad903ef9efe`
- `git status`: clean
- `git branch --show-current`: `v11-dev`
- Baseline `python3 scripts/validate-pack.py`: PASS (30/30 checks)
- Baseline `bash scripts/test-detect.sh`: 52 passed / 0 failed
- Confirmed input docs readable:
  `BACKLOG.md` (BD-157 entry at line 1361), `PLATFORM-SKILLS.md`
  (intersection table + dimensional table), `protobuf-patterns/SKILL.md`
  (BD-156 precedent), `scripts/lib/detect.sh` (`protobuf_marker_detected`,
  `python_data_marker_detected`), `scripts/init-project.sh`
  (`pack_skill_coverage_for`), `scripts/add-capability.sh`
  (`capability_skills`), `scripts/test-detect.sh` (BD-156 cases).
- Confirmed gap: `apple-architecture-core/SKILL.md` mentions SwiftData
  only as "domain layer must NOT import" — not coverage of SwiftData
  rules. `ios-architecture/SKILL.md` and `macos-architecture/SKILL.md`
  do not mention SwiftData at all.

---

## 2. Per-file edit log

### 2.1 NEW `project-template/skills/apple-swiftdata-patterns/SKILL.md`

- Created new directory + SKILL.md at the single canonical path per
  pack convention (per-CLI fan-out happens at install time via
  `init-project.sh stage_s4_skills`).
- 272 lines, frontmatter + 9 topical sections, 45 numbered rules.
  Structurally mirrors BD-156 `protobuf-patterns/SKILL.md` (234
  lines / 45 rules).
- Sections (numbered rules in parentheses):
  1. Applicability (load predicate cross-reference, scope statement)
  2. `@Model` macro design (rules 1-9): subclass ban, value-type
     stored properties, `@Transient`, `@Attribute(.unique)`,
     `.externalStorage`, `.spotlight`, deletion-rule semantics,
     explicit inverses.
  3. `ModelContainer` and `ModelContext` lifecycle (rules 10-16):
     one container per store, in-memory test config, `@MainActor`
     isolation, non-Sendable contexts, child contexts for batch,
     `autosaveEnabled` semantics.
  4. `FetchDescriptor` construction (rules 17-21): `#Predicate` macro,
     `fetchLimit`, `fetchOffset` requires sort, pre-computed sort
     descriptors, no non-stored predicate properties.
  5. Relationship traversal performance (rules 22-25):
     `relationshipKeyPathsForPrefetching`, scoped prefetching,
     `childCount` projection over `.count`, cycle breaks.
  6. Schema migration (rules 26-29): `VersionedSchema` +
     `versionIdentifier`, `SchemaMigrationPlan` lightweight vs
     custom, `willMigrate`/`didMigrate` boundary, on-disk fixture
     test discipline.
  7. History tracking (rules 30-32): opt-in only, token-based read,
     `deleteHistory(before:)` pruning.
  8. CloudKit sync integration (rules 33-36): private/shared
     databases, optional / default-valued properties only,
     `.nullify`-only relationships, schema deploy coordination.
  9. Transactionality and `save()` semantics (rules 37-40):
     durability boundary, atomic per-context, error mapping,
     `rollback()` after failure.
  10. Query performance and index hints (rules 41-43):
      `@Attribute(.indexed)`, no native composite indexes,
      Instruments SwiftData template profiling.
  11. High-risk changes — flag explicitly (rules 44-45): property
      removal is destructive, deletion-rule changes are breaking.
- Frontmatter: `name`, `description`, `allowed-tools` (matches
  `protobuf-patterns` shape).
- Verification: file exists, line count 272 (within 150–300 target,
  matches BD-156's 234-line precedent), all rules numbered 1-45 with
  no gaps.

### 2.2 MODIFIED `scripts/lib/detect.sh`

- Added new function `swiftdata_marker_detected()` at the end of
  the protobuf block, just before `detect_target_pack_version`.
- Function shape mirrors `protobuf_marker_detected()` (BD-156) and
  `python_data_marker_detected()` (BD-141): single positional
  argument defaulting to cwd; tolerates missing target as `no`;
  emits a single `swiftdata-marker: yes|no` literal line.
- Three markers per BD-157 spec:
  - (a) `.swift` source file containing `import SwiftData`,
    line-anchored to defeat comment prose.
  - (b) `.swift` source file containing an `@Model` attribute,
    boundary-anchored (`@Model([[:space:]]|\(|$)`) to reject
    `@ModelAttribute` / `@Modeled` lookalikes.
  - (c) Manifest (`Package.swift`, `Package.resolved`, `Podfile`,
    `Podfile.lock`) listing `SwiftData` or `swift-data` with the
    BD-141 negated-character-class boundary.
- Vendored / build trees pruned: `node_modules`, `.git`, `build`,
  `.venv`, `venv`, `.tox`, `.build`, `DerivedData`, `Pods`,
  `Carthage`. Mirrors BD-156 prune list + Apple-toolchain-specific
  additions.
- 108 lines added. Function comment block documents callers (init,
  add-capability, PLATFORM-SKILLS.md) and rationale.
- File mode unchanged (644; sourced, not executed).

### 2.3 MODIFIED `scripts/init-project.sh`

- `pack_skill_coverage_for()` swift case extended to call
  `swiftdata_marker_detected "$target_dir"` and emit
  `apple-architecture-core,swift-best-practices,apple-swiftdata-patterns`
  when the literal output equals `swiftdata-marker: yes`, else the
  existing two-skill list.
- Tight literal compare matches BD-141 / BD-156 precedent so a
  future helper-output change is caught at compare time, not
  silently.
- 17 lines added. Comment block cross-references BD-141 (python)
  and BD-156 (proto) precedents.
- File mode unchanged (755).

### 2.4 MODIFIED `scripts/add-capability.sh`

- Added a comment cross-reference above the existing
  `platform:macos` / `platform:ios` capability rows explaining the
  intersection-loaded `apple-swiftdata-patterns` companion skill.
  Mirrors the BD-156 comment cross-reference at `protocol:grpc`.
- The `capability_skills()` row contents themselves are
  unchanged — `apple-swiftdata-patterns` is intersection-loaded by
  marker, not by capability declaration. Pattern matches BD-156
  exactly.
- 9 lines added (comment only, no behavior change).
- File mode unchanged (755).

### 2.5 MODIFIED `scripts/test-detect.sh`

- New section "swiftdata_marker_detected (BD-157)" inserted before
  "detect_target_pack_version". 12 new test cases:
  - empty dir → no
  - non-existent target → no (tolerated)
  - marker (a): `import SwiftData` → yes
  - marker (b): `@Model` attribute → yes
  - marker (b) parameter form: `@Model(...)` → yes
  - marker (b) lookalike reject: `@ModelAttribute` / `@Modeled`
    alone → no
  - vendored prune: `import SwiftData` only inside `.build/` → no
  - marker (c) substring reject: `SwiftDataKit` → no
  - marker (c) trailing-name-char reject: `SwiftData-shim` → no
  - marker (c) bare word match: bare `SwiftData` reference → yes
  - negative: Apple project without SwiftData → no
  - negative: non-Apple project (no `.swift` files) → no
- Cases mirror the BD-156 protobuf test shape (positive markers,
  vendored-tree prune, substring boundary rejects, negative
  baseline).
- 137 lines added.
- File mode unchanged (755).

### 2.6 MODIFIED `project-template/docs/pack/PLATFORM-SKILLS.md`

- New row in §"Intersection table (sparse cells)" for
  `apple-swiftdata-patterns` with predicate
  `D1 ∈ {ios, macos} ∩ swiftdata-marker present` and
  source-of-truth pointer to
  `scripts/lib/detect.sh::swiftdata_marker_detected()`.
- §"Combining dimensions and mechanisms — worked examples":
  augmented the "iOS Swift app, no server" example to show both
  with-SwiftData and without-SwiftData result sets.
- §"Step 2 — Select skills per agent" rows updated for the 5
  loaded-by agents per BD-157 spec:
  - `architect`: appended `apple-swiftdata-patterns` with load-
    when annotation.
  - `coder`: appended `apple-swiftdata-patterns` with load-when
    annotation.
  - `reviewer`: appended `apple-swiftdata-patterns` with load-when
    annotation.
  - `auditor-architecture`: appended `apple-swiftdata-patterns`
    with rationale (`@Model` schema design + storage threading
    are architectural concerns).
  - `auditor-code`: appended `apple-swiftdata-patterns` with
    rationale (N+1 traversal, missing prefetching, unbounded
    fetches, `ModelContext` threading violations).
- §"Dimensional skills (17)" header updated to `(18)`.
- §"Dimensional skills" inventory table: new row for
  `apple-swiftdata-patterns` with Cell, Description, and Agents
  columns.
- §"Dimensional skills" trailing summary updated:
  "17 dimensional / intersection skills" → "18 dimensional /
  intersection skills"; intersection-loaded count updated from
  "four rows" → "five rows" with the new skill named.
- §"Total skills" updated: "Total skills: 32" → "Total skills: 33"
  with the dimensional count update reflected.
- 31 lines changed (15 insertions, 16 deletions per `git diff
  --stat`'s reported delta of 31 changed lines ⇒ verified diff is
  net +15 lines).

---

## 3. Verification command results

### 3.1 `python3 scripts/validate-pack.py`

```
PASSED — all checks clean
```

All 30 checks pass. No regressions in any Check.

### 3.2 `bash scripts/test-detect.sh`

```
=== Results: 64 passed, 0 failed ===
```

Baseline was 52. Delta = +12 (the 12 new BD-157 test cases listed in
§2.5). Zero regressions in BD-141 python, BD-156 protobuf, BD-119
target-pack-version, or any earlier section.

### 3.3 `bash scripts/tests/test-init-project.sh`

```
=== Summary ===
Passed: 34
Failed: 0
All tests passed.
```

No regression. All 34 cases in groups 1 (preview), 2 (--update),
3 (S11 v11 artifacts) pass.

### 3.4 Permission-bit verification

```
-rwxr-xr-x  scripts/add-capability.sh
-rwxr-xr-x  scripts/init-project.sh
-rw-r--r--  scripts/lib/detect.sh   (sourced library; non-exec by design)
-rwxr-xr-x  scripts/test-detect.sh
```

All preserved.

---

## 4. Plan deviations

**Zero.** The implementation matches the BD-157 spec exactly:

- New SKILL.md at the single canonical path
  (`project-template/skills/apple-swiftdata-patterns/SKILL.md`) per
  the BD-156 POQ-A finding. Per-CLI fan-out happens at install
  time via `init-project.sh stage_s4_skills`. No per-CLI trinity
  copies created at `project-template/.claude/skills/` etc.
- New helper `swiftdata_marker_detected()` markers as specified:
  `import SwiftData`, `@Model` macro, manifest references.
- Wiring in `init-project.sh` follows the BD-156 / BD-141
  precedent (literal-output compare, swift case extension).
- Wiring in `add-capability.sh` is a comment cross-reference, not
  a `capability_skills` row addition (per BD-156 precedent for
  marker-driven intersection skills).
- New test cases in `test-detect.sh` mirror BD-156's structural
  shape.
- PLATFORM-SKILLS.md row + counts + per-agent rows + worked
  example updated, all per spec. `validate-pack.py` Check 31 was
  explicitly NOT touched (it ships in BD-146); existing 30
  Checks preserved.
- File-count footprint: 6 (1 NEW SKILL.md + 5 modified). Within
  BD-159 §3.1 mechanical-edit cap of ≤10. Matches the spec's
  expected count exactly.

---

## 5. POQs introduced

**None.** No architectural ambiguities surfaced during
implementation. The BD-157 spec referenced BD-156 as the precedent
for every decision point (single canonical path; literal-compare
helper output; comment cross-reference in add-capability; per-agent
load-when annotations); each was applied directly without
modification.

The "future companion skills" mentioned in the BD-157 description
(`apple-coredata-patterns`, `apple-sqlite-patterns`) are explicitly
out of v11.0 scope and are not POQs — they are documented future
work in the new SKILL.md's Applicability section as the spec
requires.

---

## 6. Files-changed inventory

| Path | Change type | Lines |
|---|---|---|
| `project-template/skills/apple-swiftdata-patterns/SKILL.md` | NEW | +272 |
| `scripts/lib/detect.sh` | MODIFIED | +108 |
| `scripts/test-detect.sh` | MODIFIED | +137 |
| `scripts/init-project.sh` | MODIFIED | +17 (-2 = net +15) |
| `scripts/add-capability.sh` | MODIFIED | +9 |
| `project-template/docs/pack/PLATFORM-SKILLS.md` | MODIFIED | +31 changed (15 ins / 16 del) |

**Total:** 1 new file, 5 modified files. 6 files. Well within the
BD-159 §3.1 mechanical-edit cap of ≤10.

`git diff --stat` summary (modified files only):

```
 project-template/docs/pack/PLATFORM-SKILLS.md |  31 +++---
 scripts/add-capability.sh                     |   9 ++
 scripts/init-project.sh                       |  20 +++-
 scripts/lib/detect.sh                         | 108 ++++++++++++++++++++
 scripts/test-detect.sh                        | 137 ++++++++++++++++++++++++++
 5 files changed, 289 insertions(+), 16 deletions(-)
```

(`apple-swiftdata-patterns/` is untracked and not in the modified
diff stat — see "Untracked files" in `git status`.)

---

## 7. Definition-of-Done checklist

| # | Criterion | Status |
|---|---|---|
| 1 | `python3 scripts/validate-pack.py` returns PASS for all 30 checks | PASS |
| 2 | `bash scripts/test-detect.sh` PASS with new SwiftData cases (52 → 64; +12 added) | PASS |
| 3 | `bash scripts/tests/test-init-project.sh` no regression (34/34) | PASS |
| 4 | PLATFORM-SKILLS.md skill counts in headers and Full skill inventory match each other and reflect actual table contents (18 dimensional / 33 total) | PASS |
| 5 | Permission bits preserved on all `.sh` files | PASS |
| 6 | No edits outside the explicit BD-157 footprint | PASS |
| 7 | NEW SKILL.md at single canonical path (no per-CLI trinity copies) | PASS |
| 8 | New `swiftdata_marker_detected()` mirrors BD-141 / BD-156 shape (literal `key: value` output, single arg defaulting to cwd, tolerates missing target) | PASS |
| 9 | `init-project.sh` swift case extended with literal-compare wiring matching BD-156 precedent | PASS |
| 10 | `add-capability.sh` comment cross-reference matches BD-156 precedent | PASS |
| 11 | PLATFORM-SKILLS.md per-agent rows updated for the 5 loaded-by agents | PASS |
| 12 | `validate-pack.py` Check 31 NOT edited (ships with BD-146) | PASS |
| 13 | New SKILL.md content is NEW prose, not copied from CoreData docs / other skills | PASS |
| 14 | Implementation report written to the requested path | PASS |
| 15 | No state-changing git verbs run by this agent | PASS |

---

## 8. BD-159 §3.1 mechanical-edit sanity check

BD-159 §3.1 caps a single mechanical batch at ≤10 files. This batch
touches **6 files** (1 new SKILL.md + 5 modified). Comfortably
within the cap.

The batch is **mechanical** by the BD-159 §3 criteria: it adds a new
intersection-table row + helper + worked example, all following
established patterns (BD-141, BD-156). No architectural change is
introduced — the 5+3 dimension model is unchanged; only a new
intersection-cell skill is added. No skill is renamed; no client
`x-` skill is touched; the `x-` contract is preserved.

The batch is also a deliberate worked example demonstrating the
maintainability property the BD-142 model-validation checkpoint
validated: new intersection-cell skills are mechanical additions
under the 5+3 model, not architectural changes. Total work:
1 new SKILL.md + 5 mechanical edits to scripts + a docs update
that follows a clear template (BD-156 row addition shape).

---

## 9. Notes for the parent (Pack Chat)

- The new SKILL.md at `project-template/skills/apple-swiftdata-patterns/`
  is **untracked** in git (it is a new directory + file). Pack Chat
  should `git add` the directory explicitly when staging the commit.
- All other changes are tracked-file modifications visible in
  `git diff`.
- Suggested commit message format (matching the repo convention from
  recent commits, e.g. b168a9f / d197483 / 5fa586f):

  ```
  feat: v11 — BD-157 apple-swiftdata-patterns skill + detect.sh + init-project.sh + PLATFORM-SKILLS.md (Batch 11 / hard blocker for BD-149)
  ```

  Or more concisely matching the typical trailing-batch hint shape:

  ```
  feat: v11 — BD-157 apple-swiftdata-patterns skill (intersection-loaded SwiftData rules)
  ```

- BACKLOG.md BD-157 `Status:` flip from `Open` → `Resolved` happens
  post-review per pack memory ("implicit BD status flip on batch
  completion"). Do not flip during implementation.
- One nit on the BD-157 BACKLOG entry: its File/Symbol references
  `validate-pack.py Check 31` as a touched file. Per the spec
  (which explicitly says NOT to edit `validate-pack.py` because
  Check 31 is added by the not-yet-shipped BD-146), this is a
  forward reference — no action needed in this batch. The other
  five touched files match the spec exactly.

---

End of report.
