# IMPLEMENTATION-REPORT-BD-179-FIX-3

**BD:** BD-179 (pack-ops/ bare cross-reference scanner — Check 40)
**Scope:** PACK-REVIEW-BD-179.md §3.3 SHOULD-3 + §5 CF-2 (comprehensive
README inventory sweep covering the BD-175 → BD-179 batch's accumulated
staleness).
**Pre-fix HEAD:** `13feef3` (`docs: v11 — BD-179 survey report (Phase 1
print-only run; 160 bare-refs detected)`)
**Branch:** v11-dev
**Date:** 2026-05-20

---

## §1 Problem restatement

Per `PACK-REVIEW-BD-179.md` §3.3 SHOULD-3 and §5 carry-forward
observation 2 (CF-2):

- `README.md` v11.0 version-table row (L60) and Repository Layout
  `validate-pack.py` row (L195) both claim **"33 invoked checks (31
  numbered Check 1–11 and 16–35; 2 unnumbered informational"**, which
  was stale BEFORE BD-179 (Check 36/37/38 added by BD-175 Commit 12;
  Check 39 added by BD-175 F2a) and is more stale at HEAD `13feef3`
  (Check 40 added by BD-179).
- The Repository Layout test-script inventory at L237 lists only
  `test-validate-pack-checks-32-33-34.sh` from the
  `scripts/tests/test-validate-pack-check-*` family; it omits
  `test-validate-pack-checks-36-37-38.sh` (BD-175 Commit 12),
  `test-validate-pack-check-39.sh` (BD-175 F2a), and
  `test-validate-pack-check-40.sh` (BD-179).
- L60 also claims **"aggregate CI test runner across 17 suites"** —
  the actual CI workflow at `.github/workflows/validate-pack.yml` now
  invokes 35 `bash scripts/tests/*.sh` suites.

Pack-root `CLAUDE.md` "What this repo is" names `README.md`'s
"Repository Layout section" as the authoritative reference for repo
layout; staleness there is a discoverability defect for every new
contributor or reviewer.

---

## §2 Source-of-truth verification

### §2.1 Enumeration of invoked checks in `scripts/validate-pack.py`

Source: `grep -nE "── Check [0-9]+:" scripts/validate-pack.py` and
`grep -oE "── Check [0-9]+:" scripts/validate-pack.py | sort -u`.

**Numbered checks at HEAD `13feef3` — 36 distinct:**

