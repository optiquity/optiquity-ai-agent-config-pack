# PACK-REVIEW — BD-214 COMMIT C2 (pack-side surface sweep)

**Reviewer:** pack-reviewer (fresh spawn). **Date:** 2026-06-13.
**HEAD:** `bd06a9635c23d7df8f03fff30c6448c2acebde16` (branch `v11-dev`; C1 already landed) +
the C2 working-tree change set. **Read-only except this report.**
**Inputs read in full:** CLAUDE.md (incl. all `## Pack memory`), PLAN-BD-214-TRACKER-DEFERRAL.md,
ARCHITECTURE-BD-214-TRACKER-DEFERRAL.md (both pages — §4 Axis E/F, §6.6), every changed file
via `git diff` + direct read.

## VERDICT: CLEAN — APPROVE

The C2 pack-side surface sweep correctly presents flat-file per-entry as the sole v11.0 mode
and tracker as deferred/dormant across every swept surface, without dropping legitimate
content, breaking a still-true statement, or breaking flat-file behavior. The full wired CI
battery is GREEN (validate-pack general + DEEP + all 55 wired test scripts, every EXIT=0;
manifest regen clean). Both surfaced deviations are CORRECT. No BLOCKER / MUST / SHOULD
findings. Two NITs (non-blocking, both arguably out of C2 scope).

---

## Deviation adjudications (the two the prompt requires)

### DEVIATION 1 — heading-marker tokens retained in `_rules.md` files: **CORRECT (required by CI)**

The coder kept the literal substrings "Flat-file mode" + "Tracker mode" in
`backlog/_rules.md` and "Mode invariance" in `changelog/_rules.md`, rewording only the
bodies. This is REQUIRED, not optional:

- `scripts/validate-pack.py:3326-3329` defines `_RULES_MODE_MARKERS = {"pack-backlog":
  ("Flat-file mode", "Tracker mode"), "pack-changelog": ("Mode invariance",)}`.
- Check 32′ (`check_mirror_in_sync`, lines 3415-3436) FAILs the gate if any required marker
  substring is absent: *"missing required mode marker(s) … restore the marker heading(s)"*.
- Verified present in the working tree: `grep -c 'Flat-file mode' backlog/_rules.md` → 1,
  `grep -c 'Tracker mode' backlog/_rules.md` → 1, `grep -c 'Mode invariance' changelog/_rules.md` → 1.
- `python3 scripts/validate-pack.py` → EXIT 0 (Check 32′ passes). Removing the tokens would
  turn CI red.

The markers are now `**Flat-file mode (the sole supported mode).**` and
`**Tracker mode (deferred).**` (backlog) / `**Mode invariance.**` (changelog) — token
present, body truthful. The coder correctly distinguished the CI-pinned token from the
prose. **Verdict: keeping the headings is correct; changing them would break Check 32′.**

### DEVIATION 2 — `PACK-MEMORY-RATIONALE.md` (3 occ) + `BOUNDARY-DEFINITION.md` (2 occ) NOT edited: **CORRECT skip**

Design §4 Axis E listed these for "mechanical deferral rewording," but Axis E's own
governing rule (architecture §2) is *"It is UPDATE iff it is prose presenting tracker as
USABLE."* I independently read all 5 occurrences. None presents tracker MODE as usable; a
"(deferred)" qualifier would be inaccurate noise on each. Per-occurrence verdicts:

| File:line | Quoted occurrence | Verdict |
|---|---|---|
| PACK-MEMORY-RATIONALE.md:144 | "BD-193 commit `85196d4` removed `pack-ops/HELP-FRAGMENT-TRACKER.md` from the inventory but didn't update …test-43…" | SKIP CORRECT — a historical worked-example FILENAME ref about a validator-inventory incident; not tracker-mode usability. |
| PACK-MEMORY-RATIONALE.md:462 | "BD-135 renamed the colliding `tracker.toml.example` pair" | SKIP CORRECT — filename ref in a filename-uniqueness worked example; nothing about mode usability. |
| PACK-MEMORY-RATIONALE.md:489 | "`pack-ops/HELP-FRAGMENT-TRACKER.md` (`scripts/init-project.sh` stage S11 copies to client `docs/pack/`)" | SKIP CORRECT — a STILL-TRUE fact about which files are fixture-affecting (the stub still ships via S11); editing it would make a true statement false. |
| BOUNDARY-DEFINITION.md:43 | "C2 \| PACK × OPERATIONS \| …`pack-ops/HELP-FRAGMENT-TRACKER.md`, `pack-ops/OPTIONAL-FEATURES.md`…" | SKIP CORRECT — a boundary-CLASS membership table; the file is still a C2 pack-ops file. Still true. |
| BOUNDARY-DEFINITION.md:110 | "`tracker.toml.pack-example` \| Per user-curation direction…sufficient authority." | SKIP CORRECT — the boundary-exempt-root allowlist; the file stays COMMITTED + exempt (design D-D). Still true. |

The coder applied the architect's property-fit test ("prose presenting tracker as usable"),
not a blind mechanical pass. This is the higher-fidelity reading of the design intent and
avoids contaminating accurate historical/classification prose. **Verdict: the skip is
correct; no required edit was missed.** The coder also surfaced this deviation explicitly
in the IMPL-REPORT (deviation #2), satisfying surface-don't-silently-apply.

---

## What was verified (independent re-measurement)

**Meaning preserved, tracker-as-usable removed — every swept surface:**

- **Root trinity ×3** (CLAUDE.md / AGENTS.md / GEMINI.md): the "Per-entry trees — sole SSOT"
  bullet drops the Mode-3 contract prose and adds the 2-sentence deferral note; the "Resolved
  section" bullet drops its tracker-mode write-channel arm; the "Project goals v11" first
  bullet flips to "flat-file per-entry is the sole supported mode; tracker integration is
  deferred (no version)". All three edits are parallel (audience-correct, format-neutral).
  Matches §4 Axis E exactly.
- **`backlog/_rules.md`**: "Source of truth" section rewritten flat-file-only; the
  "Published tree + single writing authority" tracker-mode subsection correctly DELETED;
  field-faithful paragraph KEPT with format-neutral justification; "Write authority" section
  collapsed to the single flat-file procedure. All 8 section headings preserved (`Stream
  identity / Source of truth / Filename convention / ID-extraction rule / Entry contract /
  Lifecycle states admitted / Supporting files / Write authority`) — no section silently
  dropped. Matches §4 Axis A.
- **`backlog/_intro.md`**: mode pointer → deferral wording; updated cross-ref to the renamed
  `_rules.md` heading ("Source of truth — flat-file (no monolith)"). Correct.
- **`changelog/_rules.md`**: "Mode invariance" body → "flat-file unconditionally" + deferral.
  Correct.
- **`pack-ops/PACK-CHAT.md`**: read-table row reworded; "Backlog write paths by mode (Mode-3
  operations)" → "Backlog write paths" (10-item Mode-3 procedure → 5-item flat-file
  procedure); "Recommendation routing (v11+)" → "Recommendation routing (deferred)". Matches
  §4 Axis E.
- **`pack-ops/HELP-FRAGMENT-TRACKER.md`**: rewritten as deferred stub, heading "Tracker
  commands (deferred)"; verb TOKENS RETAINED (`pack tracker init` … named as refusing) so
  Checks 22/23 stay green. Matches §4 Axis F.
- **`pack-ops/HELP-FRAGMENT-PACK.md`**: tracker verb rows get "(deferred — BD-214; verbs
  refuse)"; section heading → "Tracker commands (deferred)". Correct.
- **`pack-ops/OPTIONAL-FEATURES.md`**: walkthrough REPLACED by a short deferred section
  ("What it was / Why deferred / What ships today"); no opt-in steps remain. Matches §4 Axis F.
