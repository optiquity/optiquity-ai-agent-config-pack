# RESEARCH-BD-195-SEGMENT-R9-archive-companions

**Author:** pack-docs-researcher (read-only audit segment R9)
**Date:** 2026-05-29
**Branch:** v11-dev
**Status:** Read-only audit deliverable; no implementation
**Output file:** `maintenance-docs/v11-implementation/RESEARCH-BD-195-SEGMENT-R9-archive-companions.md`

## Segment / owned paths (manifest)

- `maintenance-docs/archive/` — ALL of it MINUS `maintenance-docs/prison/`:
  - Top-level `V9-*.md`, `V10-*.md` (the non-prisoned remainder)
  - `maintenance-docs/archive/v10-working/` (25 files)
  - `maintenance-docs/archive/v11/` (201 workflow-artifact docs: IMPL-REPORTs, PACK-REVIEWs, ARCHITECTURE-*, PLAN-*, AUDIT-*, etc.)
- `xcode-companion-templates/` (6 files — audited line-by-line, NOT archive)
- `vscode-companion-templates/` (4 files — audited line-by-line, NOT archive)

Out of scope (PRISON RULE): the 11 docs now under `maintenance-docs/prison/`. Not read, cited, or flagged.

## Coverage attestation

- **Companion templates (10 files):** every file read in full, line-by-line — they are client-shipped templates audited for correctness + version + parity, NOT archive.
- **Archive (226 files):** per the SPECIAL ARCHIVE RULE, the large `archive/v11/` + `v10-working/` + top-level `V9/V10` docs were audited via **targeted grep** for the two flaggable classes only: (a) active outbound references to moved/renamed/prisoned paths, (b) mis-versioning that would mislead a reader treating the doc as current. Methods used:
  1. Grepped ALL 11 prisoned filenames across the entire archive + companions — **zero hits** (no archive/companion doc references a prisoned doc).
  2. Grepped archive for `v11.1` / `v11.0.1` and for `frozen|freeze|froze` + `v11` co-occurrence; read every hit in context.
  3. Spot-verified that live paths referenced from archive (`templates-archive/v11.0/`, `V11.1-DISCUSSION-GITHUB-PROJECTS.md`) still resolve — both EXIST.
  4. Extracted script-path outbound references from the two per-entry architecture proposal docs and classified them (proposed-future vs live).
- The two large per-entry architecture proposal docs (`ARCHITECTURE-PER-ENTRY-FLAT-FILES.md`, `ARCHITECTURE-PER-ENTRY-PACK-VS-CLIENT.md`) had their headers + version-recommendation sections read directly (not full line-by-line) — they carry the heaviest `v11.1` density; evaluated and NOT flagged (see Coverage map note).
- No file skimmed in a way that would hide a flaggable item; the grep method is appropriate per the segment's stated allowance for `archive/v11/`.

## Findings count

- BLOCKER 0 / MUST 1 / SHOULD 0 / NIT 2

---

## Findings

### R9-F01 — Xcode Codex `config.toml` declares 7 agents whose `config_file` targets are never shipped or installed
- Severity: MUST
- Category: C (cross-reference); free tags: client-shipped, correctness, broken-config
- Surface(s): `xcode-companion-templates/Codex/config.toml` (`[agents.*]` blocks); install instructions at `supporting-docs/SETUP-NEW.md` § "5.D — (Apple only) Install Xcode companion files" and `supporting-docs/SETUP_TEMPLATE.md` § Xcode copy block; companion `xcode-companion-templates/README.md` § Installation
- Side: client-shipped
- Evidence: `config.toml` declares seven agents, e.g.
  `[agents.planner]` / `config_file = "agents/planner.toml"`,
  `[agents.coder]` / `config_file = "agents/coder.toml"`, …,
  `[agents.apple_architect]` / `config_file = "agents/apple-architect.toml"`,
  `[agents.docs_researcher]` / `config_file = "agents/docs-researcher.toml"`.
  But `find xcode-companion-templates -type d` returns only `Codex` and `ClaudeAgentConfig` — there is **no `agents/` subdirectory**. The README install block copies only `Codex/AGENTS.md` and `Codex/config.toml` (no `agents/` recursion); SETUP-NEW.md 5.D copies the same two files only. After install at `~/Library/Developer/Xcode/CodingAssistant/codex/`, the seven `config_file = "agents/*.toml"` paths point at files that do not exist.
