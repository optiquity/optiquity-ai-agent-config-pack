# PLAN-BD-185-V2.md — Commit-sequenced implementation plan for BD-185 (v11.0)

**Status:** Authoritative. Standalone. Supersedes the two prior plan docs in full.
**Authored:** 2026-05-28. **Repo HEAD at planning:** `e580dda7eb46c640a92afabd3469bbada17d1975`.
**Author:** pack-planner (read-only design pass; one output file).
**Scope:** Sequence + verify the already-approved, corrected BD-185 architecture
into commits. Design is FIXED upstream; this doc orders it, sets commit
boundaries, and specifies per-commit verification. Lands entirely in **v11.0**.

---

## §0 — Supersession notice (read first)

This plan **SUPERSEDES** both prior BD-185 plan docs in their entirety:

- `maintenance-docs/v11-implementation/PLAN-BD-185.md`
- `maintenance-docs/v11-implementation/PLAN-BD-185-ADDENDUM.md`

Neither was read during this planning pass (they carry the same categorical
"v11.1" mis-versioning the architecture corrected). A coder needs **neither**
superseded plan to execute this one. This plan is built only from the
corrected, user-approved design inputs (§0.1).

### §0.1 — Authoritative inputs this plan sequences FROM

- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-V2.md` — the
  corrected, standalone architecture (phase-parts, v11.0 correction, FIXED
  grammar, form-family, §10 contamination-correction enumeration Groups A–H).
  **V2 wins for everything except the ordering subsystem.**
- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md`
  — supersedes V2's ordering subsystem precisely per its §0.1 table (V2 §5,
  D-7 mechanism clause, D-8, §7 ordering ops, §6 ordering reads/writes).
  **The addendum wins for ordering; V2 wins for all else.**
- `maintenance-docs/v11-research/RESEARCH-BD-185-ORDERING-API.md` — RG-1 / RG-2
  verified GitHub API call shapes + constraints. RESOLVED; two named residuals
  (RG-1 §8 GraphQL preview header PARTIAL; the 100-children cap documented
  outside the REST reference).
- The BD-185 entry in `pack-ops/BACKLOG.md` (L1746–1792: P1–P4, SC1–SC8,
  File/Symbol, Out-of-scope).
- `CLAUDE.md` § "Pack memory" (process + boundary rules 1–13).

### §0.2 — Contamination guardrail (binding on the coder)

The ONLY legitimate `v11.1` reference in all of BD-185 is **GH Projects
integration** (BD-185 Out-of-scope — a different feature, stays deferred). If
any commit in this plan produces a `v11.1` tag, label, marker, directory, or
"bump" for a phase-parts/ordering artifact, that is the contamination — STOP and
recheck against V2 §0 and the §10 carve-out (the SCHEMA version tag corrects
`phase-part-v11.1` → `phase-part-v11.0`). Every artifact this plan lands is
**v11.0**. There is NO v11.1 archive cut; the phase-part entry type is the 6th
type of the existing v11.0 archive cut.

### §0.3 — The OQ-A1 implement-vs-stub boundary (user-resolved; encoded per commit)

Per the user decision recorded in the addendum §11 OQ-A1 (resolved to the
middle path):

- **FULLY IMPLEMENT + TEST** (all personal-account-testable): the three abstract
  ordering ops (`provider_order_read` / `_write` / `_capability`), the
  capability×availability selector `_order_resolve_mechanism`, the 4-condition
  gate logic (G1 shipped `false`), the universal FLOOR (order-root +
  sub-issue-reprioritize — GA, repo-write-only), all seven consumers routing
  through the abstract ops, migration ordering-writes, the rate-limit throttle
  (A-7), root-chaining (§5.4), and the `tracker.toml [execution_order]` config.
- **DOCUMENTED-STUB ONLY** the GH-Issue-Fields LAYER-3 call shapes (field
  provision / value read / value write) — they need org+admin+preview with no
  personal-account test target. Ship them with the RG-1 verified call shapes
  recorded as typed-TODO comments (`# TODO(version): TD-TBD — …` per
  `project-template/CLAUDE.md` § "Deferral comments and BACKLOG hygiene") so
  future wiring is "fill in the known shape + test." Post-v11.0 wiring/testing
  against a real org target is out of v11.0 scope.

This is the K2-stub posture (addendum §3.4 / §10). The selector still evaluates
the gate (G1=false short-circuits), so the GA switch remains K1 (flip the
boolean) + K2 (replace stub bodies with the recorded shapes). Each work-stream-C
commit below states which half (full-impl vs documented-stub) it carries.

### §0.4 — Planner sizing decisions (made here, with justification)

