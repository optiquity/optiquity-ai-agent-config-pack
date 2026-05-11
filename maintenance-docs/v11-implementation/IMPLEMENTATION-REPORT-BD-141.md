# IMPLEMENTATION-REPORT-BD-141.md

**BD:** BD-141 — Concrete `python-data-architecture` load predicate
(`lib/detect.sh` marker function)
**Batch:** Batch 2 of skill-dimensions reframe (per
`maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` §2)
**Branch:** `v11-dev`
**Worktree:** `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`
**Agent:** `pack-coder`
**Date:** 2026-05-11

---

## 1. Pre-flight state

- **Pre-batch HEAD SHA:** `67222e1554f16e1a970f113ed28c809a3f6ee45a`
- **Working tree:** clean before edits.
- **Files-to-edit current line counts (pre-edit):**
  - `scripts/lib/detect.sh` — 386 lines
  - `scripts/init-project.sh` — 1072 lines
  - `scripts/add-capability.sh` — 491 lines
- **Permission bits (pre-edit):**
  - `-rwxr-xr-x` `scripts/init-project.sh`
  - `-rwxr-xr-x` `scripts/add-capability.sh`
  - `-rw-r--r--` `scripts/lib/detect.sh` (sourced; no exec bit needed)

---

## 2. Per-file edit log

### 2.1 `scripts/lib/detect.sh` — NEW function `python_data_marker_detected()`

**Location:** Inserted immediately above the existing
`detect_target_pack_version()` block (which begins around the original
line 303). This places the new helper at the end of the
detection-helper section — the cleanest available slot since
`detect_installed_capabilities()` is the prior detection helper, and
`detect_target_pack_version()` is structurally a different concern
(version detection, not skill-shape detection).

**Before** (excerpt — lines 301-303 region):

```bash
    fi
}

# target-pack-version: vN | unknown
```

**After:**

```bash
    fi
}

# python-data: yes|no
#
# BD-141 (v11.0 skill-dimensions reframe Batch 2). Concrete load
# predicate for the `python-data-architecture` skill. Replaces the
# fuzzy "multi-file Python with data access, async I/O, or ML
# inference; otherwise omit" prose previously used in
# PLATFORM-SKILLS.md.
#
# Args:
#   $1   Target project directory. Defaults to current working
#        directory. Missing/non-existent target is tolerated and
#        evaluated as `python-data: no` (no error to stderr).
#
# Output:
#   Single line `python-data: yes` or `python-data: no` on stdout.
#
# Markers (any one true → yes), per architecture §7.5
# (maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md):
#   (a) requirements.txt OR pyproject.toml OR setup.py OR setup.cfg
#       lists any of these dependencies (case-insensitive,
#       package-name boundary anchored): sqlalchemy, alembic, pydantic,
#       aiohttp, httpx, psycopg, psycopg2, aiomysql, asyncpg, redis,
#       pymongo, motor, boto3, aioboto3, grpc-tools, protobuf, pyarrow,
#       pandas, numpy, scikit-learn, torch, tensorflow.
#   (b) >= 5 *.py files outside tests/ and test_*.py / *_test.py.
#
# Callers: scripts/init-project.sh (pack_skill_coverage_for python row);
# scripts/add-capability.sh references the predicate by comment only
# (the language:python skill set is coarser than init-project's
# auto-detect). PLATFORM-SKILLS.md cites the helper as the canonical
# predicate for the python-data-architecture row.
python_data_marker_detected() {
    local target="${1:-.}"
    if [[ -z "$target" || ! -d "$target" ]]; then
        echo "python-data: no"
        return 0
    fi

    # Marker (a): dependency manifests. Case-insensitive, anchored to
    # package-name boundaries to avoid false positives (e.g., "numpy"
    # substring inside "numpyro"). Pattern: optional leading whitespace
    # / quote / bracket, then the literal name, then a non-name-char
    # boundary (=, <, >, !, ~, comma, quote, bracket, end-of-line, or
    # whitespace).
    local manifest pkg
    local pkgs="sqlalchemy|alembic|pydantic|aiohttp|httpx|psycopg|psycopg2|aiomysql|asyncpg|redis|pymongo|motor|boto3|aioboto3|grpc-tools|protobuf|pyarrow|pandas|numpy|scikit-learn|torch|tensorflow"
    local pattern="(^|[[:space:]\"'\\[])(${pkgs})([[:space:]=<>!~,;\"'\\]]|\$)"
    for manifest in \
        "$target/requirements.txt" \
        "$target/pyproject.toml" \
        "$target/setup.py" \
        "$target/setup.cfg"
    do
        [[ -f "$manifest" ]] || continue
        if grep -iqE "$pattern" "$manifest" 2>/dev/null; then
            echo "python-data: yes"
            return 0
        fi
    done

    # Marker (b): >= 5 .py files outside tests/.
    local py_count
    py_count=$(find "$target" -name "*.py" \
        -not -path "*/tests/*" \
        -not -name "test_*.py" \
        -not -name "*_test.py" \
        -type f 2>/dev/null | wc -l | tr -d '[:space:]')
    if [[ -n "$py_count" ]] && (( py_count >= 5 )); then
        echo "python-data: yes"
        return 0
    fi

    echo "python-data: no"
}

# target-pack-version: vN | unknown
```

