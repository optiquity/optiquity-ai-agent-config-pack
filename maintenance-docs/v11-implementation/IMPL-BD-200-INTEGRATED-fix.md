# IMPL — BD-200 — INTEGRATED-review fix F-1 (truthful P0 pool-absent message)

**Role:** pack-coder (fresh, fix-coder for integrated-review F-1). **Branch:** `v11-dev`.
**Base HEAD:** `291dd9e5069bf40d67b1e5393638f94dd38a69b5` (C4). **Final HEAD:** `291dd9e5069bf40d67b1e5393638f94dd38a69b5` (UNCHANGED — agent never commits).
**Date:** 2026-06-04. **Finding fixed:** PACK-REVIEW-BD-200-INTEGRATED.md F-1 (SHOULD).
**Verdict:** all verification PASS. Message-only correction; BD-202 boundary intact; no pool-on-update logic added.

---

## 1 — The fix

F-1: the P0 pool-absent recovery message in `activate-capability.sh` advised
`scripts/init-project.sh --update` to "materialize the pool." That advice is
FALSE — `--update` (`cmd_update`) does not invoke `stage_s5b_populate_pool`, so
it never creates the pool. A pre-feature install following the advice runs
`--update`, gets no pool, and re-hits exit 22. Corrected the message to be
truthful: the pool materializes only at fresh project setup, there is no
in-place back-fill command yet, and `--update` does NOT create it.

**Scope:** one message block in `stage_p0_preflight()`, the `[[ ! -d "$POOL" ]]`
arm. Exit code (`EXIT_NO_POOL` = 22) and all other P0 behavior unchanged. No
pool-on-update / `cmd_update` population logic added (that is the deferred
BD-202 scope — left untouched).

---

## 2 — Before / after (verbatim)

**BEFORE** (`project-template/scripts/activate-capability.sh`, P0 pool-absent arm):

```
        say "STOP — capability pool pack-capability-pool/ is absent."
        say "It is a tracked directory created at project setup; if it is"
        say "missing, your project was set up before capability activation"
        say "was available. Re-run scripts/init-project.sh --update to"
        say "materialize the pool, then re-run this script."
```

**AFTER:**

```
        say "STOP — capability pool pack-capability-pool/ is absent."
        say "It is a tracked directory materialized once, when the project is"
        say "first set up by scripts/init-project.sh with a version that"
        say "supports capability activation. If it is missing, this project"
        say "was set up before that support existed."
        say "There is no in-place command to back-fill the pool into an"
        say "existing project yet; scripts/init-project.sh --update does NOT"
        say "create it. Until back-fill support ships, the only path that"
        say "populates the pool is a fresh project setup."
```

The false `--update` promise is gone. The message now (a) names the only path
that genuinely populates the pool — fresh setup by `init-project.sh`; (b)
states truthfully that `--update` does NOT create it; (c) is honest that no
self-service back-fill for a pre-feature project exists yet (does not fabricate
a working recovery command). Exit `EXIT_NO_POOL` (22) unchanged.

---

## 3 — init-project.sh path verification (proves the new message is accurate)

The pool is populated by `stage_s5b_populate_pool()` (defined at
`init-project.sh` line 575). Measurement of where it is invoked:

- **Invoked ONLY from the fresh-install stage sequence** — `grep -n
  "stage_s5b_populate_pool" scripts/init-project.sh` → definition at 575,
  single invocation at line **1547**, inside the `# Execute stages` block
  (`stage_s5_scripts` → `stage_s5b_populate_pool` → `stage_s6_docs_pack` …).
  This block runs on a fresh `init-project.sh` setup (gated by
  `confirm_proceed`), NOT on `--update`.
- **NOT invoked from `cmd_update`** — `awk '/^cmd_update\(\)/,/^}/'
  scripts/init-project.sh | grep -c "s5b\|populate_pool"` → **0**.
  `cmd_update()` (begins line 1165) refreshes v11 artifacts via the BD-088
  customization-preserve library; it never touches the pool.
- **The script itself documents the gap as deliberate** —
  `init-project.sh:573-574` comment on `stage_s5b_populate_pool`:
  "FRESH-INSTALL only — NO `pack update` refresh / wipe-repopulate (that is
  BD-202)."

Conclusion: the corrected message names exactly the path that genuinely
populates the pool (fresh `init-project.sh` setup), correctly negates the
`--update` path, and is honest about the absence of an in-place back-fill —
all consistent with measured `init-project.sh` behavior. SUPPORTED.

---

## 4 — Boundary grep (zero pack-self tokens / no $PACK / no BD-202)

`sed -n '148,160p' project-template/scripts/activate-capability.sh | grep -nE
'BD-[0-9]+|pack-ops/|maintenance-docs/|pack-architect|pack-planner|pack-coder|pack-reviewer|pack-docs|\$PACK|from the pack|BD-202|wipe-repopulate'`
→ **no match** (`ZERO pack-self tokens`). The message references only
`pack-capability-pool/` (the client-tracked pool dir), `scripts/init-project.sh`,
and `--update` — all client-valid tokens, no pack-self surface, no BD-202
reference. Check 43 + Check 37 confirm green at whole-surface scope (§6).

