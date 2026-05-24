# IMPLEMENTATION-REPORT — BD-173 Batch 19c H.14 INLINE-reviewer fix (5 NITs)

**Branch:** `v11-dev`
**Base HEAD at session start:** `a6bd91d` (H.14 commit).
**Worktree HEAD at report time:** `a6bd91d` (no agent commits per pack
workflow rule; all changes in working tree).
**Triggering review:** `/tmp/PACK-REVIEW-BD-173-Batch-19c-H.14.md` —
H.14 INLINE reviewer; verdict PASS-WITH-NITS; 5 NITs.
**Triage decision (Pack Chat + user):** FIX all 5 (per user (A) decision).

---

## §1 Scope

5 NITs closed in a single fix-coder pass. Three existing files modified +
one new fix IMPL-REPORT written. No source code touched; all edits
confined to documentation surfaces.

**Files modified (3):**

| Path | NIT(s) addressed |
|---|---|
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.14.md` | N1, N2 |
| `maintenance-docs/v11-implementation/ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md` | N3, N4 |
| `README.md` | N5 |

**Files created (1):**

- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.14-fix.md` (this report)

**Scope keyword justified:** `pack-only` — no `project-template/` or
`supporting-docs/` or `scripts/` or `test-fixtures/` paths touched.
README.md sits at the pack root; the GUARDRAILS-CONTRACT.md and the
H.14 IMPL-REPORT are pack-internal maintenance-docs/.

---

## §2 Edits applied

### 2.1 N1 + N2 — H.14 IMPL-REPORT narrative count corrections

The H.14 IMPL-REPORT §2.6 sub-class table sums to **29 absorption entries**
(2 template placeholders + 3 generic basenames + 8 agent prompt
meta-refs + 5 per-entry skeleton variants + 1 custom skill placeholder +
7 legacy/generated + 3 audit-methodology examples = 29). The narrative
text throughout the report claimed "30 absorption / 61 total" — off by
one. Separately, several sites referred to "78 audit-vocabulary-gap
legitimate basenames", which conflated catch-sites and basenames — the
actual mapping is 29 distinct basenames covering 78 catch-sites in the
pre-absorption Check 43 output.

**Sites corrected (10 narrative edits across §1, §2.6, §3.1, §3.5, §6,
§7.2.1, §7.2.3, §7.4, §7.6, Closing summary):**

| Site | BEFORE excerpt | AFTER excerpt |
|---|---|---|
| §1 scope item 6 | "extended with 30 audit-vocabulary-gap legitimate entries" | "extended with 29 audit-vocabulary-gap legitimate entries[^count]" — plus new footnote naming the commit-msg discrepancy |
| §2.6 opener | "extended by 30 audit-vocabulary-gap legitimate entries" + "New entries (30 total) — appended after the existing 31 H.14 entries" | "extended by 29 audit-vocabulary-gap legitimate entries" + "New entries (29 total) — appended after the existing 31 H.14 entries — cover 78 catch-sites in pre-absorption Check 43 output" |
| §2.6 size line | "Allowlist size post-absorption: 61 entries (31 H.14 original + 30 Option C additions)" | "Allowlist size post-absorption: 60 entries (31 H.14 original + 29 Option C additions)" |
| §3.1 absorption summary | "After 30 audit-vocabulary-gap allowlist additions (Class 1) + 6 LEAK CLASS C rewrites (Class 2)" | "After 29 audit-vocabulary-gap allowlist additions (Class 1; 29 basenames covering 78 catch-sites) + 6 LEAK CLASS C rewrites (Class 2)" |
| §3.1 absorbed counts | "78 catches absorbed via allowlist tier" | "78 catch-sites (29 distinct basenames) absorbed via allowlist tier" |
| §3.2 fixture comment | "allowlist (now 61 entries)" | "allowlist (now 60 entries)" |
| §3.5 module check | "mod._CHECK_43_ALLOWLIST  # 61 entries (31 H.14 original + 30 Option C absorption)" | "mod._CHECK_43_ALLOWLIST  # 60 entries (31 H.14 original + 29 Option C absorption)" |
| §3.5 allowlist size | "Allowlist now has 61 entries (31 H.14 original — §1.4 verbatim — plus 30 Option C absorption entries covering audit-vocabulary-gap legitimates per §2.6 above)" | "Allowlist now has 60 entries (31 H.14 original — §1.4 verbatim — plus 29 Option C absorption entries covering audit-vocabulary-gap legitimates per §2.6 above; 29 basenames cover 78 catch-sites in the pre-absorption Check 43 output)" |
| §6 row 2 | "31 entries (H.14) + 30 absorption entries = 61 total" | "31 entries (H.14) + 29 absorption entries = 60 total" |
| §6 row 13 | "30 entries added per §2.6 ..." | "29 entries added per §2.6 ...; these 29 basenames cover 78 catch-sites in pre-absorption Check 43 output" |
| §7.2.1 audit-vocabulary line | "~78 audit-vocabulary-gap discoveries: legitimate template placeholders ..." | "~78 audit-vocabulary-gap catch-sites (29 distinct basenames): legitimate template placeholders ..." |
| §7.2.3 actual-resolution | "allowlist 78 audit-vocabulary-gap legitimate basenames" | "allowlist 29 audit-vocabulary-gap legitimate basenames covering 78 catch-sites" |
| §7.2.3 absorption table | "30 new entries" | "29 new entries (covering 78 catch-sites)" |
| §7.4 POQ disposition | "Option C (hybrid: allowlist 78 + fix 6 LEAK CLASS C catches)" | "Option C (hybrid: allowlist 29 basenames covering 78 catch-sites + fix 6 LEAK CLASS C catches)" |
| §7.5 boundary table | "30 new entries with one-line rationale per Check 40 §6.5 convention" | "29 new entries with one-line rationale per Check 40 §6.5 convention" |
| Closing summary entry-count | "30 audit-vocabulary-gap legitimate basenames added to `_CHECK_43_ALLOWLIST`" | "29 audit-vocabulary-gap legitimate basenames (covering 78 catch-sites) added to `_CHECK_43_ALLOWLIST`" |
| Closing summary size | "`_CHECK_43_ALLOWLIST` now has 61 entries (31 + 30)" | "`_CHECK_43_ALLOWLIST` now has 60 entries (31 + 29)" |

