# PACK-REVIEW-BD-158 — `swift-concurrency-patterns` skill

**Verdict:** APPROVE.

**One-line summary.** BD-158 lands the new D1-implied
`swift-concurrency-patterns` skill cleanly: the new SKILL.md covers all
spec topics (Modern Swift Concurrency + GCD), the strip-and-cross-reference
work in `swift-best-practices` and `apple-architecture-core` is consistent,
PLATFORM-SKILLS.md is updated correctly with the row in the
**dimensional-skills table** (not intersection), the two scripts are
extended in parallel, `detect.sh` / `test-detect.sh` / `validate-pack.py`
are correctly **not** modified (D1-implied semantics), all 30/30
validate-pack checks PASS, all 64 detect tests pass, all 34
init-project tests pass, and the change satisfies every BD-159 §3.1
mechanical-edit condition.

---

## Files reviewed

- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/skills/swift-concurrency-patterns/SKILL.md` (NEW, 418 lines, untracked)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/skills/swift-best-practices/SKILL.md` (MOD)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/skills/apple-architecture-core/SKILL.md` (MOD)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/docs/pack/PLATFORM-SKILLS.md` (MOD)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/init-project.sh` (MOD)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/add-capability.sh` (MOD)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-158.md` (transcribed report)

---

## Per-concern findings

### 1. New `swift-concurrency-patterns/SKILL.md` content — PASS

`project-template/skills/swift-concurrency-patterns/SKILL.md` (418 lines,
14 content sections + Applicability):

- **Frontmatter** (lines 1–5): `name: swift-concurrency-patterns`,
  description names every BD-158 spec topic, `allowed-tools` matches
  read-only skill convention.
- **Applicability** (lines 7–40): names the 5 loaded-by agents
  (`architect`, `coder`, `reviewer`, `auditor-architecture`,
  `auditor-code`) at lines 9–11, declares D1-implied loading explicitly
  (lines 11–15), correctly references `swift-best-practices` as the
  parallel D1-implied companion, and forward-references the v12-deferred
  Tier 0 `concurrency-architecture` skill (lines 29–34) per BD-153.
- **Modern Swift Concurrency coverage** — every BD-158 topic present:
  - async/await semantics: rules 1–5 (lines 42–64).
  - Structured concurrency (`async let`, `TaskGroup`, Task hierarchy):
    rules 6–10 (lines 66–89).
  - Cancellation propagation: rules 11–14 (lines 91–112).
  - Actor isolation (`actor`, `@MainActor`, `GlobalActor`, isolated
    parameters, reentrancy): rules 15–21 (lines 114–152).
  - Sendable conformance design: rules 22–26 (lines 154–180).
  - `@preconcurrency` boundaries: rules 27–29 (lines 182–199).
  - AsyncSequence / AsyncStream: rules 30–34 (lines 201–230).
  - Data-race avoidance under Swift 6 strict checking: rules 35–38
    (lines 232–253).
  - Bridging to legacy callback APIs via
    `withCheckedContinuation` / `withCheckedThrowingContinuation`:
    rules 39–42 (lines 255–277).
- **GCD coverage** — every BD-158 topic present:
  - DispatchQueue type selection: rules 43–46 (lines 279–301).
  - DispatchGroup / DispatchSemaphore / barriers: rules 47–50 (lines
    303–327).
  - QoS, escalation, DispatchSource: rules 51–54 (lines 329–350).
  - Do-not-mix anti-patterns: rules 55–58 (lines 352–373).
  - Modernization (when to migrate GCD to async/await): rules 59–62
    (lines 375–396).
- **High-risk changes** — rules 63–66 (lines 398–418): `@MainActor`
  retrofit; removing `@unchecked Sendable`; introducing `Task.detached`;
  replacing `DispatchSemaphore` with `AsyncSemaphore` / `TaskGroup`.
- **Naming**: `swift-concurrency-patterns` matches architecture §7.10
  `*-patterns` for cross-cutting concerns; `swift-` prefix marks
  language scope (parallel to `swift-best-practices`).
- **Single canonical path**: skill placed at
  `project-template/skills/swift-concurrency-patterns/SKILL.md` matching
  every other skill in `project-template/skills/`. (See §"Note on
  BACKLOG `File/Symbol` wording" below — the BACKLOG entry's `.claude` /
  `.codex` / `.gemini` "trinity copies" wording is inconsistent with
  the actual pack convention; the implementation correctly follows the
  established convention used by all 30 sibling skills.)

### 2. `swift-best-practices/SKILL.md` strip — PASS

Diff (`scripts/diff` summary):

- **Description** (line 3): refreshed to drop concurrency mention; now
  reads "Use for Swift language patterns, type system, immutability,
  error handling, testing tooling, and idiomatic Swift style."
- **Companion-skill block** (lines 7–22, NEW): one-paragraph
  cross-reference to `swift-concurrency-patterns`; correctly explains
  what stays here (style touchpoints) vs. what moves (substantive
  design).
- **Concurrency touchpoints (style level)** section (lines 37–53):
  trimmed from 7 rules to 4, each retaining the style-level mention
  with explicit deferral to the companion skill. Rules 10 (async/await
  preference), 11 (`@MainActor` on ViewModels), 12 (`actor` for shared
  state), 13 (Sendable on generated Protobuf types) are exactly the
  style-touchpoint rules called out in the spec.
- **Rule renumbering**: error-handling 14–17, testing 18–20, style
  21–28, dead-code 29–35, design 36 — internally consistent throughout
  the file. The IMPLEMENTATION-REPORT says 14–36; final rule is 36
  (line 90); confirmed.
- **Relocation footer** (line 92): one-line note records that the
  AsyncStream payload-design rule was moved to
  `swift-concurrency-patterns`.

### 3. `apple-architecture-core/SKILL.md` strip — PASS

Diff:

- **Description** (line 3): updated to remove "actor isolation"; now
  reads "...layer discipline, typed IDs, LSP compliance, capabilities
  pattern, SPM module structure, deployment-target compatibility."
- **Companion-skill block** (lines 7–17, NEW): one paragraph
  cross-referencing `swift-concurrency-patterns` for the substantive
  rules.
- **Section header rename** (line 73): "Actor isolation and state" →
  "State ownership", matching the IMPLEMENTATION-REPORT.
- **Rule 15** (line 75): trimmed; retains state-ownership documentation
  rule and adds "isolation domain (owning actor, thread, or queue)";
  defers actor-isolation specifics to the companion skill.

### 4. `PLATFORM-SKILLS.md` updates — PASS

- **D1 dimensional table** (lines 66–67): both `ios` and `macos` rows
  extended with `swift-concurrency-patterns`.
- **Dimensional-skills table row added** (line 450) — confirmed in the
  **dimensional-skills table**, NOT the intersection table. Row reads
  "D1 ∈ {ios, macos} *(D1-implied)*", matches the spec's KEY DIFFERENCE
  from BD-156/157.
- **Inventory math**: dimensional row count 18 → 19 (header line 442);
  total 33 → 34 (line 493). Manual recount of the dimensional table
  (lines 446–464) confirms 19 rows. Math checks out.
- **Per-agent rows updated** (lines 323, 327, 331, 360, 366) — exactly
  the 5 loaded-by agents: architect, coder, reviewer,
  auditor-architecture, auditor-code. Each row carries an inline
  rationale appropriate to that agent's concern.
- **Worked examples updated** — 5 of the 5 examples that touch D1 ∈
  {ios, macos} got the new skill added in both the input lines and the
  Result lines (260, 267, 268, 281, 288, 291, 298, 301, 308). Spot-check
  pass.
- **Inventory footer** (lines 466–473): updated count, retains the
  D1-implied breakdown including the new skill alongside
  `swift-best-practices`.

### 5. `init-project.sh` `pack_skill_coverage_for swift)` — PASS

`scripts/init-project.sh` lines 248–266:

- BD-158 explanatory comment block (lines 248–258) correctly cites
  architecture §3.2 D1-implied semantics and explains why no marker
  predicate is needed.
- Both branches updated:
  - SwiftData-present branch (line 263):
    `apple-architecture-core,swift-best-practices,swift-concurrency-patterns,apple-swiftdata-patterns`
  - SwiftData-absent branch (line 265):
    `apple-architecture-core,swift-best-practices,swift-concurrency-patterns`
- Insertion point of `swift-concurrency-patterns` is between
  `swift-best-practices` and `apple-swiftdata-patterns` — matches
  PLATFORM-SKILLS.md ordering convention.
- `swiftdata_marker_detected()` call site preserved unchanged.

### 6. `add-capability.sh` `language:swift` — PASS

`scripts/add-capability.sh` line 129:
`language:swift)     echo "swift-best-practices swift-concurrency-patterns apple-architecture-core dependency-swift" ;;`

- Added between `swift-best-practices` and `apple-architecture-core`,
  parallel ordering to `init-project.sh`.
- BD-158 comment block (lines 120–128) correctly distinguishes the
  D1-implied addition (added here) from the marker-gated
  `apple-swiftdata-patterns` (NOT added here, gated under
  `platform:macos` / `platform:ios`).

### 7. `scripts/lib/detect.sh` NOT modified — PASS

`git diff HEAD scripts/lib/detect.sh` returns empty. Correct — D1-implied
skills don't need marker helpers (KEY DIFFERENCE from BD-156's
`protobuf_marker_detected()` and BD-157's `swiftdata_marker_detected()`).

### 8. `scripts/test-detect.sh` NOT modified — PASS

`git diff HEAD scripts/test-detect.sh` returns empty. No swift-coverage
literal assertion in test-detect.sh, so no test update is required.
`bash scripts/test-detect.sh` reports `64 passed, 0 failed`.

### 9. `scripts/validate-pack.py` NOT modified — PASS

`git diff HEAD scripts/validate-pack.py` returns empty. Check 31 ships
under BD-146 (deferred). All existing 30 checks PASS — `python3
scripts/validate-pack.py` exits with `PASSED — all checks clean`.

### 10. Public contracts preserved — PASS

- `pack_skill_coverage_for()` signature/output unchanged — still emits a
  comma-separated string matching the BD-141/156/157 literal-comparison
  pattern; the only addition is one more skill name in the existing
  field.
- Permission bits preserved on both modified scripts (`-rwxr-xr-x` per
  IMPLEMENTATION-REPORT §2 row notes; `git diff` shows no mode change).
- No removal of any prior comparison; the BD-141 / BD-156 / BD-157
  marker comparisons remain intact in `init-project.sh` (the swift case
  was the only branch touched).

### 11. Maintainability principle (BD-159 §3.1) — PASS

All 7 §3.1 mechanical conditions satisfied:

1. **Trinity scope**: pack convention is single canonical path under
   `project-template/skills/`; PLATFORM-SKILLS.md is single-source.
   Trinity rule does not apply to `project-template/skills/` files —
   only to `project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md`.
   No CLAUDE/AGENTS/GEMINI changes in this batch (none required —
   skill-loading is project-template-only, not pack-ops).
2. **Existing dimension fit**: D1-implied selector for D1 ∈
   {ios, macos}, identical mechanism to `swift-best-practices`. No
   new dimension, no new load mechanism.
3. **Existing pattern fit**: `standalone` organization pattern, same as
   `grpc-patterns`, `rest-patterns`, `security-patterns`, BD-156
   `protobuf-patterns`, BD-157 `apple-swiftdata-patterns`.
4. **Existing naming convention fit**: `*-patterns` suffix per
   architecture §7.10, language-scope `swift-` prefix.
5. **Existing validator coverage**: validate-pack 30/30 PASS without
   modification.
6. **Bounded file footprint**: 1 NEW + 5 MOD = 6 edited files, well
   under the 10 cap. 0 new top-level docs (the IMPLEMENTATION-REPORT
   and the inline RESEARCH/ARCHITECTURE artifacts in the working tree
   are workflow artifacts under Pattern B per CLAUDE.md, not new
   top-level pack docs). 0 new scripts. 0 new validate-pack checks.
7. **No agent-permission expansion**: no edits to `## Pack memory`,
   `PACK-AGENTS.md` PM-only files list, or any rule in the "Repo
   conventions" / "Workflow" / "Sub-agent isolation" subsections.

