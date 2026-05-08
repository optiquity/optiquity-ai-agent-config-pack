# BD-124 Implementation Report — pack-coder skills (`implementation-report`, `verification-harness`, `commit-discipline`)

## 1. Branch + final HEAD SHA

- Branch: `worktree-agent-ab9aba4182a0bd9a3`
- HEAD SHA: `01ecadd7601dc2ae043f85dccc43c70423ed807e` (unchanged — pack-coder does not commit)
- Worktree base: `01ecadd` (BD-121 correction commit, per the BD-124 prompt)

All working-tree changes apply on top of `01ecadd`. Pack Chat will create the
single feat commit on top of this SHA after review.

## 2. Pre-flight check output

```
$ pwd
/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-ab9aba4182a0bd9a3
$ git rev-parse HEAD
01ecadd7601dc2ae043f85dccc43c70423ed807e
$ git rev-parse --abbrev-ref HEAD
worktree-agent-ab9aba4182a0bd9a3
$ git log --oneline -10
01ecadd docs: v11 — BD-121 correction: remove forbidden CHANGELOG mid-version edit step
63a096c feat: v11 — flip BD-115 + BD-119 to Resolved (Batch 8a closed; persona-coverage infra + N→N+1 migrator framework)
79f3aef fix: v11 — BD-119 fix-follow: B1 BLOCKER + S1..S5 SHOULD-FIX (Batch 8a review)
17a0cda docs: v11 — pack-reviewer report for BD-115 + BD-119 (1 BLOCKER, 5 SHOULD-FIX, 3 NICE-TO-HAVE)
d2cd9b4 docs: v11 — BD-119 C-7: migrator-framework doc refresh
861c158 refactor: v11 — BD-119 C-6: cut migrate-v10-to-v11.sh over to framework adapter
9f9f052 feat: v11 — BD-119 C-5: behavior-preservation harness (mandatory pre-C-6 gate)
3724d72 docs: v11 — reshape BD-114 for public usability + open BD-125 companion doc
0532526 docs: v11 — clarify BD-116 sequencing note + expand BD-121 scope (validate-pack + supporting-docs ripple)
23b0cb0 feat: v11 — BD-119 C-4b: add test-migrator-core.sh (T-12 unit tests; closes POQ-6)
$ ls .claude/agents/ .codex/agents/ .gemini/agents/
.claude/agents/:
pack-architect.md       pack-docs-researcher.md  pack-reviewer.md
pack-coder.md           pack-planner.md

.codex/agents/:
pack-architect.toml       pack-docs-researcher.toml  pack-reviewer.toml
pack-coder.toml           pack-planner.toml

.gemini/agents/:
pack-architect.md       pack-docs-researcher.md  pack-reviewer.md
pack-coder.md           pack-planner.md
$ ls .claude/skills/ .codex/skills/ .gemini/skills/
.claude/skills/:
architecture-review  dependency-intake  documentation  pack-help  pack-startup  planning  review

.codex/skills/:
architecture-review  dependency-intake  documentation  pack-help  pack-startup  planning  review

.gemini/skills/:
architecture-review  dependency-intake  documentation  planning  review
$ grep -c "BD-124" BACKLOG.md
1
```

All checks pass. Note: `.gemini/skills/` did not contain `dependency-intake` or
`pack-help` at the worktree base — that's pre-existing pack state, not a
BD-124 concern.

## 3. Per-task summary

### T-1 — Skill 1: `implementation-report` (3 new files)

- `.claude/skills/implementation-report/SKILL.md` (new file: 137 lines)
- `.codex/skills/implementation-report/SKILL.md` (new file: 137 lines)
- `.gemini/skills/implementation-report/SKILL.md` (new file: 137 lines)

Codifies the 9 required sections of every pack-coder report (branch+SHA,
pre-flight, per-task summary, full file contents/diffs, verification output,
plan deviations, POQs, DoD checklist, proposed commit message), plus the
chunking rule for >~300-line writes and the deferred-work-becomes-Cnb-commit
pattern (BD-119 C-4 → C-4b POQ-6 lesson).

### T-2 — Skill 2: `verification-harness` (3 new files)

- `.claude/skills/verification-harness/SKILL.md` (new file: 199 lines)
- `.codex/skills/verification-harness/SKILL.md` (new file: 199 lines)
- `.gemini/skills/verification-harness/SKILL.md` (new file: 199 lines)

Codifies the pack test-script pattern: header, mktemp+trap fixture setup,
counter+helper functions (assert_eq inline), fixture macros (mkfixture,
mkgitrepo, make_v10_target), per-case `pass:` / `FAIL:` lines, final
`=== Results: N passed, M failed ===` summary, and bash 3.2 + BSD-utils
portability constraints (no mapfile, no associative arrays, no GNU sed -i,
no `${var^^}`). References `test-detect.sh`, `test-migrator-core.sh`,
`test-migrator-manifest.sh`, `test-migrator-behavior-preservation.sh` as
canonical examples. Notes the "factor helpers into lib/test-helpers.sh —
DECLINED" decision per BD-119 convention.

