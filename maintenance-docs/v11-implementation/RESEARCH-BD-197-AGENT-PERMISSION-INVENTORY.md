# RESEARCH-BD-197 — Holistic Agent-Permission Inventory (RW/RO, both surfaces)

**Role:** pack-docs-researcher (fresh). **Mode:** read-only.
**Repo:** optiquity-ai-agent-config-pack-v11-dev · **Branch:** v11-dev
**HEAD:** `3e3159ee8b5e97bf8775ecf67a76867d28933a3e` (`3e3159e`)
**Measured:** 2026-06-13.
**Scope:** Inventory + categorize only. This document classifies every agent
RW vs RO on both surfaces, maps every surface where agent-permission rules
live today, documents the as-built RO-enforcement mechanics, and proposes
placement options for a centralized RW/RO declaration. It does NOT design the
final placement — that is the BD-197 architect's job.

---

## 0. Executive summary

- **Pack side:** 5 agents per CLI (×3 CLIs = 15 files). **1 RW** (`pack-coder`)
  + **4 RO** (`pack-architect`, `pack-planner`, `pack-reviewer`,
  `pack-docs-researcher`).
- **Project side:** 16 agents per CLI (×3 CLIs = 48 files). **2 RW**
  (`coder`, `repo-ops`) + **14 RO** (architect, planner, reviewer, tester,
  docs-researcher, grpc-schema, auditor + the 7 auditor-* clusters). The
  "14 RO" reconciles three independent ways (see §1.2).
- **Tool-set does NOT mechanically distinguish RW from RO.** On BOTH surfaces,
  almost every RO agent carries `Write, Edit` (Claude) or
  `sandbox_mode = "workspace-write"` (Codex) so it can emit its single report.
  The RW/RO distinction is carried by the agent's **prose mandate header**
  ("**Read-only.**" vs "**Write-capable (scoped).**") plus, project-side, the
  `agent-run.sh` `READONLY_AGENTS` runtime-flag dispatch.
- **There is NO single centralized cross-surface RW/RO list today.** The
  classification is scattered across roster tables, agent-file prose headers,
  a runtime dispatch array, and a PM-facing profile table. Pack-side and
  project-side are separate artifact sets (§4).
- **`agents-never-commit` + destructive-verb-ban already exists** on both
  surfaces and (project-side coder/reviewer/architect + pack-coder + the
  commit-discipline skill) already enumerate `git stash` / `git reset` /
  `git rm`. BD-197 folded-scope hardening is partly landed; gaps in §2/§4.
- **Bug-era worktree content is live** in the commit-discipline skill ×3 (it
  assumes a `worktree-agent-*` branch + worktree `pwd`). This is BD-197 P2
  removal target, confirmed present (§3.4).

---

## 1. Agent rosters, classified RW vs RO

### 1.1 PACK side (5 agents × 3 CLIs)

**Files measured** (`ls .claude/agents/ .codex/agents/ .gemini/agents/`,
2026-06-13): `pack-architect`, `pack-coder`, `pack-docs-researcher`,
`pack-planner`, `pack-reviewer` — present in all three CLI dirs
(`.md` for Claude/Gemini, `.toml` for Codex). 15 files total.

| Agent | Class | Roster `Mode` (PACK-AGENTS.md) | `tools:` (Claude frontmatter) | Evidence of class |
|---|---|---|---|---|
| `pack-coder` | **RW** | "Source-write within scope; **never** stages or commits" | `Read, Grep, Glob, Bash, Write, Edit` | Description: "makes the file changes in its worktree". Body line 86: "**Read-only outside scope:** do not modify files outside what the caller's prompt scopes you to." Line 33: "**No git state changes, ever.**" |
| `pack-architect` | RO | "Read-only" | `Read, Grep, Glob, Bash` (no Write/Edit) | Description: "Read-only analysis and recommendations." Output policy: report-only Write. |
| `pack-planner` | RO | "Read-only" | `Read, Grep, Glob, Bash` (no Write/Edit) | Body: "State queries are read-only and within [scope]". Output policy: single plan-document Write. |
| `pack-reviewer` | RO | "Read-only" | `Read, Grep, Glob, Bash, **Write, Edit**` | Body line 35-41: "Your single permitted file write is exactly one final report file ... the review is read-only on the codebase otherwise. The Write/Edit tools are listed only to enable the report deliverable; their use outside the prompted report path is a defect." |
| `pack-docs-researcher` | RO | "Read-only" | `Read, Grep, Glob, WebSearch, Bash` | Output policy: report-only Write. (This agent.) |

