---
name: api-design
description: Use for gRPC service contract design, HTTP API design, validation boundaries, error shapes, versioning, and backward-compatibility decisions.
---

For gRPC/Proto3 (first-party): one service per .proto file; google.rpc.Status + error_details; Timestamp for dates;
field numbers inviolable; auth in metadata not messages; version with package namespacing; cursor pagination.
For HTTP REST (third-party): explicit Pydantic schemas; consistent error envelopes; URL-prefix versioning; validate at handler.
