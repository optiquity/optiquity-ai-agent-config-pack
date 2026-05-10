# Pack Review — OT v10→v11 Trinity Marker Prep

**Reviewer:** pack-reviewer (Opus 4.7, 1M-ctx)
**Date:** 2026-05-10
**Repos under review (read-only):**
- OT working tree: `/Users/david/Developer/OptiquityTrader/`
- v10.1 baseline: `/Users/david/Developer/optiquity-ai-agent-config-pack/project-template/`
- v11-dev (BD-136 spec source): `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/`

## Verdict (one-line)

**Needs re-prep — pack-owned text was modified outside markers in all three trinity files, and 3 of 12 marker pairs per file wrap H2 headers in violation of the body-only-not-header rule asserted in the BD-136 spec and in the prep report itself.**

The marker counts, ordering, and balance are clean (well-formed: 12/12 BEGIN/END per file, strictly alternating, no nesting, ending at EOF, all bracketing real text). But the structural / semantic invariants the BD-136 pattern depends on are violated in two specific ways that, if committed as-is, will cause v11's marker-aware merger (when it lands) to either (a) silently lose the OT customizations to "Apple APIs" / "Document any new setup step in README.md" / "Active skills" line / `Dependency intake policy bullets 1-4` / etc., because those edits sit in pack-owned territory and will be overwritten by v11's pack text on update, or (b) — for the H2-wrapped sections — bind OT to its own H2 spelling forever, even when the pack canonicalises a different H2 name later. Both classes of issue are fixable with concrete edits enumerated below in §3.

The prep is *very nearly* good — the prep report is honest, the marker mechanics are clean, the trinity-symmetric placement is real, and 8 of the 12 marker pairs per file are textbook correct. The 4 defective pairs per file plus ~6 unwrapped pack-text edits per file are the entire delta between "OK to commit with edits" and the "needs re-prep" verdict. I lean toward **OK to commit with edits (listed in §3)** rather than full re-prep — the edits are mechanical and the prep author's intent is clear from the report. Final call rests with the user.

---

## 1. Marker accounting (per-file structural assessment)

Source-of-truth scan: `grep -n 'BEGIN project-owned\|END project-owned' <file>`.
All 36 marker pairs (12 per file × 3 files) are present, balanced, and strictly
alternating (BEGIN at odd index, END at even index, no nesting, no orphans).
Files end at the final END marker (12th END is the last line of file).

### CLAUDE.md (590 lines, 12 pairs)

| # | BEGIN line | END line | Section under wrap | H2-or-H3 wrapped? | Verdict |
|---|---|---|---|---|---|
| 1 | 4 | 10 | Intro paragraph (5 lines of project-owned OT description after H1) | no | OK |
| 2 | 44 | 53 | `## Xcode 26.4 platform features` | **YES (H2 inside)** | DEFECT — wraps H2 header |
| 3 | 69 | 83 | `## Swift coding rules` | **YES (H2 inside)** | DEFECT — wraps H2 header |
| 4 | 87 | 92 | Body of `## Security` | no (H2 stays outside) | OK (but see §2 — empty body remains under pack H2) |
| 5 | 148 | 151 | Bullet 5 of `## Dependency intake policy` | no | OK shape; **see §2 — bullets 1-4 above the marker were also edited from canonical** |
| 6 | 155 | 162 | Body of `## Testing expectations` | no | OK shape; **see §2 — canonical bullets above the marker were entirely deleted from pack-owned territory** |
| 7 | 229 | 233 | "Required first-time setup" paragraph in `## Scripts` | no | OK |
| 8 | 244 | 256 | Body of `## Build and repo hygiene` | no | OK shape (entire body wrapped is a legit choice; prep open-question 4 acknowledges this) |
| 9 | 298 | 335 | `## Anti-patterns — never introduce` | **YES (H2 inside)** | DEFECT — wraps H2 header |
| 10 | 365 | 422 | Phase routing body (3 H3s under one H2) | **YES (3 H3s inside)** | DEFECT — wraps three H3 headers, one of which (`### Custom agents`) is largely Class A pack-controlled (open question 2) |
| 11 | 433 | 436 | Last bullet of `## Agent behavior` | no | OK shape; **see §2 — earlier `Do not invent…` bullet was edited in pack-owned territory** |
| 12 | 440 | 590 | Body of `## Project addenda` (entire OT addenda content through EOF) | no | OK |

