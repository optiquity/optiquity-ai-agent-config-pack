# ORCHESTRATION PLAN — BD-175 EMERGENCY: pack/project boundary remediation

**Owner:** Pack Chat (PM role — orchestration only, NOT architecture or design)
**BD:** BD-175 (CODE RED)
**Status:** Open
**Date opened:** 2026-05-18
**Pauses:** BD-173 (Batch 19c project-side cleanup)
**Resumes after:** BD-175 Resolved + 19c re-scoping decision

**Naming note:** This doc is an orchestration plan by Pack Chat, NOT an architect deliverable — hence `ORCHESTRATION-PLAN-*.md` rather than `ARCHITECTURE-*.md`. The latter prefix is reserved for architect agent output.

---

## §1 — Context

Multiple v11 commits introduced pack-design bias into project-side files in violation of stated guiding principles. Two confirmed instances surfaced during a triage that itself was acknowledged as incomplete:

1. **Commit `240867d` (2026-05-09)** — F-7 of BD-127 (v10.1 backport fix-follow) added `PACK-AGENTS.md` reference to project-template trinity (`CLAUDE.md:366`, `AGENTS.md:343`, `GEMINI.md:356`), bypassing the project-side SSOT in `project-template/docs/pack/PM-CHAT.md:47` (`## Pack agent roster`) which itself instructs PM chats at line 239 to "treat any reference implying a different roster as stale and report it as pack feedback."

2. **Commit `aaa61b3` (2026-05-15, Batch 19b-5)** — Modified `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` during a batch the user repeatedly stated must be PACK-ONLY. `supporting-docs/` is pack-product per the trinity rule "Pack ops files (CLAUDE.md, AGENTS.md, GEMINI.md, PACK-CHAT.md, PACK-AGENTS.md, BACKLOG.md, etc.) are NEVER mixed into pack product files (`project-template/`, `supporting-docs/`)."

The bias entry mechanism in both cases: review/fix cycles where neither reviewer nor implementer investigated project-side SSOT before defaulting to pack-style mechanisms. CI checks (e.g., Trinity Check 18 H2 parity) verify wording-matches across CLI files but do NOT verify whether the rule is correct for the surface it lives on. There is no structural prevention against this regression pattern.

True scope of contamination across v11 is UNKNOWN. The triage that surfaced the two instances above was acknowledged as surface-only. A full audit is the first work this BD performs.

Separately, there is no formal classification document naming every file/directory in the pack repo as pack-only / project-only / shared. "Shared" is an anti-pattern requiring re-architecture. Root directory currently holds pack-only docs (`PACK-AGENTS.md`, `HELP-FRAGMENT-PACK.md`, etc.) that need new homes in pack-only directories — even with `PACK-` prefix, root location is not acceptable. All path references to relocated files require lockstep updating.

---

## §2 — Problems

**P1 — No formal classification exists.** There is no authoritative document or mechanism naming every file/directory as pack-only / project-only / shared. Without classification, every change-author makes ad-hoc judgments — which is how regressions enter.

**P2 — Shared files/directories is an anti-pattern.** When the same file or directory serves both pack and project audiences, ownership becomes fuzzy and pack-design bias seeps into project-side content via reviewer findings, fix-follow commits, and lockstep edits. "Shared" needs to be eliminated or rigorously minimized through re-architecture.

**P3 — v11 has actual regressions introduced by pack-bias.** Two confirmed; true scope unknown.

**P4 — Surface triage was incomplete.** The real scope of contamination across v11 has not been determined. Discovery is the first phase of this work.

**P5 — Structural prevention is absent.** Trinity parity checks verify wording-matches but not rule-correctness. Reviewer + implementer chains can introduce pack-bias unchallenged. No CI gate or agent-prompt guardrail prevents this regression pattern.

**P6 — Prior orchestration enabled this.** Pack Chat (current and prior sessions) allowed pack-bias to enter project-side artifacts through routine review/fix cycles without surfacing scope violations.

---

## §3 — Goals

**G1 — Classification.** Produce an authoritative classification document naming every file/directory in the pack repo as pack-only, project-only, or shared (with shared rigorously justified per item, or eliminated).

**G2 — Re-architect file AND directory structure to eliminate shared.** No shared directories between pack and project. Root directory holds only files that MUST be there for tool/CLI compatibility (CLAUDE.md, AGENTS.md, GEMINI.md, README.md, LICENSE, etc.). All other pack-related docs live in pack-only directories; all project-related docs live in project-only directories. Files currently at root needing relocation (e.g., `PACK-AGENTS.md`, `HELP-FRAGMENT-PACK.md`) move to architect-designated pack-only directories. All path references to relocated files updated across the repo in lockstep.

