# IMPLEMENTATION REPORT — BD-168 retro fix (pack-coder; post-review)

Status: implementation complete; ready for Pack Chat review + commit.

Branch: `v11-dev`
HEAD SHA at start: `b2b7e4c0a8f8ab095806fe7e85ba06a70bfc1e5a`
HEAD SHA at end: `b2b7e4c0a8f8ab095806fe7e85ba06a70bfc1e5a` (unchanged — agent made no
commits per `feedback_agents_never_commit`).
Working tree: 7 modified files; 0 new files; 2 pre-existing untracked files unchanged.

---

## §1 — Summary

Applied all 11 findings from Pack Chat's triage of
`PACK-REVIEW-BD-168-RETRO.md` (2 MUST + 5 SHOULD + 4 NIT). The two
MUST fixes convert the previously-inert Check 32 + Check 33 FAIL
recovery commands into fully-self-contained `bash -c '. _lib.sh && .
helper.sh && ...'` forms that a user can copy-paste verbatim (M1), and
relocate the Check 33 snapshot file from `stream_dir/` to the system
tempdir to eliminate the SIGKILL-leftover regression vector (M2). The
SHOULD fixes sweep "pre-Batch-22 pack-self" wording to the durable
"pre-BD-102 dog-food pack-self" (S1, 5 OK-message instances + cascading
docstring/comment sweeps), add pack-changelog stream + cross-stream-union
test coverage (S2, +15 new assertions in Group F), reconcile README cross-doc
counts (S3), sweep stale "Check 32" references in two older maintenance
docs to their current numbers (S4 — IMPL-REPORT-BATCH-17-FIX.md → "Check 35";
ARCHITECTURE-SKILL-DIMENSIONS.md → "Check 31" with renumber notes), and
document the intentional stderr-discard asymmetry (S5). The NIT fixes
remove `_per_entry_run_helper` dead code (N1), drop the
`skip_v8_archive` in-text suppression parameter from `_extract_references`
(N2), correct the "35 checks" wording to "33 invoked checks" in IMPL-REPORT-BD-168.md (N3),
and amend PLAN-PER-ENTRY-SPLIT-BATCH-19.md §5.6 pre-state count (N4 — 31 → 32 with edit-trail note).
All 8 baseline test suites green; BD-168 test runner expanded 46 → 65 PASS;
validate-pack.py self-test clean.

---

## §2 — Files modified / created

