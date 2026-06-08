# PACK-REVIEW — BD-204 C-4.5-ADDENDUM (single-source BATCH MODE for the gz64 codec)

**Reviewer:** pack-reviewer (adversarial; re-measured against actual code, did NOT trust the IMPL-REPORT)
**Branch:** v11-dev
**HEAD at review:** `cadfc2310bc28d4e5cb807eb4abbeaf9a07d2f08`
**Working-tree change reviewed:** `git diff` of 4 files + untracked IMPL-REPORT
**Scope:** PACK-ONLY. Read-only on the codebase — this report is the sole write.
**Spec read in full:** PLAN-BD-204.md §3.LF.3a + §3.LF.5; ARCHITECTURE-BD-204-LOSSLESS-FIX.md §4.6 / §4.6 (S) / §4.6.2 / §3.3c; both edited libs + the existing single-record originals; the edited forward/reverse tests; the roundtrip test; the IMPL-REPORT.

---

## VERDICT: **PROCEED (clean)**

No BLOCKER, no MUST, no SHOULD. One NIT (advisory). The four-function batch mode is genuinely ADDITIVE (zero removed/changed lines across BOTH libs and tests), byte-equivalent to the single-record path over BD-136 / BD-204 / the full real 211, one shared codec (no forked transform), fast (0.06 s over 211), and correctly fenced (no C-4.6 overstep). The size-budget-omission the coder flagged is **acceptable-with-rationale** and is in fact REQUIRED by the §3.LF.5 size-leg contract — adjudicated in detail in Area 3.

---

## Area 1 — NO-C-4.5-REGRESSION (the gate)

**Result: PASS.**

**Additive gate (zero removed/changed existing lines).**
`CMD`: `git diff scripts/lib/tracker-migrate-forward.sh scripts/lib/tracker-migrate-reverse.sh | grep -cE '^-[^-]'`
`OUT`: `0`. Same command over the two test files: `0`.
`AT`: HEAD `cadfc23`, 2026-06-08.
`INTERP`: every `+` is a new line; the existing single-record function bodies are byte-untouched. A batch mode is a NEW input shape via a NEW entry-point, not a behavior change. SUPPORTED.

