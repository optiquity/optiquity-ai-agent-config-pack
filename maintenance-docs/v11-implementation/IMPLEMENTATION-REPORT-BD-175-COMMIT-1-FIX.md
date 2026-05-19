# IMPLEMENTATION-REPORT — BD-175 Phase 5 Commit 1 fix-pass

**Branch.** `v11-dev`
**HEAD.** `2d68262d29e1de2d26b10522d61c713a056c04d3` (unchanged — this fix-pass produces working-tree edits only; Pack Chat owns the commit).
**Reviewer source.** `maintenance-docs/v11-implementation/PACK-REVIEW-BD-175-COMMIT-1.md` §1.13 (SHOULD) + §1.15 (NIT).
**Files modified.** 1 — `pack-ops/BOUNDARY-DEFINITION.md`.

---

## §1 Summary

Two fixes applied per the user's FIX-ALL triage on reviewer findings §1.13 (SHOULD — forward-pointing prose without "(post-Commit N location)" hedge in §6.1 and §7.7) and §1.15 (NIT — source-citation off-by-one on line 5). Both fixes are surgical edits to `pack-ops/BOUNDARY-DEFINITION.md`. No other file touched. Line count grew from 253 → 255 (still within the plan's 250-350 target). Validate-pack PASSES with all 35 checks clean.

The reviewer's §1.11 finding (IMPL-REPORT alongside in-scope files) was triaged as NO-FIX (acceptable pattern per pack memory) and is not addressed here.

---

## §2 Fix 1 (§1.13 SHOULD) — forward-pointing hedges in §6.1 + §7.7

### §2.1 §6.1 — pack-ops/PACK-* path references

**Reviewer finding wording.** "§6.1 lines 168-171: references to `pack-ops/PACK-CHAT.md`, `pack-ops/PACK-AGENTS.md`, project-side `pack-ops/` qualifier — all forward-pointing (the files won't be in `pack-ops/` until Commit 2 lands)."

**Approach.** Match §7.2's existing hedge pattern (`(post-Commit 2 location; pre-Commit 2 was at pack root)`). Added an inline "post-Commit 2 location" qualifier per bullet AND a leading paragraph that announces the convention for the whole subsection, since §6.1 references two pack-ops/ paths.

**BEFORE (lines 166-169 at HEAD `2d68262`):**

```
### §6.1 Active operating docs (top-of-file pointer)

- `pack-ops/PACK-CHAT.md` — top section "Boundary rules: see `BOUNDARY-DEFINITION.md`". Pack Chat reads PACK-CHAT.md at startup; this is the most consequential pointer.
- `pack-ops/PACK-AGENTS.md` — top section pointer. Every pack agent that reads PACK-AGENTS.md gets the pointer.
```

**AFTER (lines 166-171 in amended doc):**

```
### §6.1 Active operating docs (top-of-file pointer)

The `pack-ops/PACK-*.md` paths below reflect the post-Commit 2 location (after BD-175 Phase 5 Commit 2 relocates these files from pack root); pre-Commit 2, they live at pack root.

- `pack-ops/PACK-CHAT.md` (post-Commit 2 location) — top section "Boundary rules: see `BOUNDARY-DEFINITION.md`". Pack Chat reads PACK-CHAT.md at startup; this is the most consequential pointer.
- `pack-ops/PACK-AGENTS.md` (post-Commit 2 location) — top section pointer. Every pack agent that reads PACK-AGENTS.md gets the pointer.
```

Net: +2 lines (the new leading paragraph + blank line).

### §2.2 §7.7 — V1-removal narrative recast as future-conditional

**Reviewer finding wording.** "§7.7 line 249: 'The reference was removed from project trinity in Phase 5 of BD-175. The project trinity now contains only PROJECT × OPERATIONS pointers...' — this is past-tense but at HEAD `2d68262`, `project-template/CLAUDE.md:366` STILL references `PACK-AGENTS.md` (V1 contamination intact). The V1 removal lands in Commit 4 (TASK-T1 trinity REPLACE), not Commit 1."

