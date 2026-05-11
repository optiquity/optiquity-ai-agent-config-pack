# AUDIT — Batch 13 (BD-095 + BD-101 + BD-139)

Audit base: commits `735c152` (BD-095 + POQ-1/2 doc updates) and
`60ac6d9` (BD-101 + BD-139). Auditor: pack-reviewer per standing
rule §5.B (one review/fix cycle per batch).

## Verdict

**Findings — fix-follow BD recommended.** Implementation is functionally
correct on the BD-095 + BD-101 + BD-139 spec surface, all 5 enumerated
test suites are green (40 + 38 + 43 + 19 + 12 = 152/152), and the
validator passes 30/30. However four MAJOR/MINOR doc + CI gaps were
found that will let regressions land silently and that leave the
operator under-documented on the new exit code 31. None block ship; all
should be corrected in a small fix-follow.

## Severity legend

- **BLOCKER** — must fix before merging this batch.
- **MAJOR** — defect that allows undetected regressions or surprises
  the operator on the documented surface; fix-follow before next
  batch.
- **MINOR** — doc / cross-reference gap or single-suite-only
  coverage; fix-follow at convenience.
- **NIT** — cosmetic, comment-only, or future-proofing suggestion.

---

## Test-suite + validator pass confirmation

Re-ran all five suites and the validator on the audit-base
working-tree state:

```
test-migrate-v10-to-v11-dry-run.sh       40/40 PASS  (BD-095)
test-migrate-v10-to-v11-gates.sh         38/38 PASS  (BD-101)
test-migrate-v10-to-v11.sh               43/43 PASS  (BD-139 added Group 5)
scripts/test-migrator-core.sh            19/19 PASS
scripts/test-migrator-manifest.sh        12/12 PASS
python3 scripts/validate-pack.py         30/30 PASS
```

## Permission-bit hygiene

`git diff --summary 735c152^..60ac6d9` shows only `create mode` lines,
no `mode change` entries. New lib files (apply.sh, dry-run.sh,
resume.sh, checkpoint.sh, gate-{1,2,3}*.sh) ship as `100644`; the new
test runners ship as `100755`. Lib files are sourced via `.` from
`scripts/migrate-v10-to-v11.sh:374-390` so 644 is correct. **PASS.**

## Trinity-rule check

Neither commit touches `project-template/CLAUDE.md`, `AGENTS.md`,
`GEMINI.md`, nor any `.claude/` / `.codex/` / `.gemini/` skill or
agent file. Trinity rule N/A. **PASS.**

---

## BD-095 — two-phase migrator workflow

Spec sources audited:
- `BACKLOG.md:672-684`
- `supporting-docs/MERGE-STRATEGY.md` §A1
- `supporting-docs/MIGRATION-v10-to-v11.md:75-77, 122-149`
- ARCHITECTURE-BD-119.md §6.G / §6.H (referenced in code comments)

### Per-spec-requirement verification

| # | Spec requirement | Where implemented | Status |
|---|------------------|-------------------|--------|
| 1 | `--dry-run` produces report + dispositions.tsv + working-tree fingerprint; writes NO project files | `scripts/lib/migrate-v10-to-v11/dry-run.sh:142-232`; gate at `migrate-v10-to-v11.sh:140-143` | PASS |
| 2 | `--apply` refuses without fresh dry-run output for current fingerprint | `apply.sh:70-84` (no fingerprint), `apply.sh:115-128` (>24h), `apply.sh:136-154` (sha mismatch) | PASS |
| 3 | 24h freshness window per §6.G | `apply.sh:57` constant + `apply.sh:108-128` enforcement; test 3.2 covers | PASS |
| 4 | `--resume` forward-only with sentinel-based stage tracking | `resume.sh:117-129` refuses if S4/S5/S6 done sentinels exist; test 5.3 covers | PASS |
| 5 | Resume accepts both `.resolved` flag-file AND extension-removal signals (§6.H) | `resume.sh:43-57` classifier; tests 4.1 + 4.2 cover both signals | PASS |
| 6 | Bare invocation backwards-compat (auto-runs --dry-run if needed) | `migrate-v10-to-v11.sh:445-495`; test 6.1 covers | PASS |
| 7 | `--dry-run` post_dispatch_hook short-circuits writes | `migrate-v10-to-v11.sh:140-143` early-return; test 1.6 confirms working-tree unchanged | PASS |