- **`README.md`**: v11.0 version-table row reworded "deferred (dormant) — BD-214"; layout rows
  for tracker files annotated "(dormant, deferred per BD-214)". Matches §4 Axis F.
- **`QUICKSTART.md`**: tracker opt-in pointer → deferral wording. Correct.
- **`scripts/pack-td.sh`**: promote Path-1/Path-2 prose tracker-mode usability → "deferred"
  (the GAP-4 prose half; typo fix landed at C1). Correct.
- **pack-startup skills ×3** (.claude / .codex / .gemini): Step-8 body → 3-line deferred note,
  step number kept; byte-identical across the three (correct — these are skill files, the
  per-CLI invocation differs but the body is shared text). Strips 3 of 7 leg-3 occurrences.
- **`scripts/tests/pack-help-test.sh`**: 2.1 assertion updated to the new correct heading
  ("# Tracker commands (deferred)") — lock-step, not weakened.

**`changelog/v11.md` vs §6.6 literal:** EXACT match. `git diff` shows only: H3 title →
`### v11.0 — Flat-file per-entry model + customization-preservation fix`; Scope-A H4 →
`**Scope A — Issue-tracker integration (D-1..D-23) — DEFERRED / DORMANT in v11.0**`; the
blockquote preface inserted verbatim. D-1..D-23 inventory preserved verbatim:
`diff <(git show HEAD:changelog/v11.md | grep '^- D-') <(grep '^- D-' changelog/v11.md)` →
NO DIFF. History not erased.

**Trinity parity:** rationale-slug sets identical across CLAUDE.md / AGENTS.md / GEMINI.md
(`diff` of `rationale:` slugs → identical for both pairs). `## Pack memory` slug set
UNCHANGED vs HEAD (no rule added/removed) → no PACK-MEMORY-RATIONALE bijection /
.spawn-rule-manifest / anti-restate propagation required. validate-pack trinity-parity
checks (16/18/19/31/45/46) all PASS.

**Check 51 unchanged at legs 1/2/4:** `scripts/validate-pack.py` is NOT in the C2 diff
(`git diff --name-only` does not list it). Check 51 still asserts only legs 1/2/4. Correct:
leg 3 (`recommendation_should_recommend == 0` outside allowlist) measures 4 remaining
(pm-startup ×4, stripped at C3) — adding leg 3 at C2 would fail. validate-pack output:
*"Legs 3/5 land in later commits with their fix-recipes."*

**pack-only scope:** `git diff --name-only | grep -E '^(project-template|supporting-docs)/'`
→ ZERO matches. Scope claim valid.

**Pre-existing `M backlog/BD-214.md`:** confirmed it carries ONLY the pre-existing 2026-06-12
dated note (planner HEAD note), NOT a C2 surface edit. It is pack-chat-only state (not under
project-template/ or supporting-docs/), so it does not violate the pack-only keyword even if
it rides the commit. See NIT-2.

**Cross-reference integrity (renamed headings):** grep for the OLD heading strings
("mode-dependent (no monolith", "Backlog write paths by mode", "Mode-3 operations") across
the tree (excluding maintenance-docs/) → the only hit is a SELF-CONTAINED test fixture
(`test-validate-pack-checks-32-33-34.sh:200`, "## Source of truth — mode-dependent (test
fixture)") that builds its own synthetic `_rules.md` and asserts marker PRESENCE only — it is
independent of the real heading name and needs no edit. No stale cross-references remain.

---

## Full wired-test results (every wired script, NO sampling)

Extracted the complete run-command list from `.github/workflows/validate-pack.yml` (both
jobs) and ran each. ALL EXIT=0.

```
validate-pack general (python3 scripts/validate-pack.py)            EXIT=0  → "PASSED — all checks clean"
validate-pack DEEP    (PACK_VALIDATE_DEEP=1 …)                      EXIT=0  → "PASSED — all checks clean"
```

