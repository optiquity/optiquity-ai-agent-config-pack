# IMPL-REPORT — BD-204 C-4.6 (CI faithfulness guard, Option B: single-source batch codec) + run_check runtime-budget guard

**Agent:** pack-coder
**Branch:** v11-dev
**Worktree base HEAD (pre-flight + final, no commits — agents never commit):**
`f89ade57fe5ecf99c532adbe0ce511cbd81edf30`
**Scope keyword:** `pack-only` (`scripts/` + `.github/workflows/` only — NO `project-template/`, NO `supporting-docs/`, NO `maintenance-docs/` source edits).
**Recipe implemented:** PLAN-BD-204.md §3.LF.5 (EXACTLY). Design: ARCHITECTURE-BD-204-LOSSLESS-FIX.md §4.5 / §4.6 / §4.6.2 / §4.6.3 / §4.7 / §3.3c / §3.3e.

---

## Files changed (inventory)

| Path | Change type | Line delta |
|---|---|---|
| `scripts/validate-pack.py` | modified | +552 / −48 (net per `git diff --stat`; new check 49 + check 50 + `run_check` harness + `main()` rewrap + total-run guard) |
| `.github/workflows/validate-pack.yml` | modified | +10 (general DEEP step + per-check test wiring) |
| `scripts/tests/test-validate-pack-check-49-field-faithfulness.sh` | **new** | full file (filename verified unique pre-naming) |
| `test-fixtures/manifest.txt` | NOT staged | manifest regen ran (`bash test-fixtures/build.sh --all --clean`, exit 0); diff EMPTY → nothing to stage (the new test/script are not manifest-tracked fixtures) |

`git status --short` at completion:
```
 M .github/workflows/validate-pack.yml
 M scripts/validate-pack.py
?? scripts/tests/test-validate-pack-check-49-field-faithfulness.sh
```

---

## Per-task summary

### scripts/validate-pack.py

