---
name: swift-concurrency-patterns
description: Use for Swift concurrency design — Modern Swift Concurrency (async/await, structured concurrency, actor isolation, Sendable, Swift 6 strict checking, AsyncSequence / AsyncStream, continuation bridging) and Grand Central Dispatch (DispatchQueue, DispatchGroup, DispatchSemaphore, barrier writes, QoS, DispatchSource, GCD ↔ async-await modernization). Loads as D1-implied for D1 ∈ {ios, macos} alongside `swift-best-practices`.
allowed-tools: Read, Grep, Glob, Bash
---

## Applicability

This skill is loaded for `architect`, `coder`, `reviewer`,
`auditor-architecture`, and `auditor-code` whenever the project's
runtime substrate is Apple (D1 ∈ {ios, macos}). Loading is
**D1-implied** — every Apple project deals with concurrency, so no
marker predicate is required (parallel to the loading mechanism for
`swift-best-practices`; see
`docs/pack/PLATFORM-SKILLS.md` D1 dimensional table).

The rules cover the two concurrency models that coexist in active
Apple codebases:

- **Modern Swift Concurrency** (Swift 5.5+, hardened in Swift 6 with
  strict concurrency checking) — async/await, actors, Sendable,
  structured concurrency, AsyncSequence / AsyncStream.
- **Grand Central Dispatch (GCD)** (Foundation; available since
  iOS 4 / macOS 10.6) — DispatchQueue, DispatchGroup,
  DispatchSemaphore, DispatchSource. Still load-bearing in legacy
  code, in low-level frameworks, and at boundaries with
  C / Objective-C callback APIs.

These rules are Swift- and Apple-platform-specific. Universal
cross-language concurrency principles (actor model, structured
concurrency, cancellation propagation, backpressure) are deferred
to a future Tier 0 `concurrency-architecture` skill; when that
skill ships, this one will reference it for cross-language
principles and continue to own the Swift / Apple specifics here.

Companion skill: `swift-best-practices` carries the language-style
rules that touch concurrency at a glance (`@MainActor` on
ViewModels, `Sendable` for boundary-crossing types, `actor` for
shared state). The substantive concurrency design rules live in
this skill — `swift-best-practices` cross-references here.

## async/await semantics

1. Treat `async` as a contract: an `async` function may suspend at
   any `await` point, may resume on a different executor than the
   caller, and may not assume the surrounding actor isolation
   carries across the suspension. Inspect every `await` for
   reentrancy and isolation reasoning before merging.
2. `await` is a suspension point, not a thread hop. The runtime
   may resume on the same executor or a different one — code
   that depends on a specific thread (UIKit / AppKit calls,
   thread-local storage) must explicitly hop to `@MainActor` or
   the appropriate isolation domain.
3. Mark functions `async` only when they actually suspend. A
   gratuitously `async` function that performs only synchronous
   work forces every caller into an `await` point and fragments
   the call graph for no benefit.
4. Prefer `async throws` over `async` returning a `Result`. The
   throws-based form composes with structured concurrency
   (`TaskGroup` propagates errors), interacts correctly with
   cancellation, and reads more linearly at the call site.
5. Avoid wrapping a synchronous call in `Task { ... }` purely to
   make it "async-looking." That introduces an unstructured task
   with no parent supervision and breaks cancellation propagation.

## Structured concurrency

6. Prefer `async let` for a small, fixed fan-out of concurrent
   subtasks where the parent awaits each result. The compiler
   enforces that every `async let` is `await`ed (or explicitly
   cancelled) before the surrounding scope exits.
7. Use `withTaskGroup` / `withThrowingTaskGroup` for dynamic
   fan-out (loop over an input collection, spawn one child per
   item). Always exit the group via natural completion or
   `group.cancelAll()` — leaking a group leaks its children.
8. Tasks form a tree: a child task is automatically cancelled
   when its parent is cancelled, and an unhandled error in a
   throwing child cancels its siblings in the same group. Code
   that needs to detach from this tree must use `Task.detached`
   and accept the loss of cancellation propagation.