| # | Decision | Justification |
|---|---|---|
| SZ-1 | **12 commits total: A=2, B=4, C=6.** | Each commit leaves the pack green (validate-pack + relevant per-check tests pass) and binds to one coherent surface group. Finer granularity would split lock-step ENCODING-surface updates (rule 5) across commits and break a green-at-every-step invariant; coarser would bundle unrelated review surfaces. |
| SZ-2 | **OQ-A1 = documented-stub for Issue Fields LAYER-3 (K2-stub).** | The user resolved OQ-A1 to the middle path (§0.3). No personal-account test target exists for org Issue Fields (RG-1 §5: org+admin+preview), so a fully-wired-but-gated path would ship untestable code. The documented stub carries the RG-1 verified shapes verbatim as typed-TODOs, so the GA wiring is mechanical. Selector + gate + floor are fully impl+tested. |
| SZ-3 | **Contamination forward-fix (A) is forward-edit, not git-unwind.** | V2 §10 leaves "git unwind vs forward-edit" to the planner. Forward-edit (relocate files via the working tree, edit content, retire the v11.1 dir) keeps each commit green and auditable; a git-history unwind would rewrite landed BD-185 H.1/H.2 commits (forbidden — agents never rewrite history, and the artifacts are correct in substance). The commit subjects note the forward-fix of the specific v11.1-framing mistakes. |
| SZ-4 | **Phase-parts host scripts: extend `pack-tracker.sh` + add `scripts/pack-phase.sh` for the flat-file verbs.** | `pack-tracker.sh` exists and hosts `pack tracker …` verbs; the tracker-mode `phase split`/`phase reorder` extend it. No `pack-phase.sh` exists today (verified), so the flat-file `pack phase split`/`pack phase reorder` need a new host — `scripts/pack-phase.sh` (filename verified repo-unique, rule 13). The coder confirms wiring into `pack-help.sh`. |
| SZ-5 | **One commit per V2 §10 surface group-cluster, not one per group.** | Groups A+B+C (archive relocation) are one lock-step unit (relocating the SCHEMA, folding the INDEX, and collapsing the form snapshot are interdependent — leaving any one half-done breaks the archive's internal cross-references). Groups D+E+F+G (validator + test + INDEX reword) are a second lock-step unit (the validator, its test, and the INDEX all ENCODE the same expected state per rule 5). See A-1 / A-2. |
| SZ-6 | **Ordering ops land before consumers; consumers land before migration.** | The three abstract ops + selector + capability block are the LAYER-2/3 seam every consumer depends on; they must exist first (C-1, C-2). Consumers (C-3) route through them. Migration ordering-writes (C-4) drive the consumers in bulk and need the throttle. Doctor wiring + root-chaining (C-5) and the reverse-emit/flat-file marker (C-6) close the loop. |

---

## §1 — Goal and BD items addressed

**Goal (BD-185).** Both flat-file and tracker modes express phase splits at
creation, mid-work phase-to-parts expansion, and explicit execution ordering —
without renumbering existing phase or task IDs and without flat-file artifacts
serving as the SSOT in tracker mode. PLUS: correct the v11.1 mis-versioning of
the already-shipped H.1/H.2 phase-parts foundation to v11.0.

**BD items in scope:** BD-185 (the whole entry — P1–P4, SC1–SC8). No new BD is
opened by this plan; the highest existing BD is BD-194 (verified) and BD-185 is
the in-scope entry. The plan covers every SC:

| SC | Addressed by |
|---|---|
| SC1 (split-at-creation = two phases, both modes) | B-1 (parser/emitter encodes born-split-forbidden); B-2 (`phase split` verbs) |
| SC2 (mid-work expansion to Parts, both modes; preserve IDs) | B-1, B-2, B-3 (migration Parts steps) |
| SC3 (no renumber; tracker IDs immutable) | B-2, B-3, C-3..C-6 (order_key is a separate axis) |
| SC4 (ordering both modes; tracker not flat-file-dependent; no GH Projects) | C-1..C-6 (abstract order_key; floor; flat marker) |
| SC5 (STATUS.md stays a dashboard) | C-3 (STATUS display sort, no ownership) |
| SC6 (form-family + smallest template_version delta) | A-1 (no form bump; one new `phase-part-v11.0` template) |
| SC7 (bi-directional sync preserves Part membership + order) | B-3, B-4 (reverse-emit), C-4, C-6 |
| SC8 (v10→v11 + any v11.0 forward-migration absorb whole-number phases) | B-3, C-4 |
| SC-V (v11.0 correctness; no v11.1 cut; D16 resolved) | A-1, A-2 |
| SC-B (boundary rules 1–13) | every commit; reviewer invariant per §4 |

---

## §2 — Affected files (complete inventory, including cross-reference updates)

Grouped by surface. "Inventory file" = listed in `scripts/init-project.sh`
`_CLIENT_INSTALLED_FILES_START/_END` (Check 43 + checks-36-37-38 tests apply).
"Manifest" = under `project-template/` / `scripts/` / `pack-ops/` /
`supporting-docs/` → regenerate `test-fixtures/manifest.txt` in the same commit.

### §2.1 — Work-stream A (contamination forward-fix)

| File | Action | Manifest? | Inventory? |
|---|---|---|---|
| `maintenance-docs/v11-research/templates-archive/v11.1/phase-part-v11.1/SCHEMA.md` | RELOCATE → `…/v11.0/phase-part-v11.0/SCHEMA.md`; correct version tag (title L1, §2 markers L43+L117, §3 label L69, prose L4/L49/L63/L187/L217); fix §5 sibling-SCHEMA cross-refs (`../v11.0/…` → `../…` once co-located) | NO | NO |
| `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md` | RETIRE (fold into v11.0 INDEX) | NO | NO |
| `maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml` | RETIRE (duplicate; collapse into v11.0 snapshot) | NO | NO |
| `maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md` | EDIT: add phase-part 6th-entry-type row; update "Frozen forms" wi-type enumeration to 4 project-template options; Group G reword ("Frozen forms"→"Archived forms"; bare "D16"→"BD-193 bug-fix carve-out") | NO | NO |
| `maintenance-docs/v11-research/templates-archive/v11.0/forms/work-item.yml` | UPDATE to 4-option project-template (client-facing) shape incl. `phase-part-skeleton` (markers already `work-item-v11.0`) | NO | NO |
| `scripts/validate-pack.py` `check_issue_template_forms()` | EDIT comments only L1085–1086, L1117–1127: "added at v11.1 (BD-185 H.2)" → "added in v11.0 (BD-185)" (NO functional change) | YES | NO |
| `scripts/validate-pack.py` `check_template_archive_v11()` | EDIT entry-type loop L1238 `("bd","td","phase-epic","phase-task","inbound")` → add `"phase-part"` (6 types); docstring L5–7 5→6 | YES | NO |
| `scripts/tests/test-issue-forms.sh` | EDIT comments only L12, L18–19, L94–95, L138–142, L161–164, L180, L264–265: v11.1 framing → v11.0 (LEAK test-encoded; NO functional change) | YES | NO |
| `pack-ops/BACKLOG.md` (BD-185 entry prose + BD-193 Resolved line) | FLAG to Pack Chat — PM-only; stale `templates-archive/v11.1/…` path prose. **Coder does NOT edit.** (Group H) | n/a | n/a |
| Workflow artifacts (`IMPLEMENTATION-REPORT-BD-185-*.md`, `PACK-REVIEW-BD-185-*.md`, H.1 NITS report) | NO edit — Pattern B archive-sweep at version ship (Group H) | n/a | n/a |

### §2.2 — Work-stream B (phase-parts implementation)

| File | Action | Manifest? | Inventory? |
|---|---|---|---|
| `scripts/lib/tracker-phase-part.sh` | NEW — Part marker-trio + body-section validate/parse/emit (tracker mode), `phase-part-v11.0`. Filename verified repo-unique (rule 13). | YES | NO |
| `scripts/pack-phase.sh` | NEW — `pack phase split` / `pack phase reorder` (flat-file host). Filename verified repo-unique. | YES | NO |
| `scripts/pack-tracker.sh` | EDIT — add `pack tracker phase split` / `pack tracker phase reorder` subcommands. | YES | NO |
| `scripts/lib/tracker-provider.sh` | EDIT — `provider_sub_issue_create` admits a Part parent (regex `^phase-\d+$` → `^Phase-\d+(\.Part-[a-z])?$`); `provider_create` writes Part marker trio; `provider_link` admits `Phase-N.Part-x` forms; `provider_set_labels` admits `status:*` on Parts. (V2 §7 existing-op changes.) | YES | NO |
| `scripts/lib/tracker-migrate-forward.sh` | EDIT — Parts creation (sub-issue) + task re-parenting on phases carrying H3 Parts (V2 §6.1 Phase B, §6.2). | YES | NO |
| `scripts/lib/tracker-migrate-reverse.sh` | EDIT — reverse-emit H3 `### Part a — <title>` + H4 task grouping (V2 §6.4 / SCHEMA §7 grammar specified in V2 §6.4). | YES | NO |
| `scripts/lib/migrate-v10-to-v11/decompose.sh` | EDIT — preserve `### Part` H3 inline (Phase A), log Phase-B notice (V2 §6.1 Phase A). | YES | NO |
| `supporting-docs/METHODOLOGY.md` § "Multi-part phases" | EDIT — extend for mid-work phase-to-parts expansion mechanism (project-side SSOT, P-missed-7; client-installed → no BD/pack-ops refs). | YES | YES (S6 copy) |
| `scripts/lib/pack-help.sh` (or `pack-help.sh`) | EDIT — register new `phase split` / `phase reorder` verbs in help. | YES | NO |
| `scripts/validate-pack.py` | EDIT — new check(s) for Part-membership invariants if architect-specified (V2 §7); else extend `check_tracker_phase_task_invariants`. | YES | NO |

### §2.3 — Work-stream C (ordering mechanism)

| File | Action | Manifest? | Inventory? |
|---|---|---|---|
| `scripts/lib/tracker-provider.sh` | EDIT — add 3 abstract ops `provider_order_read` / `provider_order_write` / `provider_order_capability` + dispatcher cases; docstrings naming consumers (reconciliation chain). | YES | NO |
| `scripts/lib/tracker-provider-gh.sh` | EDIT — `_order_resolve_mechanism` (selector + 4-cond gate, G1 short-circuit); FLOOR helpers (order-root + reprioritize, RG-2 §2 shapes) FULL; Issue-Fields LAYER-3 helpers DOCUMENTED-STUB (RG-1 §3/§5/§6 shapes as typed-TODOs); `execution_order` capability block in `tracker_provider_gh_capabilities` (net-new, §4.3); root-chaining (§5.4); retained `provider_set_field`/`provider_get_field` re-scoped to gated internals. | YES | NO |
| `scripts/lib/tracker-init.sh` | EDIT — scaffold `tracker.toml [execution_order]` section, `issue_fields_enabled = false` (G1, S8); create order-root issue + link phase epics (floor init, §5.2). | YES | NO |
| `project-template/tracker.toml.project-example` | EDIT — add `[execution_order]` section template (client-facing config; `issue_fields_enabled = false`). | YES | **YES** (L1292) |
| `scripts/lib/tracker-config.sh` | EDIT — teach the schema validator the `[execution_order]` section + fields. | YES | NO |
| `scripts/lib/tracker-doctor.sh` | EDIT — consult `provider_order_capability` (C6); surface resolved mechanism + `cap_per_root` near-boundary warn. | YES | NO |
| `scripts/lib/per-entry/_lib.sh` | EDIT — mirror sort `LC_ALL=C sort` (L401) → tuple `(execution-order, phase_number, filename)` for the phase stream (C1, V2 §5.3). | YES | NO |
| `scripts/lib/tracker-migrate-reverse.sh` | EDIT — `_tmr_emit_implementation_plan` (C1) + `_tmr_emit_status` (C2) sort by `provider_order_read`; write `<!-- execution-order: N -->` into emitted `phase-N.md` (C3). | YES | NO |
| `scripts/lib/tracker-migrate-forward.sh` | EDIT — ordering writes route through `provider_order_write --batch` (C4, throttled A-7). | YES | NO |
| `scripts/lib/migrate-v10-to-v11/decompose.sh` | EDIT — write `<!-- execution-order: N -->` = 1-indexed plan position (Phase A flat marker, C7). | YES | NO |
| `scripts/pack-phase.sh` / `scripts/pack-tracker.sh` | EDIT — `phase reorder` writes via `provider_order_write` (tracker) / rewrites marker + regenerates mirror (flat) (C5). | YES | NO |
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-V2.md` §7 | EDIT — addendum cross-reference note pointing at the ordering addendum + realized ops (reconciliation chain, pack-memory rule). | NO | NO |
| `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md` §11 | EDIT — POST-AUTHORING RESOLUTION note recording the OQ-A1 middle-path decision (reconciliation chain). | NO | NO |
| `scripts/validate-pack.py` | EDIT — ordering check (if added) consults `provider_order_capability`, NEVER a mechanism literal (switch-locality invariant S5). | YES | NO |


---

## §3 — Commit sequence (A → B → C)

Each commit: **ID + subject** (pack commit-message form, `N`=11), **file set**,
**what changes**, **verification** (tests / PREFLIGHT / manifest / per-check),
**review-cycle placement**, **scope keyword** (or none), **dependencies**.

Per pack memory: the per-BD/per-commit review cycle runs INLINE — `coder →
reviewer → triage → fix-coder → commit` — per commit, before the next coder
spawns. Each commit below states "Review cycle: inline (this commit)". The
end-of-batch reviewer runs once after all 12 commits.

Manifest rule: every commit whose diff touches `project-template/` / `scripts/`
/ `pack-ops/` / `supporting-docs/` regenerates + stages `test-fixtures/manifest.txt`
in the SAME commit (run `bash test-fixtures/build.sh --all --clean`, then
`git diff test-fixtures/manifest.txt`; stage if non-empty). All A-2 through C-6
commits touch `scripts/` and/or `supporting-docs/` → ALL regenerate the manifest.
A-1 touches only `maintenance-docs/` → NO manifest regen.

PREFLIGHT line (every coder commit, per pack memory): after all in-scope edits +
verification + (where applicable) validate-pack + per-check tests pass, the coder
emits `PREFLIGHT: N/N in-scope file edits complete; verification PASS; HEAD <SHA>;
about to Write IMPL-REPORT to <path>` then writes the IMPL-REPORT. The
STOP-MEANS-STOP preamble opens every coder prompt.

**Path convention for the recipes that follow (BD-195 F-AC1-01).** All archive
paths in the Work-stream A commit recipes (and the §6.2 commit-A table mapping
back to V2 §10) are relative to `maintenance-docs/v11-research/`; when executing
recipe steps, prefix that path. The inline path forms below have already been
normalized to the full `maintenance-docs/v11-research/templates-archive/...`
shape per BD-195 F-AC1-01 — this preamble is belt-and-suspenders against
future bare-form regression.

---

### Work-stream A — Contamination forward-fix (4 commits)

Clean the committed v11.1 foundation BEFORE building on it. Commit subjects note
the forward-fix of the specific v11.1-framing mistakes.

---

#### Commit A-1 — Relocate phase-part archive into the v11.0 cut (Groups A + B + C)

- **Subject:** `fix: v11 — BD-185 relocate phase-part archive v11.1→v11.0 (forward-fix mis-versioned cut)`
- **Files:**
  - RELOCATE `maintenance-docs/v11-research/templates-archive/v11.1/phase-part-v11.1/SCHEMA.md` →
    `maintenance-docs/v11-research/templates-archive/v11.0/phase-part-v11.0/SCHEMA.md` (with version-tag
    content edits per V2 §10 Group A; grammar substance verbatim).
  - EDIT `maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md` — add phase-part 6th-entry-type row;
    update "Frozen forms" enumeration to 4 project-template options; fold the
    retired v11.1 INDEX content; remove the FALSE Convention-Y claims
    (`status:cancelled` exercise, the work-item bump, the "frozen at 5 subdirs"
    framing) and the D1–D16 cross-ref block (V2 §10 Group B); apply the Group G
    reword ("Frozen forms"→"Archived forms"; bare "D16"→"BD-193 bug-fix
    carve-out") — **see A-1 note on Group G below.**
  - UPDATE `maintenance-docs/v11-research/templates-archive/v11.0/forms/work-item.yml` → 4-option
    project-template (client-facing) shape incl. `phase-part-skeleton` (V2 §10
    Group C / D-9; markers stay `work-item-v11.0`).
  - RETIRE `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md` and
    `maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml` (their content folded above).
    After retiring all three v11.1 files, the `v11.1/` directory is empty and is
    removed. **`git rm` / file deletion is a destructive op → Pack Chat asks the
    user before the coder's working-tree deletions are committed** (pack memory
    `feedback-no-destructive-without-approval`).
- **What changes:** version-framing relocation only. NO grammar substance
  changes (SCHEMA §1–§6, §8 verbatim). The v11.0 cut becomes a 6-entry-type cut.
- **Group G note:** V2 §10 Group G + §11 OPEN-Q-1 flag the "Frozen forms"→
  "Archived forms" reword as *cosmetic, surface-to-user-not-auto-apply*. Per the
  mission prompt, Group G is APPROVED — apply it in A-1. (Pack Chat confirms the
  approval is live before the coder spawns; the reword is in-scope for A-1.)
- **Verification:** `python3 scripts/validate-pack.py` — but note
  `check_template_archive_v11()` still iterates 5 entry types at this commit
  (it gains `phase-part` in A-2). The phase-part subdir now EXISTS but is not yet
  checked; that is fine (the check is INFO-style and additive). The byte-compare
  of `v11.0/forms/work-item.yml` vs the live project-template form must still
  pass (the updated 4-option snapshot matches the live project-template form).
  No per-check test touches the archive path (verified: no script consumes
  `v11.1/`). **No manifest regen** (only `maintenance-docs/` touched).
- **Review cycle:** inline (this commit).
- **Scope keyword:** none — `maintenance-docs/` is neither pack-only-denied nor
  project-template/supporting-docs. (Check 36 only denies `project-template/` +
  `supporting-docs/` for `pack-only`; `maintenance-docs/` is permitted under
  `pack-only`, but a deletion + relocation reads cleanest with no keyword. **Use
  no keyword.**)
- **Dependencies:** none (first commit).

---

#### Commit A-2 — De-contaminate validator + test; extend archive check to 6 types (Groups D + E + F + G-encode)

- **Subject:** `fix: v11 — BD-185 de-contaminate validate-pack/test v11.1→v11.0 framing + 6th archive entry type`
- **Files:**
  - EDIT `scripts/validate-pack.py` `check_issue_template_forms()` — comments
    L1085–1086, L1117–1127: "added at v11.1 (BD-185 H.2)" → "added in v11.0
    (BD-185)" (Group D; NO functional change — `expected_wi_type_options_per_surface`
    already correct).
  - EDIT `scripts/validate-pack.py` `check_template_archive_v11()` — entry-type
    loop (currently `("bd","td","phase-epic","phase-task","inbound")`) → add
    `"phase-part"` (6 types); docstring "five"→"six" (Group E). After A-1 the
    `phase-part-v11.0/SCHEMA.md` exists, so this passes.
  - EDIT `scripts/tests/test-issue-forms.sh` — comments L12, L18–19, L94–95,
    L138–142, L161–164, L180, L264–265: v11.1 framing → v11.0 (Group F; LEAK
    test-encoded; NO functional assertion change).
- **What changes:** version-framing de-contamination of the two ENCODING
  surfaces (rule 5) + the archive-check loop extension. Functional substance
  unchanged.
- **Verification:** **per-check tests REQUIRED** (this commit modifies
  `validate-pack.py` checks + a per-check test):
  - `bash scripts/tests/test-issue-forms.sh` (Group F's own test) — MUST PASS.
  - `bash scripts/tests/test-validate-pack-checks-36-37-38.sh` and
    `bash scripts/tests/test-validate-pack-check-43.sh` (exercise
    `check_issue_template_forms` / inventory surfaces) — MUST PASS.
  - `python3 scripts/validate-pack.py` — full suite PASS.
  - **Manifest regen REQUIRED** (`scripts/` touched): rebuild + stage
    `test-fixtures/manifest.txt`.
- **Review cycle:** inline (this commit).
- **Scope keyword:** `pack-only` (only `scripts/` + `test-fixtures/manifest.txt`;
  no `project-template/` or `supporting-docs/` diff). Confirm diff matches.
- **Dependencies:** A-1 (the `phase-part-v11.0/SCHEMA.md` subdir must exist
  before the 6-type loop check passes).

---

#### Commit A-3 — (none — folded)

> A-3/A-4 are NOT separate commits. The §10 Group H surfaces are PM-only
> (BACKLOG prose) or Pattern-B sweep (workflow artifacts) — **neither is a coder
> edit.** Group H is handled OUTSIDE the commit sequence:
> - **BACKLOG.md BD-185/BD-193 prose** (stale `v11.1/…` paths): Pack Chat
>   reconciles as a PM-only direct edit when the A-1 relocation lands (flag in
>   the A-1 IMPL-REPORT). The coder MUST NOT edit `pack-ops/BACKLOG.md`.
> - **Workflow artifacts** (`IMPLEMENTATION-REPORT-BD-185-*.md`,
>   `PACK-REVIEW-BD-185-*.md`): no edit; they record the error + correction and
>   sweep to `maintenance-docs/archive/v11/` at version ship (Pattern B).

Work-stream A is therefore **2 coder commits (A-1, A-2)** + Group H PM-only
reconciliation (the BACKLOG-prose PM edit + the workflow-artifact Pattern-B
sweep), which are NOT commits. The executable commit total is **12** (A=2, B=4,
C=6); only A-1 and A-2 are coder commits in work-stream A. See §6 coverage map.


---

### Work-stream B — Phase-parts implementation (4 commits)

The SCHEMA + form-family are already shipped (H.1/H.2) — work-stream A handled
their relocation/de-contamination. B builds the runtime: parser/emitter, verbs,
migration Parts steps, reverse-emit. All `phase-part-v11.0` (never v11.1).

---

#### Commit B-1 — `tracker-phase-part.sh` parser/emitter + provider existing-op extensions

- **Subject:** `feat: v11 — BD-185 phase-part parser/emitter library + provider Part-parent support`
- **Files:**
  - NEW `scripts/lib/tracker-phase-part.sh` — marker-trio (`pack-id`,
    `template_version: phase-part-v11.0`, `pack-version`) + body-section
    (Goal / Prerequisites / Member tasks, fixed order) validate / parse / emit
    per FIXED SCHEMA §2/§3/§5 (V2 §4.1). Born-split-forbidden encoded (SC1).
  - EDIT `scripts/lib/tracker-provider.sh` — `provider_sub_issue_create` parent
    regex `^phase-\d+$` → `^Phase-\d+(\.Part-[a-z])?$`; `provider_create` writes
    the Part marker trio for Part entities; `provider_link` admits
    `Phase-N.Part-x` / `Phase-N.Part-x.Task-M` dependency forms;
    `provider_set_labels` admits `status:*` on Parts (no new namespace) — per
    V2 §7 existing-op changes.
- **What changes:** the Part data layer + the provider ops that create/link
  Parts. NO new abstract ops yet (those are work-stream C).
- **Verification:**
  - NEW test `scripts/tests/test-tracker-phase-part.sh` already EXISTS (verified)
    — extend it for the marker-trio + body-section + born-split-forbidden cases;
    `bash scripts/tests/test-tracker-phase-part.sh` MUST PASS.
  - `bash scripts/tests/tracker-provider-test.sh` (provider op surface) MUST PASS.
  - `python3 scripts/validate-pack.py` PASS (no validate-pack change yet, but the
    new lib must not break Check 43 boundary scan).
  - **Manifest regen REQUIRED** (`scripts/` touched).
- **Review cycle:** inline (this commit).
- **Scope keyword:** `pack-only` (only `scripts/` + manifest).
- **Dependencies:** A-2 (clean v11.0 framing must be in place so the new lib's
  `phase-part-v11.0` tag is consistent with the relocated SCHEMA).

---

#### Commit B-2 — `phase split` + `phase reorder` verbs (flat-file + tracker hosts)

- **Subject:** `feat: v11 — BD-185 pack phase split + phase reorder verbs (flat-file + tracker)`
- **Files:**
  - NEW `scripts/pack-phase.sh` — `pack phase split` (flat-file: add `### Part a`
    / `### Part b` H3 to `phase-N.md`, regenerate mirror) + `pack phase reorder`
    (flat-file: rewrite `<!-- execution-order: N -->` marker, regenerate mirror +
    STATUS.md). (Reorder's ordering-write half is wired in C-5; B-2 ships the
    verb skeleton + the Parts split half.)
  - EDIT `scripts/pack-tracker.sh` — `pack tracker phase split` (create
    `phase-part-v11.0` sub-issues via `tracker-phase-part.sh` + re-parent tasks
    via `provider_sub_issue_unlink`/`_create`, preserving task IDs, SC3) +
    `pack tracker phase reorder` (skeleton; ordering-write wired in C-5).
  - EDIT `scripts/lib/pack-help.sh` — register the new verbs.
