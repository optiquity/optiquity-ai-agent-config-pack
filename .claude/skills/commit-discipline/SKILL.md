---
name: commit-discipline
description: Use at the start of every pack agent run. Codifies pre-flight regime detection, the regime-aware write-target rule, the absolute git-state-change ban, pack-chat-only file boundaries, and the trinity rule cross-reference.
allowed-tools: Read, Bash
---

# Commit discipline

This skill applies to every pack agent: `pack-architect`, `pack-planner`,
`pack-coder`, `pack-reviewer`, `pack-docs-researcher`. It encodes the
non-negotiable workflow rules every agent observes from session start to
final report.

## 1. Pre-flight checks (run BEFORE any work)

Run all of these first. The pre-flight DETECTS your execution regime — it
is non-fatal in both directions. If a check reveals a genuine mismatch
(wrong base SHA, a required doc absent), STOP and report — do not invent
state, do not proceed.

```bash
pwd                                    # Detect regime: a worktree-agent-* path = ISOLATED; otherwise IN-PLACE
git rev-parse HEAD                     # Must equal the expected base SHA from the prompt
git rev-parse --abbrev-ref HEAD        # A worktree-agent-* branch = ISOLATED; otherwise IN-PLACE
git log --oneline -10                  # Verify expected ancestor commits are present
ls <every dir the agent will touch>    # Verify expected files exist
grep -c "<marker>" <authoritative-doc> # Optional: confirm authoritative content present
```

**The DEFAULT is set by your agent class, but you VERIFY the regime you
actually got from ground truth (see section 2). The default:**

- **Read-WRITE agents (coders, fix-coders) default to an ISOLATED
  worktree** — a `worktree-agent-*` checkout the orchestrator created (the
  first coder of a commit) or you are reusing (a fix-coder; never a new
  worktree). Your code Writes go under `pwd`; the report goes to the named
  `/tmp` handoff dir.
- **Read-ONLY agents (reviewers, architects, planners, auditors,
  researchers) run in the tree the work lives in** — the main checkout when
  the work is committed, the commit's live worktree when the work is still
  uncommitted there (you cd into it and verify pwd/HEAD). You write only
  your report (to the named `/tmp` handoff dir) and emit NO patch.

**IN-PLACE is the DEGRADED fallback, not the default.** If you are a
read-write agent but `pwd` / HEAD show you are NOT in a `worktree-agent-*`
checkout, isolation did not take effect (a platform fall-to-main, or a CLI
without worktree support) — you self-detect that degraded in-place regime
and write under the parent working tree, reporting the degradation.

Key the detection on GROUND TRUTH (the actual `pwd` / HEAD), never on a
settings value or your class assumption — settings can lie (platform bugs
can silently disagree with `settings.json`), so the runtime self-detect is
the only deterministic signal:

- `pwd` / HEAD indicate a `worktree-agent-*` worktree ⇒ you are
  **ISOLATED** (the class default for a read-write agent took effect).
- Otherwise ⇒ you are **IN-PLACE** (the degraded fallback): code Writes go
  under the parent working tree; report the degradation.

Paste this output verbatim into section 2 of the implementation report
(see the `implementation-report` skill). The pre-flight is the evidence
that the run started from the correct state and which regime it ran in.

Common failure modes the pre-flight catches:

- HEAD does not match the SHA in the prompt — the prompt was written
  against a different base, or the working tree drifted.
- A required doc the prompt told the agent to read is absent — likely
  a typo in the path, or the prompt was written against a different
  branch.

## 2. Write-target rule (two independent questions)

Two questions, NOT one. The regime answers "which TREE do I write code in";
your class answers "do I EMIT a patch at all". Do not collapse them — the
old binary ("isolated ⇒ patch + report; in-place ⇒ report") cannot express
a read-only agent in a live worktree.

**Question A — which tree do my code Writes/Edits go to (the regime)?**

- **ISOLATED (the class default for a read-write agent):** code
  Writes/Edits go to paths under `pwd` (your `worktree-agent-*` checkout) —
  parent-tree writes are rejected by the sandbox, and `/tmp` ("Additional
  working directories") is the reliable cross-boundary target for the
  report.
- **IN-PLACE (the degraded fallback):** code Writes/Edits go to paths under
  the parent working tree (the caller-scoped file set), and you report the
  degradation.

**Question B — do I emit a patch (am I read-write), and WHEN?**

- **Read-WRITE agent:** you DO produce a patch — but NOT up front. You do
  your edits + verification, write your report, and return. The patch is
  produced ONLY after a read-only reviewer confirms the work clean, when the
  orchestrator re-engages you (SendMessage) to emit it (`git diff >
  <handoff>/changes.patch` at THAT point). Never emit a patch on return.
- **Read-ONLY agent:** you emit NO patch — ever. Your single write is your
  report. This is the THIRD state the old binary could not express: a
  read-only agent operating IN a live worktree (because the work it reviews
  is uncommitted there) still writes only its report and produces no patch.

**Report location (both classes):** the report goes to the named `/tmp`
handoff dir the orchestrator supplies. If a `/tmp` handoff Write FAILS (the
handoff dir is not writable), fall back to the named parent-tree report path
and report the degradation — never hard-error on a failed handoff Write.

**Absolute prohibition (both regimes): NEVER retarget another agent's
main checkout.** When `pwd` is a `worktree-agent-*` checkout, writing to
the user's main checkout path (e.g.
`/Users/<user>/Developer/<repo>/<file>`) is FORBIDDEN even when the file
path "looks right" — the main checkout belongs to the user's interactive
shell and the orchestrator, not to the agent. The BD-119 C-2 incident was
exactly this failure mode: a Write rejected under the worktree path was
retried against the main checkout, which silently bypassed the workspace
boundary. If a `Write` returns "permission denied" or "file outside
workspace," the path is wrong for your regime — re-issue under the
correct target (parent tree IN-PLACE; `pwd` for code + `/tmp` for the
handoff ISOLATED), never against another agent's main checkout. This is a
cautionary guard, NOT a blanket "every Write must be under `pwd`" — in
the IN-PLACE regime the correct target IS the parent tree.

