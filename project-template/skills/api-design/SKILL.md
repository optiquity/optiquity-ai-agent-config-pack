---
name: api-design
description: Use for API design philosophy — contract-first design, versioning, error response design, backward compatibility, and protocol selection guidance. Protocol-specific rules live in dedicated skills (grpc-patterns, rest-patterns, etc.).
allowed-tools: Read, Grep, Glob, Bash
---

## Contract-first design

1. Define the API contract (schema, interface, specification) before writing implementation code. The contract is the source of truth.
2. Both sides (client and server) are generated from or validated against the contract. No hand-written serialization code for first-party APIs.
3. The contract lives in version control alongside the code. Schema files (.proto, OpenAPI spec, GraphQL SDL) are reviewed with the same rigor as code.

## Versioning strategy

4. Version all APIs from day one. Breaking changes are introduced in a new version, never applied to an existing version.
5. Non-breaking additions (new fields, new endpoints, new optional parameters) may be added to existing versions.
6. Support at least two versions simultaneously. Document the deprecation timeline for old versions.
7. Version location depends on the protocol — URL path for REST, package namespace for gRPC, schema directive for GraphQL. The choice is protocol-specific; the discipline is universal.

## Error response design

8. Define a consistent error response shape across all endpoints. Clients should be able to parse any error without knowing which endpoint produced it.
9. Errors carry: a machine-readable code, a human-readable message, and optional structured detail (field validation failures, retry guidance, quota information).
10. Use the protocol's native error mechanism — gRPC status codes, HTTP status codes, GraphQL errors array. Do not invent custom error envelopes that duplicate native semantics.
11. Distinguish between client errors (bad input, unauthorized) and server errors (internal failure, unavailable). Clients retry server errors; they do not retry client errors.

## Backward compatibility

12. Removing a field, endpoint, or operation is a breaking change. Mark as deprecated first, then remove in a future version.
13. Changing a field's type, renaming a field, or changing an endpoint's URL are breaking changes.
14. Adding optional fields, new endpoints, or new enum values (with safe handling of unknown values) are non-breaking changes.
15. Test backward compatibility explicitly — serialize with the old schema, deserialize with the new. A compatibility test catches silent breakage.

## Pagination and large collections

16. All list endpoints support pagination. Unbounded list responses are a denial-of-service vector.
17. Prefer cursor-based pagination over offset-based. Cursors are stable across concurrent modifications.
18. Bound page size server-side. Do not trust client-requested page sizes without a maximum.

## Authentication and authorization

19. Auth credentials (tokens, API keys) are placed in the protocol's standard auth mechanism — HTTP headers for REST, call metadata for gRPC, context for GraphQL. Never in request body fields.
20. Validate auth on every request server-side. Do not cache auth decisions without explicit TTL and revocation handling.

## Protocol selection guidance

21. Use the dedicated protocol skill for implementation patterns. This skill covers design philosophy; protocol skills cover execution:
    - gRPC (internal services, streaming, high throughput) → `grpc-patterns`
    - REST (public APIs, third-party integrations, caching) → `rest-patterns`
    - GraphQL, WebSocket, SSE, AMQP, Webhooks, SOAP → dedicated skills when project requires them (see PLATFORM-SKILLS.md)
