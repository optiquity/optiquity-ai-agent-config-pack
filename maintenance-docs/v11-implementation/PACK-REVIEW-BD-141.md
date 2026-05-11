# PACK-REVIEW-BD-141

**Reviewer:** pack-reviewer
**Branch:** v11-dev
**BD:** BD-141 (Batch 2 of skill-dimensions reframe)
**Scope:** `scripts/lib/detect.sh` (new `python_data_marker_detected()`),
`scripts/init-project.sh` (`pack_skill_coverage_for()` extension and two
call sites), `scripts/add-capability.sh` (comment cross-reference).

---

## Verdict

**Findings — fixes needed before commit.**

A regex-construction defect in `python_data_marker_detected()` causes
the Marker (a) dependency-manifest scan to **fail for the dominant
real-world case** (`pkg==X.Y`, `pkg>=X.Y`, etc.). Bare-name and
end-of-line-anchored matches happen to succeed; everything pinned to a
version silently returns `python-data: no`. This is a BLOCKER because
the whole purpose of BD-141 is to provide a concrete, correct predicate
that downstream batches (BD-142, BD-145) and PLATFORM-SKILLS.md will
cite as canonical truth. Shipping a broken predicate while the spec
text says "predicate is now concrete" actively misleads downstream
implementors.

Other concerns are minor.

---

## 1. Function correctness — scratch-fixture results

Fixtures created under `/tmp/bd141-tests/`. The function was sourced
via `source scripts/lib/detect.sh` and invoked once per fixture.

| # | Fixture | Manifest / contents | Expected | Actual | Pass? |
|---|---------|---------------------|----------|--------|-------|
| t1 | `requirements.txt` | `numpyro==1.0.0` | `no` (substring guard) | `no` | OK |
| t2 | `requirements.txt` | `aioredis==2.0.0` | `no` (substring guard) | `no` | OK |
| t3 | `requirements.txt` | `SQLAlchemy>=1.4` | `yes` (mixed-case + spec) | **`no`** | **FAIL** |
| t4 | `pyproject.toml` | `dependencies = ["numpy>=1.20"]` | `yes` | **`no`** | **FAIL** |
| t5 | `setup.cfg` | `install_requires =\n    pandas` (bare, EOL-terminated) | `yes` | `yes` | OK |
| t6 | `setup.py` | `install_requires=["torch"]` | `yes` | `yes` | OK (incidental — `torch"` then `]`) |
| t7 | 4 `.py` files | (no manifest) | `no` (count threshold) | `no` | OK |
| t8 | 5 `.py` files | (no manifest) | `yes` (count threshold) | `yes` | OK |
| t9 | 5 test-only `.py` files | tests/foo.py, test_bar.py, baz_test.py, test_x.py, y_test.py | `no` (exclusions) | `no` | OK |
| t10 | empty dir | – | `no` | `no` | OK |
| t11 | dir with only README.md | – | `no` | `no` | OK |
| t12 | `requirements.txt` | `numpy==1.20.0\npandas>=1.0\nsqlalchemy>=2.0` | `yes` | **`no`** | **FAIL** |
| t13 | `requirements.txt` | bare `redis\nboto3` | `yes` | `yes` | OK (incidental — EOL anchor) |
| t14 | `requirements.txt` | `flask` only | `no` | `no` | OK |
| t15 | `requirements.txt` | `redis-py-cluster==2.1.0` | `no` (substring guard) | `no` | OK |
| t16 | `requirements.txt` | realistic: `fastapi==0.100.0\nsqlalchemy==2.0.0\npsycopg2-binary==2.9.0\npydantic>=2.0` | `yes` | **`no`** | **FAIL** |
| t17 | `pyproject.toml` | `dependencies = [\n  "numpy>=1.20",\n  "pandas==2.0.0",\n  "torch",\n]` | `yes` | **`no`** | **FAIL** |
| t18 | `requirements.txt` | `psycopg2-binary==2.9.0` | `no` (substring guard) | `no` | OK |
| missing dir | `/tmp/bd141-tests/does-not-exist` | – | `no`, no stderr | `no`, no stderr | OK |
| no arg | invoked with `()` from pack-repo cwd | – | per-cwd; tolerated | `yes` (Marker (b): >= 5 .py files in pack repo, see §2 below) | OK (by design) |

