---
name: apple-swiftdata-patterns
description: Use for SwiftData (iOS 17+ / macOS 14+) object-store design — `@Model` macro rules, `ModelContainer` / `ModelContext` lifecycle and threading, `FetchDescriptor` construction, relationship traversal performance, schema migration, history tracking, CloudKit sync, and `save()` semantics. Loads via the intersection table when SwiftData markers are present in an Apple project.
allowed-tools: Read, Grep, Glob, Bash
---

## Applicability

This skill is loaded for `architect`, `coder`, `reviewer`,
`auditor-architecture`, and `auditor-code` whenever the project
combines D1 ∈ {ios, macos} with the SwiftData marker. The load
predicate is `D1 ∈ {ios, macos} ∩ swiftdata-marker` (see
`docs/pack/PLATFORM-SKILLS.md` Intersection table; the canonical
predicate is `scripts/lib/detect.sh::swiftdata_marker_detected()`).

SwiftData is Apple's first-party declarative object-store API on top
of SQLite, introduced at WWDC 2023 (iOS 17 / macOS 14). It supersedes
CoreData for new projects on supported OS versions. The rules in
this skill are SwiftData-specific; companion rules for CoreData
(predecessor) and direct SQLite (GRDB / sqlite3) are out of scope
for this skill.

These rules apply at the persistence boundary only. Domain types
(business logic, value objects) must remain free of `@Model` and
SwiftData imports per the universal layer-discipline rule in the
project's trinity (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` —
"Domain layer has zero import dependencies on … SwiftData …").

## `@Model` macro design

1. Apply `@Model` only to data-layer types whose lifetime is owned by
   a `ModelContext`. Never apply `@Model` to a domain entity or a
   view-model — the macro injects `PersistentModel` conformance,
   `Observable` synthesis, and a backing `_$backingData` store that
   make the type unsuitable for cross-layer reuse. Map between
   `@Model` types and domain types at the data-layer boundary.
2. Every `@Model` class is implicitly `final` after macro expansion;
   subclassing is unsupported and produces incorrect schema metadata.
   Compose behavior with separate types or extension methods, not
   inheritance.
3. Stored properties on a `@Model` type must be Swift value types
   (`String`, `Int`, `Date`, `URL`, `Data`, `UUID`), enums whose raw
   value is one of those types, other `@Model` references, or
   `Codable` value-type structs. Reference types other than `@Model`
   peers are not persistable; they must be marked `@Transient`.
4. Mark every property that should NOT round-trip to the store with
   `@Transient`. The macro persists every otherwise-eligible stored
   property by default — silent persistence of derived or cache state
   is a frequent bug source.
5. Use `@Attribute(.unique)` for natural keys (e.g. an externally-
   minted ID, an email address). The store enforces uniqueness at
   `save()` time; conflicting inserts throw at save, not at insert.
   Catch the conflict and surface it as a domain error — do not
   propagate the raw SwiftData error past the data layer.
6. Use `@Attribute(.externalStorage)` for `Data` properties that may
   exceed a few KB (image blobs, large JSON payloads). External
   storage moves the bytes out of the SQLite row and into a sidecar
   file — keeps row size bounded and FetchDescriptor performance
   stable.
7. Use `@Attribute(.spotlight)` only when the property is genuinely
   user-visible content that should appear in Spotlight search.
   Spotlight indexing carries a per-write CPU cost and a privacy
   surface — do not enable it for internal IDs or audit fields.
8. Default deletion rule for a `@Relationship` is
   `.nullify` for to-one and `.nullify` (effectively no-op for the
   inverse collection) for to-many. Choose explicitly:
   `.cascade` deletes related models when the owner is deleted
   (parent → children); `.deny` blocks the parent's deletion when
   children exist; `.noAction` leaves the inverse pointer dangling
   (never use without an explicit reason — a dangling reference
   throws on dereference).
9. Always declare the inverse for a `@Relationship`. The macro can
   sometimes infer inverses for symmetric to-one ↔ to-one
   relationships, but explicit `inverse:` keypaths are mandatory for
   to-many ↔ to-one and many-to-many. An inferred-but-wrong inverse
   silently produces orphaned writes.

## `ModelContainer` and `ModelContext` lifecycle

