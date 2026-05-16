# IMPLEMENTATION REPORT — BD-164 retro-fix (Batch 19 review/fix cycle)

## §1 — Summary

Applied 12 FIX items (1 MUST + 3 SHOULD + 4 NIT + 1 SHOULD-with-2-edits + 3
OUT-OF-SCOPE-promoted-to-FIX) from `PACK-REVIEW-BD-164-RETRO.md` against
5 in-scope files (`_lib.sh`, `decompose.sh`, `toc-regenerate.sh`,
`.github/workflows/validate-pack.yml`,
`IMPLEMENTATION-REPORT-BD-164.md`). Documented 4 SKIP items (N2, N6, O1, O4)
with Pack-Chat-supplied rationale in §7. All 9 verification commands pass:
bash-syntax clean across 3 helpers, YAML clean on workflow,
`validate-pack.py` PASSED, `test-per-entry.sh` 57/57, Check 32/33/34 tests
46/46, migrate suites 43+61+87, init-project 34/34, tracker-agent-read 31/31.
Branch `v11-dev`; HEAD unchanged at
`669618273d5c0b72d8abfdb602057b53bc379090` per agents-never-commit rule.

## §2 — Files modified

| Path | Pre-lines | Post-lines | Net | Type |
|---|---|---|---|---|
| `scripts/lib/per-entry/_lib.sh` | 419 | 438 | +19 | modified |
| `scripts/lib/per-entry/decompose.sh` | 280 | 287 | +7 | modified |
| `scripts/lib/per-entry/toc-regenerate.sh` | 285 | 294 | +9 | modified |
| `.github/workflows/validate-pack.yml` | 238 | 241 | +3 | modified |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-164.md` | 201 | 211 | +10 | modified |

Total: 5 files modified, 0 created, 0 deleted. Net +48 lines.

## §3 — Per-fix detail

### M1 — Wire `test-per-entry.sh` into CI

**File:** `.github/workflows/validate-pack.yml` (3 lines added).

**Before:** the workflow `tests:` job ran 28 enumerated `scripts/tests/*.sh`
runners; `test-per-entry.sh` was absent. Verified by review finding M1.

**After:** a new step

```yaml
      - name: per-entry helper tests (BD-164)
        if: always()
        run: bash scripts/tests/test-per-entry.sh
```

inserted IMMEDIATELY BEFORE the existing
`validate-pack Check 32/33/34 tests (BD-168, per-entry split validators)`
step. Foundation runs before the BD-168 validators that depend on the
helpers — per the prompt's ordering rationale (BD-164 helpers are
foundation; BD-168 validators depend on them).

**Cross-ref:** PACK-REVIEW-BD-164-RETRO §2 M1.

### S1 — Harmonize pack-changelog regex in `decompose.sh`

**File:** `scripts/lib/per-entry/decompose.sh` lines 117–122 of the
modified file.

**Before:**

```python
anchor_re = re.compile(r"^### (v\d+\.\d+(?:[-A-Za-z0-9]+)?)\b")
id_extract = lambda line: re.match(r"^### (v\d+\.\d+(?:[-A-Za-z0-9]+)?)\b", line).group(1)
```

(broader: admitted mixed-case + no leading-hyphen requirement)

**After:**

```python
# Suffix shape harmonized with _lib.sh:77 + toc-regenerate.sh:85 — the
# canonical pack-changelog convention per sidecar §3.2 line 302 is
# `v10.0-post-release` (lowercase, leading-hyphen, [a-z0-9-]).
anchor_re = re.compile(r"^### (v\d+\.\d+(?:-[a-z0-9-]+)?)\b")
id_extract = lambda line: re.match(r"^### (v\d+\.\d+(?:-[a-z0-9-]+)?)\b", line).group(1)
```

Both regex lines now use `(?:-[a-z0-9-]+)?` matching `_lib.sh:77` and
`toc-regenerate.sh:85`. Three-line explanatory comment added.

**Cross-ref:** PACK-REVIEW-BD-164-RETRO §2 S1.

### S2 — Same-directory `mktemp` in `pe_ensure_backpointer`

**File:** `scripts/lib/per-entry/_lib.sh` `pe_ensure_backpointer` function
(near the formerly-line-333 site).

**Before:**

```bash
tmp=$(mktemp -t per-entry-bp.XXXXXX) || return 1
printf '%s\n' "$bp" >"$tmp"
cat "$path" >>"$tmp"
mv "$tmp" "$path"
```

(temp file landed in `$TMPDIR` — cross-FS rename non-atomic when `$path`
lives outside TMPDIR)

**After:**

```bash
# Same-directory mktemp so the final `mv` is an atomic rename within
# the same filesystem. `mktemp -t` lands under $TMPDIR which is
# typically a different filesystem from $path — cross-FS `mv` is
# implemented as `copy + unlink` and is NOT atomic.
local dir
dir=$(dirname "$path")
tmp=$(mktemp "$dir/.per-entry-bp.XXXXXX") || return 1
printf '%s\n' "$bp" >"$tmp"
cat "$path" >>"$tmp"
mv "$tmp" "$path"
```

Pattern now mirrors `pe_write_atomic` (line 363 of pre-fix file).

**Cross-ref:** PACK-REVIEW-BD-164-RETRO §2 S2.

### S3 — Loosen project-changelog regex to admit optional slug (Option B)

**Two files:**

1. `scripts/lib/per-entry/_lib.sh` — `project-changelog` `entry-regex` case
   (formerly line 101).

   **Before:** `printf '^[0-9]{4}-[0-9]{2}-[0-9]{2}-.+\.md$' ;;`

   **After:**
   ```bash
   # Slug is OPTIONAL per sidecar §3.5 (OT convention typically
   # carries a slug, but the design does not lock it). The
   # decompose `id_extract` bare-date fall-back returns
   # `YYYY-MM-DD.md` for unannotated H3 anchors; this regex
   # admits both shapes. Mirrored in toc-regenerate.sh:88.
   entry-regex) printf '^[0-9]{4}-[0-9]{2}-[0-9]{2}(-.+)?\.md$' ;;
   ```

2. `scripts/lib/per-entry/toc-regenerate.sh` line 88 (pre-fix).

   **Before:** `"project-changelog":           re.compile(r"^\d{4}-\d{2}-\d{2}-.+\.md$"),`

   **After:**
   ```python
   # Slug is optional per sidecar §3.5; mirrors _lib.sh:101.
   "project-changelog":           re.compile(r"^\d{4}-\d{2}-\d{2}(-.+)?\.md$"),
   ```

Title-extraction fallback at `toc-regenerate.sh` (`if not title: title = entry_id`)
already handles bare-date entries; no additional change needed.

**Cross-ref:** PACK-REVIEW-BD-164-RETRO §2 S3 (Pack Chat picked option B).

### S4 — Relax back-pointer detect/strip to tolerate trailing whitespace

**Three function bodies in `scripts/lib/per-entry/_lib.sh`:**

1. `pe_first_line_is_backpointer` — case-glob replaced with
   `grep -E -q '^<!-- per-entry source: .*; contract: .* -->[[:space:]]*$'`.
   Docstring updated to mention trailing-whitespace tolerance and editor
   auto-trim hazard.

2. `pe_strip_backpointer_stdin` — awk regex changed from
   `/^<!-- per-entry source: .*; contract: .* -->$/` to
   `/^<!-- per-entry source: .*; contract: .* -->[ \t]*$/`. Docstring
   updated.

3. `pe_ensure_backpointer` — case-glob replaced with the same `grep -E -q`
   pattern as item 1. Docstring updated.

All three sites now agree on trailing-whitespace tolerance (strip and
detect remain consistent — strip removes lines that detect would
identify).

**Cross-ref:** PACK-REVIEW-BD-164-RETRO §2 S4.

### N1 — Clarify BSD-grep ERE comments in `_lib.sh`

**Two sites in `scripts/lib/per-entry/_lib.sh`:**

1. Header comment (pre-fix line 53). **Before:** `# Position 2: entry-file regex (BSD-grep ERE; matched against basename).`
   **After:** 4-line comment naming both BSD `grep -E` and Python
   `re.compile` as consumers, with use-site cross-references.

2. Inline comment in `pe_list_entry_files` (pre-fix line 406). **Before:**
   `# Match against the entry regex (BSD grep ERE).` **After:** 3-line
   comment naming both consumers with same cross-references.

**Cross-ref:** PACK-REVIEW-BD-164-RETRO §2 N1.

### N3 — try/except KeyError around `os.environ[...]` in `decompose.sh`

**File:** `scripts/lib/per-entry/decompose.sh` (pre-fix lines 66–69, inside
the Python heredoc).

**Before:** 4 direct `os.environ["…"]` accesses; a missing var would raise
a bare `KeyError` with no framing.

**After:**

```python
try:
    key = os.environ["PE_DECOMPOSE_KEY"]
    mono_path = os.environ["PE_DECOMPOSE_MONO"]
    stream_dir = os.environ["PE_DECOMPOSE_DIR"]
    entry_regex = os.environ["PE_DECOMPOSE_REGEX"]
except KeyError as e:
    sys.stderr.write(f"per-entry decompose: missing env var {e.args[0]}\n")
    sys.exit(2)
```

Now produces a framed `per-entry decompose: missing env var …` message
matching the bash side's `pe_die` style.

**Cross-ref:** PACK-REVIEW-BD-164-RETRO §2 N3.

### N4 — Comment on negate-ord descending-date trick

**File:** `scripts/lib/per-entry/toc-regenerate.sh` `entry_sort_key`
function, project-changelog branch.

**Before:**

```python
if key == "project-changelog":
    # Descending date (lex sort of inverted strings).
    return tuple(-ord(c) for c in filename)
```

**After:**

```python
if key == "project-changelog":
    # Descending date (lex sort of inverted strings). Python's tuple
    # comparison is lexicographic; negating per-char ord values
    # inverts the ordering so newer dates sort first.
    return tuple(-ord(c) for c in filename)
```

One-line explanatory comment added per prompt sample text.

**Cross-ref:** PACK-REVIEW-BD-164-RETRO §2 N4.

### N5 — Clarify §18.2 #1 case 4 scope in IMPL-REPORT-BD-164.md §6

**File:** `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-164.md`
§6 "Out-of-scope items".

**Before:** §6 had 3 bullets (`_v8-resolved-archive.md` extraction is
BD-167; project-implementation-plan + project-changelog round-trips not
yet exercised; `PE_FORCE_OVERWRITE_MIRROR` env var naming provisional)
plus a 4th legacy "Check 32 collision concern" bullet.

**After:** new bullet 4 inserted (per prompt verbatim text) naming
integration parent §18.2 #1 case 4 (cross-reference resolution) as
BD-168 / 19e territory. The previous bullet 4 (Check 32 collision) is
renumbered to bullet 5.

**Cross-ref:** PACK-REVIEW-BD-164-RETRO §2 N5.

### O2 — Parallel comment in `_lib.sh` about phase-N.md override

**File:** `scripts/lib/per-entry/_lib.sh` `pe__stream_attr`
`project-implementation-plan` case (pre-fix lines 90–97).

**Before:** the case block had no comment explaining why only
`phase-N.md` is admitted.

**After:** 4-line comment block prepended:

```bash
project-implementation-plan)
    # Filename regex admits `phase-N.md` only (no `phase-N.M.md`
    # per-task files). Per Addendum #1 §6.4 BD-167 spec override
    # of sidecar §3.4: tasks live INLINE in the phase file. See
    # `decompose.sh:125` for the parallel parser-side comment.
    case "$2" in
```

Mirrors the parallel comment already in `decompose.sh:125`.

**Cross-ref:** PACK-REVIEW-BD-164-RETRO §4 O2.

### O3 — Comment about deliberate timestamp omission in `toc-regenerate.sh`

**File:** `scripts/lib/per-entry/toc-regenerate.sh` after the
"DO NOT EDIT BY HAND" comment line (pre-fix ~line 250).

**Before:** the "DO NOT EDIT BY HAND" line stood alone with no comment
explaining the omission of regeneration-time / generator-version stamps
that sidecar §5.1 names as candidate trailers.

**After:** 6-line Python comment added immediately after the
`out.append(f"<!-- generated by …")` line, naming the deliberate
omission and tying it to Check 33's byte-identical-regeneration
requirement.

**Cross-ref:** PACK-REVIEW-BD-164-RETRO §4 O3.

### O5 — Pre-BD-165 line count note in IMPL-REPORT-BD-164.md §4

**File:** `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-164.md`
§4 "Files created", before the file table.

**Before:** §4 opened directly with the file table; no annotation about
the line counts representing the BD-164-only snapshot.

**After:** 7-line paragraph inserted immediately before the table, per
the prompt's verbatim sample text, explaining that line counts capture
the BD-164-only state (pre-BD-165 / 19c), naming `mirror-generate.sh`
276→331 as the specific downstream extension, and acknowledging
subsequent retro-fix line drift.

**Cross-ref:** PACK-REVIEW-BD-164-RETRO §4 O5.

## §4 — Verification

All commands run from the v11-dev worktree root. Command output tails:

### Bash syntax check (3 helpers)

```
$ bash -n scripts/lib/per-entry/_lib.sh && bash -n scripts/lib/per-entry/decompose.sh && bash -n scripts/lib/per-entry/toc-regenerate.sh && echo "BASH-SYNTAX OK"
BASH-SYNTAX OK
```

### YAML syntax check (workflow)

```
$ python3 -c "import yaml; yaml.safe_load(open('.github/workflows/validate-pack.yml'))" && echo "YAML OK"
YAML OK
```

### `python3 scripts/validate-pack.py`

```
── Check 32: per-entry mirror is in-sync with per-entry tree (BD-168) ──
  OK: backlog/ — not present (skipping; pre-v11.0 client or pre-Batch-22 pack-self per integration parent §10.5)
  OK: changelog/ — not present (skipping; pre-v11.0 client or pre-Batch-22 pack-self per integration parent §10.5)

── Check 33: per-entry _toc.md is in-sync with per-entry tree (BD-168) ──
  OK: backlog/ — not present (skipping; pre-v11.0 client or pre-Batch-22 pack-self per integration parent §10.5)
  OK: changelog/ — not present (skipping; pre-v11.0 client or pre-Batch-22 pack-self per integration parent §10.5)

── Check 34: cross-reference integrity (BD-168) ──
  OK: no per-entry trees present (skipping; pre-v11.0 client or pre-Batch-22 pack-self per integration parent §10.5)

── Check 35: Phase-task lib invariants (BD-106) ──
  OK: scripts/lib/tracker-phase-task.sh present
  OK: scripts/lib/tracker-labels.sh — no tracker_labels_folded_into helper definition (Path 3 forbidden)
  OK: scripts/lib/ — no `folded-into` literal in executable code (V3.3 §3 line 27); comment-only references allowed

============================================================
PASSED — all checks clean
```

### `bash scripts/tests/test-per-entry.sh` (the modified helpers)

```
=== Group 11: bash 3.2 compatibility smoke ===
  PASS 11.1 helpers source cleanly under bash --norc

=== Summary ===
PASS: 57
FAIL: 0

All per-entry tests PASSED (57/57).
```

### `bash scripts/tests/test-validate-pack-checks-32-33-34.sh`

```
  PASS E1.6 no tree → Check 34 says 'no per-entry trees present'

=== Summary ===
PASS: 46
FAIL: 0

All BD-168 validate-pack Check 32/33/34 tests PASSED (46/46).
```

### `bash scripts/tests/test-migrate-v10-to-v11.sh`

```
=== Group 5: BD-104 rename (BD-139 fix-follow) ===
  PASS 5.1 BD-104 rename happy path: git mv succeeded, content preserved, sub-banner emitted
  PASS 5.2 BD-104 source-absent no-op: info emitted, downstream S5 ran
  PASS 5.3 BD-104 untracked-source mv fallback: 'renamed (untracked)' + 'git mv hint' both emitted
  PASS 5.4 BD-104 migration-rename-collision: typed-error contract + fail_stage S4 (rc=24)

=== Summary ===
Passed: 43
Failed: 0
All tests passed.
```

### `bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh`

```
  PASS 7.4 F5: '--resume --apply' rc!=0
  PASS 7.4 F5: '--resume --apply' error names multiple mode flags

=== Summary ===
Passed: 61
Failed: 0
All BD-095 tests passed.
```

### `bash scripts/tests/test-migrate-v10-to-v11-gates.sh`

```
  PASS 5.3 mapping zero-value rc=1
  PASS 5.3 mapping FAIL zero

=== Summary ===
Passed: 87
Failed: 0
All BD-101 gate tests passed.
```

### `bash scripts/tests/test-init-project.sh`

```
  PASS 3.4 pack-help.sh from project root rc=0
  PASS 3.4 pack-help.sh emits client-side header

=== Summary ===
Passed: 34
Failed: 0
All tests passed.
```

### `bash scripts/tests/tracker-agent-read-test.sh`

```
=== Group 4: direct-execution entrypoint ===
  PASS 4.1 direct exec rc=0
  PASS 4.1 direct exec emits header
  PASS 4.2 no args → usage
  PASS 4.3 direct exec missing → not-found

=== Summary ===
Passed: 31
Failed: 0
All tests passed.
```

### HEAD-unchanged check

```
$ git rev-parse HEAD
669618273d5c0b72d8abfdb602057b53bc379090
```

(Identical to pre-flight HEAD; no state-changing git verbs run.)

## §5 — Definition-of-Done checklist

| Criterion | Status |
|---|---|
| A. All 12 FIX items applied per implementation guidance | PASS |
| B. No SKIP item applied; rationale documented in §7 | PASS |
| C.1 `bash -n` clean on all 3 modified helpers | PASS |
| C.2 `python3 scripts/validate-pack.py` PASSED | PASS |
| C.3 `test-per-entry.sh` 57/57 PASS | PASS |
| C.4 `test-validate-pack-checks-32-33-34.sh` 46/46 PASS | PASS |
| C.5 `test-migrate-v10-to-v11.sh` 43/43 PASS | PASS |
| C.6 `test-migrate-v10-to-v11-dry-run.sh` 61/61 PASS | PASS |
| C.7 `test-migrate-v10-to-v11-gates.sh` 87/87 PASS | PASS |
| C.8 `test-init-project.sh` 34/34 PASS | PASS |
| C.9 `tracker-agent-read-test.sh` 31/31 PASS | PASS |
| C.10 YAML syntax OK on validate-pack.yml | PASS |
| D. Bash 3.2 + macOS BSD-utility compatible for bash edits | PASS |
| E. HEAD unchanged (agents-never-commit) | PASS |

## §6 — Plan deviations

Zero deviations. All 12 FIX items applied per the implementation guidance
verbatim, including:
- M1: step inserted at the precise location named by the prompt
  (immediately before the BD-168 Check 32/33/34 step).
- S1: both regex lines harmonized to `(?:-[a-z0-9-]+)?`; 3-line comment
  added per prompt sample.
- S2: `dirname` + `mktemp "$dir/.per-entry-bp.XXXXXX"` pattern per prompt
  sample; existing comment text used verbatim.
- S3: option B chosen by Pack Chat applied to both `_lib.sh:101` and
  `toc-regenerate.sh:88`; 2–3 line comments added at each site naming
  sidecar §3.5 and the decompose contract.
- S4: all three sites (`pe_first_line_is_backpointer`,
  `pe_strip_backpointer_stdin`, `pe_ensure_backpointer`) relaxed; docstrings
  updated.
- N1/N3/N4/O2/O3: comment text follows prompt samples verbatim.
- N5/O5: IMPL-REPORT-BD-164.md edits use the prompt's verbatim sample
  paragraphs.

## §7 — Skip rationale

Pack Chat triaged 4 review findings as SKIP. Each rationale is recorded
verbatim from the prompt; no code changes applied for these items.

- **N2** (speculative `pe_supporting_files_lines` helper): no current
  consumer. Per `feedback_deferral_is_scope_creep` "logical fit" criterion,
  this helper belongs with its first consumer, not standalone. Not
  deferral — no work item exists yet.

- **N6** (existing §7.5 reference is correct): reviewer agrees "minor";
  the existing reference is correct.

- **O1** (stale): `scripts/tests/test-validate-pack-checks-32-33-34.sh`
  exists at 23117 bytes since BD-168 commit `6696182`, which landed
  BEFORE this review ran. The reviewer's claim that it doesn't exist is
  stale.

- **O4** (not a defect): reviewer explicitly says "no defect, just
  confirmation". Nothing to fix.

## §8 — Out-of-scope observations

None. No new defects noticed during the retro-fix pass beyond the FIX/SKIP
items already triaged. The working-tree edits are confined to the 5 files
named in the prompt; no spillover into BD-165's `mirror-generate.sh` or
any other BD's territory. Pre-flight git-status check (per `commit-discipline`
skill discipline) confirmed only the 5 expected files are modified plus the
pre-existing untracked `PACK-REVIEW-BD-164-RETRO.md` review report.
