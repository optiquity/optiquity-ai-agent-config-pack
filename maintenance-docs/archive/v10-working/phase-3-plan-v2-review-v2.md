# Phase 3 Implementation Plan v2 — Re-Review Report

**Reviewer:** pack-reviewer (sub-agent session, re-review after fixes)
**Date:** 2026-04-22
**Target:** `maintenance-docs/v10-working/phase-3-implementation-plan-v2.md` (2,157 lines)
**Prior review:** `maintenance-docs/v10-working/phase-3-plan-v2-review.md` (F1–F4 + A1–A6)
**Fixes scope claimed by task:** F1, F2, F3, F4, A3, A4
**Mode:** READ-ONLY.

---

## 0. Verdict

**APPROVED for Phase 4 execution.**

All four must-fix findings (F1–F4) are resolved. Both advisory items
targeted for this pass (A3, A4) are resolved. No regressions were
introduced. One minor textual nit remains in the C-046-ADD-01
verification block (see §3 NIT-1 below) — it does not compromise
V-ADDCAP-03b coverage because the role-dimension test is explicitly
listed at Gate E2 entry criterion 4, the §10 E2 summary row, and the
§6.7 Phase 4 activity 4 battery. Recommend fixing NIT-1 opportunistically
but do not block Phase 4 on it.

Advisory items A1, A2, A5, A6 were not in this fix pass's declared
scope. They remain open as noted in the prior review.

---

## 1. Fix-by-fix verification

### F1 — Renumbering sweep regex (MAJOR) — **RESOLVED**

**Target location.** Plan §8.2 Dimension 2, lines 1838–1856.

**Prior regex (defective):**
- apple: `(rule|rules)\s+(1[1-4])\b` (captured only 11–14)
- python: `(rule|rules)\s+(1[4-7])\b` (captured only 14–17)
- architecture-review: `(rule|rules)\s+(1[4-5])\b` (already correct)

**Current regex (lines 1842, 1849, 1854):**
- apple: `(rule|rules)\s+(1[1-9]|2[0-3])\b` → captures **11–23** ✓
  (matches V10-DESIGN §3.3 old range: 11–23 shift to 15–27)
- python: `(rule|rules)\s+(1[4-9]|2[0-9]|3[0-2])\b` → captures **14–32** ✓
  (matches V10-DESIGN §3.4 old range: 14–32 shift to 18–36)
- architecture-review: `(rule|rules)\s+(1[4-5])\b` → **14–15** ✓
  (unchanged; already correct per prior review note)

**Explanatory comments updated.** Lines 1839–1841 and 1848 now
explicitly state "FULL old range" and tie the range to the
shift-by-+4 rule. Post-match decision guidance is preserved at
lines 1844–1846: "If matches exist, evaluate whether the referent
is the pre-v10 content (now at +4) or the new Capabilities section
rules (11–14). Update accordingly."

**Scope preserved.** All three greps retain the full
`project-template/ supporting-docs/ maintenance-docs/` scope.
Dimension 1 and Dimension 3 unchanged. §8.2 "Full scope
enforcement" paragraph (lines 1885–1890) intact.

**Verdict:** F1 fully resolved. No regression detected.

---

### F2 — V-ADDCAP-03b omitted (MAJOR) — **RESOLVED (with NIT-1)**

**Prior review fix list (six call sites):**
1. §5.1 fixture-A Used-by-tests list
2. §6.6 C-046-ADD-01 verification block (explicit V-ADDCAP-03b row)
3. §6.6 Gate E2 entry criterion 4
4. §6.7 Phase 4 activity 4
5. §10 Gate E2 summary row
6. §15 commit list (optional)

**Current state (grep of `V-ADDCAP-` across the plan):**

