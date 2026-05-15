# IMPLEMENTATION-REPORT-BD-120-RETRO-FIX — Batch 21c retro fixes

**Source review:** `maintenance-docs/v11-implementation/PACK-REVIEW-BD-120-RETRO.md`
**Anchor BD:** BD-120 — Parameterize realistic-OT fixture generator for any vN
**Original commit:** `3fa3322` (Phase 3.5 Batch 3a)
**Branch:** `v11-dev`
**Worktree HEAD (start):** `870f485e3b45e27c5bba9d181563ebe0fb815b88`
**Date:** 2026-05-15
**Coder:** pack-coder (retro-fix pass; per-BD review/fix cycle for Batch 21c)

---

## 1. Summary

All six findings (F1 SHOULD, F2 SHOULD, F3 NIT, F4 NIT, F5 NIT, F6 NIT) from
`PACK-REVIEW-BD-120-RETRO.md` are addressed in two files —
`test-fixtures/build.sh` (+48/-16) and `test-fixtures/README.md` (+34/-9). Net
of 57 added lines / 25 removed lines, all changes scoped to the BD-120
surface.

The patch (a) drops the misleading `migrator_target_surface_for_version`
README/docstring claim and replaces it with truthful guidance about the
helper's role as a future-vN ground-truth that the builder does NOT consume
(F1); (b) replaces the silent dead-code v11 case body with a fail-loud `die`
sentinel pointing at BD-160 (F2); (c) adds a `_update_manifest` docstring
note explaining the v10/v11 SHA-drift asymmetry so future agents doing
`git show` archaeology on v11-* row churn have a discoverable explanation
(F3); (d) deletes the orphaned `_build_v10_realistic_ot` shim (zero callers
verified) and inlines its dispatcher target (F4); (e) extends the README
BD-120 subsection with an explicit 4-step add-a-vN-realistic-ot checklist
(F5); and (f) documents the per-version source-pin semantics asymmetry as
an invariant in the `_build_realistic_for_version` docstring (F6).

`bash -n test-fixtures/build.sh` passes. `grep -RIn '_build_v10_realistic_ot'`
returns zero matches in live code (`test-fixtures/`, `scripts/`, `.github/`)
after the F4 deletion; remaining matches are documentation/archive only.

---

## 2. Per-finding fix detail

### F1 — Helper-not-consumed contract drift (SHOULD)

**Finding (verbatim from retro §3 F1):**
> Architecture-design helper `migrator_target_surface_for_version` is
> referenced in docs but NOT consumed by the implementation (contract
> drift) … `test-fixtures/README.md` line 156-158 actively misleads on
> this … A reader follows that pointer expecting build.sh to consume the
> helper; it does not.

**Path chosen:** option (b) — drop the misleading "lives in … the per-
version customization-surface declaration" claim and replace with truthful
language that names the helper as the per-version ground truth that the
builder does NOT consume (so a future vN with a divergent surface MUST
be re-verified by hand).

**Why not option (a) (wire the helper):**
1. The prompt explicitly forbids editing `scripts/lib/migrator-core.sh`,
   which would be needed to align the helper's docstring claim ("Used by
   BD-120 fixture parameterization") with reality if option (b) is chosen
   in the README. Wiring the helper from build.sh is the only F1 path
   that preserves the helper's docstring as-is — but it (i) introduces a
   runtime `source` dependency from the fixture builder onto a migrator
   library, (ii) risks regressing the v10-realistic-ot byte-identity
   invariant (the validation step would change customization-pattern
   ordering or fail-loud on a v10 surface change), and (iii) duplicates
   work BD-160 will do anyway when it actually needs the helper.
2. "Smallest-surface-area change" per the scope clarification points to
   updating two doc surfaces (README + builder docstring) rather than
   adding a runtime dependency.
3. The scope clarification also forbids editing `scripts/lib/migrator-core.sh`
   even when convenient — so the helper docstring's "Used by BD-120
   fixture parameterization" line will remain as a forward-pointing claim
   that BD-160 (which actually wires the helper consumer) must validate
   when it lands. This is documented in §5 (out-of-scope items) below.

**Edit (README.md, BD-120 subsection):**

