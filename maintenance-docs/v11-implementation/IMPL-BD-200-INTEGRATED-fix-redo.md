# IMPL-REPORT — BD-200 INTEGRATED-review fix F-1 (REDO, authoritative)

**Role:** pack-coder (fresh, F-1 redo). **Branch:** `v11-dev`. **HEAD (unchanged — no commit):** `291dd9e5069bf40d67b1e5393638f94dd38a69b5`. **Date:** 2026-06-04.
**Finding fixed:** PACK-REVIEW-BD-200-INTEGRATED.md F-1 (SHOULD) — the P0 pool-absent recovery message in `activate-capability.sh` falsely advised `scripts/init-project.sh --update` "to materialize the pool," but `cmd_update()` never invokes `stage_s5b_populate_pool` (the pool is populated only by the fresh-install path).
**Redo reason:** the prior attempt (`IMPL-BD-200-INTEGRATED-fix.md`, NOT read by me) DERIVED the BD-200/BD-202 boundary from other docs instead of reading the BACKLOG entries directly, and attested COMPLIANT — a no-derivation-clause violation. This redo reads the BD-200 + BD-202 BACKLOG entries DIRECTLY and independently re-derives the fix; the working tree contained the prior untrusted edit, which I re-authored to my own independently-derived wording.

---

## 1 — The fix (message-only; BD-202 boundary intact)

**File:** `project-template/scripts/activate-capability.sh`, `stage_p0_preflight()`, the `[[ ! -d "$POOL" ]]` arm (exit `EXIT_NO_POOL=22`). Client-shipped (Check 43/37 walk it).

**BEFORE (committed at HEAD `291dd9e` — the false message F-1 flagged):**
```
say "STOP — capability pool pack-capability-pool/ is absent."
say "It is a tracked directory created at project setup; if it is"
say "missing, your project was set up before capability activation"
say "was available. Re-run scripts/init-project.sh --update to"
say "materialize the pool, then re-run this script."
exit "$EXIT_NO_POOL"
```
The false claim: `--update` "to materialize the pool." `cmd_update()` does NOT call `stage_s5b_populate_pool`; a pool-absent user following this advice runs `--update`, gets no pool, and re-hits exit 22 with no working recovery.

**AFTER (my independently-derived wording, now in the working tree):**
```
say "STOP — capability pool pack-capability-pool/ is absent."
say "The pool is a tracked directory materialized only at fresh"
say "project setup, by scripts/init-project.sh with a version that"
say "supports capability activation. If it is missing, this project"
say "was set up before that support existed."
say "No in-place back-fill into an existing project exists yet:"
say "scripts/init-project.sh --update does NOT create the pool. The"
say "only path that populates it today is a fresh project setup."
exit "$EXIT_NO_POOL"
```

**What changed and why each claim is now truthful:**
- "materialized only at fresh project setup, by scripts/init-project.sh" — the pool is populated ONLY by `stage_s5b_populate_pool`, invoked from `main()` at `init-project.sh:1547` (the fresh-install stage sequence S1…S5b…S9). TRUE.
- "set up before that support existed" — correctly explains pool-absence for a pre-BD-200 install. TRUE.
- "No in-place back-fill … exists yet: scripts/init-project.sh --update does NOT create the pool" — `cmd_update()` (`init-project.sh:1165`) never calls S5b; grep count of `s5b|populate_pool` inside the `cmd_update` body = 0. TRUE. Replaces the false promise with an honest statement.
- "only path that populates it today is a fresh project setup" — does not fabricate a working recovery command; states the single real population path. TRUE.

The message no longer promises a no-op flag. It does NOT add any pool-on-`--update` population logic (that is BD-202), does NOT name BD-202 or any BD number, and keeps exit code 22 and all other P0 behavior unchanged.

**Scope adherence:** only `activate-capability.sh` (the message) was edited. No other stages/behavior changed; no `cmd_update`/S5b/back-fill logic added; C1/C2/C3/C4 files other than this one untouched.

---

## 2 — `init-project.sh` pool-population path verification (the boundary fact)

