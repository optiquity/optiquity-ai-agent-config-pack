---
name: protobuf-patterns
description: Use for Protocol Buffers (Proto3) schema design, field-evolution rules, well-known types, and code-generation conventions — applies whenever a project ships `.proto` files, with or without gRPC.
allowed-tools: Read, Grep, Glob, Bash
---

## Applicability

This skill is loaded for `architect`, `grpc-schema`, `coder`, `reviewer`,
`auditor-architecture`, and `auditor-code` whenever the project contains
Protocol Buffers schemas or protobuf-generated code. The load predicate
is "any host language ∩ project has `.proto` files OR a dependency
manifest lists protobuf tooling" (see
`docs/pack/PLATFORM-SKILLS.md` Intersection table; the canonical
predicate is `scripts/lib/detect.sh::protobuf_marker_detected()`).

The rules apply equally to:

- **gRPC services** (the pack's primary use case — load `protobuf-patterns`
  alongside `grpc-patterns`).
- **Standalone protobuf** — binary file format, IPC payloads, persistent
  storage, log formats, non-gRPC RPC frameworks (Twirp, Connect),
  serialization-only consumers. In these scenarios `grpc-patterns` does
  NOT load; `protobuf-patterns` is the only schema-design skill.

Schema rules in this skill are transport-agnostic. Transport-specific
rules (servicer / handler patterns, error envelopes, deadlines,
streaming semantics) live in `grpc-patterns` and load only when D4=grpc.

## Field numbering invariants

1. Proto3 field numbers must never be reused or renumbered. Once a field
   number has shipped, it is permanent for that message — even after
   the field is removed.
2. Use `reserved` for both the field number and the field name on every
   deletion or rename: `reserved 5, 7, 9 to 11; reserved "old_name";`.
   The compiler enforces no future reuse only when the `reserved`
   declaration is present.
3. Field numbers 1–15 encode in one byte on the wire; reserve them for
   the most frequently set fields. Numbers 16–2047 use two bytes.
   Numbers 19000–19999 are reserved by the Protocol Buffers
   implementation — do not assign fields in this range.
4. Gaps in field numbers are permitted and have no wire-format cost.
   Prefer leaving deleted field numbers as `reserved` rather than
   shifting subsequent numbers down.
5. Do not "renumber to clean up" an existing message — even when no
   active reader depends on a deleted field, persisted historical
   data, log files, and backup snapshots may still contain the old
   wire encoding.

## Backward and forward compatibility

6. Adding a new field with a new number is a backward-compatible change.
   Old code ignores unknown fields; new code reads the default value
   from old payloads. This is the primary evolution mechanism.
7. Removing a field is backward-compatible at the wire level only when
   the field number is added to `reserved`. Without `reserved`, a
   future schema author may reuse the number — silent data corruption
   for any reader still observing the old wire encoding.
8. Type changes are mostly forbidden. The compatible cases are
   narrow: `int32`/`int64`/`uint32`/`uint64`/`bool` are
   mutually-compatible at the wire level (with truncation / sign
   semantics that callers must understand); `sint32`↔`sint64`,
   `fixed32`↔`sfixed32`, `fixed64`↔`sfixed64` are compatible. All
   other type changes (e.g., `string` ↔ `bytes`, scalar ↔ message,
   `enum` ↔ `int32`) are breaking and require a new field number.
9. Renaming a field is wire-compatible (the wire encoding uses field
   numbers, not names) but is a breaking change for JSON serialization
   and for any reflection-based consumer. Treat renames as breaking by
   default unless reflection consumers are known to be absent.
10. Repeated → singular and singular → repeated is a compatible change
    in Proto3 only for primitive types (the wire format is identical);
    for message-typed fields it is a breaking change.
11. Run `buf breaking` against the prior shipped version on every PR
    that touches a `.proto` file. Any reported breaking change requires
    explicit justification, a coordinated client/server release plan,
    and a version bump on the surface that consumes the message.

