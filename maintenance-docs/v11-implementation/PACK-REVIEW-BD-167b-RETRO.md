# PACK-REVIEW-BD-167b-RETRO

Retroactive per-BD review of BD-167b (Commit 19b-PM of Batch 19,
per-entry split, PM-only edits). Commit SHA `8ba0164`. Pack-Chat-direct
PM-only edits (22 files); evaluates whether Pack Chat correctly applied
the architect-doc bindings from
`maintenance-docs/v11-implementation/PLAN-PER-ENTRY-SPLIT-BATCH-19.md`
§5.3,
`maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md`
§6.4,
`maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md`
§1.1 / §1.4 / §3.1 / §3.3 / §3.4, and
`maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2.md`
§1.

## §1 — Summary

BD-167b ships exactly the 22 PM-only file edits enumerated in
PLAN-PER-ENTRY-SPLIT-BATCH-19.md §5.3 with high fidelity to the
architect-doc bindings: pack-root trinity Key files block extended with
the `/backlog/`, `/changelog/` per-entry-tree pointer plus the verbatim
Addendum #1 §3.4 mode-aware pack-memory bullet; project-template trinity
"Document locations" table clarified with a per-entry-source suffix and
a new "Per-entry source-of-truth trees (v11.0)" paragraph; PACK-AGENTS.md
"PM-only files" block reshaped into "PM-only files and directories" with
separate Files/Directories subsections, supporting-file taxonomy
paragraph, pack-coder exception clause, and the honest Signal-9 framing
from Addendum #1 §3.1 (no "refactor not expansion" wording survives);
and all 15 pack-* agent files (5 agents × 3 CLIs) gain identical
`/backlog/_rules.md` and `/changelog/_rules.md` "Inputs to read"
bullets, with the 5 Codex `.toml` files placing the addition inside
their `developer_instructions` triple-quoted strings per Addendum #2
§1.4. All five Codex TOML files parse via `tomllib`; `validate-pack.py`
passes; the trinity rule is honored at both pack-root and
project-template levels. No out-of-scope files were touched (no
STATUS.md, no PM-CHAT.md, no scripts/, no maintenance-docs/,
no project-template/docs/pack/). Zero MUST findings, zero SHOULD
findings, three NIT findings — all minor wording / formatting
observations that do not impair correctness.

## §2 — Findings

### MUST findings

None.

### SHOULD findings

None.

### NIT findings

**N1 — Addendum #1 §3.4 verbatim text uses "+" connector; trinity files use "and".**

- Files: `CLAUDE.md` line 167, `AGENTS.md` line 144, `GEMINI.md` line 125.
- Binding:
  `maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md`
  §3.4 line 619–620 sample bullet says
  `\`tracker.toml\` with \`mode.state = "tracker"\` + \`migration.forward_complete = true\``
  (using "+" as connector). All three implementation trinity files use
  the prose form
  `\`tracker.toml\` with \`mode.state = "tracker"\` and \`migration.forward_complete = true\``
  (using "and").
- Severity rationale: NIT. The prompt's "Verbatim wording fidelity"
  check explicitly permits "minor formatting adaptation." The "+" → "and"
  substitution preserves semantic equivalence and reads more naturally
  in narrative prose. Symmetrically applied across all three trinity
  files (no asymmetry introduced).
- Proposed fix (optional): either restore the literal "+" connector to
  match §3.4 verbatim, OR update §3.4 to track the "and" prose form
  Pack Chat actually adopted (the latter is more maintainable since
  prose-narrative reading favors "and"). No action required if the
  current text is intentional.

**N2 — PACK-AGENTS.md supporting-file taxonomy paragraph re-orders the list relative to PLAN §5.3 spec.**

- File: `PACK-AGENTS.md` lines 159–163.
- Binding: PLAN-PER-ENTRY-SPLIT-BATCH-19.md §5.3 row for PACK-AGENTS.md
  says: "`_rules.md` / `_intro.md` / `_format.md` / `_v8-resolved-archive.md`
  are pack-shipped immutable". The implementation says "`_rules.md`,
  `_intro.md`, `_v8-resolved-archive.md`, and `_format.md` are
  pack-shipped immutable" — `_v8-resolved-archive.md` and `_format.md`
  swapped order.
- Severity rationale: NIT. The set of names is identical; the
  enumeration order is editorial. The implementation order groups the
  pack-side-only file (`_v8-resolved-archive.md`) before the
  project-side-only file (`_format.md`), which arguably reads more
  consistently with the directory enumeration above (pack `/backlog/`
  + `/changelog/` listed before project-template trees). No defect.
- Proposed fix (optional): keep current order; no change recommended.

**N3 — Pack root trinity references `_rules.md` paths that do not yet exist at pack root (forward-pointing references).**

- Files: `CLAUDE.md` line 34
  ("`/backlog/`, `/changelog/` — per-entry source-of-truth trees (read
  `/backlog/_rules.md` and `/changelog/_rules.md` for the per-stream
  contract; …)"); same content in `AGENTS.md` line 28 and `GEMINI.md`
  lines 23–25; same forward references in the 15 pack-* agent files
  (e.g., `.claude/agents/pack-architect.md:28–29`); same in
  `PACK-AGENTS.md` lines 143–144 + 151–153.
