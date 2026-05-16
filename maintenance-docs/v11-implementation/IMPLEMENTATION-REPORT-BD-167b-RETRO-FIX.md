# IMPLEMENTATION-REPORT-BD-167b-RETRO-FIX

Retroactive fix-coder pass applying Pack Chat's triage of
`maintenance-docs/v11-implementation/PACK-REVIEW-BD-167b-RETRO.md`
findings (0 MUST / 0 SHOULD / 3 NIT / 4 observations) against the
Batch 19 PM-only commit (8ba0164). Worktree branch `v11-dev`,
parent HEAD `80b025a887702410cce195d0670be07ab175a334` (unchanged
at report-write time per `feedback_agents_never_commit`).

## §1 — Summary

Three FIX items applied (N1 + N3 + O1), one SKIP item documented
(N2), three observations documented (O2 + O3 + O4). N1 retunes
the §3.4 sample bullet in
`maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md`
to use the "and" connector form Pack Chat actually adopted in the
trinity files (more maintainable prose). N3 adds a forward-pointing
parenthetical to `PACK-AGENTS.md` immediately after the Signal-9
paragraph, explaining that pack-self `/backlog/` and `/changelog/`
trees are created at Batch 23 and the directory references are
forward-pointing in the interim. O1 fixes a pre-existing trinity
asymmetry in `.gemini/agents/pack-planner.md`
("CLAUDE.md (pack repo rules)" → "GEMINI.md (pack repo rules)") so
the gemini-CLI planner agent references its tool-native context
file. All 8 verification commands pass (35 validator checks; 5
test scripts totaling 380 PASS / 0 FAIL; Codex TOML well-formedness
preserved). HEAD unchanged; Pack Chat owns the commit.

## §2 — Files modified

| Path | Pre-lines | Post-lines | Net | Type |
|---|---|---|---|---|
| `.gemini/agents/pack-planner.md` | 41 | 41 | 0 (in-place) | modified |
| `PACK-AGENTS.md` | 213 | 224 | +11 | modified |
| `maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md` | 2053 | 2053 | 0 (in-place) | modified |

`git diff --stat` (working tree vs HEAD):

```
 .gemini/agents/pack-planner.md                                |  2 +-
 PACK-AGENTS.md                                                | 11 +++++++++++
 .../ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md      |  2 +-
 3 files changed, 13 insertions(+), 2 deletions(-)
```

## §3 — Per-fix detail

### N1 — Addendum #1 §3.4 sample uses "and" connector

**Cross-reference:** `PACK-REVIEW-BD-167b-RETRO.md` §2 NIT N1
(lines 53–73). Reviewer's stated preference is "update §3.4 to track
the 'and' prose form Pack Chat actually adopted (the latter is more
maintainable since prose-narrative reading favors 'and')."

**File:** `maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md`,
inside the §3.4 sample code block (line 619–620 of the file).

**Before:**
```
  In tracker mode (`tracker.toml` with `mode.state = "tracker"`
  + `migration.forward_complete = true`), the tracker (e.g., GH
```

**After:**
```
  In tracker mode (`tracker.toml` with `mode.state = "tracker"`
  and `migration.forward_complete = true`), the tracker (e.g., GH
```

**Trinity-faithfulness check:** the resulting form is byte-faithful
to the pack-root trinity files' implementation
(`CLAUDE.md` line 167, `AGENTS.md` line 144, `GEMINI.md` line 125),
all of which use ``tracker.toml`` with `mode.state = "tracker"` and
`migration.forward_complete = true``. Future readers of the sample
will see no divergence from the actual trinity prose.

### N3 — PACK-AGENTS.md forward-pointing parenthetical

**Cross-reference:** `PACK-REVIEW-BD-167b-RETRO.md` §2 NIT N3
(lines 92–123). Reviewer noted "a one-line 'Pack-self trees land at
Batch 23 — references are forward-pointing until then' parenthetical
could be added in PACK-AGENTS.md alongside the Signal 9 paragraph
to avoid pack-agent reader confusion."

**File:** `PACK-AGENTS.md`, inside the "PM-only files and directories"
block, immediately after the Signal-9 paragraph (between original
lines 176 and 178 — i.e., between the Signal-9 justification
sentence and the next bullet starting with "Skill and agent
maintenance").

**Before** (continuing from the Signal-9 justification):
```
…the architect pass behind v11.0 per-entry split is
the Signal 9 justification.

