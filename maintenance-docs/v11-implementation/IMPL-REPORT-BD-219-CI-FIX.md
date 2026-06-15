<!-- pack-only IMPL-REPORT — BD-219 CI-RED fix (run 27549132073). Read-only authorship by pack-coder; consumed by Pack Chat for the review/fix cycle + commit. Not a client deliverable. -->
# IMPL-REPORT — BD-219 CI-RED fix (sharded `tests` job, run 27549132073)

**Coder:** pack-coder (fresh; CI-red fix implementation pass)
**Date:** 2026-06-15
**Regime:** IN-PLACE (working tree at `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`, branch `v11-dev`). No isolation; no `/tmp` handoff dir named.
**Working-tree HEAD (unchanged — I committed nothing):** `c7e0527a5d80ff2b5b86e78b3388ab1259c553d6`
**CI-RED commit being fixed:** `origin/v11-dev = e5a366f9f94c4819d407ec252e4eb691e14ab251` (run `27549132073` = failure)
**Blueprint:** `maintenance-docs/v11-implementation/PLAN-BD-219-CI-FIX.md` (executable plan) + `…/ARCHITECTURE-BD-219-CI-FAILURE-DIAGNOSIS.md` (diagnosis).
**Scope keyword:** `pack-only` (all edits under `scripts/`; NO `project-template/`, NO `supporting-docs/`).

---

## 1. LEAD — what changed (per-file)

ONE logical change, 8 files touched (7 test scripts + 1 allowlist note). No yml change, no production-lib change, no allowlist entry-count change (stays 1), manifest diff empty.

| # | File | Change type | Change |
|---|---|---|---|
| 1 | `scripts/tests/test-tracker-promote-path1.sh` | modified | Process-wide fake-`gh` PATH shim installed after `SCRATCH`/`trap` (line ~106). Double-zero `\|\| echo 0`→`\|\| true` at the `plan_after_f2_count` site (was :275). |
| 2 | `scripts/tests/test-tracker-promote-path2.sh` | modified | Process-wide fake-`gh` PATH shim installed after `SCRATCH`/`trap` (line ~102). Double-zero `\|\| echo 0`→`\|\| true` at `create_lines` (was :246) + `link_lines` (was :263). |
| 3 | `scripts/tests/test-tracker-promote-direct.sh` | modified | Hardcoded `/Users/david/.../scripts/pack-td.sh` → repo-relative via env-threaded `$REPO_ROOT` (`REPO_ROOT="$REPO_ROOT" python3 - <<'PYEOF'` + `os.path.join(os.environ["REPO_ROOT"], "scripts", "pack-td.sh")`; added `import os`). Single-quoted heredoc delimiter preserved (no backtick/`$`-eval hazard reintroduced). |
| 4 | `scripts/tests/test-validate-pack-check-16.sh` | modified | Group-3 heredoc only (opener at `:266`): `python3 <<EOF` → `REPO_ROOT="$REPO_ROOT" VALIDATE="$VALIDATE" python3 <<'EOF'`; `$REPO_ROOT`/`$VALIDATE` shell-expansions → `os.environ` reads; added `os` import. Quoting now passes the backtick python-comment lines (323–326) through literally → no bash-eval stderr noise. The OTHER 4 `<<EOF` heredocs in the file (93/158/351/396) left AS-IS (no backticks in their bodies — not offenders). |
| 5 | `scripts/tests/tracker-bd134-close-retry-test.sh` | modified | Double-zero `\|\| echo 0`→`\|\| true` at 3 sites: `seen_count` (was :325), `total_attempts` (was :360), `bd001_attempts` (was :365). |
| 6 | `scripts/tests/test-activate-capability.sh` | modified | **FOLD-IN-extension (ci-guard-design-measure-then-bound):** a 7th double-zero site the plan's narrower regex missed — `grep -Fxc … \|\| echo 0` (`:175`, `GI_HITS`) → `\|\| true`. `-Fxc` is a `grep -c` variant; empirically reproduced as a `0\n0` double-zero (§EV-2b). |
| 7 | `scripts/tests/tracker-migrate-forward-test.sh` | modified | **FOLD-IN (4b):** latent BSD-vs-GNU `date -r FILE -u` (`:783`, `toc_mtime_st`) → portable python3 (tz-aware `datetime.fromtimestamp(..., timezone.utc)`), byte-identical UTC to production's `date -r … -u` on the GNU CI runner. |
| 8 | `scripts/ci-test-wiring-allowlist.txt` | modified | **FOLD-IN (4a):** corrected the C3-discrepancy note's false "zero live `gh` calls" sub-claim — now states the tracker-mode legs DO shell `gh` directly and are kept KEEP/WIRED via the BD-219 PATH shim. Allowlist entry count UNCHANGED (1). |
| — | `test-fixtures/manifest.txt` | regenerated (no diff) | Ran `bash test-fixtures/build.sh --all --clean` (scripts/ = v11-surface). Diff EMPTY → nothing to stage (per `regenerate-manifest-v11-surface`). |

