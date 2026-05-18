# ARCHITECTURE-CLEANUP-BATCH-19C — Project-side consolidation pass for v11.0 ship-readiness (first-pass architect doc)

**Author:** pack-architect (first pass)
**Date:** 2026-05-17
**Branch:** v11-dev (HEAD `3d8cc8b` — post-Batch-19b-close)
**Ship target:** v11.0 (unlaunched)
**Scope:** `project-template/` only — pack-side files are out of scope (covered by Batch 19b)
**Status:** First-pass architect doc; needs user review at the architect-review gate (D-1..D-N in §F), then a research pass (§G) before V2 / addendum / planner spawn.

---

## 1. Summary

This is the project-side analog to Batch 19b. Where Batch 19b consolidated the
pack-repo trinity + `PACK-CHAT.md` + `PACK-AGENTS.md` + memory cache from
empirical pack-development learnings, Batch 19c consolidates the
**`project-template/`** surface for v11.0 ship-readiness from empirical
OT-project learnings supplied by the user in
`/Users/david/Developer/__external-docs/optiquity-ai-agent-config-pack/OT Project Untracked and Tracked Memories.txt`.

The content scope is completely different from Batch 19b. Pack-side rules
govern how Pack Chat + pack-coder/architect/reviewer agents operate on the
pack repo. Project-side rules govern how a **client project team** (developer
+ PM chat + project-side agents) operates on a client repo using the pack as
installed product. Different audience, different agent set, different memory
mechanics, different file surface.

**Trinity-first design (parity with Batch 19b §A.1).** Per Batch 19b research,
trinity files are the only universal cross-CLI rule surface; Codex and Gemini
have no per-project memory cache; Claude's `~/.claude/projects/<slug>/memory/`
is opt-in and per-machine. The same constraint applies to client projects:
project-side rules MUST land in the project trinity
(`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` at the project root) to be visible
to all three CLIs in a client project. Client-machine memory caches are
out-of-band conveniences only; they are not the propagation mechanism.

**Where rules land — three surfaces (in order of precedence):**

1. **Project trinity** (`project-template/CLAUDE.md` /
   `project-template/AGENTS.md` / `project-template/GEMINI.md`) `## Project memory`
   — universal collaboration rules visible to all three CLIs on every prompt.
   This is the analog of pack-repo trinity `## Pack memory`. Currently only
   3 bullets (Trinity rule / No destructive ops / PM chat does not architect).
   Batch 19c is expected to grow this from 3 to ~10-12 bullets.

2. **PM-CHAT.md** (`project-template/docs/pack/PM-CHAT.md` `## Behavioral rules`)
   — PM-chat-specific operating rules. The analog of pack-repo `PACK-CHAT.md`
   `## Behavioral rules`. Currently ~15 bullets; expected to grow by 4-6 new
   bullets.

3. **Agent definition files** (`project-template/.claude/agents/*.md`,
   `.codex/agents/*.toml`, `.gemini/agents/*.md`) `## Hard rules` — agent-specific
   behavior rules. For OT rules that are agent-scoped (e.g., coder must verify
   before claiming done), the rule may already exist; verify and strengthen
   in place. New cross-agent rules belong in trinity, not in every agent file.

**OT input counts (10 OT items dispositioned):**

| Category | Count |
|---|---|
| PROMOTE (universal → trinity `## Project memory`) | 4 |
| PROMOTE (universal → PM-CHAT.md `## Behavioral rules`) | 3 |
| STRENGTHEN existing project-template content | 1 |
| OUT OF SCOPE — OT-specific (belongs in OT project files) | 1 |
| OUT OF SCOPE — pack-side (already covered by Batch 19b) | 1 |

Sum = 10. (Item-by-item disposition in §B.)

**Critical decisions / call-outs:**

- **D-1 (memory cache architecture for project side) — RECOMMEND: none.**
  Trinity-first single-tier-of-truth. No project-side `~/.claude/projects/<slug>/memory/`
  template is shipped. (Detail in §D.)
- **D-2 (where to land "PM chat does NOT modify source files" rule) — RECOMMEND:
  STRENGTHEN existing project trinity bullet "PM chat does not architect" to
  add a "PM chat does not modify code" clause.** Currently the trinity bullet
  is about architecture-vs-execution scope; the OT learning extends it to
  source-file-edit prohibition. Detail in §B (OT-7 row).
- **D-3 (reviewer-after-coder mandatory rule — where to land) — RECOMMEND:
  NEW trinity `## Project memory` bullet** and a parallel PM-CHAT.md
  `## Behavioral rules` bullet (one rule, two surfaces because the rule
  applies to both PM-chat-prompt-construction AND agent-behavior). Detail
  in §B (OT-1 row).
- **D-4 (closeout-approval-required rule) — RECOMMEND: NEW PM-CHAT.md
  `## Behavioral rules` bullet.** Already covered partially by existing PM-CHAT.md
  bullet "No commit without explicit approval"; the OT learning specifies the
  ORDER: propose content first, then approval, then write. Detail in §B (OT-3).
- **D-5 (architect-trigger-check rule) — RECOMMEND: NEW PM-CHAT.md
  `## Behavioral rules` bullet** OR extend existing METHODOLOGY.md Workflow 4
  cross-reference (research need: see §G.1). Detail in §B (OT-2 row).
- **D-6 (re-read-agent-prompt-file rule) — RECOMMEND: NEW PM-CHAT.md
  `## Behavioral rules` bullet** with cross-reference to per-agent files in
  `docs/pack/prompts/`. Detail in §B (OT-6 row).
- **D-7 (BACKLOG-check-between-phases rule) — RECOMMEND: NEW PM-CHAT.md
  `## Behavioral rules` bullet** (PM-chat operational rule, not a universal
  collaboration rule). Detail in §B (OT-4 row).
- **D-8 (commit-sequencing rough draft) — 4 commits**: (1) project trinity
  edits, (2) PM-CHAT.md edits, (3) any per-agent file strengthening, (4)
  archive workflow artifacts. Detail in §H.

---

## 2. Reference docs

- **OT memory file (primary input):**
  `/Users/david/Developer/__external-docs/optiquity-ai-agent-config-pack/OT Project Untracked and Tracked Memories.txt`
  (~13KB, 10 numbered rules across two sections: 10 untracked + 7 tracked, with overlap).
- **BD-173 entry:** `BACKLOG.md` lines 1418-1452.
- **Batch 19b precedent (shape/style only, NOT content):**
  - `maintenance-docs/archive/v11/ARCHITECTURE-CLEANUP-BATCH-19B-V2.md`
  - `maintenance-docs/archive/v11/PLAN-CLEANUP-BATCH-19B.md`
- **Project-template trinity (current baseline):**
  - `project-template/CLAUDE.md` (426 lines; `## Project memory` at line 343)
  - `project-template/AGENTS.md` (402 lines; `## Project memory` at line 320)
  - `project-template/GEMINI.md` (449 lines; `## Project memory` at line 338)
- **Project-template PM-CHAT.md:**
  - `project-template/docs/pack/PM-CHAT.md` (786 lines; `## Behavioral rules` at line 176)
- **Project-template agent definitions:**
  - 16 Claude agents at `project-template/.claude/agents/*.md`
  - 16 Codex agents at `project-template/.codex/agents/*.toml`
  - 16 Gemini agents at `project-template/.gemini/agents/*.md`
- **Project-template prompt templates:**
  - 10 per-agent prompt files at `project-template/docs/pack/prompts/*.md`

---

## §A — OT memory file inventory and categorization

The OT memory file contains TWO sections:

- **Section 1 (Untracked memories):** 10 numbered rules the OT PM chat
  surfaced as "stated rules not captured in memory or workflow docs."
  Mix of session-scoped, project-scoped, and universal rules.
- **Section 2 (Tracked memories):** 7 memory files
  (`feedback_*.md`) currently in the OT `~/.claude/projects/<slug>/memory/`
  cache. These are persistent project-side learnings.

The OT items are de-duplicated and consolidated into 10 canonical items below.
(Items 1, 9 from Section 1 overlap with Section 2 entries; items 2-3, 6-8
from Section 1 are unique session/project-scoped rules; Section 2 entries
not surfaced in Section 1 are listed separately.)

### A.1 — Item inventory

| OT-ID | Source location | Title | Section | Category (preview) |
|---|---|---|---|---|
| OT-1 | Section 2 `feedback_always_reviewer_after_coder.md` | ALWAYS run reviewer after every coder report | Tracked | PROMOTE-UNIVERSAL (trinity + PM-CHAT.md) |
| OT-2 | Section 2 `feedback_architect_trigger_check.md` | Architect trigger check after every reviewer report | Tracked | PROMOTE-UNIVERSAL (PM-CHAT.md) |
| OT-3 | Section 2 `feedback_closeout_approval_required.md` | Closeout approval required before writing docs | Tracked | PROMOTE-UNIVERSAL (PM-CHAT.md) |
| OT-4 | Section 2 `feedback_backlog_check_between_phases.md` | Check BACKLOG between phases for unblocked items | Tracked | PROMOTE-UNIVERSAL (PM-CHAT.md) |
| OT-5 | Section 2 `feedback_never_commit_without_approval.md` | Never commit without explicit user approval | Tracked | ALREADY-COVERED (verify wording) |
| OT-6 | Section 2 `feedback_template_read_fully.md` + Section 1 item 9 | Always re-read the agent prompt file before generating any agent prompt | Tracked + Untracked | PROMOTE-UNIVERSAL (PM-CHAT.md) |
| OT-7 | Section 2 `feedback_never_modify_code.md` | PM chat must NEVER modify Swift source files (generalize: source files) | Tracked | PROMOTE-UNIVERSAL (trinity, STRENGTHEN existing bullet) |
| OT-8 | Section 1 item 2 + item 3 | Pack repo is read-only from project working tree; leave working tree modified when told | Untracked | OUT-OF-SCOPE — OT-session-specific (sidecar v11-prep behavior) |
| OT-9 | Section 1 items 4 + 5 + 7 | v11 conversion-specific rules (TD scope, Phase 58b deferral, post-v11 prioritization) | Untracked | OUT-OF-SCOPE — OT-project-specific (belongs in OT project files, not project-template/) |
| OT-10 | Section 1 items 6 + 8 + 10 | User reads architect docs before next steps; tmp reports are ephemeral; cadence/concurrency are open questions | Untracked | STRENGTHEN existing project-template content OR DEFER (research need: see §G.2) |

**Item 1 from Section 1** ("Agent team lifecycle (CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1)")
is OUT OF SCOPE for project-template — it is pack-development behavior already
covered by Batch 19b trinity `### Sub-agent behavior (Claude-only)`. The OT
PM chat references it because OT uses Agent Teams in pack-development sessions
hosted from the OT project directory; in client projects without
pack-development context, this is not a project-team rule. Cross-reference:
`maintenance-docs/archive/v11/ARCHITECTURE-CLEANUP-BATCH-19B-V2.md` §I.1
"### Sub-agent behavior (Claude-only)".

