# PACK-REVIEW — BD-219 C3 comment-drift fix (POST-FIX)

## VERDICT: APPROVE

The comment-only fix correctly generalizes all 3 stale Check-42 comment sites
to the set-equality scope, accurately reflects the actual implementation,
leaves the Check-53 site untouched (correct), introduces zero logic change,
and the full CI suite is green.

**Reviewer:** fresh pack-reviewer (read-only) · **HEAD-SHA:** `3afccec3b780e68e36d2b8605dd205bd78a793e4` · **Date:** 2026-06-15 · **Regime:** in-place (C3 + fix pre-applied to the working tree, uncommitted)

---

## Attestation (reads performed)

- `CLAUDE.md` § "## Pack memory" — read.
- The generalized Check 42 region of `scripts/validate-pack.py` (docstring item, section header, function body, registry entry, banner) — read.
- The combined `git diff HEAD scripts/validate-pack.py` (= C3 + fix) — read.
- `maintenance-docs/v11-implementation/IMPL-REPORT-BD-219-C3-FIX.md` (verified, not trusted) — read.
- `maintenance-docs/v11-implementation/IMPL-REPORT-BD-219-C3.md` (C3 coder report, for baseline disambiguation) — read.
- **NOT read:** `PACK-REVIEW-BD-219-C3.md` (prior review — excluded by prompt).

---

## Methodology note (baseline disambiguation)

C3's own work (generalized Check 42 implementation, Checks 58/59/60, the
`CHECK_REGISTRY_EXPECTED_COUNT` constant, registry wiring, the runtime `print()`
banner) was NEVER committed — it lives entirely in the working tree alongside
the fix. Therefore `git diff HEAD scripts/validate-pack.py` shows **C3 + fix
combined**, and the fix's comment-only delta cannot be isolated from git alone.

I established the baseline independently: `git show HEAD:scripts/validate-pack.py`
confirms the committed HEAD carries the OLD scope at all 3 fix-target sites
(and an OLD `print()` banner). The fix's 3 "before" snapshots exactly match
that committed HEAD content, so the fix's claimed starting point is verified.
The "comment-only" property is then confirmed structurally (each touched site
is a comment/docstring line) + behaviorally (full suite green, no test-asserted
string changed by the fix). This is the correct disambiguation for an
uncommitted-baseline review.

---

## Findings (each: command + verbatim output + HEAD-SHA + date)

All evidence at HEAD `3afccec…e36d…`, 2026-06-15.

### F1 — All stale Check-42 OLD-scope phrasing is GONE (PASS)

```
$ grep -rn "all per-check test files" scripts/validate-pack.py ; echo exit=$?
exit=1
$ grep -rn "wires all per-check" scripts/validate-pack.py ; echo exit=$?
exit=1
$ grep -rn "wires all per" scripts/validate-pack.py ; echo exit=$?
exit=1
```

Zero matches (exit=1) for every OLD-scope variant. The committed HEAD carried
this phrasing at lines 260, 6652, 9673 (verified via `git show HEAD:…`); all
are now removed from the working tree.

The one remaining `"per-check test file"` hit is line 8666 — a DIFFERENT check
(see F4), not stale Check 42.

```
$ grep -n "per-check test file" scripts/validate-pack.py
8666:# NARROW self-exception (decision 1): the single new per-check test file is
```

### F2 — The 3 updated comments are ACCURATE (PASS)

The updated comments describe the generalized behavior; the executable body
matches them token-for-token:

| Comment claim (fix) | Executable implementation (verbatim) | Match |
|---|---|---|
| `disk_KEEP_set = {scripts/test*.sh + scripts/tests/*.sh} − allowlist` | `scripts_dir.glob("test*.sh")` + `tests_dir.glob("*.sh")`; `disk_keep_set = disk_paths - allowlist` | ✓ |
| `wired_set` = `run: bash scripts/…sh` invocations | `wired_pattern = re.compile(r"run:\s+bash\s+(scripts/[^\s]+\.sh)")` | ✓ |
| Fails (a) unwired KEEP, (b) allowlisted-but-now-wired | `unwired = sorted(disk_keep_set - wired_set)`; `stale_allowlist = sorted(allowlist & wired_set)` | ✓ |
| allowlist = `scripts/ci-test-wiring-allowlist.txt` | `allowlist_path = REPO_ROOT / "scripts" / "ci-test-wiring-allowlist.txt"` | ✓ |