### AGENTS.md (575 lines, 12 pairs)

Marker positions: 4/10, 44/53, 68/82, 86/91, 137/140, 144/151, 218/222, 226/238, 283/320, 350/407, 418/421, 425/575.

Same per-pair shape as CLAUDE.md. Same defect set:
- **Pair 2 (44–53)** wraps `## Xcode 26.4 platform features` H2.
- **Pair 3 (68–82)** wraps `## Swift coding rules` H2.
- **Pair 9 (283–320)** wraps `## Anti-patterns — never introduce` H2.
- **Pair 10 (350–407)** wraps `### Tool selection` + `### Agent routing table` + `### Custom agents` H3s.

(AGENTS.md correctly omits the canonical "Wrapper detection" / "format.sh manual-only" sub-paragraphs and correctly retains the AGENTS-only `**BACKLOG write permissions by agent:**` table outside markers — both noted in the prep report and verified.)

### GEMINI.md (617 lines, 12 pairs)

Marker positions: 4/10, 44/53, 68/82, 86/91, 147/150, 154/161, 228/232, 243/255, 297/334, 359/416, 449/452, 467/617.

Same defect set as CLAUDE.md / AGENTS.md (`## Xcode 26.4 platform features`, `## Swift coding rules`, `## Anti-patterns — never introduce`, four phase-routing H3s wrapped inside markers). GEMINI.md correctly leaves the trinity-rule-exception HTML comment + `## Agent roster` + `## Gemini CLI operating notes` sections unwrapped, as the prep report claims.

**Trinity symmetry on marker placement:** confirmed for all 12 marker pairs. The four defective marker pairs are symmetric across the three files (same H2/H3 wrapped in each), so the fix is also symmetric.

---

## 2. Pack-owned content delta vs v10.1 baseline

Method: extracted everything OUTSIDE marker pairs from each OT trinity file
into `/tmp/ot-review/ot-pack-only-{CLAUDE,AGENTS,GEMINI}.md` and ran
`diff -u` against the v10.1 baseline at
`/Users/david/Developer/optiquity-ai-agent-config-pack/project-template/`.

### Class of differences

The diff is dominated by **expected** differences (template scaffolding stripped during the original v9.3 → v10 migration; `[CONDITIONAL]` placeholders replaced with real OT content; HOW-TO-USE comment block removed; `*Copied from: ... v10*` provenance block removed). These are not BD-136 defects — they are pre-existing project-state from the prior migration and are not what the marker pattern is meant to preserve.

### Defects: pack-owned text that was edited outside markers

These are the cases where OT modified prose that, in v11, will be authoritative pack text. On v11 pack update, the marker-aware merger will overwrite each of these with the new pack version, silently losing OT's edit:

**D-1. H1 trailing suffix** (all three files)
- `# CLAUDE.md — OptiquityTrader` (canonical: `# CLAUDE.md`)
- `# AGENTS.md — OptiquityTrader` (canonical: `# AGENTS.md`)
- `# GEMINI.md — OptiquityTrader` (canonical: `# GEMINI.md`)
- The prep report flagged this as Class E and inserted `<!-- TODO: classify H1 customization -->` after each H1. This is the prep report's open question 1.

**D-2. `Do not invent…` bullet in `## Agent behavior`** (all three files)
- OT (CLAUDE.md line 429, AGENTS.md line 414, GEMINI.md line 445):
  `- Do not invent Apple APIs, package capabilities, or build flags.`
- Canonical:
  `- Do not invent APIs, framework behavior, or build flags.`
- This bullet sits OUTSIDE the marker pair (the marker pair only wraps the `For high-risk work…` bullet that OT *added*). The Apple-specific edit is silently in pack territory.

**D-3. `Document any new setup step in README.md.`** (all three files)
- OT wraps the entire `## Build and repo hygiene` body in markers (pair 8), so this case is *not* a defect in CLAUDE.md / AGENTS.md / GEMINI.md after all — verified at lines 246–249 of CLAUDE.md, all OT bullets including the `Document any new setup step` line are inside the marker. **Withdrawn — false positive on initial scan.** Logging here so the user knows it was checked.