Manifest-type spot-tests (Marker (a)):
- `requirements.txt` covered by t1, t2, t3, t12, t13, t14, t15, t16, t18.
- `pyproject.toml` covered by t4, t17.
- `setup.py` covered by t6.
- `setup.cfg` covered by t5.
All four manifest types are reached by the loop; defects are in the
regex itself, not in manifest-type plumbing.

### 1.1 Root cause of t3/t4/t12/t16/t17 failures

`scripts/lib/detect.sh:343` constructs the trailing character class as:

```
[[:space:]=<>!~,;"'\]]
```

In POSIX ERE bracket syntax, `]` terminates the class unless it is the
first character after `[` or `[^`. Backslash inside a bracket class is
**not** an escape character. So the parser reads:

- `[` open
- `[:space:]` — POSIX class
- `=<>!~,;"'\` — literal chars (including `\`)
- `]` — **closes the class**
- `]` — literal `]` outside the class

Net effect: the regex requires the package name to be followed by one
of the in-class chars **and then** a literal `]` character. So:

- `numpy>=1.20` → name followed by `>` (in class) followed by `=` (NOT `]`) → **no match**
- `numpy"]` (the t6 / "torch"] case) → name followed by `"` (in class) followed by `]` (literal) → match (incidental)
- `pandas\n` (t5 / EOL) → matches the `|$` end-of-line alternative, bypassing the broken bracket class → match

I verified this by running the constructed pattern through `grep -E`
directly (see Bash trace below).

Trace excerpt:

```
$ echo "x>"  | grep -E "(x)([[:space:]=<>!~,;\"'\\]])"  ; echo $?
1
$ echo "x>]" | grep -E "(x)([[:space:]=<>!~,;\"'\\]])"  ; echo $?
0
x>]
```

The opening character class on the same line has the same construction
but it happens to work for end-of-file-anchored matches via the `^`
alternative; line-internal positions would have the same defect.

### 1.2 Spec impact

PLAN-SKILL-DIMENSIONS.md §2 Batch 2 (line 167-174) and ARCHITECTURE-
SKILL-DIMENSIONS.md §7.5 (line 887-896) both list the dependency
markers as the primary contract — Marker (b) is a fallback. With
Marker (a) broken for versioned packages (which is the form most
real-world manifests take), the fast-path for canonical Python
data/server projects collapses onto Marker (b)'s 5-file count, which
will misclassify small data projects (≤4 files using `pandas==X.Y`) as
`python-data: no`. That is exactly the behavior BD-141 was created to
prevent.

### 1.3 Suggested fix

Replace the homegrown bracket-class boundary with a simpler ERE
construct. One concrete option (no shell-escaping landmines):

```bash
local pattern="(^|[^A-Za-z0-9_-])(${pkgs})($|[^A-Za-z0-9_.-])"
```

Where the lead/trail negated classes assert "package-name boundary"
without trying to enumerate every legal version-spec character. This
also stops `numpyro` / `aioredis` from matching (boundary on either
side of `numpy`/`redis`) without needing the brittle `\]]` construct.

If a stricter form is preferred, switch to GNU `grep -P` (PCRE) and
use real `\b` boundaries — but `-P` is non-portable to BSD `grep` on
macOS users' machines, so the negated-class form above is recommended.

Severity: **BLOCKER**.

---

## 2. API design

### 2.1 Caller enumeration (`pack_skill_coverage_for`)

```
$ grep -rn "pack_skill_coverage_for" scripts/ maintenance-docs/ supporting-docs/
```

Active callers (in scripts/):

| Caller | File:line | Args passed | Compatible with new signature? |
|---|---|---|---|
| `print_preview()` | scripts/init-project.sh:276 | `"$lang" "$target"` | Yes (passes both) |
| `stage_s10_kickoff_prompt()` | scripts/init-project.sh:653 | `"$lang" "$TARGET"` | Yes (passes both) |
| Definition | scripts/init-project.sh:227 | – | – |

`scripts/add-capability.sh:114` references the function name in a
comment only (no invocation). No other shell or python file in the
repo calls it. All callers updated; no orphan callers.

### 2.2 `$TARGET` global / default fallback analysis

`scripts/init-project.sh:1013-1014` assigns `$TARGET` near the top of
`main` execution, before any code path can reach `print_preview` (called
at line 1064) or `stage_s10_kickoff_prompt` (called at line 1082). Both
in-tree call sites pass `$TARGET` (or its local alias `$target`)
explicitly, so the `${2:-${TARGET:-.}}` chain is exercised only as a
defensive fallback for hypothetical future callers / sourced-by-tooling
use. The chain `${2:-${TARGET:-.}}` is sound: explicit `$2` wins; falls
back to `$TARGET` if set; falls back to `.` (cwd) if neither. The cwd
fallback is acceptable for ad-hoc reuse but the function header
comment (init-project.sh:223-226) calls this out. No finding.

### 2.3 Parser contract — `awk -F': ' '{print $2}'`

The init-project caller at line 237-238 parses the helper's stdout via
`awk -F': ' '{print $2}'`. This depends on the helper emitting exactly
`python-data: yes` or `python-data: no` (with `: ` as the separator).
The helper's header comment (detect.sh:316-317) does state "Single
line `python-data: yes` or `python-data: no` on stdout." That is
clear enough. The contract is documented; risk is low.

Severity: **NIT.** Could be tightened by having the caller compare
against the full literal string (`if [[ "$marker_line" == "python-data: yes" ]]`)
instead of post-parsing, but this is a style preference, not a defect.

---

## 3. Add-capability cross-reference

- `scripts/add-capability.sh:110-114` — comment block accurately
  captures the design: language:python adds `python-data-architecture`
  unconditionally as part of the language skill set; init-project.sh
  applies the predicate at scaffold time; the helper is the canonical
  source of truth. Wording is clear.
- `scripts/add-capability.sh:115` — `git show HEAD:scripts/add-capability.sh`
  diff confirms the emit line is byte-identical to pre-batch
  (`echo "python-best-practices python-data-architecture dependency-python"`).
  No behavior change here, per spec.

No findings.

---

## 4. Shellcheck output

`shellcheck` is not installed on this machine (`which shellcheck`
returns nothing; not present at `/opt/homebrew/bin` or `/usr/local/bin`).
Substituting a manual scan:

- `bash -n scripts/lib/detect.sh` → OK
- `bash -n scripts/init-project.sh` → OK
- `bash -n scripts/add-capability.sh` → OK
- New code uses `local` declarations consistently
  (detect.sh:336, 348, 350, 351, 367; init-project.sh:228, 229, 236).
- Variables expanded in command substitution contexts are quoted
  (`"$target"`, `"$manifest"`, `"$pattern"`).
- The find/wc/tr pipeline at detect.sh:367-373 quotes arguments and
  uses `2>/dev/null` to swallow find's "no permission" stderr noise
  on missing/restricted dirs.
- `(( py_count >= 5 ))` arithmetic is safe given the prior
  `[[ -n "$py_count" ]]` guard at line 372.

No manual-scan findings beyond the regex defect already cited in §1.

---

## 5. Trinity check

`git diff --name-only HEAD` returns:

```
scripts/add-capability.sh
scripts/init-project.sh
scripts/lib/detect.sh
```

No `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` files in the diff. Trinity
exemption stands per spec (script-only batch). No finding.

---

## 6. Validator

`python3 scripts/validate-pack.py` re-run by reviewer:

```
============================================================
PASSED — all checks clean
```

All 30 checks pass. No new warnings. No regressions.

---

## 7. Permission bits

```
$ ls -l scripts/init-project.sh scripts/add-capability.sh scripts/lib/detect.sh
-rwxr-xr-x@ 1 david  staff  20148 May 11 14:29 scripts/add-capability.sh
-rwxr-xr-x@ 1 david  staff  45929 May 11 14:29 scripts/init-project.sh
-rw-r--r--@ 1 david  staff  17156 May 11 14:28 scripts/lib/detect.sh
```

- `scripts/add-capability.sh` — `-rwxr-xr-x` (correct, exec preserved)
- `scripts/init-project.sh` — `-rwxr-xr-x` (correct, exec preserved)
- `scripts/lib/detect.sh` — `-rw-r--r--` (correct, sourced not exec)

No finding.

---

## 8. Scope discipline

```
$ git diff --stat HEAD
 scripts/add-capability.sh |  5 ++++
 scripts/init-project.sh   | 26 ++++++++++++++--
 scripts/lib/detect.sh     | 75 +++++++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 103 insertions(+), 3 deletions(-)
