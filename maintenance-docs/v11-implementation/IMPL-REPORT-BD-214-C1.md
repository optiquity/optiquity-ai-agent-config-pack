# IMPL-REPORT — BD-214 COMMIT C1 (flip-block code + Check-51 legs 1/2/4 + Check-50 test + Node-24 bump + pack-td typo)

**Author:** pack-coder (fresh spawn). **Date:** 2026-06-13.
**Branch:** `v11-dev`. **Pre-flight HEAD:** `0027b106789e09bad2d7cdb380c8c499d7d0f747`.
**Final HEAD:** `0027b106789e09bad2d7cdb380c8c499d7d0f747` (UNCHANGED — coder never commits; all
work is in the working tree).
**Spec:** `PLAN-BD-214-TRACKER-DEFERRAL.md` §4 (C1) + `ARCHITECTURE-BD-214-TRACKER-DEFERRAL.md`
§3 / §6.3. **Scope keyword (for Pack Chat):** `pack-only` (only `scripts/` + `.github/`).

---

## 1. Summary

C1 lands the BD-214 tracker-deferral flip-block + its regression guard scaffold:
the `tracker_mode()` deferral clamp, three verb gates (init / enable-recommendations /
forward arm), the `PACK_TRACKER_DEFERRAL_OVERRIDE=1` test seam wired into the dormant
tracker test scripts, a behavioral gate test, Check 51 legs 1/2/4 + its dedicated test,
Check 50's missing dedicated test, both new tests wired into CI, the Node-24 actions bump,
and the `pack-td.sh` advisory typo fix. validate-pack (general + deep) is GREEN; the
integration test + the full affected tracker/recommendation suite are GREEN.

Legs 3 and 5 are intentionally NOT added (their conditions are not yet true; the
dedicated test asserts ONLY legs 1/2/4) — confirmed by running validate-pack and the
dedicated test.

---

## 2. Files changed (inventory)

### Modified (in scope)
| Path | Change type |
|---|---|
| `scripts/lib/tracker-config.sh` | modified — deferral clamp |
| `scripts/pack-tracker.sh` | modified — `_tracker_deferral_gate` helper + gates on `cmd_init`, `cmd_enable_recommendations` |
| `scripts/tracker-migrate.sh` | modified — forward-arm gate |
| `scripts/pack-td.sh` | modified — advisory typo `Resolution: n/a`→`Resolved: n/a` (LHS only) |
| `scripts/validate-pack.py` | modified — ADD Check 51 (legs 1/2/4) + register in `main()` |
| `.github/workflows/validate-pack.yml` | modified — Node-24 bump (4 lines) + wire 3 new test steps |
| 21 test scripts (`scripts/tests/…`) | modified — `export PACK_TRACKER_DEFERRAL_OVERRIDE=1` seam |

The 21 test scripts: `recommendation-test.sh`, `template-translations-test.sh`,
`test-migrate-v10-to-v11-gates.sh`, `test-tracker-cycle-check.sh`, `test-tracker-links.sh`,
`test-tracker-phase-task.sh`, `test-tracker-promote-direct.sh`, `test-tracker-promote-path1.sh`,
`test-tracker-promote-path2.sh`, `tracker-bd129-gh-repo-test.sh`, `tracker-bd130-doctor-wired-test.sh`,
`tracker-bd132-race-test.sh`, `tracker-bd133-header-preservation-test.sh`,
`tracker-bd204-lossless-roundtrip-test.sh`, `tracker-config-test.sh`, `tracker-init-test.sh`,
`tracker-migrate-forward-test.sh`, `tracker-migrate-reverse-test.sh`,
`tracker-migrate-roundtrip-test.sh`, `tracker-provider-test.sh`, `tracker-bd134-close-retry-test.sh`.

### New (in scope)
| Path | Change type |
|---|---|
| `scripts/tests/test-validate-pack-check-51-flip-block.sh` | new — Check 51 dedicated test (legs 1/2/4 ONLY) |
| `scripts/tests/test-validate-pack-check-50-codec-single-source.sh` | new — Check 50 dedicated test |
| `scripts/tests/tracker-deferral-gate-test.sh` | new — behavioral gate test |