**New footnote (`[^count]`, anchored on §1 scope item 6):**

> The H.14 commit message (`a6bd91d`) records "30/61" for these counts.
> The authoritative counts are **29 absorption entries** and **60 total
> allowlist entries** post-absorption, as verified by the §2.6 sub-class
> table sum (2+3+8+5+1+7+3 = 29) and reflected throughout this corrected
> narrative. The commit message is immutable in git history; this
> footnote records the discrepancy for the audit trail. (See N1+N2
> H.14 INLINE reviewer fix, 2026-05-24.)

**Note on preserved literal quotes:** The §6 row 13 criterion quote
"~30 entries per §7.2.2 Option A list" is preserved verbatim (it's a
quote of the original architect-spec criterion text). Only the PASS
column was corrected. The §7.6 line "+47 added to `_CHECK_43_ALLOWLIST`"
references a +47-line diff delta, not an entry count, so it is
unaffected by the count correction.

**Rationale:** Reviewer N1+N2 flagged the discrepancy between the
narrative count and the sub-class-table sum, and the conflation of
"basenames" with "catch-sites" in the §7.2.3 framing. Corrected
narrative + cross-reference footnote preserves the auditability of
the commit-message-vs-IMPL-REPORT mismatch for future archaeology.

### 2.2 N3 — GUARDRAILS-CONTRACT §6 verification row update

**File:** `maintenance-docs/v11-implementation/ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md` §6 verification checklist (lines ~796-819).

**BEFORE (row "Guardrail 1 allowlist populated"):**

```
| Guardrail 1 allowlist populated | `_CHECK_43_ALLOWLIST` defined with ~25 entries per §1.4 |
```

**AFTER:**

```
| Guardrail 1 allowlist populated | `_CHECK_43_ALLOWLIST` defined with 60 entries total (31 architect-spec per §1.4 + 29 H.14 Option C absorption per `IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.14.md` §2.6) — original §1.4 spec called for ~25; H.14 main pass landed 31 verbatim per the §1.4 enumeration; the §7.2 audit-vocabulary-gap discovery added the 29 absorption entries |
```

**Rationale:** §6 verification row still reflected the architect's
original "~25 entries" target without acknowledging the H.14 Option C
absorption. Updated row records: (a) the current state (60 entries
total), (b) the architect-spec component (31), (c) the absorption
component (29), (d) cross-reference to the IMPL-REPORT §2.6 sub-class
table, (e) audit trail (original spec called for ~25; H.14 main pass
landed 31 verbatim; absorption added 29).

### 2.3 N4 — GUARDRAILS-CONTRACT §3 architect-doc-vs-reality reconciliation addendum

**File:** `maintenance-docs/v11-implementation/ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md` §3 (Guardrail 3).

**Insertion point:** New §3.5 added between existing §3.4 (Fixture-test
extension) and the `---` separator that precedes §4.