```

Plus untracked `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-141.md`.

Inspected each diff hunk:

- `detect.sh` — single new function inserted between
  `detect_installed_capabilities` and `target-pack-version`. No edits
  elsewhere.
- `init-project.sh` — header comment expansion on
  `pack_skill_coverage_for()` (lines 219-226), the `case "$lang"` body
  for the python row (lines 232-244), local var `target_dir` added at
  line 229, and two call-site arg additions at lines 276 and 653. No
  collateral edits.
- `add-capability.sh` — comment block lines 110-114 only. Emit line
  unchanged.

No scope violations.

---

## 9. Findings list

### Finding 1 — BLOCKER — Marker (a) regex fails on version-pinned packages

**File:line:** `scripts/lib/detect.sh:343`

**Symptom:** Realistic `requirements.txt` / `pyproject.toml` entries
of the form `numpy==1.20.0`, `pandas>=1.0`, `sqlalchemy>=2.0`,
`SQLAlchemy>=1.4` — i.e., the dominant manifest format for Python
data projects — return `python-data: no`. Bare-name entries
(`pandas` followed by newline) and string-quoted entries (`"torch"]`)
match incidentally via the `^`/`$` and `]`/`"` boundaries.

**Root cause:** The trailing character class is
`[[:space:]=<>!~,;"'\]]`. In POSIX ERE the first `]` after the
class contents closes the class; backslash is not an escape character
inside a bracket class. The pattern therefore requires the matched
package name to be followed by one in-class character **and then** a
literal `]`.

