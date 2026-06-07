# PACK-REVIEW-BD-204-C-3-AMENDMENT

> **Reviewer:** pack-reviewer (adversarial; re-measured against the actual code, did
> NOT trust the IMPL-REPORT). **Branch:** `v11-dev`. **HEAD:**
> `d5786267f4cb980dd8184db4416286b6fd6dac96`. **Date:** 2026-06-07. **Scope:** PACK-ONLY.
> Read-only on the codebase; this report is the single permitted write.
>
> **What was reviewed.** The C-3-amendment working-tree change (§3.LF.4): keep the gz64
> blob + the H2 projection in sync on tracker-side writes (`tracker-edit.sh`) and detect
> human-edit divergence on reverse (`tracker-migrate-reverse.sh`), plus the two test files.
> Changed files (`git diff --name-only` + untracked): `scripts/lib/tracker-edit.sh`,
> `scripts/lib/tracker-migrate-reverse.sh`, `scripts/tests/tracker-migrate-reverse-test.sh`,
> `scripts/tests/tracker-provider-test.sh`, and the new
> `maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-C-3-AMENDMENT.md`.

---

## VERDICT: PROCEED (clean)

All 4 hard invariants hold; both concerns adjudicated FAVOURABLY (C1 expected/non-issue;
C2 in-scope-required-and-correct); full battery green; teeth proven; manifest empty-diff
correct; scope fenced to exactly the 4 files + IMPL-REPORT; overstep sweep clean (the one
fixture-body edit is a REQUIRED lock-step correction, not an overstep). No BLOCKER, no MUST,
no SHOULD findings. Two NITs (non-blocking) are recorded below.

---

## THE 4 HARD INVARIANTS

### Invariant 1 — sync CALLS the C-4.5 composer; NO second gz64/H2 impl; H2+blob regenerate atomically — HELD

- `tracker-edit.sh` sources `tracker-migrate-forward.sh` idempotently (diff @ top of file:
  `[[ -z "$(declare -f tmf_compose_issue_body ...)" ]] && source .../tracker-migrate-forward.sh`)
  and calls `tmf_compose_issue_body "$pack_id" "$ed_description" "$ed_context"
  "$ed_resolution" "$ed_file_symbol" "$ed_raw_body"` (the 6-arg blob-aware composer).
- The composer at `tracker-migrate-forward.sh:811` (`local raw_body="${6:-}"`) is the SINGLE
  codec: it neutralizes the four H2 field values via `_tmf_neutralize_autolinks` (`:828-831`)
  AND emits the blob `<!-- pack-entry-body-gz64: %s -->` via `_tmf_gz64_encode` (`:837,:846`)
  in the ONE call. `grep -nE 'gz64|_tmf_gz64_encode|pack-entry-body'
  scripts/lib/tracker-edit.sh` → ZERO matches in the edit lib body: no re-implementation.
- Atomicity: the recompose is gated on `has_content` (any of
  description/context/resolution/file_symbol/raw_body present); when true the composed body
  REPLACES any literal `body` key via `jq '.body = $b'`, so a content-bearing
  `provider_update` ALWAYS carries both representations from the same composer call — never
  one without the other. If the composer fails (size budget / storage format), the edit path
  `tracker_error_emit "validation" ... return 1` BEFORE any `provider_update` (no partial
  sync). `validation` is a valid `tracker-errors.sh` type (`:94`).
- **Empirical:** `tracker-provider-test.sh` 4.7 asserts the recomposed payload carries
  `pack-entry-body-gz64:` + `## Description` + the edited value + `## File / Symbol`; 4.7b
  decodes the payload's blob and runs the reverse comparator against the payload body itself
  → MATCH (rc=0). All pass against the working tree.

### Invariant 2 — comparator normalization set EXACTLY {CRLF/CR→LF; per-line trailing-ws strip; single trailing-newline}; teeth correct; `--force` via the EXISTING flag — HELD

- The `norm()` python in `_tmr_check_blob_h2_divergence` applies EXACTLY three transforms
  and no broader (reverse diff):
  `(1) s.replace("\r\n","\n").replace("\r","\n")` ;
  `(2) "\n".join(line.rstrip(" \t") for line in s.split("\n"))` ;
  `(3) s.rstrip("\n") + "\n"`.
  NO case-fold, NO Unicode normalization, NO interior-whitespace collapse, NO content touch.
  Set is precisely the spec set (§3.3a(ii) / R-NORM) — no broader, no narrower.
- The recomputed H2 ("expected") comes from the REAL forward parser
  (`_tmf_parse_backlog_file` on the decoded `raw_body`) projected through the REAL
  `_tmf_neutralize_autolinks` — the same codec the composer uses; the stored H2 ("got")
  comes from the same `_tmr_extract_section` extractor reconstruct already uses. The blob is
  NEVER mutated (the comparator reads `raw_body`, writes a `mktemp` temp, parses, `rm -f`;
  no write-back).
