# ARCHITECTURE-CLEANUP-BATCH-19C — Project-side cleanup (V1, first-pass architect)

**Author:** pack-architect (first pass; V1 — supersedes a prior V0 attempt
that was DISCARDED per user direction without being read here).
**Date:** 2026-05-17
**Branch:** v11-dev (HEAD `3d8cc8b`; post-Batch-19b close).
**Ship target:** v11.0 (unlaunched).
**Scope:** PROJECT-SIDE pack surface — `project-template/` (CLAUDE.md /
AGENTS.md / GEMINI.md, `.claude/.codex/.gemini/agents/`,
`skills/`, `docs/pack/`) plus the slice of `supporting-docs/` that
ships to clients via `init-project.sh` (METHODOLOGY.md). Pack-self
surface (PACK-CHAT.md, PACK-AGENTS.md, pack-root trinity,
`scripts/`, `maintenance-docs/`) is OUT of scope; Batch 19b covered
those.
**Status:** V1 draft for user review. After user review, Pack Chat
will spawn `pack-docs-researcher` (scope informed by §G), then a
SECOND fresh architect will produce V2 (reading V1 + the research
output). This V1 must surface every open question and research need
so V2 can converge.

---

## §A — Preamble, scope, and OT-input summary

### A.1 — Why this batch exists

Batch 19b consolidated PACK-SIDE rules (Pack Chat operating rules,
pack-self memory cache, pack-self trinity Pack-memory section).
Batch 19c is the PROJECT-SIDE analog: same kind of consolidation
pass, but targeting the rules a CLIENT PROJECT TEAM uses when
operating the pack against their codebase.

The empirical input is the OT (OptiquityTrader) project — the only
fully-running v10 client of the pack. OT's PM chat accumulated a
small but high-signal set of standing rules captured as Claude
memory entries (both "tracked" — written to
`~/.claude/projects/<OT-slug>/memory/` — and "untracked" — described
in chat but never persisted). Each captured rule represents a
real-world failure mode the OT PM chat hit, surfaced, and codified.

The OT memory dump is the only OT-side input the user has provided;
the user has confirmed no additional OT files will be supplied.

### A.2 — Critical distinction from Batch 19b

| Axis | Batch 19b (pack-side) | Batch 19c (project-side) |
|---|---|---|
| Surface | PACK-CHAT.md / PACK-AGENTS.md / pack-root trinity / pack memory cache | project-template trinity / project-template `docs/pack/PM-CHAT.md` / supporting-docs/METHODOLOGY.md / project-side prompts |
| Actor | Pack Chat (developer of the pack itself) | PM Chat (PM of a downstream coding project) |
| Agent roster | `pack-architect / pack-planner / pack-coder / pack-reviewer / pack-docs-researcher` (5) | `architect / planner / coder / reviewer / tester / docs-researcher / auditor (×7 variants) / grpc-schema / repo-ops` (16) |
| Backlog | pack-root `BACKLOG.md` + `/backlog/` per-entry tree | project `docs/project/BACKLOG.md` + `docs/project/backlog/` per-entry tree |
| Claude memory cache | `~/.claude/projects/<pack-slug>/memory/` | `~/.claude/projects/<project-slug>/memory/` (per project) |
| Codex memory cache | None (opt-in, opaque, regionally restricted per Batch 19b research) | None |
| Gemini memory cache | None (memory IS the GEMINI.md hierarchy) | None |

The Tier 1 (trinity) and Tier 1.5 (Claude-only pointer index) design
from Batch 19b §D applies symmetrically here — but the universe of
client projects is heterogeneous, and we cannot assume every client
runs Claude. Project-side rules must be authoritative at the trinity
layer (or in METHODOLOGY.md / PM-CHAT.md, which all three CLIs read);
any per-project Claude memory entries are local-only convenience
pointers, not source of truth.

### A.3 — OT memory dump inventory (full count = 17 items)

Reading the OT dump end-to-end (`/Users/david/Developer/__external-
docs/optiquity-ai-agent-config-pack/OT Project Untracked and Tracked
Memories.txt`):

**Untracked memories (UNTRACKED — described mid-session, not yet
persisted) — 10 items:**

| ID | Title | Source line |
|---|---|---|
| UT-1 | Agent team lifecycle (CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1) — keep open within stage, SendMessage for follow-ups, close at commit | 7–9 |
| UT-2 | Pack repo is read-only from OT working tree | 12–13 |
| UT-3 | Leave working tree modified when told; do not commit between passes mid-multi-pass | 14–15 |
| UT-4 | Only OPEN TDs are in scope for v11 conversion (no reopen closed/deprecated) | 18–19 |
| UT-5 | Phase 58b (conversion phase) is deferred until v11 lands | 20–21 |
| UT-6 | User reads new architecture docs before next steps proceed; pause after architect output | 24–25 |
| UT-7 | Feature prioritization conversation is deferred until after v11 | 26–27 |
| UT-8 | Cadence checkpoints + concurrency strategy are open questions — flag, don't decide | 28–29 |
| UT-9 | Re-read agent prompts each time AND verify REPORT FILE header is present in generated prompt | 32–34 |
| UT-10 | /tmp reports are ephemeral — no revert needed, safe to share externally | 35–36 |

**Tracked memories (TRACKED — persisted in OT Claude memory) —
7 items:**

| ID | Title | Source line |
|---|---|---|
| T-1 | ALWAYS run reviewer after every coder report — no exceptions (only user can bypass, unprompted) | 49, 51–78 |
| T-2 | Architect trigger check after every reviewer report (Trigger A & B, surface even mechanical-looking trigger hits) | 43, 80–93 |
| T-3 | Check BACKLOG between phases for unblocked items (PM-chat-owned proactive surfacing) | 46, 95–108 |
| T-4 | Closeout approval required before writing docs (propose BACKLOG/CHANGELOG/STATUS content first, get approval, then write) | 44, 110–124 |
| T-5 | Never commit without explicit user approval (no chained `git add` after edits) | 47, 126–139 |
| T-6 | PM chat must NEVER modify Swift source files (no Edit on .swift; no `git checkout --` on coder-touched files) | 48, 141–154 |
| T-7 | Always re-read the agent prompt file before generating any agent prompt (every time, even if familiar) | 45, 156–171 |

**Total: 17 items.** Every one will be categorized in §B; OT-IDs in
§B use the format `OT-UT-<n>` and `OT-T-<n>` for traceability.

### A.4 — Categorization vocabulary

Each item is categorized as exactly one of:

- **ALREADY-COVERED.** The rule is already present in pack source
  (`project-template/`, `supporting-docs/METHODOLOGY.md`, agent
  files, or skills) — no edit required. Cite the pack-source
  location.
- **GENERALIZABLE-PROMOTE.** The rule is universal to ANY client
  project using the pack. Promote to a specific pack-source target
  with a specific edit type: STRENGTHEN existing wording / NEW
  bullet inside an existing section / NEW section.
- **OT-SPECIFIC-OOS.** The rule references OT's domain, OT's team
  practices, OT's external systems, or OT's specific phase plan —
  stays in OT, not promoted.
- **GAP-FILL.** The rule names a gap that the pack should fill but
  the OT wording isn't directly portable — propose pack-side
  content addition from scratch.
- **NEEDS-RESEARCH.** Cannot disposition without external
  verification; flag in §G research needs.


---

## §B — Per-item disposition table

The table below carries every OT-item. The detailed BEFORE/AFTER
text for each GENERALIZABLE-PROMOTE and GAP-FILL item lives in §C
(placement decisions). Items marked OT-SPECIFIC-OOS or
ALREADY-COVERED carry their full rationale in this section because
they need no §C entry.

### B.1 — Tracked memories (T-1 through T-7)

#### OT-T-1 — ALWAYS run reviewer after every coder report

**Source citation:** OT dump lines 49, 51–78 (full memory body).
**Rule essence:** After every coder report, the next action is to
generate a reviewer prompt. Never skip, never propose skipping.
Only the user, unprompted, may bypass. Listed trigger conditions
where violation is most likely: "it's just a comment fix," "tests
pass," "coder confirmed," "want to move past my mistake," "reviewer
already approved larger pass," "trivial/small/obvious."

**Categorization:** GENERALIZABLE-PROMOTE.

**Why generalizable:** This is the exact pack-side rule
"Pack Chat does NO fixes" / "One review/fix cycle per batch" but
projected onto the PROJECT-SIDE coder/reviewer cycle. Every client
project running the standard `coder → reviewer` workflow will hit
the same anti-patterns the OT PM chat listed. The rule is universal
across project types (Apple, Python, monorepo) and across CLIs.

**Pack-source state:** Partially covered. METHODOLOGY.md Workflow 2
(line 398–410) shows the cycle but does not state the "never skip"
rule with the named trigger conditions. PM-CHAT.md §Behavioral
rules (line 201–202) says "Follow Workflow 4" but Workflow 4
assumes the coder → reviewer cycle already ran. There is no
explicit "after every coder report, generate reviewer prompt — no
exceptions" rule in METHODOLOGY.md or PM-CHAT.md.

**Target (see §C.1 for detailed text):** PM-CHAT.md
`## Behavioral rules` (NEW bullet) + METHODOLOGY.md Part 5
Workflow 2 (STRENGTHEN with a "Cycle invariant" callout).

---

#### OT-T-2 — Architect trigger check after every reviewer report

**Source citation:** OT dump lines 43, 80–93.
**Rule essence:** PM chat must check Trigger A (≥3 coder runs since
phase start or since last architect pass, reviewer still ❌/⚠️) and
Trigger B (any prior ✅ now ❌/⚠️, OR new-issue count > previous
pass) after every reviewer report. Surface the trigger check even
when the trigger is "technically met but mechanical-looking" — get
user approval before waiving.

**Categorization:** ALREADY-COVERED (METHODOLOGY.md Workflow 4
Trigger A/B + architect-pass procedure, lines 489–533).
PARTIALLY GAP-FILL on one specific extension: the
"surface-even-when-mechanical-looking" guidance.

**Pack-source state:** METHODOLOGY.md lines 489–509 define
Trigger A and Trigger B verbatim. Lines 510–533 define what PM chat
does when a trigger fires. The OT-T-2 memory body adds one
behavioral nuance not in METHODOLOGY.md: "even when the trigger is
technically met but the remaining issue is clearly mechanical (e.g.,
a missing test with no architectural ambiguity), surface the
trigger check explicitly to the user, state your assessment of
whether a true architectural problem exists, and get approval
before proceeding with or waiving the architect pass. Never
silently skip the check."

