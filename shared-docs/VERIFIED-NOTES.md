# Verified notes

## Verified from official docs

- Claude Code supports repo and user instruction files via `CLAUDE.md`, settings via `settings.json`, project-local overrides via `.claude/settings.local.json`, subagents in `.claude/agents/`, skills with `SKILL.md`, and MCP config via `.mcp.json` or `~/.claude.json`. Anthropic also documents hooks in settings JSON. citeturn1view0turn1view1turn1view2turn1view9turn5view0turn5view1
- Codex supports layered `AGENTS.md`, user and project `config.toml`, MCP configuration in `config.toml`, skills with `SKILL.md`, and admin-enforced `requirements.toml`. Codex also supports local OSS providers such as Ollama and LM Studio when run with `--oss`, using `oss_provider`. citeturn1view3turn1view4turn2view1turn2view2turn2view3turn2view5turn2view6turn2view7
- Apple says Xcode 26.3 supports agentic coding with Claude Agent and Codex, and Xcode exposes capabilities through MCP for compatible tools. citeturn1view6
- Apple documents coding-intelligence setup and exposes locally hosted provider setup in Xcode's Intelligence settings. The parsed snippet confirms model selection in the Claude Agent setup flow, but the public parser did not return the full page content for the local-hosted section, so that part should be treated as partially verified from Apple and operationally verified by you in Xcode. citeturn3search0turn1view5
- LM Studio documents OpenAI-compatible and Anthropic-compatible local endpoints. citeturn0search3turn0search7turn0search11
- Ollama documents Xcode integration and broader coding-agent integrations, and confirms local service availability on macOS, Windows, and Linux. citeturn3search2turn3search4turn3search6turn3search8
- For UI testing, native XCUITest remains the baseline. Maestro documents iOS simulator support and black-box testing via the Accessibility layer. Appium MCP exists and is useful, but it is not Apple-official. citeturn6search2turn6search6turn6search3
- For formatting and linting, `swift-format` is part of the Swift project, and SwiftLint remains a widely used third-party linter. citeturn6search0turn6search1turn6search8

## Not fully verified

- I did not verify an Anthropic official page that says Claude Code can directly use Ollama or LM Studio as a first-class local model provider. Do not assume parity with Codex there.
- I did not verify an Apple or LM Studio page that explicitly says Xcode 26.3 supports LM Studio by name. The safer claim is that Xcode supports locally hosted providers by port, and LM Studio exposes compatible local endpoints.
- I did not find an Apple-official MCP-based UI testing tool. Appium MCP is promising, but treat it as third-party.
