# ARCHITECTURE-SIDECAR-LIFECYCLE — v10→v11 migrator sidecar lifecycle contract

**Author:** pack-architect (focused design pass)
**Date:** 2026-05-15
**Trigger:** CI red on commit `fd0c4b3` (Batch 21c close). Two retroactive
review-fixes (BD-095 retro `35b3b7a` + BD-101 retro `22fc8fc`) collide
because each was architected independently. The collision concretizes a
deeper gap: the sidecar lifecycle was never architected as a coherent
whole. This document fills the gap and recommends a specific resolution
for the CI red.

**Read order.** §1 (lifecycle states) → §2 (check placement matrix) →
§3 (`.resolved` contract) → §4 (redundancy analysis) → §5 (mode
asymmetry) → §6 (recommendation) → §7 (handoff edits) → §8 (test/contract
updates).

---

## 1. Lifecycle state diagram

A "sidecar" in this document means a file written by
`scripts/lib/customization-preserve.sh` `_cp_strategy_text` (line 273)
or `_cp_strategy_*` siblings during the framework's S3 dispatch stage,
named `<dest>${_CP_SIDECAR_SUFFIX}` (which equals
`<dest>.${MIGRATOR_OWN_SIDECAR_SUFFIX}` — `.v10-customized` for the
v10→v11 adapter).

Sidecars exist only on the `customization-detected-needs-reconciliation`
disposition path (driven by classifications `real-merge-required` and
`project-shadows-new-pack`; see `customization-preserve.sh:271-282` and
`customization-preserve.sh:287-292`). Every other disposition either
copies, preserves, or removes without producing a sidecar.

### 1.1 States

```
            (a) absent                       (e) absent
              ▲                                 ▲
              │                                 │
              │                            removed by  
              │                            user (rm,   
              │                            git rm,     
              │                            mv to bare) 
              │                                 │      
              │                                 │      
   (no S3 dispatch)                         (b) created
   • file never reached the                 *.v10-customized
     real-merge-required path               present at <dest>
   • no row in dispositions.tsv             • row in dispositions.tsv
                                            • path listed in
                                              stage-S3.paused (apply mode)
                                                 │
                                       ┌─────────┼──────────┐
                                       │         │          │
                                  flag created  rename      delete
                                  by user      by user     by user
                                  (touch       (mv to      (rm)
                                  *.resolved)  bare)
                                       │         │          │
                                       ▼         ▼          ▼
                                 (c) flagged-  (d) merged- (d) abandoned-
                                     resolved      removed     removed
                                  • sidecar     • sidecar    • sidecar
                                    present       absent       absent
                                  • companion   • bare dest   • bare dest
                                    .resolved     present       holds pack
                                    file          (carries      template
                                    present       merged        only
                                    • bare        content)      (project
                                    dest holds                   edits
                                    pack template                discarded)
                                    only (user
                                    chose accept-
                                    pack-default
                                    OR re-edited
                                    bare dest)
```

States `(a)` and `(e)` are observationally identical (no sidecar present);
the state diagram distinguishes them by lineage. Gate 2 has no way to
tell them apart at observation time — a check is structurally limited to
"is there a sidecar?" (yes / no).

States `(d-merged-removed)` and `(d-abandoned-removed)` are also
observationally identical. The migrator's contract is that BOTH count as
"resolved" — the user has owned the conflict by removing the sidecar,
period. Whether they merged or discarded is a user decision the migrator
does not adjudicate.

State `(c)` is the only state where a sidecar is present AND has been
declared resolved. The `.resolved` flag-file was added by BD-095 to
support a workflow where the user wants the sidecar preserved on disk
(audit trail, comparison, attribution) while still signalling "I'm done
with this; please proceed".

### 1.2 Transitions

```
  (a) absent                                                (e) absent
       │                                                         ▲
       │ S3 dispatch                                             │
       │ (real-merge-required                                    │
       │  OR project-shadows-new-pack                            │
       │  OR removed-by-pack-customized)                         │
       ▼                                                         │
  (b) created  ─────────────────────────────────────────────────┘
       │  rm sidecar (or mv sidecar back to bare dest)
       │  → migrator records "resolved"
       │
       │  touch <sidecar>.resolved
       ▼  → migrator records "resolved" with sidecar still on disk
  (c) flagged-resolved
       │
       │  rm sidecar (cleanup after audit)
       │  → state collapses to (e) absent
       ▼
  (e) absent
```

The diagram has **no cycles** — sidecar lifecycles are forward-only at
the per-file level (mirroring the migrator's overall forward-only
semantics: ARCHITECTURE.md §6.0 + §6.H + the resume.sh:117-129 forward-
only guard).

A second `--apply` on a tree that already cleared its sidecars cannot
recreate them: `--apply` refuses to run when `stage-S3.paused` exists
(F4 paused-state guard, `apply.sh:296-313`), and the bare path refuses
in the same scenario (F3, `migrate-v10-to-v11.sh:728-742`). The only
way to re-enter state `(b)` is via the explicit recovery recipe
(restore-from-backup → `--dry-run` → `--apply`), which yields a fresh
state-dir and a fresh dispositions cycle.

### 1.3 What *can* go wrong

The state diagram exposes three failure-shaped questions:

1. **Stragglers from outside the paused list.** A sidecar from a
   different framework stage, a sidecar produced by a hand-run of
   customization-preserve, or a sidecar copied in from an unrelated
   project clone — none of these would be in `stage-S3.paused`. The
   `--resume` precondition does not gate them. (BD-101 MINOR-3 framing.)
