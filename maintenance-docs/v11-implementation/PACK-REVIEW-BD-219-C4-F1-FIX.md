# PACK-REVIEW: BD-219 C4 F-1 Fix — JSON-quoting in CI parallelization example

**VERDICT: APPROVE** — the broken double-quoted `echo` is gone, replaced by a
single-quoted form that emits valid, `json.loads`-parseable JSON; the F-1 change
is one line, boundary-clean, and the full CI suite passes.

- **Branch:** v11-dev
- **HEAD SHA:** `26a0179ecc8e00761c53c80e0f60bf0752a58b48`
- **Date:** 2026-06-15
- **Scope:** `project-only`
- **Mode:** read-only; reviewed via `git diff` / `git status` (uncommitted working tree)

---

## 1. Valid-JSON confirmation (the F-1 fix)

**Corrected line present, single-quoted (line 347):**
```
$ grep -n "echo 'matrix=" project-template/docs/pack/OPTIONAL-FEATURES.md
347:         run: echo 'matrix={"include":[{"suite":"unit"},{"suite":"integration"}]}' >> "$GITHUB_OUTPUT"
```

**Old double-quoted form is GONE:**
```
$ grep -n 'echo "matrix=' project-template/docs/pack/OPTIONAL-FEATURES.md
$ echo "exit: $?"
exit: 1            # no match — broken form removed
$ grep -n "matrix={include" project-template/docs/pack/OPTIONAL-FEATURES.md
$ echo "exit: $?"
exit: 1            # no stripped-quote artifact anywhere in file
$ grep -c "run: echo 'matrix=" project-template/docs/pack/OPTIONAL-FEATURES.md
1                  # exactly one corrected echo
```

**Simulation — corrected echo emits parseable JSON (exit 0):**
```
$ echo 'matrix={"include":[{"suite":"unit"},{"suite":"integration"}]}' >> /tmp/rev-json-fix.txt
$ cat /tmp/rev-json-fix.txt
matrix={"include":[{"suite":"unit"},{"suite":"integration"}]}
$ python3 -c "import json; ...; json.loads(line[len('matrix='):])"
VALID JSON parsed OK: {'include': [{'suite': 'unit'}, {'suite': 'integration'}]}
parse exit: 0
```

**Counter-proof — the OLD double-quoted form is genuinely broken (fix is load-bearing):**
```
$ echo "matrix={"include":[{"suite":"unit"},{"suite":"integration"}]}" >> /tmp/rev-broken.txt
$ cat /tmp/rev-broken.txt
matrix={include:[{suite:unit},{suite:integration}]}
INVALID JSON as expected: Expecting property name enclosed in double quotes: line 1 column 2 (char 1)
```
The shell stripped every nested `"` from the double-quoted form, yielding invalid
JSON that `fromJSON(needs.plan.outputs.matrix)` would reject. The single-quoted
fix preserves all `"` verbatim. CONFIRMED.

---

## 2. Boundary confirmation (P-missed-7) — clean

```
$ sed -n '306,424p' project-template/docs/pack/OPTIONAL-FEATURES.md \
    | grep -nE 'BD-|pack-ops|maintenance-docs|ci-shard-plan|validate-pack|pack-coder|pack-reviewer|pack-architect|pack-planner|pack-chat|PACK-'
$ echo "exit: $?"
exit: 1            # zero pack-self tokens in the section
```
The CI-parallelization section is generic GitHub Actions guidance — no `BD-`,
no `pack-*` agent names, no `pack-ops`, no `maintenance-docs`, no `ci-shard-plan`,
no `validate-pack`. Project-native, zero leak.

Leak scanner:
```
$ bash scripts/tests/test-validate-pack-check-43.sh   →  All tests passed.  (PASS 9 / FAIL 0)  exit 0
```

---

## 3. Scope confirmation — F-1 change is one line; source scope correct

The full `git diff` of `OPTIONAL-FEATURES.md` shows the entire 113-line C4 section
as added (C4 itself is uncommitted), but the **F-1 fix is exactly the single
`echo` line at 347** — verified by: (a) exactly one `run: echo 'matrix=` match,
(b) zero remaining double-quoted/stripped artifacts, (c) the IMPL-REPORT before/after
naming only that line. No other section content altered by F-1.

