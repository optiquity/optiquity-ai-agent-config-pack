---
title: RESEARCH-PER-ENTRY-SPLIT-ADDENDUM
status: fact-finding-only
parent: RESEARCH-PER-ENTRY-SPLIT.md
audience: pack-architect (next), v11-implementation reviewer
date: 2026-05-13
---

# Per-entry split — research addendum

Follow-up to `RESEARCH-PER-ENTRY-SPLIT.md` (approved-with-followups by the
v11-implementation chat's reviewer). Addresses 7 tightening suggestions
plus 5 factual open questions. Same constraints apply: read-only,
fact-only, file:line citations everywhere, pack/project boundary
preserved, V3.x cited not analyzed, `maintenance-docs/archive/v11/*`
and `maintenance-docs/v11-research/ARCHITECTURE.md` not read.

---

## §1 — Reading-order pointer (closes suggestion 3.1)

Start with these four citations from the original §1 grid; together they
cover (a) when per-entry decomposition becomes load-bearing, (b) the
authoritative grammar for BACKLOG entries, (c) the identifier scheme,
and (d) the reverse-emission contract:

- `ARCHITECTURE-V3.md` §28.1 "OQ-19 — inflection-point signals and
  thresholds" — lines 566–1032 (verified: `### 28.1` heading at line 566;
  `### 28.2` heading at line 1033 begins the next sub-section).
- `ARCHITECTURE-V3.1-DELTA.md` §3 "Decision: §4.2 BACKLOG format drift
  in reverse migration — picked A2" — lines 180–255 (verified: `## §3`
  heading at line 180; `## §4` heading at line 256).
- `ARCHITECTURE-V3.3-DELTA.md` §6.4 "Identifier scheme summary" —
  lines 360–370 (corrected from reviewer's cited 361–370: `### §6.4`
  heading is at line 360; `### §6.5` heading at line 371).
- `maintenance-docs/v11-research/IMPLEMENTATION-PLAN.md` §1.4
  "Migration: reverse (D-3, D-8) — mandatory" — lines 167–209
  (verified: `### §1.4` heading at line 167; `### §1.5` heading at
  line 210).

---

## §2 — §3 architect orientation note (closes suggestion 3.2)

OT data is included as cross-check for tracker-side forward/reverse
migration contracts. Per-entry decomposition is fundamentally a
pack-side design question; OT shapes are informative but not
load-bearing.

---

## §3 — Compressed §3 alternative (closes suggestion 3.3)

The original report's §3 spans lines 258–452. Reviewer indicated that
the OT `IMPLEMENTATION_PLAN.md` H2 phase listing (original lines
357–371) and the OT `CHANGELOG.md` sample entry (original lines
425–448) can each compress to one sentence plus a line-range pointer;
the phase-task structure block (original lines 372–401) retains the
detail needed for tracker forward-parser cross-check.

Drop-in replacement (the architect can substitute this block for the
original §3 in full):

```markdown
## §3 — Project-side current state (OT as v10.1 client reference, compressed)

OT files live under `docs/project/` (not at root). `find` resolves:
- `/Users/david/Developer/OptiquityTrader/docs/project/BACKLOG.md` (1,478 lines)
- `/Users/david/Developer/OptiquityTrader/docs/project/IMPLEMENTATION_PLAN.md`
  (5,235 lines; underscore — v10.x naming)
- `/Users/david/Developer/OptiquityTrader/docs/project/CHANGELOG.md` (2,579 lines)

### `docs/project/BACKLOG.md`

Partitioned by phase (one H2 per `## Phase NN — <title>`; `## How to
use this file` mid-file at line 485; full H2 list verifiable via
`grep -n '^## '`). TD entries carry `Type:` / `Status:` / `Blockers:`
/ `Unblocks:` / `File/Symbol:` / `Description:` / `Context:` /
`Resolution:` (when Resolved); bold-header line ends in
`✅ RESOLVED (Phase NN)` for Resolved entries. Lifecycle states
observed: `Open`, `Resolved`. Sample at lines 13–21 (TD-001).
V3.3-DELTA §5.3 (lines 256–279) admits `phase-N`, `phase-N.M`,
`TD-NNN`, `BD-NNN` in `Blockers:`.

### `docs/project/IMPLEMENTATION_PLAN.md`

Organized by `## Phase NN — <title>` H2 (full list via `grep -n
'^## '` returns Phase 0..28+ across the file; 5,235-line span).
Each phase has `**Goal**`, `**Prerequisite**`, `---`, then
`### Tasks` containing `#### N.M — <task title>` sub-headings, then
`### Verification`, `### Agent`, `### Risks` H3 sections.