**D-4. `Dependency intake policy` bullets 1–4** (all three files)
- OT (CLAUDE.md lines 143–147, AGENTS.md / GEMINI.md analogous):
  ```
  Before adding any third-party package:
  1. Check whether Apple frameworks already solve the problem.
  2. Prefer actively maintained SPM packages with clear licensing.
  3. Evaluate security risk, binary size, lock-in, and long-term maintenance.
  4. Record the rationale, alternatives considered, and exit plan in `ARCHITECTURE.md` or a PR note.
  ```
- Canonical (5 bullets, different wording, generic "platform frameworks" / "the project's standard package manager" phrasing).
- Only bullet 5 (TA-Lib/Tulip/Charts) is wrapped in OT; bullets 1–4 are in pack territory but say something different from canonical. On v11 pack update these 4 lines will be reverted to canonical and OT will lose the Apple-specific phrasing.

**D-5. `Testing expectations` body** (all three files)
- Canonical body (immediately under H2): four bullets ("Add or update tests…", "Use unit tests…", "Use integration tests…", "Use protocol-based test doubles…") plus a `[PLATFORM_TESTING]` placeholder.
- OT: H2 followed immediately by BEGIN marker with 5 OT-specific bullets, no canonical bullets retained.
- This is *deletion* of pack-owned content from the unwrapped territory (the canonical bullets were stripped; the OT bullets are inside the marker, so they *are* preserved). Net result on v11 update: the canonical bullets will *re-appear* above the marker (the marker-aware merger re-adopts them), and OT will end up with 4 canonical bullets + 5 OT bullets stacked together. May be intended; user should confirm.

**D-6. `## Platform and stack defaults` body** (all three files)
- Canonical: single-line placeholder `[PLATFORM_DEFAULTS — fill in per project type]`.
- OT (CLAUDE.md lines 32–42): 8 lines of OT defaults (macOS-only Target, SwiftUI UI, SPM, Swift 6 strict concurrency, etc.).
- This region is **not wrapped** in any marker but is clearly project-owned content. Per the BD-136 spec quoted in BACKLOG.md, "stack defaults" is exactly the kind of content that should live inside markers. On v11 pack update these 8 lines will be reverted to the placeholder.

**D-7. `**Active skills:** apple-architecture-core, …`** line (all three files)
- Canonical: 4-line placeholder block (`[PM chat writes this line during project kickoff…]`).
- OT: single-line filled value.
- This is a Class B pack-template-with-fill-in case — the placeholder is *meant* to be filled in by the PM chat. But the marker pattern doesn't have a "Class B" notion — every byte is either pack-owned or project-owned. If left unwrapped, v11 pack update will revert the OT value to the 4-line placeholder. **This case must be wrapped or BD-136 must explicitly carve out a "fill-in" sub-class.**

**D-8. `## Scripts` table changes** (CLAUDE.md only — needs spot-check on AGENTS/GEMINI)
- Skipped detailed audit because the prep report claims OT's Scripts section largely matches canonical. Spot-check did not surface defects beyond the already-wrapped "Required first-time setup" paragraph (pair 7).

### Summary of pack-owned text deltas

| Defect | Files affected | Bytes silently lost on v11 update | Severity |
|---|---|---|---|
| D-1 (H1 suffix) | all 3 | ~17 chars per file | low — the TODO comment will survive too, so easy to spot |
| D-2 (`Do not invent Apple APIs…` bullet) | all 3 | one bullet line per file | medium |
| D-4 (Dependency intake bullets 1–4) | all 3 | 5 lines per file | high — substantial behavioral guidance |
| D-5 (Testing expectations canonical bullets deleted) | all 3 | 4 lines + 1 placeholder, RE-APPEAR on update | medium — semantic stacking after merge |
| D-6 (Platform and stack defaults body) | all 3 | 8 lines per file | high — core project identity |
| D-7 (Active skills filled-in line) | all 3 | 1 line per file | high — PM chat will need to refill every update |

---

## 3. Defects requiring fix before commit

These are all symmetric across the three trinity files (per the trinity rule the OT prep correctly observes).

### Structural defects (markers wrap headers — violates BD-136 spec)

