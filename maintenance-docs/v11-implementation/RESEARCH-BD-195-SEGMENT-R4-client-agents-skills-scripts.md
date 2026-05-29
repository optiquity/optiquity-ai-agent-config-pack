# RESEARCH-BD-195-SEGMENT-R4-client-agents-skills-scripts

Read-only audit segment R4 — client-shipped product: agents, skills, scripts, config.
Branch v11-dev. All paths repo-relative.

## Segment / owned paths (manifest)

- `project-template/.claude/` (16 agents + settings.json + settings.local.example.json + 2 command-skills)
- `project-template/.codex/` (16 agents + config.toml + config.toml.example + requirements.toml + 2 command-skills)
- `project-template/.gemini/` (16 agents + settings.json + .env.example + 2 commands)
- `project-template/skills/` (36 SKILL.md)
- `project-template/scripts/` (15 .sh)
- `project-template/.github/` (3 yml), `project-template/proto/` (4), `project-template/server/` (2)
- top-level: `pyproject.toml`, `pyrightconfig.json`, `.mcp.json.example`, `.gitignore`, `agent-run.sh`, `tracker.toml.project-example`, `README.md`

## Coverage attestation

Every owned path read or scanned. Full reads: all three `coder` agents; `auditor` (claude+gemini); `.claude/settings.json`; `.codex/config.toml`; `.codex/config.toml.example`; `.codex/requirements.toml`; `.gemini/settings.json`; `.gemini/.env.example`; `.mcp.json.example`; `bootstrap.sh`; `agent-post-edit-check.sh`; `pm-startup/SKILL.md`; `pack-help.toml`; `.github/ISSUE_TEMPLATE/work-item.yml`; `tracker.toml.project-example`; `project-template/README.md`; `audit-methodology/SKILL.md` (skip-rules + cross-platform sections). Remaining 13 agents ×3 CLIs, 34 platform skills, 11 other scripts, proto/server, and the other 2 issue forms covered by targeted grep sweeps (version refs v9/v10/v11/frozen; boundary refs PACK-*/pack-ops/maintenance-docs/BD-NNN/Pack Chat; pack-path leaks supporting-docs/maintenance-docs; CLI parity counts + name-set diffs). Agent/skill cross-CLI parity verified by `diff` (pm-startup, pack-help byte-identical) and count+name-set checks (16 agents ×3, identical names; 36 skills distributed). Skimmed (rationale): the 13 non-`coder` agent bodies per CLI — sampled coder (deep) + auditor (deep) + grep for leak/version tokens across all; parity established structurally.

## Findings count

BLOCKER 0 / MUST 2 / SHOULD 3 / NIT 2

## Findings

### R4-F01 — `.mcp.json.example` points clients at a pack-only doc that is never installed
- Severity: MUST
- Category: C (cross-reference, unresolvable), B (boundary)
- Surface(s): `project-template/.mcp.json.example`, `local-rag.env._readme`
- Side: client-shipped
- Evidence: `"_readme": "Set BASE_DIR to the absolute path of this project. See supporting-docs/CLI-PM-SETUP.md for setup instructions."`
- Why it's a problem: `.mcp.json.example` is client-shipped (present in `test-fixtures/v11-flat-file/.mcp.json.example`), but `CLI-PM-SETUP.md` lives only at pack `supporting-docs/CLI-PM-SETUP.md` and is NOT copied to clients (`init-project.sh` copies only `METHODOLOGY.md` and `INSTALL-PROCEDURES.md` from `supporting-docs/`). At a client install there is no `supporting-docs/` directory — the pointer is dead. Violates the pack/project separation rule (`feedback_pack_project_separation_of_concerns`) and client-facing token economy (a pack-only path on a RAG/client surface, `feedback_client_facing_token_economy`).
- Recommendation: Replace the cross-reference with the client-installed equivalent (`docs/pack/INSTALL-PROCEDURES.md` if it carries the local-rag setup, or `docs/pack/PM-CHAT.md` § RAG ingestion manifest) or drop the "See …" sentence and inline the one-line instruction. Confirm the target exists at client install before re-pointing.
- Cross-segment touch points: segment owning `supporting-docs/CLI-PM-SETUP.md` (verify whether that doc should be split client/pack); segment owning `docs/pack/` client docs.
- Confidence: high (fixture confirms ship; init-project.sh copy list confirms CLI-PM-SETUP.md not installed).

