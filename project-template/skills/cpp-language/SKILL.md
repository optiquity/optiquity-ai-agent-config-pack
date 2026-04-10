---
name: cpp-language
description: Use for C++ in any project — RAII and smart pointers, Swift-C++ interop, header organization, rule of five, const correctness, and C++ anti-patterns.
allowed-tools: Read, Grep, Glob, Bash
---

## RAII and ownership

1. Every resource (memory, file handle, mutex, network connection) is owned by an RAII wrapper. No raw `new`/`delete` in application code.
2. Use `std::unique_ptr` for exclusive ownership. Use `std::shared_ptr` only when ownership is genuinely shared — document the sharing rationale.
3. Use `std::make_unique` and `std::make_shared` for construction. Never use raw `new` followed by assignment to a smart pointer.
4. Avoid `std::weak_ptr` unless breaking a documented reference cycle.

## Rule of five

5. If a class defines any of: destructor, copy constructor, copy assignment, move constructor, move assignment — it must define or explicitly delete all five.
6. Prefer `= default` for compiler-generated special members. Use `= delete` to prohibit copying or moving.
7. Move constructors and move assignment operators must be `noexcept` to enable efficient container operations.

## Const correctness

8. Use `const` on all variables, parameters, return values, and member functions that do not modify state.
9. Prefer `const_iterator` when iterating without modification.
10. Const references (`const T&`) for read-only pass-by-reference. Move semantics (`T&&`) for ownership transfer.

## Header organization

11. Use the `.hpp`/`.cpp` split convention. Headers contain declarations, source files contain definitions.
12. Use `#pragma once` or include guards in every header.
13. Include only what you use. Prefer forward declarations in headers.
14. Keep headers self-contained — every header compiles independently without relying on inclusion order.

## Error handling

15. Use exceptions for exceptional conditions only — never for control flow.
16. Avoid exceptions in performance-critical paths. Use error codes or `std::expected` (C++23) instead.
17. Mark functions that do not throw as `noexcept`. Violations terminate the program.

## Swift-C++ interop (Swift 5.9+)

18. Swift can call C++ functions directly when the C++ header is included in the bridging header or module map.
19. C++ types used from Swift must be trivially copyable or have move semantics — Swift cannot manage C++ types with complex copy semantics.
20. Use `SWIFT_SHARED_REFERENCE` for C++ reference types that Swift should manage via reference counting.
21. Prefer C wrapper functions over direct C++ exposure when the C++ API surface is complex.

## Anti-patterns

22. No raw `new`/`delete` — use smart pointers.
23. No C-style casts — use `static_cast`, `dynamic_cast`, `const_cast`, or `reinterpret_cast` with documented justification.
24. No `using namespace` in headers — it pollutes the namespace for all includers.
25. No mutable global state — use function-local statics or dependency injection.
26. No `std::endl` in performance-sensitive code — use `'\n'` and flush explicitly when needed.
