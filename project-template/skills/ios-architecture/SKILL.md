---
name: ios-architecture
description: Use for iOS/iPadOS-specific architecture — scene lifecycle, UIKit interop justification, background tasks, App Store and extension boundaries, touch-first interaction model.
allowed-tools: Read, Grep, Glob, Bash
---

## Architectural assessment

1. Identify modules, layers, and seams.
2. Check whether SwiftUI-first remains viable.
3. Require justification for UIKit interop.
4. Check state ownership, immutability, and dependency boundaries.
5. Flag portability, maintenance, and third-party integration risks.

## Scene lifecycle

6. Use `UIScene`-based lifecycle. Do not rely on `UIApplicationDelegate` methods that have scene-aware equivalents.
7. Each scene owns its own navigation state. Do not share navigation state across scenes.
8. Handle `sceneDidDisconnect`, `sceneDidEnterBackground`, and `sceneWillEnterForeground` for resource cleanup and restoration.
9. Suspend long-lived network connections (including gRPC streams) in `sceneDidEnterBackground`. Reconnect in `sceneWillEnterForeground`.
10. Do not assume a single scene. iPad supports multiple scenes for the same app.

## UIKit interop

11. UIKit interop requires documented justification — performance, missing SwiftUI capability, or mature third-party framework that only exposes UIKit API.
12. Wrap UIKit views in `UIViewRepresentable` or `UIViewControllerRepresentable`. Do not mix UIKit view hierarchy management with SwiftUI declarative layout.
13. UIKit-hosted views must participate in the SwiftUI data flow via `Binding` or `Coordinator` — do not create parallel state channels.
14. Prefer SwiftUI navigation. Use UIKit navigation controllers only when SwiftUI `NavigationStack` cannot express the required flow.

## Background tasks

15. Use `BGAppRefreshTask` and `BGProcessingTask` for deferred background work. Do not use `beginBackgroundTask` for long-running operations — it has a 30-second limit.
16. Background tasks must be idempotent. The system may terminate and re-launch them at any time.
17. Register background task identifiers in `Info.plist`. Missing registrations silently fail.
18. Network requests in background tasks must handle connectivity loss gracefully.

## App Store and extension boundaries

19. App extensions run in a separate process with a restricted API surface. Do not import UIApplication or use APIs marked unavailable in extensions.
20. Shared data between app and extensions uses App Groups. Do not rely on the app's main container for shared state.
21. iCloud and CloudKit entitlements must match between app and extensions.
22. App Store review flags: background location, HealthKit, and push notification entitlements require usage descriptions and documented justification.

## Touch-first interaction model

23. All interactive elements must meet the 44×44pt minimum tap target size.
24. Support Dynamic Type. Do not hardcode font sizes — use text styles or scaled metrics.
25. Support both portrait and landscape where the app's purpose permits. Document any orientation lock with justification.
26. Gesture recognizers must not conflict with system gestures (edge swipe for back, notification center pull-down).
27. Accessibility: every interactive element must have an accessibility label. Images that convey meaning must not be marked decorative.