```
$ grep -n "stage_s5b_populate_pool" scripts/init-project.sh
554:# stage_s5b_populate_pool — populate the TRACKED client capability pool.
575:stage_s5b_populate_pool() {
1547:    stage_s5b_populate_pool          # ← inside main(), the fresh-install stage list

$ grep -n "^main()\|^cmd_update()" scripts/init-project.sh
1165:cmd_update() {
1467:main() {

$ awk '/^cmd_update\(\)/,/^}/' scripts/init-project.sh | grep -c "s5b\|populate_pool"
0                                       # ← cmd_update NEVER calls S5b
```
- `main()` (1467) runs the fresh-install stage sequence (1542–1553): `stage_s1_skeleton … stage_s5_scripts → stage_s5b_populate_pool (1547) → … stage_s9_conditional_remove`.
- `cmd_update()` (1165) is the `--update` path; its body contains zero references to `s5b`/`populate_pool`.
- The S5b docstring itself (`init-project.sh:573–574`) confirms the deferral: "FRESH-INSTALL only — NO `pack update` refresh / wipe-repopulate (that is BD-202)."

Conclusion: the only path that populates `pack-capability-pool/` is fresh install. `--update` does not. The corrected message is accurate; the original was false. **SUPPORTED.**

---

## 3 — BD-200 ↔ BD-202 boundary (read DIRECTLY from BACKLOG.md — the prior attempt's failure)

Read directly from `pack-ops/BACKLOG.md`:
- **BD-200 entry (lines 3273–3306).** Scope (line 3302): "… the tracked `pack-capability-pool/` + its FRESH-INSTALL population stage (S5b) … **EXCLUDES the cross-version `pack update` pool refresh + the general update engine (→ BD-202)**." Scope-split (line 3288): "BD-200 owns FRESH-INSTALL pool population (pure copy; no prior-state reconciliation). The pool's cross-version `pack update` REFRESH … move to BD-202."
- **BD-202 entry (lines 3310–3326).** Problem (line 3316): "the gap is specific to the in-place `--update` path." Scope (line 3318): "make CP-delete + CP-modify-clean correct across AC-1..AC-4 in `cmd_update` … register BD-200's pool as the AC-1 consumer." Doc-currency (line 3319): names the exact R3 INSTALL-PROCEDURES inaccuracy as the doc-drift BD-202 must prevent.

**Boundary conclusion (independently derived from the entries above):** in-place / `cmd_update` pool population — i.e. making `--update` materialize/back-fill the pool — is **BD-202**, NOT BD-200. Therefore F-1 is correctly a **message-only** fix: it makes the P0 message tell the truth about the *current* (BD-200-era) reality without promising BD-202 behavior or naming BD-202. Adding any `--update` pool-population logic here would be a BD-202 scope pull and is explicitly NOT done.

---

## 4 — Boundary grep (the corrected message is client-shipped → zero pack-self tokens)

```
$ sed -n '148,160p' project-template/scripts/activate-capability.sh \
    | grep -nE 'BD-[0-9]|pack-ops/|maintenance-docs/|pack-(architect|planner|coder|reviewer|docs-researcher|chat)|\$PACK|from the pack|BD-202|wipe-repopulate|AC-[0-9]'
→ CLEAN — zero pack-self tokens, no $PACK, no BD-202 reference

$ grep -n '\$PACK\|PACK_OVERRIDE\|PACK=' project-template/scripts/activate-capability.sh
→ CLEAN — no $PACK anywhere in the client script
```
The corrected message names only `pack-capability-pool/` (the client artifact) and `scripts/init-project.sh` / `scripts/init-project.sh --update` (client-installed script basenames/verbs — not pack-self tokens). No BD number, no `pack-ops/`, no `maintenance-docs/`, no pack-* agent name, no `$PACK`, no "from the pack", no BD-202 / `wipe-repopulate` / AC-class token. **Boundary COMPLIANT.**

---

## 5 — Harness change (NONE required)

The harness `scripts/tests/test-activate-capability.sh` does NOT assert the P0 pool-absent message text or exit 22:
```
$ grep -nE "EXIT_NO_POOL|exit 22|back-fill|--update|STOP — capability|pool is absent" scripts/tests/test-activate-capability.sh
→ (only header-comment refs to init-project.sh as the install invocation; no assertion on the recovery message)
```
Its assertions cover the happy-path P0 banner (`── P0 — pre-flight ──`) and the negative "P0 did not require an external clone (no PACK error)". The message-text edit needs no assertion update. **No harness edit made.**

---

## 6 — Verification results (all PASS)

