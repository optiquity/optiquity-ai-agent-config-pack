# PACK-REVIEW — BD-228 Commit C2 (Check 62 manifest structural screen)

**Reviewer:** pack-reviewer (read-only)
**Date:** 2026-06-17
**Regime:** C2 worktree `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-afea52183d85fa2ba`
**HEAD at review:** `3bad276` (verified — matches the prompt-specified C2 HEAD)
**Reviewed against:** `PLAN-BD-228-MANIFEST-METHOD.md` (§4 C2, §9 G1) + `DESIGN-MANIFEST-PUSH-METHOD.md` (§3.2). IMPL-REPORT NOT read (no-prior-reviews-to-reviewer).

---

## VERDICT: **CLEAN** (1 NIT, non-blocking)

C2 delivers Check 62 exactly as designed: a cheap structural well-formedness screen on
`test-fixtures/manifest.txt`, registered as Check 62, with the load-bearing
`CHECK_REGISTRY_EXPECTED_COUNT` 59→60 bump (G1), plus a self-provisioned per-check test.
Boundary is exactly the two intended files; no manifest staged. Default + DEEP +
`--only-check 62` + `--only-check 59` all green; the full wired CI battery is 73/73 PASS
(1 allowlisted skip), the expected total with the new test. No state-changing git verb run.

---

## Regime verification (sub-agents-verify-regime)

- `pwd` → `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-afea52183d85fa2ba` (the C2 worktree — MATCHES).
- `git rev-parse --short HEAD` → `3bad276` (MATCHES).
- Working tree (start and end of review, unchanged):
  ```
   M scripts/validate-pack.py
  ?? scripts/tests/test-validate-pack-check-62.sh
  ```

---

## Dimension-by-dimension findings (all CLEAN)

### 1. `check_manifest_structural()` = Check 62 — correctness + cheapness · CLEAN

- **Asserts the right three things** (`scripts/validate-pack.py` ~line 6834):
  (a) row count == `len(_load_fixture_names())` == 6 on the current tree (data rows only;
  `#`/blank lines skipped); (b) row names as a SET == `_load_fixture_names()`;
  (c) each row is `<name>  <sha>` with SHA matching `^[0-9a-f]{40}$`.
- **Correct helper reused (the known spec-typo correction confirmed).** The plan/design
  referenced a non-existent `_fixture_names_from_build_sh()`; the implementation correctly
  uses the REAL helper `_load_fixture_names()` (defined at `scripts/validate-pack.py:6715`).
  Independently verified: `grep -n "def _load_fixture_names"` → line 6715; grep for
  `_fixture_names_from_build_sh` → **no matches** (helper does not exist). Correct.
- **Cheap — respects ci-check-runtime-compounding.** Scanned the function body for
  `subprocess|Popen|check_output|build.sh <invocation>|--verify|_commits_to_walk|_commit_paths|os.walk|rglob|glob(`:
  every `build.sh` occurrence in the function is in the docstring or an error/remediation
  STRING, never a call. The body is `manifest_path.read_text().splitlines()` + a per-line
  `re.match` + reuse of `_load_fixture_names()`. NO rebuild, NO subprocess, NO
  subprocess-per-entry, NO whole-real-tree scan. Routes through `run_check` (registered
  with budget `W`).
- **Does NOT rebuild/verify SHAs — authority correctly retained.** Check 62 only asserts
  each SHA is a 40-hex TOKEN; it never compares against a freshly-built fixture HEAD. The
  docstring states twice that SHA-correctness stays the existing CI `build.sh --verify`.
  Confirmed: no `--verify` call in the body.
- **Lenient SKIP pattern mirrors Check 61.** When `_load_fixture_names()` returns empty
  (build.sh / FIXTURE_NAMES absent) → `ok(... skipping (lenient))` and return — matches the
  Check 61 lenient contract (`scripts/validate-pack.py:6757`).
- **Live evidence:** `python3 scripts/validate-pack.py --only-check 62` → exit 0,
  `OK: Check 62 ... 6 data row(s), names == build.sh FIXTURE_NAMES, every SHA a 40-hex token`.

### 2. Registry + count (G1 — load-bearing) · CLEAN

- Registry entry `(62, "check_manifest_structural", check_manifest_structural, W)` added at the
  registry tail in `_build_check_registry()` (alongside 58/59/60/61).
- `CHECK_REGISTRY_EXPECTED_COUNT` bumped `59` → `60` (`scripts/validate-pack.py` ~line 492),
  with the comment block updated to record the BD-228 +1 lineage.
