# IMPL-REPORT — BD-197 C7b (PROJECT verb-parity guard, Guard-C project)

**Commit:** C7b — P3 project verb-parity guard extension (GUARD; `pack-only`)
**Repo:** optiquity-ai-agent-config-pack-v11-dev · **Branch:** v11-dev
**Base HEAD (pre-edit):** `345756944ed6f5cc4e224811d575aecf07c04af6` (`3457569`, C7a)
**Final HEAD (working tree):** `345756944ed6f5cc4e224811d575aecf07c04af6` (`3457569`)
  — agent ran ZERO state-changing git verbs; HEAD unchanged. The edits live
  UNSTAGED in the working tree; the orchestrator applies + commits.
**Regime:** IN-PLACE (no `/tmp` handoff dir named in the prompt). Verified via
  `git worktree list`: this is the `v11-dev` worktree at `3457569` (the C7a
  HEAD). Report written to the named parent-tree path. `git diff` emitted for
  auditability (read-only patch-emit; not staged, not applied).
**Date:** 2026-06-14

---

## 1. Read attestation (no skim, no derivation)

I READ THE FOLLOWING NAMED DOCS IN FULL before any edit (direct Reads /
targeted greps against the live files — no derivation from other sources):

- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md`
  — §5.1 (the exact DENIED verb set + backstop verb-precision, lines 274-284),
  §5.2 (allowed set + principle line, 286-290), §5.3 (where it lands incl.
  project-side, 292-310), §5.4 (CI guard verb-parity measure-then-bound, 312-313),
  §13 (measure-then-bound contract, 526-528), §13.1/§13.1a/§13.2/§13.3 (Guard
  A/A′/B/C, 530-547), §14 (architect-doc-vs-reality reconciliation, 551-569).
- `maintenance-docs/v11-implementation/PLAN-BD-197-WORKTREE-ISOLATION.md`
  — §B C7a (135-144), §B C7b (146-150), §B C8a/C8b (152-163, the boundary I do
  NOT touch), §C dependency graph + green-per-commit (167-192), §D full-CI-battery
  enumeration (196-214), §E guards measure-then-bound incl. Guard-C (218-253),
  §F empirical blocks EE-1/2/4/5/6/8/9/10 (257-330), §G manifest flags (348-357),
  §I coder spawn map incl. C7b row (397-414), §J3 decision-8 fold-vs-standalone
  (444), §J/§K standing items + out-of-scope (418-457).
- `scripts/validate-pack.py` — the EXISTING Guard-C **Check 56**
  (`_CHECK_56_VERB_PARITY_SURFACES` / `_CHECK_56_CANONICAL_VERBS` /
  `_CHECK_56_PRINCIPLE_PHRASE` / `_check_56_verb_present` /
  `check_destructive_git_verb_parity`, lines 8569-8722) + its registration
  (9181-9182) + the Check 55 project guard pattern (8725-8968) + the run_check /
  fail / ok helpers (406-463) + imports (289-297) + REPO_ROOT (299).
- `scripts/tests/test-validate-pack-check-56.sh` (the test pattern I mirrored).
- The PROJECT surfaces the guard asserts:
  `project-template/{CLAUDE,AGENTS,GEMINI}.md` "No destructive operations" rule
  (CLAUDE.md:364-380); the 48 agent Hard rules
  (`project-template/.{claude,codex,gemini}/agents/*` — sampled coder.md:95-103,
  auditor-architecture.toml:52, reviewer.md:39); `project-template/agent-run.sh`
  `--disallowedTools` (`CLAUDE_READONLY_FLAGS` 105-113, dispatch 508-510).
- `CLAUDE.md` § "## Pack memory" (the rules-in-force: ci-guard-design-measure-
  then-bound, ci-check-runtime-compounding, enumerate-encoding-surfaces,
  verify-full-ci-suite, edit-in-place, regenerate-manifest, empirical-evidence,
  preflight-stop-means-stop, agents-never-commit, scope-deliverables).
- Curated memory: `feedback_ci_guard_design_measure_then_bound.md`,
  `feedback_ci_check_runtime_compounding.md`, `feedback_verify_full_ci_suite.md`.

---

## 2. Fold-vs-new-check decision (decision 8 / §J3) — NEW standalone Check 57

**Decision: a NEW STANDALONE Check 57** — NOT folded into the existing Check 56
(Guard-C pack), and NOT a new Check 56-extension. Check 57 is the project analog
of Check 56, covering ONLY the project verb-enumeration surfaces.

**Check-number re-measurement (live, HEAD `3457569`):**
```
$ grep -oE 'Check [0-9]+' scripts/validate-pack.py | grep -oE '[0-9]+' | sort -n | uniq | tail -10
46 47 48 49 50 51 52 53 55 56
```
Highest existing = **56**. The plan's §F EE-6 (measured 52 at planning HEAD
`05ad61b`) is SUPERSEDED — Check 53 (Guard-A, C5), Check 56 (Guard-C pack, C5),
and Check 55 (Guard-B project, C6b) have since landed. **54 is reserved for
C8b's Guard-A′** (confirmed UNUSED: `grep 'Check 54' scripts/validate-pack.py`
→ no hit; the C5 coder's Check 56 comment explicitly notes "54 is reserved for
the C8b Guard-A′"). So the **next available number = 57** (verified UNUSED:
`grep -nE 'Check 57|check_57|_CHECK_57' scripts/validate-pack.py` → no hit). The
non-contiguous 54-gap until C8b is expected and tolerated (numbers ≠ commit
order; the C5/C6b coders established this precedent).

**Rationale (why standalone, not fold):**
The reconciled design §13.3 conceptually names ONE Guard-C spanning trinity +
commit-discipline ×3 + pack-coder ×3 + **project Hard rules + agent-run.sh
flags**. But the C5 coder (at the decision-8 coder's-call point) implemented
Check 56 as a PACK-FOCUSED guard sized to the FULL §5.1 **28-verb** set across
**10 PACK surfaces** that all carry the AGENT ABSOLUTE ban (a closed
enumeration). The PROJECT surfaces are HETEROGENEOUS in a way that makes folding
over-complicate Check 56 (exactly the decision-8 escape hatch the C5 coder cited
for keeping 56 standalone):

1. **Different canonical verb set.** The project-consistent verb set is a
   MEASURED 8-verb INTERSECTION (§3 below), NOT the 28-verb pack set. The
   project trinity carries the PM/human "No destructive operations — needs
   approval" rule (a SUBSET: working-tree/ref mutators only), while the agent
   files + launcher carry the agent ban (a wider but still different set). The
   intersection of what ALL project families enumerate is 8 verbs.
2. **Surface-conditional principle phrase.** The catch-all "including but not
   limited to" is TRINITY-ONLY on the project side (measured 3/52, §3); the 48
   agent files use a CLOSED "Forbidden: …" / "You MAY NOT run X, Y, Z"
   enumeration with no catch-all. Check 56 asserts the phrase on ALL 10 pack
   surfaces unconditionally — a folded check would need a per-surface conditional.
3. **Different surface count + format mix.** 52 project surfaces vs 10 pack.

Folding two different canonical verb sets + a surface-conditional principle
assertion into Check 56 would force it to model two structurally-different
surface families — the over-complication the decision-8 escape hatch exists for.
A separate, single-responsibility Check 57 is cleaner and keeps each guard
auditable. **C7b is therefore PRESENT (not dropped to 11 commits)** — the
"may-drop-if-folded" branch (plan §B C7b / §J3) does not apply.

---

## 3. Guard spec + measure-then-bound evidence

### 3.1 The asserted surfaces (52 project surfaces)
`_CHECK_57_TRINITY_SURFACES` (3) + 16 agents × 3 CLI dirs (48) +
`_CHECK_57_LAUNCHER_SURFACE` (1) = **52**.

```
$ # measured live HEAD 3457569
project-template/CLAUDE.md, AGENTS.md, GEMINI.md  (trinity, "No destructive operations")
project-template/.claude/agents/*.md   = 16   (Hard rules, git <verb> prose)
project-template/.codex/agents/*.toml  = 16   (Hard rules; 6 auditors use slash-list)
project-template/.gemini/agents/*.md   = 16   (Hard rules, git <verb> prose)
project-template/agent-run.sh          =  1   (CLAUDE_READONLY_FLAGS Bash(git <verb>:*))
```

### 3.2 Measure-then-bound: the asserted canonical verb set (8-verb intersection)

**Command (the full §5.1 28-verb candidate set scanned across all 52 surfaces
with the format-agnostic git-form matcher), HEAD `3457569`, 2026-06-14:**
```
CONSISTENT (present in ALL 52 surfaces): checkout, clean, merge, rebase,
                                         reset, restore, stash, worktree
```
`_CHECK_57_CANONICAL_VERBS = ("checkout","clean","merge","rebase","reset",
"restore","stash","worktree")` — the 8 working-tree/ref mutators that the
project trinity rule, the 48 agent Hard rules, AND the launcher
`--disallowedTools` ALL enumerate.

**Every EXCLUDED verb + why (measure-then-bound, each verified NOT consistent
across all 52 — asserting it would FALSE-FAIL a legitimately-divergent surface):**

| Excluded verb(s) | Measured | Why excluded |
|---|---|---|
| `commit`, `push`, `apply`, `tag` | trinity-absent 3/3 | The project TRINITY "No destructive operations" bullet is the human/PM needs-approval rule scoped to working-tree/ref mutators; publish/index ops + `git apply` live in the AGENT ban (which Check 56 already covers for pack; the agent files + launcher carry them), NOT the trinity. Not in the project-wide intersection. |
| `add` | trinity-absent 3/3 (FALSE-POSITIVE eliminated) | The only trinity "add" hit is the literal `git worktree` (add/remove/prune) parenthetical — a worktree-SUBCOMMAND description, NOT the `git add` verb. The matcher's ≥4-member slash-run rule correctly REJECTS that 3-member parenthetical, so `add` measures 49/52 (trinity-absent) and is EXCLUDED. (A naive bare-word matcher would FALSE-PASS it — see §3.3.) |
| `rm`, `mv` | 4/52, 1/52 | `rm`/`mv` are in the trinity + launcher but NOT the 48 agent Hard rules — not consistent. |
| `config`, `remote`, `gc`, `switch`, `cherry-pick`, `revert`, `am`, `update-ref`, `update-index`, `pull`, `filter-branch`, `replace`, `notes` | 0-19/52 | Not enumerated consistently (or at all) as project deny verbs; `config` matches only incidental prose ("config state"). |

The bound is sized to the measured-consistent intersection, **no broader** —
matching `ci-guard-design-measure-then-bound`. `git apply` (the §5.1 G-4
verb-precise deny) is intentionally NOT asserted here: it is in the agent ban +
launcher but NOT the trinity, so it is not in the project-wide intersection;
Check 56 (pack) already covers `apply` parity across the pack surfaces.

### 3.3 Format-agnostic matcher (the project format variety)

`_check_57_verb_present(text, verb)` handles the THREE project enumeration
shapes the design names:
- **(a) `git <verb>` prose** — the trinity bullet + the agent Hard rules
  (`git reset`, `git checkout`, …). Regex `git\s+<verb>(?![\w-])`.
- **(b) `Bash(git <verb>:*)` launcher flags** — `agent-run.sh`
  `CLAUDE_READONLY_FLAGS`. Matched by the SAME `git <verb>` rule (the string
  `Bash(git reset:` contains `git reset`).
- **(c) slash-separated `Forbidden: a/b/c/d` list** — the 6 Codex auditor
  `.toml` files (`auditor-architecture/-docs/-ops/-security/-tests/-ui.toml`)
  carry `Forbidden: add/commit/push/tag/rebase/merge/reset/restore/stash/
  checkout/clean/apply/worktree`. Matched by a slash-run of **≥4** verb tokens
  (regex `(?:[a-z][a-z-]*/){3,}[a-z][a-z-]*`), which DISTINGUISHES the deny
  list from the 3-member `(add/remove/prune)` worktree-subcommand parenthetical
  (so `add` is NOT a false positive — this is the load-bearing precision that
  excludes `add` in §3.2).

Word-boundary safe: `clean` ≠ "cleanup", `merge` ≠ "merged". The 6 Codex
auditors (the format-variety surfaces) are why the bare `git <verb>` form alone
measured only 46/52 for the core verbs; the slash-run alternative brings them to
52/52. Verified each of the 8 verbs hits 52/52 with this exact matcher.

### 3.4 Principle phrase (measure-then-bound, surface-scoped to the trinity)

```
$ grep -c 'including but not limited to' across 52 project surfaces
present in 3/52 (the 3 trinity files); 0/49 in the 48 agent files + launcher
```
`_CHECK_57_PRINCIPLE_PHRASE = "including but not limited to"` is asserted ONLY
on the 3 trinity surfaces (the OPEN needs-approval rule: "…destructive and needs
approval, including but not limited to the ones enumerated here"). The agent
files carry a CLOSED absolute enumeration with no catch-all, and the launcher is
a flag array — asserting the phrase on them would FALSE-FAIL, so it is bounded to
the trinity where it is the load-bearing close of the open denylist.

### 3.5 Green-on-arrival (the project verb data is committed in C7a)
```
$ python3 scripts/validate-pack.py ; echo $?
…
── Check 57: BD-197 PROJECT destructive-git-verb enumeration parity (Guard-C project) ──
  OK: Check 57 (Guard-C project) — destructive-git-verb enumeration parity holds
      across 52 project surface(s) (trinity ×3, 48 agent Hard rules [16 agents ×
      3 CLIs], agent-run.sh --disallowedTools): all 8 canonical project-
      consistent verbs present in each; the catch-all principle phrase present
      on each trinity surface.