Before (lines 156-168):
```
The legacy `_build_v10_realistic_ot()` entry point
is preserved as a thin wrapper for backwards compatibility. The
per-version customization-surface declaration lives in
`scripts/lib/migrator-core.sh::migrator_target_surface_for_version`
(BD-119).
```

After (the new step-4 in the checklist replaces this):
```
4. If vN's surface differs from v10/v11 for the C1–C4 customization
   patterns (e.g., `.codex/config.toml` location moves, agent dirs
   relocate), re-verify each pattern against
   `migrator_target_surface_for_version vN` in
   `scripts/lib/migrator-core.sh`. That helper is the per-version
   customization-surface ground truth; the BD-120 builder hardcodes
   the v10/v11 paths inline rather than consuming the helper, so any
   surface change in a future vN must be reflected by hand in the
   builder's customization steps.
```

**Edit (build.sh, `_build_realistic_for_version` docstring):**

Added explicit "This builder does NOT consume the helper at runtime" lines
to the docstring (see lines 187-198 of new build.sh). Truth-aligned with
both the README and the actual implementation.

**BD-170 forward-compat preservation:** BD-170's BACKLOG File/Symbol field
calls out "fixture-generator function structure per Addendum #1 §9.1"
and combines with BD-160 to wire the v11 case + per-entry tree extension.
Option (b)'s F1 fix introduces zero runtime change; BD-160/BD-170 are free
to wire the helper into the v11 case when they re-verify C2/C3 paths
against `migrator_target_surface_for_version v11`. Nothing in this fix
forecloses the BD-119 design intent.

---

### F2 — v11 case dead code + fail-loudness gap (SHOULD)

**Finding (verbatim from retro §3 F2):**
> v11 dispatch case (lines 209-211 + 222) is reachable from
> `_build_realistic_for_version v11` but unreachable via the `--name` CLI;
> failure-loudness gap on the CLI side … the v11 dispatch path is
> currently dead code … BD-120 landed a refactor whose v11 branch has
> zero test coverage … Either it should be removed (and BD-160 adds it)
> OR its incompleteness should be guarded by a fail-loud sentinel.

**Path chosen:** option (b) — sentinel `die` until BD-160. Trade-offs vs
the alternatives:

- option (a) (remove the v11 case body and let `*) die` catch it):
  removes the line, but BD-160 has a moderately broader rewrite when it
  lands (it must reconstruct the case skeleton plus the production body).
  Option (a) is the smallest line-count fix in isolation but has higher
  BD-160 churn cost.
- option (b) (sentinel `die`): adds a single explicit failure point with
  a named pointer to BD-160. BD-160 replaces the `die` line with the
  production body — single-point edit. Higher in-fix line count but
  lower BD-160 churn cost. Aligns with pack failure-loudness convention
  (V3.3 §5.6 "no silent retry / no silent fallback" cited by reviewer).
- option (c) (README "Status" note): leaves the unwired v11 path latently
  callable. Does not satisfy the failure-loudness rule.

Per scope clarification ("smallest-surface-area … consistent with
BD-119 framework alignment + BD-160/BD-170 forward-compatibility"),
option (b) is the choice that minimizes BD-160's rework and gives
BD-160 a single named call site to swap.

**Edit (build.sh, lines 231-242 of the new file):**

Before (lines 209-211 + 222 of original):
```bash
        v11)
            info "  source: pack v11 (current HEAD) + FakeOT customizations"
            ;;
```
…and the second case block:
```bash
        v11) _run_v11_init "$target" ;;
```

After:
```bash
        v11)
            # BD-120 retro-fix F2 (2026-05-15): v11 case body removed
            # pending BD-160. Until BD-160 wires v11-realistic-ot into
            # FIXTURE_NAMES + dispatcher AND re-verifies C2/C3 against
            # the v11 surface per `migrator_target_surface_for_version
            # v11`, this path produces a functionally-incomplete fixture
            # silently (the [[ -f ]] guard at C2 masks v11-shape drift).
            # Fail loud here so any direct caller (test harness, manual
            # invocation) gets a clear pointer to BD-160 instead of a
            # half-built fixture.
            die "_build_realistic_for_version v11: unwired pending BD-160 (v11-realistic-ot dispatcher wiring + C2/C3 v11-surface verification — see BACKLOG BD-160 / BD-170)" 4
            ;;
```

…and the second case block:
```bash
    case "$ver" in
        v10) _run_v10_init "$target" ;;
        # v11) — wired by BD-160; v11 case above dies before reaching here.
    esac