- Binding: PLAN-PER-ENTRY-SPLIT-BATCH-19.md §2.3 explicitly documents
  that "The pack-self per-entry trees `/backlog/` and `/changelog/` are
  NOT created at Batch 19. They are created at Batch 23 (BD-102
  dog-food)." Plan §10.1 R-1 acknowledges this. Verified by
  `ls /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/backlog`
  → "No such file or directory" (only the project-template trees exist
  per BD-167). So a pack agent that reads any of these prompts today
  and naively tries to `Read /backlog/_rules.md` will hit a
  file-not-found.
- Severity rationale: NIT. This is by design per the architect/plan
  binding — the discoverability references are evergreen and become
  valid at Batch 23 dog-food. Between Batch 19 (now) and Batch 23,
  pack agents may transiently confuse themselves with the
  forward-pointing references, but no validator check is broken
  (`validate-pack.py` Check 34 in `scripts/validate-pack.py`
  function `check_cross_reference_integrity` only scans entry files
  inside present per-entry trees, not trinity / agent files).
- Proposed fix (optional): a one-line "Pack-self trees land at Batch
  23 — references are forward-pointing until then" parenthetical
  could be added in PACK-AGENTS.md alongside the Signal 9 paragraph
  to avoid pack-agent reader confusion. Not required; the design is
  intentional. Acceptable to leave as-is and let Batch 23
  retroactively make the references resolvable.

## §3 — Verification

Commands executed and results:

```
$ git show 8ba0164 --stat | tail -1
22 files changed, 168 insertions(+), 18 deletions(-)
```
Confirms exactly 22 files — matches PLAN §5.3 spec.

```
$ git diff-tree --no-commit-id --name-only -r 8ba0164 | sort
.claude/agents/pack-architect.md
.claude/agents/pack-coder.md
.claude/agents/pack-docs-researcher.md
.claude/agents/pack-planner.md
.claude/agents/pack-reviewer.md
.codex/agents/pack-architect.toml
.codex/agents/pack-coder.toml
.codex/agents/pack-docs-researcher.toml
.codex/agents/pack-planner.toml
.codex/agents/pack-reviewer.toml
.gemini/agents/pack-architect.md
.gemini/agents/pack-coder.md
.gemini/agents/pack-docs-researcher.md
.gemini/agents/pack-planner.md
.gemini/agents/pack-reviewer.md
AGENTS.md
CLAUDE.md
GEMINI.md
PACK-AGENTS.md
project-template/AGENTS.md
project-template/CLAUDE.md
project-template/GEMINI.md
```
6 trinity (3 pack-root + 3 project-template) + 1 PACK-AGENTS.md +
15 pack-* agent (5 Claude .md + 5 Codex .toml + 5 Gemini .md) = 22.
Out-of-scope filter: no `STATUS*`, no `PM-CHAT*`, no `scripts/`, no
`maintenance-docs/`, no `project-template/docs/pack/`. Clean.

```
$ python3 -c "import tomllib; …"
OK: .codex/agents/pack-architect.toml (keys: ['name', 'description',
    'model', 'approval_policy', 'sandbox_mode', 'model_reasoning_effort',
    'developer_instructions'])
OK: .codex/agents/pack-coder.toml (…same keys…)
OK: .codex/agents/pack-docs-researcher.toml (…same keys…)
OK: .codex/agents/pack-planner.toml (…same keys…)
OK: .codex/agents/pack-reviewer.toml (…same keys…)
```
All 5 Codex .toml files parse cleanly per Addendum #2 §1.4 contract.
The `developer_instructions = """…"""` triple-quoted strings contain
the BD-167b additions without breaking TOML well-formedness.

```
$ python3 scripts/validate-pack.py 2>&1 | tail -3
============================================================
PASSED — all checks clean
```
All 35 checks pass post-BD-167b. Checks 32 / 33 / 34 (per-entry
mirror / TOC / cross-ref integrity) SKIP gracefully when
`/backlog/` and `/changelog/` are not present per integration parent
§10.5 — matching Plan §2.3 and §10.1 R-1 expectations.

Per-file content checks:

```
$ for f in 15-pack-agent-files; do
    grep -q "/backlog/_rules.md" $f && grep -q "/changelog/_rules.md" $f
  done
```
All 15 pack-* agent files (5 Claude × 5 Codex × 5 Gemini) carry both
the `/backlog/_rules.md` and `/changelog/_rules.md` references per
Addendum #1 §1.4 / Addendum #2 §1.3.

```
$ grep "refactor in shape\|Signal 9 trip" PACK-AGENTS.md
PACK-AGENTS.md:173: This addition is a Signal 9 trip per
```
PACK-AGENTS.md uses honest "Signal 9 trip" framing per Addendum #1
§3.1; the original §6.4 "refactor in shape, not an expansion in
semantics" wording does NOT appear in the implementation. The
Signal-9 paragraph correctly cites
`ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` §3.2 line 305–306;
verified that lines 305–306 of that doc state "PM-only file
expansion: Any addition to the agents-never-modify list or the
PM-only file list in PACK-AGENTS.md" (the architect-pass-trigger
Signal 9 definition).

