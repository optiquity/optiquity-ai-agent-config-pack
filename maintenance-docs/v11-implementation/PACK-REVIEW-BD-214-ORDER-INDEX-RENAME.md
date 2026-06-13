# PACK-REVIEW — BD-214 `_order.md` → `_index.md` rename (+ scope broadening) across BD entries

- **Reviewer:** fresh pack-reviewer
- **Repo:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev` (branch `v11-dev`)
- **Base HEAD:** `935d9a5e525ded7df817803fe3b2240b087a0673`
- **Date:** 2026-06-13
- **Change set:** uncommitted working-tree edits to `backlog/BD-202.md`, `backlog/BD-203.md`, `backlog/BD-206.md`
- **Mandate:** read-only review; sole write is this report.

---

## VERDICT: **CLEAN** (APPROVE — no findings at any severity)

The change set faithfully renames `_order.md`→`_index.md` in all 3 referencing
BD entries, broadens the BD-206 definition exactly per the user directive +
census §0, preserves BD-203's Resolved state (forward-consistency note only,
not a reopen), adds an actionable DEFERRED-SWEEP ANCHOR, leaves all
user-deferred maintenance-docs untouched, and keeps the full CI suite green
(validate-pack general + DEEP + every wired test script EXIT=0). The
grep-zero gate over `backlog/` holds.

No BLOCKER / MUST / SHOULD / NIT findings.

---

## Per-entry verdict

### BD-202 — PASS
- Exactly **1** edit (L14): `per-entry trees + `_order.md` become the managed
  assets` → `per-entry trees + `_index.md` become the managed assets`.
- Nothing else touched (1-line diff). Status `Open` unchanged. Target v11.1
  unchanged. The incidental "managed assets" mention is renamed for
  consistency only — no scope change to BD-202, which is correct (the broadening
  belongs to BD-206, the primary home).

### BD-203 (Resolved) — PASS
- Exactly the **1** D1 meta-doc-list rename (L5): the meta-doc enumeration
  `_intro.md`/`_rules.md`/`_toc.md`/`_order.md` → `…/`_toc.md`/`_index.md`.
- A dated forward-consistency note appended to the same line:
  `[Note 2026-06-13 (BD-214): the prospective meta-doc formerly named `_order`
  (the predesigned `.md` sidecar) is renamed `_index.md` (broadened scope) —
  this is a forward-consistency token update to a Resolved entry; rename only,
  does not reopen the entry.]`
- **Status STILL `Resolved`** (diff confirms the `Status: Resolved` line is
  unchanged; the entry was NOT reopened). The note explicitly disclaims a
  reopen. Body otherwise byte-unchanged. Correct.