### Spot-checks (5 random dry-run/apply/resume code paths vs tests)

1. `apply.sh:154` `EXIT_DIRTY` on fingerprint mismatch — test 3.3
   "--apply succeeded after drift" + "working-tree fingerprint
   changed" string check. **Covered.**
2. `apply.sh:127` `EXIT_NOT_BASELINE` on stale (>24h) — test 3.2
   asserts rc!=0 + "24h freshness" string. **Covered.**
3. `apply.sh:259` clean exit 0 on conflict pause — test 4.0 covers
   (sidecars produced + apply rc=0 for paused). **Covered.**
4. `resume.sh:48` `.resolved` flag-file branch — test 4.1 covers.
   **Covered.**
5. `resume.sh:50` extension-removed branch — test 4.2 covers.
   **Covered.**
6. `resume.sh:127` forward-only EXIT_INTERNAL — test 5.3 covers.
   **Covered.**
7. `migrate-v10-to-v11.sh:485` bare-invocation auto-rerun — test 6.1
   covers. **Covered.**

### Findings — BD-095

#### M-1 (MAJOR) — New BD-095 test suite is not wired into CI

**File:** `.github/workflows/validate-pack.yml:52-112`
**Evidence:** No `test-migrate-v10-to-v11-dry-run.sh` step exists in
the `tests:` job. The `tests:` job currently runs 18 suites; the new
BD-095 suite (40 cases — `--dry-run`, `--apply` freshness, `--resume`
forward-only, bare-invocation backwards compat) is not among them.
**Impact:** Regressions in the new dry-run / apply / resume mode
dispatcher will not be caught by CI. Post-merge breakage in the
freshness window, the fingerprint comparator, or the bare-invocation
auto-flow can land silently on `main`.
**Recommended fix:** Add a step under `tests:`:
```yaml
- name: migrate-v10-to-v11 dry-run/apply/resume tests (BD-095)
  if: always()
  run: bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh
```

#### M-2 (MINOR) — `--resume` stub in framework parser is now dead code

**File:** `scripts/lib/migrator-core.sh:264-269`
**Evidence:** `_migrator_parse_args` still contains
`die "--resume not yet implemented; tracked as BD-095" "$EXIT_INTERNAL"`
for the `--resume` case. BD-095 has shipped — the adapter intercepts
`--resume` before forwarding to the framework
(`migrate-v10-to-v11.sh:428-435`), so the framework-level rejection is
unreachable in normal use. But any new adapter that forwards
`--resume` straight to `migrator_run` would hit this defunct stub.
**Impact:** Stale code; misleading comment that says `--resume` is not
yet implemented. Future migrator authors might believe the framework
genuinely lacks resume support.
**Recommended fix:** Either rewrite the stub to be a polymorphic
no-op (let adapters opt-in by setting `_MIGRATOR_MODE=resume`) or
update the die-message + comment to: "`--resume` is per-adapter; the
v10→v11 adapter handles it via `lib/migrate-v10-to-v11/resume.sh`.
Other adapters that need resume must wire similar dispatch in their
own pre-`migrator_run` mode parsing."

#### N-1 (NIT) — Bare-invocation auto-rerun deviates from spec (POQ-4)

**File:** `scripts/migrate-v10-to-v11.sh:467-484`
**Evidence:** The bare-invocation auto-rerun fires on (a) missing
fingerprint, (b) stale fingerprint (>24h), (c) drifted fingerprint.
The literal BD-095 spec says only (a) "auto-runs --dry-run first if
no fresh dry-run output exists". The implementation report flagged
this as POQ-4 ("strict superset of literal spec — accepted"). Behavior
is operator-friendlier than spec; flagging only as NIT in case future
audits cross-reference the spec. No action needed unless the spec is
narrowed.

