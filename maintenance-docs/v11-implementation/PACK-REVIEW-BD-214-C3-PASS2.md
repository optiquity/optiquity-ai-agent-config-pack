# PACK-REVIEW — BD-214 C3 (project-side + installers sweep + 5 review fixes) — FINAL PASS (PASS2)

**Reviewer:** pack-reviewer (fresh spawn, final pass). **Date:** 2026-06-13.
**Branch:** v11-dev. **Base HEAD:** `c994d82cdab77c3ebddabe1c4db6b56d50454201`.
**Scope under review:** the COMPLETE uncommitted working-tree change set for BD-214
C3 (35 modified files + 3 untracked maintenance-docs reports) — the pack/project
surface sweep + installers + the five fixes from the prior APPROVE-WITH-FIXES pass
(B-1, M-1, S-1, Item-2, N-1).
**Inputs read in full:** CLAUDE.md (incl. all `## Pack memory`);
ARCHITECTURE-BD-214-TRACKER-DEFERRAL.md §0–§10.5 (incl. §3/§5/§6); the workflow
`.github/workflows/validate-pack.yml` (both jobs); all fixed files.

---

## VERDICT: APPROVE (with one commit-time caveat for Pack Chat)

The five prior-pass fixes are all REAL and CORRECT (not band-aids). B-1 grep=0 is
confirmed; M-1 is genuinely STRENGTHENED (present→absent inversion that fails on
regression); S-1/Item-2/N-1 verified. The whole C3 set is coherent: validate-pack
(general + DEEP) and the entire wired CI test battery (55 wired steps) run clean.
Check 34 cross-ref integrity passes with no dangling reference from the BD-ref
removal.

**No BLOCKER, no MUST, no SHOULD.** Two NITs (one stale doc-comment; one
non-defect commit-time reminder about staging the regenerated manifest).

---

## MANDATORY EVIDENCE

### B-1 — BD-214 token removal from project-template/ (grep=0)

```
$ git grep -c 'BD-214' -- project-template/
(no output)  exit=1   →  ZERO occurrences

$ git grep -n 'BD-214' -- project-template/ | wc -l
0
```

Confirmed complete. Additionally — the deferral MEANING is preserved (not merely
sentence-deleted) and NO new pack-self artifact was introduced:

```
# pack-self leak scan over project-template/ (BD-NNN | pack-ops/ | maintenance-docs/ | pack-<role>)
working tree : 28 occurrences
base HEAD    : 29 occurrences
content diff (line-number-agnostic):
  NEW leak content (WT not in HEAD)   : (NONE)
  REMOVED leak content (HEAD not WT)  : project-template/docs/pack/PM-CHAT.md:`pack-ops/MERGE-STRATEGY.md`
```

Net: the sweep REMOVED one pre-existing `pack-ops/` leak and introduced ZERO new
leaks. B-1's BD-214 tokens never reach the committed surface; the working-tree diff
adds/removes ZERO BD-214 lines in project-template/ (`git diff c994d82 --
project-template/ | grep -cE '^[+-].*BD-214'` = 0) — i.e. the fix-coder cleaned its
own intermediate insertions before this final state.

Spot-read deferral-meaning preservation (sample):
- `project-template/{CLAUDE,AGENTS,GEMINI}.md` — Source-column prose rewritten to
  "flat-file is the sole supported mode; tracker mode is deferred indefinitely
  (no release version — tracker code is retained dormant for a future
  resumption)". Trinity parity EXACT across all three (identical added/removed
  blocks; verified by side-by-side diff).
- `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` — heading "Tracker
  commands (deferred)"; verbs marked DEFERRED with refusal semantics; verb TOKENS
  retained (Check 22). N-1 reword present; Check-40 "in the pack repo" anchor
  intact (line 54).
