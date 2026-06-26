# CONFIRM2 — Decisive confirmation review of ARCHITECTURE-BD-206.md

**Reviewer:** `reviewer-bd206-arch-confirm-2` (FRESH; not the author, not either reconciler,
not either prior reviewer).
**Review target:** `/Users/david/Developer/_tmp/pack-handoff-bd206-restart/ARCHITECTURE-BD-206.md`
(1277 lines — read IN FULL).
**Repo HEAD:** `66c833223c2c8e3b7657e3c24e7c4ddfb539a3d7` (branch `v11-dev`), 8 uncommitted
Wave-A deletions in the working tree (7 project sidecars + 1 maintenance RESEARCH doc).
**Date:** 2026-06-26.
**Mode:** read-only on pack + OT; ran only read-only git + read-only `validate-pack.py` +
read-only shell tests (scratch tmpdirs) + a read-only graphify query. Sole write = this report.
**Anti-contamination:** did NOT open any prior BD-206 review/reconcile/adversarial/RESTART doc
nor anything under `/tmp/bd206-REJECTED-DO-NOT-READ/`. Inputs limited to the allowed set
(ARCHITECTURE-BD-206.md, CENSUS, DECISIONS, INVESTIGATION via grep, backlog/BD-206.md +
BD-249.md, the live repo, the GOLD read-only).

---

## OVERALL VERDICT: **PASS (with SHOULD/NIT findings)**

The under-counted-blast-radius **class is CONFIRMED CLOSED** for the tracker family: my
independent 52-file re-sweep finds the **same candidate set** EE-11 measured, and every
M-mono REMOVE/REPOINT vs M-track KEEP classification is **substantively correct** — no
M-track surface is wrongly slated for removal in a way that survives O19's prose carve-out,
and no live M-mono surface is wrongly KEPT. The 7 confirmation findings (BLOCKER-A, MUST-A,
MUST-B, SHOULD-A..D) and the 5 added dormant surfaces (tracker-doctor / migrate-forward /
promote / phase-task / tracker-migrate) are each verified against the live repo and are
**sound**. No new BLOCKER or MUST. The findings below are SHOULDs and NITs — they sharpen the
class-closure artifact and correct two empirical overstatements, but none invalidate the
design or its wave plan. **The design may advance to the planner.**

Severity tally of NEW findings: **0 BLOCKER, 0 MUST, 3 SHOULD, 3 NIT.**

---

## FOCUS AREA 1 — Tracker-family class CLOSED? (the priority)

**Verdict: CLOSED (sound), with one SHOULD (S-1) on the row-10/row-20 line-range overlap and
one NIT (N-1) on the EE-11 reproduction command.**

### Candidate set — independently re-derived, MATCHES EE-11

`git ls-files 'scripts/lib/tracker-*.sh' 'scripts/tracker-*.sh' 'scripts/pack-tracker.sh'
'scripts/tests/tracker-*.sh' 'scripts/tests/test-tracker-*.sh' '*tracker*.toml*'` →
**52 tracked files** (lib=18, scripts=2, tests=22, toml=10). This EXACTLY matches EE-11
Command 1's "52 tracked files — 18 lib + 1 tracker-migrate + 1 pack-tracker + 16
`tracker-*-test.sh` + 6 `test-tracker-*.sh` + 10 `.toml`." A fourth reviewer re-running
Command 1 gets the same set. **CONFIRMED.**

### NIT N-1 — EE-11 "Command 2" returns ZERO when run literally as documented

