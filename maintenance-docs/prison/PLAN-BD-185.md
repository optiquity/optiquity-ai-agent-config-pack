# PLAN-BD-185 — per-commit task list (Batch 19d / BD-185)

**Author:** pack-planner
**Date:** 2026-05-25
**Branch:** v11-dev
**HEAD at plan time:** `062cb8ffe7b21efb7bb0987fac2ea93e0f3382c9`
**Architect input:** `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md` (1220 lines; 14 USER-LOCKED decisions D1-D14 per §1.4 Decision log).
**Supporting inputs:**
- `maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-PARTS-AND-ORDERING.md` (1051-line researcher fact base)
- `pack-ops/BACKLOG.md` BD-185 entry (lines 1746-1793)
- `maintenance-docs/v11-implementation/PLAN-CLEANUP-BATCH-19C.md` (format precedent)
- `maintenance-docs/v11-implementation/EXECUTION-PLAN-V11.0.md` (batch sequencing context)

**Status:** implementation-ready. Pack-coder consumes commit-by-commit; reviewer attaches per §4 reviewer column with (α-sliding) interpretation noted before §3.

---

## §1 — Scope

### §1.1 — BD-185 problem statements (verbatim, BACKLOG L1759-L1767)

- **P1.** Mid-work phase splits have no first-class tracker representation.
- **P2.** The hierarchy changes when parts are added (Phase N → Parts → Tasks), and existing task IDs must survive without renumbering.
- **P3.** Tracker-mode execution ordering has no native mechanism (issue numbers reflect creation order; blockers give partial order only; sub-issues give containment only; flat-file execution notes do not survive sync).
- **P4.** v10→v11 and flat-file→tracker migrations must absorb pre-existing whole-number phases without manual intervention, including ordering initialization.

### §1.2 — Success criteria (verbatim, BACKLOG L1771-L1779)

- **SC1.** At-creation phase splits produce multiple phases with new immutable numbers (both modes).
- **SC2.** Mid-work phase expansion to multi-part form preserves the phase number and all existing task IDs (both modes).
- **SC3.** Phase numbers and task IDs (N.M) are never renumbered; tracker entity IDs are inherently immutable.
- **SC4.** Execution ordering is expressible in both modes; tracker mode does not depend on a flat-file artifact and does not use GH Projects.
- **SC5.** STATUS.md remains a dashboard; does not become ordering SSOT.
- **SC6.** Tracker form-family supports parts and ordering with the smallest possible template_version delta consistent with BD-068.
- **SC7.** Bi-directional sync preserves part membership and execution order (forward + reverse).
- **SC8.** Pre-existing whole-number phases pass through v10→v11 and v11.0 flat→tracker without manual intervention; ordering initialized from current implementation order.

### §1.3 — 16 USER-LOCKED decisions (architect §1.4; FINAL — do not re-litigate)

| # | Decision | Architect cite |
|---|---|---|
| D1 | INV-7 5th `wi-type` option `phase-part-skeleton` ACCEPTED (defense documented) | §4.3 |
| D2 | Part collapse REJECTED as anti-pattern; no `pack phase collapse` verb in any release | §4.7 |
| D3 | Empty Parts at creation FORBIDDEN — every Part must have ≥1 task at creation | §4.7 |
| D4 | Mid-life re-parenting between Parts FORBIDDEN — supersede only via `pack task supersede` | §4.7, §4.8 |
| D5 | `cancelled` state ADDED to task taxonomy (7-state; ❌ marker) | §4.4a, §11 |
| D6 | Primary-source verification VERIFY-AT-IMPLEMENTATION-TIME (planner/coder, no extra researcher pass) | §5.1, §7 |
| D7 | `_order.md` separate per-entry file ACCEPTED + SSOT documentation + BD-189 forward-pointer | §5.3, §5.X |
| D8 | Execution-note prose parsing DEFAULTS to phase_number + structured warning + historical marker | §6.3 |
| D9 | Forgejo/Gitea fallback DESIGNED for v11.1+; DEFER `provider_sub_issue_reprioritize` v11.0 implementation | §5.2, §7 |
| D10 | gh CLI version-pin strategy uses `gh api graphql` routing (avoids version-pin) | §5.1 |
| D11 | NEW `tracker-phase-part.sh` library ACCEPTED (parallel to `tracker-phase-task.sh`) | §10.1, §14.2, §14.9 |
| D12 | `pack-id-v2` marker backfill LAZY — only Part-expanded tasks gain v2 marker | §4.1, §6.3 |
| D13 | Issue Fields name collision uses capability-detection + `Pack Execution Order` fallback name | §5.1 |
| D14 | Mid-development phase position appends to END of sub-issue priority order (GH default) | §5.2 |
| D15 | Task letter-suffix REMOVED; task numbering rule (Task-M integer-only; task number ≠ execution order; cross-refs strict) | §4.1, §4.1a (NEW), §4.7 |
| D16 | Convention Y: v11.0 archive structural shape frozen + intra-file additive extensions allowed | §10.1 |

### §1.4 — User-locked constraints (C-1..C-5; architect §1.3)

- **C-1.** Part-id grammar (refined by D15 2026-05-26): composite `Phase-N.Part-x.Task-M` (with-Part) / `Phase-N.Task-M` (null-Part); empty separator `Phase-N..Task-M` prohibited; Task-M integer-only (no letter suffix per D15).
- **C-2.** Issue Fields primary; sub-issue reprioritize fallback (v11.1+); flat-file `<!-- execution-order: NNN -->` marker.
- **C-3.** Groupings G-1 phases-only / G-2 ≥2 phases / G-3 BD-to-phase before grouping / G-4 architect judgment beyond G-1/2/3.
- **C-4.** Immutability invariants INV-1..INV-9 (architect §1.3 / inventory §9) LOCKED.
- **C-5.** Trinity rule + cross-CLI parity per `ARCHITECTURE-BD-182.md` §4.1 canonical reference table.

### §1.5 — Planner-pass scope

This document is the planner pass output: it converts the locked architect design at `ARCHITECTURE-BD-185.md` into ordered commits with per-commit success criteria. It does NOT re-design (14 D-decisions LOCKED); planner-level open questions surface in §5.

---

## §2 — Architect inputs read

The following authoritative inputs were read in full at HEAD `062cb8f` before drafting this plan:

| # | Path | Sections read | Purpose |
|---|---|---|---|
| 1 | `maintenance-docs/v11-implementation/ARCHITECTURE-BD-185.md` | §1-§15 | Primary design source; 14 D-decisions; §14 file-touch inventory |
| 2 | `pack-ops/BACKLOG.md` BD-185 entry (L1746-L1793) | Full entry | P1-P4, SC1-SC8, File/Symbol, Pipeline |
| 3 | `maintenance-docs/v11-implementation/PLAN-CLEANUP-BATCH-19C.md` | §0-§7 | Format precedent (per-commit structure, table shape, POQ pattern, sliding-window α reviewer notation) |
| 4 | `maintenance-docs/v11-research/TOUCH-POINT-INVENTORY-PARTS-AND-ORDERING.md` | §1-§13 (sampled) | Fact-base cross-reference where architect cites |
| 5 | `CLAUDE.md` Pack-repo rules § "Rules for agents working on this repo" + § "Pack memory" | Commit-subject scope-keyword convention, trinity rule, RC9 trigger, filename uniqueness, deferral rules | Planner discipline gates |
| 6 | `pack-ops/PACK-AGENTS.md` § "Agent permission rules" + § "PM-only files and directories" | PM-only file list | Scope-keyword designation correctness |

**HEAD verifications at planner-pass start:**
- `git rev-parse HEAD` = `062cb8ffe7b21efb7bb0987fac2ea93e0f3382c9` (matches input)
- `python3 scripts/validate-pack.py` = `PASSED — all checks clean` (43 checks)
- Filename uniqueness: `find . -name "{tracker-phase-part.sh,pack-phase.sh,phase-part-v11.1,_order.md}" -not -path "./.git/*"` returns ZERO matches (all new names architect proposes do not collide).
- `templates-archive/v11.0/` has 5 entry-type subdirs (bd, td, phase-epic, phase-task, inbound) + `forms/` + `INDEX.md`; `templates-archive/v11.1/` does NOT yet exist.
- Existing tracker-* lib files present at expected paths: `tracker-provider.sh`, `tracker-provider-gh.sh`, `tracker-phase-task.sh`, `tracker-sidecar.sh`, `tracker-labels.sh`, `tracker-links.sh`, `tracker-init.sh`, `tracker-doctor.sh`, `tracker-promote.sh`, `tracker-migrate-forward.sh`, `tracker-migrate-reverse.sh`, `tracker-mirror.sh`, `tracker-config.sh`, `tracker-errors.sh`, `tracker-cycle-check.sh`, `tracker-header-snapshot.sh`, `tracker-agent-read.sh`.
- Existing per-entry lib files: `scripts/lib/per-entry/_lib.sh`, `decompose.sh`, `mirror-generate.sh`, `toc-regenerate.sh`.
- Existing migrator subtree: `scripts/lib/migrate-v10-to-v11/apply.sh`, `decompose.sh`, `dry-run.sh`, `resume.sh`, `checkpoint.sh`, `gate-1-dry-run-summary.sh`, `gate-2-phase-a-verify.sh`, `gate-3-phase-b-verify.sh`.
- `pack-ops/HELP-FRAGMENT-PACK.md` + `pack-ops/HELP-FRAGMENT-TRACKER.md` present at pack-root; client-side mirrors at `project-template/docs/pack/HELP-FRAGMENT.md` + `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md`.

---

## §3 — How to use this plan

1. Each `H.N` section below is self-contained — a fresh pack-coder reading the section + the cited architect §N text can execute the commit mechanically.
2. **RC9 manifest regen** per BD-176 4-directory v11-surface trigger (`project-template/`, `scripts/`, `pack-ops/`, `supporting-docs/`). Every applicable commit lists the exact regen step. Coder runs `bash test-fixtures/build.sh --all --clean` and stages `test-fixtures/manifest.txt` alongside scope edits when manifest diff is non-empty.
3. **Per-commit reviewer designation** uses (α-sliding) interpretation from PLAN-CLEANUP-BATCH-19C precedent — each INLINE reviewer's scope is the diff from the prior INLINE commit through end of its own commit. SKIP commits are covered by the next INLINE reviewer's sliding window — they are not unreviewed.
4. **(α-sliding) sliding-window mapping summary (BD-185):**
   - H.1 covers H.1 (foundational schema; first INLINE)
   - H.2 (form-family) SKIP → covered by H.4
   - H.3 (per-entry contract) SKIP → covered by H.4
   - H.4 covers H.2+H.3+H.4 (provider abstraction extension)
   - H.5 covers H.5 alone (tracker-phase-part.sh CREATE — new library; boundary-sensitive)
   - H.6 (tracker-* lib extensions) SKIP → covered by H.7
   - H.7 covers H.6+H.7 (per-entry sort key + mirror-generate)
   - H.8 covers H.8 alone (migrators — both forward and reverse; SC7+SC8 critical)
   - H.9 covers H.9 alone (new pack verbs — user-facing CLI surface)
   - H.10 (validate-pack.py + per-check tests) SKIP → covered by H.11
   - H.11 covers H.10+H.11 (METHODOLOGY.md substantive doc edits)
   - H.12 (MIGRATION + HELP-FRAGMENT pair) SKIP → covered by H.13
   - H.13 covers H.12+H.13 (PM-CHAT.md workflow + template archive v11.0 SCHEMA extension for D5 `cancelled`)
   - H.14 covers H.14 alone (template archive v11.0 SCHEMA `cancelled` + remaining v11.1 archive INDEX cross-references)
   - H.15 covers H.15 alone (test infra: template-version-test, tracker-init-test, test-per-entry sort fixture)
   - H.16 END-OF-BATCH backstop over full H.1→H.15 diff
5. **Commit-subject scope keyword (CI Check 36):** designated per commit. Per `CLAUDE.md` § "Rules for agents working on this repo" → commit-subject scope-keyword convention: `pack-only` denies `project-template/` and `supporting-docs/`; `project-only` denies pack-only paths; `PM-only` permits per `PACK-AGENTS.md` § "PM-only files and directories" Files list; mixed-scope commits MUST NOT carry an exclusive scope keyword.

   **Note on `scripts/-primary` (per POQ-3 resolution 2026-05-26):** `scripts/-primary` in this PLAN refers to pack-root `/scripts/` only (NOT `/project-template/scripts/`). The `pack-only` scope-keyword's deny-list (project-template/ + supporting-docs/) actively guardrails this separation — any accidental touch of `/project-template/scripts/` would fail CI Check 36 under a `pack-only` claim, surfacing the boundary violation at gate time.
6. **Validation contract:** at each commit head, `python3 scripts/validate-pack.py` exits 0. Per-check tests run where applicable.
7. **NO git state changes by any agent** (read-only verbs only). Pack Chat stages + commits with user approval.
8. **No solutions in agent prompts.** Per-commit success criteria become downstream pack-coder prompt's success criteria; planner does NOT propose implementation.

---

## §4 — Per-commit summary table (planner lookup)

