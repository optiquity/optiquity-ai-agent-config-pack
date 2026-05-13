# AUDIT-BD-034 — auditor-ui scope breadth (post-BD-143)

## §0 One-line summary

Rule 20 has expanded substantially since BD-034 was deferred — the original 4-check framing is obsolete; current rule 20 covers 5 signature concerns plus a 4-item cross-platform checklist (9 distinct concerns), with most "missing" traditional UI concerns now either in-scope explicitly or properly delegated to loaded platform skills. Verdict: **CLEAN WITH NITS** — coverage is sound, but a small number of refinements would tighten the rule and remove residual gaps (haptics, animation perf, Liquid Glass) that are not currently named in either rule 20 or any loaded platform skill.

---

## §1 Audit scope and methodology

**BD-034 problem.** Validate whether `auditor-ui` scope is too narrow after the BD-032 split that moved deployment readiness to `auditor-ops`. BACKLOG framed this as a "4-check" scope (view thickness, accessibility, incomplete states, platform conventions). The v11 BD-143 rework extended rule 20 with a cross-platform UI checklist (4 additional concerns) and added a fifth signature category — localization and adaptation. So the rule today is materially broader than the BACKLOG entry assumes.

**Methodology.** Desk audit. The pack repo has no UI layer, so this is a theoretical-rule-clarity evaluation, not an empirical sample. Inputs read:

- `BACKLOG.md` BD-034 entry
- `project-template/skills/audit-methodology/SKILL.md` (rule 20, rule 21, rule 31, rule 44)
- `project-template/.claude/agents/auditor-ui.md`
- `project-template/.codex/agents/auditor-ui.toml`
- `project-template/.gemini/agents/auditor-ui.md`
- `project-template/skills/apple-architecture-core/SKILL.md`
- `project-template/skills/ios-architecture/SKILL.md`
- `project-template/skills/macos-architecture/SKILL.md`
- `project-template/docs/pack/PLATFORM-SKILLS.md` (auditor-ui loading section)

**Cluster discipline.** Findings touching rule 16 (auditor-code), rule 21 (auditor-ops), or PLATFORM-SKILLS python loading are downgraded to OBSERVATION per "stay in your lane" — those are BD-033 / BD-032 / BD-035 lanes.

---

## §2 Rule 20 verbatim (post-BD-143)

From `project-template/skills/audit-methodology/SKILL.md` rule 20:

> **auditor-ui** — UI/UX compliance: applies *every* UI rule defined in the loaded platform skills (`apple-architecture-core`, `ios-architecture`, `macos-architecture`, plus future per-platform skills). The cluster's signature concerns are: (a) view thickness (business logic embedded in views), (b) accessibility (labels, tap targets, keyboard navigation, Dynamic Type, contrast, screen-reader flow including grouping/traits/custom rotors, Reduce Motion, color-only meaning conveyance), (c) incomplete UI states (missing loading / empty / error renders), (d) platform-specific conventions (iOS 26 availability guards, macOS menu bar wiring, orientation/multitasking adaptation, drag-and-drop, system-gesture conflict), (e) localization and adaptation (string-length tolerance for translated labels, RTL layout where the platform supports it, locale-specific date/number/currency formatting, dark-mode / appearance support and contrast in both modes, iPad split-view / Stage Manager / multi-scene multitasking). **Any UI rule defined in a loaded platform skill but not enumerated here is in scope** — the enumeration above is illustrative, not exhaustive. The 4 default headings are the floor, not the ceiling. **Cross-platform UI checklist** (applies whenever any UI platform skill is loaded — Apple today; web / Android / embedded-MCU once those skills land in Phase 3):
>
> - **State source-of-truth** — every piece of visible UI state has one canonical owner; multiple writers to the same state without an explicit reconciliation policy is a defect.
> - **Interactive reachability** — every interactive element is reachable by the platform's primary input modalities (keyboard, pointer / touch, and assistive technology such as screen readers); unreachable controls are a defect.
> - **Externalized strings** — user-facing text is isolated in a localization layer (catalog, resource file, i18n table); hardcoded UI strings outside that layer are a defect.
> - **Layout adapts to translation growth** — layout tolerates ~30–40% string-length expansion (typical for German, Russian, Finnish, etc.) without truncation, overlap, or clipping; fixed-width text containers that cannot expand are a defect.
>
> Skipped for server-only projects that have no UI layer.