- **What changes:** the user-facing verbs that create Parts mid-work (SC2) and
  the reorder entrypoints (SC4 — write half lands in C-5). `pack task supersede`
  (the only re-parent-adjacent verb, SCHEMA §2.A) is added here if not present.
- **Verification:**
  - Extend `scripts/tests/test-tracker-phase-task.sh` or add a `phase split`
    case to `test-tracker-phase-part.sh` — exercise split + re-parent + ID
    preservation (SC3) against a scratch GH repo (self-provisioned via `gh`,
    per-step approval, cleanup — pack memory test-infra rule).
  - `bash scripts/tests/pack-help-test.sh` (help registration) MUST PASS.
  - `python3 scripts/validate-pack.py` PASS (Check 43 boundary; pack-help parity
    Check via `check_pack_help_per_cli_parity`).
  - **Per-check test:** `bash scripts/tests/test-validate-pack-check-43.sh` if
    the new host script lands in the inventory (it does NOT — `pack-phase.sh` is
    pack-side, not client-installed; confirm absent from `_CLIENT_INSTALLED_FILES`).
  - **Manifest regen REQUIRED** (`scripts/` touched).
- **Review cycle:** inline (this commit).
- **Scope keyword:** `pack-only`.
- **Dependencies:** B-1 (`tracker-phase-part.sh` + provider Part-parent support).

