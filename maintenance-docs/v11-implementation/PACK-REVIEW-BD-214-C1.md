# PACK-REVIEW — BD-214 COMMIT C1 (tracker-deferral flip-block + Check-51 legs 1/2/4 + Check-50 test + Node-24 bump)

**Reviewer:** fresh pack-reviewer. **Date:** 2026-06-13.
**HEAD:** `0027b106789e09bad2d7cdb380c8c499d7d0f747` (branch `v11-dev`) + working-tree C1 changes.
**Scope reviewed:** the entire uncommitted working-tree change set attributable to BD-214 C1.
**Method:** independent re-measurement of the `git diff` against
`PLAN-BD-214-TRACKER-DEFERRAL.md` §4 + `ARCHITECTURE-BD-214-TRACKER-DEFERRAL.md` §3/§6.3.
Did NOT read the coder IMPL-REPORT for judgment (used only to locate files).

---

## VERDICT: APPROVE-WITH-FIXES

C1 is substantively correct: the clamp + three verb gates are real fixes (not band-aids),
Check 51 ships ONLY legs 1/2/4 (no early leak of legs 3/5 — the green-per-commit BLOCKER
condition is satisfied), the override seam is test-only and load-bearing, and the full CI
battery (validate-pack general + DEEP + integration + all three new tests + dormant tracker
tests) passes green at the C1 boundary. No BLOCKERs. Findings are SHOULD/NIT only.

---

## Independent verification results (commands + quoted output I ran)

| Check | Command | Result |
|---|---|---|
| validate-pack general | `python3 scripts/validate-pack.py` | `EXIT=0`; `PASSED — all checks clean`; Check 51 `OK ... (leg 1) ... (leg 2) ... (leg 4). Legs 3/5 land in later commits`; Check 50 `OK — no reproduced gz64/base64 codec` |
| validate-pack DEEP | `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | `DEEP EXIT=0`; `PASSED — all checks clean` |
| Check-51 test | `bash scripts/tests/test-validate-pack-check-51-flip-block.sh` | `EXIT=0`; `PASS: 3 / FAIL: 0` |
| Check-50 test | `bash scripts/tests/test-validate-pack-check-50-codec-single-source.sh` | `EXIT=0`; `PASS: 3 / FAIL: 0` |
| gate behavioral test | `bash scripts/tests/tracker-deferral-gate-test.sh` | `EXIT=0`; `PASS: 12 / FAIL: 0` |
| integration | `bash scripts/tests/test-v11-realistic-ot.sh` | `EXIT=0`; `All v11-realistic-ot integration tests PASSED (33/33)` |
| dormant tracker tests (sampled 5) | `bash scripts/tests/tracker-{config,init,migrate-forward}-test.sh`, `recommendation-test.sh`, `tracker-bd204-lossless-roundtrip-test.sh` | all `EXIT=0`, `All tests passed.` |
| manifest regen | `bash test-fixtures/build.sh --all --clean` | `build EXIT=0`; `git diff test-fixtures/manifest.txt` → EMPTY (no stage needed) |
| Check 42 wiring | (in validate-pack run) | `OK — 17 per-check test file(s) on disk; 17 workflow invocation(s); zero unwired tests` |

**Band-aid hunt (real-fix proof, my own measurement):** I stripped the override export from
`tracker-migrate-forward-test.sh` and re-ran it → `EXIT=1`, with the test reporting
`run refused pre-mutation` and `2.6 status:deferred ... missing`. This proves `cmd_forward`
GENUINELY refuses without the seam — the override is a real, load-bearing test seam, not an
assertion-deletion mask. Across all 21 override-export test files, `git diff | grep '^-[^-]'`
returned ZERO deletions — purely additive `export PACK_TRACKER_DEFERRAL_OVERRIDE=1`, no
assertions removed.

**Override is test-only (no live-path leak):** `grep -rn PACK_TRACKER_DEFERRAL_OVERRIDE
scripts/ --include='*.sh' | grep -v scripts/tests/` returns only the three gate-DEFINING sites
(`tracker-config.sh:193`, `pack-tracker.sh:153`, `tracker-migrate.sh:109`) which READ the seam
to decide whether to refuse. No live/non-test code PATH ever sets it. COMPLIANT.

**Legs 3/5 absence (green-per-commit BLOCKER condition — PASS):** `sed -n '8004,8090p'
scripts/validate-pack.py | grep -iE 'recommendation_should_recommend|tracker.toml.example|
leg 3|leg 5|install'` → empty. Check 51's C1 assertion body contains ONLY legs 1/2/4. The
guard does not assert any not-yet-true condition. This was the prompt's critical BLOCKER risk;
it is correctly avoided.

