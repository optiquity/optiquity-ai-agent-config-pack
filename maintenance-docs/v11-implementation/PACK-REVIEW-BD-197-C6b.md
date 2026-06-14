# PACK-REVIEW — BD-197 C6b — Guard-B-project (Check 55) RW/RO consistency

**Role:** pack-reviewer (fresh, C6b). **Scope reviewed:** C6b `pack-only` — `scripts/validate-pack.py` (Check 55) + `scripts/tests/test-validate-pack-check-55.sh` + `.github/workflows/validate-pack.yml`.
**Repo:** optiquity-ai-agent-config-pack-v11-dev · **Branch:** `v11-dev`.
**HEAD at review:** `4226dc84bf99fdb20cc6599076655a09698b39f4` (read-only git; no commit). **Date:** 2026-06-14.
**Method:** INDEPENDENT re-verification — re-ran every command myself; did NOT trust the IMPL-REPORT (cross-checked it instead).

---

## VERDICT: APPROVE

Check 55 is a correct, measure-then-bound, prose-header-bound, runtime-trivial Guard-B-project; it is green on arrival, FAILS on injected per-leg mismatches (independently proven against a /tmp copy with the real tree untouched), is wired into the yml in lockstep with its run-before-wire test, and the C6b diff is cleanly single-surface `pack-only` with an empty manifest diff. No BLOCKER, MUST, or SHOULD findings. Two informational NITs only.

---

## Read attestation

Read in full before reviewing: design `ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` §13.2 (Guard-B project) + §4.3-project + §13/§13.1/§13.1a/§13.3 (sibling guards) + §14/§15; `PLAN-BD-197-WORKTREE-ISOLATION.md` §A (commit table C6a/C6b), §B C6a/C6b, §C (ordering), §D (verify-full-ci), §F (EE-1/EE-5/EE-6 measurements), §G (manifest), §H (encoding-surfaces row Check 55), §I C6b (rules-in-force); the existing Guard-B(pack) Check 52 implementation in `scripts/validate-pack.py` (for parity-of-approach); the full `git diff` of the C6b files; `IMPL-REPORT-BD-197-C6b.md`; `CLAUDE.md` § "## Pack memory".

---

## Explicit verdicts on the two flagged questions

### (a) Prose-not-tools binding — VERDICT: CORRECT, and independently proven load-bearing

`_check_55_header_class()` keys ONLY on the prose mandate headers (`_CHECK_55_RO_HEADER = "**Read-only.**"`, `_CHECK_55_RW_HEADERS = ("**Write-capable (scoped).**", "**Write-capable (script).**")`) and never inspects `tools:`. I proved the binding is load-bearing, not cosmetic, three ways on the REAL tree (HEAD `4226dc8`, 2026-06-14):

- RO agents carry write tools yet classify RO:
  ```
  $ grep -E '^tools:' project-template/.claude/agents/reviewer.md
  tools: Read, Grep, Glob, Bash, Write, Edit
  $ grep -E '^tools:' project-template/.claude/agents/architect.md
  tools: Read, Grep, Glob, Bash, Write, Edit
  $ grep -E '^tools:' project-template/.claude/agents/auditor.md
  tools: Read, Grep, Glob, Bash, Task, Write, Edit
  ```
  All three carry `Write, Edit` yet each carries `**Read-only.**` and the guard classifies them RO. A `tools:`-keyed guard would misclassify all three as RW.
- Gemini-no-`tools:` case: `grep -lE '^tools:' project-template/.gemini/agents/*.md | wc -l` → `0` (0/16 Gemini files have a `tools:` field). A `tools:`-keyed guard is impossible on the Gemini surface; the prose-header binding works uniformly.
- Mutation proof (binds-to-prose is active, not incidental): on a /tmp copy of the real tree I added `MultiEdit` to `reviewer`'s `tools:` while keeping its RO header → Check 55 reported **0 failures** (the tool-list change did NOT flip the class). Real tree untouched.

This satisfies design §13.2's mandate ("Bind to the PROSE header, NEVER `tools:`") exactly, mirroring the Check 52 `pack-reviewer` precedent.

