# RESEARCH-BD-197 — In-session sub-agent destructive-git-verb backstop: verified facts

**Role:** pack-docs-researcher (read-only + web research; this report is the sole write).
**Repo:** optiquity-ai-agent-config-pack-v11-dev · **Branch:** v11-dev · **HEAD:** `05ad61b4ca86a743d27230ec86a8252a55c064d4`.
**Date:** 2026-06-14. **Local Claude Code CLI:** `2.1.177` (`claude --version`). Architecture doc probed `2.1.173`; flag/field set unchanged between the two.
**Scope:** verify (not assume) the mechanics behind BD-197's in-session sub-agent git-verb ban, with GA-vs-experimental status + citations. Does NOT design the solution.

---

## Read attestation

Read in full before any claim:
- `project-template/.claude/agents/coder.md` (RW agent; `tools: Read, Grep, Glob, Edit, Write, MultiEdit, Bash` — bare tool NAMES; Hard rules enumerate the git ban in PROSE only).
- `project-template/.claude/agents/reviewer.md`, `architect.md` (RO agents; `tools:` carry `Write, Edit` yet are RO by prose — confirms `tools:` is NOT the RW/RO signal).
- `project-template/agent-run.sh` in full — the project launcher. Lines 96–99 `CLAUDE_READONLY_FLAGS` already pass `--permission-mode bypassPermissions` + `--disallowedTools "Bash(git commit:*)" "Bash(git push:*)"` for the `claude` CLI; comment at lines 97–98 asserts "blocks git commit and push regardless of permission mode."
- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` §5 (git-permission contract: full DENIED set §5.1, ALLOWED set §5.2, prose-surfaces + mechanical-backstop §5.3, VERB-PRECISE backstop pinned G-4) and §1.1 FACT-1..5 (the empirical mode model the design rests on).
- `CLAUDE.md` `## Pack memory` — `verify-availability-not-just-existence` lives there as the **"Verify feature availability, not just existence"** entry (memory index pointer `feedback_verify_availability_not_just_existence.md`).

Repo-state checks run:
- `grep '^tools:' project-template/.claude/agents/*.md` → all 16 project agents carry a bare comma-list of tool NAMES; `Bash` is granted whole on every one. No frontmatter expresses a Bash sub-verb pattern.
- The pack-side agent files (`coder.md` here mirrors the pack class) likewise use bare tool-name `tools:` fields.

---

## Availability matrix

GA status legend: **GA** = documented in the stable Claude Code docs / CLI reference with no preview/experimental marker; **GA (local-confirmed)** = also confirmed present in `claude --help` on 2.1.177; **EXPERIMENTAL** = doc explicitly marks it experimental; **N/A** = not the right tool for the job.

