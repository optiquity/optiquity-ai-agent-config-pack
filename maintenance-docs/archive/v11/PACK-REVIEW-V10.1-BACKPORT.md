# PACK REVIEW — v10.1 backport (1daa938..HEAD)

**Branch:** `v11-dev`
**HEAD at review time:** `bca0cfeec99ab6151601efb64fe2ef1376563f48`
**Diff range reviewed:** `1daa938..HEAD` (9 commits — note: the
prompt narrative names 8 commits ending at `19755b5`, but the
working-tree HEAD is one commit further at `bca0cfe`. Per the
prompt's literal `git diff 1daa938..HEAD` instruction, `bca0cfe` is
in scope and is reviewed below.)

---

## Environment self-report

```
$ pwd
/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev

$ git rev-parse HEAD
bca0cfeec99ab6151601efb64fe2ef1376563f48

$ git rev-parse --abbrev-ref HEAD
v11-dev
```

---

## Summary

**Verdict: fix-then-ship.**

Counts: **3 BLOCKER, 4 SHOULD-FIX, 5 NIT.**

Headline issues:

1. (BLOCKER) The new RAG-reconciliation Step 4 in
   `project-template/skills/pm-startup/SKILL.md` is the canonical
   skill source, but the three live per-CLI surfaces (`.claude/`,
   `.codex/`, `.gemini/` copies in `project-template/`) still
   ship the old single-file freshness check. `init-project.sh`
   stage S4 overwrites the `.claude/` and `.codex/` SKILL.md copies
   from the canonical at install time, so fresh installs inherit
   the new content for those two — but `.gemini/commands/pm-startup.toml`
   is never overwritten, so Gemini installs ship the stale Step 4
   in the file the slash command actually executes. The pack-repo
   committed copies of all three per-CLI files are also stale and a
   maintenance hazard.
2. (BLOCKER) Procedure 5-S Task C (added by `45d2098` to
   `supporting-docs/INSTALL-PROCEDURES.md`) reads a `RAG:` line
   from `/pm-startup` Step 6 that does not exist in the per-CLI
   pm-startup files. Task C is unrunnable on Gemini and on any
   project whose pack predates the next install/migration cycle.
