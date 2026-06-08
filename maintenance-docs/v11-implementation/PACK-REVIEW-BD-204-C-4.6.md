# PACK-REVIEW — BD-204 C-4.6 (CI faithfulness guard, Option B: single-source batch codec)

**Reviewer:** pack-reviewer (adversarial; FINAL CORRECTNESS GATE — no separate pre-code design review)
**Branch:** v11-dev · **HEAD:** `f89ade57fe5ecf99c532adbe0ce511cbd81edf30`
**Scope:** PACK-ONLY · read-only on codebase (this report is the sole write)
**Changed files reviewed:** `scripts/validate-pack.py` (Check 49 + `run_check` + Check 50 + total-run guard), `.github/workflows/validate-pack.yml` (both deep homes), new `scripts/tests/test-validate-pack-check-49-field-faithfulness.sh`, IMPL-REPORT `IMPL-REPORT-BD-204-C-4.6.md`.

---

## VERDICT: **FIXES** (bounded cycle — one MUST + minor NITs; the carry-fields approach HOLDS)

The guard is functionally correct on every load-bearing axis: OQ-4 single-source is REAL (no codec reproduction in validate-pack.py), the byte-leg is the §4.6.2 two-assertion contract (NOT the tautology) and CATCHES the C-2 loss the tautology missed, runtime non-recurrence is proven (battery completes in 408 s, deep 2.88 s), no C-4.5 regression, and all primary teeth fire.

It is **NOT FAILS-HARD** — no fundamental flaw the design cannot satisfy; the carry-fields approach is sound and the user's accept-vs-abandon escalation is NOT triggered.

The single MUST is a **self-hole in Check 50's exclusion logic** (proof 2c): a *fully functional* reproduced gz64 codec CAN be placed in validate-pack.py and EVADE Check 50 entirely if each reproduced-codec line carries a quoted copy of its own token. This does not defeat C-4.6's correctness today (no reproduction exists; Check 49 drives the shared codec), but it weakens the OQ-4 structural backstop Check 50 exists to provide. Fixable with a bounded one-function edit.

---

## THE 10 PROOFS (re-measured against the actual code — IMPL-REPORT not trusted)

### Proof 1 — OQ-4: DRIVES, NOT REPRODUCES — **PASS**

The deep leg's seam (`_CHECK_49_SEAM_SCRIPT`, `validate-pack.py:7431-7481`) sources the migrator libs once and calls the C-4.5-addendum batch functions:
- `tmf_parse_backlog_tree` (`:7444`), `_tmf_gz64_encode_batch` (`:7458`), `_tmr_decode_body_blob_batch` (`:7459`), `tmf_compose_issue_body_batch` (`:7464`).

The seam's inner `python3` blocks (`:7449-7457`, `:7464-7474`) do ONLY length-framing + JSON read — no codec transform. Verified every `gzip`/`base64` token in validate-pack.py:
```
grep -nE "gzip|base64" scripts/validate-pack.py
```
→ all 16 hits are (a) `#`-comment lines (`:7686,7688,7696,7702,7716,7726,7757,7758`), (b) the Check-50 denylist tuple as QUOTED strings (`:7703-7709`), or (c) failure-message string literals (`:7769,7779,7955`). **Zero executable codec transforms.** The migrator lib `tmf_compose_issue_body_batch` (`tracker-migrate-forward.sh:1007-1054`) legitimately contains the ONE single-sourced `gzip.GzipFile`/`base64.b64encode` codec — that is the production codec the guard CALLS, exactly per OQ-4 (one codec, in the migrator, never copied into the guard). The guard does NOT invoke `tracker_migrate_reverse_reconstruct`/`_tmr_emit_pack_tree` (the projection path, separately tested). **OQ-4 holds literally.**

### Proof 2 — Check 50 single-source: TEETH yes; NO false-FAIL; **SELF-HOLE present** — **PASS-with-MUST**

**(a) TEETH — PASS.** Injected a real `import gzip` + `gzip.compress(b'x')` into a temp copy → Check 50 emits 2 failures (`FAILURES: 2`). A naive reproduction is caught.

**(b) No false-FAIL on its own definition — PASS.** Clean HEAD: `check_validate_pack_no_reproduced_codec()` → `FAILURES: 0` (`OK: Check 50 — no reproduced gz64/base64 codec`). The exclusion of the seam-string span (`:7730-7745`), `#`-comment lines (`:7751`), and the quoted denylist tuple (`:7760-7762`) correctly excuses the guard's own legitimate token occurrences.