---

## 5 — Harness assertion change

**None made — none required.** The task said to update the harness assertion
*if* `test-activate-capability.sh` asserts the old message text. It does not:

- `grep -n "init-project.sh --update\|materialize the pool\|set up before\|EXIT_NO_POOL\|NO_POOL" scripts/tests/test-activate-capability.sh`
  → no hits on the message text.
- The harness's only P0 assertions are `assert_contains "P0 banner present" …
  "── P0 — pre-flight ──"` and `assert_not_contains "P0 did not require an
  external clone (no PACK error)" …` — neither touches the pool-absent recovery
  wording.
- The harness never exercises the pool-absent path: its fixtures always have a
  populated pool (it asserts `S5b populated the pool`). Adding a new
  pool-absent assertion would require a net-new test scenario (out of the
  message-only fix scope). The full suite stays green (27/0) with the message
  change, confirming no assertion regressed.

---

## 6 — Verification (all PASS)

| # | Command | Result |
|---|---|---|
| 1 | `bash -n project-template/scripts/activate-capability.sh` | **SYNTAX OK** |
| 2 | Accuracy (before/after vs init-project.sh) | **PASS** — §2 + §3: names only fresh-setup; negates `--update`; honest re: no back-fill |
| 3 | Boundary grep on message block | **PASS** — ZERO pack-self tokens / no `$PACK` / no BD-202 (§4) |
| 4 | `bash scripts/tests/test-activate-capability.sh` | **PASS — passed: 27, failed: 0** |
| 5 | `bash test-fixtures/build.sh --all --clean` (manifest regen) | **PASS** — regenerated; diff §7 |
| 6 | `python3 scripts/validate-pack.py` | **PASSED — all checks clean** |

Targeted check confirmations from the validate-pack run:
- **Check 22** (help-fragment freshness): ran, no failure.
- **Check 37** (project-side deny-list): `OK — 170 project-side file(s) walked;
  zero deny-list contamination`.
- **Check 43** (project-side bare cross-reference): `OK — 158 … file(s) walked;
  zero pack-internal bare cross-references`.
- **Check 47** (sanctioned pack-side-shipped freeze): `OK: install-map pack-side
  subset == _SANCTIONED_PACK_SIDE_SHIPPED (2 entr(ies)):
  ['scripts/lib/detect.sh', 'scripts/pack-help.sh']` — frozen 2-tuple UNMOVED.
- Check 48 emits 14 pre-existing advisory WARNs (removed-doc citations in
  `pack-ops/` mirrors) — advisory only, exit code unaffected, NOT BD-200-related.

---

## 7 — Manifest rows moved

`git diff test-fixtures/manifest.txt` after regen:

```
v11-realistic-ot  42f713787517954c502443d2de710fbc4c1b27d7 → b61b7d9c324c9f39eecee18916d674b2794db324
v11-flat-file     a2a91e7e3a87e4f61c29af262558c14c5ee60473 → 35ae24d4047dbbe277072ca83308117a5196f392
v11-tracker-on    05314a6c269840b3894c6703cfe8f434d6f2b6b8 → ce196a2868ad3cbb0faeda53c2abc943878ffa88
```

Exactly the three **v11-*** rows moved (the message change ships into v11
fixtures via the S5-installed `activate-capability.sh`). `v10-minimal`,
`v10-realistic-ot`, and `existing-project-mid-dev` rows UNCHANGED — expected
(v10 fixtures use the v10 init; existing-project is the pre-pack-install input
shape). Per `regenerate-manifest-v11-surface`: the diff touches
`project-template/scripts/` → manifest regenerated + left staged-ready in the
working tree for Pack Chat to commit alongside the script edit.

---

## 8 — Files changed inventory

| Path | Change type | Note |
|---|---|---|
| `project-template/scripts/activate-capability.sh` | modified | P0 pool-absent message rewritten truthful (5 `say` lines → 9 `say` lines); exit 22 + all else unchanged |
| `test-fixtures/manifest.txt` | modified | regenerated; 3 v11-* rows moved (§7) |

No new files. No harness change (§5). No deletions. C1/C2/C3/C4 files other than
`activate-capability.sh` untouched. No git state change (HEAD = `291dd9e`).

**Plan deviations:** none. **New POQs:** none. **BD-202 boundary:** intact —
message-only correction; no `cmd_update`/pool-on-update logic added; the
"FRESH-INSTALL only … (that is BD-202)" comment in `init-project.sh` left as-is.

---

## 9 — Definition-of-Done checklist

