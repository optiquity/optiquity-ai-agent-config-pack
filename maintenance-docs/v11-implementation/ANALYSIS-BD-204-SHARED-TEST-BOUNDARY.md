# ANALYSIS — BD-204 C-4: pack/project boundary in the SHARED tracker test suite

**Scope of this doc:** ANALYSIS ONLY. It assesses the current (committed) tracker
test design and BD-204's uncommitted C-4 implementation against the pack/project
boundary. It prescribes ONLY (a) the boundary PRINCIPLE for the shared tracker
tests and (b) a safe-to-commit JUDGMENT. It proposes NO refactor, NO code/test/
architecture change.

**Measurement baseline:** committed HEAD `8572479` (working tree dirty with the
C-4 changes). Date 2026-06-06.

**Files in the C-4 working-tree change set (measured):**
- `scripts/lib/tracker-migrate-reverse.sh` (the shared reverse machinery)
- `scripts/tests/tracker-migrate-reverse-test.sh`
- `scripts/tests/tracker-migrate-roundtrip-test.sh`
- `scripts/tests/tracker-bd132-race-test.sh`
- `scripts/tests/tracker-bd133-header-preservation-test.sh`

---

## 1. Current-design characterization (the shared machinery + the BD/TD test split)

### 1.1 What code is shared between the pack (BD) and project (TD) surfaces

The tracker migration machinery is a single shared library set that serves BOTH
surfaces, branching on a `surface` variable that is auto-detected per repo. The
decode/reconstruct layer is **prefix-agnostic** — it handles `BD-*` and `TD-*`
identically; only the surface BRANCH (where to emit) differs.

> **Empirical-Evidence Block — the reverse decoder is prefix-agnostic (BD + TD).**
> `CMD`: `grep -n 'BD-\*) echo\|TD-\*)' scripts/lib/tracker-migrate-reverse.sh`
> `OUT`:
> ```
> 287:        BD-*) echo "TODO(version)" ;;
> 288:        TD-*)
> ```
> `AT`: HEAD `8572479`, 2026-06-06.
> `INTERP`: `_tmr_decode_type` (and the public `tracker_migrate_reverse_reconstruct`
> decoder it feeds) classifies by `pack_id` prefix — `BD-*` and `TD-*` are both
> first-class decode paths in the SAME function. The decode layer is shared, not
> surface-specific.
> `CONCL`: SUPPORTED.

> **Empirical-Evidence Block — the client `_tmr_emit_backlog` monolith emitter
> sorts BD + TD together.**
> `CMD`: `grep -n 'order = {"BD": 0, "TD": 1}\|_tmr_emit_backlog()' scripts/lib/tracker-migrate-reverse.sh`
> `OUT`:
> ```
> 627:_tmr_emit_backlog() {
> 653:    order = {"BD": 0, "TD": 1}.get(prefix, 9)
> ```
> `AT`: HEAD `8572479`, 2026-06-06.
> `INTERP`: the client/`else`-branch monolith emitter is a single function that
> emits BOTH BD and TD entries into one `# BACKLOG` document, sorted BD-then-TD.
> Shared emitter; the BD/TD distinction is data, not a code fork.
> `CONCL`: SUPPORTED.

> **Empirical-Evidence Block — the per-entry engine is stream-keyed for BOTH
> surfaces already.**
> `CMD`: `grep -n '"pack-backlog":\|"project-backlog":' scripts/lib/per-entry/toc-regenerate.sh`
> `OUT`:
> ```
> 85:    "pack-backlog":                re.compile(r"^BD-\d+[a-z]*\.md$"),
> 88:    "project-backlog":             re.compile(r"^TD-\d+\.md$"),
> ```
> `AT`: HEAD `8572479`, 2026-06-06.
> `INTERP`: the shared per-entry engine (`pe_*` / `per_entry_*`) is parameterized
> by a stream key; `pack-backlog` matches `^BD-\d+[a-z]*\.md$`, `project-backlog`
> matches `^TD-\d+\.md$`. The BD/TD split lives in DATA (the regex table keyed by
> stream), not in duplicated code. Both keys pre-exist C-4.
> `CONCL`: SUPPORTED.

