---
name: security-patterns
description: Use for security review — credential exposure, injection vectors, unsafe deserialization, sensitive data in logs, and platform-specific security patterns.
allowed-tools: Read, Grep, Glob, Bash
---

## Credential exposure

1. No secrets, API keys, tokens, or credentials in source code, config files committed to git, or container image layers.
2. Apple: store credentials in Keychain. Never in UserDefaults, AppStorage, plist files, or the filesystem.
3. Python: use environment variables + a secrets manager for production. Use `pydantic-settings` with gitignored `.env` for local dev only.
4. gRPC auth tokens go in call metadata (HTTP/2 headers), never in Protobuf message fields.
5. Scan for accidentally committed secrets using pre-commit hooks or CI checks.

## Injection vectors

6. SQL injection: always use parameterized queries or ORM query builders. Never concatenate user input into SQL.
7. Command injection: never pass user input to shell execution with shell=True or equivalent. Use argument lists.
8. gRPC field injection: validate all incoming request fields at the handler entry point before passing to business logic.
9. Deep link / URL scheme injection (Apple): validate all URL parameters before processing. Do not trust deep link content as authenticated input.

## Unsafe deserialization

10. Never deserialize untrusted data with unsafe serialization formats. Use schema-enforced formats only.
11. Protobuf deserialization is safe by design (schema-enforced), but validate field values after deserialization — a well-formed message can still contain invalid business data.
12. JSON deserialization: use `Codable` (Swift) or Pydantic (Python) with explicit schemas. Do not deserialize into untyped dictionaries in production code.

## Sensitive data in logs

13. Never log credentials, tokens, passwords, or personally identifiable information (PII).
14. Redact sensitive fields before logging. Use structured logging with explicit field inclusion rather than logging entire request/response objects.
15. gRPC metadata (which may contain auth tokens) must not be logged at INFO level. Use DEBUG level with explicit opt-in.
16. Log sanitization applies to error messages too — stack traces and exception messages may contain sensitive data.

## Supply chain review (dependencies)

17. Scan direct and transitive dependencies for known CVEs on every audit. A CVE in a direct dependency is a Major finding; a CVE in a transitive dependency without a known exploit path is Minor. Both are tracked.
18. Abandoned or deprecated upstream packages are a Major finding even without a specific CVE — they cannot receive security patches.
19. Review license compatibility for every direct dependency against the project's distribution model. GPL contamination in a closed-source product is Critical. Incompatible copyleft in a permissive-licensed library is Major.
20. Pin dependency versions precisely in lock files (`Package.resolved`, `uv.lock`, equivalent). Unpinned dependencies allow silent substitution of malicious versions during install.
21. Verify package provenance where tooling supports it (e.g., package signing, SLSA attestations). A dependency pulled from an unverified source is a Major finding in high-sensitivity projects.
22. Platform-specific tooling for supply chain scanning: Swift → `swift package audit` + GitHub security advisories; Python → `pip-audit` + `safety`; Node.js → `npm audit`. Use the platform skill for the exact commands.

## Platform-specific security

23. Apple: enable App Transport Security. No global `NSAllowsArbitraryLoads`. Scope ATS exceptions to specific domains with documentation.
24. Apple: TLS required for all gRPC connections. Configure grpc-swift channel with TLS. Certificate pinning for production APIs.
25. Apple: declare Privacy Manifests for all required reason APIs and third-party SDK data practices.
26. Apple: request minimum permissions at the moment of first use with clear purpose strings.
27. Python: implement server-side rate limiting in a gRPC interceptor. Return `RESOURCE_EXHAUSTED` with `RetryInfo`.
28. Python: use JWT/OAuth with short-lived access tokens and refresh token rotation. Validate all claims server-side.
29. Both: run dependency security scans regularly. Block known-vulnerable versions.