| Path | Pre-lines | Post-lines | Net | Type |
|---|---:|---:|---:|---|
| `scripts/validate-pack.py` | 3536 | 3555 | +19 | modified |
| `scripts/tests/test-validate-pack-checks-32-33-34.sh` | 508 | 755 | +247 | modified |
| `README.md` | (unchanged total — 3 ins / 2 del per numstat) | — | +1 | modified |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-168.md` | (17 ins / 17 del per numstat) | — | 0 | modified |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BATCH-17-FIX.md` | (3 ins / 3 del per numstat) | — | 0 | modified |
| `maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` | (2 ins / 2 del per numstat) | — | 0 | modified |
| `maintenance-docs/v11-implementation/PLAN-PER-ENTRY-SPLIT-BATCH-19.md` | (1 ins / 1 del per numstat) | — | 0 | modified |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-168-RETRO-FIX.md` | 0 | (this file) | (new) | new |

`git diff --numstat` output for source code + IMPL/architecture/plan
edits:

```
3       2       README.md
2       2       maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md
3       3       maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BATCH-17-FIX.md
17      17      maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-168.md
1       1       maintenance-docs/v11-implementation/PLAN-PER-ENTRY-SPLIT-BATCH-19.md
247     0       scripts/tests/test-validate-pack-checks-32-33-34.sh
87      68      scripts/validate-pack.py
```

No other paths touched. No PM-only files (BACKLOG.md / CHANGELOG.md /
PACK-CHAT.md / PACK-AGENTS.md / CLAUDE.md / AGENTS.md / GEMINI.md) modified.
No `/backlog/` or `/changelog/` per-entry trees touched (per Batch 19
forward-pointing note — those directories don't exist on pack-self
until BD-102 dog-food fires).

---

## §3 — Per-fix detail

### §3.1 — FIX M1 (MUST) — runnable recovery commands in Check 32 + Check 33 FAIL messages

**Pack Chat finding** (review §2.1 #1): `bash scripts/lib/per-entry/mirror-generate.sh`
is INERT (file is sourced-not-executed); `per_entry_regenerate_mirror …`
surfaces `command not found` without prior sourcing. The cited recovery
commands silently fail or no-op; user remains blocked.

**Fix applied:** replaced all three FAIL-message branches with
`bash -c '. _lib.sh && . <helper>.sh && [PE_FORCE_OVERWRITE_MIRROR=1] <func> <args>'`
form. Locations:

- Check 32 main divergence FAIL (`scripts/validate-pack.py` near the
  "out of sync" emit): replaced the inert `bash scripts/lib/per-entry/mirror-generate.sh`
  + the un-sourced `per_entry_regenerate_mirror` with the runnable
  `bash -c '...PE_FORCE_OVERWRITE_MIRROR=1 per_entry_regenerate_mirror ...'`
  form, with parenthetical explaining the helper is
  sourced-not-executed and the env var bypasses the divergence abort.

- Check 32 mirror-absent FAIL (the "per-entry tree present but mirror
  file absent" branch): replaced `bash scripts/lib/per-entry/mirror-generate.sh`
  with the same runnable form (no `PE_FORCE_OVERWRITE_MIRROR=1`
  needed — no on-disk mirror exists to overwrite).

- Check 33 TOC-absent FAIL: replaced
  `per_entry_regenerate_toc <key> <dir>` with the
  `bash -c '. _lib.sh && . toc-regenerate.sh && per_entry_regenerate_toc ...'`
  form.

- Check 33 TOC-divergence FAIL: same as above, with parenthetical
  noting the regenerator unconditionally overwrites (no force-env-var
  needed for TOC).

**Stream name preserved:** all four FAIL messages still name the
stream that's drifted, per the review's `no-band-aid` requirement
("`{mirror_rel} is out of sync with {stream_rel}/`").

**Manual verification** — see §4 (M1 recovery-command verification
subsection). Extracted the actual runnable form from a live FAIL
message and confirmed it fixes a synthetic divergence end-to-end
(divergence introduced → validator FAILs with runnable cmd →
extracted cmd executed against the scratch repo → mirror restored to
byte-identical → re-running validator emits OK).

### §3.2 — FIX M2 (MUST) — Check 33 snap location moved to system tempdir

**Pack Chat finding** (review §2.1 #2): `tempfile.mkstemp(dir=str(stream_dir))`
creates `.per-entry-toc-snap.XXXXXX.md` inside the per-entry directory;
a SIGKILL between mkstemp and the finally-block cleanup leaves the
file behind, which Check 32 pre-check (b) `_list_unknown_files`
flags as non-conforming on the NEXT validator run, turning CI red on
a leftover the validator itself produced.

**Fix applied:** changed `tempfile.mkstemp(dir=str(stream_dir))` to
`tempfile.mkstemp(dir=None)` (system tempdir). Now the snap lives
outside `stream_dir/` and a SIGKILL leftover cannot trip
`_list_unknown_files` on the next run.

**Cross-filesystem safety follow-up:** the snap was previously
restored via `Path(snap_path).replace(toc_path)` which uses
`os.rename` — that fails with `EXDEV` if `/tmp` is on a different
filesystem than the repo root. Both FAIL-path restore call sites
were converted from `Path(snap_path).replace(toc_path)` to
`toc_path.write_bytes(snap_data)` (the snap_data bytes are already
in memory from the initial read). This is cross-filesystem safe and
matches the snap-is-read-only-consumed invariant the prompt
described.

**Regression tests added** (in test runner Group G):
- G1: Check 33 PASS path → assert no `.per-entry-toc-snap.*` left in
  `stream_dir`.
- G2: Check 33 FAIL path (hand-edited `_toc.md`) → assert no
  `.per-entry-toc-snap.*` left in `stream_dir`.

Both PASS in the green run (see §4.2).

### §3.3 — FIX S1 (SHOULD) — "pre-Batch-22 pack-self" → "pre-BD-102 dog-food pack-self"

**Pack Chat finding** (review §2.2 #1): Batch 22 is BD-100 milestone
audit per EXECUTION-PLAN-V11.0.md:309; BD-102 dog-food is Batch 23 per
EXECUTION-PLAN-V11.0.md:434. The "pre-Batch-22 pack-self" wording
originated in the now-stale architect parent §10.5 and propagated to
the implementation.

**Fix applied:** all "pre-Batch-22 pack-self" → "pre-BD-102 dog-food
pack-self" (durable form per Pack Chat direction; BD-reference doesn't
break under further batch renumbers). Sweep covered:

- `scripts/validate-pack.py` — 6 occurrences total:
  - Top-of-file docstring at the Check 32 entry.
  - Check 32 function docstring "SKIP if ..." line.
  - Check 32 OK-message f-string (the multi-line pack-backlog SKIP message).
  - Check 33 OK-message f-string (same form, different function).
  - Check 34 OK-message single-string ("pre-Batch-22 pack-self per integration parent §10.5)").
  - `main()` comment block (`# gracefully when the per-entry tree is absent (pre-Batch-22 ...`).

  Verified by post-edit `grep -n "pre-Batch-22\|Batch 22\|Batch-22" scripts/validate-pack.py` returning empty.