1. **`run_check(name, fn, budget_s)` TIMING HARNESS (§4.7).** Added after the `warn()` helper. Times every wrapped check (`time.monotonic()`), records `(name, elapsed)` in a module-level `_check_timings`, and emits a LOUD per-check WARN on a per-check budget overrun (`RUNTIME-BUDGET: check '<name>' took <e>s > budget <b>s`). Constants: `RUN_CHECK_PER_CHECK_WARN_BUDGET_S = 2.0`, `RUN_CHECK_TOTAL_GENERAL_BUDGET_S = 10.0`, `RUN_CHECK_TOTAL_DEEP_BUDGET_S = 35.0`. Added `import time`.
2. **`main()` routes EVERY check through `run_check`** (mechanical wrap of the existing flat call list; arg-bearing trinity checks 16/18/19 wrapped in named lambdas so the timing label stays meaningful). Added the TOTAL-RUN hard-FAIL at the end of `main()`: `total_elapsed = sum(...)`; budget = deep-budget if `PACK_VALIDATE_DEEP=1` else 10 s; over budget → `fail("RUNTIME-BUDGET: validate-pack total ...")`. **The 10 s total is GENERAL-PATH-ONLY** (a deep run gets the 35 s budget so a legitimate deep run is never falsely failed).
3. **NEW `check_migrator_field_faithfulness(tree_dir)` (Check 49 — next free registry integer; highest existing banner was Check 48 → 49).** Registered in `main()` with the caller passing the REAL `REPO_ROOT/"backlog"` as the explicit target (the lambda). The check body itself has **NO** `tree_dir or REPO_ROOT/"backlog"` fallback.
4. **NEW `check_validate_pack_no_reproduced_codec()` (Check 50 — the §4.5 OQ-4 single-source guard).** Scans validate-pack.py's OWN Python source; FAILs if a reproduced gz64/base64 codec (`import gzip`/`base64`, `gzip.GzipFile`/`compress`/`decompress`, `base64.b64encode`/`b64decode`) appears OUTSIDE the bash-seam string literal / comments / its own token-declaration tuple. Registered in `main()` immediately after Check 49.
5. **No codec REPRODUCTION exists to delete** — the worktree base (f89ade5) is clean (the C-4.6 revert-#2 reproduction was already reverted pre-task; `git status` clean at pre-flight). The guard CALLS the shared batch codec; there is no second copy to remove.

### .github/workflows/validate-pack.yml — BOTH deep homes

- **(a) Per-check test wired (MANDATORY — Check 42-enforced):** a `tests:`-job step `bash scripts/tests/test-validate-pack-check-49-field-faithfulness.sh`. The per-check test sets `PACK_VALIDATE_DEEP=1` internally and runs the deep check on the real ≥211 tree.
- **(b) Dedicated DEEP step (SHOULD-1):** a `validate:`-job step `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` running the deep check ONCE on the real `/backlog/` per push. The existing general `validate` step stays env-UNSET (default-SKIP).

### scripts/tests/test-validate-pack-check-49-field-faithfulness.sh (new)

7 test groups: import/symbols; POSITIVE deep run on real ≥211 tree + general-path-SKIP confirmation; synthetic NEGATIVE legs (CR byte-leg-b + R-BODY-6 / NUL R-BODY-6 / size over-budget / over-title) on small scratch trees passed as the check's `tree_dir` (proving target-tree scoping); §4.5 single-source teeth (injected reproduced codec FAILS Check 50, clean source PASSES); §4.7 runtime-budget (per-check WARN-not-FAIL + total-run hard-FAIL via `main()`, exercised with a fake monotonic clock — no real sleep); §4.6(T) no-fallback body scan.

---

## The 7 HARD-CONSTRAINT attestations (with evidence)

### 1. SEAM = THE SHARED BATCH CODEC (no Python reproduction; OQ-4 real)

The deep leg's seam (`_CHECK_49_SEAM_SCRIPT`) sources the migrator libs ONCE and drives the C-4.5-addendum batch functions — ONE `python3` over all entries each — quoting the call sites:
```
tmf_parse_backlog_tree "$TREE_KEY" "$TREE_DIR" > "$OUTDIR/tree.json" || exit 11
_tmf_gz64_encode_batch     < "$OUTDIR/raw.frame" > "$OUTDIR/enc.frame" || exit 12
_tmr_decode_body_blob_batch < "$OUTDIR/enc.frame" > "$OUTDIR/dec.frame" || exit 13
python3 - "$OUTDIR/tree.json" <<'PY' | tmf_compose_issue_body_batch > "$OUTDIR/composed.frame" || exit 14
```
Evidence the seam's inner python does NO codec transform (only length-framing + JSON read):
```
codec tokens inside seam python: []
seam calls shared batch fns: True
```
Evidence ZERO bare gzip/base64 transform tokens anywhere in validate-pack.py's executable Python:
`grep -nE "gzip\.|base64\.|import gzip|import base64" scripts/validate-pack.py | grep -vE '^\s*#|"import|"gzip|"base64|# '` → **(empty)**.
The guard does NOT invoke `tracker_migrate_reverse_reconstruct` / `_tmr_emit_pack_tree` (the LABEL/H2 projection, separately tested per §4.6.3).

### 2. ENV-GATE is the FIRST statement (general path ~0 ms)

The FIRST executable line of `check_migrator_field_faithfulness` is:
```python
if os.environ.get("PACK_VALIDATE_DEEP") != "1":
    ok("SKIP: field-faithfulness deep check (set PACK_VALIDATE_DEEP=1)")
    return
```
— BEFORE any tree read. Measured general run = **1.35 s** (deep SKIPPED), identical to baseline.

### 3. TARGET-TREE SCOPING (no fallback)

`tree_path = Path(tree_dir)` — the caller's target, used directly. There is NO `tree_dir or REPO_ROOT/"backlog"` and NO `REPO_ROOT/"backlog"` inside the check body. The caller in `main()` passes the real tree as the EXPLICIT target via `lambda: check_migrator_field_faithfulness(REPO_ROOT / "backlog")` (that is the caller choosing the target — the §4.6(T) ban is on an internal `or` fallback, which is absent). Group 5 of the per-check test body-scans the executable check body (docstring/comments stripped) and asserts neither forbidden shape is present → PASS.

### 4. BYTE LEG = §4.6.2 EXACTLY (two assertions, NOT the tautology)

- **(a) CODEC-LOSSLESS** `decode(encode(raw_body)) == raw_body`: `decoded[idx] != raw_body` → FAIL. Driven by the shared `_tmf_gz64_encode_batch` → `_tmr_decode_body_blob_batch`.
- **(b) PARSE-FAITHFUL** `PRE_PARSE_ORIGINAL_body == raw_body` — **the C-2 catch**. `PRE_PARSE_ORIGINAL` = the entry FILE's lines 2..EOF read BYTE-SAFELY in Python (`file_bytes[file_bytes.find(b"\n")+1:]` — a direct byte read after the first `\n`, NEVER awk). The bare `== raw_body` tautology is NOT present.
- **R-BODY-6** scans the same RAW FILE bytes (`pre_parse_original`) for NUL/CR/disallowed-C0-other-than-tab-LF/DEL (`_CHECK_49_DISALLOWED_CONTROL`).
- **SIZE** leg uses `len(composed[idx])` from the REAL `tmf_compose_issue_body_batch` output, vs `provider_body_limit − TMF_SIZE_SAFETY_MARGIN` (read from `provider_capabilities` `.body.limit` + the `${TMF_SIZE_SAFETY_MARGIN:-2048}` seam env).
- **TITLE** leg: `len(f"{pid}: {title}") > 256` codepoints (Python `len()` = codepoint count, not bytes; R-TITLE-1).

Empirical pre-design verification I ran (measure-not-estimate): all 211 real entries have `tail -n +2 == raw_body` byte-for-byte (`checked 211 nofile 0 diffs 0`), so leg (b) is GREEN today; and the shared batch codec round-trips all 211 byte-identical (`orig 211 decoded 211 equal True` in 0.14 s incl. lib-sourcing).

### 5. RUNTIME-BUDGET GUARD (§4.7)

Per-check 2.0 s → WARN; TOTAL-RUN 10 s HARD-FAIL GENERAL-PATH-ONLY; the deep run carries its own 35 s total budget. The total-run FAIL in `main()` selects the budget by `PACK_VALIDATE_DEEP`. Both behaviors are exercised by Group 4 of the per-check test (fake monotonic clock; per-check WARN does NOT append a failure, total-run overrun makes `main()` exit non-zero with the `RUNTIME-BUDGET: validate-pack total` message).

### 6. NO drop-allowlist; NO migrator edit

The guard asserts byte-equality with NO "OK to drop" allowlist. The migrator libs (`tracker-migrate-forward.sh` / `tracker-migrate-reverse.sh`) were NOT edited — the guard DRIVES the existing C-4.5-addendum batch functions. The guard passes on the real tree without any migrator change.

### 7. ENV-VAR DISCIPLINE while working

`PACK_VALIDATE_DEEP=1` was set ONLY for the single dedicated deep run and the per-check test (and the seam prototype). The unattended battery ran with `PACK_VALIDATE_DEEP=[UNSET]` (confirmed by echo before the run) — never exported globally.

---

## Wall-clock numbers (MEASURED, never estimated)

| Run | `/usr/bin/time -p real` | Result |
|---|---|---|
| General (`python3 scripts/validate-pack.py`, deep UNSET) | **1.35 s** (also 1.38 s) | GREEN; deep SKIPPED; 10 s total-run budget not breached |
| Deep (`PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py`) | **2.89 / 2.95 / 2.98 s** (3 runs) | GREEN; Check 49 = 211 entries byte-faithful; ≪ 30 s deep-leg / 35 s total budget (~10× margin) |
| FULL unattended battery (var UNSET, 52 unique test files + validate-pack) | **403 s (~6.7 min)** | **ALL BATTERY TESTS GREEN** — the runtime gate the prior 1.5h+ hang failed; COMPLETES in normal time |

Check 49 deep banner: `Check 49 — 211 entries byte-faithful (codec-lossless + parse-faithful), control-char-clean, title ≤ 256 codepoints, size leg vs provider body limit 65536 − margin 2048`.

---

## TEETH (each PROVEN)

| Teeth | Mechanism | Result |
|---|---|---|
| byte-leg (b) NUL/CR (the C-2 catch the tautology missed) | scratch tree, BD-900 body with a CR; parser drops `\r`, byte-safe original keeps it | leg (b) `PARSE-FAITHFUL leg FAILED` **AND** `R-BODY-6 disallowed control byte 0x0d` both fire — PASS |
| R-BODY-6 NUL | scratch tree, BD-903 body with a NUL | `R-BODY-6 disallowed control byte 0x00` fires — PASS |
| SIZE over-budget | scratch tree, BD-901; `TMF_SIZE_SAFETY_MARGIN=65536` → budget 0; REAL composed body measured | `exceeds provider body limit` FAILs — PASS |
| TITLE over-length | scratch tree, BD-902 title 300 codepoints | `exceeds R-TITLE-1 limit` FAILs — PASS |
| §4.5 single-source | injected `gzip.compress`/`base64.b64encode` into a temp COPY of validate-pack.py | Check 50 FAILs `reproduces the gz64/base64 codec`; clean source PASSES — PASS |
| runtime-budget total-run | fake monotonic clock makes a check appear 999 s; deep UNSET | `main()` emits `RUNTIME-BUDGET: validate-pack total` + exits rc 1; per-check overrun WARNs without failing — PASS |

Per-check test final: `PASS: 7 / FAIL: 0` (`All tests passed.`). Check 42 test: `FAIL: 0` (`All tests passed.`).

---

## NO-C-4.5-REGRESSION confirmation

The C-4.5 single-record codec path is byte-unchanged (the guard only DRIVES the additive batch mode; it did not touch the migrator). Re-ran:
- `tracker-migrate-roundtrip-test.sh` (the 211-entry lossless round-trip) → **All tests passed.**
- `tracker-migrate-forward-test.sh` (incl. the §2.9 batch-equivalence assertions) → **All tests passed.**
- `tracker-migrate-reverse-test.sh` → **All tests passed.**

---

## Plan deviations

**Zero.** Implemented §3.LF.5 exactly: NEW `check_migrator_field_faithfulness(tree_dir)` at the next registry integer (49); the `run_check` timing harness + total-run budget; the §4.5 OQ-4 single-source check; both workflow deep homes; the new per-check test; manifest regen (diff empty → not staged). No improve/simplify/generalize/refactor-adjacent changes; no codec reproduction reintroduced.

Note (not a deviation): the recipe item "(c) DELETE the committed gz64 codec REPRODUCTION" was a NO-OP at this worktree base — the reproduction was already reverted before this task (worktree clean at pre-flight; `grep` confirms zero codec-transform tokens in validate-pack.py). The guard calls the shared batch codec, as specified.

## New POQs introduced

None. (The check number 49 was read from the live registry — highest existing banner Check 48 — not hardcoded from the design's "49 today".)

---

## Boundary discipline check

All edits are pack-only surfaces: `scripts/validate-pack.py`, `.github/workflows/validate-pack.yml`, `scripts/tests/`. NONE are project-side (`project-template/`, `supporting-docs/`, or any client-shipped surface). No project-side SSOT investigation is owed; no `project-template/docs/pack/*` SSOT applies. No boundary-discipline STOP triggered (no pack-only reference added to a project-side file). The new check adds NO reference to `pack-ops/`, `maintenance-docs/`, a pack-* agent name, or the `Pack Chat` role.

---

## Definition-of-Done checklist

| Item | Status |
|---|---|
| `python3 scripts/validate-pack.py` GREEN + ~baseline (deep SKIPPED), measured | PASS (1.35 s, exit 0) |
| `PACK_VALIDATE_DEEP=1 ...` GREEN on real tree + SECONDS not minutes, measured | PASS (2.89–2.98 s, 211/211 byte-faithful) |
| FULL unattended battery (var UNSET) GREEN + COMPLETES in normal time | PASS (403 s, ALL GREEN) |
| Check 42 GREEN (per-check test wired) | PASS |
| §4.5 single-source check (Check 50) GREEN on clean source | PASS |
| byte-leg-(b) NUL/CR teeth fire (C-2 catch) | PASS |
| size / title / control-byte / single-source / slow-check teeth each fire | PASS |
| C-4.5 211-entry round-trip + forward + reverse still GREEN | PASS |
| SEAM drives shared batch codec; NO Python reproduction (OQ-4) | PASS (seam codec-token count 0) |
| ENV-GATE is the FIRST statement; general path ~0 | PASS |
| target-tree scoped; no `tree_dir or`/`REPO_ROOT/backlog` fallback in body | PASS |
| runtime-budget guard: per-check WARN + total-run hard-FAIL (general-only) | PASS |
| manifest regenerated; staged if non-empty | PASS (regen ran; diff empty → nothing to stage) |
| new test filename unique | PASS |
| pack-only scope (no project-template/ or supporting-docs/) | PASS |
| no migrator edit; no drop-allowlist | PASS |
| no git state change (agent) | PASS |

---

## Rules-Applied Verification Block

| Rule | Evidence | Conclusion |
|---|---|---|
| `agents-never-commit` | No `git add/commit/push/tag/...` run; only read-only `git status`/`rev-parse`/`diff`. Final HEAD == pre-flight HEAD `f89ade5`. | COMPLIANT |
| `per-action-approval-sub-agents` | No destructive op beyond in-scope edits; no live GH; scratch trees via `tempfile`/auto-cleaned. | COMPLIANT |
| `preflight-stop-means-stop` | Emitted `PREFLIGHT: 4/4 ... HEAD f89ade57... about to Write IMPL-REPORT` only AFTER all-green; no parent stop received. | COMPLIANT |
| `verify-full-ci-suite` | Ran the ENTIRE 52-file battery + validate-pack with var UNSET → `BATTERY COMPLETE in 403s / ALL BATTERY TESTS GREEN`. Did not stop at validate-pack only. | COMPLIANT |
| `regenerate-manifest-v11-surface` | `bash test-fixtures/build.sh --all --clean` (exit 0); `git status`/`git diff --stat test-fixtures/manifest.txt` → empty diff → nothing to stage. | COMPLIANT |
| `enumerate-encoding-surfaces` | The check + `run_check` harness + Check 50 single-source guard + the new per-check test + the workflow (BOTH homes) all moved in this one set of edits. | COMPLIANT |
| `edit-in-place-not-full-rewrite` | validate-pack.py + workflow edited via targeted `Edit` calls (no wholesale rewrite); the per-check test is a genuinely NEW file. | COMPLIANT |
| `pack-repo-code-comment-deferrals` | No deferral comments introduced (no `// TODO`/`# FIXME`); none needed. | N/A: no deferrals introduced |
| `filename-uniqueness-heuristic` | `find . -name 'test-validate-pack-check-49*'` and `-name '*field-faithfulness*'` → empty before naming; report name `IMPL-REPORT-BD-204-C-4.6.md` → empty before write. | COMPLIANT |
| `scope-deliverables-to-the-ask` | Exactly §3.LF.5 deliverables; nothing from fenced-out commits (no migrator edit, no schema-doc, no oracle). | COMPLIANT |
| `boundary-investigation-precedes-pack-defaults` | Edits limited to pack-only surfaces (validate-pack.py + workflow + test); no project-side file touched; no pack-only ref added to a project surface. | COMPLIANT |
| `ci-check-runtime-compounding` (constraints 1–7) | (P) env-gate FIRST → general 1.35 s; (T) caller's tree, no fallback; (S) ONE python3 per shared batch fn, deep 2.95 s vs A's 142 s; total-run guard added; battery COMPLETES 403 s. | COMPLIANT |
| `rules-applied-verification-block` | This table (per-rule name + quoted evidence + conclusion). | COMPLIANT |

---

## CONCERNS

None blocking. Notes for the reviewer:

1. **Stream key in the seam is hardcoded `pack-backlog`.** This labels the stream for `pe_list_entry_files`'s entry-regex (`^BD-[0-9]+\.md$`); the byte work is key-agnostic. The synthetic NEGATIVE fixtures use `BD-9NN.md` filenames so they match this regex. A future caller validating a non-backlog stream (e.g. changelog) would need a different key — out of scope for §3.LF.5 (the guard's two homes both target `/backlog/`). Documented in the check's comment.
2. **Size-leg provider limit source.** The seam reads `.body.limit` from `provider_capabilities` (the active provider; GH default = 65,536, pure-heredoc, no live `gh`) and the `${TMF_SIZE_SAFETY_MARGIN:-2048}` env — the SAME measurement the forward composer's §3.3c overflow gate uses. If a provider declares no `.body.limit`, the size leg SKIPs (banner says so) rather than false-failing — matches the forward composer's `[[ -n "$body_limit" && ... ]]` guard.
3. **Check 50 false-positive surface.** Check 50 skips its own forbidden-token DECLARATION tuple (quoted strings) + comment lines + the seam string. If a future edit adds a quoted `"gzip.GzipFile"` literal elsewhere it is allowed; an actual bare codec call is caught. The injected-codec teeth (Group 3) prove the catch; the clean-source reverse direction proves no false-positive at HEAD.
