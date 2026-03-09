# Verified notes

## Verified from current docs

- Claude Code supports project instructions, settings, hooks, subagents, and skills. Source: Anthropic docs.
- Codex supports layered `AGENTS.md`, project `config.toml`, skills, profiles, and model provider configuration. Source: OpenAI docs.
- Xcode 26.3 uses separate customization directories for Codex and Claude Agent. Source: Apple documentation and forums.
- Xcode supports locally hosted providers by port. Source: Apple documentation.
- Ollama documents Xcode integration. Source: Ollama docs.
- LM Studio documents OpenAI-compatible local endpoints. Source: LM Studio docs.
- `uv`, `ruff`, `pyright`, and `pytest` are current, actively documented Python tooling choices. Sources: Astral docs, Microsoft Pyright docs, pytest docs.
- `pytest-asyncio` is the standard library for async pytest test cases. Source: pytest-asyncio docs.
- `grpcio-testing` provides test utilities for Python gRPC server unit tests. Source: grpc.io Python docs.
- `buf` is the current recommended tool for Proto3 lint, breaking-change detection, and code generation. Source: buf.build docs.
- `google.rpc.Status` and `error_details.proto` are the documented patterns for rich gRPC error responses. Source: google/rpc/status.proto, grpc.io error model docs.
- `google.protobuf.Timestamp` is the documented Protobuf type for date/time fields. Source: Protocol Buffers docs.
- Proto3 field number stability and the use of `reserved` on deletion are explicitly documented requirements. Source: Protocol Buffers Language Guide.
- `GRPCNIOTransportHTTP2` (Swift gRPC NIO stack) supports TLS and is the recommended transport for production. Source: grpc-swift docs.

## Not fully verified

- I did not verify first-party Anthropic documentation that Claude Code directly supports Ollama or LM Studio as native first-class local providers.
- I did not verify an Apple or LM Studio source that explicitly names LM Studio as a supported Xcode provider by name. The verified statement is that Xcode supports locally hosted providers by port and LM Studio exposes a compatible local API.
- The specific `GRPCChannelPool` API surface in grpc-swift may vary by version. Verify against the version pinned in Package.swift before referencing specific method names.
- `pyright --strict` behavior for specific rules may vary between versions. Pin the pyright version in dev dependencies.
