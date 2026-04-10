---
name: objc-language
description: Use for Objective-C in Apple projects — ARC memory management, nullability annotations, bridging headers, NS_SWIFT_NAME, legacy code modification patterns.
allowed-tools: Read, Grep, Glob, Bash
---

## When to use Objective-C

1. Writing new Objective-C is a last resort. Document why no Swift alternative exists.
2. Valid reasons: maintaining existing Objective-C code, wrapping a C/Objective-C-only framework, runtime features unavailable in Swift (method swizzling, KVO on non-@objc properties).
3. Objective-C++ (`.mm` files) is out of scope for this skill.

## ARC memory management

4. ARC is always enabled. Never use manual retain/release in new code.
5. Use `__weak` for delegate references and back-references to avoid retain cycles.
6. Use `__strong` (the default) for ownership. Document any intentional strong reference cycles.
7. Use `@autoreleasepool` blocks in tight loops that create many temporary objects.
8. Avoid `performSelector:` with dynamically constructed selectors — it defeats ARC's ability to reason about memory.

## Nullability annotations

9. Annotate all public API parameters and return types with `_Nullable` or `_Nonnull`.
10. Use `NS_ASSUME_NONNULL_BEGIN` / `NS_ASSUME_NONNULL_END` to set the default, then annotate only the nullable exceptions.
11. Incorrect nullability annotations cause Swift optionality mismatches — verify against actual runtime behavior.

## Swift bridging

12. Use `NS_SWIFT_NAME` to provide idiomatic Swift names for Objective-C methods and classes.
13. Use `NS_REFINED_FOR_SWIFT` to hide Objective-C API from Swift and provide a hand-written Swift wrapper with better ergonomics.
14. Minimize the bridging header surface — expose only what Swift actually calls.
15. Prefer Swift extensions on Objective-C types over modifying the original Objective-C class.

## Legacy code modification

16. When modifying existing Objective-C, add nullability annotations to the methods you touch.
17. Add lightweight generics (`NSArray<NSString *> *`) to collection types you touch.
18. Convert completion-handler patterns to Swift async wrappers using `withCheckedThrowingContinuation` on the Swift side rather than rewriting the Objective-C.
19. Do not refactor working Objective-C to Swift unless the change is explicitly scoped as a migration task.

## Property patterns

20. Use `@property` with explicit attributes (`nonatomic`, `copy`, `strong`, `weak`, `readonly`).
21. Use `copy` for `NSString`, `NSArray`, `NSDictionary`, and block properties to prevent mutation by callers.
22. Use `readonly` in the public header, `readwrite` in the class extension for internal mutability.