**Diff stat:** `8 files changed, 85 insertions(+), 18 deletions(-)` (scripts only).

---

## 2. SHIM MECHANISM + enumerated `gh` legs covered

### Mechanism (identical body in path1 + path2)
A single executable fake `gh` is written under `$SCRATCH/bin/` (so the existing `EXIT` trap cleans it up), made executable, and put first on `PATH` **process-wide** — installed once at the top of each test, after the `source` block + `SCRATCH`/`trap` lines and BEFORE the first tracker-mode group. Body:

```bash
mkdir -p "$SCRATCH/bin"
cat > "$SCRATCH/bin/gh" <<'GHEOF'
#!/usr/bin/env bash
case "$1 $2" in
  "label list")   printf '[]' ;;     # empty existing set → all canonical labels "missing" → created
  "label create") exit 0 ;;          # idempotent --force create → success
  "auth status")  echo "Logged in to github.com"; exit 0 ;;
  *)              exit 0 ;;           # no other live-gh call is reached by these legs
esac
GHEOF
chmod +x "$SCRATCH/bin/gh"
export PATH="$SCRATCH/bin:$PATH"
```

- **Process-wide (not per-Group-4)** per plan §DELTA-1: path1 has 2 tracker-mode legs (Group 4 + Group-7 F7 failure leg), path2 has 5 (Groups 4/4-second-run/6/7×2) — ALL reach `_tracker_labels_create`. A per-group shim would leave the Group-7 failure-path legs masked on a re-partition. Process-wide covers every leg.
- Inert for the flat-file groups (1–3, 5, 8 — they make no `gh` calls).
- Single-quoted `<<'GHEOF'` so no host-side expansion leaks into the shim body.

### Exact `gh` legs covered (confirmed against `scripts/lib/tracker-labels.sh`)
| Lib call site (file+symbol) | Exact invocation | Shim handling | Confirmed |
|---|---|---|---|
| `tracker-labels.sh` `_tracker_labels_create` (:212) | `gh label create "$name" --description "v11 pack-managed label" --color "ededed" --force` (lib redirects stdout/stderr to /dev/null) | `"label create") exit 0` | YES — Read :210–213 |
| `tracker-labels.sh` `_tracker_labels_existing` (:201) | `gh label list --json name --limit 200` (lib pipes stdout to `jq -r '.[].name'`) | `"label list") printf '[]'` (empty set → all canonical labels treated missing → all "created") | YES — Read :199–205 |
| defensive `gh auth status` | (some tracker helpers) | `"auth status") echo "Logged in to github.com"; exit 0` | mirrors `tracker-init-test.sh:206` |
| any other `gh …` | — | `*) exit 0` (catch-all; no other live-`gh` call is reached by these legs — confirmed §EE-3 of the plan) | — |

**Infeasibility escape hatch NOT triggered:** all reached `gh` calls are `label create` / `label list`, both shim-satisfiable. No leg required re-STRIP. The 3 promote tests stay KEEP/WIRED.

---

## 3. CLEAN-ROOM VERIFICATION (load-bearing — quoted commands + exits)