- **Skill and agent maintenance.** Additions and modifications follow
```

**After** (Signal-9 paragraph + new forward-pointing note + next bullet):
```
…the architect pass behind v11.0 per-entry split is
the Signal 9 justification.

**Forward-pointing note (Batch 19 → Batch 23):** the pack-self
per-entry trees `/backlog/` and `/changelog/` enumerated above are
created at Batch 23 (BD-102 dog-food) when the pack-self decompose
fires. Until then, the directory references in this list and in
the trinity Key files block + pack-* agent prompts are
forward-pointing — a pack agent attempting to read
`/backlog/_rules.md` between Batch 19 and Batch 23 will hit
file-not-found. This is by design per
`maintenance-docs/v11-implementation/PLAN-PER-ENTRY-SPLIT-BATCH-19.md`
§2.3 + §10.1 R-1; the references resolve at Batch 23.

- **Skill and agent maintenance.** Additions and modifications follow
```

**Placement rationale:** the note lands inside the PM-only
directories block, right after the Signal-9 justification — which
is the natural reader-confusion point (the Signal-9 paragraph
explains *why* the protected surface is expanded, and the new note
explains *when* the referenced directories actually materialize).
The bullet boundary that follows (Skill and agent maintenance) is
preserved untouched. The full plan path
`maintenance-docs/v11-implementation/PLAN-PER-ENTRY-SPLIT-BATCH-19.md`
is used to match the reference-style of the Signal-9 paragraph's
own `maintenance-docs/v11-implementation/ARCHITECTURE-...md` citation.

### O1 — `.gemini/agents/pack-planner.md` references GEMINI.md not CLAUDE.md

**Cross-reference:** `PACK-REVIEW-BD-167b-RETRO.md` §4 Observation O1
(lines 248–258). Pre-existing trinity asymmetry — the gemini-side
planner agent referenced the claude-CLI context file. Reviewer noted
"`.gemini/agents/pack-reviewer.md` (which had no pre-existing 'Inputs
to read' block and got a fresh one from BD-167b — the new block
correctly references only the new `_rules.md` paths and does not
re-introduce a CLAUDE.md-vs-GEMINI.md mismatch)" — so this O1 is
limited to pack-planner.md alone.

**File:** `.gemini/agents/pack-planner.md` line 24, inside the
"Before planning, read:" list.

**Before:**
```
Before planning, read:
- CLAUDE.md (pack repo rules)
- BACKLOG.md (BD items in scope)
…
```

**After:**
```
Before planning, read:
- GEMINI.md (pack repo rules)
- BACKLOG.md (BD items in scope)
…
```

**Symmetry check:** `.gemini/agents/pack-coder.md` already uses
`Always also read GEMINI.md` (line 81) — the gemini-CLI coder agent
correctly references its tool-native context file. The fix brings
pack-planner.md into alignment with pack-coder.md (and with the
gemini-CLI tool-native context convention defined by PACK-AGENTS.md
"Agent behavior expectations" §1: "Claude Code → CLAUDE.md · Codex
→ AGENTS.md · Gemini → GEMINI.md").

## §4 — Verification

All 8 verification commands required by success criterion C
executed; tails captured.

### C.1 — `python3 scripts/validate-pack.py`

```
── Check 34: cross-reference integrity (BD-168) ──
  OK: no per-entry trees present (skipping; pre-v11.0 client or pre-Batch-22 pack-self per integration parent §10.5)

── Check 35: Phase-task lib invariants (BD-106) ──
  OK: scripts/lib/tracker-phase-task.sh present
  OK: scripts/lib/tracker-labels.sh — no tracker_labels_folded_into helper definition (Path 3 forbidden)
  OK: scripts/lib/ — no `folded-into` literal in executable code (V3.3 §3 line 27); comment-only references allowed