**Approach.** Recast the past-tense narrative as future-conditional naming Commit 4 explicitly, then add the post-Commit 4 state as a follow-on sentence. Closing sentence ties back to "what §3's procedure would have flagged" so the example remains pedagogically intact.

**BEFORE (line 249 at HEAD `2d68262`):**

```
- **Resolution applied to this specific failure.** The reference was removed from project trinity in Phase 5 of BD-175. The project trinity now contains only PROJECT × OPERATIONS pointers (e.g., `docs/pack/PM-CHAT.md`); pack-side pointers belong in pack trinity, not project trinity.
```

**AFTER (line 251 in amended doc):**

```
- **Resolution applied to this specific failure.** Commit 4 of BD-175 Phase 5 (TASK-T1 trinity REPLACE) will remove the contamination from project trinity; the V1 reference at `project-template/CLAUDE.md` and its AGENTS.md / GEMINI.md parallels is still present at the HEAD where this doc first landed (BD-175 Phase 5 Commit 1) and will be cleared by Commit 4. Post-Commit 4, the project trinity contains only PROJECT × OPERATIONS pointers (e.g., `docs/pack/PM-CHAT.md`); pack-side pointers belong in pack trinity, not project trinity. This example illustrates what §3's procedure would have flagged at the time the V1 contamination first landed.
```

Net: same line count for the bullet (1 line, no wrap), but more characters per the longer recast. Doc now reads accurately whether opened at HEAD `2d68262` (pre-Commit-4, V1 still present) or post-Commit-4 (V1 cleared).

---

## §3 Fix 2 (§1.15 NIT) — citation off-by-one on line 5

**Reviewer finding wording.** "The cited `B-fix §3.3` is incorrect — B-fix §3.3 covers per-entry-tree existence semantics, NOT the 1-entry allow-list machine-readable format. The 1-entry shrink is in B-fix §4 (the section that updates B's §2.1 exemption list from 3 entries to 1). The machine-readable FORMAT itself is from B §3.3 (the ORIGINAL B doc, not the fix doc)."

**Verification of citation accuracy.** Confirmed via `grep -n "^##\|^###" maintenance-docs/v11-implementation/ARCHITECTURE-DIRECTORY-REORGANIZATION.md` and `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md`:
- B §3.3 title = "The C2-at-root exemption list (machine-readable)" — original 3-entry design (lines 295-308 of B).
- B-fix §4 title = "Updated C2-at-root exemption list" — 1-entry shrink (lines 107-119 of B-fix).

Reviewer's correction is accurate.

**BEFORE (line 5 at HEAD `2d68262`):**

```
**Source-of-design:** `maintenance-docs/v11-implementation/ARCHITECTURE-DIRECTORY-REORGANIZATION.md` §1.1, §1.2, §4, §5.2 + `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` §3.3 + `AUDIT-USER-CURATION.md` Overrides 1 + 5.
```

**AFTER (line 5 in amended doc):**

```
**Source-of-design:** `maintenance-docs/v11-implementation/ARCHITECTURE-DIRECTORY-REORGANIZATION.md` §1.1, §1.2, §3.3 (machine-readable format), §4, §5.2 + `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` §4 (1-entry shrink) + `AUDIT-USER-CURATION.md` Overrides 1 + 5.
```

Net: line count unchanged (1 → 1); two parenthetical clarifications added so future readers can navigate the dual-source pairing without re-deriving the off-by-one.

---

## §4 Verification results

### §4.1 `grep -n "post-Commit\|pre-Commit" pack-ops/BOUNDARY-DEFINITION.md`

```
168:The `pack-ops/PACK-*.md` paths below reflect the post-Commit 2 location (after BD-175 Phase 5 Commit 2 relocates these files from pack root); pre-Commit 2, they live at pack root.
170:- `pack-ops/PACK-CHAT.md` (post-Commit 2 location) — top section "Boundary rules: see `BOUNDARY-DEFINITION.md`". Pack Chat reads PACK-CHAT.md at startup; this is the most consequential pointer.
171:- `pack-ops/PACK-AGENTS.md` (post-Commit 2 location) — top section pointer. Every pack agent that reads PACK-AGENTS.md gets the pointer.
208:- **Path.** `pack-ops/PACK-AGENTS.md` (post-Commit 2 location; pre-Commit 2 was at pack root).
```