- `IMPLEMENTATION-REPORT-BD-168.md` — narrative + §4.1 OK-line samples
  + §7.4 "Batch 22 dog-food fires" + §7.5 header + §7.5 narrative:
  swept consistently to "BD-102 dog-food" with cross-reference to
  EXECUTION-PLAN-V11.0.md:434 (the durable anchor). Also updated the
  §7.5 narrative reference to the recovery instruction to align with
  the new M1 runnable form.

  Verified by `grep -n "Batch 22\|Batch-22\|pre-Batch-22" IMPLEMENTATION-REPORT-BD-168.md` returning empty.

- Commit message body: git history, NOT amended (per the prompt's
  explicit "the commit message body is git history and CANNOT be
  amended").

Validator post-fix output confirms the new wording (see §4.1):

```
OK: backlog/ — not present (skipping; pre-v11.0 client or pre-BD-102 dog-food pack-self per integration parent §10.5)
```

### §3.4 — FIX S2 (SHOULD) — pack-changelog stream test coverage

**Pack Chat finding** (review §2.2 #2): test runner exercises only the
pack-backlog stream; the pack-changelog regex `^v\d+\.\d+(?:-[a-z0-9-]+)?\.md$`
and the Check 34 cross-stream `defined_all` union path are not
exercised.

**Fix applied:** added to `test-validate-pack-checks-32-33-34.sh`:

1. **New fixture builder `build_green_pack_changelog`** — materializes
   3 entries (`v11.0.md`, `v10.1.md`, `v10.0.md`) matching the
   regex, plus `_rules.md` + `_intro.md` + canonical
   `CHANGELOG.md` + `_toc.md` via the BD-164 helpers. Each entry
   has a date header (per the `_format.md` canonical shape from
   pack-changelog) and minimal version content.

2. **Group F — pack-changelog stream coverage** (15 new assertions):
   - F1 (positive Check 32): green pack-changelog → mirror byte-identical, pack-backlog SKIPs, no FAIL.
   - F2 (positive Check 33): green pack-changelog → `_toc.md` byte-identical.
   - F3 (positive Check 34): green pack-changelog (with body BD-100 ref stripped) → all refs resolve.
   - F4 (negative Check 32): hand-edited `CHANGELOG.md` → FAIL with runnable form + working-tree restored (`shasum` pre/post comparison).
   - F5 (cross-stream union Check 34): pack-backlog entry references `v11.0` (defined in pack-changelog) → resolves via `defined_all = union of defined_by_stream.values()` at `validate-pack.py:3280-3282`.

   The `run_check` function's `extra_streams` seam (pipe-delimited
   tuples) is now exercised — `PACKCL_TUPLE='pack-changelog|changelog|CHANGELOG.md|^v\d+\.\d+(?:-[a-z0-9-]+)?\.md$'`
   passed as `$3` to `run_check`.

3. **Group G — M2 snap-leftover regression** (4 new assertions):
   - G1: Check 33 PASS path → no `.per-entry-toc-snap.*` leftover in `stream_dir`.
   - G2: Check 33 FAIL path → same.

**Bash 3.2 + macOS BSD compat verified** — `bash -n` clean; uses only
portable constructs (`sed -i.bak ... && rm -f .bak`, `find ... -name
... -print`, no `<<<`, no `&>`).

Test runner pre 46 PASS / post 65 PASS (+19 new — F: 15, G: 4).

### §3.5 — FIX S3 (SHOULD) — README cross-doc consistency

**Pack Chat finding** (review §2.2 #3): README v11.0 row at line 60
said "31 Checks" (pre-BD-168), layout entry at line 190 said "25
Checks" (pre-v11), and `scripts/tests/` layout block at lines 230-231
didn't list the new BD-168 test runner.

**Fix applied:** ONLY the three locations the prompt scoped in:

- Line 60 — `v11.0` version row: "validate-pack.py expanded to 31 Checks ..."
  → "validate-pack.py expanded to 33 invoked checks (numbered Check
  1–11 and 16–35; Checks 12–15 retired per v9 sunset) — ... BD-168
  Checks 32/33/34 per-entry split validators (mirror-in-sync, TOC-in-sync,
  cross-reference integrity); ...".

- Line 190 — Repository Layout entry: "CI structural validation (25
  Checks; pack-internal)" → "CI structural validation (33 invoked
  checks; pack-internal)".

