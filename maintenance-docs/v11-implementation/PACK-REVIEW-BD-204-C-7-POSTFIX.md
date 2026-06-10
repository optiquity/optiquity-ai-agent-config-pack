# PACK-REVIEW — BD-204 C-7 POST-FIX (review pass 2)

- **Scope:** focused verification that the single approved NIT-1 fix (DS-3 `os.urandom` → seeded PRNG) landed correctly in `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` with zero collateral change. Not a re-review of C-7.
- **Branch/HEAD:** `v11-dev` @ `c30c8d56082a9466a1164c94925667592a5a31bf` (unchanged by this review; read-only pass).
- **Reviewer:** pack-reviewer, 2026-06-10. All evidence below reproduced with my own commands — nothing taken on trust from the fix-coder report.
- **Verdict: CLEAN** — 0 BLOCKER / 0 MUST / 0 SHOULD / 0 NIT. Two explanatory notes (§7), neither a defect of the fix.

## 1. Fix presence and correctness — PASS

`grep -n "os.urandom\|randbytes\|Random(" scripts/tests/tracker-bd204-lossless-roundtrip-test.sh`:

```
422:payload = base64.b64encode(random.Random(0xBD204).randbytes(50000)).decode("ascii")
442:payload = base64.b64encode(random.Random(0xBD204).randbytes(45000)).decode("ascii")
rc=0
```

- Zero `os.urandom` remaining in the file; the seeded generator is at BOTH DS-3 payload sites (DS-3a over-budget line 422; DS-3b near-budget line 442).
- Rationale comment present at each site (lines 421 and 441), identical one-liner: `# Seed 0xBD204 is FIXED so the probe payload is bit-reproducible for rehearsal diagnostics (NIT-1); PRNG output stays incompressible.`
- `import base64, random, sys` at both heredocs (lines 419, 437) — the `os` import is gone.
- Post-fix file: 784 lines (pre-fix 782 + the 2 comment lines), SHA-256 `1e355c996dc8ba210c4e7c9724b11ff74e5e8221059f87e9c8f480c2f3c50b1b`.

## 2. Bit-reproducibility — PASS

Generated each payload twice in-process (python, exact expressions from the file):

```
n=50000 run1_sha=4fa76318e547616e964feaba28cb0ee36ace85651d89102f565377797dd0956a
n=50000 run2_sha=4fa76318...  identical=True  b64_len=66668
n=45000 run1_sha=ea8c1e22934c21d38045a633863982ed7c4cdbb11b357e24346230cb7b2c7bdb
n=45000 run2_sha=ea8c1e22...  identical=True  b64_len=60000
```

File-level check: ran the full generator heredocs (extracted verbatim via `sed -n '418,425p'` / `'436,445p'` from the test file, no transcription) twice; both body files hash identical across runs (`over-budget-raw` sha `9662f66b8bbe…` both runs; `near-budget-raw` sha `85eac2fd3a5d…` both runs).

Reconciliation with the FIX1 report's quoted hash: `sha256(base64(Random(0xBD204).randbytes(50000)))` = `e158cd4df76827aae148ee85cce0ae5b46068563ee86de4de6260596fa7706b7` — exactly the FIX1 value (theirs is the b64 payload hash; mine above are the raw-bytes and whole-body hashes; all three reproducible).

## 3. Incompressibility + unchanged probe outcomes — PASS

- gzip of the seeded bytes EXPANDS, not shrinks: 50,000 → 50,038 bytes; 45,000 → 45,033 bytes. The payload remains incompressible — the over-budget premise holds.
- In-process probes (offline harness sourcing the same 11-lib chain as the test, fixture `tracker.toml` as `_TRACKER_PROVIDER_CONFIG_PATH`; confirmed `tracker_provider_gh_capabilities` is a static heredoc at `scripts/lib/tracker-provider-gh.sh:728` — `body.limit: 65536`, no network, no `gh` invocation):
  - **DS-3a (over-budget): rc=1**, message `size-budget: entry BD-999 projected body 67607 bytes exceeds provider body limit 65536 (margin 2048); forward aborted — split the entry or raise the limit; the migrator NEVER truncates` — the required exceeds-message shape, gate trips.
  - **DS-3b (near-budget): rc=0**, composed body 60,892 bytes < 63,488 budget (65536 − 2048) — within-budget premise passes.
- `_limit` capability read returned `65536`, matching the file's `assert_eq "DS-3: provider declares body limit" "65536"` (line 411).