**Phase-task structure (load-bearing — preserved verbatim from
original §3):** Sample from Phase 0 (lines 45–106 partial):

  ### Tasks

  #### 0.1 — `StrategyLogic` Protocol Replacement

  - **What**: Replace the `execute(context:)/shutdown(context:)`
    contract with the event/command model from §2n:

    1. In `Domain/Protocols/StrategyLogic.swift`:
       - Remove `func execute(context: StrategyExecutionContext) async throws`
       […]
  - **Dependencies**: None.

Subsequent tasks at 0.2 (line 109), 0.3 (line 134), 0.5 (line 192),
0.6 (line 213), 0.7 (line 252) each carry `- **What**:` …
`- **Dependencies**: <list>`. Task identifier convention `#### <phase>.<task>
— <title>` matches V3.2 §4.1 / V3.3-DELTA §4.1 forward-parser regex
contract.

### `docs/project/CHANGELOG.md`

Append-only, date-descending. Single H2 (`## Format Rules` at line 7);
remaining file is H3-organized version/phase entries. Format spec
inlined at lines 7–39 (entry-format fenced block lines 13–28; rules
30–39). Sample entry per Format Rules layout: `### YYYY-MM-DD —
Phase N — Title` heading + `**Summary**:` body + `**Tasks completed**:`
list + `**Backlog items addressed**:` line + `**Files created**:` /
`**Files modified**:` lines + `**Test count**:` / `**Build warnings**:`
trailers; representative entry at lines 43–67.
```

---

## §4 — BD-104 ordering paragraph (closes suggestion 3.4, Gap C)

BD-104 is scheduled in `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md`
§4 (the 23-batch plan; H2 `## 4. Batch plan (23 batches)` at line 219) as
Batch 12, a single atomic commit (line 265: `| **12** | atomic pack-coder
| BD-104 | cross-pack rename \`IMPLEMENTATION_PLAN.md\` →
\`IMPLEMENTATION-PLAN.md\` (large blast radius) | Single commit, atomic
|`). The rename itself executes from inside `migrator_post_dispatch_hook`
in the v10→v11 adapter: `migrator_core.sh` defines the optional hook at
`scripts/lib/migrator-core.sh:222` (`if declare -F
migrator_post_dispatch_hook >/dev/null 2>&1; then`), and the v10→v11
adapter defines the hook body at `scripts/migrate-v10-to-v11.sh:134-149`,
calling `_v10_to_v11_rename_implementation_plan` (line 144 of that file)
whose body sits at `scripts/migrate-v10-to-v11.sh:167-219`. Per-entry
decomposition touching `IMPLEMENTATION-PLAN.md` faces a temporal
collision with the BD-104 rename: BD-104 is the point at which the
filename changes from `IMPLEMENTATION_PLAN.md` (v10.x) to
`IMPLEMENTATION-PLAN.md` (v11.x), and any per-entry decomposition stage
that targets the file must run either before BD-104 (operating on the
underscore name) or after BD-104 (operating on the hyphenated name).

---

## §5 — Maintainability principle citation (closes suggestion 3.5, Gap B)

The maintainability principle lives in
`maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md`.
§3.2 "Structural signals — any one triggers an architect pass" is the
heading at line 274. Per §3.2 (lines 274–311), a change is structural
if any one of ten enumerated signals holds. The four signals the
reviewer cited:

- Signal 4 — "New validator check" at lines 285–287: "Any addition to
  `scripts/validate-pack.py` that introduces a new `check_*` function,
  regardless of triggering BD."
- Signal 5 — "New top-level doc" at lines 288–294: "Adding a new `.md`
  in pack root, `supporting-docs/`, `project-template/docs/`, or
  `maintenance-docs/v11-implementation/` that is not an
  `ARCHITECTURE-*.md` / `PLAN-*.md` / `IMPLEMENTATION-REPORT-*.md` /
  `PACK-REVIEW-*.md` / `AUDIT-*.md` / `RESEARCH-*.md` / `*-DISCOVERY.md`
  produced by the existing architect / planner / coder / reviewer /
  auditor / docs-researcher workflow."
- Signal 6 — "New script" at lines 295–297: "Adding a new top-level
  `scripts/*.sh` or `scripts/*.py` (helpers in `scripts/lib/` are not
  new scripts; they are library extensions)."
- Signal 8 — "Migrator behavior change" at lines 301–304: "Any change
  that requires a new migrator stage, a new manifest entry, or a new
  advisory file in `migrate-vN-to-vM.sh` — these touch BD-119 framework
  contracts (`maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md`)."

Per-entry decomposition is a structural change implicating signals 4
(any new `check_*` enforcing per-entry-file shape), 5 (any new
top-level doc outside the workflow-artifact extension list), 6 (any
new top-level `scripts/*.sh` / `scripts/*.py`), and 8 (any new
migrator stage / manifest entry).

---

## §6 — Read-shape change surface (closes suggestion 3.6, Gap A)

The wording surfaces below each treat the relevant stream file as a
single unit (read-the-whole-file or read-a-named-section). File:line
citations and ≤ 3-line quotes per surface:

### Pack-side

- `PACK-CHAT.md` file-access strategy table (table heading
  `## File access strategy` at line 38; column header at line 40):
  - Line 42: `| \`BACKLOG.md\` | Direct read | Open BD-NNN items, current backlog state |`
  - Line 43: `| \`CHANGELOG.md\` | Direct read (last entry only) | Current version and recent changes |`

  This wording reads the file as a single unit.

- `.claude/skills/pack-startup/SKILL.md` (Step 2 "Read core state files"
  heading at line 17):
  - Line 19: `Read \`BACKLOG.md\` in full.`
  - Line 21: `Read only the most recent dated entry from \`CHANGELOG.md\`.`

  This wording reads the file as a single unit.

- `.codex/skills/pack-startup/SKILL.md`:
  - Line 19: `Read \`BACKLOG.md\` in full.`
  - (`grep -nE "Read.*BACKLOG.*in full"` confirms identical directive.)

  This wording reads the file as a single unit.

- `.gemini/commands/pack-startup.toml`:
  - Line 16: `Read \`BACKLOG.md\` in full.`
  - Line 18: `Read only the most recent dated entry from \`CHANGELOG.md\`.`
  (Gemini surface lives in the commands TOML; there is no
  `.gemini/skills/pack-startup/` directory at pack root.)

  This wording reads the file as a single unit.

### Project-side

- `project-template/docs/pack/PM-CHAT.md` file-access strategy table
  (column header at line 117):
  - Line 119: `| \`BACKLOG.md\` | Direct read | Small, changes frequently, must always be current |`
  - Line 121: `| \`CHANGELOG.md\` | Direct read (last entry only) | Recent history only |`
  - Line 123: `| \`IMPLEMENTATION-PLAN.md\` | Direct read (current phase section only) | Full file is large |`

  This wording reads the file as a single unit (or a named section,
  for IMPLEMENTATION-PLAN.md).

