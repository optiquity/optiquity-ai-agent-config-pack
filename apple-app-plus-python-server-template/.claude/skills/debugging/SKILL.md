---
name: debugging
description: Use when tracing a failing path, reproducing a bug, or narrowing down likely causes before making changes.
allowed-tools: Read, Grep, Glob, Bash
---

1. Reproduce the issue or restate the failing condition clearly.
2. Trace the real execution path and data flow.
3. Narrow candidate causes before editing.
4. Prefer evidence from logs, tests, runtime output, or file references.
5. Propose the smallest defensible fix and the verification plan.