| # | Capability needed | Mechanism | GA status | Citation | Verdict |
|---|---|---|---|---|---|
| 1a | Restrict a sub-agent to specific TOOL NAMES | agent-def frontmatter `tools:` (allowlist) / `disallowedTools:` (denylist) | GA | sub-agents.md "Supported frontmatter fields" + "Available tools" | **USABLE — but tool-NAME granularity only** |
| 1b | Deny a specific Bash git VERB to a sub-agent VIA FRONTMATTER `tools:`/`disallowedTools:` | frontmatter `tools:`/`disallowedTools:` field | GA | sub-agents.md (examples are whole-tool: `Bash`, `Write`, `Edit`) | **NOT USABLE for sub-verb granularity** — frontmatter field is tool-name level; cannot express `git commit` vs `git diff` |
| 1c | Per-spawn restriction param on the Agent/Task tool (parent passes `disallowedTools` at spawn) | Agent-tool call parameter | UNVERIFIED (not documented) | sub-agents.md documents Agent-tool params `subagent_type`, `model`, `isolation`; no `disallowedTools`/`tools` per-spawn param documented | **NOT USABLE / UNVERIFIED** — no documented per-spawn tool-restriction param |
| 2a | Sub-agents inherit session `permissions.deny` (e.g. `Bash(git push:*)`) | `settings.json` `permissions.deny` | GA | permissions.md (deny rules, `Bash(git push *)`); sub-agents.md ("background subagents run with the permissions already granted in the session") | **USABLE** |
| 2b | `settings.json` `PreToolUse` hooks FIRE for sub-agent tool calls | `settings.json` `hooks.PreToolUse` | GA | hooks.md: `agent_id` "Present only when the hook fires inside a subagent call"; `agent_type` "Present when … the hook fires inside a subagent" | **USABLE** |
| 2c | Per-sub-agent-definition `PreToolUse` hook (frontmatter) that validates/denies Bash | agent-def frontmatter `hooks.PreToolUse` | GA | sub-agents.md "Define hooks for subagents" (frontmatter `PreToolUse` matcher `Bash` → `validate-command.sh`) | **USABLE** |
| 3 | Mechanical in-session backstop WITHOUT the pack shipping a settings file (user adds it to THEIR settings) | user-authored `permissions.deny` and/or `PreToolUse` hook in `~/.claude/settings.json` or project `.claude/settings.json` | GA | permissions.md (settings sources); hooks.md (settings.json hooks) | **USABLE — but requires the USER to configure it; not active out-of-box** |
| 4a | `claude --disallowedTools` restricts the agent's tools (launcher path) | CLI flag `--disallowedTools` / `--disallowed-tools` | GA (local-confirmed) | cli-reference.md `--disallowedTools` (scoped `Bash(rm *)` denies matching calls); `claude --help` 2.1.177 | **USABLE** |
| 4b | `claude --allowedTools` / `--tools` / `--permission-mode` | CLI flags | GA (local-confirmed) | cli-reference.md `--allowedTools`, `--tools`, `--permission-mode`; `claude --help` 2.1.177 | **USABLE** (note `--allowedTools` = auto-approve, NOT restrict; use `--tools` or `--disallowedTools` to restrict) |
| 5a | Exact shape of `hooks.PreToolUse` | schemastore schema | GA | schemastore claude-code-settings.json `properties.hooks.properties.PreToolUse` → array of `hookMatcher` | **CONFIRMED** |
| 5b | Exact shape of `permissions.deny` | schemastore schema | GA | schemastore `properties.permissions.properties.deny` → array of `permissionRule` (string, pattern allows `Bash(...)`) | **CONFIRMED** |
| 5c | `WorktreeCreate`/`WorktreeRemove` hooks enforce the git-verb ban? | schema + hooks.md | GA (events exist) | hooks.md: WorktreeCreate fires "When a worktree is being created"; WorktreeRemove "When a worktree is being removed" | **NOT RELEVANT to the ban** — fire on worktree lifecycle, not on git-verb attempts |
| (mode) | `worktree.baseRef` / `worktree.bgIsolation` shapes | schemastore schema | GA | schemastore `properties.worktree` (baseRef enum `[fresh,head]` default fresh; bgIsolation enum `[worktree,none]` default worktree) | **CONFIRMED** (matches ARCH FACT-2/FACT-3) |

---

## Per-question findings

### Q1 — In-session sub-agent tool restriction (can specific Bash git verbs be denied?)

**(a) The frontmatter `tools:` field is an allow-list of tool NAMES; it does NOT express granular Bash command patterns or denials.**

The official subagents doc, "Supported frontmatter fields" table:
> `tools` — No — [Tools] the subagent can use. Inherits all tools if omitted.
> `disallowedTools` — No — Tools to deny, removed from inherited or specified list

The "Available tools" / restriction examples operate at WHOLE-TOOL granularity only:
> "To restrict tools, use either the `tools` field (allowlist) or the `disallowedTools` field (denylist). This example uses `tools` to exclusively allow Read, Grep, Glob, and Bash. The subagent can't edit files, write files, or use any MCP tools" — `tools: Read, Grep, Glob, Bash`
> `disallowedTools: Write, Edit` ("inherit every tool … except Write and Edit. The subagent keeps Bash…").

There is no example anywhere in the subagents doc of a `Bash(git commit:*)`-style sub-verb pattern inside the frontmatter `tools:`/`disallowedTools:` field — those fields name TOOLS (`Bash`, `Write`, `Edit`, `Agent`, MCP names). The one parenthesised form the doc shows for frontmatter is `Agent(worker, researcher)` (sub-agent-type allowlist), NOT Bash sub-verbs. **Conclusion: the agent-definition `tools:` field cannot mechanically deny `git commit` while allowing `git diff`.** This matches the repo: all 16 project agents grant `Bash` whole.

**(b) No documented per-spawn tool-restriction parameter on the Agent/Task tool.**

