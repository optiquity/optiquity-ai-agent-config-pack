# IMPL-REPORT — BD-173 Batch 19c H.16

**Branch:** `v11-dev`
**Pre-implementation HEAD:** `5958384d49db326a9feba8f74e9f8d8248a52351` (H.15 — Guardrail 4 PREFLIGHT extension; CI green)
**Final HEAD on coder worktree:** `5958384d49db326a9feba8f74e9f8d8248a52351` (no commits by agent per workflow rule)
**Date:** 2026-05-24
**Coder:** `pack-coder` (Claude Code v11-dev session)
**Status:** Implementation complete; awaiting Pack Chat user-approval + commit

---

## §1 Scope

This commit lands two related METHODOLOGY.md Part 1 edits in one
commit per PLAN §H.16 (sliding-window scope, one per commit):

1. **D-11 principle landing** — NEW H3 sub-section
   `### PM chat omniscience obligation` in
   `## Part 1 — Tool Roles`, inserted after the existing
   "Separation rule" sub-section. Per V2 §D.6.2 verbatim text
   (multi-paragraph principle + two-exception block + closing
   default rule).

2. **OT-UT-1 informational paragraph** — NEW `>` callout in the
   `### Claude Code CLI (agents)` sub-section, inserted after the
   existing 4-bullet capabilities list and before the next H3
   `### Xcode Coding Agent`. Per V2 §D.7.3 verbatim text.

**File scope:**
- `supporting-docs/METHODOLOGY.md` (2 edits in Part 1)
- `test-fixtures/manifest.txt` (RC9 manifest regen — v11-surface
  per BD-176)
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.16.md` (this file, NEW)

**Cross-references:**
- PLAN §H.16 (`maintenance-docs/v11-implementation/PLAN-CLEANUP-BATCH-19C.md` L754-797)
- V2 §D.6 (D-11 PM-chat omniscience principle), §D.6.2 (verbatim
  principle text), §D.6.3 (documented exceptions table — informs
  the two-exception block in §D.6.2 prose)
- V2 §D.7.3 (OT-UT-1 informational paragraph verbatim text)
- BD-182 §3.1 R3-R7 (TOOL-NEUTRAL enumeration pattern — informs
  the OT-UT-1 paragraph's three-CLI naming)
- H.5 forward-reference closure: H.5 landed the V2 §D.2 placement
  rule at METHODOLOGY.md L1594 referencing "PM chat omniscience
  obligation (Part 1 — Tool Roles)"; H.16 lands the referenced
  Part 1 sub-section at L121 — forward-pointer closed.

---

## §2 Edits applied

### §2.1 Edit 1 — D-11 principle landing (NEW H3 sub-section)

**Target file:** `supporting-docs/METHODOLOGY.md`
**Target section:** `## Part 1 — Tool Roles`
**Insertion anchor:** Immediately after the existing
"Separation rule" sub-section (which closes at L101 with
"Pasting results from CLI back to Claude Chat: developer only.")
and immediately before the `---` Part 1 / Part 2 boundary.

**Final inserted location:** L121-181 in the post-edit file (new
H3 heading at L121; closing default rule at L181 followed by
blank line + `---` at L183).

**BEFORE (pre-edit context):**

```
### Separation rule

Planning and decisions: Claude Chat only.
Execution and file changes: CLI agents only (or Desktop Commander for small doc edits).
Pasting results from CLI back to Claude Chat: developer only.

---

## Part 2 — Standard Project Documents
```

**AFTER (post-edit):**

```
### Separation rule

Planning and decisions: Claude Chat only.
Execution and file changes: CLI agents only (or Desktop Commander for small doc edits).
Pasting results from CLI back to Claude Chat: developer only.

### PM chat omniscience obligation

The Separation rule above describes the WHAT — who does what
work. This sub-section describes the WHY — why the PM chat is
positioned as the brain.

[... full V2 §D.6.2 verbatim text — multi-paragraph principle
text + four-bullet list of inclusions + two-exception block
+ closing default rule ...]

When in doubt, default to single-source authoritative + PM-chat
injection. Duplication requires a documented exception.

---

## Part 2 — Standard Project Documents
```

**Verbatim-source rationale:** Per PLAN §H.16 "Per V2 §D.6.2
verbatim text (the full prose block; multi-paragraph principle
text + two-exception block + closing default rule)." The
inserted text is byte-identical to the V2 §D.6.2 fenced code
block at `ARCHITECTURE-CLEANUP-BATCH-19C-V2.md` L799-855.

