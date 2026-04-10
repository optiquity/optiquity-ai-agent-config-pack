---
name: rest-patterns
description: Use for REST/HTTP API implementation — URL design, HTTP methods, status codes, OpenAPI specs, caching, content negotiation, and rate limiting.
allowed-tools: Read, Grep, Glob, Bash
---

## URL and resource design

1. URLs represent resources (nouns), not actions (verbs). Use `/users`, not `/getUsers`.
2. Use plural nouns for collection resources: `/users`, `/orders`, `/products`.
3. Use lowercase letters and hyphens for multi-word segments: `/user-profiles`, not `/userProfiles`.
4. Nest resources to express relationships: `/users/{id}/orders`. Limit nesting to two levels — deeper nesting indicates the resource model needs restructuring.
5. Use query parameters for filtering, sorting, and pagination: `/users?status=active&sort=created_at`.

## HTTP methods

6. GET retrieves a resource. It is safe and idempotent — no side effects.
7. POST creates a new resource. It is not idempotent unless the server implements idempotency keys.
8. PUT replaces a resource entirely. It is idempotent.
9. PATCH partially updates a resource. Send only the fields being changed.
10. DELETE removes a resource. It is idempotent — deleting an already-deleted resource returns 204 or 404, not an error.

## Status codes

11. Use standard HTTP status codes. Do not invent custom codes.
12. 200 OK — successful GET, PUT, PATCH. 201 Created — successful POST with new resource. 204 No Content — successful DELETE.
13. 400 Bad Request — invalid input. 401 Unauthorized — missing or invalid auth. 403 Forbidden — valid auth, insufficient permissions. 404 Not Found. 409 Conflict — state conflict (duplicate, version mismatch). 429 Too Many Requests — rate limit exceeded.
14. 500 Internal Server Error — server fault. 502 Bad Gateway — upstream failure. 503 Service Unavailable — temporary overload.
15. Return a consistent error body for all error responses: `{"error": {"code": "...", "message": "...", "details": [...]}}`.

## OpenAPI specification

16. Maintain an OpenAPI 3.1 specification as the contract for all REST APIs. The spec is the source of truth.
17. Generate client SDKs and server stubs from the spec when possible. Hand-written serialization code drifts.
18. Include request/response examples in the spec for every endpoint.
19. Validate requests against the spec at the server boundary. Reject requests that do not match the schema.

## Caching and performance

20. Use `Cache-Control` headers to declare caching policy. Set `max-age` for cacheable GET responses.
21. Use `ETag` and `If-None-Match` for conditional requests. Return 304 Not Modified when content has not changed.
22. Compress response bodies with gzip or brotli for payloads over a reasonable threshold.
23. For large collections, implement cursor-based pagination. Include `next` and `prev` links in the response.

## Rate limiting and security

24. Implement rate limiting on all endpoints. Return 429 with a `Retry-After` header.
25. Use HTTPS for all endpoints. No plaintext HTTP in production.
26. Validate and sanitize all input. Do not trust client-provided data.
27. Use OAuth 2.1 or API keys for authentication. Do not roll custom auth schemes.
