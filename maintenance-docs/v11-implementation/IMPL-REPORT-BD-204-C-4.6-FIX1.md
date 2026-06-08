# IMPL-REPORT — BD-204 C-4.6 FIX1 (completion of stalled fix-coder: F-1 teeth + F-4)

**Agent:** pack-coder (fix-coder; completion of a watchdog-stalled prior fix-coder)
**Branch:** v11-dev
**HEAD (unchanged — agents-never-commit):** `f89ade57fe5ecf99c532adbe0ce511cbd81edf30`
**Scope:** PACK-ONLY · markdown-only report (this file is the sole report write)
**Mandate:** COMPLETE the stalled fix — verify F-1/F-2/F-3 (do NOT rewrite), finish the F-1 teeth gating in the per-check test, fix F-4 (stale test assertion), re-measure, run the full battery.

---

## Executive summary

The prior fix-coder stalled (watchdog) AFTER implementing F-1/F-2/F-3 in the working
tree and AFTER adding the F-1 evasion-teeth leg (Group 3b) to the per-check test, but
BEFORE finishing F-4 and writing the IMPL-REPORT. This session:

1. **Verified** F-1, F-2, F-3 are present + sound (read, did not rewrite).
2. **Verified** the F-1 self-quoting-comment evasion teeth (Group 3b) were already
   added to the per-check test AND that they pass (both the FAIL-the-exploit leg and
   the no-false-FAIL leg) — no edit needed there.
3. **Fixed F-4** (test-only): removed the stale `grep -q "V3.3 §3"` assertion from
   `test-tracker-promote-path1.sh` group 8.3, keeping the live `Path 3 forbidden`
   assertion. Determined METHODOLOGY.md was NOT edited (substance intact; internal
   citation legitimately dropped per BD-195/BD-200).
4. **Re-measured** all timings, regenerated the manifest (empty diff), and ran the
   FULL unattended battery (env UNSET) to completion: **52/52 PASS, 468 s**.

All verification PASS. No plan deviations. No new POQs.

---

## Files changed (this session's inventory)

| Path | Change type | Surface | This session? |
|---|---|---|---|
| `scripts/tests/test-tracker-promote-path1.sh` | modified | per-check test (F-4) | **YES — my only edit** |
| `scripts/validate-pack.py` | modified | F-1/F-2/F-3 | pre-existing in WT (verified, not rewritten) |
| `.github/workflows/validate-pack.yml` | modified | deep-home + test wiring | pre-existing in WT (verified, not rewritten) |
| `scripts/tests/test-validate-pack-check-49-field-faithfulness.sh` | new (untracked) | per-check test incl. F-1 teeth | pre-existing in WT (verified, not rewritten) |
| `test-fixtures/manifest.txt` | unchanged | deliverable manifest | regenerated → empty diff (no stage) |

`git status --short` at report time:
```
 M .github/workflows/validate-pack.yml
 M scripts/tests/test-tracker-promote-path1.sh
 M scripts/validate-pack.py
?? maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-C-4.6.md
?? maintenance-docs/v11-implementation/PACK-REVIEW-BD-204-C-4.6.md
?? scripts/tests/test-validate-pack-check-49-field-faithfulness.sh
```
(plus this new IMPL-REPORT once written). No migrator/METHODOLOGY/_rules/entry edit.

---

## F-1 — Check 50 self-quoting-comment self-hole (VERIFIED + teeth gated in CI)

**Status: IMPLEMENTED (verified, not rewritten) + TEETH IN THE PER-CHECK TEST (verified pass).**

### Implementation (verified present in `scripts/validate-pack.py`)

- `_check_50_strip_quoted_spans(line)` (`:7729-7762`) — a deliberately small,
  robust quote-span stripper that walks the line char-by-char, dropping any span
  bounded by a matching `'`/`"` (backslash-escaped quotes inside a span do not
  close it), returning the UNQUOTED residual.
- `check_validate_pack_no_reproduced_codec()` (`:7779-7854`) now tests
  `token in residual` (the post-strip residual) **per occurrence**, replacing the
  prior per-line `f'"{token}"' in line` escape. A line carrying BOTH a bare
  executable codec call AND a quoted copy of the same token in a trailing comment
  (e.g. `gzip.compress(buf)  # "gzip.compress"`) keeps the executable
  `gzip.compress(buf)` in the residual and is FLAGGED. Legitimate denylist literals
  (the bare `"gzip.compress"` tuple entries) have no unquoted occurrence → survive
  the strip with no residual hit → still PASS.