3. (BLOCKER, possibly out-of-scope) Commit `bca0cfe` deletes ~78
   lines of pack-repo-ops content from the root `CLAUDE.md`
   (Quick reference, BD-119 migrator-framework note, and the
   entire prior `## Pack memory` section: Workflow / Agent
   invocation rules / Repo conventions / Project goals (v11)) and
   replaces Pack memory with a single Claude-only worktree-isolation
   rule. None of the deleted content was Claude-specific. The
   identical text remains in `AGENTS.md` and `GEMINI.md` at the
   pack-repo root, breaking the trinity rule explicitly stated in
   `CLAUDE.md` line 64 ("This rule also applies to the pack-repo
   copies of these three files").

The v10.1 cherry-picks `43b5fe1`, `991d9e3`, `f70d798`, `83383da`,
`ac6fb0c` themselves are largely clean (per-agent permission
profiles symmetric across the trinity, PM-CHAT.md additions
internally consistent, METHODOLOGY.md hygiene principle well
written, validator Check 27 passes). The optimization pass
`19755b5` correctly resolved the Check 21 numbering collision. The
BLOCKERs above arise from the cherry-picks' incomplete reach into
the per-CLI surfaces and from `bca0cfe`'s scope going beyond what
the v10.1 backport needed.

---

## Focus area 1 — Trinity consistency

**Pack-repo root trinity (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`):
findings.**

### F-1 (BLOCKER) — Pack-root CLAUDE.md broke trinity symmetry with AGENTS/GEMINI

- **File / range:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md`
  is now 99 lines; `AGENTS.md` is 152 lines; `GEMINI.md` (not
  re-read here in full but had identical Pack memory section per
  prior review) carries the same `## Pack memory (project-local
  learnings)` H2 at line 68 that AGENTS.md has at line 87.
- **What's wrong:** `bca0cfe` deleted from `CLAUDE.md`:
  - The `## Quick reference` block (pack-help pointer + recommended
    first action), still present in `AGENTS.md` lines 9–12.
  - The `**Migrator framework (BD-119).**` paragraph, still
    present in `AGENTS.md` lines 29–34.
  - The entire `## Pack memory (project-local learnings)` section
    (Workflow, Agent invocation rules, Repo conventions, Project
    goals (v11) — roughly 70 lines), still present in `AGENTS.md`
    lines 87–151 and `GEMINI.md` line 68 onward.
  These are then replaced in CLAUDE.md by a single new section
  `## Pack memory (Claude-only, all chats in this repo)` with one
  rule: "Spawn all sub-agents with no worktree isolation."
- **Why it's wrong:** The trinity rule in `CLAUDE.md` itself
  (lines 58–64) says: *"This rule also applies to the pack-repo
  copies of these three files."* Of the deleted content, only the
  worktree-isolation rule is provably Claude-specific (it concerns
  Claude Code's Agent tool). The rest — `Quick reference`, the
  BD-119 migrator-framework warning, `Agents never commit`, `Pack
  Chat does not architect`, `One review/fix cycle per batch`,
  `Implicit BD status flip on batch completion`, `Pack agent
  invocation` (the Codex/Gemini equivalents), `Agent prompt
  requirements`, `No solutions in agent prompts`, `No prior
  reviews to pack-reviewer`, `BACKLOG.md has no Resolved section`,
  `Separate pack ops from pack product`, `Test infra is
  self-provisioned`, and `Project goals (v11)` — are all
  tool-agnostic governance for pack development. Their deletion
  leaves Codex- and Gemini-driven pack sessions reading those
  rules from AGENTS.md / GEMINI.md while Claude-driven sessions
  do not see them.
- **Suggested fix direction:** Either restore the deleted
  governance content to `CLAUDE.md` and append the new Claude-only
  worktree rule alongside the broader Pack memory (preferred), or
  delete the parallel content from `AGENTS.md` and `GEMINI.md` if
  it is genuinely no longer in force (substantively a separate
  decision and almost certainly wrong).

### F-2 (NIT) — Project-template trinity Project memory section verified clean

- **Files:** `project-template/CLAUDE.md` lines 322–344;
  `project-template/AGENTS.md` lines 297–321;
  `project-template/GEMINI.md` lines 317–334.
- **Verification:** Spot-checked the `## Project memory` section
  added by `991d9e3`. CLAUDE.md and AGENTS.md are byte-identical;
  GEMINI.md is intentionally compressed but content-equivalent
  (same three rules: trinity rule, no destructive ops without
  approval, PM chat does not architect). validate-pack Check 18
  (H2 parity) confirms 26-section parity. PASS.

### F-3 (NIT) — Per-agent Permission profile / Output policy / Hard rules trinity verified clean

- **Files:** `project-template/.claude/agents/*.md`,
  `project-template/.codex/agents/*.toml`,
  `project-template/.gemini/agents/*.md` (16 agents × 3 CLIs).
- **Verification:** validate-pack Check 27 (Agent canonical-phrase
  compliance) passes for all 48 files with the correct profile
  assignments. Spot-diffed `coder.md` and `repo-ops.md` Claude vs
  Gemini — identical content modulo intentional Gemini
  compression. The Codex `.toml` developer_instructions string
  carries the same prose with TOML-required line collapsing.
  PASS.

---

## Focus area 2 — Cross-doc references

### F-4 (SHOULD-FIX) — `INSTALL-PROCEDURES.md` historical block-quote references files deleted in v11

- **File:** `supporting-docs/INSTALL-PROCEDURES.md` lines 207, 216,
  217, 220, 246, 802.
- **What's wrong:** These references to `migrate-v9-to-v10.sh` and
  `MIGRATION-v9-to-v10.md` (deleted in `1daa938` BD-121 sunset)
  are inside Procedures 5-C and 5-S which carry an explicit
  `> **HISTORICAL — sunset in v11 (BD-121).**` block-quote at the
  top. The block-quote contains the exact recovery command:
  `git -C "$PACK" checkout v10 -- scripts/migrate-v9-to-v10.sh
  supporting-docs/MIGRATION-v9-to-v10.md`. This is intentional and
  justified for legacy v9.x clients.
- **However:** lines 220, 246, 802, 881 reference these files in
  bare prose (e.g., line 220: *"project working tree after
  `migrate-v9-to-v10.sh` completes."*; line 802: *"After commit,
  follow `MIGRATION-v9-to-v10.md` Step 8 to merge"*) without
  callouts that the file no longer ships. A reader searching the
  doc for "MIGRATION-v9-to-v10" will land on these bare references
  and may not realize the file is sunset.
- **Suggested fix direction:** Either fold these bare references
  into the existing HISTORICAL block-quote scope, or annotate each
  in-prose mention with a "(historical)" qualifier so the reader
  knows the file is no longer in the working tree.

### F-5 (SHOULD-FIX) — `supporting-docs/METHODOLOGY.md` § RAG index hygiene incorrectly states CLI-PM-SETUP is pack-only

- **File:** `supporting-docs/METHODOLOGY.md` lines ~165–170 (per
  the diff, the parenthetical *"the pack-distributed
  `CLI-PM-SETUP.md` documents this for pack maintainers;
  project-installed copies of this file do not include that
  pack-only doc"*).
- **What's wrong:** `supporting-docs/CLI-PM-SETUP.md` is a normal
  supporting-docs/ companion document, not pack-only. The
  project-template's own `README.md` line 13 instructs users to
  copy `supporting-docs/METHODOLOGY.md` into their project; users
  who copy `CLI-PM-SETUP.md` similarly have it in-project. The
  parenthetical's claim that `CLI-PM-SETUP.md` is unavailable to
  project-installed copies is false. The `.mcp.json.example` in
  project-template line 9 also points users to
  `supporting-docs/CLI-PM-SETUP.md`.
- **Suggested fix direction:** Drop the "pack-only doc"
  parenthetical or rephrase to acknowledge `CLI-PM-SETUP.md` is
  a companion doc copied alongside METHODOLOGY.md.

### F-6 (NIT) — Validator check-number consistency verified

- **Verification:** `python3 scripts/validate-pack.py` runs to
  PASS. `Check 21` is `Pack-help per-CLI parity (BD-082)` (the
  v11 pre-existing check); `Check 27` is `Agent canonical-phrase
  compliance (v10.1)` (the renumbered v10.1 import). The
  top-of-file docstring lists every numbered check that `main()`
  actually calls. The v10.1 IMPLEMENTATION-REPORT and (deliberately
  not read) prior reviews are the only places that still mention
  `Check 21` for the canonical-phrase check; those are historical
  records, not authoritative. PASS.

### F-7 (NIT) — Project memory section's agent list omits `auditor-*` siblings

- **Files:** `project-template/CLAUDE.md` line 343, AGENTS.md line
  320, GEMINI.md line 332. Each lists "(architect / planner /
  coder / reviewer / tester / auditor / docs-researcher /
  grpc-schema / repo-ops)" — 9 agents — but the project ships 16
  agents including 7 auditor variants.
- **Why it's a NIT:** the wording `auditor` arguably abbreviates
  the variant family; this is plausibly intentional. Worth noting
  for future tightening.

---

## Focus area 3 — Dead-file references

### Verification

`grep -rn "migrate-v9-to-v10\|MIGRATION-v9-to-v10"` across the
working tree finds references only inside `INSTALL-PROCEDURES.md`
(covered in F-4) and a single line in
`project-template/.claude/skills/pm-startup/SKILL.md` (covered in
F-8). No v10.1 cherry-pick introduced fresh dead-file references.
The optimization pass `19755b5` audited Item 4 against this and
correctly noted no edits required for the historical block-quotes.

**Verdict:** PASS — verified by grep against the deleted-file set
from `1daa938`.

---

## Focus area 4 — Pack-ops vs pack-product separation

### F-8 (BLOCKER) — pm-startup RAG reconciliation is in canonical SKILL but not in live per-CLI surfaces

- **Files affected (canonical, updated in `eec122e`):**
  `project-template/skills/pm-startup/SKILL.md` lines 96–159
  (new Step 4 — full RAG reconciliation, manifest-driven, with
  `RAG:` summary line in Step 6 line 188).
- **Files affected (live per-CLI surfaces, NOT updated):**
  - `project-template/.claude/skills/pm-startup/SKILL.md` lines
    96–105 — still the pre-v10.1 "Check RAG ingest freshness"
    Step 4 (single git-log-mtime check on
    `docs/pack/METHODOLOGY.md`).
  - `project-template/.codex/skills/pm-startup/SKILL.md` lines
    96–105 — identical to .claude.
  - `project-template/.gemini/commands/pm-startup.toml` lines
    93–102 — same pre-v10.1 content inside the TOML `prompt = """..."""`
    string.
- **What's wrong:**
  1. Pack-repo state: three live `/pm-startup` implementations are
     stale relative to the canonical that the v10.1 cherry-pick
     updated. Anyone reading the pack repo or running validator-style
     audits sees three `/pm-startup` files that do not implement the
     v10.1 RAG reconciliation.
  2. Install-time state: `scripts/init-project.sh` stage S4
     overwrites `.claude/skills/<name>/SKILL.md` and
     `.codex/skills/<name>/SKILL.md` from the canonical
     `project-template/skills/<name>/SKILL.md`, so a fresh
     `init-project.sh` run delivers the new Step 4 to the .claude
     and .codex client locations. But Gemini's slash command lives
     in `.gemini/commands/pm-startup.toml`, which init-project.sh
     never copies or regenerates from the canonical Markdown
     SKILL. Gemini installs ship the stale Step 4 in the file
     Gemini's slash dispatcher actually reads.
  3. Existing-project state: clients on v10.x or earlier who
     installed before the optimization pass have stale Step 4 in
     all three CLIs and no automated migrator currently rewrites
     `/pm-startup` files in place.
- **Why it's wrong:** Procedure 5-S Task C (see F-9) and Section 6
  startup summary parsing in PM-CHAT.md depend on the new `RAG:`
  output line. With stale Step 4 in the live surfaces, the
  summary line is absent and the procedure is silently broken.
- **Suggested fix direction:**
  - Synchronize `project-template/.claude/skills/pm-startup/SKILL.md`,
    `project-template/.codex/skills/pm-startup/SKILL.md`, and
    `project-template/.gemini/commands/pm-startup.toml` with the
    canonical Step 4 + Step 6 summary line.
  - Add an `init-project.sh` stage step (or a validator check)
    that either generates the Gemini `.toml` from the canonical
    Markdown skill or asserts byte-equivalence of Step-4 content
    across all four files (canonical + three per-CLI surfaces).

### F-9 (BLOCKER) — Procedure 5-S Task C unrunnable on the fleet

- **File:** `supporting-docs/INSTALL-PROCEDURES.md` lines 879–913
  (Procedure 5-S, including Task C row at line 892 and step 4 at
  lines 902–906).
- **What's wrong:** Task C and step 4 explicitly read "the current
  session's `/pm-startup` Step 4 output (the `RAG:` line in the
  startup summary)" and branch on three `RAG:` value variants
  (`0 orphans` / `not available — skipped` / `manifest not found
  — skipped`). The `RAG:` line only exists if the Step 6 summary
  template was emitted by the v10.1 canonical SKILL. Per F-8 the
  three live per-CLI `/pm-startup` files do not emit a `RAG:`
  line. Therefore: the PM chat looking for the `RAG:` line will
  not find it, and Procedure 5-S Task C cannot be confirmed.
- **Why it's wrong:** Beyond the structural broken-procedure
  issue, this also undermines the housekeeping sentinel: step 5
  says "If all tasks completed (no deferred items remain), PM
  chat offers to remove the sentinel." With Task C silently
  unfulfilled, the sentinel either lingers indefinitely (if Task
  C raises an "absent" defect) or is removed without the RAG
  cleanup actually being verified (if the PM chat ignores the
  missing line).
- **Why this is doubly fragile:** Procedure 5-S itself carries a
  `> **HISTORICAL — sunset in v11 (BD-121).**` block-quote (lines
  872–877) saying it does not fire for new migrations. Adding a
  Task C to a procedure marked historical creates contradictory
  framing — the block-quote says "retained as historical
  documentation only" but Task C is a new active rule.
- **Suggested fix direction:**
  - Resolve F-8 first (make the per-CLI Step 4 implementations
    emit the `RAG:` summary line).
  - Reconcile the "historical" block-quote with Task C either by
    narrowing the block-quote ("Tasks A/B are historical; Task C
    runs whenever the sentinel exists, including legacy v9.x
    cleanup") or by relocating Task C's RAG-reconciliation
    confirmation to a non-historical procedure or to METHODOLOGY's
    RAG hygiene section.

### F-10 (NIT) — Pack-ops ↔ pack-product boundary otherwise clean

- **Verification:** Cross-checked the four supporting-docs/
  files modified by the cherry-picks (CLI-PM-SETUP.md,
  INSTALL-PROCEDURES.md, METHODOLOGY.md) and the
  project-template/ files modified — no pack-ops content (BACKLOG,
  PACK-CHAT, PACK-AGENTS, root .md governance) leaked into
  project-template/ or supporting-docs/, and no project-template
  content (skills, agent files) leaked into pack-ops. PM-CHAT.md
  changes stay inside `project-template/docs/pack/`. PASS — verified
  by `git diff 1daa938..HEAD --stat` review.

---

## Focus area 5 — Validator vs actual structure

### F-11 (SHOULD-FIX) — Validator does not enforce per-CLI pm-startup parity

- **File:** `scripts/validate-pack.py`.
- **What's wrong:** Check 21 (Pack-help per-CLI parity, BD-082)
  enforces pack-help skill parity across `.claude/skills/`,
  `.codex/skills/`, `.gemini/commands/` (or `.gemini/skills/`),
  but no equivalent check covers pm-startup. Given that
  `init-project.sh` stage S4 overwrites the .claude / .codex
  copies from the canonical `project-template/skills/<name>/SKILL.md`
  but does NOT touch `.gemini/commands/pm-startup.toml`, divergence
  here is not just possible but already present (F-8). A validator
  check would have caught the v10.1 cherry-pick's incomplete reach.
- **Why it's wrong:** validate-pack.py is the gating CI for the
  pack — its silence on pm-startup parity is what allowed the
  F-8 BLOCKER to land clean.
- **Suggested fix direction:** Add a Check 28 (or extend Check 21)
  that asserts the canonical `project-template/skills/pm-startup/SKILL.md`
  and the three per-CLI surfaces agree on Step 4 substance and
  Step 6 summary fields. The Gemini `.toml` parsing is the only
  awkward part since it's prose-in-TOML.

### F-12 (verified) — Validator runs PASS end-to-end

- **Method:** `python3 scripts/validate-pack.py` from repo root.
- **Result:** All 24 numbered checks + 2 informational checks PASS.
  Check 17 (Tool-config AGENT_CAPABILITIES parity), Check 18
  (Trinity H2 structure parity), Check 16 (Trinity ## Project
  addenda H2), and Check 27 (Agent canonical-phrase compliance —
  the renumbered v10.1 check) all green for the post-cherry-pick
  state.
- **Verdict:** PASS — verified by full validator run.

---

## Focus area 6 — Agent-roster consistency

### F-13 (verified) — Per-agent Permission profile assignments match across PM-CHAT.md and agent files

- **Method:** Cross-checked `project-template/docs/pack/PM-CHAT.md`
  Profile assignment table (lines 271–289) against
  `project-template/.claude/agents/*.md` and
  `project-template/.codex/agents/*.toml` Permission profile
  declarations.
- **Result:**
  - PM-CHAT.md table: 14 read-only (architect, planner, reviewer,
    tester, docs-researcher, grpc-schema, auditor + 7 variants),
    1 write-scoped (coder), 1 write-script (repo-ops). Total 16.
  - validate-pack Check 27 reports the same: 14 `read-only`, 1
    `write-scoped` (coder), 1 `write-script` (repo-ops). Same 16
    agents. PASS.

### F-14 (NIT) — Codex `sandbox_mode = "workspace-write"` for read-only agents has comment justification

- **Files:** `project-template/.codex/agents/architect.toml` line 9
  + comment (lines 5–8); same pattern across the other 13
  read-only Codex agents.
- **Verification:** All 14 read-only Codex agents carry the
  comment explaining that `workspace-write` is required so the
  agent can emit its final report file at the prompted path while
  the developer_instructions enforce the read-only restriction in
  prose. This is consistent with the v11 pack-reviewer pattern as
  noted in the `43b5fe1` commit message.
- **Verdict:** PASS — verified by spot-check of architect, planner,
  reviewer, auditor.

---

## Focus area 7 — Wording contradictions

### F-15 (NIT) — `## Pack memory (Claude-only…)` rule says "this rule is Claude-specific (not part of the trinity)"

- **File:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md`
  lines 81–98.
- **Observation:** The new section explicitly states the rule is
  Claude-specific and so does not need parallel entries in
  AGENTS.md / GEMINI.md. That asymmetry is correctly justified
  (the rule concerns Claude Code's Agent tool's `isolation: "worktree"`
  mode, which Codex and Gemini do not have). This particular
  asymmetry is fine in isolation. The trinity violation flagged in
  F-1 is about the OTHER content that was removed at the same
  time (Quick reference, BD-119 note, prior Pack memory) — not
  about this Claude-only rule.

### F-16 (NIT) — `agent-run.sh` flag profile in PM-CHAT.md vs. agent files: read-only profile description mismatch

- **Files:**
  `project-template/docs/pack/PM-CHAT.md` lines 313–317 (Read-only
  profile flag profile says "Write is allowed (for the report);
  Edit is denied").
  `project-template/.claude/agents/architect.md` lines 15–25
  (Permission profile for read-only says "The single permitted
  file write or edit during this session is exactly one final
  report file" — i.e., both Write and Edit are conceptually
  permitted but only for the report).
- **What's wrong:** The PM-CHAT.md flag profile asserts `Edit`
  is on the disallowed-tool list; the agent file says Edit is
  allowed for the report. In practice the prose intent is the
  same (only the report file gets written), but the mechanism
  description differs: agent file allows both Write and Edit on
  the report (chunked-Edit pattern in Hard rules); PM-CHAT.md
  explicitly disallows Edit at the agent-run.sh layer.
  - If Edit is truly disallowed at the CLI layer, the chunked-Edit
    pattern in agent files (e.g., architect.md lines 47–48: "Chunk
    long writes…then append remaining sections via Edit or
    successive Write calls") cannot be used.
  - If Edit is allowed but PM-CHAT says it's denied, the PM-CHAT
    flag-profile string is wrong.
- **Suggested fix direction:** Pick one stance — either remove
  `Edit` from the disallowed-tool list in PM-CHAT.md's flag
  profile (line 314) and document chunked-Edit as the canonical
  long-report pattern, or remove the chunked-Edit guidance from
  the agent files' Hard rules. The decision should propagate to
  all 14 read-only agent files in lockstep.

### F-17 (NIT) — `docs/pack/METHODOLOGY.md` is the manifest default but never ships under that path in pack-template

- **Files:** PM-CHAT.md line 136 ("default manifest is exactly
  one path: `docs/pack/METHODOLOGY.md`"), pm-startup canonical
  SKILL.md line 121 (same statement), `project-template/`
  contains no `docs/pack/METHODOLOGY.md` file (verified via
  `find /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template -name METHODOLOGY*`
  returns empty).
- **Why it's a NIT not a BLOCKER:** This is the documented v10.0
  install-time copy step (project-template/README.md line 13:
  `cp /path/to/pack/supporting-docs/METHODOLOGY.md
  /path/to/your-project/docs/pack/METHODOLOGY.md`). Real client
  projects have METHODOLOGY.md at that path because they ran the
  install. The pack repo itself never has it because the pack
  doesn't install on top of itself. The `local-rag.list` /
  reconcile flow runs in client projects where the file exists.
- **Worth noting:** A first-run RAG reconciliation in a client
  project that has not yet copied METHODOLOGY.md will see the
  manifest target as "missing" and try to ingest a non-existent
  path. The Step 4 prose does not specifically handle "manifest
  path does not exist on disk." Worth a small defensive
  enhancement.

---

## Per-area verdicts (summary)

| Focus area | Verdict |
|---|---|
| 1. Trinity consistency | findings (F-1 BLOCKER, F-2/F-3 PASS) |
| 2. Cross-doc references | findings (F-4 SHOULD-FIX, F-5 SHOULD-FIX, F-6/F-7 PASS/NIT) |
| 3. Dead-file references | PASS — verified by grep |
| 4. Pack-ops vs pack-product separation | findings (F-8 BLOCKER, F-9 BLOCKER, F-10 PASS) |
| 5. Validator vs actual structure | findings (F-11 SHOULD-FIX, F-12 PASS) |
| 6. Agent-roster consistency | PASS — verified by table cross-check + Check 27 |
| 7. Wording contradictions | NIT (F-15/F-16/F-17) |

---

## Final summary

**3 BLOCKER, 4 SHOULD-FIX, 5 NIT. Verdict: fix-then-ship.**

The v10.1 cherry-picks introduced two real defects that will break
client behavior the moment a Gemini PM chat tries to run
`/pm-startup` (F-8) or any PM chat tries to complete Procedure 5-S
post-migration (F-9). Both are downstream of a single root cause —
the v10.1 RAG-reconciliation Step 4 update only touched the
canonical `project-template/skills/pm-startup/SKILL.md` and not the
three per-CLI surfaces that downstream PM chats actually execute.
Fixing F-8 and F-9 in lockstep, and adding the validator coverage
of F-11 to prevent regression, is the minimum to ship. The
out-of-scope `bca0cfe` content deletion (F-1 BLOCKER) is structurally
unrelated to the v10.1 backport but deserves explicit
keep/restore/document decisions since the trinity rule was broken
and the deleted content was non-trivial governance content. The
remaining SHOULD-FIX and NIT items can ship in a follow-up batch.
