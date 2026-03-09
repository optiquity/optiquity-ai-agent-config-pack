# Verified notes

## Verified from current docs

- Claude Code supports project instructions, settings, hooks, subagents, and skills. Source: Anthropic docs.
- Codex supports layered `AGENTS.md`, project `config.toml`, skills, profiles, and model provider configuration. Source: OpenAI docs.
- Xcode 26.3 uses separate customization directories for Codex and Claude Agent. Source: Apple documentation and forums.
- Xcode supports locally hosted providers by port. Source: Apple documentation.
- Ollama documents Xcode integration. Source: Ollama docs.
- LM Studio documents OpenAI-compatible local endpoints. Source: LM Studio docs.
- `uv`, `ruff`, `pyright`, and `pytest` are current, actively documented Python tooling choices. Sources: Astral docs, Microsoft Pyright docs, pytest docs.

## Not fully verified

- I did not verify first-party Anthropic documentation that Claude Code directly supports Ollama or LM Studio as native first-class local providers.
- I did not verify an Apple or LM Studio source that explicitly names LM Studio as a supported Xcode provider by name. The verified statement is that Xcode supports locally hosted providers by port and LM Studio exposes a compatible local API.
