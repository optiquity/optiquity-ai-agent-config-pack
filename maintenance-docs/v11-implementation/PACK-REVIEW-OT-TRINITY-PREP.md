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

---

## Fix Pass 1 — Verification (2026-05-10)

### Verdict

**OK to commit with edits (fix pass 2 list below).** All 9 originally-specified fixes (S-1..S-4, T-1..T-5) are correctly applied across all three trinity files with full trinity symmetry. Marker mechanics are clean (16/16 BEGIN/END per file, balanced, alternating, no nesting, no orphans, no markers inside fenced code blocks, no marker immediately preceding a `^#{1,3} ` heading line). However, fix pass 1 — and the prior §3 fix list — both missed three classes of pack-owned text edits (`H2 renames`, new H3 inserts in `## Phase routing`, and an AGENTS.md-only `## Agent behavior` body restructure) that will silently revert on v11 pack update. These are surfaced below as N-1..N-4 plus a Prior-review gap entry.

The defects below do not invalidate the prep work. They are the same shape as the prior T-N defects (project content in pack territory) and admit the same surgical fixes (rename or wrap). A second commit-blocking pass is warranted because some of these regions are H2/H3 names — Class A territory per BD-136 — and silent revert there is high-impact (whole sections would become misaligned with project content on v11 update).

### Marker accounting (post fix pass 1)

| File         | BEGIN | END | Pairs | Δ vs pre-fix |
|--------------|-------|-----|-------|--------------|
| CLAUDE.md    | 16    | 16  | 16    | +4 (was 12)  |
| AGENTS.md    | 16    | 16  | 16    | +4 (was 12)  |
| GEMINI.md    | 16    | 16  | 16    | +4 (was 12)  |

Matches the prior §3 prediction ("rises from 12 to ~16") exactly.

Mechanic checks (BD-136 V-1, V-2, V-3, L-1, L-6):
- Balanced count: PASS (16=16 per file).
- Strict alternation, no nesting, no orphans: PASS (per-file `awk` BEGIN/END state-machine).
- BEGIN never on the line immediately following an `^#{1,3} ` heading: PASS (zero violations across all three files).
- No marker inside a fenced code block: PASS (zero violations; triple-backtick state tracker reports clean).
- Trinity symmetry on marker placement: PASS — 16 pairs in the same logical positions across CLAUDE / AGENTS / GEMINI.

### Per-fix verdicts

#### S-1 — Pair 2 `## Xcode 26.4 platform features` (BEGIN below H2)

**PASS, all three files.** BEGIN now sits on the line after the H2:
- CLAUDE.md: H2 line 45, BEGIN line 47, END line 55.
- AGENTS.md: H2 line 45, BEGIN line 47, END line 55.
- GEMINI.md: H2 line 45, BEGIN line 47, END line 55.

Body-only wrap. No marker encloses the H2. Trinity-symmetric.

#### S-2 — Pair 3 `## Swift coding rules` (BEGIN below H2)

**PASS, all three files.**
- CLAUDE.md: H2 line 71, BEGIN line 73, END line 85.
- AGENTS.md: H2 line 70, BEGIN line 72, END line 84.
- GEMINI.md: H2 line 70, BEGIN line 72, END line 84.

#### S-3 — Pair 9 H2 renamed back + BEGIN below H2

**PASS, all three files.**
- H2 restored to canonical `## [CONDITIONAL] Anti-patterns — never introduce these` (CLAUDE.md line 302, AGENTS.md line 287, GEMINI.md line 301).
- BEGIN now sits below the H2 (CLAUDE.md line 304, AGENTS.md line 289, GEMINI.md line 303).
- END sits before the next `## Project memory` H2.

#### S-4 — Pair 10 split into per-H3 body-only sub-pairs

**PASS, all three files.** The original single 13-line wrap is now three separate body-only wraps:
- `### Tool selection: Claude Code CLI vs Xcode Claude Agent` — wrapped (CLAUDE.md BEGIN 371 / END 389, AGENTS.md 356/374, GEMINI.md 365/383).
- `### Agent routing table` — wrapped (CLAUDE.md BEGIN 393 / END 417, AGENTS.md 378/402, GEMINI.md 387/411).
- `### Custom agents` — H3 + boilerplate + table left unwrapped (correct per S-4 spec; the project has not yet added any rows, so there is no project content to wrap; canonical already owns the placeholder row).

S-4 sub-note (informational, not a defect): the §3 spec asked for "wrap only the table body (the row '(Developer / PM chat adds rows per project during Procedure 5)' and any project-added rows below it)". OT chose to leave that row unwrapped. This is acceptable today because the row is byte-identical to canonical (so v11 update is a no-op there), but the moment the developer adds a real custom-agent row it MUST go inside a new marker pair under `### Custom agents`. Flag for the BD-136 PM-CHAT.md procedure to call this out explicitly.

#### T-1 — Strip H1 suffix and remove TODO comment

**PASS, all three files.**
- `# CLAUDE.md` (line 1, no suffix, no TODO comment immediately after).
- `# AGENTS.md` (line 1, clean).
- `# GEMINI.md` (line 1, clean).

#### T-2 — Wrap `Do not invent Apple APIs…` bullet

**PASS, all three files.** Single-line marker pair around the OT-edited bullet:
- CLAUDE.md lines 435–437.
- AGENTS.md lines 420–422.
- GEMINI.md lines 451–453.

The surrounding bullets in `## Agent behavior` remain in pack territory (intentional — they match canonical in CLAUDE.md and GEMINI.md). See N-3 below for the AGENTS.md-only complication.

#### T-3 — Extend pair 5 to wrap entire `## Dependency intake policy` body