### R4-F02 — Client-shipped Codex config example leaks a pack-internal maintenance doc + commit SHA
- Severity: MUST
- Category: B (boundary, token-economy), C (bare cross-reference)
- Surface(s): `project-template/.codex/config.toml.example` (header comment block)
- Side: client-shipped
- Evidence: `# Source: V10-CODEX-MCP-RESEARCH.md (commit 73d480e). Codex supports MCP via [mcp_servers.<name>] tables …`
- Why it's a problem: `.codex/config.toml.example` is client-shipped (present in fixture). `V10-CODEX-MCP-RESEARCH.md` lives only at pack `maintenance-docs/V10-CODEX-MCP-RESEARCH.md` — a pack-internal research doc never present at client install. Citing a pack maintenance-doc + raw commit SHA on a client surface violates the deliverable-only / separation-of-concerns rules and wastes RAG tokens at client query time (`feedback_client_facing_token_economy`, `feedback_pack_project_separation_of_concerns`). The reader at a client has no doc to follow and no repo to resolve `73d480e`.
- Recommendation: Remove the "Source: V10-CODEX-MCP-RESEARCH.md (commit 73d480e)" provenance line from the client-shipped example. Keep the substantive guidance (STDIO via `command`, HTTP gated by `experimental_use_rmcp_client`) since that is client-useful; move the provenance citation to the pack-internal authoring history if needed.
- Cross-segment touch points: segment owning `maintenance-docs/V10-CODEX-MCP-RESEARCH.md`.
- Confidence: high.

### R4-F03 — `bootstrap.sh` comment references a pack-only doc absent at client install
- Severity: SHOULD
- Category: C (cross-reference), B (boundary)
- Surface(s): `project-template/scripts/bootstrap.sh`, top comment block (skills-distribution note)
- Side: client-shipped
- Evidence: `# .codex/skills/, and .gemini/skills/ by \`init-project.sh\` (see` / `# in the pack repo: supporting-docs/SETUP-NEW.md Step 3).`
- Why it's a problem: `bootstrap.sh` is client-shipped (copied by `init-project.sh`); `SETUP-NEW.md` lives only at pack `supporting-docs/SETUP-NEW.md` and is not installed to clients. The comment partly self-discloses ("in the pack repo") which softens it, but a developer reading the client copy cannot follow it. Same separation-of-concerns / token-economy class as R4-F01/F02, lower severity because it is an inline comment with a hedge.
- Recommendation: Either drop the parenthetical doc cite (the surrounding comment already explains the behavior) or rephrase to a client-resolvable reference ("see your pack version's migration guide"). Do not name pack-only `supporting-docs/SETUP-NEW.md` in client-shipped source.
- Cross-segment touch points: segment owning `supporting-docs/SETUP-NEW.md`.
- Confidence: high.