---

#### Commit B-3 — Parts MIGRATION: sub-issue creation + task re-parenting (forward) + decompose H3 preserve

- **Subject:** `feat: v11 — BD-185 migration Parts creation + task re-parenting (v10→v11 + flat→tracker)`
- **Files:**
  - EDIT `scripts/lib/migrate-v10-to-v11/decompose.sh` — Phase A: preserve
    `### Part` H3 sub-sections inline (decompose anchors on H2), log a notice
    that Phase B will create Part tracker entities (V2 §6.1 Phase A).
  - EDIT `scripts/lib/tracker-migrate-forward.sh` — Phase B / flat→tracker: for
    phases carrying H3 Parts, create `phase-part-v11.0` sub-issues and re-parent
    tasks per the H3 grouping (V2 §6.1 Phase B, §6.2). Task IDs preserved (SC3).
    Write per-Part membership + state to the tracker sidecar (round-trip, SC7).
- **What changes:** migration learns to MATERIALIZE Parts on opt-in. (Ordering
  writes are a SEPARATE concern wired in C-4 — B-3 is Parts-only; it does NOT
  touch ordering reads/writes, which route through the abstract ops added in C.)
- **Verification:**
  - `bash scripts/tests/tracker-migrate-forward-test.sh` MUST PASS (extend for
    an H3-Parts phase fixture).
  - `bash scripts/tests/tracker-migrate-roundtrip-test.sh` MUST PASS (Parts
    survive a round-trip — pairs with B-4).
  - `python3 scripts/validate-pack.py` PASS.
  - **Manifest regen REQUIRED** (`scripts/` touched).
- **Review cycle:** inline (this commit).
- **Scope keyword:** `pack-only`.
- **Dependencies:** B-1, B-2 (Part entity creation + the split verb's
  re-parent primitive).

---

#### Commit B-4 — Reverse-emit Parts (H3/H4 grammar, SCHEMA §7) + METHODOLOGY extension

- **Subject:** `feat: v11 — BD-185 reverse-emit Parts as H3/H4 + METHODOLOGY multi-part extension`
- **Files:**
  - EDIT `scripts/lib/tracker-migrate-reverse.sh` — reverse-emit Part children as
    `### Part a — <title>` H3 sub-sections inside `phase-N.md` with H4 task
    headers grouped under their Part (V2 §6.4 / D-12 — specifies the SCHEMA §7
    TBD grammar). Phase-task body emit carries the Part-scoped identifier where a
    task belongs to a Part. (Ordering reads route through the abstract op in C-6;
    B-4 is Parts-membership-only.)
  - EDIT `supporting-docs/METHODOLOGY.md` § "Multi-part phases" — extend for the
    mid-work phase-to-parts expansion mechanism (V2 §4.3 / §8.2; project-side
    SSOT per P-missed-7 — EXTEND don't invent; client-installed → NO BD/pack-ops
    operational refs per rules 2/4).
- **What changes:** flat-file round-trip carrier for Part membership + the
  human-readable doc extension.
- **Verification:**
  - `bash scripts/tests/tracker-migrate-reverse-test.sh` + `…-roundtrip-test.sh`
    MUST PASS (H3/H4 Parts round-trip).
  - `python3 scripts/validate-pack.py` PASS — note `check_mirror_in_sync` and
    `check_client_installed_files` (METHODOLOGY is a client-installed file, S6).
  - **Per-check tests:** METHODOLOGY is in `_CLIENT_INSTALLED_FILES` →
    `bash scripts/tests/test-validate-pack-check-43.sh` MUST PASS;
    `bash scripts/tests/test-init-project.sh` if the copy-site changes.
  - **Manifest regen REQUIRED** (`supporting-docs/METHODOLOGY.md` is a fixture
    source — S6 copy — AND `scripts/` touched).
- **Review cycle:** inline (this commit).
- **Scope keyword:** none — **mixed surface** (`scripts/` is pack-side;
  `supporting-docs/METHODOLOGY.md` is pack-shipped client content). A `pack-only`
  keyword would FAIL Check 36 on the `supporting-docs/` path. Use neutral framing
  (no keyword). **This is the one B-commit that is genuinely cross-surface.**
- **Dependencies:** B-3 (forward Parts materialization must exist for the
  round-trip test to pass).


---

### Work-stream C — Ordering mechanism (6 commits)

Per the addendum. The OQ-A1 split (§0.3) is explicit per commit: **FULL** =
fully implemented + tested; **STUB** = documented-stub with RG verified shapes
as typed-TODOs. The switch-locality REVIEW INVARIANT (addendum §10) applies to
every C commit: no consumer or validator may contain a mechanism literal
(`"issue_fields"`); ordering checks consult `provider_order_capability`.

---

#### Commit C-1 — Three abstract ordering ops + dispatcher + `execution_order` capability block

- **Subject:** `feat: v11 — BD-185 abstract ordering ops (order_read/write/capability) + capability descriptor`
- **Files:**
  - EDIT `scripts/lib/tracker-provider.sh` — add `provider_order_read`,
    `provider_order_write` (incl. `--batch` form), `provider_order_capability`
    (addendum §4.1) + dispatcher cases (mirror the existing 18-op dispatch).
    **FULL.** Docstrings name the seven consumers + the resolver (reconciliation
    chain, pack-memory rule).
  - EDIT `scripts/lib/tracker-provider-gh.sh` — add the `execution_order` STATIC
    capability block to `tracker_provider_gh_capabilities` (net-new — verified
    absent today; addendum §4.3): `mechanisms`, `floor`, per-mechanism scope
    descriptors. **FULL.**