**(c) SELF-HOLE — the adversarial finding — A REAL HOLE EXISTS (MUST-fix).**
The per-line quote-escape at `:7760-7762`:
```python
if token in line:
    quoted = (f'"{token}"' in line) or (f"'{token}'" in line)
    if not quoted:
        hits.append(...)
```
matches a quoted form of the token ANYWHERE on the line — it is **per-line**, not per-occurrence. So a line that has BOTH a *real bare codec call* AND a *quoted copy of the same token* is excused. I injected a **fully functional** reproduced codec where every line self-quotes its token:
```
import gzip  # "import gzip"
import base64  # "import base64"
def _reproduced_gz64(raw):
    z = gzip.compress(raw)  # "gzip.compress"
    return base64.b64encode(z)  # "base64.b64encode"
def _reproduced_ungz64(blob):
    z = base64.b64decode(blob)  # "base64.b64decode"
    return gzip.decompress(z)  # "gzip.decompress"
```
Result: `check_validate_pack_no_reproduced_codec()` → **`FAILURES: 0` (PASS)** — Check 50 sees a clean source. I confirmed the injected codec is REAL: `_reproduced_gz64`/`_reproduced_ungz64` round-trip `b"hello\x00\r..."` and emit a genuine gzip+base64 blob (`H4sIAAAA...`). So an actor CAN reintroduce a drift-prone second codec and evade the OQ-4 guard.

**Severity = MUST (not BLOCKER).** C-4.6 is correct *today* (no reproduction present; Check 49 drives the shared codec, proof 1). The hole weakens the *future* structural backstop — exactly the "structurally enforced, not by review attention" property §4.6.3/§4.5 promise. Recommended fix (bounded, one function): make the escape per-occurrence — strip quoted-string segments from the line BEFORE the membership test (e.g. regex-remove `"..."`/`'...'` spans, then test `token in residual`), so a bare call on a self-quoting line is still caught. The existing teeth + the `vpe.py` evasion both become detectable.

### Proof 3 — Byte leg = §4.6.2 (two assertions, NOT the tautology) + C-2 teeth — **PASS**

Code (`:7583-7609`): leg (a) CODEC-LOSSLESS `decoded[idx] != raw_body` (the shared batch codec round-trip) AND leg (b) PARSE-FAITHFUL `pre_parse_original != raw_body`. `pre_parse_original` is read BYTE-SAFELY in Python: `file_bytes[file_bytes.find(b"\n")+1:]` (`:7599-7601`) — a direct byte read after the first `\n`, **NEVER awk/tail** (grep of the check body + seam confirms no `awk`/`tail -n`). The bare `== raw_body` tautology is absent.

