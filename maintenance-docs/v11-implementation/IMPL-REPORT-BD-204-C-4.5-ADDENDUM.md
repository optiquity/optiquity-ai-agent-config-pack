# IMPL-REPORT — BD-204 C-4.5-ADDENDUM (single-source BATCH MODE for the gz64 codec)

**Commit (intended):** `feat: v11 — BD-204 single-source gz64 codec: add batch mode to _tmf_gz64_encode/_tmr_decode_body_blob (+neutralizer/composer) (pack-only)`
**Branch:** `v11-dev`
**Worktree base HEAD (pre-flight + final, agent makes NO commits):** `cadfc2310bc28d4e5cb807eb4abbeaf9a07d2f08`
**Recipe:** PLAN-BD-204.md §3.LF.3a (read in full) + §3.LF.9.
**Design:** ARCHITECTURE-BD-204-LOSSLESS-FIX.md §4.6 (S) Option B + §4.6.2.
**Scope:** PACK-ONLY (`scripts/` only). No `project-template/`, no `supporting-docs/`, no `maintenance-docs/` beyond this report.

---

## 1. What this commit is (additive only)

Adds a BATCH MODE — a NEW length-framed multi-record input shape selected by a
**distinct entry-point wrapper** (never by changing the single-record contract)
— to the four C-4.5 codec/projection/assembly functions the C-4.6 Option-B
guard will call:

| Function (single-record, UNCHANGED) | New batch entry-point (ADDITIVE) | Lib |
|---|---|---|
| `_tmf_gz64_encode` | `_tmf_gz64_encode_batch` | `tracker-migrate-forward.sh` |
| `_tmf_neutralize_autolinks` | `_tmf_neutralize_autolinks_batch` | `tracker-migrate-forward.sh` |
| `tmf_compose_issue_body` | `tmf_compose_issue_body_batch` | `tracker-migrate-forward.sh` |
| `_tmr_decode_body_blob` | `_tmr_decode_body_blob_batch` | `tracker-migrate-reverse.sh` |

The C-4.6 byte leg (§4.6.2) pairs `_tmf_gz64_encode_batch` with
`_tmr_decode_body_blob_batch`; the SIZE leg calls `tmf_compose_issue_body_batch`
(+ `_tmf_neutralize_autolinks_batch`). Per design §4.6 item 3, the byte leg does
NOT need `tracker_migrate_reverse_reconstruct` / `_tmr_emit_pack_tree` (they
decode the LABEL/H2 PROJECTION, separately tested per §4.6.3) — so this addendum
does NOT add batch modes to them (scope-deliverables-to-the-ask).

### The `_TMF_BATCH` framing protocol (single, shared across all four functions)

A length-prefixed protocol — arbitrary bytes safe (NUL, newline, fence) on BOTH
input and output (decode output is arbitrary bytes; NUL-delimited output would
be unsafe, length-framing is not):

- **stdin:** a decimal record-count line `N\n`; then per record a decimal
  byte-length line `L\n` followed by exactly `L` payload bytes.
- **stdout:** the same shape — `N\n`; then per record `L\n` + `L` payload bytes.
- **compose:** each record carries SIX length-framed fields in order:
  `pack_id, description, context, resolution, file_symbol, raw_body`.

ONE codec: each batch function loops internally in **ONE `python3`** over all N
records, applying the IDENTICAL transform as its single-record sibling — no
second implementation, no per-entry subprocess storm (ci-check-runtime-
compounding).

---

## 2. Per-file summary

### `scripts/lib/tracker-migrate-forward.sh` (+198 lines, modified)
- Added `_tmf_gz64_encode_batch` (after `_tmf_gz64_encode`): batch gzip(mtime=0)+base64.
- Added `_tmf_neutralize_autolinks_batch` (after `_tmf_neutralize_autolinks`): batch trigger-detect + fence-wrap, identical regex logic.
- Added `tmf_compose_issue_body_batch` (after `tmf_compose_issue_body`): batch body assembly — same template_version selection, same neutralize projection (with the same `$(...)` trailing-newline strip), same gz64 blob, same `printf` layout, same whole-body trailing-newline collapse + single `\n`. **By-design difference (NOT a regression):** the batch composer omits the §3.3c provider size-budget / storage-format FAIL-LOUD gate (a production per-create concern; the C-4.6 guard measures composed length itself per §3.LF.5). For every input the single-record path does not abort, the batch output is byte-identical (asserted).
- Single-record `_tmf_gz64_encode`, `_tmf_neutralize_autolinks`, `tmf_compose_issue_body` are **byte-unchanged**.