- Why it's a problem: Codex resolves `config_file` relative to the config's location; the referenced agent toml files are absent both in the template dir and at the install target, so every declared sub-agent fails to load. This is a broken cross-reference (lens C) in a client-shipped template — the config promises seven agents that cannot exist. (Compare: `project-template/.codex/` ships a full `agents/` tree with `planner.toml`, `coder.toml`, `reviewer.toml`, etc., matching its own `config.toml` `config_file` declarations — so the contract is "ship the referenced agent files." The Xcode companion violates that contract.)
- Recommendation: Either (a) add an `xcode-companion-templates/Codex/agents/` directory shipping the 7 referenced toml files (planner, coder, reviewer, tester, apple-architect, repo-ops, docs-researcher) and extend the README + SETUP-NEW.md + SETUP_TEMPLATE.md install blocks to copy the `agents/` dir; or (b) remove the `[agents.*]` blocks from the Xcode `config.toml` if machine-level Xcode Codex config is intentionally agent-less. Decision belongs to the user — confirm whether Xcode-level Codex is meant to support sub-agents at all.
- Cross-segment touch points: whichever segment owns `supporting-docs/SETUP-NEW.md` / `SETUP_TEMPLATE.md` (install-block edits required if remediation is option (a)); whichever segment owns `project-template/.codex/` (reference contract for "ship the agent files").
- Confidence: high (directory listing + install-block reads are dispositive; this is a pre-existing defect, not version-related).

### R9-F02 — Xcode Codex `config.toml` model string `gpt-5` lags project-template `gpt-5.4`
- Severity: NIT
- Category: A (version) + D (parity drift); free tags: client-shipped, model-currency
- Surface(s): `xcode-companion-templates/Codex/config.toml` (top-level `model = "gpt-5"` + `[profiles.cloud-default]` `model = "gpt-5"`); compare `project-template/.codex/config.toml` (`model = "gpt-5.4"` in both the top-level key and `[profiles.cloud-default]`)
- Side: client-shipped
- Evidence: Xcode template: `model = "gpt-5"` (lines 2 and 20). Project-template companion: `model = "gpt-5.4"` (lines 2 and 37). The two local-model strings (`gpt-oss:20b`, `qwen3-coder-30b-a3b-instruct-8bit`) match between the two configs; only the cloud-default model lags.
- Why it's a problem: The Xcode companion README states these files "mirror the … project-level policy"; the cloud model pin has drifted relative to the project-template Codex config, so a Mac installing the companion gets an older default model than a project repo set up from the same pack. Low impact (config is user-editable and the model string is a default), but it is an unintended parity drift between two pack-shipped Codex configs.
- Recommendation: Bump the Xcode `config.toml` cloud-default `model` to match the project-template value (`gpt-5.4`) in both the top-level key and `[profiles.cloud-default]`, OR confirm with the user that the Xcode companion intentionally pins an older cloud model. If matched, keep the two in lock-step going forward.
- Cross-segment touch points: whichever segment owns `project-template/.codex/config.toml` (the parity reference).
- Confidence: high (both files read; the drift is exact and unambiguous). Severity NIT because it is a default value the user can override and not a functional break.

### R9-F03 — Xcode README "v9 policy" + "capability is not split by tool identity" sits oddly beside the Phase-routing tables that DO assign tool defaults
- Severity: NIT
- Category: A (version staleness) + internal-consistency; free tags: client-shipped, doc-prose
- Surface(s): `xcode-companion-templates/README.md` § Policy ("These companion files mirror the v9 project-level policy … Capability is not split by tool identity"); the shipped `xcode-companion-templates/ClaudeAgentConfig/CLAUDE.md` and `xcode-companion-templates/Codex/AGENTS.md` both carry a `## Phase routing — default agent assignments` table that assigns each phase a Default of Claude Code OR Codex
- Side: client-shipped
- Evidence: README: "These companion files mirror the **v9** project-level policy: … Capability is not split by tool identity — defaults may differ but both tools can do all work categories." The companion `CLAUDE.md`/`AGENTS.md` then ship a routing table, e.g. `| Implementation | Codex | workspace-write sandbox |`, `| Code review | Claude Code | Deep multi-file analysis |`.
- Why it's a problem: Two soft issues. (1) Version-string staleness — the pack is at v11.0 (README.md version table) but the companion README still describes itself as mirroring "v9" policy; the companion files were last meaningfully updated in v9-dev/v10 (git: `9429f15`, `0907cd2`). A reader treating the companion as current may wonder if it is stale. (2) The "not split by tool identity" prose and the per-phase Default column can read as mildly contradictory, though they are reconcilable (the table is *defaults*, not *exclusive reservations*, which the prose explicitly allows: "defaults may differ"). Not a hard contradiction.
- Recommendation: Low-priority cleanup. Consider updating "v9 project-level policy" to the current major (or to a version-neutral phrasing like "the pack's project-level capability policy") so the companion does not advertise a stale version. The prose/table tension does not require a change but a one-line note in the README ("the routing table lists defaults, not exclusive assignments") would remove ambiguity. Defer if the user considers companion templates intentionally version-pinned to their last-touched era.
- Cross-segment touch points: none (self-contained to the companion templates).
- Confidence: medium (version-string staleness is factual; the prose/table tension is a judgment call, hence NIT + medium).

