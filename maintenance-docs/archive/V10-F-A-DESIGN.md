# V10-F-A-DESIGN — Kickoff surface-declaration gate auto-inference + kickoff prose hardcoded environmental assumptions

**Author:** pack-architect (Phase 4 patch design pass)
**Date:** 2026-04-29
**Status:** Draft — design pass only. Implementer (parent pack chat) commits
after project-lead approval. This document does not edit any pack source file.
**Related:** `maintenance-docs/V10-PHASE-4-VERIFICATION.md` § F-A (proposed;
v10.0 patch — last in Option A sequence). Companion to `V10-F-D-DESIGN.md`,
`V10-F-E-F-F-DESIGN.md`, and `V10-F-G-DESIGN.md` (same Phase 4 patch cohort).

---

## 0. Status and scope

F-A is two related sub-defects rooted in the kickoff variant of
`project-template/docs/pack/prompts/pm-chat.md`:

- **F-A.1 — Gate auto-inference.** §4.1 F1 (Claude Code CLI on synthetic
  fixture) and §4.7 M-OT (Claude Code CLI on real-project OT clone) both
  show the assistant skipping the surface-declaration gate. The F1 evidence
  records the assistant printing `Surface: Claude Code CLI, shell confirmed.`
  and proceeding to Form R without the developer typing `shell`. The same
  evidence shows Form I (G7-install) and Form M (G7-machine) collapsed into
  the Form R results table as one-line preview annotations rather than
  rendered as separate gates. All substantive determinations were correct;
  no destructive action occurred. §4.2 DR1 / DR2 / DR3 docs-research
  predicts the same prompt-shape pattern will recur on Codex CLI, Gemini
  CLI, and Claude Desktop with Desktop Commander.
- **F-A.2 — Kickoff prose hardcoded environmental assumptions.** §4.3
  Claude Web manual-mode smoke records two prose-accuracy issues in the
  kickoff variant body: the assertion *"The GitHub connector is connected"*
  (false on a fresh Web chat without a Project + connector) and the
  instruction *"Please search project knowledge to read: ARCHITECTURE.md,
  IMPLEMENTATION_PLAN.md, STATUS.md, BACKLOG.md"* (Web-Project-specific
  capability). Both are environment assertions baked into prose that runs
  on every surface — including surfaces where the assertions are false.

The kickoff variant is the developer-pasted entry point to Procedure 7. It
is pasted on every project kickoff. METHODOLOGY § Procedure 7 is the
canonical procedure home and is RAG-indexed. Per project-lead constraints:
centralization is required, token efficiency in the kickoff body is
required, METHODOLOGY is read-only to the PM chat at runtime, and prior
patches (F-C, F-D, F-E+F-F, F-G) have already landed in v10.0.

The kickoff variant carries a **documented Convention exception**
(`pm-chat.md` line 23, BD-049): *"kickoff is a context handoff, not an
agent-task prompt. The labeled-section convention does not apply."* This
exception is preserved by the chosen design.

Scope of this design pass:

- F-A.1: choose between procedural enforcement (α), semantic acceptance (β),
  and hybrid (γ). Decide what to do about Form I / Form M collapse.
- F-A.2: choose between conditional prose (a), always-discover (b), and
  relocate-out (c). Bound the token cost of the kickoff body.
- Confirm coexistence with F-D (METHODOLOGY at `docs/pack/`), F-E+F-F
  (Procedure 5-S sentinel + post-migration housekeeping), and F-G
  (Format-vs-solutions: worked examples).
- Confirm cross-surface generality (4 shell-capable surfaces).
- Cascade inventory.
- Trinity-rule compliance.
- Self-check.

Out of scope (deferred to implementation or to v10.1):

- Producing diffs or final prose.
- Editing any pack source file.
- Filing the BD-NNN entry (Pack Chat owns).
- Verification fixture rebuild planning (Pack Chat / pack-planner own).
- F-B (b) — three cross-surface live-runs (Codex / Gemini / Desktop
  Commander) deferred to v10.1 per §0.6 / Part 4 of the verification plan.
- Live re-verification of §4.6 / §4.7 / §4.8 (per delta-evidence pattern
  established by F-D, F-E+F-F, F-G).
- F-G's separate solution-leakage scope (different defect; independent fix).

---

## 1. Decision — summary

### 1.1 F-A.1 — chosen direction: **β (semantic acceptance)** with a one-message no-action exit ramp

**Update METHODOLOGY § Procedure 7.0 to define the gate semantically rather
than syntactically: the gate fires when the assistant has declared its
surface AND has given the developer a single-message exit ramp before
running Form R. The assistant MAY declare its surface by inference on
shell-capable surfaces; it MUST NOT begin Form R discovery in the same
message as its surface declaration. On Web / Desktop surfaces where shell
is not available, the assistant declares `manual` and emits the SETUP-NEW
pointer per the existing manual branch.**

Form I and Form M collapse into Form R's preview table when their
idempotency rule fires (Form I: tool present and in-range; Form M: every
source/target pair byte-identical) — formalize "preview, no action needed"
as a recognized rendering and not a deviation. When they do NOT short-circuit
on idempotency, they render as full gates as today.

