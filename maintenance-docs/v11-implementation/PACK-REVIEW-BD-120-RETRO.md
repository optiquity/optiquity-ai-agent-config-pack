# PACK-REVIEW-BD-120-RETRO — Retroactive per-BD review (Batch 21c)

**BD under review:** BD-120 — Parameterize realistic-OT fixture generator for any vN
**Anchor commit:** `3fa3322` ("feat: v11 — BD-120 parameterize realistic-OT fixture generator for any vN (Phase 3.5 Batch 3a)")
**Branch:** `v11-dev`
**Reviewer:** pack-reviewer (retro pass; NO prior-review docs consulted per prompt rule)
**Date:** 2026-05-15
**Methodology:** `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` — six dimensions + touch-point classification

---

## 1. Scope declaration

### 1.1 In-scope

- **Concept:** parameterized realistic-OT fixture generator + per-version dispatch surface
- **Files (per `git show --stat 3fa3322`):**
  - `test-fixtures/build.sh` (+61/-9; refactor `_build_v10_realistic_ot` → `_build_realistic_for_version <vN>` + shim + v11 dispatch case)
  - `test-fixtures/README.md` (+16; "Realistic-OT fixtures: per-version pattern" subsection)
  - `test-fixtures/manifest.txt` (+4/-2; mechanical regen)
  - (companion docs in commit but per prompt rule out-of-scope: `IMPLEMENTATION-REPORT-BD-120.md`, `PACK-REVIEW-BD-120.md`)

### 1.2 Out of scope

- BD-160 (carry-forward of NIT 2 from prior review — wires `v11-realistic-ot` into FIXTURE_NAMES + dispatcher, plus C2/C3 v11-surface re-verification). Tracked separately; explicitly excluded by prompt.
- BD-116 (persona-contract that consumes v10-realistic-ot — separate retro slot in Batch 21c group D).
- BD-119 architecture (the parent framework). BD-120's relationship to BD-119 is in scope only as far as design-intent invariants documented in `ARCHITECTURE-BD-119.md` §9.

### 1.3 Touch-point matrix

| Touch point | Class | Other concept(s) reading/writing |
|---|---|---|
| `test-fixtures/build.sh::_build_realistic_for_version` | OWNED | BD-120 owns; BD-160 will extend the v11 case |
| `test-fixtures/build.sh::_build_v10_realistic_ot` (shim) | SHARED-RO | dispatcher line 691 calls it; BD-116 persona-contract calls dispatcher; documented retire path |
| `test-fixtures/build.sh` `FIXTURE_NAMES` array | SHARED-RW | BD-160 will add `v11-realistic-ot`; BD-115/116/117 add other entries |
| `test-fixtures/build.sh::_build_one` dispatcher case | SHARED-RW | adding new realistic-OT fixtures requires new case rows; BD-160 |
| `_run_v10_init` / `_run_v11_init` helpers | SHARED-RO | BD-120 reads only; BD-115/116 also call these |
| `_setup_v10_pack_src` (only v10 path) | SHARED-RO | BD-120 reads only; BD-128 added the sweep work-around |
| `migrator_target_surface_for_version` (in `scripts/lib/migrator-core.sh`) | CONTRACT | BD-119 owns the helper; BD-120 was intended to consume it (per ARCH §9.2); BD-120 implementation does NOT consume — contract drift |
| `test-fixtures/README.md` "Adding a new fixture" + "Realistic-OT…" sections | OWNED | BD-120 maintains; BD-160 extends table row |
| `test-fixtures/manifest.txt` v10-realistic-ot row | OWNED | BD-120 byte-identity invariant; auto-regenerated |
| `test-fixtures/manifest.txt` v11-* rows | SHARED-RW | naturally drift with v11 surface; BD-143..158, BD-156/157/158 all touched these |
| `_materialize_for_contract migration` path → `v10-realistic-ot` | SHARED-RO | BD-116 contract (lines 805-813) reads the BD-120 fixture name verbatim |