| # | Site | Line | Current text | Status |
|---|---|---|---|---|
| 1 | §5.1 Fixture A "Used by tests" | 410 | `V-ADDCAP-01/02/03/03b/04..16 …` | ✓ Resolved |
| 2 | §6.6 C-046-ADD-01 verification | 1472 | `V-ADDCAP-01..08 run.` | ⚠️ NIT-1 below |
| 3 | §6.6 Gate E2 entry criterion 4 | 1548 | `V-ADDCAP-01/02/03/03b/04..16 all pass on Fixture A` | ✓ Resolved |
| 4 | §6.7 Phase 4 activity 4 | 1613 | `V-ADDCAP-01/02/03/03b/04..16.` | ✓ Resolved |
| 5 | §10 Gate E2 summary row | 1931 | `V-ADDCAP-01/02/03/03b/04..16 pass on Fixture A` | ✓ Resolved |
| 6 | §15 commit list | — | No V-ADDCAP enumeration in §15 (commit list only) | ✓ N/A |

**Coverage of V-ADDCAP-03b in verification path:**
- Gate E2 entry criterion 4 **explicitly** requires V-ADDCAP-03b to pass.
- Phase 4 activity 4 **explicitly** includes V-ADDCAP-03b in the battery.
- §10 summary row for Gate E2 **explicitly** lists V-ADDCAP-03b.

Therefore the role-dimension coverage that F2 was designed to
protect is guaranteed by three independent gate mechanisms. The
functional defect is closed.

**NIT-1 (non-blocking).** Line 1472 still uses the compact form
`V-ADDCAP-01..08 run.` inside the C-046-ADD-01 smoke-test
verification block. The same interpretation concern the original
review raised against "01..16" technically applies: a pedantic
reader may treat "01..08" as a contiguous eight-test sequence that
skips 03b. Recommend changing to
`V-ADDCAP-01/02/03/03b/04/05/06/07/08 run.` (or equivalent
explicit enumeration) for consistency with the five other call
sites now in explicit form.

Impact of leaving NIT-1 as-is: zero at Gate E2 and Gate F, because
the three explicit enumerations above compel V-ADDCAP-03b to run
during the Phase 4 battery against Fixture A. The C-046-ADD-01
verification block is a per-commit smoke test whose intent is
"script parses + flows through stages on a representative test
set" — not the exhaustive V-ADDCAP battery.

**Verdict:** F2 resolved. NIT-1 is a stylistic consistency
recommendation, not a blocker.

---

### F3 — detect.sh function count (MINOR) — **RESOLVED**

**Prior defect.** §6.7 activity 3 listed eight function tests; Gate
F entry criterion 4 said "all **nine** function tests." Eight vs.
nine mismatch.

**Current state:**
- §6.7 activity 3 (lines 1574–1599): enumerates **eight** functions
  with input/expected-output pairs —
  `detect_clean_working_tree`, `detect_git_repo`, `detect_pack_path`,
  `detect_pack_version`, `detect_ai_config`, `detect_x_files`,
  `detect_improperly_added_files`, `detect_installed_capabilities`
  (Phase 3-AC). ✓
- Gate F entry criterion 4 (line 1640): `detect.sh unit-test harness
  passes all **eight** function tests.` ✓
- §10 Gate F summary row (line 1932): `detect.sh unit tests (B5)
  pass all **eight** functions` — new consistency touch, not
  previously noted. ✓

**Cross-check against V10-DESIGN §7.2.** Design enumerates seven
base `detect_*` functions plus `detect_installed_capabilities`
added in Phase 3-AC, total eight. Plan now matches design.

**Verification of no drift elsewhere.** `grep -nE "nine|eight"`
returned four lines:
- Line 1145: "eight stages S0–S7" (migration script, unrelated) ✓
- Line 1384: "All nine `validate-pack.py` checks active and
  passing" (Checks 1–9; correct, unrelated to detect.sh) ✓
- Line 1640: "eight function tests" ✓
- Line 1932: "eight functions" ✓

No stale "nine" reference to detect.sh survives.