### BD-206 — PASS
All **4** original `_order.md` references renamed + the definition broadened,
plus a new anchor:
1. **L6 (`_index.md` FINDING):** renamed; carries a parenthetical
   `(renamed from the former `_order` sidecar 2026-06-13, BD-214 — scope
   broadened, see ADD (US-6))` and rewords the finding to "per-entry index
   sidecar … execution-ordering is ONE of the indexes `_index.md` may carry."
   The reconcile-predesign→BD-203 intent is preserved verbatim ("if the
   predesign conflicts with the BD-203 as-built per-entry shape, the predesign
   is UPDATED to match BD-203 (BD-203 as-built wins)").
2. **L13 (ADD US-6 create/reconcile):** renamed + **broadened**. New definition
   reads: "`_index.md` is a sidecar alongside `_intro.md` / `_rules.md` /
   `_toc.md` that may contain ONE OR MORE indexes or graphs for the per-entry
   flat files — including their ORDER or GROUPINGS, and OPTIONALLY a dependency
   graph (which MAY reference entries in another directory, e.g. TD entries
   depending on phase/implementation-plan entries). The dependency graph is NOT
   a default — it is created only if needed." Predesign pointers preserved
   (`ARCHITECTURE-BD-185-V2.md` §5.3, `…-ORDERING-ADDENDUM.md` §A-1,
   `ARCHITECTURE-BD-203-V3-AMENDMENT.md` §F.3), now annotated "authored under
   the former name `_order`." Reconcile→BD-203 intent preserved.
3. **L16/L17 (TRACK B):** `the conversion + `_order.md` IMPLEMENTATION` →
   `_index.md`. Renamed.
4. **L18/L19 (Acceptance criteria):** `carries an `_order.md` execution-ordering
   support-file` → `carries an `_index.md` index sidecar (carrying at least the
   execution-ordering index)`. Renamed + scope-consistent wording.
- **NEW DEFERRED-SWEEP ANCHOR (L14)** added between the create/reconcile
  clause and the DROP clause — see deviation judgment below.
- Status `Open` unchanged; Target/Position unchanged. All other clauses (KEEP,
  monolith-DELETE, DROP, dual-use-scripts, skill-masters, Out-of-scope,
  References) byte-unchanged.

**Definition-fidelity check:** the broadened BD-206 wording is a faithful,
near-verbatim capture of the user directive ("one-or-more indexes/graphs; order
or groupings; optional cross-directory dependency graph made only if needed")
and of census §0. SUPPORTED.

---

## Completeness gate (grep-zero) — PASS

```
$ git grep -c '_order\.md' -- backlog/
(no output; exit 1 = no matches)
```
Zero `_order.md` occurrences remain anywhere under `backlog/`. PASS.

`_index.md` is present in all 3 entries:
```
$ git grep -c '_index\.md' -- backlog/
backlog/BD-202.md:1
backlog/BD-203.md:1
backlog/BD-206.md:5
```
(BD-206 = 5 because the broadened definition + anchor reference `_index.md`
five times; the anchor adds one. All legitimate.)

**Whole-tree residual reconciliation** (proves nothing outside `backlog/` was
collateral-edited, and the deferred maintenance-docs were left intact):
```
$ git grep -c '_order\.md' -- ':!.git'   # summed
total lines: 50
```
Census measured 56 whole-tree lines; the 3 BD entries held 6 of them
(BD-202=1, BD-203=1, BD-206=4); 56 − 6 = **50**. Exact. The remaining 50 lines
across 11 files are ALL maintenance-docs (the user-DEFERRED predesign chain,
the BD-214 pipeline docs, and the archive) — correctly untouched:
```
maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-185-ARCHITECT-DOC-EDITS.md
maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-185-POST-PLANNER-POQS.md
maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md
maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-V2.md
maintenance-docs/v11-implementation/ARCHITECTURE-BD-203-V3-AMENDMENT.md
maintenance-docs/v11-implementation/ARCHITECTURE-BD-214-TRACKER-DEFERRAL.md
maintenance-docs/v11-implementation/AUDIT-BD-195-RETAINED-DECISIONS.md
maintenance-docs/v11-implementation/DECISION-PER-ENTRY-FORK-AND-BD185-SEQUENCING.md
maintenance-docs/v11-implementation/IMPL-REPORT-BD-214-C5a.md
maintenance-docs/v11-implementation/PACK-REVIEW-BD-214-C5a.md
maintenance-docs/v11-implementation/PLAN-BD-214-TRACKER-DEFERRAL.md
```

---

## Coder's flagged deviation — JUDGMENT: **SOUND**

To keep the zero-`_order.md` gate over `backlog/` absolute, the BD-206 anchor
(L14) refers to the OLD name historically as bare `_order` / `_order-generate.sh`
(no `.md` suffix) rather than `_order.md`. The bare-`_order` grep over
`backlog/` confirms the only `_order` tokens now in any BD entry are these
no-`.md` historical references (BD-203 note + BD-206 anchor); none is `_order.md`.

**Is the anchor still actionable?** YES. The anchor names every artifact the
future researcher+architect sweep must touch, with enough specificity to locate
each unambiguously:
- the predesign chain — `ARCHITECTURE-BD-185-V2.md` + its `-ORDERING-ADDENDUM`
  + `ARCHITECTURE-BD-203-V3-AMENDMENT.md` (named by full filename);
- the BD-214 design/plan/report docs (named by class);
- the archived BD-185 pipeline records (named by class);
- the unbuilt `_order-generate.sh` generator (named by full basename — the bare
  `_order-generate.sh` token, which is the real predesigned generator name and
  carries no `.md`, so it is genuinely accurate, not a lossy abbreviation);
- any pack-ops/scripts involvement;
- the census `RESEARCH-ORDER-MD-RENAME-CENSUS.md` (named, with the 56-refs /
  14-files headline + the "pure text, no built file / no validator-test
  hardcode" characterization).

A reader/agent following this anchor lands directly on the named docs and the
named generator; the bare `_order` is unambiguous in context ("the former
`_order` name," "the `_order`→`_index.md` rename (the former `.md` sidecar
basename)"). The phrase "the former `.md` sidecar basename" tells the reader
exactly which artifact carried `.md` historically, so no information is lost by
dropping the suffix here. The anchor is NOT too vague — it is, if anything,
more thorough than the prompt's minimum (it enumerates the docs, the generator,
the archive, AND the census). The deviation introduces no `_order.md` token
while remaining fully traceable. SOUND; no finding.

The BD-203 note uses the same device ("the prospective meta-doc formerly named
`_order` (the predesigned `.md` sidecar)") — same judgment: sound and
unambiguous.

---

## Scope check — PASS

```
$ git diff --name-only
backlog/BD-202.md
backlog/BD-203.md
backlog/BD-206.md
$ git diff --stat
 backlog/BD-202.md | 2 +-
 backlog/BD-203.md | 2 +-
 backlog/BD-206.md | 9 +++++----
 3 files changed, 7 insertions(+), 6 deletions(-)
```
- Only the 3 BD entries are modified. No maintenance-docs / scripts / ops /
  trinity / `_rules.md` edits.
- `_toc.md` is **unchanged** (`git status --short backlog/_toc.md` → empty).
  This is correct: only entry-body prose changed; no titles/IDs/status changed,
  so the generated TOC requires no regeneration. Confirmed by Check 33 (below)
  reporting `backlog/_toc.md byte-identical`.
- **No v11-surface delta.** The diff touches only `backlog/` — none of
  `project-template/`, `scripts/`, `pack-ops/`, `supporting-docs/`. So the
  `regenerate-manifest-v11-surface` rule does NOT trigger; no `manifest.txt`
  change is required or present. Correct.
- The untracked `?? maintenance-docs/...` files in `git status` (the BD-214
  GH-deletion reports, the IMPL-REPORT-BD-214-ORDER-INDEX-RENAME.md, the census,
  and this review) are pre-existing/parallel artifacts, NOT part of this rename
  change set and NOT modifications to deferred docs.

---

## Content + intent preservation — PASS

- BD-202: incidental rename only; no body content lost; no scope drift. ✓
- BD-203: D1 list rename + dated note; Status `Resolved` preserved (NOT
  reopened); body otherwise byte-identical. ✓
- BD-206: 4 renames + faithful broadening + new anchor; all other clauses
  byte-identical; the reconcile-predesign→BD-203-as-built directive preserved
  in both the FINDING (L6) and the create/reconcile clause (L13); the
  Track-B-only-TEXT framing preserved. ✓
- The broadened directive captures the user's new definition (one-or-more
  indexes/graphs; order or groupings; optional cross-directory dependency graph
  created only if needed) verbatim-in-substance. ✓

---

## Full CI suite — every wired script (NO sampling)

Run list extracted from `.github/workflows/validate-pack.yml` (both jobs:
`validate` + `tests`). Fixtures were rebuilt (`bash test-fixtures/build.sh
--all --clean` EXIT=0) and the committed `manifest.txt` restored before the
fixture-dependent tests, mirroring the workflow's step (a)/(a2) ordering.

### `validate` job
| Step | Command | EXIT |
|---|---|---|
| Run pack validation | `python3 scripts/validate-pack.py` | **0** (`PASSED — all checks clean`) |
| Run pack validation (DEEP) | `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | **0** (`PASSED — all checks clean`) |

Check 33 + Check 34 explicitly confirmed clean in the general run:
```
── Check 33: per-entry _toc.md is in-sync with per-entry tree (BD-168) ──
  OK: backlog/_toc.md byte-identical (22180 bytes)
  OK: changelog/_toc.md byte-identical (582 bytes)
── Check 34: cross-reference integrity (BD-168) ──
  OK: cross-reference integrity: 3145 reference(s) across 227 per-entry file(s);
      all resolved to defined IDs (or self-reference; leading-underscore
      supporting files are not walked)
```
(Check 33 byte-identical = no TOC regeneration needed; Check 34 = the rename
introduced no dangling cross-reference.)

### `tests` job — every enumerated script
All 49 pre-fixture scripts (workflow order) returned EXIT=0:

```
scripts/test-detect.sh                                            EXIT=0
scripts/tests/tracker-provider-test.sh                           EXIT=0
scripts/tests/tracker-config-test.sh                             EXIT=0
scripts/tests/tracker-init-test.sh                               EXIT=0
scripts/tests/tracker-agent-read-test.sh                         EXIT=0
scripts/tests/tracker-migrate-forward-test.sh                    EXIT=0
scripts/tests/tracker-migrate-reverse-test.sh                    EXIT=0
scripts/tests/tracker-migrate-roundtrip-test.sh                  EXIT=0
scripts/tests/test-tracker-phase-task.sh                         EXIT=0
scripts/tests/test-tracker-links.sh                              EXIT=0
scripts/tests/test-tracker-cycle-check.sh                        EXIT=0
scripts/tests/tracker-errors-test.sh                             EXIT=0
scripts/tests/tracker-config-schema-test.sh                      EXIT=0
scripts/tests/recommendation-state-schema-test.sh               EXIT=0
scripts/tests/test-per-entry.sh                                  EXIT=0
scripts/tests/test-validate-pack-checks-32-33-34.sh             EXIT=0
scripts/tests/test-validate-pack-checks-36-37-38.sh             EXIT=0
scripts/tests/test-validate-pack-check-39.sh                    EXIT=0
scripts/tests/test-validate-pack-check-40.sh                    EXIT=0
scripts/tests/test-validate-pack-check-41.sh                    EXIT=0
scripts/tests/test-validate-pack-check-18.sh                    EXIT=0
scripts/tests/test-validate-pack-check-16.sh                    EXIT=0
scripts/tests/test-validate-pack-check-19.sh                    EXIT=0
scripts/tests/test-validate-pack-check-42.sh                    EXIT=0
scripts/tests/test-validate-pack-check-43.sh                    EXIT=0
scripts/tests/test-validate-pack-check-44.sh                    EXIT=0
scripts/tests/test-validate-pack-check-45.sh                    EXIT=0
scripts/tests/test-validate-pack-check-46.sh                    EXIT=0
scripts/tests/test-validate-pack-check-removed-doc-advisory.sh  EXIT=0
scripts/tests/test-validate-pack-check-49-field-faithfulness.sh EXIT=0
scripts/tests/test-validate-pack-check-50-codec-single-source.sh EXIT=0
scripts/tests/test-validate-pack-check-51-flip-block.sh         EXIT=0
scripts/tests/tracker-deferral-gate-test.sh                     EXIT=0
scripts/tests/tracker-bd129-gh-repo-test.sh                     EXIT=0
scripts/tests/tracker-bd130-doctor-wired-test.sh               EXIT=0
scripts/tests/tracker-bd132-race-test.sh                        EXIT=0
scripts/tests/tracker-bd133-header-preservation-test.sh        EXIT=0
scripts/tests/tracker-bd134-close-retry-test.sh                EXIT=0
scripts/tests/recommendation-test.sh                            EXIT=0
scripts/tests/pack-help-test.sh                                 EXIT=0
scripts/tests/test-customization-preserve.sh                   EXIT=0
scripts/tests/test-init-project.sh                             EXIT=0
scripts/tests/test-migrate-v10-to-v11.sh                       EXIT=0
scripts/tests/test-migrate-v10-to-v11-dry-run.sh              EXIT=0
scripts/tests/test-migrate-v10-to-v11-gates.sh               EXIT=0
scripts/tests/test-migrate-v10-to-v11-decompose.sh           EXIT=0
scripts/test-migrator-core.sh                                EXIT=0
scripts/test-migrator-manifest.sh                            EXIT=0
scripts/test-migrator-capability-translation.sh             EXIT=0
```
GROUP-1: **PASS=49 FAIL=0**.

Fixture-dependent steps (post-build, workflow order):
```
test-fixtures/build.sh --all --clean (build)            EXIT=0
test-fixtures/build.sh --verify (manifest verify)        EXIT=0
  v11-flat-file OK / v11-tracker-on OK / existing-project-mid-dev OK
scripts/tests/test-v11-realistic-ot.sh                   EXIT=0
scripts/test-migrator-skills.sh                          EXIT=0
scripts/test-persona-contracts.sh                        EXIT=0
scripts/tests/template-translations-test.sh              EXIT=0
scripts/tests/template-version-test.sh                   EXIT=0
scripts/tests/test-issue-forms.sh                        EXIT=0
```
GROUP-2: **PASS=7 FAIL=0** (the single `EXIT=127` first observed for
`build.sh --verify` was a quoting artifact in the reviewer's loop passing
`--verify` as part of the path argument; re-run directly returned EXIT=0, shown
above — NOT a test failure).

**Full CI suite: ALL EXIT=0.**

---

## Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | Agents never commit | Only read-only git verbs run: `git rev-parse HEAD` (→ `935d9a5e…`), `git branch --show-current` (→ `v11-dev`), `git status --short`, `git diff`, `git grep`, `git checkout HEAD -- test-fixtures/manifest.txt` (read-only restore, no branch mutation). No `git add/commit/push/tag`. | COMPLIANT |
| 2 | Read-only mandate (Write ONLY this report) | Sole filesystem write is this report at `maintenance-docs/v11-implementation/PACK-REVIEW-BD-214-ORDER-INDEX-RENAME.md`. All other tools were `Read` / `Bash` (grep/find/test-runners). Fixture build wrote only gitignored build artifacts under `test-fixtures/` then restored the committed manifest — no tracked codebase file was edited by the reviewer. | COMPLIANT |
| 3 | Independent verification (every PASS carries command + quoted output; grep-zero + full wired-test mandatory) | Every PASS above quotes the exact command + output: grep-zero `git grep -c '_order\.md' -- backlog/` → exit 1 / no matches; whole-tree residual = 50 reconciled (56−6); validate-pack general+DEEP EXIT=0; all 49 + fixture-dependent wired scripts EXIT=0; Check 33/34 quoted. | COMPLIANT |
| 4 | Content + intent preserved | Diff inspected line-by-line: BD-203 `Status: Resolved` line unchanged (not reopened); all non-renamed clauses byte-identical; BD-206 broadened directive quoted and matched to user directive + census §0; reconcile→BD-203-as-built intent present in L6 + L13. | COMPLIANT |
| 5 | Severity-tagged findings (BLOCKER/MUST/SHOULD/NIT with file:line) | No findings at any severity. Each per-entry analysis cites file + clause/line (BD-202 L14; BD-203 L5; BD-206 L6/L13/L14/L16/L18). Verdict CLEAN. | COMPLIANT |
| 6 | Rules-Applied Verification Block | This table — each rule: name + quoted/measured evidence + terminal conclusion; no empty evidence; no AMBIGUOUS. | COMPLIANT |
| 7 | PREFLIGHT + STOP-MEANS-STOP | Emitted `PREFLIGHT: review complete; backlog _order.md count=0 confirmed; full CI wired-test job run; about to Write <path>` in the assistant turn immediately before this Write. No parent stop/halt message received. | COMPLIANT |
