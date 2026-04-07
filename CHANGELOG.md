# Changelog

All notable changes to the AI Agent Config Pack are documented here.
Each version is available as a git tag (v1, v2, …).

---

## v8 — March 2026

### v8.8 — April 7, 2026

**Pack CLI chat support**

- `PACK-CHAT.md` (pack repo root) — startup and operating instructions for the
  pack CLI chat session; covers role, file access strategy, behavioral rules,
  session naming, cross-machine instructions, and RAG ingest guidance. This is
  a pack-specific file — not a template and not copied to coding projects.
- `.claude/skills/pack-startup/SKILL.md` (pack repo root) — `/pack-startup` skill
  for pack chat session orientation: git pull, read BACKLOG.md and CHANGELOG.md,
  check RAG freshness for supporting-docs/METHODOLOGY.md and
  supporting-docs/PROMPT-TEMPLATES.md, report pack version and open BD items.
  Completely independent of the `/pm-startup` skill used by coding projects.
- `.mcp.json.example` (pack repo root) — mcp-local-rag configuration template
  for the pack repo itself; distinct from the template `.mcp.json.example` files
  which include an Xcode entry
- `.gitignore` (pack root) — add `.claude/rag-index/` and `.claude/rag-cache/`

**Corrections**

- `QUICKSTART.md`, `supporting-docs/DEPENDENCIES.md` — corrected embedding model
  download size from ~50MB to ~90MB (actual size per mcp-local-rag package)
- `supporting-docs/DEPENDENCIES.md`, `supporting-docs/CLI-PM-SETUP.md` — added
  mcp-local-rag update instructions (`npx --prefer-online`) and note to re-ingest
  docs after updating
- `QUICKSTART.md`, `PACK-CHAT.md`, `supporting-docs/DEPENDENCIES.md`,
  `supporting-docs/CLI-PM-SETUP.md` — removed invalid `npx -y mcp-local-rag --version`
  pre-warm step (`--version` flag does not exist); embedding model (~90MB) downloads
  automatically on first ingest; update command corrected to `--help`
- `supporting-docs/METHODOLOGY.md` — version string corrected from v8.6 to v8.8
  (file was modified in v8.7 and v8.8 but version header was not bumped)
- `PACK-CHAT.md`, `.claude/skills/pack-startup/SKILL.md` — removed mcp-local-rag
  from pack CLI chat entirely; the pack chat is the author of METHODOLOGY.md and
  PROMPT-TEMPLATES.md, not a consumer — direct read is correct; RAG is appropriate
  only for coding projects that use these files as stable reference
- `.mcp.json.example` (pack root) — deleted; no longer needed without mcp-local-rag
- `.gitignore` (pack root) — removed rag-index/rag-cache entries; no longer needed

---

### New files — methodology infrastructure
- `supporting-docs/METHODOLOGY.md` — universal project development methodology:
  tool roles, standard documents, agent roster, phase structure, 6 workflows,
  audit checkpoints, warning signs, document authoring rules
- `supporting-docs/PROMPT-TEMPLATES.md` — 14 ready-to-use agent prompt templates:
  PM chat kickoff, coder, reviewer, fix cycle, tester, docs-researcher, planner,
  BACKLOG/STATUS update, 4 audit prompts, SETUP.md and AGENT_KICKOFF.md generation
- `supporting-docs/SETUP_TEMPLATE.md` — fill-in-the-blanks template for generating
  a project-specific SETUP.md via PM chat
- `supporting-docs/AGENT_KICKOFF_TEMPLATE.md` — fill-in-the-blanks template for
  the architecture phase kickoff prompt
- `supporting-docs/MIGRATION-v7-to-v8.md` — step-by-step upgrade guide for
  existing v7 projects including exact text for all additive changes
- `supporting-docs/ANDROID-ANALYSIS.md` — analysis of what would be needed for
  Android support; Gemini CLI recommendation for Android
- `supporting-docs/GEMINI-CLI-ANALYSIS.md` — analysis of Gemini CLI integration
- `supporting-docs/origins/Claude-Assisted_Project_Methodology_Guide_v1.md` —
  raw source material (OptiquityTrader methodology guide, archived for reference)
- `METHODOLOGY.md` — copied to all three template roots
- `supporting-docs/guides/ai-agent-config-pack-v8-guide.docx` — v8 setup guide (.docx format; v9+ guides will be .md only)
- `supporting-docs/guides/ai-agent-config-pack-v8-guide.md` — Markdown version of the v8 guide (primary format going forward)

### New agents and skills
- `python-architect` agent (python-server, monorepo) — service layer, grpc.aio
  patterns, repository boundaries, Pydantic placement, ML isolation
- `python-architecture` skill (python-server, monorepo) — 10-item checklist
  mirroring ios-architecture/SKILL.md for Python server concerns

### Renamed
- `ios-architect` → `apple-architect` (apple-app, monorepo) — agent now clearly
  covers iOS, iPadOS, and macOS; all references updated

### Critical fix
- **BD-017** — iOS 26 platform features section now includes availability guard
  requirement: `.glassEffect()` and FoundationModels require `#available(iOS 26, *)`
  / `#available(macOS 26, *)` guards on older deployment targets (apple-app, monorepo,
  both Xcode companion files)

### Updated — all three templates
- `.codex/config.toml` — `post_edit_command` added; Codex now fires
  `agent-post-edit-check.sh` after every file edit (mirrors Claude Code hook)
- `.gitignore` (apple, monorepo) — complete Xcode artifact patterns merged from
  OptiquityTrader: `*.dSYM`, `*.hmap`, `*.ipa`, fastlane, Carthage/Build/
- `.claude/settings.local.example.json` — improved with common allow patterns
  (grep, ls, find, cat, open, WebSearch) and usage comment block