**211-entry single-record round-trip byte-identical (re-run independently, NOT the coder's deleted scratch).** I built a fresh harness: for each of 211 `backlog/BD-*.md` files I read lines 2..EOF byte-safely (drop through first `\n`), produced a single-record reference encoding (`GzipFile(mtime=0)` + base64) in Python, then ran the production `_tmf_gz64_encode_batch` over a length-framed input and `cmp`'d the two.
`OUT`:
```
entries: 211
batch encode == single-record reference:  IDENTICAL (211/211)   [cmp -s]
batch decode(batch encode) == original:    IDENTICAL (211/211)   [cmp -s]
```
`AT`: HEAD `cadfc23`, 2026-06-08.
`INTERP`: the batch encoder emits the byte-identical payload the single-record `_tmf_gz64_encode` emits for every real entry; the production single-record codec contract is unchanged. SUPPORTED.

**Unit suites + roundtrip green (single-record paths re-exercised).**
- `tracker-migrate-forward-test.sh` → `Passed: 181 / Failed: 0`
- `tracker-migrate-reverse-test.sh` → `Passed: 133 / Failed: 0`
- `tracker-migrate-roundtrip-test.sh` → `Passed: 51 / Failed: 0`
- `tracker-provider-test.sh` → `Passed: 127 / Failed: 0`
- `test-v11-realistic-ot.sh` → `33/33 PASS` (banner-pinning, per verify-full-ci-suite)
- `python3 scripts/validate-pack.py` → `PASSED — all checks clean` (the 14 JC-5 removed-doc WARNs are pre-existing advisory, exit code unaffected — NOT introduced here)

Single-record additive invariants 2.9.4 (`_tmf_gz64_encode` byte-unchanged) and 2.1e-iv (`_tmr_decode_body_blob` reconstruct path byte-unchanged) both PASS inside the green suites. No byte-difference anywhere in the single-record path. **Gate PASSES; no REJECT condition.**

---

## Area 2 — BATCH-EQUIVALENCE (batch(N) == single-record × N; ONE codec, not a fork)

**Result: PASS.**

**gz64 codec, real 211:** `batch encode == single-record reference` IDENTICAL 211/211; `batch decode(batch encode) == original` IDENTICAL 211/211 (Area 1, re-measured by me).

**Composer over BD-136 + BD-204 (re-measured directly, file-to-file, no capture artifact).**
`CMD`: for each id, `tmf_compose_issue_body <id> ... "$(tail -n+2 backlog/<id>.md)"` to a file vs the framed-batch `tmf_compose_issue_body_batch` payload (frame-stripped) to a file; `cmp`.
`OUT`: `BD-136 composer IDENTICAL byte-for-byte` (12861 == 12861); `BD-204 composer IDENTICAL byte-for-byte`.
`AT`: HEAD `cadfc23`, 2026-06-08.
> ADVERSARIAL NOTE: my FIRST composer comparison reported DIFFER. I traced it to a HARNESS error of mine — comparing `$(single)` (which `$(...)`-strips trailing newlines) plus a single re-appended `\n` against the batch payload, which mis-aligned the trailing-newline count. Comparing the RAW outputs file-to-file (no `$(...)` capture) they are byte-identical. The committed test 2.9.3 handles this correctly (it appends exactly `$'\n'` to the single capture, matching `printf '%s\n'`), and it passes. No defect — a measurement artifact in my probe, corrected.

**ONE-codec proof (no forked transform).** I diffed the transform constants across all call sites:
- gzip encode params: `GzipFile(fileobj=buf, mode="wb", mtime=0)` at forward `:709` (single) == `:746` (gz64 batch) == `:1038` (composer batch). Identical.
- neutralizer 4 trigger regexes: forward `:774-783` (single) == `:828-834` (neutralize batch) == `:1015-1021` (composer batch). Byte-identical regex strings (`#\d+`, `(^|[^`\w])@...`, the 7-40 hex SHA, `https?://`) and identical fence-widen logic.
- decode: `base64.b64decode(data, validate=True)` + `GzipFile(fileobj=io.BytesIO(raw))` at reverse `:688-689` (single) == `:742-743` (batch). Identical.

The composer batch INLINES the same gz64 + neutralize logic in its one Python process (rather than sub-invoking the other batch funcs), but the transform constants are verbatim-equal, so it is not a drift-prone second implementation — it is the same codec semantics, single-process. The architect-recommended ZERO-mirrored-logic intent (§4.6 (S) item 2) is honored at the semantic level. SUPPORTED.

**No per-entry subprocess storm.** Each of the four batch functions contains exactly **1** `python3 -c` (verified by per-function awk extraction) looping internally over all N records. `ci-check-runtime-compounding` property holds.

---

## Area 3 — THE SIZE-BUDGET-OMISSION (adjudication; the coder flagged it)

**Result: acceptable-with-rationale. No fix required.** The omission is not merely tolerable — it is REQUIRED by the §3.LF.5 size-leg contract.

**(a) For all REAL (non-aborting) inputs, batch == single-record byte-identical.** PROVEN over BD-136, BD-204 (Area 2, direct file cmp) and the full 211 codec round-trip (Area 1). The size-budget gate in the single-record composer is a TAIL guard (`return 1` after assembling `$body`); for any input under budget it never fires, so the produced body bytes are identical to the batch body bytes. The 211 real tree is entirely under budget (worst gzip-blob entry ~62% per §3.3c), so the omission affects NONE of the 211. SUPPORTED.

**(b) For an OVER-LIMIT input, single-record ABORTS but batch does NOT — re-measured.**
`CMD`: stubbed `_tmf_provider_capability` to declare `storage_format=raw_text`, `body.limit=100`, `TMF_SIZE_SAFETY_MARGIN=10`; fed a ~500-byte body through both paths.
`OUT`: single-record `rc=1` (the §3.3c `return 1` fires — the `tracker_error_emit: command not found` is only my harness lacking that sourced helper; the abort path is taken); batch `rc=0`, produced `679` bytes.
`AT`: HEAD `cadfc23`, 2026-06-08.
`INTERP`: the divergence the coder flagged is REAL and empirically confirmed: single-record aborts on over-limit, batch composes anyway. SUPPORTED.

