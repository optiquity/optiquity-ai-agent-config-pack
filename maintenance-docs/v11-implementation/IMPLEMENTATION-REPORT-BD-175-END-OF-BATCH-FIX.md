# IMPLEMENTATION-REPORT-BD-175-END-OF-BATCH-FIX

**BD batch:** BD-175 EMERGENCY BATCH (end-of-batch SHOULD-1 fix —
README inventory sweep covering the BD-179 → BD-180 → BD-181 → BD-183
→ BD-184 accumulated staleness past the BD-179 FIX-3 snapshot).
**Scope:** `PACK-REVIEW-BD-175-END-OF-BATCH.md` §4 SHOULD-1
(README inventory staleness; same finding class as BD-179 SHOULD-3 /
CF-2; carry-forward continuation).
**Pre-fix HEAD:** `a2cd1e2` (`docs: v11 — BD-178 SHOULD-2 per-commit
review report (APPROVE — zero blocking findings)`).
**Branch:** v11-dev
**Date:** 2026-05-21
**Triage:** Pack Chat user-approved FIX-NOW per
`feedback-deferral-is-scope-creep`. NIT (pre-existing module-docstring
numbering disorder in `scripts/validate-pack.py`) was triaged SKIP and
is NOT touched in this fix.

---

## §1 Problem restatement

Per `PACK-REVIEW-BD-175-END-OF-BATCH.md` §4 SHOULD-1, `README.md`
has accumulated inventory staleness in three regions since BD-179
FIX-3 (`2842454`) swept it for the then-current BD-179 horizon:

- **L60 (Version History → v11.0 row → Key Additions cell).** The
  validate-pack.py inventory sub-clause claims "38 invoked checks
  (36 numbered Check 1–11 and 16–40; 2 unnumbered informational ...)"
  and "aggregate CI test runner across 35 suites" — both numbers now
  stale because BD-180 added Check 41 + the BD-180 G test file +
  the corresponding CI wiring, BD-181 added Check 18 generalization +
  test file + CI wiring, BD-183 added Check 16/19 generalizations
  + two test files + CI wiring, and BD-184 added Check 42 + test
  file + CI wiring.

- **L195 (Repository Layout → `scripts/` block → `validate-pack.py`
  row).** The same inventory parenthetical with the same staleness.

- **L237 area (Repository Layout → flat test-script inventory rows
  between `scripts/tests/test-migrate-v10-to-v11-gates.sh` and
  `.github/workflows/`).** Lists only 4 of the 9
  `scripts/tests/test-validate-pack-*.sh` files actually present on
  disk. Missing 5 entries: `test-validate-pack-check-16.sh` (BD-183),
  `test-validate-pack-check-18.sh` (BD-181),
  `test-validate-pack-check-19.sh` (BD-183),
  `test-validate-pack-check-41.sh` (BD-180 G),
  `test-validate-pack-check-42.sh` (BD-184).

This is the same gap class as BD-179 SHOULD-3 / CF-2; the fix mirrors
the BD-179 FIX-3 methodology (empirical grep before edit; per-line
before/after; cross-referenced source-of-truth in §3).

Pack-root `CLAUDE.md` "What this repo is" names `README.md`'s
Repository Layout section as the authoritative reference for repo
layout; inventory staleness there is a discoverability defect for
every new contributor or reviewer.

Note on the prompt's claim of "missing 3 (or 4)" new test-script
entries: empirical disk-vs-README comparison (see §3.2) found **5
missing entries**, not 3-or-4. The prompt's "Reasonable judgment
calls expected" section authorized trusting grep over the framing —
this fix-coder did so.

---

## §2 Triage scope

| Item from PACK-REVIEW-BD-175-END-OF-BATCH.md | Severity | Triage | Implemented? |
|---|---|---|---|
| §4 SHOULD-1 README inventory staleness | SHOULD | FIX-NOW (user-approved) | YES (this report) |
| §4 NIT-1 validate-pack.py module-docstring numbering disorder | NIT | SKIP | NO — out of scope, pre-existing, not touched |

