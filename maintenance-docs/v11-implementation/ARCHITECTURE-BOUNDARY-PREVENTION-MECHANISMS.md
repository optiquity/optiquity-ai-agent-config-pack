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

### §4.1 — User Override 9 — two-tier codification authority + Check 18 H2 parity NON-application

Per `AUDIT-USER-CURATION.md` Override 9, the pack-side P-missed-7
codification (§4 above) and the project-side mirror (§4.2 below) are
intentionally DIFFERENT in wording. The pack-side bullet is detailed,
names BD-175 worked examples (V1 / V3 / V4), and instructs pack actors
to investigate project-side SSOT before defaulting to pack-style
mechanisms. The project-side mirror is **shorter and inverted** — it
does not need to know about Pack Chat; it needs to know that PROJECT
SSOT is the starting point for any project-side change. Two
audience-specific rules; not a byte-identical mirror.

**Authority:** AUDIT-USER-CURATION.md §1 Override 9 (CONFIRMED):

> "Different audience means different wording is fine." Two
> audience-specific rules, not a mirror in the byte-identical-drift
> sense. Compatible with D-4 ("no mirrors as default") because the
> two rules are substantively different even though they share the
> principle.

**Phase 3 reviewer (per Override 9):** "no cross-trinity drift gate
needed for this codification (different wording is intentional, not
drift)."

**Implication for Check 18 H2 parity:** Check 18 H2 parity (existing
Trinity-files cross-CLI wording-parity gate in `scripts/validate-pack.py`)
does NOT apply to the new bullet. Specifically:

- Check 18 H2 enforces parity ACROSS THE THREE CLI FILES at a single
  trinity location (CLAUDE.md vs AGENTS.md vs GEMINI.md at pack root,
  OR CLAUDE.md vs AGENTS.md vs GEMINI.md at `project-template/`).
  Within each trinity location, the three CLI files MUST stay in
  parity (the pack-side bullet wording in pack-root CLAUDE.md MUST
  match pack-root AGENTS.md and pack-root GEMINI.md). This standard
  per-trinity-location parity continues to apply.
- What Check 18 H2 does NOT enforce, and per Override 9 MUST NOT
  enforce, is CROSS-TRINITY parity (pack-root trinity wording vs
  project-template trinity wording). The two trinities legitimately
  carry different wording per Override 9. Any future Check 18
  extension or new check that would compare pack-root P-missed-7
  text to project-template Project SSOT-first text is REJECTED by
  this design.

**Measurable consequence:** the M2 measurable test (Trinity Check 18
H2 parity fires when the bullet is missing from one trinity file)
applies WITHIN each trinity location. It does NOT fire because the
pack-side wording differs from the project-side wording — those
differ by design per Override 9.

**Cross-reference to S4 fix-pass:** This §4.1 subsection was added
by C-fix per Phase 3 reviewer S4 finding (PACK-REVIEW-PHASE-2-DESIGNS.md
§1 S4, lines 201-216). Pre-fix, C's §4 + §4.2 implicitly aligned with
Override 9 but did not explicitly cite it; reviewer reading C alone
could not tell whether the two-trinity codification was user-confirmed
or unilateral architect decision.

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
  agent prompts, pack-repo maintenance-docs/, pack-repo pack-ops/
  — any file under pack-ops/, including BOUNDARY-DEFINITION.md,
  BACKLOG.md, CHANGELOG.md, etc. post Architect B + B-fix) are NOT
  part of the project SSOT and must not be referenced from project
  files — the pack repo is not present at this client install.
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
   - Path prefixes: `maintenance-docs/`, `pack-ops/` (pack-only
     top-level dir per Architect B; houses BOUNDARY-DEFINITION.md,
     PACK-AGENTS.md, PACK-CHAT.md, BACKLOG.md, CHANGELOG.md, etc.
     post B-fix M1-M5 + M9-M10 — none of which exist at client
     install), `scripts/` (pack-repo only — project-side scripts
     live at `project-template/scripts/`), `test-fixtures/`
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

> **F4 addendum (2026-05-19):** BD-175 commit `8f6ce51` superseded
> this Pattern B prescription with Pattern A. See §6.1 — F4 supersession
> addendum at the end of this section.

**Measurable test for M4:** After M4 lands, both pack-reviewer and pack-coder regression tests (proposed; see §11) include a synthetic boundary-violation prompt and assert the skill's methodology was applied (IMPL-REPORT / review-report mentions the SSOT-investigation step). A baseline gold-image of the skill content is checked into `test-fixtures/` for byte-identity testing (parallels Check 31 skill-cell internal-consistency gate).

### §6.1 — F4 supersession addendum

