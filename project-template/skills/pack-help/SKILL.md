---
name: pack-help
description: Show all pack commands and colloquial mappings. Run when you need a quick reference for `pm-startup`, `pack tracker *`, `init-project.sh`, `agent-run.sh`, or any other top-level pack verb.
allowed-tools: Bash
---

The user wants to see the full pack verb list and colloquial phrasings. Run
the help script and present its output verbatim to the user.

## Help fragment

!`bash scripts/pack-help.sh`

## Notes

For full documentation, see `docs/pack/PM-CHAT.md`,
`docs/pack/INSTALL-PROCEDURES.md`, and `docs/pack/OPTIONAL-FEATURES.md`.
The shell verb `pack help` (LCD floor) prints the same content as this skill.

This skill replaces the former Gemini-CLI `.gemini/commands/pack-help.toml`
slash-command. Under Antigravity CLI, slash-command behavior is expressed as
a skill: skills in `project-template/skills/<name>/SKILL.md` install to the
workspace skills directory `.agents/skills/<name>/SKILL.md` (the Antigravity
workspace skills path) rather than to `.gemini/commands/*.toml`.