- **What changes:** the LAYER-2 consumer-facing ordering surface + the STATIC
  capability descriptor. No selector/floor/stub bodies yet (C-2). The ops
  dispatch to GH backend functions that C-2 fills.
- **OQ-A1:** FULL (the abstract ops + capability block are
  personal-account-testable via mocked dispatch).
- **Verification:**
  - `bash scripts/tests/tracker-provider-test.sh` — extend for the 3 new ops +
    the `execution_order` capability block; MUST PASS.
  - `python3 scripts/validate-pack.py` PASS (Check 43 boundary; no validate-pack
    ordering check yet — added only if architect-specified, C-5/C-6).
  - **Manifest regen REQUIRED** (`scripts/` touched).
- **Review cycle:** inline (this commit). **Reviewer invariant:** confirm the
  capability block lists STATIC candidates only (no gate/environment); confirm
  no consumer yet references a mechanism literal.
- **Scope keyword:** `pack-only`.
- **Dependencies:** B-1 (provider surface conventions); independent of B-2..B-4.

---

#### Commit C-2 — Selector + 4-condition gate (G1=false) + FULL floor + STUB Issue-Fields LAYER-3

- **Subject:** `feat: v11 — BD-185 capability×availability selector + sub-issue-reprioritize floor (Issue-Fields gated/stubbed)`
- **Files:**
  - EDIT `scripts/lib/tracker-provider-gh.sh`:
    - `_order_resolve_mechanism()` — the capability×availability selector
      (addendum A-3/§3.2) + the 4-condition gate (A-4: G1 read from
      `tracker.toml [execution_order] issue_fields_enabled`, **shipped false**,
      short-circuits before G2–G4 network probes). **FULL.**
    - FLOOR helpers `tracker_provider_gh__order_read/write_sub_issue()` —
      order-root + reprioritize realization using RG-2 §2 EXACT REST shape
      (`PATCH .../sub_issues/priority`, body `{sub_issue_id, after_id|before_id}`
      — issue **id** not number) + GraphQL analog; read via `provider_sub_issue_list`
      sibling order (addendum §5.2). **FULL — personal-repo-testable (repo-write
      only).**
    - Issue-Fields LAYER-3 helpers `tracker_provider_gh__order_read/write_issue_fields()`
      + field-provisioning — **DOCUMENTED STUB.** Bodies record the RG-1 verified
      shapes as typed-TODO comments (`# TODO(version): TD-TBD — wire Issue-Fields
      ordering: PUT /repos/{owner}/{repo}/issues/{n}/issue-field-values body
      {issue_field_values:[{field_id,value}]}, perm Issues:write, RG-1 §3; field
      def POST /orgs/{org}/issue-fields {name,data_type:number} admin:org RG-1
      §5; read GET …/issue-field-values RG-1 §6; REST-first per A-8`). The stub
      is reached only if G1 flips true → never at runtime in v11.0.
    - Retain `provider_set_field`/`provider_get_field` re-scoped to gated
      Issue-Fields internals (addendum §4.2) — they ship as the field-write
      primitives the stub will call; NOT consumer-facing.
- **What changes:** selection resolves to the FLOOR in v11.0 (G1 off). The GA
  switch is K1 (flip G1) + K2 (replace the stub bodies with the recorded shapes).
- **OQ-A1:** selector + gate + floor = **FULL**; Issue-Fields LAYER-3 = **STUB**
  (this is the commit where the boundary lives).
- **Verification:**
  - `bash scripts/tests/tracker-provider-test.sh` — FULL floor: integration-test
    against a **self-provisioned scratch GH repo** (`gh` CLI, per-step approval,
    cleanup — pack memory): create order-root, link phase-epic sub-issues,
    `provider_order_write` reprioritizes, `provider_order_read` returns sibling
    order. The STUB Issue-Fields path: unit-test the SELECTOR with G1 toggled
    (mocked) — assert G1=false → resolves to floor; assert G1=true + mocked
    org/admin → would-select issue_fields (no live call, the stub asserts the
    typed-TODO presence). MUST PASS.
  - `python3 scripts/validate-pack.py` PASS — including `check_td_tbd_sentinels`
    (the typed-TODO `TD-TBD` markers in the stub must satisfy the sentinel
    format; the coder uses `# TODO(version): TD-TBD — …` exactly).
  - **Manifest regen REQUIRED** (`scripts/` touched).
- **Review cycle:** inline (this commit). **Reviewer invariant:** (i) the floor
  is mechanism-correct (id-not-number per RG-2 §2); (ii) the stub carries the
  RG-1 shapes verbatim as typed-TODOs; (iii) `_order_resolve_mechanism` is the
  ONLY place a mechanism name appears — no consumer literal; (iv) G1 ships false.
- **Scope keyword:** `pack-only`.
- **Dependencies:** C-1 (the abstract ops dispatch into these backend helpers).

---

#### Commit C-3 — Consumer routing (mirror sort, STATUS.md display, reorder verbs)

- **Subject:** `feat: v11 — BD-185 route ordering consumers through abstract ops (mirror/STATUS/reorder)`
- **Files:**
  - EDIT `scripts/lib/per-entry/_lib.sh` — mirror sort at L401 (`LC_ALL=C sort`)
    → tuple `(execution-order, phase_number, filename)` for the phase stream
    (C1; default to phase number if marker absent, V2 §5.3).
  - EDIT `scripts/lib/tracker-migrate-reverse.sh` — `_tmr_emit_implementation_plan`
    (C1) + `_tmr_emit_status` (C2) sort by `provider_order_read` (NOT a
    mechanism-specific read). STATUS.md DISPLAYS sorted order, never owns it
    (SC5, addendum §5.4 / C2). **(The H3/H4 Part-membership emit landed in B-4;
    C-3 adds only the ordering sort + the `<!-- execution-order: N -->` write —
    see C-6 for the marker write itself; C-3 is the SORT.)**
  - EDIT `scripts/pack-phase.sh` + `scripts/pack-tracker.sh` — `phase reorder`
    write half: flat-file rewrites the marker + regenerates; tracker calls
    `provider_order_write <phase> <key>` (C5). Sparse keys allowed (insert at 2.5).
- **What changes:** all order-reading + order-writing consumers route through the
  abstract ops. Zero mechanism literals in any consumer (the §8 switch-locality
  proof for S1–S7).
- **OQ-A1:** FULL (consumers are mechanism-blind; testable via the floor).
- **Verification:**
  - `bash scripts/tests/test-per-entry.sh` — mirror sort by execution-order
    tuple; MUST PASS.
  - `bash scripts/tests/tracker-migrate-reverse-test.sh` — STATUS/plan sort by
    `provider_order_read`; MUST PASS.
  - `python3 scripts/validate-pack.py` PASS — `check_mirror_in_sync`.
  - **Manifest regen REQUIRED** (`scripts/` touched).
- **Review cycle:** inline (this commit). **Reviewer invariant:** grep every
  touched consumer for `issue_fields` / `reprioritize` / `issue-field` literals
  → MUST be zero; ordering reads go through `provider_order_read`, capability
  checks through `provider_order_capability` (addendum §10 / §8 asymmetric-guard).
- **Scope keyword:** `pack-only`.
- **Dependencies:** C-1, C-2 (the ops + floor must exist + resolve).

---

#### Commit C-4 — Migration ordering-writes (throttled) — v10→v11 + flat→tracker

- **Subject:** `feat: v11 — BD-185 migration ordering-writes via batch op with secondary rate-limit throttle`
- **Files:**
  - EDIT `scripts/lib/migrate-v10-to-v11/decompose.sh` — Phase A writes
    `<!-- execution-order: N -->` = 1-indexed `IMPLEMENTATION-PLAN.md` position
    (current implementation order, P4; C7 flat marker, addendum §6.1).
  - EDIT `scripts/lib/tracker-migrate-forward.sh` — Phase B / flat→tracker:
    ordering writes route through `provider_order_write --batch` (C4); the batch
    path THROTTLES to ≤80 content-generating req/min and ≤500/hr (addendum A-7;
    implemented ONCE at the abstract-op batch layer, not per mechanism). Resolver
    selects the floor (G1 off) → batch becomes order-root linking + sibling
    ordering. Execution-note handling: structured warning, no auto-ordering,
    default = phase number (V2 §6.3 — UNCHANGED, operates on the abstract key).
- **What changes:** migrations initialize the ordering value from current
  implementation order (SC8) through the abstract op; the throttle honors the
  binding secondary cap regardless of selected mechanism.
- **OQ-A1:** FULL (the throttle + batch write are mechanism-agnostic; tested via
  the floor).
