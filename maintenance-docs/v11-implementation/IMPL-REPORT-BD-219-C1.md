# IMPL-REPORT — BD-219 C1 (`--only-check` + CHECK_REGISTRY + per-check e2e adoption + 3 stale-comment strips)

**Agent:** pack-coder (fresh) · **Date:** 2026-06-14 · **Scope keyword:** `pack-only`
**Plan SSOT:** `maintenance-docs/v11-implementation/PLAN-BD-219-CI-RUNTIME-OPTIMIZATION.md` §C1 + §1
**Design SSOT:** `maintenance-docs/v11-implementation/ARCHITECTURE-BD-219-CI-RUNTIME-OPTIMIZATION.md` §3, §6, §6.4

---

## 0. REGIME BLOCK (runtime-verified, not trusted from settings)

| Probe | Value |
|---|---|
| `pwd` | `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-ab506c5d7d320c396` |
| `git rev-parse --show-toplevel` | `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-ab506c5d7d320c396` |
| `git rev-parse HEAD` (start) | `f140c48722940578a325971b9f12611a6e9db1fd` |
| `git rev-parse HEAD` (end) | `f140c48722940578a325971b9f12611a6e9db1fd` (unchanged) |
| `git status --short` (start) | clean (no tracked changes) |
| branch | `worktree-agent-ab506c5d7d320c396` (worktree branch off `v11-dev` @ f140c48) |

**REGIME = ISOLATED.** The toplevel is a worktree path (NOT the main checkout
`/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`). HEAD is
`f140c48` — the parent's local HEAD, **NOT** `origin/main` → isolation is
correctly based; no "isolation mis-based" baseRef bug. All git verbs run were
read-only (`rev-parse`, `status`, `diff`, `show`, `branch`). No state-changing
git verb was run at any point.

**HANDOFF (this report + patch):**
- `/tmp/handoff-bd219-c1/c1.patch` ← `git diff HEAD` (961 lines; 23 `diff --git`
  headers). Read-only emit.
- `/tmp/handoff-bd219-c1/IMPL-REPORT.md` ← this file.
- Worktree NOT removed; orchestrator applies the patch onto the main tree and
  commits (with user approval). Agent did NOT stage/commit/apply.

---

## 1. FILES CHANGED INVENTORY (23 files, all `modified`; 0 new, 0 deleted)

| Path | Change | Nature |
|---|---|---|
| `scripts/validate-pack.py` | modified | argparse `--only-check` + `_build_check_registry()` + `_resolve_only_check()` + `main(only_check=None)` dispatch + total-run budget suppression in single-check mode + 3 stale "Check 54 reserved" comment strips |
| `scripts/tests/test-validate-pack-check-16.sh` | modified | e2e leg → `--only-check 16` |
| `scripts/tests/test-validate-pack-check-18.sh` | modified | e2e leg → `--only-check 18` |
| `scripts/tests/test-validate-pack-check-19.sh` | modified | e2e leg → `--only-check 19` |
| `scripts/tests/test-validate-pack-check-39.sh` | modified | e2e leg → `--only-check 39` |
| `scripts/tests/test-validate-pack-check-40.sh` | modified | e2e leg → `--only-check 40` |
| `scripts/tests/test-validate-pack-check-41.sh` | modified | e2e leg → `--only-check 41` |
| `scripts/tests/test-validate-pack-check-42.sh` | modified | e2e leg → `--only-check 42` |
| `scripts/tests/test-validate-pack-check-43.sh` | modified | e2e leg → `--only-check 43` |
| `scripts/tests/test-validate-pack-check-44.sh` | modified | e2e leg → `--only-check 44` |
| `scripts/tests/test-validate-pack-check-45.sh` | modified | e2e leg → `--only-check 45` |
| `scripts/tests/test-validate-pack-check-46.sh` | modified | e2e leg → `--only-check 46` |
| `scripts/tests/test-validate-pack-check-49-field-faithfulness.sh` | modified | BOTH legs (deep + general) → `--only-check 49` |
| `scripts/tests/test-validate-pack-check-50-codec-single-source.sh` | modified | e2e leg → `--only-check 50` |
| `scripts/tests/test-validate-pack-check-51-flip-block.sh` | modified | e2e leg → `--only-check 51` |
| `scripts/tests/test-validate-pack-check-52.sh` | modified | e2e leg → `--only-check 52` |
| `scripts/tests/test-validate-pack-check-53.sh` | modified | e2e leg → `--only-check 53` |
| `scripts/tests/test-validate-pack-check-54.sh` | modified | e2e leg → `--only-check 54` |
| `scripts/tests/test-validate-pack-check-55.sh` | modified | e2e leg → `--only-check 55` |
| `scripts/tests/test-validate-pack-check-56.sh` | modified | e2e leg → `--only-check 56` |
| `scripts/tests/test-validate-pack-check-57.sh` | modified | e2e leg → `--only-check 57` |
| `scripts/tests/test-validate-pack-check-removed-doc-advisory.sh` | modified | e2e leg → `--only-check 48` |
| `scripts/tests/test-validate-pack-checks-36-37-38.sh` | modified | G6.T11 leg → `--only-check 37` (Group 4 full-run leg deliberately UNCHANGED — see §6 deviation) |

