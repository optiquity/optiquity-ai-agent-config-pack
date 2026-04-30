# Phase 3 Implementation Plan v2 — Re-Review Report (v3, targeted)

**Reviewer:** pack-reviewer (sub-agent session, targeted re-review)
**Date:** 2026-04-22
**Target:** `maintenance-docs/v10-working/phase-3-implementation-plan-v2.md` (2,207 lines)
**Prior review:** `maintenance-docs/v10-working/phase-3-plan-v2-review-v2.md` (APPROVED)
**Fixes scope claimed by task:** NIT-1, A1, A2, A5 (A6 closed by NIT-1)
**Mode:** READ-ONLY.

---

## 0. Verdict

**APPROVED for Phase 4 execution.**

All five targeted fixes are correct and introduce no regressions. The
plan retains the APPROVED state established by `phase-3-plan-v2-
review-v2.md` and now resolves every outstanding advisory item except
the three that were explicitly deferred as plan-quality observations
(A1, A2, A5 are now resolved; NIT-1 is resolved; A6 is closed as a
byproduct of NIT-1). No open advisory items remain. No residual
findings.

---

## 1. Fix-by-fix verification

### NIT-1 — C-046-ADD-01 verification block compact range — **RESOLVED**

**Prior state (v2-review-v2 line 1472):** `- V-ADDCAP-01..08 run.`

**Current state.** The single C-046-ADD-01 smoke-test enumeration now
reads explicitly at line 1519:

```
- V-ADDCAP-01/02/03/03b/04/05/06/07/08 run.
```

**Line-number note.** The NIT-1 target previously at line 1472 has
shifted to line 1519 as a byproduct of the A2 inline expansion in
§5.2 (~+47 lines between §5 and §6.6). The fix is in the correct
location: inside the C-046-ADD-01 `**Verification:**` bullet list,
immediately before the V-ADDCAP-13 / 14 / 07 / 08 call-outs.

**Full-scope grep verification.** `grep -n "V-ADDCAP-"` across the
plan returned 18 hits. Every compact `N..M` form remaining either
(a) explicitly includes `03b` (`01/02/03/03b/04..16` at lines 413,
1598, 1663, 1981) or (b) lies outside the 03–04 boundary
(`V-ADDCAP-09..12` at line 1569, where 03b is not in range and
therefore cannot be silently excluded). No ambiguous compact form
that could silently drop 03b remains.

**A6 closure.** A6 ("compact N..M enumeration preference") was
flagged in the original review as resolved at five of six call
sites with NIT-1 as the residual. With NIT-1 now fixed, A6 is
fully closed.

**Verdict:** NIT-1 resolved. No regression.

---

### A1 — V10-DESIGN §12.5 citation at C-046-ADD-02 — **RESOLVED**

**Prior state.** C-046-ADD-02 `v1-to-v2 note` stated only that
Procedure 6 lands in a separate commit from Procedures 5/5-R
"because add-capability.sh must exist first" — no authority cited.

**Current state (lines 1553–1558):**

> **v1-to-v2 note:** PM-CHAT.md trigger rule (row 81) was already
> landed in C-046-04 per the combined rows 24+38+81 directive in
> §8.2.8. No duplicate PM-CHAT.md edit here. Procedure 6 lands in
> a separate commit from Procedures 5/5-R (C-046-08) because
> add-capability.sh must exist first — **V10-DESIGN §12.5
> explicitly permits this split and names the dependency as the
> reason for separate placement.**

**Authority check.** V10-DESIGN.md §12.5 exists (line 3866:
"### 12.5 Capability-addition commits (AD-14..AD-18 landing)").
Its content:
- Line 3868–3872 states the three commits append to BD-046 with
  dependencies on BD-044 + BD-046 outputs (detect.sh, Procedure 5).
- Line 3877 (C-046-ADD-02 row) lists dependency "BD-046
  METHODOLOGY.md Procedure 5 commit (Procedure 6 sits alongside)."
- Lines 3880–3890 discuss commit-ID placeholders and dependency
  relationships.

The citation is accurate. §12.5 is the correct V10-DESIGN section
to cite for the rationale that C-046-ADD-02 must land after
C-046-ADD-01 and C-046-08. The prose "explicitly permits this
split and names the dependency as the reason for separate
placement" matches §12.5's actual content.

**Verdict:** A1 resolved. Citation is correct and authoritative.

---

### A2 — Fixture B `--with-x-files` block inlined — **RESOLVED**

**Prior state.** §5.2 Fixture B line 508 was a single-line elision:
`: # (content elided for brevity; identical to §5.1 --with-x-files
block)`. Phase 4 implementer would have had to cross-reference §5.1.

**Current state (lines 509–556).** The block is fully inlined.

**Structural parity check against Fixture A (§5.1 lines 336–390):**