## 4. Zero collateral change — PASS

- **Section/leg map unchanged:** `grep -n '^echo "──'` → 13 headers at lines 147 / 279 / 307 / 354 / 390 / 409 / 494 / 555 / 587 / 658 / 681 / 766 / 780 — same 13 headers, no add/remove/rename; everything after the DS-3 block shifted exactly +2.
- **Line count:** 784 = 782 + the two comment lines only.
- **Default-SKIP guard still first executable statement:** stripping comments/blanks from lines 1–65 leaves exactly `set -u` then the guard `if [[ -z "${PACK_TRACKER_LIVE_GH:-}" ]] || ! command -v gh … || ! gh auth status …` printing the byte-exact pinned line `SKIP: live-GH oracle (set PACK_TRACKER_LIVE_GH=1 + gh auth to run)` and `exit 0` (lines 54, 60–65).
- **No-repo-delete self-guard intact:** split-pattern `_FORBIDDEN="gh repo de""lete"` + `grep -q` + `die` at lines 101–105, unchanged.
- **Fixtures byte-untouched:** worktree hashes `8087a068818449aa…` (BACKLOG.md) and `a34f0c77b42700ca…` (tracker.toml) match the SHA-256 values pinned in `IMPL-REPORT-BD-204-C-7.md` §1 exactly.
- **Untracked set:** `git status --short` → `M backlog/BD-204.md` + 5 untracked paths: the same pre-fix untracked set (`IMPL-REPORT-BD-204-C-7.md`, `PACK-REVIEW-BD-204-C-7.md`, `scripts/tests/fixtures/tracker-bd204-lossless/`, `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh`) plus `IMPL-REPORT-BD-204-C-7-FIX1.md` (the fix report — intentional deliverable).
- **Tracked diff:** `git diff --name-only` → `backlog/BD-204.md` only; `git diff --cached --name-only` → empty. See Note N-1 (§7) — this modification is NOT fix-coder collateral.
- **No workflow wiring:** `grep -rn "tracker-bd204-lossless" .github/workflows/` → empty, rc=1.

## 5. Unattended safety re-check — PASS

`env -u PACK_TRACKER_LIVE_GH /usr/bin/time -p bash scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` (flag NEVER set; no `gh` mutation run anywhere in this review):

```
SKIP: live-GH oracle (set PACK_TRACKER_LIVE_GH=1 + gh auth to run)
real 0.00
user 0.00
sys 0.00
rc=0
```

Pinned SKIP line byte-exact; rc=0; trivial runtime. On the prompt's "unit legs pass" element: this file by design runs NO legs unattended — the default-SKIP guard is the first executable statement, so the whole file SKIPs; the unit-level legs' unattended homes are other, already-wired tests (`tracker-migrate-forward-test.sh` §2.8.x, `tracker-migrate-reverse-test.sh` §2.1b/§2.1d, the Check-49 per-check test — enumerated in the file header, lines 20–36). Those homes are provably unaffected by this fix: the only changed file is untracked, unreachable from any workflow (grep empty above), and no tracked file under `scripts/` or `.github/` differs from HEAD (`git diff --name-only` shows none) — the battery's inputs are byte-identical to the state in which it ran green during the C-7 cycle.

## 6. validate-pack — PASS

`/usr/bin/time -p python3 scripts/validate-pack.py` → `PASSED — all checks clean`, **real 1.40 s** (~baseline 1.3–1.5 s; no runtime regression).

## 7. Notes (no severity — surfaced for the record, not defects of the fix)

