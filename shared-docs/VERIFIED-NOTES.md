# Verified notes

## Verified from official docs

- Claude Code supports repo and user instruction files via `CLAUDE.md`, settings via `settings.json`, project-local overrides via `.claude/settings.local.json`, subagents in `.claude/agents/`, skills with `SKILL.md`, and hooks in settings JSON. Project and user scope precedence is documented.
- Codex supports layered `AGENTS.md`, user and project `config.toml`, role-specific agent config through `[agents]` and `config_file`, skills with `SKILL.md`, and admin-enforced `requirements.toml`.
- Apple says Xcode 26.3 supports agentic coding with Claude Agent and Codex, and Xcode uses separate customization directories for Codex and Claude Agent. Apple also documents locally hosted provider setup in Xcode Intelligence.
- LM Studio documents OpenAI-compatible and Anthropic-compatible local endpoints.
- Ollama documents local service availability on macOS, Windows, and Linux and documents Xcode integration.
- For UI testing, native XCUITest remains the baseline. Maestro documents iOS simulator support and black-box testing via the Accessibility layer. Appium MCP exists, but it is third-party.

## Not fully verified

- I did not verify an Anthropic official page that says Claude Code can directly use Ollama or LM Studio as a first-class local model provider. Do not assume parity with Codex there.
- I did not verify an Apple or LM Studio page that explicitly says Xcode 26.3 supports LM Studio by name. The safer claim is that Xcode supports locally hosted providers by port, and LM Studio exposes compatible local endpoints.
- I did not find an Apple-official MCP-based UI testing tool. Appium MCP is promising, but treat it as third-party.
