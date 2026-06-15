<!-- pack-only review artifact — independent pack-reviewer pass over the BD-219 CI-red fix (uncommitted working tree, run 27549132073). Read-only; the only Write is this doc. Not a client deliverable. -->
# PACK-REVIEW — BD-219 CI-red fix (sharded `tests` job, run 27549132073)

**Reviewer:** pack-reviewer (fresh; independent re-verification — did NOT trust the IMPL-REPORT)
**Date:** 2026-06-15 · **Local HEAD:** `c7e0527a5d80ff2b5b86e78b3388ab1259c553d6` (branch `v11-dev`, unchanged before/after — read-only git only)
**CI-RED commit fixed:** `origin/v11-dev = e5a366f` (run `27549132073` = failure)
**Reviewed:** the uncommitted working-tree fix across the 8 in-scope files + the new IMPL-REPORT (verified, not trusted).

---

## VERDICT: APPROVE

The fix is correct, complete, and load-bearing-verified. The independent clean-room (real `gh` made unreachable + auth scrubbed) reproduces the exact CI failure pre-fix and shows EXIT 0 / FAIL 0 / zero stderr-noise post-fix for all four load-bearing tests; the double-zero idiom is fully eradicated (3 grep-zero gates, including the 7th `-Fxc` site); the full 71-test battery + validate-pack general/deep/Check-42 are green; no production code or yml touched; allowlist stays 1 / wired 71 / shards 4. No BLOCKER, MUST, or SHOULD findings. Two NITs (informational only, no fix required).

---

## 1. INDEPENDENT CLEAN-ROOM (the load-bearing check — re-run by me, not trusted)

**Method (mirrors the CI failure condition):** prepended a fail-loud `gh` shadow to PATH (a `gh` that prints "not logged in" + `exit 1`, simulating an unreachable/unauthenticated real `gh`) AND scrubbed auth via `GH_TOKEN='' GITHUB_TOKEN='' GH_CONFIG_DIR=$(mktemp -d) HOME=$(mktemp -d)`. The test's own shim prepends `$SCRATCH/bin` *after* the shadow, so ONLY the test's shim answers covered legs; any un-shimmed `gh` leg falls through to the fail-loud shadow. (Note: python3/jq/git live in `/opt/homebrew/bin` alongside the real `gh`, so a PATH-exclusion of that dir was infeasible without breaking tooling — the fail-loud shadow is the correct equivalent and is strictly stronger because it FAILS rather than silently skips on an escaped call.) Pre-fix copies extracted via read-only `git show HEAD:<path>` into relocated `/tmp` trees (no `git checkout`/`git stash`).

**PRE-FIX (relocated `/tmp` tree, real `gh` unreachable) — reproduces CI exactly:**
```
=== PRE-FIX test-tracker-promote-path1 EXIT=13 :: PASS:65 FAIL:13 :: noise=0 :: dz-syntax-err=0
=== PRE-FIX test-tracker-promote-path2 EXIT=16 :: PASS:40 FAIL:16 :: noise=2 :: dz-syntax-err=2
=== PRE-FIX test-tracker-promote-direct EXIT=0 (hardcoded /Users path still exists on dev box → masked locally; see below)
=== PRE-FIX test-validate-pack-check-16 EXIT=0  PASS:10 FAIL:0 :: noise=3  (backtick heredoc stderr noise)
```
path1 FAIL=13 and path2 FAIL=16 match the CI run's `FAIL: 13` / `FAIL: 16` verbatim; path2 emits 2× `0: syntax error in expression (error token is "0")` (the active double-zero); check-16 emits 3 stderr-noise lines (the backtick heredoc). The clean-room is therefore proven to reproduce CI.

**direct.sh hardcoded-path proof (separate, since `/Users/david/...` still exists on the dev box and masks it):** the pre-fix python opens the hardcoded `/Users/david/.../scripts/pack-td.sh`; on CI's `/home/runner/...` that is a `FileNotFoundError` → else-branch prints `0` → assertion 5.2 fails. The POST-FIX direct.sh, run from a fully relocated `/tmp/bd219-cleanroom-post` tree (so `$REPO_ROOT` resolves to `/tmp/...`), with real `gh` unreachable:
```
=== POST-FIX direct.sh from /tmp (REPO_ROOT relocated) EXIT=0  FAIL:0
   PASS 5.2 --fold-into in pack-td.sh present only as typed-error rejection (not wired)
```

