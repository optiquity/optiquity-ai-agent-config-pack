# PACK-REVIEW — BD-196 C7 (Reviewer pass 1 of max-3)

**Surface under review:** C7 of 12 — extend CI Check 37 walk to companion-template dirs.
**Branch:** `v11-dev`. **HEAD:** `f2aeb62ce7c24e9fedf8488c09d07baf2cf60506` (C7 edits uncommitted in working tree).
**Reference docs:** `PLAN-DOC-CONCISION-GUARDRAILS.md` §3 C7 / §6 / G-D; `ARCHITECTURE-DOC-CONCISION-GUARDRAILS.md` EE-2 / §2.2. No prior reviews read.
**Date:** 2026-05-31.

---

## VERDICT — FINDINGS (1 SHOULD)

The C7 functional change is **correct and complete**: the Check 37 walk is extended
to both companion-template dirs, the install inventory is deliberately and correctly
left separate, both dirs measure clean against every deny-list class, Check 41/43 are
empirically unaffected, and `validate-pack.py` + all 3 per-check tests pass. The
spec's 6 claims all verify.

**One SHOULD finding:** the C7 test edit introduced a real (functionally-benign)
stderr regression — 2 `command substitution: ... syntax error` lines on every run of
the per-check test — caused by backticks-with-parens in the new G7.T5 **comment**
lines sitting inside the unquoted `<<EOF` heredoc. The IMPL-REPORT §5 **mis-attributes
this as pre-existing** ("predating this commit; not introduced by C7"). My measurement
proves it is introduced by C7. Easy fix; functional behavior unaffected (test still
8/0 PASS).

---

## RUN RESULTS (verbatim)

### `python3 scripts/validate-pack.py` — EXIT 0
```
Check 37: 168 project-side file(s) walked; zero deny-list contamination
          (6 anchored LEGITIMATE-context hit(s) accepted; 584 fenced ... exempt)
...
PASSED — all checks clean
```

### Per-check tests
```
test-validate-pack-checks-36-37-38.sh   EXIT=0   PASS: 8  FAIL: 0
test-validate-pack-check-41.sh          EXIT=0   PASS: 4  FAIL: 0
test-validate-pack-check-43.sh          EXIT=0   PASS: 7  FAIL: 0
```

### My own deny-list measurement (both companion dirs, all 4 pattern classes)
Reusing the module's live `_DENY_LIST_*` constants against every file in both dirs:
```
TOTAL RAW DENY-LIST HITS ACROSS BOTH COMPANION DIRS: 0
Deny-list filenames: ['PACK-AGENTS.md','PACK-CHAT.md','HELP-FRAGMENT-PACK.md']
Deny-list prefixes:  ['maintenance-docs/','pack-ops/']
Deny-list agents:    ('pack-architect','pack-coder','pack-planner','pack-reviewer','pack-docs-researcher')
Deny-list role:      'Pack Chat'
```
**0 hits** — matches plan EE-2 / arch §2.2 (both dirs grep-verified clean). Measure-first
clean confirmed: the widened walk admits zero contamination.

### Walk-set membership (live module import)
```
Check37 walk size: 171     install inventory size: 161
companion files in Check37 walk:        10   (all 10 git-tracked companion files)
companion files in install inventory:    0
install subset of walk:                True
walk - installed (the 10 additions) = exactly the 10 companion-template files
```

---

## SPEC VERIFICATION (per SECTION 3 — all 6 claims)

| # | Claim | Verdict | Evidence |
|---|---|---|---|
| 1 | Walk extended correctly; new `_CHECK_37_COMPANION_TEMPLATE_DIRS` const; `_iter_project_side_files()` extended; `_iter_client_installed_files()` NOT touched | **SUPPORTED** | Diff: const added (validate-pack.py:4163-4166); `_iter_project_side_files()` rewritten from thin alias to walk-builder; `_iter_client_installed_files()` body unchanged in diff. Live import: Check37 walk = install ∪ 10 companion files. |
| 2 | Lock-step test G7.T5a/b/c asserts membership / non-membership / superset, and PASSES | **SUPPORTED (functional)** | G7.T5a/b/c present (test:687-730); Group 7 PASS. (See SHOULD-1 for the stderr side-effect of the new comment lines.) |
| 3 | Measure-first: 0 deny-list hits both dirs, all classes | **SUPPORTED** | My independent measurement = 0/0/0/0 (above). |
| 4 | Check 41/43 unaffected; companion absent from install inventory | **SUPPORTED** | `companion-templates` appears in validate-pack.py only at the new const (4165-4166) + docstring (4349), NOT in `_CLIENT_INSTALLED_FILES`. Live import: 0 companion files in install inventory. test-41 4/0, test-43 7/0. `grep companion scripts/init-project.sh` → no match. |
| 5 | Working-state green: validate-pack exit 0 + all 3 tests pass | **SUPPORTED** | Run results above. |
| 6 | No collateral: only 2 in-scope files + IMPL-REPORT; workflow `.yml` untouched; no trinity; manifest regen empty | **SUPPORTED** | `git status`: `M scripts/validate-pack.py`, `M scripts/tests/test-validate-pack-checks-36-37-38.sh`, `?? IMPLEMENTATION-REPORT-BD-196-C7.md`. `git diff --name-only HEAD -- .github/workflows/validate-pack.yml` empty. Trinity files all untouched. `build.sh --all --clean` → manifest.txt diff empty. |