10. Create exactly one `ModelContainer` per logical store at app
    launch. Pass the container into views via `.modelContainer(_:)`
    or into background work via dependency injection. Multiple
    containers pointing at the same on-disk store produce schema-
    sync warnings and undefined merge behavior.
11. Configure the container with an explicit `ModelConfiguration`.
    The defaults (URL = Application Support, name = bundle id) are
    fine for ship builds; tests must pass an in-memory configuration
    (`isStoredInMemoryOnly: true`) to avoid touching the real store
    and leaking state across runs.
12. The main `ModelContext` is `@MainActor`-isolated. Treat the
    `@Environment(\.modelContext)` instance as a UI-thread resource:
    perform reads / writes that drive a view from the main context
    only. Background work uses a separate context.
13. For background work, create a fresh context with
    `ModelContext(modelContainer)` inside the background actor /
    task. `ModelContext` is **not** `Sendable` — never capture a
    main-thread context inside a background closure. Hand off
    `PersistentIdentifier` values across the boundary instead, then
    re-`fetch` on the background context.
14. Save the background context explicitly before the task completes
    (`try context.save()`). Background context changes do not
    automatically merge into the main context until save commits to
    the underlying store and the main context observes the change
    via the model's `Observable` synthesis.
15. Detach long-running batch jobs into a child `ModelContext`
    (`ModelContext(modelContainer)` from the background actor)
    rather than reusing a request-scoped context. A batch insert of
    10k models on a single context will hold every inserted model
    in memory until save; periodic `try context.save()` plus
    `context.delete(_:)` of processed peers releases memory.
16. `autosaveEnabled` is true by default on the main context.
    Disable it (`context.autosaveEnabled = false`) when you need
    transactional control — autosave commits at view-update
    boundaries and can interleave with explicit `save()` calls in
    surprising ways.

## `FetchDescriptor` construction

17. Use the `#Predicate` macro for all query construction. The
    macro produces type-checked predicates that the store can
    translate to SQL; string-based predicates inherited from the
    NSPredicate world are unsupported and run client-side, defeating
    the index.
18. Pin the result count with `fetchDescriptor.fetchLimit` whenever
    the caller does not need the full result set. SwiftData
    materializes every result row by default — an unbounded fetch on
    a 100k-row table will allocate 100k objects.
19. Set `fetchDescriptor.fetchOffset` only with a stable
    `sortBy:` ordering — pagination over an unsorted set returns
    arbitrary rows on each page because SQLite row order is not
    stable across writes.
20. Pre-compute `SortDescriptor` arrays as constants when the same
    sort is used by multiple fetches; constructing them inline on
    every fetch is harmless for correctness but obscures the sort
    contract from reviewers.
21. Avoid `#Predicate` clauses that call functions or properties on
    the model that are not stored — the predicate macro will refuse
    to compile, and rewriting it to use a stored projection (e.g.
    persist `lowercaseEmail` alongside `email`) is the correct fix.

## Relationship traversal performance

22. Set `fetchDescriptor.relationshipKeyPathsForPrefetching` to the
    keypaths your code traverses immediately after fetch. Without
    prefetching, each `parent.children` access triggers a separate
    SQLite round trip (the classic N+1) — 1000 parents = 1001
    queries.
23. Prefetch only what the call site actually reads. Over-
    prefetching loads unused rows and inflates memory; the
    discipline is to identify the exact keypaths the next code
    block touches and list those.
24. To-many relationships return `Array`-backed collections that are
    materialized in full on first access. For "show me the count"
    UI, persist a `childCount` projection on the parent and update
    it on insert / delete — counting via `parent.children.count`
    materializes the entire collection.
25. Cyclic traversals (A → B → A) materialize both sides on first
    access. Break the cycle at the data layer by exposing a
    domain-side iterator that walks identifiers, not the full
    `@Model` graph.

## Schema migration

26. Every shipped schema must declare a `VersionedSchema` with an
    explicit `versionIdentifier`. Bumping the schema without a
    version identifier produces an unmigrated store on first launch
    after upgrade — the user sees data loss.
27. Use `SchemaMigrationPlan` to chain `MigrationStage` entries
    between adjacent versions. Lightweight stages
    (`MigrationStage.lightweight(...)`) cover additive changes
    (new property, new model, new optional relationship); custom
    stages (`MigrationStage.custom(...)`) cover renames, type
    changes, and required-field additions with a default-value
    closure.