| Commit | Scope summary | Primary files | RC9 fires? | Per-commit reviewer | Scope keyword | Commit msg |
|---|---|---|---|---|---|---|
| H.0 | Baseline verification (no commit) | n/a | n/a | n/a | n/a | (none) |
| H.1 | v11.1 templates-archive cut: phase-part-v11.1/SCHEMA.md + INDEX.md CREATE (forms/work-item.yml deferred to H.2 per POQ-1 resolution 2026-05-26) | maintenance-docs/v11-research/templates-archive/v11.1/{phase-part-v11.1/SCHEMA.md, INDEX.md} | NO (maintenance-docs/ NOT in v11-surface) | **INLINE (H.1 alone — schema foundation)** | `pack-only` (per POQ-2 resolution 2026-05-26; precedent: 3a8b5ba + 062cb8f maintenance-docs/-only commits used pack-only and CI passed) | `feat: v11 — BD-185 v11.1 templates-archive cut (phase-part-v11.1 schema + INDEX) (Batch 19d.1) (pack-only)` |
| H.2 | Form-family extension: pack-root + client-template work-item.yml; 5th wi-type option `phase-part-skeleton` + `wi-part-letter` input; v11.1 archive forms/work-item.yml CREATE (byte-identical from H.2 per POQ-1 resolution 2026-05-26) | .github/ISSUE_TEMPLATE/work-item.yml + project-template/.github/ISSUE_TEMPLATE/work-item.yml + maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml | YES (`project-template/` touched) | covered by H.4 | (mixed — pack-root + project-template/ + maintenance-docs/) | `feat: v11 — BD-185 work-item.yml form-family extension (5th wi-type + part-letter input) (Batch 19d.2)` |
| H.3 | Per-entry tree contract: `_rules.md` + `_intro.md` updates (body marker quad, H3 Part grammar, execution-order marker, reorder workflow) | project-template/docs/project/implementation-plan/{_rules.md, _intro.md} | YES (`project-template/` touched) | covered by H.4 | `project-only` (per-entry tree files are project-side) | `feat: v11 — BD-185 implementation-plan per-entry contract (body marker quad + Part H3 + execution-order) (Batch 19d.3)` |
| H.4 | TrackerProvider abstraction: 3 new ops (`_set_field`, `_get_field`, `_sub_issue_reprioritize`); GH backend implementations; capability flags | scripts/lib/tracker-provider.sh + scripts/lib/tracker-provider-gh.sh | YES (`scripts/` touched) | **INLINE (sliding from H.1: H.2+H.3+H.4)** | `pack-only` (scripts/lib only) | `feat: v11 — BD-185 TrackerProvider 3 new ops + GH backend + capability flags (Batch 19d.4)` |
| H.5 | NEW `scripts/lib/tracker-phase-part.sh` library + parallel test file (D11) | scripts/lib/tracker-phase-part.sh + scripts/tests/test-tracker-phase-part.sh | YES (`scripts/` touched) | **INLINE (H.5 alone — new library; boundary-sensitive)** | `pack-only` | `feat: v11 — BD-185 tracker-phase-part.sh library (D11; parallel to tracker-phase-task.sh) (Batch 19d.5)` |
| H.6 | tracker-* lib extensions: tracker-phase-task.sh, tracker-labels.sh, tracker-links.sh, tracker-sidecar.sh, tracker-init.sh, tracker-doctor.sh, tracker-promote.sh; id-map.json + sidecar.yaml additive shape; phase-order-root provisioning | scripts/lib/tracker-{phase-task, labels, links, sidecar, init, doctor, promote}.sh | YES (`scripts/` touched) | covered by H.7 | `pack-only` | `feat: v11 — BD-185 tracker-* lib extensions (Part admission + execution-order plumbing + id-map/sidecar schema) (Batch 19d.6)` |
| H.7 | per-entry sort key + mirror-generate; NEW `_order-generate.sh` script (per POQ-5 resolution 2026-05-26; parallel to `toc-regenerate.sh`); NEW `test-_order-generate.sh` test | scripts/lib/per-entry/{_lib.sh, mirror-generate.sh, _order-generate.sh (NEW)} + scripts/tests/test-_order-generate.sh (NEW) | YES (`scripts/` touched) | **INLINE (sliding from H.5: H.6+H.7)** | `pack-only` | `feat: v11 — BD-185 per-entry sort by execution-order + _order-generate.sh + _order.md view (D7) (Batch 19d.7)` |
| H.8 | Migrators: tracker-migrate-forward.sh + tracker-migrate-reverse.sh; migrate-v10-to-v11/decompose.sh + apply.sh; execution-note structured warning template (§6.3a; D8) | scripts/lib/tracker-migrate-{forward, reverse}.sh + scripts/lib/migrate-v10-to-v11/{decompose, apply}.sh | YES (`scripts/` touched) | **INLINE (H.8 alone — bi-directional sync; SC7+SC8 critical)** | `pack-only` | `feat: v11 — BD-185 migrators forward+reverse + execution-note structured warning (SC7+SC8) (Batch 19d.8)` |
| H.9 | New pack verbs: scripts/pack-phase.sh CREATE (`pack phase split` + `pack phase reorder`); scripts/pack-tracker.sh EXTEND (`pack tracker phase split` + `pack tracker phase reorder`); scripts/pack-td.sh EXTEND (`pack task supersede` per D4 §4.8) | scripts/pack-phase.sh + scripts/pack-tracker.sh + scripts/pack-td.sh (or scripts/pack-task.sh if separate verb file convention) | YES (`scripts/` touched) | **INLINE (H.9 alone — user-facing CLI surface)** | `pack-only` | `feat: v11 — BD-185 new pack verbs (phase split/reorder + task supersede) (Batch 19d.9)` |
| H.10 | validate-pack.py extensions (Check 32/33/34/35) + 4 NEW checks (phase-part-schema-v11.1, execution-order-marker, part-re-parentage, part-has-member-task per §10.2); CI workflow wiring | scripts/validate-pack.py + scripts/tests/test-validate-pack-check-{N..N+3}.sh + .github/workflows/validate-pack.yml | YES (`scripts/` touched) | covered by H.11 | (mixed — `scripts/` + `.github/workflows/`) | `feat: v11 — BD-185 validate-pack extensions + 4 new checks (Part schema, exec-order marker, Part re-parentage, Part membership) (Batch 19d.10)` |
| H.11 | METHODOLOGY.md substantive doc edits: Part 4 Multi-part phases (tracker rep, Part state taxonomy, programmatic creation, D3/D4 rules); Phase numbering rules (execution-order ref); supersede verb canonical; execution-note-status historical marker; D2 no-collapse rule | supporting-docs/METHODOLOGY.md | YES (`supporting-docs/` touched) | **INLINE (sliding from H.9: H.10+H.11)** | (mixed — supporting-docs/ only; no PM-only scope match) | `feat: v11 — BD-185 METHODOLOGY.md Multi-part + execution-order + supersede + historical-marker (Batch 19d.11)` |
| H.12 | MIGRATION-v10-to-v11.md edits (Per-entry decomposition + NEW Phase B Part materialization) + HELP-FRAGMENT-PACK + HELP-FRAGMENT-TRACKER (pack-ops + project-template mirrors) | supporting-docs/MIGRATION-v10-to-v11.md + pack-ops/HELP-FRAGMENT-PACK.md + project-template/docs/pack/HELP-FRAGMENT.md + pack-ops/HELP-FRAGMENT-TRACKER.md + project-template/docs/pack/HELP-FRAGMENT-TRACKER.md | YES (supporting-docs/ + pack-ops/ + project-template/ all touched) | covered by H.13 | (mixed) | `feat: v11 — BD-185 MIGRATION + HELP-FRAGMENT (pack + tracker; pack-ops + client mirror) (Batch 19d.12)` |
| H.13 | PM-CHAT.md workflow text for pack phase split + extension of D5 task taxonomy in v11.0 phase-task-v11.0 SCHEMA (status enum adds `cancelled`); execution-note-status marker added | project-template/docs/pack/PM-CHAT.md + maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md | YES (`project-template/` touched; maintenance-docs/ does not trigger RC9 alone but accompanying project-template/ does) | **INLINE (sliding from H.11: H.12+H.13)** | (mixed — project-template/ + maintenance-docs/) | `feat: v11 — BD-185 PM-CHAT workflow + phase-task-v11.0 SCHEMA cancelled-state extension (D5) (Batch 19d.13)` |
| H.14 | Cross-reference closure: v11.1 INDEX.md cross-references; v11.0/INDEX.md forward-reference footnote per POQ-6 + D16 Convention Y (intra-file additive extension permitted under v11.0 structural-shape-frozen contract) | maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md + maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md | NO (maintenance-docs/ alone — no RC9 trigger directories) | **INLINE (H.14 alone — archive cross-reference closure)** | `pack-only` (per POQ-2 resolution 2026-05-26; same condition as H.1) | `feat: v11 — BD-185 templates-archive cross-references (v11.0 ↔ v11.1) (Batch 19d.14) (pack-only)` |
| H.15 | Test infrastructure: template-version-test (add phase-part-v11.1), tracker-init-test (label provisioning for new template_version), test-per-entry sort-order fixture | scripts/tests/{template-version-test.sh, tracker-init-test.sh, test-per-entry.sh} + scripts/tests/fixtures/per-entry-split/ new fixture subdir | YES (`scripts/` touched) | **INLINE (H.15 alone — test surface)** | `pack-only` | `feat: v11 — BD-185 test infra (template-version, tracker-init labels, per-entry sort fixture) (Batch 19d.15)` |
| H.16 | End-of-batch reviewer + BD-185 status flip (combined fix+flip OR standalone flip) | (varies) | conditional | END-OF-BATCH | mixed or `PM-only` | `fix: v11 — BD-185 broad batch review/fix + status flip (Batch 19d)` OR `docs: v11 — flip BD-185 to Resolved` |

**Total commits:** 15 implementation (H.1-H.15) + 1 close (H.16) = **16 commits**.

**Per-commit reviewer breakdown:** 9 INLINE sliding-window passes (H.1 covers H.1; H.4 covers H.2+H.3+H.4; H.5 covers H.5; H.7 covers H.6+H.7; H.8 covers H.8; H.9 covers H.9; H.11 covers H.10+H.11; H.13 covers H.12+H.13; H.14 covers H.14; H.15 covers H.15) / 5 SKIP-per-commit but covered by sliding window (H.2, H.3 → H.4; H.6 → H.7; H.10 → H.11; H.12 → H.13) / 1 END-OF-BATCH (H.16 backstop). Every implementation commit is reviewed at least once before H.16.

**RC9 manifest regen attachment:** 12 of 15 implementation commits fire RC9 (all except H.1, H.14: maintenance-docs/ only commits do not trigger RC9 per BD-176 4-directory rule). Per BD-176: false positives produce no incorrect manifest change. Every commit's verification step includes `bash test-fixtures/build.sh --all --clean` AND `git diff --stat test-fixtures/manifest.txt`; coder stages manifest only when non-empty diff.

---

## §5 — Per-commit detail

Each H.N below carries: scope summary | files modified | edit specification | verification commands | RC9 manifest-regen attachment | per-commit reviewer scope | commit subject scope-keyword | commit message | ordering dependency | success criteria.

### H.0 — Baseline verification

**Coder actions** (read-only; no edits):

1. Verify HEAD: `git rev-parse HEAD` should match the plan's recorded HEAD `062cb8f` or a descendant. If HEAD advanced, planner re-verifies any new commits did not invalidate references before H.1 begins.
2. Verify working tree clean: `git status` — no uncommitted edits except plan output (`PLAN-BD-185.md`).
3. Verify validate-pack baseline: `python3 scripts/validate-pack.py` — record PASS status (43 checks).
4. Verify BD-185 status: `grep -A2 "BD-185" pack-ops/BACKLOG.md | head -5` confirms `Status: Open`.
5. Verify filename uniqueness for proposed new files: `find . -name "tracker-phase-part.sh" -not -path "./.git/*"` etc. — should return ZERO matches for `tracker-phase-part.sh`, `pack-phase.sh`, `phase-part-v11.1`, `_order.md` at H.0.

**Output:** no commit. H.0 is a pre-flight checklist for the coder's PREFLIGHT line at H.1.

**Per-commit reviewer:** n/a (no commit).

**RC9 manifest regen:** n/a.

**Ordering dependency:** none (baseline).

---

### H.1 — v11.1 templates-archive cut (NEW phase-part-v11.1 + INDEX; forms deferred to H.2 per POQ-1 resolution 2026-05-26)

**Scope:** Per architect §4.3 + §14.1. Create v11.1 templates-archive subtree as the schema foundation for all downstream BD-185 work. v11.0 archive remains frozen at 5 entry-type subdirs; v11.1 declares 6 (adds `phase-part-v11.1`).

**Files modified (2 CREATE):**
- `maintenance-docs/v11-research/templates-archive/v11.1/phase-part-v11.1/SCHEMA.md` (NEW)
- `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md` (NEW)

(Per POQ-1 resolution 2026-05-26: v11.1/forms/work-item.yml creation deferred to H.2, where it lands byte-identically with the live form. H.1 creates only SCHEMA + INDEX in the v11.1 archive.)

**Edit specification:**

1. **SCHEMA.md** declares per architect §4.3 + §11.1:
   - Identifier scheme: `Phase-N.Part-x` (per C-1 grammar)
   - Body marker trio: `<!-- pack-id: phase-N.Part-x -->`, `<!-- template_version: phase-part-v11.1 -->`, `<!-- pack-version: v11 -->`
   - Label family: no new namespace; `status:<pending|in-progress|done|deferred>` only (per §4.4)
   - State taxonomy: `pending / in-progress / done / deferred` (excludes merged-into / superseded-by per §4.4 lifecycle invariant)
   - Body section grammar (paralleling phase-task-v11.0): Goal / Prerequisite / sub-issue parent (always the phase epic) / member tasks
   - Body marker: optional `<!-- execution-note-status: historical -->` reserved (does not apply to Parts; cross-referenced for completeness)
2. **INDEX.md** declares the 6 entry-type subdirs (bd, td, phase-epic, phase-task, phase-part, inbound) + cross-reference to v11.0 archive (frozen).
3. **Archive forms file deferred to H.2** (per POQ-1 resolution 2026-05-26). H.1 creates only SCHEMA + INDEX in v11.1 archive. The `v11.1/forms/work-item.yml` archive file is created in H.2 as a byte-identical copy of the live form at H.2's commit point — eliminating the H.16-refresh placeholder pattern.

**Verification commands:**

```bash
python3 scripts/validate-pack.py
# Verify v11.1 archive directory layout:
ls maintenance-docs/v11-research/templates-archive/v11.1/
# Expected: phase-part-v11.1/ INDEX.md forms/
# (additional entry-type subdirs may or may not exist at H.1; phase-part-v11.1 is the only NEW directory introduced; per architect §4.3 the v11.0 entries are referenced from v11.1 INDEX but not duplicated as subdirs)
cat maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md | head -30
# Expected: 6 entry types enumerated; cross-reference to v11.0 archive.
```

**RC9 manifest regen:** NO. `maintenance-docs/` is NOT in the v11-surface 4-directory trigger (BD-176 rule: only `project-template/`, `scripts/`, `pack-ops/`, `supporting-docs/`). Coder confirms manifest diff empty after `bash test-fixtures/build.sh --all --clean`; if empty, no staging.

