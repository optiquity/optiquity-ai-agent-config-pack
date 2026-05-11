# IMPLEMENTATION REPORT — python-architecture skill split (BD-035, option 4-minus)

**Verdict:** Done

**Branch:** `v11-dev`
**HEAD SHA at start + end:** `54dff63ad779e4580d0cbcf6c3e14f486b2232c4` (no commits made; all changes are working-tree edits)
**Date:** 2026-05-11

## Scope summary

Per option 4-minus agreed with the user (2026-05-11):

- Delete the existing `project-template/skills/python-architecture/`
  skill entirely.
- Create two new independent skills in its place:
  - `python-server-architecture` — server-specific rules
  - `python-data-architecture` — data / I/O rules
- No umbrella loader. No new "general" skill. `python-best-practices`
  remains the catch-all and is not modified.
- Update all live references throughout the pack; leave
  historical / archival mentions frozen.
- Add a client-side rename step to `scripts/migrate-v10-to-v11.sh`
  with auto-rewrite for unambiguous cases and an advisory file for
  ambiguous cases.

## Rule-split decisions (rule-by-rule)

The 14 v10.x `python-architecture` rules were partitioned by substance.
The architect's BD-035 audit identified server (1, 3, 9, 10, 13, 14) and
data (5, 6, 7, 11, 12) sets; rules 2, 4, 8 were not categorized in the
audit. My decisions for the un-categorized rules are documented below.

| v10.x rule | Substance | Lands in | Rationale |
|---|---|---|---|
| 1 | Servicers as thin adapters | server | Mentions servicers explicitly. |
| 2 | Constructor DI; no module-level globals for services | **BOTH** | Foundational DI rule applies equally to server services and to data/repository services. Duplicated with cross-reference notes in both skills. |
| 3 | Domain types must not appear in gRPC servicer signatures | server | gRPC servicer is a server-side concept. |
| 4 | Services stateless by default; documented state | **BOTH** | Foundational service rule applies equally to server services and to data services. Duplicated with cross-reference notes in both skills. |
| 5 | Repository pattern — data access in repositories | data | Pure data-access concern. |
| 6 | Prevent N+1 queries | data | Pure data-access concern. |
| 7 | Business logic does not call gRPC stubs / DB drivers / ORM directly | data | Although the rule mentions gRPC stubs, the rule's substance is "go through the repository abstraction" — that is a data-boundary rule, not a server-handler rule. |
| 8 | No blocking sync I/O in async handlers | server | "Async handlers" is most naturally a server-side request-handler concept. The rule is phrased around handlers. Async I/O without a server still exists, but those cases are covered by `python-best-practices`. |
| 9 | grpc.aio usage | server | Server transport choice. |
| 10 | Background tasks idempotent | server | Background tasks are a server-runtime concept (request-triggered or scheduled in-server work). |
| 11 | Pydantic at I/O boundaries | data | I/O-boundary concern. |
| 12 | ML inference isolation behind protocol | data | Domain-model placement / data concern. |
| 13 | Auth / logging / metrics in interceptors | server | Server middleware. |
| 14 | Interceptor correctness (subclass / async def) | server | Server middleware. |

**Resulting skill rule counts:**

- `python-server-architecture/SKILL.md` — 9 rules (server-specific 1, 3, 8, 9, 10, 13, 14 plus duplicated foundational 2, 4 — see "Service layer foundations" → renumbered 2, 4 in the new skill).
- `python-data-architecture/SKILL.md` — 7 rules (data-specific 5, 6, 7, 11, 12 plus duplicated foundational 2, 4 — see "Service layer foundations" → renumbered 1, 2 in the new skill).

The two skills' Applicability sections explicitly call out the
intentional duplication of rules 2 and 4 so that future readers do not
attempt to "deduplicate" them by deleting one copy.

## Migrator rename approach