Wired test scripts (55 total), all EXIT=0:
```
0  test-detect.sh                          0  tracker-provider-test.sh
0  tracker-config-test.sh                  0  tracker-init-test.sh
0  tracker-agent-read-test.sh              0  tracker-migrate-forward-test.sh
0  tracker-migrate-reverse-test.sh         0  tracker-migrate-roundtrip-test.sh
0  test-tracker-phase-task.sh              0  test-tracker-links.sh
0  test-tracker-cycle-check.sh             0  tracker-errors-test.sh
0  tracker-config-schema-test.sh           0  recommendation-state-schema-test.sh
0  test-per-entry.sh                       0  test-validate-pack-checks-32-33-34.sh
0  test-validate-pack-checks-36-37-38.sh   0  test-validate-pack-check-39.sh
0  test-validate-pack-check-40.sh          0  test-validate-pack-check-41.sh
0  test-validate-pack-check-18.sh          0  test-validate-pack-check-16.sh
0  test-validate-pack-check-19.sh          0  test-validate-pack-check-42.sh
0  test-validate-pack-check-43.sh          0  test-validate-pack-check-44.sh
0  test-validate-pack-check-45.sh          0  test-validate-pack-check-46.sh
0  test-validate-pack-check-removed-doc-advisory.sh
0  test-validate-pack-check-49-field-faithfulness.sh
0  test-validate-pack-check-50-codec-single-source.sh
0  test-validate-pack-check-51-flip-block.sh
0  tracker-deferral-gate-test.sh           0  tracker-bd129-gh-repo-test.sh
0  tracker-bd130-doctor-wired-test.sh      0  tracker-bd132-race-test.sh
0  tracker-bd133-header-preservation-test.sh  0  tracker-bd134-close-retry-test.sh
0  recommendation-test.sh                  0  pack-help-test.sh
0  test-customization-preserve.sh          0  test-init-project.sh
0  test-migrate-v10-to-v11.sh              0  test-migrate-v10-to-v11-dry-run.sh
0  test-migrate-v10-to-v11-gates.sh        0  test-migrate-v10-to-v11-decompose.sh
0  test-migrator-core.sh                   0  test-migrator-manifest.sh
0  test-migrator-capability-translation.sh 0  test-v11-realistic-ot.sh
0  test-migrator-skills.sh                 0  test-persona-contracts.sh
0  template-translations-test.sh           0  template-version-test.sh
0  test-issue-forms.sh
```

**GAP-5 (empirical Checks 22/23 re-run):** satisfied — `pack-help-test.sh` (Checks 22/23
fragment freshness/completeness pins) PASSES with the rewritten deferred stub; the retained
verb tokens keep them green, confirmed by RUN not by assertion. Integration
`test-v11-realistic-ot.sh` (BD-203-lesson validator-OUTPUT-pinning surface) PASSES.

**Manifest:** `bash test-fixtures/build.sh --all --clean` → EXIT 0;
`git diff --quiet test-fixtures/manifest.txt` → NO DIFF. The `regenerate-manifest-v11-surface`
rule is satisfied: C2 touches `pack-ops/` + `scripts/`, the regen produced an empty diff
(swept files are not v11-* fixture-tree members), so there is nothing to stage.

---

## Findings

### BLOCKER — none.
### MUST — none.
### SHOULD — none.

### NIT-1 (non-blocking; out of C2 scope) — README "45 invoked checks" count is now stale.
`README.md:60` still reads "validate-pack.py expanded to 45 invoked checks". C1 added Check 50
(dedicated test) and Check 51, so the live count is higher. This is C1 scope, not C2 (C2's
README edit is only the tracker-row reword), and the design did not assign the count refresh
to C2. No CI check pins this number. Recommend Pack Chat track it for the C1 retro or a later
README pass — do NOT expand C2 scope to fix it. file:line `README.md:60`.