Soundness review: the stripper correctly handles the closer-selects-by-opener rule
and the escaped-quote case; the denylist tuple `_CHECK_50_FORBIDDEN_CODEC_TOKENS`
(`:7765-7776`) is unchanged and still excused (no unquoted occurrence). The seam-span
exclusion (`_CHECK_49_SEAM_SCRIPT` block) and `#`-pure-comment skip remain in place,
so the residual test only ever sees executable, non-seam code. **Correct.**

### Teeth gated in CI (the remaining-work item) — VERIFIED PASS

`scripts/tests/test-validate-pack-check-49-field-faithfulness.sh` **Group 3b**
(`:327-414`) was already added by the stalled coder. It:

- Builds a temp COPY of validate-pack.py with a **fully functional** reproduced gz64/
  base64 codec injected OUTSIDE the seam, where EVERY codec line self-quotes its own
  forbidden token in a trailing comment (the exact reviewer F-1 exploit).
- **Proves the injection is REAL** — round-trips `b"hello\x00\r world \xe2\x80\x94"`
  through `_evasion_reproduced_gz64`/`_evasion_reproduced_ungz64` and asserts equality
  (rejects a dead-string false exploit).
- Asserts the self-quoting reproduced codec **FAILS Check 50** (`"reproduces the
  gz64/" in cap`, `n >= 1`).
- **No-false-FAIL leg:** re-loads the REAL (clean) validate-pack.py and asserts
  `check_validate_pack_no_reproduced_codec()` → **0 failures** (its denylist literals
  have no unquoted occurrence).

Group 3 (`:259-325`) additionally retains the naive-reproduction teeth (bare
`gzip.compress`/`base64.b64encode` FAILS) + clean-source-PASSES.

### Exploit-teeth proof (this session's measurement)

```
$ bash scripts/tests/test-validate-pack-check-49-field-faithfulness.sh ; echo rc=$?
...
=== Group 3: §4.5 single-source TEETH — reproduced codec FAILS Check 50 ===
  PASS  §4.5 single-source: reproduced codec FAILS Check 50; clean source PASSES
=== Group 3b: §4.5 self-quoting-comment EVASION FAILS Check 50 (review F-1) ===
  PASS  §4.5 self-quoting evasion: a self-quoting reproduced codec FAILS Check 50; clean source still PASSES
...
=== Summary ===
  PASS: 8
  FAIL: 0
rc=0
```

Both directions fire: the self-quoting evasion is now CAUGHT, and the real
validate-pack.py is not false-FAILed on its own denylist. **F-1 closed + gated.**

---

## F-2 — deep faithfulness per-check budget (VERIFIED)

**Status: IMPLEMENTED (verified, not rewritten).**

`scripts/validate-pack.py:445`:
```python
RUN_CHECK_DEEP_FAITHFULNESS_BUDGET_S = 30.0
```
with a rationale comment (`:439-444`) tying it to spec §4.7 "Deep faithfulness-check
budget = 30 s" — DISTINCT from the 35 s deep TOTAL-run budget. Measured Check-49 deep
leg ≈ 1.6-1.9 s (≈10× headroom); an Option-A per-entry-spawn regression (~142 s) blows
it immediately. `main()` registration (`:8032`) passes
`budget_s=RUN_CHECK_DEEP_FAITHFULNESS_BUDGET_S`. **Correct (was 35 s; now 30 s).**

---

## F-3 — parameterized stream key (VERIFIED; guard still 211/211)

**Status: IMPLEMENTED (verified, not rewritten).**

`_check_49_stream_key_for_tree(tree_path)` (`:7507-7522`) DERIVES the stream key from
the target tree's directory basename against the `STREAMS` SSOT table
(`stream_key ↔ stream_dir_relative`), defaulting to `pack-backlog` when no row matches
— never hardcoded. `check_migrator_field_faithfulness` calls it at `:7570`
(`tree_key = _check_49_stream_key_for_tree(tree_path)`) and passes `tree_key` into the
seam (`:7577`). A future `pack-changelog` deep-home caller resolves the correct key
instead of mislabelling everything `pack-backlog`.

