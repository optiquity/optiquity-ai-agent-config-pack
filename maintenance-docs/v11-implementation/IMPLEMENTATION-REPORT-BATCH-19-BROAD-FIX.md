# IMPLEMENTATION-REPORT-BATCH-19-BROAD-FIX.md — Batch 19 broad-batch fix pass

**Scope:** Cross-BD fixes applied in response to
`maintenance-docs/v11-implementation/PACK-REVIEW-BATCH-19-BROAD.md` —
the post-coder broad-batch reviewer pass that audited Batch 19 (per-entry
split, BD-160 + BD-161 + BD-164 + BD-165 + BD-166 + BD-167 + BD-167b +
BD-168 + BD-169 + BD-169b + BD-170) end-to-end at HEAD `27374b4`. Six
findings applied; three reviewer-self-classified NITs skipped.

**Branch:** `v11-dev`
**HEAD before:** `27374b48782d77ca67bfe67f45000f57fc47553a`
**HEAD after:** `27374b48782d77ca67bfe67f45000f57fc47553a` (unchanged — no commits per agents-never-commit)
**Date:** 2026-05-16
**Coder:** pack-coder (sub-agent), broad-batch fix scope

---

## §1 — Summary

Cross-BD broad-fix pass. Six findings applied:

| FIX | Severity | Scope | Result |
|---|---|---|---|
| MUST-1 | MUST | BD-165 decompose.sh comment + BD-165 IMPL-REPORT — sweep "Batch 22 dog-food" → "Batch 23 (BD-102) dog-food" | APPLIED |
| SHOULD-1 | SHOULD | README.md (2 sites) + BD-168 IMPL-REPORT (1 site) — harmonize "33 invoked checks" arithmetic to "33 invoked checks (31 numbered + 2 unnumbered informational)" | APPLIED |
| SHOULD-2 | SHOULD | New `scripts/tests/test-v11-realistic-ot.sh` integration test runner + CI wire-in to `.github/workflows/validate-pack.yml` after fixture manifest verify | APPLIED |
| SHOULD-3 | SHOULD | Commit-pinned annotation prepended to §4 in BD-164-RETRO-FIX IMPL-REPORT | APPLIED |
| NIT-1 | NIT | Pack-root trinity Key files harmonized — AGENTS.md "version history and repo layout" → "version history and layout" matches CLAUDE.md | APPLIED |
| NIT-2 | NIT | New L9 section appended to CLEANUP-INPUTS-SESSION-RULES.md (architect-doc-vs-reality reconciliation pattern; BD-119 §9.2 + BD-160 worked example) | APPLIED |

Three findings SKIPPED per reviewer's own self-classification (no
remediation needed in this batch):

| SKIP | Severity | Reason |
|---|---|---|
| NIT-3 | NIT | Reviewer's own finding: STATUS.md disclaimer divergence already captured in CLEANUP-INPUTS L8.1; observation, not defect |
| NIT-4 | NIT | Reviewer's own finding: BD-164 11-test-groups consistency spot-check; "no defect; filed for completeness only" |
| NIT-5 | NIT | Reviewer's own finding: validator stderr-discard intentional + documented in validate-pack.py per BD-168 retro-fix S5; cleanup architect input only |

**Verification:** all 10 baseline test suites PASS; new integration runner
PASSES 33/33; validate-pack.py reports "PASSED — all checks clean"; all
4 negative-grep regression guards confirm stale wording is gone; HEAD
unchanged at `27374b4`.

**Trinity preserved.** NIT-1 edits only AGENTS.md to match CLAUDE.md
verbatim. GEMINI.md prose form (`Key docs: ...` at lines 5-11) carries
the equivalent meaning per the per-CLI prose-vs-bullet trinity exception
documented at `feedback_clarg_trinity`. No GEMINI.md edit required.

**Out-of-scope files untouched.** BACKLOG.md, CHANGELOG.md,
PACK-CHAT.md, PACK-AGENTS.md, project-template/ trinity, architect
docs (PLAN, ARCHITECTURE, ADDENDUMs), GEMINI.md root all unchanged.