**Scope fidelity (no out-of-scope edits):** `git diff --name-only | grep -E
'project-template/|supporting-docs/|^CLAUDE.md|^AGENTS.md|^GEMINI.md|README|QUICKSTART|
pack-ops/|changelog/|_rules.md|HELP-FRAGMENT|init-project|migrate-v10'` → only
`test-migrate-v10-to-v11-gates.sh` (a `scripts/tests/` override-export, legitimate C1 scope —
NOT a `migrate-v10` source edit). No trinity sweep, no install-map change, no pack-td prose, no
backlog re-scopes, no 93-doc deletion. `backlog/` diff = `BD-214.md` only, and that is the
PRE-EXISTING 2026-06-12 dated note (confirmed in the plan header lines 4-6) — NOT a C1 edit;
C1 added nothing to it. Reverse arm of `tracker-migrate.sh` correctly LEFT un-gated
(`cmd_reverse` gate-count = 0) per design §3 Layer B (escape hatch).

---

## Findings by severity

### BLOCKER
None.

### MUST
None.

### SHOULD

**S-1 — 17 tracker test scripts inadvertently lost their executable bit (100755 → 100644).**
`scripts/tests/{template-translations-test.sh, test-migrate-v10-to-v11-gates.sh,
test-tracker-phase-task.sh, test-tracker-promote-direct.sh, test-tracker-promote-path1.sh,
test-tracker-promote-path2.sh, tracker-bd129-gh-repo-test.sh, tracker-bd130-doctor-wired-test.sh,
tracker-bd132-race-test.sh, tracker-bd133-header-preservation-test.sh,
tracker-bd134-close-retry-test.sh, tracker-config-test.sh, tracker-init-test.sh,
tracker-migrate-forward-test.sh, tracker-migrate-reverse-test.sh,
tracker-migrate-roundtrip-test.sh, tracker-provider-test.sh}` show `mode change 100755 =>
100644` in `git diff --summary`. Evidence: `git diff --summary scripts/tests/` lists 17 mode
changes. CI invokes these via `bash scripts/tests/...`, so the gate does NOT break; but the
permission drop is an unintended side effect of the editing tool/umask, is unrelated to the
C1 deliverable, and would surprise anyone running the scripts directly. **Recommended fix:**
restore the executable bit (`chmod +x` the 17 files) before staging C1, so the diff carries
only the intended `+5 lines` per file and no mode churn.

**S-2 — `scripts/pack-td.sh` advisory remains internally inconsistent after the typo fix.**
`scripts/pack-td.sh:259` now reads `  Resolved: n/a    → Resolution: $res_text`. The plan §4
row + BD-204:30 note scoped the fix narrowly to the "before" token (`Resolution: n/a` →
`Resolved: n/a`), and the coder applied EXACTLY that — so this is NOT a C1 scope violation and
NOT a deviation from the approved spec. However, the residual right-hand side still emits the
non-canonical field name `Resolution:` as the replacement target, so a human literally
applying the advisory would write `Resolution: <text>` into a backlog entry whose canonical
field is `Resolved:` (confirmed: `grep '^Resolved:' backlog/BD-198.md` → `Resolved: n/a`; the
field is `Resolved:`, never `Resolution:`). This is a PRE-EXISTING defect on a line the
BD-204 note did not cover. **Recommended fix:** since the line is already being touched in C1,
also correct the right side to `→ Resolved: $res_text` (one token) so the advisory is
self-consistent — OR explicitly defer with a tracked note. Default-fix per the small-fix-now
contract; flag to user at triage since it widens the BD-204-note's stated one-token scope.