| Artifact | Fixture A (§5.1) | Fixture B (§5.2) | Match? |
|---|---|---|---|
| `.claude/agents/x-deployer.md` with Claude YAML frontmatter (`name`, `description`, `tools`) | line 337–345 | line 510–518 | ✓ byte-identical heredoc body |
| `.codex/agents/x-deployer.toml` with Codex TOML (`name`, `description`, `model`, `approval_policy`, `sandbox_mode`, `developer_instructions`) | line 346–355 | line 519–528 | ✓ byte-identical |
| `.gemini/agents/x-deployer.md` with Gemini YAML (`name`, `description`, `model`, `temperature`, `max_turns`) | line 356–366 | line 529–539 | ✓ byte-identical |
| `.claude/skills/x-brokerage-api/SKILL.md` + Codex + Gemini copies | line 367–379 | line 540–552 | ✓ byte-identical |
| `docs/pack/prompts/x-deployer.md` (v10-only artifact) | line 380–389 present | line 553–555 **explicitly omitted with rationale** | ✓ correctly omitted |

**v9.3-context correctness verification.** This is the critical
acceptance criterion for A2. The Fixture B block correctly does
**not** seed `docs/pack/prompts/x-deployer.md` because v9.3 does
not ship a `docs/pack/prompts/` directory (the directory is
created during migration at S4 per V10-DESIGN). The inline block
includes an explicit three-line bash comment at lines 553–555:

```bash
  # Note: v9.3 has no docs/pack/prompts/ directory, so no x- prompt file
  # is seeded here. The migration creates docs/pack/prompts/ at S4;
  # x- prompt preservation is tested in Fixture A (v10 install) instead.
```

This is the correct semantics. No v10-only artifact is seeded into
the v9.3-context fixture. The comment documents the design intent
so a future implementer does not "fix" it by copying the §5.1
x-prompt block.

**Same agent name, same skill name, same frontmatter pattern.**
Confirmed byte-for-byte except for the v9.3-appropriate omission
noted above.

**`--with-custom-prompt-templates` flag handling preserved.** Lines
559–562 still contain the second optional block (PROMPT-TEMPLATES.md
mutation), which was unrelated to A2 and is unchanged in scope.

**Verdict:** A2 resolved. Inline block matches Fixture A structurally
while correctly respecting the v9.3 context — no v10-only artifacts
seeded.

---

### A5 — Principle 7 softened re: MIGRATION-v8-to-v9.md — **RESOLVED**

**Prior state.** §2 principle 7 overstated the treatment of
MIGRATION-v8-to-v9.md, implying annotation treatment parity with
V9-DESIGN.md / V9-AUDIT-REPORT.md. This did not match C-046-10's
actual scope.

**Current state (lines 117–123):**

> 7. **Historical records are annotated, not mutated** (V9 Lessons 4,
>    5). V9-DESIGN.md and V9-AUDIT-REPORT.md receive supersession
>    annotations (C-046-09); V10-PREDESIGN.md receives a supersession
>    banner (S-02); MIGRATION-v8-to-v9.md receives an optional single-
>    line pointer to MIGRATION-v9-to-v10.md (C-046-10 — implementer
>    may skip if the pointer adds no value). Body content is preserved
>    in all cases.

**Scope-alignment verification against referenced commits:**

| File | Principle 7 claim | Actual commit scope | Match? |
|---|---|---|---|
| V9-DESIGN.md | Supersession annotations (C-046-09) | C-046-09 line 1020: "inline supersession annotations beside PROMPT-TEMPLATES.md references; Decision 7 pointer" | ✓ Exact match |
| V9-AUDIT-REPORT.md | Supersession annotations (C-046-09) | C-046-09 line 1023: "same treatment" (if present) | ✓ Exact match |
| V10-PREDESIGN.md | Supersession banner (S-02) | S-02 line 1731: "Add supersession banner to `maintenance-docs/V10-PREDESIGN.md`" | ✓ Exact match |
| MIGRATION-v8-to-v9.md | Optional single-line pointer (C-046-10 — may skip) | C-046-10 line 1050–1053: "historical; optional single-line pointer to MIGRATION-v9-to-v10.md (land it after C-046-16 creates that guide; acceptable to skip here and do it as part of S-02 or a small standalone commit)" | ✓ Exact match (including the "may skip" affordance) |

Three distinct treatment classes are now named and each attaches to
the correct commit. The "optional" and "implementer may skip"
qualifiers are preserved verbatim between principle 7 and C-046-10's
file-list entry. No downstream commit entry is contradicted.

**Verdict:** A5 resolved. Principle 7 is now a faithful summary of
C-046-09 / C-046-10 / S-02 scope.

---

### A6 — Compact "N..M" enumeration preference — **RESOLVED (closed by NIT-1)**

