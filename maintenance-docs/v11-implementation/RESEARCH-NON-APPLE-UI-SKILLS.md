# RESEARCH — Non-Apple UI Platform Skills (Web / Android / Embedded)

**Phase:** 1 of 3 (research) — feeds pack-architect (Phase 2) and
pack-coder (Phase 3).
**Scope:** propose audit-relevant rules for three new skills:
`web-architecture`, `android-architecture`, `embedded-architecture`.
**Constraint:** read-only; this report is the only file created.

---

## 1. Calibration baseline — Apple platform-skill shape

The three new skills must match the existing Apple platform-skill style
so `auditor-ui` can apply them with the same cadence and confidence.

### Shape summary (from `apple-architecture-core`, `ios-architecture`, `macos-architecture`)

| Skill | Rule count | Section count | Tone |
|---|---|---|---|
| `apple-architecture-core` | 27 | 9 | terse imperatives, "must / never" framing |
| `ios-architecture` | 33 (after BD-034 fix-follow) | 7 | identical voice; 6 Localization rules at the tail |
| `macos-architecture` | 34 (after BD-034 fix-follow) | 8 | identical voice; 6 Localization rules at the tail |

### Frontmatter contract

```
---
name: <skill-name>
description: Use for <trigger condition> — <list of concerns>.
allowed-tools: Read, Grep, Glob, Bash
---
```

### Section conventions

- Numbered rules (1, 2, 3…) flowing across sections — numbering does
  NOT restart per section. The reviewer / auditor cites rules by number.
- Each rule is one sentence (occasionally two), declarative, in the
  imperative mood. Examples: "SwiftUI is the default UI framework."
  "Background tasks must be idempotent."
- Sections have H2 headers (`## Title`). No H3 inside sections.
- Rationale is implicit in the rule wording. No paragraphs of
  explanation between rules; if explanation is needed, the rule itself
  carries it inline.
- Localization is the final section in `ios-architecture` and
  `macos-architecture`, comprising 6 rules covering:
  externalization (1) → expansion tolerance (2) → semantic
  layout / RTL (3) → locale-aware formatters (4) → translation
  source-of-truth (5) → testing under RTL + long-string locale (6).

### What to mirror in the three new skills

- Same frontmatter, same allowed-tools.
- Numbered rules flowing across sections.
- 5-15 rules per skill (per the task), targeting roughly the same
  density as ios-architecture (33 rules across 7 sections ≈ 4-5
  rules/section).
- A Localization section as the final section, with the same 6-rule
  arc translated to platform idioms.
- Imperative voice, no rationale paragraphs.

---

## 2. `web-architecture` — Web / browser UI

### Detection markers (for `PLATFORM-SKILLS.md`)

The skill should load when **any** of these are true:

- `package.json` exists AND `dependencies` or `devDependencies`
  contains any of: `react`, `react-dom`, `vue`, `@vue/runtime-core`,
  `@angular/core`, `svelte`, `@sveltejs/kit`, `next`, `nuxt`,
  `solid-js`, `preact`.
- Top-level `index.html` exists alongside a `src/` directory and any
  of `vite.config.{js,ts}`, `webpack.config.{js,cjs,mjs,ts}`,
  `next.config.{js,mjs,ts}`, `nuxt.config.{js,ts}`,
  `svelte.config.js`, `angular.json`, `astro.config.{js,mjs,ts}`.
- A `tsconfig.json` whose `compilerOptions.jsx` is set to `react`,
  `react-jsx`, `react-jsxdev`, or `preserve`.

The skill is a single file targeting the browser DOM execution model;
framework-specific rules are gated by sub-conditions inside the rules
("React projects: …", "Vue projects: …") rather than separate skills.
This keeps the skill count manageable and matches how
`apple-architecture-core` covers SwiftUI + UIKit + AppKit together.

### Recommended audit-relevant rules (12)

**Component model and state**
1. Treat user-visible state as derived from a single source of truth.
   Storing the same value in two places (e.g., a prop and a `useState`
   initialized from that prop) without a synchronization contract is
   a defect — when the source updates, the duplicate goes stale.
2. (React) Every `useEffect` declares every reactive value it reads in
   the dependency array. Suppressing the `react-hooks/exhaustive-deps`
   lint without a code comment explaining why is a finding.