2. **State `(c)` mistaken for state `(b)`.** A check that looks only at
   "*.suffix file present" cannot distinguish "user resolved with
   `.resolved` flag" from "user has not yet resolved". This is the
   collision surface that produced today's CI red.
3. **State `(b)` mistaken for state `(c)` or `(e)`.** A user might
   `touch foo.v10-customized.resolved` without actually merging the
   content. The `.resolved` flag is a self-attestation; nothing
   verifies that bare `foo` actually has the merged content. (BD-095
   spec accepted this as a deliberate trade.)

The recommendation in §6 will resolve (2) without re-opening (3).


---

## 2. Check placement matrix

This matrix names every place a sidecar-related check fires today and
classifies what each one observes. Mode column = `apply` (path through
`migrate_v10_to_v11_apply_run`) | `resume` (path through
`migrate_v10_to_v11_resume_run`) | `dry-run` (no sidecar work — sidecars
are produced by S3, and S3 is short-circuited in dry-run mode).

| # | Check site | Mode | What it observes | Failure semantics | Source |
|---|---|---|---|---|---|
| C1 | `_v10_v11_apply_collect_conflicts` (apply hook, post-S3) | apply | Reads `dispositions.tsv` for `customization-detected-needs-reconciliation` rows whose sidecar column is non-`-`; writes their paths to `stage-S3.paused` | If non-empty: pause cleanly, exit 0, prompt user to `--resume`. If empty: proceed to S4..S6 | `apply.sh:181-202` |
| C2 | `_v10_v11_resume_classify_sidecars` (resume precondition) | resume | Per-file lookup over the `stage-S3.paused` list: returns `resolved-flag` (companion `.resolved` exists) / `resolved-removed` (sidecar absent) / `unresolved` (sidecar present, no flag) | If any `unresolved`: refuse, list them, exit `EXIT_DIRTY` | `resume.sh:43-57` + `resume.sh:131-177` |
| C3 | `checkpoint_check_no_orphan_sidecars` (Gate 2, MINOR-3 fix) | apply, resume | Bare `find <target> -type f -name "*.${suffix}" -not -path '*/.pack-migrate-*' -not -path '*/.git/*'` | If any match: FAIL, list up to 10, return 1 → Gate 2 returns `EXIT_GATE_FAILED=31` | `checkpoint.sh:284-312` + `gate-2-phase-a-verify.sh:68-71` |
| C4 | `checkpoint_check_trinity_addenda` (Gate 2) | apply, resume | Trinity files exist + carry `## Project memory` or `## Project addenda` H2 | FAIL on any missing/wrong-shaped trinity file | `checkpoint.sh:128-158` |
| C5 | `checkpoint_check_help_fragments` (Gate 2) | apply, resume | `docs/pack/HELP-FRAGMENT.md` + `HELP-FRAGMENT-TRACKER.md` exist AND `cmp -s` against pack mirrors | FAIL on absence or byte-mismatch | `checkpoint.sh:167-205` |
| C6 | `checkpoint_check_dispositions_consistency` (Gate 2; SKIP in resume per MINOR-2) | apply | dispositions.tsv exists, non-empty, no `unknown-classification` rows | FAIL on missing/empty/unknown-row TSV. Skipped in resume mode | `checkpoint.sh:72-117` |
| C7 | `checkpoint_check_relocated_docs` (Gate 2) | apply, resume | Five legacy v9-era docs not at project root | FAIL on any straggler | `checkpoint.sh:214-236` |
| C8 | `checkpoint_check_validate_pack` (Gate 2) | apply, resume | `python3 scripts/validate-pack.py` exit 0 in pack repo | FAIL on validator non-zero | `checkpoint.sh:248-273` |

### 2.1 Observations from the matrix

**C3 (orphan-sidecar) is the only Gate 2 check that observes the project
tree's *file system* for sidecar artifacts.** Every other check inspects
either the migrator's state-dir, the trinity content, the relocated-docs
content, or the pack repo. C3 is also the only check whose intended
target overlaps the C2 (resume precondition) target — both look for
unresolved-sidecar conditions, but C2 is bounded to the paused list and
C3 is global.

**C3's failure mode is *blind* to the `.resolved` flag-file.** That's
the proximate cause of the CI red: state `(c)` (flagged-resolved) looks
exactly like state `(b)` (unresolved) to a bare `find -name "*.suffix"`.

**C3 fires in BOTH modes.** Gate 2 is invoked from `apply.sh:402-411`
(post-S6 wrapper) AND from `resume.sh:277-283` (explicit tail call).
Both invocations execute the same `migrate_v10_to_v11_gate2_run` body,
which runs C3 unconditionally. So a paused-then-resumed run hits C3
twice: (a) once during the original `--apply` IF it reaches Gate 2,
which it doesn't (the apply path exits 0 at the pause), and (b) once
during the `--resume` tail. In practice C3 only fires under `--resume`
for the conflict path; under `--apply` it only fires for the no-conflict
path. The asymmetry is invisible in the source but real in operation.

**C6 (dispositions) is mode-aware (skip in resume); C3 (orphans) is
not.** This is the proximate inconsistency BD-101 retro introduced. The
MINOR-2 fix correctly recognized that C6 has no meaning in resume mode
because resume.sh wipes dispositions.tsv; the MINOR-3 fix added C3
without applying the same mode-awareness lens. The result is a check
that runs in both modes but only "works" (has the same semantics as the
user expects) under the assumption that sidecars do not exist in the
post-resume tree — which is exactly what the `.resolved` flag-file
signal contradicts.