The promotion path (`tracker-promote.sh`) is project-flavored (it gates on
`^TD-[0-9]+$` and rejects BD promotion — "only TDs promote per V3.3 §3"), but it
is a project-surface feature exercised independently; it is not part of the C-4
change set and is not entangled with the pack reverse emit. (Verified:
`scripts/lib/tracker-promote.sh:216,219`.)

**Shared-machinery summary:** the forward run, the reverse decode/reconstruct, the
per-entry engine, and the silent-data-loss guard are all surface-shared and
prefix-agnostic at the decode layer. The ONLY place the surfaces diverge is the
reverse EMIT TARGET (pack → tree under `/backlog/`; client → legacy monolith) and
the per-entry stream-key (which selects the BD-only vs TD-only entry regex).

### 1.2 Where BD vs TD are tested, and whether the entanglement is a smell

The pack test suite exercises BOTH BD and TD fixtures. TD fixtures **pre-existed
BD-204** (they belong to the BD-108-F5 round-trip coverage and the
prefix-agnostic decode unit tests).

> **Empirical-Evidence Block — TD fixtures pre-exist C-4 at committed HEAD.**
> `CMD`: per-file TD-ref count at HEAD —
> `for f in <4 test files>; do git grep -c 'TD-0' HEAD -- $f; done`
> `OUT`:
> ```
> tracker-migrate-roundtrip-test.sh: 20
> tracker-migrate-reverse-test.sh:   10
> tracker-bd132-race-test.sh:         4
> tracker-bd133-header-preservation-test.sh: 0
> ```
> `AT`: HEAD `8572479`, 2026-06-06.
> `INTERP`: `TD-010` and `TD-040` fixtures are present in the COMMITTED suite,
> independent of BD-204. The BD/TD test entanglement is pre-existing, not
> introduced by C-4.
> `CONCL`: SUPPORTED.

The TD coverage at HEAD splits into two distinct KINDS:

1. **Decode-layer coverage (surface-agnostic, correct to live in the pack suite).**
   `reverse-test.sh` Group 1 `1.2` calls `_tmr_decode_type "TD-010" ...` directly
   and asserts `TODO(scope)` / `TODO(dependency)` / `KNOWN GAP(critical)`. These
   test the SHARED decoder's prefix-handling — a property of the shared machinery,
   not of either surface's product. Verified present at HEAD (`reverse-test.sh:158,
   160,162`) and unchanged in the working tree.

2. **Emit-surface coverage (where the smell lived).** At HEAD the same tests
   ALSO asserted TD entries appeared in the PACK reverse's emitted artifact:
   - `reverse-test.sh:345` — `4.2 BACKLOG has TD-010 entry` asserted off
     `pack-ops/BACKLOG.md` (the pack emit target).
   - `roundtrip-test.sh:416` — the `RECON_BACKLOG` needle loop (read from
     `pack-ops/BACKLOG.md`) included `TD-010`, `TD-040`, and their titles.
   - `roundtrip-test.sh:452,474` — TD-040 survival + Blockers asserted by grepping
     the pack `RECON_BACKLOG` monolith.
   - `roundtrip-test.sh:544-546` — the pack reverse SIDECAR asserted `## TD-010` /
     `## TD-040` sections.

   This second kind is the **pre-existing smell**: it asserted PROJECT-prefix (TD)
   entries OFF the PACK emit surface. It was tolerable at HEAD only because the pack
   reverse emitted a BD+TD-commingled monolith (the shared `_tmr_emit_backlog`
   wrote every reconstructed id, BD and TD alike, into `pack-ops/BACKLOG.md`). The
   commingling let a pack-surface assertion incidentally observe TD ids. That is a
   property-mismatch (TD is the project namespace; the pack backlog is BD-only by
   the stream regex `^BD-\d+[a-z]*\.md$`), masked by the monolith's lack of a
   namespace filter.

