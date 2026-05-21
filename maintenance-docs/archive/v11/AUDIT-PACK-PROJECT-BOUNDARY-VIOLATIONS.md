# AUDIT — pack/project boundary violations (BD-175 Phase 1 Discovery)

**Owner:** docs-researcher #1 (read-only)
**BD:** BD-175 (CODE RED emergency batch)
**Phase:** 1 (DISCOVERY — identification only; no design, no recommendations)
**Date:** 2026-05-18
**Branch:** v11-dev
**HEAD at audit time:** `3d8cc8b` (Batch 19b close)
**v10.1 baseline:** tag `v10.1`
**Commits scanned:** 261 commits across `v10.1..HEAD`

---

## Scope reminder

- IN: root inventory, directory inventory, v11 commit boundary-violation scan, project-side reference scan, path-reference scan, shared-anti-pattern catalog, aggregate counts.
- OUT: design, recommendations, proposals, fixes. Verdicts here are descriptive observations only; architects in Phase 2 decide what to do.

---

## §A — Root-directory inventory

Every file directly at `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/` (the pack-repo root). 18 entries total. Each row gives a verdict (STAYS — name/location dictated by tool/CLI/GitHub convention — or MOVES — relocation candidate with no structural requirement).

| # | Filename | Verdict | Classification (MOVES only) | Evidence |
|---|---|---|---|---|
| 1 | `.DS_Store` | STAYS-IGNORED | — | macOS Finder artifact. Not tracked in git (excluded via `.gitignore`); present on disk but irrelevant to repo identity. No structural decision needed. |
| 2 | `.gitignore` | STAYS | — | Git convention — `.gitignore` is only honored at the repo root and other tracked subdirs; the root `.gitignore` controls pack-repo ignore semantics globally. |
| 3 | `AGENTS.md` | STAYS | — | Codex CLI / Codex-style trinity convention — read at repo root by `codex` and `codex chat` for repo-wide instructions. Pack-trinity (pack ops). |
| 4 | `BACKLOG.md` | STAYS | — | Pack-repo BD tracker mirror. Per pack memory "Per-entry trees vs mirrors", `/backlog/` is source of truth in flat-file mode; `BACKLOG.md` at root is the regenerated mirror. CI Check 32 (`mirror-in-sync`) enforces root location relative to `/backlog/`. Pack-only ops file. |
| 5 | `CHANGELOG.md` | STAYS | — | Pack-repo version-history mirror. Same per-entry-tree contract as BACKLOG (per `/changelog/_rules.md`). Pack-only ops file. CI Check 32 enforces. |
| 6 | `CLAUDE.md` | STAYS | — | Claude Code CLI convention — reads `CLAUDE.md` at repo root for memory/instructions. Pack-trinity (pack ops). |
| 7 | `GEMINI.md` | STAYS | — | Gemini CLI convention — reads `GEMINI.md` at repo root (via `GEMINI.md` hierarchy). Pack-trinity (pack ops). |
| 8 | `HELP-FRAGMENT-PACK.md` | MOVES | PACK-ONLY | Content is the pack-repo verb manifest (pack commands like `pack help`, `pack-architect`, etc.). Read by `scripts/pack-help.sh`. NOT a CLI tool requirement at root — `scripts/pack-help.sh` resolves its path via constant, not root-walk. Per user direction, even `PACK-`-prefixed files at root are not acceptable. |
| 9 | `HELP-FRAGMENT-TRACKER.md` | MOVES | PACK-ONLY (tracker-mode pack verbs) | Content is tracker-mode verb fragment (pack tracker init/enable/etc.). Read by `scripts/pack-help.sh`. Same structural argument as `HELP-FRAGMENT-PACK.md` — script-resolved, not CLI-required. |
| 10 | `LICENSE.md` | STAYS | — | GitHub convention — `LICENSE` / `LICENSE.md` at repo root is the canonical license discovery location (GitHub UI surfaces it on the repo landing page). |
| 11 | `OPTIONAL-FEATURES.md` | MOVES | PACK-ONLY (pack-feature toggles) | Content describes pack-level optional features (tracker integration, etc.). Multiple project-side files reference this with path qualifiers (e.g., `OPTIONAL-FEATURES.md` in HELP-FRAGMENT.md / pack-help SKILL). Not a CLI / GitHub root requirement. |
| 12 | `PACK-AGENTS.md` | MOVES | PACK-ONLY | Pack-only agent routing table for pack-repo development. Per user direction explicitly named: "Root directory currently holds pack-only docs (`PACK-AGENTS.md`, `HELP-FRAGMENT-PACK.md`) that need new homes in pack-only directories — even with `PACK-` prefix, root location is not acceptable" (orchestration plan §2 P-context). |
| 13 | `PACK-CHAT.md` | MOVES | PACK-ONLY | Pack Chat orchestrator operating instructions. Self-described at line 4: "It is specific to the pack repo and is not a template — it is not copied to coding projects." Same root-not-required argument as PACK-AGENTS.md. |
| 14 | `QUICKSTART.md` | MOVES | SHARED-ANTI-PATTERN-CANDIDATE (read by both audiences) | Audience-mixed: addresses "you" (the developer setting up a coding project) but also serves as pack-repo landing-page Quick Start. Multiple references from both pack-only (`HELP-FRAGMENT-PACK.md`) and project-side template files (`project-template/README.md`, `project-template/.gemini/commands/pack-help.toml`). No structural requirement at root, but README.md often points here. |
| 15 | `README.md` | STAYS | — | GitHub convention — repo landing page. Mandatory at root for any GitHub-rendered repo overview. |
| 16 | `tracker.toml.pack-example` | STAYS-OR-MOVES (verify rationale) | PACK-ONLY (if MOVES) | Example pack-tracker config. Counterpart `tracker.toml.example` lives at `project-template/tracker.toml.project-example` (renamed BD-135). User-direction history: BD-135 explicitly disambiguated the filename pair; the rationale recorded was uniqueness, not root-required placement. Whether the pack-tracker example MUST sit at the pack root for `tracker-config.sh` detection is verify-needed — `tracker-config.sh` resolves path by call site, not root-walk, so structural requirement is unclear. Conservative: classify MOVES until verified. |
| 17 | `.claude/` (directory, listed for completeness) | STAYS | — | Claude Code CLI reads `.claude/agents/`, `.claude/skills/`, etc. at repo root automatically. Pack-only context (pack-architect / pack-coder / pack-startup live here). |
| 18 | `.codex/`, `.gemini/`, `.github/` (directories, completeness) | STAYS | — | Same logic — each CLI / GitHub reads its dotted dir at repo root. Pack-only context at root level (project-template has its own parallel dotted dirs). |

**§A counts:** Files at root (incl. dotted dirs): 18 entries. STAYS: 8 files (`.DS_Store`, `.gitignore`, `AGENTS.md`, `BACKLOG.md`, `CHANGELOG.md`, `CLAUDE.md`, `GEMINI.md`, `LICENSE.md`, `README.md`) + 4 dotted dirs (`.claude/`, `.codex/`, `.gemini/`, `.github/`) = 12 STAYS (counting `.DS_Store` as STAYS-IGNORED). MOVES: 6 files (`HELP-FRAGMENT-PACK.md`, `HELP-FRAGMENT-TRACKER.md`, `OPTIONAL-FEATURES.md`, `PACK-AGENTS.md`, `PACK-CHAT.md`, `QUICKSTART.md`, plus conditionally `tracker.toml.pack-example`). All MOVES candidates classify as PACK-ONLY except `QUICKSTART.md` (SHARED-ANTI-PATTERN-CANDIDATE — audience-mixed).

---

## §B — Directory inventory + classification

Every directory in the pack repo (excluding `.git/`, `node_modules/`, `__pycache__/`, generated dirs). Classified as PACK-ONLY, PROJECT-ONLY, or SHARED-ANTI-PATTERN.

### Top-level subtrees