---

## BD-101 — three validation gates

Spec sources audited:
- `BACKLOG.md:787-802`
- BD-095 BACKLOG entry refers to gate failures using
  `MIGRATOR_OWN_SIDECAR_SUFFIX` (POQ-2 closure)

### Per-spec-requirement verification

| # | Spec requirement | Where implemented | Status |
|---|------------------|-------------------|--------|
| 1 | Gate 1 fires during dry-run (read-only summary) | `dry-run.sh:212-230`; gate at `gate-1-dry-run-summary.sh:40-86`; tests 1.1-1.4 | PASS |
| 2 | Gate 2 fires after Phase-A (trinity addenda + HELP-FRAGMENT + dispositions consistency + relocations + validate-pack) | `apply.sh:361-388` (post-S6 wrap) + `resume.sh:253-260` (resume tail); checks at `gate-2-phase-a-verify.sh:50-64`; tests 2.1-2.4 | PASS |
| 3 | Gate 3 fires after Phase-B conditionally (tracker mode only) | `apply.sh:380-386` + `resume.sh:261-267`; SKIP path at `gate-3-phase-b-verify.sh:58-63`; tests 3.1-3.3 | PASS |
| 4 | Gate 3 cleanly SKIPs when tracker mode not active | `gate-3-phase-b-verify.sh:58-63` returns 0 with `[INFO] tracker: skipped`; test 3.1 covers | PASS |
| 5 | EXIT_GATE_FAILED=31 distinct from stage failures (20-30) | `migrator-core.sh:60-63`; test 4.1 + 4.2 cover | PASS |
| 6 | Gate failures route through A1 UX (sidecar / restore-from-backup recovery) | `gate-2-phase-a-verify.sh:71-77` prints recovery options + names `restore-from-backup.sh` | PASS |
| 7 | Mapping integrity check (id-map.json positive ints) | `checkpoint.sh:256-284`; test 3.2 covers | PASS |
| 8 | Mirror freshness check (BACKLOG.md mtime ≥ last_forward_run) | `checkpoint.sh:288-322` | PASS (best-effort: skips silently if `tracker_config_get` not loaded) |
| 9 | `pack tracker doctor` invocation | `checkpoint.sh:326-344`; test 3.3 covers env-dependent semantics | PASS |
| 10 | EXIT_GATE_FAILED-31 distinguishes for `--resume` reconciliation | `apply.sh:373, 384`; `resume.sh:258, 265` | Implementation present, but operator-recovery contract has a gap — see F-1 below |

### Spot-checks (5 random gate-test-case assertions vs gate code)

1. Gate 1 line 84 `return EXIT_GATE_FAILED` on FAIL — test 1.2
   asserts rc=31 after injecting `unknown-classification` row.
   **Verified.**
2. Gate 1 line 60 `[FAIL] report:` on missing report.md — test 1.3
   asserts "report.md not rendered". **Verified.**
3. Gate 2 trinity FAIL path via `checkpoint_check_trinity_addenda`
   line 122 grep — test 2.2 strips H2 marker, asserts `[FAIL] trinity`
   string + rc=31. **Verified.**
4. Gate 2 help-fragment byte-mismatch via `cmp -s` at
   `checkpoint.sh:169` — test 2.3 appends to HELP-FRAGMENT, asserts
   `[FAIL] help-fragments` + "HELP-FRAGMENT.md differs". **Verified.**
5. Gate 3 SKIP when tracker.toml absent via
   `checkpoint_tracker_mode_active:355` — test 3.1 omits tracker.toml,
   asserts SKIP banner. **Verified.**

### Findings — BD-101

#### F-1 (MINOR) — No end-to-end test that `--apply` propagates rc=31 on Gate 2 failure