The "Additional working directories" note in the harness environment
(e.g., `/tmp/...`, `/private/tmp/...`) lists paths the agent may also
write to. The named `/tmp` handoff dir is where your report lands (and, for
a read-write agent, the post-review-clean patch once the orchestrator
re-engages you to emit it). In the degraded in-place fallback the `/tmp`
dir is scratch only and the report goes to the named parent path.

## 3. Git-state-change ban (absolute)

Forbidden verbs (no exceptions, no "but just this once") — the denied set,
"including but not limited to":

- `git add` / stage (`git add -p`, `git stage`, `git restore --staged`)
- `git commit`
- `git push`
- `git tag` (create/delete)
- `git rebase`
- `git merge`
- `git reset` (all modes)
- `git stash` (all subcommands)
- `git checkout` (path checkout and branch switch alike — plain
  `checkout` of a path is destructive; there is NO carve-out. To inspect
  a file at a different ref read-only, use `git show <ref>:<path>`)
- `git switch`
- `git rm`
- `git mv`
- `git restore`
- `git revert`
- `git cherry-pick`
- `git am`
- `git apply` (the patch-APPLYING form — only the orchestrator applies
  patches; `git diff` below is the agent's patch-EMIT and is allowed)
- `git clean`
- `git branch -d` / `git branch -D` / branch create
- `git worktree` (add/remove/move/prune)
- `git config` (write)
- `git remote` (write)
- `git update-ref` / `git update-index`
- `git pull`
- `git fetch`
- `git gc`
- `git reflog expire`
- `git filter-branch`
- `git notes` (write) / `git replace`

Allowed read-only verbs:

- `git status`
- `git diff` (any form, including `git diff <ref>...HEAD` and
  `git diff > <file>` — the read-only patch-emit; the `> <file>`
  redirection is a shell operation, not a git verb)
- `git log`
- `git rev-parse`
- `git show <ref>:<path>` (read a file's content at a different ref)
- `git ls-files`
- `git blame`

**Read-only-only principle (the catch-all).** Read-only git verbs are
allowed only; any git verb that changes repository, index, working-tree,
ref, or config state is forbidden — including but not limited to the
verbs enumerated above. If a verb is not on the allowed read-only list
and you are unsure, treat it as forbidden. This principle closes the
"the list never told me" gap for any unlisted verb.

The agent's deliverable on return is the report file (its edits live in the
worktree). A read-write agent does NOT emit a patch on return; the patch is
produced ONLY after a read-only reviewer confirms the work clean, when Pack
Chat re-engages the most-recent read-write agent (SendMessage) to emit it.
Pack Chat reads the report, runs the review/fix cycle in the worktree,
applies the reviewed-clean patch, runs tests if needed, and ONLY THEN stages
and commits with explicit user approval. An agent that stages or commits
has bypassed the user-approval gate — that is the entire reason the ban
exists.

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
`agent-run.sh` references, Antigravity's `agy` subagent invocation). Symmetry
is the default; asymmetry requires justification in the implementation
report.

The same rule applies to any pack-template trinity files (e.g., when
a skill is added under `project-template/skills/<name>/`, the
`project-template/.claude/skills/<name>/`, `project-template/.codex/skills/<name>/`,
and `project-template/.agents/skills/<name>/` mirrors must also be
updated — that's a quad, not a trinity, but the discipline is the
same).

For pack-repo agent files (`.claude/agents/`, `.codex/agents/`,
`.agents-plugin/pack-agents/agents/`), the same trinity discipline applies. Each agent's
content is mirrored across the three tools with tool-specific format
differences (Claude markdown frontmatter, Codex TOML, Antigravity markdown
frontmatter) but identical prose.

## 6. Anti-patterns the discipline catches

- Running `git add` to "tidy up" before reporting → forbidden by
  section 3.
- Targeting the wrong write-path for your regime → isolated writes go under
  `pwd` (code); the degraded in-place fallback writes under the parent tree;
  the report always goes to the named `/tmp` handoff dir. Writing the report
  to `/tmp` is CORRECT when the prompt named a `/tmp` handoff dir — it is
  NOT a "wrong path." The defect is mismatching the code-write target to the
  regime, or (in any regime) retargeting another agent's main checkout
  (section 2).
- Emitting a patch on return → a read-write agent never emits a patch up
  front; the patch is the post-review-clean step (section 2, Question B). A
  read-only agent emits no patch at all.
- Updating `/backlog/BD-NNN.md` to flip a Status field after a successful test
  run → pack-chat-only, forbidden by section 4. Pack Chat does the flip after
  review.
- Editing `CLAUDE.md` with a "minor clarification" without touching
  `AGENTS.md` and `GEMINI.md` → trinity violation, defect.
- Skipping the pre-flight because "the prompt is short" → still
  required; the pre-flight is what proves the run started clean.
