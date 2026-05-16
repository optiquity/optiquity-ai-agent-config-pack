# PACK-REVIEW — BD-168 (retroactive)

| Field | Value |
|---|---|
| Review subject | BD-168 — `validate-pack.py` Check 32 (mirror-in-sync) + Check 33 (TOC-in-sync) + Check 34 (cross-reference integrity); commit `6696182` |
| Review type | RETROACTIVE per-BD review (post-commit; pre-fix) |
| Reviewed against | `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` §10 / §10.5 / §10.6 / §18.2 #5 / §18.2 #6; `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md` §9.1; `PLAN-PER-ENTRY-SPLIT-BATCH-19.md` §5.6; `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` §3.2; `IMPLEMENTATION-REPORT-BD-168.md` |
| Reviewer | pack-reviewer (sub-agent) |
| Date | 2026-05-16 |
| Repo HEAD at review | `b2b7e4c` (v11-dev branch) |

---

## §1 — Summary

BD-168 lands three new `validate-pack.py` check functions — Check 32 (mirror-in-sync), Check 33 (TOC-in-sync), Check 34 (cross-reference integrity) — and a 508-line test runner exercising 46 assertions across 5 test groups. The implementation honors the integration parent §10.6 pack-side-scope binding (2 stream tuples, NOT 5 as one earlier section of the architect doc and the planner echo suggested), reuses the BD-164 helpers via `subprocess` for byte-identical regeneration (eliminating the highest-risk in-memory-vs-on-disk regen divergence question), restores the working tree byte-identically on every FAIL path, and SKIPs gracefully when per-entry trees are absent. CI green at `b2b7e4c`. The implementation is functionally correct in all observed cases.

Material defects: the FAIL-message recovery instruction for Check 32 (`bash scripts/lib/per-entry/mirror-generate.sh`) is silently inert — `mirror-generate.sh` is sourced-not-executed by design (the BD-164 IMPL report confirms this), so users following the error message would see "no error, no fix" and remain blocked; the alternative form in the same FAIL message (`per_entry_regenerate_mirror …`) requires sourcing first and would surface as `command not found`. Check 33 has the same defect twice. This converts a designed-as-actionable CI gate into a designed-as-puzzle CI gate. Three additional SHOULD-level findings: (a) stale `pre-Batch-22 pack-self` wording (the dog-food slot is Batch 23 per EXECUTION-PLAN-V11.0.md line 434, not Batch 22 per the now-superseded integration parent §10.5); (b) test runner exercises only pack-backlog, never pack-changelog or the multi-stream-defined-IDs union path; (c) Check 33 leaves dot-prefixed snap files (`.per-entry-toc-snap.XXX.md`) inside `stream_dir/` that are not gitignored and that would be flagged by Check 32 pre-check (b) as "non-conforming filename" if a previous validator run was SIGKILL'd between `mkstemp` and `unlink`. Plus a NIT (dead code: `_per_entry_run_helper` defined but unused), and a few README/cross-doc stale references (the README "25 Checks" / "31 Checks" / scripts/tests/ layout entries were not refreshed; six older maintenance docs reference the now-renumbered Check 32 with the BD-106 phase-task-lib semantics).

**Finding totals: 2 MUST + 5 SHOULD + 4 NIT.**

---

## §2 — Findings

### §2.1 — MUST

- **Severity**: MUST
- **Location**: `scripts/validate-pack.py:3036-3042` (Check 32 FAIL message); `scripts/validate-pack.py:3147-3150` and `scripts/validate-pack.py:3157-3161` (Check 33 FAIL messages)
- **Finding**: The recovery commands cited in the FAIL messages for Check 32 and Check 33 are not executable as written — they silently no-op or surface `command not found`, leaving the user with no actionable path to resolve the failure.
- **Evidence**: Live run against `/tmp/pack-test` (synthetic hand-edited mirror):
  ```
  FAIL: BACKLOG.md is out of sync with backlog/ — re-run
  `bash scripts/lib/per-entry/mirror-generate.sh` (or invoke
  `per_entry_regenerate_mirror pack-backlog /private/tmp/pack-test/backlog
  /private/tmp/pack-test/BACKLOG.md`) before committing; …
  ```
  Direct verification: `bash /Users/david/.../scripts/lib/per-entry/mirror-generate.sh` produces ZERO output and exits 0 — the file is sourced-not-executed by design (`scripts/lib/per-entry/mirror-generate.sh:51` "Do NOT add a shebang — this file is sourced, not executed"; matches BD-164 IMPL report §3.x explicit "Public API consumed by sibling helpers" framing). The alternative form (`per_entry_regenerate_mirror pack-backlog backlog BACKLOG.md`) is a bash function defined only after the helper is `source`d into the shell; the user typing it cold gets `command not found`. No top-level orchestrator script exists (`grep -l per_entry_regenerate_mirror scripts/*.sh` returns only `init-project.sh`, which calls the function from inside its own sourced context — not exposed as a verb). `HELP-FRAGMENT-PACK.md` and `scripts/pack-help.sh` contain zero references to `per-entry` or `regenerate`. Check 33 has the same defect in both the "absent" branch (line 3147-3150) and the "out of sync" branch (line 3157-3161).