**PASS, all three files.** BEGIN now sits immediately after the `## Dependency intake policy` H2 and END after bullet 5; the leading "Before adding any third-party package:" sentence and bullets 1–5 are all inside markers:
- CLAUDE.md BEGIN 145 / END 153 (9 lines wrapped).
- AGENTS.md BEGIN 134 / END 142 (9 lines wrapped).
- GEMINI.md BEGIN 144 / END 152 (9 lines wrapped).

#### T-4 — New pair around `## Platform and stack defaults` body

**PASS, all three files.** New marker pair added immediately after the `## Platform and stack defaults` H2:
- CLAUDE.md BEGIN 33 / END 43 (8 OT default bullets wrapped).
- AGENTS.md BEGIN 33 / END 43 (8 OT default bullets wrapped).
- GEMINI.md BEGIN 33 / END 43 (8 OT default bullets wrapped).

Trinity-symmetric line numbers; bodies byte-identical across the three files (confirmed via diff of marker-bracketed regions).

#### T-5 — Single-line pair around `**Active skills:**` line

**PASS, all three files.** Minimal-fix single-line marker pair:
- CLAUDE.md BEGIN 179 / END 181 (one line wrapped).
- AGENTS.md BEGIN 168 / END 170 (one line wrapped).
- GEMINI.md BEGIN 178 / END 180 (one line wrapped).

The Class B "fill-in line" pattern is now preserved across pack updates by the wrap. The broader Class B handling question stays open for BD-136 (per L-3 / P-3).

### Pack-owned-text diff vs v10.1 baseline (post fix pass 1)

Method: extracted everything OUTSIDE marker pairs from each OT trinity file and ran `diff` against `/Users/david/Developer/optiquity-ai-agent-config-pack/project-template/{CLAUDE,AGENTS,GEMINI}.md`.

Expected legitimate scaffolding deltas (already noted in prior §2, all confirmed still present):
- HOW-TO-USE comment block stripped (lines 3–27 baseline).
- `*Copied from: project-template/* — AI Agent Config Pack v10*` provenance block removed.
- `[CONDITIONAL]` placeholder lines (`[PLATFORM_DEFAULTS]`, `[PLATFORM_ARCHITECTURE]`, `[LANGUAGE_RULES]`, `[GRPC_RULES]`, `[PLATFORM_SECURITY]`, `[PLATFORM_TESTING]`, `[PLATFORM_ANTIPATTERNS]`) — all absent (most replaced by wrapped OT content via T-3/T-4/T-5; some H2 sections removed entirely).
- `**[PROJECT_NAME]** targets [PLATFORM_TARGETS]…` placeholder paragraph replaced (the replacement sits inside pair 1 — clean).

Remaining non-scaffolding deltas in pack territory (NEW DEFECTS — see "New defects" below):
- H2 rename: `## [CONDITIONAL] iOS 26 / Xcode 26.3 platform features` → `## Xcode 26.4 platform features`.
- H2 rename: `## [CONDITIONAL] Architecture rules — platform-specific` → `## Swift coding rules`.
- H3 inserts under `## Phase routing — default agent assignments`: `### Tool selection: Claude Code CLI vs Xcode Claude Agent` and `### Agent routing table` (canonical has the table directly under the H2, no H3s).
- AGENTS.md only: `## Agent behavior` body bullets restructured (preamble inserted, bullets reordered/reworded, one canonical bullet `When using a local model, avoid high-risk changes…` deleted).
- D-5 carry-over: `## Testing expectations` canonical bullets remain stripped (the prior review noted "user should confirm" — left as-is in fix pass 1, still pending decision; not a regression).

### New defects introduced or surfaced by fix pass 1

None of the fixes in pass 1 introduced new defects. Marker mechanics, trinity symmetry, and balance are all clean. The defects below were present in OT's pre-fix state but were missed by the prior §3 fix list — they surfaced during this verification's pack-text diff.

#### N-1. H2 rename: `## Xcode 26.4 platform features` (all three files)

- Canonical: `## [CONDITIONAL] iOS 26 / Xcode 26.3 platform features`.
- OT (post-fix): `## Xcode 26.4 platform features` — pack territory edit.
- Severity: **medium**. Per BD-136 L-4, pack owns H2 names; project owns body. On v11 update, the merger will either silently overwrite OT's H2 (losing the macOS-15-target framing) or emit a sidecar conflict. Either way, manual reconciliation is required. The body is wrapped (S-1 PASS), so body content survives — only the H2 spelling drifts.
- Same shape as the original S-3 defect (H2 rename). The prior §3 caught S-3 but missed N-1 and N-2.

#### N-2. H2 rename: `## Swift coding rules` (all three files)

- Canonical: `## [CONDITIONAL] Architecture rules — platform-specific` (followed by a placeholder `[PLATFORM_ARCHITECTURE]`).
- OT (post-fix): `## Swift coding rules` — pack territory edit.
- Severity: **medium**, same logic as N-1.
- Note: the canonical pack does not have a `## Swift coding rules` H2 at all; the closest is `## [CONDITIONAL] Language-specific coding rules` followed by `[LANGUAGE_RULES]`. OT collapsed two canonical H2s (`## [CONDITIONAL] Architecture rules` and `## [CONDITIONAL] Language-specific coding rules`) into a single project-named H2. Either: (a) keep one of the two canonical H2 names and wrap the body project-side, or (b) hoist `## Swift coding rules` into v11 canonical via a separate BD, or (c) move the section under `## Project addenda` per P-5.

#### N-3. AGENTS.md `## Agent behavior` body restructured outside markers

**AGENTS.md only — not present in CLAUDE.md or GEMINI.md.**