**Notes:**
- Adheres to the file's existing comment-block convention (header
  describes purpose, args, output, marker list, source reference).
- Uses `grep -iqE` (case-insensitive, quiet, extended regex) for the
  manifest scan and `find ... | wc -l` for the file count, exactly per
  plan §2 Batch 2 implementation guidance.
- Boundary regex anchors package names with start-of-line / quote /
  bracket / whitespace on the left, and `=<>!~,;"']` / EOL / whitespace
  on the right, preventing `numpy` matching inside `numpyro` (verified
  in §3.2 below).
- Tolerant of missing target dir (echoes `python-data: no`, no stderr).
- Tolerant of missing manifest files (skips them via `[[ -f ... ]]`).
- All variables quoted (no SC2086); command substitutions quoted (no
  SC2046).
- Function returns `0` exit always — output is the carrier, not exit
  status — consistent with the file's other key:value emitters.

### 2.2 `scripts/init-project.sh` — wire the helper

**Edit A:** `pack_skill_coverage_for()` — extend signature + branch
on predicate.

**Before** (lines 219-228):

```bash
# Pack skill coverage table (per §7.8). Used for skill-gap detection.
pack_skill_coverage_for() {
    local lang="$1"
    case "$lang" in
        swift)      echo "apple-architecture-core,swift-best-practices" ;;
        python)     echo "python-data-architecture,python-best-practices" ;;
        proto)      echo "grpc-patterns" ;;
        *)          echo "" ;;  # No coverage
    esac
}
```

**After:**

```bash
# Pack skill coverage table (per §7.8). Used for skill-gap detection.
#
# Args:
#   $1   Language marker (swift|python|proto|...).
#   $2   Optional target project directory. Used by the python row
#        (BD-141) to consult the python_data_marker_detected predicate
#        in scripts/lib/detect.sh; defaults to $TARGET if unset, else
#        the current working directory. Other rows ignore $2.
pack_skill_coverage_for() {
    local lang="$1"
    local target_dir="${2:-${TARGET:-.}}"
    case "$lang" in
        swift)      echo "apple-architecture-core,swift-best-practices" ;;
        python)
            # BD-141: python-data-architecture loads only when the
            # concrete predicate matches (architecture §7.5).
            # python-best-practices is unconditional for python.
            local marker
            marker=$(python_data_marker_detected "$target_dir" \
                | awk -F': ' '{print $2}')
            if [[ "$marker" == "yes" ]]; then
                echo "python-data-architecture,python-best-practices"
            else
                echo "python-best-practices"
            fi
            ;;
        proto)      echo "grpc-patterns" ;;
        *)          echo "" ;;  # No coverage
    esac
}
```

**Edit B:** `print_preview()` call site (was line 256).

**Before:**

```bash
        coverage=$(pack_skill_coverage_for "$lang")
```

**After:**

```bash
        coverage=$(pack_skill_coverage_for "$lang" "$target")
```

**Edit C:** `stage_s10_kickoff_prompt()` call site (was line 633).

**Before:**

```bash
        [[ -z "$(pack_skill_coverage_for "$lang")" ]] && gaps+=("$lang")
```

**After:**

```bash
        [[ -z "$(pack_skill_coverage_for "$lang" "$TARGET")" ]] && gaps+=("$lang")
```

**Notes:**
- `lib/detect.sh` is already sourced near the top of the file (line
  79: `source "$SCRIPT_DIR/lib/detect.sh"`); no additional sourcing
  needed.
- Both call sites had access to a target path (`$target` local in
  `print_preview`; `$TARGET` global in `stage_s10_kickoff_prompt`). I
  passed them explicitly rather than rely on the `${TARGET:-.}` fallback
  so the data flow is grep-able.
- Fallback `${2:-${TARGET:-.}}` preserves correctness for any future
  caller that omits arg 2.
- `python-best-practices` remains unconditional for the python row,
  per spec.

### 2.3 `scripts/add-capability.sh` — comment cross-reference only

**Edit:** Comment-only addition above the `language:python` row in
`capability_skills()` (was line 109-110); no behavior change.