**Verdict:** F3 fully resolved.

---

### F4 — Standalone deferred-items table (MINOR) — **RESOLVED**

**Prior defect.** §6.9 Phase 6 step 2 was rendered as inline
bullets; the review criterion required a standalone table.

**Current state.** §6.9 step 2 (lines 1749–1757) is now a markdown
table with four columns:

| Column | Header text | Purpose |
|---|---|---|
| 1 | `V10-DESIGN §` | Source section |
| 2 | `Item` | Short description of the deferred item |
| 3 | `Resolution target` | Gate or future version where resolved |
| 4 | `Status at ship` | Whether item is v10.0 scope |

Five rows covering §13.1, §13.2, §13.3, §13.4, §13.6 — matching
the item set identified in the prior review's suggested template.
§13.5 (catch-all resolution list) is not cited; consistent with
prior review's note that §13.5 is not required.

**Verdict:** F4 fully resolved. Table structure matches the
template proposed in the prior review verbatim (column headers,
row order, resolution-target/status-at-ship semantics).

---

### A3 — scripts/ distinction pack-repo vs. project — **RESOLVED**

**Prior defect.** §5.1 Fixture A did not explicitly distinguish
between pack-repo scripts (`init-project.sh`, `migrate-v9-to-v10.sh`,
`add-capability.sh`) and project-level scripts (bootstrap, test,
format, validate) copied into the fixture.

**Current state.** §5.1 "Files counted on creation" (lines 402–405)
adds an explicit note:

> `scripts/` with v10 project-level scripts (bootstrap, validate,
> test, format, etc.) and `agent-run.sh` executable. **Note:
> pack-repo scripts (`init-project.sh`, `migrate-v9-to-v10.sh`,
> `add-capability.sh`) are invoked against the fixture by absolute
> `$PACK` path, never copied in.**

Matches the template suggested in the prior review (A3 action).
Placement is consistent with surrounding bullets; no unrelated
text disturbed.

**Verdict:** A3 fully resolved.

---

### A4 — v9.3 tag precondition in Fixture B — **RESOLVED**

**Prior defect.** §5.2 ran `git -C "$PACK" worktree add "$TMP" v9.3`
without documenting the tag precondition.

**Current state.** §5.2 Fixture B script (lines 442–446) now
includes:

```bash
# Precondition: v9.3 tag must exist in $PACK. If absent:
#   git -C "$PACK" fetch --tags
# Check out v9.3 pack contents into temp to source files from
TMP=$(mktemp -d)
git -C "$PACK" worktree add "$TMP" v9.3
```

The precondition is inlined as a bash comment immediately before
the worktree-add call — better ergonomics than the prior review's
alternative of a prose pre-condition line, because it is visible
at execution time if the script fails. The `fetch --tags` recovery
step is named explicitly.

**Verdict:** A4 fully resolved.

---

## 2. Regression sweep

Checked that fixes did not introduce new defects:

1. **Plan length.** Prior: 2,149 lines. Current: 2,157 lines.
   Net +8 lines, consistent with the scope of fixes (regex comments,
   table conversion, two advisory notes, V-ADDCAP-03b insertions).
   No large rewrites.

2. **Section heading stability.** `grep "^## "` returns 17 top-level
   sections, same as v2 prior state. No renumbering. Part 8 row
   coverage table (§16) and BD-item coverage table (§17) unchanged
   in structure.

3. **Commit-ID stability.** All C-045-*, C-046-*, C-046-ADD-*,
   C-044-*, S-* IDs preserved. Dependency chain unchanged. §15
   commit list still 33 rows.

4. **V-ADDCAP enumeration consistency.** Every call site that was
   changed uses the same form `V-ADDCAP-01/02/03/03b/04..16`.
   No site uses a third form (e.g., "01..03, 03b, 04..16" or
   "01..16 plus 03b"). Consistency is clean — aside from the
   NIT-1 item at line 1472 which uses a different compact range
   "01..08".