### T-3 — Skill 3: `commit-discipline` (3 new files)

- `.claude/skills/commit-discipline/SKILL.md` (new file: 162 lines)
- `.codex/skills/commit-discipline/SKILL.md` (new file: 162 lines)
- `.gemini/skills/commit-discipline/SKILL.md` (new file: 162 lines)

Codifies pre-flight checks (pwd / HEAD / branch / log / ls / marker grep),
write-target rule (every Write/Edit goes under `pwd`; references the
BD-119 C-2 mis-routed-Write incident), the absolute git-state-change ban
(forbidden verb list + allowed read-only verbs), PM-only file boundaries
(BACKLOG/CHANGELOG/README/PACK-CHAT/PACK-AGENTS/CLAUDE/AGENTS/GEMINI),
and the trinity rule cross-reference.

### T-4 — `PACK-AGENTS.md` skills table (3 new rows)

- `PACK-AGENTS.md` (modified: +3 rows, lines 33–35)

Three new rows in the "Skills loaded by pack agents" table:
- `implementation-report | pack-coder`
- `verification-harness | pack-coder`
- `commit-discipline | pack-coder, pack-architect, pack-planner, pack-reviewer, pack-docs-researcher`

### T-5 — pack-coder agent files (3 modified, trinity)

- `.claude/agents/pack-coder.md` (modified: +5 lines)
- `.codex/agents/pack-coder.toml` (modified: +2 lines)
- `.gemini/agents/pack-coder.md` (modified: +5 lines)

Each adds a "Load skills" paragraph naming all three new skills
(`implementation-report`, `verification-harness`, `commit-discipline`) at
the end of the "Before executing" section. Path references the
tool-appropriate skills directory (`.claude/skills/`, `.codex/skills/`,
`.gemini/skills/`).

### T-6 — Other agent files (12 modified, 4 agents × 3 tools)

- `.claude/agents/pack-architect.md` / `pack-planner.md` / `pack-reviewer.md` / `pack-docs-researcher.md`
- `.codex/agents/pack-architect.toml` / `pack-planner.toml` / `pack-reviewer.toml` / `pack-docs-researcher.toml`
- `.gemini/agents/pack-architect.md` / `pack-planner.md` / `pack-reviewer.md` / `pack-docs-researcher.md`

Each existing "Load skills as specified:" line is extended to include
`commit-discipline` (since the git-state-change ban applies to all
agents). `implementation-report` and `verification-harness` are NOT
added to these read-only agents — those skills are pack-coder-specific.

## 4. Full file contents (new files) and unified diffs (modified files)

The three new SKILL.md files each appear once below as canonical content;
the `.codex/skills/<skill>/SKILL.md` and `.gemini/skills/<skill>/SKILL.md`
mirrors are byte-identical to the `.claude/skills/<skill>/SKILL.md` shown
(no tool-specific tweaks needed — these are pure-prose process docs).

### 4.1 New file: `.claude/skills/implementation-report/SKILL.md`

(Mirrors at `.codex/skills/implementation-report/SKILL.md` and
`.gemini/skills/implementation-report/SKILL.md` are byte-identical.)

````markdown
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
````

### 4.2 New file: `.claude/skills/verification-harness/SKILL.md`

(Mirrors at `.codex/skills/verification-harness/SKILL.md` and
`.gemini/skills/verification-harness/SKILL.md` are byte-identical.)

````markdown
---
name: verification-harness
description: Use when authoring or extending a pack test runner under scripts/. Codifies the pack test-script pattern (header, fixtures, per-case lines, summary, exit code) and the bash 3.2 / BSD-utils portability requirements.
allowed-tools: Read, Write, Edit, Bash
---

# Verification harness

The pack test convention. Canonical examples:

- `scripts/test-detect.sh` — unit tests for `scripts/lib/detect.sh`
- `scripts/test-migrator-core.sh` — public-API surface of the migrator framework
- `scripts/test-migrator-manifest.sh` — engine-side manifest behavior
- `scripts/test-migrator-behavior-preservation.sh` — adapter behavior preservation harness

When adding a new test runner, match this pattern. When extending an
existing one, do not invent a parallel pattern — extend the script in
place.

## Required structural elements

### 1. Header comment

```bash
#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/test-<name>.sh — <one-line description of what is tested>
#
# <Expanded description: which functions, which contracts, which BD,
# which plan section. Reference the canonical doc that defines the
# behavior the tests are pinning down.>
#
# Usage:    bash scripts/test-<name>.sh
# Exit 0 on all pass; exit 1 on any failure.
```