---

## 2. Methodology notes

- Read `BACKLOG.md` BD-120 + BD-160 + BD-170 (carry-forward / dependency context) + BD-128 (CI-fix sequencing context).
- Read `IMPLEMENTATION-REPORT-BD-120.md` (in-scope per prompt).
- Read `ARCHITECTURE-BD-119.md` §9 (design intent for BD-120).
- Read `EXECUTION-PLAN-V11.0.md` Batch-3 row + Batch 21c row.
- Read `supporting-docs/CONCEPTUAL-REVIEW-METHODOLOGY.md` (review framework).
- Did NOT read `PACK-REVIEW-BD-120.md` or any sibling BD review (prompt prohibition).
- `git show 3fa3322 -- test-fixtures/{build.sh,README.md,manifest.txt}` to confirm shipped diffs.
- Live `grep` of repo for cross-references to `_build_realistic_for_version`, `_build_v10_realistic_ot`, `v10-realistic-ot`, `v11-realistic-ot`, `migrator_target_surface_for_version`, `FIXTURE_NAMES`.
- Read current `test-fixtures/build.sh` lines 1-870, `test-fixtures/README.md` whole file, `scripts/lib/migrator-core.sh` lines 455-513, `scripts/persona-contracts/contract-migration.sh` lines 25-75 to map cross-concept impact.
- No state-changing commands run; no Edit/Write outside this report file.

---

## 3. Findings

### F1. Architecture-design helper `migrator_target_surface_for_version` is referenced in docs but NOT consumed by the implementation (contract drift)

- **Severity:** SHOULD
- **Dimension:** (d) Pack rule adherence — design-intent compliance to ARCH §9.2 + (e) Design best practice — Single source of truth
- **Touch-point class:** CONTRACT (helper-as-contract between fixture builder and per-version surface declaration)
- **Evidence:**
  - `maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md` §9.2 lines 621-650:
    > **`migrator_target_surface_for_version <vN>` (proposed core helper).** Echo the relative paths a vN install creates that a fixture builder needs to mutate […] The fixture builder applies the patterns; the helper just tells it where the targets live in this version. **This avoids duplicating "what does v11 ship?" knowledge across `init-project.sh`, `migrate-vN-to-vM.sh`, and `build.sh`.** […] **Decision:** ship the helper as part of BD-119 — one-line addition to the core's public surface, removes a future drift risk for free.
  - `scripts/lib/migrator-core.sh` lines 459-513 — helper exists, returns the per-version surface list (v10: 8 paths; v11: 14 paths), explicit comment line 462 "Used by BD-120 fixture parameterization".
  - `test-fixtures/build.sh` — no `source` of `scripts/lib/migrator-core.sh`; no call to `migrator_target_surface_for_version`. Confirmed via grep of full file (`grep -n "source\|migrator-core\|migrator_target_surface\|scripts/lib" test-fixtures/build.sh` returns zero matches).
  - The customization paths are hardcoded inline: `.codex/config.toml` (line 239), `.claude/agents/x-fakeot-domain.md` (line 256), `.gemini/agents/x-fakeot-domain.md` (line 271), `.codex/agents/x-fakeot-domain.toml` (line 272), `BACKLOG.md` (line 280), trinity files (line 228).
  - `test-fixtures/README.md` line 156-158 actively misleads on this:
    > The per-version customization-surface declaration lives in `scripts/lib/migrator-core.sh::migrator_target_surface_for_version` (BD-119).

    A reader follows that pointer expecting build.sh to consume the helper; it does not.