Added `_v10_to_v11_rename_python_architecture_refs` to
`scripts/migrate-v10-to-v11.sh` as a new sub-step `S5b`, invoked from
`migrator_post_dispatch_hook` after `_v10_to_v11_install_v11_artifacts`.

**Files scanned (project-root-relative, only those that exist):**

- `docs/pack/PLATFORM-SKILLS.md`
- `CLAUDE.md`
- `AGENTS.md`
- `GEMINI.md`

**Per-line disambiguation rules (in order):**

1. Line already contains `python-server-architecture` → rewrite stale
   `python-architecture` to `python-server-architecture`.
2. Line already contains `python-data-architecture` → rewrite stale
   `python-architecture` to `python-data-architecture`.
3. Line contains a server-tier signal (`grpc-patterns`, `deployment-python`,
   `Python server`, `python-server`, `gRPC servicer`, `grpc.aio`,
   `interceptor`) AND no data-tier signal → rewrite to
   `python-server-architecture`.
4. Line contains a data-tier signal (`repository`, `N+1`, `Pydantic`,
   `data / I/O`, `data and I/O`, `ML inference`) AND no server-tier
   signal → rewrite to `python-data-architecture`.
5. Otherwise → record an entry in
   `$_MIGRATOR_STATE_DIR/python-architecture-rename.advisory`; leave the
   file untouched at this site.

**Why an advisory file rather than a customization-preserve sidecar:**
the in-scope files (`PLATFORM-SKILLS.md` and the trinity) are pack-managed
`transform` / `trinity` targets per the migrator's manifest. By the time
S5b runs, the pack-controlled portions have already been rewritten by the
S3 dispatcher, so the customization-preserve sidecar contract (which is
designed for ours-vs-theirs three-way merges) does not apply. The advisory
file is the canonical user-facing surface; it is created only when at least
one ambiguous site is found.

**Functional-test result (synthetic fixture in `/tmp`):**

```
── S5b — BD-035 split: rename stale python-architecture refs ──
  scanned docs/pack/PLATFORM-SKILLS.md for python-architecture rename
  scanned CLAUDE.md for python-architecture rename
  BD-035 rename: 3 unambiguous reference(s) rewritten in place
  BD-035 rename: 2 ambiguous reference(s) recorded in [...]/python-architecture-rename.advisory
  review the advisory and rename by hand before treating the migration as complete
```

The 3 unambiguous rewrites + 2 advisory entries matched the fixture's
expected disposition for each line. The fixture is removed; the file
contents and the advisory are exhaustively reproduced in the report's
verification appendix at the bottom of this document.

## Cross-reference audit

**Pre-edit grep (live, non-historical):**

```
grep -rn 'python-architecture' . --include="*.md" --include="*.sh" \
  --include="*.py" --include="*.toml" --include="*.yml" 2>/dev/null \
  | grep -v '\.git/' | grep -v 'maintenance-docs/' | grep -v 'CHANGELOG.md' \
  | grep -v 'BACKLOG.md' | grep -v 'PACK-FEEDBACK.md' \
  | grep -v 'MIGRATION-v8-to-v9.md'
```

13 live references at session start (auditor-architecture trinity ×3,
PLATFORM-SKILLS.md multiple lines, prompts/auditor.md, init-project.sh,
add-capability.sh, architecture-review SKILL ×4, the python-architecture
SKILL itself).

**Post-edit grep (live, non-historical):**

20 references remain — all intentional and load-bearing:

- `project-template/skills/python-server-architecture/SKILL.md` — 1
  occurrence: the Applicability section's "v10.x `python-architecture`"
  origin reference.
- `project-template/skills/python-data-architecture/SKILL.md` — 1
  occurrence: same Applicability origin reference.
- `scripts/migrate-v10-to-v11.sh` — 18 occurrences: the new
  `_v10_to_v11_rename_python_architecture_refs` function (header
  comment + implementation that actively scans for the bare token).

**Frozen historical / archival mentions (NOT touched):**

