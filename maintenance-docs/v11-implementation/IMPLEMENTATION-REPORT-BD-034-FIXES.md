# IMPLEMENTATION-REPORT-BD-034-FIXES

Batch 14 of EXECUTION-PLAN-V11.0.md — apply the 4 actionable findings
from `AUDIT-BD-034.md` (F2, F3, F4, F10). F1 ("BD-034 itself can be
Resolved") is a PM-chat status flip, not a code change, and is out
of this report's scope.

## §0 Pre-flight state

- **Branch:** `v11-dev`
- **HEAD at start:** `d059d5f969fdb28545aafc82f8e9dc4f8fbabbbb`
- **HEAD at finish:** `d059d5f969fdb28545aafc82f8e9dc4f8fbabbbb` (no commits — pack-coder never commits)
- **Working tree status (start):** clean except untracked
  `maintenance-docs/v11-implementation/AUDIT-BD-034.md` (the audit
  this batch closes) and untracked v11-research docs (out of scope).
- **Inputs read (read-only):**
  - `maintenance-docs/v11-implementation/AUDIT-BD-034.md`
  - `project-template/skills/audit-methodology/SKILL.md`
  - `project-template/skills/ios-architecture/SKILL.md`
  - `project-template/skills/apple-architecture-core/SKILL.md`
  - `project-template/CLAUDE.md` (Liquid Glass authoritative wording for F4)
  - `BACKLOG.md` (BD-149/BD-155/BD-156/BD-157/BD-158 lookup for F10 phasing)
  - `CLAUDE.md` Pack memory § "Repo conventions" (BD-159 maintainability principle)

---

## §1 Per-fix edit log

### F2 (NIT) — Haptic feedback rule added to `ios-architecture/SKILL.md`

**Target file:** `project-template/skills/ios-architecture/SKILL.md` (single canonical path; not a trinity file)

**Edit:** Inserted new rule 28 in the "Touch-first interaction model" section,
after rule 27 (accessibility labels). The Localization section's existing rules
were renumbered 28→29, 29→30, 30→31, 31→32, 32→33, 33→34 to accommodate.

**Rule 28 wording (verbatim):**

> Haptic feedback accompanies discrete tactile UI events — button confirmation,
> selection change, success / warning / error result. Use
> `UIImpactFeedbackGenerator`, `UISelectionFeedbackGenerator`, and
> `UINotificationFeedbackGenerator` from UIKit; in SwiftUI on iOS 17+ prefer
> the `.sensoryFeedback(_:trigger:)` modifier over manual generator calls. Do
> not fire haptics for non-interactive or background events (animation ticks,
> network polls, view appearance) — that is sensory noise and a battery drain.
> Respect the user's accessibility preferences: check
> `UIAccessibility.isReduceMotionEnabled` (or the
> `\.accessibilityReduceMotion` SwiftUI environment value) and suppress
> non-essential haptics when it is true. Generators must be prepared on the
> main actor; firing from a background thread is a defect.

**Why this placement:** The audit (F2) recommends the rule live in
`ios-architecture` under "Touch-first interaction model" so rule 20's
"every UI rule defined in the loaded platform skills … is in scope"
clause picks it up automatically without bloating audit-methodology.

**Voice match:** Present-tense imperative, names exact API symbols, classifies
the violation shape ("a defect"), parallel to existing rules 23–27.

### F3 (NIT) — Animation correctness rule added to `apple-architecture-core/SKILL.md`

**Target file:** `project-template/skills/apple-architecture-core/SKILL.md` (single canonical path)

**Edit:** Appended a new "Animation correctness" section (rules 28–29) after
the existing "Architecture documentation" section.

**Rule 28 (state-driven animation):**

> Animations are state-driven, not imperative. Bind animation to a SwiftUI
> state change with `withAnimation { … }` (when several state changes should
> animate together) or with `.animation(_, value:)` (when one state change
> drives the animation). Do not reach for `UIView.animate(withDuration:)`
> from SwiftUI code paths; use the imperative UIKit/AppKit animation APIs
> only inside `UIViewRepresentable` / `NSViewRepresentable` wrappers per
> `ios-architecture` rule 12. Snap transitions caused by a missing
> `withAnimation` wrapper around a state mutation are a defect, not a
> stylistic choice.

**Rule 29 (Reduce Motion + auditor-code boundary):**

> Respect Reduce Motion. Read `\.accessibilityReduceMotion` (SwiftUI) or
> `UIAccessibility.isReduceMotionEnabled` (UIKit) and degrade gracefully —
> substitute crossfade for slide / scale, eliminate parallax, disable
> autoplay, drop spring overshoot. Reduce Motion is a correctness
> requirement, not a polish item; ignoring it is a defect. Performance
> anti-patterns (animations on the main thread that block scrolling, layout
> thrash from animating large hierarchies during scroll) are auditor-code's
> lane per `audit-methodology` rule 16; animation *shape* —
> implicit-vs-explicit choice, missing `withAnimation`, missing Reduce
> Motion fallback — is auditor-ui's lane via this rule.

**Why this placement:** Animation correctness applies to both iOS and macOS
SwiftUI code, so it belongs in `apple-architecture-core` (cross-platform
Apple). Audit recommendation (F3 option a) explicitly chose this skill over
ios-architecture. Rule 29 closes the boundary question between auditor-ui
(animation *shape*) and auditor-code (animation *performance*) so a future
auditor doesn't double-file or miss the finding.

### F4 (NIT) — Liquid Glass rule added to `apple-architecture-core/SKILL.md`

**Target file:** `project-template/skills/apple-architecture-core/SKILL.md` (single canonical path)

**Edit:** Appended a new "Liquid Glass design language (iOS 26+ / macOS 26+)"
section (rules 30–31) immediately after the Animation correctness section.

**Rule 30 (use system materials, guard availability):**

> When the project's deployment target supports it, Liquid Glass is the
> platform-correct design language for translucent / vibrant surfaces. Use
> `.glassEffect()` and the system material APIs (`.regularMaterial`,
> `.thinMaterial`, `.ultraThinMaterial`, `.thickMaterial`,
> `.ultraThickMaterial`) rather than reimplementing equivalent surfaces with
> custom `UIVisualEffectView`, ad-hoc blur layers, or hand-painted
> translucent fills. A custom material that duplicates a system surface is
> a defect. All Liquid Glass calls require `#available(iOS 26, *)` /
> `#available(macOS 26, *)` guards per rule 22 when the deployment target is
> below iOS 26 / macOS 26.

**Rule 31 (don't paint solid over translucency; test contrast):**

> Do not paint solid colors or opaque overlays directly on top of a Liquid
> Glass surface — it defeats the design intent (the surface is meant to read
> through to whatever sits behind it). Compose translucency with
> translucency: layered materials and vibrancy effects, not solid fills.
> Test every Liquid Glass surface in both light and dark mode AND with the
> "Increase Contrast" accessibility preference enabled — Liquid Glass
> surfaces can fail contrast guidelines in some configurations, and the
> platform-correct fix is a vibrancy adjustment, not abandoning the
> material.

**Why this placement:** Audit (F4) recommended adding to
`apple-architecture-core` so auditor-ui picks it up via rule 20's platform-skill
clause. The wording quotes the same authority as `project-template/CLAUDE.md`
("use `.glassEffect()` rather than custom Material") and links back to the
existing rule 22 availability-guard requirement, so the design-language rule
and the availability-guard rule reinforce each other.

### F10 (NIT) — Phase-identifier drift fixed in `audit-methodology/SKILL.md`

**Target file:** `project-template/skills/audit-methodology/SKILL.md` (single canonical path)

**Standardized phrase:** "deferred to a future version (currently planned post-v11.0)" — version-relative, doesn't lock to a specific phase number.

**Edit 1 — Rule 20 cross-platform clause (was "Phase 3"):**

Old:
> applies whenever any UI platform skill is loaded — Apple today; web /
> Android / embedded-MCU once those skills land in Phase 3

New:
> applies whenever any UI platform skill is loaded — Apple today; web /
> Android / embedded-MCU once those skills land, deferred to a future
> version, currently planned post-v11.0 — see
> `maintenance-docs/v11-implementation/RESEARCH-NON-APPLE-UI-SKILLS.md`

**Edit 2 — Rule 44 skip-detection clause (was "now in development for v11.0"):**

Old:
> Non-Apple UI detection markers (web, Android, embedded) are added by
> the corresponding platform-architecture skills now in development for
> v11.0 (see `maintenance-docs/v11-implementation/RESEARCH-NON-APPLE-UI-SKILLS.md`
> for the in-flight design); once those skills land, this detection list
> extends to include their markers.

New:
> Non-Apple UI detection markers (web, Android, embedded) are added by
> the corresponding platform-architecture skills, deferred to a future
> version (currently planned post-v11.0 — see
> `maintenance-docs/v11-implementation/RESEARCH-NON-APPLE-UI-SKILLS.md`
> for the in-flight design); once those skills land, this detection list
> extends to include their markers.

**Why this phrasing:** "Phase 3" was load-bearing language that could shift
with development phases. "v11.0" was incorrect because the non-Apple UI
skills are no longer in v11.0 scope — they were deferred. The new wording
is honest (deferred), version-anchored (post-v11.0), and adds the research-
doc reference to rule 20 to match rule 44 (closes the asymmetry the audit
also noted).

---

## §2 Verification

### Validate-pack

Command: `python3 scripts/validate-pack.py`

Result: **PASSED — all checks clean** (31 / 31 checks).

Tail of run:

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

### Trinity-rule check

Skills are NOT trinity files — they have a single canonical path under
`project-template/skills/<name>/SKILL.md`. Confirmed:

- `project-template/skills/ios-architecture/SKILL.md` (only path)
- `project-template/skills/apple-architecture-core/SKILL.md` (only path)
- `project-template/skills/audit-methodology/SKILL.md` (only path)

Trinity rule (per CLAUDE.md / AGENTS.md / GEMINI.md) does not apply here.

### Renumbering integrity (ios-architecture)

Pre-edit rule numbering in ios-architecture SKILL.md:
- Touch-first interaction model: rules 23–27
- Localization: rules 28–33

Post-edit:
- Touch-first interaction model: rules 23–28 (added 28 = haptics)
- Localization: rules 29–34 (renumbered +1)

No external file references the old localization rule numbers (28–33) by
number — the audit-methodology coverage matrix references
`ios-arch r28/r29/r30/r31/r32` for localization concerns, but that matrix
lives in `AUDIT-BD-034.md` which is the audit *of* this fix batch, not a
production reference. Validate-pack does not check rule numbering. No
runtime breakage.

---

## §3 Files touched

| Path | Change | +/- |
|---|---|---|
| `project-template/skills/audit-methodology/SKILL.md` | modified | +2 / -2 |
| `project-template/skills/apple-architecture-core/SKILL.md` | modified | +10 / -0 |
| `project-template/skills/ios-architecture/SKILL.md` | modified | +7 / -6 |

Total: 3 files modified, 19 lines added, 8 lines removed (net +11).

File-count target was ≤10. Actual: 3. Within cap.

No files created. No files deleted.

---

## §4 BD-159 §3.1 mechanical-edit sanity check

Per `CLAUDE.md` Pack memory § "Repo conventions" — the maintainability
principle classifies this batch as mechanical-edit because:

- **0 new files in pack-product scope** (3 modified, 0 created).
- **0 new top-level docs** (the implementation report goes under
  `maintenance-docs/v11-implementation/` per Pattern B workflow-artifact
  exemption).
- **0 new scripts.**
- **0 new validate-pack checks** (validate-pack passes 31/31 unchanged).
- **0 new dimensions / no architecture changes** — added rules slot into
  existing skill sections; F10 rephrases existing forward-references
  without changing their semantic intent.
- **Client `x-` skill contracts preserved** — none of the edits touch
  the dimension contract for any pack-supplied skill, so client `x-`
  derivatives remain conformant.

Verdict: mechanical-edit. No architect/planner pre-pass required.

---

## §5 Plan deviations

None.

---

## §6 New POQs

None. All four findings had clear audit recommendations and the user
pre-approved fixing all of them.

---

## §7 Definition-of-Done checklist

| Item | Status | Evidence |
|---|---|---|
| All 4 fixes (F2, F3, F4, F10) applied | PASS | §1 per-fix edit log |
| `python3 scripts/validate-pack.py` PASS 31/31 | PASS | §2 validate-pack tail |
| Skill files at single canonical path | PASS | §2 trinity-rule check |
| New rules in idiomatic skill voice | PASS | rule wordings in §1 use present-tense imperative, name exact API symbols, classify defect shapes — parallel to existing skill rules |
| No edits outside scope (audit-methodology + ios-architecture + apple-architecture-core) | PASS | §3 files-touched shows exactly the 3 expected files |
| `maintenance-docs/v11-research/` untouched | PASS | not modified |
| `deployment-python/SKILL.md` untouched | PASS | not modified |
| `CLAUDE.md` untouched | PASS | not modified (read-only reference for F4 only) |
| File-count ≤10 | PASS | 3 files modified |
| Implementation report written | PASS | this file |
| BD-159 §3.1 mechanical-edit sanity check | PASS | §4 |
| Pack-coder did not commit | PASS | HEAD unchanged at d059d5f |

---

## §8 Notes for Pack Chat

- F1 disposition is a PM-chat decision (BD-034 status flip). The audit
  closes BD-034 with this batch + BD-143's prior expansion of rule 20
  as the resolution evidence. Recommend flipping BD-034 to `Resolved`
  per the implicit-status-flip-on-batch-completion convention.
- F10's new wording deliberately drops "in development" since the
  non-Apple UI skills were deferred out of v11.0. If post-v11.0 plans
  later rename the deferral target (e.g., to v12.0 explicitly), both
  sentences in audit-methodology will need a one-word touch-up. Captured
  here so the future-version edit isn't missed.
- The renumbering of ios-architecture localization rules (28–33 → 29–34)
  is the only number-shifting change in this batch. No other skill or
  agent file references those rule numbers by number.
