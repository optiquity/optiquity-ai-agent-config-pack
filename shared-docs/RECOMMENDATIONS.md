# Recommendations

## Default operating model

Both Claude and Codex are configured to support:

- planning
- architecture
- implementation
- refactoring
- debugging
- testing
- code review
- dependency review
- repo operations
- documentation

No category is reserved exclusively for one tool.

## Suggested defaults, not hard limits

### Claude
Prefer Claude first when you want:

- stronger up-front planning
- architecture analysis
- design review
- high-scrutiny code review
- correctness-sensitive reasoning across many files

### Codex
Prefer Codex first when you want:

- implementation
- repo operations
- shell-driven transformations
- local model fallback
- role-driven worker orchestration through project config

These are preferences only. Both tools should remain viable for all major phases.

## Model routing policy

Cloud first is the safer default for correctness-sensitive work. For Codex, switch to local OSS models for lower-risk tasks such as:

- code scaffolding
- repetitive refactors with a strong test suite
- documentation generation
- lightweight search and summarization inside the repo

Do not default local models for:

- security-sensitive changes
- architecture decisions without strong verification
- deep cross-file refactors without tests
- API migration plans
- nuanced UIKit or AppKit edge cases

## Testing stack

Use this order:

1. XCTest and Swift Testing for unit and integration tests
2. XCUITest for native UI regression coverage
3. Maestro for black-box end-to-end simulator flows when you want easier scripting or cross-platform expansion later
4. Appium MCP only if you want agent-driven device control and are willing to own third-party setup complexity

## Formatting and linting

Recommended baseline:

- formatter: `swift-format`
- linter: SwiftLint

Reason:
- `swift-format` is part of the Swift project and is the safest neutral formatter choice.
- SwiftLint remains the practical choice for rule-driven style and semantic lint checks.
