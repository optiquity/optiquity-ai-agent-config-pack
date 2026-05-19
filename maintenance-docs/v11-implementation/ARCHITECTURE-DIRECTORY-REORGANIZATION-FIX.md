# ARCHITECTURE — Directory reorganization FIX (BD-175 Phase 2 Architect B fix-pass)

**Owner:** Architect B-fix (fresh architect; read-only on source; output is this single doc)
**BD:** BD-175 (CODE RED — pack/project boundary remediation)
**Phase:** 2 — multi-architect design (B-fix = narrow corrective pass on B's §2-§3 root exemption list)
**Date:** 2026-05-18
**Branch:** v11-dev
**HEAD at design time:** `8014186` (per gitStatus on session open)

**Amends:** `maintenance-docs/v11-implementation/ARCHITECTURE-DIRECTORY-REORGANIZATION.md` (Architect B's design) — specifically §2 row 4 + row 5 (BACKLOG.md / CHANGELOG.md verdicts), §2.1 (C2-at-root exemption list), §2.2 (final root inventory), §3.3 (machine-readable exemption list), §6.1 (MOVES list), §6.4 (commit sequencing), §8 (final-state directory tree).

**Authority:** AUDIT-USER-CURATION.md §1 Override 5 (BACKLOG.md + CHANGELOG.md must MOVE; only `tracker.toml.pack-example` is exempted) + §5 (boundary articulation: "config pack operational docs used by the pack to do its work").

---

## §1 — Scope and non-scope

This doc covers ONE narrow correction to Architect B's design:

- **In scope:** Placement of `BACKLOG.md` and `CHANGELOG.md` (currently at pack root, classified by B as C2 STAYS-exempt; user direction is they MUST MOVE). Path-reference impact for both files. Coder guidance.
- **Out of scope:** B's G7 boundary definition (§1), B's directory architecture (§3.1 `pack-ops/`), B's other MOVES (M1-M8), B's QUICKSTART split (S1), B's OPTIONAL-FEATURES conditional split (S2), B's BOUNDARY-DEFINITION.md / .boundary-exempt-root.txt CREATES (N1, N2), B's SC8 cross-reference network (§5), B's discoverability invariant (§5.4), Architect A's re-litigation framework, Architect C's prevention mechanisms. Those stand as B designed them.

This doc DOES NOT relitigate B's boundary classification work. B correctly classified BACKLOG.md and CHANGELOG.md as **C2 (PACK × OPERATIONS)** per §1.1 of B's design. The only error was in the placement verdict — B carved them out as "STAYS (exempt)" using a "pinned by external constraints" rationale that the user explicitly rejected. The classification is unchanged; the placement flips from STAYS to MOVES.

---

## §2 — The defect in B's §2-§3

### §2.1 What B designed

B's §2 row 4 + row 5 (lines 162–163 of `ARCHITECTURE-DIRECTORY-REORGANIZATION.md`):

| # | Filename / dir | Category | Verdict | Reason |
|---|---|---|---|---|
| 4 | `BACKLOG.md` | C2 | STAYS (exempt) | PACK × OPERATIONS, but CI Check 32 (`mirror-in-sync`) + per-entry-tree contract pin location at repo root. **EXEMPT** from the §1.2 step 4 "no new C2 at root" rule. See §2.1 below. |
| 5 | `CHANGELOG.md` | C2 | STAYS (exempt) | Same exemption pattern as BACKLOG.md. |

B's §2.1 ("The C2-at-root exemption list (closed set)") and §3.3 (machine-readable form) listed both files alongside `tracker.toml.pack-example` as the "closed set" of C2 files allowed at root.

### §2.2 Why the user rejected it

Per AUDIT-USER-CURATION.md Override 5, **only `tracker.toml.pack-example` was authorized as exempt** (per Override 1). `BACKLOG.md` and `CHANGELOG.md` were NEVER authorized. User-curation §5 (boundary articulation):

> They are not (a) configs used by tools governing the config pack to do its work or (b) config pack operational docs used by the pack to do its work.

BACKLOG.md and CHANGELOG.md fall squarely under (b) — pack operational docs used by the pack to do its work. They are not (a) tool-governing configs (no CLI/platform mandates their location); they are pack ops files of the same class as `PACK-CHAT.md` and `PACK-AGENTS.md`, which B's design correctly MOVES to `pack-ops/`. The symmetric treatment is to MOVE them too.

### §2.3 Why B's "external constraints" rationale fails

B claimed two constraints "pinned" these files at root: (1) CI Check 32 (`mirror-in-sync`) and (2) the per-entry-tree write-authority contract in `/backlog/_rules.md`. Both claims investigated and rejected below; details in §6.

**(1) CI Check 32 is internal pack code, not an external constraint.**
`scripts/validate-pack.py:189-193` defines a `STREAMS` constant that hardcodes the pack-side mirror paths as bare filenames (`"BACKLOG.md"`, `"CHANGELOG.md"`) relative to repo root. The pack-side mirrors are resolved as `REPO_ROOT / mirror_rel` at `scripts/validate-pack.py:2893`. This is a pack-internal hardcode that the pack itself owns and updates — same shape as B's M1-M5 MOVES, where `scripts/pack-help.sh` hardcodes `$root/HELP-FRAGMENT-PACK.md` and B's design (§6.4 step 3) updates the script as part of the move commit.

By the same logic that lets B move `HELP-FRAGMENT-PACK.md`, B can move `BACKLOG.md`. The script change is parametric: replace the hardcoded `"BACKLOG.md"` literal with the new path. There is no external tool reading these files at a fixed location.

**(2) `/backlog/_rules.md` write-authority contract does not pin the mirror location.**
The per-entry source-of-truth contract (CLAUDE.md §"Repo conventions") pins the per-entry TREE (`/backlog/`, `/changelog/`) as source of truth; the mirror is REGENERATED from that tree by `per_entry_regenerate_mirror`. The mirror's filename is configurable via the `STREAMS` constant (validate-pack.py) and the `pe_canonical_mirror_for_stream` helper (`scripts/lib/per-entry/_lib.sh:71,79`). Both are pack-internal lookups; the contract does not constrain the mirror's *location* — only its *existence* and *byte-identity to the regenerator's output*. Moving the mirror to a new path requires updating the lookups (mechanical), not invalidating the contract.

Compare with `tracker.toml.pack-example` (Override 1, genuinely STAYS): the user's direction was sufficient authority without needing to verify a tool-constraint. The asymmetry is explicit — the user gave one exemption and rejected B's attempt to broaden it.

### §2.4 The corrected verdict

| # | Filename | Old verdict (B) | New verdict (B-fix) | Reason |
|---|---|---|---|---|
| 4 | `BACKLOG.md` | C2 STAYS (exempt) | **C2 MOVES** → `pack-ops/BACKLOG.md` | Same logic as B's M4 (PACK-AGENTS.md) and M5 (PACK-CHAT.md). Pack ops doc; no CLI/platform constraint at root; internal hardcodes update parametrically. |
| 5 | `CHANGELOG.md` | C2 STAYS (exempt) | **C2 MOVES** → `pack-ops/CHANGELOG.md` | Same. |

---

## §3 — Placement decision

**Destination for both files:** `pack-ops/` (the new top-level pack-only directory B designed in §3.1).

### §3.1 Why `pack-ops/` and not somewhere else

Three candidate destinations considered:

**(a) `pack-ops/` (CHOSEN).** Co-locates with the other relocated PACK × OPERATIONS files (PACK-CHAT.md, PACK-AGENTS.md, HELP-FRAGMENT-PACK.md, HELP-FRAGMENT-TRACKER.md, OPTIONAL-FEATURES.md, MERGE-STRATEGY.md, DRY-RUN-MIGRATION.md). Consistent with B's symmetric treatment of pack-ops files. Pack Chat's startup-read list (PACK-CHAT.md, PACK-AGENTS.md, BACKLOG.md, CHANGELOG.md per `.claude/skills/pack-startup/SKILL.md:17-34`) becomes a single-directory read after the move. The pack-startup helper finds all four canonical pack-ops files in one place.

**(b) `maintenance-docs/`.** REJECTED. B's §3.1 already justified why MOVES files do NOT belong in `maintenance-docs/`: that dir is for design/research/implementation RECORDS (historical artifacts), not LIVE OPERATING DOCS read every session. BACKLOG.md and CHANGELOG.md are read every session by Pack Chat (per pack-startup step 2) — putting them in `maintenance-docs/` would conflate live ops with historical records AND trigger Pattern B archive-sweep risk at version close. Reject.

**(c) New dedicated dir (e.g., `pack-tracking/`).** REJECTED. Adds a second top-level dir for ONE category-narrow purpose (mirror files). Violates the elegance principle (fewer dirs preferred over single-purpose proliferation). The `pack-ops/` dir B designed is already the home for ALL relocated C2 files; adding a second peer dir for two more would split a coherent category. Reject.

### §3.2 Why this does NOT break the per-entry source-of-truth contract

Per CLAUDE.md §"Repo conventions" "Per-entry trees vs mirrors": the per-entry tree at `/backlog/` and `/changelog/` is the source of truth in flat-file mode; the monolithic mirror is regenerated from the tree. The contract is about (a) source-of-truth direction (tree → mirror, never reverse) and (b) byte-identity invariant (mirror == regenerator output).

Moving the mirror's location from `/BACKLOG.md` to `/pack-ops/BACKLOG.md` changes neither. The per-entry trees (`/backlog/`, `/changelog/`) STAY at their current root location (they are not in scope of this fix; the user's direction was about the mirror files, not the per-entry trees). The regenerator's output destination updates parametrically via the `STREAMS` constant in validate-pack.py and the `pe_canonical_mirror_for_stream` helper.

**Important asymmetry to preserve:** the per-entry TREE source-of-truth dirs (`/backlog/`, `/changelog/`) remain at repo root. These are different artifacts from the mirror files:
- Trees are SOURCE OF TRUTH (per-entry editable files; CLAUDE.md "Repo conventions").
- Mirrors are REGENERATED OUTPUT (read-stable; never source of truth).

The user's direction in Override 5 names the mirror files (BACKLOG.md and CHANGELOG.md) explicitly. It does NOT direct moving the per-entry trees. This fix-pass therefore moves ONLY the two mirror files, not the trees. (A future BD may consider tree relocation as a separate scoping question; B-fix's prompt does not authorize it.)

### §3.3 Why this does NOT break the per-entry tree's existence semantics

Both per-entry trees are FORWARD-POINTING at v11.0 ship time per PACK-AGENTS.md:178-187 "Forward-pointing note (Batch 19 → Batch 23): the pack-self per-entry trees `/backlog/` and `/changelog/` enumerated above are created at Batch 23 (BD-102 dog-food)... a pack agent attempting to read `/backlog/_rules.md` between Batch 19 and Batch 23 will hit file-not-found."

Implication: at the time of this fix-pass implementation (BD-175 Phase 5, before Batch 23), the per-entry trees do not yet exist on disk. Validate-pack Check 32 SKIPs cleanly when the stream dir is absent (validate-pack.py:2895-2901). After the moves, the mirror files at `/pack-ops/BACKLOG.md` and `/pack-ops/CHANGELOG.md` ARE the live read-target for Pack Chat (and the pack-startup skill, etc.) until Batch 23 creates the trees and Check 32 begins validating mirror-in-sync.

There is no Batch-23-vs-BD-175 ordering hazard: BD-175 must complete BEFORE Batch 23 anyway (per ORCHESTRATION-PLAN-BD-175.md), and BD-102's dog-food per-entry decompose will use whatever mirror path the STREAMS constant declares at the time it runs. The mirror-path change in BD-175 is invisible to BD-102 (BD-102 reads STREAMS just like Check 32 does).

---

## §4 — Updated C2-at-root exemption list

After this fix-pass, B's §2.1 "C2-at-root exemption list (closed set)" shrinks from three entries to one:

| # | Filename | Reason exempt |
|---|---|---|
| 1 | `tracker.toml.pack-example` | Per AUDIT-USER-CURATION.md §1 Override 1 — user direction; sufficient authority. |