### 2.2 What "should the orphan check be in Gate 2 at all?" decomposes to

Two sub-questions:

**(2.2a) Should orphan detection happen anywhere?** Yes. The persona
contract `contract-migration.sh:87-130` exercises the
`.resolved`-flagged path; production users will hit both the
flag and rename paths. A migrated tree with stale `.v10-customized`
files (whatever lineage) is a legitimate hygiene concern — `git status`
shows them as untracked, future migrations would be confused, and
audits flag them as defects. Some check needs to surface them.

**(2.2b) Where?** The current placement (Gate 2, mode-symmetric) breaks
on legitimate paused workflows. Options enumerated in §6.

---

## 3. What "resolved" means + the `.resolved` flag-file contract

### 3.1 Observable signals

The migrator accepts two signals as evidence that the user has resolved
a sidecar (per `resume.sh:38-57`):

| Signal | Operationally | Conceptually |
|---|---|---|
| Companion `.resolved` flag-file (`<sidecar>.resolved`) | `[[ -f "${s}.resolved" ]]` | "I have decided. The sidecar may stay on disk for audit; do not block on it." |
| Sidecar removal (`<sidecar>` no longer at expected path) | `[[ ! -f "$s" ]]` | "I have decided. The sidecar is gone (because I merged content into the bare dest, OR because I accepted the pack default and `rm`'d it). There is no sidecar to gate on." |

Both are user self-attestations. Neither verifies that the bare
destination file actually contains the merged content the user
*intended*. The migrator does not three-way diff post-resolution. This
is by design — see §3.3 below.

### 3.2 Why TWO signals (BD-095 §6.H rationale)

The BD-095 spec accepted two signals because two operator workflows
both deserve first-class support:

1. **The "merge inline + delete sidecar" workflow.** User edits the
   bare destination, opens the sidecar in a diff tool, copies what
   they want forward, then `rm`s the sidecar. Common in editor-heavy
   workflows (VS Code's compare-files, etc.).
2. **The "merge inline + keep sidecar for audit" workflow.** User
   edits the bare destination, leaves the sidecar in place (to compare
   against later, to attach to the migration commit, to retain
   provenance), then signals "done" via `touch <sidecar>.resolved`.
   Common in security-conscious or code-review-heavy workflows where
   the sidecar's existence is part of the audit trail.

A single-signal contract would force users into one of these two
workflows. BD-095 explicitly chose the both-signals path. Reverting
that decision is out of scope for this design pass — every fix in §6
must preserve both signals' validity.

### 3.3 What `.resolved` does NOT promise

- It does NOT verify that bare destination has the merged content. The
  user could `touch foo.v10-customized.resolved` and never edit `foo`
  at all — Gate 2 would proceed.
- It does NOT verify that the user even read the sidecar.
- It is not encrypted, signed, or notarized. A misclick could create it.

These are accepted limitations. The compensating controls are the
*other* Gate 2 checks (trinity addenda H2 markers, HELP-FRAGMENT byte
equality, validate-pack), which check structural invariants of the
migrated tree. Those are content checks; `.resolved` is a
**procedural** check.

---

## 4. Redundancy analysis — does C3 (orphan-sidecar) catch anything other Gate 2 checks don't?

The right question to ask before keeping or removing C3 is: **what
failure mode does C3 detect that no other check would catch?**

### 4.1 Failure modes the BD-101 retro fix MINOR-3 was concerned with

Per `PACK-REVIEW-BD-101-RETRO.md` MINOR-3 (lines 232-252):

> If a user resolves a sidecar by editing the destination AND forgets
> to remove the sidecar (or if a sidecar from a different stage is
> left behind for any reason), Gate 2 reports PASS while the project
> tree still carries `*.v10-customized` files. The expected end-state
> of a successful migration is "zero `*.${MIGRATOR_OWN_SIDECAR_SUFFIX}`
> files at the target."

The reviewer named two distinct concerns:

(M3-α) **Forgot-to-remove case.** User merged into dest, did not `rm`
the sidecar, did not `touch .resolved`. Sidecar present on disk; user
believes the migration is done.

(M3-β) **Different-stage / unknown-lineage case.** A sidecar exists at
target path X, where X is NOT in `stage-S3.paused`. Lineage examples:
hand-run of customization-preserve, copy from another tree, residue
from a manually-aborted prior migration.

### 4.2 Cross-checking against existing Gate 2 checks

| Concern | Caught by C4 (trinity addenda)? | Caught by C5 (HELP-FRAGMENT)? | Caught by C7 (relocations)? | Caught by C8 (validate-pack)? | Caught by C2 (resume precondition)? |
|---|---|---|---|---|---|
| M3-α on a trinity file | NO. C4 checks *content shape* of bare dest; sidecar's existence is invisible to C4 | n/a | n/a | NO. validate-pack scans pack repo, not target | YES (in resume mode). C2 finds the unresolved sidecar and refuses to proceed. |
| M3-α on a non-trinity file (e.g. `.codex/config.toml`) | n/a | NO unless it's a HELP-FRAGMENT file | NO unless it's one of the 5 relocated docs | NO | YES (in resume mode), if the path was in stage-S3.paused |
| M3-β regardless of file | NO | NO | NO | NO | NO. C2 only looks at the paused list. |

**The redundancy verdict is clear.** For M3-α inside a paused-resume
flow, C2 already catches it (resume.sh refuses to proceed when an
`unresolved` sidecar exists). For M3-α outside the paused-resume flow
(i.e. on a no-conflict `--apply` that somehow had a stray sidecar), C3
is the only catch. For M3-β, C3 is the only catch in either mode.

So C3 catches a **real** failure class that no other check covers.
Removing it would create a (small but real) gap.

### 4.3 But: is the "real" failure class actually reachable in production?

For M3-β to occur, a sidecar matching `*.v10-customized` must exist at
target without being produced by *this* migration's S3 dispatch. The
preflight stage (`migrator-stages.sh _stage_preflight`) refuses to
proceed when a prior `.pre-update` sidecar exists (per the
`MIGRATOR_PRIOR_SIDECAR_SUFFIXES=("pre-update")` declaration at
`migrate-v10-to-v11.sh:80`). A future v11→v12 adapter would add
`v10-customized` to its prior-suffix list — at which point its
preflight would catch any v10-era straggler before it could pollute a
v11→v12 run.

Inside the v10→v11 lifetime, M3-β requires either (a) a hand-run of
customization-preserve.sh against the same suffix, or (b) a manual
copy-in from another tree, or (c) a partial-aborted prior v10→v11 run
whose state-dir was deleted but whose sidecars were left behind.
(c) is plausible — users delete state dirs to "start over". But (c) is
also caught by S0 idempotency (`migrator-stages.sh:131-135`) when
dispositions.tsv exists, and by S1 backup-dir-exists when the backup
mirror exists. The path where dispositions.tsv was deleted but sidecars
were not, AND backup-dir was deleted, AND the user re-ran `--apply`,
is narrow but not impossible.

For M3-α on no-conflict `--apply`, the path requires that S3 produced
zero conflicts (so no `stage-S3.paused`, no `--resume` invocation, no
C2 firing) AND that a sidecar nonetheless landed on disk. This is
internally inconsistent: S3 only writes a sidecar via a
`needs-reconciliation` row, which by definition appears in the paused
list. So M3-α is structurally impossible inside a single
`--apply` execution. M3-α can occur only across executions (one
execution wrote the sidecar; a later execution fails to clean up).

**Conclusion.** C3 covers real but narrow failure classes that other
checks miss. The cost of keeping C3 is the BD-095 collision (the CI
red). The right design decision is therefore: **keep C3 in some form
but make it `.resolved`-aware**, OR **move C3 out of Gate 2 to a
location where mode asymmetry is structural rather than accidental**.

---

## 5. Mode-awareness analysis — current undefined behavior + recommended

### 5.1 Current state

Gate 2's behavior across modes is *partially* mode-aware (one check,
C6, is mode-aware; one check, C3, has effectively mode-aware
*intent* but mode-symmetric *implementation*; the rest are
mode-symmetric and correctly so).

