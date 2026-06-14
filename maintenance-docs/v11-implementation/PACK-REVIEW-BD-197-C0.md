# PACK-REVIEW — BD-197 C0: Check 36 manifest carve-out

**Reviewer:** pack-reviewer (fresh). **Mode:** read-only on the codebase;
sole write = this report. **Repo:** optiquity-ai-agent-config-pack-v11-dev ·
**Branch:** v11-dev · **HEAD:** `3250887cdd08587443f33d06bcb3613404e393f5` ·
**Date:** 2026-06-13.

## VERDICT: APPROVE

The C0 carve-out matches design §17 byte-for-byte, is sized to exactly
`{test-fixtures/manifest.txt}`, provably does not weaken the guard
(independently reproduced), ships its test in lockstep with non-vacuous
cases (mutation-tested), and the full CI battery is green. No defects.

---

## Read attestation

Read IN FULL / in relevant part before reviewing:
- `ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` — §0–§9 (context) +
  §17.1–§17.8 (the C0 spec; lines 617–877) directly.
- `git diff scripts/validate-pack.py` + `git diff
  scripts/tests/test-validate-pack-checks-36-37-38.sh` (the actual unstaged
  changes).
- `maintenance-docs/v11-implementation/IMPL-REPORT-BD-197-C0-CARVEOUT.md`
  (coder claims — independently re-verified, not trusted).
- `CLAUDE.md` `## Pack memory` (ci-guard-measure-then-bound,
  ci-check-runtime-compounding, enumerate-encoding-surfaces,
  verify-full-ci-suite, regenerate-manifest-v11-surface,
  scope-deliverables-to-the-ask, agents-never-commit) via session context.

---

## Spec conformance (design §17.4 / §17.6)

All four required mutations present and verbatim-correct:

1. **Constant** (`scripts/validate-pack.py:4136`):
   `_SCOPE_NEUTRAL_GENERATED_PATHS = frozenset({"test-fixtures/manifest.txt"})`
   — type confirmed `frozenset`, single member. Placed beside
   `_PROJECT_SIDE_PATH_PREFIXES` per spec.
2. **Predicate** (`:4268`): `_is_scope_neutral_generated(path)` returns
   `path in _SCOPE_NEUTRAL_GENERATED_PATHS` — exact-string set membership,
   placed beside `_is_project_side_path`. Docstring names the §17 source and
   the snapshot/recipe-not-exempt rationale.
3. **Both offender branches** carry `and not _is_scope_neutral_generated(p)`
   — `grep -c` = exactly **2** (the `is_pack_only` + `is_project_only`
   comprehensions at `:4339` / `:4353`). No third occurrence.
4. **`is_pack_chat_only` branch UNCHANGED** — re-read `:4363`, still
   `offenders = [p for p in paths if not _is_pack_chat_only_permitted(p)]`.
   No leak.

The diff is precisely the §17.4 design code (matching comments, matching
docstring intent). No scope creep.

## EXACT-PATH, not prefix (verified)

Independent predicate probe (patched module, HEAD `3250887c`):
```
neutral('test-fixtures/manifest.txt')                          = True
neutral('scripts/validate-pack.py')                            = False
neutral('test-fixtures/v11-trinity-marker-prepped/CLAUDE.md')  = False
neutral('test-fixtures/build.sh')                              = False
neutral('test-fixtures/README.md')                            = False
neutral('test-fixtures/manifest.txt ')   (trailing space)     = False
neutral('TEST-FIXTURES/MANIFEST.TXT')    (case)               = False
neutral('a/test-fixtures/manifest.txt')  (embedded)           = False
neutral('test-fixtures/manifest.txt.bak')(suffix)             = False
```
Exact-string membership confirmed — NOT a `test-fixtures/` prefix; the
static `v11-trinity-marker-prepped/` snapshot and the `build.sh`/`README.md`
recipe are NOT exempt. Sized exactly to the one measured forced-co-variant
path (measure-then-bound).

## Guard NOT weakened (independently reproduced)

