---
name: debugging
description: Use when tracing a failing path, reproducing a bug, or narrowing down likely causes before making changes.
allowed-tools: Read, Grep, Glob, Bash
---

## Root cause first

1. No fix is attempted before the root cause is identified. Treating symptoms creates new bugs.
2. Reproduce the issue reliably before investigating. If it cannot be reproduced, document the conditions under which it was observed and instrument for next occurrence.
3. State the hypothesis explicitly before reading code. "I believe X is happening because Y" — then verify or disprove.

## Narrowing the search

4. Apply binary search on the problem space — bisect between the last known-good state and the failing state. Use `git bisect` when the regression can be tied to a commit range.
5. Trace the real execution path, not the expected one. Read code from the entry point of the failure, not from where you think the bug should be.
6. Check the simplest explanations first: wrong input, stale cache, missing dependency, wrong environment variable, wrong branch.
7. When multiple hypotheses exist, test the one that can be disproved fastest.

## Diagnostic techniques

8. Add diagnostic logging at strategic points to trace execution flow. Remove all diagnostic logging after the fix is verified.
9. Use platform debuggers: `lldb` for Swift/C/C++/Objective-C, `pdb`/`debugpy` for Python. Set conditional breakpoints rather than stepping through loops.
10. Use Instruments (Xcode) for performance, memory, and concurrency issues on Apple platforms. Use `os_signpost` for custom performance measurement.
11. For concurrency bugs: enable Thread Sanitizer (TSan) and Address Sanitizer (ASan). These catch races and memory errors that are invisible to code reading.
12. For gRPC issues: inspect wire traffic with `grpcurl` or enable gRPC debug logging. Check deadline propagation, status codes, and metadata.

## Verifying the fix

13. Write a test that fails before the fix and passes after. If the bug cannot be tested, document why.
14. Verify the fix does not change unrelated behavior — run the full test suite, not just the new test.
15. Check for the same bug pattern elsewhere in the codebase. A bug in one call site often exists in similar call sites.
16. Document the root cause in the commit message or completion report. Future maintainers need to understand why, not just what.
