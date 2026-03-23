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
- Xcode 26.3 uses a planner/executor architecture internally for its AI coding agent, confirmed by `PlannerExecutorStylePlannerSystemPrompt-gpt_5.idechatprompttemplate` inside the IDEIntelligenceChat framework. Source: Xcode 26.3 app bundle (verified March 2026).
- Xcode's AI base system prompt explicitly instructs the model to prefer Apple frameworks and avoid recommending third-party packages unless already in use. Source: `BasicSystemPrompt.idechatprompttemplate` from Xcode 26.3 app bundle (verified March 2026 via artemnovichkov/xcode-26-system-prompts).
- Xcode 26.3 ships `AdditionalDocumentation/` markdown files inside the IDEIntelligenceChat framework as supplemental AI context. These are the same files used in `shared-docs/ios26/`. Path: `Xcode.app/Contents/PlugIns/IDEIntelligenceChat.framework/Versions/A/Resources/AdditionalDocumentation/`. Source: direct inspection of Xcode 26.3 app bundle (verified March 2026).
- Liquid Glass is the iOS 26 / macOS 26 design language for materials and visual effects, available via `.glassEffect()` and related modifiers in SwiftUI. Source: `shared-docs/ios26/SwiftUI-Implementing-Liquid-Glass-Design.md` (Apple internal documentation, Xcode 26.3).
- FoundationModels is Apple's on-device LLM framework available in iOS 26+. It requires no network access and operates within App Sandbox. Source: `shared-docs/ios26/FoundationModels-Using-on-device-LLM-in-your-app.md` (Apple internal documentation, Xcode 26.3).

## Not fully verified

- I did not verify first-party Anthropic documentation that Claude Code directly supports Ollama or LM Studio as native first-class local providers.
- I did not verify an Apple or LM Studio source that explicitly names LM Studio as a supported Xcode provider by name. The verified statement is that Xcode supports locally hosted providers by port and LM Studio exposes a compatible local API.
- The specific `GRPCChannelPool` API surface in grpc-swift may vary by version. Verify against the version pinned in Package.swift before referencing specific method names.
- `pyright --strict` behavior for specific rules may vary between versions. Pin the pyright version in dev dependencies.
- The exact Liquid Glass modifier API (`.glassEffect()` parameter variants) should be verified against the installed SDK before use in production code — Apple may refine the API in Xcode point releases.
- FoundationModels API surface should be verified against the installed SDK. The framework is new in iOS 26 and may have breaking changes in point releases.
