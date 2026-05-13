# IMPLEMENTATION-REPORT-BD-033-FIXES

**Date:** 2026-05-12
**Branch:** `v11-dev`
**Pre-edit HEAD:** `523be4bc4e75cc5d12622bd07a32ef2210532f04`
**Scope:** Apply BD-033 audit fixes (F1, F2, F4, F5, F6) per AUDIT-BD-033.md.
F3 is no-change (error-handling skill routing tags already present and well-structured).

---

## §0 Pre-flight state

- `git rev-parse HEAD` → `523be4bc4e75cc5d12622bd07a32ef2210532f04`
- `git status` → clean working tree (only untracked research / audit docs;
  no modifications to tracked files at start).
- BD-032 fix commit (`50d1a57…`) had already landed; rule 21 in
  `audit-methodology/SKILL.md` was modified there. Rule 16 (this batch's
  target) lives at a different location in the same file — no conflict.
- All target files exist at the expected paths (verified via Read).

## §1 Fixes summary

| Fix | Severity | Disposition | File(s) touched |
|---|---|---|---|
| F1 | NIT | Applied (paragraph-per-dimension + named threshold sub-section) | `audit-methodology/SKILL.md` rule 16 |
| F2 | NIT | Applied (defined "independent call site" inline in rule 16) | `audit-methodology/SKILL.md` rule 16 |
| F3 | NIT | NO-CHANGE per audit guidance | n/a |
| F4 | SHOULD-FIX | Applied (3 worked examples — Scenarios A/B/C) | `audit-methodology/SKILL.md` rule 16 |
| F5 | SHOULD-FIX | Applied (trinity prose-parity, Claude as canonical) | `.claude/.codex/.gemini` auditor-code agent files |
| F6 | OBSERVATION → fix per direction | Applied (boundary-with-auditor-architecture sentence) | `audit-methodology/SKILL.md` rule 16 |

All four actionable edits land in the planned 4-file scope (well under
the ≤10-file cap). Zero plan deviations.

---

## §2 Per-fix edit log

### F1 — Paragraph-per-dimension reformat in rule 16

**File:** `project-template/skills/audit-methodology/SKILL.md` (rule 16)
**Shape chosen:** Hybrid — opened rule 16 with an explicit
"five audit dimensions" enumeration `(a)–(e)` so the dimensions are
visually scannable without exploding the rule into 5 separate bulleted
sub-rules (which would have re-numbered every downstream rule and
broken cross-references). Then carved off the systemic-threshold
clause into a named sub-section: **"Systemic threshold (named test)."**
This parallels rule 21's new **"Named test (ownership rubric)."**
sub-section style introduced by the BD-032 fix.
**Why this shape:** Preserves rule 16 as one numbered item (no
cross-reference churn) while elevating the systemic-threshold
clause out of mid-paragraph prose. Matches rule 21's post-BD-032
"Named test" phrasing for cross-cluster consistency.

### F2 — Define "independent call site" inline