**Per-commit reviewer:** **INLINE (H.1 alone — schema foundation; first commit in the batch establishes the contract every downstream commit references).** Boundary-sensitive surface for reviewer focus:
- **SCHEMA correctness vs C-1 grammar.** Verify identifier scheme `Phase-N.Part-x` matches architect §4.1 atomic + composite forms; no empty-separator forms admitted.
- **Body marker trio parallels phase-epic-v11.0 + phase-task-v11.0.** Verify the trio includes `pack-id`, `template_version: phase-part-v11.1`, `pack-version: v11` per architect §4.3.
- **State taxonomy matches §4.4.** Verify `pending / in-progress / done / deferred` exactly; no extra states; merged-into / superseded-by EXCLUDED (architect §4.4 lifecycle invariant).
- **INDEX.md cross-reference completeness.** Verify cross-reference to v11.0 archive (frozen at 5 entry-types) is correct; v11.1 declares 6.
- **Filename uniqueness preserved.** Verify `tracker-phase-part.sh` is NOT introduced in this commit (that's H.5); `phase-part-v11.1/SCHEMA.md` is a new path under maintenance-docs/ with no collision risk (per H.0 baseline `find` check).

**Commit subject scope keyword:** `pack-only`. Per POQ-2 resolution 2026-05-26: `maintenance-docs/`-only commit; the `pack-only` keyword's deny-list (project-template/ + supporting-docs/) does not trip; precedent: commits `3a8b5ba` + `062cb8f` used `pack-only` for maintenance-docs/-only commits and CI passed.

**Commit message:** `feat: v11 — BD-185 v11.1 templates-archive cut (phase-part-v11.1 schema + INDEX) (Batch 19d.1) (pack-only)`

**Pack-coder PREFLIGHT line shape:** `PREFLIGHT: 2/2 in-scope file edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.1.md`

**Ordering dependency:** none (this IS the foundation; all downstream commits reference this commit's schema).

**Success criteria:**
1. v11.1/phase-part-v11.1/SCHEMA.md exists with C-1 grammar + body marker trio + state taxonomy per architect §4.3 + §4.4.
2. v11.1/INDEX.md declares 6 entry types with v11.0 cross-references.
3. v11.1/forms/work-item.yml NOT created at H.1 (deferred to H.2 per POQ-1 resolution 2026-05-26).
4. `python3 scripts/validate-pack.py` exits 0.
5. No collision with any existing file in repo (filename uniqueness preserved).

---

### H.2 — Form-family extension (5th wi-type option + wi-part-letter input)

**Scope:** Per architect §4.3 + §14.1. Extend pack-root + client-template `work-item.yml` Issue Form with `phase-part-skeleton` 5th wi-type option, `wi-part-letter` input field (conditional on `phase-part-skeleton`), and Blockers/Unblocks/Dependencies description extensions admitting Part-id forms.

**Files modified (2 EXTEND + 1 CREATE):**
- `.github/ISSUE_TEMPLATE/work-item.yml` (pack-root, EXTEND)
- `project-template/.github/ISSUE_TEMPLATE/work-item.yml` (client mirror, EXTEND; byte-identical to pack-root per existing convention)
- `maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml` (NEW; byte-identical to live form post-H.2 edits per POQ-1 resolution 2026-05-26 — archive created here, not at H.1)

**Edit specification:**

Per architect §4.3 form-field additions table:

1. **`wi-type` dropdown** (currently 4 options at L25-28 of pack-root work-item.yml): ADD `phase-part-skeleton` as the 5th option. Defense per §4.3: 5-option dropdown is acceptable because (i) consistent naming convention compensates for length, (ii) rare-case use (3 of 5 are fallback paths), (iii) no path forward without breach.
2. **`wi-phase-number` input** (existing): extend description to admit `phase-part-skeleton` audience: "Phase the Part belongs to. Use 'N'."
3. **`wi-part-letter` input** (NEW; conditional on `phase-part-skeleton`): "Part letter. Use 'a', 'b', 'c', etc. — next available letter under phase N." Insert per architect §4.3 form-field table.
4. **`wi-blockers` / `wi-unblocks` / `wi-dependencies` textareas** (existing): extend descriptions to admit `Phase-N.Part-x` and `Phase-N.Part-x.Task-M` forms per architect §4.1 grammar.
5. **Apply byte-identically** to `project-template/.github/ISSUE_TEMPLATE/work-item.yml` (client mirror).
6. **Create archive copy** at `maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml` byte-identical to the live forms emitted in steps 1-5 (per POQ-1 resolution 2026-05-26 — eliminates H.16-refresh placeholder pattern).

**Verification commands:**

```bash
python3 scripts/validate-pack.py
# Verify `check_issue_template_forms` PASSES — H.10 extends the expected wi-type options from 4 to 5; if Check 36/37/38 is sensitive to the form layout, the check may need H.10's update to land first; planner default is H.10 lands AFTER H.2 and resolves the check coverage at H.10's commit.
# Spot-check 5th wi-type option present:
grep -A4 "id: wi-type" .github/ISSUE_TEMPLATE/work-item.yml | grep "phase-part-skeleton"
grep -A4 "id: wi-type" project-template/.github/ISSUE_TEMPLATE/work-item.yml | grep "phase-part-skeleton"
# Expected: both grep commands match.
# Verify wi-part-letter field exists:
grep -nE "^[[:space:]]+id: wi-part-letter" .github/ISSUE_TEMPLATE/work-item.yml project-template/.github/ISSUE_TEMPLATE/work-item.yml
# Expected: both files have wi-part-letter.
# Verify pack-root and project-template/ work-item.yml are byte-identical:
diff .github/ISSUE_TEMPLATE/work-item.yml project-template/.github/ISSUE_TEMPLATE/work-item.yml
# Expected: empty (byte-identical).
# Verify v11.1 archive form byte-identical to live form (per POQ-1 resolution):
diff project-template/.github/ISSUE_TEMPLATE/work-item.yml \
     maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml
# Expected: empty (byte-identical from creation per POQ-1 resolution).
bash test-fixtures/build.sh --all --clean
git diff --stat test-fixtures/manifest.txt
```

**RC9 manifest regen:** REQUIRED. `project-template/` in v11-surface per BD-176. Stage `test-fixtures/manifest.txt` alongside scope edits.

**Per-commit reviewer:** SKIP (covered by H.4 sliding window: H.2+H.3+H.4). Boundary-sensitive surface deferred to H.4 reviewer scope:
- 5th wi-type option defense vs INV-7 4-option soft cap.
- wi-part-letter input correctness (conditional rendering, letter-only grammar per C-1).
- Blockers/Unblocks/Dependencies description extensions for Part-id grammar.

**Commit subject scope keyword:** (no keyword — mixed: pack-root `.github/` + `project-template/`). Per `CLAUDE.md` § "Rules for agents working on this repo": pack-root files (e.g., `.github/`) are not in the `pack-only` deny-list scope per CI Check 36, but the commit also touches `project-template/`, so the commit is genuinely cross-surface. Per `CLAUDE.md`: "If a batch's work genuinely spans pack + project, the commit subject MUST NOT carry an exclusive scope keyword".

**Commit message:** `feat: v11 — BD-185 work-item.yml form-family extension (5th wi-type + part-letter input) (Batch 19d.2)`

**Pack-coder PREFLIGHT line shape:** `PREFLIGHT: 3/3 in-scope file edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.2.md`

**Ordering dependency:** MUST land AFTER H.1 (the v11.1 phase-part-v11.1 SCHEMA names the new template_version that the form's 5th wi-type option emits to body markers).

**Success criteria:**
1. Both `.github/ISSUE_TEMPLATE/work-item.yml` (pack-root) and `project-template/.github/ISSUE_TEMPLATE/work-item.yml` carry the 5th wi-type option `phase-part-skeleton`.
2. `wi-part-letter` input field exists; conditional rendering for `phase-part-skeleton` only.
3. Blockers/Unblocks/Dependencies descriptions admit Part-id forms.
4. Pack-root, project-template/, and v11.1 archive copies of work-item.yml are byte-identical.
5. `maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml` exists (per POQ-1 resolution 2026-05-26).
6. `python3 scripts/validate-pack.py` exits 0. (`check_issue_template_forms` may need updating in H.10 — if a transient FAIL surfaces here, surface to user; planner default: H.10 extends the check.)
7. `test-fixtures/manifest.txt` regenerated and staged.

---

### H.3 — implementation-plan per-entry tree contract (body marker quad + H3 Part grammar + execution-order marker)

**Scope:** Per architect §11.4 + §11.5 + §14.7. Update the per-entry tree contract for the `implementation-plan` stream — admits body marker quad (back-pointer + pack-id + pack-id-v2 + execution-order), H3 Part sub-section grammar, H4 task headers under Parts, execution-order reorder workflow user guidance.

**Files modified (2 EXTEND):**
- `project-template/docs/project/implementation-plan/_rules.md`
- `project-template/docs/project/implementation-plan/_intro.md`

**Edit specification:**

1. **`_rules.md` entry contract:**
   - **Body marker quad documentation:** Add `<!-- pack-id-v2: Phase-N -->` and `<!-- execution-order: NNN -->` to the existing back-pointer + `<!-- pack-id: phase-N -->` pair. Document per architect §5.3 + §4.1 + §11.4.
   - **H3 sub-section grammar (multi-part phases):** "### Part a — [Subtitle]" / "### Part b — [Subtitle]" admitted as optional content AFTER the phase H2 heading and BEFORE `### Tasks`. For phases WITHOUT Parts, the H3 Part sub-sections are absent. Document INV-12 (single-Part-no-suffix asymmetry, per inventory §12.12) — phases have 0 Parts OR 2+ Parts; never 1.
   - **H4 task headers under Parts:** `#### Task M — <title>` (the legacy `#### N.M — <title>` form continues to resolve via the pack-id v1 marker per D12 LAZY backfill).
   - Phase-state vocabulary unchanged (pending / in-progress / done / deferred / merged-into / superseded-by per existing `_rules.md`).
   - Per architect §11.4 the phase-state vocabulary additionally admits `cancelled` per D5 §4.4a — verify the existing `_rules.md` state enumeration aligns with the phase-task-v11.0 SCHEMA extension landing in H.13. If H.13 lands first, this contract carries `cancelled`. If H.3 lands first, planner notes the addition as pending H.13 cross-reference closure.

2. **`_intro.md` user guidance:**
   - **NEW sub-section "Splitting a phase into Parts":** per architect §11.5 + §4.7. When to split (planner triggers — 5+ tasks, non-linear deps, second-failure); how to split (`pack phase split <phase-N> --parts N`); what changes (H3 sub-sections appear; task pack-ids gain v2 marker; tracker creates Part sub-issues if enabled). Mention D3 (≥1 task per Part at creation; reject empty Parts).
   - **NEW sub-section "Reordering phase execution":** per architect §11.5 + §5.5. Why (phase numbers immutable per INV-1; execution order can change as priorities shift); how (`pack phase reorder` flat-file mode; `pack tracker phase reorder` tracker mode).
   - **NEW sub-section "Supersede a task":** per architect §11.1 + §4.8 + D4. Why mid-life re-parenting is forbidden; canonical mid-life task-move via `pack task supersede`; old task's `status:superseded-by:Phase-N.Part-x.Task-M` marker.
   - **NEW sub-section "Execution-note historical marker (D8):"** per architect §6.3a. Setting `<!-- execution-note-status: historical -->` to suppress migration warnings on phases whose execution note has been superseded.

**Verification commands:**

```bash
python3 scripts/validate-pack.py
# Verify per-entry stream contract files render cleanly:
grep -nE "execution-order|pack-id-v2|Part-a|Part-b" project-template/docs/project/implementation-plan/_rules.md | head -20
grep -nE "Splitting a phase|Reordering phase|Supersede a task|execution-note historical" project-template/docs/project/implementation-plan/_intro.md | head -10
bash test-fixtures/build.sh --all --clean
git diff --stat test-fixtures/manifest.txt
```

**RC9 manifest regen:** REQUIRED. `project-template/` in v11-surface per BD-176.

**Per-commit reviewer:** SKIP (covered by H.4 sliding window). Boundary-sensitive surface deferred to H.4 reviewer:
- Body marker quad consistency with phase-epic-v11.0 + phase-task-v11.0 SCHEMAs.
- H3 / H4 grammar consistency with architect §11.4 + §4.6 (Parts INLINE; no per-Part per-entry file).
- User guidance contract: D2 no-collapse, D3 ≥1 task per Part, D4 supersede only, D8 historical marker.

**Commit subject scope keyword:** `project-only`. Per `CLAUDE.md` § "Rules for agents working on this repo": `project-only` denies pack-only paths (everything outside `project-template/` + `supporting-docs/`). Both files are under `project-template/`. The accompanying maintenance-docs/IMPL-REPORT and test-fixtures/manifest are NOT denied by `project-only` per the keyword's "Permitted touched paths" column (it denies "pack-only paths" which is "everything outside `project-template/` + `supporting-docs/`"). Maintenance-docs and test-fixtures are still pack-only paths under that definition. **Planner correction:** scope is genuinely mixed (project-template/ scope edit + maintenance-docs/IMPL-REPORT + test-fixtures/manifest). Use NO KEYWORD. See POQ-3 in §6 for scope-keyword guidance ambiguity around IMPL-REPORT + manifest co-staging.

**Commit message:** `feat: v11 — BD-185 implementation-plan per-entry contract (body marker quad + Part H3 + execution-order) (Batch 19d.3)`

**Pack-coder PREFLIGHT line shape:** `PREFLIGHT: 2/2 in-scope file edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.3.md`

**Ordering dependency:** MUST land AFTER H.1 (SCHEMA + grammar foundation). MAY land before or after H.2 (form-family) — no direct dependency. Planner default: land H.3 after H.2 to keep schema → form-family → per-entry contract sequence chronologically consistent with architect §14 ordering.

**Success criteria:**
1. `_rules.md` documents body marker quad + H3 Part grammar + H4 task header form + phase-state vocabulary (incl. cancelled per D5; cross-reference to H.13).
2. `_intro.md` carries user guidance for splitting / reordering / superseding / historical-marker workflows.
3. `python3 scripts/validate-pack.py` exits 0.
4. `test-fixtures/manifest.txt` regenerated and staged.

---

### H.4 — TrackerProvider abstraction extension (3 NEW ops + GH backend + capability flags)

**Scope:** Per architect §7 + §14.2. Extend the 18-op TrackerProvider abstraction with 3 new ops (`provider_set_field`, `provider_get_field`, `provider_sub_issue_reprioritize`) and implement them for the GitHub backend. Extend `provider_capabilities` with new flags. Per D9, `provider_sub_issue_reprioritize` is DESIGNED in v11.0 but its Forgejo/Gitea implementation defers to v11.1+ — the v11.0 surface ships the dispatcher + GH-stub.

**Files modified (2 EXTEND):**
- `scripts/lib/tracker-provider.sh` (dispatcher: 18 → 20 ops + raw; reserved 21st op for `_sub_issue_reprioritize`)
- `scripts/lib/tracker-provider-gh.sh` (GH backend: implement `_set_field` + `_get_field` via `gh api graphql` per D10; stub `_sub_issue_reprioritize` for v11.1+)

**Edit specification:**

Per architect §7:

1. **`tracker-provider.sh` dispatcher extension:**
   - Add `provider_set_field <issue-id> <field-name> <value>` (NEW op signature)
   - Add `provider_get_field <issue-id> <field-name>` (NEW op signature)
   - Add `provider_sub_issue_reprioritize <parent-id> <child-id> [--after <sibling-id>]` (NEW op signature; v11.0 ships dispatcher entry; backend implementation v11.1+ per D9)
   - Update `provider_capabilities` return shape: add `execution_order.mechanism = "issue_fields" | "sub_issue_reprioritize" | "none"`; add `parts.supported = true | false`.
2. **`tracker-provider-gh.sh` GH backend:**
   - Implement `_set_field` via `gh api graphql` with `updateIssueField` mutation (primary-source verification at implementation-time per D6 — coder verifies the actual GraphQL mutation name).
   - Implement `_get_field` via `gh api graphql` field-read query.
   - Stub `_sub_issue_reprioritize` returning a "not implemented in v11.0" error path; verbose error names D9 deferral; surface in `provider_capabilities` flag.
   - Implement capability-detection at `provider_capabilities` time: check whether `Execution Order` field exists at the org (via GraphQL query); fall back to `Pack Execution Order` name per D13. Persist field-name choice to `tracker.toml` under new `[execution_order]` section.
   - Use `gh api graphql` exclusively for Issue Fields ops per D10 (avoids `gh` CLI version-pinning).

**Verification commands:**

```bash
python3 scripts/validate-pack.py
# Verify dispatcher exports 20 ops + raw:
bash scripts/lib/tracker-provider.sh --dispatch-list 2>/dev/null || grep -E "^provider_" scripts/lib/tracker-provider.sh | wc -l
# Expected: ≥20 ops (note: existing op count baseline is 18 + raw per inventory §8.1; new ops bring count to 20 — and `_sub_issue_reprioritize` design slot present per D9 deferral).
# Per-op smoke (if test infra in place):
bash scripts/tests/test-tracker-provider.sh 2>&1 || true  # may not exist; coder verifies
bash test-fixtures/build.sh --all --clean
git diff --stat test-fixtures/manifest.txt
```

**RC9 manifest regen:** REQUIRED. `scripts/` in v11-surface per BD-176.

**Per-commit reviewer:** **INLINE — sliding-window scope per (α-sliding).** Covers the diff from H.0 baseline through this commit's HEAD: H.2 + H.3 + H.4 (3 commits; H.1 was schema-only no RC9). Reviewer's scope explicitly includes the H.2 form-family extension + H.3 per-entry contract + this commit's provider abstraction. Boundary-sensitive surface for reviewer focus:
- **5th wi-type defense (H.2 carry-forward).** Verify defense documented per architect §4.3 + INV-7 breach justification.
- **wi-part-letter input correctness (H.2 carry-forward).** Verify letter-only grammar per C-1.
- **Per-entry _rules.md / _intro.md contract fidelity (H.3 carry-forward).** Verify body marker quad consistent with H.1 SCHEMA; Part H3 grammar consistent with §4.6 Parts-INLINE decision; D3 / D4 user guidance present.
- **Provider 18 → 20 ops dispatcher correctness.** Verify op signatures match architect §7 table. v11.0 ships `_set_field` + `_get_field` fully; `_sub_issue_reprioritize` v11.0 ships dispatcher stub + D9 deferral message.
- **GH backend GraphQL routing per D10.** Verify `gh api graphql` used for Issue Fields ops (no `gh` CLI version-pinned subcommands).
- **D13 name-collision capability-detection.** Verify `tracker.toml` `[execution_order]` section persists `field_name` value.
- **Trinity rule applicability.** H.4 touches `scripts/lib/`; no trinity files. PASS.

**Commit subject scope keyword:** `pack-only`. Only `scripts/lib/` edits + accompanying maintenance-docs/IMPL-REPORT + test-fixtures/manifest. Per `CLAUDE.md`: `pack-only` denies `project-template/` and `supporting-docs/`; both denied surfaces are absent. The accompanying IMPL-REPORT under `maintenance-docs/` is NOT in pack-only's permitted-paths column but is ALSO not in the deny-list — see POQ-3 in §6 for scope-keyword guidance interaction with IMPL-REPORT staging. Planner default: `pack-only` keyword.

**Commit message:** `feat: v11 — BD-185 TrackerProvider 3 new ops + GH backend + capability flags (Batch 19d.4)`

**Pack-coder PREFLIGHT line shape:** `PREFLIGHT: 2/2 in-scope file edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.4.md`

**Ordering dependency:** MUST land AFTER H.1 (SCHEMA defines `template_version: phase-part-v11.1` that the new ops reference indirectly via body marker contracts) AND after H.2 (form-family extension defines the user-facing entry path that emits the new template_version). No direct dependency on H.3.

**Success criteria:**
1. `tracker-provider.sh` dispatches `provider_set_field`, `provider_get_field`, `provider_sub_issue_reprioritize`.
2. `tracker-provider-gh.sh` implements `_set_field` + `_get_field` via `gh api graphql`; `_sub_issue_reprioritize` v11.0 stub returns informative deferral error.
3. `provider_capabilities` returns new flags `execution_order.mechanism` + `parts.supported`.
4. `tracker.toml` `[execution_order]` section persists field-name choice per D13.
5. `python3 scripts/validate-pack.py` exits 0.
6. `test-fixtures/manifest.txt` regenerated and staged.

---

### H.5 — NEW `scripts/lib/tracker-phase-part.sh` library + parallel test file (D11)

**Scope:** Per architect §4.4 + §10.1 + §14.2 + §14.9. CREATE the new `tracker-phase-part.sh` library (parser/emitter + state taxonomy + lib invariants) parallel to `tracker-phase-task.sh` per D11. CREATE the parallel test file.

**Files modified (2 CREATE):**
- `scripts/lib/tracker-phase-part.sh` (NEW)
- `scripts/tests/test-tracker-phase-part.sh` (NEW)

**Edit specification:**

1. **`scripts/lib/tracker-phase-part.sh`:**
   - Parallel structure to `scripts/lib/tracker-phase-task.sh` (read it first; mirror the function naming + invariant patterns).
   - Functions: `tracker_phase_part_parse_body`, `tracker_phase_part_emit_body`, `tracker_phase_part_validate_state`, `tracker_phase_part_validate_membership`.
   - State taxonomy enforcement: admit `pending / in-progress / done / deferred` per §4.4; reject `merged-into:` / `superseded-by:` / `cancelled` (cancelled is task-only per D5; Parts use the 4-state taxonomy).
   - Body marker emit: `<!-- pack-id: phase-N.Part-x -->` + `<!-- template_version: phase-part-v11.1 -->` + `<!-- pack-version: v11 -->`.
   - Membership invariant: at least one phase-task as sub-issue child OR `status:deferred` (per D3 + §10.2 Check N+3).
   - Lib invariant: forbids Path 3 (`--fold-into`) per INV-6 (preserved across Parts).
2. **`scripts/tests/test-tracker-phase-part.sh`:**
   - Parallel structure to `scripts/tests/test-tracker-phase-task.sh` (read it first).
   - Test groups: parse-body / emit-body / state-taxonomy-admit / state-taxonomy-reject / membership-invariant / membership-deferred-exception / body-marker-trio.
   - Smoke fixtures under `scripts/tests/fixtures/tracker-phase-part/` (NEW subdir; ~5-8 fixtures per BD-185 §4.4 state taxonomy coverage).

**Verification commands:**

```bash
python3 scripts/validate-pack.py
# Verify new lib file passes Check 35-like lib-invariant check (extended in H.10):
bash scripts/lib/tracker-phase-part.sh --self-test 2>&1 || true  # if lib has self-test
bash scripts/tests/test-tracker-phase-part.sh
# Expected: exit 0 with all groups passing.
bash test-fixtures/build.sh --all --clean
git diff --stat test-fixtures/manifest.txt
```

**RC9 manifest regen:** REQUIRED. `scripts/` in v11-surface per BD-176.

**Per-commit reviewer:** **INLINE — sliding-window scope (H.5 alone; prior INLINE was H.4).** Boundary-sensitive surface for reviewer focus:
- **Library parallels `tracker-phase-task.sh`.** Verify function naming + lib invariant pattern matches the existing phase-task lib (per D11 framing).
- **State taxonomy strict 4-state.** Verify Parts admit only `pending / in-progress / done / deferred`; explicitly reject `cancelled` (task-only per D5), `merged-into:`, `superseded-by:`.
- **Body marker trio matches SCHEMA.** Verify the emit function produces exact byte-sequence matching v11.1/phase-part-v11.1/SCHEMA.md (H.1).
- **Membership invariant per D3.** Verify the validate function enforces ≥1 task as sub-issue child OR `status:deferred`.
- **Test coverage completeness.** Verify the test file exercises every state taxonomy admit + reject + membership invariant + deferred-Part exception path.
- **Filename uniqueness preserved.** `tracker-phase-part.sh` is new; `find . -name "tracker-phase-part.sh"` returned 0 at H.0 baseline — verify still no collision at this commit's HEAD.

**Commit subject scope keyword:** `pack-only`. Only `scripts/` edits. Maintenance-docs/IMPL-REPORT considered (POQ-3 §6).

**Commit message:** `feat: v11 — BD-185 tracker-phase-part.sh library (D11; parallel to tracker-phase-task.sh) (Batch 19d.5)`

**Pack-coder PREFLIGHT line shape:** `PREFLIGHT: 2/2 in-scope file edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.5.md`

**Ordering dependency:** MUST land AFTER H.1 (SCHEMA defines body marker trio + state taxonomy) AND after H.4 (TrackerProvider abstraction surfaces the new ops that downstream H.6 tracker-* lib extensions call — H.5 itself does NOT call provider ops; the lib is parser/emitter, not provider-dispatched; verified architect §7 op-impact table does not list `tracker-phase-part.sh` as a provider-op caller).

**Success criteria:**
1. `scripts/lib/tracker-phase-part.sh` exists with parallel structure to `tracker-phase-task.sh`.
2. State taxonomy admits `pending / in-progress / done / deferred` only.
3. Body marker emit matches v11.1/phase-part-v11.1/SCHEMA.md byte-identically.
4. Membership invariant enforced per D3.
5. `scripts/tests/test-tracker-phase-part.sh` exits 0 with all groups passing.
6. `python3 scripts/validate-pack.py` exits 0.
7. `test-fixtures/manifest.txt` regenerated and staged.

---

### H.6 — tracker-* lib extensions (Part admission + execution-order plumbing + id-map/sidecar schema)

**Scope:** Per architect §7 + §14.2. EXTEND multiple existing tracker-* lib files to admit Part identifiers in cross-references, parent regex, label provisioning, dependency grammar, sidecar shape, and tracker-init/doctor checks.

**Files modified (~7 EXTEND):**
- `scripts/lib/tracker-phase-task.sh` (admit Parts in parent regex; admit Part-id in cross-refs per architect §7)
- `scripts/lib/tracker-labels.sh` (add `template:phase-part-v11.1` to label provisioning)
- `scripts/lib/tracker-links.sh` (admit `Phase-N.Part-x` in dependency grammar)
- `scripts/lib/tracker-sidecar.sh` (emit `parts` block + `phase_execution_order` block per §4.6 + §7.3)
- `scripts/lib/tracker-init.sh` (provision `Execution Order` Issue Field via `provider_set_field` setup OR phase-order-root issue based on `provider_capabilities` flag)
- `scripts/lib/tracker-doctor.sh` (admit Part pack-id in sanity check regex; verify `Execution Order` field exists + writeable per architect §5.1)
- `scripts/lib/tracker-promote.sh` (per POQ-4 resolution 2026-05-26: EXTEND existing Path 2 target-identifier grammar to admit `Phase-N.Part-x` form; NO new path introduced; INV-6 (Path 3 `--fold-into`) remains FORBIDDEN; NO `pack td promote --to=Phase-N.Part-x.Task-M` (task targets) admitted)

**Edit specification:**

Per architect §7 + §7.2 + §7.3:

1. **`tracker-phase-task.sh`:** Update sub-issue parent regex from `^phase-\d+$` to `^phase-\d+(\.Part-[a-z])?$` (or equivalent). Admit `Phase-N.Part-x` and `Phase-N.Part-x.Task-M` in cross-reference resolution (Task-M integer-only per D15).
2. **`tracker-labels.sh`:** Add `template:phase-part-v11.1` to the label provisioning list. Verify existing `status:*` namespace handles Part state taxonomy (no new label).
3. **`tracker-links.sh`:** Extend dependency grammar admission to include `Phase-N.Part-x` (per architect §7).
4. **`tracker-sidecar.sh`:** Per architect §4.6 + §7.3:
   - Emit `phase_tasks.phase-N.parts` block (per-Part `task_members` + `state`)
   - Emit `phase_tasks.phase-N.tasks.phase-N.M.parent_part` field (when task belongs to a Part)
   - Emit NEW top-level `phase_execution_order` block (per-phase order value)
   - All additive; v11.0 sidecar files load cleanly.
5. **`tracker-init.sh`:** Per architect §5.1 + §6.1:
   - Capability-detect at init time via `provider_capabilities` (added in H.4)
   - If `execution_order.mechanism = "issue_fields"`: provision `Execution Order` field at org via `gh api graphql` (or detect existence + use; D13 name-collision fallback to `Pack Execution Order`)
   - If `execution_order.mechanism = "sub_issue_reprioritize"`: create the `phase-order-root` singleton issue (per architect §5.2; for Forgejo/Gitea v11.1+ pre-provisioning — v11.0 may skip creation if no Forgejo/Gitea backend live)
   - Persist field-name choice to `tracker.toml` `[execution_order]` section per H.4 D13 extension
6. **`tracker-doctor.sh`:** Per architect §5.1:
   - Verify configured `field_name` exists at org
   - Verify field has type `number`
   - Verify field is writeable
   - Admit Part pack-id form in sanity check regex
7. **`tracker-promote.sh`:** Per POQ-4 resolution 2026-05-26: EXTEND existing Path 2 (`pack bd promote --to=Phase-N`) target-identifier grammar to admit `Phase-N.Part-x` form. NO new path is introduced. Path 3 (`--fold-into`) remains FORBIDDEN per INV-6 / C-4. The Path 2 extension admits Part epic targets (`Phase-N.Part-x`) but NOT task targets (`Phase-N.Part-x.Task-M`) — task-level promotion would conflict with phase-task immutability invariants per INV-2.

**id-map.json + sidecar schema additive extensions** (per architect §7.2 + §7.3 — these are RUNTIME schema, not source-file edits; the libraries that read/write id-map.json now produce the new fields):
- `phase-N` entries gain optional `execution_order` + `parts` blocks
- `phase-N.M` entries gain optional `parent_part` field
- `phase-order-root` entries (Forgejo/Gitea fallback) — v11.0 surfaces the field but does not exercise it

**Verification commands:**

```bash
python3 scripts/validate-pack.py
# Per-lib smoke tests where applicable:
bash scripts/tests/test-tracker-labels.sh 2>&1 || true
bash scripts/tests/test-tracker-sidecar.sh 2>&1 || true
bash scripts/tests/test-tracker-init.sh 2>&1 || true  # H.15 may extend this
bash scripts/tests/test-tracker-doctor.sh 2>&1 || true
# Verify cross-reference regex admits Part forms:
echo "Phase-7.Part-a.Task-3" | bash scripts/lib/tracker-phase-task.sh --validate-pack-id - 2>&1 || true
bash test-fixtures/build.sh --all --clean
git diff --stat test-fixtures/manifest.txt
```

**RC9 manifest regen:** REQUIRED. `scripts/` in v11-surface per BD-176.

**Per-commit reviewer:** SKIP (covered by H.7 sliding window: H.6+H.7). Boundary-sensitive surface deferred to H.7 reviewer:
- Per-lib edit consistency with H.4 provider ops (set_field / get_field invocation correctness).
- D13 name-collision capability-detection flow (init → field_name read → doctor verify).
- Sidecar additive schema does not break v11.0 sidecar load.
- INV-6 Path 3 preservation in `tracker-promote.sh` (per planner POQ-4 outcome).

**Commit subject scope keyword:** `pack-only`. Only `scripts/lib/` edits.

**Commit message:** `feat: v11 — BD-185 tracker-* lib extensions (Part admission + execution-order plumbing + id-map/sidecar schema) (Batch 19d.6)`

**Pack-coder PREFLIGHT line shape:** `PREFLIGHT: 7/7 in-scope file edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.6.md`

**Ordering dependency:** MUST land AFTER H.4 (calls into the 3 new provider ops) AND after H.5 (tracker-phase-task.sh extension references the new tracker-phase-part.sh lib).

**Success criteria:**
1. tracker-phase-task.sh / tracker-labels.sh / tracker-links.sh / tracker-sidecar.sh / tracker-init.sh / tracker-doctor.sh updated per architect §7.
2. tracker-promote.sh Path 2 extended to admit `Phase-N.Part-x` target (per POQ-4 resolution 2026-05-26); Path 3 still FORBIDDEN; task targets NOT admitted.
3. id-map.json + sidecar.yaml additive schema additions implemented in lib emit/read paths.
4. `tracker-init.sh` provisions Issue Field OR phase-order-root via capability-detect; persists field_name to tracker.toml.
5. `tracker-doctor.sh` verifies field existence + type + writeability.
6. `python3 scripts/validate-pack.py` exits 0.
7. `test-fixtures/manifest.txt` regenerated and staged.

---

### H.7 — Per-entry sort key + mirror-generate + NEW `_order-generate.sh` + `_order.md` SSOT-derived view (D7 + POQ-5)

**Scope:** Per architect §5.3 + §14.3. Extend per-entry sort to use execution-order tuple; mirror-generate emits in execution order; introduce `_order.md` as the SSOT-derived view file (D7). `toc-regenerate` may extend per planner discretion.

**Files modified (2 EXTEND + 2 CREATE):**
- `scripts/lib/per-entry/_lib.sh` (EXTEND; new sort key extractor for `project-implementation-plan` stream)
- `scripts/lib/per-entry/mirror-generate.sh` (EXTEND; sort entries by new key; emit `<!-- execution-order: NNN -->` in mirror per architect §5.3; orchestrates calls to BOTH `toc-regenerate.sh` (for `_toc.md`) AND `_order-generate.sh` (for `_order.md`))
- `scripts/lib/per-entry/_order-generate.sh` (NEW; parallel to `toc-regenerate.sh`; single-responsibility per file; emits `_order.md` SSOT-derived view per D7 + POQ-5 resolution 2026-05-26)
- `scripts/tests/test-_order-generate.sh` (NEW; parallel to existing per-entry test fixtures)

**Edit specification:**

Per architect §5.3:

1. **`_lib.sh:pe_sort_entries`:** Extend with a new sort key extractor for the `project-implementation-plan` stream. Read each entry's `<!-- execution-order: NNN -->` marker. Sort by `(execution-order, phase_number, filename)` tuple. Default to `phase_number` if execution-order marker missing; default to filename (lexical) if both missing.
2. **`mirror-generate.sh`:** Apply the new sort key to the implementation-plan stream. Emit phases in execution order in the generated `docs/project/IMPLEMENTATION-PLAN.md` mirror.
3. **`_order-generate.sh` (NEW):** Per POQ-5 resolution 2026-05-26 — create a new `scripts/lib/per-entry/_order-generate.sh` script parallel to `toc-regenerate.sh` (single-responsibility per file; matches existing per-entry script pattern per original architect POQ-7 review). `mirror-generate.sh` orchestrates calls to BOTH `toc-regenerate.sh` (for `_toc.md`) AND `_order-generate.sh` (for `_order.md`). Shared logic (entry walk, regex helpers) lives in existing `_lib.sh`.
4. **`scripts/tests/test-_order-generate.sh` (NEW):** Parallel to existing per-entry test fixtures; exercises the new script.

**`_order.md` content shape:**
- Human-readable list of phases in execution order
- One line per phase: `N. **phase-N** — <Phase title> — execution-order: <value>` or similar prose
- Header: "This file is generated by `pack mirror-generate`. It is a regenerated view of the execution-order SSOT — never the source of truth. Edit `phase-N.md` body markers (flat-file mode) or the tracker Issue Field (tracker mode) instead." per architect §5.X.

**Verification commands:**

```bash
python3 scripts/validate-pack.py
# Spot test: create a fixture with phases [10, 2, 1] and execution-order [3, 1, 2]; sort should produce [phase-2, phase-1, phase-10]:
bash scripts/tests/test-per-entry.sh 2>&1 | grep -E "sort|order" || true  # H.15 may add fixture
# Manually verify _order.md content shape:
ls scripts/lib/per-entry/  # No new script files unless POQ-5 → (b)
bash test-fixtures/build.sh --all --clean
git diff --stat test-fixtures/manifest.txt
```

**RC9 manifest regen:** REQUIRED. `scripts/` in v11-surface per BD-176.

**Per-commit reviewer:** **INLINE — sliding-window scope (sliding from H.5: H.6+H.7).** Boundary-sensitive surface for reviewer focus:
- **H.6 tracker-* extensions correctness (carry-forward).** Verify provider op calls + capability-detect flow + sidecar additive schema + INV-6 preservation in promote.sh.
- **Sort tuple correctness.** Verify `(execution-order, phase_number, filename)` tuple sorts as expected (phase-10 before phase-2 when execution-order [3, 1, ...] correctly puts phase-2 ahead).
- **Default behavior for missing markers.** Verify entries without `execution-order` markers fall through to phase_number then filename — matches architect §5.3 worked example "Greenfield projects" case.
- **`_order.md` SSOT-derived view contract.** Verify the file has a clear "never source of truth" header per architect §5.X.
- **D7 separate-file LOCK preserved.** Verify the implementation creates `_order.md` as a separate per-entry supporting file (not inlined in `_toc.md`).
- **Mirror generation idempotency.** Verify running mirror-generate twice produces byte-identical output (Check 32 mirror-in-sync semantic).

**Commit subject scope keyword:** `pack-only`. Only `scripts/lib/per-entry/` edits.

**Commit message:** `feat: v11 — BD-185 per-entry sort by execution-order + _order.md view (D7) (Batch 19d.7)`

**Pack-coder PREFLIGHT line shape:** `PREFLIGHT: 4/4 in-scope file edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.7.md`

**Ordering dependency:** MUST land AFTER H.6 (tracker-* libs emit the execution-order field that mirror-generate reads; per-entry sort is consumer of the new marker semantic).

**Success criteria:**
1. `_lib.sh:pe_sort_entries` sorts implementation-plan stream by `(execution-order, phase_number, filename)`.
2. `mirror-generate.sh` emits phases in execution order; orchestrates calls to both `toc-regenerate.sh` (for `_toc.md`) and `_order-generate.sh` (for `_order.md`).
3. NEW `scripts/lib/per-entry/_order-generate.sh` script created per POQ-5 resolution 2026-05-26 (parallel to `toc-regenerate.sh`; single-responsibility per file).
4. NEW `scripts/tests/test-_order-generate.sh` test file created and passes.
5. `_order.md` is created as SSOT-derived view file per D7.
6. `_order.md` carries "never source of truth" header per §5.X.
7. Filename uniqueness preserved (`_order-generate.sh` unique in repo).
8. `python3 scripts/validate-pack.py` exits 0.
9. `test-fixtures/manifest.txt` regenerated and staged.

---

### H.8 — Migrators (forward + reverse + v10→v11) + execution-note structured warning (SC7 + SC8)

**Scope:** Per architect §6 + §14.4. EXTEND tracker-migrate-forward.sh, tracker-migrate-reverse.sh, and migrate-v10-to-v11/{decompose,apply}.sh to support Parts + execution-order. SC7 (bi-directional sync) + SC8 (migration pass-through) are the critical success criteria for this commit. Implement execution-note structured warning per architect §6.3a (D8).

**Files modified (~4 EXTEND):**
- `scripts/lib/tracker-migrate-forward.sh` (Step 5 + 5.5 + 7b + 8 + 9 per architect §6.2)
- `scripts/lib/tracker-migrate-reverse.sh` (sort by execution_order; emit v2 markers + Part H3 sub-sections per architect §6.3)
- `scripts/lib/migrate-v10-to-v11/decompose.sh` (emit body marker quad incl. execution-order per architect §6.1 Phase A)
- `scripts/lib/migrate-v10-to-v11/apply.sh` (Phase B Part-entity creation step per architect §6.1)

**Edit specification:**

Per architect §6 + §6.3a:

1. **`tracker-migrate-forward.sh`:** Per architect §6.2 step extensions:
   - Step 5 EXTEND: read `<!-- execution-order: NNN -->` from each `phase-N.md`; pass to `provider_create` for inclusion in post-create `provider_set_field` call.
   - NEW Step 5.5: for each phase with H3 Parts, create `phase-part-v11.1` sub-issues (via `provider_create` + tracker-phase-part.sh emit); re-parent tasks per H3 grouping.
   - Step 7b EXTEND: admit `Phase-N.Part-x` form in dependency targets (per H.6 `tracker-links.sh` extension).
   - NEW Step 8: after all phase epics exist, call `provider_set_field` per phase with execution-order value.
   - NEW Step 9: write per-Part `task_members` + `state` blocks to sidecar (per H.6 `tracker-sidecar.sh` extension).
2. **`tracker-migrate-reverse.sh`:** Per architect §6.3:
   - `_tmr_emit_implementation_plan`: sort phases by `execution-order` value (read from Issue Fields or fallback); write `<!-- execution-order: NNN -->` marker into emitted `phase-N.md`.
   - `_tmr_emit_status`: sort phases by execution-order (display change; SC5 preserves STATUS.md dashboard role).
   - Phase-epic body emit: emit `<!-- pack-id-v2: Phase-N -->` marker alongside existing `<!-- pack-id: phase-N -->`.
   - Phase-task body emit: emit `<!-- pack-id-v2: Phase-N.Part-x.Task-M -->` marker (or `Phase-N.Task-M` if no Part membership) alongside existing v1 marker per D12 LAZY rule.
   - NEW: multi-part phase emit — for phases with Part children, emit H3 `### Part a — <subtitle>` / `### Part b — <subtitle>` sub-sections; H4 task headers grouped under their Part.
3. **`migrate-v10-to-v11/decompose.sh`:** Per architect §6.1 Phase A:
   - On emit of each `phase-N.md`, write body marker quad: back-pointer + pack-id + pack-id-v2 + execution-order
   - execution-order value = phase position in IMPLEMENTATION-PLAN.md (1-indexed) per "current implementation order" P4
   - For OT-style projects: value = phase_number
   - Preserve H3 sub-sections inline in emitted `phase-N.md` (if v10 source had Parts pre-BD-185).
4. **`migrate-v10-to-v11/apply.sh`:** Per architect §6.1 Phase B:
   - Initialize Issue Field at tracker init (uses `tracker-init.sh` from H.6).
   - Initial-order write: after all phase epics exist, write execution-order values (1, 2, ..., N).
   - Multi-part phase entity creation: if decompose detected H3 Parts, create Part sub-issues + re-parent tasks per H3 structure.
5. **Execution-note structured warning template (architect §6.3a / D8):** Implement in `migrate-v10-to-v11/decompose.sh` (and/or `tracker-migrate-forward.sh` Step 5 — coder picks emit site for context-richest message):
   - On encountering `> **Execution note**:` paragraph, emit structured warning with 7 fields per architect §6.3a:
     1. Phase number + title
     2. Full note text (verbatim excerpt)
     3. Referenced entities (heuristic regex extraction: `\bPhase\s+\d+\b`, `\bphase-\d+\b`, `\bBD-\d+\b`, `\bTD-\d+\b`, `\bphase-\d+\.\d+\b`)
     4. Current state of referenced entities (status / execution-order)
     5. Contextual assessment data (e.g., "all referenced phases status:done → likely historical")
     6. Suggested actions with concrete commands (3 paths: [1] accept default, [2] reorder with suggested `pack phase reorder` command + sparse value, [3] mark as historical via `<!-- execution-note-status: historical -->`)
     7. Doc cross-reference (METHODOLOGY.md or MIGRATION-v10-to-v11.md section)
   - Historical-marker persistence: respect `<!-- execution-note-status: historical -->` marker (skip warning).
   - Default order = phase_number per D8 (no auto-assignment from regex extraction).

**Verification commands:**

```bash
python3 scripts/validate-pack.py
# Round-trip verify (per architect §15 SC7 + SC8):
bash scripts/tests/test-tracker-migrate-forward.sh 2>&1 | tail -10 || true
bash scripts/tests/test-tracker-migrate-reverse.sh 2>&1 | tail -10 || true
bash scripts/tests/test-migrate-v10-to-v11.sh 2>&1 | tail -10 || true
# v10→v11 migrator smoke (uses BD-119 framework):
bash scripts/migrate-v10-to-v11.sh --dry-run --source <fixture> --target /tmp/bd185-migrate-test 2>&1 | tail -20 || true
bash test-fixtures/build.sh --all --clean
git diff --stat test-fixtures/manifest.txt
```

**RC9 manifest regen:** REQUIRED. `scripts/` in v11-surface per BD-176.

**Per-commit reviewer:** **INLINE — sliding-window scope (H.8 alone; prior INLINE was H.7).** This is THE most boundary-sensitive commit (SC7 + SC8 bi-directional sync). Boundary-sensitive surface for reviewer focus:
- **SC7 round-trip integrity.** Verify forward (flat → tracker) + reverse (tracker → flat) produce byte-equivalent phase-N.md files (modulo `pack-id-v2` LAZY backfill per D12).
- **SC8 OT-style birth-order pass-through.** Verify v10→v11 migrator carries phases 1..N with execution-order = phase_number (matches user intuition).
- **D12 LAZY pack-id-v2 backfill.** Verify only Part-expanded tasks gain v2 marker; non-Part tasks remain v1-only.
- **D8 default phase_number + structured warning.** Verify the warning template emits all 7 required fields; default order is phase_number; no auto-assignment from regex.
- **H3 Parts inline preservation.** Verify decompose preserves H3 sub-sections in emitted `phase-N.md`; reverse migrate emits H3 sub-sections grouped by Part.
- **Capability-detect for execution-order mechanism.** Verify migrate-forward Step 8 routes via `provider_capabilities` (Issue Fields primary; sub-issue reprioritize fallback v11.1+).
- **INV-1 + INV-2 + INV-3 preservation.** Verify phase numbers, task IDs, and tracker entity IDs are NEVER renumbered across migration.
- **Historical-marker round-trip.** Verify `<!-- execution-note-status: historical -->` round-trips through reverse migration.

**Commit subject scope keyword:** `pack-only`. Only `scripts/lib/` edits.

**Commit message:** `feat: v11 — BD-185 migrators forward+reverse + execution-note structured warning (SC7+SC8) (Batch 19d.8)`

**Pack-coder PREFLIGHT line shape:** `PREFLIGHT: 4/4 in-scope file edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.8.md`

**Ordering dependency:** MUST land AFTER H.6 (tracker-* libs provide the new ops the migrators call) AND after H.7 (per-entry sort + execution-order marker semantic; mirror behavior).

**Success criteria:**
1. tracker-migrate-forward.sh implements Steps 5/5.5/7b/8/9 per architect §6.2.
2. tracker-migrate-reverse.sh sorts by execution-order; emits v2 markers + Part H3 sub-sections.
3. migrate-v10-to-v11/decompose.sh emits body marker quad + execution-order initialized from current order.
4. migrate-v10-to-v11/apply.sh provisions execution-order Issue Field + creates Part entities + re-parents tasks.
5. Execution-note structured warning template implemented with all 7 required fields.
6. SC7 + SC8 round-trip integrity verified by test infra (H.15 may extend coverage).
7. `python3 scripts/validate-pack.py` exits 0.
8. `test-fixtures/manifest.txt` regenerated and staged.

---

### H.9 — New pack verbs (`pack phase split`, `pack phase reorder`, `pack tracker phase split/reorder`, `pack task supersede`)

**Scope:** Per architect §4.5 + §4.8 + §5.5 + §14.5. CREATE `scripts/pack-phase.sh` for the new `pack phase split` + `pack phase reorder` verbs (flat-file mode). EXTEND `scripts/pack-tracker.sh` for tracker-mode parallels. EXTEND `scripts/pack-td.sh` (or `scripts/pack-task.sh` if the existing convention has separate task-verb file) for `pack task supersede` per D4 §4.8.

**Files modified (~3 CREATE/EXTEND):**
- `scripts/pack-phase.sh` (NEW — `pack phase split <phase-N> --parts <count>` + `pack phase reorder`)
- `scripts/pack-tracker.sh` (EXTEND — `pack tracker phase split` + `pack tracker phase reorder`)
- `scripts/pack-td.sh` (EXTEND, OR `scripts/pack-task.sh` CREATE if convention has separate task-verb file — coder verifies existing pattern at impl-time per D6 verify-at-implementation-time approach; default per pack-td.sh existing surface)

**Edit specification:**

Per architect §4.5 + §4.8 + §5.5:

1. **`scripts/pack-phase.sh` (NEW):**
   - **`pack phase split <phase-N> --parts <count>`** (flat-file mode):
     - Read existing tasks for phase N from `docs/project/implementation-plan/phase-N.md`
     - Prompt user: "Assign each task to a Part (a, b, c, ...)"
     - VALIDATE per D3: every declared Part has ≥1 assigned task; REJECT split with actionable error if any Part is empty
     - Emit H3 sub-sections + re-parent tasks (initial Part assignment; D4 forbids subsequent re-parenting)
     - Update per-task `pack-id-v2` body marker from `Phase-N.Task-M` to `Phase-N.Part-a.Task-M` (or `Part-b`, ...) per D12 LAZY backfill
     - Regenerate IMPLEMENTATION-PLAN.md mirror via `pack mirror-generate`
   - **`pack phase reorder`** (flat-file mode):
     - Interactive: read current order from `<!-- execution-order: NNN -->` markers
     - Present phases sorted by current order
     - User reorders via index swap; sparse values admitted (e.g., 2.5 between 2 and 3)
     - Rewrite markers in `phase-N.md` files
     - Regenerate mirror + STATUS.md
2. **`scripts/pack-tracker.sh` EXTEND:**
   - **`pack tracker phase split <phase-N> --parts <count>`** (tracker mode):
     - Same UX as `pack phase split` plus:
     - Create `phase-part-v11.1` sub-issues under phase epic (via `provider_create` + tracker-phase-part.sh emit)
     - Re-parent task issues via `provider_sub_issue_unlink` + `provider_sub_issue_create`
     - Update id-map.json: add `phase-N.parts.Part-a` etc.; add `phase-N.M.parent_part` per architect §7.2
   - **`pack tracker phase reorder`** (tracker mode):
     - Same UX; writes via `provider_set_field` (Issue Fields primary) OR fallback mechanism
     - Reads via `provider_get_field` per phase
3. **`pack task supersede <old-task-id> --with <new-task-id-template>`** (per D4 §4.8):
   - Add to existing pack-td.sh OR new pack-task.sh per existing convention
   - Old task: state transitions to `status:superseded-by:Phase-N.Part-x.Task-M`
   - New task: created in target Part (or target phase for cross-phase supersession) with content (identical, modified, or different per user choice)
   - Old task body, markers, sub-issue parentage, Part membership stay byte-identical
   - New task carries `<!-- pack-id: phase-N.M -->` + `<!-- pack-id-v2: Phase-N.Part-y.Task-M -->`
   - NO `pack task reparent` verb (D4); if invoked errors with "use `pack task supersede` instead"

**Verification commands:**

```bash
python3 scripts/validate-pack.py
# Help text for new verbs:
bash scripts/pack-phase.sh --help 2>&1 | head -20 || bash scripts/pack-phase.sh 2>&1 | head -20
bash scripts/pack-tracker.sh phase split --help 2>&1 | head -20 || true
# Smoke test on scratch fixture:
mkdir -p /tmp/bd185-h9-fixture/docs/project/implementation-plan
echo '# phase-1' > /tmp/bd185-h9-fixture/docs/project/implementation-plan/phase-1.md
# (full smoke deferred to H.15 fixture coverage)
bash test-fixtures/build.sh --all --clean
git diff --stat test-fixtures/manifest.txt
```

**RC9 manifest regen:** REQUIRED. `scripts/` in v11-surface per BD-176.

**Per-commit reviewer:** **INLINE — sliding-window scope (H.9 alone; prior INLINE was H.8).** Boundary-sensitive surface for reviewer focus:
- **`pack phase split` rejection of empty Parts (D3).** Verify rejection text actionable.
- **`pack phase split` initial-Part-assignment-only contract.** Verify the verb is one-time (cannot re-run on a phase that already has Parts); architecture per architect §4.7 makes mid-life re-parenting forbidden (D4).
- **`pack phase reorder` sparse-value support.** Verify floats (2.5) admitted; renumber NOT triggered.
- **`pack task supersede` linkage.** Verify old task superseded-by marker + new task pack-id-v2 + cross-reference resolvability.
- **No `pack task reparent` verb.** Verify any reparent-named entry errors with "use supersede instead" per D4.
- **No `pack phase collapse` verb.** Verify D2: no collapse path exists anywhere.
- **Help text mentions all new verbs.** (H.12 lands HELP-FRAGMENT-PACK / HELP-FRAGMENT-TRACKER additions; this commit's verb output should match what H.12 documents.)

**Commit subject scope keyword:** `pack-only`. Only `scripts/` edits.

**Commit message:** `feat: v11 — BD-185 new pack verbs (phase split/reorder + task supersede) (Batch 19d.9)`

**Pack-coder PREFLIGHT line shape:** `PREFLIGHT: 3/3 in-scope file edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.9.md`

**Ordering dependency:** MUST land AFTER H.6 (tracker-* lib ops the verbs call) AND after H.7 (per-entry sort + mirror-generate the verbs invoke) AND after H.8 (migrators infrastructure — verbs share patterns).

**Success criteria:**
1. `scripts/pack-phase.sh` exists with `phase split` + `phase reorder` subcommands.
2. `pack phase split` enforces D3 (≥1 task per Part) with actionable rejection.
3. `pack phase reorder` admits sparse values; no renumbering.
4. `pack tracker phase split` + `pack tracker phase reorder` work via provider ops.
5. `pack task supersede` implements D4 / §4.8 contract.
6. `pack task reparent` (if any reparent-named entry exists) errors with supersede guidance.
7. No `pack phase collapse` verb exists.
8. `python3 scripts/validate-pack.py` exits 0.
9. `test-fixtures/manifest.txt` regenerated and staged.

---

### H.10 — validate-pack.py extensions + 4 NEW checks + CI workflow wiring

**Scope:** Per architect §10 + §14.6 + §14.9. EXTEND existing CI checks (32, 33, 34, 35, `check_issue_template_forms`, `check_template_archive_v11`) and ADD 4 NEW checks per §10.2 (phase-part-schema-v11.1, execution-order-marker, part-re-parentage, part-has-member-task). Add per-check test files. Wire new tests in `.github/workflows/validate-pack.yml`.

**Files modified (~5 EXTEND/CREATE):**
- `scripts/validate-pack.py` (extend Check 32/33/34/35 + `check_issue_template_forms` + `check_template_archive_v11`; add 4 new check functions)
- `scripts/tests/test-validate-pack-check-N.sh` (NEW — phase-part schema) — exact check number to be assigned at impl time (current highest is Check 43 per HEAD `062cb8f`; new checks become 44, 45, 46, 47)
- `scripts/tests/test-validate-pack-check-{N+1,N+2,N+3}.sh` (NEW — execution-order marker, part-re-parentage, part-has-member-task)
- `.github/workflows/validate-pack.yml` (4 new test-invocation lines)

**Edit specification:**

Per architect §10.1 + §10.2:

1. **Check 32 (`check_mirror_in_sync`) EXTEND:** Stream regex unchanged (Parts INLINE). Mirror sort order changes per §5.3 — test fixtures updated in H.15. Update Check 32 docstring to reference the new sort behavior.
2. **Check 33 (`check_toc_in_sync`) EXTEND:** Group regex unchanged. Optionally extend `_toc.md` display to show execution order (per planner discretion; planner default: no `_toc.md` change since `_order.md` is the SSOT-derived view per D7 / H.7).
3. **Check 34 (`check_cross_reference_integrity`) EXTEND:** Extend `CROSS_REF_RE` to admit:
   - `Phase-N` (capitalized v2)
   - `Phase-N.Part-x` (Part identifier)
   - `Phase-N.Part-x.Task-M` (Part-scoped task; Task-M integer-only per D15)
   - `Phase-N.Task-M` (null-Part task v2; Task-M integer-only per D15)
   - Legacy `phase-N.M` continues to resolve.
4. **Check 35 (`check_tracker_phase_task_invariants`) EXTEND:** Verify `tracker-phase-part.sh` exists (parallel to phase-task lib invariant). Admit `cancelled` state per D5 (introduced in H.13 v11.0 SCHEMA extension; reflected at check-time post-H.13 landing).
5. **`check_issue_template_forms` EXTEND:** Extend `expected_wi_type_options` from 4 to 5: `{bd, td, phase-epic-skeleton, phase-task-skeleton, phase-part-skeleton}` per architect §10.1 + H.2 form-family edit.
6. **`check_template_archive_v11` EXTEND:** v11.0 archive **structural shape** frozen at 5 entry-types (no new subdirs); intra-file content extensions allowed per D16 Convention Y (e.g., `phase-task-v11.0/SCHEMA.md` admits `cancelled` state per D5; `v11.0/INDEX.md` admits forward-reference footnote per H.14). NEW `check_template_archive_v11_1` verifies 6 entry-types in v11.1 archive (per H.1 layout). Alternative cleaner approach: parameterize existing check by version + verify v11.N matches its INDEX.md declaration — planner default is the cleaner approach.
7. **NEW Check N (`check_phase_part_schema_v11_1`):**
   - Verify `maintenance-docs/v11-research/templates-archive/v11.1/phase-part-v11.1/SCHEMA.md` exists
   - Verify SCHEMA declares identifier scheme `Phase-N.Part-x`; body marker trio with `template_version: phase-part-v11.1`; label family (status:* only); state taxonomy `pending / in-progress / done / deferred`
   - Pattern parallels Check 35
8. **NEW Check N+1 (`check_execution_order_marker`):**
   - Verify every `phase-N.md` in `docs/project/implementation-plan/` carries `<!-- execution-order: NNN -->` marker
   - Optional / gated by tracker.toml (project not yet at v11.1 has no markers; not required)
   - CI failure names missing-marker files
9. **NEW Check N+2 (`check_part_re_parentage_invariants`):**
   - For every phase epic with Part sub-issues, verify all phase tasks are sub-issue children of a Part (not direct children of phase epic)
   - Tracker-side check only (no flat-file analog)
10. **NEW Check N+3 (`check_part_has_member_task`):**
    - Verify every Part entity has ≥1 task as sub-issue child OR `status:deferred` (per D3 §4.7)
    - Tracker-side check only
11. **Per-check test files (NEW):** Follow structural pattern of existing `test-validate-pack-check-40.sh` (or other recent per-check tests). One file per new check.
12. **`.github/workflows/validate-pack.yml`:** Add 4 new `bash scripts/tests/test-validate-pack-check-<N>.sh` invocation lines per Check 42 contract.

**Verification commands:**

```bash
python3 scripts/validate-pack.py
# Verify check count increased by 4:
python3 scripts/validate-pack.py 2>&1 | grep -E "^── Check " | wc -l
# Expected: 47 checks total (current 43 + 4 new)
# Run each new per-check test:
bash scripts/tests/test-validate-pack-check-44.sh 2>&1 | tail -5 || true  # exact number TBD
bash scripts/tests/test-validate-pack-check-45.sh 2>&1 | tail -5 || true
bash scripts/tests/test-validate-pack-check-46.sh 2>&1 | tail -5 || true
bash scripts/tests/test-validate-pack-check-47.sh 2>&1 | tail -5 || true
# Verify Check 42 (workflow wiring) PASSES with new test files:
bash scripts/tests/test-validate-pack-check-42.sh 2>&1 | tail -5
bash test-fixtures/build.sh --all --clean
git diff --stat test-fixtures/manifest.txt
```

**RC9 manifest regen:** REQUIRED. `scripts/` in v11-surface per BD-176. (`.github/workflows/` is NOT in RC9 trigger set, but the `scripts/` change forces regen.)

**Per-commit reviewer:** SKIP (covered by H.11 sliding window: H.10+H.11). Boundary-sensitive surface deferred to H.11 reviewer:
- Each extended check's docstring updated per change.
- 4 new check functions reachable + each has corresponding per-check test file.
- Workflow wiring complete; Check 42 PASSES.
- `expected_wi_type_options` matches H.2 work-item.yml content (5 options).
- `check_template_archive_v11` (or parameterized version) handles v11.0 frozen + v11.1 declared 6 entry-types.

**Commit subject scope keyword:** (mixed — no keyword). `scripts/` + `.github/workflows/`. Per `CLAUDE.md`: `.github/workflows/` is NOT in `pack-only` deny-list (denies `project-template/` + `supporting-docs/`), so technically `pack-only` could apply. But Check 36 enforces per-CI rules; planner default is to use no keyword for cross-directory commits unless certain. See POQ-3 in §6.

**Commit message:** `feat: v11 — BD-185 validate-pack extensions + 4 new checks (Part schema, exec-order marker, Part re-parentage, Part membership) (Batch 19d.10)`

**Pack-coder PREFLIGHT line shape:** `PREFLIGHT: 6/6 in-scope file edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.10.md`

**Ordering dependency:** MUST land AFTER H.1 (SCHEMA exists for `check_phase_part_schema_v11_1` to verify), H.2 (work-item.yml has 5 options for `check_issue_template_forms` to expect 5), H.5 (`tracker-phase-part.sh` exists for Check 35 extension to verify), H.6 (id-map.json / sidecar additive schema for `check_part_re_parentage_invariants` runtime read), AND after H.9 (verbs that emit Parts exist for the new checks to ratify post-fixture runs).

**Success criteria:**
1. Check 32, 33, 34, 35, `check_issue_template_forms`, `check_template_archive_v11` updated per architect §10.1.
2. 4 new check functions implemented per architect §10.2.
3. 4 new per-check test files created with full coverage.
4. `.github/workflows/validate-pack.yml` wires the 4 new tests; Check 42 PASSES.
5. `python3 scripts/validate-pack.py` exits 0 with 47 checks total.
6. `test-fixtures/manifest.txt` regenerated and staged.

---

### H.11 — METHODOLOGY.md substantive doc edits (Multi-part + execution-order + supersede + historical-marker)

**Scope:** Per architect §11.1 + §14.8. EXTEND `supporting-docs/METHODOLOGY.md` Part 4 § "Multi-part phases" with tracker representation, Part state taxonomy, programmatic creation, D3/D4 rules; Part 4 § "Phase numbering rules" with execution-order mechanism; supersede verb canonical mid-life task-move; D8 execution-note-status historical marker; D2 no-collapse rule; SCHEMA archive extensions per D5 (deferred to H.13 for the v11.0 SCHEMA file itself; this commit lands the METHODOLOGY-side prose).

**Files modified (1 EXTEND):**
- `supporting-docs/METHODOLOGY.md`

**Edit specification:**

Per architect §11.1:

1. **Part 4 § "Multi-part phases" extensions:**
   - **Tracker-mode representation:** "When tracker mode is enabled (tracker.toml configured), Parts are first-class sub-issue entities under phase epics. See `templates-archive/v11.1/phase-part-v11.1/SCHEMA.md`."
   - **NEW sub-section "Part state taxonomy":** pending / in-progress / done / deferred (architect §4.4).
   - **NEW sub-section "Creating Parts programmatically":** references `pack phase split` + `pack tracker phase split` verbs (architect §4.5 + H.9).
   - **Note on task immutability:** "Existing `phase-N.M` task identifiers are immutable across Part expansion. The pack-id v2 marker (`pack-id-v2: Phase-N.Part-x.Task-M`) is the Part-aware form; the legacy `pack-id: phase-N.M` marker continues to resolve."
2. **Part 4 § "Phase numbering rules" extensions:**
   - **Execution-order mechanism reference:** "To reorder execution, use the `<!-- execution-order: NNN -->` marker (flat-file mode) OR the Issue Field `Execution Order` (tracker mode). The `> **Execution note**:` prose is preserved as human-readable context but is no longer the SSOT for order."
   - Note D7 SSOT vs view: `_order.md` is a regenerated view; never source of truth.
3. **NEW Multi-part phases sub-section (D3 + D4):**
   - **Part creation rule (D3):** Every Part must contain at least one task at creation time. `pack phase split` rejects splits with empty Parts.
   - **Task immutability rule (D4):** Once a task is assigned to a Part (at phase split time), the task remains in that Part forever. Tasks needing to move to a different Part use `pack task supersede` (architect §4.8). NO `pack task reparent` verb.
   - **Supersede verb is canonical mid-life task-move mechanism (D4):** Document.
4. **Execution-note-status marker convention (D8):**
   - Phases whose execution note has been superseded by current state may carry `<!-- execution-note-status: historical -->`. Migrations / lint passes / tools skip warning on phases carrying this marker. Round-trips through reverse migration.
5. **Decision-2 no-collapse rule:**
   - Part collapse is REJECTED as anti-pattern. Once split, the split is permanent — no `pack phase collapse` verb in any release.

**Verification commands:**

```bash
python3 scripts/validate-pack.py
# Spot-check sections present:
grep -nE "^### Part state taxonomy|^### Creating Parts programmatically|^### Execution-note-status historical|pack task supersede|pack phase collapse" supporting-docs/METHODOLOGY.md | head -10
bash test-fixtures/build.sh --all --clean
git diff --stat test-fixtures/manifest.txt
```

**RC9 manifest regen:** REQUIRED. `supporting-docs/` in v11-surface per BD-176.

**Per-commit reviewer:** **INLINE — sliding-window scope (sliding from H.9: H.10+H.11).** Boundary-sensitive surface for reviewer focus:
- **H.10 4-check extension correctness (carry-forward).** Verify all 4 new checks reachable; workflow wires + Check 42 PASSES; `check_issue_template_forms` expects 5 options.
- **METHODOLOGY.md Part 4 Multi-part phases additions match architect §4.4 + §4.5 + §4.7.** Specifically: Part state taxonomy excludes merged-into / superseded-by; programmatic creation references both `pack phase split` and `pack tracker phase split`.
- **D2 no-collapse rule + D3 ≥1 task rule + D4 supersede-only rule** all surfaced in METHODOLOGY.
- **D8 historical-marker convention documented in METHODOLOGY.** Cross-reference to H.8 implementation.
- **Execution-order mechanism reference in Phase numbering rules.** Reference points to flat-file marker + tracker Issue Field; NOT to `> **Execution note**:` prose as SSOT (D8 design).
- **No leak introduced** — METHODOLOGY.md is in client-installed surface (per `init-project.sh` stage S6); references must resolve at client install per `feedback_no_solutions_in_agent_prompts` / boundary-investigation rules.

**Commit subject scope keyword:** (no keyword — `supporting-docs/` only doesn't match `pack-only` deny-list (denies project-template/ + supporting-docs/), so `pack-only` is invalid here; `project-only` denies pack-only paths but allows project-template/ + supporting-docs/. Planner default: `project-only` could apply since supporting-docs/ is in `project-only`'s permitted paths — but maintenance-docs/IMPL-REPORT staging makes it mixed). Use no keyword unless POQ-3 resolves to `project-only` for supporting-docs/-only doc commits.

**Commit message:** `feat: v11 — BD-185 METHODOLOGY.md Multi-part + execution-order + supersede + historical-marker (Batch 19d.11)`

**Pack-coder PREFLIGHT line shape:** `PREFLIGHT: 1/1 in-scope file edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.11.md`

**Ordering dependency:** MUST land AFTER H.9 (verb names referenced in METHODOLOGY exist as actual implementations) AND after H.10 (CI checks ratify the rules METHODOLOGY documents).

**Success criteria:**
1. Part 4 § "Multi-part phases" extended with tracker-rep + state taxonomy + programmatic creation + task immutability.
2. Part 4 § "Phase numbering rules" extended with execution-order mechanism + `> **Execution note**:` no-longer-SSOT clarification.
3. D2 / D3 / D4 / D8 rules surfaced; supersede canonical mid-life task-move documented.
4. `python3 scripts/validate-pack.py` exits 0.
5. `test-fixtures/manifest.txt` regenerated and staged.

---

### H.12 — MIGRATION-v10-to-v11.md edits + HELP-FRAGMENT-PACK + HELP-FRAGMENT-TRACKER (pack-ops + project-template mirrors)

**Scope:** Per architect §11.2 + §11.3 + §14.8. EXTEND MIGRATION-v10-to-v11.md with per-entry decomposition Part handling + NEW Phase B Part materialization section. EXTEND HELP-FRAGMENT-PACK / HELP-FRAGMENT-TRACKER pair in both pack-ops/ and client-mirror locations.

**Files modified (~5 EXTEND):**
- `supporting-docs/MIGRATION-v10-to-v11.md`
- `pack-ops/HELP-FRAGMENT-PACK.md` (pack-side mirror)
- `project-template/docs/pack/HELP-FRAGMENT.md` (client-side mirror)
- `pack-ops/HELP-FRAGMENT-TRACKER.md` (pack-side mirror)
- `project-template/docs/pack/HELP-FRAGMENT-TRACKER.md` (client-side mirror)

**Edit specification:**

Per architect §11.2 + §11.3:

1. **MIGRATION-v10-to-v11.md:**
   - **§ "Per-entry decomposition" extensions:**
     - Multi-part phase H3 sub-sections preserved INLINE in `phase-N.md` during Phase A decompose.
     - execution-order initialization writes `<!-- execution-order: NNN -->` markers with value = phase_number.
     - Warning case: phases with `> **Execution note**:` prose emit migration warning recommending post-migration review via `pack phase reorder` (D8 structured warning template per H.8 §6.3a).
   - **NEW § "Phase B — multi-part phase tracker materialization":** insert after existing Phase B section. Documents: if H3 Parts are present in flat-file, Phase B creates Part sub-issues + re-parents tasks per H3 grouping.
2. **HELP-FRAGMENT-PACK.md additions (both pack-ops/ and project-template/docs/pack/ mirrors):**
   - `pack phase split <phase-N> --parts <count>` — Split a phase into multi-part form mid-work.
   - `pack phase reorder` — Interactively reorder phase execution order (writes markers).
   - `pack task supersede <old-id> --with <new-id-template>` — Supersede a task (per D4 §4.8).
3. **HELP-FRAGMENT-TRACKER.md additions (both pack-ops/ and project-template/docs/pack/ mirrors):**
   - `pack tracker phase split <phase-N> --parts <count>` — Create Part sub-issues + re-parent tasks (tracker mode).
   - `pack tracker phase reorder` — Update Issue Field `Execution Order` (or fallback mechanism).
4. **pack-ops/ ↔ project-template/docs/pack/ byte-identical mirror.** Per existing HELP-FRAGMENT convention (CI Check 24 byte-identical mirror).

**Verification commands:**

```bash
python3 scripts/validate-pack.py
# Verify pack-ops/ and project-template/docs/pack/ HELP-FRAGMENT files are byte-identical (CI Check 24):
diff pack-ops/HELP-FRAGMENT-PACK.md project-template/docs/pack/HELP-FRAGMENT.md
# Expected: empty (byte-identical) OR per existing convention if not identical
diff pack-ops/HELP-FRAGMENT-TRACKER.md project-template/docs/pack/HELP-FRAGMENT-TRACKER.md
# Expected: empty
# Verify new verbs documented:
grep -nE "pack phase split|pack phase reorder|pack task supersede" pack-ops/HELP-FRAGMENT-PACK.md project-template/docs/pack/HELP-FRAGMENT.md
grep -nE "pack tracker phase split|pack tracker phase reorder" pack-ops/HELP-FRAGMENT-TRACKER.md project-template/docs/pack/HELP-FRAGMENT-TRACKER.md
# Verify MIGRATION.md new section:
grep -nE "^## Phase B — multi-part" supporting-docs/MIGRATION-v10-to-v11.md
bash test-fixtures/build.sh --all --clean
git diff --stat test-fixtures/manifest.txt
```

**RC9 manifest regen:** REQUIRED. `supporting-docs/` + `pack-ops/` + `project-template/` all touched. (Note: `MIGRATION-v10-to-v11.md` per BD-176 rationale Note ("`MIGRATION-v10-to-v11.md` edit which is a pre-install reference not copied to clients") — Pack Chat verifies whether MIGRATION-v10-to-v11.md edit alone triggers RC9. Per BD-176: false positives produce no incorrect manifest change; the directory-wide trigger is defensive. Stage manifest if non-empty diff.)

**Per-commit reviewer:** SKIP (covered by H.13 sliding window: H.12+H.13). Boundary-sensitive surface deferred to H.13 reviewer:
- pack-ops/ ↔ project-template/ byte-identical HELP-FRAGMENT mirror preserved.
- New verb names documented exactly match implementation in H.9.
- Phase B new section in MIGRATION-v10-to-v11.md complete; consistent with H.8 migrator behavior.
- No leak into pack-only refs from client-side HELP-FRAGMENT mirrors.

**Commit subject scope keyword:** (no keyword — supporting-docs/ + pack-ops/ + project-template/ all touched; genuinely cross-surface). Per `CLAUDE.md`: "if a batch's work genuinely spans pack + project, the commit subject MUST NOT carry an exclusive scope keyword".

**Commit message:** `feat: v11 — BD-185 MIGRATION + HELP-FRAGMENT (pack + tracker; pack-ops + client mirror) (Batch 19d.12)`

**Pack-coder PREFLIGHT line shape:** `PREFLIGHT: 5/5 in-scope file edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.12.md`

**Ordering dependency:** MUST land AFTER H.8 (migrator behavior documented in MIGRATION.md matches implementation) AND after H.9 (verbs documented in HELP-FRAGMENT exist as implementations) AND after H.11 (METHODOLOGY.md companion doc lands first for cross-reference).

**Success criteria:**
1. MIGRATION-v10-to-v11.md extended per architect §11.2.
2. HELP-FRAGMENT-PACK.md + HELP-FRAGMENT-TRACKER.md updated in both pack-ops/ and project-template/docs/pack/ locations.
3. pack-ops/ ↔ project-template/ HELP-FRAGMENT pairs byte-identical (CI Check 24 PASSES).
4. New verbs documented in HELP-FRAGMENT match H.9 implementation.
5. `python3 scripts/validate-pack.py` exits 0.
6. `test-fixtures/manifest.txt` regenerated and staged.

---

### H.13 — PM-CHAT.md workflow + v11.0 phase-task-v11.0 SCHEMA `cancelled` extension (D5)

**Scope:** Per architect §11.1 + §14.8. EXTEND `project-template/docs/pack/PM-CHAT.md` to reference `pack phase split` workflow for mid-work expansion. EXTEND v11.0 phase-task-v11.0 SCHEMA archive with `cancelled` state per D5 §4.4a + execution-note-status historical marker per D8.

**Files modified (~2 EXTEND):**
- `project-template/docs/pack/PM-CHAT.md`
- `maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md`

**Edit specification:**

Per architect §11.1 + §14.8:

1. **PM-CHAT.md (project-template/docs/pack/PM-CHAT.md):**
   - Reference `pack phase split` workflow in PM-chat orchestration text. Specifically: when planner triggers (5+ tasks, non-linear deps, second-failure) surface mid-work, PM-chat can recommend `pack phase split` per architect §4.5.
   - Reference `pack task supersede` as canonical mid-life task-move per D4.
   - No solution-in-prompt content per `feedback_no_solutions_in_agent_prompts`.
2. **phase-task-v11.0 SCHEMA.md (v11.0 archive):**
   - **Section 3 (Label family) status enumeration extension per D5 §4.4a:**
     - BEFORE: `status:<pending|in-progress|done|deferred|merged-into:phase-N|superseded-by>`
     - AFTER: `status:<pending|in-progress|done|deferred|cancelled|merged-into:phase-N|superseded-by>`
   - **Section 4 (Body grammar) marker list extension per D8:**
     - Add optional body marker: `<!-- execution-note-status: historical -->`
   - Reverse-emit grammar extension: `#### ❌ N.M <task title>` for `status:cancelled` per architect §4.4a.

**Verification commands:**

```bash
python3 scripts/validate-pack.py
# Verify PM-CHAT.md references the new verbs (without solution-in-prompt content):
grep -nE "pack phase split|pack task supersede" project-template/docs/pack/PM-CHAT.md
# Verify v11.0 SCHEMA cancelled-state extension:
grep -nE "cancelled" maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md
grep -nE "execution-note-status: historical" maintenance-docs/v11-research/templates-archive/v11.0/phase-task-v11.0/SCHEMA.md
# Verify Check 35 (`check_tracker_phase_task_invariants`) extended in H.10 admits cancelled:
bash scripts/tests/test-validate-pack-check-35.sh 2>&1 | tail -5 || true
bash test-fixtures/build.sh --all --clean
git diff --stat test-fixtures/manifest.txt
```

**RC9 manifest regen:** REQUIRED. `project-template/` in v11-surface per BD-176. (`maintenance-docs/` does NOT trigger RC9 alone but accompanying `project-template/` does.)

**Per-commit reviewer:** **INLINE — sliding-window scope (sliding from H.11: H.12+H.13).** Boundary-sensitive surface for reviewer focus:
- **H.12 MIGRATION + HELP-FRAGMENT correctness (carry-forward).** Verify pack-ops/ ↔ project-template/ byte-identical; new verbs match H.9; MIGRATION Phase B new section matches H.8 behavior.
- **PM-CHAT.md verb references resolve at client install.** Per `feedback_no_solutions_in_agent_prompts` + boundary-investigation skill: PM-CHAT.md is client-installed (per init-project.sh stage S6); references must resolve at client install. `pack phase split` + `pack task supersede` exist client-side post-H.9.
- **v11.0 SCHEMA cancelled-state extension complies with D16 Convention Y.** Per architect §10.1 (refined by D16 Convention Y) "v11.0 archive structural shape frozen at 5 entry-type subdirs; intra-file content MAY evolve via backward-compatible additive extensions" — the SCHEMA file content extension is exactly the kind of intra-file additive change permitted under Convention Y. Verify the archive directory structure (5 entry-type subdirs) is unchanged; only `phase-task-v11.0/SCHEMA.md` content extends with the new state.
- **Cancelled state semantically distinct from deferred / superseded.** Verify the SCHEMA documents the semantic distinction per architect §4.4a.
- **Execution-note-status historical marker SCHEMA cross-reference.** Verify the marker is documented as round-trip-safe per architect §6.3a.

**Commit subject scope keyword:** (mixed — no keyword; project-template/ + maintenance-docs/).

**Commit message:** `feat: v11 — BD-185 PM-CHAT workflow + phase-task-v11.0 SCHEMA cancelled-state extension (D5) (Batch 19d.13)`

**Pack-coder PREFLIGHT line shape:** `PREFLIGHT: 2/2 in-scope file edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.13.md`

**Ordering dependency:** MUST land AFTER H.9 (verbs referenced in PM-CHAT exist as implementations) AND after H.11 (METHODOLOGY.md companion doc lands first; cross-reference) AND after H.12 (HELP-FRAGMENT documents the verbs already).

**Success criteria:**
1. PM-CHAT.md references `pack phase split` + `pack task supersede` workflow without solutions content.
2. v11.0 phase-task-v11.0 SCHEMA Section 3 (Label family) admits `cancelled` state.
3. v11.0 phase-task-v11.0 SCHEMA Section 4 (Body grammar) admits `<!-- execution-note-status: historical -->` marker.
4. v11.0 archive directory structure unchanged (still 5 entry-type subdirs); only the SCHEMA file content extended.
5. `python3 scripts/validate-pack.py` exits 0; Check 35 admits cancelled state.
6. `test-fixtures/manifest.txt` regenerated and staged.

---

### H.14 — Templates-archive cross-references (v11.0 ↔ v11.1)

**Scope:** Per architect §10.1 + §14.1. Close cross-references between v11.0 (frozen) and v11.1 (new) templates-archive: v11.1 INDEX.md back-references v11.0 archive; v11.0 INDEX.md (if edit needed for v11.1 forward-reference) updated; ensure v11.0 archive frozen invariant preserved (no entry-type subdir additions).

**Files modified (2 EXTEND):**
- `maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md` (EXTEND; finalize cross-references)
- `maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md` (EXTEND; add forward-reference footnote per POQ-6 resolution 2026-05-26 + D16 Convention Y)

**Edit specification:**

Per architect §10.1 + §14.1 + POQ-6 resolution from §6:

1. **v11.1/INDEX.md cross-reference closure:**
   - Verify all 6 entry-types in v11.1 INDEX have correct cross-references (5 inherit from v11.0; 1 new = phase-part-v11.1).
   - Verify `v11.1/forms/work-item.yml` already exists from H.2 (per POQ-1 resolution 2026-05-26); cross-reference from INDEX.
2. **v11.0/INDEX.md forward-reference footnote (per POQ-6 + D16 Convention Y):**
   - EXTEND v11.0/INDEX.md with a forward-reference footnote: '**Note:** v11.1+ archive (at `maintenance-docs/v11-research/templates-archive/v11.1/`) adds the `phase-part-v11.1` entry type and extends `phase-task-v11.0` admitted state values with `cancelled` (per D5 + D16 Convention Y). See `v11.1/INDEX.md` for details.' Per D16 Convention Y, this intra-file additive extension is allowed under the v11.0 structural-shape-frozen contract.

**Verification commands:**

```bash
python3 scripts/validate-pack.py
# Verify v11.0 directory structure unchanged (structural shape frozen per D16):
ls maintenance-docs/v11-research/templates-archive/v11.0/ | sort
# Expected: bd-v11.0 forms INDEX.md inbound-v11.0 phase-epic-v11.0 phase-task-v11.0 td-v11.0
# Verify v11.0/INDEX.md now carries v11.1 forward-reference footnote (per POQ-6 + D16 Convention Y):
grep -nE "v11.1|phase-part-v11.1|D16|Convention Y" maintenance-docs/v11-research/templates-archive/v11.0/INDEX.md
# Verify v11.1 has 6 entry-types declared in INDEX (paths or inline refs):
grep -nE "phase-part-v11.1|phase-task-v11.0|phase-epic-v11.0|bd-v11.0|td-v11.0|inbound-v11.0" maintenance-docs/v11-research/templates-archive/v11.1/INDEX.md
# Verify v11.1/forms/work-item.yml byte-identical to .github/ISSUE_TEMPLATE/work-item.yml (already so from H.2 per POQ-1):
diff maintenance-docs/v11-research/templates-archive/v11.1/forms/work-item.yml .github/ISSUE_TEMPLATE/work-item.yml
# Expected: empty (byte-identical; no H.14-refresh needed per POQ-1 resolution 2026-05-26).
```

**RC9 manifest regen:** NO. `maintenance-docs/` alone is NOT in the v11-surface 4-directory trigger per BD-176. Coder verifies manifest diff is empty after `bash test-fixtures/build.sh --all --clean`; if empty, no staging.

**Per-commit reviewer:** **INLINE — sliding-window scope (H.14 alone; prior INLINE was H.13).** Boundary-sensitive surface for reviewer focus:
- **v11.0 archive directory structure unchanged.** Verify `ls v11.0/` returns same set of subdirs as at H.0 baseline (modulo H.13's intra-file SCHEMA extension and H.14's intra-file INDEX extension — both permitted under D16 Convention Y).
- **v11.0/INDEX.md forward-reference footnote correctness.** Verify the footnote names v11.1 archive, phase-part-v11.1 entry type, D5 cancelled state, and D16 Convention Y per POQ-6 resolution.
- **v11.1 INDEX.md declares 6 entry-types.** Verify enumeration completeness; cross-references resolvable.
- **v11.1/forms/work-item.yml byte-identical to pack-root.** Verify `diff` empty (created byte-identically from H.2 per POQ-1; no H.14-refresh needed).
- **No leak into pack-internal references from archive content.** Templates-archive files are pack-internal but accessible to architect / docs-researcher; check they don't accidentally reference client-side paths or vice versa.

**Commit subject scope keyword:** `pack-only`. Per POQ-2 resolution 2026-05-26: `maintenance-docs/`-only commit; `pack-only` keyword deny-list (project-template/ + supporting-docs/) does not trip; precedent: commits `3a8b5ba` + `062cb8f` used `pack-only` for maintenance-docs/-only commits and CI passed.

**Commit message:** `feat: v11 — BD-185 templates-archive cross-references (v11.0 ↔ v11.1) (Batch 19d.14) (pack-only)`

**Pack-coder PREFLIGHT line shape:** `PREFLIGHT: 2/2 in-scope file edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.14.md`

**Ordering dependency:** MUST land AFTER H.2 (live work-item.yml exists for byte-identical archive copy) AND after H.13 (v11.0 phase-task-v11.0 SCHEMA cancelled-state extension landed — INDEX should reflect it if INDEX names extensions).

**Success criteria:**
1. v11.1 INDEX.md declares 6 entry-types with v11.0 cross-references.
2. v11.1/forms/work-item.yml byte-identical to pack-root `.github/ISSUE_TEMPLATE/work-item.yml` (already so from H.2 per POQ-1; no H.14-refresh needed).
3. v11.0/INDEX.md carries forward-reference footnote naming v11.1 archive + phase-part-v11.1 + D5 cancelled state + D16 Convention Y (per POQ-6 resolution 2026-05-26).
4. v11.0 archive directory structure unchanged (5 entry-type subdirs + forms + INDEX); only intra-file content extensions per D16 Convention Y.
5. `python3 scripts/validate-pack.py` exits 0.

---

### H.15 — Test infrastructure (template-version-test + tracker-init-test + per-entry sort fixture)

**Scope:** Per architect §14.9. EXTEND existing test files to add coverage for new template_version (phase-part-v11.1), new label provisioning (template:phase-part-v11.1), and new sort behavior (execution-order tuple). CREATE per-entry sort-order fixture under `scripts/tests/fixtures/per-entry-split/`.

**Files modified (~3-4 EXTEND/CREATE):**
- `scripts/tests/template-version-test.sh` (EXTEND — add phase-part-v11.1 to expected versions list)
- `scripts/tests/tracker-init-test.sh` (EXTEND — verify template:phase-part-v11.1 label provisioning)
- `scripts/tests/test-per-entry.sh` (EXTEND — add new sort-order test case)
- `scripts/tests/fixtures/per-entry-split/<bd-185-fixture>` (CREATE — new sort-order fixture demonstrating execution-order vs phase-number sort)

**Edit specification:**

Per architect §14.9:

1. **`template-version-test.sh` EXTEND:** Add `phase-part-v11.1` to the expected template_version values list. Verify the test passes the existing pattern (each known template_version has a known SCHEMA file).
2. **`tracker-init-test.sh` EXTEND:** Verify `tracker-init.sh` (per H.6) provisions `template:phase-part-v11.1` label. Add to expected-labels assertion list.
3. **`test-per-entry.sh` EXTEND:** Add test case for new sort behavior. Specifically: fixture with phases [phase-1, phase-2, phase-10] with execution-order values [3, 1, 2] should sort to [phase-2, phase-10, phase-1].
4. **Per-entry sort fixture (NEW):** Create `scripts/tests/fixtures/per-entry-split/<bd-185-fixture>/` with 3-4 phase-N.md files demonstrating execution-order sort vs lexical sort. Include README.md explaining the fixture purpose.

**Verification commands:**

```bash
python3 scripts/validate-pack.py
# Run extended tests:
bash scripts/tests/template-version-test.sh 2>&1 | tail -5
bash scripts/tests/tracker-init-test.sh 2>&1 | tail -5
bash scripts/tests/test-per-entry.sh 2>&1 | tail -5
# Verify fixture exists and is valid:
ls scripts/tests/fixtures/per-entry-split/
bash test-fixtures/build.sh --all --clean
git diff --stat test-fixtures/manifest.txt
```

**RC9 manifest regen:** REQUIRED. `scripts/` in v11-surface per BD-176.

**Per-commit reviewer:** **INLINE — sliding-window scope (H.15 alone; prior INLINE was H.14).** Boundary-sensitive surface for reviewer focus:
- **Test coverage completeness.** Verify new template_version + new label + new sort-key all have test coverage.
- **Fixture realism.** Verify the per-entry-split fixture demonstrates real-world out-of-birth-order execution scenario (matches architect §6.4 "Project with execution notes for re-ordered phases" worked example).
- **CI runs the extended tests.** Per Check 42 contract, tests must be wired in workflow — `template-version-test.sh` and `tracker-init-test.sh` are existing tests (presumably already wired); `test-per-entry.sh` extension is in-place; no new workflow wiring needed.

**Commit subject scope keyword:** `pack-only`. Only `scripts/` edits.

**Commit message:** `feat: v11 — BD-185 test infra (template-version, tracker-init labels, per-entry sort fixture) (Batch 19d.15)`

**Pack-coder PREFLIGHT line shape:** `PREFLIGHT: 4/4 in-scope file edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.15.md`

**Ordering dependency:** MUST land AFTER H.5 (tracker-phase-part.sh exists for the template_version test to verify), H.6 (tracker-init.sh provisions the new label), H.7 (per-entry sort behavior exists to be tested), and H.10 (new checks exist; per-check tests landed but H.10's tests are different from H.15's broader infra tests). Effectively H.15 is the LAST pre-close test-extension commit.

**Success criteria:**
1. `template-version-test.sh` admits `phase-part-v11.1` in expected versions.
2. `tracker-init-test.sh` verifies new label provisioning.
3. `test-per-entry.sh` exercises new sort behavior.
4. Per-entry-split fixture demonstrates execution-order sort vs lexical sort.
5. All extended tests exit 0.
6. `python3 scripts/validate-pack.py` exits 0.
7. `test-fixtures/manifest.txt` regenerated and staged.

---

### H.16 — End-of-batch reviewer + BD-185 status flip (single-BD batch close commit shape)

**Scope:** Per `pack-ops/PACK-CHAT.md` `## Behavioral rules` "Batch close commit shapes" + `feedback_implicit_status_flip` pack memory.

1. Run `pack-reviewer` (background spawn from Pack Chat) on full batch diff (HEAD at H.0 baseline `062cb8f` → HEAD at end of H.15).
2. Pack Chat triages findings per `feedback_fix_all_review_findings` (default fix-all; user triages per finding before fix-coder spawns).
3. If findings exist: spawn fresh fix-coder (background) per Pack Chat protocol; coder applies fixes and emits PREFLIGHT line + IMPL-REPORT.
4. Per single-BD batch close commit shape: COMBINE the fix commit and the BD-185 status flip into ONE final commit.
5. If NO fix findings: ship the BD-185 status flip as a standalone `docs: v11 — flip BD-185 to Resolved` commit.

**Reviewer prompt construction notes** (for Pack Chat — not for the coder):
- Reviewer reads ARCHITECTURE-BD-185.md as the design reference, NOT prior PACK-REVIEW-*.md reports (per `feedback_no_prior_reviews_to_reviewer`).
- Reviewer scope: full batch diff covers ~15 commits (H.1-H.15). Reviewer applies dimensions per `pack-ops/CONCEPTUAL-REVIEW-METHODOLOGY.md` including the H.15-extended dimension (d) Pack rule adherence (Check 43 verification active).
- Reviewer focus dimensions specific to BD-185:
  - **SC1-SC8 traceability.** Each SC has a code surface that ratifies it; reviewer verifies traceability.
  - **D1-D14 implementation fidelity.** Each LOCKED decision has a code surface; reviewer verifies no re-litigation.
  - **C-1 grammar consistency.** No empty-separator forms; no lowercase atoms; no numeric Part IDs.
  - **C-4 invariants INV-1..INV-9.** Phase numbers immutable, task IDs immutable, tracker entity IDs immutable, STATUS.md dashboard role preserved, etc.
  - **C-5 trinity rule + Override 9.** Where cross-CLI paths exist, audience-correct values applied; otherwise byte-identical.
  - **No solutions / no orphan refs / no leaks.** Per pack memory rules.

**BD-185 status flip mechanics:** Per `pack-ops/BACKLOG.md` BD-185 entry, change `Status: Open` → `Status: Resolved`; fill the `Resolved:` line with date + batch close commit SHA + summary of work delivered.

Summary text suggestion: `Resolved: 2026-05-DD — Batch 19d. v11.1 templates-archive cut (phase-part-v11.1 schema + form-family 5th wi-type + part-letter input) + Parts hierarchy (mid-work phase split via pack phase split; preserves task IDs; D2 no-collapse / D3 ≥1 task / D4 supersede-only / D12 LAZY v2 backfill) + execution-order mechanism (Issue Fields primary per D10 graphql; sub-issue-reprioritize fallback v11.1+ per D9; per-entry _order.md SSOT-derived view per D7; D8 historical-marker for stale execution notes) + 3 new provider ops (set_field/get_field/sub_issue_reprioritize per D11 tracker-phase-part.sh new lib) + bi-directional migrators forward+reverse + 5 new pack verbs (phase split/reorder, tracker phase split/reorder, task supersede) + 4 new CI checks (phase-part schema, exec-order marker, Part re-parentage, Part membership) + D5 cancelled-state extension to phase-task-v11.0 + 7-state task taxonomy.` Pack Chat customizes per actual close-date + commit SHA.

**Verification commands** (run by Pack Chat / reviewer; final batch verification):

```bash
# Final batch verification at HEAD after H.16 commits land:
python3 scripts/validate-pack.py
# 4 new checks active per H.10; existing checks extended; expect 47 checks PASSED.

bash test-fixtures/build.sh --verify
# Manifest matches all per-commit regenerations.

bash scripts/tests/test-validate-pack-check-{N..N+3}.sh
# New per-check tests from H.10 (exact numbers assigned at impl time).

bash scripts/tests/test-tracker-phase-part.sh
# Test for new lib from H.5.

bash scripts/tests/template-version-test.sh
# Extended in H.15 — phase-part-v11.1 admitted.

bash scripts/tests/test-per-entry.sh
# New sort-order fixture verified.

# Verify BD-185 status:
grep -A3 "^\*\*BD-185" pack-ops/BACKLOG.md | head -8
# Expected: Status: Resolved; Resolved: <date + SHA + summary>

# Verify v11.1 archive layout:
ls maintenance-docs/v11-research/templates-archive/v11.1/
# Expected: phase-part-v11.1/ forms/ INDEX.md

# Verify v11.0 archive frozen (no directory layout change):
ls maintenance-docs/v11-research/templates-archive/v11.0/
# Expected: same as H.0 baseline (bd-v11.0 forms INDEX.md inbound-v11.0 phase-epic-v11.0 phase-task-v11.0 td-v11.0)

# Verify CI:
gh run list --workflow validate-pack.yml --limit 1
# Expected: latest run conclusion = success.
```

**RC9 manifest regen:** Required IF the fix-commit modifies any v11-surface file. Pack Chat verifies via `git diff test-fixtures/manifest.txt` after `bash test-fixtures/build.sh --all --clean`; if non-empty, stage the manifest in the H.16 commit.

If H.16 is standalone status flip (no fixes), the commit touches only `pack-ops/BACKLOG.md` — RC9 fires per BD-176 4-directory trigger (`pack-ops/` in v11-surface). Coder/Pack Chat runs `bash test-fixtures/build.sh --all --clean`; if manifest diff is empty (BACKLOG.md is not fixture-affecting), no staging needed; if non-empty, stage the manifest.

**Per-commit reviewer:** END-OF-BATCH (this IS the end-of-batch reviewer pass). No further inline review attaches to H.16 — the reviewer pass at H.16 IS the inline review of the H.16 fix-commit (single review covers fix + the batch cumulative state).

**Commit subject scope keyword (commit-shape-dependent):**
- **If combined fix + status flip:** mixed scope likely (fixes may touch `project-template/` + `supporting-docs/` + `scripts/` + `pack-ops/`); use no keyword.
- **If standalone status flip on `pack-ops/BACKLOG.md` only:** `PM-only` (BACKLOG.md is PM-only per PACK-AGENTS.md).

**Commit message (commit-shape-dependent):**
- **If combined fix + status flip:** `fix: v11 — BD-185 broad batch review/fix + status flip (Batch 19d)`
- **If standalone status flip:** `docs: v11 — flip BD-185 to Resolved`

**Pack-coder PREFLIGHT line shape (if fix-coder spawns):** `PREFLIGHT: <N>/<N> in-scope file edits complete; verification PASS; HEAD <SHA>; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-185-Batch-19d-H.16-FIX.md`

(If H.16 is standalone status flip with no fix-coder spawn, Pack Chat applies the BACKLOG edit directly per PM-only files rule — no PREFLIGHT line required.)

**Ordering dependency:** RUN AFTER H.15. This IS the batch close. No subsequent commits in Batch 19d.

**Success criteria:**
1. End-of-batch reviewer pass completes (background spawn from Pack Chat).
2. All findings triaged by Pack Chat → user; fix-coder spawned for FIX-marked findings.
3. BD-185 status flipped Open → Resolved with appropriate `Resolved:` line.
4. `python3 scripts/validate-pack.py` exits 0 with 47 checks total.
5. All BD-185 per-check tests + extended tests exit 0.
6. CI run on push: conclusion = success.

---

## §6 — Planner observations (POQs) — ALL RESOLVED 2026-05-26

All 7 planner POQs were resolved during a Pack Chat decision-review session 2026-05-26. Two derivative architectural refinements (D15 + D16) emerged from the discussion. See §6a Decision log below for the full audit trail. The original POQ table is preserved in git history (planner's first emission at 'planner-pass complete') for audit purposes.

## §6a — Decision log (Pack Chat review session 2026-05-26)

| # | Decision | Source | Resolution | PLAN impact |
|---|---|---|---|---|
| POQ-1 | v11.1/forms/work-item.yml creation site | Planner POQ-1 | DEFERRED to H.2 (byte-identical from creation) | H.1 file count -1; H.2 file count +1 |
| POQ-2 | Scope keyword for maintenance-docs/-only commits (H.1, H.14) | Planner POQ-2 | `pack-only` keyword (precedent: 3a8b5ba, 062cb8f) | H.1 + H.14 commit subjects gain (pack-only) |
| POQ-3 | `pack-only` for scripts/-primary commits | Planner POQ-3 | CONFIRMED planner default; `pack-only` ALSO guardrails accidental /project-template/scripts/ touches | Clarification added to §5 |
| POQ-4 | `tracker-promote.sh` Path 2 extension | Planner POQ-4 | Extend Path 2 to admit `Phase-N.Part-x` target; NO new path; INV-6 preserved | H.6 edit specification refined |
| POQ-5 | `_order.md` emit site | Planner POQ-5 | NEW `_order-generate.sh` script (single-responsibility per file; consistent with POQ-7 original architect review) | H.7 file count +2 (NEW script + test) |
| POQ-6 | v11.0/INDEX.md forward-reference + H.13 SCHEMA tension | Planner POQ-6 | Convention Y: structural shape frozen + intra-file additive extensions allowed; BOTH H.13 SCHEMA extension AND H.14 INDEX forward-reference land | H.14 file count +1; D16 architect-doc edit |
| POQ-7 | 16-commit batch size | Planner POQ-7 | ACCEPTED planner default | No changes |
| D15 | Letter-suffix removal + task numbering rule | User-driven (POQ-4 discussion 2026-05-26) | Task grammar simplifies to `Task-M` integer only; task number ≠ execution order rule documented | Architect doc D15 edits + PLAN regex simplifications |
| D16 | Convention Y for v11.0 archive intra-file additive-extension | User-driven (POQ-6 discussion 2026-05-26) | Structural shape frozen + intra-file additive content allowed | Architect doc D16 edits |

All decisions are USER-LOCKED. No re-litigation in downstream commits.

---

## §7 — Final verification (post-H.16)

After H.16 lands successfully:

```bash
python3 scripts/validate-pack.py
# Expected exit code: 0 (47 checks total — 43 original + 4 new from H.10).

bash test-fixtures/build.sh --verify
# Expected: manifest matches all per-commit regenerations.

bash scripts/tests/test-tracker-phase-part.sh
# Expected exit code: 0 (new test file from H.5).

bash scripts/tests/template-version-test.sh
# Expected exit code: 0 (extended H.15).

bash scripts/tests/test-per-entry.sh
# Expected exit code: 0 (new sort-order fixture from H.15).

bash scripts/tests/test-validate-pack-check-42.sh
# Expected exit code: 0 (Check 42 PASSES — H.10 wired 4 new test files in workflow).

# BD-185 status:
grep -A3 "^\*\*BD-185" pack-ops/BACKLOG.md
# Expected: Status: Resolved; Resolved: <date + close commit SHA + summary>.

# v11.1 archive layout:
ls maintenance-docs/v11-research/templates-archive/v11.1/
# Expected: phase-part-v11.1/ forms/ INDEX.md

# v11.0 archive structure unchanged:
ls maintenance-docs/v11-research/templates-archive/v11.0/
# Expected: bd-v11.0 forms INDEX.md inbound-v11.0 phase-epic-v11.0 phase-task-v11.0 td-v11.0

# CI run (manual trigger or auto on push):
gh run list --workflow validate-pack.yml --limit 1
# Expected: latest run conclusion = success.

# Filename uniqueness preserved:
find . -name "tracker-phase-part.sh" -not -path "./.git/*" | wc -l
# Expected: 1 (the new file).
find . -name "pack-phase.sh" -not -path "./.git/*" | wc -l
# Expected: 1.
find . -name "_order.md" -not -path "./.git/*" | wc -l
# Expected: ≥1 (the new per-entry supporting file in implementation-plan tree post-H.7).
```

`pack-ops/CHANGELOG.md` may receive a v11.1 cut entry at version-boundary close per Pack Chat protocol; not necessarily in H.16 itself (per architect §14.8 note: "NOT a BD-185 work item; pack memory `feedback_pack_chat_does_no_fixes` restricts; planner notes").

---

## §8 — Risks (carried from architect §1.5 + §15)

- **Risk-1: Issue Fields preview-status drift.** GitHub Issue Fields was in public preview at architect-time (2026-03-12 announce; 2026-05-21 all-orgs). API may change between preview + GA. Mitigation per D6: VERIFY-AT-IMPLEMENTATION-TIME (coder confirms GraphQL mutation/query names against current docs at H.4 commit time).
- **Risk-2: D9 Forgejo/Gitea fallback shipping in v11.1+ creates a v11.0-only-GH constraint.** v11.0 ships pure GH implementation; non-GH trackers cannot use BD-185 features in v11.0. Per architect §5.2: "non-github backends are RESERVED" — acceptable scope reduction for v11.0; v11.1+ pass extends.
- **Risk-3: 25-field-per-org cap interaction with future Issue-Fields-consuming features.** BD-185 uses 1 slot; future features (BD-189 groupings; other v11.1+ features) compete for slots. Per architect §9.4: groupings architect aware; budgets at v11.1+ design time.
- **Risk-4: D5 cancelled-state extension to v11.0 SCHEMA archive interacts with the "v11.0 frozen" architect invariant.** Per POQ-6 in §6 — surfacing for user direction.
- **Risk-5: Issue Fields name-collision with non-pack-controlled orgs.** Capability-detection at tracker init per D13 provides fallback name (`Pack Execution Order`). User edits `tracker.toml` if they need a third name (advanced operation).
- **Risk-6: gh CLI version-pin sensitivity** despite D10 `gh api graphql` routing. `gh api graphql` itself is `gh` CLI subcommand; if `gh` CLI changes the `api graphql` interface, BD-185 ops break. Mitigation: D6 VERIFY-AT-IMPLEMENTATION-TIME + tracker-doctor checks.
- **Risk-7: Migrator structured warning template (H.8) verbosity** if many phases carry execution notes. Per architect §6.3a + D8: default is verbose context-rich warnings. User can suppress with `<!-- execution-note-status: historical -->` marker per-phase post-migration.

---

*End of PLAN-BD-185.*