9. `Task { ... }` (unstructured) inherits the surrounding actor
   isolation and the surrounding task's priority but NOT its
   cancellation context. Use `Task` only for fire-and-forget work
   whose cancellation is managed elsewhere.
10. `Task.detached { ... }` inherits nothing — no isolation, no
    priority, no cancellation. Use it only when isolation
    inheritance is actively wrong (e.g., a long-running
    background pipeline started from a `@MainActor` context).
    Document the rationale at the call site.

## Cancellation propagation

11. Check `Task.checkCancellation()` (or `try Task.checkCancellation()`
    inside throwing contexts) at every long-running loop iteration
    and before any expensive operation. Cancellation is cooperative
    — code that does not check is not cancellable.
12. Clean up resources via `withTaskCancellationHandler { ... } onCancel: { ... }`.
    The `onCancel` closure runs synchronously on the cancelling
    thread and must be `Sendable` and minimal — file handles,
    network sessions, and similar must be invalidated here, not in
    a `defer` block (a `defer` runs after `await` resumes, which
    may be too late).
13. Propagate cancellation from upstream APIs that do not natively
    participate (URLSession completion handlers, third-party
    callback APIs) by wiring the bridge inside
    `withCheckedContinuation` / `withCheckedThrowingContinuation`
    and observing `Task.isCancelled` at the resume site.
14. Do not swallow `CancellationError`. A thrown
    `CancellationError` must propagate up to the structured-
    concurrency boundary so the parent task can complete its
    cancellation. Catching and ignoring `CancellationError`
    converts cancellation into work-leak.

## Actor isolation

15. Use `actor` for shared mutable state accessed concurrently.
    The actor serializes all access to its mutable state and
    exposes its API as `async` to non-isolated callers. Convert
    legacy `class` + `DispatchQueue` ownership patterns to
    `actor` when the surface is Swift-only.
16. `@MainActor` on a type isolates every member to the main
    actor — calls from off the main actor become `await`s.
    Apply `@MainActor` to ViewModels, view-bound observable
    types, UIKit / AppKit-touching coordinators, and any type
    whose state is read from SwiftUI views.
17. `@MainActor` on a function (rather than the whole type) lets
    the rest of the type stay non-isolated. Use the function-
    level form for narrow main-actor entry points on otherwise
    nonisolated types (e.g., a delegate method that must run on
    the main actor).
18. `nonisolated` opts a member out of the surrounding type's
    isolation. Use it for stored property accessors that read
    immutable values (e.g., a `let id: UUID` on an actor) and
    for protocol conformances whose requirements are non-isolated
    by declaration.
19. Custom global actors (`@globalActor actor MyDatabase { static let shared = MyDatabase() }`)
    serialize state across instances. Use them for app-wide
    singleton resources whose access pattern matches an actor
    (file I/O queue, persistent-store coordinator, shared
    cache). Do not introduce a global actor when an instance
    actor or `@MainActor` would suffice.
20. Isolated parameters (`func foo(isolated database: MyDatabase)`)
    let a function execute synchronously inside the named actor's
    isolation domain — useful for fast-path helpers that would
    otherwise require an `await`. The caller must already be
    inside (or able to enter) that isolation; misuse re-introduces
    races.
21. Reentrancy: an actor's `async` method MAY suspend and the
    actor MAY admit other work in the gap. Never assume actor
    state is unchanged across `await` inside an actor method —
    re-read state after each suspension or restructure to avoid
    the suspension.

## Sendable conformance design

22. Every type that crosses an actor or task boundary must
    conform to `Sendable`. Value types composed entirely of
    `Sendable` stored properties get conformance synthesized;
    reference types require explicit reasoning.
23. `final class` types with only immutable (`let`) `Sendable`
    properties may declare `Sendable` conformance directly. Any
    mutable property requires either (a) actor isolation, (b)
    locking discipline documented at the type, or (c) the
    `@unchecked Sendable` escape hatch with audited justification.
