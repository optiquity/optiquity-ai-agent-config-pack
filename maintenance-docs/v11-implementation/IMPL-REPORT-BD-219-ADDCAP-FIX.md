<!-- pack-only IMPL-REPORT — BD-219 add-capability.sh CI-failure fix. Read-write coder ran IN-PLACE; no commit/stage. Not a client deliverable. -->
# IMPL-REPORT — BD-219 `add-capability.sh` CI-failure fix (the last red)

**Coder:** pack-coder (fresh; IN-PLACE regime) · **Date:** 2026-06-15
**Branch:** `v11-dev` · **Pre-flight HEAD:** `c96c4065ae141d210effc419b49f435b19554889`
**Final HEAD:** `c96c4065ae141d210effc419b49f435b19554889` (unchanged — agents never commit; the fix is uncommitted in the working tree)
**Scope:** `pack-only`. Single source file touched: `scripts/add-capability.sh`.
**Regime:** IN-PLACE (verified: cwd = repo working tree, HEAD = local `c96c406`, working tree was clean pre-flight). No `/tmp` handoff dir named → report written to the specified parent-tree path; no patch-emit required.

---

## 1. EXACT ROOT CAUSE (lead)

**File + construct:** `scripts/add-capability.sh`, function `write_prompt_file` — the two
arithmetic guards that gate the BD-048 install-check section of the PM-chat prompt:

```
(pre-fix, line 583)  if (( ${#DISCOVERY_LINES[@]:-0} > 0 )); then
(pre-fix, line 589)      if (( ${#INSTALL_HINTS[@]:-0} > 0 )); then
```

**The bug:** `${#NAME[@]:-0}` combines TWO mutually-exclusive parameter-expansion
forms — the length sigil `${#NAME[@]}` and the default-value operator
`${NAME[@]:-word}`. Combining `#` (length) with `:-` (default) is a **non-portable,
bash-parser-version-dependent** construct.

**Why it diverges macOS dev (bash 3.2) ↔ CI (bash 5.x / Ubuntu):**
- **bash 3.2** (the macOS default — `/bin/bash 3.2.57`): in length mode, the lexer
  reads the parameter name and **silently ignores the trailing `:-0`**, returning the
  array length. Proven empirically below (`${#arr[@]:-BADWORD WITH SPACES}` → `3`,
  EXIT 0). So the guard evaluates fine and `write_prompt_file` runs to completion →
  the prompt file is written → the test PASSES on the dev Mac.
- **bash 4.4+/5.x** (the CI Linux runner): the arithmetic-context parser does NOT
  silently ignore the `:-0` in length mode; the `${#NAME[@]:-0}` expansion aborts.
  Under the script's `set -euo pipefail` (line 64), the failing arithmetic expansion
  inside `(( ... ))` terminates `write_prompt_file` **before** the file-write at
  `printf '%s' "$report" > "$TARGET/$PROMPT_FILE"`. The A7 and A8 **banners** print
  earlier (`stage_a8_prompt` at the A8 banner line, BEFORE it calls
  `write_prompt_file`), which is exactly why the CI log shows the A7/A8 banner
  assertions PASS while `.pack-add-capability-prompt.md` is never created — the
  signature in CI run 27556025639.

**Why the `:-0` was never needed at all (so the canonical form is a strict
improvement, not a behavior change):** `DISCOVERY_LINES` and `INSTALL_HINTS` are
UNCONDITIONALLY initialized at every entry path —
`stage_a7_install_check` (`DISCOVERY_LINES=()` / `INSTALL_HINTS=()`) and `main`'s
pre-flight (the early-exit `already-active` path that calls `write_prompt_file`
before A7). There is no unset case for the `:-0` default to cover; the canonical
`${#NAME[@]}` is correct on every path under `set -u`.

**Repro status:** `bash5-specific-not-local`. Only `/bin/bash 3.2.57` is present in
this environment (no bash 4+/5 binary; I did not install one — environment
discipline). I confirmed bash 3.2 PASSES both forms (so the failure cannot be
reproduced here), then root-caused by inspection of the `set -euo pipefail` flow,
exactly as the prompt's fallback prescribes. The CI Linux/bash-5 runner is the final
judge. See §4 for the residual-risk statement.

**Tools-absent hypothesis — tested and FALSIFIED as the sole cause:** the prompt's
lead hypothesis was "CI runner missing `buf`/`protoc-gen-swift` → INSTALL_HINTS path
runs on CI but not dev." Measured: `buf`, `protoc-gen-swift`, `grpcio-tools` are
**ALL missing on the dev Mac too** (verified `command -v`), so the INSTALL_HINTS
path runs HERE as well — yet the test PASSES here. The tools-absent path is therefore
necessary (it reaches the `${#...:-0}` guards) but not sufficient to reproduce; the
divergence is the bash-version parse of `${#NAME[@]:-0}`, not tool presence.