### (b) Check-number choice (55 + the 54-gap) — VERDICT: CORRECT and SAFE

Independently re-measured at HEAD `4226dc8`, 2026-06-14:
```
$ grep -oE 'Check [0-9]+' scripts/validate-pack.py | grep -oE '[0-9]+' | sort -n | uniq | tail
... 51 52 53 55 56
$ grep -rln 'Check 54|check-54|check_54' scripts/ .github/      # → (no hits)
$ grep -rln 'Check 55|check-55|check_55' scripts/ .github/
scripts/validate-pack.py
scripts/tests/test-validate-pack-check-55.sh
.github/workflows/validate-pack.yml
```
- Highest existing check = **56**. The 52/53/55/56 section-declaration set is present; **54 is genuinely unused** (zero references anywhere in `scripts/`+`.github/`) and is reserved for C8b's Guard-A′ (plan §B C8b / §F: "Check 54 (Guard-A′) lands LAST commit-wise (C8b)... number ≠ commit order").
- Check 55 is unique (no prior occupant) and is the number the plan reserved for Guard-B-project.
- The 54-gap until C8b lands is safe: I confirmed no validator/test requires contiguous check numbers — `grep -rn 'contiguous'` returns nothing relevant, and the run-before-wire (BD-184) validator keys on the test-file↔yml-invocation bijection, not on numeric contiguity. Numbers are assigned at authoring, not commit order; the gap is expected and tolerated.

---

## Independent re-verification (all at HEAD `4226dc8`, 2026-06-14)

**1. Green on arrival + load-bearing.**
```
$ python3 scripts/validate-pack.py ; echo EXIT $?
... OK: Check 55 — project RW/RO two-class set-equality holds: 16 agents × 3 CLIs ...
PASSED — all checks clean
EXIT 0
$ PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py ; echo EXIT $?
... Check 55 ... set-equality holds ...
DEEP EXIT 0
```
Load-bearing (mismatch caught), proven against a /tmp copy of the real tree (NO real-tree mutation, NO git checkout):
```
=== /tmp copy: flip coder.md Claude header RW->RO ===
FAILURES: 1
  Check 55 — class MISMATCH for `coder`: expected `RW` (PM-CHAT table + READONLY_AGENTS) ≠ prose header `RO` ...
=== confirm REAL tree untouched ===
$ grep -c 'Write-capable (scoped)' project-template/.claude/agents/coder.md → 1
=== /tmp copy: drop `planner` from READONLY_AGENTS ===
FAILURES: 1
  Check 55 — ... READONLY_AGENTS [...] ≠ expected RO set ...
$ grep -c '^    planner' project-template/agent-run.sh → 2   # real tree intact
```
The guard catches both a header-leg mismatch and an array-leg mismatch; the /tmp dir was removed after.

**2. Measure-then-bound (the 3 legs sized exactly).**
```
Leg 1 (PM-CHAT Read-only rows):  14   (+ coder Write-capable(scoped), repo-ops Write-capable(script))
Leg 2 (READONLY_AGENTS array):   14   (coder/repo-ops absent)
Leg 3 (prose headers, 48 files): 14 RO + 2 RW per CLI, all 3 CLIs identical
```
`_CHECK_55_PROJECT_AGENTS` (16), `_CHECK_55_RW_AGENTS = ("coder","repo-ops")`, `_CHECK_55_AGENT_DIRS` (3 CLIs) are sized to EXACTLY the measured set — no broader. The stray-token guard (`run_ro - set(_CHECK_55_PROJECT_AGENTS)`) bounds the array leg so an unknown token FAILs rather than silently widening the set. All three legs measure 14 RO + 2 RW; the codex `.toml` agents carry the same `**Read-only.**` prose header inside the file (14/14 confirmed), so the whole-file `_check_55_header_class` reads them uniformly.