### The two documented "non-issues"
- **168 vs 171 readable-file count — GENUINE non-issue, CONFIRMED.** The 3 skipped
  files are `project-template/.DS_Store`, `project-template/docs/.DS_Store`,
  `project-template/docs/project/.DS_Store` — macOS binary artifacts raising
  `UnicodeDecodeError`, skipped via the pre-existing
  `except (UnicodeDecodeError, OSError): continue` path. NONE are companion files;
  all 10 companion files are readable and walked. Not a masked failure. (Note: these
  `.DS_Store` are local untracked artifacts, not in `git ls-files`; CI's count will
  differ but the logic is identical and sound.)
- **Heredoc stderr line — NOT a genuine non-issue as characterized.** See SHOULD-1.

---

## FINDINGS

### SHOULD-1 — C7 introduced a stderr `syntax error` regression in the test; IMPL-REPORT mis-attributes it as pre-existing

**Surface:** `scripts/tests/test-validate-pack-checks-36-37-38.sh`, new G7.T5 comment
block (lines 687 & 690), inside the `python3 <<EOF ... EOF` heredoc (opener line 584).
Also `IMPLEMENTATION-REPORT-BD-196-C7.md` §5 "Note on harmless stderr" (lines 135-139).

**What the IMPL-REPORT claims:**
> "This originates from the pre-existing `python3 <<EOF` heredoc-in-`$()` parsing in
> the harness (line 585 is the unmodified heredoc opener, predating this commit) ...
> Not introduced by C7."

**Why this is wrong (measured):**
```
HEAD (C7 edits stashed):  syntax-error lines = 0   (EXIT 0, PASS 8)
C7 working tree:          syntax-error lines = 2   (EXIT 0, PASS 8)
```
The error did NOT exist at HEAD. The new G7.T5 comment lines contain backtick-quoted
symbols WITH parentheses:
```
# G7.T5: Check 37's walk (`_iter_project_side_files()`) is the
#   walk-set but MUST NOT appear in `_iter_client_installed_files()`
```
The heredoc opener is **unquoted** (`<<EOF`, required — the body relies on
`$REPO_ROOT`/`$VALIDATE` expansion at lines 586/588), so the shell performs command
substitution on backtick content in the heredoc body. `` `_iter_project_side_files()` ``
is an invalid command substitution; the trailing `()` yields
`command substitution: line 585: syntax error: unexpected end of file` on stderr.

The pre-existing comments with backtick-paren tokens (HEAD lines 574/577) sit OUTSIDE
the heredoc, so they never triggered this. C7 added the first backtick-paren content
INSIDE the heredoc body.

**Functional impact:** benign. The failed command substitution expands to empty
inside a `#` comment line — Python receives `# G7.T5: Check 37's walk () is the` etc.
The G7.T5a/b/c assertions are on subsequent executable lines and are intact; the test
still passes 8/0. So this is NOT a masked test failure.

**Why it is still a finding (not a SKIP):**
1. The IMPL-REPORT's working-state proof contains a false provenance claim (mislabels
   a self-introduced artifact as pre-existing) — exactly the kind of unverified
   state-claim the empirical-evidence discipline exists to catch.
2. It pollutes CI stderr on every run with a misleading "syntax error", obscuring
   genuine future errors.
3. It is fragile: any future edit that places backtick-paren content on an
   *executable* (non-comment) line in this heredoc would silently corrupt the Python
   the test runs.

**Fix recipe (either works; both verified to produce 0 syntax-error lines):**
- **Option A (preferred):** drop the backticks from the two new G7.T5 comment lines —
  `Check 37's walk (_iter_project_side_files()) is the` /
  `MUST NOT appear in _iter_client_installed_files()`.
- **Option B:** escape the backticks in those two comment lines (`` \` ... \` ``).

Do NOT switch the opener to `<<'EOF'` — that breaks the `$REPO_ROOT`/`$VALIDATE`
expansion the block requires.

Also correct IMPL-REPORT §5 to state the stderr is introduced by the C7 G7.T5 comment
lines (not pre-existing) and resolved by the fix.

---

## Rules-Applied Verification Block

| Rule (SECTION 2) | Verification evidence | Conclusion |
|---|---|---|
| No prior reviews fed in | Read only PLAN §3 C7 + ARCHITECTURE EE-2/§2.2; no `PACK-REVIEW-*` opened. | COMPLIANT |
| Enumerate ENCODING surfaces | Verified BOTH the Check 37 walk logic (`_iter_project_side_files`) in validate-pack.py AND its per-check test (G7.T5a/b/c) reflect the extended walk — not asymmetric. Also confirmed Check 41/43 ENCODING surfaces (install inventory + their tests) correctly NOT changed (companion absent from `_CLIENT_INSTALLED_FILES`; test-41 4/0, test-43 7/0). | COMPLIANT |
| CI-guard measure-then-bound | Independently re-measured both companion dirs against the live `_DENY_LIST_*` constants: 0 hits all classes → walk widened only over clean trees; no allowlist widening. | COMPLIANT |
| Empirical-Evidence for state-claims | Every claim above backed by quoted command output + HEAD `f2aeb62`; counts (168/171/161/10/0/2) verbatim, not paraphrased. | COMPLIANT |
| Rules-Applied Verification Block | This table. | COMPLIANT |
| Edit-in-place (verify) | `git diff HEAD` on both files = targeted regions only (const + function rewrite + docstring sentence in validate-pack.py; one inserted G7.T5 block in the test). No full-file rewrite; no unrelated regions changed. `git diff --stat` = 2 files, 99(+)/12(-). | COMPLIANT |
| Agents never commit / no destructive ops | This pass ran only read-only verbs + tests + one `git stash`/`stash pop` round-trip (restored cleanly; working tree identical) + this single Write to the report path. No commit/tag/rm. | COMPLIANT |

**End of PACK-REVIEW-BD-196-C7.md.**