### 12. Validate-pack 30/30 PASS — PASS

Verified by running `python3 scripts/validate-pack.py`. Output:
`PASSED — all checks clean`. All 30 checks green; no warnings.

Additional smoke tests:
- `bash scripts/test-detect.sh` → `64 passed, 0 failed`.
- `bash scripts/tests/test-init-project.sh` → `Passed: 34 / Failed: 0`.

---

## D1-implied loading-mechanism verification

This is the KEY DIFFERENCE from BD-156/157 and the central correctness
question for BD-158. All four sub-checks pass:

1. **Skill row landed in dimensional-skills table, NOT intersection
   table** — confirmed at PLATFORM-SKILLS.md line 450 (in the
   "Dimensional skills (19)" table that starts at line 444). The
   intersection-table rows are
   `python-server-architecture` /
   `python-data-architecture` / `protobuf-patterns` /
   `apple-swiftdata-patterns` / `deployment-python` (the 5 enumerated
   in the inventory footer at lines 467–470); `swift-concurrency-patterns`
   is **not** among them.
2. **No marker helper added to `scripts/lib/detect.sh`** — `git diff
   HEAD scripts/lib/detect.sh` is empty.
3. **`init-project.sh` swift case adds the skill unconditionally** —
   added in both SwiftData branches (lines 263 and 265), no marker
   predicate gating.