The doc states (EE-11 conclusion, line 278): "A fourth reviewer re-running Command 1 +
Command 2 finds the same 52-file candidate set and the same 21 classified surfaces." I ran
Command 2 verbatim:
```
FILES=$(git ls-files 'scripts/lib/tracker-*.sh' 'scripts/tracker-*.sh' 'scripts/pack-tracker.sh' 'scripts/tests/tracker-*.sh' 'scripts/tests/test-tracker-*.sh' '*tracker*.toml*')
git grep -nE '\[mirror\]|mirror_required|location_backlog|...' -- $FILES
→ (empty output, exit 0)
```
It returns **nothing**. Two compounding causes: (a) the unquoted `$FILES` expansion of the
`*tracker*.toml*` glob members interacts badly with `git grep -- $FILES`; (b) `mirror_required`
lives ONLY in `validate-pack.py:2481,2492,2572,2577,2790,2794,2796` — which is **NOT in the
52-file set** — so that pattern can never match within the documented scope. When I instead
pass the pathspecs directly to `git grep` (not via the variable), all the expected surfaces
appear. **Impact:** the *substance* of EE-11 is verifiable (I reproduced every surface via
direct grep), but the documented reproduction recipe is broken — a NIT for the planner/coder
to note (the grep-zero gates must use direct pathspecs, and `mirror_required` belongs in a
`validate-pack.py`-scoped grep, not the 52-file one).

### Every Wave-A REMOVE/REPOINT surface — independently confirmed

- **Row 1 (Check-29 `mirror_required=True`):** `validate-pack.py:2796` passes
  `mirror_required=True` for the client example (`:2793-2796` verbatim). The `:2577`
  `if mirror_required or "mirror" in data` logic means a flip to `False` makes a client example
  WITHOUT `[mirror]` PASS while one WITH `[mirror]` still validates keys. **Flip is correct.**
- **Row 2 (client example `[mirror]` table):** `project-template/tracker.toml.project-example:37-44`
  ships `[mirror] enabled=true location_backlog="BACKLOG.md" … regenerate_on_write=true`,
  `mode.state="flat-file"`, `prefix="TD"`. M-mono → REMOVE. **CONFIRMED.**
- **Row 5 (live emitter):** `tracker-init.sh:366-379` builds a client-only `mirror_block`
  (`[mirror] enabled=true location_backlog="BACKLOG.md" …`) when `surface=="client"`;
  `:320-333` carry the "client surface keeps it until BD-206" comments. M-mono → REPOINT
  (drop the block). **CONFIRMED (MUST-B).**
- **Row 21 (`.dangling-ref-allowlist.txt`):** `:101 token: docs/project/BACKLOG.md` +
  `:104 token: docs/project/CHANGELOG.md` with "regenerated … mirror" reasons. M-mono → REMOVE;
  KEEP `:95,98 pack-ops/BACKLOG.md|CHANGELOG.md` (retired-pack-monolith no-recreate refs).
  **CONFIRMED (SHOULD-A); line numbers exact.**

### Every Wave-E REPOINT surface — independently confirmed

- **Row 7 `tracker-agent-read.sh:277-278`:** `TD-*) mirror_path="$repo_root/docs/project/BACKLOG.md"`
  / `phase-*) …/IMPLEMENTATION-PLAN.md`. M-mono fallback → REPOINT. **CONFIRMED.**
- **Row 9 `tracker-doctor.sh:173-174`:** `if [[ -f "$repo_root/docs/project/BACKLOG.md" ]]` —
  client-monolith staleness probe. M-mono → REPOINT. **CONFIRMED.**
- **Row 14 `tracker-promote.sh:261-271,479-480,525-526,597-598`:** reads/writes
  `$repo_root/BACKLOG.md` + `docs/project/BACKLOG.md` / `IMPLEMENTATION-PLAN.md` fallback;
  `:255` "In flat-file mode the BACKLOG.md is canonical" — exactly the per-entry→monolith
  assumption BD-206 abolishes. M-mono → REPOINT. **CONFIRMED.**
- **Row 15 `tracker-phase-task.sh:7,24,140,487`:** parses/emits `IMPLEMENTATION-PLAN.md`
  fragments. M-mono → REPOINT. **CONFIRMED.**

### SHOULD S-1 — EE-11 rows 10 and 20 classify an OVERLAPPING `tracker-migrate-forward.sh`
line range as BOTH REPOINT and KEEP

- **Row 10** cites `tracker-migrate-forward.sh:1387-1432,2142-2172` → **M-mono → REPOINT (O19,
  Wave E)**.
- **Row 20** cites `tracker-migrate-forward.sh:1992-2253` (+ reverse, + roundtrip fixtures) →
  **M-track / v10-INPUT → KEEP**.
- `:2142-2172` is **fully inside** `:1992-2253`. The enclosing function
  `tracker_migrate_status_report()` (`:2108-2217`) is therefore claimed by BOTH a REPOINT row
  and a KEEP row.