- `scripts/format.sh` — misleading "hook calls this" comment removed; now correctly
  documented as manual/pre-commit only
- `scripts/validate.sh` and `scripts/test.sh` (apple, monorepo) — warning upgraded
  to `⚠️  XCODE_SCHEME is not set` with clear actionable message
- `scripts/agent-post-edit-check.sh` (apple, monorepo) — now runs real
  `xcodebuild build` when XCODE_SCHEME is set; warns clearly when it is not

### Updated — CLAUDE.md and AGENTS.md (apple, monorepo)
- New `## Scripts` section — table of all scripts, when to run, who calls each
- New `## Liskov Substitution Principle` section — generalized from OptiquityTrader
- Typed ID wrapper rule added to Swift coding rules and Design rules
- Architecture section: ARCHITECTURE.md must be completed before production code
- Security: Request minimum required permissions/entitlements added
- Anti-patterns: domain types in transport signatures, hard deletion without
  tombstoning added; mutable global state added to Python section (monorepo)

### Updated — QUICKSTART.md
- Step 4 expanded: scripts/ copy instruction, permissions, bootstrap, full table
- Steps 11–13 added: Create Claude project, start PM chat, generate SETUP.md
  and AGENT_KICKOFF.md via PM chat templates

### Updated — BACKLOG.md
- `V8-BACKLOG.md` renamed to `BACKLOG.md`
- BD-008 through BD-019 added
- Active/Resolved/Deferred section structure introduced

---

## v7 — March 23, 2026

### New
- `shared-docs/ios26/` — Apple's own iOS 26 API docs extracted from the Xcode
  bundle (gitignored; sync locally with `sync-xcode-docs.sh`)
- `sync-xcode-docs.sh` (pack root) — syncs ios26 docs from installed Xcode app;
  re-run after each Xcode update

### Updated
- `docs-researcher` agent (apple, monorepo) — priority lookup: ios26/ first,
  then web search against developer.apple.com
- `CLAUDE.md` (apple, monorepo) — new iOS 26 / Xcode 26.3 platform features
  section (Liquid Glass, FoundationModels, Swift Concurrency)
- `xcode-companion-templates/ClaudeAgentConfig/CLAUDE.md` — Apple-first
  dependency policy
- `xcode-companion-templates/Codex/AGENTS.md` — matching Codex policy
- `QUICKSTART.md` — v7 setup steps including sync-xcode-docs.sh

---

## v6 — March 11, 2026

### New
- `proto/` scaffold in all templates (buf.yaml, buf.gen.yaml, example .proto
  files) — starter schema for gRPC services
- `QUICKSTART.md` (pack root) — end-to-end setup guide
- `error-handling` skill (all templates) — standardised error handling checklist
- `scripts/proto-gen.sh` — runs `buf lint` then `buf generate`; agents call this
  after every .proto edit

### Updated
- All `CLAUDE.md` files — gRPC rules, buf CLI rules, proto anti-patterns
- `scripts/validate.sh` — stricter: runs `xcodebuild build-for-testing` then
  `xcodebuild test` when scheme is configured
- `xcode-companion-templates/ClaudeAgentConfig/CLAUDE.md` — gRPC conventions
- `xcode-companion-templates/Codex/AGENTS.md` — matching Codex conventions

---

## v5 — March 9, 2026

### New
- `python-server-template/` — full template for standalone Python gRPC servers
  (CLAUDE.md, AGENTS.md, all agents + skills, scripts, pyproject.toml,
  pyrightconfig.json, src scaffold)
- `apple-app-plus-python-server-template/` — monorepo template combining Apple
  client and Python server
- `xcode-companion-templates/` added to the pack (previously machine-level only)

### Updated
- All agents — expanded with Python / gRPC / grpc.aio knowledge
- `scripts/` — bootstrap.sh and validate.sh updated for Python support

---

## v4 — March 9, 2026

### New
- `grpc-schema` agent (Claude + Codex) — Proto3 schema review, field evolution,
  buf validation
- `grpc-schema` skill — checklist for schema review tasks
- `.codex/agents/` — all Codex agents converted from YAML/md to `.toml` format

### Updated
- `apple-app-template/CLAUDE.md` — gRPC client rules, grpc-swift-2 patterns
- `apple-app-template/.claude/settings.json` — updated allowlist
- `apple-app-template/.codex/config.toml` — grpc-schema agent integration

---

## v3 — March 9, 2026

### New
- `.gitignore` added to each template (gitignores settings.local.json, .mcp.json,
  generated Protobuf output, .DS_Store, etc.)
- `README.md` added to each template — quick-start instructions for the template

### Changed
- Streamlined to `apple-app-template` only (monorepo template moved to v5
  when Python support matured)
- `shared-docs/` simplified — content consolidated and reduced

---

## v2 — March 6, 2026

### New agents
- `repo-ops` — git operations, script runs, repo housekeeping
- `docs-researcher` — documentation lookup, dependency research

### New skills
- `planning`, `implementation`, `review`, `testing`, `debugging`,
  `documentation`, `repo-ops`, `ios-architecture`

### Updated
- `xcode-companion-templates/` — full `CLAUDE.md` and `AGENTS.md` with project
  conventions and phase routing
- All existing agents — improved descriptions and tool listings
- `shared-docs/VERIFIED-NOTES.md` — expanded verification notes

---

## v1 — March 6, 2026

Initial release.

### Included
- `apple-app-template/` with 5 agents: planner, coder, reviewer, tester,
  ios-architect
- `apple-app-plus-python-server-template/` (early monorepo template)
- `xcode-companion-templates/` (minimal machine-level config)
- 3 skills: architecture-review, dependency-intake, ui-test-strategy
- `shared-docs/` with README, VERIFIED-NOTES, RECOMMENDATIONS
