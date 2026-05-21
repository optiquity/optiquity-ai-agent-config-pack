# PACK-REVIEW — BD-175 Phase 5 Commit 2 (directory reorg M1-M5 + M9-M10, Option A combined)

**Author:** pack-reviewer
**Date:** 2026-05-19
**Branch:** v11-dev
**Commit reviewed:** `59a7dbb` (parent: `e36d622`)
**Plan:** `maintenance-docs/v11-implementation/PLAN-BD-175-PHASE-5.md` §2.2
**Architects referenced:** B (`ARCHITECTURE-DIRECTORY-REORGANIZATION.md`, `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md`), AUDIT-USER-CURATION overrides 1/5/6/7/8

---

## §0 Executive summary

| Metric | Count |
|---|---|
| Critical surfaces VERIFIED | 9 |
| REMAINING ISSUES | 0 |
| NEW DEFECTS | 4 |
| BLOCKERS | 0 |
| MUSTs | 1 |
| SHOULDs | 2 |
| NITs | 1 |

**Overall verdict: GO for Commit 3 spawn** — Option A mandate honored, all critical surfaces validated, validate-pack PASSES, all spot-checked test suites PASS. The 4 NEW DEFECTS are scoped, fixable in a Commit-2 fix-pass (1 MUST + 2 SHOULDs are broken markdown/prose links in user-facing surfaces; 1 NIT is a residual trinity asymmetry). None of them block downstream Commit 3 (supporting-docs/ → pack-ops/) — they are confined to user-facing prose and one bullet that was not in the planner's enumerated edit list.

Per the calling prompt's "FIX-ALL unless impossible or scheduled in a later commit" default, all 4 NEW DEFECTS are FIXABLE in a Commit-2 fix-pass (estimated 4 edits: README.md L45, QUICKSTART.md L10+L43, pack-ops/HELP-FRAGMENT-PACK.md L4-5+L37+L41-42, plus CLAUDE.md:74 + AGENTS.md:68 trinity-symmetry alignment).

---

## §1 Per-check verdicts

### §1.1 Option A compliance — VERIFIED

- `git log --oneline e36d622..59a7dbb` returns exactly one commit (`59a7dbb`). No Commit 2a / 2b split. Commit message subject names "M1-M5 + M9-M10".
- The 7 root → pack-ops/ relocations are atomic in `59a7dbb`'s diff:
  - `BACKLOG.md => pack-ops/BACKLOG.md` (R100)
  - `CHANGELOG.md => pack-ops/CHANGELOG.md` (R100)
  - `HELP-FRAGMENT-PACK.md => pack-ops/HELP-FRAGMENT-PACK.md` (R100)
  - `HELP-FRAGMENT-TRACKER.md => pack-ops/HELP-FRAGMENT-TRACKER.md` (R100)
  - `OPTIONAL-FEATURES.md => pack-ops/OPTIONAL-FEATURES.md` (R100)
  - `PACK-AGENTS.md => pack-ops/PACK-AGENTS.md` (R100)
  - `PACK-CHAT.md => pack-ops/PACK-CHAT.md` (R100)
- `detect_pack_surface` ambiguity window per M1 finding never opens (single atomic commit).

### §1.2 Rename correctness — VERIFIED

