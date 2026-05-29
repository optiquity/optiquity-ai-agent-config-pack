# RESEARCH-BD-195-SEGMENT-R2-pack-self-agents-skills

Segment R2 — Pack-self agents & skills (pack-root CLI configs). Read-only audit, 5 lenses (A version / B boundary / C cross-reference / D trinity-parity / E ENCODING lock-step).

## Segment / owned paths (manifest)

Pack-root CLI configs (NOT `project-template/`):

- Agents ×3 CLIs: `.claude/agents/pack-{architect,coder,docs-researcher,planner,reviewer}.md`, `.codex/agents/pack-{...}.toml`, `.gemini/agents/pack-{...}.md` (15 files).
- Shared skills ×3 CLIs: `.claude/skills/<name>/SKILL.md`, `.codex/skills/<name>/SKILL.md`, `.gemini/skills/<name>/SKILL.md` for: architecture-review, boundary-investigation, commit-discipline, dependency-intake, documentation, implementation-report, planning, review, verification-harness (27 files), plus pack-help + pack-startup as skills under `.claude/` and `.codex/` (4 files).
- Gemini commands: `.gemini/commands/pack-help.toml`, `.gemini/commands/pack-startup.toml` (2 files).
- `.claude/settings.local.json` (tooling permissions).

## Coverage attestation

Every owned path read in full. The 9 shared skills (architecture-review, boundary-investigation, commit-discipline, dependency-intake, documentation, implementation-report, planning, review, verification-harness) were verified byte-identical across the three CLIs via `diff` (all "identical"), then read once each for content correctness. The 5 agents and pack-help/pack-startup were read per-CLI (frontmatter differs by tool). Referenced paths/scripts/docs were existence-checked via `find`/`ls`. Nothing skimmed.

Structural note (NOT a finding): pack-help and pack-startup live under `skills/` for Claude + Codex but under `commands/` for Gemini. This asymmetry is intentional and matches the `project-template/` canonical structure (`project-template/.gemini/commands/pack-help.toml` vs `project-template/.claude/skills/pack-help/`); it is a documented per-CLI invocation difference, not a parity defect.

## Findings count

BLOCKER 0 / MUST 1 / SHOULD 1 / NIT 1

## Findings

### R2-F01 — pack-root pack-help skill cites moved docs by stale bare name (`PACK-CHAT.md`, `OPTIONAL-FEATURES.md`)
- Severity: MUST
- Category: C (cross-reference, dead path) + D (trinity/parity asymmetry) + filename-uniqueness / BD-175-reorg-leftover
- Surface(s): `.claude/skills/pack-help/SKILL.md` "## Notes" block; `.codex/skills/pack-help/SKILL.md` "## Notes" block
- Side: pack-self
- Evidence: Both files read: `For full documentation, see \`QUICKSTART.md\`, \`README.md\`, \`PACK-CHAT.md\`, and \`OPTIONAL-FEATURES.md\`.` Neither `PACK-CHAT.md` nor `OPTIONAL-FEATURES.md` resolves at pack root — `ls PACK-CHAT.md` and `ls OPTIONAL-FEATURES.md` both return "No such file or directory". The files live only at `pack-ops/PACK-CHAT.md` and `pack-ops/OPTIONAL-FEATURES.md` (confirmed via `find`). The sibling `.gemini/commands/pack-help.toml` already cites the correct paths: `see QUICKSTART.md, README.md, \`pack-ops/PACK-CHAT.md\`, and \`pack-ops/OPTIONAL-FEATURES.md\`.` `QUICKSTART.md` and `README.md` ARE correct bare refs (both live at pack root).
- Why it's a problem: Dead cross-references. The BD-175 directory reorg (commit `59a7dbb`, "root → pack-ops/") moved these two docs under `pack-ops/` and updated the Gemini command, but the Claude and Codex skills were not updated in lock-step — a reorg leftover. Violates the filename-uniqueness rule's "follow the path" intent (CLAUDE.md § Repo conventions → "Filename uniqueness heuristic": references must resolve so prose is unambiguous) and the trinity/quad parity expectation (the three pack-help surfaces must express the same rule; here the Gemini surface diverges with the correct value while Claude/Codex carry the stale value). This is exactly the BD-195 Step-3 target class: a stale reference left over from a prior reorg.
- Recommendation: In both `.claude/skills/pack-help/SKILL.md` and `.codex/skills/pack-help/SKILL.md`, change `\`PACK-CHAT.md\`, and \`OPTIONAL-FEATURES.md\`` to `\`pack-ops/PACK-CHAT.md\`, and \`pack-ops/OPTIONAL-FEATURES.md\`` so all three pack-help surfaces match the Gemini command (which is already correct). Leave `QUICKSTART.md` and `README.md` bare. (Trinity/quad fix touching 2 of 3 pack-help surfaces; Gemini needs no change.)
- Cross-segment touch points: The `project-template/.claude/skills/pack-help/SKILL.md` (project-shipped sibling) already uses the correct project-side paths (`docs/pack/PM-CHAT.md`, `docs/pack/OPTIONAL-FEATURES.md`) — that is the project-side audience and is out of this segment's scope; do NOT byte-copy project-side paths into the pack-root skill. Whoever owns the `project-template/` pack-help quad should confirm parity there independently.
- Confidence: high (both stale refs verified non-resolving by `ls`; correct location verified by `find`; Gemini sibling proves the intended value; git log ties it to the BD-175 reorg commit).