```

**BD-170 forward-compat preservation:** The `die` sentinel is a single-
line replacement target for BD-160. When BD-160 wires the v11 case body
(per its BACKLOG File/Symbol entry: "extend the `_build_realistic_for_version`
v11 case to source-clone from the v11 git tag, run `_run_v11_init`, apply
re-verified C2/C3 customization patterns"), it deletes the comment block
+ `die` and writes the production body in its place. The second `case`
block's commented placeholder also serves BD-160 as a marker. Nothing
about the sentinel forecloses BD-160's combined-with-BD-170 commit
structure (per BACKLOG line 1393: "Combined commit shipping BD-160
(v11 case dispatch + C2/C3 customization re-verification on v11 surface)
+ BD-170 (per-entry tree extension + round-trip test)").

---

### F3 — manifest.txt v11-* SHA drift discoverability (NIT)

**Finding (verbatim from retro §3 F3):**
> `manifest.txt` v11-* SHA drift was committed with BD-120 but originates
> from BD-143..BD-158 — coupling violates separation-of-concerns … The
> general principle for future maintenance work that auto-regenerates
> artifacts: stage only the artifact rows the BD intended to change …
> Document the commit-scope discipline as a maintenance-mechanical
> convention.

**Path chosen:** brief comment near `_update_manifest` in build.sh. Per
scope clarification ("prefer a single-line live comment over a multi-
line block. The smallest surface that makes the SHA-drift behavior
discoverable to a future agent doing `git show` archaeology"). Picked
build.sh over README because:
- The `_update_manifest` docstring is the most natural live forward-
  pointing surface (an agent inspecting a manifest churn commit will
  `git blame` → `git log` → land on `build.sh::_update_manifest`).
- The README "Determinism" section already covers the v10-pinned vs
  v11-HEAD-tracking semantics generally; F3 is specifically about the
  commit-scope hygiene implication, which is a build.sh authoring
  concern, not a README contributor concern.

The note is 7 lines (one paragraph). Not strictly "single-line" but
the smallest discoverable explanation that covers (a) why v11-* rows
churn, (b) what `git blame` will misleadingly show, and (c) the
recommended hygiene.

**Edit (build.sh, lines 724-733):**

Added before the `_update_manifest()` definition:
```bash
# Write or update manifest.txt with current SHAs.
#
# v11-* row SHAs drift naturally with any pack-product change to v11
# surface (template files, scripts, skills, agents, etc.) — see README
# "Determinism" §. Result: a `git blame` on a v11-* manifest row often
# points at an unrelated BD that happened to run `--all` and stage the
# regenerated row. v10-* row SHAs are tag-pinned and only drift if the
# v10 tag itself moves. When committing manifest changes for a BD whose
# scope does NOT include the v11 surface, prefer staging only the
# in-scope rows to keep the BD commit's diff faithful.
_update_manifest() {
```

---

### F4 — Orphan shim removal (NIT)

**Finding (verbatim from retro §3 F4):**
> `_build_v10_realistic_ot` shim is preserved without an active external
> caller — orphan-shim hygiene … Caller grep confirms zero such callers
> exist today. The shim costs one indirection layer and creates a latent
> Trinity-of-naming problem (two function names that do exactly the
> same thing — composition #4 violation).

**Path chosen:** removal (per scope clarification: "minimal fix is
straightforward removal. Verify no caller before deleting"). Caller
verification command + output below in §4 Verification.

**Edits:**

(1) Delete the shim function (lines 351-357 of original build.sh):
```bash
# Backwards-compat shim: existing dispatcher + any external callers
# that name the v10-specific function continue to work. Delegates to
# the parameterized builder. Safe to remove once no caller uses the
# v10-named entry point.
_build_v10_realistic_ot() {
    _build_realistic_for_version v10
}
```

(2) Inline the dispatcher case (line 691 of original):

Before:
```bash
        v10-realistic-ot)          _build_v10_realistic_ot ;;
```
After:
```bash
        v10-realistic-ot)          _build_realistic_for_version v10 ;;