### `scripts/lib/tracker-migrate-reverse.sh` (+53 lines, modified)
- Added `_tmr_decode_body_blob_batch` (after `_tmr_decode_body_blob`): batch base64-decode + gunzip (the inverse of `_tmf_gz64_encode_batch`), takes ALREADY-EXTRACTED base64 payloads (the seam the guard needs; marker extraction + fail-loud corrupt-blob handling stay in the single-record production path). A record that fails decode aborts the batch (`exit 3`).
- Single-record `_tmr_decode_body_blob` is **byte-unchanged**.

### `scripts/tests/tracker-migrate-forward-test.sh` (+132 lines, modified)
- New §2.9 block + two local framing helpers (`_tmf_batch_frame`, `_tmf_batch_nth`):
  - 2.9.1 (×4) `_tmf_gz64_encode` batch == single-record applied N times.
  - 2.9.2 (×4) `_tmf_neutralize_autolinks` batch == single-record (no-trigger / `#NNN`+SHA / backtick-fence / URL).
  - 2.9.3 (×4) `tmf_compose_issue_body` batch == single-record (incl. BD-136 + BD-204 fixtures, TD+ctx+file, phase no-blob).
  - 2.9.4 (×1) additive invariant — single-record `_tmf_gz64_encode` byte-unchanged.

### `scripts/tests/tracker-migrate-reverse-test.sh` (+86 lines, modified)
- New §2.1e block + two local framing helpers (`_tmr_batch_frame`, `_tmr_batch_nth`):
  - 2.1e-i (×1) batch decode == single-record decode.
  - 2.1e-ii (×4) batch decode(encode(rb)) == original (BD-136 + BD-204 fixtures + trailing-newline case).
  - 2.1e-iii (×2) batch-encode → batch-decode == original (the end-to-end shared-codec seam C-4.6 depends on).
  - 2.1e-iv (×1) additive invariant — single-record `_tmr_decode_body_blob` path byte-unchanged.

### `test-fixtures/manifest.txt`
- Regenerated (`bash test-fixtures/build.sh --all --clean`); diff EMPTY (batch additions are functions inside existing tracked files, no shipped-fixture surface change) → not staged (per the "stage IF non-empty" rule).

---

## 3. The four HARD-INVARIANT attestations

1. **ADDITIVE — single-record path BYTE-UNCHANGED.** ATTESTED. Each batch mode is
   a new entry-point + new input shape; the existing single-record functions'
   source bytes are untouched (the edits insert NEW functions AFTER the existing
   ones). Tests 2.9.4 / 2.1e-iv re-exercise the single-record path and confirm
   byte-identity. The production forward-create + reverse paths keep calling the
   single-record functions.

2. **NO C-4.5 REGRESSION (the gate).** ATTESTED — see §4. The 211-entry lossless
   round-trip is byte-identical across single-record encode, batch encode (==
   single-record), batch decode round-trip, and single-record decode round-trip.
   ZERO byte-differences in the single-record path. (No STOP/REJECT condition hit.)

3. **BATCH-EQUIVALENCE.** ATTESTED — see §5. batch(N) == single-record applied N
   times, byte-identical, over a representative set including BD-136 and BD-204
   fixtures, for all four functions (13 forward + 8 reverse assertions, all PASS),
   AND over the full real 211-entry tree.

4. **ONE codec.** ATTESTED. Each batch function is the SAME logic as its
   single-record sibling, looped in one process — no forked second
   implementation. The C-4.6 guard imports/sub-invokes these same functions, so a
   codec change breaks production AND guard in lockstep (OQ-4 holds literally).

---

## 4. NO-C-4.5-REGRESSION proof — 211-entry round-trip BYTE-IDENTICAL (the gate)

