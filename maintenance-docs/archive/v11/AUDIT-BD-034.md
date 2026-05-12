# AUDIT-BD-034 — Auditor-ui scope breadth after ops split

**Verdict:** (b) Findings — fix-follow recommended pre-launch.

The four checks listed in audit-methodology rule 20 (view thickness,
accessibility gaps, incomplete UI states, platform-specific UI
conventions) are sound but read as illustrative rather than
exhaustive. The platform-architecture skills already encode several
UI dimensions that rule 20 does not surface (Dynamic Type at rule
24, 44pt tap target at rule 23, gesture conflict at rule 26,
landscape/orientation at rule 25). The result is a gap between what
the loaded skills can audit and what the cluster scope advertises.
Three small spec edits would close that gap pre-launch by
*re-pointing* rather than *re-listing* — the rule already loads the
skills that contain the missing items, so the fix is making rule 20
say "and everything else in the loaded UI skills" rather than
enumerating four. The BD stays Open with PACK-FEEDBACK Q3 as the
real-validation blocker.

---

## Spec assessment

### audit-methodology rule 20 (auditor-ui scope)

Current text:

> auditor-ui — UI/UX compliance only: view thickness (business logic
> in views), accessibility gaps (missing labels, insufficient tap
> targets, no keyboard navigation, Dynamic Type support), incomplete
> UI states (missing loading, empty, and error states),
> platform-specific UI conventions (iOS 26 availability guards,
> macOS menu bar correctness). Skipped for server-only projects that
> have no UI layer.

Rule 20 collapses several dimensions into one parenthetical
("accessibility gaps") that already mentions tap targets, keyboard
nav, and Dynamic Type — so those *are* covered, contrary to what the
BD's framing question suggests ("are obvious omissions present —
localization, dark mode, Dynamic Type, iPad split-view, custom
gestures?"). Dynamic Type IS mentioned in rule 20. Tap targets ARE
mentioned. Keyboard nav IS mentioned.

What is missing from rule 20's accessibility parenthetical:

- Localization (RTL layout, locale-specific date/number formatting,
  string-length tolerance for translated labels)
- Dark mode / appearance (light/dark/auto, contrast in both modes)
- iPad split-view / multitasking (size class adaptation, scene
  multi-window)
- Custom gestures (conflict with system gestures — covered by
  ios-architecture rule 26 but not surfaced in rule 20)
- Haptic feedback presence/correctness
- Drag-and-drop (covered by macos-architecture rule 28 but not
  surfaced in rule 20)
- Pasteboard / share sheet correctness
- Screen reader (VoiceOver/Switch Control) flow correctness beyond
  labels (e.g., grouping, traits, custom rotors)
- Motion sensitivity (Reduce Motion preference)
- Color-only meaning conveyance (color-blind safety beyond contrast)

### auditor-ui subagent file

`project-template/.claude/agents/auditor-ui.md`, "## Scope" section:

- View thickness — "business logic embedded in views… SwiftUI views
  over ~80 lines or with non-trivial state transitions are
  candidates." (Has a quantified threshold — good.)
- Accessibility gaps — "missing accessibility labels, insufficient
  tap targets (under 44pt on Apple platforms), no keyboard
  navigation support, missing Dynamic Type support, contrast
  violations." (Adds *contrast* beyond rule 20.)
- Incomplete UI states — "missing loading, empty, and error states
  for asynchronous content."
- Platform-specific UI conventions — "iOS 26 availability guards
  used correctly, macOS menu bar wiring, watchOS / tvOS layout
  conventions followed."

Trinity check: same wording in
`project-template/.codex/agents/auditor-ui.toml` and
`project-template/.gemini/agents/auditor-ui.md` per `grep` on
"Accessibility gaps" / "Dynamic Type" / "tap target" — the three
files agree on the four-bullet breakdown.

The subagent file is slightly *richer* than rule 20 (adds contrast).
Both agree on the spine but neither names the dozen items above.

### Loaded skills