```

(3) Drop the README "legacy entry point preserved as a thin wrapper"
sentence (lines 164-165 of original README) — folded into the F5 edit
below.

---

### F5 — README BD-120 subsection wiring-steps omission (NIT)

**Finding (verbatim from retro §3 F5):**
> README wording at line 140-142 implies all per-version realistic-OT
> siblings extend the same function, but FIXTURE_NAMES + dispatcher
> gating is omitted from the procedure … A future contributor … would
> extend `_build_realistic_for_version`'s case blocks per the BD-120
> subsection, then run `bash build.sh --name v12-realistic-ot`, and
> get `error: unknown fixture` from line 695.

**Path chosen:** the reviewer's recommended 4-step checklist, with
absorbed F1 truth-update on step 4 and absorbed F4 wrapper-removal
(removed the now-dead "legacy entry point preserved" sentence). One
fold, one section.

**Edit (README.md, "Realistic-OT fixtures: per-version pattern (BD-120)"):**

Before (15 lines, lines 154-168):
```
### Realistic-OT fixtures: per-version pattern (BD-120)

The realistic-OT family uses a single parameterized builder,
`_build_realistic_for_version <vN>`, that applies the same four
canonical OT-style customizations (trinity project-name fills,
`model_providers.ollama` removed, `x-`-prefixed custom agent on all
3 CLIs, TD-NNN BACKLOG.md) against any pack version's install. To add
a `vN-realistic-ot` sibling for a future version, extend the per-
version `case` blocks inside `_build_realistic_for_version` (source
setup + init runner) — the customization patterns themselves are
version-agnostic. The legacy `_build_v10_realistic_ot()` entry point
is preserved as a thin wrapper for backwards compatibility. The
per-version customization-surface declaration lives in
`scripts/lib/migrator-core.sh::migrator_target_surface_for_version`
(BD-119).
```

After (40 lines):
```
### Realistic-OT fixtures: per-version pattern (BD-120)

The realistic-OT family uses a single parameterized builder,
`_build_realistic_for_version <vN>`, that applies the same four
canonical OT-style customizations (trinity project-name fills,
`model_providers.ollama` removed, `x-`-prefixed custom agent on all
3 CLIs, TD-NNN BACKLOG.md) against any pack version's install. The
customization patterns themselves are version-agnostic; per-version
dispatch is confined to source-clone setup and which `_run_vN_init`
runner to invoke.

To add a `vN-realistic-ot` sibling for a future version:

1. Extend the two per-version `case` blocks inside
   `_build_realistic_for_version` (source setup + init runner).
2. Add `vN-realistic-ot` to the `FIXTURE_NAMES` array near the top
   of `build.sh`.
3. Add `vN-realistic-ot) _build_realistic_for_version vN ;;` to the
   `_build_one` dispatcher case.
4. If vN's surface differs from v10/v11 for the C1–C4 customization
   patterns (e.g., `.codex/config.toml` location moves, agent dirs
   relocate), re-verify each pattern against
   `migrator_target_surface_for_version vN` in
   `scripts/lib/migrator-core.sh`. That helper is the per-version
   customization-surface ground truth; the BD-120 builder hardcodes
   the v10/v11 paths inline rather than consuming the helper, so any
   surface change in a future vN must be reflected by hand in the
   builder's customization steps.

Status: v10 wired and exercised (`v10-realistic-ot` fixture); v11
case body is currently a fail-loud sentinel pending BD-160 (the BD
that wires `v11-realistic-ot` into `FIXTURE_NAMES` + dispatcher and
re-verifies C2/C3 against the v11 surface).