- `project-template/skills/pm-startup/SKILL.md` (canonical source):
  - Lines 69–70: `- BACKLOG entries (resolve via the trinity \`##
    Document locations\` table; reads \`BACKLOG.md\` in flat-file mode,
    the tracker in tracker mode)`
  - Line 76: `Read only the most recent dated section from \`CHANGELOG.md\`.`
  - Line 79: `from \`IMPLEMENTATION-PLAN.md\`.`

  This wording reads the file as a single unit.

- `project-template/.claude/skills/pm-startup/SKILL.md` and
  `project-template/.codex/skills/pm-startup/SKILL.md`: per-CLI copies
  carry the same line-69 directive (`grep -n "Read.*BACKLOG\|BACKLOG
  entries"` confirms hit at line 69 in both).

  This wording reads the file as a single unit.

- `project-template/.gemini/commands/pm-startup.toml` (Gemini surface
  at this path):
  - Line 66: `- BACKLOG entries (resolve via the trinity \`## Document
    locations\` table;`
  - Line 73: `Read only the most recent dated section from \`CHANGELOG.md\`.`
  - Line 76: `from \`IMPLEMENTATION-PLAN.md\`.`

  This wording reads the file as a single unit.

---

## §7 — Compressed §8 function summary (closes suggestion 3.7)

### Forward — `scripts/lib/tracker-migrate-forward.sh`

- **Reads file as a unit:** `tmf_parse_backlog()` at line 268 reads the
  whole `BACKLOG.md` and emits a JSON array of all entries;
  `tmf_parse_implementation_plan()` at line 399 reads the whole
  `IMPLEMENTATION-PLAN.md` and emits a JSON phases array.
- **Reads file as a stream of entries:** none — the forward path
  operates on the JSON array produced by the unit-readers above
  (`tmf_compose_issue_body()` at line 459 takes a single parsed entry).
- **Writes the whole file:** `_tmf_regen_mirror()` at line 1172
  regenerates the `BACKLOG.md` mirror in place per V1 §6.3.

### Reverse — `scripts/lib/tracker-migrate-reverse.sh`

- **Reads file as a unit:** none — the reverse path consumes tracker
  state, not flat-file text.
- **Reads file as a stream of entries:** none — reverse reconstructs
  entries from tracker JSON, then composes them
  (`tracker_migrate_reverse_reconstruct()` at line 314 consumes one
  normalized Issue JSON).
- **Writes the whole file:** `_tmr_emit_backlog()` at line 409 emits
  the full `BACKLOG.md`; `_tmr_emit_implementation_plan()` at line 485
  emits the full `IMPLEMENTATION-PLAN.md` skeleton;
  `_tmr_emit_changelog()` at line 553 emits the full `CHANGELOG.md`
  skeleton; `_tmr_emit_status()` at line 514 emits the full
  `STATUS.md`. Output paths consolidated at lines 853–856 of the
  same file.

---

## §8 — Pack-side `## Resolved — vN` historical sections (factual 4.1.1)

Command run: `grep -n "^## Resolved" /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/BACKLOG.md`.

Output:
- `2248:## Resolved — v8 (March 2026)`

Total matches: 1. The v8 entry cited in the original §4 is the only
`## Resolved — vN` H2 in the pack-side `BACKLOG.md`. No other resolved-
section H2s exist in the file.

---

## §9 — CHANGELOG.md scope-bucket distribution (factual 4.1.2)

Command run: `grep -nE '^\*\*Scope' /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CHANGELOG.md`.

Output (3 matches):
- `12:**Scope A — Issue-tracker integration (D-1..D-23)**`
- `43:**Scope B — v11 version cut + ride-alongs**`
- `124:**Scope C — Skill-dimensions reframe (BD-141..BD-150 + BD-156..BD-159)**`