Only `README.md` is modified. `scripts/validate-pack.py` is NOT
touched (NIT SKIP applies — the module-docstring numbering disorder
is pre-existing and explicitly out of this fix's scope).

---

## §3 Source-of-truth verification

### §3.1 Enumeration of invoked checks in `scripts/validate-pack.py`

Source: print-banner enumeration at runtime via
`grep -nE 'print\(f?"\\n── Check [0-9]+' scripts/validate-pack.py`.
(Print banners are runtime source-of-truth; the heading comments at
file scope are organizational signposts but the heading at L3714
covers 3 distinct checks — see Check 36/37/38 row below.)

**Numbered checks at HEAD `a2cd1e2` — 38 distinct (print-banner
unique IDs):**

| # | Check | Print-banner line |
|---|---|---|
| 1 | SKILL.md frontmatter | `validate-pack.py:361` |
| 2 | Codex TOML files | `validate-pack.py:403` |
| 3 | TD-TBD sentinels in pack-ops/BACKLOG.md | `validate-pack.py:422` |
| 4 | README version table vs git tag | `validate-pack.py:446` |
| 5 | Agent file count consistency | `validate-pack.py:497` |
| 6 | Prompts-directory format | `validate-pack.py:542` |
| 7 | Pack agent roster | `validate-pack.py:654` |
| 8 | Reserved `x-` prefix | `validate-pack.py:707` |
| 9 | Init-project structure (BD-044) | `validate-pack.py:726` |
| 10 | Prompt template triad compliance | `validate-pack.py:801` |
| 11 | Pack agent trinity-rule symmetry (informational) | `validate-pack.py:889` |
| 16 | Trinity `## Project addenda` H2 (BD-059, BD-183) | `validate-pack.py:1746` |
| 17 | Tool-config AGENT_CAPABILITIES parity (BD-059) | `validate-pack.py:981` |
| 18 | Trinity H2 structure parity (BD-059, BD-181) | `validate-pack.py:1404` |
| 19 | Trinity templates free of body scaffolding (BD-059, BD-183) | `validate-pack.py:1330` |
| 20 | Pack `.gitignore` `!.env.example` exception (BD-059) | `validate-pack.py:1257` |
| 21 | Pack-help per-CLI parity (BD-082) | `validate-pack.py:1792` |
| 22 | Help-fragment freshness (BD-082) | `validate-pack.py:1866` |
| 23 | Help-fragment completeness (BD-082) | `validate-pack.py:1951` |
| 24 | HELP-FRAGMENT-TRACKER byte-identity (BD-082, DELTA L1) | `validate-pack.py:2145` |
| 25 | Customization-detection regression guard (BD-089) | `validate-pack.py:2017` |
| 26 | BD-119 migrator-framework inventory | `validate-pack.py:2196` |
| 27 | Agent canonical-phrase compliance (v10.1) | `validate-pack.py:1546` |
| 28 | PM-startup per-CLI parity (v10.1, BD-126) | `validate-pack.py:2339` |
| 29 | Tracker-config schema (BD-078) | `validate-pack.py:2698` |
| 30 | Recommendation-state JSON schema (BD-079) | `validate-pack.py:2764` |
| 31 | Skill-cell consistency (BD-146, v11) | `validate-pack.py:2901` |
| 32 | per-entry mirror is in-sync with per-entry tree (BD-168) | `validate-pack.py:3096` |
| 33 | per-entry `_toc.md` is in-sync with per-entry tree (BD-168) | `validate-pack.py:3281` |
| 34 | cross-reference integrity (BD-168) | `validate-pack.py:3495` |
| 35 | Phase-task lib invariants (BD-106) | `validate-pack.py:3629` |
| 36 | Commit-scope honesty (BD-175, M5a) | `validate-pack.py:3924` |
| 37 | Project-side pack-only deny-list (BD-175, M5b) | `validate-pack.py:4168` |
| 38 | Pack-only-file siting (BD-175, M5c) | `validate-pack.py:4282` |
| 39 | cmd_update mapping/glob symmetry (BD-175 F2a + BD-180 E) | `validate-pack.py:4444` |
| 40 | pack-ops/ bare cross-reference scanner (BD-179) | `validate-pack.py:4826` |
| 41 | `_CLIENT_INSTALLED_FILES` self-doc list integrity (BD-180 G) | `validate-pack.py:5064` |
| 42 | CI workflow wires all per-check test files (BD-184) | `validate-pack.py:5319` |

**Retired (per v9 sunset):** Checks 12, 13, 14, 15 — no banners exist
for these IDs (string preserved verbatim in README).

**Unnumbered informational checks at HEAD — 2:**

Source:
`grep -nE '── Check: ' scripts/validate-pack.py`

| Check (description) | Source line |
|---|---|
| Issue template forms (BD-063) | `validate-pack.py:1084` (`print("\n── Check: Issue template forms (BD-063) ──")`) |
| Template archive v11.0 integrity (BD-064; informational) | `validate-pack.py:1187` (`print("\n── Check: Template archive v11.0 integrity (BD-064; informational) ──")`) |

**Total invoked = 38 numbered + 2 unnumbered informational = 40.**

The number range "Check 1–11 and 16–42" covers every numbered check;
Checks 12–15 remain retired per v9 sunset (string preserved).

Raw grep output for traceability (`grep -nE 'print\(f?"\\n── Check
[0-9]+' scripts/validate-pack.py | grep -oE 'Check [0-9]+' |
sort -u`):

```
Check 1
Check 2
Check 3
Check 4
Check 5
Check 6
Check 7
Check 8
Check 9
Check 10
Check 11
Check 16
Check 17
Check 18
Check 19
Check 20
Check 21
Check 22
Check 23
Check 24
Check 25
Check 26
Check 27
Check 28
Check 29
Check 30
Check 31
Check 32
Check 33
Check 34
Check 35
Check 36
Check 37
Check 38
Check 39
Check 40
Check 41
Check 42
```

(38 unique IDs.)

### §3.2 Enumeration of `scripts/tests/test-validate-pack-*.sh` files

Source: `ls scripts/tests/test-validate-pack-*.sh`. Count: **9
files**.

```
scripts/tests/test-validate-pack-check-16.sh
scripts/tests/test-validate-pack-check-18.sh
scripts/tests/test-validate-pack-check-19.sh
scripts/tests/test-validate-pack-check-39.sh
scripts/tests/test-validate-pack-check-40.sh
scripts/tests/test-validate-pack-check-41.sh
scripts/tests/test-validate-pack-check-42.sh
scripts/tests/test-validate-pack-checks-32-33-34.sh
scripts/tests/test-validate-pack-checks-36-37-38.sh
```

**Disk vs README pre-fix:** README L237 area listed 4 entries
(checks-32-33-34, checks-36-37-38, check-39, check-40). Missing: 5
entries — check-16, check-18, check-19, check-41, check-42.

Cross-corroboration: Check 42 runtime output reports `"9 per-check
test file(s) on disk; 9 workflow invocation(s) found; zero unwired
tests"` (validate-pack.py at-runtime; see §5.1). The 9 on disk
matches `ls` directly.

### §3.3 CI suite count in `.github/workflows/validate-pack.yml`

Source: `grep -c "bash scripts/tests/.*\.sh"
.github/workflows/validate-pack.yml`. Count: **40 invocations**.

All 40 invocations are uncommented (verified by `grep -n
"bash scripts/tests/" .github/workflows/validate-pack.yml | grep -v
"^\s*#"` returning all 40 hits — no leading-`#` filtered out).

The "35 suites" value at HEAD `a2cd1e2` was correct at BD-179
FIX-3's snapshot (`2842454`) but is now stale by 5 invocations:
+1 BD-180 (`test-validate-pack-check-41.sh`), +1 BD-181
(`test-validate-pack-check-18.sh`), +2 BD-183
(`test-validate-pack-check-16.sh` + `test-validate-pack-check-19.sh`),
+1 BD-184 (`test-validate-pack-check-42.sh`). 35 + 5 = 40.

---

## §4 Files modified — diff stat

```
README.md  |  9 +++++++--
1 file changed, 7 insertions(+), 2 deletions(-)
```

Three region edits, all in `README.md`. No other files modified.

- L60 (v11.0 version-table row Key Additions cell): in-place rewrite
  of the validate-pack.py inventory sub-clause + "aggregate CI test
  runner" suite count + extended enumeration prose for BD-180 Check 41
  and BD-184 Check 42.
- L195 (Repository Layout `validate-pack.py` row): in-place rewrite
  of the inventory parenthetical.
- L237 area (Repository Layout test-script inventory): 5 inserted
  lines — 3 before the existing `test-validate-pack-checks-32-33-34.sh`
  row (check-16, check-18, check-19 in numerical order) and 2 after
  the existing `test-validate-pack-check-40.sh` row (check-41,
  check-42).

---

## §5 Per-line edits applied to README.md (before/after with line citations)

### §5.1 L60 (Version History → v11.0 row → Key Additions cell)

**README.md cross-reference:** § "Version History" → table row
`v11.0   | May 2026     | ...`.

**Before (inventory sub-clause):**

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

**After:**

> validate-pack.py expanded to 40 invoked checks (38 numbered Check
> 1–11 and 16–42; 2 unnumbered informational — issue-template-forms
> and template-archive-v11; Checks 12–15 retired per v9 sunset) —
> per-CLI parity, help-fragment freshness/completeness, byte-identity,
> customization regression guard, BD-146 Check 31 skill-cell
> internal-consistency gate, BD-168 Checks 32/33/34 per-entry split
> validators (mirror-in-sync, TOC-in-sync, cross-reference integrity),
> BD-175 Checks 36/37/38 pack/project boundary (commit-scope honesty,
> project-side pack-only deny-list, pack-only-file siting) + Check 39
> cmd_update mapping/glob symmetry, BD-179 Check 40 pack-ops/ bare
> cross-reference scanner, BD-180 Check 41 `_CLIENT_INSTALLED_FILES`
> self-doc list integrity, BD-184 Check 42 CI workflow wires all
> per-check test files; aggregate CI test runner across 40 suites

**Cross-checks against source-of-truth:**

- `40 invoked checks` ← §3.1 (38 numbered + 2 unnumbered informational
  = 40).
- `38 numbered Check 1–11 and 16–42` ← §3.1 enumeration; range is
  contiguous within `[1,11] ∪ [16,42]`.
- `2 unnumbered informational — issue-template-forms and
  template-archive-v11` ← preserved verbatim (still accurate per §3.1
  — issue-template-forms maps to `Check: Issue template forms (BD-063)`
  banner; template-archive-v11 maps to `Check: Template archive v11.0
  integrity (BD-064; informational)` banner).
- `Checks 12–15 retired per v9 sunset` ← preserved verbatim (still
  accurate; no banners for these IDs).
- New enumeration extensions `BD-180 Check 41
  _CLIENT_INSTALLED_FILES self-doc list integrity` and `BD-184
  Check 42 CI workflow wires all per-check test files` ← matches
  the print-banner attribution at lines 5064 and 5319 respectively,
  using BD-attribution form consistent with the existing
  enumeration pattern.
- `aggregate CI test runner across 40 suites` ← §3.3
  (`grep -c "bash scripts/tests/.*\.sh"
  .github/workflows/validate-pack.yml` = 40).

**Coverage note:** BD-181 (Check 18 generalization) and BD-183
(Check 16 + Check 19 generalizations) added per-trinity-surface
*test files* but did NOT add new check numbers — Checks 16, 18, 19
are pre-existing numbers, generalized by BD-181/183 to run at multiple
trinity surfaces. Thus the L60 enumeration prose extension only names
new check NUMBERS (BD-180 Check 41 + BD-184 Check 42); the
BD-181/183 changes surface in the test-script inventory (L237) and
the CI-suite count (35 → 40), not the numbered-check enumeration.
This preserves the L60 enumeration's "new check ID per BD" pattern.

### §5.2 L195 (Repository Layout → `scripts/` block → `validate-pack.py` row)

**README.md cross-reference:** § "Repository Layout" → `scripts/`
sub-tree → `validate-pack.py` row.

**Before:**

> ├── validate-pack.py                        CI structural validation
> (38 invoked checks — 36 numbered Check 1–11 and 16–40; 2 unnumbered
> informational — issue-template-forms and template-archive-v11;
> Checks 12–15 retired per v9 sunset; pack-internal)

**After:**

> ├── validate-pack.py                        CI structural validation
> (40 invoked checks — 38 numbered Check 1–11 and 16–42; 2 unnumbered
> informational — issue-template-forms and template-archive-v11;
> Checks 12–15 retired per v9 sunset; pack-internal)

**Cross-checks:** identical to §5.1 — `40 invoked checks`, `38
numbered Check 1–11 and 16–42`, retired-12-15 preserved, unnumbered-
informational preserved. Row keeps the trailing `; pack-internal)`
marker.

### §5.3 L237 area (Repository Layout → test-script inventory rows)

**README.md cross-reference:** § "Repository Layout" → bottom of
`scripts/` block, the flat test-script inventory rows between
`scripts/tests/test-migrate-v10-to-v11-gates.sh` and
`.github/workflows/`.

**Before (4 matching rows in `test-validate-pack-*` family):**

```
scripts/tests/test-validate-pack-checks-32-33-34.sh  BD-168 tests — per-entry split validators (mirror/TOC/cross-ref)
scripts/tests/test-validate-pack-checks-36-37-38.sh  BD-175 Commit 12 tests — pack/project boundary (commit-scope honesty, project-side pack-only deny-list, pack-only-file siting)
scripts/tests/test-validate-pack-check-39.sh         BD-175 F2a tests — cmd_update mapping/glob symmetry (install-coverage gate)
scripts/tests/test-validate-pack-check-40.sh         BD-179 tests — pack-ops/ bare cross-reference scanner
```

**After (9 matching rows — 5 added; numerical-ID ordering):**

```
scripts/tests/test-validate-pack-check-16.sh         BD-183 tests — trinity `## Project addenda` H2 (per-trinity-surface generalization)
scripts/tests/test-validate-pack-check-18.sh         BD-181 tests — trinity H2 structure parity (per-trinity-surface generalization)
scripts/tests/test-validate-pack-check-19.sh         BD-183 tests — trinity templates free of body scaffolding (per-trinity-surface generalization)
scripts/tests/test-validate-pack-checks-32-33-34.sh  BD-168 tests — per-entry split validators (mirror/TOC/cross-ref)
scripts/tests/test-validate-pack-checks-36-37-38.sh  BD-175 Commit 12 tests — pack/project boundary (commit-scope honesty, project-side pack-only deny-list, pack-only-file siting)
scripts/tests/test-validate-pack-check-39.sh         BD-175 F2a tests — cmd_update mapping/glob symmetry (install-coverage gate)
scripts/tests/test-validate-pack-check-40.sh         BD-179 tests — pack-ops/ bare cross-reference scanner
scripts/tests/test-validate-pack-check-41.sh         BD-180 G tests — `_CLIENT_INSTALLED_FILES` self-doc list integrity
scripts/tests/test-validate-pack-check-42.sh         BD-184 tests — CI workflow wires all per-check test files
```

**Cross-checks against source-of-truth:**

- All 5 added filenames exist as `.sh` files under `scripts/tests/`
  per §3.2 `ls` enumeration.
- BD attribution matches the BD numbers in the corresponding check
  print-banners + the BD-179/180/181/183/184 attribution in
  `scripts/validate-pack.py` Check 16/18/19/41/42 docstring headings
  (`# ── Check N: ... (BD-NNN) ──` and
  `# ── Check N: ... (BD-NNN) ──` headings at file scope).