**Reconciliation (pack):** roster table in `pack-ops/PACK-AGENTS.md` lines
15-19 lists exactly 5 agents with `Mode` column = 1 source-write + 4
read-only. Matches file count (5 per CLI) and the per-file prose mandates. OK

**Note (pack-reviewer tools anomaly):** `pack-reviewer` is the one pack RO
agent whose `tools:` includes `Write, Edit` (to emit its report). So pack-side
`tools:` is NOT a reliable RW/RO discriminator either — only `pack-coder`'s
**role/scope** makes it RW; `pack-architect`/`pack-planner` happen to omit
Write/Edit but `pack-reviewer` does not. The discriminator is the prose header
+ roster `Mode` cell, not the tool list.

### 1.2 PROJECT side (16 agents × 3 CLIs)

**Files measured** (`ls project-template/.claude/agents/` etc., 2026-06-13):
16 files per CLI dir (48 total). Roster (alpha): `architect`,
`auditor`, `auditor-architecture`, `auditor-code`, `auditor-docs`,
`auditor-ops`, `auditor-security`, `auditor-tests`, `auditor-ui`, `coder`,
`docs-researcher`, `grpc-schema`, `planner`, `repo-ops`, `reviewer`,
`tester`.

| Agent | Class | Claude `tools:` | Mandate header in agent body | Evidence |
|---|---|---|---|---|
| `coder` | **RW** | `Read, Grep, Glob, Edit, Write, MultiEdit, Bash` | "**Write-capable (scoped).**" (line 24) | "You may write or edit source files within [scope]. Outside that scope, treat the repository as read-only." |
| `repo-ops` | **RW** | `Read, Grep, Glob, Edit, Write, MultiEdit, Bash` | (no `**Read-only**` header; "branch-safe scripted edits") | Description: "branch-safe scripted edits, local automation". Line 64: "**No hand-written source edits.** Generated files within the [scope]" — RW but limited to scripted/generated edits. Classified Write-capable by PM-CHAT.md + agent-run.sh. |
| `architect` | RO | `Read, Grep, Glob, Bash, Write, Edit` | "**Read-only.**" (line 22) | "The single permitted file write ... is exactly one final report file." |
| `planner` | RO | `... Write, Edit` | "**Read-only.**" (line 18) | report-only |
| `reviewer` | RO | `... Write, Edit` | "**Read-only.**" (line 16) | report-only |
| `tester` | RO | `... Write, Edit` | "**Read-only.**" (line 17) | report-only |
| `docs-researcher` | RO | `... WebSearch, Bash, Write, Edit` | "**Read-only.**" (line 17) | report-only + web |
| `grpc-schema` | RO | `... Write, Edit` | "**Read-only.**" (line 17) | "schema *design*" but mandate = report-only; it recommends fixes, does not write proto. Line 89: "Recommended fixes." |
| `auditor` | RO | `Read, Grep, Glob, Bash, **Task**, Write, Edit` | "**Read-only.**" (line 46) | Parent orchestrator; spawns auditor-* via Task; description ends "Read-only." |
| `auditor-architecture` | RO | `... Write, Edit` | "**Read-only.**" | audit cluster |
| `auditor-code` | RO | `... Write, Edit` | "**Read-only.**" | audit cluster |
| `auditor-docs` | RO | `... Write, Edit` | "**Read-only.**" | audit cluster |
| `auditor-ops` | RO | `... Write, Edit` | "**Read-only.**" | audit cluster |
| `auditor-security` | RO | `... Write, Edit` | "**Read-only.**" | audit cluster |
| `auditor-tests` | RO | `... Write, Edit` | "**Read-only.**" | audit cluster |
| `auditor-ui` | RO | `... Write, Edit` | "**Read-only.**" | audit cluster |

**Project RW/RO tally: 2 RW (`coder`, `repo-ops`) + 14 RO.**