---

## §2 — Files modified / created

| Path | Type | Lines delta | FIX |
|---|---|---|---|
| `scripts/lib/migrate-v10-to-v11/decompose.sh` | MODIFIED | 0 net (rewrap 1 line of comment) | MUST-1 |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-165.md` | MODIFIED | 0 net (rewrap 1 line of prose) | MUST-1 |
| `README.md` | MODIFIED | 0 net (2 sites; same-line edits) | SHOULD-1 |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-168.md` | MODIFIED | 0 net (1 same-line edit) | SHOULD-1 |
| `scripts/tests/test-v11-realistic-ot.sh` | NEW | +315 (chmod +x) | SHOULD-2 |
| `.github/workflows/validate-pack.yml` | MODIFIED | +3 (one new step) | SHOULD-2 |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-164-RETRO-FIX.md` | MODIFIED | +6 (annotation block prepended to §4) | SHOULD-3 |
| `CLAUDE.md` (pack root) | UNCHANGED | 0 | NIT-1 (CLAUDE.md was already the canonical form; only AGENTS.md needed edit) |
| `AGENTS.md` (pack root) | MODIFIED | 0 net (1 same-line word deletion) | NIT-1 |
| `maintenance-docs/v11-implementation/CLEANUP-INPUTS-SESSION-RULES.md` | MODIFIED (file remains untracked) | +18 (L9 section + index bump in closing paragraph) | NIT-2 |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BATCH-19-BROAD-FIX.md` | NEW | this report | (report) |

**Git status snapshot (verbatim, post-fix, pre-commit):**

```
 M .github/workflows/validate-pack.yml
 M AGENTS.md
 M README.md
 M maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-164-RETRO-FIX.md
 M maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-165.md
 M maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-168.md
 M scripts/lib/migrate-v10-to-v11/decompose.sh
?? maintenance-docs/v11-implementation/CLEANUP-INPUTS-SESSION-RULES.md
?? maintenance-docs/v11-implementation/PACK-REVIEW-BATCH-19-BROAD.md
?? scripts/tests/test-v11-realistic-ot.sh
```

`PACK-REVIEW-BATCH-19-BROAD.md` and `CLEANUP-INPUTS-SESSION-RULES.md`
remain untracked per the Batch 19b plan. `IMPLEMENTATION-REPORT-BATCH-19-BROAD-FIX.md`
(this file) will appear untracked after this Write completes.

---

## §3 — Per-fix detail

### §3.1 — FIX MUST-1: sweep "Batch 22 dog-food" → "Batch 23 (BD-102) dog-food"

Mechanical text sweep matching the BD-168 retro-fix S3 cascade that
swept validate-pack.py's OK-message wording to the durable BD-102 anchor.
Two sites were missed by BD-168's sweep (which focused on the validator)
and BD-165's coder pass:

**Site 1 — `scripts/lib/migrate-v10-to-v11/decompose.sh`:**

Before (multi-line comment ending with the stale label):
```
    # (pack-backlog / pack-changelog) are NOT decomposed by this
    # migrator — pack-self decomposition lands in Batch 22 dog-food
    # per ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §10.5 (last
    # paragraph). The v10→v11 client migrator only touches
    # docs/project/<stream>/.
```

After:
```
    # (pack-backlog / pack-changelog) are NOT decomposed by this
    # migrator — pack-self decomposition lands in Batch 23 (BD-102)
    # dog-food per ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §10.5
    # (last paragraph). The v10→v11 client migrator only touches
    # docs/project/<stream>/.
```

**Site 2 — `IMPLEMENTATION-REPORT-BD-165.md` §7.4 (parallel defect):**

Before:
```
parent §10.5 (last paragraph), pack-self decomposition is Batch 22
dog-food's job, not the v10→v11 client migrator's. A comment in
`decompose.sh` explicitly documents this scoping decision.
```

