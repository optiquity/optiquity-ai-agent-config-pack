---
name: macos-architecture
description: Use for macOS-specific architecture — NSDocument, multiple NSWindow management, AppDelegate lifecycle, menu bar ownership, AppKit interop, sandbox, notarization, Services integration.
allowed-tools: Read, Grep, Glob, Bash
---

## NSDocument architecture

1. Document-based apps use `NSDocument` or SwiftUI's `DocumentGroup`. Each document instance owns its data, undo manager, and save/load lifecycle.
2. Document autosave and versioning (`NSDocument.autosavesInPlace`) should be enabled unless the app has an explicit reason not to.
3. File coordination (`NSFileCoordinator`) is required when multiple processes or extensions may access the same document.

## Window management

4. macOS apps may have multiple windows open simultaneously. Each window's state is independent — do not share navigation or selection state across windows.
5. Use `WindowGroup` (SwiftUI) for multi-window support. Use `Window` for single-instance utility windows.
6. Inspector panels and floating windows use `.windowStyle(.plain)` or `NSPanel` (AppKit). They do not appear in the Window menu.
7. Window restoration: implement `NSWindowRestoration` or use SwiftUI's built-in scene state persistence so windows reopen in their previous positions after relaunch.

## AppDelegate and lifecycle

8. `AppDelegate` handles app-wide concerns only: Dock menu, global keyboard shortcuts, Services registration, open-file events.
9. Scene-level lifecycle (window activation, deactivation) is handled by `NSWindowDelegate` or SwiftUI scene phase, not AppDelegate.
10. Terminate-on-last-window-close behavior must be explicitly configured — macOS apps do not terminate by default when all windows close.

## Menu bar and keyboard shortcuts

11. Provide complete menu bar integration. All primary actions have menu items with keyboard shortcuts.
12. Use `CommandMenu` and `.keyboardShortcut()` in SwiftUI. Use `NSMenu` and `NSMenuItem` with `keyEquivalent` in AppKit.
13. Validate menu items dynamically — disable items that are not applicable to the current state using `validateMenuItem:` (AppKit) or conditional disabling (SwiftUI).
14. Respect standard macOS keyboard shortcuts (Cmd+C, Cmd+V, Cmd+Z, Cmd+Q, Cmd+W, Cmd+,). Do not override them with non-standard behavior.

## AppKit interop

15. AppKit interop follows the same justification rules as UIKit interop (see apple-architecture-core). Wrap in `NSViewRepresentable` or `NSViewControllerRepresentable`.
16. NSToolbar configuration uses SwiftUI's `.toolbar` modifier where possible. Fall back to `NSToolbar` delegate for complex customizable toolbars.

## Sandbox and notarization

17. App Sandbox is enabled. Entitlements are the minimum required set.
18. File access outside the sandbox uses Security-Scoped Bookmarks for persistent access and `NSOpenPanel`/`NSSavePanel` for one-time access.
19. Hardened Runtime is enabled for notarization. Any entitlement exception (e.g., disable library validation for plugins) requires documented justification.
20. All distributed builds are notarized. Test notarization before submission — `xcrun notarytool` or Xcode's organizer.

## Services and system integration

21. Register app Services in Info.plist when the app provides text or data transformation capabilities to other apps.
22. Support Shortcuts (formerly Automator actions) via App Intents for common operations.
23. Drag-and-drop uses `NSItemProvider` (AppKit) or `.onDrop`/`.draggable` (SwiftUI). Support standard pasteboard types for interoperability with other apps.