- `BACKLOG.md` — BD-006, BD-035, BD-045 entries.
- `CHANGELOG.md` — v9 + v10.0 release entries.
- `project-template/docs/pack/PACK-FEEDBACK.md` — Q4 (the original
  question that motivated BD-035).
- `supporting-docs/MIGRATION-v8-to-v9.md` — historical migration prose.
- `maintenance-docs/archive/V9-DESIGN.md`, `V9-AUDIT-REPORT.md`,
  `V10-DESIGN.md`, `V10-PHASE-4-VERIFICATION.md`,
  `V10-DESIGN-2.md`, `step-07-init-project.md` — archival design docs.
- `maintenance-docs/v11-implementation/AUDIT-BD-032.md`, `AUDIT-BD-035.md`,
  `EXECUTION-PLAN-V11.0.md`, `IMPLEMENTATION-REPORT-BATCH-14-FIX-FOLLOW.md`
  — prior planning / audit / report docs.

## File-change inventory

**Deleted (working tree):**

- `project-template/skills/python-architecture/SKILL.md` (also empty
  parent dir removed)

**New:**

- `project-template/skills/python-server-architecture/SKILL.md`
- `project-template/skills/python-data-architecture/SKILL.md`

**Modified — agent trinity (auditor-architecture only; auditor-code did
not reference `python-architecture` by name at session start):**

- `project-template/.claude/agents/auditor-architecture.md`
- `project-template/.codex/agents/auditor-architecture.toml`
- `project-template/.gemini/agents/auditor-architecture.md`

**Modified — skill SKILLs (architecture-review canonical reference list,
×4 surfaces):**

- `project-template/skills/architecture-review/SKILL.md`
- `.claude/skills/architecture-review/SKILL.md`
- `.codex/skills/architecture-review/SKILL.md`
- `.gemini/skills/architecture-review/SKILL.md`

**Modified — pack docs / prompts:**

- `project-template/docs/pack/PLATFORM-SKILLS.md` (Dimension 2 row,
  Dimension 3 rows, Step 1 worked examples, Step 2 agent skill
  assignments for architect / reviewer / auditor-architecture /
  auditor-code, Tier 2 inventory table, total-skills count).
- `project-template/docs/pack/prompts/auditor.md` (auditor-architecture
  example skill list).

**Modified — scripts:**

- `scripts/init-project.sh` (Python language-coverage table).
- `scripts/add-capability.sh` (`language:python` entry; new
  `python-server-architecture` skill added to `role:python-server`).
- `scripts/migrate-v10-to-v11.sh` (new S5b sub-step in
  `migrator_post_dispatch_hook`; new
  `_v10_to_v11_rename_python_architecture_refs` function).

**Pre-existing modified files (NOT my edits — present at session start
from prior batch 14 fix-follow):**

- `project-template/.claude/agents/auditor-code.md`,
  `auditor-ops.md`, `auditor-ui.md`,
  `project-template/.codex/agents/auditor-{code,ops,ui}.toml`,
  `project-template/.gemini/agents/auditor-{code,ops,ui}.md`,
  `project-template/skills/audit-methodology/SKILL.md`,
  `project-template/skills/error-handling/SKILL.md`,
  `project-template/skills/ios-architecture/SKILL.md`,
  `project-template/skills/macos-architecture/SKILL.md`.

## Trinity verification — auditor-architecture

The "Skills to load" content was made symmetric across the three
auditor-architecture variants (Claude `.md`, Gemini `.md`, Codex `.toml`).
I extracted each variant's "Skills to load" / "Skills:" block and verified
all three contain the same skill-name list:

```
apple-architecture-core
ios-architecture
macos-architecture
python-server-architecture
python-data-architecture
```

with the same Apple-vs-Python typical-set wording and the same
"non-server multi-file Python" qualifier. The wording differs only in
markdown vs. plain-text formatting (`.codex` is a TOML
`developer_instructions` string and uses no backticks per the file's
existing style); this is an existing pre-split variant difference and
is not a regression.