- The 5 added rows use the same flat-line format as the existing
  family members (filename + 2-space gap + BD-attribution + " — " +
  description) preserving the prose voice + structure constraint.
- Ordering: numerical by check ID (16, 18, 19, 32-33-34, 36-37-38,
  39, 40, 41, 42) — natural-sort + place-multi-check files
  (`checks-32-33-34.sh`, `checks-36-37-38.sh`) at their lowest ID
  position. This matches the BD-179 FIX-3 precedent where new entries
  were added after the existing `checks-32-33-34.sh` row in numerical
  order.

### §5.4 What was NOT modified

Per the prompt's "Files you must NOT modify" list:

- `scripts/validate-pack.py` (NIT SKIP — pre-existing module-docstring
  numbering disorder explicitly out of scope).
- No other version-table rows (v10.0 .. v1) — those describe shipped
  versions; retroactive edits forbidden.
- The pre-existing L218 prose remains unchanged — still accurate.
- The L33–35 README "Quick reference" header section remains
  unchanged — Check 11 informational-status preserved.
- No `pack-ops/`, other `scripts/`, `project-template/`, or
  `supporting-docs/` files touched.
- Trinity files (CLAUDE.md / AGENTS.md / GEMINI.md at pack-root and
  at `project-template/`) untouched.