**Reconciliation (project), three independent ways:**
1. **agent-run.sh `READONLY_AGENTS` array** (lines 38-52) = exactly 14 entries:
   architect, reviewer, planner, tester, docs-researcher, grpc-schema,
   auditor, auditor-architecture, auditor-code, auditor-docs, auditor-security,
   auditor-tests, auditor-ui, auditor-ops. `coder` + `repo-ops` are absent ->
   fall through to the WRITE branch (line 414). OK
2. **PM-CHAT.md `## Permission profiles` -> Profile assignment table**
   (lines 413-430): 14 rows "Read-only" + `coder` "Write-capable (scoped)" +
   `repo-ops` "Write-capable (script)". OK
3. **BD-127.md** (Resolved 2026-05-09) line 19: "consistent with all 14
   read-only agent files." OK

All three agree: 14 RO. No contradiction. (Earlier-appearing concern that
`repo-ops` might be inside `READONLY_AGENTS` is FALSE — `repo-ops` at
agent-run.sh line 64 is inside the separate `KNOWN_AGENTS` array, not
`READONLY_AGENTS`.)

**Cross-CLI note (project):** every Gemini project agent file has **no
`tools:` field** (verified — all 16 report "(no tools field)"); Gemini relies
on default tool availability + the prose mandate + `agent-run.sh` mode flags
for RO/RW. Every Codex project agent uses `sandbox_mode = "workspace-write"`
(see §3.2) regardless of class.

---

## 2. Where agent-permission rules live today — location map

Rules grouped by the three things they encode:
(a) `agents-never-commit` / destructive-verb ban;
(b) the read-only-agent notion + RO tool-set restriction;
(c) per-agent permission/tool declarations.

### 2.1 PACK side

| # | Surface | Encodes | Quoted line / location |
|---|---|---|---|
| P1 | `CLAUDE.md` `## Pack memory` -> `### Workflow` | (a) canonical | "**Agents never commit.** No agent — including `pack-coder` — may run `git add`, `git commit`, `git push`, `git tag`, or any other state-changing git verb ... `[rationale: agents-never-commit]`" (lines 152-156) |
| P2 | `AGENTS.md` `## Pack memory` | (a) trinity mirror | same rule (trinity parity with CLAUDE.md) |
| P3 | `GEMINI.md` `## Pack memory` | (a) trinity mirror | same rule (trinity parity) |
| P4 | `CLAUDE.md` `### Sub-agent behavior (Claude-only)` | worktree-isolation **prohibition** (BD-197 P2 target) | "**Spawn all sub-agents with no worktree isolation.** Do not pass `isolation: \"worktree\"` ..." (lines 325-334) |
| P5 | `pack-ops/PACK-AGENTS.md` `## Pack agents` roster | (c) per-agent `Mode` column | lines 13-19 (the 5-agent table; `Mode` = source-write / read-only) |
| P6 | `pack-ops/PACK-AGENTS.md` `## Agent permission rules` | (a)+(b)+(c) | "Git state changes are forbidden for ALL agents..." (116-120); "Source-write scope is the per-agent `Mode`... Read-only agents (...) Write/Edit only their caller-specified report; `pack-coder` Write/Edits source within its caller-defined scope" (122-128) |
| P7 | `pack-ops/PACK-AGENTS.md` `## When agents are used vs. pack chat direct` | (a) | "Staging, committing, or pushing \| Pack chat only \| ... agents cannot run state-changing git verbs" (line 106) |
| P8 | `pack-ops/PACK-CHAT.md` | (a) (Pack-Chat side) | "**No commit without explicit approval.** Never stage, commit, or push..." (101-102) |
| P9 | `pack-ops/PACK-MEMORY-RATIONALE.md` `## agents-never-commit` | (a) rationale partner | "Read-only git verbs (`status`, `diff`, `log`, `rev-parse`, `show`) are allowed. Only Pack Chat may stage and commit..." (29-34) |
| P10 | `pack-ops/PACK-MEMORY-RATIONALE.md` `## per-action-approval-sub-agents` | (a) | "State-changing git verbs are forbidden to all agents per `PACK-AGENTS.md`..." (43-47) |
| P11 | `pack-ops/.spawn-rule-manifest.txt` | (a) rule-registry pointer | slug `agents-never-commit`, corpus `### Workflow`, references `PACK-AGENTS.md § "Agent permission rules"` (24-27); slug `preflight-stop-means-stop` (34-37) |
| P12 | `.claude/agents/pack-coder.md` | (a)+(c) | "**No git state changes, ever.** ... You MAY NOT run `git add`, `git commit`, `git push`, `git tag`, `git rebase`, `git merge`, `git reset`, `git stash`, `git checkout` (except `git checkout -- <path>`)" (33-37) — **already enumerates stash/reset** |
| P13 | `.codex/agents/pack-coder.toml`, `.gemini/agents/pack-coder.md` | (a)+(c) | per-CLI mirrors of P12 |
| P14 | `.claude/agents/pack-architect.md`, `pack-planner.md`, `pack-reviewer.md`, `pack-docs-researcher.md` (+ `.codex`/`.gemini`) | (b)+(c) | Output policy = "single permitted file write" report-only mandate per agent |
| P15 | `.claude/skills/commit-discipline/SKILL.md` (+ `.codex`, `.gemini`) | (a) verb list + worktree assumptions | forbidden verbs incl. `git add`/`reset`/`stash`/`checkout`/`rm` (68-78); **bug-era worktree `pwd`/branch assumptions** (20-62) — BD-197 P2 target |
| P16 | `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` | worktree mentions (BD-197 P2 target per BD entry) | listed in BD-197 File/Symbol P2 removal list |