**Structural template:** BD-119 §9.2 addendum pattern in
`maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md` lines 652-666 ("Addendum (2026-05-16,
BD-160) ..."). The BD-119 addendum names BD-160 as the realized
consumer of `migrator_target_surface_for_version` and provides a
reconciliation chain (architect doc → in-code docstring → IMPL-REPORT).

**Content added (new §3.5):**

```markdown
### 3.5 Architect-doc-vs-reality reconciliation (BD-173 H.12)

Per the pack-memory rule "Architect-doc-vs-reality reconciliation"
(CLAUDE.md / AGENTS.md / GEMINI.md § "Repo conventions"; worked
example BD-119 §9.2), when a BD realizes a design anticipated in
an architect doc, the architect doc carries an addendum naming the
realized consumer.

**Realized consumer of `_iter_client_installed_files()` (BD-173 H.12,
commit `41041a6`):** The helper specified in §3.1 was first realized
by BD-173 Batch 19c commit H.12 (`41041a6`, 2026-05-24), which added
the function to `scripts/validate-pack.py` alongside the
`_PROJECT_SIDE_ROOTS` replacement per §3.2 and the
`_iter_project_side_files()` delegation-alias per §3.2 caller-update
plan. The Group 7 fixture tests T1–T4 specified in §3.4 were
appended to `scripts/tests/test-validate-pack-checks-36-37-38.sh`
in the same commit and PASS at HEAD.

**First downstream caller (Check 43, BD-173 H.14, commit `a6bd91d`):**
Check 43 (`check_project_side_bare_internal_refs`) per §1.2 walks
`_iter_client_installed_files()` directly. BD-173 H.14 (the H.14
commit at `a6bd91d`, 2026-05-24) wires this dependency; H.14's
implementation report at
`IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.14.md` §2.1 documents
the dependency.

**Reconciliation chain:**

- §3.1 (architect contract; this file) — function specification
- `scripts/validate-pack.py` `_iter_client_installed_files()`
  docstring — names §3.1 of this architect doc as the contract source
- `IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.12.md` §1 — IMPL-REPORT
  identifies H.12 as the realized consumer of §3.1
- `IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.14.md` §2.1 — first
  downstream caller (Check 43) cross-references H.12

The historical framing (architect spec) and the post-realization
framing (in-code docstring + IMPL-REPORTs) are not contradictory:
§3 documents the architectural contract; H.12 + H.14 document the
contract's first realization and first downstream caller.
```

**Rationale:** Per pack-memory rule "Architect-doc-vs-reality
reconciliation" (CLAUDE.md/AGENTS.md/GEMINI.md § "Repo conventions";
worked example BD-119 §9.2), the architect doc that anticipated a
design must carry an addendum naming the realized consumer once the
design is shipped. The §3.1 helper was specified by the architect doc
and realized by BD-173 H.12; the new §3.5 closes the
architect-doc-vs-reality loop. Identifiers used (file + symbol; commit
SHA; never line numbers) follow the rule's "line numbers drift" guard.

### 2.4 N5 — README.md Repository Layout test-file listing

**File:** `README.md` (repo root).

**BEFORE (L246):**

```
scripts/tests/test-validate-pack-check-42.sh         BD-184 tests — CI workflow wires all per-check test files

.github/workflows/                          GitHub Actions
```

**AFTER (L246-247):**

```
scripts/tests/test-validate-pack-check-42.sh         BD-184 tests — CI workflow wires all per-check test files
scripts/tests/test-validate-pack-check-43.sh         BD-173 H.14 tests — project-side bare cross-reference scanner (V11 leak-sweep prevention)

.github/workflows/                          GitHub Actions
```

**Rationale:** Repository Layout test-file listing enumerates per-check
test scripts in numeric order. The new `test-validate-pack-check-43.sh`
introduced by H.14 was omitted from the listing. Description follows
the existing prose convention ("BD-NNN tests — short feature description")
and cites the BD-173 H.14 context. Placement is after
test-validate-pack-check-42.sh per numeric order.

---

## §3 Verification

### 3.1 validate-pack.py at HEAD