28. A custom `MigrationStage` runs once per device per upgrade. The
    `willMigrate` and `didMigrate` closures see the old and new
    contexts respectively — never assume both schemas are queryable
    inside the same closure.
29. Test every migration with an on-disk fixture from the prior
    schema before shipping. Lightweight migration that "looks
    additive" can still fail when the new schema marks a previously-
    optional property as non-optional with no default; surface
    every such case at code-review time, not at first-launch
    crash time.

## History tracking

30. Enable history tracking via `ModelConfiguration` only when the
    app needs cross-process change observation (CloudKit sync, a
    sharing extension, a background widget). History tracking adds
    write overhead and a separate transaction log table — do not
    enable it speculatively.
31. Read history with `HistoryDescriptor` filtered by token (the
    last-seen change-token from the prior pass). Persist the token
    after each successful pass; replaying from token zero on every
    launch is correct but slow.
32. Prune the history log via the OS-provided
    `deleteHistory(before:)` after the consumer has acknowledged
    the changes. The log grows unbounded otherwise.

## CloudKit sync integration

33. Enable CloudKit sync via `ModelConfiguration(cloudKitDatabase: .private(...))`
    (or `.shared` for collaborative records). Mixed local / CloudKit
    containers are unsupported — the entire schema must be CloudKit-
    compatible.
34. Every CloudKit-synced `@Model` property must be optional or have
    a default value. CloudKit's eventual-consistency model surfaces
    properties as nil during partial sync; non-optional non-default
    properties throw on first read after a remote insert.
35. CloudKit-synced `@Relationship` must be `.nullify` deletion
    rule. `.cascade` and `.deny` are unsupported across the
    CloudKit boundary because peer devices cannot guarantee the
    target's reachability.
36. Schema changes to a CloudKit-synced container require a custom
    `MigrationStage` and a coordinated CloudKit schema deploy in
    the developer portal. The schema-deploy step happens out-of-
    band and must precede the app release that depends on the new
    fields — flag every CloudKit schema change explicitly in the PR.

## Transactionality and `save()` semantics

37. `ModelContext.save()` is the only durability boundary. An
    unsaved insert / update is visible to the same context's
    subsequent reads but invisible to other contexts and absent
    from the on-disk store; a crash before save loses all unsaved
    work.
38. `save()` is atomic per-context — either every pending change in
    the context commits or none do. Cross-context transactions
    are not supported; a workflow that requires atomicity across
    background and main contexts must consolidate the work into a
    single context.
39. Wrap `try context.save()` in error handling at the data layer.
    The throw paths include constraint violations
    (`.unique` collisions), schema validation failures, and disk-
    full conditions — surface each as a typed domain error, not a
    raw SwiftData error.
40. Call `context.rollback()` after a save failure that is not
    user-recoverable. Without rollback, the context retains the
    failing pending changes and the next `save()` re-throws the
    same error.

## Query performance and index hints

41. Add `@Attribute(.indexed)` to properties that appear in
    `#Predicate` filters or `SortDescriptor` keys with high-
    cardinality values. The store creates a SQLite index per
    declaration; queries on indexed properties run in
    `O(log n)` instead of `O(n)`.
42. Composite indexes are not directly expressible in SwiftData;
    the workaround is to persist a precomputed concatenation
    column (`@Attribute(.indexed) var statusAndDate: String`) when
    a multi-column predicate dominates the workload.
43. Profile every list view with Instruments' SwiftData template
    before shipping. The "Slow Queries" lane surfaces missing
    indexes, accidental N+1, and unbounded fetches that didn't
    set a `fetchLimit`.

## High-risk changes — flag explicitly

44. Removing a property from a `@Model` is a destructive schema
    change. Lightweight migration drops the column without
    warning; any user data in the dropped column is gone after
    first launch on the new version. Surface the removal in the
    PR and confirm with the product owner that no rollback is
    expected.
45. Changing a `@Relationship` deletion rule from `.nullify` to
    `.cascade` retroactively makes future deletes destructive for
    every existing parent. The on-disk children survive only
    until the next parent delete; the change cannot be reverted by
    schema rollback. Treat as breaking and flag explicitly.
