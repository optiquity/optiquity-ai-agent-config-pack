---
name: grpc-schema
description: Use when reviewing or authoring Proto3 schemas, validating field evolution, checking for breaking changes, or designing gRPC service contracts.
---

1. Verify every deleted/renamed field has a `reserved` entry (field number and name).
2. Proto3 field numbers are inviolable — never reused, never renumbered.
3. Enum zero value must be `*_UNSPECIFIED = 0` on every enum.
4. Use `google.protobuf.Timestamp` for all date/time fields. No raw string dates in proto.
5. Auth tokens NOT in message fields — they belong in call metadata.
6. All error envelopes use `google.rpc.Status` + error_details.proto.
7. Naming: snake_case fields, PascalCase messages/services, SCREAMING_SNAKE_CASE enum values.
8. One service per .proto file.
9. Run `buf lint` — fix all violations before merging.
10. Run `buf breaking` — any breaking change requires justification and version bump.
11. Never hand-edit generated Protobuf or gRPC code.