The substance at `:2160-2173` (the `else`/client branch) reads `$repo_root/BACKLOG.md`, checks
for the `<!--` read-only mirror header (`:2166`), and reports `mirror_age` — i.e. it is the
**M-track tracker→file read-only-mirror staleness probe** (the `tracker-mirror.sh` feature),
NOT the per-entry→monolith assumption. Likewise `:1404,1410` (mirror-only short-circuit, calls
`_tmf_regen_mirror`) and `:1429` (the forward INPUT read) are tracker-mode M-track / migration
paths. **Classifying `:2142-2172` as M-mono REPOINT is at best ambiguous and risks a Wave-E
coder repointing an M-track staleness probe to the per-entry tree, breaking the dormant
tracker→file feature.** Mitigant: O19's deliverable prose (lines 699-705) carries the explicit
M-track carve-out ("where they manage the tracker→file read-only mirror header … KEEP"), so a
coder reading O19 in full would not break it — which is why this is a SHOULD, not a MUST. The
planner/coder must reconcile the EE-11 table's overlapping line ranges before the Wave-E commit
(draw the M-mono/M-track boundary line-precisely in `tracker-migrate-forward.sh`).

### NIT N-2 — surface beyond the 52-file set: `test-fixtures/build.sh:627-632` carries a
client `[mirror]` table

A whole-tree backstop (`git grep -nE 'location_backlog|regenerate_on_write'` across
`scripts/`+`project-template/`+`test-fixtures/`) surfaces `test-fixtures/build.sh:627-632` —
a `[mirror] enabled=true location_backlog="BACKLOG.md" … regenerate_on_write=true` block inside
`_build_v11_tracker_on()`. The enclosing fixture is `mode.state="tracker"` (`:616`),
`prefix="TD"` (`:621`), forward_complete=true — i.e. it is the **M-track tracker-mode** fixture
(KEEP is correct). EE-11 did NOT enumerate it because `test-fixtures/` is outside the 52-file
`git ls-files` set. No-break (KEEP), but it is a `[mirror]`-encoding surface in the broader
tracker family that the "exhaustive" sweep missed — the completeness claim is slightly narrower
than "exhaustive." NIT only (correct disposition; no deliverable needed).

### NIT N-3 — EE-11 row 17 RATIONALE is inaccurate for `flat-file-mode.toml` (CONCLUSION still
correct)

Row 17 classifies `scripts/tests/fixtures/tracker-config/{tracker-mode,flat-file-mode,
not-yet-migrated}.toml` `[mirror]` tables as "tracker-mode/staleness-test fixtures … M-track →
KEEP." But `flat-file-mode.toml` is `mode.state="flat-file"`, `prefix="BD"` (PACK), consumed
ONLY by `tracker-config-test.sh:123` which asserts `tracker_mode()=="flat-file"` — a
**mode-resolution parse fixture**, not a tracker-mode staleness fixture. Its `[mirror]` table is
never staleness-validated (Check 29 short-circuits when `mode != tracker`). KEEP is the right
CONCLUSION (no-break), but the row's "tracker-mode/staleness" rationale mischaracterizes this
fixture. NIT only.

---

## FOCUS AREA 2 — M-mono vs M-track classification CORRECT?

**Verdict: SOUND. No M-track surface wrongly slated for removal (modulo the S-1 ambiguity); no
live M-mono surface wrongly KEPT.**

I independently verified the two-concept boundary against the actual code:

- **M-track KEEP rows confirmed PRESERVED:**
  - Row 12 `tracker-mirror.sh:1-85` — the read-only mirror header write/strip helper (the
    feature itself). Sourced by forward + reverse. **KEEP correct.**
  - Row 11 `tracker-migrate-reverse.sh:1604-1612` — the `else`/client branch emits
    `$repo_root/BACKLOG.md`/`IMPLEMENTATION-PLAN.md`/`CHANGELOG.md` on reverse (DISABLE tracker).
    Confirmed it is the reverse-emit of the M-track mirror, NOT the M-mono assumption.
    **KEEP correct.**
  - Row 13 `tracker-header-snapshot.sh` — preamble snapshot/apply helper for reverse-emit.
    **KEEP correct.**
  - Rows 18-19 (`tracker-config-test.sh:73`, `tracker-config-schema-test.sh` Tests 15/16/17) —
    pure-TOML-parse + M-track staleness/pack-`[mirror]` cases. I confirmed `tracker-config.sh`
    is a parser and Tests 15/16/17 exercise the no-mirror-surface guard + the pack optional-
    `[mirror]` malformed cases — UNAFFECTED by the client-example flip. **KEEP correct.**
  - Row 20 `tracker-migrate-forward.sh:1992-2253` (forward parses a v10 BACKLOG.md INPUT;
    reverse emits the M-track mirror) — the forward-migration v10-INPUT read is legitimately
    KEEP (it reads a v10 monolith INPUT, not a v11 mirror). **KEEP correct** — except for the
    S-1 line-range overlap with row 10.

- **The v10-INPUT-read vs reverse-emit vs live emitter distinction (focus-area-2 special-
  attention item) is correctly drawn:** the forward v10-INPUT read (`:350-387`,
  `parse_backlog`/`parse_plan` of a v10-shape `BACKLOG.md`) is KEEP (row 20); the reverse-emit
  (row 11) is KEEP (M-track); the LIVE `tracker-init.sh` client emitter (row 5) is REPOINT
  (M-mono — it WRITES a v11 client `[mirror]` pointing at a deleted monolith). These three are
  not conflated. **CONFIRMED sound.**

- **No live M-mono surface wrongly KEPT:** the only borderline is `flat-file-mode.toml`
  (N-3) — KEPT, and correctly so (it is a BD-prefix mode-resolution fixture, never validated
  for mirror semantics). All genuinely-live M-mono surfaces (rows 1,2,5,7,9,14,15,21) are
  REMOVE/REPOINT.

---

## FOCUS AREA 3 — The 7 + 5 resolutions sound?

**Verdict: ALL 7 confirmation findings + the 5 added dormant surfaces verified against the live
repo — sound.**

- **BLOCKER-A (Test 7 inversion):** `tracker-config-schema-test.sh:230-243` strips `[mirror]`
  from GOOD_CLIENT and asserts `7.1 missing mirror on client → exit nonzero` + `7.2 message
  names mirror as missing`. This PINS `mirror_required=True`. Baseline run: 40/0 PASS (green on
  old shape). Under the (A) flip it MUST invert (missing client `[mirror]` → PASS). It is in the
  shell battery (`scripts/tests/*.sh`), so it MUST land in the Wave-A inversion set — which the
  design (O25, EE-9 Wave-A row, §6) does. **RESOLVED.**
- **MUST-A (`tracker-agent-read-test.sh`):** `:71` seeds ONLY `docs/project/BACKLOG.md`
  (`**TD-010 — Document quux**`), no per-entry tree; `:191-192` `2.3 TD-010 entry header`
  asserts the read resolves. Baseline run: 57/0 PASS. Flips under O19's `:277-278` repoint.
  Correctly Wave-E (dormant) lock-step. This IS the BD-214 C1 `verify-full-ci-suite` recurrence
  file — folding it into O19 closes the recurrence. **RESOLVED.**
- **MUST-B (live emitter `tracker-init.sh:366-379`):** confirmed the emitter writes a client
  `mirror_block`. Without dropping it, a fresh `pack tracker init --surface client` would
  re-emit the very `[mirror]` table the static example (row 2) drops, pointing at a deleted
  file — a self-contradiction. O25's emitter-drop + the 3.5 inversion
  (`tracker-init-test.sh:298-302`, which asserts `mirror.location_backlog="BACKLOG.md"` etc.)
  end the contradiction. The pack-surface 3.3b assert (`:256-264`, "pack config omits `[mirror]`")
  stays green — verified the emitter drop only touches the client branch. **RESOLVED — this DOES
  end the "fresh init re-emits the table" contradiction.**
- **SHOULD-A (`.dangling-ref-allowlist.txt:101,104`):** confirmed line numbers + reasons; REMOVE
  both, KEEP `:95,98`. Dangling-ref check does not hard-fail on unused tokens but the allowlist
  must be sized to the legitimate set (`ci-guard-measure-then-bound`). **RESOLVED.**
