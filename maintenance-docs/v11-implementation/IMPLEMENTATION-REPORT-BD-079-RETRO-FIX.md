# IMPLEMENTATION-REPORT-BD-079-RETRO-FIX

**Agent:** `pack-coder`
**Batch:** 21c — retroactive review-fix for BD-079 (`check_recommendation_state_schema`, validate-pack.py Check 30)
**Date:** 2026-05-15
**Branch:** `v11-dev`
**HEAD SHA at session start:** `ea9fabee65e6c64419d8888af2c17ef22943540b`
**HEAD SHA at session end (worktree):** `ea9fabee65e6c64419d8888af2c17ef22943540b` (no commits — agents never commit)

---

## 1. Scope summary

Retro review (`maintenance-docs/v11-implementation/PACK-REVIEW-BD-079-RETRO.md`) produced 4 findings against original commit `91a9fc5`:

| Finding | Severity | Status entering this session | This session |
|---|---|---|---|
| F-1 | MUST | Already closed by commit `304078f` (CI wiring fix — cross-BD) | Verified closed; no action |
| F-2 | SHOULD | Open | Closed (rationale docstring per reviewer's option (a)) |
| F-3 | NIT | Open | Closed (docstring corrected) |
| F-4 | NIT | Already closed by commit `614e67e` (BACKLOG path-rewrite Pattern B sweep) | Verified closed; no action |

In-scope this session: F-2 + F-3. Both edits land in `scripts/validate-pack.py` and are tightly scoped to Check 30's surface (top-of-file docstring entry at lines 95–105 + `check_recommendation_state_schema` function docstring at lines 2467–2496). No other Check touched.

---

## 2. Pre-flight verification

Confirmed F-1 is already closed:
```
$ grep -n "recommendation-state" .github/workflows/validate-pack.yml
151:      - name: recommendation-state-schema tests (BD-079, validate-pack Check 30)
153:        run: bash scripts/tests/recommendation-state-schema-test.sh
```

Confirmed F-4 is already closed:
```
$ sed -n '336p' BACKLOG.md | grep -o "archive/v11/IMPLEMENTATION-REPORT-BD-078-BD-079.md"
archive/v11/IMPLEMENTATION-REPORT-BD-078-BD-079.md
```
(BACKLOG entry now points at the archive path, not the dangling `v11-implementation/` path.)

Baseline verifications (before edits):
```
$ python3 scripts/validate-pack.py | tail -1
PASSED — all checks clean
$ bash scripts/tests/recommendation-state-schema-test.sh | tail -3
=== Summary ===
PASS: 19
FAIL: 0
```

---

## 3. F-3 (NIT) — Docstring fix at top-of-file Check 30 entry

**Reviewer's evidence (`PACK-REVIEW-BD-079-RETRO.md` §F-3):** Docstring at `scripts/validate-pack.py:97–99` claims "fresh installs never write the file until first persistent-refusal toggle." But `recommendation_record_shown` in `scripts/lib/recommendation.sh:497` writes the file from a different (and typically earlier) trigger — when the recommendation prompt fires.

**Cited write trigger in `recommendation.sh`:**
```sh
# scripts/lib/recommendation.sh:494-497 (recommendation_record_shown)
updated=$(printf '%s' "$state" | jq \
    --arg t "$now" --argjson s "$signals" \
    '.last_recommendation_shown_at = $t | .last_recommendation_signals = $s')
recommendation_state_save "$path" "$updated"
```

This fires whenever the chat surfaces a recommendation, which (per the typical UX flow) precedes any persistent-refusal toggle (the user must see the prompt before they can pick "don't ask again").

The other write trigger is `recommendation_set_persistent_refusal` at `scripts/lib/recommendation.sh:526`. The corruption-rebuild path (`recommendation_state_load` lines 272 + 279) is also a write but is degenerate (rebuild-on-load), not user-triggered.

### Before (lines 95–101)

```
  30. Recommendation-state JSON schema (BD-079): if
      `.pack-tracker/recommendation-state.json` exists at the pack
      root, it parses as JSON and matches the v1 schema documented in
      `scripts/lib/recommendation.sh` (V3 §28.1.4). Soft-passes when
      the file is absent (lazy-create is by design — fresh installs
      never write the file until first persistent-refusal toggle).
      Catches state-file corruption before it causes runtime defaults.
```

### After (lines 95–105)

```
  30. Recommendation-state JSON schema (BD-079): if
      `.pack-tracker/recommendation-state.json` exists at the pack
      root, it parses as JSON and matches the v1 schema documented in
      `scripts/lib/recommendation.sh` (V3 §28.1.4). Soft-passes when
      the file is absent (lazy-create is by design — fresh installs
      never write the file until first recommendation surface or
      persistent-refusal toggle, whichever comes first; see
      `recommendation_record_shown` and
      `recommendation_set_persistent_refusal` in
      `scripts/lib/recommendation.sh`). Catches state-file corruption
      before it causes runtime defaults.
```

**Why this wording:** Adopts the reviewer's suggested text ("first recommendation surface or persistent-refusal toggle, whichever comes first") and adds explicit citations to both runtime functions so a future operator debugging file-presence questions has direct entry points into `recommendation.sh` rather than a single misleading function name.

---

## 4. F-2 (SHOULD) — `last_recommendation_signals` inner-shape scope rationale

**Reviewer's recommended disposition (`PACK-REVIEW-BD-079-RETRO.md` §F-2):** "(a) accept this as scoped out (the V3 example is descriptive not prescriptive, and the runtime tolerates absent inner keys via `// 0`) and document the rationale in the validator function docstring."

Picked option (a) — adding a rationale paragraph to the `check_recommendation_state_schema` function docstring. Reasoning:

1. V3 §28.1.4 schema example at `ARCHITECTURE-V3.md:687–690` shows two inner keys (`bd_count_active`, `backlog_kb`) — but those are descriptive. The actual per-surface key sets emitted by the runtime are larger and divergent.
2. `_rec_compute_pack_signals` (`recommendation.sh:129–143`) emits `{bd_count_active, bd_count_total, backlog_kb, backlog_growth_30d}` (4 keys).
3. `_rec_compute_client_signals` (`recommendation.sh:145–175`) emits `{td_count_active, td_count_total, backlog_kb, phase_count, implementation_plan_kb, td_tbd_comment_count, typed_deferral_count}` (7 keys).
4. The runtime reader at `recommendation.sh:360` defaults absent inner keys to 0 via `// 0`, making the runtime tolerant of arbitrary subsets.
5. `recommendation_state_default()` (`recommendation.sh:247`) emits `last_recommendation_signals: {}` (empty dict) at fresh-create — so an empty dict is the canonical-default shape.

A per-surface inner-key whitelist would be the stricter read but introduces a coupling: any future signal added to `_rec_compute_*_signals` would force a paired update to `_REC_STATE_SCHEMA` (cross-file failure mode). Given the runtime's `// 0` tolerance, the marginal benefit of the inner check is low. Documenting the deliberate scope choice is the better v11 disposition; tightening can land as a future BD if signal-corruption becomes empirical.

### Before (`scripts/validate-pack.py:2463–2475`)

```python
def check_recommendation_state_schema() -> None:
    """Check 30 — recommendation-state.json schema (BD-079).

    If `.pack-tracker/recommendation-state.json` exists at the pack
    root, it must parse as JSON and match the v1 schema documented
    in `scripts/lib/recommendation.sh` (V3 §28.1.4).

    Soft-passes when the file is absent — lazy-create is by design,
    so a fresh pack checkout will not have one. The check fires only
    when the file is present, catching state-file corruption before
    `recommendation_state_load()` falls back to defaults at runtime
    (which silently masks the underlying corruption).
    """
```

### After (`scripts/validate-pack.py:2467–2496`)

```python
def check_recommendation_state_schema() -> None:
    """Check 30 — recommendation-state.json schema (BD-079).

    If `.pack-tracker/recommendation-state.json` exists at the pack
    root, it must parse as JSON and match the v1 schema documented
    in `scripts/lib/recommendation.sh` (V3 §28.1.4).

    Soft-passes when the file is absent — lazy-create is by design,
    so a fresh pack checkout will not have one. The check fires only
    when the file is present, catching state-file corruption before
    `recommendation_state_load()` falls back to defaults at runtime
    (which silently masks the underlying corruption).

    Inner-shape scope (per BD-079 retro F-2 disposition): the
    `last_recommendation_signals` slot is checked for `(dict,)` only
    — keys and value types inside the dict are intentionally not
    validated here. Rationale: V3 §28.1.4 ships the inner-key set as
    a descriptive example (`bd_count_active`, `backlog_kb`) while
    `_rec_compute_pack_signals` and `_rec_compute_client_signals` in
    `scripts/lib/recommendation.sh` emit *different* per-surface key
    sets (pack: bd_count_active / bd_count_total / backlog_kb /
    backlog_growth_30d; client: td_count_active / td_count_total /
    backlog_kb / phase_count / implementation_plan_kb /
    td_tbd_comment_count / typed_deferral_count). The runtime reader
    at `recommendation.sh:360` defaults absent inner keys to 0 via
    `// 0`, and `recommendation_state_default()` emits an empty
    `{}` at fresh-create — so any dict shape is contract-conformant.
    Tightening to a per-surface key/value-type whitelist would be a
    future BD if signal-corruption becomes an empirical failure mode.
    """
```

No code change to `_REC_STATE_SCHEMA` or function body — the disposition is "documented intent," not "deepened check."

---

## 5. Verification

### Validator

```
$ python3 scripts/validate-pack.py | tail -20
  OK: tracker.toml absent at pack root — mirror-staleness leg soft-passes (lazy-create is by design)

── Check 30: Recommendation-state JSON schema (BD-079) ──
  OK: .pack-tracker/recommendation-state.json absent — lazy-create is by design, nothing to validate

── Check 31: Skill-cell consistency (BD-146, v11) ──
  OK: PLATFORM-SKILLS.md — 'Tier 0 base skills': 13 rows (header matches)
  OK: PLATFORM-SKILLS.md — 'Dimensional skills': 20 rows (header matches)
  OK: PLATFORM-SKILLS.md — 'Trigger-loaded skills': 1 rows (header matches)
  OK: PLATFORM-SKILLS.md — 'PM chat operational skill': 1 rows (header matches)
  OK: PLATFORM-SKILLS.md — total skills: 35 (header sum, inventory row count, and disk count all agree)
  OK: Skill-cell consistency: 35 SKILL.md on disk, all map to exactly one inventory cell; no orphans, phantoms, or double-counts

── Check 32: Phase-task lib invariants (BD-106) ──
  OK: scripts/lib/tracker-phase-task.sh present
  OK: scripts/lib/tracker-labels.sh — no tracker_labels_folded_into helper definition (Path 3 forbidden)
  OK: scripts/lib/ — no `folded-into` literal in executable code (V3.3 §3 line 27); comment-only references allowed

============================================================
PASSED — all checks clean
```

Numbered Checks present: 30 (Checks 1–11, 16–32) + 2 informational (Issue template forms; Template archive v11.0 integrity) = 32 total. Matches HEAD baseline.

### Recommendation-state schema test

```
$ bash scripts/tests/recommendation-state-schema-test.sh | tail -5
  PASS 10.2 message names bool rejection

=== Summary ===
PASS: 19
FAIL: 0
```

Count parity with HEAD baseline: 19/19 PASS. Test surface unchanged (we did not touch `scripts/tests/recommendation-state-schema-test.sh`); the docstring edit is non-behavioral.

---

## 6. Files changed

| Path | Change type | Notes |
|---|---|---|
| `scripts/validate-pack.py` | modified | Top-of-file Check 30 docstring entry (lines 95–105) + `check_recommendation_state_schema` function docstring (lines 2467–2496). No code-path or behavior change. |
| `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-079-RETRO-FIX.md` | new | This report. |

**Pre-existing diff context:** `git diff scripts/validate-pack.py` at session start already showed unrelated edits in the file from concurrent BD-078 retro-fix work (around lines 2195–2275 — `_validate_tracker_toml` bool/int hardening + `backend.repo` requirement). Those are NOT this session's changes; they belong to the BD-078 retro-fix coder. This session's edits are isolated to the Check 30 docstring areas listed above.

**Files in scope but NOT touched (read-only context only):**
- `BACKLOG.md` (PM-owned — F-4 already closed by `614e67e`)
- `CHANGELOG.md` (PM-owned)
- `scripts/lib/recommendation.sh` (read-only context; cited in docstrings, not modified)
- `.github/workflows/validate-pack.yml` (F-1 already closed by `304078f`)
- `scripts/tests/recommendation-state-schema-test.sh` (no behavioral change required; docstring-only edits)
- `maintenance-docs/v11-research/ARCHITECTURE-V3.md` §28.1.4 (the contract is correct as-is; the validator now documents its scope choice relative to the contract)
- All BD-095 / BD-101 / BD-133 owned files per the prompt's lockout list

---

## 7. Plan deviations

None. Both findings closed via the reviewer's recommended dispositions:
- F-3: adopted the reviewer's literal suggested wording, with a small additive expansion citing the two runtime functions (`recommendation_record_shown` + `recommendation_set_persistent_refusal`) so an operator can navigate directly. The reviewer's wording named only the abstract "first recommendation surface or persistent-refusal toggle"; the operator-citation expansion is strictly additive and does not change the corrected fact.
- F-2: adopted option (a) verbatim per the reviewer's "Recommend (a) for v11" disposition. No deepening of inner-shape validation; rationale lives in the function docstring.

---

## 8. New POQs introduced

None. The "tightening to a per-surface key/value-type whitelist" mentioned in the F-2 docstring rationale is a *future BD if it becomes empirical*, not a queued POQ. Per the reviewer's explicit disposition, queueing it as a BD now would be premature (no observed corruption-failure mode in v11).

---

## 9. Definition-of-Done

| Item | Status | Note |
|---|---|---|
| F-2 closed (rationale docstring OR depth deepening) | PASS | Rationale docstring (option (a)) at `scripts/validate-pack.py:2480–2495` |
| F-3 closed (docstring corrected, runtime trigger cited) | PASS | Top-of-file docstring at `scripts/validate-pack.py:95–105`; cites `recommendation_record_shown` + `recommendation_set_persistent_refusal` in `scripts/lib/recommendation.sh` |
| `python3 scripts/validate-pack.py` exit 0, all 32 checks green | PASS | 30 numbered + 2 informational, "PASSED — all checks clean" |
| `bash scripts/tests/recommendation-state-schema-test.sh` 19/19 | PASS | 19/19 PASS, count parity with HEAD baseline |
| No state-changing git verbs | PASS | Used only `git rev-parse HEAD`, `git status`, `git diff` (read-only) |
| Stayed in scope (Check 30 area only in `validate-pack.py`) | PASS | Diffs confined to lines 95–105 + 2467–2496; no other Check touched |
| No PM-owned files touched | PASS | BACKLOG.md / CHANGELOG.md / README.md untouched |
| No concurrent-coder files touched | PASS | BD-095 / BD-101 / BD-133 files all untouched |
| Trinity rule respected | N/A | No trinity files touched |
| Implementation report written | PASS | `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-079-RETRO-FIX.md` |

---

## 10. New file contents (full)

The only NEW file produced this session is this report itself; no other new files were created. The `scripts/validate-pack.py` change is a docstring-only modification, fully shown in §3 and §4 (before/after blocks).

---

## 11. Handoff to Pack Chat

This report is the agent's primary output. Pack Chat next actions (per `CLAUDE.md` Pack memory §"Workflow"):

1. Review this report + the working-tree diff (`git diff scripts/validate-pack.py` — note the BD-078 retro-fix diff is also present in that file from the concurrent BD-078 coder; this session's BD-079 changes are the docstring-only edits at the top-of-file Checks list and inside `check_recommendation_state_schema`).
2. Verify locally: `python3 scripts/validate-pack.py` → "PASSED — all checks clean" (32/32) and `bash scripts/tests/recommendation-state-schema-test.sh` → 19/19 PASS.
3. Commit decision is Pack Chat's, not this agent's. Per `CLAUDE.md` "Agents never commit."
4. With F-1 / F-2 / F-3 / F-4 all now closed (F-1 + F-4 by prior cross-BD commits; F-2 + F-3 by this session), BD-079's retro-review-fix scope is complete. Per the Pack memory rule "Implicit BD status flip on batch completion," the BD-079 status flip remains Pack Chat's call as the final batch step (BD-079 is already `Status: Resolved` from the original ship in `91a9fc5`; the retro-fix does not need a separate flip — the original Resolved stands and the retro-fix is documented here).

End of report.