The documented per-spawn Agent-tool parameters are `subagent_type` (hooks.md schema line: `subagent_type | string | "Explore"`), a per-invocation `model`, and `isolation: "worktree"` (sub-agents.md: "When Claude spawns a fork through the Agent tool, it can pass `isolation: \"worktree\"`"). **No `disallowedTools` / `tools` per-spawn parameter is documented** for the Agent tool. The in-repo Agent tool schema (this very session's tool) likewise exposes no such field — consistent with the docs. **A parent therefore cannot, at spawn time, hand a sub-agent a per-call `disallowedTools` for git verbs.** (UNVERIFIED-as-absent: docs are silent rather than stating "impossible"; treat as NOT AVAILABLE.)

**Bottom line Q1:** Per-verb Bash denial is NOT achievable through the agent-definition `tools:` field or any per-spawn Agent-tool parameter. Sub-verb granularity comes only from the permission system (`permissions.deny` Bash patterns) or a `PreToolUse` hook — see Q2/Q3.

### Q2 — Inheritance of session-level controls by sub-agents

**Both `permissions.deny` AND `PreToolUse` hooks reach sub-agent tool calls — VERIFIED.**

`permissions.deny` inheritance:
- sub-agents.md (background sub-agents): "They run with the **permissions already granted in the session** and auto-deny any tool call that would otherwise prompt." (The PRIMARY UC-1 path spawns in the background.)
- sub-agents.md: built-in sub-agents are blocked by adding `Agent(Explore)` to `permissions.deny`, and the doc says deny rules "apply to subagent sessions" — `permissions.deny` is a session-wide control, not main-thread-only.
- permissions.md, evaluation order: "deny, then ask, then allow"; deny rules are evaluated regardless of `PreToolUse` hook output (deny-first precedence "including deny rules set in managed settings").
- permissions.md Bash matching: `"Bash(git push *)"` / `"Bash(git commit *)"`; the `:*` suffix "is an equivalent way to write a trailing wildcard, so `Bash(ls:*)` matches the same … as `Bash(ls *)`" — so `Bash(git push:*)` is valid deny syntax. NOTE: read-only git forms run without a prompt by default ("read-only forms of `git`"), so a denylist (not an allowlist-by-omission) is the correct shape — exactly the design's D5 denylist-primary choice.

`PreToolUse` hook firing inside sub-agents (the decisive proof):
- hooks.md common-input-fields: **`agent_id` — "Present ONLY when the hook fires inside a subagent call. Use this to distinguish subagent hook calls from main-thread calls."** A field defined as present-only-inside-subagents is direct evidence the hook fires there.
- hooks.md: **`agent_type` — "Present when the session uses `--agent` or the hook fires inside a subagent."**
- hooks.md "Define hooks for subagents" (sub-agents.md cross-ref): a frontmatter `PreToolUse` matcher `Bash` runs a validator before the sub-agent uses Bash.
- The canonical block recipe (hooks.md): a `PreToolUse` hook with `matcher: Bash` + `if: "Bash(git *)"` returning `{permissionDecision: "deny"}` blocks the command; and "a hook that returns `permissionDecision: \"deny\"` blocks the tool even in bypassPermissions mode."

**Caveat (verified, load-bearing for the architect):** hooks.md warns the `if` Bash filter is **best-effort and fails OPEN** — "The filter also fails open, running your hook regardless of pattern, when the Bash command cannot be parsed. Because the `if` filter is best-effort, **use the permission system rather than a hook to enforce a hard allow or deny.**" So for a HARD guarantee, `permissions.deny` is the authoritative layer; a PreToolUse hook is a complementary/defence-in-depth layer (and its own script can still hard-deny by exit-2, but routing via `if`-matchers is fragile).

**Bottom line Q2:** A single user-configured `permissions.deny` block (or PreToolUse hook) in settings.json DOES mechanically cover ALL in-session sub-agents — including background ones — because deny rules are session-scoped and inherited, and PreToolUse hooks demonstrably fire inside sub-agent calls.

### Q3 — No-shipped-settings path (documented optional user backstop vs. shipping a settings file)

**A mechanical in-session backstop CAN exist that the pack only DOCUMENTS for the user to add to THEIR settings — it does NOT require the pack to ship a settings file. But it is not active out-of-box; absent user configuration, only the prose ban + agent behaviour apply.**

- The permission/hook mechanisms (Q2) live in `settings.json` at user (`~/.claude/settings.json`) or project (`.claude/settings.json`) scope. permissions.md: rules "can be checked into version control … as well as customized by individual developers." Nothing requires the PACK to be the author — the USER can add the same `permissions.deny` block / PreToolUse hook to their own settings, and it will apply to that user's sessions (and their sub-agents per Q2).
- This is exactly the model the architecture doc §5.3 lands on: prose ban everywhere + a mechanical backstop the user opts into; the pack ships NO `worktree`/permission settings file (ARCH §7 "P3 must NOT add a `worktree` key to the shipped template").
- **Honest limit (verify-availability):** With NO settings file shipped and the user NOT having configured the optional backstop, there is **no mechanical enforcement** of the git-verb ban for in-session sub-agents — enforcement degrades to (1) the always-on PROSE deny-list in the agent files / trinity / commit-discipline skill, and (2) the agents-never-commit behavioural contract. The mechanical layer is real and reachable but OPT-IN.

**Bottom line Q3:** "Documented optional user-configured mechanical backstop (a `permissions.deny` block and/or PreToolUse hook the user adds) + always-on prose deny-list" is a VIABLE model. Mechanical enforcement is NOT impossible without a shipped settings file — it is simply user-activated rather than out-of-box. (One nuance for the architect: the project-side `agent-run.sh` LAUNCHER path is the one place the pack already ships a mechanical backstop without a settings file — see Q4 — but that path covers `claude --agent` launches, not Agent-tool in-session sub-agents.)

### Q4 — Launcher path (`agent-run.sh` runs `claude --agent <name>`)

**The `claude` CLI accepts flags that mechanically restrict the launched agent's tools, including per-verb Bash denials. VERIFIED GA (and confirmed in `claude --help` 2.1.177).**

- **`--disallowedTools` / `--disallowed-tools` <tools...>** — cli-reference.md: "Deny rules. A bare tool name removes the matching tools from the model's context … A scoped rule such as `Bash(rm *)` leaves the tool available and denies only matching calls." `claude --help`: "Comma or space-separated list of tool names to deny (e.g. `\"Bash(git *)\" Edit`)." → **This is the launcher backstop.** `agent-run.sh` already uses it: `--disallowedTools "Bash(git commit:*)" "Bash(git push:*)"`. The architecture doc §5.3 extends it to `Bash(git stash:*)`, `Bash(git reset:*)`, `Bash(git restore:*)`, `Bash(git checkout:*)`, `Bash(git apply:*)`, `Bash(git worktree:*)`, `Bash(git clean:*)` — all valid per the same scoped-rule syntax.
- **`--allowedTools` / `--allowed-tools`** — cli-reference.md: "Tools that execute **without prompting** for permission … To restrict which tools are available, use `--tools` instead." → IMPORTANT: this is auto-APPROVE, NOT a restriction. Do not use `--allowedTools` to enforce the ban.
- **`--tools` <tools...>** — cli-reference.md: "Restrict which built-in tools Claude can use. Use `\"\"` to disable all, `\"default\"` for all, or tool names like `\"Bash,Edit,Read\"`." → tool-NAME granularity only (cannot deny a git sub-verb; same limit as Q1a).
- **`--permission-mode` <mode>** — cli-reference.md / `claude --help`: accepts `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, `plan`. (`agent-run.sh` uses `bypassPermissions` for RO agents.) NOTE: `--disallowedTools` deny rules are NOT bypassed by `bypassPermissions` (permissions.md deny-first precedence) — so the comment at `agent-run.sh:98` "blocks git commit and push regardless of permission mode" is CORRECT.

**Exact flag for the launcher backstop:** `--disallowedTools` (alias `--disallowed-tools`), passing scoped `Bash(git <verb>:*)` / `Bash(git <verb> *)` patterns — one per denied verb. This is the precise mechanical backstop the design assumes, and it is already partially in place.

**Bottom line Q4:** The launcher mechanical backstop is `claude --agent <name> --disallowedTools "Bash(git commit:*)" "Bash(git push:*)" …` (extend the verb list per ARCH §5.1). GA, confirmed locally. The launcher path is INDEPENDENT of the in-session Agent-tool path — it covers `claude --agent` invocations, not Agent-tool sub-agents.

### Q5 — PreToolUse hook + settings shapes; are Worktree hooks relevant?

From the official settings schema (https://www.schemastore.org/claude-code-settings.json, fetched 2026-06-14, 119,740 bytes):

**`hooks.PreToolUse`** — `properties.hooks.properties.PreToolUse`:
```
{ "type": "array", "description": "Hooks that run before tool calls",
  "items": { "$ref": "#/$defs/hookMatcher" } }
```
`$defs.hookMatcher`:
```
{ "type": "object", "required": ["hooks"],
  "properties": {
    "matcher": { "type": "string", "description": "Optional pattern to match event contexts…" },
    "hooks":   { "type": "array", "items": { "$ref": "#/$defs/hookCommand" } } } }
```
(For PreToolUse the matcher is a TOOL NAME, e.g. `Bash` or `Edit|Write` — hooks.md matcher table. The per-hook `if` field, e.g. `"Bash(git *)"`, narrows by Bash subcommand — hooks.md `hookCommand` field `if`.)

**`permissions.deny`** — `properties.permissions.properties.deny`:
```
{ "type": "array", "uniqueItems": true,
  "description": "List of permission rules for denied operations",
  "items": { "$ref": "#/$defs/permissionRule" } }
```
`$defs.permissionRule` (string with pattern; examples include the exact git form):
```
"pattern": "^((Agent|Bash|Edit|…|Write)(\\([^)]+\\))?|mcp__.*)$",
"examples": [ "Bash", "Bash(npm run build)", "Bash(git commit *)", "Bash(git * main)", "Edit", … ]
```
→ `permissions.deny` accepts `Bash(git commit *)`-style rules natively (schema-blessed example). The `worktree` object (verified): `baseRef` enum `["fresh","head"]` default `"fresh"`; `bgIsolation` enum `["worktree","none"]` default `"worktree"` — matches ARCH FACT-2/FACT-3 exactly.

**`WorktreeCreate` / `WorktreeRemove` hooks — NOT relevant to enforcing the git-verb ban.** They are distinct hook events in the schema (`hooks.properties` includes both) and fire on WORKTREE LIFECYCLE, not on git-verb attempts:
- hooks.md events table: `WorktreeCreate` — "When a worktree is being created via `--worktree` or `isolation: \"worktree\"`. Replaces default git behavior." `WorktreeRemove` — "When a worktree is being removed, either at session exit or when a subagent finishes."
- Both are matcher-less ("always fire on every occurrence").
- They could let a user customize HOW the worktree is created/cleaned up, but they do NOT intercept a sub-agent's `git commit`/`git push`. The verb-attempt interception is `PreToolUse` (+ `permissions.deny`). **Confirmed: WorktreeCreate/Remove fire on create/remove, not on git-verb attempts.**

---

## BOTTOM LINE

**Q: Can the in-session destructive-git-verb ban be mechanically enforced for sub-agents WITHOUT the pack shipping a settings file?**

**YES — but only as a USER-ACTIVATED backstop, not out-of-box.** The mechanism exists and is GA:
- A `permissions.deny` block in the USER's own `settings.json` (user or project scope) listing the banned verbs as scoped Bash rules — e.g. `"Bash(git commit:*)"`, `"Bash(git push:*)"`, `"Bash(git add:*)"`, `"Bash(git reset:*)"`, `"Bash(git checkout:*)"`, `"Bash(git apply:*)"`, `"Bash(git worktree:*)"`, etc. (full ARCH §5.1 set). Deny rules are session-scoped, inherited by sub-agents (including background ones), and deny-first (not bypassed by `bypassPermissions`). This is the AUTHORITATIVE hard layer (hooks.md explicitly says "use the permission system rather than a hook to enforce a hard … deny").
- OPTIONALLY a `PreToolUse` hook (matcher `Bash`) in the user's settings.json or in agent-definition frontmatter, returning `permissionDecision: "deny"` for matching git verbs — a defence-in-depth layer (caveat: the `if`-matcher is best-effort/fails-open; a custom validator script that exit-2s is the robust hook form).

The pack ships NEITHER — it DOCUMENTS the recommended `permissions.deny` block (and optional hook) in OPTIONAL-FEATURES for the user to add. **Without the user adding it, there is NO mechanical in-session enforcement** — only the always-on prose deny-list (agent files + trinity + commit-discipline skill) and the agents-never-commit behavioural contract. So the best available no-shipped-settings model is exactly: **always-on prose deny-list (load-bearing default) + a documented, optional, user-configured `permissions.deny` backstop (mechanical hard-enforcement when activated) + optional PreToolUse hook (defence-in-depth).**

What is NOT achievable (verified absent): per-verb Bash denial via the agent-definition `tools:` frontmatter field (tool-NAME granularity only), and any per-spawn Agent/Task-tool `disallowedTools` parameter (undocumented; the in-repo Agent tool exposes no such field). So the in-session Agent-tool path has NO self-contained per-agent mechanical git-verb lock — the only in-session mechanical layer is the session-level `permissions.deny`/hook the user configures.

**Q: What exact flag(s) give the `agent-run.sh` launcher a mechanical backstop?**

`claude --agent <name> --disallowedTools "Bash(git commit:*)" "Bash(git push:*)" "Bash(git add:*)" "Bash(git stash:*)" "Bash(git reset:*)" "Bash(git restore:*)" "Bash(git checkout:*)" "Bash(git apply:*)" "Bash(git worktree:*)" "Bash(git clean:*)" …` — i.e. **`--disallowedTools`** (alias `--disallowed-tools`) with one scoped `Bash(git <verb>:*)` rule per banned verb. GA, confirmed in `claude --help` 2.1.177 and cli-reference.md. The launcher already uses this flag for `commit`/`push`; extend the verb list per ARCH §5.1. Do NOT use `--allowedTools` (that is auto-approve, not restriction) and note `--tools` is tool-NAME-only (cannot deny a git sub-verb). The launcher backstop is INDEPENDENT of the in-session path and applies only to `claude --agent` launches.

---

## Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| **verify-availability-not-just-existence** [researcher] | Each capability carries a GA/EXPERIMENTAL/UNVERIFIED verdict in the availability matrix, tied to the actual target (Agent-tool sub-agent vs `claude --agent` CLI). E.g. CLI flags marked "GA (local-confirmed)" against `claude --version`=`2.1.177`; the per-spawn Agent-tool `disallowedTools` param marked **NOT USABLE / UNVERIFIED** (no doc); frontmatter sub-verb denial marked **NOT USABLE** (tool-name granularity, quoted). The `if`-hook fails-open caveat surfaced verbatim from hooks.md. | COMPLIANT |
| **external-rules-census-before-design** [researcher] | Complete rule set enumerated from authoritative docs BEFORE any design: hook firing scope (`agent_id` present-only-in-subagent), permission inheritance (background sub-agents "run with permissions already granted in the session"; deny-first precedence), flag availability (`--disallowedTools`/`--tools`/`--permission-mode` from cli-reference.md + `claude --help`), schema shapes (schemastore `permissionRule`/`hookMatcher`/`worktree`), and the WorktreeCreate/Remove non-relevance. | COMPLIANT |
| **empirical-evidence-blocks** [researcher] | Every finding cites source (URL/schema path) + quoted text + GA status + date (2026-06-14). Repo-state claims backed by command output: `git rev-parse HEAD`=`05ad61b4…`, `grep '^tools:' …/agents/*.md` (all bare tool names), `claude --version`=`2.1.177`, `claude --help` flag extracts, schemastore fetch (119,740 bytes) with `python3` JSON extraction of `worktree`/`permissions.deny`/`hooks.PreToolUse`/`permissionRule`/`hookMatcher`. | COMPLIANT |
| **scope-deliverables-to-the-ask** [universal] | Answered Q1–Q5 precisely with an availability matrix + per-question sections + a two-part bottom-line; flagged UNVERIFIED items honestly (per-spawn Agent-tool param); no design proposed (left to architect); no edge-case sprawl. | COMPLIANT |
| **agents-never-commit** [universal] | Read-only + web research only. No state-changing git verb run (only `git rev-parse`, `grep`, `curl`, `python3`, `claude --help`/`--version`). Single write = this report at the caller-specified path. | COMPLIANT |
| **rules-applied-verification-block** [universal] | This block. | COMPLIANT |

---

## Sources

- [Create custom subagents — Claude Code Docs](https://code.claude.com/docs/en/sub-agents)
- [Configure permissions — Claude Code Docs](https://code.claude.com/docs/en/permissions)
- [Hooks reference — Claude Code Docs](https://code.claude.com/docs/en/hooks)
- [CLI reference — Claude Code Docs](https://code.claude.com/docs/en/cli-reference)
- [Claude Code settings JSON schema — SchemaStore](https://www.schemastore.org/claude-code-settings.json)
- Local CLI: `claude --version` → `2.1.177`; `claude --help` (tool/permission flag set).