- **SHOULD-B (`test-fixtures/README.md` round-trip prose):** the build.sh round-trip
  (`build.sh:537-573`: `die "monolithic mirror missing"`, `per_entry_regenerate_mirror`,
  `cmp -s` byte-identity) is confirmed present; O23 abolishes its subject and rewrites the README
  prose. **RESOLVED.**
- **SHOULD-C (`MERGE-STRATEGY.md:267-280`):** confirmed the "regenerated mirrors of the per-entry
  trees … the migrator overwrites them … NOT authoritative edit targets" prose exists and is
  invalidated by no-mirror; also carries `_format.md` at `:270`. Classified IN-SCOPE for BD-206
  (live project-side merge-dispatch operating-doc prose, NOT pack-side/BD-249, NOT historical).
  **RESOLVED — classification sound.**
- **SHOULD-D (`tracker-config-test.sh:73`):** classified KEEP/NO-BREAK (pure-parse of the
  tracker-mode fixture). Verified: `tracker-config.sh` is a TOML parser; the assert verifies the
  parse, not M-mono semantics. **RESOLVED.**

- **The 5 added dormant surfaces (beyond the review's 7):** rows 9
  (`tracker-doctor.sh:173-174`), 10 (`tracker-migrate-forward.sh`, see S-1), 14
  (`tracker-promote.sh`), 15 (`tracker-phase-task.sh`), 16 (`scripts/tracker-migrate.sh`
  project share / `pack-tracker.sh` PACK-side OUT). I confirmed each exists and reads/writes a
  project monolith (or is correctly PACK-side OUT). All M-mono → REPOINT under O19 (Wave E),
  except the row-10 overlap (S-1). **RESOLVED (with S-1 caveat on row 10).**

---

## FOCUS AREA 4 — EE-9 Wave-A full-battery-green incl. tracker tests?

**Verdict: the Wave-A inversion-set LOGIC holds (the tracker tests ARE in it, correctly); but
one SHOULD (S-2) — EE-9's "baseline battery is green" attestation is empirically FALSE at the
stated reconciliation state, and one migration-test surface is under-attested.**

### What I confirmed green-on-old-shape (so they DO flip under Wave A / land in the inversion set)

- `tracker-config-schema-test.sh`: 40/0 PASS (Test 7 pins old behavior → Wave-A inversion). ✓
- `tracker-init-test.sh`: 104/0 PASS (3.5 pins emitted client `[mirror]` → Wave-A inversion). ✓
- `tracker-config-test.sh`: 32/0 PASS (1.5 pure-parse, KEEP). ✓
- `tracker-agent-read-test.sh`: 57/0 PASS (Wave-E inversion). ✓
- `tracker-migrate-forward-test.sh` 204/0, `tracker-migrate-reverse-test.sh` 196/0,
  `test-tracker-promote-direct.sh` 31/0, `test-tracker-phase-task.sh` 100/0 — all green-on-old-
  shape (Wave-E lock-step territory). ✓
- `validate-pack.py`: `FAILED — 14 issue(s)` = EE-4 (the 7 deleted sidecars × Checks 39/41). ✓

The CI workflow legs are confirmed three-legged (`validate-pack.yml:192-202`: build.sh
--all/--verify + the per-shard `scripts` battery). The design correctly places the tracker Test 7
+ 3.5 inversions in Wave A (lock-step with the Check-29 flip + emitter drop) and the dormant
`tracker-*.sh` repoint inversions in Wave E. **The atomic-Wave-A composition (§6) is sound and
the tracker tests are IN it.**

### SHOULD S-2 — EE-9's "the shell battery is GREEN" baseline claim is FALSE at HEAD
`66c8332` + the 8 deletions

EE-9 Command 2 measured ONLY `test-per-entry.sh` (57/0) and `validate-pack.py` (14), then
asserted "the source tree is GREEN except the 14 validate-pack rows; the shell battery is GREEN
… because the source still carries the old shape." I ran a battery member EE-9 did NOT run:
```
bash scripts/tests/test-migrate-v10-to-v11-decompose.sh  →  Passed: 33  Failed: 12
```
**12 failures** (e.g. `2.0b --apply rc=0 expected 0 got 31` EXIT_GATE_FAILED, `2.1a-f per-entry
… missing`, `4.1a/4.2a --resume …`). Root cause: the migrator
(`migrate-v10-to-v11.sh:449-454`) COPIES the project sidecars (`_rules.md`/`_intro.md`/
`_format.md`) from `project-template/docs/project/<stream>/` as its decompose source; the 8
uncommitted Wave-A deletions removed those sources, so the migrator's gate fails (exit 31) and
12 asserts cascade. (Confirmed the deleted files EXIST in HEAD — `git show HEAD:…/_format.md`
succeeds — so the breakage is the working-tree deletions, not committed state.)

This does NOT invalidate the design's atomic-Wave-A thesis (the deletions ARE the partial-Wave-A
state; landing the migrator updates + the inversions atomically restores green). It IS a defect
in the doc's empirical attestation: EE-9 + the §9 Rules-Applied block both state the FULL battery
was measured / green-baseline confirmed, but the migration leg is RED and was not measured. Per
`verify-full-ci-suite` ("sampling is the defect"), the baseline measurement should have run every
wired test, not `test-per-entry.sh` + the four tracker tests. SHOULD: the planner must treat the
migration battery (`test-migrate-v10-to-v11*.sh`) as Wave-A/Wave-B-affected and confirm full
green at each wave, not rely on EE-9's narrow baseline.

