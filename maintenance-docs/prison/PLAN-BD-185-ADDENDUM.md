# PLAN-BD-185-ADDENDUM.md — Reconciliation-triage updates to PLAN-BD-185

**Author:** pack-planner
**Date:** 2026-05-27 (US/Pacific)
**Branch:** v11-dev
**HEAD at addendum authoring:** `e128a2c` (`docs: v11 — pack memory:
ENCODING-surface enumeration rule (PM-only)`)
**Supplements (does NOT replace):** `maintenance-docs/v11-implementation/PLAN-BD-185.md`
**Pipeline position:** Original architect (D1-D14 lock 2026-05-25; D15+D16
lock 2026-05-26) → original planner (POQ-1..7 lock 2026-05-26) → H.1
coder+review (`8b4c607`+`2648bb2`) → BD-193+BD-194 closed (11 commits) →
reconciliation architect doc (`ARCHITECTURE-BD-185-RECONCILIATION.md`,
1590 lines, 2026-05-27) → user triage (10 D-N/H-N decisions + 3 prior
POQ-NEW resolutions + MF1 ENCODING rule landed) → **THIS PLANNER ADDENDUM**
→ user reviews addendum → H.2 coder spawn becomes possible.

**Authoring scope.** This addendum specifies the targeted updates to
`PLAN-BD-185.md` per ten user-locked reconciliation-triage decisions
plus the post-reconciliation architectural baseline (BD-193 + BD-194
+ 3 user-locked pack-memory rules + 2 methodology-fix rules). The
original `PLAN-BD-185.md` REMAINS the primary 16-commit plan; this
addendum prepends per-H.X update tables that the H.2+ coders read
ALONGSIDE the original plan. No re-write of `PLAN-BD-185.md` itself
is proposed; preserving the original audit trail is part of the
deliverable.

---

## §1 — Scope

### §1.1 — BD-185 addendum problem

The original `PLAN-BD-185.md` (16-commit plan) was authored 2026-05-26
against HEAD `062cb8f`. Between then and HEAD `e128a2c` (this addendum's
authoring time), the following architectural baseline shifted:

- **H.1 coder + review committed** (`8b4c607` + `2648bb2`): v11.1
  templates-archive cut landed; phase-part-v11.1/SCHEMA.md + INDEX.md
  exist; cancelled-state Part-taxonomy EXCLUSION cross-reference applied.
- **BD-193 Code Red 2 + follow-on (5 commits)**: cross-surface BD/TD/Path
  scope cleanup; F1 (INDEX segregation), F1.c (PACK-INTERNAL header),
  F2.a (phase-task-v11.0 dep grammar — BD-NNN removed), F2.b
  (phase-part-v11.1 grammar — BD-NNN excluded), F2.c (v11.0/forms/
  bd removed via D16 Class B bug-fix carve-out), F2.d (project-template
  work-item.yml — bd removed), F2.e (METHODOLOGY parser regex),
  F3 (project backlog _intro.md), F4/F5 (init-project.sh S11
  install-source).
- **BD-194 Check 24 retirement (4 commits)**: `check_help_fragment_tracker_byte_identity`
  DELETED; pack-side and project-side HELP-FRAGMENT-TRACKER.md
  DECLARED SEPARATE artifacts with SEPARATE audiences; Check 22
  per-surface fix; Check 23 fail-loud (pack-side existence); Check 41
  self-doc list (project-side existence).
- **Pack-side concepts cleanup audit (3 commits)**: `b4906d1` reduced
  pack-root work-item.yml from 4 → 1 wi-type option (`{bd}` only);
  `d424aac` documented the project-concepts-deliverable-only pack-memory
  rule; `e128a2c` documented the ENCODING-surface enumeration rule
  (MF1) — both pack-only rules.
- **Three USER-LOCKED pack-memory rules (2026-05-26)**:
  `feedback_bd_pack_only_operational_rule`,
  `feedback_pack_project_separation_of_concerns`,
  `feedback_client_facing_token_economy`.
- **One USER-LOCKED methodology rule (2026-05-27)**:
  `feedback_enumerate_encoding_surfaces_in_audits` (the MF1 fix).

The reconciliation architect doc surfaced 10 triage decisions (D1 +
D16 NEEDS-ADJUSTMENT; H.0 + H.2 + H.10 + H.11 + H.12 + H.13 + H.14 +
H.16 NEEDS-ADJUSTMENT or WRONG-AND-NEEDS-REPLACEMENT; 3 NEW POQs) +
3 prior planner POQs (POQ-NEW-1..3) + 1 reconciliation POQ-1
(landed at `b4906d1`) + 1 methodology rule MF1 (landed at `e128a2c`).
All ten plus the prior five are USER-LOCKED inputs to this addendum.

### §1.2 — BD items addressed

| BD | Status | Disposition |
|---|---|---|
| BD-185 | Open (Batch 19d) | This addendum supplements the open BD-185 16-commit plan with reconciliation-triage updates to H.0, H.2, H.10, H.11, H.12, H.13, H.14, H.16 (8 of 16 plan steps; the other 8 — H.1 committed, H.3, H.4, H.5, H.6, H.7, H.8, H.9, H.15 — are STILL-VALID per the reconciliation architect verdict and require no addendum coverage). |
| BD-193 | Resolved | Architectural-baseline input only — not re-litigated. |
| BD-194 | Resolved | Architectural-baseline input only — not re-litigated. |

### §1.3 — Planner addendum scope

This document is the planner-pass addendum: it documents the per-H.X
updates derived from the 10 user-locked decisions and surfaces any
new planner-level POQs (only those that emerge from converting the
locked decisions into commit-level mechanics; design-level POQs are
out of scope per `feedback_no_solutions_in_agent_prompts`).

The addendum does NOT:
- Re-litigate any user-locked decision (per
  `feedback_no_solutions_in_agent_prompts` + the spawn-prompt rule).
- Surface alternative designs (those are settled).
- Modify `PLAN-BD-185.md` directly (audit-history preserved).
- Spawn or simulate a coder (planner pass only).
- Run state-changing git verbs (read-only enforcement).

---

## §2 — User-locked inputs (verbatim)

### §2.1 — D-N adjustments (2 decisions; from reconciliation §3)

#### D1 (NEEDS-ADJUSTMENT applied)

Original D1 defense (architect §4.3): 5th `wi-type` option breach
defended under the BD-068 4-option soft-cap.

**Post-`b4906d1` + post-deliverable-only-rule reframing:**

> INV-7 `phase-part-skeleton` added to PROJECT-TEMPLATE form ONLY.
> Pack-root form admits only `bd` per pack-side deliverable-only rule
> (no `phase-part-skeleton`; pack doesn't have phase-parts).
> Project-template 3→4 options stays AT but not OVER the BD-068
> 4-option soft cap; no defense required at either surface.

**Consequences for the addendum:**
- H.2 reframes from "pack-root + project-template byte-identical
  edit" to "PROJECT-TEMPLATE-ONLY form extension" (see §4.2).
- The "5th option" rhetoric in `ARCHITECTURE-BD-185.md` §4.3 is now
  rhetorically moot — the breach never lands at pack-root because
  pack-root form is 1-option (`{bd}`) and is not touched in BD-185.
  The architect-doc §4.3 defense remains in git history as the
  original design rationale; the planner addendum names the moot
  status without modifying the architect doc text.
- H.10 lock-step adjustments (see §4.10): `expected_wi_type_options_per_surface`
  updates only the `project-template` entry by ONE key
  (`phase-part-skeleton`); the `pack-root` entry stays at `{"bd"}`.

#### D16 (NEEDS-ADJUSTMENT applied)

Original D16 (architect §1.4 row 16; §10.1): "Convention Y: v11.0
archive structural shape frozen at 5 subdirs; intra-file content
may evolve via backward-compatible additive extensions."

**Post-BD-193 F2.c reframing (general framing, not BD-specific):**

> Class A (additive extension): intra-file content extends backward-
> compatibly; net new content added. (Worked examples: H.13 adds
> `cancelled` state; H.14 adds INDEX footnote.)
>
> Class B (bug-fix carve-out, general): intra-file content corrects
> defects via REMOVAL when the original shipped state was wrong per a
> later-discovered rule. (Worked examples: BD-193 F2.c removed `bd`
> from v11.0 archive form; BD-193 §6.1 removed inbound mention-to-
> exclude parentheticals. Class B is GENERAL — any rule-compliance
> content removal from v11.0 archive, not just BD removal.)

**Consequences for the addendum:**
- H.13 framing references D16 Class A explicitly (cancelled-state
  addition is Class A additive extension).
- H.14 framing references D16 Class A explicitly (v11.0 INDEX
  forward-reference footnote is Class A additive extension).
- No H.X commit's behavior changes; the framing clarifies operational
  scope for future readers.

### §2.2 — H-N adjustments (8 decisions; from reconciliation §4)

Verbatim from the user-locked spawn-prompt inputs (the spawn prompt
captured the user-locked text for each H.X with sufficient specificity
that this section reproduces them without summarizing). The
`PLAN-BD-185-ADDENDUM` §4 per-step tables convert these locks into
commit-level mechanics.

#### H.0 (NEEDS-ADJUSTMENT — HEAD reference)

> Refresh HEAD reference (planner addendum HEAD applies, not original
> 062cb8f); check count phrasing "40 unique invoked checks (43
> invocations counting per-surface dual-invoked checks 16/18/19)".
> Filename-uniqueness checks STILL-VALID (tracker-phase-part.sh,
> pack-phase.sh, _order.md, _order-generate.sh all zero matches).

H.0's text refresh applies WHEN H.0 fires (HEAD at that time). For
the addendum's authoring HEAD `e128a2c`, the counts are: 40 unique
invoked checks, 43 invocations. When H.0 actually fires (coder spawn
for H.2), HEAD may have advanced; coder reads the addendum and
applies the count at-that-HEAD.

#### H.2 (WRONG-AND-NEEDS-REPLACEMENT applied)

PROJECT-TEMPLATE-ONLY form extension; pack-root form NOT touched
(stays at `{bd}` per b4906d1). See §4.2 per-step table for full
mechanics.

#### H.10 (NEEDS-ADJUSTMENT — 5-update)

1. (a) REMOVE per-surface dict extension from H.10 scope (moved to
   H.2 lock-step per ENCODING rule); H.10 plan-text should note:
   "Per-surface dict update for `phase-part-skeleton` handled by H.2
   lock-step (per ENCODING-surface enumeration rule)."
2. (b) Check count framing: pre-H.10 baseline = 40 unique invoked
   checks; post-H.10 = 44 unique invoked checks (40 + 4 new). Replace
   "47 checks total" / "current 43 + 4 new" with "44 unique invoked
   checks (current 40 + 4 new)".
3. (c) Verification command expected output adjusted to 44
   invocations pre-dual-invocation (planner addendum specifies whether
   the 4 new checks are per-surface or single-invocation; if single,
   post-H.10 invocation count = 43 + 4 = 47; if any are dual, count
   is higher).
4. (d) NEW: each new check evaluated for lock-step test file
   dependencies per ENCODING rule. All 4 new checks
   (`check_phase_part_schema_v11_1`, `check_execution_order_marker`,
   `check_part_re_parentage_invariants`, `check_part_has_member_task`)
   are constructor-context (validate project-side surfaces); each
   gets a parallel test file in `scripts/tests/`.
5. (e) H.10 plan-text should reference the new ENCODING-surface
   enumeration rule when documenting per-check test additions.

#### H.11 (NEEDS-ADJUSTMENT — token-economy)

> Per `feedback_client_facing_token_economy`: METHODOLOGY edits must
> reference client-readable surfaces only. NO BD-NNN cites; NO
> architect-doc cites; NO pack-history. Acceptable reference targets:
> `pack phase split` / `pack phase reorder` / `pack task supersede`
> verbs (documented in client-installed HELP-FRAGMENT-TRACKER.md);
> per-entry tree `_rules.md` + `_intro.md` (client-installed).

Substance of H.11 §3 + §4 unchanged.

#### H.12 (WRONG-AND-NEEDS-REPLACEMENT applied)

Per-surface same-content edits; no byte-identity asserted. See §4.12
per-step table for full mechanics.

#### H.13 (NEEDS-ADJUSTMENT — 2 items)

(a) Token-economy compliance for PM-CHAT.md edits (same directive as
H.11).

(b) Reviewer-focus item:
> Verify the BD-193 F2.a dep-grammar edit at L79, L91 is NOT
> regressed — `phase-task-v11.0/SCHEMA.md` must continue to omit
> `BD-NNN` from dep-grammar; H.13 only adds `cancelled` to state
> enumeration and `execution-note-status` marker.

Substance of H.13 SCHEMA extension unchanged.

#### H.14 (NEEDS-ADJUSTMENT — diff target)

Update verification command:

```bash
diff maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml \
     project-template/.github/ISSUE_TEMPLATE/work-item.yml
# Expected: empty (archive snapshots project-template per POQ-NEW-1
# Option c; matches v11.0 archive precedent)
```

The v11.0/INDEX.md forward-reference footnote (D16 Class A) is
unchanged.

#### H.16 (NEEDS-ADJUSTMENT — reviewer scope expansion)

Add 4 reviewer-focus dimensions specific to BD-185:

1. Token-economy compliance (no BD/architect-doc/pack-history refs in
   client-installed surfaces).
2. Pack/project separation discipline (per-surface judgments; no
   cross-surface byte-identity asserted).