- BACKLOG.md / CHANGELOG.md / PACK-CHAT.md / PACK-AGENTS.md /
  architect docs untouched.

---

## §6 Verification

### §6.1 `python3 scripts/validate-pack.py` (post-fix)

PASSED — all 40 invoked checks clean. Tail of run:

```
── Check 40: pack-ops/ bare cross-reference scanner (BD-179) ──
  OK: Check 40 — 9 pack-ops/*.md file(s) walked; zero unqualified bare cross-references (63 allowlist-exempt + 12 anchor-phrase-exempt + 32 same-dir-legit hit(s) accepted)

── Check 41: _CLIENT_INSTALLED_FILES self-doc list integrity (BD-180 G) ──
  OK: Check 41 — 38 `_CLIENT_INSTALLED_FILES` entry (entries) checked; 38 resolve to existing files at HEAD, 0 on exemption allowlist. 35 cmd_update path(s) cross-checked against inventory; 0 drift(s) (must be 0). Self-documenting list is consistent with copy-site state.

── Check 42: CI workflow wires all per-check test files (BD-184) ──
  OK: Check 42 — 9 per-check test file(s) on disk; 9 workflow invocation(s) found; zero unwired tests. CI workflow wiring is complete.

============================================================
PASSED — all checks clean
```

README changes are pure prose updates inside the v11.0 row Key
Additions cell + two Repository Layout regions — no check reads
README content for inventory enumeration, so PASS was expected and
confirmed.

