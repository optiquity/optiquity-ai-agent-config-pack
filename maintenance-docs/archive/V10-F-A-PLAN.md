# V10-F-A-PLAN — Kickoff surface-declaration gate auto-inferable + kickoff prose hardcoded environmental assumptions (planner pass)

**Author:** pack-planner (v10.0 patch — F-A resolution; final patch in Option A sequence)
**Date:** 2026-04-29
**Implements:** `maintenance-docs/V10-F-A-DESIGN.md` (architect pass, 2026-04-29; project-lead approved with 9 specific decisions — see §0).
**Status:** Draft — planner output. Read-only on every pack source. No edits, no commits. Implementer (parent Pack Chat) executes after project-lead approval of this plan.
**Scope:** v10.0 patch resolving F-A (kickoff surface-declaration gate auto-inferred by assistant, and kickoff variant prose carrying hardcoded environmental assumptions). Companion to F-D + F-C (commits `1de2d23` / `603234e` / `55d1834`), F-E + F-F (3-commit cohort), and F-G (3-commit cohort) already landed. **F-A is the last v10.0 patch in the Option A sequence.**

---

## 0. How to read this plan

`V10-F-A-DESIGN.md` is the authoritative design input. The decision (β semantic acceptance for F-A.1; (b) always-discover for F-A.2; Form I/M preview formalization placed at § 7.6 with cross-references; piggyback path-update on continuation pointer) is baked-in here and not re-litigated.

**Project-lead decisions (already approved; treat as constraints):**

- **D1 (F-A.1).** Direction **β** approved: semantic acceptance of assistant inference on shell-capable surfaces; one-message no-action exit ramp before Form R; Form I / Form M preview formalization.
- **D2 (F-A.2).** Direction **(b)** approved: always-discover; doc list preserved as project-context contract; HOW-to-retrieve becomes surface-agnostic discovery instruction.
- **D3 (OQ-F-A-1).** Specify exit-ramp shape but NOT literal words; reuse existing § 7.5 reply grammar.
- **D4 (OQ-F-A-2).** Leave the kickoff "Before pasting" preamble (`pm-chat.md` lines 25–28) alone (no F-A.2 edit there).
- **D5 (OQ-F-A-3).** Place the generic preview-rendering rule at § 7.6 once + add brief cross-references from § 7.2.3 / § 7.2.4 / § 7.3.1 / § 7.3.2 (NOT four parallel rule edits).
- **D6 (OQ-F-A-4).** No example anchor in the F-A.2 discovery wording.
- **D7 (OQ-F-A-5).** Add one-line sanctioned-inference note in § 7.0 (preempts re-filing as defect).
- **D8 (OQ-F-A-6).** No edit to the kickoff body's `PM-CHAT.md` placeholder-fill block (lines 70–73).
- **D9 (Piggyback).** Update `pm-chat.md` lines 84–91 continuation pointer from `supporting-docs/METHODOLOGY.md` to `docs/pack/METHODOLOGY.md` as part of the F-A patch (F-D path-stale fix on a file F-A is editing anyway).

The implementer can execute this plan literally without further architectural calls.

---

## 1. Goal and BD items addressed

**Goal:** Resolve F-A by (a) updating METHODOLOGY § Procedure 7.0 to define the surface-declaration gate semantically (assistant declares surface and pauses one message before Form R) — sanctioning inference on shell-capable surfaces while preserving the developer's `manual` override; (b) formalizing the Form I / Form M idempotency-preview rendering at § 7.6 once with cross-references from § 7.2.3 / § 7.2.4 / § 7.3.1 / § 7.3.2; (c) replacing the kickoff variant's surface-declaration block (`pm-chat.md` lines 42–50) with shorter β wording; (d) replacing the kickoff variant's GitHub-connector + search-project-knowledge prose (lines 52–58) with a surface-agnostic discovery instruction; (e) piggybacking the F-D continuation-pointer path update (line 84) on the same patch; and (f) **per FB-2 RESOLVED with project-lead Option 2** — extending the F-D path-staleness piggyback to a SECOND site at `pm-chat.md` line 276 (inside `Variant: generate-agent-kickoff`), updating the F-G-introduced cross-reference `supporting-docs/METHODOLOGY.md § Format-vs-solutions: worked examples` to `docs/pack/METHODOLOGY.md § Format-vs-solutions: worked examples` (single-token replacement; same fix as line 84, different line).

**BD items in scope:**
- F-A → one BD-NNN (assigned at C-V10-18 BACKLOG sweep).
- This plan does NOT file the BD entry; it produces the edits the BD entry's "Resolution" line will reference.

---

## 2. Commit shape decision

**Decision: 3 commits**, matching the F-D / F-E+F-F / F-G pattern.

| Commit | Type | Files | Purpose |
|---|---|---|---|
| **C1** | `docs:` | `maintenance-docs/V10-F-A-DESIGN.md`, `maintenance-docs/V10-F-A-PLAN.md` | Land the design + plan documents. |
| **C2** | `feat:` | `supporting-docs/METHODOLOGY.md`, `project-template/docs/pack/prompts/pm-chat.md` | Atomic 2-file, **10-edit** behavioral patch — METHODOLOGY § 7.0 semantic-gate update + § 7.6 preview-rendering rule + 4 cross-reference notes (§ 7.2.3 / § 7.2.4 / § 7.3.1 / § 7.3.2) + pm-chat.md kickoff-variant 3 edits (surface block + doc-discovery + path-update at line 84) + pm-chat.md `generate-agent-kickoff` variant 1 edit (path-update at line 276 — FB-2 Option 2 second piggyback). |
| **C3** | `docs:` | `maintenance-docs/V10-PHASE-4-VERIFICATION.md` (append §13) | Delta-verification evidence section. |

**Rationale (why atomic for C2; why the docs-vs-impl-vs-evidence split):**

1. **Atomic for C2 because the METHODOLOGY edits and the pm-chat.md edits are tightly coupled.** The new § 7.0 semantic-gate wording is the procedural spec the kickoff body's shorter "declare and pause" wording (E3) implements; landing METHODOLOGY without the kickoff body change leaves the developer-facing entry point still asking the assistant to wait for an explicit `shell` reply (which it is documented not to require). Conversely, landing the kickoff body change without the METHODOLOGY update leaves the procedural spec asserting the literal-word gate that the kickoff body no longer requests. The § 7.6 preview formalization + 4 cross-references must land in the same commit as the § 7.0 update because the new § 7.0 narrative references the preview rendering (assistant typically renders Form I / Form M as Form R inline notes when idempotency fires) — splitting them creates a misleading intermediate state. Atomic eliminates all intermediate states.
2. **C1 separated from C2** so the design + plan documents are reviewable as reference artifacts before the implementation lands, matching F-D / F-E+F-F / F-G precedent.
3. **C3 separated from C2** so the behavioral patch is reviewable independently of the evidence capture, and so evidence regeneration does not require re-touching the behavioral diff.
4. **`validate-pack.py` does not assert any of the new content.** Check 6 (Prompts-directory format) verifies frontmatter and variant→H2 consistency in `project-template/docs/pack/prompts/*.md` — it does NOT inspect variant body content. Check 10 (Prompt template triad compliance) explicitly excludes the kickoff variant via the `**Convention exception:**` callout (per F-G plan §10.3 / `validate-pack.py` Check 10 implementation). The kickoff variant body is therefore not gated by either content check; the surface-declaration block / doc-discovery block / continuation pointer rewrites do not affect any validate-pack.py check. No METHODOLOGY-content checks exist. Splitting C2 therefore offers no validate-pack.py-driven gating value.
5. **Trinity rule is not engaged in C2.** Neither `pm-chat.md` nor `METHODOLOGY.md` is a trinity file. The kickoff body does not introduce labeled sections (BD-049 Convention exception preserved per design §2.5). No trinity-symmetry gate to satisfy in C2.
6. **Touch surface for C2 is small (2 files; ~+14 net lines METHODOLOGY, ~−8 net lines pm-chat.md = ~+6 net pack-wide; 10 edits total: 6 in METHODOLOGY, 4 in pm-chat.md including the FB-2 Option 2 second-piggyback E10).** Single coherent commit is easier to review than the alternative split.

**Rejected alternative — split C2 into "METHODOLOGY first; pm-chat.md second":** doubles approval overhead; introduces a misleading intermediate state where one file claims the gate is semantic while the other still demands the literal-word reply. Produces no checkpoint that validate-pack.py would gate on.

**Rejected alternative — combine C1+C2+C3 into one commit:** mixes design docs with behavioral changes; mixes verification evidence (captured AFTER implementation runs) with the implementation itself; breaks the established F-D / F-E+F-F / F-G pattern.

---

## 3. Affected files (complete list)

### 3.1 Files edited in C2 (2)

| # | File | Edit area | Purpose |
|---|---|---|---|
| 1 | `supporting-docs/METHODOLOGY.md` | Six distinct edits in § Procedure 7: (a) § 7.0 lines 1354–1365 — replace the trigger-and-scope paragraph (preserving lines 1361–1365 verbatim) with semantic-gate wording + sanctioned-inference one-liner; (b) § 7.2.3 line 1473–1476 — append a brief cross-reference to the new § 7.6 preview rule; (c) § 7.2.4 lines 1496–1502 — append a brief cross-reference to the new § 7.6 preview rule; (d) § 7.3.1 line 1518–1520 — append a brief cross-reference to the new § 7.6 preview rule; (e) § 7.3.2 lines 1521–1531 — append a brief cross-reference to the new § 7.6 preview rule; (f) § 7.6 lines 1591–1606 — append the new "preview rendering" rule body inside the existing idempotency rules subsection. | Make the gate semantic per β; sanction inference; formalize Form I/M preview rendering as a recognized shape rather than a deviation. |
| 2 | `project-template/docs/pack/prompts/pm-chat.md` | **Four** distinct edits — three in `## Variant: kickoff` plus one in `## Variant: generate-agent-kickoff`: (a) Variant: kickoff lines 42–50 — replace the surface-declaration block with shorter β wording (declare + pause); (b) Variant: kickoff lines 52–58 — replace the GitHub-connector + search-project-knowledge prose with a surface-agnostic discovery instruction; (c) Variant: kickoff lines 84 and 89 — update path tokens `supporting-docs/METHODOLOGY.md` → `docs/pack/METHODOLOGY.md` (line 84) and leave `supporting-docs/SETUP-NEW.md` unchanged on line 89 (per design §4.1 — SETUP-NEW.md is not copied into the project tree under v10); (d) **Variant: generate-agent-kickoff line 276 — update path token `supporting-docs/METHODOLOGY.md` → `docs/pack/METHODOLOGY.md` inside the F-G-introduced `§ Format-vs-solutions: worked examples` cross-reference (FB-2 Option 2 second piggyback; descriptive text after `§ Format-vs-solutions:` preserved verbatim).** | Implement β semantic-gate behavior in developer-pasted entry point; make discovery surface-agnostic; piggyback F-D path-stale fix on BOTH stale-path sites in the file F-A is editing anyway. |

### 3.2 Files edited in C1 (2)

- `maintenance-docs/V10-F-A-DESIGN.md` — already on disk (architect output); add to git in C1.
- `maintenance-docs/V10-F-A-PLAN.md` — this file; add to git in C1.

### 3.3 Files edited in C3 (1)

- `maintenance-docs/V10-PHASE-4-VERIFICATION.md` — append new `## §13 Delta verification — F-A patch` section after the existing `## §12` section (last existing line: 1196). Template per §5.11 of this plan (C3 evidence section template; was §5.10 prior to E10 insertion — renumbered post-FB-2 Option 2).

### 3.4 Files NOT edited (verified)

- **`project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md`.** Trinity files do not carry kickoff prompt content or Procedure 7 procedural spec. METHODOLOGY (now at `docs/pack/`) is referenced by the trinity generically; no path or wording change in trinity is required. **Trinity-rule status: clean.**
- **`supporting-docs/SETUP-NEW.md`.** The manual-branch pointer in `pm-chat.md` line 89 fires correctly per §4.3 evidence. Manual fallback content carries no environmental assumptions that need the F-A.2 fix — developers run listed shell commands locally and report values back. **No edit.**
- **`project-template/docs/pack/prompts/pm-chat.md` other variants** (backlog-status-update, generate-setup). Neither carries surface-declaration prose or GitHub-connector assertions; both are PM-chat self-prompts run after surface is established. **No edit.** (Variant: generate-agent-kickoff is touched at line 276 only — single-token path-update per E10; see §3.1 row d and §5.10. FB-2 RESOLVED with Option 2; see §9.3.)
- **`project-template/docs/pack/PM-CHAT.md`** (PM-chat startup/operating instructions, distinct from `pm-chat.md` prompt templates). Carries no kickoff body content. **No edit.**
- **Kickoff "Before pasting" preamble (`pm-chat.md` lines 25–28).** Per D4 — operational warnings to developer; no environmental assertion to fix. **No edit.**
- **Kickoff `PM-CHAT.md` placeholder-fill block (`pm-chat.md` lines 70–73).** Per D8 — independent post-surface-declaration follow-on; no F-A interaction. **No edit.**
- **`scripts/init-project.sh` / `scripts/migrate-v9-to-v10.sh`.** No scripted detection of surface-declaration semantics; scripts do not parse kickoff body. **No edit.**
- **`scripts/validate-pack.py` / `scripts/test-detect.sh`.** No new validation checks introduced. **No edit.**
- **Pack-repo `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` / `PACK-AGENTS.md`.** Govern pack-repo agent behavior, not project PM-chat behavior. **Out of scope.**
- **`maintenance-docs/V10-DESIGN.md` / `V10-IMPLEMENTATION-PLAN.md`.** Design docs; not pack source. F-A is a Phase 4 patch; design docs are not retroactively edited (precedent: F-D / F-E+F-F / F-G). **No edit.**