Reproduced the patched offender comprehensions directly against the live
module (not from the IMPL-REPORT):
```
(a) project-only [project + manifest]                  -> []                                  (PASS)
(b) pack-only    [pack + manifest]                     -> []                                  (PASS)
(c) cross-surface [project + scripts/validate-pack.py + manifest]
                                                       -> ['scripts/validate-pack.py']        (STILL FAILS)
(c2) pack-only [pack + project-template/CLAUDE.md + manifest]
                                                       -> ['project-template/CLAUDE.md']      (STILL FAILS)
(d) project-only [project + static snapshot]           -> ['...v11-trinity-marker-prepped/CLAUDE.md'] (STILL FAILS)
(d2) project-only [project + build.sh]                 -> ['test-fixtures/build.sh']          (STILL FAILS)
(d3) pack-only [pack + supporting-docs/foo.md + manifest]
                                                       -> ['supporting-docs/foo.md']          (STILL FAILS)
```
All four required not-weakened conditions hold: (a) project-only+manifest
passes; (b) pack-only+manifest passes; (c) genuine cross-surface still
fails; (d) static snapshot + recipe NOT exempt. The carve-out admits ONLY
the manifest; every other cross-surface path is still an offender on both
surfaces.

## Test quality — non-vacuous (mutation-tested)

- Group-0 `required` registers `_is_scope_neutral_generated` (`:50`) — the
  new symbol is asserted present.
- NC-1..NC-3 exercise the predicate; NC-4..NC-7 reproduce the two patched
  offender comprehensions and assert the four directions (project-only pass,
  pack-only pass, cross-surface fail, snapshot fail). NC-7 (snapshot at the
  offender level) is an ADDITIVE strengthening beyond the §17.6 NC-1..NC-6
  spec — surfaced in IMPL-REPORT §9 D1, purely additive, no spec'd case
  removed/weakened. Legitimate, in-scope (it asserts §17.5(a)'s symmetric
  not-weakened claim at the level the guard runs).
- **Non-vacuity proof:** I temporarily emptied the frozenset
  (`frozenset()`) in a `/tmp` copy and ran the test — it FAILED with
  NC-1, NC-4, NC-6, NC-7 (and FAIL count 1) firing. The cases genuinely
  depend on the carve-out; they are not always-pass. Real module restored
  byte-identical afterward (`diff -q` clean; `git diff --stat` unchanged).
- Test run: `bash scripts/tests/test-validate-pack-checks-36-37-38.sh` →
  **EXIT=0**, `PASS: 8  FAIL: 0`.

## Full CI suite (independently re-run; green)

| Command | Exit |
|---|---|
| `python3 scripts/validate-pack.py` | **0** (`PASSED — all checks clean`) |
| `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | **0** (`PASSED — all checks clean`) |
| `test-validate-pack-checks-36-37-38.sh` (changed) | 0 |
| `test-validate-pack-checks-32-33-34.sh` | 0 |
| `test-validate-pack-check-43.sh` | 0 |
| `test-validate-pack-check-51-flip-block.sh` | 0 |
| `test-per-entry.sh` | 0 |
| `test-issue-forms.sh` | 0 |
| `test-customization-preserve.sh` | 0 |
| `test-v11-realistic-ot.sh` (output-pinning integration) | 0 |
| `test-detect.sh` | 0 |
| `build.sh --all --clean` | 0 |
| `build.sh --verify` | 0 |

Representative sample includes the integration test that pins validator
banner/output (`test-v11-realistic-ot.sh`, per the verify-full-ci-suite
memory) — green. The coder's "60/60 green" claim reproduces on every
command I sampled; no non-reproduction observed.

## Manifest + scope (regenerate-manifest-v11-surface)

```
cp test-fixtures/manifest.txt /tmp/manifest-before.txt
bash test-fixtures/build.sh --all --clean      -> BUILD_EXIT=0
diff /tmp/manifest-before.txt test-fixtures/manifest.txt -> MANIFEST_DIFF_EMPTY=yes
git status --porcelain test-fixtures/manifest.txt project-template/ pack-ops/ supporting-docs/ -> (empty)
```
Editing `validate-pack.py` feeds no client fixture → no v11 fixture
installed-HEAD SHA changed → rebuilt manifest is byte-identical. The rule
says stage ONLY if non-empty; diff is EMPTY → manifest correctly NOT
staged → C0 stays cleanly `pack-only`. Correct.

`git status --short` at HEAD `3250887c`:
```
 M scripts/tests/test-validate-pack-checks-36-37-38.sh
 M scripts/validate-pack.py