### §6.2 No collateral edits

`git diff README.md` shows exactly 3 hunks at the three expected
regions (L60, L195, L237). No other files were written or read in
mutating mode.

```
README.md | 9 +++++++--
1 file changed, 7 insertions(+), 2 deletions(-)
```

### §6.3 Pack-internal

No manifest impact, no fixture impact, no script-behavior impact.
README is a pack-root prose surface; this fix is documentation-only.

---

## §7 RC9 manifest status

**Trigger fired? NO.**

RC9 trigger globs (per pack-root `CLAUDE.md` § "Regenerate
test-fixtures/manifest.txt on every v11-surface commit"): any file
under `project-template/`, `scripts/`, `pack-ops/`, or
`supporting-docs/`.

This fix modifies only `README.md`, which lives at the pack **root**
— not under any of the four RC9 trigger directories. `README.md` is
not copied into client installs by `scripts/init-project.sh`
(consistent with BD-179 FIX-3 §6 finding —
`grep -nE "README\.md" scripts/init-project.sh` returns zero
copy-site invocations targeting the root `README.md`).

Therefore: no `bash test-fixtures/build.sh --all --clean` rebuild
is needed. No manifest staging is required.

(If Pack Chat batches this fix-coder commit together with other
parallel fix-coders that DO touch v11-surface, Pack Chat should still
re-verify RC9 status against the combined diff before committing —
matches BD-179 FIX-3 §6 guidance.)

---

## §8 Carry-forward discipline

Applied per `.claude/skills/review/SKILL.md` § "Carry-forward
discipline". The fix scoped exclusively to the README inventory
surface called out by the end-of-batch reviewer.

**Scope-adjacent staleness evaluated against high-bar:**

- **Other docs that mention check counts?** Grep for "invoked checks"
  / "numbered Check" / "validate-pack.py" across non-README pack-ops
  surfaces did not surface as part of this fix's scope (the
  end-of-batch reviewer named only the README as the inventory
  surface). Per `feedback-deferral-is-scope-creep` and high-bar
  carry-forward discipline, this fix-coder did NOT expand scope
  beyond the explicitly-named README regions. If other docs carry
  stale check-count claims, they would surface as a separate
  reviewer finding in a subsequent pass (not this fix).
