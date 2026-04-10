---
name: dependency-swift
description: Use alongside dependency-intake when evaluating Swift/Apple dependencies — SPM resolution, deployment targets, binary frameworks, Apple framework alternatives.
allowed-tools: Read, Grep, Glob, Bash
---

## Apple framework alternatives

1. Before adding any third-party package, check whether an Apple framework covers the need. This applies especially to ML, visual effects, networking, and system integration.
2. Check iOS 26 / macOS 26 APIs — newer framework capabilities may eliminate the need for a dependency that was required on older OS versions.
3. Prefer Foundation, SwiftUI, Combine, and other first-party frameworks over third-party equivalents unless the third-party option provides a capability Apple does not.

## SPM evaluation

4. Verify the package is available through Swift Package Manager. No CocoaPods or manual vendoring unless technically blocked in SPM.
5. Check the package's `Package.swift` for minimum Swift version and platform deployment targets. Verify compatibility with the project's targets.
6. Use version-based dependency resolution (`.upToNextMajor`, `.upToNextMinor`) rather than branch or commit pinning for stable releases. Pin to exact versions only when required by a known compatibility issue.
7. Inspect the dependency tree: `swift package show-dependencies --format json`. Flag packages with deep transitive dependency trees.
8. Check whether the package provides library or framework targets. Framework targets may affect app launch time and binary size.

## Binary and size considerations

9. Check whether the package is source-only or includes pre-built binary frameworks (`.xcframework`). Binary-only packages block debugging into library code and may not support all architectures.
10. Estimate binary size impact. For mobile apps, each additional framework adds to download size and launch time.
11. Verify the package supports all required architectures (arm64 for device, x86_64/arm64 for simulator, arm64 for macOS).

## Security and compliance

12. Run `swift package audit` (Xcode 16+) to check for known vulnerabilities. Review GitHub security advisories for the package.
13. Check whether the package accesses any required-reason APIs that must be declared in the app's Privacy Manifest (`PrivacyInfo.xcprivacy`).
14. Verify the package does not include analytics, telemetry, or data collection that conflicts with the app's privacy policy.

## Xcode compatibility

15. Verify the package builds cleanly in the project's Xcode version. Some packages require specific Xcode versions for Swift language features or SDK availability.
16. Check for known issues with the package in the current Xcode release — search the package's GitHub issues for Xcode version-specific problems.