### NOT touched (out of scope / pre-existing)
- `backlog/BD-214.md` — shows as ` M` in `git status`, but this is the PRE-EXISTING dated
  note (2026-06-12) added before this coder spawn; I did NOT edit it (diff confirmed: a single
  pre-existing `Note (2026-06-12 …)` line). Surfaced here so Pack Chat does not attribute it to C1.
- `maintenance-docs/v11-implementation/{ARCHITECTURE,PLAN,RESEARCH}-…BD-214….md` — pre-existing
  untracked design/plan/census docs (inputs, not my output).
- `test-fixtures/manifest.txt` — regenerated (`build --all --clean`, exit 0); diff is EMPTY
  (script source edits do not change fixture SHAs), so nothing to stage.

---

## 3. As-built shapes

### 3.1 Clamp — `scripts/lib/tracker-config.sh` (first statement of `tracker_mode()`)
```bash
tracker_mode() {
    # BD-214 deferral clamp (2026-06-12): tracker mode is deferred
    # indefinitely; flat-file per-entry is the SOLE supported mode.
    # PACK_TRACKER_DEFERRAL_OVERRIDE=1 is a TEST-ONLY seam that keeps the
    # dormant tracker code testable; it must NEVER be set in a live run.
    # Recorded in BD-214 / BD-204.
    if [[ "${PACK_TRACKER_DEFERRAL_OVERRIDE:-0}" != "1" ]]; then
        echo "tracker mode is deferred; operating flat-file (BD-214)" >&2
        echo "flat-file"
        return 0
    fi
    local path="$1"
    ...
```
It only STRENGTHENS the existing flat-file fallback (design EE-6); validate-pack never calls
`tracker_mode` (confirmed: validate-pack green with the clamp in place).

