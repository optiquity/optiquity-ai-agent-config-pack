# PACK-REVIEW-BD-145.md

**Summary.** BD-145 implements both planner edit sites in
`scripts/init-project.sh` cleanly, preserves the BD-141 byte-identical
marker comparison, keeps the public contract intact, and stays inside
BD-159 §3.1 mechanical-edit conditions. **Verdict: APPROVE.**

---

## Verdict

**APPROVE.** No blocking concerns. No nits requiring changes. Ready for
Pack Chat to stage + commit.

---

## Scope confirmed

- Single file modified: `scripts/init-project.sh` (per `git diff --stat
  HEAD -- scripts/init-project.sh` → "1 file changed, 18 insertions(+)").
- All other working-tree changes (BD-143, BD-144 files) are out of scope
  and were not reviewed.
- `bash -n scripts/init-project.sh` returns clean.
- File mode preserved: `-rwxr-xr-x@ 1 david staff 47198 May 12 00:14
  scripts/init-project.sh`.

---

## Per-concern findings

### 1. D1/D5 hint comments on `pack_skill_coverage_for()` rows

PASS. Three inline comments added immediately above each language case
arm:

- `scripts/init-project.sh:239` — `# swift: D1=ios|macos (D1-implied) +
  Apple-platform skills via D1`
- `scripts/init-project.sh:241` — `# python: D2=python (cross-platform
  language) + intersection-loaded data/server skills`
- `scripts/init-project.sh:257` — `# proto: D4=grpc + future
  protobuf-patterns intersection (BD-156)`

Mechanically helpful (not decorative): each comment names the dimension
that selects the row's coverage and, for python/proto, the load
mechanism (intersection) that explains why coverage is conditional or
extensible. The proto comment also forward-links BD-156 (protobuf
intersection), which keeps the future-work signal localized to the
edit site rather than a separate doc lookup.