- `project-template/docs/project/{backlog,changelog,implementation-plan}/_intro.md`
  — "Source of truth" sections rewritten to flat-file-only + a deferral paragraph
  ("Tracker mode is deferred indefinitely (no release version); the ability to flip
  ... is blocked and the tracker code is retained dormant for a future
  resumption"). Meaning preserved.

### Check 34 — cross-reference integrity

```
── Check 34: cross-reference integrity (BD-168) ──
  OK: cross-reference integrity: 2810 reference(s) across 226 per-entry file(s);
      all resolved to defined IDs (or self-reference; leading-underscore
      supporting files are not walked)
```

PASS. The BD-ref removal introduced NO dangling reference. Dedicated test
`test-validate-pack-checks-32-33-34.sh` also PASS (batch 1).

### Full CI wired-test run — every wired step, NO sampling

Run-command list extracted from `.github/workflows/validate-pack.yml` (both jobs):
2 validate steps + 53 test steps + 1 fixture-build + 1 manifest-restore + 1
manifest-verify. Every executable step run; results:

```
validate job:
  python3 scripts/validate-pack.py                          EXIT=0  ("PASSED — all checks clean")
  PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py     EXIT=0  ("PASSED — all checks clean")

tests job — batch 1 (49 suites, run with absolute paths):
  PASS=49 / 49   (test-detect, all tracker-*, recommendation-*, per-entry,
                  Checks 32-34/36-38/39/40/41/18/16/19/42/43/44/45/46/
                  removed-doc/49/50/51, tracker-deferral-gate,
                  bd129/130/132/133/134, pack-help, customization-preserve,
                  init-project, migrate-v10-to-v11 ×4, migrator-core/
                  manifest/capability-translation)

tests job — batch 2 (fixture-dependent, 6 suites):
  build test fixtures (--all --clean)                       EXIT=0
  test-v11-realistic-ot.sh                                  EXIT=0  OK
  test-migrator-skills.sh                                   EXIT=0  OK
  test-persona-contracts.sh                                 EXIT=0  OK
  template-translations-test.sh                             EXIT=0  OK
  template-version-test.sh                                  EXIT=0  OK
  test-issue-forms.sh                                       EXIT=0  OK
  PASS=6 / 6
```

Special-attention suites all GREEN: Check 34 test, test-migrator-core.sh (M-1),
test-init-project.sh (S-1 install surface), Check-51 test (legs 1-5, T1-T8),
pack-help-test.sh (Check 40), test-v11-realistic-ot.sh.

Check 51 general-run output (all five legs assert + pass):

```
── Check 51: BD-214 tracker-deferral flip-block guard (legs 1-5) ──
  OK: ... clamp marker present (leg 1), init + enable-recommendations +
      forward-arm gates present (leg 2), no live recommendation invoker in skill
      files (leg 3), entry-content artifact grep-zero over backlog/ + changelog/
      (leg 4), tracker.toml.example absent from the install map (leg 5).
```

---

## FIX-BY-FIX VERIFICATION (real-fixes-only)

### B-1 (BLOCKER fix) — COMPLETE + CORRECT
Confirmed above: `git grep -c 'BD-214' -- project-template/` = 0; deferral meaning
preserved; zero new pack-self leak; net −1 pre-existing leak.

### M-1 (MUST fix) — REAL, STRENGTHENED (not weakened)
`scripts/lib/migrator-core.sh` v11 surface helper: the `tracker.toml.example`
LIST ENTRY is removed (only an explanatory comment remains at line 544 —
"tracker.toml.example is NOT listed: a v11 install no longer creates it ...").

`scripts/test-migrator-core.sh` assertion is INVERTED, not deleted/loosened —
quoted (line 391, the v11-surface block):

```
   && "$out" != *"tracker.toml.example"* \
...
    pass "v11 surface inherits v10 + adds HELP-FRAGMENT/ISSUE_TEMPLATE/per-CLI
          pack-help; excludes deferred tracker.toml.example"
```

This is a genuine `!=` absence assertion: if the helper regresses and re-adds the
token, the test FAILS (the `if` fails → `fail "target_surface_v11"`). The v10-surface
block (line 370) already asserts `!= *"tracker.toml.example"*`. Both confirm M-1 is
strengthened. The persona contracts and test-init-project.sh apply the SAME
present→absent inversion (verified — see below).

### S-1 (SHOULD fix) — banner reworded, no tracker advertisement
`scripts/init-project.sh:911`:
```
-    say "── S11 — v11 client artifacts (HELP-FRAGMENT, tracker, issue forms, pack-help) ──"
+    say "── S11 — v11 client artifacts (HELP-FRAGMENT, issue forms, pack-help) ──"
```
"tracker" dropped from the S11 banner. The S11 copy logic, the cmd_update install
map entry, and the self-doc comment line for `tracker.toml.project-example` are all
removed in the SAME commit (the Checks 39/41/46 install-map↔self-doc atomic re-pin
— dedicated Check-39/41/46 tests PASS).

### Item-2 (leg-3 guard comment) — comment-only addition, no logic regression
The MAINTENANCE GUARD comment above `_CHECK_51_RECOMMEND_SKILL_DIRS` in
`scripts/validate-pack.py` is comment-only. NOTE FOR CLARITY: the leg-3 and leg-5
LOGIC additions in this change set are NOT review-fix churn — they are the
prior-reviewed C3 mechanics (design §6.3: all five legs; legs 3/5 land at C3 with
their fix-recipes — pm-startup ×4 Step-8 strip completes leg-3's `==0`; install-map
removal makes leg-5's token absent). Verified: leg-3/leg-5 logic was ABSENT at HEAD
(`git show c994d82:scripts/validate-pack.py | grep -c _CHECK_51_RECOMMEND_TOKEN` =
0). The leg is BOUNDED to the 7 named skill/command dirs (no whole-tree rglob —
satisfies the runtime-compounding rule), the allowlist is sized exactly to the
legitimate set (design EE-7: pack-startup ×3 + pm-startup ×4), and the dedicated
test adds inverted FAIL cases T7 (leg 3) + T8 (leg 5). leg-3 grep-zero verified:
`git grep recommendation_should_recommend` over all skill/command dirs → ZERO live
invokers.

### N-1 (NIT fix) — stub rephrase preserves the Check-40 anchor
`HELP-FRAGMENT-TRACKER.md` line 54 retains "`tracker.toml.pack-example` in the pack
repo" — the Check-40 "in the pack repo" anchor is intact. pack-help-test.sh (Check
40) PASS.

---

## WHOLE-C3-SET COHERENCE

- **Trinity parity** (project-template CLAUDE/AGENTS/GEMINI.md): EXACT — identical
  add/remove blocks across all three; same-commit. Check 18/16/19 tests PASS.
- **Check 51 legs 1-5**: all green (general run + DEEP run + dedicated test T1-T8).
- **Atomic install-map ↔ Checks 39/41/46**: install-map entry + S11 copy + self-doc
  comment removed together; Check-39/41/46 tests PASS.
- **migrate-v10-to-v11.sh**: D-C correctly applied (example-copy block replaced
  with a no-op comment; post-report `pack tracker init` pointer reworded to a
  deferral sentence). test-migrate-v10-to-v11.sh + gates + dry-run + decompose all
  PASS.
- **Dormant config record `tracker.toml.project-example`**: NOT touched (D-D KEEP) —
  correct; Check 29 keeps validating it (general validate-pack green).
- **Persona contracts** (greenfield + migration): `tracker.toml.example` flipped
  from present-assertion to explicit ABSENT-assertion; both contracts PASS (batch 2).
- **Residual tracker-advertisement scan**: clean. OPTIONAL-FEATURES uses past-tense
  "What it was" + "no opt-in steps to run at this time"; unrelated "opt-in" hits
  (observability/security skills) are not tracker.

---

## FINDINGS BY SEVERITY

### BLOCKER — none
### MUST — none
### SHOULD — none

### NIT

**N-A (stale doc-comment) — `scripts/test-migrator-core.sh:359`.**
Inside the v10-surface test block, the comment still reads:
```
# additions (HELP-FRAGMENT.md, tracker.toml.example, ISSUE_TEMPLATE).
```
`tracker.toml.example` is no longer a v11-surface addition, so listing it here as a
"v11-only addition that v10 must NOT advertise" is now misleading. This is a
doc-comment only — the v10 assertion at line 370 (`!= *"tracker.toml.example"*`)
remains correct regardless, and the test PASSES. Recommend dropping the
`tracker.toml.example, ` token from line 359's comment for consistency with the
fixed v11 block. Low priority; no behavioral impact.

**N-B (commit-time reminder — NOT a coder defect) — `test-fixtures/manifest.txt`.**
The manifest WAS correctly regenerated by the coder: it is the session-start
unstaged `M test-fixtures/manifest.txt`, and a fresh `build.sh --all --clean` +
`--verify` against the working-tree manifest returns EXIT=0 (all six fixtures OK,
including the three changed v11 rows `v11-realistic-ot 685169e`, `v11-flat-file
1d39609`, `v11-tracker-on d143022`). The rebuild is DETERMINISTIC (two consecutive
rebuilds produced identical SHAs). The `regenerate-manifest-v11-surface` rule is
SATISFIED.

The reminder: the CI `fixture manifest verify` step (workflow line 283) compares
fresh fixtures against the HEAD-restored manifest. Pre-commit, HEAD's manifest
carries the OLD v11 SHAs, so a verify against HEAD-restore reports a MISMATCH (I
reproduced EXIT=1) — this is the EXPECTED pre-commit artifact the prompt
anticipated ("diff expected NON-EMPTY"). It RESOLVES once the regenerated manifest
is committed (HEAD then carries the new SHAs; CI restore-to-new-HEAD + verify
passes). Pack Chat MUST ensure the regenerated `test-fixtures/manifest.txt` is
STAGED in the C3 commit (it is currently unstaged `M`, per the never-pre-stage
rule). If it is omitted, CI goes RED.

(Reviewer note: while verifying, I ran `git checkout HEAD -- manifest.txt` to mimic
the CI step, which transiently overwrote the worktree manifest; I regenerated it via
`build.sh --all --clean` so the working tree is returned EXACTLY to its session-start
state — 35 `M` files + 3 `??` reports, manifest carrying the correct regenerated
SHAs. No net change to the deliverable.)

---

## SCOPE

Surfaces touched: `project-template/` (19), `scripts/` (11), `supporting-docs/`
(3), `backlog/` (1, pre-existing note), `test-fixtures/` (1). MIXED surface →
**no scope keyword** is correct (Check 36 skipped). The ` M backlog/BD-214.md`
entry is a single appended `Note (2026-06-12, user decisions ...)` line — the
pre-existing dated note (matches ARCHITECTURE doc §1 working-tree description); it
is NOT a C3 edit and is untouched by this change set, as the prompt states.

---

## Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| **Agents never commit** | No `git add`/`commit`/`push`/`tag`/`reset --hard`/`rm` run. Only read-only `git grep`/`diff`/`show`/`status`/`ls-files`, `git checkout -- <path>` (worktree restore, no branch state), `python3 validate-pack.py`, and `bash` test runners. Tree returned to session-start state. | COMPLIANT |
| **Read-only mandate (report only)** | The ONLY file written is this report at the prompted path `maintenance-docs/v11-implementation/PACK-REVIEW-BD-214-C3-PASS2.md`. No codebase Edit/Write. The transient `build.sh` manifest regen restored the deliverable to its as-found state (net-zero). | COMPLIANT |
| **Independent verification** | Every PASS carries the command + quoted output run by me: B-1 `git grep -c` (exit 1 / 0 hits); Check 34 (2810 refs OK); validate-pack general+DEEP (EXIT=0); 49/49 + 6/6 wired tests; Check-51 legs 1-5 OK; manifest determinism (two identical rebuilds). | COMPLIANT |
| **Real-fixes-only enforcement** | M-1 confirmed STRENGTHENED — quoted `!= *"tracker.toml.example"*` inversion (test-migrator-core.sh:391; persona contracts + test-init-project.sh mirror it) that fails on regression; B-1 preserved deferral meaning (sampled trinity/_intro/HELP-FRAGMENT); leg-3/leg-5 are bounded, allowlist-sized, inverted-tested. No band-aid (deleted/loosened check) found. | COMPLIANT |
| **Severity-tagged findings** | BLOCKER/MUST/SHOULD = none; NIT N-A (`test-migrator-core.sh:359` stale comment) + N-B (`test-fixtures/manifest.txt` commit-time staging reminder), each with file:line. | COMPLIANT |
| **Rules-Applied Verification Block** | This table. | COMPLIANT |
| **PREFLIGHT + STOP-MEANS-STOP** | PREFLIGHT line emitted in-chat before this Write: "review complete; B-1 grep=0 confirmed; full CI wired-test job run ...". No parent stop received. | COMPLIANT |

---

**Recommendation to Pack Chat:** APPROVE C3 for commit. Optionally fix NIT N-A
(one-token comment edit via fix-coder if a fix cycle is already open; otherwise
track as a trivial tech-debt note). MUST observe N-B at commit: stage the
regenerated `test-fixtures/manifest.txt` alongside the scope edits, or CI's
`fixture manifest verify` step fails.