**Boundary discipline rationale:** Per V2 §H.16 reviewer focus +
salvageability B9 — the principle text cites only project-side
surfaces. Pack-side citations (pack memory, Tier 1.5, MEMORY.md,
pack-ops/, maintenance-docs/) are NOT present in the inserted
text. The text's only file references are:
- `docs/pack/PM-CHAT.md` (project-side, client-installed)
- "the project trinity § Project memory" (project-side surface)
- "this methodology document" (the file being edited — METHODOLOGY.md)
- "§ Prompt Authoring Principles" (existing METHODOLOGY.md section)
- "Part 9 § Rule placement" (existing METHODOLOGY.md section,
  forward-reference to the H.5-landed placement rule at L1594)

These are all project-side, client-side, or self-references.
The principle stands on its own project-side merits.

**Two-exception block rationale:** Per V2 §D.6.3, the two
documented exceptions to the omniscience-injection default are:
1. **Defense-in-depth duplication for high-blast-radius rules** —
   trinity placement is correct when prompt-corruption risk is
   non-trivial AND all agents must respect the rule. Worked
   example in V2 §D.6.3 table: §C.6 trinity STRENGTHEN
   (destructive-ops list extension with `git checkout --`).
2. **Cross-CLI parity ergonomics** — duplication across the
   three CLI tools (Claude / Codex / Gemini) is acceptable when
   per-CLI prompt-injection logic does not yet exist. Narrows
   as per-CLI injection mechanisms become available.

Both exceptions are included as `**bold-anchored**` bullets in
the inserted text, exactly matching V2 §D.6.2 prose.

### §2.2 Edit 2 — OT-UT-1 informational paragraph (NEW `>` callout)

**Target file:** `supporting-docs/METHODOLOGY.md`
**Target section:** `## Part 1 — Tool Roles` → `### Claude Code CLI (agents)`
**Insertion anchor:** Immediately after the existing 4-bullet
capabilities list at L80-83 (last bullet:
"Receives complete instructions in the prompt; never relies on
session history") and immediately before the next H3
`### Xcode Coding Agent` (was at L85 pre-edit; now at L102 post-edit).

**Final inserted location:** L84-101 in the post-edit file
(`>` callout opens at L84; closes at L101 with
"this convention does not apply to your CLI's runtime behavior.").

**BEFORE (pre-edit context):**

```
### Claude Code CLI (agents)

- Executes specific, scoped tasks in new sessions
- Full filesystem read/write access; runs builds, tests, git commands
- No persistent memory — each session starts fresh with full context in the prompt
- Receives complete instructions in the prompt; never relies on session history

### Xcode Coding Agent
```

**AFTER (post-edit):**

```
### Claude Code CLI (agents)

- Executes specific, scoped tasks in new sessions
- Full filesystem read/write access; runs builds, tests, git commands
- No persistent memory — each session starts fresh with full context in the prompt
- Receives complete instructions in the prompt; never relies on session history

> **Claude-only operating convention — Agent Teams stage
> lifecycle.** When the developer enables Claude Code's Agent
> Teams flag (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`),
> sub-agents spawned for a phase stage (architect → planner →
> coder → reviewer) stay alive within the stage; the PM chat
> uses SendMessage to send follow-up directives to the same
> sub-agent instance. After the stage's commit lands, close
> all stage sub-agents and respawn fresh for the next stage.
> Additionally, each coder commit should use a FRESH coder
> instance — never reuse a coder across commits, even within
> the same stage. This convention is Claude-Code-specific:
> Codex CLI's `/agent` slash command provides similar
> long-lived-thread behavior but no peer-messaging analog;
> Gemini CLI's `@agent` invocation is one-shot per delegation
> (no parent-controlled keep-alive across multiple parent
> turns). Codex / Gemini project teams: this convention does
> not apply to your CLI's runtime behavior.

### Xcode Coding Agent
```

**Verbatim-source rationale:** Per PLAN §H.16 "Per V2 §D.7.3
verbatim." The inserted `>` callout block is byte-identical to
the V2 §D.7.3 fenced code block at `ARCHITECTURE-CLEANUP-BATCH-19C-V2.md`
L892-910.

**TOOL-NEUTRAL enumeration rationale:** Per BD-182 §3.1 R3-R7,
references in `project-template/` and other shared documents
that enumerate all three CLIs (Claude Code, Codex, Gemini) are
TOOL-NEUTRAL — correct per-audience regardless of which CLI is
reading. The inserted paragraph names:
- Claude Code's Agent Teams flag (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`)
- Claude Code's SendMessage
- Codex CLI's `/agent` slash command
- Gemini CLI's `@agent` invocation