### 3.2 Verb gates — `scripts/pack-tracker.sh`
A shared helper `_tracker_deferral_gate()` emits a typed `not-implemented` refusal
("tracker support is deferred indefinitely (no release version)." / "Flat-file per-entry is the
sole supported mode." / "Recorded in BD-214 / BD-204.") and returns 1 unless the override is set.
- `cmd_init` calls `_tracker_deferral_gate || return 1` before `tracker_init_run`.
- `cmd_enable_recommendations` calls it after option parsing (so `--help` still works), before
  any state mutation.

### 3.3 Forward-arm gate — `scripts/tracker-migrate.sh` (`cmd_forward`, after option parse)
Inline override check emitting the same typed `not-implemented` refusal + `return 1`. The
REVERSE arm (`cmd_reverse`) is UN-gated per design (escape hatch).

### 3.4 Dormant-but-testable seam
`export PACK_TRACKER_DEFERRAL_OVERRIDE=1` inserted after the `set …` line of each of the 21
tracker/recommendation test scripts (with a 3-line comment). Without it those scripts went RED
under the clamp; with it they are GREEN (measured — §4).

### 3.5 pack-td typo (code-only portion; prose half deferred to C2 per GAP-4)
`scripts/pack-td.sh:259` LHS field-name label corrected:
`  Resolution: n/a    → Resolution: $res_text` → `  Resolved: n/a    → Resolution: $res_text`.
Only the LHS `Resolution: n/a`→`Resolved: n/a` was changed per the explicit C1 scope; the RHS
`→ Resolution: $res_text` prose reword is C2 (lane discipline).

---

## 4. Check 51 legs 1/2/4 + Check 50 test + wiring

### 4.1 Check 51 (`scripts/validate-pack.py`)
New `check_tracker_deferral_flip_block()` registered LAST in `main()` via `run_check`.
- **leg 1** — `tracker-config.sh` contains `PACK_TRACKER_DEFERRAL_OVERRIDE` + a `BD-214`
  comment. Cost: one `read_text` + two substring tests on ONE named file.
- **leg 2** — `cmd_init` + `cmd_enable_recommendations` (pack-tracker.sh) and `cmd_forward`
  (tracker-migrate.sh) bodies carry the gate. Detection accepts EITHER the override token OR a
  `_tracker_deferral_gate` helper call (cmd_init/enable use the helper). Cost: bounded
  function-body slices over TWO named files.
- **leg 4** — line-anchored `^<!-- pack-entry-body-gz64:` / `^<!-- pack-id:` over `backlog/` +
  `changelog/` `*.md` == 0, empty allowlist. Cost: glob over TWO bounded per-entry dirs, line
  scan; NO whole-tree scan, NO subprocess-per-entry.
- **Legs 3 + 5 NOT added** (conditions not yet true — their fix-recipes land in C2/C3). The
  check's OK message states this explicitly.

### 4.2 Dedicated tests + wiring
- `test-validate-pack-check-51-flip-block.sh` asserts ONLY legs 1/2/4 (Group 0 import; Group 1
  synthetic T1 PASS / T2 leg-1 FAIL / T3 leg-2 cmd_init FAIL / T4 leg-2 forward FAIL / T5 leg-4
  FAIL / T6 mid-line exclusion PASS; Group 2 e2e HEAD clean).
- `test-validate-pack-check-50-codec-single-source.sh` exercises Check 50's quote-span stripper
  + forbidden-token logic (bare-flagged / quoted-excused / self-quote-not-excused) + e2e HEAD clean.
- `.github/workflows/validate-pack.yml` wires BOTH (Check 42 enforces) PLUS the behavioral
  `tracker-deferral-gate-test.sh`, inserted after the Check 49/50 step. Check 42 now reports
  **17/17 wired**.

---

## 5. Node-24 actions bump (GAP-2, deadline 2026-06-16)

Latest stable Node-24 majors confirmed at implementation time via the GitHub API
(`repos/actions/<name>/releases/latest` + `action.yml` `using:` field):
- `actions/checkout` latest `v6.0.3`, `action.yml` → `using: node24` ⇒ bumped `@v4`→**`@v6`**.
- `actions/setup-python` latest `v6.2.0`, `action.yml` → `using: 'node24'` ⇒ bumped `@v5`→**`@v6`**.

Both occurrences of each (yml lines 88/91 in `validate:` and 109/112 in `tests:`) bumped via
`replace_all`. yml re-parsed clean (`yaml.safe_load`). Note: the plan/architect cited `@v5`
(checkout) / `@v6` (setup-python) as the Node-24 majors, but checkout's Node-24 line has since
advanced to `@v6` as the current latest stable major — the plan says "coder verifies the exact
latest majors at implementation time," so `@v6` for both is the measured current Node-24 major.

---

## 6. Manifest

`bash test-fixtures/build.sh --all --clean` ran (exit 0). `git diff test-fixtures/manifest.txt`
is EMPTY — the C1 edits are to `scripts/` source + CI yml, which do not alter any built fixture
SHA. Per the rule, nothing to stage (diff non-empty is the staging trigger; it is empty).

---

## 7. Verification battery (quoted)

**validate-pack general:** `python3 scripts/validate-pack.py` → `exit=0`,
`PASSED — all checks clean`.
- `OK: Check 42 — 17 per-check test file(s) on disk; 17 workflow invocation(s) found; zero unwired tests.`
- `OK: Check 50 — no reproduced gz64/base64 codec in validate-pack.py; Check 49 sub-invokes the shared batch codec (OQ-4 single-source)`
- `OK: Check 51 — BD-214 flip-block guard: clamp marker present (leg 1), init + enable-recommendations + forward-arm gates present (leg 2), entry-content artifact grep-zero over backlog/ + changelog/ (leg 4). Legs 3/5 land in later commits with their fix-recipes.`

**validate-pack DEEP:** `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` → `deep exit=0`,
`PASSED — all checks clean`.

**Integration:** `bash scripts/tests/test-v11-realistic-ot.sh` → `exit=0`,
`All v11-realistic-ot integration tests PASSED (33/33).`

**New tests:**
- `test-validate-pack-check-50-codec-single-source.sh` → `exit=0`, `All tests passed.`
- `test-validate-pack-check-51-flip-block.sh` → `exit=0`, `All tests passed.`
- `tracker-deferral-gate-test.sh` → `exit=0`, `PASS: 12 / FAIL: 0`.
- `test-validate-pack-check-42.sh` → `exit=0`, `All tests passed.`

**Gate behavior (manual, design §3 verification item):** all three gates refuse with
`ERROR: not-implemented` + non-zero exit WITHOUT the override; `reverse` un-gated;
`status/edit/new-entry/tree-rebuild/update-templates` exit non-zero/zero with typed errors, no
crash, under the clamp. (`doctor/disable/mirror-rebuild` touch the provider/network and are
covered by the dedicated tracker tests under the override; excluded from the behavioral test to
keep it deterministic/network-free.)

**Affected tracker/recommendation suite (21 scripts, with override seam):** ALL `exit=0`
(`tracker-config-test`, `tracker-init-test`, `tracker-migrate-forward/reverse/roundtrip-test`,
`tracker-bd204-lossless-roundtrip-test`, `recommendation-test`, `test-tracker-phase-task`,
`test-tracker-cycle-check`, `test-tracker-links`, `test-tracker-promote-direct/path1/path2`,
`tracker-bd129/130/132/133/134`, `tracker-provider-test`, `template-translations-test`,
`test-migrate-v10-to-v11-gates`). `pack-help-test.sh` → `exit=0`, `All tests passed.`

**Real-fix check:** the suite went RED→GREEN ONLY via the legitimate test-seam (override
export) — no assertion was deleted or masked; the clamp genuinely forces flat-file and the gates
genuinely refuse (verified empirically, §3.1/§3.2).

---

## 8. Plan deviations

- **Node-24 major value.** Plan/architect named `actions/checkout@v5`; the measured current
  Node-24 latest stable major is `@v6` (the plan explicitly delegates the exact major to
  implementation-time verification). Used `@v6` for both. NOT a scope deviation — within the
  plan's "verify exact majors at implementation time" instruction.
- **Behavioral gate test scope.** The plan's behavioral test asked for the three refusals + the
  un-gated reverse + per-verb no-crash. The committed behavioral test asserts the three refusals
  (executed), the clamp (executed), the forward-gated/reverse-un-gated property (asserted
  STRUCTURALLY over the two function bodies — the reverse execution path touches `gh`/network and
  hangs a command-substitution capture in CI), and the no-crash loop over the FIVE network-free
  verbs. The network-touching verbs' no-crash was verified MANUALLY (§7) and is covered by the
  dedicated tracker tests under the override. This keeps the permanent CI test deterministic +
  network-free (CI-runtime-compounding-safe). Surfaced as a deliberate, documented narrowing —
  no assertion weakened, full property still proven.

No other deviations.

---

## 9. Out-of-scope items SURFACED (not fixed)

1. **`backlog/BD-214.md` ` M`** — pre-existing dated note from the architect/planner session,
   NOT a C1 edit. Pack Chat: do not attribute to the C1 commit; it belongs to the prior session's
   working state (or its own staging decision).
2. **pack-td RHS prose** (`→ Resolution: $res_text`) and the tracker-mode prose reword in
   `pack-td.sh` — deferred to **C2** per GAP-4 lane discipline (C1 is code-only). Left unchanged.
3. **Check 50's e2e WARN noise** — Check 48 (removed-doc advisory) WARNs 14 historical citations;
   these are advisory-only (exit code unaffected), pre-existing, and out of scope.

No new POQs introduced.

---

## 10. Definition-of-Done checklist

| Item | Status |
|---|---|
| Clamp as first statement of `tracker_mode()`, override-gated, emits notice, returns flat-file | PASS |
| Verb gates on `cmd_init` + `cmd_enable_recommendations` + forward arm; reverse un-gated | PASS |
| Override export added to dormant tracker/recommendation test scripts (stay green) | PASS |
| Behavioral gate tests (refusals without override + clamp forces flat-file) | PASS |
| Check 51 legs 1+2+4 ONLY (NOT 3/5) in validate-pack.py | PASS |
| Check-51 dedicated test asserts ONLY legs 1/2/4, wired (Check 42) | PASS |
| Check-50 dedicated test added + wired | PASS |
| Node-24 actions bump at the 4 measured lines | PASS |
| pack-td typo `Resolution: n/a`→`Resolved: n/a` (LHS, code-only) | PASS |
| Manifest regenerated (diff empty → nothing to stage) | PASS |
| validate-pack general + DEEP green | PASS |
| Integration `test-v11-realistic-ot.sh` green (33/33) | PASS |
| Affected tracker/recommendation suite green | PASS |
| No out-of-scope edits (legs 3/5, prose sweep, install-map, deletions, backlog entries) | PASS |
| Coder did NOT stage/commit | PASS |

---

## 11. Rules-Applied Verification Block

| Rule | Evidence (quoted) | Conclusion |
|---|---|---|
| 1. Agents never commit | Git verbs this session: `git rev-parse HEAD`, `git status --short`, `git diff <path>`. Final HEAD `0027b106789e09bad2d7cdb380c8c499d7d0f747` == pre-flight HEAD (no commit). Zero `add/commit/push/tag/reset/stash/checkout/rm`. | COMPLIANT |
| 2. Real fixes only — no green-the-test band-aids | RED→GREEN of the 7 initially-failing tracker tests achieved ONLY via the design-mandated `PACK_TRACKER_DEFERRAL_OVERRIDE=1` seam; no assertion deleted/masked. Clamp empirically forces flat-file (`tracker_mode` on a tracker-toml → `flat-file` without override, `tracker` with it — gate test Group 1 PASS); gates empirically refuse (gate test Group 2 PASS). | COMPLIANT |
| 3. Verify the full CI suite, not just validate-pack | `python3 scripts/validate-pack.py` exit=0; `PACK_VALIDATE_DEEP=1 …` exit=0; `test-v11-realistic-ot.sh` `33/33` exit=0; new Check 50/51 tests + gate test exit=0; Check 42 test exit=0; 21 affected tracker tests + pack-help-test exit=0 (all quoted §7). | COMPLIANT |
| 4. Regenerate manifest on v11-surface commits | `bash test-fixtures/build.sh --all --clean` exit=0; `git diff test-fixtures/manifest.txt` EMPTY (script-source edits do not change fixture SHAs); nothing to stage. | COMPLIANT |
| 5. Enumerate encoding surfaces in lock-step | Check 51 (validator) + `test-validate-pack-check-51-flip-block.sh` + its yml wiring landed together; Check 50's `test-validate-pack-check-50-codec-single-source.sh` + its yml wiring landed together. Check 42 → 17/17 wired (no asymmetry). | COMPLIANT |
| 6. CI check runtime compounding | Check 51 leg1 = 1 file read + 2 substring tests; leg2 = bounded function-body slices over 2 named files; leg4 = glob over 2 bounded per-entry dirs (no whole-tree scan, no subprocess-per-entry). General validate-pack stayed under the runtime-budget guard (exit=0, no RUNTIME-BUDGET fail). | COMPLIANT |
| 7. Edit in place, not full rewrite | All source edits are targeted `Edit`/anchored insertions (clamp, gates, typo, Check-51 block, main() registration, yml lines); test-seam inserted via single anchored `awk` after the `set` line. New files are genuinely new. Re-read confirmed via validate-pack + test runs (nothing dropped). | COMPLIANT |
| 8. Pack-repo code-comment deferrals | No deferral comments authored (no `# TODO`/`# FIXME`); the in-code comments are explanatory clamp/gate notes, not deferrals. `grep` of edited files: zero plain `TODO`/`FIXME` added. | COMPLIANT |
| 9. Filename uniqueness heuristic | `find . -name "<name>" -not -path "./.git/*"` pre-create: zero hits for `test-validate-pack-check-51-flip-block.sh`, `test-validate-pack-check-50-codec-single-source.sh`, `tracker-deferral-gate-test.sh`. | COMPLIANT |
| 10. Rules-Applied Verification Block | This table; per-rule quoted evidence; no empty cells. | COMPLIANT |
| 11. PREFLIGHT + STOP-MEANS-STOP | `PREFLIGHT: 31/31 in-scope edits complete; verification PASS; HEAD 0027b10…; about to Write IMPL-REPORT …` emitted in the message immediately before this Write. No stop/halt/revert received. | COMPLIANT |

**Read-in-full attestation.** Read directly via tools this session, complete: CLAUDE.md (full,
incl. all `## Pack memory`, via system context + Read); `PLAN-BD-214-TRACKER-DEFERRAL.md` (full,
500 lines — Revision log + C1 §4 + green-per-commit §2); `ARCHITECTURE-BD-214-TRACKER-DEFERRAL.md`
(§§1-509 read in full incl. §3 flip-block + §6.3 Check-51 legs; §§510-853 are §7-§14 GH-deletion /
Track-2 / Rules blocks not load-bearing for C1's `scripts/`+`.github/` scope — C1 touches none of
those surfaces); `scripts/lib/tracker-config.sh`, `scripts/pack-tracker.sh`,
`scripts/tracker-migrate.sh`, `scripts/pack-td.sh` (the edited regions read in full before edit);
`.github/workflows/validate-pack.yml` (the uses-lines + test-wiring regions). No named C1 document
was derived rather than read.

**End of IMPL-REPORT-BD-214-C1.md**