---

## Coverage map

### Companion templates (line-by-line)
- `xcode-companion-templates/README.md` → R9-F03 (also implicated in F01 install-block)
- `xcode-companion-templates/.gitignore` → clean
- `xcode-companion-templates/ClaudeAgentConfig/CLAUDE.md` → clean (referenced by R9-F03 routing-table note; no defect in the file itself)
- `xcode-companion-templates/ClaudeAgentConfig/settings.json` → clean (valid `$schema`; hook + permission shape consistent)
- `xcode-companion-templates/Codex/AGENTS.md` → clean (referenced by R9-F03 routing-table note; no defect in the file itself)
- `xcode-companion-templates/Codex/config.toml` → R9-F01 (broken agent refs), R9-F02 (model drift)
- `vscode-companion-templates/README.md` → clean
- `vscode-companion-templates/.vscode/extensions.json` → clean
- `vscode-companion-templates/.vscode/settings.json` → clean
- `vscode-companion-templates/.vscode/tasks.json` → clean (tasks call `./scripts/*.sh`; README correctly notes those scripts must exist in the target project — not a pack-side broken ref)

### Archive (targeted-grep audit)
- `maintenance-docs/archive/v11/` (201 docs) → **clean** of both flaggable classes:
  - Zero outbound references to any of the 11 prisoned docs.
  - All `frozen`/`freeze` + `v11` hits describe OTHER frozen artifacts (byte-equal templates-archive copies, the frozen `migrate-v9-to-v10.sh`, the frozen archive tree itself) — none assert "v11.0 was frozen as a release." Not the categorical error; legitimate historical/descriptive usage; NOT flagged per the SPECIAL ARCHIVE RULE.
  - All `v11.1` hits fall into NON-flaggable buckets: (i) the pack-memory rule "No deferral to v11.1+ without explicit user direction" cited as-is; (ii) roundtrip test-fixture stub dirs `bd-v11.1/` / `bd-v11.2/`; (iii) references to `V11.1-DISCUSSION-GITHUB-PROJECTS.md` (GitHub Projects is legitimately v11.1+ — explicitly NOT flaggable); (iv) the two per-entry architecture proposal docs' v11.1 *recommendation* (see note below).
  - Live paths referenced from archive (`maintenance-docs/v11-research/templates-archive/v11.0/`, `maintenance-docs/v11-research/V11.1-DISCUSSION-GITHUB-PROJECTS.md`) both resolve.
- `maintenance-docs/archive/v10-working/` (25 docs) → clean (no prisoned-doc refs; no flaggable mis-versioning).
- `maintenance-docs/archive/V9-*.md`, `V10-*.md` (top-level remainder) → clean (frozen v9/v10 historical content; no active outbound refs to moved paths surfaced by the prisoned-doc and v11.1 greps).

### Evaluated and NOT flagged (recorded for the parent's awareness)
- `maintenance-docs/archive/v11/ARCHITECTURE-PER-ENTRY-FLAT-FILES.md` and `ARCHITECTURE-PER-ENTRY-PACK-VS-CLIENT.md` recommend the **per-entry flat-file** feature target as **v11.1** ("Recommended version target: v11.1 (minor)"). The per-entry trees subsequently shipped in **v11.0** (BD-167/BD-168; live `project-template/docs/project/{backlog,changelog}/` trees + README v11.0 changelog Checks 32/33/34). So these docs' recommendation was overtaken by events. They are **NOT flagged** because: (a) both are dated 2026-05-12 with explicit `Status: Architecture proposal; read-only deliverable; no implementation in this batch`; (b) the v11.1 reference is a *recommendation*, not an assertion of shipped reality; (c) the SPECIAL ARCHIVE RULE directs flagging only mis-versioning that would mislead a reader treating the doc as **current** — a clearly-headed proposal recommending a target version is frozen design-time content, not a current-state mislabel. Their proposed-future scripts (`scripts/decompose-monolithic.sh`, `scripts/migrate-v11.0-to-v11.1.sh`, `scripts/lib/per-entry-bulk.sh`, etc.) do not exist yet for the same reason and are NOT stale outbound refs. Surfaced here so the parent can confirm the judgment; recommend no action.
