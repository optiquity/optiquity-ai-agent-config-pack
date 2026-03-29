# Gemini CLI — Integration Analysis

**Status:** Analysis only. No implementation in v8.
**Purpose:** Documents what would need to change to support Gemini CLI as a third
coding agent alongside Claude Code and Codex CLI.

---

## What is Gemini CLI?

Gemini CLI is Google's command-line AI coding agent, analogous to Claude Code CLI
and OpenAI Codex CLI. It runs in the terminal, reads project files, and executes
coding tasks. It uses `GEMINI.md` at the repo root as its primary instruction file,
mirroring the role of `CLAUDE.md` (Claude Code) and `AGENTS.md` (Codex).

---

## Instruction file equivalent

| Tool | Instruction file | Location |
|---|---|---|
| Claude Code | `CLAUDE.md` | Repo root (+ `~/.claude/CLAUDE.md` machine-level) |
| Codex CLI | `AGENTS.md` | Repo root (+ `~/.codex/AGENTS.md` machine-level) |
| Gemini CLI | `GEMINI.md` | Repo root (+ `~/.gemini/GEMINI.md` machine-level) |

**What would need to be added to the pack:**

A `GEMINI.md` in each template root, mirroring `CLAUDE.md` content adapted for
Gemini's instruction format. Content would be substantially the same: platform rules,
layer discipline, coding rules, security rules, agent routing. Differences would be
Gemini-specific syntax and any Gemini-specific behaviors discovered through use.

---

## Agent and skill equivalents

Claude Code uses `.claude/agents/` (subagent `.md` files) and `.claude/skills/`.
Codex uses `.codex/agents/` (`.toml` files) and `.codex/skills/`.

Gemini CLI's equivalent mechanism (as of early 2026) uses tool definitions and
system prompt extensions rather than a named subagent directory structure. The
agent roster concept (planner, coder, reviewer, etc.) would need to be expressed
differently — likely as separate `GEMINI.md` variants or prompt templates rather
than named agent files.

**What would need to be added:**
- Research the current Gemini CLI agent/tool extension mechanism
- If subagent-style files are supported: add `.gemini/agents/` directory to templates
- If not: document how to invoke role-specific behavior via prompt prefix conventions

---

## Settings and hook equivalent

Claude Code uses `.claude/settings.json` for permission allowlists and the
`PostToolUse` hook that fires `agent-post-edit-check.sh` after every file edit.
Codex uses `.codex/config.toml` with `post_edit_command`.

Gemini CLI's equivalent hook mechanism (if any) would need to be identified and
configured to call `scripts/agent-post-edit-check.sh` after file edits.

**What would need to be verified:**
- Does Gemini CLI support a post-edit hook or equivalent?
- Does Gemini CLI support a permission allowlist?
- If neither: document that Gemini edits do not trigger the build-check hook

---

## Recommended tool split (if Gemini CLI were added)

Based on each tool's strengths and documented capabilities:

| Phase | Recommended tool | Reason |
|---|---|---|
| Architecture / design | Claude Code | Strongest multi-file reasoning |
| API and schema design | Claude Code | grpc-schema agent, buf integration |
| Planning | Claude Code | Best context retention |
| Implementation | Codex or Gemini | Both have strong code generation |
| Code review | Claude Code | Best multi-file analysis |
| Testing | Codex or Gemini | Pattern generation |
| Python server work | Gemini or Codex | Google's tooling ecosystem affinity |
| Android (future) | Gemini | Native Google ecosystem alignment |

Gemini CLI's strongest practical value in this stack would be Python server and
future Android work, where Google's ecosystem knowledge is most directly relevant.

---

## Pack files that would need to change

| File | Change needed |
|---|---|
| `{template}/GEMINI.md` | New file per template — Gemini instruction file |
| `QUICKSTART.md` | Add Gemini CLI setup steps |
| `METHODOLOGY.md` | Update tool roles section |
| `PROMPT-TEMPLATES.md` | Note Gemini CLI invocation syntax |
| `xcode-companion-templates/` | Verify if Xcode 26.3 supports Gemini as a provider |
| `README.md` | Update template comparison table |

Files that would NOT need to change: existing `.claude/` and `.codex/` directories,
shell scripts, proto scaffold, `CLAUDE.md`, `AGENTS.md`.

---

## Xcode 26.3 compatibility

Xcode 26.3 supports Claude and Codex as AI providers. As of March 2026, Gemini is
not listed as a supported Xcode AI provider. This would need to be re-verified when
Google announces Xcode integration (if any).

---

## Recommendation for a future version

Add Gemini CLI support when:
1. Gemini CLI's agent/subagent mechanism stabilizes and is documented
2. There is a concrete project need (Python-heavy or Android work)
3. Xcode integration is confirmed or confirmed absent

Estimated pack effort: 3–5 new files per template + QUICKSTART/METHODOLOGY updates.