**Files:** `scripts/tests/test-migrate-v10-to-v11-gates.sh:345-360`,
`scripts/lib/migrate-v10-to-v11/apply.sh:361-388`
**Evidence:** Test 4.3 explicitly punts on the end-to-end EXIT
propagation: "Skip a heavy end-to-end here and rely on 2.2's direct
gate-call assertion of rc=31." But tests 2.2/2.3/2.4 invoke
`migrate_v10_to_v11_gate2_run` directly — they never assert that
`bash MIGRATE_SH --apply <target>` exits with code 31 when the
post_report_hook wrapper observes a Gate 2 FAIL. The actual
propagation through:
```
apply.sh:361-388 -> exit "${EXIT_GATE_FAILED:-31}"
```
is unverified end-to-end. A regression in the apply.sh
`migrator_post_report_hook` wrapper (e.g. swallowing the gate's
non-zero return) would not be caught.
**Impact:** The "BD-101 EXIT_GATE_FAILED is properly threaded
through" claim in the BACKLOG entry rests on inspection only, not on
test coverage.
**Recommended fix:** Add a single end-to-end assertion: drive
`--dry-run` + `--apply` against a fixture that will fail Gate 2
(e.g. pre-mutate target trinity to remove the H2 marker between dry-run
and apply via a `migrator_post_report_hook` shim, or — simpler — write
a fixture where validate-pack will fail), assert the migrate-sh
process exit code is 31.

#### F-2 (MINOR) — MIGRATION-v10-to-v11.md exit code table missing 31 (EXIT_GATE_FAILED)

**File:** `supporting-docs/MIGRATION-v10-to-v11.md:138-149`
**Evidence:** The exit-codes table for the migrator lists 0, 10-15,
21-30 (stage failures). It does not list `31` or the new
`EXIT_GATE_FAILED` code BD-101 introduced. The script now emits Gate
1/2/3 banners during normal operation and may exit 31 on gate FAIL,
but the user-facing migration doc is silent on this. Operators
reading the doc will be surprised by the new exit code and the new
gate banners.
**Impact:** Doc-completeness gap. A user who hits a Gate 2 FAIL sees
exit code 31 with no reference in the doc and may interpret it as an
unknown failure mode.
**Recommended fix:** Add a row to the exit-code table:
```
| 31 | Verification gate (BD-101) failed (Gate 1/2/3) | Read the [FAIL] lines; either fix the underlying defect or restore from backup at .pack-migrate-v10-to-v11-backup/ and start over. |
```
And add a brief Step describing what the three gate banners mean.

#### F-3 (MAJOR) — New BD-101 test suite is not wired into CI

**File:** `.github/workflows/validate-pack.yml:52-112`
**Evidence:** Like BD-095, the new `test-migrate-v10-to-v11-gates.sh`
suite (38 cases) is not referenced anywhere in the workflow. Future
edits to `gate-{1,2,3}-*.sh`, `checkpoint.sh`, or the apply.sh /
resume.sh wrappers will not be guarded by CI.
**Impact:** Same as M-1 — silent regression risk on the gate surface.
**Recommended fix:** Add a step under `tests:`:
```yaml
- name: migrate-v10-to-v11 verification gates (BD-101)
  if: always()
  run: bash scripts/tests/test-migrate-v10-to-v11-gates.sh
```

#### F-4 (MINOR) — Gate-fix-and-continue workflow is impossible

**Files:** `apply.sh:361-388`, `resume.sh:117-129`
**Evidence:** When `--apply` reaches the post_report_hook wrapper, the
sentinels for S0..S6 are already marked `.done` (S0..S2 by
pre_dispatch_hook line 200-206; S3 by after_dispatch line 215; S4..S5
by post_dispatch wrapper line 330-331; S6 by post_report_hook line
362). If Gate 2 then FAILs and emits exit 31, the user is stuck:
- `--apply` again would refuse via `_stage_libs` already-migrated
  preflight (the working tree is no longer v10-shaped).
- `--resume` will refuse via the forward-only guard (resume.sh:117-129
  rejects when S4/S5/S6 .done sentinels exist).