### R4-F04 — Gemini settings.json claims local-rag indexes a second doc that contradicts the authoritative RAG manifest
- Severity: SHOULD
- Category: E (ENCODING lock-step), D (cross-CLI parity), correctness
- Surface(s): `project-template/.gemini/settings.json` (`_tools`); cross: `project-template/.mcp.json.example` (`_tools`); `project-template/skills/pm-startup/SKILL.md` Step 4
- Side: client-shipped
- Evidence: `.gemini/settings.json` `_tools`: "The mcp-local-rag server provides semantic search over docs/pack/METHODOLOGY.md and docs/pack/INSTALL-PROCEDURES.md." vs `.mcp.json.example` `_tools`: "It provides semantic search over METHODOLOGY.md." vs `pm-startup/SKILL.md` Step 4: "Default manifest in v10 is exactly one path: `docs/pack/METHODOLOGY.md`".
- Why it's a problem: Three client-shipped surfaces that ENCODE the same invariant (what local-rag indexes) disagree. The pm-startup skill is the operational authority and says the default manifest is exactly one path (METHODOLOGY.md); the Gemini settings.json overstates it by adding INSTALL-PROCEDURES.md. ENCODING surfaces must move in lock-step (`feedback_enumerate_encoding_surfaces_in_audits`); this is a drift that would make a Gemini user expect INSTALL-PROCEDURES.md retrievals that the manifest never ingests.
- Recommendation: Align all three. Pick the authoritative manifest text (currently single-path METHODOLOGY.md per pm-startup Step 4 and PM-CHAT.md § RAG ingestion manifest) and make the `_tools` strings in `.gemini/settings.json` and `.mcp.json.example` match it (or, if INSTALL-PROCEDURES.md is genuinely intended in the manifest, update PM-CHAT.md + pm-startup Step 4 + .mcp.json.example together). Verify against the PM-CHAT.md manifest (other segment) before deciding direction.
- Cross-segment touch points: segment owning `docs/pack/PM-CHAT.md` § RAG ingestion manifest (the SSOT); R5/R-docs for METHODOLOGY/INSTALL-PROCEDURES install.
- Confidence: high (three quoted surfaces; pm-startup is authoritative).

### R4-F05 — `pm-startup` skill carries stale "v10" version labels in a v11 pack
- Severity: SHOULD
- Category: A (version currency)
- Surface(s): `project-template/skills/pm-startup/SKILL.md` Step 4 ("Default manifest in v10 …"); and the 3 distributed copies (`.claude/skills/pm-startup/SKILL.md`, `.codex/skills/pm-startup/SKILL.md`, `.gemini/commands/pm-startup.toml`) — byte-identical to canonical for this line
- Side: client-shipped
- Evidence: Step 4: "Default manifest in **v10** is exactly one path: `docs/pack/METHODOLOGY.md`". Step 0 / Step 6 reads "Pack version: [read from … METHODOLOGY.md]" but the body hardcodes v10 in prose.
- Why it's a problem: This is a v11 pack (BD-195 categorical fact: v11.0 is current/unreleased). A client-shipped skill asserting "in v10" the default manifest behavior is stale version prose. Not the v11.0/v11.1 categorical error (no phase-parts/groupings/frozen claim), but a version-currency drift (Lens A). NOTE — distinct from the Step 0 v9→v10 migration mechanics (`.pack-migration-backup/v9.3-to-v10.0`, `migration-v9-to-v10` branch, `_v9-customized`, `_v9-backup.md`): those legitimately describe upgrading FROM v9/v10 and are not flagged here.
- Recommendation: Change "Default manifest in v10" to version-neutral phrasing ("The default manifest is exactly one path: `docs/pack/METHODOLOGY.md`") or "v11". Apply in canonical `skills/pm-startup/SKILL.md` AND the three distributed copies in the same edit (parity).
- Cross-segment touch points: none (all four copies in R4-owned trees).
- Confidence: medium (clearly stale prose; low blast radius — cosmetic to behavior, but client-visible).