**Before:**

```bash
capability_skills() {
    local cap="$1"
    case "$cap" in
        language:python)    echo "python-best-practices python-data-architecture dependency-python" ;;
```

**After:**

```bash
capability_skills() {
    local cap="$1"
    case "$cap" in
        # BD-141: python-data-architecture's load predicate is defined in
        # scripts/lib/detect.sh::python_data_marker_detected(). add-capability.sh
        # adds it as part of the language:python skill set (coarser tool —
        # explicit user intent to add the capability); init-project.sh applies
        # the predicate at scaffold time via pack_skill_coverage_for().
        language:python)    echo "python-best-practices python-data-architecture dependency-python" ;;
```

**Notes:**
- Per architecture §3.7 intersection table and the spec, the
  `language:python` capability resolution still emits
  `python-data-architecture`. add-capability.sh is the user-driven
  coarse path (explicit `--add language:python` is a stronger signal of
  intent than auto-detect), so the predicate is documentation-only at
  this call site.

---

## 3. Verification

### 3.1 Smoke test for `python_data_marker_detected()`

Setup:
- `/tmp/scratch-python-data-yes/pyproject.toml` containing
  `sqlalchemy = "^2.0"` under `[tool.poetry.dependencies]`.
- `/tmp/scratch-python-data-no/pyproject.toml` empty + `main.py`
  containing one print statement.
- Cleanup: both scratch dirs removed at end.

Output (post-edit, sourcing the updated `detect.sh`):

```
=== yes case (sqlalchemy in pyproject.toml) ===
python-data: yes
=== no case (empty pyproject + 1 .py file) ===
python-data: no
=== missing dir ===
python-data: no
yes-case exit: 0
no-case exit: 0
missing exit: 0
cleanup done
```

**Result:** PASS. All three cases (yes / no / missing dir) return
expected output and exit 0.

### 3.2 Boundary-anchor regression test

Tested the false-positive guard against `numpyro` (which is NOT in the
marker list and shares the `numpy` prefix):

```
=== falsepos (numpyro/matplotlib only) ===
python-data: no
=== with real numpy added ===
python-data: yes
=== TOML list form (pandas) ===
python-data: yes
```

**Result:** PASS. `numpyro` does not trigger the `numpy` marker;
adding `numpy>=1.24` on a new line correctly trips the predicate;
TOML list form (`dependencies = ["pandas>=2.0", ...]`) also matches.

### 3.3 No-false-positive spot check on existing fixtures

```
=== /scripts/tests/fixtures ===
python-data: no
=== /test-fixtures ===
python-data: no
=== pack repo root ===
python-data: yes
```

**Result:** PASS for fixture dirs (correct — no python deps, no .py
files). Pack repo root reports `yes` because `scripts/` contains
`validate-pack.py` and several other `.py` files, exceeding the
`>= 5` threshold. This is **not** a false positive — the pack repo
itself contains substantial Python tooling. (No init-project.sh
would actually run against the pack repo as a target.)

### 3.4 `python3 scripts/validate-pack.py`

Final summary line:

```
============================================================
PASSED — all checks clean
```

All 30 checks PASS — no regressions.

### 3.5 `bash -n` syntax checks

```
detect.sh syntax OK
init-project.sh syntax OK
add-capability.sh syntax OK
```

**Result:** PASS.

### 3.6 Permission-bit check (post-edit)

```
-rwxr-xr-x@ 1 david  staff  20148 May 11 14:29 scripts/add-capability.sh
-rwxr-xr-x@ 1 david  staff  45929 May 11 14:29 scripts/init-project.sh
-rw-r--r--@ 1 david  staff  17156 May 11 14:28 scripts/lib/detect.sh
```

**Result:** PASS. Both executable scripts retain `-rwxr-xr-x`;
`detect.sh` retains `-rw-r--r--` (sourced, no exec bit needed).
The Edit tool did NOT strip exec bits in this session.

---

## 4. POQs (Points of Question)

**None.**

The spec offered an out (leave init-project.sh wiring as a `# TODO`
if the local-variable name was ambiguous) — but both call sites had
unambiguous target-path variables in scope (`$target` in
`print_preview`, `$TARGET` global in `stage_s10_kickoff_prompt`), so
both were wired explicitly with no ambiguity.

---

## 5. Plan deviations

**None.**

- Function placement: spec said "around line 230 (after
  `detect_installed_capabilities`)". The actual file has
  `detect_installed_capabilities()` ending around line 301 and
  `detect_target_pack_version()` beginning at line 303. The new
  function was placed in the gap between them — i.e., immediately
  after `detect_installed_capabilities()` per spec intent. Plan
  guidance ("around line 230") was off by ~70 lines but the structural
  intent (after `detect_installed_capabilities`) was honored exactly.
