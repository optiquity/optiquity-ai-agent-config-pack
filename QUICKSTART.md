# AI Agent Config Pack — Quick Start

This pack configures Claude Code, Codex CLI, Gemini CLI, and Xcode to
follow your project's architecture rules, coding standards, and
conventions automatically — without repeated prompting.

> **Recommended first action.** In your CLI, run `/pack-startup` (pack
> repo) or `/pm-startup` (a pack-configured project repo). These bootstrap
> a working session. For the full pack verb list run `pack help` or
> `/pack-help` — see [`pack-ops/HELP-FRAGMENT-PACK.md`](pack-ops/HELP-FRAGMENT-PACK.md).

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

- **v10 → v11:** [`supporting-docs/MIGRATION-v10-to-v11.md`](supporting-docs/MIGRATION-v10-to-v11.md)
- **v9 → v10:** the v9→v10 migrator and guide were sunset in v11. Recover the
  guide from history with `git checkout v10 -- supporting-docs/MIGRATION-v9-to-v10.md`.

Version-specific migration guides are always named `MIGRATION-vN-to-vM.md`
and always land in `supporting-docs/`. If you are on an older major
version, first apply the intermediate guide(s) in sequence.

For the per-file customization-preservation contract that v11 migrators
honor, see [`pack-ops/MERGE-STRATEGY.md`](pack-ops/MERGE-STRATEGY.md).
Tracker (GH Issues) integration is deferred (dormant) per BD-214 —
flat-file per-entry is the sole supported mode; see
[`pack-ops/OPTIONAL-FEATURES.md`](pack-ops/OPTIONAL-FEATURES.md).

---

See [`README.md`](README.md) for the full version history and repository layout.