The BD-136 entry in BACKLOG.md is explicit: "wrap the existing `## Project addenda` H2 body in a seed `<!-- BEGIN project-owned --> ... <!-- END project-owned -->` marker pair (markers around content body only, NOT around the H2 header)." The prep report itself states the same rule. Yet 4 of 12 marker pairs per file violate it.

**S-1.** Pair 2 wraps `## Xcode 26.4 platform features` H2 (CLAUDE.md line 45, AGENTS.md line 45, GEMINI.md line 45 — inside BEGIN at line 44 of each).
- Fix: move BEGIN marker from line 44 to immediately after the H2 (between H2 and the project-owned body).
- Note: the entire H2+body in this section IS project-owned (canonical has it as `## [CONDITIONAL] iOS 26 / Xcode 26.3 platform features`). If the project owns the H2 spelling, the cleanest model is: pack canonical declares the H2 (with whatever name v11 chooses), project body alone goes inside markers. Discussion needed in BD-136 spec on how to handle "section the project entirely owns including the H2 name." The simplest answer is the project edits its H2 outside the marker (Class B-like behavior) and the marker-aware merger flags H2 disagreement as an explicit conflict requiring user reconciliation. **Pack-side decision needed; OT prep should follow whatever BD-136 resolves.**

**S-2.** Pair 3 wraps `## Swift coding rules` H2 (line 70 of CLAUDE.md, etc.). Same fix as S-1. This section has no canonical equivalent at all (v10.1 has `## [CONDITIONAL] Language-specific coding rules` placeholder); v11 may or may not give it a canonical H2. Same H2-ownership question as S-1.

**S-3.** Pair 9 wraps `## Anti-patterns — never introduce` H2 (line 299 of CLAUDE.md, etc.). Canonical is `## [CONDITIONAL] Anti-patterns — never introduce these`. OT has both renamed the H2 (dropped `[CONDITIONAL]`, dropped `these`) AND replaced the body. Same H2-ownership question.

**S-4.** Pair 10 wraps three H3s under `## Phase routing — default agent assignments` (CLAUDE.md lines 366, 386, 412). The H2 is canonical-aligned and stays outside the marker (correct). But:
- `### Tool selection: Claude Code CLI vs Xcode Claude Agent` is a wholly OT-original H3 (no canonical equivalent) — owning it project-side is fine.
- `### Agent routing table` is a renamed/re-bodied version of canonical's body that has no H3 in canonical (canonical has the table directly under the H2). Wrapping it adds an H3 the canonical doesn't have. Acceptable but worth noting.
- `### Custom agents` is **Class A pack-controlled** (the H3 heading and the boilerplate text exist in canonical; only the table rows are project-fill-in). Wrapping the entire H3 inside the marker freezes the Class A scaffolding text on the OT side, so future canonical edits to the boilerplate (e.g., a Procedure 5 reference change) will not propagate to OT.
- Fix: split pair 10 into three smaller pairs, each wrapping body-only of the matching H3. For `### Custom agents` specifically, wrap only the table body (the row "(Developer / PM chat adds rows per project during Procedure 5)" and any project-added rows below it) — leave the H3 heading and the surrounding pack boilerplate text outside markers. This matches the prep report's open question 2 framing; my recommendation is finer-grained wrap is required, not optional.

### Pack-owned text edits (project content sitting in pack territory)

**T-1.** D-2 above — wrap the `Do not invent Apple APIs…` bullet inside markers. Either expand pair 11 upward to swallow it, or split out a new pair (preferred; keeps each pair single-purpose). After fix, pair 11 will become two pairs (or one larger pair), bumping the per-file marker count from 12 to 13.

**T-2.** D-4 above — wrap `Dependency intake policy` bullets 1–4 (and the leading "Before adding any third-party package:" line). Currently only bullet 5 is wrapped (pair 5). Easiest fix: extend pair 5 upward so BEGIN moves to immediately after the H2 (`## Dependency intake policy` line 141), wrapping all 7 lines (header sentence + 5 bullets). This makes the entire body project-owned, which matches the OT pattern of full-body wraps elsewhere.