A self-contained harness read `raw_body` = lines 2..EOF (byte-safe, the carrier
contract: line 1 is the back-pointer) from each of the 211 real `backlog/BD-*.md`
entries and ran four legs:

```
entries: 211
batch encode == single-record:                     211 / 211
batch decode(encode(rb)) == original:              211 / 211
single-record decode(encode(rb)) == original:      211 / 211
RESULT: ALL BYTE-IDENTICAL
exit=0
```

- **batch encode == single-record (211/211):** the batch encoder emits the
  byte-identical payload the single-record `_tmf_gz64_encode` emits for every
  real entry → the production single-record contract is unchanged.
- **batch decode(encode) == original (211/211):** the shared codec round-trips
  every real entry's bytes losslessly (the §4.6.2 leg (a) CODEC-LOSSLESS over the
  real tree).
- **single-record decode(encode) == original (211/211):** the PRODUCTION
  single-record path still round-trips every entry byte-faithfully — the C-4.5
  behavior is intact.

`AT`: HEAD `cadfc23`, 2026-06-08. No byte-difference anywhere → the gate PASSES;
no REJECT condition. (Harness was a `/tmp` scratch script, deleted after the run;
its logic is mirrored by the committed batch-equivalence unit tests in §2.9 /
§2.1e and the roundtrip test in the battery.)

---

## 5. BATCH-EQUIVALENCE proof + the `/usr/bin/time` batch number

### Unit-level (representative set incl. BD-136 / BD-204)
- Forward §2.9: **13/13 PASS** (`tracker-migrate-forward-test.sh` total 181/0).
- Reverse §2.1e: **8/8 PASS** (`tracker-migrate-reverse-test.sh` total 133/0).

### Real-tree (211 entries)
- batch encode == single-record: **211/211** (§4).

### MEASURED batch codec runtime over 211 (`/usr/bin/time -p`)

```
framed input bytes: 612153
=== batch ENCODE over 211 (one python3) ===
real 0.05
user 0.03
sys 0.01
=== batch ENCODE→DECODE round-trip over 211 (two python3) ===
real 0.07
user 0.06
sys 0.02
```

**0.05 s** for the batch encode over all 211 in ONE `python3` — exactly the design
§4.6 (S) Option-B EE projection (0.05 s, 211/211 byte-identical). The full
encode→decode round-trip is 0.07 s. The seam C-4.6 depends on is real and fast,
and confirms the no-151×-compounding / no-per-entry-storm property
(ci-check-runtime-compounding). `AT`: HEAD `cadfc23`, 2026-06-08.

---

## 6. FULL unattended battery (verify-full-ci-suite, PACK_VALIDATE_DEEP UNSET)

The complete 45-file battery enumerated from `.github/workflows/validate-pack.yml`
(`grep -oE 'scripts/tests/...\.sh' | sort -u` → 45 distinct files) was run with
`PACK_VALIDATE_DEEP` confirmed unset:

```
battery files passed: 45 / 45
battery wall-clock: 378s
BATTERY: ALL GREEN
```

- **45/45 GREEN**, completed in **378 s (~6.3 min)** — within the ~7-min runtime
  gate; the prior 1.5h+ hang is not reproduced (this addendum adds no general-path
  cost — the deep guard arrives in C-4.6).
- Emphasis files all GREEN: `tracker-migrate-forward-test.sh` (181/0),
  `tracker-migrate-reverse-test.sh` (133/0), `tracker-migrate-roundtrip-test.sh`,
  `tracker-provider-test.sh`, `test-v11-realistic-ot.sh` (banner-pinning).
- `python3 scripts/validate-pack.py`: **PASSED — all checks clean** (14 JC-5
  removed-doc citation WARNs are pre-existing advisory, NOT gate failures, NOT
  introduced here).
- `bash -n` on all four edited files: OK.

---

## 7. Plan deviations

**ZERO substantive deviations.** Implemented §3.LF.3a exactly:
- All four named functions gained a batch mode; reconstruct/emit deliberately
  excluded per §4.6 item 3.