**Concern count today.** Five signature categories (a–e), each with multiple sub-bullets, plus four cross-platform checklist items. Total: 9 named concern groups, not 4.

---

## §3 Findings

### Finding F1 — BACKLOG entry stale; "4-check" framing predates BD-143

- **Severity:** NIT
- **Evidence:** `BACKLOG.md` BD-034 lines 2487–2502 still describes auditor-ui as covering "4 specific checks: view thickness, accessibility gaps, incomplete UI states, platform-specific UI conventions" and lists `localization, dark mode, Dynamic Type, iPad split-view, custom gestures` as concerns "a traditional UI audit might expect more". After BD-143, rule 20 explicitly lists all five of those (localization is signature category (e); dark mode and iPad split-view are sub-bullets of (e); Dynamic Type is in (b); gestures are partly in (d) as "system-gesture conflict avoidance").
- **Recommended disposition:** **No change to rule 20 / agent files needed** for this finding. BACKLOG entry can either be re-scoped (to address the residuals captured in F2/F3) or closed-as-resolved-by-BD-143. PM-chat decision.

### Finding F2 — Haptic feedback is uncovered

- **Severity:** NIT
- **Evidence:** Searched all of `audit-methodology`, `apple-architecture-core`, `ios-architecture`, `macos-architecture` for `haptic` — zero matches. Haptic feedback (`UIImpactFeedbackGenerator`, `.sensoryFeedback()` SwiftUI modifier on iOS 17+, watchOS Taptic Engine, macOS trackpad haptics) is a platform UI concern that traditional UI audits would catch (incorrect haptic intensity for the action, missing haptics on confirmation actions, haptics played on a background thread). Rule 20's "applies every UI rule defined in the loaded platform skills" escape hatch does not save the gap because no loaded skill defines a haptic rule.
- **Recommended disposition:** **Add a forward-ref to a platform-specific skill** — i.e., add a haptic feedback rule to `ios-architecture` (and watchOS-architecture if/when it lands) under "Touch-first interaction model"; rule 20 then picks it up via the "every UI rule defined in the loaded platform skills" clause without needing its own enumeration item. This keeps rule 20 stable and pushes platform-specific guidance into the platform skill where it belongs.

### Finding F3 — Animation correctness and reduced-motion-vs-perf nuance is uncovered

- **Severity:** NIT
- **Evidence:** Searched the four files for `animation` — zero matches. Rule 20 (b) names `Reduce Motion` (the accessibility setting), but does not address animation correctness or animation performance: animations that block the main thread, animations that omit `withAnimation { … }` and produce snap transitions, animation duration/curve consistency across the app, animations that trigger layout thrash. Reduce Motion alone is the accessibility opt-out, not the design rule. The platform skills also do not name animation rules.
- **Recommended disposition:** **Refine the boundary between rule 20 and platform-specific UI skills.** Two acceptable resolutions: (a) add an animation-correctness rule to `apple-architecture-core` (since `withAnimation` and `Animation` semantics are SwiftUI-wide, not iOS-only); rule 20 then picks it up via the platform-skill clause. (b) Treat severe animation defects (main-thread block, layout thrash) as `auditor-code` performance anti-patterns per rule 16's "blocking main thread" / "performance anti-patterns" wording. Recommendation: option (a) — keep performance anti-patterns in `auditor-code`'s lane, but UI animation *correctness* (missing `withAnimation`, snap transitions) is a UI-shape concern that belongs to auditor-ui via apple-architecture-core.

### Finding F4 — Liquid Glass / iOS 26 design language not named in rule 20 or any loaded skill

- **Severity:** NIT
- **Evidence:** `project-template/CLAUDE.md` declares Liquid Glass (`.glassEffect()`) as the iOS 26 / macOS 26 default design language and requires availability guards. None of `audit-methodology`, `apple-architecture-core`, `ios-architecture`, `macos-architecture` mentions Liquid Glass. Rule 20 (d) names "iOS 26 availability guards used correctly" which catches the *availability* defect (a Liquid Glass call without `#available(iOS 26, *)`) — but does not catch the *design-language* defect (a custom `Material` / `UIVisualEffectView` reimplementation when `.glassEffect()` would be the platform-correct API). The CLAUDE.md guidance is read by the developer/PM-chat at project setup but is not in any auditor-loadable skill.
- **Recommended disposition:** **Add a forward-ref to a platform-specific skill** — add a "platform-correct material APIs (Liquid Glass on iOS 26+ / macOS 26+)" rule to `apple-architecture-core` so auditor-ui picks it up via the platform-skill clause. Rule 20 itself does not need an enumeration change. This also closes a small drift between CLAUDE.md (which says "use `.glassEffect()` rather than custom Material") and the audit-side skills (which currently have no rule to cite when flagging the violation).