### A.2 — Categorization summary

- **Universal project-side rules (4):** OT-1, OT-2, OT-3, OT-4, OT-6 (5 actually
  — recount: 5 universal rules. OT-7 is universal + STRENGTHEN-existing, counted
  separately).
  - Note: re-counting against §A.1 table, the precise breakdown:
    - 4 PROMOTE-UNIVERSAL-NEW (OT-1, OT-2, OT-3, OT-4, OT-6) → 5 NEW promotions
    - 1 STRENGTHEN-EXISTING (OT-7) → expands existing trinity bullet
    - 1 ALREADY-COVERED (OT-5) → no edit
    - 2 OUT-OF-SCOPE (OT-8, OT-9)
    - 1 STRENGTHEN-OR-DEFER pending research (OT-10)
  - Sum: 5 + 1 + 1 + 2 + 1 = 10. Matches.

  Correction: §1 summary table counts above the precise breakdown:
  PROMOTE-trinity = 4 (OT-1 also goes to trinity per D-3; OT-7 goes to
  trinity via STRENGTHEN); PROMOTE-PM-CHAT.md = 4 (OT-1 also; OT-2, OT-3,
  OT-4, OT-6); STRENGTHEN-EXISTING = 1 (OT-7); OUT-OF-SCOPE = 3 (OT-8, OT-9,
  pack-side item 1 from Section 1 - now broken out as a separate OT-11);
  ALREADY-COVERED-VERIFY = 1 (OT-5); DEFER-PENDING-RESEARCH = 1 (OT-10).

  Re-stated cleanly in §B per-item disposition table.

- **OT-specific rules (1):** OT-9 — belongs in OT project's own files (e.g.,
  the OT project's CLAUDE.md or its own STATUS.md / BACKLOG.md), not in
  `project-template/`.

- **Pack-side rules (1):** OT-11 (broken out from Section 1 item 1) —
  pack-development context, covered by Batch 19b. Flagged for awareness
  only; no Batch 19c action.

- **Session-scoped (1):** OT-8 — sidecar / pre-pack-install behavior;
  not a standing rule for client projects.


---

## §B — Per-item disposition table with target placement + transformation type

This is the planner-ready triage table. Categories:

- **PROMOTE-TRINITY** — add to `project-template/{CLAUDE,AGENTS,GEMINI}.md`
  `## Project memory` as a new bullet.
- **PROMOTE-PM-CHAT** — add to `project-template/docs/pack/PM-CHAT.md`
  `## Behavioral rules` as a new bullet.
- **PROMOTE-BOTH** — add to both trinity and PM-CHAT.md (one rule, two surfaces).
- **STRENGTHEN** — modify wording of an existing project-template file content.
- **ALREADY-COVERED** — content already present; verify wording matches OT
  empirical learning and no edit needed.
- **DEFER** — research need or out-of-scope; named in §G or §E.
- **OUT-OF-SCOPE** — not appropriate for `project-template/` (OT-specific or
  pack-side).

### OT-1 — ALWAYS run reviewer after every coder report (PROMOTE-BOTH)

**OT source text (verbatim from Section 2 tracked entry):**

> After every coder report — without exception — the next action is generating
> a reviewer prompt. Never propose "approve to commit" directly after a coder
> report. ... The sequence is coder → reviewer → user approval → commit. Always.
> Bypass: This rule can only be bypassed on a conditional basis when the user
> specifically requests it. The PM chat is never to request or suggest skipping
> the reviewer pass.