`test-fixtures/manifest.txt`: **NOT changed** — regen ran (`build.sh --all
--clean`) and the diff vs HEAD is EMPTY (C1 touches no fixture SHA). Not staged
(§3). `test-validate-pack-checks-32-33-34.sh`: NOT changed — it has no
full-validate-pack subprocess e2e leg (module-import only), so there is no leg
to adopt.

---

## 2. PER-TASK SUMMARY

### Task A — `--only-check` argparse + CHECK_REGISTRY refactor (`scripts/validate-pack.py`)

`main()`'s flat 57-callsite `run_check(...)` sequence was refactored into a
single ordered registry built by a new `_build_check_registry()` and dispatched
by a new `main(only_check=None)`. Greenfield argparse (`import argparse` inside
the `if __name__ == "__main__":` block — 0 prior argparse, EE-P7) parses
`--only-check` and passes it to `main()`.

**Registry shape:** `(number, label, fn, budget_s)` 4-tuples.
- 57 entries (matches the 57 prior `run_check` callsites exactly — EE-P5).
- `number` is the integer from the check's `── Check N:` banner, or `None` for
  the two historically-unnumbered checks (`check_issue_template_forms`,
  `check_template_archive_v11`, whose banners read `── Check: … ──`).
- Checks 16/18/19 each register TWICE (project-template + pack-root surfaces) —
  so an integer `--only-check 16` selects **both** entries (verified §4 B),
  preserving the "both invocations execute" per-check test assertions.
- Check 49 keeps its larger `RUN_CHECK_DEEP_FAITHFULNESS_BUDGET_S` per-check
  budget.

