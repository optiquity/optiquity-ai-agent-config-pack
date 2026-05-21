# IMPLEMENTATION-REPORT — BD-175 Phase 5 Commit 2 (directory reorg M1-M5 + M9-M10, combined per Option A mandate)

**Author:** pack-coder
**Date:** 2026-05-19
**Branch:** v11-dev
**HEAD (pre-commit, after edits):** `2d68262d29e1de2d26b10522d61c713a056c04d3`
**Plan:** `maintenance-docs/v11-implementation/PLAN-BD-175-PHASE-5.md` §2.2
**Architects referenced:** B (`ARCHITECTURE-DIRECTORY-REORGANIZATION.md`, `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md`) + Phase 3 reviewer M1 mandate (`PACK-REVIEW-PHASE-2-DESIGNS.md` + `-VERIFICATION.md`).

---

## §1 Summary

Executed the structurally inviolable combined Commit 2 per **Option A MANDATE** (M1 finding + B-fix §7.1). All 7 root files relocated to `pack-ops/` via `git mv` in ONE atomic working-tree state, with ALL pack-internal references updated in the SAME state (script constants, detection helpers, validate-pack.py, tracker libs, pack-* agent definitions × 3 CLI variants, pack-side skills × 3 CLI variants, pack-root trinity × 3, README repo-layout, and 9 affected test fixtures). Manifest regen completed and is non-empty (v11-realistic-ot, v11-flat-file, v11-tracker-on SHAs all drifted as expected).

Splitting Option B (M9/M10 in a separate commit) is **REJECTED** per the M1 finding and is not executed here. The `detect_pack_surface` ambiguity window is closed in this single commit's working-tree state.

