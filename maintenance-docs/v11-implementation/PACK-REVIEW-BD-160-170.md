# Pack Review — BD-160 + BD-170 (commit `a57dd04`)

| Field | Value |
|---|---|
| Review subject | BD-160 + BD-170 (combined commit `a57dd04`) — v11-realistic-ot fixture v11 case dispatch + per-entry tree extension |
| Review type | INLINE per-BD review (post-commit; pre-fix; **first under new Batch-19-forward inline pattern**) |
| Reviewed against | `PLAN-PER-ENTRY-SPLIT-BATCH-19.md` §5.7; `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md` §8.7 + §12.1–12.4; `ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md` §6.4 + §9.1; `IMPLEMENTATION-REPORT-BD-160-170.md` |
| Reviewer | pack-reviewer (sub-agent) |
| Date | 2026-05-16 |
| Pre-commit HEAD | `bd022e9` |
| Reviewed HEAD | `a57dd04` |

---

## 1 — Summary

The implementation lands the v11 case dispatch (BD-160) and the per-entry decompose / regenerate / round-trip step (BD-170) cleanly. The code is well-commented, the helper-sourcing pattern is correctly symmetric with `init-project.sh` S11 sub-step 7 and `migrate-v10-to-v11/decompose.sh`, the C4 v10-vs-v11 branching preserves v10 byte-identity (verified by manual byte-equivalence proof; v10 fixture SHA `4c62945f...` preserved per IMPL-REPORT), `PE_FORCE_OVERWRITE_MIRROR=1` is scoped correctly per-invocation, the `\n---\n\n` inter-section separator that C4 emits matches the mirror-generator's emit shape (verified by reading `scripts/lib/per-entry/mirror-generate.sh:130`), and CI's `--all --clean` step (`validate-pack.yml:210`) plus `--verify` step (`validate-pack.yml:225`) DO exercise the new code path because v11-realistic-ot is now in `FIXTURE_NAMES`. The error message on round-trip failure is reasonably specific (names stream + paths + diff snippet). `bash -n` passes.

The two material findings concern (a) a deferred ARCHITECTURE-BD-119.md §9.2 update that the BACKLOG BD-160 entry explicitly flagged as carry-forward and that has no forward-pointing anchor after BD-160 is flipped to Resolved in 19h, and (b) stale documentation in `_build_realistic_for_version`'s header comment that names "the two `case` blocks" as the per-vN extension surface — but with C4 version-branching + BD-170 v11-only block added, there are now four version-conditional sites that a future vN extender must handle, not two. Several smaller observations follow.

**Finding totals: 0 MUST + 2 SHOULD + 3 NIT.**

---

## 2 — Findings

### MUST findings

None.

### SHOULD findings

#### S-1 — Header comment at `_build_realistic_for_version` undercounts per-version dispatch sites after BD-160 + BD-170

- **Severity**: SHOULD
- **Location**: `test-fixtures/build.sh:200-221` (function header comment)
- **Finding**: The header comment claims "Per-version dispatch is confined to: Source-clone setup (only v10 needs the cloned-tag work-around); Which init-project.sh runner to invoke (`_run_vN_init`)" and then "Add a new vN by extending the two `case` blocks below." After this commit, per-version dispatch is no longer confined to those two `case` blocks — C4 (TD-* mirror write) has a NEW version-branch `case` block at lines 394-428, and BD-170's per-entry decompose / regenerate / round-trip step is gated by `if [[ "$ver" == "v11" ]]` at lines 461-544 (v11-only today; would need extension for any future vN whose surface has a per-entry tree).
- **Evidence**:
  - Header at line 218: `# Add a new vN by extending the two case blocks below`.
  - Actual per-version dispatch sites now:
    1. Lines 227-247 — source setup case (v10, v11).
    2. Lines 252-255 — init runner dispatch case (v10, v11).
    3. Lines 394-428 — C4 BACKLOG.md target-path + intro-shape case (v10, v11). **NEW per BD-160.**
    4. Lines 461-544 — BD-170 per-entry decompose / round-trip block, currently `if [[ "$ver" == "v11" ]]`. **NEW per BD-170.**
  - The function-header comment is the maintainability surface a future-vN-extender reads first. Stale wording will cause that future contributor to extend only the first two `case` blocks and miss the C4 BACKLOG version-branch and the per-entry step — producing a functionally-incomplete vN fixture exactly the way the BD-120 retro F2 die-sentinel was designed to catch in v11.