Per PLATFORM-SKILLS.md, auditor-ui loads `audit-methodology` plus
platform architecture skills (`apple-architecture-core`,
`ios-architecture`, `macos-architecture`) and `swift-best-practices`.
Spot-check of those skills for UI-dimension coverage:

- `ios-architecture` rule 23 — 44×44pt tap target.
- `ios-architecture` rule 24 — Dynamic Type, no hardcoded font
  sizes.
- `ios-architecture` rule 25 — portrait/landscape support, document
  orientation locks.
- `ios-architecture` rule 26 — no system-gesture conflict.
- `ios-architecture` rule 27 — accessibility labels on every
  interactive element.
- `macos-architecture` rule 24 — Dynamic Type for user-facing text.
- `macos-architecture` rule 28 — drag-and-drop via NSItemProvider /
  SwiftUI .draggable / standard pasteboard types.

So the loaded skills already cover orientation, gesture conflicts,
drag-and-drop, and partial localization implicitly (Dynamic Type +
text styles). They do NOT cover dark mode, RTL, iPad split-view
multitasking, screen reader rotors, Reduce Motion, color-only
meaning, or string-length tolerance.

### Skip rule

Rule 44 says skip auditor-ui "when the project has no UI layer." The
detection list (`*.xcodeproj`, SwiftUI/UIKit/AppKit source files,
`**/*View.swift`) is Apple-centric. For non-Apple UI (web frontends,
Android, etc.) the rule is silent — but the pack today supports only
Apple UI, so this is a v11.x concern not a v11.0 one.

---

## Pre-emptive ambiguities

### Ambiguity 1 — "the four bullets" read as exhaustive

Rule 20's tone is exhaustive ("UI/UX compliance only: A, B, C, D").
A real audit will treat the four as the entire scope and skip
findings that the loaded skills could surface. Worse, the four
bullets *partially* enumerate dimensions that have more under them
in the platform skills (rule 20 says "Dynamic Type" but not
"orientation," yet `ios-architecture` rules 24 and 25 are siblings
in the same section).

### Ambiguity 2 — gap between rule 20 and the loaded skills

The skill file rules listed above (orientation, gesture conflict,
drag-and-drop) are loaded into auditor-ui's context but are not
referenced by rule 20 or the auditor-ui subagent's scope bullets.
Without a "and any other UI rule defined in the loaded platform
skills" sentence, an auditor will narrow to the four named bullets
and miss the rest.

### Ambiguity 3 — rule 20 lists items the *subagent file* expands

Rule 20 lists four headings; the subagent file adds "contrast
violations" silently. This is a minor trinity drift between the
authority document (audit-methodology) and the subagent files
(which `## Output` says lose to audit-methodology when they
disagree). Fixing rule 20 to subsume the subagent's expansions —
not the other way around — is the right direction.

### Ambiguity 4 — "platform-specific UI conventions" is a bag

The fourth bullet ("platform-specific UI conventions") is the
shoehorn for everything else. iOS 26 availability guards, macOS
menu bar wiring, watchOS/tvOS layout — these are unrelated. A real
audit would benefit from the bullet being expanded into a "and any
rule with the platform-conventions tag in the loaded
platform-architecture skill" pointer.

### Ambiguity 5 — localization is genuinely missing

Localization (RTL flow, string-length tolerance for translated
text, locale-specific date/number formatting) is not in any of the
four rule-20 bullets *or* in `ios-architecture` /
`macos-architecture` / `apple-architecture-core` (a quick `grep`
confirms — `localiz` returned no skill content). For a project
shipping non-English locales this would be a real gap. This is the
strongest "actually missing" item, not just a "not surfaced" item.

---

## Recommended tightenings

### Edit 1 — make rule 20 a re-pointer, not an enumeration

`project-template/skills/audit-methodology/SKILL.md`, rule 20.
Replace current text with:

> auditor-ui — UI/UX compliance: applies every UI rule in the
> loaded platform skills (`apple-architecture-core`,
> `ios-architecture`, `macos-architecture`, plus future
> per-platform skills). The cluster's signature concerns are:
> (a) view thickness (business logic embedded in views), (b)
> accessibility (labels, tap targets, keyboard navigation, Dynamic
> Type, contrast, screen-reader flow, Reduce Motion), (c)
> incomplete UI states (missing loading / empty / error renders),
> (d) platform-specific conventions (iOS 26 availability guards,
> macOS menu bar wiring, orientation/multitasking adaptation,
> drag-and-drop, system-gesture conflict). Any UI rule defined in
> the loaded platform skill but not enumerated here is in scope —
> the enumeration is illustrative, not exhaustive. Skipped for
> server-only projects that have no UI layer.

### Edit 2 — mirror the same expansion into the auditor-ui files

Trinity-edit `project-template/.claude/agents/auditor-ui.md`,
`project-template/.codex/agents/auditor-ui.toml`, and
`project-template/.gemini/agents/auditor-ui.md`:

- Expand "Accessibility gaps" bullet to add: screen-reader flow
  (grouping, traits, custom rotors), Reduce Motion preference,
  color-only meaning conveyance.
- Add a fifth bullet:
  > **Localization and adaptation** — string-length tolerance for
  > translated labels, RTL layout where the platform supports it,
  > locale-specific date/number/currency formatting, dark-mode /
  > appearance support and contrast in both modes, iPad split-view
  > / Stage Manager / multi-scene multitasking adaptation.
- Add a closing sentence:
  > Beyond the bullets above, every UI rule in the loaded platform
  > skill is in scope. This list is illustrative; if a loaded skill
  > defines a UI rule not listed here, audit it.

### Edit 3 — add localization rules to platform skills

`project-template/skills/ios-architecture/SKILL.md` and
`project-template/skills/macos-architecture/SKILL.md` — add a
Localization section with rules covering:

- String externalization (`String(localized:)` / `.strings` /
  `.xcstrings` Catalog).
- Pseudolocalization or 30%-length tolerance for layout.
- RTL semantic layout (leading/trailing instead of left/right).
- Locale-aware formatters (`Date.FormatStyle`,
  `Decimal.FormatStyle`).
- Dark mode token usage (`Color(.systemBackground)` over hex; asset
  catalog appearance variants).

This is a meaningful skill addition (not a documentation tweak) and
might warrant its own BD if it is too broad to fold into BD-034's
fix-follow. Marking it called out here for visibility.

### Edit 4 — add a brief skip-rule note for non-Apple UI

`project-template/skills/audit-methodology/SKILL.md`, rule 44,
append a sentence:

> The detection list is Apple-centric. Future non-Apple UI
> projects (web, Android, embedded) need an equivalent detection
> rule before auditor-ui can skip correctly.

Defer the actual non-Apple detection to v11.x — this sentence is a
bookmark, not a feature.

---

## Trinity check

| File | Claude | Codex | Gemini | Agreement |
|---|---|---|---|---|
| auditor-ui scope bullets | view thickness / accessibility / incomplete states / platform conventions | identical bullets | identical bullets | aligned |
| Tap target threshold (44pt) | yes | yes | yes | aligned |
| Dynamic Type mention | yes | yes | yes | aligned |
| Contrast violation mention | yes (subagent only) | yes (subagent only) | yes (subagent only) | aligned but inconsistent with rule 20 |

Trinity is intact for the *current* wording. All Edit 2 changes
must apply to all three files in the same commit. Edit 3 and Edit 4
are skill-file / methodology-file changes (single-source) and do
not require trinity coordination.

---

## Why the BD stays Open

BD-034's blocker — "First v9 project with substantial UI runs a
full audit (PACK-FEEDBACK.md Q3)" — is the real validation: do the
expanded bullets produce useful findings without drowning the audit
in noise? The pre-emptive tightenings widen the scope conservatively
(re-pointing to loaded skills, naming localization explicitly), but
calibration of *severity* and *threshold per UI dimension* requires
real-audit data.

If the recommended tightenings are accepted, log a fix-follow note
in BD-034's Context block: "v11.0 expanded rule 20 from 4 bullets
to a re-pointer with 5 enumerated dimensions; added localization
rules to ios-architecture and macos-architecture; real-world scope
validation still pending."