The planner's example (`# swift: D1=ios|macos (D1-implied) + D2=swift
via D1`) is slightly different from what shipped (`+ Apple-platform
skills via D1`). The shipped wording is in fact more accurate under the
v11 reframe: D2 is reserved for cross-platform languages
(architecture §6 / planner Batch 4), and Swift in v11 is D1-implied
rather than a D2 selector. The coder's deviation moves *toward* the
architecture, not away from it. Acceptable.

### 2. Header comment update — v11 5+3 model + PLATFORM-SKILLS.md authority

PASS. `scripts/init-project.sh:219-228` adds a 7-line block:

> Per the v11 PLATFORM-SKILLS.md reframe (BD-142), skills load via a
> 5+3 model: 5 dimensions (D1 substrate, D2 cross-platform languages,
> D3 component role, D4 communication protocols, D5 deployment surface)
> and 3 orthogonal load mechanisms (Tier 0 base, intersection-cell,
> trigger-loaded). The per-language rows below emit each language's
> pack-bundled skill coverage; PLATFORM-SKILLS.md is authoritative for
> the dimension membership and the full intersection / trigger
> semantics.

This satisfies the goal: it (a) reframes the function under the v11
model, (b) explicitly names PLATFORM-SKILLS.md as authoritative, and
(c) sets reader expectations that this table is a coverage report, not
a load-policy specification. The reframing also prevents the comment
from drifting out of date as new skills land — the dimension semantics
live in PLATFORM-SKILLS.md, not here.

### 3. Post-install prompt update — 5+3 model framing per §7.8

PASS. `scripts/init-project.sh:688-693` adds a 6-line paragraph inside
the existing `cat <<EOF` heredoc, between the kickoff-prompt
instruction and the existing-docs / gaps continuation. Wording matches
the planner spec (Batch 6 step 2) almost verbatim, with a small
expansion to enumerate the five dimensions inline. The closing
sentence ("Read §"How skill selection works" for the new framing
before generating prompts.") is the planner's exact ask.

The placement is correct: inside the EOF block (so it appears in the
emitted prompt) and before the conditional `existing_docs` /
`gaps` continuations (so it always prints, regardless of project
classification).

The planner step 2 also says "search for BD-136 near the end-of-run
prompt." There is no `BD-136` token in the script (verified via
`grep -n "BD-136" scripts/init-project.sh` → no output). The coder
correctly fell back to the planner's secondary anchor (`Active
skills:` / the `cat <<EOF` site near the end-of-run prompt). Anchor
mismatch was a planner-spec inaccuracy, not an implementation bug.

### 4. Public contract preservation

PASS.

- **Function signature unchanged.** `pack_skill_coverage_for() { local
  lang="$1"; local target_dir="${2:-${TARGET:-.}}"; ... }` — identical
  to pre-edit (positional args $1, $2 with same defaults).
- **Output format unchanged.** Each case arm still emits the same
  comma-separated skill list via `echo`. No format change.
- **BD-141 marker-line comparison preserved byte-identically.**
  `scripts/init-project.sh:251` retains `if [[ "$marker_line" ==
  "python-data: yes" ]]; then` exactly as shipped — the diff shows
  zero changes inside the python case body. The BD-141 comment block
  (lines 243-248) is untouched.
- **Exit codes unchanged.** No new `return` / `exit` paths introduced.
- **Caller contract.** `print_preview()` at line 289 still calls
  `pack_skill_coverage_for "$lang" "$target"` against the same
  output-shape expectation.

### 5. Exec bit preservation

PASS. `ls -l scripts/init-project.sh` reports `-rwxr-xr-x` (mode 755).
Diff is comment + heredoc-prose only; no chmod was needed and none
appears to have happened.

### 6. Single-file footprint

PASS. `git diff --stat HEAD -- scripts/init-project.sh` →
"1 file changed, 18 insertions(+)" with zero deletions. The other
modified files in `git status` (architecture-review trinity, audit-
methodology, add-capability.sh, lib/detect.sh, test-detect.sh,
migrate-v10-to-v11.sh, project-template trinity) belong to BD-143 /
BD-144 per the prompt's scope statement and were not assessed.

Net change: +18 lines, all comments / prose. No code-path changes.

### 7. BD-159 §3.1 mechanical-edit compliance

PASS on every condition:

| §3.1 condition | Status | Notes |
|---|---|---|
| 1. Trinity scope | N/A | Script-only; no trinity copies exist for `init-project.sh`. Planner Batch 6 explicitly states "Trinity considerations: None — script-only batch." |
| 2. Existing dimension fit | Pass | No new dimension introduced; comments label existing D1/D2/D4 selectors. |
| 3. Existing pattern fit | N/A | No new skill. |
| 4. Existing naming convention fit | N/A | No new skill name. |
| 5. Existing validator coverage | Pass | Check 9 (init-project structure) is prose-tolerant per planner Risk note; comment / heredoc additions do not perturb file-tree shape. |
| 6. Bounded file footprint | Pass | 0 new files; 1 edited file (well under the 10-edit ceiling); 0 new top-level docs; 0 new scripts; 0 new validate-pack checks. |
| 7. No agent-permission expansion | Pass | No CLAUDE.md / PACK-AGENTS.md edits; no Pack memory rule changes. |

No §3.2 structural signals tripped.

---

## Verification commands recommended for Pack Chat pre-commit

The planner specifies these and they should run before commit (each
should be quick):

- `python3 scripts/validate-pack.py` (Check 9 must remain green)
- `bash -n scripts/init-project.sh` (already run during this review:
  clean)
- `ls -l scripts/init-project.sh` (verified: `-rwxr-xr-x`)
- Optional: `bash scripts/init-project.sh --project /tmp/scratch-init`
  smoke test, inspect printed prompt for the new paragraph

---

## POQs

None. The implementation is unambiguous and matches the spec intent.

---

## Files reviewed

- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/init-project.sh` (diff against HEAD)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` §6.5, §7.8
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` Batch 6 (lines 470-515)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` §3.1, §3.2
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md` Pack memory § Repo conventions
