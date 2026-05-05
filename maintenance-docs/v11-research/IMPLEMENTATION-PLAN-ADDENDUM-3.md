# IMPLEMENTATION-PLAN-ADDENDUM-3 — v11.0

## §0. Status

- Date: 2026-05-05
- Scope: closes 2 narrow gaps after PLAN (BD-060..BD-093) + ADDENDUM 1 (BD-094..BD-101) + ADDENDUM 2 (BD-102..BD-103).
- Adds: **BD-104** (cross-pack rename `IMPLEMENTATION_PLAN.md` → `IMPLEMENTATION-PLAN.md`) + **BD-105** (STATUS.md phase-row dual-link rendering in tracker mode).
- Updates: base plan §3.3 (two lettered insertions); §7 release-readiness (3 new checkboxes); §6 — none new (no ambiguities found this pass).
- Constraints honored: §6.J stays (a) flat-file at v11.0 cut; STATUS.md dual-link uses **Option A** middle-dot inline rendering; rename mechanism is **`git mv`** (history-preserving); 4 edge cases dispositioned per maintainer-confirmed decisions.
- Highest BD now: **BD-105** (verified by enumerating BD-NNN literals across PLAN + ADDENDUM + ADDENDUM-2 + `BACKLOG.md`).
- Acyclic. BD-104 blockers: BD-085 + BD-091 (Phase A migrator script + relocation precedent). BD-105 blockers: BD-065 + BD-067 + BD-068 + BD-066 + BD-084. No new cycles.

---

## §1. New BDs

### §1.1 BD-104 — Cross-pack rename `IMPLEMENTATION_PLAN.md` → `IMPLEMENTATION-PLAN.md`

**Type:** Refactor / forced v10→v11 client change (Scope B ride-along).

**File/Symbol.**

Pack repo (renamed via `git mv`; precedent: BD-091 BD-042 relocation):
- *(no actual `IMPLEMENTATION_PLAN.md` file ships in the pack — verified by `find project-template -name 'IMPLEMENTATION_PLAN*'`; the rename is purely a reference/string change in pack content, plus a `git mv` instruction emitted by the v10→v11 client migrator.)*

Pack repo (modified — string references; enumerated by `grep -rn "IMPLEMENTATION_PLAN"` minus archives):

Project-template trinity (trinity-replicated × 3):
- `project-template/CLAUDE.md` line 198 (`## Document locations` table row).
- `project-template/AGENTS.md` line 182 (same row).
- `project-template/GEMINI.md` line 193 (same row).

Project-template prompts (6 files; consumed by every CLI surface):
- `project-template/docs/pack/prompts/pm-chat.md` (lines 52, 162, 166).
- `project-template/docs/pack/prompts/architect.md` (lines 25, 35, 56).
- `project-template/docs/pack/prompts/planner.md` (line 16).
- `project-template/docs/pack/prompts/coder.md` (lines 14, 18, 52, 63, 129, 166).
- `project-template/docs/pack/prompts/reviewer.md` (line 21).
- `project-template/docs/pack/prompts/docs-researcher.md` (line 18).

Project-template pack reference:
- `project-template/docs/pack/PM-CHAT.md` (lines 122, 161, 162, 250, 276, 320, 354, 396).
- `project-template/skills/pm-startup/SKILL.md` (line 77).

Pack-root supporting docs:
- `supporting-docs/METHODOLOGY.md` (16 occurrences: lines 113, 124, 128, 247, 288, 331, 372, 414, 461, 474, 520, 542, 549, 579, 794, 1040, 1112, 1180, 1272, 1294, 1354).
- `supporting-docs/SETUP-NEW.md` (line 389).
- `supporting-docs/SETUP_TEMPLATE.md` (line 220).
- `supporting-docs/CLI-PM-SETUP.md` (lines 147, 179).
- `supporting-docs/INSTALL-PROCEDURES.md` (line 1216).
- `supporting-docs/MIGRATION-v9-to-v10.md` (line 600 — historical reference; **do not rewrite history; leave as-is** since this doc describes the v9→v10 migration as it shipped).
- `supporting-docs/MIGRATION-v8-to-v9.md` (lines 625, 652 — historical reference; **leave as-is**).

Pack-root state files:
- `BACKLOG.md` lines 748, 760, 817 (BD-027 / BD-029 / BD-030 prose mentioning the file).
- `CHANGELOG.md` line 112 (v10 entry F-A.2 prose — historical; **leave as-is**).