```
$ grep -n "/\.backlog/\|/\.changelog/" trinity-files PACK-AGENTS.md
(no matches)
```
No dot-prefixed paths (`/.backlog/`, `/.changelog/`) survive — all
references correctly use the post-Addendum-#1-§10 non-dot form per
the architect-doc binding.

Trinity content equivalence checks:

- Pack-root trinity (CLAUDE.md / AGENTS.md / GEMINI.md): all three
  carry the substantive Key files extension and the
  `Per-entry trees vs mirrors — mode-dependent source of truth`
  pack-memory bullet under `### Repo conventions` as the FIRST
  bullet. CLAUDE.md and AGENTS.md use bulleted Key-files form;
  GEMINI.md uses compact paragraph form per the existing
  CLAUDE/AGENTS-verbose-vs-GEMINI-compact trinity convention.
- Project-template trinity (project-template/CLAUDE.md / AGENTS.md /
  GEMINI.md): byte-substantively identical Document-locations table
  row clarification and "Per-entry source-of-truth trees (v11.0)"
  paragraph. The diffs at lines 224 / 229–237 (CLAUDE.md), 208 /
  213–221 (AGENTS.md), 219 / 224–232 (GEMINI.md) match across all
  three files modulo line-number offsets caused by prior content
  differences. Project-template trinity correctly does NOT receive
  the pack-memory bullet (pack-memory is pack-self only per Plan
  §5.3 row).

## §4 — Out-of-scope observations

These are observations beyond BD-167b's scope. No deferral framing —
each is either a pre-existing condition outside BD-167b or a
heads-up for downstream batches that need the same retroactive
review.

**O1 — `.gemini/agents/pack-planner.md` references "CLAUDE.md (pack repo rules)" instead of "GEMINI.md".**
Pre-existing in the file before BD-167b (verified via
`git show 8ba0164^:.gemini/agents/pack-planner.md`). BD-167b only
added the two new `_rules.md` bullets; the CLAUDE.md vs GEMINI.md
reference is inherited from the prior commit. Not a BD-167b
defect; would be a finding for whatever earlier commit introduced
the gemini-side asymmetry. Same observation applies to
`.gemini/agents/pack-reviewer.md` (which had no pre-existing
"Inputs to read" block and got a fresh one from BD-167b — the new
block correctly references only the new `_rules.md` paths and does
not re-introduce a CLAUDE.md-vs-GEMINI.md mismatch).

**O2 — Pack agent trinity (Check 11 / `compare-agent-trinity.py`) does not cover the 5 pack-* agents.**
`scripts/compare-agent-trinity.py` (function `_list_all_agents`
checked at line ~194) scans `project-template/.claude/agents/`,
not `.claude/agents/`. So the BD-167b edits to the 15 pack-*
agent files (which are at `.claude/agents/`, `.codex/agents/`,
`.gemini/agents/` at pack root) are not validated for trinity
symmetry by Check 11. This is a coverage gap in Check 11 unrelated
to BD-167b but worth noting because BD-167b is exactly the kind of
multi-CLI parallel edit that the trinity check should gate. Plan
§5.3 acknowledges this by calling for "Pack Chat verifies via
`diff`-like inspection or grep parity" — i.e., manual verification
substitutes for Check 11 here. The 15 pack-* agent file
substantive content was confirmed by per-file grep (Section 3
verification) to be equivalent across the three CLI variants. If
Check 11 were extended to cover pack-* agents, the addition would
strengthen future trinity gating.

**O3 — Forward-pointing references resolve at Batch 23, not Batch 19.**
Per Plan §2.3 and §10.1 R-1, all `/backlog/_rules.md` references in
the trinity, PACK-AGENTS.md, and pack-* agent prompts will point at
real files only after Batch 23 (BD-102 dog-food) decomposes the
pack-self `BACKLOG.md` and `CHANGELOG.md` into per-entry trees. The
intermediate window (Batch 19 → Batch 23) ships discoverability
references that pack agents may try to read and find missing. This
is by design — Plan §2.3 explicitly lists the post-Batch-23 catch-up
as the intended resolution. No fix required in BD-167b; surfaced
here as awareness for any reviewer or pack-agent operator who
encounters file-not-found between batches.

**O4 — STATUS.md disclaimer moved to BD-169 (PM-CHAT.md) per R-3 Option A.**
The original integration parent §5.3 named STATUS.md as a
discoverability surface; Plan §10.3 R-3 resolved this Pack-Chat-direct
to Option A (PM-CHAT.md kickoff guidance), which lands in BD-169
(Commit 19g-pack). BD-167b correctly did NOT touch STATUS.md. The
disclaimer surfacing is downstream-batch work; BD-169's per-BD
review will need to verify it lands correctly. No action for
BD-167b.
