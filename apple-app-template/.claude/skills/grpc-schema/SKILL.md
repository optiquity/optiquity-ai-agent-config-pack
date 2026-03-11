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
13. Never hand-edit generated Protobuf or gRPC code (Swift or Python).
14. Flag high-risk changes: adding new required-by-convention fields, removing fields, changing field types.

## grpc-swift-2 Client Rules

15. Generated Swift code uses grpc-swift-2 async API. Verify generated files import `GRPCCore`, not `GRPC` (v1).
16. After `buf generate`: confirm generated Swift message types conform to `Sendable`. Log any missing conformances.
17. Verify Swift client code catches `RPCError` (GRPCCore), not `GRPCStatus` (v1 type). Flag any `GRPCStatus` references in new code.
18. All `CallOptions` structs must supply a `.timeout`. Flag call sites where options are omitted or timeout is not set.
19. Verify gRPC stubs are not called directly from SwiftUI Views or ViewModels. Flag violations.
20. Verify channel is created via `GRPCChannelPool` or managed as a single `GRPCClient` per scene lifecycle. Flag per-request channel creation.