Maintenance docs (active, non-archive):
- `maintenance-docs/TOOL-COMPARISON.md` (lines 185, 191).

HELP-FRAGMENT (BD-076):
- Any HELP-FRAGMENT file that names the four-doc list (verified at BD-076 land-time; if absent, no edit). Likely appears in `HELP-FRAGMENT-pack-tracker.md` and `HELP-FRAGMENT-pm-chat.md` but **MAINTAINER CHECK at BD-076 land-time**: re-run `grep -l IMPLEMENTATION_PLAN HELP-FRAGMENT-*.md` after BD-076 ships and add to this BD's scope before commit.

Scripts:
- `scripts/init-project.sh` — verified zero hits today; **re-run grep at BD-080 land-time**: BD-080 may add references during init-project's extension to v11. If any land, BD-104 updates them.
- `scripts/migrate-v10-to-v11.sh` (BD-085 / Phase A) and `scripts/lib/migrate-v10-to-v11/*` (BD-095) — **must add a `git mv IMPLEMENTATION_PLAN.md IMPLEMENTATION-PLAN.md` step** in Phase A for client repos that have the file under VCS at the legacy path. This is the consumer that performs the rename in client repos at upgrade time.
- `scripts/validate-pack.py` — verified zero hits today; if BD-082's Check 22 (verb freshness) or any new check references the filename literal, update accordingly. **MAINTAINER CHECK at BD-082 land-time.**

Out-of-scope archives (do not touch — historical record):
- `maintenance-docs/archive/V10-*.md`, `V9-DESIGN.md`, `v10-working/*`. These are frozen historical artifacts.

**Description.** The pack uses hyphenated all-caps for top-level Markdown filenames (BACKLOG.md, CHANGELOG.md, README.md, MIGRATION-v9-to-v10.md, MIGRATION-v10-to-v11.md, MERGE-STRATEGY.md, OPTIONAL-FEATURES.md, PACK-CHAT.md, etc.). `IMPLEMENTATION_PLAN.md` is the only underscore outlier. v11 is the right cut to fix this because (a) it is already a forced client migration, (b) the file is rarely renamed mid-version, (c) every other v11 ride-along (BD-091 BD-042 relocation) sets the precedent for `git mv` plus cross-reference sweep.

**Mechanism.**
1. Pack-side string sweep: every active reference in pack content updated in one commit. The greps above are exhaustive for the active surface.
2. Client-side rename: `migrate-v10-to-v11.sh` Phase A (BD-085 + BD-095) emits `git mv docs/project/IMPLEMENTATION_PLAN.md docs/project/IMPLEMENTATION-PLAN.md` after confirming the file exists at the legacy path. History is preserved (precedent: BD-091).
3. Idempotency: if the file already exists at the new path (re-run; manually renamed; not present at all), `git mv` is skipped silently with a stdout note. If both paths exist, surface typed error per BD-070 (`migration-rename-collision`); halt; user resolves manually. If the file is not under VCS, fall back to `mv` with a warning that history is not preserved; surface non-fatal warning.

**Failure mode (A1 escape-hatch consistency).** Per MERGE-STRATEGY §2.3, `git mv` failures are an A1 surface: emit `*.merge-conflict` companion is **not** the right pattern here (this is a rename, not a content merge). Instead, the migrator halts at the rename step with a typed error, prints the two competing paths, and instructs the user to resolve manually then run `--resume` (BD-095). The BD-101 Gate-2 checkpoint records the rename as "pending" or "completed".

**Description (continued — trinity rule).** The trinity Document locations table row update is trinity-replicated × 3 (CLAUDE / AGENTS / GEMINI). All three files must change in the same commit per `CLAUDE.md` trinity rule. Same applies to the pack-root copies if they ever name the file (verified today: zero hits in pack-root CLAUDE/AGENTS/GEMINI).

