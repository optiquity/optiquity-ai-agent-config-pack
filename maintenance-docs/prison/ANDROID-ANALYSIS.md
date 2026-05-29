> **⚠️ DEPRECATED — April 2026**
> This document is superseded by [`TOOL-COMPARISON.md`](TOOL-COMPARISON.md).
> It is retained as a historical record. Do not use it as a current reference.

---

# Android App Development — Integration Analysis

**Status:** Analysis only. No implementation in v8.
**Purpose:** Documents what would need to change to support Android app development
within the AI Agent Config Pack.

---

## New template needed

An `android-app-template/` would be required, analogous to `apple-app-template/`.
It would not be a modification of an existing template — the toolchain, language,
build system, and IDE are sufficiently different to warrant a standalone template.

---

## CLAUDE.md and AGENTS.md changes

The existing templates' Swift-specific rules would be replaced or supplemented with:

**Language:** Kotlin (primary), Java (legacy interop only)
**UI framework:** Jetpack Compose (analogous to SwiftUI-first rule)
**Build system:** Gradle (replaces SPM; no CocoaPods equivalent)
**Concurrency:** Kotlin coroutines + Flow (analogous to Swift async/await + AsyncSequence)
**Architecture:** MVVM or MVI with ViewModel, analogous to existing layer discipline
**Persistence:** Room (analogous to SwiftData/CoreData rules)
**Dependency injection:** Hilt or Koin (analogous to manual DI rules)
**Testing:** JUnit 5 + Mockk + Espresso (analogous to XCTest + XCUITest)
**Code style:** ktlint or detekt (analogous to swift-format + ruff)

**Layer discipline rules** would be substantially the same:
- Domain layer has no Android framework imports (no Context, no ViewModel, no Room)
- Generated Protobuf types stay in the data layer
- Every cross-layer dependency is a protocol/interface
- Navigation logic outside composables and view models

**Security rules** would differ:
- Android Keystore (not iOS Keychain)
- ProGuard/R8 for release builds
- Network Security Configuration instead of ATS
- `EncryptedSharedPreferences` for non-credential local storage

---

## New architect agent needed

`android-architect` — analogous to `apple-architect`. Focus areas:
- Jetpack Compose-first design
- ViewModel scope and lifecycle awareness
- Hilt dependency graph design
- Room database schema design
- Navigation component vs manual navigation
- Module structure (app, feature, core, data modules)
- ProGuard rule implications for architecture decisions

---

## New skill needed

`android-architecture` skill — 10-item checklist analogous to `ios-architecture/SKILL.md`:
1. Verify domain layer has no Android framework imports
2. Check Compose UI is thin (no business logic in composables)
3. Verify ViewModel does not hold Android Context directly
4. Check Room entities do not appear in domain layer type signatures
5. Verify Hilt dependency graph has no circular dependencies
6. Check navigation logic is in NavHost or Coordinator, not in composables
7. Verify coroutine scope management (no GlobalScope in production)
8. Check Flow collection is lifecycle-aware (no raw collect in composables)
9. Verify ProGuard rules cover all reflection-used classes
10. Flag any Java interop that bypasses null safety

---

## IDE companion files

Android development uses Android Studio, not Xcode. New companion files would be
needed at `android-studio-companion-templates/` analogous to `xcode-companion-templates/`:
- Machine-level CLAUDE.md and AGENTS.md for Android Studio's AI features
- Verify whether Android Studio 2025+ supports Claude/Codex/Gemini as providers

VS Code with the Android extension pack is a viable alternative for non-UI work.
The existing `vscode-companion-templates/` would need Android-specific additions
(lint tasks, Gradle tasks, ADB commands).

---

## Scripts changes

The existing shell scripts assume Swift/Xcode or Python. An Android template would need:

| Script | Android equivalent |
|---|---|
| `bootstrap.sh` | `./gradlew dependencies` |
| `format.sh` | `./gradlew ktlintFormat` or `./gradlew detekt` |
| `test.sh` | `./gradlew test` (unit) + `./gradlew connectedAndroidTest` (instrumented) |
| `validate.sh` | `./gradlew build` + `./gradlew test` |
| `proto-gen.sh` | `./gradlew generateProto` (via protobuf-gradle-plugin) |
| `agent-post-edit-check.sh` | `./gradlew compileDebugKotlin` |

---

## gRPC differences for Android clients

gRPC on Android uses `grpc-kotlin` or `grpc-java`, not `grpc-swift-2`. Key differences:
- Generated code uses Kotlin coroutines (suspend functions) or Java futures
- Channel creation uses `ManagedChannelBuilder` (not `GRPCChannelPool`)
- TLS configuration differs (OkHttp or Netty transport)
- `grpc-kotlin` is the recommended modern choice (analogous to `grpc-swift-2`)

The `grpc-schema` agent and skill are language-agnostic (Proto3 rules don't change)
and would apply unchanged to Android projects. The client-side gRPC rules in
`CLAUDE.md` would need Android-specific versions.

---

## Gemini CLI vs Claude Code for Android

**Gemini CLI is likely the better choice for Android** for these reasons:

1. **Ecosystem alignment.** Android is a Google platform. Gemini's training includes
   deep coverage of Android SDK, Jetpack libraries, and Google Play policies.
2. **Jetpack Compose knowledge.** Compose is Google-developed and relatively new.
   Gemini's training is more likely to be current on Compose APIs and patterns.
3. **Gradle knowledge.** Gradle's complexity and Kotlin DSL evolution are areas where
   more recent, Google-aligned training helps.
4. **Android Studio integration.** If Google adds Gemini to Android Studio (analogous
   to Apple's Xcode integration), Gemini CLI would be the natural companion.

Claude Code would still be appropriate for architecture review, multi-file reasoning,
and Python server work in a monorepo that includes both Android and server code.

**Recommended tool split for an Android project:**

| Phase | Tool | Reason |
|---|---|---|
| Architecture / design | Claude Code | Multi-file reasoning, layer discipline |
| Implementation | Gemini CLI | Ecosystem alignment, Compose/Gradle knowledge |
| Code review | Claude Code | Multi-file analysis |
| Testing | Gemini CLI or Codex | Pattern generation |
| gRPC schema | Claude Code | grpc-schema agent |

---

## Pack files that would need to change or be added

**New files:**
- `android-app-template/` — full template directory
- `android-app-template/CLAUDE.md` — Android-specific rules
- `android-app-template/AGENTS.md` — Android agent roster
- `android-app-template/METHODOLOGY.md` — copy from pack
- `android-app-template/.claude/agents/android-architect.md`
- `android-app-template/.claude/skills/android-architecture/SKILL.md`
- `android-studio-companion-templates/` — analogous to xcode-companion-templates/

**Modified files:**
- `QUICKSTART.md` — add Android template option to Step 1 table
- `README.md` — add android-app to template comparison table
- `METHODOLOGY.md` — update tool roles to mention Android Studio and Gemini CLI
- `vscode-companion-templates/.vscode/tasks.json` — add Gradle tasks

**Files unchanged:** All existing templates, existing companion files, proto scaffold.

---

## Recommendation for a future version

Add Android support when:
1. There is a concrete Android project to build (drives real validation)
2. Gemini CLI's agent mechanism is confirmed and stable
3. Android Studio AI provider support is known

Estimated pack effort: 1 new template directory (~30 files) + updates to
QUICKSTART.md, README.md, METHODOLOGY.md.