**C-2 teeth (my own scratch fixtures, not the test's):** a BD-901 body with a CR and a BD-902 body with a NUL, run directly through `check_migrator_field_faithfulness(scratch)`:
```
Check 49 — BD-901: PARSE-FAITHFUL leg FAILED (PRE_PARSE_ORIGINAL != raw_body — the C-2 catch ...)
Check 49 — BD-901: R-BODY-6 disallowed control byte 0x0d at body offset 47 ...
Check 49 — BD-902: PARSE-FAITHFUL leg FAILED (... C-2 catch ...)
Check 49 — BD-902: R-BODY-6 disallowed control byte 0x00 at body offset 48 ...
```
BOTH leg (b) AND R-BODY-6 fire on each — the exact catch the tautology missed. A clean well-formed entry (copy of BD-002) → `FAILURES: 0`, so leg (b) does not false-positive.

### Proof 4 — Runtime non-recurrence — **PASS**

- Env-gate is the FIRST statement of `check_migrator_field_faithfulness` (`:7526-7528`) — `os.environ.get("PACK_VALIDATE_DEEP") != "1"` → `ok(SKIP...)` → return, BEFORE any tree read.
- NO `tree_dir or REPO_ROOT/"backlog"` fallback; `tree_path = Path(tree_dir)` (`:7531`) uses the caller's target; the caller passes the real tree explicitly via `lambda: check_migrator_field_faithfulness(REPO_ROOT / "backlog")` (`:7958`).
- Batch seam = ONE `python3` per shared batch fn (not per-entry).
- **MEASURED (`/usr/bin/time -p`, deep UNSET):** general = **1.32 s** (deep SKIPPED, no runtime-budget breach). Deep = **2.88 s** (211/211 byte-faithful). Deep `total_elapsed` sum = **2.86 s** vs 35 s budget; Check 49 alone = **1.58 s**.
- **FULL unattended battery (51 test files + validate-pack, `PACK_VALIDATE_DEEP` UNSET): completes in 408 s (~6.8 min)** — the runtime gate the prior 1.5 h+ hang failed. (One failure, see Overstep note — pre-existing, unrelated.)

### Proof 5 — Runtime-budget guard (§4.7), general-path-only — **PASS**

`main()` (`:7968-7979`): `total_budget = DEEP(35) if PACK_VALIDATE_DEEP==1 else GENERAL(10)`; over budget → `fail("RUNTIME-BUDGET: validate-pack total ...")`. Independent test (synthetic 999 s check timing): general budget 10 s → FAIL (1 failure); deep budget 35 s → also fails at 999 s but a real 2.86 s deep run is far under 35 s (never falsely failed). Per-check WARN (`run_check`, `:457-461`): a 3 s check (over 2 s) WARNs and adds **0 failures** (non-gating) — correct. The 10 s total is GENERAL-PATH-ONLY; deep carries its own 35 s.

### Proof 6 — No C-4.5 regression — **PASS**

`tracker-migrate-roundtrip-test.sh` (211-entry lossless round-trip), `tracker-migrate-forward-test.sh`, `tracker-migrate-reverse-test.sh` → all **`All tests passed.`** (exit 0). The migrator libs were NOT edited (`git diff --name-only HEAD -- scripts/lib/` empty).

### Proof 7 — All teeth — **PASS**

| Teeth | Independent result |
|---|---|
| byte-leg (b) CR (C-2) | leg (b) + R-BODY-6 0x0d both fire |
| R-BODY-6 NUL | leg (b) + R-BODY-6 0x00 both fire |
| SIZE over-budget | `composed body ... exceeds provider body limit 65536 − margin 65536 = 0` fires |
| TITLE over-length | `stored title 308 codepoints exceeds R-TITLE-1 limit 256` fires |
| single-source (naive) | Check 50 → 2 failures on injected `gzip.compress` |
| slow-check total-run | `main()` FAILs with `RUNTIME-BUDGET: validate-pack total` |

Per-check test `test-validate-pack-check-49-field-faithfulness.sh`: `PASS: 7 / FAIL: 0`. Check 42 (per-check wiring): `PASS: 4 / FAIL: 0`.

### Proof 8 — Both deep homes target the REAL ≥211 tree — **PASS**

- Per-check test POSITIVE leg (`:88,96-99`) runs `PACK_VALIDATE_DEEP=1 python3 "$VALIDATE"` against the real repo and ASSERTS entry count ≥ 211 (toothless-guard `t_fail "... entry count <211 (toothless)"`). NOT a fixture-pointed POSITIVE.
- Dedicated workflow step `.github/workflows/validate-pack.yml` (validate job): `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` runs once per push on real `/backlog/`.
- Per-check test wired into the tests job (Check 42 green). Deep banner: `Check 49 — 211 entries byte-faithful ...`.

### Proof 9 — Hardcoded `pack-backlog` stream key — **NIT**

`tree_key = "pack-backlog"` (`:7540`). Verified the seam parses the real `/backlog/` tree correctly under this key (211 entries; `title`/`raw_body`/`pack_id` present). The key only labels the stream for `pe_list_entry_files`'s entry-regex; the byte work is key-agnostic; both §3.LF.5 deep homes target `/backlog/`. A future changelog-stream caller would need a different key — out of §3.LF.5 scope, documented in the check comment. **Acceptable; NIT.**

### Proof 10 — Scope/fence + overstep sweep — **PASS (one unrelated pre-existing battery failure flagged)**

`git status --short`: exactly `M scripts/validate-pack.py`, `M .github/workflows/validate-pack.yml`, `?? scripts/tests/test-validate-pack-check-49-field-faithfulness.sh`, `?? maintenance-docs/.../IMPL-REPORT-BD-204-C-4.6.md`. No migrator edit, no `_rules.md`/entry edit, no other maintenance-docs source. Manifest regen (`bash test-fixtures/build.sh --all --clean`, exit 0) → **empty diff** (correct: the manifest tracks `project-template/` deliverable surface, not `scripts/`). Registry integers 49/50 are next-free (highest prior banner = 48); no banner collision. Nothing outside §3.LF.5.

**Overstep/unrelated note (NOT a C-4.6 defect):** the full battery had ONE failure — `test-tracker-promote-path1.sh` group `8.3 METHODOLOGY.md cites V3.3 §3`. I proved it PRE-EXISTING: stashing the C-4.6 changes and re-running the test fails IDENTICALLY at clean HEAD `f89ade5`. It references none of the C-4.6 surfaces. Surface to Pack Chat as a separate item; it does not bear on this verdict.

---

## FINDINGS SUMMARY (triage-ready)

| # | Severity | Finding | Recommended disposition |
|---|---|---|---|
| F-1 | **MUST** | Check 50 self-hole: a fully functional reproduced codec evades detection when each codec line self-quotes its token (per-line escape, not per-occurrence). Proven with a real round-tripping injection (`FAILURES: 0`). | FIX — make the quote-escape per-occurrence (strip quoted spans before the `token in residual` test); add an evasion-case negative to the per-check test (enumerate-encoding-surfaces). |
| F-2 | NIT | Check 49 per-check `budget_s` set to `RUN_CHECK_TOTAL_DEEP_BUDGET_S` (35 s) vs the spec §4.7 "deep faithfulness-check budget = 30 s". Measured 1.58 s — no functional impact. | FIX-or-accept — align to a 30 s deep per-check constant, or accept the 35 s with a one-line rationale note. |
| F-3 | NIT | Hardcoded `tree_key = "pack-backlog"` in the seam (proof 9). | Accept — out of §3.LF.5 scope; documented. |
| F-4 | NIT (out of scope) | Pre-existing battery failure `test-tracker-promote-path1.sh` (8.3 METHODOLOGY.md cites V3.3 §3) — fails identically at clean HEAD. | Surface to Pack Chat as a separate item; not C-4.6. |
| F-5 | NIT | IMPL-REPORT says "52 unique test files"; observed 51 in `scripts/tests/`. Cosmetic count drift. | Accept. |

**Empty sections:** No BLOCKER findings. No FAILS-HARD condition. The accept-vs-abandon user escalation (`project_bd204_c46_last_redesign`) is NOT triggered — the carry-fields approach is correct.

---

## Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| `agents-never-commit` | Only read-only git verbs (`status`, `rev-parse`, `diff`, `stash push/pop` to A/B test then RESTORED — pop confirmed "Dropped refs/stash@{0}", working tree returned to pre-review state). No `add`/`commit`/`push`/`tag`. HEAD unchanged `f89ade5`. | COMPLIANT |
| `empirical-evidence-blocks` | Every proof carries the actual CMD + verbatim OUT or quoted code + line refs; HEAD `f89ade57...` pinned; measurements (1.32 s general / 2.88 s deep / 408 s battery / Check-50 `FAILURES: 0` evasion / C-2 fixture failures) are quoted, not paraphrased. | COMPLIANT |
| `verify-full-ci-suite` | Ran the FULL 51-file battery + validate-pack (not validate-pack alone) + per-check test 49 + Check 42 + the 3 migrator tests; quoted banner outputs. Caught the pre-existing promote-path1 failure and isolated it via stash A/B. | COMPLIANT |
| `ci-check-runtime-compounding` | Confirmed env-gate FIRST (general ~0), no `tree_dir or`/`REPO_ROOT/backlog` fallback in body, ONE python3 per batch fn, total-run guard present; battery COMPLETES (408 s) — the compounding constraint holds. | COMPLIANT |
| `enumerate-encoding-surfaces` | Verified the lock-step set: the check + `run_check` + Check 50 + the per-check test + BOTH workflow homes + Check 42 wiring. F-1 fix recommendation explicitly includes adding the evasion negative to the per-check test (asymmetric coverage = audit gap). | COMPLIANT |
| `scope-deliverables-to-the-ask` | Delivered exactly the 10 proofs + verdict + the adversarial Check-50 self-hole; no edge-case sprawl; report is the single permitted write at the prompted path. | COMPLIANT |
| `rules-applied-verification-block` | This table. | COMPLIANT |

---

## READ-IN-FULL attestation

Read in full: PLAN-BD-204.md §3.LF.5 (`:644-675`); ARCHITECTURE-BD-204-LOSSLESS-FIX.md §4.5 (`:845-899`), §4.6/§4.6.1/§4.6.2/§4.6.3 (`:900-1149`), §4.7 (`:1151-1194`); memory `feedback_ci_check_runtime_compounding.md` + `project_bd204_c46_last_redesign.md`; `scripts/validate-pack.py` Check 49 (`:7431-7681`), `run_check` (`:436-461`), Check 50 (`:7683-7781`), `main()` registration + total-run guard (`:7946-7979`); the batch functions in `scripts/lib/tracker-migrate-forward.sh` (`_tmf_gz64_encode_batch :731`, `tmf_compose_issue_body_batch :1006`) + `tracker-migrate-reverse.sh` (`_tmr_decode_body_blob_batch :727`); the new `scripts/tests/test-validate-pack-check-49-field-faithfulness.sh` + an existing per-check test (`test-validate-pack-check-42.sh`); `.github/workflows/validate-pack.yml` diff; the IMPL-REPORT (verified, not trusted); CLAUDE.md `## Pack memory` in full. No file was skimmed, summarized in lieu of reading, or cropped.