The paragraph is functionally Claude-specific (the convention
applies to Claude Code's runtime behavior) but contextualizes
why Codex / Gemini readers do NOT need to apply it. This is
correct per any audience reading METHODOLOGY.md.

**Surface placement rationale:** Per V2 §D.7.2 Considerations
1-3, this content does NOT land in the project-template
trinity:
1. Check 18 H2 within-trinity body parity would fail with a
   Claude-only H3 under a SHARED H2 (would require structural
   CI change).
2. Project-side trinity ships to clients who may or may not use
   Claude; a Claude-only sub-section would create asymmetric
   visibility for Codex / Gemini client teams.
3. The content is informational (runtime convention), not a
   project-team behavioral guardrail — different surface category
   from trinity rules.

METHODOLOGY.md Part 1 → Claude Code CLI sub-section is the
correct surface: informational, per-CLI clearly scoped, no
trinity ripple.

---

## §3 Verification

### §3.1 validate-pack.py

```bash
$ python3 scripts/validate-pack.py 2>&1 | tail -5
── Check 42: CI workflow wires all per-check test files (BD-184) ──
  OK: Check 42 — 10 per-check test file(s) on disk; 10 workflow invocation(s) found; zero unwired tests. CI workflow wiring is complete.

============================================================
PASSED — all checks clean
```

All 43 checks PASS (Checks 1-43, including the Check 43
project-side bare cross-reference scanner from H.14, the
Check 37 project-side pack-only deny-list with the H.13 fence
exemption, and Check 36 commit-scope honesty).

### §3.2 Positive grep — new content presence

**D-11 sub-section heading present:**

```bash
$ grep -nA2 "^### PM chat omniscience obligation" supporting-docs/METHODOLOGY.md
121:### PM chat omniscience obligation
122-
123-The Separation rule above describes the WHAT — who does what
```

**OT-UT-1 `>` callout present:**

```bash
$ grep -nA2 "Claude-only operating convention" supporting-docs/METHODOLOGY.md
84:> **Claude-only operating convention — Agent Teams stage
85-> lifecycle.** When the developer enables Claude Code's Agent
86-> Teams flag (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`),
```

Both inserts are present at the expected line ranges:
- D-11 sub-section: L121-181 (heading + multi-paragraph principle
  + four-bullet list + two-exception block + closing default)
- OT-UT-1 callout: L84-101 (single `>` callout paragraph)

### §3.3 Negative grep — boundary discipline (NO pack-side citations)

**Per V2 §H.16 reviewer focus + salvageability B9:**

```bash
$ grep -nE "pack memory|Tier 1\.5|MEMORY\.md|pack-ops|maintenance-docs" supporting-docs/METHODOLOGY.md | grep -v "^\s*<!--"
(no output)
```

ZERO matches. The inserted text contains no pack-side memory
references, no `pack-ops/` cross-references, no
`maintenance-docs/` cross-references, no "Tier 1.5", no
"MEMORY.md". The principle stands on its own project-side
merits. Boundary discipline preserved per the P-missed-7 trinity
rule.

### §3.4 RC9 manifest regen

`supporting-docs/` is v11-surface per BD-176 (the trigger
expansion that landed after the 2026-05-19 incident at commit
`4120d19`). RC9 requires manifest regen.

```bash
$ bash test-fixtures/build.sh --all --clean 2>&1 | tail -10
[...]
manifest written: /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/test-fixtures/manifest.txt

$ git diff --stat test-fixtures/manifest.txt
 test-fixtures/manifest.txt | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)
```

The 3 v11-* fixture row SHAs drifted as expected per
`test-fixtures/README.md` § Determinism (any v11-surface change
ripples into v11-realistic-ot + v11-flat-file + v11-tracker-on
fixture HEAD SHAs). New v11-* SHAs:
- `v11-realistic-ot`: `52f34126f73a6276bebf68e92f4180f2c169a81c`
- `v11-flat-file`: `825b0061551e621b3b25793f16504609f70747d5`
- `v11-tracker-on`: `0c9bffb0c2e7a9af3bec55312873a9604bdfd20a`

The v10-* fixture rows (`v10-minimal`, `v10-realistic-ot`) and
`existing-project-mid-dev` row are unchanged (tag-pinned /
synthesized; do not drift on v11-surface edits).

`test-fixtures/manifest.txt` is staged in the working tree
alongside the METHODOLOGY.md edit for Pack Chat to commit in
the same commit per the RC9 rule.

### §3.5 Forward-reference closure (success criterion #6)

H.5 landed the V2 §D.2 placement rule at METHODOLOGY.md L1594:

```
### Rule placement: trinity vs PM-CHAT.md vs METHODOLOGY.md