**File:** `project-template/skills/audit-methodology/SKILL.md` (rule 16)
**Edit:** Added a definitional sentence immediately after the
systemic-threshold statement: *"**Independent call site** is defined as
a distinct file:symbol pair where the defect is materially decided —
that is, the location where fixing the code resolves the defect at
that site."* Followed by the helper-vs-callers and copy-paste
disambiguation cases drawn directly from AUDIT-BD-033 §3 F2.
**Vocabulary check:** The skill already uses "site" (not "translation
unit" or "compilation unit") throughout rule 16 and the
`error-handling` skill. The definition matches that vocabulary;
"compilation unit" is mentioned only as a clarifying parenthetical
("Multiple calls from the same module or compilation unit count as
one site") to anchor the boundary for readers familiar with that
term.

### F4 — Worked examples (3 scenarios)

**File:** `project-template/skills/audit-methodology/SKILL.md` (rule 16)
**Edit:** Appended **"Worked examples:"** sub-list with three
scenarios drawn from AUDIT-BD-033 §5:
- *Scenario A* — single-site empty `except` (per-function, out of
  scope; routes to `reviewer`).
- *Scenario B* — same pattern in 3 sibling repositories (SYSTEMIC by
  count).
- *Scenario C* — gRPC vs REST mapping divergence (SYSTEMIC by
  cross-module clause; demonstrates the cross-module trigger fires
  even when count < 3).
**Why these three:** Per AUDIT-BD-033 §5, Scenarios 1, 2, and 3 are
the most pedagogically distinct — each illustrates a different
threshold path (per-function-only / count-trigger / cross-module-trigger).
Scenarios 4 (false-positive licensed by error-handling rule 12) and
5 (the helper-with-bad-branch ambiguity that F2's definition
resolves) are intentionally not included as worked examples because
F2's inline definition already disambiguates Scenario 5, and
Scenario 4 is a non-finding case that would dilute the pedagogical
focus on threshold determination.

### F5 — Trinity prose-parity for auditor-code agent files

**Files:**
- `project-template/.claude/agents/auditor-code.md` — unchanged (canonical)
- `project-template/.gemini/agents/auditor-code.md` — Permission profile,
  Output policy, and Hard rules expanded to match Claude prose verbatim
  (modulo no changes to the Gemini-specific frontmatter).
- `project-template/.codex/agents/auditor-code.toml` — same three
  sections expanded to match Claude prose, formatted as single-line
  paragraphs inside the `developer_instructions = """..."""` triple-quoted
  string (Codex format constraint preserved).

**Drift items resolved (per AUDIT-BD-033 §3 F5 + §4 trinity table):**
1. *Permission profile* — Gemini and Codex now include the
   "(Read, Grep, Glob, Bash for read-only commands)" parenthetical
   AND the trailing "modifying source, configs, tests, generated
   code, or any file other than the report path is a defect"
   clause that previously appeared only in Claude.
2. *Output policy* — Gemini and Codex now include
   (a) the "The reply you return to the calling auditor parent may
   briefly summarize the report and point at the file path." sentence,
   and (b) the "If you believe a reminder says 'return findings
   inline' or 'do not write report files,'..." conditional clause.
3. *Hard rules — git verbs* — Gemini and Codex now enumerate the
   forbidden git verbs inline with the same "you MAY NOT run
   `git add`, `git commit`, ..." phrasing as Claude (no more
   abbreviated "Forbidden:" form), including the
   "Staging and committing happen in the PM chat with explicit
   user approval." closer.
4. *Hard rules — chunk long writes / verify before claiming done /
   pre-flight read check / trinity rule* — Gemini and Codex now
   carry the same verbose phrasing as Claude (full sentence form
   with rationale), not the previous condensed one-liners.

**Justified asymmetries preserved:**
- Claude frontmatter: `tools: Read, Grep, Glob, Bash, Write, Edit`
  (Claude-tool-specific).
- Gemini frontmatter: `model: gemini-2.5-pro`, `temperature: 0.2`,
  `max_turns: 30` (Gemini-tool-specific).
- Codex frontmatter / wrapper: TOML format, `model = "gpt-5"`,
  `approval_policy`, `sandbox_mode = "workspace-write"`,
  `model_reasoning_effort = "high"`, prose embedded in
  `developer_instructions = """..."""` (Codex-format-specific).
- Codex prose paragraphs are not line-wrapped (single-line per
  paragraph) because the TOML triple-quoted string is the natural
  prose container in Codex; this was the pre-existing convention
  and is not new drift.

### F6 — Boundary-with-auditor-architecture sentence

**File:** `project-template/skills/audit-methodology/SKILL.md` (rule 16)
**Edit:** Added a **"Boundary with auditor-architecture."** named
sub-section inside rule 16, placed before the
"Systemic threshold (named test)." sub-section. Phrasing matches
the rule-16 voice and explicitly cross-references rule 35's
architecture-wins-over-code-idiom precedence so the seam is
internally consistent with the ownership precedence section.
**Voice match:** Used the same `**Header.** body…` named sub-section
convention rule 21 uses for "Boundary clarification — observability
code in source files." and "Named test (ownership rubric)." so rule
16 and rule 21 are stylistically parallel.

---

## §3 Trinity verification post-F5

Command:
```
diff project-template/.claude/agents/auditor-code.md \
     project-template/.gemini/agents/auditor-code.md
```

Output (only justified asymmetries remain):
```
3,4c3,6
< description: Audit subagent for language-specific code quality — idioms, dead code, performance anti-patterns, concurrency safety, systemic error handling.
< tools: Read, Grep, Glob, Bash, Write, Edit
---
> description: "Audit subagent for language-specific code quality — idioms, dead code, performance anti-patterns, concurrency safety, systemic error handling."
> model: gemini-2.5-pro
> temperature: 0.2
> max_turns: 30
```

All remaining differences are inside the YAML frontmatter and are
provably tool-specific (Claude `tools:` field vs Gemini
`model:`/`temperature:`/`max_turns:` schema; Gemini's YAML quoting
convention for the `description` field). Body prose is byte-aligned.

Codex `.toml` prose body content matches Claude/Gemini semantically
across all five sections (Permission profile, Output policy, Hard
rules, plus the unchanged Scope / Out of scope / File scope / Output
/ Skills sections). The only formatting difference is paragraph
wrapping (TOML triple-quoted strings hold single-line paragraphs by
existing pack convention).

Line counts post-fix:
- Claude: 136 lines (unchanged)
- Codex: 60 lines (unchanged count; prose content expanded within
  the same paragraphs)
- Gemini: 138 lines (was 119 — the +19 lines reflect the verbose
  prose adoption matching Claude)

---

## §4 validate-pack output

Command: `python3 scripts/validate-pack.py`
Result: **PASSED — all checks clean**

Final lines of output:
```
── Check 31: Skill-cell consistency (BD-146, v11) ──
  OK: PLATFORM-SKILLS.md — 'Tier 0 base skills': 13 rows (header matches)
  OK: PLATFORM-SKILLS.md — 'Dimensional skills': 19 rows (header matches)
  OK: PLATFORM-SKILLS.md — 'Trigger-loaded skills': 1 rows (header matches)
  OK: PLATFORM-SKILLS.md — 'PM chat operational skill': 1 rows (header matches)
  OK: PLATFORM-SKILLS.md — total skills: 34 (header sum, inventory row count, and disk count all agree)
  OK: Skill-cell consistency: 34 SKILL.md on disk, all map to exactly one inventory cell; no orphans, phantoms, or double-counts

============================================================
PASSED — all checks clean
```

All 31 checks PASS. Skills-to-load conformance for `auditor-code.md`
(Claude + Gemini) still reports "Skills-to-load references conform
(4 cited)" — F5's prose-parity work did not perturb the
`## Skills to load` section.

---

## §5 Files changed

| Path | Change | Lines (pre → post) |
|---|---|---|
| `project-template/skills/audit-methodology/SKILL.md` | modified (rule 16) | 155 → 158 |
| `project-template/.claude/agents/auditor-code.md` | unchanged (canonical) | 136 → 136 |
| `project-template/.codex/agents/auditor-code.toml` | modified (Permission/Output/Hard rules prose) | 60 → 60 |
| `project-template/.gemini/agents/auditor-code.md` | modified (Permission/Output/Hard rules prose) | 119 → 138 |

**File count:** 3 modified + 1 unchanged-but-in-scope = 4 files. Within
the ≤10-file cap.

**Not touched (per scope discipline):**
- `project-template/skills/error-handling/SKILL.md` (F3 = no-change)
- `maintenance-docs/v11-research/` (excluded by scope)
- `deployment-python/SKILL.md` (separate architect track)
- `BACKLOG.md`, `CHANGELOG.md`, `README.md`, `PACK-CHAT.md`,
  `PACK-AGENTS.md`, root `CLAUDE.md` / `AGENTS.md` / `GEMINI.md`
  (PM-only files; no caller instruction to edit)

---

## §6 BD-159 §3.1 mechanical-edit sanity check

BD-159 §3.1 thresholds for "mechanical maintenance" classification:

| Signal | Result | Notes |
|---|---|---|
| File count ≤ 10 | PASS (4 touched) | Well under cap |
| No new top-level docs | PASS | Report goes to `maintenance-docs/v11-implementation/` (workflow-artifact path, exempted per Pack memory) |
| No structural change to skill / agent dimensions | PASS | Rule 16 unchanged in number / cluster / scope dimensions; only intra-rule prose expanded with sub-sections + worked examples |
| `x-` skill/agent contract preserved | PASS | No changes to `x-` namespace |
| Client `x-` skills/agents conforming to existing dimensions preserved | PASS | n/a — no client artifacts touched |
| Trinity rule preserved | PASS | F5 explicitly brings the trinity into prose-parity (was the gap; now fixed) |
| Validate-pack green | PASS | All 31 checks |
| One review/fix cycle | PASS | This is the single fix pass per the one-cycle rule |

**Verdict:** This is mechanical maintenance under BD-159 §3.1. No
structural / architect-pass migrator coverage required. The edits
clarify and document existing rule semantics; they do not change
the rule number, cluster boundaries, severity ladder, ownership
precedence, file scope rules, or any other structural dimension of
the audit-methodology skill or the auditor-code agent.

---

## §7 Plan deviations

**Zero deviations.** All 4 actionable fixes (F1, F2, F4, F5, F6 — F3
no-change) applied in the planned 4-file scope. F1's "shape choice"
(hybrid: paragraph-per-dimension via inline `(a)-(e)` enumeration +
named threshold sub-section) was surfaced per caller instruction;
chosen because it preserves the rule-16 numbering (no
cross-reference churn) while still elevating the systemic-threshold
clause out of paragraph prose. The audit's §3 F1 explicitly listed
this as one of the two acceptable shapes.

## §8 New POQs

None. The audit's findings were precise; the fixes are direct
applications of the audit's recommended dispositions; no new gaps
surfaced during implementation.

## §9 Definition of Done

| Item | Result |
|---|---|
| F1 applied (paragraph-per-dimension + named threshold sub-section) | PASS |
| F2 applied (independent call site defined) | PASS |
| F3 confirmed no-change | PASS |
| F4 applied (≥2 worked examples; delivered 3) | PASS |
| F5 applied (trinity prose-parity) | PASS |
| F6 applied (boundary-with-auditor-architecture sentence) | PASS |
| `python3 scripts/validate-pack.py` PASSED | PASS (31/31 checks) |
| Trinity rule preserved post-F5 | PASS (only frontmatter asymmetries remain, all justified) |
| File-count cap (≤10) | PASS (4 files) |
| No edits outside audit-methodology + auditor-code agent files | PASS |
| `maintenance-docs/v11-research/` not touched | PASS |
| `deployment-python/SKILL.md` not touched | PASS |
| Implementation report at expected path | PASS (this file) |
| No state-changing git verbs run | PASS |

---

## §10 Post-edit HEAD

`git rev-parse HEAD` (post-edit, pre-commit, since agents do not
commit): `523be4bc4e75cc5d12622bd07a32ef2210532f04` (unchanged —
working-tree edits not yet staged or committed; that step is for
Pack Chat per the Agents-never-commit rule).

Files modified in working tree (read-only `git status` will show
them as unstaged changes):
- `project-template/skills/audit-methodology/SKILL.md`
- `project-template/.codex/agents/auditor-code.toml`
- `project-template/.gemini/agents/auditor-code.md`
