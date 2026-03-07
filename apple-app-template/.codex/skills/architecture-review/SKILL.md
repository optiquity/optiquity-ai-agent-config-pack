---
name: architecture-review
description: Use when evaluating Apple-platform architecture, module boundaries, concurrency choices, state ownership, or whether UIKit or AppKit interop is justified.
---

1. Inspect the relevant modules and seams.
2. Identify mutable state, ownership, and threading assumptions.
3. Check whether value semantics, final classes, builders, or validated factories would improve correctness.
4. Check whether the design keeps UI thin and orchestration outside views.
5. Produce a recommendation with concrete tradeoffs and suggested tests.