| # | Check | Source line(s) |
|---|---|---|
| 1 | SKILL.md frontmatter | `validate-pack.py:324, :327` |
| 2 | Codex TOML files | `validate-pack.py:366, :369` |
| 3 | TD-TBD sentinels | `validate-pack.py:385, :388` |
| 4 | README version table vs git tag | `validate-pack.py:409, :412` |
| 5 | Agent file count consistency | `validate-pack.py:460, :463` |
| 6 | Prompts-directory format | `validate-pack.py:505, :508` |
| 7 | Pack agent roster | `validate-pack.py:617, :620` |
| 8 | Reserved `x-` prefix | `validate-pack.py:670, :673` |
| 9 | Init-project structure (BD-044) | `validate-pack.py:689, :692` |
| 10 | Prompt template triad compliance | `validate-pack.py:764, :767` |
| 11 | Pack agent trinity-rule symmetry (informational) | `validate-pack.py:855` |
| 16 | Trinity `## Project` addenda H2 (BD-059) | `validate-pack.py:1607` |
| 17 | Tool-config AGENT_CAPABILITIES parity (BD-059) | `validate-pack.py:947` |
| 18 | Trinity H2 structure parity (BD-059) | `validate-pack.py:1316` |
| 19 | Trinity templates free of body scaffolding (BD-059) | `validate-pack.py:1270` |
| 20 | Pack `.gitignore` `!.env.example` exception (BD-059) | `validate-pack.py:1223` |
| 21 | Pack-help per-CLI parity (BD-082) | `validate-pack.py:1645` |
| 22 | Help-fragment freshness (BD-082) | `validate-pack.py:1719` |
| 23 | Help-fragment completeness (BD-082) | `validate-pack.py:1804` |
| 24 | HELP-FRAGMENT-TRACKER byte-identity (BD-082, DELTA L1) | `validate-pack.py:1998` |
| 25 | Customization-detection regression guard (BD-089) | `validate-pack.py:1870` |
| 26 | BD-119 migrator-framework inventory | `validate-pack.py:2014, :2049` |
| 27 | Agent canonical-phrase compliance (v10.1) | `validate-pack.py:1456` |
| 28 | PM-startup per-CLI parity (v10.1, BD-126) | `validate-pack.py:2192` |
| 29 | Tracker-config schema (BD-078) | `validate-pack.py:2273, :2551` |
| 30 | Recommendation-state JSON schema (BD-079) | `validate-pack.py:2569, :2617` |
| 31 | Skill-cell consistency (BD-146, v11) | `validate-pack.py:2680, :2754` |
| 32 | per-entry mirror is in-sync with per-entry tree (BD-168) | `validate-pack.py:2877, :2949` |
| 33 | per-entry `_toc.md` is in-sync with per-entry tree (BD-168) | `validate-pack.py:3117, :3134` |
| 34 | cross-reference integrity (BD-168) | `validate-pack.py:3260, :3348` |
| 35 | Phase-task lib invariants (BD-106) | `validate-pack.py:3455, :3482` |
| 36 | Commit-scope honesty (BD-175, M5a) | `validate-pack.py:3777` |
| 37 | Project-side pack-only deny-list (BD-175, M5b) | `validate-pack.py:4021` |
| 38 | Pack-only-file siting (BD-175, M5c) | `validate-pack.py:4135` |
| 39 | `cmd_update` mapping/glob symmetry (BD-175, F2a) | `validate-pack.py:4200, :4275` |
| 40 | pack-ops/ bare cross-reference scanner (BD-179) | `validate-pack.py:4333, :4562` |

**Retired (per v9 sunset):** Checks 12, 13, 14, 15 — no `── Check 12:`
.. `── Check 15:` headings exist in `validate-pack.py`.

**Unnumbered informational checks at HEAD — 2:**

| Check (description) | Source line |
|---|---|
| Issue-template-forms (BD-064 informational guard, per L33–35 README pre-existing note) | (no `── Check NN:` line — invoked under the BD-064 informational helper) |
| Template archive v11.0 integrity (BD-064; informational) | `validate-pack.py:1153` (`print("\n── Check: Template archive v11.0 integrity (BD-064; informational) ──")`) |

**Total invoked = 36 numbered + 2 unnumbered informational = 38.**

The number range "Check 1–11 and 16–40" covers every numbered check;
Checks 12–15 remain retired per v9 sunset (string preserved).

### §2.2 Enumeration of test scripts in `scripts/tests/`

Source: `ls scripts/tests/*.sh`. Count: **39 `.sh` files**.

Of those, the three that are new since the README's staleness baseline
and that this fix adds to the inventory:

- `scripts/tests/test-validate-pack-checks-36-37-38.sh` — added by
  BD-175 Commit 12 (pack/project boundary tests).
- `scripts/tests/test-validate-pack-check-39.sh` — added by BD-175
  F2a (`cmd_update` mapping/glob symmetry).
- `scripts/tests/test-validate-pack-check-40.sh` — added by BD-179
  (pack-ops/ bare cross-reference scanner).

### §2.3 CI suite count in `.github/workflows/validate-pack.yml`

Source: `grep -c "run: bash scripts/tests/"
.github/workflows/validate-pack.yml`. Count: **35 invocations**.

Note: the workflow file itself is staged as a modified working-tree
file at HEAD `13feef3` (per pre-flight `git status`) carrying the 3
CI rows for the new test scripts; the count of 35 reflects the
working-tree state, which is the same state the README inventory
now describes. This is the BD-179 SHOULD-1 fix-coder's work
(parallel coder, disjoint scope).

The previous "17 suites" value would have been correct at the
BD-141..BD-168 era; it was already stale before BD-179 and is
now an order-of-magnitude undercount.

---

## §3 Files modified — diff stat