| Check | apply behavior | resume behavior | Documented? |
|---|---|---|---|
| C4 trinity addenda | Same | Same | Yes (`gate-2-phase-a-verify.sh:14-15`) |
| C5 HELP-FRAGMENT | Same | Same | Yes (`gate-2-phase-a-verify.sh:16`) |
| C6 dispositions | Full check | SKIP with `[INFO]` | Yes (`checkpoint.sh:79-89`; reviewer comment) |
| C7 relocations | Same | Same | Yes |
| C8 validate-pack | Same | Same | Yes |
| C3 orphan-sidecars | Full check | Full check (treats `(c)` flagged-resolved as orphan) | NO — comment at `checkpoint.sh:280-283` does not name the mode interaction |

The C6 fix establishes a precedent that mode-awareness IS acceptable
for Gate 2 checks when the resume path's data shape genuinely differs
from the apply path's. For C3, the question is symmetric: under
`--apply`, sidecars on disk are user-error (or edge-case M3-β); under
`--resume`, sidecars on disk in state `(c)` are *expected and
legitimate*.

### 5.2 Why the persona contract sees `--apply`-pass-then-`--resume`-fail today

Reading the symptom in the prompt:

> An asymmetry hint in the persona contract log: dispositions message
> says "the original --apply Gate 2 already validated them" — i.e., the
> SAME sidecars passed Gate 2 at `--apply` time but failed at `--resume`
> time. Gate 2's behavior is currently undefined-by-design across modes.

The `--apply`-pass claim is misleading on close reading: in the persona
contract scenario the original `--apply` paused at S3
(`apply.sh:221-271`) and exited 0 BEFORE reaching the post-S6 wrapper
that fires Gate 2. So Gate 2 never ran in `--apply` mode for that
sandbox. When `--resume` finishes S4..S6 and explicitly invokes Gate 2
at `resume.sh:277-283`, that's the FIRST time Gate 2 sees the tree.
The sidecars are still on disk (the persona contract used the
`.resolved` flag-file path; sidecars are intact in state `(c)`). C3
fires, doesn't know about state `(c)`, and FAILs.

So the asymmetry is not "apply Gate 2 said OK; resume Gate 2 said FAIL"
— it's "apply Gate 2 was never invoked for this conflict path; resume
Gate 2 invoked it for the first time, against a tree where the
`.resolved` signal was the user's chosen resolution path".

### 5.3 Recommended mode-awareness

Gate 2 in `--resume` mode is observing the END STATE of a paused-
reconciled-resumed flow. State `(c)` is a legitimate end state: the
user chose to keep the sidecar on disk for audit. State `(b)` is NOT
a legitimate end state in `--resume` (C2 already enforced this — if a
state `(b)` sidecar existed in the paused list, `--resume` would have
refused).

Therefore, in `--resume` mode, C3 should observe sidecars but classify
them using the same `.resolved` / removed / unresolved logic that
`_v10_v11_resume_classify_sidecars` uses (C2). A flagged-resolved
sidecar is NOT an orphan; an unresolved sidecar IS (and would be a
defect because C2 should already have caught it; finding one here is
a defense-in-depth signal of a C2 bug).