- ADDITIVE new-entry-point shape; single-record contract byte-unchanged.
- Tests added in lock-step (enumerate-encoding-surfaces).

**One design-intentional clarification (not a deviation):** `tmf_compose_issue_body_batch`
omits the §3.3c provider size-budget / storage-format FAIL-LOUD gate (documented
inline + §2 above). This is REQUIRED for the function to be a pure assembly the
C-4.6 guard can measure (§3.LF.5 has the guard enforce the budget itself); the
plan's "assembles markers + neutralized H2 + the gz64 blob" assembly contract is
met byte-for-byte for all non-aborting inputs (proven by 2.9.3). This matches
design §4.6 item 2 ("the guard reuses the SAME batch codec ... and assembles the
body shape ... `tmf_compose_issue_body` itself gains a batch mode the guard
calls"). No architecture change.

---

## 8. New POQs introduced

**None.** No gap in the plan/design required a new POQ; §3.LF.3a was fully
specified and the C-4.6 consumer's needs (§4.6.2 byte leg + §3.LF.5 size leg) map
cleanly onto the four batch entry-points.

---

## 9. CONCERNS

1. **UTF-8 round-trip in the neutralizer/composer batch (matches single-record).**
   The batch neutralize/compose decode field bytes via `decode("utf-8")` and
   re-encode via `encode("utf-8")` — IDENTICAL to the single-record `sys.stdin.read()`
   / `sys.stdout.write()` text path (default UTF-8). Real pack-entry content is
   UTF-8 text, so this is lossless and byte-equivalent (proven 211/211 + unit). The
   gz64 codec batch (encode/decode) operates on RAW BYTES throughout, so it is
   binary-faithful regardless. No action needed; flagged for the reviewer's
   awareness that the text-mode functions share the single-record path's UTF-8
   assumption (not a new assumption).

2. **The byte-leg pairing the guard will use.** C-4.6's byte leg is
   `PRE_PARSE_ORIGINAL_body == decode(encode(raw_body))` (§4.6.2 — two assertions,
   NOT the tautology). This addendum delivers `decode(encode(...))` via
   `_tmf_gz64_encode_batch` → `_tmr_decode_body_blob_batch`; leg (b) PARSE-FAITHFUL
   (`PRE_PARSE_ORIGINAL == raw_body`, the C-2 catch) is the guard's own
   responsibility in C-4.6 (it compares the byte-safe pre-parse original to the
   parser-captured span). This commit correctly scopes to the codec seam only — no
   overreach into C-4.6.

3. **Manifest unchanged.** The v11-surface (`scripts/`) was touched, so the
   manifest was regenerated per rule; the diff was empty (no shipped-fixture
   content depends on these libs' function bodies). Confirmed not staged.

---

## 10. Definition-of-Done checklist

| Item | Result |
|---|---|
| `_tmf_gz64_encode` batch mode added (additive entry-point) | PASS |
| `_tmf_neutralize_autolinks` batch mode added | PASS |
| `tmf_compose_issue_body` batch mode added | PASS |
| `_tmr_decode_body_blob` batch mode added | PASS |
| Single-record paths byte-unchanged (additive) | PASS |
| Batch-equivalence unit tests added in lock-step (fwd+rev) | PASS (13 + 8) |
| `bash -n` all 4 edited files | PASS |
| `tracker-migrate-forward-test.sh` GREEN | PASS (181/0) |
| `tracker-migrate-reverse-test.sh` GREEN | PASS (133/0) |
| `tracker-migrate-roundtrip-test.sh` GREEN | PASS |
| `tracker-provider-test.sh` GREEN | PASS |
| `test-v11-realistic-ot.sh` GREEN (banner-pinning) | PASS |
| `python3 scripts/validate-pack.py` GREEN | PASS |
| FULL battery (45 files) COMPLETES, deep UNSET | PASS (45/45, 378s) |
| NO-C-4.5-REGRESSION 211-round-trip byte-identical | PASS (211/211 ×3 legs) |
| BATCH-EQUIVALENCE proof | PASS (unit + 211/211) |
| `/usr/bin/time -p` batch codec over 211 quoted | PASS (0.05 s) |
| Manifest regen + stage-if-non-empty | PASS (empty → not staged) |
| Scope fence: no `validate-pack.py` / workflow touched (C-4.6) | PASS |
| No git state changes (agents-never-commit) | PASS |

---

## 11. Files-changed inventory

| Path | Change type |
|---|---|
| `scripts/lib/tracker-migrate-forward.sh` | modified (+198: 3 batch fns) |
| `scripts/lib/tracker-migrate-reverse.sh` | modified (+53: 1 batch fn) |
| `scripts/tests/tracker-migrate-forward-test.sh` | modified (+132: §2.9 + helpers) |
| `scripts/tests/tracker-migrate-reverse-test.sh` | modified (+86: §2.1e + helpers) |
| `test-fixtures/manifest.txt` | regenerated, diff empty → NOT staged |

`git diff --stat`: 4 files changed, 469 insertions(+), 0 deletions.

---

## 12. Boundary discipline check

All edits are PACK-ONLY under `scripts/lib/` + `scripts/tests/`. No
`project-template/`, `supporting-docs/`, or other client-shipped surface was
touched → no project-side SSOT investigation applies (boundary-investigation-
precedes-pack-defaults: N/A — no project-side edit). No pack-only reference was
added to any client surface.

---

## 13. Rules-Applied Verification Block

| Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|
| agents-never-commit | No git add/commit/push/tag run; `git rev-parse HEAD` = `cadfc23` unchanged pre→post; only read-only `git status`/`git diff`/`git rev-parse`. | COMPLIANT |
| per-action-approval-sub-agents | No destructive op beyond in-scope file edits; `/tmp` scratch files self-created + `rm -f`'d; no live GH (`PACK_TRACKER_LIVE_GH` never set). | COMPLIANT |
| preflight-stop-means-stop | Emitted `PREFLIGHT: 4/4 ... PASS; HEAD cadfc23 ...` only after ALL verification green (battery 45/45, validate-pack clean, 211-round-trip + equivalence + time). No parent stop received. | COMPLIANT |
| verify-full-ci-suite | Ran the ENTIRE 45-file battery (workflow `run:` set), var UNSET → `battery files passed: 45 / 45`, `378s`, `BATTERY: ALL GREEN`; COMPLETED (not hung). | COMPLIANT |
| regenerate-manifest-v11-surface | `scripts/` touched → ran `bash test-fixtures/build.sh --all --clean`; `git status --short test-fixtures/manifest.txt` EMPTY → no stage needed (rule: stage IF non-empty). | COMPLIANT |
| enumerate-encoding-surfaces | Each batch fn shipped WITH its assertions in the same commit: fwd lib + `tracker-migrate-forward-test.sh §2.9` (13); rev lib + `tracker-migrate-reverse-test.sh §2.1e` (8). Lock-step. | COMPLIANT |
| edit-in-place-not-full-rewrite | All edits were targeted `Edit` insertions after existing functions (no file rewrite); single-record fn bodies untouched; re-verified via `git diff --stat` (469 insertions, 0 deletions). | COMPLIANT |
| pack-repo-code-comment-deferrals | No deferral comments introduced (no `TODO`/`FIXME`/`KNOWN GAP` added); grep of the diff shows none. | N/A: no deferrals authored |
| scope-deliverables-to-the-ask | Implemented exactly §3.LF.3a's four functions; reconstruct/emit excluded per §4.6 item 3; NO `validate-pack.py`/workflow edit (C-4.6). `git status` shows only the 4 in-scope files. | COMPLIANT |
| boundary-investigation-precedes-pack-defaults | Pack-only edits under `scripts/lib` + `scripts/tests`; no project-side/client-shipped surface touched (see §12). | N/A: no project-side edit |
| ci-check-runtime-compounding | Batch mode is ONE `python3` looping internally over N records (no per-entry spawn); measured 0.05 s over 211; battery completed 378 s (no compounding). | COMPLIANT |
| rules-applied-verification-block | This table — each rule has named evidence (command/count/path quoted) + terminal conclusion; no empty-evidence row. | COMPLIANT |

---

*End of IMPL-REPORT — BD-204 C-4.5-ADDENDUM.*
