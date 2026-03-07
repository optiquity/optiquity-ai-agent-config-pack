---
name: ui-test-strategy
description: Use when deciding how to test UI or end-to-end behavior across XCTest, Swift Testing, XCUITest, Maestro, or optional third-party MCP automation.
---

1. Define the behavior under test.
2. Prefer unit and integration tests where they are sufficient.
3. Recommend XCUITest for native UI coverage.
4. Recommend Maestro only when black-box simulator flows reduce effort.
5. Mention Appium MCP only as an optional third-party path when explicit agent-driven automation is needed.