### NIT-2 (non-blocking; staging hygiene) — `backlog/BD-214.md` will appear in C2's diff.
The pre-existing 2026-06-12 dated note on `backlog/BD-214.md` is uncommitted and will show in
`git status` at C2 commit time. It is NOT a C2 edit. It is pack-chat-only (not
project-template/supporting-docs), so it does not trip the `pack-only` Check-36 keyword.
Recommend Pack Chat commit C2 by NAMED pathspecs (the 19 C2 surface files), leaving
`backlog/BD-214.md` out of the C2 commit, so the dated note lands on its own pack-chat-only
channel and C2's audit trail stays surface-pure. No correctness impact either way.

---

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|
| 1. Agents never commit | Git verbs this session: `git rev-parse HEAD`, `git status --short`, `git diff` (×N read-only), `git show HEAD:…`, `git diff --quiet`. Zero `add/commit/push/tag/reset`. The one `git checkout HEAD -- test-fixtures/manifest.txt` from the workflow list was NOT run (manifest diff was already empty; no restore needed). | COMPLIANT |
| 2. Read-only mandate | Sole write: this report at the prompt-specified path `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/maintenance-docs/v11-implementation/PACK-REVIEW-BD-214-C2.md`. `test-fixtures/build.sh --all --clean` rewrote manifest.txt then verified NO DIFF (idempotent regen, tree unchanged); no other file edited. | COMPLIANT |
| 3. Independent verification (full wired-test run) | Every PASS above carries the command + quoted output: validate-pack general/DEEP EXIT=0 with "PASSED — all checks clean"; all 55 wired scripts EXIT=0 (table quoted); manifest regen NO DIFF. Marker presence, leg-3 count (4), scope grep (0), parity diff (identical) all re-measured by command. | COMPLIANT |
| 4. Real-fixes-only enforcement | Hunted meaning-changes/dropped content: `_rules.md` 8-section structure preserved (`grep '^## '` before/after); D-1..D-23 verbatim (`diff` NO DIFF); v11.md change is ONLY the 2 heading lines + preface (`git diff` non-blockquote changes quoted); pack-help-test assertion UPDATED to correct prose not weakened. Check-32′ markers KEPT (not deleted to pass). No band-aids found. | COMPLIANT |
| 5. Severity-tagged findings + deviation verdicts | BLOCKER/MUST/SHOULD = none; 2 NITs with file:line + fix. Deviation 1 = CORRECT (Check 32′ `_RULES_MODE_MARKERS:3326` requires the tokens). Deviation 2 = CORRECT skip (all 5 occurrences quoted with per-occurrence verdict; none present tracker mode as usable). | COMPLIANT |
| 6. Rules-Applied Verification Block | This table; per-rule quoted evidence; zero empty cells. | COMPLIANT |
| 7. PREFLIGHT + STOP-MEANS-STOP | Emitted `PREFLIGHT: review complete; full CI wired-test job run … about to Write <path>` in the turn immediately before this write. No stop/halt/revert message received. | COMPLIANT |

**Read-in-full attestation.** Read directly via tools this session, complete: CLAUDE.md
(full, incl. all `## Pack memory`, via system context); PLAN-BD-214-TRACKER-DEFERRAL.md
(full, 499 lines); ARCHITECTURE-BD-214-TRACKER-DEFERRAL.md (full, both pages — 853 lines,
incl. §4 Axis E/F, §6.6 literal block, §9, §10, §11, §14a); every changed file via `git diff`
+ direct read (root trinity ×3, backlog/_rules.md, backlog/_intro.md, changelog/_rules.md,
changelog/v11.md, PACK-CHAT.md, HELP-FRAGMENT-TRACKER.md, HELP-FRAGMENT-PACK.md,
OPTIONAL-FEATURES.md, README.md, QUICKSTART.md, pack-startup ×3, pack-td.sh, pack-help-test.sh);
plus the 5 Deviation-2 occurrences in PACK-MEMORY-RATIONALE.md + BOUNDARY-DEFINITION.md;
relevant validate-pack.py Check 32′ + Check 51 sections. No prior PACK-REVIEW / IMPL-REPORT
was used for judgment. No named document was derived rather than read.

**End of PACK-REVIEW-BD-214-C2.md**