**Characterization verdict:** the BD/TD test entanglement is **partly by design
and partly a pre-existing smell**. The decode-layer TD coverage (kind 1) is
correct — it tests the shared, prefix-agnostic machinery. The emit-surface TD
coverage (kind 2) was a pre-existing smell: it asserted project-prefix ids off the
pack emit surface, surviving only because the pre-C-4 pack emit was an unfiltered
BD+TD monolith. C-4 surfaces this latent issue because it gives the pack surface a
namespace-correct emit (BD-only tree).

---

## 2. C-4 implementation assessment (uncommitted working tree)

### 2.1 (a) Pack-only compliance — no project PRODUCT touched

> **Empirical-Evidence Block — no `project-template/` or `supporting-docs/` in the
> change set.**
> `CMD`: `git diff --name-only | grep -E '^(project-template/|supporting-docs/)'`
> `OUT`: (empty — no match)
> `AT`: HEAD `8572479` + working tree, 2026-06-06.
> `INTERP`: every C-4 file lives under `scripts/lib/` or `scripts/tests/` — pack-
> side shared libraries and pack-side test infra. Zero project PRODUCT files.
> `CONCL`: SUPPORTED — C-4 is pack-only-compliant for CI Check 36 (`pack-only`
> denies `project-template/` + `supporting-docs/`).

> **Empirical-Evidence Block — the reverse lib contains no project-product path.**
> `CMD`: `grep -c 'project-template\|supporting-docs' scripts/lib/tracker-migrate-reverse.sh`
> `OUT`: `0`
> `AT`: working tree, 2026-06-06.
> `INTERP`: the C-4 reverse changes introduce no reference to project product.
> `CONCL`: SUPPORTED.

`scripts/tests/*` is pack-side TEST INFRA — pack-only-compliant to edit. It is NOT
project product. The pack/project boundary distinguishes (i) project PRODUCT
(`project-template/`, `supporting-docs/` — a violation for BD-204 to touch) from
(ii) pack-side shared libs + test infra (`scripts/` — pack-only, in scope). C-4
touches only (ii). **Pack-only compliance: PASS.**

### 2.2 (b) Did C-4 handle the shared-test boundary correctly, or reshape
project-side (TD) coverage that belongs to BD-207?

C-4's reverse change makes the pack surface emit a **BD-only** tree (the
`_tmr_emit_pack_tree` filter uses the SAME single source — `pe_entry_regex_for_stream
"pack-backlog"` = `^BD-\d+[a-z]*\.md$` — as the backup set and the `_toc.md`
regen, so emit-set == backup-set == toc-set by construction). This is exactly the
design in `ARCHITECTURE-BD-204.md` §4.2:

> "the stream key drives the entry regex `^BD-\d+[a-z]*\.md$` vs the client's
> `^TD-\d+\.md$`" ... "BD-204 wires the pack instance; the shared layer carries NO
> pack-specifics."

The BD-only pack emit is therefore **design-faithful**, not an ad-hoc choice. The
question is whether the consequent TEST reshaping crossed into project (TD)
coverage owned by BD-207. Assessed per assertion KIND:

**Kind-1 (decode-layer TD coverage) — PRESERVED, untouched.** The
`_tmr_decode_type "TD-010"` unit assertions (`reverse-test.sh` Group 1 `1.2`) are
unchanged in the working tree (still at `:154-163`). The shared decoder's TD
prefix-handling stays covered.

**TD-040 reconstruction survival — PRESERVED, relocated to the decode layer.**