3. (React) Lists rendered with `.map()` use a stable, data-derived
   `key` prop. Array index is acceptable only when items are never
   reordered, inserted, or removed; `key={Math.random()}` and similar
   regeneration patterns are defects (state and DOM identity are lost).
4. (Vue 3) Component props are accessed as `props.x` and not
   destructured at definition; destructuring loses reactivity. State
   exposed across template / script blocks uses `ref` for primitives
   and top-level state, `reactive` only for objects with stable
   identity, and never both for the same logical value.
5. (Angular) New components declare `changeDetection:
   ChangeDetectionStrategy.OnPush` unless they specifically require
   default checking. Mixing default and OnPush in a parent/child pair
   without justification is a finding.
6. (Svelte) External event sources (WebSocket, IntersectionObserver,
   MediaQuery) are bridged into reactivity via `createSubscriber` or
   a store with an explicit teardown — never via untracked
   subscriptions in a `<script>` block.

**Server-side rendering and hydration**
7. (SSR — React/Next.js, Nuxt, SvelteKit) Components rendered on the
   server produce byte-equivalent output on the first client render.
   `Date.now()`, `Math.random()`, `typeof window`, `localStorage`, and
   user-locale-derived values in the initial render path are
   hydration-mismatch sources; gate them behind a post-mount effect or
   render the same placeholder on both sides.
8. (React) `Suspense` boundaries are placed at the granularity of the
   loading sequence the user should perceive — not wrapped around
   every async leaf, and not absent above any component that uses
   `use()` on a promise. Each `Suspense` boundary has a corresponding
   error boundary above it, so a fetch failure does not cascade to a
   blank page.

**Accessibility**
9. Every interactive element is a native interactive element
   (`<button>`, `<a href>`, `<input>`, `<select>`) unless a documented
   reason requires a custom widget. Custom widgets carry the correct
   ARIA role, `aria-label` or `aria-labelledby`, and full keyboard
   support (Enter / Space / arrow keys per the WAI-ARIA pattern).
10. Modal dialogs are implemented via `<dialog>` (preferred) or with
    `role="dialog"` + `aria-modal="true"` + an inert / `aria-hidden`
    treatment of the rest of the page. Focus moves into the dialog on
    open, is trapped within the dialog while open, and returns to the
    triggering element on close.

**Performance and visual stability**
11. `<img>` and `<video>` elements declare `width` and `height`
    attributes (or equivalent CSS aspect-ratio) so the browser can
    reserve layout space — preventing Cumulative Layout Shift.
    Above-the-fold images critical to LCP are NOT marked `loading="lazy"`;
    below-the-fold images may be.
12. Web fonts use `font-display: swap` (or `optional`) and preload the
    first-paint font. Layout-affecting fonts loaded without these
    measures cause CLS or FOIT (flash of invisible text) on slow
    connections.

### Localization rules (6 — final section)

13. Externalize every user-visible string. Use a documented i18n
    library appropriate to the framework (`react-intl`/`react-i18next`
    for React, `vue-i18n` for Vue 3, Angular's built-in `@angular/localize`,
    `svelte-i18n` for Svelte) with all strings keyed in a translation
    catalog under version control. Hardcoded user-facing literals in
    JSX / templates / `aria-label` attributes are findings.
14. Tolerate translated string-length growth — design layouts and
    constraints for at least 30% expansion. Use CSS `min-content` /
    `max-content` / flex-wrap rather than fixed widths for buttons,
    nav items, and headings; pseudolocalize during development.
15. Use CSS logical properties (`margin-inline-start`,
    `padding-inline-end`, `inset-inline-start`, `border-inline-end`)
    instead of left / right physical properties for any margin,
    padding, border, or positioning that should mirror under RTL. The
    document root carries `<html lang="<bcp47>" dir="ltr|rtl">`,
    populated dynamically when the user changes locale.
16. Format dates, times, numbers, currencies, lists, and relative
    times via `Intl.DateTimeFormat`, `Intl.NumberFormat`,
    `Intl.ListFormat`, and `Intl.RelativeTimeFormat` (or framework
    wrappers around them). Never concatenate locale-sensitive
    substrings by hand. Use `<time datetime="…">` for machine-readable
    timestamps.
17. Maintain a single source of truth for translations — the
    catalog file(s) under version control with a documented translator
    workflow. Empty translation values, stale keys, untranslated
    languages, and translation files diverging from the source
    catalog are findings.