**G3 — Full v11 audit.** Identify ALL v11 commits that violated pack/project boundaries — not just the two found so far. Audit includes:
- Pack-bias in project-side files
- Project-side file modifications during pack-only batches
- Project-side references to pack-only files/mechanisms/rules
- Project-side content mirroring pack-side decisions without independent project rationale
- Root-directory file inventory with verdict (STAYS — tool/CLI requirement / MOVES — needs new home)
- Path-reference scan for all relocation candidates

**G4 — Re-litigation, not blind revert.** Every identified violation must be re-litigated by an architect (designs the right project-side answer) and a reviewer (verifies correctness independently). Blind reverts would lose any valid intent buried in the bad change.

**G5 — Restore project-side integrity.** Project-side artifacts at HEAD reflect project-design intent — free of pack-bias contamination — after re-litigation completes.

**G6 — Structural prevention.** Codify mechanisms that prevent this regression pattern from recurring:
- Classification document as living reference
- CI checks where mechanically possible (e.g., "no new docs at root" gate)
- Agent prompt guardrails (P-missed-7 / project-design-investigation-first codified)
- Reviewer protocol amendment requiring SSOT investigation before recommending content
- Possibly amended trinity rule that adds substance-checks to parity-checks

**G7 — Stated boundary definition.** Produce an authoritative boundary definition (rules for what makes a file/directory pack-only vs project-only). Quality bars: **unimpeachable** (sound rationale per rule; survives challenge) and **unambiguous** (no edge cases unresolved; every conceivable artifact has a clear placement verdict from the rules). Per-file classifications (G1) derive FROM this definition; prevention mechanisms (G6) enforce IT.

**User-stated boundary input** (verbatim — input to Phase 2 architect, NOT the final boundary definition):

> Files in `project-template/` are for projects and will be in the project dirs. Not necessarily root dirs. They are the product of the config pack. They are not (a) configs used by tools governing the config pack to do its work or (b) config pack operational docs used by the pack to do its work.

---

## §4 — Success Criteria

**SC1 — Classification document exists.** Every file/directory in the pack repo is classified pack-only / project-only / shared. Shared entries are either eliminated or carry rigorously-defended justification + structural firewall description. Directory classification is part of this document.

**SC2 — Audit report exists.** Names ALL v11 commits with pack/project boundary violations, with severity, file/section, and recommended action per finding. Identifies any related v10 or earlier issues if discovered.

**SC3 — All violations re-litigated.** Each identified violation has been: reviewed by an architect with a documented design decision (revert / replace / justify); verified by an independent reviewer; implemented by a coder; committed with explicit traceability to the audit finding.

**SC4 — Project-side HEAD is clean.** Inspection (manual + automated where possible) confirms project-side files at HEAD are free of pack-bias contamination per the classification document.

**SC5 — Structural prevention deployed.** P-missed-7 codified; relevant agent prompts updated; CI checks added where mechanically possible; reviewer protocol amended to require SSOT investigation.

**SC6 — 19c resumes on clean foundation.** Once SC1-SC5 met, 19c can resume with V1 architect doc + curation work preserved. Pack Chat updates the V2 architect prompt to incorporate the new classification + prevention rules.

**SC7 — Directory architecture deployed.** All pack-only docs reside in pack-only directories; all project-related docs reside in project-only directories; root holds only files that MUST be there for tool/CLI compatibility; all path references to relocated files updated; CI check (where possible) enforces "no new docs at root" going forward.

**SC8 — Boundary definition is discoverable.** The boundary definition is documented in a place that is easily discoverable by any workflow, agent, actor, or tool that needs to see it — whether the work is for new pack versions, project-related migrations, or updates.

---

## §5 — Orchestration sequence (7 phases)

### Phase 0 — Setup (Pack Chat, immediate)

- Verify BD number against live BACKLOG → BD-175 confirmed
- Write this orchestration plan
- Create BD-175 entry in BACKLOG.md
- Update Task #13 (19c) to paused-pending-BD-175
- Create new Task for BD-175
- Spawn Phase 1 docs-researcher in background

### Phase 1 — Discovery (docs-researcher #1, read-only)

**Goal:** Determine the REAL scope of the problem (surface triage acknowledged as incomplete).

**Outputs:**
- Complete inventory of every file at repo root with classification verdict (STAYS — tool/CLI requirement / MOVES — needs new home)
- Complete inventory of every directory in the pack repo with classification (pack-only / project-only / shared-anti-pattern)
- All v11 commits that modified project-side files during pack-only batches (full scan, not just 19b)
- All project-side file references to pack-only files/mechanisms/rules (full grep + structural scan)
- All project-side content blocks mirroring pack-design without independent project rationale (heuristic scan)
- All path references that would need updating if relocations happen

**Output file:** `AUDIT-PACK-PROJECT-BOUNDARY-VIOLATIONS.md`

**Constraints:** NO design, NO recommendations — identification only. Read-only on all surfaces including OT.

### Phase 2 — Multi-architect design (THREE separate architects, parallel where safe)