This placement rule is SUBSIDIARY to the PM chat omniscience
obligation (Part 1 — Tool Roles). [...]
```

H.16 lands the referenced "PM chat omniscience obligation"
sub-section in Part 1 at METHODOLOGY.md L121. The two read
consistently:

- §D.2 placement rule cites the omniscience principle as the
  parent rule and the source of "single-source authoritative
  with PM-chat injection-into-agent-prompts as the delivery
  mechanism." This wording matches the §D.6 closing default
  rule: "When in doubt, default to single-source authoritative
  + PM-chat injection. Duplication requires a documented
  exception."
- §D.2 placement rule cites "the documented defense-in-depth
  conditions in Part 1 — Tool Roles (prompt-corruption
  resilience for high-risk rules; cross-CLI parity ergonomics
  until per-CLI injection logic exists)." This matches the
  §D.6 two-exception block's two `**bold-anchored**` bullets
  verbatim.

The H.5 forward-pointer is closed; the §D.2 placement rule
no longer points at a missing sub-section.

---

## §4 Cross-references

| Spec | Anchor | Purpose |
|---|---|---|
| PLAN §H.16 | `maintenance-docs/v11-implementation/PLAN-CLEANUP-BATCH-19C.md` L754-797 | Full H.16 commit spec — insertion anchors, verification commands, commit subject |
| V2 §D.6 | `maintenance-docs/v11-implementation/ARCHITECTURE-CLEANUP-BATCH-19C-V2.md` §D.6 (L776+) | NEW for V2; lands per D-11 Alt-1; principle text rationale |
| V2 §D.6.2 | Same doc §D.6.2 (L790-855) | Verbatim text source for Edit 1 (NEW H3 sub-section content) |
| V2 §D.6.3 | Same doc §D.6.3 (L859-868) | Documented exceptions table — informs the two-exception block in §D.6.2 prose |
| V2 §D.7.3 | Same doc §D.7.3 (L886-916) | Verbatim text source for Edit 2 (`>` callout in `### Claude Code CLI (agents)`) + cross-CLI placement rationale |
| BD-182 §3.1 R3-R7 | `maintenance-docs/v11-implementation/ARCHITECTURE-BD-182.md` L148-152 | TOOL-NEUTRAL enumeration pattern — informs the OT-UT-1 paragraph's three-CLI naming |
| H.5 landed §D.2 placement rule | `supporting-docs/METHODOLOGY.md` L1594-1638 (post-edit line numbers) | Forward-reference closure — H.5 referenced "PM chat omniscience obligation (Part 1 — Tool Roles)"; H.16 lands the referenced sub-section |
| BD-176 v11-surface trigger | `maintenance-docs/v11-implementation/ARCHITECTURE-BD-176.md` + `CLAUDE.md` § "Regenerate test-fixtures/manifest.txt on every v11-surface commit" | RC9 manifest regen rationale — `supporting-docs/` in v11-surface per BD-176 |

---

## §5 Success-criteria checklist

| # | Criterion | Status |
|---|---|---|
| 1 | `python3 scripts/validate-pack.py` — PASS (all 43 checks clean) | PASS (verified §3.1) |
| 2 | New H3 "PM chat omniscience obligation" sub-section present in METHODOLOGY.md Part 1 with V2 §D.6.2 verbatim text + two-exception block | PASS (verified §3.2; L121-181) |
| 3 | New OT-UT-1 `>` callout paragraph present in `### Claude Code CLI (agents)` with V2 §D.7.3 verbatim text naming all three CLIs | PASS (verified §3.2; L84-101) |
| 4 | NO new pack-side references introduced in the new content (no "pack memory" / "Tier 1.5" / "MEMORY.md" / "pack-ops" / "maintenance-docs" tokens in the inserted text outside HTML comments) | PASS (verified §3.3; grep returned no output) |
| 5 | Manifest regen completed; `test-fixtures/manifest.txt` staged if non-empty diff | PASS (verified §3.4; 3 v11-* rows drifted; manifest staged in working tree) |
| 6 | Forward-reference closure: H.5 landed §D.2 placement rule referencing this principle; the new §D.6 sub-section closes that pointer | PASS (verified §3.5; §D.2 at L1594 reads consistently with §D.6 at L121) |

