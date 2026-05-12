# PACK-REVIEW-BD-146

**Verdict:** APPROVE — Check 31 + Check 27 extension land cleanly with structural (line-number-free) parsing, exec bit preserved, no out-of-scope edits, and the synthetic-orphan negative test verified with no leftover artifact.

---

## 1. Summary

BD-146 (Batch 7 of the v11.0 skill-dimensions reframe) adds a single
new check (Check 31, skill-cell consistency) to
`scripts/validate-pack.py` and extends Check 27 to validate agent
files' `## Skills to load:` sections against the canonical skills set.
The implementation is mechanical, on-spec, robust against future
PLATFORM-SKILLS.md edits, and passes a full validator run end-to-end.
All three POQs in the implementation report are accept-grade.

Files modified by BD-146: 1 (`scripts/validate-pack.py`, +304 lines
2322 → 2626).

---

## 2. Per-concern findings

### 2.1 Check 31 algorithm (correctness)

`scripts/validate-pack.py:2380-2574` — the implementation matches the
architect spec from `ARCHITECTURE-SKILL-DIMENSIONS.md` §3 + §3.7-§3.8.

- Inventory subsections enumerated at lines 2386-2391 match the four
  `### <name> (NN)` headers actually present in
  `project-template/docs/pack/PLATFORM-SKILLS.md` (lines 417, 439, 475,
  481 — verified by grep).
- Disk-side enumeration (lines 2467-2471) walks
  `project-template/skills/<name>/` for `SKILL.md` — the canonical
  pack-convention path, NOT the per-CLI fan-out paths from the BACKLOG
  File/Symbol wording. This matches the prompt clarification and the
  pack convention established by BD-156/157/158 (per-CLI fan-out
  happens at install time via `init-project.sh stage_s4_skills`).
- Five failure modes covered: orphan (lines 2511-2519), phantom
  (2521-2530), double-counted (2532-2542), per-subsection header drift
  (2488-2494), total-line drift (2544-2567). Each emits a
  message that names the exact file path and the exact problem class.
- D1-implied skills are correctly counted as ONE canonical cell — the
  inventory subsection rows are the canonical source; the dimension
  tables (D1-D5) and intersection table contain loading-mechanism
  descriptors only and are NOT parsed by Check 31. This matches
  `PLAN-SKILL-DIMENSIONS.md` §4.3.

### 2.2 Check 27 extension (correctness)

`scripts/validate-pack.py:1379-1457` — extension is correctly nested
inside `check_agent_canonical_phrases()` so it brands as part of
Check 27, not a sibling check (preserving the public check count).

- Builds `disk_skills` from canonical `project-template/skills/`
  (1388-1392) and `known_skills` from PLATFORM-SKILLS.md backticked
  identifiers + inventory-table first-column tokens (1396-1412).
- Walks every agent file with a `## Skills to load` H2 (1415-1457),
  skips `x-*` agents (1420), and validates each backticked identifier
  against both the on-disk set AND the PLATFORM-SKILLS.md known set.
- Underscore filter at line 1434 correctly excludes
  detection-helper identifiers like `swiftdata_marker_detected()`
  from being treated as skill names (skills are kebab-case).
- Output verified by validator run: 14 OK lines (7 auditor-* × 2 CLIs
  carrying `## Skills to load`; codex `.toml` agent files have no such
  section, correctly skipped).

### 2.3 Check number not occupied

Verified `Check 31` is the next-free number per `PLAN-SKILL-DIMENSIONS.md`
§4.3 guidance. Highest pre-existing check is Check 30 (recommendation
state schema, BD-079, line 2304 of validate-pack.py). Check 31 added at
line 2380. No collision.

### 2.4 Synthetic-orphan negative test — no leftover artifact

`ls /Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/project-template/skills/test-orphan/`
returns "No such file or directory". Skill directory count:

```
ls project-template/skills/ | wc -l   →   34
```

Matches the inventory total. No synthetic artifact left behind. The
implementation report (§5.3) shows the orphan was correctly detected
with the exact message:

```
FAIL: PLATFORM-SKILLS.md — orphan SKILL.md: project-template/skills/test-orphan/SKILL.md exists on disk but is not listed in any Full skill inventory subsection
```

### 2.5 No out-of-scope edits

`git status --short` shows only:

- `M project-template/docs/pack/PLATFORM-SKILLS.md` — verified to be
  BD-149 in-flight work (additive "Extending this file" / naming
  convention section); explicitly out of scope for this review.
- `M scripts/validate-pack.py` — the BD-146 change.
- Untracked `IMPLEMENTATION-REPORT-BD-146.md`, `IMPLEMENTATION-REPORT-BD-149.md`,
  `PACK-REVIEW-BD-149.md`, plus the six `RESEARCH-*.md` /
  `ARCHITECTURE-PER-ENTRY-*.md` files (out-of-band per prompt).

Confirmed BD-146 touched only the one file.

### 2.6 Permission bits preserved

```
-rwxr-xr-x@ 1 david  staff  113221 May 12 11:28 scripts/validate-pack.py
```

Exec bit `-rwxr-xr-x` intact.

### 2.7 Robustness against future PLATFORM-SKILLS.md edits

The parser is structurally robust:

- `_parse_inventory_subsection()` uses a regex anchored to
  `### <header> (NN)` headers (line 2400-2403), bounded by lookahead
  for the next `###` / `##` / EOF. No hardcoded line numbers.
- The body parser (lines 2410-2421) accepts both backticked
  (`` | `name` | ``) and plain (`| name |`) first-column styles, skips
  separator (`|---|`) and header (`| Skill |`) rows explicitly.
- `re.MULTILINE | re.DOTALL` flags ensure cross-line matching works
  regardless of surrounding prose insertions.
- Verified empirically: BD-149's parallel-batch insertions to
  PLATFORM-SKILLS.md are present in the working tree, and Check 31
  still PASSES with no warnings — confirming structural parsing
  tolerates additive prose changes that don't touch the inventory.

### 2.8 `python3 scripts/validate-pack.py` returns PASS

End-to-end run completes with `PASSED — all checks clean`. Check 31
output:

```
── Check 31: Skill-cell consistency (BD-146, v11) ──
  OK: PLATFORM-SKILLS.md — 'Tier 0 base skills': 13 rows (header matches)
  OK: PLATFORM-SKILLS.md — 'Dimensional skills': 19 rows (header matches)
  OK: PLATFORM-SKILLS.md — 'Trigger-loaded skills': 1 rows (header matches)
  OK: PLATFORM-SKILLS.md — 'PM chat operational skill': 1 rows (header matches)
  OK: PLATFORM-SKILLS.md — total skills: 34 (header sum, inventory row count, and disk count all agree)
  OK: Skill-cell consistency: 34 SKILL.md on disk, all map to exactly one inventory cell; no orphans, phantoms, or double-counts
```

13 + 19 + 1 + 1 = 34 = disk count.

### 2.9 Maintainability principle (BD-159 §3.1)

- Files touched: 1 (≤ 10 cap). PASS.
- New top-level docs: 0. PASS.
- Trinity touched: No (single-file validator). PASS.
- Architecture changes: None. The check encodes existing canonical-cell
  contract from `ARCHITECTURE-SKILL-DIMENSIONS.md` §3 / §3.7-§3.8. PASS.
- Client `x-` skills/agents preserved: Yes — Check 27 extension skips
  `x-*` agents (line 1420); Check 31 enumerates a pack-shipped namespace
  (`project-template/skills/`). PASS.

Verdict: mechanical edit. No architect-pass migrator coverage required.

---

## 3. POQ disposition

**POQ-1 (D1-implied skills counted as one cell).** ACCEPT. Matches
`PLAN-SKILL-DIMENSIONS.md` §4.3 directive verbatim. The inventory row
in `### Dimensional skills (19)` is the canonical cell; D1-row
references in the dimension tables are loading-mechanism descriptors,
not separate cells. Check 31 correctly does not parse the D1-D5 / D-row
tables to avoid counting these as duplicates. No further action.

**POQ-2 (strict per-agent assignment derivation deferred).** ACCEPT.
The shipped Check 27 extension enforces the right contract for the
current state: every cited skill must exist on disk AND be known to
PLATFORM-SKILLS.md. This catches typos and stale renames — the most
common drift modes — without coupling the validator to PLATFORM-SKILLS.md
"Step 2" prose that is still in flux through BD-141..BD-150. The
follow-on BD recommendation in the implementation report is sound;
recommend a v11.x BD opened post-BD-150 once the Step-2 prose
stabilizes. Pack Chat may capture this via the standard PM-chat flow,
not pack-coder.