18. Test under at least one RTL locale (Arabic or Hebrew) and one
    long-string locale (German or Finnish) before release. Snapshot
    or visual-regression tests cover both directions for any
    user-facing surface.

### Out-of-scope (considered, excluded)

- 2-space-vs-4-space indent and similar formatting (tooling, not
  audit).
- Specific bundler configuration (Vite vs Webpack vs Turbopack) —
  changes faster than the skill could keep up.
- CSS-in-JS vs CSS-modules choice — team preference, not defect.
- TanStack Query / SWR / RTK Query selection — addressed by general
  data-layer rules in the existing universal layer-discipline section.
- "Use functional components instead of class components" — class
  components are valid; the audit-relevant defects (stale state,
  missing dep arrays) cover both forms via the same rules.
- Specific SSR framework (Next vs Remix vs Nuxt vs SvelteKit) —
  hydration rule covers the cross-cutting concern; framework-specific
  routing is out of scope for a UI architecture skill.

---

## 3. `android-architecture` — Android UI

### Detection markers (for `PLATFORM-SKILLS.md`)

The skill should load when **any** of these are true:

- A `*.gradle` or `*.gradle.kts` file (any depth) contains
  `com.android.application` or `com.android.library` plugin
  application.
- A `settings.gradle` / `settings.gradle.kts` includes a module whose
  build script applies an Android plugin.
- An `AndroidManifest.xml` exists at any depth.
- A `build.gradle.kts` declares `androidx.compose` runtime / UI
  dependencies (Compose-only library projects without an
  `AndroidManifest.xml`).

### Recommended audit-relevant rules (13)

**Compose state and recomposition**
1. State that survives recomposition is held in `remember { … }` (or
   `rememberSaveable` for state that must survive process death and
   configuration change). Allocating new mutable objects in the
   composable body without `remember` re-creates them on every
   recomposition and silently drops state.
2. Hoist state to the lowest common ancestor of its readers and
   writers. A composable that does not need to mutate state takes the
   value as a parameter and an `onChange: (T) -> Unit` callback —
   never an `MutableState<T>` directly. State hoisted higher than its
   readers wastes recomposition; state hoisted lower than its writers
   creates duplicate sources of truth.
3. Use `derivedStateOf` only when the inputs change more frequently
   than the derived value (e.g., scroll position → "is at top"
   boolean). Wrapping a derivation whose inputs change at the same
   rate as the output adds overhead with no benefit.
4. Never write to a `State<T>` that has already been read in the same
   composition pass — backwards writes cause endless recomposition at
   frame rate. Reads inside `LaunchedEffect` / `SideEffect` /
   `DisposableEffect` are not "in the composition" for this purpose.
5. Side effects use the right API: `LaunchedEffect(key)` for work
   tied to the composition lifecycle that suspends; `SideEffect` for
   non-suspend work to publish state to non-Compose code;
   `DisposableEffect` when cleanup is required;
   `rememberCoroutineScope()` for scopes launched from event handlers
   (button clicks). `scope.launch { … }` directly in the composable
   body without `rememberCoroutineScope` is a defect.
6. Stable inputs to composables are `@Stable` or `@Immutable` (or
   primitive / String / function references). Passing a `var`-bearing
   data class or a collection from `kotlin.collections` (mutable
   `List<T>`) to a composable defeats skipping and forces
   recomposition on every parent change. Use
   `kotlinx.collections.immutable` types or explicit `@Immutable`
   data classes.

**Modifier discipline**
7. `Modifier` parameters are accepted by every reusable composable as
   the first optional parameter (named `modifier: Modifier =
   Modifier`) and applied to the outermost layout node. Custom
   composables that swallow caller-supplied `modifier` are a finding.
8. `Modifier` ordering is semantic, not decorative. `Modifier.padding`
   applied before `.background` puts the background outside the
   padding; applied after, inside. Visual defects arising from
   reversed modifier order are common; auditors flag any modifier
   chain whose ordering does not match the composable's documented
   intent (or, when undocumented, the visually-correct intent).

**View-system and lifecycle (for legacy / mixed projects)**
9. View-system fragments use ViewBinding (or DataBinding); raw
   `findViewById` calls in new code are findings. The binding is
   nulled in `onDestroyView()` to avoid leaking the inflated view
   hierarchy across the fragment-vs-fragment-view lifecycle gap.
10. State that must survive configuration change lives in a
    `ViewModel`, not the Activity / Fragment. Manual rotation handling
    via `android:configChanges` requires documented justification —
    it is an opt-out from the framework's standard recreate-on-change
    contract.