- **N-1 — `M backlog/BD-204.md` is Pack-Chat governance, not fix collateral.** The prompt's literal expectation "`git diff --name-only` vs HEAD empty" does not hold: `backlog/BD-204.md` is modified. The diff is a single added line — a dated note (`REHEARSAL-CONFIRMATION ITEM (dated note 2026-06-10, from the C-7 review OOS-1 — user-approved BLOCKED deferral to the §3.LF.10 rehearsal): …` re the forward re-run `provider_close` question). This is a pack-chat-only bookkeeping edit on the BD entry (the tracked-anchor for the C-7 review's OOS-1 deferral), and it appears verbatim in the fix-coder's quoted PRE-edit `git status` in `IMPL-REPORT-BD-204-C-7-FIX1.md` (lines 29–35) — i.e., it pre-dates the fix-coder's edits. The fix itself modified NO tracked file.
- **N-2 — `IMPL-REPORT-BD-204-C-7.md` Appendix A is now a pre-fix snapshot.** The C-7 base report's verbatim file appendix (and its §1 pinned sha `114dbf7d…`/782 lines) still shows the `os.urandom` form (lines 805, 824) and no longer matches the worktree file (`1e355c99…`/784 lines). This is acceptable by convention: IMPL-REPORTs are immutable point-in-time records, and `IMPL-REPORT-BD-204-C-7-FIX1.md` sitting beside it documents the exact delta (sites, comment text, 782→784), keeping the audit chain whole. Flagged only so nobody "re-applies from the appendix" and silently resurrects the pre-fix payload generators.
- **Method note:** the repo-wide `grep -rn "os.urandom"` sweep (for the encoding-surfaces rule) incidentally matched two lines inside `PACK-REVIEW-BD-204-C-7.md`. I did not Read that file (prior-review bias prohibition); only the path-level result is used in §"sweep" below, and every finding in this report was established from my own reproduction commands, all run before that grep returned.

## 8. Encoding-surfaces sweep (rule: enumerate-encoding-surfaces)

Surfaces that could encode the pre-fix state (`os.urandom` usage or the old payload bytes):

- Executable/assertion surfaces: `grep -rn "os.urandom" --include="*.sh" --include="*.py" --include="*.yml" scripts/ .github/ project-template/` → **zero hits** (rc=1). No validator, test, or workflow pins the old generator or its output.
- Repo-wide: residual `os.urandom` strings exist ONLY in `maintenance-docs/` historical records — `IMPL-REPORT-BD-204-C-7.md` (the verbatim pre-fix appendix, Note N-2), `PACK-REVIEW-BD-204-C-7.md` (the pass-1 record quoting the finding), `IMPL-REPORT-BD-204-C-7-FIX1.md` (quoting the finding it fixed). None are encoding surfaces (not executed, not asserted against).
- Seed constant: `grep -rln "0xBD204" . --exclude-dir=.git` → only the test file itself + the FIX1 report. No other surface depends on the seed value.
- Workflow wiring: `grep -rn "tracker-bd204-lossless" .github/workflows/` → empty.

## Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| agents-never-commit | Git verbs run this session, exhaustively: `git rev-parse HEAD`, `git status --short`, `git diff --name-only`, `git diff --cached --name-only`, `git diff backlog/BD-204.md`. All read-only. HEAD before == after: `c30c8d56082a9466a1164c94925667592a5a31bf`. No add/commit/push/tag/checkout executed. | COMPLIANT |
| per-action-approval-sub-agents | Unattended run executed as `env -u PACK_TRACKER_LIVE_GH /usr/bin/time -p bash scripts/tests/...` → output `SKIP: live-GH oracle (set PACK_TRACKER_LIVE_GH=1 + gh auth to run)`, rc=0. PACK_TRACKER_LIVE_GH never set; zero `gh` commands run (the only gh-adjacent action was grepping source for the string). Only destructive op: `rm -rf /tmp/bd204-postfix /tmp/bd204-postfix-probe.py` — my own scratch artifacts in /tmp, not repo files. No repo file edited except this report at the prompted path. | COMPLIANT |
| preflight-stop-means-stop | No stop/halt/revert message received from the parent at any point; all verification completed before this report was written. (Reviewer role — no PREFLIGHT line obligation; the halt clause is the binding part.) | COMPLIANT |
| rules-applied-verification-block | This block, in the `pack-ops/PACK-MEMORY-RATIONALE.md` § rules-applied-verification-block format (read in full at lines 206–233 this session); every row carries quoted command output. | COMPLIANT |
| ci-check-runtime-compounding | Measured unattended cost of the changed file: `real 0.00 / user 0.00 / sys 0.00`, rc=0 (SKIP guard exits first). Wired into zero workflows: `grep -rn "tracker-bd204-lossless" .github/workflows/` → empty, rc=1 — battery contribution is exactly zero. `validate-pack.py` measured `real 1.40` (~baseline). | COMPLIANT |
| enumerate-encoding-surfaces | §8 sweep: `grep -rn "os.urandom"` over scripts/ .github/ project-template/ (sh/py/yml) → 0 hits; repo-wide hits confined to maintenance-docs historical reports; `grep -rln "0xBD204"` → test file + FIX1 report only; workflow grep empty. No validator/test/CI surface encodes the pre-fix state. | COMPLIANT |