?? maintenance-docs/v11-implementation/IMPL-REPORT-BD-197-C0-CARVEOUT.md
```
Exactly the check + its test + the IMPL-REPORT. No other file touched, no
`pack_chat_only` branch change, no design/plan-doc edit. Clean.

## Runtime (ci-check-runtime-compounding)

The carve-out is one `frozenset` membership test per offender candidate on
the already-materialized path list — O(1) per path, no new subprocess, no
per-entry storm, no whole-tree scan. Check 36 still walks only the commits
in its range (default HEAD). Negligible, non-compounding. COMPLIANT.

---

## Findings

**BLOCKER:** none.
**MUST:** none.
**SHOULD:** none.

**NIT (pre-existing, NOT introduced by C0 — do not fix in C0):** Group 1 of
`test-validate-pack-checks-36-37-38.sh` emits cosmetic shell-noise at line
75 (`pack-ops/BACKLOG.md: No such file or directory`, `backlog/: is a
directory`, `fatal: No pathspec was given`) from the long-standing UNQUOTED
`<<EOF` heredoc expanding pre-existing `assert_pm(...)` path-string
arguments. Confirmed pre-existing via `git show HEAD:` (identical at line
75). The test still exits 0; correctness unaffected. The coder correctly
surfaced this as out-of-scope (IMPL-REPORT §10) and added NO new noise (no
backticks in the inserted block — verified). Tracking it is optional; it is
not a C0 defect.

## IMPL-REPORT cross-check

Every IMPL-REPORT empirical claim reproduces independently: conflict-real
(§2), not-weakened proof (§4), manifest-empty (§5), test EXIT=0 (§6),
O(1)/wall-time (§7), full-suite green (§8). The §9 NC-7 deviation is
genuinely additive. No mislabeled COMPLIANT, no overclaim. HEAD cited in
the report (`3250887c`) matches the working-tree HEAD.

---

## Rules-Applied Verification Block

| Rule | Evidence (quoted/measured) | Conclusion |
|---|---|---|
| **ci-guard-design-measure-then-bound** | Frozenset = `{'test-fixtures/manifest.txt'}` (single path, sized to §17.3 measured set). Independent not-weakened probe: cross-surface `-> ['scripts/validate-pack.py']`; snapshot `-> ['...v11-trinity-marker-prepped/CLAUDE.md']`; recipe `-> ['test-fixtures/build.sh']` — all STILL offenders. Allowlist not widened. | COMPLIANT |
| **ci-check-runtime-compounding** | One `frozenset` membership per path on already-materialized list; no subprocess, no per-entry storm, no whole-tree scan; Check 36 default-range = HEAD. | COMPLIANT |
| **enumerate-encoding-surfaces** | Both surfaces changed in one edit set: `validate-pack.py` (check) + `test-validate-pack-checks-36-37-38.sh` (test); new symbol registered in Group-0 `required` (`:50`); `git status --short` shows exactly these two + the IMPL-REPORT. | COMPLIANT |
| **verify-full-ci-suite** | Independently re-ran validate-pack ×2 (both EXIT 0, `PASSED — all checks clean`) + 11 wired scripts incl. the output-pinning integration `test-v11-realistic-ot.sh` (all EXIT 0) + build/verify (0). No non-reproduction. | COMPLIANT |
| **regenerate-manifest-v11-surface** | `build.sh --all --clean` EXIT 0; `MANIFEST_DIFF_EMPTY=yes`; `git status --porcelain` over all five v11-surface dirs empty → manifest correctly unstaged (diff empty). | COMPLIANT |
| **empirical-evidence-blocks** | Every claim above carries the command + verbatim output + HEAD `3250887cdd08587443f33d06bcb3613404e393f5` + date 2026-06-13. Mutation test (empty frozenset → NC failures) quoted verbatim. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Reviewed ONLY C0's carve-out + test; confirmed `pack_chat_only` untouched, no design/plan edit, exactly 2 modified files. Surfaced one pre-existing NIT, invented no nits, softened no blocker. | COMPLIANT |
| **agents-never-commit** | Only read-only git verbs run: `rev-parse`, `status`, `diff`, `show`, `checkout HEAD -- test-fixtures/manifest.txt` (read-only path-restore after the empty-diff build). No `add`/`commit`/`push`/`stash`/`reset`/`branch`-mutating verb. The temporary module mutation was on `/tmp` copies; the real `validate-pack.py` restored byte-identical (`diff -q` clean). Sole codebase write = this report. | COMPLIANT |
| **rules-applied-verification-block** | This block. | COMPLIANT |

---
*End of PACK-REVIEW-BD-197-C0.md*