24. `@unchecked Sendable` is a compiler-silenced unsafe
    conformance. Use only when the type's safety is established
    by external invariant (lock-protected state, single-owner
    transfer, immutable-after-construction). Document the
    invariant at the conformance site — a future reader must be
    able to verify why the unchecked is sound.
25. Closures that escape into a `Task` or `async let` are
    implicitly `@Sendable`. Captured values must be `Sendable`;
    captured mutable references are a compile error under Swift
    6 strict checking. Restructure to capture immutable
    snapshots, pass through actors, or hand off via
    `PersistentIdentifier`-style opaque tokens.
26. Generated Protobuf message types (via `swift-protobuf`) are
    `Sendable` since `swift-protobuf` 1.20+. Verify Sendable
    conformance survives every code-gen pass — silent removal
    breaks the data → presentation actor hop.

## `@preconcurrency` boundaries

27. Use `@preconcurrency import Foo` to import a module written
    against pre-Swift-6 concurrency rules without promoting its
    Sendable / isolation warnings to errors. This is a temporary
    bridge — every `@preconcurrency` import must be tracked with
    a TD-TBD comment naming the upstream issue / version that
    will allow removal.
28. `@preconcurrency` on a protocol declaration tells callers
    "treat my Sendable / actor-isolation requirements as warnings
    until the call site explicitly opts in." Use this only for
    APIs whose callers may not yet be Swift-6-ready; for new
    code, declare protocols with strict Sendable / isolation
    requirements from the start.
29. Removing a `@preconcurrency` annotation is a source-breaking
    change for downstream consumers. Coordinate the removal with
    the consumer migration and bump the package's major version
    if the protocol or import is part of a public surface.

## AsyncSequence and AsyncStream

30. Use `AsyncSequence` for natural producer-consumer streams
    (file lines, network frames, system event feeds) where each
    element is independently consumable. The protocol has a
    single requirement (`makeAsyncIterator()`) and composes with
    `for try await ... in`, `.map`, `.filter`, and the operators
    in `swift-async-algorithms`.
31. Use `AsyncStream { continuation in ... }` to bridge a
    callback / observer API into an `AsyncSequence`. Wire the
    cancellation handler (`continuation.onTermination = { ... }`)
    so the upstream observer is removed when the consumer's
    iteration ends — leaking the observer leaks the producer.
32. Choose buffering policy explicitly:
    `AsyncStream(bufferingPolicy: .unbounded)` is the default
    and a backpressure footgun for high-rate producers. Prefer
    `.bufferingNewest(N)` or `.bufferingOldest(N)` with a
    documented N for any producer whose rate exceeds the
    consumer's processing speed.
33. Typed payload streams (`AsyncStream<ChangeEvent>`) let
    subscribers filter by relevance before crossing actor
    boundaries. Avoid content-less broadcast
    (`AsyncStream<Void>`) when the subscriber must re-fetch
    state on every signal — that pattern forces an actor hop
    plus a fetch on every signal regardless of relevance.
34. `AsyncChannel` (from `swift-async-algorithms`) is a
    competing-consumer rendezvous channel — at most one
    consumer receives each value. Do not use it as a fan-out
    broadcast; use multiple `AsyncStream`s plus an explicit
    multicaster, or `AsyncBroadcastChannel`.

## Data-race avoidance under Swift 6 strict checking

35. Swift 6 `-strict-concurrency=complete` upgrades every
    Sendable / isolation warning to an error. Enable strict
    concurrency package-by-package as the team migrates;
    incremental migration via per-target `swiftSettings` is
    more reliable than an all-at-once flip.
36. The compiler cannot prove the safety of types it cannot
    inspect (Objective-C imports, third-party C-API wrappers,
    pre-Swift-6 dependencies). Wrap such types behind a Swift
    facade that establishes a single isolation contract and
    let strict checking apply uniformly to the facade's API.
37. Mutable global variables are illegal under strict
    concurrency unless they are `let` Sendable, `@MainActor`-
    isolated, or guarded by a global actor. Refactor every
    `var` global to one of these three forms before enabling
    strict checking.