- Canonical AGENTS.md (line 350+): 6 bullets in flat list (no preamble).
  ```
  - Plan first for non-trivial work.
  - Read existing code before adding new abstractions.
  - Do not invent APIs, framework behavior, or build flags.
  - Prefer the smallest correct change.
  - State uncertainty explicitly.
  - When using a local model, avoid high-risk changes unless a stronger model has reviewed the plan.
  ```
- OT AGENTS.md (line 415+): preamble `When acting in this repo:` inserted, bullets reordered to match CLAUDE.md / GEMINI.md shape, the `When using a local model…` bullet deleted entirely, two bullets reworded:
  - `Read existing code before adding new abstractions.` → `Read existing code before introducing new patterns.`
  - `Prefer the smallest correct change.` → `Prefer changing the smallest correct surface area.`
  - `State uncertainty explicitly.` → `Call out uncertainty explicitly.`
  - Added: `Match local style when it does not violate these rules.`

This is the most consequential N-finding because it's pack territory in only ONE of three trinity files — a real silent-revert risk on v11 update specifically for AGENTS.md. The intent appears to be "make AGENTS.md mirror CLAUDE.md / GEMINI.md shape," but that's a pack-level decision (whether the trinity should converge on a single shape for `## Agent behavior`) and should be raised as a BD against the pack rather than edited project-side.

Severity: **medium-to-high**. On v11 update, the merger reverts AGENTS.md's `## Agent behavior` body to the canonical 6-bullet flat list, the OT-added `Do not invent Apple APIs…` and `For high-risk work…` markers stay (they're inside their own pairs), but the surrounding pack-owned bullets revert to the AGENTS-canonical wording — leaving a stylistically inconsistent block. CLAUDE.md and GEMINI.md are unaffected because their bodies were already canonical-shaped.

#### N-4. H3 inserts under `## Phase routing` (all three files)

- Canonical `## Phase routing — default agent assignments` body: opening prose paragraph + agent routing table directly under the H2 + `### Custom agents` H3.
- OT (post-fix): two NEW H3s inserted before `### Custom agents`:
  - `### Tool selection: Claude Code CLI vs Xcode Claude Agent` (CLAUDE.md line 369, AGENTS.md line 354, GEMINI.md line 363).
  - `### Agent routing table` (CLAUDE.md line 391, AGENTS.md line 376, GEMINI.md line 385).
- The bodies under each H3 are correctly wrapped (S-4 PASS), but the H3 lines themselves are pack territory.
- Severity: **low-to-medium**. The H3 names are reasonable additions, but per BD-136 L-4 they're pack-owned territory. On v11 update the merger will see two H3s in OT that don't exist in canonical and either drop them (losing the project's body wraps' anchor headings — leaving orphan wrapped bodies under the H2) or sidecar-flag them. The orphan-body case is the one to worry about: if the H3 anchor disappears on update, the wrapped bodies become semantically dangling under the H2 directly.

Recommended treatment per L-4: either (a) hoist the two H3 names into v11 canonical via a separate BD (preferable; the H3 structure is genuinely useful), or (b) wrap each H3+body together as a unit inside markers (degrades to S-4-style "marker around H3" which BD-136 forbids per L-1 / P-1) — option (a) is the only clean path.

#### Prior-review gap

The original §3 fix list correctly identified S-1..S-4 (one whole class of H2-wrap defects) and T-1..T-5 (one class of pack-text-edit defects) but missed:

- **PG-1.** H2-rename defects in unwrapped territory (N-1, N-2). The prior §3 caught the H2-rename in S-3 (Anti-patterns) because that section already had a marker pair to repair, but the same defect class in `## Xcode 26.4 platform features` and `## Swift coding rules` was not flagged because the prior review focused on marker-pair correctness rather than separately auditing every H2-line spelling against canonical.
- **PG-2.** AGENTS.md-only divergences (N-3). The prior review treated the trinity files as symmetric for diff purposes (which they should be) but did not run a per-file pack-text diff against the corresponding per-file canonical baseline. AGENTS.md's canonical has a different `## Agent behavior` shape than CLAUDE.md / GEMINI.md, so OT's CLAUDE-mirroring shape is a defect ONLY in AGENTS.md.
- **PG-3.** New-H3-in-pack-territory defects (N-4). The prior review's S-4 spec correctly split the marker pairs, but did not flag that the H3 anchor lines themselves (`### Tool selection`, `### Agent routing table`) are pack territory.

**BD-136 lessons-learned additions** (extending the L/P/V/M matrix already in the BACKLOG entry):

- **L-8 (merger).** Per-file H2/H3 spelling diff against canonical MUST run as part of marker-aware merge — even when the H2 has a wrapped body. Drift in the heading line itself is a Class A defect that the merger MUST surface as a sidecar. Today's defect class N-1 / N-2 / N-4 would all be caught by this check.
- **P-6 (procedure).** PM-CHAT.md authoring procedure MUST instruct the PM chat to: before any trinity edit, diff the working copy of each trinity file against its OWN per-file canonical (not against a sibling trinity file). Cross-trinity convergence (e.g., making AGENTS.md look like CLAUDE.md) is a pack-level decision that requires a BD against the pack, not a project-side edit.
- **V-6 (validator).** `validate-pack.py` should add a check that every H2 / H3 line in each `project-template/` trinity file is byte-identical to its sibling at the same position OR explicitly marked as tool-specific. Trinity-symmetry on heading text is a hard requirement of the trinity rule.
- **M-6 (test).** `scripts/tests/test-customization-preserve-bd136.sh` should include a test where the project has renamed an H2 outside markers — verify migrator emits sidecar conflict, does NOT silently overwrite project edit, does NOT silently keep project edit either.

### Fix pass 2 list (recommended)

Treat the same way as §3 — symmetric across the trinity unless explicitly marked tool-specific.