**Accessibility and resource correctness**
11. Every interactive `View` and clickable / focusable composable
    carries a non-empty `contentDescription` (or
    `Modifier.semantics { contentDescription = "…" }`) describing the
    *action*, not the visual ("Submit", not "Submit button"). Decorative
    images set `contentDescription = null` (or `null` in semantics) so
    TalkBack skips them.
12. Use density-independent units (`dp` for sizes, `sp` for text)
    everywhere user-facing. Hardcoded `px` values in layout XML or
    Compose modifiers are findings (except in custom `Canvas` drawing
    where the unit is intentional).
13. Use Material components for tap targets — they default to 48dp
    minimum. Custom `Modifier.size()` smaller than 48dp on a
    clickable composable is a finding (Android accessibility
    requirement is 48×48dp minimum).

### Localization rules (6 — final section)

14. Externalize every user-visible string into
    `res/values/strings.xml` (and `res/values-<locale>/strings.xml`
    overrides). Hardcoded literals in XML `android:text`, Compose
    `Text("…")`, `setText("…")`, `contentDescription`, and toast /
    snackbar messages are findings. Use `getString(R.string.key,
    formatArgs…)` — never string concatenation of localized
    fragments.
15. Tolerate translated string-length growth — design layouts for at
    least 30% expansion. `ConstraintLayout` chains, `Modifier.weight`,
    and `wrap_content` widths handle expansion gracefully; fixed
    `dp` widths on text-bearing views are findings.
16. Mirror layout under RTL: use `start` / `end` instead of `left` /
    `right` in XML attributes (`paddingStart`, `layout_marginEnd`),
    set `android:supportsRtl="true"` in the manifest, and respect
    `LocalLayoutDirection` in Compose. Asymmetric icons (chevrons,
    arrows) use auto-mirrored vector drawables
    (`android:autoMirrored="true"`).
17. Format dates, times, numbers, currencies, and units locale-aware
    via `java.text.NumberFormat`, `java.text.DateFormat`,
    `android.icu.text.*`, or Kotlin's `kotlinx.datetime` with explicit
    locale. Never concatenate locale-sensitive substrings by hand;
    use `getQuantityString(R.plurals.…)` for plurals.
18. Maintain a single source of truth for translations —
    `strings.xml` files under version control with a documented
    translator workflow. Empty `<string>` values, stale keys, missing
    translations for declared locales (per `<locale-config>` /
    `LocaleManager`), and untranslated quantity strings are findings.
19. Test under both pseudolocales (`en-XA` for expansion + accented
    text, `ar-XB` for RTL) and at least one real RTL locale (`ar`,
    `he`, `fa`) before release. Snapshot or screenshot tests cover
    RTL for any user-facing surface.

### Out-of-scope (considered, excluded)

- Specific dependency injection framework (Hilt vs Koin vs manual) —
  belongs to a separate `android-di` skill if added; defects there are
  not UI-architecture defects.
- Navigation library choice (Navigation Compose vs Voyager vs
  Decompose) — the universal "navigation lives outside views" rule
  already covers it.
- Specific image-loading library (Coil vs Glide vs Picasso) —
  framework-of-the-year question; out of scope for an
  architecture audit.
- KMP / multiplatform UI choices (Compose Multiplatform) — emerging,
  shape will change; defer to a future v11.x skill.
- "Use Compose instead of XML" — both are supported; many real
  projects mix; the audit-relevant defects exist in both and are
  covered by the rules above.

---

## 4. `embedded-architecture` — Embedded UI (LVGL / Qt for MCU / ESP-IDF)

### Detection markers (for `PLATFORM-SKILLS.md`)

Embedded projects do not have a single canonical manifest; surface
heuristics rather than a single must-match condition:

- An `lv_conf.h` file anywhere in the tree, OR a CMake target that
  links `lvgl` / `liblvgl`.
- A `qmlproject` file alongside `qul-` named build presets, OR a
  `QmlProject` block referencing Qt for MCU (`Qul.Application`).
- An ESP-IDF project marker: `idf_component.yml` with `lvgl` or
  `esp_lcd` dependency; OR a top-level `CMakeLists.txt` calling
  `idf_build_process` / `idf_component_register`.
