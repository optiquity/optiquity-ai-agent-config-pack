# IMPL-REPORT — BD-204 C-7 fix-pass 1

Branch: `v11-dev` — HEAD `c30c8d56082a9466a1164c94925667592a5a31bf` (unchanged; no commits made).

## Fix-pass 1 (NIT-1)

**Finding (verbatim):** "DS-3 probes use `os.urandom` — outcome-deterministic but not
bit-reproducible for diagnosing a failed live DS-3b; a seeded PRNG is a zero-cost
improvement."

**Fix:** in `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh`, both DS-3 probe
payload generators (DS-3a over-budget, DS-3b near-budget) now use
`random.Random(0xBD204).randbytes(N)` instead of `os.urandom(N)`. The seed `0xBD204`
is a literal constant at each site with the one-line comment:
`# Seed 0xBD204 is FIXED so the probe payload is bit-reproducible for rehearsal diagnostics (NIT-1); PRNG output stays incompressible.`
Two targeted in-place edits (import swap `os` → `random` + the seeded call + the
comment line); no other line of the file touched. `os.urandom` occurrences after fix: 0.

### Files changed

| Path | Change type |
|---|---|
| `scripts/tests/tracker-bd204-lossless-roundtrip-test.sh` | modified (still untracked/new from C-7; 2 payload-gen sites edited, +2 comment lines, file 782 → 784 lines) |
| `maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-C-7-FIX1.md` | new (this report) |

No tracked file modified. `git status --short` after the edit shows the identical
pre-edit set (`M backlog/BD-204.md` pre-existing; the C-7 untracked set unchanged):

```
 M backlog/BD-204.md
?? maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-C-7.md
?? maintenance-docs/v11-implementation/PACK-REVIEW-BD-204-C-7.md
?? scripts/tests/fixtures/tracker-bd204-lossless/
?? scripts/tests/tracker-bd204-lossless-roundtrip-test.sh
```

### Verification

1. **Probe outcomes UNCHANGED** (standalone harness sourcing the same lib chain as
   the test, fixture `tracker.toml` as provider config):
   - DS-3a (seeded over-budget): `rc=1`, message
     `size-budget: entry BD-999 projected body 67607 bytes exceeds provider body limit 65536 (margin 2048); forward aborted — split the entry or raise the limit; the migrator NEVER truncates`
     — same exceeds-message shape the reviewer reproduced (byte count differs from
     the reviewer's 67554 only because the payload bytes differ; now fixed forever).
   - DS-3b (seeded near-budget): `rc=0`, `composed bytes=60892` (under the
     65536−2048 = 63488 budget) — the within-budget premise passes.
2. **Bit-reproducibility:** the 50000-byte payload generated twice →
   `sha256 e158cd4df76827aae148ee85cce0ae5b46068563ee86de4de6260596fa7706b7` both runs
   (identical length 66668 b64 chars). Incompressibility confirmed: gzip of the
   50000/45000 seeded PRNG bytes → 50038 / 45033 bytes (expands, does not compress).
3. **Unattended run** (`PACK_TRACKER_LIVE_GH` explicitly unset via `env -u`; never set):
   ```
   SKIP: live-GH oracle (set PACK_TRACKER_LIVE_GH=1 + gh auth to run)
   real 0m0.003s
   rc=0
   ```
4. **validate-pack:** `python3 scripts/validate-pack.py` → `PASSED — all checks clean`, rc=0.
5. **Full battery N/A — proven:** `grep -rn "tracker-bd204-lossless" .github/workflows/
   scripts/tests/*.sh | grep -v "^scripts/tests/tracker-bd204-lossless-roundtrip-test.sh"`
   → no output, rc=1 (zero invoking hits). The changed file is unreachable from any
   battery test; the battery ran green at this same tree state in the C-7 cycle.
6. **Structure preserved:** `bash -n` SYNTAX-OK; the `grep -n '^echo "──'` section map
   shows the same 13 leg headers before and after (lines after the DS-3 block shifted
   +2 from the two added comment lines; no header added/removed/renamed).

### Plan deviations

None. One finding, one fix, nothing else.

### New POQs

None.

### Out-of-scope observations

None surfaced.

### Boundary discipline check

No project-side file touched (the one edited file is pack-side:
`scripts/tests/`; this report is `maintenance-docs/`). No pack-only reference added
to any client-shipped surface. N/A beyond that.

### Definition of Done

| Item | Result |
|---|---|
| DS-3 payloads use a fixed-seed PRNG, literal seed + one-line why-comment | PASS |
| Probe outcomes unchanged (DS-3a rc=1 same message shape; DS-3b rc=0) | PASS |
| No other change; git status set identical; no tracked file modified | PASS |
| Unattended run: pinned SKIP line, rc=0; PACK_TRACKER_LIVE_GH never set | PASS |
| validate-pack.py green | PASS |
| Payload byte-identical across two runs (hash-verified) | PASS |
| Zero workflow wiring proven; full battery N/A on that evidence | PASS |
| Report at IMPL-REPORT-BD-204-C-7-FIX1.md; existing C-7 report/review untouched | PASS |

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|
| agents-never-commit | Only git commands run: `git rev-parse HEAD`, `git status --short` (read-only). HEAD before == after: `c30c8d56082a9466a1164c94925667592a5a31bf`. No add/commit/push/tag executed. | COMPLIANT |
| per-action-approval-sub-agents | Test run via `env -u PACK_TRACKER_LIVE_GH bash ...` → output `SKIP: live-GH oracle (set PACK_TRACKER_LIVE_GH=1 + gh auth to run)`, rc=0. No `gh` mutation run; PACK_TRACKER_LIVE_GH never set; only destructive op was `rm -rf` of my own `mktemp -d` probe dir. | COMPLIANT |
| preflight-stop-means-stop | Emitted exactly one line: `PREFLIGHT: 1/1 in-scope edits complete; verification PASS; HEAD c30c8d56082a9466a1164c94925667592a5a31bf; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-C-7-FIX1.md` — after all verification passed; no stop message received. | COMPLIANT |
| rules-applied-verification-block | This block; every row carries quoted command output as evidence. | COMPLIANT |
| edit-in-place-not-full-rewrite | Two `Edit` calls only (no `Write` on the test file). Section map before AND after: identical 13 `echo "── ... ──"` headers (`147/279/307/354/390/409/...` before → `147/279/307/354/390/409/494/555/587/658/681/766/780` after — DS-3-downstream lines +2 from the two added comment lines, zero headers changed). `grep -c 'os.urandom'` → `0`. | COMPLIANT |
| pack-repo-code-comment-deferrals | No deferral comment added. Added comments are explanatory only: `# Seed 0xBD204 is FIXED so the probe payload is bit-reproducible for rehearsal diagnostics (NIT-1); PRNG output stays incompressible.` `grep -n 'TODO\|FIXME'` on the diff: none added. | N/A: no deferral introduced |
| ci-check-runtime-compounding | Measured unattended runtime after the change: `real 0m0.003s` (the default-SKIP guard exits first); the file remains wired into zero CI workflows (grep rc=1, no invoking hit). | COMPLIANT |