Version-block boundaries from `grep -n '^## ' CHANGELOG.md`:
- `## v11 — May 2026` at line 8
- `## v10 — April 2026` at line 269
- `## v9 — April 2026` at line 421
- `## v8 — March 2026` at line 465
- `## v7 — March 23, 2026` at line 621
- `## v6 — March 11, 2026` at line 641
- `## v5 — March 9, 2026` at line 660
- `## v4 — March 9, 2026` at line 676
- `## v3 — March 9, 2026` at line 691
- `## v2 — March 6, 2026` at line 705
- `## v1 — March 6, 2026` at line 723

Distribution: all three `**Scope X — ...**` headings fall inside the
`## v11 — May 2026` block (lines 8–268). Per-version scope-bucket count:

| Version H2 (line) | Scope buckets observed |
|---|---|
| `## v11 — May 2026` (line 8) | Scope A (line 12), Scope B (line 43), Scope C (line 124) |
| `## v10 — April 2026` (line 269) | none |
| `## v9 — April 2026` (line 421) | none |
| `## v8 — March 2026` (line 465) | none |
| `## v7 — March 23, 2026` (line 621) | none |
| `## v6 — March 11, 2026` (line 641) | none |
| `## v5 — March 9, 2026` (line 660) | none |
| `## v4 — March 9, 2026` (line 676) | none |
| `## v3 — March 9, 2026` (line 691) | none |
| `## v2 — March 6, 2026` (line 705) | none |
| `## v1 — March 6, 2026` (line 723) | none |

---

## §10 — IMPLEMENTATION-PLAN.md phase-entry sizes (factual 4.1.3)

`maintenance-docs/v11-research/IMPLEMENTATION-PLAN.md` is organized by
`## §N. <title>` Scope/§ sections, not by `## Phase NN`. H2 enumeration
from `grep -n '^## ' maintenance-docs/v11-research/IMPLEMENTATION-PLAN.md`
yields eight H2 sections. Line ranges and line counts:

| H2 line | Section name | Line range | Line count |
|---|---|---|---|
| 3 | `## §0. Status and conventions` | 3–21 | 19 |
| 22 | `## §1. Scope A — Issue-tracker integration BDs` | 22–544 | 523 |
| 545 | `## §2. Scope B — v11 version cut + ride-alongs` | 545–818 | 274 |
| 819 | `## §3. Cross-scope dependencies and sequencing` | 819–941 | 123 |
| 942 | `## §4. Verification strategy` | 942–1027 | 86 |
| 1028 | `## §5. Risks and rollback` | 1028–1051 | 24 |
| 1052 | `## §6. MAINTAINER CHECK NEEDED items` | 1052–1084 | 33 |
| 1085 | `## §7. Definition of v11.0 release-readiness` | 1085–1109 (END) | 25 |

Sub-section ("BD-task-like") granularity inside the large H2 sections
is `### §N.M` H3 (e.g. `### §1.1`, `### §1.2`, …); BD entries inside
each H3 use bold headers `**BD-NNN — <title>**`. Total BD entries in
the file (via `grep -cE '^\*\*BD-'`): 34. Per-section H3 + BD
distribution:

- §1 (Issue-tracker BDs, lines 22–544): 13 H3 sub-sections (§1.1
  through §1.13; `grep -n '^### §1\.'` returns 13 hits) containing
  the bulk of BD entries (BD-060..BD-083 cluster; first BD at line 26,
  last in §1 at line 529).
- §2 (Scope B BDs, lines 545–818): 7 H3 sub-sections (§2.1..§2.7);
  BD entries BD-084..BD-093 cluster (first BD at line 580, last at
  line 798).
- §3..§7: H3 sub-sections only (no BD entries inside them — these
  sections cover sequencing, verification, risks, etc.).

Typical BD-entry size (file-as-stream-of-entries view): BD-060 spans
lines 26–45 (20 lines); BD-063 spans lines 87–105 (19 lines);
BD-088 spans lines 740–768 (29 lines); BD-085 spans lines 601–619
(19 lines). The standard BD entry block in this file is approximately
15–30 lines.

---

## §11 — `.gemini/` references to entry files (factual 4.1.4)

### Pack-root `.gemini/`