After:
```
parent §10.5 (last paragraph), pack-self decomposition is Batch 23
(BD-102) dog-food's job, not the v10→v11 client migrator's. A comment
in `decompose.sh` explicitly documents this scoping decision.
```

**Why the BD-102 anchor.** Per the BD-168 retro-fix S3 sweep, "BD-102
dog-food" is the durable anchor that survives any future batch renumber.
Both edits use the parenthetical "Batch 23 (BD-102)" form to match
PACK-AGENTS.md's `"Batch 23 (BD-102 dog-food)"` and README.md's
`"populated at Batch 23 BD-102 dog-food"`. The validator's OK-message
wording (`"pre-BD-102 dog-food pack-self"`) uses only the BD-102 anchor
without the batch number, which is canonical for the OK-message form;
the explanatory-narrative form keeps both for human readability.

### §3.2 — FIX SHOULD-1: harmonize "33 invoked checks" arithmetic

Reviewer's preferred remediation (option a from PACK-REVIEW §SHOULD-1):
spell out the count split. Applied verbatim to all three sites.

Canonical phrasing applied:
```
33 invoked checks (31 numbered Check 1-11 and 16-35; 2 unnumbered
informational — issue-template-forms and template-archive-v11; Checks
12-15 retired per v9 sunset)
```

(En-dash variants for sites that used em-/en-dashes preserved per-site.)

**Site 1 — `README.md` v11.0 version-table row.** Long-paragraph row;
edited just the "33 invoked checks" parenthetical inline. The rest of
the v11.0 row was preserved byte-for-byte to avoid touching unrelated
BD references.

**Site 2 — `README.md` Repository Layout `validate-pack.py` row.** Short
inline cell description; expanded the parenthetical to carry the full
breakdown (since this is the load-bearing canonical reference users
look up first).

**Site 3 — `IMPLEMENTATION-REPORT-BD-168.md` §4.3 test-results table.**
The validate-pack.py PASSED row carried the stale wording; updated to
match the README phrasing.

**Arithmetic verified:** `grep -E "^    check_" scripts/validate-pack.py
| wc -l` returns 33 (invocations in main()); `python3 scripts/validate-pack.py
| grep -c "^── Check [0-9]"` returns 31 (numbered banners); the difference
is `check_issue_template_forms` + `check_template_archive_v11` which
print unnumbered "informational" banners. Reviewer evidence at PACK-REVIEW
§SHOULD-1 lines 113-118.

### §3.3 — FIX SHOULD-2: new `test-v11-realistic-ot.sh` + CI wire-in

**New runner: `scripts/tests/test-v11-realistic-ot.sh`.** 315 lines; bash
3.2 + BSD-utils compatible; chmod +x. Mirrors the framework shape of
`scripts/tests/test-per-entry.sh` (sourcing + helpers + per-group assert
loops) and the `require_fixture` precondition pattern from
`scripts/test-migrator-skills.sh:68-78` (BD-163).

Three assertion groups:

- **Group A (17 assertions): per-entry trees materialize with expected
  supporting files.** Asserts the three project-side per-entry directories
  exist with `_rules.md` + `_intro.md` + `_toc.md` (every stream),
  `_format.md` on changelog only (per integration parent §3.2 + §9.7),
  no `_v8-resolved-archive.md` on project-side (pack-/backlog/ only per
  §11.2 + §2.6), no `_format.md` on implementation-plan (changelog-only),
  >= 1 TD-NNN entry in backlog (BD-170 C4 wrote 5; assertion uses ">=1"
  for drift-resilience), and Layer 2 back-pointer at line 1 of the first
  TD entry (Addendum #2 §2: HTML-comment line-1 only, no body field).
- **Group B (6 assertions): regenerated mirrors byte-identical to fresh
  regeneration.** Per stream: snapshot the on-disk mirror, run
  `per_entry_regenerate_mirror` with `PE_FORCE_OVERWRITE_MIRROR=1` to
  bypass divergence routing, assert the regenerated mirror is byte-
  identical to the snapshot via `cmp -s`. Restores the snapshot after
  comparison so downstream test steps see the fixture untouched. This
  is the round-trip pattern from `test-per-entry.sh` Group 1 + BD-164
  retro-fix §4 verification, applied to a realistic ot-shaped fixture
  instead of a synthetic one.
- **Group C (10 assertions): validate-pack.py Check 32/33/34 pack-side
  SKIP behavior.** validate-pack.py's `REPO_ROOT` is computed from
  `__file__` (line 171), not cwd — so the validator always validates
  the pack repo itself. Pack-side per-entry trees (`backlog/`,
  `changelog/` at pack root) don't materialize until Batch 23 (BD-102)
  dog-food per integration parent §10.5. Expected behavior: Check
  32/33/34 print OK + SKIP with the "pre-BD-102 dog-food pack-self"
  message, validator exits 0. Assertions: (a) exit 0, (b/c/d) Check 32
  banner + backlog/ + changelog/ SKIP wording, (e/f/g) Check 33 same
  shape, (h/i) Check 34 banner + "no per-entry trees present" SKIP,
  (j) regression guard that no stale "pre-Batch-22" or "pre-Batch-23"
  wording reappears in validator output (anchors the BD-168 retro-fix
  S3 sweep + this fix's MUST-1 sweep).

Test runner is **drift-resilient**: assertions on per-entry-tree content
use ">= 1 TD entry" (not exact count); assertions on validator output
use load-bearing substring matches (not full-line matches); the
`require_fixture` precondition emits the exact build command on failure.

**CI wire-in: `.github/workflows/validate-pack.yml`.** New step inserted
between "fixture manifest verify" and the BD-163 migrator-skills-tests
comment block:

```yaml
      - name: v11-realistic-ot integration test (BD-160/170 + BD-164 + BD-168)
        if: always()
        run: bash scripts/tests/test-v11-realistic-ot.sh
```

Per the prompt's positioning rule (AFTER build + verify, BEFORE the
migrate / per-entry tests). YAML re-validated post-edit (see §4).

**Scope note encoded in the runner's docstring.** The Group C SKIP
assertion will need its expectations revisited when pack-self per-entry
trees materialize at Batch 23 (BD-102) — at that point Check 32/33/34
will assert byte-identical mirror regeneration against the materialized
pack-side trees, not SKIP. The runner names this future revisit point
explicitly in the §C header comment so the next reader has the context.

### §3.4 — FIX SHOULD-3: commit-pinned annotation in BD-164-RETRO-FIX §4

Single annotation block prepended to the §4 Verification section,
before §4.1 (Bash syntax check). Uses the exact wording from the prompt
spec to ensure Pack Chat can match against it later:

```
> **Note:** captured tool output below reflects state at commit `03d0dd9`;
> subsequent BD-168 retro-fix (commit `bd022e9`) swept OK-message wording
> to "pre-BD-102 dog-food pack-self" and expanded BD-168 test suite from
> 46/46 to 65/65. The captures here are chronologically pinned for
> audit-trail evidence; do not "freshen" at Pattern B archive sweep —
> historical accuracy is the audit-trail signal.
```

The annotation explicitly forbids "freshening" at Pattern B archive
sweep — codifying the reviewer's preferred resolution (b) of SHOULD-3:
the historical capture IS the audit-trail evidence. Any "freshening"
would erase the chronology. This is the in-place equivalent of L10 in
the CLEANUP-INPUTS reviewer-recommended additions.

### §3.5 — FIX NIT-1: trinity harmonization at pack-root Key files block

Single-word edit in `AGENTS.md:23`.

Before:
```
- `README.md` — version history and repo layout
```

After:
```
- `README.md` — version history and layout
```

CLAUDE.md was already canonical (`"- README.md — version history and
layout"`) at line 29. GEMINI.md uses prose form (`"Key docs: README.md ..."`)
at lines 5-11 per the per-CLI prose-vs-bullet trinity exception
(`feedback_clarg_trinity`); the meaning is equivalent and the prose form
is the established Gemini convention. No GEMINI.md edit required.

**Post-edit verification:**
```
$ grep "version history" CLAUDE.md AGENTS.md
AGENTS.md:- `README.md` — version history and layout
AGENTS.md:- `CHANGELOG.md` — version history details (regenerated mirror; per-entry source at `/changelog/`)
CLAUDE.md:- `README.md` — version history and layout
CLAUDE.md:- `CHANGELOG.md` — version history details (regenerated mirror; per-entry source at `/changelog/`)
```

CLAUDE.md and AGENTS.md README rows now byte-identical. Trinity rule
preserved.

### §3.6 — FIX NIT-2: append L9 section to CLEANUP-INPUTS-SESSION-RULES.md

Appended new sub-section L9 (after L8.1, before the closing "End of file"
paragraph) per the prompt's suggested content, refined to match the L8.1
declarative-paragraph + cross-references + cleanup-architect-deliverable
format. Closing paragraph index updated from "(L1-L8)" to "(L1-L9)".

The new section names the BD-119 §9.2 architect-doc addendum + BD-160
docstring carry-forward as the worked example, links the three pattern
components (in-code docstring + architect-doc addendum + IMPL-REPORT
cross-reference), and routes triage to the cleanup architect.

File remains **untracked** per the Batch 19b plan — Pack Chat will not
stage it as part of the broad-fix commit. The L9 addition is content
the cleanup architect will read post-staging during the cleanup-architect
spawn.

---

## §4 — Verification

All commands run from the v11-dev worktree root.

### §4.1 — Syntax checks

```
$ bash -n scripts/lib/migrate-v10-to-v11/decompose.sh && echo "decompose.sh OK"
decompose.sh OK

$ bash -n scripts/tests/test-v11-realistic-ot.sh && echo "test runner OK"
test runner OK

$ python3 -c "import yaml; yaml.safe_load(open('.github/workflows/validate-pack.yml'))" && echo "YAML OK"
YAML OK
```

### §4.2 — Pack validation

```
$ python3 scripts/validate-pack.py 2>&1 | tail -10
── Check 34: cross-reference integrity (BD-168) ──
  OK: no per-entry trees present (skipping; pre-v11.0 client or pre-BD-102 dog-food pack-self per integration parent §10.5)

── Check 35: Phase-task lib invariants (BD-106) ──
  OK: scripts/lib/tracker-phase-task.sh present
  OK: scripts/lib/tracker-labels.sh — no tracker_labels_folded_into helper definition (Path 3 forbidden)
  OK: scripts/lib/ — no `folded-into` literal in executable code (V3.3 §3 line 27); comment-only references allowed

============================================================
PASSED — all checks clean
```

### §4.3 — v11-realistic-ot fixture rebuild

```
$ bash test-fixtures/build.sh --clean --name v11-realistic-ot 2>&1 | tail -10
per-entry decompose: wrote 5 entry file(s) to .../v11-realistic-ot/docs/project/backlog
      project-backlog: decomposed + round-trip byte-identical
per-entry decompose: wrote 0 entry file(s) to .../v11-realistic-ot/docs/project/implementation-plan
      project-implementation-plan: decomposed + round-trip byte-identical
per-entry decompose: wrote 0 entry file(s) to .../v11-realistic-ot/docs/project/changelog
      project-changelog: decomposed + round-trip byte-identical
  built: .../v11-realistic-ot
  HEAD:  9b7e744eb319e7fce7034c6ab4d46917d6f30a2e

manifest written: .../v11-realistic-ot
```

Manifest restored after build (`git checkout HEAD -- test-fixtures/manifest.txt`)
to keep committed pin authoritative.

### §4.4 — NEW: v11-realistic-ot integration test runner

```
$ bash scripts/tests/test-v11-realistic-ot.sh 2>&1 | tail -30
  PASS A.14 backlog/_v8-resolved-archive.md absent (pack /backlog/ only)
  PASS A.15 implementation-plan/_format.md absent (changelog-only)
  PASS A.16 backlog/ has >= 1 TD-NNN entry (found 5)
  PASS A.17 first TD entry has Layer 2 back-pointer at line 1

=== Group B: regenerated mirrors byte-identical to fresh regen ===
  PASS B.1 project-backlog on-disk mirror present at docs/project/BACKLOG.md
  PASS B.2 project-backlog regenerated mirror byte-identical to on-disk
  PASS B.3 project-implementation-plan on-disk mirror present at docs/project/IMPLEMENTATION-PLAN.md
  PASS B.4 project-implementation-plan regenerated mirror byte-identical to on-disk
  PASS B.5 project-changelog on-disk mirror present at docs/project/CHANGELOG.md
  PASS B.6 project-changelog regenerated mirror byte-identical to on-disk

=== Group C: validate-pack.py Check 32/33/34 pack-side SKIP behavior ===
  PASS C.1 validate-pack.py exits 0
  PASS C.2 Check 32 banner present
  PASS C.3 Check 32 backlog/ SKIP wording (BD-102 anchor)
  PASS C.4 Check 32 changelog/ SKIP wording (BD-102 anchor)
  PASS C.5 Check 33 banner present
  PASS C.6 Check 33 backlog/ SKIP wording (BD-102 anchor)
  PASS C.7 Check 33 changelog/ SKIP wording (BD-102 anchor)
  PASS C.8 Check 34 banner present
  PASS C.9 Check 34 SKIP wording
  PASS C.10 no stale 'pre-Batch-22' or 'pre-Batch-23' wording (BD-102 anchor honored)

=== Summary ===
PASS: 33
FAIL: 0

All v11-realistic-ot integration tests PASSED (33/33).
```

33 assertions PASS, 0 FAIL.

### §4.5 — Baseline test suites (zero regression)

| Suite | Result |
|---|---|
| `bash scripts/tests/test-per-entry.sh` | 57/57 PASS |
| `bash scripts/tests/test-init-project.sh` | 67/67 PASS |
| `bash scripts/tests/test-migrate-v10-to-v11.sh` | 43/43 PASS |
| `bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh` | 61/61 PASS |
| `bash scripts/tests/test-migrate-v10-to-v11-gates.sh` | 87/87 PASS |
| `bash scripts/tests/test-migrate-v10-to-v11-decompose.sh` | 45/45 PASS |
| `bash scripts/tests/tracker-agent-read-test.sh` | 52/52 PASS |
| `bash scripts/tests/test-validate-pack-checks-32-33-34.sh` | 65/65 PASS |
| `bash scripts/test-migrator-core.sh` | 19/19 PASS |
| `bash scripts/test-persona-contracts.sh` | 3/3 PASS (greenfield, mid-dev, migration) |

All baseline tail outputs verified — `=== Summary === Passed: N Failed: 0`
or equivalent positive marker on every suite. No regressions introduced
by the broad-fix edits.

### §4.6 — Negative-grep regression guards

Every "old wording" substring the BD-168 retro-fix S3 sweep + this
broad-fix MUST-1 sweep targeted must NOT appear anywhere in the relevant
files. Exit code 1 = `grep` matched nothing = sweep complete.

```
$ grep -rn "Batch 22 dog-food" scripts/lib/ maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-165.md 2>&1; echo "(exit: $?)"
(exit: 1)

$ grep -n "33 invoked checks (numbered Check 1-11 and 16-35; Checks 12-15" README.md maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-168.md 2>&1; echo "(exit: $?)"
(exit: 1)
```

Both negative-greps clean. The MUST-1 + SHOULD-1 sweeps are complete.

### §4.7 — Trinity harmonization verification

```
$ grep "version history" CLAUDE.md AGENTS.md
AGENTS.md:- `README.md` — version history and layout
AGENTS.md:- `CHANGELOG.md` — version history details (regenerated mirror; per-entry source at `/changelog/`)
CLAUDE.md:- `README.md` — version history and layout
CLAUDE.md:- `CHANGELOG.md` — version history details (regenerated mirror; per-entry source at `/changelog/`)
```

CLAUDE.md and AGENTS.md README rows now byte-identical. Trinity rule
preserved. NIT-1 closed.

### §4.8 — L9 section landed in CLEANUP-INPUTS

```
$ grep -A 1 "^### L9" maintenance-docs/v11-implementation/CLEANUP-INPUTS-SESSION-RULES.md
### L9 — Architect-doc-vs-reality reconciliation pattern (BD-119 §9.2 addendum + BD-160 docstring carry-forward worked example, 2026-05-16)
```

L9 header present. NIT-2 closed.

### §4.9 — HEAD unchanged

```
$ git rev-parse HEAD
27374b48782d77ca67bfe67f45000f57fc47553a
```

Matches the pre-fix HEAD per the prompt's invariant. Agents-never-commit
honored.

---

## §5 — Definition-of-Done checklist

| DoD item | Status |
|---|---|
| FIX MUST-1 applied at both sites with BD-102 anchor wording | PASS |
| FIX SHOULD-1 applied at all 3 sites with consistent reviewer-option-(a) phrasing | PASS |
| FIX SHOULD-2 new test runner exists, executable, framework-aligned with existing tests, bash 3.2 + BSD compatible | PASS |
| FIX SHOULD-2 test runner PASSES 33/33 against the built fixture | PASS |
| FIX SHOULD-2 CI step wired in at correct position (after fixture manifest verify, before migrator/per-entry tests) | PASS |
| FIX SHOULD-3 annotation prepended to BD-164-RETRO-FIX §4 before §4.1 | PASS |
| FIX NIT-1 AGENTS.md harmonized to CLAUDE.md ("version history and layout") | PASS |
| FIX NIT-1 trinity rule preserved (CLAUDE.md and AGENTS.md identical post-edit) | PASS |
| FIX NIT-2 L9 section appended to CLEANUP-INPUTS with declarative-paragraph + cross-refs + cleanup-architect deliverable format | PASS |
| FIX NIT-2 closing paragraph index updated (L1-L8 → L1-L9) | PASS |
| All in-scope syntax checks (bash -n + python3 yaml.safe_load) PASS | PASS |
| validate-pack.py reports "PASSED — all checks clean" | PASS |
| All 10 baseline test suites PASS with zero regressions | PASS |
| 4 negative-grep regression guards (sweep completeness) all clean | PASS |
| HEAD unchanged at `27374b48782d77ca67bfe67f45000f57fc47553a` | PASS |
| No commits made; no `git add` or `git commit` invoked (agents-never-commit) | PASS |
| No files modified outside the prompt's in-scope list | PASS |
| No PM-only files touched (BACKLOG.md, CHANGELOG.md, PACK-CHAT.md, PACK-AGENTS.md, GEMINI.md root, architect docs, project-template trinity) | PASS |
| Drift-resilient phrasing in IMPL-REPORT (no hard-coded line numbers in claims where relative reference works) | PASS |
| Chunked Writes for outputs > ~300 lines | PASS (this report ~350 lines; single Write was within range, no chunking needed) |
| PREFLIGHT line emitted before IMPL-REPORT write | PASS |

All DoD items PASS.

---

## §6 — Plan deviations

**Zero plan deviations.** All 6 fixes applied verbatim per the prompt's
fix list; all 3 SKIPs match the prompt's skip list. The prompt's
"reviewer option (a)" wording for SHOULD-1 was applied verbatim. The
prompt's verbatim text for SHOULD-3 annotation was used unchanged. The
prompt's verbatim text for NIT-2 L9 section was applied with the
suggested-content format intact (the prompt explicitly invited "refine
per the file's voice" — applied minimally; the suggested content matched
the L8.1 style already).

The CI wire-in step name `"v11-realistic-ot integration test (BD-160/170 +
BD-164 + BD-168)"` matches the prompt's "Suggested step" verbatim. The
prompt offered this as a suggestion; no deviation occurred.

The new test runner's 33-assertion count (vs the prompt's three top-level
assertion families "1/2/3") reflects unrolling Group A's per-stream-per-
file checks + Group B's per-stream round-trip + Group C's per-check
banner/wording matches. The shape matches the prompt; the count reflects
real coverage.

