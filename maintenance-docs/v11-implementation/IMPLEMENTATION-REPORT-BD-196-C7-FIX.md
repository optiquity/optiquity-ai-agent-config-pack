# IMPLEMENTATION-REPORT — BD-196 C7-FIX (fix-coder pass 1)

**Branch:** `v11-dev`
**HEAD at start (and end — agents never commit):** `f2aeb62ce7c24e9fedf8488c09d07baf2cf60506`
**Role:** fresh `pack-coder` applying ONE user-approved SHOULD finding from C7 reviewer pass 1.
**Scope:** the C7 edits are uncommitted in the working tree; this fix is applied in place before commit.

---

## 1. Pre-flight

| Check | Result |
|---|---|
| `git rev-parse HEAD` | `f2aeb62ce7c24e9fedf8488c09d07baf2cf60506` |
| `git status` | clean tree base; 2 modified (C7 edits) + 2 untracked C7 reports — as expected |
| target files exist | both `scripts/tests/test-validate-pack-checks-36-37-38.sh` and `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-196-C7.md` present |

---

## 2. The finding (SHOULD, user-approved FIX)

In `scripts/tests/test-validate-pack-checks-36-37-38.sh`, the new `G7.T5` **comment**
lines (687, 690) contained backtick-with-parens tokens inside the **unquoted** `<<EOF`
heredoc (opener at line 584). The shell attempted command-substitution on the backticks,
producing **2** stderr lines on every run:

```
command substitution: line 585: syntax error: unexpected end of file
```

Functionally benign (test still PASS 8/0, the failed substitution expands to empty inside
`#` comments) but it is CI-stderr noise AND the C7 IMPL-REPORT §5 mislabeled it as
"pre-existing / not introduced by C7."

---

## 3. Edits made (exact)

### Edit 1 — `scripts/tests/test-validate-pack-checks-36-37-38.sh` (G7.T5 comment, lines 687 + 690)

Removed the backticks from the two offending comment tokens. Function names are now plain
text. The `<<EOF` heredoc delimiter was **kept UNQUOTED** (it legitimately expands
`$REPO_ROOT` / `$VALIDATE`). Only comment text changed — no test logic touched.

Before:
```
# G7.T5: Check 37's walk (`_iter_project_side_files()`) is the
#   client-installed inventory PLUS the two companion-template dirs
#   (BD-196 C7 / plan §3 D1). The companion files appear in Check 37's
#   walk-set but MUST NOT appear in `_iter_client_installed_files()`
```

After:
```
# G7.T5: Check 37's walk (_iter_project_side_files) is the
#   client-installed inventory PLUS the two companion-template dirs
#   (BD-196 C7 / plan §3 D1). The companion files appear in Check 37's
#   walk-set but MUST NOT appear in _iter_client_installed_files()
```

Re-read of lines 684–699 after the edit confirms: backticks gone from 687/690; the `<<EOF`
opener (line 584) is unchanged/unquoted; the Python comment block + `if hasattr(...)` test
logic below are structurally intact.

### Edit 2 — `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-196-C7.md` §5

Replaced the "Note on harmless stderr" paragraph that called the stderr lines
"pre-existing / not introduced by C7." The corrected note states accurately: the 2 stderr
lines were **C7-introduced** (0 at HEAD `f2aeb62`, 2 after the original C7 edit), the cause
was backtick-with-parens tokens in the new G7.T5 comment lines, and the lines are removed by
this fix-coder pass (cross-referencing this report). Re-read of §5 confirms the paragraph is
replaced in place and surrounding sections (§4 / §6 boundaries, the "168 vs 171" note above
it, the `---` separator below) are intact.

---

## 4. Before/After stderr-count proof

| State | Command | `syntax error` lines | `command substitution` lines | Test result |
|---|---|---|---|---|
| BEFORE (original C7 edit) | `bash scripts/tests/test-validate-pack-checks-36-37-38.sh 2>err` | **2** | **2** | EXIT 0, PASS 8 / FAIL 0 |
| AFTER (this fix) | same | **0** | **0** | EXIT 0, PASS 8 / FAIL 0 |

BEFORE stderr (verbatim):
```
scripts/tests/test-validate-pack-checks-36-37-38.sh: command substitution: line 585: syntax error: unexpected end of file
scripts/tests/test-validate-pack-checks-36-37-38.sh: command substitution: line 585: syntax error: unexpected end of file
```

