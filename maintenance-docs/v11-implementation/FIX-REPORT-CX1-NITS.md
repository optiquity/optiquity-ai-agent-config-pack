# FIX-REPORT — BD-221 CX1 two-NIT accuracy fixes

- **Regime:** isolated worktree, REUSED (subsequent RW agent in CX1's cycle; no new worktree).
- **Worktree:** `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-adcb03ef07394ff01`
- **Branch / HEAD:** HEAD == `c4beb8d3599027e589c212b4b7cd0fddf659b4f6` (matches expected `c4beb8d`).
- **Scope:** `pack-only`. Exactly the two NIT fixes from the CX1 review. No patch emitted; left UNCOMMITTED; awaiting post-review SendMessage.
- **PREFLIGHT line emitted:** `PREFLIGHT: 2/2 NIT fixes complete (NIT-1 comment, NIT-2 comment + disposition assertion); test-customization-preserve PASS; validate default+DEEP exit 0; full suite green; diff=6 CX1 files; about to Write report`

## Pre-flight worktree confirmation

- `pwd` = the named CX1 worktree (confirmed).
- `git rev-parse HEAD` = `c4beb8d3599027e589c212b4b7cd0fddf659b4f6` (== `c4beb8d`).
- `git status --short` showed all 6 uncommitted CX1 `scripts/` files, including
  `scripts/migrate-v10-to-v11.sh` and `scripts/tests/test-customization-preserve.sh`. State as expected — proceeded.

## Correctness basis (empirically verified before editing)

`scripts/lib/three-way.sh` `three_way_classify` is **presence-based when base
is absent** (no `cmp` on the base-absent legs):

- `new-file-in-pack` = base absent, **ours ABSENT**, theirs present.
- `project-shadows-new-pack` = base absent, **ours PRESENT**, theirs present.

`_cp_disposition_for` (customization-preserve.sh) maps `project-shadows-new-pack`
→ `_CP_DISP_NEEDS_RECONCILIATION` = `customization-detected-needs-reconciliation`,
and `_cp_strategy_text` routes that leg to the **sidecar** branch (writes a
`.pre-update` sidecar, copies theirs to dest). Probed directly:

```
# raw classifier (base="" ours present theirs present, differ):
project-shadows-new-pack
# recorded dispositions.tsv row for the 6.4 input shape:
col1(disp) = customization-detected-needs-reconciliation
col2(class) = pack-agent
col4(action) = sidecar   ; dest = "v11 pack coder body"
```

This is why NIT-2(b)'s new assertion targets the **raw classifier**
(`three_way_classify` returns `project-shadows-new-pack`) and NOT
`dispositions.tsv` col 1 (which records the mapped canonical token, so a col-1
== `project-shadows-new-pack` assertion would FAIL). The test already sources
`three-way.sh`, so `three_way_classify` is directly callable.

## NIT-1 — `scripts/migrate-v10-to-v11.sh` install-idempotence comment (~L379-381)

Comment-only; no code/behavior change.

**Before:**
```
    # _v10_to_v11_lift_gemini_customs_to_bundle step (runs after this, before
    # the .gemini/ retire). Idempotent: a re-run sees ours==theirs →
    # unchanged-pack, no-op. Runs before _v10_to_v11_retire_gemini (the
    # departing .gemini/ tree and this .agents-plugin/ surface are disjoint).
```

**After:**
```
    # _v10_to_v11_lift_gemini_customs_to_bundle step (runs after this, before
    # the .gemini/ retire). Re-run disposition: on a second pass `ours` is now
    # present (installed on the first pass) while base stays "", so
    # three_way_classify yields project-shadows-new-pack (NOT unchanged-pack —
    # that branch needs all three inputs present; with base="" the classifier
    # is presence-based and never reaches the cmp-driven no-op). That routes
    # through the conservative sidecar gate (needs-reconciliation). This is the
    # benign, never-reached case on a real single-shot net-new v10→v11
    # migration (which only ever sees the first pass = new-file-in-pack); it
    # belongs to the --update path's pre-existing-accepted domain. Runs before
    # _v10_to_v11_retire_gemini (the departing .gemini/ tree and this
    # .agents-plugin/ surface are disjoint).
```

The wrong `unchanged-pack` claim is removed; the accurate `project-shadows-new-pack`
disposition is named, with the "benign, never-reached on a real single-shot
net-new migration / `--update` pre-existing-accepted domain" framing.

## NIT-2 — `scripts/tests/test-customization-preserve.sh` case 6.4 (~L375-392)

(a) comment corrected `new-file-in-pack` → `project-shadows-new-pack`;
(b) added a disposition assertion (the raw classify result).

**Before (comment):**
```
# 6.4 BD-221: a bundle PACK agent SELF-CLASSIFIES to pack-agent and is
# REPLACE-IF-DIFFERENT (a config-pack bump updates pack agents). Base "" +
# ours present + theirs differs → new-file-in-pack on the net-new bundle
# surface → copy theirs (the v11 pack content) over the stale client copy.
```

**After (comment):**
```
# 6.4 BD-221: a bundle PACK agent SELF-CLASSIFIES to pack-agent. Base "" +
# ours present + theirs differs → project-shadows-new-pack on the net-new
# bundle surface (the classifier is presence-based when base="" — ours is
# present, so NOT new-file-in-pack, which requires ours absent). The
# project-shadows-new-pack leg routes through the conservative sidecar gate:
# dest receives theirs (the v11 pack content) and ours is preserved in a
# .pre-update sidecar; the recorded canonical disposition is
# customization-detected-needs-reconciliation.
```

**New assertion added (placed BEFORE `customization_preserve`, because the
sidecar leg overwrites `coder.md` (ours) in-place; classify must see the stale
ours):**
```
# Assert the raw classify result directly (dispositions.tsv col 1 records the
# mapped canonical token, not the classifier token).
assert_eq "6.4 classify = project-shadows-new-pack" \
    "project-shadows-new-pack" \
    "$(three_way_classify "" \
        "$T6/proj/.agents-plugin/optiquity-agents/agents/coder.md" \
        "$T6/theirs-coder.md")"
```

Pre-existing 6.4 assertions (`class = pack-agent`, `replaced with v11 content`)
are unchanged — behavior is untouched; the test is strengthened, not altered.

## Verification results (Section 2)

- `grep -n "unchanged-pack" scripts/migrate-v10-to-v11.sh` → only the corrected
  "NOT unchanged-pack" clarification at L381; wrong claim gone; `project-shadows-new-pack` present.
- `grep -n "new-file-in-pack" scripts/tests/test-customization-preserve.sh` → at
  6.4 only the corrected "NOT new-file-in-pack" clarification (L378); the
  unrelated case 2.5 reference (L163) untouched; `project-shadows-new-pack`
  present at L376/L379/L388-389 (comment + new assertion).
- `bash scripts/tests/test-customization-preserve.sh` → **Passed: 233 / Failed: 0; All tests passed.**
  New assertion line confirmed PASS: `PASS 6.4 classify = project-shadows-new-pack`
  (plus pre-existing `6.4 ... class = pack-agent`, `6.4 ... replaced with v11 content`).
- `python3 scripts/validate-pack.py` → **exit 0** ("PASSED — all checks clean").
- `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` → **exit 0** ("PASSED — all checks clean").
- Full wired CI suite (`.github/workflows/validate-pack.yml` — `ci-shard-plan.py
  --emit-matrix`, 72 wired tests across 4 shards, run exactly as the CI shard
  step does) → **OVERALL_WIRED_RC=0** (no FAIL lines), incl.
  `test-migrate-v10-to-v11.sh`, `test-persona-contracts.sh`,
  `test-customization-preserve.sh`. `ci-shard-plan.py --assert-coverage` → OK
  (union == wired KEEP set; pairwise-disjoint; fixture cohesion co-located).
- Fixtures built (`test-fixtures/build.sh --all --clean`, exit 0) for the
  fixture-dependent shard tests; committed manifest restored to HEAD via
  read-only `git show HEAD:test-fixtures/manifest.txt > test-fixtures/manifest.txt`
  (no `git checkout`) so the manifest stays OUT of the diff.

## `git diff --name-only` (final)

```
scripts/init-project.sh
scripts/lib/customization-preserve.sh
scripts/migrate-v10-to-v11.sh
scripts/persona-contracts/contract-migration.sh
scripts/tests/test-customization-preserve.sh
scripts/tests/test-migrate-v10-to-v11.sh
```

Exactly the 6 CX1 `scripts/` files — no new file. My deltas are inside
`migrate-v10-to-v11.sh` (NIT-1) and `test-customization-preserve.sh` (NIT-2),
both already among the 6. The other 4 CX1 files carry only their prior CX1
deltas (untouched by me). Manifest NOT in the diff. No untracked files.

## Plan deviations

None. Exactly NIT-1 + NIT-2 from the CX1 review; nothing else touched.

Implementation note (not a deviation): NIT-2(b)'s assertion targets the raw
`three_way_classify` result rather than `dispositions.tsv` col 1, because col 1
records the mapped canonical disposition (`customization-detected-needs-reconciliation`),
not the classifier token. Asserting the raw classifier is the faithful way to
prove "the classify for 6.4 IS `project-shadows-new-pack`" and is what makes
both the corrected comments accurate. Empirically verified above.

## New POQs

None.

## Definition-of-Done checklist

- NIT-1 comment corrected (`unchanged-pack` claim removed; `project-shadows-new-pack` named) — **PASS**
- NIT-2(a) comment corrected (`new-file-in-pack` → `project-shadows-new-pack`) — **PASS**
- NIT-2(b) disposition assertion added, mirrors existing `assert_eq` style — **PASS**
- `test-customization-preserve.sh` PASS incl. new assertion — **PASS**
- validate-pack default exit 0 — **PASS**
- validate-pack DEEP exit 0 — **PASS**
- Full wired CI suite green — **PASS**
- Diff = exactly the 6 CX1 `scripts/` files; manifest not in diff; no new file — **PASS**
- No code/behavior change (comment + new assertion only) — **PASS**
- No state-changing git verb run; left UNCOMMITTED; no patch emitted — **PASS**

## Files changed inventory

| Path | Change type | This-agent delta |
|---|---|---|
| `scripts/migrate-v10-to-v11.sh` | modified (CX1) | NIT-1 comment correction (~L379-389) |
| `scripts/tests/test-customization-preserve.sh` | modified (CX1) | NIT-2 comment correction + new classify assertion (case 6.4) |
| `scripts/init-project.sh` | modified (CX1) | none (prior CX1 deltas only) |
| `scripts/lib/customization-preserve.sh` | modified (CX1) | none (prior CX1 deltas only) |
| `scripts/persona-contracts/contract-migration.sh` | modified (CX1) | none (prior CX1 deltas only) |
| `scripts/tests/test-migrate-v10-to-v11.sh` | modified (CX1) | none (prior CX1 deltas only) |

## Rules-Applied Verification Block

| Rule | Evidence | Conclusion |
|---|---|---|
| agents-never-commit | No state-changing git verb run. Git verbs used: `git rev-parse HEAD`, `git status --short`, `git diff --name-only`, `git diff --stat`, `git show HEAD:test-fixtures/manifest.txt` (read-only). No add/commit/stage/apply/checkout. Left UNCOMMITTED; no patch emitted. | COMPLIANT |
| per-action-approval-sub-agents | Worktree state matched expectation (HEAD `c4beb8d`, 6 CX1 files present); no unexpected state, so no STOP needed. No destructive op performed. | COMPLIANT |
| preflight-stop-means-stop | Section 2 all-PASS verified, THEN emitted the single PREFLIGHT line, THEN wrote this report (Section 3 order honored). No partial report. | COMPLIANT |
| edit-in-place-not-full-rewrite | Two targeted `Edit` calls only (one per locus); no full rewrite. `git diff --stat` shows `migrate-v10-to-v11.sh` and `test-customization-preserve.sh` gained only comment + assertion lines; other 4 files untouched by me. | COMPLIANT |
| scope-deliverables-to-the-ask | Exactly NIT-1 + NIT-2. `git diff --name-only` = the 6 CX1 files; only 2 carry new deltas. No other locus, no manifest change, no new file. | COMPLIANT |
| verify-full-ci-suite | Ran the FULL wired battery via `ci-shard-plan.py --emit-matrix` (72 tests / 4 shards) exactly as CI's shard step does → `OVERALL_WIRED_RC=0`; `--assert-coverage` OK; incl. `test-migrate-v10-to-v11.sh`, `test-persona-contracts.sh`, `test-customization-preserve.sh`; plus validate-pack default + DEEP exit 0. | COMPLIANT |
| rules-applied-verification-block | This block. | COMPLIANT |