Command run: `grep -nE 'BACKLOG|CHANGELOG|IMPLEMENTATION_PLAN|IMPLEMENTATION-PLAN' .gemini/agents/*.md .gemini/commands/*.toml`.

Output (8 matches across 5 files):
- `.gemini/agents/pack-architect.md:29: - BACKLOG.md (open BD items and their constraints)`
- `.gemini/agents/pack-planner.md:25: - BACKLOG.md (BD items in scope)`
- `.gemini/agents/pack-coder.md:36: modify BACKLOG.md, CHANGELOG.md, README.md version table, PACK-CHAT.md,`
- `.gemini/agents/pack-coder.md:40: **No BD status flips.** BACKLOG.md \`Status:\` flips happen post-review`
- `.gemini/agents/pack-reviewer.md:30: - **BACKLOG accuracy.** If the change resolves or modifies a BD item, verify`
- `.gemini/agents/pack-reviewer.md:31:   the BACKLOG entry is updated with the correct status and resolution.`
- `.gemini/commands/pack-startup.toml:16: Read \`BACKLOG.md\` in full.`
- `.gemini/commands/pack-startup.toml:18: Read only the most recent dated entry from \`CHANGELOG.md\`.`

Five pack-root Gemini surfaces reference BACKLOG.md / CHANGELOG.md by
name. No Gemini surface at pack root references IMPLEMENTATION-PLAN.md
or IMPLEMENTATION_PLAN.md (no grep hits).

### `project-template/.gemini/`

Command run: `grep -nE 'BACKLOG|CHANGELOG|IMPLEMENTATION_PLAN|IMPLEMENTATION-PLAN' project-template/.gemini/agents/*.md project-template/.gemini/commands/*.toml`.

Output (15 matches across 5 files):
- `project-template/.gemini/agents/auditor-docs.md:3: description: "Audit subagent for documentation drift detection — does documentation match the actual code? Path validity, API examples, config options, setup commands, CHANGELOG accuracy."`
- `project-template/.gemini/agents/auditor-docs.md:30: - **CHANGELOG drift** — CHANGELOG entries must match git history. A`
- `project-template/.gemini/agents/auditor-docs.md:31:   CHANGELOG entry claiming a security fix that was not actually committed`
- `project-template/.gemini/agents/auditor-docs.md:64: CHANGELOG entry claiming a security fix that was not committed is Critical.`
- `project-template/.gemini/agents/auditor.md:58: 6. Append a \`## Next steps\` section listing Critical and Major findings in priority order, cross-referencing the PM chat's BACKLOG processing workflow.`
- `project-template/.gemini/agents/coder.md:80: modify \`BACKLOG.md\`, \`CHANGELOG.md\`, \`STATUS.md\`, \`PACK-FEEDBACK.md\`,`
- `project-template/.gemini/agents/repo-ops.md:66: - **No PM-only file edits.** Do not modify \`BACKLOG.md\`,`
- `project-template/.gemini/agents/repo-ops.md:67:   \`CHANGELOG.md\`, \`STATUS.md\`, \`PACK-FEEDBACK.md\`, or any \`.md\` file`
- `project-template/.gemini/commands/pm-startup.toml:66: - BACKLOG entries (resolve via the trinity \`## Document locations\` table;`
- `project-template/.gemini/commands/pm-startup.toml:67:   reads \`BACKLOG.md\` in flat-file mode, the tracker in tracker mode)`
- `project-template/.gemini/commands/pm-startup.toml:73: Read only the most recent dated section from \`CHANGELOG.md\`.`
- `project-template/.gemini/commands/pm-startup.toml:76: from \`IMPLEMENTATION-PLAN.md\`.`
- `project-template/.gemini/commands/pm-startup.toml:80: Resolve every BACKLOG / STATUS / IMPLEMENTATION-PLAN / CHANGELOG read through`
- `project-template/.gemini/commands/pm-startup.toml:83: tracker mode the table points at the tracker (BACKLOG / STATUS / CHANGELOG /`
- `project-template/.gemini/commands/pm-startup.toml:84: IMPLEMENTATION-PLAN are tracker-mirrored read-only files in that mode).`
- `project-template/.gemini/commands/pm-startup.toml:188: **Open BACKLOG items:** [count of Status: Open + Status: Unblocked]`
- `project-template/.gemini/commands/pm-startup.toml:189: **Last TD number:** TD-NNN (or "none yet" if BACKLOG is empty)`