4. **Cell column reads `D1 ∈ {ios, macos} *(D1-implied)*`** —
   PLATFORM-SKILLS.md line 450; matches the architecture §3.2 D1-implied
   semantics and is identical in shape to `swift-best-practices` (line
   449).

---

## Cross-reference integrity

`grep` across `project-template/`, `scripts/`, `maintenance-docs/` for
`swift-concurrency-patterns` returns hits in:

- New skill (1 file).
- 2 stripped skills with cross-reference paragraphs (correct).
- PLATFORM-SKILLS.md (12 hits — D1 table, worked examples, agent rows,
  inventory).
- 2 scripts (init-project, add-capability — correct).
- BACKLOG entry, PLAN, ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY,
  IMPLEMENTATION-REPORT (workflow artifacts, expected).

No stale or orphaned references. No dangling forward-reference to
removed sections in `swift-best-practices` or `apple-architecture-core`.

---

## Note on BACKLOG `File/Symbol` wording (informational, not a defect)

BACKLOG.md line 1355 enumerates the new skill at three trinity paths
(`.claude/skills/...`, `.codex/skills/...`, `.gemini/skills/...`) and
likewise refers to "3× swift-best-practices/SKILL.md trinity copies"
and "3× apple-architecture-core/SKILL.md trinity copies".

