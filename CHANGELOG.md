# Changelog

All notable changes to the AI Agent Config Pack are documented here.
Each version is available as a git tag (v1, v2, …).

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