**3. Runtime (ci-check-runtime-compounding).**
```
$ Check 55 isolated wall-time: 1.96 ms   (per-check WARN budget RUN_CHECK_PER_CHECK_WARN_BUDGET_S = 2000 ms)
$ grep -iE 'RUNTIME-BUDGET|exceeded|WARN.*budget' <full validate-pack output> → (none)
```
Single bounded pass: 48 agent reads + 1 PM-CHAT + 1 agent-run.sh = 50 reads; bounded `.split('|')` + set ops; NO whole-tree scan, NO subprocess-per-entry, NO regex backtracking. Registered via `run_check(...)` so the per-check + total-run runtime guards apply. ~0.1% of the per-check budget.

**4. Run-before-wire + encoding surfaces (enumerate-encoding-surfaces).**
```
$ bash scripts/tests/test-validate-pack-check-55.sh ; echo EXIT $?
  PASS validate-pack.py imports + Check 55 symbol registered
  PASS End-to-end synthetic-tree tests T1-T8 (...binds-to-prose-header-not-tools + no-tools-field case)
  PASS validate-pack.py exits 0; Check 55 runs and reports set-equality clean at HEAD
  PASS: 3   FAIL: 0   All tests passed.
EXIT 0
$ grep -c SyntaxWarning <test-output> → 0
```
yml wiring present (diff shows the sister-step after the Check-56 step, in the `tests:` job, `if: always()`). Check + test + yml all in this one commit half. The BD-184 run-before-wire validator (which FAILs an on-disk test with no yml invocation) is satisfied. The IMPL-REPORT's §13 embedded test is **byte-identical** to the on-disk file (`diff` clean, 292 lines each).