**Definition-of-Done.**
- Every active-content reference updated; archives untouched.
- `grep -rn "IMPLEMENTATION_PLAN" project-template/ supporting-docs/ scripts/ BACKLOG.md HELP-FRAGMENT-*.md 2>/dev/null` returns **zero matches** post-commit (excluding `MIGRATION-v9-to-v10.md`, `MIGRATION-v8-to-v9.md`, `CHANGELOG.md` historical entries — explicit allowlist).
- `grep -rn "IMPLEMENTATION-PLAN" project-template/` returns matches at every previously-affected line (proves the substitution landed everywhere).
- `migrate-v10-to-v11.sh` Phase A includes a `git mv` step (BD-085/BD-095 extension); test fixture exercises the rename on a v10-shape input.
- BD-101 Gate 2 (post-Phase-A) includes a check: file exists at `docs/project/IMPLEMENTATION-PLAN.md` and not at the legacy path.
- Trinity Document locations row identical across 3 files (Check 18 verifies).
- CI green.

**Test.**
- `scripts/tests/test-migrate-v10-to-v11.sh` (extends BD-085 test) — fixture has `docs/project/IMPLEMENTATION_PLAN.md`; after `--apply`, asserts new path exists, old path absent, `git log --follow` shows pre-rename history.
- Collision case: fixture pre-creates both paths; assert migrator halts with typed error.
- BD-101 Gate-2 fail-path test: rename collision triggers Gate 2 fail.

**Blockers.** BD-085 (the migrator script the rename step extends); BD-091 (BD-042 relocation precedent for `git mv` in Phase A); BD-076 (HELP-FRAGMENT files must exist before being string-swept); BD-070 (typed-error code `migration-rename-collision`).

**Risks.** (R-104.1) A reference is missed in active content and surfaces post-release as a stale link — mitigated by the exhaustive grep in DoD and by Check 22 (BD-082) cross-reference sweep. (R-104.2) The historical-allowlist line drifts (someone edits `MIGRATION-v9-to-v10.md` to use the new name retroactively) — documented in BD-104 commit message that historical migration docs are frozen.

---

### §1.2 BD-105 — STATUS.md phase-row dual-link rendering (tracker mode)

**Type:** Feature extension to tracker forward / reverse / round-trip (Scope A).

**File/Symbol.**
- `scripts/lib/tracker-migrate-forward.sh` (modified — extends BD-065) — STATUS.md regen step (V1 §6.5 step 6 / mirror regen per V1 §6.3) gains dual-link rendering when `tracker.toml mode.state = "tracker"` AND the phase resolves to a tracker epic.
- `scripts/lib/tracker-migrate-reverse.sh` (modified — extends BD-067) — STATUS.md emit step (V1 §6.5 step 6) strips ` · [#N](URL)` patterns to restore single-link form.
- `scripts/lib/pack-tracker/doctor.sh` (modified — extends BD-066) — emits warnings for orphan phase (epic missing in tracker) and multiple-epic match.
- `scripts/tests/tracker-migrate-roundtrip-test.sh` (modified — extends BD-068) — fixture exercises dual-link round-trip; flat-file form is byte-equivalent (whitespace-tolerant); tracker form restores dual-link.
- `scripts/tests/fixtures/roundtrip/bd-v11.0/STATUS.md` (modified) — fixture shape includes a phase row with dual-link in tracker mode.
- `supporting-docs/MIGRATION-v10-to-v11.md` (modified — extends BD-084) — Phase B section adds a paragraph: "When tracker mode is active, STATUS.md phase-row titles render as `[Phase Title](IMPLEMENTATION-PLAN.md#anchor) · [#N](issue-URL)`. The dual-link is regenerated on every chat-side write (V1 §6.3 mirror behavior); direct edits are overwritten — edit via PM Chat. `pack tracker disable` strips the dual-link to restore the original single-link form."
- *(STATUS.md template: there is no shipped `project-template/STATUS.md` template file — verified by `find project-template -name 'STATUS*.md'` returning zero hits. STATUS.md is created at project init via PM-chat-driven setup per `METHODOLOGY.md`. Documentation of the dual-link rendering lives in `MIGRATION-v10-to-v11.md` Phase B and in V1 §6.3 reference, not in a template file. **MAINTAINER CHECK NEEDED §6.L** — see §2.3.)*

**Description.** Per maintainer-confirmed decision: STATUS.md phase rows in tracker mode render dual-link in **Option A** middle-dot inline format. When in flat-file mode, STATUS.md phase rows continue to render the single flat-file link — unchanged from v10.

**Exact rendering format (Option A — verbatim).**

```markdown
| # | Phase | Status |
|---|-------|--------|
| 3 | [Auth Refactor](./docs/project/IMPLEMENTATION-PLAN.md#phase-3-auth-refactor) · [#42](https://github.com/owner/repo/issues/42) | In Progress |
```

