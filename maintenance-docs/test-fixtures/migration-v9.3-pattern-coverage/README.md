# Fixture: migration-v9.3-pattern-coverage

A v9.3 project with **one customization per migration disposition pattern**,
exercising every code path BD-059's fix introduces. This fixture is
project-agnostic by design — any future project's customization shape
decomposes into a subset of these patterns, so a regression here means a
regression for every project, not just one.

The fixture intentionally does NOT model any specific real project. It
is a pattern-coverage matrix.

## Pattern coverage matrix

Each row is exercised by an overlay file under `overlay/`. Each
`FIXTURE-MARKER-*` string is grep-asserted by `scripts/test-migration.sh`
in either the post-migration live file (Pattern S — content preserved
through merge) or in a `.v9-customized` sidecar (Pattern P — content
preserved through sidecar fallback).

| Pattern | File class | Overlay path | Disposition expected | Marker |
|---|---|---|---|---|
| P (trinity) | C1 — CLAUDE.md | `overlay/CLAUDE.md` | `customization-detected-needs-reconciliation` (sidecar) | `FIXTURE-MARKER-CLAUDE` in sidecar |
| P (trinity) | C2 — AGENTS.md | `overlay/AGENTS.md` | sidecar | `FIXTURE-MARKER-AGENTS` in sidecar |
| P (trinity) | C3 — GEMINI.md | `overlay/GEMINI.md` | sidecar | `FIXTURE-MARKER-GEMINI` in sidecar |
| T → P | D1 — PM-CHAT.md | `overlay/docs/pack/PM-CHAT.md` | sidecar | `FIXTURE-MARKER-PMCHAT` in sidecar |
| S (JSON) | K1 — `.claude/settings.json` | `overlay/.claude/settings.json` | `merged-with-customization` (key-merge) | `FIXTURE-SCHEME-MARKER` in `XCODE_SCHEME` of post-migration file |
| S (TOML) | K2 — `.codex/config.toml` | `overlay/.codex/config.toml` | `merged-with-customization` (key-merge with project-removal honored + pack-addition adopted) | `[model_providers.*]` ABSENT post-migration; `[agent_capabilities]` PRESENT post-migration |
| P (pack agent) | A1 — `.claude/agents/coder.md` | `overlay/.claude/agents/coder.md` | sidecar | `FIXTURE-MARKER-A1` in sidecar |
| P (pack skill) | L1 — `.claude/skills/swift-best-practices/SKILL.md` | `overlay/.claude/skills/swift-best-practices/SKILL.md` | sidecar | `FIXTURE-MARKER-L1` in sidecar |
| **OQ-6(b) skill-dir sibling** | sibling — `.claude/skills/swift-best-practices/notes.md` | `overlay/.claude/skills/swift-best-practices/notes.md` | `project-only-file` (preserved in place) | `FIXTURE-MARKER-SIBLING` present at original path post-migration |
| P (pack script) | S2 — `scripts/format.sh` | `overlay/scripts/format.sh` | sidecar | `FIXTURE-MARKER-S2` in sidecar |
| Project-only | scripts/x-fixture.sh | `overlay/scripts/x-fixture.sh` | preserved untouched | file present post-migration |

**Pattern coverage achieved:** Pattern P (7 instances: trinity ×3, PM-CHAT, pack-agent, pack-skill, pack-script) + Pattern S (2 instances: JSON + TOML) + Pattern T→P (1 instance: PM-CHAT post-kickoff) + OQ-6(b) skill-dir-sibling (1 instance) + project-only-file preservation (1 instance).

**Patterns NOT exercised** (left for future fixture extension if needed):
- D4 — PROMPT-TEMPLATES.md customization → `removed-by-design` with sidecar (5-C.1 case). Currently only exercised by clean removal in `migration-v9.3-empty`.
- Improperly-added files (no `x-` prefix, not in pack roster). Not currently flagged by any fixture.
- Multi-tool skill customization (one project customizes the same skill across all three tool dirs differently).

## Expected migration outcome

- Migration completes (exit 0).
- Disposition summary: K reconciliations needed, where K ≥ 6 (C1+C2+C3+D1+A1+L1+S2 = 7).
- Sidecars produced for every Pattern P file class (≥7 sidecars).
- `.claude/settings.json` post-migration retains `FIXTURE-SCHEME-MARKER` (Pattern S key-merge worked).
- `.codex/config.toml` post-migration drops `[model_providers.*]` (project removal honored) and contains `[agent_capabilities]` (pack v10 addition adopted).
- `scripts/x-fixture.sh` and `.claude/skills/swift-best-practices/notes.md` both preserved byte-identical.
- Report's "Reconciliation required" section non-empty.
- Report does NOT contain `customization: none` (the BD-059 truthfulness invariant).

## Why pattern-coverage, not project-shape

The original v10.0 release's verification (`V10-PHASE-4-VERIFICATION.md`
§4.6) was an "OT smoke test" that exercised one specific project. That
project happened not to have customization in the trinity files
according to its sanitization rules — and the verification missed the
defect that destroyed customization in trinity files. The lesson:
project-shape fixtures only catch defects in patterns those specific
projects exercise.

Pattern-coverage fixtures catch every defect in every pattern, regardless
of which projects use which patterns. That's what this fixture is for.
Future projects with shapes the pack hasn't seen before will still be
covered, because their customizations decompose into instances of the
patterns this fixture exercises.