**5. Full CI (independent sample).** validate-pack EXIT 0 + DEEP EXIT 0 + check-55 EXIT 0 (above), plus a representative sample all EXIT 0:
```
test-validate-pack-check-52.sh: EXIT 0   (sibling Guard-B pack)
test-validate-pack-check-56.sh: EXIT 0   (adjacent Guard-C)
template-translations-test.sh:  EXIT 0   (agent-file parity ×3 CLIs)
test-persona-contracts.sh:      EXIT 0
```
(I did not re-run the entire 59-script battery; the IMPL-REPORT's full enumeration plus this sample + both validate-pack invocations is sufficient evidence of a green tree for a `pack-only` validator addition.)

**6. Scope (scope-deliverables-to-the-ask).**
```
$ git status --short
 M .github/workflows/validate-pack.yml
 M backlog/_toc.md            ← orchestrator/BD-219 work, NOT C6b
 M scripts/validate-pack.py
?? backlog/BD-219.md          ← orchestrator/BD-219 work, NOT C6b
?? maintenance-docs/v11-implementation/IMPL-REPORT-BD-197-C6a.md   ← pre-existing C6a artifact
?? maintenance-docs/v11-implementation/IMPL-REPORT-BD-197-C6b.md   ← this commit's report
?? maintenance-docs/v11-implementation/PACK-REVIEW-BD-197-C6a.md   ← pre-existing C6a artifact
?? scripts/tests/test-validate-pack-check-55.sh
```
The C6b in-scope edits are exactly `scripts/validate-pack.py` + `.github/workflows/validate-pack.yml` + the new `scripts/tests/test-validate-pack-check-55.sh` + the IMPL-REPORT. `backlog/_toc.md` / `backlog/BD-219.md` are the orchestrator's separate BD-219 open (correctly surfaced as NOT-mine in IMPL-REPORT §12 and left untouched). The C6a reports were present at session start. NO `project-template/` file is in the diff (`git status --short | grep project-template/` → none) — the project legs were READ-only. Manifest diff EMPTY, confirmed independently cp-safe (no git checkout):
```
$ cp test-fixtures/manifest.txt /tmp/manifest-backup-review.txt
$ bash test-fixtures/build.sh --all --clean → exit 0
$ git diff --quiet test-fixtures/manifest.txt → EMPTY
$ cp /tmp/manifest-backup-review.txt test-fixtures/manifest.txt → restored clean
```

---

## Findings

No BLOCKER / MUST / SHOULD findings.

### NIT-1 (informational; no fix required) — parity-of-approach note vs Check 52
Check 55 mirrors Check 52's structure (per-check constants, helper parsers, `_check_NN_header_class` discriminator binding to prose) but legitimately differs in two ways the spec demands: (1) Check 55 has THREE legs (PM-CHAT table + READONLY_AGENTS array + headers) vs Check 52's TWO (PACK-AGENTS `Class` column + headers); (2) the project SSOT is the PM-CHAT profile table read as a 2-cell `| name | Read-only |` row, whereas Check 52 reads a roster `Class` column. Both are correct for their surface (separation-of-concerns; native per-surface artifacts). No action — recorded so a future maintainer does not mistake the structural divergence for drift.

### NIT-2 (informational; no fix required) — `_check_55_header_class` ambiguity handling
`_check_55_header_class` returns `None` (→ a loud per-file FAIL) when a file carries BOTH an RW and an RO header, or NEITHER. This is the correct fail-loud behavior (T5 covers the NEITHER case). The BOTH case is not separately unit-tested, but it is structurally covered by the same `None` path and is an implausible authoring state. No action.

---

## Rules-Applied Verification Block

| # | Rule (as named in prompt) | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|---|
| 1 | ci-guard-design-measure-then-bound [verify] | Independently measured the 3 legs at HEAD `4226dc8`: PM-CHAT 14 RO + 2 RW; READONLY_AGENTS 14; prose headers 14 RO + 2 RW × 3 CLIs (codex toml 14/14 carry `**Read-only.**`). Constants sized to EXACTLY the 16-agent set + stray-token guard. Binds to prose proven load-bearing (reviewer/architect/auditor carry `Write,Edit` yet RO; Gemini 0/16 `tools:`; MultiEdit-add no-op). Mismatch caught on /tmp copy (`FAILURES: 1` for header-leg AND array-leg; real tree intact). | COMPLIANT |
| 2 | ci-check-runtime-compounding [verify] | Independently measured Check 55 wall-time `1.96 ms` (budget 2000 ms); no RUNTIME-BUDGET warning in full run; single bounded pass = 50 reads, no subprocess-per-entry, no whole-tree scan; registered via `run_check`. | COMPLIANT |
| 3 | enumerate-encoding-surfaces [verify] | Check source + new test + yml sister-step all changed in this one commit half (git diff confirms yml step after Check-56, `if: always()`; new test on disk; BD-184 bijection validator satisfied; embedded test byte-identical to file). | COMPLIANT |
| 4 | verify-full-ci-suite [universal] | Re-ran validate-pack EXIT 0 + DEEP EXIT 0 + check-55 EXIT 0 + sample (check-52/56, template-translations, persona-contracts) all EXIT 0. | COMPLIANT |
| 5 | empirical-evidence-blocks [reviewer] | Every claim above carries the command + verbatim output + HEAD `4226dc8` + date 2026-06-14 (check-number map, 3-leg measures, mismatch proof, binds-to-prose proof, wall-time, test run, manifest, scope). | COMPLIANT |
| 6 | scope-deliverables-to-the-ask [universal] | Verified C6b touches ONLY validate-pack.py + the yml + the new test + report; `git status` shows backlog/BD-219 + C6a reports as pre-existing NOT-mine; no `project-template/` in diff; manifest diff EMPTY (cp-safe). Surfaced two informational NITs, no invented blockers. | COMPLIANT |
| 7 | agents-never-commit [universal] | Read-only git only: `git rev-parse HEAD` → `4226dc84...`, `git rev-parse --abbrev-ref HEAD` → `v11-dev`, `git status`, `git diff`, `git log`. Manifest backup/restore via `cp`, NOT git checkout. NO add/commit/push/stage/apply/reset/restore/checkout. Wrote ONLY this review doc. | COMPLIANT |
| 8 | rules-applied-verification-block [universal] | This block; every row carries quoted/measured evidence; no empty cell. | COMPLIANT |

---

**End of PACK-REVIEW-BD-197-C6b.** VERDICT: **APPROVE.**
