# IMPL-REPORT: BD-219 C4 F-1 Fix — JSON-quoting in CI parallelization example

**Branch:** v11-dev
**HEAD SHA:** 26a0179ecc8e00761c53c80e0f60bf0752a58b48
**Regime:** In-place
**Date:** 2026-06-15

---

## Summary

Fix-coder for review finding F-1 (SHOULD): the `plan` job's `echo` command
in `project-template/docs/pack/OPTIONAL-FEATURES.md` used double-quotes
around the JSON literal, causing the shell to strip all nested `"` characters
and produce invalid JSON that `fromJSON(needs.plan.outputs.matrix)` cannot parse.

Single-quoting the JSON literal makes it emit correctly.

---

## Before / After

### Before (broken)

```yaml
- id: plan
  run: echo "matrix={"include":[{"suite":"unit"},{"suite":"integration"}]}" >> "$GITHUB_OUTPUT"
```

Shell interpretation: the outer double-quotes cause nested `"` to terminate and
re-open the quoted string around bare words. The shell strips them all, producing:

```
matrix={include:[{suite:unit},{suite:integration}]}
```

That is **not valid JSON**. `fromJSON(...)` in the `tests` job would fail.

### After (fixed)

```yaml
- id: plan
  run: echo 'matrix={"include":[{"suite":"unit"},{"suite":"integration"}]}' >> "$GITHUB_OUTPUT"
```

Single-quoting the entire JSON literal preserves every `"` character verbatim.

### Valid-JSON proof

Simulation (run locally):

```
$ echo 'matrix={"include":[{"suite":"unit"},{"suite":"integration"}]}' >> /tmp/test-json-fix.txt
$ python3 -c "
import json
with open('/tmp/test-json-fix.txt') as f:
    line = f.read().strip()
val = line[len('matrix='):]
parsed = json.loads(val)
print('VALID JSON:', parsed)
"
VALID JSON: {'include': [{'suite': 'unit'}, {'suite': 'integration'}]}
```

`json.loads()` parses cleanly → exit 0.

Contrast with the broken form:

```
$ echo "matrix={"include":[{"suite":"unit"},{"suite":"integration"}]}" >> /tmp/test-broken.txt
$ cat /tmp/test-broken.txt
matrix={include:[{suite:unit},{suite:integration}]}
```

All `"` stripped — invalid JSON.

---

## File touched

| File | Change type | Delta |
|---|---|---|
| `project-template/docs/pack/OPTIONAL-FEATURES.md` | Modified | 1 line changed (line 347) |
| `test-fixtures/manifest.txt` | Modified | 3 hash lines updated (fixture rebuild required by `regenerate-manifest-v11-surface` rule) |

No other files touched.

---

## Verification commands and results

| Command | Result |
|---|---|
| `python3 scripts/validate-pack.py` | `PASSED — all checks clean` (exit 0) |
| `bash scripts/tests/test-validate-pack-check-43.sh` | `All tests passed.` (PASS: 9, FAIL: 0) |
| `bash scripts/tests/test-validate-pack-check-54.sh` | `All tests passed.` (PASS: 3, FAIL: 0) |
| `bash test-fixtures/build.sh --all --clean` | Manifest written; 3 fixture hashes updated |
| `git status --short` | `M project-template/docs/pack/OPTIONAL-FEATURES.md` + `M test-fixtures/manifest.txt` + 2 pre-existing untracked `.md` files (not this fix) |

---

## Plan deviations

None. The fix is exactly and only the one-line JSON-quoting change specified in F-1.

## New POQs

None.

---

## Definition-of-Done checklist

| Item | Status |
|---|---|
| F-1: broken double-quoted echo replaced with single-quoted echo | PASS |
| Valid-JSON proof shown (python3 parse succeeds) | PASS |
| No other lines changed in OPTIONAL-FEATURES.md | PASS |
| No pack-self tokens in the edited section | PASS |
| `validate-pack.py` exit 0 | PASS |
| `test-validate-pack-check-43.sh` pass | PASS |
| `test-validate-pack-check-54.sh` pass | PASS |
| Manifest regenerated; diff non-empty (correctly reflects content change) | PASS |
| `git status --short` shows only expected files | PASS |
| No git state-changing verbs run | PASS |

---

## Boundary discipline check

File edited: `project-template/docs/pack/OPTIONAL-FEATURES.md` — a client-shipped doc.

Investigation: the change is a one-character shell-quoting fix within an existing
GitHub Actions YAML example. No pack-self concept is introduced. The edited section
contains no reference to `BD-`, `pack-*` agent names, `pack-ops`, `maintenance-docs`,
`ci-shard-plan`, or `validate-pack`. The fix is generic GitHub Actions advice —
single-quote a JSON literal in a shell `echo`. No project-side SSOT exists for
"how to quote a shell string in a YAML example" — this is a code-correctness fix
with no SSOT cross-reference needed.

Result: **no boundary stop; no pack-self leak introduced or present.**

---

## Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| **boundary-investigation / P-missed-7** | Edited file is `project-template/docs/pack/OPTIONAL-FEATURES.md`. Section reviewed for pack-self tokens: no `BD-`, no `pack-*`, no `pack-ops`, no `maintenance-docs`, no `ci-shard-plan`, no `validate-pack` in the edited line or its surrounding example. Generic GitHub Actions content only. | COMPLIANT |
| **edit-in-place-not-full-rewrite** | Exactly one line changed (line 347): `echo "matrix=…"` → `echo 'matrix=…'`. File re-read after edit confirms only that line differs. All 429 other lines unchanged. | COMPLIANT |
| **verify-full-ci-suite** | `python3 scripts/validate-pack.py` → `PASSED — all checks clean` (exit 0). `bash scripts/tests/test-validate-pack-check-43.sh` → `All tests passed.` PASS:9 FAIL:0. `bash scripts/tests/test-validate-pack-check-54.sh` → `All tests passed.` PASS:3 FAIL:0. | COMPLIANT |
| **regenerate-manifest-v11-surface** | `project-template/` was touched → ran `bash test-fixtures/build.sh --all --clean`. Manifest diff non-empty (3 fixture hash lines updated). Manifest updated in working tree. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Only the JSON-quoting fix applied. No other changes to OPTIONAL-FEATURES.md or any other source file. | COMPLIANT |
| **agents-never-commit** | No `git add`, `git commit`, `git push`, or any state-changing git verb run. Only `git diff`, `git status`, `git rev-parse` (read-only). | COMPLIANT |
| **preflight-stop-means-stop** | All edits complete; valid-JSON proof shown; validate-pack exit 0; leak-scanner pass; git status project-only (OPTIONAL-FEATURES.md + manifest only). PREFLIGHT line emitted before report. | COMPLIANT |
| **rules-applied-verification-block** | This block present; per-rule evidence quoted (command names + exit codes + pass/fail counts); all entries COMPLIANT. No empty-evidence entries. | COMPLIANT |