**POST-FIX (in-place, real `gh` unreachable + auth scrubbed) — PRIMARY GATE:**
```
=== test-tracker-promote-path1 EXIT=0 :: PASS:79 FAIL:0 :: stderr-noise=0
=== test-tracker-promote-path2 EXIT=0 :: PASS:59 FAIL:0 :: stderr-noise=0
=== test-tracker-promote-direct EXIT=0 :: PASS:31 FAIL:0 :: stderr-noise=0
=== test-validate-pack-check-16 EXIT=0 :: PASS:10 FAIL:0 :: stderr-noise=0
```
(`stderr-noise` = `grep -cE 'command not found|syntax error'` on captured stderr.)

**Verdict on item 1:** PASS. Every load-bearing test that failed on CI now exits 0 with FAIL=0 and no stderr noise under the exact unauthenticated-`gh` condition that failed. No `gh` leg is un-shimmed.

---

## 2. SHIM COMPLETENESS (item 2)

- **Process-wide, correctly placed.** Shim built + `export PATH="$SCRATCH/bin:$PATH"` at path1:129 / path2:125 — after the `source` block (ends ~line 81/79) and the `SCRATCH`/`trap` lines, BEFORE the first tracker-mode leg (path1 first `... 0` at :323; path2 first `... 0` at :265). Never restored → covers all groups including the Group-7 failure-path legs (path1:573, path2 F7 legs). Lives under `$SCRATCH` so the existing EXIT trap cleans it. Mirrors `tracker-bd129-gh-repo-test.sh:104`.
- **Covers every live-`gh` leg — empirically proven.** Instrumented the test's own shim to log every `gh` subcommand it serviced during a clean-room run: the shim serviced ONLY `label create` (14 invocations across path1+path2, exact shape `label create <name> --description "v11 pack-managed label" --color "ededed" --force`) and is wired to also answer `label list` / `auth status`. A separate logging-shadow run confirmed **0 `gh` calls escaped the test shim** and **0 `gh` calls occurred before the shim installed**. The catch-all `*) exit 0` is never relied upon for an un-analyzed subcommand.
- **No conflict with the stub seam.** The `_TRACKER_PROVIDER_BACKEND_OVERRIDE=stub` blocks are untouched; they intercept `provider_*` (writing `$G4_STUB_LOG`, which the assertions read). The shim only covers the direct `gh label …` calls in `tracker-labels.sh` the stub never intercepted — complementary, orthogonal (process-wide shim vs per-group stub override). The `$SCRATCH`-rooted shim does not collide with the existing trap.

**Verdict on item 2:** PASS.

---

## 3. DOUBLE-ZERO ERADICATION (item 3) — grep-zero completeness gate

Three grep-zero gates over the wired test set (`scripts/test*.sh` + `scripts/tests/*.sh`), all returning ZERO (exit 1):
```
GATE A  grep -rnE 'grep -c[A-Za-z]* .*\|\| *echo 0' …            → exit=1 (ZERO)
GATE B  grep -rnE 'grep -[A-Za-z]*c[A-Za-z]* .*\|\| *echo 0' …   → exit=1 (ZERO)
GATE C  grep -rnE 'grep .*\|\| *echo 0' …                        → exit=1 (ZERO)
```
- **7 sites fixed, including the 7th** (`test-activate-capability.sh:175`, `grep -Fxc … || echo 0`). Independently confirmed `grep -Fxc … || echo 0` IS the bug class — `od -c` shows `0 \n 0` (the two-line double-zero) — and `test-activate-capability.sh` IS wired (in the partition, shard 2; 1 yml ref). The plan's narrower regex `grep -c[A-Za-z]*` structurally cannot match `-Fxc`; the coder's fold-in is correct and in-scope per `ci-guard-design-measure-then-bound`.
- **Surviving `|| echo 0` correctly left as-is (NOT the bug class):** verified empirically — `jq … || echo 0` prints a single clean `0` on both parse-error and empty-array (`od -c` shows one byte `0`, no newline-doubling); `[[ … ]] && echo 1 || echo 0` ternaries print a single token. Leaving these is correct (`scope-deliverables-to-the-ask`).

**Verdict on item 3:** PASS.

---

## 4. PORTABILITY FIXES (item 4)