- **S-5.** Restore canonical H2 spelling for `## [CONDITIONAL] iOS 26 / Xcode 26.3 platform features` OR confirm v11 will adopt `## Xcode 26.4 platform features` as the new canonical (separate BD against the pack). If keeping OT's spelling is correct, hoist via BD; do not leave the rename in pack territory. Alternative: move the entire section under `## Project addenda` per P-5 (cleaner; loses the canonical anchor but project owns whole subtree). All three files.
- **S-6.** Same treatment for `## Swift coding rules` H2 (canonical: `## [CONDITIONAL] Architecture rules — platform-specific`). All three files. Prefer hoisting to canonical (Swift is the project's primary language; a Swift-named H2 is a sensible v11 canonical addition); fallback is move under `## Project addenda`.
- **S-7.** Same treatment for the two H3 inserts under `## Phase routing` (`### Tool selection`, `### Agent routing table`). All three files. Recommended: hoist both H3 names into v11 canonical (the structure is genuinely useful for projects that want to add Xcode-Agent-style tool-selection guidance); fallback: collapse the wrapped bodies up to live directly under the H2 with no project H3.
- **T-6.** AGENTS.md only — restore the canonical `## Agent behavior` body wording outside markers (re-introduce the deleted `When using a local model, avoid high-risk changes…` bullet, restore the original 6-bullet wording, remove the `When acting in this repo:` preamble, remove the OT-added `Match local style when it does not violate these rules.` bullet). The two existing in-marker pairs (lines 420–422 and 426–429) stay as-is. Trinity is preserved because CLAUDE.md and GEMINI.md keep their existing canonical-aligned bodies; AGENTS.md returns to its own per-file canonical shape.

After S-5..S-7 + T-6, OT's pack-owned text will be byte-clean against v10.1 canonical except for the legitimate scaffolding deltas (HOW-TO-USE strip, `[CONDITIONAL]` placeholder removal where the section was wrapped, *Copied from* removal). The D-5 (Testing expectations canonical bullets stripped) decision remains the user's to make — left out of the fix pass 2 list per the prior §2 note that it "may be intended."

### Read-only confirmation

No files in `/Users/david/Developer/OptiquityTrader/`, `/Users/david/Developer/optiquity-ai-agent-config-pack/`, or `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/` (other than this report) were modified during verification. Only Bash `diff`, `wc`, `grep`, `awk`, and Read calls were used.

---

## Fix Pass 2 — Verification (2026-05-10)

### Verdict

**OK to commit with one optional FP3 edit OR a pack-side spec amendment (operator's choice).**

All 7 FP2 actions correctly applied across all three trinity files with the trinity-asymmetry that FP2-7 Option B explicitly authorizes (AGENTS.md −1 pair vs CLAUDE/GEMINI). Marker mechanics are clean (16/16 BEGIN/END in CLAUDE and GEMINI, 15/15 in AGENTS, all balanced, alternating, no nesting, no markers in fenced code blocks). Self-reported counts (CLAUDE 11A+5B, AGENTS 9A+6B, GEMINI 11A+5B) are confirmed exactly. Pack-area text is now byte-clean against v10.1 canonical (the `<` direction of `diff` is empty for all three files — every delta is a canonical line that was legitimately stripped or moved into a Shape B wrap).

One real residual defect remains:

- **R-1 (Phase routing pack body deleted, partial-pack-content-delete via Shape B sub-section route).** The canonical `## Phase routing — default agent assignments` H2 ships a body (intro paragraph + 12-row routing table + footer paragraph + cost-optimized-routing footnote) that OT's FP2-4 + FP2-5 conversions deleted from pack territory. The two new Shape B H3 wraps (`### Tool selection`, `### Agent routing table`) sit under `## Phase routing` but the H2's own body between the H2 line and the first Shape B BEGIN is now empty. Per BD-136 Description (last paragraph): *"Partial-pack-content-delete (e.g., 'keep canonical Build and repo hygiene mostly, but delete bullet 3') is NOT supported by the Shape A + Shape B model."* On a future pack update the marker-aware merger will see canonical `## Phase routing` body content with no project Shape A pair to merge against; behavior is unspecified but the most likely outcome is the canonical body re-inserts above OT's H3 wraps, yielding two routing tables. Two acceptable FP3 paths: (a) convert `## Phase routing` itself to a single Shape B wrap (pack-overrides via override mechanism, but OT's name happens to byte-match canonical so L-4/V-6 would correctly trigger suppression); (b) keep the FP2 H3-Shape-B structure but file a pack-side BD to hoist `### Tool selection` / `### Agent routing table` as canonical H3 anchors so OT's customizations land as Shape A body wraps under those H3s. R-1 is the same defect class the prior FP1 fix-pass-2 list flagged as S-7 with the same two-path resolution. OT picked the FP2-4/5 conversion-only path; the underlying "what happens to the canonical body" question was not addressed.

Two spec gaps were also surfaced (see "Spec gap" subsection) — both are amendments BD-136 would benefit from before the v11 marker-aware merger lands; neither blocks committing the FP2 work as-is.

### Marker accounting (post FP2)

| File | BEGIN | END | Pairs | Shape A | Shape B | OT-reported (A+B) | Match |
|---|---|---|---|---|---|---|---|
| CLAUDE.md | 16 | 16 | 16 | 11 | 5 | 11A+5B | YES |
| AGENTS.md | 15 | 15 | 15 | 9 | 6 | 9A+6B | YES |
| GEMINI.md | 16 | 16 | 16 | 11 | 5 | 11A+5B | YES |

All three files: BEGIN==END, strictly alternating, no nesting, no markers inside fenced code blocks (verified by awk fence-state tracker).

### Per-pair Shape classification

Notation: pair index | line range | shape | scope.

CLAUDE.md (`/Users/david/Developer/OptiquityTrader/CLAUDE.md`):

| # | Lines | Shape | Scope |
|---|---|---|---|
| 1 | 3–9 | A | Lead paragraphs (project intro) inside pack-area pre-H2 region |
| 2 | 33–43 | A | `## Platform and stack defaults` body bullets |
| 3 | 45–54 | B | `## Xcode 26.4 platform features` (project-renamed from `[CONDITIONAL] iOS 26 / Xcode 26.3`) |
| 4 | 70–84 | B | `## Swift coding rules` (project-renamed from `[CONDITIONAL] Architecture rules — platform-specific`) |
| 5 | 88–93 | A | `## Security` body project bullets |
| 6 | 144–152 | A | `## Dependency intake policy` body project bullets |
| 7 | 156–163 | A | `## Testing expectations` body project bullets |
| 8 | 178–180 | A | `## Skill loading` Active-skills fill-in (T-5) |
| 9 | 232–236 | A | `## Scripts` Required-first-time-setup paragraph |
| 10 | 247–259 | A | `## Build and repo hygiene` body project bullets |
| 11 | 301–338 | B | `## Anti-patterns — never introduce these` (project-renamed body override) |
| 12 | 368–388 | B | `### Tool selection: Claude Code CLI vs Xcode Claude Agent` (project-original H3 under `## Phase routing`) |
| 13 | 390–416 | B | `### Agent routing table` (project-original H3 under `## Phase routing`) |
| 14 | 434–436 | A | Single bullet inside `## Agent behavior` body |
| 15 | 440–443 | A | "For high-risk work…" bullet inside `## Agent behavior` body |
| 16 | 447–597 | A | `## Project addenda` body wrap (BD-136 seed slot) |

AGENTS.md (`/Users/david/Developer/OptiquityTrader/AGENTS.md`):

| # | Lines | Shape | Scope |
|---|---|---|---|
| 1 | 3–9 | A | Lead paragraphs |
| 2 | 33–43 | A | `## Platform and stack defaults` body |
| 3 | 45–54 | B | `## Xcode 26.4 platform features` |
| 4 | 69–83 | B | `## Swift coding rules` |
| 5 | 87–92 | A | `## Security` body |
| 6 | 133–141 | A | `## Dependency intake policy` body |
| 7 | 145–152 | A | `## Testing expectations` body |
| 8 | 167–169 | A | `## Skill loading` Active-skills (T-5) |
| 9 | 221–225 | A | `## Scripts` Required-first-time-setup |
| 10 | 229–241 | A | `## Build and repo hygiene` body |
| 11 | 286–323 | B | `## Anti-patterns — never introduce these` |
| 12 | 353–373 | B | `### Tool selection: Claude Code CLI vs Xcode Claude Agent` |
| 13 | 375–401 | B | `### Agent routing table` |
| 14 | 414–426 | B | `## Agent behavior` (FP2-7 Option B — entire H2+body wrapped as override) |
| 15 | 430–580 | A | `## Project addenda` body wrap |

GEMINI.md (`/Users/david/Developer/OptiquityTrader/GEMINI.md`):

| # | Lines | Shape | Scope |
|---|---|---|---|
| 1 | 3–9 | A | Lead paragraphs |
| 2 | 33–43 | A | `## Platform and stack defaults` body |
| 3 | 45–54 | B | `## Xcode 26.4 platform features` |
| 4 | 69–83 | B | `## Swift coding rules` |
| 5 | 87–92 | A | `## Security` body |
| 6 | 143–151 | A | `## Dependency intake policy` body |
| 7 | 155–162 | A | `## Testing expectations` body |
| 8 | 177–179 | A | `## Skill loading` Active-skills (T-5) |
| 9 | 231–235 | A | `## Scripts` Required-first-time-setup |
| 10 | 246–258 | A | `## Build and repo hygiene` body |
| 11 | 300–337 | B | `## Anti-patterns — never introduce these` |
| 12 | 362–382 | B | `### Tool selection: Claude Code CLI vs Xcode Claude Agent` |
| 13 | 384–410 | B | `### Agent routing table` |
| 14 | 450–452 | A | Single bullet inside `## Agent behavior` body |
| 15 | 456–459 | A | "For high-risk work…" bullet inside `## Agent behavior` body |
| 16 | 474–624 | A | `## Project addenda` body wrap |

Mechanical Shape A / Shape B integrity check (per L-1 / V-2):

- Every Shape A pair body contains zero same-or-higher-depth heading lines (verified per pair via `grep -c '^#\{1,6\} '`). The `## Project addenda` body wrap (Pair 16 / Pair 15 in AGENTS) intentionally encloses 17 H3/H4 sub-headings per file — these are the project-original sections under the BD-136 seed slot, allowed by P-7 only as a fallback (note in spec gap below).
- Every Shape B pair: BEGIN sits on the line immediately preceding the wrapped heading (verified — every Shape B pair's `BEGIN+1` is a `## ` or `### ` line); END lands at the natural section boundary (verified — every Shape B END's `END+2` line is the next same-or-lower-depth heading, never mid-body).

### Per-FP2-action verdicts

**FP2-1 — `## Xcode 26.4 platform features` Shape A → Shape B.** PASS. CLAUDE 45–54, AGENTS 45–54, GEMINI 45–54. BEGIN immediately precedes the H2 line; END lands at blank line before next H2 `## Architecture — universal layer discipline`. Trinity-symmetric (same H2 spelling, same body, same pair lines).

**FP2-2 — `## Swift coding rules` Shape A → Shape B.** PASS. CLAUDE 70–84, AGENTS 69–83, GEMINI 69–83. AGENTS+GEMINI use line 69 (one line earlier) because AGENTS body in `## Architecture — universal layer discipline` and `## Platform and stack defaults` regions trims a section header in canonical (legitimate AGENTS-shorter pattern). End boundary is `## Security` H2. Trinity-symmetric in shape, name, body.

**FP2-3 — `## Anti-patterns — never introduce these` Shape A → Shape B + `[CONDITIONAL]` prefix dropped.** PASS. CLAUDE 301–338, AGENTS 286–323, GEMINI 300–337. H2 spelling is `Anti-patterns — never introduce these` in all three files; canonical is `[CONDITIONAL] Anti-patterns — never introduce these`. Body is OT's elaborated 29-bullet form (genuine project override, not canonical). Note: this is a Shape B with renamed H2, not a name-equality override — see Spec gap S-G-1 below.

**FP2-4 — `### Tool selection` Shape B (was H2-wrap defect S-1 from FP1).** PASS structurally (Shape B mechanics are correct in all three files: CLAUDE 368–388, AGENTS 353–373, GEMINI 362–382; BEGIN immediately precedes the H3, END lands at blank line before sibling H3 `### Agent routing table`). Defect R-1 surfaced separately: this conversion deleted pack-owned `## Phase routing` H2 body that the H3 sat under in canonical.

**FP2-5 — `### Agent routing table` Shape B.** PASS structurally (CLAUDE 390–416, AGENTS 375–401, GEMINI 384–410). END lands at blank line before sibling H3 `### Custom agents`. Same R-1 caveat applies — conversion + deletion of canonical `## Phase routing` H2 body.

**FP2-6 — `### Custom agents` documented no-op (Shape A pack-owned).** PASS. The `### Custom agents` H3 sits in pack territory in all three files (verified — no marker pair encloses it; it sits between the Shape B `### Agent routing table` END and the `## Agent behavior` H2). The intro paragraph, body bullet pointers to `PLATFORM-SKILLS.md`, and the seed table row `(Developer / PM chat adds rows per project during Procedure 5)` are byte-identical to canonical. The FP1 §3 / S-4 informational sub-note (the seed row will need a new Shape A wrap once a real custom agent row is added) still applies as PM-CHAT.md procedure guidance; no FP2 action was required here.

**FP2-7 — AGENTS.md `## Agent behavior` Shape B Option B (whole-H2-and-body wrap; two prior in-marker Shape A pairs removed).** PASS. AGENTS pair 14 = lines 414–426 wraps `## Agent behavior` H2 + body + END at the blank line before `## Project addenda`. Body inside the wrap (lines 415–425): H2 line, the "When acting in this repo:" preamble (this is the OT-only sentence the prior T-6 said to drop or keep — kept inside Shape B is acceptable because Shape B is project-owned in full), the 7 bullets including the OT-added "Match local style…" bullet AND the "When using a local model…" bullet (also kept — same justification: Shape B is project-owned). The two prior in-marker Shape A pairs from FP1 (the single-bullet wrap and the "For high-risk work…" wrap) are GONE from AGENTS.md (verified — pair count dropped from 16 → 15; pair-13 END at 401 is followed immediately by Shape B `## Agent behavior` BEGIN at 414, not by the prior Shape A bullets). CLAUDE.md and GEMINI.md keep `## Agent behavior` as a pack-area H2 with the two intra-section Shape A pairs (CLAUDE 434–436 + 440–443; GEMINI 450–452 + 456–459) — exactly the pre-FP2 trinity-symmetric state for those two files. Trinity asymmetry on this H2 is intentional per FP2-7 and within L-7's soft-warn allowance.

### Override-mechanism check (L-4 / V-6) — duplicate H2 across Shape A and Shape B in same file

Catalog (per file): no H2 name appears in both Shape A territory (pack-area H2 outside markers) AND Shape B territory (H2 inside a Shape B wrap) within the same file.

- CLAUDE.md Shape B H2s: `Xcode 26.4 platform features`, `Swift coding rules`, `Anti-patterns — never introduce these`. None of these appear as a pack-area H2 in CLAUDE.md.
- AGENTS.md Shape B H2s: `Xcode 26.4 platform features`, `Swift coding rules`, `Anti-patterns — never introduce these`, `Agent behavior`. The `Agent behavior` H2 is the FP2-7 Option B override; it does not appear elsewhere in AGENTS.md as a pack-area H2 (the H2 line itself moved INTO the Shape B wrap, leaving zero pack-area `^## Agent behavior` lines). Pass.
- GEMINI.md Shape B H2s: `Xcode 26.4 platform features`, `Swift coding rules`, `Anti-patterns — never introduce these`. None duplicate.

L-4 / V-6: PASS in all three files.

Note: the override mechanism's name-equality contract (per L-4 spec text) is technically NOT triggered for `Anti-patterns — never introduce these` because canonical's H2 is `[CONDITIONAL] Anti-patterns — never introduce these`, a different string. Spec gap S-G-1 below.

### `[CONDITIONAL]` audit (L-9 / V-7)

```
grep -n "\[CONDITIONAL\]" /Users/david/Developer/OptiquityTrader/{CLAUDE,AGENTS,GEMINI}.md
(no output)
```

Zero `[CONDITIONAL]` prefix occurrences anywhere in the three OT trinity files. PASS.

### Pack-owned-text diff vs v10.1 baseline (post FP2)

For each file: stripped every BEGIN/END marker block (markers + enclosed lines) and diffed the residue against `/Users/david/Developer/optiquity-ai-agent-config-pack/project-template/<F>.md`. Result:

- The `<` direction (lines OT has but canonical does not) is **empty** in all three files. This means the pack-area in OT contains zero net additions vs canonical — no project text bleeds into pack territory.
- The `>` direction (lines canonical has but OT does not) is non-empty and consists entirely of legitimate scaffolding strips and Shape-B-absorbed content:
  - HOW-TO-USE comment block at top of file (init-time scaffolding — correct to strip).
  - `*Copied from: project-template/<F>.md — AI Agent Config Pack v10*` block (init-time scaffolding — correct to strip).
  - Inline placeholders `[PROJECT_NAME]`, `[PLATFORM_TARGETS]`, `[TRANSPORT]`, `[PLATFORM_DEFAULTS]`, `[PLATFORM_ARCHITECTURE]`, `[PLATFORM_SECURITY]`, `[PLATFORM_TESTING]`, `[PLATFORM_ANTIPATTERNS]`, `[LANGUAGE_RULES]`, `[GRPC_RULES]` — all resolved (some via Shape B replacement, some by deletion of non-applicable section).
  - `## [CONDITIONAL] iOS 26 / Xcode 26.3 platform features` body — replaced by Shape B `## Xcode 26.4 platform features` (FP2-1).
  - `## [CONDITIONAL] Architecture rules — platform-specific`, `## [CONDITIONAL] Language-specific coding rules`, `## [CONDITIONAL] gRPC and Proto3 rules` — replaced by Shape B `## Swift coding rules` (FP2-2) and intentionally deleted (gRPC/Language not Swift-applicable per OT scope).
  - `## [CONDITIONAL] Anti-patterns — never introduce these` body — replaced by Shape B `## Anti-patterns — never introduce these` with OT's elaborated body (FP2-3).
  - **`## Phase routing — default agent assignments` body** (intro paragraph + 12-row table + footer + cost-optimized footnote) — DELETED from OT pack-area, NOT replaced by any Shape B (the new Shape B sub-sections wrap H3s, not the H2 body itself). This is defect R-1 above.
  - `## Agent behavior` (AGENTS.md only) — body absorbed into Shape B Option B wrap (FP2-7).
  - Project addenda HTML comment block — replaced by OT-tailored variant inside the Shape A body wrap (Q3 from prior FP1 review; allowed because the comment sits inside markers).

Apart from R-1 the pack-area diff is byte-clean against v10.1 canonical. The original review's §3 / FP1's "Pack-owned-text diff" criterion is satisfied (modulo R-1).

### Trinity symmetry (L-7 soft-warn)

- Marker pair count: CLAUDE 16, AGENTS 15, GEMINI 16. AGENTS −1 vs CLAUDE/GEMINI is the FP2-7 Option B consolidation (two Shape A `## Agent behavior` bullet wraps merged into one Shape B whole-H2 wrap). Expected and intentional per L-7.
- All other pair indexes are trinity-symmetric in shape, semantic scope, and (where bodies are not file-specific) byte-content.
- Tool-specific exemptions: GEMINI has its `## Agent roster` and `## Gemini CLI operating notes` H2s with no CLAUDE/AGENTS analog (canonical-shipped, not project-side). These remain pack-area Shape A territory in OT (no markers).
- No unexpected asymmetries detected.

### Marker mechanics (L-6)

- Balanced: `BEGIN` count == `END` count per file. PASS.
- Strict alternation: no `BEGIN` follows another `BEGIN` without an `END` between (verified via line-number sequence — every BEGIN is followed by an END before the next BEGIN). PASS.
- No nesting (corollary of strict alternation). PASS.
- Markers inside fenced code blocks: zero (awk-fence-state tracker scanned all three files — no marker line found while `fence` flag was 1). PASS.

### Class B fill-in placeholder lines (L-3)

Only the T-5 `**Active skills:** ...` wrap was a real fill-in in this trinity (other placeholders like `[PLATFORM_TESTING]` were resolved by Shape B replacement of the enclosing H2). T-5 status post-FP2:

- CLAUDE.md lines 178–180, AGENTS.md lines 167–169, GEMINI.md lines 177–179 — all three files have the wrap intact, single line of body containing `**Active skills:** apple-architecture-core, macos-architecture, deployment-apple, swift-best-practices, dependency-swift, rest-patterns`. Trinity-byte-identical inside the wrap. PASS.

### AGENTS.md FP2-7 Option B specifically

- Shape B pair 14 BEGIN at line 414, immediately precedes `## Agent behavior` at line 415, END at line 426 just before blank line before `## Project addenda` H2 at line 428. Mechanically clean override.
- Body inside the Shape B wrap (lines 415–425) is byte-identical to AGENTS.md's pre-FP2 body for this section (kept the OT-introduced "Match local style…" bullet and the OT-introduced "When acting in this repo:" preamble; did NOT re-introduce the deleted-by-OT canonical `When using a local model…` bullet — see surface note below).
- The two prior in-marker Shape A pairs in AGENTS.md `## Agent behavior` (the single-bullet `Do not invent Apple APIs…` wrap and the `For high-risk work…` wrap) are GONE — pair count dropped 16 → 15. Verified: between pair-13 END at line 401 and pair-14 BEGIN at line 414, lines 402–413 contain only the `### Custom agents` content and the `## Agent behavior` neighbouring text — no marker remnants.
- Surface note (informational, not a defect): the body inside the Shape B wrap retains OT's pre-FP2 deviations from canonical — specifically the missing `When using a local model, avoid high-risk changes…` bullet that canonical AGENTS.md ships at line 365. Because the wrap is Shape B (project-owned override), this is by design and intentional per the override mechanism's contract. The original FP1 T-6 "restore canonical body" recommendation became moot the moment OT chose Option B (Option A would have restored canonical body and kept the two Shape A pairs; Option B accepts the OT-restructured body wholesale as the override). User-facing implication: AGENTS.md `## Agent behavior` will diverge from CLAUDE/GEMINI on every future pack update because Shape B opts AGENTS out of pack-side body refreshes for this section. Acceptable if intentional; flag if not.

### New defects introduced or surfaced by FP2

- **R-1 (above) — `## Phase routing` H2 body deleted from pack area, not replaced.** This is the partial-pack-content-delete BD-136 declares unsupported. Optional FP3 fix paths described above. Severity: real but not migration-blocking — will manifest as a sidecar conflict or a re-inserted duplicate routing table on the first v11 pack update that touches `## Phase routing`. Recommended FP3-R1: convert pair-12 + pair-13 into a single Shape B wrap of `## Phase routing — default agent assignments` (entire H2 + body) — name-equality with canonical triggers L-4/V-6 override, suppresses canonical body, OT keeps its custom intro + Tool selection H3 + routing table H3 sub-structure intact. Trinity-symmetric across all three files. Net pair count changes: CLAUDE/GEMINI 16 → 15 (two Shape B pairs collapse into one); AGENTS 15 → 14.

### Spec gaps (BD-136 amendments to consider)

- **S-G-1.** `[CONDITIONAL]` ↔ Shape B name-equality override. L-4 specifies pure name-equality for the override mechanism. When canonical ships an H2 as `## [CONDITIONAL] X` and the project renames it to `## X` while wrapping in Shape B (which is exactly what L-9 mandates for kept `[CONDITIONAL]` sections at init time), the L-4 override does NOT trigger because the strings differ. The merger therefore needs a fuzzy-match rule: canonical `## [CONDITIONAL] <name>` matches project Shape B `## <name>` for the override-suppression check. Alternatively, the v11 pack canonical drops the `[CONDITIONAL]` prefix entirely from its trinity templates (which V-7 already implies for pack-repo `project-template/` files) — at which point the L-4 strict name-equality is sufficient. Recommend the latter (cleaner; matches V-7 intent). OT FP2 surfaces this gap on three sections per file: `## Anti-patterns — never introduce these` (vs canonical `## [CONDITIONAL] Anti-patterns — never introduce these`), and the equivalent for `## Xcode 26.4 platform features` and `## Swift coding rules` if the v11 canonical retains the `[CONDITIONAL]` prefix on those.
- **S-G-2.** Project addenda H3-dump vs P-7 semantic-anchoring rule. Pair 16 (CLAUDE/GEMINI) / pair 15 (AGENTS) is a single Shape A wrap around `## Project addenda` body containing 17 H3/H4 sub-headings of project-original content. P-7 says "do NOT relocate semantically-anchored project content into a single `## Project addenda` dump — Shape B preserves semantic anchoring at top-level H2." OT inherited this H3-dump shape from a v9.3 → v10 migration sink (per the in-marker comment block). Strict L-1 reading ("no heading inside" Shape A) would also flag this as a defect because the wrap encloses 17 heading lines. Two reasonable BD-136 amendments: (a) carve out an explicit exception in L-1 / V-2 for the `## Project addenda` body wrap — Shape A is allowed to enclose H3+ headings only when the enclosing H2 is `## Project addenda` (the BD-136 seed slot); or (b) tighten the procedure to require migration of every project-original H3/H4 OUT of `## Project addenda` and into top-level Shape B sections. (a) is back-compatible with OT and other v9.3-migrated projects; (b) enforces P-7 strictly but breaks every existing migrated project. Recommend (a) — codify the seed-slot exception explicitly so the validator can implement V-2 unambiguously.

### Trinity-symmetry exception inventory (post FP2)

For the record (none of these are defects; all pre-existing canonical-shipped asymmetries):

- GEMINI.md ships `## Agent roster` (lines ~436–443) and `## Gemini CLI operating notes` (lines ~462–474) — no CLAUDE/AGENTS analog. Pack-area, no markers, byte-identical to canonical.
- AGENTS.md does NOT ship the `### Custom agents` "Five fully-prompted personas" intro paragraph that CLAUDE.md ships — this is a canonical AGENTS-shorter pattern, unchanged by FP2.
- AGENTS.md `## Agent behavior` is now Shape B (FP2-7 Option B) while CLAUDE/GEMINI keep it as pack-area H2 with two intra-section Shape A pairs. Intentional per FP2-7 spec.

### Final verdict

**OK to commit as-is** if the user accepts the R-1 risk for the next pack update (manifests as a sidecar conflict or a duplicate `## Phase routing` body on the first v11 pack refresh that touches that H2). The defect is recoverable post-update.

**OK to commit with one optional FP3 edit** if the user wants R-1 closed pre-commit:

- **FP3-R1.** Convert AGENTS/CLAUDE/GEMINI `## Phase routing — default agent assignments` to a single Shape B whole-H2 wrap (collapse current pair-12 + pair-13 into one Shape B pair around the H2 line + intro paragraph (project-original) + the two H3 sub-sections (project-original) + routing table). Trinity-symmetric. Triggers L-4/V-6 name-equality override (OT name byte-matches canonical), suppresses canonical body on pack updates, OT keeps full project sub-structure. Resulting pair counts: CLAUDE 15, AGENTS 14, GEMINI 15.

The two spec gaps (S-G-1, S-G-2) are amendments to BD-136 itself, not OT-side fixes — they should be folded into the BD before the v11 marker-aware merger lands but do NOT affect whether OT's current FP2 state is committable.

### Read-only confirmation (FP2 verification)

No files in `/Users/david/Developer/OptiquityTrader/`, `/Users/david/Developer/optiquity-ai-agent-config-pack/`, or `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/` (other than this report file) were modified during FP2 verification. Only Bash `diff`, `wc`, `grep`, `awk`, `sed`, and Read calls were used. Confirmed `git status --porcelain` clean in the v10.1 baseline; OT working tree shows the expected pre-existing uncommitted FP2 changes to CLAUDE.md / AGENTS.md / GEMINI.md (these are OT's FP2 work product, not modifications by this verification pass).
