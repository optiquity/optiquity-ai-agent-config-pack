# AI Agent Config Pack — Quick Start

This pack configures Claude Code, Codex CLI, Gemini CLI, and Xcode to
follow your project's architecture rules, coding standards, and
conventions automatically — without repeated prompting.

## Which path are you on?

### New project — you are creating a new repo (no code yet, or only a README)

Follow **[`supporting-docs/SETUP-NEW.md`](supporting-docs/SETUP-NEW.md)**.
You will run `scripts/init-project.sh` from the pack; it copies the agent
files, skills, scripts, and context-file templates into your new project
and prints a PM chat kickoff prompt at the end.

### Existing project — you have an existing project with no AI tooling

Follow **[`supporting-docs/SETUP-EXISTING.md`](supporting-docs/SETUP-EXISTING.md)**.
You will run the same `scripts/init-project.sh`; it detects your existing
source files and docs, previews what it will do, and adds the pack
without overwriting your existing files. The script stops automatically
if any prior AI agent config is detected.

### Pack version upgrade — you already use the pack and want the next major version

Follow the version-specific migration guide in `supporting-docs/`.
For v9 → v10, that is **[`supporting-docs/MIGRATION-v9-to-v10.md`](supporting-docs/MIGRATION-v9-to-v10.md)**.

Version-specific migration guides are always named `MIGRATION-vN-to-vM.md`
and always land in `supporting-docs/`. If you are on an older major
version, first apply the intermediate guide(s) in sequence.

---

See `README.md` for the full version history and repository layout.