**T-3.** D-6 above — wrap `## Platform and stack defaults` body (CLAUDE.md lines 34–42, plus matching ranges in AGENTS / GEMINI). Add a NEW marker pair immediately after the H2. This bumps per-file marker count by 1.

**T-4.** D-7 above — wrap the `**Active skills:**` filled-in line. Either add a single-line marker pair (BEGIN before the line, END after) inside `## Skill loading`, or escalate to BD-136 the "fill-in line" sub-pattern. **Recommend single-line marker pair as the minimal fix; flag the broader Class B problem as input to BD-136.**

### After all fixes

Per-file marker count rises from 12 to ~16 (12 existing − 1 for pair-10 split-becomes-3 = 14, + 1 each for T-1/T-2/T-3 = 17, − 1 for T-2 absorption into pair 5 = 16). Approximate; the fix is mechanical and the count is incidental.

---

## 4. Open questions in OT's prep report (V10-TRINITY-MARKER-PREP-REPORT.md §5)

### Q1. H1 classification

> "...leave as-is with the TODO marker, or strip the suffix to match the canonical bare H1?"

**Genuine ambiguity? Partly.** The pack has not yet published a rule for H1 customization in trinity. From the BD-136 spec, the marker pattern is body-only and never wraps H2/H3 — by extension, a project-customized H1 has the same problem as a project-customized H2 (S-1/S-2/S-3 above) and needs the same answer.

**My recommendation:** strip the suffix; H1 stays canonical (`# CLAUDE.md` etc.). The trailing project name adds zero machine-readable signal (PM chat / agents do not parse the H1 to learn the project name; they read the project name from the intro paragraph or `README.md`). Customizing the H1 buys nothing and costs trinity-rule complexity. Remove the `<!-- TODO: classify H1 customization -->` lines after the strip. **Feed back to BD-136:** add to the PM-CHAT.md authoring procedure: "Do not customize the trinity H1; if you want a project-named subtitle, add it to the intro paragraph inside the first marker pair."

### Q2. Phase routing region length

> "...wrap only the `### Tool selection` and `### Agent routing table` subsections, leave `### Custom agents` outside?"

**Answerable now from the BD-136 spec.** The spec says markers wrap content body only, never headers. `### Custom agents` is a pack-owned H3 with pack-owned boilerplate; only its table-rows region is project-fill-in.

**My recommendation:** finer-grained wrap is mandatory, not optional. Split as described in S-4 above. Do not leave the entire phase-routing block as one wrap — that freezes Class A scaffolding (the `### Custom agents` boilerplate and the Procedure 5 references) on the OT side and will produce stale text after future pack updates.

### Q3. Project addenda HTML comment inside wrapped region

> "I included it inside the marker for cleanliness — if v11 prefers it left outside the wrap as Class A scaffolding, the END marker for region 14 would need to move to a position above the H3 sections instead. Confirm preference."

**Genuine ambiguity.** The HTML comment in question is the v9.3 → v10 migration provenance comment ("Project-original H2 sections from v9.3 land under this heading…"). This is an *artifact* of a prior migration step, not pack-owned canonical content per se. v11 will likely replace this comment entirely with a BD-136-aware comment that says "Project addenda go below — see PM-CHAT.md §How to add project-owned content for the procedure" or similar (BACKLOG.md BD-136 §File/Symbol mentions exactly this: "Comment block inside each trinity file's seed `## Project addenda` section pointing to PM-CHAT.md").

**My recommendation:** leave the comment inside the marker for now, but expect v11's marker-aware merger to detect the canonical-comment-replaced-by-different-canonical-comment shape and emit an "outside-marker pack content changed; please reconcile" sidecar at first v11 update. This is acceptable churn for one migration cycle. **Feed back to BD-136:** the spec'd "comment block inside each trinity file's seed `## Project addenda` section" should explicitly NOT live inside the marker pair — keep it outside as Class A pack scaffolding. The OT prep should be re-prepped to leave the equivalent v9.3-era comment outside the marker for symmetry; or, alternatively, accept the one-cycle reconciliation cost.

### Q4. Build and repo hygiene first bullet symmetry

> "I wrapped the entire body as one block (per prep step 10) rather than wrapping only the Xcode-specific bullet plus the extended `BACKLOG.md, README.md` text. If the developer wants finer-grained wraps within this section, say so and I'll split."

