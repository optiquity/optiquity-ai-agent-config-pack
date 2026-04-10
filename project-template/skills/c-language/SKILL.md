---
name: c-language
description: Use for C code in any project — memory ownership and lifecycle, pointer safety, buffer handling, const correctness, header guards, Swift and Python interop.
allowed-tools: Read, Grep, Glob, Bash
---

## Memory ownership and lifecycle

1. Every allocation has a single, documented owner responsible for freeing it.
2. Document ownership transfer at every function boundary — callers must know whether they own the returned pointer.
3. Free memory in the reverse order of allocation. Pair every `malloc`/`calloc` with exactly one `free`.
4. Set freed pointers to NULL immediately after `free` to prevent use-after-free.
5. Never return pointers to stack-allocated memory.

## Pointer safety

6. Check all pointers for NULL before dereferencing. Document which function parameters may be NULL.
7. Never cast between incompatible pointer types without documented justification.
8. Use `restrict` only when aliasing is provably absent and performance measurement justifies it.
9. Avoid pointer arithmetic on void pointers — cast to a concrete type first.

## Buffer handling

10. Track buffer sizes alongside buffer pointers. Pass both as parameters — never rely on sentinels alone.
11. Use `strncpy`, `snprintf`, and bounded variants. Never use `strcpy`, `sprintf`, or `gets`.
12. Validate all buffer indices against bounds before access.
13. Null-terminate all strings explicitly. Do not assume library functions null-terminate output buffers.

## Const correctness

14. Use `const` for all parameters, return values, and local variables that are not modified.
15. Pointer-to-const (`const char *`) for read-only access. Const-pointer (`char *const`) for non-reassignable pointers.
16. Cast away `const` only at documented, justified interop boundaries.

## Header hygiene

17. Every header uses include guards (`#ifndef`/`#define`/`#endif`) or `#pragma once`.
18. Headers declare the public interface only. Implementation details stay in `.c` files.
19. Include only what you use. Do not rely on transitive includes.
20. Use forward declarations in headers when a full type definition is not needed.

## Swift interop

21. Expose C functions to Swift via a bridging header. Keep the bridging surface minimal.
22. Use `CF_SWIFT_NAME` or `NS_SWIFT_NAME` to provide idiomatic Swift names for C functions.
23. Nullable pointers must be annotated (`_Nullable`, `_Nonnull`) so Swift can generate correct optionality.

## Python interop

24. Use `ctypes` for simple FFI or `cffi` for complex C library bindings. Prefer `cffi` for new code.
25. Document memory ownership at the Python/C boundary — who allocates, who frees.
26. Never pass Python-managed memory to C functions that may outlive the Python object's lifetime.