| # | Directory path | Classification | Evidence note |
|---|---|---|---|
| B1 | `.claude/` (root) | PACK-ONLY | Holds pack-* agents (`pack-architect`, `pack-coder`, `pack-planner`, `pack-reviewer`, `pack-docs-researcher`) and pack-side skills (`architecture-review`, `commit-discipline`, `dependency-intake`, `documentation`, `implementation-report`, `pack-help`, `pack-startup`, `planning`, `review`, `verification-harness`). Read by Pack Chat (the Claude Code chat operating ON the pack repo). |
| B2 | `.codex/` (root) | PACK-ONLY | Parallel pack-side Codex configuration — `.toml` variants of B1 contents. |
| B3 | `.gemini/` (root) | PACK-ONLY | Parallel pack-side Gemini configuration — `.md` variants of B1 contents + Gemini-specific commands (`pack-help.toml`, `pack-startup.toml`). |
| B4 | `.github/` (root) | SHARED-ANTI-PATTERN | Mixed: `.github/workflows/validate-pack.yml` is pack-only CI infrastructure; `.github/ISSUE_TEMPLATE/{config.yml,inbound.yml,work-item.yml}` are issue forms — pack-only IN THIS DIRECTORY (they govern pack-repo issue intake) but BD-063 also shipped the same forms to `project-template/.github/ISSUE_TEMPLATE/` for client repos. Diff between root and project-template versions confirms they differ (`diff -q` finds all three pairs differ at HEAD), so they are not byte-identical mirrors. Classification: pack-only by content + location (root .github = pack-repo only). Anti-pattern signal: the parallel project-template/.github/ structure forces lockstep edits in some BDs (e.g., BD-063 shipped both in one commit). |
| B5 | `maintenance-docs/` | PACK-ONLY | All design / research / implementation artifacts for pack development. Contains `archive/`, `guides/`, `origins/`, `v11-implementation/`, `v11-research/`. Never shipped to client projects. |
| B6 | `maintenance-docs/archive/` | PACK-ONLY | Archived pack design docs (v9/v10/v11 working artifacts). |
| B7 | `maintenance-docs/archive/v10-working/` | PACK-ONLY | Working v10 archive. |
| B8 | `maintenance-docs/archive/v11/` | PACK-ONLY | Working v11 archive (Pattern B sweep at version close). |
| B9 | `maintenance-docs/guides/` | PACK-ONLY (historical reference) | Contains `ai-agent-config-pack-v8-guide.md` — header explicitly marks "SOURCE MATERIAL — DO NOT USE DIRECTLY IN PROJECTS". |
| B10 | `maintenance-docs/origins/` | PACK-ONLY | Original methodology / config-file source materials (pre-v8). Reference-only. |
| B11 | `maintenance-docs/v11-implementation/` | PACK-ONLY | All v11 BD implementation artifacts (ARCHITECTURE-*, IMPLEMENTATION-REPORT-*, PACK-REVIEW-*, PLAN-*, RESEARCH-*, AUDIT-*, etc.). 126 entries. |
| B12 | `maintenance-docs/v11-implementation/CLEANUP-INPUTS-BATCH-19C/` | PACK-ONLY | Pack-internal cleanup inputs. |
| B13 | `maintenance-docs/v11-research/` | PACK-ONLY | All v11 pre-implementation research / architecture docs (ARCHITECTURE.md, ARCHITECTURE-V*, DESIGN-BRIEF, EXTERNAL-RESEARCH, RESEARCH-AUDIT, etc.). |
| B14 | `maintenance-docs/v11-research/templates-archive/v11.0/{bd-v11.0,forms,inbound-v11.0,phase-epic-v11.0,phase-task-v11.0,td-v11.0}/` | PACK-ONLY | Frozen v11.0 schema templates. Reference-only for the pack itself; client projects do not consume from here. |
| B15 | `project-template/` | PROJECT-ONLY | Top-level — files installed to client project root by `init-project.sh` (and refreshed by `migrate-v10-to-v11.sh`). |
| B16 | `project-template/.claude/` | PROJECT-ONLY | Client-installed Claude configuration: `.claude/agents/` (architect, auditor-*, coder, docs-researcher, grpc-schema, planner, repo-ops, reviewer, tester), `.claude/skills/` (pack-help, pm-startup). |
| B17 | `project-template/.codex/` | PROJECT-ONLY | Parallel client-installed Codex configuration. |
| B18 | `project-template/.gemini/` | PROJECT-ONLY | Parallel client-installed Gemini configuration. |
| B19 | `project-template/.github/` | PROJECT-ONLY | Client-installed issue templates. Lockstep-parallel with root `.github/ISSUE_TEMPLATE/`. |
| B20 | `project-template/docs/` | PROJECT-ONLY (audience signal mixed at second level) | Contains `pack/` (pack-side concerns expressed for client consumption, e.g., PM-CHAT.md) and `project/` (per-entry trees for project's own backlog/changelog/plan). |
| B21 | `project-template/docs/pack/` | PROJECT-ONLY (but anti-pattern naming — see §F) | Client-side directory NAMED `pack/`. Contains HELP-FRAGMENT.md, HELP-FRAGMENT-TRACKER.md, PACK-FEEDBACK.md, PLATFORM-SKILLS.md, PM-CHAT.md (the PROJECT-SIDE PM Chat counterpart to the pack-side PACK-CHAT.md), plus `prompts/` subdir for project-side agent invocation prompts. The directory NAME `pack/` is misleading — its contents are project-side artifacts about pack-related concerns (the SSOT for "Pack agent roster" lives here at PM-CHAT.md:47). |
| B22 | `project-template/docs/pack/prompts/` | PROJECT-ONLY | Project-side agent invocation prompts (architect, coder, docs-researcher, planner, pm-chat, reviewer, tester). NOT pack-side `pack-*` agent prompts. |
| B23 | `project-template/docs/project/` | PROJECT-ONLY | Project's per-entry trees (`backlog/`, `changelog/`, `implementation-plan/`). |
| B24 | `project-template/docs/project/{backlog,changelog,implementation-plan}/` | PROJECT-ONLY | Per-entry tree source-of-truth for the project's own work-tracking (mirrors project's regenerated monoliths). |
| B25 | `project-template/proto/` | PROJECT-ONLY | Protocol buffer source templates installed to client. Contains `common/v1/`, `example/v1/`, `buf.gen.yaml`, `buf.yaml`. |
| B26 | `project-template/scripts/` | PROJECT-ONLY | Client-installed scripts: bootstrap-{python,swift}.sh, format/test/validate-*.sh, proto-gen.sh, agent-post-edit-check.sh. |
| B27 | `project-template/server/` | PROJECT-ONLY | Python server source templates (`src/app/`, `tests/`). |
| B28 | `project-template/skills/` | PROJECT-ONLY | Client-installed skill files (canonical SKILL.md source-of-truth; the per-CLI `.claude/skills/`, `.codex/skills/`, `.gemini/skills/` are merged from these by `init-project.sh`). Contains 35 skill subdirs (api-design, apple-architecture-core, apple-swiftdata-patterns, architecture-review, audit-methodology, c-language, cpp-language, debugging, dependency-{intake,python,swift}, deployment-{apple,python}, documentation, error-handling, grpc-patterns, implementation, ios-architecture, macos-architecture, objc-language, planning, pm-startup, protobuf-patterns, python-{best-practices,data-architecture,observability-patterns,server-architecture}, repo-ops, rest-patterns, review, security-patterns, swift-{best-practices,concurrency-patterns}, testing, ui-test-strategy). |
| B29 | `scripts/` (root) | PACK-ONLY | Pack-repo utility scripts. Includes `init-project.sh` (installs project-template into client repos), `migrate-v10-to-v11.sh`, `validate-pack.py`, `add-capability.sh`, etc. Tooling that runs IN the pack repo or ABOUT the pack repo. |
| B30 | `scripts/lib/` | PACK-ONLY | Pack-internal helpers (`migrator-core.sh`, `tracker-*.sh`, `recommendation.sh`, etc.). |
| B31 | `scripts/lib/migrate-v10-to-v11/` | PACK-ONLY | Per-stage migrator helper functions (BD-119 framework adapters: checkpoint.sh, decompose.sh, gates.sh, etc.). |
| B32 | `scripts/lib/per-entry/` | PACK-ONLY | Per-entry tree helpers (BD-167 family). |
| B33 | `scripts/persona-contracts/` | PACK-ONLY | Persona contract scripts for migration personas (contract-greenfield.sh, contract-mid-dev.sh, contract-migration.sh). |
| B34 | `scripts/tests/` | PACK-ONLY | Pack-only test infrastructure (test runners for migrator, tracker, init, recommendation, per-entry, etc.). |
| B35 | `scripts/tests/fixtures/` | PACK-ONLY | Test fixtures consumed by `scripts/tests/`. |
| B36 | `scripts/__pycache__/` | IGNORED-GENERATED | Python bytecode cache. Excluded per `.gitignore`. |
| B37 | `supporting-docs/` | SHARED-ANTI-PATTERN | Mixed audience: most files are project-side (audience = project setup / methodology / migration / dependencies — installed to client per `INSTALL-PROCEDURES.md` and `init-project.sh`), BUT two files are pack-only by content despite living here: `CONCEPTUAL-REVIEW-METHODOLOGY.md` (pack-internal review methodology — references Pack Chat, pack-architect, pack-reviewer) and `DRY-RUN-MIGRATION.md` (pack-repo tooling for org maintainers). Plus `MERGE-STRATEGY.md` self-describes "Pack-shipped agent files (e.g., `pack-architect.md`, `pack-reviewer.md`)" — a TYPE-4 contamination if MERGE-STRATEGY is project-side. The pack memory trinity rule explicitly classifies `supporting-docs/` as PACK-PRODUCT ("Pack ops files NEVER mixed into pack product files (`project-template/`, `supporting-docs/`)") but the rule is silently violated by the pack-only methodology docs that landed here. |
| B38 | `test-fixtures/` (root) | PACK-ONLY | Pack-test infrastructure: `build.sh`, `manifest.txt`, six fixtures (existing-project-mid-dev, v10-minimal, v10-realistic-ot, v11-flat-file, v11-realistic-ot, v11-tracker-on, v11-trinity-marker-prepped). Note: each fixture sub-repo is itself a git repo with `.claude`/`.codex`/`.gemini` contents — those are simulated client-project trees inside the fixture, NOT pack-repo content. |
| B39 | `test-fixtures/{existing-project-mid-dev,v10-*,v11-*}/` | PACK-ONLY (fixture content simulates client projects) | Each fixture is pack-only as a fixture (input to pack tests); the content within each fixture simulates a client project. |
| B40 | `vscode-companion-templates/` | PROJECT-ONLY (machine-installed) | Machine-level VS Code config (`.vscode/settings.json`, etc.). Installed per-Mac to client developer machines, not into project repos. README explicit. |
| B41 | `vscode-companion-templates/.vscode/` | PROJECT-ONLY | Per the above. |
| B42 | `xcode-companion-templates/` | PROJECT-ONLY (machine-installed) | Machine-level Xcode AI agent config. Per Xcode 26.3 conventions — installed to `~/Library/Developer/Xcode/CodingAssistant/`. |
| B43 | `xcode-companion-templates/ClaudeAgentConfig/`, `xcode-companion-templates/Codex/` | PROJECT-ONLY | Sub-trees of B42. |

**§B counts:** ~43 logical directory entries (excluding `.git`, `__pycache__`, generated). PACK-ONLY: B1, B2, B3, B5-B14, B29-B35, B38, B39 = 26 entries. PROJECT-ONLY: B15-B28, B40-B43 = 16 entries. SHARED-ANTI-PATTERN: B4 (`.github/`), B37 (`supporting-docs/`) = 2 entries. IGNORED-GENERATED: B36 (`scripts/__pycache__/`) = 1 entry.

**Cross-cutting anti-pattern signal not captured per-row but worth flagging here:** the parallel `.claude/` (root, pack-only) vs `project-template/.claude/` (project-only) pair is structurally parallel-by-design, not a shared anti-pattern. Same for `.codex`, `.gemini`. The `.github/` pair (root vs project-template/.github/) IS an anti-pattern because the two diverge (diff -q confirms differing files), forcing lockstep maintenance (e.g., BD-063 shipped both).

---

## §C — v11 commit audit for boundary violations

Scan: 261 commits from `v10.1..HEAD` (v11-dev branch).

**Classification taxonomy applied to every commit:**
- PACK-ONLY commit: touches only pack-only paths (root trinity, root pack-* docs, `.claude/`, `.codex/`, `.gemini/`, `.github/`, `maintenance-docs/`, `scripts/`, `test-fixtures/`, root `BACKLOG`/`CHANGELOG`/`OPTIONAL-FEATURES`/`HELP-FRAGMENT-*`, etc., and `supporting-docs/`).
- PROJECT-ONLY commit: touches only `project-template/` paths.
- MIXED commit: touches both pack-only and project-template paths in the same commit.

**Aggregate (before per-finding analysis):**
- PACK-ONLY: 216 commits
- PROJECT-ONLY (touches only `project-template/`, no pack-side change): 7 commits
- MIXED (touches both buckets in same commit): 38 commits

**Per-finding analysis below targets MIXED commits primarily** (these are the structural mixing-points). PACK-ONLY commits that imported pack-only-style content into shared/project-side files are also examined where surfaced by §D.

### Violation types

- **TYPE-1:** Project-side file modified during pack-only batch (commit subject claims pack-only scope but commit also edits `project-template/` or `supporting-docs/` project-content). e.g., `aaa61b3` modified `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` during Batch 19b cleanup.
- **TYPE-2:** Pack-bias content ADDED to project-side file (the content of an edit to a project-side file references pack-only mechanisms/files/rosters). e.g., `240867d` added a `PACK-AGENTS.md` reference into project-template trinity.
- **TYPE-3:** Pack-side file modified during project-only batch (symmetric to TYPE-1).
- **TYPE-4:** Cross-reference from a project-side file to a pack-only file/mechanism — typically the persistent regression form (a project-side rule that should cite a project-side SSOT but cites pack-side instead).
- **TYPE-5:** Project-side content mirrors a pack-side decision without independent project-design rationale (heuristic; applied judgmentally only where signal is clear).