Per-version determinism asymmetry: `v10-realistic-ot` is built from
the v10 git tag (byte-identity stable across rebuilds, like
`v10-minimal`); a future `v11-realistic-ot` will track the current
pack `HEAD` (SHA drifts with every pack-product change to v11
surface, like `v11-flat-file` / `v11-tracker-on`). See the
**Determinism** section above.
```

The F5 absorption also covers F1 (truthful step 4 instead of misleading
"declaration lives in" pointer), F2 (Status callout signals v11 is
unwired pending BD-160), F4 (legacy wrapper sentence removed since the
shim no longer exists), and F6 (Determinism asymmetry note for
contributors).

---

### F6 — Per-version source-pin asymmetry not documented (NIT)

**Finding (verbatim from retro §3 F6):**
> `_run_v11_init` runs the CURRENT pack HEAD, not a tagged v11 — fixture-
> determinism semantics for the v11 dispatch path differ from v10's …
> the `_build_realistic_for_version` docstring at lines 177-198 does not
> note the asymmetry between the v10 case (tag-pinned) and the v11 case
> (HEAD-tracking).

**Path chosen:** docstring-only addition to `_build_realistic_for_version`
(reviewer's recommended fix, applied verbatim with light prose tightening).
Also surfaced in the README "Determinism asymmetry" callout per F5.

**Edit (build.sh, `_build_realistic_for_version` docstring lines 204-215
of new file):**

Added between the dispatch description and "Add a new vN…":
```bash
# Per-version source-pin semantics (invariant for BD-160 / BD-170 +
# future vN extension):
#   v10: source pinned to the v10 git tag via `_setup_v10_pack_src`
#        (byte-identity stable across rebuilds; same model as
#        `v10-minimal`).
#   v11: source tracks current pack HEAD via `_run_v11_init`
#        (SHA drifts with every pack-product change to v11 surface;
#        same model as `v11-flat-file` / `v11-tracker-on` — see
#        README.md "Determinism" §). When a future version freezes
#        v11 (e.g., when v12 ships and v11 becomes a frozen tag),
#        add a v11-tag-cloned source path mirroring
#        `_setup_v10_pack_src`.
```

---

## 3. Files modified

| Path | Change type | Line delta (insertions / deletions) |
|---|---|---|
| `test-fixtures/build.sh` | modified | +48 / -16 |
| `test-fixtures/README.md` | modified | +34 / -9 |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-120-RETRO-FIX.md` | new | (this file) |

No other files touched. No new files outside the report. No deletes.

---

## 4. Verification

### 4.1 F4 caller-grep proof (zero callers in live code)

Command run:
```
grep -RIn '_build_v10_realistic_ot' test-fixtures/ scripts/ .github/
```
Output:
```
(empty)
```

For full disclosure, the unscoped grep (entire repo) returns the following
matches — all are documentation / archive / BACKLOG references, none are
executable callers:

```
BACKLOG.md:1262                                       (BD-120 description prose)
BACKLOG.md:1270                                       (BD-120 Resolved: prose)
test-fixtures/README.md:164                           (was the "legacy entry
                                                       point preserved" sentence
                                                       — REMOVED in this fix's
                                                       F5 edit; if grep still
                                                       shows this, the line
                                                       below is stale)
maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-128.md:80
                                                       (historical reference)
maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-120.md:*
                                                       (original BD-120 IMPL
                                                       report — describes the
                                                       refactor's history)
maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md:610
                                                       (architecture doc cite
                                                       to the OLD function name)
maintenance-docs/v11-implementation/PACK-REVIEW-BD-120-RETRO.md:*
                                                       (this fix's source
                                                       review — discusses the
                                                       shim by name)
maintenance-docs/v11-implementation/PACK-REVIEW-BD-120.md:*
                                                       (original BD-120 review
                                                       — historical)
```

Re-running after the F4 + F5 edits, the README match at line 164 is
gone (verified by reading the updated file). All remaining matches are
in archive/, IMPL-REPORT, ARCH, BACKLOG, and PACK-REVIEW prose — none
are bash-callable references. F4 deletion is therefore safe.

### 4.2 build.sh syntax check

Command:
```
bash -n test-fixtures/build.sh
```
Output: (no output; exit 0). Captured locally:
```
$ bash -n test-fixtures/build.sh && echo "SYNTAX OK"
SYNTAX OK
```

### 4.3 Diff stat

```
$ git diff --stat test-fixtures/build.sh test-fixtures/README.md
 test-fixtures/README.md | 43 ++++++++++++++++++++++++++-------
 test-fixtures/build.sh  | 64 ++++++++++++++++++++++++++++++++++++-------------
 2 files changed, 82 insertions(+), 25 deletions(-)
```

Numstat:
```
$ git diff --numstat test-fixtures/build.sh test-fixtures/README.md
34	9	test-fixtures/README.md
48	16	test-fixtures/build.sh
```

### 4.4 BD-160 / BD-170 forward-compat preservation