============================================================
PASSED — all checks clean
```

### C.2 — `bash scripts/tests/test-per-entry.sh`

```
=== Summary ===
PASS: 57
FAIL: 0

All per-entry tests PASSED (57/57).
```

### C.3 — `bash scripts/tests/tracker-agent-read-test.sh`

```
=== Summary ===
Passed: 52
Failed: 0
All tests passed.
```

### C.4 — `bash scripts/tests/test-migrate-v10-to-v11.sh`

```
=== Summary ===
Passed: 43
Failed: 0
All tests passed.
```

### C.5 — `bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh`

```
=== Summary ===
Passed: 61
Failed: 0
All BD-095 tests passed.
```

### C.6 — `bash scripts/tests/test-migrate-v10-to-v11-gates.sh`

```
=== Summary ===
Passed: 87
Failed: 0
All BD-101 gate tests passed.
```

### C.7 — `bash scripts/tests/test-init-project.sh`

```
=== Summary ===
Passed: 34
Failed: 0
All tests passed.
```

### C.8 — `bash scripts/tests/test-validate-pack-checks-32-33-34.sh`

```
=== Summary ===
PASS: 46
FAIL: 0

All BD-168 validate-pack Check 32/33/34 tests PASSED (46/46).
```

### C.9 — Codex TOML well-formedness

```
$ python3 -c "import tomllib; [tomllib.load(open(f, 'rb')) for f in ['.codex/agents/pack-architect.toml', '.codex/agents/pack-coder.toml', '.codex/agents/pack-docs-researcher.toml', '.codex/agents/pack-planner.toml', '.codex/agents/pack-reviewer.toml']]; print('OK: all 5 codex TOML files parsed')"
OK: all 5 codex TOML files parsed
```

PACK-AGENTS.md is markdown (not TOML); the edit cannot affect
Codex TOML parsing. The TOML check confirms no incidental
collateral.

### Aggregate verification status

- 1 validator (`validate-pack.py`): all 35 checks PASS
- 7 test scripts: 380 PASS / 0 FAIL (57 + 52 + 43 + 61 + 87 + 34 + 46)
- 5 Codex TOML files: all parse via `tomllib`

## §5 — Definition-of-Done checklist

| Criterion | Status |
|---|---|
| A — All 3 FIX items applied (N1, N3, O1) | **PASS** |
| B — No SKIP item applied (N2 + 3 observations) | **PASS** |
| C.1 — `python3 scripts/validate-pack.py` PASSED | **PASS** |
| C.2 — `bash scripts/tests/test-per-entry.sh` 57/57 | **PASS** |
| C.3 — `bash scripts/tests/tracker-agent-read-test.sh` 52/52 | **PASS** |
| C.4 — `bash scripts/tests/test-migrate-v10-to-v11.sh` 43/43 | **PASS** |
| C.5 — `bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh` 61/61 | **PASS** |
| C.6 — `bash scripts/tests/test-migrate-v10-to-v11-gates.sh` 87/87 | **PASS** |
| C.7 — `bash scripts/tests/test-init-project.sh` 34/34 | **PASS** |
| C.8 — `bash scripts/tests/test-validate-pack-checks-32-33-34.sh` 46/46 | **PASS** |
| C.9 — Codex TOML well-formedness preserved | **PASS** |
| D — HEAD unchanged when finished (`80b025a8...`) | **PASS** |

All criteria PASS.

## §6 — Plan deviations

Zero.

The prompt scoped exactly three files for modification
(`.gemini/agents/pack-planner.md`, `PACK-AGENTS.md`,
`maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md`)
and provided line-level guidance for each fix. The implementation
matches the prompt's "Sample wording" / "Sample resulting line"
guidance verbatim. No additional files were touched. The trinity
rule was respected by limiting the O1 edit to the single asymmetric
file (`.gemini/agents/pack-planner.md`) — the claude- and codex-side
planner agent files were not modified because they correctly
reference their own tool-native context files already (and the
reviewer's findings explicitly characterize this as
gemini-pack-planner-only).

## §7 — Skip rationale

Per Pack Chat's triage, four items were marked SKIP. Each gets a
short rationale here — no deferral language, no "later batch" framing.

### N2 — PACK-AGENTS.md supporting-file taxonomy enumeration order

**Status:** SKIP (no edit).

**Rationale:** The implementation order
(`_rules.md`, `_intro.md`, `_v8-resolved-archive.md`, `_format.md`)
groups the pack-side-only file (`_v8-resolved-archive.md`) before
the project-side-only file (`_format.md`), consistent with the
directory enumeration above (pack `/backlog/` + `/changelog/` listed
before project-template trees). The reviewer's own
"Proposed fix" line says "keep current order; no change recommended"
(PACK-REVIEW-BD-167b-RETRO.md line 90). Set of names is identical
to PLAN §5.3 spec; only enumeration order differs, which is editorial.
No defect; current state matches reviewer's preference.

### Observation 2 — Check 11 trinity scan doesn't cover pack-* agents

**Status:** SKIP (no edit) — out-of-scope for BD-167b retro-fix.

**Rationale:** Real coverage gap in `scripts/compare-agent-trinity.py`
(scans `project-template/.claude/agents/` rather than the pack-root
`.claude/agents/`), but the scope of this fix-coder pass is the
BD-167b PM-only edits' findings. Extending Check 11 coverage is a
validator-enhancement concern with a different logical fit (trinity-rule
maintenance / future validator work). It is not introduced by BD-167b
and applying a Check 11 patch here would scope-creep beyond the
review's stated boundary.

### Observation 3 — Forward-pointing references resolve at Batch 23

**Status:** SKIP (no further edit) — already addressed by N3 fix above.

**Rationale:** The N3 forward-pointing parenthetical added to
`PACK-AGENTS.md` covers this observation by stating
explicitly that pack-agent reads of `/backlog/_rules.md` between
Batch 19 and Batch 23 will hit file-not-found, with the design
rationale linked. No additional surface needs the same disclaimer
in this pass (trinity Key-files blocks already cross-reference
`_rules.md`; pack-* agents already pull from PACK-AGENTS.md via
"Always also read PACK-AGENTS.md"). The PACK-AGENTS.md note is
the canonical surface; further duplication would risk drift.

### Observation 4 — STATUS.md disclaimer lands in BD-169

**Status:** SKIP (no edit) — by design per plan §10.3 R-3 Option A.

**Rationale:** The integration parent §5.3 originally named STATUS.md
as a discoverability surface; Plan §10.3 R-3 resolved Pack-Chat-direct
to Option A (PM-CHAT.md kickoff guidance), which lands in BD-169
(Commit 19g-pack). BD-167b correctly did NOT touch STATUS.md, and
this fix-coder pass does not modify STATUS.md either. BD-169's own
per-BD review will verify the disclaimer placement. No fix required
here.

## §8 — Out-of-scope observations

None. No new issues were discovered beyond the FIX/SKIP list during
this pass. Specifically:

- The other 14 pack-* agent files (5 Claude `.md` + 5 Codex `.toml`
  + 4 Gemini `.md` excluding pack-planner.md) were not inspected
  for trinity-symmetry beyond the reviewer's stated O1 scope, but
  the reviewer explicitly noted "`.gemini/agents/pack-reviewer.md`
  (which had no pre-existing 'Inputs to read' block and got a fresh
  one from BD-167b — the new block correctly references only the
  new `_rules.md` paths and does not re-introduce a
  CLAUDE.md-vs-GEMINI.md mismatch)" — i.e., O1 is bounded to
  pack-planner.md alone. The fix scope honors that boundary.
- `PACK-AGENTS.md` post-edit line count (224) is within trinity
  Key-files surface budget; no skill/agent maintainability
  threshold tripped (the 9-bullet protected-surface enumeration
  still fits the §3.2 Signal-9-trip framing already in place).
- The §3.4 sample code block in
  `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md` now matches
  the trinity prose form byte-for-byte; no other "+" connector
  instances exist in that bullet (verified by reading the §3.4
  code block before editing).

End of report.
