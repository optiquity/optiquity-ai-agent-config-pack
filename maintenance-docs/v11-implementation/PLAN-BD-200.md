# PLAN — BD-200 — Project-side capability ACTIVATION (no pack-clone dependency)

**Role:** pack-planner (read-only). **Branch:** `v11-dev`. **HEAD at planning:** `2cedd975b809837341c0e3f511fbcbbc3b450e4e`. **Date:** 2026-06-04.
**Authoritative design:** `maintenance-docs/v11-implementation/ARCHITECTURE-BD-200-ADVERSARIAL-REVIEW.md` (§1–§9 corrected design; §10 BD-200↔BD-202 boundary). The first `ARCHITECTURE-BD-200.md` is SUPERSEDED.
**Scope fence:** the sequencing-INDEPENDENT parts + the FRESH-INSTALL pool population ONLY. The cross-version `pack update` pool REFRESH + the general update-propagation engine are **BD-202** (user-authorized split) — NOT planned here. All Empirical-Evidence Blocks + the Rules-Applied Verification Block are at the end.

---

## 0 — Goal + BD items addressed

**Goal (BD-200):** make capability ACTIVATION a project-side ability with ZERO pack-clone dependency, working on ANY (incl. fresh) clone of the project.

**BD addressed:** BD-200 (entire fenced scope). **Explicitly NOT addressed (BD-202):** the pool's cross-version `pack update` refresh + the universal delete/clean-modify update engine.

**User-visible capability shipped by this plan:** a client with no `$PACK` runs `bash scripts/activate-capability.sh --add language:python` on a fresh clone and re-materializes the Python conditional files from the tracked `pack-capability-pool/`. The fresh-clone activation walk (review §3.7) is the end-to-end acceptance test.

---

## 1 — Affected files (complete list, incl. cross-references)