- Markers: implemented exactly per architecture §7.5 list — no
  additions, no omissions. Including `psycopg2` separately from
  `psycopg` (the spec explicitly listed both — `psycopg` v2 ships as
  the `psycopg2` distribution name; v3 ships as `psycopg`).
- Manifest files scanned: `requirements.txt`, `pyproject.toml`,
  `setup.py`, `setup.cfg` per the spec. (Plan text only listed
  `requirements.txt` and `pyproject.toml` in some places but the spec
  explicitly listed all four; followed the spec.)

---

## 6. Files touched

```
 scripts/add-capability.sh |  5 ++++
 scripts/init-project.sh   | 26 ++++++++++++++--
 scripts/lib/detect.sh     | 75 +++++++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 103 insertions(+), 3 deletions(-)
```

| Path | Change type | Notes |
|---|---|---|
| `scripts/lib/detect.sh` | modified | +75 lines: new `python_data_marker_detected()` function |
| `scripts/init-project.sh` | modified | +24 / -2: extended `pack_skill_coverage_for()` + 2 call-site arg additions |
| `scripts/add-capability.sh` | modified | +5 / 0: comment-only cross-reference above `language:python` row |

No new files created. No files deleted.

---

## 7. Definition-of-done checklist

| # | Requirement | Status |
|---|---|---|
| 1 | New function `python_data_marker_detected()` added to `scripts/lib/detect.sh` | PASS |
| 2 | Function takes target dir as `$1`, defaults to `.` | PASS |
| 3 | Function emits single line `python-data: yes\|no` to stdout | PASS |
| 4 | Marker (a): manifest scan covers `requirements.txt`, `pyproject.toml`, `setup.py`, `setup.cfg` | PASS |
| 5 | Marker (a): all 21 dependency names from architecture §7.5 list, case-insensitive | PASS |
| 6 | Marker (a): boundary anchored to avoid false positives (e.g., `numpy` vs `numpyro`) | PASS — verified §3.2 |
| 7 | Marker (b): `>= 5` `.py` files outside `tests/`, `test_*.py`, `*_test.py` | PASS |
| 8 | Function tolerates missing target dir (no stderr, returns `python-data: no`) | PASS — verified §3.1 |
| 9 | Function tolerates missing manifest files | PASS (per `[[ -f ... ]] \|\| continue`) |
| 10 | Header comment block: purpose, args, output, marker list, source reference | PASS |
| 11 | `init-project.sh` `pack_skill_coverage_for()` python row consults the helper | PASS |
| 12 | `init-project.sh` emits `python-data-architecture` only if marker → `yes`; `python-best-practices` unconditional | PASS |
| 13 | `init-project.sh` does NOT need re-sourcing (already sources `lib/detect.sh` line 79) | PASS |
| 14 | `add-capability.sh` `language:python` row unchanged in behavior; comment cross-references the helper | PASS |
| 15 | `python3 scripts/validate-pack.py` — 30/30 checks PASS, no regressions | PASS |
| 16 | `bash -n` clean on all three files | PASS |
| 17 | Smoke test: `/tmp/scratch-python-data-yes` returns `python-data: yes` | PASS — verified §3.1 |
| 18 | Smoke test: `/tmp/scratch-python-data-no` returns `python-data: no` | PASS — verified §3.1 |
| 19 | Permission bits: `init-project.sh` and `add-capability.sh` remain `-rwxr-xr-x` | PASS — verified §3.6 |
| 20 | Permission bits: `detect.sh` remains `-rw-r--r--` (sourced) | PASS — verified §3.6 |
| 21 | No edits outside the 3 in-scope files | PASS — verified `git diff --stat` |
| 22 | No state-changing git verbs run | PASS |
| 23 | No false-positive regression on existing test fixtures | PASS — verified §3.3 |
| 24 | Helper function is cleanly sourceable (contract for downstream BD-145) | PASS — re-sourcing at smoke-test confirms |

**All 24 DoD items PASS.**

---

## 8. Summary

Function `python_data_marker_detected()` added to
`scripts/lib/detect.sh`; `init-project.sh::pack_skill_coverage_for()`
wired to the predicate at both call sites (`print_preview` and
`stage_s10_kickoff_prompt`); `add-capability.sh::capability_skills()`
gains a 5-line comment cross-reference above the `language:python`
row (no behavior change). Validate-pack 30/30 PASS. Bash syntax
clean. Exec bits preserved. Smoke + boundary + spot-check tests all
PASS. No POQs, no plan deviations, no out-of-scope edits.