### 2.2 PROJECT side (`project-template/`)

| # | Surface | Encodes | Quoted line / location |
|---|---|---|---|
| C1 | `project-template/CLAUDE.md` `## Project memory` | (a) + defer-to-agent-file | "**No destructive operations without explicit approval.** Before any `git rm`, `rm -rf`, file deletion, overwrite, `git reset --hard`, or `git checkout -- <path>` ... wait for explicit approval"; "Each agent's full operating rules (Permission profile, Output policy, Hard rules) live in its own definition file" |
| C2 | `project-template/AGENTS.md` `## Project memory` | (a) trinity mirror | same (trinity parity) |
| C3 | `project-template/GEMINI.md` `## Project memory` | (a) trinity mirror | same; plus GEMINI.md line 471: "**Approval mode:** Read-only and review agents use Gemini default mode (per-command approval) ... Plan Mode blocks all command execution and must not be used as the standard mode for read-only agents." |
| C4 | `project-template/docs/pack/PM-CHAT.md` `## Permission profiles` | (b)+(c) **canonical project RW/RO table** | Profile-assignment table (413-430): 14 Read-only + coder + repo-ops; "**The agent file is authoritative; this section is the PM-chat-facing reinforcement.**" (406-409) |
| C5 | PM-CHAT.md `### Read-only profile — prompt requirements` | (b) enforcement-via-prompt | "`agent-run.sh` flag profile (Claude Code): `--permission-mode bypassPermissions --disallowedTools 'Bash(git add:*)' 'Bash(git mv:*)' 'Bash(git commit:*)' 'Bash(git push:*)'`" (455-459) |
| C6 | `project-template/agent-run.sh` | (b)+(c) **runtime RW/RO dispatch** | `READONLY_AGENTS` array (38-52, 14 entries); `CLAUDE_READONLY_FLAGS` / `CODEX_READONLY_FLAGS` / `GEMINI_READONLY_FLAGS` / `GEMINI_WRITE_FLAGS` (96-129); dispatch at 405-414 |
| C7 | `project-template/.claude/agents/*.md` (16) | (b)+(c) per-agent mandate | "**Read-only.**" / "**Write-capable (scoped).**" headers; "**No state-changing git operations, ever.**" Hard-rule (e.g., coder line 72, reviewer line 48) |
| C8 | `project-template/.codex/agents/*.toml` (16) | (b)+(c) | `## Permission profile` prose + `sandbox_mode`; git-ban Hard rule already lists `git reset`/`git stash` (e.g., coder.toml line 47, architect.toml line 38) |
| C9 | `project-template/.gemini/agents/*.md` (16) | (b)+(c) | prose mandate (no `tools:` field; mode comes from agent-run.sh) |
| C10 | `project-template/skills/repo-ops/SKILL.md` | (a)/(c) for repo-ops | repo-ops scripted-edit discipline |
| C11 | `project-template/CLAUDE.md` deny-list block | boundary (pack-only refs) | `<!-- DENY-LIST-CONTENT-START -->` ... (not RW/RO per se, but governs what agent files may reference) |