**Status.** A6 was the class finding; NIT-1 was the last concrete
call site. With NIT-1's line 1519 now explicit, no compact form
remains that could silently exclude V-ADDCAP-03b. A6 is fully
closed. No further action required.

---

## 2. Regression sweep

The six tests requested by the task goal:

### 2.1 No change to commit dependencies

**Check.** Every `**Dependencies:**` line across all 30 commit
entries and 3 ship entries was spot-checked. Representative entries:

- C-046-ADD-01 deps (lines 1493–1500): C-044-01, C-046-15, C-046-08,
  C-044-02 §7.6 table — unchanged.
- C-046-ADD-02 deps (line 1559): C-046-ADD-01, C-046-08 — unchanged.
- C-046-ADD-03 deps (line 1584): C-046-ADD-01 — unchanged.
- C-046-09 deps (line 1027): none beyond C-046-01 — unchanged.
- C-046-10 deps (line 1054): C-046-01 — unchanged.
- S-02 deps chain (line 1722–1733): unchanged.

No dependency edge was added, removed, or re-wired by any of the
five fixes.

**Verdict:** No regression.

### 2.2 No change to gate entry criteria

**Check.** Eight gates exist (A, B, C, D, E, E2, F, Ship). Each
was spot-checked.

- Gate A (§6.1 tail): unchanged.
- Gate B (line 847–849): unchanged.
- Gate C (line 1086–1101): five entry criteria unchanged. MIGRATION-
  v8-to-v9.md historical mention at criterion 3 is consistent with
  the A5-softened principle 7.
- Gate D (line 1246–1248): unchanged.
- Gate E (line 1427–1432): nine-validator-checks criterion intact.
- **Gate E2** (line 1592–1608): seven entry criteria unchanged.
  Criterion 4 still reads "V-ADDCAP-01/02/03/03b/04..16 all pass on
  Fixture A" — 03b coverage preserved independent of the NIT-1 fix.
- Gate F (line 1681–1696): six criteria unchanged. Criterion 4
  still says "all eight function tests." F3's eight-vs-nine
  resolution is untouched.
- Gate Ship (line 1981–1983, §10 summary): unchanged.

**Verdict:** No regression. Particularly important: Gate E2
criterion 4 still guarantees V-ADDCAP-03b coverage as an
independent backstop to the now-explicit NIT-1 smoke-test.

### 2.3 No change to Part 8 row coverage

**Check.** §16 table (lines 2158–2169) — every row range (1–84)
and commit assignment matches prior review's audit byte-for-byte.
No row was orphaned or re-homed. §8.2.8 row range (78–84) still
maps to C-046-ADD-01 (78, 79), C-046-ADD-02 (80), C-046-04 (81),
C-046-ADD-03 (82), S-03 (83), V-ADDCAP-01 validates 84.

**Verdict:** No regression.

### 2.4 No regression in F1 — Dimension 2 regex

**Check.** §8.2 Dimension 2 (lines 1888–1906). All three regexes
intact:
- apple: `(rule|rules)\s+(1[1-9]|2[0-3])\b` → 11–23 ✓
- python: `(rule|rules)\s+(1[4-9]|2[0-9]|3[0-2])\b` → 14–32 ✓
- architecture-review: `(rule|rules)\s+(1[4-5])\b` → 14–15 ✓

Explanatory comments at lines 1889–1891, 1898, 1902 still say
"FULL old range." Scope still `project-template/ supporting-docs/
maintenance-docs/`. No drift.

**Verdict:** F1 remains resolved.

### 2.5 No regression in F3 — detect.sh function count

**Check.** `grep -nE "nine|eight"` returned four matches:
- Line 1192: "eight stages S0–S7" (migration script, unrelated) ✓
- Line 1431: "All nine `validate-pack.py` checks active" ✓
- Line 1690: Gate F criterion 4 "eight function tests" ✓
- Line 1982: §10 Gate F summary "eight functions" ✓

§6.7 activity 3 (lines 1624–1649) enumerates eight `detect_*`
functions; the eighth is `detect_installed_capabilities` (the
Phase 3-AC extension). Count consistent throughout.

**Verdict:** F3 remains resolved.

### 2.6 No regression in F4 — Deferred-items table

**Check.** §6.9 Phase 6 step 2 (lines 1799–1807) still a standalone
markdown table with four columns (V10-DESIGN §, Item, Resolution
target, Status at ship) and five rows (§13.1, §13.2, §13.3, §13.4,
§13.6). Table placement between list items 1 and 3 unchanged.
(The table's line numbers shifted from 1751–1757 to 1801–1807 as a
byproduct of the A2 inline expansion; structure and content
identical.)

**Verdict:** F4 remains resolved.

---

## 3. Cross-cutting integrity checks