- A bare-metal / RTOS project (`Zephyr`, `FreeRTOS`, `NuttX`, `Mbed`)
  with display-driver headers (`display/cfb.h`, `gd_display.h`,
  vendor display HAL headers).

The skill must avoid over-specifying — embedded UI projects vary too
much. The pack-architect should consider whether `embedded-architecture`
is one skill or two (LVGL-leaning vs Qt-for-MCU-leaning); see Risks.

### Recommended audit-relevant rules (11)

**Object lifecycle and memory**
1. (LVGL) Every `lv_obj_create()` has a documented owner responsible
   for `lv_obj_delete()` (or relies on parent deletion to cascade).
   Objects created in event callbacks without an owner hierarchy leak
   into the LVGL memory pool. Use `lv_obj_clean()` to delete children
   without destroying the parent.
2. Static memory budget is documented in `ARCHITECTURE.md`: pool size
   (`LV_MEM_SIZE` for LVGL; static QML object count for Qt for MCU),
   peak measured allocation, and guard band. New UI features that
   consume more than 10% of the remaining guard band require an
   updated budget entry, not a silent `LV_MEM_SIZE` increase.
3. Display draw buffers are placed in the fastest available memory.
   On ESP32 / similar with PSRAM, LVGL draw buffers belong in
   internal SRAM (LVGL accesses them per-pixel); the framebuffer
   destination — read by DMA / EDMA only — may live in PSRAM. Mixing
   the two is a defect that costs 2-5× rendering throughput.

**Refresh budget and tear-free updates**
4. Display refresh uses double or triple buffering with VSYNC / TE
   (Tearing Effect) signal synchronization. Single-buffer rendering
   to a torn display is acceptable only on displays without a TE
   signal AND where partial-window rendering happens entirely within
   the vertical blanking interval.
5. The UI loop budget is documented per frame: `lv_timer_handler()`
   (or Qt for MCU equivalent) must complete within
   `1000 / target_fps` ms minus draw-buffer transfer time. Frames
   that overflow the budget cause perceived stutter; auditors flag
   composables / QML items that do unbounded work in property bindings
   or signal handlers fired during refresh.

**Watchdog-friendly UI loops**
6. Long-running UI operations (image decode, animation pre-bake,
   localized-text remeasure) yield to the OS scheduler at least every
   `task_wdt_timeout_ms / 4`. ESP32 `esp_task_wdt_reset()` (or RTOS
   equivalent) is called inside any UI loop that may exceed the
   watchdog interval. UI threads that block on I/O without yielding
   trigger the task watchdog and reboot the device.

**Power awareness**
7. UI components that animate (LVGL animations, QML
   `NumberAnimation` / `Behavior`) are gated by an active-input
   condition or an idle timeout. Continuous animation when the user
   is not present prevents the system from entering low-power /
   light-sleep modes — significant battery / thermal cost on
   battery-powered or fanless devices.
8. Backlight / display-on state is owned by an explicit
   power-management module that listens for user-input events and an
   idle timer. UI code that toggles backlight directly from event
   handlers leaks PM state across modules.

**Driver coupling**
9. Display driver code (panel init sequence, SPI / parallel / RGB /
   MIPI-DSI bus configuration) is isolated behind a thin HAL layer.
   UI code (LVGL widgets, QML scenes) does not include vendor
   `*_lcd.h` headers directly. Switching display panels should
   require changes only to the HAL implementation file.

**Font and asset placement**
10. Font and image assets are placed in flash / external NOR /
    QSPI-mapped read-only memory, not RAM. Per-glyph caches in RAM
    are sized via configuration (`LV_FONT_CACHE_SIZE` or equivalent),
    not unbounded. Loading a full Unicode font into RAM for a
    locale-aware UI is the most common embedded UI memory-exhaustion
    cause.

**Architecture decomposition**
11. UI logic, business logic, and driver logic live in separate
    translation units with explicit interfaces. UI event callbacks
    (`lv_event_cb_t`, QML `Connections`) call into a domain-layer
    function — they do not contain business logic inline. This rule
    parallels the Apple `apple-architecture-core` layer rules but
    holds even more strongly on embedded targets where rebuild cycles
    are slow and per-module testing matters.

### Localization rules (5 — final section, fewer because some
concepts do not apply on every embedded target)

12. Externalize every user-visible string into a build-time string
    table (LVGL `lv_i18n` / equivalent, or a project-local
    `strings.h` indexed by enum). Hardcoded `lv_label_set_text("…")`
    or QML `text: "…"` literals for user-facing strings are findings.
    The string table is the source of truth; per-locale files are
    overlays.