### Findings — confirmed boundary violations

#### V1 (HIGH) — TYPE-2 pack-bias contamination in project-template trinity
- **Commit:** `240867d` (2026-05-09, "fix: v11 — BD-126 / BD-127 v10.1 backport fix-follow (8 reviewer findings)")
- **Files modified that triggered the flag:** `project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md` (F-7 in commit message)
- **Violation:** F-7 added `PACK-AGENTS.md` reference into the project-template trinity. The Project memory agent-list previously read "(architect / planner / coder / reviewer / tester / auditor / docs-researcher / grpc-schema / repo-ops)"; F-7 inserted "— `auditor` covers the 7 variant agents; see `PACK-AGENTS.md` for the full roster". Project-side SSOT for the agent roster is `project-template/docs/pack/PM-CHAT.md:47` (`## Pack agent roster`), and PM-CHAT.md:239 even instructs PM chats to "treat any reference implying a different roster as stale and report it as pack feedback." F-7 introduced exactly the kind of reference that PM-CHAT.md tells PM chats to flag.
- **Severity:** HIGH (lives in project-template trinity → installed to every client repo → instructs every project-side PM chat to read a pack-only file).
- **Reversibility:** HIGH (small text edit; revert is mechanical).
- **Current HEAD state:** Still present at `project-template/CLAUDE.md:366`, `project-template/AGENTS.md:343`, `project-template/GEMINI.md:356`.