- **Description:** BD-119's architecture explicitly designed `migrator_target_surface_for_version` as the BD-120-consumer-facing contract — the helper exists with v10/v11 cases, was shipped specifically for this BD ("Used by BD-120 fixture parameterization", line 462), and was justified as "removes a future drift risk for free." BD-120's implementation shipped the parameterized dispatcher but did NOT wire the helper into the customization-pattern body. The result is exactly the duplication the architecture warned against: when v12 lands and adds (say) `.config/codex.toml` as the new ollama location (or removes ollama entirely), the surface declaration in `migrator-core.sh::v11)` case would correctly say "no `.codex/config.toml` in v12" but `_build_realistic_for_version` would still hardcode `.codex/config.toml` and silently no-op via the `[[ -f ]]` guard at line 239 — the C2 customization would silently disappear from the v12 fixture without any failure signal. The `[[ -f ]]` defensive guard is a foot-gun that masks the regression. The README pointer at line 156-158 implies the helper is consumed when it is not — this is documentation drift that will mislead future maintainers (BD-160 implementer in particular).
- **Suggested fix:** One of:
  - **(a) Wire the helper now (preferred per ARCH).** Source `scripts/lib/migrator-core.sh` from `build.sh`, call `migrator_target_surface_for_version "$ver"` to validate the four customization paths exist in the surface list before applying, fail-loud with a named error message if any expected path is missing from the surface (e.g., "C2 ollama-strip path `.codex/config.toml` not in v12 surface — fixture pattern needs re-verification per BD-120 NIT 2 / BD-160"). Replace the `[[ -f ]]` defensive guard at line 239 with a positive assertion.
  - **(b) Remove the helper claim from the README and from the helper's docstring.** If BD-120 deliberately chose not to consume the helper (the IMPLEMENTATION-REPORT does not mention the architecture §9.2 decision either way), update README.md line 156-158 to drop the misleading pointer, update `migrator-core.sh` line 462 to drop "Used by BD-120 fixture parameterization", and document in BD-120's BACKLOG entry that the architecture-design helper was deferred. This restores doc-truth correspondence even if the underlying duplication remains.
- **Cross-concept impact:** BD-119 (helper now has zero callers — option (b) might re-frame it as planned-for-BD-160), BD-160 (will inherit this decision; the BD-160 BACKLOG entry already references the helper as the v11-surface ground truth, so option (a) is the cleanest setup), the persona-contract `contract-migration.sh` (which depends on knowing the customization surface to assert post-migration; making the surface explicit via the helper benefits this consumer too).
- **Rule/principle violated:**
  - Pack design best practice #1 "Single source of truth" (CONCEPTUAL-REVIEW-METHODOLOGY.md "Design best practices" table).
  - ARCH §9.2 design intent ("removes a future drift risk for free").

### F2. v11 dispatch case (lines 209-211 + 222) is reachable from `_build_realistic_for_version v11` but unreachable via the `--name` CLI; failure-loudness gap on the CLI side

- **Severity:** SHOULD
- **Dimension:** (a) Completeness — the v11 path is in scope per the BD ("Refactor into `_build_realistic_for_version <vN>`") + (f) Concept-specific — fixture-generator failure-loudness on mis-specified inputs
- **Touch-point class:** SHARED-RW (FIXTURE_NAMES + dispatcher case both need extension to expose v11)
- **Evidence:**
  - `test-fixtures/build.sh` line 49-55 `FIXTURE_NAMES` array: contains 5 entries; `v11-realistic-ot` is NOT one of them.
  - `test-fixtures/build.sh` line 689-696 `_build_one` dispatcher case: 5 entries; no `v11-realistic-ot)` row.
  - `test-fixtures/build.sh` line 199-215 / line 220-223: the function-level v11 dispatch path exists and is callable via direct shell function invocation.
  - Result: a contributor running `bash test-fixtures/build.sh --name v11-realistic-ot` gets `error: unknown fixture: v11-realistic-ot (known: v10-minimal v10-realistic-ot v11-flat-file v11-tracker-on existing-project-mid-dev)` (line 695), which correctly fails loud — but does NOT mention that the v11 path exists at the function level and only needs FIXTURE_NAMES + dispatcher extension. The error misleads the contributor into thinking parameterization for v11 is unimplemented, when in fact it is implemented but unwired.
  - The function-level v11 path is currently dead code per the BD-160 entry's own characterization ("currently dead code", BACKLOG line 1555). Dead code at landing time without an executable test path is a BD-120 completeness gap, not just a BD-160 wire-up task.