PASSED — all checks clean
0
```
Also green under `PACK_VALIDATE_DEEP=1` (exit 0). C7a (`3457569`) made the
project verb enumeration consistent, so Check 57 is GREEN on arrival.

### 3.6 Mismatch-catch proof (injected project-surface verb-drop, /tmp, cp — NO real-tree mutation, NO git checkout)

I copied ALL 52 real project surfaces to a `/tmp` mirror (via `shutil.copy` =
`cp` of real content), then mutated ONLY the `/tmp` copy of `agent-run.sh` to
drop `git worktree` / `Bash(git worktree:*)`, then pointed `mod.REPO_ROOT` at the
`/tmp` tree and ran the check:
```
Failures raised: 1
FAIL: Check 57 (Guard-C project) — project-template/agent-run.sh is MISSING
destructive git verb(s) from the project-consistent denylist: worktree. …
MISMATCH-CATCH PROVEN: dropping 'git worktree' from agent-run.sh (in /tmp) FAILs Check 57.
```
Post-proof `git status --short project-template/` = EMPTY (NO real-tree
mutation; cp-based mirror only; no `git checkout` used anywhere).

The dedicated test (§4) additionally injects 4 more failure shapes (dropped verb
in trinity; dropped trinity catch-all phrase; absent surface; dropped verb in
the launcher `Bash(git <verb>:*)` form) — all proven to FAIL.

### 3.7 Wall-time (ci-check-runtime-compounding)
```
Check 57 wall-time: min=6.66ms max=8.53ms mean=7.44ms (5 runs)
Across ~202 validate-pack battery invocations: ~1.50s total
```
**Budget:** the per-check WARN budget (`RUN_CHECK_PER_CHECK_WARN_BUDGET_S`) and
the total-run budget are both comfortably met — 7.44ms per run is ~0.07% of a
typical multi-second general run. **Single-pass:** 52 single-file reads +
bounded regex tests per file. **No subprocess, no whole-tree scan, no
subprocess-per-entry storm** — the 48 agent files are read once each, no per-file
subprocess. Compounding-safe.

---

## 4. The per-check test + run-before-wire evidence

**New file:** `scripts/tests/test-validate-pack-check-57.sh` (executable,
`chmod +x`), mirroring the Check 56 test structure:
- **Group 0:** module import + Check 57 symbol registration (8 symbols).
- **Group 1:** synthetic-`/tmp`-tree end-to-end T1–T7:
  - T1 PASS — all 52 surfaces carry every verb (+ trinity catch-all phrase).
  - T2 FAIL — a trinity surface drops a verb (`worktree`) → names worktree+CLAUDE.md.
  - T3 FAIL — a trinity surface drops the catch-all principle phrase.
  - T4 FAIL — one surface absent.
  - T5 PASS — an AGENT file lacking the catch-all phrase is fine (phrase is
    trinity-only) → no false FAIL.
  - T6 PASS — word-boundary + slash-run safety (a 3-member `(add/remove/prune)`
    parenthetical + a `cleanup` token does NOT false-match) → a well-formed
    Codex slash-list surface PASSes.
  - T7 FAIL — the launcher `Bash(git <verb>:*)` form is honored: dropping a
    verb from the launcher flag block FAILs naming stash+agent-run.sh.
- **Group 2:** end-to-end `validate-pack.py` exit-status on HEAD (Check 57 clean).

**Run-before-wire ordering (decision 2):**
1. Authored the test → 2. RAN it locally (first run surfaced the BD-184
   un-wired-test guard FAIL — the expected run-before-wire signal — plus 2
   heredoc-escaping test bugs I fixed; the GUARD itself reported OK throughout)
   → 3. WIRED it into `.github/workflows/validate-pack.yml` `tests` job (sister
   step after the Check 55 step) → 4. RE-RAN the full battery.

**Final test run (post-wire), quoted exit:**
```
$ bash scripts/tests/test-validate-pack-check-57.sh ; echo $?
  PASS validate-pack.py imports + Check 57 symbols registered
  PASS End-to-end synthetic-tree tests T1-T7 (parity PASS + dropped-verb/
       dropped-trinity-phrase/absent-surface FAIL + trinity-only-phrase +
       word-boundary/slash-run safety + launcher-form honored)
  PASS validate-pack.py exits 0; Check 57 runs and reports project verb-parity clean at HEAD
  PASS: 3   FAIL: 0   →  All tests passed.