```
README.md  |  6 +++---
```

Three single-line region edits, all in `README.md`. No other files
modified.

- L60 (v11.0 version-table row Key Additions cell): in-place rewrite
  of the validate-pack.py inventory sub-clause + "aggregate CI test
  runner" suite count.
- L195 (Repository Layout `validate-pack.py` row): in-place rewrite
  of the inventory parenthetical.
- L237 area (Repository Layout test-script inventory row group):
  3 inserted lines after the existing
  `test-validate-pack-checks-32-33-34.sh` row.

---

## §4 Per-update audit

### §4.1 L60 (Version History → v11.0 row → Key Additions cell)

**README.md cross-reference:** § "Version History" → table row
`v11.0   | May 2026     | ...`.

**Before (inventory sub-clause):**

> validate-pack.py expanded to 33 invoked checks (31 numbered Check
> 1–11 and 16–35; 2 unnumbered informational — issue-template-forms
> and template-archive-v11; Checks 12–15 retired per v9 sunset) —
> per-CLI parity, help-fragment freshness/completeness, byte-identity,
> customization regression guard, BD-146 Check 31 skill-cell
> internal-consistency gate, BD-168 Checks 32/33/34 per-entry split
> validators (mirror-in-sync, TOC-in-sync, cross-reference integrity);
> aggregate CI test runner across 17 suites

**After:**

> validate-pack.py expanded to 38 invoked checks (36 numbered Check
> 1–11 and 16–40; 2 unnumbered informational — issue-template-forms
> and template-archive-v11; Checks 12–15 retired per v9 sunset) —
> per-CLI parity, help-fragment freshness/completeness, byte-identity,
> customization regression guard, BD-146 Check 31 skill-cell
> internal-consistency gate, BD-168 Checks 32/33/34 per-entry split
> validators (mirror-in-sync, TOC-in-sync, cross-reference integrity),
> BD-175 Checks 36/37/38 pack/project boundary (commit-scope honesty,
> project-side pack-only deny-list, pack-only-file siting) + Check 39
> cmd_update mapping/glob symmetry, BD-179 Check 40 pack-ops/ bare
> cross-reference scanner; aggregate CI test runner across 35 suites

**Cross-checks against source-of-truth:**

- `38 invoked checks` ← §2.1 (36 numbered + 2 unnumbered informational
  = 38).
- `36 numbered Check 1–11 and 16–40` ← §2.1 enumeration; range is
  contiguous within `[1,11] ∪ [16,40]`.
- `2 unnumbered informational — issue-template-forms and
  template-archive-v11` ← preserved verbatim from prior text (still
  accurate per §2.1).
- `Checks 12–15 retired per v9 sunset` ← preserved verbatim (still
  accurate; no Check 12–15 heading exists in `validate-pack.py`).
- `BD-175 Checks 36/37/38 ... + Check 39` and `BD-179 Check 40` ←
  new prose extending the existing "BD-146 Check 31 ..., BD-168
  Checks 32/33/34 ..." enumeration pattern, matching the historical
  attribution discipline.
- `aggregate CI test runner across 35 suites` ← §2.3
  (`grep -c "run: bash scripts/tests/"
  .github/workflows/validate-pack.yml` = 35).

### §4.2 L195 (Repository Layout → `scripts/` block → `validate-pack.py` row)

**README.md cross-reference:** § "Repository Layout" → `scripts/`
sub-tree → `validate-pack.py` row.

**Before:**

> ├── validate-pack.py                        CI structural validation
> (33 invoked checks — 31 numbered Check 1–11 and 16–35; 2 unnumbered
> informational — issue-template-forms and template-archive-v11;
> Checks 12–15 retired per v9 sunset; pack-internal)

**After:**

> ├── validate-pack.py                        CI structural validation
> (38 invoked checks — 36 numbered Check 1–11 and 16–40; 2 unnumbered
> informational — issue-template-forms and template-archive-v11;
> Checks 12–15 retired per v9 sunset; pack-internal)

**Cross-checks:** identical to §4.1 — `38 invoked checks`, `36
numbered Check 1–11 and 16–40`, retired-12-15 preserved, unnumbered-
informational preserved. (Row keeps the trailing `; pack-internal)`
marker.)