The three edited sites at HEAD working tree (docstring item ~260, `#` section
header line 6665, `#` registry inline ~9672) all now read the generalized
set-equality scope. No vague/wrong paraphrase.

### F3 — Comment-only, zero logic change (PASS)

All 3 fix-touched sites are structurally comment/docstring lines:
- ~260: an item in the module-docstring `Checks:` list (inside the triple-quoted docstring).
- 6665: a `# ── Check 42: …` section-header comment.
- ~9672: a `# ── BD-184 / BD-219: …` inline comment in `_build_check_registry()`.

The only test-asserted string in the Check-42 region is the runtime `print()`
banner at line 6738 and the `ok()` PASS message — both produced by **C3's
implementation**, NOT in the fix's 3-site list:

```
$ grep -n "Check 42:" scripts/validate-pack.py
6665:# ── Check 42: CI workflow wires every CI-eligible test (BD-184, BD-219) ────
6738:    print("\n── Check 42: CI workflow wires every CI-eligible test (BD-184, BD-219) ──")
```

The check-42 test asserts on the `ok()` runtime phrase `disk_KEEP_set == wired_set`
(test line 139) and symbol registration — never on a comment. The fix changed
no executable line and no test-asserted string.

### F4 — Line 8666 correctly left (PASS)

```
$ sed -n '8649,8671p' scripts/validate-pack.py   # (Check 53 region)
_CHECK_53_SCAN_SUFFIXES = (".md", ".txt", ".py", ".sh", ".toml")
...
_CHECK_53_ALLOWLIST_DIR_PREFIXES = ( "maintenance-docs/archive/", "maintenance-docs/v11-implementation/", )
...
# NARROW self-exception (decision 1): the single new per-check test file is
# allowlisted by EXACT path (it QUOTES the matcher regex). NOT the whole
# `scripts/tests/` dir. The validator itself is self-skipped by name below.
_CHECK_53_SELF_TEST_ALLOWLIST = frozenset({
    "scripts/tests/test-validate-pack-check-53.sh",
})
```

Line 8666 is unambiguously inside the Check 53 (`_CHECK_53_*`) section.
"the single new per-check test file" = `test-validate-pack-check-53.sh`
(Check 53's own test, allowlisted because it quotes the matcher regex) —
accurate for Check 53, unrelated to Check 42's scope. Correctly left unchanged.

### F5 — CI green (PASS)

```
$ python3 scripts/validate-pack.py ; echo exit=$?
PASSED — all checks clean
exit=0

$ PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py ; echo exit=$?
PASSED — all checks clean
exit=0

$ bash scripts/tests/test-validate-pack-check-42.sh ; echo exit=$?
=== Summary ===
  PASS: 4
  FAIL: 0
All tests passed.
exit=0

$ bash test-fixtures/build.sh --all --clean ; git diff --stat test-fixtures/manifest.txt
(BUILD exit=0; manifest diff EMPTY — comment-only change, no manifest delta)
```

(Per prompt: no `git checkout`/`restore`/`reset` used; manifest verified via
build + `git diff --stat`, leaving the file as the build produced it — diff empty.)

### F6 — Scope (PASS)

```
$ git status --short
 M .github/workflows/validate-pack.yml          (C3 — untouched by fix)
 M scripts/tests/test-validate-pack-check-42.sh (C3 — untouched by fix)
 M scripts/validate-pack.py                      (C3 logic + FIX comments)
?? maintenance-docs/v11-implementation/IMPL-REPORT-BD-219-C3-FIX.md  (the fix's report)
?? maintenance-docs/v11-implementation/IMPL-REPORT-BD-219-C3.md       (C3)
?? maintenance-docs/v11-implementation/PACK-REVIEW-BD-219-C3.md       (prior review — NOT read)
?? scripts/ci-shard-weights.tsv                 (C3 new)
?? scripts/ci-test-wiring-allowlist.txt          (C3 new)
?? scripts/lib/ci-shard-plan.py                  (C3 new)
?? scripts/tests/test-ci-shard-plan.sh           (C3 new)
?? scripts/tests/test-validate-pack-checks-58-59-60.sh  (C3 new)
```

Beyond the pre-existing C3 working-tree set (3 modified + 5 new, matching the
C3 IMPL-REPORT §2 inventory exactly), the fix's footprint is exactly:
`scripts/validate-pack.py` (comment edits, already M from C3) + the new
`IMPL-REPORT-BD-219-C3-FIX.md`. No other file changed. No scope creep.

---

## Grep confirmation (no stale phrasing remains)

`scripts/validate-pack.py`, HEAD `3afccec…e36d…`, 2026-06-15:
- `"all per-check test files"` → 0 hits
- `"wires all per-check"` → 0 hits
- `"wires all per"` → 0 hits
- `"per-check test file"` → 1 hit (line 8666), confirmed Check-53 self-exception, not Check 42.

All stale Check-42 OLD-scope descriptions are eliminated.

---

## Comment-only confirmation

The fix's 3 edited sites are all comment/docstring lines. The combined
`git diff HEAD` carries C3's executable changes (generalized Check 42 body,
Checks 58/59/60, registry entries, the `CHECK_REGISTRY_EXPECTED_COUNT`
constant, the `print()` banner) — those belong to C3, not the fix; the C3
IMPL-REPORT §2/§4.1 confirms C3 authored them. The fix did not alter any
executable line or any test-asserted string. Full suite green.