- **Verification:**
  - `bash scripts/tests/tracker-migrate-forward-test.sh` — extend: OT-style
    60-phase fixture (V2 §6.3 worked example) → `execution-order = phase_number`
    1..60; floor links 60 ordered siblings under one order-root (< 100 cap).
    Throttle: assert the batch path paces writes (mock the clock/counter — no
    need to actually wait; assert the throttle gate is consulted).
  - `bash scripts/tests/tracker-migrate-roundtrip-test.sh` MUST PASS (order
    survives round-trip).
  - `python3 scripts/validate-pack.py` PASS.
  - **Manifest regen REQUIRED** (`scripts/` touched).
- **Review cycle:** inline (this commit). **Reviewer invariant:** the throttle is
  at the abstract-op layer (one implementation); the migrator is mechanism-blind
  (no literal); whole-number phases pass through unrenumbered (SC3/SC8).
- **Scope keyword:** `pack-only`.
- **Dependencies:** C-1, C-2, C-3 (ops + floor + reorder write path).

---

#### Commit C-5 — `tracker.toml [execution_order]` scaffold + order-root init + doctor wiring + root-chaining

- **Subject:** `feat: v11 — BD-185 [execution_order] config scaffold (issue_fields_enabled=false) + order-root init + doctor`
- **Files:**
  - EDIT `scripts/lib/tracker-init.sh` — scaffold the `tracker.toml
    [execution_order]` section, `issue_fields_enabled = false` (G1, S8); create
    the singleton order-root issue + link phase epics as sub-issues at init
    (floor init, addendum §5.2); root-chaining when phase count > 100 (addendum
    §5.4 — `ceil(phase_count/100)` chained roots, depth 2). **FULL.**
  - EDIT `project-template/tracker.toml.project-example` — add the
    `[execution_order]` section template with `issue_fields_enabled = false`
    (client-facing config). **This file IS in `_CLIENT_INSTALLED_FILES` (L1292).**
  - EDIT `scripts/lib/tracker-config.sh` — teach the schema validator the
    `[execution_order]` section + field types (so `check_tracker_config` passes).
  - EDIT `scripts/lib/tracker-doctor.sh` — consult `provider_order_capability`
    (C6 consumer); surface the resolved mechanism + `cap_per_root: 100` warn near
    the chaining boundary. **FULL.**
- **What changes:** the policy gate surface (S8 = K1 switch point) + the floor's
  order-root provisioning + doctor's resolved-mechanism report.
- **OQ-A1:** FULL (config scaffold, order-root init, doctor are all
  personal-repo-testable; G1 ships false).
- **Verification:**
  - `bash scripts/tests/tracker-init-test.sh` — `[execution_order]` scaffolded
    with `issue_fields_enabled=false`; order-root created + phase epics linked;
    root-chaining at >100 (synthetic count). MUST PASS.
  - `bash scripts/tests/tracker-config-test.sh` + `…-config-schema-test.sh` —
    the new section validates. MUST PASS.
  - `bash scripts/tests/tracker-bd130-doctor-wired-test.sh` — doctor consults
    `provider_order_capability`. MUST PASS.
  - **Per-check tests REQUIRED** (`tracker.toml.project-example` is in the
    inventory): `bash scripts/tests/test-validate-pack-check-43.sh` and
    `bash scripts/tests/test-validate-pack-checks-36-37-38.sh` MUST PASS (the
    inventory expected_extras for `tracker.toml.example` must still match —
    confirm no inventory drift from the content edit).
  - `python3 scripts/validate-pack.py` PASS — `check_tracker_config`,
    `check_client_installed_files`.
  - **Manifest regen REQUIRED** (`project-template/` + `scripts/` touched).
- **Review cycle:** inline (this commit). **Reviewer invariant:** G1 default is
  `false` in BOTH the scaffold writer AND `_order_resolve_mechanism`'s hard
  default (addendum K1); doctor reads `provider_order_capability`, not a literal.
- **Scope keyword:** none — **mixed surface** (`scripts/` pack-side +
  `project-template/tracker.toml.project-example` pack-shipped client content). A
  `pack-only` keyword FAILS Check 36 on the `project-template/` path. No keyword.
- **Dependencies:** C-1, C-2 (the capability op + selector G1 read).

---

#### Commit C-6 — Reverse-emit ordering reads + flat-file marker + reconciliation chain

- **Subject:** `feat: v11 — BD-185 reverse-emit execution-order marker via abstract read + architect-doc reconciliation`
- **Files:**
  - EDIT `scripts/lib/tracker-migrate-reverse.sh` — reverse-emit writes
    `<!-- execution-order: N -->` = `provider_order_read` abstract key into each
    emitted `phase-N.md` (C3, addendum §6.4). (B-4 added the H3/H4 Part-membership
    emit; C-3 added the SORT; C-6 adds the MARKER WRITE — the flat-file order_key
    realization, C7.)
  - EDIT `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-V2.md` §7 — add
    the addendum cross-reference note (reconciliation chain (b): architect-doc
    addendum pointing at the realized ordering ops + the addendum doc).
  - EDIT `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-V2-ORDERING-ADDENDUM.md`
    §11 — add the OQ-A1 POST-AUTHORING RESOLUTION note recording the middle-path
    decision (selector+gate+floor FULL; Issue-Fields LAYER-3 documented-stub).
  - EDIT `scripts/validate-pack.py` — IF the architect-specified ordering
    invariant check is added (V2 §7 "new check(s)"), it consults
    `provider_order_capability` and contains NO mechanism literal (S5 invariant).
    If no check is warranted, this file is untouched in C-6.
- **What changes:** closes the flat-file round-trip for ordering (SC7) + lands
  the reconciliation chain (docstrings were added in C-1; the architect-doc
  addenda + IMPL-REPORT links complete it per the pack-memory rule).
- **OQ-A1:** FULL (reverse-emit marker is mechanism-blind via `provider_order_read`).
- **Verification:**
  - `bash scripts/tests/tracker-migrate-reverse-test.sh` + `…-roundtrip-test.sh`
    — execution-order marker round-trips losslessly. MUST PASS.
  - **Per-check test REQUIRED IF validate-pack gains an ordering check:** add +
    wire `scripts/tests/test-validate-pack-check-<NN>.sh` and the CI workflow row
    (`.github/workflows/validate-pack.yml` — enumerate the new test); run
    `bash scripts/tests/test-ci-workflow-wires-checks.sh` analog
    (`check_ci_workflow_wires_per_check_tests` enforces this). If no new check,
    no per-check test.
  - `python3 scripts/validate-pack.py` PASS.
  - **Manifest regen REQUIRED** (`scripts/` touched; the `maintenance-docs/`
    edits do not affect fixtures but the `scripts/` edit does).
- **Review cycle:** inline (this commit). **Reviewer invariant:** the
  reconciliation chain is complete (docstring + V2 §7 addendum note + addendum
  §11 OQ-A1 note + IMPL-REPORT links); any new validate-pack check has no
  mechanism literal (S5); the GA switch is provably K1 (+ K2-stub replacement).
- **Scope keyword:** none — **mixed surface** (`scripts/` + `maintenance-docs/`;
  the latter is not project-template/supporting-docs, so `pack-only` would NOT
  fail Check 36 here — but if the C-6 validate-pack check + CI wiring land, the
  diff is purely `scripts/` + `maintenance-docs/` + `.github/`, all `pack-only`-
  permitted. **Use `pack-only`** unless the architect-check requires a
  project-template fixture change, in which case use no keyword. Coder confirms
  diff before claiming the keyword.)
- **Dependencies:** C-1..C-5 (full ordering stack); B-4 (Part-membership emit
  co-located in the same reverse-emit function — coordinate edits).


---

## §4 — Reviewer invariants (apply across all commits)

These are checked at EVERY inline review, not just where noted above:

1. **Zero v11.1 reintroduction.** Grep each diff for `v11.1` / `phase-part-v11.1`
   / `work-item-v11.1` → MUST be absent (the only legitimate `v11.1` is the
   GH-Projects Out-of-scope reference, which no commit here touches).
2. **Switch-locality (addendum §10, work-stream C).** No consumer (C1–C7) or
   validator (S5) contains a mechanism literal (`"issue_fields"`,
   `reprioritize`, `issue-field`); ordering reads go through `provider_order_read`,
   capability checks through `provider_order_capability`. A literal leaking into
   S1–S7 is a LEAK (operational) → reject.
3. **OQ-A1 boundary.** Issue-Fields LAYER-3 is documented-stub (typed-TODOs with
   RG-1 shapes); everything else is full-impl. G1 ships `false` in both the
   scaffold writer and the resolver default.
4. **Boundary rules 1–13** (V2 §1.5): deliverable-only (pack scripts construct
   project-side tracker state → ALLOWED); DISJOINT invariant (pack-root `{bd}` vs
   project-template 4-option); pack/project separation; no BD operational refs in
   client-facing surfaces (METHODOLOGY, project-template form); tracker-portability
   (ordering via abstract ops so future backends slot in); enumerate-ENCODING
   (validator + test + INDEX + CI update in lock-step).
5. **SC3 invariant.** No commit renumbers a phase number or task ID; `order_key`
   is a separate axis.
6. **Reconciliation chain** (C-1 docstrings + C-6 architect-doc addenda +
   IMPL-REPORT links) is complete for the net-new ordering ops (pack-memory
   "Architect-doc-vs-reality reconciliation").
