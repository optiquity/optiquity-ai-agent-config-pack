# ARCHITECTURE — Boundary prevention mechanisms (BD-175 Phase 2 / Architect C)

**Author:** pack-architect (Architect C of Phase 2 trio)
**BD:** BD-175 (CODE RED emergency batch)
**Phase:** 2 (DESIGN — structural prevention mechanisms only; A and B handle re-litigation and directory architecture respectively)
**Date:** 2026-05-18
**Branch:** v11-dev
**Inputs read:** `AUDIT-PACK-PROJECT-BOUNDARY-VIOLATIONS.md`, `AUDIT-USER-CURATION.md`, `ORCHESTRATION-PLAN-BD-175.md`, plus pack-repo trinity / PACK-AGENTS.md / pack-agent definitions / project-agent prompts / `scripts/validate-pack.py` / `.github/workflows/validate-pack.yml`
**Inputs NOT read (per prompt out-of-scope):** Architect A's `ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md`, Architect B's `ARCHITECTURE-DIRECTORY-REORGANIZATION.md`, the 19c-stream artifacts (CLEANUP, STRATEGIC-PRINCIPLES, G-VERIFICATIONS, PATH-C-CURATION)

---

## §0 — Scope boundary with Architects A and B

This document designs **forward-looking structural prevention**. It does NOT:

- Re-litigate any of the 13 audit findings (Architect A's domain)
- Specify new directory homes for relocated files, the formal boundary definition (G7), or its discoverability surface (SC8) — Architect B's domain
- Touch existing contamination at HEAD (Architect A drives revert/replace/justify decisions)

It DOES design how Pack Chat, pack agents, project agents, reviewers, implementers, and CI prevent the regression patterns from recurring in v11.1+, v12, and beyond.

Several prevention mechanisms have **conditional shape** depending on Architect B's output (the formal boundary definition + new directory homes). Those conditionals are flagged inline with the surface variable they depend on (e.g., `B.BOUNDARY_DEF_PATH`) and surfaced in §10 as Phase 3 reviewer concerns.

---

## §1 — The regression mechanism this design prevents

The audit identifies a single regression mechanism with two halves:

**Mechanism (audit ORCHESTRATION-PLAN §1 P6, AUDIT §C TYPE-1/2/4 findings):**

A review/fix cycle on a project-side file (or a file mis-located in a project-side directory) produces a finding ("this rule is missing", "this cross-reference is stale", "this enumeration is incomplete"). The reviewer's first instinct — and the implementer's first instinct on receiving the finding — is to reach for the pack-side mechanism they know (`PACK-AGENTS.md` roster, `maintenance-docs/` design doc, `pack-architect` agent, Pack Chat orchestrator) and import it into the project-side file. Neither actor pauses to ask: "Is there a project-side SSOT for this concept that I should be reading or augmenting instead?"

The result is **TYPE-2 contamination** (pack-side mechanism imported into project-side content) or **TYPE-4 contamination** (project-side file cross-references pack-only path that does not exist at client install).

The meta-cause is **P-missed-7** (user articulation, captured in `AUDIT-USER-CURATION.md` §5 and Architect-C-paraphrased here): *project and pack are intentionally designed differently. When making project-side changes, investigate project-side SSOT first; do not default to pack-style mechanisms. Pack-style thinking is a bias that's doomed to fail and should never be the first choice.*

**Symptom catalog from audit:**
- TYPE-1 (scope mix): batch claimed pack-only but edits leaked into `project-template/` or `supporting-docs/` (V2, V10 partial)
- TYPE-2 (content import): pack-only file reference inserted into project trinity by a review-fix commit (V1)
- TYPE-3 (symmetric scope mix): pack-side modified during project-only batch (0 confirmed — included for symmetry)
- TYPE-4 (cross-reference): project-side file references pack-only path that breaks at client install (V3, V4, V5, V6, V7, V8 cluster; 17 confirmed contamination refs)
- TYPE-5 (structural mirror): project-side content mirrors pack-side structure without independent project rationale (T5-A, T5-B; root cause of TYPE-2)

**Density observation from audit §G:** All 17 confirmed contaminations cluster in 6 files. Five of those six are pack-only-by-content but located in project-side directories — confirming that the regression is driven as much by file mis-location (Architect B's domain) as by reviewer/implementer behavior (this architect's domain).

---

## §2 — Design philosophy (three load-bearing premises)

**Premise 1 — Prevention is layered, not single-point.** No single mechanism catches every regression. The audit's 13 findings entered through three distinct mechanisms: scope drift in batch boundaries (TYPE-1), reviewer/implementer behavior in review/fix cycles (TYPE-2), and stale/incorrect references that survive multiple commits (TYPE-4). Each needs its own prevention layer — process gate, prompt guardrail, automated check.

**Premise 2 — Codify behavior at the surface that triggers it.** P-missed-7 belongs in every actor surface that is positioned to default to pack-style mechanisms: the reviewer-protocol surface (catches the finding), the implementer-prompt surface (catches the fix), the Pack-Chat-triage surface (catches the framing), and the trinity Pack memory section (catches the cross-actor universal). Codification in one place only is insufficient — the actor reading their own surface must encounter the rule before they form the wrong instinct.

**Premise 3 — CI catches what process can't.** Process gates depend on actors observing them. CI gates run mechanically every push. Where the regression pattern can be expressed as a structural property (no project-side file references `PACK-AGENTS.md`, no project-side file references `maintenance-docs/` path, no commit subject claiming pack-only scope touches `project-template/`), it belongs in CI. Where it cannot (a project-side rule mirrors pack-side rationale without independent justification — a TYPE-5 semantic check), it belongs in process with explicit acknowledgment of the gap.

The audit revealed that existing CI (Trinity Check 18 H2 parity) verifies *wording matches* but not *rule correctness for the surface it lives on*. Extending Check 18 to substance-checks is one consideration (§9); but the larger insight is that the trinity rule is a **symmetry rule, not a correctness rule** — it ensures the three CLIs see the same content, but it does not ensure the content is right for the trinity it lives on (pack-root trinity vs project-template trinity). Substance-correctness is the new rule layer this architecture introduces.

---

## §3 — Prevention coverage matrix (the master table)

Each row maps a violation type from audit §C → the prevention mechanism(s) designed in §4–§9 → the surface where the mechanism attaches → the measurable test (success criterion 6).

| Audit TYPE | Mechanism(s) | Surface(s) where attached | Measurable test |
|---|---|---|---|
| **TYPE-1** (scope mix: pack-only batch touches project-side) | M1a Pack-Chat batch-scope gate; M1b commit-message scope declaration; M5a CI commit-scope check | Pack Chat memory + PACK-CHAT.md; pack-coder + fix-coder prompts; `scripts/validate-pack.py` Check 36 (proposed) | Failed prevention shape: a commit whose subject claims pack-only scope but `git diff --name-only` includes `project-template/` or `supporting-docs/`. Test: commit a deliberate violation in a branch test fixture; CI Check 36 must fail with file-path callout |
| **TYPE-2** (pack-bias content added to project-side file) | M2 P-missed-7 codification in trinity Pack memory; M3a SSOT-investigation step in reviewer protocol; M3b SSOT-investigation step in implementer prompt; M4 boundary-investigation skill | Trinity Pack memory; pack-reviewer agent + `.claude/skills/review/SKILL.md`; pack-coder agent + project coder.md prompt; new `boundary-investigation` skill loaded by reviewers + coders | Failed prevention shape: review report recommends adding pack-only file reference to project-side file without explicit "investigated project-side SSOT" line item; OR implementer commits the fix without same line item in IMPL-REPORT |
| **TYPE-3** (symmetric: pack-side touched during project-only batch) | M1a Pack-Chat batch-scope gate (symmetric); M5a CI commit-scope check (symmetric) | Same as TYPE-1 | Symmetric: commit subject claims project-only scope but diff includes pack-only paths |
| **TYPE-4** (project-side cross-references pack-only file) | M5b CI grep gate on project-side files; M3a/b SSOT-investigation gate; M6 reviewer-prompt SSOT-rotation reminder | `scripts/validate-pack.py` Check 37 (proposed); pack-reviewer + coder prompts | Failed prevention shape: a commit touching `project-template/` or (post-Architect-B) the new project-side directories introduces a literal reference to any pack-only file/path in the **deny-list** (`PACK-AGENTS.md`, `PACK-CHAT.md`, `maintenance-docs/`, `HELP-FRAGMENT-PACK.md`, pack-* agent names, `Pack Chat` capitalized as orchestrator-role, etc.); CI must fail with file:line + offending pattern |
| **TYPE-5** (project-side mirrors pack-side without independent rationale) | M2 P-missed-7 codification; M7 SSOT-divergence test in reviewer-protocol amendment; M8 trinity rule substance-extension consideration | Trinity Pack memory; reviewer-protocol amendment; trinity rule | Mechanically impossible to detect via grep (requires semantic understanding of "independent rationale"). Compensating control: M7 is a reviewer-protocol gate — reviewer must positively assert "this project-side rule has independent project-design rationale that does not reduce to 'because the pack does it'" or flag as a TYPE-5 finding. Test: stage a deliberate TYPE-5 violation (e.g., a project-side trinity rule lifted from pack-side trinity) into a review run; reviewer must surface as a finding |

Notes on coverage:

- TYPE-1 and TYPE-3 share infrastructure (commit-scope check is symmetric).
- TYPE-2 and TYPE-5 share the cognitive root (P-missed-7); the prevention surfaces overlap.
- TYPE-4 is the one type with strong mechanical detectability (grep against deny-list); the most leverage per unit of CI work lands here.
- TYPE-5 is acknowledged as not-mechanically-detectable; the compensating manual gate is explicit (M7) rather than left as an unspoken hope.

---

## §4 — Mechanism M2: P-missed-7 codification

**Goal (orchestration-plan SC5):** P-missed-7 codified in a location accessible to all relevant actors.

**Recommended canonical home: trinity Pack memory section** (`/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md` and parallel `AGENTS.md` / `GEMINI.md`) under a new bullet in the existing `### Workflow` or new `### Boundary discipline` subsection — Architect-B and Architect-C-conditional decision (see §10 conditional dependency).

**Rationale for canonical home choice:**
- The trinity Pack memory is read by EVERY pack agent at session start (per `PACK-AGENTS.md` § "Agent behavior expectations" item 1).
- The trinity Pack memory already hosts the closest analogues (`feedback-deferral-is-scope-creep`, `feedback-no-deferral-without-user-direction`, the separate-pack-ops-from-pack-product bullet) — P-missed-7 fits the same pattern (cognitive bias → standing rule).
- Memory-cache index (Tier 1.5) already points to trinity as authoritative; adding a `feedback-pack-bias-doomed-to-fail` pointer extends an existing pattern.

**Proposed bullet text (for Architect B / Pack-Chat / user review before mechanical coder pass):**

```
- **P-missed-7 — project-side investigation precedes pack-style defaults.**
  Project and pack are intentionally designed differently. When making
  ANY change to a project-side file (project-template/ trees, project-
  shipped content), an actor (reviewer, implementer, Pack Chat triage)
  MUST first investigate whether a project-side SSOT exists for the
  concept being changed. Pack-style mechanisms (PACK-AGENTS.md roster,
  Pack Chat orchestrator role, pack-* agent names, maintenance-docs/
  design records) are PACK-ONLY by construction — they do not exist at
  client install, they do not govern project behavior, and importing
  them into project-side files is a regression that breaks at client
  install or pollutes project-design intent. The default instinct
  "reach for the pack mechanism I know" is bias, not a starting point.
  Investigate the project-side SSOT FIRST. Worked examples of the
  failure mode this rule prevents: BD-175 audit V1 (project trinity
  acquired PACK-AGENTS.md reference via a review-fix commit when the
  project-side SSOT was docs/pack/PM-CHAT.md), V3 (project-side
  PLATFORM-SKILLS.md acquired PACK-AGENTS.md reference instead of
  pointing at PM-CHAT.md), V4 (project-side methodology doc became
  pack-internal by drift).
```

**Codification surfaces (defense in depth — same rule restated for each actor's first-encounter surface):**

| Actor | Surface | Treatment |
|---|---|---|
| All pack agents | Trinity Pack memory section (canonical) | Full text per bullet above |
| Pack Chat | PACK-CHAT.md operating rules + memory cache index | Pointer entry: `feedback-pack-bias-doomed-to-fail` |
| pack-reviewer | `.claude/agents/pack-reviewer.md` agent definition + `.claude/skills/review/SKILL.md` skill | One-line reference + protocol step (see M3a §5) |
| pack-coder | `.claude/agents/pack-coder.md` agent definition | One-line reference + IMPL-REPORT line item (see M3b §5) |
| project-side reviewer | `project-template/docs/pack/prompts/reviewer.md` standard variant | Ninth review dimension + rotation reminder (see M6 §7) |
| project-side coder | `project-template/docs/pack/prompts/coder.md` standard + fix-cycle variants | Pre-implementation SSOT-investigation step (see M3b §5) |
| Project trinity | `project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md` `## Project memory` section | Project-side mirror rule (see §4.2 below) |

### §4.2 — Project-side mirror of P-missed-7

The audit's TYPE-2 / TYPE-4 / TYPE-5 patterns can recur in client repos too — a project's PM Chat or reviewer can introduce inappropriate pack-style mechanisms into client project content. The mirror rule for project-side trinity is **shorter and inverted** (project trinity does not need to know about Pack Chat; it needs to know that PROJECT-side SSOT is the starting point for any project-side change):

```
- **Project SSOT-first.** When making any change to a project file
  (architecture, BACKLOG, agent prompt, skill content, etc.),
  investigate the existing project SSOT for that concept FIRST.
  Do not default to importing rules, file references, or orchestrator
  roles from external sources (the AI Agent Config Pack repo itself,
  third-party templates, other projects). Pack-shipped files installed
  in this project (e.g., docs/pack/PM-CHAT.md, docs/pack/PLATFORM-
  SKILLS.md) are part of the project SSOT and may be referenced.
  Files at the pack repo (PACK-AGENTS.md, PACK-CHAT.md, pack-*
  agent prompts, pack-repo maintenance-docs/) are NOT part of the
  project SSOT and must not be referenced from project files —
  the pack repo is not present at this client install.
```

This mirror lives under `## Project memory` in the project-template trinity. It is part of the prevention layer because the same regression pattern can enter client projects via the same review/fix mechanism that infected the pack-shipped trinity.

**Measurable test for M2:** Stage a deliberate omission in a candidate commit that removes the P-missed-7 bullet. Trinity Check 18 H2 parity should fail (the section heading is missing from one of the three trinity files). Beyond CI, a Pack Chat actor reading the trinity should hit the bullet before forming the wrong instinct in a review/fix cycle.

---

## §5 — Mechanism M3: SSOT-investigation gates in reviewer + implementer prompts

**Goal (orchestration-plan SC5 + success criterion 3 + 4):** Reviewer protocol amendment addresses the entry mechanism; agent prompt guardrails address the implementer side.

### §5.1 — M3a: reviewer SSOT-investigation protocol amendment

The audit's entry mechanism (`ORCHESTRATION-PLAN-BD-175.md` §1 paragraph 3) names the reviewer as half of the contamination chain: "neither reviewer nor implementer investigated project-side SSOT before defaulting to pack-style mechanisms."

**Amendment to `project-template/docs/pack/prompts/reviewer.md` standard variant** — add a ninth review dimension after the existing eight:

```
9. **Boundary discipline (P-missed-7)** —
   For every recommended change that adds, modifies, or removes a rule,
   reference, or enumeration in a project-side file (any file in
   project-template/ trees, any file shipped to client repos): before
   recommending the change, investigate whether a project-side SSOT
   for the concept exists.
   - If a project-side SSOT exists, recommend the change cite or
     augment that SSOT — not a pack-side equivalent.
   - If no project-side SSOT exists and the project-side file genuinely
     needs the rule, flag a deferred design question rather than
     importing the pack-side mechanism: "no project-side SSOT for
     <concept>; project-design rationale needed before recommending
     content."
   - If the change involves cross-referencing a file outside the
     installed-at-client-repos surface (PACK-AGENTS.md, maintenance-
     docs/, pack-* agent names, Pack Chat orchestrator role), the
     recommendation is FAIL by construction — that reference will
     break at client install. Recommend project-side equivalent
     instead (or recommend NO reference, with rationale).
   Output per finding under this dimension explicitly names which
   project-side SSOT was investigated (file path + relevant section)
   or explicitly states "no SSOT exists for <concept>".
```

**Amendment to `.claude/skills/review/SKILL.md`** — add a new top-level review priority "0" (positioned BEFORE correctness — boundary discipline is a precondition for the rest of the review being meaningful):

```
0. **Boundary discipline** — if reviewing a change to a file that
   ships to client repos (project-template/ or any pack-shipped
   directory), verify the change does NOT introduce references to
   pack-only files, pack-only mechanisms, pack-* agent names, or
   the Pack Chat orchestrator role. If it does, the finding is
   blocking. See trinity Pack memory P-missed-7 for the underlying
   rule and worked examples.
```

(Note: the project-side review skill is the project's `.claude/skills/review/` — distinct from the pack-side review skill loaded by `pack-reviewer`. Both need the dimension; trinity rule extension across CLI variants applies.)

**Measurable test for M3a:** Stage a synthetic review-target commit that recommends adding "see PACK-AGENTS.md" to a project-side file. Run pack-reviewer against it. Pack-reviewer output MUST include a dimension-9 (or priority-0) finding flagging the recommendation as boundary-violation. If pack-reviewer passes the commit without flagging, the prompt is broken.

### §5.2 — M3b: implementer SSOT-investigation pre-implementation step

The reviewer-side gate (M3a) catches recommendations before they land. The implementer-side gate (M3b) catches fixes BEFORE the implementer applies them — important because, in pack memory's per-BD fix cycle pattern, the reviewer's findings flow to a fix-coder who is a fresh agent without the reviewer's framing.

**Amendment to `.claude/agents/pack-coder.md`** — add to the `# Before executing` section:

```
### Boundary discipline pre-flight (P-missed-7)

If any of your scoped edits touch a file in any of these surfaces
(project-template/ trees, supporting-docs/ — pending Architect B's
relocation decision —, or any other pack-shipped-to-client surface),
before making the edit:

1. Identify whether a project-side SSOT exists for the concept being
   changed. Common project-side SSOTs include:
   - docs/pack/PM-CHAT.md (agent roster, PM chat operating rules)
   - docs/pack/PLATFORM-SKILLS.md (skill matrix)
   - docs/pack/PACK-FEEDBACK.md (project-to-pack feedback channel)
   - project trinity (CLAUDE.md/AGENTS.md/GEMINI.md universal rules)
2. If your edit would add a reference to a pack-only file (PACK-
   AGENTS.md, PACK-CHAT.md, maintenance-docs/, pack-* agents, etc.):
   STOP. Report in your IMPL-REPORT under "Boundary discipline
   stop" with: (a) the proposed edit, (b) the pack-only target, (c)
   the project-side SSOT that should be used instead, (d) request
   re-prompting from Pack Chat with the corrected reference target.
3. Document the SSOT investigation in your IMPL-REPORT under a new
   required section "Boundary discipline check": for each project-
   side file edit, name the project-side SSOT investigated (or
   "no SSOT exists for <concept> — implementing per Pack Chat's
   prompt with no SSOT augmentation").

This pre-flight is non-negotiable for project-side edits. It mirrors
the trinity Pack memory P-missed-7 rule and the pack-reviewer
dimension-9 / priority-0 gate.
```

**Amendment to `project-template/docs/pack/prompts/coder.md` standard variant** — add to the Constraints block:

```
- **Boundary discipline (P-missed-7):** If any task in your scope
  would modify a file shipped to client repos (project-template/
  content, agent prompts, skills) AND the modification adds, changes,
  or removes a reference to a rule, role, or file path, then BEFORE
  applying the change: investigate whether the project's SSOT for
  that concept supports the change. Project SSOTs include:
  docs/pack/PM-CHAT.md, docs/pack/PLATFORM-SKILLS.md, the project
  trinity files at project root, and any project-side architecture/
  methodology document at docs/project/ or docs/reference/. If the
  change would introduce a reference to a file outside the project
  (e.g., a pack-repo file like PACK-AGENTS.md or pack-repo maintenance-
  docs/), STOP and report the situation in your completion report
  under "Boundary discipline stop" — do not improvise a fix.
```

The project-coder mirror is shorter because (a) project-side coders rarely have explicit pack-only file references on their radar and (b) the rule is fail-stop, not a procedural amendment.

**Measurable test for M3b:** Spawn pack-coder against a synthetic fix-cycle prompt instructing it to add "see PACK-AGENTS.md" to a project trinity file. Pack-coder MUST emit a "Boundary discipline stop" line in its IMPL-REPORT and refuse to make the edit. If pack-coder makes the edit, the prompt is broken.

---

## §6 — Mechanism M4: boundary-investigation skill (new pack skill)

**Goal:** Concentrate the SSOT-investigation methodology into a single skill loaded by every actor whose work could trigger the regression. Single canonical home for the methodology; agent prompts reference the skill by name instead of duplicating the methodology in N places.

**New skill: `boundary-investigation`** (proposed path: `.claude/skills/boundary-investigation/SKILL.md`, with parallel `.codex/skills/` and `.gemini/skills/` versions per the existing pack-skill trinity convention).

**Skill content sketch (full text drafted by mechanical coder per planner sequencing; this architect provides the canonical surface, not the prose):**

```
---
name: boundary-investigation
description: Use when reviewing or implementing any change to a project-side file (project-template/ trees or pack-shipped content) before recommending or applying the change. Codifies P-missed-7 — project-side SSOT investigation precedes pack-style defaults.
allowed-tools: Read, Grep, Glob
---

# Boundary investigation

## When this skill applies

This skill applies to any session whose scope includes a change to:
- `project-template/` (any file)
- `supporting-docs/` (pending Architect B's relocation decision)
- (post-Architect-B) any new project-side directory

It does NOT apply to changes to pack-only files (pack-repo root trinity,
`PACK-*.md`, `maintenance-docs/`, `scripts/`, `test-fixtures/`, the pack-
repo `.claude/`/`.codex/`/`.gemini/` dotted dirs at repo root).

## Methodology (run BEFORE recommending or applying a change)

1. **Identify the concept being changed.** What rule, reference,
   enumeration, or role is the proposed change adding, modifying, or
   removing? Name the concept in plain language.

2. **Locate the project-side SSOT for the concept.** Search the
   project-side surface for an existing source of truth:
   - `project-template/docs/pack/PM-CHAT.md` — agent roster, PM chat
     orchestration rules
   - `project-template/docs/pack/PLATFORM-SKILLS.md` — skill selection
     matrix
   - `project-template/docs/pack/PACK-FEEDBACK.md` — project-to-pack
     feedback channel
   - `project-template/CLAUDE.md`/`AGENTS.md`/`GEMINI.md` — universal
     project rules
   - `project-template/docs/pack/prompts/<agent>.md` — per-agent prompt
     templates
   - Project-side skills (`project-template/skills/<skill>/SKILL.md`)

3. **Decide the SSOT-relative action:**
   - **SSOT exists, change is aligned:** recommend/apply the change as
     an augmentation to the SSOT (cite SSOT, edit SSOT, or reference
     SSOT — never duplicate).
   - **SSOT exists, change conflicts:** flag the conflict; do NOT
     apply. Surface to Pack Chat for re-design.
   - **No SSOT exists, change is needed:** flag the gap; do NOT
     improvise. Surface to Pack Chat for "needs project-design
     rationale".
   - **No SSOT exists, change is not needed:** drop the change.

4. **NEVER cross-reference pack-only paths from project-side files.**
   The pack-only deny-list (illustrative, not exhaustive; Architect B's
   directory architecture refines):
   - File names: `PACK-AGENTS.md`, `PACK-CHAT.md`, `HELP-FRAGMENT-PACK.md`,
     `HELP-FRAGMENT-TRACKER.md`, `OPTIONAL-FEATURES.md` (current root
     location; Architect B may relocate)
   - Path prefixes: `maintenance-docs/`, `scripts/` (pack-repo only —
     project-side scripts live at `project-template/scripts/`),
     `test-fixtures/`
   - Agent names: `pack-architect`, `pack-coder`, `pack-planner`,
     `pack-reviewer`, `pack-docs-researcher`
   - Role names: `Pack Chat` (capitalized as orchestrator role; lower-
     case "pack chat" describing the feedback flow in PACK-FEEDBACK.md
     is LEGITIMATE per audit §D-4)

5. **Document the investigation in the deliverable:**
   - Reviewer: under review dimension 9 finding, name the project-side
     SSOT investigated.
   - Implementer: under IMPL-REPORT "Boundary discipline check"
     section, name the project-side SSOT investigated per project-side
     edit.

## Worked example (BD-175 V1 anti-pattern)

The pack reviewer flagged that the project trinity agent enumeration
was missing the 7 auditor variants. The reviewer's recommendation was
"add: see PACK-AGENTS.md for the full roster." This skill would have
caught the recommendation in step 4 (pack-only deny-list match on
PACK-AGENTS.md) and redirected to step 2 (project-side SSOT is
docs/pack/PM-CHAT.md:47 § "Pack agent roster"). The corrected
recommendation: "trinity says: see docs/pack/PM-CHAT.md § 'Pack
agent roster'" — which is the project-side SSOT, present at every
client install.
```

**Skill loading wiring (per `PACK-AGENTS.md` § "Skills loaded by pack agents" table):**

| Agent | Skill load addition |
|---|---|
| `pack-reviewer` | Add `boundary-investigation` |
| `pack-coder` | Add `boundary-investigation` |
| `pack-architect` | Add `boundary-investigation` (architects designing project-side surfaces hit the same trap) |
| `pack-planner` | Add `boundary-investigation` (planners sequencing project-side work hit the same trap) |
| `pack-docs-researcher` | Add `boundary-investigation` (researchers auditing project-side content for v11.1+ work hit the same trap) |

The skill loads for ALL pack agents because all five may be invoked against project-side surfaces.

**Project-side skill trinity:** The skill ALSO ships to `project-template/.claude/skills/boundary-investigation/` and `.codex/` / `.gemini/` parallels — project-side coders / reviewers / architects / planners working in client repos hit the same regression mechanism in their own workflows. (This is Trinity Pack memory's "Repo conventions — Skill and agent maintenance is mechanical by default" pattern: the skill is the methodology, agent prompts reference it, both pack-side and project-side surfaces get the same skill loaded.)

**Measurable test for M4:** After M4 lands, both pack-reviewer and pack-coder regression tests (proposed; see §11) include a synthetic boundary-violation prompt and assert the skill's methodology was applied (IMPL-REPORT / review-report mentions the SSOT-investigation step). A baseline gold-image of the skill content is checked into `test-fixtures/` for byte-identity testing (parallels Check 31 skill-cell internal-consistency gate).

---

## §7 — Mechanism M6: SSOT-rotation reminder

The audit's V1 finding describes how the pack-side reviewer authored a recommendation that the implementer applied without question. The reviewer's framing (familiar with pack-side mechanisms) leaked into a project-side file through an implementer who didn't independently investigate. This is the **frame contagion** problem: an actor's mental model of "we're working on pack stuff right now" stays sticky across a session that involves both pack-side and project-side files.

**M6 — SSOT-rotation reminder in reviewer prompts:**

Add to the reviewer-protocol-amendment from M3a, as a final paragraph under the dimension-9 instruction:

```
**Frame-rotation reminder:** When reviewing a commit or batch that
touches BOTH pack-side and project-side files, mentally rotate frames
between pack-side and project-side reviews. The same review dimension
(e.g., "rule is missing", "cross-reference is stale") has different
correct answers depending on which side the file lives on. Pack-side
correct answer: cite pack-side SSOT (CLAUDE.md / PACK-AGENTS.md /
maintenance-docs/). Project-side correct answer: cite project-side
SSOT (docs/pack/PM-CHAT.md / docs/pack/PLATFORM-SKILLS.md / project
trinity). The bias to import the framing from the earlier-reviewed
side into the later-reviewed side is real; the SSOT investigation
step (P-missed-7) is the explicit antidote.
```

Same reminder appears in pack-coder fix-cycle prompts (where the implementer is touching one file at a time but may have a multi-finding fix batch spanning both sides).

**Measurable test for M6:** Mixed-side review test fixture (synthetic commit touching both pack-side and project-side files with parallel "missing rule" patterns); reviewer report must address each side with the appropriate-side SSOT (no cross-import).

---

## §8 — Mechanism M5: CI / automated checks

**Goal (orchestration-plan SC5 + success criterion 5):** CI checks added where mechanically possible. For checks that aren't mechanically possible, explicit note of why + what compensating manual or process control covers the gap.

### §8.1 — M5a: Check 36 — commit-scope honesty (catches TYPE-1 + TYPE-3)

**Behavior contract:**

For every commit on every push, parse the commit subject for scope claims and compare against `git diff --name-only` for that commit. Scope claims and their permitted file-prefix surfaces:

| Subject keyword pattern | Permitted touched paths |
|---|---|
| Subject contains literal `pack-only` (case-insensitive) | Only pack-only paths (deny `project-template/` + Architect-B-conditional project-side dirs) |
| Subject contains literal `project-only` (case-insensitive) | Only project-side paths (deny pack-only paths) |
| Subject contains literal `PM-only` or `pack-memory-only` | Only Pack-Chat-direct-edit surfaces per PACK-AGENTS.md (root trinity, PACK-CHAT.md, PACK-AGENTS.md, root BACKLOG/CHANGELOG, project-template trinity edits FAIL this gate — caught V10) |
| No scope keyword in subject | Check skipped (commit is implicitly mixed-scope) |

The keyword vocabulary is narrow (3 keyword patterns) and the deny rules are mechanically verifiable.

**Implementation strategy:**

- Check 36 runs in `scripts/validate-pack.py` as a per-commit walk of `git log --format=%H%n%s --reverse $BASE_SHA..HEAD` where `$BASE_SHA` is configurable (default: the last release tag or merge-base with `main`).
- For each commit, parse subject for keywords; if matched, diff against permitted-paths regex.
- FAIL with commit SHA + offending file paths + "subject claims `<keyword>` but commit touches `<paths>`".

**Constraint dependency on Architect B:**

The PERMITTED-PATHS regex is conditional on Architect B's directory architecture output. Until B's design lands, the gate operates on the conservative current state (`project-template/` + `supporting-docs/` as project-side; everything else as pack-only). Post-B, the regex updates in the same commit as the relocations.

**Failure mode (worked example): The audit's V2 finding.** Commit `aaa61b3` subject "docs: v11 — Batch 19b cleanup — V11-12/13/14 CONCEPTUAL-REVIEW-METHODOLOGY verification + V11-15 reviewer-prompt-template find-replace" doesn't carry an explicit `pack-only` keyword, so Check 36 wouldn't have caught it under strict keyword-matching. **Architectural decision needed (Phase 3 reviewer concern, §10):** does the keyword vocabulary expand to detect implicit pack-only intent (e.g., "Batch NN cleanup" without explicit `mixed` keyword presumed pack-only), or does Pack-Chat-side discipline (M1a) provide the only gate for implicit-scope commits?

**Measurable test for M5a:** Stage three test commits in CI fixture branch:
- Commit subject `"pack-only: test"` touching `project-template/CLAUDE.md` → MUST FAIL Check 36 with diff callout
- Commit subject `"project-only: test"` touching `scripts/foo.sh` → MUST FAIL
- Commit subject `"PM-only: test"` touching `project-template/CLAUDE.md` → MUST FAIL (project-template trinity is NOT a Pack-Chat-direct surface per PACK-AGENTS.md)

### §8.2 — M5b: Check 37 — project-side pack-only-reference deny list (catches TYPE-4)

**Behavior contract:**

For every file under `project-template/` (and post-Architect-B, any new project-side directory), grep for literal references to the pack-only deny list. Each hit is a FAIL with file:line + matched pattern + remediation pointer.

**Deny-list (initial — Architect B's directory architecture refines):**

| Pattern (case-sensitive, word-boundary) | Why pack-only |
|---|---|
| `PACK-AGENTS.md` | Pack-repo only |
| `PACK-CHAT.md` | Pack-repo only |
| `HELP-FRAGMENT-PACK.md` | Pack-repo only |
| `HELP-FRAGMENT-TRACKER.md` (pack-root copy; project-side has its own copy at `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`) | Architect-B-conditional — depends on byte-identity status post-B |
| `OPTIONAL-FEATURES.md` | Architect-B-conditional — currently pack-root only; B may decide install-to-client path |
| `maintenance-docs/` (path prefix) | Pack-only; not installed |
| `pack-architect`, `pack-coder`, `pack-planner`, `pack-reviewer`, `pack-docs-researcher` (agent names, word-boundary) | Pack-only agents |
| `Pack Chat` (capitalized, orchestrator-role reference) | Pack-only orchestrator role — DISTINCT from lower-case "pack chat" in feedback flow per audit §D-4 |
| `tracker.toml.pack-example` | Per AUDIT-USER-CURATION.md Override 1 — STAYS at pack root; not installed |

**Per-pattern exception list (LEGITIMATE references — per audit §D-4 LEGITIMATE designation):**

| Pattern | Exception | Rationale |
|---|---|---|
| `Pack Chat` (capitalized) | `PACK-FEEDBACK.md`, `PM-CHAT.md` (in feedback-flow context only) | Feedback channel description per audit §D-4 LEGITIMATE |
| `Pack Chat` (capitalized) | `METHODOLOGY.md` feedback-flow section | Per audit §D-4 LEGITIMATE |
| `Pack Chat` (capitalized) | `SETUP-EXISTING.md` escalation paths | Per audit §D-4 LEGITIMATE |

The exception list is **per file:line context** (the legitimate context is the feedback-flow / escalation-path description; the contamination context is the orchestrator-role reference). Mechanical implementation: grep with a context-window check (the matched line OR the surrounding 2 lines must contain one of the LEGITIMATE-context anchor phrases: `feedback`, `report back`, `escalation`, `STOP and surface`). If anchor phrases absent in the window, hit is CONTAMINATION.

**Implementation strategy:**

- Check 37 runs in `scripts/validate-pack.py`.
- Walks files under `project-template/` (recursive, with `.gitignore`-style excludes for generated content).
- Per match, applies context-window exception check.
- FAILs with file:line + matched pattern + (if applicable) "no LEGITIMATE-context anchor found within 2-line window" + remediation hint pointing to the project-side SSOT.

**Constraint dependency on Architect B:**

The deny-list itself depends on B's directory architecture (where the relocated files end up; whether `HELP-FRAGMENT-TRACKER.md` byte-identity status changes). Until B lands, Check 37 operates on the current pack-root state.

**Bootstrap incompatibility note:** Check 37 will FAIL on HEAD at the moment it's enabled because the 17 confirmed CONTAMINATION refs from audit §D-9 are still present. The check must be enabled AFTER Architect A's re-litigation lands (the contamination is fixed) OR enabled with a temporary `--known-failures` allow-list shrinking commit-by-commit as Architect A's fixes land. The planner phase decides which approach. The architect-side guidance: enable with allow-list at the end of Architect A's pass; remove allow-list entries as fixes land; CI green when allow-list empties.

**Measurable test for M5b:** After enabling, create a synthetic commit adding `"See PACK-AGENTS.md for details"` to `project-template/CLAUDE.md` in a CI test branch. CI MUST fail Check 37 with the file:line + pattern callout. Remove the synthetic line and CI must pass.

### §8.3 — M5c: Check 38 — pack-only-file siting (catches mis-located pack-only content; supports Architect B's relocation)

**Behavior contract:**

For each file in a deny-listed path prefix (post-Architect-B, this is the relocated pack-only directory; pre-B, this is `supporting-docs/`), check whether the file's content matches pack-only signals (references pack-only mechanisms, pack-* agents, Pack Chat orchestrator role, etc.). Files matching pack-only signals in pack-only directories are OK. Files matching pack-only signals in project-side directories FAIL with "pack-only content in project-side directory; relocate or rewrite for project-side audience".

The check is approximate (semantic intent isn't grep-detectable) but the audit's V4 finding (`CONCEPTUAL-REVIEW-METHODOLOGY.md` is pack-only by content but project-side by location) demonstrates that even a coarse grep gate catches the most egregious cases.

**Implementation:** Per-file count of pack-only-signal hits (deny-list patterns from §8.2); threshold-based FAIL when count exceeds N (heuristic; planner-pass refines threshold).

**Dependency on Architect B:** Check 38 is conditional on B's `supporting-docs/` decision (split, rename, eliminate). The mechanical implementation must wait for B's directory architecture; until then, the gap is covered by M3a/M3b/M6 process gates.

**Measurable test for M5c:** Stage a synthetic file in a project-side directory containing 5 references to `Pack Chat` (orchestrator role) outside feedback-flow context; Check 38 must FAIL. Remove file or relocate to pack-only dir; check must pass.

### §8.4 — Where CI is not mechanically possible (gap acknowledgment)

**TYPE-5 (project-side mirrors pack-side without independent rationale)** is not mechanically detectable. The check would require semantic understanding of "independent project-design rationale" which exceeds grep / AST capability.

**Compensating control:** M7 (§9) — reviewer-protocol amendment requires positive assertion of independent rationale per project-side rule change. The TYPE-5 detection is a **manual gate, owned by the reviewer**. The architecture explicitly acknowledges this gap rather than papering over it with a check that won't actually catch the regression.

**TYPE-2 (pack-bias content addition) at the moment of edit** is also not mechanically pre-detectable (the content doesn't exist yet to grep). The Check-37 gate catches it post-commit (CI fails the PR), which is the right gate level: pre-commit prevention is owned by M3a/M3b/M6 (prompt guardrails). The redundancy (process + CI) is intentional defense in depth.

---

## §9 — Mechanism M7 + M8: trinity rule consideration + TYPE-5 reviewer gate

### §9.1 — M7: TYPE-5 reviewer-protocol gate (positive-assertion mode)

**Problem:** TYPE-5 is not mechanically detectable. A project-side rule that mirrors a pack-side rule without independent rationale looks identical, in content, to a project-side rule with independent rationale. The difference is in the WHY, not the WHAT.

**Gate design:** Extend the M3a reviewer dimension-9 (§5.1) with a positive-assertion requirement:

```
[continuing dimension 9 from §5.1]

In addition: when a project-side rule, enumeration, or convention is
present, the reviewer MUST positively assert one of:
  (a) "Independent project-design rationale: <rationale text>" — name
      the project-side reason this rule exists for project-side use,
      independent of any pack-side parallel.
  (b) "Structural mirror: pack-side <X> has parallel rule, and the
      mirror is justified because <why-mirror-makes-sense>" — explicitly
      identify the pack-side parallel and explain why the mirror is
      load-bearing (not coincidental).
  (c) "TYPE-5 finding: this project-side rule mirrors pack-side <X>
      without independent rationale; recommend either (i) demote to
      pack-side only and remove from project-side, or (ii) add project-
      design rationale, or (iii) confirm structural mirror per (b)."

A review that passes a project-side rule WITHOUT one of (a) / (b) /
(c) is incomplete. (a) and (b) are positive assertions of rule-
correctness; (c) is a flagged finding.
```

This is a positive-assertion gate (the reviewer must say something explicit, not just stay silent) — designed to make the omission visible. The audit's T5-A finding (project trinity copied pack agent-list rule rather than instructing PM-chat to read project SSOT) is the worked example this gate would catch.

**Test:** Run reviewer against a project trinity edit that adds a rule copied from pack trinity verbatim. Reviewer report MUST contain a (b) or (c) entry for that rule. If neither is present, reviewer prompt is broken.

### §9.2 — M8: trinity rule consideration — symmetry vs substance

**Audit observation (`AUDIT-PACK-PROJECT-BOUNDARY-VIOLATIONS.md` §C / orchestration-plan §1 paragraph 3):** Trinity Check 18 H2 parity verifies wording-matches across CLI files but does NOT verify whether the rule is correct for the surface it lives on. V1's regression entered specifically through this gap: F-7 added `PACK-AGENTS.md` reference to project trinity, the addition was uniform across CLAUDE.md / AGENTS.md / GEMINI.md (parity preserved), Check 18 passed, the regression shipped.

**The fundamental trinity-rule scope question:** Is the trinity rule (a) a **symmetry rule** (the three CLI files must say the same thing) or (b) a **correctness rule** (the three CLI files must say the right thing for their trinity location)?

The trinity rule as currently written is (a) — symmetry only. (b) is a separate, larger discipline that the architecture currently delegates to reviewer / implementer judgment.

**Decision: do NOT extend the trinity rule itself to substance-checks.** Rationale:

1. **The trinity rule is sound for what it does.** Symmetry across CLI files is a CLI-portability concern (Codex sees what Claude sees what Gemini sees). Symmetry has no opinion on whether the content is right for the trinity it lives on — that's a different layer.

2. **Substance correctness is per-trinity, not cross-trinity.** Pack-root trinity (CLAUDE.md / AGENTS.md / GEMINI.md at pack repo root) must contain pack-only rules. Project-template trinity (under `project-template/`) must contain project-only rules. The substance correctness rule is "rules in trinity X must be appropriate for the audience trinity X serves" — that's a content-vs-location rule, not a CLI-parity rule. Bolting it onto Check 18 conflates two orthogonal axes.

3. **The right surface for substance correctness is the new mechanisms M2 + M3a + M3b + M4 + M7.** P-missed-7 codification + SSOT-investigation gate + boundary-investigation skill collectively address substance correctness across BOTH trinities (and across all project-side surfaces, not just trinity). Extending Check 18 would address only the trinity slice of the larger problem.

4. **Mechanical implementation of substance-correctness in Check 18 would either:**
   - Require an authoritative "rule X belongs in pack-trinity, rule Y belongs in project-trinity" classification table (enormous maintenance burden; brittle to natural-language drift in rules), OR
   - Reduce to a deny-list check (already covered by Check 37 / M5b for cross-references; no new coverage from extending Check 18).

**Recommendation:** Keep Check 18 as a symmetry check. Codify substance correctness in M2 / M3a / M3b / M4 / M7 (the layered prevention). Architect-B's directory-architecture work may surface a related rule (e.g., "files in pack-only directories must not import project-side rules") which is a different mechanical check (Check 38 / §8.3 covers part of this).

**Trinity rule documentation amendment (informational, not enforced — explanatory):** Add to the trinity-rule bullet in pack-repo `CLAUDE.md` `## Rules for agents working on this repo`:

```
Note: the trinity rule enforces parity (the three CLI files express
the same project rules). It does NOT verify that the rule is correct
for the surface it lives on (pack-root trinity vs project-template
trinity). For substance correctness, see Pack memory P-missed-7
(boundary discipline) and the boundary-investigation skill.
```

This addition makes the trinity rule's SCOPE explicit so future actors don't infer that "trinity rule passed" implies "rule is correct for both trinities" — the V1 regression's exact failure mode.

**Measurable test for M8:** No test (this is a documentation amendment, not a behavior change). The test of the rule-clarification working is BD-175 + retrospective: did future audits find any new V1-style regressions where actors mistook trinity parity for substance correctness? If yes, M8 needs strengthening.

---

## §10 — Mechanism M1: Pack Chat batch-scope discipline (the upstream of TYPE-1/3)

The TYPE-1 / TYPE-3 violations enter at the BATCH-FRAMING stage: Pack Chat (or a prior session) tells the implementer "this is a pack-only batch" but doesn't gate the implementer's actual edits against the scope claim. The audit's V2 finding (commit `aaa61b3`) is the worked example: Pack Chat or the implementer self-described the batch as pack-only but still edited `supporting-docs/`.

### §10.1 — M1a: Pack Chat batch-scope memory rule

Add to trinity Pack memory `### Pack Chat scope` subsection:

```
- **Batch-scope claims are enforced by CI, not honor system.** When
  Pack Chat frames a batch as `pack-only`, `project-only`, or
  `PM-only` in commit subjects, CI Check 36 verifies the commit
  diff matches the claimed scope. If a batch's work genuinely spans
  pack + project, the commit subject MUST NOT carry an exclusive
  scope keyword — use neutral framing ("BD-NNN cross-surface work")
  or explicitly split the batch into separate pack-side and project-
  side commits. Mis-framing a mixed-scope commit with a pack-only
  keyword is a CI failure, not a discipline note.
```

This memory rule activates Check 36 (§8.1). Without the memory rule, actors don't know the keyword-vocabulary is load-bearing; with the rule, the keyword choice has a CI consequence that's visible at every commit.

### §10.2 — M1b: commit-subject scope keyword convention

The keyword vocabulary needs to be standardized before Check 36 is meaningful. Recommendation (subject to Phase 3 reviewer feedback):

| Keyword (case-insensitive, in commit subject) | Meaning | Permitted touched paths |
|---|---|---|
| `pack-only` | Pack repo state only | Deny `project-template/` + Architect-B-conditional project-side dirs |
| `project-only` | Project-side state only | Deny pack-only paths |
| `PM-only` | Pack-Chat-direct-edit only | Per PACK-AGENTS.md PM-only list |
| (no keyword) | Mixed-scope implicit | Check 36 skipped (no claim to verify) |

The vocabulary is intentionally small. Adding more keywords increases CI fragility without proportional value. The "no keyword = mixed" default makes the keyword opt-in (low friction for actors who don't want the gate; mandatory for actors who claim a scope).

**Worked example (audit V10):** Commit `8ba0164` subject "docs: v11 — BD-167b per-entry split PM-only edits" claimed `PM-only` but the commit also edited project-template trinity (which is NOT a PM-only surface per PACK-AGENTS.md). Under Check 36 + M1b: this commit FAILS CI at push, before merge. Pack Chat would have re-issued either as `(no keyword)` mixed scope OR split into two commits.

---

## §11 — Conditional dependencies on Architect B

Several mechanisms in this design are conditional on Architect B's directory architecture output. This section enumerates the dependencies as a Phase 3 reviewer concern (so the reviewer verifies the conditional surfaces are correctly handled when both A's, B's, and C's outputs are integrated).

| Mechanism | Conditional surface | What B's output determines |
|---|---|---|
| M2 P-missed-7 canonical home | Trinity `### Boundary discipline` subsection placement | Whether trinity Pack memory needs a new subsection or whether the bullet lives in existing `### Workflow` |
| M3a reviewer protocol amendment | Project-side file detection scope | Whether `supporting-docs/` continues to count as project-side, or B splits/relocates it |
| M3b implementer pre-flight | Boundary-investigation skill load | Same — affects which agent prompts gate against which directory paths |
| M4 boundary-investigation skill | Pack-only deny-list | Files relocated by B drop from the pack-root deny-list and may gain new pack-only-dir paths |
| M5a Check 36 commit-scope honesty | PERMITTED-PATHS regex | Same |
| M5b Check 37 project-side deny-list | Deny-list patterns | B's renames / relocations change which patterns are deny-listed |
| M5c Check 38 pack-only-file siting | Project-side directory boundaries | Same |
| M7 reviewer positive-assertion gate | "Project-side" definition | Same |

**Integration strategy (Phase 3 reviewer + Phase 4 planner concern):**

- Architect A's re-litigation lands first (fixes the 13 existing violations in place).
- Architect B's directory architecture lands second (relocates files to new homes; updates path references).
- Architect C's prevention mechanisms (this doc) land LAST so each mechanism can hard-code the post-B file paths.
- Until B's design is integrated, this doc's mechanisms operate on the pre-B baseline. Mechanisms M2 / M3a / M3b / M4 / M6 / M7 are mostly path-independent (codification + process gates). Mechanisms M5a / M5b / M5c are MOST path-dependent.

**Phase 3 reviewer focus:** verify the conditional surfaces in §10 / §8.1 / §8.2 / §8.3 are correctly expressed against B's output. Where C's design conflicts with B's, surface the conflict; Phase 4 planner resolves.

---

## §12 — Test plan summary (success criterion 6: each mechanism has a measurable test)

| Mechanism | Test |
|---|---|
| M2 (P-missed-7 codification) | Trinity Check 18 H2 parity fails when the bullet is missing from one trinity file. Beyond CI: Pack Chat actor reading trinity hits the bullet before forming wrong instinct. |
| M3a (reviewer SSOT-investigation) | Synthetic recommendation to add `PACK-AGENTS.md` ref to project trinity → pack-reviewer MUST flag with dimension-9 / priority-0 finding. |
| M3b (implementer pre-flight) | Synthetic fix-cycle prompt instructing pack-coder to add `PACK-AGENTS.md` ref to project trinity → pack-coder MUST emit "Boundary discipline stop" + refuse edit. |
| M4 (boundary-investigation skill) | Skill content checked into `test-fixtures/` for byte-identity testing. Regression tests for reviewer + coder assert the skill's methodology is referenced in their output reports. |
| M5a (Check 36 commit-scope) | Three test commits in CI fixture branch (`pack-only` claiming touching `project-template/`, etc.) — all MUST FAIL Check 36 with file-path callout. |
| M5b (Check 37 project-side deny-list) | Synthetic commit adding `See PACK-AGENTS.md for details` to `project-template/CLAUDE.md` → CI MUST FAIL Check 37 with file:line + pattern. |
| M5c (Check 38 pack-only-file siting) | Synthetic file in project-side directory containing N references to `Pack Chat` orchestrator-role outside feedback-flow → Check 38 MUST FAIL. |
| M6 (SSOT-rotation reminder) | Mixed-side review fixture (synthetic commit touching pack + project files with parallel patterns) → reviewer report addresses each side with the appropriate SSOT. |
| M7 (TYPE-5 positive-assertion gate) | Reviewer run against project trinity edit copying pack rule verbatim → report MUST contain (b) or (c) entry per the M7 contract. |
| M8 (trinity-rule documentation amendment) | No automated test (documentation-only). Retrospective test: future audits should find no new V1-style regressions where actors confuse trinity parity with substance correctness. |
| M1a / M1b (Pack Chat batch-scope) | Subsumed under M5a. M1a + M1b are the memory + convention layer; M5a is the CI enforcement layer; the test of the trio working is M5a's tests. |

---

## §13 — Order of land + dependency graph

Phase 5 implementation order (proposed; Phase 4 planner refines):

1. **Pre-requisite — Architect A's re-litigation lands.** Without this, M5b Check 37 fails immediately at HEAD (the 17 confirmed CONTAMINATION refs are present).
2. **Pre-requisite — Architect B's directory architecture lands.** Without this, M5a/b/c regex patterns operate against an interim baseline that will need re-work post-B.
3. **M2 (P-missed-7 codification + trinity Pack memory + project-side Project memory mirror).** Pure-codification; no path dependencies; lands first among prevention mechanisms.
4. **M4 (boundary-investigation skill).** Pure-new-file; loaded by all five pack agents + four project-side agents (reviewer, coder, architect, planner). Trinity per skill convention.
5. **M3a (pack-reviewer + skill amendment) + M3b (pack-coder amendment + project-coder amendment).** References M2 + M4; lands after both.
6. **M6 (SSOT-rotation reminder, included in the M3a / M3b prompts).** Same commit as M3a/b.
7. **M7 (reviewer positive-assertion gate, extension of M3a dimension-9).** Same commit as M3a/b.
8. **M1a (Pack Chat batch-scope memory rule) + M1b (commit-subject scope keyword convention).** Memory + convention; no enforcement until M5a lands.
9. **M5a (Check 36 commit-scope honesty).** CI enforcement of M1a/b. Lands after M1a/b memory rules.
10. **M5b (Check 37 project-side deny-list).** Lands AFTER Architect A's re-litigation has fixed the existing 17 contaminations (or with allow-list shrinking commit-by-commit during A's fix-pass).
11. **M5c (Check 38 pack-only-file siting).** Lands AFTER Architect B's `supporting-docs/` decision.
12. **M8 (trinity-rule documentation amendment).** Pure-documentation; can land any time after M2.

The dependency graph:

```
A's re-litigation ──┐
                    ├─→ M5b Check 37 (deny-list, hard FAIL at HEAD without A)
B's directory arch ─┤
                    ├─→ M5a Check 36 (regex paths) ──┐
                    ├─→ M5b Check 37 (deny-list)     ├─→ CI green at v11.1
                    └─→ M5c Check 38 (siting)        │
                                                     │
M2 P-missed-7 codification ──┐                       │
                              ├─→ M3a (reviewer)  ───┤
M4 boundary skill ─────────── ┤                      │
                              ├─→ M3b (coder)     ───┤
                              ├─→ M6 (rotation)   ───┤
                              └─→ M7 (TYPE-5)     ───┘
M1a + M1b (Pack Chat) ────────→ M5a (Check 36)
M8 (trinity doc amendment) ───→ standalone, any time after M2
```

---

## §14 — Constraints, gaps, and open questions for Phase 3 reviewer

**Constraints honored in this design:**

- Read-only on every file except the single output report (this doc).
- No state-changing git verbs.
- No design in Architect A's domain (no per-finding revert/replace/justify decisions).
- No design in Architect B's domain (no boundary definition; no directory architecture; no relocations).
- User's boundary articulation (`AUDIT-USER-CURATION.md` §5) treated as foundation; not extended or refined here.

**Gaps acknowledged:**

- **TYPE-5 detection is not mechanically possible.** Compensating control is the M7 positive-assertion reviewer gate. The architecture explicitly accepts this gap rather than pretending a grep can solve it.
- **The implicit-scope case for M5a (commit-subject with no scope keyword).** A commit subject like "BD-NNN: implement X" with no keyword skips Check 36 entirely. This is intentional (keyword opt-in, low friction). The cost: an implicit-scope commit that mixes pack + project surfaces is allowed by Check 36 and depends entirely on M1a discipline + reviewer judgment. Architect-B-conditional Phase 3 question: should this be revisited if mixed-scope commits prove to be a regression vector in v11.1?
- **Deny-list maintenance burden.** The Check 37 deny-list (§8.2) needs to be updated every time the pack adds a new pack-only file (e.g., a new `pack-orchestrator.md` agent in v12). Without maintenance, new pack-only files can leak into project-side without CI catching them. Mitigation: a Check 37 self-test that walks the actual pack-only directories at validation time and flags any pack-only file NOT in the deny-list (meta-check). Phase 4 planner concern.
- **Anchor-phrase exception window in Check 37 (§8.2).** The 2-line context-window check is approximate; a hostile (or sloppy) commit could insert `Pack Chat` orchestrator reference NEAR an anchor phrase without legitimate feedback-flow context. Mitigation: anchor-phrase list is tightly scoped (`feedback`, `report back`, `escalation`, `STOP and surface`) and the check FAILS-CLOSED (no match = CONTAMINATION). Phase 3 reviewer concern: is the failure mode acceptable, or does the gate need stronger NLP?

**Open questions for Phase 3 reviewer (cross-architect verification):**

1. **Conflict with Architect A's domain?** Architect A may decide to revert some V1-V8 findings (clean revert), replace others (project-side equivalent content), or justify a few (LEGITIMATE despite cross-surface ref). The Check 37 deny-list operates AFTER A's decisions. The conflict surface: if A decides a particular cross-reference is JUSTIFIED LEGITIMATE (e.g., the `Pack Chat` references in `PACK-FEEDBACK.md` per audit §D-4 LEGITIMATE), Check 37 must have the exception in its anchor-phrase list. Reviewer should verify the LEGITIMATE-context list aligns with A's decisions.

2. **Conflict with Architect B's domain?** Architect B may relocate `PACK-AGENTS.md` / `PACK-CHAT.md` / `HELP-FRAGMENT-PACK.md` / `OPTIONAL-FEATURES.md` to a new pack-only directory (e.g., `pack-docs/`). All deny-list patterns and SSOT pointers in this doc reference current file paths. Reviewer should verify the post-B paths are correctly substituted (or explicitly note path-substitution as a Phase 4 planner concern).

3. **Skill-load-table extension.** M4 adds `boundary-investigation` to all 5 pack agents + 4 project-side agents. Cross-tool parity (skill in `.claude/skills/` + `.codex/skills/` + `.gemini/skills/`, mirrored to `project-template/` parallels) is implicit. Reviewer should verify the trinity-skill-shipping convention applies cleanly.

4. **PACK-CHAT.md amendments.** This doc references PACK-CHAT.md as a codification surface for Pack-Chat-side rules (M1a). PACK-CHAT.md is a PM-only file per PACK-AGENTS.md; the edits land via Pack Chat direct edit, not pack-coder. Reviewer should verify the PM-only-edit pathway is correctly identified in Phase 4 planner sequencing.

5. **CI failure mode if M5b lands before A's fixes.** §8.2 notes the bootstrap incompatibility and proposes either (a) land M5b AFTER A's fixes or (b) land M5b with `--known-failures` allow-list. The planner chooses. Reviewer should verify the chosen approach is sound (allow-list approach risks contamination growth in the allow-list window; AFTER-A approach delays prevention coverage).

---

## §15 — Summary

Three audit-confirmed regression mechanisms (TYPE-1 batch scope drift, TYPE-2 content import, TYPE-4 cross-reference) become two mechanically detectable (TYPE-1/3, TYPE-4) and one explicitly-acknowledged-not-mechanically-detectable (TYPE-5). Coverage is layered across three surfaces:

1. **Codification (M2, M8)** — trinity Pack memory + project-template Project memory + trinity-rule documentation clarification. Reaches every actor at session start.
2. **Process gates (M1a, M1b, M3a, M3b, M4, M6, M7)** — Pack Chat batch-scope discipline + reviewer SSOT-investigation gate + implementer SSOT-investigation pre-flight + boundary-investigation skill + frame-rotation reminder + TYPE-5 positive-assertion gate. Catches the regression at the moment of review or fix.
3. **CI enforcement (M5a, M5b, M5c)** — commit-scope-honesty check + project-side deny-list + pack-only-file-siting. Catches the regression at push time when process gates fail.

Each mechanism has a measurable test (§12). Each conditional dependency on Architects A and B is enumerated (§11, §14). The design's order of land is staged so the prevention mechanisms land in a sequence that doesn't fight Architects A's and B's outputs (§13).

The single most leverage point per unit of CI work is M5b (Check 37 project-side deny-list) — it directly addresses the most-frequent contamination type (TYPE-4 / 17 confirmed refs) with a mechanically simple grep gate. The single most leverage point per unit of process work is M2 (P-missed-7 codification in trinity Pack memory) — it reaches every actor at session start and is the upstream of M3a / M3b / M4 / M6 / M7. Together, M2 + M5b carry the bulk of the protection; the rest of the mechanisms are defense in depth.

The trinity rule itself is NOT extended to substance-checks (§9.2 / M8). Symmetry and substance-correctness are orthogonal axes; conflating them weakens both. Substance correctness lives in the boundary-investigation layer (M2 + M3a/b + M4 + M7), which addresses ALL project-side surfaces — not just trinity files.

---

## End of architecture design

Architect C / Phase 2 / BD-175 work complete. No design content in Architect A's or Architect B's domain. Conditional dependencies on B surfaced explicitly. Test plans per mechanism. Phase 3 reviewer receives this alongside A's and B's outputs for cross-architect verification.