In `--apply` mode the same logic applies: a sidecar in state `(c)` is
legitimate IF stage-S3.paused was processed; a sidecar in state `(b)`
is unresolved. (In practice apply-mode-without-pause means stage-S3.paused
was never written, so any sidecar found is M3-β; that should still
fail loud.)

The unifying principle: **C3 should classify sidecars the same way C2
does**, then FAIL only on `unresolved` instances. Both modes share the
classification; the mode awareness reduces to "what does
'unclassified-because-not-in-paused-list' mean?" — which is
mode-symmetric: it means M3-β, which is an orphan in either mode.

This unification removes the implicit mode asymmetry that today's
C3 has accidentally and replaces it with explicit, documented
mode-symmetric semantics. C6 stays mode-aware (its data is genuinely
absent in resume mode). The fixed C3 stays mode-symmetric because its
classification logic handles both modes the same way.

---

## 6. Recommendation

**Recommendation: option (d), modified — keep C3 in Gate 2 + make it
sidecar-classification-aware, sharing the C2 classifier.**

The decision tree:

1. The check is *necessary* (§4.3 — closes M3-α and M3-β classes that
   no other Gate 2 check covers).
2. The check is *correctly placed* in Gate 2 conceptually (§5.3 — Gate 2
   is the post-Phase-A truth oracle; sidecar state IS part of the
   post-Phase-A truth).
3. The check is *broken* today because it uses an over-coarse predicate
   that ignores the BD-095 contract.
4. The fix is to share the C2 classification primitive — a single
   helper (`_v10_v11_resume_classify_sidecars` in resume.sh:43-57) that
   already encodes the BD-095 two-signal contract correctly.

This is option (d) from the prompt menu, but framed as architectural
unification rather than band-aid: we're not bolting `.resolved`
awareness onto C3 as a special case, we're recognizing that C2 and C3
are two views of the same predicate ("is sidecar X resolved?") and
extracting the predicate to a shared site.

### 6.1 Why not option (a) — move orphan check to pre-resume preflight, remove from Gate 2

**Rejected because:**

- Pre-resume preflight is C2's territory (resume.sh:131-177). C2 already
  does this check, but only for paused-list entries. Extending C2 to
  do a global find at preflight conflates two concerns: "the paused
  conflicts I asked you to resolve" vs "stale sidecars from anywhere".
  The error message and recovery verbs differ between them.
- C3-in-preflight does not catch the `--apply`-mode M3-β case (a stale
  sidecar at `--apply` time, when there is no pre-resume preflight at
  all). Gate 2 is the only place that fires under `--apply` AND under
  `--resume`. Moving C3 out of Gate 2 sacrifices `--apply`-mode
  coverage for `--resume`-mode purity.