### NIT

**N-1 — dead module constant `_CHECK_51_VERB_GATE_FILES`.** `scripts/validate-pack.py:7980`
defines `_CHECK_51_VERB_GATE_FILES = ("scripts/pack-tracker.sh", "scripts/tracker-migrate.sh")`
but it is never referenced — leg 2 hardcodes the two paths inline at the
`pack_tracker_path` / `tracker_migrate_path` assignments. Evidence:
`grep -n _CHECK_51_VERB_GATE_FILES scripts/validate-pack.py` → single hit (the definition).
**Recommended fix:** either use the constant in leg 2 or delete it. Cosmetic only.

**N-2 — column alignment drift in the pack-td advisory.** After S-2's left-token shortening,
`  Resolved: n/a    →` no longer aligns its `→` with `  Status: Open       →` (line 258).
Cosmetic; fold into the S-2 fix if S-2 is taken.

**N-3 — three new test files lack the executable bit** (`test-validate-pack-check-50-*.sh`,
`test-validate-pack-check-51-*.sh`, `tracker-deferral-gate-test.sh` are `-rw-r--r--`). Invoked
via `bash` in the yml, so functionally fine and consistent with S-1's stripped files; but if
S-1 is fixed by re-chmod, apply `chmod +x` to these three too for repo consistency. Cosmetic.

---

## Acceptance-bar checklist (prompt §"WHAT TO VERIFY")

| Bar | Result | Evidence |
|---|---|---|
| Scope fidelity (C1 only; no early legs 3/5; no surface sweep / install-map / pack-td prose / backlog re-scope / 93-doc deletion) | PASS | `git diff --name-only` scan; legs 3/5 grep-empty in the check body; backlog diff = BD-214 pre-existing note only |
| Pre-existing BD-214 dated note untouched by C1 | PASS | `git diff backlog/BD-214.md` = the single 2026-06-12 note (plan header lines 4-6); C1 added nothing |
| Green-per-commit (Check 51 asserts ONLY 1/2/4) | PASS | validate-pack general+DEEP EXIT=0; legs 3/5 absent from assertion body |
| Real fix — clamp forces flat-file | PASS | gate test `tracker_mode()` clamps a tracker-toml → `flat-file` + stderr notice; honors override → `tracker` |
| Real fix — 3 verb gates refuse (non-zero + typed) without override | PASS | gate test Group 2: init / enable-recommendations / forward all refuse `not-implemented` + non-zero |
| Override is TEST-ONLY (no live-path set) | PASS | grep: only the 3 gate-defining READ sites + tests/validator |
| 21 dormant tests pass via the seam, not assertion deletion | PASS | zero `^-` deletions across 21 files; sampled 5 green; forward-test FAILS when seam removed (proves real refusal) |
| Enumerate-encoding-surfaces (Check 51 + test + yml; Check 50 test + yml; no asymmetry) | PASS | Check 42 → 17 files / 17 wirings / zero unwired; both new per-check tests + gate test wired |
| Runtime compounding (Check 51 legs cheap/bounded) | PASS | leg 4 globs only `backlog/*.md` + `changelog/*.md` (no recursion, no subprocess); legs 1/2 read 3 named files; DEEP run within budget (no Check-budget FAIL) |
| Node-24 bump (checkout + setup-python current node24 majors) | PASS | yml: `actions/checkout@v6` (lines 88/109), `actions/setup-python@v6` (91/112); both v6 = current major, node24 runtime |
| Manifest regenerated + consistent | PASS | `build.sh --all --clean` → no diff; nothing to stage |
| Reverse arm un-gated (intentional) | PASS | `cmd_reverse` gate-count = 0; design §3 Layer B escape-hatch |

