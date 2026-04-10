---
name: api-design
description: Use for gRPC service contract design, HTTP API design, validation boundaries, error shapes, versioning, and backward-compatibility decisions.
allowed-tools: Read, Grep, Glob, Bash
---

For gRPC/Proto3 (first-party):
1. One service per .proto file.
2. google.rpc.Status + error_details for all errors.
3. google.protobuf.Timestamp for all date/time fields.
4. Field numbers inviolable — never reuse deleted numbers, always use reserved.
5. proto3 optional for nullable scalars. FieldMask for partial updates.
6. Auth tokens in call metadata, never in message fields.
7. Version with package-level namespacing (e.g., myservice.v1).
8. Cursor-based pagination for large collections.

For HTTP REST (third-party integrations or REST fallback):
1. Explicit schemas with Pydantic models.
2. Consistent error envelopes. Predictable status codes.
3. Version with URL prefix (/v1/) or header.
4. Validate all inputs at handler boundary.