- Bare `#42` link text (no "Issue " prefix).
- ` · ` (space-middle-dot-space) separator between the two links.
- Flat-file link first; tracker link second.
- Note: file path uses the post-BD-104 hyphenated name `IMPLEMENTATION-PLAN.md`.

**Rendering logic (forward / mirror regen, V1 §6.3, BD-065).**

```
For each phase row in STATUS.md regen:
  flat_link = "[<phase title>](./docs/project/IMPLEMENTATION-PLAN.md#<anchor>)"
  if tracker.toml.mode.state == "tracker":
    epic = lookup_phase_epic(phase_anchor)  # from .pack-tracker/phase-mapping.json
    if epic and epic.count == 1:
      tracker_link = "[#<N>](<issue_url>)"
      cell = flat_link + " · " + tracker_link
    elif epic and epic.count > 1:
      cell = flat_link  # warn in doctor (BD-066): "multiple epics match phase X"
    else:
      cell = flat_link  # warn in doctor: "orphan phase X — no epic"
  else:
    cell = flat_link
```

**Reverse-migration behavior (BD-067).** STATUS.md emit at V1 §6.5 step 6 detects ` · [#\d+]\([^)]+\)` regex pattern in any phase row title cell; strips it; preserves the leading flat-file link unchanged. Round-trip is **byte-equivalent on flat-file form** (whitespace-tolerant per V1 §6.7) AND **dual-link is restored on re-forward** when mapping is preserved.

**Edge case dispositions (per maintainer-confirmed decisions).**

1. **Orphan phase** (epic missing in tracker). Render flat-file link only. `pack tracker doctor` (BD-066) reports the missing epic with phase title and anchor. Doctor exit code: warning (non-fatal). Documented in `MIGRATION-v10-to-v11.md` Phase B troubleshooting.
2. **Multiple epics for one phase**. Render the marker-matched epic's link (the one whose body contains the phase-anchor marker per V1 §4.3). Doctor surfaces warning: "phase X matches N epics; using marker-matched #M".
3. **User direct edits to STATUS.md in tracker mode**. Overwritten on next regen (consistent with V1 §6.3 mirror-file read-only contract). Documented in `MIGRATION-v10-to-v11.md` Phase B with an explicit warning note: "Tracker mode: STATUS.md is a regenerated mirror — edit via PM Chat, not directly."
4. **Closed phase-epic**. Link still renders (history is preserved; closed issues remain reachable via URL). The `Status` column conveys completion separately (e.g., `Done`); the link is not a status indicator.

**Bidirectionality contract (V1 §6.0).** BD-105's dual-link is **tracker-only enrichment**. The flat-file v10 grammar does not contain the `[#N](URL)` annotation; reverse strips it; round-trip is byte-equivalent on flat-file content. The mapping file (`.pack-tracker/phase-mapping.json`) preserves the phase→epic association across reverse→re-forward cycles. Re-forward restores the dual-link from the mapping. Mapping loss → orphan phase fallback (case 1) — non-fatal degradation, doctor reports.

**Definition-of-Done.**
- Forward (BD-065) regen produces dual-link for matched phases in tracker mode; single-link in flat-file mode.
- Reverse (BD-067) strips ` · [#N](URL)` from STATUS.md cleanly.
- Round-trip test (BD-068) fixture: flat-file → forward → tracker STATUS.md has dual-link → reverse → flat-file STATUS.md byte-equivalent (whitespace-tolerant) to the original. Re-forward restores dual-link.
- Doctor (BD-066) emits warnings for orphan phase + multi-epic match; exit code non-fatal.
- MIGRATION-v10-to-v11.md Phase B paragraph present; cross-references V1 §6.3 mirror behavior.
- General-use audit: no OT/Optiquity strings in any user-facing rendering example or prose.
- CI green.

**Test.**
- `scripts/tests/tracker-migrate-roundtrip-test.sh` extension: fixture has 4 phases — one matched 1:1, one orphan, one multi-epic (2 matches with one marker-matched), one closed. Assert exact rendered output for each case in tracker mode; assert single-link form in flat-file mode after reverse; assert byte-equivalence of flat-file form across round-trip.
- `scripts/tests/test-tracker-doctor.sh` extension: orphan + multi-epic warnings emit on stderr with phase identifiers.