The dev box `gh` is authenticated (`DShaneNYC`) — local-pass is INSUFFICIENT and is exactly what caused the C3 mis-classification. I forced `gh` unauthenticated (CI-runner condition) and ran from a relocated `/tmp` path (proves no residual hardcoded path).

### 3.1 PRE-FIX reproduction (PROVE the failure first)
Pre-fix files extracted via read-only `git show origin/v11-dev:<path>` into a relocated `/tmp` copy (NEVER `git checkout`/`git stash` — used `cp` + `git show`). Run with `gh` scrubbed:

Command (per test):
```
env GH_TOKEN='' GITHUB_TOKEN='' GH_CONFIG_DIR="$(mktemp -d)" HOME="$(mktemp -d)" bash scripts/tests/<t>.sh
```
Results (PRE-FIX, unauthenticated `gh`):
```
=== test-tracker-promote-path1 EXIT=16 ::   PASS: 62   FAIL: 16
=== test-tracker-promote-path2 EXIT=16 ::   PASS: 40   FAIL: 16
```
- path2 emitted the EXACT diagnosis double-zero signature: `0: syntax error in expression (error token is "0")` (×2).
- `test-tracker-promote-direct` hardcoded-path: proven via the pre-fix python literal at `:265` (`/Users/david/.../pack-td.sh`); simulated CI `/home/runner/...` location → `0 (FileNotFoundError -> assertion 5.2 FAILS, exactly the CI symptom)`.

### 3.2 POST-FIX — PRIMARY GATE (in-place, full tree, unauthenticated `gh`)
Run in the REAL repo (all files present) with the same scrubbed-`gh` env:
```
=== test-tracker-promote-path1 EXIT=0 ::   PASS: 79   FAIL: 0  :: stderr-noise=0
=== test-tracker-promote-path2 EXIT=0 ::   PASS: 59   FAIL: 0  :: stderr-noise=0
=== test-tracker-promote-direct EXIT=0 ::   PASS: 31   FAIL: 0  :: stderr-noise=0
=== test-validate-pack-check-16 EXIT=0 ::   PASS: 10   FAIL: 0  :: stderr-noise=0
```
(`stderr-noise` = `grep -cE 'command not found|syntax error'` on captured stderr — 0 confirms the check-16 backtick noise is gone.)

### 3.3 POST-FIX — RELOCATED `/tmp` clean-room (proves §2.1 hardcoded-path fix)
Full repo tree copied to `/tmp/bd219-cleanroom` (NOT `/Users/david`), same scrubbed-`gh` env:
```
=== test-tracker-promote-path1 (relocated /tmp) EXIT=0 ::   PASS: 79   FAIL: 0  :: stderr-noise=0
=== test-tracker-promote-path2 (relocated /tmp) EXIT=0 ::   PASS: 59   FAIL: 0  :: stderr-noise=0
=== test-tracker-promote-direct (relocated /tmp) EXIT=0 ::   PASS: 31   FAIL: 0  :: stderr-noise=0
=== test-validate-pack-check-16 (relocated /tmp) EXIT=0 ::   PASS: 10   FAIL: 0  :: stderr-noise=0
```
direct.sh assertion 5.2 in the relocated path: `PASS 5.2 --fold-into in pack-td.sh present only as typed-error rejection (not wired)` — the `$REPO_ROOT` env-threading resolves correctly outside `/Users/david`.

> Clean-room caveat noted honestly: an INITIAL relocated copy that omitted `pack-ops/` + `project-template/` produced 3 path1 failures (`8.1/8.2/8.3` reading PM-CHAT.md/METHODOLOGY.md) and 2 check-16 failures (`project-template/CLAUDE.md — file missing`). Those were artifacts of the INCOMPLETE partial copy, NOT my edits — proven by (a) copying the missing dirs → all pass (above), and (b) the in-place run (3.2) passing with the full tree. `test-activate-capability.sh` similarly EXIT=1 in the partial `/tmp` copy because `init-project.sh` needs the full repo; in-place it is `passed: 27 failed: 0 EXIT=0`.