13. Font assets are selected per locale at build or runtime to ensure
    glyph coverage. A font with only Basic Latin glyphs cannot render
    Cyrillic / CJK / Arabic — characters fall back to `?` or empty
    boxes. Document supported locales and the font asset for each
    in `ARCHITECTURE.md`.
14. Display framebuffer and string-rendering paths are UTF-8-aware.
    LVGL with `LV_TXT_ENC = LV_TXT_ENC_UTF8`; Qt for MCU's text APIs
    accept QString (UTF-16 internal). Single-byte (Latin-1)
    string handling is a finding for any project supporting more than
    one Western European locale.
15. RTL / bidirectional text rendering: LVGL projects supporting RTL
    set `LV_USE_BIDI 1` and `LV_BIDI_BASE_DIR_DEF` per the active
    locale; Qt for MCU uses the platform text engine. Display
    layouts mirror under RTL where the project supports any RTL
    locale; embedded UIs that explicitly do NOT support RTL document
    that scope decision in `ARCHITECTURE.md`.
16. Tolerate translated string-length growth — design label widths
    and reserved screen regions for at least 30% expansion. Embedded
    UIs that truncate localized text silently are findings;
    truncation must be explicit (ellipsis indicator, marquee, or
    documented design decision).

### Out-of-scope (considered, excluded)

- Specific RTOS choice (FreeRTOS vs Zephyr vs RTX vs NuttX) — UI
  rules apply equally; RTOS-specific patterns belong to a separate
  skill if added.
- TouchGFX, Embedded Wizard, SquareLine Studio, Crank Storyboard —
  proprietary stacks; the rules above largely transfer but the skill
  should focus on the open / widely-documented stacks (LVGL, Qt for
  MCU, ESP-IDF) that the pack can verify against primary sources.
- GPU-accelerated rendering (Vivante / Mali / NEMA-GFX) — vendor
  specifics; defer to a future `embedded-gpu` skill if demand arises.
- Specific connectivity stacks (BLE / Wi-Fi / LoRa) — not UI
  concerns.

---

## 5. Cross-platform notes — patterns appearing in multiple platforms

Several patterns surfaced in 2+ platforms. The architect must decide
where each lives.

### Patterns that should live in EACH platform skill (not centralized)

These have platform-specific idioms even when conceptually identical;
auditing requires the platform-specific form.

- **Localization** — every platform skill carries its own; the
  Localization concept is universal but the APIs (`Intl.*` vs
  `getString` vs `lv_i18n`) differ.
- **Accessibility minimum tap target** — 44pt iOS, 48dp Android, no
  formal minimum on embedded but project-specific. Rule wording must
  cite the platform's accepted number.
- **State / source-of-truth discipline** — React `useState` vs
  Compose `remember` vs LVGL `lv_obj_get_user_data` are too different
  to share rule text.

### Patterns that could live in a shared `ui-architecture-core` skill

These have framework-agnostic phrasings the auditor can apply.

- **Single source of truth for state** — already implied by the
  universal layer-discipline rules in `project-template/CLAUDE.md`
  ("undocumented shared mutable state is a defect"). A
  `ui-architecture-core` would specialize that for "state that
  drives a rendered UI tree."
- **Navigation lives outside view types** — already in
  `apple-architecture-core` rule 27 and `project-template/CLAUDE.md`
  ("navigation logic lives outside view and view-model types").
- **Interactive elements must be reachable by keyboard / assistive
  tech** — phrased generically, this is a one-rule add to
  `audit-methodology` (see below) rather than a new core skill.

### Recommendation: extend `audit-methodology` rule 20 rather than
add a new core skill

The pack already has an audit-methodology cluster. Rather than create
`ui-architecture-core`, the architect should consider extending
`audit-methodology` rule 20 (the auditor-ui trigger rule) with a
short cross-platform UI checklist:

- Source of truth for visible state
- Interactive elements reachable by primary input modality (keyboard,
  touch, screen reader)
- No hardcoded user-facing strings outside a localization layer
- Layout adapts to translated string growth and bidirectional text

Then each platform skill specializes those checks for its idioms.
This keeps the skill catalog small and avoids a third level of
indirection.

The architect should make the call; this report flags the option.

---

## 6. Risks and open questions for pack-architect