3. BD-NNN operational-rule preservation (H.13 SCHEMA edit doesn't
   regress F2.a; dep grammars don't re-acquire BD-NNN).
4. ENCODING-surface enumeration completeness (per
   `feedback_enumerate_encoding_surfaces_in_audits`): for each H.X
   surface modification, verify all encoding surfaces updated in
   lock-step — H.2 form changes → validator dict + tests; H.10 new
   checks → per-check test files + CI wiring; H.12 HELP-FRAGMENT
   edits → Check 22/23/41 still hold; H.13 SCHEMA edit → Check 22
   surface-local invariants still hold.

Close-commit summary may optionally mention BD-193/194 architectural
baseline integration.

### §2.3 — Prior user-locked decisions (re-affirmed for context)

| Anchor | Decision | Date | Source |
|---|---|---|---|
| POQ-NEW-1 | v11.1 archive snapshots PROJECT-TEMPLATE only (Option c per reconciliation §5.1) | 2026-05-27 user triage | spawn-prompt input |
| POQ-NEW-2 | Drop diff assertion for HELP-FRAGMENT-* pairs (no byte-identity required) | 2026-05-27 user triage | spawn-prompt input |
| POQ-NEW-3 | Check 22/23/41 informational note in H.10 + H.12 reviewer-focus | 2026-05-27 user triage | spawn-prompt input |
| POQ-RECONCILIATION-1 | Pack-root form cleanup (landed at `b4906d1`) | 2026-05-27 | committed |
| MF1 | ENCODING-surface enumeration rule (landed at `e128a2c`) | 2026-05-27 | committed |


---

## §3 — Pre-implementation investigation

### §3.1 — File-path verification (HEAD `e128a2c`)

| Path | Exists at HEAD? | Relevance | Verification |
|---|---|---|---|
| `.github/ISSUE_TEMPLATE/work-item.yml` | YES | Pack-root form (1 wi-type option `{bd}` post-b4906d1) | H.2 NOT touched by this addendum |
| `project-template/.github/ISSUE_TEMPLATE/work-item.yml` | YES | Project-template form (3 wi-type options `{td, phase-epic-skeleton, phase-task-skeleton}` post-F2.d) | H.2 extends to 4 options |
| `maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md` | YES | Frozen v11.0 INDEX; carries F2.c carve-out note at L31 | H.14 adds Class A forward-reference footnote |
| `maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md` | YES | Frozen v11.0 schema; F2.a removed BD-NNN from dep grammar at L79/L91 | H.13 adds D5 `cancelled` state (Class A) |
| `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md` | YES | v11.1 INDEX (committed at H.1) | H.14 finalizes cross-references; "Forms file" L53 currently "Not yet created" — H.2 creates the archive snapshot |
| `maintenance-docs/v11-research/templates-archive/v11.1/phase-part-v11.1/SCHEMA.md` | YES | v11.1 schema (committed at H.1) | No further edits in addendum scope |
| `maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml` | NO (per ls verification) | Per POQ-NEW-1 Option c: byte-identical archive snapshot to project-template post-H.2 | H.2 creates it |
| `scripts/validate-pack.py` | YES | Per-surface dict at L1117 `expected_wi_type_options_per_surface = {"pack-root": {"bd"}, "project-template": {"td", "phase-epic-skeleton", "phase-task-skeleton"}}` | H.2 ENCODING lock-step: extends project-template entry by one key |
| `scripts/tests/test-issue-forms.sh` | YES (269 lines) | Surface-aware test post-b4906d1 F3 cleanup | H.2 ENCODING lock-step: extends expected wi-type set + adds `phase-part-skeleton` presence assertion + `wi-part-letter` field assertion (project-template surface only) |
| `scripts/tests/test-validate-pack-check-43.sh` | YES | Check 43 leak-sweep prevention test | Run as part of H.2 PREFLIGHT (project-template surface touched) |
| `scripts/tests/test-validate-pack-checks-36-37-38.sh` | YES | Check 36/37/38 surface-scope tests | Run as part of every commit's PREFLIGHT |
| `scripts/tests/test-validate-pack-checks-32-33-34.sh` | YES | Check 32/33/34 surface tests | Run as part of every commit's PREFLIGHT |
| `pack-ops/HELP-FRAGMENT-PACK.md` | YES | Pack-side help fragment | H.12 same-content edit (pack-side audience) |
| `pack-ops/HELP-FRAGMENT-TRACKER.md` | YES (49 lines; coincidentally byte-identical to project-side TODAY per BD-194) | Pack-side tracker help fragment | H.12 same-content edit (pack-side audience) |
| `project-template/docs/pack/HELP-FRAGMENT.md` | YES | Project-side help fragment | H.12 same-content edit (project audience) |
| `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` | YES (49 lines) | Project-side tracker help fragment | H.12 same-content edit (project audience) |
| `project-template/docs/pack/PM-CHAT.md` | YES | Client-installed PM-Chat workflow doc | H.13 token-economy-compliant edit |
| `supporting-docs/METHODOLOGY.md` | YES | Client-installed methodology doc | H.11 token-economy-compliant edit |
| `supporting-docs/MIGRATION-v10-to-v11.md` | YES | Client-readable migration doc | H.12 token-economy-compliant edit |
| `.github/workflows/validate-pack.yml` | YES | CI workflow | H.10 adds 4 per-check test invocations |

### §3.2 — Filename-uniqueness re-verification (per addendum HEAD)

Per the H.0 success-criterion baseline (filename uniqueness checks
for proposed new files):

| Filename | `find` count at HEAD `e128a2c` | Status |
|---|---|---|
| `tracker-phase-part.sh` | 0 | STILL-VALID (H.5 creates) |
| `pack-phase.sh` | 0 | STILL-VALID (H.9 creates) |
| `_order.md` | 0 | STILL-VALID (H.7 creates as per-entry view) |
| `_order-generate.sh` | 0 | STILL-VALID (H.7 creates per POQ-5) |

### §3.3 — Check count at addendum HEAD

```bash
$ python3 scripts/validate-pack.py 2>&1 | grep -c "^── Check"
43
```

Resolved per the 10-decision spawn-prompt input:
- 38 numbered unique checks (1-11, 16-23, 25-43; Checks 12-15 retired
  in v9-migrator removal; Check 24 retired in BD-194)
- + 2 unnumbered checks (`Issue template forms`, `Template archive
  v11.0 integrity`)
- = **40 unique invoked checks**
- + 3 dual-invocation overhead (Checks 16, 18, 19 per pack-root +
  project-template surfaces)
- = **43 invocations**

Post-H.10 (4 new checks; all constructor-context single-invocation):
- 44 unique invoked checks
- 47 invocations

This count baseline is what H.0 verifies and what H.10 success
criteria + verification commands assert.

### §3.4 — Validate-pack baseline at addendum HEAD

```bash
$ python3 scripts/validate-pack.py 2>&1 | tail -5
# Returns: FAILED — 1 issue(s) found
# Failing check: Check 36 — Commit e128a2c subject claims `PM-only`
# but touches non-PM-only paths: .claude/skills/review/SKILL.md,
# .codex/skills/review/SKILL.md, .gemini/skills/review/SKILL.md
```

**Analysis.** Check 36 failure on commit `e128a2c` is a pre-existing
state at the addendum's authoring HEAD. The failing commit is the
`docs: v11 — pack memory: ENCODING-surface enumeration rule (PM-only)`
commit which mixed PM-only trinity edits with `.claude/.codex/.gemini/skills/review/SKILL.md`
edits (review-skill operational mirrors).

**Planner-level POQ surfaced — see §5 POQ-A1.**

**POST-AUTHORING RESOLUTION (2026-05-27).** Per POQ-A1 user resolution
(see §5.1), commit `e128a2c` was force-pushed out of `v11-dev`
history. The trinity Pack memory rule re-landed at `f19b585` (PM-only
correct; trinity-only diff). The companion review-skill operational
checklist landed at `42ce52d` (pack-only correct; review-skill mirrors
applied per `feedback_pack_chat_does_no_fixes` discipline via
fix-coder rather than Pack Chat direct edit). validate-pack PASSES
at the current branch tip; the Check 36 failure described above no
longer exists on remote `v11-dev`. Recovery tag
`pre-rewrite-e128a2c-recovery` exists locally as a rollback safety
point.

### §3.5 — Cross-reference health of H.X surfaces (addendum-driven)

For each H.X step receiving addendum edits, the cross-references in
the addendum's per-step tables (§4) name:
- The original PLAN-BD-185 §5 H.X section being supplemented
- The reconciliation architect §4.X verdict
- The user-locked spawn-prompt text quoted in §2 above
- Pack-memory rule anchors that gate the edit

No addendum content invents file paths or interfaces beyond what the
reconciliation architect doc + the user-locked spawn prompt already
authorize.

---

## §4 — H.X per-step addendum tables

Each subsection below SUPPLEMENTS the matching `PLAN-BD-185.md` §5
section. Coder reads the original PLAN-BD-185 §5 H.X content FIRST,
then applies the supplemental table below.

### §4.0 — H.0 — Baseline verification (supplement)

**Original plan reference:** `PLAN-BD-185.md` §5 H.0

**Supplement applies WHEN H.0 fires.** H.0 is a pre-flight checklist
the coder runs at H.2 spawn time (NOT at addendum-authoring time);
the HEAD reference and counts may have advanced.

**Coder PREFLIGHT step adjustments (at H.0 fire-time):**

1. `git rev-parse HEAD` — record actual HEAD at coder spawn time
   (NOT the addendum-authoring HEAD `e128a2c`; HEAD may advance if
   the user lands additional commits between addendum landing and
   H.2 coder spawn).
2. `git status` — working tree clean except plan addendum (this file)
   and any pending coder deliverables.
3. `python3 scripts/validate-pack.py` — record PASS status. If FAIL,
   surface to Pack Chat triage (e.g., the Check 36 issue on
   `e128a2c` per §3.4 should be resolved before H.2 fires;
   investigation via §5 POQ-A1).
4. BD-185 status: `grep -A2 "BD-185" pack-ops/BACKLOG.md | head -5`
   confirms `Status: Open`.
5. Filename-uniqueness re-verification per §3.2:
   - `find . -name "tracker-phase-part.sh" -not -path "./.git/*"` →
     0 matches
   - `find . -name "pack-phase.sh" -not -path "./.git/*"` → 0 matches
   - `find . -name "_order.md" -not -path "./.git/*"` → 0 matches
   - `find . -name "_order-generate.sh" -not -path "./.git/*"` →
     0 matches
6. Check-count baseline: `python3 scripts/validate-pack.py 2>&1 |
   grep -c "^── Check "` — expected **43** invocations (40 unique +
   3 dual-invocation overhead) at addendum HEAD. If fewer/more,
   investigate before H.2 fires.

**Files modified (post-update):** none (H.0 is read-only verification).

**Edit specification (post-update):** none.

**Verification commands (post-update):** as above (steps 1-6).

**RC9 manifest regen (post-update):** n/a (no commit).

**Per-commit reviewer scope (post-update):** n/a (no commit).

**Commit subject scope-keyword (post-update):** n/a (no commit).

**Commit message draft (post-update):** n/a.

### §4.2 — H.2 — Form-family extension (REPLACEMENT)

**Original plan reference:** `PLAN-BD-185.md` §5 H.2 ("Form-family
extension: pack-root + client-template work-item.yml; 5th wi-type
option `phase-part-skeleton` + `wi-part-letter` input; v11.1 archive
forms/work-item.yml CREATE byte-identical").

**Reconciliation verdict:** WRONG-AND-NEEDS-REPLACEMENT (architect
§4.2). User-locked replacement: PROJECT-TEMPLATE-ONLY form extension
+ archive snapshots project-template (Option c per POQ-NEW-1).

**Files modified (post-update):** 5 files

1. `project-template/.github/ISSUE_TEMPLATE/work-item.yml` (EXTEND):
   - `wi-type` options: 3 → 4 (add `phase-part-skeleton`; under BD-068
     soft cap; no defense required)
   - Add `wi-part-letter` input (conditional on
     `wi-type=phase-part-skeleton`)
   - `wi-blockers` / `wi-unblocks` / `wi-dependencies` descriptions:
     admit `Phase-N.Part-x` + `Phase-N.Part-x.Task-M` forms (NOT
     `BD-NNN` — must not regress BD-193 F2.d)
   - `wi-type` description: extend to mention `phase-part-skeleton`
2. `maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml`
   (NEW; byte-identical to project-template post-H.2 edits; per
   POQ-NEW-1 Option c)
3. `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md`
   (UPDATE "Forms file" section L53-77: replace "Not yet created"
   with description of post-H.2 archive snapshot referencing
   project-template surface; matches v11.0 archive precedent)
4. `scripts/validate-pack.py` (LOCK-STEP per ENCODING rule):
   - Update `expected_wi_type_options_per_surface["project-template"]`
     from 3-element set to 4-element set
   - Pack-root entry UNCHANGED at `{"bd"}`
5. `scripts/tests/test-issue-forms.sh` (LOCK-STEP per ENCODING rule):
   - Update surface-aware expected set for project-template
   - Add `phase-part-skeleton` presence assertion for project-template
   - Add `wi-part-letter` field presence assertion for project-template
   - DISJOINT invariant still passes (pack-root `{bd}` ∩
     project-template `{td, phase-epic-skeleton, phase-task-skeleton,
     phase-part-skeleton}` = ∅)

**NOT modified:** `.github/ISSUE_TEMPLATE/work-item.yml` (pack-root
form; stays at `{bd}` per b4906d1).

**Edit specification (post-update):**

Per the user-locked text and the ENCODING-surface enumeration rule
(`feedback_enumerate_encoding_surfaces_in_audits` at HEAD `e128a2c`),
H.2 modifies five surfaces in lock-step. The form-file change (item
#1) is the AUDITED surface; the validator (#4) + test (#5) are ENCODING
surfaces; the archive snapshot (#2) + INDEX (#3) are CROSS-REFERENCE
surfaces. Asymmetric coverage (e.g., editing the form file without
the validator + test) would surface as a CI failure (per the
methodology gap MF1 worked example).

Sub-edits per file:

(1) `project-template/.github/ISSUE_TEMPLATE/work-item.yml`
   - At `id: wi-type` `options:` list (currently 3 options): append
     `- phase-part-skeleton`. Result: 4 options.
   - At `id: wi-type` `description:` field: extend prose to mention
     "phase-part-skeleton (rare-case fallback for hand-edited Part
     skeletons)".
   - Insert NEW `wi-part-letter` input field after the existing
     `wi-task-title` field (which is the established conditional
     pattern for phase-task-skeleton):
     ```yaml
     - type: input
       id: wi-part-letter
       attributes:
         label: Part letter (phase-part-skeleton only)
         description: Required for Type=phase-part-skeleton. The next available letter under phase N (a, b, c, ...).
       validations:
         required: false
     ```
   - At `id: wi-blockers` `description:` field: extend prose to admit
     `Phase-N.Part-x` and `Phase-N.Part-x.Task-M` forms (in addition
     to existing `phase-N`, `phase-N.M`, `TD-NNN`).
   - At `id: wi-unblocks` `description:` field: same extension.
   - At `id: wi-dependencies` `description:` field: same extension.

(2) `maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml`
    (NEW file)
   - Copy entire content of `project-template/.github/ISSUE_TEMPLATE/work-item.yml`
     post-(1) edits. Byte-identical at creation.

(3) `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md`
    (EXTEND existing "Forms file" section)
   - Replace L53-77 ("Not yet created. The v11.1 forms/ subdirectory…")
     with descriptive prose for the post-H.2 archive snapshot. Cite
     project-template surface as snapshot target (POQ-NEW-1 Option c).
     Cite v11.0 archive precedent (the v11.0 form is project-template-shaped
     after F2.c bug-fix carve-out). Cite the 4 wi-type options + the
     new `wi-part-letter` field + the description extensions.

(4) `scripts/validate-pack.py`
   - At L1117-1120 (`expected_wi_type_options_per_surface = {…}`):
     update the `"project-template"` value from
     `{"td", "phase-epic-skeleton", "phase-task-skeleton"}` to
     `{"td", "phase-epic-skeleton", "phase-task-skeleton", "phase-part-skeleton"}`.
   - The `"pack-root"` value stays `{"bd"}`.
   - Update the surrounding docstring to reflect the deliverable-only
     rule + the new option.

(5) `scripts/tests/test-issue-forms.sh`
   - Group 2 (work-item.yml structure): update the per-surface
     expected wi-type options:
     - pack-root: still `"bd"` (unchanged)
     - project-template: from `"td phase-epic-skeleton phase-task-skeleton"`
       to `"td phase-epic-skeleton phase-task-skeleton phase-part-skeleton"`
   - Group 2: add a NEW assertion under the `if [[ "$surface_kind"
     == "project" ]]` branch: presence of `id: wi-part-letter` field.
   - Group 5 (or appropriate group per current test structure): add
     a `phase-part-skeleton`-conditional rendering assertion for the
     project-template surface.
   - DISJOINT invariant unchanged (pack-root `{bd}` vs project-template
     4 options remain disjoint).

**Verification commands (post-update):**

```bash
# 1. Validator passes against the new dict (ENCODING surface 1):
python3 scripts/validate-pack.py
# Expected: PASS

# 2. Test passes against the new assertions (ENCODING surface 2):
bash scripts/tests/test-issue-forms.sh
# Expected: 0 exit; all groups PASS

# 3. Project-template form has 4 wi-type options:
grep -A6 "id: wi-type" project-template/.github/ISSUE_TEMPLATE/work-item.yml | grep -c "^[[:space:]]*-"
# Expected: 4

# 4. Project-template still does NOT admit `bd`:
grep "^[[:space:]]*-[[:space:]]*bd$" project-template/.github/ISSUE_TEMPLATE/work-item.yml
# Expected: NO match

# 5. Pack-root form UNCHANGED at 1 wi-type option (`{bd}`):
grep -A4 "id: wi-type" .github/ISSUE_TEMPLATE/work-item.yml | grep -c "^[[:space:]]*-"
# Expected: 1

# 6. Project-template has `wi-part-letter` field:
grep -nE "^[[:space:]]+id: wi-part-letter" project-template/.github/ISSUE_TEMPLATE/work-item.yml
# Expected: ONE match

# 7. Pack-root does NOT have `wi-part-letter` field:
grep -nE "^[[:space:]]+id: wi-part-letter" .github/ISSUE_TEMPLATE/work-item.yml
# Expected: NO match

# 8. Archive snapshot byte-identical to project-template (Option c):
diff maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml \
     project-template/.github/ISSUE_TEMPLATE/work-item.yml
# Expected: empty

# 9. Archive snapshot NOT byte-identical to pack-root (per intentional divergence):
diff maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml \
     .github/ISSUE_TEMPLATE/work-item.yml | head -5
# Expected: non-empty (option set + description divergence)

# 10. Per-check tests pass (every change touching project-template/ runs Check 43 + others):
bash scripts/tests/test-validate-pack-check-43.sh
bash scripts/tests/test-validate-pack-checks-36-37-38.sh
bash scripts/tests/test-validate-pack-checks-32-33-34.sh
# Expected: each exits 0

# 11. RC9 manifest regen:
bash test-fixtures/build.sh --all --clean
git diff --stat test-fixtures/manifest.txt
# Expected: non-empty diff; coder stages manifest.txt alongside scope edits
```

**RC9 manifest regen (post-update):** REQUIRED. `project-template/`
in v11-surface per BD-176. Stage `test-fixtures/manifest.txt`
alongside scope edits.

**Per-commit reviewer scope (post-update):** **INLINE — sliding-window
covers H.2 alone (since H.3 + H.4 inline reviews fire later under
their own H.X scopes per original plan §3 (α-sliding) mapping; the
PROJECT-TEMPLATE-ONLY refocus does not change the sliding window's
H.2-H.3-H.4 cumulative coverage at H.4).** Boundary-sensitive review
focus:
- PROJECT-TEMPLATE-ONLY (no pack-root edit; verify pack-root form is
  byte-equivalent pre-H.2 vs post-H.2).
- 4-option count (project-template) under BD-068 soft cap; no defense
  required.
- `wi-part-letter` field correctness (conditional on
  `phase-part-skeleton`; letter-only grammar per C-1).
- Blockers / Unblocks / Dependencies description extensions admit
  Part-id forms (`Phase-N.Part-x` + `Phase-N.Part-x.Task-M`); MUST
  NOT re-introduce `BD-NNN` (BD-193 F2.d regression prevention).
- DISJOINT invariant holds at the validator + test surfaces.
- Archive snapshot byte-identical to project-template; v11.0 archive
  precedent followed (POQ-NEW-1 Option c).
- ENCODING-surface lock-step completeness: form + validator + test +
  archive + INDEX all updated; no asymmetric coverage.
- Check 22 / Check 23 / Check 41 informational note (POQ-NEW-3): these
  checks enforce surface-local invariants for HELP-FRAGMENT-TRACKER
  but do NOT touch work-item.yml form-family; H.2's ENCODING-surface
  lock-step at the form / validator / test surfaces is the relevant
  enforcement here.

**Commit subject scope-keyword (post-update):** `project-only` (the
H.2 edit set lands entirely under `project-template/`,
`maintenance-docs/`, `scripts/`, `scripts/tests/`, and `test-fixtures/`).
Per CI Check 36 rule:
- `project-only` permits everything OUTSIDE pack-only paths.
- Pack-only deny-list = ANYTHING outside `project-template/` +
  `supporting-docs/`.
- H.2 edits hit `project-template/.github/…`, `maintenance-docs/…`,
  `scripts/validate-pack.py`, `scripts/tests/test-issue-forms.sh`,
  `test-fixtures/manifest.txt`.
- The `scripts/` + `maintenance-docs/` + `test-fixtures/` edits are
  pack-only paths; `project-template/` is project-only territory.
- This is a MIXED-SCOPE commit (project-template + pack-only paths).
- **Per `CLAUDE.md` rule "If a batch's work genuinely spans pack +
  project, the commit subject MUST NOT carry an exclusive scope
  keyword":** Use NO KEYWORD.

**Commit message draft (post-update):**

```
feat: v11 — BD-185 work-item.yml form-family extension (project-template 4th wi-type + part-letter input + archive snapshot) (Batch 19d.2)
```

**Pack-coder PREFLIGHT line shape (post-update):**

```
PREFLIGHT: 5/5 in-scope file edits complete; verification PASS;
HEAD <SHA>; about to Write IMPL-REPORT to
maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.2.md
```

**Ordering dependency:** MUST land AFTER H.1 (committed at `8b4c607`+`2648bb2`).
No direct dependency on H.3.

**Success criteria (post-update):**
1. `project-template/.github/ISSUE_TEMPLATE/work-item.yml` carries
   the 4th wi-type option `phase-part-skeleton`.
2. `wi-part-letter` input field exists in project-template; conditional
   rendering for `phase-part-skeleton` only.
3. Blockers/Unblocks/Dependencies descriptions admit Part-id forms;
   NO `BD-NNN` re-introduced.
4. `maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml`
   exists; byte-identical to project-template-side (POQ-NEW-1 Option c).
5. `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md`
   "Forms file" section reflects the post-H.2 snapshot.
6. `scripts/validate-pack.py` `expected_wi_type_options_per_surface`
   dict updated: project-template entry has 4 elements; pack-root
   entry unchanged at `{"bd"}`.
7. `scripts/tests/test-issue-forms.sh` surface-aware assertions
   updated; new `phase-part-skeleton` + `wi-part-letter` assertions
   for project-template; DISJOINT invariant holds.
8. `python3 scripts/validate-pack.py` exits 0; check count
   UNCHANGED at 43 invocations (H.10 introduces the 4 new checks).
9. `bash scripts/tests/test-issue-forms.sh` exits 0.
10. `bash scripts/tests/test-validate-pack-check-43.sh` exits 0.
11. `bash scripts/tests/test-validate-pack-checks-36-37-38.sh` exits 0.
12. `bash scripts/tests/test-validate-pack-checks-32-33-34.sh` exits 0.
13. `test-fixtures/manifest.txt` regenerated and staged.
14. Pack-root form is byte-equivalent pre-H.2 vs post-H.2 (no edit).


### §4.10 — H.10 — validate-pack.py extensions + 4 NEW checks (5-update)

**Original plan reference:** `PLAN-BD-185.md` §5 H.10 ("validate-pack.py
extensions (Check 32/33/34/35) + 4 NEW checks").

**Reconciliation verdict:** NEEDS-ADJUSTMENT (architect §4.10).
User-locked 5-update applied.

**Files modified (post-update):** ~5 EXTEND/CREATE

1. `scripts/validate-pack.py` (EXTEND Check 32/33/34/35 + ADD 4 new
   check functions; per-surface dict update DROPPED from H.10 scope
   per (a) — moved to H.2 ENCODING lock-step)
2. `scripts/tests/test-validate-pack-check-NN.sh` (NEW; phase-part
   schema; NN = next gap-allocated number per §5 POQ-A2)
3. `scripts/tests/test-validate-pack-check-NN+1.sh` (NEW; exec-order
   marker)
4. `scripts/tests/test-validate-pack-check-NN+2.sh` (NEW; Part
   re-parentage)
5. `scripts/tests/test-validate-pack-check-NN+3.sh` (NEW; Part has
   member task)
6. `.github/workflows/validate-pack.yml` (4 NEW per-check test
   invocation lines)

**Edit specification (post-update):**

Per the user-locked 5-update:

(a) **Per-surface dict update DROPPED from H.10 scope.** The
`expected_wi_type_options_per_surface` dict update for
`phase-part-skeleton` is handled by H.2 lock-step (per ENCODING-surface
enumeration rule). H.10 plan-text MUST NOT include the per-surface
dict edit; the responsibility moved to H.2.

Plan-text note for the coder: "Per-surface dict update for
`phase-part-skeleton` handled by H.2 lock-step (per ENCODING-surface
enumeration rule). H.10 only extends Check 32/33/34/35 + adds 4 new
checks; no `check_issue_template_forms` edit at H.10."

(b) **Check count framing updated.** Replace "47 checks total" /
"current 43 + 4 new" with "**44 unique invoked checks (current 40
+ 4 new)**". Original plan §5 H.10 success-criterion #5 + §7 final
verification + §6.3 cross-cutting all carry the stale count.

(c) **Verification command expected output adjusted.** All 4 new
checks are constructor-context (validate project-side surfaces);
they are SINGLE-INVOCATION (NOT dual-invoked per surface). Therefore:
- Pre-H.10 invocation count: 43
- Post-H.10 invocation count: 47 (43 + 4 single-invocation = 47)
- Pre-H.10 unique count: 40
- Post-H.10 unique count: 44 (40 + 4 = 44)

Verification command:
```bash
python3 scripts/validate-pack.py 2>&1 | grep -c "^── Check "
# Expected: 47 (43 baseline + 4 new single-invocation checks)
```

(d) **NEW per-check test file dependencies per ENCODING rule.** Each
of the 4 new checks gets a parallel test file under `scripts/tests/`.
All 4 follow the per-check test pattern established by
`test-validate-pack-check-40.sh` / `test-validate-pack-check-41.sh` /
`test-validate-pack-check-42.sh` / `test-validate-pack-check-43.sh`
(synthetic fixture approach, no real-file mutation).

(e) **ENCODING-surface enumeration rule reference.** H.10 plan-text
should reference `feedback_enumerate_encoding_surfaces_in_audits`
when documenting per-check test additions. For each new check:
- The check function in `scripts/validate-pack.py` is the AUDITED
  surface (the validator extension).
- The per-check test file is the ENCODING-paired surface.
- The CI workflow wiring (`.github/workflows/validate-pack.yml`) is
  the ENCODING-paired CI surface.

Per-check sub-edits (mechanical detail; coder applies):

**Check 32 (`check_mirror_in_sync`) EXTEND:** Per original plan §5
H.10 #1. Stream regex unchanged; mirror sort order changes per §5.3
(execution-order tuple). Test fixtures updated in H.15.

**Check 33 (`check_toc_in_sync`) EXTEND:** Per original plan §5 H.10 #2.
Group regex unchanged. `_toc.md` display unchanged (planner default
per D7 — `_order.md` is the SSOT-derived view; `_toc.md` content
unchanged).

**Check 34 (`check_cross_reference_integrity`) EXTEND:** Per original
plan §5 H.10 #3. Extend `CROSS_REF_RE` to admit:
- `Phase-N` (capitalized v2)
- `Phase-N.Part-x` (Part identifier)
- `Phase-N.Part-x.Task-M` (Part-scoped task; Task-M integer-only per D15)
- `Phase-N.Task-M` (null-Part task v2; Task-M integer-only per D15)
- Legacy `phase-N.M` continues to resolve.

**Check 35 (`check_tracker_phase_task_invariants`) EXTEND:** Per
original plan §5 H.10 #4. Verify `tracker-phase-part.sh` exists
(parallel to phase-task lib invariant); admit `cancelled` state per
D5 (post-H.13 SCHEMA extension).

**`check_template_archive_v11` EXTEND:** Per original plan §5 H.10 #6.
v11.0 archive structural shape frozen at 5 entry-types; intra-file
extensions allowed per D16 Convention Y Class A (H.13 cancelled-state)
AND Class B (BD-193 F2.c carve-out precedent, per §2.1 D16
reframing). Planner default per original plan: parameterize by version;
verify v11.N matches its INDEX.md declaration.

**`check_issue_template_forms`:** NO EDIT at H.10 per (a). The
per-surface dict update was already handled by H.2 ENCODING lock-step.

**NEW Check NN (`check_phase_part_schema_v11_1`):** Per original
plan §5 H.10 #7.
- Verify `templates-archive/v11.1/phase-part-v11.1/SCHEMA.md` exists
- Verify SCHEMA declares identifier scheme `Phase-N.Part-x`; body
  marker trio with `template_version: phase-part-v11.1`; label
  family (status:* only); state taxonomy `pending / in-progress /
  done / deferred`
- Pattern parallels Check 35

**NEW Check NN+1 (`check_execution_order_marker`):** Per original
plan §5 H.10 #8.
- Verify every `phase-N.md` in `docs/project/implementation-plan/`
  carries `<!-- execution-order: NNN -->` marker
- Optional / gated by tracker.toml (project not yet at v11.1 has no
  markers; not required)
- CI failure names missing-marker files

**NEW Check NN+2 (`check_part_re_parentage_invariants`):** Per
original plan §5 H.10 #9.
- For every phase epic with Part sub-issues, verify all phase tasks
  are sub-issue children of a Part (not direct children of phase
  epic)
- Tracker-side check only (no flat-file analog)

**NEW Check NN+3 (`check_part_has_member_task`):** Per original plan
§5 H.10 #10.
- Verify every Part entity has ≥1 task as sub-issue child OR
  `status:deferred` (per D3 §4.7)
- Tracker-side check only

**Per-check test files (NEW):** Follow structural pattern of
`test-validate-pack-check-43.sh` (synthetic fixture approach). One
file per new check.

**`.github/workflows/validate-pack.yml`:** Add 4 new
`bash scripts/tests/test-validate-pack-check-<N>.sh` invocation lines
per Check 42 contract.

**Verification commands (post-update):**

```bash
# 1. Validator passes with 4 new checks active:
python3 scripts/validate-pack.py
# Expected: PASS

# 2. Check count is now 47 invocations / 44 unique:
python3 scripts/validate-pack.py 2>&1 | grep -c "^── Check "
# Expected: 47

# 3. Each new per-check test exits 0:
bash scripts/tests/test-validate-pack-check-NN.sh
bash scripts/tests/test-validate-pack-check-NN+1.sh
bash scripts/tests/test-validate-pack-check-NN+2.sh
bash scripts/tests/test-validate-pack-check-NN+3.sh
# Expected: each exits 0

# 4. Check 42 (workflow wiring) PASSES with the 4 new test files:
bash scripts/tests/test-validate-pack-check-42.sh
# Expected: exit 0; 14 per-check test file(s) on disk; 14 workflow
# invocation(s) found; zero unwired tests.

# 5. ENCODING-surface lock-step verification (per MF1 rule):
# For each new check (the AUDITED validator extension):
#   - Per-check test exists at scripts/tests/test-validate-pack-check-NN.sh
#   - Workflow invocation exists at .github/workflows/validate-pack.yml
ls scripts/tests/test-validate-pack-check-NN.sh \
   scripts/tests/test-validate-pack-check-NN+1.sh \
   scripts/tests/test-validate-pack-check-NN+2.sh \
   scripts/tests/test-validate-pack-check-NN+3.sh
grep -c "test-validate-pack-check-NN" .github/workflows/validate-pack.yml
# Expected: 1 (per new check; 4 total grep matches across the 4 names)

# 6. RC9 manifest regen:
bash test-fixtures/build.sh --all --clean
git diff --stat test-fixtures/manifest.txt
# Expected: non-empty (scripts/ + .github/ touched)
```

**RC9 manifest regen (post-update):** REQUIRED. `scripts/` in
v11-surface per BD-176. `.github/workflows/` is NOT in RC9 trigger
set alone, but the `scripts/` change forces regen.

**Per-commit reviewer scope (post-update):** **SKIP (covered by H.11
sliding window: H.10+H.11)** per original plan §3 (α-sliding)
mapping. Boundary-sensitive review focus deferred to H.11 reviewer:
- Each extended check's docstring updated per change.
- 4 new check functions reachable + each has corresponding per-check
  test file.
- Workflow wiring complete; Check 42 PASSES.
- `expected_wi_type_options_per_surface` UNCHANGED at H.10 (per (a);
  was updated at H.2; verify no H.10 edit accidentally re-touched
  the dict).
- `check_template_archive_v11` (or parameterized version) handles
  v11.0 frozen + v11.1 declared 6 entry-types.
- Check count = 44 unique / 47 invocations (per (b) + (c)).
- ENCODING-surface lock-step holds for each new check (per (d) + (e)
  + MF1 rule).
- Check 22 / Check 23 / Check 41 informational note (POQ-NEW-3 +
  reconciliation §5.3 + reconciliation §6.5 cross-cutting): the new
  Check NN..NN+3 are ORTHOGONAL to Check 22/23/41 — the new checks
  validate Part schema / exec-order / re-parentage / membership;
  Check 22/23/41 validate HELP-FRAGMENT surface-local invariants;
  no overlap. Note: reviewer should also verify that H.10's design
  does NOT inadvertently break Check 22/23/41 (e.g., by changing
  paths the HELP-FRAGMENT checks read).

**Commit subject scope-keyword (post-update):** **NO KEYWORD**
(mixed: `scripts/` + `.github/workflows/`). Per `CLAUDE.md` §
"Commit-subject scope-keyword convention": `.github/workflows/` is
NOT in `pack-only` deny-list (which denies `project-template/` +
`supporting-docs/`), so technically `pack-only` could apply. But
the planner default per original plan §5 H.10 is to use no keyword
for cross-directory commits unless certain — sticking with that
default; see §5 POQ-A3 for guidance.

**Commit message draft (post-update):**

```
feat: v11 — BD-185 validate-pack 4 new checks (Part schema, exec-order marker, Part re-parentage, Part membership) + CI wiring (Batch 19d.10)
```

(Removed "extensions" from the commit-message body since the
`expected_wi_type_options_per_surface` extension moved to H.2 per (a);
H.10 now centers on Check 32/33/34/35 extensions + 4 new checks.)

**Pack-coder PREFLIGHT line shape (post-update):**

```
PREFLIGHT: 6/6 in-scope file edits complete; verification PASS;
HEAD <SHA>; about to Write IMPL-REPORT to
maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.10.md
```

**Ordering dependency:** MUST land AFTER H.1 (SCHEMA exists for
`check_phase_part_schema_v11_1`), H.2 (per-surface dict already has
phase-part-skeleton; `check_issue_template_forms` PASSES at H.10
without re-edit), H.5 (`tracker-phase-part.sh` exists for Check 35
extension), H.6 (id-map.json / sidecar additive schema for
`check_part_re_parentage_invariants` runtime read), AND after H.9
(verbs that emit Parts exist for the new checks to ratify
post-fixture runs).

**Success criteria (post-update):**
1. Check 32, 33, 34, 35, `check_template_archive_v11` updated per
   architect §10.1.
2. `check_issue_template_forms` UNCHANGED at H.10 (per (a); was
   updated at H.2 ENCODING lock-step).
3. 4 new check functions implemented per architect §10.2.
4. 4 new per-check test files created with full coverage; follow
   `test-validate-pack-check-43.sh` synthetic-fixture pattern.
5. `.github/workflows/validate-pack.yml` wires the 4 new tests; Check
   42 PASSES (10 → 14 per-check test files).
6. `python3 scripts/validate-pack.py` exits 0 with **44 unique
   invoked checks (47 invocations)**.
7. ENCODING-surface lock-step: each new check has paired per-check
   test + workflow wiring (per MF1 rule).
8. `test-fixtures/manifest.txt` regenerated and staged.

### §4.11 — H.11 — METHODOLOGY.md substantive doc edits (token-economy)

**Original plan reference:** `PLAN-BD-185.md` §5 H.11.

**Reconciliation verdict:** NEEDS-ADJUSTMENT (architect §4.11).
Token-economy compliance added to reviewer-focus list.

**Files modified (post-update):** 1 EXTEND (same as original plan)

1. `supporting-docs/METHODOLOGY.md`

**Edit specification (post-update):**

Substance of H.11 §3 + §4 UNCHANGED (per spawn-prompt user-locked
text: "Substance of H.11 §3 + §4 unchanged"). The original plan
§5 H.11 #1-#5 edit specification stands.

Token-economy compliance directive (per `feedback_client_facing_token_economy`):

> METHODOLOGY edits must reference client-readable surfaces only.
> NO BD-NNN cites; NO architect-doc cites; NO pack-history.
> Acceptable reference targets:
> - `pack phase split` / `pack phase reorder` / `pack task supersede`
>   verbs (documented in client-installed HELP-FRAGMENT-TRACKER.md)
> - Per-entry tree `_rules.md` + `_intro.md` (client-installed)

This is a REVIEWER-FOCUS gate, not a substance change. The original
plan §5 H.11 plan text used internal scaffolding references like
"(architect §4.4)" and "(architect §4.5 + H.9)" inside the prose —
those are PLAN-TEXT references that the coder MUST NOT carry into
the actual METHODOLOGY edits.

**Verification commands (post-update):**

Original plan §5 H.11 verification commands stand, plus:

```bash
# Token-economy compliance check (no BD-NNN / architect-doc / pack-history refs):
grep -nE "BD-[0-9]+|ARCHITECTURE-BD-|PLAN-BD-|IMPLEMENTATION-REPORT-BD-|PACK-REVIEW-BD-" supporting-docs/METHODOLOGY.md
# Expected: NO new matches introduced by H.11 (pre-existing references
# in METHODOLOGY.md may exist from prior BDs; reviewer verifies that
# H.11's diff introduces ZERO new BD/architect-doc/pack-history refs).
# Coder runs `git diff supporting-docs/METHODOLOGY.md` and inspects
# every added line for the pattern; report any matches in the IMPL-
# REPORT (no leak in H.11's added content).

# Spot-check sections present (from original plan):
grep -nE "^### Part state taxonomy|^### Creating Parts programmatically|^### Execution-note-status historical|pack task supersede|pack phase collapse" supporting-docs/METHODOLOGY.md | head -10
```

**RC9 manifest regen (post-update):** REQUIRED (per original plan).
`supporting-docs/` in v11-surface per BD-176.

**Per-commit reviewer scope (post-update):** **INLINE — sliding-window
scope (sliding from H.9: H.10+H.11)** per original plan §3 (α-sliding)
mapping. Boundary-sensitive review focus (additions to original plan):
- **Token-economy compliance.** Verify NO new BD-NNN / architect-doc /
  pack-history references introduced in METHODOLOGY edits. Acceptable
  references: client-installed verb docs + client-installed per-entry
  tree contracts.
- All other reviewer-focus dimensions from original plan §5 H.11 stand
  unchanged.

**Commit subject scope-keyword (post-update):** **NO KEYWORD** per
original plan §5 H.11 (supporting-docs/-only + maintenance-docs/
IMPL-REPORT staging makes it mixed; see §5 POQ-A3).

**Commit message draft (post-update):**

```
feat: v11 — BD-185 METHODOLOGY.md Multi-part + execution-order + supersede + historical-marker (Batch 19d.11)
```

(Unchanged from original plan.)

**Pack-coder PREFLIGHT line shape (post-update):**

```
PREFLIGHT: 1/1 in-scope file edits complete; verification PASS;
HEAD <SHA>; about to Write IMPL-REPORT to
maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.11.md
```

**Ordering dependency:** MUST land AFTER H.9 (verb names referenced
in METHODOLOGY exist as actual implementations) AND after H.10 (CI
checks ratify the rules METHODOLOGY documents).

**Success criteria (post-update):**

Original plan §5 H.11 success criteria #1-#5 stand, plus:
6. NO new BD-NNN / architect-doc / pack-history references introduced
   in METHODOLOGY.md edits (per token-economy compliance directive).


### §4.12 — H.12 — MIGRATION + HELP-FRAGMENT pair (REPLACEMENT)

**Original plan reference:** `PLAN-BD-185.md` §5 H.12 ("MIGRATION-v10-to-v11.md
edits + HELP-FRAGMENT-PACK + HELP-FRAGMENT-TRACKER (pack-ops +
project-template mirrors)" with `diff = empty` byte-identity
assertion).

**Reconciliation verdict:** WRONG-AND-NEEDS-REPLACEMENT (architect
§4.12). Per-surface same-content edits; no byte-identity asserted
(POQ-NEW-2 user-locked).

**Files modified (post-update):** 5 EXTEND (file list UNCHANGED from
original plan; verification commands + framing CHANGED)

1. `supporting-docs/MIGRATION-v10-to-v11.md`
2. `pack-ops/HELP-FRAGMENT-PACK.md`
3. `pack-ops/HELP-FRAGMENT-TRACKER.md`
4. `project-template/docs/pack/HELP-FRAGMENT.md`
5. `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`

**Edit specification (post-update):**

Per the user-locked H.12 replacement text: "Per-surface same-content
edits; no byte-identity asserted." Reframe H.12 as PER-SURFACE
same-content edits applied INDEPENDENTLY to each surface — the
edits are SEMANTICALLY EQUIVALENT (same verbs added to each
fragment) but NOT MECHANICALLY BYTE-IDENTICAL.

(1) `supporting-docs/MIGRATION-v10-to-v11.md` (additive content;
    subject to token-economy compliance same as H.11/H.13)
- Original plan §5 H.12 #1 edits stand:
  - `Per-entry decomposition` section: Multi-part phase H3 sub-sections
    preserved INLINE in `phase-N.md` during Phase A decompose;
    execution-order initialization writes `<!-- execution-order: NNN -->`
    markers; D8 structured warning template referenced.
  - NEW section `Phase B — multi-part phase tracker materialization`
    inserted after existing Phase B section.
- Token-economy compliance: MIGRATION-v10-to-v11.md edits may carry
  LEGITIMATE migration-mechanism cites per reconciliation §6.2 ("Class A
  LEGITIMATE migration-mechanism cites preserved per BD-193 §6.3 user
  resolution"). No BD-NNN / architect-doc / pack-history WASTE cites.

(2) `pack-ops/HELP-FRAGMENT-PACK.md` (add rows): `pack phase split`,
    `pack phase reorder`, `pack task supersede`. Content audience:
    pack-developer.

(3) `pack-ops/HELP-FRAGMENT-TRACKER.md` (add rows): `pack tracker
    phase split`, `pack tracker phase reorder`. Content audience:
    pack-developer.

(4) `project-template/docs/pack/HELP-FRAGMENT.md` (add same verb
    rows as pack-side HELP-FRAGMENT-PACK; client audience).

(5) `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` (add same
    verb rows as pack-side HELP-FRAGMENT-TRACKER; client audience).

**Same content, applied per-surface independently. NOT byte-identical
mirrors.** Today at HEAD `e128a2c`, `pack-ops/HELP-FRAGMENT-TRACKER.md`
and `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` are
COINCIDENTALLY byte-identical (49 lines each); that is COINCIDENCE per
`feedback_pack_project_separation_of_concerns`, NOT design rationale.
Post-H.12 they should remain SEMANTICALLY equivalent (same verb rows
added to each); MECHANICAL byte-identity is not asserted and not
required.

**Verification commands (post-update):**

```bash
# 1. Validator passes:
python3 scripts/validate-pack.py
# Expected: PASS

# 2. Pack-side new verbs present in HELP-FRAGMENT-PACK:
grep -nE "pack phase split|pack phase reorder|pack task supersede" pack-ops/HELP-FRAGMENT-PACK.md
# Expected: 3 lines (one per new verb)

# 3. Pack-side new verbs present in HELP-FRAGMENT-TRACKER:
grep -nE "pack tracker phase split|pack tracker phase reorder" pack-ops/HELP-FRAGMENT-TRACKER.md
# Expected: 2 lines

# 4. Project-side new verbs present in HELP-FRAGMENT.md:
grep -nE "pack phase split|pack phase reorder|pack task supersede" project-template/docs/pack/HELP-FRAGMENT.md
# Expected: 3 lines

# 5. Project-side new verbs present in HELP-FRAGMENT-TRACKER.md:
grep -nE "pack tracker phase split|pack tracker phase reorder" project-template/docs/pack/HELP-FRAGMENT-TRACKER.md
# Expected: 2 lines

# 6. Pack-side existence assertion (Check 23 fail-loud per BD-194):
test -f pack-ops/HELP-FRAGMENT-TRACKER.md && echo "pack-side present"
test -f pack-ops/HELP-FRAGMENT-PACK.md && echo "pack-side present"
# Expected: "pack-side present" x2

# 7. Project-side existence assertion (Check 41 self-doc list per BD-194):
test -f project-template/docs/pack/HELP-FRAGMENT.md && echo "project-side present"
test -f project-template/docs/pack/HELP-FRAGMENT-TRACKER.md && echo "project-side present"
# Expected: "project-side present" x2

# 8. MIGRATION-v10-to-v11.md new section:
grep -nE "^## Phase B — multi-part" supporting-docs/MIGRATION-v10-to-v11.md
# Expected: ONE match

# 9. Per-check tests pass (Check 22 + 23 + 41 enforce surface-local
#    HELP-FRAGMENT invariants per BD-194):
bash scripts/tests/test-validate-pack-check-43.sh
# (Check 22 + 23 don't have dedicated test files in the per-check
# pattern; their assertions are covered by validate-pack.py main run.)

# 10. RC9 manifest regen:
bash test-fixtures/build.sh --all --clean
git diff --stat test-fixtures/manifest.txt
# Expected: non-empty (supporting-docs/ + pack-ops/ + project-template/
# all touched)

# 11. NO `diff = empty` assertions for HELP-FRAGMENT-* pairs:
# (Verification commands explicitly OMIT `diff pack-ops/HELP-FRAGMENT-TRACKER.md
# project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` per POQ-NEW-2 user
# resolution.)
```

**RC9 manifest regen (post-update):** REQUIRED.
`supporting-docs/` + `pack-ops/` + `project-template/` all touched.

**Per-commit reviewer scope (post-update):** **SKIP (covered by H.13
sliding window: H.12+H.13)** per original plan §3 (α-sliding) mapping.
Boundary-sensitive review focus deferred to H.13 reviewer:
- **Per-surface same-content judgment.** Verify each surface gains the
  SAME verb rows (semantic equivalence per audience); MECHANICAL
  byte-identity NOT required.
- **No `diff = empty` assertions on HELP-FRAGMENT-* pairs** (POQ-NEW-2
  user-locked).
- **Each surface's content is judged on its OWN merit per its audience.**
  Pack-side HELP-FRAGMENT-PACK is pack-developer audience; project-side
  HELP-FRAGMENT is client audience.
- **MIGRATION-v10-to-v11.md edits subject to token-economy compliance**
  (same directive as H.11). LEGITIMATE migration-mechanism cites
  acceptable; WASTE cites forbidden.
- **Phase B new section in MIGRATION-v10-to-v11.md complete; consistent
  with H.8 migrator behavior.**
- **New verb names exactly match implementation in H.9.**
- **Check 22 surface-local invariants hold after H.12** (per BD-194
  per-surface tracker_fragment lookup): each surface's verbs match
  its own HELP-FRAGMENT-TRACKER content.
- **POQ-NEW-3 informational note:** Check 22 enforces "each surface's
  verbs match its own HELP-FRAGMENT-TRACKER content"; Check 23
  enforces "pack-side HELP-FRAGMENT-TRACKER must exist (fail-loud)";
  Check 41 enforces "project-side HELP-FRAGMENT-TRACKER must be in
  `_CLIENT_INSTALLED_FILES`". H.12's edits add verb rows to each
  surface; Check 22/23/41 PASS post-edit.

**Commit subject scope-keyword (post-update):** **NO KEYWORD**
(mixed: `supporting-docs/` + `pack-ops/` + `project-template/` all
touched; genuinely cross-surface). Per `CLAUDE.md`: "If a batch's
work genuinely spans pack + project, the commit subject MUST NOT
carry an exclusive scope keyword."

**Commit message draft (post-update):**

```
feat: v11 — BD-185 MIGRATION + HELP-FRAGMENT (pack + tracker; per-surface same-content edits) (Batch 19d.12)
```

(Adjusted from original plan: replaced "pack-ops + client mirror"
with "per-surface same-content edits" to reflect POQ-NEW-2 user
resolution.)

**Pack-coder PREFLIGHT line shape (post-update):**

```
PREFLIGHT: 5/5 in-scope file edits complete; verification PASS;
HEAD <SHA>; about to Write IMPL-REPORT to
maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.12.md
```

**Ordering dependency:** MUST land AFTER H.8 (migrator behavior
documented in MIGRATION.md matches implementation) AND after H.9
(verbs documented in HELP-FRAGMENT exist as implementations) AND
after H.11 (METHODOLOGY.md companion doc lands first for
cross-reference).

**Success criteria (post-update):**
1. MIGRATION-v10-to-v11.md extended per original plan §5 H.12 #1.
2. HELP-FRAGMENT-PACK.md + HELP-FRAGMENT-TRACKER.md updated in both
   pack-ops/ AND project-template/docs/pack/ locations.
3. Each surface gains the SAME verb rows (semantic equivalence per
   audience).
4. **NO `diff = empty` assertions for HELP-FRAGMENT-* pairs**
   (POQ-NEW-2 user-locked).
5. Pack-side and project-side existence assertions PASS (Check 23
   + Check 41 per BD-194).
6. New verbs documented in HELP-FRAGMENT match H.9 implementation.
7. MIGRATION-v10-to-v11.md token-economy compliant (LEGITIMATE
   migration-mechanism cites only; no WASTE cites).
8. `python3 scripts/validate-pack.py` exits 0 (Check 22 + 23 + 41
   surface-local invariants hold).
9. `test-fixtures/manifest.txt` regenerated and staged.

### §4.13 — H.13 — PM-CHAT.md workflow + v11.0 phase-task-v11.0 SCHEMA cancelled (2 items)

**Original plan reference:** `PLAN-BD-185.md` §5 H.13.

**Reconciliation verdict:** NEEDS-ADJUSTMENT (architect §4.13). Two
items: (a) token-economy for PM-CHAT.md; (b) reviewer-focus addition
re BD-193 F2.a dep-grammar non-regression.

**Files modified (post-update):** 2 EXTEND (same as original plan)

1. `project-template/docs/pack/PM-CHAT.md`
2. `maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md`

**Edit specification (post-update):**

Substance of H.13 SCHEMA extension UNCHANGED (per spawn-prompt
user-locked text: "Substance of H.13 SCHEMA extension unchanged").
The original plan §5 H.13 #1-#2 edit specification stands.

Two additions per user-locked items:

(a) **Token-economy compliance for PM-CHAT.md edits (same directive
as H.11):** PM-CHAT.md is client-installed (per `init-project.sh`
stage S6) and RAG-indexed. NO BD-NNN cites; NO architect-doc cites;
NO pack-history. The PM-CHAT.md edits must reference:
- `pack phase split` / `pack task supersede` verbs (client-installed
  HELP-FRAGMENT-PACK / HELP-FRAGMENT.md documentation)
- Client-installed methodology / per-entry tree contracts
- NOT BD-185 / D-N labels / architect-doc sections

(b) **Reviewer-focus item (BD-193 F2.a non-regression):**
> Verify the BD-193 F2.a dep-grammar edit at L79, L91 is NOT
> regressed — `phase-task-v11.0/SCHEMA.md` must continue to omit
> `BD-NNN` from dep-grammar; H.13 only adds `cancelled` to state
> enumeration and `execution-note-status` marker.

Specifically: the H.13 SCHEMA Section 3 (Label family) extension
adds `cancelled` to the status enumeration. The H.13 SCHEMA Section 4
(Body grammar) extension adds the `<!-- execution-note-status:
historical -->` marker. NEITHER edit touches the dependencies grammar
at L79 or L91 (which were edited by BD-193 F2.a to REMOVE `BD-NNN`).
The coder must verify that the H.13 diff does NOT inadvertently re-add
`BD-NNN` to L79/L91 grammar.

D16 Convention Y framing reference (per §2.1 D16 reframing): H.13's
SCHEMA edit is a Class A intra-file additive extension (no removal).
The architect-doc references "intra-file additive extension permitted
under v11.0 structural-shape-frozen contract" — that wording is
incomplete after BD-193 F2.c (Class B carve-out precedent). The
addendum framing acknowledges both classes (per §2.1 D16); H.13 is
explicitly Class A.

**Verification commands (post-update):**

Original plan §5 H.13 verification commands stand, plus:

```bash
# Token-economy compliance check for PM-CHAT.md:
grep -nE "BD-[0-9]+|ARCHITECTURE-BD-|PLAN-BD-|IMPLEMENTATION-REPORT-BD-|PACK-REVIEW-BD-" project-template/docs/pack/PM-CHAT.md
# Expected: NO new matches introduced by H.13 (pre-existing references
# may exist from prior BDs; reviewer verifies H.13's diff introduces
# ZERO new BD/architect-doc/pack-history refs).

# BD-193 F2.a dep-grammar non-regression check:
grep -nE "BD-NNN" maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md | head -5
# Expected: NO matches (or pre-existing legitimate matches preserved;
# H.13's diff must not ADD new BD-NNN refs to dep-grammar at L79/L91).
# Coder runs `git diff …phase-task-v11.0/SCHEMA.md` and inspects added
# lines for `BD-NNN`; report any matches in the IMPL-REPORT.

# F2.a-specific lines: verify dep grammar at L79+L91 is unchanged or
# additively extended (no BD-NNN re-introduction):
sed -n '75,95p' maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md
# Expected: grammar admits `phase-N`, `phase-N.M`, `TD-NNN` (post-F2.a
# state); H.13 does NOT touch this region.
```

**RC9 manifest regen (post-update):** REQUIRED (per original plan).
`project-template/` in v11-surface per BD-176.

**Per-commit reviewer scope (post-update):** **INLINE — sliding-window
scope (sliding from H.11: H.12+H.13)** per original plan §3 (α-sliding)
mapping. Boundary-sensitive review focus (additions to original plan):
- **(a) PM-CHAT.md token-economy compliance.** Verify NO new BD-NNN /
  architect-doc / pack-history references introduced.
- **(b) BD-193 F2.a non-regression.** Verify `phase-task-v11.0/SCHEMA.md`
  dep grammar at L79/L91 is UNCHANGED (continues to omit `BD-NNN`).
  H.13 only adds `cancelled` state + `execution-note-status: historical`
  marker.
- **D16 Class A intra-file additive extension.** Verify the SCHEMA
  edit adds (Class A) and does not remove (Class B). v11.0 archive
  directory structure unchanged (5 entry-type subdirs); only the
  SCHEMA file content extends.
- All other reviewer-focus dimensions from original plan §5 H.13 stand.

**Commit subject scope-keyword (post-update):** **NO KEYWORD** per
original plan §5 H.13 (mixed: `project-template/` + `maintenance-docs/`).

**Commit message draft (post-update):**

```
feat: v11 — BD-185 PM-CHAT workflow + phase-task-v11.0 SCHEMA cancelled-state extension (D5; D16 Class A) (Batch 19d.13)
```

(Adjusted from original plan: added "D16 Class A" framing for clarity
per §2.1 D16 reframing.)

**Pack-coder PREFLIGHT line shape (post-update):**

```
PREFLIGHT: 2/2 in-scope file edits complete; verification PASS;
HEAD <SHA>; about to Write IMPL-REPORT to
maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.13.md
```

**Ordering dependency:** MUST land AFTER H.9 (verbs referenced in
PM-CHAT exist as implementations) AND after H.11 (METHODOLOGY.md
companion doc lands first; cross-reference) AND after H.12
(HELP-FRAGMENT documents the verbs already).

**Success criteria (post-update):**

Original plan §5 H.13 success criteria #1-#6 stand, plus:
7. PM-CHAT.md token-economy compliant (no new BD-NNN / architect-doc /
   pack-history refs).
8. BD-193 F2.a dep-grammar at `phase-task-v11.0/SCHEMA.md` L79/L91
   NOT regressed (continues to omit `BD-NNN`).
9. H.13 SCHEMA edit is D16 Class A intra-file additive extension
   (no removal).

### §4.14 — H.14 — Templates-archive cross-references (diff target adjustment)

**Original plan reference:** `PLAN-BD-185.md` §5 H.14.

**Reconciliation verdict:** NEEDS-ADJUSTMENT (architect §4.14). Diff
target changes from pack-root to project-template per POQ-NEW-1
Option c.

**Files modified (post-update):** 2 EXTEND (same as original plan)

1. `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md`
2. `maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md`

**Edit specification (post-update):**

(1) **v11.1/INDEX.md cross-reference closure** per original plan
§5 H.14 #1:
- Verify all 6 entry-types in v11.1 INDEX have correct cross-references
  (5 inherit from v11.0; 1 new = phase-part-v11.1).
- Verify `v11.1/forms/work-item.yml` exists from H.2 (per POQ-NEW-1
  Option c: byte-identical to project-template-side); cross-reference
  from INDEX.

(2) **v11.0/INDEX.md forward-reference footnote** per original plan
§5 H.14 #2 (D16 Class A intra-file additive extension):
- EXTEND v11.0/INDEX.md with a forward-reference footnote: "**Note:**
  v11.1+ archive (at `maintenance-docs/v11-research/templates-archive/v11.1/`)
  adds the `phase-part-v11.1` entry type and extends `phase-task-v11.0`
  admitted state values with `cancelled` (per D5 + D16 Convention Y).
  See `v11.1/INDEX.md` for details."
- D16 Class A applies (additive content, no removal); per §2.1 D16
  reframing acknowledging both classes.

**Verification commands (post-update):**

Per the user-locked diff target adjustment:

```bash
# 1. Validator passes:
python3 scripts/validate-pack.py
# Expected: PASS

# 2. v11.0 directory structure unchanged (structural shape frozen per D16):
ls maintenance-docs/v11-research/templates-archive/v11.0/ | sort
# Expected: bd-v11.0 forms INDEX.md inbound-v11.0 phase-epic-v11.0 phase-task-v11.0 td-v11.0

# 3. v11.0/INDEX.md carries v11.1 forward-reference footnote:
grep -nE "v11.1|phase-part-v11.1|D16|Convention Y" maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md
# Expected: matches (the new forward-reference footnote)

# 4. v11.1 has 6 entry-types declared in INDEX:
grep -nE "phase-part-v11.1|phase-task-v11.0|phase-epic-v11.0|bd-v11.0|td-v11.0|inbound-v11.0" maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md
# Expected: matches (each entry type cited)

# 5. **DIFF TARGET CHANGED PER POQ-NEW-1 OPTION c:**
#    Archive snapshot byte-identical to project-template (NOT pack-root):
diff maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml \
     project-template/.github/ISSUE_TEMPLATE/work-item.yml
# Expected: empty (archive snapshots project-template per POQ-NEW-1
# Option c; matches v11.0 archive precedent)

# 6. Archive snapshot NOT byte-identical to pack-root (intentional divergence):
diff maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml \
     .github/ISSUE_TEMPLATE/work-item.yml | head -5
# Expected: non-empty (per intentional divergence; pack-root is `{bd}`,
# archive is project-template-shaped per Option c)
```

**RC9 manifest regen (post-update):** NO. `maintenance-docs/` alone
is NOT in the v11-surface 4-directory trigger per BD-176. Coder
verifies manifest diff is empty after `bash test-fixtures/build.sh
--all --clean`; if empty, no staging.

**Per-commit reviewer scope (post-update):** **INLINE — sliding-window
scope (H.14 alone; prior INLINE was H.13)** per original plan §3
(α-sliding) mapping. Boundary-sensitive review focus (updates from
original plan):
- **v11.0 archive directory structure unchanged** (modulo H.13's
  intra-file SCHEMA extension and H.14's intra-file INDEX extension —
  both permitted under D16 Convention Y Class A).
- **v11.0/INDEX.md forward-reference footnote correctness.** Verify
  the footnote names v11.1 archive, phase-part-v11.1 entry type, D5
  cancelled state, and D16 Convention Y per POQ-6 (original) +
  reconciliation §2.1 D16 reframing.
- **v11.1 INDEX.md declares 6 entry-types.** Verify enumeration
  completeness; cross-references resolvable.
- **DIFF TARGET (CHANGED).** v11.1/forms/work-item.yml byte-identical
  to project-template-side (POQ-NEW-1 Option c); NOT to pack-root.
- All other reviewer-focus dimensions from original plan §5 H.14 stand.

**Commit subject scope-keyword (post-update):** **`pack-only`** per
original plan §5 H.14 (per original POQ-2 resolution: `maintenance-docs/`-only
commit; deny-list (project-template/ + supporting-docs/) does not trip).

**Commit message draft (post-update):**

```
feat: v11 — BD-185 templates-archive cross-references (v11.0 ↔ v11.1; archive snapshot project-template per POQ-NEW-1) (Batch 19d.14) (pack-only)
```

(Adjusted from original plan: added archive snapshot target reference
per POQ-NEW-1 Option c.)

**Pack-coder PREFLIGHT line shape (post-update):**

```
PREFLIGHT: 2/2 in-scope file edits complete; verification PASS;
HEAD <SHA>; about to Write IMPL-REPORT to
maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.14.md
```

**Ordering dependency:** MUST land AFTER H.2 (live project-template
work-item.yml exists for byte-identical archive copy) AND after H.13
(v11.0 phase-task-v11.0 SCHEMA cancelled-state extension landed —
INDEX should reflect it).

**Success criteria (post-update):**

1. v11.1 INDEX.md declares 6 entry-types with v11.0 cross-references.
2. v11.1/forms/work-item.yml byte-identical to
   `project-template/.github/ISSUE_TEMPLATE/work-item.yml` (NOT
   pack-root; per POQ-NEW-1 Option c).
3. v11.0/INDEX.md carries forward-reference footnote naming v11.1
   archive + phase-part-v11.1 + D5 cancelled state + D16 Convention Y.
4. v11.0 archive directory structure unchanged (5 entry-type subdirs
   + forms + INDEX); only intra-file content extensions per D16 Class
   A.
5. `python3 scripts/validate-pack.py` exits 0.


### §4.16 — H.16 — End-of-batch reviewer + status flip (reviewer scope expansion)

**Original plan reference:** `PLAN-BD-185.md` §5 H.16.

**Reconciliation verdict:** NEEDS-ADJUSTMENT (architect §4.16).
Reviewer scope expanded with 4 BD-185-specific dimensions.

**Files modified (post-update):** varies (depends on whether fix-coder
findings produce file edits; standalone status flip if no findings)

If FIX + flip combined:
- (varies based on triage outcome)
- `pack-ops/BACKLOG.md` (status flip Open → Resolved)

If standalone status flip:
- `pack-ops/BACKLOG.md` only

**Edit specification (post-update):**

Substance of H.16 batch close mechanics UNCHANGED from original plan
§5 H.16. The user-locked addition is reviewer-scope expansion.

End-of-batch reviewer prompt construction includes BD-185 reviewer
focus dimensions (per user-locked spawn-prompt text), in addition to
original plan §5 H.16 dimensions:

1. **Token-economy compliance** (no BD/architect-doc/pack-history refs
   in client-installed surfaces). Surfaces to audit:
   - `supporting-docs/METHODOLOGY.md` (per H.11)
   - `supporting-docs/MIGRATION-v10-to-v11.md` (per H.12; LEGITIMATE
     migration-mechanism cites permitted)
   - `project-template/docs/pack/PM-CHAT.md` (per H.13)
   - `project-template/docs/pack/HELP-FRAGMENT.md` (per H.12)
   - `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` (per H.12)
   - `project-template/docs/project/implementation-plan/_rules.md`
     (per H.3)
   - `project-template/docs/project/implementation-plan/_intro.md`
     (per H.3)
   - `pack-ops/HELP-FRAGMENT-PACK.md` (pack-side but indexable per
     reconciliation §6.2)
   - `pack-ops/HELP-FRAGMENT-TRACKER.md` (pack-side but indexable per
     reconciliation §6.2)

2. **Pack/project separation discipline** (per `feedback_pack_project_separation_of_concerns`):
   - Per-surface judgments; no cross-surface byte-identity asserted.
   - `work-item.yml` pair (pack-root `{bd}` + project-template 4-option):
     intentionally divergent.
   - `HELP-FRAGMENT-TRACKER.md` pair (pack-ops + project-template):
     COINCIDENTALLY byte-identical at HEAD; semantic equivalence post-H.12
     but byte-identity not asserted per POQ-NEW-2 / BD-194 Check 24
     retirement.

3. **BD-NNN operational-rule preservation** (per `feedback_bd_pack_only_operational_rule`):
   - H.13 v11.0 SCHEMA edit does not regress F2.a.
   - Dep grammars don't re-acquire BD-NNN at any project-side surface.
   - Client-facing form admissions, parser regexes, dependency grammars
     remain BD-NNN-free at project-side.

4. **ENCODING-surface enumeration completeness** (per
   `feedback_enumerate_encoding_surfaces_in_audits` — the MF1 rule
   landed at `e128a2c`):
   - H.2 form changes → validator dict + tests updated in lock-step
     (3 ENCODING surfaces: form, validator, test).
   - H.10 new checks → per-check test files + CI wiring updated in
     lock-step (3 ENCODING surfaces: validator, test, workflow).
   - H.12 HELP-FRAGMENT edits → Check 22/23/41 PASS at each surface
     (lock-step at the per-surface tracker_fragment lookup).
   - H.13 SCHEMA edit → Check 22 surface-local invariants still hold
     (SCHEMA is project-archived; HELP-FRAGMENT references unchanged).

The original plan §5 H.16 reviewer focus dimensions (SC1-SC8
traceability, D1-D16 fidelity, C-1 grammar, C-4 invariants, C-5
trinity, no-solutions / no-orphan / no-leaks) ALL STAND.

Close-commit summary may optionally mention BD-193/194 architectural
baseline integration (per user-locked spawn-prompt text). Suggested
addition to the original plan's summary suggestion: "...integrated
with BD-193/BD-194 architectural baseline (pack/project separation
discipline + Check 24 retirement + per-surface ENCODING enumeration)."

**Verification commands (post-update):**

Original plan §5 H.16 verification commands stand, plus:

```bash
# Token-economy compliance sweep across BD-185 H.X surfaces:
for f in supporting-docs/METHODOLOGY.md \
         supporting-docs/MIGRATION-v10-to-v11.md \
         project-template/docs/pack/PM-CHAT.md \
         project-template/docs/pack/HELP-FRAGMENT.md \
         project-template/docs/pack/HELP-FRAGMENT-TRACKER.md \
         project-template/docs/project/implementation-plan/_rules.md \
         project-template/docs/project/implementation-plan/_intro.md \
         pack-ops/HELP-FRAGMENT-PACK.md \
         pack-ops/HELP-FRAGMENT-TRACKER.md; do
  git diff 2648bb2 HEAD -- "$f" 2>&1 | grep -nE "^\+.*(BD-[0-9]+|ARCHITECTURE-BD-|PLAN-BD-|IMPLEMENTATION-REPORT-BD-|PACK-REVIEW-BD-)" || true
done
# Expected: NO new BD-NNN / architect-doc / pack-history refs introduced
# by Batch 19d (modulo LEGITIMATE migration-mechanism cites in
# MIGRATION-v10-to-v11.md per BD-193 §6.3 user resolution).

# BD-193 F2.a non-regression check (full-batch sweep):
git diff 2648bb2 HEAD -- maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md 2>&1 | grep -nE "^\+.*BD-NNN" || true
# Expected: NO `BD-NNN` re-added to L79/L91 dep grammar.

# Pack/project separation: HELP-FRAGMENT pair status
echo "Pack-side: $(wc -l < pack-ops/HELP-FRAGMENT-TRACKER.md) lines"
echo "Project-side: $(wc -l < project-template/docs/pack/HELP-FRAGMENT-TRACKER.md) lines"
# Same content (post-H.12 verbs added per surface) is expected;
# byte-identity is not asserted (per POQ-NEW-2 + BD-194 Check 24
# retirement).

# ENCODING-surface lock-step verification at batch close:
# H.2 lock-step:
grep -c "phase-part-skeleton" \
     project-template/.github/ISSUE_TEMPLATE/work-item.yml \
     scripts/validate-pack.py \
     scripts/tests/test-issue-forms.sh
# Expected: ≥1 per file (form / validator / test all encode the option)

# H.10 lock-step:
ls scripts/tests/test-validate-pack-check-{NN,NN+1,NN+2,NN+3}.sh
grep -c "test-validate-pack-check-NN" .github/workflows/validate-pack.yml
# Expected: 4 files exist; workflow has 4 invocations

# All BD-185 per-check tests + extended tests pass:
bash scripts/tests/test-validate-pack-check-43.sh
bash scripts/tests/test-validate-pack-checks-32-33-34.sh
bash scripts/tests/test-validate-pack-checks-36-37-38.sh
bash scripts/tests/test-validate-pack-check-42.sh
bash scripts/tests/test-tracker-phase-part.sh  # from H.5
bash scripts/tests/template-version-test.sh    # extended in H.15
bash scripts/tests/test-per-entry.sh           # extended in H.15
# Expected: each exits 0
```

**RC9 manifest regen (post-update):** Required IF the fix-commit
modifies any v11-surface file (per original plan).

If standalone status flip on `pack-ops/BACKLOG.md` only: `pack-ops/`
is in v11-surface but `BACKLOG.md` is not fixture-affecting; manifest
diff should be empty. If non-empty, stage the manifest.

**Per-commit reviewer scope (post-update):** **END-OF-BATCH** (per
original plan; this IS the end-of-batch reviewer pass). Boundary-sensitive
review focus extends original plan with the 4 user-locked dimensions
above.

**Commit subject scope-keyword (post-update):** depends on commit
shape:
- **If combined fix + status flip:** likely mixed scope; use NO
  KEYWORD.
- **If standalone status flip on `pack-ops/BACKLOG.md` only:**
  `PM-only` (BACKLOG.md is PM-only per PACK-AGENTS.md).

**Commit message draft (post-update):**

- **If combined fix + status flip:**
  ```
  fix: v11 — BD-185 broad batch review/fix + status flip (Batch 19d)
  ```
- **If standalone status flip:**
  ```
  docs: v11 — flip BD-185 to Resolved
  ```

(Unchanged from original plan.)

**Pack-coder PREFLIGHT line shape (post-update, if fix-coder spawns):**

```
PREFLIGHT: <N>/<N> in-scope file edits complete; verification PASS;
HEAD <SHA>; about to Write IMPL-REPORT to
maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.16-FIX.md
```

(If H.16 is standalone status flip with no fix-coder spawn, Pack
Chat applies the BACKLOG edit directly per PM-only files rule — no
PREFLIGHT line required.)

**Ordering dependency:** RUN AFTER H.15. This IS the batch close. No
subsequent commits in Batch 19d.

**Success criteria (post-update):**

Original plan §5 H.16 success criteria #1-#6 stand, plus the four
user-locked reviewer-focus dimensions are verified clean:
7. Token-economy compliance: no new BD/architect-doc/pack-history
   refs in any client-installed surface (modulo MIGRATION-v10-to-v11.md
   LEGITIMATE migration-mechanism cites).
8. Pack/project separation discipline: per-surface judgments preserved;
   no cross-surface byte-identity asserted on `work-item.yml` pair or
   HELP-FRAGMENT-* pairs.
9. BD-NNN operational-rule preservation: H.13 v11.0 SCHEMA edit does
   not regress F2.a; dep grammars don't re-acquire BD-NNN at any
   project-side surface.
10. ENCODING-surface enumeration completeness: H.2 + H.10 + H.12 +
    H.13 each updated all paired ENCODING surfaces in lock-step.

---

## §5 — Planner-level POQs

The following planner-level POQs emerged from converting the
user-locked decisions into commit-level mechanics. Surfaced for user
resolution per `feedback_no_solutions_in_agent_prompts` (the planner
does NOT auto-resolve).

### §5.1 — POQ-A1 — Check 36 failure on commit `e128a2c`

**Context.** At the addendum's authoring HEAD `e128a2c`, `python3
scripts/validate-pack.py` reports `FAILED — 1 issue(s) found`:

```
FAIL: Commit e128a2c subject claims `PM-only` but touches non-PM-only
paths: .claude/skills/review/SKILL.md, .codex/skills/review/SKILL.md,
.gemini/skills/review/SKILL.md (PM-only permitted set per
pack-ops/PACK-AGENTS.md § 'PM-only files and directories')
```

**Question.** The commit `e128a2c` landed BOTH the trinity Pack-memory
ENCODING-surface enumeration rule AND the `.claude/.codex/.gemini/skills/review/SKILL.md`
operational mirrors. The trinity edits are PM-only (per PACK-AGENTS.md);
the review skill edits are pack-skill operational content. The commit
claimed `PM-only` in subject but Check 36 disallows the review skill
paths under PM-only.

Three options for the H.2 coder PREFLIGHT to pass:

| Option | Mechanic | Pros | Cons |
|---|---|---|---|
| (a) Land a corrective commit BEFORE H.2 spawns | A new commit fixes the `e128a2c` subject claim (e.g., re-tag `PM-only` to `pack-only` or no-keyword) | Clean PREFLIGHT baseline; no scope-keyword carryover ambiguity at H.2 | Adds 1 commit to history; corrective commits for subject-claim violations are unusual (this would need a Pack Chat discussion-and-user-approval per CLAUDE.md `fix:` shape rules) |
| (b) Allow H.2 PREFLIGHT to surface the failure and Pack Chat triages | H.2 coder runs validate-pack as part of PREFLIGHT, gets the same failure, reports the situation in IMPL-REPORT §6 (plan deviations) or §7 (POQs) | Honest carryover; Pack Chat decides if/how to resolve at H.2 commit time | H.2 PREFLIGHT cannot pass cleanly until Check 36 is satisfied (per `feedback_pack_coder_preflight_pattern`); coder cannot write IMPL-REPORT until verification PASS |
| (c) Investigate whether Check 36 has a false-positive case for `PM-only` + review-skill operational mirrors | Re-examine `pack-ops/PACK-AGENTS.md` § "PM-only files and directories" to see if review-skill operational mirrors should be added to the PM-only permitted set | Could resolve the underlying issue if review-skill edits are conceptually PM-only (Pack Chat orchestrates skill content) | Requires architect-pass thinking (PACK-AGENTS.md edit + Check 36 logic edit); large-scope investigation for a single-commit issue |

**Planner has no evidence-based recommendation** (per `feedback_decision_presentation_protocol`
extended 2026-05-25: "evidence-based recommendation REQUIRED; never
guess; if no evidence → no recommendation"). The planner cannot
determine which option the user prefers without seeing the user's
intent for `e128a2c`. Pack Chat should surface this POQ to the user
BEFORE H.2 coder spawns.

**Impact on H.0:** The H.0 success-criterion #3 ("`python3
scripts/validate-pack.py` exits 0") is currently NOT met at HEAD
`e128a2c`. Either a corrective commit lands or the success criterion
is temporarily relaxed at H.0 (with Pack Chat decision recorded in
H.0 PREFLIGHT report).

**POST-AUTHORING RESOLUTION (2026-05-27).** User selected Option (a)
(land a corrective commit BEFORE H.2 spawns). The corrective sequence:

1. Local `git reset HEAD~1` un-committed `e128a2c` (preserved working tree)
2. Stage trinity files only; commit as `f19b585`
   ("docs: v11 — pack memory: ENCODING-surface enumeration rule
   (PM-only)") — PM-only correct since only trinity touched
3. Force-push with `--force-with-lease` to overwrite remote `v11-dev`
4. Revert review-skill files in working tree
5. Spawn fix-coder for review-skill ENCODING section (applies same
   content as original `e128a2c` had)
6. Commit fix-coder's IMPL-REPORT + 3 review-skill mirrors as
   `42ce52d` ("docs: v11 — review skill: ENCODING-surface section
   (pack-only)") — pack-only correct since review-skill mirrors are
   pack-side but NOT PM-only per `pack-ops/PACK-AGENTS.md:140-164`

CI green on both `f19b585` and `42ce52d`. Recovery tag
`pre-rewrite-e128a2c-recovery` exists locally as rollback safety
point (not pushed). The H.0 success-criterion #3 is now satisfied
at the current branch tip; no relaxation needed.

**Lesson learned:** Pack Chat editing review-skill files directly
violated `feedback_pack_chat_does_no_fixes` (review skills are NOT
on PM-only list per PACK-AGENTS.md:140-164). Going forward, all
non-PM-only file edits go through fix-coder regardless of size or
apparent simplicity. The `e128a2c` mistake reinforced that the rule
has no size threshold.

### §5.2 — POQ-A2 — Gap-allocation for 4 new Check numbers (H.10)

**Context.** H.10 adds 4 new checks. The existing check-number space
has gaps (12-15 retired in v9-migrator removal; 24 retired in BD-194).
The 4 new checks need assigned numbers.

**Question.** Three allocation strategies:

| Strategy | Numbers | Rationale |
|---|---|---|
| (a) Sequential from current max | Check 44, 45, 46, 47 | Simplest; matches "next integer" pattern; no gap reuse |
| (b) Fill retired gaps | Check 12, 13, 14, 24 (or 12, 13, 14, 15) | Reuses retired numbers; consistent with "no waste"; but historically retired checks have informational comment blocks in `validate-pack.py` (e.g., "Check 24 RETIRED in BD-194") — reusing the number could confuse the audit |
| (c) Sequential with semantic affinity | Check 44 (phase-part-schema; near Check 35 phase-task-lib), Check 45 (exec-order-marker), Check 46 (Part re-parentage), Check 47 (Part membership) | Sequential AND keeps related checks adjacent; the existing Check 35 (phase-task-lib invariants) becomes a natural neighbor to Check 44 (phase-part-schema) |

**Planner recommendation (evidence-based):** Strategy (a) sequential
from current max (Check 44-47).

**Evidence.**
- Retired numbers (12-15, 24) carry informational comments documenting
  the retirement. Reuse would invalidate the comments and complicate
  audit history (someone reading `git blame` would see `Check 24 retired`
  comments interleaved with `Check 24` new check additions).
- Existing pattern (post-BD-194): retired numbers are NOT reused
  (Check 24 retirement preserved as historical record).
- Strategy (c)'s semantic affinity (Check 35 next to Check 44) is a
  cosmetic concern; numbers are arbitrary identifiers.
- Strategy (a) is the simplest path consistent with established
  convention.

**User decision needed.** Confirm strategy (a) (Check 44-47) OR
authorize alternative (b) or (c).

### §5.3 — POQ-A3 — Commit-subject scope-keyword for cross-surface commits with IMPL-REPORT staging

**Context.** Several H.X commits include scope edits PLUS the
accompanying IMPL-REPORT under `maintenance-docs/` AND
`test-fixtures/manifest.txt`. The `pack-only` scope-keyword's deny-list
denies `project-template/` + `supporting-docs/`. The IMPL-REPORT under
`maintenance-docs/` is NOT in the deny-list but is ALSO not in the
"permitted" column (the convention is positively-defined for `pack-only`
deny-rule).

**Question.** For commits like H.2 (project-template form + maintenance-docs
INDEX + scripts validator/test + test-fixtures manifest), what
scope-keyword applies?

Per CLAUDE.md:
- `pack-only` denies `project-template/` + `supporting-docs/`
- `project-only` denies pack-only paths (everything outside
  `project-template/` + `supporting-docs/`)
- `PM-only` permits per PACK-AGENTS.md § "PM-only files and directories"
  list
- (no keyword) = mixed-scope implicit

For H.2: edits hit `project-template/` (project-only territory) AND
`scripts/` (pack-only territory) AND `maintenance-docs/` (pack-only
territory) AND `test-fixtures/` (pack-only territory). The commit is
genuinely cross-surface (project + pack).

**Planner default (per CLAUDE.md rule):** "If a batch's work genuinely
spans pack + project, the commit subject MUST NOT carry an exclusive
scope keyword." Use NO KEYWORD.

This default is APPLIED in §4.2 H.2 commit-message draft (no keyword)
and §4.10 H.10 commit-message draft (no keyword) and §4.11 H.11
commit-message draft (no keyword) and §4.12 H.12 commit-message draft
(no keyword) and §4.13 H.13 commit-message draft (no keyword).

ONLY H.14 carries `(pack-only)` per the original plan — because H.14
touches only `maintenance-docs/` (which is pack-only territory; no
project-template / supporting-docs touched).

**User decision needed (if desired).** Confirm the planner default
(no keyword for genuinely cross-surface commits; pack-only for
maintenance-docs-only commits like H.14) OR authorize alternative
guidance.

### §5.4 — POQ-A4 — Coder spawn sequencing (single fresh-coder per H.X)

**Context.** Per `feedback_agent_teams_stage_lifecycle` ("each pack-coder
commit gets a FRESH coder instance — never reuse a coder across commits,
even within a stage"), each H.X commit requires a fresh coder spawn.

**Question.** Does the addendum-supplemented plan change the spawn
cadence for any H.X? Specifically:
- H.2 (with 5 modified files including ENCODING-lock-step surfaces)
- H.10 (with 6 modified files: validator + 4 per-check tests + workflow)

**Planner observation (informational; not a decision).** No change to
spawn cadence. Each H.X is still a single coder spawn that applies
all the H.X edits in one IMPL-REPORT. The increase in file count (5
for H.2, 6 for H.10) is well within established coder capacity
(prior BDs have applied 7+ file edits per IMPL-REPORT, e.g., BD-175
F1 cascade cleanup).

**User decision NOT needed** unless the user prefers to split H.2 or
H.10 across multiple commits (which would change the §5 H.X enumeration
and is a substantive plan revision, not a planner-level POQ).

---

## §6 — Lock-step coordination map (ENCODING-surface enumeration rule)

Per `feedback_enumerate_encoding_surfaces_in_audits` (MF1, landed at
`e128a2c`): for each H.X surface modification, every ENCODING surface
that asserts state about the audited surface MUST update in lock-step.
The table below traces ENCODING pairings for the 4 H.X steps where
the rule explicitly applies (H.2, H.10, H.12, H.13 per spawn-prompt
H.16 reviewer-focus item 4).

### §6.1 — H.2 ENCODING surfaces

| Surface | Role | Edit |
|---|---|---|
| `project-template/.github/ISSUE_TEMPLATE/work-item.yml` | AUDITED (the form file) | Add 4th wi-type option `phase-part-skeleton` + `wi-part-letter` field + description extensions |
| `.github/ISSUE_TEMPLATE/work-item.yml` | AUDITED (sibling pack-root form) | NOT EDITED (pack-root stays at `{bd}` per b4906d1; verified UNCHANGED) |
| `scripts/validate-pack.py` `expected_wi_type_options_per_surface` | ENCODING (validator dict) | Add `phase-part-skeleton` to project-template entry |
| `scripts/tests/test-issue-forms.sh` Group 2 + Group 5 | ENCODING (test assertions) | Update expected wi-type set + add presence assertions |
| `maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml` | ENCODING (archive snapshot per POQ-NEW-1 Option c) | NEW; byte-identical to project-template post-edit |
| `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md` "Forms file" section | ENCODING (archive INDEX) | Update L53-77 to describe post-H.2 snapshot |

**Lock-step verification (at H.2 commit time):**
```bash
# All 5 ENCODING surfaces touched in same commit:
git diff --name-only HEAD~1 HEAD | grep -E "work-item.yml|validate-pack.py|test-issue-forms.sh"
# Expected: 5 paths (project-template form, archive form, archive INDEX,
# validator, test)
```

**Failure mode prevented (per MF1):** Editing the form file but not
the validator/test would surface as a CI failure (validator dict
disagrees with form content). MF1 worked example: BD-185 reconciliation
audit walked F1 (form) + F2 (validator dict) but missed F3'
(test-issue-forms.sh Group 2/5 assertions). The lock-step coordination
map prevents recurrence.

### §6.2 — H.10 ENCODING surfaces

| Surface | Role | Edit |
|---|---|---|
| `scripts/validate-pack.py` Check NN..NN+3 functions | AUDITED (validator extensions) | Add 4 new check functions |
| `scripts/tests/test-validate-pack-check-NN.sh` | ENCODING (per-check test for new Check NN) | NEW; synthetic fixture pattern per `test-validate-pack-check-43.sh` |
| `scripts/tests/test-validate-pack-check-NN+1.sh` | ENCODING (per-check test for new Check NN+1) | NEW |
| `scripts/tests/test-validate-pack-check-NN+2.sh` | ENCODING (per-check test for new Check NN+2) | NEW |
| `scripts/tests/test-validate-pack-check-NN+3.sh` | ENCODING (per-check test for new Check NN+3) | NEW |
| `.github/workflows/validate-pack.yml` | ENCODING (CI workflow wiring) | Add 4 new `bash scripts/tests/test-validate-pack-check-<N>.sh` invocation lines |

**Lock-step verification (at H.10 commit time):**
```bash
# All 6 ENCODING surfaces touched in same commit:
git diff --name-only HEAD~1 HEAD | grep -E "validate-pack.py|test-validate-pack-check-|validate-pack.yml"
# Expected: 6 paths (validator + 4 new test files + workflow)
```

**Failure mode prevented:** Adding new check functions without
per-check tests / workflow wiring → Check 42 FAIL (workflow wiring
verification). Adding tests without workflow wiring → Check 42 FAIL.

### §6.3 — H.12 ENCODING surfaces

| Surface | Role | Edit |
|---|---|---|
| `pack-ops/HELP-FRAGMENT-PACK.md` | AUDITED (pack-side help fragment) | Add 3 new verb rows |
| `pack-ops/HELP-FRAGMENT-TRACKER.md` | AUDITED (pack-side tracker help fragment) | Add 2 new verb rows |
| `project-template/docs/pack/HELP-FRAGMENT.md` | AUDITED (project-side help fragment) | Add 3 new verb rows (same content as pack-side) |
| `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` | AUDITED (project-side tracker help fragment) | Add 2 new verb rows (same content as pack-side) |
| `supporting-docs/MIGRATION-v10-to-v11.md` | AUDITED (migration doc) | Add Phase B multi-part materialization section |
| `scripts/validate-pack.py` Check 22 | ENCODING (per-surface tracker_fragment lookup; per BD-194) | NO CODE EDIT; verify Check 22 PASSES post-H.12 (each surface's verbs match its own HELP-FRAGMENT-TRACKER) |
| `scripts/validate-pack.py` Check 23 | ENCODING (pack-side existence fail-loud; per BD-194) | NO CODE EDIT; verify Check 23 PASSES post-H.12 |
| `scripts/validate-pack.py` Check 41 | ENCODING (project-side self-doc list; per BD-194) | NO CODE EDIT; verify Check 41 PASSES post-H.12 |

**Lock-step verification (at H.12 commit time):**
```bash
# All 5 AUDITED surfaces touched + Check 22/23/41 PASS verification:
git diff --name-only HEAD~1 HEAD | grep -E "HELP-FRAGMENT|MIGRATION-v10"
# Expected: 5 paths
python3 scripts/validate-pack.py 2>&1 | grep -E "Check (22|23|41)"
# Expected: each OK
```

**Failure mode prevented:** Adding verb rows to METHODOLOGY prose
references but not HELP-FRAGMENT → Check 22 FAIL (surface-local
invariant: HELP-FRAGMENT-TRACKER must list verbs referenced in
substantive docs). Adding only pack-side rows but not project-side
→ semantic mismatch (per `feedback_pack_project_separation_of_concerns`,
each audience needs the verb documented in its own help fragment).

### §6.4 — H.13 ENCODING surfaces

| Surface | Role | Edit |
|---|---|---|
| `project-template/docs/pack/PM-CHAT.md` | AUDITED (PM workflow doc; client-installed) | Reference `pack phase split` + `pack task supersede` workflows |
| `maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md` Section 3 (Label family) | AUDITED (v11.0 archive SCHEMA; D16 Class A) | Add `cancelled` to status enumeration |
| `maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md` Section 4 (Body grammar) | AUDITED (same file, different section) | Add `<!-- execution-note-status: historical -->` marker |
| `maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md` L79/L91 (dep grammar) | NOT EDITED (BD-193 F2.a preserved) | Verify NO `BD-NNN` re-introduced |
| `scripts/validate-pack.py` Check 35 (`check_tracker_phase_task_invariants`) | ENCODING (validator; admits `cancelled` per D5) | Updated at H.10 per original plan; verify Check 35 admits `cancelled` post-H.13 SCHEMA edit |
| `scripts/validate-pack.py` Check 22 (per-surface tracker_fragment lookup) | ENCODING (per BD-194) | NO CODE EDIT; verify Check 22 surface-local invariants still hold (PM-CHAT.md references the new verbs; HELP-FRAGMENT-TRACKER must list them — covered by H.12 lock-step) |

**Lock-step verification (at H.13 commit time):**
```bash
# 2 AUDITED files edited in same commit:
git diff --name-only HEAD~1 HEAD | grep -E "PM-CHAT|phase-task-v11.0/SCHEMA"
# Expected: 2 paths

# Check 22 + Check 35 invariants hold:
python3 scripts/validate-pack.py 2>&1 | grep -E "Check (22|35)"
# Expected: each OK
```

**Failure mode prevented:** Adding `cancelled` to SCHEMA without
Check 35 admitting it → Check 35 FAIL. Editing SCHEMA dep grammar
(re-adding BD-NNN) → F2.a regression; surfaces via H.16 reviewer
focus item 3.


---

## §7 — Final verification gates (post-H.16)

This section UPDATES original plan §7 with the post-reconciliation
counts and gates.

After H.16 lands successfully:

```bash
# 1. Validator passes with all 4 new H.10 checks active:
python3 scripts/validate-pack.py
# Expected exit code: 0
# Expected check count: 44 unique invoked checks / 47 invocations
#   (40 unique baseline + 4 new at H.10; 43 invocations baseline +
#    4 new single-invocation = 47 invocations)

# 2. Check count verification:
python3 scripts/validate-pack.py 2>&1 | grep -c "^── Check "
# Expected: 47

# 3. Test-fixtures manifest verify:
bash test-fixtures/build.sh --verify
# Expected: manifest matches all per-commit regenerations.

# 4. Per-check tests pass (4 new + all existing):
bash scripts/tests/test-validate-pack-check-NN.sh
bash scripts/tests/test-validate-pack-check-NN+1.sh
bash scripts/tests/test-validate-pack-check-NN+2.sh
bash scripts/tests/test-validate-pack-check-NN+3.sh
bash scripts/tests/test-validate-pack-check-42.sh  # workflow wiring (14 tests now)
bash scripts/tests/test-validate-pack-check-43.sh  # leak-sweep prevention
# Expected exit code 0 for each

# 5. Phase-part lib test (from H.5):
bash scripts/tests/test-tracker-phase-part.sh
# Expected exit code 0

# 6. Template version test (extended in H.15):
bash scripts/tests/template-version-test.sh
# Expected exit code 0 (phase-part-v11.1 admitted)

# 7. Per-entry sort test (extended in H.15):
bash scripts/tests/test-per-entry.sh
# Expected exit code 0 (new sort-order fixture verified)

# 8. Issue-forms test (extended at H.2 ENCODING lock-step):
bash scripts/tests/test-issue-forms.sh
# Expected exit code 0 (project-template surface admits 4 wi-type
# options including phase-part-skeleton; pack-root unchanged at {bd};
# DISJOINT invariant holds)

# 9. BD-185 status:
grep -A3 "^\*\*BD-185" pack-ops/BACKLOG.md
# Expected: Status: Resolved; Resolved: <date + close commit SHA + summary>

# 10. v11.1 archive layout:
ls maintenance-docs/v11-research/templates-archive/v11.1/
# Expected: phase-part-v11.1/ forms/ INDEX.md

# 11. v11.0 archive structure unchanged (D16 structural shape frozen):
ls maintenance-docs/v11-research/templates-archive/v11.0/
# Expected: bd-v11.0 forms INDEX.md inbound-v11.0 phase-epic-v11.0
#           phase-task-v11.0 td-v11.0

# 12. v11.0/INDEX.md carries forward-reference footnote (per H.14):
grep -nE "v11.1|phase-part-v11.1|D16" maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md
# Expected: matches (the new forward-reference footnote)

# 13. v11.1/forms/work-item.yml byte-identical to project-template-side
#     (per POQ-NEW-1 Option c, NOT pack-root):
diff maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml \
     project-template/.github/ISSUE_TEMPLATE/work-item.yml
# Expected: empty

# 14. NO byte-identity assertions on HELP-FRAGMENT-TRACKER pair
#     (per POQ-NEW-2 + BD-194 Check 24 retirement):
# (No `diff` command between pack-side and project-side HELP-FRAGMENT-TRACKER.md
#  is part of the verification gate; coincidental byte-identity today
#  is NOT a contract.)

# 15. Token-economy compliance sweep at batch close:
for f in supporting-docs/METHODOLOGY.md \
         project-template/docs/pack/PM-CHAT.md \
         project-template/docs/pack/HELP-FRAGMENT.md \
         project-template/docs/pack/HELP-FRAGMENT-TRACKER.md \
         project-template/docs/project/implementation-plan/_rules.md \
         project-template/docs/project/implementation-plan/_intro.md \
         pack-ops/HELP-FRAGMENT-PACK.md \
         pack-ops/HELP-FRAGMENT-TRACKER.md; do
  echo "=== $f ==="
  git diff 2648bb2 HEAD -- "$f" 2>&1 | grep -nE "^\+.*(BD-[0-9]+|ARCHITECTURE-BD-|PLAN-BD-|IMPLEMENTATION-REPORT-BD-|PACK-REVIEW-BD-)" || true
done
# Expected: NO new BD-NNN / architect-doc / pack-history refs in any
# client-installed surface (per token-economy compliance).
# Note: supporting-docs/MIGRATION-v10-to-v11.md may carry LEGITIMATE
# migration-mechanism cites per BD-193 §6.3 user resolution; reviewer
# distinguishes Class A (legitimate) from Class B (WASTE).

# 16. BD-193 F2.a non-regression at batch close:
git diff 2648bb2 HEAD -- maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md 2>&1 | grep -nE "^\+.*BD-NNN" || true
# Expected: NO new `BD-NNN` re-added to dep grammar at L79/L91.

# 17. ENCODING-surface lock-step at batch close (H.2 surfaces):
grep -c "phase-part-skeleton" \
     project-template/.github/ISSUE_TEMPLATE/work-item.yml \
     scripts/validate-pack.py \
     scripts/tests/test-issue-forms.sh
# Expected: each ≥1 (form / validator / test all encode the option)

# 18. ENCODING-surface lock-step at batch close (H.10 surfaces):
ls scripts/tests/test-validate-pack-check-{44,45,46,47}.sh 2>&1
grep -c "test-validate-pack-check-44\|test-validate-pack-check-45\|test-validate-pack-check-46\|test-validate-pack-check-47" .github/workflows/validate-pack.yml
# Expected: 4 files exist; 4 workflow invocations
# (Numbers 44-47 per POQ-A2 planner-recommendation sequential-from-max;
# adjust if user authorized alternative in §5.2)

# 19. CI run (manual trigger or auto on push):
gh run list --workflow validate-pack.yml --limit 1
# Expected: latest run conclusion = success

# 20. Filename uniqueness preserved:
find . -name "tracker-phase-part.sh" -not -path "./.git/*" | wc -l
# Expected: 1
find . -name "pack-phase.sh" -not -path "./.git/*" | wc -l
# Expected: 1
find . -name "_order.md" -not -path "./.git/*" | wc -l
# Expected: ≥1 (per-entry view file in implementation-plan tree post-H.7)
find . -name "_order-generate.sh" -not -path "./.git/*" | wc -l
# Expected: 1 (new script from H.7)
```

`pack-ops/CHANGELOG.md` may receive a v11.1 cut entry at version-boundary
close per Pack Chat protocol; not necessarily in H.16 itself (per
original plan §7).

---

## §8 — Cross-references

### §8.1 — Architect documents

- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md` —
  original architect pass (1233 lines; 16 USER-LOCKED decisions
  D1-D16; D1 + D16 NEEDS-ADJUSTMENT per reconciliation §3).
- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185-RECONCILIATION.md`
  — reconciliation architect pass (1590 lines; D-N + H-N verdicts +
  POQ-NEW-1..3; 2026-05-27).
- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-193.md` —
  Code Red 2 scope cleanup architect.
- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-194.md` —
  Check 24 retirement architect (Candidate 6).

### §8.2 — Plan documents

- `maintenance-docs/v11-implementation/PLAN-BD-185.md` — original
  16-commit plan (1424 lines; 2026-05-26; HEAD `062cb8f`). This
  addendum SUPPLEMENTS (does not replace).
- `maintenance-docs/v11-implementation/PLAN-BD-194.md` — BD-194 plan.

### §8.3 — Implementation reports (input baseline)

- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.1.md`
  — H.1 coder pass (committed at `8b4c607`).
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-H.1-NITS.md`
  — H.1 NIT cleanup (committed at `2648bb2`).
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-193.md`
  — BD-193 Phase 3.
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-193-PHASE-5.md`
  — BD-193 Phase 5.
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-194.md`
  — BD-194 coder pass.
- `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-194-FOLLOWUP.md`
  — BD-194 follow-up.

### §8.4 — Pack memory anchors (authoritative rules applied)

All visible in `CLAUDE.md` § "Pack memory" at HEAD `e128a2c`:

| Rule | Authoritative for |
|---|---|
| `feedback_bd_pack_only_operational_rule` (user-locked 2026-05-26) | §2.1 D1 per-surface defense; §4.13 H.13 dep-grammar regression check; H.16 reviewer focus item 3 |
| `feedback_pack_project_separation_of_concerns` (user-locked 2026-05-26) | §2.1 D1 reframing; §4.2 H.2 PROJECT-TEMPLATE-ONLY framing; §4.12 H.12 per-surface same-content edits; §5.1 POQ-NEW-1; §5.2 POQ-NEW-2; H.16 reviewer focus item 2 |
| `feedback_client_facing_token_economy` (user-locked 2026-05-26) | §4.11 H.11 token-economy compliance; §4.12 H.12 MIGRATION-v10-to-v11.md edits; §4.13 H.13 PM-CHAT.md edits; H.16 reviewer focus item 1 |
| `feedback_enumerate_encoding_surfaces_in_audits` (user-locked 2026-05-27 at `e128a2c`; "MF1 fix") | §4.10 H.10 (e) ENCODING-surface rule reference; §6 lock-step coordination map (all 4 sub-sections); H.16 reviewer focus item 4 |
| `feedback_pack_coder_preflight_pattern` (updated `ba9e09d` with per-check test runs gate) | §5.1 POQ-A1 (PREFLIGHT cannot pass with FAILED validate-pack); per-H.X PREFLIGHT line shapes |
| `feedback_planner_user_review_before_coder` | §7 final verification gates; addendum surfaced for user review before H.2 coder spawn |
| `feedback_decision_presentation_protocol` (extended 2026-05-25) | §5.1 POQ-A1 ("no evidence → no recommendation"); §5.2 POQ-A2 evidence-based recommendation; §5.3 POQ-A3 planner default with user-override path |
| `feedback_preliminary_triage_architect_challenge` | underlying methodology for the reconciliation architect pass that produced the 10 decisions consumed here |
| `feedback_no_solutions_in_agent_prompts` | §1.3 scope exclusion (no design re-litigation); §5 POQs surfaced for user, not auto-resolved |
| `feedback_tracker_portability` | original plan §5 H.4 D9 still applies (Forgejo/Gitea v11.1+ forward-pointer preserved) |
| `feedback_deferral_is_scope_creep` | no addendum-induced deferrals (all 10 user-locked decisions land in v11.0 BD-185 via the 8 supplemented H.X steps) |

### §8.5 — BD entries

- BD-185 entry: `pack-ops/BACKLOG.md` lines 1746-1793. Status: Open.
  Position: Batch 19d. This addendum supplements the open BD-185
  16-commit plan; BD-185 closes per H.16 status flip.
- BD-193 entry: `pack-ops/BACKLOG.md` lines 3015-3072. Resolved per
  Phase 5 close. Architectural-baseline input only.
- BD-194 entry: `pack-ops/BACKLOG.md` lines 3076-3124. Resolved per
  follow-up close. Architectural-baseline input only.

### §8.6 — Per-stream contract docs

- `/backlog/_rules.md` — backlog stream contract (read at addendum
  authoring time per spawn-prompt directive).
- `/changelog/_rules.md` — changelog stream contract.
- `README.md` § Repository Layout — authoritative repo structure
  reference.

### §8.7 — Working-tree HEAD state evidence (at addendum authoring)

- HEAD SHA `e128a2c`
  (`docs: v11 — pack memory: ENCODING-surface enumeration rule (PM-only)`).
- Pack-root `.github/ISSUE_TEMPLATE/work-item.yml`: 1 wi-type option
  (`{bd}`) post-b4906d1.
- Project-template `.github/ISSUE_TEMPLATE/work-item.yml`: 3 wi-type
  options (`{td, phase-epic-skeleton, phase-task-skeleton}`); L18
  boundary defense present.
- `pack-ops/HELP-FRAGMENT-TRACKER.md`: 49 lines.
- `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`: 49 lines.
  Coincidentally byte-identical to pack-side TODAY per BD-194.
- `scripts/validate-pack.py`: Check 24 retired; per-surface dict at
  L1117 carries `pack-root: {bd}` + `project-template: {td,
  phase-epic-skeleton, phase-task-skeleton}`.
- `scripts/tests/test-issue-forms.sh`: 269 lines; surface-aware
  assertions post-b4906d1 F3 cleanup.
- `maintenance-docs/v11-research/templates-archive/v11.0/`: 5
  entry-type subdirs + `forms/` + `INDEX.md` (with F2.c carve-out
  cite at L31).
- `maintenance-docs/v11-research/templates-archive/v11.1/`: 1
  entry-type subdir (`phase-part-v11.1`) + `INDEX.md` (declares 6
  entry types; "Forms file" L53 says "Not yet created" — H.2 fills).
  NO `forms/work-item.yml` yet.
- `maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md`:
  no BD-NNN dep grammar at L79/L91 (post-F2.a); `cancelled` state
  NOT YET admitted (H.13 pending).
- `find . -name "tracker-phase-part.sh" -not -path "./.git/*"` — 0
  matches.
- `find . -name "pack-phase.sh" -not -path "./.git/*"` — 0 matches.
- `find . -name "_order.md" -not -path "./.git/*"` — 0 matches.
- `find . -name "_order-generate.sh" -not -path "./.git/*"` — 0 matches.
- Check count: 43 invocations / 40 unique invoked checks.
- `python3 scripts/validate-pack.py`: FAIL on Check 36 (commit
  `e128a2c` subject-claim violation; see §5 POQ-A1).

---

*End of PLAN-BD-185-ADDENDUM.*