### R2-F02 — pack-planner agent: substantive "state-verifiable questions" rule present only in Claude version, absent from Codex + Gemini
- Severity: SHOULD
- Category: D (trinity/parity asymmetry, unjustified)
- Surface(s): `.claude/agents/pack-planner.md` Responsibilities list ("State-verifiable questions are not `MAINTAINER CHECK NEEDED` items" bullet); absent from `.codex/agents/pack-planner.toml` `developer_instructions` and `.gemini/agents/pack-planner.md`
- Side: pack-self
- Evidence: `.claude/agents/pack-planner.md` carries a multi-sentence rule: `**State-verifiable questions are not \`MAINTAINER CHECK NEEDED\` items.** When evaluating a BD whose scope depends on the current repo state ... run the appropriate read-only tool ... NOW and write the BD scope reflecting actual current state. \`MAINTAINER CHECK NEEDED\` is reserved for genuinely unanswerable questions ...` The Codex `developer_instructions` Responsibilities list ends at "Do not invent file structures or conventions. Read the current state first." with no equivalent bullet; the Gemini version likewise ends at the same line with no equivalent bullet.
- Why it's a problem: This is content-bearing planner behavior (how to treat state-verifiable questions vs. maintainer-check items), not a tool-specific construct — nothing about it depends on Claude's tooling. The trinity rule (CLAUDE.md § "Trinity rule" + commit-discipline skill §5: pack-repo agent files mirror identical prose with only tool-specific format differences) requires the three pack-planner files to express the same rules; asymmetry requires justification. There is no justification here — a Codex or Gemini pack-planner would mis-route state queries to MAINTAINER CHECK that the Claude one would answer directly. Minor secondary parity nit in the same family: the `description` field includes "cross-doc consistency checks" in Claude + Gemini but omits it in Codex.
- Recommendation: Add the "State-verifiable questions are not `MAINTAINER CHECK NEEDED` items" rule to the Codex `developer_instructions` and the Gemini agent body, mirroring the Claude wording (adapt only mechanical formatting, not substance). While there, align the `description` field's "cross-doc consistency checks" phrase across all three. This is an agent-rule-correctness + parity fix; confirm whether the rule was intentionally Claude-only (unlikely — it reads as universal planner discipline) before deciding direction, but default is to propagate to all three.
- Cross-segment touch points: none (pack-self only; the project-side `planner` agent is a different roster/audience and out of scope).
- Confidence: high (asymmetry confirmed by direct read of all three files; substance is platform-neutral planner methodology).