0
```

**macOS bash 3.2 / BSD compatibility:** the test uses `set -u`, `printf`, `case`,
`(( ))`, and heredocs — no GNU-only flags, no bash-4 features. Backticks were
removed from the unquoted-heredoc Python body builders (they would be
shell-interpreted) — the matcher keys on `git <verb>` prose, not backtick fences.

---

## 5. FULL CI SUITE results (no sampling — every wired script, quoted exit)

Every script wired in `.github/workflows/validate-pack.yml` was run locally and
its exit status quoted. **Total: 2 validate-job invocations + 64 tests-job
scripts = 66 invocations, all EXIT 0.**

**validate job (2):**
| Script | EXIT |
|---|---|
| `python3 scripts/validate-pack.py` | 0 |
| `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | 0 |

**tests job (64) — all EXIT 0:**
- Part 1 (17): test-detect; tracker-{provider,config,init,agent-read,migrate-
  forward,migrate-reverse,migrate-roundtrip}-test; test-tracker-{phase-task,
  links,cycle-check}; tracker-{errors,config-schema}-test;
  recommendation-state-schema-test; test-per-entry. **17/17 PASS.**
- Part 2 (22): test-validate-pack-checks-32-33-34, -36-37-38; -check-{39,40,41,
  18,16,19,42,43,44,45,46}; -removed-doc-advisory; -49-field-faithfulness;
  -50-codec-single-source; -51-flip-block; -52; -53; **-56**; -55; **-57**.
  **22/22 PASS** (incl. the new Check 57 test + the unchanged Check 56 test).