Per BD-170 BACKLOG entry (line 1384, line 1393): "Combined commit
shipping BD-160 (v11 case dispatch + C2/C3 customization re-verification
on v11 surface) + BD-170 (per-entry tree extension + round-trip test) …
Both BDs are v11-realistic-ot fixture surface work and share the same
dependency on BD-164 helpers".

This fix preserves BD-160/BD-170 forward-compat in three ways:
1. **F1:** the README step-4 explicitly names
   `migrator_target_surface_for_version vN` as the surface to verify
   against — BD-160 will follow this exact pointer when re-verifying
   C2/C3 paths on v11. The fix removes the "is consumed by" claim but
   keeps the helper's role as the BD-160 reference surface.
2. **F2:** the `die` sentinel is a single named line for BD-160 to
   replace. The second case block has a placeholder comment marking
   where BD-160 wires `_run_v11_init`. BD-160 has fewer moving parts
   to reconstruct than option-(a) "remove the entire v11 case" would
   have left.
3. **F6:** the docstring's per-version source-pin invariant explicitly
   anticipates BD-160's v11 case (HEAD-tracking) and a future v12-era
   v11-tag-cloned migration ("when a future version freezes v11 … add
   a v11-tag-cloned source path mirroring `_setup_v10_pack_src`").
   This documents the invariant BD-160 must respect when it wires the
   v11 case body.

No changes to `scripts/lib/migrator-core.sh`, `_build_one` dispatcher
beyond the F4 single-token inline (`_build_realistic_for_version v10`
in place of the deleted shim name), or any sibling fixture builder.

---

## 5. Out-of-scope items (Pack Chat decides tracking)

Per the deferred-work-must-be-tracked rule from the prompt, surfacing
items I noticed but did not act on:

1. **`scripts/lib/migrator-core.sh::migrator_target_surface_for_version`
   docstring still claims "Used by BD-120 fixture parameterization"**
   (line 462). Post-F1 fix, the helper has zero live callers. The
   prompt explicitly forbade editing `migrator-core.sh`, so the
   docstring drift is unresolved. BD-160 is the natural fix vehicle
   (BD-160 wires the v11 case AND would consume the helper to drive
   per-version surface verification, restoring the "Used by BD-120-derived
   fixture parameterization" claim's truth). Pack Chat: consider
   whether to (a) update the helper's docstring as a separate hygiene
   commit, (b) leave the claim for BD-160 to validate when it lands, or
   (c) annotate BD-160's BACKLOG entry to call this out. I did not
   touch BACKLOG.

2. **F4 follow-on POQ-BD-120-1 disposition** — the original IMPLEMENTATION-
   REPORT-BD-120 §7 recorded the shim sunset as "defer until v11-realistic-ot
   is actually wired (separate BD)". This fix retires the shim early
   (per the scope clarification's "F4 minimal fix is straightforward
   removal"). POQ-BD-120-1 is therefore now closed. Pack Chat may want
   to record this in BD-160's File/Symbol field (since BD-160 no longer
   needs to "fold the cleanup in" — it's already done). I did not touch
   BACKLOG.

3. **README line 164 historical mention of `_build_v10_realistic_ot`
   in the BD-120 subsection** — removed by F5 edit. Confirmed no other
   live README/template references to the shim exist. Verified via grep
   in §4.1.

4. **BD-160 BACKLOG entry line 1556 references `[[ -f ]]` guard at
   `test-fixtures/build.sh` line 226** — line numbers in the BD-160
   entry will drift after this commit because this fix added ~32 net
   lines to build.sh above line 226. The line-number reference will
   point a few dozen lines off. Mostly cosmetic; BD-160's coder will
   re-grep for the actual `[[ -f ]]` site. Not in scope for this fix
   (BD-160 BACKLOG edit is PM-only).

5. **`maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md` §9.2**
   describes the helper as a BD-120-consumer-facing contract. After
   this fix, the architectural intent is partially deferred to BD-160
   (the helper's "first real consumer" role moves from BD-120 to
   BD-160 per F1's option (b) framing). Architect-pass review may want
   to annotate ARCHITECTURE-BD-119.md §9.2 with a note that BD-120
   deferred the consume step to BD-160. Not in scope for this fix
   (architecture-doc edit, not a coder action).

End of report.