Five project-template Gemini surfaces reference the entry files by
name: `auditor-docs.md` (CHANGELOG drift), `auditor.md` (BACKLOG cross-
reference), `coder.md` (PM-only modify-deny list), `repo-ops.md` (same
deny list), `commands/pm-startup.toml` (multi-stream read directives
including IMPLEMENTATION-PLAN.md at line 76).

---

## §12 — OT STATUS.md shape (factual 4.1.5)

`find /Users/david/Developer/OptiquityTrader -name STATUS.md -type f`
returns exactly one file:
- `/Users/david/Developer/OptiquityTrader/docs/project/STATUS.md`

File metadata:
- Path: `/Users/david/Developer/OptiquityTrader/docs/project/STATUS.md`
- Line count: 139 lines (`wc -l`).

Top-level structure (H1 / H2 enumeration via `grep -n '^# \|^## '`):
- `# OptiquityTrader — Project Status` at line 1
- `## Current Phase` at line 7
- `## Phase Completion` at line 14
- `## Active Backlog` at line 80
- `## Key Metrics` at line 106
- `## Next Actions` at line 117
- `## How to Update This File` at line 128

The structure is per-section, not per-phase or per-task; each H2 is a
dashboard rubric. `## Phase Completion` is a single table (header at
line 16; rows from line 18 onward) listing every phase across the
project with a status cell (`✅ Complete` / `⬜ Not started`).
`## Active Backlog` is a category-binned summary table (header at line
84; rows from line 86 onward) listing open TD-NNN entries grouped by
audit/area category.

Representative section (`## Key Metrics`, lines 106–113, 8 lines, mid-
file):

```
## Key Metrics

- **Test count**: 805 passing, 0 failing
- **Build warnings**: 0 Swift compiler warnings
- **Supported brokers**: Public.com, E*Trade, Charles Schwab
- **Target platform**: macOS 15+
- **Swift version**: Swift 6 strict concurrency
- **AI Agent Config Pack**: v10
```

