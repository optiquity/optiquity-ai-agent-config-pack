# ARCHITECTURE — BD-136 POQ-1 resolution (minimal-sidecar `[CONDITIONAL]` retirement on the v10→v11 migration path)

**Stage:** FRESH, independent pack-architect resolving POQ-1 (a design/plan gap surfaced during BD-136 C1 implementation). Did NOT author the original/reconciled design, nor the C1 code (`reconciliation-instance-independence`). Feeds → user design review → planner → C1-merger-change + C1b-migrator commits.
**Placement:** designed against the COMMITTED state in the MAIN checkout `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev`. Runtime-verified: `pwd` = that checkout, HEAD `fcc2f83`, tree clean (only untracked `pack-ops/dashboard-approvals/`). READ-ONLY: no edits, no state-changing git verb. Graph stale → grep/Read only.
**Inputs consumed:** the C1 IMPL-REPORT (POQ-1 §7 + isolation table), the C1 merger AS BUILT (`marker-preserve.sh` + `customization-preserve.sh` reroute, held worktree), `ARCHITECTURE-BD136.md` (the reconciled design — committed under its canonical name; M1 §2.1, two-regime merge, L-9), `DESIGN-DECISIONS-BD136.md` (O-3, O-8, the 9 decisions), `backlog/BD-136.md` (L-9 + P-6 + File/Symbol bullet 1), and the live migrator machinery (`migrate-v10-to-v11.sh`, `migrator-{core,stages,manifest}.sh`, `lib/migrate-v10-to-v11/apply.sh`, `three-way.sh`, `customization-preserve.sh`, both `test-migrate-v10-to-v11*.sh`). Every state-claim re-verified this session (EEBs in §6).
**Author note:** REFERENCE doc (design) — carries rationale + evidence by design (`operating-docs-no-history` governs live operating docs, not this design record).

**One-paragraph disposition.** POQ-1 is NOT a merger defect and NOT a plan-vs-design contradiction that requires weakening M1. The observed halt is the *intentional* BD-095 pause-before-S4 gate firing correctly on a sidecar the M1 hoist produced *spuriously*. The M1 hoist, as built, is BASE-blind: it fails loud on ANY `[CONDITIONAL]` heading in OURS — and every real v10 trinity carries `[CONDITIONAL]` (it is the v10 format), so M1 fires on the **non-customized** normal migration path where the correct outcome is a clean `pack-update-applied` (adopt THEIRS, no sidecar). The fix is a single, minimal refinement — make M1 **BASE-aware** (fire only when a `[CONDITIONAL]` section is *genuinely customized*, `base != ours`, or when BASE is absent). This makes the normal path produce NO sidecar → no pause → the whole install completes → all 72 + 4 migrator assertions go green — WITHOUT touching the pause gate (which is load-bearing and tested), WITHOUT a migrator pre-pass, and WITHOUT weakening M1's true target. The `[CONDITIONAL]` retirement the user wants is already delivered by *adopting the pack's own retired v11 trinity* (BD-136 Commit 3) — the migration does not need to retire anything itself.

---

## 1. The HALT — diagnosis + fix

### 1.1 WHERE + WHY the migrator stops after the trinity's `needs-reconciliation`

The halt is the **intentional BD-095 two-phase "pause-before-S4" gate**, not an incidental abort. It lives in the v10→v11 adapter's `--apply` wrapper, NOT in the framework stage sequencer.

**Trace (each hop quoted from live source at HEAD `fcc2f83`):**