- **Description:** BD-120's success criteria #3 in IMPLEMENTATION-REPORT-BD-120.md §2.4 explicitly carves out the v11 fixture wiring as a "two-line addition when the v11-realistic-ot fixture is needed" and defers it. That deferral is defensible (BD-160 is the proper vehicle), but the user-facing CLI surface offers no signal that the v11 dispatch path exists. The BD landed a refactor whose v11 branch has zero test coverage (none of the listed test runs exercise the `ver=v11` case), zero CLI exposure (dispatcher rejects the name), and only one consumer (the function itself, called with `v11`, which in turn would silently produce an incomplete fixture per BD-160's analysis of C2/C3 v11-surface drift). The cleanest interpretation: the v11 case in `_build_realistic_for_version` is structurally aspirational rather than functionally complete. Either it should be removed (and BD-160 adds it) OR its incompleteness should be guarded by a fail-loud sentinel.
- **Suggested fix:** One of:
  - **(a) Remove the v11 case body from `_build_realistic_for_version`** and let `*) die` catch v11 too. Reduces line count and removes dead-code surface; BD-160 adds the v11 case alongside the FIXTURE_NAMES + dispatcher extension and the C2/C3 verification it actually owns. This is the minimal, lowest-risk fix for retro.
  - **(b) Keep the v11 case body but tag it with an explicit `die` until BD-160 lands.** Wrap line 210 + 222 in:
    ```bash
    v11)
        die "_build_realistic_for_version v11: unwired pending BD-160 (C2/C3 v11-surface verification + FIXTURE_NAMES + dispatcher case)" 4
        ;;
    ```
    Until BD-160 lands, no one accidentally invokes the path; when BD-160 lands, the `die` is replaced with the production body.
  - **(c) Document the v11 dispatch path is intentionally unwired in the README "Realistic-OT fixtures: per-version pattern" subsection.** Currently the README at lines 144-158 reads as if the v11 path is production-ready. Add a one-sentence "Status: v10 wired; v11 case deferred to BD-160" callout. Smallest-footprint fix; preserves all the existing v11 scaffolding.
- **Cross-concept impact:** BD-160 (its work surface shrinks if (a) is chosen; expands if (b)/(c)), CI test-fixture builds (no impact today since no caller).
- **Rule/principle violated:**
  - V3.3 §5.6 "no silent retry / no silent fallback" — the `[[ -f ]]` guard at line 239 + the unwired-but-callable v11 body together produce a silent partial-fixture if directly invoked.
  - Pack failure-loudness convention (CONCEPTUAL-REVIEW-METHODOLOGY.md "Race-condition detection heuristic" + "When to tag ARCH" §3.6).

### F3. `manifest.txt` v11-* SHA drift was committed with BD-120 but originates from BD-143..BD-158 — coupling violates separation-of-concerns

- **Severity:** NIT
- **Dimension:** (d) Pack rule adherence — commit-scope discipline + (e) Design best practice — separation of concerns
- **Touch-point class:** SHARED-RW (`manifest.txt` is touched by every batch that moves v11 surface; BD-120 commit landed v11-flat-file SHA `e54ab38…` and v11-tracker-on SHA `ae6f0ae…` that are products of BD-143..BD-158, NOT BD-120)
- **Evidence:**
  - Commit `3fa3322` diff for `test-fixtures/manifest.txt` shows v11-* rows changed:
    ```
    -v11-flat-file  39e8978d120d55e0d70123e867292ec19d5f6139
    -v11-tracker-on  e4317694550f18516ea47dc1f92e7f5cc0342cf3
    +v11-flat-file  e54ab38fbb5d0099826b384de3c39d61bd7cb171
    +v11-tracker-on  ae6f0ae6d8fb3b27c29d1ba8a61e2af12edaac2f
    ```
  - IMPLEMENTATION-REPORT-BD-120.md §4.1.1 acknowledges the drift is "pre-existing and NOT caused by BD-120" and traces it to "BD-143, BD-144, BD-145, BD-146, BD-147, BD-148, BD-149, BD-156, BD-157, BD-158".
  - IMPLEMENTATION-REPORT §10 "Notes for Pack Chat" line 374 actively flagged this as a Pack Chat decision: "alternative: stage only the BD-120 functional changes and let manifest update with a future BD".
  - Pack Chat (or the agent) chose to fold the drift into the BD-120 commit anyway.
