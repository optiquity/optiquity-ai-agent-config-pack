# IMPL-BD-203-C1-fix1 — CI-red missed encoding surface (Check 32 → 32′)

**Agent:** pack-coder
**Branch:** v11-dev
**HEAD (pre-flight & final, unchanged — no git verbs):** `2cc92b92e49e95799e44ffe4113d38ae634a85ba`
**Scope:** TEST-only fix. One file edited: `scripts/tests/test-v11-realistic-ot.sh`.
**Result:** Fix complete; all verification PASS (0 FAIL); zero regressions.

---

## 1. Defect recap

BD-203 C-1 (committed `3d7bec4`) replaced Check 32 with the inverted Check 32′
in `scripts/validate-pack.py`. C-1's encoding-surface sweep updated the UNIT
test (`test-validate-pack-checks-32-33-34.sh`) but MISSED the INTEGRATION test
`scripts/tests/test-v11-realistic-ot.sh`, whose Group C assertions still
encoded the OLD Check 32 banner + SKIP wording. CI `tests` job failed there.

## 2. Finding beyond the named line (surfaced, fixed in lockstep)

The prompt named C.2 (banner, line 333) as the known stale needle. The sweep
established that **C-1 changed TWO output strings in Check 32′, not one** — the
banner AND the per-stream SKIP wording:

| Output | Old (Check 32) | New (Check 32′ — `validate-pack.py:3191`, `3208–3209`) |
|---|---|---|
| Banner | `── Check 32: per-entry mirror is in-sync with per-entry tree (BD-168) ──` | `── Check 32′: no pack monolith exists (BD-203) ──` |
| SKIP msg | `... not present (skipping; pre-v11.0 client or pre-BD-102 dog-food pack-self...` | `... not present (skipping; pre-conversion pack-self or pre-v11.0 client)` |

So C.3 and C.4 (lines 334–337, the backlog/ + changelog/ SKIP-wording needles)
were ALSO stale and would have failed against current Check 32′ output. I fixed
all three (C.2/C.3/C.4) in lockstep per `enumerate-encoding-surfaces`. Fixing
only the named C.2 would have left CI red on C.3/C.4. Verified against the
live validator (Check 33/34 SKIP wording is **unchanged** — still
`pre-BD-102 dog-food pack-self` — so C.5–C.9 correctly stay as-is).

## 3. Edits (targeted, in-place; full file re-read after)

`scripts/tests/test-v11-realistic-ot.sh` — `+30 / -24` (net per-region; no
logic change, banner/SKIP needles + descriptive comments only):

1. **Assertions C.2/C.3/C.4 (now lines 335–343)** — banner needle → Check 32′
   string (byte-exact copy of `validate-pack.py:3191`, incl. the `′` prime and
   the box-drawing `──`); SKIP needles → the new `pre-conversion pack-self or
   pre-v11.0 client` wording (copied from `validate-pack.py:3208–3209`). Labels
   relabeled `Check 32 → Check 32′` and anchor name updated to `pre-conversion`.
2. **Group C summary comment (file-header, ~lines 27–35)** — old "pre-BD-102
   dog-food pack-self" SKIP description for Check 32 updated to note Check 32′
   ("no pack monolith exists") emits the `pre-conversion pack-self` message
   while Check 33/34 retain the `pre-BD-102 dog-food pack-self` wording.
3. **Group C in-body header comment (~lines 291–318)** — same hygiene: describe
   Check 32′ semantics + its distinct SKIP wording; future-Batch-23 note
   reworded for the inverted "no monolith co-exists" assertion.

NOT touched (verified correct, left alone per scope): Check 33 needle
(line 347), Check 34 needle (line 355), all assertion LOGIC, Groups A/B,
`scripts/validate-pack.py` (out of scope).

## 4. Sweep (scope #3) — full `scripts/tests/` for sibling stale needles

Commands + verbatim results:

```
$ grep -rn "Check 32:" scripts/tests/
scripts/tests/test-v11-realistic-ot.sh:333:    "── Check 32: per-entry mirror is in-sync with per-entry tree (BD-168) ──"
$ grep -rn "mirror is in-sync" scripts/tests/
scripts/tests/test-v11-realistic-ot.sh:333:    "── Check 32: per-entry mirror is in-sync with per-entry tree (BD-168) ──"
```

(Both hits are line 333 — the C.2 needle now fixed.) The unit test
`test-validate-pack-checks-32-33-34.sh` was already migrated by C-1 (its
Group A / F1 / F4 assertions reference Check 32′ / "no monolith"; the
`Check 32` strings remaining there are descriptive header prose at lines
3/19/44/47, not assertion needles — out of scope for this test-only fix, and
that file is green in verification §5). **No other stale assertion exists** —
the only stale ASSERTION needles in all of `scripts/tests/` were C.2/C.3/C.4 in
`test-v11-realistic-ot.sh`, all now fixed. No invented changes.

## 5. Verification (all run; verbatim)

