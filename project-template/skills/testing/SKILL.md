---
name: testing
description: Use when designing test strategy, choosing test types, organizing test suites, or defining coverage expectations. Platform-agnostic methodology.
allowed-tools: Read, Grep, Glob, Bash
---

## Test pyramid

1. Many unit tests, fewer integration tests, fewest UI/E2E tests. The pyramid is a budget — spend most testing effort where feedback is fastest and cheapest.
2. Unit tests cover domain logic, state transitions, and pure functions. They run in milliseconds with no external dependencies.
3. Integration tests cover boundaries: database adapters, network clients, module seams, transport handlers. They may use real infrastructure (test database, in-process server).
4. UI and E2E tests cover critical user flows only. See `ui-test-strategy` for tool selection.

## Test design

5. Each test verifies one behavior. If the test name requires "and," split it.
6. Test names are self-documenting failure messages. Each test name describes the condition under test and the expected outcome. Language-specific naming syntax comes from the loaded language skills.
7. Tests are deterministic. No dependency on real system time, random seeds, or live network calls. Inject clocks and use test doubles.
8. Use the simplest test double that satisfies the test: stub → fake → spy → mock. Overuse of full mocks indicates too many dependencies.
9. Use protocol-based test doubles for external dependencies (network clients, databases, message queues, third-party APIs). Never hit real endpoints in unit or integration tests.

## Test organization

10. Mirror the source directory structure in the test directory. Tests for a source file live in a corresponding test file using the language's naming convention.
11. Shared test fixtures and helpers live in a dedicated test utilities module, not duplicated across test files.
12. Fast tests (unit) and slow tests (integration, UI) are separable — CI can run fast tests on every push and slow tests on PR merge.

## Coverage and verification

13. Every behavior change requires a corresponding test change. A PR that changes behavior without updating tests is incomplete.
14. Coverage is a regression signal, not a vanity metric. A drop in coverage on changed files indicates missing tests.
15. Snapshot tests are optional. Use them only for complex UI components where they reduce review noise.

## Test framework selection

16. Use the test framework specified by the project's loaded language skills and protocol skills. This skill does not prescribe frameworks — the platform skills do.
17. When multiple frameworks are available for a language, prefer the one the project already uses. Do not mix frameworks within the same language without documented justification.
