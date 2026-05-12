# Implementation Report — BD-117

**BD:** BD-117 — `RELEASE-GATE.md` per-major-version checklist
**Batch:** Phase 3.5 Batch 4 (first half; pairs with BD-118 second half)
**Branch:** `v11-dev`
**Pre-flight HEAD:** `4e2778554d8544ff722126ab261910e640c38ba0`
**Final HEAD on this worktree:** `4e2778554d8544ff722126ab261910e640c38ba0`
  (no commits made — agents do not commit; Pack Chat applies / commits)
**Agent:** `pack-coder`
**Date:** 2026-05-12

---

## 1. Pre-flight state

Verified before any edits:

- `git rev-parse HEAD` → `4e2778554d8544ff722126ab261910e640c38ba0`.
- `git status --short` → only the 7 `??` `maintenance-docs/v11-research/`
  entries from the user's parallel research chat. None overlap this
  task's scope. Untouched.
- `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md` present;
  §1.1 BD-117 entry confirms scope; §4 Batch 4 row confirms target file
  + sequencing (BD-117 first commit, BD-118 second).
- `BACKLOG.md` BD-117 entry confirms 5-item gate scope (lines
  1161-1175); `Status: Open`.
- All five items' referenced infrastructure verified present on this
  HEAD:
  - `scripts/migrate-v10-to-v11.sh` exists and declares
    `MIGRATOR_FROM_VERSION="v10"` / `MIGRATOR_TO_VERSION="v11"` /
    `MIGRATOR_BASELINE_TAG="${V10_TAG:-v10}"` (lines 73-75 — confirms
    BD-119 framework adoption that item 1 references).
  - `scripts/dry-run-migration.sh` exists (BD-114 harness item 2 uses).
  - `scripts/test-persona-contracts.sh` exists; emits
    `Persona contract summary: N/N passed` and
    `All persona contracts PASS.` (item 3 pass criterion).
  - `test-fixtures/build.sh --verify` exists (item 5).
  - `.github/workflows/validate-pack.yml` exists (item 4).
- `scripts/lib/migrator-core.sh` and `migrator-skills.sh` present
  (BD-119/BD-147 framework that item 1 attests).
- Baseline `python3 scripts/validate-pack.py` → `PASSED — all checks
  clean` (31 checks).

No working-tree mutations from PM-only files; no v11-research
directory touched.

---

## 2. Document structure rationale

The doc follows the suggested structure from the prompt with one
deliberate adjustment in §4 (Maintenance) to enforce the "five items
only" rule from the BD-117 spec.

**Header block** — title + one-line purpose + `Last updated:` line.
The `Last updated:` line is the explicit maintenance hook §4 calls out.

**§1 Purpose** — one-paragraph why-this-exists, with explicit pointer
that the release-pin BD records evidence per item. Anchors the gate's
authority: it is the checklist a release-pin BD must satisfy, not
guidance.

**§2 When to run** — covers the major-version triggering condition
(BD-093 for v11.0, analogue for v12.0+), the run-order guidance (which
items are working-tree state vs. command-driven), the sign-off
mechanism, and the explicit boundary against the per-batch CI gates and
the milestone-audit / dog-food gates that run earlier in the release
sequence (per EXECUTION-PLAN §7). Prevents future maintainers from
confusing "did the audit pass?" with "did the release gate pass?".

**§3 Gate items** — five subsections, one per item, each with a fixed
shape:
- Bold short heading naming the gate.
- "Asserts:" — the one-paragraph plain-English statement of what
  passing means.
- "Commands to run:" — fenced bash block, copy-pasteable, with
  `<N>`/`<N+1>` placeholders where the command text varies per major.
- "Pass criterion:" — bullet list of concrete observable outcomes
  (exit code, stdout substring, file presence).
- "Common failure mode:" — one paragraph naming the most likely
  reason this gate fails and the standard remediation.