**POQ-3 (canonical `project-template/skills/` enumeration).** ACCEPT.
Consistent with the BD-156/157/158 pack convention finding — per-CLI
fan-out happens at install time, not in source. The BACKLOG File/Symbol
wording referencing per-CLI paths is stale planner-template wording;
the canonical path is the single `project-template/skills/<name>/`. No
further action.

---

## 4. Cross-reference integrity

- `PLAN-SKILL-DIMENSIONS.md` §1 critical-path diagram lists BD-146 →
  BD-150; BD-150 references Check 31 as the gate. Check 31 ships at
  the right location in the sequence.
- BD-146 BACKLOG entry (line 1427-1434) — File/Symbol still says
  `.claude/skills/` / `.codex/skills/` / `.gemini/skills/` paths. This
  is acknowledged in the implementation report POQ-3 as stale planner
  wording per pack convention; the implementation correctly uses the
  canonical path. NIT (informational only): the BACKLOG entry could
  be tightened in the same way BD-156/157/158 entries were tightened
  in commit `8014186`. Not a blocker; recommend the next BACKLOG
  housekeeping pass picks this up.
- No stale references found elsewhere — `Check 31` references in
  `PLAN-SKILL-DIMENSIONS.md` (BD-156/157/158/142 entries) all point at
  the same check that just landed.

---

## 5. Trinity rule

N/A — `scripts/validate-pack.py` is single-file pack tooling. The
review verified no CLAUDE.md / AGENTS.md / GEMINI.md edits were
required nor present in this BD's diff. The Check 27 extension's
agent-file scope correctly walks all three CLI directories
(`.claude/agents/`, `.codex/agents/`, `.gemini/agents/`) so the
check itself is trinity-aware.

---

## 6. validate-pack.py alignment

Check 31 is properly registered:

- Module docstring updated to describe the new check
  (`scripts/validate-pack.py:108-114`).
- `main()` calls `check_skill_cell_consistency()` after
  `check_recommendation_state_schema()` (line 2614).
- Print header at line 2454 follows the existing
  `── Check NN: <name> ──` convention.
- Failure messages use the existing `fail()` helper (lines 2459, 2462,
  2480, 2490, 2514, 2525, 2536, 2550, 2556).
- Success messages use the existing `ok()` helper.

No deviations from the file's idiom.

---

## 7. Migration safety / README layout / BACKLOG accuracy

- Migration safety: N/A — Check 31 is a CI-side validator addition;
  no project-side files affected. No MIGRATION or QUICKSTART changes
  needed.
- README layout: N/A — no files added, moved, or removed.
- BACKLOG accuracy: BD-146 status will be flipped to Resolved by Pack
  Chat as the final batch step (per CLAUDE.md `## Pack memory`
  implicit-flip rule). The Resolved line should reference Check 31
  PASS + synthetic-orphan negative test verified + 1 file modified
  (validate-pack.py).

---

## 8. Nits (non-blocking)

1. **BACKLOG File/Symbol wording (BD-146 line 1432).** Says
   `project-template/.claude/skills/` / `.codex/skills/` / `.gemini/skills/` —
   inconsistent with pack convention (canonical path is
   `project-template/skills/`). Recommend tightening in the next
   BACKLOG housekeeping pass, parallel to the
   BD-156/157/158 wording fixup in `8014186`. Not a blocker because
   POQ-3 documents the implementation-time decision and the validator
   correctly uses the canonical path.

2. **Implementation-report claim about line count vs actual file
   size.** Report §5.1 cites `113221` bytes post-edit; report §2 cites
   `+304 lines (2322 → 2626)`. Verified file is now `2626` lines and
   `113221` bytes, matching the report. No issue — informational.

---

## 9. Verdict

**APPROVE.**

BD-146 is a clean, mechanical, on-spec landing of the Check 31 +
Check 27 extension gate. Robust structural parsing, exec bit
preserved, no out-of-scope edits, validator passes end-to-end, and
the synthetic-orphan negative test is verified with no leftover
artifact. POQs 1/2/3 are all accept-grade. Pack Chat may flip BD-146
to Resolved as the final batch step.
