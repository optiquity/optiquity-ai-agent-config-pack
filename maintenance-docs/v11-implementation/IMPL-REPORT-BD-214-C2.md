# IMPL-REPORT — BD-214 COMMIT C2 (pack-side surface sweep)

**Author:** pack-coder (fresh spawn). **Date:** 2026-06-13.
**Branch:** `v11-dev`. **HEAD at start + end (read-only session, no commits):**
`bd06a9635c23d7df8f03fff30c6448c2acebde16`.
**Spec:** `PLAN-BD-214-TRACKER-DEFERRAL.md` §6 (C2) + `ARCHITECTURE-BD-214-TRACKER-DEFERRAL.md`
§4 Axis E/F, §5, §6.6. **Scope keyword (for Pack Chat's commit):** `pack-only`.

## Result summary

- **18 in-scope files edited** (all pack-side; ZERO under `project-template/` or
  `supporting-docs/`). One extra path (`backlog/BD-214.md`) shows in `git diff` but is a
  PRE-EXISTING working-tree change from before this session (a +1-line dated note); I did
  NOT touch it.
- **Full CI wired-test suite GREEN locally: 59/59 PASS, 0 FAIL** (all 58 run-commands from
  `.github/workflows/validate-pack.yml` `validate` + `tests` jobs, plus `PACK_VALIDATE_DEEP=1`).
- **Check 51 still asserts ONLY legs 1/2/4** (leg 3 NOT added — correct for C2; C2 strips only
  pack-startup ×3 of the 7 leg-3 occurrences, so leg-3's `== 0` is not yet true).
- **Trinity parity:** root `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` edited together; the three
  edited bullets are byte-identical across all three (pack-side audience-neutral text).
- **changelog/v11.md §6.6 literal substitution:** live lines MATCHED the architect's quoted
  "current text" exactly — applied verbatim, no drift.
- **Manifest:** regenerated (`bash test-fixtures/build.sh --all --clean`, exit 0); diff EMPTY
  (nothing to stage).

## Per-task edit inventory

| # | File | Change type | Edit |
|---|---|---|---|
| 1 | `CLAUDE.md` | modified | "Per-entry trees — sole SSOT" bullet → flat-file-only + deferral note (Mode-3 contract prose deleted); "Resolved section" bullet drops tracker write-channel arm; "Project goals (v11)" first bullet → flat-file-sole/tracker-deferred. |
| 2 | `AGENTS.md` | modified | Same three edits (trinity parity, same commit). |
| 3 | `GEMINI.md` | modified | Same three edits (trinity parity, same commit). |
| 4 | `backlog/_rules.md` | modified | "Source of truth — mode-dependent (no monolith in either mode)" → "Source of truth — flat-file (no monolith)": flat-file-only paragraph + short "Tracker mode (deferred)" paragraph; DELETED the "Published tree + single writing authority" tracker arm + the tracker-mode regenerated-mirror paragraph; field-faithful paragraph justification reworded format-neutral; "Write authority" mode-dependent intro + tracker bullet → flat-file-only. |
| 5 | `backlog/_intro.md` | modified | Mode pointer paragraph → flat-file-sole + deferral; re-pointed to the renamed `_rules.md` § heading. |
| 6 | `changelog/_rules.md` | modified | "Mode invariance" §: body reworded to flat-file-unconditional + deferral; the literal marker token **"Mode invariance"** RETAINED (Check 32′ requires it — see deviations). |
| 7 | `changelog/v11.md` | modified | §6.6 literal old→new: H3 title `Issue-tracker integration` → `Flat-file per-entry model`; Scope-A H4 + inserted deferral blockquote preface; D-1..D-23 bullets kept verbatim. |
| 8 | `pack-ops/PACK-CHAT.md` | modified | "Backlog write paths by mode (Mode-3 operations)" → "Backlog write paths" (flat-file procedure + deferral note; tracker bullets removed; re-pointed to renamed `_rules.md` §); file-access table per-entry row reworded; "Recommendation routing (v11+)" → "Recommendation routing (deferred)" (D-19 prose replaced by deferral note). |
| 9 | `pack-ops/HELP-FRAGMENT-TRACKER.md` | modified | Rewritten as deferred STUB: heading "Tracker commands (deferred)"; all 10 `pack tracker <verb>` TOKENS retained as *refusing* (Check 22); `set up the tracker` colloquial mapping retained (pack-help-test pin); TD-promotion + colloquial sections kept. |
| 10 | `pack-ops/HELP-FRAGMENT-PACK.md` | modified | Tracker script rows annotated "(DEFERRED — BD-214; verbs refuse)"; "## Tracker commands (v11+)" → "## Tracker commands (deferred)". |
| 11 | `pack-ops/OPTIONAL-FEATURES.md` | modified | "## Tracker integration (v11)" walkthrough (≈98 lines) → "## Tracker integration (deferred)" short section (what it was / why deferred / what ships today; no opt-in steps). |
| 12 | `README.md` | modified | v11.0 version-table row reworded ("deferred (dormant) — BD-214" + flat-file-sole); 7 layout rows for tracker files annotated "(dormant, deferred per BD-214)". |
| 13 | `QUICKSTART.md` | modified | :43 tracker opt-in pointer → deferral wording. |
| 14 | `.claude/skills/pack-startup/SKILL.md` | modified | Step 8 BODY → 3-line deferred note (step NUMBER kept; strips 1 of 7 leg-3 occurrences). |
| 15 | `.codex/skills/pack-startup/SKILL.md` | modified | Same Step-8 strip. |
| 16 | `.gemini/commands/pack-startup.toml` | modified | Same Step-8 strip. |
| 17 | `scripts/pack-td.sh` | modified | Two usage-text `in tracker mode` clauses (Path 1 / Path 2 help) reworded to "(tracker mode is deferred — BD-214; flat-file is the supported mode)". (Typo fix already landed in C1 — not redone.) |
| 18 | `scripts/tests/pack-help-test.sh` | modified | Lock-step: 2.1 pack-side assertion `# Tracker commands (v11+)` → `# Tracker commands (deferred)` to match the rewritten pack stub. (Project-side 2.2/2.2.b assertions left intact — the project fragment is unchanged at C2; it is rewritten at C3.) |

pack-startup Step 8 strips 3 of 7 leg-3 (`recommendation_should_recommend`) occurrences
(pack-startup ×3). The pm-startup ×4 are stripped at C3 (project-side), where leg 3 is added.

## changelog/v11.md §6.6 application (US-2)

Measured live lines at HEAD (`changelog/v11.md` lines 4 + 6) BEFORE editing:

```
### v11.0 — Issue-tracker integration + customization-preservation fix

**Scope A — Issue-tracker integration (D-1..D-23)**
```

These EXACTLY MATCH the architect's quoted "Measured current text" / OLD block in §6.6 — no
drift. Applied the §6.6 NEW substitution verbatim (two heading lines + the inserted blockquote
preface; the blank line between preserved; D-1..D-23 bullets untouched). Validate-pack +
changelog stream checks (Check 32′/33/34) green post-edit.

## Trinity parity confirmation

Root trinity edited in the same change set. The three edited bullets are byte-identical across
`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` (verified by signature greps: "Flat-file per-entry is
the SOLE supported" → 1/1/1; "tracker integration is" → 1/1/1; "Flip in the per-entry file" →
present line 491/457/424 respectively, identical text). These bullets are pack-side
audience-neutral, so byte-identity is correct (no cross-CLI normalization needed — none of the
edited text references per-CLI paths/commands). validate-pack Checks 16/18 (trinity H2 +
structure parity, pack-root) PASS; Check 11 (trinity-rule symmetry) informational, unchanged.

No `## Pack memory` rule SLUG was added/removed/renamed — both edited bullets are
deferral-rewording of existing rules WITHOUT `[rationale: slug]` tags. Bijection / anti-restate
/ rule-manifest UNCHANGED; validate-pack confirms green. No rule-propagation procedure needed.

## Full CI wired-test results (Rule 5 — no sampling)

Extracted every `run: (bash|python3) …` step from BOTH the `validate` and `tests` jobs of
`.github/workflows/validate-pack.yml` (58 commands) and ran each, plus `PACK_VALIDATE_DEEP=1
python3 scripts/validate-pack.py`. CI-only steps `pip install pyyaml` and `git checkout HEAD --
test-fixtures/manifest.txt` were not run (env/git-state; the latter is a forbidden git verb).

**Aggregate result (quoted from the run harness):**

```
TOTAL run (incl deep): 59   PASS=59  FAIL=0
FAILURES:
(none)
```

Spot-confirmations of the C2-relevant checks/tests:
- `python3 scripts/validate-pack.py` → `PASSED — all checks clean` (exit 0).
- `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` → exit 0.
- Check 22 (help-fragment freshness) — green: all prose-referenced verb tokens present in the
  rewritten stub (`pack tracker` + every `pack tracker <verb>` retained).
- Check 23 (completeness) — green (pack-tracker.sh / tracker-migrate.sh still listed).
- Check 32′ — green: `backlog/_rules.md` carries both markers ("Flat-file mode", "Tracker
  mode"); `changelog/_rules.md` carries "Mode invariance".
- Check 40 (bare cross-ref scanner) — green after qualifying the 3 refs I introduced.
- Check 51 — green, asserts ONLY legs 1/2/4 (banner: "flip-block guard (legs 1/2/4)").
- `scripts/tests/pack-help-test.sh` — green (the updated 2.1 assertion + the unchanged
  project-side 2.2/2.2.b assertions all pass).
- `scripts/tests/test-validate-pack-check-51-flip-block.sh` — green (still asserts legs 1/2/4).
- `scripts/tests/test-v11-realistic-ot.sh` — green.

## Manifest diff (Rule 6)

`bash test-fixtures/build.sh --all --clean` → exit 0. `git diff --stat test-fixtures/manifest.txt`
→ NO change (the swept prose edits do not alter manifested fixture content). Nothing to stage.

## pack-only scope proof (Rule 8)

`git diff --name-only` (working tree):

```
.claude/skills/pack-startup/SKILL.md
.codex/skills/pack-startup/SKILL.md
.gemini/commands/pack-startup.toml
AGENTS.md
CLAUDE.md
GEMINI.md
QUICKSTART.md
README.md
backlog/BD-214.md        <- PRE-EXISTING working-tree note; NOT my edit
backlog/_intro.md
backlog/_rules.md
changelog/_rules.md
changelog/v11.md
pack-ops/HELP-FRAGMENT-PACK.md
pack-ops/HELP-FRAGMENT-TRACKER.md
pack-ops/OPTIONAL-FEATURES.md
pack-ops/PACK-CHAT.md
scripts/pack-td.sh
scripts/tests/pack-help-test.sh
```

Filter `^(project-template|supporting-docs)/` → ZERO matches. `pack-only` Check 36 will pass.

## Plan deviations (4 — all in-scope-preserving, surfaced not silently applied)

1. **changelog/_rules.md "Mode invariance" marker retained (Check 32′ encoding-surface).**
   The plan said rewrite the "Mode invariance" § to "flat-file in all cases". `validate-pack.py`
   Check 32′ `_RULES_MODE_MARKERS["pack-changelog"] = ("Mode invariance",)` requires the literal
   heading token `Mode invariance` in `changelog/_rules.md`. Dropping the token would FAIL Check
   32′, and editing the validator is OUT OF C2 scope (validator changes are C1/C3). I kept the
   `**Mode invariance.**` lead token and reworded the BODY to flat-file-unconditional +
   deferral. Same for `backlog/_rules.md`: Check 32′ requires markers `("Flat-file mode",
   "Tracker mode")` — both retained (my "Flat-file mode (the sole supported mode)" and "Tracker
   mode (deferred)" lead tokens). Meaning preserved (no band-aid; Rule 2).

2. **PACK-MEMORY-RATIONALE.md (3 occ) + BOUNDARY-DEFINITION.md (2 occ) NOT edited.**
   The plan listed these for "mechanical deferral rewording". On inspection, NONE of the
   "tracker" mentions present tracker MODE as usable: PACK-MEMORY-RATIONALE.md occurrences are
   (a) `:144` a historical worked-example naming `HELP-FRAGMENT-TRACKER.md` (a still-valid
   pack-ops file), (b) `:462` a historical worked-example naming `tracker.toml.example` (BD-135
   rename history), (c) `:489` a still-accurate fact (init S11 copies the fragment — now a
   stub). BOUNDARY-DEFINITION.md occurrences are (a) `:43` a directory list naming
   `HELP-FRAGMENT-TRACKER.md` as a pack-ops doc (still accurate), (b) `:110` `tracker.toml.pack-example`
   (a committed file, still present). The other "opt-in" mentions in BOUNDARY-DEFINITION.md
   (`:89`, `:125`) are the Check-37 labeled-block convention — UNRELATED to the tracker.
   Per design §2/§4 ("UPDATE only where prose says usable") + Rule 2 (preserve meaning, no
   band-aids), forcing a "(deferred)" qualifier onto historical filename references or unrelated
   "opt-in" prose would be inaccurate. I made NO change to these two files and surface this for
   Pack-Chat/reviewer confirmation. (If the reviewer disagrees, point me at the SPECIFIC line +
   the usable-claim it makes and I will reword it.)

3. **README "tracker.toml.project-example" layout row.** I annotated "(dormant, deferred per
   BD-214)" only — I did NOT add "no longer installed to client root", because the install-map
   removal lands at C3 (init-project.sh STILL installs the example at the C2 boundary).
   Asserting the removal here would be a not-yet-true claim. Same restraint applied to
   `OPTIONAL-FEATURES.md` "What ships today" (reworded to avoid claiming the C3 install removal).

4. **3 Check-40 bare cross-refs introduced by my new prose were qualified in-line** (not a plan
   deviation per se, a required lock-step fix): `HELP-FRAGMENT-TRACKER.md` `OPTIONAL-FEATURES.md`
   → `pack-ops/OPTIONAL-FEATURES.md`; `OPTIONAL-FEATURES.md` `init-project.sh` →
   `scripts/init-project.sh`; `PACK-CHAT.md` `recommendation.sh` → `scripts/lib/recommendation.sh`.
   Also fixed a self-introduced Check-22 false token (`` `pack\ntracker` `` wrapped across a
   line break in OPTIONAL-FEATURES.md → kept the backticked token on one line) and trimmed the
   tracker stub by 2 lines to clear a per-doc length ADVISORY (58→56; advisory only, not a gate).

## New POQs introduced

None beyond deviation #2 (the rationale/boundary "tracker" mentions that are historical /
unrelated rather than usable-claims), which is surfaced above for confirmation.

## Out-of-scope items surfaced (touched NOTHING)

- §6.6 architect text refers to "the C3 coder" applies `changelog/v11.md` — that is the
  architect's OLD numbering; under the plan's renumber the changelog reword is **C2** (plan §6
  line 221 confirms `changelog/v11.md` is in C2). Applied here as instructed; flagging the
  stale "C3" wording in the architect doc only as a note.
- Check 51 legs 3/5: NOT added (C3). Install-map removal: NOT done (C3). 93-doc deletion: NOT
  done (C4). Backlog ENTRY re-scopes: NOT done (C5a/C5b). pm-startup ×4 / PM-CHAT / project
  trinity / DEPENDENCIES / MIGRATION / METHODOLOGY / project `_intro` ×3: NOT touched (C3).

## Definition-of-Done checklist

| Item | Status |
|---|---|
| All C2 pack-side surfaces swept to flat-file-only + deferral note | PASS |
| changelog/v11.md §6.6 literal substitution applied (matched, no drift) | PASS |
| HELP-FRAGMENT-TRACKER.md rewritten as deferred stub; verb tokens retained | PASS |
| HELP-FRAGMENT-PACK.md tracker rows → "(deferred)" | PASS |
| pack-startup Step 8 ×3 → deferred note (step number kept; strips leg-3 ×3) | PASS |
| pack-td.sh tracker-mode prose → deferred (typo NOT re-touched) | PASS |
| Lock-step test (pack-help-test.sh) updated to rewritten stub | PASS |
| Trinity ×3 edited together with parity | PASS |
| Check 51 still legs 1/2/4 only (leg 3 NOT added) | PASS |
| validate-pack.py general + DEEP green | PASS |
| FULL CI wired-test suite green (59/59, no sampling) | PASS |
| Manifest regenerated; diff empty | PASS |
| `git diff --name-only` zero project-template/ + supporting-docs/ files | PASS |
| No git state changes (read-only verbs only) | PASS |
| No section dropped (in-place edits; H2 counts verified) | PASS |

## Files changed inventory

All `modified` (no new/deleted files among my edits):
`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `backlog/_rules.md`, `backlog/_intro.md`,
`changelog/_rules.md`, `changelog/v11.md`, `pack-ops/PACK-CHAT.md`,
`pack-ops/HELP-FRAGMENT-TRACKER.md`, `pack-ops/HELP-FRAGMENT-PACK.md`,
`pack-ops/OPTIONAL-FEATURES.md`, `README.md`, `QUICKSTART.md`,
`.claude/skills/pack-startup/SKILL.md`, `.codex/skills/pack-startup/SKILL.md`,
`.gemini/commands/pack-startup.toml`, `scripts/pack-td.sh`, `scripts/tests/pack-help-test.sh`.
(`backlog/BD-214.md` is a pre-existing working-tree change, NOT mine.)

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted) | Conclusion |
|---|---|---|
| 1. Agents never commit | Git verbs this session: `git rev-parse HEAD`, `git status`, `git diff [--name-only/--stat]`, `git show HEAD:<file>` (read). Zero `add/commit/push/tag/reset/stash/checkout/rm`. HEAD unchanged `bd06a96…` start→end. | COMPLIANT |
| 2. Real fixes only — no band-aids | Deferral rewording preserves meaning; flat-file fully working (validate-pack + all 59 tests green). Check-32′ marker tokens KEPT (not deleted to pass) — see deviation #1. pack-help-test 2.1 assertion UPDATED to the new correct prose (lock-step), not weakened. | COMPLIANT |
| 3. Trinity parity same-commit | Root trinity ×3 edited together; signature greps 1/1/1; Checks 16/18 pack-root PASS. | COMPLIANT |
| 4. Cross-CLI reference normalization | Edited trinity text references no per-CLI path/command → byte-identical is correct; no normalization applicable. | N/A: no per-CLI references in the edited text |
| 5. Verify the FULL CI suite — no sampling | Extracted all 58 `run:` commands from validate-pack.yml `validate`+`tests` jobs + DEEP; ran every one; `TOTAL run (incl deep): 59 PASS=59 FAIL=0`. | COMPLIANT |
| 6. Regenerate manifest on v11-surface commits | pack-ops/ + scripts/ touched → `bash test-fixtures/build.sh --all --clean` exit 0; `git diff --stat test-fixtures/manifest.txt` EMPTY. | COMPLIANT |
| 7. Edit in place, not full rewrite | All edits targeted string/section replacements (HELP-FRAGMENT-TRACKER.md was a designated stub rewrite per plan). H2 counts re-verified vs HEAD: backlog/_rules.md 8→8, changelog/_rules.md 8→8, PACK-CHAT.md 10 H2s, OPTIONAL-FEATURES.md 5. No section dropped. | COMPLIANT |
| 8. pack-only scope | `git diff --name-only` filtered `^(project-template|supporting-docs)/` → ZERO. | COMPLIANT |
| 9. Rules-Applied Verification Block | This table; per-rule quoted evidence; no empty cells. | COMPLIANT |
| 10. PREFLIGHT + STOP-MEANS-STOP | Emitted `PREFLIGHT: 19/19 in-scope edits complete; FULL CI wired-test job verified locally (59/59 PASS incl PACK_VALIDATE_DEEP); HEAD bd06a96…; about to Write IMPL-REPORT …` immediately before this Write. No stop/halt/revert received. | COMPLIANT |

**Read-in-full attestation.** Read directly via tools this session, complete: `CLAUDE.md`
(full, incl. all `## Pack memory`, via system context); `PLAN-BD-214-TRACKER-DEFERRAL.md`
(full, 499 lines incl. Revision log + §6 C2 + green-per-commit table); `ARCHITECTURE-BD-214-TRACKER-DEFERRAL.md`
(§§1-509 read directly incl. Update log / §3 / §4 Axis E/F / §5 / §6.1-§6.6 — the C2-relevant
sections; §§510-853 are §7 GH-deletion + §8-§14 which are C4/C5/held-deletion, out of C2 scope);
`pack-ops/PACK-CHAT.md` (full, incl. "Backlog write paths" + D-19 + rule-propagation procedure);
plus every file edited (read in full before editing). No named C2-scope document was derived
rather than read.

**End of IMPL-REPORT-BD-214-C2.md**