- **Description:** This is a low-impact NIT but worth surfacing for future-batch hygiene. BD-120's scope per BACKLOG is "Refactor `_build_v10_realistic_ot` …"; the v11-* SHA drift in `manifest.txt` is collateral from unrelated BDs. Folding it into the BD-120 commit means the BD-120 commit's diff is no longer a faithful representation of "what BD-120 did" — a `git blame` on those v11-* SHA rows points at BD-120 even though BD-120 did not produce them. This is mostly a record-keeping concern and the IMPLEMENTATION-REPORT documents the coupling clearly, so the audit trail is intact. The general principle for future maintenance work that auto-regenerates artifacts: stage only the artifact rows the BD intended to change; let an explicit hygiene commit (or the next BD that legitimately moves v11-* surface) capture the rest. The current state is acceptable — flag for future-batch awareness only.
- **Suggested fix:** No retroactive action. Document the commit-scope discipline as a maintenance-mechanical convention in `CLAUDE.md` "Pack memory > Repo conventions" or in `test-fixtures/README.md`'s "Determinism" section: "When `build.sh --all` regenerates `manifest.txt` rows that are not in scope for the current BD, prefer to stage only the in-scope rows and let an explicit hygiene commit capture the rest." (Out-of-session note for the user; do not file a new BD per the standing fix-all-or-defer policy. If accepted, this would land in a future hygiene batch — not in BD-120-RETRO scope.)
- **Cross-concept impact:** Future maintenance batches that touch fixtures (BD-160 / BD-170 in particular). No runtime / behavioral impact.
- **Rule/principle violated:** Pack convention "BD scope discipline" (implicit in `CLAUDE.md` "Rules for agents working on this repo" — agents may modify "Files in supporting-docs/ or maintenance-docs/ when the task explicitly requires it"; `manifest.txt` v11-* row update was not explicitly required by BD-120's task statement).

### F4. `_build_v10_realistic_ot` shim is preserved without an active external caller — orphan-shim hygiene

- **Severity:** NIT
- **Dimension:** (e) Design best practice — composition over special cases / dead-code minimization
- **Touch-point class:** OWNED
- **Evidence:**
  - `test-fixtures/build.sh` lines 351-357: shim function.
  - `test-fixtures/build.sh` line 691: dispatcher calls `_build_v10_realistic_ot` (the shim) rather than `_build_realistic_for_version v10` directly.
  - IMPLEMENTATION-REPORT-BD-120.md §1.3 grep results show only one live caller — the in-file dispatcher itself. POQ-BD-120-1 (§7) recorded "Should `_build_v10_realistic_ot` shim be sunset once a v11-realistic-ot fixture lands? Disposition: defer until v11-realistic-ot is actually wired (separate BD)."
  - The shim's stated purpose (line 351-354 docstring): "any external callers that name the v10-specific function continue to work." No such external callers are demonstrated anywhere in the repo.
- **Description:** The shim is a defense against hypothetical external callers (test harness, dog-food script). Caller grep confirms zero such callers exist today. The shim costs one indirection layer and creates a latent Trinity-of-naming problem (two function names that do exactly the same thing — composition #4 violation). The IMPLEMENTATION-REPORT correctly identified this as a deferred-to-future-BD question. This NIT records the shim as a maintenance-tax item that should be sunset opportunistically when BD-160 (v11-realistic-ot wiring) ships, since BD-160 will already be touching the dispatcher case rows anyway.
- **Suggested fix:** No retroactive action. Document a note in `BACKLOG.md` BD-160 entry's File/Symbol field: "While extending the dispatcher for `v11-realistic-ot)`, also retire the `_build_v10_realistic_ot` shim by changing the dispatcher row to `v10-realistic-ot) _build_realistic_for_version v10 ;;` and deleting the shim — single-commit cleanup per IMPLEMENTATION-REPORT-BD-120 POQ-BD-120-1." Since BACKLOG edits are PM-only, this is a Pack-Chat action; the retro report flags it for that path.
- **Cross-concept impact:** BD-160 (one extra one-line cleanup folded in).
- **Rule/principle violated:** None directly; design-best-practice composition #4 (avoid two names for one operation; converge on uniform mechanism).

### F5. README wording at line 140-142 implies all per-version realistic-OT siblings extend the same function, but FIXTURE_NAMES + dispatcher gating is omitted from the procedure

- **Severity:** NIT
- **Dimension:** (a) Completeness — procedure-doc completeness for the contributor flow
- **Touch-point class:** OWNED
- **Evidence:**
  - `test-fixtures/README.md` lines 140-142:
    > **For a new realistic-OT version** (`v11-realistic-ot`, `v12-realistic-ot`, ...), do NOT add a per-version `_build_<name>()` function — extend the per-version subsection below instead.
  - `test-fixtures/README.md` lines 144-158 (the BD-120 subsection) describes only the `case` block extension and the customization-pattern version-agnosticism. It does NOT describe the two REQUIRED additional steps:
    1. Add the new fixture name to the `FIXTURE_NAMES` array (line 49-55) so `--all` and `--verify` discover it.
    2. Add a new dispatcher case row in `_build_one` (line 689-696) so `--name vN-realistic-ot` resolves to the parameterized builder.
  - The general "Adding a new fixture" procedure at lines 129-138 has these two steps for non-realistic-OT fixtures (steps 2 and the implicit dispatcher edit), but the realistic-OT subsection's "extend the per-version `case` blocks" instruction omits the wiring side.
  - BD-160's own description in BACKLOG (line 1556-1557) had to enumerate these two steps explicitly because the README does not.
- **Description:** A future contributor following the README to add `v12-realistic-ot` would extend `_build_realistic_for_version`'s case blocks per the BD-120 subsection, then run `bash build.sh --name v12-realistic-ot`, and get `error: unknown fixture` from line 695. They would have to grep for FIXTURE_NAMES and `_build_one` independently. The procedure documentation is incomplete for the parameterized-builder flow.
- **Suggested fix:** Extend the BD-120 subsection in `test-fixtures/README.md` (lines 144-158) with a short explicit checklist of the THREE wiring steps:
  ```
  To add a new vN realistic-OT sibling:
  1. Extend the two per-version `case` blocks in `_build_realistic_for_version` (source setup + init runner).
  2. Add `vN-realistic-ot` to the `FIXTURE_NAMES` array (see top of build.sh).
  3. Add `vN-realistic-ot) _build_realistic_for_version vN ;;` to the `_build_one` dispatcher case.
  4. (If vN's surface differs from v10/v11 for the C1-C4 customization patterns,
     re-verify each pattern against `migrator_target_surface_for_version vN`.)
  ```
  This brings the realistic-OT subsection up to parity with the general "Adding a new fixture" procedure and removes the implicit knowledge gap that BD-160 had to compensate for.
- **Cross-concept impact:** BD-160 implementer benefits from clearer procedure (closes a small documentation race that would otherwise be pure rediscovery cost).
- **Rule/principle violated:** Pack convention "documentation must enumerate the procedure such that an outside contributor can execute it without grep" (implicit; CONCEPTUAL-REVIEW-METHODOLOGY.md dimension (a)).

### F6. `_run_v11_init` runs the CURRENT pack HEAD, not a tagged v11 — fixture-determinism semantics for the v11 dispatch path differ from v10's

- **Severity:** NIT
- **Dimension:** (f) Concept-specific — vN parameterization symmetry / determinism invariant
- **Touch-point class:** SHARED-RO (`_run_v11_init` is owned by build.sh; the BD-120 v11 dispatch path consumes it)
- **Evidence:**
  - `test-fixtures/build.sh` lines 115-127:
    ```
    _run_v10_init() { ... PACK="$v10_src" bash "$v10_src/scripts/init-project.sh" ... }
    _run_v11_init() { ... PACK="$PACK_ROOT" bash "$PACK_ROOT/scripts/init-project.sh" ... }
    ```
  - v10 path uses a v10-tag-cloned isolated source tree (via `_setup_v10_pack_src`). v11 path uses the live `$PACK_ROOT`.
  - `test-fixtures/README.md` lines 105-110 acknowledge this for v11-flat-file / v11-tracker-on:
    > For `v11-*` fixtures: SHAs change whenever the pack's current `HEAD` changes the v11 surface
  - But the BD-120 v11 dispatch path inherits this semantics WITHOUT a documented note that "v11-realistic-ot" would also drift with HEAD changes — unlike v10-realistic-ot which is byte-identity-stable per the v10 tag pin.
- **Description:** When BD-160 wires `v11-realistic-ot` and the fixture starts being built, its determinism profile will diverge from v10-realistic-ot's: each push that touches v11 surface (almost any pack-product change) will move `v11-realistic-ot`'s SHA, whereas `v10-realistic-ot` stays frozen. This is correct behavior (matching v11-flat-file / v11-tracker-on) but the `_build_realistic_for_version` docstring at lines 177-198 does not note the asymmetry between the v10 case (tag-pinned) and the v11 case (HEAD-tracking). The IMPLEMENTATION-REPORT does not surface this either — yet it is a cross-version invariant of the parameterized builder that the BD-120 surface is designed to expose.
- **Suggested fix:** Add a one-paragraph note to the `_build_realistic_for_version` docstring (around line 192-198) documenting the per-version source-pin semantics:
  ```
  # Per-version source semantics:
  #   v10: source pinned to the v10 git tag (byte-identity stable across rebuilds).
  #   v11: source tracks current pack HEAD (SHA drifts with every pack-product
  #        change to v11 surface; matches v11-flat-file / v11-tracker-on
  #        semantics — see README.md "Determinism" §).
  #   When future versions tag v11 (e.g., when v12 ships and v11 freezes),
  #   add a v11-tag-cloned source path mirroring _setup_v10_pack_src.
  ```
  This codifies an invariant that is currently implicit and prevents a BD-160 implementer or v12+ extender from being surprised by the determinism asymmetry.
- **Cross-concept impact:** BD-160 (will need to handle this when wiring; the doc clarifies expected behavior). Future v12 work (when v11 freezes and v12 becomes the new HEAD-tracking case).
- **Rule/principle violated:** None hard; design-best-practice "explicit invariants" (cross-cuts pack rule "fail loud + document non-obvious semantics").

---

## 4. Coverage notes

### What was IN scope but reviewed lightly

- **Customization-pattern body (lines 226-348)** — re-read to confirm it is verbatim from the original `_build_v10_realistic_ot`, but did not re-validate each pattern's correctness vs the v10 surface (covered by the v10-realistic-ot byte-identity test in IMPLEMENTATION-REPORT §3, which I treated as authoritative).
- **`_setup_v10_pack_src` BD-128 work-around (lines 144-162)** — BD-128 owns; BD-120 only consumes. Out-of-BD-120-scope per the BACKLOG entry's File/Symbol declaration (`test-fixtures/build.sh` only at function level).
- **Determinism pins (lines 44-47, 89-110)** — pre-existing infrastructure; BD-120 inherits without modification. Validated by the byte-identity test.

### What was OUT of scope but mentioned for cross-reference

- BD-160 entire scope. This retro review explicitly acknowledges BD-160 as the carry-forward vehicle for NIT 2 (per prompt) and references it in F1, F2, F4, F5, F6 only as touch-point context, not as scope.
- BD-119 architecture compliance beyond §9 (the BD-120 enablement subsection). The wider BD-119 framework correctness is out of scope per the per-BD review boundary.
- `test-fixtures/manifest.txt` v11-* SHA correctness (I do not validate the SHAs themselves; only the commit-scope discipline of including them in BD-120's commit is in scope).

---

## 5. Re-architect summary

**No `ARCH`-severity findings.** All findings are SHOULD or NIT and are addressable by:

- F1: small build.sh edit (source the lib + call the helper) OR doc-truth edit (drop the misleading README/docstring claim).
- F2: small build.sh edit (remove the v11 case body OR add a `die` sentinel) OR doc-only addition to the README.
- F3: forward-looking convention note; no code change.
- F4: one-line dispatcher cleanup folded into BD-160 (via BACKLOG annotation).
- F5: README docs-only addition (4-step checklist).
- F6: docstring-only addition to `_build_realistic_for_version`.

No CONTRACT-class touch point requires re-architecture across multiple concepts. F1 is the closest to a CONTRACT issue (the helper IS a designed contract), but resolution is binary (consume or retire) — no migration coordination required.

---

## 6. Methodology friction notes

**Friction observed during this review:**

1. **The "DO NOT read PACK-REVIEW-BD-120.md" rule is a strong signal that the prior review may have caught some of these findings.** The retro review is most valuable when it catches MUSTs the prior review missed; SHOULDs and NITs may overlap. F1 (helper not consumed) is the strongest candidate for "missed" since it requires cross-doc reading (architecture §9 + migrator-core.sh + build.sh) rather than just diff inspection. F2-F6 are mostly diff-visible. The prompt's success criterion "Identify any MUST/SHOULD/NIT findings […] that the original ship missed" is honest about overlap risk.

2. **The carry-forward note (BD-160 = NIT 2 from prior review) hints that the prior review used numbered NITs.** Without seeing it, I cannot disambiguate which of my findings overlap with prior nits. F2 (v11 dispatch path coverage) is most likely to overlap with the prior NIT 2 since both surface the same dead-code observation; if prior NIT 2 was just "v11 path unexercised, fold to BD-160", my F2 adds the failure-loudness angle that may or may not have been raised.

3. **CONCEPTUAL-REVIEW-METHODOLOGY.md § "Touch-point classification" was useful for F1 (CONTRACT class clarified the severity question — drift on a designed contract is a SHOULD even if no caller notices today).** The framework helped surface F1 as a real finding rather than dismissing it as cosmetic.

4. **No methodology gaps surfaced.** The six dimensions cleanly captured all five findings. The "fixture-generator failure-loudness on mis-specified inputs" weighting from the prompt was load-bearing for F2.

---

## 7. Final disposition

- **F1 (SHOULD):** recommend fix-or-defer per pack standing fix-all rule. Preferred: option (a) wire the helper. Acceptable: option (b) drop the README/docstring claim. Either way removes a documentation-vs-code drift.
- **F2 (SHOULD):** recommend fix-or-defer. Preferred: option (a) remove the v11 case body until BD-160 wires it. Acceptable: option (b) sentinel `die` or option (c) README "Status" note.
- **F3 (NIT):** no action retro; surface convention note for future-batch hygiene if user wants.
- **F4 (NIT):** no action retro; flag for BD-160 to fold the cleanup in (BACKLOG annotation, PM-only).
- **F5 (NIT):** small README addition (3-step checklist for the realistic-OT extension flow).
- **F6 (NIT):** small docstring addition to `_build_realistic_for_version`.

Per `CLAUDE.md` "Pack memory > Workflow" `feedback_fix_all_review_findings`: surface every finding to the user as fix-or-defer per finding; default to fix-all; nits become tech debt if deferred.

End of report.