- Part 3 (17): tracker-deferral-gate; tracker-bd{129,130,132,133,134}; 
  recommendation; pack-help; test-customization-preserve; test-init-project;
  test-migrate-v10-to-v11{,-dry-run,-gates,-decompose}; test-migrator-{core,
  manifest,capability-translation}. **17/17 PASS.**
- Part 4 (8): build.sh --all --clean; build.sh --verify; test-v11-realistic-ot;
  test-migrator-skills; test-persona-contracts; template-translations-test;
  template-version-test; test-issue-forms. **8/8 PASS.**

**Note on the CI manifest-reset step:** the yml's tests-job runs
`git checkout HEAD -- test-fixtures/manifest.txt` between `build.sh --all --clean`
and `build.sh --verify`. As an agent I MUST NOT run `git checkout` (denied verb);
I substituted `cp /tmp/manifest-backup-c57.txt test-fixtures/manifest.txt`
(restore-from-cp-backup), which achieves the identical effect (committed manifest
state restored before `--verify`). `build.sh --verify` passed (EXIT 0).

`test-v11-realistic-ot.sh` (the validator-output/banner pins — the BD-203/214
trap) PASSED, confirming Check 57's new banner did not break a stale assertion.

---

## 6. Manifest determination (regenerate-manifest-v11-surface — cp, NOT git checkout)

C7b touches `scripts/` (a v11-surface dir) → manifest regen REQUIRED.
```
$ cp test-fixtures/manifest.txt /tmp/manifest-backup-c57.txt   # cp backup (NOT git checkout)
$ bash test-fixtures/build.sh --all --clean ; echo $?          # 0
$ git status --short test-fixtures/manifest.txt                 # (empty)
$ diff /tmp/manifest-backup-c57.txt test-fixtures/manifest.txt  # MANIFEST UNCHANGED (byte-identical)
```
**Determination: manifest diff is EMPTY → stage NOTHING** (expected — validate-
pack.py + its test + the yml do not project into client fixtures, same as the
C6b guard-half precedent S-2). Confirmed cp-based regen, NOT `git checkout`.

---

## 7. Files changed inventory

| Path | Change | Lines |
|---|---|---|
| `scripts/validate-pack.py` | MODIFIED (new Check 57: comment block + 8 module constants + `_check_57_verb_present` + `check_project_destructive_git_verb_parity` + `run_check` registration) | +257 |
| `.github/workflows/validate-pack.yml` | MODIFIED (new `tests`-job step wiring `test-validate-pack-check-57.sh`, after the Check 55 step) | +3 |
| `scripts/tests/test-validate-pack-check-57.sh` | NEW (per-check test, executable) | +281 (new file) |

No other files touched. `test-fixtures/manifest.txt` regenerated but byte-
identical (not staged). The two `IMPL-REPORT-BD-197-C7a.md` /
`PACK-REVIEW-BD-197-C7a.md` untracked files PRE-EXISTED this session (C7a
artifacts; the orchestrator bundles them — NOT mine).

**Full content of the new file is preserved in §11 (so the orchestrator can
re-apply without re-deriving).** The validate-pack.py additions + the yml delta
are in the emitted `git diff` (read-only patch-emit; not staged, not applied).

---

## 8. Boundary discipline check (P-missed-7 / boundary-investigation)

C7b makes ZERO project-side edits — it adds a PACK-side validator + test + yml
wiring (`scripts/`, `.github/`). Confirmed:
```
$ git diff --name-only | grep -E 'project-template/|supporting-docs/'
(no output) — CLEAN: no project-template/ or supporting-docs/ edits (pack-only)
```
The new code REFERENCES project-side paths (the 52 surfaces it ASSERTS), which is
legitimate pack-side construction of a CI guard over a client surface (Check 56,
55, 52, 37 all do the same) — it does NOT import a pack-only mechanism INTO a
project surface, and it does NOT edit a project surface. The
project-side-edit pre-flight (identify project-side SSOT before editing) does
NOT trigger because there are no project-side edits. **No boundary-discipline
stop.**

`pack-only` Check-36 scope verified: the only changed paths are
`scripts/validate-pack.py`, `scripts/tests/test-validate-pack-check-57.sh`,
`.github/workflows/validate-pack.yml` — all outside `project-template/` +
`supporting-docs/`, so the `pack-only` keyword is honest (Check 36 self-verifies
this on commit; the validate-pack run was green).

---

## 9. Plan deviations