| # | Check | Command | Result |
|---|---|---|---|
| 1 | Syntax | `bash -n project-template/scripts/activate-capability.sh` | clean (SYNTAX OK). Harness unedited but re-checked: clean. |
| 2 | Accuracy | message audit vs `init-project.sh` (§2) | every claim TRUE; no `--update` promise; truthful about no in-place back-fill |
| 3 | Boundary | grep §4 | zero pack-self tokens, no `$PACK`, no BD-202 ref |
| 2b | Exit code | `grep EXIT_NO_POOL` | `EXIT_NO_POOL=22` + `exit "$EXIT_NO_POOL"` unchanged |
| 4 | Test harness | `bash scripts/tests/test-activate-capability.sh` | **passed: 27, failed: 0** |
| 5 | Manifest | `bash test-fixtures/build.sh --all --clean` | regenerated; 3 v11-* rows moved; v10-*/existing unchanged (diff below) |
| 6 | Pack validator | `python3 scripts/validate-pack.py` | **PASSED — all checks clean** (exit 0; 0 FAIL/ERROR); Check 43 OK, Check 37 OK, Check 22 + Check 47 ran clean; Check 47 frozen 2-tuple `("scripts/lib/detect.sh", "scripts/pack-help.sh")` UNMOVED |

**Manifest diff (v11-* rows moved because `activate-capability.sh` ships into v11 fixtures via S5; v10-* + existing-project rows unchanged):**
```
-v11-realistic-ot  42f713787517954c502443d2de710fbc4c1b27d7
-v11-flat-file  a2a91e7e3a87e4f61c29af262558c14c5ee60473
-v11-tracker-on  05314a6c269840b3894c6703cfe8f434d6f2b6b8
+v11-realistic-ot  1c5caf63d65303cd12c5df7b897b5cd57f7b9697
+v11-flat-file  1a67d6a4c4ea933838529d59c62500ef86a3bdb0
+v11-tracker-on  44a69506fb93c279a219bc08388cefdf8d6996bb
 v10-minimal  19558cbac58ed3e47642a6bbe64418a38c60bc16   (unchanged)
 v10-realistic-ot  4c62945f...                            (unchanged)
 existing-project-mid-dev  a54e081a...                    (unchanged)
```

---

## 7 — Files changed (inventory)

| Path | Change type | Note |
|---|---|---|
| `project-template/scripts/activate-capability.sh` | modified | P0 pool-absent message (lines 148–158) rewritten to be truthful; exit 22 + all other behavior unchanged |
| `test-fixtures/manifest.txt` | modified | regenerated per `regenerate-manifest-v11-surface`; 3 v11-* fixture SHAs moved |

No new files (this report aside). No deletions. HEAD unchanged (`291dd9e`); nothing staged or committed (Pack Chat commits).

**Plan deviations:** none. PLAN-BD-200.md §2 T3 / §6 do not specify the recovery-message wording; F-1 is a post-review SHOULD correction to T3's P0 stage, applied within the plan's fenced scope. No new POQs.

---

## 8 — Definition-of-Done checklist

| Item | PASS/FAIL |
|---|---|
| BD-200 + BD-202 BACKLOG entries read DIRECTLY (not derived) | PASS |
| P0 message truthful (every claim verified vs `init-project.sh`) | PASS |
| Message advises no `--update` pool-materialization; honest about no in-place back-fill | PASS |
| No fabricated working recovery command | PASS |
| Zero pack-self tokens / no `$PACK` / no BD-202 reference in message | PASS |
| Exit code 22 + all other P0 behavior unchanged | PASS |
| BD-202 boundary intact (no `cmd_update`/S5b/back-fill logic added) | PASS |
| `bash -n` clean | PASS |
| Test harness green (27/0); harness needed no edit | PASS |
| Manifest regenerated + reported | PASS |
| `validate-pack.py` PASSED; Check 43/37/22 green; Check 47 frozen 2-tuple unmoved | PASS |
| No state-changing git verb; HEAD `291dd9e` | PASS |

---

