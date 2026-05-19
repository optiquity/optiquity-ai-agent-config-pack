# IMPLEMENTATION-REPORT-BD-175-F4-BUNDLE

**Branch:** `v11-dev`
**HEAD at start:** `f5b3998e2944dbee7ba7941e4a607ba9d98bfb32` (Commit 12)
**HEAD at end (worktree, no state-changing git verbs run):** `f5b3998e2944dbee7ba7941e4a607ba9d98bfb32`
**Scope:** BD-175 F4 BUNDLE — mechanical Pattern B → Pattern A consolidation for `boundary-investigation` skill, AND POQ-F4-1 (validate-pack.py allowlist update) AND POQ-F4-2 (PLATFORM-SKILLS.md Tier 0 inventory registration). Single bundled commit prevents landing a known-CI-red intermediate commit per user direction.
**Driver:** Post-Commit-12 CI red. Greenfield persona contract failed on skill count (Pattern B copies were never installed by `stage_s4_skills()`). F4 mechanical work alone unblocks greenfield but cascades into 30 validate-pack.py failures (28 Check 37 deny-list + 1 orphan SKILL.md + 1 manifest delta) — POQ-F4-1 + POQ-F4-2 close the cascade and turn CI fully green.

---

## §1 Summary

F4 mechanically relocates the project-side `boundary-investigation` skill from three byte-identical CLI-specific files (Pattern B: `project-template/.{claude,codex,gemini}/skills/boundary-investigation/SKILL.md`) to a single canonical Pattern A source (`project-template/skills/boundary-investigation/SKILL.md`). The Pattern A source auto-distributes to all three CLI install paths in any client repo via `stage_s4_skills()` in `scripts/init-project.sh:484-507` — the convention used by 30+ existing skills (`api-design`, `architecture-review`, `debugging`, `planning`, `python-best-practices`, `repo-ops`, `review`, `swift-best-practices`, etc.). Content is moved verbatim — 186 lines, byte-identical to the deleted Pattern B sources.

The F4 mechanical move triggers two downstream cascade failures that POQ-F4-1 and POQ-F4-2 resolve in the same commit:

- **POQ-F4-1 (validate-pack.py allowlist):** Check 37 (project-side pack-only deny-list) holds an explicit allowlist of files whose whole purpose is to *teach* the deny-list. The Pattern B paths were on the allowlist; the new Pattern A path is not. This commit replaces the 3 Pattern B entries with the 1 Pattern A entry and updates surrounding docstring / comment text to match the new single-file reality. Closes 28 Check-37 FAIL lines.
- **POQ-F4-2 (PLATFORM-SKILLS.md Tier 0 registration):** The orphan-SKILL.md check (`scripts/validate-pack.py:2773-2781`) walks `project-template/skills/*/SKILL.md` and requires every file there to be enumerated in one of PLATFORM-SKILLS.md's inventory subsections. Pattern B locations were silently exempt (the check never scanned them); Pattern A is not. This commit adds `boundary-investigation` to the Tier 0 base skills table (both the Step 1 "Tier 0 — Base skills" matrix and the Full skill inventory "Tier 0 base skills" table), updates the `(13)` headers to `(14)`, and updates the `Total skills: 35` line to `Total skills: 36`. User-approved Tier 0 placement (boundary-investigation is loaded by all 5 pack-* agents per `pack-ops/PACK-AGENTS.md:36`; the project-side analog is universally applicable to architect/coder/planner/reviewer/docs-researcher). Closes 1 orphan FAIL line.

POQ-F4-3 (editorial trinity note about Tier 0 base loading) is explicitly DEFERRED to BD-178 per user direction — NOT in this commit's scope.

