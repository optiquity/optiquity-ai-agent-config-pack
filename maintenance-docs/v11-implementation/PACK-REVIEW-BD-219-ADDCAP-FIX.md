<!-- pack-only PACK-REVIEW — BD-219 add-capability.sh CI-failure fix. Read-only reviewer; uncommitted working-tree fix reviewed via git diff. Not a client deliverable. -->
# PACK-REVIEW — BD-219 `add-capability.sh` CI-failure fix (the last red)

**VERDICT: APPROVE** — Both fixes are correct and portable; the malformed
`${#NAME[@]:-0}` length+default construct is the real root cause (empirically
tolerated on bash 3.2 here, soundly reasoned to abort on bash 5/CI), the bug
class is fully eradicated in live code (only explanatory comments remain), and
the full 71-test wired battery + validate-pack general/DEEP are green with no
scope creep.

**Reviewer:** pack-reviewer (fresh; read-only) · **Date:** 2026-06-15
**Branch:** `v11-dev` · **HEAD:** `c96c4065ae141d210effc419b49f435b19554889`
**Bash on this machine:** `GNU bash 3.2.57(1)-release (arm64-apple-darwin25)` — only bash 3.2; no bash 4/5 binary.
**Scope claim:** `pack-only`. **Regime:** in-place; report written to the named parent-tree path.

---

## 1. ROOT CAUSE CONFIRMATION (independently re-derived)

The fix targets `scripts/add-capability.sh` function `write_prompt_file` —
the two arithmetic guards gating the BD-048 install-check section (now lines
601 / 607 post-fix) and the union-skills pipeline (now line 554).

### 1a. The malformed construct IS the bug (bash-3.2-empirical)

`${#NAME[@]:-0}` combines the length sigil `#` with the `:-` default operator —
mutually exclusive forms. Empirically on bash 3.2 (this machine):

```
$ arr=(a b); echo "$(( ${#arr[@]:-0} ))"
2                        # returns the LENGTH, not the default — :-0 ignored
$ arr2=(x y z); echo "$(( ${#arr2[@]:-BADWORD} ))"
3                        # :-BADWORD silently ignored entirely (length mode)
$ ( set -euo pipefail; a=(p q r); n=${#a[@]:-0}; echo "n=$n; exit=$?" )
tolerated, n=3; exit=0   # bash 3.2 tolerates it under set -euo pipefail
```

This proves the bash-3.2 side: the parser ignores the `:-…` modifier in length
mode and returns the array length, so `write_prompt_file` runs to completion →
the prompt file is written → the test PASSES on the dev Mac. This exactly
explains the passes-locally / fails-on-CI divergence.

### 1b. The bash-5/CI side (reasoned — bash 5 not available here)

bash 4.4+ tightened arithmetic-context expansion parsing; `${#NAME[@]:-0}` is no
longer silently accepted in length mode. Under the script's `set -euo pipefail`
(line 64, confirmed intact), a failing arithmetic expansion inside `(( … ))`
terminates `write_prompt_file`. The A8 banner is emitted by `stage_a8_prompt`
(line 627) BEFORE it calls `write_prompt_file` (line 630), and A7's banner
earlier still — so the CI log shows the A7/A8 banner assertions PASS while
`.pack-add-capability-prompt.md` is never created. This matches the reported CI
signature exactly: the early-exit lands BEFORE the file-write at line 621
(`printf '%s' "$report" > "$TARGET/$PROMPT_FILE"`), which is AFTER the guards at
601/607. **CI (Linux/bash 5) is the final judge; this leg is reasoned, not run.**

**Test-side confirmation of the signature.** `scripts/tests/test-add-capability.sh`
Group 2 asserts the A7 banner (line 118) and A8 banner (line 119) — both before
the `[[ -f "$PROMPT_FILE" ]]` gate (line 124); on a missing file it falls to
`t_fail "prompt file should exist"` (line 140). Banner-pass + prompt-missing is
precisely this test's failure shape — consistent with the diagnosed early-exit.

---

## 2. THE FIX IS CORRECT + PORTABLE

### 2a. Fix A — canonical length form (lines 601 / 607)

`${#DISCOVERY_LINES[@]:-0}` → `${#DISCOVERY_LINES[@]}` and
`${#INSTALL_HINTS[@]:-0}` → `${#INSTALL_HINTS[@]}`. The single canonical length
form is version-stable across bash 3.2/4/5, BSD/GNU.

**Dropping `:-0` is safe under `set -u` — both arrays are ALWAYS pre-initialized
before every path to `write_prompt_file`** (traced independently):

- `main()` (`scripts/add-capability.sh:644-645`) does `DISCOVERY_LINES=()` /
  `INSTALL_HINTS=()` BEFORE any stage runs.
- Early-exit `already-active` path: `stage_a2_delta` calls
  `write_prompt_file "already-active"` (line 339), which runs AFTER main's
  644-645 init. So the arrays exist on the early-exit path.
- Normal path: `stage_a7_install_check` re-inits both (lines 467-468) before
  `stage_a8_prompt` → `write_prompt_file` (lines 654→655).

