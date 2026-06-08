# PACK-REVIEW-2 — BD-204 C-4.6 (re-review of the F-1..F-4 FIX pass)

**Reviewer:** pack-reviewer (adversarial; REVIEW-2 = bounded-cycle re-review of the FIX of Review-1)
**Branch:** v11-dev · **HEAD:** `f89ade57fe5ecf99c532adbe0ce511cbd81edf30` (unchanged; read-only)
**Scope:** PACK-ONLY · markdown-only · this report is the sole write
**Inputs verified, not trusted:** `IMPL-REPORT-BD-204-C-4.6-FIX1.md`, re-measured against the actual code/tests at HEAD.
**Predecessor:** Review-1 (`PACK-REVIEW-BD-204-C-4.6.md`) found 1 MUST (F-1) + 3 NITs (F-2/F-3/F-4) and PASSED the core guard. This pass verifies the four fixes are correct AND did not break the guard / introduce new issues.

---

## VERDICT: **PROCEED** — the fix is correct, the guard is sound, ready to commit.

All four findings (F-1 MUST, F-2/F-3/F-4 NITs) are correctly resolved and independently re-measured. The core guard is intact (OQ-4 single-source real, byte-leg two-assertion contract fires, runtime non-recurrence holds, no C-4.5 regression). The fix diff is correctly scoped. One non-blocking observation is recorded (O-1: a transient first-run flake in `test-tracker-promote-path1.sh`'s gh-provisioning groups — NOT in the F-4 area, NOT introduced by this fix, steady-state green). No FIXES required. No BLOCKER, no MUST, no SHOULD.

---

## F-1 (MUST) — Check 50 self-quoting-comment self-hole: **CLOSED + GATED** — PASS

The fix added `_check_50_strip_quoted_spans(line)` (`validate-pack.py:430`-ish, the char-walk stripper) and rewired `check_validate_pack_no_reproduced_codec()` to test `token in residual` **per occurrence** (strip quoted spans first), replacing the prior per-line `f'"{token}"' in line` escape that excused the whole line on a quoted copy alone.

### (a) RE-RAN the exploit — the hole is CLOSED
I injected (independently, not via the test) a FUNCTIONAL reproduced gz64 codec where every line self-quotes its token, plus harder variants. CMD: a temp copy of `validate-pack.py` with each injection spliced before `# ── Main ──`, then `check_validate_pack_no_reproduced_codec()` on the dirty module. Verbatim results:
```
[1 self-quote double]  failures=1 -> CAUGHT     gzip.compress(raw)  # "gzip.compress"
[2 self-quote single]  failures=1 -> CAUGHT     gzip.compress(raw)  # 'gzip.compress'
[3 quoted-then-bare same line] failures=1 -> CAUGHT   x = "label gzip.compress"; return gzip.compress(raw)
[4 escaped-quote string + bare call] failures=1 -> CAUGHT   s = "he said \"gzip.compress\" here" / return gzip.compress(raw)
[5b getattr-evasion (import gzip bare)] failures=1 -> CAUGHT
[6 naive bare base64] failures=1 -> CAUGHT
```
The exact Review-1 exploit (`FAILURES: 0` before) now yields `failures=1` (CAUGHT). Hole closed.

### (b) No false-FAIL on the real file
Isolated Check 50 on the live `validate-pack.py`:
```
Check50 failures on REAL file: 0
OK: Check 50 — no reproduced gz64/base64 codec in validate-pack.py; Check 49 sub-invokes the shared batch codec (OQ-4 single-source)
```
The denylist literals (`"gzip.compress"` tuple entries) have no UNQUOTED occurrence → stripped → no residual hit → PASS. Deep run end-to-end also green (Check 50 OK).

### (c) Strip logic is sound for the exploit class — I tried to defeat it
Direct inspection of `_check_50_strip_quoted_spans` output (verbatim):
```
'gzip.compress(raw)  # "gzip.compress"'        -> 'gzip.compress(raw)  # '   (bare call KEPT  -> CAUGHT)
"gzip.compress(raw)  # 'gzip.compress'"        -> 'gzip.compress(raw)  # '   (single-quote KEPT)
'    "gzip.compress",  # denylist literal'      -> '    ,  # denylist literal' (no bare token -> PASS)
r's = "he said \"gzip.compress\" here"'         -> 's = '   (escaped-quote span dropped whole; \" does NOT close early)
'x = "import gz" "ip"'                           -> 'x =  '  (adjacent spans dropped; residuals NOT joined into a token -> no false token)
'gzip.compress("import base64")'                 -> 'gzip.compress()'  (real call KEPT; quoted-arg other-token dropped)
```
- Escaped quotes: handled (`if ch == "\\" and i+1 < n: i += 2`) — the `\"` is consumed, span stays open.
- Mixed single/double: the opener selects the closer (`quote = ch`); a `'` inside a `"`-span is inert. Both directions CAUGHT.
- Token split across a quote boundary: stripping does NOT concatenate residual halves into a forbidden token (probe 5c → 0 failures = correct CLEAN, not an evasion). My one "EVADED" label there was a CLEAN input (no codec); 0 failures is the right answer.
- getattr-evasion (5b): a real codec must `import gzip`/`import base64`; that bare import token is caught even when the call uses `getattr`. The denylist's import tokens backstop the call-token strip.
The stripper is "deliberately small, not a full tokenizer" (its docstring) but is sufficient and correct for the reproduced-codec class. No defeat found.

### (d) Teeth in the per-check test (CI-gated)
`scripts/tests/test-validate-pack-check-49-field-faithfulness.sh` **Group 3b** (`:327-414`) builds a FULLY FUNCTIONAL self-quoting reproduced codec, PROVES it round-trips `b"hello\x00\r world \xe2\x80\x94"` (rejects a dead-string false exploit), asserts it FAILS Check 50, AND asserts the clean source still PASSES. Run result (verbatim):
```
=== Group 3b: §4.5 self-quoting-comment EVASION FAILS Check 50 (review F-1) ===
  PASS  §4.5 self-quoting evasion: a self-quoting reproduced codec FAILS Check 50; clean source still PASSES
...
  PASS: 8 / FAIL: 0   (rc=0)
```
The teeth are gated (test wired in `.github/workflows/validate-pack.yml:208`; Check 42 CI-wiring gate green — `PASS: 4 / FAIL: 0`). enumerate-encoding-surfaces set complete: check + run_check + Check 50 + per-check test (Group 3 naive + Group 3b evasion) + both workflow homes + Check 42 wiring.

**F-1 verdict: CLOSED + correct + gated. PASS.**

---

## F-2 (NIT) — deep faithfulness per-check budget = 30.0 s: **PASS**

`grep` verbatim:
```
437:RUN_CHECK_TOTAL_GENERAL_BUDGET_S = 10.0
438:RUN_CHECK_TOTAL_DEEP_BUDGET_S = 35.0
445:RUN_CHECK_DEEP_FAITHFULNESS_BUDGET_S = 30.0
8032:              budget_s=RUN_CHECK_DEEP_FAITHFULNESS_BUDGET_S)
8044:        RUN_CHECK_TOTAL_DEEP_BUDGET_S if deep else RUN_CHECK_TOTAL_GENERAL_BUDGET_S
```
- The per-check deep faithfulness budget is **30.0 s** (was 35) and is the value passed to Check 49's `run_check` registration (`:8032`).
- The deep TOTAL-run budget is **unchanged at 35.0 s** (`:438`, used at `:8044`).
- Spec alignment: `ARCHITECTURE-BD-204-LOSSLESS-FIX.md:1176` states "**Deep faithfulness-check budget = 30 s.**" — the fix matches the spec value exactly (not arbitrary).
- Measured deep leg = 3.03 s wall total / Check 49 ≈ 1.6 s → ~10–18× headroom under 30 s; an Option-A per-entry regression (142 s) blows it. No functional change; alignment correct. **PASS.**

---

## F-3 (NIT) — stream key derived from the target, not hardcoded: **PASS (no /backlog/ behavior change)**

`_check_49_stream_key_for_tree(tree_path)` matches the target tree's basename against the `STREAMS` SSOT table, defaulting to `pack-backlog`. Verbatim derivation:
```
backlog   -> pack-backlog
changelog -> pack-changelog
bogus     -> pack-backlog   (default)
STREAMS: pack-backlog dir=backlog ; pack-changelog dir=changelog
```
- For `/backlog/` (the real deep home) it resolves to `pack-backlog` — IDENTICAL to the prior hardcode → no behavior change for the production target.
- Deep guard still 211/211 byte-faithful on the real tree (verbatim):
```
OK: Check 49 — 211 entries byte-faithful (codec-lossless + parse-faithful), control-char-clean, title ≤ 256 codepoints, size leg vs provider body limit 65536 − margin 2048
```
- Both §3.LF.5 deep homes target `/backlog/` today; a future `pack-changelog` home now resolves correctly instead of mislabelling. The parameterization is exercised only by the `backlog` branch in production (per-check test does not yet drive a changelog tree — correct, none exists; would be added with that surface per enumerate-encoding-surfaces). **PASS.**

---

## F-4 (NIT, test-only) — stale `V3.3 §3` assertion removed; substance kept; METHODOLOGY untouched: **PASS**

Diff of `scripts/tests/test-tracker-promote-path1.sh` group 8.3: the `grep -q "V3.3 §3"` PASS/FAIL block is REMOVED (replaced by an explanatory comment citing BD-195/BD-200 internal-ref cleanup); the live `grep -q "Path 3 is forbidden\|Path 3 forbidden"` assertion is KEPT verbatim.

Verbatim verification:
- `grep -c "V3.3" supporting-docs/METHODOLOGY.md` → **0**; `grep "V3.3 §3"` → (none). So the removal is CORRECT — the citation genuinely no longer exists; the assertion was stale, not masking a real regression.
- `grep -niE "Path 3 (is )?forbidden" METHODOLOGY.md` → `1313:**Path 3 is forbidden** (supersedes the v10 fold-into-existing-task shape).` So the Path-3 SUBSTANCE survives — the removal did not gut a real check; the retained assertion still exercises it.
- METHODOLOGY.md is **untouched**: `git status --short supporting-docs/METHODOLOGY.md` empty; `git diff --stat` empty (pack-only/client-surface preserved — boundary-discipline correct).
- Test result, steady state (3 consecutive runs): `exit=0 PASS: 79 FAIL: 0`. Group 8.3 line: `PASS  8.3 METHODOLOGY.md names Path 3 forbidden` (green in all runs).

Note: other in-file labels/comments still mention "V3.3 §3" (lines ~66, ~77) but those grep `pack td promote --help` output and helper-absence, NOT METHODOLOGY.md — unaffected by, and correctly out of scope of, the F-4 removal (surgically scoped). **F-4 PASS.**

---

## NON-REGRESSION / CORE INTACT

- **OQ-4 (drive, not reproduce):** `grep -nE "gzip|base64" validate-pack.py` outside comment/quoted/seam → only the docstring line `7782` (prose). No executable codec transform. Migrator libs untouched (`git diff --name-only HEAD -- scripts/lib/` empty). Check 50 self-proves OQ-4 (0 failures on real file). **HELD.**
- **Byte leg = §4.6.2 two-assertion contract:** scratch fixture (a real BD-002 body with a CR injected) run through `check_migrator_field_faithfulness` → `failures: 2`, verbatim:
  ```
  FAIL: Check 49 — BD-002: PARSE-FAITHFUL leg FAILED (PRE_PARSE_ORIGINAL != raw_body — the C-2 catch ...)
  FAIL: Check 49 — BD-002: R-BODY-6 disallowed control byte 0x0d at body offset 76 ...
  ```
  Both leg (b) AND R-BODY-6 still fire — the NUL/CR teeth are intact; the tautology is absent. **HELD.**
- **RUNTIME:** general (deep UNSET) = **1.36 s** (`PASSED`, deep `SKIP`). Deep = **3.03 s** (`PASSED`, Check 49 `211 entries byte-faithful`, Check 50 OK) — well under the 30 s per-check + 35 s total deep budgets. **FULL unattended battery (env UNSET, env stays unset throughout): 51/51 test files + validate-pack PASS, 0 failed, wall-clock 489 s (~8.2 min)** — the battery COMPLETES (no recurrence of the prior >2 h hang); `ci-check-runtime-compounding` holds. **HELD.**
- **No C-4.5 regression:** `tracker-migrate-roundtrip-test.sh` (211-entry lossless), `tracker-migrate-forward-test.sh`, `tracker-migrate-reverse-test.sh` → all `exit=0 / All tests passed.`. **HELD.**
- **Per-check test 49:** `PASS: 8 / FAIL: 0` (incl. Group 3 naive teeth, Group 3b evasion teeth, Group 4 runtime-budget, Group 5 no-fallback). Check 42 wiring: `PASS: 4 / FAIL: 0`. `python3 -m py_compile validate-pack.py` clean.
- **SCOPE / overstep sweep on the fix diffs:** `git status --short` = `M .github/workflows/validate-pack.yml`, `M scripts/tests/test-tracker-promote-path1.sh`, `M scripts/validate-pack.py` (+ untracked report/IMPL artifacts). F-1/F-2/F-3 land in `validate-pack.py` (+ the per-check test, already present). F-4 lands in `test-tracker-promote-path1.sh` ONLY. The `validate-pack.yml` mod (deep-home step + per-check-test wiring) is the ORIGINAL C-4.6 implementation reviewed in Review-1 — NOT introduced by this fix pass (IMPL-REPORT correctly tags it "pre-existing in WT"). No migrator / METHODOLOGY / `_rules` / entry edits. Manifest empty-diff (manifest tracks `project-template/` surface, not `scripts/`) — nothing to stage. HEAD unchanged. **CLEAN.**

---

## FINDINGS / OBSERVATIONS (REVIEW-2)

| # | Severity | Finding | Disposition |
|---|---|---|---|
| — | BLOCKER | (none) | — |
| — | MUST | (none) — F-1 closed | — |
| — | SHOULD | (none) | — |
| O-1 | NIT (informational, NOT a fix-2 trigger) | `test-tracker-promote-path1.sh` showed ONE transient first-invocation run of `PASS: 66 / FAIL: 12` before 3 consecutive clean `79/0` runs and a clean battery pass. The flake is in the gh-scratch-repo-provisioning groups (env/network cold-start), NOT in the F-4 group 8.3 (green in EVERY run), and is NOT introduced by this fix. Pre-existing test-infra sensitivity. | Surface to Pack Chat as a separate test-stability note; does NOT bear on the C-4.6 verdict. No fix-2. |

**Empty sections:** No BLOCKER. No MUST (F-1 resolved). No SHOULD. No new POQ from the fix. The accept-vs-abandon escalation is NOT triggered.

---

## Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| `agents-never-commit` | Only read-only git verbs (`rev-parse`, `status`, `diff --stat`, `diff`). `git rev-parse HEAD` = `f89ade57fe5ecf99c532adbe0ce511cbd81edf30` at start and end — unchanged. No `add`/`commit`/`push`/`tag`. No codebase edit; this report is the sole write. | COMPLIANT |
| `empirical-evidence-blocks` | Every claim carries CMD + verbatim OUT or quoted code, pinned to HEAD `f89ade57…`: F-1 exploit re-run (`failures=1 -> CAUGHT` per variant), strip-logic outputs (verbatim residuals), F-2 grep (lines 437/438/445/8032/8044 + spec line 1176), F-3 derivation table, F-4 grep counts (`V3.3`=0, Path-3 line 1313, METHODOLOGY untouched), byte-leg fixture (`failures: 2` + 0x0d), timings (1.36 s / 3.03 s), battery (`51/51 … 489 s`), migrator tests (`All tests passed.`). Not paraphrased. | COMPLIANT |
| `verify-full-ci-suite` | Ran the FULL 51-file battery + validate-pack (general AND deep) — not validate-pack alone — to completion (489 s, 0 fail), PLUS per-check test 49 (8/8), Check 42 (4/4), the 3 migrator round-trip tests, and `test-tracker-promote-path1.sh` ×4. Integration tests included. | COMPLIANT |
| `ci-check-runtime-compounding` | Confirmed env-gate is FIRST statement (general 1.36 s, deep SKIP), no `tree_dir or REPO_ROOT/backlog` fallback (Group 5 green), ONE python3 per batch fn, total-run guard present (general 10 s / deep 35 s), per-check deep budget 30 s (§4.7 spec line 1176). Battery COMPLETES (489 s) — compounding constraint holds; no >2 h recurrence. | COMPLIANT |
| `enumerate-encoding-surfaces` | Verified lock-step set for F-1: the check + `run_check` + Check 50 + the per-check test (Group 3 + Group 3b evasion teeth) + BOTH workflow homes (`validate-pack.yml:208` test wiring + deep-home step) + Check 42 wiring (green). No asymmetric coverage. | COMPLIANT |
| `scope-deliverables-to-the-ask` | Delivered exactly the F-1..F-4 verifications (esp. F-1 exploit re-run with hardened variants) + non-regression confirmation + verdict; one NIT observation (O-1) surfaced, not dropped, not sprawled. Single permitted write at the prompted path. | COMPLIANT |
| `rules-applied-verification-block` | This table. | COMPLIANT |

---

## READ-IN-FULL attestation

Read in full: `PACK-REVIEW-BD-204-C-4.6.md` (F-1..F-4 findings + 10 proofs); `IMPL-REPORT-BD-204-C-4.6-FIX1.md` (verified against code, not trusted — its `79/0`/`52/52`/`468 s` claims independently re-measured); `scripts/validate-pack.py` — the F-1 `_check_50_strip_quoted_spans` + `_CHECK_50_FORBIDDEN_CODEC_TOKENS` + `check_validate_pack_no_reproduced_codec` (Check 50), the F-2 budget constants + `run_check` harness + `main()` total-run guard, the F-3 `_check_49_stream_key_for_tree` + `check_migrator_field_faithfulness` (Check 49) + the `_CHECK_49_SEAM_SCRIPT`; `scripts/tests/test-validate-pack-check-49-field-faithfulness.sh` (Groups 0–5, incl. Group 3/3b/4); `scripts/tests/test-tracker-promote-path1.sh` group 8 diff + surrounding structure; `supporting-docs/METHODOLOGY.md` promotion-paths section (Path 3 forbidden, line 1313) + the `V3.3` grep (0); `ARCHITECTURE-BD-204-LOSSLESS-FIX.md` §4.5/§4.6/§4.6.2/§4.7 (incl. line 1176 deep-budget spec + 1645 runtime-compounding EE); memory `feedback_ci_check_runtime_compounding` + `project_bd204_c46_last_redesign` (via MEMORY index) and CLAUDE.md `## Pack memory` in full. The `.github/workflows/validate-pack.yml` diff. No file was skimmed, summarized in lieu of reading, or cropped.
