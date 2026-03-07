---
name: dependency-intake
description: Use before adding a third-party package, UI framework, SDK, or external API wrapper.
allowed-tools: Read, Grep, Glob
---

Evaluate the proposed dependency against this checklist:

1. Can Apple frameworks solve the need well enough?
2. Is it available through Swift Package Manager?
3. What is the maintenance status, license, security posture, and lock-in risk?
4. Does it force UIKit or AppKit interop or shape the architecture in unwanted ways?
5. What is the rollback plan if the dependency becomes stale?

Output:

- recommendation
- rationale
- rejected alternatives
- integration risks