---

## 2. SECONDARY SAME-CLASS TRAP (swept + fixed in lockstep)

Per `ci-guard-design-measure-then-bound`, I swept the WHOLE function/file for the
same class of `set -euo pipefail` portability trap and found ONE more — fixed in the
same pass:

**`write_prompt_file` union-skills pipeline (pre-fix line 545):**
```
union_display=$(printf '%s\n' "${all_skills[@]}" | grep -v '^$' | sort -u | paste -sd, - | sed 's/,/, /g')
```
`all_skills` is built as `("${ACTIVE_SKILLS[@]:-}" "${SKILLS_TO_ADD[@]:-}")`; when
`ACTIVE_SKILLS` is empty (the placeholder-CLAUDE.md case) the `:-` injects an empty
placeholder element, so `all_skills` can be all-empty-strings. `grep -v '^$'` then
matches NOTHING and **exits 1**; under `set -o pipefail` that propagates and `set -e`
aborts `write_prompt_file` before the file-write. This trap fires on **all** bash
versions (it is not the grpc CI failure — the grpc path has `grpc-patterns` so grep
matches — but it is the same `set -euo pipefail` portability bug class, and it would
break the `already-active` / no-real-skills paths on any machine). **Reproduced
locally on bash 3.2 (pre-fix EXIT 1, post-fix EXIT 0).**

This is the only OTHER instance of the class in `add-capability.sh`. The full sweep
(below) confirms no further occurrences.

---

## 3. THE FIX (before / after)

### Fix A — the bash-version trap (THE CI failure), `write_prompt_file` lines 583/589