AFTER stderr: empty (0 lines). No regression — PASS count held at 8/0.

---

## 5. validate-pack result

```
python3 scripts/validate-pack.py  →  EXIT 0
PASSED — all checks clean
```

---

## 6. Per-check test results

| Command | Result |
|---|---|
| `bash scripts/tests/test-validate-pack-checks-36-37-38.sh` | EXIT 0 — PASS: 8, FAIL: 0 (incl. G7.T5) |

(The fix touches only this one test file; Check 41 / Check 43 tests were verified PASS in the
original C7 IMPL-REPORT §5 and are not re-affected by a comment-only change.)

---

## 7. Manifest regeneration

```
bash test-fixtures/build.sh --all --clean  →  EXIT 0
git diff --stat test-fixtures/manifest.txt  →  (empty)
```

Manifest diff is **EMPTY** — no change to `test-fixtures/manifest.txt`. (Do NOT stage — Pack
Chat handles staging. There is nothing to stage for the manifest regardless.)

---

## 8. ENCODING-surface check

The fix changes ONLY comment text in a single TEST file. There is no paired
validator/workflow surface that encodes the comment's content — the comment is not an
asserted invariant. `validate-pack.py` was NOT edited by this fix (its working-tree
modification is the pre-existing C7 edit, untouched). No lock-step surface update required.

---

## 9. Files changed (this fix)

| Path | Change type |
|---|---|
| `scripts/tests/test-validate-pack-checks-36-37-38.sh` | modified (comment-only; lines 687, 690) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-196-C7.md` | modified (§5 stderr note corrected) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-196-C7-FIX.md` | new (this report) |

`scripts/validate-pack.py` remains modified in the working tree from the original C7 edit —
**not touched by this fix-coder pass.**

---

## 10. Plan deviations

None. The fix matches SECTION 3 exactly (two targeted edits; heredoc kept unquoted; only
comment text + report note changed).

---

## 11. New POQs introduced

None.

---

## 12. Definition-of-Done checklist

| Item | Result |
|---|---|
| Edit 1 removes backticks; heredoc still unquoted | PASS |
| stderr syntax-error lines 2 → 0 | PASS |
| Test still passes (8/0, no regression) | PASS |
| Edit 2 corrects "pre-existing" mislabel to "C7-introduced" | PASS |
| `python3 scripts/validate-pack.py` EXIT 0 clean | PASS |
| Manifest regenerated; diff reported (EMPTY) | PASS |
| No other file changed; no test logic altered | PASS |
| No state-changing git verb run | PASS |

---

## 13. Rules-Applied Verification Block

| Rule | Evidence | Conclusion |
|---|---|---|
| **Agents never commit** | Only `git rev-parse`, `git status`, `git diff --stat` (read-only) run. No `add/commit/push/tag/mv/rm`. End HEAD = `f2aeb62` (unchanged). | COMPLIANT |
| **Per-action approval extends to sub-agents** | No destructive file op performed; `cp` was to `/tmp` only; no `rm`/overwrite of tracked files. | COMPLIANT |
| **Pack-coder PREFLIGHT + STOP-MEANS-STOP** | Emitted `PREFLIGHT: 2/2 in-scope edits complete; verification PASS; HEAD f2aeb62; about to Write fix-report ...` only after both edits + validate + per-check test + manifest all PASS. No stop message received. | COMPLIANT |
| **Agent output requires Rules-Applied Verification Block** | This table, with quoted command output throughout (§4 stderr counts, §5 validate, §7 manifest). | COMPLIANT |
| **Edit-in-place, not full rewrite** | Two targeted `Edit` calls; both edited regions re-read (test lines 684–699; report §5) and confirmed structurally intact — see §3. | COMPLIANT |
| **Enumerate ENCODING surfaces** | §8: comment-only change; no paired validator/workflow/test encodes this comment as an invariant; `validate-pack.py` not edited by this fix. | COMPLIANT |
| **Regenerate test-fixtures/manifest.txt on v11-surface commits** | `scripts/tests/` touched → ran `bash test-fixtures/build.sh --all --clean` (EXIT 0); `git diff --stat` reports EMPTY manifest diff (§7); not staged (Pack Chat stages). | COMPLIANT |
| **Truthful reporting** | Report states the stderr lines were C7-introduced (0 at HEAD → 2 after C7 edit, §4); Edit 2 corrects the prior false "pre-existing" claim in the C7 IMPL-REPORT §5. No false provenance repeated. | COMPLIANT |
