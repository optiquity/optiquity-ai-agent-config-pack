# PACK-REVIEW — BD-197 C7b (PROJECT verb-parity guard, Check 57)

## VERDICT: APPROVE

Check 57 is correct, measure-then-bound to a verified 8-verb project
intersection, format-agnostic across all three project enumeration shapes,
green on arrival, mismatch-catch independently proven, full CI sample green,
and pack-only scope clean — I found no BLOCKER or MUST; two minor NITs below
do not block.

**Reviewer:** fresh pack-reviewer · **Regime:** IN-PLACE (report written to the
named parent-tree path; report is my SOLE write) · **HEAD:** `3457569`
(`345756944ed6f5cc4e224811d575aecf07c04af6`, unchanged) · **Date:** 2026-06-14
· **Branch:** v11-dev · **Read-only git only** (`rev-parse`, `status`, `diff`,
`log`); zero state-changing verbs.

---

## Read attestation

Read IN FULL before reviewing (direct Reads / targeted greps against live
files — no derivation):
- `ARCHITECTURE-BD-197-WORKTREE-ISOLATION-RECONCILED.md` §5.1 (denied set +
  G-4 verb-precision), §5.2 (allowed set + principle line), §5.3 (where it
  lands incl. project-side launcher), §5.4 (CI guard measure-then-bound),
  §13 + §13.3 (Guard-C verb-parity, "MAY fold... prefer fewer checks"), §14
  (architect-doc-reality reconciliation).