### 3.4 Linux-container check (§5.3) — SKIPPED (daemon unavailable)
`docker` is installed but the daemon is not running on the dev box. The container check is "STRONGER — recommended," not mandatory. Coverage substituted by the in-place + relocated-`/tmp` clean-room (both unauthenticated `gh`), which exercise both bug classes (live-`gh` dep + portability). Pack Chat may want CI itself (the actual Linux runner) to serve as the final container-equivalent gate on push.

---

## 4. DOUBLE-ZERO grep-ZERO completeness gate (`ci-guard-design-measure-then-bound`)

After fixing ALL sites, three completeness greps over the wired test set (`scripts/test*.sh` + `scripts/tests/*.sh`) return ZERO matches:
```
GATE A: grep -rnE 'grep -c[A-Za-z]* .*\|\| *echo 0' …       → exit=1 (ZERO)   [plan/diagnosis pattern]
GATE B: grep -rnE 'grep -[A-Za-z]*c[A-Za-z]* .*\|\| *echo 0' … → exit=1 (ZERO) [any flag-order grep-count]
GATE C: grep -rnE 'grep .*\|\| *echo 0' …                    → exit=1 (ZERO)   [any grep variant + || echo 0]
```
**Sites fixed: 7** (the plan named 6; I found a 7th):
- `test-tracker-promote-path2.sh` :246 / :263 (active — caused the run-27549132073 failure)
- `test-tracker-promote-path1.sh` :275 (latent)
- `tracker-bd134-close-retry-test.sh` :325 / :360 / :365 (latent)
- `test-activate-capability.sh` :175 — `grep -Fxc … || echo 0` — **7th site, plan's regex `grep -c[A-Za-z]*` missed it** (count flag `c` follows `Fx`, not the `-`). Empirically a genuine `0\n0` double-zero (§EV-2b). `test-activate-capability.sh` IS wired (shard 2). Fixed in lockstep per the bug-class-completeness rule.

**Surviving `|| echo 0` constructs are NOT the bug class** (verified, left as-is — scope-to-the-ask):
- `jq … || echo 0` (tracker-migrate-reverse :1053/:1085/:1099, tracker-migrate-forward :688) — jq prints nothing on parse error → single clean `0` (proven §EV-2c).
- `[[ … ]] && echo 1 || echo 0` ternaries (recommendation :135, bd204 :627, tracker-init :318/:319) — single print.

---

## 5. FOLDED items detail

### 5a. Allowlist C3-note correction (`scripts/ci-test-wiring-allowlist.txt`)
The embedded note's "zero live `gh` calls" premise was the false belief that caused C3 to wire these tests without a shim. Corrected in place (targeted edit, not a rewrite) to: stub seam intercepts only `tracker_provider_*`; tracker-mode legs shell `gh label create`/`gh label list` directly; masked by authed `gh` on the C3 box; KEEP/WIRED decision STANDS and is now MADE TRUE via the process-wide PATH shim; allowlist UNCHANGED at 1. The measure-then-bound framing + the bd204 single-entry rationale are preserved.

### 5b. `date -r` BSD-vs-GNU portability (`tracker-migrate-forward-test.sh:783`)
- **Found via grep:** `grep -rnE 'date -r' scripts/test*.sh scripts/tests/*.sh` → exactly ONE hit (`:783`). Matches plan §7 item 3.
- **Constraint discovered + honored:** the test's `toc_mtime_st` must byte-match production's `mirror freshness:` line, which production (`tracker-migrate-forward.sh:2156`, OUT of scope) computes with the IDENTICAL `date -r "$toc_path" -u '+%Y-%m-%dT%H:%M:%SZ'`. I CANNOT touch production (plan §2.4 + prompt item 5). So the portable replacement must yield the SAME UTC string production emits on the GNU CI runner.
- **Fix:** portable tz-aware python3 — `datetime.datetime.fromtimestamp(int(os.path.getmtime(FILE)), datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")`, file threaded via `MTIME_FILE` env, keeping the `|| echo ""` guard. Empirically byte-identical to `date -r … -u` on this BSD box (`2026-06-15T14:26:27Z` == `2026-06-15T14:26:27Z`) and to GNU `date -r … -u` on CI (where the test ran green on shard 3 pre-fix). No deprecation warning (modern tz-aware API, not `utcfromtimestamp`).
- **Verified:** `tracker-migrate-forward-test.sh` in-place → `=== Summary === Passed: 204 Failed: 0`, EXIT=0; assertion `3.10b pack mirror freshness reads /backlog/_toc.md mtime` PASS.