### Under-attestation note (folded into S-2, not separate): the migrator support-set `_format.md`
branch

`migrate-v10-to-v11.sh:449-454` (`changelog) support_basenames="_rules.md _intro.md _format.md"`)
is the `_format.md` copy-source. `scripts/migrate-v10-to-v11.sh` IS in EE-6's 23-file operational
set and O1 declares `_format.md` FORBIDDEN everywhere, so a grep-zero coder catches it — but
neither O1's nor O7's deliverable text ENUMERATES this specific `support_basenames` branch as a
Wave-A/Wave-B edit. Minor enumeration gap; the grep-zero gate is the backstop. (No separate
finding — covered by S-2's "confirm the migration battery per wave.")

---

## FOCUS AREA 5 — General backstop + new-error check

**Verdict: the NON-tracker encoding layer is sound (no regression); the 1117→1276-line growth
introduced NO new contradiction beyond the S-1 line-range overlap.**

- **Non-tracker `_format.md` test sweep — MATCHES EE-6 exactly.** `git grep -lE '_format\.md'`
  across `scripts/tests/`+`scripts/persona-contracts/`+`test-fixtures/` returns exactly the 8
  files EE-6 enumerates (contract-greenfield, contract-migration, test-v11-realistic-ot, the 2
  project-side-refs skeletons, test-init-project, test-per-entry, test-validate-pack-check-43).
  No missed `_format.md` test surface.
- **Phantom `backlog/_format.md`:** `ls backlog/_format.md` → absent. O9's `:5094` STRIP of the
  `(see /backlog/_format.md)` parenthetical is correct.
- **Check-43 allowlist (`validate-pack.py:5503-5507`) + required-set
  (`test-validate-pack-check-43.sh:133-138`):** confirmed both carry `_format.md` + the 3
  monolith basenames; O9/O24's lock-step is sized correctly.
- **Negative controls:** I did not re-derive them exhaustively, but the non-tracker monolith-
  presence test list (contract-mid-dev = comment only; test-migrate-v10-to-v11.sh = no mirror-
  present assert; test-persona-contracts.sh = no die/round-trip) confirms EE-9's exclusions are
  right for the surfaces I spot-checked.
- **No NEW contradiction from the doc growth:** the FINAL-reconciliation additions (EE-11, the
  7-finding fold, O25/O19/O26 expansions) are internally consistent with §6 (Wave A/E placement)
  and §0 (executive summary) — EXCEPT the S-1 row-10/row-20 overlap, which is the one
  self-inconsistency the growth introduced. SHOULD, not BLOCKER (O19 prose carve-out mitigates).

---

## NEW FINDINGS (summary)

| ID | Severity | Finding | Evidence | Design location |
|---|---|---|---|---|
| S-1 | SHOULD | EE-11 rows 10 & 20 classify overlapping `tracker-migrate-forward.sh` line ranges as BOTH REPOINT (M-mono) and KEEP (M-track); `:2142-2172` (an M-track staleness probe + v10-INPUT path) is inside row 20's `:1992-2253` KEEP range. Risks a Wave-E coder breaking the dormant tracker→file feature. | `:2160-2173` reads `$repo_root/BACKLOG.md` + checks the `<!--` M-track header; func `tracker_migrate_status_report():2108-2217` is inside both ranges. O19 prose carve-out mitigates. | EE-11 rows 10/20; O19 (Wave E) |
| S-2 | SHOULD | EE-9's "shell battery is GREEN" baseline is empirically FALSE: `test-migrate-v10-to-v11-decompose.sh` = 33/12 at HEAD `66c8332`+deletions (migrator support-set copy-source deleted → exit 31 cascade). Baseline sampled only test-per-entry + 4 tracker tests. | `bash test-migrate-v10-to-v11-decompose.sh → Passed:33 Failed:12`; `migrate-v10-to-v11.sh:449-454`; deleted sidecars exist in HEAD. | EE-9; §9 Rules-Applied "verify-full-ci-suite" row |
| S-3 | SHOULD | `.dangling-ref-allowlist.txt` REMOVE/KEEP is right, but the grep-zero/allowlist-sizing gates must use DIRECT pathspecs (not the broken EE-11 Command 2 form) — see N-1. | EE-11 Command 2 returns empty when run verbatim. | EE-11 Command 2; O26 |
| N-1 | NIT | EE-11 "Command 2" returns ZERO run literally (unquoted-`$FILES` glob + `mirror_required` not in the 52-file set). The reproduction recipe is broken though the substance is verifiable via direct grep. | reproduced empty output; `mirror_required` only in `validate-pack.py`. | EE-11 |
| N-2 | NIT | `test-fixtures/build.sh:627-632` carries a tracker-mode client `[mirror]` table (M-track KEEP, correct) but is outside the 52-file set → not enumerated by the "exhaustive" sweep. | `git grep location_backlog` whole-tree; `:616 state="tracker"`. | EE-11 |
| N-3 | NIT | EE-11 row 17 rationale ("tracker-mode/staleness fixtures") mischaracterizes `flat-file-mode.toml` (it is `mode.state="flat-file"`, `prefix="BD"`, a mode-resolution fixture). KEEP conclusion still correct. | `flat-file-mode.toml:9 state="flat-file"`; consumed only by `tracker-config-test.sh:123`. | EE-11 row 17 |

None of S-1/S-2/S-3 is a BLOCKER or MUST: each is an artifact-quality / attestation-accuracy
issue with a built-in backstop (O19's prose carve-out for S-1; the grep-zero gates + per-wave
full-battery run for S-2/S-3). The tracker-family class itself is closed.

---

## Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| **measure-then-bound / blast-radius completeness** | Independently re-derived the tracker family via `git ls-files` (52 files: lib 18, scripts 2, tests 22, toml 10 — MATCHES EE-11 Command 1) + a whole-tree `git grep -nE 'location_backlog\|regenerate_on_write'` backstop (surfaced `test-fixtures/build.sh:627-632` beyond the 52). Verified each REMOVE/REPOINT/KEEP row against the live code. | COMPLIANT |
| **verify-full-ci-suite** | Ran read-only: `validate-pack.py` (14 issues=EE-4); `tracker-config-schema-test.sh` 40/0; `tracker-init-test.sh` 104/0; `tracker-config-test.sh` 32/0; `tracker-agent-read-test.sh` 57/0; `tracker-migrate-forward-test.sh` 204/0; `tracker-migrate-reverse-test.sh` 196/0; `test-tracker-promote-direct.sh` 31/0; `test-tracker-phase-task.sh` 100/0; `test-per-entry.sh` (via citations); AND `test-migrate-v10-to-v11-decompose.sh` 33/12 — which EXPOSED EE-9's narrow baseline (S-2). Did NOT sample. | COMPLIANT |
| **ci-guard-measure-then-bound** | Re-checked the Check-29 `mirror_required` flip at `validate-pack.py:2796` against the `:2577 if mirror_required or "mirror" in data` logic (flip is sized correctly — KEEP rows untouched); the `.dangling-ref-allowlist.txt:101,104` REMOVE / `:95,98` KEEP sized to the legitimate set; Check-43 allowlist `:5503-5507` + `:5094` phantom STRIP measured against the actual tree (`ls backlog/_format.md`=absent). | COMPLIANT |
| **enumerate-encoding-surfaces** | For each tracker surface verified its lock-step set: Check-29 flip ⇔ Test 7 ⇔ emitter ⇔ 3.5 (all Wave A); O19 repoints ⇔ tracker-agent-read/doctor/promote/phase-task tests (Wave E). Flagged the migrator support-set `_format.md` branch under-attestation (S-2) + the row-10/20 overlap (S-1). | COMPLIANT |
| **tracker-portability** | Confirmed the reconciliation adds NO vendor coupling: KEEP rows (tracker-mirror.sh, reverse-emit, header-snapshot, the tracker-mode fixtures) PRESERVE the tracker→file feature behind the TrackerProvider abstraction; tracker stays gated OFF (BD-214); O19/O25 reconcile dormant M-mono assumptions only — no GH primitive added, no feature activated. | COMPLIANT |
| **ground every finding in evidence** | Every finding carries command + verbatim output + file:line + HEAD `66c8332` + severity + design location (see NEW FINDINGS table + per-focus-area sections). | COMPLIANT |
| **agents-never-commit / per-action-approval-sub-agents** | Ran ONLY read-only git (`rev-parse`, `status --short`, `ls-files`, `grep`, `show … >/dev/null`, `branch`) + read-only `python3 validate-pack.py` + read-only `bash` tests (scratch tmpdirs; no fixtures mutated) + file Reads + one read-only graphify query. SOLE write = this report. No state-changing git verb; no destructive op. | COMPLIANT |
| **graph-first-context** | DISCOVERY ran the graph FIRST against the orchestrator-canonical path `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/graphify-out/graph.json` (`--backend claude-cli --budget 1500`, BFS depth=2, 98 nodes) — surfaced orientation nodes, no tracker surface beyond the grep ground-truth. VERIFICATION via grep/Read (exact file:line/counts). G2 not needed. | COMPLIANT |
| **spawn-unique-naming** | Operating as `reviewer-bd206-arch-confirm-2` (this header + row). | COMPLIANT |
| **rules-applied-verification-block / agents-read-rule-docs-in-full** | This block exists with per-rule evidence. READ-IN-FULL via Read tool: the ARCHITECTURE-BD-206.md target (1277 lines, all pages); pack-root CLAUDE.md `## Pack memory` (in-context, full); `feedback_verify_full_ci_suite.md` (58 ln; first line `---`, RECURRENCE 2026-06-13 BD-214 C1 last block); `feedback_ci_guard_design_measure_then_bound.md` (15 ln); `feedback_enumerate_encoding_surfaces.md` ABSENT as a standalone file (Read error "File does not exist") → relied on the CLAUDE.md `enumerate-encoding-surfaces` rule text (in-context, full), as permitted; `feedback_researcher_maps_blast_radius_before_architect.md` (41 ln); `feedback_tracker_portability.md` (21 ln); `feedback_agent_output_rules_applied_block.md` (15 ln); `feedback_agents_read_rule_docs_in_full.md` (134 ln); `feedback_architect_planner_empirical_evidence.md` (15 ln). Plus backlog/BD-206.md + BD-249.md (full), DECISIONS-BD-206-RESTART.md (relevant sections). Anti-contamination: NO prior BD-206 review/reconcile/adversarial/RESTART doc opened. | COMPLIANT |

**HEAD:** `66c833223c2c8e3b7657e3c24e7c4ddfb539a3d7` — **Date:** 2026-06-26 —
**Reviewer:** `reviewer-bd206-arch-confirm-2` — **Report:**
`/Users/david/Developer/_tmp/pack-handoff-bd206-restart/CONFIRM2-ARCH-REVIEW-BD-206.md`
