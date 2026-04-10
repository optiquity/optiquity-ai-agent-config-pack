---
name: deployment-apple
description: Use for Apple platform deployment — code signing, entitlements, notarization, privacy manifests, App Store submission, and distribution profiles.
allowed-tools: Read, Grep, Glob, Bash
---

## Code signing

1. Automatic signing is acceptable for development. Manual signing is required for CI/CD and release builds.
2. Development and distribution certificates must be stored in the team's Apple Developer portal, not in individual developer Keychains.
3. Provisioning profiles must match the app's bundle identifier and entitlements exactly. Mismatches cause silent signing failures.

## Entitlements

4. App Sandbox is enabled for all macOS apps unless explicitly exempted with documented justification.
5. Entitlements are the minimum required set. Each entitlement is justified in comments or documentation.
6. Hardened Runtime is enabled for all distributed macOS builds. Exceptions (e.g., disable library validation) require documented justification.
7. Entitlement changes require review — they affect what the app can access on the user's device.

## Notarization

8. All macOS builds distributed outside the App Store must be notarized.
9. Test notarization before submission using `xcrun notarytool submit`.
10. Notarization failures are usually caused by unsigned embedded frameworks, missing Hardened Runtime, or entitlement issues. Check the notarization log for specifics.

## Privacy manifests

11. Every App Store submission includes a `PrivacyInfo.xcprivacy` manifest.
12. Declare all accessed required reason APIs and all third-party SDK data practices.
13. Update the manifest when adding or removing third-party SDKs.

## App Store submission

14. Ensure the build number is incremented for every submission. Duplicate build numbers are rejected.
15. App Store screenshots and metadata must match the submitted binary's functionality.
16. Review App Store Review Guidelines before submission — especially sections on data collection, in-app purchases, and content.
17. TestFlight builds expire after 90 days. Plan beta testing timelines accordingly.

## Distribution profiles

18. Ad Hoc profiles are for testing on registered devices only. They are not for production distribution.
19. Enterprise distribution profiles are for internal-only apps. They must never be used for public distribution.
20. App Store distribution profiles are the only valid profile type for App Store submission.
