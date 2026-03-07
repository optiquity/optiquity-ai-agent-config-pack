---
name: ios-architecture
description: Use when assessing Apple-platform architecture, module boundaries, SwiftUI to UIKit or AppKit interop, or long-term maintainability.
allowed-tools: Read, Grep, Glob, Bash
---

1. Identify modules, layers, and seams.
2. Check whether SwiftUI-first remains viable.
3. Require justification for UIKit or AppKit interop.
4. Check state ownership, immutability, and dependency boundaries.
5. Flag portability, maintenance, and third-party integration risks.