38. Avoid `nonisolated(unsafe)` outside narrow lock-protected
    accessor patterns. The annotation tells the compiler "trust
    me," and silent misuse reintroduces the race the keyword
    was meant to resolve. Document the lock or invariant at the
    declaration.

## Bridging to legacy callback APIs

39. Use `withCheckedContinuation { continuation in legacyApi { result in continuation.resume(returning: result) } }`
    to wrap a single-shot callback API as `async`. The checked
    form crashes on misuse (resuming twice or never) — preferred
    over `withUnsafeContinuation` for non-performance-critical
    paths.
40. Use `withCheckedThrowingContinuation` when the legacy API can
    fail. Pattern: branch on the callback's success / failure
    and call `continuation.resume(returning:)` or
    `continuation.resume(throwing:)`. Resume exactly once on
    every code path.
41. For multi-shot callback APIs (delegate methods, event
    streams), bridge to `AsyncStream` instead of continuations
    — continuations are single-shot. The `AsyncStream`
    constructor's `continuation.yield(_:)` accepts repeated
    values; `continuation.finish()` ends the stream.
42. Continuation safety checklist: every `withChecked*`
    invocation must (a) resume exactly once on every code path,
    (b) handle cancellation by resuming with a thrown
    `CancellationError` if the upstream cannot itself cancel,
    (c) avoid capturing actor-isolated mutable state in the
    callback closure.

## GCD — DispatchQueue type selection

43. `DispatchQueue.main` is the main thread's serial queue. Use
    only for UIKit / AppKit work (or main-actor-equivalent UI
    updates from non-Swift-concurrency code paths). Prefer
    `await MainActor.run { ... }` when the surrounding code is
    Swift-concurrency-native.
44. `DispatchQueue.global(qos:)` provides shared concurrent
    queues at four QoS classes (`.userInteractive`,
    `.userInitiated`, `.utility`, `.background`). Use only for
    short-lived parallel work; long-running tasks on a global
    queue can starve other workloads at the same QoS.
45. Custom serial queues
    (`DispatchQueue(label: "com.example.foo")`) serialize work
    by themselves — historically used as a poor-actor's actor.
    For new Swift-only code, prefer `actor` over a custom
    serial queue; for Objective-C interop, the serial queue is
    still appropriate.
46. Custom concurrent queues
    (`DispatchQueue(label: "...", attributes: .concurrent)`)
    allow parallel reads with serialized writes via the
    `.barrier` flag. Use for reader-writer cache patterns where
    actor reentrancy is undesirable.

## DispatchGroup, DispatchSemaphore, barriers

47. `DispatchGroup` coordinates fan-out / fan-in: enter on each
    spawn, leave on each completion, then `notify(queue:)` or
    `wait()` for completion. Pair every `enter()` with exactly
    one `leave()` — an unbalanced enter blocks the wait
    forever.
48. `DispatchSemaphore` is a counting semaphore for
    serialization across non-Swift-concurrency boundaries. The
    classic `semaphore.wait()` blocks the caller's thread —
    NEVER call `semaphore.wait()` from a Swift Concurrency
    context, the blocked thread can deadlock the cooperative
    thread pool.
49. To gate concurrent work from inside an `async` context,
    prefer `AsyncSemaphore` (e.g., from
    `swift-async-algorithms` or a small in-house equivalent)
    or restructure with `TaskGroup` + a fixed concurrency
    limit. Do not reach for `DispatchSemaphore` from Swift
    Concurrency code.
50. Barrier writes on a custom concurrent queue
    (`queue.async(flags: .barrier) { ... mutate ... }`) wait
    for in-flight reads to drain, then run exclusively, then
    allow new reads. Use for concurrent-read / serial-write
    caches; document the invariant that all writes go through
    the barrier path.

## QoS, escalation, DispatchSource

51. QoS class on a `DispatchQueue` (or `Task`) advises the
    scheduler about urgency. Higher QoS gets more CPU and
    earlier wake-up; lower QoS yields to higher. Choose the
    lowest QoS the work tolerates — over-claiming
    `.userInteractive` for background work can starve UI.