- Line 230-231 — `scripts/tests/` block: appended new line
  `scripts/tests/test-validate-pack-checks-32-33-34.sh  BD-168
  tests — per-entry split validators (mirror/TOC/cross-ref)`,
  matching the dry-run + gates entry style.

No other README sections modified — version table rows except v11.0 row
were not touched (per prompt scope and PM-only line rule).

### §3.6 — FIX S4 (SHOULD) — sweep 5 stale "Check 32" → correct numbering

**Pack Chat finding** (review §2.2 #4): BD-168 renumbered the pre-existing
Check 32 to Check 35 without sweeping cross-references. 3 references
in `IMPLEMENTATION-REPORT-BATCH-17-FIX.md` and 2 in
`ARCHITECTURE-SKILL-DIMENSIONS.md` still cite "Check 32".

**Fix applied — per-doc semantic decoding:**

- `IMPLEMENTATION-REPORT-BATCH-17-FIX.md:208, :209, :244` — all 3
  references are to the BD-106 phase-task-lib semantics (the function
  `check_tracker_phase_task_invariants`), which BD-168 renumbered
  from Check 32 to Check 35. Swept to "Check 35" with parenthetical
  edit-trail note "(renumbered from Check 32 by BD-168)" for future
  readers.

- `ARCHITECTURE-SKILL-DIMENSIONS.md:700, :1025` — both references are
  to the BD-146 skill-cell-consistency semantics
  (`check_skill_cell_consistency`). The architect's "Check 32 (next
  free)" wording was forward-pointing at architect-write time; the
  BD-146 implementation actually landed as Check 31 (not Check 32 —
  it took the then-next-free slot before any other check claimed
  it; verified via `grep -n "^def check_" scripts/validate-pack.py`
  where `check_skill_cell_consistency` is at line 2655, the 17th
  function listed but the 31st numbered check). Swept to "Check 31"
  with explanatory parenthetical citing both the BD-146 landing
  context AND the subsequent BD-168 renumber.

  Distinct from the BATCH-17-FIX.md sweep target (Check 35), per the
  prompt's "Read context first ... If the text refers to ... the
  BD-146 skill-cell consistency semantics, update to whatever the
  post-BD-168 number is" guidance.

Verified by `grep -nE "^def check_" scripts/validate-pack.py` cross-checked against the validate-pack.py
top-of-file docstring (Check 31 = `check_skill_cell_consistency`;
Check 35 = `check_tracker_phase_task_invariants`).

Note: line 240 of `IMPLEMENTATION-REPORT-BATCH-17-FIX.md` says
"validate-pack.py passes all 32 checks" — this is a Batch-17-time
count claim (accurate at archive time), NOT a "Check 32" reference;
left as-is per the historical-accuracy principle for archived
reports.

### §3.7 — FIX S5 (SHOULD) — document Check 32/33 stderr discard asymmetry