Companion edit to the kickoff variant body: replace the existing
surface-declaration prose (`pm-chat.md` lines 42–50) with a shorter form
that states the assistant's obligation as "declare surface and pause before
acting" rather than "ask the developer to type a word." The developer's
ability to override (`manual` mid-kickoff) is preserved per existing
Procedure 7.0 lines 1361–1365 wording, which is reused unchanged.

Total touch: METHODOLOGY § 7.0 (and § 7.1, § 7.2.3, § 7.2.4 for the Form
I/M preview formalization), and the kickoff-variant body in `pm-chat.md`.

### 1.2 F-A.2 — chosen direction: **(b) always-discover** with the doc list reframed as a fetch list

**Replace the kickoff-variant prose lines 52–58 of `pm-chat.md` (the
"GitHub connector is connected" assertion and the "search project knowledge"
instruction with the four-doc list) with a short surface-agnostic
discovery instruction: ask the assistant to locate and read the four named
docs by whatever means its surface provides (filesystem read on shell;
GitHub-connector search on Web with a Project + connector; ChatGPT custom
GPT knowledge on ChatGPT Web; Files-tab attachments otherwise). If none
of those work, the assistant reports what it can access and the PM chat
adapts.**

The four doc names (ARCHITECTURE.md, IMPLEMENTATION_PLAN.md, STATUS.md,
BACKLOG.md) are preserved — they are the project-context contract, not an
environmental assumption. What is removed is the assertion about HOW the
assistant retrieves them.

Total touch: ~6 lines of `pm-chat.md` kickoff body replaced with ~5 lines.

### 1.3 Combined cascade

**3 files touched** (METHODOLOGY + pm-chat.md + nothing else).
**Net line count: roughly 0** (kickoff body shrinks by ~8 lines; Procedure
7 grows by ~8 lines for the semantic-gate spec + Form I/M preview
formalization; the relocation is intentional given centralization
requirement).
**No trinity edits.** **No SETUP-NEW.md edit** (the manual branch already
points at `SETUP-NEW.md § Manual fallback 5.A–5.D` and that pointer
continues to fire correctly under the new design).

---

## 2. F-A.1 — rationale

### 2.1 Why β over α (procedural enforcement)

The α option strengthens kickoff-variant wording so the assistant truly
waits for an explicit `shell` reply: explicit "STOP. Wait for reply."
callout; explicit "Do not infer the surface from your environment"
sentence; restructure so the surface-declaration question is the LAST
message before reply.

α has been effectively in place since v10.0 ship — `pm-chat.md` line 50
already says *"Reply with the single word `shell` or `manual` before
continuing."* The §4.1 F1 and §4.7 M-OT evidence shows that this wording
does NOT enforce the gate against the assistant's auto-inference behavior.
The §4.2 DR1/DR2/DR3 docs-research analysis explicitly predicts the same
shape on Codex, Gemini, and Desktop Commander — concluding the issue is
"a prompt-shape issue (not model-specific)." Strengthening the wording
further is plausible but:

1. **The assistant's inference is correct.** When pasted into Claude Code
   CLI, the assistant's environment is unambiguous — it IS on a
   shell-capable surface. The §4.1 F1 inference (`Surface: Claude Code
   CLI, shell confirmed.`) is true. Asking the assistant to disregard
   correct, immediately-available context to wait for a developer to type
   a redundant word is procedurally cleaner but operationally pointless.
   Spending wording-budget to suppress correct inference is the wrong
   direction.

2. **Multi-LLM evidence convergent.** §4.2 predicts the same behavior
   across four model families (Anthropic Claude in two surfaces,
   OpenAI GPT in Codex, Google Gemini, and Anthropic Claude in Desktop
   Commander). When four independently-trained models all collapse the
   same procedural step in the same direction, the parsimonious read is
   that the step is procedurally redundant in the contexts where they
   collapse it — not that all four are misbehaving identically.

3. **The Web manual smoke (§4.3) shows the gate works correctly when it
   has informational value.** On Claude Web (no shell), the assistant
   replied `Surface: **manual**.` because the choice between `shell` and
   `manual` was actually a choice — the assistant could not run shell. The
   gate fires correctly when the surface is ambiguous from the assistant's
   POV (Web could in principle be Web-Desktop with Desktop Commander; the
   developer disambiguates by replying `manual`). The gate does NOT fire
   when the surface is unambiguous (CLI surfaces). β codifies this
   asymmetry rather than fighting it.

4. **α inflates the kickoff body.** Adding "STOP. Wait for reply."
   callouts plus "do not infer" prohibitions plus restructured ordering
   would add ~10–15 lines to the kickoff body. The kickoff body is
   pasted on every project kickoff. Token cost recurs for every developer.

### 2.2 Why β over γ (hybrid)

γ keeps the gate as a hard requirement on developer-facing surfaces (Web /
Desktop where the developer must explicitly choose between shell and
manual) but makes it optional on shell-only CLI surfaces.

γ is closer to β than α and is operationally similar to what β codifies.
The difference: γ frames the rule as "two surface classes have different
gate semantics," whereas β frames the rule as "the gate fires when the
developer's choice carries information." On Web, the developer's choice
genuinely disambiguates (they could have Desktop Commander or not; they
could have a Project / connector or not). On a CLI, the developer's
choice carries no information beyond what the assistant already knows.
β's framing is the more accurate generalization.