### R4-F06 — `project-template/README.md` is v10-stale (header, skill count, design-doc shorthand, config row)
- Severity: NIT
- Category: A (version), C (bare-version shorthand + count drift)
- Surface(s): `project-template/README.md` (title; skills row; line 9; Config row)
- Side: maintenance-doc (pack-authoring artifact — NOT client-shipped; `init-project.sh` never copies template README over a target's README, and the fixture has no template-derived README)
- Evidence: Title: "# Project Template — AI Agent Config Pack **v10**". Skills row: "30 skills per tool" (canonical `project-template/skills/` has 36 SKILL.md; fixture distributes 36). Line 9: "METHODOLOGY.md lives under `docs/pack/` per **V10-DESIGN.md Part 7 §7.6**" (bare pack-internal design-doc shorthand). Config row lists only "`.claude/settings.json`, `.codex/config.toml`, `.mcp.json.example`" — omits `.gemini/settings.json` and `.gemini/.env.example`.
- Why it's a problem: Stale across Lens A (v10 header in a v11 pack) and Lens C (skill count drift 30→36; bare-version shorthand "V10-DESIGN.md Part 7 §7.6" violates the filename-uniqueness/bare-shorthand-leak rule — a reader has no resolvable path; also references `QUICKSTART.md` in pack root). Because this README is a pack-authoring artifact (not RAG-indexed, not installed), severity is NIT — but it is inside R4-owned paths and actively misleads a pack maintainer.
- Recommendation: Refresh: title → v11; skills count 30 → 36; replace "V10-DESIGN.md Part 7 §7.6" with the current authoritative reference or drop it; add the two `.gemini` config files to the Config row; verify "Agent files … 16 agents" and "Scripts … 15 scripts" still hold (they do).
- Cross-segment touch points: any segment auditing pack-root `QUICKSTART.md` / `V10-DESIGN.md` existence/currency.
- Confidence: high (counts verified; fixture confirms README not client-shipped).

### R4-F07 — `.codex/config.toml.example` "v10 ships STDIO only" version prose stale in v11 pack
- Severity: NIT
- Category: A (version currency)
- Surface(s): `project-template/.codex/config.toml.example` (MCP transport note)
- Side: client-shipped
- Evidence: "`v10 ships STDIO only; HTTP transport stability is research OQ-1 (defer to a future pack version if needed).`"
- Why it's a problem: Client-shipped file says "v10 ships STDIO only" in a v11 pack. Lens A version-currency drift. The "defer to a future pack version" is a generic, unblocked-feature deferral (HTTP MCP transport), NOT the v11.0/v11.1 categorical error and NOT phase-parts/groupings — so it is permissible as a feature deferral, but the "v10" label is stale.
- Recommendation: Update "v10 ships STDIO only" → "v11 ships STDIO only" (or version-neutral "This pack ships STDIO transport only"). Bundle with the R4-F02 provenance-line removal in the same file edit.
- Cross-segment touch points: none.
- Confidence: medium (stale label is clear; the deferral clause itself is acceptable).

## Coverage map

| Owned path | Result |
|---|---|
| `.claude/agents/*` (16) | clean (coder deep; parity by count+name-set+grep) |
| `.codex/agents/*` (16) | clean |
| `.gemini/agents/*` (16) | clean (auditor "coordinate" vs claude "spawn" = justified tool-specific asymmetry) |
| `.claude/settings.json` | clean |
| `.claude/settings.local.example.json` | clean (not opened individually; no leak in grep) |
| `.codex/config.toml` | clean |
| `.codex/config.toml.example` | R4-F02, R4-F07 |
| `.codex/requirements.toml` | clean |
| `.gemini/settings.json` | R4-F04 |
| `.gemini/.env.example` | clean |
| `.mcp.json.example` | R4-F01 |
| `.claude/.codex/.gemini` command-skills (pack-help, pm-startup) | pack-help clean (byte-identical across CLIs); pm-startup → R4-F05 |
| `skills/pm-startup/SKILL.md` (canonical) | R4-F05 |
| `skills/audit-methodology/SKILL.md` | clean (post-v11.0 non-Apple-UI deferral is a legitimate feature deferral, not the categorical error) |
| `skills/*` (other 34 SKILL.md) | clean (v11.0 split refs correct; no frozen/v11.1 leak; grep-swept) |
| `scripts/bootstrap.sh` | R4-F03 |
| `scripts/agent-post-edit-check.sh` | clean |
| `scripts/*` (other 13) | clean (grep-swept; pack-help.sh/init-project.sh refs resolve at client runtime) |
| `.github/ISSUE_TEMPLATE/work-item.yml` | clean (correct polarity: admits td/phase/phase-part, excludes BD; v11.0 labels correct) |
| `.github/ISSUE_TEMPLATE/inbound.yml`, `config.yml` | clean (grep-swept; pack-version v11) |
| `proto/*` (4) | clean |
| `server/*` (2) | clean |
| `pyproject.toml`, `pyrightconfig.json`, `.gitignore`, `agent-run.sh` | clean (grep-swept) |
| `tracker.toml.project-example` | clean (v11.0 backend note correct; TD/BD namespace polarity correct) |
| `README.md` | R4-F06 |