**Dispatch (`main(only_check=None)`):**
- `only_check is None` (no-flag default AND the value used by every in-process
  caller, e.g. the §4.7 runtime-budget test's `mod.main()`) → iterate the FULL
  registry through `run_check` → byte-identical to pre-BD-219 behavior; total-run
  budget LIVE.
- selector set → `_resolve_only_check()` matches by integer number (all entries
  of that number) OR exact label; runs ONLY the matched entries; total-run
  budget SUPPRESSED (prints `(total-run budget N/A in single-check mode; …)`);
  per-check WARN budget STAYS active (it routes through `run_check` with each
  entry's `budget_s`).
- **Unmatched selector → LOUD named error + exit 1** (never a silent no-op,
  which would turn a per-check test into a tautology = effectiveness loss).
- Exit-code contract preserved: `--only-check K` exits non-zero IFF the selected
  check appended to `failures`.

**Module-import path preserved:** the `if __name__ == "__main__":` guard stays;
argparse lives inside it. The per-check tests' `spec_from_file_location` import
does NOT run `main()` (unchanged). `mod.main()` (called in-process by the
runtime-budget test) still runs the full registry + enforces the total-run
budget — verified §4 F.

**Line delta:** `scripts/validate-pack.py` +400/−285 net (the registry literal +
the two helper functions + the `main()` signature/dispatch rewrite; every inline
landing-rationale comment block — BD-183/BD-181/BD-168/BD-175/BD-179/BD-180/
BD-196/BD-195/BD-204/BD-214/BD-197 — was carried verbatim into the registry,
edit-in-place, no section dropped).

### Task B — 3 stale "Check 54 reserved" comment strips (`scripts/validate-pack.py`)

Located by grepping `reserved` near `54`/`Guard-A′` (NOT by line number — they
drift). All three were inside Check 54/55/57's landing-comment blocks. Stripped
the stale "reserved" assertion from each (Check 54 IS implemented + CI-wired,
yml line 232 — so "reserved" was stale), preserving all surrounding non-stale
comment text. Did NOT renumber or touch Check 54's implementation.

Before → After (text, not line numbers):
1. `… Check number 54 — reserved for Guard-A′ across the prior BD-197 commits; with this landing, checks 52–57 are contiguous. Per …`
   → `… Check number 54. Per …`
2. `… Check number 55 (next available after 52/53/56; 54 is reserved for the C8b Guard-A′ — a non-contiguous gap is expected and tolerated; numbers ≠ commit order). …`
   → `… Check number 55 (a non-contiguous gap relative to commit order is expected and tolerated; numbers ≠ commit order). …`
3. `… Check number 57 (next available after 52/53/55/56; 54 is reserved for the C8b Guard-A′ — the gap is expected). Per …`
   → `… Check number 57. Per …`

Post-edit re-grep: `grep -niE 'reserved' scripts/validate-pack.py | grep -E
'54|Guard-A'` → **no Check-54-reserved comment remains** (the only residual
`reserved` hit is the word "preserved" in Check 3's unrelated comment — a
substring match, not a Check-54 reference).

### Task C — per-check e2e leg adoption of `--only-check NN` (22 test files, 23 legs)

Each single-check e2e subprocess `python3 …/validate-pack.py` became
`python3 …/validate-pack.py --only-check NN` (NN = that file's check number).
**ALL existing assertions preserved verbatim** — only the subprocess flag was
added. The module-import unit-assertion legs are UNCHANGED. Check 49 has two
legs (deep `PACK_VALIDATE_DEEP=1 … --only-check 49` + general `… --only-check
49`), both adopted with the env var preserved. The deferred wiring-proof
(§3.4/§6.4) — the e2e leg no longer implicitly proves the check is wired into
the full `main()` run; that proof is restored as C3's registry-completeness
guard — is a KNOWN GAP-UNTIL-C3 by design (ordered C1→C3, §3 of the plan).
This is the ONLY weakening of any kind, it is by design, and no per-check
assertion is otherwise weakened.

### Task D — manifest regen (`regenerate-manifest-v11-surface`)

Ran `bash test-fixtures/build.sh --all --clean` (exit 0) then `git status
--short test-fixtures/manifest.txt` → **empty**; `git diff --quiet
test-fixtures/manifest.txt` → empty. **Manifest diff EMPTY — not staged** (C1
edits validate-pack.py + test scripts, never a fixture; the manifest pins
fixture SHAs, not script text). Matches the plan's expectation.

---

## 3. VERIFICATION EVIDENCE (quoted exit statuses)

### 3.1 Top-level validators
| Command | Exit | Verdict |
|---|---|---|
| `python3 scripts/validate-pack.py` (general) | **0** | `PASSED — all checks clean` |
| `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` (deep) | **0** | `PASSED — all checks clean` |

### 3.2 Full wired CI battery (every `run: bash …` step in `.github/workflows/validate-pack.yml`'s `tests` job — 63 steps, NOT sampled)
All exit **0**. Run in yml order, fixture-dependent tests after `build.sh
--all --clean`:

- `scripts/test-detect.sh` → 0
- `scripts/tests/tracker-provider-test.sh` → 0
- `scripts/tests/tracker-config-test.sh` → 0
- `scripts/tests/tracker-init-test.sh` → 0
- `scripts/tests/tracker-agent-read-test.sh` → 0
- `scripts/tests/tracker-migrate-forward-test.sh` → 0 (heavy ~61 s)
- `scripts/tests/tracker-migrate-reverse-test.sh` → 0
- `scripts/tests/tracker-migrate-roundtrip-test.sh` → 0
- `scripts/tests/test-tracker-phase-task.sh` → 0
- `scripts/tests/test-tracker-links.sh` → 0
- `scripts/tests/test-tracker-cycle-check.sh` → 0
- `scripts/tests/tracker-errors-test.sh` → 0
- `scripts/tests/tracker-config-schema-test.sh` → 0
- `scripts/tests/recommendation-state-schema-test.sh` → 0
- `scripts/tests/test-per-entry.sh` → 0
- `scripts/tests/test-validate-pack-checks-32-33-34.sh` → 0
- `scripts/tests/test-validate-pack-checks-36-37-38.sh` → 0
- `scripts/tests/test-validate-pack-check-39.sh` → 0
- `scripts/tests/test-validate-pack-check-40.sh` → 0
- `scripts/tests/test-validate-pack-check-41.sh` → 0
- `scripts/tests/test-validate-pack-check-18.sh` → 0
- `scripts/tests/test-validate-pack-check-16.sh` → 0
- `scripts/tests/test-validate-pack-check-19.sh` → 0
- `scripts/tests/test-validate-pack-check-42.sh` → 0
- `scripts/tests/test-validate-pack-check-43.sh` → 0
- `scripts/tests/test-validate-pack-check-44.sh` → 0
- `scripts/tests/test-validate-pack-check-45.sh` → 0
- `scripts/tests/test-validate-pack-check-46.sh` → 0
- `scripts/tests/test-validate-pack-check-removed-doc-advisory.sh` → 0
- `scripts/tests/test-validate-pack-check-49-field-faithfulness.sh` → 0
- `scripts/tests/test-validate-pack-check-50-codec-single-source.sh` → 0
- `scripts/tests/test-validate-pack-check-51-flip-block.sh` → 0
- `scripts/tests/test-validate-pack-check-52.sh` → 0
- `scripts/tests/test-validate-pack-check-53.sh` → 0
- `scripts/tests/test-validate-pack-check-56.sh` → 0
- `scripts/tests/test-validate-pack-check-55.sh` → 0
- `scripts/tests/test-validate-pack-check-57.sh` → 0
- `scripts/tests/test-validate-pack-check-54.sh` → 0
- `scripts/tests/tracker-deferral-gate-test.sh` → 0
- `scripts/tests/tracker-bd129-gh-repo-test.sh` → 0
- `scripts/tests/tracker-bd130-doctor-wired-test.sh` → 0
- `scripts/tests/tracker-bd132-race-test.sh` → 0
- `scripts/tests/tracker-bd133-header-preservation-test.sh` → 0
- `scripts/tests/tracker-bd134-close-retry-test.sh` → 0
- `scripts/tests/recommendation-test.sh` → 0
- `scripts/tests/pack-help-test.sh` → 0
- `scripts/tests/test-customization-preserve.sh` → 0
- `scripts/tests/test-init-project.sh` → 0
- `scripts/tests/test-migrate-v10-to-v11.sh` → 0
- `scripts/tests/test-migrate-v10-to-v11-dry-run.sh` → 0
- `scripts/tests/test-migrate-v10-to-v11-gates.sh` → 0 (heavy ~94 s long-pole)
- `scripts/tests/test-migrate-v10-to-v11-decompose.sh` → 0
- `scripts/test-migrator-core.sh` → 0
- `scripts/test-migrator-manifest.sh` → 0
- `scripts/test-migrator-capability-translation.sh` → 0
- `test-fixtures/build.sh --all --clean` → 0
- (yml manifest-restore `git checkout HEAD -- test-fixtures/manifest.txt` —
  **SKIPPED locally**: it is a state-changing git verb forbidden by
  agents-never-commit; the local fixtures are freshly built so `--verify`
  passes against them, and the committed manifest is unchanged. The CI runner
  runs this restore; the orchestrator/CI is the authoritative gate for the
  BD-118 tautology nuance.)
- `test-fixtures/build.sh --verify` → 0
- `scripts/tests/test-v11-realistic-ot.sh` → 0
- `scripts/test-migrator-skills.sh` → 0
- `scripts/test-persona-contracts.sh` → 0
- `scripts/tests/template-translations-test.sh` → 0
- `scripts/tests/template-version-test.sh` → 0
- `scripts/tests/test-issue-forms.sh` → 0

### 3.3 EFFECTIVENESS-PRESERVATION proofs

**(P1) No-flag full run is byte-identical behavior.** Compared the new no-flag
run's ORDERED banner sequence against the HEAD baseline (`git show
HEAD:scripts/validate-pack.py`, run with REPO_ROOT correctly resolved):
- baseline `── Check` banner count = **56**; new = **56**.
- `diff` of the ordered banner sequence (baseline vs new) → **IDENTICAL CHECK
  SEQUENCE (order + banners preserved)**.
- new no-flag run verdict = `PASSED — all checks clean`, exit 0.
(The 57 registry entries → 56 banner lines because Checks 16/18/19 each emit a
`Check N [surface]` line twice but the `── Check N ──` heading style varies, and
2 checks are unnumbered `── Check:`; the EXECUTION set is identical to the 57
prior callsites — registry length 57, confirmed.)

**(P2) `--only-check` smoke + selector semantics.**
| Invocation | Exit | Observed |
|---|---|---|
| `--only-check 52` | 0 | 1 check banner; `Check 52:` present; `PASSED`; single-check notice printed |
| `--only-check 18` (dual-entry) | 0 | `(--only-check 18: running 2 selected check(s): check_trinity_h2_parity[project-template], check_trinity_h2_parity[pack-root])`; BOTH surface banners present |
| `--only-check check_pack_rw_ro_two_class` (label) | 0 | Check 52 ran |
| `--only-check 9999` (unknown number) | 1 | `FAIL: --only-check: unknown selector '9999' …`; `FAILED — 1 issue(s) found` |
| `--only-check bogus_label` (unknown label) | 1 | `FAIL: --only-check: unknown selector 'bogus_label' …`; `FAILED — 1 issue(s) found` |

**(P3) MUTATION proof — `--only-check NN` still catches its check's regression
(2 representative checks, plan-named 52 + 40).** For each: inserted a throwaway
`fail("MUTATION-PROOF-…")` right after the check's banner, ran `--only-check NN`
+ the per-check test, then REVERTED. Post-revert residue grep = 0;
validate-pack PASSES clean.

- Check 52 mutated: `python3 scripts/validate-pack.py --only-check 52` →
  **exit 1**, `FAIL: MUTATION-PROOF-C1-52 …`. Per-check test
  `test-validate-pack-check-52.sh` → **exit 1** (2 FAILs).
- Check 40 mutated: `python3 scripts/validate-pack.py --only-check 40` →
  **exit 1**, `FAIL: MUTATION-PROOF-C1-40 …`. Per-check test
  `test-validate-pack-check-40.sh` → **exit 1** (2 FAILs).
- Post-revert: `grep -c MUTATION-PROOF scripts/validate-pack.py` → **0**;
  `python3 scripts/validate-pack.py` → exit 0, `PASSED — all checks clean`.

**(P4) In-process `mod.main()` (the §4.7 runtime-budget test's full-run +
total-run-budget driver) preserved.** `test-validate-pack-check-49-field-
faithfulness.sh` Group 4(b) calls `mod.main()` with NO args and expects the
TOTAL-RUN hard-FAIL to fire on a synthetic 999 s check. That test → **exit 0
(PASS)** under the refactor: `main(only_check=None)` runs the full registry and
enforces the total-run budget exactly as before.

**(P5) enumerate-encoding-surfaces.** I changed NO existing banner or printed
verdict text (the `── Check N:` banners and `PASSED — all checks clean` /
`FAILED — N issue(s)` verdicts are byte-identical). The NEW C1 output strings
(single-check notice, selected-check line, `unknown selector`, total-run N/A
notice) are asserted by NO test: `grep -rE 'single-check mode|selected
check\(s\)|unknown selector|total-run budget N/A' scripts/tests/ scripts/test*.sh`
→ **(NONE)**. No lock-step test update needed.

**(P6) Per-check WARN budget stays active in single-check mode; total-run
suppressed.** The dispatch loop calls `run_check(label, fn, budget_s=budget_s)`
for selected entries (per-check WARN live); the total-run block is gated behind
`if only_check is None:` (suppressed for single-check; LIVE for the no-flag full
run). The six existing runtime guards (EE-P9) are preserved verbatim (constants
448–457 untouched; `run_check` body untouched).

---

## 4. PLAN DEVIATIONS

**One deliberate, scope-protecting deviation (surfaced, not absorbed):**

The plan §C1 item 2 says "Change EACH e2e subprocess … to `--only-check NN`."
Taken literally that would also narrow the **`test-validate-pack-checks-36-37-38.sh`
Group 4 leg** (line ~398: `python3 …/validate-pack.py` asserting
`"validate-pack.py exits 0 with all checks including 36/37/38 on HEAD"`). That
leg is a **deliberate FULL-RUN exit-0 assertion** — its `t_pass` text and intent
prove the WHOLE run passes, not just one check. Narrowing it to `--only-check 36`
would **WEAKEN** it (it would stop proving the full run passes), violating the
plan's own §C1 "Preserve ALL THREE assertions verbatim … Do NOT delete or weaken
any assertion" hard constraint and the no-weakening effectiveness constraint.

**Resolution (consistent with BOTH plan clauses + `scope-deliverables-to-the-ask`):**
- The `36-37-38` G6.T11/T12 leg (the one that explicitly says "run Check 37 via
  validate-pack.py" and asserts Check 37's success message) → adopted
  `--only-check 37` (its genuine per-check target).
- The `36-37-38` Group 4 full-run exit-0 leg → **LEFT AS A FULL RUN** (a distinct,
  non-redundant assertion that the whole run is green; narrowing it loses
  coverage).
- `test-validate-pack-checks-32-33-34.sh` → no full-validate-pack subprocess e2e
  leg exists (module-import only), so nothing to adopt.

This yields **23 `--only-check` adoptions** across 22 test files (matching the
plan's "~23"), with zero assertion weakening beyond the by-design,
restored-by-C3 wiring-proof move. **No other deviation.** No design decision was
relitigated; no file outside the C1 scope was edited; no C2/C3/C4 scope was
started.

---

## 5. NEW POQs INTRODUCED

None. (The wiring-proof-until-C3 gap is the design's own ordered C1→C3 sequence,
already documented in the plan §3 + design §3.4/§6.4 — not a new open question.)

---

## 6. DEFINITION-OF-DONE CHECKLIST

| Item | Status | Evidence |
|---|---|---|
| `--only-check <N\|NAME>` argparse mode added (greenfield; no-flag = run ALL, byte-identical) | **PASS** | §2 A; P1 (identical banner sequence); P2 |
| `CHECK_REGISTRY` refactor (single dispatch source) | **PASS** | `_build_check_registry()` 57 entries; §2 A |
| Total-run-budget suppression in single-check mode; per-check WARN stays; no-flag keeps total-run LIVE | **PASS** | §2 A; P6; total-run block gated `if only_check is None:` |
| `--only-check` adopted in per-check e2e legs (~23) WITHOUT weakening assertions | **PASS** | §2 C; 23 adoptions; §4 deviation (no weakening) |
| 3 stale "Check 54 reserved" comments stripped (no renumber; no impl touch) | **PASS** | §2 B; post-edit re-grep clean |
| Manifest regen run + checked; staged iff non-empty | **PASS** | §2 D; diff EMPTY → not staged |
| No C2/C3/C4 scope; no new Check; no new file | **PASS** | §1 (0 new files); no registry-completeness/full-run/shard guard added |
| No-flag full run still runs ALL checks | **PASS** | P1 (identical sequence); registry length 57 |
| Each per-check test still catches its check's regression under the flag (mutation-proven, ≥2 checks) | **PASS** | P3 (Check 52 + Check 40) |
| In-process `mod.main()` full-run + total-run-budget behavior preserved | **PASS** | P4 (check-49 Group 4 → PASS) |
| `python3 scripts/validate-pack.py` exit 0, all clean | **PASS** | §3.1 |
| `PACK_VALIDATE_DEEP=1 …` exit 0 | **PASS** | §3.1 |
| FULL wired battery (63 steps) each exit 0 (not sampled) | **PASS** | §3.2 |
| enumerate-encoding-surfaces (no banner/verdict change; new strings unasserted) | **PASS** | P5 |
| HEAD unchanged (f140c48); no state-changing git verb | **PASS** | §0 |
| edit-in-place (no full rewrite; all comment blocks carried) | **PASS** | §2 A; targeted Edits only |

**DoD: ALL PASS.**

---

## 7. KEY EDIT — `scripts/validate-pack.py` dispatch (load-bearing new code)

The selector resolution + dispatch (the contract a reviewer must check):

```python
def _resolve_only_check(registry, selector):
    matches = []
    if selector.isdigit():
        want = int(selector)
        matches = [e for e in registry if e[0] == want]
    if not matches:
        matches = [e for e in registry if e[1] == selector]
    return matches

def main(only_check=None) -> None:
    ...
    registry = _build_check_registry()
    if only_check is None:
        selected = registry
    else:
        selected = _resolve_only_check(registry, only_check)
        if not selected:
            fail(f"--only-check: unknown selector '{only_check}' — ...")
            print(...); print("FAILED — ..."); sys.exit(1)
        ...
    for number, label, fn, budget_s in selected:
        run_check(label, fn, budget_s=budget_s)
    if only_check is None:
        total_elapsed = sum(...); deep = ...; total_budget = ...
        if total_elapsed > total_budget: fail("RUNTIME-BUDGET: validate-pack total ...")
    else:
        print("(total-run budget N/A in single-check mode; per-check WARN budget stays active)")
    ...

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(...)
    parser.add_argument("--only-check", metavar="N|LABEL", default=None, help=...)
    args = parser.parse_args()
    main(only_check=args.only_check)
```

(The `expected_count` mentioned in the plan/design §6.4 is a **C3** concern — C1
adds NO hard-coded count constant. The registry length is computed at runtime,
never literal `57`.)

---

## 8. RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted / measured) | Conclusion |
|---|---|---|
| **agents-never-commit** | Only read-only git verbs run: `git rev-parse HEAD/--show-toplevel/--abbrev-ref`, `git status --short`, `git diff [--stat\|--quiet\|HEAD]`, `git show HEAD:scripts/validate-pack.py`. NO add/stage/commit/push/checkout/restore/reset/apply/etc. HEAD start == end == `f140c48`. The yml manifest-restore `git checkout HEAD -- …` was NOT run (forbidden verb) — noted §3.2. Patch emitted via read-only `git diff HEAD > /tmp/handoff-bd219-c1/c1.patch`. | COMPLIANT |
| **edit-in-place-not-full-rewrite** | `scripts/validate-pack.py` edited via 3 targeted Edits (signature+registry-head, registry-tail+dispatch, then 2 throwaway-mutation Edits both reverted) — never a wholesale Write. Every inline landing-rationale comment block carried verbatim into the registry (BD-183/181/168/175/179/180/196/195/204/214/197). Test files edited one e2e-leg line each. Re-read/verified changed regions; `git diff --stat` = 23 files, +400/−285. | COMPLIANT |
| **architect-doc-reality-reconciliation** | Comment strips + the registry numbers reference checks by banner text/symbol, NEVER line numbers. The §6.4 `expected_count` is NOT introduced in C1 (it is C3); the registry length is computed at runtime (`len(registry)` via iteration), never a literal `57`. The 3 reserved-comment sites located by `reserved`-grep, not line number. | COMPLIANT |
| **regenerate-manifest-v11-surface** | C1 touches `scripts/` → ran `bash test-fixtures/build.sh --all --clean` (exit 0); `git status --short test-fixtures/manifest.txt` → empty; `git diff --quiet test-fixtures/manifest.txt` → empty. Manifest diff EMPTY → NOT staged (correct; C1 changes no fixture SHA). | COMPLIANT |
| **verify-full-ci-suite** | Ran general + deep validate-pack (exit 0/0) AND every one of the 63 `run: bash …` steps in `.github/workflows/validate-pack.yml`'s `tests` job (extracted via `grep -E '^\s+run: bash '`), each quoted exit 0 — NOT a sample (§3.2). Includes the heavy long poles (gates ~94 s exit 0; tracker-migrate-forward ~61 s exit 0) + the fixture-dependent group after `build.sh --all --clean`. | COMPLIANT |
| **ci-check-runtime-compounding** | No new check added (C1 = mechanism + comment strips only). Total-run budget suppressed ONLY in single-check mode (`if only_check is None:` gate); per-check WARN budget stays active via `run_check(..., budget_s=budget_s)`. Six existing runtime guards (constants 448–457 + `run_check` body + deep ENV-gate) preserved verbatim — untouched in the diff. P6. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Delivered exactly C1: `--only-check` + registry + total-run suppression + 23 e2e-leg adoptions + 3 comment strips + manifest check. NO C3 guard (registry-completeness / full-run-no-flag / generalized Check 42), NO new Check, NO new file. The one full-run leg that the literal "each e2e leg" reading would have weakened was SURFACED (§4), not silently narrowed or silently left — explained against both plan clauses. | COMPLIANT |
| **preflight-stop-means-stop** | Emitted the single PREFLIGHT line ONLY after all edits + full battery + manifest check PASSED (general 0, deep 0, battery all 0; REGIME=isolated; HEAD f140c48; patch+report to /tmp/handoff-bd219-c1/). No partial report. No parent stop/halt message received. | COMPLIANT |
| **rules-applied-verification-block** | This table — per-rule, quoted/measured evidence (commands, exits, grep results, diff stats), terminal COMPLIANT conclusion; no empty evidence; no AMBIGUOUS. | COMPLIANT |
