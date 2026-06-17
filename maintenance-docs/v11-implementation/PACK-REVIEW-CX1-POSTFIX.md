# PACK-REVIEW-CX1-POSTFIX — BD-221 cluster, commit CX1 (post-fix tight confirmation)

**Reviewer role:** fresh post-fix reviewer (TIGHT confirmation of 2 NIT
accuracy fixes after a CLEAN full review). Read-only; no edits.
**Worktree:** `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-adcb03ef07394ff01`
**HEAD (parent of CX1):** `c4beb8d3599027e589c212b4b7cd0fddf659b4f6` (== `c4beb8d`) — CONFIRMED
**Date:** 2026-06-17
**Cycle position:** CX1's FINAL review pass. (If DIRTY, the bounded cycle
escalates to architect — no further fix-coder pass.)

---

## VERDICT: CLEAN — ready to patch + commit

The 2 NIT accuracy fixes are present, correct, and confined to their loci.
The gate (validate-pack shallow + deep, full 72-test wired CI battery) is
green with no new fail-lines. Scope is exactly the 6 CX1 `scripts/` files;
the manifest is correctly NOT in the diff. No collateral change.

---

## SECTION 0 — Worktree / HEAD / scope confirmation

| Check | Expected | Observed | Result |
|---|---|---|---|
| pwd | the named worktree | `…/.claude/worktrees/agent-adcb03ef07394ff01` | OK |
| `git rev-parse HEAD` | `c4beb8d` | `c4beb8d3599027e589c212b4b7cd0fddf659b4f6` | OK |
| `git status --short` | exactly 6 `scripts/` files modified | 6 ` M scripts/…` (see below) | OK |
| `git diff --stat` | 6 files | 6 files, +392/−88 | OK |

The 6 modified files:
```
 M scripts/init-project.sh
 M scripts/lib/customization-preserve.sh
 M scripts/migrate-v10-to-v11.sh
 M scripts/persona-contracts/contract-migration.sh
 M scripts/tests/test-customization-preserve.sh
 M scripts/tests/test-migrate-v10-to-v11.sh
```
All under top-level `scripts/`; uncommitted (working-tree CX1 content
based on parent c4beb8d). Confirmed — no STOP condition.

---

## SECTION 1 — The two NIT fixes

### NIT-1 — `scripts/migrate-v10-to-v11.sh` install-idempotence comment (~L379-389) — CONFIRMED

- `grep -n "unchanged-pack" scripts/migrate-v10-to-v11.sh` → **single hit at
  L381**, and it is INSIDE the corrected comment, reading:
  `three_way_classify yields project-shadows-new-pack (NOT unchanged-pack — that
  branch needs all three inputs present; with base="" the classifier is
  presence-based and never reaches the cmp-driven no-op).`
  The wrong "re-run → unchanged-pack" claim is gone; the comment now names
  `project-shadows-new-pack` and routes it through "the conservative sidecar
  gate (needs-reconciliation)", explicitly labeled the "benign, never-reached
  case on a real single-shot net-new v10→v11 migration."
- **Comment-only:** every changed line in the NIT-1 region of the CX1 diff is a
  `+` line beginning with `#` (pure comment). No executable/behavior change.
- **Technical accuracy verified against the classifier source**
  (`scripts/lib/three-way.sh`):
  - `unchanged-pack` is emitted only inside the all-three-present branch
    (`has_base=1 && has_ours=1 && has_theirs=1`, then cmp-equal) — matches the
    comment's "needs all three inputs present."
  - base="" (`has_base=0`) + ours present + theirs present reaches the
    presence-based branch → `project-shadows-new-pack`. Matches the corrected
    claim exactly.

### NIT-2 — `scripts/tests/test-customization-preserve.sh` case 6.4 — CONFIRMED

- The case-6.4 comment now reads `project-shadows-new-pack` (the prior
  `new-file-in-pack` mislabel is gone). The comment correctly explains the
  presence-based classification (base "" + ours present + theirs differs) and
  notes the recorded canonical disposition is
  `customization-detected-needs-reconciliation`.
- A NEW assertion is present:
  `assert_eq "6.4 classify = project-shadows-new-pack" "project-shadows-new-pack"
  "$(three_way_classify "" "$T6/proj/.agents-plugin/optiquity-agents/agents/coder.md" "$T6/theirs-coder.md")"`
- **Asserts the RAW classifier result — correct.** The test sources
  `three-way.sh` (L36) and the assertion calls `three_way_classify` directly
  with base="" + ours present + theirs differing. It does NOT assert the mapped
  `dispositions.tsv` col-1 token. An inline comment makes the distinction
  explicit: *"Assert the raw classify result directly (dispositions.tsv col 1
  records the mapped canonical token, not the classifier token)."* The separate
  pre-existing assertions check col-2 class (`pack-agent`) and the replaced body
  — neither incorrectly asserts col-1 == `project-shadows-new-pack`. This avoids
  the WRONG-assertion trap SECTION 1 flagged.
- `bash scripts/tests/test-customization-preserve.sh` → **233 passed, 0
  failed**, including the three case-6.4 PASS lines:
  - `PASS 6.4 classify = project-shadows-new-pack`  (the new assertion)
  - `PASS 6.4 bundle pack agent class = pack-agent`
  - `PASS 6.4 bundle pack agent replaced with v11 content`