The `pack-internal: true` marker tells the pack help / verb scanner that
this is not a user-facing command.

### 2. Fixture-temp setup

```bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

FIXTURE_BASE="$(mktemp -d -t test-<name>.XXXXXX)"
trap 'rm -rf "$FIXTURE_BASE"' EXIT
```

Notes:
- `mktemp -d -t <prefix>.XXXXXX` is the BSD form (no template path).
  GNU's `mktemp -d` requires `--tmpdir` for the same effect; the BSD form
  works on both macOS and Linux CI.
- The `trap … EXIT` cleanup MUST be registered before any fixtures are
  created. A test failure mid-script must not leak `/tmp/` directories.
- `set -uo pipefail` (NOT `set -e`) — let assertion failures be tallied
  rather than aborting the run on the first failure.

### 3. Counter + helper functions

```bash
passes=0
fails=0

fail() {
    echo "  FAIL: $1"
    [[ -n "${2:-}" ]] && printf '    expected: %s\n' "$2"
    [[ -n "${3:-}" ]] && printf '    actual:   %s\n' "$3"
    fails=$((fails + 1))
}
pass() { echo "  pass: $1"; passes=$((passes + 1)); }

assert_eq() {
    local label="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        pass "$label"
    else
        fail "$label" "$expected" "$actual"
    fi
}
```

Inline these helpers in each test script. (Considered factoring into
`scripts/lib/test-helpers.sh` and sourcing — DECLINED for now per BD-119
convention. Keeping helpers inline makes each script self-contained and
diff-friendly; a single shared lib is a future optimization, not a
current requirement.)

Common helpers beyond `assert_eq`:

- `assert_contains <haystack> <needle> <description>` — for substring
  matches in command output
- `assert_exit_code <expected-rc> <actual-rc> <description>` — for
  testing failure modes (use `cmd; rc=$?` to capture without aborting
  under `set -u`)

Define only the helpers the script actually uses; do not paste a kitchen
sink.

### 4. Fixture macros

When a script needs the same kind of fixture in many cases, factor a
small macro. Examples:

```bash
mkfixture() {
    local name="$1"
    local dir="$FIXTURE_BASE/$name"
    mkdir -p "$dir"
    printf '%s' "$dir"
}

mkgitrepo() {
    local dir
    dir=$(mkfixture "$1")
    git -C "$dir" init -q -b main
    git -C "$dir" config user.email test@example.com
    git -C "$dir" config user.name test
    printf '%s' "$dir"
}

make_v10_target() {
    # Synthesizes a minimal v10-shape target dir: CLAUDE.md without v11
    # fingerprint, docs/pack/PROMPT-TEMPLATES.md present, no
    # .claude/skills/pack-help/.
    local dir
    dir=$(mkfixture "$1")
    mkdir -p "$dir/.claude" "$dir/docs/pack"
    printf '# CLAUDE.md\nv10 shape\n' > "$dir/CLAUDE.md"
    : > "$dir/docs/pack/PROMPT-TEMPLATES.md"
    printf '%s' "$dir"
}
```

Document each macro at definition with a one-line comment naming what
shape it produces.

### 5. Per-case structure

Every test case prints exactly one summary line:

- `  pass: <one-line description>`
- `  FAIL: <one-line description>` (plus optional `expected:` / `actual:`
  follow-up lines from the helper)

The description is specific and one line. Examples:

- `pass: trinity validator rejects when only 2 of 3 trinity files in manifest`
- `pass: detect_target_pack_version returns v10 for v10-shape target`
- `pass: migrator_dispatch with no args → die EXIT_INTERNAL (arity guard)`

Anti-pattern: multi-line case descriptions, generic descriptions like
"works correctly", or descriptions that do not name the input + expected
output.

Group related cases under section banners:

```bash
# ── detect_clean_working_tree ──────────────────────────────────────────
echo "== detect_clean_working_tree =="
```

### 6. Final summary

```bash
# ── Summary ────────────────────────────────────────────────────────────
echo
echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
```

The exact string `=== Results: N passed, M failed ===` is what Pack Chat
greps for in implementation reports. Do not vary the format. Exit 0 iff
M = 0.

## Portability requirements (macOS bash 3.2 + BSD utils)

The pack ships to developer macs running stock `/bin/bash` (3.2) and
BSD utilities. Pack CI also runs on Linux. Both must pass. Forbidden
constructs:

- `mapfile` / `readarray` — bash 4+ only. Use a `while read` loop.
- Associative arrays (`declare -A`) — bash 4+ only. Use parallel
  indexed arrays or a delimited string.
- GNU-only `sed -i` (no extension argument) — BSD `sed -i` requires an
  empty string argument. Portable form: write to a tempfile and `mv`.
- `${var^^}` / `${var,,}` (case modification) — bash 4+ only. Use
  `tr '[:lower:]' '[:upper:]'` / `tr '[:upper:]' '[:lower:]'`.