### §4.3 L237 area (Repository Layout → test-script inventory rows)

**README.md cross-reference:** § "Repository Layout" → bottom of
`scripts/` block, the flat test-script inventory rows between
`scripts/tests/test-migrate-v10-to-v11-gates.sh` and
`.github/workflows/`.

**Before (single matching row in family):**

> scripts/tests/test-validate-pack-checks-32-33-34.sh  BD-168 tests —
> per-entry split validators (mirror/TOC/cross-ref)

**After (added 3 rows):**

> scripts/tests/test-validate-pack-checks-32-33-34.sh  BD-168 tests —
> per-entry split validators (mirror/TOC/cross-ref)
> scripts/tests/test-validate-pack-checks-36-37-38.sh  BD-175 Commit
> 12 tests — pack/project boundary (commit-scope honesty, project-
> side pack-only deny-list, pack-only-file siting)
> scripts/tests/test-validate-pack-check-39.sh         BD-175 F2a
> tests — cmd_update mapping/glob symmetry (install-coverage gate)
> scripts/tests/test-validate-pack-check-40.sh         BD-179 tests —
> pack-ops/ bare cross-reference scanner

**Cross-checks against source-of-truth:**

- All three new filenames exist as `.sh` files under `scripts/tests/`
  per §2.2 `ls scripts/tests/` enumeration.
- BD attribution matches the SHOULD-3 finding text in `PACK-REVIEW-
  BD-179.md` §3.3 + the per-BD descriptions in `validate-pack.py`'s
  Check 36 / 37 / 38 / 39 / 40 docstring headings.
- The 3 added rows use the same flat-line format as the existing
  family member (filename + 2-space gap + BD-attribution + " — " +
  description) preserving the prose voice + structure constraint.

### §4.4 What was NOT modified

Per the prompt's "DO NOT modify" list and "Reasonable judgment
calls" guidance, the following stayed untouched:

- No other version-table rows (v10.0 .. v1) — those describe shipped
  versions; retroactive edits forbidden.
- The pre-existing L218 prose "Two additional informational checks
  (no number, soft / advisory)" remains unchanged — it is still
  accurate (2 unnumbered informational checks at HEAD per §2.1).
- The L33–35 README "Quick reference" header section listing Check
  11 as "Pack agent trinity-rule symmetry (informational): pack-roster"
  remains unchanged — Check 11 is still informational, still numbered,
  still present.
- No other `pack-ops/`, `scripts/`, `project-template/`, or doc files
  were touched.

---

## §5 Verification

### §5.1 `python3 scripts/validate-pack.py` (post-fix)

PASSED — all 38 invoked checks clean. Tail of run:

```
── Check 36: Commit-scope honesty (BD-175, M5a) ──
  OK: Check 36 — 0 scope-claiming commit(s) verified clean; 1 implicit-scope commit(s) skipped

── Check 37: Project-side pack-only deny-list (BD-175, M5b) ──
  OK: Check 37 — 146 project-side file(s) walked; zero deny-list contamination (0 anchored LEGITIMATE-context hit(s) accepted)

── Check 38: Pack-only-file siting (BD-175, M5c) ──
  OK: Check 38 — 1 pack-root prose file(s) checked; no pack-only content mis-sited outside `pack-ops/`. Exemption list: ['tracker.toml.pack-example'].

── Check 39: cmd_update mapping/glob symmetry (BD-175, F2a) ──
  OK: Check 39 — 6 `project-template/docs/pack/*.md` file(s) checked; 6 have explicit `cmd_update` mappings, 0 on exemption allowlist. No asymmetric coverage between S6 fresh-install glob and `cmd_update` explicit mappings.

── Check 40: pack-ops/ bare cross-reference scanner (BD-179) ──
  OK: Check 40 — 9 pack-ops/*.md file(s) walked; zero unqualified bare cross-references (63 allowlist-exempt + 12 anchor-phrase-exempt + 32 same-dir-legit hit(s) accepted)

============================================================
PASSED — all checks clean
```

README changes are pure prose updates inside the v11.0 row Key
Additions cell + two Repository Layout rows — no check reads
README content for inventory, so a PASS was expected and
confirmed.

### §5.2 No other behavioral change

`git diff README.md` shows exactly 3 hunks (one at L60, one at L195,
one at L235–238 region with 3 added lines). No other files were
written or read in mutating mode. No fixture rebuild was performed
(see §6 for the RC9 rationale).

---

## §6 RC9 manifest status

**Trigger fired? NO.**

RC9 trigger globs (per pack-root `CLAUDE.md` § "Regenerate
test-fixtures/manifest.txt on every v11-surface commit"): any file
under `project-template/`, `scripts/`, `pack-ops/`, or
`supporting-docs/`.

This commit modifies only `README.md`, which lives at the pack
**root** — not under any of the four RC9 trigger directories.
`README.md` is not copied into client installs by `scripts/init-
project.sh` (`grep -nE "README\.md" scripts/init-project.sh`
returns zero copy-site invocations targeting the root `README.md`).

Therefore: no `bash test-fixtures/build.sh --all --clean` rebuild
is needed. No manifest staging is required. (If Pack Chat batches
this fix-coder commit together with other parallel fix-coders that
DO touch v11-surface — e.g., BD-179 SHOULD-1 fix-coder editing
`.github/workflows/validate-pack.yml` is also outside the four
trigger dirs — Pack Chat should still re-verify RC9 status against
the combined diff before committing.)

---

## §7 Files changed inventory

| Path | Change type | Lines (insert/delete) |
|---|---|---|
| `README.md` | modified | +5 / -2 (= 3 hunks: 1 in-place version-table row replacement, 1 in-place Repository Layout row replacement, 1 three-line insertion block) |

No new files. No deletions. No renames. No fixture changes. No
script changes.

---

## §8 Plan deviations

None. The fix landed exactly the four required updates from the
caller's prompt (L60 inventory sub-clause, L60 "17 suites" count,
L195 inventory parenthetical, L237 area test-script inventory rows)
and nothing else.

---

## §9 New POQs / boundary concerns

None.

**Boundary discipline check.** The single edited file is `README.md`
at the pack repo **root**. Pack-root README is a pack-side surface
(not a project-side template, not under `project-template/`); the
edit describes pack-internal infrastructure (`scripts/validate-
pack.py`, `scripts/tests/`, `.github/workflows/`). No project-side
SSOT applies. Pack-only file siting (Check 38) confirms pack-root
prose files are correctly sited. No project-side SSOT investigation
required — pack-internal scope.

---

## §10 Definition-of-Done checklist

| Item | Status |
|---|---|
| L60 v11.0 row inventory sub-clause updated to 38 invoked / 36 numbered / range `1–11 and 16–40` | PASS |
| L60 v11.0 row extended to enumerate new check families (BD-175 Checks 36/37/38 + 39; BD-179 Check 40) | PASS |
| L60 "aggregate CI test runner" count updated from `17 suites` to `35 suites` | PASS |
| L195 Repository Layout validate-pack.py row updated to 38 invoked / 36 numbered / range `1–11 and 16–40` | PASS |
| L195 retired-12-15 note + 2 unnumbered informational note preserved verbatim | PASS |
| L237 area test-script inventory adds rows for `test-validate-pack-checks-36-37-38.sh`, `test-validate-pack-check-39.sh`, `test-validate-pack-check-40.sh` | PASS |
| Existing prose voice + structure preserved (no stylistic rewrites) | PASS |
| Only `README.md` modified | PASS |
| `python3 scripts/validate-pack.py` PASS | PASS |
| RC9 manifest trigger not fired (README is at pack root, not under v11-surface dirs) | PASS — no manifest rebuild needed |
| IMPL-REPORT cross-references actual `scripts/validate-pack.py` check enumeration as evidence | PASS — see §2.1 |
| No `git add` / `git commit` / `git push` (or any state-changing git verb) run | PASS — only read-only `git status` + `git diff` were used |

---

**End of IMPLEMENTATION-REPORT-BD-179-FIX-3.md.**