- **Suggested remediation**: Ship a runnable form. Options the fix-coder may pick from include: (a) emit a fully-self-contained `bash -c '. … && per_entry_regenerate_mirror …'` form in the FAIL message; (b) add a top-level `scripts/per-entry-regenerate.sh` that takes `<stream-key>` and dispatches to the helper functions; (c) add a `pack regenerate-per-entry <stream>` verb wired through `scripts/pack-help.sh` + `HELP-FRAGMENT-PACK.md`. Whichever form lands, Check 32 + Check 33 FAIL messages must cite the form that a user can copy-paste verbatim and have it actually fix the divergence.

- **Severity**: MUST
- **Location**: `scripts/validate-pack.py:3093-3098` (Check 33 snap-file creation site) + working-tree-state assumption embedded in Check 32 pre-check (b) at `scripts/validate-pack.py:2841-2862`
- **Finding**: Check 33 creates its snapshot file as `<stream_dir>/.per-entry-toc-snap.XXXXXX.md` inside the per-entry directory itself, with no gitignore coverage; if any validator run is SIGKILL'd between `mkstemp` (line 3095) and the `finally` cleanup (line 3162-3167), a leftover dot-file is left in `stream_dir/`, which is NOT excluded by the `_list_unknown_files` pre-check (it filters `_*` and `known_supporting` only, never `.*`), so the NEXT validator run would FAIL Check 32 pre-check (b) with "non-conforming filenames: `['.per-entry-toc-snap.XXXXXX.md']`" — turning CI red on a leftover the validator itself produced.
- **Evidence**: `scripts/validate-pack.py:3095-3098`:
  ```python
  snap_fd, snap_path = tempfile.mkstemp(
      prefix=".per-entry-toc-snap.", suffix=".md",
      dir=str(stream_dir),
  )
  ```
  `scripts/validate-pack.py:2853-2861` (`_list_unknown_files`):
  ```python
  for child in sorted(stream_dir.iterdir()):
      if not child.is_file():
          continue
      name = child.name
      if name in known_supporting:
          continue
      if pattern.match(name):
          continue
      unknown.append(name)
  ```
  Direct test: `grep -rn "per-entry-toc-snap\|per-entry-snap" .gitignore project-template/.gitignore` returns empty (no gitignore entry covers the pattern). The Check 32 mirror snap (`.per-entry-snap.`) lives in `mirror_dir` (REPO_ROOT for canonical mirrors), not in `stream_dir`, so that path doesn't trip the same precheck — but the Check 33 snap IS in `stream_dir` and DOES trip it.
- **Suggested remediation**: Either (a) move the snap to a non-stream directory (e.g., `tempfile.mkstemp(dir=None)` → system tempdir; the helper invocation that consumes the snap is read-only on the snap, no atomic-rename requirement, so cross-filesystem is fine for read), OR (b) add a `name.startswith(".")` skip clause inside `_list_unknown_files` so leftover hidden files don't false-positive the pre-check, OR (c) ship a `.gitignore` covering `.per-entry-*snap.*.md`. Whichever form, the leftover-after-SIGKILL scenario must not turn CI red on the next push.

### §2.2 — SHOULD

- **Severity**: SHOULD
- **Location**: `scripts/validate-pack.py:2921` + `:2923` + `:3078` + `:3080` + `:3276` (all five "pre-Batch-22 pack-self" OK-message instances); + IMPL report §1 + §4.1 narrative; + commit message body "pre-Batch-22"
- **Finding**: The validator's SKIP messages cite "pre-Batch-22 pack-self" as the rationale for the SKIP, but the actual pack-self dog-food migration is in Batch 23 per `EXECUTION-PLAN-V11.0.md:434` (`Dog-food migration | Batch 23 | clean migrator output …`) and `EXECUTION-PLAN-V11.0.md:381` ("CI `validate` job must be green before BD-102 dog-food (Batch 23)"); Batch 22 is the BD-100 final milestone audit per `EXECUTION-PLAN-V11.0.md:309`. The stale wording originates in the integration parent §10.5 itself ("pack-self goes through the v10→v11 dog-food migration in Batch 22 of `EXECUTION-PLAN-V11.0.md`"), which was authored before Batch 21c was inserted; the implementation faithfully echoes the now-stale architect wording.
- **Evidence**: `EXECUTION-PLAN-V11.0.md:309` "**22** | sequential pack-architect + pack-reviewer (audit-only) | BD-100 final milestone audit"; `EXECUTION-PLAN-V11.0.md:434` "Dog-food migration | Batch 23"; `EXECUTION-PLAN-V11.0.md:381` ("CI `validate` job must be green before BD-102 dog-food (Batch 23)"). Validator emits this wording on every pack-self CI run today (see live run above: `OK: backlog/ — not present (skipping; pre-v11.0 client or pre-Batch-22 pack-self per integration parent §10.5)`).
- **Suggested remediation**: Replace all five "pre-Batch-22 pack-self" occurrences with "pre-Batch-23 pack-self" (or, more durably, "pre-BD-102 dog-food pack-self" — referencing the BD that actually fires the migration is stable across any further batch renumbers). Sweep the commit message body and IMPL report for the same reference and align. Decision on whether to also fix the integration parent §10.5 source is a Pack Chat call (per project rule, architect docs are PM-only).