**Largely answerable now.** The whole-body wrap is consistent with how OT wrapped Testing expectations and Security. This pattern (when the project has edited > 50% of the body, wrap the entire body) is simple and understandable. The cost is the same as D-5: canonical pack bullets that were deleted will re-appear above the marker on next pack update (because the marker-aware merger re-adopts pack-owned content from canonical).

**My recommendation:** keep the whole-body wrap; do not split. **Feed back to BD-136:** the PM-CHAT.md authoring procedure must explicitly support "whole body wrap" as a first-class choice for sections where the project has heavily edited the body. The procedure should also warn that when the project chooses a whole-body wrap, future canonical body changes will appear *above* the marker on update and the project must either delete them or fold them into the wrapped region — as a first-class merge follow-up.

### Q5. No additional Class A scaffolding gaps detected

> "If v11 introduces new Class A H2s that OT lacks, they will need to be added at v11 install time — not in this prep pass."

**Not a question, a statement; agreed.** This is correct. The marker prep is a pre-migration prep, not a content adoption. v11's migrator will be responsible for adding new pack-owned H2s at install time — and BD-136's marker-aware merger needs to handle the case where a new pack H2 is inserted into pack-owned territory between two existing project-owned marker pairs without disturbing them. **Feed back to BD-136:** add an explicit test case to `scripts/tests/test-customization-preserve-bd136.sh` covering "insert new pack H2 between two project-owned marker pairs."

---

## 5. BD-136 implementation lessons from this prep

These are concrete requirements the BD-136 implementation MUST handle. They are derived from real defects found in OT's prep, not generic considerations.

### For the marker-aware merger (`scripts/lib/marker-preserve.sh` or extension to `customization-preserve.sh`)

**L-1. Marker pair MUST NOT enclose an H2 or H3 line.** The validator (BD-136's new validate-pack.py Check) MUST fail with a clear error if BEGIN immediately precedes (single blank line allowed) a `^## ` or `^### ` line. OT's pairs 2/3/9/10 in each trinity file would have been caught by this check during prep.

**L-2. "Whole-body wrap" is a supported pattern** (project wraps everything between H2 and next H2). The merger MUST handle the case where canonical adds a new bullet at the top of the wrapped section's territory: that new bullet appears *above* the project's marker pair, sitting unwrapped. The merger MUST emit a sidecar / migration warning telling the user "canonical added new pack content above your marker pair under `## <heading>` — review and either delete or fold into your wrap."

**L-3. "Fill-in placeholder" lines are a third class** beyond pack-owned and project-owned. The `**Active skills:**` line, the `[PROJECT_NAME]` placeholder pattern, and the `[PLATFORM_DEFAULTS]` placeholders are ALL Class B "pack provides shape, project fills value." BD-136 must either:
- (a) Require the PM-CHAT authoring procedure to wrap every fill-in value in single-line markers (verbose but uniform); OR
- (b) Add a Class B notion to the marker spec (e.g., `<!-- FILL: skills -->` syntax with default value, persisted across updates).
- The current spec assumes (a) implicitly. **Document this explicitly in the PM-CHAT.md procedure section** — otherwise PM chats will silently leave fill-in values in pack territory and lose them on every update (this is exactly what OT did with `**Active skills:** apple-architecture-core, …`).

**L-4. H2/H3 ownership is asymmetric.** Pack owns H2/H3 names; project owns the body under each. When the project edits an H2 name (as OT did with `## Anti-patterns — never introduce` losing the `[CONDITIONAL]` prefix and `these` suffix), the merger MUST detect the H2 disagreement and emit a sidecar conflict, NOT silently overwrite or silently keep. The validator should also flag this on the pack side: "trinity has an unwrapped H2 that does not match v11 canonical — reconcile before commit."

**L-5. New pack H2 inserted between existing project-owned pairs MUST be additive, not disruptive.** If v11 adds `## Liskov Substitution Principle 2` (hypothetical) between OT's pair 4 (Security body) and pair 5 (Dependency intake bullet 5), the merger MUST insert the new H2 + canonical body in the correct lexical position, leaving both surrounding marker pairs untouched. Test case required.

**L-6. Orphan / unbalanced markers MUST fail loud on the migrator.** The BACKLOG entry already calls this out — confirmed needed. The validator MUST also check (a) BEGIN count == END count, (b) strict alternation, (c) no nesting, (d) BEGIN never on the line immediately following a `^#{1,3} ` heading, (e) END never on the line immediately preceding a `^#{1,3} ` heading (because the heading would then be inside the next pair territory ambiguously). OT's prep is clean on (a)/(b)/(c) but fails (d) on pairs 2/3/9/10 per file.

**L-7. Trinity symmetry on marker placement should be a soft-warn, not a hard-fail.** OT's prep correctly placed all 12 pairs in the same logical positions across CLAUDE/AGENTS/GEMINI. The validator should warn (not block) if a marker pair is present in CLAUDE.md but missing in AGENTS.md/GEMINI.md, since legitimate tool-specific exceptions exist (e.g., GEMINI.md's `## Agent roster` has no CLAUDE/AGENTS analog). Hard-fail would over-constrain.

