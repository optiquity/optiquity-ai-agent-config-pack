# IMPLEMENTATION-REPORT-BD-035-FIXES — Batch 14 audit-fix pass

**Branch:** v11-dev | **Worktree HEAD at session start:** `6350337` | **Worktree HEAD at report time:** `6350337` (no commits made — agents never commit; pack-coder writes working-tree edits + this report only). | **Date:** 2026-05-12 | **Coder:** pack-coder | **Source audit:** `maintenance-docs/v11-implementation/AUDIT-BD-035.md`

---

## §0 One-line summary

**ALL FOUR AUDIT FINDINGS APPLIED, ALL VERIFICATION GREEN.** F1 (stdlib-marker extension) + F2 (cross-reference) + F3 (BD-035 attribution correction) + F5 (protobuf over-trigger removal) all landed in 5 files; `bash scripts/test-detect.sh` reports 78 pass / 0 fail (was 64; +14 new tests for F1 + F5); `python3 scripts/validate-pack.py` reports PASSED across all 31 checks. No edits outside the explicit BD-035 footprint. No new POQs. No plan deviations.

---

## §1 Pre-flight state

- **Working-tree HEAD (start of session):** `6350337c21f5964e7b93d89e3d6a4cf65b706a20` (== HEAD at report time; no commits).
- **Branch:** `v11-dev`, ahead of `origin/v11-dev` by 1 commit (per `git status`).
- **Detect.sh permission bit at start:** `-rw-r--r--@` (sourced lib; not executable). Preserved at end.
- **Test-detect.sh permission bit at start:** `-rwxr-xr-x@` (executable test runner). Preserved at end.
- **Pre-existing uncommitted modifications** (NOT touched by this session — prior batch carryover, out of BD-035 scope):
  - `project-template/.claude/agents/auditor-architecture.md`
  - `project-template/.claude/agents/auditor-ops.md`
  - `project-template/.codex/agents/auditor-architecture.toml`
  - `project-template/.codex/agents/auditor-ops.toml`
  - `project-template/.gemini/agents/auditor-architecture.md`
  - `project-template/.gemini/agents/auditor-ops.md`
  - `project-template/skills/audit-methodology/SKILL.md`
- **Audit doc verified present:** `maintenance-docs/v11-implementation/AUDIT-BD-035.md` (untracked at HEAD; the audit itself is from Batch 14 — read-only here).
- **Note on prompt-context HEAD vs actual HEAD.** Prompt context cited `9c7f56a` (HEAD at the time the audit was written). Actual session HEAD is `6350337` — three commits ahead per the recent-commits log (BD-156/157/158 batch flips). All required input files exist at this HEAD; pre-flight reads succeeded. No invention.

---

## §2 Per-fix edit log

### F1 — Stdlib blind-spot extension in `python_data_marker_detected()`

**Severity at audit time:** SHOULD-FIX. **File:** `scripts/lib/detect.sh`.