#### V2 (MEDIUM) — TYPE-1 project-side modification during pack-only batch
- **Commit:** `aaa61b3` (2026-05-17, "docs: v11 — Batch 19b cleanup — V11-12/13/14 CONCEPTUAL-REVIEW-METHODOLOGY verification + V11-15 reviewer-prompt-template find-replace")
- **Files modified:** `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` (+2 lines at lines 113-114)
- **Violation:** Batch 19b was stated by the user as PACK-ONLY scope. `supporting-docs/` is classified as pack-product per the trinity rule ("Pack ops files... NEVER mixed into pack product files (`project-template/`, `supporting-docs/`)"). Per that classification, supporting-docs is project-side and should not have been touched in a pack-only batch. Note the COMMIT MESSAGE explicitly says "Manifest regen: NOT NEEDED — supporting-docs/ is not v11-surface per RC9 rule (recursive base case)" — the commit author knew this was outside v11-surface but still modified during the pack-only batch.
- **Note on file classification ambiguity:** `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` is itself pack-only-content lodged in a project-side directory (see §F). The "violation" here is the SCOPE mismatch (pack-only batch should not touch project-side dir) not the content mismatch (the content addition is pack-only, congruent with the file's actual nature).
- **Severity:** MEDIUM (no client-installed regression; only batch-scope discipline violated; file itself is mis-located but not contaminated by THIS edit).
- **Reversibility:** HIGH.

#### V3 (HIGH) — TYPE-4 contamination in project-template/docs/pack/PLATFORM-SKILLS.md
- **Commit (first introduction):** Discovered via grep; first ships in v11 — earliest occurrence appears in commits creating/modifying PLATFORM-SKILLS.md (`58f79f0` 2026-05-11 BD-142 reframe; subsequent BD-148/156/157/158 amendments).
- **File:** `project-template/docs/pack/PLATFORM-SKILLS.md:251`
- **Violation:** Line reads: "selection. See `PACK-AGENTS.md` in the pack repo for their use." This is a project-side file (installed to client repos) referencing a pack-only file at the pack repo root. Client-installed PLATFORM-SKILLS.md cannot resolve this path.
- **Severity:** HIGH (lives in project-template, broken reference at client repos).
- **Reversibility:** HIGH (small text edit).

#### V4 (HIGH) — TYPE-4 contamination in supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md
- **Commits (introduced):** `4497e21` (2026-05-15, file creation) + `fd0c4b3` (2026-05-15, Batch 21c empirical roll-up extension)
- **File:** `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md`
- **Violations (multiple sites):**
  - Line 38 (`(d) Pack rule adherence` review dimension): "Reference: `CLAUDE.md`, `PACK-CHAT.md`, pack memory `MEMORY.md` index + linked feedback files, `ARCHITECTURE-V*.md` family." Treats pack-only files as the rule corpus. If supporting-docs is project-side, this dimension is wrong for project-side use.
  - Line 185: "**From `PACK-CHAT.md` and pack memory `MEMORY.md` index:**" — direct reference to pack-only files.
  - Line 225: "**Fallback before BD-110 lands:** `pack-architect` invoked..."  — references pack-only agent.
  - Line 227: "**Wrong tool:** `pack-reviewer`. Its scope is pre-commit changes..." — references pack-only agent.
  - Line 231: "These rules govern how the calling chat (Pack Chat) constructs the reviewer's prompt." — references pack-only orchestrator.
  - Line 253: "Future Pack Chat prompts MUST surface this rule prominently..." — Pack Chat reference.
- **Severity:** HIGH (whole doc is pack-only methodology mis-classified as project-side by location).
- **Reversibility:** MEDIUM (whole-doc relocation, not per-line; but conceptually self-contained).

#### V5 (MEDIUM) — TYPE-4 contamination in supporting-docs/MERGE-STRATEGY.md
- **Commit (first ships):** Likely pre-v11 origin; specific v11-touch commits include `024ed72` (Batch 6 review fixes), `3b8136a` (BD-097), `8497b03` (Batch 6 doc cluster), `d197483` (BD-148), `cf67a96` (BD-169).
- **File:** `supporting-docs/MERGE-STRATEGY.md:189` and `:472`
- **Violations:**
  - Line 189: "Pack-shipped agent files (e.g., `pack-architect.md`, `pack-reviewer.md`)." Project-side classification of MERGE-STRATEGY would make this a TYPE-4 cross-reference; pack-only classification (which is more accurate by content) makes this internally consistent.
  - Line 472: "`HELP-FRAGMENT-PACK.md` and `validate-pack.py` Check 22 skips" — references pack-only file + pack-only script.
- **Severity:** MEDIUM (audience-mixed file; ambiguity is the underlying issue, see §F).
- **Reversibility:** MEDIUM (requires choosing audience first).

#### V6 (LOW) — TYPE-4 reference in supporting-docs/MIGRATION-v10-to-v11.md
- **Commit (first ships):** `5877b8d` (2026-05-08 BD-114) original; modified by `cf67a96` and others.
- **File:** `supporting-docs/MIGRATION-v10-to-v11.md:35`, `:516`, `:123`, `:194`, `:225`
- **Violations:**
  - `:35`: "`HELP-FRAGMENT-PACK.md` (pack repo) or `docs/pack/HELP-FRAGMENT.md`" — pack-only file referenced with "in pack repo" qualifier (clarified, but still a cross-reference).
  - `:516`: "Run a Pack Chat session: `/pm-startup` should now report v11" — confusing: Pack Chat ≠ PM chat session for the project; if this is the project's migration guide, the conventional terminology is "PM Chat" not "Pack Chat".
  - `:123`, `:194`, `:225`: "Per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md`" — project-side migration guide pointing into pack-only maintenance-docs (not installed to client repos).
- **Severity:** LOW for `:35` (qualified), MEDIUM for `:516` (terminology contamination), MEDIUM for the maintenance-docs refs (broken pointers at client repos).
- **Reversibility:** HIGH.

#### V7 (MEDIUM) — TYPE-4 in project-template/skills/audit-methodology/SKILL.md
- **Commits (modifying):** multiple — including `50d1a57`, `523be4b`, `e9c44e7`, `faadc56`, `af66c62`, `cf67a96` (per `git log -- project-template/skills/audit-methodology/SKILL.md`).
- **File:** `project-template/skills/audit-methodology/SKILL.md:51`, `:106`
- **Violations:**
  - `:51`: "See `maintenance-docs/v11-implementation/RESEARCH-NON-APPLE-UI-SKILLS.md`" — project-side skill referencing pack-only maintenance-docs path (not installed at client repos).
  - `:106`: Same `maintenance-docs/v11-implementation/RESEARCH-NON-APPLE-UI-SKILLS.md` ref.
- **Severity:** MEDIUM (broken pointers at client repos; LOW user-visible impact since these are inline "see also" pointers, not workflow-blocking).
- **Reversibility:** HIGH (drop the pointer or relocate the doc).

#### V8 (MEDIUM) — TYPE-4 in project-template trinity (maintenance-docs reference)
- **Commits (first ships v11):** Pre-v11 origin (v10.1 backport carry-forward); landed in v11 by virtue of being present at HEAD.
- **File:** `project-template/CLAUDE.md:397`, `project-template/AGENTS.md:374`, `project-template/GEMINI.md:387`
- **Violation:** All three trinity files end with "*For deeper agent-by-agent comparison (e.g., when to use auditor vs. reviewer vs. docs-researcher), see `TOOL-COMPARISON.md` in the pack's `maintenance-docs/`.*" Project-side trinity points client PM chats to pack-only maintenance-docs.
- **Severity:** MEDIUM (qualified with "in the pack's" so the reader knows it's not installed locally; but still expects client-PM-chat to fetch from pack repo).
- **Reversibility:** HIGH.

### Findings — TYPE-1 batch-scope violations (further instances surfaced by MIXED-commit scan)

Beyond V2 (`aaa61b3`), the following commits show pack-only batch identifiers in their subject (or were known pack-only batches per the orchestration plan / batch nomenclature) but also touched project-side paths:

#### V9 (LOW) — `cf67a96` BD-169 pack-product wording updates
- **Subject:** "feat: v11 — BD-169 per-entry split pack-product wording updates (PM-CHAT + MERGE-STRATEGY + MIGRATION + audit-methodology + pack-startup x3 + pm-startup x4)"
- **Project-side files touched:** `project-template/.claude/skills/pm-startup/SKILL.md`, `project-template/.codex/skills/pm-startup/SKILL.md`, `project-template/.gemini/commands/pm-startup.toml`, `project-template/docs/pack/PM-CHAT.md`, `project-template/skills/audit-methodology/SKILL.md`, `project-template/skills/pm-startup/SKILL.md`, plus `supporting-docs/MERGE-STRATEGY.md`, `supporting-docs/MIGRATION-v10-to-v11.md`.
- **TYPE-1 assessment:** The commit explicitly self-describes scope as "pack-product wording updates" — implying project-side touches are IN SCOPE. Not a strict TYPE-1 (subject does not claim pack-only); but worth noting that 7+ project-side files were modified in a single commit alongside `.claude/skills/pack-startup/SKILL.md` (pack-side) and `.codex/skills/pack-startup/SKILL.md` (pack-side) — meaning pack-side and project-side wording changed in lockstep, increasing the risk of cross-contamination at edit time.
- **Severity:** LOW (subject was honest about mixed scope; no scope-deception finding); FLAGGED for content audit (whether each project-side edit independently makes sense for project-side audience, or whether pack-side language leaked).

#### V10 (LOW) — `8ba0164` BD-167b per-entry split PM-only edits
- **Subject:** "docs: v11 — BD-167b per-entry split PM-only edits (trinity Key files + PACK-AGENTS.md + CLAUDE.md pack-memory + pack-* agent prompts)"
- **Files touched:** Root trinity (CLAUDE/AGENTS/GEMINI), PACK-AGENTS.md, pack-side `.claude/agents/pack-*`, `.codex/agents/pack-*`, `.gemini/agents/pack-*` — AND project-template trinity (`project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md`).
- **TYPE-1 assessment:** Subject says "PM-only edits" — "PM-only" in pack memory means files Pack Chat may edit directly (root trinity, PACK-AGENTS, etc.). Yet this commit ALSO edited project-template trinity, which is NOT PM-only per pack memory (project-template/ is a pack-product space; "Pack Chat may NOT edit project-template / supporting-docs..." per pack memory). The commit subject is misleading — it did MORE than PM-only edits.
- **Severity:** MEDIUM (commit subject misrepresents scope; project-template trinity edits should have gone through fix-coder per pack memory rule).
- **Reversibility:** MEDIUM (need per-edit triage of the project-template trinity changes).

#### V11 (LOW) — `30a1bc3` broad batch review/fix (Batch 19b)
- **Subject:** "fix: v11 — broad batch review/fix (Batch 19b)"
- **Files touched:** `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `PACK-CHAT.md` — all pack-only root trinity / pack ops.
- **TYPE-1 assessment:** Cleanly pack-only. Listed for completeness; no violation.

#### V12 (LOW) — `479fef5` Batch 19 broad review/fix
- **Subject:** "fix: v11 — Batch 19 broad review/fix"
- **Files touched:** `.github/workflows/validate-pack.yml`, `AGENTS.md`, `README.md`, several maintenance-docs/ entries, `scripts/lib/migrate-v10-to-v11/decompose.sh`, `scripts/tests/test-v11-realistic-ot.sh`. No project-template touches.
- **TYPE-1 assessment:** Cleanly pack-only. Listed for completeness.

### Findings — TYPE-5 heuristic (project-side mirrors pack-side decision without independent rationale)

The Path C architect surfaced P-missed-7 ("project-design-investigation-first") which is the pre-condition for TYPE-5 detection — namely, that reviewers/implementers did not investigate the project-side SSOT before importing pack-style mechanisms. Confirmed TYPE-5 instances visible from the audit:

#### T5-A (HIGH) — Project trinity copied pack agent-list rule rather than instructing PM-chat to read project SSOT
- **Files:** `project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md` (same Project-memory agent-list bullet referenced in V1).
- **Description:** The trinity contains a static enumeration of agent roles (architect / planner / coder / ... / repo-ops). The project-side SSOT for the agent roster is `project-template/docs/pack/PM-CHAT.md:47` (`## Pack agent roster`). The trinity-level static enumeration creates two sources of truth and a stale-pointer risk; V1 made this worse by adding a pack-only file as the resolution target. Independent project-design rationale would say: "let PM-CHAT.md own the roster; don't enumerate it inline in trinity."
- **Severity:** HIGH (root cause of V1's regression).

#### T5-B (MEDIUM) — supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md mirrors PACK-CHAT/MEMORY structure
- **Description:** The doc's review dimensions (a-f) and "Pack rule adherence" (dimension d) are structurally pack-internal — they reference pack-only files (CLAUDE.md, PACK-CHAT.md, pack memory MEMORY.md). If this doc were meant for project-side reviewers, dimension (d) would reference project-side equivalents. The structural mirror without project-design rationale suggests the doc was written for pack-internal use and dropped into supporting-docs/ by location-default.
- **Severity:** MEDIUM.

### Findings — TYPE-3 symmetric violation (pack-side modified during project-only batch)

Searched the 7 PROJECT-ONLY commits (per §C aggregate count). All 7 touched project-template/ files (or root trinity in the case of `d8e6a02` which classification logic mis-counted; see note below). None of the 7 commits touched pack-only `maintenance-docs/`, `scripts/`, or `test-fixtures/`. Verdict: **0 confirmed TYPE-3 violations.**

**Classification correction:** `d8e6a02` (feat: v11 — BD-081 trinity addenda) touched ROOT trinity (CLAUDE.md, AGENTS.md, GEMINI.md) AND project-template trinity. Root trinity is pack-only per §B. So `d8e6a02` is MIXED, not PROJECT-ONLY — the classification script under-counted MIXED by 1 (38 → 39).


### Full MIXED-commit roster (for traceability)

Below is the complete list of 38 MIXED commits (per the classification heuristic in §C intro). Each is annotated with a "scope honesty" note. Most are legitimate mixed-scope commits (BD-shipping both pack-side and project-side artifacts in one BD, e.g., BD-060/061/063 issue-forms shipped to both, or BD-074 pack-startup + pm-startup shipped in trinity-parallel). The flagged ones are V1, V2, V9, V10 from above. Listed in reverse chronological order.

| SHA | Date | Subject | Mixed-scope assessment |
|---|---|---|---|
| `62f9eec` | 2026-05-16 | fix: v11 — BD-169 review/fix | Legitimate (BD-169 was per-entry split client + pack lockstep) |
| `cf67a96` | 2026-05-16 | feat: v11 — BD-169 pack-product wording updates | V9 (flagged) |
| `80b025a` | 2026-05-16 | fix: v11 — BD-167 retro review/fix | Legitimate (per-stream rules ship to project-template; helper to scripts) |
| `8ba0164` | 2026-05-15 | docs: v11 — BD-167b per-entry split PM-only edits | V10 (flagged) |
| `142d160` | 2026-05-15 | feat: v11 — BD-167 per-entry split client artifact installs | Legitimate (BD-167 explicitly client-artifact-install) |
| `1a5944b` | 2026-05-15 | feat: v11 — BD-107 TD promotion + per-BD review-fix | Mixed by design (TD promotion ships HELP-FRAGMENT + project-template/docs/pack/HELP-FRAGMENT + scripts) |
| `430c637` | 2026-05-15 | fix: v11 — BD-108 review-fix | Mixed by design (tracker-cycle-check.sh + project-template/tracker.toml.project-example + tests + CI) |
| `2a6f032` | 2026-05-13 | feat: v11 — BD-162 python-observability-patterns skill | Mixed by design (skill ships to project-template/skills/) |
| `e9c44e7` | 2026-05-12 | fix: v11 — BD-034 audit + Apple skill additions | Mixed by design (skills + audit-methodology in project-template) |
| `d059d5f` | 2026-05-12 | fix: v11 — BD-033 audit + audit-methodology + auditor-code trinity prose-parity | Mixed by design |
| `523be4b` | 2026-05-12 | fix: v11 — BD-035 audit + python_data_marker + protobuf-overlap | Mixed by design |
| `50d1a57` | 2026-05-12 | fix: v11 — BD-032 audit + audit-methodology rule 21 | Mixed by design |
| `09b609a` | 2026-05-12 | docs: v11 — BD-149 codify skill naming in PLATFORM-SKILLS | Legitimate (PLATFORM-SKILLS lives in project-template) |
| `8c117cf` | 2026-05-12 | feat: v11 — BD-158 swift-concurrency-patterns | Mixed by design |
| `c2beaa0` | 2026-05-12 | feat: v11 — BD-157 apple-swiftdata-patterns | Mixed by design |
| `af2f651` | 2026-05-12 | feat: v11 — BD-156 protobuf-patterns | Mixed by design |
| `d197483` | 2026-05-12 | feat: v11 — BD-148 MIGRATION/MERGE-STRATEGY docs | Mixed by design (docs update spans supporting-docs + project-template/docs/pack/PLATFORM-SKILLS.md) |
| `af66c62` | 2026-05-12 | feat: v11 — BD-143 skill-dimensions trinity prose | Mixed by design (trinity prose in both pack-side .claude/skills + project-template) |
| `58f79f0` | 2026-05-11 | feat: v11 — BD-142 PLATFORM-SKILLS reframed | Legitimate |
| `faadc56` | 2026-05-11 | fix: v11 — Batch 14 audit fix-follow | Mixed by design |
| `a354a35` | 2026-05-11 | fix: v11 — python-architecture skill split | Mixed by design |
| `ef20113` | 2026-05-10 | fix: v11 — BD-104 cross-pack rename IMPLEMENTATION_PLAN.md → IMPLEMENTATION-PLAN.md | Legitimate (cross-pack rename is necessarily mixed) |
| `ffecfef` | 2026-05-09 | feat: v11 — BD-135 disambiguate tracker.toml.example pair | Legitimate (rename pair lives in both) |
| `240867d` | 2026-05-09 | fix: v11 — BD-126 / BD-127 v10.1 backport fix-follow | **V1 (flagged HIGH)** |
| `19755b5` | 2026-05-08 | fix: v11 — v10.1 backport optimization pass | Mixed (project-template/docs/pack/PM-CHAT.md + scripts/validate-pack.py + maint) — legitimate scope |
| `ac6fb0c` | 2026-05-08 | docs: v10.1 — codify RAG ingestion manifest | Mixed (project-template/docs/pack/PM-CHAT.md + supporting-docs/) — needs content audit |
| `3b8136a` | 2026-05-08 | feat: v11 — BD-097 audit + Batch 7 fixes | Mixed by design (semantic audit touches both buckets) |
| `024ed72` | 2026-05-08 | fix: v11 — Batch 6 review fixes | Mixed by design |
| `8497b03` | 2026-05-08 | docs: v11 — Batch 6 doc cluster | Mixed by design (doc cluster spans both) |
| `2593131` | 2026-05-07 | fix: v11 — Batch 2 review fixes | Mixed (pack-help shipped to both surfaces) — legitimate |
| `1d478d1` | 2026-05-07 | feat: v11 — BD-077 per-CLI pack-help command/skill | Legitimate (BD-077 explicit "Trinity × 2 surfaces") |
| `663db86` | 2026-05-07 | feat: v11 — BD-076 HELP-FRAGMENT files | Mixed by design (canonical + per-surface) |
| `887e4b6` | 2026-05-06 | fix: v11 — Batch 1 review fixes | Mixed (pack-startup pack-side + pm-startup project-side fix in lockstep) — legitimate |
| `0d62429` | 2026-05-06 | feat: v11 — BD-074 pack-startup / pm-startup Step 8 | Legitimate (BD-074 explicit pack-startup + pm-startup pair) |
| `09b31c2` | 2026-05-06 | feat: v11 — BD-071 agent read-pattern adaptation | Mixed (project-template/docs/pack/prompts/ + scripts/lib/) — legitimate scope |
| `d836f01` | 2026-05-06 | feat: v11 — BD-062 trinity Document locations Source column | Mixed (BACKLOG + project trinity) — legitimate |
| `12243e1` | 2026-05-06 | feat: v11 — BD-063 issue forms work-item+inbound+config | Legitimate (BD-063 explicitly ships forms to both surfaces) |
| `c0f29ab` | 2026-05-06 | feat: v11 — BD-061 tracker.toml schema | Mixed (gitignore + tracker.toml.example in both surfaces) — legitimate |
| `aaa61b3` | 2026-05-17 | docs: v11 — Batch 19b cleanup — V11-12/13/14 CONCEPTUAL-REVIEW-METHODOLOGY | **V2 (flagged MEDIUM)** |
| `d8e6a02` | 2026-05-08 | feat: v11 — BD-081 trinity addenda | Legitimate (BD-081 explicit "Pack commands + Recommended first action" trinity addenda lockstep) — corrected to MIXED |

**Total flagged from MIXED roster:** 4 commits (V1, V2, V9, V10). Other 34 MIXED commits are legitimate by-design (BD-scope honestly spans both buckets).

### TYPE-2 instances beyond V1 (independent grep on project-side files for pack-only refs)

Beyond V1's `PACK-AGENTS.md` reference, the following grep results (full enumeration in §D) surface additional TYPE-2/4 candidates in project-side files. Per the TYPE classification system, TYPE-2 specifically means a project-side file was MODIFIED to add pack-bias content; TYPE-4 means the project-side file CONTAINS a cross-reference (may pre-date v11). The §D scan does not always discriminate; the v11-commit audit treats each grep hit as a candidate and surfaces the introducing commit when grep-blame is straightforward (skipped for findings beyond V1 to avoid scope creep — Phase 2 architects can blame each hit individually if needed).

---

## §D — Project-side reference scan for pack-only artifacts

Comprehensive grep against `project-template/` and `supporting-docs/` for references to pack-only artifacts. Each hit gets a verdict: **CONTAMINATION** (wrong for the surface it lives on), **LEGITIMATE** (correctly classified pack-vs-project boundary discussion), or **AMBIGUOUS** (audience or intent unclear; needs Phase 2 judgment).

### D-1: References to `PACK-AGENTS.md`

| File:Line | Context | Verdict |
|---|---|---|
| `project-template/CLAUDE.md:366` | "7 variant agents; see `PACK-AGENTS.md` for the full roster" | **CONTAMINATION** — V1 finding; project-side SSOT is `docs/pack/PM-CHAT.md:47`. |
| `project-template/AGENTS.md:343` | Same as above (trinity parity) | **CONTAMINATION** — V1. |
| `project-template/GEMINI.md:356` | Same as above (trinity parity) | **CONTAMINATION** — V1. |
| `project-template/docs/pack/PLATFORM-SKILLS.md:251` | "See `PACK-AGENTS.md` in the pack repo for their use." | **CONTAMINATION** — V3 finding; broken pointer at client repos. |

**D-1 total:** 4 CONTAMINATION hits, 0 LEGITIMATE, 0 AMBIGUOUS.

### D-2: References to `PACK-CHAT.md`

| File:Line | Context | Verdict |
|---|---|---|
| `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md:38` | "Reference: `CLAUDE.md`, `PACK-CHAT.md`, pack memory `MEMORY.md` index..." | **CONTAMINATION** if file is project-side; **LEGITIMATE** if file is reclassified as pack-only. Per §F, file is pack-only by content but project-side by location. Phase 2 architect resolves. **AMBIGUOUS-pending-§F-resolution** (provisional CONTAMINATION). |
| `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md:185` | "From `PACK-CHAT.md` and pack memory `MEMORY.md` index:" | **AMBIGUOUS-pending-§F** (provisional CONTAMINATION). |

**D-2 total:** 2 provisional CONTAMINATION hits (both AMBIGUOUS pending §F resolution).

### D-3: References to pack-only agent names (`pack-architect`, `pack-coder`, `pack-planner`, `pack-reviewer`, `pack-docs-researcher`)

| File:Line | Context | Verdict |
|---|---|---|
| `supporting-docs/MERGE-STRATEGY.md:189` | "Pack-shipped agent files (e.g., `pack-architect.md`, `pack-reviewer.md`)." | **AMBIGUOUS** — file is audience-mixed; if file is project-side, this is CONTAMINATION; if file is pack-internal, it's documenting pack-shipped artifacts which is meta-correct. |
| `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md:225` | "Fallback before BD-110 lands: `pack-architect` invoked..." | **AMBIGUOUS-pending-§F** (provisional CONTAMINATION; file content is pack-only). |
| `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md:227` | "Wrong tool: `pack-reviewer`. Its scope is pre-commit changes..." | **AMBIGUOUS-pending-§F** (provisional CONTAMINATION). |

**D-3 total:** 1 AMBIGUOUS (MERGE-STRATEGY), 2 provisional CONTAMINATION (CONCEPTUAL-REVIEW-METHODOLOGY).

### D-4: References to `Pack Chat` (capitalized — pack-only orchestrator name)

| File:Line | Context | Verdict |
|---|---|---|
| `project-template/docs/pack/PACK-FEEDBACK.md:13` | "PM chat running this project to the Pack Chat maintaining the pack." | **LEGITIMATE** — PACK-FEEDBACK.md is the project-side feedback channel TO Pack Chat; the reference is the legitimate cross-boundary communication mechanism. |
| `project-template/docs/pack/PACK-FEEDBACK.md:42`, `:58`, `:87`, `:98`, `:104`, `:106`, `:112`, `:122`, `:143`, `:150`, `:151`, `:152`, `:172`, `:294`, `:312`, `:336`, `:357`, `:377`, `:394`, `:419`, `:446`, `:448` | Multiple "Pack Chat" references in the feedback-channel doc | **LEGITIMATE** — all in PACK-FEEDBACK.md describing the feedback flow. |
| `project-template/docs/pack/PM-CHAT.md:225` | "batches to the Pack Chat only at workflow-complete boundaries (never" | **LEGITIMATE** — describing the feedback flow. |
| `project-template/docs/pack/PM-CHAT.md:227` | "not solutions — the Pack Chat decides what to do with them." | **LEGITIMATE** — describing the feedback flow. |
| `supporting-docs/SETUP-EXISTING.md:274` | "This log is delivered back to the Pack Chat at a workflow boundary" | **LEGITIMATE** — describing the feedback flow (PACK-FEEDBACK.md anchor). |
| `supporting-docs/MIGRATION-v10-to-v11.md:516` | "Run a Pack Chat session: `/pm-startup` should now report v11" | **CONTAMINATION** — wrong terminology: project-side PM chat sessions are "PM chat" sessions, not "Pack Chat" sessions. The instruction is for the project user; "Pack Chat" is the pack-only orchestrator. V6 partial. |
| `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md:231` | "These rules govern how the calling chat (Pack Chat) constructs the reviewer's prompt." | **AMBIGUOUS-pending-§F** (provisional CONTAMINATION). |
| `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md:253` | "Future Pack Chat prompts MUST surface this rule..." | **AMBIGUOUS-pending-§F** (provisional CONTAMINATION). |
| `supporting-docs/METHODOLOGY.md:119` | "PACK-FEEDBACK.md ... upstream feedback log to Pack Chat" | **LEGITIMATE** — describing the feedback channel. |
| `supporting-docs/METHODOLOGY.md:1420` | "running on real production work. The Pack Chat (the upstream maintainer" | **LEGITIMATE** — describing the feedback channel. |
| `supporting-docs/METHODOLOGY.md:1438`, `:1444`, `:1446` | Multiple references in feedback-flow section | **LEGITIMATE**. |
| `supporting-docs/MIGRATION-v8-to-v9.md:57`, `:212` | Pack Chat references in historical migration doc | **LEGITIMATE** (historical context). |
| `supporting-docs/INSTALL-PROCEDURES.md:301`, `:609` | "STOP and surface to Pack Chat" | **LEGITIMATE** — escalation paths. |

**D-4 total:** ~32 LEGITIMATE (mostly feedback-flow), 1 CONTAMINATION (MIGRATION-v10-to-v11.md:516), 4 AMBIGUOUS-pending-§F (CONCEPTUAL-REVIEW-METHODOLOGY).

### D-5: References to `maintenance-docs/` (pack-only directory) from project-side files

| File:Line | Context | Verdict |
|---|---|---|
| `project-template/CLAUDE.md:397` | "see `TOOL-COMPARISON.md` in the pack's `maintenance-docs/`." | **CONTAMINATION** — V8; pointer to pack-only directory not installed at client repos. |
| `project-template/AGENTS.md:374` | Same (trinity parity) | **CONTAMINATION** — V8. |
| `project-template/GEMINI.md:387` | Same (trinity parity) | **CONTAMINATION** — V8. |
| `project-template/docs/pack/PLATFORM-SKILLS.md:572` | "(`maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md`" | **CONTAMINATION** — broken pointer at client repos. |
| `project-template/skills/audit-methodology/SKILL.md:51` | "see `maintenance-docs/v11-implementation/RESEARCH-NON-APPLE-UI-SKILLS.md`" | **CONTAMINATION** — V7; broken pointer at client repos. |
| `project-template/skills/audit-methodology/SKILL.md:106` | Same path ref | **CONTAMINATION** — V7. |
| `supporting-docs/MIGRATION-v10-to-v11.md:123` | "Per `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md`" | **CONTAMINATION** — V6; broken pointer at client repos. |
| `supporting-docs/MIGRATION-v10-to-v11.md:194`, `:225` | Same path ref | **CONTAMINATION** — V6. |
| `supporting-docs/METHODOLOGY.md:1509` | "*Source: maintenance-docs/origins/Claude-Assisted_Project_Methodology_Guide_v1.md*" | **AMBIGUOUS** — historical attribution; correct in pack-repo context, broken in client-repo context. |
| `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md:268`, `:281`, `:293` | "These docs live at `maintenance-docs/v{N}-implementation/CONCEPTUAL-AREA-{NAME}.md`" | **AMBIGUOUS-pending-§F** (if doc reclassifies pack-only, these are LEGITIMATE; if project-side, CONTAMINATION). |

**D-5 total:** 9 CONTAMINATION, 1 AMBIGUOUS, 3 AMBIGUOUS-pending-§F.

### D-6: References to `BACKLOG.md` / `CHANGELOG.md` (need disambiguation: pack-root vs project-side mirror)

The pack-root `BACKLOG.md` / `CHANGELOG.md` are pack-only mirrors of the `/backlog/` and `/changelog/` per-entry trees. Project-side `BACKLOG.md` / `CHANGELOG.md` are project's own — different files, but identical filenames. Project-side trinity references to BACKLOG/CHANGELOG should resolve to PROJECT-side files (typically `docs/project/BACKLOG.md` per v11 per-entry split), not pack-root.

| File:Line | Context | Verdict |
|---|---|---|
| `project-template/GEMINI.md:219`, `:228`, `:229`, `:278`, `:280`, `:311` | "`docs/project/` ... `BACKLOG.md`, `STATUS.md`, `CHANGELOG.md`" | **LEGITIMATE** — refers to project's own files at `docs/project/`, not pack-root. |
| `project-template/AGENTS.md:208`, `:217`, `:218`, `:260`, `:261`, `:276`, `:302` | Same project-internal | **LEGITIMATE**. |
| `project-template/CLAUDE.md:224`, `:233`, `:234`, `:283`, `:285`, `:316` | Same project-internal | **LEGITIMATE**. |
| `project-template/.gemini/agents/repo-ops.md:66-67`, `coder.md:80` | "Do not write to `BACKLOG.md`, `CHANGELOG.md`, `STATUS.md`, `PACK-FEEDBACK.md`" | **LEGITIMATE** — project-side agent prohibition rules (refers to project's own files at project root, alongside `PACK-FEEDBACK.md` which is project-side). |
| `project-template/.gemini/commands/pm-startup.toml:67`, `:73` | "reads `BACKLOG.md` in flat-file mode" | **LEGITIMATE** — project's PM startup reads project BACKLOG. |
| `project-template/docs/pack/PM-CHAT.md:119`, `:121` | PM-chat reads project BACKLOG/CHANGELOG | **LEGITIMATE**. |
| `project-template/docs/pack/prompts/reviewer.md:20`, `:73`, `tester.md:17`, `pm-chat.md:127`, `coder.md:17`, `:52`, `:62`, `:63`, `:81`, `:100` | Project-side agent prompts referencing project's own BACKLOG/CHANGELOG | **LEGITIMATE**. |
| `project-template/.claude/agents/repo-ops.md:69-70`, `coder.md:81`, `.claude/skills/pm-startup/SKILL.md:70`, `:76` | Same as above for .claude variant | **LEGITIMATE**. |

**D-6 total:** All ~25 hits are LEGITIMATE — they correctly refer to project's OWN BACKLOG / CHANGELOG (not pack-root files). The bare filename is ambiguous only out-of-context.

### D-7: References to `HELP-FRAGMENT-PACK.md` (pack-root file) from project-side

| File:Line | Context | Verdict |
|---|---|---|
| `supporting-docs/MERGE-STRATEGY.md:472` | "`HELP-FRAGMENT-PACK.md` and `validate-pack.py` Check 22 skips" | **CONTAMINATION** — V5 partial; pack-root file + pack-only script referenced from project-side file. |
| `supporting-docs/MIGRATION-v10-to-v11.md:35` | "`HELP-FRAGMENT-PACK.md` (pack repo) or `docs/pack/HELP-FRAGMENT.md`" | **AMBIGUOUS** — explicit "(pack repo)" qualifier; treated as documentation of where things live across pack-vs-client. CONTAMINATION-LITE — qualified but still surfaces pack-only file in project-side migration guide. |

**D-7 total:** 1 CONTAMINATION, 1 AMBIGUOUS (qualified).

### D-8: References to `OPTIONAL-FEATURES.md` (pack-root file)

| File:Line | Context | Verdict |
|---|---|---|
| `project-template/.gemini/commands/pack-help.toml:12` | "docs/pack/OPTIONAL-FEATURES.md." | **AMBIGUOUS** — the path qualifier `docs/pack/` suggests there's an installed version at the client; current state has NO `OPTIONAL-FEATURES.md` under `project-template/docs/pack/`. So the ref is to a file that doesn't exist at client repos. Likely CONTAMINATION (or mis-direction). |
| `project-template/.claude/skills/pack-help/SKILL.md:15` | "`docs/pack/OPTIONAL-FEATURES.md`. The shell verb `pack help`" | Same | **AMBIGUOUS** (likely CONTAMINATION). |
| `project-template/.codex/skills/pack-help/SKILL.md:15` | Same | **AMBIGUOUS** (likely CONTAMINATION). |
| `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md:49` | "See ... and `OPTIONAL-FEATURES.md` for full setup." | **AMBIGUOUS** — bare filename; client install would not have this file under `docs/pack/`. |
| `project-template/docs/pack/HELP-FRAGMENT.md:6`, `:33` | "`docs/pack/OPTIONAL-FEATURES.md`" | **AMBIGUOUS** (likely CONTAMINATION). |
| `supporting-docs/MERGE-STRATEGY.md:465` | "`OPTIONAL-FEATURES.md` — tracker opt-in walkthrough" | **CONTAMINATION** — pack-root file referenced from project-side. |
| `supporting-docs/DEPENDENCIES.md:162` | "See `OPTIONAL-FEATURES.md` § 'Tracker integration (v11)' for the full" | **CONTAMINATION** — pack-root file referenced from project-side. |

**D-8 total:** 2 CONTAMINATION, 5 AMBIGUOUS-likely-CONTAMINATION. **Pattern:** OPTIONAL-FEATURES.md is currently at pack root only, but at least 5 project-side files reference `docs/pack/OPTIONAL-FEATURES.md` as if it were installed at client repos under `docs/pack/`. This is an installed-path-vs-source-path discrepancy worth flagging.

### D-9: Cross-cutting CONTAMINATION summary

Aggregating CONTAMINATION verdicts across D-1..D-8 (exclusive of LEGITIMATE / AMBIGUOUS):
- Definite CONTAMINATION: 4 (D-1) + 0 (D-2) + 0 (D-3 inside-resolved) + 1 (D-4) + 9 (D-5) + 0 (D-6) + 1 (D-7) + 2 (D-8) = **17 confirmed contamination hits**.
- AMBIGUOUS-pending-§F (CONCEPTUAL-REVIEW-METHODOLOGY-related): 2 (D-2) + 2 (D-3) + 4 (D-4) + 3 (D-5) = 11 hits.
- AMBIGUOUS-other (MERGE-STRATEGY audience, OPTIONAL-FEATURES installed-path mismatch, METHODOLOGY historical attribution, HELP-FRAGMENT-PACK qualified ref): 1 (D-3) + 1 (D-5) + 1 (D-7) + 5 (D-8) = 8 hits.
- LEGITIMATE: ~32 (D-4 feedback-flow) + ~25 (D-6 project BACKLOG/CHANGELOG) = ~57 hits.

---

## §E — Path-reference scan for relocation candidates

For each MOVES candidate from §A, enumerate every path reference across the repo. This data informs the lockstep path-update work in Phase 5.

### E-1: `PACK-AGENTS.md`

Repo-wide grep `PACK-AGENTS\.md` (all file types). Excluded: `.git/`. Files containing references:

**Pack-only context (correct refs):**
- `HELP-FRAGMENT-PACK.md` (1+ ref, bare filename in "verb reference" surface)
- `CHANGELOG.md`, `BACKLOG.md`, `README.md` (pack-root mirrors / index)
- `PACK-AGENTS.md` (self)
- `PACK-CHAT.md` (pack ops adjacent)
- `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` (pack-root trinity)
- `.claude/agents/pack-coder.md:35`, `:86`
- `.claude/agents/pack-architect.md:18`, `:25`
- `.claude/skills/commit-discipline/SKILL.md:117`
- `.codex/agents/pack-coder.toml:21`, `:45`
- `.codex/agents/pack-architect.toml:15`, `:18`
- `.codex/skills/commit-discipline/SKILL.md:117`
- `.gemini/agents/pack-coder.md` (2+ refs)
- `.gemini/agents/pack-architect.md:20`, `:27`
- `.gemini/skills/commit-discipline/SKILL.md:117`
- `maintenance-docs/V10-MIGRATION-FIX-DESIGN.md` and various archived design docs

**Project-side context (CONTAMINATION refs per §D-1):**
- `project-template/CLAUDE.md:366`
- `project-template/AGENTS.md:343`
- `project-template/GEMINI.md:356`
- `project-template/docs/pack/PLATFORM-SKILLS.md:251`

**Reference shapes encountered:**
- Bare filename: `PACK-AGENTS.md` (most common — implies "at pack root")
- Qualified: `PACK-AGENTS.md` in the pack repo (one site)
- Verb-context: `PACK-AGENTS.md`-style usage in HELP-FRAGMENT-PACK.md

**E-1 total references:** ~25+ files across pack-only + 4 project-side CONTAMINATION sites.

### E-2: `HELP-FRAGMENT-PACK.md`

Repo-wide grep. Files containing references:

**Pack-only context:**
- `CHANGELOG.md`, `QUICKSTART.md`, `README.md`, `BACKLOG.md` (pack-root index)
- `scripts/pack-help.sh` (resolves this file)
- `scripts/validate-pack.py` (Check 22 references)
- `scripts/tests/pack-help-test.sh`
- `maintenance-docs/archive/v11/*.md` (multiple archived BD reports)
- `maintenance-docs/v11-implementation/PACK-REVIEW-BD-107.md`, `PACK-REVIEW-BATCH-17.md`, `PACK-REVIEW-BD-116-RETRO.md`, `IMPLEMENTATION-REPORT-BD-107-FIX.md`, `PACK-REVIEW-BD-168-RETRO.md`, `IMPLEMENTATION-REPORT-BD-107.md`, `ORCHESTRATION-PLAN-BD-175.md`
- `maintenance-docs/v11-research/ARCHITECTURE-REVIEW-PASS3.md`, `ARCHITECTURE-V3.2-DELTA.md`, `ARCHITECTURE-V3.3-DELTA.md`, `ARCHITECTURE-REVIEW-PASS2.md`

**Project-side context (CONTAMINATION/AMBIGUOUS):**
- `supporting-docs/MERGE-STRATEGY.md:472` (CONTAMINATION per D-7)
- `supporting-docs/MIGRATION-v10-to-v11.md:35` (AMBIGUOUS per D-7 — qualified)

**E-2 total references:** ~22 files across pack-only + 2 project-side (1 CONTAMINATION + 1 AMBIGUOUS).

### E-3: `HELP-FRAGMENT-TRACKER.md`

Repo-wide grep:
- `HELP-FRAGMENT-PACK.md`, `CHANGELOG.md`, `README.md`, `BACKLOG.md` (pack-root index)
- `project-template/docs/pack/HELP-FRAGMENT.md` (project-side, but refers as cross-ref to pack-root)
- `supporting-docs/MIGRATION-v10-to-v11.md` (project-side)
- `scripts/migrate-v10-to-v11.sh`, `scripts/pack-help.sh`, `scripts/validate-pack.py`, `scripts/init-project.sh` (pack-only scripts)
- `scripts/tests/pack-help-test.sh`, `scripts/tests/test-init-project.sh`, `scripts/tests/test-migrate-v10-to-v11.sh`
- `scripts/persona-contracts/contract-greenfield.sh`, `scripts/persona-contracts/contract-migration.sh`
- `scripts/lib/migrate-v10-to-v11/checkpoint.sh`
- Multiple maintenance-docs archive and v11-implementation references

**E-3 total references:** ~25+ files. Significant pack-side script wiring; minor project-side cross-ref pattern.

### E-4: `OPTIONAL-FEATURES.md`

Repo-wide grep:
- `HELP-FRAGMENT-PACK.md`, `CHANGELOG.md`, `QUICKSTART.md`, `HELP-FRAGMENT-TRACKER.md`, `README.md`, `BACKLOG.md` (pack-root index)
- `project-template/.gemini/commands/pack-help.toml`
- `project-template/.claude/skills/pack-help/SKILL.md`
- `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`
- `project-template/docs/pack/HELP-FRAGMENT.md`
- `project-template/.codex/skills/pack-help/SKILL.md`
- `.gemini/commands/pack-help.toml`
- `.claude/skills/pack-help/SKILL.md`
- `.codex/skills/pack-help/SKILL.md`
- `supporting-docs/MERGE-STRATEGY.md`
- `supporting-docs/DEPENDENCIES.md`
- `scripts/validate-pack.py`
- Multiple archived maintenance-docs

**E-4 total references:** ~20+ files. Critical note: many project-side refs use path `docs/pack/OPTIONAL-FEATURES.md` (implying installed location), but no such file currently exists in `project-template/docs/pack/`. Source-vs-installed-path discrepancy worth highlighting for Phase 2.

### E-5: `PACK-CHAT.md`

Repo-wide grep:
- `HELP-FRAGMENT-PACK.md`, `CHANGELOG.md`, `PACK-AGENTS.md`, `README.md`, `GEMINI.md`, `PACK-CHAT.md` (self), `AGENTS.md`, `CLAUDE.md`, `BACKLOG.md` (pack-root)
- `.gemini/agents/pack-coder.md`, `.gemini/commands/pack-help.toml`, `.gemini/agents/pack-architect.md`, `.gemini/commands/pack-startup.toml`, `.gemini/skills/commit-discipline/SKILL.md`
- `.claude/agents/pack-coder.md`, `.claude/agents/pack-architect.md`, `.claude/skills/pack-startup/SKILL.md`, `.claude/skills/commit-discipline/SKILL.md`, `.claude/skills/pack-help/SKILL.md`
- `.codex/agents/pack-architect.toml`, `.codex/agents/pack-coder.toml`, `.codex/skills/pack-startup/SKILL.md`, `.codex/skills/commit-discipline/SKILL.md`, `.codex/skills/pack-help/SKILL.md`
- `scripts/pack-tracker.sh`, `scripts/validate-pack.py`, `scripts/tests/test-per-entry.sh`, `scripts/tests/tracker-init-test.sh`, `scripts/tests/recommendation-test.sh`
- `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` (project-side — provisional CONTAMINATION)

**E-5 total references:** ~30+ files. Largely pack-side; minor project-side contamination already captured in §D-2.

### E-6: `QUICKSTART.md`

Repo-wide grep:
- `HELP-FRAGMENT-PACK.md`, `CHANGELOG.md`, `README.md`, `BACKLOG.md` (pack-root)
- `project-template/README.md` (project-side install README)
- `project-template/.gemini/commands/pack-help.toml`
- `project-template/.claude/skills/pack-help/SKILL.md`
- `project-template/docs/pack/HELP-FRAGMENT.md`
- `project-template/.codex/skills/pack-help/SKILL.md`
- `.gemini/agents/pack-reviewer.md`, `pack-planner.md`, `commands/pack-help.toml`
- `.claude/agents/pack-reviewer.md`, `pack-planner.md`, `skills/pack-help/SKILL.md`
- `.codex/agents/pack-planner.toml`, `pack-reviewer.toml`, `skills/pack-help/SKILL.md`
- `supporting-docs/MERGE-STRATEGY.md`, `METHODOLOGY.md`
- `scripts/validate-pack.py`
- Multiple maintenance-docs

**E-6 total references:** ~25 files. SHARED-ANTI-PATTERN consequence: referenced from both audiences which makes it a relocation challenge.

### E-7: `tracker.toml.pack-example`

Repo-wide grep:
- `BACKLOG.md`, `CHANGELOG.md`, `README.md` (pack-root mirrors)
- `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md:49` ("`tracker.toml.pack-example` in the pack repo, or `tracker.toml.example` at a client project root")
- `scripts/init-project.sh`, `scripts/migrate-v10-to-v11.sh`, `scripts/test-migrator-manifest.sh`
- `supporting-docs/MERGE-STRATEGY.md`, `MIGRATION-v10-to-v11.md`
- Various maintenance-docs

**E-7 total references:** ~15 files. Whether MOVES is feasible depends on whether `tracker-config.sh` can resolve a non-root path — verify-needed.

**§E aggregate counts:**
- `PACK-AGENTS.md`: ~25+ refs (~21 pack-only, 4 project-side CONTAMINATION)
- `HELP-FRAGMENT-PACK.md`: ~22 refs (~20 pack-only, 2 project-side)
- `HELP-FRAGMENT-TRACKER.md`: ~25 refs (mostly pack-only)
- `OPTIONAL-FEATURES.md`: ~20+ refs (significant project-side via installed-path-mismatch pattern)
- `PACK-CHAT.md`: ~30+ refs (mostly pack-only)
- `QUICKSTART.md`: ~25 refs (cross-audience — SHARED)
- `tracker.toml.pack-example`: ~15 refs (mostly pack-only)

---

## §F — Shared-anti-pattern catalog

Entries that fail the clean PACK-ONLY / PROJECT-ONLY dichotomy. Each carries an elimination feasibility estimate (HIGH = easy to split / MEDIUM = needs design / LOW = structurally required to be shared).

### F-1: `supporting-docs/` (directory)
- **Path:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/supporting-docs/`
- **Why shared:** Per pack memory's trinity rule, `supporting-docs/` is classified as "pack product" (i.e., project-side — content shipped to client projects on install). However, two files in this directory are pack-only by content:
  - `CONCEPTUAL-REVIEW-METHODOLOGY.md` — pack-internal review methodology with multiple references to Pack Chat, `pack-architect`, `pack-reviewer`, pack memory `MEMORY.md`. Audience: pack-only.
  - `DRY-RUN-MIGRATION.md` — pack-repo tooling for "any org maintaining a v10 (or future-vN) pack-managed client." Audience: pack maintainers (or org leads who fork the pack).
  - `MERGE-STRATEGY.md` — audience-mixed; refers to pack-shipped agent files and is consumed by `migrate-v10-to-v11.sh` (pack tooling), but contains content (preservation strategies) relevant to client projects.
  - `INSTALL-PROCEDURES.md` — strictly project-side (install instructions for client setup), but contains "STOP and surface to Pack Chat" escalation paths (feedback-loop refs, classed LEGITIMATE per D-4).
- **Symptom of anti-pattern:** Pack-only commits that should be limited to pack-only directories silently expand into `supporting-docs/` (V2 confirmed instance: `aaa61b3`). Project-side methodology content gets contaminated by pack-internal mechanism references (V4 confirmed: CONCEPTUAL-REVIEW-METHODOLOGY's pack-only orientation).
- **Contamination pathway:** Pack maintainers writing pack-internal docs default to `supporting-docs/` because the directory NAME does not signal "this is project-installed content"; the trinity rule's PACK-PRODUCT classification is non-obvious from the directory name.
- **Elimination feasibility:** **MEDIUM** — requires (a) classifying each file by intended audience, (b) deciding the new home for pack-only files, (c) the bare path `supporting-docs/` is referenced by `init-project.sh` and `migrate-v10-to-v11.sh` for client install operations, so any relocation must update install logic in lockstep. Design needed before mechanical work.

### F-2: `project-template/docs/pack/` (directory name)
- **Path:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/docs/pack/`
- **Why shared/anti-pattern:** Directory NAME `pack/` lives inside `project-template/` (project-side) but its name implies "pack-side concerns." Contents are PROJECT-SIDE artifacts that describe pack-related concerns from the project's perspective (PM-CHAT.md = project-side counterpart to pack-side PACK-CHAT.md; PACK-FEEDBACK.md = project-side feedback channel TO Pack Chat; HELP-FRAGMENT.md = project-side verb reference; PLATFORM-SKILLS.md = project-side skill catalog).
- **Symptom of anti-pattern:** Name confusion creates cross-bias risk — both pack-coders and project-PM-chats may misread the directory's audience. V1 finding is one manifestation: the project trinity's "see PACK-AGENTS.md for the full roster" reference might have been written by an actor who read `project-template/docs/pack/` and concluded pack-only files are project-installable.
- **Contamination pathway:** Reviewer/implementer ambiguity about who owns the directory's content; SSOT enforcement weakens.
- **Elimination feasibility:** **MEDIUM** — renaming `project-template/docs/pack/` to a clearer name (or moving the contents to other project-template subtrees) requires updating ~20-50 path references across the repo and is breaking for any client repo that uses the path. Design needed.

### F-3: `.github/` (root) parallel with `project-template/.github/`
- **Paths:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.github/` and `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/.github/`
- **Why shared:** Root `.github/` is pack-repo only; `project-template/.github/` is shipped to client repos. Both have the same THREE files (`ISSUE_TEMPLATE/{config,inbound,work-item}.yml`) — but they are NOT byte-identical (`diff -q` confirms all three differ at HEAD).
- **Symptom:** BD-063 shipped both surfaces in one commit (`12243e1`); subsequent edits risk diverging the pair further (or accidentally syncing them via lockstep edit when one surface should be different). The pair is parallel-by-design but not byte-identical, creating maintenance friction.
- **Contamination pathway:** Pack-side issue forms (forms for the PACK repo's issue tracker) may import project-side wording or vice versa; cross-bias risk.
- **Elimination feasibility:** **LOW** — structurally required (GitHub reads `.github/ISSUE_TEMPLATE/` at the repo root for issue templates; both pack repo and client repos need their own). The pair cannot be eliminated, but the parallel maintenance burden can be made explicit (test that the pair stay either byte-identical OR have a documented diff contract).

### F-4: `QUICKSTART.md` (root)
- **Path:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/QUICKSTART.md`
- **Why shared:** Audience-mixed — addresses developers setting up a coding project (project-side voice) but also serves as the pack-repo landing-page Quick Start (pack-side discovery surface). Referenced from both pack-only (`HELP-FRAGMENT-PACK.md`) and project-side template files (`project-template/README.md`, `project-template/.gemini/commands/pack-help.toml`).
- **Symptom:** The file's verbiage hovers between "what is this pack and how do I install it on my project" (project-side) and "what is the pack repo" (pack-side). Cleaner split would put pack-repo landing info in README.md (already happens, partially) and project-install QUICKSTART into `project-template/QUICKSTART.md` (does not currently exist as a separate copy).
- **Elimination feasibility:** **MEDIUM** — design needed to split the audience cleanly; many references would need updating.

### F-5: `OPTIONAL-FEATURES.md` (root, but referenced as `docs/pack/OPTIONAL-FEATURES.md` from project-side)
- **Path:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/OPTIONAL-FEATURES.md`
- **Why shared (or mis-located):** File is at pack root but multiple project-side files (HELP-FRAGMENT.md, pack-help SKILL.md across all three CLIs) reference path `docs/pack/OPTIONAL-FEATURES.md` as if it were installed at client repos. Either: (a) it SHOULD be installed at `project-template/docs/pack/OPTIONAL-FEATURES.md` and currently isn't, or (b) the project-side references are wrong.
- **Symptom:** Installed-path-vs-source-path discrepancy. Per the v8 audit + recent BD work, this content appears to be intended for both audiences. The bare-filename pattern in pack-help fragments suggests "look it up locally" but the file isn't present at client install.
- **Elimination feasibility:** **HIGH** — design decision (install copy vs cross-link with explicit qualifier vs separate pack-only and project-only files). Mechanical implementation is straightforward.

### F-6: Trinity files at pack-root vs `project-template/` (CLAUDE/AGENTS/GEMINI)
- **Paths:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/{CLAUDE,AGENTS,GEMINI}.md` and `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/{CLAUDE,AGENTS,GEMINI}.md`
- **Why shared:** Same filenames; different files; both pairs are CLI-required (CLIs read `CLAUDE.md` etc. at the working-tree root). The pack-root trinity governs PACK-REPO behavior; the project-template trinity is INSTALLED to client repos to govern THEIR behavior.
- **Symptom:** Naming collision at the prose level — discussions of "CLAUDE.md" need disambiguation. Pack memory's "Filename uniqueness heuristic" explicitly carves out trinity files as exempted but requires prose disambiguation ("pack-root `CLAUDE.md`" vs "project-template `CLAUDE.md`"). When disambiguation slips, cross-bias risk rises (an instruction meant for one trinity gets pasted into the other).
- **Contamination pathway:** V1 finding (`240867d`) is direct manifestation — the F-7 reviewer finding meant for the project trinity may have been written by an actor with the pack trinity in mind.
- **Elimination feasibility:** **LOW** — structurally required pair (each CLI mandates these names at the working-tree root). Cannot rename. Mitigation: stronger prose disambiguation discipline + reviewer protocol amendments. Or: trinity prose duplication audit — find the cases where the same prose lives in both pairs and either justify or split.

### F-7: pack-side / project-side parallel `.claude` / `.codex` / `.gemini` trees
- **Paths:** root `.claude/`, `.codex/`, `.gemini/` and `project-template/.claude/`, `project-template/.codex/`, `project-template/.gemini/`
- **Why parallel:** Same structural pattern (each CLI dir has `agents/`, `skills/`, `commands/` subdirs). Different content audiences.
- **Symptom:** While not strictly an anti-pattern (parallel-by-design), it's a contamination opportunity — agent files like `pack-architect.md` (pack-side) and `architect.md` (project-side) live at structurally parallel paths and can be confused in edits. The pack `pack-help` skill (root `.claude/skills/pack-help/`) and the project `pack-help` skill (`project-template/.claude/skills/pack-help/`) are different content sharing a directory name.
- **Elimination feasibility:** **LOW** — structurally required (CLI conventions). Existing convention (pack-side agents prefixed `pack-`, skills sometimes overlap) is mostly working; reinforcement could come from CI parity-check that pack-side files use `pack-` prefix and project-side files do NOT.

**§F count:** 7 SHARED-ANTI-PATTERN entries (F-1..F-7). Elimination feasibility distribution: HIGH = 1 (F-5), MEDIUM = 4 (F-1, F-2, F-4, design-dependent), LOW = 3 (F-3, F-6, F-7 — structurally required).

---

## §G — Summary + verdict counts

### Root-directory inventory (§A)
- Total entries at root (files + dotted dirs): **18**
- STAYS: **12** (8 files + 4 dotted dirs `.claude/.codex/.gemini/.github/`; includes `.DS_Store` as STAYS-IGNORED)
- MOVES: **6 confirmed + 1 conditional** (`HELP-FRAGMENT-PACK.md`, `HELP-FRAGMENT-TRACKER.md`, `OPTIONAL-FEATURES.md`, `PACK-AGENTS.md`, `PACK-CHAT.md`, `QUICKSTART.md`, plus `tracker.toml.pack-example` conditional)
- MOVES classification: 5 PACK-ONLY (`HELP-FRAGMENT-PACK`, `HELP-FRAGMENT-TRACKER`, `OPTIONAL-FEATURES`, `PACK-AGENTS`, `PACK-CHAT`), 1 SHARED-ANTI-PATTERN-CANDIDATE (`QUICKSTART`), 1 conditional PACK-ONLY (`tracker.toml.pack-example`).

### Directory inventory (§B)
- Total logical directory entries enumerated: **43** (B1..B43; excludes `.git`, `__pycache__`, generated)
- PACK-ONLY: **26** (B1, B2, B3, B5-B14, B29-B35, B38, B39)
- PROJECT-ONLY: **16** (B15-B28, B40-B43)
- SHARED-ANTI-PATTERN: **2** (B4 `.github/`, B37 `supporting-docs/`)
- IGNORED-GENERATED: **1** (B36 `scripts/__pycache__/`)

### v11 commit audit (§C)
- Total v11 commits scanned: **261** (`v10.1..HEAD`)
- PACK-ONLY commits: **216**
- PROJECT-ONLY commits: **6** (corrected from initial classification of 7; `d8e6a02` is MIXED)
- MIXED commits: **39** (corrected from initial 38; including `d8e6a02`)
- **Boundary violations flagged from MIXED roster: 4** (V1, V2, V9, V10)
- **TYPE-2 confirmed violations:** 1 (V1 `240867d`)
- **TYPE-1 confirmed violations:** 1 strict (V2 `aaa61b3`), plus V10 partial (`8ba0164` misrepresents scope)
- **TYPE-3 confirmed violations:** 0
- **TYPE-4 confirmed violations:** 4 grouped (V3 PLATFORM-SKILLS, V4 CONCEPTUAL-REVIEW-METHODOLOGY, V5 MERGE-STRATEGY, V6 MIGRATION-v10-to-v11, V7 audit-methodology, V8 trinity TOOL-COMPARISON pointer) = **6 finding clusters**
- **TYPE-5 heuristic findings:** 2 (T5-A trinity agent-list anti-SSOT pattern; T5-B CONCEPTUAL-REVIEW pack-internal mirror)
- **Severity distribution (across all V/T findings):**
  - HIGH: 4 (V1, V3, V4, T5-A)
  - MEDIUM: 6 (V2, V5, V7, V8, V10, T5-B)
  - LOW: 3 (V6, V9, V11/V12 cleanup notes)

### Project-side reference scan (§D)
- Confirmed CONTAMINATION references: **17** (per §D-9: D-1=4, D-4=1, D-5=9, D-7=1, D-8=2)
- AMBIGUOUS-pending-§F (CONCEPTUAL-REVIEW-METHODOLOGY-related): **11**
- AMBIGUOUS-other: **8** (MERGE-STRATEGY audience, OPTIONAL-FEATURES installed-path mismatch, METHODOLOGY historical attribution, HELP-FRAGMENT-PACK qualified ref)
- LEGITIMATE references (feedback-channel + project-internal BACKLOG/CHANGELOG): **~57**
- **Total grep hits triaged in §D:** ~93

### Path-reference scan for MOVES candidates (§E)
- `PACK-AGENTS.md`: ~25 refs (21 pack-only OK + 4 project-side CONTAMINATION)
- `HELP-FRAGMENT-PACK.md`: ~22 refs (20 pack-only OK + 1 CONTAMINATION + 1 AMBIGUOUS)
- `HELP-FRAGMENT-TRACKER.md`: ~25 refs (mostly pack-only)
- `OPTIONAL-FEATURES.md`: ~20+ refs (5 project-side installed-path-mismatch AMBIGUOUS-likely-CONTAMINATION)
- `PACK-CHAT.md`: ~30+ refs (mostly pack-only)
- `QUICKSTART.md`: ~25 refs (cross-audience — SHARED)
- `tracker.toml.pack-example`: ~15 refs (mostly pack-only)
- **Aggregate path-reference count for the 7 MOVES candidates: ~160+ references**

### Shared-anti-pattern catalog (§F)
- Total SHARED-ANTI-PATTERN entries: **7** (F-1..F-7)
- Elimination feasibility distribution: HIGH = 1 (F-5), MEDIUM = 4 (F-1, F-2, F-4, plus considerations on F-1 split), LOW = 3 (F-3, F-6, F-7)

---

## Cross-reference observations (no design content)

Per the cross-reference instruction, the following pre-existing artifacts contain partial answers that this audit incorporates without inheriting their framing:

- `maintenance-docs/v11-implementation/PATH-C-CURATION.md` § 3 surfaces `P-missed-7` (project-design-investigation-first) which is the META-cause of TYPE-2 / TYPE-5 violations in this audit. Confirmed orthogonal to audit findings.
- `maintenance-docs/v11-implementation/ARCHITECTURE-BATCH-19B-STRATEGIC-PRINCIPLES.md` — referenced as Path C architect synthesis; does not contain a full audit; this audit's scope is BROADER and DEEPER.
- `maintenance-docs/v11-implementation/RESEARCH-BATCH-19B-STRATEGIC-RULES.md` — researcher pass on strategic rules; does not catalog boundary violations.
- `maintenance-docs/v11-implementation/ORCHESTRATION-PLAN-BD-175.md` — this BD's orchestration plan (input to this audit).

---

## Boundary-finding density observations (descriptive, not prescriptive)

- All 4 HIGH severity findings cluster on project-side trinity (V1, T5-A) or pack-only methodology mis-located to supporting-docs (V3, V4). No HIGH findings in `project-template/.claude`, `.codex`, or `.gemini` agent prompt files (those came up clean on the pack-* agent name grep, per §C pre-amble).
- All 17 confirmed CONTAMINATION references (§D-9) cluster in 6 files:
  - Project trinity (3 trinity files): V1 PACK-AGENTS refs + V8 TOOL-COMPARISON refs = 6 hits
  - `project-template/docs/pack/PLATFORM-SKILLS.md`: 2 hits (PACK-AGENTS + maintenance-docs)
  - `project-template/skills/audit-methodology/SKILL.md`: 2 hits (maintenance-docs)
  - `supporting-docs/MIGRATION-v10-to-v11.md`: 4 hits (Pack Chat + maintenance-docs ×3)
  - `supporting-docs/MERGE-STRATEGY.md`: 2 hits (HELP-FRAGMENT-PACK + OPTIONAL-FEATURES)
  - `supporting-docs/DEPENDENCIES.md`: 1 hit (OPTIONAL-FEATURES)
- The 11 AMBIGUOUS-pending-§F references all cluster on a SINGLE file (`supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md`); resolving F-1's audience classification for this file would convert all 11 to either LEGITIMATE (if file moves to pack-only directory) or HIGH-priority CONTAMINATION (if file stays in supporting-docs and content is rewritten for project-side audience).

---

## End of audit

Phase 1 DISCOVERY complete. No design or recommendation content above. All verdicts and classifications are descriptive observations of HEAD state as of `3d8cc8b` on v11-dev. Phase 2 architects (A/B/C) take this audit as input and decide what to do.