Result: PASS — §6.1 has the new "post-Commit 2 location" hedges (lines 168, 170, 171); §7.2's pre-existing hedge unchanged (line 208). §7.7's hedge uses explicit "Commit 4" wording (line 251) rather than "post-Commit"/"pre-Commit" template phrasing, since the §7.7 narrative is about an event that hasn't yet happened (V1 removal), not a relocation. Confirmed via separate `grep -n "Commit 4"` (output below):

```
251:- **Resolution applied to this specific failure.** Commit 4 of BD-175 Phase 5 (TASK-T1 trinity REPLACE) will remove the contamination from project trinity; ...
```

### §4.2 `head -10 pack-ops/BOUNDARY-DEFINITION.md`

```
# BOUNDARY-DEFINITION — pack/project boundary rules

**Status:** canonical rule reference (stable across pack versions; updated only when the boundary definition itself changes).
**Audience:** pack maintainers, pack agents (pack-architect / pack-coder / pack-planner / pack-reviewer / pack-docs-researcher), future architects, project PM chats (post-install qualifier — see §6).
**Source-of-design:** `maintenance-docs/v11-implementation/ARCHITECTURE-DIRECTORY-REORGANIZATION.md` §1.1, §1.2, §3.3 (machine-readable format), §4, §5.2 + `ARCHITECTURE-DIRECTORY-REORGANIZATION-FIX.md` §4 (1-entry shrink) + `AUDIT-USER-CURATION.md` Overrides 1 + 5.

---

## §1 Purpose
```

Result: PASS — line 5 now references both `B §3.3 (machine-readable format)` and `B-fix §4 (1-entry shrink)`.

### §4.3 `wc -l pack-ops/BOUNDARY-DEFINITION.md`

```
     255 /Users/david/.../pack-ops/BOUNDARY-DEFINITION.md
```

Result: PASS — 255 lines, within 250-360 range (grew by 2 from pre-fix 253; the §6.1 leading paragraph + blank line account for the +2).

### §4.4 `python3 scripts/validate-pack.py`

Tail of output:

```
── Check 35: Phase-task lib invariants (BD-106) ──
  OK: scripts/lib/tracker-phase-task.sh present
  OK: scripts/lib/tracker-labels.sh — no tracker_labels_folded_into helper definition (Path 3 forbidden)
  OK: scripts/lib/ — no `folded-into` literal in executable code (V3.3 §3 line 27); comment-only references allowed

============================================================
PASSED — all checks clean
```

Result: PASS — exit 0, all 35 checks clean.

### §4.5 `bash test-fixtures/build.sh --all --clean && git diff test-fixtures/manifest.txt`

Build output (tail):

```
── building v11-flat-file ──
    source: pack current HEAD
  built: /Users/david/.../test-fixtures/v11-flat-file
  HEAD:  9a1b492f070f4b0d757e045ba002cc5fcacb24b0
── building v11-tracker-on ──
    source: pack current HEAD + tracker.toml mode=tracker
  built: /Users/david/.../test-fixtures/v11-tracker-on
  HEAD:  cdca2132b0ed6e1ed17d31b0aed7c65a6e2f16d3
── building existing-project-mid-dev ──
  ...
  HEAD:  a54e081a9e1d04f293bfb38fa0af77fd9f7f8619

manifest written: /Users/david/.../test-fixtures/manifest.txt
```

Manifest diff:

```
-v11-realistic-ot  9b7e744eb319e7fce7034c6ab4d46917d6f30a2e
-v11-flat-file  eb66fc6cc9ebd5533a4aaf62bef19ab29014ec83
-v11-tracker-on  4d51b7b25f3b8e9dc5ae55f94858adb7ee64e2ad
+v11-realistic-ot  e7ff2315f8b8e3b4b6fb794e994d76506136bf20
+v11-flat-file  9a1b492f070f4b0d757e045ba002cc5fcacb24b0
+v11-tracker-on  cdca2132b0ed6e1ed17d31b0aed7c65a6e2f16d3
```