- `PLAN-BD-197-WORKTREE-ISOLATION.md` §B C7a/C7b/C8a/C8b, §E Guard-C
  (measure-then-bound steps), §J3 decision-8 (CODER'S CALL fold-vs-standalone),
  §I C5/C7b coder rows, §K out-of-scope.
- `scripts/validate-pack.py` — the new Check 57 (constants + `_check_57_verb_present`
  + `check_project_destructive_git_verb_parity` + registration) AND the existing
  Check 56 (the fold-vs-new comparison baseline, lines 8569-8722 + reg 9421-9422).
- The `git diff` of `scripts/validate-pack.py` + `.github/workflows/validate-pack.yml`.
- `scripts/tests/test-validate-pack-check-57.sh` (full).
- `project-template/CLAUDE.md` "No destructive operations" trinity rule
  (lines 364-381); the 6 Codex auditor `.toml` Forbidden lists; `agent-run.sh`
  `CLAUDE_READONLY_FLAGS`.
- `IMPL-REPORT-BD-197-C7b.md` (coder claims).
- `CLAUDE.md` § "## Pack memory".

---

## Explicit verdicts on the three scrutiny questions

### (a) 8-verb-intersection categorization — SOUND ✅

Independently re-measured the FULL §5.1 28-verb candidate set across all 52
project surfaces using the check's own `_check_57_verb_present` matcher
(HEAD `3457569`, 2026-06-14). Exactly 8 verbs measure 52/52:

```
  stash 52/52  reset 52/52  restore 52/52  checkout 52/52
  clean 52/52  merge 52/52  rebase  52/52  worktree 52/52
```

This is byte-for-byte the asserted `_CHECK_57_CANONICAL_VERBS`. Every excluded
verb verified NOT consistent (would FALSE-FAIL a legitimately-divergent surface):

| Verb | Measured | Reviewer-confirmed disposition |
|---|---|---|
| `commit`, `push`, `add`, `apply` | 49/52 — absent from EXACTLY the 3 trinity files | **Surface-specific by design, NOT drift.** Verified the trinity "No destructive operations" rule (CLAUDE.md:364-381) is the **human/PM needs-approval** rule, scoped explicitly to "working-tree- or ref-mutating git verb" and ending "Agents go further — an agent runs NO state-changing git verb at all; see the agent's own definition file." commit/push/add/apply are NOT working-tree/ref-destructive ops the human needs approval for, so their absence from the trinity is intentional; they ARE present in all 49 agent+launcher surfaces. Correctly excluded from the project-wide intersection. (The IMPL-REPORT §3.2 table label "trinity-absent 3/3" is accurate — they hit 49/52 = present everywhere except the 3 trinity.) |
| `tag` | 48/52 — absent from 3 trinity + launcher | Not consistent; correctly excluded. |
| `rm`, `mv` | 4/52, 1/52 | Not consistent across agent Hard rules; correctly excluded. |
| `cherry-pick`, `revert`, `am`, `switch`, `config`, `remote`, `update-ref`, `update-index`, `pull`, `gc`, `filter-branch`, `notes`, `replace`, `stage` | 0/52 | Not enumerated as project deny verbs; correctly excluded. |

The bound is sized to the measured-consistent intersection, no broader —
satisfies `ci-guard-design-measure-then-bound`. `git apply` is correctly NOT
asserted (agent/launcher-only, not in the trinity intersection; Check 56 covers
apply parity on the pack side).

### (b) Standalone-vs-fold decision — SOUND ✅

The plan §J3 / §E and the in-source Check 56 comment make this an explicit
**coder's call** ("decision 8 — CODER'S CALL... PREFER folding... author a
standalone check ONLY if folding over-complicates"). Note the design §13.3
states a preference ("MAY fold... prefer fewer checks — design-elegance"), but
that preference is subordinate to the measured over-complication test, which the
coder correctly applied. The standalone choice is well-justified:

- The project intersection is **8 verbs**; Check 56's canonical set is the
  **28-verb** full §5.1 set across 10 PACK surfaces — folding would force one
  check to model two structurally-different canonical sets.
- The catch-all principle phrase is **trinity-only on the project side** (3/52,
  verified) whereas Check 56 asserts it unconditionally on all 10 pack surfaces
  — folding would require a per-surface conditional.
- Precedent: Check 56 is ITSELF standalone (the C5 coder cited the same escape
  hatch). A separate single-responsibility Check 57 keeps each guard auditable.

Check-number hygiene verified: highest existing check = 56; **54 is reserved for
C8b's Guard-A′** (corroborated by the in-source comment at `validate-pack.py:9431`
"54 is reserved for the C8b Guard-A′" and `grep 'Check 54'` → no hit); **57 is
the next available** (33 occurrences of Check 57 / `_CHECK_57`, none pre-existing).
The non-contiguous 54-gap is plan-expected (numbers ≠ commit order). C7b is
therefore PRESENT (not the dropped-to-11-commits branch), correctly recorded.

### (c) `add` false-positive handling — CORRECT ✅

The trinity carries the literal `git worktree (add/remove/prune)` parenthetical.
Verified the matcher's ≥4-member slash-run rule (`(?:[a-z][a-z-]*/){3,}[a-z][a-z-]*`)
correctly REJECTS the 3-member `(add/remove/prune)` parenthetical:

```
trinity 'add' present (should be False): False
3-member (add/remove/prune): False
4-member add/commit/push/tag: True   # a real ≥4 Forbidden list IS caught
prose 'git add' detected: True       # a real prose deny IS caught
```

So `add` measures trinity-absent and is correctly EXCLUDED — and critically, the
≥4-member rule does NOT mask a real `git add` deny (prose `git add` and ≥4-member
slash lists both detect). No masking risk.

---

## Independent re-verification (commands + verbatim output)

**1. Green on arrival + load-bearing.** `python3 scripts/validate-pack.py` →
EXIT 0; Check 57 OK across 52 surfaces. `PACK_VALIDATE_DEEP=1` → EXIT 0 (235
OK lines, all checks clean).

