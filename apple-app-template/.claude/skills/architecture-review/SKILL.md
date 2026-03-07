---
name: architecture-review
description: Use when assessing architecture, module boundaries, concurrency decisions, ownership of mutable state, or whether UIKit or AppKit interop is justified.
allowed-tools: Read, Grep, Glob, Bash
---

1. Identify the modules, layers, and ownership boundaries involved.
2. Locate mutable state and decide whether it is justified.
3. Check whether value semantics, final classes, builders, or factories would improve correctness.
4. Check whether the proposed design keeps SwiftUI views thin.
5. Flag dependency, testability, and concurrency risks.
6. Give a recommendation with explicit tradeoffs.
