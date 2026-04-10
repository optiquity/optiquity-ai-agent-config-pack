---
name: documentation
description: Use when verifying configuration, API behavior, version-specific features, or tool support from official docs.
allowed-tools: Read, Grep, Glob, WebSearch, Bash
---

## Research methodology

1. Start with official documentation. Prefer primary sources (Apple Developer, Python docs, library README, API reference) over blog posts, Stack Overflow, or AI-generated summaries.
2. Verify version-specific behavior. Documentation for version N may not apply to version N+1. Check which version the docs describe and which version the project uses.
3. When official docs are ambiguous, verify behavior by reading the source code or writing a minimal test. Do not assume behavior from documentation alone.
4. Cross-reference multiple sources when evaluating a claim. A single blog post is not sufficient evidence for an architectural decision.

## Source prioritization

5. For Apple APIs: check `shared-docs/ios26/` first (local Xcode-extracted docs), then developer.apple.com, then WWDC session transcripts.
6. For Python packages: check the package's official docs, then PyPI page for metadata, then GitHub README and issues.
7. For gRPC/protobuf: check buf.build docs, grpc.io, then the relevant language-specific gRPC library docs (grpc-swift, grpcio).
8. For third-party dependencies: check the library's official documentation, then its GitHub issues for known limitations and breaking changes.

## Reporting findings

9. Separate verified facts from inferences. Label each finding: "Confirmed: [source]" or "Inferred: [reasoning]".
10. When a feature or API is undocumented, state that explicitly. Do not guess behavior — flag it as requiring verification by testing.
11. Include the documentation URL or file path for every claim so it can be re-verified later.
12. When documentation contradicts observed behavior, report both and recommend which to trust (observed behavior wins for implementation decisions; documentation wins for design intent).