**Target (see §C.2):** METHODOLOGY.md Workflow 4 lines 489–509
(STRENGTHEN — add the "even mechanical-looking trigger hits get
surfaced" callout immediately after the Trigger B definition).

---

#### OT-T-3 — Check BACKLOG between phases for unblocked items

**Source citation:** OT dump lines 46, 95–108.
**Rule essence:** At every phase gate (after closeout, before next
phase prompt), grep BACKLOG.md for items whose blockers were
resolved by the completed phase. Report newly-unblocked items
proactively — user shouldn't have to remind. Decide fix-now vs
defer per item.

**Categorization:** ALREADY-COVERED (METHODOLOGY.md Procedure 1
Phase gate check, lines 1080–1120, especially step 2 "For every
Open item, check each Blocker" and step 3 "For every Unblocked
item: present list to user").

**Pack-source state:** Procedure 1 already mandates this scan at
every phase gate. The OT memory adds two emphases worth confirming
are present in pack source: (a) PROACTIVE surfacing (user should
not have to ask), and (b) the per-item fix-now-vs-defer decision is
the user's, not PM chat's unilateral call. Both are arguably
present in step 3 ("Wait for explicit approval before incorporating
into any phase prompt") but the proactive framing is implicit.

**Possible minor STRENGTHEN target:** METHODOLOGY.md Procedure 1
step 2 (add explicit "Report newly-unblocked items to the user
proactively — the user should not need to ask.") — see §C.3 for
proposed wording, but this is a small edit, candidate for
deferring to a one-line touch-up rather than a separate edit.

---

#### OT-T-4 — Closeout approval required before writing docs

**Source citation:** OT dump lines 44, 110–124.
**Rule essence:** Never write BACKLOG.md, CHANGELOG.md, or STATUS.md
without first presenting the proposed content and getting explicit
user approval. After every READY TO COMMIT verdict, the sequence
is: (1) check architect triggers, (2) PRESENT proposed content as
text, (3) WAIT for explicit approval, (4) only then write files,
(5) show commit message and wait for approval before committing.

**Categorization:** GENERALIZABLE-PROMOTE.

**Why generalizable:** This is the project-side analog of pack-side
"Closeout approval required" + the broader "PM chat does not
auto-write." The pack has scattered references — PM-CHAT.md says
"after explicit user approval" in some bullets, METHODOLOGY.md
Part 9 lists who-can-write-what — but there is no single bullet
codifying the CLOSEOUT SEQUENCE: trigger check → present content →
wait for approval → write → show commit message → wait for
approval → commit.

**Pack-source state:** PM-CHAT.md `## Behavioral rules` (line
203–205) says "Source file edits. You may write to BACKLOG.md,
STATUS.md, and deferral comments in source files — but only after
explicit user approval." This is necessary but not sufficient — it
covers the WRITE permission but not the closeout SEQUENCE.

**Target (see §C.4):** PM-CHAT.md `## Behavioral rules` (NEW
bullet titled "Closeout sequence: present-before-write").

---

#### OT-T-5 — Never commit without explicit user approval

**Source citation:** OT dump lines 47, 126–139.
**Rule essence:** Never run `git add`, `git commit`, or `git push`
without the user's explicit approval. Always present changes for
review first. Never chain `git add` into the same action as making
edits. The words "approve to commit" (or equivalent) must appear
AND user must respond affirmatively. Applies to small/obvious
changes too (config files, scripts, one-line fixes).

**Categorization:** ALREADY-COVERED (project-template trinity
`## Project memory` "No destructive operations without explicit
approval" + agent files' Hard rule "No state-changing git
operations, ever" + PM-CHAT.md "Source file edits ... only after
explicit user approval"). PARTIALLY GAP-FILL on the "no chained
`git add` after edits" nuance.

**Pack-source state:** The trinity files (lines 360–362 CLAUDE.md;
337–339 AGENTS.md; 350–353 GEMINI.md) require explicit approval for
any `git rm`, `rm -rf`, file deletion, overwrite, `git reset --hard`.
The agent definition files (lines 54–61 each of architect.md,
coder.md, reviewer.md, planner.md) forbid every state-changing git
verb. METHODOLOGY.md Workflow 2 step 6 says "developer commits."

The OT-T-5 nuance NOT covered: "Never chain `git add` into the
same action as making changes — always pause for review." This is
a procedural sequencing rule for the PM chat, not an agent rule.

**Target (see §C.5):** PM-CHAT.md `## Behavioral rules`
(STRENGTHEN the existing "Source file edits" bullet to add the
"never chain `git add` after an edit" sub-rule).

---

#### OT-T-6 — PM chat must NEVER modify Swift source files

**Source citation:** OT dump lines 48, 141–154.
**Rule essence:** PM chat must NEVER directly edit any .swift file
— not code, not comments within code files, not variable names,
nothing. All modifications go through the coder agent. The OT
incident: PM chat tried to "fix a comment" and ended up modifying
code logic (removing an allowlist, renaming vars, changing control
flow), then tried `git checkout --` which would have reverted the
coder's work. Both actions were destructive. PM chat's
file-editing scope: docs/, scripts/, .claude/ settings, memory.
Nothing in app source.

**Categorization:** GENERALIZABLE-PROMOTE (with one OT-specific
detail to abstract — "Swift" → "source").

**Why generalizable:** The principle "PM chat does NOT edit source
files; route all source edits through the coder agent" is universal
across project types. The OT wording specifies `.swift` because OT
is a Swift project; the generalized rule applies to `.swift`,
`.py`, `.proto`, `.c`/`.h`/`.cpp`, `.m`/`.mm`, `.kt`/`.swift`/etc.
The deferral-comment carve-out (PM chat MAY edit deferral comments
in source files for TD-TBD → TD-NNN replacement) is documented in
METHODOLOGY.md Procedure 2 step 5 and Part 9 lines 1396–1405 —
that remains the only exception.

**Pack-source state:** Partially covered. METHODOLOGY.md Part 9
"Document Authoring Rules" table (line 1384) shows "Production
source files: Coder: Yes; PM chat: Never." But this is buried in
a table, not surfaced as a behavioral rule. PM-CHAT.md
`## Behavioral rules` does NOT have a "PM chat never edits source
files (except deferral comments)" bullet — only mentions BACKLOG
/ STATUS / deferral-comment write permissions. The negative rule
("never edit source") is implicit.

The OT-T-6 nuance NOT obviously covered: "Never use `git checkout
--` on files that have coder work. That's a destructive operation."
This is a destructive-operations rule with a specific git-verb
flavor; the trinity "No destructive operations" bullet should be
strengthened to include `git checkout --` explicitly.

**Target (see §C.6):** PM-CHAT.md `## Behavioral rules` (NEW
bullet titled "PM chat never edits source files") + trinity
`## Project memory` "No destructive operations" bullet
(STRENGTHEN to add `git checkout --` to the named list).

---

#### OT-T-7 — Always re-read the agent prompt file before generating any agent prompt

**Source citation:** OT dump lines 45, 156–171.
**Rule essence:** Before generating any agent prompt (coder,
reviewer, architect, planner, tester, auditor, docs-researcher,
repo-ops, grpc-schema, or any other), re-read the full per-agent
prompt file from `docs/pack/prompts/<agent>.md`. Every single time
without exception, even if the file seems familiar. Verify the
generated prompt includes the report header line instruction
before handing it to the user.

**Categorization:** GENERALIZABLE-PROMOTE.

**Why generalizable:** This is the project-side analog of the
pack-side "Agent prompt requirements" rule (CLAUDE.md `## Pack
memory` `### Agent invocation rules` line 211–215). The pack-side
rule mandates "Every agent prompt must include: context, output
file path, read-only flags, markdown-only, problem/goal/success
criteria, chunk Write calls instruction." But there's no parallel
project-side "PM chat MUST re-read the prompt file every time"
rule.

**Pack-source state:** PM-CHAT.md `## Behavioral rules` line
188–189 says "Follow Prompt Authoring Principles. Before
generating any prompt, re-read the Prompt Authoring Principles
section of METHODOLOGY.md." This covers re-reading the
PRINCIPLES doc, NOT the per-agent prompt FILE. The OT-T-7 rule
specifically targets per-agent prompt files (`<agent>.md` under
`docs/pack/prompts/`), which are templates the PM chat customizes
per call — and they evolve as the pack ships new versions. A PM
chat that "remembers" the prompt shape misses additions like the
REPORT FILE line, new constraints, new completion-report sections.

**The "report header line" nuance:** The OT-T-7 memory adds a
verification step — "Verify the generated prompt includes the
report header line instruction before handing it to the user."
This is the OT empirical observation: the OT PM chat omitted the
report header line in two prompts during one session, and a
narrowly-scoped earlier memory ("read Templates 3 and 4 fully")
failed to prevent the second miss. The fix is requiring a fresh
read AND a verification step.

**Target (see §C.7):** PM-CHAT.md `## Behavioral rules` (NEW
bullet titled "Re-read per-agent prompt file every time" — extends
or sits beside the existing "Follow Prompt Authoring Principles"
bullet).

### B.2 — Untracked memories (UT-1 through UT-10)

#### OT-UT-1 — Agent team lifecycle (CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1)

**Source citation:** OT dump lines 7–9.
**Rule essence:** With AGENT_TEAMS=1 flag, keep docs-researcher /
architect / planner / coder / reviewer sub-agents open across a
PHASE; continue them via SendMessage. Close them once the phase is
committed. Out-of-scope work gets a fresh agent.

**Categorization:** ALREADY-COVERED (Claude-specific) +
NEEDS-RESEARCH for the project-side trinity exemption framing.

**Pack-source state:** This is identical to the pack-side rule
codified in pack-root CLAUDE.md `### Sub-agent behavior
(Claude-only)` "Agent-team stage lifecycle + per-commit
fresh-coder" bullet (lines 300–316), with the Trinity exemption
note ("Agent Teams + SendMessage are Claude-Code-specific; Codex /
Gemini have no peer-messaging equivalent — confirmed absent per
Codex issue #12462 and Gemini hub-and-spoke docs"). The pack-side
rule is in pack-root CLAUDE.md only (not in pack-root AGENTS.md
or GEMINI.md) per the Trinity exemption.

**Question:** Should the project-side trinity (`project-template/
CLAUDE.md`) carry the same `### Sub-agent behavior (Claude-only)`
sub-section with the Agent Teams rule? The use-case is symmetric
— a client project's PM chat running under Claude Code with
AGENT_TEAMS=1 has the same stage-lifecycle obligation. But:
(a) the trinity exemption framing means the rule lives in
CLAUDE.md only, breaking trinity symmetry; (b) project-side
agent definitions don't reference Agent Teams; (c) Batch 19b
research confirmed Codex/Gemini have no equivalent.

See §F D-1 — open question for V2 decision.

---

#### OT-UT-2 — Pack repo is read-only from OT working tree

**Source citation:** OT dump lines 12–13.
**Rule essence:** Pack repo is read-only from a client project's
working tree. Never modify any file under
`~/Developer/optiquity-ai-agent-config-pack/` from a client
project — read for reference only.

**Categorization:** GENERALIZABLE-PROMOTE.

**Why generalizable:** Every client project that has the pack
cloned somewhere on disk for reference (e.g., for the dev to read
METHODOLOGY.md, prompts/, supporting-docs/ as upstream) hits the
same risk — a PM chat or coder agent could "fix" something
upstream while working on the project, polluting the pack and
losing the change in the project's history.

**Pack-source state:** This is implied by PACK-FEEDBACK.md
`## How to use this doc` "Scope boundaries" (line 121: "The PM
chat does not modify the pack from within a project — the pack
repo is upstream and read-only.") The framing is feedback-loop-
specific. The general rule "pack is read-only from a project
working tree" should be at the trinity / PM-CHAT.md level, not
just inside the PACK-FEEDBACK.md operational reference.

**Target (see §C.8):** PM-CHAT.md `## Behavioral rules` (NEW
bullet titled "Pack repo is read-only from this project").

---

#### OT-UT-3 — Leave working tree modified when told (multi-pass jobs)

**Source citation:** OT dump lines 14–15.
**Rule essence:** When a multi-pass prep job (like trinity marker
work) is in flight, do not commit between passes even if it feels
like a natural checkpoint — wait for explicit "commit and push."

**Categorization:** GAP-FILL.

**Why gap-fill:** This rule is universal (any multi-pass agent
sequence in any client project) but the OT wording is too
project-specific to copy verbatim ("the trinity marker work" is an
OT-conversion-specific job). The principle is broader: a multi-
agent pipeline (architect → planner → coder → reviewer, or
researcher → architect → planner → coder → reviewer) may
deliberately leave intermediate working-tree state for the next
pass to verify against; PM chat should NOT auto-commit at
intermediate checkpoints just because tests are green.

**Pack-source state:** Not present. PM-CHAT.md's commit-discipline
rules cover the "no commit without approval" axis (OT-T-5) but do
not cover the "mid-pipeline working-tree state is intentional"
axis.

**Target (see §C.9):** PM-CHAT.md `## Behavioral rules` (NEW
bullet titled "Mid-pipeline working-tree state is intentional —
no auto-commit at checkpoints").

---

#### OT-UT-4 — Only OPEN TDs are in scope for v11 conversion

**Source citation:** OT dump lines 18–19.
**Rule essence:** During BACKLOG → GitHub Issues migration, do
not reopen closed or deprecated TDs.

**Categorization:** OT-SPECIFIC-OOS.

**Why OOS:** This is about OT's specific v11 migration pass (the
flat-file → tracker conversion). The pack-side analog is
covered by the migration scripts themselves (see
`scripts/migrate-v10-to-v11.sh` and `pack tracker init`
mechanics). The rule "don't reopen closed/deprecated TDs during
migration" is a property of the migration tooling, not a PM-chat
behavioral rule for ongoing project operation.

**Disposition:** No promotion. Migration mechanics are tested via
the migrator framework (BD-119) and exercised by BD-171
(real-OT scratch test). If gaps surface during BD-171, those are
migration-tool bugs, not PM-chat-rule gaps.

---

#### OT-UT-5 — Phase 58b deferred until v11 lands

**Source citation:** OT dump lines 20–21.
**Rule essence:** Don't start preparing conversion mappings or
partial drafts of OT's Phase 58b ahead of v11 install.

**Categorization:** OT-SPECIFIC-OOS.

**Why OOS:** OT-specific phase deferral. No pack-side analog.

---

#### OT-UT-6 — User reads new architecture docs before next steps proceed

**Source citation:** OT dump lines 24–25.
**Rule essence:** After architect output lands (e.g., TD-099/
TD-100 designs), pause for the user to read before suggesting
follow-on work.

**Categorization:** GENERALIZABLE-PROMOTE.

**Why generalizable:** This is the project-side analog of
pack-side `feedback-planner-user-review-before-coder` ("Planner
output → user review → coder spawn"). Same principle applied
ONE STEP EARLIER in the pipeline: architect output → user review
→ planner spawn (or → coder spawn for trivially-small architect
outputs).

The pack-side rule is in CLAUDE.md `### Agent invocation rules`
(line 231–237). The project-side has no equivalent. METHODOLOGY.md
Workflow 4 step 4 mentions "Present proposed doc changes — show
the user exactly what the architect proposes to change. Get
explicit approval for each change before applying it." That
covers the doc-changes-apply gate, not the broader "pause for
user to read the architect's output before advancing to next
step" gate.

**Pack-source state:** Implicit but not codified. The architect
prompt (project-template/docs/pack/prompts/architect.md) says
"The PM chat will apply approved changes after this session"
(line 14) — this presumes user approval but doesn't mandate the
read-pause.

**Target (see §C.10):** PM-CHAT.md `## Behavioral rules` (NEW
bullet titled "Architect output → user reads → next step waits")
+ METHODOLOGY.md Workflow 4 step 4 (STRENGTHEN with explicit
read-pause language).

---

#### OT-UT-7 — Feature prioritization conversation deferred until after v11

**Source citation:** OT dump lines 26–27.
**Rule essence:** Don't push for backlog prioritization decisions
before v11 lands.

**Categorization:** OT-SPECIFIC-OOS.

**Why OOS:** OT-specific scheduling. Not a pack-rule candidate.

---

#### OT-UT-8 — Cadence checkpoints + concurrency strategy are open questions

**Source citation:** OT dump lines 28–29.
**Rule essence:** Cadence checkpoints (audit/architect frequency)
and concurrency strategy (parallel agent batches) are open
questions — flag if they become relevant, don't decide unilaterally.

**Categorization:** GENERALIZABLE-PROMOTE (one half) +
OT-SPECIFIC-OOS (other half).

**The generalizable half:** "Open questions surfaced during work
should be flagged for user discussion, not unilaterally decided
by the PM chat." This is universal.

**The OT-specific half:** The specific open questions ("cadence
checkpoints" and "concurrency strategy") are OT's open questions,
not pack-wide ones. Different projects have different open
questions.

**Pack-source state:** The generalizable half is implicit in
PM-CHAT.md `## Behavioral rules` "Plan before executing" and "No
solutions in agent prompts" but is not stated as a separate
behavioral rule. The closest pack-side analog is `feedback-no-
solutions-in-agent-prompts` (CLAUDE.md line 216–219), but that
covers agent prompts, not user-facing PM chat discussion.

**Target (see §C.11):** PM-CHAT.md `## Behavioral rules` (NEW
bullet titled "Open questions surface to user, never decided
unilaterally"). The specific open questions OT mentioned are
NOT promoted — only the meta-rule.

---

#### OT-UT-9 — Re-read agent prompts each time + verify REPORT FILE header present

**Source citation:** OT dump lines 32–34.
**Rule essence:** Re-read agent prompts every time (already
captured as OT-T-7 in tracked form), PLUS verify the REPORT FILE
header is present in the generated prompt. OT user noted this
verification step "may not be captured yet" in OT's tracked
memory.

**Categorization:** Subsumed by OT-T-7 — same rule with an
extension nuance. See §C.7 for combined treatment.

---

#### OT-UT-10 — /tmp reports are ephemeral

**Source citation:** OT dump lines 35–36.
**Rule essence:** When a sub-agent writes a report to /tmp, treat
it as ephemeral — nothing to revert, safe to share externally.

**Categorization:** GAP-FILL.

**Why gap-fill:** Universal property of /tmp-written reports
across all client projects. The PM chat needs to know it's safe
to share /tmp reports externally (e.g., paste to Pack Chat for
upstream debugging) without worrying about secrets leaking from
the repo. Not OT-specific.

**Pack-source state:** Not present anywhere. PM-CHAT.md and
METHODOLOGY.md treat reports as living under `docs/project/` —
they don't address the case where the prompt writes a report to
/tmp (which docs-researcher and architect mid-phase variants do
when the developer doesn't want the report committed).

**Target (see §C.12):** METHODOLOGY.md Part 9 Document Authoring
Rules (NEW one-line addendum) + PM-CHAT.md (no change — the
audience is the agent prompt-construction discipline, not
behavioral rules).

### B.3 — Summary count

| Categorization | Count | Items |
|---|---|---|
| ALREADY-COVERED | 4 | OT-T-2 (partial), OT-T-3, OT-T-5 (partial), OT-UT-1 (with Trinity-exemption question) |
| GENERALIZABLE-PROMOTE | 7 | OT-T-1, OT-T-4, OT-T-6, OT-T-7, OT-UT-2, OT-UT-6, OT-UT-8 (meta-rule half) |
| OT-SPECIFIC-OOS | 4 | OT-UT-4, OT-UT-5, OT-UT-7, OT-UT-8 (specific-questions half) |
| GAP-FILL | 2 | OT-UT-3, OT-UT-10 |
| NEEDS-RESEARCH | 0 (all 17 categorized; research needs in §G are derived from gap-fill rationale and pack-source verification, not from "uncategorized" items) |

**Total = 17 (matches inventory in §A.3).**

Items needing §C placement: OT-T-1, OT-T-2, OT-T-3 (small), OT-T-4,
OT-T-5 (small), OT-T-6, OT-T-7, OT-UT-2, OT-UT-3, OT-UT-6, OT-UT-8
(meta), OT-UT-10. That is 12 items needing concrete placement
language, plus the trinity Trinity-exemption question (OT-UT-1) if
the user / V2 architect decides yes in §F D-1.


---

## §C — Placement decisions (BEFORE/AFTER text)

This section produces concrete edit text for every
GENERALIZABLE-PROMOTE and GAP-FILL item. Pack-coder will apply
these mechanically (with planner-refined sequencing per §H). Where
trinity files are involved, the same content applies to
`project-template/CLAUDE.md`, `project-template/AGENTS.md`, and
`project-template/GEMINI.md` per the trinity rule.

### C.1 — OT-T-1 (always-reviewer-after-coder) placement

**Target file 1:** `project-template/docs/pack/PM-CHAT.md`
**Target section:** `## Behavioral rules`
**Insertion anchor:** After the existing bullet titled
"Fix cycle rules." (line 201–202) — before "Source file edits."
**Edit type:** NEW bullet.

**Proposed text:**

```
- **Always run reviewer after every coder report — no exceptions.**
  After every coder report, the next action is to generate a
  reviewer prompt. Never propose "approve to commit" directly
  after a coder report. Never say "this is small enough to skip
  review," "the coder confirmed it's correct," "the reviewer
  already approved the larger pass," or "tests pass, so it's
  fine." All of these are the conditions under which the reviewer
  is most needed — they are the conditions under which critical
  thinking stops. The cycle is coder → reviewer → user approval →
  commit. Always. The only bypass is an unprompted user
  instruction to skip the reviewer; PM chat never requests or
  suggests skipping.
```

**Target file 2:** `supporting-docs/METHODOLOGY.md`
**Target section:** Part 5 Workflow 2 (line 398–410)
**Insertion anchor:** Immediately after the existing fenced code
block ending at line 410 (before the `> **agent-run.sh:**`
callout at line 411).
**Edit type:** NEW callout block.

**Proposed text:**

```
> **Cycle invariant — reviewer always runs.** Step 4 (reviewer)
> runs after every step-3 coder report without exception. The PM
> chat must not propose skipping the reviewer for any reason —
> "small change," "comment-only," "tests pass," "coder confirmed
> correct," or "prior reviewer already approved" are all the
> conditions under which the reviewer is most needed. The reviewer
> exists precisely to catch what "tests pass" does not:
> architecture compliance, security posture, intent alignment.
> The only bypass is an unprompted user instruction to skip;
> PM chat never suggests it.
```

**Trinity ripple:** None. This is PM-chat behavior, not
project-team behavior; trinity files (CLAUDE/AGENTS/GEMINI) do not
need a parallel bullet — the trinity `## Project memory` section
covers project-team behavior, not PM-chat orchestration. (Open
question: should it? — see §F D-2.)

### C.2 — OT-T-2 (architect trigger surface-even-mechanical) placement

**Target file:** `supporting-docs/METHODOLOGY.md`
**Target section:** Part 5 Workflow 4 → "#### Architect trigger
conditions" (line 489)
**Insertion anchor:** Immediately after the end of the "Trigger B"
paragraph at line 503 — before the "**Why this matters:**" callout
at line 504.
**Edit type:** NEW callout (STRENGTHEN existing section).

**Proposed text:**

```
> **Surface mechanical-looking trigger hits explicitly.** Even
> when the trigger is technically met but the remaining issue
> looks clearly mechanical (e.g., a missing test with no
> architectural ambiguity), the PM chat must surface the
> trigger check explicitly to the user, state its assessment of
> whether a true architectural problem exists, and get explicit
> approval before proceeding with or waiving the architect pass.
> Never silently skip the check.
```

**Trinity ripple:** None (this is METHODOLOGY.md detail; trinity
files do not duplicate METHODOLOGY content).

### C.3 — OT-T-3 (BACKLOG-between-phases proactive surfacing) placement

**Status:** OPTIONAL — small edit, low value-add since the rule
is already in Procedure 1. Defer to a one-line touch-up only if
the user / V2 architect agrees the implicit framing is
insufficient. See §F D-3 for the explicit decision point.

**Conditional target:** `supporting-docs/METHODOLOGY.md` Part 7
Procedure 1 step 2 (line 1083), STRENGTHEN.

**Conditional proposed text:** Append at the end of step 2
(after the existing "If ALL blockers resolved → set Status:
Unblocked" line):

```
   The PM chat reports newly-unblocked items to the user
   proactively at every phase gate — the user should not need
   to ask. ("TD-NNN is now unblocked by Phase N completion.")
```

### C.4 — OT-T-4 (closeout-sequence: present-before-write) placement

**Target file:** `project-template/docs/pack/PM-CHAT.md`
**Target section:** `## Behavioral rules`
**Insertion anchor:** After the existing "Source file edits."
bullet (line 203–205) — before "STATUS.md phase title links."
**Edit type:** NEW bullet.

**Proposed text:**

```
- **Closeout sequence — present, wait, then write.** After every
  reviewer pass that ends in a READY TO COMMIT verdict, the
  sequence is mandatory and ordered: (1) check architect trigger
  conditions per Workflow 4; (2) present proposed BACKLOG entry,
  CHANGELOG entry, and STATUS changes as TEXT in chat — do NOT
  write any files yet; (3) wait for explicit user approval
  ("approved," "looks good," or equivalent affirmative); (4) only
  then write the files; (5) show the commit message and wait for
  approval before committing. Skipping step 2 or step 3 (writing
  files before the user has seen and approved the content) causes
  unauthorized state changes and requires manual revert.
```

**Trinity ripple:** None (PM-chat orchestration; trinity covers
project-team rules).

### C.5 — OT-T-5 (no-chained-git-add) placement

**Target file:** `project-template/docs/pack/PM-CHAT.md`
**Target section:** `## Behavioral rules`
**Insertion anchor:** STRENGTHEN the existing "Source file edits"
bullet (line 203–205) — append after the existing text.
**Edit type:** STRENGTHEN existing bullet.

**Proposed BEFORE text (existing):**

```
- **Source file edits.** You may write to BACKLOG.md, STATUS.md, and deferral
  comments in source files — but only after explicit user approval. Never write
  to source code files for any other reason.
```

**Proposed AFTER text (replacement):**

```
- **Source file edits.** You may write to BACKLOG.md, STATUS.md, and deferral
  comments in source files — but only after explicit user approval. Never write
  to source code files for any other reason. Never chain `git add` into the
  same action as making an edit — always describe what was changed and pause
  for the user to review and approve before staging anything. This applies
  even to small/obvious changes (config files, scripts, one-line fixes); the
  user reviews each edit before it is staged. The words "approve to commit"
  (or equivalent affirmative) must appear AND the user must respond
  affirmatively before any state-changing git verb runs.
```

**Trinity ripple:** The trinity `## Project memory` "No destructive
operations without explicit approval" bullet (CLAUDE.md line
358–362, AGENTS.md line 335–339, GEMINI.md line 350–353) already
covers `git rm`, `rm -rf`, file deletion, overwrite,
`git reset --hard`. The OT-T-6 placement (§C.6 below) extends that
list with `git checkout --` on files with coder work; this is the
appropriate trinity touch-point for additions to that named list.

### C.6 — OT-T-6 (PM-chat-never-edits-source) placement

**Target file 1:** `project-template/docs/pack/PM-CHAT.md`
**Target section:** `## Behavioral rules`
**Insertion anchor:** After the "Source file edits" bullet
(post-§C.5 strengthening) — before "STATUS.md phase title links."
**Edit type:** NEW bullet.

**Proposed text:**

```
- **PM chat never edits production source files.** PM chat must
  never directly edit any production source file — not code, not
  comments within source files (other than typed deferral
  comments, per the carve-out in METHODOLOGY.md Part 7 / Part 9),
  not variable names, not formatting. All source-file edits route
  through the coder agent — including one-line typo fixes,
  comment cleanups, and apparently-trivial changes. PM chat's
  file-editing scope is: docs/ files, scripts/, .claude/.codex/
  .gemini/ settings, memory files, and deferral comments
  (TD-TBD → TD-NNN replacement or rejected-comment removal). Any
  edit outside this scope MUST be routed through a coder agent
  with an explicit scoped prompt — no exceptions for size.
```

**Target file 2:** Trinity (`project-template/CLAUDE.md`,
`project-template/AGENTS.md`, `project-template/GEMINI.md`)
**Target section:** `## Project memory`
**Insertion anchor:** STRENGTHEN the existing "No destructive
operations without explicit approval" bullet.
**Edit type:** STRENGTHEN existing bullet (extend named list of
destructive operations).

**Proposed BEFORE text (CLAUDE.md, lines 358–362; symmetric in
AGENTS/GEMINI):**

```
- **No destructive operations without explicit approval.** Before
  any `git rm`, `rm -rf`, file deletion, overwrite, or
  `git reset --hard`, state exactly what will be destroyed and wait
  for explicit approval — even when the overall task is approved.
```

**Proposed AFTER text:**

```
- **No destructive operations without explicit approval.** Before
  any `git rm`, `rm -rf`, file deletion, overwrite, `git reset
  --hard`, or `git checkout -- <path>` on a file with uncommitted
  agent work, state exactly what will be destroyed and wait for
  explicit approval — even when the overall task is approved.
  `git checkout --` is destructive because it discards
  working-tree changes irreversibly; never run it on files that
  contain coder-written changes without per-action user approval.
```

**Trinity ripple:** Apply the same wording to all three trinity
files in the same commit.

### C.7 — OT-T-7 (re-read per-agent prompt file every time + verify REPORT FILE header) placement

**Target file:** `project-template/docs/pack/PM-CHAT.md`
**Target section:** `## Behavioral rules`
**Insertion anchor:** After the existing "Follow Prompt Authoring
Principles." bullet (line 188–189) — before "Select skills using
PLATFORM-SKILLS.md."
**Edit type:** NEW bullet (extends the existing
"Prompt Authoring Principles" bullet's neighborhood).

**Proposed text:**

```
- **Re-read the per-agent prompt file before generating any agent
  prompt — every time, no exceptions.** Before generating any
  agent prompt (coder, reviewer, architect, planner, tester,
  auditor, docs-researcher, repo-ops, grpc-schema, or any custom
  x-* agent), re-read the full per-agent prompt file from
  `docs/pack/prompts/<agent>.md`. Do this every single time, even
  if the file seems familiar or was recently read. "I remember
  the format" is not a substitute — the pack ships prompt-file
  updates between pack versions (new variants, new constraints,
  new completion-report sections), and a PM chat operating from
  memory misses them. Before handing the generated prompt to the
  developer, VERIFY the prompt includes the REPORT FILE line
  (per `## Permission profiles` requirements) — agents that do
  not receive a REPORT FILE line return findings inline instead
  of writing the deliverable, breaking the file-based-reporting
  contract.
```

### C.8 — OT-UT-2 (pack-repo-is-read-only) placement

**Target file:** `project-template/docs/pack/PM-CHAT.md`
**Target section:** `## Behavioral rules`
**Insertion anchor:** After "Pack feedback loop." (line 221–227) —
before "Custom files via Procedure 5 only."
**Edit type:** NEW bullet.

**Proposed text:**

```
- **Pack repo is read-only from this project.** If a clone of the
  AI Agent Config Pack lives on this machine for reference (e.g.,
  to read METHODOLOGY.md, prompts/, supporting-docs/ as upstream
  source), the PM chat MUST NOT modify any file inside that pack
  clone from this project's session. Read for reference only.
  Pack-side issues (rule clarifications, prompt template gaps,
  documentation errors) are recorded in PACK-FEEDBACK.md per
  METHODOLOGY.md Part 10, delivered to Pack Chat at workflow
  boundaries — never patched into the upstream pack from within
  a project. This rule applies to agent sessions spawned from
  this project as well: scope all agent edits to this project's
  working tree.
```

### C.9 — OT-UT-3 (mid-pipeline working-tree state intentional) placement

**Target file:** `project-template/docs/pack/PM-CHAT.md`
**Target section:** `## Behavioral rules`
**Insertion anchor:** After "Closeout sequence — present, wait,
then write." (post-§C.4 insertion) — before "STATUS.md phase
title links."
**Edit type:** NEW bullet.

**Proposed text:**

```
- **Mid-pipeline working-tree state is intentional — no auto-
  commit at checkpoints.** When a multi-agent pipeline is in
  flight (researcher → architect → planner → coder → reviewer, or
  any multi-pass coder/reviewer sequence), the PM chat does NOT
  auto-commit at intermediate checkpoints — even when tests are
  green and the moment "feels like" a natural commit point.
  Intermediate working-tree state may be load-bearing for the
  next pass (e.g., the planner verifies the architect's
  proposed changes against the working tree; the next coder pass
  may extend the prior coder's working changes). Wait for explicit
  user direction ("commit and push," "stage and commit," or
  equivalent) before any state-changing git verb. Single-commit
  jobs proceed normally; multi-pass jobs wait.
```

### C.10 — OT-UT-6 (architect-output → user-reads → next-step-waits) placement

**Target file 1:** `project-template/docs/pack/PM-CHAT.md`
**Target section:** `## Behavioral rules`
**Insertion anchor:** After "Re-read the per-agent prompt file
..." (post-§C.7 insertion) — before "Select skills using
PLATFORM-SKILLS.md."
**Edit type:** NEW bullet.

**Proposed text:**

```
- **Architect output → user reads → next step waits.** When the
  architect agent's report lands (mid-phase architect pass per
  Workflow 4, or kickoff-time architect pass producing
  ARCHITECTURE.md content), the PM chat surfaces the report to
  the user and WAITS for the user to read it before suggesting
  any follow-on work. Do not auto-stage proposed doc changes; do
  not auto-spawn the next planner / coder pass; do not propose
  "ready to commit" until the user has signaled they have read
  the architect's output. This is the project-side analog of the
  pack-side "Planner output → user review → coder spawn" rule
  applied one step earlier in the pipeline — the architect-to-
  next-step gate is the user's last cheap window to redirect
  before downstream work consumes hours of agent time and chat
  context.
```

**Target file 2:** `supporting-docs/METHODOLOGY.md`
**Target section:** Part 5 Workflow 4 step 4 (line 522–523)
**Insertion anchor:** STRENGTHEN existing step 4 text.
**Edit type:** STRENGTHEN.

**Proposed BEFORE text (existing):**

```
4. **Present proposed doc changes** — show the user exactly what the architect proposes
   to change. Get explicit approval for each change before applying it.
```

**Proposed AFTER text:**

```
4. **Present proposed doc changes and wait for the user to read.**
   Show the user exactly what the architect proposes to change.
   The PM chat WAITS for the user to read the architect's full
   report before suggesting any follow-on step — do not auto-
   advance to the next step, do not auto-stage changes, do not
   propose "ready to commit" until the user has signaled they
   have read the report. Get explicit approval for each change
   before applying it.
```

### C.11 — OT-UT-8 (open-questions-surface-to-user, meta-rule only) placement

**Target file:** `project-template/docs/pack/PM-CHAT.md`
**Target section:** `## Behavioral rules`
**Insertion anchor:** After "Open Question status state machine"-
adjacent bullets, after the "Plan before executing." bullet (line
180–181) — early in the list since it is a high-level meta-rule.
**Edit type:** NEW bullet.

**Proposed text:**

```
- **Open questions surface to user, never decided unilaterally.**
  When the PM chat encounters a question about cadence
  (audit/architect frequency, review checkpoints), concurrency
  (parallel agent spawns vs sequential), scope (what belongs in
  this phase vs the next), or any other decision that affects
  multi-phase ordering or project rhythm, flag it explicitly to
  the user. Do NOT decide unilaterally even when the question
  feels mechanical — multi-phase decisions compound, and a
  unilateral default that "works for the next step" can lock the
  project into a path the user would have steered away from.
  Surface, wait, decide together.
```

### C.12 — OT-UT-10 (/tmp reports are ephemeral) placement

**Target file:** `supporting-docs/METHODOLOGY.md`
**Target section:** Part 9 Document Authoring Rules → "What
agents can and cannot modify" table (line 1384–1394) — add a
short paragraph immediately AFTER the existing table (line 1395
area).
**Edit type:** NEW paragraph appended after the table.

**Proposed text:**

```
> **/tmp reports are ephemeral.** When an agent prompt specifies
> a `REPORT FILE:` path under `/tmp/...` (typically used for
> docs-researcher reports, architect mid-phase reports, or any
> report the developer does not want committed to the repo),
> treat the file as ephemeral: it is safe to share externally
> (e.g., paste into Pack Chat for upstream debugging), nothing
> to revert if discarded, and never to be committed. Reports
> intended for the repo are written under `docs/project/` per
> the standard prompt templates.
```

**Trinity ripple:** None (METHODOLOGY.md scope, not trinity).


---

## §D — Architecture decisions

This section captures architectural decisions made above the per-
item placement level. Each decision has a recommendation and
alternatives. User and V2 architect can override any of these at
the V2 gate.

### D.1 — Per-project Claude memory cache for project-side

**The question:** Should the pack ship convention / tooling for a
per-project Claude memory cache under
`~/.claude/projects/<project-slug>/memory/`, mirroring the pack-
side cache established in Batch 19b?

**Background:** Batch 19b §D research established:
- Claude Code has per-project memory at
  `~/.claude/projects/<slug>/memory/` (Tier 1.5 pointer index in
  the pack-side design — pure pointer file, NO body text, NO
  contradictions possible by construction).
- Codex CLI has no equivalent (opt-in, opaque, regionally
  restricted).
- Gemini CLI has no separate per-project cache (memory IS the
  GEMINI.md hierarchy + `save_memory` to `~/.gemini/GEMINI.md`).

The OT project IS a Claude-using project (per OT's PM chat memory
dump). OT has accumulated 7 tracked memories in its Claude cache.
These are project-specific — the OT PM chat needs them; another
client project would have its own.

**Architect recommendation:** YES, the pack ships convention but
NOT auto-tooling. Specifically:

(a) Add a documentation section to PM-CHAT.md
"Tool-specific: Claude Code CLI" (around line 552) explaining:
"Claude Code projects may use per-project memory at
`~/.claude/projects/<slug>/memory/` as a convenience pointer
index to project rules — same Tier 1.5 design as the pack repo
(per pack memory pattern). Pure pointers; no body text; trinity /
PM-CHAT.md / METHODOLOGY.md remain authoritative. Codex and
Gemini have no equivalent and read rules directly from trinity /
PM-CHAT.md / METHODOLOGY.md."

(b) Do NOT ship a script that auto-creates a per-project memory
cache — that's per-developer setup discretion. The pack ships the
convention so a Claude-using project can adopt it; non-Claude
projects ignore the section.

(c) The OT memories themselves (T-1 through T-7) are NOT in scope
for promotion to a "project-template default memory set" — they
ARE the OT project's memories. The promotion happens for the rule
content (per §B / §C), not for the memory entries themselves.

**Alternatives considered:**

- **Alt-1: NO per-project Claude memory documentation.** Argument:
  Codex and Gemini projects don't have an equivalent; documenting
  Claude-only is trinity-asymmetry. Counter: the Claude-only
  documentation lives in PM-CHAT.md's "Tool-specific: Claude Code
  CLI" section — that section is already Claude-only by name and
  carries Claude-only operating notes (compaction handling,
  /pm-startup skill); adding a per-project memory note there is
  symmetric with how the section already works.
- **Alt-2: Ship auto-tooling (a `pm-init-memory` script or
  /pm-startup-side memory bootstrap).** Argument: makes adoption
  trivial. Counter: per-developer discretion. Different projects
  use Claude memory differently; one-size-fits-all is wrong.
  Better to ship the convention and let projects adopt or not.

**Status:** Recommendation only. User / V2 architect to confirm at
V2 gate. See §F D-1 for the open-question framing.

### D.2 — Trinity surface vs PM-CHAT.md surface for behavioral rules

**The question:** When a new behavioral rule applies to the PM
chat, does it go in trinity `## Project memory` (read by all
agents and the PM chat directly) or in PM-CHAT.md
`## Behavioral rules` (read only by the PM chat at startup)?

**Background:** Trinity `## Project memory` is a
section that all AGENTS read when they load CLAUDE.md / AGENTS.md
/ GEMINI.md. It's the rules-the-agents-must-respect surface. The
PM chat reads CLAUDE.md (or AGENTS.md or GEMINI.md, depending on
tool) AND PM-CHAT.md. So trinity-section rules reach the PM chat
too — but trinity is for project-team behavior (agents + PM
chat), while PM-CHAT.md is PM-chat-only orchestration.

**Architect recommendation (default rule):**

- **PM-chat orchestration rules** (workflow ordering, when to
  spawn which agent, closeout sequence, "never skip reviewer,"
  "re-read prompt files") → PM-CHAT.md `## Behavioral rules`.
  These rules describe the PM chat's process, not what agents
  must do.
- **Agent-affecting rules** (no destructive operations, trinity
  rule, agent file authority) → trinity `## Project memory`.
  These rules affect every agent invocation regardless of
  whether the PM chat is in the loop.
- **PM-chat AND agent rules** (e.g., "no edits to PM-only files")
  → trinity `## Project memory` (so agents see them) AND
  PM-CHAT.md `## Behavioral rules` (so PM chat sees them in its
  startup file). Mirror the rule across both surfaces, not
  duplicate-with-divergence.

**Applied to §B items:**

- All §C placements above go to PM-CHAT.md (they are PM-chat
  orchestration rules) EXCEPT:
  - OT-T-6 (PM-chat-never-edits-source) — has BOTH a PM-CHAT.md
    bullet AND a trinity STRENGTHEN (the destructive-operations
    list extension to add `git checkout --`). The trinity
    STRENGTHEN is justified because `git checkout --` is a
    destructive operation that ALL agents must avoid (per the
    existing trinity bullet's scope), not just the PM chat.
  - OT-T-1 (always-reviewer-after-coder) — METHODOLOGY.md
    Workflow 2 callout is added BECAUSE Workflow 2 is read by
    agents-via-references and developers-running-the-cycle, not
    just the PM chat; the PM-CHAT.md bullet handles PM-chat-only
    enforcement.

This applied rule is itself worth documenting somewhere as a
project-template architecture principle. See §F D-4.

### D.3 — Project-side audit / fix-cycle clarification

**OT PM PARTIAL flag (the OT PM clarification in the prompt
context):** "There is no single 'when to end the fix cycle'
clause. Cycle termination is implicit: reviewer PASS on all
items ends it. No explicit upper bound on passes other than the
Trigger A threshold (which forces an architect pass, not
termination)."

**Architect assessment:** The pack's current cycle-termination
shape IS "reviewer PASS = end" plus "Trigger A = forced
architect pass," and that is a deliberate design (the architect
pass either resolves the root cause OR escalates back to the user
for re-scoping). The OT PM's observation is that this is implicit
and could be misread as "infinite cycles allowed." A small
explicit clause naming the termination condition would close
this gap without changing behavior.

**Architect recommendation:** ADD a one-paragraph clarification
to METHODOLOGY.md Workflow 4 (after the fenced code block at
line 449). Wording:

```
> **Cycle termination.** The fix cycle terminates when the
> reviewer returns Verdict: Ready to commit AND no architect
> trigger fires per the Trigger A / Trigger B checks. A cycle
> that fails to terminate after 3 coder passes against the same
> phase ALWAYS triggers Trigger A and the architect pass — the
> architect either resolves the root cause (allowing the cycle
> to converge in the next coder pass) or escalates to the user
> for re-scoping. There is no infinite-cycle path; either
> reviewer-PASS terminates, or the architect pass terminates by
> re-scoping the work.
```

**Status:** Architect recommendation. User / V2 architect to
confirm at V2 gate. See §F D-5 for the explicit decision point.

### D.4 — Project-side "when to call planner mid-phase" (OT PM flagged gap)

**OT PM flag:** "There is no documented rule for 'when to call a
planner mid-phase' analogous to the architect triggers. The
planner is dispatched at phase-design time per the Agent dispatch
table; mid-phase planner involvement is undefined."

**Architect assessment:** This IS a real gap. METHODOLOGY.md
Part 3 "Planner trigger rule" (lines 236–248) covers WHEN to
INVOKE the planner at phase-design time but doesn't cover
mid-phase. The closest mid-phase mechanism is Trigger A's
architect pass, which CAN propose splitting the phase but doesn't
formally invoke a planner.

The gap matters because mid-phase planner involvement is
sometimes the right response — specifically when:
- A coder runs into a task-definition ambiguity (the task is
  under-specified — not an architecture problem but a planning
  problem).
- A phase mid-flight reveals that the task ordering was wrong
  (task B should have come before task A; not a re-design but a
  re-sequencing).
- An architect pass's output names "needs planning" as the
  follow-up but the PM chat has no procedure to invoke it.

**Architect recommendation:** ADD a "Planner trigger (mid-phase)"
sub-section to METHODOLOGY.md Workflow 4, sibling to the existing
architect trigger conditions. Three triggers:

1. **Trigger P-A — Task-definition ambiguity surfaced by coder.**
   The coder's report names a task that "could not be completed
   as specified" because the task description is ambiguous (not
   missing data, not architectural issue — task wording problem).
   PM chat surfaces the ambiguity AND a candidate planner pass to
   the user; user approves.
2. **Trigger P-B — Architect output names "planning pass needed"
   as the follow-up.** When the architect pass concludes "the
   design is sound; the task breakdown needs revision," PM chat
   invokes the planner with the architect's output as input.
3. **Trigger P-C — Task-ordering revision discovered mid-phase.**
   When coder mid-phase discovers that task B's preconditions
   require task A's output (and the original plan had them
   parallel or reversed), PM chat surfaces this AND a candidate
   planner pass to re-sequence.

For each trigger, the planner pass produces an updated
IMPLEMENTATION-PLAN.md Phase N task block; PM chat presents to
user for approval before re-running the coder.

**Status:** Architect recommendation. This is a substantive
addition. User / V2 architect to confirm at V2 gate. See §F D-6.

### D.5 — Project-side closeout-gating elevation

**OT PM flag:** "Closeout/commit gating after a clean reviewer
pass lives in `feedback_closeout_approval_required.md` memory,
not in METHODOLOGY.md."

**Architect assessment:** Promoting closeout-approval to
METHODOLOGY.md is exactly what §C.4 (OT-T-4 placement) addresses
— the new PM-CHAT.md `## Behavioral rules` "Closeout sequence —
present, wait, then write." bullet. The OT PM's framing suggests
METHODOLOGY.md is the right home; the architect's choice of
PM-CHAT.md is the more specific home (closeout is a PM-chat
orchestration step, not a methodology principle).

**Architect recommendation:** Place in PM-CHAT.md per §C.4 (no
change to that recommendation). ADDITIONALLY add a one-line
cross-reference in METHODOLOGY.md Part 7 Procedure 4 (line 1198
area) pointing at the PM-CHAT.md bullet, so a reader looking in
METHODOLOGY.md sees the pointer. Wording:

```
> **Closeout-sequence rule.** Procedure 4 step 3 ("PM chat marks
> Status: Resolved") and step 4 ("Run disposition scan") MUST
> be preceded by the closeout sequence defined in PM-CHAT.md
> `## Behavioral rules` ("Closeout sequence — present, wait,
> then write."): trigger check → present content → wait for
> approval → write → show commit message → wait for approval →
> commit. Never write closeout files before presenting their
> content and receiving approval.
```

**Status:** Architect recommendation. Combine with C.4 placement;
land both in the same commit.


---

## §E — Out of scope (with rationale per item)

This section documents what this batch explicitly does NOT touch,
with rationale. Items here SHOULD NOT be added to V2 unless the
user authorizes scope expansion.

### E.1 — Pack-side files (Batch 19b territory)

- `PACK-CHAT.md` (pack root) — Batch 19b consolidated PM-chat-side
  rules.
- `PACK-AGENTS.md` (pack root) — Batch 19b agent permission rules.
- pack-root `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` (with the
  `## Pack memory` section) — Batch 19b promoted memory entries.
- `scripts/` — script changes are out of cleanup-batch scope.
- `maintenance-docs/` — these ARE the cleanup-batch authoring
  artifacts; not pack-product surface.

**Rationale:** Per BD-173 NOT-in-scope list and the
separation-of-pack-ops-from-pack-product rule (CLAUDE.md
`## Pack memory` `### Repo conventions`).

### E.2 — OT-specific rules

- OT-UT-4 (only OPEN TDs in scope for v11 conversion) — OT
  migration-specific.
- OT-UT-5 (Phase 58b deferred until v11 lands) — OT phase plan
  specific.
- OT-UT-7 (feature prioritization deferred until after v11) —
  OT timing decision.
- OT-UT-8 (specific open questions: "cadence checkpoints,"
  "concurrency strategy") — OT's specific open list; the
  meta-rule about open-questions-surfacing IS promoted (per
  §C.11).

**Rationale:** These rules reference OT's domain, OT's team
practices, or OT's specific external systems. They stay in OT's
own files. The generalizable abstractions ARE promoted (e.g.,
the open-questions meta-rule per §C.11).

### E.3 — Test fixtures, CI workflows, GH MCP integration

- `test-fixtures/` — no change in this batch.
- `.github/workflows/` — no change in this batch.
- GitHub MCP server setup (`.mcp.json.example`) — no change in
  this batch.

**Rationale:** Per BD-173 NOT-in-scope list.

### E.4 — Skills and agent definitions content (frontmatter only)

The agent definition files (`project-template/.claude/agents/
<name>.md`, `.codex/agents/<name>.toml`, `.gemini/agents/<name>.md`)
were read for shape and frontmatter only. NO content changes are
proposed to these files in this batch — every per-item placement
in §C targets PM-CHAT.md or METHODOLOGY.md or the trinity
`## Project memory` section.

**Rationale:** The agent files are stable, well-tested,
codified-per-agent-role. Changes there are mechanical-edit
sized only if they propagate from a trinity rule change (e.g.,
the trinity `git checkout --` extension in §C.6 does NOT
require an agent-file update — the agent files already say
"git checkout (except git checkout -- <path> for read-only
inspection)" which is consistent with the trinity STRENGTHEN).
If V2 architect identifies an agent-file change as required for
a §C edit to land coherently, surface it as a V2 open question.

### E.5 — Project-template trinity NEW sub-sections

This batch does NOT propose new H3 sub-sections under
`## Project memory` in the project-template trinity (CLAUDE/
AGENTS/GEMINI). All trinity edits in §C are STRENGTHEN to existing
bullets, NOT structural additions.

**Rationale:** Trinity-section structural additions trigger the
Signal 9 / mechanical-edit-threshold review per
`maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-
MAINTAINABILITY.md` §3.2. Avoiding structural additions in this
batch keeps the batch at mechanical-edit scope and avoids re-
triggering the architect-pass-for-rules protocol mid-batch. If
the OT empirical inputs reveal a structural gap (a new H3 sub-
section is required), surface as a V2 architectural escalation.

### E.6 — Project-side prompt files (architect.md / coder.md / reviewer.md / planner.md / etc.)

This batch does NOT propose content changes to
`project-template/docs/pack/prompts/<agent>.md` files. All §C
edits land in PM-CHAT.md, METHODOLOGY.md, or trinity.

**Rationale:** The prompt files are read fresh by the PM chat
every time it generates a prompt (per OT-T-7 / §C.7). The rules
that govern HOW the PM chat customizes those prompts live in
PM-CHAT.md and METHODOLOGY.md `## Prompt Authoring Principles`
section. The prompt files themselves are templates, not rule
surfaces. If a §C edit reveals that a prompt template needs an
adjustment (e.g., a new required section in coder.md), surface
as a V2 open question.


---

## §F — Open questions (D-1 .. D-N)

These questions need user resolution before V2 finalizes. Each
carries an architect recommendation + alternatives with rationale.
V2 architect reads V1 + pack-docs-researcher output + user
resolutions and produces the final design.

### D-1 — Should the project-template trinity carry the Claude-only Agent Teams stage-lifecycle rule?

**Question:** OT-UT-1 captures the Claude-Code-specific
AGENT_TEAMS=1 stage-lifecycle rule. The pack-side trinity
(pack-root CLAUDE.md) carries it under `### Sub-agent behavior
(Claude-only)` with a Trinity exemption note. Should the
PROJECT-SIDE trinity (`project-template/CLAUDE.md`) carry the same
sub-section?

**Architect recommendation:** NO. The project-side trinity
`## Project memory` does not currently have a `### Sub-agent
behavior (Claude-only)` sub-section, and adding one would be a
structural change (new H3) that triggers the maintainability-
principle architect pass per §E.5. The OT empirical evidence
(one tracked memory; no incident report) is not strong enough
justification for a structural addition. The Claude-specific
operating notes that ARE codified in project-template trinity
are minimal (see GEMINI.md lines 432–441 "Gemini CLI operating
notes" — these are mechanical operating notes, not rules).

If the user / V2 architect decides yes, the sub-section would
mirror pack-root CLAUDE.md's `### Sub-agent behavior
(Claude-only)` with two bullets: (a) "Spawn all sub-agents with
no worktree isolation" (already pack-side; project-side
equivalent would be different — needs research, see G-1); (b)
"Agent-team stage lifecycle" (the OT-UT-1 content).

**Alternatives:**

- **Alt-1 (architect recommendation): NO new sub-section.** Don't
  promote OT-UT-1 to trinity. The rule lives in the developer's
  Claude session as a runtime convention; if a Claude-using
  project needs it codified, the project can add a per-project
  Claude memory entry per §D.1.
- **Alt-2: YES, add the sub-section to project-template
  CLAUDE.md only (Trinity exemption).** Mirrors pack-side
  structurally. Costs: trinity asymmetry (CLAUDE-only
  sub-section); structural addition triggering maintainability
  signal; requires per-project decision on whether AGENT_TEAMS=1
  is enabled (most projects today, no).
- **Alt-3: YES, but as a SHORT bullet in METHODOLOGY.md (not
  trinity).** Reduces trinity bloat; same content reach. Costs:
  METHODOLOGY.md is project-team-facing, not Claude-CLI-internal
  — the rule is operationally Claude-internal, not project-team
  guidance.

**Decision needed at:** V2 gate (user discussion).

### D-2 — Should the trinity `## Project memory` carry the always-reviewer-after-coder rule (§C.1) or only PM-CHAT.md?

**Question:** §C.1 places the OT-T-1 rule in PM-CHAT.md (PM-chat
orchestration) and METHODOLOGY.md Workflow 2 (cycle invariant
callout). Should it also appear in trinity `## Project memory`?

**Architect recommendation:** NO. Trinity `## Project memory` is
the rules-agents-must-respect surface. The
always-reviewer-after-coder rule is a PM-chat orchestration rule
— agents don't "skip the reviewer"; the PM chat does (by failing
to spawn one). Putting it in trinity would over-broaden the
audience.

**Alternatives:**

- **Alt-1 (architect recommendation): NO trinity placement.**
  Keep in PM-CHAT.md + METHODOLOGY.md.
- **Alt-2: ADD a trinity bullet** with the same wording. Reach:
  every agent loads the trinity, so every agent's context window
  includes the rule. Cost: trinity bloat; rule audience widens
  unnecessarily.

**Decision needed at:** V2 gate.

### D-3 — Should §C.3 (OT-T-3 BACKLOG-between-phases proactive surfacing) land at all?

**Question:** §C.3 is an OPTIONAL small STRENGTHEN. The rule is
already in METHODOLOGY.md Procedure 1 step 2; the STRENGTHEN adds
the explicit "report proactively — user should not need to ask"
framing. Is this worth one paragraph of churn?

**Architect recommendation:** YES, land §C.3. The "user should
not need to ask" framing is a behavioral nuance worth surfacing
explicitly even though the procedural step is present. Cost is
one paragraph; benefit is the OT-empirically-observed
proactive-surfacing failure mode is prevented.

**Alternatives:**

- **Alt-1 (architect recommendation): LAND §C.3.** Minimal cost,
  measurable benefit.
- **Alt-2: SKIP §C.3.** Rely on the existing Procedure 1 step 2
  wording. Risk: PM chat reads step 2 and interprets it as "if
  user asks about newly-unblocked items, report them" — the
  reactive framing the OT memory was fixing.

**Decision needed at:** V2 gate (recommend LAND).

### D-4 — Should the trinity-vs-PM-CHAT.md placement rule from §D.2 be codified as a project-template architecture principle?

**Question:** §D.2 articulates a placement rule: PM-chat
orchestration → PM-CHAT.md; agent-affecting → trinity;
both-audiences → mirror across both. Should this principle be
documented somewhere in the project-template?

**Architect recommendation:** YES — but in METHODOLOGY.md Part 9
Document Authoring Rules (not trinity, not PM-CHAT.md). The
appropriate home is METHODOLOGY.md because the rule is about
where documentation rules LIVE — it is a meta-rule about doc
architecture.

Proposed placement: METHODOLOGY.md Part 9 → NEW sub-section
"Rule placement: trinity vs PM-CHAT.md vs METHODOLOGY.md" after
the existing "Desktop Commander scope for PM chat" sub-section
(around line 1395).

Proposed wording:

```
### Rule placement: trinity vs PM-CHAT.md vs METHODOLOGY.md

New rules added during pack maintenance fall into one of three
categories based on audience:

- **PM-chat orchestration rules** (workflow ordering, when to
  spawn which agent, closeout sequence, prompt-generation
  discipline) → `docs/pack/PM-CHAT.md` § Behavioral rules. These
  describe the PM chat's process, not what agents must do.
- **Agent-affecting rules** (no destructive operations, trinity
  rule, agent file authority, file scope) → trinity `CLAUDE.md`
  / `AGENTS.md` / `GEMINI.md` § Project memory. These rules
  affect every agent invocation regardless of whether the PM
  chat is in the loop.
- **Both-audience rules** (rules where agents AND the PM chat
  both need to see the rule) → mirror across both surfaces with
  IDENTICAL wording. Never duplicate-with-divergence.

This placement rule guides cleanup batches and pack-version
upgrades; it does not retroactively renumber existing rules.
```

**Alternatives:**

- **Alt-1 (architect recommendation): LAND in METHODOLOGY.md
  Part 9.** Meta-rule about doc architecture; correct home.
- **Alt-2: SKIP — leave the principle implicit.** Risk: future
  cleanup batches will need to re-derive the rule.

**Decision needed at:** V2 gate (recommend LAND).

### D-5 — Should §D.3 (cycle-termination clarification) land?

**Question:** §D.3 proposes a one-paragraph clarification to
METHODOLOGY.md Workflow 4 explicitly stating "Cycle termination:
reviewer-PASS or architect-pass-re-scope; no infinite-cycle path."
Worth one paragraph?

**Architect recommendation:** YES. Closes a small but real gap
(OT PM explicitly flagged it). One paragraph; high clarity gain.

**Alternatives:**

- **Alt-1 (architect recommendation): LAND.**
- **Alt-2: SKIP — cycle termination is implicit and the existing
  Trigger A mechanism handles edge cases.** Risk: implicit
  rules get reinterpreted.

**Decision needed at:** V2 gate (recommend LAND).

### D-6 — Should §D.4 (mid-phase planner triggers P-A/P-B/P-C) land?

**Question:** §D.4 proposes adding "Planner trigger (mid-phase)"
with three triggers (task-definition ambiguity from coder,
architect output names "planning pass needed," task-ordering
revision discovered mid-phase). This is a SUBSTANTIVE addition
to METHODOLOGY.md Workflow 4 — closes the OT-PM-flagged gap but
adds new procedural surface.

**Architect recommendation:** YES, but with caveats.

YES because:
- The OT PM-flagged gap is real (no documented mid-phase planner
  mechanism).
- All three triggers describe failure modes that occur in
  real-world client work (the third one — task ordering — is
  particularly common when an architect pass reveals a
  dependency the original planner missed).
- The addition is symmetric in shape to the existing architect
  triggers; readers already know how to parse "Trigger A /
  Trigger B" — adding "Trigger P-A / P-B / P-C" follows the
  established pattern.

Caveats:
- The exact trigger boundaries (when is "task-definition
  ambiguity" vs "architectural problem"?) are fuzzy. The
  proposed wording for each trigger needs the planner-vs-
  architect demarcation to be explicit.
- Without empirical evidence, "three triggers" is partly
  speculative — OT has not specifically requested mid-phase
  planner triggers, only flagged that the absence is a gap.

**Alternatives:**

- **Alt-1 (architect recommendation): LAND §D.4 with three
  triggers and explicit planner-vs-architect demarcation.**
- **Alt-2: LAND only Trigger P-A** (task-definition ambiguity)
  for now; defer P-B and P-C to a future batch when empirical
  evidence accumulates.
- **Alt-3: SKIP — defer the entire mid-phase-planner gap to a
  later batch.** Costs: leaves the OT-PM-flagged gap open;
  v11.0 ships with the gap.

**Decision needed at:** V2 gate.

### D-7 — How prescriptive should the closeout-sequence rule (§C.4) be?

**Question:** §C.4 lays out 5 mandatory ordered steps (check
triggers → present content → wait approval → write files → show
commit message → wait approval → commit). Is this the right level
of prescription, or too much?

**Architect recommendation:** YES, this level of prescription is
right. The OT incident that motivated the rule was a SEQUENCE
failure — PM chat ran step 4 (write) before step 3 (wait
approval). Naming each step makes the sequence verifiable. Less
prescriptive wording ("get approval before writing") leaves the
SEQUENCE ambiguous.

**Alternatives:**

- **Alt-1 (architect recommendation): LAND as written.**
- **Alt-2: TRIM to "present content, wait for approval, then
  write — never reverse this order."** Risks: ambiguity about
  whether trigger check belongs in the sequence or before it.

**Decision needed at:** V2 gate.

### D-8 — Should the trinity STRENGTHEN for `git checkout --` (§C.6) ship in this batch?

**Question:** §C.6 includes a trinity STRENGTHEN extending the
named destructive-operations list with `git checkout -- <path>`
on files with uncommitted agent work. This is the only trinity
edit in §C. Should it ship in this batch (trinity edits
mid-cleanup-batch) or defer to a trinity-edit-batch?

**Architect recommendation:** YES, ship in this batch. The edit
is a STRENGTHEN (extending an existing bullet's named list), not
a new bullet or new sub-section — it remains within mechanical-
edit scope per §E.5 rationale. The trinity rule applies
symmetrically to project-template/CLAUDE.md, AGENTS.md, GEMINI.md
in the same commit.

**Alternatives:**

- **Alt-1 (architect recommendation): SHIP in this batch.**
- **Alt-2: DEFER to a separate trinity-focused commit** within
  this batch (so trinity edits are siblings, easier to review).
  This is a sequencing question (see §H commit sequencing) more
  than a content question.

**Decision needed at:** V2 gate (recommend SHIP; sequencing per
§H).

### D-9 — Should METHODOLOGY.md edits and PM-CHAT.md edits land in separate commits or the same commit?

**Question:** The §C placements split across PM-CHAT.md (7
edits) and METHODOLOGY.md (5 edits) and trinity (1 edit). §H
proposes a commit sequence. Should each target file get its own
commit, or should related edits across files land together?

**Architect recommendation:** Group by RULE, not by FILE. When a
rule has placements in both PM-CHAT.md and METHODOLOGY.md (e.g.,
§C.1 / OT-T-1 / always-reviewer; §C.10 / OT-UT-6 / architect-
output-user-reads), land them in the SAME commit. This keeps the
rule atomic in git history — a reader navigating the commit can
see both placements together. See §H for detailed sequencing.

**Alternatives:**

- **Alt-1 (architect recommendation): GROUP BY RULE.**
- **Alt-2: GROUP BY FILE** (all PM-CHAT.md edits in one commit,
  all METHODOLOGY.md edits in another, trinity in a third).
  Argument: easier to review per-file diffs. Counter: harder to
  trace a rule's full surface in git log.

**Decision needed at:** V2 gate / planner stage.

### D-10 — Does this batch need a per-commit reviewer pass or only end-of-batch reviewer?

**Question:** Per Pack Chat operating rules, single-BD batches
need only ONE review/fix cycle (end of batch). BD-173 is a
single-BD batch. Should each commit still run a per-commit
reviewer, or only the end-of-batch reviewer?

**Architect recommendation:** END-OF-BATCH ONLY. Per
`CLAUDE.md` `### Workflow` "One review/fix cycle per batch ...
Single-BD batches: only one cycle needed." This batch's commits
are mechanical-edit-sized text additions to ops docs — high
blast radius is unlikely, and the end-of-batch reviewer (running
on the full batch diff) will catch anything cross-cutting.

**Alternatives:**

- **Alt-1 (architect recommendation): END-OF-BATCH ONLY.**
- **Alt-2: PER-COMMIT REVIEWER on the trinity-touching commit
  (§D-8 / §C.6 / `git checkout --` extension).** The trinity
  edit is the highest-blast-radius edit in the batch; a per-
  commit reviewer would catch any unforeseen ripple before more
  commits stack on top. Cost: one extra reviewer pass.
- **Alt-3: PER-COMMIT REVIEWER on every commit.** Costs >
  benefits for a mechanical-edit batch.

**Decision needed at:** V2 gate (recommend Alt-1; user may
prefer Alt-2 for caution).


---

## §G — Research needs (G-1 .. G-N)

These research items are surfaced for the pack-docs-researcher
pass that runs between V1 and V2. Each names: the specific
question, the file(s) and section(s) to research, the expected
output format, and which §F open question's resolution depends
on the result.

### G-1 — Verify the Claude Code "worktree isolation broken from v11-dev clone" rule applies to project-side sub-agent spawns

**Question:** Pack-side memory entry
`feedback_worktree_isolation_broken_from_v11_clone` says: "Agent
isolation=worktree lands under main clone (v10.1 HEAD), not
v11-dev cwd; from v11-dev chat use no-isolation sequential
agents." This rule was established for the pack repo's
v11-dev/main split.

For a CLIENT PROJECT's sub-agent spawns (e.g., a PM chat in
Claude Code spawning an architect sub-agent via the Agent tool
on a feature branch), does the same isolation-broken issue apply?
If yes, the project-side trinity (CLAUDE.md, under a possible
new `### Sub-agent behavior (Claude-only)` sub-section per
§F D-1) would carry an analogous rule.

**Files/sections to research:**
- Claude Code documentation on Agent tool `isolation` parameter
  semantics (https://docs.claude.com/en/docs/claude-code/agents).
- GitHub issue tracker for `anthropics/claude-code` searching
  for "isolation worktree" + "branch" semantics.
- The behavior tested: from a feature branch with uncommitted
  changes, what does `isolation: "worktree"` do? Same
  `.git/worktrees/...` placement, same checkout at default
  branch?

**Expected output format:** Y/N verdict ("yes — same issue
applies to client project sub-agent spawns" / "no — client
project sub-agent spawns are unaffected"). If Y, name the
mechanism. If N, explain why it doesn't apply.

**Architect-decision dependency:** §F D-1 (whether to add the
`### Sub-agent behavior (Claude-only)` sub-section to project-
template trinity).

### G-2 — Verify Codex CLI and Gemini CLI have NO equivalent to Claude Code Agent Teams stage-lifecycle

**Question:** Batch 19b research confirmed Codex / Gemini have
no peer-messaging equivalent (Codex issue #12462; Gemini hub-
and-spoke docs). But the OT-UT-1 rule covers a broader concept
than peer-messaging: it covers SPAWNING + KEEP-ALIVE + REUSE +
CLOSE-AT-COMMIT, not just messaging.

For project-side sub-agent spawning via `./agent-run.sh codex
--agent <name>` and `gemini @<name>` invocations, what are the
equivalent (or near-equivalent) lifecycle semantics? Is there
ANY analog to "keep open across a phase, close at commit," even
without messaging?

**Files/sections to research:**
- Codex CLI agent invocation documentation (especially
  `agents.max_threads` setting, agent session lifecycle, agent
  process reuse across commands).
- Gemini CLI `@<agent-name>` invocation semantics (process
  lifecycle, multi-agent session behavior, `/chat save/resume`
  applied to agent sub-sessions).
- Pack-shipped `agent-run.sh` script — does it manage agent
  session lifecycle on Codex / Gemini, or does each invocation
  produce a fresh agent process?

**Expected output format:** Per-CLI summary table. Codex column:
"Lifecycle on agent invocation: <fresh per call / session
persists / N/A>." Gemini column: same. Naming the specific
session-control flag or command if any. If both CLIs are
"fresh per call" with no persistence concept, the §C.1 +
§C-related cross-CLI parity arguments simplify (no
keep-alive-across-phase rule needed for those CLIs).

**Architect-decision dependency:** §F D-1 (whether the rule
applies cross-CLI or stays Claude-only). Also informs whether
§C.1 (always-reviewer-after-coder) needs a Trinity exemption
note.

### G-3 — Verify the architect-trigger-surface-even-mechanical rule (§C.2 / OT-T-2) does not already exist in pack source

**Question:** §B categorization for OT-T-2 says "PARTIALLY
GAP-FILL on the surface-even-mechanical extension." Is this
extension genuinely absent from pack source, or is it implicit
in some existing rule I missed?

**Files/sections to research:**
- METHODOLOGY.md full read (Workflow 4, the "Why this matters"
  callout at line 504-508, the "What the PM chat does when a
  trigger fires" sub-section at lines 510-533).
- Project-template trinity `## Project memory` (all three files).
- PM-CHAT.md `## Behavioral rules` (specifically the "Fix cycle
  rules" bullet at line 201-202, which says "Follow Workflow 4
  in METHODOLOGY.md").
- All project-side prompt files (`prompts/<agent>.md`) for any
  reviewer / architect prompt language about trigger-surfacing.

**Expected output format:** Confirmation Y/N + cited section(s)
if Y. If N, confirms the GAP-FILL classification and §C.2 lands
as new content.

**Architect-decision dependency:** §C.2 placement (no change if
already covered; otherwise land as proposed).

### G-4 — Verify the "PM chat never edits source files" rule (§C.6 / OT-T-6) is genuinely absent from PM-CHAT.md as a behavioral rule

**Question:** §B categorization for OT-T-6 says "Not present as
a PM-CHAT.md `## Behavioral rules` bullet — only mentions
BACKLOG / STATUS / deferral-comment write permissions. The
negative rule ('never edit source') is implicit." Verify this.

**Files/sections to research:**
- PM-CHAT.md `## Behavioral rules` full read (lines 176-263).
- PM-CHAT.md `## Permission profiles` full read (lines 266-371).
- METHODOLOGY.md Part 9 "Document Authoring Rules" full read
  (lines 1382-1413) — especially the table at line 1384 and the
  Desktop Commander scope at 1396-1409.
- Project-template trinity `## Project memory` (all three files)
  for any PM-chat-source-edit prohibition.

**Expected output format:** Confirmation Y/N + cited section(s)
if Y. If N, confirms §C.6 placement as new content.

**Architect-decision dependency:** §C.6 placement.

### G-5 — Verify the "re-read per-agent prompt file every time" rule (§C.7 / OT-T-7) is genuinely absent from PM-CHAT.md

**Question:** §B categorization for OT-T-7 says PM-CHAT.md line
188-189 covers re-reading the PRINCIPLES doc (METHODOLOGY.md
Prompt Authoring Principles) but NOT the per-agent prompt
FILE. Verify this.

**Files/sections to research:**
- PM-CHAT.md `## Behavioral rules` full read.
- METHODOLOGY.md "Prompt Authoring Principles" full read
  (lines 603-886) — especially "PM chat self-check before
  generating any prompt" at lines 862-885.
- All prompt files (`prompts/<agent>.md`) for any "PM chat must
  re-read" language.

**Expected output format:** Confirmation Y/N + cited section(s)
if Y. If N, confirms §C.7 placement.

**Architect-decision dependency:** §C.7 placement.

### G-6 — Verify whether the closeout-sequence rule (§C.4 / OT-T-4) is genuinely absent from PM-CHAT.md beyond the "Source file edits" bullet

**Question:** §C.4 places a NEW "Closeout sequence — present,
wait, then write." bullet. Verify no existing PM-CHAT.md bullet
or METHODOLOGY.md Part 7 / Part 9 procedure already covers the
exact 5-step sequence (trigger check → present → wait → write
→ commit-message-approval → commit).

**Files/sections to research:**
- PM-CHAT.md `## Behavioral rules` full read.
- METHODOLOGY.md Part 7 Procedure 4 full read (line 1198-1219).
- METHODOLOGY.md Part 9 full read (line 1382-1413).
- Any pack-side analog in PACK-CHAT.md `## Behavioral rules`
  for comparison.

**Expected output format:** Confirmation Y/N + cited section(s)
if Y. If N, confirms §C.4 placement.

**Architect-decision dependency:** §C.4 placement and §D.5
elevation cross-reference.

### G-7 — Verify the mid-phase planner triggers (§D.4) have no existing pack-side codification

**Question:** §D.4 proposes Trigger P-A / P-B / P-C as a NEW
sub-section. Verify these trigger types are not codified
anywhere else (METHODOLOGY.md Planner trigger rule at lines
236-248 covers phase-design-time only; verify no mid-phase
analog elsewhere).

**Files/sections to research:**
- METHODOLOGY.md Part 3 "Planner trigger rule" (lines 236-248).
- METHODOLOGY.md Workflow 4 (lines 435-533) for any
  mid-phase-planner language.
- All prompt files (`prompts/planner.md` Variant: standard;
  `prompts/architect.md` Variant: mid-phase).
- Project-template `.claude/agents/planner.md` (read).

**Expected output format:** Confirmation Y/N + cited section(s)
if Y. If N, confirms §D.4 placement.

**Architect-decision dependency:** §F D-6.

### G-8 — Verify project-template/skills/ frontmatter does not already document any of the OT promotion candidates

**Question:** Many OT rules are about agent-loop discipline.
Skills like `planning`, `architecture-review`, `review`, and
`pm-startup` might already carry overlapping or related rules.
Verify the §C placements don't duplicate skill content.

**Files/sections to research:**
- `project-template/skills/pm-startup/SKILL.md` frontmatter +
  full SKILL body for any cycle-discipline rules.
- `project-template/skills/review/SKILL.md` for any reviewer
  invocation discipline.
- `project-template/skills/architecture-review/SKILL.md` for any
  architect-trigger discipline.
- `project-template/skills/planning/SKILL.md` for any
  planner-trigger discipline.

**Expected output format:** Per-skill summary: which §C / §D
items (if any) overlap with which skill section. If overlap
exists, the §C / §D placement may need to point AT the skill
rather than duplicating content; flag for V2 architect.

**Architect-decision dependency:** All §C placements (potential
deduplication or redirection); §D.4 (planner-trigger placement
might land in planning skill rather than METHODOLOGY.md).

### G-9 — Verify NO per-project Claude memory cache tooling already ships in the pack

**Question:** §D.1 architect recommendation says "ship convention
but NOT auto-tooling." Verify the pack does not already ship a
script or skill that auto-creates a per-project Claude memory
cache.

**Files/sections to research:**
- `scripts/init-project.sh` — any memory-cache bootstrap step?
- `scripts/add-capability.sh` — any memory-cache extension?
- `project-template/.claude/skills/pm-startup/SKILL.md` — any
  memory cache reference?
- `supporting-docs/SETUP-NEW.md` — any memory cache setup step?

**Expected output format:** Confirmation Y/N. If Y (some
tooling exists), describe what it does so §D.1 can be reframed
appropriately.

**Architect-decision dependency:** §D.1 / §F D-1.


---

## §H — Commit sequencing (rough draft for planner)

This is a rough draft. The planner pass refines this with file
dependency analysis and verification commands per commit. Per
§F D-9 (architect recommendation), grouping is BY RULE, not BY
FILE — when a rule has placements in multiple files, they land
together.

### H.0 — Pre-commit setup

- HEAD before batch: `3d8cc8b` (Batch 19b close commit).
- Branch: `v11-dev`.
- Working-tree baseline: clean (post-Batch-19b ship).
- BD-173 status: Open (to be flipped after all commits land and
  end-of-batch review is clean).

### H.1 — Commit 1: METHODOLOGY.md Workflow cycle additions

**Scope:** §C.1 (METHODOLOGY.md callout — always-reviewer) +
§C.2 (METHODOLOGY.md Trigger A/B surface-even-mechanical) +
§D.3 (cycle-termination clarification) + §C.10 (METHODOLOGY.md
Workflow 4 step 4 STRENGTHEN — architect-output user-reads).

**Files modified:**
- `supporting-docs/METHODOLOGY.md`

**Per-commit reviewer:** SKIP (per §F D-10 architect
recommendation; end-of-batch reviewer covers).

**Commit message:** `feat: v11 — BD-173 METHODOLOGY.md workflow
clarifications (Batch 19c.1)`

**Rationale for ordering as commit 1:** METHODOLOGY.md is the
PM-chat's authoritative reference; landing the clarifications
here first ensures the PM-CHAT.md bullets in commit 2 can cite
the new METHODOLOGY.md anchors.

### H.2 — Commit 2: PM-CHAT.md `## Behavioral rules` additions (PM-chat orchestration rules)

**Scope:** §C.1 PM-CHAT.md bullet (always-reviewer) +
§C.4 (closeout-sequence) + §C.7 (re-read per-agent prompt
files) + §C.8 (pack-repo-read-only) + §C.9 (mid-pipeline
working-tree intentional) + §C.10 PM-CHAT.md bullet
(architect-output user-reads) + §C.11 (open-questions surface)
+ §D.5 (METHODOLOGY.md Part 7 Procedure 4 cross-reference to
PM-CHAT.md closeout-sequence rule).

**Files modified:**
- `project-template/docs/pack/PM-CHAT.md`
- `supporting-docs/METHODOLOGY.md` (Part 7 Procedure 4
  cross-ref only — small)

**Per-commit reviewer:** SKIP.

**Commit message:** `feat: v11 — BD-173 PM-CHAT.md behavioral
rules consolidation (Batch 19c.2)`

**Rationale for ordering as commit 2:** Most additions are
PM-CHAT.md, single file dominates the diff. Includes the cross-
ref back to METHODOLOGY.md so the closeout-sequence rule has
both home + cross-reference together.

### H.3 — Commit 3: PM-CHAT.md `## Behavioral rules` STRENGTHEN (existing-bullet extensions)

**Scope:** §C.5 (STRENGTHEN "Source file edits" with
no-chained-git-add and "approve to commit" wording) +
§C.6 PM-CHAT.md bullet (PM-chat-never-edits-source).

**Files modified:**
- `project-template/docs/pack/PM-CHAT.md`

**Per-commit reviewer:** SKIP.

**Commit message:** `feat: v11 — BD-173 PM-CHAT.md source-edit
discipline (Batch 19c.3)`

**Rationale for ordering as commit 3:** Source-edit discipline
is a related cluster — the STRENGTHEN on "Source file edits"
naturally precedes the new "PM chat never edits production source
files" bullet. Splitting this commit from commit 2 keeps the
"new bullets" vs "existing bullet STRENGTHEN" diffs visually
separable for review.

### H.4 — Commit 4: Trinity STRENGTHEN — destructive-operations list extension

**Scope:** §C.6 trinity STRENGTHEN (extend "No destructive
operations" bullet with `git checkout --`).

**Files modified:**
- `project-template/CLAUDE.md`
- `project-template/AGENTS.md`
- `project-template/GEMINI.md`

**Per-commit reviewer:** Per §F D-10 Alt-2, USER MAY ELECT a
per-commit reviewer here because trinity edits carry highest
blast radius. Architect recommendation: SKIP per Alt-1 (end-of-
batch reviewer covers).

**Commit message:** `feat: v11 — BD-173 trinity destructive-ops
list extension (Batch 19c.4)`

**Rationale for ordering as commit 4:** Trinity edits land
separate from PM-CHAT.md / METHODOLOGY.md to keep the trinity-
ripple commit clean and reviewable. Per the trinity rule, all
three files in one commit.

### H.5 — Commit 5: METHODOLOGY.md substantive additions (D-4 mid-phase planner + D.2 placement rule)

**Scope:** §D.4 (NEW METHODOLOGY.md Workflow 4 sub-section
"Planner trigger (mid-phase)") + §D.2 / §F D-4 (NEW
METHODOLOGY.md Part 9 sub-section "Rule placement: trinity vs
PM-CHAT.md vs METHODOLOGY.md") + §C.12 (METHODOLOGY.md Part 9
appended paragraph "/tmp reports are ephemeral").

**Files modified:**
- `supporting-docs/METHODOLOGY.md`

**Per-commit reviewer:** Per §F D-10, RECOMMEND per-commit
reviewer here because the §D.4 addition introduces new
procedural surface (three new triggers). If the V2 architect /
user decides §D.4 is alt-2 (only Trigger P-A lands now) or
alt-3 (defer entire mid-phase-planner gap), the commit shrinks
or merges into commit 1.

**Commit message:** `feat: v11 — BD-173 METHODOLOGY.md
substantive additions (mid-phase planner, rule placement,
/tmp ephemerality) (Batch 19c.5)`

### H.6 — Commit 6 (CONDITIONAL): METHODOLOGY.md Procedure 1 BACKLOG-proactive-surfacing STRENGTHEN

**Scope:** §C.3 (if §F D-3 = LAND).

**Files modified:**
- `supporting-docs/METHODOLOGY.md`

**Per-commit reviewer:** SKIP.

**Commit message:** `feat: v11 — BD-173 METHODOLOGY.md
proactive BACKLOG surfacing (Batch 19c.6)`

**Rationale:** Conditional on §F D-3 decision. If land: separate
commit because Procedure 1 (Part 7) is far from the prior
commit's edit sites; cleaner diff to keep it isolated.

### H.7 — Commit 7 (CONDITIONAL): Project-template trinity Claude-only sub-section

**Scope:** §F D-1 (if = YES per Alt-2: add `### Sub-agent
behavior (Claude-only)` sub-section to project-template
CLAUDE.md with OT-UT-1 content + the G-1 / G-2 research
findings).

**Files modified:**
- `project-template/CLAUDE.md` (only — Trinity exemption).

**Per-commit reviewer:** RECOMMEND per-commit reviewer (trinity
asymmetry; structural addition).

**Commit message:** `feat: v11 — BD-173 project-template
CLAUDE.md sub-agent behavior sub-section (Trinity exemption)
(Batch 19c.7)`

**Rationale:** Conditional on §F D-1 decision. If land: must be
a separate commit because trinity asymmetry is a high-signal
change that benefits from being identified as a discrete commit
in git log.

### H.8 — End-of-batch reviewer + BD status flip

**Scope:**
1. Run `pack-reviewer` on the full batch diff (HEAD `3d8cc8b`
   to current HEAD).
2. Triage findings per Pack Chat protocol (default fix-all).
3. Apply fix-coder if findings.
4. Per single-BD batch close commit shape: COMBINE fix commit
   and BD status flip in ONE final commit
   (`fix: v11 — BD-173 broad batch review/fix + status flip
   (Batch 19c)`) per PACK-CHAT.md `## Behavioral rules` "Batch
   close commit shapes" (line 113–121).
5. If no fixes: ship the BD status flip as a standalone
   `docs: v11 — flip BD-173 to Resolved` commit.

**Test fixture manifest regen:** v11-surface files in this
batch include `project-template/CLAUDE.md / AGENTS.md /
GEMINI.md` (commit 4) and possibly `project-template/CLAUDE.md`
(commit 7 if conditional fires). Per CLAUDE.md `## Pack memory`
`### Repo conventions` "Regenerate test-fixtures/manifest.txt
on every v11-surface commit" rule, those commits MUST regenerate
the manifest in the same commit. Planner pass clarifies how the
manifest regen attaches per commit.

**Note:** Files under `project-template/docs/pack/PM-CHAT.md`
and `supporting-docs/METHODOLOGY.md` are NOT v11-surface
(v11-surface = files under `project-template/` or `scripts/`).
PM-CHAT.md IS under `project-template/docs/pack/` so IS
v11-surface; METHODOLOGY.md is under `supporting-docs/` so is
NOT v11-surface. Per the rule, every commit touching PM-CHAT.md
(commits 2, 3, possibly 6) MUST regen the manifest. Planner
needs to verify this distinction.


---

## §I — Summary table (all items + dispositions + targets, one row each)

| OT-ID | Title (short) | Category | Target file | Target section | Edit type | §C ref |
|---|---|---|---|---|---|---|
| OT-T-1 | Always reviewer after coder | GENERALIZABLE-PROMOTE | PM-CHAT.md | `## Behavioral rules` | NEW bullet | §C.1 |
| OT-T-1 | (same — METHODOLOGY callout) | GENERALIZABLE-PROMOTE | METHODOLOGY.md | Part 5 Workflow 2 | NEW callout | §C.1 |
| OT-T-2 | Architect trigger surface-even-mechanical | ALREADY-COVERED + GAP-FILL extension | METHODOLOGY.md | Part 5 Workflow 4 | STRENGTHEN | §C.2 |
| OT-T-3 | BACKLOG between phases proactive | ALREADY-COVERED + optional STRENGTHEN | METHODOLOGY.md | Part 7 Procedure 1 step 2 | STRENGTHEN (conditional per §F D-3) | §C.3 |
| OT-T-4 | Closeout approval before writing docs | GENERALIZABLE-PROMOTE | PM-CHAT.md | `## Behavioral rules` | NEW bullet | §C.4 |
| OT-T-4 | (same — METHODOLOGY cross-ref) | GENERALIZABLE-PROMOTE | METHODOLOGY.md | Part 7 Procedure 4 | NEW callout (cross-ref) | §D.5 |
| OT-T-5 | No chained `git add` after edits | ALREADY-COVERED + GAP-FILL extension | PM-CHAT.md | `## Behavioral rules` — "Source file edits" bullet | STRENGTHEN | §C.5 |
| OT-T-6 | PM chat never edits source files | GENERALIZABLE-PROMOTE | PM-CHAT.md | `## Behavioral rules` | NEW bullet | §C.6 |
| OT-T-6 | (same — trinity STRENGTHEN for `git checkout --`) | GENERALIZABLE-PROMOTE | project-template CLAUDE.md / AGENTS.md / GEMINI.md | `## Project memory` — "No destructive operations" bullet | STRENGTHEN | §C.6 |
| OT-T-7 | Re-read per-agent prompt files every time + REPORT FILE check | GENERALIZABLE-PROMOTE | PM-CHAT.md | `## Behavioral rules` | NEW bullet | §C.7 |
| OT-UT-1 | Agent Teams stage lifecycle (Claude-only) | ALREADY-COVERED (pack-side) + question for project-side | project-template CLAUDE.md (conditional) | NEW `### Sub-agent behavior (Claude-only)` sub-section | NEW sub-section (conditional per §F D-1) | §F D-1 |
| OT-UT-2 | Pack repo is read-only from this project | GENERALIZABLE-PROMOTE | PM-CHAT.md | `## Behavioral rules` | NEW bullet | §C.8 |
| OT-UT-3 | Mid-pipeline working-tree intentional | GAP-FILL | PM-CHAT.md | `## Behavioral rules` | NEW bullet | §C.9 |
| OT-UT-4 | Only OPEN TDs in scope for v11 conversion | OT-SPECIFIC-OOS | (none) | (none) | (none) | §E.2 |
| OT-UT-5 | Phase 58b deferred until v11 lands | OT-SPECIFIC-OOS | (none) | (none) | (none) | §E.2 |
| OT-UT-6 | Architect output → user reads → next step waits | GENERALIZABLE-PROMOTE | PM-CHAT.md | `## Behavioral rules` | NEW bullet | §C.10 |
| OT-UT-6 | (same — METHODOLOGY Workflow 4 step 4) | GENERALIZABLE-PROMOTE | METHODOLOGY.md | Part 5 Workflow 4 step 4 | STRENGTHEN | §C.10 |
| OT-UT-7 | Feature prioritization deferred until after v11 | OT-SPECIFIC-OOS | (none) | (none) | (none) | §E.2 |
| OT-UT-8 | Open questions surface to user (meta-rule) | GENERALIZABLE-PROMOTE | PM-CHAT.md | `## Behavioral rules` | NEW bullet | §C.11 |
| OT-UT-8 | (specific OT open questions) | OT-SPECIFIC-OOS | (none) | (none) | (none) | §E.2 |
| OT-UT-9 | Re-read prompts + verify REPORT FILE present | Subsumed by OT-T-7 | (see OT-T-7) | (see §C.7) | (see §C.7) | §C.7 |
| OT-UT-10 | /tmp reports are ephemeral | GAP-FILL | METHODOLOGY.md | Part 9 | NEW paragraph | §C.12 |
| OT PM gap A | When to call planner mid-phase | GAP-FILL (architect-decision) | METHODOLOGY.md | Part 5 Workflow 4 (NEW sub-section) | NEW sub-section (conditional per §F D-6) | §D.4 |
| OT PM gap B | Closeout commit-gating elevation | Covered by §C.4 + §D.5 | (see §C.4 + §D.5) | (see §C.4 + §D.5) | (see §C.4 + §D.5) | §D.5 |
| OT PM gap C | No single "when to end fix cycle" clause | GAP-FILL | METHODOLOGY.md | Part 5 Workflow 4 (callout after fenced block) | NEW callout (conditional per §F D-5) | §D.3 |
| Arch derived 1 | Rule placement: trinity vs PM-CHAT.md vs METHODOLOGY.md | GAP-FILL (architect-derived) | METHODOLOGY.md | Part 9 (NEW sub-section) | NEW sub-section (conditional per §F D-4) | §D.2 |
| Arch derived 2 | Per-project Claude memory cache convention | GAP-FILL (architect-derived; conditional) | PM-CHAT.md | "Tool-specific: Claude Code CLI" section | NEW paragraph (conditional per §F D-1) | §D.1 |

**Total table rows:** 26 (some OT-IDs split across two targets;
some §F open-question items appear as conditional rows). Per-
distinct-OT-item count = 17 (matches inventory).


---

## §J — Batch 19b parity check

This section confirms Batch 19b decisions do not conflict with
Batch 19c proposals. Where parallels exist, Batch 19c follows the
same shape.

### J.1 — Trinity-first / single-tier-of-truth design

Batch 19b §A.1 collapsed the Tier 2 design to Tier 1 (trinity) +
Tier 1.5 (Claude-only pointer index). Batch 19c follows the same
shape for the project-side:

- Trinity (`project-template/CLAUDE.md` / `AGENTS.md` /
  `GEMINI.md`) is the authoritative source-of-truth surface for
  project-team rules (read by every agent + the PM chat).
- PM-CHAT.md is the authoritative source-of-truth surface for
  PM-chat orchestration rules (read by the PM chat at startup,
  not by agents).
- METHODOLOGY.md is the authoritative reference for methodology
  rules (workflows, procedures, prompt authoring) — read by the
  PM chat + cited by all four CLI tools.
- Tier 1.5 per-project Claude memory cache is an OPTIONAL
  convenience pointer per §D.1 — same Tier 1.5 design as
  pack-side; pure pointers, no body text, trinity / PM-CHAT.md /
  METHODOLOGY.md always wins.

**No conflict.**

### J.2 — Pack-side vs project-side rule separation

Batch 19b's `feedback_ops_product_separation` rule says "never
mix pack-repo operational files with pack product files." Batch
19c respects this by:

- Only editing pack-product surface (project-template/,
  supporting-docs/).
- Not touching any pack-ops surface (PACK-CHAT.md, PACK-AGENTS.md,
  pack-root trinity, scripts/, maintenance-docs/) per §E.1.
- Not duplicating pack-side rules into project-side (project-side
  rules are derived from OT empirical inputs, not copy-pasted
  from pack-side).

**No conflict.**

### J.3 — Mechanical-edit-vs-structural-change threshold

Batch 19b avoided structural trinity additions where possible
(STRENGTHEN existing bullets, ADD new bullets within existing
sections — rarely added new sub-sections). Batch 19c §E.5
follows the same posture:

- No new H3 sub-sections in trinity `## Project memory` (the §C.6
  trinity STRENGTHEN extends an existing bullet's named list).
- New sub-sections only in METHODOLOGY.md (§D.2 / §D.4 / §D.5)
  where the surface is appropriate for procedural additions and
  the mechanical-edit threshold per
  `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` is more permissive.
- The conditional §F D-1 new trinity sub-section is explicitly
  flagged as a structural escalation requiring user / V2-architect
  approval; default architect recommendation is NO.

**No conflict.**

### J.4 — Single-BD batch close commit shape

Batch 19b was a multi-BD batch and shipped a separate
status-flip commit after the broad batch fix. Batch 19c is a
single-BD batch (only BD-173) and per PACK-CHAT.md
`## Behavioral rules` "Batch close commit shapes" (line 113-121):
"Single-BD batches: combine the fix commit and the status flip
into ONE final commit." §H.8 follows this.

**No conflict.**

### J.5 — Researcher-first pipeline

Batch 19b ran researcher → architect → planner → coder. Batch
19c follows the same pipeline order — this V1 is the first
architect pass; pack-docs-researcher runs next (per §G research
needs); a second fresh architect produces V2; planner; then
pack-coder per commit.

**No conflict.**

### J.6 — Per-BD review/fix inline vs end-of-batch

Batch 19b ran per-BD reviews inline for multi-BD batches. Batch
19c is single-BD; per §F D-10 architect recommendation, end-of-
batch reviewer is the only review pass needed.

**No conflict.**

---

## §K — Risk surface (what could go wrong; mitigation)

### K.1 — Risk: V2 architect disagrees substantively with V1 §C placements

**Likelihood:** Medium. A fresh architect with independent
context may reach different categorizations or placement choices.

**Impact:** V2 architect produces a revised §C; planner sequences
V2; coder applies V2. V1's §C is superseded — no rework on V1's
side. V1 is consumed for its inventory, categorization
methodology, and surfaced open questions.

**Mitigation:** §F open questions exhaustively surface every
substantive decision V1 made. V2 architect reads V1 + research
output + user resolutions and re-derives. V1 should NOT be
treated as authoritative on the placement choices — V1 is
authoritative on the inventory (§A.3, §B summary) and the
open-question surface (§F + §G).

### K.2 — Risk: Pack-docs-researcher findings invalidate §B categorizations

**Likelihood:** Low-Medium. The "ALREADY-COVERED" categorizations
in §B were derived from selective reading of pack source. If a
research finding shows a rule IS already codified somewhere I
missed, §C placement for that item drops; if a research finding
shows a rule I marked "ALREADY-COVERED" actually isn't, §C
placement adds.

**Impact:** Per-item adjustment. The structure of §B / §C does
not collapse.

**Mitigation:** §G research items target exactly the
categorizations most at risk (G-3, G-4, G-5, G-6). V2 architect
re-categorizes per research output.

### K.3 — Risk: Trinity STRENGTHEN (§C.6 `git checkout --` extension) ripples to other rules

**Likelihood:** Low. The named-list extension is mechanical-edit
sized.

**Impact:** If a ripple appears (e.g., an agent definition file's
git-verb prohibition list needs the same extension), a separate
edit lands in a follow-up commit.

**Mitigation:** §E.4 explicitly says no agent-file content
changes in this batch; if V2 architect or planner identifies an
agent-file change as required, surface as V2 open question.

### K.4 — Risk: PM-CHAT.md grows beyond its maintainable size

**Likelihood:** Medium. PM-CHAT.md is currently 786 lines.
Adding ~7 new bullets to `## Behavioral rules` grows the file
by an estimated ~80-100 lines.

**Impact:** PM-CHAT.md becomes harder to scan; PM chat may take
longer to load at startup; new rules become harder to find.

**Mitigation:** New bullets are short (each is 5-12 lines per
§C). Total batch addition is ~80-100 lines added; PM-CHAT.md
ends up ~870-900 lines — still within reasonable PM-chat-startup
read budget. Per CLAUDE.md `## Pack memory` `### Repo
conventions` filename-uniqueness heuristic, PM-CHAT.md remains
single-source. If size becomes a concern, a future batch could
split PM-CHAT.md by topic — but that is OUT of Batch 19c scope.

### K.5 — Risk: Trinity files diverge across CLAUDE/AGENTS/GEMINI

**Likelihood:** Low. The only trinity edit (§C.6 STRENGTHEN)
applies symmetrically. The conditional §F D-1 trinity addition
is explicitly Trinity-exempt (CLAUDE.md only).

**Impact:** Trinity-rule violation in commit if pack-coder fails
to apply the STRENGTHEN identically across all three files.

**Mitigation:** End-of-batch reviewer specifically checks trinity
parity for STRENGTHEN edits. Per CLAUDE.md "Trinity rule," all
three files in one commit.

### K.6 — Risk: Existing OT project consumes the rules and finds them duplicative or conflicting

**Likelihood:** Low. OT is the empirical source — the OT
memories ARE the OT-side equivalent of the §C bullets. After
this batch ships, OT's tracked memories become redundant with
the project-template surface (OT memory entries continue to
point at trinity / PM-CHAT.md / METHODOLOGY.md anchors).

**Impact:** OT PM chat reads the same rule twice (once from
its memory cache, once from the project-template surface).
No conflict in content; possible cognitive overhead.

**Mitigation:** Per §D.1, the Claude memory cache IS a Tier 1.5
pointer to trinity / PM-CHAT.md / METHODOLOGY.md content — by
design, the pointer cannot diverge from the trinity content.
OT's memories already are effectively pointers (the body text
in each OT memory entry is the rule the memory cites; in the
post-batch world, OT memory entries point at the project-
template anchors as Tier 1.5). OT's PM chat does not lose
context — it gains it (the rule lives BOTH in OT's memory AND
in the project-template surface).

---

## §L — Success-criteria self-check

| Success criterion | Status | Cite |
|---|---|---|
| 1. Every rule in OT memory dump is categorized (no TBD items) | YES | §A.3 inventory + §B per-item dispositions; total = 17 items |
| 2. Per-item disposition table covers every consolidation candidate with exact target + insertion anchor | YES | §B per-item + §C placements + §I summary table |
| 3. Open questions are specific (A or B with rationale for each), not "consider X" | YES | §F D-1 through D-10 all carry recommendation + alternatives + decision-needed-at |
| 4. Placement decisions name exact files + sections | YES | §C every placement names file + section + insertion anchor |
| 5. Research-need flags name exactly what to verify | YES | §G G-1 through G-9 name question + files/sections + expected output format + architect-decision dependency |
| 6. Commit sequencing has realistic granularity (~3-6 commits typical) | YES — 5 mandatory + 2 conditional + 1 end-of-batch | §H |
| 7. Out-of-scope items are explicit and rationale-justified | YES | §E.1 through E.6 |
| 8. OT PM's flagged gaps are addressed (YES/NO/RESEARCH per item) | YES | §D.3 (cycle termination — YES per §F D-5), §D.4 (mid-phase planner — YES per §F D-6 with caveats), §D.5 (closeout elevation — YES per §C.4 + §D.5 combined) |
| 9. Doc structure is well-organized | YES | §A-§M as specified in user prompt |


---

## §M — Architect-review gate (what user needs to do next)

### M.1 — Decisions the user needs to resolve at the V1 review gate

Read §F D-1 through D-10 and decide each. Each carries an
architect recommendation; user can accept, override, or request
modification. The decisions feed forward into V2:

| ID | Architect recommendation | User decision |
|---|---|---|
| D-1 | NO new sub-section (Alt-1) | ___ |
| D-2 | NO trinity placement for always-reviewer (Alt-1) | ___ |
| D-3 | LAND §C.3 (Alt-1) | ___ |
| D-4 | LAND placement-rule sub-section in METHODOLOGY.md Part 9 (Alt-1) | ___ |
| D-5 | LAND cycle-termination clarification (Alt-1) | ___ |
| D-6 | LAND §D.4 mid-phase planner with all 3 triggers (Alt-1) | ___ |
| D-7 | LAND closeout-sequence at the proposed prescription level (Alt-1) | ___ |
| D-8 | SHIP trinity STRENGTHEN in this batch (Alt-1) | ___ |
| D-9 | GROUP BY RULE in commits (Alt-1) | ___ |
| D-10 | END-OF-BATCH reviewer only (Alt-1) | ___ |

### M.2 — Research the user authorizes for pack-docs-researcher

After D-1 through D-10 are resolved, the user authorizes a
pack-docs-researcher pass on the §G research items. The user can:

- AUTHORIZE all 9 research items (most thorough V2).
- AUTHORIZE a subset (cite which by ID).
- AUTHORIZE additional research items beyond §G (cite the
  question).

Research items recommended as HIGH PRIORITY:
- G-3 / G-4 / G-5 / G-6 — verify the GAP-FILL categorizations
  in §B before V2 commits to placements.
- G-1 / G-2 — if D-1 = YES (add Claude-only sub-section), this
  research is required.

Research items recommended as MEDIUM PRIORITY:
- G-7 — verify §D.4 mid-phase planner trigger has no existing
  codification.
- G-8 — verify no skill overlap.
- G-9 — confirm §D.1 no-existing-tooling claim.

### M.3 — What V2 architect produces

After research output lands, the user spawns a SECOND fresh
architect for V2. V2 reads:
- This V1 (`ARCHITECTURE-CLEANUP-BATCH-19C.md`).
- The research output
  (`RESEARCH-CLEANUP-BATCH-19C-<scope>.md`).
- User decisions on §F D-1 through D-10.

V2 produces:
- Confirmed (or revised) §B per-item table.
- Final §C placements (BEFORE/AFTER text) reflecting any
  research-driven adjustments and user overrides.
- Final §H commit sequencing (planner-ready).
- Resolved §F open questions (no more open D-N decisions —
  every decision has a verdict).
- Any V1 → V2 disagreements stated explicitly (per the V2-of-
  Batch-19b pattern in §A of that doc).

### M.4 — Planner consumption (after V2 lands)

After V2 lands and user approves, planner pass produces:
- Per-commit task list with exact file paths and content
  diffs.
- Verification commands per commit.
- Per-commit reviewer scope (which commits get inline review).
- End-of-batch reviewer scope.
- Manifest-regen step assignments per commit.
- Per-commit checklist for pack-coder.

### M.5 — Pack-coder consumption (after planner approves)

After planner lands and user approves, fresh pack-coder per
commit applies the planner's task list mechanically. Each coder
PREFLIGHT line confirms in-scope edits complete + HEAD SHA;
each coder writes IMPL-REPORT to `maintenance-docs/v11-
implementation/IMPLEMENTATION-REPORT-CLEANUP-BATCH-19C-
<commit-id>.md`.

### M.6 — End-of-batch flow

After all commits land:
1. Pack-reviewer runs on full batch diff (HEAD before batch →
   final HEAD).
2. Pack Chat triages findings to user (default fix-all).
3. Fresh pack-coder applies fixes (if any).
4. Per §H.8 single-BD batch close commit shape: fix commit +
   BD-173 status flip ship in ONE commit.
5. If no fixes: standalone `docs: v11 — flip BD-173 to
   Resolved` commit closes the batch.

---

*End of ARCHITECTURE-CLEANUP-BATCH-19C V1.*