The file's self-described update rules at lines 128–139 specify update
triggers ("Update the phase table when a phase completes — change ⬜
to ✅"; "Update 'Current Phase' to the next phase"; "Update 'Next
Actions' to reflect what's up next"; "Update 'Key Metrics' test count
after any phase that adds tests") and an anchor-link rule
("Link every phase Title in the Phase Completion table to its heading
in IMPLEMENTATION_PLAN.md using `[Title](IMPLEMENTATION_PLAN.md#anchor)`
format.") at lines 134–139.

---

## §13 — Read-record

### Pack-repo v11-dev SHA

`git -C /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev rev-parse HEAD`
→ `6f9e6aa77e6ac401863f6ab2a06ad63dd02bc281` (same as the original
research pass; no commits landed between the two passes).

### New files read in this addendum pass

- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md`
  — lines 260–280 (Batch 12 row for BD-104).
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md`
  — lines 274–339 (§3.2 structural signals).
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/PACK-CHAT.md`
  — lines 38–49 (file-access strategy table).
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/docs/pack/PM-CHAT.md`
  — lines 115–129 (file-access strategy table).
- `/Users/david/Developer/OptiquityTrader/docs/project/STATUS.md`
  — full file (lines 1–139, with detailed read of lines 14–63, 80–113,
  117–139).

### Files re-read for verification (already in original §10 read-record)

- `BACKLOG.md`, `CHANGELOG.md` (pack root)
- `ARCHITECTURE-V3.md`, `ARCHITECTURE-V3.1-DELTA.md`,
  `ARCHITECTURE-V3.3-DELTA.md`, `IMPLEMENTATION-PLAN.md`
  (v11-research; H2/H3 line ranges re-checked)
- `.claude/skills/pack-startup/SKILL.md`,
  `.codex/skills/pack-startup/SKILL.md`,
  `.gemini/commands/pack-startup.toml`
- `project-template/skills/pm-startup/SKILL.md` and per-CLI mirrors
  (`.claude`, `.codex`, `.gemini/commands/pm-startup.toml`)
- `project-template/.claude/agents/{repo-ops,coder,auditor,auditor-docs}.md`
  and `.gemini` counterparts
- `scripts/lib/migrator-core.sh` (lines 217–225 for the optional hook)
- `scripts/migrate-v10-to-v11.sh` (lines 134–149 for the post-dispatch
  hook body)
- `scripts/lib/tracker-migrate-forward.sh` and
  `scripts/lib/tracker-migrate-reverse.sh` (function-line citations
  reconfirmed)

### Commands run during this pass

- `git -C /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev rev-parse HEAD`
  → `6f9e6aa77e6ac401863f6ab2a06ad63dd02bc281`
- `grep -n "^## §28\|^### §28.1" ARCHITECTURE-V3.md` → §28.1 at line
  566; §28.2 at line 1033.
- `grep -n "^## §3 \|^## §4" ARCHITECTURE-V3.1-DELTA.md` → §3 at line
  180; §4 at line 256.
- `grep -n "^### §6.4\|^### §6.5\|^## §6\|^## §7" ARCHITECTURE-V3.3-DELTA.md`
  → §6.4 at line 360; §6.5 at line 371.
- `grep -n "^### §1.4\|^### §1.5" maintenance-docs/v11-research/IMPLEMENTATION-PLAN.md`
  → §1.4 at line 167; §1.5 at line 210.
- `grep -n "^## Resolved" BACKLOG.md` → single hit at line 2248.
- `grep -nE '^\*\*Scope' CHANGELOG.md` → 3 hits (lines 12, 43, 124).
- `grep -n "^## " CHANGELOG.md` → 11 version H2 boundaries (v1..v11).
- `grep -n "^## " maintenance-docs/v11-research/IMPLEMENTATION-PLAN.md`
  → 8 H2 sections; awk-derived ranges as tabled in §10.
- `grep -cE '^\*\*BD-' maintenance-docs/v11-research/IMPLEMENTATION-PLAN.md`
  → 34 BD entries.
- `grep -nE 'BACKLOG|CHANGELOG|IMPLEMENTATION_PLAN|IMPLEMENTATION-PLAN'`
  against `.gemini/agents/*.md` + `.gemini/commands/*.toml` at pack
  root and project-template (results in §11).
- `find /Users/david/Developer/OptiquityTrader -name STATUS.md -type f`
  → single hit `docs/project/STATUS.md`.
- `wc -l` on `docs/project/STATUS.md` → 139 lines.
- `grep -n "^# \|^## " docs/project/STATUS.md` → 7 headings (1 H1 + 6 H2).

---

RESEARCH-PER-ENTRY-SPLIT-ADDENDUM-COMPLETE: 2026-05-13 — Closed 7 reviewer tightening suggestions (reading-order pointer, §3 OT-orientation note, compressed §3 alternative, BD-104 temporal-collision paragraph, maintainability §3.2 signals 4/5/6/8 citation, read-shape-change wording surface enumeration, §8 forward/reverse function-by-shape summary) and 5 factual questions (pack `## Resolved` H2 count = 1; CHANGELOG `**Scope` buckets = 3 all in v11; IMPLEMENTATION-PLAN.md §-section line ranges and 34 BD entries; `.gemini/` stream-file references at pack + project-template; OT STATUS.md = 139 lines, 6 dashboard H2s) — file:line citations throughout, no proposals, fact-finding only.