**Removed from exemption list (now MOVES):**
- `BACKLOG.md` — moves to `pack-ops/BACKLOG.md`.
- `CHANGELOG.md` — moves to `pack-ops/CHANGELOG.md`.

The machine-readable form B designed at `pack-ops/.boundary-exempt-root.txt` (B's §3.3) shrinks correspondingly to one line of allow-listed filename plus the original comment header. Architect C's CI gate (the "no new C2 at root" check) consumes this shorter list as its allow-list.

---

## §5 — Updated MOVES list (extending B's §6.1)

B's §6.1 enumerated 8 MOVES (M1-M8). This fix-pass adds two more, M9 and M10:

| # | Source path | Destination path | Reference-count estimate |
|---|---|---|---|
| M1 | `HELP-FRAGMENT-PACK.md` | `pack-ops/HELP-FRAGMENT-PACK.md` | ~22 refs (B's §6.1) |
| M2 | `HELP-FRAGMENT-TRACKER.md` | `pack-ops/HELP-FRAGMENT-TRACKER.md` | ~25 refs (B's §6.1) |
| M3 | `OPTIONAL-FEATURES.md` | `pack-ops/OPTIONAL-FEATURES.md` | ~20+ refs (B's §6.1) |
| M4 | `PACK-AGENTS.md` | `pack-ops/PACK-AGENTS.md` | ~25+ refs (B's §6.1) |
| M5 | `PACK-CHAT.md` | `pack-ops/PACK-CHAT.md` | ~30+ refs (B's §6.1) |
| M6 | `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` | `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` (per Override 6; see §16 below) | ~10 refs (B's §6.1) |
| M7 | `supporting-docs/DRY-RUN-MIGRATION.md` | `pack-ops/DRY-RUN-MIGRATION.md` | ~5-10 refs (B's §6.1) |
| M8 | `supporting-docs/MERGE-STRATEGY.md` | `pack-ops/MERGE-STRATEGY.md` | ~15-20 refs (B's §6.1) |
| **M9** | `BACKLOG.md` | `pack-ops/BACKLOG.md` | **~140 refs (see §6 below; mostly pack-side ops/agent/skill files + scripts + maintenance archive)** |
| **M10** | `CHANGELOG.md` | `pack-ops/CHANGELOG.md` | **~80 refs (smaller surface; mostly pack-startup + scripts/lib/recommendation.sh + maintenance archive)** |

Aggregate path-reference update count grows from B's ~150-200 to roughly ~370-420 across the repo after M9 + M10. Most of the M9/M10 incremental count is in archived `maintenance-docs/archive/v11/` content where the references are HISTORICAL (they describe past commits / prior reviewer findings); see §6.4 for the live-vs-archive triage.

---

## §6 — Path-reference impact for BACKLOG.md and CHANGELOG.md

References fall into FIVE categories. The first three are LIVE (must update); the last two are FROZEN (no update needed).

### §6.1 LIVE — Pack-side internal pack-ops surfaces (must update)

These reference the mirror files at the pack root and must update to the new `pack-ops/` paths.

**Pack-root context files (trinity):**
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md:30-31` — "Key files to read before working on the pack" lists `BACKLOG.md` and `CHANGELOG.md` with bare-name references (and points to `/backlog/`, `/changelog/` per-entry trees, which STAY at root).
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/AGENTS.md` (same line range; trinity rule).
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/GEMINI.md` (same line range; trinity rule).
- Pack-root trinity § "What agents may modify" (line 83 in CLAUDE.md): `CHANGELOG.md only at version boundaries with explicit instruction` — bare name; update.
- Pack-root trinity § "What agents must never modify without explicit instruction" (line 99 in CLAUDE.md): `BACKLOG.md (PM chat only, after user approval)` — bare name; update.
- Pack-root trinity § "Pack memory" §"Repo conventions" bullet "BACKLOG.md has no Resolved section" (line 389): bare name; update.

**Pack-side operating docs:**
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/PACK-AGENTS.md:143-144` (currently at root, B's M4 moves it to `pack-ops/`): names BACKLOG.md and CHANGELOG.md in the "PM-only files" list. After M4 lands, this file lives at `pack-ops/PACK-AGENTS.md`; after M9/M10 it references siblings within `pack-ops/`.

**Pack-side agent definitions (CLI trinity — `.claude/agents/`, `.codex/agents/`, `.gemini/agents/`):**
- `pack-architect.md:27` (+ `.toml:18` Codex + `.md:29` Gemini): "BACKLOG.md (open BD items and their constraints)"
- `pack-planner.md:32` (+ `.toml:18` + `.md:25`): "BACKLOG.md (BD items in scope)"
- `pack-coder.md:34,38` (+ `.toml:21,23` + `.md:36,40`): "do not modify BACKLOG.md, CHANGELOG.md, README.md version table, PACK-CHAT.md..." and "BACKLOG.md Status: flips happen post-review"

**Pack-side skills (trinity — `.claude/skills/`, `.codex/skills/`, `.gemini/skills/`):**
- `pack-startup/SKILL.md:19,21,32-33` (+ Codex parallel + Gemini parallel at `.gemini/commands/pack-startup.toml:16,18,29-30`): step-2 instructions tell Pack Chat to "Read BACKLOG.md in full" and "Read only the most recent dated entry from CHANGELOG.md", plus the per-entry-tree forward-pointing note that names the mirrors.
- `commit-discipline/SKILL.md` (Claude + Codex + Gemini parallel): grep shows references — update.
- `implementation-report/SKILL.md` (Claude + Codex + Gemini parallel): same — update.

**Pack scripts (`scripts/`):**
- `scripts/validate-pack.py:122` (Check 32 docstring): `regenerated mirror (BACKLOG.md, CHANGELOG.md) is byte-` — comment text; update path or keep as bare names with a parenthetical "(at pack-ops/)".
- `scripts/validate-pack.py:191-192` (STREAMS constant): mirror paths `"BACKLOG.md"` and `"CHANGELOG.md"` — update to `"pack-ops/BACKLOG.md"` and `"pack-ops/CHANGELOG.md"`.
- `scripts/validate-pack.py:319` (Check 3): `backlog = REPO_ROOT / "BACKLOG.md"` — update to `REPO_ROOT / "pack-ops" / "BACKLOG.md"`.
- `scripts/validate-pack.py:321,332,336` (Check 3 error/ok messages): update path strings.
- `scripts/pack-help.sh:33` (usage docstring): `BACKLOG.md with ^**BD-` — update parenthetically (the file isn't actually opened by pack-help; this is doc text).
- `scripts/lib/per-entry/_lib.sh:71` (`pack-backlog` mirror attr `printf 'BACKLOG.md'`): update to `printf 'pack-ops/BACKLOG.md'`.
- `scripts/lib/per-entry/_lib.sh:79` (`pack-changelog` mirror attr `printf 'CHANGELOG.md'`): update to `printf 'pack-ops/CHANGELOG.md'`.
- `scripts/lib/recommendation.sh:131,151,152,393,462`: hardcoded `$repo_root/BACKLOG.md`. Update to `$repo_root/pack-ops/BACKLOG.md` for pack surface; the fallback `$repo_root/docs/project/BACKLOG.md` (line 152) STAYS unchanged (project-side mirror unaffected).
- `scripts/lib/recommendation.sh:393` (prompt label): `backlog_kb)             echo "BACKLOG.md size (KB)" ;;` — display string; update parenthetically.
- `scripts/lib/tracker-doctor.sh:114,116,118,123,129,131,135,138`: hardcoded `$repo_root/BACKLOG.md` for mirror-freshness check. Update to `$repo_root/pack-ops/BACKLOG.md` when surface == pack. The doctor helper handles both pack and client surfaces; the pack-surface path needs the new prefix, the client-surface path (`docs/project/BACKLOG.md`) stays.
- `scripts/lib/tracker-agent-read.sh:264,267`: `mirror_path="$repo_root/BACKLOG.md"` for BD-* and unknown-prefix IDs. Update to `$repo_root/pack-ops/BACKLOG.md`. The TD-* branch (line 265) stays.
- `scripts/lib/tracker-migrate-reverse.sh:1050,1053,1068,1078,1095,1119,1147`: hardcoded `$repo_root/BACKLOG.md` and `$repo_root/CHANGELOG.md` as reverse-emit destinations. Update both. **CRITICAL:** the reverse-migrate writes these files from scratch; getting the destination right is load-bearing for the reverse-migration round-trip.
- `scripts/dry-run-migration.sh:64` (commented BACKLOG ref): cosmetic doc-comment.
- `scripts/migrate-v10-to-v11.sh:151,368,696-697`: comments naming `BACKLOG.md / IMPLEMENTATION-PLAN.md / CHANGELOG.md` as docs/project/ files (project-side; UNAFFECTED — these are project paths under `docs/project/`, not pack-root paths). VERIFY no false-positive sed.
- `scripts/init-project.sh:991,993,1013`: project-side path strings (`docs/project/BACKLOG.md`, `docs/project/CHANGELOG.md`). UNAFFECTED.
- `scripts/pack-td.sh:91,140,211`: commented `BACKLOG.md` mentions; document text — update parenthetically.
- `scripts/tracker-migrate.sh:51,65`: commented references to flat-file `BACKLOG.md`/`IMPLEMENTATION-PLAN.md` content — update or keep as a generic reference (the wording is mode-neutral; surface as "pack-side mirror file" in either case).
- `scripts/test-persona-contracts.sh:25`: comment reference; cosmetic.
- `scripts/test-migrator-core.sh:358,368`: test assertions about migrator behavior referencing `BACKLOG.md` — VERIFY whether the test is asserting pack-side path (update) or project-side path (no change). Reviewer should resolve case-by-case.

**Pack-side test infrastructure (`scripts/tests/`):**
- `scripts/tests/test-per-entry.sh:220,221,222,224,292,304,307,328,335,339,340,355,370,372,373,375,376,378,379,394,398,443,444,464,468,470,471,475,477,478,490,491,502,539,562,564`: extensive pack-backlog / pack-changelog fixture testing. The assertions on lines 220 and 221 (`assert_eq "1.1 pack-backlog mirror filename" "BACKLOG.md" ...`) test the OUTPUT of `pe_canonical_mirror_for_stream pack-backlog` — after the `_lib.sh` constant change above, this expected value updates to `"pack-ops/BACKLOG.md"`. The remaining 33+ lines use TEMP-DIR fixtures (`$PB_ROOT/BACKLOG.md`) — these are isolated fixture trees inside `mktemp`, not the pack repo's actual mirror, so they STAY UNCHANGED. Distinguishing the two requires per-line review by Phase 5 coder; the assertion-on-canonical-output lines update, fixture-tree paths stay.
- `scripts/tests/recommendation-test.sh:36,62,79,85,288`: more temp-dir fixtures + one prompt-text assertion. Per-line review; same pattern.
- `scripts/tests/pack-help-test.sh:31,33,44,47,55,57,61,67,78,80,114,132,142`: temp-dir fixtures simulating pack vs. client repos for the `detect_pack_surface` test. STAY UNCHANGED — these test the helper's behavior against synthetic trees (where BACKLOG.md location is intentional fixture state), not the actual pack repo.
- `scripts/tests/test-migrate-v10-to-v11-gates.sh:516,518`: temp-dir fixture; STAYS.
- `scripts/tests/test-migrate-v10-to-v11-decompose.sh:20,116,120,190`: project-side `docs/project/BACKLOG.md` and `docs/project/CHANGELOG.md` — UNAFFECTED.

### §6.2 LIVE — Pack auto-detection helpers (must update; CRITICAL)

**`scripts/lib/detect.sh:23-51` — `detect_pack_surface`**

```bash
for backlog in "$target/BACKLOG.md" "$target/docs/project/BACKLOG.md"; do
    [[ -f "$backlog" ]] || continue
    if grep -qE '^\*\*BD-[0-9]+ ' "$backlog" 2>/dev/null; then
        bd_seen=1
    fi
    ...
done
```

This is the auto-detection signal that `pack-help.sh` uses to distinguish pack-surface from client-surface. After the move:
- Pack-surface BACKLOG.md lives at `$target/pack-ops/BACKLOG.md` (BD entries).
- Client-surface BACKLOG.md lives at `$target/docs/project/BACKLOG.md` (TD entries) — UNCHANGED.

The loop must update to scan `$target/pack-ops/BACKLOG.md` as the first candidate, retaining `$target/docs/project/BACKLOG.md` as the second. There's a transitional consideration: legacy v11 fixtures (or any pre-fix snapshot) may still have BACKLOG.md at root; an optional fallback scan of `$target/BACKLOG.md` could preserve back-compat detection for older trees. Phase 5 coder + reviewer decide whether back-compat is needed (probably yes given test-fixtures cover legacy shapes).

**`scripts/lib/tracker-config.sh:298` — `tracker_config_auto_surface`**

B's §3.2 already updates this to `[[ -d "$repo_root/pack-ops" ]]` as part of M5 (PACK-CHAT.md move). No additional change needed for M9/M10 — the `pack-ops/` dir existence is already the auto-detect signal after M5; M9 and M10 just add BACKLOG.md and CHANGELOG.md into that already-detected dir.

**`scripts/lib/detect.sh:797-829` — `detect_target_pack_version` Signal 2-3:**

These signals already use trinity-addenda + v11-only surface markers (e.g., `.github/ISSUE_TEMPLATE/work-item.yml`); they do NOT read BACKLOG.md or CHANGELOG.md. UNAFFECTED.

### §6.3 LIVE — Pack-side cross-reference docs (must update)

- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/README.md` — version history table is dense with references to BD-NNN entries (entries live in BACKLOG.md). The "Repository Layout" section (lines 261-262 + 266) names `BACKLOG.md` and `CHANGELOG.md` at root. Both lines update to `pack-ops/BACKLOG.md` and `pack-ops/CHANGELOG.md`. The `## Repository Layout` ascii-tree block updates accordingly.
- `pack-ops/PACK-CHAT.md` (after B's M5 lands): if PACK-CHAT.md references BACKLOG.md / CHANGELOG.md, the references update to bare names (sibling files within `pack-ops/`).

### §6.4 FROZEN — Maintenance archive (no update needed)

All references under `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/archive/**` are HISTORICAL records of prior commits, reviews, and design decisions. They describe the past state where BACKLOG.md was at root; that state was correct at the time. Per pack memory § "Skill and agent maintenance is mechanical by default" + the Pattern B archive convention, archived docs are immutable — they describe history. Updating them would falsify the historical record.

Archived references (no update):
- `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-*.md` (many)
- `maintenance-docs/archive/v11/PACK-REVIEW-*.md` (many)
- `maintenance-docs/archive/v11/ARCHITECTURE-*.md` (many)
- `maintenance-docs/archive/V*-*.md` (v9/v10 archives — same logic)
- `maintenance-docs/archive/v10-working/*.md`

### §6.5 LIVE — Maintenance docs in-flight (case-by-case)

Files under `maintenance-docs/v11-implementation/` and `maintenance-docs/v11-research/` that have NOT yet swept to `archive/v11/` may carry references to BACKLOG.md at root. Architect A's re-litigation work will touch many of these as part of the contamination triage; Phase 5 coder coordinates with Architect A's framework to avoid double-edits.

Forward-pointing notes (specifically PACK-AGENTS.md:178-187 forward-pointing note about Batch 23 BD-102 dog-food creating the per-entry trees) reference the trees `/backlog/` and `/changelog/` — those STAY at root; this fix-pass moves only the mirror files. No update to that note.

### §6.6 FROZEN — Project-side files (UNAFFECTED)

`project-template/**` references to `BACKLOG.md` or `CHANGELOG.md` are talking about PROJECT-side files (`docs/project/BACKLOG.md`, etc.), not pack-side root files. After install via `init-project.sh`, project-side BACKLOG.md is created from the per-entry templates B's §8 tree shows at `project-template/docs/project/backlog/_rules.md` etc. UNAFFECTED by M9/M10.

Specifically:
- `project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md` (trinity): all references to BACKLOG.md / CHANGELOG.md are about the PROJECT-side mirror at `docs/project/`. UNAFFECTED.
- `project-template/docs/pack/PM-CHAT.md`, `project-template/docs/pack/PLATFORM-SKILLS.md`, etc.: same — project-side context. UNAFFECTED.
- `project-template/.claude/agents/coder.md`, `.codex/agents/coder.toml`, `.gemini/agents/coder.md` (project-side agents): "do not modify BACKLOG.md, CHANGELOG.md..." — refers to PROJECT-side files; UNAFFECTED.
- `project-template/docs/project/backlog/_rules.md`, `project-template/docs/project/changelog/_rules.md`, `project-template/docs/project/changelog/_format.md`: project-side per-entry contracts; UNAFFECTED.
- `project-template/.claude/skills/pm-startup/SKILL.md` (+ Codex + Gemini): project-side startup; UNAFFECTED.
- `project-template/skills/audit-methodology/SKILL.md`: project-side skill; UNAFFECTED.

**The pack/project boundary B established (§1.1 C4-C6) means BACKLOG.md references in `project-template/` are talking about the PROJECT's BACKLOG.md (at `docs/project/`), not the pack's. The audience-context check (B's §1.1 Challenge 1) confirms this: when the CWD is the CLIENT repo, "BACKLOG.md" means `docs/project/BACKLOG.md` (the client's project tracking).**

### §6.7 Special-case: BACKLOG.md self-reference

BACKLOG.md has internal cross-references — entries mention each other ("Blockers: BD-119", "Unblocks: BD-120", etc.). After the move, the file path of BACKLOG.md changes but its INTERNAL content (BD entries) does not. Internal BD-NNN cross-references are stable. No internal sed needed.

**Exception:** if any BD entry in BACKLOG.md mentions "see PACK-CHAT.md" or "see PACK-AGENTS.md" as a relative path (these may exist), the relative paths break after the moves. Phase 5 coder runs a grep on BACKLOG.md content for relative-path mentions of other relocated files and updates parenthetically. CHANGELOG.md has similar exposure for cross-version references; check both.

---

## §7 — Ripple effect on B's §6 commit sequencing

B's §6.4 ordered four commits (M1-M5 single commit, M6-M8 second, S1 third, S2 conditional fourth). This fix-pass requires re-sequencing:

### §7.1 Option A — Fold M9/M10 into B's existing M1-M5 commit (RECOMMENDED)

The cleanest sequencing folds M9 and M10 into B's existing root → `pack-ops/` commit (B's §6.4 step 3). Rationale:

- Same shape: bare-root → `pack-ops/` mechanical `git mv`.
- Same auto-detection update: B's M5 already updates `tracker-config.sh:298` to `[[ -d "$repo_root/pack-ops" ]]`. After this single change, ALL pack-ops files (M1-M5 + M9/M10) live under the detected directory.
- Same `detect_pack_surface` update: a single edit to `scripts/lib/detect.sh:35` updates the scan path for ALL pack-side BACKLOG.md detection.
- Same validate-pack.py constant batch: B's §6.6 already updates lines 1654, 1655, 1656, 1659, 1669, 1735, 1736, 1929 for M1-M5; M9/M10 add lines 191-192, 319, plus Check 3 path strings.
- Same manifest regen requirement: one rebuild covers all the changes (no extra rebuild needed for M9/M10 on top of M1-M5).
- Same test-fixture regen: rebuild covers all paths.

The combined commit is larger but mechanically uniform. Splitting M9/M10 into a separate commit creates a window where the new `pack-ops/` dir contains some files but not others, which has no functional cost but no semantic benefit either.

**Recommended commit decomposition after this fix:**

1. **Commit A (CREATE):** `pack-ops/.boundary-exempt-root.txt` + `pack-ops/BOUNDARY-DEFINITION.md` (B's N1 + N2 unchanged). Empty `pack-ops/` placeholder before relocations.
2. **Commit B (MOVES — combined M1-M5 + M9-M10):** `git mv` all SEVEN root → `pack-ops/` files in one commit. Update:
   - `scripts/lib/tracker-config.sh:298` per B's §3.2.
   - `scripts/lib/detect.sh:35` per §6.2 above.
   - `scripts/validate-pack.py` STREAMS constant (lines 191-192), Check 3 path (line 319), Check 22 surfaces dict (lines 1650-1668), Check 24 byte-identity paths (lines 1929-1930), Check 35 etc. — combined sweep.
   - `scripts/lib/per-entry/_lib.sh` lines 71, 79 (mirror paths in stream attrs).
   - `scripts/pack-help.sh` (HELP-FRAGMENT path).
   - `scripts/lib/recommendation.sh` lines 131, 151, 152, 393, 462.
   - `scripts/lib/tracker-doctor.sh` lines 114-138.
   - `scripts/lib/tracker-agent-read.sh` lines 264, 267.
   - `scripts/lib/tracker-migrate-reverse.sh` lines 1050, 1053, 1068, 1078, 1095, 1119, 1147.
   - `scripts/tests/test-per-entry.sh` lines 220, 221 (canonical-output assertions; fixture-tree paths stay).
   - Pack-side trinity (CLAUDE.md, AGENTS.md, GEMINI.md) + pack-side agent files (`.claude/agents/pack-*`, `.codex/agents/pack-*`, `.gemini/agents/pack-*`) + pack-side skills (`.claude/skills/pack-startup/`, `.codex/skills/pack-startup/`, `.gemini/commands/pack-startup.toml`, etc.).
   - Pack-ops PACK-AGENTS.md (now at `pack-ops/PACK-AGENTS.md` after M4): self-references to BACKLOG.md / CHANGELOG.md update to bare-name relative references (within the same dir).
   - Pack-root README.md repo-layout block.
   - `test-fixtures/manifest.txt` regenerated per CLAUDE.md "Regenerate test-fixtures/manifest.txt on every v11-surface commit" rule (this commit touches `scripts/`).
3. **Commit C (M6-M8):** B's §6.4 step 4 unchanged (supporting-docs → maintenance-docs + pack-ops).
4. **Commit D (S1):** B's §6.4 step 5 unchanged (QUICKSTART split).
5. **Commit E (S2, conditional):** B's §6.4 step 6 unchanged (OPTIONAL-FEATURES split, conditional on Architect A).

This produces FIVE commits total instead of B's four — one extra is the Create commit A, which B's design also has. The number of MOVE commits stays at three (B, C, D); only the per-commit file count grows for commit B.

### §7.2 Option B — Separate M9/M10 commit between Commit B and Commit C (NOT RECOMMENDED)

Putting M9/M10 in their own commit between B's M1-M5 commit and M6-M8 commit creates two windows where:
- After M1-M5 commit lands: `pack-ops/` exists with PACK-CHAT.md, PACK-AGENTS.md, etc., but BACKLOG.md and CHANGELOG.md still at root. Pack-startup skill instructions become inconsistent (some files in pack-ops, some not).
- After M9/M10 commit lands: pack-ops/ is complete for these seven files. State matches Option A end-state, but with an intermediate split-commit history.

The extra commit boundary adds no audit value (both halves are clearly BD-175) and increases the chance of partial-state CI failures (validate-pack Check 3, Check 32, Check 24 all touch BACKLOG.md and CHANGELOG.md; splitting the constant updates across two commits doubles the risk that one commit lands with an inconsistent state).

**Reject Option B.** Phase 5 coder + planner finalize per Option A.

### §7.3 Commit-message guidance

The combined Commit B message references BD-175 explicitly per pack memory:

```
feat: v11 — BD-175 directory reorg M1-M5 + M9-M10 (root → pack-ops/)

Moves 7 PACK × OPERATIONS files from pack root to pack-ops/ per
ARCHITECTURE-DIRECTORY-REORGANIZATION.md + DIRECTORY-REORGANIZATION-FIX.md:
- PACK-CHAT.md, PACK-AGENTS.md (B's M4 + M5)
- HELP-FRAGMENT-PACK.md, HELP-FRAGMENT-TRACKER.md (B's M1 + M2)
- OPTIONAL-FEATURES.md (B's M3)
- BACKLOG.md, CHANGELOG.md (B-fix M9 + M10, per AUDIT-USER-CURATION
  Override 5 + boundary articulation §5)

Updates:
- scripts/lib/tracker-config.sh:298 (auto-detection signal)
- scripts/lib/detect.sh:35 (pack-surface scan path)
- scripts/validate-pack.py STREAMS + Check 3/22/24/32/35 paths
- scripts/lib/per-entry/_lib.sh:71,79 (mirror path constants)
- scripts/lib/recommendation.sh, tracker-doctor.sh, tracker-agent-read.sh,
  tracker-migrate-reverse.sh (hardcoded $repo_root/BACKLOG|CHANGELOG.md)
- scripts/pack-help.sh (fragment-path resolution)
- Pack-side trinity + pack-* agent + pack-startup skill files
- README.md Repository Layout block
- test-fixtures/manifest.txt regenerated (RC9)
```

---

## §8 — External-constraint claims investigated

Per the prompt instruction "Notes any external-constraint claims B made about these files that you investigated and either confirmed (don't move; surface) or rejected (no constraint; move)":

### §8.1 B's claim: "CI Check 32 (mirror-in-sync) pins location at repo root"

**Investigation:**
- `scripts/validate-pack.py:189-193` (STREAMS): hardcodes `("pack-backlog", "backlog", "BACKLOG.md", ...)` and parallel for changelog. The third column is a path STRING relative to `REPO_ROOT`.
- `scripts/validate-pack.py:2893`: `mirror_path = REPO_ROOT / mirror_rel` — joins repo root with the string.

**Verdict: REJECTED.** This is a pack-internal hardcode that the pack owns and updates. Same pattern as B's M1-M5 MOVES, where `scripts/pack-help.sh` hardcodes `$root/HELP-FRAGMENT-PACK.md` and is updated mechanically as part of the move. The STREAMS constant updates parametrically:

```python
("pack-backlog",      "backlog",            "pack-ops/BACKLOG.md",   r"^BD-\d+\.md$"),
("pack-changelog",    "changelog",          "pack-ops/CHANGELOG.md", r"^v\d+\.\d+(?:-[a-z0-9-]+)?\.md$"),
```

No external tool — no CLI, no GitHub feature, no build system — reads these files at a fixed location. CI Check 32 is the pack validating its own invariants; the pack's own code is mutable.

### §8.2 B's claim: "Per-entry-tree contract pins location at repo root"

**Investigation:**
- CLAUDE.md § "Repo conventions" "Per-entry trees vs mirrors": names the per-entry trees `/backlog/` and `/changelog/` as source of truth in flat-file mode; the MONOLITHIC mirror files are regenerated.
- The contract talks about (a) direction (tree → mirror) and (b) byte-identity (mirror == regenerator output). It does NOT pin the mirror's location.
- `scripts/lib/per-entry/_lib.sh:128-138` (`pe_canonical_mirror_for_stream`): looks up the mirror filename by stream key. The lookup is internal; the result is a relative path resolved against repo root.

**Verdict: REJECTED.** The per-entry contract is about source-of-truth direction, not location. The mirror's path is configurable via the same `pe_canonical_mirror_for_stream` helper that names project-side mirrors as `docs/project/BACKLOG.md` and `docs/project/CHANGELOG.md` (i.e., the helper already handles non-root mirror paths). Moving the pack-side mirrors to `pack-ops/` is the same shape as the existing project-side `docs/project/` mirror path — supported by the existing helper.

### §8.3 New constraint surfaced (not claimed by B): auto-detection signal in detect.sh

**Discovery:** `scripts/lib/detect.sh:31-51` `detect_pack_surface` scans `$target/BACKLOG.md` (and `$target/docs/project/BACKLOG.md` as fallback) to classify pack-vs-client surface for `pack-help.sh`.

**Verdict: NOT a STAYS-blocking constraint, but MUST update at the same commit as M9.** This is a pack-internal helper that needs a parametric update — same shape as M5's `tracker-config.sh:298` update B's §3.2 already designed. The fix: update the scan loop to look for `$target/pack-ops/BACKLOG.md` first, retaining `$target/docs/project/BACKLOG.md` as the client-surface fallback.

This is a CRITICAL update because the helper is called by `pack-help.sh` and could affect dozens of downstream consumers if left stale. Phase 5 coder must NOT leave this for a follow-up commit; it lands in the same commit as M9.

### §8.4 Conclusion

**No genuine external constraint pins BACKLOG.md or CHANGELOG.md at pack root.** Every constraint B cited is internal pack code that updates parametrically. User-direction (Override 5 + boundary articulation §5) wins on its own authority, and the implementation cost is mechanical updates to the same constants B already plans to update for M1-M5.

---

## §9 — Updated final-state directory tree

Replaces the `pack-ops/` and pack-root entries in B's §8 (lines 709-748) with the corrected layout. Sections not shown are unchanged from B's §8.

```
pack-repo-root/
├── .DS_Store                         (ignored)
├── .gitignore                        (C3)
├── .claude/, .codex/, .gemini/       (C3 — pack-side CLI configs)
├── .github/                          (C3 — pack-side CI + issue templates)
├── AGENTS.md, CLAUDE.md, GEMINI.md   (C3 — pack trinity)
├── README.md                         (C1 — GitHub landing page)
├── LICENSE.md                        (C1 — GitHub license discovery)
├── QUICKSTART.md                     (C1 — pack-side half post-split)
├── tracker.toml.pack-example         (C2 exempt — user Override 1)
│
├── pack-ops/                         (NEW — C2 top-level dir)
│   ├── .boundary-exempt-root.txt     (NEW — closed-set exemption list; 1 entry)
│   ├── BOUNDARY-DEFINITION.md        (NEW — G7 canonical reference)
│   ├── BACKLOG.md                    (moved from root — B-fix M9)
│   ├── CHANGELOG.md                  (moved from root — B-fix M10)
│   ├── HELP-FRAGMENT-PACK.md         (moved from root — B's M1)
│   ├── HELP-FRAGMENT-TRACKER.md      (moved from root — B's M2)
│   ├── OPTIONAL-FEATURES.md          (moved from root — B's M3)
│   ├── PACK-AGENTS.md                (moved from root — B's M4)
│   ├── PACK-CHAT.md                  (moved from root — B's M5)
│   ├── MERGE-STRATEGY.md             (moved from supporting-docs/ — B's M8)
│   └── DRY-RUN-MIGRATION.md          (moved from supporting-docs/ — B's M7)
│
├── backlog/                          (C2 — pack-self per-entry tree; STAYS at root; populated Batch 23 BD-102 dog-food per PACK-AGENTS.md forward-pointing note)
├── changelog/                        (C2 — pack-self per-entry tree; STAYS at root; same forward-pointing note)
│
├── maintenance-docs/                 (C2 — pack design records + cross-cutting methodology; unchanged from B's §8)
├── scripts/                          (C2 — pack-only scripts; unchanged from B's §8)
├── test-fixtures/                    (C2 — pack-only test infra; unchanged from B's §8)
├── supporting-docs/                  (C4 — clean PROJECT × PRODUCT after B's M6-M8; unchanged from B's §8)
├── project-template/                 (C4/C5/C6 — project-installed; unchanged from B's §8)
├── vscode-companion-templates/       (C4 — unchanged)
└── xcode-companion-templates/        (C4 — unchanged)
```

**Key changes from B's §8:**
- `BACKLOG.md` moves from root to `pack-ops/BACKLOG.md`.
- `CHANGELOG.md` moves from root to `pack-ops/CHANGELOG.md`.
- The C2-exempt-at-root list shrinks from 3 entries to 1 (only `tracker.toml.pack-example`).
- The per-entry source-of-truth trees `/backlog/` and `/changelog/` are now shown explicitly to disambiguate from the relocated mirrors (they STAY at root).

---

## §10 — Phase 5 coder guidance (concrete)

This section is action-oriented; planner refines into per-task units before coder spawns.

### §10.1 Pre-flight verification

Before any `git mv`, Phase 5 coder confirms:

1. `git status` clean.
2. `bash scripts/validate-pack.py` PASS at HEAD (baseline green).
3. `bash test-fixtures/build.sh --all --clean` clean (no manifest drift baseline).
4. Per-entry trees `/backlog/` and `/changelog/` are NOT yet populated (per forward-pointing note); confirm `ls backlog/ 2>/dev/null` returns empty. This means Check 32 currently SKIPs and the move-commit's only Check-32 concern is updating the STREAMS constant for future Batch 23 use.

### §10.2 Move sequence (folded into B's §6.4 step 3 per Option A)

Run the same commit as B's M1-M5 plus:

```bash
git mv BACKLOG.md pack-ops/BACKLOG.md
git mv CHANGELOG.md pack-ops/CHANGELOG.md
```

### §10.3 Per-file edits (added by M9/M10 on top of B's M1-M5 list)

**`scripts/validate-pack.py`:**
- Line 191: `"pack-backlog", "backlog", "BACKLOG.md"` → `"pack-backlog", "backlog", "pack-ops/BACKLOG.md"`
- Line 192: `"pack-changelog", "changelog", "CHANGELOG.md"` → `"pack-changelog", "changelog", "pack-ops/CHANGELOG.md"`
- Line 319: `backlog = REPO_ROOT / "BACKLOG.md"` → `backlog = REPO_ROOT / "pack-ops" / "BACKLOG.md"`
- Line 321 message: keep wording; update displayed path.
- Line 332 message: keep wording; update displayed path.
- Line 336 message: same.
- Line 122 docstring + line 238 + line 849 comment: update parenthetical path references.

**`scripts/lib/per-entry/_lib.sh`:**
- Line 71: `printf 'BACKLOG.md'` → `printf 'pack-ops/BACKLOG.md'`
- Line 79: `printf 'CHANGELOG.md'` → `printf 'pack-ops/CHANGELOG.md'`

**`scripts/lib/detect.sh`:**
- Lines 23-25: update docstring (pack-surface description).
- Line 35: scan loop — first candidate `"$target/pack-ops/BACKLOG.md"`, retain `"$target/docs/project/BACKLOG.md"` as fallback. Consider adding `"$target/BACKLOG.md"` as third fallback for legacy/test-fixture back-compat (planner + reviewer decide).

**`scripts/lib/recommendation.sh`:**
- Lines 131, 151, 152, 393, 462: update `$repo_root/BACKLOG.md` → `$repo_root/pack-ops/BACKLOG.md` for pack surface. Project-side fallback `$repo_root/docs/project/BACKLOG.md` STAYS.

**`scripts/lib/tracker-doctor.sh`:**
- Lines 114, 116, 118, 123, 129, 131, 135, 138: update `$repo_root/BACKLOG.md` → `$repo_root/pack-ops/BACKLOG.md` for pack surface. The doctor helper may need a surface-aware branch (check existing code shape; if it already branches by surface, only the pack branch updates).

**`scripts/lib/tracker-agent-read.sh`:**
- Lines 264, 267: update `mirror_path="$repo_root/BACKLOG.md"` → `mirror_path="$repo_root/pack-ops/BACKLOG.md"` for BD-* and unknown-prefix branches. TD-* branch unchanged.

**`scripts/lib/tracker-migrate-reverse.sh`:**
- Lines 1050, 1053, 1068, 1078, 1095, 1119, 1147: update reverse-emit destinations from `$repo_root/BACKLOG.md` and `$repo_root/CHANGELOG.md` to `$repo_root/pack-ops/BACKLOG.md` and `$repo_root/pack-ops/CHANGELOG.md`. **CRITICAL** for reverse-migration round-trip.

**`scripts/pack-help.sh`:**
- Line 33 usage docstring: update parenthetical reference.

**`scripts/tests/test-per-entry.sh`:**
- Line 220: `assert_eq "1.1 pack-backlog mirror filename" "BACKLOG.md" "$(pe_canonical_mirror_for_stream pack-backlog)"` → `assert_eq "1.1 pack-backlog mirror filename" "pack-ops/BACKLOG.md" "$(pe_canonical_mirror_for_stream pack-backlog)"`.
- Line 221: parallel update for pack-changelog → `"pack-ops/CHANGELOG.md"`.
- Lines 222, 224: project-side assertions UNCHANGED.
- Remaining lines (292-562, ~30 lines): fixture-tree paths inside `mktemp` dirs — STAY UNCHANGED. These are isolated test trees, not the pack repo's actual mirror. Per-line review by Phase 5 coder confirms.

**Pack-side trinity (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md` at pack root):**
- Lines 30-31: "Key files to read before working on the pack" — update bare `BACKLOG.md` / `CHANGELOG.md` references to `pack-ops/BACKLOG.md` / `pack-ops/CHANGELOG.md`. Per-entry tree references (`/backlog/`, `/changelog/`) UNCHANGED.
- Line 83 ("What agents may modify" — CHANGELOG.md): update.
- Line 99 ("What agents must never modify without explicit instruction" — BACKLOG.md): update.
- Line 389 ("BACKLOG.md has no Resolved section" bullet): update.
- All three trinity files edited in lockstep per trinity rule.

**Pack-side agent definitions (`.claude/agents/pack-*`, `.codex/agents/pack-*`, `.gemini/agents/pack-*`):**
- `pack-architect.md / .toml / .md`: line 27/18/29 read-list entry for BACKLOG.md.
- `pack-planner.md / .toml / .md`: line 32/18/25 read-list entry.
- `pack-coder.md / .toml / .md`: lines 34, 38 / 21, 23 / 36, 40 PM-only file list + BD-status-flip rule.
- All three CLI variants per trinity rule.

**Pack-side skills (`.claude/skills/`, `.codex/skills/`, `.gemini/`):**
- `pack-startup/SKILL.md` (Claude + Codex) and `.gemini/commands/pack-startup.toml`: lines 17-34 step-2 instructions naming both files and the per-entry-tree relationship. Per-line surgery: update mirror references; per-entry-tree references stay.
- `commit-discipline/SKILL.md` (3-way): grep + update per-line.
- `implementation-report/SKILL.md` (3-way): same.

**`pack-ops/PACK-AGENTS.md` (after B's M4 lands; in same commit):**
- Lines 143-144 PM-only files list: update bare `BACKLOG.md` / `CHANGELOG.md` references. Since PACK-AGENTS.md now lives at `pack-ops/PACK-AGENTS.md` and BACKLOG.md lives at `pack-ops/BACKLOG.md`, the references can be bare names (sibling-relative) OR absolute (`pack-ops/BACKLOG.md`). Phase 5 coder chooses consistent form; planner specifies.

**`README.md`:**
- Repository Layout ascii-tree block: relocate `BACKLOG.md` / `CHANGELOG.md` entries from pack-root section to `pack-ops/` section. Specific lines: ~261-262 (current location) → move under the new `pack-ops/` entry.
- Any other prose references to "pack BACKLOG" or "pack CHANGELOG" — update parenthetically.

### §10.4 Verification protocol additions to B's §6.8

After the combined Commit B lands:

1. `bash scripts/validate-pack.py` — all currently-enabled checks pass. Check 3, Check 22, Check 24, Check 32, Check 35 all touch the relocated paths; any failure here means a constant was missed.
2. `bash scripts/pack-help.sh --root .` — pack-side fragment resolves; detection picks pack-surface from new BACKLOG location.
3. `bash scripts/pack-help.sh --root project-template` — project-side fragment resolves unchanged.
4. `bash -c '. scripts/lib/detect.sh && detect_pack_surface .'` — returns `pack-surface: pack` (confirms detect.sh update).
5. `bash -c '. scripts/lib/per-entry/_lib.sh && pe_canonical_mirror_for_stream pack-backlog'` — returns `pack-ops/BACKLOG.md` (confirms _lib.sh update).
6. `bash scripts/tests/test-per-entry.sh` — passes (confirms assertion update).
7. `bash test-fixtures/build.sh --all --clean && git diff test-fixtures/manifest.txt` — stage the manifest diff if non-empty.
8. `git log --oneline -5` — Commit B shows the BD-175 reference.

If any step fails, Phase 5 coder reverts the offending commit and re-investigates before re-landing (per B's §6.8).

### §10.5 Operator-facing back-compat caveat

After Commit B lands, scripts or agents holding stale local references to `<repo>/BACKLOG.md` (e.g., a script pinned to a pre-fix git ref, or an externally cached path) will fail. The migration is internal to the pack repo; no downstream client-side impact (project-side `docs/project/BACKLOG.md` is UNAFFECTED). Phase 5 coder + Pack Chat surface the operator-facing impact in the commit message (already drafted in §7.3 above).

---

## §11 — Summary

- **§2:** B's §2 row 4 + row 5 reclassified from STAYS-exempt to MOVES, per AUDIT-USER-CURATION.md Override 5 + boundary articulation §5.
- **§3:** Both files move to `pack-ops/` (consistent with B's other M1-M8 PACK × OPERATIONS relocations; sole sibling of relocated PACK-CHAT.md / PACK-AGENTS.md). Per-entry trees (`/backlog/`, `/changelog/`) STAY at root — they are different artifacts from the mirror files.
- **§4:** The C2-at-root exemption list shrinks from 3 entries to 1 (only `tracker.toml.pack-example`).
- **§5:** MOVES list extends from B's M1-M8 to include M9 (BACKLOG.md) and M10 (CHANGELOG.md); ~140 + ~80 incremental path-reference updates respectively, mostly live pack-side surfaces (archive stays frozen, project-side unaffected).
- **§6:** Path-reference impact catalogued in five categories: live pack-internal (must update), live auto-detection helpers (CRITICAL must update — `detect_pack_surface`), live cross-reference docs (must update), frozen maintenance archive (no update), frozen project-side (no update — different files entirely).
- **§7:** Commit sequencing folds M9/M10 into B's existing root → pack-ops/ commit (Option A) — same shape, single auto-detection update, single validate-pack constant batch, single manifest regen.
- **§8:** Both of B's "external constraint" claims investigated and REJECTED. CI Check 32 is internal pack code (STREAMS constant); per-entry tree contract is about source-of-truth direction, not mirror location. New constraint surfaced (detect.sh:35 auto-detection) is also internal and updates parametrically. No genuine external constraint exists.
- **§9:** Updated directory tree shows seven pack-ops files (B's five + B-fix's two) co-located, with per-entry trees still at root.
- **§10:** Concrete Phase 5 guidance — per-file line-numbered edits, verification protocol additions, operator-facing back-compat caveat.

This fix-pass honors AUDIT-USER-CURATION.md Override 5 by moving BACKLOG.md and CHANGELOG.md to `pack-ops/`. B's other 8 design contributions (G7 boundary definition, G2 directory architecture, SC8 discoverability, M1-M8 + S1-S2 relocations, BOUNDARY-DEFINITION.md, manifest regen contract, verification protocol) stand unchanged.


---

## §12 — Phase 3 fix-pass extension (M3 / Override 7 + Override 10)

**Trigger:** PACK-REVIEW-PHASE-2-DESIGNS.md M3 (lines 108-124) + AUDIT-USER-CURATION.md Override 7 + Override 10.

**Authority:**
- **Override 7:** `QUICKSTART.md` STAYS at pack root as-is. No SPLIT. Architect B's S1 commit is DROPPED. `project-template/docs/pack/QUICKSTART.md` is NOT created. `init-project.sh` does NOT gain a new install stage for it.
- **Override 10:** Remove the `docs/pack/QUICKSTART.md` references from the 4 help files entirely (do NOT retarget). User framing: install docs (QUICKSTART) are pre-install pack-installer content; the 4 help files serve users using the pack inside their project and have no business pointing at install docs. Project-template `README.md` lines 16 + 39 are correctly worded ("in the pack root" / pack-supporting-doc read) and are NOT affected.

**Scope of amendment.** This section amends Architect B's original directory doc (`ARCHITECTURE-DIRECTORY-REORGANIZATION.md`) at every location B mentions QUICKSTART SPLIT (S1) or the project-side `docs/pack/QUICKSTART.md` file. After Phase 5 coder reads B-original through B-fix-extended in order, no instruction remains anywhere to create the SPLIT files or the surfaces["project-template"]["docs"] addition.

### §12.1 — Amendments to Architect B's original §4.4 (F-4 QUICKSTART.md split)

**B's original §4.4 (lines 378-406 of `ARCHITECTURE-DIRECTORY-REORGANIZATION.md`):** Designs the SPLIT into pack-side half (stays at `/QUICKSTART.md`) + project-side half (`project-template/docs/pack/QUICKSTART.md`); names content-split sketch for both halves; gives path-reference impact statement; calls out `scripts/validate-pack.py:1655` as unchanged AND `scripts/validate-pack.py` Check 22 `surfaces["project-template"]["docs"]` as gaining `REPO_ROOT / "project-template" / "docs" / "pack" / "QUICKSTART.md"`.

**Amendment (per Override 7 + Override 10):**

The entire SPLIT design in B's §4.4 is **REPLACED** with the following resolution:

> **§4.4 F-4 resolution (B-fix-extended per Override 7): KEEP AT ROOT, NO SPLIT.**
>
> `QUICKSTART.md` stays at pack root (`/QUICKSTART.md`) as-is. It is a pre-install pack-installer doc (~47 lines) that serves one audience — pack-installers evaluating the pack via GitHub or about to run `scripts/init-project.sh`. Audience-mixing concern from audit §F.F-4 is resolved by user direction (Override 7); the file does not need to serve a post-install in-project audience because no in-project workflow needs it (per Override 10).
>
> **Classification:** C1 (PACK × PRODUCT, landing-page surface). The "pack-installer GitHub visitor" audience is the same audience README.md serves, which is also C1 at pack root.
>
> **No SPLIT commit lands.** B's S1 commit is DROPPED in §12.2 below.
>
> **No project-side QUICKSTART created.** `project-template/docs/pack/QUICKSTART.md` is NOT created. `init-project.sh` gains no install stage for it.
>
> **Path-reference impact (amended):**
> - Pack-only refs to `QUICKSTART.md` (HELP-FRAGMENT-PACK.md, README.md, pack-side `.claude/agents/`, `.codex/agents/`, `.gemini/agents/`, `scripts/validate-pack.py`, B-fix M9-relocated `pack-ops/BACKLOG.md` and M10-relocated `pack-ops/CHANGELOG.md` if they mention QUICKSTART, etc.): UNCHANGED — point to pack-root `/QUICKSTART.md`.
> - Project-side refs in the 4 help files (`project-template/.gemini/commands/pack-help.toml:10`, `project-template/.claude/skills/pack-help/SKILL.md:13`, `project-template/.codex/skills/pack-help/SKILL.md:13`, `project-template/docs/pack/HELP-FRAGMENT.md:4` + `:31`): REMOVED entirely per Override 10. Wording-removal designed in §12.4 below.
> - Project-template `README.md` lines 16 + 39: UNAFFECTED. Both already correctly disambiguate ("in the pack root" / pack-supporting-doc read).
> - Supporting-docs refs (`MERGE-STRATEGY.md`, `METHODOLOGY.md`): Architect A's domain. These continue to point to pack-root `/QUICKSTART.md` regardless of B-fix-extension (no relocation occurred).
>
> **`scripts/validate-pack.py:230` (REQUIRED_BD044_DOCS):** Stays valid (`REPO_ROOT / "QUICKSTART.md"` — pack-root file unchanged). **No change.**
>
> **`scripts/validate-pack.py:1655` (Check 22 `surfaces["pack-root"]["docs"]`):** Stays valid (`REPO_ROOT / "QUICKSTART.md"`). **No change.** (B-fix §6.6 already records this as unchanged; B-fix-extended confirms.)
>
> **`scripts/validate-pack.py` Check 22 `surfaces["project-template"]["docs"]` (line 1663-1665):** The addition of `REPO_ROOT / "project-template" / "docs" / "pack" / "QUICKSTART.md"` that B's §4.4 mentioned is **DROPPED**. No project-side QUICKSTART.md exists, so no entry needs validating. The current contents of `surfaces["project-template"]["docs"]` (`PM-CHAT.md`) remain as-is.

### §12.2 — Amendments to Architect B's original §6.2 (SPLIT list — S1 row)

**B's original §6.2 (lines 537-541 of `ARCHITECTURE-DIRECTORY-REORGANIZATION.md`):** The SPLIT table includes:

| # | Source | Pack-side stays | Project-side new | Notes |
|---|---|---|---|---|
| S1 | `QUICKSTART.md` | `QUICKSTART.md` (content trimmed to pack-side audience) | `project-template/docs/pack/QUICKSTART.md` (new file, project-side audience) | Per §4.4. Pack-side path unchanged; project-side path new. `init-project.sh` gains an install stage. |
| S2 | `OPTIONAL-FEATURES.md` (conditional on Architect A) | `pack-ops/OPTIONAL-FEATURES.md` (moved per M3) | `project-template/docs/pack/OPTIONAL-FEATURES.md` (new file, IF B's recommended default per §4.5 is accepted) | Per §4.5. New project-side file under `init-project.sh` install. |

**Amendment (per Override 7):**

The S1 row is **DELETED**. Updated SPLIT list contains S2 only:

| # | Source | Pack-side stays | Project-side new | Notes |
|---|---|---|---|---|
| S2 | `OPTIONAL-FEATURES.md` (per Override 8 — CONFIRMED SPLIT) | `pack-ops/OPTIONAL-FEATURES.md` (moved per M3) | `project-template/docs/pack/OPTIONAL-FEATURES.md` (new file, project-side audience) | Per §4.5 + §12 content-split sketch. `init-project.sh` gains an install stage. |

Note that the S2 conditional "(conditional on Architect A)" qualifier is also lifted per Override 8 (CONFIRMED SPLIT) — Phase 5 coder lands S2 unconditionally.

### §12.3 — Amendments to Architect B's original §6.4 step 5 (commit sequencing — S1 commit)

**B's original §6.4 step 5 (line 563 of `ARCHITECTURE-DIRECTORY-REORGANIZATION.md`):**

> 5. **Execute S1 (QUICKSTART.md split) as a third commit.** Pack-side QUICKSTART.md trims content; project-side QUICKSTART.md is created with project-targeted content; `init-project.sh` gains the install stage; references update. Architect A's per-content findings for QUICKSTART apply to whichever half the content lands on.

**Amendment (per Override 7):**

Step 5 is **DELETED**. The commit sequence in B's §6.4 collapses by one commit:

- **Old step 5 (S1 third commit):** DELETED — no S1 commit lands.
- **Old step 6 (S2 fourth commit, conditional):** **becomes new step 5; conditional qualifier lifted per Override 8.**

Updated B's §6.4 sequence after §12.3 amendment (cross-referenced with B-fix §7.1 Option A folding):

1. **Commit A (CREATE):** `pack-ops/.boundary-exempt-root.txt` + `pack-ops/BOUNDARY-DEFINITION.md` (B's N1 + N2 unchanged).
2. **Commit B (MOVES — combined M1-M5 + M9-M10 per B-fix §7.1):** seven root → `pack-ops/` files in one commit; auto-detection, validate-pack, per-entry, recommendation, doctor, tracker-agent-read, tracker-migrate-reverse, pack-help, test-per-entry assertions, pack-side trinity, pack-* agents, pack-startup skills, README repo-layout, manifest regen.
3. **Commit C (M6-M8):** `supporting-docs/` → `pack-ops/` for ALL THREE files (M6 `CONCEPTUAL-REVIEW-METHODOLOGY.md` → `pack-ops/` per `AUDIT-USER-CURATION.md` Override 6 — this v2 amendment closes the cascade gap acknowledged in the pre-v2 wording of this step; see §16 below for the cascade detail; M7 `DRY-RUN-MIGRATION.md` → `pack-ops/`; M8 `MERGE-STRATEGY.md` → `pack-ops/`). All three MOVES land in the same commit; reference updates; manifest regen.
4. **Commit D (S2, per Override 8):** `pack-ops/OPTIONAL-FEATURES.md` (moved as part of Commit B's M3) gains a project-side sibling `project-template/docs/pack/OPTIONAL-FEATURES.md` created with project-side-audience content per §12 content-split sketch; `init-project.sh` gains the install stage; the 5 project-side references resolve to the new file; manifest regen.

**No S1 commit appears anywhere in the sequence.** The previous "step 6 conditional on Architect A" framing collapses to an unconditional step 4 (since Override 8 confirmed SPLIT — see also S2 reviewer finding cascade, this fix-pass extension does not address S2 directly because that is Architect A's fix-pass scope, but the conditional qualifier is correctly lifted here for consistency with B's commit sequencing).

### §12.4 — Wording-removal designed for each of the 4 help files (Override 10)

Per Override 10, the 5 references in 4 help files to `docs/pack/QUICKSTART.md` are REMOVED entirely. The other doc names in each list (PM-CHAT.md / INSTALL-PROCEDURES.md / OPTIONAL-FEATURES.md) are PRESERVED — they are valid in-project help references. Trinity rule applies because three of the four files are CLI-parallel (`.claude/`, `.codex/`, `.gemini/` surfaces).

#### §12.4.1 — `project-template/.gemini/commands/pack-help.toml` (file 1 of 4)

**Affected line:** 10 (also touches line 11 due to multi-line phrasing).

**Current text (lines 3-13):**

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

**Amended text (lines 3-13):**

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

**Mechanical edit:** Delete `docs/pack/QUICKSTART.md,` from line 10 and rewrap the surviving comma-separated list. The "For full documentation, see " prefix and the trailing-period sentence boundary stay; only the QUICKSTART token (with its trailing comma + space) is removed. The list shortens from 4 items to 3 items with appropriate `,` / `, and` placement.

#### §12.4.2 — `project-template/.claude/skills/pack-help/SKILL.md` (file 2 of 4)

**Affected line:** 13 (also touches lines 14-15 due to multi-line phrasing).

**Current text (lines 11-16):**

```
## Notes

For full documentation, see `docs/pack/QUICKSTART.md`,
`docs/pack/PM-CHAT.md`, `docs/pack/INSTALL-PROCEDURES.md`, and
`docs/pack/OPTIONAL-FEATURES.md`. The shell verb `pack help`
(LCD floor) prints the same content as this skill.
```

**Amended text (lines 11-16):**

```
## Notes

For full documentation, see `docs/pack/PM-CHAT.md`,
`docs/pack/INSTALL-PROCEDURES.md`, and `docs/pack/OPTIONAL-FEATURES.md`.
The shell verb `pack help` (LCD floor) prints the same content as this skill.
```

**Mechanical edit:** Delete the `` `docs/pack/QUICKSTART.md`, `` token from line 13 and rewrap the surviving list. Backticks preserved on the surviving items. The "The shell verb..." sentence keeps its content; only the punctuation surrounding the trailing period adjusts as the preceding list shortens by one item.

#### §12.4.3 — `project-template/.codex/skills/pack-help/SKILL.md` (file 3 of 4)

**Affected line:** 13 (also touches lines 14-15; this file is byte-identical to §12.4.2 today per trinity parity).

**Current text:** Same as §12.4.2 above.

**Amended text:** Same as §12.4.2 above.

**Mechanical edit:** Same as §12.4.2. Apply in lockstep with §12.4.2 per trinity rule (Claude + Codex parity for pack-help skill).

#### §12.4.4 — `project-template/docs/pack/HELP-FRAGMENT.md` (file 4 of 4)

**Affected lines:** 4 (in the front-matter sentence) AND 31 (in the "See also" list). TWO removals in this file.

**Reference 1 of 2 — Front-matter sentence (lines 1-7):**

**Current text (lines 1-7):**

```
# Pack v11 — verb reference (this project)

Verb manifest for **this project**. Run `pack help` or `/pack-help` in
your CLI for this content. Full docs in `docs/pack/QUICKSTART.md`,
`docs/pack/PM-CHAT.md`, `docs/pack/INSTALL-PROCEDURES.md`,
`docs/pack/OPTIONAL-FEATURES.md`.
```

**Amended text (lines 1-7):**

```
# Pack v11 — verb reference (this project)

Verb manifest for **this project**. Run `pack help` or `/pack-help` in
your CLI for this content. Full docs in `docs/pack/PM-CHAT.md`,
`docs/pack/INSTALL-PROCEDURES.md`, `docs/pack/OPTIONAL-FEATURES.md`.
```

**Mechanical edit:** Delete the `` `docs/pack/QUICKSTART.md`, `` token from line 4. The "Full docs in " prefix and the trailing period stay; the list shortens from 4 items to 3 items with appropriate comma placement.

**Reference 2 of 2 — "See also" section (lines 29-33):**

**Current text (lines 29-33):**

```
## See also

`docs/pack/QUICKSTART.md`, `docs/pack/PM-CHAT.md`,
`docs/pack/METHODOLOGY.md`, `docs/pack/PLATFORM-SKILLS.md`,
`docs/pack/OPTIONAL-FEATURES.md`, `docs/project/BACKLOG.md`.
```

**Amended text (lines 29-33):**

```
## See also

`docs/pack/PM-CHAT.md`, `docs/pack/METHODOLOGY.md`,
`docs/pack/PLATFORM-SKILLS.md`, `docs/pack/OPTIONAL-FEATURES.md`,
`docs/project/BACKLOG.md`.
```

**Mechanical edit:** Delete the `` `docs/pack/QUICKSTART.md`, `` token from line 31. The "## See also" heading stays; the list shortens from 6 items to 5 items with appropriate comma placement and line rewrapping.

**Note on `docs/project/BACKLOG.md` reference in line 33:** This reference is to the PROJECT-side BACKLOG (the client's installed `docs/project/BACKLOG.md`), NOT the pack-side mirror. It is UNAFFECTED by B-fix M9 (B-fix M9 moves only the pack-side `BACKLOG.md` to `pack-ops/`); project-side `docs/project/BACKLOG.md` is the client's own file. Override 10 does not touch this reference.

### §12.5 — Trinity rule compliance for §12.4 edits

The three CLI-parallel pack-help skill files (`pack-help.toml`, `.claude/.../SKILL.md`, `.codex/.../SKILL.md`) are TRINITY (Claude + Codex + Gemini parity for the pack-help skill). Per the pack memory trinity rule:

- §12.4.1 (Gemini): edit lands in the same commit as §12.4.2 + §12.4.3.
- §12.4.2 (Claude): edit lands in the same commit as §12.4.1 + §12.4.3.
- §12.4.3 (Codex): edit lands in the same commit as §12.4.1 + §12.4.2.
- §12.4.4 (HELP-FRAGMENT.md): NOT trinity-parallel by name (different shape), but lives in the same project-side help surface and SHOULD land in the same commit for cohesion. Phase 5 coder treats §12.4.1-§12.4.4 as a single 4-file commit, not split across commits.

After the edits land, the three trinity files (`pack-help.toml`, `.claude/.../SKILL.md`, `.codex/.../SKILL.md`) remain symmetric — they all reference the same 3 docs (PM-CHAT.md, INSTALL-PROCEDURES.md, OPTIONAL-FEATURES.md) instead of the previous 4.

### §12.6 — Amendments to Architect B's original §8 (final-state directory tree)

**B's original §8 tree (line 757 of `ARCHITECTURE-DIRECTORY-REORGANIZATION.md`):**

```
│   │   │   ├── HELP-FRAGMENT.md, HELP-FRAGMENT-TRACKER.md
│   │   │   ├── PACK-FEEDBACK.md, PLATFORM-SKILLS.md, PM-CHAT.md
│   │   │   ├── QUICKSTART.md         (NEW — project-side half from S1 split)
│   │   │   ├── OPTIONAL-FEATURES.md  (NEW conditional — from S2 split if Architect A accepts default)
│   │   │   └── prompts/
```

**Amendment (per Override 7 + Override 8):**

The `QUICKSTART.md (NEW ...)` row is **DELETED** from the `project-template/docs/pack/` block. The `OPTIONAL-FEATURES.md` row's "(NEW conditional — from S2 split if Architect A accepts default)" qualifier becomes "(NEW — from S2 split per Override 8)" (unconditional). Amended block:

```
│   │   │   ├── HELP-FRAGMENT.md, HELP-FRAGMENT-TRACKER.md
│   │   │   ├── PACK-FEEDBACK.md, PLATFORM-SKILLS.md, PM-CHAT.md
│   │   │   ├── OPTIONAL-FEATURES.md  (NEW — project-side from S2 split per Override 8)
│   │   │   └── prompts/
```

**B-fix §9 (final-state directory tree in this doc) is NOT amended** — B-fix's §9 already shows the pack-root section without a `project-template/docs/pack/QUICKSTART.md` entry (it only shows pack-root layout, not `project-template/` sub-layout). No drift to fix in B-fix §9.

### §12.7 — Net effect on Phase 5 coder instructions

After §11 lands, Phase 5 coder receiving B-original + B-fix-extended as a paired read sees:

- **No S1 commit anywhere.** Override 7 (B's S1 dropped) is reflected in B's §4.4 (amended), §6.2 (S1 row deleted), §6.4 step 5 (deleted), §8 (project-side QUICKSTART row deleted).
- **No `validate-pack.py` Check 22 `surfaces["project-template"]["docs"]` addition.** Override 7 (no project-side QUICKSTART exists) is reflected in §12.1 amendment.
- **No `init-project.sh` install stage for project-side QUICKSTART.md.** Override 7.
- **4-file wording-removal commit** for Override 10 (the 5 references to `docs/pack/QUICKSTART.md` in 4 help files), per §12.4. Trinity rule applies for the 3 CLI-parallel files. Single commit covers all 4 files.
- **S2 commit unconditional per Override 8.** B's original §6.4 step 6 conditional-on-Architect-A qualifier is lifted (already noted in §12.3); content-split sketch in §12 below provides starting structure.

**Override 7 citation:** This entire §11 is authorized by AUDIT-USER-CURATION.md §1 Override 7. No further verification needed.

**Override 10 citation:** §12.4 is authorized by AUDIT-USER-CURATION.md §1 Override 10. The architect's call (per Override 10's "Architect B's call HOW to reword") is the per-file wording removals designed above; the user's call is the REMOVE direction.


---

## §13 — Phase 3 fix-pass extension (S3 OPTIONAL-FEATURES.md content-split sketch)

**Trigger:** PACK-REVIEW-PHASE-2-DESIGNS.md S3 (lines 185-198) + AUDIT-USER-CURATION.md Override 8.

**Authority:**
- **Override 8 (CONFIRMED SPLIT):** "One for pack. One for projects. There may be something common to both and maybe some individual to both. That is OK." Pack-side and project-side files are independently curated; the project-side file is NOT required to be a byte-identical mirror — content overlap is allowed where it serves both audiences, but each file's content is tailored to its audience.

**Reviewer's concern (S3):** B's §4.5 says "create a new file `project-template/docs/pack/OPTIONAL-FEATURES.md` with project-side-audience content (subset of pack-side, project-targeted)." The "subset" content split is not designed anywhere. Phase 5 coder receives a content-design task masquerading as a mechanical task. Without specificity, the coder will improvise — exactly the P-missed-7 anti-pattern this BD is trying to fix.

**Fix shape (per reviewer):** Add a 5-10 line content-split sketch naming which sections of current `OPTIONAL-FEATURES.md` stay pack-only vs ship as project-side content. Honor Override 8: not byte-identical mirror; tailored per audience; common-to-both content acceptable.

### §13.1 — Current `OPTIONAL-FEATURES.md` section inventory (pre-split)

Source: `OPTIONAL-FEATURES.md` at pack root (will move to `pack-ops/OPTIONAL-FEATURES.md` per B's M3). The current file has these top-level sections (## headings):

1. **Intro paragraphs** (no heading; lines 1-15): purpose statement, feature characteristics (tool-specific / experimental / higher-cost), cross-CLI-by-default disclaimer.
2. **`## Claude Code — Agent Teams`** (lines 19-107): tool-specific Claude-only feature; status, what it is, when it matters, how to enable (settings.json env var), how to use pack agents as teammates, caveats, when to skip.
3. **`## Codex CLI — Optional features`** (lines 111-114): placeholder section for future Codex-specific opt-in features.
4. **`## Gemini CLI — Optional features`** (lines 118-121): placeholder section for future Gemini-specific opt-in features.
5. **`## Tracker integration (v11)`** (lines 125-219): tracker opt-in; status, what it is, when it matters, how to enable (`pack tracker init`), how to use, caveats (gh auth, multi-project, sidecar reconciliation), failure modes (customization-detected-needs-reconciliation), how to disable, when to skip.
6. **`## Adding new entries`** (lines 223-235): contributor guidance for adding new optional-feature sections (status / what / when / enable / use / caveats / when-to-skip shape).

### §13.2 — Audience analysis

**Pack-side audience** (post-move at `pack-ops/OPTIONAL-FEATURES.md`):
- Pack maintainers deciding whether to introduce / deprecate / refine an optional feature.
- Pack Chat orchestrating pack-self workflows that may opt into a feature (e.g., enabling Agent Teams in the pack repo for pack work).
- Pack agents (architect / planner / reviewer) consulting the canonical pack-feature catalog when designing pack-self work.
- Pack contributors authoring new optional-feature sections per the "Adding new entries" shape contract.

**Project-side audience** (new file at `project-template/docs/pack/OPTIONAL-FEATURES.md`, installed by `init-project.sh` to client `<client>/docs/pack/OPTIONAL-FEATURES.md`):
- Project PM chats (`pm-startup`) deciding whether to opt the client project into a feature (tracker init, Agent Teams in the client repo, etc.).
- Project developers consulting feature catalog when reviewing CLI capability tradeoffs for the client repo.
- Project agents (when applicable) consulting the feature catalog when in-project workflows reference opt-in features.

### §13.3 — Content-split sketch (5-10 line outline per Override 8)

The two files are independently curated. Sections classified as **pack-side-only**, **project-side-only**, or **common-to-both** (tailored wording per audience for common content):

| Section | Pack-side (`pack-ops/`) | Project-side (`project-template/docs/pack/`) | Audience-tailoring notes |
|---|---|---|---|
| Intro paragraphs | KEEP — pack-maintainer framing ("pack stays cross-CLI by default") | ADAPT — project-PM framing ("your project can opt into per-CLI features without abandoning cross-CLI parity") | Common-to-both topic; different voice. |
| `## Claude Code — Agent Teams` | KEEP FULL — pack-self use case + how pack agents work as teammates (the "pack agents at `.claude/agents/<name>.md`" reference is pack-internal) | ADAPT — project-side framing: "your client repo can adopt Agent Teams; the project agents (`.claude/agents/coder.md` etc.) work as teammate types"; reference project-side agent paths, not pack-side. | Common topic; different example paths and different motivating use cases. |
| `## Codex CLI — Optional features` | KEEP placeholder | KEEP placeholder | Common-to-both; both are forward-pointing stubs. |
| `## Gemini CLI — Optional features` | KEEP placeholder | KEEP placeholder | Common-to-both. |
| `## Tracker integration (v11)` — pack surface | KEEP FULL — pack-repo tracker opt-in (`pack-tracker.sh init` from pack-repo CWD), pack-side `tracker.toml.pack-example`, pack-side recommendation signals (BD count, BACKLOG.md size), pack-self failure modes | DROP pack-self-specific subsections (pack repo CWD; pack-side example; pack-side signals) | Pack-only mechanism; not project-relevant in this form. |
| `## Tracker integration (v11)` — project surface | (covered by pack-side narration of the dual-surface model) | KEEP FULL — project tracker opt-in (`pack-tracker.sh init` from client-repo CWD), client-side `tracker.toml.example` (installed by `init-project.sh` from `tracker.toml.project-example`), project-side recommendation signals (project BD count, project BACKLOG.md size), client-side failure modes | Project-only mechanism; the pack-side narration mentions the project-surface exists but doesn't duplicate the project-side how-to. |
| `## Tracker integration (v11)` — `customization-detected-needs-reconciliation` reference | KEEP — points to `pack-ops/MERGE-STRATEGY.md` (per B's M8 destination) | KEEP — points to the same `pack-ops/MERGE-STRATEGY.md` (with the "in the pack repo" qualifier since the client install does not ship `pack-ops/`); OR (alternative) ship a project-side MERGE-STRATEGY excerpt at `project-template/docs/pack/MERGE-STRATEGY.md` IF Architect A's content re-litigation directs (Architect A's domain, not B). | Pack-only mechanism doc; project-side reader needs the pointer but the doc itself stays pack-side. |
| Pack-tracker plumbing details (validate-pack Check 22 mentions, STREAMS constant references, per-entry-tree contract details) | KEEP — pack-internal plumbing relevant only to pack maintainers | OMIT entirely — project-PM doesn't need pack-internal validation details | Pack-only content; would be TYPE-2 contamination if copied to project-side. |
| `## Adding new entries` | KEEP — pack-contributor guidance for adding to `pack-ops/OPTIONAL-FEATURES.md` | KEEP-OR-ADAPT — same shape contract applies; project-side version emphasizes the project's role: "if the project surfaces a project-specific optional feature, add it here." Some projects may not use this section at all. Phase 5 coder ships the same shape; ProjPM may rewrite or remove during project use. | Common-to-both shape contract; different scope (pack-self vs project-self). |

**Pack-side file (`pack-ops/OPTIONAL-FEATURES.md`) post-split contains:** the full Agent Teams section as currently written, Codex/Gemini placeholders, the FULL Tracker integration section with pack-self framing and pack-only plumbing details, the contributor guidance. Approximate length: similar to current (~235 lines); plumbing details preserved.

**Project-side file (`project-template/docs/pack/OPTIONAL-FEATURES.md`) post-split contains:** intro paragraphs in project-PM voice, Agent Teams section with project-side agent path examples and project-side use cases, Codex/Gemini placeholders, Tracker integration section with project-self framing (client CWD, client `tracker.toml.example`, project-side recommendation signals, client-side failure modes) and a pointer to `pack-ops/MERGE-STRATEGY.md` qualified with "in the pack repo", the contributor guidance adapted for project use. Approximate length: ~150-180 lines (shorter; plumbing details omitted).

### §13.4 — Phase 5 coder guidance for S2 content split

Phase 5 coder reading B-original §4.5 + §6.2 step 6 + B-fix-extended §12.2 + §13.3 above:

1. **Pack-side file:** `git mv OPTIONAL-FEATURES.md pack-ops/OPTIONAL-FEATURES.md` (B's M3); no content edits at move time. Subsequent S2 commit may tighten pack-side wording to remove project-side voice (the intro paragraph rewording per §13.3) but content stays substantively unchanged. Length stays ~235 lines.
2. **Project-side file:** CREATE `project-template/docs/pack/OPTIONAL-FEATURES.md` from scratch, using `pack-ops/OPTIONAL-FEATURES.md` as the SOURCE STRUCTURE TEMPLATE. Walk each section per §13.3 table. For ADAPT rows, rewrite from the project-side audience perspective (project-PM voice, client-repo CWD assumption, project-side agent path examples). For DROP rows, omit entirely. For KEEP rows, copy verbatim. For OMIT rows, suppress. Result: a project-targeted feature catalog ~150-180 lines.
3. **`init-project.sh`:** Add the install stage: copy `project-template/docs/pack/OPTIONAL-FEATURES.md` → `<client>/docs/pack/OPTIONAL-FEATURES.md` during init. Existing install-stage scaffolding (e.g., the loop in `init-project.sh` that copies all `project-template/docs/pack/*.md` files) likely already handles this — Phase 5 coder verifies no special-casing needed.
4. **5 project-side references** to `docs/pack/OPTIONAL-FEATURES.md` in `project-template/.gemini/commands/pack-help.toml`, `project-template/.claude/skills/pack-help/SKILL.md`, `project-template/.codex/skills/pack-help/SKILL.md`, `project-template/docs/pack/HELP-FRAGMENT.md` (front-matter + See-also): UNCHANGED — they resolve correctly to the newly-created project-side file.
5. **No byte-identity contract** between pack-side and project-side files (different from HELP-FRAGMENT-TRACKER.md Check 24 pattern). Per Override 8, byte-identity is explicitly rejected — content overlap is acceptable where it serves both audiences, but each file is independently curated.

### §13.5 — TYPE-2 contamination avoidance during the split

The S3 finding warns that without specificity, the coder will improvise — reflexively copying "pack tracker integration" content into project-side without considering audience. §13.3 explicitly classifies each section to prevent this:

- Pack-tracker plumbing (validate-pack Check 22, STREAMS, per-entry-tree contract): EXPLICITLY OMITTED from project-side per §13.3 "Pack-tracker plumbing details" row. Phase 5 coder DOES NOT copy these mentions into project-side.
- Pack-self surface mentions (pack-repo CWD, pack-side `tracker.toml.pack-example`): EXPLICITLY DROPPED from project-side per §13.3 tracker pack-surface row. Project-side uses project-side framing (client CWD, client `tracker.toml.example`).
- `pack-ops/` path references: When project-side content needs to reference a pack-only file (e.g., MERGE-STRATEGY.md), the reference is QUALIFIED with "in the pack repo" per Architect C's prevention work (the TYPE-4 contamination guardrail). Phase 5 coder applies this qualifier consistently.

### §13.6 — Override 8 citation

This entire §12 is authorized by AUDIT-USER-CURATION.md §1 Override 8 ("CONFIRMED SPLIT"). The user explicitly endorsed (a) pack-side and project-side as separate independently-curated files, (b) common-to-both content as acceptable, (c) per-audience tailoring as the operative principle. §13.3's table operationalizes (c); §13.4's coder guidance operationalizes (a) and (b); §13.5 operationalizes the anti-contamination contract embedded in the user's framing.

---

## §14 — Phase 3 fix-pass extension (N2 count-agnostic verification phrasing)

**Trigger:** PACK-REVIEW-PHASE-2-DESIGNS.md N2 (lines 269-275).

**Authority:** Reviewer's NIT finding accepted (triaged FIX per default-fix-all pack memory).

**Reviewer's concern:** B-fix §10.4 step 1 says "`bash scripts/validate-pack.py` — all 33 checks pass." Architect C designs Checks 36, 37, 38 (new checks not yet implemented at HEAD). The hardcoded "33 checks" count will drift when C's checks land — Phase 5 coder running validate-pack post-C will see 36+ checks, and the hardcoded count becomes misleading.

**Fix applied:** Edit applied INLINE at B-fix §10.4 step 1 (line 536 of this doc post-extension). The phrase "all 33 checks pass" was replaced with "all currently-enabled checks pass" — count-agnostic phrasing that holds regardless of whether the check count is 33 (pre-C) or 36+ (post-C). The verification semantics are preserved: every enabled check must pass; the count itself is not load-bearing on the assertion.

**Net effect:** Phase 5 coder reading B-fix §10.4 step 1 sees a count-agnostic instruction. If validate-pack.py at Phase 5 execution time has 33 checks, all 33 must pass. If it has 36+ (post-C-fix landing first), all 36+ must pass. No hardcoded count to maintain.

**Cross-reference:** This is the only count-hardcoded location in B-fix; §6 references to "Check 3, Check 22, Check 24, Check 32, Check 35" (line 536, post-fix) are check-name references (stable identifiers), not check counts (drifting numbers). No further amendment needed.

---

## §15 — Summary of B-fix extension

- **§12 (M3 + Override 7 + Override 10):** Amends B-original at §4.4 (drop SPLIT design; KEEP-AT-ROOT resolution), §6.2 (delete S1 row from SPLIT table), §6.4 step 5 (delete S1 commit; lift S2 conditional per Override 8), §8 (delete project-side QUICKSTART row from tree). Drops the `surfaces["project-template"]["docs"]` addition to validate-pack.py Check 22. Designs per-file wording-removal for 4 help files (5 references total) per Override 10. Honors trinity rule across `.claude/` / `.codex/` / `.gemini/` parallel files.
- **§13 (S3 + Override 8):** Provides 5-10 line content-split sketch for project-side `OPTIONAL-FEATURES.md` creation. Inventories current pack-side sections; classifies each as pack-side-only / project-side-only / common-to-both per audience analysis. Operationalizes Override 8's "common-to-both is OK; tailored per audience" principle. Provides Phase 5 coder guidance + TYPE-2 contamination avoidance contract.
- **§14 (N2):** Replaced "all 33 checks pass" with "all currently-enabled checks pass" at §10.4 step 1 — count-agnostic.

**Existing B-fix content (§1-§10) is UNCHANGED.** All extensions are at the end of the document, appended after the original §11 summary line. The original §11 summary (now displaced by these extensions) still serves as the closing for the M9/M10 BACKLOG.md/CHANGELOG.md fix-pass scope; §12-§14 are scope-additions for the Phase 3 review findings.

**Phase 5 coder reads B-original + B-fix (§1-§15) in order.** No additional judgment required for the M3/Override 10/S3/N2 surfaces; the amendments at §12-§14 are mechanical.

---

## §16 — Phase 3 fix-pass v2 amendment (Override 6 cascade to B's design)

### §16.1 — Authority

`AUDIT-USER-CURATION.md` Override 6 (verbatim):

> **Architect B said:** Moves `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` to `maintenance-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md`.
>
> **User override:** **`pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md`.** B's "maintenance-docs/ houses live methodology" reasoning is rejected. Destination is `pack-ops/`.
>
> **Phase 5 coder:** moves to `pack-ops/`, not `maintenance-docs/`. Path-reference updates target `pack-ops/`.

### §16.2 — Why this amendment exists (the gap closed)

During the Phase 3 fix-pass (this doc's §10-§15), Override 6 was applied to Architect A's `ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md` (via the A-fix S1 amendments — see A-fix §10.2). It was NOT rippled into Architect B's `ARCHITECTURE-DIRECTORY-REORGANIZATION.md` (B-original) or into this B-fix doc itself. The pre-v2 wording of B-fix §11.3 step 3 (line 646 area, now amended in this v2) explicitly acknowledged the gap:

> "Override 6 places `CONCEPTUAL-REVIEW-METHODOLOGY.md` at `pack-ops/`, not `maintenance-docs/`; that override is Architect A / B-fix cross-cutting and is NOT amended in B-fix §11 — see B-fix front-matter cross-ref."

That self-flagged gap was known-but-deferred at the time of the first fix-pass. User has now authorized a small B fix-pass v2 amendment to ripple Override 6 through the 5 stale references. This §16 documents the v2 amendment and closes the gap.

### §16.3 — The 5 amended locations (before / after summary)

**File 1: `maintenance-docs/v11-implementation/ARCHITECTURE-DIRECTORY-REORGANIZATION.md` (B-original) — 4 locations:**

1. **§4.1 F-1 resolution, step 1 bullet (was line 339):**
   - **Before:** `CONCEPTUAL-REVIEW-METHODOLOGY.md` → `maintenance-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` ... `maintenance-docs/` is the existing home for pack methodology ...
   - **After:** `CONCEPTUAL-REVIEW-METHODOLOGY.md` → `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` ... `pack-ops/` is the home for pack operational docs ... CONCEPTUAL-REVIEW-METHODOLOGY belongs alongside them as a sibling pack-operations doc. Cross-reference to this §16 inserted in-line.

2. **§4.1 "Naming rationale" paragraph (was line 349):**
   - **Before:** A multi-sentence paragraph DEFENDING `maintenance-docs/` over `pack-ops/` on live-vs-textbook / sibling-family grounds.
   - **After:** Replaced with an Override-6 supersession marker. The defended rationale is explicitly labeled REJECTED; the file's role as pack-internal methodology consumed by pack agents is preserved as the justification for the new `pack-ops/` placement. Cross-reference to this §16 inserted in-line.

3. **§5.2 cross-reference network, design-surface bullet (was line 472):**
   - **Before:** `maintenance-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` (after F-1 move) — add a pointer ...
   - **After:** `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` (after F-1 move per Override 6) — add a pointer ...

4. **§6.1 MOVES table, M6 row (was line 531):**
   - **Before:** Destination column = `maintenance-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md`.
   - **After:** Destination column = `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` (per Override 6; see B-fix §16).

**File 2: `maintenance-docs/v11-implementation/ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` (this doc) — 2 locations:**

5. **§5 MOVES table, M6 row (was line 134):**
   - **Before:** Destination column = `maintenance-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md`.
   - **After:** Destination column = `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` (per Override 6; see §16 below).

6. **§11.3 step 3, Commit C bullet (was line 646):**
   - **Before:** Step 3 described Commit C as `supporting-docs/` → `maintenance-docs/` for M6, with an inline "wait, Override 6 places it at `pack-ops/`, not `maintenance-docs/`; that override is ... NOT amended in B-fix §11" acknowledgment.
   - **After:** Step 3 unconditionally describes all three M6/M7/M8 moves as `supporting-docs/` → `pack-ops/`, with cross-reference to this §16 for the cascade detail. The forward-pointing speculation is replaced with a closed-gap reference.

(Locations 5 + 6 are inside the file this §16 lives in. Counting independently: 5 stale references at amendment time, plus this new §16 as the documenting amendment.)

### §16.4 — Sections NOT amended

- **§1-§15 of this doc:** UNTOUCHED, with the sole exception of the two inline edits at §5 M6 row (table cell) and §11.3 step 3 (Commit C bullet wording). All other paragraphs, sub-sections, tables, and lists are byte-stable from the pre-v2 state.
- **§12-§15 (just-landed Phase 3 fix-pass extensions):** UNTOUCHED. Those extensions covered M3/Override 7/Override 10 (§12), S3/Override 8 (§13), N2 count-agnostic phrasing (§14), and the §15 summary. Override 6 was out of scope for those extensions; this §16 v2 amendment is a strict scope addition, not a rewrite.
- **Architect A's `ARCHITECTURE-RE-LITIGATION-FRAMEWORK.md`:** Already amended in A-fix S1 (see A-fix §10.2). No further A-side ripple needed for Override 6 — A's doc already names `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` explicitly. This v2 amendment brings B's docs to the same coverage A's doc already has.
- **Architect C's design doc:** Per Pack Chat's earlier grep, C references CONCEPTUAL-REVIEW-METHODOLOGY only in the source context (`supporting-docs/` audit V4 finding) and does NOT reference any destination path. No C-side ripple needed.

### §16.5 — Net effect on Phase 5 coder instructions

Phase 5 coder reads B-original + B-fix (§1-§16) in sequence. The M6 destination after this v2 amendment is unambiguously `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` — both the MOVES tables (B-original §6.1, B-fix §5) and the commit-sequencing step (B-fix §11.3 step 3) agree. Path-reference updates for the file's old `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` location target the new `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` path. The cross-reference-network bullet in B's §5.2 (now amended) names the same `pack-ops/` destination, so reviewer-protocol pointers that add a citation in dimension (d) Pack rule adherence resolve to the correct file. No further architect-side amendments are needed for Override 6.

### §16.6 — Cross-doc cascade closure

The Override 6 cascade now has full coverage:

- **A-side:** A's design + A-fix S1 amendments — `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` named explicitly throughout (A-fix §0, §2 V4 Rationale, §2 V4 Dependency, §5 conditional fallback block, OQ-1, §10.2 amendments list).
- **B-side:** B-original + B-fix (§1-§15) + this v2 amendment (§16) — `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` now named throughout; all 5 stale `maintenance-docs/` references retargeted.
- **C-side:** No destination references; no ripple needed.

Phase 5 coder, Phase 4 planner, and Phase 3 reviewer all see a consistent destination (`pack-ops/`) across every architect doc. The cascade is closed.