**Rationale for PROMOTE-BOTH:** This is the project-side analog of pack-repo
trinity `### Workflow` "Per-BD review/fix runs INLINE" (Batch 19b L3) but it
has additional weight: the OT learning explicitly enumerates the trigger
conditions under which the rule is most likely to be violated ("It's just a
comment fix", "The tests pass", etc.). For a universal collaboration rule
visible to all CLIs, trinity is the right home. For PM-chat-specific
prompt-construction behavior ("never propose approve-to-commit after a coder
report"), PM-CHAT.md is the right home. The rule has both halves; both
surfaces get a bullet.

**Trinity bullet text (target: `## Project memory` in CLAUDE.md / AGENTS.md /
GEMINI.md, INSERT after the existing "PM chat does not architect" bullet):**

```
- **Reviewer follows every coder run.** After every coder agent report,
  the next action is to spawn a reviewer agent — no exceptions. PM chat
  must NOT propose "approve to commit" directly after a coder report,
  must NOT say "small enough to skip review," and must NOT cite a prior
  reviewer pass on a different change as authorization to skip review
  for this change. The sequence is coder → reviewer → user approval →
  commit. The user may bypass this rule by explicit request; PM chat
  must never propose or suggest skipping the reviewer pass.
```

**PM-CHAT.md bullet text (target: `## Behavioral rules`, INSERT after the
existing "Fix cycle rules" bullet at line ~201):**

```
- **Reviewer follows every coder run.** After every coder agent report,
  generate a reviewer prompt before any other action. Do not propose
  "approve to commit" after a coder report. Do not suggest skipping
  review for any reason — "comment fix," "tests pass," "trivial,"
  "obvious," "prior pass already approved" are exactly the conditions
  under which review is most needed. Only the user, unprompted, may
  bypass the reviewer. See trinity `## Project memory` "Reviewer
  follows every coder run" for the universal rule.
```

### OT-2 — Architect trigger check after every reviewer report (PROMOTE-PM-CHAT)

**OT source text:**

> After every reviewer agent report, check the architect trigger conditions
> (Methodology Workflow 4 step 3) before generating any fix plan or declaring
> ready to commit.
> Trigger A — Repeated coder runs without resolution: Coder has run 3 or more
> times since phase started (or since last architect pass) AND reviewer still
> identifies ❌ or ⚠️ issues.
> Trigger B — Regression or issue count increase: Any previously ✅ item is
> now ❌ or ⚠️, OR new issue count this pass is greater than the previous pass.

**Rationale for PROMOTE-PM-CHAT (not trinity):** This is PM-chat-specific
orchestration behavior — the trigger check is a PM chat decision point
between reviewer report and fix plan. Project-side agents (coder, reviewer,
architect) don't run this check themselves; PM chat does. Trinity is for
universal-to-all-CLIs rules; this is a PM-chat-workflow rule and belongs in
PM-CHAT.md.

**Research need (see §G.1):** The OT text cites "Methodology Workflow 4 step
3" — verify whether `supporting-docs/METHODOLOGY.md` (which becomes
`project-template/docs/pack/METHODOLOGY.md` after pack install — note: this
file appears in the PM-CHAT.md RAG manifest but is NOT in
`project-template/docs/pack/` — it ships from `supporting-docs/`) Workflow 4
already names these trigger conditions. If yes, PM-CHAT.md gets a
cross-reference. If no, the trigger conditions need to be either added to
METHODOLOGY.md or inlined in PM-CHAT.md.

**PM-CHAT.md bullet text (target: `## Behavioral rules`, INSERT after the new
OT-1 PM-CHAT.md bullet above):**

```
- **Architect trigger check after every reviewer report.** Before
  generating any fix plan or declaring ready-to-commit, check Workflow
  4's architect trigger conditions:
  - Trigger A — Repeated coder runs without resolution: coder has run
    3 or more times since phase started (or since last architect pass)
    AND reviewer still identifies blocker / must-fix issues.
  - Trigger B — Regression or issue-count increase: any previously
    passing item is now failing, OR new issue count this pass exceeds
    the previous pass.
  Either condition may signal an architectural root cause that coder-
  level fixes cannot address. Even when the trigger is technically met
  but the remaining issue appears mechanical, surface the trigger check
  explicitly to the user — state your assessment and get approval before
  proceeding with or waiving the architect pass. Never silently skip
  the check. See `METHODOLOGY.md` Workflow 4 step 3 for the underlying
  workflow.
```

### OT-3 — Closeout approval required before writing docs (PROMOTE-PM-CHAT)

**OT source text:**

> Never write BACKLOG.md, CHANGELOG.md, or STATUS.md without first presenting
> the proposed content to the user and receiving explicit approval. ...
> After every READY TO COMMIT verdict, the sequence is:
> 1. Check architect triggers (already a saved memory)
> 2. Present proposed BACKLOG entry, CHANGELOG entry, and STATUS changes as text
> 3. Wait for explicit user approval ("approved", "looks good", etc.)
> 4. Only then write the files
> 5. Show the commit message and wait for approval before committing

**Rationale for PROMOTE-PM-CHAT:** This is PM-chat orchestration sequencing.
Already partially covered by existing PM-CHAT.md bullet "Source file edits"
("You may write to BACKLOG.md, STATUS.md ... but only after explicit user
approval"), but that bullet does not specify the SEQUENCE
(propose-content-first → approval → write). OT learning is the explicit
ordering rule.

**PM-CHAT.md bullet text (target: `## Behavioral rules`, INSERT after the
new OT-2 bullet above):**

```
- **Closeout approval sequence.** After any READY TO COMMIT verdict,
  follow this sequence exactly:
  1. Check architect triggers (see "Architect trigger check" bullet).
  2. Present proposed BACKLOG entry, CHANGELOG entry, and STATUS
     changes as text (in chat, not as file writes).
  3. Wait for explicit user approval ("approved," "looks good," or
     equivalent affirmative).
  4. Only then write the files.
  5. Present the commit message and wait for separate approval before
     running git add / commit.
  Do not chain steps 2 and 4 — never write files in the same turn as
  proposing their content. Existing rule "Source file edits" governs
  what PM chat may write; this rule governs WHEN.
```

### OT-4 — Check BACKLOG between phases for unblocked items (PROMOTE-PM-CHAT)

**OT source text:**

> At every phase gate (after a phase completes, before starting the next),
> check BACKLOG.md for items whose blockers were resolved by the completed
> phase. Any newly unblocked item should be assessed: fix now if tightly
> scoped, or schedule into an upcoming phase if larger.

**Rationale for PROMOTE-PM-CHAT:** Phase-gate workflow is PM-chat orchestration,
not universal collaboration. Belongs in PM-CHAT.md.

**Research need (see §G.1):** Verify whether METHODOLOGY.md Part 7 Procedure 1
(TD lifecycle) already names this check or whether it's implicit. If implicit,
PM-CHAT.md gets the explicit rule; if METHODOLOGY.md already covers it,
PM-CHAT.md gets a cross-reference only.

**PM-CHAT.md bullet text (target: `## Behavioral rules`, INSERT after the
new OT-3 bullet above):**

```
- **BACKLOG check at every phase gate.** After every phase closeout
  (STATUS.md updated, CHANGELOG written), before generating the next
  phase's first prompt, scan BACKLOG entries for items whose blockers
  were resolved by the completed phase. For each newly unblocked item,
  report it to the user: "TD-NNN is now unblocked by Phase N
  completion." Let the user decide whether to fix it now (small, tightly
  scoped) or schedule it into an upcoming phase. This check is the PM
  chat's responsibility — the user should not have to remind you. See
  `METHODOLOGY.md` Part 7 Procedure 1 step 3 for the TD lifecycle
  context.
```

### OT-5 — Never commit without explicit user approval (ALREADY-COVERED — verify wording)

**OT source text:**

> Never run `git add`, `git commit`, or `git push` without the user's explicit
> approval. ... The words "approve to commit" or similar must appear AND the
> user must respond affirmatively before any git operation. This applies even
> to small/obvious changes like config files, scripts, or one-line fixes.

**Rationale for ALREADY-COVERED:** Existing PM-CHAT.md `## Behavioral rules`
contains "No commit without explicit approval" as the second bullet (line ~180
range). Verify current wording carries the "even small/obvious changes" clause.

**Verification step for pack-coder:** Read PM-CHAT.md `## Behavioral rules`
bullet "No commit without explicit approval"; verify wording carries the
"even small/obvious changes like config files, scripts, or one-line fixes"
clause. If missing, file as STRENGTHEN — extend with the explicit "small
changes are not an exception" wording.

### OT-6 — Always re-read the agent prompt file before generating any agent prompt (PROMOTE-PM-CHAT)

**OT source text:**

> Before generating any agent prompt (coder, reviewer, architect, planner,
> tester, auditor, docs-researcher, repo-ops, grpc-schema, or any other),
> re-read the full per-agent prompt file for that agent from
> `docs/pack/prompts/<agent>.md`. Do this every single time without exception,
> even if the file seems familiar or was recently read. ... Verify the
> generated prompt includes the report header line instruction before handing
> it to the user.

**Rationale for PROMOTE-PM-CHAT:** PM-chat prompt-construction discipline.
Already partially covered by existing PM-CHAT.md bullet "Follow Prompt
Authoring Principles" but that bullet cites METHODOLOGY.md's principles
section — not the explicit re-read-the-file behavior. OT learning is the
explicit "every time, no exception" rule.

**PM-CHAT.md bullet text (target: `## Behavioral rules`, INSERT after the
new OT-4 bullet above):**

```
- **Re-read the agent prompt file every time.** Before generating any
  agent prompt (architect, planner, coder, reviewer, tester, auditor,
  docs-researcher, grpc-schema, repo-ops, or any custom `x-*` agent),
  re-read the full per-agent prompt file at `docs/pack/prompts/<agent>.md`.
  Do this every time without exception — "I remember the format" is
  not a substitute for reading the file. Verify the generated prompt
  includes the `REPORT FILE:` line and any other per-agent required
  headers before sending it to the developer. See "Follow Prompt
  Authoring Principles" bullet for the underlying principles; this
  rule is the operational re-read discipline.
```

### OT-7 — PM chat must NEVER modify source files (PROMOTE-TRINITY via STRENGTHEN existing bullet)

**OT source text:**

> The PM chat must NEVER directly edit any .swift file — not code, not
> comments within code files, not variable names, nothing. All modifications
> to source files are exclusively the coder agent's responsibility. ...
> The PM chat's file-editing scope is: docs/ files, scripts/, .claude/
> settings, and memory. Nothing in OptiquityTrader/ or OptiquityTraderTests/.

**Rationale for PROMOTE-TRINITY via STRENGTHEN:** The trinity already has
"PM chat does not architect" bullet, scoped to architecture/planning/review
delegation. The OT learning extends scope: PM chat also does not edit code.
This is a universal-to-all-CLIs rule (the prohibition applies regardless of
which CLI hosts the PM chat). Generalize "Swift source files" → "source
files" so the rule applies to any project language (Swift / Python / C++ /
etc.).

**Trinity STRENGTHEN — target: `## Project memory` "PM chat does not architect"
bullet in CLAUDE.md / AGENTS.md / GEMINI.md.**

BEFORE (current text in `project-template/CLAUDE.md` lines 362-368, identical
in AGENTS.md and GEMINI.md):

```
- **PM chat does not architect.** Architecture, planning,
  implementation, and review work goes to the corresponding agent
  (architect / planner / coder / reviewer / tester / auditor /
  docs-researcher / grpc-schema / repo-ops) — `auditor` covers the
  7 variant agents; see `PACK-AGENTS.md` for the full roster. The
  PM chat handles BACKLOG, STATUS, CHANGELOG, routing, approvals,
  and prompt construction — not the work the agents do.
```

AFTER (replace with):

```
- **PM chat does not architect or code.** Architecture, planning,
  implementation, refactoring, debugging, and review work goes to the
  corresponding agent (architect / planner / coder / reviewer /
  tester / auditor / docs-researcher / grpc-schema / repo-ops) —
  `auditor` covers the 7 variant agents; see `PACK-AGENTS.md` for the
  full roster. The PM chat handles BACKLOG, STATUS, CHANGELOG, routing,
  approvals, and prompt construction — not the work the agents do.
  **PM chat does NOT use Edit / Write tools on source files.** All
  source-file edits (code, in-source comments, variable names,
  configuration files that are part of the build) go to the coder
  agent — no matter how small the change. PM chat's direct-edit scope
  is limited to docs / scripts / agent settings / memory cache. Even
  fixing a comment in a source file requires spawning the coder agent.
```

**Cross-CLI parity:** apply this exact text to AGENTS.md and GEMINI.md per
trinity rule. (Reference: pack-repo trinity rule. The project-template trinity
follows the same rule by construction — see `project-template/CLAUDE.md` line
355.)

### OT-8 — Pack repo read-only; leave working tree modified when told (OUT-OF-SCOPE)

**OT source text (Section 1 items 2 + 3):**

> 2. Pack repo is read-only from the OT working tree. Never modify any file
> under `~/Developer/optiquity-ai-agent-config-pack/` from this project —
> read for reference only.
> 3. Leave the working tree modified when told. When a multi-pass prep job
> (like the trinity marker work) is in flight, do not commit between passes
> even if it feels like a natural checkpoint — wait for explicit "commit and push."

**Rationale for OUT-OF-SCOPE:** OT-8 is OT-session-specific behavior tied to
the v11-prep window when OT was used as a sidecar workspace for testing pack
changes. It is NOT a universal client-project rule. Client projects don't
have a "sibling pack repo" in their working environment. The rule belongs in
the OT project's own files (if anywhere), not in `project-template/`.

**No project-template edit.** Flag for OT to add to OT's own CLAUDE.md /
PM-CHAT.md if OT wants standing rule rather than session-scoped behavior.

### OT-9 — v11 conversion-specific rules (TD scope, Phase 58b deferral, post-v11 prioritization) (OUT-OF-SCOPE)

**OT source text (Section 1 items 4 + 5 + 7):**

> 4. Only open TDs are in scope for v11 conversion. Do not reopen closed or
> deprecated TDs during the BACKLOG → GitHub Issues migration.
> 5. Phase 58b (conversion phase) is deferred until v11 lands. Don't start
> preparing conversion mappings or partial drafts ahead of v11 install.
> 7. Feature prioritization conversation is deferred until after v11.
> Don't push for backlog prioritization decisions before then.

**Rationale for OUT-OF-SCOPE:** These are OT-project-specific decisions
(specific phase numbers, specific deferral targets keyed to OT's release
schedule). Not universal client-project rules. Belong in OT's own
IMPLEMENTATION-PLAN.md / BACKLOG.md / project-side CLAUDE.md addenda.

**No project-template edit.** OT may carry these in OT's own CLAUDE.md
"Project addenda" section (the trinity template has a `<!-- Project addenda
go here -->` marker at line ~422 for exactly this purpose).

### OT-10 — Architect docs read-before-next-steps; tmp reports ephemeral; cadence open questions (STRENGTHEN-OR-DEFER pending research)

**OT source text (Section 1 items 6 + 8 + 10):**

> 6. User reads new architecture docs before next steps proceed. After
> architect output lands (e.g., TD-099/TD-100 designs), pause for the user
> to read before suggesting follow-on work.
> 8. Cadence checkpoints (audit/architect frequency) and concurrency strategy
> (parallel agent batches) are open questions — flag if they become relevant,
> don't decide unilaterally.
> 10. When a sub-agent writes a report to /tmp, treat it as ephemeral —
> confirmed during the docs-researcher test but I don't think there's a
> memory entry for "tmp reports = nothing to revert, safe to share externally."

**Rationale for STRENGTHEN-OR-DEFER:** Item 6 is a candidate for STRENGTHEN
of existing PM-CHAT.md / METHODOLOGY.md behavior (architect output triggers
a user-review pause — analog of pack-side Batch 19b "Planner output → user
review → coder spawn"). Item 8 is OPEN-QUESTION at OT, not a settled rule —
flag for D-10 user discussion. Item 10 is a documentation-clarity rule
(tmp-report semantics) — narrow and possibly already implicit; needs
verification.

**Decision is research-gated.** See §G.2 for the research need; outcome
determines whether OT-10 lands as PROMOTE-PM-CHAT (item 6 STRENGTHEN, item
10 NEW-bullet) or DEFER (waits for item-8 resolution).

### OT-11 — Agent team lifecycle (CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1) (OUT-OF-SCOPE — pack-side)

**OT source text (Section 1 item 1):**

> Agent team lifecycle (CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1). Leave
> docs-researcher / architect / planner / coder / reviewer open across a phase
> and continue them via SendMessage. Close them once the phase is committed.
> Out-of-scope work gets a fresh agent rather than reuse.

**Rationale for OUT-OF-SCOPE:** Already covered by Batch 19b pack-repo trinity
`### Sub-agent behavior (Claude-only)` "Agent-team stage lifecycle + per-commit
fresh-coder" bullet. The OT learning surfaced this because OT runs
pack-development sessions in the OT working directory; in client projects
without pack-development context, the rule still applies but doesn't need
parallel codification in `project-template/` — agent-teams behavior on the
client side is consumed via pack-repo trinity when client developers do
pack-development.

**Possible exception:** Client projects MAY use Agent Teams for parallel
client-side agent execution (architect → planner → coder → reviewer pipeline).
If we want to teach client projects Agent Teams behavior, we should add a
client-side analog. See §F D-6 for this open question.

**Default disposition: OUT-OF-SCOPE for Batch 19c.** Revisit per D-6 user
direction.


---

## §C — Placement decisions (target file + insertion anchor)

This section consolidates §B's per-item placement into a single planner-ready
table with exact file path + insertion anchor.

| OT-ID | Disposition | Target file | Insertion anchor | Bullet count |
|---|---|---|---|---|
| OT-1 (trinity half) | PROMOTE-TRINITY | `project-template/{CLAUDE,AGENTS,GEMINI}.md` `## Project memory` | INSERT after existing "PM chat does not architect" bullet | 1 (×3 files) |
| OT-1 (PM-CHAT half) | PROMOTE-PM-CHAT | `project-template/docs/pack/PM-CHAT.md` `## Behavioral rules` | INSERT after existing "Fix cycle rules" bullet (around line 201) | 1 |
| OT-2 | PROMOTE-PM-CHAT | `project-template/docs/pack/PM-CHAT.md` `## Behavioral rules` | INSERT after OT-1 PM-CHAT bullet | 1 |
| OT-3 | PROMOTE-PM-CHAT | `project-template/docs/pack/PM-CHAT.md` `## Behavioral rules` | INSERT after OT-2 bullet | 1 |
| OT-4 | PROMOTE-PM-CHAT | `project-template/docs/pack/PM-CHAT.md` `## Behavioral rules` | INSERT after OT-3 bullet | 1 |
| OT-5 | ALREADY-COVERED (verify) | n/a (verification step only) | n/a (pack-coder verifies; reports outcome) | 0 (unless verification surfaces a gap, then 1 STRENGTHEN) |
| OT-6 | PROMOTE-PM-CHAT | `project-template/docs/pack/PM-CHAT.md` `## Behavioral rules` | INSERT after OT-4 bullet | 1 |
| OT-7 | STRENGTHEN-TRINITY | `project-template/{CLAUDE,AGENTS,GEMINI}.md` `## Project memory` "PM chat does not architect" bullet | REPLACE in place; rename bullet to "PM chat does not architect or code" | 0 new (×3 file edits) |
| OT-8 | OUT-OF-SCOPE | n/a | n/a | 0 |
| OT-9 | OUT-OF-SCOPE | n/a (belongs in OT's own files) | n/a | 0 |
| OT-10 | DEFER-PENDING-RESEARCH | TBD (PM-CHAT.md likely, pending §G.2 outcome) | TBD | 0-2 (pending §G.2) |
| OT-11 | OUT-OF-SCOPE | n/a (covered by pack-side trinity) | n/a (revisit per D-6) | 0 |

**Edit count summary:**

- Trinity edits: 2 distinct edits per file × 3 trinity files = 6 file-edits.
  (Edit 1: STRENGTHEN existing "PM chat does not architect" bullet per OT-7.
  Edit 2: INSERT new "Reviewer follows every coder run" bullet per OT-1 trinity
  half.)
- PM-CHAT.md edits: 5 distinct edits, all INSERT-after-existing-bullet:
  OT-1 (PM-CHAT half), OT-2, OT-3, OT-4, OT-6.
- Per-agent file edits: 0 (no per-agent file edits needed; OT-7's source-file
  prohibition already covered by existing coder.md hard rule line 80-85
  "No PM-only file edits without explicit caller scoping").

**Total file-edit operations:** 11 (6 trinity + 5 PM-CHAT.md).

**Trinity-rule compliance:** All trinity edits apply to CLAUDE.md / AGENTS.md /
GEMINI.md identically. Per Batch 19b §I.4 precedent, GEMINI.md gets the same
content as CLAUDE.md (no tighter version even though Gemini has a "keep
concise" header — symmetry wins).

---

## §D — Memory cache architecture for project side (D-1 decision)

### D.1 — Decision: trinity-first single-tier-of-truth; NO project-side memory cache template

**Rationale (parity with Batch 19b §A.1):** Per Batch 19b research findings,
Codex memories are opt-in + opaque + EEA-restricted; Gemini has no separate
per-project memory cache (memory IS the GEMINI.md hierarchy); Claude's
`~/.claude/projects/<slug>/memory/` is per-machine and opt-in. The same
constraint applies to client projects: there is no universal cross-CLI
memory cache surface.

For a client project to have universal-to-all-CLIs rules visible at session
start, the rules MUST live in the project trinity (`CLAUDE.md` / `AGENTS.md` /
`GEMINI.md` at the project root). Trinity files are loaded automatically by
all three CLIs.

**What we do NOT do:**

- We do NOT ship a `project-template/.claude/projects/<slug>/memory/` template.
  Per-machine memory caches are not pack-shipped; they are an opt-in local
  convenience that individual developers may use on their own machines.
- We do NOT ship a "client-side MEMORY.md index" file. The project trinity
  `## Project memory` section IS the index (one bullet per rule; the bullet
  body IS the rule body).
- We do NOT define a cross-CLI memory cache protocol for client projects.
  The trinity-only model is the protocol.

### D.2 — Project trinity is the universal surface

The project trinity at `{CLAUDE,AGENTS,GEMINI}.md` (project root after install)
is loaded by all three CLIs on every session:

- **Claude Code CLI** loads `CLAUDE.md` via the standard `CLAUDE.md` hierarchy.
- **Codex CLI** loads `AGENTS.md` via the standard Codex project-doc loading.
- **Gemini CLI** loads `GEMINI.md` via the GEMINI.md hierarchy.

Any rule in the trinity `## Project memory` section is visible to all three
CLIs on every prompt. This is the universal cross-CLI rule surface. No other
file in the project has this property.

### D.3 — Client-machine local memory cache is OPT-IN

A developer may CHOOSE to maintain a Claude-Code-specific memory cache at
`~/.claude/projects/<client-project-slug>/memory/` on their own machine. The
pack does not ship a template for this; the developer creates entries as
they accumulate session-scoped feedback. This is analogous to pack-repo
Claude memory cache for Pack Chat development.

The pack does NOT enforce or audit client-side memory cache content. The
trinity is the authoritative surface; memory cache is per-developer
convenience.

### D.4 — Comparison to pack-repo (parity check)

| Surface | Pack repo | Client project |
|---|---|---|
| Universal cross-CLI rules | Pack-repo trinity `## Pack memory` | Project trinity `## Project memory` |
| PM-chat-orchestration rules | `PACK-CHAT.md` `## Behavioral rules` | `project-template/docs/pack/PM-CHAT.md` `## Behavioral rules` (becomes `docs/pack/PM-CHAT.md` after install) |
| Per-agent behavior rules | Per-agent files (`.claude/agents/*.md`, `.codex/agents/*.toml`, `.gemini/agents/*.md`) | Same per-agent files (installed from `project-template/.claude/agents/*.md`, `.codex/agents/*.toml`, `.gemini/agents/*.md`) |
| Claude-Code memory cache (opt-in, per-machine) | `~/.claude/projects/<pack-slug>/memory/*.md` (Tier 1.5 pointer files post-Batch-19b) | `~/.claude/projects/<client-slug>/memory/*.md` (no template; opt-in per-developer) |
| Codex memory cache | n/a (per Batch 19b research) | n/a (same constraint) |
| Gemini memory cache | n/a (per Batch 19b research) | n/a (same constraint) |

**Symmetry note:** The pack-repo and client-project surfaces are structurally
parallel. The Batch 19b design (trinity-first, Tier 1.5 Claude-only pointer
cache for the pack repo) is directly analogous to the Batch 19c design
(trinity-first, no template for the client-side optional memory cache).

---

## §E — Items explicitly OUT OF SCOPE

Per task constraints and §A categorization, this batch does NOT propose:

- **Pack-side files** — `PACK-CHAT.md`, `PACK-AGENTS.md`, pack-root trinity,
  `scripts/`, `supporting-docs/`, `maintenance-docs/`, pack-repo Claude memory
  cache. These were Batch 19b's domain. Pack-side rule surface is unchanged
  in Batch 19c.
- **OT-specific rules** (OT-9). These belong in OT's own project files, not
  in `project-template/`. The trinity template provides a `<!-- Project
  addenda go here -->` marker for exactly this purpose; OT may use that
  marker in OT's own CLAUDE.md/AGENTS.md/GEMINI.md.
- **OT-session-scoped behavior** (OT-8 — sidecar pack-prep behavior). Not a
  standing client-project rule.
- **Per-CLI memory cache for project side** (D-1 decision). No template, no
  protocol, no shipped MEMORY.md.
- **Agent Teams behavior for client side** (OT-11; revisit per D-6). Default:
  pack-side trinity is the home; client-side trinity does not get a parallel
  bullet unless D-6 user decision says otherwise.
- **Per-agent file rewrites.** No per-agent file edits in Batch 19c — OT-7's
  source-file prohibition is already covered by existing `coder.md` Hard
  rules (line 80-85) and `reviewer.md` Hard rules (line 48-55). New cross-
  agent rules belong in trinity, not in every agent file.
- **`docs/pack/prompts/*.md` rewrites.** OT-6's re-read discipline is a
  PM-chat-behavior rule; prompt-template files themselves are unchanged.
- **METHODOLOGY.md edits.** METHODOLOGY.md ships from `supporting-docs/`,
  not from `project-template/`. Edits to METHODOLOGY.md are pack-side work,
  out of scope for Batch 19c (which targets `project-template/` only). If
  OT-2 (architect trigger check) or OT-4 (BACKLOG check at phase gate)
  requires METHODOLOGY.md text that doesn't currently exist, that becomes
  a separate pack-side BD opened per OQ-1 (user-discussion-and-approval).
- **Project-template skills extensions** (e.g., adding a new skill for
  PM-chat-behavior). OT learnings are rules, not skill content. Skills
  carry technical/methodology knowledge; rules belong in trinity or
  PM-CHAT.md.
- **README.md / agent-run.sh edits.** Not implicated by any OT item.
- **Tracker config example edits.** Not implicated.
- **Per-CLI settings.json edits.** Not implicated.
- **CI / GitHub Actions edits.** Not implicated.
- **New BDs.** Per OQ-1 (rewritten EXECUTION-PLAN-V11.0.md §B step 5), new-BD-
  opens require user-discussion-and-approval; this batch proposes no new BDs.
  If §G research surfaces blockers, those would open new BDs only with
  explicit user approval.


---

## §F — Open questions for user discussion at architect-review gate

Per task constraints, every architecturally-significant choice that I cannot
unilaterally make becomes a discussion item here. The goal is to keep this
section small but explicit.

### D-1 — Memory cache architecture for project side (decision)

**Question:** Confirm or challenge the §D recommendation: trinity-first
single-tier-of-truth; no project-side memory cache template; client-machine
Claude memory caches are opt-in per-developer with no pack-shipped template.

**Options:**

- **(a) Accept §D recommendation** — trinity-only; no template; opt-in
  per-developer. (Architect recommendation.)
- **(b) Ship a project-template/.claude/projects/memory/ template scaffold** —
  give client developers a starting MEMORY.md and a few example entries.
  (Rejected by architect because (i) per Batch 19b research, the cache is
  per-machine and Claude-only — a template doesn't propagate to Codex/Gemini
  developers; (ii) trinity already covers the universal-rule surface;
  (iii) shipping a template implies an enforced convention that we don't
  audit.)
- **(c) Ship a different per-CLI cache structure** — e.g., a
  `project-template/docs/pack/PROJECT-MEMORY.md` file that summarizes
  project-side learnings. (Rejected: this is just a renamed trinity
  `## Project memory` — duplicates content without adding propagation value.)

**Architect recommendation: (a).** This matches Batch 19b's collapsed two-tier
model and avoids inventing a convention that doesn't reliably propagate.

### D-2 — STRENGTHEN bullet wording for OT-7 (PM chat does not architect OR CODE)

**Question:** The OT-7 STRENGTHEN expands the existing "PM chat does not
architect" trinity bullet to also prohibit source-file edits by PM chat. Two
sub-decisions:

**Sub-decision (a) — Generalize "Swift" → "source files":** OT's source text
says "any .swift file." Client projects may be Python, Swift, C++, etc.
Architect recommends generalizing.

**Sub-decision (b) — Bullet title:** Two candidates:
- (i) "PM chat does not architect or code" (architect recommendation; short,
      symmetric with original title)
- (ii) "PM chat scope" (broader title; matches pack-repo trinity `### Pack
       Chat scope` sub-section naming convention)

**Architect recommendation: (a) generalize + (b)(i) keep title symmetry with
existing trinity bullet.** Option (b)(ii) would require splitting the bullet
into a new sub-section, which is a larger restructure not warranted by the
single OT-7 extension. If a future batch promotes more project-side rules
that warrant a `### PM Chat scope` sub-section (analogous to Batch 19b's
new sub-section), revisit then.

### D-3 — Reviewer-after-coder rule landing in trinity (PROMOTE-BOTH)

**Question:** Confirm or challenge the §B (OT-1 row) PROMOTE-BOTH disposition.
Two surfaces: trinity bullet (universal-to-all-CLIs collaboration rule) AND
PM-CHAT.md bullet (PM-chat-specific orchestration rule).

**Options:**

- **(a) PROMOTE-BOTH per architect recommendation** — universal rule in
  trinity (visible to any agent on any CLI); PM-chat-orchestration text in
  PM-CHAT.md (with cross-reference to trinity for the universal rule).
- **(b) PROMOTE-PM-CHAT only** — argue this is purely PM-chat orchestration
  and doesn't need trinity placement.
- **(c) PROMOTE-TRINITY only** — argue PM-CHAT.md is redundant if trinity
  carries the universal rule.

**Architect recommendation: (a).** The OT learning's stakes (the original
incident allowed unauthorized structural code changes to nearly commit
without review) justify visibility on every prompt, not just on PM-chat
prompt-construction. Trinity is the universal surface. PM-CHAT.md is the
operational re-statement for the PM chat specifically.

### D-4 — Closeout approval sequence as separate bullet vs. STRENGTHEN existing "Source file edits" bullet

**Question:** OT-3 (closeout approval sequence) overlaps with existing
PM-CHAT.md `## Behavioral rules` bullet "Source file edits." Two options:

- **(a) NEW separate bullet** "Closeout approval sequence" (architect
  recommendation per §B OT-3 row) — covers the SEQUENCE (propose-content-
  first → approval → write) which is distinct from the WHAT (which files
  PM chat may write).
- **(b) STRENGTHEN existing "Source file edits" bullet** to include the
  sequence — keeps related content adjacent but bullet body gets long.

**Architect recommendation: (a).** Separation of concerns: existing bullet
governs scope (what files); new bullet governs sequence (when/how). Keeping
them separate lets each bullet stay focused. PM-CHAT.md already has ~15
behavioral rule bullets; +1 is not excessive.

### D-5 — Architect-trigger-check rule wording: trigger-conditions inline or cross-reference METHODOLOGY.md

**Question:** OT-2 (architect trigger check) is conditional on the existence
of METHODOLOGY.md Workflow 4 step 3. Sub-decisions:

**Sub-decision (a) — Do trigger conditions exist in METHODOLOGY.md today?**
(Research need: see §G.1. If yes, PM-CHAT.md bullet can cross-reference. If
no, PM-CHAT.md must inline the trigger conditions OR a separate pack-side BD
adds them to METHODOLOGY.md.)

**Sub-decision (b) — If METHODOLOGY.md needs the addition:** That is a
pack-side edit (METHODOLOGY.md ships from `supporting-docs/`). Per §E, this
batch does NOT edit pack-side files. Options:

- **(b-i) Inline the trigger conditions in PM-CHAT.md** (architect
  recommendation per §B OT-2 row) — self-contained; doesn't depend on
  pack-side edits. Cross-references METHODOLOGY.md for "underlying workflow"
  but doesn't require METHODOLOGY.md to carry the trigger conditions.
- **(b-ii) Open a separate pack-side BD** for METHODOLOGY.md addition; defer
  OT-2 PM-CHAT.md bullet until that BD lands.
- **(b-iii) Inline in PM-CHAT.md AND open pack-side BD** to add to
  METHODOLOGY.md for completeness.

**Architect recommendation: (b-i) for Batch 19c.** Inline is self-contained;
PM-CHAT.md bullet stands alone. If user wants METHODOLOGY.md to also carry
the trigger conditions, that becomes a separate user-approved pack-side BD
(per OQ-1) — but not blocking Batch 19c.

### D-6 — Agent Teams behavior for client projects (OT-11 disposition)

**Question:** OT-11 (Agent Teams stage lifecycle) is currently OUT-OF-SCOPE
(default disposition per §B). Should client projects get a parallel rule in
project-template trinity for client-side Agent Teams usage?

**Options:**

- **(a) Leave OUT-OF-SCOPE** (architect default) — Agent Teams is currently
  only documented for pack-development context (per Batch 19b §I.1
  `### Sub-agent behavior (Claude-only)`). Client projects may use Agent Teams
  but the rule is the same (close after stage commit; respawn fresh per
  commit); duplicating it in client trinity adds surface without adding value.
- **(b) Add to project-template trinity** as a Claude-only sub-section
  (analog of pack-side `### Sub-agent behavior (Claude-only)`) — gives
  client PM chats explicit Agent Teams guidance.
- **(c) Defer entirely** — Agent Teams is experimental
  (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`); wait until stable before
  adding client-side rules.

**Architect recommendation: (a) for Batch 19c.** Pack-side Batch 19b already
codifies the rule; pack developers running Agent Teams in client projects
inherit the rule via pack-repo trinity. Client developers without
pack-development context likely don't run Agent Teams at all (it's used for
multi-stage architect→planner→coder pipelines, which the project-side
methodology already orchestrates through PM-CHAT.md sequencing). If user
wants client-side codification, defer to a future batch (post-v11.0
candidate).

### D-7 — OT-10 (items 6, 8, 10) disposition pending §G.2 research

**Question:** OT-10's three sub-items (architect-doc read-before-next-steps;
cadence open questions; tmp report ephemeral semantics) need research per
§G.2 before a placement decision. Two-step:

**Step 1 — Wait for §G.2 research, then revisit.** Architect drafts addendum/
V2 with concrete dispositions for each sub-item.

**Step 2 — User decision at architect-addendum/V2 review.** Per-sub-item:
PROMOTE-PM-CHAT (new bullet), STRENGTHEN-EXISTING (modify existing bullet),
or DEFER (future BD with explicit user direction).

**Architect recommendation: Step 1 first (research), then Step 2 (user
decision at architect-addendum review).** No premature commitment.

### D-8 — Commit sequencing decision (planner-rough-draft)

**Question:** Per §H rough draft, Batch 19c is ~4 commits (trinity edits,
PM-CHAT.md edits, archive workflow artifacts; possibly 1-2 more depending on
D-7 research outcome). Confirm the rough shape?

**Options:**

- **(a) 4-commit shape per §H** (architect recommendation) — keeps related
  edits together; matches Batch 19b's per-file-grouping pattern.
- **(b) Single-commit shape** — all edits in one commit. Discouraged because
  it makes review harder and violates the "small reviewable commits"
  preference.
- **(c) Per-OT-item commit shape (~8 commits)** — one commit per OT item.
  Discouraged because it produces too many tiny commits and breaks the
  per-file-grouping pattern.

**Architect recommendation: (a) ~4 commits, planner refines.**

### D-9 — Research-pass timing: before or after V2 / addendum?

**Question:** §G surfaces research needs (METHODOLOGY.md content, OT-10
sub-item context). Two options for timing:

- **(a) Research → architect-addendum (or V2) → planner** — researcher
  produces report; same or fresh architect produces addendum (or V2 if
  scope materially changes); planner sequences. Matches Batch 19b precedent.
- **(b) Skip research; architect produces V2 with conservative defaults**
  (e.g., assume METHODOLOGY.md does NOT cover trigger conditions; inline
  in PM-CHAT.md per D-5(b-i)). Faster but risks duplicate content if
  METHODOLOGY.md already covers it.

**Architect recommendation: (a) for D-5 + D-7 sub-questions.** Research
is small (verify two METHODOLOGY.md sections; verify two OT context items)
and prevents downstream duplication / drift. Per Batch 19b
`feedback-researcher-architect-planner-pipeline` memory rule, "when work
depends on domain knowledge verified against authoritative external sources
... pipeline is researcher → architect → planner → coder."

### D-10 — Per-BD review/fix cycle gate (per pack-memory rule)

**Question:** Per pack-memory rule `feedback_review_fix_one_cycle` and Batch
19b trinity bullet "Per-BD review/fix runs INLINE": Batch 19c is a single-BD
batch (BD-173). Single-BD batches need only one review/fix cycle (end-of-batch
reviewer). Confirm.

**Architect recommendation: yes, one review/fix cycle.** End-of-batch
pack-reviewer runs once on the full Batch 19c diff. No per-commit reviewer
runs (those are for multi-BD batches with per-BD impl).

### D-11 — Archive timing for workflow artifacts (this doc + V2/addendum + plan + IMPL-REPORT)

**Question:** Per Batch 19b `### Repo conventions` "Skill and agent maintenance
is mechanical by default" trinity bullet, workflow artifacts (ARCHITECTURE-*,
PLAN-*, IMPLEMENTATION-REPORT-*, PACK-REVIEW-*, RESEARCH-*) "sweep to
`maintenance-docs/archive/vN/` at version ship as the final pre-tag step
(Pattern B)." However, Batch 19b's own cleanup batch overrode this — it
archived at batch end per OQ-6, not at version ship.

**Options:**

- **(a) Archive at v11.0 ship time** (Pattern B default) — matches the
  trinity rule.
- **(b) Archive at end of Batch 19c** (per Batch 19b precedent for cleanup
  batches) — workflow artifacts have no live forward-pointing value after
  the rules land.
- **(c) Defer decision** — let planner / Pack Chat decide at end-of-batch
  approval.

**Architect recommendation: (b) — archive at end of Batch 19c per Batch 19b
precedent.** Cleanup batches consume their workflow artifacts immediately;
archiving keeps `maintenance-docs/v11-implementation/` clean for in-flight
work.

---

## §G — Research needs (for pack-docs-researcher pass between this doc and V2/addendum)

Per `feedback-researcher-architect-planner-pipeline`, research needs that
require external/file-verified information beyond architect knowledge get a
docs-researcher pass between architect first-pass and architect addendum/V2.

### G.1 — METHODOLOGY.md content verification (D-5 dependency)

**Research need:** Verify what `supporting-docs/METHODOLOGY.md` currently
contains regarding:

1. **Workflow 4 step 3 architect trigger conditions** (OT-2 cited).
   - Does Workflow 4 exist?
   - Does step 3 of Workflow 4 enumerate architect trigger conditions
     (Trigger A: 3+ coder runs without resolution; Trigger B: regression or
     issue-count increase)?
   - If yes: PM-CHAT.md bullet can cross-reference, no inline.
   - If no: PM-CHAT.md bullet inlines the trigger conditions per D-5(b-i).

2. **Part 7 Procedure 1 step 3 — TD lifecycle / BACKLOG-check-at-phase-gate**
   (OT-4 cited).
   - Does Part 7 Procedure 1 step 3 name the BACKLOG-check rule?
   - If yes: PM-CHAT.md bullet can cross-reference, no full inline.
   - If no: PM-CHAT.md bullet describes the check fully.

**Researcher sources:**

- File: `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/supporting-docs/METHODOLOGY.md`
  (full read; search for "Workflow 4", "Trigger A", "Trigger B", "Part 7",
  "Procedure 1", "BACKLOG check", "phase gate").
- Cross-check: Search any project-template references to METHODOLOGY.md
  Workflow 4 or Part 7 Procedure 1 (in PM-CHAT.md, in per-agent files, in
  prompt templates).

**Researcher output:** Two short paragraphs (one per question), each ending
with a Y/N verdict on "is content present in METHODOLOGY.md today?" Plus
exact file:section anchors for the content found (or absence noted).

### G.2 — OT-10 sub-item context (D-7 dependency)

**Research need:** OT-10 sub-items 6 and 10 are candidate PM-CHAT.md
additions; sub-item 8 is "open question per OT." Verify:

1. **OT item 6 ("user reads architect docs before next steps proceed")** —
   does any existing project-template or pack-side surface (PM-CHAT.md,
   METHODOLOGY.md, pack-repo trinity Workflow section) already codify a
   "user-reads-architect-output-before-next-step" pause rule? If yes, what
   wording? If no, what's the closest analog?

2. **OT item 10 ("tmp reports = nothing to revert, safe to share externally")**
   — does any existing surface document the semantics of `/tmp` agent report
   outputs? If yes, what wording? If no, this becomes a NEW PM-CHAT.md bullet.

3. **OT item 8 ("cadence checkpoints and concurrency strategy are open questions")**
   — verify whether this is an OT-only open question or a universal client-
   project open question. Likely OT-specific (pack-development cadence is OT's
   concern). If universal: a new BD candidate; if OT-specific: OUT-OF-SCOPE
   per §E.

**Researcher sources:**

- File: `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/supporting-docs/METHODOLOGY.md`
  (search "tmp", "architect output", "user review", "cadence", "concurrency").
- File: `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/docs/pack/PM-CHAT.md`
  (same searches).
- File: `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/PACK-CHAT.md`
  (pack-repo — for comparison; pack-side may have an analog under
  `feedback-planner-user-review-before-coder` precedent).

**Researcher output:** Three short paragraphs (one per sub-item), each
naming existing coverage (if any) and gap (if any).

### G.3 — Per-CLI memory cache documentation verification (D-1 confirmation)

**Research need:** D-1 architect recommendation cites Batch 19b research. To
confirm that recommendation for the project-side context (not just pack-side):

1. **Confirm Codex per-project memory cache constraint applies in client
   project context** — Batch 19b research established Codex memories are
   opt-in + EEA-restricted + opaque-generated for the pack-repo session.
   Does the same constraint apply to client-project Codex sessions? (Expected:
   yes; the constraint is on Codex platform behavior, not on pack-vs-client
   project distinction. Confirm.)

2. **Confirm Gemini hierarchy applies symmetrically** — Batch 19b research
   established Gemini "has no separate per-project memory cache (memory IS
   the GEMINI.md hierarchy)." Confirm this applies symmetrically to client
   projects.

3. **Confirm Claude Code `~/.claude/projects/<slug>/memory/` directory
   naming** — for client projects, the slug is derived from the client
   project directory path (not pack repo path). Confirm the cache directory
   would appear at `~/.claude/projects/<client-slug>/memory/` per Claude
   Code's standard slug derivation.

**Researcher sources:**

- Batch 19b research artifact: `maintenance-docs/archive/v11/RESEARCH-CLEANUP-BATCH-19B-CROSS-CLI.md` (likely)
- Claude Code memory docs (web — `https://docs.anthropic.com/claude/docs/claude-code-memory`)
- Codex CLI memory docs (web)
- Gemini CLI memory docs (web)

**Researcher output:** Three short paragraphs (one per question), Y/N
confirmation each. Quick — this is "confirm Batch 19b research generalizes
to client projects."

### G.4 — Research need that does NOT exist (explicit no-research items)

For clarity, no research is needed on:

- OT-1, OT-3, OT-5, OT-6, OT-7, OT-8, OT-9, OT-11 — all dispositioned
  directly from OT source text + existing project-template surface; no
  external verification required.
- D-1 architecture-decision itself — based on Batch 19b research findings
  that I have direct access to via referenced V2 architect doc.
- D-2 through D-4, D-6, D-8, D-10, D-11 — user-decision items, not
  research items.


---

## §H — Commit sequencing rough draft (planner refines)

This is an architect-side rough shape. Planner will produce the final
`PLAN-CLEANUP-BATCH-19C.md` after research (§G) lands and any V2 / addendum
revises the per-item dispositions per D-7.

### H.1 — 4-commit shape (D-8 architect recommendation)

```
Commit 19c-1: docs: v11 — BD-173 project trinity ## Project memory edits

  Scope: project-template/CLAUDE.md, project-template/AGENTS.md,
         project-template/GEMINI.md
  Edits:
    - STRENGTHEN existing "PM chat does not architect" bullet → "PM chat
      does not architect or code" (per §B OT-7 row); apply to all 3 files.
    - INSERT new "Reviewer follows every coder run" bullet (per §B OT-1
      trinity half); apply to all 3 files.
  Verification:
    - Trinity rule compliance: all 3 files updated identically.
    - validate-pack CI: trinity invariants.
    - Read-only review by Pack Chat.

Commit 19c-2: docs: v11 — BD-173 project PM-CHAT.md ## Behavioral rules
              extensions

  Scope: project-template/docs/pack/PM-CHAT.md
  Edits:
    - INSERT new "Reviewer follows every coder run" bullet (PM-CHAT half;
      per §B OT-1 PM-CHAT row).
    - INSERT new "Architect trigger check after every reviewer report"
      bullet (per §B OT-2).
    - INSERT new "Closeout approval sequence" bullet (per §B OT-3).
    - INSERT new "BACKLOG check at every phase gate" bullet (per §B OT-4).
    - INSERT new "Re-read the agent prompt file every time" bullet (per
      §B OT-6).
    - (OT-5 verification — if existing "No commit without explicit
      approval" bullet missing the "even small changes" clause, STRENGTHEN
      in this commit; otherwise no edit. Per §B OT-5 row.)
    - (OT-10 sub-items 6 / 10 if D-7 resolves to PROMOTE-PM-CHAT — INSERT
      additional 1-2 bullets per §G.2 research outcome. Pending §G.2.)
  Verification:
    - Read-only review by Pack Chat.
    - PM-CHAT.md bullet ordering matches §H.2 theme-clustering.

Commit 19c-3 (CONDITIONAL — only if §G.1 research surfaces METHODOLOGY.md
              gaps that user approves filling): docs: v11 — BD-NNN
              supporting-docs/METHODOLOGY.md extensions

  Scope: supporting-docs/METHODOLOGY.md (PACK-SIDE — out of normal scope
         per §E; requires separate user-approved BD per OQ-1 if pursued).
  Edits: Workflow 4 trigger conditions addition (only if D-5 research
         outcome says METHODOLOGY.md lacks them AND user approves the
         pack-side BD per OQ-1).
  Default: SKIP. PM-CHAT.md inline per D-5(b-i) handles it.

Commit 19c-4 (FINAL): docs: v11 — BD-173 archive Batch 19c workflow
              artifacts

  Scope: maintenance-docs/v11-implementation/CLEANUP-INPUTS-BATCH-19C/
         (directory; currently empty) — leave in place OR archive.
         maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19C.md
         (this doc) → archive
         maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19C-V2.md
         (if produced) → archive
         maintenance-docs/v11-implementation/RESEARCH-CLEANUP-BATCH-19C.md
         (if produced per §G) → archive
         maintenance-docs/v11-implementation/PLAN-CLEANUP-BATCH-19C.md
         (when planner produces) → archive
         maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-CLEANUP-BATCH-19C.md
         (when pack-coder produces) → archive
         maintenance-docs/v11-implementation/PACK-REVIEW-CLEANUP-BATCH-19C.md
         (when reviewer produces) → archive
  Target: maintenance-docs/archive/v11/
  Per: D-11 architect recommendation (archive at batch end, Batch 19b
       precedent for cleanup batches).
  Verification:
    - Directory listing of maintenance-docs/archive/v11/ confirms all
      workflow artifacts present.
    - maintenance-docs/v11-implementation/ no longer contains
      ARCHITECTURE-CLEANUP-BATCH-19C.md or related artifacts.
    - BD-173 status flips from Open to Resolved as part of this commit
      (per `feedback_implicit_status_flip`: when review fixes are green
      and tests pass, flip the BD as the final step of the batch).
```

**Total commits: 3 (default) or 4 (if §G.1 research opens a pack-side BD
per OQ-1).** Commit 19c-3 is conditional.

### H.2 — PM-CHAT.md `## Behavioral rules` ordering for new bullets

Per Batch 19b §H.2 precedent (theme-clustered ordering), recommend the new
5 (or 6-7 if OT-10 adds bullets) PM-CHAT.md bullets land in this order
relative to existing bullets:

```
Existing bullets (unchanged, pre-OT additions):
  - Plan before executing
  - No solutions in agent prompts
  - Follow Prompt Authoring Principles
  - Select skills using PLATFORM-SKILLS.md
  - Check active skills at every phase gate
  - BACKLOG and deferral comment rules
  - Fix cycle rules
  - Source file edits
  - STATUS.md phase title links
  - STATUS.md never-source-of-truth disclaimer
  - Pack feedback loop
  - Custom files via Procedure 5 only
  - Detection scan at every startup and every phase gate
  - Pack roster is in ## Pack agent roster above
  - Agent report file
  - No prior reviews to reviewer
  - Chunk long writes in agent prompts
  - Capability addition

NEW bullets inserted in the following order, grouped by theme:

  [Group: review/fix cycle — adjacent to existing "Fix cycle rules"]
  After existing "Fix cycle rules" bullet:
    - Reviewer follows every coder run                    [OT-1 PM-CHAT half]
    - Architect trigger check after every reviewer report [OT-2]

  [Group: phase-gate orchestration]
  After OT-2 bullet:
    - BACKLOG check at every phase gate                   [OT-4]

  [Group: closeout sequencing]
  After OT-4 bullet:
    - Closeout approval sequence                          [OT-3]

  [Group: prompt construction discipline — adjacent to existing
   "Follow Prompt Authoring Principles" bullet, but new placement
   sits with the review/fix cluster for tighter cohesion. Architect
   placement decision: keep with cluster.]
  After OT-3 bullet:
    - Re-read the agent prompt file every time            [OT-6]

  [Group: pending §G.2 — OT-10 sub-items 6 / 10 if D-7 resolves
   to PROMOTE]
  After OT-6 bullet (pending §G.2):
    - User reads architect output before next-step proposals  [OT-10 item 6 if PROMOTE]
    - /tmp agent reports are ephemeral                        [OT-10 item 10 if PROMOTE]
```

5 NEW bullets confirmed (OT-1 PM-CHAT half, OT-2, OT-3, OT-4, OT-6); 0-2
more depending on §G.2 outcome.

### H.3 — Trinity `## Project memory` structure POST-Batch-19c

```
## Project memory

[existing 5-line preamble — unchanged]

- **Trinity rule.** [unchanged]
- **No destructive operations without explicit approval.** [unchanged]
- **PM chat does not architect or code.** [STRENGTHENED per OT-7 §B]
- **Reviewer follows every coder run.** [NEW per OT-1 trinity half §B]
```

**Bullet count: 4 (was 3 pre-batch).** Modest growth. Trinity file
size impact: ~15 lines added per file × 3 files = trivial. CLAUDE.md
goes from 426 → ~441 lines; AGENTS.md from 402 → ~417 lines; GEMINI.md
from 449 → ~464 lines. Well within any soft cap concern.

### H.4 — Workflow artifact archive list (D-11 + Pattern B exception per Batch 19b precedent)

Per D-11 architect recommendation, the final commit archives:

1. `maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19C.md`
   (this doc)
2. `maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19C-V2.md`
   (if user direction at architect-review gate produces a V2)
3. `maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19C-ADDENDUM.md`
   (if architect-addendum is the chosen second-pass shape instead of V2)
4. `maintenance-docs/v11-implementation/RESEARCH-CLEANUP-BATCH-19C.md`
   (if pack-docs-researcher pass produces per §G; could be one report or
   per-question sub-reports)
5. `maintenance-docs/v11-implementation/PLAN-CLEANUP-BATCH-19C.md`
   (planner output)
6. `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-CLEANUP-BATCH-19C.md`
   (pack-coder output)
7. `maintenance-docs/v11-implementation/PACK-REVIEW-CLEANUP-BATCH-19C.md`
   (end-of-batch reviewer output, if produced)

**Archive target:** `maintenance-docs/archive/v11/`

**Move verb:** `git mv` (not `mv` — preserves history).

**Verification:** Directory listing confirms artifacts present in archive,
absent from `v11-implementation/`.


---

## §I — Summary table (all OT items + dispositions + targets, one row each)

| OT-ID | Title | Disposition | Target file (post-install path in client) | Insertion anchor | Edit type |
|---|---|---|---|---|---|
| OT-1 | Reviewer follows every coder run | PROMOTE-BOTH | (a) `{CLAUDE,AGENTS,GEMINI}.md` `## Project memory`; (b) `docs/pack/PM-CHAT.md` `## Behavioral rules` | (a) after "PM chat does not architect or code"; (b) after "Fix cycle rules" | INSERT new bullet (×4 file-edits: 3 trinity + 1 PM-CHAT) |
| OT-2 | Architect trigger check after every reviewer report | PROMOTE-PM-CHAT | `docs/pack/PM-CHAT.md` `## Behavioral rules` | after OT-1 PM-CHAT bullet | INSERT new bullet |
| OT-3 | Closeout approval sequence | PROMOTE-PM-CHAT | `docs/pack/PM-CHAT.md` `## Behavioral rules` | after OT-4 bullet | INSERT new bullet |
| OT-4 | BACKLOG check at every phase gate | PROMOTE-PM-CHAT | `docs/pack/PM-CHAT.md` `## Behavioral rules` | after OT-2 bullet | INSERT new bullet |
| OT-5 | Never commit without explicit user approval | ALREADY-COVERED-VERIFY | `docs/pack/PM-CHAT.md` `## Behavioral rules` "No commit without explicit approval" | n/a (verify wording) | 0 (or STRENGTHEN if gap) |
| OT-6 | Re-read agent prompt file every time | PROMOTE-PM-CHAT | `docs/pack/PM-CHAT.md` `## Behavioral rules` | after OT-3 bullet | INSERT new bullet |
| OT-7 | PM chat must NEVER modify source files | STRENGTHEN-TRINITY | `{CLAUDE,AGENTS,GEMINI}.md` `## Project memory` "PM chat does not architect" bullet | n/a (replace in place) | REPLACE existing bullet (×3 files) |
| OT-8 | Pack repo read-only; working-tree-modified handling | OUT-OF-SCOPE | n/a (OT session-scoped behavior) | n/a | 0 |
| OT-9 | v11 conversion-specific (TD scope, Phase 58b, post-v11 prioritization) | OUT-OF-SCOPE | n/a (OT project-specific; belongs in OT's own files) | n/a | 0 |
| OT-10 | Architect docs read-before-next-steps; tmp ephemeral; cadence open | DEFER-PENDING-RESEARCH | TBD (pending §G.2) | TBD | 0-2 (pending §G.2) |
| OT-11 | Agent Teams stage lifecycle | OUT-OF-SCOPE | n/a (covered by pack-side Batch 19b) | n/a | 0 |

**Total file-edit operations:** 11 default (5 PM-CHAT inserts + 1 PM-CHAT
verify + 3 trinity inserts + 3 trinity strengthens — wait, let me recount
against §C properly).

**Recount per §C edit count summary:**

- Trinity edits per file (CLAUDE.md, AGENTS.md, GEMINI.md):
  - Edit 1: STRENGTHEN "PM chat does not architect" → "PM chat does not
    architect or code" (OT-7).
  - Edit 2: INSERT "Reviewer follows every coder run" bullet (OT-1 trinity
    half).
  - Per file: 2 edits. Three files: 6 trinity file-edits.

- PM-CHAT.md edits (single file):
  - Edit 1: INSERT "Reviewer follows every coder run" (OT-1 PM-CHAT half).
  - Edit 2: INSERT "Architect trigger check after every reviewer report" (OT-2).
  - Edit 3: INSERT "BACKLOG check at every phase gate" (OT-4).
  - Edit 4: INSERT "Closeout approval sequence" (OT-3).
  - Edit 5: INSERT "Re-read the agent prompt file every time" (OT-6).
  - Plus OT-5 verification (0 file-edits if wording is correct; +1
    STRENGTHEN if not).
  - Plus 0-2 conditional inserts from §G.2 (OT-10 sub-items).
  - Default: 5 PM-CHAT.md file-edits. Conditional: up to 8.

**Default total: 11 file-edit operations.** (Conditional max: 14.)

---

## §J — Comparison to Batch 19b (architecture symmetry check)

This section is a sanity check: are project-side rules being landed in a
shape that PARALLELS pack-side rules (per Batch 19b)? If yes, the two
surfaces are structurally symmetric, which makes maintenance easier and
makes future cross-applies (per OQ-3 future discussion) cleaner.

### J.1 — Surface parity

| Surface | Pack-side (post-Batch-19b) | Project-side (post-Batch-19c, this design) | Symmetric? |
|---|---|---|---|
| Universal cross-CLI rules | Pack-repo trinity `## Pack memory` (~35 bullets after Batch 19b) | Project trinity `## Project memory` (4 bullets after Batch 19c) | YES (structurally parallel, different sizes) |
| Chat-orchestration rules | `PACK-CHAT.md` `## Behavioral rules` (~16 bullets after Batch 19b) | `project-template/docs/pack/PM-CHAT.md` `## Behavioral rules` (~20 bullets after Batch 19c) | YES |
| Per-agent rules | Pack-agent files (3 directories × N agents) | Project-agent files (3 directories × 16 agents) | YES |
| Claude memory cache | Per-machine, Tier 1.5 pointer files (Pack Chat owns) | Per-machine, no template (developer owns) | ASYMMETRIC by design — pack has Tier 1.5 because Batch 19b promoted 26 rules from memory to trinity; project has no analogous historical promotion. This is fine. |
| Codex memory | Not shipped, not designed | Not shipped, not designed | YES (symmetric absence) |
| Gemini memory | Not shipped, not designed (Gemini hierarchy IS memory) | Not shipped, not designed | YES |

### J.2 — Bullet shape parity

Compare a representative project-side new bullet (OT-1 trinity) to a
representative pack-side new bullet from Batch 19b (L1 "Pack Chat does NO
fixes"):

Project-side OT-1 trinity bullet structure:
- Bullet title in bold
- 2-3 sentence rule body
- Trigger conditions / scope clauses
- Cross-reference to related rule

Pack-side L1 trinity bullet structure:
- Bullet title in bold
- 2-3 sentence rule body
- Trigger conditions / scope clauses
- Rationale clause

Symmetric: yes (modulo content). Both use bold-titled bullets, 3-6 line
bodies, no nested sub-bullets for simple rules.

### J.3 — Where project-side INTENTIONALLY differs from pack-side

- **Smaller bullet count.** Pack-side trinity Pack memory has ~35 bullets;
  project-side trinity Project memory has 4 bullets post-Batch-19c. Project
  rules are narrower — client projects have less operational complexity
  (no multi-stage architect-planner-coder-reviewer pipelines run from a
  single chat; the PM-chat operational role is simpler). This asymmetry is
  expected and intentional.

- **No Claude-only sub-section.** Pack-side trinity has `### Sub-agent
  behavior (Claude-only)` covering isolation / background-spawn / Agent
  Teams. Project-side has no analog (per D-6 architect default). If client
  projects start using Agent Teams routinely, revisit.

- **No "Pack Chat scope" sub-section.** Pack-side has `### Pack Chat scope`
  for "does no fixes" / "commit-approval next steps" / "architect spawn
  protocol." Project-side has only one analog ("PM chat does not architect
  or code" — single bullet, no sub-section needed at current scale).

- **No "Repo conventions" sub-section.** Pack-side has `### Repo conventions`
  (8+ bullets — per-entry trees / BACKLOG structure / test infra /
  skill maintenance / etc.). Project-side has equivalent conventions but
  they're scattered across CLAUDE.md sections ("Document locations",
  "Scripts", "Build and repo hygiene", "Deferral comments and BACKLOG
  hygiene"). Project-side conventions are already organized; no
  consolidation needed.

### J.4 — Symmetry verdict

Structurally symmetric where it matters (universal-rule surfaces, chat-
orchestration surfaces, per-agent surfaces). Asymmetric where it makes
sense (no Tier 1.5 because no historical memory cache to consolidate; no
sub-sections because rule count doesn't warrant it).

The Batch 19c design is consistent with Batch 19b design without
duplicating pack-side complexity for project-side simpler use-cases.

---

## §K — Risk surface

### K.1 — Risk: PM-CHAT.md bullet sprawl

**Risk:** Adding 5+ bullets to PM-CHAT.md `## Behavioral rules` (currently
~15 bullets) grows the section to ~20 bullets. Each bullet is 6-12 lines;
section length grows by ~30-60 lines.

**Mitigation:**

- Theme-clustering per §H.2 keeps related bullets adjacent (reduces
  cognitive load when scanning).
- Cross-references to METHODOLOGY.md / trinity reduce redundancy.
- PM-CHAT.md is already large (786 lines); +30-60 lines is ~5-8% growth.
  No structural restructure needed.

**Residual risk:** Moderate. If a future batch adds another 10 PM-CHAT.md
bullets, sub-sectioning becomes warranted. Out of scope for Batch 19c.

### K.2 — Risk: Trinity-rule violation if OT-7 STRENGTHEN is uneven across CLAUDE/AGENTS/GEMINI

**Risk:** The STRENGTHEN of "PM chat does not architect" bullet is applied
to 3 files. Asymmetric application would violate trinity rule.

**Mitigation:**

- Pack-coder prompt MUST list all 3 files in scope.
- Pack-coder PREFLIGHT line must confirm all 3 file-edits complete.
- End-of-batch reviewer verifies trinity invariant (validate-pack CI check).
- Pack-coder PREFLIGHT pattern (per pack-repo trinity `### Agent invocation
  rules` "Pack-coder PREFLIGHT + STOP-MEANS-STOP pattern") is the safety
  net.

**Residual risk:** Low.

### K.3 — Risk: OT-10 (DEFER-PENDING-RESEARCH) becomes scope creep

**Risk:** OT-10 sub-items wait for §G.2 research. If research outcome is
"NEW PROMOTE-PM-CHAT bullets needed," Batch 19c grows by 0-2 more bullets.

**Mitigation:**

- Per `feedback_deferral_is_scope_creep`, deferral is scope creep — but the
  defer here is research-gated, not punting. Research lands within this
  batch; if it surfaces work, the work also lands within this batch.
- Architect addendum/V2 covers the research outcome before planner spawns.
- User reviews V2 / addendum and explicitly approves the additional bullets
  before planner sequences them.

**Residual risk:** Low. The defer is bounded by research duration (small)
and user-approval gate.

### K.4 — Risk: D-5 / D-7 user decisions diverge from architect recommendations

**Risk:** Architect recommends specific dispositions for D-5, D-7, etc.
User may direct differently at the architect-review gate, which changes
the per-item disposition table (§B / §C) and the planner-rough-draft (§H).

**Mitigation:**

- Architect-review gate is exactly the place to surface these divergences.
- V2 / addendum produces revised disposition table if user direction
  materially changes the design.
- Planner consumes the user-approved V2 / addendum, not this first-pass
  doc.

**Residual risk:** Low. Architect-review gate is the cheap-redirect window.

### K.5 — Risk: STATUS.md disclaimer in client-side STATUS.md (cross-check)

**Risk:** PM-CHAT.md already has "STATUS.md never-source-of-truth disclaimer"
bullet. OT learning does not surface a contradiction, but verify the
existing bullet's wording is consistent with the post-Batch-19b pack-side
STATUS.md disclaimer canonical wording (per Batch 19b §L.2 L8.1 — Pack-Chat
action item to pick canonical wording).

**Mitigation:**

- Out of scope for Batch 19c (pack-side L8.1 lands separately per Batch 19b
  pending items).
- If post-Batch-19b STATUS.md canonical wording IS picked before Batch 19c
  ships, verify project-side PM-CHAT.md STATUS.md disclaimer matches.

**Residual risk:** Low (governance, not code).

### K.6 — Risk that does NOT exist (explicit no-risk items)

- **Memory cache drift:** No project-side memory cache template ships per
  D-1; no drift surface exists.
- **Per-CLI parity drift:** Trinity rule enforced via validate-pack CI;
  any drift surfaces immediately.
- **Skill / agent maintenance disruption:** Batch 19c edits no skills, no
  agent definitions (per §E); skill/agent maintenance contract unchanged.


---

## §L — Success-criteria self-check

Per task constraints, this first-pass architect doc is evaluated against
the success criteria stated in the architect prompt.

1. **OT memory file fully read and categorized.** YES — §A.1 inventory
   table lists all 10 OT items (with 1 additional broken out as OT-11);
   §A.2 categorization summary names each item's bucket. No "skim" — every
   rule is dispositioned.

2. **Per-item disposition table covers EVERY consolidation candidate.** YES
   — §B per-item triage covers OT-1 through OT-11. §C placement table is
   the planner-ready summary. No "TBD" or "may consider" — each item is
   either IN (with target/transformation) or OUT (with rationale). OT-10
   is DEFER-PENDING-RESEARCH, which is a tracked outcome (research need
   in §G.2) — not an unresolved TBD.

3. **Open questions are specific.** YES — D-1 through D-11 in §F each
   name options with architect recommendations. Not "consider X" but
   "(a) accept §D recommendation / (b) ship template / (c) different
   structure" with rationale.

4. **Placement decisions name exact files + sections.** YES — §C placement
   table names per-item file path + insertion anchor. Not "in PM-CHAT.md"
   but "in PM-CHAT.md `## Behavioral rules` after the existing 'Fix cycle
   rules' bullet."

5. **Research-need flags name what specifically needs verification.** YES
   — §G.1 / §G.2 / §G.3 each name the file, the question, the
   researcher source, the expected output. Not "may need research" but
   "verify METHODOLOGY.md Workflow 4 step 3 enumerates trigger conditions
   A and B; researcher reads supporting-docs/METHODOLOGY.md and reports
   Y/N + file:section anchor."

6. **Commit sequencing rough draft has realistic granularity.** YES —
   §H.1 names 3 default commits (4 conditional) with per-commit scope,
   per-commit verification, per-commit deliverable. Not "one commit" or
   "many tiny commits"; matches Batch 19b precedent for cleanup batches.

7. **Out-of-scope items are explicit.** YES — §E enumerates 14 categories
   of out-of-scope items. OT-specific rules (OT-9) named by item with
   "belongs in OT project, not project-template/" rationale. OT-session-
   scoped (OT-8), pack-side (OT-11), and the absent items (per-CLI
   memory cache, per-agent file rewrites, METHODOLOGY.md edits, etc.).

8. **Doc is well-structured.** YES — sections §1 (summary), §A (OT
   inventory), §B (per-item triage), §C (placement), §D (memory cache
   architecture decision), §E (out-of-scope), §F (open questions D-1..D-11),
   §G (research needs), §H (commit sequencing rough draft), §I (summary
   table), §J (parity check with Batch 19b), §K (risk surface), §L (this
   self-check).

**All eight success criteria met.**

---

## §M — Architect-review gate: what user needs to do

Per Pack-Chat operating rules (`feedback_planner_user_review_before_coder`
analog at architect stage), this architect doc requires user review at the
architect-review gate before any downstream pipeline (research, V2 /
addendum, planner) spawns.

**User actions at this gate:**

1. **Read §1 summary** and §A categorization to confirm OT items are
   correctly inventoried.
2. **Read §B per-item disposition** and surface any disagreement with the
   PROMOTE / STRENGTHEN / OUT-OF-SCOPE classification.
3. **Resolve §F open questions** D-1 through D-11. Architect recommendations
   are provided for each; user may accept or direct otherwise.
4. **Approve §G research needs.** If user wants to skip research and
   proceed with conservative defaults, surface D-9 alternative.
5. **Confirm §H commit sequencing.** Architect proposes 3 default commits;
   user may direct different granularity.
6. **Confirm scope per §E.** If user wants any out-of-scope item brought
   in, surface and revise (e.g., D-6 if user wants client-side Agent Teams
   bullet).

**Pack Chat actions after user gate clears:**

- If material changes: spawn second architect pass (V2). Architect
  recommendation: same-architect-vs-fresh-architect decision is per-case
  per `feedback_researcher_architect_planner_pipeline`. Default: fresh
  architect for V2 if user direction substantially diverges; same
  architect for addendum if direction is incremental.
- If §G research needed: spawn pack-docs-researcher BEFORE V2 / addendum.
- If no material changes: proceed to V2 or directly to planner. Per
  `feedback_researcher_architect_planner_pipeline`, planner consumes the
  user-approved architect output (V2 or first-pass + addendum) as its
  primary input.

**Pack Chat must NOT:**

- Spawn planner without user gate clear.
- Skip §G research without explicit user direction (per architect
  recommendation D-9(a)).
- Open any new BD without user-discussion-and-approval (per OQ-1).

---

## §N — Final notes

### N.1 — What this doc does NOT do

- Does NOT propose pack-side edits beyond explicit cross-references (per
  §E pack-side OUT-OF-SCOPE).
- Does NOT propose new BDs (per OQ-1; any new-BD candidates surface as
  user-discussion items at architect-review gate, not as architect
  recommendations).
- Does NOT prescribe exact wording for the V2 / addendum (those are
  produced after user gate per §M).
- Does NOT make the per-bullet ordering binding (planner refines per
  §H.2 architect recommendation; user may direct).

### N.2 — How this differs from Batch 19b in approach

Batch 19b consolidated 40 cleanup inputs accumulated over multiple sessions
of pack-development work, plus 29 memory cache entries. Substantial scope.
Batch 19c consolidates ~10 OT items (1 user-supplied input file with
2 sections). Smaller scope, smaller blast radius.

Consequences:
- Batch 19c needs no Tier 1.5 memory cache design (D-1) because there's
  no historical memory cache to consolidate.
- Batch 19c has no "challenge first architect" structure — there's no
  first architect; I AM the first architect. (V2 would be a fresh
  architect if user direction diverges materially.)
- Batch 19c trinity growth is modest (3→4 bullets) vs Batch 19b's
  substantial growth (~14→~35 bullets).
- Batch 19c commits are fewer (3 default) vs Batch 19b's 7.

### N.3 — Forward-pointing notes

- **Future BD candidate (post-v11.0 or v11.1):** Per OQ-3 (user's
  2026-05-16 framing — see Batch 19b §A.8), a future batch may decide
  which pack-side rules cross-apply to project-side. Examples that
  COULD propagate: `feedback_deferral_is_scope_creep`,
  `feedback_no_destructive_without_approval`, "L9 architect-doc-vs-
  reality reconciliation pattern", "Pack-coder PREFLIGHT" (for client-
  side coder agents). NOT for Batch 19c; flagged for awareness.

- **Future BD candidate:** Client-side STATUS.md disclaimer canonical
  wording — should match the pack-side L8.1 outcome per Batch 19b
  pending §L.2. Tracked as governance item, not Batch 19c work.

- **Future BD candidate:** Per D-6, if Agent Teams becomes routine in
  client-project context, add `### Sub-agent behavior (Claude-only)`
  sub-section to project trinity per Batch 19b precedent.

- **Future BD candidate:** Per K.1, if PM-CHAT.md `## Behavioral rules`
  grows past ~25 bullets in future batches, sub-section the content.

These are not Batch 19c deliverables. They exist to surface awareness so
future architect / planner work doesn't re-derive them from scratch.

---

**End of architect doc — ARCHITECTURE-CLEANUP-BATCH-19C.md**

**Awaiting user review at architect-review gate per §M.**