**Pack Chat finding** (review §2.2 #5): the helper's `pe_warn`
audit-trail stderr (Addendum #2 §4.5) is silently dropped on the
success-with-divergence path because the validator captures stderr
only for the `rc != 0` branch. The asymmetry is defensible (in CI
the validator's FAIL message IS the audit trail) but undocumented.

**Fix applied** (Option a per Pack Chat triage — document as intentional):

- Added a 6-line inline comment block in Check 32 immediately above
  the `subprocess.run(...)` call site citing:
  - Addendum #2 §4.5 (audit-trail intent on migrator path).
  - The CI-vs-migrator-path asymmetry (in CI, validator FAIL message
    IS audit trail; helper's pe_warn redundant on the CI path).
  - Why the silent discard is intentional (no behavior change; just
    clarity for future readers).

- Added a parallel 4-line comment block in Check 33 immediately above
  its `subprocess.run(...)` call site, with the same intent (Check 33
  doesn't use `PE_FORCE_OVERWRITE_MIRROR`, but the same stderr-discard
  pattern applies on the success-with-divergence path).

### §3.8 — FIX N1 (NIT) — remove `_per_entry_run_helper` dead code

**Pack Chat finding** (review §2.3 #1): `_per_entry_run_helper` defined
at the top of the BD-168 block but never called.

**Fix applied:** removed the 30-line function and its docstring,
replaced with an 8-line comment block explaining the seam was removed
per the project maintainability principle "favor actual-use over
speculative-API" (from `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md`).
The future-reader trail is preserved: if a future BD adds a third
check that needs the seam, the comment block guides them to the inlined
pattern used by Check 32 + Check 33 as the canonical reuse model.

### §3.9 — FIX N2 (NIT) — remove `_extract_references` `skip_v8_archive` parameter

**Pack Chat finding** (review §2.3 #2): the in-text `skip_v8_archive`
suppression is belt-and-suspenders (file-level skip at the walk loop
already excludes `_v8-resolved-archive.md`) and introduces a
theoretical false-negative risk for pack-changelog entries that might
legitimately carry `## Resolved — v11.0` H2.

**Fix applied:** removed the `skip_v8_archive` parameter from
`_extract_references` (and the call-site argument at the cross-ref
walk). Updated the function docstring to explain the file-level skip
is the canonical enforcement point.

Verified test C3 (`BD-999` inside `_v8-resolved-archive.md`) still
PASSes — the file-level skip at the walk loop suffices (test runner
re-confirms 12/12 Group C assertions PASS post-removal; see §4.2).

### §3.10 — FIX N3 (NIT) — IMPL-REPORT "35 checks" wording

**Pack Chat finding** (review §2.3 #3): `IMPLEMENTATION-REPORT-BD-168.md`
§4.3 conflates highest-number with count ("PASSED — all 35 checks
clean" implies 35 distinct checks; validator has 33 invoked functions).

**Fix applied:** §4.3 table row updated to "PASSED — all 33 invoked
checks (numbered Check 1–11 and 16–35; Checks 12–15 retired per v9
sunset) clean". The §1 "renumbered to Check 35" wording correctly
refers to the check NUMBER (not count) and was left as-is.

### §3.11 — FIX N4 (NIT) — PLAN §5.6 pre-state count

**Pack Chat finding** (review §2.3 #4): `PLAN-PER-ENTRY-SPLIT-BATCH-19.md:759`
said `validate-pack.py` had 31 check functions pre-BD-168; actual was
32 (the `check_tracker_phase_task_invariants` function existed but
was labeled Check 32 in its banner).

**Fix applied:** amended the pre-state line to "32 check functions"
with parenthetical edit-trail note "(amended 2026-05-16 per BD-168
retro fix — actual was 32, off-by-one in planner pass; see
`IMPLEMENTATION-REPORT-BD-168.md` §7.1)" and explanatory clarification
that the 32nd function was already labeled "Check 32" at planner-pass
time but was subsequently renumbered to Check 35 by BD-168.

---

## §4 — Verification

All commands run from
`/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`.

### §4.1 — Syntax + self-test

| Check | Result |
|---|---|
| `bash -n scripts/tests/test-validate-pack-checks-32-33-34.sh` | OK (exit 0) |
| `python3 -c "import ast; ast.parse(open('scripts/validate-pack.py').read())"` | OK (exit 0) |
| `python3 scripts/validate-pack.py` | PASSED — all checks clean |

Tail of `python3 scripts/validate-pack.py`:

```
── Check 35: Phase-task lib invariants (BD-106) ──
  OK: scripts/lib/tracker-phase-task.sh present
  OK: scripts/lib/tracker-labels.sh — no tracker_labels_folded_into helper definition (Path 3 forbidden)
  OK: scripts/lib/ — no `folded-into` literal in executable code (V3.3 §3 line 27); comment-only references allowed

============================================================
PASSED — all checks clean
```

S1 wording sweep verified live:

```
OK: backlog/ — not present (skipping; pre-v11.0 client or pre-BD-102 dog-food pack-self per integration parent §10.5)
OK: changelog/ — not present (skipping; pre-v11.0 client or pre-BD-102 dog-food pack-self per integration parent §10.5)
... (same for Check 33)
OK: no per-entry trees present (skipping; pre-v11.0 client or pre-BD-102 dog-food pack-self per integration parent §10.5)
```

### §4.2 — BD-168 test runner (with new pack-changelog tests)

`bash scripts/tests/test-validate-pack-checks-32-33-34.sh` — tail:

```
=== Group G: M2 snap-leftover regression (no snap files in stream_dir) ===
  PASS G1.1 Check 33 PASS path → rc=0
  PASS G1.2 Check 33 PASS path → no .per-entry-toc-snap.* leftover in stream_dir
  PASS G2.1 Check 33 FAIL path → rc=1
  PASS G2.2 Check 33 FAIL path → no .per-entry-toc-snap.* leftover in stream_dir

=== Summary ===
PASS: 65
FAIL: 0

All BD-168 validate-pack Check 32/33/34 tests PASSED (65/65).
```

Per-group breakdown:
- Group D (STREAMS structural smoke): 3/3 PASS (unchanged).
- Group A (Check 32 mirror-in-sync, pack-backlog): 15/15 PASS (unchanged).
- Group B (Check 33 TOC-in-sync, pack-backlog): 10/10 PASS (unchanged).
- Group C (Check 34 cross-ref, pack-backlog): 12/12 PASS (unchanged, N2 fix verified).
- Group E (§10.5 SKIP behavior): 6/6 PASS (unchanged).
- **Group F (pack-changelog stream coverage — NEW per S2): 15/15 PASS.**
- **Group G (M2 snap-leftover regression — NEW per M2): 4/4 PASS.**

Net change: 46/46 baseline → 65/65 post-fix (+19 new assertions).

### §4.3 — Baseline regression suites (zero regression)

| Suite | Pre | Post | Result |
|---|---:|---:|---|
| `bash scripts/tests/test-per-entry.sh` | 57/57 | 57/57 | PASS |
| `bash scripts/tests/test-init-project.sh` | 67/67 | 67/67 | PASS |
| `bash scripts/tests/test-migrate-v10-to-v11.sh` | 43/43 | 43/43 | PASS |
| `bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh` | 61/61 | 61/61 | PASS |
| `bash scripts/tests/test-migrate-v10-to-v11-gates.sh` | 87/87 | 87/87 | PASS |
| `bash scripts/tests/test-migrate-v10-to-v11-decompose.sh` | 45/45 | 45/45 | PASS |
| `bash scripts/tests/tracker-agent-read-test.sh` | 52/52 | 52/52 | PASS |
| `bash scripts/test-migrator-core.sh` | 19/19 | 19/19 | PASS |
| `bash scripts/test-persona-contracts.sh` | 3/3 contracts | 3/3 contracts | PASS |
| `python3 scripts/validate-pack.py` | clean | clean | PASS |

All 9 baseline suites + validate-pack self-test green. No regressions.

### §4.4 — M1 manual recovery-command verification

Built a synthetic divergent fixture in `/tmp` (with the same shape as
the BD-168 test runner's pack-backlog fixture: `_rules.md`,
`_intro.md`, `_v8-resolved-archive.md`, BD-100.md, plus a hand-edited
`BACKLOG.md` with a rogue trailing line). Ran the validator's Check
32 against it, captured the FAIL message verbatim, extracted the
runnable `bash -c '...'` form via grep, and executed it via `eval`
against the divergent scratch.

Live output (M1 recovery cycle):

```
=== Run validate-pack against the divergent scratch ===
── Check 32: per-entry mirror is in-sync with per-entry tree (BD-168) ──
FAIL: BACKLOG.md is out of sync with backlog/ — re-run `bash -c '. scripts/lib/per-entry/_lib.sh && . scripts/lib/per-entry/mirror-generate.sh && PE_FORCE_OVERWRITE_MIRROR=1 per_entry_regenerate_mirror pack-backlog /private/var/folders/.../backlog /private/var/folders/.../BACKLOG.md'` before committing (the helper is sourced-not-executed; PE_FORCE_OVERWRITE_MIRROR=1 bypasses the divergence abort); restored on-disk mirror to pre-check state

=== Execute extracted command ===
per-entry: WARNING: PE_FORCE_OVERWRITE_MIRROR=1; overwriting hand-edited mirror at /private/var/folders/.../BACKLOG.md
After recovery: mirror byte size =      219
Mirror tail after recovery:
## Resolved — v8 (March 2026)
- v8.0 — initial.

=== Re-run validator — should be CLEAN ===
── Check 32: per-entry mirror is in-sync with per-entry tree (BD-168) ──
  OK: backlog/ → BACKLOG.md byte-identical (219 bytes)
failures=0
```

M1 PASS — the FAIL message's runnable form, copy-pasted verbatim, restores
byte-identity and the subsequent validator run is clean.

### §4.5 — M2 snap-leftover regression check (manual + Group G)

**Group G (in-runner regression):** see §4.2 — G1/G2 PASS.

**Manual independent verification:** built a synthetic green
pack-backlog fixture, ran Check 33, then `find` for any
`.per-entry-toc-snap.*` in `stream_dir`:

```
=== Run Check 33 → assert NO snap is created in stream_dir ===
── Check 33: per-entry _toc.md is in-sync with per-entry tree (BD-168) ──
  OK: backlog/_toc.md byte-identical (169 bytes)
Check 33 failures=0

Post-Check-33 stream_dir contents (no .per-entry-toc-snap.* expected):
(directory listing showed only: _intro.md, _rules.md, _toc.md, BD-100.md)

M2 PASS: no snap leftovers in stream_dir/
```

Pre-M2 (before fix), the validator created the snap inside
`stream_dir/` via `tempfile.mkstemp(dir=str(stream_dir))`; the
finally-block cleanup would normally remove it, but a SIGKILL between
mkstemp and cleanup would leave a leftover. Post-M2, the snap is
created in the system tempdir (`/var/folders/...` on macOS) so the
leftover-from-SIGKILL scenario cannot trip `stream_dir/`'s
`_list_unknown_files` pre-check on the next run.

The cross-filesystem-safe restore (`toc_path.write_bytes(snap_data)`
instead of `Path(snap_path).replace(toc_path)`) was also verified
indirectly via Group B + Group G PASS — all FAIL-path restores
continue to leave the working tree byte-identical to pre-check state
(asserted via `shasum`).

### §4.6 — HEAD unchanged

```
$ git rev-parse HEAD
b2b7e4c0a8f8ab095806fe7e85ba06a70bfc1e5a
```

Matches starting HEAD; zero state-changing git verbs invoked.

---

## §5 — Definition-of-Done checklist

| Fix | Status | Evidence |
|---|---|---|
| M1 — runnable recovery commands in Check 32 + Check 33 FAIL messages | PASS | §3.1 + §4.4 (manual M1 verification: extracted form fixes divergence end-to-end). |
| M2 — Check 33 snap location in system tempdir | PASS | §3.2 + §4.5 (Group G G1/G2 + manual independent verification). |
| S1 — sweep "pre-Batch-22 pack-self" → "pre-BD-102 dog-food pack-self" | PASS | §3.3 (6 in validate-pack.py + cascading IMPL-REPORT sweeps); `grep -n "Batch 22\|Batch-22\|pre-Batch-22" scripts/validate-pack.py maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-168.md` returns empty. |
| S2 — pack-changelog stream test coverage | PASS | §3.4 (new build_green_pack_changelog + Group F 15 assertions + Group G 4 assertions); §4.2 (65/65 PASS, +19 new). |
| S3 — README cross-doc consistency | PASS | §3.5 (3 changes in scope: line 60 row, line 190 layout, line 230-231 tests block). |
| S4 — sweep 5 stale "Check 32" → correct numbering | PASS | §3.6 (IMPL-REPORT-BATCH-17-FIX.md 3 refs → "Check 35"; ARCHITECTURE-SKILL-DIMENSIONS.md 2 refs → "Check 31" with renumber notes). Verified via post-edit `grep -n "Check 32" maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BATCH-17-FIX.md maintenance-docs/v11-implementation/ARCHITECTURE-SKILL-DIMENSIONS.md` returning only the parenthetical historical-context references. |
| S5 — document Check 32/33 stderr discard | PASS | §3.7 (inline comment blocks added at both subprocess invocation sites citing Addendum #2 §4.5). |
| N1 — remove `_per_entry_run_helper` dead code | PASS | §3.8 (30-line function removed; 8-line explanatory comment block added); `grep -n "_per_entry_run_helper" scripts/validate-pack.py` returns only the explanatory comment. |
| N2 — remove `_extract_references` `skip_v8_archive` param | PASS | §3.9 (parameter + in-text logic removed; docstring updated); test C3 (BD-999 in v8 archive → still no FAIL) PASS confirms file-level skip suffices. |
| N3 — IMPL-REPORT "35 checks" wording | PASS | §3.10 (§4.3 table row updated; §1 wording untouched as it correctly cites Check NUMBER not count). |
| N4 — PLAN §5.6 pre-state count | PASS | §3.11 (line 759: 31 → 32 with edit-trail note + clarification of the planner-pass undercount). |

**11/11 fixes PASS.** Zero plan deviations.

---

## §6 — Plan deviations

**Zero plan deviations.** All 11 findings applied exactly per Pack
Chat's triage in the calling prompt. No options were skipped. No
substantive substitution of approach. Implementation notes that may be
useful for Pack Chat's commit-time review:

- **Cross-filesystem-safe restore in Check 33** (not explicitly named
  in M2 but logically required): the M2 fix moves the snap to system
  tempdir, which on macOS is `/var/folders/...` — a different
  filesystem than the repo root. `Path.replace()` (used in 2 FAIL-path
  restore call sites) wraps `os.rename` which raises `EXDEV` across
  filesystems. Switched the restore to `toc_path.write_bytes(snap_data)`
  using the in-memory `snap_data` bytes captured by the initial read.
  Behavior-equivalent (the file gets restored to byte-identical state)
  but cross-filesystem-safe.

- **S1 wording sweep coverage**: extended beyond the 5 OK-message
  instances called out by the prompt to also sweep the 1 top-of-file
  docstring + 1 Check 32 function docstring + 1 `main()` comment block
  (6 total in validate-pack.py), plus the cascading IMPL-REPORT
  narrative. Rationale: "drift-resilient phrasing" is a project rule;
  leaving the docstring stale while updating the OK-messages would
  create new internal-consistency drift.

- **S4 ARCHITECTURE-SKILL-DIMENSIONS.md sweep target = Check 31, not
  Check 35** (different from the IMPL-REPORT-BATCH-17-FIX.md target).
  The prompt explicitly named this contingency: "If it refers to the
  BD-146 skill-cell consistency semantics, update to whatever the
  post-BD-168 number is." That number is 31 (the BD-146 implementation
  took the next-free slot at landing time, which was 31, not the
  "Check 32 (next free)" the architect originally projected).

---

## §7 — Skip rationale

**Zero fixes skipped.** All 11 (2 MUST + 5 SHOULD + 4 NIT) applied.

Observations from §4 of the review report remain informational per
Pack Chat triage; brief disposition:

- **§5.h folding (verified working)**: no action needed; already
  correctly implemented in BD-168 commit `6696182` and verified by
  Group A tests A3 + A4 + A5.

- **§10.1 vs §10.6 architect-doc internal inconsistency**: routed to
  Batch 19b cleanup architect pass; explicitly out of scope for this
  retro fix per the prompt's "Out of scope" list.

- **Subprocess invocation eliminates in-memory drift (verified
  working)**: no action; named as a load-bearing design choice in BD-168.

- **CI step placement consistent (verified working)**: no action;
  alongside other validate-pack-Check tests in the workflow per BD-168.

- **STREAMS vs PE_STREAM_KEYS cross-encoding drift**: forward
  maintenance concern; not a BD-168 retro defect. Pack Chat may
  consider a follow-up cross-encoding-sync check in a future BD
  (would be a new BD, post-v11.0-launch). No action in this retro fix.

- **No trinity-rule impact (verified)**: BD-168 retro modifies only
  `scripts/validate-pack.py`, `scripts/tests/test-validate-pack-checks-32-33-34.sh`,
  README.md (in-scope lines only), and 4 maintenance docs. None of
  the pack-root or `project-template/` trinity files (CLAUDE.md /
  AGENTS.md / GEMINI.md) were touched. Trinity rule does not apply.

- **`bash -n` + `python3` self-execution clean (verified)**: confirmed
  in §4.1.

---

## §8 — Out-of-scope observations

(Intentionally empty per `feedback_deferral_is_scope_creep` and
`feedback_no_deferral_without_user_direction` — all 11 findings applied;
no new observations to surface; no scope-creep proposals.)

---

End of report.