- **Hardcoded path gone.** `grep -rnF '/Users/'` and `grep -rnE '/home/[a-z]'` over the wired set → ZERO (exit 1). direct.sh now threads `$REPO_ROOT` via env into the single-quoted heredoc and opens `os.path.join(os.environ["REPO_ROOT"], "scripts", "pack-td.sh")` (`import os` added). Single-quoted delimiter preserved → no backtick/`$`-eval hazard reintroduced. Relocated-`/tmp` run (item 1) proves resolution outside `/Users/david`.
- **check-16 stderr noise gone.** Group-3 heredoc is now `REPO_ROOT="$REPO_ROOT" VALIDATE="$VALIDATE" python3 <<'EOF'` (quoted); body reads `os.environ["REPO_ROOT"]`/`["VALIDATE"]` (`os` added to the import line); `REPO_ROOT`/`VALIDATE` are defined at lines 31–32, before the heredoc. The backtick python-comment lines now pass through literally → noise=0 in the clean-room. The other 4 `<<EOF` heredocs in the file were correctly left untouched (no backticks in their bodies).
- **`date -r` portable + byte-identical.** The only `date -r` tokens remaining are in the explanatory COMMENT; the actual code uses portable tz-aware python3 (`datetime.fromtimestamp(int(os.path.getmtime(...)), timezone.utc).strftime(...)`). Independently confirmed byte-identical to the production `date -r … -u` form on this platform (`2026-06-15T14:51:44Z` == `2026-06-15T14:51:44Z`). The test↔production parity constraint is correctly preserved: production (`tracker-migrate-forward.sh:2156`, out of scope) still uses `date -r "$toc_path" -u`; on the GNU CI runner `date -r FILE` = reference-file mtime, matching python's `getmtime`; both floor to the same integer second. `tracker-migrate-forward-test.sh` runs green (204/0) with assertion `3.10b … reads /backlog/_toc.md mtime` passing.

**Verdict on item 4:** PASS.

---

## 5. FOLD-INS (item 5)

- **4a — allowlist C3-note.** The false "zero live `gh` calls" premise is corrected: the phrase now appears only inside the CORRECTION as a negation ("does NOT make these tests 'zero live `gh` calls'"), with the accurate account (tracker-mode legs shell `gh` directly; masked by authed `gh` on the C3 box; KEEP/WIRED now made true via the PATH shim). Allowlist entry count UNCHANGED at exactly 1 (`tracker-bd204-lossless-roundtrip-test.sh`). Edit is targeted in-place, not a rewrite.
- **4b — `date -r`.** Correct (see §4).
- **Allowlist/wired/shards invariants.** `ci-shard-plan.py --print-partition` → `wired: 71  allowlisted (STRIP): 1  KEEP: 71  shards: 4`. `--assert-coverage` → exit 0 (`union == wired_KEEP_set; pairwise-disjoint; fixture cohesion group co-located`). Check 42 → `72 on disk; 1 allowlisted; 71 KEEP; 71 wired; disk_KEEP_set == wired_set`.

**Verdict on item 5:** PASS.

---

## 6. NO PRODUCTION CODE / NO RE-STRIP (item 6)

- `git diff --name-only` contains NO `scripts/lib/` path and NO `.github/workflows/` path. Production lib code untouched; no yml regen.
- All 3 promote tests stay KEEP-wired (1 yml ref each; present in the partition). The re-STRIP escape hatch was not triggered (no leg required it — confirmed by the shim-call instrumentation in §2).

**Verdict on item 6:** PASS.

---

## 7. FULL CI BATTERY (item 7) — independent, not sampled