### 3.5 Cross-reference audit (verified)

- `supporting-docs/METHODOLOGY.md` references in `pm-chat.md` Variant: kickoff: 1 hit pre-C2 at line 84; 0 hits post-C2 (replaced with `docs/pack/METHODOLOGY.md` via E9).
- `supporting-docs/METHODOLOGY.md` references in `pm-chat.md` Variant: generate-agent-kickoff: 1 hit pre-C2 at line 276 (F-G-introduced, inside the `§ Format-vs-solutions: worked examples` cross-reference); 0 hits post-C2 (replaced with `docs/pack/METHODOLOGY.md` via E10 — FB-2 Option 2 second piggyback).
- `supporting-docs/METHODOLOGY.md` pack-wide references in `pm-chat.md`: 2 hits pre-C2 (line 84 + line 276); 0 hits post-C2 (both fixed by E9 + E10).
- `supporting-docs/SETUP-NEW.md` references in `pm-chat.md` Variant: kickoff: 1 hit pre-C2 at line 89; 1 hit post-C2 (unchanged — SETUP-NEW.md is not copied into project tree under v10 per design §4.1).
- "GitHub connector is connected" assertion in `pm-chat.md`: 1 hit pre-C2 at line 52; 0 hits post-C2.
- "search project knowledge" instruction in `pm-chat.md`: 1 hit pre-C2 at line 53; 0 hits post-C2.
- "Reply with the single word `shell` or `manual` before continuing" assertion in `pm-chat.md`: 1 hit pre-C2 at line 50; 0 hits post-C2 (replaced by β wording).
- `### 7.6 Idempotency rules` heading in METHODOLOGY: 1 hit pre/post-C2 (unchanged); body extended with new preview-rendering rule paragraph.
- New cross-references "see § 7.6 preview rendering" / equivalent in METHODOLOGY: 0 hits pre-C2; 4 hits post-C2 (one each in § 7.2.3, § 7.2.4, § 7.3.1, § 7.3.2).
- Sanctioned-inference one-liner in METHODOLOGY § 7.0: 0 hits pre-C2; 1 hit post-C2.

---

## 4. Edit order within C2

The implementer applies edits in this order within the atomic C2 commit (**10 edits total** — was 9; E10 added per FB-2 Option 2). Order is chosen so (a) METHODOLOGY edits land before pm-chat.md edits — so an interrupted session leaves the procedural spec consistent first; (b) within METHODOLOGY, the new § 7.6 preview-rendering rule lands BEFORE the four cross-references that point at it — so no intermediate state has cross-references pointing at content that does not yet exist; (c) within pm-chat.md, the substantive prose rewrites (E7, E8) land before the path-update piggybacks (E9, E10), and the two single-line path-update piggybacks land LAST — preserving the smallest-change-last pattern. E9 and E10 are both single-token path replacements; their order vs each other does not matter (they touch different lines, different variants); E10 lands after E9 to keep the final two edits adjacent and smallest-last.

| Step | File | Why this order |
|---|---|---|
| E1 | `supporting-docs/METHODOLOGY.md` § 7.0 (lines 1354–1365 area) — replace trigger-and-scope paragraph with semantic-gate wording + sanctioned-inference one-liner; preserve lines 1361–1365 verbatim. | Lands first — the foundational procedural-spec change. All other METHODOLOGY edits depend on this framing. Largest single insertion (~6 net new lines). |
| E2 | `supporting-docs/METHODOLOGY.md` § 7.6 (after line 1606 within "Idempotency rules") — append new "preview rendering" rule body. | Lands second so when E3–E6 add cross-references "see § 7.6 preview rendering" they point at content that already exists. ~+6 net lines. |
| E3 | `supporting-docs/METHODOLOGY.md` § 7.2.3 (after line 1476, the existing idempotency note) — append brief cross-reference to § 7.6 preview rule. | Lands after E2. ~+1 net line. |
| E4 | `supporting-docs/METHODOLOGY.md` § 7.2.4 (after line 1502, the existing idempotency note) — append brief cross-reference to § 7.6 preview rule. | Lands after E2. ~+1 net line. |
| E5 | `supporting-docs/METHODOLOGY.md` § 7.3.1 (after line 1520, the existing per-tool idempotency note) — append brief cross-reference to § 7.6 preview rule. | Lands after E2. ~+1 net line. |
| E6 | `supporting-docs/METHODOLOGY.md` § 7.3.2 (after line 1531, the existing per-tool block) — append brief cross-reference to § 7.6 preview rule. | Lands after E2. ~+1 net line. |
| E7 | `project-template/docs/pack/prompts/pm-chat.md` Variant: kickoff lines 42–50 — replace surface-declaration block with β wording. | Lands after METHODOLOGY edits so the kickoff body's β phrasing is honest about what § 7.0 documents. ~−4 net lines. |
| E8 | `project-template/docs/pack/prompts/pm-chat.md` Variant: kickoff lines 52–58 — replace GitHub-connector + search-project-knowledge prose with surface-agnostic discovery instruction. | Lands after E7 (same file; sequential edits in the kickoff body). ~−4 net lines. |
| E9 | `project-template/docs/pack/prompts/pm-chat.md` Variant: kickoff line 84 — update path token `supporting-docs/METHODOLOGY.md` → `docs/pack/METHODOLOGY.md`. | First of two single-line piggyback path-updates (D9); lands after substantive prose rewrites (E7, E8). |
| E10 | `project-template/docs/pack/prompts/pm-chat.md` Variant: generate-agent-kickoff line 276 — update path token `supporting-docs/METHODOLOGY.md` → `docs/pack/METHODOLOGY.md` inside the F-G-introduced `§ Format-vs-solutions: worked examples` cross-reference. | Lands last — second of two single-line piggyback path-updates (FB-2 Option 2). Smallest, lowest-risk edit (single-token replacement on one line; descriptive text after `§ Format-vs-solutions:` preserved verbatim). |

**Edit-order justification (E1–E10):** METHODOLOGY first (E1–E6), pm-chat.md second (E7–E10). Within METHODOLOGY, the canonical rule body (E2 at § 7.6) lands before the cross-references (E3–E6) so no intermediate state has dangling pointers. Within pm-chat.md, the substantive prose rewrites (E7, E8) land before the path-update piggybacks (E9, E10) so the largest changes are reviewed first; E10 lands after E9 because both are single-token path replacements and ordering them adjacent at the tail preserves the smallest-change-last pattern. The alternative E1 → E3–E6 → E2 was rejected because between E3-landing and E2-landing there would be a transient self-inconsistency (cross-references to a § 7.6 rule that does not yet exist). E9-vs-E10 ordering is interchangeable (different lines, different variants, no shared dependency); the chosen E9-then-E10 ordering is by convention only.

`validate-pack.py` is not run incrementally between these edits — Check 6 / Check 10 do not gate on any of the new content (kickoff variant excluded from Check 10 via `**Convention exception:**`; the generate-agent-kickoff variant E10 path-token edit does not touch any triad marker — see §10.8). It is run **once** after all ten edits land, before commit (per §6 checklist).

---

## 5. Per-file edit specifications

### 5.1 Edit E1 — `supporting-docs/METHODOLOGY.md` § 7.0 trigger and scope (semantic-gate update + sanctioned-inference one-liner)

**File:** `/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/METHODOLOGY.md`
**Lines (current):** 1354 (`#### 7.0 Trigger and scope`) through 1365 (end of the override paragraph). Lines 1361–1365 (the developer-override paragraph) are PRESERVED VERBATIM per design §1.1 / §2.6.

**Pre-edit excerpt (lines 1354–1365, current):**

```
#### 7.0 Trigger and scope

The PM chat enters Procedure 7 when the kickoff-variant continuation
pointer fires on a `shell` declaration. On `manual`, Procedure 7 is
not entered; the PM chat emits the `SETUP-NEW.md § Manual fallback`
pointer instead and waits for developer-reported values.

The developer may declare `manual` even on a shell-capable surface
(e.g., to read the planned commands before granting execution); the
PM chat honors it. The developer may also switch to `manual`
mid-kickoff; the PM chat treats that as a re-declaration from that
point onward — commands already run cannot be unrun.
```

**Post-edit text (replace lines 1356–1360 only — keep the heading at 1354 and the override paragraph at 1361–1365 verbatim):**

```markdown
#### 7.0 Trigger and scope

The PM chat enters Procedure 7 once the assistant has (a) declared
its surface and (b) given the developer a one-message exit ramp
before any non-read-only action. On a shell-capable surface (Claude
Code CLI, Codex CLI, Gemini CLI, Claude Desktop with Desktop
Commander), the assistant typically declares `shell` by inference
from its environment — this is sanctioned and not a deviation; it
MUST NOT begin Form R discovery in the same message as the surface
declaration. On Web / Desktop surfaces without shell access (Claude
Web, ChatGPT Web), the assistant declares `manual`; Procedure 7 is
not entered; the PM chat emits the `SETUP-NEW.md § Manual fallback`
pointer and waits for developer-reported values. The exit-ramp
reply is interpreted per the § 7.5 reply grammar (`yes` / `no` /
`skip` / `abort` / `edit` / bare value); a positive reply
authorizes Form R, anything else defers per the grammar's
"unrecognized → no" rule.

The developer may declare `manual` even on a shell-capable surface
(e.g., to read the planned commands before granting execution); the
PM chat honors it. The developer may also switch to `manual`
mid-kickoff; the PM chat treats that as a re-declaration from that
point onward — commands already run cannot be unrun.
```

**Diff shape:** ~+10 net lines (the original 5-line trigger paragraph is replaced with a 15-line semantic-gate paragraph). Lines 1361–1365 (developer-override paragraph) untouched.

**Verification check for this edit:**

```bash
# Confirm the new semantic-gate wording is present.
grep -n 'declared.*surface.*one-message exit ramp' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/METHODOLOGY.md
# Expect: 1 hit in § 7.0.

# Confirm the sanctioned-inference one-liner (D7).
grep -n 'sanctioned and not a deviation' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/METHODOLOGY.md
# Expect: 1 hit in § 7.0.

# Confirm the developer-override paragraph (lines 1361–1365 originally) is preserved verbatim.
grep -n 'switch to .manual. mid-kickoff' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/METHODOLOGY.md
# Expect: 1 hit (paragraph reused unchanged; line number shifted).

# Confirm the literal-word "Reply with the single word `shell`" assertion is GONE from § 7.0.
grep -n 'Reply with the single word' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/METHODOLOGY.md
# Expect: 0 hits (it was never in METHODOLOGY; this verifies it is not introduced).

# Confirm the § 7.5 reply-grammar cross-reference is present in § 7.0.
grep -n '§ 7.5 reply grammar' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/METHODOLOGY.md
# Expect: at least 1 hit (the new § 7.0 reference).
```

### 5.2 Edit E2 — `supporting-docs/METHODOLOGY.md` § 7.6 preview-rendering rule (single source per D5)

**File:** `/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/METHODOLOGY.md`
**Lines (current):** § 7.6 starts at line 1591 (`#### 7.6 Idempotency rules`); the bulleted Form R / Form I / Form E / Form M list runs lines 1598–1606; the "concurrent / interrupted kickoff" cross-reference paragraph starts at line 1608.

**NOTE on line drift after E1:** edit E1 inserts ~+10 lines into § 7.0 area, shifting all subsequent METHODOLOGY lines down by ~10. After E1 lands, the § 7.6 anchor is at approximately line 1601; the bulleted list ends around line 1616; the "concurrent / interrupted" paragraph starts around line 1618. The implementer applies E2 by anchoring on **content** (the closing line of the Form M bullet `under cmp -s.` followed by the blank line before the "concurrent / interrupted kickoff" paragraph), not on the absolute line number.

**Insertion point:** after the existing Form M bullet (`- **Form M** — skip when every source/target pair is byte-identical under cmp -s.`) and the blank line that follows, insert the new paragraph; then a blank line; then the existing "concurrent / interrupted kickoff" paragraph remains unchanged.