- The only recovery is `restore-from-backup.sh`, which is per spec
  (BD-101 BACKLOG entry: "Failures route through A1 UX") — but the
  Gate FAIL message at gate-2-phase-a-verify.sh:71-77 implies the
  user has a choice between "(a) inspect each [FAIL] line and fix the
  underlying defect" and "(b) Restore from backup". Option (a) is not
  actually achievable for many Gate 2 defects (e.g. an HELP-FRAGMENT
  mismatch the user fixes by hand) without a path to re-run the
  gate.
**Impact:** Operator UX gap rather than spec defect. Spec is satisfied
(restore-from-backup is the documented recovery). But the gate FAIL
message dangles option (a) as if it were a viable workflow when it
isn't.
**Recommended fix:** Either (i) tighten the Gate FAIL message to
state up-front that fix-and-continue is not supported and option (a)
must be followed by restore-from-backup + re-run; OR (ii) introduce
a `--rerun-gates` flag that re-fires Gate 2/3 against the existing
state-dir (no stage re-run required).

#### N-2 (NIT) — Check 26 in validate-pack.py does not enforce EXIT_GATE_FAILED

**File:** `scripts/validate-pack.py:1853-1867`
**Evidence:** Check 26's `required_exits` list enforces the 8
baseline exit codes BD-119 froze. BD-101 added a 9th
(`EXIT_GATE_FAILED`); the check is silent on it. Removing the
`readonly EXIT_GATE_FAILED=31` line in the future would not be
caught.
**Impact:** Future-proofing only; current state is correct.
**Recommended fix:** Either extend `required_exits` with
`EXIT_GATE_FAILED` (and document the new floor as 9 codes), or
explicitly note in the Check 26 docstring that BD-101 codes are out
of scope.

---

## BD-139 — Batch 12 audit fix-follow (shallow correctness check)

Per prompt: shallow correctness check only — the deep audit was the
BD-104 audit that produced BD-139.

| Finding | Claim | Verified |
|---------|-------|----------|
| F-1 (MAJOR) | 4 BD-104 test cases added to test-migrate-v10-to-v11.sh; count 39 → 43 | YES — `test-migrate-v10-to-v11.sh:298` adds Group 5 with 4 cases (5.1-5.4); suite reports 43/43 PASS |
| F-2 (MINOR) | MIGRATION stage table updated with S4a/S4b rows + lead-in | YES — `MIGRATION-v10-to-v11.md:122-134` |
| F-3 (MINOR) | Banners relabeled to `S4a (rename)` / `S4b (relocate)`; fail_stage S4 arity preserved | YES — `migrate-v10-to-v11.sh:173, 196, 211, 215, 228, 247, 251` (sub-stage prefix in fail msgs; `fail_stage S4` arity intact) |
| F-4 (NIT) | `$mv_stderr` surfaced via info log in fallback branch | YES — `migrate-v10-to-v11.sh:206` |
| F-5 (NIT) | BACKLOG BD-104 Resolved-line clarifies "179 vs 181" disposition | YES — `BACKLOG.md` BD-104 Resolved line includes the F-5 reconciliation paragraph |

BD-139 self-report claim of "all 5 PASS" is corroborated by code +
docs + suite output. **PASS.**

### BD-139 / BD-101 coexistence

Both BDs edited `scripts/migrate-v10-to-v11.sh`. Verified line-disjoint:
- BD-139 banner work: lines 163-260 (rename + relocate functions)
- BD-101 source-additions: lines 378-389 (4 source lines for the 4
  new lib files)

`fail_stage S4` arity check: `grep -n 'fail_stage S4' migrate-v10-to-v11.sh`
returns 5 hits, all 2-argument calls (stage + message). BD-095
sentinel filename `stage-S4.done` and exit code 24 (= 20 + 4) stay
stable. **PASS.**

---

## Cross-pack consistency findings

#### F-5 (MINOR) — README Repository Layout omits new lib + test files