**Outcome:** all 3 persona contracts PASS (greenfield 191/0, mid-dev 25/0, migration 37/0); `python3 scripts/validate-pack.py` exits 0 with all checks clean. The migration contract was the previously-red one on F4-only (validate-pack exit-1 cascaded into the migrator's verification gate); it now passes.

---

## §2 Files changed (inventory)

| Path | Action | Rationale | Scope tag |
|---|---|---|---|
| `project-template/skills/boundary-investigation/SKILL.md` | NEW (186 lines) | Pattern A canonical source; auto-distributes via `stage_s4_skills()` | F4 mechanical |
| `project-template/.claude/skills/boundary-investigation/SKILL.md` | DELETED | Pattern B duplicate; never installed by S4 | F4 mechanical |
| `project-template/.claude/skills/boundary-investigation/` | DELETED (dir) | Empty after file delete | F4 mechanical |
| `project-template/.codex/skills/boundary-investigation/SKILL.md` | DELETED | Pattern B duplicate; never installed by S4 | F4 mechanical |
| `project-template/.codex/skills/boundary-investigation/` | DELETED (dir) | Empty after file delete | F4 mechanical |
| `project-template/.gemini/skills/boundary-investigation/SKILL.md` | DELETED | Pattern B duplicate; never installed by S4 | F4 mechanical |
| `project-template/.gemini/skills/boundary-investigation/` | DELETED (dir) | Empty after file delete | F4 mechanical |
| `project-template/.gemini/skills/` | DELETED (dir) | Empty parent; created by Commit 12 only to hold this skill | F4 mechanical |
| `scripts/validate-pack.py` | MODIFIED | Allowlist: 3 Pattern B paths → 1 Pattern A path; docstring + walker comment updated to match | POQ-F4-1 |
| `project-template/docs/pack/PLATFORM-SKILLS.md` | MODIFIED | Tier 0 inventory: add `boundary-investigation` row in 2 tables; update `(13)` → `(14)` × 2 + `Total skills: 35` → `36` × 1 | POQ-F4-2 |
| `test-fixtures/manifest.txt` | MODIFIED | RC9 regen — 3 v11-* SHAs updated; v10-* + existing-* unchanged | manifest hygiene |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-F4.md` | DELETED | Prior coder pass's F4-only IMPL-REPORT; superseded by THIS bundle report (the F4-only intermediate state never lands as a commit) | doc cleanup |

**Note on `.gemini/skills/` parent dir.** This directory did not exist in v11-dev prior to Commit 12. Commit 12 created it solely to hold the Pattern B `boundary-investigation/` subdirectory. After F4, removing the empty parent restores the pre-Commit-12 directory tree and avoids two downstream issues:
1. Greenfield contract's per-CLI extras scanner uses `set -uo pipefail`; an empty array from a present-but-empty `project-template/.gemini/skills/` dir triggered `unbound variable cli_extras_list[@]` (script bug — pre-existing fragility surfaced by the dir becoming empty).
2. `git ls-files project-template/.gemini/` shows no tracked file under `skills/`; git doesn't track empty dirs.

---

## §3 F4 mechanical work (summary; cites superseded prior IMPL-REPORT)

The F4 mechanical Pattern B → Pattern A move was performed by a prior pack-coder session and committed to the working tree (NOT to git history) before this bundle pass began. That prior session's IMPL-REPORT (`maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-F4.md`) was DELETED in this bundle pass — it represented an intermediate state that intentionally never lands as a discrete commit. The full F4 mechanical content (byte-identity verification, manifest regen evidence, F4-scope success criteria) was preserved across the supersession; the relevant content was carried forward into this bundle report's §2 / §3 / §6 / §10.

**F4 pre-existing working-tree state (verified at start of this session):**
- NEW: `project-template/skills/boundary-investigation/SKILL.md` (186 lines)
- DELETED: 3 Pattern B `SKILL.md` files (verified via `git status --short` showing 3 `D` lines)
- DELETED: 3 Pattern B parent dirs + 1 `.gemini/skills/` grandparent
- MODIFIED: `test-fixtures/manifest.txt` (RC9 partial regen — re-regenerated in this pass to capture POQ-F4-1 + POQ-F4-2 deltas)

**Pattern A vs Pattern B (background for future readers):**

| | Pattern A — canonical/generic single-source | Pattern B — CLI-specific separate files |
|---|---|---|
| Layout | `project-template/skills/<name>/SKILL.md` (1 file per skill) | `project-template/.{claude,codex,gemini}/skills/<name>/` (3 files per skill) |
| Install | `stage_s4_skills()` auto-iterates and copies to all 3 CLI install paths | Explicit per-skill blocks in `stage_s11_v11_artifacts()` |
| Used by | 30+ existing byte-identical-across-CLIs skills | Skills with genuine per-CLI content variation (`pack-help`, `pm-startup`) |
| Sync burden | Zero | Three byte-identical files to keep in sync |

**Why F4 is correct for `boundary-investigation`:** Architect C's design produces byte-identical content across all three CLIs (verified pre-F4: `diff` exit code 0 across all three pairs). When content is byte-identical, Pattern A is the canonical choice — it is zero-overhead and the convention every other byte-identical-across-CLIs skill follows.

---

## §4 POQ-F4-1 implementation (validate-pack.py allowlist edit)

**Location:** `scripts/validate-pack.py` — function `_is_legitimate_deny_list_doc` (allowlist) + surrounding docstring (around lines 3897-3946) + walker comment (around lines 3886-3893).

**Before (3 Pattern B entries):**

```python
    rel_str = str(rel_path)
    legitimate = (
        # Boundary-investigation skill files (project-side).
        "project-template/.claude/skills/boundary-investigation/SKILL.md",
        "project-template/.codex/skills/boundary-investigation/SKILL.md",
        "project-template/.gemini/skills/boundary-investigation/SKILL.md",
```

**After (1 Pattern A entry):**

```python
    rel_str = str(rel_path)
    legitimate = (
        # Boundary-investigation skill (project-side, Pattern A canonical
        # single source — auto-distributed via stage_s4_skills() to all
        # three CLI install paths at client install time).
        "project-template/skills/boundary-investigation/SKILL.md",
```

**Two supporting edits in the same function/walker (to keep prose consistent with the new single-file reality):**

1. **Docstring "Specific exemptions" block** (now reads):

   ```text
   - The `boundary-investigation` skill (Pattern A canonical single
     source at `project-template/skills/boundary-investigation/SKILL.md`,
     auto-distributed to all three CLI install paths via
     `stage_s4_skills()` at client install time) — its purpose is to
     teach the deny-list, so the entries appear as instructional
     content.
   ```

2. **`_iter_project_side_files()` walker comment** (now reads):

   ```text
   # Skip dotted-dir agents/skills/commands fixtures — actually
   # those ARE in scope (skills like boundary-investigation
   # carry the deny-list legitimately as instructional content
   # via the Pattern A canonical source at
   # project-template/skills/boundary-investigation/SKILL.md;
   # that's why we use the anchor-phrase + per-skill exception
   # lists below). No skip here — all project-template/ files
   # are scanned (including .claude/.codex/.gemini extras).
   ```

**Cascade-failure resolution:** Before the edit, `python3 scripts/validate-pack.py` produced 28 FAIL lines from Check 37 (project-side pack-only deny-list), all of the form `project-template/skills/boundary-investigation/SKILL.md:LINE — references pack-only X (...); no LEGITIMATE-context anchor in window.` The file's content has not changed — only its path; the validator's allowlist is path-keyed; the new path was not allowlisted. After the edit, Check 37 reports `OK: Check 37 — 146 project-side file(s) walked; zero deny-list contamination (0 anchored LEGITIMATE-context hit(s) accepted)`.

---

## §5 POQ-F4-2 implementation (PLATFORM-SKILLS.md Tier 0 entry + counts)

**Location:** `project-template/docs/pack/PLATFORM-SKILLS.md` — 4 distinct edit sites.

**Edit site 1: Step 1 "Tier 0 — Base skills" table (around line 191-205)** — added `boundary-investigation` row alphabetically (between `architecture-review` and `debugging`):

```markdown
| boundary-investigation | Project-side SSOT investigation methodology; flag pack-vs-project boundary violations on every action |
```

**Edit site 2: Step 1 "13 Tier 0 base skills" callout (line 207)** — updated count:

- Before: `**13 Tier 0 base skills.**`
- After: `**14 Tier 0 base skills.**`

**Edit site 3: Full skill inventory "Tier 0 base skills (13)" subsection (line 418)** — updated header count + added row alphabetically (between `architecture-review` and `debugging`):

- Header before: `### Tier 0 base skills (13)`
- Header after: `### Tier 0 base skills (14)`

New row added in the same subsection (with the "Primary agents" column that the Full inventory table has but the Step-1 table doesn't):

```markdown
| boundary-investigation | Project-side SSOT investigation methodology; flag pack-vs-project boundary violations on every action | architect, coder, planner, reviewer, docs-researcher |
```

**Edit site 4: "Total skills: 35" line (line 496)** — updated total + Tier 0 count:

- Before: `**Total skills: 35** (13 Tier 0 base + 20 dimensional / intersection + 1 trigger-loaded + 1 PM chat operational).`
- After: `**Total skills: 36** (14 Tier 0 base + 20 dimensional / intersection + 1 trigger-loaded + 1 PM chat operational).`

**Tier 0 placement rationale:** User-approved at the bundle-triage gate. The pack-side equivalent at `pack-ops/PACK-AGENTS.md:36` lists all five pack-* agents as users of `boundary-investigation`; the project-side analog is universally applicable to `architect`, `coder`, `planner`, `reviewer`, `docs-researcher` (and any other Tier-0-filtering agent that the per-agent Step 2 assignments select). The "Primary agents" column in the Full inventory table reflects this 5-agent universality.

**Orphan-FAIL resolution:** Before the edit, `python3 scripts/validate-pack.py` produced:

```text
FAIL: PLATFORM-SKILLS.md — orphan SKILL.md: project-template/skills/boundary-investigation/SKILL.md exists on disk but is not listed in any Full skill inventory subsection
```

After the edit, the orphan check passes (verified by full validate-pack.py run exit 0 in §7).

---

## §6 All 3 persona contracts result

```text
$ bash scripts/persona-contracts/contract-greenfield.sh 2>&1 | tail -1
=== greenfield contract: 191 passed, 0 failed ===

$ bash scripts/persona-contracts/contract-mid-dev.sh 2>&1 | tail -1
=== mid-dev contract: 25 passed, 0 failed ===

$ bash scripts/persona-contracts/contract-migration.sh 2>&1 | tail -1
=== migration contract: 37 passed, 0 failed ===
```

All 3 personas PASS. The migration contract was the previously-RED persona on F4-only (validate-pack exit-1 cascaded into the migrator's verification gate via `_install_v11_files()` → final `validate-pack.py` exit-status check); the cascade is now fully resolved by POQ-F4-1 + POQ-F4-2.

---

## §7 validate-pack.py full run output (all checks PASS)

```text
$ python3 scripts/validate-pack.py 2>&1 | tail -15
  OK: scripts/lib/tracker-phase-task.sh present
  OK: scripts/lib/tracker-labels.sh — no tracker_labels_folded_into helper definition (Path 3 forbidden)
  OK: scripts/lib/ — no `folded-into` literal in executable code (V3.3 §3 line 27); comment-only references allowed

── Check 36: Commit-scope honesty (BD-175, M5a) ──
  OK: Check 36 — 0 scope-claiming commit(s) verified clean; 1 implicit-scope commit(s) skipped

── Check 37: Project-side pack-only deny-list (BD-175, M5b) ──
  OK: Check 37 — 146 project-side file(s) walked; zero deny-list contamination (0 anchored LEGITIMATE-context hit(s) accepted)

── Check 38: Pack-only-file siting (BD-175, M5c) ──
  OK: Check 38 — 1 pack-root prose file(s) checked; no pack-only content mis-sited outside `pack-ops/`. Exemption list: ['tracker.toml.pack-example'].

============================================================
PASSED — all checks clean

$ echo $?
0
```

All 38 checks pass; exit 0 confirmed.

---

## §8 Manifest regen evidence

```text
$ bash test-fixtures/build.sh --all --clean 2>&1 | tail -20
... (output: 4 fixtures rebuilt; manifest written)
manifest written: /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/test-fixtures/manifest.txt

$ git diff test-fixtures/manifest.txt
diff --git a/test-fixtures/manifest.txt b/test-fixtures/manifest.txt
index 501bad7..c8690d9 100644
--- a/test-fixtures/manifest.txt
+++ b/test-fixtures/manifest.txt
@@ -4,7 +4,7 @@
 #
 v10-minimal  19558cbac58ed3e47642a6bbe64418a38c60bc16
 v10-realistic-ot  4c62945f72b037908b38967d5d8f019745263258
-v11-realistic-ot  b77a7785c0043a85cc09b0a05a94eef46359101c
-v11-flat-file  5909367a72c77fff66ccd71f6cc2db163309294d
-v11-tracker-on  54951dd0742612923e7c17820b31701deb9f7961
+v11-realistic-ot  50940281c243f28c8ff755f5fd2361c5c63340b8
+v11-flat-file  8a6a2d05bf285f178335c9f13b0636a2c1e10b98
+v11-tracker-on  11bc0a3ac70b3fe8cdd64d353f3381e0ad4e953d
 existing-project-mid-dev  a54e081a9e1d04f293bfb38fa0af77fd9f7f8619
```

Expected shape (RC9 trinity rule): 3 v11-* rows updated, v10-* + existing-* rows unchanged. Confirmed. The v11-* SHAs differ from the F4-only manifest (re-regen captures the additional POQ-F4-2 PLATFORM-SKILLS.md changes propagating into all three v11-* fixtures; the v11-realistic-ot fixture's per-entry tree regen via project-implementation-plan / project-changelog decomposition is also reflected).

---

## §9 Verification command output (final pre-PREFLIGHT sweep)

```text
$ git rev-parse HEAD
f5b3998e2944dbee7ba7941e4a607ba9d98bfb32

$ git status --short
 D project-template/.claude/skills/boundary-investigation/SKILL.md
 D project-template/.codex/skills/boundary-investigation/SKILL.md
 D project-template/.gemini/skills/boundary-investigation/SKILL.md
 M project-template/docs/pack/PLATFORM-SKILLS.md
 M scripts/validate-pack.py
 M test-fixtures/manifest.txt
?? project-template/skills/boundary-investigation/

$ ls project-template/skills/boundary-investigation/
SKILL.md

$ ls project-template/.claude/skills/
pack-help
pm-startup

$ ls project-template/.codex/skills/
pack-help
pm-startup

$ ls project-template/.gemini/
agents
commands
settings.json
# (skills/ removed — was empty after F4)

$ grep -n "boundary-investigation" scripts/validate-pack.py
168:      legitimate-documentation files (boundary-investigation skill,
3888:            # those ARE in scope (skills like boundary-investigation
3891:            # project-template/skills/boundary-investigation/SKILL.md;
3906:      - **Boundary-discipline teaching docs:** the `boundary-investigation`
3922:        "project-template/skills/boundary-investigation/SKILL.md",
3962:      - The `boundary-investigation` skill (Pattern A canonical single
3963:        source at `project-template/skills/boundary-investigation/SKILL.md`,

$ grep -n "boundary-investigation\|Tier 0 base skills\|Total skills" project-template/docs/pack/PLATFORM-SKILLS.md
195:| boundary-investigation | Project-side SSOT investigation methodology; flag pack-vs-project boundary violations on every action |
208:**14 Tier 0 base skills.** Several of these were classified as "Tier 1
316:For each agent prompt, load the agent's Tier 0 base skills plus the
419:### Tier 0 base skills (14)
429:| boundary-investigation | Project-side SSOT investigation methodology; flag pack-vs-project boundary violations on every action | architect, coder, planner, reviewer, docs-researcher |
498:**Total skills: 36** (14 Tier 0 base + 20 dimensional / intersection + 1 trigger-loaded + 1 PM chat operational).

$ ls maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-F4.md
ls: maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-F4.md: No such file or directory
# (deleted — superseded by this bundle IMPL-REPORT)
```

---

## §10 PREFLIGHT line (paste exactly)

```
PREFLIGHT: 6/6 in-scope file edits complete (F4: 1 new SKILL.md + 3 deleted Pattern B + empty parents removed; POQ-F4-1: validate-pack.py allowlist + 2 doc/comment updates; POQ-F4-2: PLATFORM-SKILLS.md Tier 0 entry + 3 count updates; manifest regen; prior IMPL-REPORT deleted); verification PASS (validate-pack exit 0, greenfield 191/0, mid-dev 25/0, migration 37/0); HEAD f5b3998e2944dbee7ba7941e4a607ba9d98bfb32; about to Write IMPL-REPORT to /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-F4-BUNDLE.md
```

---

## §11 Definition-of-Done checklist

Success criteria from the prompt:

| Criterion | Status | Evidence |
|---|---|---|
| F4 mechanical state preserved (4 file ops from prior coder pass still present) | PASS | §9 ls outputs + git status |
| POQ-F4-1: `scripts/validate-pack.py` allowlist updated (1 Pattern A entry; 0 Pattern B entries) | PASS | §4 before/after quote + §9 grep |
| POQ-F4-2: PLATFORM-SKILLS.md lists `boundary-investigation` in Tier 0 + counts updated | PASS | §5 4-edit detail + §9 grep |
| `test-fixtures/manifest.txt` regenerated; 3 v11-* row updates | PASS | §8 git diff |
| `python3 scripts/validate-pack.py` exit 0 | PASS | §7 |
| greenfield persona contract PASS | PASS | §6 (191/0) |
| mid-dev persona contract PASS | PASS | §6 (25/0) |
| migration persona contract PASS | PASS | §6 (37/0) — was RED on F4-only |
| Prior F4 IMPL-REPORT deleted | PASS | §9 final ls confirms `No such file or directory` |
| New bundle IMPL-REPORT exists at prompt-specified path | PASS | this file at `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-F4-BUNDLE.md` |
| No state-changing git verbs run | PASS | Only `git rev-parse`, `git status`, `git diff` used (read-only) |
| PREFLIGHT line emitted before IMPL-REPORT write | PASS | §10 + emitted to chat |

**All success criteria: PASS.**

---

## §12 Plan deviations

**Zero scope deviations.** The bundle includes exactly the three pieces the prompt specified (F4 mechanical work preservation + POQ-F4-1 + POQ-F4-2) and nothing more. Out-of-scope items the prompt explicitly listed as NOT TO TOUCH (POQ-F4-3 trinity editorial deferral to BD-178; pack-side `.claude/skills/`, `.codex/skills/`, `.gemini/skills/` at pack root; trinity files at pack root and project-template; `pack-ops/PACK-AGENTS.md`; F1/F2a/F3 work) were not modified — confirmed by `git status --short` showing none of those paths.

The prompt's path for persona-contract scripts (`scripts/tests/personas/`) did not exist in this repo; the actual path is `scripts/persona-contracts/`. This is a prompt-vs-reality mismatch, not a scope deviation — the contracts were located by `find` and run successfully at the correct path. The IMPL-REPORT documents the actual path used.

---

## §13 New POQs introduced

**Zero new POQs.** All known POQs (F4-1, F4-2, F4-3) were already surfaced by the prior F4-only IMPL-REPORT. This bundle closes F4-1 and F4-2; F4-3 remains the existing pre-surfaced item deferred to BD-178 per user direction.

---

## §14 Files-changed-by-tool summary

**Files created (2):**
- `project-template/skills/boundary-investigation/SKILL.md` (186 lines, byte-identical to deleted Pattern B sources — F4 mechanical, from prior coder pass)
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-F4-BUNDLE.md` (this file — bundle IMPL-REPORT)

**Files deleted (4):**
- `project-template/.claude/skills/boundary-investigation/SKILL.md` (F4 mechanical)
- `project-template/.codex/skills/boundary-investigation/SKILL.md` (F4 mechanical)
- `project-template/.gemini/skills/boundary-investigation/SKILL.md` (F4 mechanical)
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-F4.md` (superseded by this bundle IMPL-REPORT)

**Directories deleted (4, empty after file-level deletions):**
- `project-template/.claude/skills/boundary-investigation/`
- `project-template/.codex/skills/boundary-investigation/`
- `project-template/.gemini/skills/boundary-investigation/`
- `project-template/.gemini/skills/` (empty parent — was created by Commit 12 only for this skill)

**Files modified (3):**
- `scripts/validate-pack.py` (POQ-F4-1: allowlist + docstring + walker comment)
- `project-template/docs/pack/PLATFORM-SKILLS.md` (POQ-F4-2: Tier 0 entry × 2 tables + counts × 3 sites)
- `test-fixtures/manifest.txt` (RC9 regen — 3 v11-* SHAs updated)

**Files explicitly NOT modified (per prompt):**
- Pack-side skill files at `.claude/skills/boundary-investigation/`, `.codex/skills/boundary-investigation/`, `.gemini/skills/boundary-investigation/` (at pack root) — UNCHANGED; pack-repo agents continue to use these per `pack-ops/PACK-AGENTS.md:36`
- Trinity files (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md` at pack root and at `project-template/`) — UNCHANGED; POQ-F4-3 trinity work deferred to BD-178
- `pack-ops/PACK-AGENTS.md` — UNCHANGED (already correctly references pack-side skill)
- `scripts/init-project.sh` — UNCHANGED (Pattern A auto-distribute via `stage_s4_skills()` already works without modification)
- F1 / F2a / F3 work — separate commits, NOT in this bundle

---

## §15 Cross-references

- Commit 12 (`f5b3998`) — `feat: v11 — BD-175 prevention mechanisms (Architect C M1-M8)` — original Pattern B placement that this bundle corrects
- `scripts/init-project.sh:484-507` — `stage_s4_skills()` auto-install loop (Pattern A consumer)
- `scripts/init-project.sh:855-871` — `stage_s11_v11_artifacts()` Pattern B explicit-install logic for `pack-help` (template for future genuine-CLI-variation skills)
- `scripts/persona-contracts/contract-greenfield.sh:81-130` — skill count + presence assertions (the test that F4 was scoped to fix)
- `scripts/persona-contracts/contract-migration.sh` — migrator persona that was RED on F4-only due to validate-pack exit-1 cascade
- `scripts/validate-pack.py` — `_is_legitimate_deny_list_doc()` allowlist (POQ-F4-1 surface, edited in this bundle); `check_platform_skills_inventory()` orphan check around line 2773-2781 (POQ-F4-2 surface, resolved by adding the Tier 0 inventory row in this bundle)
- `project-template/docs/pack/PLATFORM-SKILLS.md` — Full skill inventory (POQ-F4-2 target, edited in this bundle)
- Pack-side skill (unchanged): `.claude/skills/boundary-investigation/SKILL.md`, `.codex/skills/boundary-investigation/SKILL.md`, `.gemini/skills/boundary-investigation/SKILL.md` (at pack root) — loaded by pack agents per `pack-ops/PACK-AGENTS.md:36`
- BD-178 — anchor for POQ-F4-3 (editorial trinity note about Tier 0 base loading)