The fixed shape means BD-118 can mechanically lift the
"Commands to run" blocks for items 3, 4, 5 into CI step descriptions
(items 1 and 4 are not CI-suitable: item 1 is a one-shot pre-tag check
that's strictly working-tree state, and item 4 is the CI workflow
itself — it can't be a CI step that watches itself).

**§4 Maintenance** — locks the five-item count (per the BD-117 spec's
"five items only — don't add or remove" constraint), explicitly
labels which items are order-sensitive (1, 4, 5) and which are
order-independent (2, 3), and specifies the `Last updated:` line
discipline. This section enforces the pack-memory rule that any
expansion of the gate is a structural change requiring
architect+planner sign-off.

**§5 Cross-references** — explicit BD-NNN anchors back to the
authoritative BACKLOG entries (BD-117 itself, BD-093, BD-118, BD-114,
BD-115, BD-116, BD-119) plus the EXECUTION-PLAN §7 boundary and the
per-major MIGRATION doc that defines item 2's "expected diff shape."
Every cross-ref names the BD plus the specific file/path the BD
shipped, so the reader can navigate without re-reading BACKLOG.

**Style consistency** — matches `supporting-docs/MIGRATION-v10-to-v11.md`
and `supporting-docs/MERGE-STRATEGY.md` conventions: H1 title +
single-sentence subtitle, `---` between top-level sections, fenced
bash blocks for commands, bullet lists for criteria, terse
single-paragraph "Common failure mode" entries.

---

## 3. Gate items — exact commands and pass criteria as written

### Item 1 — Per-version migrator uses the BD-119 framework

**Commands:**

```bash
test -x scripts/migrate-v<N>-to-v<N+1>.sh
grep -q 'scripts/lib/migrator-core.sh' scripts/migrate-v<N>-to-v<N+1>.sh
grep -E '^MIGRATOR_(FROM_VERSION|TO_VERSION|BASELINE_TAG)=' \
    scripts/migrate-v<N>-to-v<N+1>.sh
```

**Pass criterion:** script exists + executable; sources
`migrator-core.sh`; declares the three required `MIGRATOR_*` env vars.

### Item 2 — BD-114 dry-run against real OT

**Commands:**

```bash
bash scripts/dry-run-migration.sh "$OT_URL" --report-out /tmp/release-gate-dry-run.md
```

**Pass criterion:** exit `0`; report shows clean migrator completion;
maintainer signs off on diff matching the per-major MIGRATION doc's
expected shape.

### Item 3 — All three persona contracts pass

**Commands:**

```bash
bash scripts/test-persona-contracts.sh
```

**Pass criterion:** exit `0`; stdout contains
`Persona contract summary: 3/3 passed` followed by
`All persona contracts PASS.`; all three contract names under `PASS:`,
no `FAIL:` block.

### Item 4 — BD-118 CI workflow green on the release commit

**Commands:**

```bash
RELEASE_SHA=$(git rev-parse HEAD)
gh run list --workflow=validate-pack.yml --commit="$RELEASE_SHA" \
    --json status,conclusion,name,headSha
```

**Pass criterion:** at least one run with `headSha == $RELEASE_SHA`,
`status == "completed"`, `conclusion == "success"`; both the
`validate` and `tests` jobs report success.

### Item 5 — Fixture verify passes against committed manifest

**Commands:**

```bash
bash test-fixtures/build.sh --verify
```

**Pass criterion:** exit `0`; every fixture line `OK: <sha>`; no
`MISMATCH` lines; no `not built` warnings on fixtures expected to be
present.

---

## 4. Verification

### 4.1 Validator

```
$ python3 scripts/validate-pack.py
...
PASSED — all checks clean
```

All 31 checks PASS. No regression. (Doc-only batch — no code path
changed.)

### 4.2 File-shape sanity

- `wc -l maintenance-docs/v11-implementation/RELEASE-GATE.md` → 263 lines (within the
  prompt's "should not exceed 300 lines" guidance; terse checklist).
- Markdown structure: 1 H1, 5 H2 (`§1`..`§5`), 5 H3 under §3 (one per
  gate item) — matches the prompt's recommended structure.
- Single Write call (no chunking needed at 263 lines).

### 4.3 Cross-reference well-formedness

Manually walked every BD-NNN cited in §5 against `BACKLOG.md`:

| BD       | In BACKLOG | Status (at this HEAD)     |
|----------|------------|---------------------------|
| BD-093   | yes        | Open (release-pin)        |
| BD-114   | yes        | Resolved                  |
| BD-115   | yes        | Resolved                  |
| BD-116   | yes        | Resolved                  |
| BD-117   | yes        | Open (this BD)            |
| BD-118   | yes        | Open (next batch)         |
| BD-119   | yes        | Resolved                  |

Every referenced file path verified present on this HEAD (`scripts/`,
`test-fixtures/`, `.github/workflows/`, `scripts/lib/`,
`scripts/persona-contracts/`, `maintenance-docs/v11-implementation/`).

---

## 5. POQs

**None.** The BD-117 spec was unambiguous on the five-item scope, and
all referenced infrastructure exists at this HEAD. No new questions
surfaced during authoring.

---

## 6. Plan deviations

**None.** Five items, single new doc at the path the spec named,
read-only on every other file, validator clean, line count under cap.

---

## 7. Files changed

| Path                                                         | Change | Lines |
|--------------------------------------------------------------|--------|------:|
| `maintenance-docs/v11-implementation/RELEASE-GATE.md`                           | NEW    | 263   |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-117.md` | NEW    | (this report) |

No other files in the working tree modified by this agent. The 7
`??` entries under `maintenance-docs/v11-research/` are untouched
user-side parallel work.

---

## 8. Definition of Done

| #  | Criterion                                                                 | Result |
|----|---------------------------------------------------------------------------|--------|
| 1  | `maintenance-docs/v11-implementation/RELEASE-GATE.md` exists, well-formed markdown.          | PASS   |
| 2  | Every gate item has a concrete command + concrete pass criterion.          | PASS   |
| 3  | BD-118 (next batch) can lift item-3 / item-4 / item-5 commands into CI.   | PASS   |
| 4  | BD-093 (release-pin) can use this doc as the gating list.                 | PASS   |
| 5  | `python3 scripts/validate-pack.py` returns PASS for all 31 checks.        | PASS   |
| 6  | No edits outside `RELEASE-GATE.md` + this report.                          | PASS   |
| 7  | `maintenance-docs/v11-research/` untouched.                                | PASS   |
| 8  | Five gate items only — not four, not six.                                  | PASS   |
| 9  | `<N>`/`<N+1>` placeholders used; v11.0-specific examples explicitly labeled. | PASS |
| 10 | No state-changing git verbs run by this agent.                             | PASS   |
| 11 | Trinity rule N/A (no trinity files touched).                               | PASS   |

---

## 9. BD-159 §3.1 mechanical-edit sanity check

The BD-117 work adds **one new top-level doc** in `maintenance-docs/`
(`RELEASE-GATE.md`).

`maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md`
§3.2 condition 5 ("New top-level doc") classifies this as a
**structural** change because `RELEASE-GATE.md` is not one of the
exempted workflow-artifact patterns (`ARCHITECTURE-*.md`, `PLAN-*.md`,
`IMPLEMENTATION-REPORT-*.md`, `PACK-REVIEW-*.md`, `AUDIT-*.md`,
`RESEARCH-*.md`, `*-DISCOVERY.md`).

**Disposition: structural-with-prior-architect-approval.** The work is
authorized in the v11 plan via:

- `BACKLOG.md` BD-117 entry (Status: Open, scope explicit, file path
  named).
- `EXECUTION-PLAN-V11.0.md` §1.1 Group 1 BD-117 listing.
- `EXECUTION-PLAN-V11.0.md` §4 Batch 4 row naming
  `maintenance-docs/v11-implementation/RELEASE-GATE.md (NEW)` as the first commit's
  target file.

This is the documented architect+planner pass that §3 of the
maintainability arch requires for structural changes. The new doc is
an authorized one-time artifact, not a slip in the mechanical-edit
discipline. No additional architect pass is needed.

`maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-117.md`
(this report) is itself an `IMPLEMENTATION-REPORT-*.md` workflow
artifact — exempted by §3.1 condition 6 / §3.2 condition 5.

---

## 10. Hand-off notes for Pack Chat

- Stage exactly two files for the BD-117 commit:
  `maintenance-docs/v11-implementation/RELEASE-GATE.md` and
  `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-117.md`.
  Do not stage anything in `maintenance-docs/v11-research/` (parallel
  user work).
- Suggested commit message (per CLAUDE.md format):
  `feat: v11 — BD-117 RELEASE-GATE.md per-major-version pre-tag checklist (Batch 4 first-half)`.
- BD-117 status flip to `Resolved` per the implicit-status-flip rule
  is appropriate after BD-118 (Batch 4 second-half) lands clean and
  the batch's review/fix cycle is green — not as part of this commit
  in isolation. (Or per Pack Chat's normal cadence.)
- BD-118 (next commit in this batch) will reference RELEASE-GATE.md
  from CI step descriptions; the item 3 / item 4 / item 5 command
  blocks above are CI-liftable as-is.