```
$ git status --short
 M project-template/docs/pack/OPTIONAL-FEATURES.md
 M test-fixtures/manifest.txt
?? maintenance-docs/v11-implementation/IMPL-REPORT-BD-219-C4-F1-FIX.md     (this fix's report)
?? maintenance-docs/v11-implementation/IMPL-REPORT-BD-219-C4.md            (C4-cycle artifact, 12:34)
?? maintenance-docs/v11-implementation/PACK-REVIEW-BD-219-C4.md            (C4-cycle artifact, 12:39)
```

The two extra untracked `.md` files are prior **C4-cycle** maintenance-docs
(timestamps 12:34 / 12:39 — both pre-date the F-1 IMPL-REPORT at 12:51), NOT
products of this F-1 fix. The F-1 fix itself touched only
`OPTIONAL-FEATURES.md` + `manifest.txt` and wrote its own IMPL-REPORT. Source
scope is exactly the expected `project-only` pair; the extra maintenance-docs are
out-of-source-scope review artifacts with no committed-source impact.
(Note for the committing actor: the C4 IMPL-REPORT / PACK-REVIEW are separate
C4-cycle artifacts — handle per the C4 commit, not this F-1 review.)

---

## 4. CI confirmation — full suite green

| Command | Exit | Result |
|---|---|---|
| `python3 scripts/validate-pack.py` (no-flag = authoritative full run) | 0 | `PASSED — all checks clean` |
| `bash scripts/tests/test-validate-pack-check-43.sh` (leak scanner) | 0 | `All tests passed.` (PASS 9 / FAIL 0) |
| `bash scripts/tests/test-validate-pack-check-54.sh` | 0 | `All tests passed.` (PASS 3 / FAIL 0) |
| `bash test-fixtures/build.sh --all --clean` | 0 | manifest reproduces; `git status` unchanged after rebuild → manifest canonical |
| JSON-parse simulation (`json.loads`) | 0 | corrected echo parses; broken form rejected |

**Note on `--deep`:** the prompt asked for "general + deep", but `validate-pack.py`
exposes no `--deep` flag (`--deep` → exit 2, `unrecognized arguments`). Per its own
`--help`, the **no-flag run IS the authoritative full run of ALL checks** — that run
is exit 0. No separate deep mode exists to run; full coverage is satisfied.

**Manifest diff** = exactly the 3 v11-fixture hash lines that embed
`project-template/` content (`v11-realistic-ot`, `v11-flat-file`,
`v11-tracker-on`) — expected from adding the C4 section; deterministic
(re-running `build.sh --all --clean` leaves the tree unchanged).

---

## Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| **boundary-investigation / P-missed-7** | `sed -n '306,424p' … \| grep -E 'BD-\|pack-ops\|maintenance-docs\|ci-shard-plan\|validate-pack\|pack-*'` → exit 1 (no match). `test-validate-pack-check-43.sh` → exit 0, PASS 9/FAIL 0. Section is generic GitHub Actions YAML; project-native. | COMPLIANT |
| **empirical-evidence-blocks** | Every finding above carries the exact command + verbatim output + HEAD `26a0179` + date 2026-06-15. JSON parse, broken-form counter-proof, grep counts, validate-pack exits all quoted. | COMPLIANT |
| **verify-full-ci-suite** | `validate-pack.py` (full run) exit 0 `PASSED — all checks clean`; `check-43` exit 0; `check-54` exit 0 (PASS 3/FAIL 0); `build.sh --all --clean` exit 0; `json.loads` parse exit 0. `--deep` flag does not exist (exit 2) — full no-flag run substitutes per `--help`. | COMPLIANT |
| **scope-deliverables-to-the-ask** | F-1 changed exactly one line (347, `echo "…"` → `echo '…'`); `grep -c "run: echo 'matrix="` = 1; no broken artifact remains; source diff = `OPTIONAL-FEATURES.md` + `manifest.txt` only. Extra untracked `.md` are pre-existing C4-cycle artifacts (timestamps 12:34/12:39 < F-1 12:51), out of F-1 source scope. | COMPLIANT |
| **agents-never-commit** | Only read-only git used: `git rev-parse HEAD`, `git status --short`, `git diff`. No `add`/`commit`/`checkout`/`restore`/any state-changing verb. Single file write = this review doc. | COMPLIANT |
| **rules-applied-verification-block** | This block present; each rule has a quoted-evidence row and a terminal COMPLIANT conclusion; no empty-evidence rows. | COMPLIANT |