```
$ python3 scripts/validate-pack.py
... (43 checks run)
── Check 40: pack-ops/ bare cross-reference scanner (BD-179) ──
  OK: Check 40 — 9 pack-ops/*.md file(s) walked; zero unqualified bare cross-references (63 allowlist-exempt + 12 anchor-phrase-exempt + 32 same-dir-legit hit(s) accepted)

── Check 41: _CLIENT_INSTALLED_FILES self-doc list integrity (BD-180 G) ──
  OK: Check 41 — 38 `_CLIENT_INSTALLED_FILES` entry (entries) checked; ...

── Check 43: Project-side bare cross-reference scanner (BD-173) ──
  OK: Check 43 — 152 project-side / client-installed file(s) walked; zero pack-internal bare cross-references (578 allowlist-exempt + 18 anchor-phrase-exempt + 12 same-dir-legit + 140 client-installed-legit + 585 fenced-line(s) accepted)

── Check 42: CI workflow wires all per-check test files (BD-184) ──
  OK: Check 42 — 10 per-check test file(s) on disk; 10 workflow invocation(s) found; zero unwired tests. CI workflow wiring is complete.

============================================================
PASSED — all checks clean
```

**All 43 checks PASS.** Check 43 reports clean at HEAD; Check 42
confirms 10 per-check test files / 10 workflow invocations / zero
unwired tests.

### 3.2 No source code changed (out-of-scope guard)

```
$ git diff --stat scripts/ project-template/ supporting-docs/ test-fixtures/
(empty — no output)
```

**No source code changed.** All edits confined to `README.md`,
`maintenance-docs/v11-implementation/ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md`,
and `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.14.md`.

### 3.3 Corrected-count grep verification

```
$ grep -c "29 absorption\|29 new entries\|60 total\|60 entries\|29 audit-vocabulary-gap\|29 distinct" maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.14.md
16
```

16 corrected-count instances present.

```
$ grep -nE "61 (entries|total)|30 absorption|30 audit|30 new entries|30 Option C|30 catches|allowlist 78|\(31 \+ 30\)" maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.14.md
(no output — pattern returns nothing; "CLEAN — no stale 30/61 narrative claims")
```

Zero stale narrative claims remain. The footnote `[^count]` explicitly
records the commit-msg discrepancy.

### 3.4 In-scope file-touch inventory

```
$ git diff --stat README.md maintenance-docs/v11-implementation/ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.14.md
 README.md                                          |  1 +
 .../ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md        | 42 ++++++++++-
 .../IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.14.md | 87 +++++++++++++---------
 3 files changed, 94 insertions(+), 36 deletions(-)
```

Exactly the 3 in-scope files touched. The fix IMPL-REPORT (this file)
is newly written.

### 3.5 Manifest regen — N/A

No v11-surface paths touched (`project-template/`, `scripts/`,
`pack-ops/`, `supporting-docs/` all untouched per §3.2). RC9 rule does
not trigger; manifest regen not required.

---

## §4 Cross-references

- **Triggering review:** `/tmp/PACK-REVIEW-BD-173-Batch-19c-H.14.md` —
  H.14 INLINE reviewer, verdict PASS-WITH-NITS, 5 NITs.
- **H.14 IMPL-REPORT §2.6 sub-class table (authoritative source of the
  "29" count):**
  `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.14.md`
  §2.6 — the table sums 2+3+8+5+1+7+3 = 29 absorption entries.
- **H.12 IMPL-REPORT (cross-ref for N4 addendum):**
  `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.12.md`
  §1 — identifies H.12 as the realized consumer of §3.1
  `_iter_client_installed_files()`.
- **BD-119 §9.2 addendum (structural template for N4):**
  `maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md`
  §9.2 "Addendum (2026-05-16, BD-160)" — names BD-160 as the realized
  first fixture-builder consumer of `migrator_target_surface_for_version`.
- **Pack-memory rule cited by N4 addendum:** CLAUDE.md / AGENTS.md /
  GEMINI.md § "Repo conventions" → "Architect-doc-vs-reality
  reconciliation" bullet.
- **H.14 commit-msg discrepancy (footnote `[^count]`):** commit
  `a6bd91d` subject + body record "30 absorption / 61 total"; this fix
  records the corrected "29/60" and reasons in the new footnote.

---

## §5 Success criteria checklist

| # | Criterion | Status |
|---|---|---|
| 1 | N1+N2: H.14 IMPL-REPORT narrative counts corrected (30→29, 61→60) | **PASS** — 16 corrected instances confirmed by grep; zero stale claims remain |
| 2 | N1+N2: "78 basenames" framing clarified ("29 basenames covering 78 catch-sites") | **PASS** — §1, §2.6, §3.1, §3.5, §6 row 13, §7.2.1, §7.2.3, §7.4, Closing summary all updated |
| 3 | N1+N2: Commit-msg discrepancy footnoted | **PASS** — footnote `[^count]` anchored on §1 scope item 6 |
| 4 | N3: GUARDRAILS-CONTRACT §6 verification row updated to "60 entries (31 architect-spec + 29 absorption)" | **PASS** — row updated with full breakdown + cross-reference to H.14 IMPL-REPORT §2.6 |
| 5 | N4: GUARDRAILS-CONTRACT §3 addendum naming BD-173 H.12 as realized consumer | **PASS** — new §3.5 added between §3.4 and the §3/§4 separator; reconciliation chain documented |
| 6 | N5: README.md test-file listing includes `test-validate-pack-check-43.sh` | **PASS** — entry added after Check 42 in numeric order |
| 7 | validate-pack.py PASS | **PASS** — all 43 checks clean at HEAD |
| 8 | No source code changed | **PASS** — `git diff --stat scripts/ project-template/ supporting-docs/ test-fixtures/` is empty |
| 9 | Fix IMPL-REPORT written | **PASS** — this file at `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.14-fix.md` |