**2. Mismatch-catch (independently, /tmp `cp` mirror — NO real-tree mutation,
NO git checkout).** Mirrored all 52 real surfaces to `/tmp` via `shutil.copy`,
mutated only the copies:
```
MIRROR baseline failures (expect 0): 0
After dropping checkout from launcher: 1  | names 'checkout' True, 'agent-run.sh' True
After dropping catch-all from CLAUDE.md: 1 | names 'principle phrase' True, 'CLAUDE.md' True
Real-tree project-template/ status after mutations (expect EMPTY): ''
```
The guard FAILS on an injected project-surface verb-drop AND a catch-all drop;
real tree untouched.

**3. Format-agnostic matcher — all 3 shapes, word-boundary safe.**
- (a) `git <verb>` prose: detected.
- (b) `Bash(git <verb>:*)` launcher: all 8 verbs True against the real launcher.
- (c) Codex slash-list: the 6 auditor `.toml` files each carry
  `Forbidden: add/commit/push/tag/rebase/merge/reset/restore/stash/checkout/clean/apply/worktree`
  — verified these 6 are the ONLY surfaces relying on branch (b) for the 8 verbs
  (slash-only contribution = exactly +6 per verb, all from the legit Forbidden
  lists). Word-boundary: `clean`≠`cleanup`→False, `merge`≠`merged`→False.

**4. Runtime (`ci-check-runtime-compounding`).** Single-pass over 52 single-file
reads (3 trinity + 48 agents + 1 launcher), bounded regex per file, NO subprocess,
NO whole-tree scan. Measured mean ~7.2ms/run (3 runs: 7.49 / 7.08 / 7.16 ms) —
trivial across the ~202-invocation battery (~1.5s total). Routed through
`run_check` (per-check + total-run budget harness). Matches IMPL-REPORT.

**5. Run-before-wire + encoding surfaces.** `scripts/tests/test-validate-pack-check-57.sh`
exists (executable, `-rwxr-xr-x`), runs PASS 3 / FAIL 0 (Group 0 symbols +
Group 1 T1-T7 + Group 2 HEAD exit). Wired into `.github/workflows/validate-pack.yml`
`tests` job at line 229 (sister step after Check 55). Check + test + yml in
lockstep.

**6. CI sample.** validate-pack (general + DEEP) EXIT 0; check-57 EXIT 0;
check-56 EXIT 0 (standalone neighbor unbroken); check-55 EXIT 0; check-53 EXIT 0;
**test-v11-realistic-ot.sh EXIT 0 (33/33 — the banner-pin trap; the new Check 57
banner did not break a stale assertion).**

**7. Scope.** `git diff --name-only` = `scripts/validate-pack.py` +
`.github/workflows/validate-pack.yml` ONLY; untracked = the new test +
`IMPL-REPORT-BD-197-C7b.md` (+ pre-existing C7a artifacts the orchestrator
bundles). No `project-template/` or `supporting-docs/` edit (pack-only honest).
No C8 work. Manifest regen (`build.sh --all --clean` EXIT 0) → byte-identical →
stage nothing.

**8. Agent-enumeration completeness (drift safety).** Verified
`_CHECK_57_PROJECT_AGENTS` × `_CHECK_57_AGENT_DIRS` is a perfect bijection with
the on-disk files: 16/16 per CLI, zero extras, zero missing. A new agent added
without updating the tuple is caught by the absent-surface FAIL (drift-safe).
`re` imported (`validate-pack.py:291`).

---

## Findings by severity

### BLOCKER / MUST / SHOULD: none.

### NIT-1 (theoretical, no action required) — slash-run branch can false-positive on a benign 4-segment path

The branch-(b) regex `(?:[a-z][a-z-]*/){3,}[a-z][a-z-]*` matches ANY ≥4-segment
lowercase slash-run, so a benign path like `docs/pack/changelog/reset` would
report `reset` "present." Confirmed:
```
path 'docs/pack/changelog/reset' -> reset present: True
```
**Why not a blocker:** (i) a false-positive here can only make a surface look
MORE compliant, never cause a spurious FAIL; (ii) verified no real surface
relies on a benign slash-path to satisfy a verb — the entire +6 slash-only
contribution for every canonical verb comes from the 6 legitimate Codex
`Forbidden:` lists, nothing else. The risk is purely theoretical at current tree
state. If hardening is ever wanted, anchoring the slash-list to a `Forbidden:`/
deny-context token would tighten it, but that is gold-plating, not a defect.