7. **Typed-TODO format.** Stub deferrals use `# TODO(version): TD-TBD — title`
   (Python `#`); never plain-English markers (pack-memory "Pack-repo code-comment
   deferrals").

---

## §5 — Verification strategy

### §5.1 — The universal FLOOR: live-GH integration test (personal account)

The floor (order-root + sub-issue-reprioritize) is repo-write-only and
personal-repo-testable (RG-2 §2 permission = "Issues" repo write). Integration
tests (C-2, C-4, C-5) provision a **scratch GH repo** via `gh` CLI with per-step
approval and clean up after (pack-memory "Test infra is self-provisioned" — never
touch a real repo; use scratch repos or `/tmp` clones). The test exercises:
create order-root → link phase-epic sub-issues → `provider_order_write`
reprioritizes (`PATCH .../sub_issues/priority`, id-not-number) → `provider_order_read`
returns sibling order → root-chaining at synthetic >100 count.

### §5.2 — The STUBBED Issue-Fields path: unit-test (mocked, no live target)

Issue Fields needs org+admin+preview (RG-1 §5) — no personal-account target.
Tested WITHOUT a live target by:
- **Selector unit-test (C-2):** toggle G1 in a mocked `tracker.toml`; assert
  G1=false → resolves to floor (the v11.0 ship behavior); assert G1=true + mocked
  org/admin metadata → would-select `issue_fields` (no live call — the test
  asserts the resolution decision + the presence of the typed-TODO shapes in the
  stub body).
- **Shape-presence assertion:** the stub bodies carry the RG-1 verified call
  shapes as typed-TODO comments; a test greps for the recorded REST shapes
  (`POST /orgs/{org}/issue-fields`, `PUT …/issue-field-values`) so a future
  wiring pass has the verified shape in place. No network call is made.

### §5.3 — The manifest + per-check-test gates (per commit)

- **Manifest:** A-2, B-1..B-4, C-1..C-6 all touch `scripts/` and/or
  `project-template/` / `supporting-docs/` → each regenerates
  `test-fixtures/manifest.txt` (`bash test-fixtures/build.sh --all --clean`;
  stage if `git diff` non-empty). A-1 (maintenance-docs only) does NOT.
- **Per-check tests** (run BEFORE the PREFLIGHT line, MUST PASS):
  - A-2: `test-issue-forms.sh`, `test-validate-pack-checks-36-37-38.sh`,
    `test-validate-pack-check-43.sh` (modifies `check_issue_template_forms` +
    `check_template_archive_v11` + a per-check test).
  - B-4 / C-5: `test-validate-pack-check-43.sh` +
    `test-validate-pack-checks-36-37-38.sh` (touch `_CLIENT_INSTALLED_FILES`
    surfaces — METHODOLOGY, `tracker.toml.project-example`).
  - C-6 (only if a new validate-pack ordering check lands): new
    `test-validate-pack-check-<NN>.sh` + CI workflow row + re-run
    `check_ci_workflow_wires_per_check_tests`.
- **Full suite:** `python3 scripts/validate-pack.py` PASS at EVERY commit (the
  green-at-every-step invariant, SZ-1).

### §5.4 — End-of-batch review

After all 12 coder commits, a single end-of-batch `pack-reviewer` pass runs on
the full BD-185 batch (per pack memory: one end-of-batch review after per-BD/
per-commit inline cycles). Then BD-185 flips `Open` → `Resolved` (implicit
status flip on clean batch completion) — Pack Chat PM-only edit.

---

## §6 — Coverage map (proves completeness — nothing in scope unmapped)

### §6.1 — Commit accounting

**12 coder commits**: A=2 (A-1, A-2), B=4 (B-1..B-4), C=6 (C-1..C-6). PLUS
**2 Group H non-coder reconciliations** (BACKLOG prose PM-only edit; workflow-
artifact Pattern-B sweep flag) — tracked work-stream-A items that are NOT coder
commits and do NOT count toward the commit total. The executable commit total is
**12**; the 2 Group H items are handled out-of-band by Pack Chat. The
coder executes A-1, A-2, B-1..B-4, C-1..C-6 in that order; Pack Chat handles the
2 Group H items out-of-band (A-1 IMPL-REPORT flags the BACKLOG prose).

### §6.2 — V2 §10 contamination-correction groups (A–H) → commit

| §10 Group | What | Commit |
|---|---|---|
| **A** — relocate phase-part SCHEMA v11.1→v11.0 + version-tag content edits | Archive relocation | **A-1** |
| **B** — fold phase-part into v11.0 INDEX; retire v11.1 INDEX; drop false Convention-Y claims | INDEX fold | **A-1** |
| **C** — collapse to single v11.0 (project-template-shaped) form snapshot; retire v11.1 form | Form snapshot | **A-1** |
| **D** — de-contaminate `check_issue_template_forms()` comments | validate-pack comments | **A-2** |
| **E** — extend `check_template_archive_v11` to 6 entry types | validate-pack loop | **A-2** |
| **F** — de-contaminate `test-issue-forms.sh` comments (LEAK test-encoded) | test comments | **A-2** |
| **G** — `v11.0/INDEX.md` "Frozen forms"→"Archived forms"; bare "D16"→"BD-193 bug-fix carve-out" (APPROVED) | INDEX reword | **A-1** |
| **H** — PM-only BACKLOG prose + Pattern-B workflow artifacts | Non-coder | **PM Chat (flagged in A-1 IMPL-REPORT) / version-ship sweep** |

### §6.3 — Addendum net-new surfaces (§10 handoff list) → commit

| Addendum surface | Commit | OQ-A1 |
|---|---|---|
| 3 abstract ops (`provider_order_read/_write/_capability`) + dispatcher cases | **C-1** | FULL |
| `execution_order` STATIC capability block (§4.3, net-new — verified absent) | **C-1** | FULL |
| `_order_resolve_mechanism` selector + 4-cond gate (G1 false short-circuit) | **C-2** | FULL |
| Universal FLOOR helpers (order-root + reprioritize, RG-2 §2) | **C-2** | FULL |
| Gated Issue-Fields LAYER-3 helpers (RG-1 §3/§5/§6 shapes) | **C-2** | **STUB** |
| `provider_set_field`/`provider_get_field` re-scoped to gated internals | **C-2** | (primitive; behind stub) |
| `tracker.toml [execution_order]` scaffold, `issue_fields_enabled=false` (S8) | **C-5** | FULL |
| Order-root init at `pack tracker init` | **C-5** | FULL |
| Root-chaining 100-cap (§5.4) | **C-5** | FULL |
| `provider_order_capability` → `pack tracker doctor` wiring (C6) | **C-5** | FULL |
| Rate-limit throttle at abstract-op batch layer (A-7) | **C-4** | FULL |
| Consumer routing: mirror sort (C1), STATUS display (C2), reorder verbs (C5) | **C-3** | FULL |
| Consumer routing: migration ordering-writes (C4) | **C-4** | FULL |
| Consumer routing: reverse-emit ordering reads (C3) + flat marker (C7) | **C-6** | FULL |
| Reconciliation chain (docstrings + V2 §7 note + addendum §11 OQ-A1 note) | **C-1 (docstrings) + C-6 (doc addenda)** | n/a |
| Switch-locality review invariant (S5: no mechanism literal in validate-pack) | **§4 invariant; enforced C-1..C-6** | n/a |

### §6.4 — Phase-parts implementation pieces (V2 §4 / §6) → commit

| V2 piece | Commit |
|---|---|
| `tracker-phase-part.sh` parser/emitter (marker-trio + body-section) (V2 §4.1, D-11) | **B-1** |
| Provider existing-op extensions (Part parent, marker trio, link, labels) (V2 §7) | **B-1** |
| `pack [tracker] phase split` verbs (V2 §4.2, D-11) | **B-2** |
| `pack [tracker] phase reorder` verbs (V2 §5.5, D-11) | **B-2** (skeleton) + **C-3/C-5** (write half) |
| `pack task supersede` (the only re-parent-adjacent verb, §2.A) | **B-2** |
| Parts MIGRATION: sub-issue creation + task re-parenting (V2 §6.1 Phase B, §6.2) | **B-3** |
| decompose H3 preserve inline (V2 §6.1 Phase A) | **B-3** (preserve) + **C-4** (marker write) |
| Reverse-emit Parts H3/H4 (V2 §6.4 / SCHEMA §7 specified) | **B-4** |
| METHODOLOGY § "Multi-part phases" extension (V2 §4.3, §8.2) | **B-4** |
| Flat-file Parts H3 split (V2 §4.3) | **B-2** (flat `phase split`) |
| validate-pack Part-membership check (V2 §7, architect-specified) | **B-1** or **C-6** (if warranted; else extend existing) |

### §6.5 — BD-185 File/Symbol line items → commit

| BACKLOG File/Symbol | Commit | Note |
|---|---|---|
| `project-template/.github/ISSUE_TEMPLATE/work-item.yml` | already shipped H.2 (A-1 relocates archive snapshot) | "part:M label namespace" REJECTED per V2 D-6 (Parts carry identity in pack-id) |
| `supporting-docs/METHODOLOGY.md` § "Multi-part phases" | **B-4** | |
| `scripts/lib/tracker-provider-*.sh` (bi-directional Part + order sync) | **B-1, B-3, B-4, C-1, C-2** | |
| `scripts/migrate-v10-to-v11.sh` + v11.0 flat→tracker migrator | **B-3, C-4** | migrator-core framework (BD-119); no copy-rewrite |
| `scripts/validate-pack.py` (Part + ordering invariants) | **A-2** (decontaminate/extend) + **B-1/C-6** (new check if warranted) | |
| `project-template/docs/pack/PM-CHAT.md` (PM-chat orchestration) | **B-2/B-4 IF architect-specified** | V2 does not mandate a PM-CHAT edit; coder adds only if the split verb needs orchestration text. **Reviewer confirms client-facing boundary (no pack-ops refs).** |
| `project-template/STATUS.md` (confirm role unchanged) | **C-3** (display sort only; NO ownership change — SC5) | |

**Unmapped check:** every V2 §10 group (A–H), every addendum net-new surface,
every phase-parts piece (V2 §4/§6), and every BD-185 File/Symbol item maps to a
commit. **Nothing in scope is unmapped.**


---

## §7 — Dependency ordering (at-a-glance)

```
A-1 (relocate archive) ─┬─> A-2 (de-contaminate validator/test, 6-type loop)
                        │
                        └─> [Group H PM-only: BACKLOG prose — Pack Chat, out-of-band]

A-2 ─> B-1 (phase-part lib + provider Part-parent)
        ├─> B-2 (split/reorder verbs)  ──> B-3 (migration Parts)  ──> B-4 (reverse-emit Parts + METHODOLOGY)
        └─> C-1 (abstract ops + capability block)
              └─> C-2 (selector+gate+FULL floor + STUB issue-fields)
                    ├─> C-3 (consumer routing: mirror/STATUS/reorder)
                    │     └─> C-4 (migration ordering-writes, throttled)
                    └─> C-5 (config scaffold + order-root init + doctor + chaining)
                          └─> C-6 (reverse-emit order marker + reconciliation chain)
                                 ^── coordinates with B-4 (same reverse-emit fn)
```

- **A before B before C** (user-approved sequencing): clean the contaminated
  foundation, then build Parts, then ordering.
- **C-6 + B-4 edit the same `tracker-migrate-reverse.sh` function** (Part-membership
  H3/H4 emit in B-4; ordering-marker write in C-6). Because B-4 lands before C-6
  in the A→B→C order, C-6 extends B-4's emit — no conflict; the coder reads the
  B-4 state before the C-6 edit.

---

## §8 — Open risks and unknowns

| # | Risk / unknown | Severity | Mitigation / disposition |
|---|---|---|---|
| R-1 | **Stale `v11.1/` path references reappear** after relocation (BACKLOG prose, any doc cross-ref). | MED | §4 invariant 1 (grep every diff for `v11.1`); Group H BACKLOG reconciliation by Pack Chat; A-1 IMPL-REPORT flags. |
| R-2 | **Trinity rule** — none of the in-scope files are trinity files (pack-root or project-template `CLAUDE/AGENTS/GEMINI.md`). **No trinity edit is required.** If the coder finds a phase-parts rule belongs in the project-template trinity, that is a SCOPE EXPANSION → surface to Pack Chat, do NOT auto-add (V2 does not mandate it). | LOW | Reviewer confirms no trinity file touched; if one is, the parallel edit + Check via `check_trinity_h2_parity` applies. |
| R-3 | **CI breakage from per-check test drift** — A-2 modifies `check_issue_template_forms`/`check_template_archive_v11` + `test-issue-forms.sh`; C-5 touches `_CLIENT_INSTALLED_FILES`. A stale per-check test fails on push even if `validate-pack.py` runs clean (BD-193/BD-194 incident pattern). | HIGH | PREFLIGHT per-check-test runs are MANDATORY for A-2, B-4, C-5 (and C-6 if a check lands). Run `test-issue-forms.sh` + `test-validate-pack-check-43.sh` + `test-validate-pack-checks-36-37-38.sh` BEFORE the PREFLIGHT line. |
| R-4 | **Manifest drift** — any v11-surface commit that forgets the manifest regen fails the `fixture manifest verify` CI step even when functional tests pass (the 2026-05-17 / 2026-05-19 incidents). | HIGH | Every B/C commit + A-2 regenerates `test-fixtures/manifest.txt` in-commit. A-1 (maintenance-docs only) does NOT. |
| R-5 | **Check 36 scope-keyword mismatch** — B-4 and C-5 are genuinely mixed-surface (`scripts/` + client content); a `pack-only` keyword would FAIL Check 36. | MED | B-4 + C-5 carry NO keyword (mixed). A-2, B-1, B-2, B-3, C-1..C-4 are pack-only (confirm diff = `scripts/`/manifest only). C-6 = pack-only unless an architect-check adds a project-template fixture. |
| R-6 | **RG-1 §8 residual (GraphQL preview header PARTIAL).** | LOW | Confined to the STUBBED Issue-Fields path (A-8 REST-first); the v11.0 floor depends on neither. The stub records the REST shape; the GraphQL header is a future-wiring concern (typed-TODO note). |
| R-7 | **100-children cap documented outside the REST reference (RG-2 §5).** | LOW | Root-chaining (C-5, §5.4) handles it; the coder confirms the live cap value before relying on the threshold (addendum §7.4 residual 2). |
| R-8 | **Migration regression** — the v10→v11 migrator (BD-119 framework) must NOT be copy-rewritten (CLAUDE.md rule); B-3/C-4 edit `migrate-v10-to-v11/decompose.sh` + the forward lib in place. | MED | Edits source `scripts/lib/migrator-core.sh` adapter pattern in place; no new `migrate-vN-to-vM.sh` copy. `tracker-migrate-roundtrip-test.sh` guards regression. |
| R-9 | **`provider_create` / `provider_sub_issue_create` regex change (B-1)** could break existing phase-epic/phase-task creation if the broadened regex is wrong. | MED | `tracker-provider-test.sh` + `test-tracker-phase-task.sh` exercise the existing phase-epic/task creation paths; both MUST PASS after the regex widening. |
| R-10 | **Switch-locality leak** — a consumer or validate-pack check could acquire a mechanism literal during C-3..C-6, silently creating a new ENCODING surface the GA switch must touch. | MED | §4 invariant 2 (reviewer greps every C-commit consumer + validate-pack for `issue_fields`/`reprioritize`/`issue-field` literals → MUST be zero). |
| R-11 | **PM-CHAT.md scope** — the BD-185 File/Symbol names `project-template/docs/pack/PM-CHAT.md` "architect determines." V2 does NOT mandate a PM-CHAT edit. | LOW | Coder adds PM-CHAT orchestration text ONLY if the split verb genuinely needs it; reviewer enforces the client-facing boundary (no pack-ops/PACK-AGENTS refs — rule 7 / `check_project_side_deny_list`). If unneeded, no edit (do not invent). |

### §8.1 — No `MAINTAINER CHECK NEEDED` items

All state-dependent questions were resolved by reading the working tree at HEAD
`e580dda`: the contaminated `v11.1/` tree (3 files), the v11.0 archive (6th
subdir target), the provider op surface (18 ops, no `execution_order` block), the
validate-pack functions + contamination comment line numbers, the
`_CLIENT_INSTALLED_FILES` inventory (`tracker.toml.example` at L1292), the mirror
sort (`per-entry/_lib.sh:401`), the CI per-check wiring, and the highest BD
(BD-194). Group G is APPROVED per the mission prompt. OQ-A1 is user-resolved to
the middle path (§0.3). No genuinely unanswerable (maintainer-intent / future-
decision / judgment-call) question remains for the plan.

---

## §9 — Handoff to coder (execution checklist)

1. Execute commits in order: **A-1, A-2, B-1, B-2, B-3, B-4, C-1, C-2, C-3,
   C-4, C-5, C-6** (12 commits).
2. Every coder prompt opens with the STOP-MEANS-STOP preamble and ends with the
   PREFLIGHT line before the IMPL-REPORT write.
3. Each commit: edit the §3 file set → run the named verification (validate-pack
   + per-check tests + scratch-repo integration where named) → regenerate the
   manifest if the diff touches `project-template/`/`scripts/`/`pack-ops/`/
   `supporting-docs/` → emit PREFLIGHT → write IMPL-REPORT → STOP for Pack Chat
   to run the inline reviewer + triage + (if needed) fix-coder + commit.
4. Scope keyword per §3 (pack-only for A-2/B-1/B-2/B-3/C-1..C-4; none for B-4/C-5;
   pack-only-or-none for C-6 — confirm diff first).
5. OQ-A1: full-impl the selector/gate/floor/consumers/migration/config; document-
   stub ONLY the Issue-Fields LAYER-3 call shapes (typed-TODOs with RG-1 shapes).
6. NEVER reintroduce `v11.1` for any phase-parts/ordering artifact.
7. Group H (BACKLOG prose, workflow-artifact sweep) is Pack Chat's, NOT the
   coder's — flag in the A-1 IMPL-REPORT.
8. Agents never commit; Pack Chat stages + commits with explicit user approval
   after each inline review cycle.

---

*End of PLAN-BD-185-V2.md.*