- TEETH (re-run by me, NOT trusted from the report):
  - **No false-positive on a CRLF + trailing-space body:** 2.1d-i feeds a body with real
    `\r\n` + per-line trailing spaces → comparator MATCHES (rc=0). PASS.
  - **Mismatch on a one-word edit (fox→cat):** 2.1d-ii → comparator FAILs loud (rc=1) with
    `divergence: issue #79` naming `Description`. PASS.
  - **`--force` overrides to blob-wins:** 2.1d-iii passes `force=1` (the EXISTING
    `tracker_migrate_reverse_run` `force="${5:-0}"` flag, threaded through reconstruct's new
    `force="${3:-0}"` param into the comparator's 5th arg — NOT a new flag) → rc=0 + a
    `blob wins` WARN on stderr. PASS. Verified `--force` is the existing refusal idiom:
    `grep 'local force' tracker-migrate-reverse.sh` shows it on `reverse_run` (`:1185`),
    `reconstruct` (`:542`, new), and the comparator (`:746`).

### Invariant 3 — blob authoritative; comparator never mutates the blob; recomputed H2 from the real forward parser+neutralizer — HELD

- See Invariant 2: the recompute path is `_tmf_parse_backlog_file` + `_tmf_neutralize_autolinks`
  (the production forward symbols, sourced idempotently into reverse), never a re-impl. The
  comparator only READS `raw_body`; the blob bytes are untouched. On an unparseable blob
  (`parsed` empty/`[]`) the comparator returns 0 and defers to the existing corrupt-blob /
  decode-identity guards rather than false-flagging — correct layering.

### Invariant 4 — C-4.5 carrier/emit/composer unchanged except the ADDED comparator call; `_tmr_emit_backlog` (client) BYTE-UNTOUCHED — HELD

- `git diff scripts/lib/tracker-migrate-reverse.sh | grep _tmr_emit_backlog` → ZERO matches.
  The diff hunks land ONLY at: the forward-lib source block (`@@ -93`), reconstruct's new
  `force` param (`@@ -523`), the comparator call hook (`@@ -577`), the new comparator helper
  (`@@ -674`), and the run-loop rc-check (`@@ -1161`). No hunk touches `_tmr_emit_backlog`
  (client `# BACKLOG` monolith) nor the `_tmr_emit_pack_tree` C-4.5 emit body.
- `tracker-migrate-forward.sh` is NOT in `git diff --name-only` — the composer is REUSED
  as-is (sourced, not edited). No carrier re-touch.

---

## THE 2 CONCERN ADJUDICATIONS

### C1 — the 3 parked C-7 files vanished — EXPECTED / NON-ISSUE (not a finding)

`scripts/tests/tracker-bd204-lossless-roundtrip-test.sh`,
`scripts/tests/fixtures/tracker-bd204-lossless/`, and `IMPL-REPORT-BD-204-BD-C7.md` were
`??` (untracked) at the session-start snapshot and are absent now. Per the context supplied:
Pack Chat deleted them earlier under explicit user approval (gap-contaminated parked C-7 +
its superseded IMPL-REPORT) as the C-7 REBUILD targets (§3.LF.7). I verified the C-3
amendment is independent of them: (a) `git diff` of the 4 files contains ZERO references to
`bd204-lossless` / `tracker-bd204` / `C-7`; (b) nothing in the changed code depends on those
fixtures; (c) the change did not delete them (untracked files removed by Pack Chat, not by
this code; `test-fixtures/build.sh --clean` only wipes targets under `test-fixtures/`, not
`scripts/tests/fixtures/`). Render: **expected / non-issue.**

### C2 — the rc-check added to the reverse RUN-LOOP — IN-SCOPE-REQUIRED-AND-CORRECT

- **(a) Necessary for §3.LF.4's divergence requirement?** YES. At HEAD the run-loop was
  `rec=$(tracker_migrate_reverse_reconstruct "$issue" "$mapping")` — command substitution
  DISCARDS the inner rc, so reconstruct's `return 1` (the divergence abort AND the
  pre-existing C-4.5 corrupt-blob abort at `:589`) never propagated. A comparator that cannot
  abort the loop is useless; the rc capture (`rec_rc=$?` + `if [[ "$rec_rc" -ne 0 ]]; then
  ... return 1`) is exactly what makes the divergence backstop effective. Required.