**Reconciles:** The "Project-side skill trinity" paragraph above (Pattern
B prescription) with the realized shipping shape committed in BD-175
commit `8f6ce51` (F4 bundle).

The original §6 design above prescribed **Pattern B** for the
project-side boundary-investigation skill — 3 byte-identical SKILL.md
files at `project-template/.claude/skills/boundary-investigation/`,
`project-template/.codex/skills/boundary-investigation/`, and
`project-template/.gemini/skills/boundary-investigation/`. BD-175
commit `8f6ce51` (F4 bundle) superseded this with **Pattern A**, the
pack's canonical skill-source convention: a single source at
`project-template/skills/boundary-investigation/SKILL.md` that
auto-distributes to all 3 client CLI skill directories at client install
time.

**Realized consumer:** `stage_s4_skills()` in `scripts/init-project.sh`
— iterates `$PACK/project-template/skills/*/`, copies each `SKILL.md`
into `$TARGET/.claude/skills/<name>/`, `$TARGET/.codex/skills/<name>/`,
and `$TARGET/.gemini/skills/<name>/`, then verifies all three
destinations exist. The boundary-investigation skill participates in
this loop alongside the 30+ other Pattern A skills.

**Why Pattern A:** Pack convention for byte-identical-across-CLIs skills
(no per-CLI content variation) is the canonical
`project-template/skills/<name>/` location, matching how 30+ other
project-side skills already ship (`api-design`, `audit-methodology`,
`debugging`, `python-best-practices`, etc.). Pattern A guarantees
byte-identity by construction (single source) rather than by
maintenance discipline (three trinity files that drift if maintainers
diverge). Pattern B remains valid for skills with genuinely CLI-specific
content variation (e.g., skills whose invocation syntax differs per
CLI); boundary-investigation has no such variation. Pattern B was
inadvertently prescribed in the original architect design and not caught
until F4-bundle implementation.

**Unchanged from §6:** The pack-side boundary-investigation skill at
pack-repo root `.claude/skills/boundary-investigation/`,
`.codex/skills/boundary-investigation/`, and
`.gemini/skills/boundary-investigation/` (the "New skill" paragraph
at the top of §6). Pack-repo agents load skills at run-time from
CLI-prefixed dirs at the pack root — this is structurally different
from project-side ship-via-install and was correctly described in §6.

**Back-pointer:** commit `8f6ce51` (BD-175 F4 bundle) is the realizing
commit for this supersession.

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
| Subject contains literal `PM-only` or `pack-memory-only` | Only Pack-Chat-direct-edit surfaces per `PACK-AGENTS.md:142-148` PM-only Files list — see §8.1a below for the verbatim list. Notably **PERMITS** edits to `project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md` (project-template trinity IS PM-only per PACK-AGENTS.md:148 — "root and `project-template/`"). Updated per Phase 3 reviewer finding B1-cascade + S6. |
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
- Commit subject `"PM-only: test"` touching `project-template/CLAUDE.md` → MUST **PASS** (project-template trinity IS a Pack-Chat-direct PM-only surface per `PACK-AGENTS.md:148` — "root and `project-template/`"). Updated per Phase 3 reviewer finding B1-cascade + S6 cascade; pre-fix this test asserted FAIL, which was incorrect per the actual pack-memory rule. The correct PM-only-violation fixture must touch a file OUTSIDE the PACK-AGENTS.md:142-148 PM-only Files list — see §8.1a §10.2 worked example.
- (Additional fixture per S6 fix:) Commit subject `"PM-only: test"` touching `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` → MUST FAIL (supporting-docs/ is project-side per CLAUDE.md trinity rule; not in the PM-only Files list). This is the corrected V2-shape fixture; the previous V10-shape fixture was based on the misreading B1 corrected.

### §8.1a — Authoritative PM-only Files list (consumed by Check 36 PM-only keyword)

The `PM-only` / `pack-memory-only` commit-subject keyword's permitted-paths
regex is defined by `PACK-AGENTS.md:142-148` § "PM-only files and directories"
Files block (verbatim at HEAD `8014186`):

```
Files:
- BACKLOG.md (regenerated mirror; per-entry source at /backlog/)
- CHANGELOG.md (regenerated mirror; per-entry source at /changelog/)
- README.md version table
- PACK-CHAT.md
- PACK-AGENTS.md
- CLAUDE.md / AGENTS.md / GEMINI.md (root and project-template/)
```