### Finding F5 — Custom-gesture rule is partial — system-gesture conflict named, but custom gesture *design* is not

- **Severity:** OBSERVATION
- **Evidence:** Rule 20 (d) names "system-gesture conflict" (i.e., your custom gesture stomps on edge swipe / control center pull-down). `ios-architecture` rule 26 mirrors that. Neither names the converse: custom gestures that lack a discoverable affordance, gestures with no fallback for assistive technology, gestures that are mandatory (no tap alternative). BACKLOG mentioned "custom gestures" as a possible gap; the system-gesture-conflict bullet partially addresses it. Strict reading: the discoverability/fallback aspect falls through.
- **Recommended disposition:** **No change needed** unless a real audit shows recurring custom-gesture defects. The cross-platform checklist's "Interactive reachability" bullet ("every interactive element is reachable by the platform's primary input modalities… and assistive technology") arguably already covers the gesture-fallback case. Sufficient for now; revisit when the first real iOS audit runs.

### Finding F6 — Internal redundancy between rule 20 (b) and the cross-platform checklist (interactive reachability)

- **Severity:** OBSERVATION
- **Evidence:** Rule 20 (b) lists `tap targets, keyboard navigation` (Apple-specific accessibility). The cross-platform checklist's "Interactive reachability" bullet says "every interactive element is reachable by the platform's primary input modalities (keyboard, pointer / touch, and assistive technology such as screen readers); unreachable controls are a defect." These overlap on iOS (tap targets, keyboard) and macOS (keyboard, pointer). The overlap is not a defect — the cross-platform bullet is the cross-platform abstraction, and (b) is the Apple-specific concrete instance — but the rule does not call out the relationship explicitly. A reader might wonder whether to file a tap-target finding under "(b) accessibility" or under "Interactive reachability".
- **Recommended disposition:** **No change needed.** The relationship is conventional (cross-platform abstraction subsumes platform-specific concretes); the auditor in practice will file the finding once and cite whichever sub-rule names it most directly. Adding text to rule 20 to disambiguate would inflate the rule for marginal benefit.

### Finding F7 — Internal redundancy between rule 20 (e) and the cross-platform checklist (string externalization, layout growth)

- **Severity:** OBSERVATION
- **Evidence:** Rule 20 (e) signature concerns include "string-length tolerance for translated labels". Cross-platform checklist's "Layout adapts to translation growth" bullet says "layout tolerates ~30–40% string-length expansion … fixed-width text containers that cannot expand are a defect." Same concern, two locations. Similarly: (e) localization implies externalized strings; cross-platform checklist names "Externalized strings" explicitly. iOS/macOS architecture skills (rules 28/29 and 29/30) restate both for Apple platforms. Three layers of restatement (rule 20 (e), cross-platform checklist, platform skill) for the same defect.
- **Recommended disposition:** **No change needed.** The intentional design pattern is: rule 20 (e) = signature heading, cross-platform checklist = portable rule, platform skill = concrete tooling. The redundancy is an asset (every reading path lands the rule), not a defect. If a future audit shows confusion, consolidate to a single canonical statement; until then, leave it.

### Finding F8 — Rule 31 file scope is Apple/SwiftUI-only; cross-platform checklist's "Phase 3 web / Android / embedded-MCU" forward-ref has no file-scope counterpart