### R2-F03 — commit-discipline skill cites `agent-run.sh` as a pack-side tool-specific example, but it does not exist pack-side
- Severity: NIT
- Category: C (cross-reference precision) + B (pack/project boundary nuance)
- Surface(s): `.claude/skills/commit-discipline/SKILL.md` §5 "Trinity rule cross-reference" (and its byte-identical `.codex/` + `.gemini/` mirrors)
- Side: pack-self
- Evidence: §5 reads: `...modulo provably tool-specific tweaks (Claude's Task tool syntax, Codex's \`agent-run.sh\` references, Gemini's \`@<agent>\` invocation).` Per CLAUDE.md § "Agent invocation rules": "The pack repo has no `agent-run.sh` — that's a project template helper, not a pack invocation method." `find . -name agent-run.sh` confirms it exists only under `project-template/` (and fixtures), never at pack root. This skill is a pack-self surface (loaded by pack-* agents working on the pack repo).
- Why it's a problem: The example names a project-template helper as if it were a Codex pack-side invocation mechanism, on a pack-self skill. It is illustrative (an example of "the kind of tool-specific tweak"), so it does not break a live path, but it is mildly misleading on a pack-self surface and conflicts with the explicit CLAUDE.md statement that the pack repo has no `agent-run.sh`. Low severity because the surrounding clause is about the *project-template* trinity files the pack-coder edits (where `agent-run.sh` IS the correct Codex example), so the example is arguably in-context. Flagging for precision per the BD-195 stale-reference sweep.
- Recommendation: Optional. If tightening: either (a) qualify the example as project-side ("Codex's project-template `agent-run.sh` references"), or (b) replace the Codex example with a genuinely pack-side-applicable tool-specific tweak (e.g., the Codex TOML `developer_instructions` format vs. Claude/Gemini markdown frontmatter, already noted in §5's own next paragraph). Because the skill is byte-identical across the three CLIs, any edit must land in all three to preserve parity (quad/trinity fix).
- Cross-segment touch points: none directly; whoever audits the `project-template/` skills should note the project-side commit-discipline skill (if one exists) has a different correct answer (`agent-run.sh` IS valid there).
- Confidence: low (the example is illustrative, not a live path; the in-context reading is defensible — surfaced only because BD-195 sweeps stale references and CLAUDE.md explicitly disclaims pack-side `agent-run.sh`).

## Coverage map

| Owned path | Result |
|---|---|
| `.claude/agents/pack-architect.md` | clean |
| `.codex/agents/pack-architect.toml` | clean |
| `.gemini/agents/pack-architect.md` | clean |
| `.claude/agents/pack-coder.md` | clean |
| `.codex/agents/pack-coder.toml` | clean |
| `.gemini/agents/pack-coder.md` | clean |
| `.claude/agents/pack-docs-researcher.md` | clean |
| `.codex/agents/pack-docs-researcher.toml` | clean |
| `.gemini/agents/pack-docs-researcher.md` | clean |
| `.claude/agents/pack-planner.md` | R2-F02 |
| `.codex/agents/pack-planner.toml` | R2-F02 |
| `.gemini/agents/pack-planner.md` | R2-F02 |
| `.claude/agents/pack-reviewer.md` | clean |
| `.codex/agents/pack-reviewer.toml` | clean |
| `.gemini/agents/pack-reviewer.md` | clean |
| `.claude/skills/pack-help/SKILL.md` | R2-F01 |
| `.codex/skills/pack-help/SKILL.md` | R2-F01 |
| `.gemini/commands/pack-help.toml` | clean (correct paths; reference value for R2-F01) |
| `.claude/skills/pack-startup/SKILL.md` | clean |
| `.codex/skills/pack-startup/SKILL.md` | clean |
| `.gemini/commands/pack-startup.toml` | clean |
| `.claude/skills/architecture-review/SKILL.md` (+codex/+gemini) | clean (byte-identical) |
| `.claude/skills/boundary-investigation/SKILL.md` (+codex/+gemini) | clean (byte-identical; deny-list refs all resolve; CI Check 37 ENCODING lock-step intact) |
| `.claude/skills/commit-discipline/SKILL.md` (+codex/+gemini) | R2-F03 (byte-identical across all three) |
| `.claude/skills/dependency-intake/SKILL.md` (+codex/+gemini) | clean (byte-identical) |
| `.claude/skills/documentation/SKILL.md` (+codex/+gemini) | clean (byte-identical) |
| `.claude/skills/implementation-report/SKILL.md` (+codex/+gemini) | clean (byte-identical) |
| `.claude/skills/planning/SKILL.md` (+codex/+gemini) | clean (byte-identical) |
| `.claude/skills/review/SKILL.md` (+codex/+gemini) | clean (byte-identical; ENCODING-surfaces methodology + test-issue-forms.sh ref resolves) |
| `.claude/skills/verification-harness/SKILL.md` (+codex/+gemini) | clean (byte-identical; all cited test scripts resolve) |
| `.claude/settings.local.json` | clean (benign tooling permissions) |
