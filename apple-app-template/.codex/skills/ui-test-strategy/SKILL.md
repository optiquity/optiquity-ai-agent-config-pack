---
name: ui-test-strategy
description: Use when deciding between XCTest, Swift Testing, XCUITest, Maestro, or a third-party MCP-based UI automation path.
---

1. Identify what behavior needs confidence.
2. Prefer the cheapest test that proves the requirement.
3. Recommend unit and integration tests before UI automation when possible.
4. Recommend XCUITest for native Apple UI coverage.
5. Recommend Maestro only for black-box simulator flows where it materially lowers cost.
6. Mention Appium MCP only as an optional third-party path when explicit agent-driven automation is desired.
