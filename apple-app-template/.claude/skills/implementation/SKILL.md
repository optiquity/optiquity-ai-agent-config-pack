---
name: implementation
description: Use when adding code, fixing bugs, or making targeted refactors after the task is understood.
allowed-tools: Read, Grep, Glob, Edit, Write, MultiEdit, Bash
---

1. Read the existing code path first.
2. Make the smallest correct change.
3. Preserve behavior unless the task explicitly changes it.
4. Keep architecture aligned with repo rules.
5. Add or update tests when behavior changes.
6. Avoid unrelated cleanup.