- All 7 renames at `R100` per `git show 59a7dbb -M100% --name-status`. File history preserved (`git log --follow pack-ops/PACK-AGENTS.md` correctly traces through the prior root path's history).
- Renamed-file contents unchanged at the new path. The only file with intra-content edits is `pack-ops/PACK-AGENTS.md` (planner-allowed sibling self-reference judgment in §2.6).

### §1.3 Auto-detection migration — VERIFIED

- `scripts/lib/tracker-config.sh:298` correctly migrated to `[[ -d "$repo_root/pack-ops" ]]` (matches B §3.2 spec).
- `scripts/lib/detect.sh:43` correctly migrates the candidate scan to `pack-ops/BACKLOG.md` first, then `docs/project/BACKLOG.md`, then bare `BACKLOG.md` (legacy fallback retained per planner default §2.2.3 + B-fix §10.3 explicit latitude).
- Functional verification:
  - `bash -c '. scripts/lib/detect.sh && detect_pack_surface .'` → `pack-surface: pack` (PASS).
  - `bash -c '. scripts/lib/tracker-config.sh && tracker_config_auto_surface .'` → `pack` (PASS).
  - `bash -c '. scripts/lib/per-entry/_lib.sh && pe_canonical_mirror_for_stream pack-backlog'` not re-run here but coder reported PASS in IMPL-REPORT §4.6.

### §1.4 validate-pack.py constant updates — VERIFIED

- STREAMS L191-192: `"pack-ops/BACKLOG.md"` + `"pack-ops/CHANGELOG.md"` (correct).
- Check 3 L319: `backlog = REPO_ROOT / "pack-ops" / "BACKLOG.md"` (correct).
- Check 3 L321/332/336 display path: `pack-ops/BACKLOG.md:{i}` (correct).
- Check 22 surfaces dict L1654/1656/1659: pack-ops paths for PACK-CHAT.md, OPTIONAL-FEATURES.md, HELP-FRAGMENT-PACK.md (correct).
- Check 22 tracker_fragment L1669: `pack-ops/HELP-FRAGMENT-TRACKER.md` (correct).
- Check 23 L1735-1736: pack-ops paths for HELP-FRAGMENT-PACK.md + HELP-FRAGMENT-TRACKER.md (correct).
- Check 24 L1929 (byte-identity source): `REPO_ROOT / "pack-ops" / "HELP-FRAGMENT-TRACKER.md"`; client mirror L1930 unchanged (correct).
- L122 docstring + L238 comment: updated to pack-ops paths.
- L849 comment "BACKLOG / archive" left as generic concept reference per coder note (acceptable — not a path consumer).
- **Full run:** `python3 scripts/validate-pack.py` → **PASSED — all checks clean** (35 checks). All Check 3, Check 22, Check 23, Check 24 messages reference pack-ops paths.

### §1.5 Trinity rule compliance — VERIFIED at the 4 planner-scoped sites; NEW DEFECT D-1 below for residual asymmetry

- The 4 planner-enumerated sites are correctly edited in lockstep across `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`:
  - Site 1 (Key files block): CLAUDE.md L30-34 / AGENTS.md L24-28 / GEMINI.md L19-25 — all reference `pack-ops/{BACKLOG,CHANGELOG,PACK-CHAT,PACK-AGENTS}.md`.
  - Site 2 (What agents may modify — CHANGELOG): CLAUDE.md L83 / AGENTS.md L77 / GEMINI.md L53 — all reference `pack-ops/CHANGELOG.md`.
  - Site 3 (What agents must never modify — BACKLOG/PACK-CHAT/PACK-AGENTS): CLAUDE.md L99-102 / AGENTS.md L93-96 / GEMINI.md L57-59 — all reference pack-ops paths.
  - Site 4 (BACKLOG.md has no Resolved section): CLAUDE.md L389 / AGENTS.md L342 / GEMINI.md L317 — all reference `pack-ops/BACKLOG.md`.
- **Defect found** (D-1, NIT): GEMINI.md L47 was updated to `pack-ops/BACKLOG.md` in the "BD numbering" prose, but the parallel sentences in CLAUDE.md:74 + AGENTS.md:68 (bulleted form of the same rule) still say bare `BACKLOG.md`. See §2 below.
- **Pack-* agents trinity** (pack-architect/-coder/-planner across .claude/.codex/.gemini = 9 files) verified by grep — all 9 contain `pack-ops/` paths in their PM-only / read-list / before-reading entries. pack-reviewer and pack-docs-researcher correctly contain no matches (their BACKLOG references are concept-level, not path-level — coder's no-match claim is accurate).
- **Pack-startup skill trinity** (.claude SKILL.md / .codex SKILL.md / .gemini commands toml) — all 3 reference `pack-ops/` in Step 2 instructions, GitHub MCP fallback, and per-entry-tree forward-pointing note.
- **commit-discipline + implementation-report skills** — 3 CLI variants each in lockstep; no bare `BACKLOG.md` / `CHANGELOG.md` references found in any of the 6 files.

### §1.6 pack-ops/PACK-AGENTS.md self-references — VERIFIED

- L142-148 PM-only Files list retains bare names (`BACKLOG.md`, `CHANGELOG.md`, `PACK-CHAT.md`, `PACK-AGENTS.md`) per planner choice (a) — sibling-relative within `pack-ops/`. `README.md` / `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` in the same list are root-resolved by prose context (the list mixes pack-ops-relative and root-relative bare names; this pattern is documented in IMPL-REPORT §2.6).
- L178-187 forward-pointing per-entry-tree note (`/backlog/`, `/changelog/`) UNCHANGED per planner constraint — those references are to per-entry trees that STAY at root.

### §1.7 README.md Repository Layout — VERIFIED (block structure); NEW DEFECT D-2 below for unrelated stale link

- New `pack-ops/` block at L254-263 lists 7 relocated files plus 2 Commit-1 artifacts (`BOUNDARY-DEFINITION.md` + `.boundary-exempt-root.txt`).
- Pack-root section at L265-274 retains: QUICKSTART.md, tracker.toml.pack-example, trinity (CLAUDE/AGENTS/GEMINI), README.md, `.github/ISSUE_TEMPLATE/`, forward-pointing `/backlog/` + `/changelog/` per-entry tree refs. Matches plan §2.2.2 expectation.
- **Defect found** (D-2, SHOULD): README.md L45 has a broken markdown link `[OPTIONAL-FEATURES.md](OPTIONAL-FEATURES.md)` — the file moved to `pack-ops/`. See §2 below.

### §1.8 RC9 manifest regen — VERIFIED

- `test-fixtures/manifest.txt` IS in Commit 2's diff (`git show 59a7dbb -- test-fixtures/manifest.txt` shows the 6-line replacement).
- 3 v11-* SHAs drifted as expected per RC9 (v11-realistic-ot, v11-flat-file, v11-tracker-on — all are pack-side-aware fixtures).
- v10-* rows unchanged (tag-pinned).
- existing-project-mid-dev unchanged (no pack-surface dependency).

### §1.9 Override anchoring — VERIFIED

- **Override 1** (`tracker.toml.pack-example` STAYS): `git show 59a7dbb -- tracker.toml.pack-example` returns empty — file untouched. Confirmed.
- **Override 5** (BACKLOG/CHANGELOG MUST MOVE): both R100 renames present in commit diff. Confirmed.
- **Override 7** (QUICKSTART.md STAYS): `git show 59a7dbb -- QUICKSTART.md` returns empty — file untouched. Confirmed at the file level — but see NEW DEFECT D-3 below for the stale markdown links INSIDE QUICKSTART.md (a planner-omission consequence of Override 7's "no edit" directive intersecting with paths that changed underneath it).

### §1.10 Plan deviations — VERIFIED within latitude

- IMPL-REPORT §7 lists 6 judgment calls; reviewed against B-fix §10.3 latitude scope. All 6 are within the planner's explicit "per-file review by coder" instruction:
  1. detect.sh root-fallback retained — matches planner default in §2.2.3 line 198; coder cited fixture 1.3 ("client repo (root BACKLOG.md, TD entries)") for justification.
  2. pack-help.sh root-fallback for test fixtures — analogous pattern to (1), used for fixture 2.5.
  3. Surface-aware refactors in tracker-doctor/forward/header-snapshot/init — necessary for client-side flows (these libs are bi-surface; hardcoding pack-ops/ would break client surfaces).
  4. 9 test scripts updated for new pack-ops/ marker — necessary because the prior `PACK-CHAT.md` file marker is gone; tests using `prefix = "BD"` would silently fall back to client paths.
  5. pack-ops/PACK-AGENTS.md L143-148 bare-names retained per planner choice (a) — sibling-relative within pack-ops/.
  6. Trinity pack-memory prose left bare per planner's explicit line-scoping (4 enumerated sites only) — but see D-1 below for the residual asymmetry from GEMINI.md L47's edit not matching CLAUDE/AGENTS:74/:68.
- No judgment call exceeds the §10.3 latitude. No files outside the planner's spec were modified.

### §1.11 Coder-claimed verifications — INDEPENDENTLY SPOT-CHECKED

- `python3 scripts/validate-pack.py` → **PASSED — all checks clean**.
- `bash scripts/tests/test-per-entry.sh` → **PASS: 57, FAIL: 0**.
- `bash scripts/pack-help.sh --root .` → produces pack-side fragment (renders from `pack-ops/HELP-FRAGMENT-PACK.md`). NB: the rendered output's "Full docs in `PACK-CHAT.md`, `OPTIONAL-FEATURES.md`" prose is stale — see D-4 below.

---

## §2 Defect classification

### D-1 — Trinity asymmetry at the "BD numbering" rule (NIT)

**Severity:** NIT
**Files affected:**
- `CLAUDE.md:74` (`Read BACKLOG.md, find the highest existing BD-NNN, increment by 1` — bare)
- `AGENTS.md:68` (same bare phrasing)
- `GEMINI.md:47` (`Always read \`pack-ops/BACKLOG.md\` to find the highest existing BD number` — updated)

**Description:** The "BD numbering" rule appears in all three trinity files but with slightly different wording. GEMINI.md L47's prose form WAS updated to `pack-ops/BACKLOG.md` during Commit 2, but the parallel bulleted form in CLAUDE.md:74 and AGENTS.md:68 was NOT updated. This is asymmetric: either all three should reference `pack-ops/BACKLOG.md` or none of them should. The coder's §7.6 judgment-call argues "planner enumerated only 4 sites"; that holds for sites the coder DIDN'T touch, but it does not justify GEMINI.md's L47 edit asymmetry. The simpler fix is to align CLAUDE.md:74 + AGENTS.md:68 to GEMINI.md (i.e., update to `pack-ops/BACKLOG.md`).

**Fix shape (1-line fix):** Edit CLAUDE.md:74 from `Read BACKLOG.md, find the highest existing BD-NNN, increment by 1` → `Read pack-ops/BACKLOG.md, find the highest existing BD-NNN, increment by 1`. Same edit in AGENTS.md:68.

**Schedule:** Commit-2 fix-pass (mechanical, 2 lines).

---

### D-2 — README.md:45 broken link to relocated OPTIONAL-FEATURES.md (SHOULD)

**Severity:** SHOULD
**File:** `README.md:45`

**Description:** README.md line 45 still has `See [\`OPTIONAL-FEATURES.md\`](OPTIONAL-FEATURES.md) for the current list...` — the link target no longer exists at the root (it moved to `pack-ops/OPTIONAL-FEATURES.md`). On GitHub's web view, this link will 404. The pack-repo README is a high-traffic landing surface; broken links here are user-visible.

**Fix shape:** Edit README.md:45 from `See [\`OPTIONAL-FEATURES.md\`](OPTIONAL-FEATURES.md) for the` → `See [\`pack-ops/OPTIONAL-FEATURES.md\`](pack-ops/OPTIONAL-FEATURES.md) for the`.

**Schedule:** Commit-2 fix-pass (mechanical, 1 line). The planner's §2.2.2 list missed this — the README repo-layout block was updated but the prose link in §"Optional features and settings" was not.

---

### D-3 — QUICKSTART.md:10 + QUICKSTART.md:43 broken links to relocated files (MUST)

**Severity:** MUST
**File:** `QUICKSTART.md` lines 10 and 43

**Description:** QUICKSTART.md contains two broken markdown links:
- L10: `\`/pack-help\` — see [\`HELP-FRAGMENT-PACK.md\`](HELP-FRAGMENT-PACK.md).` — target moved to `pack-ops/`.
- L43: `For tracker opt-in (Phase B of the v11 migration), see [\`OPTIONAL-FEATURES.md\`](OPTIONAL-FEATURES.md).` — target moved to `pack-ops/`.

Override 7 mandates "QUICKSTART.md STAYS at root as-is. No SPLIT, no relocation." The Override's spirit is "don't restructure QUICKSTART" — it is NOT a directive to skip updating links that break because OTHER files moved underneath. The planner's §2.2.2 omitted QUICKSTART.md from the edit list, treating Override 7 as a hard untouchable; that interpretation broke 2 markdown links that are now visibly stale on the GitHub landing page and break the documented pack-installer flow ("see HELP-FRAGMENT-PACK.md" returns 404).

**Severity rationale:** MUST not BLOCKER because Commit 3 does not depend on QUICKSTART.md correctness, but the broken links are visible to every prospective pack adopter. SHOULD-vs-MUST tipping point is that QUICKSTART.md is the pre-install pack-installer entry doc (per Override 7 rationale) — stale links here defeat the doc's purpose.

**Fix shape:** Edit QUICKSTART.md:10 to point at `pack-ops/HELP-FRAGMENT-PACK.md`; edit L43 to point at `pack-ops/OPTIONAL-FEATURES.md`. No structural change to QUICKSTART; only the 2 link targets update. This honors Override 7's intent (don't move/restructure QUICKSTART) while keeping the file functional.

**Schedule:** Commit-2 fix-pass (mechanical, 2 lines).

---

### D-4 — pack-ops/HELP-FRAGMENT-PACK.md user-facing prose still names bare-root paths (SHOULD)

**Severity:** SHOULD
**File:** `pack-ops/HELP-FRAGMENT-PACK.md` lines 4-5, 37, 41-42

**Description:** When a user runs `pack help` or `/pack-help` in the pack repo, the rendered output contains:
- L4-5: `Full docs in \`QUICKSTART.md\`, \`README.md\`, \`PACK-CHAT.md\`, \`OPTIONAL-FEATURES.md\`.` — three of four names point at files that have moved (only `QUICKSTART.md` and `README.md` are still at root; `PACK-CHAT.md` and `OPTIONAL-FEATURES.md` are at `pack-ops/`).
- L37: `[Included from \`HELP-FRAGMENT-TRACKER.md\` at pack root via \`pack-help.sh\`.]` — wording is now stale; it's at `pack-ops/HELP-FRAGMENT-TRACKER.md`.
- L41-42 "See also": `\`PACK-CHAT.md\`, \`PACK-AGENTS.md\`, \`OPTIONAL-FEATURES.md\`, \`BACKLOG.md\`, \`CHANGELOG.md\`.` — all 5 names are stale.

This is verb-output prose that is printed to the user (pack-side fragment). The planner's §2.2.2 listed validate-pack.py / scripts / trinity / agents / skills / PACK-AGENTS.md self-refs but did NOT enumerate HELP-FRAGMENT-PACK.md content updates. The `git mv` preserved the file but did not update its content.

**Why SHOULD not MUST:** The HELP-FRAGMENT prose is documentation, not a tested invariant. Check 22 (verb-name-presence-in-fragment) still passes because the VERB NAMES are listed — Check 22 doesn't audit the "Full docs in" line. Plain prose drift is recoverable.

**Fix shape:** Edit lines 4-5, 37, 41-42 in `pack-ops/HELP-FRAGMENT-PACK.md` to use `pack-ops/<file>` paths. Trinity-symmetric edit also needed in `project-template/docs/pack/HELP-FRAGMENT.md` IF Check 24 byte-identity is affected — verified above (Check 24 only audits HELP-FRAGMENT-TRACKER, not HELP-FRAGMENT-PACK; the project-side HELP-FRAGMENT.md is a separate file).

**Schedule:** Commit-2 fix-pass (mechanical, ~5 lines).

---

## §3 Critical surfaces audit

### §3.1 Option A compliance — PASS (load-bearing for all downstream commits)

The Option A mandate is the load-bearing constraint M1 surfaced — splitting M9/M10 from M1-M5 would open the `detect_pack_surface` ambiguity window. Commit 2 honors the mandate: single atomic commit, 7 renames + all path-reference updates in one git state. No further per-commit guard is needed for Commits 3-10 (they don't share this constraint), but the Option A discipline must be visible in the audit chain — confirmed via `git log` showing exactly one commit between e36d622 and HEAD.

### §3.2 Rename correctness — PASS

All 7 renames at `R100` similarity. `git log --follow` traces correctly. This is critical because file history preservation enables `git blame` / `git log <file>` to work across the move boundary — downstream BD work that references "BACKLOG.md L NNN at commit Y" can still resolve those references via `--follow` semantics.

### §3.3 Auto-detection migration — PASS (load-bearing for surface-aware libs)

The `tracker-config.sh:298` change to `[[ -d pack-ops ]]` and `detect.sh:43` first-candidate `pack-ops/BACKLOG.md` are both functionally verified. These are the two CRITICAL auto-detection signals — every tracker subcommand depends on `tracker_config_auto_surface` returning the correct surface, and every pack-help / pack-startup invocation depends on `detect_pack_surface`. Both return correct results on the post-Commit-2 pack repo state. The retained legacy root fallback in detect.sh (3rd candidate) was the documented planner default and is justified by fixture 1.3.

### §3.4 validate-pack.py constants — PASS

All plan-§2.2.2-enumerated lines are correctly updated:
- L191-192 (STREAMS) ✓
- L319 (Check 3 backlog path) ✓
- L1654/1656/1659 (Check 22 surfaces dict) ✓
- L1669 (Check 22 tracker_fragment) ✓
- L1735-1736 (Check 23) ✓
- L1929 (Check 24 byte-identity source) ✓
- L122/238 (docstring + comment) ✓

The full `validate-pack.py` run PASSES 35/35 checks. Check 22 explicitly emits `pack-root: 11 prose-referenced verb(s) all present in fragment (pack-ops/HELP-FRAGMENT-PACK.md)`; Check 24 emits `pack-ops/HELP-FRAGMENT-TRACKER.md byte-identical to project-template/docs/pack/HELP-FRAGMENT-TRACKER.md (DELTA L1)`. The constant updates are load-bearing for CI green-light on push.

---

## §4 PREFLIGHT

PREFLIGHT: 11/11 review checklist sections covered (Option A compliance, rename correctness, auto-detection migration, validate-pack constants, trinity rule, pack-ops/PACK-AGENTS.md self-refs, README.md repo-layout, RC9 manifest regen, override anchoring, plan deviations, coder-claimed verifications); independent functional verification PASS (validate-pack 35/35, test-per-entry 57/57, detect_pack_surface returns pack, tracker_config_auto_surface returns pack); HEAD `59a7dbb`; about to Write report to `maintenance-docs/v11-implementation/PACK-REVIEW-BD-175-COMMIT-2.md`.