**(c) Is the divergence acceptable / does it undermine OQ-4?** YES acceptable; NO it does not undermine OQ-4. The §3.LF.5 SIZE-leg contract states verbatim: *"SIZE leg = the REAL composed body: `len(composed Issue body)` via the §3.LF.3a SHARED BATCH composer/codec (markers + neutralized H2 + the gz64 blob), NOT a reproduction; assert within `provider_body_limit - SAFETY_MARGIN`."* And §3.LF.5 negative test (ii): *"a synthetic over-limit body FAILS the size leg."*

The C-4.6 guard performs its OWN size assertion at its own layer. It NEEDS the batch composer to RETURN a measurable body length for an over-limit input — if the batch composer aborted like single-record, the guard could never obtain `len(composed body)` to assert it exceeds the budget. A batch composer that aborted would make the guard's negative-size test (ii) unverifiable. So the omission is REQUIRED, not just tolerated.

This does NOT weaken OQ-4: OQ-4 is about the CODEC not drifting (a lossy codec change must break the guard in lockstep). The size-budget gate is a per-create PRODUCTION concern (fail-loud before a real Issue create), NOT a codec/transform; it carries no encode/decode logic that could false-pass a lossy migration. The composer batch shares the codec + neutralizer semantics (Area 2) — exactly the surfaces OQ-4 protects — and omits only the provider-side fail-loud envelope, which the guard re-implements (`assert within provider_body_limit - SAFETY_MARGIN`). Design §4.6 (S) item 2 explicitly frames the batch composer as the body-SHAPE assembly the guard measures, not the production size enforcer.

The "batch == single-record for non-aborting inputs" equivalence claim is therefore SOUND and SUFFICIENT: the equivalence the addendum must guarantee is over the bytes that get composed, and the only inputs where the two paths diverge are inputs the production path refuses to compose at all (where there is no "single-record body" to be equivalent to). The abort-divergence is the correct, intended seam.

**Verdict on the omission: acceptable-with-rationale.** It is well-documented inline (forward `:983-989` comment block) + in the IMPL-REPORT §2 / §7. No design-note gap; the design + plan already prescribe the guard-owns-the-size-check split.

---

## Area 4 — TIMING + BATTERY

**Result: PASS.**

**Batch codec over 211 (re-timed independently, `/usr/bin/time -p`).**
```
batch ENCODE over 211 (one python3):              real 0.06   user 0.03   sys 0.01
batch ENCODE→DECODE round-trip over 211 (two):    real 0.08   user 0.06   sys 0.03
```
`AT`: HEAD `cadfc23`, 2026-06-08. Matches the design §4.6 (S) Option-B EE (~0.05 s, 211/211 byte-identical) to within measurement noise; ~500× under the 30 s deep budget. SUPPORTED.

**Full battery completes, deep UNSET.** Confirmed `PACK_VALIDATE_DEEP` is `<unset>` in the review shell. The emphasis battery members all complete green in normal time (forward 181/0, reverse 133/0, roundtrip 51/0, provider 127/0, realistic-ot 33/33, validate-pack clean). This addendum adds NO general-path cost (the deep guard arrives in C-4.6), so no compounding / no hang risk is introduced here. The IMPL-REPORT's 45/45-in-378 s figure is consistent with a completing (~6.3 min) battery; I independently re-ran the migration + validate suites rather than the full 378 s battery and all pass. SUPPORTED.

---

## Area 5 — SCOPE / FENCE

**Result: PASS.**

`CMD`: `git status --short`
`OUT`:
```
 M scripts/lib/tracker-migrate-forward.sh
 M scripts/lib/tracker-migrate-reverse.sh
 M scripts/tests/tracker-migrate-forward-test.sh
 M scripts/tests/tracker-migrate-reverse-test.sh
?? maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-C-4.5-ADDENDUM.md
```
Exactly the 4 in-scope files + the IMPL-REPORT. **NO** `validate-pack.py`, **NO** `.github/workflows/`, **NO** guard symbol, **NO** `_rules.md` / `_methodology` / per-entry tree edits.