| # | Command | Result |
|---|---|---|
| 1 | `bash scripts/tests/test-v11-realistic-ot.sh` | **PASS — 33/33, FAIL: 0** ("All v11-realistic-ot integration tests PASSED (33/33).") |
| 2 | `python3 scripts/validate-pack.py` | **rc=0** ("PASSED — all checks clean") |
| 3a | `bash scripts/tests/test-validate-pack-checks-32-33-34.sh` | **rc=0, FAIL: 0** ("All BD-168 validate-pack Check 32/33/34 tests PASSED (70/70).") |
| 3b | `bash scripts/tests/test-per-entry.sh` | **rc=0, FAIL: 0** ("All per-entry tests PASSED (58/58).") |
| 4 | `bash test-fixtures/build.sh --all --clean` (rc=0) then `git status --short test-fixtures/manifest.txt` | **manifest UNCHANGED** (empty `git status`/`git diff` — the fixture embeds project-side content, not pack `scripts/tests/`, so the edited test does not move the manifest). **No manifest staging needed.** |

Pre-test note: ran `build.sh --all --clean` (rc=0) before test #1 so the
v11-realistic-ot fixture was freshly built for the integration consumer.

## 6. Plan deviations

One, surfaced not silently expanded: the prompt named C.2 (banner) as the
single known needle; I additionally fixed C.3 + C.4 (SKIP-wording siblings)
because C-1 changed Check 32′'s SKIP message in lockstep with the banner —
leaving C.3/C.4 stale would have kept CI red. This is in-scope under scope #3
(SWEEP for any other assertion encoding C-1-changed output) and the
`enumerate-encoding-surfaces` rule, not scope creep.

## 7. New POQs

None.

## 8. Files changed

| Path | Change type |
|---|---|
| `scripts/tests/test-v11-realistic-ot.sh` | modified (test needles + adjacent comments; no logic change) |

No new files. No deletions. `test-fixtures/manifest.txt` rebuilt but byte-identical (not changed). `validate-pack.py` NOT touched.

## 9. Definition-of-Done

| Item | Status |
|---|---|
| C.2 banner needle byte-exact = current Check 32′ banner | PASS |
| C.3/C.4 SKIP needles match current Check 32′ SKIP wording | PASS |
| Adjacent old-"Check 32 mirror-in-sync" comments updated to Check 32′ | PASS |
| Check 33 (line 347) + Check 34 needles left ALONE (verified unchanged in validator) | PASS |
| `scripts/tests/` swept; no other stale assertion | PASS |
| `validate-pack.py` + all other source untouched | PASS |
| CI integration test PASSES (FAIL: 0) | PASS |
| No regression (validator rc=0; unit tests 70/70 + 58/58) | PASS |
| Manifest regen check run; disposition reported | PASS |
| No git verbs run | PASS |

---

## Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| read-in-full + NO-DERIVATION | Read DIRECTLY via Read tool: `scripts/tests/test-v11-realistic-ot.sh` (full, 382 lines), `scripts/validate-pack.py` Check 32′ region (offset 3160–3290), `CLAUDE.md ## Pack memory` (full, via project-instructions in context), and the 4 named memory files in full (`feedback_agents_read_rule_docs_in_full.md`, `feedback_agent_output_rules_applied_block.md` + its rationale pointer `PACK-MEMORY-RATIONALE.md` §rules-applied-verification-block, `feedback_scope_deliverables_to_the_ask.md`, `feedback_edit_in_place_not_full_rewrite.md`). No content derived from non-source. | COMPLIANT |
| preflight-stop-means-stop | Emitted the single `PREFLIGHT:` line only AFTER edit + all of verification §5 PASS; no parent stop message received. | COMPLIANT |
| agents-never-commit | Ran only read-only git verbs (`rev-parse`, `status`, `diff`); no `add`/`commit`/`push`/`tag`/`mv`/`rm`. | COMPLIANT |
| enumerate-encoding-surfaces | Sweep §4: `grep -rn "Check 32:"` + `"mirror is in-sync"` over `scripts/tests/` returned only line 333; identified C.3/C.4 SKIP siblings as also-stale and fixed all three in lockstep; confirmed unit test already migrated by C-1. No sibling stale assertion remains. | COMPLIANT |
| edit-in-place-not-full-rewrite | Three targeted `Edit` calls on byte-exact anchors (no full-file `Write` of the test); re-read edited region (lines 330–354) after editing to confirm — see §3. | COMPLIANT |
| manifest-regen-on-v11-surface | `scripts/tests/` is v11-surface → ran `build.sh --all --clean` (rc=0); `git status --short test-fixtures/manifest.txt` empty → manifest byte-identical, no staging needed (verification §5 #4). | COMPLIANT |
| scope-deliverables-to-the-ask | One file edited (the test); `validate-pack.py` + all other source untouched; finding beyond the named line surfaced in §2/§6, not silently expanded; report terse. | COMPLIANT |
| rules-applied-verification-block | This table (per-rule, quoted evidence, COMPLIANT terminal) is the final section of the IMPL-REPORT. | COMPLIANT |