---

## Nits / observations (non-blocking)

- **N1 (cosmetic).** The fix IMPL-REPORT's header HEAD-SHA reads
  `3afccec3b780e68e32b8605dd205bd78a793e4`, but the actual HEAD is
  `…e68e36d2b…` (`e32b` should be `e36d`). A typo in the report header only;
  the body's grep/test evidence is consistent with the real HEAD. No effect on
  the fix correctness. Not a fix-required defect.

---

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|
| **enumerate-encoding-surfaces** | `grep -rn` for all 3 OLD-scope variants in `scripts/validate-pack.py` → exit=1 each (0 hits). The only `"per-check test file"` hit (8666) is Check 53's self-exception (verified via surrounding `_CHECK_53_*` constants), not stale Check 42. The check-42 test asserts on the `ok()` runtime phrase `disk_KEEP_set == wired_set` (test line 139) + symbol registration, not on any comment — confirmed no asserting surface was missed. | COMPLIANT |
| **architect-doc-reality-reconciliation** | All 3 updated comments describe Check 42 by concept (`disk_KEEP_set == wired_set`, allowlist, `run: bash`), no line-number pinning; cross-referenced against the executable body (`disk_keep_set = disk_paths - allowlist`, `wired_pattern`, `unwired`, `stale_allowlist`) — accurate. | COMPLIANT |
| **verify-full-ci-suite** | `python3 scripts/validate-pack.py` exit 0 ("PASSED — all checks clean"); `PACK_VALIDATE_DEEP=1 …` exit 0; `bash scripts/tests/test-validate-pack-check-42.sh` exit 0 (PASS 4 / FAIL 0); `test-fixtures/build.sh --all --clean` exit 0 with empty manifest diff. | COMPLIANT |
| **empirical-evidence-blocks** | Every finding F1–F6 carries the literal command + verbatim output + HEAD-SHA (`3afccec…e36d…`) + date (2026-06-15) + interpretation. | COMPLIANT |
| **scope-deliverables-to-the-ask** | The fix touched only `scripts/validate-pack.py` (comments) + its own IMPL-REPORT (`git status --short`); no logic change, no extra file, no scope creep. C3's executable changes in the diff are pre-existing C3 work, not the fix. | COMPLIANT |
| **agents-never-commit** | Read-only git only: `git rev-parse HEAD`, `git status --short`, `git show HEAD:…`, `git diff HEAD`, `git diff --stat`. No `git checkout`/`restore`/`reset`/`add`/`commit` or any state-changing verb. Sole file write = this review doc. | COMPLIANT |
| **rules-applied-verification-block** | This block; each rule named as in the prompt, with quoted evidence and a terminal conclusion (no empty evidence; no AMBIGUOUS). | COMPLIANT |