## Proto3 vs Proto2 differences

12. Proto3 is the default for new schemas; Proto2 only appears when an
    existing project already uses it. Do not mix syntax versions in a
    new schema; in a mixed-version repo, document the rationale for any
    Proto2 file in a `// SYNTAX-RATIONALE:` comment at the top.
13. Proto3 does not have field-level `required` — every scalar field is
    implicitly optional and reads as the type's default value when
    absent. The `proto3 optional` keyword (re-introduced in protoc
    3.15+) restores explicit field presence for genuinely nullable
    scalar fields. Use `proto3 optional` whenever absent-vs-default-zero
    must be distinguishable.
14. Proto3 enums must include a zero value, conventionally
    `*_UNSPECIFIED = 0`. The zero value is the default when the field
    is absent and is the safe value for forward compatibility — readers
    that encounter unknown enum values may surface them as the zero
    value depending on language binding.
15. Default values cannot be customized in Proto3 — every scalar reads
    as the language-default zero when absent. If non-zero defaults
    matter, use `proto3 optional` and have the consumer apply the
    default explicitly.

## `oneof` semantics

16. A `oneof` block models exclusive alternatives — at most one member
    field is set on the wire. Setting a different member clears the
    previously-set one. Use `oneof` for true XOR semantics, not as a
    "tagged union of optionals" — readers cannot distinguish "no
    member set" from "this member set to its default value" without
    explicit `WhichOneof` checks.
17. Adding a field to an existing `oneof` is backward-compatible.
    Removing a field follows the same `reserved` rule as top-level
    field removal.
18. Moving a previously top-level field INTO a `oneof` is a breaking
    change at the API level: old code that read the field as
    independent will continue to work at the wire level, but writing
    the field now clears any other oneof member, changing observable
    semantics. Treat as breaking.
19. Moving a field OUT of a `oneof` is similarly breaking — old
    writers will inadvertently clear other members on assignment;
    new readers lose the exclusivity guarantee.

## Well-known types

20. Use `google.protobuf.Timestamp` for all date/time fields. Reject
    raw string date fields, `int64` epoch fields, and ad-hoc date
    encodings — they reproduce timezone bugs and lose
    sub-second precision uniformly across language bindings.
21. Use `google.protobuf.Duration` for elapsed times and intervals
    rather than `int64` seconds or `double` seconds — same rationale.
22. Use `google.protobuf.FieldMask` for partial-update RPCs (the
    request specifies which fields to update). Document FieldMask
    semantics in the RPC's leading comment — the wire format alone
    does not communicate "merge" vs "replace" semantics for repeated
    or message-typed fields.
23. Use `google.protobuf.Empty` for RPCs with no request or response
    payload rather than empty self-defined messages — it composes
    correctly across language bindings and signals intent.
24. Use `google.protobuf.Any` only when the message type is genuinely
    polymorphic at runtime and the type URL must be carried alongside
    the payload. Prefer `oneof` for closed alternative sets — it
    preserves type safety in generated code.
25. Use the wrapper types (`google.protobuf.StringValue`,
    `Int32Value`, `BoolValue`, etc.) only in legacy schemas predating
    `proto3 optional`. New schemas should use `proto3 optional`
    instead — it produces cleaner generated code and avoids the
    boxing overhead.

## Map types

26. `map<KeyType, ValueType>` is convenient but has a strictly weaker
    compatibility surface than message-typed fields. Map values can
    only be primitive scalars, enums, or messages — not other maps.
    Map keys can only be integral types or `string`.
27. A map field cannot be marked `repeated` — `map<K, V>` is
    semantically `repeated MapEntry { K key = 1; V value = 2; }` and
    the underlying entry message is generated implicitly. To migrate
    a map to a list of entries (or vice versa), use a new field
    number; the wire format is not interchangeable in the general
    case.
28. Map entry order on the wire is unspecified. Code that depends on
    iteration order is non-portable across language bindings and
    across protobuf runtime versions.