5. **F3 count consistency.** §10 Gate F summary row (line 1932) was
   updated alongside the §6.7 Gate F entry criterion (line 1640)
   to say "eight" — the fixer tracked the second call site and
   kept them synchronized. No single-site fix left behind.

6. **F4 table placement.** The new table at lines 1751–1757 sits
   between numbered list item 1 (OT project migration) and list
   item 3 (v10.x planning). Item 2's intro line "Deferred-item
   follow-through:" remains; list nesting is correct.

7. **Fixture A script integrity.** The A3 insertion is in the
   asserted-files bullet list (prose), not in the bash script
   body. The bash script block (lines 276–392) is byte-identical
   in its operational commands to the prior state. No script
   was modified.

8. **Fixture B script integrity.** The A4 insertion is a three-line
   bash comment block immediately before `TMP=$(mktemp -d)`. No
   operational commands altered. `trap`, `cp`, `awk`, profile
   switches all unchanged.

9. **Trinity rule (pack self-audit).** No trinity-governed file in
   `project-template/` was modified by this fix pass. This review
   is purely against a maintenance-docs document.

10. **CLAUDE.md pack-repo rules compliance.** Fixes confined to
    `maintenance-docs/v10-working/` — permitted scope per
    CLAUDE.md "What agents may modify." No BACKLOG.md, README.md,
    PACK-CHAT.md, or trinity edits. ✓

No regression detected.

---

## 3. Remaining advisory items (out of scope for this fix pass, for clarity)

The following items from the prior review were **not** in the
declared fix scope (F1–F4 + A3 + A4) and remain open:

- **A1** — Cite V10-DESIGN §12.5 at C-046-ADD-02 v1-to-v2 note.
  Status at this review: still not cited. Not blocking.
- **A2** — Fixture B `--with-x-files` body elision (line 508,
  `: # (content elided for brevity; identical to §5.1 --with-x-files
  block)`). Still elided. Not blocking but a Phase-4 implementer
  will need to inline the block from §5.1 when running V-X-PRESERVE
  or V-M1-CUSTOM tests.
- **A5** — §2 principle 7's assertion about MIGRATION-v8-to-v9.md
  annotation vs. C-046-09/10's actual scope. Unchanged. Not blocking.
- **A6** — Compact "N..M" enumeration preference for V-ADDCAP.
  Partially addressed by F2 (five call sites now explicit); NIT-1
  at line 1472 is the residual A6 case.

None of A1/A2/A5/A6 block Phase 4 execution. They are plan-quality
observations to resolve at implementer discretion or in a future
docs-only touch-up.

---

## 3.bis Residual nit (introduced as a byproduct of the F2 fix)

### NIT-1 — C-046-ADD-01 verification block still uses compact range

**Location.** Plan line 1472.

**Current text.**

```
- V-ADDCAP-01..08 run.
```

**Observation.** The same interpretation ambiguity that triggered
F2 for "V-ADDCAP-01..16" (is 03b in or out?) applies in miniature
to "V-ADDCAP-01..08." The F2 fix pass correctly rewrote five of the
six "01..16" call sites to explicit form but left this smaller
compact range as-is.

**Why this is not a blocker.** V-ADDCAP-03b coverage is guaranteed
by three explicit gate enumerations further downstream (Gate E2
criterion 4 line 1548, Phase 4 activity 4 line 1613, §10 E2
summary line 1931). The C-046-ADD-01 block at line 1472 is a
per-commit smoke test, not the comprehensive V-ADDCAP battery.
Even if the implementer reads "01..08" as excluding 03b at commit
time, the role-dimension test still fires at Gate E2 against
Fixture A before the gate can be approved.

**Suggested fix (opportunistic, not blocking).** Change line 1472
from `- V-ADDCAP-01..08 run.` to
`- V-ADDCAP-01/02/03/03b/04/05/06/07/08 run.` This removes the
last enumeration ambiguity and brings C-046-ADD-01's smoke tests
into style parity with the other five sites.