### For the PM-CHAT.md authoring procedure (BD-136 §File/Symbol bullet 3)

**P-1. "Body only, never around an H2 or H3" must be the first rule, with a concrete bad-example block.** OT's prep author read the rule ("markers NEVER around H2/H3 headers") and then violated it 4 times per file. The procedure must show an explicit anti-pattern block:
```
WRONG:
<!-- BEGIN project-owned -->
## My project section
content
<!-- END project-owned -->

RIGHT:
## My project section
<!-- BEGIN project-owned -->
content
<!-- END project-owned -->
```

**P-2. "Do not edit pack-owned text outside markers" must be enforced by the PM chat itself, not just stated.** OT's prep edited the `Do not invent…` bullet, the `Dependency intake` bullets 1–4, the H1, and the `**Active skills:**` line — all in pack territory. The procedure should instruct the PM chat to: (a) re-read the v11 canonical version of any trinity file before editing, (b) diff the working copy against canonical before any edit, (c) refuse to write edits that fall outside marker pairs unless the user explicitly approves "edit pack-owned text" (which the procedure should re-route as "open a BD against the pack to make the change canonical").

**P-3. Fill-in lines are a known gotcha.** The procedure must explicitly enumerate the fill-in patterns currently in trinity (`**Active skills:**`, `[PROJECT_NAME]`, `[PLATFORM_DEFAULTS]`, `[PLATFORM_TARGETS]`, `[TRANSPORT]`, `[PLATFORM_TESTING]`, `[PLATFORM_ARCHITECTURE]`, `[LANGUAGE_RULES]`, `[GRPC_RULES]`, `[PLATFORM_SECURITY]`, `[PLATFORM_ANTIPATTERNS]`, `[CONDITIONAL]` H2 prefixes) and either tell the PM chat to wrap the fill-in inline (per L-3 option a) or describe Class B handling (per L-3 option b).

**P-4. Whole-body wrap vs. surgical wrap is a deliberate choice.** Document both shapes with examples. OT's open question 4 reflects genuine ambiguity that the procedure should resolve by giving the PM chat a decision rule: "if you need to edit > 50% of the section body, whole-body wrap; else surgical wrap of the specific lines."

**P-5. H2 customization is not supported by the marker pattern.** The procedure must say outright: "If you need to add an H2 the pack does not have, add it under `## Project addenda` (which is one whole-body wrap by design). Do not introduce a new H2 outside the addenda section." OT's `## Xcode 26.4 platform features`, `## Swift coding rules`, and renamed `## Anti-patterns — never introduce` H2s would all violate this rule and need to be relocated under `## Project addenda` or hoisted into the canonical pack via a BD.

### For the validator (BD-136 §File/Symbol bullet `scripts/validate-pack.py` new Check)

**V-1.** Every trinity file in `project-template/` (and any seed under `project-template/docs/pack/`) MUST have well-formed marker pairs: matched count, no nesting, no orphans, BEGIN precedes its END. (Already in BD-136 spec.)

**V-2.** No marker pair may immediately enclose a `^#{1,3} ` heading line (per L-1 / P-1).

**V-3.** No marker may sit inside a fenced code block. Easy lex check: track triple-backtick state line-by-line; emit error if a marker appears with `inside_fence == True`.