**Insert text (paste verbatim; insert after the Form M bullet's blank-line terminator, before the "For concurrent / interrupted kickoff handling" paragraph):**

```markdown
**Preview rendering.** When a Form's idempotency rule fires (Form I:
`command -v <tool>` returns a path AND `<tool> --version` is within
the pack-tested range; Form M: every source/target pair is
byte-identical under `cmp -s`), the gate renders as a single-line
`note:` diagnostic inside the Form R results table rather than as a
separately-rendered Form. The preview is the gate — there is no
proposed action for the developer to approve, skip, or abort. This
applies wherever Form I or Form M is invoked (§ 7.2.3 swift-format,
§ 7.2.4 Xcode companion files, § 7.3.1 Apple-side gRPC tooling,
§ 7.3.2 Python-side gRPC tooling). The full Form renders only when
the idempotency rule does NOT fire — i.e., when there is something
to gate. Reply grammar (§ 7.5) does not apply to preview lines; they
are informational notes inside Form R, whose own reply grammar
covers the read-only discovery decision.
```

**Diff shape:** ~+12 net lines added inside § 7.6 (one new paragraph + surrounding blank lines).

**Verification check for this edit:**

```bash
# Confirm the new preview-rendering rule is present in § 7.6.
grep -n '^\*\*Preview rendering\.\*\*' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/METHODOLOGY.md
# Expect: 1 hit.

# Confirm the rule names all four invocation sites.
grep -E '§ 7\.2\.3.*§ 7\.2\.4.*§ 7\.3\.1.*§ 7\.3\.2' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/METHODOLOGY.md
# Expect: at least 1 hit (the preview-rendering paragraph).

# Confirm § 7.6 is the placement (not § 7.2 / § 7.3 area).
awk '/^#### 7\.6/,/^#### 7\.7/' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/METHODOLOGY.md | grep -c 'Preview rendering'
# Expect: 1.

# Confirm the existing "concurrent / interrupted kickoff" paragraph is still present and downstream of the new paragraph.
grep -n 'For concurrent / interrupted kickoff handling' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/METHODOLOGY.md
# Expect: 1 hit; line position downstream of the Preview rendering paragraph.
```

### 5.3 Edit E3 — `supporting-docs/METHODOLOGY.md` § 7.2.3 cross-reference

**File:** `/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/METHODOLOGY.md`
**Lines (current):** § 7.2.3 idempotency note ends at line 1476 (`...within the known-good range) — skipping\nand do not render Form I.`).

**NOTE on line drift after E1+E2:** the absolute line is now around 1486 + the additional E2 insert. Anchor on content (`and do not render Form I.` as the last line of § 7.2.3's idempotency paragraph; the next H4 `##### 7.2.4 Xcode companion files` starts after a blank line).

**Insertion point:** after `and do not render Form I.` and the blank line that follows, before the next `#####` heading.

**Insert text (paste verbatim):**

```markdown
The single-line `note:` is rendered inside the Form R results table
per § 7.6 (Preview rendering) — it is not a separate Form rendering.
```

**Diff shape:** ~+3 net lines (one paragraph + surrounding blank lines).

**Verification check for this edit:**

```bash
# Confirm the cross-reference is present in § 7.2.3.
awk '/^##### 7\.2\.3/,/^##### 7\.2\.4/' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/METHODOLOGY.md | grep -c '§ 7\.6 (Preview rendering)'
# Expect: 1.
```

### 5.4 Edit E4 — `supporting-docs/METHODOLOGY.md` § 7.2.4 cross-reference

**File:** `/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/METHODOLOGY.md`
**Lines (current):** § 7.2.4 idempotency note ends at line 1502 (`— default remains skip.`).

**NOTE on line drift after E1+E2+E3:** anchor on content. The § 7.2.4 idempotency paragraph ends with `— default remains skip.`; the next `#### 7.3` H4 starts after a blank line.

**Insertion point:** after `— default remains skip.` and the blank line that follows, before the `#### 7.3 K3 — gRPC sub-flow` heading.

**Insert text (paste verbatim):**

```markdown
The single-line `note:` is rendered inside the Form R results table
per § 7.6 (Preview rendering) — it is not a separate Form rendering.
```

**Diff shape:** ~+3 net lines.

**Verification check for this edit:**

```bash
awk '/^##### 7\.2\.4/,/^#### 7\.3/' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/METHODOLOGY.md | grep -c '§ 7\.6 (Preview rendering)'
# Expect: 1.
```

### 5.5 Edit E5 — `supporting-docs/METHODOLOGY.md` § 7.3.1 cross-reference

**File:** `/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/METHODOLOGY.md`
**Lines (current):** § 7.3.1 ends with the existing reference back to § 7.2.3's idempotency rule (line 1519–1520: `Each Form I applies the idempotency rule from §7.2.3 — already-installed\nand in-range tools are skipped with a note.`).

**NOTE on line drift after E1+E2+E3+E4:** anchor on content. The closing line is `already-installed and in-range tools are skipped with a note.`; the next H5 `##### 7.3.2 Python-side gRPC tooling` starts after a blank line.

**Insertion point:** after `already-installed and in-range tools are skipped with a note.` and the blank line that follows, before the `##### 7.3.2` heading.

**Insert text (paste verbatim):**

```markdown
The note is rendered inside Form R per § 7.6 (Preview rendering).
```

**Diff shape:** ~+2 net lines (one short line + surrounding blank).

**Verification check for this edit:**

```bash
awk '/^##### 7\.3\.1/,/^##### 7\.3\.2/' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/METHODOLOGY.md | grep -c '§ 7\.6 (Preview rendering)'
# Expect: 1.
```

### 5.6 Edit E6 — `supporting-docs/METHODOLOGY.md` § 7.3.2 cross-reference

**File:** `/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/METHODOLOGY.md`
**Lines (current):** § 7.3.2 ends with the optional-reflection bullet (line 1530–1531: `- uv add grpcio-reflection — Pack-tested: grpcio-reflection ≥1.64.0\n  (optional, only if reflection is used).`).

**NOTE on line drift after E1+E2+E3+E4+E5:** anchor on content. The last bullet ends `(optional, only if reflection is used).`; the next H5 `##### 7.3.3 Proto code generation example` starts after a blank line.

**Insertion point:** after `(optional, only if reflection is used).` and the blank line that follows, before the `##### 7.3.3` heading.

**Insert text (paste verbatim):**

```markdown
Each Form I in this section applies the § 7.2.3 idempotency rule;
the resulting note is rendered inside Form R per § 7.6
(Preview rendering).
```

**Diff shape:** ~+4 net lines (three lines + surrounding blank).

**Verification check for this edit:**

```bash
awk '/^##### 7\.3\.2/,/^##### 7\.3\.3/' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/METHODOLOGY.md | grep -c '§ 7\.6 (Preview rendering)'
# Expect: 1.

# Cross-confirm: total cross-reference hits across § 7.2.3 / § 7.2.4 / § 7.3.1 / § 7.3.2 = 4.
grep -c '§ 7\.6 (Preview rendering)' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/supporting-docs/METHODOLOGY.md
# Expect: 4 (E3, E4, E5, E6).
```

### 5.7 Edit E7 — `project-template/docs/pack/prompts/pm-chat.md` Variant: kickoff surface-declaration block (lines 42–50)

**File:** `/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md`
**Lines (current):** 42–50 (the existing `**Before I do anything else:**` block).

**Pre-edit excerpt (lines 42–50, current):**

```
**Before I do anything else:** I am about to run read-only discovery
commands and propose installs and file edits for your approval.
Confirm one of:

- `shell` — I have shell access on this surface (Claude Code CLI, Codex
  CLI, Gemini CLI, or Claude Desktop with Desktop Commander enabled).
- `manual` — I have no shell on this surface (Claude Web, ChatGPT Web).

Reply with the single word `shell` or `manual` before continuing.
```

**Post-edit text (replace lines 42–50 verbatim with the following):**

```markdown
**Before I do anything else:** I will declare my surface and pause
for your reply before running any non-read-only action. The recognized
surfaces are Claude Code CLI, Codex CLI, Gemini CLI, or Claude Desktop
with Desktop Commander (shell-capable — I typically declare `shell`
by inference); and Claude Web or ChatGPT Web (no shell — I declare
`manual` and route to the manual fallback). Reply `yes` to authorize
Form R discovery, `manual` to override mid-kickoff, or per the
METHODOLOGY § 7.5 reply grammar (`no` / `skip` / `abort` / `edit`).
```

**Diff shape:** ~−1 net line (replaced 9 lines with 8 lines). β semantic-gate phrasing per design §1.1 + D3 (exit-ramp shape specified, literal words not over-constrained — reuses § 7.5 grammar).

**Verification check for this edit:**

```bash
# Confirm the new β phrasing landed.
grep -n 'declare my surface and pause' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md
# Expect: 1 hit in Variant: kickoff.

# Confirm the literal-word gate is gone.
grep -n 'Reply with the single word' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md
# Expect: 0 hits.

# Confirm § 7.5 reply-grammar cross-reference is present in the new block.
grep -n 'METHODOLOGY § 7\.5 reply grammar' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md
# Expect: 1 hit (the new kickoff body wording).

# Confirm the four shell-capable surface enumeration is preserved (per design §9; NOT changing the list).
grep -nE 'Claude Code CLI.*Codex CLI.*Gemini CLI' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md
# Expect: at least 1 hit; line shifted slightly.

# Confirm Convention exception (BD-049) line at line 23 is unchanged.
grep -n 'Convention exception:.*kickoff is a context handoff' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md
# Expect: 1 hit; unchanged.

# Confirm no labeled sections introduced (no Problem/Goal/Success criteria H3-or-bold lines added inside Variant: kickoff).
awk '/^## Variant: kickoff/,/^## Variant: backlog-status-update/' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md | grep -cE '^\*\*(Problem|Goal|Success criteria|Constraints|Files in scope|Completion report):\*\*'
# Expect: 0 (Convention exception preserved).
```

### 5.8 Edit E8 — `project-template/docs/pack/prompts/pm-chat.md` Variant: kickoff doc-discovery block (lines 52–58)

**File:** `/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md`
**Lines (current):** 52–58 (the GitHub-connector + search-project-knowledge block).

**NOTE on line drift after E7:** E7 reduced the block above by 1 line. After E7, the doc-discovery block sits at approximately lines 51–57. The implementer applies E8 by anchoring on **content** (`**Project documents are in the GitHub repo.**` opening line; the four-doc bulleted list; the closing bullet `- BACKLOG.md`).

**Pre-edit excerpt (lines 52–58, current):**

```
**Project documents are in the GitHub repo.** The GitHub connector is connected.
Please search project knowledge to read:
- ARCHITECTURE.md
- IMPLEMENTATION_PLAN.md (current phase)
- STATUS.md
- BACKLOG.md
```

**Post-edit text (replace those 7 lines with the following 6 lines):**

```markdown
**Project documents the PM chat needs in context:** ARCHITECTURE.md,
IMPLEMENTATION_PLAN.md (current phase), STATUS.md, BACKLOG.md.
Locate and read these by whatever means your surface provides —
local repo read on shell-capable surfaces; project-knowledge or
GitHub-connector search on Web with a Project + connector;
equivalent retrieval on other surfaces. If you cannot access them,
report what you can reach and I will adapt.
```

**Diff shape:** ~−1 net line (replaced 7 lines with 6). Per design §3.4 / D2 / D6 (no example anchor). The four doc names are PRESERVED as the project-context contract; the HOW-to-retrieve assertion is REMOVED.

**Verification check for this edit:**

```bash
# Confirm GitHub-connector assertion is gone.
grep -n 'GitHub connector is connected' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md
# Expect: 0 hits.

# Confirm "search project knowledge" instruction is gone.
grep -n 'search project knowledge' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md
# Expect: 0 hits.

# Confirm the four doc names are preserved (project-context contract).
grep -nE 'ARCHITECTURE\.md.*IMPLEMENTATION_PLAN\.md' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md
# Expect: at least 1 hit (the new combined-line wording).
grep -c 'STATUS\.md' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md
# Expect: at least 1.
grep -c 'BACKLOG\.md' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md
# Expect: at least 1.

# Confirm the surface-agnostic discovery wording landed.
grep -n 'Locate and read these by whatever means your surface provides' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md
# Expect: 1 hit.

# Confirm the "report what you can reach" fallback wording landed.
grep -n 'report what you can reach and I will adapt' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md
# Expect: 1 hit.
```

### 5.9 Edit E9 — `project-template/docs/pack/prompts/pm-chat.md` Variant: kickoff continuation pointer path update (line 84)

**This is the FIRST of TWO single-line path-staleness piggyback edits in this patch.** The companion edit (E10) updates a second occurrence of the same stale path at line 276 inside `Variant: generate-agent-kickoff` — see §5.10. Both are F-D residual path-staleness fixes; they could be ordered either way (independent lines, independent variants); the chosen ordering is E9 then E10 by convention (smallest-change-last cluster at the tail of C2).

**File:** `/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md`
**Lines (current):** line 84 (the `On shell:` continuation pointer naming `supporting-docs/METHODOLOGY.md`).

**NOTE on line drift after E7+E8:** E7+E8 net change is approximately −2 lines. After E7+E8, the line-84 reference sits at approximately line 82. The implementer applies E9 by anchoring on **content** (`On shell: I will read supporting-docs/METHODOLOGY.md Procedure 7`).

**Pre-edit excerpt (lines 84–87, current):**

```
On `shell`: I will read `supporting-docs/METHODOLOGY.md` Procedure 7
directly (not via RAG — Procedure 7 is order-sensitive) and follow
its gates G7-discovery / G7-install / G7-edit / G7-machine before
any write or install.
```

**Post-edit text (replace `supporting-docs/METHODOLOGY.md` with `docs/pack/METHODOLOGY.md` on the first line; rest of the paragraph unchanged):**

```markdown
On `shell`: I will read `docs/pack/METHODOLOGY.md` Procedure 7
directly (not via RAG — Procedure 7 is order-sensitive) and follow
its gates G7-discovery / G7-install / G7-edit / G7-machine before
any write or install.
```

**Diff shape:** ±0 net lines (single-token replacement on one line). Per D9 (piggyback F-D path-stale fix on the file F-A is editing anyway).

**NOTE on line 89 (`SETUP-NEW.md § Manual fallback`):** **NOT EDITED.** Per design §4.1 — `SETUP-NEW.md` is at `supporting-docs/` in the pack and is not copied into the project tree under v10. The path on line 89 (`supporting-docs/SETUP-NEW.md`) is correct as-is. Confirmed by checking the pack file layout — `SETUP-NEW.md` lives only under `supporting-docs/` and is not in the F-D move list.

**Verification check for this edit:**

```bash
# Confirm the path update landed in the kickoff continuation pointer.
awk '/^## Variant: kickoff/,/^## Variant: backlog-status-update/' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md | grep -c 'docs/pack/METHODOLOGY\.md'
# Expect: 1 (the new continuation pointer).

# Confirm the stale path is gone from the kickoff variant.
awk '/^## Variant: kickoff/,/^## Variant: backlog-status-update/' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md | grep -c 'supporting-docs/METHODOLOGY\.md'
# Expect: 0 (Variant: kickoff body has zero remaining `supporting-docs/METHODOLOGY.md` references).

# Confirm line 28 path-name reference (no path) is unchanged — it does not include "supporting-docs/" prefix.
awk '/^## Variant: kickoff/,/^## Variant: backlog-status-update/' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md | grep -c 'METHODOLOGY\.md Procedure 7'
# Expect: at least 2 (line 28 unqualified reference + new continuation pointer at ~line 82).

# Confirm SETUP-NEW.md path on line 89 is preserved as `supporting-docs/SETUP-NEW.md`.
awk '/^## Variant: kickoff/,/^## Variant: backlog-status-update/' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md | grep -c 'supporting-docs/SETUP-NEW\.md'
# Expect: 1 (unchanged from pre-C2).

# Pack-wide cross-check at THIS point in the edit sequence (post-E9, pre-E10):
grep -nE 'supporting-docs/METHODOLOGY\.md' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md
# Expect post-E9 (E10 not yet applied): 1 hit remaining at line ~276 (Variant: generate-agent-kickoff F-G-introduced cross-reference).
# Expect post-E10 (final post-C2 state): 0 hits — both line 84 (E9) and line 276 (E10) fixed. See §5.10 for E10.
```

### 5.10 Edit E10 — `project-template/docs/pack/prompts/pm-chat.md` Variant: generate-agent-kickoff path-staleness piggyback (line 276) — FB-2 Option 2 second piggyback

**This is the SECOND of TWO single-line path-staleness piggyback edits in this patch.** The companion edit (E9) updates the first occurrence at line 84 inside `Variant: kickoff` — see §5.9. Both are F-D residual path-staleness fixes (single-token replacement: `supporting-docs/METHODOLOGY.md` → `docs/pack/METHODOLOGY.md`). E10 was added to F-A scope per **FB-2 RESOLVED with project-lead Option 2** — extend F-A to include both path-staleness sites in `pm-chat.md` rather than deferring line 276 to a separate C-V10-18 BACKLOG sweep item.

**File:** `/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md`
**Lines (current, pre-edit; verified by Read at planner-pass amendment time):** line 276 (inside `## Variant: generate-agent-kickoff`, within a pointer item that F-G commit `a7d3542` added; the `supporting-docs/METHODOLOGY.md` token wraps onto its own line within a multi-line bullet that begins on line 273 and continues through line 278).

**NOTE on line drift after E1–E9:** E1–E6 touch METHODOLOGY only (no pm-chat.md drift). E7, E8 reduce pm-chat.md by ~−2 net lines BEFORE line 276. E9 changes only a single token on line 84 (no line-count change). After E1–E9, the line-276 anchor sits at approximately line 274 in the working copy. The implementer applies E10 by anchoring on **content** (the unique multi-line bullet text `per supporting-docs/METHODOLOGY.md § Format-vs-solutions: worked` followed on the next line by `examples`, prescribing a structural answer in an architect prompt`), not on the absolute line number. The `supporting-docs/METHODOLOGY.md` token is unique on this line within the file post-E9 (since E9 already removed the only other occurrence at line 84).

**Pre-edit excerpt (lines 273–278, current — verified by Read against working tree at amendment time):**

```
        listed in the trinity `**Active skills:**` line (concurrency,
        platform architecture, language-specific rules). The PM chat does
        not pre-decide these structural choices in this checklist —
        per `supporting-docs/METHODOLOGY.md § Format-vs-solutions: worked
        examples`, prescribing a structural answer in an architect prompt
        anchors the agent and is forbidden.
```

**Post-edit text (replace `supporting-docs/METHODOLOGY.md` with `docs/pack/METHODOLOGY.md` on line 276; all other text — leading whitespace, the `per ` prefix, the backticks around the path, the ` § Format-vs-solutions: worked` suffix, the line break, the continuation `examples`, and the descriptive prose that follows — preserved VERBATIM):**

```
        listed in the trinity `**Active skills:**` line (concurrency,
        platform architecture, language-specific rules). The PM chat does
        not pre-decide these structural choices in this checklist —
        per `docs/pack/METHODOLOGY.md § Format-vs-solutions: worked
        examples`, prescribing a structural answer in an architect prompt
        anchors the agent and is forbidden.
```

**Diff shape:** ±0 net lines (single-token replacement on one line; same shape as E9). Per FB-2 Option 2 (extend F-A scope to address both stale-path sites in `pm-chat.md`).

**Verification check for this edit:**

```bash
# Confirm the path update landed at line 276 inside Variant: generate-agent-kickoff.
awk '/^## Variant: generate-agent-kickoff/,0' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md | grep -c 'docs/pack/METHODOLOGY\.md § Format-vs-solutions: worked'
# Expect: 1 (the new path token in the F-G cross-reference).

# Confirm the stale path is gone from Variant: generate-agent-kickoff.
awk '/^## Variant: generate-agent-kickoff/,0' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md | grep -c 'supporting-docs/METHODOLOGY\.md'
# Expect: 0.

# Confirm the F-G cross-reference content is preserved (we updated the path; we did NOT damage the descriptive text after § Format-vs-solutions:).
grep -c '§ Format-vs-solutions: worked' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md
# Expect: 1 (the F-G-introduced cross-reference still says "§ Format-vs-solutions: worked" — only the path token in front of it changed).

# Confirm the multi-line continuation `examples`, prescribing a structural answer is also preserved.
grep -c "prescribing a structural answer in an architect prompt" /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md
# Expect: 1 (the F-G content body unchanged).

# Pack-wide final-state cross-check (post-C2 — both E9 and E10 applied).
grep -c 'supporting-docs/METHODOLOGY\.md' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md
# Expect: 0 (both stale-path occurrences fixed — line 84 by E9, line 276 by E10).

# Pack-wide final-state docs/pack/METHODOLOGY.md count.
grep -c 'docs/pack/METHODOLOGY\.md' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md
# Expect: 2 (line 84 from E9 + line 276 from E10). Pre-C2 baseline was 0.

# Confirm Variant: generate-agent-kickoff triad markers are intact (E10 must not damage triad).
awk '/^## Variant: generate-agent-kickoff/,0' /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/project-template/docs/pack/prompts/pm-chat.md | grep -cE '^\*\*(Problem|Goal|Success criteria|Constraints|Files in scope|Completion report):\*\*'
# Expect: at least the count present pre-E10 (the generate-agent-kickoff variant has triad markers — E10 touches a body-text line, not a triad marker; count must NOT change).
```

### 5.11 Edit C3 — `maintenance-docs/V10-PHASE-4-VERIFICATION.md` §13 evidence section

**File:** `/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev/maintenance-docs/V10-PHASE-4-VERIFICATION.md`
**Insertion point:** at end of file (after the existing §12.11 "Flag-back updates" subsection at line 1196). Append new H2 `## §13 Delta verification — F-A patch` section.

**Append text (template — implementer fills bracketed values from §7 harness output):**

```markdown

## §13 Delta verification — F-A patch

**Date:** [YYYY-MM-DDTHH:MM:SSZ] (UTC, harness execution timestamp)
**Patch commits:** `[C1 sha]` (design + plan docs), `[C2 sha]` (2-file behavioral patch).
**Scope:** Delta-only re-verification per project-lead Option A sequence — final v10.0 patch. Confirms METHODOLOGY § 7.0 redefines the surface-declaration gate semantically (β); § 7.6 carries the new preview-rendering rule; § 7.2.3 / § 7.2.4 / § 7.3.1 / § 7.3.2 carry brief cross-references to § 7.6; pm-chat.md kickoff variant body uses β phrasing for surface declaration; doc-discovery is surface-agnostic; continuation pointer path updated to `docs/pack/METHODOLOGY.md`. Full §4.1 / §4.3 / §4.7 NOT re-run; historical evidence in those sections retained as-was per delta-evidence pattern.

### §13.1 Static checks — METHODOLOGY edits

- `### 7.0 Trigger and scope` semantic-gate phrasing landed (`declared.*surface.*one-message exit ramp`): [1 hit / OK].
- Sanctioned-inference one-liner present (`sanctioned and not a deviation`): [1 hit / OK].
- Developer-override paragraph (`switch to manual mid-kickoff`) preserved verbatim: [1 hit / OK].
- New § 7.5 reply-grammar cross-reference inside § 7.0: [present / OK].
- `**Preview rendering.**` rule body present in § 7.6: [1 hit / OK].
- Preview rule names all four invocation sites (§ 7.2.3 / § 7.2.4 / § 7.3.1 / § 7.3.2): [OK].
- Existing § 7.6 "concurrent / interrupted kickoff handling" paragraph still present and downstream of new rule: [1 hit / OK].
- Cross-reference `§ 7.6 (Preview rendering)` total hits across § 7.2.3 / § 7.2.4 / § 7.3.1 / § 7.3.2: [4 hits / OK].

### §13.2 Static checks — pm-chat.md kickoff variant edits

- New β phrasing landed (`declare my surface and pause`): [1 hit / OK].
- Old literal-word gate (`Reply with the single word`) gone: [0 hits / OK].
- METHODOLOGY § 7.5 reply-grammar cross-reference present in kickoff body: [1 hit / OK].
- Four shell-capable surface enumeration preserved (Claude Code CLI / Codex CLI / Gemini CLI / Claude Desktop with Desktop Commander): [1 hit / OK].
- GitHub-connector assertion (`GitHub connector is connected`) gone: [0 hits / OK].
- "Search project knowledge" instruction gone: [0 hits / OK].
- Four doc names preserved (ARCHITECTURE.md, IMPLEMENTATION_PLAN.md, STATUS.md, BACKLOG.md): [present / OK].
- Surface-agnostic discovery wording landed (`Locate and read these by whatever means your surface provides`): [1 hit / OK].
- "Report what you can reach" fallback wording landed: [1 hit / OK].
- Continuation-pointer path updated (`docs/pack/METHODOLOGY.md` present in Variant: kickoff): [1 hit / OK].
- Stale continuation-pointer path gone from Variant: kickoff (`supporting-docs/METHODOLOGY.md` absent in kickoff body): [0 hits / OK].
- SETUP-NEW.md path on line ~87 preserved as `supporting-docs/SETUP-NEW.md`: [1 hit / OK].
- Convention exception (BD-049) line 23 unchanged: [1 hit / OK].
- No labeled sections introduced inside Variant: kickoff (no Problem / Goal / Success criteria / Constraints / Files in scope / Completion report bold-headers): [0 hits / OK].
- Kickoff "Before pasting" preamble lines 25–28 unchanged (per D4): [OK].
- Kickoff `PM-CHAT.md` placeholder-fill block lines 70–73 unchanged (per D8): [OK].

### §13.3 §4.1-shape kickoff smoke (Claude Code CLI)

Per design §9 (delta-verification fixture set, item a): static check that the patched kickoff body produces the documented β behavior on a Claude Code CLI surface. Full live re-run is out of scope per delta-evidence pattern.

- Fixture: `/tmp/v10-fa-fixtures/fresh-init/` (fresh git-init repo with seed README; built via `init-project.sh`).
- `init-project.sh` exit: [0].
- Fresh-init `docs/pack/METHODOLOGY.md` present: [OK].
- Fresh-init `docs/pack/METHODOLOGY.md` carries new § 7.0 semantic-gate wording: [OK — `declared.*surface.*one-message exit ramp` 1 hit].
- Fresh-init `docs/pack/METHODOLOGY.md` carries new § 7.6 Preview rendering rule: [OK — 1 hit].
- Fresh-init `docs/pack/METHODOLOGY.md` carries 4 cross-references to § 7.6: [OK — 4 hits].
- Fresh-init `docs/pack/prompts/pm-chat.md` carries new β surface-declaration block: [OK].
- Fresh-init `docs/pack/prompts/pm-chat.md` carries surface-agnostic doc-discovery: [OK].
- Fresh-init `docs/pack/prompts/pm-chat.md` continuation pointer references `docs/pack/METHODOLOGY.md` (NOT `supporting-docs/METHODOLOGY.md`) inside Variant: kickoff: [OK].
- **Paper-trace** through the new kickoff body on Claude Code CLI (the assistant pastes the kickoff variant; under β it declares `shell` by inference, names the next planned action, pauses; on developer `yes` it runs Form R; if Form I idempotency fires, the gate renders as a `note:` inside the Form R results table per the new § 7.6 preview rule): [PASS — kickoff body wording, METHODOLOGY § 7.0, and METHODOLOGY § 7.6 are mutually consistent; the §4.1 F1 deviation pattern is now the documented behavior, not a deviation].

### §13.4 §4.3-shape Web manual smoke (paper trace through new F-A.2 wording)

Per design §9 (delta-verification fixture set, item b): paper trace through the new F-A.2 surface-agnostic discovery wording on a no-connector Claude Web surface.

- The new doc-discovery block names four required docs (ARCHITECTURE.md, IMPLEMENTATION_PLAN.md, STATUS.md, BACKLOG.md) as the project-context contract: [OK].
- The new wording does NOT assert the GitHub connector is present (compare §4.3 evidence — that assertion was the false statement on no-connector Web): [OK — assertion absent].
- The new wording instructs the assistant to "report what you can reach" if no retrieval mechanism is available: [OK — fallback wording present].
- On a fresh Claude Web chat with no Project + no GitHub connector, the new wording would direct the assistant to (a) attempt project-knowledge / connector search; (b) on absence, report what it can access; (c) PM chat hand-feeds context. This is the §4.3 M2 behavior pattern, now sanctioned by the kickoff body wording rather than depending on the assistant adapting around a false assertion: [PASS].

### §13.5 §4.2-shape paper trace (Codex CLI / Gemini CLI / Desktop Commander)

Per design §9 (delta-verification fixture set, item c): paper trace through Codex CLI / Gemini CLI / Desktop Commander spec text per §4.2 to confirm β still applies.

- Codex CLI: shell-capable; assistant declares `shell` by inference per design §2.4; one-message pause before Form R; idempotency-fired Form I renders as Form R inline note. Workspace-write sandbox interaction on Form I `yes` is v10.1-deferred (F-B (b) item 2) — not blocked by F-A: [PASS].
- Gemini CLI: shell-capable; assistant declares `shell` by inference per design §2.4; if in `/plan` mode, plan-mode detection is v10.1-deferred (F-B (b) item 3); kickoff "Before pasting" preamble (line 26) already warns about `/plan`: [PASS].
- Desktop Commander: shell-capable via filesystem MCP; assistant declares `shell` by inference per design §2.4; allowlist interaction on Form M `yes` is v10.1-deferred (F-B (b) item 4); Form M default `skip` per § 7.2.4 unchanged: [PASS].

### §13.6 Pack-level regression guards

- `python3 scripts/validate-pack.py` exit: [0].
  - Check 6 (Prompts-directory format) on `pm-chat.md`: [PASS] — frontmatter and variant→H2 consistency unaffected by kickoff body content edits.
  - Check 10 (Prompt template triad compliance): [PASS] — kickoff variant excluded via `**Convention exception:**`; no other variant edited.
- `bash scripts/test-detect.sh` exit: [0]; reports [34/34] passing.

### §13.7 Trinity-rule check

- `git diff project-template/CLAUDE.md project-template/AGENTS.md project-template/GEMINI.md` returns empty: [OK].
- F-A modifies neither pm-chat.md trinity-files nor METHODOLOGY trinity-files; pm-chat.md is single-source per project-lead constraint; METHODOLOGY is single-source. Trinity-rule status: clean.

### §13.8 Live-OT byte-identity

- Live OT HEAD post-§13: `[capture rev-parse]` (unchanged from baseline; **12th post-baseline checkpoint** across this verification effort).
- Live OT working tree porcelain: empty.
- All §13 fixtures built under `/tmp/v10-fa-fixtures/`. No OT live-repo content involved.

### §13.9 Sanitization

All §13 fixtures synthetic; built from the v10-dev pack source. No OT content involved. The new METHODOLOGY § 7.0 wording, § 7.6 preview rule, cross-references, and pm-chat.md kickoff body are pack-distribution content (not OT-derived). Per §6.7.7 sanitization rules: clean.

### §13.10 Cleanup

`/tmp/v10-fa-fixtures/` removed at end of §13.

### §13.11 Pass / fail summary

| Check | Result |
|---|---|
| METHODOLOGY § 7.0 semantic-gate wording landed (β + sanctioned-inference + reply-grammar cross-ref) | [PASS] |
| METHODOLOGY § 7.6 preview-rendering rule landed (single source per D5) | [PASS] |
| 4 cross-references in § 7.2.3 / § 7.2.4 / § 7.3.1 / § 7.3.2 | [PASS — 4 hits] |
| pm-chat.md kickoff surface-declaration block β rewrite | [PASS] |
| pm-chat.md kickoff doc-discovery surface-agnostic rewrite | [PASS] |
| pm-chat.md kickoff continuation-pointer path update (D9 piggyback) | [PASS] |
| Convention exception (BD-049) preserved (no labeled sections) | [PASS — 0 labeled-section markers in Variant: kickoff] |
| Fresh-init propagation (METHODOLOGY + pm-chat.md correct in fixture) | [PASS] |
| §4.3-shape Web manual paper trace (no false assertions; fallback present) | [PASS] |
| §4.2-shape Codex / Gemini / Desktop Commander paper trace (β applies) | [PASS] |
| validate-pack.py | [PASS exit 0] |
| test-detect.sh | [PASS 34/34] |
| Trinity-rule (no trinity edits) | [PASS empty diff] |
| Live OT unchanged | [PASS — 12th post-baseline checkpoint] |

**Outcome:** **F-A resolved.** METHODOLOGY § 7.0 redefines the surface-declaration gate semantically (β); the historical "assistant skipped the gate" deviation is now sanctioned behavior with a sanctioned-inference one-liner that preempts re-filing as a defect. Form I / Form M idempotency-preview rendering is formalized once at § 7.6 with cross-references to the four invocation sites — historical "preview, no action needed" pattern is now the documented behavior. The kickoff variant body uses β phrasing for surface declaration and surface-agnostic prose for doc discovery — the false GitHub-connector assertion is removed; the four-doc project-context contract is preserved. Continuation pointer path updated to `docs/pack/METHODOLOGY.md` per F-D piggyback (D9). Convention exception (BD-049) preserved — no labeled sections introduced.

### §13.12 Flag-back updates

- **F-A → RESOLVED** (semantic-gate β + Form I/M preview formalization + surface-agnostic doc discovery + continuation-pointer path update).
- **Option A v10.0 sequence COMPLETE** (F-D + F-C, F-E + F-F, F-G, F-A all landed and verified).
- **F-B (b)** still deferred to v10.1 (three cross-surface live-runs: Codex CLI sandbox, Gemini CLI plan-mode, Desktop Commander allowlist). Layer onto Procedure 7 § 7.4 failure-handling discipline; not blocked by F-A's β change.
- **OQ-2 trinity-asymmetry follow-up** unchanged (separate / non-F-A concern; partially mitigated by F-G's swift-best-practices SKILL additions).
- F-G-introduced cross-reference at `pm-chat.md` line 276 (`supporting-docs/METHODOLOGY.md § Format-vs-solutions: worked examples` inside Variant: generate-agent-kickoff): **fixed by E10 in this patch** (FB-2 Option 2 second piggyback; updated to `docs/pack/METHODOLOGY.md`). Pack-wide post-C2: `pm-chat.md` carries 0 stale `supporting-docs/METHODOLOGY.md` references.
```

---

## 6. Per-commit verification checklist

Adapted from `V10-F-G-PLAN.md` §6 shape, specialized for this patch.

### 6.1 Pre-C2-commit checks

```
[ ] git status                          — staged files match the 2 listed in §3.1:
       supporting-docs/METHODOLOGY.md
       project-template/docs/pack/prompts/pm-chat.md
[ ] git diff --stat                     — METHODOLOGY ~+22 lines net (E1 +10, E2 +12, E3 +3, E4 +3, E5 +2, E6 +4 — ~+34 gross, ~+22 net after small line-merge overlaps; expect range +20 to +30); pm-chat.md ~−2 net (E7 −1, E8 −1, E9 ±0, E10 ±0 — the two single-token path piggybacks add zero lines).
[ ] git diff --name-only                — exactly the 2 files; no surprise additions; in particular NO trinity diff (§9.3 FB-3).
[ ] §5.1 grep checks (E1)               — all expected hit-counts match.
[ ] §5.2 grep checks (E2)               — all expected hit-counts match.
[ ] §5.3 grep checks (E3)               — `§ 7.6 (Preview rendering)` 1 hit in § 7.2.3.
[ ] §5.4 grep checks (E4)               — `§ 7.6 (Preview rendering)` 1 hit in § 7.2.4.
[ ] §5.5 grep checks (E5)               — `§ 7.6 (Preview rendering)` 1 hit in § 7.3.1.
[ ] §5.6 grep checks (E6)               — `§ 7.6 (Preview rendering)` 1 hit in § 7.3.2; total 4 across METHODOLOGY.
[ ] §5.7 grep checks (E7)               — β phrasing landed; literal-word gate gone; § 7.5 cross-ref present; surface enumeration preserved; Convention exception line unchanged; 0 labeled-section markers in Variant: kickoff.
[ ] §5.8 grep checks (E8)               — GitHub-connector assertion gone; "search project knowledge" gone; four doc names preserved; surface-agnostic discovery wording landed.
[ ] §5.9 grep checks (E9)               — kickoff variant has 1 hit `docs/pack/METHODOLOGY.md` and 0 hits `supporting-docs/METHODOLOGY.md`; SETUP-NEW.md path unchanged.
[ ] §5.10 grep checks (E10)             — generate-agent-kickoff variant has 1 hit `docs/pack/METHODOLOGY.md § Format-vs-solutions: worked` and 0 hits `supporting-docs/METHODOLOGY.md`; F-G cross-reference content (`§ Format-vs-solutions: worked` and continuation `prescribing a structural answer`) preserved verbatim; generate-agent-kickoff triad markers unchanged.
[ ] Pre-commit pack-wide path audit   — `grep -c 'supporting-docs/METHODOLOGY.md' project-template/docs/pack/prompts/pm-chat.md` returns 0 (both line 84 and line 276 fixed by E9 + E10; pre-C2 baseline was 2).
[ ] Pre-commit pack-wide path audit   — `grep -c 'docs/pack/METHODOLOGY.md' project-template/docs/pack/prompts/pm-chat.md` returns 2 (one from E9 at ~line 82, one from E10 at ~line 274; pre-C2 baseline was 0).
[ ] python3 scripts/validate-pack.py    — exits 0.
[ ] bash scripts/test-detect.sh         — exits 0; reports 34/34 passing.
[ ] Self-consistency re-read            — implementer reads the new METHODOLOGY § 7.0 + § 7.6 paragraphs and the new kickoff body block top-to-bottom; confirms (a) METHODOLOGY § 7.0 + § 7.6 + 4 cross-references are mutually consistent; (b) kickoff body β phrasing matches METHODOLOGY § 7.0 wording; (c) sanctioned-inference one-liner present.
[ ] Trinity rule N/A                    — `git diff project-template/CLAUDE.md project-template/AGENTS.md project-template/GEMINI.md` returns empty. (E1–E9 do NOT touch trinity files; confirm no diff slipped in.)
[ ] Convention exception preserved      — `awk '/^## Variant: kickoff/,/^## Variant: backlog-status-update/' pm-chat.md | grep -cE '^\*\*(Problem|Goal|Success criteria|Constraints|Files in scope|Completion report):\*\*'` returns 0.
[ ] §7 delta harness                    — fresh-init fixture build passes; output captured to /tmp; ready for §13 evidence section.
[ ] Approval gate                       — explicit project-lead "approved" before `git commit`.
```

### 6.2 Post-C2-commit checks

```
[ ] git log --oneline -1                — commit message matches §8.2 spec.
[ ] python3 scripts/validate-pack.py    — exits 0 (re-confirm post-commit).
[ ] gh run watch                        — Validate Pack workflow green on v10-dev branch.
```

### 6.3 Pre-C3-commit checks

```
[ ] §7 harness output captured to /tmp/v10-fa-fixtures/fresh-init.{stdout,stderr}.txt.
[ ] §13 section drafted with bracketed values filled from §7 outputs.
[ ] git diff maintenance-docs/V10-PHASE-4-VERIFICATION.md — only an append; no edits to existing §1–§12 content.
[ ] Approval gate                       — explicit project-lead "approved" before `git commit`.
```

**If validate-pack.py fails post-C2:** roll back per established pattern (`git reset --soft HEAD~1`), fix, recommit. Pack must remain working at every intermediate commit.

---

## 7. Verification harness — delta evidence

Per established F-D / F-E+F-F / F-G precedent (delta-only re-verification). Full §4.1 / §4.3 / §4.7 NOT re-run.

This patch is text-only (no script changes), so harness scope is much smaller than F-D. The harness verifies (a) METHODOLOGY content propagates correctly to a fresh-init project (§ 7.0 semantic-gate + § 7.6 preview rule + 4 cross-references), and (b) pm-chat.md kickoff variant content propagates correctly. State A/B/C/D matrix from F-D NOT applicable (no migration-path interaction; this patch only changes content of files that already propagate via existing copy paths).

**Decision:** Single fresh-init harness sufficient. No migration harness required (the migration script does not parse METHODOLOGY content or prompts/ content; it copies them whole — same conclusion as F-G §7).

**All operations within `/tmp/`. Live OT untouched. Live pack on `main` untouched.**

### 7.1 Pre-flight — pack repo state

```bash
cd /Users/david/Developer/dhs-ai-agent-config-pack-v10-dev
git status --porcelain        # Expect: empty (post-C2-commit) or only the 2 patched files (pre-C2-commit on staged tree).
git rev-parse HEAD            # Capture for §13 evidence.
PACK=/Users/david/Developer/dhs-ai-agent-config-pack-v10-dev
```

### 7.2 Fixture base directory

```bash
mkdir -p /tmp/v10-fa-fixtures
cd /tmp/v10-fa-fixtures
```

### 7.3 §13.3 — Fresh-init propagation harness

```bash
mkdir -p /tmp/v10-fa-fixtures/fresh-init
cd /tmp/v10-fa-fixtures/fresh-init
git init -q
echo "# fresh-init test fixture (F-A)" > README.md
git add README.md && git commit -q -m "seed"

PACK="$PACK" "$PACK/scripts/init-project.sh" . \
  > /tmp/v10-fa-fixtures/fresh-init.stdout.txt 2> /tmp/v10-fa-fixtures/fresh-init.stderr.txt
echo "init-project.sh exit: $?"

# Assert METHODOLOGY landed at docs/pack and carries the new § 7.0 + § 7.6 + cross-references.
[[ -f docs/pack/METHODOLOGY.md ]] && echo "OK: docs/pack/METHODOLOGY.md present" || echo "FAIL"
grep -q 'declared.*surface.*one-message exit ramp' docs/pack/METHODOLOGY.md \
  && echo "OK: § 7.0 semantic-gate wording present" || echo "FAIL"
grep -q 'sanctioned and not a deviation' docs/pack/METHODOLOGY.md \
  && echo "OK: § 7.0 sanctioned-inference one-liner present" || echo "FAIL"
grep -q '^\*\*Preview rendering\.\*\*' docs/pack/METHODOLOGY.md \
  && echo "OK: § 7.6 preview-rendering rule present" || echo "FAIL"
[[ $(grep -c '§ 7\.6 (Preview rendering)' docs/pack/METHODOLOGY.md) == 4 ]] \
  && echo "OK: 4 cross-references to § 7.6 present" || echo "FAIL"

# Assert pm-chat.md kickoff variant edits landed.
[[ -f docs/pack/prompts/pm-chat.md ]] && echo "OK: pm-chat.md present" || echo "FAIL"
grep -q 'declare my surface and pause' docs/pack/prompts/pm-chat.md \
  && echo "OK: β surface-declaration phrasing landed" || echo "FAIL"
[[ $(grep -c 'Reply with the single word' docs/pack/prompts/pm-chat.md) == 0 ]] \
  && echo "OK: literal-word gate gone" || echo "FAIL"
[[ $(grep -c 'GitHub connector is connected' docs/pack/prompts/pm-chat.md) == 0 ]] \
  && echo "OK: GitHub-connector assertion gone" || echo "FAIL"
[[ $(grep -c 'search project knowledge' docs/pack/prompts/pm-chat.md) == 0 ]] \
  && echo "OK: search-project-knowledge instruction gone" || echo "FAIL"
grep -q 'Locate and read these by whatever means your surface provides' docs/pack/prompts/pm-chat.md \
  && echo "OK: surface-agnostic discovery wording landed" || echo "FAIL"
grep -q 'report what you can reach and I will adapt' docs/pack/prompts/pm-chat.md \
  && echo "OK: fallback wording landed" || echo "FAIL"
# Continuation-pointer path update inside Variant: kickoff specifically.
n_new=$(awk '/^## Variant: kickoff/,/^## Variant: backlog-status-update/' docs/pack/prompts/pm-chat.md | grep -c 'docs/pack/METHODOLOGY\.md')
n_old=$(awk '/^## Variant: kickoff/,/^## Variant: backlog-status-update/' docs/pack/prompts/pm-chat.md | grep -c 'supporting-docs/METHODOLOGY\.md')
[[ "$n_new" == "1" && "$n_old" == "0" ]] \
  && echo "OK: E9 continuation-pointer path updated (Variant: kickoff)" || echo "FAIL E9 ($n_new new, $n_old old)"
# Path update inside Variant: generate-agent-kickoff (E10 — FB-2 Option 2 second piggyback).
n_new10=$(awk '/^## Variant: generate-agent-kickoff/,0' docs/pack/prompts/pm-chat.md | grep -c 'docs/pack/METHODOLOGY\.md § Format-vs-solutions: worked')
n_old10=$(awk '/^## Variant: generate-agent-kickoff/,0' docs/pack/prompts/pm-chat.md | grep -c 'supporting-docs/METHODOLOGY\.md')
[[ "$n_new10" == "1" && "$n_old10" == "0" ]] \
  && echo "OK: E10 path updated inside Variant: generate-agent-kickoff (FB-2 Option 2)" || echo "FAIL E10 ($n_new10 new, $n_old10 old)"
# F-G cross-reference content preserved (E10 must not damage F-G's descriptive prose).
grep -q '§ Format-vs-solutions: worked' docs/pack/prompts/pm-chat.md \
  && echo "OK: F-G cross-reference '§ Format-vs-solutions: worked' preserved post-E10" || echo "FAIL E10 damaged F-G content"
grep -q "prescribing a structural answer in an architect prompt" docs/pack/prompts/pm-chat.md \
  && echo "OK: F-G continuation prose preserved post-E10" || echo "FAIL E10 damaged F-G continuation prose"
# Pack-wide final-state path audit (both E9 and E10 applied).
[[ $(grep -c 'supporting-docs/METHODOLOGY\.md' docs/pack/prompts/pm-chat.md) == 0 ]] \
  && echo "OK: pack-wide pm-chat.md has 0 stale 'supporting-docs/METHODOLOGY.md' references" || echo "FAIL"
[[ $(grep -c 'docs/pack/METHODOLOGY\.md' docs/pack/prompts/pm-chat.md) == 2 ]] \
  && echo "OK: pack-wide pm-chat.md has 2 'docs/pack/METHODOLOGY.md' references (E9 + E10)" || echo "FAIL"
# SETUP-NEW.md path preserved.
[[ $(awk '/^## Variant: kickoff/,/^## Variant: backlog-status-update/' docs/pack/prompts/pm-chat.md | grep -c 'supporting-docs/SETUP-NEW\.md') == 1 ]] \
  && echo "OK: SETUP-NEW.md path preserved" || echo "FAIL"
# Convention exception preserved (no labeled sections in Variant: kickoff).
[[ $(awk '/^## Variant: kickoff/,/^## Variant: backlog-status-update/' docs/pack/prompts/pm-chat.md | grep -cE '^\*\*(Problem|Goal|Success criteria|Constraints|Files in scope|Completion report):\*\*') == 0 ]] \
  && echo "OK: Convention exception preserved (0 labeled-section markers)" || echo "FAIL"
```

### 7.4 §13.6 — Pack-level regression guards

```bash
cd "$PACK"
python3 scripts/validate-pack.py
echo "validate-pack.py exit: $?"           # Expect: 0
bash scripts/test-detect.sh
echo "test-detect.sh exit: $?"             # Expect: 0; reports 34/34 passing
```

### 7.5 §13.8 — Live-OT byte-identity

```bash
# Replace OT_LIVE with the actual live-OT clone path used in §10/§11/§12 evidence checkpoints.
# (Plan does NOT hardcode OT_LIVE — implementer uses the same path as previous checkpoints.)
cd "$OT_LIVE"
git rev-parse HEAD             # Expect: unchanged from baseline.
git status --porcelain         # Expect: empty.
```

### 7.6 §13.10 — Cleanup

```bash
rm -rf /tmp/v10-fa-fixtures
ls -ld /tmp/v10-fa-fixtures 2>&1
# Expect: "No such file or directory"
```

### 7.7 Evidence destination

The §13 evidence section is appended to `maintenance-docs/V10-PHASE-4-VERIFICATION.md` after the existing §12.11 line (current last line: 1196). Template per §5.11 (C3 evidence template; renumbered from §5.10 to §5.11 when E10 was inserted at §5.10 per FB-2 Option 2). The C3 commit lands the appended section.

---

## 8. Commit messages (proposed)

Per CLAUDE.md commit message format and the F-D / F-E+F-F / F-G precedent.

### 8.1 C1 commit message

```
docs: v10 — V10-F-A design + plan (kickoff gate + prose accuracy)

Architect (V10-F-A-DESIGN.md) and planner (V10-F-A-PLAN.md) outputs
for F-A — kickoff surface-declaration gate auto-inferred by assistant
on shell-capable surfaces (§4.1 F1 / §4.7 M-OT evidence; §4.2 docs-
research predicts same on Codex / Gemini / Desktop Commander) and
kickoff variant prose carries hardcoded environmental assumptions
("The GitHub connector is connected" + "search project knowledge"
— false on no-connector Web per §4.3 evidence). Decision: F-A.1 —
direction β (semantic-acceptance gate; assistant declares surface
and pauses one message before Form R; sanctioned-inference one-liner
in METHODOLOGY § 7.0 preempts re-flagging; Form I/M idempotency-
preview formalized once at § 7.6 with cross-references to § 7.2.3 /
§ 7.2.4 / § 7.3.1 / § 7.3.2). F-A.2 — direction (b) always-discover
(four-doc list preserved as project-context contract; HOW-to-retrieve
becomes surface-agnostic discovery instruction). Piggyback (D9):
update kickoff continuation-pointer path from
supporting-docs/METHODOLOGY.md to docs/pack/METHODOLOGY.md (F-D
path-stale fix on a file F-A is editing anyway). Convention
exception (BD-049) preserved.

No source files modified by this commit. Behavioral patch lands in
the next commit. Last v10.0 patch in Option A sequence.
```

### 8.2 C2 commit message

```
feat: v10 — BD-NNN F-A semantic-gate β + surface-agnostic discovery

Resolves F-A (kickoff surface-declaration gate auto-inferred by
assistant + kickoff prose carries hardcoded environmental
assumptions) per V10-F-A-DESIGN.md (architect 2026-04-29; project-
lead approved with 9 specific decisions D1–D9) and V10-F-A-PLAN.md
(planner 2026-04-29).

Files touched:
  supporting-docs/METHODOLOGY.md
    — § 7.0 Trigger and scope: replaced trigger paragraph with β
      semantic-gate wording (assistant declares surface and pauses
      one message before Form R; on shell-capable surfaces typically
      declares `shell` by inference — sanctioned and not a deviation;
      reply interpreted per § 7.5 grammar). Developer-override
      paragraph preserved verbatim.
    — § 7.6 Idempotency rules: added Preview rendering rule body —
      when Form I idempotency fires (tool present and in-range) or
      Form M source/target byte-identical, the gate renders as a
      single-line note inside the Form R results table rather than
      as a full Form. Preview is the gate; no developer reply.
    — § 7.2.3 / § 7.2.4 / § 7.3.1 / § 7.3.2: added 4 brief
      cross-references to § 7.6 (Preview rendering).
  project-template/docs/pack/prompts/pm-chat.md
    — Variant: kickoff lines 42–50: replaced surface-declaration
      block with β phrasing (declare and pause; reply per § 7.5
      grammar).
    — Variant: kickoff lines 52–58: replaced GitHub-connector
      assertion + search-project-knowledge instruction with
      surface-agnostic discovery wording (four doc names preserved
      as project-context contract; HOW-to-retrieve removed).
    — Variant: kickoff continuation pointer (line ~84): updated
      path supporting-docs/METHODOLOGY.md → docs/pack/METHODOLOGY.md
      (D9 piggyback F-D path-stale fix).

Convention exception (BD-049): preserved — no labeled sections
introduced inside Variant: kickoff.

Trinity rule: clean — pm-chat.md and METHODOLOGY are single-source
per project-lead constraint; no trinity edits required.

Verification: §13 delta-evidence harness in V10-PHASE-4-VERIFICATION
(separate docs: commit) — fresh-init propagation passes; static
checks confirm new METHODOLOGY content + new kickoff body content;
paper trace through §4.3-shape Web manual and §4.2-shape Codex /
Gemini / Desktop Commander confirms β applies; validate-pack.py
exits 0; test-detect.sh 34/34. Live OT unchanged (12th post-baseline
checkpoint).

BD-NNN to be assigned at C-V10-18 BACKLOG sweep. Last v10.0 patch
in Option A sequence (F-D + F-C, F-E + F-F, F-G, F-A all landed).
```

### 8.3 C3 commit message

```
docs: v10 — V10-PHASE-4-VERIFICATION §13 delta evidence (F-A)
```

---

## 9. Risks and assumptions

### 9.1 Risks

| # | Risk | Likelihood | Mitigation |
|---|---|---|---|
| R1 | The new METHODOLOGY § 7.0 paragraph is over-long (~15 lines vs the original 5) and increases RAG-ingest cost on every Procedure 7 retrieval. | Low | Per design §1.3, the kickoff body shrinks by ~8 lines; net pack-wide change is ~+6 lines. METHODOLOGY § 7.0 is read on procedure entry, not on every kickoff paste — the cost is per-procedure-invocation, not per-developer-kickoff. β's centralization tradeoff is the explicit project-lead choice (D1). |
| R2 | The new § 7.6 Preview rendering rule conflicts with the existing § 7.6 Form I / Form M bullets (which already document idempotency-fired skipping). | Low | The rule is additive — it formalizes the **rendering shape** (single-line note inside Form R) of the existing skipping behavior. The bullets continue to define WHEN the skip fires; the new paragraph defines HOW the skip is rendered. Self-consistency check in §6.1 confirms. |
| R3 | The 4 cross-references at § 7.2.3 / § 7.2.4 / § 7.3.1 / § 7.3.2 land out of order with E2 (§ 7.6) and reference content that does not yet exist mid-edit. | Low | §4 edit order explicitly places E2 before E3–E6 to eliminate this transient state. §6.1 pre-commit checklist gates on all 4 cross-references being present (4-hit grep) only after all six METHODOLOGY edits land. |
| R4 | The kickoff body β phrasing is read by the assistant as license to skip the surface-declaration entirely (no declaration; no pause). | Low–Medium | Plan wording explicitly says "I will declare my surface and pause for your reply before running any non-read-only action" — both clauses retained. The §13.3 paper trace confirms the new wording produces the §4.1 F1 substantive behavior (declare + Form R discovery; idempotency-fired Form I as inline note). The §4.7 M-OT pattern is also re-confirmed. If live testing post-ship surfaces "no declaration" behavior, that becomes a new (separate) defect, not an F-A regression. |
| R5 | The continuation-pointer path update on line 84 misses the asymmetric `supporting-docs/SETUP-NEW.md` reference on line 89, leading to an inconsistent post-edit state. | Low | §5.9 explicitly documents that line 89 is NOT edited (SETUP-NEW.md lives only at `supporting-docs/` per design §4.1). §5.9 verification check confirms `supporting-docs/SETUP-NEW.md` still has 1 hit post-C2. |
| R6 | The §1 doc-discovery wording is read by the developer as removing the four-doc requirement. | Low | The four doc names are preserved verbatim and front-loaded in the new wording (`**Project documents the PM chat needs in context:** ARCHITECTURE.md, IMPLEMENTATION_PLAN.md (current phase), STATUS.md, BACKLOG.md.`). §5.8 verification checks that all four names are present post-C2. |
| R7 | Line numbers in `supporting-docs/METHODOLOGY.md` drift across E1–E6 (each insert shifts downstream lines). The implementer applies E3–E6 by anchoring on absolute line numbers instead of content. | Low | §5.3 / §5.4 / §5.5 / §5.6 each explicitly note the line drift and instruct the implementer to anchor on content (the closing line of each sub-section's idempotency paragraph), not on absolute line numbers. |
| R8 | CI (`Validate Pack` GitHub Actions workflow) does not exercise content propagation through `init-project.sh`, only validate-pack.py. So the §7 fresh-init harness must be run locally. | Medium — known CI shape limitation. | The §7 harness IS the verification. Implementer runs it; project lead reviews evidence. CI is a regression backstop, not the primary gate. Same posture as F-G §7. |
| R9 | The new kickoff body wording "Reply `yes` to authorize Form R discovery, `manual` to override mid-kickoff, or per the METHODOLOGY § 7.5 reply grammar" is read by the developer as ambiguous (which is the default? what does an empty reply mean?). | Low | The METHODOLOGY § 7.5 reply grammar already specifies "Empty / unrecognized / 'no' / 'don't' / 'wait' → treated as `no`; re-prompt with a clarifying question. Never defaults to `yes`." The kickoff body's cross-reference to § 7.5 is sufficient — over-specifying the reply grammar in the kickoff body inflates token cost (per design §2.1 wording-budget concern). D3 explicitly chose this resolution. |

### 9.2 Assumptions

| # | Assumption | Resolution |
|---|---|---|
| A1 | METHODOLOGY § Procedure 7 anchor lines (§ 7.0 starts at line 1354; § 7.6 starts at line 1591) match the architect's design read at 2026-04-29. | **Confirmed** — `grep -n '^#### 7\.[06]' supporting-docs/METHODOLOGY.md` returns matching line numbers. |
| A2 | The developer-override paragraph at lines 1361–1365 (preserved verbatim per design §1.1 / §2.6 / D1) is structurally a discrete paragraph that can be left untouched while replacing only the trigger paragraph above it. | **Confirmed** — lines 1361–1365 are a self-contained paragraph separated from the trigger paragraph by a blank line; can be preserved by anchoring on its opening clause `The developer may declare manual even on a shell-capable surface`. |
| A3 | The pm-chat.md kickoff variant body lines 42–50, 52–58, 84 match the design's read at 2026-04-29 (no intervening edits). | **Confirmed** — `grep -n 'Before I do anything else\|GitHub connector is connected\|supporting-docs/METHODOLOGY' project-template/docs/pack/prompts/pm-chat.md` returns matching line numbers in Variant: kickoff. |
| A4 | `validate-pack.py` Check 6 does not inspect prompt-variant body content beyond frontmatter + variant→H2 mapping. | **Confirmed via F-G plan §10.1** — Check 6 source (validate-pack.py lines 283–393) reads frontmatter and matches H2 headings; body content not parsed. |
| A5 | `validate-pack.py` Check 10 explicitly excludes the kickoff variant via the `**Convention exception:**` callout. | **Confirmed via F-G plan §10.3** — the Variant: kickoff section's `**Convention exception:**` excludes it from Check 10's triad-marker compliance. |
| A6 | The line 84 path is the only `supporting-docs/METHODOLOGY.md` reference inside Variant: kickoff. | **Confirmed** — `awk '/^## Variant: kickoff/,/^## Variant: backlog-status-update/' pm-chat.md \| grep -c 'supporting-docs/METHODOLOGY\.md'` returns 1 (line 84). Line 28 unqualified reference (`METHODOLOGY.md Procedure 7`) is path-name-only, not a path; per design §4.1 — no edit. |
| A7 | The F-G-introduced cross-reference at line 276 (Variant: generate-agent-kickoff) is INSIDE F-A scope post-amendment (was originally OUT OF SCOPE; FB-2 RESOLVED with project-lead Option 2 — extended F-A scope to include line 276 as E10). | **Confirmed — E10 added at §5.10; line 276 path token updated from `supporting-docs/METHODOLOGY.md` to `docs/pack/METHODOLOGY.md` as part of F-A C2. Pack-wide post-C2: `pm-chat.md` carries 0 stale `supporting-docs/METHODOLOGY.md` references. See §5.10, §9.3 (FB-2 RESOLVED), §10.4, §10.8.** |
| A8 | The METHODOLOGY § 7.5 reply grammar (lines 1582–1589 area) is unchanged by this patch and continues to be the canonical reply grammar reference. | **Confirmed** — F-A makes no edits to § 7.5; the new § 7.0 / kickoff-body cross-references point at it as a stable target. |
| A9 | The pack-level test fixtures (`scripts/test-detect.sh` 34 tests) do not assert specific kickoff body content. | **Confirmed by precedent** — F-G's same patch shape ran test-detect.sh post-C2 and got 34/34. F-A's edits are smaller in scope. |

### 9.3 Flag-backs (conditions where implementer pauses)

The implementer MUST flag-back to the parent agent before proceeding if:

- **FB-1.** `validate-pack.py` Check 6 fails after E7 / E8 / E9 land. Diagnose before proceeding to commit; the edit may have inadvertently shifted a frontmatter line or broken a `## Variant:` H2 anchor (kickoff variant boundaries must remain intact for Check 6).
- **FB-2 — RESOLVED (project-lead chose Option 2 at planner-pass amendment time).** The F-G-introduced cross-reference at `pm-chat.md` line 276 (inside `Variant: generate-agent-kickoff`) reads `supporting-docs/METHODOLOGY.md § Format-vs-solutions: worked examples` — the same path-staleness pattern that D9 piggybacks at line 84. Project lead extended F-A scope to add E10 as a second path-staleness piggyback at line 276 (single-token replacement; same fix as E9, different line, different variant). E10 specification at §5.10; lands as the smallest-and-last edit in C2 after E9. **No pre-C2 pause required for this item — project-lead direction received and incorporated.**
- **FB-3.** Trinity-rule `git diff project-template/{CLAUDE,AGENTS,GEMINI}.md` returns non-empty after E1–E9. The plan asserts no trinity edits — any trinity diff is unexpected and requires diagnosis before commit.
- **FB-4.** The §6.1 self-consistency re-read of the new METHODOLOGY § 7.0 + § 7.6 + 4 cross-references identifies any inconsistency (e.g., § 7.0 references § 7.6 by a name the rule paragraph does not use; cross-references point at a sub-rule that the rule does not articulate). Pause; revise; re-read; do not commit until clean.
- **FB-5.** The §7.3 fresh-init harness fails any assertion. Do NOT commit C2 (or, if already committed, do NOT commit C3) before the failure is diagnosed.
- **FB-6.** Live OT rev-parse / porcelain check (§7.5) returns anything non-empty / non-baseline. Do NOT commit; investigate (no live-OT writes are sanctioned in F-A scope).

---

## 10. Cascading-effect checks

### 10.1 Does the new METHODOLOGY § 7.0 wording interact with Procedure 5-S (F-E + F-F) or Procedure 5-R?

**Answer: NO.** Procedure 5-S (post-migration housekeeping; sentinel-driven via `migrate-v9-to-v10.sh` writing `.pack-migration-pending`) and Procedure 5-R (post-restart housekeeping) are both detected at `/pm-startup` SKILL Step 0, BEFORE any Procedure 7 invocation. They have distinct triggers (sentinel file presence; pack-version markers) and distinct entry points (`/pm-startup` SKILL, not the kickoff variant body). Procedure 7's β semantic-gate fires only AFTER `/pm-startup` Step 0 routing has determined that no 5-R / 5-S work is pending. **No interaction.** Confirmed by reading design §4.2 (F-E + F-F coexistence).

### 10.2 Does the kickoff body change affect existing evidence in §4.1 / §4.3 / §4.7?

**Answer: NO.** Those evidence sections are historical (already-committed; record what happened on the previous fixture build). This patch's delta verification adds §13; it does not rewrite §4.x. The §4.1 F1 deviation pattern (assistant declared `shell` by inference + collapsed Form I/M into Form R inline notes) is now the documented behavior — but §4.1 records the historical observation, including the deviation classification at the time. §13 explicitly notes the reclassification ("the §4.1 F1 deviation pattern is now the documented behavior, not a deviation") without editing §4.1 itself. Same posture as F-D / F-E+F-F / F-G.

### 10.3 Does pm-chat.md's PROMPT-AUTHORING.md / Convention exception status change?

**Answer: NO.** Per design §2.5 + F-G audit (V10-F-G-DESIGN.md line 308: *"Variant: kickoff. Carries documented convention exception. No prescriptive content beyond surface-detection and read-list. Clean."*). F-A's edits to Variant: kickoff body do NOT introduce labeled sections (Problem / Goal / Success criteria / etc.) — the new β surface-declaration block remains unstructured prose; the new doc-discovery block remains unstructured prose. §5.7 verification check explicitly counts labeled-section markers in Variant: kickoff post-edit and asserts 0. **Convention exception (BD-049) preserved.**

Additionally per F-G design §4.3 / F-A design §4.3: F-A.2's discovery wording is itself an instance of F-G's "format-vs-solutions" rule applied to kickoff prose — it names the requirement (four doc names) without prescribing the retrieval mechanism (project-knowledge / GitHub-connector / filesystem-read). F-A's wording REINFORCES F-G's pattern; it does not violate it.

### 10.4 Does the path-update on lines 84 and 276 break any other reference?

**Answer: NO — both stale-path sites in pm-chat.md addressed by E9 + E10 (FB-2 RESOLVED with Option 2).** The kickoff variant body (Variant: kickoff) has one `supporting-docs/METHODOLOGY.md` reference at line 84 (the continuation pointer); E9 updates that. The generate-agent-kickoff variant body has one `supporting-docs/METHODOLOGY.md` reference at line 276 (the F-G-introduced `§ Format-vs-solutions: worked examples` cross-reference); E10 updates that. Both are single-token replacements; both preserve all surrounding text.

**E10 cascading-effect verification (FB-2 Option 2):**
- The line-276 edit changes ONLY the path token. The leading whitespace (8-space indent), the `per ` prefix, the backticks bracketing the path, the ` § Format-vs-solutions: worked` suffix on the same line, the line break, the continuation line `examples`, prescribing a structural answer in an architect prompt`, and the closing line `anchors the agent and is forbidden.` are ALL preserved verbatim. The F-G-introduced semantic content (the "Format-vs-solutions: worked examples" cross-reference body that F-G commit `a7d3542` landed) is unchanged.
- E10 does NOT interact with Check 10 (Prompt template triad compliance). E10 touches a single body-text token inside an existing pointer item; it does not introduce, remove, or alter any `**Problem:**` / `**Goal:**` / `**Success criteria:**` / `**Constraints:**` / `**Files in scope:**` / `**Completion report:**` triad marker. The Variant: generate-agent-kickoff section's triad markers (which F-G validated to be Check 10 compliant) remain in place. The §5.10 verification grep explicitly counts triad markers post-E10 to confirm no change. See also §10.8.

Other `supporting-docs/METHODOLOGY.md` references pack-wide (not in pm-chat.md): out of F-A scope. The F-D residual cross-reference audit was completed at F-D landing (commit `603234e`); any remaining stale references in other files are F-D residual items, not F-A items. After C2 lands, `pm-chat.md` carries 0 stale `supporting-docs/METHODOLOGY.md` references.

### 10.5 Does the new METHODOLOGY § 7.6 preview rule interact with `init-project.sh` `blast_radius_sweep` (per F-D §10.0 surfacing)?

**Answer: NO.** The blast-radius-sweep scans `docs/pack/` for `PROMPT-TEMPLATES` references (per F-D §10.0). The new § 7.6 paragraph does NOT add any `PROMPT-TEMPLATES` mention. The pre-existing `--exclude='METHODOLOGY.md'` mitigation from F-D commit `55d1834` continues to apply regardless. No interaction.

### 10.6 Does the new kickoff body wording interact with any other pm-chat.md variant?

**Answer: NO for substantive prose; YES (intentional, single-token) for `Variant: generate-agent-kickoff` line 276 path piggyback (E10).** F-A's substantive prose edits are confined to `## Variant: kickoff` (lines 18–91): E7 (surface-declaration block), E8 (doc-discovery block), E9 (path-update on line 84). The other variants (`backlog-status-update`, `generate-setup`, `generate-agent-kickoff`) carry no surface-declaration prose, no GitHub-connector assertions, and no kickoff-time doc discovery. The single touch outside `Variant: kickoff` is E10 — a single-token path-update at line 276 inside `Variant: generate-agent-kickoff` (FB-2 Option 2 second piggyback). E10 does NOT alter `Variant: generate-agent-kickoff` substantive prose or triad structure; it replaces only the stale F-D path token. Verified by reading the full file (Read result lines 93–293) and the targeted re-read at lines 273–278 during planner-pass amendment.

### 10.7 Does the §13 evidence section interact with §10 / §11 / §12 evidence sections?

**Answer: NO.** §13 is a fresh append (after §12.11 at line 1196). The existing §10 (F-D + F-C delta), §11 (F-E + F-F delta), and §12 (F-G delta) sections are not edited. The §13 "Live-OT byte-identity" subsection records the **12th post-baseline checkpoint** (consistent with §12's "11th" — incremented by one). No cross-section dependencies broken.

### 10.8 Does E10 interact with `validate-pack.py` Check 10 (Prompt template triad compliance) on the `generate-agent-kickoff` variant?

**Answer: NO.** Check 10 verifies that prompt-template variants carry the standard triad markers (`**Problem:**` / `**Goal:**` / `**Success criteria:**` / `**Constraints:**` / `**Files in scope:**` / `**Completion report:**`). The `Variant: generate-agent-kickoff` section already carries its own triad markers (validated as compliant by F-G commit `a7d3542`). E10 is a single-token path replacement on a body-text line INSIDE one of that variant's content blocks — it does NOT touch any triad marker line; it does NOT add or remove any `**Marker:**` line; it does NOT change any H2 or H3 heading. The §5.10 verification grep (`grep -cE '^\*\*(Problem|Goal|Success criteria|Constraints|Files in scope|Completion report):\*\*'` scoped to Variant: generate-agent-kickoff) explicitly confirms triad-marker count is unchanged post-E10. **Check 10 status post-E10: clean.** Per F-G plan §10.3 cross-reference.

---

## 11. Open-question resolutions

### 11.1 OQ-F-A-1 (D3) — exit-ramp shape vs literal words?

**Resolution: SHAPE-ONLY; reuse § 7.5 reply grammar.** Per project-lead D3. The new METHODOLOGY § 7.0 wording specifies the shape (declare + pause; reply per § 7.5 grammar) without naming literal trigger words. The kickoff body wording at E7 mirrors this: `Reply yes to authorize Form R discovery, manual to override mid-kickoff, or per the METHODOLOGY § 7.5 reply grammar`. The § 7.5 grammar already covers `yes` / `no` / `skip` / `abort` / `edit` / bare values — sufficient.

### 11.2 OQ-F-A-2 (D4) — edit kickoff "Before pasting" preamble?

**Resolution: NO EDIT.** Per project-lead D4. The preamble (`pm-chat.md` lines 25–28) carries operational warnings to the developer (Gemini `/plan` mode; Web no-shell). It does not assert anything about the assistant's environment. F-A.2 scope is environmental-assertion removal; the preamble has none. **Lines 25–28 untouched in F-A.**

### 11.3 OQ-F-A-3 (D5) — preview rule placement?

**Resolution: SINGLE-SOURCE AT § 7.6 + 4 CROSS-REFERENCES.** Per project-lead D5. The new Preview rendering rule body lands at § 7.6 (E2). Brief cross-references land at § 7.2.3 / § 7.2.4 / § 7.3.1 / § 7.3.2 (E3 / E4 / E5 / E6). Avoids the four-parallel-edits anti-pattern; aligns with the design §1.1 / §2.3 placement decision.

### 11.4 OQ-F-A-4 (D6) — example anchor in F-A.2 discovery wording?

**Resolution: NO EXAMPLE.** Per project-lead D6. The §5.8 (E8) wording includes the surface-agnostic discovery instruction and the "report what you can reach" fallback — it does NOT anchor on an example of what the report looks like. The §4.3 evidence shows the assistant on Claude Web correctly identified what was accessible without an example; adding one would inflate the kickoff body for a behavior that already works.

### 11.5 OQ-F-A-5 (D7) — sanctioned-inference one-liner in § 7.0?

**Resolution: ADD ONE LINE.** Per project-lead D7. The §5.1 (E1) wording includes the explicit phrase `this is sanctioned and not a deviation` as part of the new § 7.0 paragraph. Pre-empts the next round of verification from re-filing F-A as a fresh defect.

### 11.6 OQ-F-A-6 (D8) — edit kickoff `PM-CHAT.md` placeholder-fill block (lines 70–73)?

**Resolution: NO EDIT.** Per project-lead D8. The block is a post-surface-declaration follow-on task and is independent of the surface-declaration gate and the doc discovery. F-F's Procedure 5-S handles the migration-time placeholder case; the kickoff-time block here handles the fresh-project case. They do not overlap. **Lines 70–73 untouched in F-A.**

### 11.7 D9 — piggyback continuation-pointer path update?

**Resolution: PIGGYBACK (extended to BOTH stale-path sites per FB-2 Option 2).** Per project-lead D9. The continuation pointer at `pm-chat.md` line 84 currently references `supporting-docs/METHODOLOGY.md`; F-D moved METHODOLOGY to `docs/pack/`. F-A is editing the kickoff body anyway (E7, E8); E9 piggybacks the path-update as a single-token edit on the same lines region. Per **FB-2 Option 2** (project-lead direction received at planner-pass amendment), the piggyback is EXTENDED to a second site at `pm-chat.md` line 276 (inside `Variant: generate-agent-kickoff`, F-G-introduced cross-reference) as E10. Both single-token replacements; both free fixes; saves two separate BACKLOG cycles. F-A C2 now lands a clean `pm-chat.md` with zero stale `supporting-docs/METHODOLOGY.md` references.

---

## 12. Self-check

- **Can the implementer execute the 10 edits + harness + 3 commits without further architectural calls?** Yes — every edit (E1, E2, E3, E4, E5, E6, E7, E8, E9, E10 in execution order) has its file, line range, before/after snippet (or insertion-point spec), verbatim insert text, and grep verification check. The §7 harness is copy-pasteable bash. No design questions remain (D1–D9 baked-in; OQ-F-A-1..6 resolved per §11; **FB-2 RESOLVED with Option 2 — E10 added per project-lead direction**). No pre-C2 pause points remain active.
- **Are the proposed wording strings actually correct (not pseudocode)?** Yes — §5.1, §5.2, §5.3, §5.4, §5.5, §5.6, §5.7, §5.8, §5.9, §5.10 all contain verbatim insert text in fenced markdown blocks, ready to paste. The implementer copy-pastes; no creative judgment required. §5.10 (E10) before/after strings were verified against the working tree by Read at planner-pass amendment time.
- **Is the convention exception (BD-049) preserved (no labeled sections introduced)?** Yes — §5.7 (E7) and §5.8 (E8) wording is unstructured prose within the existing exception structure; no `**Problem:**` / `**Goal:**` / `**Success criteria:**` / `**Constraints:**` / `**Files in scope:**` / `**Completion report:**` markers introduced. §5.7 verification check explicitly counts labeled-section markers in Variant: kickoff post-edit and asserts 0. §6.1 and §13.2 both gate on this.
- **Does the path update on lines 84 and 276 land cleanly?** Yes — §5.9 (E9) updates only line 84 (the `supporting-docs/METHODOLOGY.md` token in `Variant: kickoff`); line 89 (`supporting-docs/SETUP-NEW.md`) is intentionally NOT edited (per design §4.1 — SETUP-NEW.md is at `supporting-docs/` and is not copied into the project tree under v10). §5.10 (E10) updates only the `supporting-docs/METHODOLOGY.md` token at line 276 inside `Variant: generate-agent-kickoff` (the F-G-introduced cross-reference body), preserving the surrounding `§ Format-vs-solutions: worked examples` descriptive text and all other tokens on that multi-line bullet verbatim. §5.9 + §5.10 verification checks together confirm post-C2: `supporting-docs/SETUP-NEW.md` 1 hit (preserved), `supporting-docs/METHODOLOGY.md` 0 hits (both stale sites fixed), `docs/pack/METHODOLOGY.md` 2 hits (one each from E9 and E10). FB-2 RESOLVED via Option 2.
- **Is the §13 evidence template specific enough to populate without creative judgment?** Yes — §5.11 (C3 evidence template; renumbered from §5.10 post-E10 insertion) specifies §13.1 / §13.2 (static checks with literal grep expectations), §13.3 (fresh-init harness with literal assertion strings), §13.4 (paper trace with explicit verification points), §13.5 (per-surface paper trace), §13.6 (regression guards), §13.7 (trinity diff), §13.8 (live-OT checkpoint number), §13.9 (sanitization), §13.10 (cleanup), §13.11 (pass/fail table), §13.12 (flag-back updates). Every bracketed value is either a fixed literal expectation or a single command output to capture.
- **Trinity-rule check:** §3.4 / §6.1 / §13.7 / §10 (no item) all confirm no trinity edits required. F-A modifies neither `pm-chat.md` trinity-files nor METHODOLOGY trinity-files. **Trinity-rule status: clean.**
- **Cascading-effect checks complete:** §10 covers Procedure 5-S / 5-R interaction (none); §4.1 / §4.3 / §4.7 historical-evidence interaction (none — historical sections not edited); Convention exception status (preserved); path-update side effects (line 84 fixed by E9; line 89 untouched; line 276 fixed by E10 — FB-2 Option 2); blast-radius-sweep interaction (none — no PROMPT-TEMPLATES mention); other pm-chat.md variants (substantive prose untouched; only single-token path piggyback at line 276 inside generate-agent-kickoff); §13 vs §10 / §11 / §12 evidence sections (no cross-section dependencies broken); E10 vs Check 10 triad compliance (no interaction — §10.8).
- **Flag-backs surfaced:** FB-1 (validate-pack.py post-E7–E10), **FB-2 RESOLVED (Option 2 — E10 added)**, FB-3 (trinity diff non-empty), FB-4 (METHODOLOGY self-consistency), FB-5 (fresh-init harness failure), FB-6 (live-OT non-baseline). No ACTIVE pre-C2 pause points remain; all remaining flag-backs are conditional on harness/grep failures.

---

## 13. Summary

**Decision:** 3-commit pattern (C1 docs design+plan, C2 atomic 2-file behavioral patch, C3 docs §13 delta evidence) matching the F-D / F-E+F-F / F-G shape. C2 is **10 edits** (6 in METHODOLOGY, 4 in pm-chat.md — the 4th is E10 added per FB-2 Option 2) executed in the order E1 → E2 → E3 → E4 → E5 → E6 → E7 → E8 → E9 → E10.

**Edits in C2 (execution order):**
1. **E1** — `supporting-docs/METHODOLOGY.md` § 7.0 (lines 1354–1365 area) — replace trigger paragraph with β semantic-gate wording + sanctioned-inference one-liner; preserve developer-override paragraph (lines 1361–1365) verbatim.
2. **E2** — `supporting-docs/METHODOLOGY.md` § 7.6 — append Preview rendering rule body (single source per D5).
3. **E3** — `supporting-docs/METHODOLOGY.md` § 7.2.3 — append brief cross-reference to § 7.6 (Preview rendering).
4. **E4** — `supporting-docs/METHODOLOGY.md` § 7.2.4 — append brief cross-reference to § 7.6 (Preview rendering).
5. **E5** — `supporting-docs/METHODOLOGY.md` § 7.3.1 — append brief cross-reference to § 7.6 (Preview rendering).
6. **E6** — `supporting-docs/METHODOLOGY.md` § 7.3.2 — append brief cross-reference to § 7.6 (Preview rendering).
7. **E7** — `project-template/docs/pack/prompts/pm-chat.md` Variant: kickoff lines 42–50 — replace surface-declaration block with β phrasing.
8. **E8** — `project-template/docs/pack/prompts/pm-chat.md` Variant: kickoff lines 52–58 — replace GitHub-connector + search-project-knowledge prose with surface-agnostic discovery instruction (D2; D6 — no example anchor).
9. **E9** — `project-template/docs/pack/prompts/pm-chat.md` Variant: kickoff line 84 — update path token `supporting-docs/METHODOLOGY.md` → `docs/pack/METHODOLOGY.md` (D9 piggyback; first of two single-line path-staleness fixes).
10. **E10** — `project-template/docs/pack/prompts/pm-chat.md` Variant: generate-agent-kickoff line 276 — update path token `supporting-docs/METHODOLOGY.md` → `docs/pack/METHODOLOGY.md` inside the F-G-introduced `§ Format-vs-solutions: worked examples` cross-reference (FB-2 Option 2 piggyback; second of two single-line path-staleness fixes; smallest-change-last).

**Net change:** ~+22 net lines METHODOLOGY; ~−2 net lines pm-chat.md (E9 and E10 are single-token path replacements that add zero lines); ~+20 net pack-wide. Comparable to F-G (~+53 net) and smaller than F-D (5-file behavioral patch).

**Verification:** single fresh-init harness under `/tmp/v10-fa-fixtures/` with 14 static-check assertions on METHODOLOGY content and **17 static-check assertions on pm-chat.md content** (13 original + 4 added for E10 — Variant: generate-agent-kickoff line 276 path update + F-G content preservation + pack-wide stale-path zero-count + pack-wide new-path two-count), paper traces through §4.3-shape Web manual and §4.2-shape Codex / Gemini / Desktop Commander, validate-pack.py exit 0, test-detect.sh 34/34, live OT byte-identical (12th checkpoint). All within /tmp; live OT and live pack-on-main untouched. §13 evidence template ready for C3.

**Trinity rule:** clean (no trinity edits; pm-chat.md and METHODOLOGY are single-source per project-lead constraint).

**Convention exception (BD-049):** preserved (no labeled sections introduced inside Variant: kickoff; verified via grep gate at §6.1 and §13.2).

**Open questions resolved:** OQ-F-A-1 (shape-only via § 7.5 grammar per D3), OQ-F-A-2 (no preamble edit per D4), OQ-F-A-3 (single-source at § 7.6 + 4 cross-references per D5), OQ-F-A-4 (no example anchor per D6), OQ-F-A-5 (sanctioned-inference one-liner per D7), OQ-F-A-6 (no PM-CHAT.md placeholder-fill edit per D8), D9 piggyback path-update (extended to BOTH stale-path sites per FB-2 Option 2: E9 at line 84 + E10 at line 276).

**Flag-backs surfaced:** **FB-2 RESOLVED with project-lead Option 2** — F-A scope extended to include the F-G-introduced cross-reference at `pm-chat.md` line 276 (Variant: generate-agent-kickoff) as a second piggyback (E10 — see §5.10). No ACTIVE pre-C2 pause points remain. All other flag-backs (FB-1 / FB-3 / FB-4 / FB-5 / FB-6) are conditional on harness/grep failures.

**Sequence position:** F-A is the **final v10.0 patch** in the Option A sequence. After C1 / C2 / C3 land and §13 evidence is captured, the v10.0 ship-blocker queue is empty. F-B (b) three cross-surface live-runs remain deferred to v10.1.
