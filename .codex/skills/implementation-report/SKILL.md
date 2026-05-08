---
name: implementation-report
description: Use when writing the structured report that every pack-coder run produces. Codifies the report sections, evidence requirements, chunking rule, and deferred-work-as-Cnb-commit pattern.
allowed-tools: Read, Write, Edit, Bash
---

# Implementation report

Every pack-coder run produces one report markdown file at the path the
caller's prompt specifies. The report is the agent's primary deliverable —
Pack Chat reads it, verifies the working-tree edits against it, and only
then stages and commits. Treat the report as a self-contained artifact:
Pack Chat must be able to re-derive every change from the report alone if
the worktree is lost.

## Required sections (all of them, in this order)

### 1. Branch + final HEAD SHA

State the branch name and the HEAD SHA from `git rev-parse HEAD`. Pack-coder
does not commit, so the SHA is unchanged from the worktree base — that's
the point. Documents which base the changes apply to.

### 2. Pre-flight check output

Paste the verbatim output of the agent's pre-flight checks: `pwd`,
`git rev-parse HEAD`, `git rev-parse --abbrev-ref HEAD`,
`git log --oneline -N`, the `ls` of every directory touched, plus any
prompt-required marker greps (e.g., `grep -c "BD-NNN" BACKLOG.md`). This
is the evidence that the agent started from the correct state. See the
`commit-discipline` skill for the pre-flight requirements themselves.

### 3. Per-task summary

For each T-task in the prompt's scope, one entry with: file path, line
delta (`+N / -M` or "new file: N lines"), and 1–3 sentences naming the
behavior that landed. Not a diff; a behavior summary. The diff goes in
section 4.

### 4. Full file contents and unified diffs

- **New files:** paste full contents verbatim inside a fenced block.
- **Modified files:** paste a unified diff against the worktree base,
  produced via `diff -u <(git show <base-SHA>:<path>) <path>`. Use the
  base SHA recorded in section 1.

This is the section Pack Chat reads to re-apply changes from the report
alone if needed. Do not abbreviate; do not say "see the worktree."

### 5. Verification output

For every verification command run, paste the literal command followed by
the relevant tail of output (typically the last 10–12 lines, always
including the result/summary line). Required entries depend on what
landed:

- `bash -n <script>` for any new or modified shell script.
- The relevant `bash scripts/test-*.sh` runs for any test suites the
  changes touch — must show `=== Results: N passed, 0 failed ===`.
- `python3 scripts/validate-pack.py` final tally line whenever any file
  under `project-template/`, `.claude/`, `.codex/`, `.gemini/`,
  `BACKLOG.md`, `README.md`, or agent definitions changed.

"Looks right" is not verification. If a command was not run, say so and
explain why; do not pretend.

### 6. Plan deviations

Explicit list. Zero is the expected case. If anything diverged from the
ARCHITECTURE / PLAN / prompt, name it and the reason. Silent deviation is
a defect — document it here so Pack Chat can decide whether to keep,
revert, or escalate.

### 7. POQs (Planner-Open-Questions) introduced

Questions that surfaced during implementation. For each: a one-line
problem statement, disposition (resolved / deferred / escalated), and the
recommended default if deferred. The C-4 → C-4b POQ-6 pattern: when a
prompt scopes a task narrower than the plan would have, surface the gap
as a POQ and propose a fast-follow Cnb commit. Do not silently expand
scope. Do not silently shrink scope without flagging.

### 8. Definition-of-Done checklist

Each item from the prompt's success criteria, marked PASS or FAIL with a
one-line evidence pointer (file path, test name, command output line). A
DoD with no evidence pointers is not a DoD; it's a guess.

### 9. Proposed commit message

Pack convention: `feat: vN — BD-NNN <description>` /
`fix: vN — BD-NNN <description>` / `docs: vN — BD-NNN <description>` /
`refactor: vN — BD-NNN <description>`. N is the current major version
(read from README.md version table). Single-line preferred; multi-line OK
if the body adds material context. Pack Chat may rewrite this; the agent's
job is to propose, not decide.

## Chunking rule for long reports

Reports often exceed ~300 lines (9 sections × multiple files of diffs).
Do not produce a single oversized Write — long single Writes have failed
in past sessions. Pattern:

1. Initial `Write` creates the file with sections 1–4 (or fewer, sized
   conservatively — aim for ≤300 lines per chunk).
2. Subsequent `Edit` calls append the remaining sections by replacing a
   sentinel line (e.g., the last header in the previous chunk) with that
   header plus the new content.

Apply the same rule when generating any other long markdown artifact
(plan documents, architecture records, review reports).

## Deferred-work-becomes-Cnb-commit pattern

When the prompt's scope is narrower than the plan's intent (e.g., "C-4
adds the migrator engine" but the plan also expected unit tests in C-4),
do NOT silently include the extra work — that violates the prompt scope
and inflates the commit. Instead:

1. Land the prompt-scoped work as the named commit (C-N).
2. Surface the gap as a POQ in section 7 of the report.
3. Recommend a fast-follow Cnb commit (C-Nb) with a one-paragraph
   description of what it should land.

This pattern was established by BD-119 C-4 → C-4b POQ-6 (the test runner
that should have been in C-4 became C-4b on the next pass). Pack Chat
decides whether to take the Cnb fast-follow or close the gap differently.

## Anti-patterns (do not do these)

- Reporting "all tests pass" without showing the literal `=== Results:
  N passed, 0 failed ===` line.
- Skipping the unified diff for modified files because "the change is
  small."
- Combining sections 4 and 5 into a single "what I did" prose blob.
- Marking a DoD item PASS without a file-path / test-name pointer.
- Writing the report inline as a chat message instead of to the
  caller-specified path. The disk artifact IS the deliverable.