- **(b) Correct — propagates the abort without breaking other paths?** YES. The rc-check is
  INSIDE the `BD-*|TD-*` case only; the `phase-*` case and the `*` fallthrough are untouched.
  The inbound soft-skip lanes (provider_get fail `:1294`; unresolvable pack-id `:1311`; null
  roster id `:1289`) remain `continue` (soft skip → `skipped_log`). Divergence/corrupt is a
  DISTINCT, HARD class (loud abort, not a soft skip — correct per §3.3a fail-loud); the abort
  does `rm -f "$skipped_log"` (no temp leak) then `return 1` with a typed `validation` error.
  `force` is correctly threaded from `reverse_run`'s `force="${5:-0}"` into reconstruct so
  `--force` overrides to blob-wins. Partial-success semantics for the soft-skip class are
  unchanged (end-of-loop guard at `:1389` still governs them).
- **(c) Does making the C-4.5 corrupt-blob abort "now effective" break any existing test?**
  NO. The corrupt-blob `return 1` (`:589`) was a no-op pre-amendment only because the
  run-loop ignored the rc; no existing test feeds a CORRUPT blob through the RUN-LOOP (2.1b
  tests reconstruct directly, and already saw rc=1 at HEAD). The `reverse_run` callers in
  `bd132-race-test.sh` + `roundtrip-test.sh` use VALID blobs, so no abort fires — all green
  in the full battery. No existing expectation changes.
- Render: **in-scope-required-and-correct.**

---

## ALSO-VERIFIED

- **FULL BATTERY (verify-full-ci-suite).** I ran `python3 scripts/validate-pack.py` →
  `PASSED — all checks clean`. I then ran the ENTIRE unattended battery — all 45
  `scripts/tests/*.sh` enumerated from `.github/workflows/validate-pack.yml` (`grep -oE
  'scripts/tests/[A-Za-z0-9._-]+\.sh'` → 45 unique) — via per-script rc capture: **PASS=45
  FAIL=0.** Includes `test-v11-realistic-ot.sh` (banner-pinning) and the four directly-relevant
  trackers (reverse 125/0, provider 127/0, forward 168/0, roundtrip 51/0; internal
  `Failed: 0` each).
- **TEETH (re-run by me).** Built a sandbox with the working-tree TESTS but the HEAD
  (un-amended) libs. Result: reverse-test 2.1d-ii (mismatch caught) + 2.1d-iii (force WARN)
  FAIL (4 fails); provider-test ALL FIVE 4.7/4.7b sync legs FAIL. The new test legs genuinely
  fail in the absence of the change. (Note: 2.1d-i no-false-positive PASSES even at HEAD —
  with no comparator there is no abort, so rc=0 trivially; it is a no-false-positive guard,
  not a standalone teeth leg. Not a defect — recorded as NIT-1.)
- **MANIFEST.** `bash test-fixtures/build.sh --all --clean` → rc=0; `git status --short
  test-fixtures/manifest.txt` → empty; `diff` of pre/post manifest → UNCHANGED. The
  empty-diff claim is CORRECT (these scripts are not manifest-shipped trees).
- **SCOPE / FENCE.** `git status --short` shows EXACTLY the 4 files + the IMPL-REPORT. No
  `tracker-migrate-forward.sh` carrier re-touch, no `validate-pack.py`, no `_rules.md`, no
  `backlog/BD-*.md`, no `project-template/`, no `supporting-docs/`, no maintenance-docs beyond
  the report. PACK-ONLY clean.