52. QoS is inferred from the spawning context but propagates
    only forward (a low-QoS task can spawn a higher-QoS
    child; the child's QoS does not lower the parent). Use
    explicit QoS at task spawn (`Task(priority: .background) { ... }`)
    when the inferred priority is wrong.
53. Priority inversion mitigation: when a high-QoS task waits
    on work scheduled at a lower QoS, the system temporarily
    boosts the lower-QoS work. Do not rely on this for
    correctness — restructure to avoid the high-on-low wait.
54. `DispatchSource` exposes kernel-event subscriptions (file
    descriptor activity, signals, process state, mach-port
    messages). Use only when the higher-level Foundation /
    System framework wrappers do not cover the need; cancel
    the source explicitly (`source.cancel()`) before releasing
    the last reference.

## Do-not-mix anti-patterns

55. Do not call GCD from inside an `actor`. Submitting work to
    a `DispatchQueue` from an actor method spawns work outside
    the actor's serialization, defeats the actor model, and
    re-introduces the races the actor was meant to prevent.
56. Do not block an `await` with `semaphore.wait()` or
    `DispatchQueue.main.sync(execute:)` from a Swift
    Concurrency task. Both can deadlock the cooperative
    thread pool — restructure with `await` on an async API.
57. Do not capture a `DispatchQueue.main`-targeted closure
    that escapes into a `Task` and then re-hops to the main
    actor; the double-hop is a code smell that usually
    indicates a partial migration. Pick one model per call
    chain.
58. Do not use `@MainActor` and `DispatchQueue.main.async`
    interchangeably in the same call chain. The first is
    isolation, the second is an unstructured async dispatch
    — they have different cancellation, priority, and
    reentrancy semantics. Standardize on `@MainActor` for new
    code and only fall back to `DispatchQueue.main` at GCD
    boundaries.

## Modernization — when to migrate GCD to async/await

59. Migrate a custom serial queue to `actor` when (a) the
    surface is Swift-only, (b) the queue's job is mutual
    exclusion over state, and (c) callers can be made `async`.
    Pure Objective-C consumers block this migration — keep
    the serial queue and document the constraint.
60. Migrate a `DispatchQueue` + completion-handler API to
    `async` when the API has a single-shot completion. Use
    `withCheckedThrowingContinuation` to wrap the legacy
    callback during migration; remove the wrapper once the
    surface is fully `async`.
61. Migrate `DispatchGroup` fan-out / fan-in to
    `withThrowingTaskGroup`. The TaskGroup form composes with
    cancellation, propagates errors, and reads more linearly
    than enter / leave / notify.
62. Do not migrate GCD code that interoperates with a C or
    Objective-C callback API merely for stylistic
    consistency — the `withCheckedContinuation` bridge has a
    real cost (allocation, indirection, harder-to-read stack
    traces). Migrate when the boundary moves to Swift, not
    before.

## High-risk changes — flag explicitly

63. Adding `@MainActor` to an existing type is API-breaking for
    every off-main caller — calls become `await` and the
    surrounding code must already be in an `async` context.
    Surface in the PR description and confirm caller migration.
64. Removing `@unchecked Sendable` (or replacing it with checked
    `Sendable`) requires verifying the type now genuinely meets
    the Sendable contract under strict checking. The compiler
    will surface violations; resolve each by isolation, locking,
    or restructuring — not by re-adding `@unchecked`.
65. Introducing `Task.detached` in a previously structured
    concurrency context loses cancellation and isolation
    inheritance. Surface explicitly — a detached task that is
    not explicitly cancelled by the surrounding lifecycle is a
    leak.
66. Replacing a `DispatchSemaphore`-gated synchronization with
    an `AsyncSemaphore` or `TaskGroup` limit changes the
    runtime profile (cooperative scheduling vs. blocking
    threads). Verify the throughput characteristic on a
    realistic workload before merging.