γ also requires the kickoff body to express the rule in surface-class
terms ("if you are on a CLI..., if you are on Web..."), which is a
maintenance burden when surface classes evolve (e.g., a future surface
that doesn't fit cleanly). β expresses the rule in semantic terms and
does not enumerate surfaces in the gate spec — surfaces are enumerated
elsewhere (`pm-chat.md` lines 46–47, METHODOLOGY § Procedure 7.0).

### 2.3 Why Form I and Form M collapse to "preview" is consistent with β

The §4.1 F1 evidence shows the assistant collapsed Form I and Form M into
the Form R results table:

- Form I (G7-install): `skipped by idempotency (swift-format 602.0.0
  in-range)` — this is the EXACT condition Procedure 7.6 idempotency rules
  prescribe for Form I (`command -v <tool>` returns a path AND
  `<tool> --version` is within pack-tested range → emit single-line
  `note:`, do not render Form I).
- Form M (G7-machine): `not applicable (no $PACK companion template
  source)` — this is a §7.4 sub-condition (skip with single-line note when
  source files are not present).

In both cases, Procedure 7.6 already says "emit a single-line `note:`
diagnostic and moves on without re-rendering." The §4.1 deviation is the
assistant rendering those `note:` lines INSIDE the Form R results table
rather than as separate Form-rendering passes. The substantive outcome —
no install action, no machine-level write — is identical to what
rendering the gates separately would have produced.

The fix on the Form I / Form M side is wording, not behavior:
**formalize "preview" (the inline note rendering inside Form R) as a
recognized rendering for the idempotency-fired and not-applicable
sub-cases.** The full gate renders only when there is something to gate
(install proposed; machine-level write proposed). When idempotency or
not-applicable fires, the preview is the gate — there is nothing for the
developer to approve or skip because there is no proposed action. This
is consistent with §7.6's "moves on without re-rendering" wording but
makes explicit that an inline preview is the canonical render.

The §4.7 M-OT evidence (Form I rendered "as inline 'preview, no action
needed' with no separate gate") is the same pattern. Formalizing it
removes the deviation classification from §4.7.

### 2.4 Cross-surface check

β + Form I/M preview formalization generalizes:

| Surface | β behavior | Form I preview | Form M preview |
|---|---|---|---|
| Claude Code CLI | declare `shell` by inference; one-message pause; proceed | fires when tool in-range | fires when source missing or byte-identical |
| Codex CLI | declare `shell` by inference; one-message pause; proceed; respect workspace-write sandbox on Form I `yes` (v10.1 docs gap per F-B (b) item 2) | fires when tool in-range | fires when source missing or byte-identical |
| Gemini CLI | declare `shell` by inference; one-message pause; proceed; if in `/plan` mode, declare `shell` is unavailable and ask developer to exit `/plan` (v10.1 docs gap per F-B (b) item 3) | fires when tool in-range | fires when source missing or byte-identical |
| Desktop Commander | declare `shell` by inference; one-message pause; proceed; respect filesystem-MCP allowlist on Form M `yes` (v10.1 docs gap per F-B (b) item 4) | fires when tool in-range | typically fires (default skip per existing §7.2.4) |
| Claude Web (no MCP) | declare `manual`; emit SETUP-NEW pointer; do NOT enter Procedure 7 (per existing § 7.0 line 1357–1359) | n/a | n/a |
| ChatGPT Web | declare `manual`; emit SETUP-NEW pointer; do NOT enter Procedure 7 | n/a | n/a |

The four shell-capable surfaces all use the same β inference path. The
two non-shell surfaces use the existing manual branch unchanged. The
v10.1-deferred per-surface details (Codex sandbox escalation, Gemini
plan-mode detection, Desktop Commander allowlist) are not blocked by the
β change — they layer onto Procedure 7's existing failure-handling
discipline (§7.4) when v10.1 lands them.

### 2.5 Convention exception (BD-049) preservation

The kickoff variant carries the `pm-chat.md` line 23 exception: *"kickoff
is a context handoff, not an agent-task prompt. The labeled-section
convention does not apply."* β does not introduce labeled sections. The
kickoff body remains unstructured prose with the project-context block,
the surface-declaration line, the doc list, and the continuation
pointer. The β edit is rewording within the existing structure, not
restructuring. **Convention exception preserved.**

### 2.6 What β does NOT do

- Does not change the developer's ability to override mid-kickoff
  (`pm-chat.md` Procedure 7.0 lines 1361–1365 wording is reused unchanged).
- Does not remove the surface-declaration concept — the assistant still
  declares its surface; the change is who declares it and how.
- Does not change Form R, Form E, Form I, or Form M body specs (only the
  rendering rule for Form I / Form M when idempotency fires).
- Does not change SETUP-NEW.md — the manual branch pointer continues to
  fire correctly per §4.3 evidence (M2 reply correctly named `SETUP-NEW.md
  § Manual fallback 5.A–5.D`).

---

## 3. F-A.2 — rationale

### 3.1 Why (b) over (a) (conditional prose)

(a) inflates kickoff body with surface-conditional prose:

> *"If on Claude Web with a Project + GitHub connector: search project
> knowledge for these docs. If on shell-capable surface: read these docs
> from the local repo at these paths. If on Web without project/connector:
> report manual and the PM chat will guide you."*

This roughly triples the size of the doc-list section (from ~6 lines to
~18 lines). It also bakes in a specific enumeration of surface-class
behaviors that must be maintained when surfaces evolve. It also forces
the developer to read every conditional branch even though only one
applies to their session. Token cost recurs on every kickoff paste.

### 3.2 Why (b) over (c) (relocate doc list to Procedure 7 sub-step)

(c) keeps the kickoff body short by moving the doc-list out entirely —
e.g., into Procedure 7 as a post-surface-declaration sub-step.

The asymmetry: the doc list is part of the project-context contract, not
part of Procedure 7. Even on `manual` (where Procedure 7 is not entered
per §7.0), the assistant still needs to know what project documents
exist and try to read them. Relocating the doc list out of the kickoff
body into Procedure 7 would either (i) require `manual` to load Procedure
7 anyway just to retrieve the list (defeats the manual-branch
short-circuit), or (ii) require duplicating the list into both Procedure
7 AND SETUP-NEW.md § Manual fallback (duplicates content; centralization
violation).

(b) keeps the list in the kickoff body where both branches see it once
and replaces only the assertion about HOW to retrieve them.

### 3.3 Why (b) is the right form

The kickoff body's job for the doc list is to **name the project-context
docs the assistant should attempt to read**. The current prose conflates
this with **prescribing a specific retrieval mechanism** (GitHub connector
+ search project knowledge). Decoupling them:

- The list of docs (ARCHITECTURE.md, IMPLEMENTATION_PLAN.md, STATUS.md,
  BACKLOG.md) is a project-level convention. It applies regardless of
  surface. Keep.
- The retrieval mechanism varies by surface. Replace the assertion with a
  short discovery instruction: the assistant locates and reads the docs
  by whatever means its surface provides; if it cannot access any, it
  reports what is available and the PM chat adapts.

This is "format requirements vs. solutions" applied to the kickoff
prose: the four doc names are the requirement; the retrieval mechanism
is the solution; the kickoff should specify the requirement and let the
assistant choose the solution. (This is the same principle as F-G's rule,
applied to kickoff prose rather than to PM-chat-generated agent prompts.)

### 3.4 What replaces lines 52–58

Approximate replacement shape (final wording is implementer's; this is
content sketch only):

> *"Project documents the PM chat needs in context: ARCHITECTURE.md,
> IMPLEMENTATION_PLAN.md (current phase), STATUS.md, BACKLOG.md. Locate
> and read these by whatever means your surface provides — local repo
> read on shell-capable surfaces; project-knowledge or GitHub-connector
> search on Claude Web with a Project + connector; equivalent retrieval
> on other surfaces. If you cannot access them, report what you can
> reach and I will adapt."*

~5 lines, surface-agnostic, no environment assertion. The assistant on
shell reads the local files; the assistant on Claude Web with a Project +
connector searches project knowledge; the assistant on plain Claude Web
reports inability and the PM chat hand-feeds context. All three branches
work without surface-class prose in the kickoff body.

### 3.5 What (b) does NOT do

- Does not change which docs the PM chat expects to see (same four).
- Does not change the manual-branch behavior (assistant still reports
  inability when nothing is reachable).
- Does not require any SETUP-NEW.md edit.
- Does not change CLAUDE.md / AGENTS.md / GEMINI.md trinity content.

---

## 4. Interaction with prior patches

### 4.1 F-D (METHODOLOGY canonical at `docs/pack/`)

F-D moved METHODOLOGY.md to `docs/pack/METHODOLOGY.md` per F-D-DESIGN
decision. The kickoff body's continuation pointer (`pm-chat.md` lines
84–91) currently references `supporting-docs/METHODOLOGY.md` Procedure 7.
This is **stale** post-F-D — the project-tree path is now
`docs/pack/METHODOLOGY.md` (F-D resolved-state per §10.1–§10.4 evidence).

**The F-A.1 edit to the kickoff body's continuation pointer must update
the path to `docs/pack/METHODOLOGY.md`.** This is a small piggyback fix on
the F-A patch, not a separate defect — the F-D patch landed without
touching `pm-chat.md` because pm-chat.md was not in F-D's cascade.
F-A.1 touches `pm-chat.md` lines 42–91 anyway, so the path-update is
free.

The same `supporting-docs/METHODOLOGY.md` reference appears at line 28
("Shell-capable surfaces run kickoff auto-discovery (METHODOLOGY.md
Procedure 7); non-shell surfaces use SETUP-NEW.md § Manual fallback.")
— this line is fine as-is because it does not name a path, only a file
name. No edit required there. The line-89 reference (`SETUP-NEW.md §
Manual fallback`) is also fine — SETUP-NEW.md is at `supporting-docs/`
in the pack and is not copied into the project tree under v10.

### 4.2 F-E + F-F (Procedure 5-S sentinel + post-migration housekeeping)

F-E + F-F added Procedure 5-S to METHODOLOGY (post-migration housekeeping
trigger via `.pack-migration-pending` sentinel; pm-startup SKILL Step 0
detects both Procedure 5-R and 5-S triggers). Procedure 5-S handles
stale pack-version markers and unfilled trinity placeholders.

**Does the kickoff variant need to mention Procedure 5-S?** No.
Procedure 5-S triggers post-migration via the sentinel that
`migrate-v9-to-v10.sh` writes. Kickoff is the entry point for fresh
projects (init-project.sh path) AND for migrated projects on next PM
chat startup, but the trigger detection is inside `/pm-startup` SKILL
Step 0, not inside the kickoff prompt body. The kickoff variant's job is
to deliver project context and route to Procedure 7; the housekeeping
detection is a separate routing step that happens before kickoff parsing
in the post-migration case. **No conflict; no edit required to kickoff
for F-E + F-F coexistence.**

### 4.3 F-G (Format-vs-solutions: worked examples)

F-G added `### Format-vs-solutions: worked examples` to METHODOLOGY §
Prompt Authoring Principles. F-G's audit (§4.2 of F-G-DESIGN) checked
all 4 variants of `pm-chat.md` and recorded the kickoff variant as
**clean** (line 308 of V10-F-G-DESIGN.md: *"Variant: kickoff. Carries
documented convention exception. No prescriptive content beyond
surface-detection and read-list. Clean."*).

The F-A.1 + F-A.2 edits to the kickoff variant body do not introduce
solution leakage:

- F-A.1 reformulates the surface-declaration mechanism (procedural ->
  semantic). The new wording asks the assistant to "declare and pause";
  it does not prescribe an implementation technique.
- F-A.2 replaces the GitHub-connector assertion with a discovery
  instruction. The new wording names the requirement (which docs the PM
  chat needs) without prescribing the retrieval mechanism. This is the
  exact pattern F-G's worked examples codify (Example 2 — API/framework
  name leakage; the negative names a specific retrieval API, the
  positive names the requirement).

**F-A's wording is itself an instance of F-G's rule applied to kickoff
prose.** No conflict; the patches reinforce each other.

### 4.4 F-C (legacy `docs/pack/METHODOLOGY.md` cleanup)

F-C resolved as part of F-D (combined fix per project-lead Decision 3 at
§10.10 of V10-PHASE-4-VERIFICATION.md). No interaction with F-A.

### 4.5 BD-049 Convention exception

BD-049 originated the Convention exception that the kickoff variant
carries. F-A preserves the exception (§2.5 above). F-A.1 + F-A.2 do not
add labeled sections (Problem / Goal / Success criteria) — they reword
existing prose within the existing exception structure.

---

## 5. Cascade — files that change

### 5.1 Pack source files

| # | File | Change |
|---|---|---|
| 1 | `project-template/docs/pack/prompts/pm-chat.md` Variant: kickoff body, lines 42–91 | (a) Replace lines 42–50 (surface-declaration block) with shorter β wording: assistant declares surface and pauses one message before Form R; developer can override with `manual` / `wait`. (b) Replace lines 52–58 (GitHub-connector assertion + search-project-knowledge instruction) with discovery instruction per §3.4. (c) Update lines 84–91 continuation pointer: change `supporting-docs/METHODOLOGY.md` to `docs/pack/METHODOLOGY.md` (post-F-D path). (d) Line 28 path-name reference is fine as-is. **Net change: ~−8 lines kickoff body** (replaced 6+9 lines with shorter equivalents, plus path update). |
| 2 | `supporting-docs/METHODOLOGY.md` § Procedure 7.0 (lines 1354–1365) | Update wording: gate fires when assistant declares surface AND emits one-message no-action exit ramp before Form R. Existing line 1361–1365 wording (developer may declare `manual` even on shell-capable surface; may switch mid-kickoff) is reused unchanged. **Net change: ~+5 lines.** |
| 3 | `supporting-docs/METHODOLOGY.md` § Procedure 7.1 (lines 1367–1398) and § 7.2.3 (lines 1458–1476) and § 7.2.4 (lines 1478–1502) | Add explicit "preview rendering" sub-paragraph to each: when the idempotency rule fires (Form I) or source files are missing / byte-identical (Form M), the gate renders as a single-line note inside the Form R results table rather than a full Form. Reference the existing § 7.6 idempotency rules (which already prescribe the "single-line `note:` diagnostic and moves on without re-rendering" behavior). **Net change: ~+3 lines per Form section, ~+9 total.** |

**Net METHODOLOGY change: ~+14 lines.** Kickoff body shrinks ~8 lines.
**Pack-wide net: ~+6 lines.**

### 5.2 Files NOT changed (and why)

- **`supporting-docs/SETUP-NEW.md` § Manual fallback (5.A–5.D).** The
  manual-branch pointer in `pm-chat.md` line 89 continues to fire
  correctly per §4.3 evidence. The Manual fallback content does not
  carry any environmental assumptions that need the F-A.2 fix —
  developers run the listed shell commands locally and report values
  back. **No edit.**
- **`project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md`.** Trinity
  files do not carry kickoff prompt content or Procedure 7 procedural
  spec. METHODOLOGY (now at `docs/pack/`) is referenced by the trinity
  generically (per F-D's resolved trinity table); no path or wording
  change in trinity is required. **No edit.**
- **`project-template/docs/pack/prompts/pm-chat.md` other variants
  (backlog-status-update, generate-setup, generate-agent-kickoff).**
  None of the other three variants carry surface-declaration prose or
  GitHub-connector assertions. They are PM-chat self-prompts run after
  surface is established. **No edit.**
- **`project-template/docs/pack/PM-CHAT.md`** (the PM-chat startup and
  operating instructions doc, distinct from `pm-chat.md` prompt
  templates). Carries no kickoff body content. **No edit.**
- **`scripts/init-project.sh` / `scripts/migrate-v9-to-v10.sh`.** No
  scripted detection of surface-declaration semantics; scripts do not
  parse kickoff body. **No edit.**
- **Pack-repo `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` / `PACK-AGENTS.md`.**
  Govern pack-repo agent behavior, not project PM-chat-with-developer
  behavior. **Out of scope.**
- **`maintenance-docs/V10-DESIGN.md` / V10-IMPLEMENTATION-PLAN.md.**
  Design docs, not pack source. F-A is a Phase 4 patch; design docs
  are not retroactively edited per the convention used by F-D / F-E+F-F /
  F-G. **No edit.**

### 5.3 Total touch surface

**2 files** (`pm-chat.md` + METHODOLOGY.md). **No trinity edits.** **No
script edits.** **~+6 net lines pack-wide.** Comparable in scope to F-G
(2 files, ~+12 net lines) and smaller than F-D (5 files behavioral
patch).

---

## 6. Trinity-rule compliance

Per CLAUDE.md trinity rule: when modifying `project-template/CLAUDE.md`,
make the parallel edit in `AGENTS.md` and `GEMINI.md` in the same commit.

**F-A modifies neither `project-template/CLAUDE.md` nor `AGENTS.md` nor
`GEMINI.md`.** The trinity rule does not engage. The kickoff variant
body (`pm-chat.md`) is single-source per the project-lead constraint
("Trinity rule applies to project-template/CLAUDE.md / AGENTS.md /
GEMINI.md but NOT to pm-chat.md (which is single-source)"). METHODOLOGY
is also single-source.

**Trinity-rule status: clean. No parallel edits required.**

---

## 7. Self-check

| Property | Status |
|---|---|
| F-A.1 decision (β) defended with logic? | **Yes.** §2.1 (vs α: assistant inference correct, multi-LLM convergent, gate has informational value only when surface ambiguous, α inflates kickoff body), §2.2 (vs γ: β is the more accurate generalization; γ enumerates surface classes that may evolve), §2.3 (Form I/M preview consistent with existing § 7.6), §2.4 (cross-surface generality). |
| F-A.2 decision (b) defended with logic? | **Yes.** §3.1 (vs a: triples kickoff body size; bakes surface enumeration; recurring token cost), §3.2 (vs c: doc list is project-context contract not Procedure 7; relocation forces duplication or manual-branch loads Procedure 7 anyway), §3.3 (b decouples requirement from solution; same principle as F-G applied to kickoff prose). |
| Convention exception (BD-049) preserved? | **Yes — verified in §2.5.** No labeled sections introduced. Edits reword existing prose within existing exception structure. |
| Coexists with F-D (METHODOLOGY at `docs/pack/`)? | **Yes — and F-A piggybacks the path update.** kickoff body line 84–91 continuation pointer currently still references `supporting-docs/METHODOLOGY.md`; F-A updates to `docs/pack/METHODOLOGY.md` as part of its scope (small free fix on a file F-A is editing anyway). |
| Coexists with F-E + F-F (Procedure 5-S)? | **Yes — verified in §4.2.** Procedure 5-S triggers via sentinel + `/pm-startup` SKILL Step 0 (out-of-band of kickoff body). No kickoff body interaction. |
| Coexists with F-G (Format-vs-solutions worked examples)? | **Yes — and F-A.2 is itself an instance of F-G's rule applied to kickoff prose.** F-G audit recorded kickoff variant as clean; F-A's edits do not introduce solution leakage; the F-A.2 form (decouple requirement from solution) reinforces F-G's pattern. |
| Generalizes across 4 shell-capable surfaces (Claude CLI / Codex / Gemini / Desktop Commander)? | **Yes — verified in §2.4 table.** β inference path is identical across all four shell-capable surfaces. v10.1-deferred per-surface details (Codex sandbox, Gemini plan-mode, Desktop Commander allowlist) layer onto Procedure 7's existing failure-handling discipline (§7.4) and are not blocked by β. |
| F-A wording itself avoids solution leakage (per F-G)? | **Yes — verified inline.** F-A.1's β wording asks the assistant to "declare and pause" — a behavioral requirement, not a technique. F-A.2's discovery wording names the doc list (requirement) and asks the assistant to choose retrieval (solution). The Form I / Form M "preview" formalization names the rendering condition (when idempotency fires) and the rendering shape (single-line note inside Form R) — both are format requirements, not solution prescriptions. |
| Centralization preserved? | **Yes.** Procedure spec (the gate semantics + Form I/M preview rules) lives in METHODOLOGY § Procedure 7 (canonical). The kickoff body carries the developer-facing entry-point summary only (~5 lines for surface-declaration; ~5 lines for doc-list discovery; ~6 lines for continuation pointer). RAG ingest of Procedure 7 covers the spec; kickoff body covers what the developer sees on paste. |
| Token efficiency in kickoff body? | **Yes.** Net kickoff body change: ~−8 lines (down from ~50 to ~42). This is a recurring saving on every kickoff paste. |
| Boundary discipline preserved? | **Yes.** No new write surfaces. METHODOLOGY remains read-only to the PM chat at runtime. The kickoff body is read by the assistant on paste; no agent-output write involved. |
| Adjacent-precedent symmetry with F-D / F-E+F-F / F-G design? | **Yes.** F-D resolved a contradiction by aligning multiple sources to one canonical (META + scripts + trinity). F-E+F-F centralized post-migration housekeeping in Procedure 5-S with a sentinel-driven trigger. F-G centralized prompt-authoring guidance in METHODOLOGY worked examples. F-A centralizes gate semantics in METHODOLOGY § Procedure 7 and reduces kickoff body to entry-point summary. All four follow the same pattern: canonical procedure home in METHODOLOGY (RAG-indexed); short developer-facing pointers in pasted prompts. |

---

## 8. Open questions for project lead

**OQ-F-A-1.** Should the assistant's "one-message no-action exit ramp"
have a specific wording the PM chat is asked to recognize (e.g., explicitly
naming `wait` / `manual` / proceed)?
*Recommendation: **specify the exit-ramp shape in METHODOLOGY § 7.0 but
not the literal words**. The shape: assistant's first message after
kickoff paste declares surface and lists the next planned action;
assistant does not begin the next planned action in the same message;
developer's reply is interpreted per the existing § 7.5 reply grammar
(which already covers `yes` / `no` / `skip` / `abort` / `edit`). On a
shell-capable inference, the assistant treats absence-of-objection +
positive reply (`yes`, `proceed`, or just `<Enter>`) as authorization to
run Form R. Specifying the literal words further would over-constrain;
the existing § 7.5 reply grammar is sufficient. Project lead confirms.*

**OQ-F-A-2.** Should the kickoff variant's "Before pasting" preamble
(`pm-chat.md` lines 25–28) be edited under F-A.2's discovery framing?
*The current preamble warns about Gemini plan-mode and Web manual mode.
These are operational warnings to the developer (before pasting); they
do not assert anything about the assistant's environment. **No F-A.2
edit needed for the preamble.** The Gemini plan-mode warning becomes
unnecessary if Procedure 7's plan-mode-detection v10.1 candidate
(F-B (b) item 3) lands; that's a v10.1 question. Project lead confirms
preamble is left alone in F-A.*

**OQ-F-A-3.** Should the "preview" rendering formalization in § 7.2.3 /
§ 7.2.4 also apply to § 7.3 (gRPC sub-flow Form I gates) for symmetry?
*Recommendation: **yes**. The same idempotency rule fires in § 7.3.1 /
§ 7.3.2 (already-installed gRPC tools at in-range version → § 7.6
single-line note). The preview formalization should be a generic Form I
behavior (and likewise Form M generic), not § 7.2-specific. Cleanest
implementation: add the preview rendering rule to § 7.6 itself, then
reference from § 7.2.3 / § 7.2.4 / § 7.3.1 / § 7.3.2. This is one
location instead of four. Project lead confirms placement.*

**OQ-F-A-4.** Should the kickoff body's discovery instruction (F-A.2)
include an explicit example of what "report what you can access" looks
like, to anchor the assistant on the manual-fallback case?
*Recommendation: **no**. The §4.3 evidence shows the assistant on Claude
Web correctly identified what was accessible (Gmail/GCal/GDrive/HF
connectors visible; no GitHub connector; no Project) and reported it
without an example to anchor on. Adding an example would inflate the
kickoff body for a behavior that already works. The PM chat's reply on
manual handles the adaptation. Project lead confirms.*

**OQ-F-A-5.** Should the F-A patch include a note in METHODOLOGY § 7.0
about the historical pattern (assistant on shell collapses gates by
inference; this is sanctioned behavior under β) so future verification
work doesn't re-flag it as a deviation?
*Recommendation: **yes — one line**. A single sentence in § 7.0 stating
that on shell-capable surfaces the assistant typically declares its
surface by inference rather than asking the developer, and that this is
sanctioned. This pre-empts the next round of verification from re-filing
F-A as a fresh defect. ~1 line. Project lead confirms.*

**OQ-F-A-6.** Does F-A change anything about how the kickoff body
handles the existing "If `PM-CHAT.md` exists in the project root with
`[PROJECT_NAME]` still as a placeholder, fill it in now" block
(`pm-chat.md` lines 70–73)?
*No F-A edit to that block. It is a post-surface-declaration follow-on
task and is independent of the surface-declaration gate and the doc
discovery. F-F's Procedure 5-S handles the migration-time placeholder
case; the kickoff-time block here handles the fresh-project case. They
do not overlap. Confirmed independent; **no edit**.*

---

## 9. What F-A explicitly does NOT do

- **Does not re-litigate F-G** (format-vs-solutions in PM-chat-generated
  prompts). F-A is about the kickoff variant body itself — the prompt
  the developer pastes into a chat, not the prompts the PM chat generates
  for downstream agents. F-A.2's discovery instruction is consistent
  with F-G's worked examples but does not duplicate or modify them.
- **Does not change PM chat behavior for non-kickoff variants**
  (backlog-status-update, generate-setup, generate-agent-kickoff). Those
  variants are PM-chat self-prompts and do not carry surface-declaration
  prose or environmental assertions.
- **Does not require live re-verification of §4.6 / §4.7 / §4.8** (per
  delta-evidence pattern from F-D / F-E+F-F / F-G). The F-A patch
  delta-verification fixture set covers: (a) §4.1-shape kickoff smoke on
  Claude Code CLI to confirm β behavior renders correctly and Form I/M
  preview lands as documented; (b) §4.3-shape Web manual smoke to confirm
  the F-A.2 discovery instruction works on the no-connector case; (c)
  paper trace through Codex / Gemini / Desktop Commander spec text per
  §4.2 to confirm β still applies. Live runs on the three deferred
  surfaces remain F-B (b) / v10.1 work. Implementer (or pack-planner)
  scopes the §11 delta-verification fixture set; this design pass does
  not.
- **Does not address F-B (b)** — three cross-surface live-runs deferred
  to v10.1 per §0.6 / Part 4 of the verification plan. The four v10.1
  candidates (Codex sandbox escalation, Codex Form I `yes`-path, Gemini
  plan-mode detection, Desktop Commander MCP-scope check) layer onto
  Procedure 7's existing § 7.4 failure-handling and are not blocked by
  F-A.
- **Does not change the surface enumeration in `pm-chat.md` lines 46–47**
  ("Claude Code CLI, Codex CLI, Gemini CLI, or Claude Desktop with
  Desktop Commander enabled" / "Claude Web, ChatGPT Web"). The β change
  is to how the gate fires, not to the list of recognized surfaces.
- **Does not touch SETUP-NEW.md.** The manual-fallback content remains
  authoritative for the `manual` branch.

---

## 10. Summary

**Decision:**

- **F-A.1 — direction β (semantic acceptance) with one-message no-action
  exit ramp.** Procedure 7.0 redefines the gate semantically: fires when
  assistant has declared surface AND emitted a one-message pause before
  Form R. On shell-capable surfaces the assistant typically declares
  surface by inference; on Web / Desktop without shell the assistant
  declares `manual` and emits the SETUP-NEW pointer. Developer override
  preserved per existing § 7.0 lines 1361–1365. Form I / Form M render as
  single-line "preview" inside Form R's results table when the idempotency
  rule fires (existing § 7.6 behavior, formalized as a recognized
  rendering rather than a deviation).
- **F-A.2 — direction (b) always-discover.** Replace the GitHub-connector
  assertion + search-project-knowledge instruction in the kickoff body
  with a short surface-agnostic discovery instruction that names the four
  required docs (ARCHITECTURE.md, IMPLEMENTATION_PLAN.md, STATUS.md,
  BACKLOG.md) and asks the assistant to locate and read them by whatever
  means its surface provides. The doc list (requirement) is preserved;
  the retrieval mechanism (solution) is removed.

**Why β over α / γ for F-A.1.** α (procedural enforcement) fights correct
assistant inference and inflates the kickoff body to suppress correct
behavior. γ (hybrid) is operationally similar to β but expresses the rule
in surface-class terms that may evolve. β codifies the underlying
semantic: the gate fires when the developer's choice carries information
(Web), not when the surface is unambiguous from the assistant's POV (CLI).
Multi-LLM evidence (Claude × 2, Codex / GPT, Gemini, Desktop Commander)
predicts convergence on the same inference, supporting β as the accurate
generalization.

**Why (b) over (a) / (c) for F-A.2.** (a) inflates kickoff body with
surface-conditional prose, baking enumeration that may evolve. (c) forces
duplication or manual-branch reads Procedure 7 unnecessarily. (b)
decouples the requirement (which docs) from the solution (how to retrieve)
— same principle as F-G's worked examples, applied to kickoff prose
itself.

**Convention exception (BD-049) preserved** — no labeled sections
introduced; all edits reword existing prose within existing structure.

**Cascade.** 2 files (`pm-chat.md` Variant: kickoff body + METHODOLOGY §
Procedure 7.0 / 7.2.3 / 7.2.4 / 7.6). ~+6 net lines pack-wide. F-A
piggybacks the F-D path update (continuation pointer
`supporting-docs/METHODOLOGY.md` → `docs/pack/METHODOLOGY.md`) as a free
fix on a file F-A is editing anyway.

**Trinity-rule:** clean. F-A modifies neither CLAUDE.md / AGENTS.md /
GEMINI.md.

**Coexistence:** F-D path-update piggybacked; F-E + F-F orthogonal
(Procedure 5-S triggers out-of-band of kickoff body); F-G reinforced
(F-A.2 wording is an instance of F-G's pattern); F-C resolved jointly
with F-D.

**Cross-surface generality:** β + Form I/M preview formalization applies
identically across the four shell-capable surfaces; v10.1 per-surface
detail work (Codex sandbox, Gemini plan-mode, Desktop Commander
allowlist) is not blocked.

**Open questions:** 6, listed in §8; none block project-lead approval.