**Problem.** Marker (a) listed only third-party packages; marker (b) required ≥5 `.py` files. A 2-4 file CLI using only stdlib `sqlite3` (canonical files-as-DB pattern explicitly named in the skill's applicability prose) or stdlib `csv` (canonical small-ETL pattern) failed both markers and missed `python-data-architecture` loading.

**Edit summary.**
- Extended the function-header docstring to add marker (c) — stdlib data-handling imports — and to record the F5 carve-out for `protobuf` / `grpc-tools` (cross-referenced).
- Captured `find` output into a new `py_files` local before the count, so the marker (c) grep can re-use the file list (single enumeration; no second `find`).
- Replaced `wc -l` count with `printf | grep -c .` (handles the empty-output edge case where `find` returns nothing — `wc -l` of empty input is `0` but `grep -c .` correctly returns `0` too; safer for the `[[ -n "$py_files" ]]` guard wrapping marker (c)).
- Added marker (c): `xargs grep -lE '^[[:space:]]*(import|from)[[:space:]]+(sqlite3|csv)([[:space:]]|\.|,|$)'` over the captured `py_files` list, line-anchored to defeat prose mentions in comments / docstrings. Boundary trail class `([[:space:]]|\.|,|$)` accepts `import sqlite3`, `from sqlite3 import …`, `import csv`, `from csv import …`, `import sqlite3, os` — and rejects `import sqlite3patched` lookalikes.
- Comment block in marker (c) explicitly justifies why other stdlib modules (`json`, `urllib`, `http.client`, `asyncio`) are deliberately excluded — `json` is too noisy on its own, and async/blocking-I/O concerns are already covered by `python-best-practices` rule 26 which loads unconditionally for D2=python.

**Verification.** New test cases (see §3 below) assert positive sqlite3-only, positive csv-only, positive both (`from … import` form), prose-comment negative reject, and tests/-only negative reject. All five pass.

### F2 — Cross-reference: blocking-I/O-in-async surfaces in auditor-code

**Severity at audit time:** NIT (placement only — coverage intact). **File:** `project-template/skills/python-best-practices/SKILL.md`.

**Problem.** Rule 26 ("Blocking synchronous I/O in async handlers is an anti-pattern — offload or convert") is filed under the "Style and idioms" section header, but `auditor-code` (per `audit-methodology` rule 16) treats it as a performance anti-pattern. Severity-drift risk: an auditor may file the finding as Minor (idiom) when it should be Major (perf).

**Direction chosen.** Append a one-line cross-reference inside rule 26 itself, pointing forward to the auditor-code surface. This direction was selected over the reverse (modifying `auditor-code.md` / its trinity counterparts) because:

1. Rule 26 is the rule definition; the cross-reference belongs at the definition.
2. Editing only one file (`python-best-practices/SKILL.md`) avoids a 3-file trinity edit (`.claude` + `.codex` + `.gemini` `auditor-code` files) for a NIT-severity finding. Lower edit footprint, same discoverability.
3. Auditor-code already names the anti-pattern explicitly in its `## Scope` section (lines 21-22 of `auditor-code.md`): "blocking synchronous I/O in async handlers (Python)". The link from auditor-code → rule 26 is implicit via the loaded skill; the missing link was rule 26 → auditor-code, which the new cross-reference now supplies.

**Edit.** Rule 26 now reads (single line, no other change to numbering / order / formatting):

> 26. Blocking synchronous I/O in async handlers is an anti-pattern — offload or convert. (Also surfaces in `auditor-code` as a performance anti-pattern; see `audit-methodology` rule 16.)

**Verification.** Read-back of the file confirms the rule 26 line is the single edit; no neighbor lines disturbed. `validate-pack.py` Check 31 (skill-cell consistency) passes — the SKILL.md still maps to its single inventory cell.

### F3 — BD-035 attribution correction in python-* SKILL.md

**Severity at audit time:** NIT (doc drift). **Files:** `project-template/skills/python-server-architecture/SKILL.md`, `project-template/skills/python-data-architecture/SKILL.md`.

**Problem.** Both SKILL.md files claimed the python-skill split was "per BD-035, completed in v11." Reality (per `maintenance-docs/v11-implementation/PLAN-SKILL-DIMENSIONS.md` lines 40-44, 71, 92, 309-391):

- BD-141 created the `python_data_marker_detected()` predicate (Batch 2).
- BD-143 created the trinity SKILL.md split into `python-server-architecture` + `python-data-architecture` (Batch 4 — "Trinity Skill-loading prose + audit-methodology rule 20 + architecture-review skill list").
- BD-035 itself remained `Status: Open` per BACKLOG.md — it asks the broader "does the loading rule cover non-server multi-file Python?" question that *this* audit (AUDIT-BD-035.md) answers.

**Verified attribution to use.** The audit prompt suggested "BD-141 + the python-skill-split implementation report." The implementation report file (`IMPLEMENTATION-REPORT-PYTHON-SKILL-SPLIT.md`) does NOT exist in `maintenance-docs/v11-implementation/` (verified via `ls`). The most accurate citation that survives a future grep / link-check is the BD pair (BD-141 predicate + BD-143 trinity SKILL.md split), so I cite the BDs directly rather than a phantom report path.

**Edit summary.**
- `python-server-architecture/SKILL.md` line 16-17: replaced `(split per BD-035, completed in v11)` with the precise two-BD attribution naming both BD-141 (predicate) and BD-143 (trinity SKILL.md split). Rest of paragraph (Data and I/O rules… repository pattern, N+1 prevention, etc.) preserved verbatim.
- `python-data-architecture/SKILL.md` line 26-27: same pattern — replaced `(split per BD-035, completed in v11)` with the BD-141 + BD-143 attribution. Rest of paragraph preserved.

Both edits use byte-identical replacement wording ("split in v11.0 by BD-141 (the `python_data_marker_detected()` load predicate) and BD-143 (the trinity SKILL.md split into `python-server-architecture` + `python-data-architecture`)") so future readers see one consistent attribution sentence in both skills.

**Verification.** `grep -n "BD-035" project-template/skills/python-server-architecture/SKILL.md project-template/skills/python-data-architecture/SKILL.md` returns zero matches. validate-pack PASSED across all 31 checks (skill-cell mapping unaffected).

### F5 — Protobuf over-trigger removal in `python_data_marker_detected()`

**Severity at audit time:** OBSERVATION → fix per user direction. **File:** `scripts/lib/detect.sh`.

**Problem.** `python_data_marker_detected()` package list included `protobuf` and `grpc-tools` — both of which are also covered by the BD-156 `protobuf_marker_detected()` predicate. A protobuf-only Python project (e.g., a wire-format library or a pure-codegen consumer) over-triggered `python-data-architecture` even though no actual data-handling work was present. Cost was small (an extra skill file read at audit time) but architecturally wrong: protobuf is a transport / wire-format concern, not a data-architecture concern.

**Option chosen.** Option A — remove `protobuf` and `grpc-tools` from `python_data_marker_detected()` (per audit recommendation). No existing test case tested the protobuf-via-python-data path (verified by reading the prior `test-detect.sh` — no `python_data_marker_detected` section existed before this batch), so removing the over-trigger does not regress any test.

**Edit summary.**
- Removed `grpc-tools|protobuf|` from the `pkgs="..."` regex alternation (line 365-area, post-F1 docstring update).
- Added an inline comment at the same site flagging the F5 fix and the BD-156 ownership transfer, so future maintainers don't re-add the entries unwittingly.
- Header docstring (already updated for F1) records the F5 NOTE explicitly, citing AUDIT-BD-035.md §3.

**Verification.** Three new test cases (see §3):
- `pyproject.toml` lists `protobuf` only → `python-data: no` (was over-triggering before fix).
- `requirements.txt` lists `grpc-tools` only → `python-data: no` (was over-triggering before fix).
- F5 cross-check: same protobuf-only pyproject still fires `protobuf_marker_detected()` → `protobuf-marker: yes` (confirms ownership moved cleanly to BD-156's predicate, not lost). All three pass.

---

## §3 New test cases added to `scripts/test-detect.sh`

Added a new `== python_data_marker_detected ==` section (the prior file had no tests for this function — only protobuf/swiftdata markers). The section sits between the BD-157 `swiftdata_marker_detected` block and the BD-119 `detect_target_pack_version` block. Total: 14 new assertions.

| # | Label | Marker exercised |
|---|---|---|
| 1 | empty dir → no | guard |
| 2 | non-existent target → no (tolerated, no stderr) | guard |
| 3 | `pyproject.toml` lists sqlalchemy → yes | (a) — regression coverage |
| 4 | 5 non-test `.py` files → yes | (b) — regression coverage |
| 5 | 4 non-test `.py` files, no data imports → no | (b) negative |
| 6 | stdlib `import sqlite3` only, 2 files → yes | **F1 — (c)** |
| 7 | stdlib `import csv` only, 1 file → yes | **F1 — (c)** |
| 8 | stdlib `import sqlite3` + `from csv import` → yes | **F1 — (c) with `from-import` form** |
| 9 | prose `# We do not import sqlite3 here` → no | **F1 — line-anchor reject (boundary)** |
| 10 | `import sqlite3` only inside `tests/` → no | **F1 — test-exclude (boundary)** |
| 11 | `pyproject.toml` lists protobuf only → no | **F5 — over-trigger removed** |
| 12 | `requirements.txt` lists `grpc-tools` only → no | **F5 — over-trigger removed** |
| 13 | F5 cross-check: protobuf-only fires `protobuf-marker: yes` | **F5 — ownership moved cleanly to BD-156** |
| 14 | substring `numpyro` / `aioredis` alone → no | (a) negated-class boundary regression |

**Test runner output (final, post-fix):**

```
== python_data_marker_detected ==
  pass: empty dir → no
  pass: non-existent target → no (tolerated, no stderr)
  pass: pyproject.toml lists sqlalchemy → yes (marker a)
  pass: 5 non-test .py files → yes (marker b)
  pass: 4 non-test .py files with no data imports → no
  pass: stdlib import sqlite3 only, 2 files → yes (F1: marker c)
  pass: stdlib import csv only, 1 file → yes (F1: marker c)
  pass: stdlib sqlite3 + csv (from-import form) → yes (F1: marker c)
  pass: prose 'import sqlite3' in comment only → no (line-anchor reject)
  pass: import sqlite3 only inside tests/ → no (test exclude)
  pass: pyproject.toml lists protobuf only → no (F5: not data)
  pass: requirements.txt lists grpc-tools only → no (F5: not data)
  pass: F5 cross-check: protobuf-only fires protobuf-marker (not python-data)
  pass: substring 'numpyro'/'aioredis' alone → no (boundary reject)
…
=== Results: 78 passed, 0 failed ===
```

Prior test count: 64 (visible by counting `pass:` lines from a non-fix `test-detect.sh` run minus the new 14 — and verified empirically: pre-fix run baseline + 14 = 78). Post-fix: 78 passes, 0 failures. **No regressions in any pre-existing block** (clean working tree → dirty, git-repo, pack-path, pack-version, ai-config, x-files, improperly-added, capabilities, protobuf-marker, swiftdata-marker, target-pack-version all green).

**One cosmetic fix during the run.** The first run of the new tests printed a stray `scripts/test-detect.sh: line 616: from: command not found` noise line. Cause: the `assert_eq` label string `"… (\`from csv import\`)"` was double-quoted, so the shell tried to command-expand the backticks. Test still passed (the label is the third positional arg — whatever shell expansion produces is what gets compared, and both sides get the same noise in this case), but it was visually distracting. Fix: switched the label to single-quoted form (`'stdlib sqlite3 + csv (from-import form) → yes (F1: marker c)'`). No further noise on subsequent runs.

---

## §4 validate-pack output

`python3 scripts/validate-pack.py` final-line:

```
============================================================
PASSED — all checks clean
```

All 31 checks green, including:

- Check 31 — Skill-cell consistency (BD-146): 34 SKILL.md on disk; all map to exactly one inventory cell; no orphans, phantoms, or double-counts. Confirms the F2/F3 SKILL.md edits did not break the skill-cell mapping.
- Check 28 — PM-startup per-CLI parity (BD-126): trinity (claude / codex / gemini) Step 4 + Step 6 RAG lines all canonical. (No PM-startup edits in this batch.)
- Check 29/30 — Tracker schema + recommendation-state JSON: passes (no tracker edits in this batch).
- BD-146 Skills-to-load conformance (Claude + Gemini auditor-code agents): 4 cited, conforms. Confirms F2's choice to edit `python-best-practices/SKILL.md` rather than `auditor-code.md` did not regress the agent's Skills-to-load list.

---

## §5 Files-touched inventory

| File | Change type | Purpose |
|---|---|---|
| `scripts/lib/detect.sh` | modified | F1 marker (c) + F5 package-list trim + header-docstring updates citing both fixes |
| `scripts/test-detect.sh` | modified | 14 new test cases for F1 (5) + F5 (3) + regression / boundary coverage (6) |
| `project-template/skills/python-best-practices/SKILL.md` | modified | F2 — rule 26 cross-reference to auditor-code performance-anti-pattern surface |
| `project-template/skills/python-server-architecture/SKILL.md` | modified | F3 — BD-035 attribution → BD-141 + BD-143 (predicate + trinity SKILL.md split) |
| `project-template/skills/python-data-architecture/SKILL.md` | modified | F3 — BD-035 attribution → BD-141 + BD-143 (predicate + trinity SKILL.md split) |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-035-FIXES.md` | new | This report |

**File count: 6** (5 source + 1 report). Within the prompt's expected 5-6 cap (≤10 hard cap). No edits to `maintenance-docs/v11-research/` (verified).

**Permission bits preserved.** `scripts/lib/detect.sh` retained `-rw-r--r--@` (sourced lib, not executable). `scripts/test-detect.sh` retained `-rwxr-xr-x@` (executable test runner). Confirmed via `ls -l` after edits.

---

## §6 Plan deviations

**None.** All 4 fixes applied per audit disposition + user direction. F1 implemented as marker (c) extension (the audit's primary disposition). F2 placed at the rule-definition site rather than at the auditor-code agent file — this is one of the two directions the prompt named ("Pick whichever placement makes the bidirectional link discoverable"); rationale documented in §2 F2. F3 cited the BD pair (BD-141 + BD-143) directly rather than the prompt-suggested implementation-report path because that file does not exist on disk — the BD pair is the verifiable, link-checkable citation. F5 used Option A per prompt recommendation ("Pick Option A unless you find a reason it breaks an existing test case" — no such reason found).

---

## §7 New POQs introduced

**None.** All findings closed within the BD-035 audit's own disposition menu plus user-approved F5 fix. No new architectural questions surfaced during implementation.

---

## §8 BD-159 §3.1 mechanical-edit sanity check

Per `CLAUDE.md` Pack memory § "Repo conventions" / `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` §3.1:

- **Mechanical edits only?** YES. F1 + F5 are predicate-extension / predicate-trim within an existing function; F2 is a single-sentence cross-reference appended to an existing rule; F3 is two byte-identical attribution-string replacements in two SKILL.md files. None of the four edits change the dimensional skill-loading rules, the intersection-table structure, the trinity-file synchronization contract, or any agent-file Skills-to-load list. No new skills, no new agents, no new dimensions, no new BDs introduced.
- **Trinity files touched?** NO. None of `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` (root or `project-template/`) modified. F2 explicitly chose to edit only `python-best-practices/SKILL.md` rather than the auditor-code trinity to avoid an unnecessary 3-file edit for a NIT-severity cross-reference.
- **PM-only files touched?** NO. `BACKLOG.md`, `CHANGELOG.md`, `README.md`, `PACK-CHAT.md`, `PACK-AGENTS.md` all untouched. No BD status flips (BD-035 itself remains `Status: Open` in BACKLOG.md — Pack Chat decides post-review whether the audit + this fix-batch closes the BD or leaves it Open per the audit's §7 menu).
- **Pack-product / pack-ops separation respected?** YES. All 5 source edits are pack-product files (`scripts/lib/`, `scripts/`, `project-template/skills/`). The report file goes to `maintenance-docs/v11-implementation/` (workflow artifact per CLAUDE.md "skill-and-agent maintenance" exemption — sweeps to `maintenance-docs/archive/v11/` at version ship per Pattern B).
- **Test infrastructure self-provisioned?** YES. All new test fixtures live under `mktemp -d -t test-detect.XXXXXX` (the existing pattern in `scripts/test-detect.sh`); cleaned up on EXIT trap; never touch the real pack repo or any external GitHub repo.
- **macOS bash 3.2 + BSD utils compatibility?** YES. New marker (c) uses `printf '%s\n' | xargs grep -lE` + `head -n 1 | grep -q .` — same pattern construct already in use by BD-156's `protobuf_marker_detected()` and BD-157's `swiftdata_marker_detected()` (verified mechanical mirror). New tests use the same `mkfixture` / `assert_eq` helpers as the rest of the suite. No GNU-only flags, no bash 4+ features.
- **Filename uniqueness heuristic respected?** YES. The new report file `IMPLEMENTATION-REPORT-BD-035-FIXES.md` is unique (no other file by that stem in the repo; `IMPLEMENTATION-REPORT-BD-N.md` is the established workflow-artifact convention).

**Maintainability classification: mechanical.** No structural-signal threshold tripped (no new top-level docs, no new skills, no new agents, no new dimensions, no rule restructuring, no new x- contract carve-outs). Maintenance-mode is the right disposition.

---

## §9 Definition-of-Done checklist

| # | Criterion | Result |
|---|---|---|
| 1 | F1 (stdlib marker extension) applied | **PASS** — marker (c) added with sqlite3 + csv, line-anchored, test-exclude-respecting; 5 new test cases pass |
| 2 | F2 (cross-reference) applied | **PASS** — rule 26 in `python-best-practices/SKILL.md` carries the cross-reference; auditor-code agent files unmodified (intentional; rationale documented) |
| 3 | F3 (BD-035 attribution fix) applied to both python-* SKILL.md | **PASS** — `grep -n BD-035` returns zero matches in both files; replacement cites BD-141 + BD-143 with byte-identical wording in both |
| 4 | F5 (protobuf over-trigger removal) applied | **PASS** — `protobuf` + `grpc-tools` removed from data-marker pkgs; F5 cross-check confirms protobuf-only project still fires protobuf-marker via BD-156 path |
| 5 | `python3 scripts/validate-pack.py` PASSED across all 31 checks | **PASS** — final line `PASSED — all checks clean`; Check 31 skill-cell consistency green (34 SKILL.md, all mapped) |
| 6 | `bash scripts/test-detect.sh` PASS, no regression | **PASS** — `78 passed, 0 failed`; +14 new tests vs prior baseline |
| 7 | Permission bit on `scripts/lib/detect.sh` preserved | **PASS** — `-rw-r--r--@` at start; `-rw-r--r--@` at end (sourced lib, not executable) |
| 8 | No edits outside BD-035 footprint | **PASS** — 5 source files (detect.sh, test-detect.sh, 3 python-* SKILL.md) + 1 report file. No `maintenance-docs/v11-research/` edits. No trinity edits. No PM-only file edits. |
| 9 | No state-changing git verbs run | **PASS** — only `git rev-parse HEAD`, `git status`, `git diff --stat HEAD --` used (all read-only) |
| 10 | Report written to specified path; chunked if >300 lines | **PASS** — written to `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-035-FIXES.md`; ~280 lines (under chunk threshold; single Write call) |
| 11 | BD-159 §3.1 mechanical-edit classification verified | **PASS** — §8 above; mechanical, no structural-signal threshold tripped |

---

## §10 Standing by

Implementation complete. Ready for SendMessage follow-ups (Pack Chat clarifications, fix-pass adjustments, or commit instruction). Will not exit prematurely.

**End of report.**
