# Xcode companion templates

Apple's Xcode 26.3 agent integrations are separate from your repo-level Claude and Codex CLI or IDE configs.

Apple documents separate customization directories for Xcode agentic coding:

- `~/Library/Developer/Xcode/CodingAssistant/codex`
- `~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig`

Treat these as user-local. Do not commit real copies of these into app repositories.

The companion files here mirror the repo-level v6 policy:
- both Claude Agent and Codex are allowed to do planning, implementation, testing, review, repo operations, and documentation
- defaults may differ, but capability is not split by tool identity