> NOTE — divergence from the plan that I am SURFACING: plan §7 lists items 4a (allowlist note) and 4b (`date -r`) as SURFACED-not-absorbed. My spawn prompt's FOLD-IN section (item 4) explicitly marks BOTH as USER-APPROVED for folding into this commit. I followed the spawn prompt (latest directive). If Pack Chat intended the plan's surfaced-only disposition, these two edits can be reverted independently (they are isolated single-region changes). See §8.

---

## 6. MANIFEST result
- `bash test-fixtures/build.sh --all --clean` ran clean (`manifest written: …/test-fixtures/manifest.txt`).
- `git status --short test-fixtures/manifest.txt` → EMPTY; `git diff --stat test-fixtures/manifest.txt` → EMPTY.
- The manifest tracks fixture-tree content, not test-script bytes, so test-script edits don't change it. Per `regenerate-manifest-v11-surface` ("stage iff the diff is non-empty"): nothing to stage.

---

## 7. FULL-SUITE + validator results (`verify-full-ci-suite`)

| Check | Command | Result |
|---|---|---|
| Full wired battery (71) | iterate the yml `matrix.include[].scripts` union (71 unique) in-place | **71 passed, 0 failed** |
| validate-pack general | `python3 scripts/validate-pack.py` | `PASSED — all checks clean` |
| validate-pack DEEP | `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | `PASSED — all checks clean` |
| Check 42 (wiring completeness) | `python3 scripts/validate-pack.py --only-check 42` | `OK: 72 on disk; 1 allowlisted; 71 KEEP; 71 wired; disk_KEEP_set == wired_set` |
| Partition invariant | `python3 scripts/lib/ci-shard-plan.py --print-partition` | `wired: 71   allowlisted (STRIP): 1   KEEP: 71   shards: 4` (UNCHANGED) |
| Allowlist entry count | `grep -vE '^\s*#' … | grep -vE '^\s*$' | wc -l` | `1` (UNCHANGED) |
| Shard-plan test | `bash scripts/tests/test-ci-shard-plan.sh` | `PASS: 10  FAIL: 0` |
| `bash -n` syntax (all 7 edited tests) | `bash -n <file>` | all OK |

The real gate remains CI on push (all 4 shards + `tests-result` aggregator + `validate` job).

---

## 8. PLAN DEVIATIONS (explicit)

1. **7th double-zero site (additive, in-bug-class).** The plan/diagnosis named 6 sites; I found and fixed a 7th — `test-activate-capability.sh:175` (`grep -Fxc … || echo 0`). The plan's matching regex (`grep -c[A-Za-z]*`) structurally cannot match `-Fxc`. Per `ci-guard-design-measure-then-bound` (fix ALL sites of the bug class) + the prompt's "grep-ZERO completeness gate proving no `|| echo 0` failure-masking idiom remains in the wired test set," this site is in-scope. Empirically confirmed as the same `0\n0` double-zero (§EV-2b). It IS a wired test (shard 2).
2. **Fold-in items 4a + 4b applied (per spawn prompt), vs plan §7 surfaced-only.** The plan listed the allowlist note + `date -r` as SURFACED-not-absorbed; the spawn prompt's FOLD-IN section marks both USER-APPROVED for this commit. I followed the spawn prompt. Both edits are isolated single-region changes, independently revertible if Pack Chat prefers the plan's disposition.
3. **`date -r` fix mechanism = python3, NOT a different `date` form.** The plan/diagnosis suggested generic portability; I discovered the test↔production byte-match constraint (production is out of scope) and chose a python3 form proven byte-identical to production's `date -r … -u` output, so the constraint is preserved. Surfaced here, not silently substituted.
4. **Linux-container check skipped** (Docker daemon down) — substituted by in-place + relocated-`/tmp` clean-room, both unauthenticated `gh`. (§3.4.)

No other deviations.

---

## 9. NEW POQs introduced
None. (One forward-looking item the plan §7-1 already surfaces — an optional cheap validate-pack standing guard that flags a wired tracker test invoking `gh ` without a PATH shim, to close the "confirm-offline-ran-on-an-authed-machine" gap — is NOT implemented here; it NEEDS user approval + a BD anchor. Surfacing only, per the plan; not my scope.)

---

## 10. DEFINITION-OF-DONE checklist

| Item | Status |
|---|---|
| Process-wide fake-`gh` shim in path1 + path2 (top-of-test, mirrors `tracker-bd129`) | PASS |
| Shim covers `label create` / `label list` / `auth status` / catch-all (confirmed vs `tracker-labels.sh`) | PASS |
| direct.sh hardcoded path → repo-relative via env-threaded `$REPO_ROOT` (single-quoted heredoc preserved) | PASS |
| check-16 Group-3 heredoc quoted + env-threaded; backtick stderr noise gone (count=0); other 4 heredocs untouched | PASS |
| Double-zero `|| echo 0`→`|| true` at all sites (7, incl. the 7th the plan missed) | PASS |
| grep-ZERO completeness gate (3 regex variants) returns ZERO | PASS |
| Allowlist stays 1 entry / 71 wired / 4 shards; no yml regen; no production-lib edit | PASS |
| FOLD-IN 4a: allowlist C3-note corrected | PASS |
| FOLD-IN 4b: `date -r` made portable (test↔production parity preserved) | PASS |
| Manifest regen run; diff empty → nothing to stage | PASS |
| Clean-room (unauthenticated `gh`): path1/path2/direct/check-16 EXIT 0, FAIL 0, noise 0 | PASS |
| Pre-fix reproduction (clean-room FAILS before, PASSES after) demonstrated via `cp`/`git show` (no checkout/stash) | PASS |
| Relocated `/tmp` path proves hardcoded-path fix | PASS |
| Full 71-test wired battery green | PASS |
| validate-pack general + deep + Check 42 green | PASS |
| `bash -n` syntax-clean on all edited files | PASS |
| No git state changes (read-only git only) | PASS |
| No out-of-scope edits (only `scripts/tests/*.sh` + allowlist; concurrent `backlog/_toc.md` IGNORED) | PASS |

---

## 11. FILES CHANGED inventory

| Path | Change type |
|---|---|
| `scripts/tests/test-tracker-promote-path1.sh` | modified |
| `scripts/tests/test-tracker-promote-path2.sh` | modified |
| `scripts/tests/test-tracker-promote-direct.sh` | modified |
| `scripts/tests/test-validate-pack-check-16.sh` | modified |
| `scripts/tests/tracker-bd134-close-retry-test.sh` | modified |
| `scripts/tests/test-activate-capability.sh` | modified |
| `scripts/tests/tracker-migrate-forward-test.sh` | modified |
| `scripts/ci-test-wiring-allowlist.txt` | modified |
| `test-fixtures/manifest.txt` | regenerated (no diff — not staged) |

**Out of my scope, present in tree, NOT touched by me (concurrent work):** `backlog/_toc.md` (modified at pre-flight), `backlog/BD-222.md` (untracked), the two input docs (`PLAN-BD-219-CI-FIX.md`, `ARCHITECTURE-BD-219-CI-FAILURE-DIAGNOSIS.md`).

---

## EVIDENCE BLOCKS (selected, for re-derivation)

### §EV-2b — `grep -Fxc … || echo 0` IS the double-zero bug class
```
$ printf 'foo\nbar\n' > /tmp/probe; result=$(grep -Fxc "nomatch" /tmp/probe 2>/dev/null || echo 0)
$ printf '%s' "$result" | od -c
0000000    0  \n   0
```
→ two-line `0\n0` on zero match (same failure mode as `grep -c`). `test-activate-capability.sh` confirmed wired (`ci-shard-plan.py --print-partition` lists it, shard 2). Fixed → `|| true`.

### §EV-2c — `jq … || echo 0` is NOT the bug class (left as-is)
```
$ printf 'not-json' | jq 'length' 2>/dev/null || echo 0    # → single line "0" (jq prints nothing on error)
$ printf '[]'       | jq 'length' 2>/dev/null || echo 0    # → single line "0" (jq prints 0, exits 0; || doesn't fire)
```

### §EV-5b — `date -r … -u` vs portable python3 byte-identical (this BSD box)
```
BSD date -r -u : 2026-06-15T14:26:27Z
python tz-aware: 2026-06-15T14:26:27Z   (no DeprecationWarning)
```
Production `tracker-migrate-forward.sh:2156` uses the identical `date -r … -u` form; the test's python value matches it on both BSD (here) and GNU (CI shard-3 green).

---

## RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted / measured) | Conclusion |
|---|---|---|
| **agents-never-commit** | Read-only git only: `git rev-parse HEAD` (returned `c7e0527…`, unchanged at end), `git status`, `git diff`, `git show origin/v11-dev:<path>` (read-only extraction for the pre-fix copies). NO add/commit/push/stash/checkout/restore/reset/worktree. Before/after copies made with `cp -R` + `git show`, never `git checkout`/`git stash`. Final HEAD == start HEAD `c7e0527a5d80ff2b5b86e78b3388ab1259c553d6`. | COMPLIANT |
| **edit-in-place-not-full-rewrite** | All 8 files edited via targeted `Edit` calls (single regions), no full rewrites. check-16 Group-3 heredoc uniquely targeted (the other 4 `<<EOF` heredocs untouched). Each edited region re-confirmed via `git diff` (§ diffs shown). | COMPLIANT |
| **ci-guard-design-measure-then-bound** | Fixed ALL sites of each bug class, not only the run-27549132073 failures: 7 double-zero sites (incl. the 7th the plan's regex missed) + the shim covers ALL 7 tracker-mode legs across path1+path2 (process-wide, plan §DELTA-1), not just Group 4. grep-ZERO gate (3 regex variants) → ZERO. Allowlist sized to EXACTLY the measured KEEP set (unchanged at 1). | COMPLIANT |
| **regenerate-manifest-v11-surface** | `scripts/` touched (v11-surface) → ran `bash test-fixtures/build.sh --all --clean` (`manifest written: …`). `git status --short test-fixtures/manifest.txt` → empty diff → nothing to stage (rule = stage iff non-empty). | COMPLIANT |
| **verify-full-ci-suite** | Full 71-test wired battery (yml matrix union) → 71 passed / 0 failed; validate-pack general + DEEP (`PACK_VALIDATE_DEEP=1`) + Check 42 → all clean; clean-room unauthenticated-`gh` (in-place + relocated `/tmp`) → all 4 promote/check-16 EXIT 0 / FAIL 0 / noise 0. Local-pass-on-authed-box declared insufficient and bypassed via scrubbed-`gh`. | COMPLIANT |
| **architect-doc-reality-reconciliation** | Lib references by file+symbol, never line-number-only as authority: `tracker-labels.sh` `_tracker_labels_create` / `_tracker_labels_existing`, `tracker-migrate-forward.sh:2156` (named with its `mirror_age` symbol context). Line numbers cited only as locators alongside symbol names. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Implemented exactly the plan + the 3 folded items (shim, portability, double-zero + 4a + 4b). Did NOT add the optional standing guard (surfaced only). Left non-bug-class `|| echo 0` (jq/ternary) untouched. Did NOT touch the concurrent `backlog/_toc.md` / `backlog/BD-222.md` / input docs. No production-lib edit. | COMPLIANT |
| **preflight-stop-means-stop** | Emitted the single PREFLIGHT line (`PREFLIGHT: CI-fix complete; promote tests PASS clean-room (gh-unauthenticated); double-zero grep=0; full battery all 0; manifest empty; about to Write IMPL-REPORT`) only AFTER all edits + clean-room + full battery + validate-pack PASS. No parent stop/halt received. | COMPLIANT |
| **rules-applied-verification-block** | This table — per-rule, quoted/measured evidence, terminal COMPLIANT; no empty evidence; no AMBIGUOUS. | COMPLIANT |

<!-- END IMPL-REPORT-BD-219-CI-FIX.md -->