> **Empirical-Evidence Block — TD-040 survival now asserted via the public
> reconstruct decoder, not the pack emit surface.**
> `CMD`: `grep -n 'tracker_migrate_reverse_reconstruct\|2.2c TD-040 reconstructs\|2.2c TD-040 Blockers' scripts/tests/tracker-migrate-roundtrip-test.sh`
> `OUT`:
> ```
> 493:TD040_ENTRY=$(tracker_migrate_reverse_reconstruct "$TD040_ISSUE" "$TD040_MAPPING" 2>/dev/null)
> 496:assert_eq "2.2c TD-040 reconstructs with correct pack-id (BD-108 F5)" \
> 514:td040_blockers=$(printf '%s' "$TD040_ENTRY" | jq -r '.blockers // [] | join(",")')
> ```
> `AT`: working tree, 2026-06-06.
> `INTERP`: the pre-C-4 assertion grepped TD-040 out of the pack `RECON_BACKLOG`
> monolith (`roundtrip-test.sh:452,474` at HEAD). C-4 moves the same two properties
> — (1) TD-040 reconstructs with the correct `pack_id`, (2) its `TD-010` Blocker
> round-trips — to the PUBLIC `tracker_migrate_reverse_reconstruct` decoder (the
> same decoder the orchestrator calls per issue). The property tested is unchanged;
> only the OBSERVATION POINT moved from the pack emit surface to the surface-
> agnostic decode layer.
> `CONCL`: SUPPORTED — TD-040 survival coverage is preserved, not deleted.

**Kind-2 (emit-surface TD coverage) — removed/inverted, correctly.** C-4 removes
the assertions that TD ids appear in the PACK emit, and replaces them with NEGATIVE
assertions that TD ids are NOT written to the pack tree (e.g. `roundtrip-test.sh`
`2.2 TD-010/TD-040 NOT emitted to pack tree`; `reverse-test.sh` `4.2 TD-010 NOT
emitted to pack tree`). This is the correct disposition: asserting TD off the PACK
emit surface was the pre-existing smell (§1.2 kind 2). Removing it does NOT remove
project (TD) coverage — it removes an INCORRECT assertion about the PACK surface
that only ever passed because the old pack monolith was namespace-unfiltered.

**Did C-4 reshape coverage owned by BD-207?** No. BD-207 owns the project-side EMIT
surface (the client `_tmr_emit_backlog` monolith branch → eventually
`docs/project/backlog/`). C-4 leaves the client `else` branch UNTOUCHED — verified:
the working-tree diff keeps `_tmr_emit_backlog`, `tracker_header_snapshot_capture/
apply`, `tracker_sidecar_emit`, and the four `tracker_mirror_header_strip` calls in
the `else` branch verbatim. C-4 does not assert anything about the PROJECT emit
surface (there is no `docs/project/backlog/` assertion). The TD ids it stops
asserting were being asserted off the PACK surface, which was never BD-207's
territory. **No BD-207-owned coverage was reshaped.**

### 2.3 (c) Was project-side coverage WEAKENED (TD before vs after)?

Comparing the TD assertions at HEAD vs the working tree:

| TD coverage at HEAD | Disposition in C-4 | Coverage effect |
|---|---|---|
| `_tmr_decode_type "TD-010"` unit asserts (decode layer) | UNCHANGED | Preserved |
| TD-040 reconstructs + Blockers round-trip (grepped off pack monolith) | RELOCATED to public `reconstruct` decoder (2.2c) | Preserved (same property, surface-agnostic observation point) |
| `4.2 BACKLOG has TD-010 entry` (asserted TD in PACK emit) | REMOVED; replaced by NEGATIVE assert (TD NOT in pack tree) | Smell removed; not project coverage |
| roundtrip `RECON_BACKLOG` needle loop incl. TD-010/TD-040 | REMOVED from pack-tree read; survival proven by recon-count + 2.2c | Smell removed; survival still covered |
| sidecar `## TD-010` / `## TD-040` sections | REMOVED (DP-2 drops the sidecar on the pack surface) | Not weakened — the carrier itself is retired by design (DP-2), so there is no pack sidecar to assert |

The TD-ref counts rising (roundtrip 20→25, reverse 10→15) reflect ADDED negative
assertions + the new 2.2c decode-layer block — not a coverage loss.

