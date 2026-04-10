---
name: ui-test-strategy
description: Use when choosing UI or E2E testing tools, designing UI test suites, or deciding between native and cross-platform test frameworks.
allowed-tools: Read, Grep, Glob, Bash
---

## Decision framework — choose the right tool

1. **XCUITest** — use for iOS/macOS native UI testing. Deepest access to native UI elements, most reliable interactions with iOS-specific components. Requires Xcode and Apple hardware. Best for: iOS-only projects with native UI.
2. **Swift Testing / XCTest** — use for view model and view logic unit tests that don't require a running UI. Faster than XCUITest. Best for: testing view state transitions, navigation logic, and data binding without launching the app.
3. **Maestro** — use for cross-platform E2E testing (iOS, Android, web) from a single YAML test definition. Built-in auto-waiting and flake resistance. Best for: critical user flows on cross-platform projects where maintaining one test suite is more valuable than native depth.
4. **Playwright** — use for web UI and progressive web app testing. Cross-browser support (Chromium, Firefox, WebKit). Best for: web applications, mobile web via device emulation.
5. **Appium / MCP-based automation** — use when agent-driven UI automation is needed or when testing must integrate with external automation infrastructure. Higher setup cost. Best for: enterprise test infrastructure integration, accessibility testing across platforms.

## When to use UI tests vs. other test types

6. Do not use UI tests to verify business logic. Use unit tests for that — they are faster and more reliable.
7. UI tests cover critical user flows: login, checkout, data entry, navigation between major screens. Not every screen needs a UI test.
8. If a UI interaction can be tested by asserting on view model state changes instead, prefer the view model test.
9. Limit UI test suite size to what can run in CI within a reasonable time (target under 10 minutes for the UI suite).

## UI test design

10. Each UI test is independent — no test depends on state left by a previous test. Reset app state at the start of each test.
11. Use accessibility identifiers for element selection, not text labels or position. Text changes break tests; accessibility IDs are stable.
12. Handle asynchronous UI transitions with explicit waits (XCUITest `waitForExistence`, Maestro auto-waiting, Playwright `waitForSelector`). Never use fixed `sleep` delays.
13. Test both happy path and key error states (network failure, empty state, invalid input).

## Snapshot and visual regression testing

14. Use snapshot tests for complex UI components to catch unintended visual regressions. Commit snapshots to source control.
15. Snapshot tests complement, not replace, behavioral UI tests. A snapshot proves the UI looks right; a behavioral test proves it works right.
16. Update snapshots intentionally — a snapshot failure during review is a signal to verify the visual change was intended.