- **Severity:** OBSERVATION
- **Evidence:** Rule 31 (auditor-ui file scope) lists `**/*View.swift`, `**/*ViewModel.swift`, `**/View/**/*.swift`, "SwiftUI/UIKit/AppKit source files", resource catalogs, localization files, accessibility audit descriptors. No glob for `*.tsx` / `*.jsx` / `*.html` / `*.css` (web), `*.kt` / `**/res/layout/*.xml` (Android), or `*Display.c` / LVGL widget files (embedded-MCU). When Phase 3 platform skills land, rule 31's globs need to extend in lockstep — but the rule does not flag this. Rule 44 (skip rules) explicitly notes "Non-Apple UI detection markers … are added by the corresponding platform-architecture skills now in development for v11.0", so the *skip-detection* side is forward-referenced but the *file-scope-glob* side is silent.
- **Recommended disposition:** **No change needed in BD-034 lane.** This is Phase 3 work; flagging it now would create an artificial dependency. The rule 44 note is sufficient to remind future skill authors that auditor-ui scope expands with each new D1 platform — skill authors will reach rule 31 naturally when they look. If desired, BD-034 follow-up could add a one-sentence note in rule 31 mirroring the rule 44 forward-ref ("File globs extend as new D1 platform skills land — see rule 44").

### Finding F9 — auditor-ui.md "Skills to load" still says "swift-best-practices is also loaded for view code idioms inside UI files" — boundary with auditor-code

- **Severity:** OBSERVATION (cross-cutting — flagged for BD-033 awareness)
- **Evidence:** `project-template/.claude/agents/auditor-ui.md` "Skills to load" section says "The language skill (`swift-best-practices`) is also loaded for view code idioms inside UI files." `audit-methodology` rule 16 puts "language-specific code quality, idiom adherence" in `auditor-code`'s lane. Rule 20's "Out of scope" in the auditor-ui agent file says "Code idioms inside views (Swift style, error handling) — that is `auditor-code`'s scope." So auditor-ui loads `swift-best-practices` but is told not to use it for code idioms. The skill is loaded for the *view-shape* rules inside swift-best-practices (e.g., view body cleanliness, single responsibility), not the language-idiom rules. The wording is defensible but the dual-claim could confuse a future auditor reading the agent file.
- **Recommended disposition:** **Refine the boundary** — clarifying note in the auditor-ui agent file's "Skills to load" section, e.g., "loaded for view-shape and SwiftUI-specific guidance, not for language-idiom enforcement (that is `auditor-code`'s lane)." This is a NIT-grade tightening; deferring is also acceptable since BD-033 may revisit auditor-code/auditor-ui boundary in its own lane.

---

## §4 Coverage matrix

Traditional UI audit concerns × where they land. Concerns are drawn from BACKLOG BD-034 plus the BD-034-task brief expansion (localization, dark mode, Dynamic Type, iPad split-view, custom gestures, animation perf, haptic feedback) and the natural extension set (Liquid Glass, RTL, color-only meaning, screen-reader flow).

| Traditional concern | Rule 20 covers? | Platform skill covers? | Falls through? |
|---|---|---|---|
| Localization (string externalization) | Yes — (e) + cross-platform "Externalized strings" | Yes — ios-arch r28, macos-arch r29 | No |
| Localization (string-length growth) | Yes — (e) + cross-platform "Layout adapts" | Yes — ios-arch r29, macos-arch r30 | No |
| Localization (locale-aware formatting) | Yes — (e) ("locale-specific date/number/currency formatting") | Yes — ios-arch r31, macos-arch r32 | No |
| Localization (translation source-of-truth) | Implied by (e) | Yes — ios-arch r32, macos-arch r33 | No |
| Dark mode / appearance support | Yes — (e) ("dark-mode / appearance support and contrast in both modes") | Not explicit in any platform skill | Partially — rule 20 names it but no concrete platform skill rule |
| Dynamic Type | Yes — (b) ("Dynamic Type") | Yes — ios-arch r24, macos-arch r24 | No |
| iPad split-view / Stage Manager / multi-scene | Yes — (e) | Partial — ios-arch r10 ("iPad supports multiple scenes") names the lifecycle aspect; UI-layout aspect not separately stated | No |
| Custom gestures (system-gesture conflict) | Yes — (d) ("system-gesture conflict") | Yes — ios-arch r26 | No |
| Custom gestures (discoverability / fallback / a11y) | Partial — cross-platform "Interactive reachability" implies it | Not explicit | Partially (see F5) |
| Animation correctness | No | No | **Yes** (see F3) |
| Animation performance | No (auditor-code rule 16 catches "blocking main thread" / perf anti-patterns) | No | Routed to auditor-code (acceptable; documented in F3) |
| Haptic feedback | No | No | **Yes** (see F2) |
| Liquid Glass / iOS 26 design language | Partial — (d) catches availability guard defect; design-language correctness not named | No | Partially (see F4) |
| RTL layout | Yes — (e) ("RTL layout where the platform supports it") | Yes — ios-arch r30, macos-arch r31 | No |
| Color-only meaning conveyance | Yes — (b) | Not explicit in platform skills | No (rule 20 alone is sufficient) |
| Screen-reader flow (grouping / traits / rotors) | Yes — (b) | Partial — ios-arch r27, macos-arch r22–25 (basic VO) | No |
| Reduce Motion | Yes — (b) | Not explicit | No (rule 20 alone is sufficient) |
| Tap target sizing | Yes — (b) ("tap targets") | Yes — ios-arch r23 (44pt) | No |
| Keyboard navigation (macOS) | Yes — (b) | Yes — macos-arch r21 | No |
| State source-of-truth | Yes — cross-platform | Implied by apple-arch-core layer discipline | No |
| Drag-and-drop | Yes — (d) ("drag-and-drop") | Yes — macos-arch r28 | No |
| menu bar wiring (macOS) | Yes — (d) ("macOS menu bar wiring") | Yes — macos-arch r11–14 | No |
| iOS 26 availability guards | Yes — (d) | Yes — apple-arch-core r22 | No |