**Net status:** 9 of 9 criteria PASS.

---

## §6 Out-of-scope confirmations

**Pack/project boundary discipline (P-missed-7) check:**

Per CLAUDE.md § "Pack memory" → P-missed-7, edits to project-side
files require investigating the project-side SSOT first. This fix
touches ONLY pack-side files; no project-side investigation needed.

| Path | Surface | SSOT |
|---|---|---|
| `README.md` | Pack-root | The README IS the pack-side authoritative source for "Repository Layout"; no project-side SSOT applies |
| `maintenance-docs/v11-implementation/ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md` | Pack-only (maintenance-docs/) | The architect doc IS the pack-side SSOT for Guardrail 1-4 contract |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.14.md` | Pack-only (maintenance-docs/) | The IMPL-REPORT IS the pack-side audit-trail surface for H.14 |

**No project-side files touched** (no `project-template/`,
`supporting-docs/`, `scripts/`, `pack-ops/`, `test-fixtures/`).

**Trinity rule check (CLAUDE.md / AGENTS.md / GEMINI.md):**

This fix touches ZERO trinity files (neither pack-root nor
project-template). Trinity parity rule does not trigger.

**RC9 manifest regen check:**

Per CLAUDE.md § "Repo conventions" → "Regenerate test-fixtures/
manifest.txt on every v11-surface commit", v11-surface =
`project-template/`, `scripts/`, `pack-ops/`, `supporting-docs/`. This
fix touches none of these. Manifest regen does NOT trigger.

**Plan deviations:** Zero. The prompt scoped the fix to exactly 5 NITs
across 4 file surfaces (3 modified + 1 new); the fix applies all 5 NITs
within scope. No new POQs introduced.

**New POQs introduced:** None.

---

## §7 Files-changed inventory

| Path | Type | NIT(s) |
|---|---|---|
| `README.md` | Modified | N5 — +1 line (test-file listing entry) |
| `maintenance-docs/v11-implementation/ARCHITECTURE-V11-GUARDRAILS-CONTRACT.md` | Modified | N3 (§6 row) + N4 (§3.5 addendum) — +42 lines / -1 line |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.14.md` | Modified | N1, N2 — 16+ narrative edits + new footnote |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-173-Batch-19c-H.14-fix.md` | New file | This report |

**Total: 4 files touched (3 modified + 1 new).**

---

## Closing summary

All 5 H.14 INLINE-reviewer NITs closed in a single fix-coder pass:

- **N1+N2** — H.14 IMPL-REPORT narrative counts corrected to match the
  §2.6 sub-class table sum (29 absorption, 60 total); "78 basenames"
  framing clarified to "29 basenames covering 78 catch-sites"; new
  footnote `[^count]` records the commit-msg discrepancy for the audit
  trail.
- **N3** — GUARDRAILS-CONTRACT §6 verification row updated to reflect
  the post-absorption state (60 entries; 31 architect-spec + 29
  absorption; cross-reference to IMPL-REPORT §2.6).
- **N4** — GUARDRAILS-CONTRACT §3.5 architect-doc-vs-reality
  reconciliation addendum added per the pack-memory rule (worked
  example BD-119 §9.2); names BD-173 H.12 as the realized consumer of
  `_iter_client_installed_files()` and Check 43 / BD-173 H.14 as the
  first downstream caller; reconciliation chain documented.
- **N5** — README.md Repository Layout test-file listing now includes
  `test-validate-pack-check-43.sh` in numeric order.

No source code changed; all 43 validate-pack.py checks PASS at HEAD.
Manifest regen does not trigger (no v11-surface touched). No project-side
files touched (P-missed-7 trivially satisfied). No trinity-rule edits
required. Zero plan deviations; zero new POQs.

**HEAD at report time:** `a6bd91d` (unchanged; agents never commit per
pack workflow rule).