Result: **PASS-with-caveat.** The manifest IS dirty, but the drift is NOT caused by this fix-pass. The drift is from the parallel Commit-2 coder's staged work — `git status` shows 7 staged renames (BACKLOG.md → pack-ops/BACKLOG.md, etc.) plus ~30 unstaged modifications under `scripts/`, `.claude/agents/pack-*.md`, `.codex/agents/pack-*.toml`, `.gemini/agents/pack-*.md`, and root trinity. All three v11-* fixtures (which build from `pack current HEAD` including staged + unstaged working-tree state) see SHA drift because of Commit 2's pending v11-surface edits.

This fix-pass's only edit is `pack-ops/BOUNDARY-DEFINITION.md`, which is NOT v11-surface (only files under `project-template/` or `scripts/` trigger RC9 per the pack-memory rule). In isolation (i.e., if this fix-pass landed as the next commit BEFORE Commit 2), the BOUNDARY-DEFINITION.md edit alone would produce ZERO manifest delta. Pack Chat will commit this fix BEFORE Commit 2's commit lands; the manifest regeneration for the Commit 2 changeset is Commit 2's responsibility, not this fix-pass's.

RC9 base case (BOUNDARY-DEFINITION.md not v11-surface): CONFIRMED. The dirty manifest visible at this moment is pre-existing parallel-work drift, not a regression introduced by this fix.

---

## §5 Plan deviations

NONE. Both fixes match the reviewer's `Proposed fix shape` exactly:
- §1.13 SHOULD: Option (a) chosen — added the same `(post-Commit N location)` hedge to §7.7 and §6.1 entries (one-of-two reviewer-suggested options; user's session triage is FIX-ALL default, so option (a) — the smaller fix — was preferred over option (b) post-batch deferral).
- §1.15 NIT: One-line edit to BOUNDARY-DEFINITION.md line 5 changing `B-fix §3.3` to `B §3.3 (machine-readable format) + B-fix §4 (1-entry shrink)`.

The reviewer's parenthetical note about the plan §2.1.3 inheriting the same off-by-one ("Pack Chat may want to fix the plan in the same fix-pass for symmetry") was NOT addressed in this fix-pass because the prompt scoped me to `pack-ops/BOUNDARY-DEFINITION.md` only (`ONLY pack-ops/BOUNDARY-DEFINITION.md modified`). The plan file is `maintenance-docs/v11-implementation/PLAN-BD-175-PHASE-5.md` — Pack Chat can elect to fix it separately or accept that the plan is an archived planning artifact that need not be retroactively corrected.

---

## §6 New OQs

None. Both fixes were mechanical applications of the reviewer's proposed fix shape; no design ambiguity surfaced during implementation.

The manifest-drift caveat in §4.5 is NOT a new OQ — it is an explanation of an expected pattern (parallel coder work staged but not committed yields cumulative manifest drift; per-fix manifest accounting is per-commit, not per-edit). The pack-memory `feedback_manifest_regen_on_v11_surface` rule already governs this and is correctly applied: my non-v11-surface edit does not trigger RC9; Commit 2's v11-surface edits do trigger RC9 and Commit 2's coder is responsible for regenerating manifest as part of that commit.

---

## §7 PREFLIGHT

PREFLIGHT: 1/1 in-scope file edits complete; verification PASS (validate-pack.py exit 0 / 35 checks clean; §4.1-§4.4 grep + head + wc all match expected post-fix shape; §4.5 manifest drift is pre-existing parallel-Commit-2 work, not caused by this fix per RC9 file-path analysis); HEAD `2d68262d29e1de2d26b10522d61c713a056c04d3`; about to Write IMPL-REPORT to `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-175-COMMIT-1-FIX.md`.

---

**End of IMPLEMENTATION-REPORT-BD-175-COMMIT-1-FIX.md.**
