---
name: documentation
description: Use when verifying configuration, API behavior, version-specific features, or tool support from official docs. Platform-agnostic research methodology.
allowed-tools: Read, Grep, Glob, WebSearch, Bash
---

This skill defines universal documentation research methodology. Platform-specific source paths, local reference doc locations, and preferred documentation portals come from the project context files (CLAUDE.md, AGENTS.md, GEMINI.md) and the loaded platform skills — not from this skill.

## Research methodology

1. Start with official documentation. Prefer primary sources (vendor developer sites, library READMEs, API references) over blog posts, Stack Overflow, or AI-generated summaries.
2. Verify version-specific behavior. Documentation for version N may not apply to version N+1. Check which version the docs describe and which version the project uses.
3. When official docs are ambiguous, verify behavior by reading the source code or writing a minimal test. Do not assume behavior from documentation alone.
4. Cross-reference multiple sources when evaluating a claim. A single blog post is not sufficient evidence for an architectural decision.

## Source prioritization

5. Check any local reference documentation the project provides before web sources. The project context files (CLAUDE.md, AGENTS.md, GEMINI.md) name the local doc directories and how to keep them current.
6. For language or framework APIs: the official vendor documentation (developer portal, language reference, framework docs) is authoritative.
7. For packages and libraries: the package's own docs and README, then its public issue tracker for known limitations and breaking changes, then its release notes for version-specific behavior.
8. For protocols and standards (HTTP, gRPC, SQL, etc.): the standards body or specification owner's documentation is authoritative.
9. For third-party dependencies: the library's official documentation, then its GitHub (or equivalent) issues for known limitations and breaking changes.

## Reporting findings

10. Separate verified facts from inferences. Label each finding: "Confirmed: [source]" or "Inferred: [reasoning]".
11. When a feature or API is undocumented, state that explicitly. Do not guess behavior — flag it as requiring verification by testing.
12. Include the documentation URL or file path for every claim so it can be re-verified later.
13. When documentation contradicts observed behavior, report both and recommend which to trust (observed behavior wins for implementation decisions; documentation wins for design intent).