There is no unset case for the `:-0` default to cover — it was dead. Verified
the early-exit path end-to-end: re-running `--add protocol:grpc` on a clean tree
already carrying grpc hits the already-active branch (EXIT 0) and the prompt
file IS created — i.e. `write_prompt_file` runs past the now-`:-0`-free guards
with `DISCOVERY_LINES`/`INSTALL_HINTS` initialized by main alone.

### 2b. Fix B — scoped grep wrap (line 554)

`… | grep -v '^$' | …` → `… | { grep -v '^$' || true; } | …`. The `|| true` is
scoped to grep ALONE (inside the brace group), tolerating only grep's
legitimate no-match (exit 1) when `all_skills` is all-empty-strings. Verified it
does NOT mask a genuine downstream failure:

```
$ ( set -o pipefail; printf 'a\nb\n' | { grep -v '^$' || true; } | sort --badflag-xyz 2>/dev/null | paste -sd, - ; echo "pipeline exit: $?" )
pipeline exit: 2          # real sort failure still propagates — not masked
$ ( set -euo pipefail; all_skills=("" "grpc-patterns"); union=$(printf '%s\n' "${all_skills[@]}" | { grep -v '^$' || true; } | sort -u | paste -sd, - | sed 's/,/, /g'); echo "<$union>" )
<grpc-patterns>           # normal grpc input still correct
```

**Caveat on the IMPL-REPORT's §6.1 local-repro claim (does not change the
verdict).** The IMPL-REPORT claims Fix B was reproduced on bash 3.2
("PRE-FIX EXIT=1, function aborted before file write"). I could NOT reproduce
that on bash 3.2 with the actual code shape (separate `local union_display`
declaration, then `union_display=$(…)` assignment inside a function):

```
$ ( set -euo pipefail; all_skills=("" "")
    f(){ local u; u=$(printf '%s\n' "${all_skills[@]}" | grep -v '^$' | sort -u | paste -sd, -); echo "REACHED <$u>"; }
    f; echo "returned" ) ; echo "exit: $?"
REACHED <>
returned
exit: 0                   # pre-fix did NOT abort on bash 3.2
```

Reason: on bash 3.2 a command-substitution-in-assignment does not trip `set -e`
in this position (the assignment's own status, and the `local`-builtin status
where applicable, mask the inner failure), even though `pipefail` reports the
pipeline as exit 1 in isolation. So on bash 3.2 the latent grep trap is masked
by assignment context — it is bash-5 (where `set -e` in command-sub assignments
behaves more strictly) where Fix B's guard earns its keep. **This is a precision
correction to the report's repro narrative, not a defect in the fix:** Fix B is
defensively correct, scoped, non-masking, and harmless on bash 3.2 (verified
EXIT 0 both pre and post). Both legs of the actual fix (A and B) thus share the
same "bash-5-strict, bash-3.2-lenient" character; CI remains the gate.
**Severity: NIT (report-narrative accuracy), not a fix defect — no action
required for APPROVE.**

---

## 3. BUG-CLASS ERADICATION (measure-then-bound)

The prompt's exact sweep across `scripts/` + `project-template/`:

```
$ grep -rnE '\$\{#[A-Za-z_][A-Za-z0-9_]*\[[@*]\]:-' scripts/ project-template/
scripts/add-capability.sh:552:        # pipefail. (BD-219 same-class hardening alongside the `${#arr[@]:-0}`
scripts/add-capability.sh:593:    # `${#arr[@]:-0}`: combining the length sigil `#` with the `:-` default
```

Both hits are confirmed `#`-comment lines (`grep -nE '^\s*#'` matches both); no
live-code instance. A repo-wide sweep excluding comment lines returns ZERO
matches. The bug class is fully eradicated in executable code; the only
remaining occurrences are the deliberate explanatory comments documenting the
trap. Fix is sized exactly to the two measured constructs + the one measured
unguarded grep-pipeline. COMPLIANT with measure-then-bound.

---

## 4. NO REGRESSION / SCOPE

```
$ git status --short
 M scripts/add-capability.sh
?? maintenance-docs/v11-implementation/IMPL-REPORT-BD-219-ADDCAP-FIX.md
```

- Only the one source file (M) + the new IMPL-REPORT. No manifest change
  (`git status --short test-fixtures/manifest.txt` empty after
  `test-fixtures/build.sh --all --clean` EXIT 0 — `add-capability.sh` is not a
  fixture file; the no-stage decision is correct).
- `git diff --stat`: 1 file, 23 insertions, 5 deletions (surgical).
- `set -euo pipefail` (line 64) is intact — NOT removed.
- Exactly ONE new `|| true`, scoped to grep inside braces — no blanket masking,
  no disabling of `set -euo pipefail`.
- Production behavior on bash 3.2 unchanged (both forms tolerated; prompt file
  created on both normal and already-active paths).
- The unrelated `test-tracker-promote-*` live-`gh` CI red is a separate,
  pre-existing, documented issue — not introduced or touched by this change.

---

## 5. FULL BATTERY (verify-full-ci-suite — quoted exits)

```
bash -n scripts/add-capability.sh                       → OK (exit 0)
bash scripts/tests/test-add-capability.sh               → passed: 19  failed: 0  EXIT=0
python3 scripts/validate-pack.py                        → "PASSED — all checks clean"  EXIT=0
PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py   → "PASSED — all checks clean"  EXIT=0
test-fixtures/build.sh --all --clean                    → EXIT=0 ; manifest diff EMPTY
```

**Every wired test in the yml `matrix.include[].scripts` (the SSOT) — 71 tests,
each exit quoted:**

```
Wired count extracted from .github/workflows/validate-pack.yml = 71
ci-shard-plan.py --print-partition reports: wired 71 / KEEP 71 (corroborates)
Battery result: PASS 71 / 71 ; FAIL 0 / 71
Failed: (none)
```

(All 71 enumerated with `exit=0`, incl. `test-add-capability.sh`. The 3
`test-tracker-promote-*.sh` pass here because `gh` is authenticated on this dev
machine — the documented passes-locally signature of the SEPARATE tracker CI
red, not this fix.)

**End-to-end fixture run (`test-fixtures/v11-flat-file` clone):**
```
normal run:        add-capability EXIT=0 ; .pack-add-capability-prompt.md CREATED (PASS)
already-active run: add-capability EXIT=0 ; prompt file CREATED via early-exit path (PASS)
```

---

## 6. FINDINGS

| # | Severity | Finding | Disposition |
|---|---|---|---|
| F1 | NIT | IMPL-REPORT §6.1 claims Fix B's grep-pipefail trap was reproduced on bash 3.2 (PRE-FIX EXIT=1). Independent testing shows the actual code shape (separate `local` decl + assignment) does NOT abort on bash 3.2 — assignment context masks `set -e`; the guard earns its value on bash 5. Report-narrative accuracy only; the FIX itself is correct, scoped, and non-masking. | No action required. Optional: a one-line report correction if Pack Chat wants the repro narrative exact. Does not block APPROVE. |
| — | (none) | No BLOCKER / MUST / SHOULD findings. Root cause real, fix correct + portable, bug class eradicated, no regression, scope clean. | APPROVE |

---

## 7. RULES-APPLIED VERIFICATION BLOCK

| Rule | Verification evidence (quoted / measured) | Conclusion |
|---|---|---|
| **verify-full-ci-suite** | Ran the full battery, exits quoted (§5): `bash -n` OK; `test-add-capability.sh` 19/19 EXIT 0; validate-pack general + DEEP both EXIT 0 "PASSED — all checks clean"; ALL 71 wired tests (yml `matrix.include[].scripts`, count cross-checked vs `ci-shard-plan.py --print-partition`=71) → 71/71 EXIT 0; end-to-end fixture run normal + already-active both EXIT 0 with prompt file created. Not validate-pack alone. | COMPLIANT |
| **ci-guard-design-measure-then-bound** | Ran the prompt's exact sweep `grep -rnE '\$\{#[A-Za-z_][A-Za-z0-9_]*\[[@*]\]:-' scripts/ project-template/` → only two hits, both confirmed `^\s*#` comment lines (552, 593); repo-wide live-code sweep (comments excluded) ZERO. Bug class fully gone in executable code; fix sized exactly to the measured 2 malformed constructs + 1 unguarded grep-pipeline (§3). | COMPLIANT |
| **empirical-evidence-blocks** | Every finding carries command + verbatim output + HEAD `c96c4065ae141d210effc419b49f435b19554889` + date 2026-06-15. Explicitly partitioned: bash-3.2 legs empirically RUN here (§1a, §2b repro, F1 counter-repro); bash-5 leg REASONED (no bash 5 binary; CI is the gate, stated §1b). | COMPLIANT |
| **architect-doc-reality-reconciliation** | All constructs referenced by file + symbol — `scripts/add-capability.sh` `write_prompt_file` / `main` / `stage_a2_delta` / `stage_a7_install_check` / `stage_a8_prompt` — not bare line numbers as durable anchors (line numbers used only as transient locators paired with the symbol). Confirmed the in-code comment references the report by filename (`See IMPL-REPORT-BD-219-ADDCAP-FIX.md`, line 599) and the durable A-fix comment carries no bare line numbers. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Reviewed only the add-capability fix. `git status --short` = `scripts/add-capability.sh` (M) + the new IMPL-REPORT; no other files; manifest unchanged. Flagged no scope creep in the change. My single write is this review doc; no codebase file edited; read-only git only (`rev-parse`, `status`, `diff`, `log`, `show`-class), `cp`/`mktemp` for scratch fixtures — no `checkout`/`stash`/`add`/`commit`. | COMPLIANT |
| **agents-never-commit** | No state-changing git verb run. HEAD unchanged `c96c4065ae141d210effc419b49f435b19554889`. Scratch fixtures via `mktemp`/`cp -R` then `rm -rf` on the temp dir only (their own throwaway `git init` is inside `/tmp`, never the pack repo). Sole write = this report. | COMPLIANT |
| **rules-applied-verification-block** | This table — per named rule, quoted/measured evidence, terminal COMPLIANT; no empty evidence; no AMBIGUOUS. | COMPLIANT |