## Imports and package conventions

29. Every `.proto` file declares a `package` matching its directory
    structure (e.g., `package myorg.billing.v1;` for
    `proto/myorg/billing/v1/*.proto`). Package collisions across files
    are a hard error; package mismatch with directory structure is a
    soft error that `buf lint` catches.
30. API surfaces that are expected to evolve must include a version
    suffix in the package name (`v1`, `v2`, ...). Version bumps are
    additive — a new version number means a new directory, new
    package, and new generated code; the old version stays shipped
    until consumers migrate.
31. Imports are file-scoped, not package-scoped. Always import the
    specific `.proto` file that defines the type you reference — do
    not import a "barrel" file that re-exports.
32. Do not place more than one service per `.proto` file. Group
    related RPCs in one service per file; split unrelated services
    into separate files in the same package.

## Naming conventions

33. Use snake_case for field names, repeated fields, and oneof names.
    Use PascalCase for messages, services, and enum types.
    SCREAMING_SNAKE_CASE for enum values, with the enum-type prefix
    repeated to avoid collisions across languages where enum values
    occupy the parent scope (e.g., `enum Color { COLOR_UNSPECIFIED =
    0; COLOR_RED = 1; }`).
34. Boolean fields read better as positive predicates: prefer
    `is_active = 1;` over `is_inactive = 1;`.
35. Avoid stuttering type names in field names: `User user = 1;` not
    `User user_object = 1;`.

## Code-generation options

36. Set language-specific options at the top of each `.proto` file
    when the generated namespace must differ from the proto package:
    - `option swift_prefix = "MyOrg";` — prepended to every generated
      Swift type to avoid collisions with platform types.
    - `option java_package = "com.myorg.billing.v1";` — Java's flat
      package layout requires explicit reverse-DNS naming.
    - `option go_package = "github.com/myorg/proto/billing/v1;billingv1";`
      — the path before `;` is the Go module import path; the optional
      identifier after `;` is the package alias.
    - `option csharp_namespace = "MyOrg.Billing.V1";` — for projects
      with C# consumers.
37. These options are part of the schema's API surface — changing
    them after release breaks downstream import statements. Treat
    code-generation option changes as breaking and version-bump
    accordingly.
38. Never hand-edit generated Protobuf code in any language. The
    correct fix for an awkward generated API is a schema change
    (with version bump if the schema is shipped) or a hand-written
    wrapper type that wraps the generated type.

## Tooling

39. Run `buf lint` on every `.proto` change — fix all violations
    before merging. The default `STANDARD` rule set encodes the
    naming and structural rules in this skill.
40. Run `buf format` (or the project's formatter equivalent) to
    normalize whitespace and field ordering — keeps diffs reviewable
    and avoids merge churn.
41. Pin the `buf` version in repo tooling (e.g., `buf.yaml`'s
    `version: v2` plus a documented `buf` CLI version in the README
    or bootstrap script). Newer `buf` versions occasionally tighten
    lint rules; an unpinned upgrade can break CI.
42. The `protoc` plugin chain (the language-specific code generators
    invoked by `buf generate`) must be pinned to compatible versions
    across all consumers — generated code is sensitive to plugin
    version. Document plugin versions in `buf.gen.yaml` or an
    equivalent generator config.

## High-risk changes — flag explicitly

43. Removing a field, even with `reserved`, is high-risk: persisted
    historical data may still contain the field. Surface the change
    in the PR description and confirm no historical-data reader
    depends on it.
44. Changing a field type, even between wire-compatible types, is
    high-risk because the language-binding semantics may differ
    (e.g., `int32` → `int64` is wire-compatible but changes the
    generated Swift / Python / Go types and may overflow downstream
    arithmetic). Surface the change explicitly.
45. Renaming an RPC method, message, enum, or top-level field is
    breaking for JSON serialization and any reflection-based
    consumer. Surface the change explicitly and bump the schema
    version if applicable.
