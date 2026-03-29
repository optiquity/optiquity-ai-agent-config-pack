# Migration Guide — v7 to v8

This guide covers upgrading existing projects from AI Agent Config Pack v7 to v8.

---

## Overview of what changed in v8

v8 is the largest pack version since v5. Changes fall into three categories:

**1. Config fixes and improvements** (Groups 1–2): surgical edits to existing files
**2. New agents and companion files** (Group 3): new files added to templates
**3. Methodology infrastructure** (Groups 4–5): new files that didn't exist before

---

## Files safe to replace entirely

These files contain no project-specific content — replace them wholesale:

| File | Action |
|---|---|
| `xcode-companion-templates/ClaudeAgentConfig/CLAUDE.md` | Replace — reinstall on each Mac |
| `xcode-companion-templates/Codex/AGENTS.md` | Replace — reinstall on each Mac |
| `scripts/validate.sh` | Replace (or apply the ⚠️ warning change manually) |
| `scripts/test.sh` | Replace (or apply the ⚠️ warning change manually) |
| `scripts/agent-post-edit-check.sh` | Replace |
| `scripts/format.sh` | Replace (or remove the misleading hook comment) |
| `.codex/config.toml` | Replace (adds `post_edit_command`) |

To reinstall Xcode companion files:
```bash
cp /path/to/pack/xcode-companion-templates/ClaudeAgentConfig/CLAUDE.md \
   ~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig/
cp /path/to/pack/xcode-companion-templates/Codex/AGENTS.md \
   ~/Library/Developer/Xcode/CodingAssistant/codex/
```
Repeat on each Mac.

---

## Files requiring manual merge

These files contain project-specific customizations that must be preserved.
Apply only the additive changes listed — do not replace the whole file.

### `CLAUDE.md` (apple and monorepo projects)

Apply these additions in order:

**1. iOS 26 availability guard fix** — in the `## iOS 26 / Xcode 26.3 platform features` section,
add this bullet after the FoundationModels bullet:

```markdown
- **Availability guards required.** Liquid Glass and FoundationModels require iOS 26+ /
  macOS 26+. If the project's deployment target is below iOS 26 / macOS 26, all usage of
  `.glassEffect()`, FoundationModels, and related APIs must be wrapped in
  `#available(iOS 26, *)` / `#available(macOS 26, *)` guards. Do not use these APIs as
  unconditional defaults on older deployment targets.
```

**2. Typed ID rule** — in `## Swift and Apple coding rules`, add after the typed errors bullet:
```markdown
- Persistent domain objects carry a typed ID wrapper (a `UUID` wrapped in a named struct).
  Never use raw `UUID` or `String` at domain boundaries.
```

**3. ARCHITECTURE.md emphasis** — in `## Architecture — universal layer discipline`,
update the first bullet to bold the ARCHITECTURE.md requirement:
```markdown
- Choose one primary architecture pattern per app target before writing production code.
  **Document the choice and rationale in `ARCHITECTURE.md` before implementation begins.**
  Do not write production code before the architecture decision is recorded.
```

**4. LSP section** — add a new `## Liskov Substitution Principle` section after `## Security`:
```markdown
## Liskov Substitution Principle

- Every protocol method must have a meaningful implementation in every conforming type.
  Silent no-ops and unconditional "not supported" throws not gated by capability checks
  are violations.
- No domain or presentation layer code may branch on the concrete type behind a protocol
  reference. Use capability flags or feature checks for all implementation differences.
- No concrete data-layer type may be referenced by name in domain or presentation code.
  Only protocol types and domain model types cross layer boundaries.
- When adding a new protocol, verify conformance correctness across all implementing types
  before committing.
```

**5. New anti-patterns** — in `## Anti-patterns — never introduce these`, add:
```markdown
- Domain types appearing in data-layer or transport-layer signatures.
- Hard deletion of user-modifiable objects — use soft-delete (tombstoning) where audit
  or logging requires data retention.
```

**6. Scripts section** — add a new `## Scripts` section before `## Anti-patterns`:
See the apple-app-template CLAUDE.md for the exact table content.

### `AGENTS.md` (apple and monorepo projects)

Apply the same changes mirrored to AGENTS.md format:
- Typed ID rule → add to `## Design rules`
- ARCHITECTURE.md emphasis → update `## Design rules`
- LSP section → add after `## Security rules`
- New anti-patterns → add to `## Anti-patterns — never introduce`
- Scripts section → add before `## Anti-patterns`

### `.gitignore`

Append the Xcode artifact patterns from the v8 template:
```
# Additional Xcode artifacts
*.hmap
*.ipa
*.dSYM
*.dSYM.zip
*.xcuserstate
*.xccheckout
*.xcscmblueprint
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3
timeline.xctimeline
playground.xcworkspace
fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots/**/*.png
fastlane/test_output
Carthage/Build/
```

### `.claude/settings.local.example.json`

Replace with:
```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "allow": [
      "Bash(grep *)",
      "Bash(ls *)",
      "Bash(find *)",
      "Bash(cat *)",
      "Bash(open *)",
      "WebSearch"
    ]
  }
}
```

---

## Agent rename impact (ios-architect → apple-architect)

In any existing project that has the agent config installed:

```bash
# Rename the agent files
mv .claude/agents/ios-architect.md .claude/agents/apple-architect.md
mv .codex/agents/ios-architect.toml .codex/agents/apple-architect.toml
```

Update `.codex/config.toml`:
- Change `[agents.ios_architect]` → `[agents.apple_architect]`
- Change `config_file = "agents/ios-architect.toml"` → `config_file = "agents/apple-architect.toml"`

Update the agent name in `apple-architect.md` frontmatter:
```yaml
name: apple-architect
```

Update `CLAUDE.md` and `AGENTS.md` phase routing tables:
- Replace `ios-architect` with `apple-architect` throughout

Update any saved prompts, scripts, or shell aliases that use `--agent ios-architect`.

---

## New files to add to projects

These are new in v8 and don't exist in v7 projects:

**Add to project repo root:**
```bash
cp /path/to/pack/apple-app-template/METHODOLOGY.md ./METHODOLOGY.md
```

**Upload to app's Claude project knowledge** (not to the repo):
- `METHODOLOGY.md` (from project repo or pack supporting-docs/)
- `supporting-docs/PROMPT-TEMPLATES.md` (from pack)

---

## New agent for Python/monorepo projects

If using `python-server-template` or `apple-app-plus-python-server-template`:

```bash
cp /path/to/pack/python-server-template/.claude/agents/python-architect.md \
   .claude/agents/python-architect.md
cp /path/to/pack/python-server-template/.codex/agents/python-architect.toml \
   .codex/agents/python-architect.toml
mkdir -p .claude/skills/python-architecture
cp /path/to/pack/python-server-template/.claude/skills/python-architecture/SKILL.md \
   .claude/skills/python-architecture/SKILL.md
```

Register in `.codex/config.toml` by adding:
```toml
[agents.python_architect]
description = "Python server architect..."
config_file = "agents/python-architect.toml"
```

Update `CLAUDE.md` and `AGENTS.md` phase routing to reference `python-architect`.

---

## Verify after migration

```bash
chmod +x scripts/*.sh
./scripts/bootstrap.sh
./scripts/validate.sh
```

Confirm: zero errors, zero warnings.

Commit with:
```bash
git add -A
git commit -m "Update AI agent configuration to v8"
git push
```