- **Severity**: SHOULD
- **Location**: `scripts/tests/test-validate-pack-checks-32-33-34.sh:132-140` (Python wrapper `streams` override); Group A/B/C bodies (no test passes extras to `run_check`)
- **Finding**: The test runner exercises only the `pack-backlog` stream. The validator defines TWO streams (`pack-backlog`, `pack-changelog`), but every call to `run_check` defaults the `streams` override to `pack-backlog` only and no test passes a second `pack-changelog` tuple via the `extra_streams` extension point at lines 105-110. Consequences: (a) the pack-changelog entry regex `^v\d+\.\d+(?:-[a-z0-9-]+)?\.md$` is never exercised against a green or red fixture; if it drifts (e.g., a typo that breaks `vN.M-suffix` matching), Group A/B regressions would not catch the failure; (b) Check 34's `defined_all = union of defined_by_stream.values()` cross-stream union (line 3280-3282) is never tested — a pack-backlog entry referencing a pack-changelog ID (e.g., `v11.0`) would today succeed in real-world use but is not exercised by any test.
- **Evidence**: `test-validate-pack-checks-32-33-34.sh:132-134`:
  ```python
  streams = [
      ("pack-backlog", "backlog", "BACKLOG.md", r"^BD-\d+\.md$"),
  ]
  ```
  Grep for `pack-changelog` in the test runner returns only the structural-smoke test (`assert_contains "D1.2 STREAMS includes pack-changelog"`). No build helper exists for a green pack-changelog fixture. `build_green_pack_backlog` is the only fixture builder.
- **Suggested remediation**: Add a `build_green_pack_changelog` fixture builder (3 entries — `v11.0.md`, `v10.1.md`, `v10.0.md` with date headers + version content matching the BD-164 regex), and add at least one positive + negative test per check that includes the pack-changelog tuple in the streams override. Bonus: one Check 34 test where a pack-backlog entry references a pack-changelog version (e.g., `Resolved: 2026-05-16 in v11.0`) — exercises the cross-stream union path.