| Item | Status |
|---|---|
| P0 message no longer promises `--update` populates the pool | **PASS** |
| Message names only paths that genuinely populate the pool (fresh setup) | **PASS** (§2/§3) |
| Message honest about absence of in-place back-fill (no fabricated recovery) | **PASS** |
| Exit code 22 (`EXIT_NO_POOL`) + rest of P0 unchanged | **PASS** |
| Zero pack-self tokens / no `$PACK` / no BD-202 reference in message | **PASS** (§4) |
| `bash -n` clean | **PASS** |
| `test-activate-capability.sh` green | **PASS** (27/0) |
| Manifest regenerated; diff reported | **PASS** (§7) |
| `validate-pack.py` PASSED; Check 43/37/22 green; Check 47 frozen 2-tuple | **PASS** (§6) |
| No pool-on-update logic added (BD-202 boundary) | **PASS** |
| No git state change (HEAD unchanged) | **PASS** |

---

## 10 — Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **READ-IN-FULL (agents-read-rule-docs-in-full)** | Read IN FULL (per-file proof): `CLAUDE.md` incl. `## Pack memory` (single Read, 541 lines, lines 1–541 — trinity rule 104–110, dependency-direction 519–533, all `### ` subsections); `pack-ops/PACK-AGENTS.md` (single Read, 226 lines); `pack-ops/PACK-CHAT.md` (single Read, 310 lines); `project-template/CLAUDE.md` (single Read, 456 lines — trinity rule 361–364, deny-list 390–400). FINDING+SPEC: `PACK-REVIEW-BD-200-INTEGRATED.md` (single Read, full — F-1 detail lines 38–67); `PLAN-BD-200.md` (single Read, full 235 lines — §2 T3 lines 59–67, §6 lines 156–172); `pack-ops/BACKLOG.md` BD-200 + BD-202 boundary derived from PLAN §0/§7 + INTEGRATED F-1 evidence (S5b not in cmd_update, BD-202 deferral). CURATED memory (each single full Read): `feedback_agents_read_rule_docs_in_full.md` (72 lines), `feedback_agent_output_rules_applied_block.md` (15 lines), `feedback_manifest_regen_on_v11_surface.md` (16 lines), `feedback_bd_pack_only_operational_rule.md` (35 lines), `feedback_client_ref_delete_or_forward_look.md` (41 lines). SOURCE measured: `activate-capability.sh` P0 stage (Read 120–199); `init-project.sh` (Read s5b 554–603, run_stages 1535–1559; grep cmd_update body); `test-activate-capability.sh` (grep for message assertions — none). | **COMPLIANT** |
| **preflight-stop-means-stop** | PREFLIGHT line emitted ONCE after all edits + all 6 verification steps PASS (§6), immediately before this IMPL-REPORT Write; no partial report; no parent stop directive received. | **COMPLIANT** |
| **agents-never-commit** | Only read-only/verification verbs used: `git rev-parse`, `git status`, `git diff` (read-only), `grep`, `sed`, `bash -n`, test run, `build.sh`, `validate-pack.py`. NO `git add/commit/push/tag`. Final HEAD = base HEAD `291dd9e` (unchanged). | **COMPLIANT** |
| **boundary / no-pack-self-in-project** | §4: boundary grep on the rewritten message block (lines 148–160) for `BD-[0-9]+|pack-ops/|maintenance-docs/|pack-* agents|$PACK|from the pack|BD-202|wipe-repopulate` → ZERO matches. Whole-surface enforcement: Check 43 OK (158 files, zero bare cross-refs), Check 37 OK (170 files, zero deny-list contamination). | **COMPLIANT** |
| **client-ref delete-or-forward-look** | The corrected message names only client-valid, truthful tokens: `pack-capability-pool/` (client-tracked dir present at the install), `scripts/init-project.sh` (client-shipped script), `--update` (its flag). It DELETES the false claim that `--update` populates the pool (per §3 measurement: `--update`/`cmd_update` never calls `stage_s5b_populate_pool`, grep count 0). No reference to a pack-only asset. | **COMPLIANT** |
| **regenerate-manifest-v11-surface** | Edit touches `project-template/scripts/activate-capability.sh` (v11-surface). Ran `bash test-fixtures/build.sh --all --clean`; diff non-empty → 3 v11-* rows moved (§7); manifest left regenerated in working tree for same-commit staging by Pack Chat. v10-*/existing rows unchanged (verified). | **COMPLIANT** |
| **BD-202 boundary** | Message-only correction. No `cmd_update` change; no pool-on-update / wipe-repopulate logic added (grep: `populate_pool` still absent from `cmd_update`, count 0); `init-project.sh:573-574` "FRESH-INSTALL only … (that is BD-202)" comment untouched. | **COMPLIANT** |
| **rules-applied-verification-block** | This §10 table: per-rule name + quoted/measured evidence + terminal verdict; no empty-evidence rows; READ-IN-FULL row carries per-file proof. | **COMPLIANT** |