1. **The manifest dispatch does NOT abort.** `_manifest_iterate` (`scripts/lib/migrator-manifest.sh:216-253`) loops over EVERY parsed row and dispatches each; `_manifest_dispatch_transform` calls `customization_preserve … >/dev/null` (`migrator-manifest.sh:295-296`) then unconditionally `return 0` (`:305`). `customization_preserve` on the trinity `needs-reconciliation` path records a disposition and returns 0 (the merger's `_mp_sidecar_conflict` → `_cp_record` → `return 0`). So the loop processes ALL 13 manifest rows + the sweeps; nothing aborts here. **The prompt's "aborts the manifest" framing is imprecise: the manifest fully dispatches; every row records a disposition.** What halts is the *post-dispatch install*.

2. **The `--apply` wrapper injects the pause between S3 and the post-dispatch install.** The tests invoke bare (`bash "$MIGRATE_SH" "$T"`) which routes → `migrate_v10_to_v11_apply_run` (`migrate-v10-to-v11.sh:1179`). That wrapper *re-defines* `migrator_post_dispatch_hook` so the conflict check runs FIRST (`apply.sh:361-370`):
   ```
   migrator_post_dispatch_hook() {
       migrate_v10_to_v11_apply_after_dispatch      # ← conflict check + PAUSE
       _v10_to_v11_orig_post_dispatch               # ← the REAL S4/S5 install work
       _v10_v11_apply_sentinel_mark … S4
       _v10_v11_apply_sentinel_mark … S5
   }
   ```
   `_v10_to_v11_orig_post_dispatch` is the snapshot of the adapter's original hook that installs HELP-FRAGMENT / ISSUE forms / the Antigravity bundle / net-new skills / groupings / decompose (`migrate-v10-to-v11.sh:139-176`).

3. **The pause fires on ANY `needs-reconciliation` sidecar and `exit 0`s BEFORE the install.** `migrate_v10_to_v11_apply_after_dispatch` (`apply.sh:221-272`) calls `_v10_v11_apply_collect_conflicts` (`apply.sh:180-202`), whose selector is:
   ```
   awk -F'\t' -v want="customization-detected-needs-reconciliation" \
       '$1 == want && $5 != "-" && $5 != "" { print $5 }' "$tsv" > "$paused"
   ```
   If ANY row matches (disposition == needs-reconciliation AND sidecar column non-empty), it writes `sentinels/stage-S3.paused`, prints the "── PAUSED ──" block, and `exit 0` (`apply.sh:270`). Because this exits *inside* the wrapped hook, `_v10_to_v11_orig_post_dispatch` never runs → HELP-FRAGMENT / skills / groupings / bundle / pm-help never install; the framework's `_stage_relocations`/`_stage_artifact_installs`/`_stage_report` (`migrator-core.sh:230-232`) never run either. Only the EXIT trap's best-effort report render (`migrator-core.sh:190-213`) fires — matching the C1 report's "rc=0; only S0/S6 run."

**Intentional, not incidental.** The adapter header documents it (`migrate-v10-to-v11.sh:56-58`: "`--apply` … Pauses cleanly before S4 if dispatch produces sidecars the user must reconcile"), and it is **load-bearing + tested**: the dry-run test's `prepare_paused` helper (`test-migrate-v10-to-v11-dry-run.sh:195-204`) deliberately injects a customization to *force* this pause, and Group 4/5 assert the resume flow off it. Removing the pause would REGRESS BD-095 and break those tests.

**Root cause of the *spurious* pause.** The pause is correct; the sidecar that triggered it is not. The C1 M1 hoist (`marker-preserve.sh:286-293`) fails loud on ANY `[CONDITIONAL]` heading in OURS regardless of BASE. Every real v10 trinity carries `## [CONDITIONAL] …` H2s (EEB-6), so M1 fires on the *non-customized* migration path — where the pre-BD-136 baseline correctly produced `pack-update-applied` (EEB-8: HEAD migrator test 66/0). The C1 isolation table pins it: full C1 = 42/72; C1 with ONLY Step-1 (`_mp_has_conditional_heading`) disabled = 66/0.

### 1.2 The FIX — do NOT touch the pause; stop M1 from firing spuriously

The minimal, correct change is a refinement of **M1's trigger** in `scripts/lib/marker-preserve.sh` (Step 1 of `marker_preserve_trinity`, currently at `:286-293`), NOT a change to `apply.sh` / the pause gate / the framework. Detailed in §3. Net effect:

- **Non-customized `[CONDITIONAL]` trinity (base == ours):** M1 does NOT fire → falls through to the Step-2 markerless fallback → `_cp_strategy_text "trinity"` → `three_way_classify(base, ours, theirs)` → `base==ours && ours!=theirs` → `pack-update-applied` → `cp theirs dest` (`customization-preserve.sh:294-298`). **No sidecar → no `needs-reconciliation` → no pause → S4/S5 run → the full install completes.**
- **Customized `[CONDITIONAL]` body (base != ours for a `[CONDITIONAL]` section):** M1 fires → sidecar + the L-9 keep/delete message → the BD-095 pause fires *correctly* (this is the reserved genuine-reconciliation case; the user resolves + `--resume`).
- **BASE absent (client `init --update`, or a regressed v11 project):** M1 fires (M-14's true target — unchanged).

**Why not "fix the halt" by decoupling the pause?** Two reasons. (a) The pause is *intentional* BD-095 behavior, tested by `prepare_paused` (Group 4/5) — decoupling regresses tested behavior and is out of BD-136 scope; it would affect ALL classes, not just trinity. (b) It is unnecessary: with the refined M1 the normal path never produces a sidecar, so the pause never fires on it. The genuine-reconciliation case *should* pause (the user steer itself says the customized `[CONDITIONAL]` case "needs human reconciliation" — which IS the pause). Whether to *additionally* decouple the pause so a genuine trinity reconciliation still lets the unrelated install proceed is surfaced as **OI-1** (recommendation: keep the pause).

---

## 2. Minimal-sidecar `[CONDITIONAL]` retirement (the user steer)

**User steer (binding):** a NORMAL v10→v11 migration produces NO trinity sidecar; `[CONDITIONAL]` is retired cleanly (bare H2 + the `<!-- OPTIONAL: keep this section … -->` hint, section preserved); M1 fail-loud / sidecar is reserved for a genuinely-CUSTOMIZED `[CONDITIONAL]` body.

### 2.1 The cleanest architecture — retirement is "adopt THEIRS," not a new migrator step

The retirement is **already delivered by BD-136 Commit 3 (pack-trinity `[CONDITIONAL]` retirement) + the merger's existing adopt-THEIRS path** — the migrator needs NO retirement code of its own.

- **BD-136 Commit 3** (already in the reconciled wave map, §5.1 / `ARCHITECTURE-BD136.md §4.4`; spec = `backlog/BD-136.md` File/Symbol bullet 1 + L-9) retires the PACK trinity's 5 `## [CONDITIONAL] X` H2s ×3 to **bare H2 + the `<!-- OPTIONAL: keep this section if your project targets <X>; delete the entire section if not applicable -->` hint, section preserved.** After Commit 3, THEIRS (the v11 pack trinity the migration copies) is `[CONDITIONAL]`-free and marker-model-conformant.
- On the **non-customized** migration path, `three_way_classify(base=v10, ours=v10, theirs=v11)` yields `pack-update-applied` (EEB-5) → `cp theirs dest` → the client's post-migration trinity **IS** THEIRS's retired shape. `[CONDITIONAL]` is gone, the OPTIONAL-hint sections are preserved, and **no sidecar is written** (the `pack-update-applied` arm records `action=copied`, no sidecar — `customization-preserve.sh:294-298`).

So "retire `[CONDITIONAL]` cleanly as part of migration, section preserved, no sidecar" = "adopt the pack's own retired canonical." The only thing standing between the non-customized path and that clean adopt is the C1 M1 hoist firing spuriously — which §3 removes.

### 2.2 Why NOT a migrator pre-pass, and why NOT teach the merger to retire-in-place

The prompt floats two candidate architectures; both are rejected on evidence.

- **REJECT: a migrator pre-pass that rewrites OURS (`## [CONDITIONAL] X` → `## X` + hint) before dispatch.** Rewriting OURS *breaks* `base == ours`: after the rewrite, `ours != base` (BASE is the untouched v10 tag, which still carries `[CONDITIONAL]`), so `three_way_classify` yields `merged-with-customization` or `real-merge-required` for the trinity — i.e. it manufactures a "customization" that is actually the migrator's own pre-pass edit. Best case it lands `merged-with-customization` only if the pre-pass produces THEIRS *byte-exact* (fragile: any drift → `real-merge-required` → the exact sidecar we are trying to avoid). It also adds an in-place OURS mutation with ordering/idempotency concerns. Strictly worse than adopt-THEIRS.
- **REJECT: teach the merger to retire-in-place.** Unnecessary. Adopting THEIRS already yields the retired shape; adding retire-in-place logic to `marker-preserve.sh` duplicates what `cp theirs dest` already does, and it would have to run on the client `init --update` path too (where a v11 trinity carrying `[CONDITIONAL]` is an ANOMALY that must fail loud, not be silently retired — see §3). Retire-in-place would blur that boundary.

### 2.3 Detecting a "customized `[CONDITIONAL]` body" — the migrator HAS the BASE (verified)

The reserved sidecar case (customized `[CONDITIONAL]` body) requires a BASE to distinguish "project edited this section" from "this is just the v10 default." The migrator supplies one for every `transform` row (EEB-4): `_manifest_dispatch_transform` calls `migrator_baseline_to_tmp "project-template/CLAUDE.md" "$base"` (`migrator-manifest.sh:275-284`), which runs `git -C "$PACK" show v10:project-template/CLAUDE.md > "$base"` (`migrator-core.sh:458-459`). Empirically the v10 blob resolves (EEB-4: `git show v10:project-template/CLAUDE.md` rc=0). So per-`[CONDITIONAL]`-section `base`-vs-`ours` comparison is available on the migrator path. On the client `init --update` path BASE is `""` (`init-project.sh` passes empty first positional — `ARCHITECTURE-BD136.md §1.4 EEB-R1a`), so the "BASE absent" branch of the refined M1 handles it (fail loud — M-14's true target).

### 2.4 Reconciliation with L-9 + P-6

- **L-9** (`backlog/BD-136.md`) says the migrator MUST treat a `[CONDITIONAL]` carryover as "kept-and-transitioned-to-Shape-B … or deleted." That fork is a HUMAN decision. This design *refines* L-9: the human keep-vs-delete decision applies ONLY to a **customized** `[CONDITIONAL]` section (where M1 fires → sidecar → the user follows P-6). A **non-customized** `[CONDITIONAL]` section needs no human decision — the migration auto-adopts the pack's retired canonical (bare H2 + OPTIONAL hint). This third disposition ("adopt pack retired canonical") is not spelled out in the current L-9 text, so a one-clause L-9 clarification is warranted — surfaced as **OI-2** (user sign-off; BD-spec edit).
- **P-6** (`backlog/BD-136.md`) is the PM-chat procedure for a `[CONDITIONAL]` H2 encountered at init/migration ("decide keep→rename+Shape-B, or delete"). It stays exactly as written and is the human's playbook when the sidecar+pause fires for a customized `[CONDITIONAL]` — no change.
- **O-3** ("V-7 fails on ANY `[CONDITIONAL]` literal in a trinity file") governs the **validator** (Check 91) on a **committed** file, and is unaffected: the pack's v11 trinity is `[CONDITIONAL]`-free after Commit 3 (Check 91 passes), and the migrator's runtime M1 is a different surface (a v10 file being migrated is not a committed v11 file). The prompt's own note flags this distinction; this design preserves it.

---

## 3. The refined M1 condition + M-test impact

### 3.1 The refinement (exact, `scripts/lib/marker-preserve.sh`)

**As built (M1, BASE-blind — the defect):**
```
# Step 1 (L-9 HOIST): _mp_has_conditional_heading fires on ANY [CONDITIONAL] in OURS
if _mp_has_conditional_heading "$ours"; then
    _mp_sidecar_conflict … "project trinity carries a '[CONDITIONAL]' heading — decide …"
    return 0
fi
```

**Refined (M1, BASE-aware, per `[CONDITIONAL]` section):**
```
# Step 1 (L-9 HOIST, BASE-aware): fire ONLY on an un-auto-retirable [CONDITIONAL].
#   - BASE absent            → cannot attribute → fail loud (client anomaly / M-14 target)
#   - BASE present + section  customized (base-body != ours-body) → fail loud (L-9 keep/delete)
#   - BASE present + section  NON-customized (base-body == ours-body) → do NOT fire on it
if _mp_conditional_needs_reconciliation "$base" "$ours"; then
    _mp_sidecar_conflict "$base" "$ours" "$theirs" "$rel" "$dest" \
        "project trinity carries a '[CONDITIONAL]' heading whose body you customized — decide: keep (rename + wrap Shape B, optionally renamed-from) or delete; the literal prefix must not remain"
    return 0
fi
```

**New helper `_mp_conditional_needs_reconciliation(base, ours)`** (returns 0 = fire):
1. Enumerate every `## `/`### ` heading in OURS carrying the literal `[CONDITIONAL]` (fence-aware) — the existing `_mp_has_conditional_heading` scan generalised to *emit the matching heading lines* instead of a boolean. If none → return 1 (do not fire).
2. If BASE is absent/empty → return 0 (fire — cannot attribute).
3. For each matched `[CONDITIONAL]` heading H: extract H's section body from BASE and from OURS via the existing `_mp_extract_section` (both are v10-format, so H matches byte-for-byte in both). If `base-section != ours-section` for ANY H → return 0 (fire; this specific optional section was customized).
4. Else (BASE present AND every matched section is byte-identical base-vs-ours) → return 1 (do not fire; the sections are the v10 default and will be cleanly adopted from THEIRS).

All O(lines): one fence-aware awk pass to list `[CONDITIONAL]` headings + one `_mp_extract_section` + `cmp` per matched heading (≤5 per trinity file). No whole-tree walk, no subprocess-per-entry (`ci-check-runtime-compounding` — though this is runtime merge code, the same cheapness bar applies). Reuses existing primitives (`_mp_extract_section`, the fence-aware heading scan); no new machinery.

**Boundary note (why this is safe on BOTH paths):**
- **Migrator path** (BASE = v10 tag, present): non-customized → M1 silent → Step-2 markerless fallback → `pack-update-applied` (adopt THEIRS). Customized `[CONDITIONAL]` body → M1 fires → sidecar. Customized *elsewhere* (a non-`[CONDITIONAL]` section) → M1 silent (its `[CONDITIONAL]` sections are pristine) → Step-2 fallback → `three_way_classify` → `real-merge-required` → sidecar with the *generic* message (correct — the customization is not in a `[CONDITIONAL]` section, so the L-9-specific message would mislead). No silent loss on any branch (L-8 upheld — see §6 EEB-8).
- **Client `init --update` path** (BASE = ""): any `[CONDITIONAL]` in a v11 trinity is an anomaly → BASE-absent branch → M1 fires → fail loud. Unchanged from as-built for its true target.

### 3.2 M-14's proof still holds; M-test changes

M-14 (the M1 guard) currently asserts "markerless `[CONDITIONAL]` OURS → fail loud via the Step-1 hoist" (2 legs, `test-marker-preserve-bd136.sh`). The refinement makes M1 BASE-conditional, so M-14 must be re-cast into three legs (all in the C1 merger test — pack-only, `scripts/tests/test-marker-preserve-bd136.sh`):

- **M-14a (BASE absent — the preserved true target).** Markerless `## [CONDITIONAL] X` OURS, `base=""` → fail loud with the L-9 message. This is M-14's original intent (a regressed v11 trinity / the client path). ASSERTION UNCHANGED in substance; just pin `base=""` explicitly.
- **M-14b (BASE present, customized body — the reserved case).** `base` present, OURS = base with the `## [CONDITIONAL] X` *body edited* → `_mp_conditional_needs_reconciliation` returns fire → `needs-reconciliation` sidecar + the L-9 message. NEW leg.
- **M-14c (BASE present, NON-customized — the new clean path).** `base` present, OURS == base (the `## [CONDITIONAL] X` body byte-identical to base), THEIRS = a `[CONDITIONAL]`-free canonical → M1 does NOT fire; the merge resolves to `pack-update-applied`/clean adopt of THEIRS, **no sidecar, no `[CONDITIONAL]` L-9 disposition**. NEW leg — this is the regression guard that would have caught POQ-1.

M-7 (markered `[CONDITIONAL]` → the hoist still reaches it) is unaffected: a markered OURS with a customized `[CONDITIONAL]` still fires; a markered OURS whose `[CONDITIONAL]` section is non-customized (base==ours) now correctly does not fire on the `[CONDITIONAL]` account (it proceeds into the graft as any Shape-A/B file would). If M-7's fixture relied on BASE-blind firing, re-pin it to a customized/`base=""` variant so its assertion stays true. No other M-leg (M-1..M-6, M-13, M-15, M-16) touches the `[CONDITIONAL]` trigger, so they are unaffected.

**Design-decision fidelity.** The refinement is intentional and property-fit (`design-discipline-challenge`, pack-boundary HIGH bar): it is the minimal predicate that (a) preserves M1's true purpose (fail loud on an un-attributable / customized `[CONDITIONAL]`), (b) reuses the reconciled design's own BASE-aware theme (Regime A already 3-ways the pack body where BASE exists — `ARCHITECTURE-BD136.md §1.2`), and (c) restores the pre-BD-136 baseline on the non-customized path (EEB-8). It does not weaken any other gate (L-1/L-4/L-6/L-10 unchanged) and does not touch O-3/O-8 or the 9 decisions.

---

## 4. Encoding-surface reconciliation + migrator-test changes

### 4.1 The missed surface (enumerate-encoding-surfaces)

The plan's §5 encoding-surface list (`PLAN-BD136-RECONCILED §5`; reconciled arch §5 test-plan) enumerated the merger + Check-19 + Check-91 + `test-customization-preserve-bd136.sh` surfaces but **OMITTED**:
- `scripts/tests/test-migrate-v10-to-v11.sh` — the end-to-end migrator fixture suite (asserts the full v11 artifact install).
- `scripts/tests/test-migrate-v10-to-v11-dry-run.sh` — the BD-095 dry-run/apply/resume mode suite (asserts the pause/complete branch).
- The **migration reconciliation flow** itself: `scripts/lib/migrate-v10-to-v11/apply.sh` (the pause-before-S4 gate) is the surface that ENCODES the migration's response to a trinity `needs-reconciliation`.

These three MUST be added to the BD-136 §5 encoding-surface list so the migrator behavior is never re-omitted (the omission is exactly what let POQ-1 through: the C1 coder correctly implemented M1, but no plan commit re-encoded the migrator's expected behavior). This is a plan/BD-spec bookkeeping change (pack-chat-only or planner-scoped), not code.

### 4.2 What the migrator tests assert AFTER the refined M1 (measured baseline → projected)

- **`test-migrate-v10-to-v11.sh`** — the fixture (`make_v10_target`, lines 30-61) seeds the trinity byte-for-byte from `git show v10:project-template/*.md`, so `base == ours` (non-customized). After the refined M1: M1 silent → `pack-update-applied` → adopt THEIRS → no trinity sidecar → no pause → S4/S5 run → HELP-FRAGMENT / issue forms / bundle / net-new skills / groupings all install. **All groups go green (projected 66/0, matching the HEAD baseline EEB-8; the C1-full 42/72 failures were exactly the S4/S5-skipped install assertions 2.4/2.5/2.5b/2.5c/2.7/2.8/2.9 + downstream 5.2).**
- **`test-migrate-v10-to-v11-dry-run.sh`** — the 4 failures were the `--apply`/bare-complete assertions the pause broke: `2.5 stage-S6.done` (pause exits before S6), `5.2 --resume rc!=0 (no pause to resume)` (M1 forced a pause where none was expected), `6.2 bare completes through S6`, and the paired S6 assertion. After the refined M1: the non-customized `--apply`/bare runs complete → `stage-S6.done` present, no `stage-S3.paused` → all 4 green (projected 70/0). **Crucially, Group 4 `prepare_paused` (lines 195-204) STILL pauses** — it injects a plain `## Project customization line` (a non-`[CONDITIONAL]` edit), which yields `base != ours` → `real-merge-required` → sidecar → pause, independent of M1. So the refined M1 does NOT break the resume-flow tests.

### 4.3 NEW assertions to add (assert the new behavior explicitly)

Additive, in a dedicated commit (C1b, §5). These lock the fix and cover the reserved case the suite currently has NO test for:

1. **`test-migrate-v10-to-v11.sh` — Group 2 lock (clean migration → no trinity sidecar):** after the existing non-customized migration, assert `[[ ! -f "$T/CLAUDE.md.v10-customized" && ! -f "$T/AGENTS.md.v10-customized" && ! -f "$T/GEMINI.md.v10-customized" ]]` AND `[[ ! -f "$T/.pack-migrate-v10-to-v11/sentinels/stage-S3.paused" ]]` (no pause). This is the POQ-1 regression guard at the migrator level.
2. **`test-migrate-v10-to-v11.sh` — NEW Group (customized `[CONDITIONAL]` body → sidecar + fail-loud + pause):** build a v10 target, then EDIT the body under one `## [CONDITIONAL] X` heading (e.g. append a line inside the `## [CONDITIONAL] iOS 26 / Xcode 26.3 platform features` section) and commit; run the migrator; assert (a) `CLAUDE.md.v10-customized` sidecar exists AND contains the customized line; (b) the report / dispositions.tsv records `customization-detected-needs-reconciliation` for the trinity; (c) the output/report carries the specific `[CONDITIONAL]` keep-vs-delete message (the L-9 message text); (d) `sentinels/stage-S3.paused` present (the BD-095 pause fired). This is the `declare-verify-backing` proof that the reserved case still fires end-to-end.
3. **`test-migrate-v10-to-v11-dry-run.sh` — optional parity:** a `prepare_paused`-style helper variant that forces the pause via a customized `[CONDITIONAL]` body (rather than a generic edit), asserting the same resume flow works off a `[CONDITIONAL]`-triggered pause.

### 4.4 Full encoding-surface set for the POQ-1 fix (lock-step)

| Surface | Change | Commit |
|---|---|---|
| `scripts/lib/marker-preserve.sh` | Refine Step 1 → BASE-aware `_mp_conditional_needs_reconciliation` | C1 (held worktree) |
| `scripts/tests/test-marker-preserve-bd136.sh` | M-14 → 3 legs (a/b/c); re-pin M-7 if BASE-blind-dependent | C1 (held worktree) |
| `scripts/tests/test-migrate-v10-to-v11.sh` | Group-2 lock (no sidecar / no pause) + NEW customized-`[CONDITIONAL]` group | C1b (new) |
| `scripts/tests/test-migrate-v10-to-v11-dry-run.sh` | (optional) `[CONDITIONAL]`-triggered pause parity | C1b (new) |
| BD-136 §5 encoding-surface list (`PLAN-BD136-RECONCILED` / `backlog/BD-136.md`) | Add the two migrator tests + the `apply.sh` reconciliation flow; add the L-9 non-customized-auto-adopt clarification (OI-2) | plan/BD-spec (pack-chat) |

No validator interacts with this fix (Check 91/V-7 is a committed-file check, unchanged), so `ci-guard-measure-then-bound` is N/A here — verified: the refined M1 is runtime merge code, not a CI guard.

---

## 5. Commit / scope plan

### 5.1 Two commits; O-8 + the 9 decisions untouched

- **C1 (MODIFY the held C1 worktree — pack-only).** Refine the M1 trigger in `scripts/lib/marker-preserve.sh` (Step 1 → `_mp_conditional_needs_reconciliation`, BASE-aware) and update the merger test `scripts/tests/test-marker-preserve-bd136.sh` (M-14 → 3 legs; re-pin M-7 if needed). `customization-preserve.sh` (the reroute) and the fixtures are UNCHANGED. This stays entirely within C1's existing 4-file scope — it is a refinement of one of C1's own files, not a scope expansion. **Reuse the held worktree** (`agent-a621503706ed6ec77`) per `sub-agent-isolation` (the first coder created it; the fix-coder reuses it — no new worktree).
- **C1b (NEW commit — pack-only).** Add the migrator-test assertions (`test-migrate-v10-to-v11.sh` Group-2 lock + NEW customized-`[CONDITIONAL]` group; optional `-dry-run.sh` parity). File-disjoint from C1 (no other commit touches `test-migrate-v10-to-v11*.sh`), so it can be a parallel wave-1 sibling of C1 in the rule-10 map — but it is GATED on C1 landing first because its non-customized assertions only pass once the refined M1 is in (`{C1} → {C1b}` serial by *behavioral* dependency, though file-disjoint).

**Wave placement (rule 10):** slot into the reconciled wave map (`ARCHITECTURE-BD136.md §5.1`) as: C1 stays Commit 1 (the merger); C1b is a new pack-only test commit gated on Commit 1, analogous to Commit 8 (the test suite) — it may run in the Wave-3 test/doc parallel band, after Commit 1. No file collision with Commits 2-9 (it touches only `test-migrate-v10-to-v11*.sh`, which none of them touch).

**Cross-BD:** none of the POQ-1 surfaces (`marker-preserve.sh`, `test-marker-preserve-bd136.sh`, `test-migrate-v10-to-v11*.sh`) collide with BD-236 (`singletons.py`/`core.py`/trinity) or BD-202 (`customization-preserve.sh` engine layer). The S-D serialize set is unchanged.

### 5.2 CI-green-at-every-boundary

- **After C1:** the merger test (`test-marker-preserve-bd136.sh`) is green (M-14 3 legs). The pre-existing migrator tests (`test-migrate-v10-to-v11*.sh`) go green **without being edited** — the refined M1 makes the non-customized migration adopt THEIRS + complete, which is exactly what those tests already assert (EEB-8 anchors this: HEAD/no-M1 = 66/0, and the refined M1 reproduces that on the non-customized path). `validate-pack` shallow+DEEP and `test-customization-preserve.sh` (243/0, Check 25) are unaffected (the reroute and the markerless fallback are unchanged). **CI green.**
- **After C1b:** additive assertions on top of already-green tests. **CI green.**

**Sequencing note (not a blocker):** between C1 landing and Commit 3 (pack-trinity retirement) landing, a non-customized migration adopts THEIRS which — until Commit 3 — still carries `[CONDITIONAL]`. So the *post-migration* trinity carries `[CONDITIONAL]` transiently. This breaks NO test (the migrator suite does not assert `[CONDITIONAL]`-absence in the migrated tree) and does NOT reach Check 91/V-7 (a committed-pack-file check that lands in Commit 4, gated on Commit 3 per S-B). Once Commit 3 lands, THEIRS is `[CONDITIONAL]`-free and the migrated trinity is too. The full BD-136 (Commits 1-9 + C1b) delivers the complete user steer; C1 alone delivers the halt fix + no-spurious-sidecar.

### 5.3 What is explicitly NOT changed

`scripts/lib/migrate-v10-to-v11/apply.sh` (the pause gate), `migrator-core.sh` (the stage sequencer), `migrator-manifest.sh` (the dispatch), `three-way.sh`, and `customization-preserve.sh` (the reroute + strategies) are ALL unchanged. The fix is one predicate in one function in `marker-preserve.sh` + tests. This is the minimal surface that resolves POQ-1.

---

## 6. Empirical-Evidence Blocks

**EEB-1 — the halt is the BD-095 pause gate (WHERE).** Cmd: `awk 'NR>=221 && NR<=272' scripts/lib/migrate-v10-to-v11/apply.sh`; `awk 'NR>=356 && NR<=370' …/apply.sh`. Output: `migrate_v10_to_v11_apply_after_dispatch` calls `_v10_v11_apply_collect_conflicts` then `exit 0` (`:270`) when conflicts exist; the wrapped `migrator_post_dispatch_hook` runs `migrate_v10_to_v11_apply_after_dispatch` BEFORE `_v10_to_v11_orig_post_dispatch` (`:364-366`). HEAD `fcc2f83`, 2026-07-29. Interpretation: on a `needs-reconciliation` sidecar, the wrapper exits before the S4/S5 install work. Conclusion: **SUPPORTED** — halt = intentional BD-095 pause-before-S4.

**EEB-2 — the manifest dispatch does NOT abort.** Cmd: `awk 'NR>=216 && NR<=253' scripts/lib/migrator-manifest.sh`; `awk 'NR>=288 && NR<=306' …/migrator-manifest.sh`. Output: `_manifest_iterate` for-loops all rows (`processed++`, no early break); `_manifest_dispatch_transform` ends `return 0` regardless of disposition. HEAD `fcc2f83`. Interpretation: every manifest row dispatches + records a disposition; the halt is downstream of dispatch. Conclusion: **SUPPORTED** — "aborts the manifest" is imprecise; the manifest completes.

**EEB-3 — the pause selector keys on `needs-reconciliation` + non-empty sidecar.** Cmd: `awk 'NR>=180 && NR<=202' scripts/lib/migrate-v10-to-v11/apply.sh`. Output: `awk -F'\t' -v want="customization-detected-needs-reconciliation" '$1 == want && $5 != "-" && $5 != "" { print $5 }'`; writes `stage-S3.paused` iff non-empty. HEAD `fcc2f83`. Interpretation: exactly one such row (the C1 trinity sidecar) is sufficient to pause. Conclusion: **SUPPORTED**.

**EEB-4 — the migrator HAS a real v10 BASE (verify-availability, not existence).** Cmd: `awk 'NR>=275 && NR<=284' scripts/lib/migrator-manifest.sh`; `awk 'NR>=444 && NR<=465' scripts/lib/migrator-core.sh`; `git show v10:project-template/CLAUDE.md | head -3; echo rc=$?`. Output: `base=$(mktemp); migrator_baseline_to_tmp "$pack_rel" "$base"` → `git -C "$PACK" show v10:$pack_rel > "$tmpfile"`; the probe printed the v10 CLAUDE.md head with `rc=0`; `git rev-parse --short v10` = `fa81704`. HEAD `fcc2f83`, 2026-07-29. Interpretation: a per-`[CONDITIONAL]`-section base-vs-ours comparison is actually available on the migrator path (not merely "a BASE parameter exists"). Conclusion: **SUPPORTED**.

**EEB-5 — `base==ours && ours!=theirs` → `pack-update-applied` (no sidecar).** Cmd: `awk 'NR>=68 && NR<=82' scripts/lib/three-way.sh`; `awk 'NR>=290 && NR<=298' scripts/lib/customization-preserve.sh`. Output: three-way.sh `base_eq_ours && !base_eq_theirs → echo "pack-update-applied"`; customization-preserve.sh `pack-update-applied) mkdir…; cp "$theirs" "$dest"; _cp_record … "copied"` (no sidecar). HEAD `fcc2f83`. Interpretation: the non-customized normal path adopts THEIRS with no sidecar once M1 stops firing. Conclusion: **SUPPORTED**.

**EEB-6 — every real v10 trinity carries `[CONDITIONAL]`; v11 HEAD still does (Commit 3 pending).** Cmd: `grep -nE '^#{2,3} .*\[CONDITIONAL\]' project-template/CLAUDE.md`; `git show v10:project-template/CLAUDE.md | grep -nE '^#{2,3} .*\[CONDITIONAL\]'`. Output: v11 HEAD CLAUDE.md has 5 `## [CONDITIONAL]` H2s (lines 59/81/85/89/346); v10 tag CLAUDE.md has 5 (lines 52/74/78/82/292); GEMINI/AGENTS symmetric. HEAD `fcc2f83`, 2026-07-29. Interpretation: (a) M1 fires on EVERY v10 trinity (the over-fire); (b) THEIRS is `[CONDITIONAL]`-free only AFTER BD-136 Commit 3 (the retirement is pending). Conclusion: **SUPPORTED**.

**EEB-7 — the tests invoke bare/`--apply` (pause active) and Group 4 RELIES on the pause.** Cmd: `grep -nE 'MIGRATE_SH|--apply|--dry-run' scripts/tests/test-migrate-v10-to-v11.sh scripts/tests/test-migrate-v10-to-v11-dry-run.sh`; `awk 'NR>=195 && NR<=204' …-dry-run.sh`. Output: `test-migrate-v10-to-v11.sh` calls `bash "$MIGRATE_SH" "$T"` (bare → apply wrapper); `-dry-run.sh` `prepare_paused` injects `## Project customization line` then `--apply` "pauses at S3 with conflicts. Exit code 0 (clean pause)." HEAD `fcc2f83`. Interpretation: the pause is exercised + asserted as designed behavior; removing it regresses Group 4/5. Conclusion: **SUPPORTED**.

**EEB-8 — the M1-disabled baseline is green (no sidecar on the non-customized path).** Cmd: `bash scripts/tests/test-migrate-v10-to-v11.sh` at HEAD `fcc2f83` (HEAD has NO M1 hoist — trinity routes through `_cp_strategy_text`, the M1-disabled equivalent). Output (this session, 2026-07-29): `Passed: 66  Failed: 0  All tests passed.` Interpretation: with the trinity taking the markerless/`three_way_classify` path (exactly what the refined M1 restores on the non-customized branch), the migrator suite is fully green and NO trinity sidecar is produced. The refined M1 is silent on `base==ours`, so it reproduces this path → projected 66/0. Corroborated by the C1 isolation table (C1 with Step-1 disabled = 66/0). Conclusion: **SUPPORTED** (baseline measured; post-fix state is a logic-projected reproduction of the measured baseline, not independently run — the refined M1 is not yet written).

**EEB-9 — L-8 (no silent loss) holds on every refined-M1 branch.** Cmd: case analysis over `three-way.sh:57-125` + `marker-preserve.sh:281-303`. Output/interpretation: non-customized (base==ours) → adopt THEIRS, client had no edits to lose; customized `[CONDITIONAL]` body → M1 fires → `_mp_sidecar_conflict` `cp "$ours" "$sidecar"` (preserved); customized elsewhere → `real-merge-required` → `_cp_strategy_text` sidecar (preserved); BASE absent → M1 fires → sidecar. No branch overwrites OR keeps silently. Conclusion: **SUPPORTED**.

---

## 7. Open items (context + options + recommendation)

Per `open-item-surfacing`, each carries context + my own options + an evidence/logic recommendation; none defers the work to a new BD (all resolve within BD-136 / v11.0).

**OI-1 — Keep the BD-095 pause for a genuinely-customized `[CONDITIONAL]`, or decouple so the unrelated install still completes? (the item-2 "make the install proceed" reading).**
*Context:* the prompt's item 2 says "a per-file needs-reconciliation MUST NOT abort the manifest; the rest of the install proceeds." The refined M1 satisfies that on the NORMAL path (no sidecar → no pause → install completes). But a genuinely-customized `[CONDITIONAL]` body still produces a sidecar → the BD-095 pause halts the unrelated HELP-FRAGMENT/skills/groupings install until `--resume`.
*Options:* (a) KEEP the pause — the customized case is exactly the "human reconciliation" the user steer reserves, and the pause IS that flow; it is intentional, pre-existing (BD-095), and tested (`prepare_paused`, Group 4/5). Blast radius: zero. (b) Decouple — make trinity (or all) `needs-reconciliation` non-blocking so S4/S5 install completes and the sidecar is a post-migration flag. Blast radius: changes BD-095 for ALL classes (or a trinity carve-out), regresses `prepare_paused`/Group 4/5, out of BD-136 scope.
*Recommendation:* **(a) KEEP the pause.** Evidence: the user steer itself calls the customized case one that "needs human reconciliation"; the pause is that reconciliation flow; the 72-failure symptom is fully resolved by the refined M1 without touching it (EEB-8); decoupling regresses tested BD-095 behavior. If the user *does* want the install to proceed on a genuine trinity reconciliation, that is a separate BD-095 change to scope explicitly — I do not recommend folding it into BD-136.

**OI-2 — L-9 spec text does not cover the non-customized auto-adopt disposition.**
*Context:* L-9 (`backlog/BD-136.md`) enumerates only "kept→Shape-B or deleted" for a `[CONDITIONAL]` carryover — a human decision. This design adds a third, silent disposition: a non-customized `[CONDITIONAL]` is auto-adopted from the pack's retired canonical (bare H2 + OPTIONAL hint), no human decision, no sidecar.
*Options:* (a) add a one-clause L-9 clarification ("a non-customized `[CONDITIONAL]` carryover — `base==ours` — is retired by adopting the pack's `[CONDITIONAL]`-free canonical, no sidecar; the keep-vs-delete decision applies only to a customized `[CONDITIONAL]` body"). (b) leave L-9 as-is (behavior correct; spec narrow). 
*Recommendation:* **(a).** It is a BD-spec (pack-chat-only) edit needing user sign-off; keeping the spec and the code in agreement (`fail-loud-delete-old-source` spirit — no stale contract) is cheap and prevents a future actor re-reading L-9 and "restoring" the BASE-blind M1.

**OI-3 — M1 granularity: per-`[CONDITIONAL]`-section vs whole-file base-vs-ours.**
*Context:* the refined M1 can compare each `[CONDITIONAL]` section's body (per-section) or the whole trinity (whole-file) to decide firing. Both fix the halt (both leave the non-customized `base==ours` case silent). Per-section fires the L-9-specific message ONLY when a `[CONDITIONAL]` section is itself edited; whole-file fires it whenever the trinity is customized anywhere.
*Options:* (a) per-section (recommended in §3.1) — the L-9 keep-vs-delete message is accurate (it only appears when a `[CONDITIONAL]` section is the customized one); a customization elsewhere gets the generic `real-merge-required` message. (b) whole-file — simpler (one `cmp base ours`), but the L-9 message can fire for a non-`[CONDITIONAL]` customization, mildly misleading (though not unsafe — the file does still carry `[CONDITIONAL]` H2s the user must handle during reconciliation).
*Recommendation:* **(a) per-section** — message precision matters for a user staring at a paused migration; the extra cost is ≤5 `_mp_extract_section`+`cmp` calls, negligible. (b) is an acceptable fallback if the coder finds section extraction fragile against an odd heading; either way the halt is fixed and no silent loss occurs.

**OI-4 — Fold the migrator-test additions into C1, or ship as a separate C1b?**
*Context:* the M1 refinement lives in `marker-preserve.sh` (+ its merger test); the new migrator-test assertions live in `test-migrate-v10-to-v11*.sh` (a different surface).
*Options:* (a) separate C1b (recommended) — file-disjoint, clean CI boundary, keeps C1 within its original 4-file scope. (b) fold into C1 — one fewer commit, but expands C1's file set beyond its scoped 4.
*Recommendation:* **(a) separate C1b.** Evidence: `enumerate-encoding-surfaces` wants the migrator tests brought in lock-step, but the wave map's file-disjointness discipline is best served by a dedicated pack-only test commit gated on C1. Low stakes; the planner may overrule on batching grounds.

**No open item is deferred to a new BD.** OI-1 and OI-2 carry decisions the user owns (a BD-095-scope question and a BD-spec clarification); OI-3/OI-4 are design-detail calls the planner/coder may settle.

---

## 8. Rules-Applied Verification Block

- **empirical-evidence-blocks** — Evidence: §6 EEB-1..EEB-9, each with the command run, quoted output, HEAD `fcc2f83`/2026-07-29, interpretation, conclusion; the load-bearing state-claims (halt location, migrator BASE availability, `base==ours → pack-update-applied`, v10/v11 `[CONDITIONAL]` counts, the M1-disabled 66/0 baseline) are each backed. The single projected claim ("no sidecar on the normal path after the fix") is explicitly marked as a logic-projection of the measured baseline (EEB-8), not an independent run. Conclusion: **COMPLIANT**.
- **no-deferral-without-user-direction** — Evidence: the entire fix lands in BD-136 / v11.0 (C1 merger change + C1b migrator tests); nothing is pushed to BD-202/BD-236/a new BD. OI-1/OI-2 are surfaced for the user gate, not deferred. Conclusion: **COMPLIANT**.
- **dependency-direction-placement / P-missed-7 / filename-uniqueness-heuristic** — Evidence: the fix is pack-side runtime merge code (`marker-preserve.sh`) + pack-side tests; the `[CONDITIONAL]` retirement stays the pack's own trinity edit (Commit 3, product surface) adopted by the migrator (pack-side); no dual-use, no client-shipped file touched, no `_SANCTIONED_PACK_SIDE_SHIPPED` growth; no new filenames introduced (`_mp_conditional_needs_reconciliation` is a new *function*, uniquely named, inside an existing file). Conclusion: **COMPLIANT**.
- **enumerate-encoding-surfaces** — Evidence: §4 lists the missed surfaces (`test-migrate-v10-to-v11.sh`, `-dry-run.sh`, the `apply.sh` reconciliation flow) and brings them in lock-step (§4.4 table), and adds them to the BD-136 §5 encoding list so the omission cannot recur. Conclusion: **COMPLIANT**.
- **ci-guard-measure-then-bound** — Evidence: N/A — the refined M1 is runtime merge code, not a CI guard/validator/allowlist; no guard's matching logic is added or changed (Check 91/V-7 unchanged). Verified the fix touches no `validate_checks/` file. Conclusion: **N/A (no CI guard interacts)**.
- **ci-check-runtime-compounding** — Evidence: `_mp_conditional_needs_reconciliation` is O(lines) — one fence-aware awk heading scan + ≤5 `_mp_extract_section`+`cmp` per trinity file; no whole-tree walk, no subprocess-per-entry. Conclusion: **COMPLIANT**.
- **fail-loud-delete-old-source** — Evidence: the refinement replaces the BASE-blind Step-1 predicate in place (no half-state — the old `_mp_has_conditional_heading`-as-boolean is generalised, not left dangling); OI-2 recommends reconciling the L-9 spec text so no stale contract survives. Conclusion: **COMPLIANT**.
- **design-discipline-challenge / verify-availability-not-existence** — Evidence: the BASE-aware predicate was held to the pack-boundary HIGH bar (§3.2 property-fit); the design depends on the migrator having a real v10 BASE, which was VERIFIED usable (EEB-4: `git show v10:… rc=0` + the `migrator_baseline_to_tmp` path), not merely assumed to exist. Conclusion: **COMPLIANT**.
- **memory-not-an-ssot** — Evidence: every rule + state-claim was sourced this session from the live in-repo SSOT (`CLAUDE.md ## Pack memory`, `backlog/BD-136.md`, the merger/migrator libs, both tests read at HEAD) + the caller-named handoff docs; no memory cache. Conclusion: **COMPLIANT**.
- **open-item-surfacing** — Evidence: §7 OI-1..OI-4 each carry context + own options + an evidence/logic recommendation; none defers to a new BD. Conclusion: **COMPLIANT**.
- **agents-never-commit / per-action-approval-sub-agents** — Evidence: only read-only git (`rev-parse`, `status --porcelain`, `show v10:…`, `merge-base`-free reads) + grep/awk/Read + one read-only test run (`test-migrate-v10-to-v11.sh`, which self-provisions its own `mktemp` targets and reads the repo read-only); all Writes confined to the single caller-specified report under the owned handoff dir; no repo edit, no state-changing git verb, no destructive op outside the owned dir / OS temp. Conclusion: **COMPLIANT**.
- **rules-applied-verification-block** — Evidence: this block. Conclusion: **COMPLIANT**.

*End ARCHITECTURE-BD136-POQ1.md*