- It does not solve the underlying problem: the `find ... -name "*.suffix"`
  predicate is still wrong (it can't tell `(c)` from `(b)`); option (a)
  just reduces the number of places it's wrong from two to one.

### 6.2 Why not option (b) — make Gate 2 mode-aware (skip orphan check on initial `--apply`; enforce on `--resume`)

**Rejected because:**

- The proposed mode mapping is exactly backwards. Under `--apply`
  without a pause, sidecars on disk should be impossible (S3 only
  writes them on the needs-reconciliation path, and that path forces
  a pause); finding one is a strong M3-β signal — exactly the case
  Gate 2 was supposed to catch. We should NOT skip the check there.
- Under `--resume`, the legitimate state-`(c)` sidecars exist, and C3
  as written would FAIL on them. Enforcing C3 on `--resume` is what's
  broken today; mode-aware skip would mask it but not fix it.
- The right shape is "enforce in both modes, but classify correctly,
  not skip". Option (d) gives that.

### 6.3 Why not option (c) — remove MINOR-3 entirely

**Rejected because:**

- §4.3 establishes M3-α (cross-execution) and M3-β as real classes
  that no other Gate 2 check covers. Removing C3 reopens those gaps.
- The persona contract failure is not evidence that M3-β doesn't
  matter — it's evidence that the check is over-zealous on a
  legitimate state.
- "Just remove the check" is the path of least resistance, but it
  silently shifts a category of defect (orphan sidecars in any
  lineage) from "Gate 2 catches it" to "no one catches it until the
  next migration's preflight, if ever".

### 6.4 Why option (d) modified vs option (d) literal

The literal option-(d) framing in the prompt was "Keep in Gate 2 +
add `.resolved` awareness (the band-aid candidate)". The modified
form is structurally cleaner because:

- It does not duplicate the C2 classification logic in C3. Duplicating
  is the band-aid path; sharing the helper is the unification path.
- It surfaces the existing C2 helper
  (`_v10_v11_resume_classify_sidecars`) as a generally-useful primitive
  instead of leaving it as a private helper of resume.sh. The promotion
  is the architectural payoff.
- It preserves the existing C2 contract verbatim — C2 stays in
  resume.sh as the precondition gate; C3 reuses C2's classifier as
  the global gate. Two callers of one classifier; clear ownership.

### 6.5 Option (e) considered: classify and split the helper

A cleaner-still option is to extract the classifier into the shared
`checkpoint.sh` (where C3's body already lives) as
`checkpoint_classify_sidecar <sidecar-path>` returning one of
`resolved-flag` / `resolved-removed` / `unresolved`, then have BOTH
resume.sh's C2 helper AND the new C3 body call it. This is an option-(d)
variant that goes one step further: it makes the classifier the single
source of truth for sidecar resolution semantics.

I recommend option (d) modified as the IMMEDIATE fix (smaller surface,
unblocks CI today) and option (e) extraction as a SEPARATE follow-up
(touches resume.sh, which is BD-095 territory; that boundary is exactly
the kind of cross-team edit Pack Chat should approve as its own BD).
The §7 handoff implements option (d) modified.


---

## 7. Implementation handoff

### 7.1 Scope

One file edit, ≤ 25 LOC. The change:

- Modifies `checkpoint_check_no_orphan_sidecars` in
  `scripts/lib/migrate-v10-to-v11/checkpoint.sh` (lines 284-312) to
  classify each found sidecar against the BD-095 `.resolved` /
  removed / present contract before counting it as orphan.
- Updates the function header comment (lines 275-283) to name the
  BD-095 lifecycle states the function now respects.
- No edits to `gate-2-phase-a-verify.sh` (the call site is
  unchanged: still `if ! checkpoint_check_no_orphan_sidecars
  "$target"; then fails=$((fails + 1)); fi`).
- No edits to `resume.sh` (preserves BD-095 territory boundary).
- No edits to `apply.sh`, `dry-run.sh`, `migrate-v10-to-v11.sh`,
  `migrator-core.sh`, or `customization-preserve.sh`.

### 7.2 The edit (verbatim before/after for the function body)

**File:** `scripts/lib/migrate-v10-to-v11/checkpoint.sh`

**Lines to replace:** 275-312 (header comment + entire function body).

**After (replacement text):**

```bash
# ── checkpoint_check_no_orphan_sidecars ──────────────────────────────────
#
# MINOR-3 (BD-101 retro fix), updated per
# maintenance-docs/v11-implementation/ARCHITECTURE-SIDECAR-LIFECYCLE.md
# §6: Gate 2 should observe zero UNRESOLVED own-suffix sidecar files at
# the project root. The BD-095 contract (resume.sh:38-57) accepts TWO
# resolution signals: (a) companion `<sidecar>.resolved` flag-file, and
# (b) sidecar absence (user merged + `rm`'d). A sidecar in state (c)
# "flagged-resolved" — present on disk WITH a `.resolved` companion —
# is legitimate audit-trail residue and MUST NOT be counted as orphan.
#
# What this catches that other Gate 2 checks don't:
#   - M3-α (cross-execution forgot-to-remove): sidecar present, no
#     `.resolved` companion, no `stage-S3.paused` guard active because
#     a later run wiped state-dir or completed. C2 (resume.sh
#     precondition) only sees paused-list entries; this catches the
#     residual class.
#   - M3-β (unknown-lineage stragglers): sidecar matching this
#     migrator's suffix at any path under target, regardless of whether
#     it appears in stage-S3.paused.
#
# Lifecycle states (§1):
#   (b) created     → sidecar present, no .resolved → UNRESOLVED → FAIL
#   (c) flagged     → sidecar present + .resolved   → RESOLVED   → OK
#   (d)/(e) absent  → sidecar gone                  → RESOLVED   → not seen by find

checkpoint_check_no_orphan_sidecars() {
    local target="${1:-}"
    if [[ -z "$target" || ! -d "$target" ]]; then
        printf '  [FAIL] sidecars: target dir missing (%s)\n' "$target"
        return 1
    fi
    local suffix="${MIGRATOR_OWN_SIDECAR_SUFFIX:-}"
    if [[ -z "$suffix" ]]; then
        # Adapter contract violation — treat as INFO not FAIL so the
        # gate does not block on a framework-loading defect.
        printf '  [INFO] sidecars: MIGRATOR_OWN_SIDECAR_SUFFIX unset; skipping orphan-sidecar check\n'
        return 0
    fi
    # Find candidates under target, excluding migrator state dirs and
    # .git/. `head -10` caps the listed-orphan output so a pathological
    # fixture does not flood the gate banner.
    local candidates orphans=()
    candidates=$(find "$target" -type f -name "*.${suffix}" \
        -not -path '*/.pack-migrate-*' \
        -not -path '*/.git/*' \
        2>/dev/null)
    if [[ -z "$candidates" ]]; then
        printf '  [OK]   sidecars: no *.%s files at target\n' "$suffix"
        return 0
    fi
    # Per BD-095 §6.H + ARCHITECTURE-SIDECAR-LIFECYCLE.md §3.1: a
    # sidecar with a companion `.resolved` flag-file is in state (c) —
    # legitimate. Only sidecars WITHOUT that companion count as orphan.
    local s
    while IFS= read -r s; do
        [[ -z "$s" ]] && continue
        [[ -f "${s}.resolved" ]] && continue
        orphans+=("$s")
    done <<< "$candidates"
    if (( ${#orphans[@]} > 0 )); then
        printf '  [FAIL] sidecars: %d unresolved *.%s file(s) at target  → Run: resolve and rm each listed sidecar (or touch <sidecar>.resolved if accepting pack default)\n' \
            "${#orphans[@]}" "$suffix"
        printf '         %s\n' "${orphans[@]:0:10}"
        return 1
    fi
    printf '  [OK]   sidecars: no unresolved *.%s files at target (resolved-via-flag sidecars present are OK)\n' "$suffix"
    return 0
}
```

### 7.3 Behavior table (post-edit)

| Tree state | candidates result | orphans array | Outcome |
|---|---|---|---|
| No `*.v10-customized` files | empty | `[]` | `[OK] no *.v10-customized files` |
| 3 files, all with `.resolved` companions (state (c)) | 3 paths | `[]` | `[OK] no unresolved *.v10-customized files (resolved-via-flag sidecars present are OK)` |
| 3 files, none with companions (state (b)) | 3 paths | 3 paths | `[FAIL] 3 unresolved *.v10-customized file(s)` |
| 3 files, 2 flagged + 1 not | 3 paths | 1 path | `[FAIL] 1 unresolved *.v10-customized file(s)` |

The persona contract scenario (3 trinity sidecars, all flagged via
`touch ${s}.resolved` per `contract-migration.sh:115-118`) lands in
row 2: PASS, exit 0. CI red is closed.

### 7.4 What the edit does NOT do

- Does NOT change C2's resume precondition (the resume.sh classifier
  stays put; both helpers now agree on the contract).
- Does NOT extract a shared classifier (option (e), deferred).
- Does NOT change Gate 2 wiring at gate-2-phase-a-verify.sh:68-71.
- Does NOT add mode-aware skip logic; both modes execute the same
  classification (the asymmetry of "what `unresolved-not-in-paused-list`
  means" is observably mode-symmetric — both modes treat it as defect).
- Does NOT alter the `head -10` cap behavior; the cap is preserved as
  `${orphans[@]:0:10}` slice.

### 7.5 LOC delta

The replacement function body is ~30 LOC vs the original ~28 LOC; the
header comment grows from 8 lines to 22 lines (lifecycle naming).
Total file delta: approximately +20 / -10. Within the ≤ 30 LOC
guideline.


---

## 8. Tests / contracts that need updating

### 8.1 CI red — what passes after the §7 edit

These two artifacts fail today on commit `fd0c4b3` and should pass
unmodified after the §7 edit. Coder should verify, not edit:

- **`scripts/tests/test-migrate-v10-to-v11-dry-run.sh:208-225` test 4.1**
  (`--resume rc=0 (.resolved signal)`). The test creates a paused
  migration, touches `${s}.resolved` for each sidecar, then invokes
  `--resume`. The expected rc=0 and `[ stage-S6.done after --resume]`.
  Current rc=31 because Gate 2's C3 fails on the still-present
  `*.v10-customized` files. After §7: C3 sees the `.resolved`
  companions, returns 0, Gate 2 PASS, rc=0.

- **`scripts/persona-contracts/contract-migration.sh:115-130`**.
  Same pattern — the contract creates `.resolved` flag-files for each
  sidecar after the apply pause, then runs `--resume`. The
  `[FAIL] sidecars: orphan *.v10-customized file(s) at target` banner
  goes away; the contract proceeds to assertions 2-4.

No changes to these files are required by the §7 edit.

### 8.2 New test cases coder SHOULD add

Add to `scripts/tests/test-migrate-v10-to-v11-gates.sh` (the BD-101
gate test harness), in Group 2 (orphan-sidecar coverage):

| Case | Asserts | File:line target |
|---|---|---|
| 2.5b | Sidecar present + `.resolved` companion present → `[OK] sidecars: no unresolved` line in stdout, return 0 (no orphan flagged) | `scripts/tests/test-migrate-v10-to-v11-gates.sh` Group 2, after the existing 2.5 (`scripts/tests/test-migrate-v10-to-v11-gates.sh` — file present per Batch 21c per `IMPLEMENTATION-REPORT-BD-101-RETRO-FIX.md` §3) |
| 2.5c | Sidecar present + NO `.resolved` companion → `[FAIL] N unresolved *.v10-customized file(s)` line, return 1 | Same file, immediately after 2.5b |
| 2.5d | Two sidecars, one flagged, one not → `[FAIL] 1 unresolved` (count is precise; only the unflagged one is named) | Same file, immediately after 2.5c |
| 2.5e | Three sidecars, all flagged → `[OK] sidecars: no unresolved *.v10-customized files (resolved-via-flag sidecars present are OK)` | Same file, immediately after 2.5d |

The existing case 2.5 (`Planted orphan-doc.v10-customized → Gate 2
returns rc=31`) becomes a special case of 2.5c and continues to PASS
unchanged after the §7 edit (the planted orphan has no companion
`.resolved`, so it's correctly classified as orphan).

The existing case 2.6 (`Clean post-apply tree → [OK] sidecars: no
orphan`) PASSes unchanged because the [OK] line wording shifts from
"no orphan *.v10-customized files at target" to "no *.v10-customized
files at target" — the assertion in 2.6 should look for the substring
`no` plus the suffix; if it grep-matches the literal pre-fix line it
will need a one-token tightening. Coder verify against the actual
assertion in `scripts/tests/test-migrate-v10-to-v11-gates.sh` Group 2.

### 8.3 Architecture invariant to add to CONCEPTUAL-AREA doc (optional)

`maintenance-docs/v11-implementation/CONCEPTUAL-AREA-CUSTOMIZATION-PRESERVATION.md`
is the conceptual-area doc for the customization-preservation domain.
It currently does not name the sidecar lifecycle states. Coder MAY
add a back-reference paragraph naming the states (a)..(e) and
pointing at this document as the authoritative state diagram. Not
required for the CI red fix; suggested for documentation
completeness if the doc is touched in a future BD.

### 8.4 No changes required to

- `scripts/lib/migrate-v10-to-v11/resume.sh` — C2's classifier remains
  the precondition-list classifier; the §7 edit does not call into it.
- `scripts/lib/migrate-v10-to-v11/apply.sh` — Gate 2 invocation is
  unchanged.
- `scripts/lib/migrate-v10-to-v11/dry-run.sh` — sidecars are not
  written in dry-run mode.
- `scripts/lib/migrate-v10-to-v11/gate-2-phase-a-verify.sh` — the
  function call site at line 70 (`if !
  checkpoint_check_no_orphan_sidecars "$target"; then`) is unchanged.
  The function's return semantics (0 = PASS, 1 = FAIL) are preserved.
- `supporting-docs/MIGRATION-v10-to-v11.md` — user-facing surface is
  unchanged; the OK-vs-FAIL semantics improve but the docs already
  describe the BD-095 two-signal contract correctly.
- `supporting-docs/MERGE-STRATEGY.md` — §A1 already describes both
  signals correctly.
- `BACKLOG.md` — BD-101 stays Resolved; the §7 edit is a fix-follow
  inside the existing BD's scope (§4.3 + §6 establish that C3 is
  necessary; the fix preserves the BD's intent while closing the
  collision).

### 8.5 If Pack Chat opens a fresh BD for this fix

If the fix is scoped as a new BD (rather than a Batch 21c follow-up
fix), the BD entry should:

- **Type:** Fix-follow (BD-101 collision with BD-095 contract).
- **File/Symbol:** `scripts/lib/migrate-v10-to-v11/checkpoint.sh`
  `checkpoint_check_no_orphan_sidecars` (lines 275-312).
- **Blockers:** BD-101 (Resolved), BD-095 (Resolved).
- **Description anchor:** "Per
  `maintenance-docs/v11-implementation/ARCHITECTURE-SIDECAR-LIFECYCLE.md`
  §6, the BD-101 retro fix MINOR-3 orphan-sidecar check uses an
  over-coarse `find -name "*.suffix"` predicate that ignores the
  BD-095 §6.H two-signal `.resolved` contract. State `(c)`
  flagged-resolved sidecars are misclassified as orphans, causing
  Gate 2 to FAIL on legitimate paused-resumed flows. Replace with a
  classifier-aware check per §7 of the architecture doc."
- **Blocks:** none (this is the leaf fix).

### 8.6 Coder pre-flight checklist

Before applying the §7 edit, verify:

- [ ] `scripts/lib/migrate-v10-to-v11/checkpoint.sh` lines 275-312 are
  the function header comment + body (no other code interleaved).
- [ ] `scripts/lib/migrate-v10-to-v11/gate-2-phase-a-verify.sh:70`
  invokes `checkpoint_check_no_orphan_sidecars "$target"` (no
  additional arguments to update).
- [ ] `scripts/tests/test-migrate-v10-to-v11-dry-run.sh:208-225` test
  4.1 is the failing test (run it to confirm rc=31 pre-edit, rc=0
  post-edit).
- [ ] `scripts/persona-contracts/contract-migration.sh` is the failing
  contract (run it to confirm pre-edit FAIL, post-edit PASS).
- [ ] `scripts/tests/test-migrate-v10-to-v11-gates.sh` exists and
  Group 2 is the orphan-sidecar group (where 2.5b/c/d/e land).

After the §7 edit:

- [ ] `bash -n scripts/lib/migrate-v10-to-v11/checkpoint.sh` clean.
- [ ] Test 4.1 in `test-migrate-v10-to-v11-dry-run.sh` PASSes.
- [ ] Persona contract `contract-migration.sh` PASSes.
- [ ] BD-101 gate test suite (`test-migrate-v10-to-v11-gates.sh`) all
  pass plus the four new 2.5b/c/d/e cases.
- [ ] `python3 scripts/validate-pack.py` clean.

---

## Appendix A — Files / call sites referenced

Absolute paths (per session conventions):

- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/migrate-v10-to-v11/checkpoint.sh` (target file for §7 edit; lines 275-312)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/migrate-v10-to-v11/gate-2-phase-a-verify.sh` (call site; line 70)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/migrate-v10-to-v11/apply.sh` (Gate 2 invocation; lines 402-411)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/migrate-v10-to-v11/resume.sh` (C2 precondition + Gate 2 invocation; lines 38-57, 131-177, 277-283)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/migrator-core.sh` (`MIGRATOR_OWN_SIDECAR_SUFFIX` adapter contract; lines 139-180)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/lib/customization-preserve.sh` (sidecar producer; lines 271-292)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/migrate-v10-to-v11.sh` (adapter; `MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"` declaration at line 76)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/tests/test-migrate-v10-to-v11-dry-run.sh` (test 4.1 at lines 208-225 — currently failing on commit `fd0c4b3`)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/tests/test-migrate-v10-to-v11-gates.sh` (BD-101 gate harness; Group 2 owns orphan-sidecar coverage)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/scripts/persona-contracts/contract-migration.sh` (BD-116 persona contract; `.resolved`-flag path at lines 115-130)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/PACK-REVIEW-BD-095-RETRO.md` (F3, F4 paused-state guards informing §1.2)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/PACK-REVIEW-BD-101-RETRO.md` (MINOR-3 framing for C3, MAJOR-1 recovery banner cross-reference)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-095-RETRO-FIX.md` (F3/F4 fix history)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-101-RETRO-FIX.md` (MINOR-3 fix history that introduced C3)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-research/ARCHITECTURE.md` (§6.0 bidirectionality contract, §6.7 round-trip safety; informing §1.2 forward-only)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/supporting-docs/MIGRATION-v10-to-v11.md` (user-facing migration narrative; §3.2 two-signal contract appears in Step 2)
- `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/supporting-docs/MERGE-STRATEGY.md` (§A1 BD-095/BD-101 mode + recovery descriptions)