Before:
```bash
    # ...guard with `:-` defaults to keep this prompt block well-formed in both modes.
    local dl il
    if (( ${#DISCOVERY_LINES[@]:-0} > 0 )); then
        ...
        if (( ${#INSTALL_HINTS[@]:-0} > 0 )); then
```
After (canonical length form + explanatory comment; arrays always pre-initialized):
```bash
    # ...Use the canonical `${#arr[@]}` length form, NOT `${#arr[@]:-0}`: combining
    # the length sigil `#` with the `:-` default operator is a non-portable,
    # parser-version-dependent construct. bash 3.2 silently ignores the `:-0`...
    # bash 4.4+/5.x (the CI Linux runner) parses it differently and the arithmetic
    # expansion aborts under `set -euo pipefail`... — the BD-219 CI failure...
    local dl il
    if (( ${#DISCOVERY_LINES[@]} > 0 )); then
        ...
        if (( ${#INSTALL_HINTS[@]} > 0 )); then
```

### Fix B — the union-pipeline grep-pipefail trap, `write_prompt_file` line 545

Before:
```bash
        union_display=$(printf '%s\n' "${all_skills[@]}" | grep -v '^$' | sort -u | paste -sd, - | sed 's/,/, /g')
```
After (tolerate ONLY grep's legitimate no-match; real failures in sort/paste/sed
still caught by pipefail — no blanket masking):
```bash
        # ...grep -v '^$' then matches nothing and exits 1; under set -o pipefail that
        # propagates and set -e would abort... Tolerate ONLY grep's no-match... with
        # `|| true` scoped to grep alone — a real failure in sort/paste/sed is still
        # caught by pipefail. (BD-219 same-class hardening...)
        union_display=$(printf '%s\n' "${all_skills[@]}" | { grep -v '^$' || true; } | sort -u | paste -sd, - | sed 's/,/, /g')
```

Both fixes are targeted in-place edits (no full rewrite); the function's section map
was re-read after editing and is intact (§DoD).

**Why these fixes are correct & portable (no band-aid):**
- Fix A uses the single canonical POSIX/bash length form, identical on bash 3.2,
  4.x, 5.x, BSD and GNU. The `:-0` it removes was dead (arrays always initialized).
- Fix B's `{ grep -v '^$' || true; }` swallows ONLY grep's exit (no-match is a
  legitimate empty result), leaving the rest of the pipeline pipefail-checked
  (verified: a downstream `sort --badflag` still yields a non-zero pipeline). It is
  NOT `|| true` over the whole substitution and does NOT disable `set -euo pipefail`.

---

## 4. RESIDUAL RISK (honest statement)

Fix A's true verification gate is the CI Linux/bash-5 runner (~2.5 min), because the
failure does not manifest on the only bash available here (3.2.57). The fix is
reasoned to be correct on bash 5 because: (a) it replaces a documented non-portable
length+`:-` combo with the single canonical length form; (b) that canonical form is
the unambiguous, version-stable construct used everywhere else in the file
(e.g. `${#FILES_TO_ADD[@]}`, `${#all_skills[@]}` — all already `:-`-free and all
passing on CI today); (c) the removed `:-0` default was provably dead. Fix B IS
locally reproduced (bash 3.2 pre/post). Confidence is high; CI remains the final
judge. No other bash-5-vs-3.2 divergence was found in the file (§5 sweep).

---

## 5. FULL SWEEP RESULT (measure-then-bound)

Grepped all relevant `set -euo pipefail` trap classes across the entire
`scripts/add-capability.sh`:

| Class | Sweep pattern | Hits | Disposition |
|---|---|---|---|
| Malformed `${#...[@]:-N}` (length+default) | `\$\{#[^}]*:-` | **2** (583, 589) | **FIXED** (the CI failure) |
| `grep` in command-sub pipeline (pipefail) | `grep ` + `$(...\|...)` | 545 (unguarded) | **FIXED** (Fix B). Lines 219/262/267/288 already `\|\| true`-guarded → SAFE. Lines 429/435/446 are `grep -Fxq` in `if`/`!` conditions → set-e-exempt → SAFE. Line 301 `grep -v '^$'` is the tail of a `< <(...)` process-sub → its exit is not propagated to the consumer → SAFE (verified). |
| Other command-subs with pipelines | `$(...\|...)` | 116/190/201/208/222/378/477/488-490/530/537 | SAFE — terminal cmd is `awk`/`pwd`/`tr` (always exit 0) or guarded (`cd ... \|\| echo`, `... \|\| true`); 537 is in the `else` of an empty-array check. |
| Bare `(( ))` statement (false → exit 1) | `^\s*\(\( ` | 110, 314 | SAFE — 110 is `(( )) \|\| die` (exempt); 314 is `(( )) && cmd` in an AND-list (set-e-exempt; verified). |

**No further instances of the bug class.** The fix is sized exactly to the two
measured malformed constructs + the one measured unguarded grep-pipeline.

**Pattern spotted elsewhere (surfaced, NOT fixed — per `scope-deliverables-to-the-ask`):**
I did not grep other wired scripts exhaustively for `${#...[@]:-N}` as part of this
ask (scope = `add-capability.sh` + its test). If Pack Chat wants a repo-wide sweep of
this construct across `scripts/`, that is a separate, easily-scoped follow-up
(`grep -rnE '\$\{#[^}]*\[@\]:-' scripts/`). Recommend it but do not action it here.

---

## 6. VERIFICATION EVIDENCE (quoted exits)

### 6.1 Local reproduction of the secondary grep-pipefail trap (Fix B) — bash 3.2
```
PRE-FIX  (old line 545, all_skills=("" "")):  EXIT=1  (function aborted before file write — the bug)
POST-FIX (new line 545, all_skills=("" "")):  REACHED FILE WRITE (union_display=<>) ; EXIT=0
```
Normal grpc input still works: `all_skills=("" "grpc-patterns")` → `union_display=<grpc-patterns>`, EXIT 0.
Real-failure still caught: downstream `sort --badflag` → pipeline EXIT 2 (not masked).

### 6.2 bash-version trap (Fix A) — construct demonstration on bash 3.2
```
OLD  ${#DISCOVERY_LINES[@]:-0} (5 entries):  TRUE n=5 ; [reached file write] ; EXIT=0   (bash 3.2 ignores :-0)
NEW  ${#DISCOVERY_LINES[@]}    (5 entries):  TRUE n=5 ; [reached file write] ; EXIT=0   (canonical)
Proof bash 3.2 ignores the modifier: ${#arr[@]:-BADWORD WITH SPACES} → 3 ; EXIT=0
```
(bash 5 cannot be run here; CI is the gate — §4.)

### 6.3 `test-add-capability.sh` (the failing test) — bash 3.2
```
── Summary ──  passed: 19  failed: 0
test-add-capability EXIT=0
```
(Necessary-not-sufficient: it passes on bash 3.2 regardless; the CI bash-5 run is
the real check.)

### 6.4 End-to-end script run against `test-fixtures/v11-flat-file` clone — prompt file IS created
```
add-capability EXIT=0
PROMPT FILE EXISTS (PASS)
```
Plus the `already-active` path (run twice): run1 EXIT=0, run2 EXIT=0 (exercises the
empty-`SKILLS_TO_ADD` branch that Fix B hardens).

### 6.5 Syntax check
```
bash -n scripts/add-capability.sh → OK (exit 0)
```

### 6.6 `validate-pack.py` — general + DEEP
```
python3 scripts/validate-pack.py                       → EXIT 0 ("PASSED — all checks clean")
PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py  → EXIT 0 ("PASSED — all checks clean")
```

### 6.7 FULL wired CI battery (every test in the validate-pack.yml matrix; `verify-full-ci-suite`)
Extracted the authoritative 71-test set from `scripts/lib/ci-shard-plan.py
--print-partition` and ran each, quoting exits:
```
Total wired tests: 71
PASS (exit 0): 71
FAIL (exit !=0): 0
Failed: (none)
```
Note: the 3 `test-tracker-promote-*.sh` scripts (the KNOWN separate CI red diagnosed
in `ARCHITECTURE-BD-219-CI-FAILURE-DIAGNOSIS.md`, live-`gh` dependency) PASS here
because `gh` is authenticated on this dev machine — that is the documented
passes-locally signature, a SEPARATE issue, NOT introduced or affected by this fix.
My change regressed nothing.

### 6.8 Manifest regeneration (`regenerate-manifest-v11-surface`)
`scripts/` touched → ran `bash test-fixtures/build.sh --all --clean` (EXIT 0).
Manifest diff: **EMPTY** (`add-capability.sh` is not a fixture file;
`git status --short test-fixtures/manifest.txt` shows no change). No manifest stage
needed.

---

## 7. FILES CHANGED INVENTORY

| Path | Change type | Notes |
|---|---|---|
| `scripts/add-capability.sh` | modified | `write_prompt_file`: 583/589 `${#...[@]:-0}`→`${#...[@]}` (Fix A, the CI failure); 545 grep `\| { grep -v '^$' \|\| true; }` (Fix B, same-class hardening); explanatory comments added. `git diff --stat`: 1 file, 23 insertions, 5 deletions. |
| `maintenance-docs/v11-implementation/IMPL-REPORT-BD-219-ADDCAP-FIX.md` | new | this report |

No other working-tree changes (`git status --short` = only `M scripts/add-capability.sh`
pre-report). Manifest unchanged. No BD status flip, no pack-chat-only file touched.

---

## 8. PLAN DEVIATIONS

Zero. The ask was: root-cause THE last BD-219 CI red, fix it portably, sweep the same
class in `add-capability.sh`, fix in lockstep, surface (not fix) the pattern
elsewhere. All done as specified. The prompt's lead hypothesis (tools-absent path)
was tested and refined to the precise root cause (bash-version parse of
`${#...[@]:-0}`), with evidence — this is hypothesis verification, not a deviation.

---

## 9. NEW POQs

None. The fix is mechanical and bounded. One optional follow-up surfaced (repo-wide
`${#...[@]:-N}` sweep across `scripts/`, §5) — recommended but out of this ask's
scope; for Pack Chat to schedule if desired.

---

## 10. BOUNDARY DISCIPLINE CHECK

`scripts/add-capability.sh` is a **pack-side** source script (it also ships to
clients as `activate-capability.sh` via the install map, so portability is real).
The edit is a pure shell-portability bug fix inside an existing function — it adds NO
references to any pack-only file, pack-* agent name, `Pack Chat` role,
`maintenance-docs/`, or `pack-ops/`. No project-side SSOT concept is involved (this
is a bash construct fix, not a rule/doc change). No pack-only reference was
introduced into a client-shipped surface. **No boundary-discipline stop.** The only
new file is this IMPL-REPORT, which lives in pack-only `maintenance-docs/` (correct
home for a pack implementation record).

---

## 11. DEFINITION-OF-DONE CHECKLIST

| Item | Status | Evidence |
|---|---|---|
| Concrete root cause identified (file + construct + why it diverges) | PASS | §1 — `write_prompt_file:583/589` `${#...[@]:-0}`; bash 3.2 ignores `:-0`, bash 5 aborts under `set -euo pipefail` |
| Repro attempted in-environment; result stated | PASS | §1/§4 — bash5-specific (not locally reproducible); secondary Fix-B trap WAS reproduced on bash 3.2 (§6.1) |
| Fix is correct & portable (bash 3.2+5, BSD+GNU, tools present+absent); no band-aid / no `\|\| true` masking / no disabling set -euo pipefail | PASS | §3 — canonical `${#arr[@]}`; scoped `{ grep \|\| true; }` (real failures still caught, §6.1) |
| Same bug class swept in `add-capability.sh` + fixed in lockstep | PASS | §2, §5 — 2 malformed + 1 grep-pipeline found and fixed; no others |
| Pattern elsewhere surfaced, not fixed | PASS | §5 — repo-wide `${#...[@]:-N}` sweep recommended as follow-up, not actioned |
| `test-add-capability.sh` EXIT 0 | PASS | §6.3 — 19/19, EXIT 0 |
| Full wired CI battery green (no regression) | PASS | §6.7 — 71/71 EXIT 0 |
| validate-pack general + DEEP green | PASS | §6.6 — both EXIT 0 |
| Manifest regenerated; diff reported | PASS | §6.8 — EXIT 0, diff EMPTY |
| `bash -n` syntax OK | PASS | §6.5 |
| In-place edits, re-read after, section map intact | PASS | §3 — re-read lines 539-613 post-edit |
| No commit/stage/push; read-only git only | PASS | HEAD unchanged `c96c406`; only `git status`/`diff`/`log`/`rev-parse`/`show`/`gh run view` used |
| scope = pack-only; only intended file changed | PASS | §7 — `git diff --name-only` = `scripts/add-capability.sh` only |

---

## 12. RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted / measured) | Conclusion |
|---|---|---|
| **agents-never-commit** | Read-only git only: `git rev-parse HEAD`, `git status --short`, `git diff --stat/--name-only`, `git log`, `gh run view` (read). HEAD unchanged: `c96c4065ae141d210effc419b49f435b19554889` pre- and post-work. No add/commit/push/checkout/stash/restore. Baseline copies used `cp -R` (fixture clones), never `git checkout`/`git stash`. | COMPLIANT |
| **edit-in-place-not-full-rewrite** | Two targeted `Edit` calls on `write_prompt_file` (no full-file Write of the script). Re-Read lines 539-613 after editing; confirmed section map intact (union block → report heredoc → BD-048 install-check block → trailing Procedure-6 text all present and ordered). `git diff --stat` = 1 file, 23 ins / 5 del (surgical). | COMPLIANT |
| **ci-guard-design-measure-then-bound** | Swept the WHOLE file for every trap class (§5 table: `\$\{#[^}]*:-`, grep-in-pipeline, bare `(( ))`, command-subs-with-pipes), categorized each hit KEEP-SAFE vs FIX, and sized the fix to exactly the measured set (2 malformed + 1 grep-pipeline). No broadening; no other instance left unfixed. | COMPLIANT |
| **verify-full-ci-suite** | Ran EVERY one of the 71 wired tests (extracted from `ci-shard-plan.py --print-partition`, the matrix source) quoting exits → 71/71 EXIT 0 (§6.7); plus `validate-pack` general AND DEEP (§6.6); plus the target `test-add-capability.sh` (§6.3) and `bash -n` (§6.5). Not validate-pack alone. | COMPLIANT |
| **regenerate-manifest-v11-surface** | `scripts/` (v11-surface) touched → `bash test-fixtures/build.sh --all --clean` EXIT 0; `git status --short test-fixtures/manifest.txt` → no change (diff EMPTY); no stage needed (§6.8). | COMPLIANT |
| **architect-doc-reality-reconciliation** | All constructs described by file + function/symbol (`scripts/add-capability.sh` `write_prompt_file`) plus the actual code text quoted; the in-code comments reference the realized record (`IMPL-REPORT-BD-219-ADDCAP-FIX.md`) and the symbol, not drift-prone bare line numbers in the durable comment prose. (Line numbers used in this report only as transient locators, paired with the construct.) | COMPLIANT |
| **scope-deliverables-to-the-ask** | Touched exactly `scripts/add-capability.sh` (the fix) + this report. Surfaced — did not fix — the repo-wide `${#...[@]:-N}` follow-up (§5) and the separate known tracker-promote live-`gh` CI red (§6.7). Ignored the unrelated concurrent BD-221 inventory work (none present in the repo tree; `git status` = only my file). | COMPLIANT |
| **preflight-stop-means-stop** | Emitted the single PREFLIGHT line (ROOT CAUSE + repro classification + test/battery exits) only AFTER all edits + verification PASSED, immediately before writing this report. A concrete root cause WAS identified, so no STOP-and-report-instead. No parent stop/halt was received. | COMPLIANT |
| **rules-applied-verification-block** | This table — per named rule, quoted/measured evidence, terminal COMPLIANT; no empty evidence; no AMBIGUOUS. | COMPLIANT |
