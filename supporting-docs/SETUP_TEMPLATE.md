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
*Generated from: supporting-docs/SETUP_TEMPLATE.md — AI Agent Config Pack v8*
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
- AI Agent Config Pack v8 available locally

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

Copy the template `.gitignore` from the pack:

```bash
cp /path/to/pack/[TEMPLATE_NAME]/.gitignore .gitignore
```

---

## 4. Copy agent configuration files

```bash
# Copy the correct template (adjust template name for your project type)
cp -r /path/to/pack/[TEMPLATE_NAME]/. .

# The trailing /. ensures hidden directories are included (.claude/, .codex/)

# Copy METHODOLOGY.md separately — it is not included in the template directory
cp /path/to/pack/supporting-docs/METHODOLOGY.md ./METHODOLOGY.md
```

Make scripts executable:

```bash
chmod +x scripts/*.sh
```

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

1. Go to claude.ai → Projects → New Project
2. Name it: **[PROJECT_NAME]**
3. Connect the GitHub repo via the GitHub connector
4. Upload to project knowledge:
   - `METHODOLOGY.md` (from the project repo root — copied there in setup Step 2)
   - `supporting-docs/PROMPT-TEMPLATES.md` (from the pack)
5. Start a new chat in the project and paste the PM chat kickoff prompt
   (from PROMPT-TEMPLATES.md — "PM chat kickoff prompt" section)

---

## 12. What comes next

Once setup is confirmed, the PM chat will guide you through:
- Architecture kickoff (run `claude --agent [ARCHITECT_AGENT]` with AGENT_KICKOFF.md)
- Creating ARCHITECTURE.md and stub class hierarchy
- Creating IMPLEMENTATION_PLAN.md
- Beginning Phase 1

Do not begin implementation until ARCHITECTURE.md is reviewed and approved.

---

## Second machine setup

To set up on a second Mac ([SECOND_MACHINE_NAME]):

```bash
git clone https://github.com/[GITHUB_USERNAME]/[REPO_NAME].git
cd [REPO_NAME]
chmod +x scripts/*.sh
./scripts/bootstrap.sh
```

Then repeat steps 5 (fill in Xcode scheme) and 6 (Xcode companion files) on the new machine.