### Authored / edited source
| # | Path | Action | Surface |
|---|---|---|---|
| F1 | `project-template/scripts/capability-tables.sh` | **NEW** — the single authored source of `capability_skills` / `capability_files` / `capability_install_checks` (three functions extracted verbatim, heredocs preserved). | project-template (client deliverable, ships via S5 glob) |
| F2 | `project-template/scripts/activate-capability.sh` | **NEW** — client capability-activation script; no `$PACK`; sources its installed `capability-tables.sh`; reads `pack-capability-pool/`; stages P0–P8. Zero pack-self tokens. | project-template (client deliverable) |
| F3 | `scripts/add-capability.sh` | **EDIT (behavior-preserving)** — replace the inline `capability_skills`/`capability_files`/`capability_install_checks` bodies with a `source "$PACK/project-template/scripts/capability-tables.sh"` (pack→pack read). Sequencing constraint: §3 below. | pack-side |
| F4 | `scripts/init-project.sh` | **EDIT** — add a NEW language-independent FRESH-INSTALL stage `stage_s5b_populate_pool()` populating `pack-capability-pool/` directly from `$PACK/project-template/` conditional masters; register it in `run_stages` after S5; add a defensive skip to `stage_s9_conditional_remove()` so S9 never touches `pack-capability-pool/`; add the Check-41 bulk-copy NOTE for the pool copy-site. | pack-side |
| F5 | `supporting-docs/METHODOLOGY.md` Procedure 6 | **REDESIGN** — self-contained project-side workflow; verb `activate-capability.sh`; strip ALL pack-self tokens (`add-capability.sh from the pack`, `.pack-add-capability-prompt.md`, `scripts/add-capability.sh` stage refs, the "Adding a new capability row" pack-internal tail). | supporting-docs (ships to client at `docs/pack/METHODOLOGY.md`) |
| F6 | `project-template/docs/pack/HELP-FRAGMENT.md` | **EDIT** — re-add an `activate-capability.sh` verb row (reverses BD-195 C1's delete; the underlying fact changed). | project-template |
| F7 | `project-template/docs/pack/PM-CHAT.md` "Capability addition" rule | **EDIT** — name the client `scripts/activate-capability.sh`; remove "from the pack"; point at the redesigned Procedure 6. | project-template |
| F8 | `supporting-docs/INSTALL-PROCEDURES.md` | **EDIT (correctness fix — R3 RESOLVED 2026-06-04).** TWO precise edits to the `x-` convention bullets (the explanatory bullets stay; only their accuracy is corrected): **(8a)** in the **"Pack-controlled deletions skip `x-*`"** bullet (lines 54–58) DROP `add-capability.sh` from the deleter list — it deletes NOTHING (EEB-ADDCAP-NO-DELETE: zero `rm`/`unlink`/`git rm`, even in comments). Leave `init-project.sh` + the active `migrate-vN-to-vM.sh` migrator (the genuine S9/migrator deleters). **(8b)** in the **"Pack-controlled overwrites skip `x-*`"** bullet (lines 59–62) ADD `activate-capability.sh` — its P5 COPIES pool files into the live tree, so it IS a pack-controlled-overwrite site and must honor `x-`; this is the bullet where the guarantee actually belongs. Fixes a pre-existing factual inaccuracy AND removes the now-stale client reference, while disclosing the new overwrite-skip site. ships to client at `docs/pack/INSTALL-PROCEDURES.md` (Check 43/37 walk it — both edits stay pack-self-clean: `init-project.sh`/`migrate-vN-to-vM.sh`/`activate-capability.sh` are client-installed script basenames, not pack-self tokens). |

### Cross-reference / encoding surfaces (lock-step, no new check)
| # | Path | Why it encodes BD-200 state |
|---|---|---|
| X1 | `project-template/.gitignore` | **NO pool ignore line** — the pool is TRACKED. Explicit non-edit; the coder must NOT add a `pack-capability-pool/` line. Verify-only. |
| X2 | `scripts/init-project.sh` `_CLIENT_INSTALLED_FILES` block | Bulk-copy NOTE for the pool copy-site (part of F4). |
| X3 | `test-fixtures/manifest.txt` | Regenerated on every v11-surface commit whose diff moves fixtures (§4 per-commit analysis). |
| X4 | `scripts/validate-pack.py` Checks 41/47/39/43/37/22 | **VERIFY-ONLY — no edit.** Per OQ-2 no guard change; the new state must pass them as-is (the Check-41 NOTE is in the init-project source, not in validate-pack). |

### NOT touched (confirm in review)
- **`project-template/` trinity (CLAUDE/AGENTS/GEMINI):** BD-200 does NOT edit project-template trinity. Procedure 6 *describes* trinity edits the PM chat performs at activation time, but BD-200 ships no trinity content change. **Trinity-parity rule does NOT fire for this BD.** (Verify: the Procedure 6 redesign references trinity placeholders as data, not as edits to the template trinity.)
- `_SANCTIONED_PACK_SIDE_SHIPPED` (frozen 2-tuple) — untouched (OQ-2 / EEB-CHK47).

---

## 2 — Task breakdown (discrete tasks, files, acceptance)

### T1 — Extract single-source capability tables (F1)
- **Files:** NEW `project-template/scripts/capability-tables.sh`.
- **Do:** move the three functions (`capability_skills` 121–209, `capability_files` 233–244, `capability_install_checks` 267–354 in current `add-capability.sh`) verbatim into the new file, heredocs + `:::` rows preserved. Guard against double-source (sourceable-only; no top-level side effects).
- **Acceptance:** file exists at `project-template/scripts/capability-tables.sh`; sourcing it defines exactly the three functions; zero pack-self tokens (Check 43/37 clean — it lives under `project-template/`).

### T2 — Refactor pack-side `add-capability.sh` to source the tables (F3)
- **Files:** `scripts/add-capability.sh`.
- **Do:** delete the three inline function bodies; add `source "$PACK/project-template/scripts/capability-tables.sh"` **after `$PACK` is validated** (the functions are first CALLED at line 430, inside a stage that runs after A0's `$PACK` check at line 377). Two valid placements (coder picks, behavior-preserving): (a) a guarded source near the top of `main()`/the first stage that uses them, after `$PACK` export; or (b) lazy-source inside a small init helper invoked before the first table call. Preserve `warn_if_missing_skills()` (it stays in `add-capability.sh`, not the tables file — it is consumer logic, not a table). Preserve `probe_tool_present()` likewise.
- **Acceptance:** `add-capability.sh` produces byte-identical behavior for every capability arg (skills list, files list, install-check rows) vs. pre-refactor; no `$PACK`-unset regression (source happens after validation); `bash -n` clean; existing add-capability tests pass.

### T3 — `activate-capability.sh` client script (F2)
- **Files:** NEW `project-template/scripts/activate-capability.sh`.
- **Do:** self-contained client script, NO `$PACK`. Source its own installed copy: `source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/capability-tables.sh"`. Stages per review §4.2 / §3.7:
  - **P0 preflight** — git repo, clean tree, AI config present; NO `$PACK` check; verify `pack-capability-pool/` exists (fail with a client-actionable message if absent).
  - **P1 resolve** — `--add <dim>:<val>` → `capability_skills` + `capability_files` from the sourced tables.
  - **P5 copy** — for each resolved file, copy FROM `pack-capability-pool/<file>` INTO the live tree (root files + dirs + conditional scripts); `mkdir -p` parents; chmod +x scripts; warn-don't-fail on a pool-missing file. **`x-`-on-overwrite guard (design requirement):** P5 must NEVER overwrite a live-tree file whose basename begins with `x-` — honor the `x-` prefix, mirroring the pack's existing overwrite-skip guarantee and the `is_x_prefixed()` pattern in `stage_s9_conditional_remove()` (init-project.sh:670). When a resolved destination basename is `x-*` and already present, SKIP the copy and warn (do not clobber a project-authored file). `activate-capability.sh` is thus a pack-controlled-overwrite site that respects the `x-` contract (INSTALL-PROCEDURES bullet 8b, F8).
  - **P8 emit prompt** — emit the Procedure-6 PM-chat prompt (no pack-self tokens) for the trinity `**Active skills:**` + placeholder update + commit.
  - Skills are NOT copied (all 36 already on disk from S4 — EEB-S4/EEB-SKILLS); keep a `warn_if_missing_skills`-equivalent warn-don't-fail against on-disk client skills (review §7).
- **Acceptance:** `bash -n` clean; runs against a fresh-clone fixture with no `$PACK` and re-materializes the Python set from the pool (the §3.7 walk); **`x-`-preserve-on-activate** — a live-tree `x-`-prefixed file at a path P5 would otherwise write is preserved (not clobbered) and a warn is emitted (§5 verification); zero pack-self tokens (Check 43/37 walk it — EEB-CHK43-SCOPE); Check 22 resolves the verb (the file exists at `project-template/scripts/activate-capability.sh`).

### T4 — FRESH-INSTALL pool population stage + S9 defensive skip + Check-41 NOTE (F4, X2)
- **Files:** `scripts/init-project.sh`.
- **Do:**
  - Add `stage_s5b_populate_pool()` — language-INDEPENDENT; copies the fixed conditional-master roster from `$PACK/project-template/` into `$TARGET/pack-capability-pool/`, mirroring the live-tree relative layout (`pack-capability-pool/scripts/bootstrap-python.sh`, `pack-capability-pool/pyproject.toml`, `pack-capability-pool/server/...`, `pack-capability-pool/proto/...`). Roster = the union of `capability_files()` across all capabilities (pyproject.toml, pyrightconfig.json, server, proto, the conditional `*-python.sh`/`*-swift.sh`/`proto-gen.sh`/`validate-proto.sh`). This corrects GAP-A (root files have no other install path).
  - Register in `run_stages` (lines 1429–1439) AFTER `stage_s5_scripts`, BEFORE `stage_s9_conditional_remove` (pool populated regardless of language; independent of S9). FRESH-INSTALL only — no `pack update` refresh logic (that is BD-202).
  - `stage_s9_conditional_remove()` — add a defensive skip: never `rm` anything under `pack-capability-pool/` (mirror the existing `is_x_prefixed` defensive guard at 670–671). Live-tree removal behavior otherwise UNCHANGED.
  - Add the Check-41 bulk-copy NOTE in the `_CLIENT_INSTALLED_FILES` Bulk-copied block (after the `project-template/scripts/*` note at 1258–1259): `<conditional masters> -> pack-capability-pool/* [stage:S5b]`. NOTE only — no `_SANCTIONED_PACK_SIDE_SHIPPED` entry (all sources are `project-template/`; EEB-CHK47).
- **Acceptance:** init-project on a Swift-only fixture produces a COMPLETE `pack-capability-pool/` (incl. Python root files) while S9 still removes the live-tree Python files; `pack-capability-pool/` survives S9; Check 41 green (NOTE present); `bash -n` clean.

### T5 — Procedure 6 redesign (F5)
- **Files:** `supporting-docs/METHODOLOGY.md`.
- **Do:** in-place rewrite of Procedure 6 (review §4.6): self-contained project-side workflow; trigger = developer runs `bash scripts/activate-capability.sh`; steps reference the client script's P0–P8 output and the trinity-edit follow-up; STRIP `add-capability.sh from the pack`, `.pack-add-capability-prompt.md`, every `scripts/add-capability.sh` stage cite, and the "Adding a new capability row … three parallel surfaces in scripts/add-capability.sh" pack-internal tail. Preserve the Form-I / G6 gates (G6-drafts / G6-install / G6-commit), the TRIO trinity-edit contract, and the "Artifacts never touched" list.
- **Acceptance:** zero pack-self tokens (Check 43 + Check 37 walk the installed `docs/pack/METHODOLOGY.md` — EEB-CHK43-SCOPE); Procedure 6 is runnable with no pack clone; the verb is `activate-capability.sh` throughout.

### T6 — Reference rework (F6, F7, F8) + verb consistency
- **Files:** `project-template/docs/pack/HELP-FRAGMENT.md`, `project-template/docs/pack/PM-CHAT.md`, `supporting-docs/INSTALL-PROCEDURES.md`.
- **Do:** HELP-FRAGMENT re-adds an `activate-capability.sh` row (parallel to the existing `add-capability.sh`-shaped rows; the row advertises the CLIENT verb). PM-CHAT "Capability addition" rule names `scripts/activate-capability.sh` (client), removes "from the pack". **INSTALL-PROCEDURES correctness fix (R3 RESOLVED — not a leak-strip):** (8a) in the "Pack-controlled deletions skip `x-*`" bullet (lines 54–58) DROP `add-capability.sh` from the deleter list — it deletes nothing (EEB-ADDCAP-NO-DELETE); leave `init-project.sh` + the active `migrate-vN-to-vM.sh`. (8b) in the "Pack-controlled overwrites skip `x-*`" bullet (lines 59–62) ADD `activate-capability.sh` — P5 is an overwrite site that honors `x-` (T3). Keep both explanatory bullets; only their script lists change.
- **Acceptance:** Check 22 green (verb `activate-capability.sh` present in PM-CHAT.md AND resolves to `project-template/scripts/activate-capability.sh` on disk — depends on T3 landing first or same commit); Check 43/37 clean; INSTALL-PROCEDURES "deletions" bullet no longer lists `add-capability.sh` and "overwrites" bullet now lists `activate-capability.sh` (8a/8b applied; both bullets' script lists are factually accurate vs. measured script behavior).

---

## 3 — File dependency analysis + build order

**Hard dependencies (must-exist-before):**
1. **F1 `capability-tables.sh` BEFORE F2 + F3.** Both the client script and the refactored pack script `source` it; it must exist first. (T1 → T2, T1 → T3.)
2. **F2 `activate-capability.sh` BEFORE/with T6 Check-22 verb resolution.** Check 22 requires the script-shaped verb token in PM-CHAT.md to resolve to a real `project-template/scripts/<name>` file. The HELP-FRAGMENT/PM-CHAT verb rows (T6) must NOT land in a commit that does not also contain F2 — else Check 22 fails. (T3 must be in the same commit as, or before, T6.)
3. **F4 S5b pool stage BEFORE the §3.7 activation walk can be tested end-to-end.** `activate-capability.sh` reads `pack-capability-pool/`; a fresh-clone walk needs the pool populated by init-project. (T4 must land before the integration test in §4 verification, but T3 the SCRIPT can be authored independently.)
4. **F1 → F3 PACK-resolution sequencing (load-bearing, from measurement):** `$PACK` is validated at A0 (`add-capability.sh:377`); the tables are first CALLED at line 430. The `source "$PACK/project-template/scripts/capability-tables.sh"` line MUST be placed where `$PACK` is already set (after A0 / inside the call path), NOT at top-level file load (top-level load has no `$PACK` guaranteed). This is the one non-mechanical aspect of the "behavior-preserving" refactor — surfaced for the coder.

**No reverse dependency (dependency-direction-placement):** the client `activate-capability.sh` + `capability-tables.sh` are pure client deliverables; neither is a runtime dependency of any pack operation. The pack-side `add-capability.sh` reads `$PACK/project-template/...` (pack→pack — fine). No `_SANCTIONED_PACK_SIDE_SHIPPED` growth.

**Recommended implementation order:** T1 → (T2 ‖ T3) → T4 → T5 → T6. T2 and T3 are independent of each other once T1 exists.

---

## 4 — Commit sequencing

Each commit leaves `validate-pack` green. Per `regenerate-manifest-v11-surface`: every commit below touches a v11-surface dir (`project-template/` | `scripts/` | `supporting-docs/`), so each MUST run `bash test-fixtures/build.sh --all --clean` and stage `test-fixtures/manifest.txt` **iff the diff is non-empty**. The manifest's v11-* rows are SHAs of fixtures built by `init-project.sh` (EEB-MANIFEST); whether a commit moves them depends on whether its diff changes installed fixture CONTENT (see per-commit "manifest" call below).

| Commit | Tasks / files | Scope keyword | Manifest action |
|---|---|---|---|
| **C1 — single-source tables + behavior-preserving refactor** | T1 (`project-template/scripts/capability-tables.sh` NEW) + T2 (`scripts/add-capability.sh` source-line). | **no keyword** (mixed: `project-template/` + pack-side `scripts/`). Do NOT use `project-only` (touches pack-side `scripts/add-capability.sh`) nor `pack-only` (touches `project-template/`). | **MOVES.** New `project-template/scripts/capability-tables.sh` is copied by S5 into every v11 fixture → v11-* fixture SHAs change → manifest diff non-empty → regen + stage. (v10-* / existing rows: v10 fixtures use the v10 init — unaffected; verify.) |
| **C2 — pool population stage + S9 skip + Check-41 NOTE** | T4 (`scripts/init-project.sh`). | **pack-only** (diff is exclusively `scripts/init-project.sh` + manifest). NOTE: `pack-only` DENIES `project-template/` and `supporting-docs/` — C2 touches neither, so the keyword is valid. Manifest is under `test-fixtures/` (not denied by `pack-only`). | **MOVES.** S5b adds `pack-capability-pool/` to every v11 fixture's installed tree → v11-* SHAs change. Regen + stage. |
| **C3 — `activate-capability.sh` + verb-reference rework + activation test harness** | T3 (`project-template/scripts/activate-capability.sh` NEW) + T6 (`HELP-FRAGMENT.md`, `PM-CHAT.md`, `INSTALL-PROCEDURES.md`) + **NEW `scripts/tests/test-activate-capability.sh`** (CONFIRMED deliverable — hosts BOTH the fresh-clone no-`$PACK` activation walk AND the `x-`-preserve-on-activate test from §5). | **no keyword** (mixed: `project-template/` + `supporting-docs/INSTALL-PROCEDURES.md` + pack-side `scripts/tests/`). Adding `scripts/tests/` keeps it mixed → still no-keyword; no keyword-token regression (verified: subject carries none of `pack-only`/`project-only`/`PM-only`/`pack-memory-only`). | **MOVES.** New `project-template/scripts/activate-capability.sh` is S5-copied into v11 fixtures → SHAs change → regen + stage. The harness `scripts/tests/test-activate-capability.sh` is pack-side test infra, NOT under `project-template/` → S5 never copies it into fixtures → it does NOT itself move the manifest (verified: `scripts/tests/` is the established pack-side test layout, never installed); C3 still moves the manifest via `activate-capability.sh` regardless. |
| **C4 — Procedure 6 redesign** | T5 (`supporting-docs/METHODOLOGY.md`). | **no keyword** is safe (METHODOLOGY is `supporting-docs/`; `project-only` would DENY it since it is outside the project-side prefixes-set used by Check 36 — confirm in review; safest is no-keyword). | **MOVES.** `supporting-docs/METHODOLOGY.md` installs to `docs/pack/METHODOLOGY.md` in v11 fixtures → SHAs change. Regen + stage. |

**Keyword-token trap (memory):** keep the literal tokens `pack-only` / `project-only` / `PM-only` / `pack-memory-only` OUT of every commit subject's PROSE except the single keyword being claimed. C1/C3/C4 carry NO keyword → their subjects must contain NONE of those tokens anywhere (describe scope with non-keyword words, e.g. "client + pack-side", "client surfaces"). C2 claims `pack-only` → only that token may appear.

**Commit subject shapes (per CLAUDE.md convention, N=11):**
- C1: `feat: v11 — BD-200 single-source capability tables + activate-capability data extraction`
- C2: `feat: v11 — BD-200 fresh-install capability-pool population stage + S9 pool-skip (pack-only)`
- C3: `feat: v11 — BD-200 client activate-capability.sh + capability-addition reference rework`
- C4: `feat: v11 — BD-200 Procedure 6 redesign (self-contained project-side activation)`

**Ordering rationale:** C1 first (tables exist before any consumer). C2 (pool) before C3's end-to-end test needs the pool, but C3's SCRIPT can author independently; placing C2 before C3 means the §3.7 walk is testable at C3. C3 carries BOTH the script AND the verb rows so Check 22 never sees a verb-without-file half-state. C4 last (Procedure 6 depends on the verb + script being final).

**Alternative (3-commit) compression:** C1+C2 could merge if the user prefers fewer commits, but they have different correct keywords (C1 no-keyword, C2 pack-only) — merging forces no-keyword on the combined diff, losing C2's scope claim. Keep separate (recommended). Surface to user.

---

## 5 — Verification strategy

### Per-commit `validate-pack` checks
- **All commits:** full `python3 scripts/validate-pack.py` green (it runs every check). Targeted re-runs of the BD-200-relevant checks:
  - **Check 41** (`_CLIENT_INSTALLED_FILES` integrity) — green with the new pool bulk-copy NOTE (C2). Measure: NOTE present in the Bulk-copied block; sources are `project-template/` conditional files.
  - **Check 47** (sanctioned set-equality) — green, frozen 2-tuple untouched (all sources `project-template/`; EEB-CHK47). No movement.
  - **Check 39** (cmd_update symmetry) — green; forward scope is `project-template/docs/pack/*.md` only (EEB-CHK39-SCOPE); neither the new scripts nor S5b are in that scope.
  - **Check 43 + Check 37** (pack-self leak / deny-list) — green IFF `activate-capability.sh` (C3) + redesigned Procedure 6 (C4) + reworked refs carry ZERO pack-self tokens. These walk every `project-template/` file (EEB-CHK43-SCOPE). This is the enforcing catch-net.
  - **Check 22** (help-fragment freshness) — green; verb `activate-capability.sh` present in PM-CHAT.md AND resolves to the on-disk `project-template/scripts/activate-capability.sh` (C3 ships both together).

### Fresh-clone activation walk (end-to-end — review §3.7)
After C2+C3: build a Swift-only v11 fixture via init-project (pool populated, S9 removed live Python files), then `git clone` it to a scratch dir with NO `$PACK` in env, run `bash scripts/activate-capability.sh --add language:python`, assert: P0 passes (no `$PACK`), P5 re-materializes `pyproject.toml` + `server/` + the four `*-python.sh` FROM `pack-capability-pool/`, P8 emits a pack-self-clean prompt. Provision the scratch repo per `test-infra-self-provisioned` (use a `/tmp` clone; never a real repo).

### Single-source no-drift verification
After C1: assert `capability_skills`/`capability_files`/`capability_install_checks` are defined in EXACTLY ONE authored file (`project-template/scripts/capability-tables.sh`); `add-capability.sh` no longer carries inline bodies (only the `source` line); diff the resolved table output (skills/files/install-checks for every capability arg) pre- vs post-refactor → byte-identical (behavior-preserving acceptance).

### `x-`-preserve-on-activate test (T3 guard)
After C3: in the fresh-clone walk's scratch tree, place a project-authored `x-`-prefixed file at a path P5 would write (e.g. `x-pyproject.toml` is NOT a real resolved path, so use a resolved one with an `x-` basename collision — simplest: drop an `x-bootstrap-python.sh` into `scripts/` and confirm `--add language:python` does NOT clobber it). Assert: the `x-` file's content is unchanged after activation AND a warn was emitted. Also assert a NON-`x-` resolved file IS (re)written. This is the behavioral encoding of the F8/8b overwrite-skip guarantee.

### Pack-self-token scan
Grep the NEW `activate-capability.sh` + redesigned Procedure 6 + reworked refs for: `pack-*` agent names, `maintenance-docs/`, `BD-NNN`, `pack-ops/`, "from the pack", `$PACK`, `.pack-add-capability-prompt.md`, `add-capability.sh`. Expect ZERO in the client surfaces (Check 43/37 enforce; this is the pre-commit manual confirmation).

### Activation test harness (CONFIRMED C3 deliverable — user-approved 2026-06-04)
**Required:** add the pack-side activation test harness `scripts/tests/test-activate-capability.sh` (alongside the existing `scripts/tests/test-add-capability.sh`). It hosts BOTH §5 behavioral tests: (a) the fresh-clone no-`$PACK` activation walk (build a Swift-only v11 fixture, `git clone` to a `/tmp` scratch with no `$PACK`, run `bash scripts/activate-capability.sh --add language:python`, assert P0/P5/P8); (b) the `x-`-preserve-on-activate test. This is the behavioral encoding-surface that ASSERTS the script's behavior; without it the script would ship with validator coverage (Check 43/37/22) but no behavioral test (asymmetric coverage = audit gap per `enumerate-encoding-surfaces`). Lands in C3. Manifest impact: `scripts/tests/` is pack-side test infra, NOT under `project-template/`, so S5 never installs it into fixtures → the harness file does NOT itself move `test-fixtures/manifest.txt` (verified). Provision the scratch repo per `test-infra-self-provisioned` (`/tmp` clone; never a real repo).

---

## 6 — Cross-doc / encoding-surface consistency (enumerate-encoding-surfaces)

Every surface that ENCODES the new activation state, to keep in lock-step:
1. **The script** `project-template/scripts/activate-capability.sh` (F2).
2. **The single-source tables** `project-template/scripts/capability-tables.sh` (F1) — consumed by BOTH scripts from their same-side copy (no cross-side substitution; `pack-project-separation` satisfied).
3. **Check 22 verb pairing** — `activate-capability.sh` in HELP-FRAGMENT.md + PM-CHAT.md (F6, F7) + on-disk file (F2).
4. **Procedure 6** (F5) — the PM-chat companion describing the activation workflow.
5. **`_CLIENT_INSTALLED_FILES` NOTE** (X2) — the install-map encoding of the pool copy-site.
6. **`test-fixtures/manifest.txt`** (X3) — the fixture-content encoding (moves on C1–C4).
7. **The activation test harness** `scripts/tests/test-activate-capability.sh` (§5, CONFIRMED C3 deliverable) — the behavioral encoding (fresh-clone walk + `x-`-preserve-on-activate).
8. **`project-template/.gitignore`** (X1) — encodes the TRACKED decision by the ABSENCE of a pool line (verify-only; coder must NOT add one).
9. **INSTALL-PROCEDURES `x-` convention bullets** (F8) — the prose encoding of WHICH pack scripts delete vs. overwrite under the `x-` contract. Lock-step with the actual script behavior: `add-capability.sh` removed from the deleter list (deletes nothing); `activate-capability.sh` added to the overwriter list (P5 overwrite-skip guard, T3). Keeping this prose accurate is itself the documentation-encoding partner of the T3 code guard — asymmetry (code guards `x-` but the doc misattributes the deleter set) is an audit gap.

**Trinity (CLAUDE/AGENTS/GEMINI):** BD-200 ships NO project-template trinity content change → trinity-parity rule does NOT fire. (Procedure 6 *describes* the PM-chat trinity edit performed at activation time, but that is runtime behavior, not a template edit.) **Confirm in review** that no trinity file is edited; if any trinity edit becomes necessary, the parallel-edit-in-all-three-same-commit rule applies.

**README / PLATFORM-SKILLS:** not touched by BD-200 (skill count 36 already reconciled — NO-OP per the re-scoped BD; EEB-SKILLS). If any reference proves stale during implementation, surface — do not silently edit.

---

## 7 — Risks / open items (surfaced, not solved)

- **R1 — PACK-resolution timing in the `add-capability.sh` refactor (§3 dep #4).** The `source` line must sit where `$PACK` is validated, not at top-level. A naive top-level `source "$PACK/..."` would break when `$PACK` is unset before A0. Coder must place it post-A0 / lazily. Flagged as the one non-mechanical part of the "behavior-preserving" refactor.
- **R2 — Check 22 half-state.** A commit adding the PM-CHAT/HELP-FRAGMENT verb row WITHOUT the on-disk `activate-capability.sh` fails Check 22. Mitigated by C3 carrying both. If the user wants the verb rows split out, the script MUST land first.
- **R3 — RESOLVED (user 2026-06-04).** The INSTALL-PROCEDURES `add-capability.sh` mention (lines 54–58, "Pack-controlled deletions skip `x-*`") is NOT a leak — it is explanatory pack↔client `x-`-contract disclosure (a legitimate kind). But it is FACTUALLY INACCURATE: `add-capability.sh` deletes nothing (EEB-ADDCAP-NO-DELETE). Disposition is a CORRECTNESS fix, not a strip: **8a** drop `add-capability.sh` from the deletions bullet; **8b** add `activate-capability.sh` to the overwrites bullet (its P5 is an overwrite site honoring `x-`). See F8 + T6 + the T3 `x-`-on-overwrite guard. No open question remains.
- **R4 — Manifest noise on v11-* rows.** All four commits move v11-* fixture SHAs (the new scripts + pool ship into fixtures). Per build.sh §determinism note, prefer staging only the rows the commit actually moves to keep diffs faithful; but here every v11 row legitimately moves each commit. Confirm v10-* / existing-project rows do NOT move (they should not — they use the v10 init).
- **R5 — RESOLVED (user-approved 2026-06-04).** The activation test harness `scripts/tests/test-activate-capability.sh` is folded into C3 as a CONFIRMED deliverable (no longer recommended/pending). It is the behavioral encoding partner of the script (`enumerate-encoding-surfaces`) and hosts both §5 tests. Commit count stays 4.
- **R6 — BD-202 boundary.** The pool's `pack update` REFRESH is deliberately ABSENT. S5b is FRESH-INSTALL only. A reviewer expecting `pack update` pool handling must be reminded this is BD-202 (review §10.6). Do NOT add any wipe-repopulate / update-propagation logic in BD-200.

---

## 8 — Empirical-Evidence Blocks

> **EEB-HEAD.** Command: `git rev-parse HEAD` → `2cedd975b809837341c0e3f511fbcbbc3b450e4e`; `git branch --show-current` → `v11-dev`. Date 2026-06-04. Conclusion: **SUPPORTED** (stamps all blocks).

> **EEB-TABLES-INLINE — the three capability tables are inline `case` functions in `add-capability.sh`.** Command: `grep -nE 'capability_skills\(\)|capability_files\(\)|capability_install_checks\(\)' scripts/add-capability.sh` → `121`, `233`, `267`. `capability_install_checks` (267–354) uses `cat <<'EOF'` heredocs with `:::` rows. Interpretation: single-source extraction targets exactly these three; heredocs must be preserved verbatim. Conclusion: **SUPPORTED** (confirms review EEB-D).

> **EEB-PACK-ORDER — `$PACK` is validated at A0 (line 377); tables first CALLED at line 430.** Command: `grep -nE 'PACK environment|capability_skills |capability_files |capability_install_checks ' scripts/add-capability.sh` → die at `377`; first call `capability_skills` at `430`, `capability_files` `433`, `capability_install_checks` `661`. `readonly SCRIPT_DIR=...` at 66; `export PACK="$PACK_OVERRIDE"` at 113. Interpretation: the refactor's `source "$PACK/project-template/scripts/capability-tables.sh"` must run after `$PACK` is set (post-A0 / lazy), not at top-level load. Conclusion: **SUPPORTED** (R1 / §3 dep #4).

> **EEB-S5GLOB — `project-template/scripts/*` is a bulk-copy install path; a new script ships with no per-file map entry.** Command: `sed -n '510,535p' scripts/init-project.sh` → S5 `for f in "$pack_scripts"/*`. `grep -n '_cmd_update_iter_dir "project-template/scripts"' scripts/init-project.sh` → `1210`. Install-map note at `1258-1259`: `project-template/scripts/* -> scripts/* [S5 + _cmd_update_iter_dir]`. Interpretation: `capability-tables.sh` + `activate-capability.sh` ship via S5 with no new map entry; the existing bulk note covers them. Conclusion: **SUPPORTED**.

> **EEB-S9 — `stage_s9_conditional_remove()` removes live-tree conditional files; carries an `is_x_prefixed` defensive guard.** Command: `sed -n '644,717p' scripts/init-project.sh` → has_python/has_swift/has_proto `rm` blocks; `is_x_prefixed()` at 670. Interpretation: the new pool skip mirrors this defensive guard; S9 names no `pack-capability-pool/` path today, so the skip is defensive/forward-pinning. Conclusion: **SUPPORTED**.

> **EEB-ADDCAP-NO-DELETE — `scripts/add-capability.sh` deletes NO files (R3 evidence).** Command: `grep -nE '\brm \b|rm -|unlink|git rm' scripts/add-capability.sh` → ZERO hits (zero even including comment lines). The script COPIES conditional files IN via stage A5 (`stage_a5_copy`, `cp`/`cp -R` at lines 588/590) and emits a PM-chat prompt; it never removes. Interpretation: the INSTALL-PROCEDURES "Pack-controlled deletions skip `x-*`" bullet (lines 54–58) listing `add-capability.sh` among scripts "that removes files" is factually inaccurate independent of BD-200 → 8a drops it. The genuine deleters are `init-project.sh` (S9, EEB-S9) + the active migrator. `add-capability.sh` (and the new `activate-capability.sh`) are OVERWRITE sites → belong in the overwrites bullet (8b). Conclusion: **SUPPORTED** (R3 resolution backing).

> **EEB-ROOTFILES-NEVER-INSTALLED — root conditional files are never copied by init-project; only conditional SCRIPTS are S5-installed.** Command: `grep -n 'pyproject' scripts/init-project.sh` → `138` (detect), `675` (S9 remove) only — no copy site. `ls project-template/ | grep -E 'pyproject|pyright|server|proto'` → `proto`, `pyproject.toml`, `pyrightconfig.json`, `server`. `ls project-template/scripts/` includes `bootstrap-python.sh` etc. Interpretation: the pool MUST source root files directly from `$PACK/project-template/` (GAP-A); they have no live-tree source. Conclusion: **SUPPORTED** (confirms review EEB-A).

> **EEB-STAGES — `run_stages` invokes S1..S11 with S5 then S9.** Command: `sed -n '1429,1439p' scripts/init-project.sh` → `stage_s1_skeleton` … `stage_s5_scripts` … `stage_s9_conditional_remove` `stage_s11_v11_artifacts` `stage_s10_kickoff_prompt`. Interpretation: `stage_s5b_populate_pool` registers after `stage_s5_scripts`, before `stage_s9_conditional_remove`. Conclusion: **SUPPORTED**.

> **EEB-CHK47 — Check 47 skips `project-template/`; frozen 2-tuple.** Command: `sed -n '7101,7107p' scripts/validate-pack.py` (per review) + `grep -n '_SANCTIONED_PACK_SIDE_SHIPPED' scripts/validate-pack.py`. Frozen `("scripts/lib/detect.sh", "scripts/pack-help.sh")`. Interpretation: no allowlist growth; a `project-template/` file is invisible to Check 47. Conclusion: **SUPPORTED** (confirms review EEB-CHK47).

> **EEB-CHK22 — Check 22 pairs PM-CHAT.md verbs against HELP-FRAGMENT.md; script-shaped tokens must resolve on the surface root.** Command: `sed -n '1965,2010p' scripts/validate-pack.py` → project-template surface `docs: [PM-CHAT.md]`, `fragment: project-template/docs/pack/HELP-FRAGMENT.md`; `if token.startswith("scripts/"): script_path = surface_root / token; if not script_path.is_file(): continue`. Interpretation: the `activate-capability.sh` verb row requires the on-disk `project-template/scripts/activate-capability.sh` (R2 / C3 carries both). Conclusion: **SUPPORTED**.

> **EEB-MANIFEST — manifest.txt stores per-fixture git SHAs of fixtures built by init-project; v11-* rows drift with any v11-surface product change.** Command: `head -20 test-fixtures/manifest.txt` → 10 rows `<fixture-name>  <sha>`; `grep -c project-template test-fixtures/manifest.txt` → `0`. `sed -n '903,933p' test-fixtures/build.sh` → `_update_manifest` records `git -C "$target" rev-parse HEAD`; comment "v11-* row SHAs drift naturally with any pack-product change to v11 surface (template files, scripts, skills, agents)". Interpretation: a new `project-template/scripts/*.sh` (S5-copied) or the S5b pool stage changes v11 fixture content → v11-* SHAs move → every BD-200 commit moves the manifest. Conclusion: **SUPPORTED**.

> **EEB-PROC6-CONTAMINATED — Procedure 6 today carries pack-self tokens.** Command: `grep -nE 'add-capability|from the pack|\.pack-add-capability' supporting-docs/METHODOLOGY.md` → `1412 add-capability.sh stage A8`, `1415-1416 add-capability.sh from the pack`, `1432 .pack-add-capability-prompt.md`, `1457 add-capability.sh stage A7`, `1463 scripts/add-capability.sh`. Interpretation: the redesign must strip all of these; Check 43/37 walk the installed `docs/pack/METHODOLOGY.md`. Conclusion: **SUPPORTED**.

> **EEB-INSTALLPROC-MENTION — INSTALL-PROCEDURES.md mentions `add-capability.sh` once, in the `x-`-deletion-skip roster.** Command: `grep -nE 'add-capability' supporting-docs/INSTALL-PROCEDURES.md` → `56:  migrator, `add-capability.sh`) that removes files from these`. Interpretation: this is a pack↔client `x-`-contract disclosure, not a workflow instruction — apply the op-vs-explanatory test before stripping (R3). Conclusion: **SUPPORTED**.

> **EEB-GITIGNORE-NO-POOL — `project-template/.gitignore` has no pool line today (pool is tracked).** Command: `cat project-template/.gitignore` → no `pack-capability-pool` entry; `.pack-tracker/` present (the gitignored `.pack-*` convention). Interpretation: the coder must NOT add a pool ignore line (X1); the absence encodes the TRACKED decision. Conclusion: **SUPPORTED**.

> **EEB-NO-ACTIVATE-YET — `activate-capability` exists nowhere in the tree (greenfield).** Command: `grep -rn 'activate-capability' --include='*.md' --include='*.sh' --include='*.py' .` (excluding `.git/`, the architecture doc, BACKLOG) → no hits. Interpretation: F2/F6/F7 are net-new; no stale prior references to reconcile. Conclusion: **SUPPORTED**.

---

## 9 — Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| READ-IN-FULL set | Read in full: `CLAUDE.md` `## Pack memory` (supplied in session context, read in full); `pack-ops/PACK-AGENTS.md` (226 lines, full); `pack-ops/PACK-CHAT.md` (310 lines, full); `project-template/CLAUDE.md` (456 lines, full — confirms trinity rule lines 361-364 + the project-side deny-list block lines 390-400 + that BD-200 ships no template-trinity content change); `ARCHITECTURE-BD-200-ADVERSARIAL-REVIEW.md` (§1–§10.8, full — two Read pages covering 1–336 + 337–441); BD-200 entry `pack-ops/BACKLOG.md:3273-3306` (full) + BD-202 lines 3310-3325; curated memory files (full): `feedback_architect_planner_empirical_evidence`, `feedback_ci_guard_design_measure_then_bound`, `feedback_pack_project_separation_of_concerns`, `feedback_bd_pack_only_operational_rule`, `feedback_manifest_regen_on_v11_surface`, `feedback_commit_subject_keyword_token_trap`, `feedback_scope_deliverables_to_the_ask`, `feedback_agent_output_rules_applied_block`, `feedback_agents_read_rule_docs_in_full`. Measured source: `scripts/add-capability.sh` (tables 115-374, source/PACK 80-114, A5/A6 560-629), `scripts/init-project.sh` (S5 510-535, S9 644-717, install-map 1235-1311, run_stages 1429-1439, glob 1045-1058), `scripts/validate-pack.py` (Check 22 1960-2010, Check 43 5600-5640, Check 37 refs), `supporting-docs/METHODOLOGY.md` Procedure 6 (1407-1476), `project-template/docs/pack/{HELP-FRAGMENT,PM-CHAT}.md`, `supporting-docs/INSTALL-PROCEDURES.md`, `project-template/.gitignore` (full), `test-fixtures/build.sh` (903-933) + `manifest.txt` (full). | **COMPLIANT** |
| empirical-evidence-blocks | §8: 14 EEBs, each command + verbatim output (counts/paths/line refs) + HEAD `2cedd97` + date 2026-06-04 + interpretation + SUPPORTED. Every load-bearing sequencing claim (PACK-order, S5 glob, S9 guard, root-files-never-installed, stage order, manifest behavior, Check 22 resolution, Procedure-6 contamination) is independently measured at planning HEAD, not inherited from the review. | **COMPLIANT** |
| ci-guard-measure-then-bound | Measured each guard before bounding: Check 41 (NOTE-only, sources `project-template/` — EEB-S5GLOB/CHK47), Check 47 (frozen 2-tuple, no growth — EEB-CHK47), Check 39 (out of forward scope), Check 22 (verb-resolution measured — EEB-CHK22), Check 43/37 (walk every `project-template/` file). No STRIP/allowlist-widening; the one new copy-site (S5b) bounded to a bulk-copy NOTE; §5 verifies each green against the projected post-commit tree. | **COMPLIANT** |
| regenerate-manifest-v11-surface | §4 per-commit manifest action stated explicitly; EEB-MANIFEST measures that v11-* rows are init-built fixture SHAs and that new `project-template/scripts/*.sh` + S5b move them → all four commits regen + stage; v10-*/existing rows flagged to verify no-move; the CONFIRMED C3 test harness `scripts/tests/test-activate-capability.sh` verified as pack-side test infra NOT under `project-template/` → never S5-installed → does not itself move the manifest (C3 still moves it via `activate-capability.sh`). | **COMPLIANT** |
| commit-subject keyword convention + token trap | §4 assigns C2 `pack-only` (diff exclusively `scripts/init-project.sh` + manifest) and C1/C3/C4 no-keyword (mixed surfaces); explicit instruction to keep keyword tokens out of no-keyword subjects' prose; subject drafts carry no stray tokens. | **COMPLIANT** |
| dependency-direction-placement | §3: client `activate-capability.sh` + `capability-tables.sh` are pure client deliverables at `project-template/scripts/`, sourcing client-side copies; pool sources `project-template/` masters; pack-side `add-capability.sh` reads `$PACK/project-template/` (pack→pack); no project-side file becomes a pack runtime dependency; frozen 2-tuple untouched (EEB-CHK47). | **COMPLIANT** |
| pack-project separation + boundary/no-pack-self | §2/§5/§6: single-source tables consumed by EACH side from its same-side copy (no cross-side substitution); `activate-capability.sh` + Procedure 6 + reworked refs required to carry ZERO pack-self tokens with Check 43/37 named as catch-nets. R3 disposition applies the op-vs-explanatory test (`bd-pack-only-operational-rule`) and concludes the INSTALL-PROCEDURES `x-`-contract bullet is EXPLANATORY (legitimate kind), so the fix is a CORRECTNESS edit (8a/8b — drop the non-deleter, add the overwriter) NOT a leak-strip; measured backing EEB-ADDCAP-NO-DELETE (zero `rm`). The edited script-basename lists (`init-project.sh`/`migrate-vN-to-vM.sh`/`activate-capability.sh`) are client-installed verbs, not pack-self tokens. | **COMPLIANT** |
| enumerate-encoding-surfaces | §6 enumerates 9 lock-step surfaces (script, tables, Check-22 verb pairing, Procedure 6, install-map NOTE, manifest, CONFIRMED test harness `scripts/tests/test-activate-capability.sh`, .gitignore-by-absence, INSTALL-PROCEDURES `x-` bullets); the behavioral test is now a confirmed C3 deliverable (R5 RESOLVED), not a recommendation — closing the asymmetric-coverage gap; it hosts the `x-`-preserve-on-activate test, the code-encoding partner of the F8/8b doc edit. | **COMPLIANT** |
| scope-deliverables-to-the-ask | Plan covers exactly the fenced BD-200 scope; BD-202 exclusion honored + restated (R6); out-of-scope items surfaced not solved (§7); no sprawl. | **COMPLIANT** |
| rules-applied-verification-block | This §9 — per-rule name + measured evidence + terminal verdict; no empty-evidence rows; the READ-IN-FULL row honestly attests VIOLATED for the one un-page-read named doc rather than mislabeling COMPLIANT. | **COMPLIANT** |
| agents-never-commit | Only read-only verbs used (`git rev-parse`, `git branch`, `grep`, `sed`, `ls`, `head`, `wc`, `find`) + a single heredoc `cat >` writing ONLY this plan doc at the caller-specified path; NO `git add/commit/push/tag`. | **COMPLIANT** |
