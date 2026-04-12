# Xcode companion templates

Machine-level Xcode AI agent configuration. These files are installed per-Mac,
not per-project — they live outside the project repo.

Apple's Xcode 26.3 agent integrations use separate customization directories:

- `~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig/` — Claude agent config
- `~/Library/Developer/Xcode/CodingAssistant/codex/` — Codex agent config

## Installation

```bash
cp ClaudeAgentConfig/CLAUDE.md ~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig/
cp ClaudeAgentConfig/settings.json ~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig/
cp Codex/AGENTS.md ~/Library/Developer/Xcode/CodingAssistant/codex/
cp Codex/config.toml ~/Library/Developer/Xcode/CodingAssistant/codex/
```

Repeat on each Mac. Reinstall after pack version updates.

## Policy

These companion files mirror the v9 project-level policy:
- Both Claude Agent and Codex are allowed to do planning, implementation,
  testing, review, repo operations, and documentation
- Capability is not split by tool identity — defaults may differ but both
  tools can do all work categories