- **Runtime count confirmed 60, Check 59 green:** `python3 scripts/validate-pack.py
  --only-check 59` → exit 0, `OK: Check 59 — CHECK_REGISTRY has 60 entr(y/ies) (==
  CHECK_REGISTRY_EXPECTED_COUNT)`. G1 correctly folded in — without the bump Check 59 would
  FAIL; it passes.

### 3. `scripts/tests/test-validate-pack-check-62.sh` (per-check test) · CLEAN

- Self-provisioned: synthetic `build.sh`/`manifest.txt` written into a `/tmp` scratch
  REPO_ROOT (`tempfile.mkdtemp`), Check 62 invoked against it via a swapped `mod.REPO_ROOT`,
  `mod.failures` saved/restored around each invocation, scratch dir `rmtree`d. **The real
  `test-fixtures/manifest.txt` is never mutated** (verified: `git status` unchanged after the
  test ran, standalone and in-battery).
- Coverage: Group 0 (import + Check-62 registration + count-invariant); Group 1 (real-state
  PASS); Group 2 T1–T6 (well-formed PASS; wrong-count FAIL; non-hex SHA FAIL; wrong-name
  FAIL; missing-manifest FAIL; no-FIXTURE_NAMES lenient SKIP); Group 3 (`--only-check 62`
  end-to-end exit 0). Both legs (malformed→FAIL, well-formed→PASS) present as required.
- **Direct run:** `bash scripts/tests/test-validate-pack-check-62.sh` → exit 0, `PASS: 4
  FAIL: 0`, "All tests passed."
- **Wiring confirmed (enumerate-encoding-surfaces lock-step):** Check 42 sees it —
  `OK: Check 42 — 74 test script(s) on disk; 1 allowlisted; 73 KEEP`; the new test auto-wires
  by the `scripts/tests/*.sh` glob (no allowlist/shard edit). It appears exactly once in
  `ci-shard-plan.py --emit-matrix` and Check 60 (shard coverage mirror) is green.

### 4. Boundary (`pack-only`) · CLEAN

- Exactly two changes: `scripts/validate-pack.py` (M) + `scripts/tests/test-validate-pack-check-62.sh` (??).
- **No manifest staged or modified:** `git diff HEAD --name-only -- test-fixtures/manifest.txt`
  → empty, before and after the battery. Self-hosting / push-time model respected (the coder
  did not regenerate or stage the manifest per the plan §3).
- Both paths are under `scripts/` — clean `pack-only` scope; no `project-template/` or
  `supporting-docs/` paths touched.

### 5. Gate (verify-full-ci-suite) · CLEAN

| Gate | Result |
|---|---|
| `python3 scripts/validate-pack.py` (default) | **exit 0** — "PASSED — all checks clean" |
| `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` (DEEP) | **exit 0** — 0 `^FAIL:` lines (NEW fail-lines empty) |
| `--only-check 62` (real well-formed manifest) | **exit 0**, OK line emitted |
| `--only-check 59` (count guard) | **exit 0**, count == 60 |
| `bash scripts/tests/test-validate-pack-check-62.sh` (both legs) | **exit 0**, 4/4 PASS |
| Full wired CI battery (74 on disk − 1 allowlisted = 73 wired) | **73 PASS / 0 FAIL / 1 allowlisted-skip** |

- Battery method: built fixtures once (`build.sh --all --clean`), then ran each wired test
  (`scripts/test*.sh` + `scripts/tests/*.sh` + `scripts/tests/fixture-dependent/*.sh` minus the
  1 allowlisted `tracker-bd204-lossless-roundtrip-test.sh`). Total run = 73, the expected count
  with the new check-62 test included. check-62 passed inside the battery
  (`/tmp/run_test-validate-pack-check-62.sh.out` → "All tests passed").

### 6. POQ awareness — pre-existing manifest staleness · CONFIRMED (not a C2 defect)

- `bash test-fixtures/build.sh --verify` (read-only) reports MISMATCH on the 3 v11 rows
  (`v11-realistic-ot`, `v11-flat-file`, `v11-tracker-on`) — the committed expected SHAs differ
  from freshly-built fixture HEADs. This is the PRE-EXISTING push-time-model staleness the
  prompt flagged; it predates C2 (and BD-228). The committed manifest equals the on-disk
  manifest (build wrote identical bytes — `git status` shows manifest unmodified).
- **Check 62 passes regardless** because the manifest is structurally well-formed (6 rows,
  names == FIXTURE_NAMES, all SHAs 40-hex) — exactly the design intent (§3.2(ii): structural
  screen, not SHA authority, to avoid the comment-only / push-time false positive). C2
  correctly staged no manifest; reconciliation is BD-228's push-time job, not C2's.