1. **Plan length trajectory.** Prior (v2-review-v2): 2,157 lines.
   Current: 2,207 lines. Net +50 lines. Consistent with scope:
   A2 inline (~47 lines for the --with-x-files heredoc block),
   A1 (~1 line citation clause appended), A5 (~2 lines principle
   7 rewrite; replaces existing text), NIT-1 (0 net lines;
   in-place replacement).

2. **Section-heading stability.** `grep "^## "` → 19 top-level
   sections (unchanged). 30 `#### C-…` commit subsections +
   3 `#### S-…` ship subsections = 33 total (unchanged). Gate
   subsections (A, B, C, D, E, E2, F) unchanged. No renumbering.

3. **Commit-ID stability.** §15 commit list (lines 2110–2145)
   retains 33 rows with identical IDs, phases, gates, and
   messages. C-046-ADD-01/02/03 placements at rows 28/29/30 and
   S-01/02/03 at rows 31/32/33 are preserved.

4. **V-ADDCAP enumeration consistency.** Six call sites that take
   a "full battery" form (§5.1 used-by-tests, §6.6 C-046-ADD-01
   smoke, §6.6 Gate E2 criterion 4, §6.7 Phase 4 activity 4,
   §10 E2 summary row, `—` §15 N/A) now use either
   `V-ADDCAP-01/02/03/03b/04..16` (five sites) or the fully
   explicit `V-ADDCAP-01/02/03/03b/04/05/06/07/08` (one site,
   1519, the subset smoke test). Every full-battery site
   explicitly names 03b. No compact form excludes 03b.

5. **Trinity rule (pack self-audit).** No `project-template/`
   trinity file was touched by any of the five fixes. All edits
   are in `maintenance-docs/v10-working/phase-3-implementation-
   plan-v2.md`.

6. **CLAUDE.md pack-repo rules compliance.** All five fixes are
   confined to `maintenance-docs/v10-working/`. No BACKLOG.md,
   README.md, PACK-CHAT.md, PACK-AGENTS.md, CLAUDE.md / AGENTS.md
   / GEMINI.md, or CHANGELOG.md was modified. ✓

7. **Fixture A script integrity (A2 adjacency check).** §5.1
   Fixture A bash script block (lines 279–394) is byte-
   identical to the prior v2-review-v2 state. A2's inlining
   happened in §5.2 only; §5.1 was untouched, so the "source
   block" against which A2 inlined remained a valid reference
   during the edit.

8. **C-046-09 / C-046-10 / S-02 body content (A5 alignment).**
   C-046-09 (lines 1013–1031), C-046-10 (lines 1033–1059), and
   S-02 (lines 1722–1734) are textually unchanged apart from
   the explicit-citation downstream ripple in principle 7. The
   fix updated principle 7 to track these commits' pre-existing
   scope rather than moving scope between commits.

9. **Risk table §13 unchanged** (R1–R20 per prior review;
   current lines 2050–2073).

10. **Part 10 CP battery listing (§6.7 activity 4).** Line 1663
    reads `V-ADDCAP-01/02/03/03b/04..16.` — 03b intact. No other
    V-ID battery list was altered.

No regression detected in any check.

---

## 4. Advisory items — closed-out ledger

| Item | Prior status | Current status |
|---|---|---|
| F1 (Dimension 2 regex) | Resolved | Resolved, no regression |
| F2 (V-ADDCAP-03b omitted) | Resolved w/ NIT-1 | Resolved (NIT-1 now closed) |
| F3 (detect.sh eight/nine) | Resolved | Resolved, no regression |
| F4 (deferred-items table) | Resolved | Resolved, no regression |
| A1 (§12.5 citation) | Open | **Resolved this pass** |
| A2 (Fixture B elision) | Open | **Resolved this pass** |
| A3 (scripts/ distinction) | Resolved | Resolved, no regression |
| A4 (v9.3 tag precondition) | Resolved | Resolved, no regression |
| A5 (Principle 7 vs. C-046-09/10) | Open | **Resolved this pass** |
| A6 (compact N..M preference) | Mostly resolved | **Resolved this pass (via NIT-1)** |
| NIT-1 (line 1472 compact range) | Open | **Resolved this pass (now line 1519, explicit)** |

**No open findings remain.**

---

## 5. Final verdict

**APPROVED.**

All five targeted fixes (NIT-1, A1, A2, A5, A6-via-NIT-1) are correct
and no regressions were introduced. Previously-resolved findings
(F1, F2, F3, F4, A3, A4) remain resolved. Commit dependencies, gate
entry criteria, Part 8 row coverage, V-ADDCAP battery semantics,
and trinity-rule compliance are intact.

The plan is ready for Phase 4 execution. No further review passes
are required on this basis.

---

*End of re-review v3 report.*