**Blockers.** BD-065 (forward / mirror regen — the entry point); BD-067 (reverse strip); BD-068 (round-trip test fixture); BD-066 (doctor warning emission); BD-084 (MIGRATION doc Phase B paragraph).

**Risks.** (R-105.1) Regex strip in reverse mis-matches a user-authored ` · [#N](URL)` pattern that happens to appear in non-phase prose — mitigated by scoping the strip to phase-table title cells only (parse Markdown table; do not blanket-replace). (R-105.2) Mapping file loss across reverse→re-forward causes silent dual-link absence on re-forward — mitigated by doctor orphan-phase warning surfacing the gap loudly.

---

## §2. Updates to base plan

### §2.1 §3.3 commit-order integration (insertions only)

The base plan §3.3 is steps 1..34. Addendum 1 inserted lettered steps (19a, 20a, 22a, 22b, 30a, 30b, 33a). Addendum 2 inserted 33b, 33c. Addendum 3 inserts two more:

- **After step 9 (BD-068 round-trip test), insert step 9a: BD-105 — STATUS.md phase-row dual-link rendering.** Rationale: BD-105 extends BD-065 (forward), BD-067 (reverse), BD-068 (round-trip test). All three are in place by step 9; BD-105 lands as a coherent extension to all three at once. Lands before BD-066 step 10 is wrong — BD-066 is step 7, already landed; BD-105's doctor extension piggybacks on the existing BD-066 doctor surface.
- **After step 22b (BD-101 validation gates), insert step 22c: BD-104 — cross-pack rename `IMPLEMENTATION_PLAN.md` → `IMPLEMENTATION-PLAN.md`.** Rationale: BD-104's `git mv` step extends `migrate-v10-to-v11.sh` Phase A (BD-085 step 22) and is wired into BD-101 Gate 2 (step 22b). Landing at 22c places it right after the migrator + gates exist, and before BD-081 trinity addenda (step 23) — which need to reflect the new filename in any cross-references they add. Pack-side string sweep (the bulk of BD-104) lands in the same commit as the migrator extension.

Updated tail of §3.3 (illustrative; full edit lands when this addendum is approved):

```
... 9. BD-068 — round-trip test
    9a. BD-105 — STATUS.md dual-link rendering (forward + reverse + round-trip + doctor extensions)
10. BD-069
... 22. BD-085
    22a. BD-095
    22b. BD-101
    22c. BD-104 — cross-pack rename + Phase A git mv step
[CP3 audit — BD-100 report]
23. BD-081
... 33. BD-087
    33a. BD-097
    33b. BD-103
    33c. BD-102
34. BD-093
```

CI green at every numbered + lettered boundary. Commit at 9a leaves validate-pack green (no schema changes; new fixture cases pass; rendering logic gated on `tracker.toml mode.state`). Commit at 22c leaves validate-pack green (`grep IMPLEMENTATION_PLAN` returns only allowlisted historical files; trinity Check 18 still passes since all 3 files change in the same commit).

### §2.2 §7 release-readiness checklist additions