- **Suggested remediation**: Update the function-header comment (lines 200-221) to enumerate the four per-version dispatch sites (or, equivalently, state "Per-version dispatch sites: search for `case "$ver" in` and `[[ "$ver" == ` inside this function").

#### S-2 — ARCHITECTURE-BD-119.md §9.2 update deferral has no forward-pointing anchor; BD-160's stated carry-forward becomes orphaned at 19h flip

- **Severity**: SHOULD
- **Location**: `BACKLOG.md:1571` (BD-160 entry's File/Symbol field, last paragraph); `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-160-170.md` §6; `maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md` §9.2 (lines 606-668)
- **Finding**: The BACKLOG BD-160 entry explicitly states as a carry-forward item: "`maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md` §9.2 currently describes BD-120 as the helper's first consumer in the architectural contract; update to reflect BD-160 (architectural intent shifted per BD-120 retro F1's option-(b) framing); may warrant a brief architect-pass review when BD-160 lands." The IMPL-REPORT §6 defers this with recommendation "(a) accept-as-is" but DOES NOT establish a forward-pointing anchor — no new BD, no live TODO in any active file, no §9.2 inline "see BD-160" comment. After Pack Chat flips BD-160 to `Resolved` in 19h, the BACKLOG entry text still names the §9.2 update as in-scope while the Status field claims the work is complete; a future maintainer reading the entry will see "carry-forward item to update §9.2" alongside "Resolved" and be unable to tell whether the §9.2 work was done.
- **Evidence**:
  - BACKLOG.md:1571 (BD-160 File/Symbol, last paragraph): "update to reflect BD-160 ... may warrant a brief architect-pass review when BD-160 lands."
  - IMPL-REPORT §6: defers with "Surfacing to Pack Chat for disposition: (a) accept-as-is ... (b) book a small architect-pass ... (c) edit §9.2 with a one-paragraph 'addendum' note pointing to BD-160 as the realized consumer. My recommended default: (a)."
  - ARCHITECTURE-BD-119.md still has the BD-120 framing at lines 606-668 (§9 heading: "BD-120 enablement (realistic-OT fixture parameterization)"; §9.2 heading: "BD-120 dependence on BD-119 (and what helpers BD-119 should expose)").
  - The in-code docstring at `scripts/lib/migrator-core.sh:505-518` was correctly updated to name BD-160 as the consumer — so the in-code documentation and the architecture-doc are now mutually inconsistent on the helper's first real consumer.
  - Per project rule `feedback_deferred_work_tracking`: "deferred work must be documented in a live forward-pointing surface AND scheduled to a specific anchor (BD entry, live comment, or new BD); archived reports are not acceptable anchors." The IMPL-REPORT is a workflow artifact destined for archive at v11.0 ship per Pattern B; it is not an acceptable anchor.
  - Per project rule `feedback_deferral_is_scope_creep`: defensible deferral needs (a) size, (b) blockedness, or (c) clear logical fit with different already-scoped work. The IMPL-REPORT §6 rationale rests on "touches the architect-pass binding for BD-119" — but the rewrite is a documentary update to historical framing (one §9 sub-section reframing BD-120 → BD-160 + small cross-reference adjustments). This is not architect-pass-scale; it is the kind of carry-forward closure BD-160 was explicitly chartered to deliver per its own BACKLOG entry.
- **Suggested remediation**: Either (i) land the §9.2 wording update in this batch (lowest-cost: option (c) from IMPL-REPORT — append a one-paragraph addendum to §9.2 pointing at BD-160 as the realized consumer; in-place historical preservation), OR (ii) if the architect-pass review is genuinely needed, surface as a new BD with a concrete forward-pointing anchor and a Resolved-line in BD-160 that names the new BD as the deferred-work follow-on. The "accept-as-is" path leaves the carry-forward orphaned and is unbacked tech debt under `feedback_deferral_is_scope_creep`.

### NIT findings

#### N-1 — README.md Repository Layout block does not list `v11-realistic-ot`

- **Severity**: NIT
- **Location**: `README.md:237-246` (Repository Layout — `test-fixtures/` subtree)
- **Finding**: The Repository Layout subtree at `README.md:237-246` enumerates `v10-minimal`, `v10-realistic-ot`, `v11-flat-file`, `v11-tracker-on`, and `existing-project-mid-dev` as the gitignored built-fixture entries. The newly-added `v11-realistic-ot/` is missing from this list. Per `CLAUDE.md` "Repository Layout block is the authoritative reference," this is a layout-consistency gap.
- **Evidence**:
  - `README.md:243-246` lists the five existing fixtures with one-line descriptions.
  - `FIXTURE_NAMES` array in `build.sh:49-56` now contains six fixture names.
  - **Note**: BD-169b (commit 19g-PM) explicitly covers README.md Repository Layout edits for the per-entry-tree directory naming. The v11-realistic-ot fixture entry is NOT named in BD-169b's File/Symbol field (which focuses on per-entry tree directories like `docs/project/backlog/`); the fixture-layout addition is a logically-different item. NIT-grade because the fixture is gitignored (no checked-in content drift) but the Layout block is documented as authoritative and a reader who scans it will miss the v11-realistic-ot fixture's existence.
- **Suggested remediation**: Add `├── v11-realistic-ot/` row between `v10-realistic-ot/` (line 243) and `v11-flat-file/` (line 244) with a brief description.

#### N-2 — IMPL-REPORT §7 row 2 acknowledges `--all --clean` was not run locally; coverage relies on CI

- **Severity**: NIT
- **Location**: `IMPLEMENTATION-REPORT-BD-160-170.md` §7 row 2
- **Finding**: The verification table row 2 reads: "full `--all --clean` not run to preserve session time, but the v11-realistic-ot path AND the v10-realistic-ot path (the touched code paths) both pass; the other 4 builders were untouched by this session." The acknowledged gap is that pre-commit local verification did NOT exercise the full `--all --clean` sequence; it relies on CI's `validate-pack.yml:210` step to catch any cross-fixture ordering/state issue. CI does run this step on every push, so the gate exists — but the IMPL-REPORT's verification claim is incomplete vs. PLAN §5.7's gate 2 wording ("`bash test-fixtures/build.sh --all --clean` succeeds and produces v11-realistic-ot"). The fixture builders are mostly-independent, but they share `_setup_v10_pack_src` global state (the `V10_PACK_SRC_DIR` lazy-clone), and the manifest-regen step at end of `--all` writes all six rows. NIT because CI will catch a regression and `bash -n` passes.
- **Evidence**:
  - IMPL-REPORT §7 row 2 verbatim wording above.
  - `validate-pack.yml:210` runs `bash test-fixtures/build.sh --all --clean`.
  - PLAN §5.7 verification gate 2 wording: "`bash test-fixtures/build.sh --all --clean` succeeds and produces the v11-realistic-ot fixture."
- **Suggested remediation**: No code change. If Pack Chat wants to upgrade verification rigor for similar future fixture-builder changes, the PLAN gate text could be updated to specify "full local `--all --clean` OR CI green at this commit's SHA on the validate-pack workflow."

#### N-3 — IMPL-REPORT §5 names a "caller-typo" (`bash scripts/validate-pack.py`); the prompt that produced it isn't in-tree but the IMPL-REPORT's wording is unnecessarily judgmental

- **Severity**: NIT
- **Location**: `IMPLEMENTATION-REPORT-BD-160-170.md` §5 (Test suite table — the parenthetical "the prompt's `bash scripts/validate-pack.py` would error at the shebang — caller-typo, treated as `python3 scripts/validate-pack.py`")
- **Finding**: The IMPL-REPORT calls out that the calling prompt named `bash scripts/validate-pack.py` and notes "caller-typo, treated as `python3 scripts/validate-pack.py`." The disposition (running with `python3`) is correct (the file is Python); the framing as "caller-typo" is judgmental about Pack Chat's prompt and adds no value to the artifact. NIT because the technical disposition is fine and the file IS sweep-destined for archive at v11.0 ship.
- **Evidence**: IMPL-REPORT §5 row 1 cell — see the parenthetical.
- **Suggested remediation**: No code change required. Optional: future IMPL-REPORTs can drop judgmental framing about the calling prompt and instead note the substitution as a routine adaptation.

---

## 3 — Test-coverage assessment

**The new functional surface IS exercised in CI.** The validate-pack.yml workflow contains two steps that exercise BD-160 + BD-170's new code path:

1. **`build test fixtures (BD-115/116/117)`** at line 210: `bash test-fixtures/build.sh --all --clean`. Because BD-160 added `v11-realistic-ot` to `FIXTURE_NAMES` (line 52 of build.sh), this step now invokes `_build_realistic_for_version v11`, which runs the BD-160 v11 case dispatch AND the BD-170 per-entry decompose / regenerate / round-trip block. Any failure in BD-170's per-stream round-trip (`die ... 4` per build.sh:532) causes this step to fail.

2. **`fixture manifest verify`** at line 225: `bash test-fixtures/build.sh --verify`. Iterates `FIXTURE_NAMES` (including `v11-realistic-ot`) and compares against `manifest.txt`. Catches non-determinism in the v11 build.

**No dedicated test runner was added for BD-160 / BD-170.** The validation surface is exclusively the build-and-verify step pair. This is acceptable for fixture-builder code because:
- The round-trip cmp -s check IS the test — it's a load-bearing invariant inside the builder itself (build fails if round-trip diverges).
- The manifest SHA pin is a determinism gate.
- The per-entry helpers themselves have dedicated tests (`scripts/tests/test-per-entry.sh` — 57/0 PASS per IMPL-REPORT).
- The v10→v11 migrator's decompose adapter has dedicated tests (`scripts/tests/test-migrate-v10-to-v11-decompose.sh` — 45/0 PASS per IMPL-REPORT).

**No coverage gap surfaces.** The IMPL-REPORT §7 row 2 acknowledges the coder did not run `--all --clean` locally but the CI step exists; if a cross-fixture interaction regression slips in, CI catches it. There is no test-not-in-CI heuristic trip.

---

## 4 — Observations (informational; not findings)

- **O-1.** The `\n---\n\n` inter-section separator that C4 v11 emits at `build.sh:423` is byte-identical to the mirror generator's emit shape at `scripts/lib/per-entry/mirror-generate.sh:130`. The byte-identity round-trip works because C4 writes exactly what the regenerator would emit from intro + 5 entries; the decompose strips back-pointers (none were added because C4 wrote inline content); the regenerator re-emits with back-pointer strip path (no-op for already-stripped content) and matches separator. Verified by code-read; the IMPL-REPORT's claim of REGEN BYTE-IDENTICAL across all 3 streams is sound.
- **O-2.** `PE_FORCE_OVERWRITE_MIRROR=1 per_entry_regenerate_mirror ...` at `build.sh:514` is a per-invocation environment prefix; it does NOT leak into other invocations within the same loop iteration or across iterations (verified by inline bash semantic test). The choice of force flag is correct because C4 just wrote the on-disk mirror, which IS divergent from what the per-entry tree (decomposed in the same iteration) would produce; the helper would otherwise return rc=2 from the non-interactive default branch per `mirror-generate.sh:330-336`.
- **O-3.** The stream tuple format `"key|mirror|dir"` at `build.sh:486-488` is byte-identical to `scripts/init-project.sh:991-994` and `scripts/lib/migrate-v10-to-v11/decompose.sh:145-148`. All three call sites use the same `${spec%%|*}` / `${spec#*|}` decomposition pattern. Adding a fourth project-side stream in the future is a parallel three-line change across all three sites.
- **O-4.** C4 v10 path byte-equivalence vs pre-commit: verified by manual byte-equivalence proof (constructed an isolated repro outside the repo and `cmp -s` confirmed). The `td_entries=$(cat <<'EOF' ... EOF)` extraction followed by `printf '%s\n' "$td_entries"` produces identical bytes to the pre-commit single-heredoc shape. v10-realistic-ot SHA preservation claim (`4c62945f...` per IMPL-REPORT §3) is mechanically sound.
- **O-5.** The `_pe_mirror.orig` snapshot file is cleaned via `rm -f` at `build.sh:537` only on the cmp-s-success path. On any `die` exit before that line (decompose / regenerate / TOC failure or cmp -s failure), the `.orig` file would remain in the in-progress fixture directory. This is mostly cosmetic because: (a) `_fixture_commit_all` is never called on the failure path so the orphan is not committed; (b) the next `--clean` build runs `_fixture_git_init` which `rm -rf`s the target. No leak surfaces in normal operation.
- **O-6.** Determinism risk surfaces analyzed:
  - `mktemp` usages in `_lib.sh:350`, `_lib.sh:380`, `toc-regenerate.sh:49`, `mirror-generate.sh:212` — all use random suffixes but each is renamed to a deterministic target via `mv`; final on-disk content is byte-stable.
  - No timestamps emitted by init-project.sh into project content (`grep` for `date` patterns came up clean; verified by the existing v11-flat-file fixture's deterministic SHA).
  - `_fixture_commit_all` (line 102-112) pins author / committer dates to `FIXTURE_EPOCH` so commit SHAs are stable across rebuilds.
  - Iteration order of stream loop is fixed by the literal `for _pe_spec in ...` list; entry-file iteration inside per_entry_decompose / per_entry_regenerate_mirror is deterministic (lexical sort).
  - IMPL-REPORT §5 verified determinism by running two consecutive `--clean` builds; both produced content-SHA `f5bbb1c1...` and HEAD-SHA `85072fec...`. Determinism claim is sound.
- **O-7.** Cross-reference grep for `BD-120-retro-F2` / "unwired pending BD-160" / "die-sentinel" came up clean except for `IMPLEMENTATION-REPORT-BD-120-RETRO-FIX.md`, which is itself a frozen-historical workflow artifact (sweeps to archive at v11.0). No live stale references.
- **O-8.** `bash -n test-fixtures/build.sh` is clean (verified).
- **O-9.** The BACKLOG BD-160 entry references `scripts/lib/migrator-core.sh lines 459-513` as the helper's location; actual location is now lines 524-566 (the file grew). This is a stale-line-number reference inside the BACKLOG entry the coder was instructed to read; the BACKLOG entry itself flagged this risk inline ("BD-160's coder should re-grep for the actual `[[ -f ]]` site"). Not a defect of this commit (the BACKLOG entry text is PM-only and pre-existed this commit); informational only.

---

## 5 — Definition-of-Done verification (PLAN §5.7 verification gates)

| # | Gate (per PLAN §5.7) | Verdict | Evidence |
|---|---|---|---|
| 1 | `bash scripts/validate-pack.py` PASSES (existing 31 + new Checks 32/33/34) | **PASS** | IMPL-REPORT §5 row 1 cites "PASSED — all checks clean"; Checks 32/33/34 SKIP on pack-self (per pack repo not having per-entry trees yet — pack-self per-entry split lands in Batch 23). |
| 2 | `bash test-fixtures/build.sh --all --clean` succeeds and produces v11-realistic-ot | **PASS (with CI delegation noted)** | Coder ran `--clean --name v11-realistic-ot` directly (succeeded); full `--all --clean` deferred to CI per IMPL-REPORT §7 row 2. CI's validate-pack.yml:210 exercises this exact sequence on every push; gate is operational. See finding N-2 for verification-rigor observation. |
| 3 | Manual integration test per §12.1: byte-identity round-trip — decompose v11-realistic-ot monolithic → regenerate mirror → diff against original → byte-identical | **PASS** | Two-level verification per IMPL-REPORT §5: (a) inline `cmp -s` in build.sh fires per-stream during build and dies on divergence; (b) independent manual replay confirmed `BACKLOG: REGEN BYTE-IDENTICAL`, `IMPLEMENTATION-PLAN: REGEN BYTE-IDENTICAL`, `CHANGELOG: REGEN BYTE-IDENTICAL`. Inline check at `build.sh:526-534` will fire on every CI build. |
| 4 | `bash scripts/test-persona-contracts.sh` PASSES | **PASS** | IMPL-REPORT §5 cites `3/3 passed`; `contract-migration.sh` internal `37 passed, 0 failed`. |
| 5 | BD-160 verification per its spec: v11's `.codex/config.toml` present (ollama-strip path); v11's per-CLI agent dirs accept x-agent file shape per `migrator_target_surface_for_version v11` | **PASS** | IMPL-REPORT §5 confirms `.codex/config.toml` present (5556 bytes); `grep -c ollama = 0` after strip; `grep -c lmstudio = 1` (kept); `x-fakeot-domain.{md,toml}` present in all 3 agent dirs; trinity FakeOT-filled in CLAUDE.md / AGENTS.md / GEMINI.md. |
| 6 | Determinism per integration parent §12.3 | **PASS** | IMPL-REPORT §5 cites two consecutive `--clean --name v11-realistic-ot` builds produced identical content-SHA `f5bbb1c1...` + HEAD-SHA `85072fec...`. |
| 7 | Manifest regenerated per integration parent §12.4 | **PASS** | `test-fixtures/manifest.txt:7` contains `v11-realistic-ot  85072fec8ad59e1badd86e0bde62f943811a7bba`; other rows preserved per IMPL-REPORT §4. |
| 8 | BD-160 + BD-170 combined per Pack-Chat-direct R-2 | **PASS** | Single commit `a57dd04` ships both BD-160 (FIXTURE_NAMES + dispatcher + v11 case body + C4 branching + docstring) and BD-170 (per-entry decompose / regen / round-trip + 4th fixture commit). |

All PLAN §5.7 gates pass. Status flips for BD-160 + BD-170 → Resolved are correctly deferred to commit 19h per PLAN §5.10 (BACKLOG is PM-only).

---

## 6 — Deferral assessment for the ARCHITECTURE-BD-119.md §9.2 update

This section addresses the IMPL-REPORT §6 decision to defer the §9.2 update with recommendation "(a) accept-as-is."

**Per project rule `feedback_deferral_is_scope_creep`**, a defensible deferral rests on one of:
- (a) **size** — the deferred work is genuinely too large to land in the current batch.
- (b) **blockedness** — the deferred work is blocked on something not yet delivered.
- (c) **clear logical fit** with a different already-scoped piece of work.

**Per project rule `feedback_deferred_work_tracking`**, deferred work must be documented in a live forward-pointing surface AND scheduled to a specific anchor (BD entry, live comment, or new BD); archived reports (and reports that will be archived) are not acceptable anchors.

**Assessment of the IMPL-REPORT §6 deferral against these rules:**

- **Size argument (rule a):** The IMPL-REPORT's rationale is that §9.2 is "a structured BD-120-anchored argument (heading + 5 sub-sections + decision rationale + cascading text); rewriting touches the architect-pass binding for BD-119." On reading §9.2 (lines 606-668 of ARCHITECTURE-BD-119.md — 62 lines), the section is a single H2 (`## 9. BD-120 enablement (realistic-OT fixture parameterization)`) with four H3 sub-sections (§9.1, §9.2, §9.3, §9.4). The minimal addendum option from IMPL-REPORT §6's enumeration ("option (c) — edit §9.2 with a one-paragraph 'addendum' note pointing to BD-160 as the realized consumer") is ~3 sentences — clearly NOT architect-pass-scale. The size argument does not defend the deferral.

- **Blockedness argument (rule b):** The §9.2 update is not blocked on anything — BD-160 has now landed; the helper consumer is real; the architecture text is historically anchored on the BD-120 design intent. There is no blocker.

- **Logical-fit argument (rule c):** No other already-scoped Batch 19 BD covers ARCHITECTURE-BD-119.md updates. The §9.2 update logically belongs to BD-160 itself (the BACKLOG BD-160 entry's File/Symbol field explicitly names it as carry-forward). There is no different already-scoped piece of work to absorb it into.

- **Anchor argument (`feedback_deferred_work_tracking`):** The IMPL-REPORT §6 surface that "Surfacing to Pack Chat for disposition" is the entirety of the deferral documentation. The IMPL-REPORT itself is a workflow artifact destined for `maintenance-docs/archive/v11/` at v11.0 ship per Pattern B. After Pack Chat flips BD-160 → Resolved in commit 19h, the BACKLOG entry text still names the §9.2 update in its File/Symbol field, but the Status field is Resolved — a future maintainer reading the entry will see the carry-forward item next to a "done" marker with no way to verify whether it was actually addressed. **There is no live forward-pointing anchor** (no new BD to track the deferred work; no inline live comment in §9.2 itself; no Resolved-line note in BD-160 naming the follow-on).

**Verdict: the deferral is NOT defensible under `feedback_deferral_is_scope_creep` AND is anchorless under `feedback_deferred_work_tracking`.** It will become orphaned tech debt on 19h. The remediation paths from finding S-2 above are:
- **Preferred:** Land the §9.2 update in this batch as option (c) from IMPL-REPORT §6 — a one-paragraph addendum to §9.2 pointing at BD-160 as the realized consumer (in-place historical preservation; trivial size).
- **Alternative:** Surface a new BD to track the deferred §9.2 update, AND name that new BD in BD-160's Resolved-line in 19h so the carry-forward chain remains readable.

The "accept-as-is" recommendation in IMPL-REPORT §6 does not meet either project rule and should not be adopted as-is.

---

## End of report
