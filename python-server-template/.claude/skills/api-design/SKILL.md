---
name: api-design
description: Use for gRPC service contract design, HTTP API design, validation boundaries, error shapes, versioning strategy, and backward-compatibility decisions.
allowed-tools: Read, Grep, Glob, Bash
---

For gRPC/Proto3 APIs (first-party):
1. One service per .proto file. Group related RPCs in one service.
2. Use google.rpc.Status + error_details.proto for all error envelopes.
3. Use google.protobuf.Timestamp for all date/time fields.
4. Field numbers are inviolable — never reuse or rename deleted numbers, always use reserved.
5. Use proto3 optional for genuinely nullable scalar fields.
6. Use FieldMask for partial update patterns.
7. Design streaming patterns deliberately: unary, server, client, or bidirectional.
8. Auth tokens belong in call metadata, never in message fields.
9. Version services with package-level namespacing (e.g., myservice.v1).
10. Use cursor-based pagination for large collection responses.

For HTTP APIs (third-party integrations or REST fallback):
1. Prefer explicit schemas with Pydantic request/response models.
2. Use predictable, documented status codes.
3. Error envelopes must be consistent across all endpoints.
4. Document backward-compatibility guarantees and breaking-change policy.
5. Version APIs with URL path prefix (e.g., /v1/) or header-based versioning.
6. Validate all inputs at the controller/handler boundary.