Append to the existing `## §7. Definition of v11.0 release-readiness` checklist (after Addendum 2's additions):

- [ ] **BD-104 cross-pack rename complete**: `find project-template supporting-docs scripts -name 'IMPLEMENTATION_PLAN.md'` returns zero matches; `grep -rn 'IMPLEMENTATION_PLAN' project-template/ supporting-docs/ scripts/ BACKLOG.md HELP-FRAGMENT-*.md` returns zero matches outside the historical allowlist (`MIGRATION-v9-to-v10.md`, `MIGRATION-v8-to-v9.md`, `CHANGELOG.md` v10 entry); `migrate-v10-to-v11.sh` Phase A `git mv` step verified against BD-085 fixture; trinity Document locations row identical across CLAUDE/AGENTS/GEMINI.
- [ ] **BD-104 history preserved**: `git log --follow docs/project/IMPLEMENTATION-PLAN.md` on the migrator-test fixture shows pre-rename commits.
- [ ] **BD-105 dual-link verified end-to-end**: round-trip test fixture (`scripts/tests/tracker-migrate-roundtrip-test.sh`) covers four cases (1:1 match, orphan, multi-epic, closed); flat-file round-trip is byte-equivalent (whitespace-tolerant); tracker form restores dual-link on re-forward; doctor warnings emit for orphan + multi-epic; MIGRATION-v10-to-v11.md Phase B paragraph present and accurate.
- [ ] **General-use audit (Addendum 3 scope)**: `grep -i "OT\|Optiquity"` returns zero hits in BD-104-modified content (excluding archives) and in BD-105 rendering examples / prose.

### §2.3 §6 MAINTAINER CHECK NEEDED additions

Append to §6 of the base plan (Addendum 1 ends at §6.I; Addendum 2 ends at §6.K):

- **§6.L — STATUS.md template provenance.** No `project-template/STATUS.md` template ships today (verified by `find project-template -name 'STATUS*.md'` → zero hits). STATUS.md is created at project init by PM-chat-driven setup per `METHODOLOGY.md`. BD-105 documents the dual-link rendering in `MIGRATION-v10-to-v11.md` Phase B and relies on V1 §6.3 mirror-file behavior; no template file is created. Options:
  - (a) **Keep current state (proposed).** Documentation lives in MIGRATION-v10-to-v11.md Phase B and V1 §6.3; no new template file. Rendering is determined by the regen script (BD-065) and tested by the round-trip fixture (BD-068).
  - (b) Introduce a `project-template/docs/project/STATUS.md` template at v11.0 that includes a documentation comment block explaining dual-link rendering. Adds a shipped artifact; conflicts with current `METHODOLOGY.md` setup procedure (PM-chat creates STATUS.md).
  - **Recommendation: (a).** No new template file. Maintainer confirms at BD-105 land-time.

---

## §3. Verification additions

### §3.1 New / extended tests

- **`scripts/tests/tracker-migrate-roundtrip-test.sh`** (extended by BD-105) — fixture grows to include 4 phase cases (1:1, orphan, multi-epic, closed). Assertion set: rendered Markdown for tracker form matches Option A literal; rendered Markdown for flat-file form matches v10 single-link literal; round-trip diff = 0 (whitespace-tolerant) on flat-file form; re-forward restores dual-link.
- **`scripts/tests/test-tracker-doctor.sh`** (extended by BD-105) — orphan-phase + multi-epic warnings emit on stderr with structured identifiers.
- **`scripts/tests/test-migrate-v10-to-v11.sh`** (extended by BD-104) — fixture has `docs/project/IMPLEMENTATION_PLAN.md`; after `--apply`, asserts new path exists, old path absent, `git log --follow` shows continuous history. Collision case: pre-create both paths; assert halt with typed error `migration-rename-collision`.

### §3.2 Effect on §4.4 CI gate count

No new top-level test scripts; existing scripts grow assertions. CI gate count at v11.0 cut remains as Addendum 2 leaves it.

### §3.3 Cross-reference grep additions for §4.2 (validate-pack)

Check 22 (BD-082, help-fragment freshness) implicitly catches stale `IMPLEMENTATION_PLAN` references in HELP-FRAGMENT files; no Check renumbering needed. If BD-082 is implemented as a string-list of "current verbs / file names", add `IMPLEMENTATION-PLAN.md` to that list and remove `IMPLEMENTATION_PLAN.md` — **a one-line edit that lands as part of BD-104's commit at step 22c.**

---

## §4. Open risks / unknowns

- **(R-Add3.1)** HELP-FRAGMENT files do not yet exist (BD-076 is upstream). The BD-104 grep enumeration above reflects HEAD; post-BD-076, the grep must be re-run before BD-104 land-time and any new hits added to the BD-104 sweep. BD-104's DoD makes this explicit.
- **(R-Add3.2)** `init-project.sh` may grow references during BD-080's v11 extension. Re-grep at BD-080 land-time; if hits, fold into BD-104 (BD-080 is step 21; BD-104 is step 22c; ordering correct).
- **(R-Add3.3)** Mapping file (`.pack-tracker/phase-mapping.json`) format is not specified in V1 — V1 §6.5 step 5 mentions phase epic emit but not a separate mapping file. **MAINTAINER CHECK NEEDED at BD-105 land-time**: is the mapping derivable from epic-body markers alone (V1 §4.3), or is a separate `phase-mapping.json` needed? If derivable, no new file ships. Recommendation: derive from markers; do not introduce a new state file.
- No new cycles introduced. Acyclic per §0.

---

**End of Addendum 3.** Total: 2 BDs added (BD-104, BD-105). Highest BD now BD-105. Base plan §3.3 gains 2 lettered insertions (9a, 22c). §7 gains 4 checkboxes. §6 gains 1 MAINTAINER CHECK item (§6.L).