**Proposed fix:** Replace the homegrown boundary class with negated
character classes that simply assert package-name boundaries. Concretely:

```bash
local pattern="(^|[^A-Za-z0-9_-])(${pkgs})($|[^A-Za-z0-9_.-])"
```

Re-run the t3 / t4 / t12 / t16 / t17 fixtures after the fix and confirm
`python-data: yes` for all five. Also re-run t1 / t2 / t15 / t18 to
confirm the substring guard still holds (`numpyro`, `aioredis`,
`redis-py-cluster`, `psycopg2-binary` must remain `no`).

### Finding 2 — NIT — Parser tightness for helper output contract

**File:line:** `scripts/init-project.sh:237-238`

**Symptom:** Caller parses helper output with `awk -F': ' '{print $2}'`
and compares the result against the literal string `yes`. Helper
contract is documented in `detect.sh:316-317`, so this is not a
defect — but a future change to the helper's output format (e.g.
adding a confidence suffix) would silently break the parser.

**Proposed fix (optional):** Compare against the full literal:

```bash
local marker_line
marker_line=$(python_data_marker_detected "$target_dir")
if [[ "$marker_line" == "python-data: yes" ]]; then
    echo "python-data-architecture,python-best-practices"
else
    echo "python-best-practices"
fi
```

Or leave as-is and trust the documented contract. Pack Chat / user
decides.

---

## 10. Verdict rationale

The structural work in BD-141 is sound: the helper is in the right
file, has a clean header contract, integrates into both
`pack_skill_coverage_for()` call sites with a backward-compatible
default for `$2`, the `add-capability.sh` cross-reference is accurate
and non-behavioral, exec bits are preserved, the validator stays clean,
and scope is tight. However, the predicate's Marker (a) regex is
broken in a way that defeats BD-141's stated purpose: real-world
versioned manifests — the precise case where prior fuzzy prose was
producing detection inconsistency — return the wrong answer. The
spec batch downstream (BD-142) will document the helper as canonical
truth in PLATFORM-SKILLS.md; shipping a helper that silently lies for
the dominant input form would lock that defect into the v11.0
contract. Fix Finding 1 before commit; Finding 2 is optional polish.

---

**Report path:** `maintenance-docs/v11-implementation/PACK-REVIEW-BD-141.md`