- **Severity**: SHOULD
- **Location**: `README.md:60` ("validate-pack.py expanded to 31 Checks"); `README.md:190` ("validate-pack.py CI structural validation (25 Checks; pack-internal)"); `README.md:230-231` (`scripts/tests/` partial layout block)
- **Finding**: README cross-doc consistency was not updated as part of BD-168. The v11 version row at line 60 still says "31 Checks" (pre-BD-168 count) and the Repository Layout entry at line 190 still says "25 Checks" (pre-v11 count). The new test runner `scripts/tests/test-validate-pack-checks-32-33-34.sh` is NOT listed under the `scripts/tests/` portion of the layout (lines 230-231 list only the dry-run + gates runners as exemplars; the BD-168 runner deserves the same treatment given the BD's structural significance).
- **Evidence**: `README.md:190`: `├── validate-pack.py                        CI structural validation (25 Checks; pack-internal)`. After BD-168 the highest-numbered check is Check 35 (renumbered phase-task) and the function-count is 33 (`grep -n "^def check_" scripts/validate-pack.py | wc -l` = 33; 31 numbered + 2 informational). Neither "25" nor "31" nor the BD-168 test runner name appear in any updated form.
- **Suggested remediation**: Reconcile the count to the post-BD-168 reality (recommend "33 Checks" if measuring by function-count, or "Checks 1–11, 16–35" if explicit about the retired 12–15 range). Add the BD-168 test runner to the Layout's `scripts/tests/` block. Decision on whether to also bring the v11 row at line 60 forward is a Pack Chat call (README version-table edits are PM-only per CLAUDE.md).

- **Severity**: SHOULD
- **Location**: `scripts/validate-pack.py:2865-2902` (Check 32 docstring "Failure mode" + "Recovery" lines); IMPL report §1 + §3.1.5 + §7.1
- **Finding**: BD-168 renumbered the pre-existing Check 32 (`check_tracker_phase_task_invariants`, BD-106) to Check 35 without sweeping cross-references in older maintenance docs. Three IMPL/architecture docs still reference the OLD Check 32 semantics ("phase-task lib invariants"): `IMPLEMENTATION-REPORT-BATCH-17-FIX.md:208`, `:209`, `:244` ("Check 32 in validate-pack: PASS"; "validate-pack Check 32 + test-suite assertions"), and `ARCHITECTURE-SKILL-DIMENSIONS.md:700` + `:1025` ("Add a new **Check 32** (next free) that parses PLATFORM-SKILLS.md tables"). A maintainer searching for "Check 32" today gets BOTH the new semantics (mirror-in-sync, BD-168) AND the now-stale semantics (phase-task lib, BD-106; skill-cell consistency, BD-146) without a sweep mechanism.
- **Evidence**: `grep -rn "Check 32" maintenance-docs/v11-implementation/` returns the references above. Pattern B sweeps these workflow artifacts at version ship — but until then they are live and misleading. The pre-Batch-22-vs-Batch-23 sweep above is a separate stale-wording trip.
- **Suggested remediation**: Either (a) sweep the three IMPL/architecture references to point at "Check 35" (preferred; restores cross-doc accuracy now), OR (b) explicitly defer the sweep to the version-ship Pattern B archive (and document the deferral in the BD-168 IMPL report §7.x out-of-scope block), OR (c) sweep `IMPLEMENTATION-REPORT-BATCH-17-FIX.md` only (the most likely future re-read target) and leave `ARCHITECTURE-SKILL-DIMENSIONS.md` to be caught at archive time. Pack Chat decides the scope.

- **Severity**: SHOULD
- **Location**: `scripts/validate-pack.py:3003-3009` + `:3010-3020` (Check 32 subprocess invocation); `scripts/validate-pack.py:3116-3121` + `:3122-3131` (Check 33 subprocess invocation); interaction with `scripts/lib/per-entry/mirror-generate.sh:243` (`pe_warn "PE_FORCE_OVERWRITE_MIRROR=1; overwriting hand-edited mirror at $mirror_path"`)
- **Finding**: When Check 32 forces overwrite via `PE_FORCE_OVERWRITE_MIRROR=1`, the helper emits an audit-trail warning to stderr per Addendum #2 §4.5 (cited in `mirror-generate.sh:242`). The validator captures this stderr via `capture_output=True` but discards it on every code path except `rc != 0` (line 3010-3020). Net effect in the divergence-detected case: the helper's audit-trail message is silently dropped, the validator restores the mirror, the FAIL message fires. The audit-trail signal that Addendum #2 §4.5 architected is invisible in the CI surface. This is borderline because the validator's FAIL message IS the audit trail for the CI scenario (and the architect-doc §4.5 audit-trail intent was anchored on the migrator path, not the CI path), but the asymmetry is silent and not documented in the BD-168 IMPL report.
- **Evidence**: `scripts/validate-pack.py:3003-3009`:
  ```python
  result = subprocess.run(
      ["bash", "-c", script],
      capture_output=True, text=True, stdin=subprocess.DEVNULL, env=env,
  )
  ```
  `:3010-3020` consumes `result.stderr` only when `result.returncode != 0`; on the success-with-divergence path (returncode 0 because the force-overwrite succeeded), `result.stderr` (the `pe_warn` line) is dropped.
- **Suggested remediation**: Either (a) document the silent-discard as intentional in a Check 32 / Check 33 docstring comment (cite Addendum #2 §4.5 and explain the CI-vs-migrator-path asymmetry), OR (b) surface the helper warning in the validator's OK / FAIL line so the audit trail propagates (`print(f"[helper warning] {result.stderr.strip()}")`). Decision is a Pack Chat call; the current behavior is defensible but undocumented.

### §2.3 — NIT

- **Severity**: NIT
- **Location**: `scripts/validate-pack.py:2809-2838` (`_per_entry_run_helper`)
- **Finding**: `_per_entry_run_helper` is defined but never called from within BD-168. Check 32 inlines its own `subprocess.run` invocation (line 3003-3009) to pass the `PE_FORCE_OVERWRITE_MIRROR` env var, and Check 33 also inlines (line 3116-3121) without using the helper. The IMPL report §3.1.2 acknowledges this: "the helper is retained as a named seam for future reuse." Dead code today; the seam is a forward-looking convenience that masks the inlined pattern.
- **Evidence**: `grep -n "_per_entry_run_helper" scripts/validate-pack.py` returns only the definition site (line 2809), no call sites.
- **Suggested remediation**: Either (a) actually use it in Check 33 (which has no env-var requirement and matches the helper's shape cleanly), OR (b) remove it and document the inlined-pattern reuse with a one-line comment. Forward-seam-for-future-use is a maintainability red flag; the principle from `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` favors actual-use over speculative-API.

- **Severity**: NIT
- **Location**: `scripts/validate-pack.py:3207-3226` (`_extract_references`)
- **Finding**: The `skip_v8_archive=True` branch suppresses references after any line matching `^## Resolved — v\d+\b`, regardless of which file the text comes from. In practice the validator already excludes `_v8-resolved-archive.md` from the walk entirely at line 3304-3306, so the in-text skip is purely belt-and-suspenders. But if a per-entry pack-changelog file (e.g., `v11.0.md`) ever contained an H2 like `## Resolved — v11.0`, every reference after it would be silently suppressed. Theoretical false-negative; not observed in current shape.
- **Evidence**: `_extract_references` is called only from `check_cross_reference_integrity` at line 3328 with `skip_v8_archive=True`. The walk loop at line 3301-3315 already SKIPs `_v8-resolved-archive.md` files entirely (line 3304). Pack-side changelog entries today use `## v11 — May 2026` style H2 headers (verified via `grep "^## " CHANGELOG.md`), not `## Resolved — v11`, so the false-negative is dormant.
- **Suggested remediation**: Either (a) remove the in-text `skip_v8_archive` parameter (since the file-level skip is sufficient and the in-text version risks false negatives), OR (b) add a comment at the call site explaining why the defensive in-text skip exists despite the file-level skip. NIT — not breaking.

- **Severity**: NIT
- **Location**: `IMPLEMENTATION-REPORT-BD-168.md` §1 ("the pre-existing Check 32 … was renumbered to Check 35"); `IMPLEMENTATION-REPORT-BD-168.md` §4.3 ("validate-pack.py | PASSED — all 35 checks clean")
- **Finding**: The IMPL report's "35 checks" wording at §4.3 implies 35 distinct checks, but the validator has 33 invoked functions (31 numbered + 2 informational; numbering 1–11 + 16–35 because 12–15 are retired). The highest-numbered check is Check 35; the COUNT is 33. Different concepts, conflated in the report.
- **Evidence**: `grep -n "^def check_" scripts/validate-pack.py | wc -l` = 33. `grep -E "^\s+check_" scripts/validate-pack.py | wc -l` = 33 (main() invocations). The docstring at lines 6–146 enumerates checks 1–11 + 16–35.
- **Suggested remediation**: Use "33 invoked checks (numbered Check 1–11 and 16–35; Checks 12–15 retired per v9 sunset)" in any forward-pointing prose. Update IMPL report §4.3 wording if it ships forward (otherwise NIT-only against the archived report).

- **Severity**: NIT
- **Location**: `PLAN-PER-ENTRY-SPLIT-BATCH-19.md:759` ("`validate-pack.py` has 31 check functions … verified by `grep -n "^def check_"`)
- **Finding**: Plan §5.6 Pre-state line undercounted by one (actual was 32 pre-BD-168). The IMPL report §7.1 surfaces this and explains the renumber-to-35 decision. The cosmetic-relabel approach (keep function name, renumber banner + docstring) is sound and matches the architect-doc's explicit "Check 32 / 33 / 34" naming. No code-level remediation needed; the planner-pass count was wrong and the implementer correctly worked around it.
- **Evidence**: `git show 6696182:scripts/validate-pack.py | grep -c "^def check_"` = 33 post-commit, was 32 pre-commit (BD-106's `check_tracker_phase_task_invariants` already existed but was labeled "Check 32"); the planner-pass figure of 31 was off-by-one. IMPL report §7.1 enumerates this and surfaces it to Pack Chat.
- **Suggested remediation**: No code-level fix needed. Pack Chat may opt to amend `PLAN-PER-ENTRY-SPLIT-BATCH-19.md:759` for archive-time accuracy, or accept the IMPL-report §7.1 surfacing as sufficient record.

---

## §3 — Test-coverage assessment

**What was added (46 assertions across 5 groups):**

| Group | Check | Scenarios covered | Assertion count |
|---|---|---|---|
| D | STREAMS smoke | structural — STREAMS includes pack-backlog + pack-changelog; tuples are 4-tuples | 3 |
| A | Check 32 (mirror-in-sync) | A1 in-sync green / A2 hand-edited mirror / A3 missing `_rules.md` / A4 non-conforming filename / A5 v8-archive edit | 15 |
| B | Check 33 (TOC-in-sync) | B1 in-sync / B2 hand-edited TOC / B3 missing TOC | 10 |
| C | Check 34 (cross-ref integrity) | C1 all-resolve / C2 dangling BD-555 / C3 BD-999 in v8 archive / C4 self-ref / C5 dangling phase-3 | 12 |
| E | SKIP behavior | E1 no per-entry tree → all 3 checks SKIP gracefully | 6 |

**Positive-case branches exercised:**
- Check 32 in-sync (A1) — green pack-backlog → byte-identical mirror → OK.
- Check 33 in-sync (B1) — green pack-backlog → byte-identical `_toc.md` → OK.
- Check 34 all-resolve (C1) — green pack-backlog → all refs resolve → OK summary.
- All three SKIP paths (E1.1–E1.6) — empty scratch_repo (no `backlog/`) → rc=0 + "not present" messages.

**Negative-case branches exercised:**
- Check 32 hand-edited mirror (A2) — divergence → FAIL with "out of sync" + names regenerator + working-tree restored.
- Check 32 missing `_rules.md` (A3) — pre-check (a) FAIL.
- Check 32 non-conforming filename (A4) — pre-check (b) FAIL.
- Check 32 v8-archive edit (A5) — folded pre-check (c) FAIL (folded into main divergence check).
- Check 33 hand-edited TOC (B2) — divergence → FAIL with "out of sync" + working-tree restored.
- Check 33 missing TOC (B3) — FAIL + working-tree restored (no leftover TOC).
- Check 34 dangling BD-555 (C2) — FAIL names file + line + ref + "no matching entry file".
- Check 34 dangling phase-3 (C5) — FAIL exercises §10.6 cross-stream scope (phase-N is project-side; not loaded).

**Working-tree restoration explicitly asserted via `shasum` pre/post:**
- A2.4 (Check 32 hand-edited mirror restored).
- B2.4 (Check 33 hand-edited TOC restored).
- B3.3 (Check 33 missing TOC stays missing — no leftover from regenerator).

**Branches NOT exercised (additional coverage that SHOULD be added):**
- **Pack-changelog stream** (any of A/B/C against the second stream). See §2.2 SHOULD-finding above. The streams override in `run_check` (lines 105-110) supports passing extras as pipe-delimited tuples; no test uses this seam.
- **Cross-stream `defined_all` union path** in Check 34. A pack-backlog entry referencing a pack-changelog version (e.g., `Resolved in v11.0`) is the multi-stream union test case; not exercised.
- **Multiple dangling refs in one file** in Check 34. The implementation has a `seen_ids_this_file` set (line 3330, 3340-3344) to de-dup FAIL messages by `(ref, line_no)`; no test exercises whether identical refs at different line numbers DO produce separate FAILs (the de-dup is by line, not by ref alone). Edge case.
- **`_intro.md` absent** in Check 32. The fixture always builds `_intro.md`; behavior when `_intro.md` is missing from the per-entry tree is untested.
- **Helper subprocess failure path** in Check 32 / Check 33 (the `result.returncode != 0` branch at line 3010-3020 / 3122-3131). Tested implicitly via "missing `_rules.md`" → BD-164 helper would error out, but no test directly exercises a synthetic helper-rc != 0 scenario.
- **Stale `.per-entry-toc-snap.XXXXXX.md` leftover** (related to §2.1 MUST-finding #2). If a previous validator run was SIGKILL'd, the leftover would be flagged by pre-check (b); no test exercises this regression vector.
- **Test of validator OK summary line `cross-reference integrity: N references across M files`** in C1 — C1.2 only checks for "all resolved" substring; the count format isn't validated.

**Branches deliberately not exercised (correct per architect-doc scope):**
- Code-block-internal `BD-NNN` references (§11.2 explicitly tolerates these as conservative false-positives; no test attempts to assert suppression).
- References in commit messages / workflow artifacts (§11.5 explicit out-of-scope).
- Cross-pack-and-project references (§11.5 explicit out-of-scope; only pack-side streams loaded per §10.6).

**Confidence summary:** the test runner covers the core positive/negative/SKIP triangle for each check against the pack-backlog stream, with explicit working-tree-restore assertions. Pack-changelog stream coverage and cross-stream union path coverage are the two highest-value additions. The stale-snap regression vector (§2.1 MUST #2) should also gain a test once the underlying behavior is fixed.

---

## §4 — Observations (not findings)

- **§5.h candidate-check folding into 3 checks** was implemented as named in integration parent §10.4 — `_rules.md` existence + filename conformance + v8-archive byte-stability all fold into Check 32 (pre-checks a/b/c). The IMPL report §5 A.1 + A.4 + test A3 + A4 + A5 confirm. No defect; named here as audit-trail.

- **The integration parent §10.1 pseudo-code says `for stream in STREAMS: # 5 streams`** but the binding constraint at §10.6 says pack-side scope ONLY (2 streams). The PLAN §5.6 manual-verification step also repeats the "5 stream tuples" instruction but immediately qualifies with "for pack-self validation only the first two are loaded". The implementer correctly identified §10.6 as the binding scope constraint and defined 2 tuples. This is correct, but the architect-doc internal inconsistency is named here in case Pack Chat wants to align §10.1 with §10.6 in a follow-up PM-only architect-doc edit.

- **The Check 32 + Check 33 implementation uses subprocess invocation of the BD-164 helpers**, not Python in-memory re-implementation. This eliminates the "in-memory regen byte-identical to on-disk regen?" question entirely — both paths call the SAME bash helper code. This was the highest-risk surface named in the calling prompt; the implementation correctly chose the lowest-risk pattern. No defect; named here as the load-bearing design choice that explains why no in-memory-vs-on-disk drift CAN exist by construction.

- **The CI step placement at `.github/workflows/validate-pack.yml:157-159`** is alongside the other per-entry test step (`per-entry helper tests (BD-164)` at line 154-156) and after the other validate-pack-Check test steps (`tracker-config-schema tests (BD-078, validate-pack Check 29)` at line 148-150; `recommendation-state-schema tests (BD-079, validate-pack Check 30)` at line 151-153). Logical grouping; uses `if: always()` matching every other tests-job step. No defect.

- **`STREAMS` constant vs `PE_STREAM_KEYS` cross-encoding drift detection**: BD-164's `scripts/lib/per-entry/_lib.sh:64` defines `PE_STREAM_KEYS="pack-backlog pack-changelog project-backlog project-implementation-plan project-changelog"` (5 streams), while BD-168's `scripts/validate-pack.py:189-193` defines `STREAMS` with 2 stream tuples (`pack-backlog`, `pack-changelog`). The validator's 2-tuple subset is correct per §10.6. But if BD-164 adds a 6th stream in the future, the validator silently won't validate it. There is NO runtime cross-check between the bash and Python encodings of stream identity. This is a forward maintenance concern, not a BD-168 defect (the validator's scope is explicitly pack-side-only). Pack Chat may consider a follow-up cross-encoding-sync check in a future BD.

- **Two earlier maintenance docs reference Check 32 with the pre-BD-168 semantics**: `IMPLEMENTATION-REPORT-BATCH-17-FIX.md` (3 references) and `ARCHITECTURE-SKILL-DIMENSIONS.md` (2 references). See §2.2 SHOULD-finding #4. Per Pattern B these would archive at version-ship; until then they're misleading.

- **No trinity-rule impact**: BD-168 modified only `scripts/validate-pack.py`, `scripts/tests/test-validate-pack-checks-32-33-34.sh`, `.github/workflows/validate-pack.yml`, and `IMPLEMENTATION-REPORT-BD-168.md`. None of CLAUDE.md / AGENTS.md / GEMINI.md (pack-root or `project-template/`) were touched, so the trinity rule does not apply.

- **`bash -n` + `python3` self-execution both clean**: `bash -n scripts/tests/test-validate-pack-checks-32-33-34.sh` returns 0; `python3 scripts/validate-pack.py` returns 0 with `PASSED — all checks clean`; `bash scripts/tests/test-validate-pack-checks-32-33-34.sh` returns 0 with `46/46 PASS`. CI green at b2b7e4c confirmed locally.

---

## §5 — Definition-of-Done verification

Per PLAN-PER-ENTRY-SPLIT-BATCH-19.md §5.6 "Verification gate" + "Constraints (architect-doc bindings)" — each criterion verified below.

| # | Criterion (paraphrased from §5.6) | Status | Evidence |
|---|---|---|---|
| 1 | `bash scripts/validate-pack.py` PASSES on the pack repo (Checks 32/33/34 SKIP) | PASS | Live run §observations + IMPL report §4.1; all three Checks emit "OK: … not present (skipping …)" or "OK: no per-entry trees present …"; overall validator exits 0. |
| 2 | New test runner PASSES against synthetic fixtures (green = pass, red = fail) | PASS | Live run §observations: 46/46 PASS. Each negative test (A2/A3/A4/A5, B2/B3, C2/C5) asserts rc=1 + matches the expected FAIL substring. |
| 3 | STREAMS constant matches §18.2 #5 tuple shape (per integration parent + Addendum #1 §9.1 planner qualifier) | PASS (with caveat) | `STREAMS` defined at line 189-193 with 2 tuples of 4 elements each. Architect §18.2 #5 text says "five stream tuples" (project-side included) but §10.6 (binding) says pack-side ONLY. Implementer correctly picked §10.6 as binding. Plan §5.6 also says "5 stream tuples per integration parent §18.2 #5" but qualifies "for pack-self validation only the first two are loaded" — implementation is plan-conformant when read with the qualifier. See §4 Observations for the architect-doc internal inconsistency. |
| 4 | Check 32 pre-checks fold §10.4 supplementary checks: (a) `_rules.md` exists, (b) filename conformance, (c) v8-archive byte-stable | PASS | (a) → line 2927-2934 + test A3; (b) → line 2936-2945 + test A4; (c) → folded into main divergence check via line 3022-3042 + test A5. |
| 5 | Check 34 SKIPs the v8 archive per §11.3 | PASS | Line 3287 `v8_archive_basenames = {"_v8-resolved-archive.md"}`; line 3304-3306 explicit `continue` for the file; line 3328 `skip_v8_archive=True` is a defensive belt-and-suspenders pass for any in-entry `## Resolved — v\d+` header. Test C3 verifies BD-999 inside `_v8-resolved-archive.md` does not FAIL. |
| 6 | Three checks total per §10.4 (NOT six) | PASS | Three `def check_*` additions; supplementary §5.h candidates 3/4/6 fold into Check 32 pre-checks per (a)/(b)/(c). |
| 7 | Each check is a Signal 4 trip per `ARCHITECTURE-SKILL-AGENT-MAINTAINABILITY.md` §3.2; architect+planner pass IS the defense | PASS | §3.2 line 285-287 explicitly names Signal 4 as "New validator check"; THE BD-168 architect+planner pass (integration parent §10 + PLAN §5.6) provides the named defense. |
| 8 | Each check SKIPs gracefully when per-entry tree absent (§10.5 backward-compat) | PASS | Check 32 line 2919-2925; Check 33 line 3075-3081; Check 34 line 3266-3277. Test E1.1–E1.6 exercise all three SKIP paths. Live pack-self CI confirms (no `backlog/` or `changelog/` → all three SKIP). |
| 9 | Pack-side scope only per §10.6 (project-side trees validated by client CI) | PASS | `STREAMS` defines only `pack-backlog` + `pack-changelog`; no `docs/project/*` paths. Test C5 confirms cross-stream `phase-3` reference (project-implementation-plan, not loaded) is correctly flagged as dangling — the §10.6 scope rule from the failure side. |
| 10 | Pseudo-code disclaimer per Addendum #1 §9.2 ("planner refines exact implementation") | PASS | Check 32 docstring line 2868-2869; Check 34 docstring line 3232-3233. Both call out "Pseudo-code sketches the behavioral contract; planner refines exact implementation (per Addendum #1 §9.2 disclaimer)." |
| 11 | Each check uses existing check-function shape (banner, OK/FAIL prints, exit codes) | PASS | Each function: `print(f"\n── Check NN: <name> (BD-NNN) ──")` banner; uses `ok()` / `fail()` module-level helpers; runs inside `main()` which collects failures into module-level `failures` list and `sys.exit(1 if failures else 0)`. Consistent with pre-existing checks 1–31. |
| 12 | CI step wired in `.github/workflows/validate-pack.yml` (step count +1) | PASS | New step at line 157-159 "validate-pack Check 32/33/34 tests (BD-168, per-entry split validators)" with `if: always()` + `bash scripts/tests/test-validate-pack-checks-32-33-34.sh`. Per Batch 21c "test-not-in-CI" empirical heuristic. |
| 13 | All baseline tests preserved (zero regression) | PASS | IMPL report §4.3 verifies: test-per-entry 57/57, test-init-project 34/34, migrate-v10-to-v11 43/43, dry-run 61/61, gates 87/87, tracker-agent-read 31/31. |
| 14 | Bash 3.2 + macOS BSD-utility compatible | PASS | `bash -n` on test runner clean; no GNU-isms (no `declare -A`, `<<<`, `&>`, `mapfile`, `readarray`). Local bash 3.2.57 verified by IMPL report §4.4. |
| 15 | No state-changing git verbs | PASS | IMPL report §C.1; HEAD unchanged across implementation. |

**Definition-of-Done verdict: 15/15 criteria PASS** at the architect-binding level. The MUST findings in §2.1 are USER-FACING DEFECTS that do not violate any §5.6 criterion explicitly named in the plan, but they violate the project "no band-aid fixes" principle (error messages must point at runnable recovery commands; the current recovery commands are inert / not-found). The SHOULD findings span stale wording (pre-Batch-22), missing test coverage (pack-changelog stream), cross-doc consistency (README + older IMPL reports), and a silent stderr discard. None of these block the Definition-of-Done as written; they are correctness-of-the-thing findings that the plan did not explicitly enumerate as verification gates.

---

End of report.