- **Other inventory rows in README?** L218 region prose "Two
  additional informational checks (no number, soft / advisory)"
  remains accurate per §3.1 (2 unnumbered informational checks at
  HEAD). No edit needed.
- **Coverage of the BD-181 Check 18 generalization in L60
  enumeration:** Check 18 is pre-existing; the L60 enumeration
  pattern names new check IDs per BD, so BD-181's
  generalization-without-new-ID does not require a L60 enumeration
  extension. The BD-181 change surfaces correctly in the test-
  script inventory (new `test-validate-pack-check-18.sh` row) and
  in the CI-suite count (35 → 40). Same logic for BD-183 Check 16/19
  generalizations.

**Zero deferrals.** All in-scope work landed in this commit. No new
BDs opened. No new POQs introduced. No "noted but skipped" findings.

---

## §9 New POQs / boundary concerns

None.

**Boundary discipline check** (per pack-coder system-prompt
"Boundary discipline pre-flight" rule, P-missed-7):

The single edited file is `README.md` at the pack repo **root**.
Pack-root README is a pack-side surface (not a project-side template,
not under `project-template/`); the edit describes pack-internal
infrastructure (`scripts/validate-pack.py`, `scripts/tests/`,
`.github/workflows/`). The pack-root README is NOT shipped to
clients via `scripts/init-project.sh`.