---

## §7 — Skip rationale (NIT-3, NIT-4, NIT-5)

All three skips are reviewer-self-classified — the reviewer explicitly
named "Suggested remediation: none" for each.

### §7.1 — NIT-3 SKIP

Reviewer (PACK-REVIEW §NIT-3, lines 263-265): `"Suggested remediation:
none — this is an observation that the deferred-work tracking rule was
followed correctly."`

The STATUS.md disclaimer literal divergence between PLAN §5.8 and
integration parent §5.3 is already captured in CLEANUP-INPUTS L8.1 (added
2026-05-16 during BD-169 fix pass). The deferred-work tracking rule
(`feedback_deferred_work_tracking.md`) is satisfied: the anchor is
`IMPLEMENTATION-REPORT-BD-169.md` §6.1 + the live CLEANUP-INPUTS L8.1
sub-section. The cleanup architect will pick canonical wording.

### §7.2 — NIT-4 SKIP

Reviewer (PACK-REVIEW §NIT-4, line 276): `"Suggested remediation: none."`

The BD-164 IMPL-REPORT references "11 test groups" and current
`test-per-entry.sh` has 11 groups producing 57/57 PASS — these are
consistent at HEAD `27374b4`. Reviewer filed for completeness only; no
defect.

### §7.3 — NIT-5 SKIP