| Check | Command | Result |
|---|---|---|
| Full wired battery (71) | ran every test in the `ci-shard-plan.py --print-partition` list (71) in-place, captured each exit | **PASS=71, FAIL=0** (all EXIT=0, incl. all 7 edited tests) |
| validate-pack general | `python3 scripts/validate-pack.py` | exit 0 — `PASSED — all checks clean` |
| validate-pack DEEP | `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | exit 0 — `PASSED — all checks clean` |
| Check 42 | `--only-check 42` | exit 0 — `72 on disk; 1 allowlisted; 71 KEEP; 71 wired; disk_KEEP_set == wired_set` |
| `--assert-coverage` | `ci-shard-plan.py --assert-coverage` | exit 0 — union==wired_KEEP_set, disjoint, cohesion co-located |
| Manifest regen | `bash test-fixtures/build.sh --all --clean` | exit 0; `git diff --stat test-fixtures/manifest.txt` → EMPTY (nothing to stage) |
| `bash -n` (7 edited tests) | `bash -n <file>` | all OK |

- **enumerate-encoding-surfaces:** the edits change no test's asserted OUTPUT. Cross-references to the edited test names are all benign — `validate-pack.py:6685` (comment), `test-validate-pack-check-42.sh` (wired-test-name metadata list; check-42 ran green), the tracker cross-refs (comments + shared `source` lines). No stale assertion anywhere; no banner/SKIP-wording surface pins these tests' output.

**Verdict on item 7:** PASS.

---

## SCOPE CONFIRMATION

Reviewed ONLY the 8 in-scope fix files (`scripts/tests/test-tracker-promote-{path1,path2,direct}.sh`, `test-validate-pack-check-16.sh`, `tracker-bd134-close-retry-test.sh`, `test-activate-capability.sh`, `tracker-migrate-forward-test.sh`, `scripts/ci-test-wiring-allowlist.txt`) + the new IMPL-REPORT. The working tree ALSO carries, OUT of scope and explicitly NOT flagged: `backlog/BD-222.md`, `backlog/_toc.md` (concurrent backlog), and the input docs `ARCHITECTURE-BD-219-CI-FAILURE-DIAGNOSIS.md` + `PLAN-BD-219-CI-FIX.md`. Manifest diff empty → no manifest stage needed (the IMPL-REPORT's claim is correct). Diff-stat matches the IMPL-REPORT (8 files, 85+/18−).

---

## FINDINGS BY SEVERITY

**BLOCKER:** none. **MUST:** none. **SHOULD:** none.

**NIT-1 (informational, no fix).** The shim's `label list` leg (`printf '[]'`) is defensive only — the instrumentation showed the tracker-mode legs reach `gh label create` (14×) but never `gh label list` in these tests. The `label list` + `auth status` cases are harmless coverage matching `tracker-labels.sh` / the bd129/init pattern; no change needed.

**NIT-2 (informational, no fix).** Production `tracker-migrate-forward.sh:2156` still uses `date -r … -u` (out of scope by design). The test's portable python form is now byte-identical on GNU and BSD, so the test↔production parity holds; if production's `date -r` is ever revisited for portability, that is a separate (non-CI-red) item. The plan's §7 already surfaces the optional standing guard (flag a wired tracker test invoking `gh` without a PATH shim) as a user-gated follow-up needing a BD anchor — correctly NOT absorbed here.

---

## RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (command + verbatim output + HEAD `c7e0527` + 2026-06-15) | Conclusion |
|---|---|---|
| **verify-full-ci-suite** | Independent clean-room (real `gh` unreachable via fail-loud shadow + `GH_TOKEN=''/GITHUB_TOKEN=''/GH_CONFIG_DIR/HOME` scrubbed): pre-fix path1 FAIL=13 / path2 FAIL=16 (matches CI) + 2× `syntax error in expression` + check-16 noise=3; post-fix path1/path2/direct/check-16 all `EXIT=0 FAIL:0 noise=0` (§1). Full 71-test battery `PASS=71 FAIL=0`; validate-pack general+DEEP+Check42 exit 0; `bash -n` all OK; manifest diff empty (§7). | COMPLIANT |
| **ci-guard-design-measure-then-bound** | 3 grep-zero gates (A/B/C) over the wired set → ZERO (§3); 7th `-Fxc` site confirmed bug class via `od -c` = `0 \n 0` and confirmed wired (shard 2); jq/ternary survivors confirmed single-token (not bug class). Shim covers ALL tracker-mode legs (process-wide; 14 `label create` serviced, 0 escaped to shadow — §2). Allowlist sized to exactly 1 (the lone live-GH oracle); partition `--assert-coverage` exit 0 (§5). | COMPLIANT |
| **empirical-evidence-blocks** | Every finding carries the command + verbatim output + HEAD `c7e0527` + date 2026-06-15 (§§1–7); HEAD confirmed unchanged before/after (`git rev-parse HEAD` = `c7e0527…`). | COMPLIANT |
| **enumerate-encoding-surfaces** | `grep -rln` of each edited test name across `*.sh/*.py/*.yml`: cross-refs are comments (`validate-pack.py:6685`), wired-test-name metadata (`test-validate-pack-check-42.sh`, which ran green), and shared `source` lines — none pin the edited tests' OUTPUT. No stale assertion (§7). | COMPLIANT |
| **scope-deliverables-to-the-ask** | Reviewed ONLY the 8 fix files + IMPL-REPORT; `git status` shows the concurrent `backlog/BD-222.md` / `backlog/_toc.md` + the input/IMPL docs as untouched-by-fix and explicitly NOT flagged (Scope Confirmation). | COMPLIANT |
| **agents-never-commit** | Read-only git only: `git rev-parse`, `git status`, `git diff`, `git show HEAD:<path>` (pre-fix extraction). NO checkout/stash/add/commit/reset/worktree. Baseline copies via `cp -R` + `git show`. Final HEAD == start HEAD `c7e0527a5d80ff2b5b86e78b3388ab1259c553d6`. Single Write = this review doc at the caller-specified path. | COMPLIANT |
| **rules-applied-verification-block** | This table — per-rule, quoted/measured evidence, terminal COMPLIANT; no empty evidence; no AMBIGUOUS. | COMPLIANT |

<!-- END PACK-REVIEW-BD-219-CI-FIX.md -->