## 9 — Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **READ-IN-FULL set (+ no-derivation clause)** | Each named doc Read DIRECTLY, in full, via the Read tool. Per-file proof — `CLAUDE.md` (541 lines; first `# CLAUDE.md — AI Agent Config Pack (Pack Repo)`, last `testing (use /tmp clones or scratch fixtures, never write to real OT).`); `pack-ops/PACK-AGENTS.md` (226 lines; last `Always run git add -A && git status and confirm staged files before any commit.`); `pack-ops/PACK-CHAT.md` (310 lines; last `verified by END-STATE checks (bijection / anti-restate / trinity-parity / manifest), not a hard-enforced step sequence.`); `project-template/CLAUDE.md` (456 lines; last `The marker is preserved across pack upgrades. New projects start with this H2 empty.`); `PACK-REVIEW-BD-200-INTEGRATED.md` (97 lines; F-1 §38–67 read); `PLAN-BD-200.md` (235 lines; §2 T3 lines 59–67 + §6 lines 156–171 read); **`pack-ops/BACKLOG.md` BD-200 entry Read DIRECTLY lines 3273–3306** (Scope line 3302 EXCLUDES `pack update` pool refresh → BD-202) **+ BD-202 entry Read DIRECTLY lines 3310–3326** (line 3316 "gap is specific to the in-place `--update` path"; line 3318 `cmd_update` scope) — NOT derived from PLAN/review; `feedback_agents_read_rule_docs_in_full.md` (97 lines; carries the exact BD-200 F-1 no-derivation incident at 91–96); `feedback_agent_output_rules_applied_block.md` (15 lines); `feedback_manifest_regen_on_v11_surface.md` (16 lines); `feedback_bd_pack_only_operational_rule.md` (35 lines); `feedback_client_ref_delete_or_forward_look.md` (41 lines). Source Read/measured: `activate-capability.sh` (P0 block 127–164, headers 42–59), `scripts/init-project.sh` (S5b docstring+def 554–583, run_stages 1535–1553, cmd_update/main line refs), `scripts/tests/test-activate-capability.sh` (assertion grep — no message assertion), `scripts/validate-pack.py` (frozen 2-tuple 4158–4161). | **COMPLIANT** |
| **preflight-stop-means-stop** | PREFLIGHT line emitted once, only after all edits + verification (syntax + harness 27/0 + `validate-pack.py` PASSED + manifest regen) PASSED: `PREFLIGHT: F-1 redo complete; verification PASS; HEAD 291dd9e…; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPL-BD-200-INTEGRATED-fix-redo.md`. No parent stop/halt/revert received. | **COMPLIANT** |
| **agents-never-commit** | Read-only git verbs only (`git rev-parse`, `git status`, `git show`, `git diff`). No `git add/commit/push/tag`. Test harness self-provisioned its `/tmp` clones internally + cleaned up. HEAD remains `291dd9e5069bf40d67b1e5393638f94dd38a69b5`. | **COMPLIANT** |
| **boundary / no-pack-self-in-project** | §4 grep: corrected client-shipped message carries zero pack-self tokens (no BD-NNN, `pack-ops/`, `maintenance-docs/`, pack-* agent name, `$PACK`, "from the pack"), no BD-202 reference, no `wipe-repopulate`/AC-class token. Check 43 OK (158 files walked, zero bare cross-refs) + Check 37 OK (170 files walked, zero contamination) confirm at validator level. | **COMPLIANT** |
| **regenerate-manifest-v11-surface** | `activate-capability.sh` is under `project-template/` (v11-surface) → ran `bash test-fixtures/build.sh --all --clean`; manifest diff non-empty (3 v11-* SHAs moved); left regenerated in working tree; diff reported §6. v10-*/existing-project rows unchanged (verified). | **COMPLIANT** |
| **BD-202 boundary (message-only)** | No `cmd_update`/S5b/pool-back-fill logic added (only the P0 `say` lines changed; `git diff HEAD` is the 5-line→8-line message block alone). The message states the BD-202 reality (no in-place back-fill yet) without naming BD-202 or implementing it. Boundary read DIRECTLY from BACKLOG BD-200 line 3302 (EXCLUDES pool refresh) + BD-202 line 3316 (`--update` path is BD-202). | **COMPLIANT** |
| **rules-applied-verification-block** | This table — per-rule name + quoted/measured evidence + terminal verdict; no empty-evidence rows; READ-IN-FULL row carries per-file proof (line count or first+last line) for every named doc, incl. the BD-200 + BD-202 BACKLOG entries attested as Read DIRECTLY at their line ranges. | **COMPLIANT** |