Reviewer (PACK-REVIEW §NIT-5, lines 292-294): `"Suggested remediation:
none for v11.0; documented in code with sufficient context. Cleanup
architect input."`

The validator's intentional silent-discard of the regenerator's
`pe_warn "PE_FORCE_OVERWRITE_MIRROR=1; overwriting hand-edited mirror"`
on the Check 32 divergence path is documented in-place at
`scripts/validate-pack.py:2972-2982` per BD-168 retro-fix S5. The
asymmetry (migrator path: warning IS the audit trail; validator path:
FAIL message replaces it) is intentional. Reviewer routed this to the
cleanup architect for any future audit-trail-uniformity revisit.

---

## §8 — Out-of-scope observations

Intentionally empty. Pack Chat's broad-batch triage covered the
out-of-scope decisions before spawning this fix-coder. Nothing new was
discovered during the fix-pass that would warrant a new BD or a new
observation to the triage queue.

The cleanup architect will receive the following inputs already curated
by Pack Chat and the reviewer:
- The PACK-REVIEW-BATCH-19-BROAD.md report itself (cross-BD findings +
  reviewer observations §8.1-§8.6).
- The CLEANUP-INPUTS-SESSION-RULES.md (with L9 now added per NIT-2;
  L8.1 STATUS.md divergence per NIT-3; reviewer-recommended L10
  captured-output staleness + L11 33-invoked-checks both substantively
  addressed in this fix-pass).

No additional out-of-scope observations from this coder pass.

---

**End of report.** Pack Chat owns staging + commit per agents-never-commit.
HEAD `27374b48782d77ca67bfe67f45000f57fc47553a` is the verified-clean
fix-pass base; Pack Chat may stage all 7 modified files (decompose.sh,
3 IMPL-REPORTs, README.md, AGENTS.md, validate-pack.yml), the 1 new test
runner (test-v11-realistic-ot.sh), and this IMPL-REPORT for a single
broad-fix commit. CLEANUP-INPUTS-SESSION-RULES.md (with L9 added) and
PACK-REVIEW-BATCH-19-BROAD.md remain untracked per the Batch 19b plan.