**Coverage gaps that fall through:** haptic feedback, animation correctness, Liquid Glass design-language correctness. All NIT-grade (per F2/F3/F4).

---

## §5 Trinity discipline check (auditor-ui agent files)

Compared `project-template/.claude/agents/auditor-ui.md`, `project-template/.codex/agents/auditor-ui.toml`, and `project-template/.gemini/agents/auditor-ui.md` for content parity.

| Element | .claude | .codex | .gemini | Parity? |
|---|---|---|---|---|
| Description (frontmatter) | "Audit subagent for UI/UX compliance only — view thickness, accessibility, incomplete states, platform UI conventions. Skipped for server-only projects." | Same prose, modulo `name=` syntax | Identical to .claude | Yes |
| 5 signature concern bullets (view thickness, a11y, incomplete states, platform conventions, localization) | Yes | Yes | Yes | Yes |
| "4 default headings are the floor, not the ceiling" floor/ceiling clause | Yes | Yes | Yes | Yes |
| Out-of-scope list (auditor-ops, auditor-architecture, auditor-code) | Yes | Yes | Yes | Yes |
| File scope quotes rule 31 | Yes | Yes | Yes | Yes |
| Skills-to-load list | Yes — explicit "audit-methodology + platform-arch + swift-best-practices" | Yes — same | Yes — same | Yes |
| Permission profile (read-only + REPORT FILE: exception) | Yes | Yes | Yes | Yes |
| Output policy (REPORT FILE: write directive) | Yes — full block | Yes — same | Yes — same | Yes |
| Hard rules (no state-changing git, chunk long writes, verify, symbol references, pre-flight read, trinity) | Yes — 6 bullets | Yes — 6 bullets | Yes — 6 bullets | Yes |
| Tool-specific frontmatter | `tools: Read, Grep, Glob, Bash, Write, Edit` | `model = "gpt-5"`, `sandbox_mode = "workspace-write"`, etc. | `model: gemini-2.5-pro`, `temperature: 0.2`, `max_turns: 30` | Tool-specific (acceptable per trinity rule's "provably tool-specific" exemption) |

**Verdict:** Trinity discipline is intact. The three files express the same operating rules. Differences are limited to per-tool frontmatter (model, sandbox, tools) — provably tool-specific, exempted by the trinity rule.

**Minor note (sub-NIT):** the .codex `developer_instructions` is a triple-quoted string and the .claude / .gemini are markdown — inevitable due to TOML packaging. Both render identical content to the agent at runtime.

---

## §6 Forward-ref consistency (rule 20 cross-platform sub-bullet vs rule 44)

**Rule 20 cross-platform clause:** "applies whenever any UI platform skill is loaded — Apple today; web / Android / embedded-MCU once those skills land in Phase 3"

**Rule 44 skip-detection clause:** "the current detection list is Apple-centric. Non-Apple UI detection markers (web, Android, embedded) are added by the corresponding platform-architecture skills now in development for v11.0 (see `maintenance-docs/v11-implementation/RESEARCH-NON-APPLE-UI-SKILLS.md` for the in-flight design); once those skills land, this detection list extends to include their markers."

**Consistency check:**

| Aspect | Rule 20 phrasing | Rule 44 phrasing | Consistent? |
|---|---|---|---|
| Phase identifier | "Phase 3" | "v11.0" + "now in development" | Drift — rule 20 says Phase 3, rule 44 says v11.0 |
| Platform list | web / Android / embedded-MCU | web, Android, embedded | Matches (embedded vs embedded-MCU is the same scope; no new platforms in either list) |
| Direction (forward-ref to skills) | Yes — "once those skills land in Phase 3" | Yes — "now in development for v11.0" + research doc reference | Both forward-ref skills; consistent in intent |
| Research-doc reference | None | Yes — `maintenance-docs/v11-implementation/RESEARCH-NON-APPLE-UI-SKILLS.md` | Asymmetric (rule 44 cites the research doc; rule 20 does not) |

**Finding F10 — Phase identifier drift:** rule 20 says "Phase 3" and rule 44 says "v11.0" / "now in development". A reader switching between the two would not know whether "Phase 3" means the v11.0 development phase or some later phase.

- **Severity:** NIT
- **Recommended disposition:** **Refine wording** — pick one identifier (recommend "v11.0" since that aligns with the research doc and the BACKLOG vN versioning convention) and align both rules. The research doc is at `maintenance-docs/v11-implementation/RESEARCH-NON-APPLE-UI-SKILLS.md` per rule 44; rule 20 could optionally cite the same doc but this is not load-bearing.

**Finding F11 — Rule 44 detection markers and rule 20 cross-platform clause are *almost* coupled but not symmetrically:** rule 44 explicitly extends the detection list when new platform skills land. Rule 20's cross-platform checklist explicitly lists which platforms it applies to. If a future skill author adds a platform (e.g., watchOS, visionOS) and updates rule 44's detection markers but forgets rule 20, the cross-platform checklist will silently exclude that platform.

- **Severity:** OBSERVATION
- **Recommended disposition:** **No change needed.** A documented skill-author checklist (when adding a new D1 platform skill, update: rule 20 platform list, rule 31 file globs, rule 44 detection markers, PLATFORM-SKILLS.md auditor-ui dimensional list) would prevent the drift, but BD-034 is not the right vehicle to add it. Capture as a future skill-maintenance follow-up if drift recurs.

---

## §7 Overall verdict

**CLEAN WITH NITS.**

Rule 20 has matured significantly since BD-034 was originally deferred. The post-BD-143 form covers 9 distinct concern groups (5 signature + 4 cross-platform), explicitly defers extra UI rules to loaded platform skills via the "every UI rule defined in the loaded platform skills … is in scope" clause, and successfully accommodates the BACKLOG entry's "missing" examples (localization, dark mode, Dynamic Type, iPad split-view, custom gestures) — all are in-scope today either directly in rule 20 or via the platform skills.

**Real gaps that warrant attention:**

- **F2 (NIT)** — haptic feedback unnamed anywhere; add to ios-architecture.
- **F3 (NIT)** — animation correctness unnamed; add to apple-architecture-core.
- **F4 (NIT)** — Liquid Glass design-language correctness unnamed in audit-loadable skills (CLAUDE.md only); add to apple-architecture-core.
- **F10 (NIT)** — Phase 3 vs v11.0 phase-identifier drift between rule 20 and rule 44.

**Stale-but-resolved:**

- **F1 (NIT)** — BACKLOG entry's "4-check" framing is obsolete. BD-034 itself can either be re-scoped to F2/F3/F4 + F10, or marked Resolved with this audit as the resolution evidence (the rule has materially expanded since the entry was written; the "missing" concerns the entry called out are now in scope).

**Items judged not-worth-fixing:**

- F5 (custom gesture discoverability — sufficient indirect coverage).
- F6, F7 (internal redundancies — intentional layered restatement).
- F8 (rule 31 file-scope forward-ref — Phase 3 follow-up).
- F9 (swift-best-practices loading rationale — boundary clarification, optional).
- F11 (skill-author checklist — separate maintenance follow-up if recurrence observed).

No BLOCKER, no SHOULD-FIX. Trinity discipline is intact. Rule 20 boundaries with auditor-ops (rule 21), auditor-architecture (rule 15), and auditor-code (rule 16) are clean.