**Duplication / scatter observations:**
- `agents-never-commit` is stated in **>=10 pack-side places** (trinity x3,
  PACK-AGENTS x3 sub-sections, PACK-CHAT, RATIONALE x2, spawn-manifest,
  pack-coder x3, commit-discipline x3) and **>=6 project-side places** (trinity
  x3, PM-CHAT, agent-run.sh, 48 agent files' Hard rules). Heavy redundancy by
  design (the trinity/propagation model intentionally restates), but it means a
  verb-list change (BD-197 folded scope adds `git stash`) must touch **many**
  surfaces in lockstep.
- The **RW/RO classification list itself** lives in 4 forms project-side
  (PM-CHAT table, agent-run.sh array, per-file prose header, BD-127 prose) and
  3 forms pack-side (PACK-AGENTS roster `Mode`, per-file prose, no runtime
  array). No single cross-surface SSOT.

---

## 3. As-built RO-enforcement mechanics (how RW vs RO is enforced today)

### 3.1 Claude Code
- **Pack side:** RO agents `pack-architect`/`pack-planner`/`pack-docs-researcher`
  omit `Write, Edit` from `tools:` (hard tool-gating). BUT `pack-reviewer`
  *includes* `Write, Edit` and is RO only by prose. `pack-coder` (RW) includes
  `Write, Edit`. So tool-gating is **inconsistent** as an RO signal.
- **Project side:** EVERY agent (RO and RW alike) carries `Write, Edit`
  (+ `MultiEdit` for coder/repo-ops) in `tools:`. RO is NOT tool-gated at the
  agent-definition level; it is enforced at **launch** by `agent-run.sh`:
  `CLAUDE_READONLY_FLAGS = --permission-mode bypassPermissions
  --disallowedTools Bash(git commit:*) Bash(git push:*)` (lines 96-99). Write
  is allowed for the report; the prompt constrains Write to the report path
  (PM-CHAT C5). Comment at line 92-94: "Edit/Write tools are excluded at the
  agent-definition level" — **this comment is now stale** for the project side,
  since the agent files DO list Write/Edit (BD-127 deliberately kept Write for
  the report). Flag for the architect.

### 3.2 Codex CLI
- **All** Codex agents (RO and RW) set `sandbox_mode = "workspace-write"`.
  RO agents need workspace-write to emit their one report; `.git` is protected
  read-only by the sandbox so `git commit`/`push` fail at OS level
  (agent-run.sh lines 102-107). The RW/RO distinction is **prose-only** in the
  TOML `## Permission profile` block ("**Read-only.**" vs "**Write-capable
  (scoped).**"). So Codex `sandbox_mode` does **not** mechanically distinguish
  RW from RO. RO launch flag: `-a never` (agent-run.sh line 112).
- Codex git-ban Hard rule **already enumerates** the full destructive set incl.
  `git reset`, `git stash`, `git checkout` (coder.toml line 47; architect.toml
  line 38; reviewer.toml line 30).

### 3.3 Gemini CLI
- Project Gemini agents carry **no `tools:` field**. RO enforced at launch by
  **mode**: RO agents use **default mode** (per-command approval) —
  `GEMINI_READONLY_FLAGS=()` (empty, line 122). Plan Mode
  (`--approval-mode=plan`) is explicitly REJECTED for RO agents because it
  blocks build/test execution (xcodebuild, swift test) — GEMINI.md line 471 +
  agent-run.sh lines 115-122. RW agents use `--approval-mode=yolo`
  (`GEMINI_WRITE_FLAGS`, lines 127-129).
- (The original prompt cited "GEMINI.md:523" — the actual line is **471** at
  this HEAD; line numbers drifted.)

### 3.4 Bug-era worktree content still present (BD-197 P2 target, confirmed)
- `.claude/.codex/.gemini/skills/commit-discipline/SKILL.md` assumes the
  Agent-tool **isolated worktree** model: `pwd` "Must end in worktree path,
  not main checkout" (line 20); `git rev-parse --abbrev-ref HEAD` "Must start
  with `worktree-agent-`" (line 22); "final deliverables go under the worktree
  only" (line 62). This is the exact bug-era assumption BD-197 P2 removes/redesigns.
- `CLAUDE.md` `### Sub-agent behavior (Claude-only)` worktree-prohibition
  bullet (P4 above) is the prohibition BD-197 P2 removes.

---

## 4. Gap analysis + placement options

### 4.1 Is there a centralized RW/RO list today?
**No single cross-surface SSOT.** Findings:
- **Pack side:** the closest thing is the `pack-ops/PACK-AGENTS.md` roster
  `Mode` column (5 rows). There is **no runtime dispatch list** (pack agents
  are spawned via the Agent tool / `claude --agent`, not via an `agent-run.sh`
  equivalent — confirmed: CLAUDE.md line 233 "The pack repo has no
  `agent-run.sh`"). So pack-side RW/RO lives in (i) PACK-AGENTS roster `Mode`
  and (ii) each agent file's prose. Two places, hand-synchronized.
- **Project side:** RW/RO lives in **four** places that must agree —
  PM-CHAT.md profile table (C4), agent-run.sh `READONLY_AGENTS` array (C6),
  per-agent prose header (C7/C8/C9), and historically BD-127 prose. They
  agree today (§1.2) but nothing CI-enforces set-equality between the
  PM-CHAT table and the agent-run.sh array (architect should verify whether a
  validate-pack check covers this; not found in this inventory's scope).
- **Cross-surface:** pack and project are deliberately **separate artifact
  sets** (separation-of-concerns rule). A "two-class agent model" for BD-197
  must be declared **twice** (once per surface) — there is no shared file, and
  per the separation rule there should not be one.

### 4.2 Candidate homes for a coherent RW/RO + permission SSOT (options, NOT a decision)

**Pack side:**
- **Option PA — Extend PACK-AGENTS.md roster `Mode` into an explicit
  RW/RO class column** + a short "Two agent classes" subsection under
  `## Agent permission rules`. *Pro:* already the routing SSOT; agents already
  read it. *Con:* not the tool-native context file; relies on agents loading it.
- **Option PB — Declare the class in each pack agent file's frontmatter**
  (e.g., a `# class: read-write|read-only` comment or a standard mandate
  header), with PACK-AGENTS.md as the index. *Pro:* the agent file is the
  thing the runtime actually loads; matches "agent file is authoritative."
  *Con:* 15 files to keep in lockstep (x3 CLIs); needs a parity check.
- **Option PC — Add the class to trinity `## Pack memory`** (a named rule
  like "two-class agent model"). *Pro:* highest-authority surface, propagation
  procedure already exists. *Con:* trinity should carry universal rules, not
  per-agent rosters; risks duplicating the PACK-AGENTS roster.

**Project side:**
- **Option CA — Make PM-CHAT.md `## Permission profiles` the single
  human-readable SSOT and have agent-run.sh `READONLY_AGENTS` be a
  CI-checked projection of it** (set-equality validator). *Pro:* removes the
  silent-drift risk between the table and the array; one authored list.
  *Con:* needs a new validate-pack check (architect: measure-then-bound).
- **Option CB — Per-agent-file frontmatter class field as SSOT**, with both
  PM-CHAT table and agent-run.sh array generated/validated from the files.
  *Pro:* "agent file is authoritative" is already the stated model (PM-CHAT
  406-409). *Con:* Gemini files have no `tools:`/frontmatter today; adding a
  field is a cross-CLI change.
- **Option CC — Keep the current multi-surface model, add a single CI
  set-equality guard** binding {agent-file mandate header} <-> {PM-CHAT table}
  <-> {agent-run.sh array}. *Pro:* minimal disruption. *Con:* doesn't reduce
  scatter, only detects drift.

**Cross-cutting (the `agents-never-commit` verb list):**
- The destructive-verb enumeration is the most-duplicated string. BD-197
  folded scope adds `git stash` (+ reset/restore/checkout class) across
  trinity x3 + PACK-AGENTS + commit-discipline x3 + rationale. **Partial
  state today:** pack-coder, project coder/architect/reviewer (Codex), and the
  commit-discipline skill **already** list `git stash`/`git reset`; the
  trinity `## Pack memory` `agents-never-commit` bullet (CLAUDE.md 152-156)
  does **not** enumerate stash/reset (it says "or any other state-changing git
  verb"). Architect must decide: enumerate explicitly everywhere vs. rely on
  the catch-all. This is a measure-then-bound + propagation-procedure task.

### 4.3 Open questions for the BD-197 architect
1. Should the RW/RO class be a **machine-readable field** (frontmatter / TOML
   key) or remain **prose** (mandate header)? Today it is prose + (project)
   a runtime array.
2. Stale comment: `agent-run.sh` lines 92-94 claim "Edit/Write tools are
   excluded at the agent-definition level" — false for the project side
   (BD-127 kept Write for reports). Reconcile during P3.
3. Is there (or should there be) a CI guard enforcing set-equality between
   PM-CHAT.md table <-> agent-run.sh `READONLY_AGENTS` <-> agent-file headers?
   Not found in this inventory.
4. The "merge-back for RW agents" (BD-197 P3) currently has **zero** as-built
   mechanism — there is no Pack-Chat-mediated patch-capture surface today; the
   commit-discipline skill assumes the (buggy) auto-worktree model instead.
5. `repo-ops` is RW-by-script ("**No hand-written source edits**", generated
   files only) — a third nuance the two-class model must place: is it RW or a
   distinct "scripted-write" class? PM-CHAT.md uses two labels ("Write-capable
   (scoped)" for coder, "Write-capable (script)" for repo-ops).

---

## 5. Counts reconciled (summary)

| Surface | Agents/CLI | RW | RO | Reconciliation |
|---|---|---|---|---|
| Pack | 5 (x3 = 15 files) | 1 (`pack-coder`) | 4 | PACK-AGENTS roster `Mode` (5 rows) = file count = prose headers |
| Project | 16 (x3 = 48 files) | 2 (`coder`, `repo-ops`) | 14 | agent-run.sh `READONLY_AGENTS` (14) = PM-CHAT table (14 RO + 2 RW) = BD-127 "14 read-only" = file count (16) |

---

## Rules-Applied Verification Block

| Rule (from prompt "Rules in force") | Verification evidence | Conclusion |
|---|---|---|
| 1. Agents never commit (git read-only only) | This session ran only read-only verbs: `git rev-parse HEAD` (returned `3e3159e...`), `ls`, `grep`, `awk`, `sed`, `cat`, `find`. No `git add/commit/push/tag/stash/reset/mv/rm` issued. | COMPLIANT |
| 2. Read-only mandate (write ONLY the one report) | Exactly one report file written, to `maintenance-docs/v11-implementation/RESEARCH-BD-197-AGENT-PERMISSION-INVENTORY.md` (the caller-specified path), via Bash heredoc (the Write tool was disabled in this context). No source/config/agent files edited. | COMPLIANT |
| 3. Inventory + categorize, don't design | Every agent classified with quoted evidence (§1); §4 PROPOSES placement options PA-PC / CA-CC with trade-offs and lists open questions; no final design picked. | COMPLIANT |
| 4. Exhaustive + reconciled | Both surfaces fully enumerated (5 pack + 16 project, x3 CLIs); permission-doc map has 16 pack + 11 project entries (§2); counts reconciled >=3 ways project-side, >=2 ways pack-side (§1.2, §5). | COMPLIANT |
| 5. Empirical-Evidence blocks | Each classification/location claim carries the command or file:line + verbatim quote; HEAD `3e3159e` and date 2026-06-13 recorded in header and applied throughout. | COMPLIANT |
| 6. Pack/project separation respected | §1.1 vs §1.2 and §2.1 vs §2.2 kept as separate artifact sets; cross-surface coupling explicitly noted as "must be declared twice; no shared file" (§4.1). | COMPLIANT |
| 7. Rules-Applied Verification Block present | This block. | COMPLIANT |
| 8. PREFLIGHT + STOP-MEANS-STOP | PREFLIGHT line emitted in chat before this write: "PREFLIGHT: inventory complete; about to Write ...". No parent stop received. | COMPLIANT |
