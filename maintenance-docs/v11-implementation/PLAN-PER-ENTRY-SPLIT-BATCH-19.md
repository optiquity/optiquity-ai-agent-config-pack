---
title: PLAN-PER-ENTRY-SPLIT-BATCH-19
author: pack-planner (v11-dev)
status: plan — for primary-chat reviewer, then primary-chat coder + Pack Chat (mixed-mode batch)
parent-design:
  - maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-SPLIT.md (sidecar parent — 1,649 lines)
  - maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md (integration parent — 3,477 lines)
  - maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md (Addendum #1 — 2,053 lines)
  - maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2.md (Addendum #2 — 1,400 lines)
authority-precedence: Addendum #2 > Addendum #1 > integration parent > sidecar parent
audience: primary-chat reviewer (next); primary-chat pack-coder + Pack Chat (mixed-mode commits per §6.5 of Addendum #1)
batch: v11.0 Batch 19 (NEW per Addendum #1 Item 2; Batches 19+ renumber up by one)
bds-in-scope: BD-164, BD-165, BD-166, BD-167, BD-167b, BD-168, BD-169, BD-169b, BD-170 (9 new) + BD-161 absorbed into BD-167 + BD-160 pulled into commit 19f per R-2 resolution = 11 BD-tracked items, 10 commits
commit-count: 10 (per Addendum #1 §6.5; BD-160 + BD-170 combined in commit 19f per R-2 resolution preserves the 10-commit total)
date: 2026-05-14
---

# Per-entry split — implementation plan for Batch 19

## §0 — TL;DR + execution map

**Goal.** Implement per-entry decomposition of pack `BACKLOG.md` /
`CHANGELOG.md` (pack-self) and project `BACKLOG.md` /
`IMPLEMENTATION-PLAN.md` / `CHANGELOG.md` (project-template) as
mandatory non-reversible v11.0 behavior, ship the mirror+TOC
regenerator helpers + decompose helper + migrator wiring +
init-project wiring + validator gates + fixture extension +
documentation/discoverability surface, with all PM-only edits
applied by Pack Chat in dedicated commits.

**Authority precedence.** Where the four architect docs disagree:
Addendum #2 supersedes Addendum #1 supersedes integration parent
supersedes sidecar parent. This plan applies that precedence
throughout. Specifically:
- Layer 2 of discoverability is HTML-comment line-1 only — body-field back-pointer DROPPED per Addendum #2 §2.
- Pack-side per-entry trees are non-dot (`/backlog/`, `/changelog/`) — leading-dot DROPPED per Addendum #1 §10.
- Codex pack-* agent files are `.toml` (not `.md`) — Addendum #2 §1 BLOCKER correction. Same for `.codex/agents/auditor.toml`.
- EXECUTION-PLAN line 282 totals replacement is per Addendum #2 §3.3 verbatim text (not Addendum #1 §2.4 row 4).
- Total v11.0 commit count target: max ~41 (per Addendum #2 §3.3, Pack-Chat-direct edits already lockstep-applied to Addendum #1 §0.2 / §6.6 / §11.3 per Addendum #2 §3.4).
- Regenerator divergence in apply/resume mode BLOCKS unless `--force-overwrite-mirror` is passed — per Addendum #2 §4 BD-095 bridge (replaces Addendum #1 §5.3 "stderr warning + proceed" non-interactive routing for the migrator path).
- PACK-CHAT.md row exact text is per Addendum #2 §5.2 verbatim; PM-CHAT.md analog row text is per Addendum #2 §5.4 verbatim.

**Batch shape.** 10 commits (per Addendum #1 §6.5), authored by
mixed pack-coder + Pack-Chat-direct authorship. The 10 commits in
order: 19a (BD-164) → 19b-pack (BD-167) → 19b-PM (BD-167b) → 19c
(BD-165) → 19d (BD-166) → 19e (BD-168) → 19f (BD-160 + BD-170
combined per Pack-Chat-direct R-2 resolution) → 19g-pack (BD-169) →
19g-PM (BD-169b) → 19h (BD status flips). 6 pack-coder commits +
4 Pack-Chat-direct commits.

**BD numbering verified.** `grep -nE "^\*\*BD-[0-9]+ —" BACKLOG.md
| tail -1` returns `BD-155` literal but the highest by number per
the same grep (sorted) is BD-163 (BD-163 lives at
`BACKLOG.md:1399` per integration parent §1.1). The new BDs
BD-164..BD-170 are sequential and non-colliding. BD-167b and
BD-169b are suffix-IDs per Addendum #1 §6.2 / §6.3 split.

**Hard sequencing constraints (Batch 19 cannot fire until):**
- AFTER Batch 6 (BD-128, CI repair).
- AFTER Batches 7–10 (BD-131..BD-134, tracker repairs).
- AFTER Batch 12 (BD-104, IMPLEMENTATION-PLAN.md rename).
- AFTER Batch 13 (BD-095 + BD-101, two-phase migrator + validation gates) — BD-095's `--dry-run`/`--apply`/`--resume` mode-flag parser at `migrator-core.sh:264-276` must be live for Item 4 bridge (per Addendum #2 §4 / §6.9 verification).
- AFTER Batch 17 (BD-106 / BD-107 / BD-108, tracker entity model).
- AFTER Batch 18 (BD-111, GH dependency API switch).

**Hard sequencing constraints (Batch 19 must complete before):**
- BEFORE Batch 22 (BD-100 final milestone audit; was Batch 21).
- BEFORE Batch 23 (BD-102 dog-food migration; was Batch 22).
- BEFORE Batch 24 (BD-093 release pin; was Batch 23).

**Pre-flight verifications grounded in this plan (verify-by-`ls`).**
The 18 facts the plan depends on are listed in §11. Every File/Symbol
path in the per-commit specs (§5) was verified via `ls`, `sed -n`,
or `grep -nE` before write.


---

## §1 — Scope, in-scope BDs, and out-of-scope clarifications

### §1.1 — In-scope BDs (10 items tracked)

| BD | Topic (one-line) | Author | Commit | New / split / absorbed |
|---|---|---|---|---|
| BD-164 | Per-entry split helpers (decompose + mirror generator + `_toc.md` regenerator + supporting-file generators) under `scripts/lib/per-entry/` | pack-coder | 19a | NEW |
| BD-167 | Per-entry split client artifact installs (pack-product templates + install plumbing); absorbs BD-161 net-new SKILL.md installs | pack-coder | 19b-pack | NEW; absorbs BD-161 |
| BD-167b | PM-only edits paired with BD-167 (trinity Key files lines × 6, PACK-AGENTS.md PM-only directories list, CLAUDE.md pack-memory bullet, pack-* agent prompts × 15). STATUS.md disclaimer surface moved to BD-169 (19g-pack PM-CHAT.md guidance) per Pack-Chat-direct R-3 resolution. | Pack Chat direct | 19b-PM | NEW (split from BD-167 per Addendum #1 §6.2) |
| BD-165 | `_v10_to_v11_decompose_streams` 6th sub-operation in v10→v11 post-dispatch hook + `--force-overwrite-mirror` flag wiring per Addendum #2 §4 | pack-coder | 19c | NEW |
| BD-166 | `init-project.sh` greenfield per-entry tree install (S11 extension or S11b new stage; planner picks S11 extension per Addendum #1 §8.17 recommendation) | pack-coder | 19d | NEW |
| BD-168 | `validate-pack.py` Check 32 (mirror-in-sync) + Check 33 (TOC-in-sync) + Check 34 (cross-reference integrity) | pack-coder | 19e | NEW |
| BD-160 | v11-realistic-ot fixture v11 case dispatch (extend `_build_realistic_for_version` v11 case + verify C2/C3 customizations on v11 surface) | pack-coder | 19f (combined with BD-170 per R-2 resolution) | EXISTING `Status: Open` BD pulled into Batch 19 (was unscheduled in EXECUTION-PLAN; no precursor batch needed) |
| BD-170 | Pre-decomposed `v11-realistic-ot` fixture per-entry tree extension (consumes BD-160 v11 case + BD-164 decompose helper) | pack-coder | 19f (combined with BD-160) | NEW |
| BD-169 | Per-entry split pack-product wording updates (project-template `PM-CHAT.md` row + STATUS.md disclaimer guidance per R-3, supporting-docs `MERGE-STRATEGY.md` paragraph + `MIGRATION-v10-to-v11.md` section, audit-methodology SKILL.md scope extension per R-4 (auditor agent files NOT modified), pack-startup directives × 3, pm-startup directives × 4) | pack-coder | 19g-pack | NEW |
| BD-169b | PM-only wording updates (PACK-CHAT.md row + README.md Repository Layout entries) | Pack Chat direct | 19g-PM | NEW (split from BD-169 per Addendum #1 §6.3) |
| BD-161 | v10→v11 migrator: install net-new v11 SKILL.md dirs (BD-156/157/158 + python-server-architecture / python-data-architecture split) | (Pack Chat direct status flip; implementation work folded into BD-167) | 19h | ABSORBED into BD-167 per integration parent §17.2 |

### §1.2 — Out-of-scope (named so they don't sneak in)

- **PM-only file edits authored by agents.** Trinity, PACK-AGENTS.md, PACK-CHAT.md, README.md, EXECUTION-PLAN-V11.0.md, RELEASE-GATE.md, BACKLOG.md, CHANGELOG.md edits are AUTHORED BY PACK CHAT only. Agents contribute working-tree edits to non-PM-only files only.
- **STATUS.md authoring.** Verified by `find project-template -name "STATUS*"`: STATUS.md does NOT ship from `project-template/` (it is created by the client during PM-Chat kickoff per the existing flow). The integration parent §5.3 disclaimer requirement targets the CLIENT-created STATUS.md. **Pack-Chat-direct R-3 resolution: PM-CHAT.md kickoff guidance addition (Option A).** Lands in 19g-pack (BD-169) PM-CHAT.md edits. No new pack-product STATUS_TEMPLATE.md file. STATUS.md remains client-authored.
- **Pre-commit hook shipping.** Per integration parent §7.3 + Addendum #1 §4.5 + Addendum #2 §4.4: the optional pre-commit hook is OUT OF SCOPE for v11.0; flagged for v11.x or v12.0. Not in any Batch 19 BD.
- **`pack doctor` verb extension.** Per Addendum #1 §5.5 Layer 4: out of scope for v11.0; planner-flagged for v11.x. Not in any Batch 19 BD.
- **Cross-pack-and-project reference validation.** Per integration parent §11.5: out of scope; pack-repo CI does not load project tree.
- **Pack-self decompose at Batch 19.** The pack repo's own `BACKLOG.md` and `CHANGELOG.md` get decomposed by the v10→v11 migrator at Batch 23 (BD-102 dog-food, was Batch 22) when Pack Chat runs `bash scripts/migrate-v10-to-v11.sh` against the pack-self clone. Batch 19 ships the helpers + canonical templates + migrator wiring; Batch 23 fires the migration on pack-self.
- **Editing the four architect docs.** Per planner-prompt constraint. The architect corpus is final; this plan composes against them.
- **New BD numbers beyond BD-164..BD-170 + BD-167b + BD-169b.** Per planner-prompt constraint.

### §1.3 — Authority precedence reconfirmed inline

For every decision in this plan, the plan applies:
**Addendum #2 > Addendum #1 > integration parent > sidecar parent.**
Specific architect-doc-conflict resolutions used in this plan:

| Topic | Resolution applied | Source |
|---|---|---|
| Layer 2 of discoverability | HTML-comment line-1 ONLY (no body-field back-pointer) | Addendum #2 §2 |
| Pack-side per-entry-tree paths | `/backlog/` + `/changelog/` (non-dot) | Addendum #1 §10 |
| Codex pack-* agent file extension | `.toml` (5 files in `.codex/agents/pack-*.toml`) | Addendum #2 §1 + §6.1 verify-by-`ls` |
| Codex auditor agent file extension | `.codex/agents/auditor.toml` (in project-template) | Addendum #2 §1.5 Finding 2A + §6.4 verify-by-`ls` |
| EXECUTION-PLAN line 282 totals replacement text | "26 main batches (24 + Batch 5b + Batch 21b) ... ~41 commits" verbatim per Addendum #2 §3.3 | Addendum #2 §3.3 |
| Regenerator divergence in apply/resume | BLOCKS unless `--force-overwrite-mirror` passed (per BD-095 bridge) | Addendum #2 §4 |
| PACK-CHAT.md row text | Verbatim per Addendum #2 §5.2 (two new rows) | Addendum #2 §5.2 |
| project-template PM-CHAT.md row text | Verbatim per Addendum #2 §5.4 (two new rows) | Addendum #2 §5.4 |
| Total v11.0 commit count | max ~41 (was max ~40 in Addendum #1; corrected per Addendum #2 §3.3) | Addendum #2 §3.3 |
| Mode-aware source-of-truth language in CLAUDE.md pack-memory bullet | Verbatim per Addendum #1 §3.4 (replaces integration parent §6.5 bullet text) | Addendum #1 §3.4 |
| PACK-AGENTS.md framing | Honest Signal 9 trip per Addendum #1 §3.1 (NOT "refactor not expansion") | Addendum #1 §3.1 |


---

## §2 — Pre-flight verifications (verify-by-`ls` discipline)

These are the file-system facts the plan depends on, each verified
directly. Pack Chat / coder should re-run these at the start of
Batch 19 implementation to catch any drift since plan write.

### §2.1 — Files / directories that EXIST today

| Path | Verified by | Used by plan |
|---|---|---|
| `BACKLOG.md` (3,627 lines; highest BD = BD-163) | `wc -l` + `grep -nE` | BD numbering audit; PM-only edits (Pack Chat) |
| `CHANGELOG.md` | (referenced; not directly relevant to plan) | — |
| `EXECUTION-PLAN-V11.0.md` (431 lines; line 282 is the totals line) | `sed -n '281,283p'` | PM-only edits (Pack Chat) |
| `RELEASE-GATE.md` (263 lines; lines 38–39 reference Batch 21 / 22) | `sed -n '36,42p'` | PM-only edits (Pack Chat) |
| `PACK-CHAT.md` (199 lines; file-access strategy table at lines 38–47) | `sed -n '38,47p'` | PM-only edits (Pack Chat); BD-169b |
| `PACK-AGENTS.md` (179 lines; PM-only files at lines 139–142; agent-extension convention at lines 174–176) | `sed -n '170,179p'` | PM-only edits (Pack Chat); confirms Codex `.toml` |
| `README.md` (Repository Layout starts at line 85) | `grep -nE "Repository Layout"` | PM-only edits (Pack Chat); BD-169b |
| `CLAUDE.md` (pack root; Key files block ~lines 28–33; Pack memory section starts ~line 93) | (referenced) | PM-only edits (Pack Chat); BD-167b |
| `AGENTS.md`, `GEMINI.md` (pack root) | (referenced) | PM-only edits (Pack Chat); BD-167b trinity |
| `project-template/CLAUDE.md`, `AGENTS.md`, `GEMINI.md` | (referenced) | PM-only edits (Pack Chat); BD-167b trinity |
| `.claude/agents/pack-{architect,coder,docs-researcher,planner,reviewer}.md` (5 files) | `ls -la .claude/agents/` | Pack Chat applies BD-167b Layer 4 edits |
| `.codex/agents/pack-{architect,coder,docs-researcher,planner,reviewer}.toml` (5 files) | `ls -la .codex/agents/` | Pack Chat applies BD-167b Layer 4 edits — **TOML format** |
| `.gemini/agents/pack-{architect,coder,docs-researcher,planner,reviewer}.md` (5 files) | `ls -la .gemini/agents/` | Pack Chat applies BD-167b Layer 4 edits |
| `.claude/skills/pack-startup/SKILL.md` | `ls` | BD-169 (pack-product wording — directive line addition) |
| `.codex/skills/pack-startup/SKILL.md` | `ls` | BD-169 (Codex SKILL is `.md` — verified per Addendum #2 §6.6) |
| `.gemini/commands/pack-startup.toml` | `ls` | BD-169 (Gemini commands are `.toml`) |
| `project-template/skills/pm-startup/SKILL.md` (canonical) | `ls` | BD-169 |
| `project-template/.claude/skills/pm-startup/SKILL.md` | `ls` | BD-169 |
| `project-template/.codex/skills/pm-startup/SKILL.md` | `ls` | BD-169 |
| `project-template/.gemini/commands/pm-startup.toml` | `ls` | BD-169 |
| `project-template/.claude/agents/auditor.md` | `test -f` | (NOT in BD-169 scope per R-4 resolution — verified for context only; auditor agent files NOT modified) |
| `project-template/.codex/agents/auditor.toml` | `test -f` | (NOT in BD-169 scope per R-4 resolution — verified for context only; **TOML** extension confirmed) |
| `project-template/.gemini/agents/auditor.md` | `test -f` | (NOT in BD-169 scope per R-4 resolution — verified for context only) |
| `project-template/skills/audit-methodology/SKILL.md` (26496 bytes) | `ls -la` per Addendum #1 §7 + Addendum #2 §6 | BD-169 (audit-scope rule extension per R-4 resolution: per-entry tree files in scope; regenerated mirrors out of scope) |
| `project-template/docs/pack/PM-CHAT.md` | `ls` | BD-169 |
| `supporting-docs/MERGE-STRATEGY.md` | `ls` | BD-169 |
| `supporting-docs/MIGRATION-v10-to-v11.md` | `ls` | BD-169 |
| `scripts/migrate-v10-to-v11.sh` (post-dispatch hook at lines 134–149) | `sed -n` | BD-165 |
| `scripts/lib/migrate-v10-to-v11/` (adapter-private lib subdirectory) | `ls` | BD-165 (decompose helper home: `scripts/lib/migrate-v10-to-v11/decompose.sh` per Addendum #1 §6.4 + integration parent §10.2) |
| `scripts/lib/migrator-core.sh` (mode-flag parser at 264–276; `_MIGRATOR_DRY_RUN` / `_MIGRATOR_MODE` at 109–110, 121; `EXIT_GATE_FAILED=31` at line 70) | `grep -nE` | BD-165 (BD-095 bridge per Addendum #2 §4) |
| `scripts/lib/migrator-stages.sh` (`_stage_backup` at line 146 — corrected from sidecar §5.r per integration parent §3.2) | (referenced) | BD-165 (backup contract preserved) |
| `scripts/lib/customization-preserve.sh` (`customization_classify` lines 145–180; `generic` fall-through at 178) | (referenced) | BD-167 (per-entry trees route through `generic`) |
| `scripts/lib/tracker-agent-read.sh` (`_tar_read_entry_flat` at line 153) | (referenced) | BD-167 (extension to prefer per-entry file when tree exists) |
| `scripts/init-project.sh` (`stage_s11_v11_artifacts` at line 803) | (referenced) | BD-166 |
| `scripts/validate-pack.py` (current Check 31 at line 2425; new Checks 32/33/34 to add) | `grep -n "^def check_"` | BD-168 |
| `test-fixtures/build.sh` (BD-160 v11 case dispatch in `_build_realistic_for_version`) | (referenced; per pack `BACKLOG.md:1399`) | BD-170 |

### §2.2 — Files / directories that DO NOT EXIST today (must be created)

| Path | Created in commit | Reason |
|---|---|---|
| `scripts/lib/per-entry/` directory | 19a (BD-164) | New helper home for decompose / mirror generator / TOC regenerator (planner picks file structure: single file or sub-directory) |
| `project-template/docs/project/` directory | 19b-pack (BD-167) | New canonical-template home — verified absent by `find project-template/docs -type d` (only `project-template/docs/pack/` exists) |
| `project-template/docs/project/backlog/` (with `_rules.md`, `_intro.md` canonical templates) | 19b-pack (BD-167) | Canonical pack-product templates ship into client projects via init-project.sh + migrate-v10-to-v11.sh |
| `project-template/docs/project/implementation-plan/` (with `_rules.md`, `_intro.md`) | 19b-pack (BD-167) | Same |
| `project-template/docs/project/changelog/` (with `_rules.md`, `_intro.md`, `_format.md`) | 19b-pack (BD-167) | Same |
| `scripts/lib/migrate-v10-to-v11/decompose.sh` (adapter-private decompose helper) | 19c (BD-165) | Per Addendum #1 §6.4 + integration parent §10.2 + §18.1 #3 — recommended location; planner-final |
| `scripts/tests/test-per-entry.sh` (or similar — round-trip identity / empty-tree / supporting-file admission tests) | 19a (BD-164) | Per integration parent §18.2 #1 |
| `scripts/tests/test-validate-pack-checks-32-33-34.sh` (or fold into existing validate-pack test surface) | 19e (BD-168) | Per integration parent §18.2 #6 — planner picks placement |
| `STREAMS` constant in `scripts/validate-pack.py` (top-level near `BACKLOG_FILE` / `REPO_ROOT`) | 19e (BD-168) | Per integration parent §18.2 #5 |

### §2.3 — Files that DO NOT yet have per-entry trees but will

The pack-self per-entry trees `/backlog/` and `/changelog/` are
NOT created at Batch 19. They are created at Batch 23 (BD-102
dog-food, was Batch 22) when Pack Chat runs the v10→v11 migrator
against the pack-self repo. Batch 19 only ships:
- The helpers (BD-164).
- The adapter-private decompose helper for the migrator (BD-165).
- The init-project.sh extension (BD-166).
- The pack-product canonical templates for project-template
  (BD-167) — but NOT the pack-self trees themselves.
- The validator gates (BD-168) — which SKIP gracefully when
  `/backlog/` doesn't exist (per integration parent §10.5).
- The fixture extension (BD-170).
- Documentation/discoverability (BD-169 / BD-169b).

This means: Checks 32 / 33 / 34 fire on the pack repo from Batch
19 onward, but they SKIP `/backlog/` and `/changelog/` until
Batch 23 lands the pack-self migration. After Batch 23, they
fire on the pack-self trees too.

### §2.4 — Validator-checks current state

`grep -n "^def check_"` returned the most-recent additions:
`check_skill_cell_consistency` (Check 31, line 2425). Check 32 /
33 / 34 are new. No conflicts with existing check numbering.


---

## §3 — File dependency analysis

### §3.1 — Cross-commit file dependency graph

Each commit's outputs that subsequent commits read.

```
19a (BD-164) — produces:
   scripts/lib/per-entry/<helpers>     (decompose, mirror, toc; planner picks structure)
   scripts/tests/test-per-entry.sh     (or similar)
                                        |
                                        v consumed by:
   19c (BD-165): adapter-private decompose.sh under
                 scripts/lib/migrate-v10-to-v11/decompose.sh sources
                 the BD-164 helpers
   19d (BD-166): init-project.sh stage_s11_v11_artifacts extension
                 calls the BD-164 mirror generator + toc regenerator
                 against empty input
   19e (BD-168): validate-pack.py Check 32 invokes the BD-164
                 mirror generator against the per-entry tree
                 (when present) then diffs against on-disk mirror
                 (Check 33 same shape for TOC); Check 34 reads
                 entry files directly (no helper invocation)
   19f (BD-160 + BD-170 combined per R-2): test-fixtures/build.sh
                 _build_realistic_for_version v11 case dispatch
                 (BD-160 part) is added; v11 init customizations
                 verified; then the v11 case calls the BD-164 decompose
                 helper (BD-170 part) on the just-built v11 monolithic
                 shape to produce per-entry tree + regenerated mirrors
   19g-pack (BD-169): MIGRATION-v10-to-v11.md prose references the
                 helpers (no source dependency, but doc-content
                 dependency)

19b-pack (BD-167) — produces:
   project-template/docs/project/{backlog,implementation-plan,changelog}/
     _rules.md, _intro.md, _format.md (project changelog only)
   scripts/lib/tracker-agent-read.sh _tar_read_entry_flat extension
   scripts/migrate-v10-to-v11.sh _v10_to_v11_install_v11_artifacts
     extension (installs the new templates) + BD-161 net-new SKILL.md
     installs absorbed
                                        |
                                        v consumed by:
   19b-PM (BD-167b): trinity Key files + PACK-AGENTS.md edits
                     reference the per-entry-tree paths produced
                     by BD-167's canonical templates (paths don't
                     exist in the pack-product source until
                     19b-pack lands)
   19c (BD-165): the post-dispatch decompose step writes the
                 per-entry trees IN CLIENT REPOS using the
                 templates (the templates ship from project-template
                 via BD-167's install-step extension)
   19d (BD-166): init-project.sh stage extension reads the
                 canonical templates from project-template/docs/project/
                 to install them in greenfield client repos
   19e (BD-168): Check 34 reads entry files; the canonical templates
                 are control state (skipped); the v8 archive in the
                 mirror is read but not validated for cross-refs
   19g-pack (BD-169): documentation references the canonical
                 template files
   19g-PM (BD-169b): README.md Repository Layout entries reference
                 the new directories created by BD-167

19c (BD-165) — produces:
   scripts/migrate-v10-to-v11.sh post-dispatch hook 6th sub-op
   scripts/lib/migrate-v10-to-v11/decompose.sh
   scripts/lib/migrator-core.sh --force-overwrite-mirror flag parsing
                                        |
                                        v consumed by:
   19f (BD-170): the v11-realistic-ot fixture builder uses
                 the same decompose helper (BD-164) plus the
                 migrator's adapter-private decompose pattern as
                 reference for fixture build steps
   No subsequent commit consumes BD-165 output directly during
   this batch; client repos consume it on next pack-update.

19d (BD-166) — produces:
   scripts/init-project.sh stage_s11_v11_artifacts extension
                                        |
                                        v consumed by:
   No subsequent commit in Batch 19 directly. Client greenfield
   inits consume it on next init-project.sh run.

19e (BD-168) — produces:
   scripts/validate-pack.py Check 32 / 33 / 34 + STREAMS constant
                                        |
                                        v consumed by:
   ALL subsequent commits trigger Check 32/33/34 in CI on push.
   Specifically the pack-CI for 19f / 19g-pack / 19g-PM / 19h
   verifies these checks pass. (Pack-self trees don't exist yet,
   so the checks SKIP gracefully — but Check 31 and prior checks
   still pass.)

19f (BD-170) — produces:
   test-fixtures/build.sh _build_realistic_for_version v11 case
   test-fixtures/manifest.txt regeneration
                                        |
                                        v consumed by:
   Batch 23 (BD-102 dog-food) — the dog-food run uses the
   v11-realistic-ot fixture as one of the migration test inputs.
   No Batch 19 subsequent commit consumes it.

19g-pack (BD-169) — produces:
   project-template/docs/pack/PM-CHAT.md row addition
   supporting-docs/MERGE-STRATEGY.md paragraph
   supporting-docs/MIGRATION-v10-to-v11.md section (~30 lines)
   project-template/.{claude,gemini}/agents/auditor.md edits
   project-template/.codex/agents/auditor.toml edit
   .{claude,codex}/skills/pack-startup/SKILL.md + .gemini/commands/pack-startup.toml
     directive line
   project-template/skills/pm-startup/SKILL.md (canonical) +
     per-CLI mirrors directive line
                                        |
                                        v consumed by:
   19g-PM (BD-169b) lands AFTER 19g-pack so the README.md and
   PACK-CHAT.md PM-only edits reference paths and concepts
   already documented in pack-product prose.

19g-PM (BD-169b) — produces:
   PACK-CHAT.md row addition (verbatim per Addendum #2 §5.2)
   README.md Repository Layout entries (per Addendum #1 §6.3 +
     integration parent §4.4.3)
                                        |
                                        v consumed by:
   19h (BD status flips) — the BACKLOG status-flip commit
   references README.md and PACK-CHAT.md as final-state docs.

19h (BD status flips) — produces:
   BACKLOG.md status flips: BD-164..BD-170 + BD-167b + BD-169b
   to Resolved; BD-160 to Resolved (combined with BD-170 in 19f);
   BD-161 to Resolved with "absorbed into BD-167" Resolution.
   Separate commit because BACKLOG.md is PM-only (per CLAUDE.md
   PM-only files list) and pack-coder cannot include the BACKLOG
   status flip within its own commit (agents-never-commit rule);
   Pack Chat applies the flip in dedicated 19h covering all 11
   BD-tracked items.
                                        |
                                        v consumed by:
   Downstream Batches 20–24 consume the Resolved-status BDs
   (BD-100 audit reads BACKLOG; BD-102 dog-food exercises the
   migration end-to-end).
```

### §3.2 — Why this commit ordering

- **19a first.** The helpers must exist before anything that calls them (BD-165, BD-166, BD-168, BD-170, BD-169 docs).
- **19b-pack before 19b-PM.** BD-167's canonical templates create the paths that BD-167b's trinity Key files / PACK-AGENTS.md / pack-* agent prompts reference. Without 19b-pack, the PM-only edits would point at non-existent paths (failing manual review).
- **19b-PM before 19c.** The PACK-AGENTS.md PM-only directories list expansion (Goal 3 binding per integration parent §6) protects pack agents from writing per-entry files. BD-165's migrator wires the decompose step that writes per-entry files in client repos; the protection must be in place first conceptually (though the migrator is invoked by Pack Chat / migrator tooling, not by an agent — the rule is Goal-3-clean by design).
- **19c after 19b-{pack,PM}.** BD-165 wires the migrator to read the canonical templates installed by BD-167's install-step extension; the templates must exist in pack-product source first.
- **19d after 19c.** BD-166's init-project.sh extension is symmetric with BD-165's migrator extension (same helpers, same templates); ordering is conventional rather than strict (init-project.sh and migrate-v10-to-v11.sh are independent scripts), but landing 19c first matches the migrator-then-init flow tested at greenfield boot.
- **19e after 19d.** Check 32 / 33 / 34 verify the per-entry tree state; if BD-167's canonical templates have a bug, the validator on push will catch it. Landing the validator AFTER the templates means the first-push CI catches any template defect.
- **19f after 19e.** The fixture extension (BD-170) needs the validator to pass on the new fixture (the manifest regeneration step verifies SHAs); landing 19e first ensures the validator gate is live.
- **19g-pack after 19f.** Documentation references the helpers, validator, and fixture; landing them all first gives the docs accurate referent.
- **19g-PM after 19g-pack.** README.md Repository Layout references the new pack-product directories created by 19b-pack; the references make sense once the pack-product prose (BD-169) is in place.
- **19h last.** Status flips after all batch work is green. Separate commit because BACKLOG.md is PM-only (per CLAUDE.md PM-only files list) and pack-coder commits 19a/19b-pack/19c/19d/19e/19f/19g-pack cannot include the BACKLOG status flip within the same commit (agents-never-commit rule per CLAUDE.md pack memory); Pack Chat applies the flip in dedicated 19h covering all 11 BD-tracked items at once. (Note: EXECUTION-PLAN-V11.0.md §C.4 implicit-flip rule says status flips happen INSIDE the implementation commit; the 19h structure is forced by the agents-never-commit + PM-only-file rules and supersedes the §C.4 in-commit shape for this batch.)

### §3.3 — File-set conflicts (ensures parallelism would be unsafe)

Even if the planner wanted to parallelize commits within Batch 19,
the following conflicts force sequential ordering:

- **19a / 19b-pack / 19c / 19d / 19e / 19f all touch `scripts/lib/` or `scripts/`.** Different files in the same directory; safe in principle for parallel coding sessions, but commit ordering must be sequential because each consumes prior outputs.
- **19b-pack / 19c both extend `scripts/migrate-v10-to-v11.sh`.** 19b-pack adds the install-step entry for the canonical templates; 19c adds the 6th sub-op `_v10_to_v11_decompose_streams`. Both edit the post-dispatch hook section but at different lines. Sequential.
- **19g-pack / 19b-pack both touch project-template files.** 19b-pack creates `project-template/docs/project/` and the `_rules.md` / `_intro.md` / `_format.md` canonical templates; 19g-pack edits `project-template/docs/pack/PM-CHAT.md` and `project-template/.{claude,gemini}/agents/auditor.md` + `project-template/.codex/agents/auditor.toml`. Different files. Sequential because of the broader doc-vs-template ordering, not because of file conflicts.
- **19h depends on the rest being green.** Status flips can only happen after `validate-pack.py` is green and the test surface is green.


---

## §4 — Coder vs Pack-Chat-direct allocation

Per the planner-prompt criterion: trivial = mechanical text edits
to a single file or 1:1 mirror addition; non-trivial = anything
involving new script logic, multi-file coordination, or trinity-
rule expansion.

| Commit | Author | Rationale |
|---|---|---|
| 19a | pack-coder | New shell logic across multiple helper files; new test suite; mirror generator + decompose helper + TOC regenerator design surface. Non-trivial. |
| 19b-pack | pack-coder | Multi-file coordination: 5+ canonical templates created, install-step extension in `migrate-v10-to-v11.sh`, `tracker-agent-read.sh` `_tar_read_entry_flat` extension, BD-161 SKILL.md installs absorbed. Non-trivial. |
| 19b-PM | **Pack Chat direct** | All targets are PM-only files. Trinity-rule expansion across 6 trinity files; PACK-AGENTS.md PM-only directories list extension; CLAUDE.md pack-memory bullet (trinity); pack-* agent prompts × 15 files (PM-only — agent files are off-limits to all agents). Per CLAUDE.md "What agents must never modify without explicit instruction" list. STATUS.md disclaimer NOT in 19b-PM scope per R-3 resolution (moved to 19g-pack PM-CHAT.md guidance). |
| 19c | pack-coder | New post-dispatch sub-op; new adapter-private helper file; new `--force-overwrite-mirror` flag wiring in `migrator-core.sh` mode-flag parser. Non-trivial. |
| 19d | pack-coder | New stage extension or new stage in `init-project.sh`; helper invocation against empty input. Non-trivial. |
| 19e | pack-coder | Three new validator check functions; STREAMS constant; test fixtures. Non-trivial. |
| 19f | pack-coder | Combined BD-160 + BD-170 per R-2 resolution. Fixture builder extension (BD-160 v11 case dispatch + C2/C3 customization re-verification on v11 surface; BD-170 per-entry tree decomposition + round-trip test); manifest regeneration; README table row. Non-trivial. |
| 19g-pack | pack-coder | Multi-file documentation + audit-methodology SKILL.md scope extension per R-4 (project-template auditor agent files NOT modified per R-4; pack-* agent prompts handled in 19b-PM); STATUS.md disclaimer guidance paragraph in PM-CHAT.md per R-3; skill directive additions × 7 files (pack-startup × 3 + pm-startup × 4). Non-trivial coordination. |
| 19g-PM | **Pack Chat direct** | PACK-CHAT.md (PM-only) row addition; README.md Repository Layout entries (PM-only). |
| 19h | **Pack Chat direct** | BACKLOG.md status flips (PM-only). Separate commit forced by agents-never-commit + PM-only-file rules (per CLAUDE.md pack memory): pack-coder cannot flip BACKLOG status within its own commit, so Pack Chat applies all 11 status flips in dedicated 19h. (Supersedes EXECUTION-PLAN §C.4 in-commit-flip shape for this batch.) |

**Total: 6 pack-coder commits + 4 Pack-Chat-direct commits = 10 commits.** Matches Addendum #1 §6.5 commit ordering.


---

## §5 — Per-commit specifications

Each commit lists: commit message format, BDs touched, files
created / modified / deleted with verified absolute paths, pre-state
and post-state per file, dependencies on prior commits, and the
verification gate (which checks must pass before the commit is
considered complete).

The commit-message format follows pack convention from CLAUDE.md
(`feat: vN — BD-NNN short description` / `fix:` / `docs:` per the
nature of the change).

### §5.1 — Commit 19a — BD-164: per-entry helpers

**Commit message:**
```
feat: v11 — BD-164 per-entry split helpers (decompose + mirror generator + _toc.md regenerator)
```

**BDs touched:** BD-164 (sole content; status flip deferred to 19h).

**Files created (verify absent before commit):**

| Absolute path | Purpose |
|---|---|
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/per-entry/` (directory) | New helper home (planner picks single-file vs sub-directory per integration parent §18.1 #2) |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/per-entry/decompose.sh` (provisional name; planner picks final per integration parent §18.1 #1) | Decompose monolithic → per-entry tree. Idempotent. Adds line-1 HTML-comment back-pointer per Layer 2 (per Addendum #2 §2 — HTML comment ONLY, no body field). |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/per-entry/mirror-generate.sh` (provisional name) | Regenerate monolithic mirror from per-entry tree + supporting files (intro + entries in sort order + v8-archive for pack backlog only). Strips line-1 HTML-comment back-pointer from per-entry content when emitting. Idempotent + deterministic per sidecar §6.2. Reads `_rules.md` for supporting-file basename list ONLY (per integration parent §7.5); hard-codes entry regex + state vocabulary + grammar field labels. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/per-entry/toc-regenerate.sh` (provisional name) | Regenerate `_toc.md` from per-entry tree per stream-specific axis (per sidecar §5.1 + Mode 2 declaration). Deterministic; same parsing logic shared with mirror-generate.sh per sidecar §6.2. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/per-entry/_lib.sh` (recommended sub-helper for shared parsing logic; planner picks final) | Shared parser utilities consumed by all three. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/tests/test-per-entry.sh` (provisional name) | Test cases per integration parent §18.2 #1: round-trip identity (decompose → regenerate yields byte-identical mirror); empty-tree (regenerate produces mirror with only `_intro.md` content); supporting-file admission (`_quotas.md` unknown → SKIP; `_v8-resolved-archive.md` known → emit); regenerator divergence-warning behavior (interactive vs non-interactive context per Addendum #1 §5.3 + Addendum #2 §4 split). |

**Files modified:** none in this commit.

**Files deleted:** none.

**Pre-state.** All listed paths absent (verified by `ls`).
`scripts/lib/migrate-v10-to-v11/` exists (per `ls scripts/lib/`)
but does NOT yet contain `decompose.sh` (that lands in 19c).

**Post-state.** All listed paths created. Helpers are
self-contained and testable in isolation; running
`bash scripts/tests/test-per-entry.sh` exits 0.

**Dependencies on prior commits in batch:** none — this is the first commit.

**Verification gate:**
- New `scripts/tests/test-per-entry.sh` PASSES (all test cases per integration parent §18.2 #1).
- Existing `bash scripts/validate-pack.py` PASSES with all 31 existing checks (per `grep -n "^def check_"`).
- Trinity rule N/A (no trinity files modified).
- Manual: review the divergence-warning routing — interactive context per Addendum #1 §5.3 (TTY detection prompts user); non-interactive context bridged to BD-095 mode in 19c (so 19a's helpers EMIT the warning + return non-zero exit if invoked outside `--force-overwrite-mirror`; the BD-095 wiring in 19c interprets the exit code).

**Constraints (architect-doc bindings):**
- Mirror generator MUST be deterministic + idempotent (sidecar §6.2; Addendum #2 §6.7).
- Helper MUST read `_rules.md` at runtime ONLY for the supporting-file basename list (per integration parent §7.5 split — entry regex + state vocab + field labels are hard-coded).
- Helper MUST treat unknown supporting-file basenames as SKIP (per integration parent §7.5 final paragraph).
- Decompose helper MUST add line-1 HTML-comment back-pointer per Layer 2 (Addendum #2 §2 — `<!-- per-entry source: /backlog/BD-NNN.md; contract: /backlog/_rules.md -->` shape; non-dot paths per Addendum #1 §10).
- Mirror generator MUST strip line-1 HTML-comment back-pointer when emitting (per integration parent §4.2 Layer 2 strip discipline; preserves byte-additive grammar invariant).
- NO body-field back-pointer (per Addendum #2 §2 — DROPPED).
- Helpers live in `scripts/lib/` per signal-6 carve-out (per integration parent §13.3); no new top-level scripts.

**Architect-doc planner-deferred items (planner picks; coder ships):**
- Helper file structure: single `scripts/lib/per-entry.sh` vs sub-directory `scripts/lib/per-entry/{decompose,mirror,toc,_lib}.sh`. Recommendation per integration parent §18.1 #2: sub-directory because three distinct surfaces with shared parsing logic.
- Function naming: `regenerate_mirror`, `regenerate_toc`, `decompose_streams` are sample shapes per integration parent §18.1 #1.


### §5.2 — Commit 19b-pack — BD-167: pack-product templates + install plumbing (absorbs BD-161)

**Commit message:**
```
feat: v11 — BD-167 per-entry split client artifact installs (absorbs BD-161)
```

**BDs touched:** BD-167 (sole content; status flip 19h). BD-161 absorbed (status flip 19h with "absorbed into BD-167" Resolution).

**Files created (verify absent before commit):**

| Absolute path | Purpose |
|---|---|
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/docs/project/` (directory) | New canonical-template home for project-side per-entry trees |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/docs/project/backlog/_rules.md` | Per-stream contract per sidecar §4 + Addendum #1 §3 (mode-aware): filename regex `^TD-\d+\.md$`; lifecycle states {Open, Resolved}; supporting-file basenames {`_rules.md`, `_intro.md`, `_toc.md`}; write-authority pointer to PM-CHAT.md + METHODOLOGY.md Part 7. Pointer-heavy, ~30–60 lines per sidecar §4.1. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/docs/project/backlog/_intro.md` | Stream preamble + how-to-use text per Addendum #1 §3.4 (mode-aware) + Addendum #1 §5.2 (Layer 1 "DO NOT EDIT" warning block at top, sourced for the regenerated mirror's preamble). |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/docs/project/implementation-plan/_rules.md` | Per-stream contract: filename regex `^(phase-\d+|phase-\d+\.\d+)\.md$` (per sidecar §3.4 — but addendum §2 locks "one file per phase, tasks inline"; planner verifies whether per-task files are emitted or tasks-inline is the canonical shape per Addendum #1 §6.4 BD-167 spec); lifecycle states per V3.3-DELTA §6.3; supporting-file basenames {`_rules.md`, `_intro.md`, `_toc.md`}; write-authority pointer. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/docs/project/implementation-plan/_intro.md` | Stream preamble + DO-NOT-EDIT warning. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/docs/project/changelog/_rules.md` | Per-stream contract: filename regex `^\d{4}-\d{2}-\d{2}-.+\.md$`; append-only-historical (no lifecycle); supporting-file basenames {`_rules.md`, `_intro.md`, `_toc.md`, `_format.md`}. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/docs/project/changelog/_intro.md` | Stream preamble + DO-NOT-EDIT warning. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/docs/project/changelog/_format.md` | Project-side CHANGELOG Format Rules block per sidecar §3.5 (project-side asymmetry — pack changelog has no analog). Sourced from OT v10 `docs/project/CHANGELOG.md` Format Rules H2 (per sidecar §3.5 + RESEARCH §3 line 408–421 area). |

**Files modified:**

| Absolute path | Change |
|---|---|
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/migrate-v10-to-v11.sh` | Extend `_v10_to_v11_install_v11_artifacts` (currently 3rd sub-op at lines 144–148; verify by `sed -n '144,148p'`) to install the new project-template canonical templates + the BD-161 net-new SKILL.md dirs (BD-156 / BD-157 / BD-158 + python-server-architecture + python-data-architecture + python-observability-patterns from BD-162). Planner picks function placement; coder authors. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/tracker-agent-read.sh` | Extend `_tar_read_entry_flat` (line 153) to PREFER the per-entry file `<stream>/<ID>.md` when the per-entry tree exists (`[[ -d /backlog/ ]]` or analogous mode-aware check per Addendum #1 §3.2 mode-aware language); FALL BACK to the regenerated mirror for backward-compatibility with pre-v11.0 client repos. Per integration parent §5.2 + §18.1 #10 + §18.2 #2. |

**Files deleted:** none.

**Pre-state.** All listed creation paths absent (`find project-template/docs -type d` returns only `project-template/docs` and `project-template/docs/pack` and `project-template/docs/pack/prompts`). `migrate-v10-to-v11.sh` post-dispatch hook at lines 134–149 has 5 sub-ops; install-step is at lines 144–148 (`_v10_to_v11_install_v11_artifacts` per Addendum #1 §6.4 + integration parent §3.1 reading). `tracker-agent-read.sh` `_tar_read_entry_flat` is at line 153 (per integration parent §6.3 + §18.2 #2 reference).

**Post-state.** All canonical templates present. `migrate-v10-to-v11.sh` install step extended to ship the templates AND the BD-161 net-new SKILL.md dirs. `tracker-agent-read.sh` `_tar_read_entry_flat` extended with the per-entry-prefer-mirror-fallback shim. The pack repo's pack-product source ships v11.0 client artifacts including the per-entry tree skeletons.

**Dependencies on prior commits in batch:**
- 19a (BD-164): the helpers must exist in pack-product source so the migrator's install step (extended in this commit) ships them. The helpers are referenced by the canonical `_intro.md` "DO NOT EDIT" warning text (which says "to change an entry, edit the corresponding `<stream>/<ID>.md` per-entry file and re-run the mirror regenerator") — the helpers MUST exist for the warning text to be accurate.

**Verification gate:**
- `bash scripts/validate-pack.py` PASSES (existing 31 checks; new Checks 32/33/34 not yet live — they land in 19e).
- Existing tests still pass (no regression).
- Manual: visual inspection of the 8 canonical template files for content correctness against sidecar §4 / §5 / §3.5 specs + Addendum #1 §5.2 "DO NOT EDIT" warning shape.
- Manual: visual inspection of `migrate-v10-to-v11.sh` extension to confirm the install step ships all 8 canonical templates + the BD-161 net-new SKILL.md dirs.
- Manual: visual inspection of `tracker-agent-read.sh` `_tar_read_entry_flat` extension to confirm the mode-aware prefer-then-fall-back logic works for both pre-v11.0 and v11.0+ client shapes.

**Constraints (architect-doc bindings):**
- `_rules.md` MUST be pointer-heavy + short (~30–60 lines per sidecar §4.1).
- `_rules.md` MUST contain the sixth contract item: supporting-file basenames admitted (per addendum §3.3 sixth item; consumed by helpers at runtime per integration parent §7.5).
- `_intro.md` MUST contain the Layer 1 "DO NOT EDIT" warning block (per Addendum #1 §5.2 — HTML comment shape).
- `_intro.md` MUST be pack-shipped immutable (per integration parent §3.3 — not tracker-touched; updated only on pack version-bump).
- `_format.md` (project changelog only) MUST preserve OT v10 Format Rules block content (per sidecar §3.5 — project-side asymmetry; pack-shipped immutable like `_rules.md`).
- BD-161 net-new SKILL.md dirs MUST install in the same step as the canonical templates (per integration parent §17.2 BD-167 absorption + §8.14).
- `_tar_read_entry_flat` extension MUST preserve backward-compatibility for pre-v11.0 clients (per integration parent §18.2 #2).
- Per-entry-tree paths MUST use non-dot (`docs/project/backlog/`, etc. — already non-dot per Addendum #1 §10; project-side was already non-dot in sidecar; only pack-side changed convention).

**Architect-doc planner-deferred items:**
- Function placement of the install-step extension (planner picks insertion point in `migrate-v10-to-v11.sh`).
- Whether to fold the canonical-template install into the existing `_v10_to_v11_install_v11_artifacts` or add a sibling sub-op (recommendation per Addendum #1 §6.4: fold).
- Whether `_tar_read_entry_flat` extension folds into the existing function or adds a sibling `_tar_read_entry_per_entry` (recommendation per integration parent §18.1 #10: extend existing).
- Phase-task decomposition unit for project implementation-plan stream: per Addendum §2 the design locks "one file per phase, tasks inline" — but sidecar §3.4 originally allowed `phase-N.M.md` per-task files. Addendum #1 §6.4 BD-167 spec uses "phase-N.md per-phase files (no per-task files per addendum §2)". Plan applies addendum decision: tasks inline, no per-task files. Filename regex in `_rules.md` becomes `^phase-\d+\.md$` (no `phase-\d+\.\d+\.md` admitted).


### §5.3 — Commit 19b-PM — BD-167b: PM-only edits (Pack Chat direct)

**Commit message:**
```
docs: v11 — BD-167b per-entry split PM-only edits (trinity Key files + PACK-AGENTS.md + CLAUDE.md pack-memory + pack-* agent prompts)
```

**Author:** Pack Chat direct (no agent — all targets are PM-only).

**BDs touched:** BD-167b (sole content; status flip 19h).

**Files modified (PM-only — Pack Chat applies; trinity rule applies for trinity files):**

| Absolute path | Change |
|---|---|
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md` | (1) "Key files to read before working on the pack" block (~lines 28–33): add one line `"- /backlog/, /changelog/ — per-entry source-of-truth trees (read /backlog/_rules.md and /changelog/_rules.md for the per-stream contract; BACKLOG.md and CHANGELOG.md are the regenerated mirrors)"`. (2) Pack-memory section (starts ~line 93): add the mode-aware "Per-entry trees vs mirrors — mode-dependent source of truth" bullet verbatim per Addendum #1 §3.4. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/AGENTS.md` | Same edits as CLAUDE.md — trinity rule. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/GEMINI.md` | Same edits as CLAUDE.md — trinity rule. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/CLAUDE.md` | "Key files" / "Document locations" block: add analog line naming `docs/project/backlog/`, `docs/project/implementation-plan/`, `docs/project/changelog/` and the project-side `_rules.md` paths. (No pack-memory bullet — pack-memory is pack-self only.) |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/AGENTS.md` | Same edits as project-template/CLAUDE.md — trinity rule. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/GEMINI.md` | Same edits as project-template/CLAUDE.md — trinity rule. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/PACK-AGENTS.md` | "PM-only files" block at lines 139–142 (per integration parent §6.4 + Addendum #1 §3.1 honest framing). Extend the list from naming files to naming files + directories per integration parent §6.4 specification: add `/backlog/`, `/changelog/` (pack), `project-template/docs/project/backlog/`, `project-template/docs/project/implementation-plan/`, `project-template/docs/project/changelog/` (project-template canonical). Add one paragraph noting `_rules.md` / `_intro.md` / `_format.md` / `_v8-resolved-archive.md` are pack-shipped immutable; `_toc.md` is derived. Add one line noting pack-coder MAY scope per-entry tree in for explicit BD if Pack Chat's prompt scopes it. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.claude/agents/pack-architect.md` | Add to "Inputs to read" / "Before making any design recommendation, read:" block (per integration parent Layer 4 + Addendum #1 §1.4): two lines `"- /backlog/_rules.md (pack per-entry tree contract)"` and `"- /changelog/_rules.md (pack changelog per-entry tree contract)"`. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.claude/agents/pack-coder.md` | Same addition. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.claude/agents/pack-docs-researcher.md` | Same addition. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.claude/agents/pack-planner.md` | Same addition. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.claude/agents/pack-reviewer.md` | Same addition. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.codex/agents/pack-architect.toml` | **TOML format** (per Addendum #2 §1 + verify-by-`ls`). Same substantive addition placed inside the existing `prompt = """..."""` triple-quoted TOML string (per Addendum #2 §1.4). Trinity rule: same prose; format-specific wrapping. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.codex/agents/pack-coder.toml` | Same. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.codex/agents/pack-docs-researcher.toml` | Same. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.codex/agents/pack-planner.toml` | Same. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.codex/agents/pack-reviewer.toml` | Same. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.gemini/agents/pack-architect.md` | Same addition as Claude (Markdown format with YAML frontmatter per `PACK-AGENTS.md:174-176`). |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.gemini/agents/pack-coder.md` | Same. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.gemini/agents/pack-docs-researcher.md` | Same. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.gemini/agents/pack-planner.md` | Same. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.gemini/agents/pack-reviewer.md` | Same. |

**STATUS.md disclaimer surfacing — RESOLVED per Pack-Chat-direct R-3 (Option A).** STATUS.md disclaimer lives in PM-CHAT.md kickoff guidance (Option A); lands in 19g-pack (BD-169) PM-CHAT.md edits per §5.8 above, NOT in 19b-PM. No new pack-product STATUS_TEMPLATE.md file (Option B was rejected). STATUS.md remains client-authored. See §10.3 R-3 resolution detail.

**Files deleted:** none.

**Pre-state.** Trinity files (6 paths) verified present per `ls`.
PACK-AGENTS.md verified present per `ls`. Pack-* agent files
verified present per `ls -la .{claude,codex,gemini}/agents/` —
5 files per CLI × 3 CLIs = 15 files (with Codex `.toml` + Claude /
Gemini `.md`, per Addendum #2 §1 + §6.1).

**Post-state.** All 22 PM-only files (3 trinity + 3 trinity + 1
PACK-AGENTS + 5 pack-* claude + 5 pack-* codex toml + 5 pack-*
gemini = 22) edited with the discoverability + write-authority +
pack-memory additions. STATUS.md disclaimer is NOT in 19b-PM scope —
per R-3 resolution (Option A) it lands in 19g-pack as a PM-CHAT.md
guidance paragraph, not as a 19b-PM trinity-file edit.

**Dependencies on prior commits in batch:**
- 19b-pack (BD-167): the trinity Key files lines and PACK-AGENTS.md PM-only directories list reference the per-entry tree paths created by BD-167's canonical templates. Without 19b-pack having landed, the references would point at non-existent paths.
- 19a (BD-164): the helper file paths referenced in Pack memory bullet ("read more at `<stream>/_rules.md`") implicitly depend on the helpers existing — since the bullet describes the helpers' role.

**Verification gate:**
- `bash scripts/validate-pack.py` PASSES (existing 31 checks; new Checks 32/33/34 not yet live).
- Trinity-file byte-equivalence check: the same prose lands in CLAUDE.md / AGENTS.md / GEMINI.md (pack root) and in project-template/{CLAUDE,AGENTS,GEMINI}.md per the trinity rule. Pack Chat verifies via `diff`-like inspection or grep parity.
- Manual: visual inspection of all 22 file edits to confirm:
  (a) consistent prose across trinity sets (modulo tool-specific tweaks),
  (b) Codex TOML strings are well-formed (no embedded triple-quote sequences),
  (c) PACK-AGENTS.md directory list extension is the honest Signal 9 trip framing per Addendum #1 §3.1 (NOT "refactor not expansion"),
  (d) CLAUDE.md pack-memory bullet uses mode-aware language per Addendum #1 §3.4 (NOT integration parent §6.5's mode-unaware text).

**Constraints (architect-doc bindings):**
- Trinity rule per CLAUDE.md "Trinity rule": parallel edits to all three (pack-root) and parallel edits to all three (project-template). Each set is a trinity unto itself.
- PACK-AGENTS.md framing per Addendum #1 §3.1: honest Signal 9 trip; THIS architect+planner pass IS the justification.
- CLAUDE.md pack-memory bullet text per Addendum #1 §3.4 (mode-aware): replaces integration parent §6.5 (mode-unaware) text.
- Codex agent files MUST be `.toml` not `.md` (per Addendum #2 §1 BLOCKER).
- Pack-* agent prompt addition is byte-additive on existing "Inputs to read" / "Before making any design recommendation, read:" blocks (per integration parent Layer 4 + Addendum #1 §1.4).
- STATUS.md disclaimer surfacing: per §10.3 R-3 resolution (Option A) — moved out of 19b-PM scope; lives in 19g-pack PM-CHAT.md guidance.

**Architect-doc planner-deferred items:**
- Exact wording of trinity Key files line (per Addendum #1 §1.3 sample shape; planner refines).
- Exact wording of CLAUDE.md pack-memory bullet (per Addendum #1 §3.4 sample shape; Pack Chat refines).
- PACK-AGENTS.md directory-list expansion final wording (per integration parent §6.4 spec).
- (STATUS.md disclaimer routing — RESOLVED per R-3 Option A; no longer a planner-deferred item.)


### §5.4 — Commit 19c — BD-165: v10→v11 migrator post-dispatch decompose step + `--force-overwrite-mirror` flag

**Commit message:**
```
feat: v11 — BD-165 v10→v11 migrator decompose-streams 6th sub-op + --force-overwrite-mirror flag (BD-095 bridge)
```

**BDs touched:** BD-165 (sole content; status flip 19h).

**Files created (verify absent before commit):**

| Absolute path | Purpose |
|---|---|
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/migrate-v10-to-v11/decompose.sh` | Adapter-private decompose helper. Sources the BD-164 helpers from `scripts/lib/per-entry/`. Defines `_v10_to_v11_decompose_streams()` per integration parent §3.1 + Addendum #1 §6.4 + sidecar §1.3 (downgraded to constraint statement per integration parent §3.1). |

**Files modified:**

| Absolute path | Change |
|---|---|
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/migrate-v10-to-v11.sh` | Add 6th sub-op call to `_v10_to_v11_decompose_streams` in the post-dispatch hook (currently 5 sub-ops at lines 144–148; per `sed -n '144,148p'` reading). Constraint: MUST run AFTER all 5 existing sub-ops (BD-104 rename, BD-042 relocation, v11 install, BD-144 capability-token translation, python-architecture refs rename) so the decompose step reads the final v11-shape monolithic files (per integration parent §3.1 constraint statement). Source the new `scripts/lib/migrate-v10-to-v11/decompose.sh` near the existing source statements. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/migrator-core.sh` | Extend mode-flag parser at lines 264–276 (verified via `grep -n "_MIGRATOR_MODE\|--dry-run" scripts/lib/migrator-core.sh`) to add `--force-overwrite-mirror` parsing. Sample addition shape per Addendum #2 §4.5: `--force-overwrite-mirror) _MIGRATOR_FORCE_OVERWRITE_MIRROR="1" ; shift ;;`. Default `_MIGRATOR_FORCE_OVERWRITE_MIRROR="0"` set near `_MIGRATOR_MODE` initialization at line 121. Add usage line in the help text near lines 243–245. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/migrator-core.sh` (post-report hook contract) | The `_v10_to_v11_decompose_streams` step uses the post-report hook (existing required `migrator_post_report_hook`) to add the BD-088-style advisory paragraph explaining v11.0 decomposition is non-reversible + names the rollback path per integration parent §8.18 sample text. Implementation lives in the v10→v11 adapter (`migrate-v10-to-v11.sh`), not in `migrator-core.sh`. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/migrate-v10-to-v11.sh` (post-report hook) | Add the v11.0 decomposition advisory paragraph per integration parent §8.18 sample text (~12-line block explaining what changed + how to rollback). Inserted into the existing `migrator_post_report_hook` adapter function. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/per-entry/mirror-generate.sh` (and possibly `decompose.sh`) | Update the divergence-detection routing per Addendum #2 §4: in non-interactive context (CI / migrator), check `_MIGRATOR_MODE` and `_MIGRATOR_FORCE_OVERWRITE_MIRROR`; in `--dry-run` mode, REPORT divergence to stdout and exit 0; in `--apply` / `--resume` mode without `--force-overwrite-mirror`, BLOCK with `EXIT_GATE_FAILED=31` (per `migrator-core.sh:70`) and a recovery instruction; in `--apply` / `--resume` with `--force-overwrite-mirror`, proceed (with stderr warning for audit trail per Addendum #2 §4.5). Interactive context routing UNCHANGED from Addendum #1 §5.3 (TTY check + prompt). |

**Files deleted:** none.

**Pre-state.** `scripts/lib/migrate-v10-to-v11/decompose.sh` absent (verified by `ls scripts/lib/migrate-v10-to-v11/` per Addendum #2 §6.4 + integration parent §1.1). `migrate-v10-to-v11.sh` post-dispatch hook has 5 sub-ops (verified at lines 144–148). `migrator-core.sh` mode-flag parser at 264–276 has `--dry-run` / `--apply` / `--resume`; no `--force-overwrite-mirror` (verified via `grep -nE "MIGRATOR_FORCE" scripts/lib/migrator-core.sh` returns nothing).

**Post-state.** `scripts/lib/migrate-v10-to-v11/decompose.sh` exists. `migrate-v10-to-v11.sh` post-dispatch hook has 6 sub-ops; post-report hook has the v11.0 decomposition advisory paragraph. `migrator-core.sh` mode-flag parser admits `--force-overwrite-mirror`. The BD-164 helpers' divergence-detection routing dispatches via the BD-095 mode flag.

**Dependencies on prior commits in batch:**
- 19a (BD-164): the helpers MUST exist; `decompose.sh` sources them.
- 19b-pack (BD-167): the canonical templates MUST be installed by the migrator's `_v10_to_v11_install_v11_artifacts` step (extended in 19b-pack) before the decompose step (this commit's 6th sub-op) runs — because the decompose step relies on the per-stream `_rules.md` having been installed in the client repo.

**Verification gate:**
- `bash scripts/validate-pack.py` PASSES (existing 31 checks).
- `bash scripts/test-migrator-core.sh` PASSES (existing BD-119 tests).
- `bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh` PASSES (existing BD-095 dry-run tests).
- `bash scripts/tests/test-migrate-v10-to-v11-gates.sh` PASSES (existing BD-101 gate tests).
- New manual integration test: `bash scripts/migrate-v10-to-v11.sh --dry-run` against a v10-realistic-ot fixture clone reports the new decompose step in the dry-run output. (Builds against the existing v10-realistic-ot fixture; per-entry tree shape lands in 19f's BD-170 fixture extension which adds the v11-realistic-ot golden — this commit's manual check uses the existing v10 fixture as input.)
- New manual integration test: `bash scripts/migrate-v10-to-v11.sh --apply` against a fresh v10-realistic-ot clone produces the per-entry trees + regenerated mirrors AND the post-report hook advisory paragraph.
- New manual integration test: hand-edit the regenerated mirror after migration; re-run the regenerator without `--force-overwrite-mirror` — confirms BLOCK with `EXIT_GATE_FAILED=31` and recovery instruction.
- New manual integration test: same as above with `--force-overwrite-mirror` — confirms proceed with stderr warning.

**Constraints (architect-doc bindings):**
- Decompose step MUST run as the 6th sub-op AFTER all 5 existing sub-ops (per integration parent §3.1 sequencing constraint statement).
- Function name: `_v10_to_v11_decompose_streams` is provisional per sidecar §1.3 + integration parent §3.1; planner picks final.
- Helper location: `scripts/lib/migrate-v10-to-v11/decompose.sh` per Addendum #1 §6.4 + integration parent §10.2 + §18.1 #3 recommendation.
- Flag name: `--force-overwrite-mirror` provisional per Addendum #2 §4.5; planner picks final.
- Default `_MIGRATOR_FORCE_OVERWRITE_MIRROR="0"`.
- Exit code on block: `EXIT_GATE_FAILED=31` (existing slot per `migrator-core.sh:70` verified by `grep -nE "EXIT_GATE_FAILED"`); planner verifies whether to use this slot or a sibling slot per Addendum #2 §4.5.
- BD-095 contract preserved: the bridge composes against existing `_MIGRATOR_DRY_RUN` / `_MIGRATOR_MODE` state vars (lines 109–110, 121); NO redesign of BD-095; NO new mode flag beyond `--force-overwrite-mirror`.
- Backup contract preserved per integration parent §9.4: `_stage_backup` at `scripts/lib/migrator-stages.sh:146` (corrected citation per integration parent §3.2).
- Post-report advisory paragraph per integration parent §8.18 sample text (planner refines wording before commit; ~12 lines).
- BD-119 framework contract UNCHANGED: no new hook; no new framework stage; no manifest entries for per-entry files (per sidecar §10.1 + integration parent §9).

**Architect-doc planner-deferred items:**
- Exact function name + position in call list (planner picks per integration parent §18.1 #4).
- Exact flag-parser placement in `migrator-core.sh` lines 264–276 (planner picks).
- Whether to use existing `EXIT_GATE_FAILED=31` slot or add a new exit code constant (planner picks per Addendum #2 §4.5).
- Exact post-report advisory paragraph wording (planner refines per integration parent §8.18 sample).


### §5.5 — Commit 19d — BD-166: init-project.sh greenfield per-entry tree install

**Commit message:**
```
feat: v11 — BD-166 init-project.sh greenfield per-entry tree install (S11 extension)
```

**BDs touched:** BD-166 (sole content; status flip 19h).

**Files modified:**

| Absolute path | Change |
|---|---|
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/init-project.sh` | Extend `stage_s11_v11_artifacts` (line 803 per integration parent §8.17 + §18.1 #5) to install the per-entry tree skeleton in greenfield client repos. Reads canonical templates from `project-template/docs/project/<stream>/` (created by 19b-pack BD-167) and writes to client `docs/project/<stream>/`. Installs `_rules.md`, `_intro.md`, empty seed `_toc.md` per stream; `_format.md` for project changelog only; no entry files (greenfield project starts empty). After installs, invokes the BD-164 mirror generator + TOC regenerator (per integration parent §9.3) to produce empty mirrors at `docs/project/{BACKLOG.md, IMPLEMENTATION-PLAN.md, CHANGELOG.md}` containing only `_intro.md` content. Per integration parent §8.17 + §9.3. |

**Files created / deleted:** none.

**Pre-state.** `scripts/init-project.sh` `stage_s11_v11_artifacts` exists at line 803 (per integration parent §8.17 verification). `project-template/docs/project/` and its contents exist (created by 19b-pack BD-167; this is a hard dependency).

**Post-state.** `init-project.sh` greenfield path installs the per-entry tree skeleton + supporting files + regenerated empty mirrors. A fresh greenfield init produces a v11.0-shape client repo with empty per-entry trees and current empty mirrors.

**Dependencies on prior commits in batch:**
- 19a (BD-164): the helpers MUST exist; init-project.sh stage extension calls them.
- 19b-pack (BD-167): the canonical templates MUST exist in pack-product source; init-project.sh reads from `project-template/docs/project/<stream>/`.

**Verification gate:**
- `bash scripts/validate-pack.py` PASSES (existing 31 checks).
- `bash scripts/test-init-project.sh` PASSES (existing test suite).
- New manual integration test: run `bash scripts/init-project.sh /tmp/test-greenfield-v11.0` against a clean directory; verify the resulting client has:
  - `docs/project/backlog/_rules.md`, `_intro.md`, `_toc.md` (empty seed) — no `TD-NNN.md` entry files.
  - `docs/project/implementation-plan/_rules.md`, `_intro.md`, `_toc.md` — no `phase-N.md` files.
  - `docs/project/changelog/_rules.md`, `_intro.md`, `_format.md`, `_toc.md` — no entry files.
  - `docs/project/BACKLOG.md` regenerated empty mirror containing only `_intro.md` content.
  - `docs/project/IMPLEMENTATION-PLAN.md` regenerated empty mirror.
  - `docs/project/CHANGELOG.md` regenerated empty mirror.

**Constraints (architect-doc bindings):**
- Stage extension preferred over new stage per integration parent §8.17 + §18.1 #5 recommendation.
- Mirror regenerator MUST handle empty input naturally per integration parent §9.3 (no special "greenfield empty mirror" template).
- Helper reuse pattern preserved per integration parent §9.3: same BD-164 helpers serve three call sites (v10→v11 migrator, init-project.sh, tracker mode transitions per integration parent §5.6).
- `_intro.md` and `_format.md` ship from `project-template/docs/project/<stream>/` per integration parent §9.7 (pack-product canonical templates; client receives via init).

**Architect-doc planner-deferred items:**
- Whether to fold into `stage_s11_v11_artifacts` or add `stage_s11b_per_entry_tree` (recommendation per integration parent §8.17 + §18.1 #5: extend S11). Planner picks final.

### §5.6 — Commit 19e — BD-168: validator Checks 32 / 33 / 34

**Commit message:**
```
feat: v11 — BD-168 validate-pack Checks 32 (mirror-in-sync) + 33 (TOC-in-sync) + 34 (cross-reference integrity)
```

**BDs touched:** BD-168 (sole content; status flip 19h).

**Files modified:**

| Absolute path | Change |
|---|---|
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/validate-pack.py` | Add three new check functions per integration parent §10 + Addendum #1 §9.2 pseudo-code disclaimer: `check_mirror_in_sync` (Check 32), `check_toc_in_sync` (Check 33), `check_cross_reference_integrity` (Check 34). Add `STREAMS` constant near existing `BACKLOG_FILE` / `REPO_ROOT` constants per integration parent §18.2 #5. STREAMS shape per integration parent §18.2 #5: `STREAMS = [("/backlog/", "/BACKLOG.md", "BD-NNN"), ("/changelog/", "/CHANGELOG.md", "vN.M"), ...]`. Hook the three new checks into the main check sequence (after Check 31). Each check skips gracefully when the per-entry tree is absent (per integration parent §10.5). Each pseudo-code block in the doc has a disclaimer prepended per Addendum #1 §9.2. |

**Files created (verify absent before commit):**

| Absolute path | Purpose |
|---|---|
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/tests/test-validate-pack-checks-32-33-34.sh` (or fold into existing test surface; planner picks placement per integration parent §18.2 #6) | Synthetic per-entry trees that pass and fail each of Checks 32 / 33 / 34. Lives under `scripts/tests/fixtures/per-entry/` per integration parent §18.2 #6 OR inline in the test runner. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/tests/fixtures/per-entry/` (directory; if planner picks fixture-out approach) | Synthetic per-entry trees + canonical mirror pairs. |

**Files deleted:** none.

**Pre-state.** `validate-pack.py` has 31 check functions (highest is `check_skill_cell_consistency` Check 31 at line 2425, verified by `grep -n "^def check_"`). No `STREAMS` constant. `scripts/tests/fixtures/per-entry/` does not exist.

**Post-state.** `validate-pack.py` has 34 check functions (Checks 32 / 33 / 34 added). STREAMS constant added. New test file + fixtures present. Running `bash scripts/validate-pack.py` exits 0 on the pack repo (Checks 32 / 33 / 34 SKIP — pack-self trees don't exist until Batch 23 BD-102 dog-food).

**Dependencies on prior commits in batch:**
- 19a (BD-164): Check 32 invokes the BD-164 mirror generator against the per-entry tree to produce a temporary file; diffs against on-disk mirror. Same for Check 33 + TOC regenerator.
- 19b-pack (BD-167): the canonical templates exist (Check 32 verifies `_rules.md` exists per stream as a pre-check; if absent, FAIL with "missing `_rules.md` for stream X" per integration parent §10.1 pre-check).

**Verification gate:**
- `bash scripts/validate-pack.py` PASSES on the pack repo (Checks 32 / 33 / 34 SKIP — per-entry trees don't exist yet on pack-self).
- New test runner PASSES against the synthetic fixtures (each check passes the green-fixture and fails the red-fixture).
- Manual: confirm STREAMS constant matches the 5 stream tuples per integration parent §18.2 #5 (pack/backlog, pack/changelog, project/docs/project/backlog, project/docs/project/implementation-plan, project/docs/project/changelog — for pack-self validation only the first two are loaded; project-side trees are validated by the client's CI per integration parent §10.6).
- Manual: confirm Check 32 pre-checks fold the supplementary checks per integration parent §10.4: (a) `_rules.md` exists per stream (FAIL with "missing `_rules.md` for stream X"); (b) per-entry filename conformance (FAIL with "non-conforming filenames: ..."); (c) `_v8-resolved-archive.md` byte-stable (folded into Check 32's main divergence check).
- Manual: confirm Check 34 SKIPs the v8 archive per integration parent §11.3.

**Constraints (architect-doc bindings):**
- Three checks total per integration parent §10.4 (NOT six — folded the rest into Check 32 pre-checks).
- Each check is a Signal 4 trip per the maintainability principle (`ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` §3.2 line 285–287); THIS architect+planner pass IS the defense per integration parent §10.
- Each check SKIPs gracefully when the per-entry tree is absent (per integration parent §10.5 backward-compatibility for pre-v11.0 clients).
- Pack-side scope only per integration parent §10.6 (`validate-pack.py` runs in pack repo CI; project-side trees validated by the client's CI if any).
- Pseudo-code in integration parent §10.1 / §10.3 has a disclaimer per Addendum #1 §9.2 ("Pseudo-code sketches the behavioral contract; planner refines exact implementation"); planner refines.

**Architect-doc planner-deferred items:**
- Exact function names (`check_mirror_in_sync` etc. are placeholder per Addendum #1 §9.1).
- Exact STREAMS tuple shape per integration parent §18.2 #5.
- Test file placement per integration parent §18.2 #6 (separate file vs fold into `test-validate-pack.sh`).


### §5.7 — Commit 19f — BD-160 + BD-170: v11-realistic-ot fixture (v11 case dispatch + per-entry tree extension)

**Commit message:**
```
feat: v11 — BD-160/BD-170 v11-realistic-ot fixture (v11 case dispatch + per-entry tree extension)
```

**BDs touched:** BD-160 + BD-170 combined per Pack-Chat-direct R-2 resolution (status flips for both in 19h). BD-160 creates the v11 case dispatch baseline; BD-170 extends it for per-entry trees. Shipping them as a single commit avoids artificial separation since both are v11-realistic-ot fixture surface work and both share the same dependency on BD-164 helpers.

**Files modified:**

| Absolute path | Change |
|---|---|
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/test-fixtures/build.sh` | (BD-160 part): Extend `_build_realistic_for_version` v11 case dispatch (currently dead code per `_build_realistic_for_version v11` per pack `BACKLOG.md:1399` BD-160 spec) — add `v11-realistic-ot` to `FIXTURE_NAMES` array; implement the v11 case body (source-clone from v11 git tag, run v11 init, apply re-verified C2 ollama-strip and C3 x-agent payload patterns against v11's surface — verify `.codex/config.toml` ollama strip path, verify v11's per-CLI agent dirs `.codex/agents/`, `.claude/agents/`, `.gemini/agents/` accept the x-agent file shape per `migrator_target_surface_for_version v11`). (BD-170 part): Then extend the v11 case to: (1) read the just-built v11 monolithic shape; (2) run the BD-164 decompose helper against it (same helper the migrator's `_v10_to_v11_decompose_streams` uses); (3) write the per-entry tree + supporting files + regenerated mirrors per stream; (4) verify byte-identity round-trip per integration parent §12.1 + §8.7. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/test-fixtures/manifest.txt` | Regenerate. New SHA for `v11-realistic-ot` reflecting both BD-160 v11 case dispatch + BD-170 per-entry tree extension. Coder runs the manifest-regen step per integration parent §12.4. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/test-fixtures/README.md` | Add table row for `v11-realistic-ot` per BD-160 spec (`test-fixtures/README.md` table row). |

**Files created (verify absent before commit):**
- `test-fixtures/v11-realistic-ot/docs/project/backlog/TD-NNN.md` files (gitignored per `README.md:228-233`; built directory).
- `test-fixtures/v11-realistic-ot/docs/project/implementation-plan/phase-N.md` files (gitignored).
- `test-fixtures/v11-realistic-ot/docs/project/changelog/YYYY-MM-DD-*.md` files (gitignored).
- `test-fixtures/v11-realistic-ot/docs/project/{backlog,implementation-plan,changelog}/_rules.md`, `_intro.md`, `_toc.md`, `_format.md` (project changelog only) (gitignored — built per build.sh; canonical templates come from BD-167's pack-product files).

**Files deleted:** none.

**Pre-state.** `test-fixtures/build.sh` does NOT yet have the v11 case dispatch in `FIXTURE_NAMES` (verified — BD-160 is `Status: Open` per `BACKLOG.md:1401`). `v10-realistic-ot/` is the source state for v10 baseline (per `README.md:230`). The v11-realistic-ot directory does not yet exist.

**Post-state.** `test-fixtures/build.sh --all --clean` builds `v11-realistic-ot/` with both (a) the v11 monolithic surface from v11 init + C2/C3 customizations and (b) the per-entry tree shape + regenerated mirrors. The fixture is deterministic (per integration parent §12.3); re-running produces byte-identical output. Manifest.txt has the new SHA. README.md table row reflects `v11-realistic-ot`.

**Dependencies on prior commits in batch:**
- 19a (BD-164): the decompose helper MUST exist; build.sh calls it for the BD-170 part.
- 19b-pack (BD-167): the canonical templates MUST exist in pack-product source; build.sh sources them from `project-template/docs/project/<stream>/`.
- 19c (BD-165): NOT a hard dependency — the fixture builder calls the BD-164 helpers directly (per integration parent §12.1), not the adapter-private migrator helper. But the migrator (BD-165) is the canonical caller of the same helpers; landing BD-165 first ensures the integration test surface in §5.4 is green.

**Verification gate:**
- `bash scripts/validate-pack.py` PASSES (existing 31 + new Checks 32 / 33 / 34 — the pack repo doesn't have per-entry trees so the new checks SKIP; the fixture's per-entry trees are inside `test-fixtures/v11-realistic-ot/` which is gitignored so the pack repo's CI doesn't scan them).
- `bash test-fixtures/build.sh --all --clean` succeeds and produces the v11-realistic-ot fixture.
- New manual integration test per integration parent §12.1: byte-identity round-trip — decompose the v11-realistic-ot monolithic shape; regenerate the mirror from the per-entry tree; diff against the original; must be byte-identical.
- `bash scripts/test-persona-contracts.sh` PASSES (existing tests; BD-116 contract-migration.sh exercises v10→v11 migration of v10-realistic-ot; this should pick up the decompose step per the BD-165 wiring landed in 19c).
- BD-160 verification per its own spec: confirm v11's surface still has `.codex/config.toml` (ollama-strip path); confirm v11's per-CLI agent dirs accept x-agent file shape per `migrator_target_surface_for_version v11` enumeration in `scripts/lib/migrator-core.sh:459-513`.

**Constraints (architect-doc bindings):**
- Fixture must be deterministic per integration parent §12.3.
- Manifest regeneration runs as part of the build step per integration parent §12.4.
- The v10-realistic-ot and v11-flat-file fixtures STAY (per integration parent §12.2); only v11-realistic-ot is added/extended.
- BD-160 + BD-170 ship together per Pack-Chat-direct R-2 resolution: both are v11-realistic-ot fixture surface work; combining avoids artificial separation. BD-170's blocker on BD-160 (per Addendum #1 §6.4 BD table) is satisfied trivially because they ship as one commit.
- BD-160's verification of C2/C3 customization paths against v11's surface per its own File/Symbol field.

**Architect-doc planner-deferred items:**
- Fixture-generator function structure per Addendum #1 §9.1 ("planner picks fixture-generator function structure" qualifier).

### §5.8 — Commit 19g-pack — BD-169: pack-product wording updates

**Commit message:**
```
docs: v11 — BD-169 per-entry split pack-product wording updates (PM-CHAT row + MERGE-STRATEGY + MIGRATION + auditor agents + pack-startup + pm-startup directives)
```

**BDs touched:** BD-169 (sole content; status flip 19h).

**Files modified:**

| Absolute path | Change |
|---|---|
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/docs/pack/PM-CHAT.md` | TWO additions: (1) Add two new rows in file-access strategy table (at lines 119–123 per integration parent §14.2 reference) per Addendum #2 §5.4 verbatim text (per-entry tree direct-read capability + per-stream `_rules.md` discoverability). (2) Add a new paragraph in the kickoff-procedures section per Pack-Chat-direct R-3 resolution: "When authoring `STATUS.md`, prepend the following HTML-comment disclaimer at the top of the file: `<!-- Working snapshot. Source-of-truth lives in docs/project/backlog/ (per-entry tree). Regenerated mirror at docs/project/BACKLOG.md. Edits to STATUS.md must not contradict the per-entry tree.\n  -->` " — exact text per integration parent §5.3 disclaimer shape (coder refines wording to match existing PM-CHAT.md prose voice). This avoids creating a new pack-product STATUS_TEMPLATE.md file; STATUS.md remains client-authored. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/supporting-docs/MERGE-STRATEGY.md` | Add one paragraph in the catch-all classifier section per integration parent §4.4.3 explaining v11.0 per-entry-tree mirror-vs-source distinction (~1 paragraph; coder refines exact text). |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/supporting-docs/MIGRATION-v10-to-v11.md` | Add new "Per-entry decomposition" section (~30 lines per integration parent §4.4.3) covering: what changes (per-entry tree appears under `/backlog/` etc.; monolithic files become regenerated mirrors), why mandatory + non-reversible per addendum §1, what the user does (nothing — the migrator handles it), backup + rollback per integration parent §9.4 + Addendum #2 §4 BD-095 bridge, the `--force-overwrite-mirror` flag semantics for advanced users. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/skills/audit-methodology/SKILL.md` | Extend audit-scope rules per Pack-Chat-direct R-4 resolution: (1) clarification under auditor-docs scope rule 29 (`**/*.md`) that per-entry tree files (`docs/project/backlog/BD-NNN.md`, `docs/project/implementation-plan/phase-N.md`, `docs/project/changelog/YYYY-MM-DD-*.md`) are IN SCOPE as authored source-of-truth; (2) regenerated mirrors (`BACKLOG.md`, `CHANGELOG.md`, `IMPLEMENTATION-PLAN.md`) are OUT OF SCOPE when per-entry tree is present (auditing them duplicates findings against the canonical per-entry tree; auditor-docs SKIPs them). The skill is the authoritative source per its own §66 + per `auditor.md` line 11-12. NO audit agent file edits (auditor.md / auditor.toml × 3 CLIs are NOT modified per R-4 resolution) — the skill delegation chain is sufficient. Init-project.sh `stage_s4_skills` handles per-CLI fanout to `.claude/skills/`, `.codex/skills/`, `.gemini/skills/` at install time. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.claude/skills/pack-startup/SKILL.md` | Add one directive line per Addendum #1 §1.3 (sample shape: "Pack streams under `/backlog/` and `/changelog/` are per-entry trees; read `/backlog/_rules.md` and `/changelog/_rules.md` for the per-stream contract before any per-entry edit."). NOT an "Active skills" addition (per Addendum #1 §1.5 cascade — original §4.4.2 Active-skills line additions are REMOVED in favor of body directive). |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.codex/skills/pack-startup/SKILL.md` | Same addition (Codex SKILL is `.md` per Addendum #2 §6.6 — only Codex AGENTs are `.toml`). |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.gemini/commands/pack-startup.toml` | Same addition (Gemini command is `.toml`). |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/skills/pm-startup/SKILL.md` (canonical) | Add one directive line per Addendum #1 §1.3 (sample shape: "Project streams under `docs/project/backlog/`, `docs/project/implementation-plan/`, `docs/project/changelog/` are per-entry trees; read each `<stream>/_rules.md` for the per-stream contract before any per-entry edit."). |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/.claude/skills/pm-startup/SKILL.md` | Same addition (per-CLI mirror). |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/.codex/skills/pm-startup/SKILL.md` | Same addition (Codex SKILL is `.md`). |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/.gemini/commands/pm-startup.toml` | Same addition (Gemini command is `.toml`). |

**Files created / deleted:** none.

**Pre-state.** All 11 modified files exist (verified by `ls`). PM-CHAT.md is pack-product (`project-template/docs/pack/`); not PM-only at pack-root scope. Auditor agent files (auditor.md / auditor.toml × 3 CLIs) are NOT in this commit's scope per R-4 resolution.

**Post-state.** All 11 files extended with per-entry tree references / directives / prose / scope rules. Pack-product wording reflects v11.0 per-entry decomposition reality. Trinity rule respected within the per-CLI mirror sets (pack-startup × 3, pm-startup canonical + 3 = 4 — pm-startup has a canonical at `project-template/skills/` per `README.md:101-104`). Audit-methodology SKILL.md per-CLI fanout happens at install time via init-project.sh `stage_s4_skills`.

**Dependencies on prior commits in batch:**
- 19b-pack (BD-167): the canonical templates exist; the docs and skill directives reference them.
- 19c (BD-165): the `--force-overwrite-mirror` flag exists; MIGRATION-v10-to-v11.md prose references it.
- 19a (BD-164): the helpers exist; PM-CHAT.md row text and MIGRATION-v10-to-v11.md prose reference them.

**Verification gate:**
- `bash scripts/validate-pack.py` PASSES (Checks 21 + 28 = per-CLI parity for pack-help and pm-startup; per-CLI mirrors must be parity-preserved).
- Trinity rule check for skill mirrors: pack-startup × 3 mirrors have identical substantive content (modulo format-specific tweaks — Gemini TOML vs Claude / Codex Markdown); pm-startup × 4 mirrors (canonical + 3 per-CLI) have identical substantive content.
- Audit-methodology SKILL.md canonical at `project-template/skills/audit-methodology/SKILL.md` — single canonical file; per-CLI mirrors regenerate on next init-project.sh run.
- Manual: visual inspection of MIGRATION-v10-to-v11.md new section for accuracy against integration parent §9.4 backup contract + Addendum #2 §4 BD-095 bridge.
- Manual: visual inspection of PM-CHAT.md row text against Addendum #2 §5.4 verbatim.
- Manual: visual inspection of PM-CHAT.md STATUS.md disclaimer paragraph for accuracy against integration parent §5.3 + R-3 resolution.
- Manual: visual inspection of audit-methodology SKILL.md scope rules for accuracy against R-4 resolution.

**Constraints (architect-doc bindings):**
- PM-CHAT.md row text per Addendum #2 §5.4 verbatim.
- STATUS.md disclaimer guidance lives in PM-CHAT.md only per R-3 resolution; no new pack-product file (no STATUS_TEMPLATE.md).
- Audit-scope extension lives in audit-methodology SKILL.md only per R-4 resolution; no auditor agent file edits (auditor.md / auditor.toml × 3 CLIs are NOT modified).
- Pack-startup / pm-startup directive lines per Addendum #1 §1.3 sample shapes; coder refines.
- No new skill creation (per Addendum #1 §1.3 + Item 1 — `stream-discovery` skill DROPPED in Addendum #1).
- Trinity rule applies per pack-startup × 3 and pm-startup × 4 sets.

**Architect-doc planner-deferred items:**
- Exact directive-line wording for pack-startup / pm-startup per Addendum #1 §1.3.
- Exact MIGRATION-v10-to-v11.md section wording per integration parent §4.4.3 sample (~30 lines).
- Exact MERGE-STRATEGY.md paragraph wording per integration parent §4.4.3.
- Exact STATUS.md disclaimer paragraph wording in PM-CHAT.md per R-3 resolution.
- Exact audit-methodology SKILL.md scope rule wording per R-4 resolution.


### §5.9 — Commit 19g-PM — BD-169b: PM-only wording updates (Pack Chat direct)

**Commit message:**
```
docs: v11 — BD-169b PACK-CHAT.md row + README.md Repository Layout per-entry tree entries
```

**Author:** Pack Chat direct (no agent — all targets are PM-only).

**BDs touched:** BD-169b (sole content; status flip 19h).

**Files modified (PM-only — Pack Chat applies):**

| Absolute path | Change |
|---|---|
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/PACK-CHAT.md` | Add two new rows in file-access strategy table at lines 38–47 (verified by `sed -n '38,47p'`) per Addendum #2 §5.2 verbatim text. The two rows: per-entry tree direct-read capability (`/backlog/<ID>.md`, `/changelog/<ID>.md`); per-stream `_rules.md` discoverability. |
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/README.md` | Repository Layout section (starts line 85; pack-side scripts area at ~lines 173–250). Add new entries naming the per-entry tree directories: pack-side `/backlog/`, `/changelog/` (added under "Pack-specific" section near line 173); project-template-side `docs/project/backlog/`, `docs/project/implementation-plan/`, `docs/project/changelog/` with `_rules.md`, `_intro.md`, `_format.md` (changelog only) noted (added under "project-template/" tree near line 105). Per integration parent §4.4.3 + Addendum #1 §6.3 BD-169b spec. |

**Files created / deleted:** none.

**Pre-state.** PACK-CHAT.md verified at 199 lines; file-access strategy table at lines 38–47 (verified). README.md Repository Layout starts at line 85 (verified by `grep -nE "Repository Layout"`).

**Post-state.** PACK-CHAT.md has two new rows reflecting per-entry-tree direct-read capability. README.md Repository Layout reflects v11.0 per-entry tree directories.

**Dependencies on prior commits in batch:**
- 19g-pack (BD-169): the parallel pack-product wording (PM-CHAT.md) lands first, so PACK-CHAT.md row addition is consistent with PM-CHAT.md row addition.
- 19b-pack (BD-167): the canonical templates exist (so README.md references resolve to actual pack-product directories).

**Verification gate:**
- `bash scripts/validate-pack.py` PASSES.
- Manual: visual inspection of PACK-CHAT.md row text against Addendum #2 §5.2 verbatim (no abdication; exact text per architect doc).
- Manual: visual inspection of README.md Repository Layout entries for accuracy against actual directory shape created by 19b-pack.

**Constraints (architect-doc bindings):**
- PACK-CHAT.md row text per Addendum #2 §5.2 verbatim.
- README.md Repository Layout entries per integration parent §4.4.3.
- Trinity rule N/A (PACK-CHAT.md and README.md are not trinity-replicated).

**Architect-doc planner-deferred items:**
- README.md Repository Layout entry exact placement (planner picks position within the existing layout sections).

### §5.10 — Commit 19h — BD status flips (Pack Chat direct)

**Commit message:**
```
docs: v11 — Batch 19 BD status flips (BD-164..BD-170 + BD-167b + BD-169b + BD-160 → Resolved; BD-161 → Resolved/absorbed)
```

**Author:** Pack Chat direct (BACKLOG.md is PM-only).

**BDs touched:** BD-164, BD-165, BD-166, BD-167, BD-167b, BD-168, BD-169, BD-169b, BD-170 (all flipped to Resolved); BD-160 (flipped to Resolved per Pack-Chat-direct R-2 resolution — shipped in commit 19f combined with BD-170); BD-161 (flipped to Resolved with "absorbed into BD-167" Resolution).

**Files modified (PM-only — Pack Chat applies):**

| Absolute path | Change |
|---|---|
| `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/BACKLOG.md` | Status flips for the 9 new BDs (BD-164 through BD-170 + BD-167b + BD-169b): `Status: Open` → `Status: Resolved`; fill `Resolved:` line with date + commit SHA + brief outcome description per the existing pack-side BD-resolution convention (verified shape per `BACKLOG.md` recent BD-156 / BD-157 / BD-158 entries). For BD-160 (existing entry at `BACKLOG.md:1399`): `Status: Open` → `Status: Resolved`; `Resolved:` line cites "shipped in commit 19f combined with BD-170 per Pack-Chat-direct R-2 resolution; both BDs are v11-realistic-ot fixture surface work and shared the same dependency on BD-164 helpers." For BD-161 (entry at `BACKLOG.md:1388`): `Status: Open` → `Status: Resolved`; `Resolved:` line cites "absorbed into BD-167 v11.0 client artifact install batch (commits 19b-pack + 19b-PM)" per integration parent §17.2 + Addendum #1 §6.4. |

**Files created / deleted:** none.

**Pre-state.** BD-164..BD-170 + BD-167b + BD-169b entries do NOT yet exist in BACKLOG.md (they are CREATED by Pack Chat as part of the §6 PM-only edit specifications BEFORE Batch 19 fires; the §6 spec details that creation step). The 9 entries land in BACKLOG.md as `Status: Open` BEFORE 19a fires; they flip to `Status: Resolved` in this commit (19h). BD-160 entry header at `BACKLOG.md:1399`; `Status: Open` field at line 1401 (verified). BD-161 entry header at `BACKLOG.md:1388` (per integration parent §8.14 reference) with `Status: Open`.

**Post-state.** All 11 BDs (9 new + BD-160 + BD-161 absorbed) flipped to Resolved with appropriate Resolved-line content.

**Dependencies on prior commits in batch:** ALL prior commits 19a / 19b-pack / 19b-PM / 19c / 19d / 19e / 19f / 19g-pack / 19g-PM. The status flip is the LAST step of Batch 19. Separate commit because BACKLOG.md is PM-only (per CLAUDE.md PM-only files list); pack-coder commits cannot include the status flip within their own commit (agents-never-commit rule per CLAUDE.md pack memory); Pack Chat applies all 11 status flips in dedicated 19h. The EXECUTION-PLAN-V11.0.md §C.4 in-commit-flip rule is superseded for this batch by the agents-never-commit + PM-only-file structural constraints.

**Verification gate:**
- `bash scripts/validate-pack.py` PASSES (full 31 + 3 = 34 checks; new Checks 32/33/34 SKIP because pack-self trees don't exist until Batch 23).
- All previous commits' verification gates PASSED (regression catches: per-CLI parity, trinity rule, byte-equivalence checks).
- Manual: visual inspection of all 10 BD entries' Resolved-line text for accuracy and consistent commit-SHA format.

**Constraints (architect-doc bindings):**
- Per CLAUDE.md "Pack memory" implicit-flip rule: status flips happen after batch review + tests are green; no separate user approval needed for the flip itself (the implementation work is approved per stop-before-commit; the flip is mechanical). Note: EXECUTION-PLAN-V11.0.md §C.4 says flips happen INSIDE the implementation commit; for this batch the 19h separate-commit structure is forced by agents-never-commit + PM-only-file rules and supersedes §C.4's in-commit shape.
- Per CLAUDE.md "Pack memory" (no Resolved section rule): entries flip in place with `Status:` field; do NOT propose moving entries to a separate section.
- BD-161 Resolved line MUST cite BD-167 absorption per integration parent §17.2 + §8.14 + Addendum #1 §6.4 BD table.

**Architect-doc planner-deferred items:** none — this is mechanical status flipping per established pack convention.


---

## §6 — PM-only edit specifications (Pack Chat applies — separate from per-commit work)

The PM-only files BELOW must be edited BY PACK CHAT before / during /
after Batch 19. These edits are SEPARATE from the per-commit work in
§5; they are listed here so Pack Chat sees the full PM-only edit
inventory in one place.

The per-commit specs in §5 already include the PM-only edits that
land WITHIN a Batch-19 commit (19b-PM, 19g-PM, 19h). This §6 section
covers the PM-only edits that land OUTSIDE the per-commit sequence:
BACKLOG.md BD-creation entries (must exist as `Status: Open` BEFORE
19a fires); EXECUTION-PLAN-V11.0.md row insertion + line edits;
RELEASE-GATE.md line edits; BD-138 / BD-136 in-line text
backstamp edits per Addendum #1 §2.5 + Pack-Chat-direct R-8 resolution.

### §6.1 — BACKLOG.md: 9 new BD entries + BD-160 amendment (Pack Chat applies before Batch 19 fires)

The 9 NEW BD entries (BD-164..BD-170 + BD-167b + BD-169b) must exist
in BACKLOG.md as `Status: Open` BEFORE the first Batch 19 commit (19a)
fires. They flip to `Status: Resolved` in commit 19h per §5.10. Entry
text drafted from Addendum #1 §6.2 / §6.3 / §6.4 (BD table) +
Addendum #2 §1.3 (Codex `.toml` paths) + Addendum #2 §2 (HTML-only
Layer 2) + Addendum #2 §4 (BD-095 bridge) + Pack-Chat-direct R-3 / R-4
resolutions.

**BD-160 (existing entry at `BACKLOG.md:1399`) — no new entry creation needed; entry stays as `Status: Open` until 19h flips it.** Per Pack-Chat-direct R-2 resolution, BD-160 ships in commit 19f combined with BD-170. Optionally Pack Chat may amend BD-160's entry in the Batch 19 setup commit (alongside BD-138 backstamp + EXECUTION-PLAN edits) to update its Unblocks/Blockers fields if any cross-references reference it (verify via grep at setup time); this is a Pack-Chat-direct decision at setup time, not a planner prescription.

**Insertion location.** Per the existing pack-side BACKLOG H2 partition
at `BACKLOG.md` (verified `## Active — v11 Scope` is the v11 active
section per `RESEARCH-PER-ENTRY-SPLIT.md` §2 lines 162–167 reference),
the 9 new BDs land under `## Active — v11 Scope`.

**BD-NNN ordering convention.** Per the pack-side `BACKLOG.md` BD-NNN
descending order (verified by `grep -nE "^\*\*BD-[0-9]+ —" BACKLOG.md`
showing recent BD-156 / BD-157 / BD-158 are at higher line numbers than
older BDs), the new BDs land at appropriate positions; planner does not
prescribe exact line numbers since BACKLOG.md ordering is by section
+ chronological/topical grouping rather than strict BD-NNN sort.

#### BD-164 entry (sample text — Pack Chat drafts final wording)

```
**BD-164 — Per-entry split implementation: decompose helper + mirror generator + _toc.md regenerator + supporting-file generators**
Type: TODO(version) — surfaced 2026-05-13 during per-entry-split integration architect pass
Status: Open
Blockers: BD-104 (rename), BD-128 (CI green), BD-131..BD-134 (tracker repairs), BD-111 (final tracker dependency surface per integration parent §17.2 + Addendum #1 §2.3)
Unblocks: BD-165, BD-166, BD-167, BD-168, BD-170
File/Symbol:
  - scripts/lib/per-entry/ (planner picks file structure / specific helper file naming per integration parent §18.1 #2 + Addendum #1 §9 qualifier)
Description: Implement per-entry decomposition helpers per ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §6.2 (mirror generator) + §5.2 (TOC regenerator) + sidecar parent §3 (decompose helper). Library helpers in scripts/lib/ per signal-6 carve-out (no new top-level scripts). Mirror generator + TOC regenerator + decompose helper share parsing logic (per sidecar §6.2). Decompose adds line-1 HTML-comment back-pointer per Addendum #1 §1.2 → reverted-to-HTML-only per Addendum #2 §2 (no body-field back-pointer). Mirror generator strips line-1 HTML-comment when emitting. Test fixtures cover round-trip identity / empty-tree / supporting-file admission per integration parent §18.2 #1.
```

#### BD-165 entry (sample text)

```
**BD-165 — _v10_to_v11_decompose_streams 6th sub-operation in v10→v11 post-dispatch hook + --force-overwrite-mirror flag (BD-095 bridge)**
Type: TODO(version) — surfaced 2026-05-13 during per-entry-split integration architect pass
Status: Open
Blockers: BD-164
Unblocks: BD-167
File/Symbol:
  - scripts/migrate-v10-to-v11.sh (post-dispatch hook 6th sub-op addition + post-report hook advisory paragraph; planner picks function name / position per integration parent §3.1 + §18.1 #4)
  - scripts/lib/migrate-v10-to-v11/decompose.sh (adapter-private helper)
  - scripts/lib/migrator-core.sh (mode-flag parser at lines 264–276 extension for --force-overwrite-mirror per Addendum #2 §4.5)
Description: Add 6th sub-op to v10→v11 migrator's post-dispatch hook (currently 5 sub-ops at lines 144–148). Constraint: MUST run AFTER all 5 existing sub-ops so the decompose step reads final v11-shape monolithic files (per integration parent §3.1 constraint statement). Bridges to BD-095 two-phase --dry-run/--apply/--resume contract per Addendum #2 §4: dry-run reports divergence informationally (exit 0); apply/resume blocks with EXIT_GATE_FAILED=31 unless --force-overwrite-mirror is passed. Post-report hook gains v11.0 decomposition advisory paragraph per integration parent §8.18 sample text (~12 lines, names rollback path).
```

#### BD-166 entry (sample text)

```
**BD-166 — init-project.sh greenfield per-entry tree install (S11 extension)**
Type: TODO(version) — surfaced 2026-05-13 during per-entry-split integration architect pass
Status: Open
Blockers: BD-164, BD-167
Unblocks: none
File/Symbol:
  - scripts/init-project.sh (stage_s11_v11_artifacts at line 803 extended; planner picks stage extension vs new stage per integration parent §8.17 + §18.1 #5; recommendation: extend S11)
Description: Extend init-project.sh greenfield path to install per-entry tree skeleton + supporting files + regenerated empty mirrors. Reads canonical templates from project-template/docs/project/<stream>/ (created by BD-167); writes to client docs/project/<stream>/. Per integration parent §8.17 + §9.3.
```

#### BD-167 entry (sample text)

```
**BD-167 — Per-entry split client artifact installs (pack-product templates + install plumbing; absorbs BD-161)**
Type: TODO(version) — surfaced 2026-05-13 during per-entry-split integration architect pass
Status: Open
Blockers: BD-164
Unblocks: BD-165, BD-166, BD-168, BD-169
File/Symbol:
  - project-template/docs/project/{backlog,implementation-plan,changelog}/_rules.md, _intro.md (canonical templates)
  - project-template/docs/project/changelog/_format.md (project changelog only)
  - scripts/migrate-v10-to-v11.sh (_v10_to_v11_install_v11_artifacts extension to install new templates + BD-161 net-new SKILL.md installs)
  - scripts/lib/tracker-agent-read.sh (_tar_read_entry_flat at line 153 extended to prefer per-entry file when tree exists; mode-aware per Addendum #1 §3.2)
  - BD-161 net-new SKILL.md installs (BD-156 / BD-157 / BD-158 + python-server-architecture / python-data-architecture / python-observability-patterns) — absorbed per integration parent §17.2 + §8.14
Description: Ship pack-product canonical templates for per-entry trees + extend migrator install step to ship them + extend tracker-agent-read.sh _tar_read_entry_flat for per-entry-prefer-mirror-fallback. Includes BD-161 absorption for client artifact install batch. Per integration parent §17.2 + Addendum #1 §6.2.
```

#### BD-167b entry (sample text)

```
**BD-167b — Per-entry split PM-only edits (trinity Key files + PACK-AGENTS.md PM-only directories list + CLAUDE.md pack-memory bullet + pack-* agent prompts × 15)**
Type: TODO(version) — surfaced 2026-05-13 during per-entry-split integration architect pass; split from BD-167 per Addendum #1 §6.2
Status: Open
Blockers: BD-167
Unblocks: none
File/Symbol (PM-only — Pack Chat applies):
  - CLAUDE.md / AGENTS.md / GEMINI.md (pack root) — Key files line addition + Pack-memory mode-aware bullet per Addendum #1 §3.4
  - project-template/CLAUDE.md / AGENTS.md / GEMINI.md — Key files / Document locations line addition
  - PACK-AGENTS.md — PM-only directories list expansion per integration parent §6.4 + Addendum #1 §3.1 honest Signal 9 trip framing
  - (STATUS.md disclaimer surface — RESOLVED per R-3 Option A: lives in BD-169 19g-pack PM-CHAT.md guidance; NOT in BD-167b)
  - .claude/agents/pack-{architect,coder,docs-researcher,planner,reviewer}.md (5 files; Markdown)
  - .codex/agents/pack-{architect,coder,docs-researcher,planner,reviewer}.toml (5 files; TOML per Addendum #2 §1 BLOCKER correction)
  - .gemini/agents/pack-{architect,coder,docs-researcher,planner,reviewer}.md (5 files; Markdown with YAML frontmatter)
Description: PM-only edits paired with BD-167 client artifact installs. Trinity rule applies for the trinity sets (pack-root × 3, project-template × 3) and pack-* agent sets (5 agents × 3 CLIs). Layer 1 + Layer 4 of the four-layer discoverability cascade per Addendum #1 §1. Honest Signal 9 trip framing per Addendum #1 §3.1.
```

#### BD-168 entry (sample text)

```
**BD-168 — validate-pack.py Check 32 (mirror-in-sync) + Check 33 (TOC-in-sync) + Check 34 (cross-reference integrity)**
Type: TODO(version) — surfaced 2026-05-13 during per-entry-split integration architect pass
Status: Open
Blockers: BD-164, BD-167
Unblocks: none
File/Symbol:
  - scripts/validate-pack.py (three new check functions + STREAMS constant; planner picks function names + STREAMS constant shape per Addendum #1 §9.1 + integration parent §18.2 #5)
  - scripts/tests/test-validate-pack-checks-32-33-34.sh (or fold into existing test surface; planner picks placement per integration parent §18.2 #6)
Description: Three new validator checks per integration parent §10. Each is a Signal 4 trip per ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md §3.2 line 285–287; THIS architect+planner pass IS the defense. Each SKIPs gracefully when per-entry tree is absent (per integration parent §10.5 backward-compat for pre-v11.0 clients). Pack-side scope only per integration parent §10.6.
```

#### BD-169 entry (sample text)

```
**BD-169 — Per-entry split pack-product wording updates**
Type: TODO(version) — surfaced 2026-05-13 during per-entry-split integration architect pass
Status: Open
Blockers: BD-167
Unblocks: none
File/Symbol (coder authors exact wording; planner-deferrals enumerated in PLAN §5.8):
  - project-template/docs/pack/PM-CHAT.md (TWO additions: file-access strategy table row addition per Addendum #2 §5.4 verbatim; STATUS.md disclaimer guidance paragraph per R-3 resolution at integration parent §5.3 disclaimer shape)
  - supporting-docs/MERGE-STRATEGY.md (one paragraph per integration parent §4.4.3)
  - supporting-docs/MIGRATION-v10-to-v11.md (~30-line section per integration parent §4.4.3 covering decomposition behavior + backup rollback + --force-overwrite-mirror semantics)
  - project-template/skills/audit-methodology/SKILL.md (audit-scope rule extension per R-4 resolution: per-entry tree files in scope under auditor-docs rule 29; regenerated mirrors out of scope when per-entry tree present; auditor agent files NOT modified — skill is authoritative source per its own §66 + per auditor.md line 11-12)
  - .claude/skills/pack-startup/SKILL.md, .codex/skills/pack-startup/SKILL.md, .gemini/commands/pack-startup.toml (one-line directive per Addendum #1 §1.3)
  - project-template/skills/pm-startup/SKILL.md (canonical) + .claude/skills/, .codex/skills/, .gemini/commands/ per-CLI mirrors (one-line directive)
Description: Pack-product wording updates for per-entry decomposition. Excludes PM-only edits (PACK-CHAT.md row + README.md Repository Layout — those land in BD-169b). Per integration parent §4.4.3 + Addendum #1 §6.3 + Pack-Chat-direct R-3 + R-4 resolutions. Auditor agent files (auditor.md / auditor.toml × 3 CLIs) are NOT modified per R-4 resolution — the audit-methodology SKILL.md is the authoritative source for audit-scope rules and the agent files delegate to the skill.
```

#### BD-169b entry (sample text)

```
**BD-169b — Per-entry split PM-only wording updates (PACK-CHAT.md row + README.md Repository Layout entries)**
Type: TODO(version) — surfaced 2026-05-13 during per-entry-split integration architect pass; split from BD-169 per Addendum #1 §6.3
Status: Open
Blockers: BD-169
Unblocks: none
File/Symbol (PM-only — Pack Chat applies):
  - PACK-CHAT.md (file-access strategy table row addition at lines 38–47 per Addendum #2 §5.2 verbatim)
  - README.md Repository Layout entries naming pack-side /backlog/, /changelog/ + project-template-side docs/project/{backlog,implementation-plan,changelog}/ per integration parent §4.4.3 + Addendum #1 §6.3
Description: PM-only wording updates for per-entry decomposition; paired with BD-169 pack-product wording.
```

#### BD-170 entry (sample text)

```
**BD-170 — Pre-decomposed v11-realistic-ot fixture per-entry tree extension**
Type: TODO(version) — surfaced 2026-05-13 during per-entry-split integration architect pass
Status: Open
Blockers: BD-164 (BD-160 blocker satisfied trivially — BD-160 ships in the same commit as BD-170 per Pack-Chat-direct R-2 resolution)
Unblocks: BD-102 dog-food (Batch 23 per Addendum #1 §2.2 renumber cascade — was Batch 22)
File/Symbol (combined with BD-160 in commit 19f per R-2 resolution):
  - test-fixtures/build.sh (_build_realistic_for_version v11 case dispatch per BD-160 + extension to call decompose helper per integration parent §12.1; coder picks fixture-generator function structure per Addendum #1 §9.1)
  - test-fixtures/manifest.txt (regeneration per integration parent §12.4)
  - test-fixtures/README.md (table row for v11-realistic-ot per BD-160 spec)
Description: Combined commit shipping BD-160 (v11 case dispatch + C2/C3 customization re-verification on v11 surface) + BD-170 (per-entry tree extension + round-trip test) per Pack-Chat-direct R-2 resolution. Both BDs are v11-realistic-ot fixture surface work and share the same dependency on BD-164 helpers; combining them avoids artificial separation. Per integration parent §12.1 + §8.7 + Addendum #1 §6.4 BD table.
```


### §6.2 — EXECUTION-PLAN-V11.0.md edits (Pack Chat applies before Batch 19 fires)

Per Addendum #1 §2 BLOCKER (renumber cascade) + Addendum #2 §3
(line 282 totals correction). Pack Chat applies these edits as a
single PM-only commit BEFORE Batch 19 fires (so the in-flight batch
references resolve to current line numbers).

**Edit 1 — Insert NEW Batch 19 row** between current Batch 18 (BD-111) and current Batch 19 (BD-105 ∥ BD-103) per Addendum #1 §2.4 row text:

```
| **19** | sequential pack-coder + Pack Chat (mixed) | per-entry split (mandatory v11.0): BD-164 → BD-167 → BD-167b → BD-165 → BD-166 → BD-168 → BD-170 → BD-169 → BD-169b → status-flips | scripts/lib/per-entry/* helpers + scripts/migrate-v10-to-v11.sh post-dispatch hook 6th sub-op + scripts/init-project.sh stage extension + scripts/validate-pack.py Checks 32+33+34 + project-template/docs/project/<stream>/ canonical templates × 5 streams + pack-* agent prompt edits + trinity Key files line additions (PM-only) + STATUS.md disclaimer (PM-only) + PACK-AGENTS.md PM-only directories list expansion (PM-only) + READ-site wording updates | After Batch 18 (BD-111 dependency-API switch — final tracker surface dependency); BD-161 absorbed into BD-167. 10 commits. Mixed mode: pack-coder commits 19a/19c/19d/19e/19f/19g + Pack Chat direct commits 19b-PM/19g-PM/19h. |
```

**Edit 2 — Renumber existing Batches 19+ up by one** per Addendum #1 §2.2:

| Current label | New label |
|---|---|
| Batch 19 (BD-105 ∥ BD-103) | Batch 20 |
| Batch 20 (BD-109 ∥ BD-110) | Batch 21 |
| Batch 20b (BD-136 4-sub-commit) | Batch 21b |
| Batch 21 (BD-100 final audit) | Batch 22 |
| Batch 21b (conditional fix) | Batch 22b |
| Batch 22 (BD-102 dog-food) | Batch 23 |
| Batch 22b (conditional fix) | Batch 23b |
| Batch 23 (BD-093 release pin) | Batch 24 |

**Edit 3 — Line edits per Addendum #1 §2.4 + Addendum #2 §3:**

| Line | Current text (verbatim from EXECUTION-PLAN-V11.0.md verified by `sed -n`) | New text |
|---|---|---|
| 277 (current `Batch 21b`) | "**21b** \| (conditional in-session fix commit if needed — no BD)" | RENAME to `**22b**` |
| 278 (current `Batch 22`) | "**22** \| sequential pack-coder + manual \| BD-102 dog-food migration" | RENAME to `**23**` |
| 279 (current `Batch 22b`) | "**22b** \| (conditional in-session fix commit if needed — no BD)" | RENAME to `**23b**` |
| 280 (current `Batch 23`) | "**23** \| direct (Pack Chat) \| BD-093 v11.0 release pin" | RENAME to `**24**` |
| 282 (totals line) | "**Total: 25 main batches (23 + Batch 5b for BD-135 + Batch 20b for BD-136 implementation) + up to 3 conditional in-session fix commits if audits/dog-food surface defects = max 28 commits, plus Batch 20b internally ships 4 commits, putting practical max at ~31 commits.** Could be slightly higher if any audit / dog-food gate needs more than one small follow-up commit." | **REPLACED VERBATIM per Addendum #2 §3.3:** "**Total: 26 main batches (24 + Batch 5b for BD-135 + Batch 21b for BD-136 implementation) + up to 3 conditional in-session fix commits if audits/dog-food surface defects = max 29 commits, plus Batch 21b internally ships 4 commits AND Batch 19 ships 10 commits internally per the per-entry split BD-split per ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §17.3 + ADDENDUM §6.5, putting practical max at ~41 commits.** Could be slightly higher if any audit / dog-food gate needs more than one small follow-up commit." (Note: the ~31→~41 commit-count shift drives the lockstep edits to Addendum #1 §0.2 / §6.6 / §11.3 — those Pack-Chat-direct edits are ALREADY APPLIED per Addendum #2 §3.4 cascade.) |
| 295 | "Push to `v11-dev` only. Never push to `main` from this chat. v11.0 ships via deliberate handoff at Batch 23." | "...deliberate handoff at Batch 24." |
| 296 | "...Treat as requiring explicit approval at Batch 23 (the only batch that creates/moves tags)." | "...approval at Batch 24..." |
| 348 | "CI `validate` job must be green before BD-102 dog-food (Batch 22)." | "(Batch 23)" |
| 349 | "CI `tests` job must be green before BD-093 release pin (Batch 23)." | "(Batch 24)" |
| (Verification gates table — verify approximate line numbers via grep) | "Final milestone audit Batch 21" | "Batch 22" |
| (Same table) | "Dog-food migration Batch 22" | "Batch 23" |
| (Same table) | "Pre-tag check Batch 23" | "Batch 24" |

**Edit 4 — Update §1 in-scope inventory** per Addendum #1 §6.7: add 9 new BDs (BD-164..BD-170 + BD-167b + BD-169b) under a new Group 5 "per-entry split (added during integration architect pass)". Bump "Total: 41 BDs in-scope" → "Total: 50 BDs in-scope".

**Edit 5 — Update §3 cleanup status** per integration parent §17.4 #4: mention the per-entry-split integration corpus (4 architect docs + 2 reviewer docs + research docs) as Pattern B sweep targets at Batch 24 (was Batch 23) release pin. Add as a new line item / bullet inside the existing §3 list (Pack Chat picks placement at edit time per §3's existing structure of bullet items).

**Edit 6 — Update §7 verification gates** per integration parent §17.4 #5: add a row for "Mirror+TOC in-sync (Check 32+33)" with "After every code-change batch in Batch 19+; before commit" + "validate-pack.py PASSED" / "Fix regenerator and re-stage".

### §6.3 — RELEASE-GATE.md edits (Pack Chat applies)

Per Addendum #1 §2.6:

| Line | Current text (verified by `sed -n '36,42p'`) | New text |
|---|---|---|
| 38 | "**separate from** the final milestone audit (Batch 21) and dog-food" | "(Batch 22) and dog-food" |
| 39 | "migration (Batch 22). Those run earlier in the release sequence" | "migration (Batch 23). Those run earlier" |

### §6.4 — BACKLOG.md amendments to BD-138 / BD-136 (Pack Chat applies)

Per Addendum #1 §2.5 — references in BD-138 (already Resolved) and BD-136 (Open) reference future batch numbers and need updates:

| BACKLOG.md line | Current text (verified by `sed -n` per Addendum #1 §2.5) | New text |
|---|---|---|
| 1595 (BD-138 Unblocks) | "downstream Batch 21 (BD-100 final audit) and Batch 22 (BD-102 dog-food)" | "downstream Batch 22 (BD-100 final audit) and Batch 23 (BD-102 dog-food)" |
| 1597 (BD-138 description, EXECUTION-PLAN amendment narrative) | "insert new **Batch 20b** for BD-136 implementation between Batch 20 (auditor agents) and Batch 21 (BD-100 final audit)" | "insert new **Batch 21b** for BD-136 implementation between Batch 21 (auditor agents) and Batch 22 (BD-100 final audit)" |
| 1597 cont'd | "Update Batch 21 (BD-100) audit scope" | "Update Batch 22 (BD-100) audit scope" |
| 1597 cont'd | "Update Batch 22 (BD-102) to specify" | "Update Batch 23 (BD-102) to specify" |
| 1599 (BD-138 description, batch description) | "Batch 20b lands BD-136 implementation" | "Batch 21b lands BD-136 implementation" |
| 1600 (BD-138 Resolved line) | "EXECUTION-PLAN-V11.0.md amended to insert Batch 20b for BD-136 implementation; Batch 21 (BD-100) and Batch 22 (BD-102) scope updated" | "EXECUTION-PLAN-V11.0.md amended to insert Batch 21b for BD-136 implementation; Batch 22 (BD-100) and Batch 23 (BD-102) scope updated" |
| 1624 (BD-136 Blockers / scheduling note) | "before Batch 22 BD-102 dog-food migration" | "before Batch 23 BD-102 dog-food migration" |

**Pack-Chat-direct R-8 resolution: BACKSTAMP.** Apply the line-edits above directly in-place, no parenthetical. Reasoning: (1) BD entries should reflect current truth — a future reader querying BD-138 wants the current Batch numbers, not "Batch 20b (now 21b)" indirection; (2) git history IS the audit trail (`git log -p BACKLOG.md` preserves the original text + the renumber commit message); (3) forward-looking fields (Unblocks / File-Symbol / Description) need backstamping anyway since they reference future work — mixing backstamp + parenthetical across fields is confusing; (4) the renumbering itself is documented in Addendum #1 §2 + the cascaded EXECUTION-PLAN edits + the renumber commit message — over-documenting in BD-138 is redundant; (5) "pack convention" claim by planner was not actually verified against precedent. Backstamp lands as part of the Batch 19 setup commit (per §9.3) alongside the EXECUTION-PLAN renumber edits.

### §6.5 — README.md Repository Layout edit (already covered in §5.9 BD-169b)

Per integration parent §4.4.3. README.md edit lands in 19g-PM
(BD-169b) per §5.9 above — not separately enumerated here.

### §6.6 — STATUS.md disclaimer edit (Pack-Chat-direct R-3 resolution: Option A)

Per integration parent §5.3. STATUS.md does NOT exist in
`project-template/` (verified). **Pack-Chat-direct R-3 resolution: Option A** — PM-CHAT.md kickoff guidance addition. Lands in 19g-pack (BD-169) as part of the PM-CHAT.md edits per §5.8 above. No new pack-product file (no STATUS_TEMPLATE.md). STATUS.md remains client-authored; the disclaimer becomes part of PM-CHAT.md kickoff procedure, surfaced to clients during PM-Chat-driven STATUS.md authoring. Option B (ship STATUS_TEMPLATE.md) was rejected to avoid creating a new pack-product file for a client-authored surface and to respect the existing client-authoring convention.


---

## §7 — Verification strategy

### §7.1 — Per-commit verification gates (summary)

| Commit | Mandatory gates | Manual checks |
|---|---|---|
| 19a | `bash scripts/tests/test-per-entry.sh` PASSES (new); `bash scripts/validate-pack.py` PASSES (31 existing checks) | Helper file structure review; divergence-warning routing review (interactive vs non-interactive split per Addendum #2 §4) |
| 19b-pack | `bash scripts/validate-pack.py` PASSES (31 existing); existing test surface PASSES | Visual inspection of 8 canonical templates; visual inspection of `migrate-v10-to-v11.sh` install-step extension; visual inspection of `tracker-agent-read.sh` per-entry-prefer-mirror-fallback shim |
| 19b-PM | `bash scripts/validate-pack.py` PASSES (existing 31 checks); trinity rule check for trinity sets + pack-* agent sets; per-CLI parity preserved | Visual inspection of all 22 PM-only file edits for trinity consistency, Codex TOML well-formedness, PACK-AGENTS.md honest Signal 9 framing per Addendum #1 §3.1, CLAUDE.md pack-memory mode-aware bullet per Addendum #1 §3.4 |
| 19c | `bash scripts/test-migrator-core.sh` (existing); `bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh` (existing); `bash scripts/tests/test-migrate-v10-to-v11-gates.sh` (existing); `bash scripts/validate-pack.py` PASSES; new manual integration tests per §5.4 | Manual: dry-run reports decompose; apply produces per-entry trees; apply with hand-edit blocks; apply with hand-edit + `--force-overwrite-mirror` proceeds |
| 19d | `bash scripts/test-init-project.sh` PASSES; `bash scripts/validate-pack.py` PASSES | Manual: greenfield init produces correct per-entry tree skeleton + regenerated empty mirrors |
| 19e | `bash scripts/validate-pack.py` PASSES (31 existing + 3 new = 34 total; new checks SKIP on pack-self per integration parent §10.5); new test runner PASSES against synthetic fixtures | Manual: STREAMS constant matches 5 stream tuples; Check 32 pre-checks fold supplementary checks per integration parent §10.4; Check 34 SKIPs v8 archive |
| 19f | `bash test-fixtures/build.sh --all --clean` succeeds; `bash scripts/validate-pack.py` PASSES; `bash scripts/test-persona-contracts.sh` PASSES | Manual: byte-identity round-trip on v11-realistic-ot per integration parent §12.1 |
| 19g-pack | `bash scripts/validate-pack.py` PASSES (Checks 21 + 28 per-CLI parity); trinity rule check for skill mirrors and auditor mirrors | Visual inspection of MIGRATION-v10-to-v11.md new section against integration parent §9.4 + Addendum #2 §4; visual inspection of PM-CHAT.md row text against Addendum #2 §5.4 verbatim |
| 19g-PM | `bash scripts/validate-pack.py` PASSES | Visual inspection of PACK-CHAT.md row text against Addendum #2 §5.2 verbatim; visual inspection of README.md Repository Layout entries |
| 19h | `bash scripts/validate-pack.py` PASSES (full 31 + 3 = 34); all previous gates PASSED (regression catch) | Visual inspection of all 10 BD entries' Resolved-line text |

### §7.2 — Trinity rule byte-equivalence checks

The Batch 19 commits touch the following trinity sets:

| Trinity set | Files | Verification |
|---|---|---|
| Pack-root trinity | `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` (pack root) | 19b-PM: parallel edits to all three for Key files line + pack-memory bullet. Verification: `diff` or visual inspection — substantive content identical, modulo provably tool-specific tweaks. |
| Project-template trinity | `project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md` | 19b-PM: parallel edits for Key files / Document locations line. |
| Pack-* agent trinity (Claude) | 5 files in `.claude/agents/pack-*.md` | 19b-PM: same `_rules.md` reference addition in each. Format: Markdown bullet. |
| Pack-* agent trinity (Codex) | 5 files in `.codex/agents/pack-*.toml` | 19b-PM: same substantive addition inside `prompt = """..."""` TOML string. Per Addendum #2 §1.4. |
| Pack-* agent trinity (Gemini) | 5 files in `.gemini/agents/pack-*.md` | 19b-PM: same `_rules.md` reference addition (Markdown with YAML frontmatter). |
| ~~Auditor agent trinity~~ | (`project-template/.claude/agents/auditor.md`, `.codex/agents/auditor.toml`, `.gemini/agents/auditor.md`) | **NOT a Batch 19 trinity set per R-4 resolution.** Auditor agent files are NOT modified in 19g-pack. Audit-methodology SKILL.md (single canonical at `project-template/skills/audit-methodology/SKILL.md`) is the only file modified for the audit-scope extension; per-CLI fanout to `.claude/skills/`, `.codex/skills/`, `.gemini/skills/` happens at install time via init-project.sh `stage_s4_skills`. Addendum #2 §1.5 Finding 2A correction (auditor `.codex` extension is `.toml`, not `.md`) is preserved as a precedent rule for any FUTURE auditor agent file edit (none in Batch 19). |
| Pack-startup skill trinity | `.claude/skills/pack-startup/SKILL.md`, `.codex/skills/pack-startup/SKILL.md`, `.gemini/commands/pack-startup.toml` | 19g-pack: same directive line addition; Codex SKILL is `.md` (Addendum #2 §6.6); Gemini command is `.toml`. |
| Pm-startup skill quad | `project-template/skills/pm-startup/SKILL.md` (canonical) + `.claude/skills/`, `.codex/skills/`, `.gemini/commands/` per-CLI mirrors (4 files total) | 19g-pack: same directive line addition. Verification: per-CLI parity maintained (Check 28 in `validate-pack.py` per BD-126). |

**Trinity verification commands:**
- For pack-root: `diff <(grep -A1 "Key files" CLAUDE.md) <(grep -A1 "Key files" AGENTS.md)` (sample shape).
- For per-CLI parity: `bash scripts/validate-pack.py | grep -E "Check 21|Check 28"` should report PASS.
- Specifically for pack-* agent trinity (Claude vs Gemini): `diff .claude/agents/pack-architect.md .gemini/agents/pack-architect.md` should show only YAML frontmatter / format differences (not substantive content drift).

### §7.3 — Byte-additive entry-content invariant test

Per sidecar parent §3.1 + Addendum #2 §2.1: the per-entry file
content from `**BD-NNN —` through the last narrative line MUST be
byte-identical to the corresponding span in the legacy monolithic
`BACKLOG.md`. The line-1 HTML-comment back-pointer (added by
decompose, stripped by mirror generator) lives ABOVE the byte-identical
span and does NOT violate the invariant.

**Test method (per integration parent §8.4 round-trip verification):**
1. Take the legacy monolithic `BACKLOG.md` (or any client mirror).
2. Run decompose helper: `mirror → per-entry tree`.
3. For each per-entry file: `tail +2 BD-NNN.md` (skip line 1 HTML comment) and compare against the corresponding span in the original mirror — must be byte-identical.
4. Run mirror generator: `per-entry tree → mirror'`.
5. Compare `mirror == mirror'` byte-for-byte. Must be byte-identical.

This test lives in 19a's test suite (`scripts/tests/test-per-entry.sh`).
The fixture builder (19f) ALSO runs this test on the v11-realistic-ot
build per integration parent §12.1.

### §7.4 — Cross-reference integrity test (Check 34 invocation)

After 19e lands, Check 34 fires automatically in CI. Manual
verification: `python3 scripts/validate-pack.py | grep "Check 34"`
should report PASS or SKIP (SKIP if pack-self trees absent — the
case until Batch 23).

### §7.5 — End-to-end Batch 19 verification (after 19h lands)

After 19h lands and Pack Chat pushes Batch 19, the CI run on push
should:
- All 34 validate-pack checks PASS (Checks 32 / 33 / 34 SKIP on pack-self because trees don't exist yet — Batch 23 will create them).
- All existing test runners PASS (no regressions).
- Pack-CI tests job PASS.
- No new advisory paragraphs / no new disposition tokens / no migrator-framework contract changes (per integration parent §13.4 + Addendum #1 §6.4 — Signal 8 conditional trip already accepted; Item 4 BD-095 bridge composes onto existing surface).

### §7.6 — Batch 23 (BD-102 dog-food, was Batch 22) verification of Batch 19

When Batch 23 fires (Pack Chat runs `bash scripts/migrate-v10-to-v11.sh` against pack-self clone), the migration produces:
- Pack-self `/backlog/BD-NNN.md` files for every existing BD entry.
- Pack-self `/changelog/vN.M.md` files for every existing version block.
- Regenerated `BACKLOG.md` mirror byte-identical to pre-migration `BACKLOG.md`.
- Regenerated `CHANGELOG.md` mirror byte-identical.
- `_intro.md`, `_rules.md`, `_v8-resolved-archive.md` per integration parent §9.7 extracted content.

After Batch 23, `bash scripts/validate-pack.py` runs Checks 32 / 33 / 34 against pack-self trees (no longer SKIP). All three should PASS.


---

## §8 — Cross-doc consistency check (planner-flagged)

Per planner-prompt success criterion #4: scan the four architect
docs for any remaining contradictions or unclear specifications
that would block coder execution. Surface every ambiguity.

### §8.1 — Resolved by addendum supersession (no action needed)

The four architect docs have a documented supersession order. Where
they disagree, the resolution is mechanical:

| Topic | Sidecar parent | Integration parent | Addendum #1 | Addendum #2 | Plan applies |
|---|---|---|---|---|---|
| Pack-side per-entry-tree paths | `/.backlog/`, `/.changelog/` | `/.backlog/`, `/.changelog/` | `/backlog/`, `/changelog/` (REDESIGN-CORE #2) | `/backlog/`, `/changelog/` | `/backlog/`, `/changelog/` |
| Layer 2 of discoverability | HTML-comment line 1 only | HTML-comment line 1 only | HTML + body-field `Stream contract:` | HTML-comment line 1 only (body-field DROPPED — sidecar invariant violated) | HTML-comment line 1 only |
| Codex pack-* agent file extension | (not specified) | `.codex/agents/pack-*.md` | `.codex/agents/pack-*.md` | `.codex/agents/pack-*.toml` (verify-by-`ls`) | `.codex/agents/pack-*.toml` |
| Auditor codex extension | (not specified) | `auditor.md` | `auditor.md` | `auditor.toml` (sweep finding 2A) | `auditor.toml` |
| Regenerator divergence in apply/resume | After-every-write semantics | Commit-time semantics + interactive-prompt + non-interactive stderr-warn | Same | Apply/resume BLOCKS unless `--force-overwrite-mirror` (BD-095 bridge) | BLOCKS unless `--force-overwrite-mirror` |
| EXECUTION-PLAN line 282 totals | (sidecar-agnostic) | (n/a) | "26 main batches (24 + Batch 5b + Batch 21b + Batch 19 = 27 total)" — arithmetic broken | "26 main batches (24 + Batch 5b + Batch 21b)" verbatim, max ~41 commits | Per Addendum #2 §3.3 verbatim |
| PACK-CHAT.md row text | (n/a) | "deferred to Pack Chat" | "deferred to Pack Chat" | Verbatim 2-row spec per §5.2 | Per Addendum #2 §5.2 verbatim |
| PM-CHAT.md row text (project-template) | (n/a) | (mentioned not specified) | (deferred) | Verbatim 2-row spec per §5.4 | Per Addendum #2 §5.4 verbatim |
| Total v11.0 commit count | (n/a) | max ~38 | max ~40 (Addendum #1 §6.6 / §11.3 / §0.2) | max ~41 (corrected per §3.3; Pack-Chat-direct lockstep edits to Addendum #1 already applied) | max ~41 |
| `_intro.md` lifecycle | Tracker-touched (sidecar §3.4 silent) | Pack-shipped immutable (Friction 3 resolution) | Same | (unchanged) | Pack-shipped immutable |
| `_stage_backup` location citation | (sidecar §5.r incorrect: `migrator-core.sh:146`) | Corrected: `migrator-stages.sh:146` (Friction 2) | (unchanged) | (unchanged) | `migrator-stages.sh:146` |
| Hook-sequencing 6-item list (sidecar §1.3) | Hard-orders 6 sub-ops literally | Downgraded to constraint statement (Friction 1) | (unchanged) | (unchanged) | Constraint statement; planner picks position |
| PACK-AGENTS.md framing | (n/a) | "refactor not expansion" | "honest Signal 9 trip" (Item 3) | (unchanged) | "honest Signal 9 trip" |
| CLAUDE.md pack-memory bullet | (n/a) | Mode-unaware text | Mode-aware text (Item 3 §3.4) | (unchanged) | Mode-aware text per Addendum #1 §3.4 |
| Mode-2 → Mode-3 transition | Option A recommended | "Option A is required" (strengthening) | (unchanged) | (unchanged) | Option A required |
| `stream-discovery` skill | (sidecar-agnostic) | New skill (§4.2 Layer 3) | DROPPED — replaced by directives in pack-startup + pm-startup (Item 1 §1.3) | (unchanged) | One-line directives in existing skills; no new skill |
| Body-field back-pointer | (sidecar §3.1 invariant prohibits) | (n/a) | Adds `Stream contract:` body field (§1.2) | DROPPED entirely (Item 2 — sidecar invariant violated) | No body field; HTML comment only |
| Total BDs in scope (Batch 19) | (n/a) | 7 new + BD-161 absorbed = 8 entries | 9 new + BD-161 absorbed = 10 entries (BD-167 split, BD-169 split) | (unchanged) | 9 new + BD-161 = 10 BDs |
| Total commits in Batch 19 | (n/a) | 8 | 10 (Item 6) | (unchanged) | 10 commits |

All conflicts above are resolved by Addendum #2 supersession +
Addendum #1 supersession. The plan applies the deepest-supersession
text in each case. **No conflicts requiring user / Pack-Chat resolution beyond Risks in §10.**

### §8.2 — Items the architect docs leave to the planner (already noted in §5)

Per integration parent §18 + Addendum #1 §9 ("planner picks file structure" qualifier):
- Helper file structure under `scripts/lib/per-entry/` (single file vs sub-directory; see §5.1).
- Function names for the helpers (see §5.1 + §5.4).
- Adapter-private decompose helper location (recommended `scripts/lib/migrate-v10-to-v11/decompose.sh`; see §5.4).
- `init-project.sh` stage extension vs new stage (recommended extend S11; see §5.5).
- Sequencing of the 6 sub-operations within `migrator_post_dispatch_hook` (constraint: decompose runs LAST; see §5.4).
- Validator function names + STREAMS constant tuple shape (see §5.6).
- Test fixture placement for Check 32/33/34 (see §5.6).
- Fixture-generator function structure (see §5.7).
- Exact wording of trinity Key files line / pack-memory bullet / PACK-AGENTS.md directory list (see §5.3).
- Exact MIGRATION-v10-to-v11.md section wording / MERGE-STRATEGY.md paragraph wording (see §5.8).
- README.md Repository Layout exact placement (see §5.9).

These are NOT ambiguities — they are explicit planner-pass deferrals
from the architect docs. The plan names each one in the affected
§5 commit spec.

### §8.3 — Items the architect docs surface but DO NOT resolve (genuine ambiguities — see §10 Risks)

- **STATUS.md disclaimer surfacing routing.** Integration parent §5.3 surfaces the requirement; Addendum #1 §6.2 BD-167b lists it as "the project-template-side `STATUS.md` if it ships; otherwise surfaced for client-side STATUS.md only per the client-tooling boundary." Plan finding (verify-by-`ls`): STATUS.md does NOT exist in `project-template/`. Pack Chat must ratify routing. **See §10 Risk R-3.**
- **Phase-task decomposition unit for project implementation-plan stream.** Sidecar §3.4 admits per-task files; Addendum (§2) locks "one file per phase, tasks inline"; Addendum #1 §6.4 BD-167 spec uses "phase-N.md per-phase files (no per-task files per addendum §2)". Plan applies addendum decision. **No ambiguity — addendum supersedes sidecar; documented in §5.2.**
- **Audit-methodology skill extension.** Addendum #1 §7.4 says "the planner should verify whether the skill file itself needs the extension or whether the auditor agent files (which load the skill) cover it. Planner-final." Plan defers to coder-pass during 19g-pack drafting. **See §10 Risk R-4.**
- **EXECUTION-PLAN-V11.0.md gates table line numbers.** Addendum #1 §2.4 lists lines 400/401/402 for the gates table edits but the verification by `sed -n` was not done by the architect doc (the gates table line numbers may have drifted). Plan defers to Pack Chat's PM-only edit step (§6.2 Edit 3 final entries). **See §10 Risk R-5.**
- **`init-project.sh` stage extension exact behavior** when the canonical templates don't exist in the source tree (e.g., if 19b-pack hasn't run before 19d). Plan §5.5 implies hard dependency; planner should verify the failure mode is graceful. **See §10 Risk R-6.**
- **Whether the post-report hook advisory paragraph (per integration parent §8.18) constitutes a "new advisory file" per maintainability signal 8** — sidecar §13.4 acknowledged this as conditionally tripped. Plan defers to architect-pass discipline (THIS architect+planner pass IS the defense per integration parent §13.4 + Addendum #1 §6.4). **No ambiguity — design-time decision already made.**

### §8.4 — Items I would have liked clarity on but the docs are silent

- **`_v8-resolved-archive.md` initial content extraction** for the v10→v11 migration: integration parent §9.7 says "the decompose step reads the source `BACKLOG.md` from the `## Resolved — v8 (March 2026)` H2 line through the next H2 (or EOF) and writes it to `_v8-resolved-archive.md`." But for client repos that do NOT have a `## Resolved — v8` H2 (i.e., greenfield project-template clients with no v8 history), what does the decompose step do? Plan inference: the v8 archive is pack-self only; project-side BACKLOG.md has no v8 archive section per integration parent §11.2 surface count table. The decompose step produces an EMPTY `_v8-resolved-archive.md` (or skips it entirely) for clients without the v8 H2. **See §10 Risk R-7 to confirm this inference.**
- **Trinity rule application to pack-startup directive line.** Pack-startup ships only at pack-repo root level (per Addendum #1 §7.1 fact-check; pack-startup does NOT ship in `project-template/`). The directive line addition lands in 3 files at pack root (`.claude/skills/pack-startup/SKILL.md`, `.codex/skills/pack-startup/SKILL.md`, `.gemini/commands/pack-startup.toml`). The trinity rule applies to the substantive content of these 3 files. The plan applies this in §5.8.


---

## §9 — Sequencing summary + approval gates

### §9.1 — Sequencing within Batch 19 (10 commits, in order)

```
1. 19a (BD-164) ── pack-coder ── helpers + tests in scripts/lib/per-entry/
   ↓
2. 19b-pack (BD-167) ── pack-coder ── canonical templates (project-template/docs/project/) + install plumbing extension + tracker-agent-read.sh extension + BD-161 absorption
   ↓
3. 19b-PM (BD-167b) ── Pack Chat direct ── trinity Key files × 6 + PACK-AGENTS.md + STATUS.md disclaimer routing (per Risk R-3) + CLAUDE.md pack-memory bullet (trinity) + pack-* agent prompts × 15
   ↓
4. 19c (BD-165) ── pack-coder ── migrator post-dispatch 6th sub-op + --force-overwrite-mirror flag + post-report advisory paragraph
   ↓
5. 19d (BD-166) ── pack-coder ── init-project.sh greenfield install (S11 extension)
   ↓
6. 19e (BD-168) ── pack-coder ── validator Checks 32/33/34 + STREAMS constant + tests
   ↓
7. 19f (BD-160 + BD-170 combined per R-2) ── pack-coder ── v11-realistic-ot fixture: v11 case dispatch (BD-160) + per-entry tree extension (BD-170) + manifest regen + README row
   ↓
8. 19g-pack (BD-169) ── pack-coder ── PM-CHAT.md row + STATUS.md disclaimer guidance paragraph (per R-3) + MERGE-STRATEGY paragraph + MIGRATION-v10-to-v11 section + audit-methodology SKILL.md scope extension (per R-4; auditor agent files NOT modified) + pack-startup directives × 3 + pm-startup directives × 4
   ↓
9. 19g-PM (BD-169b) ── Pack Chat direct ── PACK-CHAT.md row (verbatim per Addendum #2 §5.2) + README.md Repository Layout entries
   ↓
10. 19h ── Pack Chat direct ── BD status flips: 9 new BDs to Resolved + BD-161 to Resolved with absorption attribution
```

### §9.2 — Approval gates per stop-before-commit protocol

Per `EXECUTION-PLAN-V11.0.md` §A.1 (verified via `sed -n '292,296p'`):
- Stop-before-each-commit: Pack Chat shows staged file list + diff stat + one-line description; waits for explicit user approval before committing.
- No `git add -A`: stage explicit files.
- No commit or push without explicit user approval, every time.

For Batch 19, the stop-before-commit gates fire 10 times (once per
commit). Pack Chat presents:
- Files to be staged.
- Diff stats.
- Verification gate evidence (test runner output, validate-pack output, manual check sign-off).
- Compliance with the per-commit constraint list (per §5.X).

User approval is required for each of the 10 commits independently.

### §9.3 — PM-only edits that land OUTSIDE the per-commit sequence (per §6)

The PM-only edits in §6.2 (EXECUTION-PLAN-V11.0.md), §6.3
(RELEASE-GATE.md), §6.4 (BACKLOG.md BD-138 / BD-136 amendments),
and §6.1 (BACKLOG.md 9 new `Status: Open` BD-creation entries)
land in a single PM-only commit BEFORE Batch 19 fires (per
Addendum #1 §2.7 cascade-summary). Pack Chat applies these edits
under stop-before-commit per §9.2.

**Suggested PM-only commit message:**
```
docs: v11 — Batch 19 setup (renumber cascade Batches 19+ → 20+; insert NEW Batch 19 row; open BD-164..BD-170 + BD-167b + BD-169b)
```

### §9.4 — Pre-Batch-19 verification

Before firing 19a, Pack Chat verifies all hard sequencing
constraints are satisfied:
- Batch 6 (BD-128) — DONE
- Batches 7–10 (BD-131..BD-134) — DONE
- Batch 12 (BD-104) — DONE
- Batch 13 (BD-095 + BD-101) — DONE; verify by `grep "BD-095\|BD-101" BACKLOG.md` showing both `Status: Resolved`.
- Batch 17 (BD-106 / BD-107 / BD-108) — DONE
- Batch 18 (BD-111) — DONE; verify by `grep "BD-111" BACKLOG.md` showing `Status: Resolved`.

Pack Chat verifies CI is green at the v11-dev branch HEAD before
firing 19a (per `EXECUTION-PLAN-V11.0.md` §F.1 validate gate).


---

## §10 — Risks and open questions (planner-flagged for Pack Chat resolution)

These are items the plan surfaces but cannot resolve at planner-pass
discipline. Pack Chat resolves before / during Batch 19 execution.

**Resolution status (post-planner Pack-Chat-direct pass, 2026-05-14):**
- **R-2 (BD-160 placement)** — RESOLVED: combine BD-160 + BD-170 into commit 19f. See §10.2.
- **R-3 (STATUS.md disclaimer routing)** — RESOLVED: Option A — PM-CHAT.md kickoff guidance addition; lands in 19g-pack. See §10.3.
- **R-4 (audit-methodology SKILL.md extension)** — RESOLVED: Option A — extend SKILL.md only; auditor agent files NOT modified. See §10.4.
- **R-8 (BD-138 batch reference updates)** — RESOLVED: BACKSTAMP. See §10.8.
- R-1, R-5, R-6, R-7, R-9, R-10, R-11, R-12, R-13 — operational mitigations specified in-line per each risk; no pre-execution decision required.

### §10.1 — Risk R-1: pack-self decompose at Batch 23 may surface late defects in Batch 19 helpers

**Description.** Batch 19 ships the helpers (BD-164) and the migrator wiring (BD-165) but does NOT exercise them on pack-self. Pack-self decompose happens at Batch 23 (BD-102 dog-food, was Batch 22). If the helpers have a subtle bug that only manifests on the pack-self size + shape (3,627-line BACKLOG.md, ~144 BD entries, the v8-archive H2 at line 2248), Batch 19 may pass CI green and Batch 23 may surface the defect.

**Mitigation.**
- 19f (BD-170) builds the v11-realistic-ot fixture which extends the v10-realistic-ot OT shape (~50 TD entries + ~12 phase files) — close in scale to the project-side surface.
- The byte-identity round-trip test (per integration parent §12.1 + §8.4) at fixture-build time provides deterministic verification.
- For pack-self size verification, Pack Chat MAY (out of scope for plan; Pack-Chat-direct optional check) run `bash scripts/migrate-v10-to-v11.sh --dry-run` against a pack-self clone in `/tmp/` after 19c lands but before Batch 23 fires. This is a manual integration check, not a Batch 19 gate. Plan recommendation: do this between 19c and 19h to surface any pack-self-specific defect early.

**Resolution path if defect surfaces at Batch 23.** Per the §B in-session fix rule (`EXECUTION-PLAN-V11.0.md` lines 298–322): Batch 22b (was Batch 21b) or Batch 23b (was Batch 22b) conditional fix slots fire if defects surface; fixes land in the same batch as Pack-Chat-approved follow-up commits; no new BDs opened.

### §10.2 — Risk R-2: BD-160 dependency may not be ready when 19f fires — **RESOLVED (Pack-Chat-direct)**

**Original description.** Per Addendum #1 §6.4 BD table: BD-170 is BLOCKED by BD-164 AND BD-160. BD-160 ("v11-realistic-ot fixture: extend `_build_realistic_for_version v11` case") per pack `BACKLOG.md:1399` may or may not have landed by the time Batch 19 fires.

**Verification.** Verified `Status: Open` for BD-160 at `BACKLOG.md:1401` (Pack-Chat-direct check 2026-05-14). BD-160 is NOT scheduled in any v11.0 batch in `EXECUTION-PLAN-V11.0.md` (Pack-Chat-direct grep returned zero matches).

**Resolution: Combine BD-160 + BD-170 into commit 19f (Option A from the formal AskUserQuestion choice set).** Both BDs are v11-realistic-ot fixture surface work — BD-160 creates the v11 case dispatch baseline; BD-170 extends it for per-entry trees. Shipping them as a single commit avoids artificial separation since both share the same dependency on BD-164 helpers. Reflected in §1.1 BD table, §0 TL;DR batch shape, §4 coder/Pack-Chat allocation, §5.7 commit 19f spec, §5.10 19h status flip list, §6.1 BD-170 entry text, §9.1 sequencing summary. Net effect: 10-commit total preserved (no Addendum #2 §3.3 ~41-count re-correction needed); 11 BD-tracked items in Batch 19 (was 10).

**Why not Option B (BD-160 as 19a-pre, 11 commits) or Option C (BD-160 as standalone batch, renumber cascade):** Option B would have required re-correcting Addendum #2 §3.3 arithmetic AND EXECUTION-PLAN-V11.0.md line 282 verbatim text (~41 → ~42); Option C would have cascaded renumbering through ALL downstream batches for one BD's worth of work. Option A keeps the numerics stable while honoring the thematic coupling.

### §10.3 — Risk R-3: STATUS.md disclaimer surfacing routing — **RESOLVED (Pack-Chat-direct: Option A)**

**Original description.** Integration parent §5.3 surfaces the disclaimer requirement; Addendum #1 §6.2 BD-167b spec lists STATUS.md disclaimer as a target file. Verify-by-`ls`: `find project-template -name "STATUS*"` returns NOTHING. `project-template/STATUS.md` does NOT ship from project-template. STATUS.md is created by the client during PM-Chat kickoff per the existing flow.

**Resolution: Option A — PM-CHAT.md kickoff guidance addition.** Lands in 19g-pack (BD-169) as part of PM-CHAT.md edits per §5.8 above. The disclaimer guidance lives in PM-CHAT.md as a kickoff-procedure paragraph: "When authoring `STATUS.md`, prepend the following HTML-comment disclaimer..." (exact wording per integration parent §5.3 disclaimer shape; coder refines voice to match existing PM-CHAT.md prose). No new pack-product file (no STATUS_TEMPLATE.md). Reflected in §5.8 commit 19g-pack spec (PM-CHAT.md modification clause), §6.1 BD-169 entry File/Symbol field, §6.6 STATUS.md disclaimer edit subsection.

**Why not Option B (ship STATUS_TEMPLATE.md):** Would have created a new pack-product file for a client-authored surface, requiring trinity-rule consideration and skill-agent maintainability principle accounting. Option A respects the existing client-authoring convention without adding pack-product surface.

### §10.4 — Risk R-4: audit-methodology SKILL.md extension — **RESOLVED (Pack-Chat-direct: Option A)**

**Original description.** Per Addendum #1 §7.4: "the planner should verify whether the skill file itself needs the extension or whether the auditor agent files (which load the skill) cover it."

**Verification.** Pack-Chat-direct grep of `audit-methodology/SKILL.md` and `project-template/.claude/agents/auditor.md` confirmed: (1) the SKILL.md File-scope-rules section (rules 25–32) is the authoritative definition of per-cluster scope; auditor-docs scope rule 29 uses `**/*.md` glob which would naively match per-entry tree files AND regenerated mirrors; (2) `auditor.md` line 11-12 explicitly says "rules in the `audit-methodology` skill — that skill is the authoritative source." Auditor agent file delegates entirely to the skill.

**Resolution: Option A — Extend audit-methodology SKILL.md only.** Add to SKILL.md File-scope-rules section: clarification that per-entry tree files (`docs/project/backlog/BD-NNN.md`, `docs/project/implementation-plan/phase-N.md`, `docs/project/changelog/YYYY-MM-DD-*.md`) are IN SCOPE under auditor-docs rule 29 (authored source-of-truth); regenerated mirrors (`BACKLOG.md` / `CHANGELOG.md` / `IMPLEMENTATION-PLAN.md`) are OUT OF SCOPE when per-entry tree present (auditing them duplicates findings). Auditor agent files (auditor.md / auditor.toml × 3 CLIs) NOT modified — the skill delegation chain is sufficient. Single canonical edit at `project-template/skills/audit-methodology/SKILL.md`; init-project.sh `stage_s4_skills` handles per-CLI fanout. Reflected in §5.8 commit 19g-pack spec (auditor agent file rows REMOVED; SKILL.md row UPGRADED from "if needed" to definite), §6.1 BD-169 entry File/Symbol field.

**Cascade consequence:** Addendum #2 §1.5 Finding 2A's auditor.toml correction stays valid as a documentation-correction note for any FUTURE references to auditor agent files in architect/plan docs, but does NOT trigger any auditor agent file edit in Batch 19 itself. Plan §1.3 supersession table row for "Codex auditor agent file extension" remains accurate as a precedent rule.

### §10.5 — Risk R-5: EXECUTION-PLAN-V11.0.md gates table line numbers may have drifted

**Description.** Addendum #1 §2.4 listed lines 400/401/402 for the gates table edits but the verification by `sed -n` was not done by the architect doc.

**Mitigation.** Pack Chat verifies the actual line numbers via `grep -nE "Final milestone audit|Dog-food migration|Pre-tag check" EXECUTION-PLAN-V11.0.md` at the §6.2 PM-only edit step.

### §10.6 — Risk R-6: init-project.sh failure mode if canonical templates absent

**Description.** §5.5 (commit 19d) implies hard dependency on 19b-pack (canonical templates exist in pack-product source). If 19b-pack regresses or rolls back, 19d fails.

**Mitigation.** The commit ordering guarantees 19b-pack lands before 19d. The §9.2 stop-before-commit gates ensure 19b-pack passes verification before 19d fires. Risk is operational (Pack Chat following the ordering), not architectural.

**Plan recommendation:** add a `[[ -d project-template/docs/project/<stream> ]]` precondition check in `stage_s11_v11_artifacts` extension — if absent, fail fast with a clear error message ("missing canonical templates; pack repo state is invalid"). Same pattern as existing init-project.sh precondition checks.

### §10.7 — Risk R-7: `_v8-resolved-archive.md` extraction for clients without v8 H2

**Description.** Integration parent §9.7 specifies the v8-archive extraction algorithm but is silent on what happens for client repos with no `## Resolved — v8` H2 in their BACKLOG.md (i.e., greenfield project-template clients with no v8 history).

**Mitigation.** The v8 archive is pack-self-only per integration parent §11.2 surface count table (`_v8-resolved-archive.md` is in pack `/backlog/` only; project-side `docs/project/backlog/` has no analog). The decompose helper for project-side stream MUST NOT attempt to extract a v8-archive (would fail or produce empty file).

**Plan recommendation:** in BD-164 (19a) helpers, the decompose helper takes the stream identity (pack-backlog vs project-backlog vs ...) as an argument; the v8-archive extraction is conditional on stream == pack-backlog. Per integration parent §3.5 + §11.2 + Addendum #1 §6.2 BD-167 File/Symbol — the `_v8-resolved-archive.md` file is in pack `/backlog/` only.

### §10.8 — Risk R-8: BD-138 backstamp vs parenthetical for renumber cascade — **RESOLVED (Pack-Chat-direct: BACKSTAMP)**

**Original description.** Per §6.4 + Addendum #1 §2.5 — BD-138 is already Resolved; the Resolved-line text references "Batch 20b" / "Batch 21" / "Batch 22" which need renumbering after Addendum #1 Item 2 cascade pushed Batches 19+ → 20+.

**Resolution: BACKSTAMP — direct in-place edits to BD-138's batch references.** Apply the §6.4 line edits in-place (Batch 20b → 21b, Batch 20 → 21, Batch 21 → 22, Batch 22 → 23) throughout BD-138's Unblocks / File-Symbol / Description / Resolved fields. No parenthetical disclaimer added.

**Reasoning.** (1) BD entries should reflect current truth — a future reader querying BD-138 wants the current Batch numbers, not "Batch 20b (now 21b)" indirection; (2) git history IS the audit trail (`git log -p BACKLOG.md` preserves the original text + the renumber commit message — Pack Chat surfaces the backstamp in the renumber-cascade commit message: e.g., `"docs: v11 — Batch 19 setup (BD-138 Resolved-line backstamped from Batch 20b/21/22 to Batch 21b/22/23 per Addendum #1 §2.2 renumber cascade; EXECUTION-PLAN renumber edits; open BD-164..BD-170 + BD-167b + BD-169b)"`); (3) forward-looking fields (Unblocks / File-Symbol / Description) need backstamping anyway since they reference future work — mixing backstamp + parenthetical across fields is confusing; (4) the renumbering itself is documented in Addendum #1 §2 + the cascaded EXECUTION-PLAN edits + the renumber commit message — over-documenting in BD-138 is redundant; (5) the original "preserves history; pack convention" claim by the planner was not actually verified against precedent. §6.4 updated to reflect backstamp resolution; the parenthetical-recommendation paragraph removed.

### §10.9 — Risk R-9: pack-* agent prompts in 19b-PM may have inconsistent existing "Inputs to read" block shapes

**Description.** The 5 pack-* agent files (per CLI; 15 total) may have varying "Inputs to read" / "Before making any design recommendation, read:" block shapes. The Addendum #1 §1.4 plan adds a `_rules.md` reference to each — but if the existing block shapes differ across the 5 agents, the addition wording must adapt.

**Mitigation.** Pack Chat reads each of the 15 files at 19b-PM drafting time and adapts the prose to match the existing block shape per agent. Trinity rule: substantive content (the `_rules.md` reference) is the same; format-specific wrapping (Markdown bullet vs Codex TOML string vs Gemini Markdown bullet) varies.

**Plan recommendation:** if any pack-* agent file does NOT have an "Inputs to read" / equivalent block, Pack Chat adds one (single-line block) for that agent. Pack Chat surfaces the gap to the user during stop-before-commit.

### §10.10 — Risk R-10: Codex TOML string escaping in 19b-PM and 19g-pack

**Description.** Per Addendum #2 §1.4: Codex agent files are `.toml` with `prompt = """..."""` triple-quoted strings. Adding new content to the `prompt` field requires no embedded triple-quote sequences. The added content (`_rules.md` reference) is plain text; no quote sequences. Low risk but worth verifying.

**Mitigation.** Pack Chat applies the edit; manually verifies the resulting `.toml` parses correctly. A `python3 -c "import tomllib; tomllib.load(open('.codex/agents/pack-architect.toml', 'rb'))"` check would be authoritative (planner recommends adding a one-shot validation at stop-before-commit).

### §10.11 — Risk R-11: trinity rule symmetry breakage if Codex TOML format forces semantic divergence

**Description.** Per CLAUDE.md trinity rule: substantive content is identical across CLAUDE / AGENTS / GEMINI; tool-specific tweaks are allowed. Codex `.toml` adds a `prompt = """..."""` wrapper; the prose inside is identical to the Markdown prose in `.claude/` and `.gemini/`. This is the standard trinity pattern (per existing pack-* agents — per `ls -la .codex/agents/` confirms `.toml` extension and content size compatible with Markdown content).

**Mitigation.** Pack Chat verifies trinity symmetry per §7.2 trinity rule byte-equivalence checks.

### §10.12 — Risk R-12: scope creep into client-side workflow

**Description.** The plan ships pack-product canonical templates that ship into client projects via init-project.sh / migrate-v10-to-v11.sh. Client-side workflows (PM-Chat sessions, project agents) inherit the per-entry trees per the integration parent §11 surface count table. If client-side workflows have unanticipated dependencies on the monolithic-as-source-truth shape, Batch 19's lock-in could break them.

**Mitigation.** The mirror generator preserves byte-identical mirrors (per integration parent §6.1 mirror-not-replace). Existing read sites continue to read the same file path — no wording change required for decomposition to work (per integration parent §6.3). The new behaviors (per-entry-direct-read capability) are OPT-IN, not required for backward-compatibility. Per integration parent §10.5 + the mode-aware shim in `_tar_read_entry_flat` (per §5.2 BD-167), pre-v11.0 client repos continue to work with the regenerated mirror.

**Plan recommendation:** during BD-167 / BD-166 implementation, the coder verifies that the v11.0-shape regenerated mirror is byte-identical to the v10.1-shape monolithic source via the round-trip test (per §7.3). If any drift is detected, pause and re-architect.

### §10.13 — Risk R-13: trinity-mirror line-number drift in `auditor.md` references

**Description.** Per Addendum #2 §1.5 Finding 2C: bare `auditor.md:42` line references in the original integration architect doc are Claude-side and correct as-is, but per-CLI mirrors may have different line numbers (mirrors are regenerated; line numbers may drift). The plan §5.8 lists auditor agent file edits without prescribing specific line numbers.

**Mitigation.** Coder pass at 19g-pack drafting time identifies the equivalent location in each mirror (Codex TOML and Gemini Markdown) and applies the audit-scope extension at the equivalent location. Trinity rule applies to substantive content, not to line numbers.


---

## §11 — Final-line marker + verify-by-`ls` evidence summary

### §11.1 — Verify-by-`ls` evidence record

This plan's facts were verified against the file system before write.
The verification commands (verbatim from terminal) and their results:

```
$ ls /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.codex/agents/
pack-architect.toml  pack-coder.toml  pack-docs-researcher.toml
pack-planner.toml    pack-reviewer.toml
   → 5 Codex pack-* agent files are .toml (Addendum #2 §1 BLOCKER confirmed)

$ ls /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.claude/agents/
pack-architect.md  pack-coder.md  pack-docs-researcher.md
pack-planner.md    pack-reviewer.md
   → 5 Claude pack-* agent files are .md

$ ls /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/.gemini/agents/
pack-architect.md  pack-coder.md  pack-docs-researcher.md
pack-planner.md    pack-reviewer.md
   → 5 Gemini pack-* agent files are .md

$ find /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/docs -type d
project-template/docs
project-template/docs/pack
project-template/docs/pack/prompts
   → project-template/docs/project/ does NOT exist (will be created in 19b-pack)

$ ls /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/.codex/agents/
architect.toml  auditor.toml  auditor-architecture.toml  auditor-code.toml
auditor-docs.toml  auditor-ops.toml  auditor-security.toml  auditor-tests.toml
auditor-ui.toml  coder.toml  docs-researcher.toml  grpc-schema.toml
planner.toml  repo-ops.toml  reviewer.toml  tester.toml
   → 16 project-template Codex agent files are .toml (Addendum #2 §1.5 Finding 2A/2B confirmed for auditor.toml)

$ test -f /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/skills/audit-methodology/SKILL.md && echo OK
OK   → audit-methodology skill exists in project-template/skills/

$ ls /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/migrate-v10-to-v11/
   → directory exists; subordinate decompose.sh does NOT exist (will be created in 19c)

$ grep -nE "^EXIT_|EXIT_GATE_FAILED" /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/migrator-core.sh | head -10
60:readonly EXIT_PACK_INVALID=10
61:readonly EXIT_NOT_GIT=11
62:readonly EXIT_DIRTY=12
63:readonly EXIT_NOT_BASELINE=13
64:readonly EXIT_BASELINE_MISSING=14
65:readonly EXIT_LIB_MISSING=15
66:readonly EXIT_ALREADY_MIGRATED=16
70:readonly EXIT_GATE_FAILED=31
71:readonly EXIT_INTERNAL=99
   → EXIT_GATE_FAILED=31 confirmed (Addendum #2 §4.5 + BD-101 resolution)

$ grep -n "^def check_" /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/validate-pack.py | tail -3
2304:def check_recommendation_state_schema() -> None:
2425:def check_skill_cell_consistency() -> None:
   → highest existing Check is 31 (Skill-cell consistency); new Checks 32/33/34 land in 19e

$ sed -n '38,47p' /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/PACK-CHAT.md
## File access strategy
| File | How to access | Why |
|---|---|---|
| `BACKLOG.md` | Direct read | Open BD-NNN items, current backlog state |
| `CHANGELOG.md` | Direct read (last entry only) | Current version and recent changes |
| `README.md` | Direct read (version table section) | Pack version history at a glance |
| `supporting-docs/METHODOLOGY.md` | Direct read (on demand) | Author of this file — read directly when needed |
| `project-template/docs/pack/prompts/*.md` | Direct read (on demand) | Author of this set of files — read directly when needed |
   → 3-column table structure confirmed for Addendum #2 §5.2 row addition

$ sed -n '281,283p' /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md
[full line 282 verbatim per §6.2 Edit 3 row 5 — 25 main batches, max ~31 commits]
   → confirmed for Addendum #2 §3.3 verbatim replacement

$ sed -n '36,42p' /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/RELEASE-GATE.md
[lines 38-39 reference Batch 21 / 22]
   → confirmed for §6.3 line edits

$ grep -nE '^\| \*\*[0-9]+[a-z]?\*\*' .../EXECUTION-PLAN-V11.0.md
[returns Batch 1 → Batch 23 with the rows visible in §6.2 Edit 1/2/3]
   → batch sequence confirmed; Batch 18 is BD-111 (NOT new per-entry-split per Addendum #1 §2 BLOCKER)
```

### §11.2 — Final-line marker

PLAN-PER-ENTRY-SPLIT-BATCH-19-COMPLETE: 2026-05-14 — Implementation
plan for v11.0 Batch 19 (per-entry split, mandatory non-reversible).
10 commits per Addendum #1 §6.5 ordering (19a / 19b-pack / 19b-PM /
19c / 19d / 19e / 19f / 19g-pack / 19g-PM / 19h). 9 new BDs
(BD-164..BD-170 + BD-167b + BD-169b) + BD-161 absorbed into BD-167
= 10 BD-tracked items. Mixed-mode authorship: 6 pack-coder commits
(19a / 19b-pack / 19c / 19d / 19e / 19f / 19g-pack) + 4 Pack-Chat-
direct commits (19b-PM / 19g-PM / 19h) per the agents-never-commit
rule + PM-only file scoping. Per-commit task breakdown in §5 with
verified absolute file paths, pre/post state, dependencies, and
verification gates. PM-only edit specifications surfaced for Pack
Chat in §6 (BACKLOG.md 9 new BD-creation entries + EXECUTION-PLAN
renumber cascade per Addendum #1 §2 + line 282 totals replacement
verbatim per Addendum #2 §3.3 + RELEASE-GATE.md Batch 21/22 →
Batch 22/23 line edits + BD-138/BD-136 in-line Resolved-line
clarifications). File dependency graph in §3. Verification
strategy in §7 covering trinity rule byte-equivalence + byte-additive
entry-content invariant + byte-identity round-trip tests.
Cross-doc consistency check in §8 — 16 Addendum supersession
chains all resolved by precedence (Addendum #2 > Addendum #1 >
integration parent > sidecar parent); only items requiring Pack-
Chat / user resolution are surfaced as Risks in §10. Risks and
open questions in §10 — 13 enumerated with mitigation +
recommendation per item; STATUS.md disclaimer routing (R-3) and
audit-methodology SKILL.md extension (R-4) and BD-160 status
(R-2) are the load-bearing items needing Pack-Chat ratification
before / during Batch 19 execution. Verify-by-`ls` discipline
applied (per Addendum #2 §6 PROCESS SAFEGUARD); evidence record
in §11.1. Authority precedence applied throughout: pack-side
per-entry trees use non-dot paths (`/backlog/`, `/changelog/`)
per Addendum #1 §10 REDESIGN-CORE #2; Layer 2 of discoverability
is HTML-comment line-1 only (no body-field back-pointer) per
Addendum #2 §2; Codex pack-* + auditor agents are `.toml` per
Addendum #2 §1; PACK-CHAT.md row text is verbatim per Addendum
#2 §5.2; PM-CHAT.md analog row text is verbatim per Addendum #2
§5.4; EXECUTION-PLAN line 282 totals text is verbatim per
Addendum #2 §3.3; total v11.0 commit count target is max ~41 per
Addendum #2 §3.3; regenerator divergence in apply/resume BLOCKS
unless `--force-overwrite-mirror` per Addendum #2 §4 BD-095
bridge; CLAUDE.md pack-memory bullet is mode-aware per Addendum
#1 §3.4; PACK-AGENTS.md framing is honest Signal 9 trip per
Addendum #1 §3.1. Architect-pass discipline preserved: zero
PM-only file edits authored by this plan; zero pack-product file
edits authored; zero parent-doc edits; all required PM-only edits
surfaced as edit specifications for Pack Chat. Hard sequencing
constraints respected: AFTER Batches 6, 7–10, 12, 13, 17, 18;
BEFORE Batches 22, 23, 24 (renumbered per Addendum #1 §2). Plan
ready for primary-chat reviewer evaluation.