### NIT-2 (cosmetic) — design §13.3 still names ONE conceptual Guard-C

The realized implementation is two checks (Check 56 pack 28-verb / 10-surface +
Check 57 project 8-verb / 52-surface). This is the correct measure-then-bound
outcome and within decision-8 latitude. The coder correctly surfaced this in
IMPL-REPORT §10 as an out-of-scope observation for a future
`architect-doc-reality-reconciliation` pass (design-doc owner's call), not a
C7b fix. No action in C7b.

---

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured, HEAD `3457569`, 2026-06-14) | Conclusion |
|---|---|---|
| ci-guard-design-measure-then-bound | Independently re-measured the full §5.1 28-verb set across 52 surfaces with the check's own matcher: exactly `{checkout,clean,merge,rebase,reset,restore,stash,worktree}` = 52/52; every excluded verb confirmed NOT consistent (commit/push/add/apply=49/52 trinity-only-absent BY DESIGN per CLAUDE.md:364-381; tag=48/52; rm=4/52; rest 0-1/52). `add` false-positive eliminated by the ≥4-member slash-run rule (3-member `(add/remove/prune)`→False; prose `git add`→True). Mismatch caught (launcher checkout-drop→1 FAIL; trinity catch-all-drop→1 FAIL). Sized to measured-consistent set, no broader. | COMPLIANT |
| ci-check-runtime-compounding | Single-pass: 52 single-file reads + bounded regex; no subprocess, no whole-tree scan. Measured mean ~7.2ms/run (7.49/7.08/7.16ms × 3). Routed through `run_check`. | COMPLIANT |
| enumerate-encoding-surfaces | Check (`validate-pack.py` Check 57 + reg `:9446`), test (`test-validate-pack-check-57.sh` PASS 3/0), yml (`validate-pack.yml:229`) all present and in lockstep in this one change set. Agent tuple = perfect bijection with on-disk 48 (zero extra/missing); absent-surface FAIL guards drift. | COMPLIANT |
| verify-full-ci-suite | Re-ran validate-pack general (EXIT 0) + DEEP (EXIT 0, 235 OK) + check-57 (EXIT 0) + representative sample check-56/55/53 (all EXIT 0) + test-v11-realistic-ot.sh (EXIT 0, 33/33 banner-pin trap). | COMPLIANT |
| empirical-evidence-blocks | Every claim above carries the command + verbatim output + HEAD `3457569` + date 2026-06-14 (verb-presence scan, mismatch-catch, runtime, slash-only contribution, scope, agent bijection). | COMPLIANT |
| scope-deliverables-to-the-ask | Reviewed exactly C7b (project verb-parity guard + test + yml). `git diff --name-only` = validate-pack.py + yml only; no project-template/, no C8, no C7a/BD-219/_toc tracked edits; manifest byte-identical. Surfaced 2 NITs, no invented nits, no softened blocker. | COMPLIANT |
| agents-never-commit | Read-only git only (`rev-parse`, `status`, `diff`, `log`); `/tmp` mismatch-catch used `shutil.copy` not `git checkout`; HEAD `3457569` unchanged before/after; my SOLE write is this review doc. | COMPLIANT |
| rules-applied-verification-block | This block; every rule addressed with quoted/measured evidence; no empty cell; no AMBIGUOUS terminal state. | COMPLIANT |

---

**RECOMMENDATION: APPROVE.** Check 57 is correct and load-bearing. The 8-verb
intersection categorization, the standalone-vs-fold decision, and the `add`
false-positive handling are all sound and independently verified. The two NITs
are non-blocking (NIT-1 theoretical-only; NIT-2 cosmetic doc reconciliation
already surfaced for a future owner). No fix-coder pass required.
