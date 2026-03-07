# Recommendations

## Default tool split

### Claude
Use Claude first for:

- planning
- architecture
- design review
- cross-file reasoning
- review of concurrency, API design, state ownership, and dependency boundaries

### Codex
Use Codex first for:

- implementation
- repo operations
- shell-driven transformations
- low-risk generation against local models
- repetitive edits and test iteration

## Model routing policy

Cloud first is the safer default for correctness-sensitive work. For Codex, switch to local OSS models for lower-risk tasks such as:

- code scaffolding
- repetitive refactors with a strong test suite
- documentation generation
- lightweight search and summarization inside the repo

Do not default local models for:

- security-sensitive changes
- architecture decisions
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

- `swift-format` is tied to the Swift project and is the safest neutral formatter choice. citeturn6search0turn6search8
- SwiftLint is still the practical choice for rule-driven style and semantic lint checks. citeturn6search1
