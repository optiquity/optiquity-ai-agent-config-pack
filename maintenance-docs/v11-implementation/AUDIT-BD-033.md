# AUDIT-BD-033 — auditor-code "systemic error handling" rule clarity

**Date:** 2026-05-12
**Scope:** Desk-audit of `audit-methodology` rule 16 (auditor-code cluster), the three per-CLI `auditor-code` agent files, and the `error-handling` skill's per-function/systemic partitioning.
**Mode:** Audit-only. No source edits.

---

## §0 One-line summary

Rule 16's systemic threshold *is* quantified ("three or more independent call sites OR crosses module boundaries"), the partition with the `error-handling` skill *is* explicitly tagged at the rule level, and trinity prose between the three CLI files has expected-and-justified asymmetries — but rule 16's own example density is thin and one trinity asymmetry between Claude and Gemini is not tool-specific (it's style-drift). **Verdict: CLEAN WITH NITS.**

---

## §1 Audit scope + methodology

### Files audited (read-only)

- `project-template/skills/audit-methodology/SKILL.md` — rule 16 (primary target), with rules 20/21 read for comparative example-density baselining.
- `project-template/skills/error-handling/SKILL.md` — routing-tag header + 14 numbered rules.
- `project-template/.claude/agents/auditor-code.md` (136 lines).
- `project-template/.codex/agents/auditor-code.toml` (60 lines, prose-in-TOML).
- `project-template/.gemini/agents/auditor-code.md` (119 lines).

### Methodology

1. **Read-only inspection** of rule 16 verbatim, the three CLI agent files, and the `error-handling` skill.
2. **Threshold scenarios** — walked five concrete error-handling situations against rule 16's quantified threshold to test whether an auditor-code agent can decide "systemic vs per-function" without hand-waving.
3. **Trinity diff** — `diff` of Claude vs Gemini auditor-code.md; manual comparison of Codex auditor-code.toml prose against the Markdown variants. Asymmetries classified as tool-specific (justified) or drift (unjustified).
4. **Example-density baseline** — line-count of rules 16, 20, 21 in `audit-methodology/SKILL.md` to test whether rule 16 carries comparable concrete-example weight to its sibling rules of similar audit-cluster scope.

### What was NOT done

- No source edits (audit-only per BD-033 batch contract).
- No live audit against domain code (the pack repo has no Swift/Python domain code — this is the original BD-033 deferral).
- No cross-cutting findings on rules 20 (BD-034) / 21 (BD-032) / PLATFORM-SKILLS (BD-035) — those are surfaced as OBSERVATION-tier where they touched rule 16 reasoning.

---

## §2 Rule 16 verbatim

From `project-template/skills/audit-methodology/SKILL.md` line 44 (a single very long bulleted line in the source):

> **auditor-code** — language-specific code quality, idiom adherence, dead code, unused imports, performance anti-patterns (N+1, blocking main thread, unnecessary allocations in hot paths), concurrency safety (race conditions, missing async handling, incorrect isolation annotations), and systemic error handling (boundary mapping consistency, retry policy uniformity). **Systemic threshold.** A finding is *systemic* when the same divergence or omission appears at three or more independent call sites, OR crosses module boundaries (the same defect in two different services / packages / modules). A single-site instance belongs to per-PR review (the `reviewer` agent), not to auditor-code. When the threshold is met, file once as a systemic finding listing all affected sites, not N separate per-site findings. The boundaries auditor-code audits for mapping consistency are exactly those defined in `error-handling` rule 4 (repository / service / external-API ingress) plus every transport the project uses per `grpc-patterns`, `rest-patterns`, or other loaded protocol skills. A project with multiple transports (e.g., gRPC, REST, message queue) must show consistent mapping across all of them. Per-function error-handling defects (empty catch blocks, swallowed errors, error types that lose context, missing re-raise after log) are language-idiom findings unless they recur at 3+ sites; tag them `[per-function — reviewer]` in the error-handling skill.

---

## §3 Findings

### F1 — Rule 16 packs five distinct audit dimensions into one bulleted line — readability defect (NIT)

**Severity:** NIT
**Evidence:** `project-template/skills/audit-methodology/SKILL.md:44` — single bullet covering (a) idiom adherence, (b) dead code, (c) performance anti-patterns, (d) concurrency safety, (e) systemic error handling, AND the systemic-threshold definition, AND the boundary enumeration, AND the per-function escalation rule.
**Why this matters for BD-033:** the systemic-threshold sentence ("A finding is *systemic* when the same divergence or omission appears at three or more independent call sites, OR crosses module boundaries...") is itself crisp and quantified — but it's buried mid-paragraph after four other audit dimensions. An auditor-code agent reading rule 16 has to parse out the systemic clause from a wall of prose. Comparison with rule 20 (auditor-ui) shows rule 20 was structurally expanded with sub-bullets and an explicit "Cross-platform UI checklist" sub-section — rule 16 was not given the same treatment.
**Recommended disposition:** Add concrete example(s) to rule 16 — specifically, lift the systemic-threshold definition into its own sub-section with a header (e.g., "**Systemic threshold.**" already exists as bold text but is not paragraphed off), and add 2–3 worked examples adjacent to it (see §5 for candidate scenarios). The threshold language itself does NOT need to change.

---

### F2 — "Independent call sites" is undefined — minor ambiguity (NIT)

**Severity:** NIT
**Evidence:** `audit-methodology/SKILL.md:44` — phrase: "three or more independent call sites." Two questions an auditor-code agent could ask without an unambiguous answer:
1. If the same `mapTransportError(...)` helper is called from 5 places but the helper itself does the wrong mapping in one branch, is that 5 sites (calls) or 1 site (the helper)?
2. If a per-package error-mapping convention is duplicated by copy-paste across 3 sibling packages with byte-identical implementations, is that 3 sites or 1 (the same convention, replicated)?
**Why this matters:** the threshold is quantified (3 sites), but the unit of count is not. Two reasonable auditor-code agents could disagree and produce different finding counts on the same codebase.
**Recommended disposition:** Add concrete example(s) to rule 16 — define "independent call site" as "a distinct file:symbol pair where the defect is materially decided" (i.e., the helper-with-bad-branch counts as 1 site at the helper, not N at the callers; copy-pasted-across-3-packages counts as 3 because each package owns its own implementation that could independently be fixed). This is a count-threshold clarification, not a structural change.

---

### F3 — `error-handling` skill routing tags are present but uneven — partial coverage (NIT)

**Severity:** NIT
**Evidence:** `project-template/skills/error-handling/SKILL.md` lines 25–46. Of 14 numbered rules:
- 8 carry `[systemic — auditor-code]` (rules 1, 2, 3, 4, 8, 9, 10, 11, 12)
- 4 carry `[per-function — reviewer]` (rules 5, 7, 13, partial 6)
- 1 carries BOTH tags (rule 6 — "structured logging on boundary error" is systemic for cross-boundary uniformity, per-function for single-site application)
- 1 untagged (rule 14 — explicitly tagged `*(meta — no routing tag)*` because it points to platform skills)

This is actually well-structured for routing. The NIT is that rule 6's dual tag is the only worked example of "this rule has both systemic and per-function aspects" — a future skill maintainer might not know whether to dual-tag a new rule or pick one.
**Recommended disposition:** No change needed. The routing tags do exactly what BD-033 originally feared the skill *might* lack ("consider whether the error-handling skill needs systemic rules split from per-function rules"). The split exists. Document the dual-tag pattern only if a second dual-tagged rule emerges.

---

### F4 — Rule 16 example density is materially lower than rules 20 and 21 (SHOULD-FIX)

**Severity:** SHOULD-FIX
**Evidence:** Comparing line counts in `audit-methodology/SKILL.md`:
- Rule 16 (auditor-code): 1 line (line 44 — single very long bulleted paragraph)
- Rule 20 (auditor-ui): 7 lines (lines 48–54 — main paragraph + 4-bullet "Cross-platform UI checklist" + skip-condition)
- Rule 21 (auditor-ops): 4 lines (lines 55–58 — main paragraph + "Boundary clarification" sub-section)

Rules 20 and 21 carry sub-sectioned worked examples (rule 20's checklist; rule 21's "Boundary clarification — observability code in source files" with side-by-side code examples). Rule 16's "Systemic threshold." sub-section is bold-prefixed inside the paragraph, with no worked example of "here's a 2-site case (per-function) vs a 3-site case (systemic)."
**Why this matters for BD-033:** the original deferral asked exactly this question — does rule 16 give an auditor enough to act on? Compared to its sibling rules of similar audit-cluster weight, the answer is *barely* — the threshold language is quantified, but lacks the sub-sectioned worked examples that rules 20/21 use to operationalize their similarly-abstract scope language.
**Recommended disposition:** Add concrete example(s) to rule 16 — specifically two or three worked examples illustrating the 3-site count threshold AND the cross-module scope threshold (see §5 for candidate scenarios). This brings rule 16 to the same example-density floor as rules 20/21.

---

### F5 — Trinity drift: Claude auditor-code.md is verbose, Gemini is condensed, and the difference is NOT provably tool-specific (SHOULD-FIX)

**Severity:** SHOULD-FIX
**Evidence:** `diff project-template/.claude/agents/auditor-code.md project-template/.gemini/agents/auditor-code.md`:
- Claude version: 136 lines.
- Gemini version: 119 lines.
- Differences in **scope/threshold/output-policy/hard-rules prose** are condensations only — same semantic rules, shorter wording. Examples:
  - Claude `Permission profile` is 7 lines; Gemini is 4 lines (drops "modifying source, configs, tests, generated code, or any file other than the report path is a defect").
  - Claude `Output policy` includes a sentence about the parent reply ("The reply you return to the calling auditor parent may briefly summarize the report and point at the file path"); Gemini omits it.
  - Claude `Hard rules` enumerate the full git verb list inline; Gemini abbreviates it.
- **Justified asymmetries** (provably tool-specific, per Trinity rule):
  - Claude frontmatter `tools: Read, Grep, Glob, Bash, Write, Edit` (Claude-tool-specific).
  - Gemini frontmatter `model: gemini-2.5-pro`, `temperature: 0.2`, `max_turns: 30` (Gemini-tool-specific).
  - Codex `.toml` wrapper format with `developer_instructions = """..."""` (Codex-format-specific).
- **Unjustified asymmetries** (style drift, not tool-specific):
  - Permission-profile prose verbosity.
  - Output-policy "parent reply" sentence.
  - Hard-rules verb-list inlining vs abbreviation.

**Why this matters for BD-033:** the trinity rule says symmetry is the default and asymmetry requires justification. None of the prose-condensation differences are provably Gemini-specific — they're just shorter wording for the same rules. An auditor-code agent on Gemini will operate from slightly less detailed permission/output rules than the same agent on Claude, with no documented reason.
**Recommended disposition:** No change needed *for BD-033 scope* (the prose drift doesn't change the systemic threshold). But surface as OBSERVATION-tier for a future trinity-sweep pass — either condense Claude to match Gemini, or expand Gemini to match Claude. The Codex `.toml` is closer to Gemini's condensed form, suggesting the original design intent was the shorter wording. **This finding is in scope for BD-033 only because §4 trinity discipline is required by the BD-033 audit dimensions — the fix itself is out of BD-033 scope.**

---

### F6 — Rule 16 boundary enumeration overlaps and may conflict with auditor-architecture (OBSERVATION)

**Severity:** OBSERVATION
**Evidence:** Rule 16 says "boundary mapping consistency" is auditor-code's concern, with boundaries = "exactly those defined in `error-handling` rule 4 (repository / service / external-API ingress) plus every transport the project uses." But rule 35 (ownership precedence) says *architecture violations win over code idiom* for layer-shaped findings. A repository/service boundary is a layer seam.
**Possible reading 1:** auditor-architecture audits whether the *seam exists at all and is the right shape*; auditor-code audits whether *the error-mapping behavior at the seam is uniform across all instances of the seam*. This is consistent.
**Possible reading 2:** "boundary mapping consistency" could be read as a layer-shape finding (the boundary is in the wrong place / has the wrong contract) → would route to auditor-architecture.
**Why this is OBSERVATION not SHOULD-FIX:** the auditor-code.md file's `## Out of scope` section already says "Layer-boundary violations — auditor-architecture (per rule 35, architecture wins over code idiom for layer-shaped findings)." This implicitly resolves the ambiguity in favor of reading 1. So the routing IS correct in the agent files even if rule 16 itself doesn't spell it out.
**Recommended disposition:** No change needed. Cross-cutting with BD-032 (auditor-ops) territory — the same kind of boundary-clarification sub-section that rule 21 has ("Boundary clarification — observability code in source files") could be added to rule 16 for the architecture-vs-code-mapping seam, but this is a polish item, not a clarity defect.

---

## §4 Trinity discipline check (auditor-code across .claude / .codex / .gemini)

| Aspect | Claude (.md) | Codex (.toml) | Gemini (.md) | Verdict |
|---|---|---|---|---|
| File format | Markdown w/ YAML frontmatter | TOML w/ prose in `developer_instructions` triple-quoted string | Markdown w/ YAML frontmatter | Asymmetry justified — Codex format is tool-fixed |
| Frontmatter contents | `name`, `description`, `tools` | `name`, `description`, `model`, `approval_policy`, `sandbox_mode`, `model_reasoning_effort` | `name`, `description`, `model`, `temperature`, `max_turns` | Asymmetry justified — each CLI's frontmatter schema is tool-specific |
| `## Scope` body (5 bullets including systemic + per-function) | 47 lines, fully detailed | 8 lines (compact prose, same content) | 47 lines, fully detailed (matches Claude) | OK — Codex condenses for TOML readability; Claude/Gemini match |
| `## Out of scope` | 4 bullets | 4 bullets (compact) | 4 bullets | OK |
| `## File scope` | 5 lines | 4 lines | 5 lines | OK |
| `## Output` | 5 lines | 2 lines (compact) | 5 lines | OK |
| `## Skills to load` | 4 lines | 2 lines (compact) | 4 lines | OK |
| `## Permission profile` | **7 lines** (verbose with rationale) | 1 line (compact) | **4 lines** (condensed, omits rationale clause) | **Drift between Claude and Gemini** — see F5 |
| `## Output policy` | **8 lines** (includes "parent reply" sentence) | 5 lines | **6 lines** (omits "parent reply" sentence) | **Drift between Claude and Gemini** — see F5 |
| `## Hard rules` git-verbs section | Full enumeration with inline rationale | Abbreviated single line | Abbreviated 2-line form | **Drift between Claude and Gemini** — see F5 |
| Semantic rules (what the agent does) | Identical | Identical | Identical | OK — no behavioral drift |

**Verdict:** Trinity is **semantically aligned** (all three agents will produce the same audit findings on the same codebase) but **prose-drifted** between Claude and Gemini in three sections. The drift is not tool-specific. This is the pattern flagged in F5 — surface but defer fix to a future trinity-sweep BD.

---

## §5 Threshold scenarios walked through

For each scenario, the call is what an auditor-code agent should do given rule 16 verbatim. These are the worked examples missing from rule 16 that F1+F2+F4 recommend adding.

### Scenario 1 — single empty `except` in one Python repository class

```python
# server/src/repositories/user_repository.py
async def get_user(self, user_id: str) -> User | None:
    try:
        row = await self._db.fetch_one("SELECT ...", user_id)
        return User.from_row(row)
    except Exception:
        pass  # ← empty catch
```

**Sites:** 1. **Cross-module:** No.
**Call:** Per-function defect — out of scope for auditor-code under rule 16. Belongs to the `reviewer` agent at PR time per `error-handling` rule 5 `[per-function — reviewer]`. Auditor-code does NOT file.

---

### Scenario 2 — same empty `except` pattern repeated in 3 Python repositories

Same defect as Scenario 1, but appears in `user_repository.py`, `order_repository.py`, and `inventory_repository.py`.

**Sites:** 3 (independent symbols in 3 distinct files). **Cross-module:** Borderline — all 3 are in `server/src/repositories/`, same package.
**Call:** SYSTEMIC under the count threshold (3 ≥ 3 sites). Auditor-code files ONE finding listing all three sites, severity Major (per `audit-methodology` rule 8 — "systemic error-handling inconsistencies" is named under Major). Recommended action: introduce a shared error-mapping convention at the repository base class.

---

### Scenario 3 — gRPC service maps `Status.UNAVAILABLE` to `DomainError.serviceDown`, but the REST adapter maps the equivalent HTTP 503 to a different `DomainError.unknown`

Two sites, same logical defect, different transports.

**Sites:** 2. **Cross-module:** Yes — gRPC adapter and REST adapter are different transport packages.
**Call:** SYSTEMIC under the cross-module clause ("OR crosses module boundaries — the same defect in two different services / packages / modules"). Even though count is below 3, the cross-module trigger is independent. Auditor-code files one Major finding citing both adapters, recommends unifying retryable-vs-non-retryable taxonomy across transports per rule 16's "A project with multiple transports must show consistent mapping across all of them."

---

### Scenario 4 — retry policy: write path uses `maxAttempts=3` with linear backoff; read path uses `maxAttempts=5` with exponential backoff

This is by-design per `error-handling` rule 12 ("Make retry behavior configurable per operation type. A read may retry more aggressively than a write.").

**Sites:** 2 (write retry, read retry). **Cross-module:** No.
**Call:** NOT a finding. Rule 12 explicitly licenses per-operation-type variation. Auditor-code does NOT file. (This scenario tests false-positive risk — without rule 12, an auditor might incorrectly flag the variation as inconsistency.)

---

### Scenario 5 — a single helper `mapGrpcStatus(_:) -> DomainError` is called from 8 sites; the helper itself omits one status mapping (drops `Status.deadlineExceeded` to default `.unknown`)

The defect lives in 1 implementation, surfaced at 8 call sites.

**Sites:** Per F2's recommended definition of "independent call site," this is **1 site** (the helper symbol is where the defect is materially decided — fixing the helper fixes all 8 callers). **Cross-module:** No.
**Call:** Per-function defect at the helper — out of scope for auditor-code, belongs to reviewer. **But** if rule 16 doesn't define "independent call site" (which it currently doesn't — see F2), an auditor could legitimately call this 8 sites and file as systemic. This is the ambiguity F2 surfaces.

---

## §6 Overall verdict

**CLEAN WITH NITS.**

Rule 16 *does* meet BD-033's original ask — the systemic threshold IS quantified (3 sites OR cross-module), and the partition between auditor-code and reviewer IS explicitly tagged in the `error-handling` skill (rule-by-rule routing tags). The deferral hypothesis ("the threshold is not quantified") is *factually false* against the current rule 16 — which is the result of work done in v11 since the BD was filed.

What's still imperfect:
- **F1 (NIT):** rule 16 is a single dense paragraph; the systemic-threshold sub-section deserves the same paragraph-and-sub-section treatment rules 20 and 21 received.
- **F2 (NIT):** "independent call site" needs a one-sentence definition to prevent auditor-disagreement on the helper-vs-callers count.
- **F4 (SHOULD-FIX):** rule 16 lacks worked examples; rules 20 and 21 carry them. Adding 2–3 examples (Scenarios 1–3 from §5 are good candidates) brings rule 16 to parity.
- **F5 (SHOULD-FIX, scope-deferred):** trinity prose drift between Claude and Gemini auditor-code agent files is real but doesn't affect behavior; surface to a future trinity-sweep BD (cross-cutting with BD-032 and BD-034 if those find the same drift in auditor-ops.md and auditor-ui.md).

None of these are BLOCKER-tier. The auditor-code agent can act on rule 16 today; the recommended fixes raise it from "acts correctly with mild risk of disagreement at edges" to "acts correctly with no ambiguity."

