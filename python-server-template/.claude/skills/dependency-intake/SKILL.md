---
name: dependency-intake
description: Use before adding a third-party package, UI framework, SDK, or external API wrapper.
allowed-tools: Read, Grep, Glob, Bash
---

1. Can Apple frameworks solve the need well enough?
2. Is it available through Swift Package Manager?
3. What are the maintenance, license, security posture, and lock-in risks?
4. Does it force UIKit or AppKit interop or shape the architecture in unwanted ways?
5. What is the rollback plan if the dependency becomes stale?

Output:
- recommendation
- rationale
- rejected alternatives
- integration risks