**No C-4.6 overstep:** `git diff <libs> | grep -E 'check_migrator_field_faithfulness|run_check|PACK_VALIDATE_DEEP|validate-pack'` → NONE. The addendum scopes to the codec seam only; the guard (C-4.6) is correctly deferred.

**Manifest empty-diff correct:** `scripts/` touched → ran `bash test-fixtures/build.sh --all --clean`; `git status --short test-fixtures/manifest.txt` EMPTY (diff 0 lines). Batch additions are function bodies inside already-tracked files; no shipped-fixture surface change → not staged is correct per the stage-IF-non-empty rule (regenerate-manifest-v11-surface).

**Overstep sweep (anything not in §3.LF.3a):** none found. Reconstruct/emit correctly NOT given batch modes (§4.6 item 3). `bash -n` clean on all 4 edited files.

---

## NITs (advisory; default-fix per triage but none gate this commit)

- **NIT-1 (UTF-8 assumption, inherited not new).** The neutralizer/composer batch decode field bytes via `decode("utf-8")` and re-encode via `encode("utf-8")` — IDENTICAL to the single-record text path (`sys.stdin.read()` / `sys.stdout.write()`, default UTF-8). Real pack-entry content is UTF-8 text (proven 211/211 byte-identical), so this is lossless. The gz64 codec batch operates on RAW BYTES throughout (binary-faithful regardless). This is the SAME assumption the single-record path already carries — not a new risk introduced by the addendum. No action; the coder already flagged it (IMPL-REPORT §9.1). I concur it is N/A as a defect.

---

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|
| agents-never-commit | No `git add`/`commit`/`push`/`tag` run; only read-only `git status`/`diff`/`rev-parse`; `git rev-parse HEAD` = `cadfc23` unchanged pre→post. This report is the sole write (to the prompted path). | COMPLIANT |
| empirical-evidence-blocks | Every Area carries the actual command + verbatim output + `AT` HEAD `cadfc23`/2026-06-08 + interpretation: additive `grep -cE '^-[^-]'`=0; 211/211 `cmp -s` IDENTICAL; over-limit single rc=1 vs batch rc=0; `/usr/bin/time -p` real 0.06/0.08; `git status --short` 5-path inventory; per-function `python3 -c`=1. | COMPLIANT |
| verify-full-ci-suite | Ran migration+validate suites (forward 181/0, reverse 133/0, roundtrip 51/0, provider 127/0, realistic-ot 33/33 banner-pinning, validate-pack clean) — not validate-pack alone; integration banner test included. | COMPLIANT |
| scope-deliverables-to-the-ask | Reviewed exactly the 5 prompted areas + the size-budget adjudication; no edge-case sprawl; led with the verdict; one report, no codebase edits. | COMPLIANT |
| rules-applied-verification-block | This table — each rule has named, quoted evidence + a terminal conclusion; no empty-evidence row. | COMPLIANT |

---

## READ-IN-FULL attestation

Read in full (no skim/crop): PLAN-BD-204.md §3.LF.3a (`:611-630`) + §3.LF.5 C-4.6 (`:644-675`, incl. the SIZE leg `:659` + negative test ii `:663`); ARCHITECTURE-BD-204-LOSSLESS-FIX.md §4.6 / §4.6 (S) (`:900-1037`), §4.6.2 byte-leg contract (`:1059-1098`), §3.3c size-budget (`:417-526`); `scripts/lib/tracker-migrate-forward.sh` (single-record `_tmf_gz64_encode` `:704-712`, `_tmf_neutralize_autolinks` `:767-786`, `tmf_compose_issue_body` `:907-980` + the three new `_batch` funcs) + `tracker-migrate-reverse.sh` (single-record `_tmr_decode_body_blob` + new `_tmr_decode_body_blob_batch`); the edited `tracker-migrate-forward-test.sh §2.9` + `tracker-migrate-reverse-test.sh §2.1e`; `tracker-migrate-roundtrip-test.sh` (battery); the IMPL-REPORT (verified, not trusted — composer DIFFER probe traced to my own harness artifact, corrected); CLAUDE.md `## Pack memory` in full incl. `ci-check-runtime-compounding` (via the design's runtime EE blocks).

*End of PACK-REVIEW — BD-204 C-4.5-ADDENDUM.*