---

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|
| 1. Agents never commit | Git verbs this session: `git status`, `git rev-parse HEAD`, `git diff`, `git diff --summary/--stat/--name-only`, `git ls-files`, `git show HEAD:...`. Zero `add/commit/push/tag/reset/stash/checkout/rm`. | COMPLIANT |
| 2. Read-only mandate (write ONLY the report) | The single file I write is `maintenance-docs/v11-implementation/PACK-REVIEW-BD-214-C1.md`. I ran tests; the `tracker-deferral-gate-test.sh` and dormant tests self-provision under `mktemp -d` + `trap rm` and clean up; I stripped a seam into `/tmp/noseam-fwd.sh` (a /tmp throwaway, removed) — no repo file modified by me. `git status` post-run shows only the C1 coder changes + this report. | COMPLIANT |
| 3. Independent verification | Every PASS above carries the command I ran + quoted output (validate-pack general/DEEP EXIT=0; three new tests PASS:3/12/3; integration 33/33; manifest no-diff; seam-strip FAIL proof). Not derived from the coder report. | COMPLIANT |
| 4. Real-fixes-only enforcement | Actively hunted band-aids: (a) seam-strip experiment proved `cmd_forward` genuinely refuses (`run refused pre-mutation`); (b) zero `^-` deletions across 21 override-export files; (c) override grep-confined to gate-READ sites + tests. No assertion deletion, no masked failure, no live-path override leak found. | COMPLIANT |
| 5. Verify the full CI suite | Ran validate-pack general AND DEEP, the integration `test-v11-realistic-ot.sh` (33/33), the new check-50 + check-51 + gate tests, and 5 dormant tracker tests — all green, quoted above. | COMPLIANT |
| 6. Severity-tagged findings | Findings tagged BLOCKER(0)/MUST(0)/SHOULD(2: S-1 mode-strip, S-2 pack-td advisory)/NIT(3: dead constant, alignment, new-file perms), each with file:line + evidence + recommended fix. | COMPLIANT |
| 7. Rules-Applied Verification Block | This table; per-rule quoted evidence; no empty cell. | COMPLIANT |
| 8. PREFLIGHT + STOP-MEANS-STOP | Emitting `PREFLIGHT: review complete; about to Write <path>` in the message immediately preceding this write. No stop/halt/revert received. | COMPLIANT |

**Read-in-full attestation.** Read directly via tools this session, complete:
`CLAUDE.md` (full, incl. all `## Pack memory`, via system context);
`PLAN-BD-214-TRACKER-DEFERRAL.md` (full, 500 lines — Revision log, §2 green-per-commit table,
§4 C1 spec, §11 gaps, §12/§12a verification blocks);
`ARCHITECTURE-BD-214-TRACKER-DEFERRAL.md` (§§0-509 incl. Update log, §3 flip-block layers +
entry-point table, §6.1-§6.3 Check-51 legs, §6.5 Node-24 bump, §6.6 changelog text — the C1-
relevant sections; §§510-853 cover C2-C5/GH-deletion, out of C1 scope);
all changed files read fully: `scripts/lib/tracker-config.sh` (clamp), `scripts/pack-tracker.sh`
(gates), `scripts/tracker-migrate.sh` (forward gate), `scripts/validate-pack.py` Check 51 +
Check-42/50 anchors, `scripts/pack-td.sh` (advisory), the two new per-check tests + the gate
test, `.github/workflows/validate-pack.yml`, `backlog/BD-214.md`, and the 21 override-export
test diffs. No named document was derived rather than read.

**End of PACK-REVIEW-BD-214-C1.md**