- `find -print0` paired with `xargs -0` — works on both, but only
  needed for paths containing whitespace or newlines. Test fixtures
  control their own path names — keep them whitespace-free and avoid
  `-print0` clutter.
- `&>file` redirection — POSIX form is `>file 2>&1`.
- `[[ … =~ … ]]` regex with PCRE-only constructs — BSD regex is BRE.

Allowed and recommended:

- `[[ "$a" == "$b" ]]` for string equality.
- `[[ "$haystack" == *"$needle"* ]]` for substring match (no regex).
- `printf '%s'` instead of `echo -n` (BSD `echo` does not support `-n`).
- `local` for function-scoped vars.
- `set -uo pipefail` (skip `-e` so individual assertion failures
  accumulate instead of aborting).

## When to extend an existing script vs. add a new one

- Same target unit / same surface → extend the existing script.
- Different unit / different surface / different fixture style →
  new `scripts/test-<name>.sh`.
- A new BD that needs to verify multi-step behavior → consider a
  behavior-preservation harness (see
  `test-migrator-behavior-preservation.sh` for the pattern).

Do not duplicate fixture macros across scripts; if two scripts need the
same fixture, that's the signal to factor — but per "DECLINED for now"
above, defer the factoring until at least three call-sites exist.
````

### 4.3 New file: `.claude/skills/commit-discipline/SKILL.md`

(Mirrors at `.codex/skills/commit-discipline/SKILL.md` and
`.gemini/skills/commit-discipline/SKILL.md` are byte-identical.)

````markdown
---
name: commit-discipline
description: Use at the start of every pack agent run. Codifies pre-flight checks, the write-target rule (under pwd only), the absolute git-state-change ban, PM-only file boundaries, and the trinity rule cross-reference.
allowed-tools: Read, Bash
---

# Commit discipline

This skill applies to every pack agent: `pack-architect`, `pack-planner`,
`pack-coder`, `pack-reviewer`, `pack-docs-researcher`. It encodes the
non-negotiable workflow rules every agent observes from session start to
final report.

## 1. Pre-flight checks (run BEFORE any work)

Run all of these first. If any check fails, STOP and report — do not
invent state, do not proceed.

```bash
pwd                                    # Must end in worktree path, not main checkout
git rev-parse HEAD                     # Must equal the expected base SHA from the prompt
git rev-parse --abbrev-ref HEAD        # Must start with `worktree-agent-`
git log --oneline -10                  # Verify expected ancestor commits are present
ls <every dir the agent will touch>    # Verify expected files exist
grep -c "<marker>" <authoritative-doc> # Optional: confirm authoritative content present
```

Paste this output verbatim into section 2 of the implementation report
(see the `implementation-report` skill). The pre-flight is the evidence
that the run started from the correct state.

Common failure modes the pre-flight catches:

- `pwd` resolves to the main checkout, not the worktree (the most
  common cause of the C-2 mis-routed-Write incident).
- HEAD does not match the SHA in the prompt — the prompt was written
  against a different base, or the worktree drifted.
- A required doc the prompt told the agent to read is absent — likely
  a typo in the path, or the prompt was written against a different
  branch.

## 2. Write-target rule

**Every `Write` and `Edit` MUST go to a path under `pwd`.** No exceptions.

When `pwd` is `/Users/<user>/Developer/<repo>/.claude/worktrees/agent-<id>/`,
the only valid write paths are under that prefix. Writing to
`/Users/<user>/Developer/<repo>/<file>` (the main checkout) is FORBIDDEN
even when the file path "looks right" — the main checkout belongs to the
user's interactive shell and Pack Chat, not to the agent.

If a `Write` returns "permission denied" or "file outside workspace,"
the path is wrong — re-issue the same content under the worktree path.
NEVER work around the rejection by re-targeting the main checkout. The
BD-119 C-2 incident was exactly this failure mode: a Write rejected
under the worktree path was retried against the main checkout, which
silently bypassed the workspace boundary.

The "Additional working directories" note in the harness environment
(e.g., `/tmp/...`, `/private/tmp/...`) lists paths the agent may also
write to for scratch work. Those are not substitutes for the worktree
path; final deliverables go under the worktree only.

## 3. Git-state-change ban (absolute)

Forbidden verbs (no exceptions, no "but just this once"):

- `git add`
- `git commit`
- `git push`
- `git tag`
- `git rebase`
- `git merge`
- `git reset`
- `git stash`
- `git checkout` *(except the read-only form `git checkout -- <path>`
  used to inspect a single file at a different ref)*
- `git rm`
- `git restore`
- `git revert`
- `git cherry-pick`
- `git pull`
- `git fetch`

Allowed read-only verbs:

- `git status`
- `git diff` (any form, including `git diff <ref>...HEAD`)
- `git log`
- `git rev-parse`
- `git show <ref>:<path>` (read a file's content at a different ref)
- `git ls-files`
- `git blame`

The agent's deliverable is the report file plus working-tree edits.
Pack Chat reads the report, verifies the edits, runs tests if needed,
and ONLY THEN stages and commits with explicit user approval. An agent
that stages or commits has bypassed the user-approval gate — that is
the entire reason the ban exists.

If a step in the prompt appears to require staging or committing, STOP
and write the situation into the implementation report under section 6
(plan deviations) or section 7 (POQs). Do not improvise. The prompt is
either wrong or the agent is misreading it; either way the resolution
is Pack Chat's, not the agent's.

## 4. PM-only file boundaries

Without explicit caller instruction in the prompt, the following files
are OFF-LIMITS to all pack agents:

- `BACKLOG.md`
- `CHANGELOG.md`
- `README.md` (specifically the version table; other sections are also
  off-limits unless the prompt names them)
- `PACK-CHAT.md`
- `PACK-AGENTS.md`
- `CLAUDE.md` (root)
- `AGENTS.md` (root)
- `GEMINI.md` (root)
- `project-template/CLAUDE.md`
- `project-template/AGENTS.md`
- `project-template/GEMINI.md`

"Explicit caller instruction" means the prompt names the file AND the
section/lines/changes. A vague "you may need to update related docs"
does not authorize a PM-only edit.

If the prompt's stated goal seems to require a PM-only edit but the
prompt does not authorize one, surface the gap as a POQ in the report
and proceed with the non-PM portion of the work. Do not silently edit
the PM-only file.

## 5. Trinity rule cross-reference

When modifying any of:

- `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` (root)
- `project-template/CLAUDE.md` / `project-template/AGENTS.md` / `project-template/GEMINI.md`

…the agent MUST modify all three with byte-identical wording, modulo
provably tool-specific tweaks (Claude's Task tool syntax, Codex's
`agent-run.sh` references, Gemini's `@<agent>` invocation). Symmetry
is the default; asymmetry requires justification in the implementation
report.

The same rule applies to any pack-template trinity files (e.g., when
a skill is added under `project-template/skills/<name>/`, the
`project-template/.claude/skills/<name>/`, `project-template/.codex/skills/<name>/`,
and `project-template/.gemini/skills/<name>/` mirrors must also be
updated — that's a quad, not a trinity, but the discipline is the
same).

For pack-repo agent files (`.claude/agents/`, `.codex/agents/`,
`.gemini/agents/`), the same trinity discipline applies. Each agent's
content is mirrored across the three tools with tool-specific format
differences (Claude markdown frontmatter, Codex TOML, Gemini markdown
frontmatter) but identical prose.

## 6. Anti-patterns the discipline catches

- Running `git add` to "tidy up" before reporting → forbidden by
  section 3.
- Writing the implementation report to `/tmp/<file>.md` because the
  worktree write rejected once → wrong path; re-issue under the
  worktree.
- Updating `BACKLOG.md` to flip a Status field after a successful test
  run → PM-only, forbidden by section 4. Pack Chat does the flip after
  review.
- Editing `CLAUDE.md` with a "minor clarification" without touching
  `AGENTS.md` and `GEMINI.md` → trinity violation, defect.
- Skipping the pre-flight because "the prompt is short" → still
  required; the pre-flight is what proves the run started clean.
````

### 4.4 Unified diffs (modified files)

All diffs against base SHA `01ecadd`. Produced via
`git diff --no-color 01ecadd -- <path>`.

#### `.claude/agents/pack-coder.md`

```diff
--- a/.claude/agents/pack-coder.md
+++ b/.claude/agents/pack-coder.md
@@ -86,3 +86,8 @@ Read the files the caller's prompt names. Always also read:
 - PACK-AGENTS.md (agent routing + permission rules)
 
 These contain standing rules every pack-coder session must respect.
+
+Load skills as specified: `implementation-report` for report structure
+and chunking discipline, `verification-harness` for the pack test-script
+pattern, `commit-discipline` for pre-flight checks, write-target rules,
+and the absolute git-state-change ban. Skills are in `.claude/skills/`.
```

#### `.codex/agents/pack-coder.toml`

```diff
--- a/.codex/agents/pack-coder.toml
+++ b/.codex/agents/pack-coder.toml
@@ -43,5 +43,7 @@ If the report exceeds ~300 lines, chunk via initial write + subsequent append-ed
 
 # Before executing
 Read the files the caller's prompt names. Always also read AGENTS.md (pack repo rules; includes the Pack memory section that governs all agents) and PACK-AGENTS.md (agent routing + permission rules). These contain standing rules every pack-coder session must respect.
+
+Load skills as specified: implementation-report for report structure and chunking discipline, verification-harness for the pack test-script pattern, commit-discipline for pre-flight checks, write-target rules, and the absolute git-state-change ban. Skills are in .codex/skills/.
 """
 # Implementation specialist. Edits source within scope; never touches git state.
```

#### `.gemini/agents/pack-coder.md`

```diff
--- a/.gemini/agents/pack-coder.md
+++ b/.gemini/agents/pack-coder.md
@@ -82,3 +82,8 @@ Read the files the caller's prompt names. Always also read GEMINI.md
 (pack repo rules; includes the Pack memory section that governs all
 agents) and PACK-AGENTS.md (agent routing + permission rules). These
 contain standing rules every pack-coder session must respect.
+
+Load skills as specified: `implementation-report` for report structure
+and chunking discipline, `verification-harness` for the pack test-script
+pattern, `commit-discipline` for pre-flight checks, write-target rules,
+and the absolute git-state-change ban. Skills are in `.gemini/skills/`.
```

#### `.claude/agents/pack-architect.md`

```diff
--- a/.claude/agents/pack-architect.md
+++ b/.claude/agents/pack-architect.md
@@ -30,5 +30,6 @@ Do not propose solutions unless asked. Describe the constraint or design
 problem, then wait for direction.
 
 Load skills as specified: `architecture-review` for design review methodology,
-`planning` for structuring design work, `documentation` for doc standards.
-Skills are in `.claude/skills/`.
+`planning` for structuring design work, `documentation` for doc standards,
+`commit-discipline` for pre-flight checks, write-target rules, and the
+absolute git-state-change ban. Skills are in `.claude/skills/`.
```

#### `.claude/agents/pack-planner.md`

```diff
--- a/.claude/agents/pack-planner.md
+++ b/.claude/agents/pack-planner.md
@@ -41,4 +41,6 @@ Output:
 - Open risks or unknowns.
 
 Load skills as specified: `planning` for methodology, `architecture-review`
-for structural analysis. Skills are in `.claude/skills/`.
+for structural analysis, `commit-discipline` for pre-flight checks,
+write-target rules, and the absolute git-state-change ban. Skills are
+in `.claude/skills/`.
```

#### `.claude/agents/pack-reviewer.md`

```diff
--- a/.claude/agents/pack-reviewer.md
+++ b/.claude/agents/pack-reviewer.md
@@ -50,4 +50,6 @@ If the calling prompt does not specify a report file path, return
 findings inline in your final assistant message instead of writing.
 
 Load skills as specified: `review` for review methodology,
-`architecture-review` for structural analysis. Skills are in `.claude/skills/`.
+`architecture-review` for structural analysis, `commit-discipline` for
+pre-flight checks, write-target rules, and the absolute git-state-change
+ban. Skills are in `.claude/skills/`.
```

#### `.claude/agents/pack-docs-researcher.md`

```diff
--- a/.claude/agents/pack-docs-researcher.md
+++ b/.claude/agents/pack-docs-researcher.md
@@ -29,5 +29,6 @@ Before making any verification claim, check the source directly. Do not
 rely on training data for CLI tool behavior — these tools update frequently.
 
 Load skills as specified: `documentation` for doc standards,
-`dependency-intake` for dependency evaluation framework. Skills are in
-`.claude/skills/`.
+`dependency-intake` for dependency evaluation framework,
+`commit-discipline` for pre-flight checks, write-target rules, and the
+absolute git-state-change ban. Skills are in `.claude/skills/`.
```

#### `.codex/agents/pack-architect.toml`

```diff
--- a/.codex/agents/pack-architect.toml
+++ b/.codex/agents/pack-architect.toml
@@ -19,6 +19,6 @@ Before making any design recommendation, read: CLAUDE.md (pack repo rules and st
 
 Do not propose solutions unless asked. Describe the constraint or design problem, then wait for direction.
 
-Load skills as specified: architecture-review for design review methodology, planning for structuring design work, documentation for doc standards. Skills are in .codex/skills/.
+Load skills as specified: architecture-review for design review methodology, planning for structuring design work, documentation for doc standards, commit-discipline for pre-flight checks, write-target rules, and the absolute git-state-change ban. Skills are in .codex/skills/.
 """
 # Pack architecture and design decisions. Read-only analysis and recommendations.
```

#### `.codex/agents/pack-planner.toml`

```diff
--- a/.codex/agents/pack-planner.toml
+++ b/.codex/agents/pack-planner.toml
@@ -25,6 +25,6 @@ Output:
 - Verification plan (CI checks, manual checks, grep audits).
 - Open risks or unknowns.
 
-Load skills as specified: planning for methodology, architecture-review for structural analysis. Skills are in .codex/skills/.
+Load skills as specified: planning for methodology, architecture-review for structural analysis, commit-discipline for pre-flight checks, write-target rules, and the absolute git-state-change ban. Skills are in .codex/skills/.
 """
 # Pack implementation planning. Read-only analysis.
```

#### `.codex/agents/pack-reviewer.toml`

```diff
--- a/.codex/agents/pack-reviewer.toml
+++ b/.codex/agents/pack-reviewer.toml
@@ -25,7 +25,7 @@ Output policy. Make NO file edits or content writes EXCEPT exactly one final rep
 
 If the calling prompt does not specify a report file path, return findings inline in your final assistant message instead of writing.
 
-Load skills as specified: review for review methodology, architecture-review for structural analysis. Skills are in .codex/skills/.
+Load skills as specified: review for review methodology, architecture-review for structural analysis, commit-discipline for pre-flight checks, write-target rules, and the absolute git-state-change ban. Skills are in .codex/skills/.
 """
 # Pack change review. Sandbox is workspace-write so the agent can emit
 # its single report file at the prompted path; prose restricts writes
```

#### `.codex/agents/pack-docs-researcher.toml`

```diff
--- a/.codex/agents/pack-docs-researcher.toml
+++ b/.codex/agents/pack-docs-researcher.toml
@@ -23,6 +23,6 @@ Key documentation sources:
 
 Before making any verification claim, check the source directly. Do not rely on training data for CLI tool behavior — these tools update frequently.
 
-Load skills as specified: documentation for doc standards, dependency-intake for dependency evaluation framework. Skills are in .codex/skills/.
+Load skills as specified: documentation for doc standards, dependency-intake for dependency evaluation framework, commit-discipline for pre-flight checks, write-target rules, and the absolute git-state-change ban. Skills are in .codex/skills/.
 """
 # CLI tool documentation verification. Read-only research.
```

#### `.gemini/agents/pack-architect.md`

```diff
--- a/.gemini/agents/pack-architect.md
+++ b/.gemini/agents/pack-architect.md
@@ -32,5 +32,6 @@ Do not propose solutions unless asked. Describe the constraint or design
 problem, then wait for direction.
 
 Load skills as specified: `architecture-review` for design review methodology,
-`planning` for structuring design work, `documentation` for doc standards.
-Skills are in `.gemini/skills/`.
+`planning` for structuring design work, `documentation` for doc standards,
+`commit-discipline` for pre-flight checks, write-target rules, and the
+absolute git-state-change ban. Skills are in `.gemini/skills/`.
```

#### `.gemini/agents/pack-planner.md`

```diff
--- a/.gemini/agents/pack-planner.md
+++ b/.gemini/agents/pack-planner.md
@@ -34,4 +34,6 @@ Output:
 - Open risks or unknowns.
 
 Load skills as specified: `planning` for methodology, `architecture-review`
-for structural analysis. Skills are in `.gemini/skills/`.
+for structural analysis, `commit-discipline` for pre-flight checks,
+write-target rules, and the absolute git-state-change ban. Skills are
+in `.gemini/skills/`.
```

#### `.gemini/agents/pack-reviewer.md`

```diff
--- a/.gemini/agents/pack-reviewer.md
+++ b/.gemini/agents/pack-reviewer.md
@@ -40,4 +40,6 @@ If the calling prompt does not specify a report file path, return
 findings inline in your final assistant message instead of writing.
 
 Load skills as specified: `review` for review methodology,
-`architecture-review` for structural analysis. Skills are in `.gemini/skills/`.
+`architecture-review` for structural analysis, `commit-discipline` for
+pre-flight checks, write-target rules, and the absolute git-state-change
+ban. Skills are in `.gemini/skills/`.
```

#### `.gemini/agents/pack-docs-researcher.md`

```diff
--- a/.gemini/agents/pack-docs-researcher.md
+++ b/.gemini/agents/pack-docs-researcher.md
@@ -31,5 +31,6 @@ Before making any verification claim, check the source directly. Do not
 rely on training data for CLI tool behavior — these tools update frequently.
 
 Load skills as specified: `documentation` for doc standards,
-`dependency-intake` for dependency evaluation framework. Skills are in
-`.gemini/skills/`.
+`dependency-intake` for dependency evaluation framework,
+`commit-discipline` for pre-flight checks, write-target rules, and the
+absolute git-state-change ban. Skills are in `.gemini/skills/`.
```

#### `PACK-AGENTS.md`

```diff
--- a/PACK-AGENTS.md
+++ b/PACK-AGENTS.md
@@ -30,6 +30,9 @@ Skills are in `.claude/skills/`, `.codex/skills/`, `.gemini/skills/`
 | `documentation` | pack-architect, pack-docs-researcher |
 | `review` | pack-reviewer |
 | `dependency-intake` | pack-docs-researcher |
+| `implementation-report` | pack-coder |
+| `verification-harness` | pack-coder |
+| `commit-discipline` | pack-coder, pack-architect, pack-planner, pack-reviewer, pack-docs-researcher |
 
 ---
```

## 5. Verification output

### `python3 scripts/validate-pack.py`

```
$ python3 scripts/validate-pack.py
…
── Check 25: Customization-detection regression guard (BD-089) ──
  OK: 4/4 fixture rows recorded with expected disposition + class
  OK: truthful-report contract: every fixture file appears in report.md

── Check 26: BD-119 migrator-framework inventory ──
  OK: scripts/lib/migrator-core.sh syntax valid
  OK: scripts/lib/migrator-stages.sh syntax valid
  OK: scripts/lib/migrator-manifest.sh syntax valid
  OK: migrator-core.sh declares all 6 public-API functions
  OK: migrator-core.sh declares all 8 exit-code constants
  OK: migrator-core.sh preserves EXIT_NOT_V10 back-compat synonym

============================================================
PASSED — all checks clean
```

All 26 checks green. (Note: validate-pack.py only validates SKILL.md
frontmatter for `project-template/skills/`; the new pack-repo skills
under `.claude/skills/`, `.codex/skills/`, `.gemini/skills/` are not
registered with validate-pack — same as the existing skills there.)

### `bash scripts/test-detect.sh`

```
$ bash scripts/test-detect.sh
…
=== Results: 40 passed, 0 failed ===
```

### `bash scripts/test-migrator-core.sh`

```
$ bash scripts/test-migrator-core.sh
…
=== Results: 19 passed, 0 failed ===
```

### `bash scripts/test-migrator-manifest.sh`

```
$ bash scripts/test-migrator-manifest.sh
…
=== Results: 12 passed, 0 failed ===
```

### `bash scripts/test-migrator-behavior-preservation.sh`

```
$ bash scripts/test-migrator-behavior-preservation.sh
…
=== Results: 15 passed, 0 failed ===
```

Total: 86 tests across 4 suites, 0 failures. No regressions.

`bash -n` not run for the new files — they are pure markdown SKILL.md
docs, no shell content.

## 6. Plan deviations

None. The work matches the BD-124 prompt scope exactly:

- 9 new SKILL.md files (3 skills × 3 tools) — done
- 3 new rows in PACK-AGENTS.md skills table — done
- pack-coder agent files load all 3 new skills — done (3 files)
- other 4 agent definitions load `commit-discipline` only — done (12 files)
- `implementation-report` and `verification-harness` NOT added to read-only
  agents (per prompt) — confirmed
- Trinity rule observed for skills (3-way mirror, byte-identical content)
- Trinity rule observed for agent definitions (Claude/Codex/Gemini, with
  expected tool-format differences and tool-appropriate skills-dir paths)
- Stayed clear of all paths owned by BD-121 and BD-114
- No PM-only files modified (`PACK-AGENTS.md` was scoped in by the
  prompt; trinity files at root, BACKLOG, CHANGELOG, README untouched)
- No git state-change verbs run

## 7. POQs introduced

None. The prompt was complete and unambiguous; nothing surfaced during
implementation that needed deferral or escalation.

## 8. Definition-of-Done checklist

- [x] **9 SKILL.md files exist** — PASS. All present:
  `.claude/skills/{implementation-report,verification-harness,commit-discipline}/SKILL.md`
  + `.codex/skills/...` + `.gemini/skills/...` (verified via `ls`
  output in section 2 plus the new entries in the post-edit `ls` of
  the skills directories).
- [x] **PACK-AGENTS.md skills table has 3 new rows** — PASS. Rows for
  `implementation-report`, `verification-harness`, `commit-discipline`
  added at lines 33–35 (see diff in section 4.4).
- [x] **15 agent files reference appropriate skills** — PASS. pack-coder
  (3 files) loads all 3 new skills; pack-architect / pack-planner /
  pack-reviewer / pack-docs-researcher (12 files) each load
  `commit-discipline`. Diffs in section 4.4.
- [x] **Trinity rule respected** — PASS. The 3 new skills are
  byte-identical across `.claude/skills/`, `.codex/skills/`,
  `.gemini/skills/`. The 5 agent definitions are mirrored across
  Claude/Codex/Gemini with consistent prose; tool-format differences
  (markdown frontmatter vs TOML, skills-dir path) are pre-existing
  conventions.
- [x] **validate-pack.py green** — PASS. `PASSED — all checks clean`
  (26/26 checks). Section 5 above.
- [x] **Existing tests still green** — PASS. test-detect 40/40,
  test-migrator-core 19/19, test-migrator-manifest 12/12,
  test-migrator-behavior-preservation 15/15. Section 5 above.

## 9. Proposed commit message

```
feat: v11 — BD-124 pack-coder skills (implementation-report, verification-harness, commit-discipline)
```

Single line is sufficient — the BD-124 BACKLOG entry already documents
the rationale and scope; the commit message just needs to point at it.