**All 6 success criteria PASS.**

---

## §6 Out-of-scope confirmations

- **No pack-side files touched.** This commit is purely
  `supporting-docs/METHODOLOGY.md` + `test-fixtures/manifest.txt`
  + this new IMPL-REPORT. No `project-template/` trinity files,
  no `pack-ops/` files, no `maintenance-docs/v11-implementation/`
  files except this NEW IMPL-REPORT, no agent definition files.
- **Trinity rule does not apply.** `supporting-docs/METHODOLOGY.md`
  is not a trinity file. The trinity rule (CLAUDE.md / AGENTS.md
  / GEMINI.md must change in parallel) governs the three CLI
  files at pack-root and at `project-template/`; METHODOLOGY.md
  is a single shared document read by PM chats running on any
  of the three CLIs and is intentionally NOT in the trinity.
- **No project-template trinity edits.** Per V2 §D.7.2
  Considerations 1-3, the OT-UT-1 content does NOT belong in
  project-template trinity (would trigger Check 18 H2 parity
  failure; creates asymmetric visibility for non-Claude client
  teams; is informational, not a behavioral guardrail of the
  trinity class). METHODOLOGY.md is the correct surface.
- **No PM-only file edits.** Per `pack-ops/PACK-AGENTS.md`
  PM-only file list: pack-ops/BACKLOG.md, pack-ops/CHANGELOG.md,
  README.md version table, pack-ops/PACK-CHAT.md,
  pack-ops/PACK-AGENTS.md, CLAUDE.md / AGENTS.md / GEMINI.md
  (pack-root), project-template/{CLAUDE,AGENTS,GEMINI}.md.
  None of these are touched by this commit.
- **No state-changing git verbs.** Per the workflow rule
  (CLAUDE.md § "Workflow"), agents NEVER commit. Only
  read-only verbs (`git rev-parse HEAD`, `git status`,
  `git diff`) were used. Pack Chat will stage + commit with
  user approval.
- **Verbatim text from V2 §D.6.2 + §D.7.3.** Both inserts use
  the V2 architect doc's verbatim text — no paraphrasing, no
  abbreviation, no rewording. Per PLAN §H.16's explicit
  "verbatim" requirement.
- **No BD status flip.** Per the workflow rule, BD status flips
  happen post-review at end-of-batch (H.17 per V2 §M.4 + §H.17),
  not during per-commit work.

**Commit-subject scope keyword (per PLAN §H.16):** none (mixed
— supporting-docs/ + maintenance-docs/IMPL-REPORT +
test-fixtures/manifest). Mixed-scope commit; Check 36 will skip
verification.

---

## §7 Files-changed inventory

| File | Change type | Lines touched |
|---|---|---|
| `supporting-docs/METHODOLOGY.md` | Modified | +79 inserted (2 edits: +18 OT-UT-1 callout at L84-101; +61 D-11 sub-section at L121-181) |
| `test-fixtures/manifest.txt` | Modified | +3 / -3 (3 v11-* fixture row SHAs updated per RC9 regen) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.16.md` | NEW | This file |

**Working-tree state at IMPL-REPORT-write time:**

```bash
$ git status --short
 M supporting-docs/METHODOLOGY.md
 M test-fixtures/manifest.txt
?? maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.16.md
```

**HEAD at IMPL-REPORT-write time:** `5958384d49db326a9feba8f74e9f8d8248a52351`
(unchanged from pre-implementation HEAD; agent did not commit
per workflow rule).

Pack Chat actions to land this commit:
1. Spawn `pack-reviewer` (in background, sliding-window scope = this commit's diff only) per V2 Decision 4 (α-sliding) + PLAN §H.16 "Per-commit reviewer: REQUIRED INLINE."
2. Read review report; triage findings.
3. (If findings: spawn fix-coder; commit fix.)
4. Stage `supporting-docs/METHODOLOGY.md` + `test-fixtures/manifest.txt` + this IMPL-REPORT.
5. Commit with subject per PLAN §H.16:
   `feat: v11 — BD-173 METHODOLOGY.md Part 1 — PM chat omniscience principle + Claude Code Agent Teams operating note (Batch 19c.16)`
6. Continue to H.17 (end-of-batch reviewer + BD-173 status flip; single-BD-batch close commit shape).

---

**END IMPL-REPORT**