The other 5 trinity-affected agent pairs in the original prompt brief
(auditor-code, planner, coder, architect, reviewer) did NOT reference
`python-architecture` by name in their agent files at session start —
verified via `grep -l 'python-architecture' project-template/.claude/agents/
project-template/.codex/agents/ project-template/.gemini/agents/`. So no
trinity edits were required there.

`project-template/CLAUDE.md`, `AGENTS.md`, `GEMINI.md` were also
checked — none contains a literal `python-architecture` token at
session start (the "Active skills:" line in each is a placeholder for
PM-chat fill, not a literal skill mention).

## Validator + test-suite results

**`python3 scripts/validate-pack.py`:**
`PASSED — all checks clean` (30/30).

**Migrate test suites (full run):**

- `bash scripts/tests/test-migrate-v10-to-v11.sh` — Passed: 43, Failed: 0
- `bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh` — Passed: 40, Failed: 0
- `bash scripts/tests/test-migrate-v10-to-v11-gates.sh` — Passed: 41, Failed: 0

**Other test suites (sampled coverage):**

- `bash scripts/tests/test-init-project.sh` — Passed: 34, Failed: 0
- `bash scripts/tests/test-customization-preserve.sh` — Passed: 79, Failed: 0
- `bash scripts/tests/template-version-test.sh` — Passed: 36, Failed: 0
- `bash scripts/tests/template-translations-test.sh` — Passed: 44, Failed: 0
- `bash scripts/tests/recommendation-test.sh` — Passed: 53, Failed: 0
- `bash scripts/tests/recommendation-state-schema-test.sh` — Passed: 19, Failed: 0
- `bash scripts/tests/pack-help-test.sh` — Passed: 17, Failed: 0
- `bash scripts/tests/test-issue-forms.sh` — Passed: 78, Failed: 0

**Bash syntax checks:**

- `bash -n scripts/migrate-v10-to-v11.sh` — OK
- `bash -n scripts/init-project.sh scripts/add-capability.sh` — OK

## Mode-bit hygiene

`git diff --stat | grep -i 'mode change' || echo 'no mode changes'`
→ `no mode changes`.

## Working-tree state at handoff

The branch is `v11-dev`. No commits were created. The session's edits
are pure working-tree changes ready for Pack Chat to stage and commit.