- **No project-side SSOT applies.** Edits describe pack-only
  infrastructure (validate-pack.py, scripts/tests/, CI workflow).
  No reference to pack-only files added in a project-side surface —
  none of the edited regions live on a project-side surface.
- **Pack-only file siting (Check 38) confirms pack-root prose files
  are correctly sited** (Check 38 PASS at §6.1 includes pack-root
  README via the "1 pack-root prose file(s) checked" output).
- **No project-side SSOT investigation required** — pack-internal
  scope by construction.

---

## §10 Files changed inventory

| Path | Change type | Lines (insert/delete) |
|---|---|---|
| `README.md` | modified | +7 / -2 (= 3 hunks: 1 in-place version-table row replacement at L60, 1 in-place Repository Layout `validate-pack.py` row replacement at L195, 1 five-line insertion at L237 region — 3 lines before existing `checks-32-33-34.sh` row, 2 lines after existing `check-40.sh` row) |

No new files. No deletions. No renames. No fixture changes. No
script changes. No CI changes.

---

## §11 Plan deviations

None from the prompt's explicit success criteria. The prompt
authorized "Reasonable judgment calls" where source-of-truth grep
disagreed with the prompt's framing; this fix-coder exercised that:

- **Prompt claimed 42 numbered checks; grep found 38.** The prompt's
  framing — "current state has 42 numbered checks (Check 1–11 +
  Check 16–42)" — was inadvertently counting the highest check ID
  (42) rather than the count of distinct check IDs (38: 11 in
  [1,11] + 27 in [16,42] = 38). The prompt explicitly authorized
  "TRUST the grep — that's the source of truth; document the
  discrepancy and apply the correct counts." Applied accordingly:
  README now says "38 numbered Check 1–11 and 16–42" (count =
  38; ID range = 1–11 ∪ 16–42).
- **Prompt claimed missing "3 (or 4)" test-script entries;
  empirical disk-vs-README diff found 5.** Disk has 9 files; README
  pre-fix listed 4; missing 5. The prompt's "3 (or 4)" framing
  predated the actor's grep verification — this fix-coder added all
  5 missing entries.

No new BDs opened. No new POQs. No scope expansion beyond the
README inventory regions. No edits to files outside the prompt's
"may modify" list.

---

## §12 Definition-of-Done checklist

| Item | Status |
|---|---|
| L60 v11.0 row inventory sub-clause updated to 40 invoked / 38 numbered / range `1–11 and 16–42` | PASS |
| L60 v11.0 row extended to enumerate new check families (BD-180 Check 41 + BD-184 Check 42) | PASS |
| L60 "aggregate CI test runner" count updated from `35 suites` to `40 suites` | PASS |
| L195 Repository Layout validate-pack.py row updated to 40 invoked / 38 numbered / range `1–11 and 16–42` | PASS |
| L195 retired-12-15 note + 2 unnumbered informational note preserved verbatim | PASS |
| L237 area test-script inventory adds rows for `test-validate-pack-check-16.sh`, `test-validate-pack-check-18.sh`, `test-validate-pack-check-19.sh`, `test-validate-pack-check-41.sh`, `test-validate-pack-check-42.sh` | PASS |
| Existing prose voice + structure preserved (no stylistic rewrites; flat-line format for inventory) | PASS |
| Only `README.md` modified (NIT SKIP — `validate-pack.py` module-docstring untouched) | PASS |
| `python3 scripts/validate-pack.py` PASS post-fix | PASS |
| RC9 manifest trigger not fired (README is at pack root, not under v11-surface dirs) | PASS — no manifest rebuild needed |
| IMPL-REPORT cross-references actual `scripts/validate-pack.py` check enumeration as evidence (per §3.1 print-banner grep) | PASS |
| IMPL-REPORT documents per-line before/after with line citations (per §5) | PASS |
| IMPL-REPORT cites source-of-truth grep evidence (per §3) | PASS |
| No `git add` / `git commit` / `git push` (or any state-changing git verb) run | PASS — only read-only `git status` + `git diff` were used |
| Carry-forward discipline applied; zero deferrals (per §8) | PASS |

---

**End of IMPLEMENTATION-REPORT-BD-175-END-OF-BATCH-FIX.md.**