**File:** `README.md:179-209`
**Evidence:** README §Repository Layout lists `scripts/lib/` files
including the BD-119 framework members but does not mention the new
adapter-private subdirectory `scripts/lib/migrate-v10-to-v11/` (apply.sh,
dry-run.sh, resume.sh, checkpoint.sh, gate-{1,2,3}*.sh — 7 new files
across this batch). README also lists the migrator-core / migrator-
manifest test scripts (lines 205-206) but does not list the two new
test runners under `scripts/tests/` (`test-migrate-v10-to-v11-dry-run.sh`,
`test-migrate-v10-to-v11-gates.sh`).
**Impact:** Per pack standing rule "When files are added, moved, or
removed, verify the Repository Layout section in README.md is updated."
**Recommended fix:** Add a stanza under `scripts/lib/`:
```
└── migrate-v10-to-v11/                      v10→v11 adapter-private libs (v11; BD-095 + BD-101)
    ├── dry-run.sh, apply.sh, resume.sh      Two-phase mode dispatchers (BD-095)
    ├── checkpoint.sh                        BD-101 verification helpers
    └── gate-{1,2,3}-*.sh                    Pre/post Phase-A/Phase-B gates (BD-101)
```
And add the two new test runners to the test-script listing.

#### F-6 (MINOR) — MERGE-STRATEGY.md does not reference BD-101 gates

**File:** `supporting-docs/MERGE-STRATEGY.md`
**Evidence:** MERGE-STRATEGY §A1 was updated by BD-095 to reference
the new mode dispatch but no equivalent update was made for BD-101.
The BACKLOG entry says BD-101 failures "route through A1 UX" — the
A1 doc itself has no mention of the gate FAIL pathway, restore-from-
backup recovery for gate failures, or the new exit code 31.
**Impact:** Doc-internal consistency gap. The A1 UX doc and the gate
FAIL message reference each other indirectly through code; an
operator reading A1 will not learn about the gates that produce the
FAILs A1 is supposed to handle.
**Recommended fix:** Add a paragraph to MERGE-STRATEGY.md §A1
covering: "After Phase-A/Phase-B, three BD-101 verification gates
fire (Gate 1 inside `--dry-run`; Gate 2 + Gate 3 inside `--apply`).
On gate FAIL the script exits with `EXIT_GATE_FAILED=31`; recovery
is `restore-from-backup.sh` + re-run of `--dry-run` + `--apply`."

---

## Summary of recommended fix-follow

A single fix-follow BD covering 6 findings is appropriate. Suggested
scope:

- **F-3 (MAJOR)** — wire BD-101 gate suite into CI
- **M-1 (MAJOR)** — wire BD-095 dry-run suite into CI
- **F-1 (MINOR)** — add end-to-end EXIT 31 propagation test
- **F-2 (MINOR)** — document exit code 31 + gates in MIGRATION-v10-to-v11.md
- **F-4 (MINOR)** — clarify Gate FAIL message that fix-and-continue requires restore-from-backup
- **F-5 (MINOR)** — README Repository Layout updates (3 new entries)
- **F-6 (MINOR)** — MERGE-STRATEGY.md §A1 paragraph on BD-101 gates
- **M-2 (MINOR)** — clarify framework `--resume` stub comment
- **N-1 (NIT)**, **N-2 (NIT)** — at convenience or accept-as-shipped

Two MAJOR items both concern CI test wiring — landing them together is
trivial. Doc + UX clarifications are a single `docs:` commit.

Recommend opening one BD: e.g. **BD-140 — Batch 13 audit fix-follow
(2 MAJOR + 5 MINOR + 2 NIT)**.

---

## What was NOT found

No problems with:
- Trinity-rule symmetry (no trinity touched)
- Permission-bit hygiene (no mode changes)
- Test-suite green-status (152/152 PASS across 5 suites)
- Validator green-status (30/30 PASS)
- BD-139 fix-follow correctness (all 5 findings correctly addressed)
- BD-095/BD-139 line-disjointness in migrate-v10-to-v11.sh
- Sentinel naming + exit-code formula stability
- BD-101 EXIT_GATE_FAILED constant + slot choice (31 above stage cap 30)
- Fingerprint surface choice (intentionally limited to v10 customization
  surface; tracker state changes correctly excluded)
- Resume sidecar classification (both signals correctly handled)
- Gate 3 SKIP path (cleanly returns 0 in flat-file mode)