---

## 4. Part 8 row coverage recheck

The prior review audited §16 row-by-row coverage and confirmed every
row 1–84 has a committed home. This fix pass did not alter any
commit's Part 8 row assignment. Spot-checked §16 table
(lines 2108–2118):
- §8.2.1 rows 1–10 → unchanged ✓
- §8.2.2 rows 11–23 → unchanged ✓
- §8.2.2 sweep rows 24–37 → unchanged ✓
- §8.2.3 rows 38–43 → unchanged ✓
- §8.2.4 rows 44–48 → unchanged ✓
- §8.2.5 rows 49–55 → unchanged ✓
- §8.2.6 rows 56–61 → unchanged ✓
- §8.2.7 rows 62–66 → unchanged ✓
- §8.2.8 rows 78–84 → unchanged ✓
- §8.3 rows 67–77 → unchanged (runtime) ✓

No row was orphaned or re-homed by the fix pass.

---

## 5. Consistency spot-checks (confirmed intact)

1. Trinity rule commits (C-045-01, C-046-03) remain TRIO. ✓
2. validate-pack.py Check 6/7/8/9 sequencing unchanged. ✓
3. `x-` invariant (pack ships zero `x-` files; fixtures seed them
   against project dirs only) preserved in Fixture A (§5.1) and
   Fixture B (§5.2). ✓
4. Commit-message format (`feat: v10 — BD-NNN …` / `docs: …` /
   `fix: …`) unchanged in §15 commit list and in all §6 commit
   entries. ✓
5. Gate structure (A / B / C / D / E / E2 / F / Ship) entry-criterion
   counts unchanged except for the text edits at F3 and F4
   locations. ✓
6. Risk table §13 unchanged (R1–R20 still covered). ✓
7. New-file content-source map §11 unchanged. ✓
8. Worktree strategy §4.1 unchanged. ✓

---

## 6. Summary

| Finding | Severity | Status in v2 (post-fix) |
|---|---|---|
| **F1** — Renumbering sweep Dimension 2 regex incomplete | MAJOR | ✅ Resolved |
| **F2** — V-ADDCAP-03b omitted | MAJOR | ✅ Resolved (NIT-1 residual) |
| **F3** — detect.sh function count inconsistency | MINOR | ✅ Resolved |
| **F4** — No standalone deferred-items table | MINOR | ✅ Resolved |
| **A3** — scripts/ distinction | advisory | ✅ Resolved |
| **A4** — v9.3 tag precondition | advisory | ✅ Resolved |
| **A1** — §12.5 citation at C-046-ADD-02 | advisory | Not in scope; still open |
| **A2** — Fixture B `--with-x-files` elision | advisory | Not in scope; still open |
| **A5** — Principle 7 vs. C-046-09/10 scope | advisory | Not in scope; still open |
| **A6** — Compact "N..M" enumeration preference | advisory | Mostly resolved; NIT-1 is residual |
| **NIT-1** — Line 1472 `V-ADDCAP-01..08` compact | nit | New (consistency-only); non-blocking |

**Blockers to Phase 4 execution: none.**

**Recommendation:**
1. Approve the plan for Phase 4 execution.
2. Optionally fix NIT-1 in a follow-up docs pass at any time before
   ship (or never — it does not change behavior).
3. Consider addressing A1/A2/A5 at implementer's discretion during
   Phase 4 — none blocks any gate.

---

## 7. Final verdict

**APPROVED.**

The plan satisfies every must-fix finding from the prior review.
The two targeted advisory items (A3, A4) are resolved. No
regressions were introduced. The remaining nit (NIT-1) does not
compromise V-ADDCAP-03b coverage because three downstream gate
enumerations guarantee it runs at Phase 4. Phase 4 may begin.

---

*End of re-review report.*
