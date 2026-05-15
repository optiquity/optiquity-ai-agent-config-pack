# IMPLEMENTATION-REPORT-BD-078-RETRO-FIX — Batch 21c retro fixes for BD-078

**Author:** pack-coder (Batch 21c retroactive review-fix sub-agent for BD-078)
**Date:** 2026-05-15
**Branch:** `v11-dev`
**Worktree base SHA at start:** `304078f3d88aa48d763dd8e5c4b3d41917076640`
**Worktree base SHA at end:** `304078f3d88aa48d763dd8e5c4b3d41917076640` (no commits made; pack-coder is non-committing)
**Source review:** `maintenance-docs/v11-implementation/PACK-REVIEW-BD-078-RETRO.md`

---

## 1. Summary

This report covers the in-scope subset of the BD-078 retro review's 9 findings:

| # | Sev | Status entering this fix | Closed by this fix |
|---|-----|---------------------------|--------------------|
| F1 | MUST | Open (acceptance criterion B never shipped) | Yes — staleness leg added |
| F2 | MUST | Already closed by `304078f` (cross-BD CI wiring) | N/A |
| F3 | SHOULD | Open (bool-as-int trap) | Yes — `_require()` defends bool |
| F4 | SHOULD | Open (`backend.repo` ungated) | Yes — added with empty-string check |
| F5 | SHOULD | Open (ambiguous `ARCHITECTURE.md §3.1`) | Yes — full path qualification |
| F6 | NIT | Open (test-fixture variants undocumented) | Yes — docstring exclusion note |
| F7 | NIT | Open (dead `VALIDATOR=` line) | Yes — deleted |
| F8 | NIT | Open (`_ = (fwd, rev)` smell) | Yes — replaced with bare calls |
| F9 | NIT | Already closed by `614e67e` (Pattern B bulk-fix) | N/A |

All 7 in-scope findings are closed in the working tree. Verification:

- `python3 scripts/validate-pack.py` — all 32 numbered checks PASS (Check 29 now reports 3 OK lines: pack-example, project-example, mirror-staleness soft-pass).
- `bash scripts/tests/tracker-config-schema-test.sh` — 28/28 assertions PASS (was 17/17; 11 new assertions added across 5 new test cases).
- `bash -n scripts/tests/tracker-config-schema-test.sh` — exit 0.

No state-changing git verbs were run. No files outside the allowed scope (`scripts/validate-pack.py`, `scripts/tests/tracker-config-schema-test.sh`, the new report) were modified.

---

## 2. Per-finding fix detail

### F1 — MUST — Acceptance criterion B (mirror staleness warning)

**What shipped:** `check_tracker_config()` now wires a new `_check_mirror_staleness()` helper that is invoked when a live `tracker.toml` exists at the pack root (`REPO_ROOT/tracker.toml`). The leg:

1. Soft-passes (with a visible OK line) when `tracker.toml` is absent — lazy-create is by design (parallel to Check 30's pattern for `recommendation-state.json`).
2. Soft-passes when `mode.state != "tracker"` (flat-file legitimately leaves mirrors stale).
3. Soft-passes when `migration.forward_complete` is not `true` (no migration has happened yet).
4. When tracker mode AND forward-complete are both true, parses `migration.last_forward_run` (must be ISO-8601 UTC string), then walks each configured mirror file (`mirror.location_backlog` / `_status` / `_changelog`) and:
   - FAILs the file if it does not exist on disk;
   - FAILs the file if it has no parseable `Last regenerated:` header;
   - FAILs the file if the header timestamp is lexicographically older than `last_forward_run` (ISO-8601 Z-suffixed UTC sorts correctly without datetime parsing).

**Header format:** Reads the `Last regenerated:` line from the mirror's leading `<!-- ... -->` HTML comment block written by `scripts/lib/tracker-mirror.sh:tracker_mirror_header_emit` (see V1 §6.5 step 8 + V1 §A.2). Regex: `Last regenerated:\s*(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z)`. Reads at most the first 4 KiB of each mirror file to bound memory.

**Why the staleness leg never fires on the existing example files:** `tracker.toml.pack-example` and `project-template/tracker.toml.project-example` both ship with `mode.state = "flat-file"` and `forward_complete = false` — exactly the modes where the staleness leg legitimately soft-passes. The example files exercise the *schema-validation* leg only. The staleness leg is gated on a *live* `tracker.toml` because that is when `last_forward_run` is meaningful (the example files commented out the timestamp deliberately).

**Files touched:** `scripts/validate-pack.py` — new helper `_check_mirror_staleness()` + new module constant `_MIRROR_HEADER_TS_RE` + new helper `_read_mirror_last_regenerated()` + invocation block at the end of `check_tracker_config()`.

**Before/after evidence (live demo against pre-fix `validate-pack.py` extracted via `git show HEAD:`):**

```
PRE-FIX (live tracker.toml + stale BACKLOG.md mirror with Last regenerated 2026-05-01):
  failure count = 0       ← spec gap; mirror staleness silently passes

POST-FIX (same fixture):
  FAIL: BACKLOG.md — Last regenerated 2026-05-01T08:00:00Z is older than
        migration.last_forward_run 2026-05-15T12:00:00Z; mirror is stale and
        must be regenerated
  failure count = 1       ← spec gap closed
```

**Test coverage added:** Tests 13.1–13.3 (stale BACKLOG mirror flagged, error message names file + older-than wording, fresh STATUS/CHANGELOG mirrors NOT flagged) and Tests 14.1–14.2 (live tracker.toml in flat-file mode soft-passes; staleness leg reports "N/A" when not in tracker mode). All 5 assertions PASS.

### F3 — SHOULD — `schema_version = true` slips through

**What shipped:** `_require()` now has an explicit bool-rejection branch ahead of `isinstance(cur, expected_type)`. Two arms:

```python
if expected_type is int and isinstance(cur, bool):
    fail(f"{rel} — key {key_path}: expected int, got bool")
    failed = True
    return None
if expected_type is bool and not isinstance(cur, bool):
    fail(f"{rel} — key {key_path}: expected bool, got {type(cur).__name__}")
    failed = True
    return None
```

The first arm closes F3 directly (Python `isinstance(True, int)` is `True` and `True == 1` is `True`, so the original two checks both passed). The second arm (`expected bool, got non-bool`) is symmetric defense — without it, `_require("migration.forward_complete", bool)` would accept e.g. `forward_complete = 1` because of the same bool/int subclass relationship in reverse. Mirrors Check 30's defensive idiom for `user_re_enable_count` (validate-pack.py:2347-2351) so BD-078 and BD-079 use the same pattern.

**Files touched:** `scripts/validate-pack.py` — `_require()` inner function inside `_validate_tracker_toml`.

**Before/after evidence:**

```
PRE-FIX (tracker.toml.pack-example with `schema_version = true`):
  OK: tracker.toml.pack-example — schema OK (...)         ← bool slipped through
  failure count = 0

POST-FIX (same fixture):
  FAIL: tracker.toml.pack-example — key schema_version: expected int, got bool
  failure count = 1
```

**Test coverage added:** Tests 10.1–10.2 (exit nonzero on bool, message identifies "expected int, got bool"). Both PASS.

### F4 — SHOULD — `backend.repo` not gated; load-bearing for BD-129's `tracker_gh_repo_setup()`

**What shipped:** Added immediately after the existing `backend.name` check:

```python
repo_slug = _require("backend.repo", str)
if repo_slug is not None and not repo_slug.strip():
    fail(f"{rel} — backend.repo: empty string")
    failed = True
```

This is required + non-empty for all backends in v11.0 since `github` is the only first-class backend. Future non-`github` backends with no repo concept will need a `backend.name`-conditional gate; that is documented in the in-line comment ("future backends with no repo concept will need a backend-conditional check here") so the next maintainer is not surprised. Mirrors the existing `migration.mapping_file` empty-string treatment — same pattern, same idiom.

The two committed example files already declare `backend.repo` (pack: `"DShaneNYC/optiquity-ai-agent-config-pack"`; client: `"your-org/your-project"`), so the live tree continues to PASS without modification.

**Files touched:** `scripts/validate-pack.py` — inside `_validate_tracker_toml`, after the `backend.name` block.

**Before/after evidence:**

```
PRE-FIX (tracker.toml.pack-example with backend.repo line stripped):
  OK: tracker.toml.pack-example — schema OK (...)         ← missing key not caught
  failure count = 0

POST-FIX (same fixture):
  FAIL: tracker.toml.pack-example — missing required key: backend.repo
  failure count = 1
```

**Test coverage added:** Tests 11.1/11.2 (missing key) and 12.1/12.2 (empty string). All 4 assertions PASS.

### F5 — SHOULD — Ambiguous `ARCHITECTURE.md §3.1` references

**What shipped:** Both docstring references replaced with the disambiguated path `maintenance-docs/v11-research/ARCHITECTURE.md §3.1`. This is the V1 doc — the canonical source the BACKLOG entry cites verbatim ("(per V1 §A.2)"). The V2 / V3 / V3.x delta docs in the same directory have not superseded §3.1's tracker-config schema for v11.0; if/when they do, the docstring is the canonical place to update.

Two sites updated:

1. **Top-of-file numbered-check ledger** (line 88 area): "and carry the required keys/types per `maintenance-docs/v11-research/ARCHITECTURE.md` §3.1 (`schema_version`, `[backend].name`, `[backend].repo`, `[mode].state`, ...)". Added `[backend].repo` to the listed keys to keep the ledger in sync with the F4 addition.
2. **`check_tracker_config()` docstring** (the function-level docstring): same path qualification + a new paragraph documenting the §A.2 mirror-staleness leg + a new paragraph (F6) documenting the deliberate exclusion of `test-fixtures/v11-*/tracker.toml.example`.

**Files touched:** `scripts/validate-pack.py` — top-of-file docstring + `check_tracker_config()` docstring.

### F6 — NIT — Test-fixture `tracker.toml.example` files not validated

**What shipped:** Took path (b) from the reviewer's options — added a paragraph to `check_tracker_config()`'s docstring explicitly documenting that `test-fixtures/v11-*/tracker.toml.example` are intentionally excluded:

> "Test-fixture variants under `test-fixtures/v11-*/tracker.toml.example` are intentionally NOT validated here: they are pinned migration inputs owned by BD-115/116/117 fixtures and may model historical schemas for migration-regression coverage. See F6 in PACK-REVIEW-BD-078-RETRO.md."

This is the lighter-weight close per the reviewer's recommendation. Path (a) — extending Check 29 to validate the test-fixture files — would risk false-positive failures if any fixture deliberately models a historical schema (BD-115/116/117 own those fixtures and may have already chosen historical shapes for regression purposes). The docstring exclusion is the unambiguous answer to "why doesn't Check 29 cover those files?" without breaking the migration test contract.

**Files touched:** `scripts/validate-pack.py` — `check_tracker_config()` docstring.

### F7 — NIT — Dead `VALIDATOR=` assignment in test script

**What shipped:** Deleted line 28 of `scripts/tests/tracker-config-schema-test.sh`:

```bash
VALIDATOR="$REPO_ROOT/scripts/validate-pack.py"     # unused
```

Verified after deletion: `grep -n "VALIDATOR" scripts/tests/tracker-config-schema-test.sh` returns no hits. The test still loads `validate-pack.py` via `importlib` inside `run_check29_at()`'s heredoc, which constructs the path from `REAL_REPO_ROOT` independently — the deletion does not break the test harness.

**Files touched:** `scripts/tests/tracker-config-schema-test.sh`.

### F8 — NIT — `_ = (fwd, rev)` lint-silencer

**What shipped:** Replaced the captured-and-discarded pattern with bare calls:

Before:
```python
fwd = _require("migration.forward_complete", bool)
rev = _require("migration.reverse_available", bool)
mapping = _require("migration.mapping_file", str)
...
# Silence unused-binding lint; the _require side effects ...
_ = (fwd, rev)
```

After:
```python
# Bare calls: _require's side effect (fail registration on
# missing/wrong-type) is the load-bearing behavior; no return
# value needed here.
_require("migration.forward_complete", bool)
_require("migration.reverse_available", bool)
mapping = _require("migration.mapping_file", str)
```

`mapping` retains its binding because it is genuinely used downstream for the empty-string check (the existing logic at the next line). Behavior is identical — `_require()` registers `fail()` calls regardless of whether the return value is captured.

**Files touched:** `scripts/validate-pack.py` — inside `_validate_tracker_toml`.

---

## 3. Files modified

| Path | Change type | Lines added | Lines deleted |
|------|-------------|-------------|---------------|
| `scripts/validate-pack.py` | modified | +169 | -10 |
| `scripts/tests/tracker-config-schema-test.sh` | modified | +189 | -9 |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-078-RETRO-FIX.md` | new | (this file) | — |

(Numbers from `git diff --stat HEAD -- scripts/validate-pack.py scripts/tests/tracker-config-schema-test.sh` at end of session.)

---

## 4. Verification

### 4.1 `python3 scripts/validate-pack.py`

All 32 numbered checks PASS. Check 29 now reports three OK lines (was two):

```
── Check 29: Tracker-config schema (BD-078) ──
  OK: tracker.toml.pack-example — schema OK (prefix='BD', backend='github', mode='flat-file')
  OK: project-template/tracker.toml.project-example — schema OK (prefix='TD', backend='github', mode='flat-file')
  OK: tracker.toml absent at pack root — mirror-staleness leg soft-passes (lazy-create is by design)
```

Final summary line: `PASSED — all checks clean`.

### 4.2 `bash scripts/tests/tracker-config-schema-test.sh`

```
=== Summary ===
PASS: 28
FAIL: 0
```

Was 17/17 PASS before this session; +11 assertions across 5 new test cases (Tests 10–14). Per-test PASS lines:

```
Test 10: schema_version = true (bool-as-int defense)
  PASS 10.1 schema_version=true → exit nonzero
  PASS 10.2 message identifies expected int, got bool

Test 11: missing backend.repo (load-bearing for gh CLI)
  PASS 11.1 missing backend.repo → exit nonzero
  PASS 11.2 message names backend.repo as missing

Test 12: empty backend.repo
  PASS 12.1 empty backend.repo → exit nonzero
  PASS 12.2 message identifies empty backend.repo

Test 13: live tracker.toml + stale mirror
  PASS 13.1 stale BACKLOG mirror → exit nonzero
  PASS 13.2 message names stale mirror + older-than wording
  PASS 13.3 fresh STATUS mirror not flagged

Test 14: live tracker.toml flat-file → staleness N/A
  PASS 14.1 flat-file live tracker.toml → exit 0
  PASS 14.2 staleness leg reports N/A for flat-file mode
```

### 4.3 `bash -n scripts/tests/tracker-config-schema-test.sh`

Exit 0 (no syntax errors). The file remains bash 3.2 compatible (no associative arrays, no `&>`, no GNU-only constructs); BSD `sed` / `awk` / `mktemp -d -t` portability preserved.

### 4.4 Direct before/after isolation runs (extracting pre-fix `validate-pack.py` from HEAD)

Used `git show HEAD:scripts/validate-pack.py > /tmp/.../validate-pack-OLD.py`, loaded both pre-fix and post-fix modules via `importlib.util.spec_from_file_location`, and ran each against scratch `/tmp` fixture roots. Results in §2 above per-finding (F1, F3, F4) confirm:

- F1: pre-fix failure count = 0 → post-fix failure count = 1 with the expected staleness message.
- F3: pre-fix failure count = 0 → post-fix failure count = 1 with `expected int, got bool`.
- F4: pre-fix failure count = 0 → post-fix failure count = 1 with `missing required key: backend.repo`.

---

## 5. Out-of-scope items / deviations / new POQs

### 5.1 Out of scope per caller's prompt

- **F2 (CI wiring of `tracker-config-schema-test.sh`)** — closed by the cross-BD CI wiring fix in commit `304078f`. No edits to `.github/workflows/validate-pack.yml` made by this fix.
- **F9 (BACKLOG `Resolved:` link rot)** — closed by Pattern B bulk-fix in commit `614e67e`. No edits to `BACKLOG.md` made by this fix.
- **`scripts/lib/tracker-config.sh` (the reader)** — read-only context per the prompt. The validator stays in lockstep with the reader's expected schema (`backend.repo` is consumed by `tracker_repo_slug()` at line 217; `mirror.location_*` keys at line 33-39 of `tracker.toml.pack-example`); no reader edits required.
- **Test-fixture `tracker.toml.example` files under `test-fixtures/v11-{tracker-on,flat-file}/`** — F6's path (b) chosen (docstring exclusion). Not validated; ownership stays with BD-115/116/117.

### 5.2 Plan deviations from the review's suggested fixes

None of substance. Two minor implementation choices vs the reviewer's exact suggestions:

1. **F3 — extra symmetric arm.** The reviewer suggested only the `int + isinstance(bool)` rejection. I added the symmetric `bool + not isinstance(bool)` arm too, because Python's bool/int subclass relationship is symmetric (`isinstance(1, int)` is True for `expected_type=bool` if you don't defend) and BD-078's bool keys (`migration.forward_complete`, `migration.reverse_available`, `mirror.enabled`, `mirror.regenerate_on_write`) would be silently accepted as integers without it. This stays internally consistent with Check 30's pattern (which guards `user_re_enable_count` on the int side). The change is additive defense, not a different design.
2. **F1 — gating signal choice.** The reviewer offered two paths: (a) implement the staleness leg, or (b) defer with a follow-up BD. Chose (a) — direct implementation against the spec wording in BACKLOG (V1 §A.2). The gating choice for "when does the leg fire?" is a live `tracker.toml` at the pack root + tracker mode + forward complete. The example files cannot exercise this because they ship in flat-file mode; this is by design (an example file is a template, not a live config). The implementation does NOT walk `project-template/docs/pack/tracker.toml` because that lives under client trees, not under the pack repo's CI scope.

### 5.3 New POQs introduced

**POQ-1 (informational, not blocking):** When v11.1+ adds backends with no `repo` concept (e.g. Linear / Jira teams), the F4 unconditional `_require("backend.repo", str)` will need to become a `backend.name`-conditional gate. Documented in-line at the new code site so the next maintainer is not surprised:

> "Required + non-empty for any github-backed install. We require it for all backends in v11.0 since `github` is the only first-class backend; future backends with no repo concept will need a backend-conditional check here."

This is forward debt, not a current bug. No new BD-NNN required at this time per pack memory rule "BDs reserved for new scope / new feature / new architecture" — when v11.1 lands a non-`github` backend, the BD that adds the backend handles the conditional update as part of its scope.

**POQ-2 (informational, not blocking):** The mirror-staleness leg compares timestamps lexicographically. This works correctly because the `Last regenerated:` header is always written in ISO-8601 Z-suffixed UTC form by `tracker_mirror_header_emit` (verified — `date -u '+%Y-%m-%dT%H:%M:%SZ'`). If a future header writer ever switches to a different format (e.g. with sub-second precision or a TZ offset), the regex in `_MIRROR_HEADER_TS_RE` and the lexicographic comparison both need refresh. Documented in-line in the helper docstring.

### 5.4 Definition-of-Done checklist

| Item | Status |
|------|--------|
| F1 (MUST) — staleness leg implemented per V1 §A.2 | PASS |
| F1 — exit-nonzero + clear message when stale | PASS (Test 13.1/13.2) |
| F1 — fresh mirrors not flagged | PASS (Test 13.3) |
| F1 — flat-file mode soft-passes | PASS (Test 14.1/14.2) |
| F1 — absent live tracker.toml soft-passes | PASS (live-tree run shows the new OK line) |
| F3 (SHOULD) — bool-as-int rejected for `int` | PASS (Test 10.1/10.2) |
| F3 — symmetric defense for bool keys | PASS (added in `_require()`) |
| F4 (SHOULD) — `backend.repo` required + non-empty | PASS (Tests 11/12) |
| F4 — both example files pass with their existing `repo =` lines | PASS (live-tree run) |
| F4 — comment documents future backend-conditional gate | PASS (in-line note) |
| F5 (SHOULD) — bare `ARCHITECTURE.md §3.1` references replaced with full paths | PASS (top-of-file + function docstring) |
| F6 (NIT) — docstring documents test-fixture exclusion | PASS (function docstring final paragraph) |
| F7 (NIT) — dead `VALIDATOR=` line removed | PASS (`grep -n VALIDATOR` returns nothing) |
| F8 (NIT) — `_ = (fwd, rev)` replaced with bare calls | PASS |
| `python3 scripts/validate-pack.py` passes | PASS (32/32 checks clean) |
| `bash scripts/tests/tracker-config-schema-test.sh` passes | PASS (28/28 assertions) |
| `bash -n scripts/tests/tracker-config-schema-test.sh` passes | PASS |
| No state-changing git verbs run | PASS (only `git rev-parse HEAD`, `git status`, `git diff --stat`, `git show HEAD:...`) |
| No edits outside allowed scope | PASS (only the two source files + new report) |
| No edits to BACKLOG.md / CHANGELOG.md | PASS |
| No edits to `.github/workflows/validate-pack.yml` | PASS |
| No edits to `scripts/lib/tracker-config.sh` | PASS |
| No edits to other concurrent coders' files (BD-095/129/130/131) | PASS |
| Trinity rule N/A (no edits to CLAUDE/AGENTS/GEMINI files) | PASS |
| Bash 3.2 + BSD utils compatibility preserved | PASS |
| Long-Write chunking discipline observed | PASS (initial Write + this Edit append) |

---

## 6. Files-changed inventory

```
M  scripts/validate-pack.py                        (Check 29 area only)
M  scripts/tests/tracker-config-schema-test.sh     (extended fixture suite, F6 docstring N/A)
A  maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-078-RETRO-FIX.md  (this file)
```

(`A` = added/new; `M` = modified.)

The other `M`-marked files visible in `git status` at session end belong to concurrent Batch 21c coders (BD-095, BD-129, BD-130, BD-131) and were not touched by this session — confirmed via `git diff HEAD -- scripts/validate-pack.py scripts/tests/tracker-config-schema-test.sh` returning the entire diff for in-scope files only.

---

## 7. Closing note

All 7 in-scope findings (F1, F3, F4, F5, F6, F7, F8) are closed. The two out-of-scope findings (F2, F9) were already closed by prior commits this batch. The shipped Check 29 now satisfies both halves of the BACKLOG acceptance criteria (schema validation AND mirror staleness), defends against the bool-as-int Python trap, gates the load-bearing `backend.repo` key, and documents its scope unambiguously.

Pack Chat may stage and commit the two source-file changes plus this new report.