**Post-B + B-fix path substitution** (per `ARCHITECTURE-DIRECTORY-REORGANIZATION.md`
M4 + M5 + `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` M9 + M10):
- `BACKLOG.md` → `pack-ops/BACKLOG.md`
- `CHANGELOG.md` → `pack-ops/CHANGELOG.md`
- `PACK-CHAT.md` → `pack-ops/PACK-CHAT.md`
- `PACK-AGENTS.md` → `pack-ops/PACK-AGENTS.md`
- Pack-root trinity (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` at repo root) UNCHANGED.
- Project-template trinity (`project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md`)
  UNCHANGED.
- `README.md` version table UNCHANGED.

**Pre-B + pre-B-fix path substitution** (interim state, pre-relocation): the
PM-only Files are the bare-root paths as listed in PACK-AGENTS.md.

**Check 36 PM-only keyword PERMITTED-PATHS regex (canonical, post-B + B-fix):**

```
^(pack-ops/BACKLOG\.md|pack-ops/CHANGELOG\.md|README\.md|
 pack-ops/PACK-CHAT\.md|pack-ops/PACK-AGENTS\.md|
 CLAUDE\.md|AGENTS\.md|GEMINI\.md|
 project-template/CLAUDE\.md|project-template/AGENTS\.md|project-template/GEMINI\.md)$
```

**(README.md version-table edits:** Check 36 cannot mechanically distinguish
a version-table-only edit from an other-section edit on the README. The
permitted-paths regex therefore PERMITS any README.md touch under `PM-only`;
the version-table-only narrower constraint stays a Pack Chat discipline
concern (M1a memory rule), not a Check 36 mechanical concern. Mis-scoped
README.md edits surface in M3a/M5b/M5c instead.)

**Directories also listed by PACK-AGENTS.md:150-158** (`/backlog/`,
`/changelog/`, `project-template/docs/project/backlog/`,
`project-template/docs/project/implementation-plan/`,
`project-template/docs/project/changelog/` and their `_rules.md` /
`_intro.md` / `_format.md` / per-entry files) are also PM-only.
The post-Batch-23 forward-pointing note in PACK-AGENTS.md:178-187 confirms
these directories materialize at Batch 23 BD-102 dog-food; pre-Batch-23
the PM-only files-only list is what Check 36 enforces. Post-Batch-23 the
regex extends to include these per-entry tree paths.

**Cross-reference to B1-cascade + S6 fix-pass:** §8.1a was added by C-fix
per Phase 3 reviewer findings B1-cascade (BLOCKER, PACK-REVIEW-PHASE-2-DESIGNS.md
§1 B1, lines 43-65) and S6 (SHOULD, lines 241-253). Pre-fix, C's §8.1 keyword-table
treated project-template trinity edits as PM-only VIOLATIONS ("caught V10"),
which reproduced Architect A's misreading of `8ba0164`'s scope. The actual
PACK-AGENTS.md:148 PM-only list explicitly names "`CLAUDE.md` / `AGENTS.md` /
`GEMINI.md` (root and `project-template/`)" — project-template trinity IS
PM-only. V10 collapses to NO-ACTION per Architect A fix-pass; this design's
Check 36 PM-only keyword definition no longer references V10.

### §8.2 — M5b: Check 37 — project-side pack-only-reference deny list (catches TYPE-4)

**Behavior contract:**

For every file under `project-template/` (and post-Architect-B, any new project-side directory), grep for literal references to the pack-only deny list. Each hit is a FAIL with file:line + matched pattern + remediation pointer.

**Deny-list (initial — Architect B's directory architecture refines):**

| Pattern (case-sensitive, word-boundary) | Why pack-only |
|---|---|
| `PACK-AGENTS.md` | Pack-repo only |
| `PACK-CHAT.md` | Pack-repo only |
| `HELP-FRAGMENT-PACK.md` | Pack-repo only |
| `HELP-FRAGMENT-TRACKER.md` (bare filename; project-side has its own copy at `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`) | Pack-only at the bare-filename level. Post-B the pack-side copy lives at `pack-ops/HELP-FRAGMENT-TRACKER.md` (per Architect B §3 #9 + B's M2); CI Check 24 enforces byte-identity between the pack-ops copy and the project-side `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` copy. This bare-filename row catches project-side references that omit a path prefix; broader `pack-ops/` path-prefix coverage is the row below. |
| `OPTIONAL-FEATURES.md` | Architect-B-conditional — currently pack-root only; B may decide install-to-client path |
| `maintenance-docs/` (path prefix) | Pack-only; not installed |
| `pack-ops/` (path prefix) | Pack-only; new top-level pack-only dir per Architect B's design (`pack-ops/PACK-AGENTS.md`, `pack-ops/PACK-CHAT.md`, `pack-ops/BACKLOG.md`, `pack-ops/CHANGELOG.md`, `pack-ops/HELP-FRAGMENT-PACK.md`, `pack-ops/HELP-FRAGMENT-TRACKER.md`, `pack-ops/OPTIONAL-FEATURES.md`, `pack-ops/MERGE-STRATEGY.md`, `pack-ops/DRY-RUN-MIGRATION.md`, `pack-ops/BOUNDARY-DEFINITION.md`, `pack-ops/.boundary-exempt-root.txt` post B-fix). Project-side files MUST NOT cross-reference any file under `pack-ops/` — the directory does not exist at client install. Symmetric with `maintenance-docs/` entry above. |
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

**Worked example (audit V2, corrected per Phase 3 reviewer B1-cascade + S6 fix):**

**Pre-fix worked example (V10) was INCORRECT and is dropped.** Phase 3 reviewer
finding B1 surfaced that commit `8ba0164` ("docs: v11 — BD-167b per-entry split
PM-only edits") DID claim `PM-only` and DID touch project-template trinity —
but project-template trinity IS PM-only per `PACK-AGENTS.md:148` ("`CLAUDE.md`
/ `AGENTS.md` / `GEMINI.md` (root and `project-template/`)"). The commit's
scope was correct; the audit's V10 finding misread the PM-only list. V10
collapses to NO-ACTION per Architect A fix-pass; using `8ba0164` as the
worked example here would encode the misreading into the M1b convention and
Check 36 fixtures, producing a false-positive CI gate against legitimate
PM-only commits.

**Corrected worked example (audit V2 `aaa61b3`):** Commit subject
"docs: v11 — Batch 19b cleanup — V11-12/13/14 CONCEPTUAL-REVIEW-METHODOLOGY
verification + V11-15 reviewer-prompt-template find-replace" did NOT carry
an explicit `PM-only` keyword, so Check 36 + M1b wouldn't have caught V2
either under strict keyword-matching (as the §8.1 implicit-scope caveat
notes). The instructive shape for M1b purposes is the HYPOTHETICAL: had the
commit been issued with subject `"docs: v11 — PM-only Batch 19b cleanup"`,
the diff (`supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md`) would have
failed Check 36 because `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md`
is NOT in the PACK-AGENTS.md:142-148 PM-only Files list (it's project-side
per CLAUDE.md trinity rule "`supporting-docs/`" classification, regardless
of Architect B's planned post-fix relocation to `pack-ops/`). Pack Chat
would have re-issued without the `PM-only` keyword or split the commit.

**Real-fixture worked examples** for the Check 36 regression test live in
§8.1 above (three test commits) + the §12 test-plan summary; the V2-shape
fixture replaces the V10-shape fixture from the pre-fix design.

---

## §11 — Conditional dependencies on Architect B

Several mechanisms in this design are conditional on Architect B's directory architecture output. This section enumerates the dependencies as a Phase 3 reviewer concern (so the reviewer verifies the conditional surfaces are correctly handled when both A's, B's, and C's outputs are integrated).

| Mechanism | Conditional surface | What B's output determines |
|---|---|---|
| M2 P-missed-7 canonical home | Trinity `### Boundary discipline` subsection placement | Whether trinity Pack memory needs a new subsection or whether the bullet lives in existing `### Workflow` |
| M3a reviewer protocol amendment | Project-side file detection scope | Whether `supporting-docs/` continues to count as project-side, or B splits/relocates it |
| M3b implementer pre-flight | Boundary-investigation skill load | Same — affects which agent prompts gate against which directory paths |
| M4 boundary-investigation skill | Pack-only deny-list | Files relocated by B drop from the pack-root deny-list and may gain new pack-only-dir paths |
| M5a Check 36 commit-scope honesty | PERMITTED-PATHS regex (PM-only) + permitted pack-only paths regex | Same. **Post-B-fix:** PM-only paths regex is per §8.1a, sourcing from `PACK-AGENTS.md:142-148`. The B-fix C2-at-root exemption list (`pack-ops/.boundary-exempt-root.txt`) is a **1-entry list** (only `tracker.toml.pack-example` per AUDIT-USER-CURATION.md Override 1 + Override 5 collapsing the original 3-entry closed-set proposed in B's §2.1); Check 36 / Check 38 fixtures that depend on the allow-list count assert N=1, NOT N=3. |
| M5b Check 37 project-side deny-list | Deny-list patterns | B's renames / relocations change which patterns are deny-listed. Post-B + B-fix adds `pack-ops/` path-prefix per finding M2. |
| M5c Check 38 pack-only-file siting | Project-side directory boundaries | Same. The 1-entry exemption list (above) governs which C2-at-root files Check 38 tolerates as exempt. |
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
11. **M5c (Check 38 pack-only-file siting).** Lands AFTER Architect B's `supporting-docs/` decision. Consumes `pack-ops/.boundary-exempt-root.txt` (the 1-entry list per B-fix §4 + Overrides 1 + 5 — only `tracker.toml.pack-example`) as the allow-list for C2-at-root files; reject all other PACK × OPERATIONS files at root.
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

## §16 — Phase 3 fix-pass amendments (M2 + M4 + B1-cascade + S4 + S5 + S6)

This section summarizes the amendments applied by C-fix in response to
Phase 3 reviewer findings (PACK-REVIEW-PHASE-2-DESIGNS.md). Each finding
below names: (a) the reviewer-report severity + finding ID, (b) the sections
amended in this doc, (c) the change applied, (d) cross-reference to the
reviewer-report fix-shape that the change satisfies.

**Authority for the fix-pass:**
- `PACK-REVIEW-PHASE-2-DESIGNS.md` §1 + §4 (action summary)
- `AUDIT-USER-CURATION.md` Overrides 1 + 5 + 6 + 9 (user-confirmed overrides
  governing the M4 / S4 / S5 amendments)
- `PACK-AGENTS.md:142-148` (authoritative PM-only Files list governing
  the B1-cascade + S6 amendments)
- `ARCHITECTURE-DIRECTORY-REORGANIZATION.md` (Architect B's pack-ops/ design
  governing the M2 / S5 amendments)
- `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` (Architect B-fix exemption-list
  reduction governing the M4 amendment)

### §16.1 — M2 (MUST) — add `pack-ops/` to Check 37 deny-list

- **Reviewer finding:** PACK-REVIEW-PHASE-2-DESIGNS.md §1 M2, lines 86-104.
  C's §8.2 deny-list includes `maintenance-docs/` as a path-prefix entry but
  NOT `pack-ops/`. Post-B + post-B-fix, `pack-ops/` is the new pack-only
  home for relocated files. A project-side file referencing
  `pack-ops/BOUNDARY-DEFINITION.md` would NOT be flagged because the
  path-prefix isn't in the deny-list.
- **Reviewer fix-shape:** Add `pack-ops/` to the deny-list path-prefix
  entries in §8.2. Mirror this in M4's boundary-investigation skill deny-list
  (§6 "Pack-only deny-list" section).
- **Sections amended:**
  - §8.2 — added a `pack-ops/` (path prefix) row in the deny-list table,
    placed symmetrically after the `maintenance-docs/` row. The row notes
    that `pack-ops/` houses the relocated PACK × OPERATIONS files per
    Architect B's design + B-fix's exemption-list reduction.
  - §6 (M4 boundary-investigation skill text, step 4 Path prefixes
    bullet) — added `pack-ops/` alongside `maintenance-docs/`, `scripts/`,
    `test-fixtures/`. The skill text now lists `pack-ops/` as a
    pack-only directory that does not exist at client install.
- **How this satisfies the fix-shape:** Both surfaces named in the
  reviewer fix-shape (§8.2 Check 37 deny-list + §6 M4 skill deny-list)
  are updated. Check 37's grep against project-side files will now flag
  any literal reference to a `pack-ops/`-prefixed path with file:line +
  pattern callout. The boundary-investigation skill methodology (step 4)
  surfaces the same deny-target to reviewers + implementers before they
  recommend / apply such a reference.

### §16.2 — M4 (MUST) — collapse 3-entry exemption list to 1-entry per B-fix

- **Reviewer finding:** PACK-REVIEW-PHASE-2-DESIGNS.md §1 M4, lines 127-140.
  C's §11 conditional-surfaces table referenced B's original 3-entry
  closed set (BACKLOG.md, CHANGELOG.md, tracker.toml.pack-example). B-fix
  correctly shrinks to 1 entry (only `tracker.toml.pack-example`) per
  AUDIT-USER-CURATION.md Overrides 1 + 5.
- **Reviewer fix-shape:** C-fix surfaces the post-B-fix exemption list as
  1-entry; updates any allow-list-count-based assertions accordingly.
- **References to the 3-entry list found in C's design (pre-fix):**
  - **§11 conditional-surfaces table** — the row for M5a Check 36 and the
    rows for M5b Check 37 and M5c Check 38 implicitly reference B's
    exemption-list via the "Pack-only deny-list" upstream input. The
    explicit text did not encode the 3-entry count, but the conditional
    surface depends on B's count — which is now 1.
  - **§13 Order of land Step 11 (M5c)** — references B's `supporting-docs/`
    decision but did not name the exemption-list count.
  - No C-design body text encoded "3 entries" as a literal assertion or as
    a test-fixture expectation. C's measurable-tests (§12) for M5a/b/c do
    not encode N=3 anywhere — verified via grep on C's pre-fix text for
    "3-entry", "three-entry", "closed set" (zero literal hits in C).
  - Count before fix: 0 literal "N=3" assertions in C; 2 indirect references
    via §11 + §13 to B's exemption list as an upstream input.
  - Count after fix: 2 explicit "N=1, NOT N=3" disambiguations added to
    §11 + §13 to forestall planner / coder confusion when C's design is
    integrated with B-fix's exemption-list count.
- **Sections amended:**
  - §11 conditional-surfaces table rows for M5a / M5b / M5c — added an
    explicit "1-entry list (only `tracker.toml.pack-example`), NOT 3-entry"
    note citing Overrides 1 + 5. The M5b row also notes the M2-finding
    addition of `pack-ops/` path-prefix.
  - §13 Order of land Step 11 (M5c) — added explicit "1-entry list per
    B-fix §4 + Overrides 1 + 5" annotation; reject all other PACK ×
    OPERATIONS files at root.
- **How this satisfies the fix-shape:** Phase 3 reviewer noted the 3-entry
  vs 1-entry asymmetry as a planner / coder gotcha — Phase 5 coder reading
  C's design without context would build fixtures assuming the original
  3-entry list. The amendments cite Overrides 1 + 5 explicitly (with
  pointers to B-fix §4 for the underlying derivation) so the planner /
  coder cannot land an N=3 fixture by accident. Test fixtures asserting
  Check 36 / Check 38 allow-list contents must now assert N=1.

### §16.3 — B1-cascade (BLOCKER) + S6 (SHOULD) — PM-only keyword permits project-template trinity

- **Reviewer findings:**
  - B1 (BLOCKER) cascade — PACK-REVIEW-PHASE-2-DESIGNS.md §1 B1, lines
    43-65. Architect A's V10 framing contradicts pack-memory; the cascade
    into C is that C's M5a Check 36 PM-only keyword + §10.2 worked example
    + §12 test plan treated `project-template/` trinity edits as PM-only
    VIOLATIONS, but `PACK-AGENTS.md:148` explicitly lists project-template
    trinity AS PM-only ("root and `project-template/`"). C's Check 36 PM-only
    keyword would WRONGLY fail correct PM-only commits.
  - S6 (SHOULD) — PACK-REVIEW-PHASE-2-DESIGNS.md §1 S6, lines 241-253.
    Same fix as B1-cascade — handled in one coordinated amendment.
- **Reviewer fix-shape:** Update C §8.1 + §10.2 + §12 (test plan) to make
  the `PM-only` keyword PERMIT `project-template/` trinity edits per actual
  `PACK-AGENTS.md:148` PM-only list. Drop the parenthetical "caught V10".
- **Actual PACK-AGENTS.md:142-148 PM-only Files list (verbatim — used as
  the corrected definition):**

  ```
  Files:
  - BACKLOG.md (regenerated mirror; per-entry source at /backlog/)
  - CHANGELOG.md (regenerated mirror; per-entry source at /changelog/)
  - README.md version table
  - PACK-CHAT.md
  - PACK-AGENTS.md
  - CLAUDE.md / AGENTS.md / GEMINI.md (root and project-template/)
  ```

- **Sections amended:**
  - §8.1 keyword-table PM-only row — rewritten to PERMIT project-template
    trinity, cite PACK-AGENTS.md:142-148 by line range, and reference the
    new §8.1a verbatim list. "Caught V10" parenthetical DROPPED.
  - §8.1 measurable-test bullet list — the PM-only test fixture that
    previously asserted FAIL on `project-template/CLAUDE.md` edits now
    asserts PASS (correct per actual PACK-AGENTS.md list). An additional
    V2-shape PM-only fixture (subject `"PM-only: ..."` touching
    `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md`) added as the
    asserts-FAIL fixture (supporting-docs is NOT in the PM-only Files
    list per CLAUDE.md trinity rule).
  - §8.1a (new subsection) — paste the verbatim PACK-AGENTS.md:142-148
    PM-only Files block + the post-B + B-fix path-substitution rules
    (paths inside `pack-ops/` after relocations) + the canonical
    PERMITTED-PATHS regex for Check 36 PM-only keyword + a directives
    block on README.md (Check 36 cannot distinguish version-table edits
    from other-section edits; the narrower discipline stays Pack Chat's
    via M1a) + a forward-pointing note on PACK-AGENTS.md:150-158
    directories (per-entry trees Batch-23-materialized). Cross-reference
    to B1-cascade + S6 fix-pass added at the foot of §8.1a.
  - §10.2 worked example — V10 worked example DROPPED with explicit
    rationale (V10 collapses to NO-ACTION per Architect A fix-pass per
    B1; using `8ba0164` here would encode the misreading into M1b). The
    corrected worked example uses V2 (`aaa61b3`) in its hypothetical
    PM-only-keyword shape (had the commit subject been
    `"docs: v11 — PM-only Batch 19b cleanup"`, the
    `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` edit would fail
    Check 36 because supporting-docs is NOT in the PM-only Files list).
  - §12 test plan — M5a row implicitly references §8.1's measurable
    tests; no separate edit needed since the §8.1 bullets are the
    canonical test definitions and §12 says "Three test commits in CI
    fixture branch (`pack-only` claiming touching `project-template/`,
    etc.) — all MUST FAIL Check 36 with file-path callout." Note: §12's
    table summary line for M5a is intentionally not re-stated — it's a
    pointer summary, and the canonical fixtures are §8.1 which IS updated.
    Re-stating in §12 would force a divergent fixture definition. Phase 5
    coder reads §8.1 for fixtures and §12 for coverage.
- **How this satisfies the fix-shape:** The reviewer fix-shape names §8.1
  + §10.2 + §12 as the surfaces requiring update. §8.1 + §10.2 are amended
  directly; §12 reads through to §8.1's fixtures and is now correct via
  the §8.1 update. The PACK-AGENTS.md:142-148 list is pasted verbatim in
  the new §8.1a so the corrected definition is traceable; the V10 worked
  example is dropped explicitly with rationale (so future readers cannot
  resurrect the misreading by mistake). The corrected V2-shape test
  fixture replaces it.

### §16.4 — S4 (SHOULD) — explicit Override 9 citation block

- **Reviewer finding:** PACK-REVIEW-PHASE-2-DESIGNS.md §1 S4, lines 201-216.
  C's M2 codification (§4) + project-side mirror (§4.2) are substantively
  correct per Override 9 (different wording per audience is intentional),
  but C did not cite Override 9 explicitly. Reviewer reading C alone could
  not tell whether the two-trinity codification was user-confirmed or
  unilateral. Override 9 also says "no cross-trinity drift gate" — C's
  design implicitly aligned but did not state it.
- **Reviewer fix-shape:** Add explicit citation: "Per
  AUDIT-USER-CURATION.md Override 9, the pack-side and project-side
  P-missed-7 codifications are intentionally different in wording. No
  Check 18 H2 parity gate applies to the new bullet."
- **Sections amended:**
  - §4.1 (new subsection) — added immediately before §4.2. Cites Override
    9 with a quote-block of the user-curation text; states explicitly
    that the pack-side bullet and project-side mirror are
    audience-specific by design. Adds an "Implication for Check 18 H2
    parity" sub-block that distinguishes WITHIN-trinity parity (continues
    to apply per CLI-files-cross-CLI-parity) from CROSS-trinity parity
    (pack-root trinity vs project-template trinity) — which is REJECTED
    per Override 9. Adds a measurable-consequence sub-block clarifying
    that the M2 measurable test (§4 last paragraph) does NOT fire on the
    pack-side-vs-project-side wording difference.
- **How this satisfies the fix-shape:** Override 9 is now cited
  explicitly with a quote-block + authority pointer. The "no cross-trinity
  drift gate" implication is stated directly + scoped to Check 18 H2
  parity specifically (the existing CI gate readers might worry about).
  Future readers + Phase 4 planner + Phase 5 coder cannot infer that the
  pack-side / project-side wording must match — and a reviewer cannot
  introduce a new "cross-trinity drift gate" check by accident.

### §16.5 — S5 (SHOULD) — `pack-ops/` path-prefix in project-side mirror deny-list

- **Reviewer finding:** PACK-REVIEW-PHASE-2-DESIGNS.md §1 S5, lines 219-237.
  C's §4.2 project-side mirror text deny-list uses bare filenames for
  PACK-AGENTS.md / PACK-CHAT.md (correct for grep regardless of new path)
  but does NOT name `pack-ops/` path-prefix. Symmetric with M2: the
  project-side mirror also needs `pack-ops/` path-prefix.
- **Reviewer fix-shape:** Add to §4.2 project-side mirror text:
  `pack-ops/ (any file there)` to the deny-list — matches the symmetric
  pack-side P-missed-7 expansion.
- **Sections amended:**
  - §4.2 project-side mirror text — the deny-list paragraph ("Files at
    the pack repo ...") now lists `pack-repo pack-ops/ — any file under
    pack-ops/, including BOUNDARY-DEFINITION.md, BACKLOG.md, CHANGELOG.md,
    etc. post Architect B + B-fix" alongside the existing
    PACK-AGENTS.md / PACK-CHAT.md / pack-* agent prompts /
    pack-repo maintenance-docs/ entries. The added qualifier "any file
    under pack-ops/" matches the symmetric pack-side P-missed-7
    expansion from M2 §6 / §8.2.
- **How this satisfies the fix-shape:** Project-side trinity readers
  (project PM chat at client install) now see `pack-ops/` named
  explicitly as a deny-target. The phrasing "any file under pack-ops/"
  is path-prefix-equivalent and matches the grep contract used by
  Check 37 (M2 amendment). Symmetric coverage with the pack-side
  P-missed-7 expansion.

### §16.6 — Unaffected sections

The following sections were NOT amended by this fix-pass and remain
intact per the reviewer's recommended scope:

- §0 (scope boundary), §1 (regression mechanism), §2 (design philosophy),
  §3 (coverage matrix structure — though individual rows reference
  §8.1 / §8.2 updates).
- §4 main P-missed-7 bullet text (the bullet itself is untouched;
  §4.1 added beside it as a citation block per S4).
- §4.2 project-side mirror BULLET STRUCTURE (only the deny-list
  paragraph was edited per S5; the rest of the mirror text + the
  measurable-test paragraph are unchanged).
- §5 (M3 reviewer + implementer SSOT-investigation gates), §6 main
  skill content (only step 4 Path-prefixes bullet was edited per M2);
  §7 (M6 SSOT-rotation reminder), §9 (M7 + M8 trinity-rule + TYPE-5
  gates), §10 main M1a memory-rule + §10.2 header (the worked example
  body was rewritten per B1-cascade; the surrounding M1b convention
  text + the keyword-table in §10.2 are unchanged).
- §13 dependency graph (only Step 11 annotation added per M4);
  §14 (constraints + gaps + open questions), §15 (summary).
- Cross-references to Architect A's `ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md`
  and Architect B's `ARCHITECTURE-DIRECTORY-REORGANIZATION.md` + B-fix's
  `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` are preserved
  throughout (the new §4.1 + §8.1a + §11 + §13 + §16 amendments cite
  these docs explicitly to maintain the cross-reference network).

### §16a — Phase 3 verification v2 amendment — HELP-FRAGMENT-TRACKER row staleness fix

- **Source:** `maintenance-docs/v11-implementation/PACK-REVIEW-PHASE-2-DESIGNS-VERIFICATION.md`
  §2 "One mild observation (informational, not a defect)" — Phase 3
  re-verification flagged the §8.2 deny-list row for
  `HELP-FRAGMENT-TRACKER.md` (line 584 at HEAD `8014186`) as still
  carrying "Architect-B-conditional — depends on byte-identity status
  post-B" wording, despite Architect B's design having finalized the
  byte-identity contract.
- **Why the prior wording was stale:** Architect B's
  `ARCHITECTURE-DIRECTORY-REORGANIZATION.md` §3 row #9 (line 167) AND
  B's M2 row in §6.1 (line 527) unconditionally relocate
  `HELP-FRAGMENT-TRACKER.md` to `pack-ops/HELP-FRAGMENT-TRACKER.md`
  and unconditionally retain CI Check 24's byte-identity contract
  between the pack-ops copy and `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`.
  Nothing in B-fix or B-fix v2 amendments reopens the contract. The
  "conditional" qualifier in the §8.2 row therefore implied a design
  uncertainty that does not exist.
- **What was changed:** The §8.2 deny-list row at line 584 area was
  reworded in place. The "Architect-B-conditional" qualifier is
  dropped; the cell now affirms the finalized byte-identity contract,
  names the post-B pack-side path (`pack-ops/HELP-FRAGMENT-TRACKER.md`),
  cites Architect B §3 #9 + M2 as authority, and notes that broader
  `pack-ops/` path-prefix coverage is the immediately-following row
  (the M2 `pack-ops/` row at line 587, already added in this doc's
  fix-pass per §16.1). The bare-filename row is retained because it
  catches project-side references that name `HELP-FRAGMENT-TRACKER.md`
  without a path prefix — a distinct grep shape from the `pack-ops/`
  path-prefix row.
- **Net effect on Phase 5 coder:** Identical to the pre-amendment
  state. The row already correctly flagged the file as pack-only;
  the rewording only removes a stale conditional qualifier and
  documents the finalized contract. No fixture, no check semantics,
  no order-of-land step changes.
- **Sections NOT touched:** All other sections of this design
  (§0-§15, §16.1-§16.6) are unchanged. Only the line 584 row cell
  and this §16a note were added.

---

## End of architecture design

Architect C / Phase 2 / BD-175 work complete. No design content in Architect A's or Architect B's domain. Conditional dependencies on B surfaced explicitly. Test plans per mechanism. Phase 3 reviewer receives this alongside A's and B's outputs for cross-architect verification.

