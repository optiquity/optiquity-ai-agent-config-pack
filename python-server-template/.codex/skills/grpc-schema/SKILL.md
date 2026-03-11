---
name: grpc-schema
description: Use for Proto3 schema design, field evolution, breaking-change detection, buf validation, and gRPC service contract decisions. Default for: API and schema design (Claude Code).
allowed-tools: Read, Grep, Glob, Bash
---

## Proto3 Schema Rules

1. Verify every deleted or renamed field has a `reserved` entry for both the field number and name.
2. Verify proto3 field numbers have never been reused or renumbered.
3. Verify enum zero value is `*_UNSPECIFIED = 0` on every enum.
4. Verify `google.protobuf.Timestamp` for all date/time fields; reject raw string date fields.
5. Verify auth tokens are NOT in message fields — they belong in call metadata.
6. Verify `google.rpc.Status` + error_details.proto is used for all error envelopes.
7. Check naming: snake_case fields, PascalCase messages and services, SCREAMING_SNAKE_CASE enum values.
8. One service per .proto file. Group related RPCs in one service.
9. Use `proto3 optional` for genuinely nullable scalar fields.
10. Use `FieldMask` for partial update RPCs.
11. Run `buf lint` — fix all violations before merging.
12. Run `buf breaking` against the prior stable version — any breaking change requires explicit justification and a version bump.
13. Never hand-edit generated Protobuf or gRPC Python code.
14. Flag high-risk changes: removing fields, changing field types, renaming RPC methods.

## grpc.aio Server Rules

15. Verify generated Python servicer classes are used with `grpc.aio.server(...)`, not `grpc.server(...)`. Flag synchronous server usage.
16. Verify all servicer handler methods are `async def`. Flag any synchronous handler implementations.
17. Verify handlers call `await context.abort(...)` for error responses, not raise bare Python exceptions.
18. Verify `grpcio-status` is used for rich error responses; flag direct string-only abort calls for error cases requiring structured detail.
19. Verify `grpcio`, `grpcio-tools`, `grpcio-status`, and `grpcio-reflection` are all pinned to the same version in pyproject.toml.
20. Verify server interceptors subclass `grpc.aio.ServerInterceptor`, not the synchronous base class.
21. Verify `asyncio.CancelledError` is not swallowed in streaming handlers.