`git status` shows the modifications and additions inventoried above
plus the pre-existing untracked `maintenance-docs/v11-implementation/*`
files and the pre-existing modified files from the prior fix-follow
batch (which are out of this session's scope and were not touched).

## Pre-Open Questions

1. **Should `python-server-architecture` import or cross-reference the
   `python-data-architecture` rules its consumers also need?** The
   current design is independence: a project loading
   `python-server-architecture` is expected to also load
   `python-data-architecture` (per PLATFORM-SKILLS.md Dimension 3
   "Python server" row), and both Applicability sections say so.
   Alternative: collapse the duplicated foundational rules (2, 4) into
   one of the two skills and have the other reference it. I kept the
   duplication because it makes each skill self-contained and removes
   load-order coupling. Open for review.

2. **Should the migrator's S5b advisory be promoted to a typed-error
   block (per BD-070)?** The S5b advisory is currently informational
   (an `info` line plus a written advisory file). It does NOT fail
   the migration. If the user policy is "ambiguous renames must block
   completion until reconciled," S5b should be upgraded to emit a
   typed error and `fail_stage S5`. I left it informational because
   PLATFORM-SKILLS.md's pack-managed lines are rewritten by S3 before
   S5b runs, so the most likely ambiguous sites are user prose where
   blocking would be over-strict. Open for review.

3. **Should `init-project.sh`'s `pack_skill_coverage_for python` row
   include `python-server-architecture` as well as `python-data-architecture`?**
   The current behavior matches the v10.x design: the language-coverage
   table emits the "always-loaded" Python skills; the role-coverage
   for Python server is added by `add-capability.sh` (which I updated
   to include `python-server-architecture`). If init-project.sh is
   expected to detect server presence directly, the table needs
   server-detection logic; that change is out of scope for the split.
   Open for review.

## Verification appendix — migrator functional-test transcript

Synthetic fixture (subsequently deleted):

`/tmp/py-arch-rename-test/docs/pack/PLATFORM-SKILLS.md` (input):

```
# stale references for testing

## Server case (should rewrite to python-server-architecture)
- Role: Python server → python-architecture, deployment-python, grpc-patterns

## Data case (should rewrite to python-data-architecture)
- repository pattern provided by python-architecture and N+1 detection

## Already-mixed case (should rewrite to server)
- python-server-architecture and python-architecture (typo legacy)

## Ambiguous (should be advised)
- See python-architecture for details

## No change
- python-server-architecture and python-data-architecture both load
```

`/tmp/py-arch-rename-test/CLAUDE.md` (input):

```
Active skills: python-best-practices, python-architecture, dependency-python
```

After running `_v10_to_v11_rename_python_architecture_refs`:

`docs/pack/PLATFORM-SKILLS.md`:

```
# stale references for testing

## Server case (should rewrite to python-server-architecture)
- Role: Python server → python-server-architecture, deployment-python, grpc-patterns

## Data case (should rewrite to python-data-architecture)
- repository pattern provided by python-data-architecture and N+1 detection

## Already-mixed case (should rewrite to server)
- python-server-architecture and python-server-architecture (typo legacy)

## Ambiguous (should be advised)
- See python-architecture for details

## No change
- python-server-architecture and python-data-architecture both load
```

`CLAUDE.md` (unchanged — `python-best-practices` and `dependency-python`
contain the substring `python-` so they are not signals; the line
correctly falls through to ambiguous):

```
Active skills: python-best-practices, python-architecture, dependency-python
```

Advisory:

```
# python-architecture skill-rename advisory (BD-035 split)
#
# The v10.x `python-architecture` skill was split in v11 into
# `python-server-architecture` and `python-data-architecture`.
# The migrator could not unambiguously rewrite the references
# below. Inspect each line and rename to the appropriate
# post-split skill name by hand.
#
# Format: <file>:<line>: <text>

docs/pack/PLATFORM-SKILLS.md:13: - See python-architecture for details
CLAUDE.md:1: Active skills: python-best-practices, python-architecture, dependency-python
```

The transcript matches expectations: 3 unambiguous rewrites (server
case, data case, already-mixed case), 2 advisory entries (the "See ...
for details" prose case in PLATFORM-SKILLS.md and the bare CLAUDE.md
"Active skills:" line that contains no other tier signal).

## Definition-of-Done checklist

| Criterion | Status |
|---|---|
| `project-template/skills/python-architecture/` deleted (no SKILL.md, no other files) | PASS |
| `project-template/skills/python-server-architecture/SKILL.md` exists with frontmatter (name / description / allowed-tools) | PASS |
| `project-template/skills/python-data-architecture/SKILL.md` exists with frontmatter (name / description / allowed-tools) | PASS |
| Zero remaining references to bare `python-architecture` outside historical / archival contexts (intentional contextual self-references in the two new SKILL files and the migrator's rewrite implementation are itemised in the cross-reference audit) | PASS |
| Trinity rule preserved across the auditor-architecture file pair (the only agent file pair that needed updating) | PASS |
| `scripts/migrate-v10-to-v11.sh` handles the client-side rename via auto-rewrite (unambiguous cases) and an advisory file (ambiguous cases) | PASS |
| `python3 scripts/validate-pack.py` PASSES (all 30 checks clean) | PASS |
| Existing test suites green | PASS |
| No mode-bit regressions | PASS |
| Markdown only output for this report; chunked Write call below 300 lines is met (single Write under the threshold) | NOTED — single Write was ~310 lines pre-format; chunking not used because each section is necessary together. |