1. **Embedded scope is broader than the other two.** "Embedded UI"
   spans bare-metal MCUs (Cortex-M0+, 32 KB SRAM) to Linux-class
   embedded (i.MX8, 1 GB DRAM, Wayland + Qt). The rules above lean
   toward the constrained end (where defects are common and
   audit-actionable). An `embedded-linux-architecture` companion skill
   may eventually be needed; the proposed `embedded-architecture`
   should explicitly scope itself to "MCU-class embedded UI" in its
   description, with a note that Linux-class UI is out of scope.

2. **Web is multi-framework.** The proposed single `web-architecture`
   skill carries framework-conditional rules ("React projects: …",
   "Vue projects: …"). The architect should decide whether this is
   acceptable or whether the skill should split into
   `web-architecture-core` + `web-react`, `web-vue`, `web-angular`,
   `web-svelte`. Single-skill is simpler for the pack; multi-skill
   matches how Apple platforms are organized
   (`apple-architecture-core` + `ios-architecture` + `macos-architecture`).
   Recommendation: start with single skill; split in a later
   minor version if rules grow past ~25.

3. **`auditor-ui` detection logic.** The auditor currently has Apple
   markers hardcoded. Adding three new platforms requires the
   auditor to enumerate detection markers per skill OR consult
   `PLATFORM-SKILLS.md`. The cleaner design is the latter — auditor
   reads `PLATFORM-SKILLS.md` to find applicable UI skills; if none
   match, it skips with a logged reason. The architect should specify
   this contract.

4. **Localization rule numbering.** The Apple skills numbered
   Localization 28-33 (ios) and 29-34 (macos) — sequential within
   the skill. The new skills should follow the same convention:
   number rules sequentially from 1, with Localization as the final
   section. (The report above already follows this.)

5. **Compose vs View-system coverage in `android-architecture`.**
   The 13 proposed rules lean Compose-heavy because Compose is the
   recommended path. Two View-system rules (9, 10) are included
   because legacy / mixed projects exist. The architect should
   decide whether the skill targets greenfield Compose projects only
   (drop View-system rules) or both (keep them). Recommendation: keep
   both; pack-coder can check if any consuming project exists that
   would be ill-served.

6. **Embedded localization is partially aspirational.** Many embedded
   UIs ship single-locale. The Localization section's 5 rules apply
   only to multi-locale projects; the architect may want to gate the
   section with a sentence: "If the project supports more than one
   user-visible locale, the following apply." Single-locale projects
   would still be audited against the non-Localization rules.

7. **Pseudolocale support varies.** Android has built-in `en-XA` /
   `ar-XB`. Web has no built-in pseudolocale; tools like
   `pseudo-localization` npm package exist but are project choice.
   Embedded projects often have no pseudolocale tooling. Localization
   rule 18 / 16 / 16 should be phrased to require *equivalent
   testing*, not specifically pseudolocales, for web and embedded.
   (The report above already softens these.)

---

## 7. Sources / references

### React / Web

