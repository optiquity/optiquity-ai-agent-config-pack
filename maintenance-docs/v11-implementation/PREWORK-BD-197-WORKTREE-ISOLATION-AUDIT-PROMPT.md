# PREWORK-BD-197 — Worktree-isolation blast-radius inventory prompt (v3 snapshot)

**Status:** BD-197 PREWORK ONLY — a non-binding starting reference. This is NOT the final audit prompt or scope. BD-197's P1 (brainstorm/research) and P2 (removal audit) author their own prompts fresh at implementation time; this snapshot exists only to preserve the *intent* of the broad search if chat history is lost.
**Captured:** 2026-06-01, against v11-dev. The file/line lists this prompt produces WILL drift; do not treat any resulting location list as authoritative.
**Provenance:** the third (gap-closed) iteration of the inventory prompt used during the 2026-05-31 / 2026-06-01 worktree-isolation verification work. It closed the hidden-dir / `.gitignore` / main-clone / plugins gaps found in earlier iterations.

---

## Verbatim prompt (v3)

```
I need a blast-radius inventory before changing any Claude Code worktree-isolation behavior. Find every location that gives instructions, settings, or guidance about Claude Code's Agent-tool worktree isolation (the isolation: "worktree" parameter, the worktree.baseRef setting, and the --worktree / EnterWorktree feature surface) anywhere it can affect this pack repo, the shipped project template, or any chat session that touches them.

This is READ-ONLY. No edits, no commits, no git mv/rm, no settings changes. Do NOT spawn any agent with isolation: "worktree" — the pack rule prohibiting it is still in force during this inventory.

Step 0 — Enumerate both worktree trees first; do not assume a directory list

Before searching, run a discovery pass against both the v11-dev worktree (your own) AND the main clone (where worktree-isolated agents physically execute today). Report what you found so the search targets the real layouts:

echo "--- v11-dev ---"
git rev-parse --show-toplevel
git branch --show-current
git log -1 --oneline
ls -1
find . -maxdepth 2 -type d -not -path './.git*' -not -path './node_modules*' | sort

echo "--- main clone ---"
git -C /Users/david/Developer/optiquity-ai-agent-config-pack rev-parse --show-toplevel
git -C /Users/david/Developer/optiquity-ai-agent-config-pack branch --show-current
git -C /Users/david/Developer/optiquity-ai-agent-config-pack log -1 --oneline
ls -1 /Users/david/Developer/optiquity-ai-agent-config-pack
find /Users/david/Developer/optiquity-ai-agent-config-pack -maxdepth 2 -type d -not -path '*/.git*' -not -path '*/node_modules*' | sort

Then list, with file counts, the contents of each of these dirs if they exist in EITHER tree (skip silently if absent):

- supporting-docs/, maintenance-docs/, maintenance-docs/v11-research/, maintenance-docs/v11-implementation/, maintenance-docs/archive/
- pack-ops/
- .claude/, .claude/agents/, .claude/skills/, .claude/commands/, .claude/hooks/
- .codex/, .codex/agents/, .codex/skills/, .codex/commands/
- .gemini/, .gemini/agents/, .gemini/skills/, .gemini/commands/
- scripts/, scripts/lib/, scripts/tests/
- test-fixtures/
- project-template/, project-template/.claude/, project-template/.codex/, project-template/.gemini/
- project-template/docs/, project-template/docs/pack/, project-template/docs/pack/prompts/
- project-template/scripts/, project-template/skills/
- project-template/.github/, project-template/.github/ISSUE_TEMPLATE/

Report any tree-specific directories you find that might plausibly contain agent/chat instructions (e.g., new per-entry flat-file directories, new agent prompt locations introduced for the per-entry architecture). Add them to the search scope before continuing.

Print the discovered structure as a single block titled TREE so I can sanity-check before reading the inventory.

Step 1 — What counts as a "worktree isolation instruction"

Include if it matches any of:

a. A rule that prohibits, permits, or constrains agents from using isolation: "worktree" (e.g., the CLAUDE.md ## Pack memory block).
b. Documentation describing what isolation: "worktree" does, its base-branch behavior, when to use it, or known bugs.
c. A settings.json / settings.local.json key under worktree.* (especially worktree.baseRef, worktree.basePath, anything in the worktree namespace).
d. A skill, agent definition, prompt template, methodology section, or coder/reviewer/planner spawn template that tells agents/chats to use, avoid, or configure worktree isolation. Per pack rule "Agent prompt enumerates all applicable rules inline", the worktree rule may be reproduced in MANY spawn prompts and SKILL.md files — find every reproduction.
e. Hook scripts that gate Agent-tool behavior on the isolation flag.
f. A script comment, helper, or env var that gates git worktree add based on the Claude Agent tool path.
g. MCP configs (.mcp.json, .mcp.json.example) that mention worktree behavior.
h. CHANGELOG / migration notes / BACKLOG items that reference the rule's history or proposed changes.
i. Validate-pack rules that enforce/check the convention (look in scripts/validate-pack.py and any pack-ops validators).
j. Test fixtures / golden files that contain the rule string.

Explicitly EXCLUDE:

- General git worktree mentions about manually-created worktrees unrelated to Claude Agent isolation.
- "isolation" in unrelated contexts (test/network/sandbox isolation).
- The Antigravity CLI docs snapshot under maintenance-docs/antigravity-cli-docs-snapshot-*/ — flag any hits separately (those are upstream docs, not pack rules).

When in doubt, include with flag-for-review.

Step 2 — Search areas (cover all that exist; expand based on TREE)

Pack-side (v11-dev worktree, the tree you live in):

- Root: CLAUDE.md, AGENTS.md, GEMINI.md, PACK-CHAT.md, PACK-AGENTS.md, README.md, BACKLOG.md, CHANGELOG.md
- supporting-docs/**
- maintenance-docs/** (include v11-research/, v11-implementation/, archive/; flag Antigravity snapshot dir separately)
- pack-ops/** (if present)
- .claude/** — especially agents/ (every pack-*.md agent definition), skills/*/SKILL.md, commands/, hooks/
- .codex/**, .gemini/** — agent files, skill files, commands. (The rule is Claude-only by design, but check for accidental parallels or asymmetric drift.)
- scripts/**, scripts/lib/**, scripts/tests/**
- test-fixtures/**
- .mcp.json, .mcp.json.example

Main-clone content side (at main HEAD — what a worktree-isolated agent actually reads at execution time):

A worktree-isolated agent today physically executes in the main clone at main's HEAD (verified by the 2026-05-31 probe: PWD=/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-…, HEAD=7ccbba9, reading main's tree). The rule text such an agent actually obeys lives in the main clone's content side, not v11-dev's. Search this scope separately and label findings as main-clone. Highlight any file whose content DIFFERS between v11-dev and main for the same path — that divergence is itself a risk surface.

- /Users/david/Developer/optiquity-ai-agent-config-pack/CLAUDE.md, /AGENTS.md, /GEMINI.md
- /Users/david/Developer/optiquity-ai-agent-config-pack/PACK-CHAT.md, /PACK-AGENTS.md, /README.md, /BACKLOG.md, /CHANGELOG.md
- /Users/david/Developer/optiquity-ai-agent-config-pack/supporting-docs/**
- /Users/david/Developer/optiquity-ai-agent-config-pack/maintenance-docs/** (note v11-research/ exists at main HEAD too — verified 2026-05-31)
- /Users/david/Developer/optiquity-ai-agent-config-pack/pack-ops/** (if present)
- /Users/david/Developer/optiquity-ai-agent-config-pack/.claude/**, /.codex/**, /.gemini/**
- /Users/david/Developer/optiquity-ai-agent-config-pack/scripts/**, /scripts/lib/**, /scripts/tests/**
- /Users/david/Developer/optiquity-ai-agent-config-pack/test-fixtures/**
- /Users/david/Developer/optiquity-ai-agent-config-pack/.mcp.json, /.mcp.json.example
- /Users/david/Developer/optiquity-ai-agent-config-pack/project-template/** (full project-template subtree, at main HEAD)

Project-template side (under project-template/, search both trees independently):

- project-template/CLAUDE.md, project-template/AGENTS.md, project-template/GEMINI.md
- project-template/docs/pack/** (METHODOLOGY.md and any agent/skill prompt docs)
- project-template/docs/pack/prompts/** (spawn prompt templates — these typically inline pack-memory rules)
- project-template/.claude/**, project-template/.codex/**, project-template/.gemini/** — agents, skills, commands
- project-template/scripts/**, project-template/skills/**
- project-template/.github/** (issue forms, workflows)
- project-template/.mcp.json.example

Claude CLI settings (project-level — read every file that exists; if not, say "absent"):

- /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.claude/settings.json
- /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.claude/settings.local.json
- /Users/david/Developer/optiquity-ai-agent-config-pack/.claude/settings.json
- /Users/david/Developer/optiquity-ai-agent-config-pack/.claude/settings.local.json
- /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/.claude/settings.json (and .local.json)
- /Users/david/Developer/optiquity-ai-agent-config-pack/project-template/.claude/settings.json (and .local.json)

Claude CLI settings (user-global):

- ~/.claude/settings.json
- ~/.claude/settings.local.json
- ~/.claude/CLAUDE.md (user-global memory; check for any worktree mentions)
- ~/.claude/agents/**
- ~/.claude/skills/**
- ~/.claude/commands/**
- ~/.claude/hooks/**
- ~/.claude/plugins/** — every installed plugin (e.g., commit-commands, pr-review-toolkit, coderabbit, context7, playwright). Plugin-shipped skills, agents, hooks, and commands can carry isolation guidance the same way native ones can. Recurse into each plugin's tree.

For every settings file: report whether a top-level worktree key exists; if yes, dump that block verbatim. If no, say "no worktree.* keys". Also flag any permissions rule that mentions isolation or worktrees.

Cross-CLI user-global (parity/drift detection):

- ~/.codex/AGENTS.md (if present), ~/.codex/config.toml (worktree-related options)
- ~/.gemini/GEMINI.md (if present), ~/.gemini/settings.json (worktree-related options)

Project-scoped user memory (Claude):

- ~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack/memory/**
- ~/.claude/projects/-Users-david-Developer-optiquity-ai-agent-config-pack-v11-dev/memory/**

Read every .md file in each and grep for worktree / isolation / baseRef. Report hits even if they're informational (memory entries that describe the rule).

Step 3 — How to search

Mandatory execution discipline (failure to apply these will silently miss the most consequential files — this has bit us twice already):

- rg MUST be invoked with --hidden --no-ignore for every scope. ripgrep's defaults skip hidden directories (.claude, .codex, .gemini) AND .gitignored files (settings.local.json, plugin internals, etc.) — both filters silently drop the files this inventory exists to find.
- Equivalent acceptable form: target every dot-dir by explicit path AND pass --no-ignore-vcs --no-ignore-dot --hidden so no filter is left on.
- For ~/.claude/plugins/**, individual plugins ship their own .gitignore-equivalents — keep --no-ignore on through plugin trees too.
- Verification: after each scope search, run rg --hidden --no-ignore -c 'worktree' <scope-root> and confirm you got hits in dot-dirs and *.local.json files where you expected them. If the count is suspiciously low, fix the flags before continuing.

Patterns (case-insensitive); sanity-check each hit with 5 lines of context:

- worktree
- isolation
- baseRef|base.?ref|base_ref
- Agent tool|Task tool near worktree
- subagent.*worktree|worktree.*subagent
- git worktree add (filter out pure plumbing scripts)
- \.claude/worktrees|\.git/worktrees

For project-template spawn prompts specifically, also grep for the literal rule fragments that may have been inlined verbatim:

- do not pass .*isolation
- worktree isolation
- Pack memory (the section title — could be reproduced in agent prompts)

Step 4 — Output format

Begin with the TREE block from Step 0 (both v11-dev and main-clone discovery output).

Then one section per scope, in this order:

1. Pack-side (v11-dev)
2. Main-clone content side
3. Project-template (v11-dev) — note differences from main-clone project-template if any
4. Settings — project-level
5. Settings — user-global (including plugins/)
6. Cross-CLI user-global
7. User memory

Inside each section, a table:

| File | Line(s) | Category (a–j) | Excerpt (≤3 lines verbatim) | Action if baseRef:"head" rolled out + isolation rule lifted |

For Action, classify as one of:

- delete — rule/doc/inlined-rule that prohibits isolation; would be obsolete.
- update — rule/doc that describes current behavior; needs the new behavior.
- add — settings file where the new worktree.baseRef key needs to land.
- none — purely informational; no action.
- flag-for-review — unclear; needs human judgment.

End with a synthesis block:

- Total locations: N
- By action: delete=N, update=N, add=N, none=N, flag=N
- Inlined-rule reproductions — count of places where the literal rule text was copied into agent/skill prompts (vs. referenced by link). High count = high coupling; future changes risk drift.
- v11-dev vs main-clone divergences — list every file path where the same-path file differs between the two trees in a worktree-rule-relevant way. Each is a risk surface (the agent reads main's version, not yours).
- Asymmetries — any place AGENTS.md or GEMINI.md mention the rule even though it's Claude-only by design; any settings file at one scope but not its peers.
- Surprises — anything you found a hit in that you didn't expect (especially in test fixtures, archived docs, plugin internals, or validator scripts).
- Risk callouts — indirect references that a naive grep worktree would miss (e.g., descriptions of the bug that don't use the word "worktree"; rules expressed via the Agent tool's prohibited flags).

Cap at ~2500 words. Cite file:line for every hit. No commits, no edits, no agent fan-out with worktree isolation.
```