**V-4.** The `## Project addenda` H2 must exist in each trinity file and must contain at least one marker pair (the seed pair from BD-136 §File/Symbol bullet 1).

**V-5.** Trinity-symmetry warn (per L-7): emit a warning, not error, if a marker pair count differs across CLAUDE / AGENTS / GEMINI.

### For the migrator dog-food test (`scripts/tests/test-customization-preserve-bd136.sh`)

**M-1.** Round-trip with N=3 marker pairs across distinct H2 anchors (already in spec).

**M-2.** New test: simulate a pack update that inserts a new canonical H2 between two existing project-owned marker pairs. Verify the new H2 lands in the correct lexical position and both project pairs are byte-identical post-migration.

**M-3.** New test: simulate a pack update that adds a new canonical bullet at the top of a section the project has whole-body-wrapped. Verify the merger emits the warning sidecar (per L-2) and the project content is byte-identical.

**M-4.** Negative test: file with marker pair enclosing an H2 line MUST cause migration to fail loud (per L-1 / V-2).

**M-5.** Negative test: file with one orphan BEGIN MUST cause migration to fail loud.

---

## 6. Final recommendation

**Recommendation: OK to commit with edits (listed in §3 above).**

Reasoning:
- The structural mechanics are clean (balanced markers, no nesting, trinity-symmetric placement).
- The defects are all mechanical to fix — 4 marker pairs per file need to be split / shifted, and 4 pack-text regions per file need to be wrapped.
- The prep author's intent is clear and documented in the prep report; the report's own stated rules match the BD-136 spec, so the author understands the pattern.
- The 5 open questions in the prep report map cleanly to BD-136 specification gaps, and resolving them now feeds high-value real-world signal into BD-136 implementation.
- A full re-prep would discard the careful trinity-symmetric placement work the author has already done. The fixes are additive / surgical, not foundational.

**Order of operations recommended:**

1. User reviews this report and confirms the §3 fix list is correct (or amends it).
2. OT PM chat applies §3 fixes in a follow-up edit pass (still pre-commit).
3. OT commits the trinity files with both the prep work and the fixes in one commit (or two, prep-then-fix).
4. The fixed OT trinity files become the reference fixture for BD-136 implementation: `scripts/tests/test-customization-preserve-bd136.sh` should consume them as a real-world golden example.
5. BD-136 implementation incorporates lessons L-1 through L-7, P-1 through P-5, V-1 through V-5, M-1 through M-5.
6. Pack v11 ships with the BD-136 marker-aware merger; OT runs the v10→v11 migration; the trinity files preserve byte-identical OT customization across the migration with no manual reconciliation.

**Alternative (if user disagrees with my read of the H2-wrapping defects):** if the user decides H2 wrapping is acceptable (i.e., BD-136 spec relaxes the body-only-not-header rule), then only the §3 "Pack-owned text edits" group (T-1 through T-4) remain as required fixes, and the verdict moves to "OK to commit with edits — ~6 lines per file rewrap only." The H2-wrapping decision is a BD-136 spec choice the user owns.

---

## 7. Cross-reference integrity check

Files referenced in this report and verified to exist at the cited paths:
- `/Users/david/Developer/OptiquityTrader/CLAUDE.md` (590 lines)
- `/Users/david/Developer/OptiquityTrader/AGENTS.md` (575 lines)
- `/Users/david/Developer/OptiquityTrader/GEMINI.md` (617 lines)
- `/Users/david/Developer/OptiquityTrader/docs/V10-TRINITY-MARKER-PREP-REPORT.md`
- `/Users/david/Developer/optiquity-ai-agent-config-pack/project-template/CLAUDE.md` (389 lines, v10.1 baseline)
- `/Users/david/Developer/optiquity-ai-agent-config-pack/project-template/AGENTS.md` (365 lines, v10.1 baseline)
- `/Users/david/Developer/optiquity-ai-agent-config-pack/project-template/GEMINI.md` (412 lines, v10.1 baseline)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/BACKLOG.md` (BD-136 entry at line 1327)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/docs/pack/PM-CHAT.md` (precedent marker section at lines 627–643)

No edits were made to any of the above files. The only file written by this review is the report itself.