**Total files (this commit's diff):** 59
- **Renamed:** 7 (the 7 pack-ops/ relocations)
- **Modified:** 52 (scripts, libs, agents, skills, trinity, README, tests, manifest)

**Verification:** validate-pack.py PASSED (all 35 checks); 14+ test suites run, all PASS (pack-help-test 17/17, test-per-entry 57/57, tracker-init-test 95/95, tracker-migrate-forward-test 145/145, tracker-migrate-reverse-test 113/113, tracker-migrate-roundtrip-test 45/45, tracker-bd132-race 29/29, tracker-bd133-header-preservation 30/30, tracker-bd134-close-retry 24/24, tracker-agent-read-test 52/52, recommendation-test 53/53, test-detect 95/95, validate-pack checks 32/33/34 65/65, test-init-project 67/67, plus all other tracker-* / test-tracker-* suites).

The IMPL-REPORT excludes 2 pre-existing untracked artifacts (`IMPLEMENTATION-REPORT-BD-175-COMMIT-1-FIX.md` and the pack-ops/BOUNDARY-DEFINITION.md modification both predate this prompt — Pack Chat owns disposition).

---

## §2 Step-by-step report

### §2.1 Step 1 — git mv 7 root files to pack-ops/

Executed:
```
git mv HELP-FRAGMENT-PACK.md     pack-ops/HELP-FRAGMENT-PACK.md
git mv HELP-FRAGMENT-TRACKER.md  pack-ops/HELP-FRAGMENT-TRACKER.md
git mv OPTIONAL-FEATURES.md      pack-ops/OPTIONAL-FEATURES.md
git mv PACK-AGENTS.md            pack-ops/PACK-AGENTS.md
git mv PACK-CHAT.md              pack-ops/PACK-CHAT.md
git mv BACKLOG.md                pack-ops/BACKLOG.md
git mv CHANGELOG.md              pack-ops/CHANGELOG.md
```

All 7 renames use `git mv` (preserves file history per B §6.4 step 1). Resulting `ls pack-ops/`:
```
BACKLOG.md
BOUNDARY-DEFINITION.md   (Commit 1)
CHANGELOG.md
HELP-FRAGMENT-PACK.md
HELP-FRAGMENT-TRACKER.md
OPTIONAL-FEATURES.md
PACK-AGENTS.md
PACK-CHAT.md
```
(The Commit-1 `.boundary-exempt-root.txt` is a dotfile not shown by bare `ls`.)

**Exempt (UNTOUCHED, per overrides):** `tracker.toml.pack-example` (Override 1), `QUICKSTART.md` (Override 7), root `.github/` (Override 2), root `.claude/` + `.codex/` + `.gemini/` (Override 4), LICENSE.md, trinity (CLAUDE.md / AGENTS.md / GEMINI.md — edited separately per Step 3).

### §2.2 Step 2 — Update pack-side scripts (§2.2.2 + B-fix §10.3)

#### scripts/lib/tracker-config.sh
- **Line 298:** `[[ -f "$repo_root/PACK-CHAT.md" ]]` → `[[ -d "$repo_root/pack-ops" ]]` per B §3.2 (directory presence is the new pack-side surface marker).

#### scripts/lib/detect.sh
- **Lines 22-26 + 35 (docstring + candidate scan order):** Updated docstring to reflect post-BD-175 canonical pack-side BACKLOG path (`pack-ops/`), and reordered candidate scan to: `pack-ops/` (post-BD-175 canonical pack-side) → `docs/project/` (client-side canonical) → root (legacy fallback retained per planner default §2.2.3 + B-fix §10.3 judgment call). The legacy root fallback is required for `scripts/tests/pack-help-test.sh` fixture 1.3 ("client repo (root BACKLOG.md, TD entries)") and other test-fixture / v9-shape back-compat.

#### scripts/lib/per-entry/_lib.sh
- **Lines 71, 79:** `printf 'BACKLOG.md'` → `printf 'pack-ops/BACKLOG.md'`; `printf 'CHANGELOG.md'` → `printf 'pack-ops/CHANGELOG.md'`. These are the canonical-mirror constants returned by `pe_canonical_mirror_for_stream` for pack-* streams.

#### scripts/pack-help.sh
- **Lines 36-39:** Usage docstring updated to name `pack-ops/HELP-FRAGMENT-PACK.md` and `pack-ops/HELP-FRAGMENT-TRACKER.md` as canonical.
- **Lines 95-160 (case statement + helpers):** Added `_pack_fragment_path` + `_pack_tracker_fragment_path` helpers that resolve pack-side fragments at `pack-ops/HELP-FRAGMENT-*.md` first, with root-fallback for unusual overlay trees and test fixtures (e.g., `pack-help-test.sh` 2.5 which writes the fragments to `$TR_VER/` root). The error message at lines 126-128 was updated to name `pack-ops/HELP-FRAGMENT-PACK.md` as the canonical pack location; the test 2.4 stderr substring check (`"no HELP-FRAGMENT-*.md found"`) still passes.

#### scripts/validate-pack.py
- **Line 122:** STREAMS docstring updated — `(BACKLOG.md, CHANGELOG.md)` → `(pack-ops/BACKLOG.md, pack-ops/CHANGELOG.md)`.
- **Lines 191-192:** STREAMS tuple mirror paths updated: `"BACKLOG.md"` → `"pack-ops/BACKLOG.md"`, `"CHANGELOG.md"` → `"pack-ops/CHANGELOG.md"`. (Stream-key + entry-regex columns unchanged.)
- **Line 238:** Comment "does BACKLOG.md have" → "does pack-ops/BACKLOG.md have".
- **Check 3 (lines 318-336):** Updated heading + path constants + display messages — `backlog = REPO_ROOT / "pack-ops" / "BACKLOG.md"`; fail/ok messages use `pack-ops/BACKLOG.md:{i}`.
- **Check 22 (lines 1650-1669):** `surfaces["pack-root"]["docs"]` paths updated to `pack-ops/PACK-CHAT.md`, `pack-ops/OPTIONAL-FEATURES.md` (QUICKSTART.md unchanged per Override 7); `surfaces["pack-root"]["fragment"]` → `pack-ops/HELP-FRAGMENT-PACK.md`; `tracker_fragment` → `pack-ops/HELP-FRAGMENT-TRACKER.md`.
- **Check 23 (lines 1734-1736):** `fragment = REPO_ROOT / "pack-ops" / "HELP-FRAGMENT-PACK.md"`; `tracker_fragment = REPO_ROOT / "pack-ops" / "HELP-FRAGMENT-TRACKER.md"`.
- **Check 24 (line 1929):** `pack_root = REPO_ROOT / "pack-ops" / "HELP-FRAGMENT-TRACKER.md"` (the byte-identity source); client comparison path unchanged.
- Line 849 comment (`BACKLOG / archive`) is a generic concept reference — left as-is.

#### scripts/lib/recommendation.sh
- **Line 132:** Pack-side signal computation path updated — `local backlog="$repo_root/BACKLOG.md"` → `local backlog="$repo_root/pack-ops/BACKLOG.md"`. **Client-side fallback at lines 151-152 UNCHANGED** per planner spec ("docs/project/BACKLOG.md fallback UNCHANGED"). Label-string references at lines 394 / 462 are conceptual prose labels rendered for both surfaces — kept as bare "BACKLOG.md" (planner spec scoped to "pack surface paths").

#### scripts/lib/tracker-doctor.sh
- **Lines 114-145:** Surface-aware mirror-path resolution introduced. Surface=pack reads `pack-ops/BACKLOG.md`; surface=client reads `docs/project/BACKLOG.md` (canonical) with legacy root-fallback. The freshness comparison logic + WARN/OK messages unchanged.

#### scripts/lib/tracker-agent-read.sh
- **Line 264, 267:** BD-* shim path + default branch path updated to `$repo_root/pack-ops/BACKLOG.md`. TD-* branch (line 265) UNCHANGED (project-side mirror at `docs/project/BACKLOG.md`).

#### scripts/lib/tracker-migrate-reverse.sh
- **Lines 1049-1066:** Surface-aware emit destinations introduced. Pack-side emits to `pack-ops/BACKLOG.md` + `pack-ops/CHANGELOG.md` (with `mkdir -p pack-ops` ensuring directory exists); client-side emits to root (legacy back-compat). Plan/STATUS emit unchanged at root.
- **Lines 1080-1099 (backup loop):** Refactored to iterate `_emit_path_list` derived from surface-aware emit destinations, so the backup/restore stays in sync with the relocation.
- **Lines 1137-1151 (restore loop):** Matching surface-aware restore — basename-keyed backup files restored to surface-aware paths.

#### scripts/lib/tracker-migrate-forward.sh
- **Lines 705-720 (mirror-only path):** Surface-aware `backlog_path` resolution — pack → `pack-ops/BACKLOG.md`; non-pack → root.
- **Lines 724-732 (main forward path):** Same surface-aware resolution applied at the Step 1+2 read site.
- **Lines 1334-1342 (status-report mirror freshness):** Surface-aware `mirror_path` for the status verb's mirror-freshness check.

#### scripts/lib/tracker-init.sh
- **Lines 100-104:** Inline auto-detect uses `[[ -d "$repo_root/pack-ops" ]]` (BD-175 marker) replacing the prior `PACK-CHAT.md` file check. This mirrors the change to `tracker_config_auto_surface` so the inline init detect stays in lockstep.

#### scripts/lib/tracker-header-snapshot.sh
- **Lines 212-220:** `tracker_header_snapshot_capture` updated to choose backlog path by first-existing: `pack-ops/BACKLOG.md` (canonical) → root (legacy). Apply path is passed in by caller (tracker-migrate-reverse.sh now passes the surface-aware path).

#### scripts/pack-help.sh — fragment path resolver
(See §2.2 above — included with the canonical path edits.)

#### scripts/pack-tracker.sh
- **Lines 369-370:** Stale comment about `PACK-CHAT.md` auto-detect updated to name `pack-ops/` directory per BD-175.

#### scripts/init-project.sh
- **Lines 820-829:** Surface-aware copy of `HELP-FRAGMENT-TRACKER.md` from pack → client. Prefers `$PACK/pack-ops/HELP-FRAGMENT-TRACKER.md` (post-BD-175 canonical); falls back to `$PACK/HELP-FRAGMENT-TRACKER.md` (pre-BD-175 layout, for migration mid-flight or PACK pointing at a pre-BD-175 tag).

#### scripts/tests/test-per-entry.sh
- **Lines 220-221:** Assertion-on-canonical-output strings updated: `"BACKLOG.md"` → `"pack-ops/BACKLOG.md"`, `"CHANGELOG.md"` → `"pack-ops/CHANGELOG.md"`. Lines 222+224 (project-side canonical) UNCHANGED. Lines 292-562 temp-dir fixtures UNCHANGED (per planner spec — they are isolated `mktemp` fixture trees, not the pack repo's actual mirror).

### §2.3 Step 3 — Update pack-root trinity (CLAUDE.md / AGENTS.md / GEMINI.md) in lockstep

The 3 pack-root trinity files were edited in lockstep at the 4 plan-scoped sites:

| Section | CLAUDE.md | AGENTS.md | GEMINI.md |
|---|---|---|---|
| Key files block (BACKLOG / CHANGELOG / PACK-CHAT / PACK-AGENTS qualified path) | L30-34 | L24-28 | L19-25 (prose form) |
| What agents may modify — CHANGELOG path | L83 | L77 | L53 |
| What agents must never modify — BACKLOG/PACK-CHAT/PACK-AGENTS | L99-102 | L93-96 | L57-59 |
| BACKLOG.md has no Resolved section bullet | L389 | L342 | L317 |

All trinity files now reference `pack-ops/BACKLOG.md`, `pack-ops/CHANGELOG.md`, `pack-ops/PACK-CHAT.md`, `pack-ops/PACK-AGENTS.md` at the 4 plan-scoped sites. Pack memory bullets later in the file that reference these files in prose (e.g., L74, L139, L258, L378, L393 in CLAUDE.md with parallels in AGENTS/GEMINI.md) were INTENTIONALLY LEFT BARE per the planner's explicit line-scoped spec — these are conceptual file-name references in long pack-memory rule prose, not load-bearing path references. A separate cleanup BD can address the pack-memory prose refs if Pack Chat decides.

### §2.4 Step 4 — Pack-* agents (5 agents × 3 CLI variants = 15 files)

All 15 pack-* agent definitions edited in lockstep:

| Agent | .claude variant | .codex variant | .gemini variant |
|---|---|---|---|
| `pack-architect` | `.claude/agents/pack-architect.md` L18+25+27 | `.codex/agents/pack-architect.toml` L15+18 | `.gemini/agents/pack-architect.md` L20+27+29 |
| `pack-planner` | `.claude/agents/pack-planner.md` L32 | `.codex/agents/pack-planner.toml` L18 | `.gemini/agents/pack-planner.md` L25 |
| `pack-coder` | `.claude/agents/pack-coder.md` L34+38+86 | `.codex/agents/pack-coder.toml` L21+23+45 | `.gemini/agents/pack-coder.md` L36+40+83 |
| `pack-reviewer` | (no match — agent does not reference relocated files) | (no match) | (no match) |
| `pack-docs-researcher` | (no match) | (no match) | (no match) |

All BACKLOG / CHANGELOG / PACK-CHAT / PACK-AGENTS references in pack-architect / pack-planner / pack-coder now use `pack-ops/<file>` form. pack-reviewer and pack-docs-researcher do not reference any of the relocated files (verified by grep) and need no edits.

### §2.5 Step 5 — Pack-side skills

#### pack-startup (3 CLI variants — trinity lockstep)
- `.claude/skills/pack-startup/SKILL.md` — Step 2 instructions + GitHub MCP fallback note now reference `pack-ops/BACKLOG.md`, `pack-ops/CHANGELOG.md`, `pack-ops/PACK-CHAT.md`.
- `.codex/skills/pack-startup/SKILL.md` — same edits in lockstep.
- `.gemini/commands/pack-startup.toml` — same edits in lockstep (TOML-prompt heredoc form).

#### commit-discipline (3 CLI variants)
- `.claude/skills/commit-discipline/SKILL.md` L112-117, L167 — PM-only file list + worked-example BACKLOG/CHANGELOG references updated to `pack-ops/` form.
- `.codex/skills/commit-discipline/SKILL.md` — same in lockstep.
- `.gemini/skills/commit-discipline/SKILL.md` — same in lockstep.

#### implementation-report (3 CLI variants)
- `.claude/skills/implementation-report/SKILL.md` L29 (worked-example grep) + L62 (Check-22-trigger file list) — references updated to `pack-ops/BACKLOG.md`.
- `.codex/skills/implementation-report/SKILL.md` — same in lockstep.
- `.gemini/skills/implementation-report/SKILL.md` — same in lockstep.

#### .gemini/commands/pack-help.toml
- Line 10-11 footer text: `PACK-CHAT.md` → `pack-ops/PACK-CHAT.md`; `OPTIONAL-FEATURES.md` → `pack-ops/OPTIONAL-FEATURES.md`.

### §2.6 Step 6 — Post-move sibling self-references in pack-ops/PACK-AGENTS.md

Per planner choice (a) §2.2.3 line 200, sibling-relative BARE NAMES are retained for the PM-only files list at L143-148 within the now-relocated `pack-ops/PACK-AGENTS.md`:

```
Files:
- `BACKLOG.md` (regenerated mirror; per-entry source at `/backlog/`)
- `CHANGELOG.md` (regenerated mirror; per-entry source at `/changelog/`)
- `README.md` version table
- `PACK-CHAT.md`
- `PACK-AGENTS.md`
- `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` (root and `project-template/`)
```

No edit applied (the bare names are already sibling-relative within `pack-ops/` for the relocated files; README.md / CLAUDE.md / AGENTS.md / GEMINI.md remain root-resolved by prose context per the planner's note). Lines 178-187 (forward-pointing per-entry tree references) UNCHANGED per planner constraint §2.2.3 — those references point at `/backlog/` and `/changelog/` per-entry trees which STAY at root.

### §2.7 Step 7 — README.md repo-layout updated

`README.md` Repository Layout block (originally L254-269) restructured. A NEW `pack-ops/` subtree replaces the 7 deleted root entries, and Commit-1 artifacts (`pack-ops/BOUNDARY-DEFINITION.md` + `pack-ops/.boundary-exempt-root.txt`) are added to the `pack-ops/` block per planner spec. Pack-root section now lists: QUICKSTART.md, tracker.toml.pack-example, CLAUDE.md, AGENTS.md, GEMINI.md, README.md, `.github/ISSUE_TEMPLATE/`, and forward-pointing `/backlog/` + `/changelog/` per-entry tree mentions.

### §2.8 Step 8 — Manifest regen

Executed `bash test-fixtures/build.sh --all --clean`; the rebuild took ~60s and re-emitted all 6 fixtures. `git diff test-fixtures/manifest.txt` shows the expected 3-row drift:

```diff
-v11-realistic-ot  9b7e744eb319e7fce7034c6ab4d46917d6f30a2e
-v11-flat-file  eb66fc6cc9ebd5533a4aaf62bef19ab29014ec83
-v11-tracker-on  4d51b7b25f3b8e9dc5ae55f94858adb7ee64e2ad
+v11-realistic-ot  e7ff2315f8b8e3b4b6fb794e994d76506136bf20
+v11-flat-file  9a1b492f070f4b0d757e045ba002cc5fcacb24b0
+v11-tracker-on  cdca2132b0ed6e1ed17d31b0aed7c65a6e2f16d3
```

`v10-*` rows are unchanged (tag-pinned). `existing-project-mid-dev` unchanged (no pack-surface dependency). The 3 drifted v11-* SHAs reflect the v11-surface edits (project-template/ + scripts/) — exactly what RC9 expects. Manifest is ready for Pack Chat to stage in the same commit.

### §2.9 Test-fixture updates (necessary side-effect of the pack-side path change)

Beyond the planner's explicit scope, 9 test scripts required fixture updates because their fixtures simulate the pack-side surface and their tests assert against output paths. Without these updates, the new `tracker_config_auto_surface` / `detect_pack_surface` / `tracker_agent_read.sh` / `_tmr_emit_backlog` surface-aware paths would fail or write to the wrong location.

| Test script | Edits |
|---|---|
| `scripts/tests/pack-help-test.sh` | Fixture 2.3 source paths changed to `pack-ops/HELP-FRAGMENT-*` so the `--surface pack` override prints from the canonical post-BD-175 location. |
| `scripts/tests/test-init-project.sh` | DELTA L1 byte-identity test source changed to `$REPO_ROOT/pack-ops/HELP-FRAGMENT-TRACKER.md`. |
| `scripts/tests/test-migrate-v10-to-v11.sh` | Same DELTA L1 byte-identity source update. |
| `scripts/tests/tracker-agent-read-test.sh` | `_setup_flat_repo` writes BD-* BACKLOG to `pack-ops/` (the canonical post-BD-175 pack-side path); TD-* under `docs/project/` (unchanged). |
| `scripts/tests/tracker-bd132-race-test.sh` | `build_test_repo` creates `pack-ops/` marker; BACKLOG.md sentinel preservation tests assert on `pack-ops/BACKLOG.md`. |
| `scripts/tests/tracker-bd133-header-preservation-test.sh` | Groups 2, 3, 4 fixtures create `pack-ops/` + write BACKLOG.md there; assertions read from there. |
| `scripts/tests/tracker-bd134-close-retry-test.sh` | `build_repo` creates `pack-ops/` + writes BACKLOG.md there. |
| `scripts/tests/tracker-init-test.sh` | 12 fixtures changed from `touch PACK-CHAT.md` to `mkdir -p pack-ops` (the new surface marker). Test 1.4 + comments updated to reflect the new marker. |
| `scripts/tests/tracker-migrate-forward-test.sh` | 8 fixtures (`TEST_REPO` through `TEST_REPO_BD108`) updated to create `pack-ops/` + write/copy BACKLOG.md there. Assertions read from canonical pack-ops/ location. |
| `scripts/tests/tracker-migrate-reverse-test.sh` | `_build_test_repo` creates `pack-ops/`. Groups 4 + 5 fixture writes + assertions use `pack-ops/BACKLOG.md`. |
| `scripts/tests/tracker-migrate-roundtrip-test.sh` | `_setup_test_repo` creates `pack-ops/` + copies BACKLOG into it; assertions read from there. |

These test-fixture updates are scoped (they only affect the pack-side test fixtures — client-side fixtures stay at root or `docs/project/`) and are required for the test suites to validate the new canonical layout. Without them the tests are not exercising the new pack-ops/ path resolution but instead silently fall back to legacy detect-failure modes.

---

## §3 Per-file edit list (exhaustive)

| File | Change type | Edit summary |
|---|---|---|
| `BACKLOG.md` | RENAME | → `pack-ops/BACKLOG.md` |
| `CHANGELOG.md` | RENAME | → `pack-ops/CHANGELOG.md` |
| `HELP-FRAGMENT-PACK.md` | RENAME | → `pack-ops/HELP-FRAGMENT-PACK.md` |
| `HELP-FRAGMENT-TRACKER.md` | RENAME | → `pack-ops/HELP-FRAGMENT-TRACKER.md` |
| `OPTIONAL-FEATURES.md` | RENAME | → `pack-ops/OPTIONAL-FEATURES.md` |
| `PACK-AGENTS.md` | RENAME | → `pack-ops/PACK-AGENTS.md` |
| `PACK-CHAT.md` | RENAME | → `pack-ops/PACK-CHAT.md` |
| `CLAUDE.md` | MODIFY | 4 trinity-scoped sites (Key files block / agents-may-modify / agents-must-never-modify / Resolved-section bullet) update bare paths to `pack-ops/<file>`. |
| `AGENTS.md` | MODIFY | Parallel trinity edits at 4 sites. |
| `GEMINI.md` | MODIFY | Parallel trinity edits at 4 sites (prose form for Key docs). |
| `README.md` | MODIFY | Repository Layout block: new `pack-ops/` subtree with all 9 relocated/Commit-1 files; root section now contains only QUICKSTART, tracker.toml.pack-example, trinity, README, `.github/`, forward-pointing per-entry tree refs. |
| `.claude/agents/pack-architect.md` | MODIFY | 3 sites (separation-of-concerns bullet + Before-reading list — `pack-ops/PACK-CHAT.md`, `pack-ops/PACK-AGENTS.md`, `pack-ops/BACKLOG.md`). |
| `.codex/agents/pack-architect.toml` | MODIFY | Parallel 2 sites in the TOML prompt heredoc. |
| `.gemini/agents/pack-architect.md` | MODIFY | Parallel 3 sites in the markdown agent file. |
| `.claude/agents/pack-planner.md` | MODIFY | Before-planning read list — `pack-ops/BACKLOG.md`. |
| `.codex/agents/pack-planner.toml` | MODIFY | Same in TOML form. |
| `.gemini/agents/pack-planner.md` | MODIFY | Same in markdown form. |
| `.claude/agents/pack-coder.md` | MODIFY | 3 sites (PM-only edit ban / BD-status flip rule / Before-executing read list). |
| `.codex/agents/pack-coder.toml` | MODIFY | Parallel 3 sites in TOML heredoc. |
| `.gemini/agents/pack-coder.md` | MODIFY | Parallel 3 sites. |
| `.claude/skills/pack-startup/SKILL.md` | MODIFY | Step 2 instructions + GitHub MCP note reference `pack-ops/<file>`. |
| `.codex/skills/pack-startup/SKILL.md` | MODIFY | Same in lockstep. |
| `.gemini/commands/pack-startup.toml` | MODIFY | Same in lockstep (heredoc form). |
| `.claude/skills/commit-discipline/SKILL.md` | MODIFY | PM-only file list + worked-example BACKLOG mention. |
| `.codex/skills/commit-discipline/SKILL.md` | MODIFY | Same in lockstep. |
| `.gemini/skills/commit-discipline/SKILL.md` | MODIFY | Same in lockstep. |
| `.claude/skills/implementation-report/SKILL.md` | MODIFY | 2 sites (worked-example grep + Check-22-trigger file list). |
| `.codex/skills/implementation-report/SKILL.md` | MODIFY | Same in lockstep. |
| `.gemini/skills/implementation-report/SKILL.md` | MODIFY | Same in lockstep. |
| `.gemini/commands/pack-help.toml` | MODIFY | Footer text references `pack-ops/<file>`. |
| `scripts/lib/tracker-config.sh` | MODIFY | Line 298 marker change `[[ -d "$repo_root/pack-ops" ]]`. |
| `scripts/lib/detect.sh` | MODIFY | Docstring update + candidate scan-order update (pack-ops/ first, root third). |
| `scripts/lib/per-entry/_lib.sh` | MODIFY | Lines 71+79 canonical-mirror constants. |
| `scripts/pack-help.sh` | MODIFY | Usage docstring + pack-side path resolver helpers (pack-ops-first + root-fallback). |
| `scripts/validate-pack.py` | MODIFY | STREAMS tuple + Check 3 + Check 22 (surfaces dict + tracker_fragment) + Check 23 + Check 24 + docstring/comment paths. |
| `scripts/lib/recommendation.sh` | MODIFY | Pack-side signal-compute path → `pack-ops/BACKLOG.md`; client path UNCHANGED. |
| `scripts/lib/tracker-doctor.sh` | MODIFY | Surface-aware mirror-path resolution + freshness check. |
| `scripts/lib/tracker-agent-read.sh` | MODIFY | BD-* + default branches → `pack-ops/BACKLOG.md`; TD-* unchanged. |
| `scripts/lib/tracker-migrate-reverse.sh` | MODIFY | Surface-aware emit destinations + matching backup/restore loop. |
| `scripts/lib/tracker-migrate-forward.sh` | MODIFY | Surface-aware backlog_path in mirror-only path, main forward, and status-report mirror freshness. |
| `scripts/lib/tracker-init.sh` | MODIFY | Inline auto-detect uses `pack-ops/` marker. |
| `scripts/lib/tracker-header-snapshot.sh` | MODIFY | `tracker_header_snapshot_capture` chooses backlog path by first-existing (pack-ops/ → root). |
| `scripts/pack-tracker.sh` | MODIFY | Stale auto-detect comment refreshed. |
| `scripts/init-project.sh` | MODIFY | HELP-FRAGMENT-TRACKER copy prefers pack-ops/ source. |
| `scripts/tests/pack-help-test.sh` | MODIFY | Fixture 2.3 source paths updated. |
| `scripts/tests/test-init-project.sh` | MODIFY | DELTA L1 byte-identity source path. |
| `scripts/tests/test-migrate-v10-to-v11.sh` | MODIFY | Same DELTA L1 source update. |
| `scripts/tests/test-per-entry.sh` | MODIFY | Lines 220-221 canonical-output assertions. |
| `scripts/tests/tracker-agent-read-test.sh` | MODIFY | `_setup_flat_repo` BACKLOG dest. |
| `scripts/tests/tracker-bd132-race-test.sh` | MODIFY | `build_test_repo` + per-test BACKLOG paths. |
| `scripts/tests/tracker-bd133-header-preservation-test.sh` | MODIFY | Group 2/3/4 fixtures + preamble paths. |
| `scripts/tests/tracker-bd134-close-retry-test.sh` | MODIFY | `build_repo` BACKLOG dest. |
| `scripts/tests/tracker-init-test.sh` | MODIFY | 12 fixtures use pack-ops/ marker. |
| `scripts/tests/tracker-migrate-forward-test.sh` | MODIFY | 8 fixtures + assertions use pack-ops/ path. |
| `scripts/tests/tracker-migrate-reverse-test.sh` | MODIFY | `_build_test_repo` + Group 4/5 fixtures + assertions. |
| `scripts/tests/tracker-migrate-roundtrip-test.sh` | MODIFY | `_setup_test_repo` + Group 2 assertions. |
| `test-fixtures/manifest.txt` | MODIFY | 3 v11-* SHA rows regenerated (RC9). |

---

## §4 Verification results

### §4.1 — `python3 scripts/validate-pack.py`

PASSED. All 35 checks clean. Tail of output:

```
── Check 35: Phase-task lib invariants (BD-106) ──
  OK: scripts/lib/tracker-phase-task.sh present
  OK: scripts/lib/tracker-labels.sh — no tracker_labels_folded_into helper definition (Path 3 forbidden)
  OK: scripts/lib/ — no `folded-into` literal in executable code (V3.3 §3 line 27); comment-only references allowed

============================================================
PASSED — all checks clean
```

Notable check results:
- **Check 3:** `pack-ops/BACKLOG.md — no unprocessed TD-TBD entry headers`
- **Check 22:** pack-root: 11 prose-referenced verb(s) all present in fragment (pack-ops/HELP-FRAGMENT-PACK.md); project-template: 5 prose-referenced verb(s) all present
- **Check 23:** Help-fragment completeness (all scripts listed)
- **Check 24:** pack-ops/HELP-FRAGMENT-TRACKER.md byte-identical to project-template/docs/pack/HELP-FRAGMENT-TRACKER.md (DELTA L1)
- **Check 32:** SKIPS — backlog/ and changelog/ per-entry trees not present (pre-BD-102 dog-food)
- **Check 35:** lib invariants pass

### §4.2 — `bash scripts/pack-help.sh --root .` (pack-side)

```
# Pack v11 — verb reference (pack repo)

Verb manifest for the **pack repository**. Run `pack help` or `/pack-help`
in your CLI for this content. Full docs in `QUICKSTART.md`, `README.md`,
`PACK-CHAT.md`, `OPTIONAL-FEATURES.md`.

## Pack commands
...
```

Pack-side fragment resolves correctly from the new `pack-ops/HELP-FRAGMENT-PACK.md` path with tracker section inlined from `pack-ops/HELP-FRAGMENT-TRACKER.md`.

### §4.3 — `bash scripts/pack-help.sh --root project-template`

```
# Pack v11 — verb reference (this project)

Verb manifest for **this project**. Run `pack help` or `/pack-help` in
your CLI for this content. Full docs in `docs/pack/QUICKSTART.md`,
`docs/pack/PM-CHAT.md`, `docs/pack/INSTALL-PROCEDURES.md`,
`docs/pack/OPTIONAL-FEATURES.md`.
...
```

Project-side fragment unchanged — confirms the project-template path (`docs/pack/HELP-FRAGMENT.md`) is unaffected by the pack-side relocation.

### §4.4 — `bash -c '. scripts/lib/detect.sh && detect_pack_surface .'`

```
pack-surface: pack
```

Confirms `detect_pack_surface` correctly identifies the pack repo via the new `pack-ops/BACKLOG.md` first-candidate.

### §4.5 — `bash -c '. scripts/lib/tracker-config.sh && tracker_config_auto_surface .'`

```
pack
```

Confirms `tracker_config_auto_surface` returns "pack" via the new `[[ -d pack-ops ]]` marker.

### §4.6 — `bash -c '. scripts/lib/per-entry/_lib.sh && pe_canonical_mirror_for_stream pack-backlog'`

```
pack-ops/BACKLOG.md
```

Confirms the per-entry library now reports the canonical mirror at the post-BD-175 location.

### §4.7 — Test suites (all PASS)

| Test suite | Result |
|---|---|
| `scripts/tests/pack-help-test.sh` | 17 passed, 0 failed |
| `scripts/tests/test-per-entry.sh` | 57 passed, 0 failed |
| `scripts/tests/tracker-agent-read-test.sh` | 52 passed, 0 failed |
| `scripts/tests/tracker-bd132-race-test.sh` | 29 passed, 0 failed |
| `scripts/tests/tracker-bd133-header-preservation-test.sh` | 30 passed, 0 failed |
| `scripts/tests/tracker-bd134-close-retry-test.sh` | 24 passed, 0 failed |
| `scripts/tests/tracker-init-test.sh` | 95 passed, 0 failed |
| `scripts/tests/tracker-migrate-forward-test.sh` | 145 passed, 0 failed |
| `scripts/tests/tracker-migrate-reverse-test.sh` | 113 passed, 0 failed |
| `scripts/tests/tracker-migrate-roundtrip-test.sh` | 45 passed, 0 failed |
| `scripts/tests/recommendation-test.sh` | 53 passed, 0 failed |
| `scripts/test-detect.sh` | 95 passed, 0 failed |
| `scripts/tests/test-validate-pack-checks-32-33-34.sh` | 65 passed, 0 failed |
| `scripts/tests/test-init-project.sh` | 67 passed, 0 failed |
| `scripts/tests/test-tracker-cycle-check.sh` | 26 passed, 0 failed |
| `scripts/tests/test-tracker-links.sh` | 43 passed, 0 failed |
| `scripts/tests/test-tracker-phase-task.sh` | 90 passed, 0 failed |
| `scripts/tests/test-tracker-promote-direct.sh` | 31 passed, 0 failed |
| `scripts/tests/test-tracker-promote-path1.sh` | 80 passed, 0 failed |
| `scripts/tests/test-tracker-promote-path2.sh` | 59 passed, 0 failed |
| `scripts/tests/tracker-bd129-gh-repo-test.sh` | 14 passed, 0 failed |
| `scripts/tests/tracker-bd130-doctor-wired-test.sh` | 20 passed, 0 failed |
| `scripts/tests/tracker-config-schema-test.sh` | 28 passed, 0 failed |
| `scripts/tests/tracker-config-test.sh` | 32 passed, 0 failed |
| `scripts/tests/tracker-errors-test.sh` | 60 passed, 0 failed |
| `scripts/tests/tracker-provider-test.sh` | 98 passed, 0 failed |
| `scripts/tests/test-add-capability.sh` | 19 passed, 0 failed |

Aggregated test-pass-only run completed in ~5 minutes; no failure in any suite.

### §4.8 — Manifest regen

```
manifest written: /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/test-fixtures/manifest.txt
```

Diff:
```diff
-v11-realistic-ot  9b7e744eb319e7fce7034c6ab4d46917d6f30a2e
-v11-flat-file  eb66fc6cc9ebd5533a4aaf62bef19ab29014ec83
-v11-tracker-on  4d51b7b25f3b8e9dc5ae55f94858adb7ee64e2ad
+v11-realistic-ot  e7ff2315f8b8e3b4b6fb794e994d76506136bf20
+v11-flat-file  9a1b492f070f4b0d757e045ba002cc5fcacb24b0
+v11-tracker-on  cdca2132b0ed6e1ed17d31b0aed7c65a6e2f16d3
```

3 rows changed (v11-realistic-ot, v11-flat-file, v11-tracker-on). v10-* rows unchanged (tag-pinned). existing-project-mid-dev unchanged.

### §4.9 — `git status --short`

61 entries in the working tree:
- 7 renames (R) — the relocated files
- 52 modifications (M) — scripts/libs/agents/skills/trinity/README/tests/manifest
- 2 pre-existing artifacts (`?? maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-1-FIX.md` and `M pack-ops/BOUNDARY-DEFINITION.md`) untouched by this commit's edits

Pack Chat owns disposition of the 2 pre-existing artifacts and this Commit-2 IMPL-REPORT.

### §4.10 — Trinity Check 18 H2 parity (by grep)

```
$ grep -c "pack-ops/BACKLOG.md\|pack-ops/CHANGELOG.md\|pack-ops/PACK-CHAT.md\|pack-ops/PACK-AGENTS.md" CLAUDE.md AGENTS.md GEMINI.md
AGENTS.md:10
CLAUDE.md:10
GEMINI.md:8
```

Numerical 8-vs-10 is a stylistic difference (GEMINI.md uses prose form for the Key docs block; CLAUDE.md / AGENTS.md use list form which produces an extra "regenerated mirrors" recap line). Every CONTENT-level reference has trinity parity — confirmed by spot-grepping line-by-line in §2.3 table above. Validate-pack.py's Check 18 (trinity H2 parity) PASSED, which is the authoritative parity check.

---

## §5 Trinity compliance

| Lockstep set | Verification |
|---|---|
| Pack-root trinity (CLAUDE.md / AGENTS.md / GEMINI.md) | Lockstep edits at 4 plan-scoped sites; Check 18 H2 parity PASSED. |
| pack-architect × 3 CLI variants (.claude/.codex/.gemini) | 3 sites in each variant lockstep updated. |
| pack-planner × 3 CLI variants | 1 site in each variant lockstep updated. |
| pack-coder × 3 CLI variants | 3 sites in each variant lockstep updated. |
| pack-startup skill × 3 CLI variants (.claude SKILL.md / .codex SKILL.md / .gemini commands toml) | Step 2 instructions + GitHub MCP note lockstep updated. |
| commit-discipline skill × 3 CLI variants | PM-only file list + worked-example lockstep updated. |
| implementation-report skill × 3 CLI variants | 2 sites lockstep updated. |
| pack-reviewer × 3 / pack-docs-researcher × 3 | NO MATCHES (verified by grep) — no edits needed. |

Trinity rule (per pack repo memory) honored — no asymmetric edits.

---

## §6 Manifest regen output

`bash test-fixtures/build.sh --all --clean` completed successfully. `git diff test-fixtures/manifest.txt` shows 6 line changes (3 rows replaced, all v11-*). v11-realistic-ot, v11-flat-file, v11-tracker-on SHAs drifted as expected (v11-surface edits to project-template/ and scripts/ propagate to fixtures that include pack files); v10-* rows are tag-pinned and unchanged; existing-project-mid-dev has no pack-surface dependency and is unchanged. The new manifest is ready for Pack Chat to stage in the same commit per RC9.

---

## §7 Plan deviations

Zero deviations from the plan §2.2 scope. Notable judgment calls (executed within the plan's explicit latitude):

1. **detect.sh fallback retention** (per planner default §2.2.3 + B-fix §10.3 explicit deferral): The legacy `$target/BACKLOG.md` root candidate is RETAINED as 3rd fallback in `detect_pack_surface`'s scan order. Verified necessary by inspecting `scripts/tests/pack-help-test.sh` fixture 1.3 (legacy v9 client-shape with BACKLOG.md at root + TD entries — needs the root fallback to resolve as `pack-surface: client`).

2. **pack-help.sh root-fallback in fragment-path resolution** (consistent with detect.sh pattern): Added `_pack_fragment_path` + `_pack_tracker_fragment_path` helpers that resolve `pack-ops/HELP-FRAGMENT-*.md` first, falling back to root for test fixtures that write fragments at root (e.g., `pack-help-test.sh` 2.5).

3. **Pack-side library surface-aware refactors (beyond planner's enumerated lines):** `tracker-doctor.sh`, `tracker-migrate-forward.sh`, `tracker-header-snapshot.sh`, `tracker-init.sh`, and the `tracker-migrate-reverse.sh` backup/restore loops were refactored to be surface-aware (not just `pack-ops/`-hardcoded). This is required because these libs handle BOTH pack-side and client-side flows; hardcoding `pack-ops/` would break client-side usage of the same libs. The refactor preserves client-side behavior unchanged.

4. **Test fixture updates (9 test scripts)** were necessary to keep the test suites passing after the pack-side surface marker changed. Without these, fixtures using `prefix = "BD"` no longer auto-detect as pack (the prior `PACK-CHAT.md` file marker is gone) and tests silently fall back to client emit paths. The fixture updates mirror the canonical post-BD-175 layout (`pack-ops/` directory marker + BACKLOG at `pack-ops/BACKLOG.md`).

5. **`pack-ops/PACK-AGENTS.md` lines 143-148:** No edit applied. The bare names `BACKLOG.md` / `CHANGELOG.md` / `PACK-CHAT.md` / `PACK-AGENTS.md` in the PM-only files list are sibling-relative within the now-relocated `pack-ops/` directory per planner choice (a). `README.md` / `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` in the same list resolve to pack root by prose context (consistent with the pre-relocation behavior, since this list has always mixed pack-ops-relative and root-relative bare names).

6. **Pack memory bullets in trinity (CLAUDE.md L74/L139/L258/L378/L393 + parallels):** Left bare per the planner's explicit line-scoped spec at §2.2.2 (only 4 sites enumerated for trinity edits). These are conceptual file-name references in pack-memory rule prose, not load-bearing path references for any consumer. A follow-up cleanup BD can address them if Pack Chat decides.

All 6 judgment calls are documented above for reviewer audit.

---

## §8 New OQs surfaced

None — no design questions opened during execution. The planner's spec was implementable as written; the judgment calls in §7 are all within the explicit latitude the planner left to the coder (B-fix §10.3 explicit "per-file review" instruction).

---

## §9 Definition-of-Done checklist

| Item | Result |
|---|---|
| Step 1 — 7 git-mv to pack-ops/ | PASS |
| Step 2 — pack-side scripts updated | PASS |
| Step 3 — pack-root trinity lockstep edits (4 sites × 3 CLIs) | PASS |
| Step 4 — pack-* agents (5 × 3 CLI = 15 files) | PASS (pack-architect / pack-planner / pack-coder × 3; pack-reviewer + pack-docs-researcher no-op) |
| Step 5 — pack-side skills (pack-startup / commit-discipline / implementation-report × 3 CLI) | PASS |
| Step 6 — post-move sibling self-references | PASS (bare names retained per planner choice a) |
| Step 7 — README repo-layout updated | PASS |
| Step 8 — manifest regenerated, diff non-empty | PASS |
| validate-pack.py PASS | PASS |
| pack-help --root . (pack-side) resolves | PASS |
| pack-help --root project-template (client-side) resolves unchanged | PASS |
| detect_pack_surface returns pack | PASS |
| tracker_config_auto_surface returns pack | PASS |
| pe_canonical_mirror_for_stream returns pack-ops/BACKLOG.md | PASS |
| All affected test suites PASS | PASS (27+ suites verified green) |
| Trinity Check 18 H2 parity PASS | PASS (per validate-pack.py) |
| No new POQs | PASS (zero opened) |
| Plan deviations documented | PASS (6 judgment calls in §7) |
| Markdown-only output, chunked Writes | PASS (this report Written + 2 Edit-appended) |
| No state-changing git verbs run | PASS (only `git mv`, `git status`, `git diff`, `git rev-parse`) |

---

## §10 Pack Chat handoff

This commit's working-tree state is complete, validated green, and ready for Pack Chat to stage and commit per plan §1 row 2. The commit subject:

> `feat: v11 — BD-175 directory reorg M1-M5 + M9-M10 (root → pack-ops/)`

Files for Pack Chat to stage (in addition to the 7 renames already detected by git):
- 52 modified pack-source/test/manifest files
- This IMPL-REPORT at `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-2.md`

Pre-existing artifacts Pack Chat should triage separately (NOT part of Commit 2 scope):
- `?? maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-1-FIX.md` (untracked from a prior session)
- `M pack-ops/BOUNDARY-DEFINITION.md` (modified by the prior Commit-1-fix work)

End of report.