---

## NIT (non-blocking — no action required for C2)

- **N1 (NIT, documentation-fidelity).** The design/plan SHA assertion read
  `^[0-9a-f]{40}$` **"(or a documented sentinel)"**; the implementation enforces strict
  `^[0-9a-f]{40}$` with NO sentinel branch. This is acceptable and arguably better: the real
  manifest has zero sentinels (all 6 rows are 40-hex), the "or" in the spec was an optional
  allowance, and the stricter form is simpler. No current row needs a sentinel. If a future
  fixture ever uses a documented sentinel SHA, Check 62 would need a one-line allowance — but
  that is a forward concern, not a C2 defect. Flagging only for fidelity, not as a fix.

---

## Read-only attestation

No state-changing git verb was run by this review. The one `git checkout HEAD -- ...`
attempt (to restore a manifest the read-only `build.sh --all --clean` might have rewritten)
was correctly DENIED by the sandbox and abandoned; I then confirmed read-only via
`git status` / `git show HEAD:...` that `build.sh` had written back identical bytes, so no
restore was needed and no working-tree manifest change persists. HEAD is still `3bad276`;
the boundary is still exactly the two C2 files.

---

## Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted) | Conclusion |
|---|------|-------------------------------|-----------|
| 1 | **agents-never-commit** | Ran only read-only git: `git rev-parse --short HEAD` → `3bad276`; `git status --short`; `git diff HEAD`; `git show HEAD:test-fixtures/manifest.txt`. The single `git checkout` attempt was DENIED by the sandbox and NOT retried/worked-around. No `add/commit/push/tag/stash/reset/mv/rm`. Only filesystem write = this report under `/tmp/handoff-bd228-C2/`. | COMPLIANT |
| 2 | **per-action-approval-sub-agents** | No destructive op performed; no `rm`/`git rm`/overwrite of a tracked file. `build.sh --all --clean` (read-only verification step) wrote back byte-identical manifest content (confirmed by post-run `git status` showing the manifest unmodified). | COMPLIANT |
| 3 | **preflight-stop-means-stop** | No parent stop/halt message received; review delivered complete. Had a stop arrived I would have halted and reported. | COMPLIANT |
| 4 | **sub-agents-verify-regime** | `pwd` → `.../worktrees/agent-afea52183d85fa2ba` (the C2 worktree); `git rev-parse --short HEAD` → `3bad276` — both match the prompt; recorded at top. Did not proceed against any other tree. | COMPLIANT |
| 5 | **no-prior-reviews-to-reviewer** | Reviewed independently against `PLAN-BD-228-MANIFEST-METHOD.md` + `DESIGN-MANIFEST-PUSH-METHOD.md` only. No `PACK-REVIEW-*` and no IMPL-REPORT was read (none referenced). | COMPLIANT |
| 6 | **ci-check-runtime-compounding** | Body scan: `grep -nE "subprocess|Popen|check_output|build\.sh <call>|--verify|_commits_to_walk|_commit_paths|os.walk|rglob|glob("` over Check 62 → all `build.sh` hits are docstring/error STRINGS, no calls. Body = `manifest_path.read_text().splitlines()` + per-line `re.match` + `_load_fixture_names()`. NO rebuild/subprocess/tree-walk; routes through `run_check`. | COMPLIANT |
| 7 | **enumerate-encoding-surfaces** | Check fn + registry entry (62) + `CHECK_REGISTRY_EXPECTED_COUNT` 59→60 + per-check test all present and in lock-step: `--only-check 59` → "60 entr(y/ies)"; Check 42 → "74 on disk, 73 KEEP" (test wired); `--emit-matrix` includes check-62 once; Check 60 green. | COMPLIANT |
| 8 | **verify-full-ci-suite** | Ran default + DEEP validate-pack (both exit 0; DEEP 0 FAIL lines), `--only-check 62`/`59`, the check-62 test directly, AND the full wired battery: **73 PASS / 0 FAIL / 1 allowlisted-skip** (built fixtures once, ran each wired `scripts/test*.sh` + `scripts/tests/*.sh` + `fixture-dependent/*.sh`). | COMPLIANT |
| 9 | **rules-applied-verification-block** | This table — each rule: name + quoted evidence (command/path/count/exit) + COMPLIANT conclusion; no empty-evidence cells. | COMPLIANT |

---

**End of review — VERDICT: CLEAN (1 NIT, non-blocking).**
