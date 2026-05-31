# PACK-REVIEW-BD-196-C7-PASS2 — Reviewer pass 2 of max-3

**BD:** BD-196 C7 (Check 37 walk-set extension to companion-template dirs)
**Branch:** v11-dev · **HEAD:** `f2aeb62` (C7 + its fix uncommitted in working tree)
**Scope:** Re-verify the pass-1 SHOULD fix (backtick-in-heredoc stderr noise + false
"pre-existing" §5 claim). READ-ONLY.

## Verdict: CLEAN — SHOULD closed

The single pass-1 SHOULD is closed. stderr syntax-error lines dropped 2 → 0, the test
still PASSes 8/0, the heredoc is still unquoted (vars still expand), no test-logic
changed, and the C7 IMPL-REPORT §5 now reports the stderr provenance truthfully.
`validate-pack.py` exits 0 all clean; manifest regen empty.

---

## Re-verification evidence

### 1. SHOULD closed — stderr now 0 (was 2); test still PASS

```
$ bash scripts/tests/test-validate-pack-checks-36-37-38.sh 2>stderr.txt
  PASS: 8
  FAIL: 0
All tests passed.   (EXIT 0)
$ grep -c "command substitution: syntax error" stderr.txt
0
```
stderr file was empty; 0 `command substitution: syntax error` lines (was 2 pre-fix).
Test summary `PASS: 8 / FAIL: 0`, exit 0 — no regression. **SUPPORTED.**

### 2. Heredoc still UNQUOTED (vars still expand)

The G7.T5 block lives inside the heredoc opened at line 584: `python3 <<EOF` (UNQUOTED —
not `<<'EOF'`). Inside it, `sys.path.insert(0, '$REPO_ROOT/scripts')` and
`spec_from_file_location('vp', '$VALIDATE')` still use bare-`$` expansion. The fix
removed backticks from comment lines only; it did NOT quote the delimiter. The PASS
result in (1) confirms `$REPO_ROOT`/`$VALIDATE` still resolve (module imports succeed).
**SUPPORTED.**

### 3. No test-logic change — comment text only

`git diff scripts/tests/test-validate-pack-checks-36-37-38.sh` shows the G7.T5 block.
The 2 changed comment lines now read `(_iter_project_side_files)` and
`_iter_client_installed_files()` with **no backticks** — verified:

```
$ sed -n '685,694p' ...test-...36-37-38.sh | grep -c '`'
0
```
All assertions intact — G7.T5a (companion files in Check 37 walk), G7.T5b (companion
files NOT in client-installed inventory), G7.T5c (installed ⊆ check37_walk) all present
and unchanged in the diff. No assertion / `failures.append` logic touched. **SUPPORTED.**

### 4. IMPL-REPORT §5 now accurate

`IMPLEMENTATION-REPORT-BD-196-C7.md` §5 (lines 135–145) now states: the 2 stderr lines
were "**C7-introduced, NOT pre-existing**: at HEAD `f2aeb62` the test emitted 0 such
lines; after the original C7 edit it emitted 2," names the backtick-with-parens cause,
and points to the C7-FIX report. No surviving false "pre-existing" claim about the
stderr lines. (Line 131's "This is pre-existing" refers to the 168-vs-171
`UnicodeDecodeError`/`OSError` file-skip iterator behavior — a genuinely pre-existing
behavior, correctly labeled — NOT the stderr lines.) **SUPPORTED.**

### 5. Working-state green + no collateral

```
$ python3 scripts/validate-pack.py  →  EXIT 0  ·  "PASSED — all checks clean"
$ bash test-fixtures/build.sh --all --clean ; git status --short test-fixtures/manifest.txt
  (empty — no manifest diff)
```
`git status --short` working tree: `M scripts/tests/test-validate-pack-checks-36-37-38.sh`,
`M scripts/validate-pack.py` (the C7 edit), plus the untracked C7 / C7-FIX / review docs.
The fix touched only the test file's comment lines + the C7 IMPL-REPORT §5; no source or
fixture collateral. Manifest regen empty. **SUPPORTED.**

---

## Rules-Applied Verification Block

| Rule | Evidence | Conclusion |
|---|---|---|
| Empirical-Evidence for state-claims | All 5 claims above carry the actual command + verbatim output + HEAD `f2aeb62` + SUPPORTED conclusion (stderr count `0`, test `PASS: 8 / FAIL: 0`, validate `EXIT 0`, manifest empty). | COMPLIANT |
| Edit-in-place (verify) | `git diff` shows targeted edits: 2 comment lines in the test (backticks removed) + C7 IMPL-REPORT §5 correction. No full-file rewrite, no test-logic/assertion change (G7.T5a/b/c intact). | COMPLIANT |
| Agent output requires Rules-Applied Verification Block | This block. | COMPLIANT |
| Agents never commit / no destructive ops | Read-only: ran only the test, `validate-pack.py`, `git diff`/`status`, `build.sh --all --clean` (regenerates fixture only — produced no diff, left no stray state), and report Write. No state-changing git verb, no destructive file op. | COMPLIANT |
| Prison rule | Did not read `maintenance-docs/prison/`. | COMPLIANT |