Guard still green on the real tree (this session's measurement):
```
OK: Check 49 — 211 entries byte-faithful (codec-lossless + parse-faithful),
    control-char-clean, title ≤ 256 codepoints, size leg vs provider body limit
    65536 − margin 2048
```
**211/211 — F-3 introduces no regression.**

---

## F-4 — stale test assertion (FIXED, test-only)

**Status: FIXED. Determination: test-only; METHODOLOGY.md NOT edited.**

### Determination (boundary-discipline investigation)

The review flagged `test-tracker-promote-path1.sh` group 8.3's first assertion
(`grep -q "V3.3 §3" supporting-docs/METHODOLOGY.md`) failing identically at clean HEAD.
Investigation of `supporting-docs/METHODOLOGY.md` promotion-paths section (Procedure 1,
≈`:1252-1320`):

- **`grep -c "V3.3" METHODOLOGY.md` → 0.** The internal `ARCHITECTURE-V3.3-DELTA §3`
  citation is entirely absent — it was stripped off the **client-facing** surface by
  BD-195/BD-200 (internal-ref cleanup on client deliverables), with **no replacement
  citation** (client docs do not cite internal architecture-delta docs — correct per
  `feedback_client_ref_delete_or_forward_look`: a pack-only asset ref is deleted, not
  forward-looked, when the asset is genuinely internal).
- **The promotion-paths SUBSTANCE is intact:** Path 1 / Path 2 / direct-close decision
  logic (`:1287-1311`) and **`Path 3 is forbidden`** (`:1313-1320`, "supersedes the v10
  fold-into-existing-task shape ... `pack td promote` verb has no `--fold-into` flag")
  are all present. `grep -q "Path 3 is forbidden\|Path 3 forbidden" METHODOLOGY.md`
  succeeds.

Therefore METHODOLOGY genuinely retained the Path-3 substance — it lost ONLY the
internal citation. Per the prompt's decision tree ("if the internal ref was simply
dropped with no replacement, REMOVE that stale assertion; keep Path-3 forbidden") and
the scope fence (do NOT edit client-shipped METHODOLOGY.md unless it lost the Path-3
substance — it didn't), the fix is **test-only**.

### Edit applied (the only file I modified)

`scripts/tests/test-tracker-promote-path1.sh` group 8 — removed the stale
`grep -q "V3.3 §3"` PASS/FAIL block (former `:580-584`) and replaced it with a
context comment documenting the BD-195/BD-200 removal + why the fix is test-only. The
live substance assertion `grep -q "Path 3 is forbidden\|Path 3 forbidden"` is retained
verbatim. Net: one stale assertion removed; the 2nd 8.3 assertion unchanged.

### Proof (before → after)

Before (clean WT): `8.3 METHODOLOGY.md cites V3.3 §3` → **FAIL**; `PASS: 79 / FAIL: 1`.

After:
```
$ bash scripts/tests/test-tracker-promote-path1.sh ; echo rc=$?
...
  PASS  8.3 METHODOLOGY.md names Path 3 forbidden
=== Summary ===
  PASS: 79
  FAIL: 0
rc=0
```
**F-4 fixed; rc=0.**

---

## Re-measured verification (MEASURE, not "looks right")

All commands run this session at HEAD `f89ade5` (working tree dirty per the inventory).

| Verification | Command | Result |
|---|---|---|
| General validate-pack GREEN + timing | `/usr/bin/time -p python3 scripts/validate-pack.py` | rc=0, **real 1.37 s**, `PASSED — all checks clean`; deep leg = `SKIP: field-faithfulness deep check` |
| Deep validate-pack GREEN + timing (<30 s) | `/usr/bin/time -p env PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | rc=0, **real 2.99 s**, `PASSED`; Check 49 = `211 entries byte-faithful`; Check 50 = `no reproduced gz64/base64 codec` |
| Per-check test (incl. F-1 teeth + no-false-FAIL) | `bash scripts/tests/test-validate-pack-check-49-field-faithfulness.sh` | rc=0, **PASS: 8 / FAIL: 0** (Group 3b self-quoting evasion green) |
| F-4 test | `bash scripts/tests/test-tracker-promote-path1.sh` | **rc=0, PASS: 79 / FAIL: 0** |
| Manifest regen | `bash test-fixtures/build.sh --all --clean` | rc=0; `git diff --stat test-fixtures/manifest.txt` → **empty** (no stage; manifest tracks `project-template/` deliverable surface, not `scripts/`) |
| **FULL unattended battery (env UNSET)** | validate-pack + all 51 `scripts/tests/*.sh`, sequential, `PACK_VALIDATE_DEEP` UNSET throughout | **COMPLETES in 468 s (~7.8 min); 52/52 PASS, 0 FAIL** |

Full-battery completion is the load-bearing runtime check (`ci-check-runtime-compounding`):
the battery COMPLETES rather than hanging — the env var was UNSET for the entire run,
so the 151× general path pays the ~0 ms deep SKIP and the deep leg runs only on its
dedicated home. The previously-failing `test-tracker-promote-path1.sh` now passes
(F-4), so the whole battery is green (the review's lone pre-existing failure is resolved).

---

## Plan deviations

**None.** Verified F-1/F-2/F-3 without rewrite; completed the F-1 teeth gating
(already present — verified pass); fixed F-4 test-only per the prompt's decision tree;
did not touch the migrator, METHODOLOGY.md, `_rules`, entries, or other maintenance-docs
beyond this IMPL-REPORT; did not reintroduce a codec reproduction.

---

## New POQs introduced

**None.**

---

## Boundary discipline check

My only edit, `scripts/tests/test-tracker-promote-path1.sh`, is a pack-side test file
(not a `project-template/` / `supporting-docs/` client surface). No SSOT-augmentation
required for a pack-side test. The F-4 *determination* required investigating the
client-side `supporting-docs/METHODOLOGY.md`: I read it but did **not** edit it
(correct — it retains the Path-3 substance; the internal-citation removal was a prior,
intentional client-surface cleanup per BD-195/BD-200). No pack-only reference was added
to any client surface. No boundary-discipline STOP triggered.

---

## Definition-of-Done checklist

| Item | Status |
|---|---|
| F-1 implementation present + sound (verified, not rewritten) | PASS |
| F-1 teeth (self-quoting evasion FAILS Check 50) gated in per-check test | PASS |
| F-1 no-false-FAIL leg (clean source still PASSES) in per-check test | PASS |
| F-2 budget = 30.0 s (verified) | PASS |
| F-3 parameterized stream key (verified) + guard still 211/211 | PASS |
| F-4 fixed (test-only); rc=0 on test-tracker-promote-path1.sh | PASS |
| F-4 determination documented (METHODOLOGY not edited; substance intact) | PASS |
| General validate-pack GREEN, deep SKIPPED, ~1.3-1.4 s | PASS (1.37 s) |
| Deep validate-pack GREEN, <30 s, Check 49+50 pass | PASS (2.99 s) |
| Per-check test GREEN | PASS (8/8) |
| Full unattended battery (env UNSET) COMPLETES | PASS (468 s, 52/52) |
| Manifest regenerated; staged if non-empty | PASS (empty diff — nothing to stage) |
| No git state change (HEAD unchanged) | PASS (`f89ade5`) |
| Scope fence respected (no migrator/METHODOLOGY/_rules/entry edits) | PASS |
| IMPL-REPORT at the prompted path, unique name | PASS |

---

## CONCERNS

1. **Working-tree-vs-brief discrepancy (informational, not blocking).** The prompt said
   F-1/F-2/F-3 + the Group-3b teeth were already in the working tree. `git status` at
   pre-flight confirmed `scripts/validate-pack.py` + `.github/workflows/validate-pack.yml`
   modified and the per-check test untracked — consistent with the brief. I verified
   each edit by reading it and re-running the proofs rather than trusting the brief.
   The F-1 teeth (Group 3b) and the no-false-FAIL leg were ALREADY present and passing,
   so item 1 of my remaining work required verification only, not authoring.

2. **F-3 is a NIT-grade carry-fields hardening, not on any current critical path.** Both
   §3.LF.5 deep homes today target `/backlog/` (key `pack-backlog`), so the derive-vs-
   hardcode change is exercised only by the default branch in production. A future
   `pack-changelog` deep-home caller would be the first real consumer of the STREAMS-row
   match. The per-check test does not yet drive a non-`/backlog/` tree through
   `_check_49_stream_key_for_tree` (no changelog deep-home exists to point at). When a
   changelog deep-home lands, an explicit non-`pack-backlog` resolution case should be
   added to the per-check test (enumerate-encoding-surfaces). Not actionable now — no
   such surface exists.

3. **`PACK-REVIEW-BD-204-C-4.6.md` and `IMPL-REPORT-BD-204-C-4.6.md` are untracked in the
   working tree** (the prior cycle's artifacts). They are out of my edit scope; I leave
   them as-is for Pack Chat to handle at commit time.

---

## Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| `agents-never-commit` | Ran only read-only git verbs (`rev-parse`, `status`, `diff`). No `add`/`commit`/`push`/`tag`. `git rev-parse HEAD` = `f89ade57fe5ecf99c532adbe0ce511cbd81edf30` at start and at report time — unchanged. | COMPLIANT |
| `per-action-approval-sub-agents` | No destructive op run on own authority. Manifest regen via `build.sh --all --clean` is the sanctioned non-destructive regen (rc=0, empty diff); no `rm -rf`/`git rm`/trusted-file overwrite. Temp files under `/tmp` only. | COMPLIANT |
| `preflight-stop-means-stop` | Emitted the single PREFLIGHT line `PREFLIGHT: 2/2 complete; verification PASS; HEAD f89ade57...; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-C-4.6-FIX1.md` only AFTER all in-scope edits + verification (per-check test 8/8, validate-pack general+deep GREEN, F-4 rc=0, full battery 52/52) PASSED. No parent stop/halt message received. | COMPLIANT |
| `verify-full-ci-suite` | Ran the FULL battery (validate-pack + all 51 `scripts/tests/*.sh`), env UNSET, to completion (468 s, 52/52 PASS) — not validate-pack alone. F-4 fix verified against the integration test it pins. | COMPLIANT |
| `regenerate-manifest-v11-surface` | My diff touches `scripts/` (a v11 surface). Ran `bash test-fixtures/build.sh --all --clean` (rc=0); `git diff --stat test-fixtures/manifest.txt` → empty (manifest tracks `project-template/` deliverable surface, not `scripts/`), so nothing to stage. | COMPLIANT |
| `scope-deliverables-to-the-ask` | Delivered exactly: verify F-1/F-2/F-3, confirm F-1 teeth gated+passing, fix F-4 test-only, re-measure, run battery, write this report. No edge-case sprawl; one file edited. | COMPLIANT |
| `boundary-investigation-precedes-pack-defaults` | F-4 determination investigated client-side `supporting-docs/METHODOLOGY.md` before deciding: `grep -c "V3.3"` = 0; Path-3 substance present → test-only fix; did NOT edit the client surface or reach for a pack-style default. | COMPLIANT |
| `ci-check-runtime-compounding` | Verified env-gate is first statement (general ~0 SKIP), deep leg 2.99 s (≪ 30 s budget), and the FULL battery COMPLETES (468 s) with env UNSET — the compounding constraint holds; no hang. | COMPLIANT |
| `rules-applied-verification-block` | This table. | COMPLIANT |

---

## READ-IN-FULL attestation

Read in full this session: `PACK-REVIEW-BD-204-C-4.6.md` (F-1..F-4 findings + 10 proofs);
`scripts/validate-pack.py` — the F-1 `_check_50_strip_quoted_spans` + Check 50 body
(`:7713-7854`), F-2 budget constant (`:435-445`), F-3 `_check_49_stream_key_for_tree`
(`:7507-7522`) + Check 49 body (`:7540-7600`), `main()` registration (`:8021-8032`);
`scripts/tests/test-validate-pack-check-49-field-faithfulness.sh` (entire file, all
groups incl. Group 3b); `scripts/tests/test-tracker-promote-path1.sh` group 8 (test 8.3)
+ the surrounding test structure; `supporting-docs/METHODOLOGY.md` promotion-paths
section (Procedure 1, `:1280-1320`); CLAUDE.md `## Pack memory` in full. The
`feedback_ci_check_runtime_compounding` rule content was applied via the
`ci-check-runtime-compounding` verification above (battery-completion + env-gate-first +
deep-leg-under-budget). No file was skimmed, summarized in lieu of reading, or cropped.