The actual pack convention — verified by `ls
project-template/skills/` showing 30 sibling skills, every one of
which lives at `project-template/skills/<name>/SKILL.md` (single
canonical path, not per-CLI mirrored) — is single-canonical-path.
Per-CLI mirroring under `.claude/skills/` / `.codex/skills/` /
`.gemini/skills/` exists for a small set of operational skills only
(`pack-help`, `pm-startup`).

The IMPLEMENTATION-REPORT correctly notes "Single canonical path (no
per-CLI mirrors)" at row 25. The BD-158 implementation is consistent
with the actual pack layout; the BACKLOG `File/Symbol` line was
written from a planner template that didn't account for the
single-canonical-path convention. This is a documentation defect in
the BACKLOG entry, not in the BD-158 implementation.

**Recommended follow-up (PM-chat scope, not a blocker for this batch):**
Update the BACKLOG BD-158 `File/Symbol` line to read
`project-template/skills/swift-concurrency-patterns/SKILL.md` (single
path) before flipping the BD to Resolved, so the resolved entry
accurately records what shipped. The same wording fix applies to the
BD-156 / BD-157 entries if they used the same planner-template
language. (Verified out of scope: this review does not edit BACKLOG.)

---

## Trinity-rule check

The CLAUDE.md trinity rule applies to `project-template/CLAUDE.md` /
`AGENTS.md` / `GEMINI.md` and to the pack-repo copies of those three
files. **None of these were modified in BD-158.** The trinity rule does
not extend to `project-template/skills/<name>/SKILL.md` files (which
live at a single canonical path) — confirmed against the directory
listing of `project-template/skills/`. Correct: no trinity violation
possible here.

---

## Summary table

| Concern | Status | Notes |
|---|---|---|
| 1. New SKILL.md content | PASS | All BD-158 topics present; 66 rules across 14 sections |
| 2. swift-best-practices strip | PASS | 7→4 concurrency rules; renumbering consistent |
| 3. apple-architecture-core strip | PASS | Header renamed; rule 15 trimmed |
| 4. PLATFORM-SKILLS.md | PASS | Dimensional-table row; counts 18→19 / 33→34 |
| 5. init-project.sh swift | PASS | Both SwiftData branches updated |
| 6. add-capability.sh | PASS | language:swift extended in parallel |
| 7. detect.sh unchanged | PASS | Empty diff |
| 8. test-detect.sh unchanged | PASS | Empty diff; 64/64 tests pass |
| 9. validate-pack.py unchanged | PASS | Empty diff; 30/30 checks pass |
| 10. Public contracts preserved | PASS | Signatures + perm bits intact |
| 11. BD-159 §3.1 mechanical | PASS | All 7 conditions satisfied |
| 12. validate-pack 30/30 | PASS | All checks clean |
| D1-implied loading | PASS | Dimensional table, no marker, unconditional add |
| Cross-reference integrity | PASS | No stale refs |
| Trinity rule | PASS | Not applicable to skills/ files |

**Verdict: APPROVE.** Ready for commit.
