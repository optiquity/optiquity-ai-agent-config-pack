# PLAN — BD-175 Phase 5 implementation (per-commit sequencing)

**Owner:** pack-planner (Phase 4 of BD-175; read-only on source; output is this single doc)
**BD:** BD-175 (CODE RED — pack/project boundary remediation)
**Phase:** 4 (PLANNING — concrete commit sequencing for Phase 5 coder spawns)
**Date:** 2026-05-19
**Branch:** v11-dev
**HEAD at planning time:** `8014186` (per gitStatus on session open); two new commits landed during Phase 3 verification at `9863c06` + `b8d6b1d`
**Inputs:** see top of file front-matter in the planner-spawn prompt; primary anchors are AUDIT-USER-CURATION.md, ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md (A + A-fix), ARCHITECTURE-DIRECTORY-REORGANIZATION.md (B + B-fix + B-fix-v2), ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md (C + C-fix + C-fix-v2), PACK-REVIEW-PHASE-2-DESIGNS.md, PACK-REVIEW-PHASE-2-DESIGNS-VERIFICATION.md, PACK-AGENTS.md:142-148 (PM-only Files), scripts/validate-pack.py Check 22 area

---

## §0 — Executive summary

- **Total commit count:** 13 commits (Path A per resolved OQ-1; user decision 2026-05-19)
- **Total v11-surface commits (RC9 manifest-regen):** 7 commits (Commits 2, 3, 4, 5, 6, 10, 11, 12 — wait, that's 8; let me recount). Per §4.2: Commit 1 N, Commit 2 Y, Commit 3 Y, Commit 4 Y, Commit 5 Y, Commit 6 Y, Commit 7 N (supporting-docs), Commit 8 N (supporting-docs), Commit 9a N (pack-ops/), Commit 9b N (pack-ops/), Commit 10 Y, Commit 11 Y, Commit 12 Y = **8 v11-surface commits**. Commit 1 may run `--all --clean` and confirm zero diff per RC9 inclusive trigger but is not required to stage.
- **Combined commit named (per M1 Option A mandatory):** Commit 2 — "feat: v11 — BD-175 directory reorg M1-M5 + M9-M10 (root → pack-ops/)" — folds B's M1-M5 + B-fix's M9-M10 + the `detect_pack_surface` update + all script constant updates + pack trinity + pack-* agents + pack-startup skill + README repo-layout + manifest regen in ONE atomic landing per B-fix §7.1 Option A
- **Sequencing constraints (load-bearing):**
  - Commit 1 MUST land before Commit 2 (the `pack-ops/` directory must exist before `git mv root → pack-ops/`)
  - Commit 2 is structurally inviolable (M1-M5 + M9-M10 in ONE commit per M1 finding + B-fix §7.1)
  - Commit 3 (M6-M8 supporting-docs → pack-ops/) MUST land after Commit 2 to avoid `pack-ops/` ambiguity windows in `detect_pack_surface` (Commit 2 establishes the dir; Commit 3 adds three more files into it)
  - Commit 4 (TASK-T1 trinity edits) MUST land after Commit 2 because TASK-T1 wording redirects from `PACK-AGENTS.md` to `docs/pack/PM-CHAT.md` § Pack agent roster (the pack-side `PACK-AGENTS.md` is gone from root after Commit 2 — Architect A's REPLACE wording is for project-side trinity readers who consume the project-side SSOT instead); Commit 4 is also a Trinity-rule commit (3 CLI files in lockstep)
  - Commits 4 (TASK-T1 trinity), 5 (TASK-T2 PLATFORM-SKILLS), 6 (TASK-T3 audit-methodology SKILL), 7 (TASK-T4 MIGRATION-v10-to-v11), 8 (TASK-T6 METHODOLOGY), 9a (TASK-T5 MERGE-STRATEGY audience header only), and 11 (Override 10 4-help-file removal) form **parallel set ALPHA-EXPANDED — 7 file-disjoint commits** that execute in CONCURRENT pack-coder spawns after Commit 3 lands. Per OQ-1 RESOLVED (user decision 2026-05-19): **Path A chosen.** Commit 9 splits into 9a (audience-header only — joins parallel set ALPHA-EXPANDED) + 9b (D8.6 ref-update only — lands sequentially after Commit 10). See §8.2 for the parallel-set orchestration pattern, §8.5 for OQ-1 close-out, §8.7 for the git-stash isolation pattern, §8.6 for push-then-wait CI cascade pattern. Estimated 30-90 min coder-phase wall-clock savings vs fully-sequential
  - Commit 10 (TASK-T8 OPTIONAL-FEATURES SPLIT — `init-project.sh` install stage + project-side file create) lands after parallel set ALPHA-EXPANDED completes (sequential tail begins). Pack-side `pack-ops/OPTIONAL-FEATURES.md` exists post-Commit 2
  - Commit 11 (Override 10 — 4-help-file QUICKSTART-ref removal) is a Trinity-rule commit (3 CLI-parallel pack-help skill files + HELP-FRAGMENT.md cohesion); part of parallel set ALPHA-EXPANDED (file-disjoint from Commit 4's project-template trinity — different sub-trees within `project-template/`)
  - **Sequential tail under Path A: 10 → 9b → 12.** Commit 9b (TASK-T5 D8.6 ref-update only) requires project-side `project-template/docs/pack/OPTIONAL-FEATURES.md` from Commit 10. Commit 12 (Architect C prevention mechanisms — M2 P-missed-7 codification + M4 boundary-investigation skill + M3a/M3b + M6 + M7 + M1a/M1b + M5a Check 36 + M5b Check 37 + M5c Check 38 + M8 trinity doc amendment) lands LAST per C's §13 order-of-land: M5b Check 37 deny-list would fail at HEAD until all 17 §D-9 contamination refs are addressed by Commits 4-9b
- **Phase 5 estimated complexity:** ONE structural commit (Commit 2 — large diff, many files, structurally inviolable per M1) + THREE other multi-file commits (Commit 3 supporting-docs MOVE, Commit 4 trinity TASK-T1, Commit 12 prevention) + NINE smaller targeted commits (Path A split). **Coder-spawn count: 13 fresh pack-coder spawns** per pack-memory "each pack-coder commit gets a FRESH coder instance" — Path A per OQ-1 RESOLVED.
- **Chosen parallelism + orchestration (user decisions 2026-05-19; see §8):**
  - **Parallel set ALPHA-EXPANDED** — 7 file-disjoint commits (4, 5, 6, 7, 8, 9a, 11) executed via 7 concurrent pack-coder spawns after Commit 3 lands. Estimated 30-90 min coder-phase wall-clock savings; token cost unchanged (FRESH-coder rule mandates per-commit context re-read regardless of timing).
  - **CI cascade pattern: push-then-wait** for the ALPHA-EXPANDED parallel batch — Pack Chat commits each member serially, pushes, waits for CI green (`gh run list --branch v11-dev --limit 10 --json status,conclusion,headSha`), then pushes the next. Trades wall-clock for cascade-isolation safety.
  - **Manifest-regen pattern: git-stash isolation** per §8.7 — Pack Chat stashes other coders' unstaged edits before each commit's manifest regen, restores them after `git commit`. Honors RC9 per-commit contract.

---

## §1 — Commit sequence table

Order: dependency-driven. Commit 1 creates the new `pack-ops/` directory and the boundary-definition documents; Commit 2 is the structurally inviolable combined relocation (M1-M5 + M9-M10 per Option A); Commit 3 finishes supporting-docs cleanup. **Per OQ-1 RESOLVED (Path A, user decision 2026-05-19): Commits 4, 5, 6, 7, 8, 9a, 11 form parallel set ALPHA-EXPANDED (7 concurrent pack-coder spawns after Commit 3 lands).** Sequential tail: Commit 10 (TASK-T8 SPLIT — creates project-side OPTIONAL-FEATURES.md) → Commit 9b (TASK-T5 D8.6 ref-update — requires project-side file from Commit 10) → Commit 12 (Architect C prevention mechanisms, lands LAST per C §13 bootstrap order). **13 commits total.**

| # | Commit name (proposed subject) | Scope summary | Files affected (count + categories) | Manifest regen Y/N | Dependencies (commit #s) | Coder spawn |
|---|---|---|---|---|---|---|
| 1 | `feat: v11 — BD-175 pack-ops/ scaffold + BOUNDARY-DEFINITION` | Create `pack-ops/` dir; create `pack-ops/BOUNDARY-DEFINITION.md` (~250-350 lines per B's §5.3); create `pack-ops/.boundary-exempt-root.txt` with 1-entry allow-list (`tracker.toml.pack-example`) per B-fix §4 + Overrides 1 + 5 | 2 new files in new `pack-ops/` dir (zero deletions, zero modifications) | N (pure pack-only doc creation; no project-template/ or scripts/ files touched) — Pack Chat may still run `--all --clean` and confirm zero diff per RC9 inclusive trigger | none | spawn 1 |
| 2 | `feat: v11 — BD-175 directory reorg M1-M5 + M9-M10 (root → pack-ops/)` | **Combined Option A per M1 + B-fix §7.1 — STRUCTURALLY INVIOLABLE.** `git mv` 7 root files → `pack-ops/` (PACK-CHAT, PACK-AGENTS, HELP-FRAGMENT-PACK, HELP-FRAGMENT-TRACKER, OPTIONAL-FEATURES, BACKLOG, CHANGELOG); update `scripts/lib/tracker-config.sh:298` `[[ -d "$repo_root/pack-ops" ]]`; update `scripts/lib/detect.sh:35` first candidate `$target/pack-ops/BACKLOG.md`; update `scripts/validate-pack.py` STREAMS lines 191-192 + Check 3 line 319 + Check 22 surfaces dict lines 1654/1656/1659 + tracker_fragment 1669 + lines 1735-1736 + Check 24 pack-side path 1929; update `scripts/lib/per-entry/_lib.sh` lines 71+79; update `scripts/pack-help.sh` lines 33+resolution; update `scripts/lib/recommendation.sh` lines 131/151/152/393/462; update `scripts/lib/tracker-doctor.sh` lines 114-138; update `scripts/lib/tracker-agent-read.sh` lines 264+267; update `scripts/lib/tracker-migrate-reverse.sh` lines 1050/1053/1068/1078/1095/1119/1147; update `scripts/tests/test-per-entry.sh` lines 220+221 (assertion-on-canonical-output only; temp-dir fixtures unchanged); update pack-side trinity CLAUDE.md / AGENTS.md / GEMINI.md (lines 30-31 + 83 + 99 + 389); update 5 pack-* agents x 3 CLI variants (15 files: pack-architect.md/.toml/.md line 27/18/29, pack-planner line 32/18/25, pack-coder lines 34+38/21+23/36+40); update pack-startup skill x 3 CLI variants (lines 19/21/32-33); update commit-discipline + implementation-report skills x 3 CLIs (if grep hits); update post-M4 `pack-ops/PACK-AGENTS.md` bare-name sibling references at lines 143-144 (sibling-relative within `pack-ops/`); update `README.md` Repository Layout block (move BACKLOG/CHANGELOG/PACK-CHAT/PACK-AGENTS/HELP-FRAGMENT-PACK/HELP-FRAGMENT-TRACKER/OPTIONAL-FEATURES entries from root section to `pack-ops/` block); **regenerate test-fixtures/manifest.txt per RC9** | 7 git-mv'd files + ~15 scripts/lib + 1 scripts/ root + 3 pack trinity + 15 pack-* agent CLI files + 3 pack-startup CLI skills + ~6 other skill files + 1 README + manifest = ~52 files | **Y** (touches scripts/ + manifest required) | 1 | spawn 2 |
| 3 | `feat: v11 — BD-175 directory reorg M6-M8 (supporting-docs/ → pack-ops/)` | `git mv` 3 supporting-docs files → `pack-ops/` (CONCEPTUAL-REVIEW-METHODOLOGY.md per Override 6; DRY-RUN-MIGRATION.md; MERGE-STRATEGY.md); update `scripts/migrate-v10-to-v11.sh` + `scripts/dry-run-migration.sh` references; update CLAUDE.md pack-memory mention of CONCEPTUAL-REVIEW-METHODOLOGY (the trinity rule § "Repo conventions" archive-doc-vs-reality bullet mentions ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY which lives in maintenance-docs/ — unchanged; verify no CONCEPTUAL-REVIEW-METHODOLOGY trinity reference exists); update any AUDIT-*.md or PACK-REVIEW-*.md or ARCHITECTURE-*.md historical references that name `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` AS A LIVE PATH (not those that quote past state — those are frozen per B-fix §6.4); **regenerate test-fixtures/manifest.txt per RC9** | 3 git-mv'd files + 2 scripts/ + 1-3 maintenance-docs/v11-implementation/ live cross-references + manifest = ~7-9 files | **Y** (scripts/migrate-v10-to-v11.sh touched) | 2 | spawn 3 |
| 4 | `feat: v11 — BD-175 TASK-T1 trinity REPLACE + REVERT (V1 + T5-A + V8)` | **Trinity rule commit — all 3 CLI files in lockstep.** In `project-template/CLAUDE.md` + `AGENTS.md` + `GEMINI.md`: REPLACE the parenthetical at L366/343/356 (V1 + T5-A) — drop "(architect / planner / coder / reviewer / tester / auditor / docs-researcher / grpc-schema / repo-ops) — `auditor` covers the 7 variant agents; see `PACK-AGENTS.md` for the full roster" → "the corresponding agent. The full pack agent roster is at `docs/pack/PM-CHAT.md` § Pack agent roster — that section is the project-side SSOT; do not infer the roster from any other source"; REVERT (V8) — delete the italicized paragraph at L397/374/387 "*For deeper agent-by-agent comparison (e.g., when to use auditor vs. reviewer vs. docs-researcher), see `TOOL-COMPARISON.md` in the pack's `maintenance-docs/`.*"; **regenerate test-fixtures/manifest.txt per RC9** | 3 trinity files + manifest = 4 files | **Y** (project-template/ trinity touched) | 2 (depends on Commit 2 establishing `pack-ops/PACK-AGENTS.md`; project-side trinity wording redirects to project SSOT regardless, but coder verifies SSOT path resolves) | spawn 4 |
| 5 | `feat: v11 — BD-175 TASK-T2 PLATFORM-SKILLS REPLACE + REVERT (V3)` | In `project-template/docs/pack/PLATFORM-SKILLS.md`: V3.a L251 REPLACE "selection. See `PACK-AGENTS.md` in the pack repo for their use." → "selection. See `docs/pack/PM-CHAT.md` § Pack agent roster for the canonical project-side agent list."; V3.b L572 REVERT drop the `maintenance-docs/.../ARCHITECTURE-SKILL-DIMENSIONS.md` parenthetical entirely (or reduce to generic "(see pack documentation if you need the design rationale)" with NO path); full-grep verify no other PACK-AGENTS.md / maintenance-docs/ refs remain in PLATFORM-SKILLS.md; **regenerate test-fixtures/manifest.txt per RC9** | 1 file + manifest = 2 files | **Y** | 3 (no cross-dependency on Commit 4; can land in any order after Commit 3) | spawn 5 |
| 6 | `feat: v11 — BD-175 TASK-T3 audit-methodology REVERT (V7)` | In `project-template/skills/audit-methodology/SKILL.md`: V7 L51 + L106 REVERT — drop both `RESEARCH-NON-APPLE-UI-SKILLS.md` references (keep "currently planned post-v11.0" deferral language); full-grep verify no other `maintenance-docs/` refs in project-template/skills/ tree; **regenerate test-fixtures/manifest.txt per RC9** | 1 file + manifest = 2 files | **Y** | 3 | spawn 6 |
| 7 | `feat: v11 — BD-175 TASK-T4 MIGRATION-v10-to-v11 REPLACE + REVERT (V6)` | In `supporting-docs/MIGRATION-v10-to-v11.md`: V6.a L35 tighten phrasing or leave (LOW); V6.b L516 REPLACE "Run a Pack Chat session: `/pm-startup`..." → "Open a PM Chat session in your client project: `/pm-startup`..."; V6.c L123 + L194 + L225 REVERT — drop "Per `maintenance-docs/.../ARCHITECTURE-SKILL-DIMENSIONS.md` §N.M," prefix from each sentence; verify file's narrative reads cleanly post-edit | 1 file (no manifest — `supporting-docs/` is not v11-surface per RC9 base case) | **N** (per RC9: `supporting-docs/` is not under `project-template/` or `scripts/`) | 3 | spawn 7 |
| 8 | `feat: v11 — BD-175 TASK-T6 METHODOLOGY REPLACE (A2)` | In `supporting-docs/METHODOLOGY.md:1509`: A2 REPLACE "*Source: maintenance-docs/origins/Claude-Assisted_Project_Methodology_Guide_v1.md*" → "*Source: Claude-Assisted Project Methodology Guide v1 (pack-archived design source)*" (drop the path; keep attribution name); full-grep verify no other `maintenance-docs/` refs in METHODOLOGY.md | 1 file (no manifest) | **N** (supporting-docs/) | 3 | spawn 8 |
| 9a | `feat: v11 — BD-175 TASK-T5 MERGE-STRATEGY audience header only (V5 PRIMARY)` | In `pack-ops/MERGE-STRATEGY.md` (post-Commit 3 location): V5 PRIMARY — add audience header amendment to L1-L20 area: "This document is pack-internal reference for pack maintainers running the migrator. Project users encounter the per-class disposition tokens via `report.md` produced by the migrator; they do not read this file directly." Leave `:189` and `:472` references AS-IS (they become unambiguously LEGITIMATE under PRIMARY framing — pack-internal refs in a pack-internal file at a pack-only path); A1 (`:189`) and D7.1 (`:472`) SUBSUMED by V5 PRIMARY header. D8.6 (`:465`) NOT touched in this commit — that lands in Commit 9b after Commit 10. **Path A per OQ-1 RESOLVED** | 1 file (pack-ops/ is pack-only; not v11-surface per RC9 base) | **N** (pack-ops/ — new directory; NOT under project-template/ or scripts/) | 3 (file exists at `pack-ops/` post-Commit-3 location); **member of parallel set ALPHA-EXPANDED** | spawn 9a |
| 9b | `feat: v11 — BD-175 TASK-T5 MERGE-STRATEGY D8.6 ref-update (Override 8 cascade)` | In `pack-ops/MERGE-STRATEGY.md`: D8.6 (`:465`) REPLACE — bare `OPTIONAL-FEATURES.md` reference → `docs/pack/OPTIONAL-FEATURES.md` (resolvable at client repos after S2 SPLIT lands per Commit 10). Path A second half of TASK-T5; single-hunk edit. **Path A per OQ-1 RESOLVED** | 1 file (pack-ops/ — not v11-surface) | **N** (pack-ops/) | 9a (file already audience-header-amended); 10 (project-side `project-template/docs/pack/OPTIONAL-FEATURES.md` exists post-Commit 10) | spawn 9b |
| 10 | `feat: v11 — BD-175 TASK-T8 OPTIONAL-FEATURES SPLIT (Override 8 + S3)` | Create `project-template/docs/pack/OPTIONAL-FEATURES.md` from scratch using `pack-ops/OPTIONAL-FEATURES.md` (post-Commit 2 location) as STRUCTURE TEMPLATE per B-fix §13.3 content-split table (9 row-decisions: KEEP / ADAPT / DROP / OMIT per section per audience); approximate length ~150-180 lines; add install stage to `scripts/init-project.sh` to copy `project-template/docs/pack/OPTIONAL-FEATURES.md` → client `docs/pack/OPTIONAL-FEATURES.md` during init (verify existing install-loop already handles `project-template/docs/pack/*.md`; if so, no special-casing); A4-A8 are NO EDIT (LEGITIMATE post-SPLIT — 5 project-side refs become resolvable); D8.7 `supporting-docs/DEPENDENCIES.md:162` REPLACE bare `OPTIONAL-FEATURES.md` with `docs/pack/OPTIONAL-FEATURES.md`. D8.6 in `pack-ops/MERGE-STRATEGY.md` is NOT folded into this commit under Path A — it lands separately in Commit 9b after Commit 10. **regenerate test-fixtures/manifest.txt per RC9** | 1 new project-template file + 1 init-project.sh (conditional) + 1 supporting-docs file (D8.7) + manifest = 3-4 files | **Y** (project-template/ + scripts/init-project.sh touched) | 2 (pack-side file exists post-Commit 2; S2 SPLIT creates project-side counterpart); **first commit of sequential tail under Path A** | spawn 10 |
| 11 | `feat: v11 — BD-175 Override 10 QUICKSTART ref removal (4 help files)` | **Trinity rule commit — 3 CLI-parallel pack-help skill files in lockstep + 1 HELP-FRAGMENT for cohesion per B-fix §12.5.** Remove `docs/pack/QUICKSTART.md` references entirely (do NOT retarget per Override 10) from: (a) `project-template/.gemini/commands/pack-help.toml:10` — delete `docs/pack/QUICKSTART.md,` token, list shortens from 4 to 3 (BEFORE/AFTER per B-fix §12.4.1); (b) `project-template/.claude/skills/pack-help/SKILL.md:13` — same pattern (B-fix §12.4.2); (c) `project-template/.codex/skills/pack-help/SKILL.md:13` — same pattern (B-fix §12.4.3); (d) `project-template/docs/pack/HELP-FRAGMENT.md:4` (front-matter sentence — list shortens from 4 to 3) + `:31` (See-also section — list shortens from 6 to 5) (B-fix §12.4.4); **regenerate test-fixtures/manifest.txt per RC9** | 4 files + manifest = 5 files | **Y** (project-template/ touched) | 3; **member of parallel set ALPHA-EXPANDED** (file-disjoint from Commit 4 — pack-help skill trinity is a different `project-template/` sub-tree from project-template trinity) | spawn 11 |
| 12 | `feat: v11 — BD-175 prevention mechanisms (Architect C M1-M8)` | **Final commit — Architect C's entire prevention mechanism suite per C's §13 order-of-land.** (a) **M2** P-missed-7 codification in pack-root trinity § Pack memory `### Workflow` or new `### Boundary discipline` subsection (per §10 conditional — planner picks `### Workflow` for less invasive landing; full bullet text per C §4); (b) **M2 project-side mirror** in `project-template/CLAUDE.md` + `AGENTS.md` + `GEMINI.md` § Project memory — "Project SSOT-first" bullet per C §4.2 (with `pack-ops/` path-prefix included per S5); per Override 9 the pack-side and project-side bullets DIFFER intentionally (no cross-trinity drift gate); (c) **M4** boundary-investigation skill — create `.claude/skills/boundary-investigation/SKILL.md` + `.codex/skills/boundary-investigation/SKILL.md` + `.gemini/skills/boundary-investigation/SKILL.md` per C §6 content sketch (pack-side); ALSO create `project-template/.claude/skills/boundary-investigation/` + `.codex/skills/` + `.gemini/skills/` parallel set per project-side trinity convention; update PACK-AGENTS.md § "Skills loaded by pack agents" to add `boundary-investigation` to pack-architect / pack-coder / pack-planner / pack-reviewer / pack-docs-researcher; (d) **M3a** reviewer protocol amendment — add dimension 9 to `project-template/docs/pack/prompts/reviewer.md` per C §5.1; add priority-0 to `.claude/skills/review/SKILL.md` + `.codex/skills/review/SKILL.md` + `.gemini/skills/review/SKILL.md`; (e) **M3b** implementer pre-flight — amend `.claude/agents/pack-coder.md` + `.codex/agents/pack-coder.toml` + `.gemini/agents/pack-coder.md` per C §5.2; amend `project-template/docs/pack/prompts/coder.md` standard variant Constraints block; (f) **M6** SSOT-rotation reminder — included in the M3a/M3b prompts per C §7 (no separate commit); (g) **M7** TYPE-5 positive-assertion gate — extension to M3a dimension 9 per C §9.1; (h) **M1a** Pack Chat batch-scope memory rule — added to pack-root trinity § Pack memory `### Pack Chat scope` per C §10.1; (i) **M1b** commit-subject scope-keyword convention — documented in pack-root CLAUDE.md + AGENTS.md + GEMINI.md (Trinity); (j) **M5a Check 36** commit-scope honesty — new check in `scripts/validate-pack.py` with PM-only PERMITTED-PATHS regex per C §8.1a (consumes `pack-ops/.boundary-exempt-root.txt` 1-entry list per C-fix §11 M4 amendment); (k) **M5b Check 37** project-side deny-list — new check with deny-list per C §8.2 (including `pack-ops/` path-prefix per M2 amendment); (l) **M5c Check 38** pack-only-file siting — new check per C §8.3 (consumes 1-entry exemption list per M4); (m) **M8** trinity-rule documentation amendment — add explanatory note per C §9.2 to pack-root CLAUDE.md § "Rules for agents working on this repo" trinity-rule bullet (informational, not enforced); **regenerate test-fixtures/manifest.txt per RC9**; verify Check 37 passes (all 17 contamination refs are resolved by Commits 4-9) | ~30+ files: 6 trinity (pack-root + project-template) + 6 boundary-investigation skill files + 3-4 review skill files + 3 pack-coder agent files + 1 reviewer prompt + 1 coder prompt + 1 PACK-AGENTS.md + scripts/validate-pack.py + scripts/tests/ new check fixtures + manifest | **Y** (multiple project-template/ + scripts/ surfaces) | 4, 5, 6, 7, 8, 9a, 9b, 10, 11 — all 17 contamination refs must be resolved before Check 37 lands or Check 37 fails at HEAD per C §8.2 bootstrap incompatibility note. **Final commit of sequential tail under Path A** | spawn 12 |

**Coder spawn count:** **13 fresh pack-coder spawns** per pack-memory rule (Path A per OQ-1 RESOLVED). NO coder reuse across commits. Spawns 4, 5, 6, 7, 8, 9a, 11 launch in parallel (parallel set ALPHA-EXPANDED) after Commit 3 lands; spawns 9b, 10, 12 are sequential tail.

---

## §2 — Per-commit detail

### §2.1 — Commit 1: pack-ops/ scaffold + BOUNDARY-DEFINITION

#### §2.1.1 — Scope

Create the new top-level `pack-ops/` directory and seed it with two foundational files: `BOUNDARY-DEFINITION.md` (the canonical G7 boundary-rule reference per Architect B's §5.3 structure) and `.boundary-exempt-root.txt` (the 1-entry machine-readable allow-list per B-fix §4 + Overrides 1 + 5). This commit is pre-relocation scaffolding only — no `git mv` operations, no script updates, no path-reference edits. The purpose is to make `pack-ops/` exist on HEAD before Commit 2's `git mv` operations need a destination directory.

#### §2.1.2 — Files affected

ADDED:
- `pack-ops/BOUNDARY-DEFINITION.md` (NEW; ~250-350 lines per B §5.3 structure — §1 Purpose, §2 two-axis classification verbatim from B §1.1, §3 placement verdict procedure verbatim from B §1.2, §4 closed-set root exemption list pointer, §5 SHARED anti-pattern catalog post-resolution per B §4, §6 cross-reference network verbatim from B §5.2, §7 6-10 worked examples one per C1-C6 category)
- `pack-ops/.boundary-exempt-root.txt` (NEW; 1 file content line + 4-line comment header per B §3.3 + B-fix §4):
  ```
  # pack-ops/.boundary-exempt-root.txt — machine-readable closed-set
  # Format: one filename per line; lines starting with # are comments.
  # Files in this list are C2 (PACK × OPERATIONS) allowed at pack root.
  # Adding to this list requires explicit user approval.
  tracker.toml.pack-example
  ```

MODIFIED: none.
DELETED: none.
RENAMED: none.

Manifest regen: N (no `project-template/` or `scripts/` files touched; per RC9 inclusive trigger Pack Chat MAY run `--all --clean` and verify zero diff but is not REQUIRED to stage manifest).

#### §2.1.3 — Coder-prompt sketch

Key inputs the coder reads:
- `ARCHITECTURE-DIRECTORY-REORGANIZATION.md` §5.3 (BOUNDARY-DEFINITION.md doc structure — 7 sub-sections)
- `ARCHITECTURE-DIRECTORY-REORGANIZATION.md` §1.1 (verbatim source for §2 of new doc — the two-axis matrix C1-C6)
- `ARCHITECTURE-DIRECTORY-REORGANIZATION.md` §1.2 (verbatim source for §3 of new doc — placement verdict procedure)
- `ARCHITECTURE-DIRECTORY-REORGANIZATION.md` §4 (source for §5 of new doc — SHARED anti-pattern resolutions; pull post-Override 3 + 4 reduced 5-entry catalog)
- `ARCHITECTURE-DIRECTORY-REORGANIZATION.md` §5.2 (verbatim source for §6 of new doc — cross-reference network)
- `AUDIT-USER-CURATION.md` Overrides 1 + 5 (source for the 1-entry exemption rationale)
- `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` §3.3 (1-entry allow-list machine-readable format)

Key constraints:
- BOUNDARY-DEFINITION.md is markdown-only, ~250-350 lines, NO commentary or BD-specific content (pure rule reference per B §5.3)
- .boundary-exempt-root.txt is plain text, ONE entry (`tracker.toml.pack-example`), NOT THREE (do not include `BACKLOG.md` or `CHANGELOG.md` — those MOVE per Override 5)
- The leading `.` in `.boundary-exempt-root.txt` makes it default-ls-hidden but it IS checked in to git (no `.gitignore` entry needed)
- Worked examples in §7 of the new doc should cover one example per C1-C6 (e.g., README.md = C1, PACK-AGENTS.md = C2, CLAUDE.md = C3, project-template/skills/auditing/SKILL.md = C4, project-template/docs/pack/PM-CHAT.md = C5, project-template/CLAUDE.md = C6) plus at least one worked anti-pattern example (e.g., the V1 failure mode — project trinity acquiring PACK-AGENTS.md reference; show how the placement verdict procedure would have flagged it)

Output expectations: 2 new files committed; PREFLIGHT line per pack-memory; IMPL-REPORT documents the architectural sources for each section of BOUNDARY-DEFINITION.md.

#### §2.1.4 — Verification steps

- `bash scripts/validate-pack.py` — all currently-enabled checks PASS (no new check expects `pack-ops/` to exist at this point; the dir is invisible to existing checks)
- `ls pack-ops/` returns the 2 new files
- `cat pack-ops/.boundary-exempt-root.txt | grep -v '^#' | wc -l` returns `1` (one allow-listed filename)
- `head -1 pack-ops/BOUNDARY-DEFINITION.md` returns the doc title
- No CI failure (pack-ops/ dir + 2 docs are new content; nothing existing breaks)
- Manifest regen check: `bash test-fixtures/build.sh --all --clean && git diff test-fixtures/manifest.txt` returns empty diff (this commit does not touch v11-surface)

#### §2.1.5 — Trinity implications

None. This commit creates only `pack-ops/` files; no CLAUDE.md / AGENTS.md / GEMINI.md edits (pack-root or project-template).

#### §2.1.6 — User-override anchoring

- **Override 1:** `tracker.toml.pack-example` STAYS — encoded as the sole entry in `.boundary-exempt-root.txt`
- **Override 5:** BACKLOG.md + CHANGELOG.md MUST MOVE — encoded as their ABSENCE from the 1-entry list (they are NOT exempted; they will move in Commit 2)
- Cross-reference: per B-fix §4, the C2-at-root exemption list shrinks from B's original 3-entry to 1-entry — this commit encodes that 1-entry reality

---

### §2.2 — Commit 2: directory reorg M1-M5 + M9-M10 (COMBINED — Option A mandatory)

#### §2.2.1 — Scope

The structurally inviolable combined commit per M1 finding + B-fix §7.1 Option A. Relocates 7 root files to `pack-ops/` in ONE atomic landing (PACK-CHAT.md, PACK-AGENTS.md, HELP-FRAGMENT-PACK.md, HELP-FRAGMENT-TRACKER.md, OPTIONAL-FEATURES.md, BACKLOG.md, CHANGELOG.md). Updates ALL pack-side internal references in lockstep — `tracker-config.sh` auto-detection, `detect.sh` pack-surface scan, validate-pack.py STREAMS + Checks 3/22/24, per-entry _lib.sh mirror constants, pack-help.sh fragment resolution, recommendation.sh + tracker-doctor.sh + tracker-agent-read.sh + tracker-migrate-reverse.sh hardcoded mirror paths, test-per-entry.sh canonical-output assertions, pack-root trinity (CLAUDE.md / AGENTS.md / GEMINI.md) Key-files-to-read block + PM-only file list + Repo-conventions BACKLOG bullet, pack-* agent files (5 agents × 3 CLI variants = 15 files), pack-startup skill (3 CLI variants), commit-discipline + implementation-report skills (3 CLIs each), post-M4 `pack-ops/PACK-AGENTS.md` self-references at lines 143-144 (sibling-relative), README.md Repository Layout block. Regenerates `test-fixtures/manifest.txt` per RC9. **Splitting any of M1-M5 from M9-M10 produces the `detect_pack_surface` ambiguity window per M1 finding — Option B is REJECTED per B-fix §7.2.**

#### §2.2.2 — Files affected

RENAMED (git mv — 7 files):
- `HELP-FRAGMENT-PACK.md` → `pack-ops/HELP-FRAGMENT-PACK.md`
- `HELP-FRAGMENT-TRACKER.md` → `pack-ops/HELP-FRAGMENT-TRACKER.md`
- `OPTIONAL-FEATURES.md` → `pack-ops/OPTIONAL-FEATURES.md`
- `PACK-AGENTS.md` → `pack-ops/PACK-AGENTS.md`
- `PACK-CHAT.md` → `pack-ops/PACK-CHAT.md`
- `BACKLOG.md` → `pack-ops/BACKLOG.md`
- `CHANGELOG.md` → `pack-ops/CHANGELOG.md`

MODIFIED (scripts):
- `scripts/lib/tracker-config.sh` line 298 (change `[[ -f "$repo_root/PACK-CHAT.md" ]]` → `[[ -d "$repo_root/pack-ops" ]]`)
- `scripts/lib/detect.sh` lines 23-25 (update docstring) + line 35 (first candidate `$target/pack-ops/BACKLOG.md`; retain `$target/docs/project/BACKLOG.md` as fallback; optionally retain `$target/BACKLOG.md` as third fallback for legacy/fixture back-compat — coder decides per B-fix §10.3)
- `scripts/validate-pack.py` STREAMS lines 191-192 (paths → `pack-ops/BACKLOG.md` + `pack-ops/CHANGELOG.md`); Check 3 line 319 (`backlog = REPO_ROOT / "pack-ops" / "BACKLOG.md"`); Check 3 messages lines 321/332/336 (display path); Check 22 surfaces dict lines 1654/1656/1659 (PACK-CHAT, OPTIONAL-FEATURES, HELP-FRAGMENT-PACK paths); tracker_fragment line 1669 (HELP-FRAGMENT-TRACKER path); lines 1735-1736 (HELP-FRAGMENT-PACK + TRACKER); Check 24 line 1929 (pack-side HELP-FRAGMENT-TRACKER path); docstring/comment lines 122/238/849 (parenthetical path refs)
- `scripts/lib/per-entry/_lib.sh` lines 71+79 (`printf 'pack-ops/BACKLOG.md'` + `printf 'pack-ops/CHANGELOG.md'`)
- `scripts/pack-help.sh` line 33 (usage docstring path)
- `scripts/lib/recommendation.sh` lines 131/151/152/393/462 (`$repo_root/pack-ops/BACKLOG.md` for pack surface; `$repo_root/docs/project/BACKLOG.md` fallback UNCHANGED)
- `scripts/lib/tracker-doctor.sh` lines 114/116/118/123/129/131/135/138 (`$repo_root/pack-ops/BACKLOG.md` for pack surface)
- `scripts/lib/tracker-agent-read.sh` lines 264+267 (`mirror_path="$repo_root/pack-ops/BACKLOG.md"`; TD-* branch line 265 UNCHANGED)
- `scripts/lib/tracker-migrate-reverse.sh` lines 1050/1053/1068/1078/1095/1119/1147 (`$repo_root/pack-ops/BACKLOG.md` + `$repo_root/pack-ops/CHANGELOG.md` reverse-emit destinations)
- `scripts/tests/test-per-entry.sh` lines 220+221 (assertion-on-canonical-output: `"pack-ops/BACKLOG.md"` + `"pack-ops/CHANGELOG.md"`); lines 292+ ~30 lines temp-dir fixtures UNCHANGED (per-line review by coder per B-fix §10.3)

MODIFIED (pack trinity — pack-root, 3 files lockstep per trinity rule):
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md` lines 30-31 (Key files: BACKLOG.md → pack-ops/BACKLOG.md, CHANGELOG.md → pack-ops/CHANGELOG.md); line 83 ("What agents may modify" — CHANGELOG path); line 99 ("What agents must never modify" — BACKLOG path); line 389 ("BACKLOG.md has no Resolved section" bullet — update bare path)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/AGENTS.md` parallel lines (trinity)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/GEMINI.md` parallel lines (trinity)

MODIFIED (pack-* agents — 5 agents × 3 CLI variants = 15 files):
- `.claude/agents/pack-architect.md` line 27 + `.codex/agents/pack-architect.toml` line 18 + `.gemini/agents/pack-architect.md` line 29 (BACKLOG.md read-list entry → `pack-ops/BACKLOG.md`)
- `.claude/agents/pack-planner.md` line 32 + `.codex/agents/pack-planner.toml` line 18 + `.gemini/agents/pack-planner.md` line 25 (BACKLOG.md read-list)
- `.claude/agents/pack-coder.md` lines 34+38 + `.codex/agents/pack-coder.toml` lines 21+23 + `.gemini/agents/pack-coder.md` lines 36+40 (PM-only file list + BD-status-flip rule — both paths)
- `.claude/agents/pack-reviewer.md` + `.codex/.toml` + `.gemini/.md` (grep + update — verify per file at pre-commit)
- `.claude/agents/pack-docs-researcher.md` + `.codex/.toml` + `.gemini/.md` (grep + update)

MODIFIED (pack-side skills):
- `.claude/skills/pack-startup/SKILL.md` lines 19/21/32-33 + `.codex/skills/pack-startup/SKILL.md` lines 19/21/32-33 + `.gemini/commands/pack-startup.toml` lines 16/18/29-30 (step-2 instructions: "Read `pack-ops/BACKLOG.md` in full" + "Read only the most recent dated entry from `pack-ops/CHANGELOG.md`" + per-entry-tree forward-pointing note — update mirror references; per-entry-tree `/backlog/` and `/changelog/` references STAY)
- `.claude/skills/commit-discipline/SKILL.md` + `.codex/.../SKILL.md` + `.gemini/...` (grep + update per pre-commit grep)
- `.claude/skills/implementation-report/SKILL.md` + parallel (grep + update)

MODIFIED (post-M4 sibling references in relocated `pack-ops/PACK-AGENTS.md`):
- `pack-ops/PACK-AGENTS.md` lines 143-144 PM-only files list — update bare `BACKLOG.md` / `CHANGELOG.md` references to bare names (sibling-relative within `pack-ops/`) per B-fix §10.3 (coder chooses consistent form; planner specifies "sibling-bare with no path prefix" for compactness)

MODIFIED (README.md repo-layout):
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/README.md` lines 254-269 area — Repository Layout ascii-tree block. Move 7 entries (HELP-FRAGMENT-PACK, HELP-FRAGMENT-TRACKER, OPTIONAL-FEATURES, PACK-AGENTS, PACK-CHAT, BACKLOG, CHANGELOG) from the pack-root section to a NEW `pack-ops/` block. Add `pack-ops/BOUNDARY-DEFINITION.md` + `pack-ops/.boundary-exempt-root.txt` entries (these are Commit 1 artifacts; ensure README reflects). Verify pack-root section after removal contains exactly: LICENSE.md, QUICKSTART.md, tracker.toml.pack-example, README.md, trinity (CLAUDE/AGENTS/GEMINI), .github/ISSUE_TEMPLATE/, plus the `/backlog/` + `/changelog/` per-entry tree references (UNCHANGED at root — different artifacts from the mirror files)

MODIFIED (test-fixtures/manifest.txt):
- Regenerate per RC9 via `bash test-fixtures/build.sh --all --clean` then `git diff test-fixtures/manifest.txt` (non-empty → stage). v11-* fixture SHAs WILL drift because v11-surface files (project-template/ + scripts/) were touched.

Total: ~52 files modified or renamed.

#### §2.2.3 — Coder-prompt sketch

Key inputs the coder reads:
- `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` §7.1 Option A (THE MANDATE — combined commit; reject Option B)
- `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` §10.3 (per-file line-numbered edits — exhaustive list)
- `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` §6.1-§6.6 (path-reference impact categories — LIVE pack-internal, LIVE auto-detection helpers CRITICAL, LIVE cross-reference docs, FROZEN archive, FROZEN project-side)
- `ARCHITECTURE-DIRECTORY-REORGANIZATION.md` §3.2 (tracker-config.sh detection migration — `[[ -d "$repo_root/pack-ops" ]]`)
- `ARCHITECTURE-DIRECTORY-REORGANIZATION.md` §6.6 (validate-pack.py constant-update table)
- `PACK-REVIEW-PHASE-2-DESIGNS.md` M1 (Option A is mandatory — reject Option B)
- `PACK-REVIEW-PHASE-2-DESIGNS-VERIFICATION.md` §1 M1 (Phase 4 planner constraint — Option A)

Key constraints (load-bearing):
- **Option A is MANDATORY.** Do NOT split M9/M10 into a separate commit. The `detect_pack_surface` ambiguity window between Commit 2-A (M1-M5) and Commit 2-B (M9-M10) is the failure mode M1 finding identifies; this commit is structurally inviolable.
- **`git mv` (not `cp + rm`)** for all 7 relocations — preserves file history per B's §6.4 step 1.
- **Trinity rule applies** to pack-root CLAUDE.md / AGENTS.md / GEMINI.md edits (3 files in lockstep) AND to the 5 pack-* agent file CLI variants (each agent has .md/.toml/.md parallel — Claude / Codex / Gemini) AND to pack-startup skill (.claude/.codex/.gemini variants).
- **Detection fallback judgement call:** B-fix §10.3 leaves to coder + reviewer whether to retain `$target/BACKLOG.md` as a 3rd fallback in `detect.sh` for legacy/test-fixture back-compat. Planner default: RETAIN as 3rd fallback (test-fixtures may have legacy shape; back-compat is cheap; protects against fixture rebuild ordering). Coder confirms by checking `scripts/tests/pack-help-test.sh` fixtures.
- **test-per-entry.sh care:** Lines 220+221 update (they assert canonical-output strings); lines 222+224 (project-side assertions) UNCHANGED; lines 292-562 temp-dir fixtures STAY UNCHANGED (they are isolated `mktemp` fixture trees, not the pack repo's actual mirror — per-line review per B-fix §10.3).
- **Self-reference in `pack-ops/PACK-AGENTS.md` lines 143-144:** post-move, these bare BACKLOG.md / CHANGELOG.md references can be (a) bare names (sibling-relative within `pack-ops/`) OR (b) absolute `pack-ops/BACKLOG.md`. Planner picks (a) bare names for compactness — sibling-relative is the conventional shape in same-directory file references.
- **Forward-pointing note in PACK-AGENTS.md:178-187:** mentions `/backlog/` and `/changelog/` per-entry trees populated at Batch 23. These references are to PER-ENTRY TREES (which STAY at root), not mirror files (which MOVE). DO NOT modify lines 178-187 — they remain accurate.
- **CLAUDE.md / AGENTS.md / GEMINI.md (pack-root) line 389:** "BACKLOG.md has no Resolved section" bullet — update to `pack-ops/BACKLOG.md` (per B-fix §6.1 LIVE pack-side reference).
- **Manifest regen NON-NEGOTIABLE per RC9.** Skipping it produces the 2026-05-17 incident pattern (recovery commit ef9e5c7 standalone).
- **STOP-MEANS-STOP preamble + PREFLIGHT line** per pack-memory (Pack Chat injects when finalizing the prompt).

Output expectations: 7 git-mv'd + ~45 modified files committed in one atomic commit; PREFLIGHT line per pack-memory; IMPL-REPORT documents per-file edits, manifest regen output, full validate-pack pass.

#### §2.2.4 — Verification steps

- `bash scripts/validate-pack.py` — all currently-enabled checks PASS. Check 3 (BACKLOG.md exists at new path), Check 22 (Help-fragment freshness against new paths), Check 24 (HELP-FRAGMENT-TRACKER byte-identity between `pack-ops/` pack-side and `project-template/docs/pack/` client-side), Check 32 (mirror-in-sync — SKIPS since per-entry trees are forward-pointing pre-Batch-23), Check 35 (other surface check).
- `bash scripts/pack-help.sh --root .` — pack-side fragment resolves from new path.
- `bash scripts/pack-help.sh --root project-template` — project-side fragment resolves unchanged (project-side path is `project-template/docs/pack/HELP-FRAGMENT.md`, NOT relocated).
- `bash -c '. scripts/lib/detect.sh && detect_pack_surface .'` — returns `pack-surface: pack` (confirms detect.sh first-candidate update).
- `bash -c '. scripts/lib/tracker-config.sh && tracker_config_auto_surface .'` — returns `pack` (confirms `[[ -d "$repo_root/pack-ops" ]]` works).
- `bash -c '. scripts/lib/per-entry/_lib.sh && pe_canonical_mirror_for_stream pack-backlog'` — returns `pack-ops/BACKLOG.md` (confirms _lib.sh constant update).
- `bash scripts/tests/test-per-entry.sh` — PASS (confirms assertion update at line 220+221; temp-dir fixtures unchanged).
- `bash test-fixtures/build.sh --all --clean && git diff test-fixtures/manifest.txt` — diff is NON-EMPTY (v11-* SHAs drifted); stage the manifest.
- `git status` — shows 52 files staged + manifest staged.
- `git log --format=%s HEAD` — top-line commit subject contains "BD-175 directory reorg M1-M5 + M9-M10 (root → pack-ops/)".
- CI Validate Pack workflow PASS on push.
- Trinity Check 18 H2 parity PASS (pack-root trinity edits in lockstep across all 3 CLI files).

If ANY verification step fails, the coder revert + re-investigate per B's §6.8.

#### §2.2.5 — Trinity implications

- **Pack-root trinity:** lines 30-31 + 83 + 99 + 389 edited in lockstep across CLAUDE.md / AGENTS.md / GEMINI.md (Trinity rule).
- **Pack-side agent files trinity:** 5 agents × 3 CLI variants = 15 files in lockstep (pack-architect / pack-coder / pack-planner / pack-reviewer / pack-docs-researcher each in .claude/.codex/.gemini).
- **Pack-startup skill trinity:** .claude + .codex + .gemini variants in lockstep.
- **commit-discipline + implementation-report skill trinity:** .claude + .codex + .gemini variants in lockstep IF grep matches.
- **Project-template trinity:** UNCHANGED in this commit (all `BACKLOG.md` / `CHANGELOG.md` references in `project-template/` refer to project-side `docs/project/BACKLOG.md` per B-fix §6.6, UNAFFECTED by M9/M10).

#### §2.2.6 — User-override anchoring

- **Override 1:** `tracker.toml.pack-example` STAYS — confirmed by ABSENCE from MOVES list; no relocation in this commit.
- **Override 5:** BACKLOG.md + CHANGELOG.md MUST MOVE — M9 + M10 enacted in this commit (the entire Commit 2 reason-for-existence on top of B's M1-M5).
- **Override 6:** does not apply to Commit 2 (CONCEPTUAL-REVIEW-METHODOLOGY.md moves in Commit 3).
- **Override 2 + Override 4:** root `.github/` / root `.claude/` / root `.codex/` / root `.gemini/` are PACK-ONLY (NOT shared) — DO NOT touch them in this commit; they STAY at root.
- **Override 7:** QUICKSTART.md STAYS at root — DO NOT touch QUICKSTART.md in this commit.

---

### §2.3 — Commit 3: directory reorg M6-M8 (supporting-docs/ → pack-ops/)

#### §2.3.1 — Scope

Relocate 3 supporting-docs files to `pack-ops/` per Architect B's §4.1 F-1 resolution + Override 6: CONCEPTUAL-REVIEW-METHODOLOGY.md (per Override 6 — destination is `pack-ops/`, NOT `maintenance-docs/`), DRY-RUN-MIGRATION.md, MERGE-STRATEGY.md. Updates `scripts/migrate-v10-to-v11.sh` and `scripts/dry-run-migration.sh` path references; updates any live (non-archive, non-frozen) cross-references in `maintenance-docs/v11-implementation/` to the relocated files. This is location-only — content stays as-is (Commit 9 will add the audience header amendment to MERGE-STRATEGY.md per V5 PRIMARY).

#### §2.3.2 — Files affected

RENAMED (git mv — 3 files):
- `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` → `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` (per Override 6, B-fix §16)
- `supporting-docs/DRY-RUN-MIGRATION.md` → `pack-ops/DRY-RUN-MIGRATION.md`
- `supporting-docs/MERGE-STRATEGY.md` → `pack-ops/MERGE-STRATEGY.md`

MODIFIED (scripts):
- `scripts/migrate-v10-to-v11.sh` — references to `supporting-docs/MERGE-STRATEGY.md` and `supporting-docs/DRY-RUN-MIGRATION.md` (full grep)
- `scripts/dry-run-migration.sh` — references to `supporting-docs/DRY-RUN-MIGRATION.md` (per B's §6.5 M7-M8 description)

MODIFIED (live maintenance-docs/v11-implementation/ cross-references — case-by-case per B-fix §6.5):
- Any in-flight (non-archived) `maintenance-docs/v11-implementation/*.md` file that names `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` or `supporting-docs/MERGE-STRATEGY.md` or `supporting-docs/DRY-RUN-MIGRATION.md` as a LIVE PATH (not as a historical quote describing past state — those are FROZEN per B-fix §6.4) updates to the `pack-ops/` path. Coder runs a grep to identify, applies per-file judgment: live forward-pointing references update; archived/historical references stay.

NOT MODIFIED (frozen per B-fix §6.4):
- `maintenance-docs/archive/v11/**` — all archived design records / impl reports / reviews stay UNCHANGED (they describe past state where files were at `supporting-docs/`; updating would falsify the historical record)
- Architect docs (`ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md`, `ARCHITECTURE-DIRECTORY-REORGANIZATION.md`, `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md`, `ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md`) — these already name the post-move paths correctly per the architect-fix-pass cycles (A-fix S1, B-fix-v2 §16, C-fix). Verify no stale `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` LIVE refs remain (per Phase 3 verification §1 Override 6 cascade — 0 hits in B-original, 5 hits all inside historical `Before:` rows in B-fix §16).

NOT MODIFIED (no CONCEPTUAL-REVIEW-METHODOLOGY trinity reference exists):
- Pack-root trinity (CLAUDE.md / AGENTS.md / GEMINI.md) — verify via grep that NO trinity file references `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` or the bare filename. The trinity § "Repo conventions" §"Skill and agent maintenance is mechanical by default" bullet mentions `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` (which is at `maintenance-docs/v11-implementation/` — UNAFFECTED).

MODIFIED (test-fixtures/manifest.txt):
- Regenerate per RC9 (scripts/migrate-v10-to-v11.sh + scripts/dry-run-migration.sh touched — v11-surface).

Total: ~7-9 files (3 git-mv + 2-3 scripts + 1-3 live maintenance-docs/v11-implementation/ refs + manifest).

#### §2.3.3 — Coder-prompt sketch

Key inputs the coder reads:
- `ARCHITECTURE-DIRECTORY-REORGANIZATION.md` §4.1 (F-1 resolution; CONCEPTUAL-REVIEW-METHODOLOGY destination per B-fix §16 v2 amendment)
- `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` §11.3 step 3 (Commit C — `supporting-docs/` → `pack-ops/` for ALL THREE files post-v2 amendment)
- `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` §16 (Override 6 cascade closure — destination is `pack-ops/`, NOT `maintenance-docs/`)
- `AUDIT-USER-CURATION.md` Override 6 (the user direction — destination is `pack-ops/`)
- `ARCHITECTURE-DIRECTORY-REORGANIZATION.md` §6.5 M6 + M7 + M8 grep + sed plans (per-file reference updates)
- `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` §6.5 (live-vs-archive triage — only LIVE maintenance-docs/v11-implementation/ refs update; archive stays frozen)
- `ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md` §2 V4 implementation hint step 4 (full grep + retarget all to `pack-ops/`)

Key constraints:
- **Destination is `pack-ops/` per Override 6, NOT `maintenance-docs/`.** This is load-bearing; B's original §4.1 proposed `maintenance-docs/` but was rejected by Override 6 (per B-fix §16 cascade closure).
- **git mv** (not cp + rm) for all 3 relocations.
- **Content preserved exactly** during the move — including the +2 lines from `aaa61b3` (per V2 cascade subsumption — V4 absorbs V2; content is correct for pack-internal audience).
- **Archive is FROZEN** — do not modify any file under `maintenance-docs/archive/v11/`. Skill: when the grep finds matches, check the file path; if `archive/`, skip (historical record).
- **Architect docs are already updated** post-fix-pass; verify no stale LIVE refs remain via grep but do not re-edit unless a true live LIVE ref is found.
- **Test-per-entry.sh and other tests:** unaffected by these moves (the test-per-entry.sh assertions test pack-side BACKLOG/CHANGELOG mirror paths — already updated in Commit 2).
- Manifest regen NON-NEGOTIABLE per RC9.

Output expectations: 3 git-mv'd + ~5 modified files committed; PREFLIGHT line; IMPL-REPORT documents per-script and per-cross-reference edits.

#### §2.3.4 — Verification steps

- `bash scripts/validate-pack.py` — all checks PASS (no check directly references supporting-docs/ → pack-ops/ moves except by file existence)
- `ls pack-ops/` — shows 9 files (Commit 1's 2 + Commit 2's 7 + Commit 3's 3 — wait, Commit 2 has 7 git-mv + Commit 1 has 2 new = 9 expected before Commit 3; after Commit 3 = 12 files)
- `ls supporting-docs/` — shows the post-move state: AGENT_KICKOFF_TEMPLATE.md, CLI-PM-SETUP.md, DEPENDENCIES.md, INSTALL-PROCEDURES.md, METHODOLOGY.md, MIGRATION-v10-to-v11.md, MIGRATION-v8-to-v9.md, SETUP-EXISTING.md, SETUP-NEW.md, SETUP_TEMPLATE.md (CONCEPTUAL-REVIEW-METHODOLOGY, DRY-RUN-MIGRATION, MERGE-STRATEGY are gone)
- `grep -r "supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY\.md" --include="*.md" --include="*.sh" --include="*.py" --exclude-dir=archive .` — returns ZERO LIVE hits (architect docs allowed if they cite as historical "Before:")
- `grep -r "supporting-docs/DRY-RUN-MIGRATION\.md" --include="*.md" --include="*.sh" --include="*.py" --exclude-dir=archive .` — zero live hits
- `grep -r "supporting-docs/MERGE-STRATEGY\.md" --include="*.md" --include="*.sh" --include="*.py" --exclude-dir=archive .` — zero live hits
- `bash scripts/dry-run-migration.sh --help` (or equivalent) — script runs without "file not found" errors
- `bash test-fixtures/build.sh --all --clean && git diff test-fixtures/manifest.txt` — diff non-empty (scripts/ touched); stage manifest
- Trinity Check 18 H2 parity: N/A (no trinity files touched)
- CI Validate Pack PASS

#### §2.3.5 — Trinity implications

None. No CLAUDE.md / AGENTS.md / GEMINI.md edits in this commit.

#### §2.3.6 — User-override anchoring

- **Override 6:** CONCEPTUAL-REVIEW-METHODOLOGY.md destination is `pack-ops/`, NOT `maintenance-docs/` — this commit enacts Override 6 directly. Cross-reference to B-fix §16 v2 amendment for the cascade closure.
- **Override 1, 5, 7:** not applicable to this commit.

---

### §2.4 — Commit 4: TASK-T1 trinity REPLACE + REVERT (V1 + T5-A + V8)

#### §2.4.1 — Scope

The trinity-rule commit per Architect A's §2 V1 + T5-A + V8 cluster (TASK-T1). Three project-template trinity files (CLAUDE.md / AGENTS.md / GEMINI.md) edited in lockstep:
1. **V1 REPLACE + T5-A REVERT** at L366/343/356 — drop the inline agent enumeration `(architect / planner / coder / reviewer / tester / auditor / docs-researcher / grpc-schema / repo-ops)` AND the `see PACK-AGENTS.md for the full roster` reference; replace with a single pointer to project-side SSOT `docs/pack/PM-CHAT.md § Pack agent roster`.
2. **V8 REVERT** at L397/374/387 — delete the italicized paragraph referencing `TOOL-COMPARISON.md in the pack's maintenance-docs/`.

The TYPE-2 contamination (V1) and the TYPE-4 contamination (V8) both stem from the project-side trinity acquiring pack-only references. The fix routes project-side trinity readers to the project-side SSOT (`docs/pack/PM-CHAT.md` § Pack agent roster) that already exists at every client install. The inline enumeration (T5-A) was the structural defect that V1 contamination grew on top of — removing it closes both findings at once.

#### §2.4.2 — Files affected

MODIFIED (project-template trinity — 3 files in lockstep):
- `project-template/CLAUDE.md` lines 364-366 (V1 + T5-A) + line 397 (V8)
- `project-template/AGENTS.md` lines 341-343 (V1 + T5-A) + line 374 (V8)
- `project-template/GEMINI.md` lines 354-356 (V1 + T5-A) + line 387 (V8)

EXACT EDIT (V1 + T5-A) per Architect A §2 V1 Implementation hint:

BEFORE (representative — trinity wording varies slightly across CLI files):
```
- **PM chat does not architect.** Architecture, planning,
  implementation, and review work goes to the corresponding agent
  (architect / planner / coder / reviewer / tester / auditor /
  docs-researcher / grpc-schema / repo-ops) — `auditor` covers the
  7 variant agents; see `PACK-AGENTS.md` for the full roster. The
  PM chat handles BACKLOG, STATUS, CHANGELOG, routing, approvals,
  and prompt construction — not the work the agents do.
```

AFTER:
```
- **PM chat does not architect.** Architecture, planning,
  implementation, and review work goes to the corresponding agent.
  The full pack agent roster is at `docs/pack/PM-CHAT.md` §
  Pack agent roster — that section is the project-side SSOT; do
  not infer the roster from any other source. The PM chat handles
  BACKLOG, STATUS, CHANGELOG, routing, approvals, and prompt
  construction — not the work the agents do.
```

EXACT EDIT (V8) per Architect A §2 V8 Implementation hint:

BEFORE:
```
*For deeper agent-by-agent comparison (e.g., when to use auditor
vs. reviewer vs. docs-researcher), see `TOOL-COMPARISON.md` in
the pack's `maintenance-docs/`.*
```

AFTER: (deleted entirely — drop the entire italicized paragraph; no replacement)

MODIFIED (test-fixtures/manifest.txt):
- Regenerate per RC9 (project-template/ trinity files touched — v11-surface).

Total: 3 trinity files + manifest = 4 files.

#### §2.4.3 — Coder-prompt sketch

Key inputs the coder reads:
- `ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md` §2 V1 (REPLACE — full implementation hint with BEFORE/AFTER)
- `ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md` §2 T5-A (REVERT — inline enumeration removal coupled to V1's REPLACE; single hunk per trinity file)
- `ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md` §2 V8 (REVERT — delete italicized paragraph)
- `ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md` §6.1 TASK-T1 (V1 + T5-A + V8 combined commit)
- `ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md` §6.4 TASK-T1 manifest-regen trigger

Key constraints:
- **Trinity rule strict** — all 3 CLI files edited in the same commit; no asymmetry. Each CLI's BEFORE wording varies slightly (Claude vs Codex vs Gemini); coder reads each file to find the exact match before sed/edit.
- **V1 + T5-A is ONE hunk per trinity file** — the inline enumeration removal IS the V1 REPLACE (per A §2 V1 + T5-A coupling).
- **V8 is a separate hunk** further down in the same trinity file — delete the entire italicized paragraph.
- **Project-side SSOT is `docs/pack/PM-CHAT.md` § Pack agent roster** — this resolves at every client install (the PM-CHAT.md file ships via init-project.sh). Verify via grep that PM-CHAT.md contains the § Pack agent roster section.
- **Reference target is bare path `docs/pack/PM-CHAT.md`** (NOT a pack-side qualified path) — resolvable from a client repo root after install.
- **No remaining `PACK-AGENTS.md` references** in any project-template trinity file post-edit (full grep verifies).
- **No remaining `TOOL-COMPARISON.md` references** in any project-template trinity file post-edit.
- **No remaining `maintenance-docs/` references** in project-template trinity post-edit.
- Manifest regen per RC9.

Output expectations: 3 modified trinity files + manifest; PREFLIGHT line; IMPL-REPORT documents per-file BEFORE/AFTER diff context.

#### §2.4.4 — Verification steps

- `bash scripts/validate-pack.py` — Trinity Check 18 H2 parity PASS (3 files updated symmetrically)
- `grep -n "PACK-AGENTS" project-template/CLAUDE.md project-template/AGENTS.md project-template/GEMINI.md` — ZERO hits
- `grep -n "TOOL-COMPARISON" project-template/CLAUDE.md project-template/AGENTS.md project-template/GEMINI.md` — ZERO hits
- `grep -n "maintenance-docs" project-template/CLAUDE.md project-template/AGENTS.md project-template/GEMINI.md` — ZERO hits
- `grep -n "docs/pack/PM-CHAT.md" project-template/CLAUDE.md project-template/AGENTS.md project-template/GEMINI.md` — 1 hit each (the new pointer is present)
- `grep -n "architect / planner / coder / reviewer / tester / auditor" project-template/CLAUDE.md project-template/AGENTS.md project-template/GEMINI.md` — ZERO hits (the inline enumeration is gone)
- `bash test-fixtures/build.sh --all --clean && git diff test-fixtures/manifest.txt` — diff non-empty; stage
- CI Validate Pack PASS

#### §2.4.5 — Trinity implications

- **Project-template trinity (3 files lockstep).** V1 + T5-A is hunk 1; V8 is hunk 2 — both hunks land in all 3 files in the same commit.
- **Pack-root trinity:** UNTOUCHED by this commit. The pack-root trinity reads the pack-only roster from PACK-AGENTS.md (now at `pack-ops/PACK-AGENTS.md` post-Commit-2) — that reference is LEGITIMATE pack-internal (pack-root trinity is pack audience). Pack-root trinity does NOT need the same edit.

#### §2.4.6 — User-override anchoring

- **Override 9:** does not apply directly to this commit (Override 9 is about the M2 P-missed-7 codification in Commit 12). But the principle (different audience = different wording) is consistent with this commit — project-side trinity gets project-side SSOT pointer; pack-side trinity (if it had an analogous reference) would point to pack-side SSOT.
- **No other overrides apply directly.**

---

### §2.5 — Commit 5: TASK-T2 PLATFORM-SKILLS REPLACE + REVERT (V3)

#### §2.5.1 — Scope

Per Architect A's §2 V3 (TASK-T2): two distinct contamination patterns in `project-template/docs/pack/PLATFORM-SKILLS.md`:
1. V3.a L251 REPLACE — pack-only `PACK-AGENTS.md` reference replaced with project-side SSOT `docs/pack/PM-CHAT.md § Pack agent roster`.
2. V3.b L572 REVERT — pack-only `maintenance-docs/.../ARCHITECTURE-SKILL-DIMENSIONS.md` reference dropped (or reduced to generic "(see pack documentation if you need the design rationale)" with NO path).

Both edits in the same file in one commit.

#### §2.5.2 — Files affected

MODIFIED:
- `project-template/docs/pack/PLATFORM-SKILLS.md` lines ~251 (V3.a) + ~572 (V3.b)

EXACT EDIT (V3.a):
- BEFORE: "selection. See `PACK-AGENTS.md` in the pack repo for their use."
- AFTER: "selection. See `docs/pack/PM-CHAT.md` § Pack agent roster for the canonical project-side agent list."

EXACT EDIT (V3.b):
- BEFORE: "(`maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md`" + surrounding rationale parenthetical
- AFTER: drop entire parenthetical pointer; if surrounding prose needs an anchor, replace with "(see pack documentation if you need the design rationale)" — generic, no path

MODIFIED (test-fixtures/manifest.txt):
- Regenerate per RC9 (project-template/ touched).

Total: 1 file + manifest = 2 files.

#### §2.5.3 — Coder-prompt sketch

Key inputs: `ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md` §2 V3 (full implementation hint with BEFORE/AFTER for both sites).

Key constraints:
- V3.a SSOT path is `docs/pack/PM-CHAT.md` (resolvable from client repo root after install)
- V3.b drop the entire parenthetical pointer; if generic anchor is wanted, no path
- Full grep on PLATFORM-SKILLS.md verifies NO remaining `PACK-AGENTS.md` or `maintenance-docs/` references after both edits
- File reads cleanly end-to-end post-edit (no orphan punctuation, no broken sentence flow)
- Manifest regen per RC9

Output: 1 modified file + manifest committed; PREFLIGHT; IMPL-REPORT shows BEFORE/AFTER for both hunks.

#### §2.5.4 — Verification steps

- `grep -n "PACK-AGENTS.md" project-template/docs/pack/PLATFORM-SKILLS.md` — ZERO hits
- `grep -n "maintenance-docs/" project-template/docs/pack/PLATFORM-SKILLS.md` — ZERO hits
- Read L251 area + L572 area context; prose flows cleanly
- `bash test-fixtures/build.sh --all --clean && git diff test-fixtures/manifest.txt` — diff non-empty; stage
- CI PASS

#### §2.5.5 — Trinity implications

None. PLATFORM-SKILLS.md is a single-file project-side surface; no CLI-parallel mirrors at this path.

#### §2.5.6 — User-override anchoring

None apply directly. V3 is an Architect A decision under boundary-discipline (per AUDIT §C / §D-1 D1.4 + §D-5 D5.4); user did not override A's V3 decision.

---

### §2.6 — Commit 6: TASK-T3 audit-methodology REVERT (V7)

#### §2.6.1 — Scope

Per Architect A's §2 V7 (TASK-T3): drop both `maintenance-docs/.../RESEARCH-NON-APPLE-UI-SKILLS.md` references from `project-template/skills/audit-methodology/SKILL.md` (L51 + L106). Keep the "currently planned post-v11.0" deferral language; only drop the pack-side path pointer.

#### §2.6.2 — Files affected

MODIFIED:
- `project-template/skills/audit-methodology/SKILL.md` lines 51 + 106

EXACT EDITS (per Architect A §2 V7 Implementation hint):
- L51 BEFORE: "…currently planned post-v11.0 — see `maintenance-docs/v11-implementation/RESEARCH-NON-APPLE-UI-SKILLS.md`):"
- L51 AFTER: "…currently planned post-v11.0):"
- L106 BEFORE: "…currently planned post-v11.0 — see `maintenance-docs/v11-implementation/RESEARCH-NON-APPLE-UI-SKILLS.md` for the in-flight design); once those skills land, this detection list extends to include their markers."
- L106 AFTER: "…currently planned post-v11.0); once those skills land, this detection list extends to include their markers."

MODIFIED (test-fixtures/manifest.txt):
- Regenerate per RC9.

Total: 1 file + manifest = 2 files.

#### §2.6.3 — Coder-prompt sketch

Inputs: `ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md` §2 V7.

Constraints:
- Drop only the " — see `maintenance-docs/...`" prefix (and similar for L106 variant); keep "currently planned post-v11.0" intact
- Surrounding prose reads cleanly after deletion
- Full grep across `project-template/skills/` tree confirms no other `maintenance-docs/` refs (the prompt instructs the coder to grep the whole skill tree, not just the audit-methodology skill)
- Manifest regen per RC9

Output: 1 modified file + manifest; PREFLIGHT; IMPL-REPORT shows BEFORE/AFTER.

#### §2.6.4 — Verification steps

- `grep -n "RESEARCH-NON-APPLE-UI-SKILLS" project-template/skills/audit-methodology/SKILL.md` — ZERO hits
- `grep -rn "maintenance-docs/" project-template/skills/` — ZERO hits across all 35 skill subdirs
- Prose at L51 + L106 reads cleanly
- Manifest staged
- CI PASS

#### §2.6.5 — Trinity implications

None. audit-methodology SKILL.md is a single-file project-side skill (not CLI-parallel — the SKILL.md lives at `project-template/skills/audit-methodology/` and is distributed to `.claude/skills/`, `.codex/skills/`, `.gemini/skills/` at client install via init-project.sh).

#### §2.6.6 — User-override anchoring

None apply directly. V7 is an A decision under boundary-discipline (per AUDIT §D-5 D5.5 + D5.6).

---

### §2.7 — Commit 7: TASK-T4 MIGRATION-v10-to-v11 REPLACE + REVERT (V6)

#### §2.7.1 — Scope

Per Architect A's §2 V6 (TASK-T4): three distinct edits in `supporting-docs/MIGRATION-v10-to-v11.md`:
1. V6.a L35 — LOW priority; tighten phrasing or leave (qualified-dual-path is LEGITIMATE inter-surface communication).
2. V6.b L516 REPLACE — "Run a Pack Chat session: `/pm-startup`..." → "Open a PM Chat session in your client project: `/pm-startup`..." (terminology fix — pack-side orchestrator "Pack Chat" is wrong for project-user-facing migration instruction).
3. V6.c L123 + L194 + L225 REVERT — drop leading "Per `maintenance-docs/.../ARCHITECTURE-SKILL-DIMENSIONS.md` §N.M, " prefix from each sentence; sentence stands without the prefix.

#### §2.7.2 — Files affected

MODIFIED:
- `supporting-docs/MIGRATION-v10-to-v11.md` lines 35 (V6.a, LOW) + 123 + 194 + 225 (V6.c REVERT) + 516 (V6.b REPLACE)

MODIFIED (test-fixtures/manifest.txt):
- NONE — `supporting-docs/` is NOT v11-surface per RC9 base case.

Total: 1 file (no manifest).

#### §2.7.3 — Coder-prompt sketch

Inputs: `ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md` §2 V6 (all three sub-decisions with implementation hints).

Constraints:
- V6.b: the "Pack Chat session" → "PM Chat session in your client project" terminology change is load-bearing for project-user audience clarity
- V6.c: drop only the leading "Per `maintenance-docs/...` §N.M, " prefix from each sentence; preserve the rest of each sentence
- V6.a: optional tightening; coder may leave as-is OR rephrase per architect's "tighten phrasing" suggestion (e.g., "you'll read `HELP-FRAGMENT-PACK.md` from the pack repo before running the migrator; afterwards your client repo will have `docs/pack/HELP-FRAGMENT.md`")
- Full grep on MIGRATION-v10-to-v11.md confirms NO remaining `maintenance-docs/` references post-edits
- File's narrative reads cleanly end-to-end post-edits (coder sample-reads three modified sections in context)
- NO manifest regen needed (supporting-docs/ is not v11-surface)

Output: 1 modified file (no manifest); PREFLIGHT; IMPL-REPORT shows BEFORE/AFTER for all 5 edits.

#### §2.7.4 — Verification steps

- `grep -n "Pack Chat" supporting-docs/MIGRATION-v10-to-v11.md` — only LEGITIMATE feedback-flow references remain (verify per audit §D-4 LEGITIMATE designation); L516 "Pack Chat session" is GONE
- `grep -n "maintenance-docs/" supporting-docs/MIGRATION-v10-to-v11.md` — ZERO hits
- `grep -n "PM Chat session in your client project" supporting-docs/MIGRATION-v10-to-v11.md` — at least 1 hit (the new L516 wording)
- Sample-read L35 + L123 + L194 + L225 + L516 in context; prose flows cleanly
- NO manifest regen check (file is not v11-surface)
- CI PASS

#### §2.7.5 — Trinity implications

None. MIGRATION-v10-to-v11.md is a single-file pack-side migration guide (no CLI-parallel mirrors).

#### §2.7.6 — User-override anchoring

None apply directly. V6 is an A decision under boundary-discipline (per AUDIT §C V6 + §D-4 D4.1 + §D-5 D5.7 + D5.8 + D5.9).

---

### §2.8 — Commit 8: TASK-T6 METHODOLOGY REPLACE (A2)

#### §2.8.1 — Scope

Per Architect A's §4 A2 (TASK-T6): historical attribution at `supporting-docs/METHODOLOGY.md:1509` references pack-internal `maintenance-docs/origins/Claude-Assisted_Project_Methodology_Guide_v1.md`. METHODOLOGY.md IS installed to clients (per `init-project.sh:565-570`). The path is unresolvable at clients → contamination. REPLACE: drop the path; keep the descriptive attribution name.

#### §2.8.2 — Files affected

MODIFIED:
- `supporting-docs/METHODOLOGY.md` line 1509

EXACT EDIT (per A §4 A2 Implementation hint):
- BEFORE: "*Source: maintenance-docs/origins/Claude-Assisted_Project_Methodology_Guide_v1.md*"
- AFTER: "*Source: Claude-Assisted Project Methodology Guide v1 (pack-archived design source)*"

MODIFIED (test-fixtures/manifest.txt):
- NONE — `supporting-docs/` is NOT v11-surface per RC9 base case.

Total: 1 file (no manifest).

#### §2.8.3 — Coder-prompt sketch

Inputs: `ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md` §4 A2.

Constraints:
- Drop ONLY the `maintenance-docs/origins/` path; keep "Claude-Assisted Project Methodology Guide v1" attribution
- Add "(pack-archived design source)" qualifier to preserve provenance context without the broken path
- Full grep on METHODOLOGY.md confirms NO remaining `maintenance-docs/` paths (only this one reference per audit)
- METHODOLOGY.md reads cleanly at client repos post-edit (the file IS installed to clients per init-project.sh:565-570)
- NO manifest regen (supporting-docs/ not v11-surface)

Output: 1 modified file; PREFLIGHT; IMPL-REPORT.

#### §2.8.4 — Verification steps

- `grep -n "maintenance-docs/" supporting-docs/METHODOLOGY.md` — ZERO hits
- `grep -n "Claude-Assisted Project Methodology Guide v1" supporting-docs/METHODOLOGY.md` — 1 hit (attribution preserved with the post-edit phrasing)
- Sample-read L1509 context; reads cleanly
- NO manifest regen check
- CI PASS

#### §2.8.5 — Trinity implications

None.

#### §2.8.6 — User-override anchoring

None apply directly. A2 is an A decision under boundary-discipline (per AUDIT §D AMBIGUOUS-other A2).

---

### §2.9a — Commit 9a: TASK-T5 MERGE-STRATEGY audience header only (V5 PRIMARY)

#### §2.9a.1 — Scope

Per Architect A's §2 V5 PRIMARY recommendation (TASK-T5, first half under Path A per OQ-1 RESOLVED): add an audience header amendment to `pack-ops/MERGE-STRATEGY.md` (post-Commit 3 location) at L1-L20 area making the pack-internal audience explicit. PRIMARY framing: file stays pack-only (not installed to clients), so `:189` and `:472` pack-only references become unambiguously LEGITIMATE under the header amendment — no per-ref REPLACE needed for those two.

D8.6 (`:465` bare `OPTIONAL-FEATURES.md` reference) is NOT touched in this commit. Per Path A (OQ-1 RESOLVED 2026-05-19), D8.6 lands separately in Commit 9b AFTER Commit 10 creates the project-side `project-template/docs/pack/OPTIONAL-FEATURES.md`.

**Commit 9a is a member of parallel set ALPHA-EXPANDED** (see §8.2) — file-disjoint from Commits 4, 5, 6, 7, 8, 11; concurrent with them.

#### §2.9a.2 — Files affected

MODIFIED:
- `pack-ops/MERGE-STRATEGY.md` lines 1-20 area ONLY (audience header amendment per V5 PRIMARY). Lines 189 + 465 + 472 are LEFT AS-IS in this commit (line 465 lands in Commit 9b; lines 189 + 472 are LEGITIMATE under PRIMARY framing per A §2 V5).

EXACT EDIT (V5 PRIMARY audience header — per A §2 V5 PRIMARY):
- Add to L1-L20 area: "This document is pack-internal reference for pack maintainers running the migrator. Project users encounter the per-class disposition tokens via `report.md` produced by the migrator; they do not read this file directly."

NOT MODIFIED in this commit (per Path A split):
- L189: "Pack-shipped agent files (e.g., `pack-architect.md`, `pack-reviewer.md`)" — STAYS (LEGITIMATE under PRIMARY framing)
- L465: bare `OPTIONAL-FEATURES.md` reference — DEFERRED to Commit 9b
- L472: "`HELP-FRAGMENT-PACK.md` and `validate-pack.py` Check 22 skips" — STAYS (LEGITIMATE under PRIMARY framing)

MODIFIED (test-fixtures/manifest.txt):
- NONE — `pack-ops/` is NOT v11-surface per RC9 base case (pack-ops/ is a new pack-only top-level dir, not under project-template/ or scripts/).

Total: 1 file (no manifest).

#### §2.9a.3 — Coder-prompt sketch

Inputs:
- `ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md` §2 V5 PRIMARY (audience header amendment)
- This plan's §2.9a (Path A first-half partition per OQ-1 RESOLVED)

Constraints:
- V5 PRIMARY chosen over ALTERNATIVE — audience header amendment is the load-bearing edit
- L465 (D8.6 ref) NOT touched in this commit — Path A split means audience-header only
- A1 (`:189` site-rendered) + D7.1 (`:472` site-rendered) are SUBSUMED under PRIMARY header — no edit
- File reads cleanly post-edit (audience header makes the pack-internal framing explicit)
- NO manifest regen (pack-ops/ not v11-surface)
- **Coder runs in parallel set ALPHA-EXPANDED** — file-disjoint from concurrent Commits 4, 5, 6, 7, 8, 11 per §8.2

Output: 1 modified file (no manifest); PREFLIGHT; IMPL-REPORT.

#### §2.9a.4 — Verification steps

- `head -25 pack-ops/MERGE-STRATEGY.md` — shows the new audience header amendment
- `grep -n "audience" pack-ops/MERGE-STRATEGY.md | head -3` — confirms header inserted
- `sed -n '465p' pack-ops/MERGE-STRATEGY.md` — confirms L465 still says bare `OPTIONAL-FEATURES.md` (unchanged in this commit; D8.6 lands in 9b)
- File reads cleanly end-to-end
- NO manifest regen check
- CI PASS

#### §2.9a.5 — Trinity implications

None. MERGE-STRATEGY.md is a single pack-side migration helper doc.

#### §2.9a.6 — User-override anchoring

- **Override 6:** indirect — MERGE-STRATEGY.md moved to `pack-ops/` in Commit 3 per Override 6 cascade; this commit edits content at the new path.
- **Override 8:** does NOT apply to this commit (D8.6 ref-update is in Commit 9b).
- No other overrides apply directly.

---

### §2.9b — Commit 9b: TASK-T5 MERGE-STRATEGY D8.6 ref-update (Override 8 cascade)

#### §2.9b.1 — Scope

Per Architect A's §3.5 D8.6 amendment (S2 fix-pass per Override 8): REPLACE bare `OPTIONAL-FEATURES.md` reference at `pack-ops/MERGE-STRATEGY.md:465` with `docs/pack/OPTIONAL-FEATURES.md` (resolvable at client repos after S2 SPLIT lands per Commit 10).

This is the second half of TASK-T5 under Path A (OQ-1 RESOLVED 2026-05-19). Single-hunk edit; lands SEQUENTIALLY after Commit 10 (project-side `project-template/docs/pack/OPTIONAL-FEATURES.md` must exist for the reference to resolve at client repos).

#### §2.9b.2 — Files affected

MODIFIED:
- `pack-ops/MERGE-STRATEGY.md:465` ONLY (D8.6 REPLACE)

EXACT EDIT (D8.6 ref):
- BEFORE (L465): "`OPTIONAL-FEATURES.md` — tracker opt-in walkthrough"
- AFTER: "`docs/pack/OPTIONAL-FEATURES.md` — tracker opt-in walkthrough"

NOT MODIFIED in this commit:
- L1-L20 audience header — landed in Commit 9a; unchanged
- L189 + L472 — LEGITIMATE under PRIMARY framing from Commit 9a; unchanged

MODIFIED (test-fixtures/manifest.txt):
- NONE — `pack-ops/` is NOT v11-surface per RC9 base case.

Total: 1 file (no manifest).

#### §2.9b.3 — Coder-prompt sketch

Inputs:
- `ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md` §3.5 D8.6 (REPLACE bare `OPTIONAL-FEATURES.md` with `docs/pack/OPTIONAL-FEATURES.md` per Override 8 S2 SPLIT)
- This plan's §2.9b (Path A second-half partition per OQ-1 RESOLVED)
- Verify: project-side `project-template/docs/pack/OPTIONAL-FEATURES.md` exists at HEAD (Commit 10 already landed)

Constraints:
- Single-hunk edit at L465 ONLY; do not re-edit the audience header (lands in 9a)
- D8.6 ref-update path is `docs/pack/OPTIONAL-FEATURES.md` — resolvable at client repos after Commit 10 SPLIT
- File reads cleanly post-edit
- NO manifest regen (pack-ops/ not v11-surface)
- Sequential commit — coder waits for Commit 10 to land before spawning

Output: 1 modified file (no manifest); PREFLIGHT; IMPL-REPORT.

#### §2.9b.4 — Verification steps

- `sed -n '465p' pack-ops/MERGE-STRATEGY.md` — confirms L465 now says `docs/pack/OPTIONAL-FEATURES.md`
- `grep -n "docs/pack/OPTIONAL-FEATURES" pack-ops/MERGE-STRATEGY.md` — at least 1 hit (L465 post-edit)
- `ls project-template/docs/pack/OPTIONAL-FEATURES.md` — confirms target file exists (Commit 10 landed)
- File reads cleanly end-to-end
- NO manifest regen check
- CI PASS

#### §2.9b.5 — Trinity implications

None. MERGE-STRATEGY.md is a single pack-side migration helper doc.

#### §2.9b.6 — User-override anchoring

- **Override 8:** D8.6 REPLACE per Override 8 SPLIT-confirmed path — bare `OPTIONAL-FEATURES.md` → `docs/pack/OPTIONAL-FEATURES.md`. Cross-reference to A-fix §10.3.
- **Override 6:** does not apply directly (MERGE-STRATEGY.md moved per Override 6 in Commit 3; this commit edits content at the new path).
- No other overrides apply directly.

---

### §2.10 — Commit 10: TASK-T8 OPTIONAL-FEATURES SPLIT (Override 8 + S3)

#### §2.10.1 — Scope (sequential-tail-first commit per Path A)

Per Architect A's §6.1 TASK-T8 (per Override 8 CONFIRMED SPLIT + Architect B's §4.5 (b) + B-fix §13 content-split sketch + S3 fix-pass): create the project-side `OPTIONAL-FEATURES.md` from scratch using `pack-ops/OPTIONAL-FEATURES.md` (post-Commit-2 location) as the STRUCTURE TEMPLATE. Apply B-fix §13.3's 9-row content-split table per audience (KEEP / ADAPT / DROP / OMIT). Add install stage to `scripts/init-project.sh` so the new project-side file ships to clients. Update D8.7 reference in DEPENDENCIES.md to resolvable path. A4-A8 verify-only (5 references become LEGITIMATE post-SPLIT — no edits).

**Per OQ-1 RESOLVED (Path A, user decision 2026-05-19): Commit 9a executes in parallel set ALPHA-EXPANDED before Commit 10. Commit 10 is the FIRST commit of the sequential tail (10 → 9b → 12). Commit 9b (D8.6 ref-update) lands AFTER Commit 10 because the D8.6 ref points to the project-side `project-template/docs/pack/OPTIONAL-FEATURES.md` file that Commit 10 creates.**

#### §2.10.2 — Files affected

ADDED:
- `project-template/docs/pack/OPTIONAL-FEATURES.md` (NEW; ~150-180 lines per B-fix §13.3 content-split sketch). Content tailored to project audience per Override 8 (not byte-identical to pack-side):
  - Intro paragraphs (ADAPT for project-PM voice)
  - `## Claude Code — Agent Teams` (ADAPT — project-side agent path examples like `.claude/agents/coder.md`)
  - `## Codex CLI — Optional features` (KEEP placeholder)
  - `## Gemini CLI — Optional features` (KEEP placeholder)
  - `## Tracker integration (v11)` (KEEP project-surface only; DROP pack-self-specific subsections; OMIT pack-tracker plumbing details per S3 TYPE-2 contamination avoidance; reference to `pack-ops/MERGE-STRATEGY.md` qualified with "in the pack repo" per Architect C prevention contract)
  - `## Adding new entries` (KEEP-OR-ADAPT — project-side framing)

MODIFIED:
- `scripts/init-project.sh` — add install stage: copy `project-template/docs/pack/OPTIONAL-FEATURES.md` → `<client>/docs/pack/OPTIONAL-FEATURES.md` during init. Per B-fix §13.4 step 3, the existing install-loop scaffolding likely already handles `project-template/docs/pack/*.md` files — coder verifies via grep; if loop already covers `*.md`, no special-casing needed; if not, add explicit install line.
- `supporting-docs/DEPENDENCIES.md:162` (D8.7) — REPLACE bare `OPTIONAL-FEATURES.md` reference with `docs/pack/OPTIONAL-FEATURES.md` (resolvable at client repos after SPLIT). Per A §3.5 D8.7 + Override 8 S2 fix-pass.

NOT MODIFIED (A4-A8 verify-only — no edits):
- `project-template/.gemini/commands/pack-help.toml:12` (A4) — `docs/pack/OPTIONAL-FEATURES.md` reference becomes LEGITIMATE post-SPLIT
- `project-template/.claude/skills/pack-help/SKILL.md:15` (A5) — same
- `project-template/.codex/skills/pack-help/SKILL.md:15` (A6) — same
- `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md:49` (A7) — bare `OPTIONAL-FEATURES.md` (relative to its directory) becomes resolvable post-SPLIT
- `project-template/docs/pack/HELP-FRAGMENT.md:6` + `:33` (A8) — same

MODIFIED (test-fixtures/manifest.txt):
- Regenerate per RC9 (project-template/ + scripts/ touched).

Total: 1 new file + 1 modified script + 1 modified supporting-docs + manifest = 4 files (+ A4-A8 NO-EDIT verification).

#### §2.10.3 — Coder-prompt sketch

Key inputs:
- `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` §13 (S3 content-split sketch — entire section including §13.1 section inventory, §13.2 audience analysis, §13.3 9-row content-split table, §13.4 Phase 5 coder guidance, §13.5 TYPE-2 contamination avoidance, §13.6 Override 8 citation)
- `ARCHITECTURE-DIRECTORY-REORGANIZATION.md` §4.5 (B's (b) SPLIT design — pack-side at `pack-ops/`, project-side at `project-template/docs/pack/`)
- `ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md` §6.1 TASK-T8 (per Override 8 — full SPLIT design)
- `AUDIT-USER-CURATION.md` Override 8 (CONFIRMED SPLIT — "one for pack. one for projects. There may be something common to both and maybe some individual to both")
- `pack-ops/OPTIONAL-FEATURES.md` (post-Commit-2 location — the STRUCTURE TEMPLATE source)

Key constraints:
- **NOT byte-identical mirror.** Per Override 8, the project-side file is tailored per audience; content overlap is acceptable where it serves both audiences, but each file is independently curated.
- **Apply B-fix §13.3 row-by-row** — for each of the 9 sections, classify as KEEP / ADAPT / DROP / OMIT per the table. Coder follows the table mechanically; this is NOT a content-design task (S3 fix-pass moved the design into the table to prevent P-missed-7 improvisation).
- **TYPE-2 contamination avoidance per §13.5** — do NOT copy pack-tracker plumbing details (validate-pack Check 22 mentions, STREAMS constant references, per-entry-tree contract details), pack-self surface mentions (pack-repo CWD, pack-side `tracker.toml.pack-example`), or unqualified `pack-ops/` path references into project-side file.
- **`init-project.sh` install stage:** verify existing install-loop already handles `project-template/docs/pack/*.md` files (likely yes — INSTALL-PROCEDURES.md and PM-CHAT.md are installed via this loop). If yes, no script edit needed (just confirm via grep + dry-run). If not, add explicit install line.
- **No byte-identity contract** between pack-side and project-side files (different from HELP-FRAGMENT-TRACKER.md Check 24 pattern; Check 24 does NOT extend to OPTIONAL-FEATURES.md).
- **5 project-side references (A4-A8) become LEGITIMATE post-SPLIT** — verify via grep that each reference resolves to the new file (e.g., `project-template/.claude/skills/pack-help/SKILL.md:15` says `docs/pack/OPTIONAL-FEATURES.md` which now exists at `project-template/docs/pack/OPTIONAL-FEATURES.md` and ships to clients via init-project.sh).
- **D8.7 in DEPENDENCIES.md** is a separate single-line edit in `supporting-docs/DEPENDENCIES.md:162` per A §3.5 D8.7.
- Manifest regen per RC9.
- Per pack-memory rule: PREFLIGHT + STOP-MEANS-STOP preamble injected by Pack Chat.

Output: 1 new project-template file + 1 modified script + 1 modified supporting-docs file + manifest; PREFLIGHT; IMPL-REPORT documents (a) per-section split-table decisions actually applied, (b) install-stage verification result, (c) D8.7 BEFORE/AFTER, (d) A4-A8 verify-only confirmations.

#### §2.10.4 — Verification steps

- `ls project-template/docs/pack/OPTIONAL-FEATURES.md` — file exists, ~150-180 lines
- `wc -l project-template/docs/pack/OPTIONAL-FEATURES.md` — line count in expected range
- Spot-read each major section; confirm project-side voice (project-PM perspective, client-repo CWD assumptions)
- `grep -n "STREAMS\|Check 22\|validate-pack" project-template/docs/pack/OPTIONAL-FEATURES.md` — ZERO hits (pack-tracker plumbing OMITTED per §13.5)
- `grep -n "tracker.toml.pack-example" project-template/docs/pack/OPTIONAL-FEATURES.md` — ZERO hits (pack-side example DROPPED per §13.3 row)
- `grep -n "pack-ops/" project-template/docs/pack/OPTIONAL-FEATURES.md` — hits (if any) MUST be qualified with "in the pack repo" per Architect C prevention contract (TYPE-4 guardrail); ideally ZERO hits except qualified MERGE-STRATEGY reference
- `grep -n "OPTIONAL-FEATURES" supporting-docs/DEPENDENCIES.md` — at L162 shows `docs/pack/OPTIONAL-FEATURES.md` (D8.7 post-edit)
- `bash scripts/init-project.sh --help` (or dry-run on a `/tmp` scratch repo) — confirms install stage works
- Verify A4-A8 references all resolve after SPLIT: grep each project-side ref location; confirm `docs/pack/OPTIONAL-FEATURES.md` is the expected target
- `bash test-fixtures/build.sh --all --clean && git diff test-fixtures/manifest.txt` — diff non-empty; stage
- CI PASS

#### §2.10.5 — Trinity implications

None directly. The new project-side `OPTIONAL-FEATURES.md` is a single-file project-side surface (not CLI-parallel — the file lives at `project-template/docs/pack/OPTIONAL-FEATURES.md` and serves all CLI variants via the shared PM-CHAT.md surface).

#### §2.10.6 — User-override anchoring

- **Override 8 (CONFIRMED SPLIT):** the entire premise of this commit. Cross-reference: B-fix §13 + §15 + §16 (S3 content-split sketch + summary); A-fix §10.3 (D8.6/D8.7/A4-A8 SPLIT cascade).
- **Override 9:** does not apply directly (Override 9 is about trinity P-missed-7 codification).

---

### §2.11 — Commit 11: Override 10 QUICKSTART ref removal (4 help files)

#### §2.11.1 — Scope

Per AUDIT-USER-CURATION.md Override 10 + B-fix §12.4 wording-removal design: REMOVE `docs/pack/QUICKSTART.md` references entirely (NOT retarget) from 4 help files (5 references total). The 3 pack-help CLI-parallel skill files form a trinity (Claude + Codex + Gemini); HELP-FRAGMENT.md joins the same commit for cohesion per B-fix §12.5.

User framing per Override 10: install docs (QUICKSTART) are pre-install pack-installer content; the 4 help files serve users using the pack INSIDE their project — they have no business pointing at install docs. The correct fix is REMOVAL of those references, not retargeting them.

#### §2.11.2 — Files affected

MODIFIED (trinity — 3 CLI-parallel pack-help skill files in lockstep + 1 HELP-FRAGMENT for cohesion):
- `project-template/.gemini/commands/pack-help.toml` line 10 (1 reference) — delete `docs/pack/QUICKSTART.md,` token; list shortens from 4 docs to 3 (PM-CHAT.md, INSTALL-PROCEDURES.md, OPTIONAL-FEATURES.md preserved)
- `project-template/.claude/skills/pack-help/SKILL.md` line 13 (1 reference) — same pattern; backticks preserved
- `project-template/.codex/skills/pack-help/SKILL.md` line 13 (1 reference) — same pattern (byte-identical to Claude file per current pack-help skill trinity)
- `project-template/docs/pack/HELP-FRAGMENT.md` line 4 (front-matter sentence, 1 reference — list shortens from 4 to 3) + line 31 (See-also section, 1 reference — list shortens from 6 to 5)

EXACT EDITS per B-fix §12.4 (BEFORE/AFTER for each file).

**File 1 — `project-template/.gemini/commands/pack-help.toml`** (B-fix §12.4.1):

BEFORE (lines 3-13):
```
prompt = """
The user wants to see the full pack verb list and colloquial
phrasings. Run the help script and present its output verbatim
to the user.

!{bash scripts/pack-help.sh}

For full documentation, see docs/pack/QUICKSTART.md,
docs/pack/PM-CHAT.md, docs/pack/INSTALL-PROCEDURES.md, and
docs/pack/OPTIONAL-FEATURES.md.
"""
```

AFTER:
```
prompt = """
The user wants to see the full pack verb list and colloquial
phrasings. Run the help script and present its output verbatim
to the user.

!{bash scripts/pack-help.sh}

For full documentation, see docs/pack/PM-CHAT.md,
docs/pack/INSTALL-PROCEDURES.md, and docs/pack/OPTIONAL-FEATURES.md.
"""
```

**File 2 — `project-template/.claude/skills/pack-help/SKILL.md`** (B-fix §12.4.2):

BEFORE (lines 11-16):
```
## Notes

For full documentation, see `docs/pack/QUICKSTART.md`,
`docs/pack/PM-CHAT.md`, `docs/pack/INSTALL-PROCEDURES.md`, and
`docs/pack/OPTIONAL-FEATURES.md`. The shell verb `pack help`
(LCD floor) prints the same content as this skill.
```

AFTER:
```
## Notes

For full documentation, see `docs/pack/PM-CHAT.md`,
`docs/pack/INSTALL-PROCEDURES.md`, and `docs/pack/OPTIONAL-FEATURES.md`.
The shell verb `pack help` (LCD floor) prints the same content as this skill.
```

**File 3 — `project-template/.codex/skills/pack-help/SKILL.md`** (B-fix §12.4.3):

Same as File 2 (byte-identical to Claude file per pack-help skill trinity convention).

**File 4 — `project-template/docs/pack/HELP-FRAGMENT.md`** (B-fix §12.4.4):

**Reference 1 of 2 (front-matter, lines 1-7):**

BEFORE:
```
# Pack v11 — verb reference (this project)

Verb manifest for **this project**. Run `pack help` or `/pack-help` in
your CLI for this content. Full docs in `docs/pack/QUICKSTART.md`,
`docs/pack/PM-CHAT.md`, `docs/pack/INSTALL-PROCEDURES.md`,
`docs/pack/OPTIONAL-FEATURES.md`.
```

AFTER:
```
# Pack v11 — verb reference (this project)

Verb manifest for **this project**. Run `pack help` or `/pack-help` in
your CLI for this content. Full docs in `docs/pack/PM-CHAT.md`,
`docs/pack/INSTALL-PROCEDURES.md`, `docs/pack/OPTIONAL-FEATURES.md`.
```

**Reference 2 of 2 (See also, lines 29-33):**

BEFORE:
```
## See also

`docs/pack/QUICKSTART.md`, `docs/pack/PM-CHAT.md`,
`docs/pack/METHODOLOGY.md`, `docs/pack/PLATFORM-SKILLS.md`,
`docs/pack/OPTIONAL-FEATURES.md`, `docs/project/BACKLOG.md`.
```

AFTER:
```
## See also

`docs/pack/PM-CHAT.md`, `docs/pack/METHODOLOGY.md`,
`docs/pack/PLATFORM-SKILLS.md`, `docs/pack/OPTIONAL-FEATURES.md`,
`docs/project/BACKLOG.md`.
```

NOT MODIFIED (per Override 10):
- `project-template/README.md` lines 16 + 39 — both correctly disambiguate "in the pack root" / pack-supporting-doc read; UNAFFECTED per Override 10
- `docs/project/BACKLOG.md` reference at HELP-FRAGMENT.md:33 — refers to PROJECT-side BACKLOG (`docs/project/BACKLOG.md` at client install) NOT the pack-side mirror; UNAFFECTED by Commit 2 M9 (which moved pack-side BACKLOG only)

MODIFIED (test-fixtures/manifest.txt):
- Regenerate per RC9 (project-template/ touched).

Total: 4 files + manifest = 5 files.

#### §2.11.3 — Coder-prompt sketch

Key inputs:
- `AUDIT-USER-CURATION.md` Override 10 (REMOVE direction; framing "install docs vs in-project help docs")
- `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` §12.4.1 + §12.4.2 + §12.4.3 + §12.4.4 (BEFORE/AFTER for each file per architect's wording-removal design)
- `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` §12.5 (trinity rule compliance — 3 CLI files in lockstep + HELP-FRAGMENT for cohesion)
- `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` §12.7 (net effect — Phase 5 coder mechanical wording edit)

Key constraints:
- **Mechanical edit** — delete the `docs/pack/QUICKSTART.md` token (with trailing comma + space) per file; preserve all other doc references intact
- **Trinity rule for 3 CLI files** (pack-help.toml + .claude/.../SKILL.md + .codex/.../SKILL.md) — single commit, lockstep edits, post-edit symmetry verified: all 3 reference exactly 3 docs (PM-CHAT.md + INSTALL-PROCEDURES.md + OPTIONAL-FEATURES.md) — same 3 docs, same order
- **HELP-FRAGMENT.md joins for cohesion** per B-fix §12.5 (not byte-trinity but same surface, same Override 10 directive)
- **README.md NOT touched** per Override 10 (both lines 16 + 39 are already correct)
- **`docs/project/BACKLOG.md` in HELP-FRAGMENT.md:33 NOT touched** — refers to project-side BACKLOG, unaffected by Commit 2's pack-side BACKLOG move
- Manifest regen per RC9
- PREFLIGHT + STOP-MEANS-STOP

Output: 4 modified files + manifest; PREFLIGHT; IMPL-REPORT shows per-file BEFORE/AFTER context.

#### §2.11.4 — Verification steps

- `grep -n "docs/pack/QUICKSTART" project-template/.gemini/commands/pack-help.toml project-template/.claude/skills/pack-help/SKILL.md project-template/.codex/skills/pack-help/SKILL.md project-template/docs/pack/HELP-FRAGMENT.md` — ZERO hits across all 4 files
- `diff project-template/.claude/skills/pack-help/SKILL.md project-template/.codex/skills/pack-help/SKILL.md` — empty diff (trinity byte-identity for these two — both should have identical "Notes" section post-edit)
- `grep -c "docs/pack/" project-template/.gemini/commands/pack-help.toml` — returns 3 (3 doc references remain: PM-CHAT, INSTALL-PROCEDURES, OPTIONAL-FEATURES)
- `grep -c "docs/pack/" project-template/.claude/skills/pack-help/SKILL.md` — returns 3
- `grep -c "docs/pack/" project-template/.codex/skills/pack-help/SKILL.md` — returns 3
- `grep -n "docs/pack/" project-template/docs/pack/HELP-FRAGMENT.md` — front-matter: 3 docs; See-also: 4 docs (PM-CHAT + METHODOLOGY + PLATFORM-SKILLS + OPTIONAL-FEATURES) + 1 docs/project/ (the project-side BACKLOG ref); total = 7 hits
- Trinity Check 18 H2 parity PASS (pack-help skill trinity now symmetric across .claude + .codex variants for the post-edit content; .gemini variant is a .toml not .md, so trinity contract per pack-help skill cross-CLI parity per the existing convention)
- `bash test-fixtures/build.sh --all --clean && git diff test-fixtures/manifest.txt` — stage manifest
- CI PASS

#### §2.11.5 — Trinity implications

- **Pack-help skill trinity:** 3 CLI-parallel files (.claude / .codex / .gemini) edited in lockstep. Post-edit symmetry: all 3 reference the same 3 docs (PM-CHAT + INSTALL-PROCEDURES + OPTIONAL-FEATURES). The .gemini file is `.toml` (not `.md`); the trinity rule applies to wording-content parity, not file-extension matching, per the existing pack-help skill convention.
- **HELP-FRAGMENT.md** is not CLI-parallel (single project-side file); joins the commit for cohesion (same Override 10 directive, same wording-removal pattern).

#### §2.11.6 — User-override anchoring

- **Override 10:** REMOVE direction is the entire premise. The 4 files affected match the 5 references identified by the M3 reviewer cascade. Architect B's call HOW to reword is the per-file BEFORE/AFTER above; user's call is the REMOVE direction.
- **Override 7:** indirect — Override 7 keeps QUICKSTART.md at root (no SPLIT), which is why these 4 help-file references would break if not removed (the project-side `docs/pack/QUICKSTART.md` is NEVER created per Override 7's NO-SPLIT direction). Override 10 closes the cascade Override 7 opened.
- Cross-reference: B-fix §12.7 confirms no S1 commit lands anywhere; this commit closes the dangling refs.

---

### §2.12 — Commit 12: prevention mechanisms (Architect C M1-M8)

#### §2.12.1 — Scope

The final commit. Implements Architect C's entire prevention mechanism suite per C's §13 order-of-land:
- **M2** P-missed-7 codification in pack-root trinity Pack memory + project-template trinity Project memory (per Override 9 — different wording per audience, no cross-trinity parity gate)
- **M4** boundary-investigation skill (new pack skill across all 3 CLI variants pack-side + 3 CLI variants project-side; loaded by all 5 pack-* agents)
- **M3a** pack-reviewer SSOT-investigation protocol amendment + review skill priority-0 addition
- **M3b** pack-coder pre-flight Boundary discipline section + project-side coder.md Constraints addition
- **M6** SSOT-rotation reminder (included in M3a/M3b prompts; no separate commit)
- **M7** TYPE-5 positive-assertion gate (extension to M3a dimension 9)
- **M1a** Pack Chat batch-scope memory rule (added to pack-root trinity Pack memory § Pack Chat scope)
- **M1b** commit-subject scope-keyword convention (documented in pack-root trinity)
- **M5a Check 36** commit-scope honesty check (new validate-pack.py check; PM-only PERMITTED-PATHS regex per C §8.1a consuming `pack-ops/.boundary-exempt-root.txt` 1-entry list)
- **M5b Check 37** project-side pack-only-reference deny-list check (new validate-pack.py check; deny-list includes `pack-ops/` path-prefix per M2 amendment + symmetric pack-side P-missed-7 expansion)
- **M5c Check 38** pack-only-file siting check (new validate-pack.py check; consumes 1-entry exemption list per M4 amendment)
- **M8** trinity-rule documentation amendment (informational, not enforced; added to pack-root CLAUDE.md § "Rules for agents working on this repo" trinity-rule bullet per C §9.2)

This commit lands LAST per C §13 order-of-land + bootstrap incompatibility note (§8.2): M5b Check 37 deny-list would fail at HEAD if landed before Architect A's contamination fixes (Commits 4-9) resolve the 17 §D-9 confirmed contamination refs.

#### §2.12.2 — Files affected

MODIFIED (pack-root trinity — 3 files in lockstep):
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md` § Pack memory `### Workflow` — add P-missed-7 bullet per C §4 (full text in C's design); § Pack memory `### Pack Chat scope` — add M1a Batch-scope claims bullet per C §10.1; § "Rules for agents working on this repo" trinity-rule bullet — add M8 explanatory note per C §9.2
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/AGENTS.md` parallel edits
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/GEMINI.md` parallel edits

MODIFIED (project-template trinity — 3 files in lockstep):
- `project-template/CLAUDE.md` § Project memory — add "Project SSOT-first" bullet per C §4.2 (with `pack-ops/` path-prefix included per S5 — "pack-repo pack-ops/ — any file under pack-ops/, including BOUNDARY-DEFINITION.md, BACKLOG.md, CHANGELOG.md, etc. post Architect B + B-fix")
- `project-template/AGENTS.md` parallel
- `project-template/GEMINI.md` parallel

Per Override 9: the pack-side P-missed-7 bullet and the project-side "Project SSOT-first" mirror are INTENTIONALLY DIFFERENT in wording. Detailed pack-side bullet (worked examples V1/V3/V4) vs shorter inverted project-side mirror (project SSOT is the starting point). No cross-trinity drift gate.

ADDED (boundary-investigation skill — 6 files total, 3 pack-side + 3 project-side per trinity skill convention):
- `.claude/skills/boundary-investigation/SKILL.md` (pack-side)
- `.codex/skills/boundary-investigation/SKILL.md` (pack-side)
- `.gemini/skills/boundary-investigation/SKILL.md` (pack-side) — note .gemini may use `.toml` per pack-startup pattern; coder follows existing pack-skill trinity shape conventions
- `project-template/.claude/skills/boundary-investigation/SKILL.md` (project-side; ships to clients via init-project.sh)
- `project-template/.codex/skills/boundary-investigation/SKILL.md` (project-side)
- `project-template/.gemini/skills/boundary-investigation/SKILL.md` (project-side; or `.gemini/commands/boundary-investigation.toml` if that's the existing convention)

Content per C §6 (skill methodology, when-this-applies, deny-list including post-B `pack-ops/` path-prefix per M2 amendment, worked example based on V1 anti-pattern).

MODIFIED (pack-* agent skill-load tables):
- `pack-ops/PACK-AGENTS.md` (post-Commit-2 location) § "Skills loaded by pack agents" — add `boundary-investigation` to: pack-architect, pack-coder, pack-planner, pack-reviewer, pack-docs-researcher

MODIFIED (pack-side review skill — 3 CLI variants):
- `.claude/skills/review/SKILL.md` — add priority-0 Boundary discipline per C §5.1
- `.codex/skills/review/SKILL.md` — same
- `.gemini/skills/review/SKILL.md` (if exists; or .gemini/commands/review.toml per convention) — same

MODIFIED (pack-coder agent — 3 CLI variants):
- `.claude/agents/pack-coder.md` — add Boundary discipline pre-flight section per C §5.2
- `.codex/agents/pack-coder.toml` — same
- `.gemini/agents/pack-coder.md` — same

MODIFIED (project-side reviewer + coder prompts):
- `project-template/docs/pack/prompts/reviewer.md` (standard variant) — add dimension 9 per C §5.1 + M7 positive-assertion extension per C §9.1
- `project-template/docs/pack/prompts/coder.md` (standard variant) — add Boundary discipline (P-missed-7) Constraints block per C §5.2

MODIFIED (`scripts/validate-pack.py` — new Checks 36 + 37 + 38):
- Check 36 (commit-scope honesty) per C §8.1 + §8.1a — parses commit subjects for `pack-only` / `project-only` / `PM-only` keywords; compares against `git diff --name-only`; PM-only PERMITTED-PATHS regex consumes `pack-ops/.boundary-exempt-root.txt` 1-entry list; PERMITS project-template trinity per PACK-AGENTS.md:148 (post-B1+S6 cascade); test fixtures include PASS for PM-only touching project-template trinity + FAIL for PM-only touching supporting-docs/ + standard pack-only/project-only fixtures
- Check 37 (project-side deny-list) per C §8.2 — walks project-template/ files; greps for deny-list patterns including `pack-ops/` path-prefix per M2 amendment + anchor-phrase exception for LEGITIMATE Pack Chat feedback-flow context per audit §D-4
- Check 38 (pack-only-file siting) per C §8.3 — per-file pack-only-signal-count threshold check; consumes 1-entry exemption list

MODIFIED (existing `scripts/validate-pack.py` headers / counters — Check 36/37/38 added):
- Update the per-check count in CLI output (Check 36, 37, 38 added; total check count increases)
- Update Check 18 H2 parity to NOT enforce cross-trinity parity (the P-missed-7 bullets at pack-root vs project-template trinity differ per Override 9 — Check 18 only enforces WITHIN-trinity parity across CLI files at each trinity location)

ADDED (test fixtures for Checks 36/37/38):
- `scripts/tests/test-validate-pack-checks-36-37-38.sh` — regression test scripts per C §12 measurable tests
- `test-fixtures/` synthetic fixtures for the three checks (per C §8.1/§8.2/§8.3 test plans)

MODIFIED (test-fixtures/manifest.txt):
- Regenerate per RC9 (extensive project-template/ + scripts/ + .claude/skills/ + .codex/skills/ + .gemini/ surfaces touched).

Total: ~30+ files (6 trinity + 6 boundary-investigation + 3 review skills + 3 pack-coder + 1 reviewer prompt + 1 coder prompt + 1 PACK-AGENTS.md + scripts/validate-pack.py + scripts/tests/ + test-fixtures/ + manifest).

#### §2.12.3 — Coder-prompt sketch

Key inputs the coder reads:
- `ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md` §3 (master coverage matrix), §4 + §4.1 + §4.2 (M2 P-missed-7 codification per Override 9 — full bullet text + project-side mirror text), §5 + §5.1 + §5.2 (M3a + M3b protocol amendments), §6 (M4 boundary-investigation skill content sketch + skill-loading table), §7 (M6 SSOT-rotation reminder), §8 + §8.1 + §8.1a + §8.2 + §8.3 (M5a Check 36 + M5b Check 37 + M5c Check 38 implementations with PERMITTED-PATHS regex + deny-list + bootstrap incompatibility note), §9.1 (M7 positive-assertion gate), §9.2 (M8 trinity-rule documentation amendment), §10.1 + §10.2 (M1a memory rule + M1b commit-subject scope-keyword convention), §11 (conditional dependencies on Architect B — post-B+B-fix paths), §13 (order-of-land), §16 (fix-pass amendments: M2 + M4 + B1-cascade + S4 + S5 + S6 + line 584 staleness fix per §16a)
- `AUDIT-USER-CURATION.md` Override 9 (different audience = different wording; no cross-trinity drift gate)
- `PACK-AGENTS.md:142-148` (authoritative PM-only Files list for Check 36 PM-only keyword PERMITTED-PATHS regex)
- `pack-ops/.boundary-exempt-root.txt` (1-entry list for Check 36 / 38 allow-list)

Key constraints:
- **Override 9 strict:** pack-side P-missed-7 bullet and project-side "Project SSOT-first" bullet INTENTIONALLY DIFFER. NO cross-trinity drift gate. Within-trinity parity (Check 18 H2 across CLI files at each trinity location) continues to apply.
- **Trinity rule** for pack-root trinity edits (3 CLI files) AND project-template trinity edits (3 CLI files) — but the wording AT the two trinity locations differs by design.
- **PM-only keyword regex permits project-template trinity** per PACK-AGENTS.md:148 (post-B1 cascade fix) — explicit PASS fixture for PM-only commits touching project-template trinity.
- **Deny-list includes `pack-ops/`** per M2 amendment — both Check 37 (project-side grep) and M4 skill methodology (deny-list step 4).
- **1-entry exemption list** per M4 amendment — Check 36/38 consume 1-entry, NOT 3-entry.
- **Bootstrap order:** Check 37 lands LAST in this commit; previous commits 4-9 must have resolved all 17 §D-9 contamination refs. Coder confirms via grep on project-template/ before staging Check 37 — if any contamination refs remain (would indicate Commits 4-9 didn't land or had partial coverage), STOP and report.
- **Boundary-investigation skill loaded by ALL 5 pack-* agents** per PACK-AGENTS.md skill-load table update.
- **Project-side skill trinity:** skill ALSO ships to `project-template/.claude/skills/boundary-investigation/`, `.codex/`, `.gemini/` parallels per C §6 closing paragraph (Trinity Pack memory "Skill and agent maintenance is mechanical by default" pattern).
- **Check 36 / 37 / 38 test fixtures** added in same commit per C §12 measurable tests.
- Manifest regen per RC9 (extensive v11-surface touch).
- PREFLIGHT + STOP-MEANS-STOP.

Output: ~30+ files modified or added + manifest; PREFLIGHT; IMPL-REPORT documents each mechanism's landed surface, the 3 new validate-pack checks' implementations, fixture additions, and a verification table cross-referencing each mechanism to its measurable test result (per C §12).

#### §2.12.4 — Verification steps

- `bash scripts/validate-pack.py` — all checks PASS including the 3 new Checks 36/37/38
- Check 36 fixtures PASS: PM-only + project-template/CLAUDE.md → PASS (per B1 cascade fix); PM-only + supporting-docs/ → FAIL with file:path callout
- Check 37: grep on project-template/ for deny-list patterns returns ZERO hits except LEGITIMATE-context-anchored references; specifically the 17 §D-9 contamination refs from audit are all resolved (Commits 4-9 closed them)
- Check 38: 1-entry exemption list consumed correctly; no C2 file at root other than `tracker.toml.pack-example` triggers FAIL
- `bash scripts/tests/test-validate-pack-checks-36-37-38.sh` (new fixture test) — PASS
- Boundary-investigation skill files exist at 6 paths (3 pack-side + 3 project-side)
- pack-* agent skill-load table in `pack-ops/PACK-AGENTS.md` lists `boundary-investigation` for all 5 agents
- Pack-root trinity § Pack memory contains P-missed-7 bullet + M1a batch-scope claims bullet (all 3 CLI files in lockstep per Check 18 within-trinity parity)
- Project-template trinity § Project memory contains "Project SSOT-first" bullet (all 3 CLI files in lockstep)
- M8 trinity-rule documentation amendment present in pack-root CLAUDE.md (informational note)
- `bash test-fixtures/build.sh --all --clean && git diff test-fixtures/manifest.txt` — stage manifest
- CI Validate Pack PASS with new checks enabled
- Trinity Check 18 H2 parity: PASS for within-trinity; NO cross-trinity drift gate applied (per Override 9)
- Spot-check: ALL 13 audit boundary violations (V1-V12 + T5-A + T5-B + V8) + ALL 17 §D-9 contamination refs are resolved at HEAD (cross-check the per-finding reviewer-checks)

#### §2.12.5 — Trinity implications

- **Pack-root trinity (3 files lockstep):** P-missed-7 bullet + M1a Batch-scope bullet + M8 trinity-rule documentation note
- **Project-template trinity (3 files lockstep):** "Project SSOT-first" mirror bullet
- **Pack-side boundary-investigation skill trinity (3 CLI variants in lockstep):** new pack skill
- **Project-side boundary-investigation skill trinity (3 CLI variants in lockstep):** new project-side skill
- **Pack-side review skill trinity (3 CLI variants in lockstep):** priority-0 Boundary discipline addition
- **Pack-coder agent trinity (3 CLI variants in lockstep):** Boundary discipline pre-flight section
- **NO cross-trinity drift gate per Override 9** — pack-side P-missed-7 wording differs from project-side "Project SSOT-first" wording BY DESIGN; reviewer does not flag this as drift

#### §2.12.6 — User-override anchoring

- **Override 9 (CONFIRMED):** the two-tier codification authority — pack-side detailed bullet + project-side shorter inverted mirror; NO cross-trinity drift gate. Cross-reference: C §4.1 + C-fix §16.4.
- **Override 1 + Override 5 (cascade):** 1-entry exemption list (only `tracker.toml.pack-example`); Check 36/38 consume 1-entry, NOT 3-entry. Cross-reference: C §11 + C-fix §16.2 + B-fix §4.
- **Override 6:** indirect — Check 37 deny-list includes `pack-ops/` path-prefix per M2 amendment + S5 (project-side mirror); the `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` path is one of many under the `pack-ops/` umbrella.
- **B1 cascade (BLOCKER):** Check 36 PM-only keyword PERMITS project-template trinity per PACK-AGENTS.md:148. Cross-reference: A-fix §10.1 + C-fix §16.3.

---

## §3 — Coder spawn breakdown

Per pack-memory "each pack-coder commit gets a FRESH coder instance — never reuse a coder across commits, even within a stage": **13 FRESH pack-coder spawns total** (Path A per OQ-1 RESOLVED). Pack Chat orchestrates each spawn with the per-commit prompt sketch from §2 above (PREFLIGHT + STOP-MEANS-STOP preamble injected by Pack Chat per pack-memory). Spawns 4, 5, 6, 7, 8, 9a, 11 launch CONCURRENTLY (parallel set ALPHA-EXPANDED per §8.2) after Commit 3 lands; spawns 9b, 10, 12 are sequential tail.

| Spawn # | Commit # | Coder prompt anchor (architect doc + section) | Per-spawn inputs (key reads) | Per-spawn outputs |
|---|---|---|---|---|
| 1 | 1 | ARCHITECTURE-DIRECTORY-REORGANIZATION.md §5.3 (BOUNDARY-DEFINITION doc structure) + §3.3 (machine-readable exemption list format) + B-fix §4 (1-entry list per Overrides 1+5) | B §1.1 + §1.2 (verbatim source for new doc §2 + §3); B §4 (verbatim for §5); B §5.2 (verbatim for §6); AUDIT-USER-CURATION.md Overrides 1+5; B-fix §4 | 2 NEW files: `pack-ops/BOUNDARY-DEFINITION.md` (~250-350 lines) + `pack-ops/.boundary-exempt-root.txt` (1-entry); IMPL-REPORT documenting architect sources per section |
| 2 | 2 | **ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md §7.1 Option A (MANDATE) + §10.3 (per-file line-numbered edits)** + B §3.2 (detect.sh migration) + B §6.6 (validate-pack.py constants) + PACK-REVIEW-PHASE-2-DESIGNS.md M1 (Option A enforcement) | B-fix §6.1-§6.6 (LIVE pack-internal / LIVE auto-detection / LIVE cross-reference docs / FROZEN archive / FROZEN project-side); B §6.5 (grep + sed plan per MOVES file); pack-memory RC9 | 7 git-mv files + ~45 modified files (scripts/, pack-root trinity, pack-* agents, pack-startup skill, README, pack-ops/PACK-AGENTS.md self-ref) + manifest; IMPL-REPORT documenting per-file edits + manifest regen output + full validate-pack pass |
| 3 | 3 | ARCHITECTURE-DIRECTORY-REORGANIZATION.md §4.1 (F-1 resolution) + B-fix §11.3 step 3 (Commit C — all 3 supporting-docs → pack-ops/) + B-fix §16 (Override 6 cascade closure) | AUDIT-USER-CURATION.md Override 6; B §6.5 M6+M7+M8 grep plans; B-fix §6.5 (live-vs-archive triage) | 3 git-mv files + 2-3 scripts + 1-3 live maintenance-docs/v11-implementation/ refs + manifest; IMPL-REPORT documenting per-script and per-cross-reference edits |
| 4 | 4 | ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md §2 V1 + §2 T5-A + §2 V8 + §6.1 TASK-T1 (combined commit) | A §2 V1 Implementation hint (BEFORE/AFTER); A §2 T5-A (coupled to V1); A §2 V8 Implementation hint (delete italicized paragraph) | 3 project-template trinity files (CLAUDE/AGENTS/GEMINI) + manifest; IMPL-REPORT showing per-file BEFORE/AFTER for both hunks |
| 5 | 5 | ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md §2 V3 (V3.a + V3.b in one file in one commit) | A §2 V3 Implementation hint for both L251 + L572 sites | 1 modified file (PLATFORM-SKILLS.md) + manifest; IMPL-REPORT showing both hunks |
| 6 | 6 | ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md §2 V7 (L51 + L106 REVERT) | A §2 V7 Implementation hint | 1 modified file (audit-methodology SKILL.md) + manifest; IMPL-REPORT |
| 7 | 7 | ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md §2 V6 (V6.a + V6.b + V6.c — 5 edits in one file) | A §2 V6 Implementation hint for all sites | 1 modified file (MIGRATION-v10-to-v11.md, NO manifest — supporting-docs/ not v11-surface); IMPL-REPORT showing all 5 edits |
| 8 | 8 | ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md §4 A2 (METHODOLOGY.md:1509 REPLACE) | A §4 A2 Implementation hint | 1 modified file (METHODOLOGY.md, NO manifest); IMPL-REPORT |
| 9a | 9a | ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md §2 V5 PRIMARY (audience header ONLY); this plan §2.9a (Path A first-half partition per OQ-1 RESOLVED) | A §2 V5 PRIMARY; B-fix §13 (S3 context for OPTIONAL-FEATURES SPLIT awareness — relevant to D8.6 dependency on Commit 10) | 1 modified file (pack-ops/MERGE-STRATEGY.md, NO manifest — pack-ops/ not v11-surface); IMPL-REPORT showing audience-header-only edit + verify L465 unchanged (D8.6 lands in 9b) |
| 9b | 9b | ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md §3.5 D8.6 (REPLACE bare `OPTIONAL-FEATURES.md` with `docs/pack/OPTIONAL-FEATURES.md` per Override 8 S2 SPLIT); this plan §2.9b (Path A second-half partition per OQ-1 RESOLVED) | A §3.5 D8.6 amendment (S2 cascade); verify `project-template/docs/pack/OPTIONAL-FEATURES.md` exists at HEAD (Commit 10 already landed) | 1 modified file (pack-ops/MERGE-STRATEGY.md, NO manifest — pack-ops/ not v11-surface); IMPL-REPORT showing single-hunk D8.6 ref-update |
| 10 | 10 | ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md §13 (S3 content-split sketch — entire §13.1-§13.6) + B §4.5 (b) (SPLIT design) + A §6.1 TASK-T8 (per Override 8) | AUDIT-USER-CURATION.md Override 8; pack-ops/OPTIONAL-FEATURES.md (post-Commit-2 source); B-fix §13.3 row-by-row content split; B-fix §13.5 TYPE-2 avoidance | 1 NEW project-template file (~150-180 lines) + 1 modified script (init-project.sh install stage if needed) + 1 modified supporting-docs file (DEPENDENCIES.md:162) + manifest; IMPL-REPORT documenting per-section split decisions + install-stage verification + D8.7 BEFORE/AFTER + A4-A8 verify-only |
| 11 | 11 | AUDIT-USER-CURATION.md Override 10 + ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md §12.4 (per-file BEFORE/AFTER) + §12.5 (trinity rule compliance) + §12.7 (net effect) | Override 10 REMOVE direction; B-fix §12.4.1 + §12.4.2 + §12.4.3 + §12.4.4 per-file wording-removal | 4 modified files (3 CLI-parallel pack-help skill files in lockstep + HELP-FRAGMENT.md cohesion) + manifest; IMPL-REPORT showing per-file BEFORE/AFTER context |
| 12 | 12 | ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md (entire C design + §16 fix-pass) + AUDIT-USER-CURATION.md Override 9 + PACK-AGENTS.md:142-148 (PM-only list) | C §3 master coverage matrix; C §4 + §4.1 + §4.2 (M2 codification); C §5 + §5.1 + §5.2 (M3a + M3b); C §6 (M4 skill); C §7 (M6 reminder); C §8 + §8.1 + §8.1a + §8.2 + §8.3 (M5a/b/c Checks 36/37/38); C §9.1 (M7); C §9.2 (M8); C §10 (M1a + M1b); C §11 (post-B+B-fix conditional surfaces); C §13 (order-of-land); C §16 (fix-pass amendments); Override 9 (no cross-trinity drift) | ~30+ files: pack-root trinity (P-missed-7 + M1a + M8) + project-template trinity (Project SSOT-first) + 6 boundary-investigation skill files (3 pack-side + 3 project-side) + pack-* agent skill-load table + 3 review skill priority-0 + 3 pack-coder pre-flight + reviewer prompt dimension 9 + coder prompt Constraints + scripts/validate-pack.py 3 new Checks (36/37/38) + scripts/tests/ new fixture script + test-fixtures fixtures + manifest; IMPL-REPORT cross-referencing each mechanism to its measurable test result (per C §12) |

**No coder reuse across commits.** Each of the 13 commits gets a fresh pack-coder per pack-memory rule. Pack Chat closes the prior coder session AFTER the commit lands; spawns a NEW coder for the next commit. This is non-negotiable per the pack-memory "fresh coder instance" contract. **Parallel-set ALPHA-EXPANDED:** 7 fresh coder spawns launch CONCURRENTLY via the Agent-tool `run_in_background:true` pattern per pack-memory; Pack Chat triages IMPL-REPORTs as they return and commits SERIALLY using the git-stash isolation pattern per §8.7.

---

## §4 — Verification gates

Map each commit to the verification surface it must pass before Pack Chat stages and commits.

### §4.1 — Per-commit `bash scripts/validate-pack.py` checks

| Commit | Critical validate-pack checks |
|---|---|
| 1 | All currently-enabled checks PASS (no new checks expect `pack-ops/` to exist yet; the dir is invisible to existing checks) |
| 2 | Check 3 (pack-side BACKLOG at new path); Check 22 (Help-fragment freshness with new surface paths); Check 24 (HELP-FRAGMENT-TRACKER byte-identity between `pack-ops/` + `project-template/docs/pack/`); Check 32 (mirror-in-sync — SKIPS pre-Batch-23 per per-entry forward-pointing note); Check 35 (other surface check). Trinity Check 18 H2 parity for pack-root trinity edits. |
| 3 | All checks PASS; no specific check directly validates supporting-docs→pack-ops moves but Check 22/24 paths from Commit 2 must still resolve |
| 4 | Trinity Check 18 H2 parity PASS for project-template trinity edits (V1+T5-A+V8 in lockstep across 3 CLI files) |
| 5 | All checks PASS; Check 22 surfaces dict for project-template surface verifies PLATFORM-SKILLS.md changes |
| 6 | All checks PASS |
| 7 | All checks PASS (no v11-surface impact — supporting-docs not in any check's surface dict) |
| 8 | All checks PASS (no v11-surface impact) |
| 9a | All checks PASS (no v11-surface impact — pack-ops/ not in any check's surface dict at HEAD pre-Commit-12; Check 37 not yet enabled). Trinity Check 18 N/A (no trinity surface). |
| 9b | All checks PASS (no v11-surface impact). Single-hunk D8.6 ref-update at L465 only. |
| 10 | All checks PASS; Check 22 surfaces dict for project-template surface verifies new OPTIONAL-FEATURES.md doesn't break verb-freshness |
| 11 | Trinity Check 18 H2 parity for pack-help skill trinity (3 CLI-parallel files in lockstep); Check 22 surfaces dict for project-template surface verifies HELP-FRAGMENT.md changes |
| 12 | **All currently-enabled checks PASS including the 3 new Checks 36/37/38.** Check 36 PM-only fixture: PM-only + project-template/CLAUDE.md → PASS; PM-only + supporting-docs/ → FAIL. Check 37 deny-list grep on project-template/ → ZERO contamination hits (Commits 4-9 closed all 17 §D-9 refs). Check 38 1-entry exemption list verified. Trinity Check 18 H2 parity for within-trinity-location (pack-root + project-template separately); NO cross-trinity drift gate per Override 9. |

### §4.2 — Per-commit `bash test-fixtures/build.sh --all --clean` + manifest verify (for v11-surface commits)

| Commit | Manifest regen | Why |
|---|---|---|
| 1 | N (Pack Chat may run + confirm zero diff per RC9 inclusive trigger, but not strictly required) | pack-ops/ files outside `project-template/` and `scripts/` |
| 2 | **Y MANDATORY** | scripts/ + project-template/ trinity touched; v11-* SHAs drift |
| 3 | **Y MANDATORY** | scripts/migrate-v10-to-v11.sh + scripts/dry-run-migration.sh touched |
| 4 | **Y MANDATORY** | project-template/ trinity touched |
| 5 | **Y MANDATORY** | project-template/ touched |
| 6 | **Y MANDATORY** | project-template/ touched |
| 7 | N | supporting-docs/ not v11-surface per RC9 base case |
| 8 | N | supporting-docs/ not v11-surface |
| 9a | N | pack-ops/ not v11-surface per RC9 base case |
| 9b | N | pack-ops/ not v11-surface per RC9 base case (single-hunk D8.6 ref-update) |
| 10 | **Y MANDATORY** | project-template/ + scripts/init-project.sh touched |
| 11 | **Y MANDATORY** | project-template/ touched |
| 12 | **Y MANDATORY** | Extensive project-template/ + scripts/ + .claude/skills/ etc touched |

**RC9 process per pack-memory:** for Y commits, `bash test-fixtures/build.sh --all --clean` then `git diff test-fixtures/manifest.txt` — if non-empty, `git add test-fixtures/manifest.txt` and stage in the SAME commit. Skipping reproduces the 2026-05-17 incident pattern (CI `fixture manifest verify` step fails alone with all functional tests passing).

### §4.3 — Trinity Check 18 (CI parity) — for trinity-touched commits

| Commit | Trinity touched | Check 18 parity expectation |
|---|---|---|
| 2 | Pack-root trinity (CLAUDE/AGENTS/GEMINI lines 30-31 + 83 + 99 + 389); pack-* agents (5 × 3 CLI); pack-startup skill (3 CLI) | Within-trinity-location parity at pack-root (all 3 pack-root trinity files have identical edits) |
| 4 | Project-template trinity (CLAUDE/AGENTS/GEMINI L366/343/356 + L397/374/387) | Within-trinity-location parity at project-template (all 3 project-template trinity files have identical edits) |
| 11 | Pack-help skill trinity (.claude + .codex + .gemini) | Cross-CLI parity for pack-help skill (post-edit symmetry: all 3 reference same 3 docs) |
| 12 | Pack-root trinity (P-missed-7 + M1a + M8); project-template trinity (Project SSOT-first); boundary-investigation skill trinity (pack-side AND project-side; 3 CLI each); review skill trinity (3 CLI); pack-coder agent trinity (3 CLI) | Within-trinity-location parity per surface; **NO cross-trinity drift gate per Override 9** (pack-side P-missed-7 wording differs from project-side "Project SSOT-first" wording BY DESIGN) |

### §4.4 — CI workflow check (every push)

Each commit triggers `Validate Pack` GitHub Actions workflow per pack-memory "CI validation: The Validate Pack GitHub Actions workflow runs on every push. If it fails, fix before proceeding." Pack Chat orchestrates background CI monitoring; per pack-memory hint, use `gh run list` via Bash for workflow status.

**Chosen orchestration patterns per user decision 2026-05-19:**
- **CI cascade: push-then-wait** for the parallel set ALPHA-EXPANDED batch — Pack Chat commits each member serially, pushes, waits CI green (`gh run list --branch v11-dev --limit 10 --json status,conclusion,headSha`), then commits the next. See §8.6 for details.
- **Manifest regen: git-stash isolation pattern** per §8.7 — Pack Chat stashes other coders' unstaged working-tree edits before each Y-marked commit's `bash test-fixtures/build.sh --all --clean`, then `git stash pop` after committing.

If a commit fails CI:
- DO NOT amend the commit (per pack-memory git-state-change rule + "Always create NEW commits rather than amending")
- Pack Chat reads CI log; identifies the failed check; spawns fresh pack-coder with corrective task; lands fix as NEW commit with `fix: v11 — BD-175 ... (Batch ...)` form per CLAUDE.md approved suffixes
- Per pack-memory "review/fix cycles per BD AND per batch": each commit's failure follows the inline per-BD review/fix pattern

### §4.5 — Per-commit grep audits

| Commit | Specific grep audit (post-coder, pre-Pack-Chat-commit) |
|---|---|
| 2 | `grep -rn "PACK-CHAT.md\|PACK-AGENTS.md\|HELP-FRAGMENT-PACK.md\|HELP-FRAGMENT-TRACKER.md\|OPTIONAL-FEATURES.md\|BACKLOG.md\|CHANGELOG.md" scripts/ .claude/ .codex/ .gemini/ CLAUDE.md AGENTS.md GEMINI.md README.md --include="*.sh" --include="*.py" --include="*.md" --include="*.toml"` — only `pack-ops/`-qualified paths remain for these files; bare-root references gone |
| 3 | `grep -rn "supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY\|supporting-docs/DRY-RUN-MIGRATION\|supporting-docs/MERGE-STRATEGY" . --exclude-dir=.git --exclude-dir=archive --exclude-dir=node_modules` — only architect-doc historical `Before:` refs remain; ZERO LIVE refs |
| 4 | `grep -n "PACK-AGENTS\|TOOL-COMPARISON\|maintenance-docs" project-template/CLAUDE.md project-template/AGENTS.md project-template/GEMINI.md` — ZERO hits |
| 5 | `grep -n "PACK-AGENTS\|maintenance-docs" project-template/docs/pack/PLATFORM-SKILLS.md` — ZERO hits |
| 6 | `grep -rn "maintenance-docs/" project-template/skills/` — ZERO hits |
| 7 | `grep -n "Pack Chat\|maintenance-docs" supporting-docs/MIGRATION-v10-to-v11.md` — Pack-Chat hits ONLY in LEGITIMATE feedback-flow contexts (verify per audit §D-4 LEGITIMATE designation); maintenance-docs ZERO |
| 8 | `grep -n "maintenance-docs/" supporting-docs/METHODOLOGY.md` — ZERO hits |
| 9a | `head -25 pack-ops/MERGE-STRATEGY.md` — audience header present at L1-L20; `sed -n '465p' pack-ops/MERGE-STRATEGY.md` — L465 STILL bare `OPTIONAL-FEATURES.md` (unchanged; D8.6 lands in 9b) |
| 9b | `sed -n '465p' pack-ops/MERGE-STRATEGY.md` — L465 now `docs/pack/OPTIONAL-FEATURES.md`; `ls project-template/docs/pack/OPTIONAL-FEATURES.md` — confirms target exists (Commit 10 landed) |
| 10 | `ls project-template/docs/pack/OPTIONAL-FEATURES.md` — file exists; `grep -n "STREAMS\|Check 22\|validate-pack\|tracker.toml.pack-example" project-template/docs/pack/OPTIONAL-FEATURES.md` — ZERO hits (TYPE-2 avoidance verified); `grep -n "docs/pack/OPTIONAL-FEATURES" supporting-docs/DEPENDENCIES.md` — at L162 (D8.7 post-edit) |
| 11 | `grep -n "docs/pack/QUICKSTART" project-template/.gemini/commands/pack-help.toml project-template/.claude/skills/pack-help/SKILL.md project-template/.codex/skills/pack-help/SKILL.md project-template/docs/pack/HELP-FRAGMENT.md` — ZERO hits |
| 12 | `grep -n "P-missed-7\|Project SSOT-first\|boundary-investigation\|Boundary discipline" <pack-root trinity + project-template trinity + agent files + skill files>` — expected hits present per C §4 + §4.2 + §5.1 + §5.2 + §6; Check 37 fixture test PASS |

---

## §5 — Open questions

**Zero open questions remain.** OQ-1 (the sole genuine OQ surfaced by this plan) was RESOLVED by the user on 2026-05-19. See close-out below.

### OQ-1 — RESOLVED 2026-05-19 (Path A chosen)

**Decision:** **Path A** — split V5 into Commit 9a (audience header only) + Commit 9b (D8.6 ref-update only). 13 commits total. Commit 9a joins parallel set ALPHA-EXPANDED (7 concurrent pack-coder spawns); Commit 9b lands sequentially after Commit 10 in the sequential tail (10 → 9b → 12).

**User's reasoning** (per parallelism-aware re-litigation surfaced in §8.5):
- **Clarity** — single-concern commits (9a = audience header only; 9b = D8.6 ref-update only) read more cleanly in the audit trail than the Path B combined Commit 9.
- **Monotonic ordering** — execution order matches commit numbering (1→2→3→[parallel 4,5,6,7,8,9a,11]→10→9b→12); no Path B "10 before 9" inversion to footnote.
- **Single-concern commits** — each TASK-T5 hunk lives in its own commit, easier to audit and (if needed) revert independently.
- **+5-15 min marginal wall-clock save** — Commit 9a's parallelization (joining ALPHA-EXPANDED instead of running sequentially after Commit 10) saves additional time per §8.8 wall-clock comparison.

**OQ-1 closed; Phase 5 coder reads §2.9a + §2.9b as the authoritative TASK-T5 partition.** No further user reconciliation needed for OQ-1. Plan ready for Phase 5 implementation.

---

## §6 — Cross-references

Each commit cross-references the architect design that authorized it. Where overrides apply, the override citation is named per commit. Architect docs cited:

- **AUDIT-USER-CURATION.md** — `maintenance-docs/v11-implementation/AUDIT-USER-CURATION.md`
  - §1 Override 1 — `tracker.toml.pack-example` STAYS — Commits 1 (1-entry exemption list)
  - §1 Override 5 — BACKLOG.md + CHANGELOG.md MUST MOVE — Commits 1 (exemption list excludes), 2 (M9 + M10 enacted)
  - §1 Override 6 — CONCEPTUAL-REVIEW-METHODOLOGY.md → `pack-ops/` (NOT `maintenance-docs/`) — Commit 3 (M6 destination)
  - §1 Override 7 — QUICKSTART.md STAYS at root, no SPLIT — Commits 2 (QUICKSTART untouched), 11 (Override 10 cascade closure)
  - §1 Override 8 — OPTIONAL-FEATURES.md SPLIT confirmed — Commits 10 (SPLIT enacted — project-side file created), 9b (D8.6 ref-update per S2 cascade — Path A per OQ-1 RESOLVED)
  - §1 Override 9 — C's M2 two-tier codification, different wording per audience, no cross-trinity drift gate — Commit 12 (P-missed-7 + Project SSOT-first bullets in lockstep within each trinity location but differing across)
  - §1 Override 10 — REMOVE `docs/pack/QUICKSTART.md` references from 4 help files — Commit 11
  - §1 Override 2 — root `.github/` PACK-ONLY (NOT shared) — informational; no commit enacts (root `.github/` STAYS as-is)
  - §1 Override 3 — drop F-3 from SHARED catalog — informational; reflected in Commit 1's BOUNDARY-DEFINITION.md §5 SHARED catalog
  - §1 Override 4 — parallel CLI dotted-dirs NOT shared — informational; reflected in Commit 1's BOUNDARY-DEFINITION.md §5

- **ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md** (Architect A) — `maintenance-docs/v11-implementation/ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md`
  - §2 V1 + T5-A + V8 + §6.1 TASK-T1 — Commit 4 (project-template trinity)
  - §2 V3 + §6.1 TASK-T2 — Commit 5 (PLATFORM-SKILLS.md)
  - §2 V5 PRIMARY + §6.1 TASK-T5 (audience header half) — Commit 9a (MERGE-STRATEGY audience header only — Path A per OQ-1 RESOLVED)
  - §3.5 D8.6 + §6.1 TASK-T5 (D8.6 ref-update half) — Commit 9b (MERGE-STRATEGY D8.6 ref-update only — Path A per OQ-1 RESOLVED)
  - §2 V6 + §6.1 TASK-T4 — Commit 7 (MIGRATION-v10-to-v11.md)
  - §2 V7 + §6.1 TASK-T3 — Commit 6 (audit-methodology SKILL.md)
  - §2 V4 + §5 11-ref cluster + §6.1 TASK-T7 — Commit 3 (CONCEPTUAL-REVIEW-METHODOLOGY.md RELOCATE — V4 absorbs V2 + T5-B + §5 cluster per cascade)
  - §3.5 D8.7 + §4 A4-A8 + §6.1 TASK-T8 — Commit 10 (OPTIONAL-FEATURES.md SPLIT — D8.7 REPLACE; A4-A8 verify-only)
  - §4 A2 + §6.1 TASK-T6 — Commit 8 (METHODOLOGY.md REPLACE)
  - §2 V2 / V9 / V10 / V11 / V12 / T5-A / T5-B — SUBSUMED into other TASKs per A §6.3 cascade; no standalone commits
  - §10 fix-pass amendments (B1 + S1 + S2) — informational; reflected in V10 NO-ACTION + V4 destination per Override 6 + TASK-T8 SPLIT-confirmed per Override 8

- **ARCHITECTURE-DIRECTORY-REORGANIZATION.md** (Architect B) — `maintenance-docs/v11-implementation/ARCHITECTURE-DIRECTORY-REORGANIZATION.md`
  - §1.1 + §1.2 two-axis classification + verdict procedure — Commit 1 (BOUNDARY-DEFINITION.md §2 + §3)
  - §3.1 `pack-ops/` new top-level dir — Commits 1 (scaffold), 2 (populated)
  - §3.2 tracker-config.sh auto-detection migration — Commit 2 (`[[ -d "$repo_root/pack-ops" ]]`)
  - §3.3 machine-readable exemption list — Commit 1 (`pack-ops/.boundary-exempt-root.txt`)
  - §4.1 F-1 resolution (supporting-docs cleanup) — Commit 3 (M6 + M7 + M8) per B-fix §16 Override 6 cascade
  - §4.2 F-2 resolution (docs/pack/ name stays) — informational; no commit needed
  - §4.4 F-4 resolution per Override 7 — Commit 2 (QUICKSTART STAYS); Commit 11 (4 help files Override 10)
  - §4.5 F-5 OPTIONAL-FEATURES.md SPLIT option (b) — Commit 10 (per Override 8 confirmed)
  - §4.6 F-6 trinity collisions NO RENAME — informational
  - §5 BOUNDARY-DEFINITION.md doc + cross-reference network — Commit 1 (BOUNDARY-DEFINITION.md creation); Commit 12 (cross-reference network insertion via trinity edits + agent skill-load updates)
  - §6.1 MOVES list M1-M8 — Commit 2 (M1-M5 + B-fix M9-M10); Commit 3 (M6-M8)
  - §6.2 SPLIT list S1 + S2 — S1 DROPPED per Override 7 + B-fix §12.2; S2 = Commit 10
  - §6.3 CREATES list N1 + N2 — Commit 1
  - §6.4 order of operations — Commits 1-12 sequence (B-fix §11.3 amended per Option A + Override 7 drop + Override 6 cascade)
  - §6.5 grep + sed plan per MOVES file — Commits 2 + 3 (per-file grep + sed)
  - §6.6 validate-pack.py constant updates — Commit 2 (lines 191-192, 230, 1654, 1656, 1659, 1669, 1735-1736, 1929 — except 230 unchanged per Override 7 QUICKSTART stays); Commit 3 (migrate-v10-to-v11.sh references)
  - §6.7 manifest-regen contract — every v11-surface commit per RC9
  - §6.8 verification protocol — §4 Verification gates in this plan

- **ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md** (Architect B-fix + extension + v2) — `maintenance-docs/v11-implementation/ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md`
  - §4 1-entry exemption list — Commit 1
  - §5 MOVES list extending M9 + M10 — Commit 2
  - §6 path-reference impact (5 categories) — Commit 2 (LIVE pack-internal + LIVE auto-detection); Commit 3 (LIVE supporting-docs)
  - §7.1 Option A combined commit (MANDATE per M1 reviewer finding) — Commit 2
  - §8 external-constraint claims rejected — informational background for Commit 2
  - §10 Phase 5 coder guidance per-file edits — Commit 2 (extensive)
  - §12 Override 7 + Override 10 cascade — Commit 11 (per-file BEFORE/AFTER); Commit 2 (QUICKSTART surfaces["project-template"]["docs"] addition DROPPED)
  - §13 S3 content-split sketch for OPTIONAL-FEATURES.md — Commit 10
  - §14 N2 count-agnostic phrasing — informational; Commit 12 increases check count from 33 to 36+
  - §16 Override 6 cascade closure — Commit 3 (CONCEPTUAL-REVIEW-METHODOLOGY.md destination `pack-ops/`)

- **ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md** (Architect C + C-fix + C-fix-v2) — `maintenance-docs/v11-implementation/ARCHITECTURE-BOUNDARY-PREVENTION-MECHANISMS.md`
  - §3 coverage matrix — Commit 12 (entire prevention mechanism suite)
  - §4 + §4.1 (Override 9) + §4.2 — Commit 12 (M2 P-missed-7 + project-side mirror)
  - §5 + §5.1 + §5.2 — Commit 12 (M3a + M3b)
  - §6 — Commit 12 (M4 boundary-investigation skill)
  - §7 — Commit 12 (M6 SSOT-rotation reminder)
  - §8 + §8.1 + §8.1a + §8.2 + §8.3 — Commit 12 (M5a Check 36 + M5b Check 37 + M5c Check 38)
  - §9.1 — Commit 12 (M7 TYPE-5 positive-assertion gate)
  - §9.2 — Commit 12 (M8 trinity-rule documentation amendment)
  - §10.1 + §10.2 — Commit 12 (M1a memory rule + M1b commit-subject scope-keyword convention)
  - §11 conditional dependencies on B — Commit 12 (post-B+B-fix paths consumed)
  - §13 order-of-land — Commit 12 lands LAST per bootstrap incompatibility note
  - §16 + §16a fix-pass amendments — Commit 12 (M2 deny-list + M4 exemption-list + B1-cascade PM-only + S4 Override 9 + S5 project-side mirror deny-list + S6 cascade + HELP-FRAGMENT-TRACKER row staleness)

- **PACK-REVIEW-PHASE-2-DESIGNS.md** — `maintenance-docs/v11-implementation/PACK-REVIEW-PHASE-2-DESIGNS.md`
  - M1 (BLOCKER planner-level finding) — Commit 2 (Option A enforcement; reject Option B)
  - All other findings (B1 / M2 / M3 / M4 / S1-S6 / N1-N4) — VERIFIED CLOSED per PACK-REVIEW-PHASE-2-DESIGNS-VERIFICATION.md; no Phase 5 action beyond what the architect fix-pass amendments already encode

- **PACK-REVIEW-PHASE-2-DESIGNS-VERIFICATION.md** — `maintenance-docs/v11-implementation/PACK-REVIEW-PHASE-2-DESIGNS-VERIFICATION.md`
  - §0 Executive summary GO verdict — premise for this plan
  - §1 per-finding verdicts (12 VERIFIED) — informational; closed
  - §2 cross-doc consistency check (VERIFIED) — informational; ALIGNED
  - §3 Final go/no-go GO — Phase 4 planner may spawn (this plan is the planner output)
  - Action item Pack Chat carries forward into planner spawn: M1 Option A constraint — encoded in Commit 2 scope

- **PACK-AGENTS.md** — `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/PACK-AGENTS.md` (will become `pack-ops/PACK-AGENTS.md` after Commit 2)
  - Lines 142-148 PM-only Files list — Commit 12 (Check 36 PERMITTED-PATHS regex sources this list); Commit 2 (the file itself moves to `pack-ops/`)
  - Lines 150-158 PM-only Directories — informational; per-entry trees STAY at root (forward-pointing per lines 178-187 Batch-23 note)

- **scripts/validate-pack.py** — `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/validate-pack.py`
  - Lines 189-193 STREAMS — Commit 2 (paths → `pack-ops/`)
  - Line 230 REQUIRED_BD044_DOCS QUICKSTART.md — UNCHANGED per Override 7
  - Line 319 Check 3 backlog path — Commit 2
  - Lines 1650-1668 Check 22 surfaces dict — Commit 2 (PACK-CHAT.md, OPTIONAL-FEATURES.md, HELP-FRAGMENT-PACK.md paths); Commit 10 (project-template/docs/pack/OPTIONAL-FEATURES.md addition if Check 22 verifies it — coder verifies; Override 7 explicitly DROPS the surfaces["project-template"]["docs"] QUICKSTART.md addition per B-fix §12.1)
  - Line 1929 Check 24 byte-identity pack-side path — Commit 2
  - Line 2482 tracker.toml.pack-example — UNCHANGED per Override 1
  - New Checks 36/37/38 — Commit 12

---

---

## §8 — Parallelism analysis (Commits 4-11)

This section identifies which of Commits 4-11 can execute in parallel, with concrete orchestration patterns, manifest-regen sequencing, CI cascade risk analysis, and wall-clock + token-cost tradeoffs. Commit 1 (scaffold), Commit 2 (M1-M5+M9-M10 mandatory single commit), Commit 3 (M6-M8 supporting-docs MOVE — depends on Commit 2's pack-ops/ existence), and Commit 12 (prevention — must land last per C §13 bootstrap order + must follow ALL contamination fixes from Commits 4-9) are NOT parallelism candidates per the §0 sequencing constraints.

Constraints unchanged from prior sections:
- M1 Option A Commit 2 STRUCTURALLY INVIOLABLE (not in scope here)
- Trinity rule per §4.3 (within-trinity-location parity at Commits 2, 4, 11, 12)
- RC9 manifest-regen per §4.2
- Override-source-wins
- FRESH coder per commit per pack-memory
- No worktree isolation per pack-memory (sub-agents run in parent working tree)
- Pack Chat ONLY commits per pack-memory (agents never `git commit`)

### §8.1 — File footprint summary per commit (foundation for disjointness analysis)

Compact footprint matrix for Commits 4-11. Manifest column shows Y/N per §4.2 (manifest-regen file: `test-fixtures/manifest.txt`):

| Commit | Files touched (excluding manifest) | Manifest Y/N | Trinity surface? |
|---|---|---|---|
| 4 | `project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md` (3 files) | Y | YES — project-template trinity (within-location parity required) |
| 5 | `project-template/docs/pack/PLATFORM-SKILLS.md` (1 file) | Y | NO |
| 6 | `project-template/skills/audit-methodology/SKILL.md` (1 file) | Y | NO (single-source SKILL.md; init-project.sh distributes at install) |
| 7 | `supporting-docs/MIGRATION-v10-to-v11.md` (1 file) | **N** (supporting-docs not v11-surface) | NO |
| 8 | `supporting-docs/METHODOLOGY.md` (1 file) | **N** (supporting-docs not v11-surface) | NO |
| 9a | `pack-ops/MERGE-STRATEGY.md` (1 file — audience header ONLY at L1-L20) | **N** (pack-ops not v11-surface per RC9 base) | NO |
| 9b | `pack-ops/MERGE-STRATEGY.md` (1 file — D8.6 ref REPLACE ONLY at L465; same file as 9a but distinct hunk; lands after Commit 10) | **N** (pack-ops not v11-surface per RC9 base) | NO |
| 10 | `project-template/docs/pack/OPTIONAL-FEATURES.md` (NEW), `scripts/init-project.sh` (conditional — if install loop doesn't already handle `docs/pack/*.md`), `supporting-docs/DEPENDENCIES.md` (3 files max; 2 if init-project.sh edit unneeded) | Y | NO |
| 11 | `project-template/.gemini/commands/pack-help.toml`, `project-template/.claude/skills/pack-help/SKILL.md`, `project-template/.codex/skills/pack-help/SKILL.md`, `project-template/docs/pack/HELP-FRAGMENT.md` (4 files) | Y | YES — pack-help CLI-parallel trinity (within-skill parity required) |

**File-disjointness verification across Commits 4-11** (grep audit — each file is touched by exactly one commit; zero pairwise overlaps):

```
# Pairwise overlap check (all 28 pairs):
# 4 vs 5: trinity vs PLATFORM-SKILLS.md — disjoint
# 4 vs 6: trinity vs audit-methodology — disjoint
# 4 vs 7: trinity vs MIGRATION-v10-to-v11 — disjoint
# 4 vs 8: trinity vs METHODOLOGY — disjoint
# 4 vs 9a/9b: trinity vs MERGE-STRATEGY — disjoint
# 4 vs 10: trinity vs OPTIONAL-FEATURES + init-project + DEPENDENCIES — disjoint
# 4 vs 11: trinity vs pack-help files + HELP-FRAGMENT — disjoint (both project-template/ but different sub-trees)
# 5 vs 6: PLATFORM-SKILLS vs audit-methodology — disjoint
# 5 vs 7-11: PLATFORM-SKILLS vs all others — disjoint
# 6 vs 7-11: audit-methodology vs all others — disjoint
# 7 vs 8: MIGRATION vs METHODOLOGY — disjoint (both supporting-docs/ but different files)
# 7 vs 9a/9b/10/11: MIGRATION vs all — disjoint
# 8 vs 9a/9b/10/11: METHODOLOGY vs all — disjoint
# 9a vs 9b: SAME FILE (MERGE-STRATEGY.md) but DISJOINT HUNKS (L1-L20 audience header vs L465 D8.6 ref); sequenced 9a in parallel set, 9b in tail
# 9a vs 10: MERGE-STRATEGY (pack-ops/) vs OPTIONAL-FEATURES (project-template/) — disjoint
# 9b vs 10: same as above; 9b runs AFTER 10 sequentially
# 9a vs 11: MERGE-STRATEGY vs pack-help — disjoint
# 9b vs 11: same as above
# 10 vs 11: OPTIONAL-FEATURES (docs/pack/) vs HELP-FRAGMENT (docs/pack/) — DIFFERENT FILES, disjoint at file level (both inside project-template/docs/pack/ but distinct .md files)
```

**Sole shared file across ALL Commits 2-11:** `test-fixtures/manifest.txt`. This file regenerates from a DETERMINISTIC SHA computation over the v11-surface tree; any commit modifying `project-template/` or `scripts/` triggers a manifest change. The manifest is a SHARED-OUTPUT, not a SHARED-INPUT — parallel coders can produce concurrent v11-surface edits, but the manifest must be regenerated SERIALLY by Pack Chat between each `git commit` (the manifest reflects the cumulative tree state, not per-coder deltas). See §8.7 for the manifest orchestration pattern.

### §8.2 — Parallel set ALPHA-EXPANDED (Path A authoritative per OQ-1 RESOLVED)

Per OQ-1 RESOLVED (Path A chosen, user decision 2026-05-19), parallel set ALPHA-EXPANDED contains **7 file-disjoint commits**: 4, 5, 6, 7, 8, 9a, 11. These 7 commits launch as CONCURRENT pack-coder spawns after Commit 3 lands; Pack Chat commits each serially using the git-stash isolation pattern per §8.7 + push-then-wait CI cascade pattern per §8.6.

#### §8.2.1 — Parallel set ALPHA-EXPANDED (after Commit 3 lands): Commits 4, 5, 6, 7, 8, 9a, 11

**Participating commits:** 4 (TASK-T1 trinity), 5 (TASK-T2 PLATFORM-SKILLS), 6 (TASK-T3 audit-methodology), 7 (TASK-T4 MIGRATION), 8 (TASK-T6 METHODOLOGY), **9a (TASK-T5 MERGE-STRATEGY audience header only)**, 11 (Override 10 4-help-files).

**File-disjointness verification:** Per §8.1 matrix — zero pairwise overlap across these 7 commits. Each touches a distinct file or file cluster:
- 4: 3 project-template trinity files (CLAUDE.md + AGENTS.md + GEMINI.md)
- 5: 1 file (PLATFORM-SKILLS.md)
- 6: 1 file (audit-methodology SKILL.md)
- 7: 1 file (MIGRATION-v10-to-v11.md)
- 8: 1 file (METHODOLOGY.md)
- 9a: 1 file (pack-ops/MERGE-STRATEGY.md — audience header L1-L20 hunk ONLY; L465 D8.6 ref-update is DEFERRED to Commit 9b in sequential tail)
- 11: 4 files (pack-help skill trinity + HELP-FRAGMENT.md)

Total distinct files: 12. Total `git diff --name-only` overlap: zero (verified via §8.1 pairwise check). Commit 9a + Commit 9b touch the SAME file (`pack-ops/MERGE-STRATEGY.md`) but DISJOINT HUNKS (L1-L20 vs L465); since 9b lands sequentially AFTER 9a (in the tail), there is no concurrent-write conflict.

**Why these specific commits:** All 7 have a common dependency profile — they MUST land AFTER Commit 3 (Commits 5-8 + 11 are independent of the supporting-docs MOVE; Commit 4's trinity wording change is the project-side SSOT pointer redirect, which is logically independent of where pack-side files moved to — V1+T5-A+V8 only require the destination SSOT `docs/pack/PM-CHAT.md § Pack agent roster` to exist at client install, which it does in `project-template/docs/pack/PM-CHAT.md` per current HEAD state, regardless of Commits 1-3 outcome; Commit 9a edits `pack-ops/MERGE-STRATEGY.md` which exists at its `pack-ops/` location after Commit 3's `git mv`). Commit 11 (Override 10) is independent of all earlier commits — it could even land before Commit 2 in principle, but landing it with this set keeps the CI cascade simpler.

**NOT in parallel set ALPHA-EXPANDED:**
- Commit 9b is EXCLUDED because its D8.6 ref-update REQUIRES the project-side `project-template/docs/pack/OPTIONAL-FEATURES.md` to exist (Commit 10 creates it). 9b lands sequentially AFTER Commit 10.
- Commit 10 is EXCLUDED — it creates the project-side OPTIONAL-FEATURES.md that 9b's ref-update needs; 10 is the FIRST commit of the sequential tail (10 → 9b → 12).
- Commit 12 is EXCLUDED because Check 37 deny-list lands in 12 and FAILS at HEAD until ALL 17 §D-9 contamination refs (resolved by Commits 4-9b) are gone. Commit 12 must land LAST.

**Pack Chat orchestration pattern:**

```
[Pack Chat] After Commit 3 lands and CI greens, in ONE message:
  - Spawn pack-coder #4 (background, per pack-memory run_in_background:true)
    with full Commit 4 prompt (per §2.4.3 + spawn breakdown row 4)
  - Spawn pack-coder #5 (background) with Commit 5 prompt
  - Spawn pack-coder #6 (background) with Commit 6 prompt
  - Spawn pack-coder #7 (background) with Commit 7 prompt
  - Spawn pack-coder #8 (background) with Commit 8 prompt
  - Spawn pack-coder #9a (background) with Commit 9a prompt (per §2.9a)
  - Spawn pack-coder #11 (background) with Commit 11 prompt
  (7 fresh pack-coder spawns in ONE Agent-tool batch)

[7 coders run in parallel; each emits PREFLIGHT line + IMPL-REPORT;
 each makes its own file edits in the parent's working tree.
 NO worktree isolation per pack-memory.
 File-disjointness ensures no edit conflicts.]

[Pack Chat] As coders return reports, triage each:
  - Read each IMPL-REPORT in any order they return
  - Verify each coder's edits via git diff (per-coder file scope)
  - Decide commit order (suggested: 4, 11, 5, 6, 7, 8, 9a — trinity surfaces first,
    then non-trinity; trinity rule per §4.3 enforced per-commit)

[Pack Chat] Serial commit loop with git-stash isolation per §8.7
  (chosen orchestration pattern per user decision 2026-05-19):
  FOR each of 7 commits in chosen order:
    1. Identify coder-K's file set (from coder-K IMPL-REPORT)
    2. git stash push -m "P5-parallel-other-coders-pre-K" -- <files-NOT-in-K-set>
       (isolates K's files from other concurrent unstaged edits)
    3. git add <coder-K files>
    4. IF commit K is v11-surface per §4.2 (Commits 4, 5, 6, 11 = Y;
       Commits 7, 8, 9a = N):
         bash test-fixtures/build.sh --all --clean
         git diff test-fixtures/manifest.txt
         IF non-empty: git add test-fixtures/manifest.txt
    5. git commit -m "feat: v11 — BD-175 ..."  [per-commit subject per §1]
    6. git stash pop  (restore other coders' edits to working tree)
    7. git push  (CI run triggers per commit)
    8. Wait for CI green (push-then-wait per §8.6 — chosen pattern per
       user decision 2026-05-19) before next commit
```

**Manifest-regen orchestration:** Serial — Pack Chat runs `bash test-fixtures/build.sh --all --clean` BETWEEN each Y-marked commit (post git-stash isolation per §8.7), not per-coder. The manifest is a cumulative SHA of v11-surface state; running it once per commit is correct (the manifest delta from each commit reflects only that commit's tree changes plus the prior cumulative state). Running it per-coder would produce 7 manifest regens, only the LAST being correct. Running it serially per-commit produces 4 manifest regens for the parallel set ALPHA-EXPANDED batch (one each for Commits 4, 5, 6, 11; Commits 7 + 8 + 9a are N and skip). Each manifest regen takes ~30-90s per pack-memory RC9 cost-estimate.

**CI cascade risk + recovery:** With 7 commits pushed serially in one batch, CI runs 7 workflow instances. **Per user decision 2026-05-19: push-then-wait pattern is the chosen CI cascade orchestration** for this parallel batch — Pack Chat commits each member, pushes, waits CI green, then pushes the next. Trades wall-clock savings for cascade-isolation safety. Failure modes:
- **Best case:** all 7 pass. Total CI time = 7 × workflow runtime (GitHub Actions runs sequentially per branch unless parallel jobs configured); user observes 7 passing checks.
- **Mid-cascade failure (Commit K fails CI under push-then-wait):** Push-then-wait isolates failures to a single commit — no cascade-fail because subsequent commits do not push until K is green. Recovery: identify the root failure at K, spawn fresh pack-coder #K-fix with corrective task per pack-memory commit-discipline rules, land fix as NEW commit (per pack-memory "Always create NEW commits rather than amending"). Per CLAUDE.md approved suffix: `fix: v11 — BD-175 ... (Batch P5-parallel-set-ALPHA-EXPANDED)` or similar.
- **Alternative push-all-then-watch (NOT chosen for this batch):** would expose cascade-fail risk; rejected per user decision in favor of safety.

**Wall-clock savings vs sequential (Path A ALPHA-EXPANDED — 7 commits):**
- Sequential baseline: 7 coder spawns × ~5-15 min/spawn = 35-105 minutes pure coder time + Pack Chat read/triage/commit gaps + 7 × CI runs (serial per branch ~3-5 min each in this repo per recent observation = 21-35 min CI time).
- Parallel baseline: 7 coders concurrent = ~5-15 min for the slowest (likely Commit 4 trinity per V1+T5-A+V8 mechanical depth) + Pack Chat serial triage (~2-3 min per IMPL-REPORT × 7 = 14-21 min) + serial CI = same 21-35 min if pushed all-at-once, OR 35-70 min if push-then-wait per commit (chosen pattern).
- **Net savings:** Coder phase: 30-90 min saved (5-7× speedup on coder time). Triage phase: unchanged (Pack Chat is single-threaded by user-attention bottleneck). CI phase: modestly slower with push-then-wait, but cascade-isolation safety chosen per user decision 2026-05-19.
- **Realistic total:** ~50-70 min savings end-to-end vs ~110-170 min sequential. Estimated 30-50% wall-clock reduction.

**Token cost vs sequential:**
- Each fresh pack-coder spawn re-reads the same architect docs (A + B + B-fix + C + relevant overrides). For Commits 4-8 + 9a + 11, the shared context-load is roughly: AUDIT-USER-CURATION.md (~170 lines), ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md relevant sections per commit (~50-150 lines), per-commit anchor doc sections (~30-100 lines), CLAUDE.md trinity rule + RC9 reminders (~50 lines from context).
- Per-coder marginal token cost: ~5-15k input tokens for context-reading, plus ~5-20k output tokens for edits + IMPL-REPORT.
- Parallel set ALPHA-EXPANDED: 7 coders × ~10-30k tokens total each = 70-210k tokens for the batch.
- Sequential: same 70-210k tokens total (each fresh coder still re-reads docs whether sequential or parallel — pack-memory's FRESH coder rule mandates re-reading per commit; no shared-context savings available).
- **Net token cost:** parallel and sequential are IDENTICAL on token count. Parallelism saves wall-clock only, not tokens. (This is a pack-memory consequence — FRESH coder per commit is non-negotiable, so context-reading repeats either way.)

#### §8.2.2 — Sequential tail after parallel set ALPHA-EXPANDED: Commits 10 → 9b → 12 (Path A)

After parallel set ALPHA-EXPANDED lands all 7 commits and CI greens (push-then-wait per §8.6), the remaining sequential tail is:
- **Commit 10** (TASK-T8 OPTIONAL-FEATURES SPLIT) — depends on parallel set ALPHA-EXPANDED being clean (no contamination from any of Commits 4-8 + 9a + 11 lingering); creates project-side `project-template/docs/pack/OPTIONAL-FEATURES.md`.
- **Commit 9b** (TASK-T5 D8.6 ref-update only) — depends on Commit 10 (D8.6 ref-update at `pack-ops/MERGE-STRATEGY.md:465` references `docs/pack/OPTIONAL-FEATURES.md` which Commit 10 created).
- **Commit 12** (prevention) — depends on ALL prior commits (Check 37 deny-list grep on project-template/ must return zero contamination hits, which requires Commits 4-9b all landed).

These three are **strictly sequential** under Path A: 10 → 9b → 12. No further parallelization possible (10 ↔ 9b ↔ 12 each have cross-dependencies).

#### §8.2.3 — Historical: Path B parallel set ALPHA (6 commits) — NOT CHOSEN

Under the rejected Path B alternative explored during OQ-1 deliberation: Commit 9 would have stayed as one logical TASK-T5 unit (audience header + D8.6 ref combined). Path B's parallel set ALPHA would have been 6 commits (4, 5, 6, 7, 8, 11) — Commit 9 could NOT join because its D8.6 ref-update depended on Commit 10 (Commit 9 would have run in the sequential tail AFTER Commit 10: 10 → 9 → 12). Path B yielded 12 total commits.

**Why Path B was rejected (user decision 2026-05-19):** per §8.5 close-out, Path A's monotonic execution order, single-concern commits, larger parallel set (7 vs 6), and ~5-15 min extra wall-clock savings outweighed Path B's "one fewer commit ceremony" advantage. See §8.5 for the full re-litigation table.

### §8.3 — Parallelism NOT possible for these pairs

Documenting the pairs that CANNOT parallelize, so future planners don't re-litigate:

| Pair | Reason no parallelism |
|---|---|
| 1 ↔ 2 | Commit 2's `git mv` targets need `pack-ops/` dir to exist (Commit 1 creates it). Sequential. |
| 2 ↔ 3 | Commit 3 moves 3 more files INTO `pack-ops/` and updates pack-internal scripts that Commit 2 also touched (scripts/migrate-v10-to-v11.sh references could conflict). Sequential. Plus Commit 2 establishes the `[[ -d "$repo_root/pack-ops" ]]` detection signal that Commit 3 verifies works. |
| 3 ↔ 4 | Commit 4 (project-template trinity) is conceptually independent of Commit 3 (supporting-docs MOVE), but landing them in parallel risks confusion in IMPL-REPORTs about which contamination ref Commit 4 should target. Sequential is safer. (Could be parallelized in principle — see §8.4 advanced option.) |
| 9b ↔ 10 (Path A) | Commit 9b D8.6 ref-update requires project-side file from Commit 10. Sequential 10→9b. |
| 9a ↔ 9b (Path A) | Same file (`pack-ops/MERGE-STRATEGY.md`) but disjoint hunks (L1-L20 vs L465); sequenced 9a-in-parallel-set then 9b-in-sequential-tail to avoid concurrent write to the same file path. |
| Any ↔ 12 | Commit 12's Check 37 deny-list fails at HEAD until ALL contamination from Commits 4-9b is resolved. Commit 12 strictly LAST. |

### §8.4 — Optional advanced: extend ALPHA to include Commit 3

Commit 3 (M6-M8 supporting-docs MOVE) touches:
- 3 git-mv files: supporting-docs/{CONCEPTUAL-REVIEW-METHODOLOGY,DRY-RUN-MIGRATION,MERGE-STRATEGY}.md → pack-ops/
- scripts/migrate-v10-to-v11.sh
- scripts/dry-run-migration.sh
- 1-3 live maintenance-docs/v11-implementation/ refs

Commit 3 is file-disjoint from all of Commits 4-8 + 11. Specifically:
- Commit 4 trinity: project-template/CLAUDE.md etc. — disjoint
- Commit 5 PLATFORM-SKILLS: project-template/docs/pack/PLATFORM-SKILLS.md — disjoint
- Commit 6 audit-methodology: project-template/skills/audit-methodology/SKILL.md — disjoint
- Commit 7 MIGRATION-v10-to-v11.md: this is supporting-docs/MIGRATION-v10-to-v11.md — disjoint from supporting-docs/{CONCEPTUAL-REVIEW-METHODOLOGY,DRY-RUN-MIGRATION,MERGE-STRATEGY}.md
- Commit 8 METHODOLOGY: supporting-docs/METHODOLOGY.md — disjoint
- Commit 11 pack-help + HELP-FRAGMENT: project-template/.{claude,codex,gemini}/... — disjoint

**Theoretical:** Commit 3 could join parallel set ALPHA, expanding to 7 parallel commits.

**Why NOT recommended:**
- Commits 9a + 9b (Path A — both edit `pack-ops/MERGE-STRATEGY.md`) need the file to exist at its post-Commit-3 `pack-ops/` location. If Commit 3 lands in parallel with Commits 4-8 + 9a + 11, the `pack-ops/MERGE-STRATEGY.md` path doesn't exist on Pack Chat's working tree until Commit 3's `git mv` is staged + committed. Commit 9a must commit AFTER Commit 3's mv lands. This is a Pack-Chat commit-order constraint, not a coder edit-order constraint — coders work in the working tree, and Pack Chat decides commit order.
- More importantly: Commit 3's grep+update sweep for live `supporting-docs/{CONCEPTUAL-REVIEW-METHODOLOGY,DRY-RUN-MIGRATION,MERGE-STRATEGY}.md` refs in `maintenance-docs/v11-implementation/**.md` could collide with concurrent IMPL-REPORT writes by Commits 4-8+11 coders to the SAME directory (`maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-*.md`). Coders write their IMPL-REPORTs to `maintenance-docs/v11-implementation/`. Commit 3's coder doing a grep+update sweep across `maintenance-docs/v11-implementation/*.md` would see other coders' in-progress IMPL-REPORT files. The risk is small (Commit 3's grep target is the BD-175 source files we relocated, not the IMPL-REPORTs themselves; IMPL-REPORT filenames are predictable and excludable), but it's a real shared-directory concern.
- **Recommendation:** Land Commit 3 SEQUENTIALLY before parallel set ALPHA spawns. The wall-clock cost is ~5-10 min vs the cost of debugging a shared-directory write race. Not worth the savings.

If user wants the further savings, the mitigation is: Commit 3's coder restricts its grep+update to specific files named in B's §6.5 M6/M7/M8 plan (not a broad `maintenance-docs/v11-implementation/**.md` sweep), and parallel coders are instructed to write IMPL-REPORTs to a temp path that Pack Chat moves into `maintenance-docs/v11-implementation/` post-commit. This is structurally cleaner but adds orchestration complexity.

### §8.5 — OQ-1 RESOLVED (Path A chosen by user 2026-05-19)

**DECISION: Path A chosen by user 2026-05-19.** 13 commits total; Commit 9 splits into 9a (audience header — joins parallel set ALPHA-EXPANDED) + 9b (D8.6 ref-update — sequential tail after Commit 10). User reasoning: clarity (single-concern commits), monotonic execution order, +5-15 min marginal wall-clock save (Commit 9a parallelizes instead of running sequentially after Commit 10).

**The comparison table below is preserved as historical record of the parallelism-aware re-litigation that informed the decision.** Originally surfaced as OQ-1 in §5; user reconciled on the parallelism-aware merits.

**Under Path B (planner's pre-parallelism default):**
- Total commits: 12
- Parallel set ALPHA: 6 commits (4, 5, 6, 7, 8, 11)
- Sequential tail: 3 commits (10 → 9 → 12)
- Wall-clock save: parallel set ALPHA saves ~25-75 min on coder phase; sequential tail runs in serial
- Audit-trail: TASK-T5 = 1 commit (Commit 9 carries audience header + D8.6 ref together); execution-order vs commit-numbering mismatch (10 runs before 9 numerically)
- Cognitive cost: future archaeology may find the "Commit 10 before Commit 9" execution-order odd

**Under Path A (split V5 — 13 commits total):**
- Total commits: 13 (Commit 9 → 9a audience-header + 9b D8.6-ref)
- Parallel set ALPHA-EXPANDED: 7 commits (4, 5, 6, 7, 8, 11, **9a**) — adding 9a to the parallel batch
- Sequential tail: 3 commits (10 → 9b → 12)
- Wall-clock save: parallel set ALPHA-EXPANDED saves ~30-90 min on coder phase (one extra coder in parallel adds ~no marginal time — concurrent execution dominates); sequential tail unchanged
- Marginal additional wall-clock savings under Path A: ~5-15 min (one more commit moves from sequential to parallel)
- Audit-trail: TASK-T5 = 2 commits (9a + 9b); execution-order = commit-numbering matches (9a before 10 before 9b before 12)
- Cognitive cost: 13 commits in audit trail vs 12; but each commit's scope is cleaner

**Path A's renewed merits under parallelism:**
1. **Smoother parallel-set composition:** Commit 9a joins parallel set ALPHA cleanly (file-disjoint from all 6 other set-ALPHA commits — touches `pack-ops/MERGE-STRATEGY.md` which is fully disjoint from project-template/* + supporting-docs/*). Path B requires Commit 9 to wait for Commit 10 (sequential tail), preventing 9 from joining the parallel batch.
2. **Execution-order matches commit-numbering:** Path A executes 1→2→3→[parallel 4,5,6,7,8,9a,11]→10→9b→12. Numbering and execution monotonically aligned. Path B requires the "Commit 10 before Commit 9" inversion, which is a documentation footnote burden.
3. **Marginal extra savings:** Path A saves ~5-15 minutes more wall-clock than Path B because Commit 9a parallelizes instead of running sequentially after Commit 10.
4. **Cleaner per-commit scope:** Path A Commit 9a is audience-header-only (single concern); Commit 9b is D8.6-ref-only (single concern). Path B Commit 9 carries two concerns (audience-header + D8.6 ref) that are conceptually independent — they just happen to live in the same file.

**Path B's merits remain:**
1. **One fewer commit:** 12 vs 13 — smaller audit-trail surface area.
2. **TASK-T5 stays as one commit:** A's §6.1 task partitioning preserved verbatim (A defines TASK-T5 as one logical unit).
3. **No extra Pack Chat orchestration:** Commit 9b is one more commit ceremony (read IMPL-REPORT, commit, push, await CI) — ~3-5 minutes of Pack Chat work per commit.

**Resolution (user decision 2026-05-19):**

The parallelism analysis shifted the balance toward Path A. User chose Path A explicitly on the parallelism-aware merits surfaced above:
- Cleaner parallel set (ALPHA-EXPANDED = 7 commits vs Path B ALPHA = 6 commits)
- Monotonic execution-order matches commit-numbering (no Path B "10 before 9" inversion)
- Single-concern commits (9a = audience header only; 9b = D8.6 ref-update only)
- +5-15 min marginal wall-clock save

OQ-1 closed; Path A authoritative throughout the plan. The §5 OQ-1 section now reads "RESOLVED" with this close-out cited.

**OQ-1 updated framing for user reconciliation:**

| Dimension | Path A (split V5; 13 commits) | Path B (one V5; 12 commits) |
|---|---|---|
| Commits | 13 | 12 |
| Parallel set size (after Commit 3) | 7 (ALPHA-EXPANDED includes 9a) | 6 (ALPHA only; 9 must wait for 10) |
| Wall-clock save vs sequential | ~30-90 min | ~25-75 min |
| Execution-order matches numbering | YES (1→2→3→[parallel]→10→9b→12) | NO (10 before 9 inversion) |
| Per-commit scope cleanliness | Cleaner (1 concern per commit) | Less clean (Commit 9 = 2 concerns) |
| Audit-trail footprint | Larger (1 extra commit) | Smaller |
| TASK-T5 preservation | Split (9a + 9b) | Intact (1 commit) |
| Pack Chat ceremony cost | +3-5 min for one extra commit | baseline |

**Historical: Question that was put to user on 2026-05-19** (now RESOLVED — Path A chosen): "Path A or Path B?"

### §8.6 — CI cascade risk + recovery pattern (general)

This sub-section applies to the chosen parallel-set push pattern (ALPHA-EXPANDED under Path A per OQ-1 RESOLVED 2026-05-19).

**Cascade definition:** When N commits are pushed serially to the same branch in quick succession, CI runs N workflow instances. GitHub Actions' default behavior on the pack repo: workflows are queued per-branch and run serially (one workflow finishes before the next on the same branch starts). N pushes → N workflow runs in sequence.

**Risk modes:**

1. **Mid-cascade failure (Commit K fails, K+1..N already pushed):** K's failure means the working tree at K is broken. K+1..N were pushed on top of K, so their CI runs will likely cascade-fail (each sits on broken state). However, the COMMITS themselves are not "wrong" — they reflect the coder's correct edits per the plan; the BREAKAGE is at K specifically. Recovery: identify K's failure root cause, spawn fresh pack-coder per pack-memory ("fresh coder per commit"), land fix as NEW commit on top of N (`fix: v11 — BD-175 ... (Batch P5-parallel-set-...)` per CLAUDE.md approved suffix). The fix commit subsumes K's intent; K-1 and earlier stay; K and K+1..N stay too (they don't need reverting — the fix on top restores correctness).
2. **Manifest drift between parallel coders' edits and Pack Chat's serial regen:** Coders edit working-tree files concurrently. Pack Chat commits serially. Between commit K and commit K+1, Pack Chat must regen the manifest (per RC9 for Y commits) and stage it with commit K+1's files. If Pack Chat regenerates manifest BEFORE stashing other coders' unstaged edits, the manifest captures their tree state too — see §8.7 for the corrected pattern.
3. **CI workflow runtime contention:** Multiple commits pushed in quick succession can queue past GitHub's free-tier minute limits (rare on this repo per current usage). Mitigation: push-then-wait pattern (commit, push, wait CI green, repeat) trades wall-clock for safety.

**Recommended Pack Chat CI orchestration pattern for parallel sets:**

- **First parallel batch (set ALPHA or ALPHA-EXPANDED):** Use push-then-wait. Land Commit 4, push, wait CI green, land Commit 5, push, wait, ... etc. Slower (~3-5 min CI wait per commit = 18-30 min of CI waiting for 6 commits) but isolates each commit's CI failure to that single commit (no cascade). Recommended for the FIRST parallel batch until the pattern is proven on this repo.
- **Subsequent parallel batches (if any):** Push-all-then-watch is acceptable once the pattern is proven. Faster wall-clock; cascade risk is the only downside, and recovery via NEW fix-commit is well-defined.

**Pack Chat's CI monitoring:** Per pack-memory `reference_github_mcp_availability` hint, GitHub MCP has no `list_workflow_runs` tool; use `gh run list` via Bash for workflow status. Pattern: `gh run list --branch v11-dev --limit 10 --json status,conclusion,headSha` after each push; wait until the latest run's `status` is `completed` and `conclusion` is `success` before pushing the next commit.

### §8.7 — Manifest-regen orchestration pattern (parallel-aware)

The manifest-regen rule (RC9) operates SEQUENTIALLY by Pack Chat, NOT by per-coder action. Per pack-memory "no worktree isolation" rule, ALL parallel coders edit the SAME working tree — which creates a subtle orchestration concern: a manifest regen captures the state of EVERY unstaged edit in the working tree, not just the files-for-this-commit. If Pack Chat commits Commit K's files first and then runs `bash test-fixtures/build.sh --all --clean`, the resulting manifest reflects K's staged tree PLUS any other parallel coders' UNSTAGED edits still sitting in the working tree. Those unrelated edits would bleed into Commit K's manifest delta, corrupting the audit trail.

**Correct pattern (git-stash isolation):**

```
[All parallel coders complete and exit. Working tree contains
 concurrent edits from 6 coders (or 7 under Path A ALPHA-EXPANDED).
 No coder ran git add or test-fixtures/build.sh.
 No coder ran git commit.]

[Pack Chat enters serial commit loop. For each commit K in
 chosen-order (suggested: trinity commits first per §4.3 → non-trinity):]

  1. Identify coder-K's file set (from coder-K IMPL-REPORT).

  2. Stash OTHER coders' working-tree edits to isolate K:
     git stash push -m "P5-parallel-other-coders-pre-K" \
       -- <files-not-in-coder-K-set>
     (only stash files NOT in K's set; this leaves K's files
      in the working tree and removes everyone else's)

  3. git add <coder-K files>

  4. IF commit K is v11-surface per §4.2:
        bash test-fixtures/build.sh --all --clean
        (manifest now reflects ONLY commit K's tree state since
         other coders' edits are stashed away)
        git diff test-fixtures/manifest.txt
        IF non-empty: git add test-fixtures/manifest.txt

  5. git commit -m "<commit K subject per §1>"

  6. git stash pop  (restore other coders' edits to working tree)

  7. git push  (per §8.6 CI orchestration: push-then-wait OR
                  push-all-then-watch per Pack Chat choice)

  Repeat for each commit in chosen-order.
```

**Why git-stash, not git-worktree:** Pack-memory's "no worktree isolation" rule applies to SUB-AGENT spawns (Agent-tool calls must not pass `isolation: "worktree"`). That rule does NOT prohibit Pack Chat from using `git stash` as an in-tree isolation primitive during the serial commit loop. Stash is local to Pack Chat's bash session; sub-agents are not involved.

**Edge case — file-disjoint but git-rename collision:** Commit 2 + Commit 3 use `git mv` to relocate files. If parallel set ALPHA includes a coder that needs to read or grep against `pack-ops/PACK-AGENTS.md` (which was `git mv`'d in Commit 2 — already committed before set ALPHA spawns), there's no collision because the rename was committed before the parallel batch started. The stash dance only stashes UNCOMMITTED working-tree edits.

**Alternative simpler pattern (NOT recommended):** Skip the stash dance; commit all parallel-set files in N commits WITHOUT per-commit manifest regen; do ONE manifest regen at the END of the parallel batch and stage it with a final `fix: v11 — BD-175 manifest regen (Batch P5-parallel-set-ALPHA)` commit per CLAUDE.md approved suffixes. This violates RC9's per-commit contract — every Y-marked commit in the parallel batch lands with a stale manifest until the regen commit lands, causing CI fixture-manifest-verify to FAIL on each interim commit. Recommended ONLY if user explicitly accepts the trade-off (one fix-commit per parallel batch in exchange for orchestration simplicity). **Planner default: USE THE STASH DANCE to honor RC9 per-commit.**

### §8.8 — Estimated wall-clock and token comparison

End-to-end estimates for Phase 5 with parallelism vs without. **Authoritative row is Path A ALPHA-EXPANDED per OQ-1 RESOLVED.** Path B rows preserved as comparison record:

| Scenario | Coder phase | Pack Chat triage + commit | CI phase (push-then-wait) | Total wall-clock | Total tokens |
|---|---|---|---|---|---|
| Fully sequential (12 commits, Path B baseline) | 60-180 min (12 × 5-15 min/coder) | 36-60 min (12 × 3-5 min/commit) | 36-60 min (12 × 3-5 min CI) | **132-300 min** | ~120-360k tokens |
| Path B with parallel set ALPHA (6 parallel + 6 sequential) | 15-30 min ALPHA + 30-90 min remaining 6 = 45-120 min | 36-60 min (still 12 commits) | 36-60 min (still 12 commits) | **117-240 min** | ~120-360k tokens (same) |
| Path A with parallel set ALPHA-EXPANDED (7 parallel + 6 sequential) | 15-30 min ALPHA-EXPANDED + 30-90 min remaining 6 (10, 9b, 12 + 3 other later batches if needed) = 45-120 min | 39-65 min (13 commits) | 39-65 min (13 commits) | **123-250 min** | ~130-390k tokens |

**Net wall-clock savings from parallelism:**
- Path B parallel set ALPHA: ~15-60 min saved vs sequential (10-25% reduction)
- Path A parallel set ALPHA-EXPANDED: ~10-50 min saved vs Path A sequential (8-20% reduction); marginal extra parallelism vs Path B ALPHA = ~5-10 min

**Net token cost:**
- Parallel and sequential are essentially IDENTICAL on tokens (each fresh coder reads same context regardless of timing).
- Path A has marginally more tokens than Path B (extra coder for Commit 9b = ~10-30k tokens).

**Recommendation summary (locked per user decisions 2026-05-19):**
- **Parallel set ALPHA-EXPANDED** (7 concurrent pack-coder spawns: Commits 4, 5, 6, 7, 8, 9a, 11) after Commit 3 lands. Per Path A per OQ-1 RESOLVED.
- **CI cascade: push-then-wait** for the parallel set ALPHA-EXPANDED batch — commit each member serially, push, wait CI green, then push the next. Cascade-isolation safety chosen.
- **Manifest regen: git-stash isolation pattern** (§8.7 — `git stash push -m "P5-parallel-other-coders-pre-K"` between commits) to honor RC9 per-commit manifest contract.
- **OQ-1 RESOLVED** — Path A chosen; no further user reconciliation needed.

## §7 — End-of-plan PREFLIGHT and meta

This plan covers:
- All 13 §C boundary violations (V1-V12 + T5-A + T5-B) per A's framework — addressed via Commits 4 (V1+T5-A+V8) + 5 (V3) + 6 (V7) + 7 (V6) + 9a (V5 audience header) + 9b (V5 D8.6 ref-update per Override 8 cascade) + 3 (V4 RELOCATE absorbs V2 + T5-B + §5 11-ref cluster) + cascade NO-ACTION (V10 per B1; V9/V11/V12 audit-clean)
- All 17 §D-9 confirmed CONTAMINATION refs — 15 SUBSUMED by V-decisions + 2 NEW (D8.6 in Commit 9b per Path A, D8.7 in Commit 10)
- All 8 §D AMBIGUOUS-other refs — 2 SUBSUMED + 1 NEW standalone (A2 in Commit 8) + 5 NEW cluster (A4-A8 LEGITIMATE post-SPLIT, verified in Commit 10)
- All 11 §D AMBIGUOUS-pending-§F refs — all SUBSUMED by V4 RELOCATE in Commit 3
- All 10 user overrides (per AUDIT-USER-CURATION.md) — explicit per-commit citation in §2.X.6 sub-sections + §6 cross-reference
- All Phase 3 reviewer findings (15 total: 1 BLOCKER + 4 MUST + 6 SHOULD + 4 NIT) — 12 VERIFIED + 3 status-only per VERIFICATION.md; the single carry-forward (M1 Option A) is encoded as the Commit 2 mandate
- M1 Option A combined commit is structurally inviolable in Commit 2 per Constraint 1
- Trinity rule honored per §4.3 (within-trinity-location parity at Commits 2, 4, 11, 12; Commits 9a + 9b have no trinity surface; cross-trinity drift gate REJECTED per Override 9 at Commit 12)
- RC9 manifest-regen marked per commit in §1 + §4.2; mandatory on all 8 v11-surface commits (Commits 2, 3, 4, 5, 6, 10, 11, 12); applied via git-stash isolation pattern per §8.7
- Override-source-wins enforced at every conflict — Commit 3 destination `pack-ops/` (Override 6 over B's original `maintenance-docs/`); Commit 11 REMOVE direction (Override 10 over retarget); Commit 10 SPLIT confirmed (Override 8 over A's DUAL-INSTALL fallback); Commit 12 different-wording-per-audience (Override 9 over default mirror)
- No state-changing git verbs by this plan — pure read-only on source; output is `PLAN-BD-175-PHASE-5.md` only
- Pack-coder PREFLIGHT + STOP-MEANS-STOP preamble noted per spawn (Pack Chat finalizes at spawn time per pack-memory)
- ZERO open questions remain. OQ-1 (Commit 9/10 execution ordering — Path A vs Path B) RESOLVED by user 2026-05-19: **Path A chosen** (split V5 into 9a + 9b; 13 commits total; parallel set ALPHA-EXPANDED = 7 commits including 9a; sequential tail = 10 → 9b → 12). User reasoning: clarity, monotonic ordering, single-concern commits, +5-15 min marginal wall-clock save per §8.5 close-out.

**PREFLIGHT:** PLAN-BD-175-PHASE-5.md covers ALL in-scope architect amendments (A + A-fix; B + B-fix-extension + B-fix-v2; C + C-fix + C-fix-v2) + ALL 10 user overrides (1, 2, 3, 4, 5, 6, 7, 8, 9, 10) + ALL 12 reviewer-verified fixes (B1 + M1 + M2 + M3 + M3 Override 10 cascade + M4 + S1 + S2 + S3 + S4 + S5 + S6 + N2) + Override 6 cascade + line 584 staleness. M1 Option A combined commit encoded as structurally inviolable Commit 2. Trinity rule + RC9 + override-authority preserved per commit. **OQ-1 RESOLVED 2026-05-19: Path A chosen** (13 commits total; parallel set ALPHA-EXPANDED = 7 commits; sequential tail = 10 → 9b → 12). **Chosen orchestration patterns: push-then-wait CI cascade + git-stash isolation manifest regen.** Phase 5 coder reading this plan executes 13 fresh-coder spawns mechanically; ZERO OPEN QUESTIONS remain.

