---
name: commit-discipline
description: Use at the start of every pack agent run. Codifies pre-flight checks, the write-target rule (under pwd only), the absolute git-state-change ban, pack-chat-only file boundaries, and the trinity rule cross-reference.
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

## 4. pack-chat-only file boundaries

Without explicit caller instruction in the prompt, the following files
are OFF-LIMITS to all pack agents:

- the `/backlog/` per-entry tree
- the `/changelog/` per-entry tree
- `README.md` (specifically the version table; other sections are also
  off-limits unless the prompt names them)
- `pack-ops/PACK-CHAT.md`
- `pack-ops/PACK-AGENTS.md`
- `CLAUDE.md` (root)
- `AGENTS.md` (root)
- `GEMINI.md` (root)
- `project-template/CLAUDE.md`
- `project-template/AGENTS.md`
- `project-template/GEMINI.md`

"Explicit caller instruction" means the prompt names the file AND the
section/lines/changes. A vague "you may need to update related docs"
does not authorize a pack-chat-only edit.

If the prompt's stated goal seems to require a pack-chat-only edit but the
prompt does not authorize one, surface the gap as a POQ in the report
and proceed with the non-PM portion of the work. Do not silently edit
the pack-chat-only file.

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
- Updating `/backlog/BD-NNN.md` to flip a Status field after a successful test
  run → pack-chat-only, forbidden by section 4. Pack Chat does the flip after
  review.
- Editing `CLAUDE.md` with a "minor clarification" without touching
  `AGENTS.md` and `GEMINI.md` → trinity violation, defect.
- Skipping the pre-flight because "the prompt is short" → still
  required; the pre-flight is what proves the run started clean.