Per the user's "different agents for different blast radii" rule, three architects with non-overlapping scopes:

- **Architect A — Re-litigation framework.** Reads audit. Per-finding from audit: revert vs replace vs justify (with documented rationale per finding). Output: `ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md`.

- **Architect B — Directory architecture + boundary definition.** Reads audit + user curation (`AUDIT-USER-CURATION.md` — contains user-stated boundary articulation as input). Concerns include: G7 boundary definition (unimpeachable + unambiguous); SC8 discoverability of the boundary definition; new pack-only directory structure for relocated files; naming/placement; root-directory exemption rules; path-reference update strategy. Output: `ARCHITECTURE-DIRECTORY-REORGANIZATION.md`.

- **Architect C — Structural prevention.** Reads audit. Designs P-missed-7 codification, CI gates, agent-prompt guardrails, reviewer protocol amendments. Output: `ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md`.

Each architect's prompt strictly forbids designing another's domain. Each writes their design doc to the designated output path. NO architect reads another's output.

### Phase 3 — Independent reviewer (DIFFERENT agent than any of A/B/C)

- Spawn `pack-reviewer` once
- Reads: audit doc + all three architect design docs
- Verifies designs are correct, complete, internally consistent, don't conflict with each other
- Output: `PACK-REVIEW-EMERGENCY-DESIGNS.md` with BLOCKER/MUST/SHOULD/NIT findings

**Pack Chat triages findings with user before any fix passes.**

Per-architect fix cycles where needed (fresh architect-fix-coder per finding cluster, NOT the original architect).

### Phase 4 — Planner (resolves ambiguities)

- Spawn `pack-planner` after architect designs + reviewer findings stabilized
- Input: three architect docs + reviewer findings + audit doc
- Output: `PLAN-EMERGENCY-IMPLEMENTATION.md`
- Resolves ambiguities (e.g., implementation ordering, dependencies, which file moves first)
- User reviews planner output thoroughly before any implementation spawn (per memory rule)

### Phase 5 — Implementation (per-task coder spawns)

- One coder per planner task (fresh coder per task per pack memory)
- Per-task review/fix cycles inline
- Categories of work (per planner sequencing):
  - File relocations (`git mv` to preserve history)
  - Path reference updates (bulk)
  - Contamination reverts/replacements (per Architect A's design)
  - CI checks added (per Architect C's design)
  - Agent prompt updates (per Architect C's design)
  - Trinity bullet updates if needed (per Architect C's design)
  - Memory file updates (P-missed-7 codification)
- End-of-batch broad reviewer pass at completion (DIFFERENT reviewer than Phase 3's)

### Phase 6 — Verification

- All audit findings addressed (cross-check against `AUDIT-*` doc)
- Directory architecture matches Architect B's design
- All path references resolve correctly
- CI passes (including new boundary-check gates)
- Trinity rule + RC9 manifest still honored
- Test fixtures regenerated
- Manual spot-check by user

### Phase 7 — Close + 19c resume decision

- BD-175 flipped to Resolved
- Pack Chat updates Task #13 to ready-to-resume
- Decision point: salvage 19c V1/Path C/G-research docs OR restart 19c from scratch given the new classification + prevention rules

---

## §6 — Agent separation matrix

| Phase | Agent | Cannot also be |
|---|---|---|
| Discovery (Phase 1) | docs-researcher #1 | Any subsequent architect / reviewer / planner |
| Re-litigation design (Phase 2) | architect A | architects B, C; reviewer; planner |
| Directory design (Phase 2) | architect B | architects A, C; reviewer; planner |
| Prevention design (Phase 2) | architect C | architects A, B; reviewer; planner |
| Design review (Phase 3) | reviewer #1 | any architect, any architect-fix-coder |
| Planning (Phase 4) | planner #1 | any architect, reviewer |
| Implementation (Phase 5) | coder #1..N (fresh per task) | each other |
| Broad review (Phase 5 end) | reviewer #2 (fresh) | reviewer #1, any architect, any coder |

---

## §7 — Process expectations

- **Pack Chat = PM role.** Pack Chat orchestrates; does NOT architect, plan, or design solutions itself.
- **Architects + reviewers do re-litigation.** Pack Chat spawns the right agents at the right time.
- **Scoping discovery is FIRST.** The real scope of the problem is unknown; the audit comes BEFORE re-litigation.
- **Each phase requires user approval.** Pack Chat proposes; user approves; then agent spawns.
- **19c paused, not abandoned.** V1 architect doc, principle-check, researcher, Path C, G-research, PATH-C-CURATION are preserved for the 19c-resume decision.
- **Per-action approval extends to sub-agents.** All sub-agent spawns and state-changing operations require explicit per-action user approval per pack memory.

---

## §8 — Status

- **2026-05-18:** BD-175 opened. Phase 0 setup in progress.