> **Empirical-Evidence Block — the removed pack-emit TD assertions are exactly the
> kind-2 (smell) set, and the kind-1 decode asserts are retained at HEAD too.**
> `CMD`: `git show HEAD:scripts/tests/tracker-migrate-reverse-test.sh | grep -n '_tmr_decode_type "TD-010"'`
> `OUT`: `158: "TODO(scope)" ...`, `160: "TODO(dependency)" ...`, `162: "KNOWN GAP(critical)" ...`
> `AT`: HEAD `8572479`, 2026-06-06.
> `INTERP`: the decode-layer TD unit asserts exist at HEAD AND in the working tree
> (§2.2). Only the emit-surface (kind-2) TD asserts were removed/inverted. The
> removed set is precisely the pre-existing smell, not genuine project coverage.
> `CONCL`: SUPPORTED — no project-side coverage weakened.

**The one judgment-requiring item — the BD-133 header-preservation Groups 2-4
deletion.** C-4 deletes ~360 lines (Groups 2/3/4) of
`tracker-bd133-header-preservation-test.sh`. These were PACK-surface integration
tests of the header-snapshot on `pack-ops/BACKLOG.md`. Under DP-5 the pack reverse
no longer calls `tracker_header_snapshot_capture/apply` (no monolith preamble
exists), so those integration assertions have no pack-surface target. The module's
direct-API unit tests (Group 1) are KEPT, and the module stays DORMANT for the
client `else` branch (BD-207 will delete it when the last consumer goes). This is a
correct consequence of the no-monolith pack reverse, NOT a weakening of project
coverage — the deleted tests targeted the PACK monolith, which no longer exists on
the pack surface. (This is the largest single deletion; it is in-scope and
boundary-clean, but it is the item most worth a reviewer's eyes.)

---

## 3. The boundary PRINCIPLE for the shared tracker tests (a rule, for BD-207)

The shared tracker machinery is surface-shared and prefix-agnostic at the decode
layer; only the EMIT TARGET and the stream-key entry-regex are surface-specific.
The test boundary follows that same structural seam:

**PRINCIPLE — assert shared properties at the shared layer; assert surface
properties only off that surface's own emit.**

1. **Decode/reconstruct properties are surface-agnostic → test them at the
   decode/reconstruct layer.** A property like "a `TD-*` id decodes its type
   correctly" or "an entry survives forward→state→reverse" is a property of the
   SHARED machinery. Assert it by calling the shared function directly
   (`_tmr_decode_type`, `tracker_migrate_reverse_reconstruct`) — NOT by reading
   some surface's emitted artifact. A `TD-*` fixture is legitimate in the pack test
   suite WHEN AND ONLY WHEN it exercises the shared decode layer, never the pack
   emit surface.

2. **Emit-surface properties are surface-specific → assert each id only off the
   surface that owns its namespace.** The PACK emit (tree under `/backlog/`,
   stream `pack-backlog`, regex `^BD-\d+[a-z]*\.md$`) carries `BD-*` ids ONLY; a
   pack-surface emit test asserts `BD-*` presence and `TD-*` ABSENCE (negative
   assertion), never `TD-*` presence. The PROJECT emit (BD-207's
   `docs/project/backlog/`, stream `project-backlog`, regex `^TD-\d+\.md$`) carries
   `TD-*` ids ONLY; a project-surface emit test asserts `TD-*` presence — and that
   project-surface emit assertion is BD-207's to author, in BD-207's own scope.

3. **A pack-only BD (BD-204) edits ONLY the `surface=="pack"` branch + its tests;
   a project BD (BD-207) edits ONLY the client `else` branch + its tests.** Where
   a shared decode-layer test needs to change, the BD that owns the SHARED-LAYER
   change owns the edit, and the change must stay surface-neutral (it must not bake
   in a pack OR a project emit assumption). The emit-target seam (which BD touches
   which branch) is the boundary line.

4. **Corollary for BD-207:** when BD-207 retires the client monolith and adds the
   project tree emit, it asserts `TD-*` presence off `docs/project/backlog/` (its
   own emit), adds the project negative assertion (no `BD-*` in the project tree),
   and deletes the dormant `tracker-sidecar.sh` / `tracker-header-snapshot.sh`
   modules + their Group-1 unit tests once the last consumer is gone — the
   fail-loud delete BD-204 could not do while staying pack-only. BD-207 does NOT
   re-add any `TD-*`-off-the-pack-surface assertion; those are gone for the correct
   reason.

---

## 4. JUDGMENT — safe to commit?

**SAFE TO COMMIT AS-IS.**

Reasons, with evidence:

1. **Pack-only compliant.** Zero `project-template/` or `supporting-docs/` files;
   zero project-product path references in the edited lib (§2.1). CI Check 36
   `pack-only` will pass. C-4 touches only pack-side shared libs + pack-side test
   infra, both in BD-204 scope.

2. **Boundary handled correctly.** The BD-only pack emit is design-faithful
   (`ARCHITECTURE-BD-204.md` §4.2 stream-key parameterization, regex
   `^BD-\d+[a-z]*\.md$`). C-4 leaves the client `else` branch verbatim — no
   BD-207-owned project EMIT coverage was touched (§2.2).

3. **No project coverage weakened.** Surface-agnostic TD coverage is preserved:
   the decode-layer `_tmr_decode_type "TD-010"` unit asserts are unchanged, and
   TD-040 survival + Blockers round-trip is relocated to the public
   `tracker_migrate_reverse_reconstruct` decoder (§2.3). The only TD assertions
   REMOVED are the kind-2 emit-surface asserts — which were a pre-existing SMELL
   (asserting project-prefix ids off the pack emit, surviving only because the old
   pack monolith was namespace-unfiltered), not genuine project coverage. C-4
   converts them to correct negative assertions.

4. **The largest deletion (BD-133 Groups 2-4) is in-scope and boundary-clean.**
   Those were pack-surface header-snapshot INTEGRATION tests against the pack
   monolith; under DP-5 the pack reverse no longer maintains a monolith preamble,
   so they have no pack-surface target. The module stays dormant for BD-207 with
   its Group-1 unit tests retained. This is the item most worth a reviewer's
   attention, but it is a correct consequence of the no-monolith pack reverse —
   not a defect and not a boundary problem.

**No genuine boundary problem found.** The user's flag — "C-4 reshaped shared TD
test assertions" — is real in that C-4 DID reshape TD assertions; but the reshaping
is the CORRECT disposition of a pre-existing smell (TD asserted off the pack emit),
performed within BD-204's pack-only scope, with all surface-agnostic TD coverage
preserved at the shared layer. There is nothing to resolve before C-4 commits.
(Outside this analysis's scope but noted as a reviewer cue, not a fix: the
load-bearing claim that the negative assertions + decode-layer relocations actually
PASS is a test-execution fact for the C-4 reviewer/coder cycle to verify, not an
architecture-boundary question.)

---

## 5. Rules-Applied Verification Block

| Rule (as named in prompt / CLAUDE.md) | Verification evidence (quoted / measured) | Conclusion |
|---|---|---|
| **Empirical-Evidence Blocks (every state-claim)** | Every state-claim carries a block with CMD + verbatim OUT + HEAD `8572479` + date 2026-06-06 + INTERP + CONCL: §1.1 (prefix-agnostic decode `:287-288`; `_tmr_emit_backlog` BD+TD sort `:653`; stream regex table `:85,:88`); §1.2 (per-file TD counts at HEAD: 20/10/4/0); §2.1 (no project-product diff; `grep -c project-template`=0); §2.2 (`reconstruct` relocation `:493,496,514`); §2.3 (decode asserts retained at HEAD `:158,160,162`). All quoted, none empty. | COMPLIANT |
| **Pack/project separation of concerns** | The analysis distinguishes pack-side TEST INFRA (`scripts/tests/` — pack-only, in scope) from project PRODUCT (`project-template/`/`supporting-docs/` — a violation; measured ABSENT from the diff, §2.1). It separates surface-agnostic decode coverage (shared, correct in the pack suite) from emit-surface coverage (each id off its own surface), and confirms the client `else` branch (BD-207's territory) is untouched. Pack emit is never a project fallback (§3). | COMPLIANT |
| **Pattern-matching anti-pattern** | The verdict is reached by the ACTUAL shared-vs-separate structure (the `surface` branch + the stream-key regex seam, measured §1.1), not by resemblance. The BD-only pack emit is judged design-faithful by property-fit to `ARCHITECTURE-BD-204.md` §4.2's stream-key parameterization, and the removed TD asserts are judged a smell by the property-mismatch (TD = project namespace asserted off the BD-only pack emit), not by surface resemblance to a "boundary violation" template. | COMPLIANT |
| **Analysis-only scope (no redesign)** | Output prescribes ONLY the boundary PRINCIPLE (§3, a rule) + the safe-to-commit JUDGMENT (§4). No refactor, no code/test/architecture change proposed; the smell is surfaced (§1.2) and the disposition is assessed, not redesigned. No file other than this analysis doc was edited. | COMPLIANT |
| **Rules-Applied Verification Block + read-docs-in-full** | This block + the READ-IN-FULL attestation below; every row carries quoted evidence (none empty). | COMPLIANT |

### READ-IN-FULL attestation (per-file direct-read proof, this session)

| # | Artifact | Direct-read proof |
|---|---|---|
| 1 | C-4 uncommitted diff — `tracker-migrate-reverse.sh` | `git diff` read full (the new `_tmr_emit_pack_tree`, the surface-branched emit, the header-snapshot/sidecar gating). |
| 2 | C-4 uncommitted diff — all 4 test files | `git diff` read full for roundtrip / reverse / bd132 / bd133. |
| 3 | Committed baseline (HEAD) of the TD assertions | `git show HEAD:` + `git grep -n 'TD-0' HEAD` for roundtrip + reverse + bd132; per-file counts measured. |
| 4 | `scripts/lib/tracker-migrate-reverse.sh` — pack branch + client `else` branch | Read via the diff + targeted greps (`:287-288` decode, `:627/:653` emit, `:1056` surface branch). |
| 5 | Shared machinery skim — `tracker-migrate-forward.sh` + `tracker-promote.sh` | grep for `surface`/`TD-`/`prefix` (forward `:709,:732` surface branch; promote `^TD-` gate `:216,219`). |
| 6 | per-entry engine stream-key table | `scripts/lib/per-entry/toc-regenerate.sh:85,88` (`pack-backlog`/`project-backlog` regexes) read directly. |
| 7 | `ARCHITECTURE-BD-204.md` §2.9 + §4 | Read directly (855-974): §4.1 tracker-agnostic, §4.2 surface-generalizable (the BD-only-regex-vs-TD-regex design statement), §4.3 dependency-direction; the architect Rules-Applied block. |
| 8 | `PLAN-BD-204.md` § Commit C-4 | grep'd the C-4 section (`:145,281,360,374`) — reverse-emit repoint to tree + header-snapshot retire + sidecar drop; client `else` untouched. |
| 9 | `backlog/BD-204.md` | Read full (1-27) — the pack-only HARD CONSTRAINT, no-monolith, GENERALIZABLE design property, C-5 carry-forward. |
| 10 | `backlog/BD-207.md` | Read full (1-16) — project-side scope, the dormant-module deletion scope addition, the BD-204 reuse-unchanged property. |
| 11 | `CLAUDE.md` `## Pack memory` | Read in full (provided in session context + file 1-576). |
| 12 | `feedback_pack_project_separation_of_concerns.md` | Read full (1-32) this session. |
| 13 | `feedback_bd_pack_only_operational_rule.md` | Read full (1-34) this session. |
| 14 | `feedback_pattern_matching_out_of_context_antipattern.md` | Read full (1-40) this session. |
| 15 | `feedback_architect_planner_empirical_evidence.md` | Read full (1-14) this session. |

**No named document was derived rather than read.** Every C-4 diff file, committed
baseline, architecture/plan/BD doc, shared-lib site, and memory file above was
opened directly via the Read/Bash tools this session at HEAD `8572479`.