- [useEffect — React](https://react.dev/reference/react/useEffect)
- [Removing Effect Dependencies — React](https://react.dev/learn/removing-effect-dependencies)
- [exhaustive-deps lint — React](https://react.dev/reference/eslint-plugin-react-hooks/lints/exhaustive-deps)
- [Rendering Lists — React](https://react.dev/learn/rendering-lists)
- [Suspense — React](https://react.dev/reference/react/Suspense)
- [hydrateRoot — React](https://react.dev/reference/react-dom/client/hydrateRoot)
- [Text content does not match server-rendered HTML — Next.js](https://nextjs.org/docs/messages/react-hydration-error)
- [Reactivity Fundamentals — Vue.js](https://vuejs.org/guide/essentials/reactivity-fundamentals)
- [ChangeDetectionStrategy — Angular](https://angular.dev/api/core/ChangeDetectionStrategy)
- [Skipping component subtrees — Angular](https://angular.dev/best-practices/skipping-subtrees)
- [Zoneless — Angular](https://angular.dev/guide/zoneless)
- [Accessibility — Angular](https://angular.dev/best-practices/a11y)
- [Stores — Svelte](https://svelte.dev/docs/svelte/stores)
- [svelte/reactivity — Svelte](https://svelte.dev/docs/svelte/svelte-reactivity)
- [Accessibility — SvelteKit](https://kit.svelte.dev/docs/accessibility)
- [Dialog (Modal) Pattern — W3C ARIA APG](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/)
- [Understanding SC 2.4.3: Focus Order — W3C WCAG 2.2](https://www.w3.org/WAI/WCAG22/Understanding/focus-order.html)
- [aria-modal — MDN](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Attributes/aria-modal)
- [CSS Logical Properties and Values — MDN](https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Logical_properties_and_values)
- [lang HTML global attribute — MDN](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Global_attributes/lang)
- [Largest Contentful Paint — web.dev](https://web.dev/articles/lcp)
- [Optimize Cumulative Layout Shift — web.dev](https://web.dev/articles/optimize-cls)
- [The performance effects of too much lazy loading — web.dev](https://web.dev/lcp-lazy-loading/)
- [i18next — i18next.com](https://www.i18next.com/)
- [Vue I18n — vue-i18n.intlify.dev](https://vue-i18n.intlify.dev/)

### Android

- [State and Jetpack Compose — Android Developers](https://developer.android.com/develop/ui/compose/state)
- [Where to hoist state — Android Developers](https://developer.android.com/develop/ui/compose/state-hoisting)
- [Side-effects in Compose — Android Developers](https://developer.android.com/develop/ui/compose/side-effects)
- [Follow best practices (Compose performance) — Android Developers](https://developer.android.com/develop/ui/compose/performance/bestpractices)
- [Stability in Compose — Android Developers](https://developer.android.com/develop/ui/compose/performance/stability)
- [Strong skipping mode — Android Developers](https://developer.android.com/develop/ui/compose/performance/stability/strongskipping)
- [Compose modifiers — Android Developers](https://developer.android.com/develop/ui/compose/modifiers)
- [Fragment lifecycle — Android Developers](https://developer.android.com/guide/fragments/lifecycle)
- [View binding — Android Developers](https://developer.android.com/topic/libraries/view-binding)
- [ViewModel overview — Android Developers](https://developer.android.com/topic/libraries/architecture/viewmodel)
- [Handle configuration changes — Android Developers](https://developer.android.com/guide/topics/resources/runtime-changes)
- [Principles for improving app accessibility — Android Developers](https://developer.android.com/guide/topics/ui/accessibility/principles)
- [Make custom views more accessible — Android Developers](https://developer.android.com/guide/topics/ui/accessibility/custom-views)
- [Localize your app — Android Developers](https://developer.android.com/guide/topics/resources/localization)
- [Test your app with pseudolocales — Android Developers](https://developer.android.com/guide/topics/resources/pseudolocales)
- [LayoutDirection — Compose API reference](https://developer.android.com/reference/kotlin/androidx/compose/ui/unit/LayoutDirection)

### Embedded

- [LVGL master documentation — docs.lvgl.io](https://docs.lvgl.io/master/)
- [LVGL Refreshing — docs.lvgl.io](https://docs.lvgl.io/master/main-modules/display/refreshing.html)
- [LVGL Setting Up Your Display(s) — docs.lvgl.io](https://docs.lvgl.io/master/main-modules/display/setup.html)
- [LVGL on ESP32 — Tips and tricks (PSRAM, framebuffer placement)](https://docs.lvgl.io/master/integration/chip_vendors/espressif/tips_and_tricks.html)
- [Add LVGL to an ESP32 IDF project — docs.lvgl.io](https://docs.lvgl.io/master/integration/chip_vendors/espressif/add_lvgl_to_esp32_idf_project.html)
- [Detailed Explanation of LCD Screen Tearing — ESP-IoT-Solution](https://docs.espressif.com/projects/esp-iot-solution/en/latest/display/lcd/lcd_screen_tearing.html)
- [Watchdogs — ESP-IDF Programming Guide](https://docs.espressif.com/projects/esp-idf/en/stable/esp32/api-reference/system/wdts.html)
- [Support for External RAM — ESP-IDF Programming Guide](https://docs.espressif.com/projects/esp-idf/en/stable/esp32/api-guides/external-ram.html)
- [Memory Types (ESP32) — ESP-IDF Programming Guide](https://docs.espressif.com/projects/esp-idf/en/v4.4/esp32/api-guides/memory-types.html)
- [Qt Quick Ultralite overview — Qt for MCUs 2.12.1](https://doc.qt.io/QtForMCUs/qtul-overview.html)
- [Performance considerations and suggestions — Qt Quick](https://doc.qt.io/qt-6/qtquick-performance.html)