**None material.** One reconciliation against the plan's stated measurements (an
expected re-measure-at-commit, not a deviation):

- Plan §F EE-6 measured "highest Check = 52" at planning HEAD `05ad61b` and
  projected the new guards as 53/55/54/**56**. By C7b's HEAD `3457569`, Check 53
  / 56 / 55 had all landed (C5/C6b), so the next available is **57**, not the
  plan's projected number. The plan explicitly mandates re-measuring at
  commit-time (§K "the C5/C8a/C8b coders re-measure AGAIN at commit-time …
  never trust this plan's static enumerations"), which I did. The 54-gap until
  C8b is the plan-expected reservation. This is the re-measure mandate realized,
  not a deviation.
- The plan's §B C7b "may be EMPTY → DROPPED if folded" branch did NOT fire,
  because the C5 coder made Check 56 standalone (not folded into an existing
  parity check), and folding the project surfaces into Check 56 over-complicates
  (§2). C7b is PRESENT (standalone Check 57) — the plan's primary "IF standalone,
  extend it for project surfaces in C7b" path (§E Guard-C). I authored a separate
  Check 57 rather than EXTENDING Check 56, because the project surfaces need a
  different canonical set + a trinity-only catch-all (§2) — "extend Check 56"
  would have re-introduced the heterogeneity over-complication the decision-8
  escape hatch exists to avoid. This is within decision-8's coder's-call latitude
  ("EXTEND Check 56 … OR author a NEW standalone check — pick whichever is
  cleaner + measure-then-bound").

---

## 10. New POQs introduced

**None.** No architecture gap found; the design §13.3 + plan §E/§J3 gave full
latitude for the fold-vs-standalone + extend-vs-new-check decision, which I
exercised with measure-then-bound rationale.

**One observation surfaced (not a fix, not in scope — for Pack Chat awareness):**
The reconciled design §13.3 names ONE conceptual Guard-C spanning BOTH pack and
project surfaces, but the realized implementation is now TWO checks: Check 56
(pack, 28 verbs, 10 surfaces) + Check 57 (project, 8-verb intersection, 52
surfaces). This is the correct measure-then-bound outcome (the two surface
families have genuinely different consistent verb sets), and it matches the
decision-8 coder's-call latitude — but if a future architect-doc-reality
reconciliation pass runs (per `architect-doc-reality-reconciliation`), §13.3
could note the realized split (Check 56 + Check 57) as the two consumers. I did
NOT edit the design doc (out of C7b scope; the orchestrator/architect owns doc
reconciliation). Surfaced per `scope-deliverables-to-the-ask` (not silently
fixed, not silently ignored).

---

## 11. Full content of the new file (`scripts/tests/test-validate-pack-check-57.sh`)

> The validator additions to `scripts/validate-pack.py` + the yml delta are in
> the emitted `git diff` (read-only). The NEW test file is reproduced here in
> full so the orchestrator can re-apply without re-deriving.

```bash
#!/usr/bin/env bash
# scripts/tests/test-validate-pack-check-57.sh — dedicated test for
# BD-197 Check 57 (PROJECT destructive-git-verb enumeration parity,
# Guard-C project).
#
# Check 57 is the PROJECT analog of Check 56 (Guard-C pack). It asserts the
# project-consistent canonical verb set — the measured 8-verb intersection
# checkout/clean/merge/rebase/reset/restore/stash/worktree — appears in every
# project surface that enumerates the No-destructive / agents-never-commit ban
# (project trinity ×3 + the 48 per-agent Hard rules [16 agents × 3 CLIs] +
# agent-run.sh --disallowedTools = 52 surfaces), and that the catch-all
# principle phrase (`including but not limited to`) appears on each of the 3
# trinity surfaces (the open needs-approval rule; the agent files + launcher
# carry a closed enumeration with no catch-all — measure-then-bound,
# surface-scoped). Standalone Check 57 per decision 8 (folding into Check 56
# over-complicates: different canonical verb set + a trinity-only catch-all).
# Format-agnostic matcher: `git <verb>` prose (trinity + agent Hard rules) /
# `Bash(git <verb>:*)` launcher / Codex slash-list `Forbidden: a/b/c/d`.
#
# This test proves the guard PASSes when all 52 surfaces carry the full set
# and FAILs when a verb is dropped from one surface OR the trinity catch-all
# phrase is missing OR a surface is absent — all in a synthetic /tmp tree (it
# NEVER mutates the real tree).
#
# Coverage:
#   Group 0: module import + Check 57 symbol registration
#   Group 1: synthetic-tree end-to-end (mod.REPO_ROOT pointed at /tmp):
#            T1 PASS — all 52 surfaces carry every verb (+ trinity phrase)
#            T2 FAIL — one surface drops a verb (e.g. `worktree` in trinity)
#            T3 FAIL — a trinity surface drops the catch-all principle phrase
#            T4 FAIL — one surface absent
#            T5 PASS — an agent file (NOT trinity) lacks the catch-all phrase
#                      (the phrase is asserted ONLY on the trinity → no FAIL)
#            T6 PASS — word-boundary + slash-run safety: `cleanup` ≠ `clean`,
#                      and a 3-member `(add/remove/prune)` parenthetical does
#                      NOT false-match `add` (which is not an asserted verb
#                      anyway) — a well-formed Codex slash-list surface PASSes
#            T7 FAIL — the launcher form `Bash(git <verb>:*)` is honored:
#                      dropping a verb from the launcher flag block FAILs
#   Group 2: end-to-end validate-pack.py exit-status on HEAD (Check 57 clean)
#
# Usage: bash scripts/tests/test-validate-pack-check-57.sh

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VALIDATE="$REPO_ROOT/scripts/validate-pack.py"

PASS=0
FAIL=0
t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() {
    FAIL=$((FAIL + 1))
    printf "  \033[31mFAIL\033[0m %s\n" "$1"
    [[ -n "${2:-}" ]] && printf "       %s\n" "$2"
}

# ─────────────────────────────────────────────────────────────────
# Group 0: module import + symbol registration
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 0: Module import + Check 57 symbol registration ===\n"

python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
required = [
    'check_project_destructive_git_verb_parity',
    '_check_57_verb_present',
    '_CHECK_57_TRINITY_SURFACES',
    '_CHECK_57_PROJECT_AGENTS',
    '_CHECK_57_AGENT_DIRS',
    '_CHECK_57_LAUNCHER_SURFACE',
    '_CHECK_57_CANONICAL_VERBS',
    '_CHECK_57_PRINCIPLE_PHRASE',
]
missing = [n for n in required if not hasattr(mod, n)]
if missing:
    print('FAIL_MISSING ' + ' '.join(missing))
    sys.exit(1)
print('OK')
" > /tmp/vp-check57-import.out 2>&1

if grep -q "^OK$" /tmp/vp-check57-import.out; then
    t_pass "validate-pack.py imports + Check 57 symbols registered"
else
    t_fail "validate-pack.py import or Check 57 symbol registration failed" \
        "$(cat /tmp/vp-check57-import.out)"
fi

# ─────────────────────────────────────────────────────────────────
# Group 1: synthetic-tree end-to-end (PASS + injected-FAIL cases)
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 1: End-to-end synthetic-tree tests ===\n"

python3 <<EOF
import sys, tempfile, pathlib, shutil, io, contextlib
sys.path.insert(0, '$REPO_ROOT/scripts')
import importlib.util
spec = importlib.util.spec_from_file_location('vp', '$VALIDATE')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

failures = []

VERBS = list(mod._CHECK_57_CANONICAL_VERBS)
PHRASE = mod._CHECK_57_PRINCIPLE_PHRASE
TRINITY = list(mod._CHECK_57_TRINITY_SURFACES)
AGENTS = list(mod._CHECK_57_PROJECT_AGENTS)
AGENT_DIRS = list(mod._CHECK_57_AGENT_DIRS)
LAUNCHER = mod._CHECK_57_LAUNCHER_SURFACE

# Build the full surface list the check walks: trinity ×3 + 48 agents + launcher.
def all_surfaces():
    s = list(TRINITY)
    for dir_rel, ext in AGENT_DIRS:
        for a in AGENTS:
            s.append(f"{dir_rel}/{a}.{ext}")
    s.append(LAUNCHER)
    return s

def trinity_body(verbs=None, include_phrase=True):
    """A well-formed trinity 'No destructive operations' bullet: every verb as
    a git-verb token + the catch-all principle phrase. (No backticks — this
    body is built inside an unquoted heredoc; the matcher keys on 'git <verb>'
    prose, not on backtick fences.)"""
    vs = VERBS if verbs is None else verbs
    lines = ["- No destructive operations without explicit approval. Before"]
    lines += [f"  any git {v}," for v in vs]
    if include_phrase:
        lines.append(f"  read-only git verbs are allowed; {PHRASE} the ones enumerated.")
    return "\n".join(lines) + "\n"

def agent_prose_body(verbs=None):
    """A well-formed agent Hard rule (Claude/Gemini .md prose form). No
    backticks (unquoted heredoc)."""
    vs = VERBS if verbs is None else verbs
    lst = ", ".join(f"git {v}" for v in vs)
    return ("- No state-changing git operations, ever. Read-only git verbs "
            f"only. You MAY NOT run {lst}. Inspect via git show <ref>:<path>.\n")

def codex_slash_body(verbs=None):
    """A well-formed Codex auditor .toml Hard rule (slash-list form)."""
    vs = VERBS if verbs is None else verbs
    # >=4-member slash list so the matcher's slash-run rule applies.
    return ("- **No state-changing git operations, ever.** Read-only git verbs "
            f"only (status/diff/log/show). Forbidden: {'/'.join(vs)}.\n")

def launcher_body(verbs=None):
    """A well-formed agent-run.sh launcher flag block (Bash(git <verb>:*))."""
    vs = VERBS if verbs is None else verbs
    flags = " ".join(f'"Bash(git {v}:*)"' for v in vs)
    return f"CLAUDE_READONLY_FLAGS=(\n    \"--disallowedTools\"\n    {flags}\n)\n"

def body_for(surface, verbs=None, include_phrase=True):
    if surface in TRINITY:
        return trinity_body(verbs=verbs, include_phrase=include_phrase)
    if surface == LAUNCHER:
        return launcher_body(verbs=verbs)
    if surface.endswith(".toml"):
        return codex_slash_body(verbs=verbs)
    return agent_prose_body(verbs=verbs)

def run(overrides=None, drop_surface=None):
    """overrides: {surface: body_text}; drop_surface: a surface to OMIT."""
    overrides = overrides or {}
    tmpdir = tempfile.mkdtemp(prefix="vp-check57-")
    root = pathlib.Path(tmpdir)
    for s in all_surfaces():
        if s == drop_surface:
            continue
        p = root / s
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(overrides.get(s, body_for(s)))
    saved_root = mod.REPO_ROOT
    saved_failures = list(mod.failures)
    mod.failures.clear()
    mod.REPO_ROOT = root
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            mod.check_project_destructive_git_verb_parity()
        n = len(mod.failures)
        cap = buf.getvalue()
    finally:
        mod.REPO_ROOT = saved_root
        mod.failures.clear()
        mod.failures.extend(saved_failures)
        shutil.rmtree(tmpdir, ignore_errors=True)
    return n, cap

# T1: PASS — all 52 surfaces carry every verb (+ trinity catch-all phrase).
n, cap = run()
if n != 0:
    failures.append(f"T1 (all consistent) expected PASS, got {n}: {cap}")

# T2: FAIL — a trinity surface drops a verb (worktree).
short = [v for v in VERBS if v != "worktree"]
n, cap = run(overrides={"project-template/CLAUDE.md": trinity_body(verbs=short)})
if n < 1 or "worktree" not in cap or "CLAUDE.md" not in cap:
    failures.append(f"T2 (dropped verb in trinity) expected FAIL naming worktree+CLAUDE.md, got {n}: {cap}")

# T3: FAIL — a trinity surface drops the catch-all principle phrase.
n, cap = run(overrides={"project-template/AGENTS.md": trinity_body(include_phrase=False)})
if n < 1 or "principle phrase" not in cap or "AGENTS.md" not in cap:
    failures.append(f"T3 (dropped trinity phrase) expected FAIL, got {n}: {cap}")

# T4: FAIL — one surface absent.
n, cap = run(drop_surface="project-template/.gemini/agents/coder.md")
if n < 1 or "not found" not in cap:
    failures.append(f"T4 (absent surface) expected FAIL, got {n}: {cap}")

# T5: PASS — an AGENT file (not trinity) lacking the catch-all phrase is fine
# (the phrase is asserted ONLY on the trinity). The agent prose body carries
# every verb but no catch-all phrase → still PASSes.
n, cap = run()  # agent_prose_body never includes PHRASE by construction
if n != 0:
    failures.append(f"T5 (agent lacks catch-all, asserted trinity-only) expected PASS, got {n}: {cap}")

# T6: PASS — word-boundary + slash-run safety. A Codex slash-list surface with
# an extra benign 3-member parenthetical (add/remove/prune) and a cleanup
# token still carries every real verb, so it PASSes; no false verb match.
codex_safe = codex_slash_body() + (
    "Note: worktree (add/remove/prune) cleanup is described, not a deny verb.\n")
n, cap = run(overrides={"project-template/.codex/agents/reviewer.toml": codex_safe})
if n != 0:
    failures.append(f"T6 (word-boundary/slash-run safety) expected PASS, got {n}: {cap}")

# T7: FAIL — the launcher Bash(git <verb>:*) form is honored: drop a verb from
# the launcher flag block → FAIL naming the launcher + the dropped verb.
n, cap = run(overrides={LAUNCHER: launcher_body(verbs=[v for v in VERBS if v != "stash"])})
if n < 1 or "stash" not in cap or "agent-run.sh" not in cap:
    failures.append(f"T7 (dropped verb in launcher Bash(git ...:*) form) expected FAIL naming stash+agent-run.sh, got {n}: {cap}")

if failures:
    print("FAILURES")
    for f in failures:
        print(" ", f)
    sys.exit(1)
print("OK")
EOF
case $? in
    0) t_pass "End-to-end synthetic-tree tests T1-T7 (parity PASS + dropped-verb/dropped-trinity-phrase/absent-surface FAIL + trinity-only-phrase + word-boundary/slash-run safety + launcher-form honored)" ;;
    *) t_fail "End-to-end check_project_destructive_git_verb_parity tests failed (see Python output)" ;;
esac

# ─────────────────────────────────────────────────────────────────
# Group 2: end-to-end validate-pack.py exit-status on HEAD
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 2: End-to-end validate-pack.py exit-status on HEAD ===\n"

if python3 "$REPO_ROOT/scripts/validate-pack.py" > /tmp/vp-check57-e2e.out 2>&1; then
    if grep -q "Check 57: BD-197 PROJECT destructive-git-verb enumeration parity" /tmp/vp-check57-e2e.out \
       && grep -q "Check 57 (Guard-C project) — destructive-git-verb enumeration parity holds" /tmp/vp-check57-e2e.out; then
        t_pass "validate-pack.py exits 0; Check 57 runs and reports project verb-parity clean at HEAD"
    else
        t_fail "validate-pack.py exits 0 but Check 57 clean-output not detected" \
            "Tail: $(tail -10 /tmp/vp-check57-e2e.out)"
    fi
else
    if grep -q "Check 57: BD-197 PROJECT destructive-git-verb enumeration parity" /tmp/vp-check57-e2e.out; then
        t_fail "validate-pack.py exits non-zero on HEAD (Check 57 ran but found a violation)" \
            "Tail: $(tail -40 /tmp/vp-check57-e2e.out)"
    else
        t_fail "validate-pack.py exits non-zero on HEAD (Check 57 did not run)" \
            "Tail: $(tail -40 /tmp/vp-check57-e2e.out)"
    fi
fi

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────
printf "\n=== Summary ===\n"
printf "  PASS: %d\n" "$PASS"
printf "  FAIL: %d\n" "$FAIL"
if (( FAIL == 0 )); then
    printf "\n\033[32mAll tests passed.\033[0m\n"
    exit 0
else
    printf "\n\033[31m%d test(s) failed.\033[0m\n" "$FAIL"
    exit 1
fi
```

---

## 12. Definition-of-Done checklist

| Item | Status | Evidence |
|---|---|---|
| Fold-vs-new-check decision made + recorded + check number | PASS | §2 — NEW standalone Check 57; live re-measure (highest=56, 54 reserved, 57 next) |
| Project verb-parity guard implemented (52 surfaces) | PASS | §3.1 — trinity ×3 + 48 agents + agent-run.sh |
| Format-agnostic matcher (prose / Bash(git…:*) / slash-list) | PASS | §3.3 — `_check_57_verb_present` handles all 3; ≥4-member slash-run precision |
| Measure-then-bound (sized to measured project verb set) | PASS | §3.2 — 8-verb intersection; every excluded verb + why |
| Unassertable-element rationale recorded | PASS | §3.4 — principle phrase trinity-only; §3.2 — apply/commit excluded |
| Green on arrival (general + deep, exit 0) | PASS | §3.5 — Check 57 OK; PASSED all checks |
| Mismatch-catch proven (injected drop, /tmp, no real-tree, no git checkout) | PASS | §3.6 — agent-run.sh worktree-drop FAILs; project-template clean |
| Runtime: single-pass, runtime-guarded, no subprocess-per-entry | PASS | §3.7 — 7.44ms/run; 52 single-file reads; no subprocess |
| New per-check test authored | PASS | §4 / §11 — test-validate-pack-check-57.sh (T1-T7) |
| Run-before-wire (author→run→wire→re-run battery, SAME commit) | PASS | §4 — ordering documented; final exit 0 |
| Test wired into validate-pack.yml tests job | PASS | §7 — +3 lines after Check 55 step |
| FULL CI suite run, every script, quoted exit, no sampling | PASS | §5 — 66 invocations, all EXIT 0 |
| enumerate-encoding-surfaces lockstep (check + test + yml, 1 commit) | PASS | §7 — all 3 in one change set |
| Manifest regen (cp, not git checkout; stage iff non-empty) | PASS | §6 — byte-identical → stage nothing; cp confirmed |
| Scope (C7b only; no C8a/C8b; no project-side edits) | PASS | §8 — pack-only; no project-template/ edits |
| edit-in-place (no wholesale rewrite of validate-pack.py) | PASS | targeted Edit insertions after Check 55 + at registration |
| No state-changing git verb run | PASS | §13 RAVB — only read-only git + cp; HEAD unchanged |

---

## 13. Rules-Applied Verification Block

| Rule (as named in prompt) | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| ci-guard-design-measure-then-bound | The guard is sized to the MEASURED 8-verb project intersection `{checkout,clean,merge,rebase,reset,restore,stash,worktree}` (§3.2 — measured present 52/52 with the format-agnostic matcher); EVERY excluded verb categorized with why (commit/push/apply/tag trinity-absent; `add` false-positive eliminated by the ≥4-member slash-run rule; rm/mv/config/… not consistent); the principle-phrase assertion measured-and-bounded to the 3 trinity surfaces (3/52); the matcher is format-agnostic (§3.3) and catches a mismatch (§3.6 — agent-run.sh worktree-drop → 1 FAIL naming verb+surface). | COMPLIANT |
| ci-check-runtime-compounding | Single-pass: 52 single-file reads + bounded regex per file; "NO subprocess, NO whole-tree scan, NO per-entry subprocess storm" (the 48 agent files read once each). Wall-time measured: mean 7.44ms/run, ~1.50s across the ~202-invocation battery (§3.7). Routed through `run_check` (the per-check + total-run budget harness). | COMPLIANT |
| enumerate-encoding-surfaces | The check (`scripts/validate-pack.py` Check 57 + registration), its test (`scripts/tests/test-validate-pack-check-57.sh`), and the yml wiring (`.github/workflows/validate-pack.yml` step) all in LOCKSTEP, this ONE change set (§7 files-changed inventory — 3 paths). The `_CHECK_57_PROJECT_AGENTS`/`_CHECK_57_AGENT_DIRS` tuples carry the "add a new agent/CLI here in lock-step else blind spot" note (mirrors Check 55). | COMPLIANT |
| verify-full-ci-suite | EVERY wired script run, no sampling: 2 validate-job invocations (general + `PACK_VALIDATE_DEEP=1`, both exit 0) + 64 tests-job scripts (all exit 0) = 66 invocations, quoted in §5. Run-before-wire honored (§4 — new test run + quoted exit 0 BEFORE wiring, then full battery re-run). `test-v11-realistic-ot.sh` (the banner-pin trap) PASSED — the new Check 57 banner did not break a stale assertion. | COMPLIANT |
| edit-in-place-not-full-rewrite | Targeted `Edit` insertions into `scripts/validate-pack.py` (new Check 57 block inserted after Check 55's `ok(...)`; registration inserted after the Check 55 `run_check`) + targeted `Edit` into the yml (one new step after the Check 55 step). NO wholesale rewrite. `git diff --stat`: validate-pack.py +257 (additions only, 0 deletions), yml +3. | COMPLIANT |
| regenerate-manifest-v11-surface | `cp` backup → `bash test-fixtures/build.sh --all --clean` (exit 0) → `git status --short test-fixtures/manifest.txt` EMPTY → `diff` byte-identical → STAGE NOTHING (§6). cp used (NOT git checkout) for backup/restore. The CI's `git checkout HEAD -- manifest.txt` step substituted by cp in my local battery (§5 note). | COMPLIANT |
| empirical-evidence-blocks | Every state-claim backed by command + verbatim output + HEAD-SHA `3457569` + date 2026-06-14: §2 (check-number grep), §3.2 (verb consistency scan), §3.4 (principle-phrase grep), §3.5 (validate-pack OK), §3.6 (mismatch-catch failures-raised), §3.7 (wall-time), §5 (66-invocation battery), §6 (manifest diff), §8 (scope grep). | COMPLIANT |
| preflight-stop-means-stop | Emitted the single PREFLIGHT line ("project verb-parity guard (new Check 57) + test complete; green on arrival; mismatch-catch proven; FULL CI battery PASS; manifest empty; HEAD 3457569; about to Write IMPL-REPORT…") only AFTER all edits + the full battery + the new test PASSED. No parent stop/halt message received. | COMPLIANT |
| agents-never-commit | ZERO state-changing git verbs run. Only read-only git used: `git rev-parse`, `git status`, `git worktree list`, `git diff` (the patch-emit). cp (not `git checkout`) used for manifest backup/restore + the mismatch-catch mirror. HEAD unchanged (`3457569` before and after). Edits left UNSTAGED in the working tree; the orchestrator applies + commits. | COMPLIANT |
| scope-deliverables-to-the-ask | C7b = the project verb-parity guard + its test ONLY. Did NOT do C8a/C8b (Guard-A′ / OPTIONAL-FEATURES), did NOT touch project surfaces or the C7a audit docs (§8 — no project-template/ edits; the two C7a untracked .md files pre-existed and are the orchestrator's to bundle). One out-of-scope observation surfaced not fixed (§10 — design §13.3 realized as Check 56 + Check 57). | COMPLIANT |
| rules-applied-verification-block | This block. Every rules-in-force rule addressed with quoted/measured evidence; no empty cell; no AMBIGUOUS terminal state. | COMPLIANT |

---

**IMPL-READY: YES.** Check 57 (Guard-C project) authored as a standalone check
(decision 8 / §J3 coder's-call), sized measure-then-bound to the 8-verb project
intersection across 52 surfaces, format-agnostic across the 3 project
enumeration shapes, green on arrival, mismatch-catch proven, full CI battery
green (66/66 invocations exit 0), manifest byte-identical (no stage), pack-only
scope clean. Edits are UNSTAGED in the working tree at HEAD `3457569`; the `git
diff` is emitted (read-only) for the orchestrator's review/apply/commit cycle.
