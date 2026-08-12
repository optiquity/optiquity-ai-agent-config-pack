# SETUP_TEMPLATE.md — New Project Setup Guide Template

<!--
HOW TO USE THIS TEMPLATE

This is a fill-in-the-blanks template for generating a project-specific SETUP.md.

1. The PM chat generates SETUP.md by reading this template and filling in all
   [PLACEHOLDER] values based on the project planning conversation.
2. The resulting SETUP.md goes in the project repo root.
3. This template stays in the pack — it is never copied to project repos.

The PM chat should customize, expand, or remove sections based on the actual project.
Not every section applies to every project. Remove sections that don't apply.
-->

---
*Generated from: supporting-docs/SETUP_TEMPLATE.md — AI Agent Config Pack v11*
*Note to PM chat: Replace all [PLACEHOLDERS] and remove this header before saving.*
---

# [PROJECT_NAME] — Project Setup Guide

Follow these steps to create the GitHub repo, Xcode project, and agent configuration
for [PROJECT_NAME] on a new machine.

---

## Prerequisites

- macOS [MACOS_VERSION]+ installed
- Xcode [XCODE_VERSION] installed and launched at least once
- Git configured: `git config --global user.name "Your Name"`
- GitHub CLI (optional): `brew install gh`
- AI Agent Config Pack v11 available locally

---

## 1. Create the GitHub repository

```bash
# Via GitHub CLI (recommended):
gh repo create [GITHUB_USERNAME]/[REPO_NAME] --private --clone
cd [REPO_NAME]

# Or via GitHub website, then:
git clone https://github.com/[GITHUB_USERNAME]/[REPO_NAME].git
cd [REPO_NAME]
```

---

## 2. Create the Xcode project

<!-- APPLE PROJECTS ONLY — remove this section for Python-only projects -->

1. Open Xcode [XCODE_VERSION]
2. File → New → Project
3. Choose: **[PROJECT_TYPE]** (e.g., macOS → App, iOS → App)
4. Product Name: **[PRODUCT_NAME]**
5. Team: **[TEAM_NAME_OR_NONE]**
6. Organization Identifier: **[BUNDLE_PREFIX]** (e.g., com.yourname)
7. Interface: **SwiftUI**
8. Language: **Swift**
9. Storage: **[STORAGE_CHOICE]** (None recommended unless SwiftData is part of architecture)
10. Testing: **[TESTING_CHOICE]** (None if architecture phase will set up tests)
11. Save to: the cloned repo directory

---

## 3. Set up .gitignore

`init-project.sh` (Step 4 below) merges pack `.gitignore` entries with
any existing project `.gitignore`, appending missing lines under a
header comment `# --- AI Agent Config Pack additions (v11.0) ---`
and deduplicating. Existing entries and their ordering are preserved.
Verify the result after running the script:

```bash
ls -la .gitignore
```

---

## 4. Install the pack via `init-project.sh`

```bash
# Install the pack. The script detects project state, previews every
# operation, asks for confirmation, then copies the unified template +
# METHODOLOGY.md, handles conditional file removal per detected language,
# merges .gitignore entries, and applies chmod +x.
export PACK=/path/to/pack
"$PACK/scripts/init-project.sh" .
```

See `supporting-docs/SETUP-NEW.md` §3 for the detailed walk-through,
including the preview sections to review before typing `y`.

For CI / scripted installs, pass `--yes` to bypass the `Proceed?` confirm
(a non-TTY run without `--yes` declines, naming `--yes`; `--no-interactive`
forces that path). Fresh install only.

---

## 5. Fill in Xcode scheme variables

<!-- APPLE PROJECTS ONLY — remove for Python-only projects -->

Open `scripts/validate.sh` and `scripts/test.sh` and fill in:

```bash
XCODE_SCHEME="[SCHEME_NAME]"
XCODE_DESTINATION="[DESTINATION]"
# Example: "platform=macOS" or "platform=iOS Simulator,name=iPhone 16,OS=latest"
```

**Also set the same values in `.claude/settings.json`** env block — the post-edit hook reads
from the environment, not from inside the scripts:

```json
"env": {
    "AGENT_CAPABILITIES": "...",
    "XCODE_SCHEME": "[SCHEME_NAME]",
    "XCODE_DESTINATION": "[DESTINATION]"
}
```

If your project uses an Xcode-generated directory layout (e.g. `[ProductName]/` and
`[ProductName]Tests/`) rather than SPM's `Sources/` and `Tests/`, also set in `scripts/format.sh`:

```bash
SWIFT_SOURCE_DIRS="[ProductName] [ProductName]Tests"
```

Find valid scheme and destination values:
```bash
xcodebuild -list
xcrun simctl list devices available
```

---

## 6. Install machine-level Xcode companion files

<!-- APPLE PROJECTS ONLY — skip if already installed from a previous project -->

```bash
mkdir -p ~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig
mkdir -p ~/Library/Developer/Xcode/CodingAssistant/codex

cp /path/to/pack/xcode-companion-templates/ClaudeAgentConfig/CLAUDE.md \
   ~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig/
cp /path/to/pack/xcode-companion-templates/ClaudeAgentConfig/settings.json \
   ~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig/
cp /path/to/pack/xcode-companion-templates/Codex/AGENTS.md \
   ~/Library/Developer/Xcode/CodingAssistant/codex/
cp /path/to/pack/xcode-companion-templates/Codex/config.toml \
   ~/Library/Developer/Xcode/CodingAssistant/codex/
```

---

## 7. Customize CLAUDE.md and AGENTS.md

Open `CLAUDE.md` at the project root and update at minimum:
- Architecture pattern choice (MVVM, TCA, MV, etc.)
- [ANY PROJECT-SPECIFIC RULES TO ADD]
- [ANY THIRD-PARTY APIS OR FRAMEWORKS TO NOTE]

---

## 8. Run bootstrap

```bash
./scripts/bootstrap.sh
```

---

## 9. Verify the project builds clean

<!-- APPLE PROJECTS ONLY -->

1. Open `[PRODUCT_NAME].xcodeproj` in Xcode [XCODE_VERSION]
2. Select the `[SCHEME_NAME]` scheme, destination **[BUILD_DESTINATION]**
3. Product → Build (⌘B)
4. Confirm: zero errors, zero warnings

---

## 10. Initial commit

```bash
git add -A
git status   # verify nothing sensitive is staged
git commit -m "Initial project setup: [SUMMARY_OF_WHAT_WAS_ADDED]"
git push origin main
```

---

## 11. Set up the Claude project for PM chat

**Option A — Claude Desktop app:**
1. Go to claude.ai → Projects → New Project
2. Name it: **[PROJECT_NAME]**
3. Connect the GitHub repo via the GitHub connector
4. Sync the GitHub connector — `METHODOLOGY.md` and `PM-CHAT.md`
   are in the project repo (copied in setup Step 4) and searchable after sync.
   No manual upload is needed.
5. Start a new chat and paste Template 1 (PM chat kickoff prompt) from `docs/pack/prompts/pm-chat.md` (Variant: kickoff)

**Option B — Claude Code CLI (non-blocking):**
Follow `supporting-docs/SETUP-NEW.md` Step 10, Option B (Claude Code CLI). Setup is self-contained there.
For daily session management after setup, see `supporting-docs/CLI-PM-SETUP.md`.

---

## 12. What comes next

Once setup is confirmed, the PM chat will guide you through:
- Architecture kickoff (run `./agent-run.sh claude --agent [ARCHITECT_AGENT]` with AGENT_KICKOFF.md)
- Creating ARCHITECTURE.md and stub class hierarchy
- Creating the per-entry implementation plan (`docs/project/implementation-plan/`)
- Beginning Phase 1

Do not begin implementation until ARCHITECTURE.md is reviewed and approved.

---

## Second machine setup

To set up on a second Mac ([SECOND_MACHINE_NAME]):

```bash
git clone https://github.com/[GITHUB_USERNAME]/[REPO_NAME].git
cd [REPO_NAME]
chmod +x agent-run.sh scripts/*.sh
./scripts/bootstrap.sh
```

Then repeat steps 5 (fill in Xcode scheme) and 6 (Xcode companion files) on the new machine.