- **OVERSTEP SWEEP.** Everything in the diffs maps to §3.LF.4: (1) tracker-edit blob+H2 sync
  (source-forward + `has_content` recompose + patch-key doc-comment), (2) reverse comparator
  (`_tmr_check_blob_h2_divergence` + the call hook + the `force` param + source-forward),
  (3) the run-loop rc-check. The new `description/context/resolution/file_symbol/raw_body`
  patch keys are REQUIRED to feed the composer (§3.LF.4 "call the C-4.5 blob-aware composer")
  — not extra surface. The ONE fixture-body edit (#43 BD-002 gains `## File / Symbol\n\n
  scripts/bar.sh`) is a REQUIRED lock-step correction, NOT an overstep: the fixture's blob
  (`FIX_BD002_RAWBODY`) carries `File/Symbol: scripts/bar.sh`, #43 is reconstructed via
  `tracker_migrate_reverse_run` (`:423`), and the new comparator would correctly abort that
  pre-existing test on the inconsistent stored body — so the fixture had to be made
  blob↔H2-consistent (matching what a real forward migration always emits) per
  `enumerate-encoding-surfaces`. No new flags/markers/helpers beyond the comparator + rc-check.

---

## FINDINGS

- **BLOCKER:** none.
- **MUST:** none.
- **SHOULD:** none.
- **NIT-1 (non-blocking, informational).** Test leg 2.1d-i (no-false-positive) PASSES even
  against the un-amended HEAD libs (no comparator ⇒ no abort ⇒ rc=0 trivially), so on its own
  it is not a teeth leg — it only proves the no-false-positive property in combination with
  the comparator being present (which 2.1d-ii/iii establish). The suite as a whole has teeth;
  this is a note on leg 2.1d-i's standalone discriminating power, not a defect. No fix
  required.
- **NIT-2 (non-blocking, informational; mirrors IMPL-REPORT CONCERNS #3).** The comparator
  re-parses the blob's `raw_body` via `_tmf_parse_backlog_file` on EVERY reverse. For a
  BD-167/169-style entry with an interior `## Sub-entry` H2, the projection fields close at
  the interior H2 (unchanged C-4.5 behavior) and the stored H2 was emitted from those same
  fields, so recompute == stored and no false-flag — confirmed indirectly by the green
  211-entry forward/roundtrip battery. Surfaced for completeness; no action.

---

## Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| `agents-never-commit` | Only read-only git (`rev-parse`, `status`, `diff`, `show`, `log`) + `grep`/`sed`/`bash <test>`/`python3 validate-pack`. No `git add/commit/push/tag`. The single write is this report. | COMPLIANT |
| `empirical-evidence-blocks` | Every invariant + concern + also-verify backed by an actual command/quoted-code measurement at HEAD `d578626`, 2026-06-07 (battery PASS=45 FAIL=0; teeth sandbox 4+5 fails vs HEAD libs; manifest `diff` UNCHANGED; `git status --short` = 4 files + report; comparator `norm()` quoted verbatim). | COMPLIANT |
| `verify-full-ci-suite` | Ran ALL 45 workflow `run: bash scripts/tests/*.sh` (enumerated via `grep -oE 'scripts/tests/[A-Za-z0-9._-]+\.sh' .github/workflows/validate-pack.yml`) + `validate-pack.py`, not a subset; `test-v11-realistic-ot.sh` included → ALL GREEN. | COMPLIANT |
| `enumerate-encoding-surfaces` | Verified the change updated the comparator + the sync + ALL encoding tests in lock-step (reverse-test 2.1d + the now-consistent #43 fixture; provider-test 4.7/4.7b); confirmed the #43 fixture correction was REQUIRED, not optional, by tracing `FIX_BD002_RAWBODY` → `tracker_migrate_reverse_run :423`. | COMPLIANT |
| `scope-deliverables-to-the-ask` | Delivered exactly: the 4 invariants + 2 concern adjudications + also-verify + verdict + this block + the read-in-full attestation, at the prompted report path. No extra surface; no second review pass proposed. | COMPLIANT |
| `boundary-investigation-precedes-pack-defaults` | Confirmed the change stays on pack-side libs/tests (`scripts/`); no `project-template/`/`supporting-docs/` touched; the composer is a shared pack-side lib reused under correct dependency direction (edit/reverse depend on forward — fine). | COMPLIANT |
| `rules-applied-verification-block` | This table present; each rule has quoted/measured evidence + a terminal COMPLIANT/N-A/VIOLATED (no empty cells, no AMBIGUOUS). | COMPLIANT |

---

## READ-IN-FULL attestation

Read in full this session: `PLAN-BD-204.md` §3.LF.4 (the C-3 amendment recipe) + §3.LF.9
(the full unattended battery list, the verify-full-ci-suite SSOT); `ARCHITECTURE-BD-204-
LOSSLESS-FIX.md` §3.3 (the verbatim-body blob + composer reused), §3.3a + §3.3a(ii) (the
blob↔H2 sync + the normalization-tolerant comparator), §7 R-EDIT / R-NORM / R-CLIENT (the
regression contract). Read the production code: `scripts/lib/tracker-edit.sh` (full diff +
context), `scripts/lib/tracker-migrate-reverse.sh` (diff + the reconstruct body `:560-606`,
the comparator `:702-830`, the run-loop `:1180-1400`), `scripts/lib/tracker-migrate-forward.sh`
(the composer `:811-846` + parser raw_body capture `:438-574` + `_tmf_neutralize_autolinks`).
Read the two edited test files in full (diffs + the fixture setup `:50-108`, 2.1c/2.1d
`:270-345`, provider 4.7/4.7b/4.8). Verified the IMPL-REPORT's claims against my own
measurements rather than trusting it. Memory rules in force read in CLAUDE.md `## Pack memory`:
`verify-full-ci-suite`, `regenerate-manifest-v11-surface`, `scope-deliverables-to-the-ask`,
`agent-output-rules-applied-block`, `enumerate-encoding-surfaces`,
`boundary-investigation-precedes-pack-defaults`.