---

## SECTION 2 — Gate + scope

### validate-pack

| Run | Exit | tail -1 |
|---|---|---|
| `python3 scripts/validate-pack.py` | 0 | `PASSED — all checks clean` |
| `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` | 0 | `PASSED — all checks clean` |

**No NEW fail-lines.** The only WARN/ADVISORY lines are pre-existing,
unrelated to CX1: JC-5 accurate-history citations to removed docs in
`changelog/v8.md`, `changelog/v9.md`, `backlog/BD-030/044/046/193.md` (all
explicitly "advisory only, NOT a gate failure"), and the OPTIONAL-FEATURES.md
line-count advisory. None of those files are in the CX1 diff — they are not
introduced by the fix.

### Full wired CI suite (verify-full-ci-suite)

- `ci-shard-plan.py --assert-coverage` → `OK: 72 wired KEEP test(s) across 4
  shard(s); union == wired_KEEP_set; pairwise-disjoint; fixture cohesion group
  co-located`.
- Built fixtures (`test-fixtures/build.sh --all --clean`, exit 0) for the
  fixture-dependent shard; the regenerated manifest was byte-identical to the
  committed one (it did NOT appear in `git status` afterward — committed
  manifest is current).
- Ran all **72** wired tests (the complete set the workflow's dynamic shard
  matrix executes). **PASSED=72, FAILED=0.** The driver's failure log is
  absent/empty; every wired log carries a pass/OK summary.
- Three logs initially flagged by a broad failure-keyword grep were verified
  FALSE POSITIVES (negative-path PASS lines / expected stderr from a
  deliberate negative-path git call):
  - `test-migrator-core.sh` → `19 passed, 0 failed`
  - `test-validate-pack-check-removed-doc-advisory.sh` → `PASS: 3 / FAIL: 0`
  - `test-validate-pack-checks-36-37-38.sh` → `PASS: 8 / FAIL: 0`
- The two SECTION-2 named tests both PASS:
  - `test-migrate-v10-to-v11.sh` → `All tests passed.` (exit 0)
  - `test-persona-contracts.sh` → `migration contract: 41 passed, 0 failed`
    (exit 0)
- Additional migration-family confirmation (all exit 0):
  `test-migrate-v10-to-v11-decompose.sh`, `-dry-run.sh`, `-gates.sh` → Failed: 0.

### Scope confinement

- The fix is content-confined to the 2 loci: the NIT-1 comment block in
  `migrate-v10-to-v11.sh` and the NIT-2 comment + new assertion in
  `test-customization-preserve.sh`. NIT-1 is comment-only (no code/behavior
  change); NIT-2 adds a test assertion only.
- The other 4 CX1 files (`init-project.sh`, `lib/customization-preserve.sh`,
  `persona-contracts/contract-migration.sh`, `tests/test-migrate-v10-to-v11.sh`)
  carry only their prior CX1 deltas. No behavior change is introduced by the
  fix-coder; the full migration + customization + persona-contract suites pass,
  confirming no functional regression.
- `git diff --name-only` = exactly the 6 CX1 `scripts/` files. **Manifest NOT
  in the diff** — correct: the manifest tracks shipped (`project-template/`)
  surfaces, not top-level `scripts/`; a scripts-only commit does not trigger
  the manifest-regen rule, and the committed manifest is already current
  (verified: regen produced no diff).

---

## SECTION 4 — Rules-Applied Verification Block

| Rule | Evidence | Conclusion |
|---|---|---|
| **agents-never-commit** | No state-changing git verb run. Only `git rev-parse`, `git status --short`, `git diff`, `git diff --name-only/--numstat/--stat` (all read-only). No add/commit/push/stage/etc. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Verified exactly the 2 NIT fixes (NIT-1 comment; NIT-2 comment + 1 new assertion) + the gate (validate-pack shallow/deep + full 72-test battery) + scope confinement. No coverage/edge-case sprawl beyond the ask. | COMPLIANT |
| **edit-in-place-not-full-rewrite** | NIT-1 = pure comment lines (all `+` `#` lines in the diff region) — targeted, no code touched. NIT-2 = targeted comment edit + a single new `assert_eq` block; no rewrite of case 6.4 or the file. No collateral change in the other 4 files (suites green). | COMPLIANT |
| **verify-full-ci-suite** | Ran the complete 72-test wired set from `ci-shard-plan.py --emit-matrix` (not validate-pack alone), including the changed `test-customization-preserve.sh` (233/0) and the integration migration tests (`test-migrate-v10-to-v11.sh`, `test-persona-contracts.sh` 41/0, decompose/dry-run/gates). PASSED=72, FAILED=0. validate-pack shallow + deep both exit 0. | COMPLIANT |
| **rules-applied-verification-block** | This block. | COMPLIANT |

---

## Bottom line

CX1 post-fix is **CLEAN**. Both NIT accuracy fixes are present, technically
correct against the classifier source, and confined to their loci with no
behavior change. The gate is green (validate-pack shallow + deep exit 0, full
72-test wired battery 72/0, no new fail-lines). Scope is exactly the 6 CX1
`scripts/` files; manifest correctly excluded. Ready to patch + commit.
