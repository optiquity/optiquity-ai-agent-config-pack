# IMPL-REPORT-MODE3-OPS-COMMIT2-FIX1 — BD-204 Mode-3 ops Commit 2, fix-coder pass 1

> **Agent:** pack-coder (fresh fix-coder instance). **Date:** 2026-06-12 session.
> **Branch:** `v11-dev`. **HEAD (verified at pre-flight AND at report time —
> unchanged):** `358310e4e3586fd94d838e0097954c804638f530`.
> **Input:** `PACK-REVIEW-MODE3-OPS-COMMIT2.md` findings MUST-1 / SHOULD-1 /
> SHOULD-2 / NIT-1 — all four user-approved FIX. §INCIDENT skipped per prompt
> (already remediated by Pack Chat; my pre-flight confirms HEAD is back at
> `358310e` and `tracker.toml` is untracked, 23 lines).
> **Scope discipline:** exactly the four findings; the 26 inherited files were
> not reworked outside them. Zero live GitHub calls (all gh traffic in tests
> hit fake/exploding stubs). All verification FOREGROUND; zero background
> tasks armed. No isolated repo copies were made (no `cp -R` worktree hazard
> exercised; the one `/tmp` artifact is a 3-line gh stub + logs).

---

## 1. Pre-flight

- `git rev-parse HEAD` → `358310e4e3586fd94d838e0097954c804638f530` (matches the prompt).
- `git status --short` → exactly the 26 inherited modified files + the 2
  untracked workflow reports (`IMPL-REPORT-MODE3-OPS-COMMIT2.md`,
  `PACK-REVIEW-MODE3-OPS-COMMIT2.md`). Index clean.
- `wc -l tracker.toml` → 23 (live file untouched, before and after this pass);
  `.pack-tracker/` never read or written.

## 2. Per-finding fixes

### MUST-1 — `README.md` stale `pack-tracker.sh` verb enumeration

**File:** `README.md` (Repository Layout, the `scripts/` block's
`pack-tracker.sh` row). One line modified.

- **Before:** `Tracker — init / status / mirror-rebuild / disable / doctor / update-templates / enable-recommendations (v11)`
- **After:** `Tracker — init / status / tree-rebuild / edit / new-entry / mirror-rebuild / disable / doctor / update-templates / enable-recommendations (v11)`

The three verbs are inserted in the SAME position/order as the updated
`pack-ops/HELP-FRAGMENT-PACK.md` row (`init`, `status`, `tree-rebuild`,
`edit`, `new-entry`, `mirror-rebuild`, …). Encoding-surface sweep: a repo-wide
grep for verb-list enumerations (needle `enable-recommendations` filtered to
list-shaped lines, excluding `.git/`, `maintenance-docs/`, `test-fixtures/`)
returns exactly these two surfaces, now in agreement — no third stale list.

**Verification:** grep of both rows quoted above; `validate-pack.py` ×2 green
(§5).

### SHOULD-1 — doctor leg (h) coverage truncated at 100

**File:** `scripts/lib/tracker-doctor.sh`, `tracker_doctor_run` leg (h).
Two targeted edits (header-comment block + the read/saturation logic);
~+22 lines net. **Companion test file:**
`scripts/tests/tracker-bd130-doctor-wired-test.sh` Group 9 (~+34 lines).

- **Before:** `provider_list '{"label":"bd-entry","state":"all"}' 100` — a
  fixed 100-item read against 213 live entries (~47% coverage), no
  truncation signal.
- **After:**
  - `local coh_limit="${TRACKER_DOCTOR_COH_LIMIT:-1000}"` — full-coverage
    default 1000, matching the forward-side precedent
    (`_tmf_wait_for_close_stabilization` in
    `scripts/lib/tracker-migrate-forward.sh` uses `provider_list … 1000`);
    the env seam follows the established `TMF_*`/`TMR_*` override pattern
    (e.g. `TMR_RACE_FRESHNESS_SECS`).
  - `provider_list '{"label":"bd-entry","state":"all"}' "$coh_limit"`.
  - **Saturation guard** immediately after `coh_n` is computed: if
    `coh_n >= coh_limit`, emit
    `[WARN] status-coherence: provider_list read SATURATED at the
    $coh_limit-item limit ($coh_n returned) — coverage may be truncated;
    re-run with TRACKER_DOCTOR_COH_LIMIT raised (a coverage advisory must
    never sample silently)` and increment `n_warn` (→ doctor rc=1). No
    silent sampling in a coverage check.
  - Leg-(h) header comment updated in lock-step (full-coverage limit +
    saturation WARN; cites file + symbol, no line numbers).

**Tests (new legs, both green):**
- The Group-9 fake gh (`FG9` heredoc) now logs its argv to
  `${0%/*}/calls.log` (the stub's own mktemp dir).
- **9.4b** asserts the doctor's leg-(h) read requests
  `--limit 1000 --label bd-entry --state all` (limit + filter pinned;
  the `--json` field list deliberately NOT pinned here — that contract is
  owned by the provider suite).
- **9.4c** forces saturation deterministically (`TRACKER_DOCTOR_COH_LIMIT=1`
  against the 1-issue fixture → items returned == limit): asserts the loud
  truncation WARN, the recovery-seam name in the message, and doctor rc=1.

### SHOULD-2 — pack emit failure stamped `last_tree_regen` + reported success + rc=0

**File:** `scripts/lib/tracker-migrate-reverse.sh`,
`tracker_migrate_reverse_run` Step 9 region (~+23 lines).
**Companion test file:** `scripts/tests/tracker-migrate-reverse-test.sh`
new leg 8.7 (~+30 lines).

- **Before:** with `flip_mode=0` on the pack surface, `emit_failed=1` gated
  nothing — `_stamp_tree=1` unconditionally for `surface == pack`, the
  `tree-rebuild: complete.` summary printed, rc=0.
- **After — all three gated on `emit_failed==0`, exactly per the review's
  recommendation:**
  1. **Stamp:** `[[ "$surface" == "pack" && "$emit_failed" == "0" ]] &&
     _stamp_tree=1` — the `[migration].last_tree_regen` stamp is now
     SUCCESS-ONLY, mirroring the success-only
     `tracker_edit_stamp_last_write` call site in
     `scripts/lib/tracker-edit.sh`. (Step 9 itself still runs, preserving
     the inherited `last_reverse_run` behavior — the review's fix shape.)
  2. **Summary + rc:** a new PACK-surface fail-loud gate after Step 9 and
     before the completion summaries: `surface == pack && emit_failed == 1`
     → typed `tracker_error_emit "partial-write"` naming the verb
     (`tree-rebuild` when `tree_only==1`, else `reverse`), stating
     `emit step failed; tree state may be partial; [migration].last_tree_regen
     NOT stamped`, with the `Re-run 'pack tracker tree-rebuild'` recovery
     hint — then `return 1`. No success summary is reachable on a failed
     pack emit.
- **Untouched by design:** the `flip_mode=1` path (already covered by the
  pre-existing atomicity gate, which aborts BEFORE Step 9); the client
  surface (inherited best-effort shape — BD-207 scope); the comparator/guard
  abort paths (they fail pre-emission, pre-stamp — unchanged and still
  test-pinned by 8.5).

**Test (new leg 8.7, all 6 assertions green):** direct engine call (the
suite's 8.4 engine-seam precedent) with `_tmr_emit_pack_tree` overridden to
`return 1` inside the command-substitution subshell — exercising the exact
`|| emit_failed=1` seam deterministically, override never leaks. Asserts:
rc≠0; NO `tree-rebuild: complete` in output; `ERROR: partial-write`;
`tree-rebuild: emit step failed`; `last_tree_regen NOT stamped` in the
message; and `last_tree_regen` ABSENT from the fixture `tracker.toml`
after the failed run.

```
PASS 8.7 emit failure → tree-rebuild rc!=0 (fail loud)
PASS 8.7 emit failure → NO success summary
PASS 8.7 emit failure → typed partial-write error
PASS 8.7 emit failure → names the failed emit step
PASS 8.7 emit failure → states the stamp was withheld
PASS 8.7 emit failure → last_tree_regen NOT stamped in tracker.toml
```

### NIT-1 — 7 unwrapped read-only `gh repo view` calls in the reverse suite

**File:** `scripts/tests/tracker-migrate-reverse-test.sh` (~+17 lines:
Group-2 wrap open + close).

- **Origin:** every successful `tracker_migrate_reverse_reconstruct` call in
  Group 2 reaches `_tmr_fetch_first_class_blocked_by`
  (`scripts/lib/tracker-migrate-reverse.sh`), whose GH_REPO-absent fallback
  shells out to `gh repo view --json nameWithOwner`. Seven Group-2
  reconstruct calls succeed past decode/comparator (2.1, 2.1c, 2.1d-i,
  2.1d-iii, 2.1f ×2, 2.1e-iv) — matching the review's count of 7. Worse than
  cosmetic: on a developer machine where the real `gh repo view` SUCCEEDS,
  the follow-on `provider_raw POST graphql` would have issued a REAL
  GraphQL call.
- **Fix:** the whole of Group 2 is wrapped in the suite's existing hermetic
  pattern — `FAKE_G2=$(mktemp -d …); _build_fake_gh "$FAKE_G2";
  export PATH="$FAKE_G2:$PATH_SAVED"` at the group head, restore + `rm -rf`
  at the group tail (the same `_build_fake_gh` stub Groups 4/5 use:
  `repo view` answers the fixture slug; the catch-all arm answers
  `gh api graphql` with empty output, so the fetch degrades to `[]` exactly
  as the offline baseline). No behavior-assertion changes — zero existing
  assertions edited.

**Hermeticity proof (before/after, exploding+logging stub `exit 99` FIRST on
PATH, run in-place, FOREGROUND):**

- BEFORE (working tree as inherited): suite rc=0, `Passed: 190 / Failed: 0`;
  stub log → `7 GH-CALL: repo view --json nameWithOwner --jq .nameWithOwner`.
- AFTER (this pass): suite rc=0, **`Passed: 196 / Failed: 0`**; stub log →
  **NOT CREATED — ZERO invocations of the real-PATH gh** (no `repo view`, no
  `issue list`, no graphql). The suite is fully offline-deterministic.

## 3. Verification battery (FOREGROUND, complete)

- `bash -n` on all 4 edited shell files → clean. (README is prose.)
- `python3 scripts/validate-pack.py` → **PASSED — all checks clean** (rc=0).
- `PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py` → **PASSED** (rc=0).
- **All 52 workflow `tests:`-job suites, run in workflow order, 52/52 rc=0**
  (4 foreground chunks; per-suite line captured in-session): detect 100/0;
  provider/config/init/agent-read/forward/REVERSE(196/0)/roundtrip/
  phase-task/links/cycle/errors all "All tests passed"; config-schema
  PASS:40; recommendation-state-schema PASS:19; per-entry PASS:57;
  checks-32-33-34 PASS:96; checks-36-37-38, 39, 40, 41, 18, 16, 19, 42, 43,
  44, 45, 46, removed-doc-advisory, 49-field-faithfulness all green;
  bd129 14/0; **bd130 40/0**; bd132 29/0; bd133 green; bd134 24/0;
  recommendation/pack-help/customization-preserve/init-project green;
  all 4 migrate-v10-to-v11 suites green; migrator-core 19/0;
  migrator-manifest 12/0; capability-translation 12/0; integration
  `test-v11-realistic-ot.sh` **33/33**; migrator-skills 19/0;
  persona-contracts PASS; template-translations/template-version/
  issue-forms green.
- **Reverse suite under the exploding-gh stub:** 196/0 with ZERO real-gh
  invocations (the NIT-1 hermeticity gate). **bd130 suite under the same
  stub:** 40/0, no real-gh calls.
- Live oracle: **default-SKIP** (not run). Zero live GitHub calls and zero
  GitHub MCP calls by this coder.
- Assertion deltas: reverse suite 190 → 196 (+6, leg 8.7); bd130 suite
  36 → 40 (+4, legs 9.4b/9.4c).

## 4. Manifest state (regenerate-manifest-v11-surface)

`scripts/` was touched → trigger fires. Ran
`bash test-fixtures/build.sh --all --clean` → rc=0;
`git diff test-fixtures/manifest.txt | wc -l` → **0**;
`bash test-fixtures/build.sh --verify` → **6/6 rows OK** (SHAs:
`19558cb…/4c62945…/ae3fc6f…/f9705c2…/944ddee…/a54e081…` — identical to the
reviewer's §5 values). Empty diff = nothing to stage (the canonical-authority
"if empty … no staging needed" arm; pack-side `scripts/lib/tracker-*.sh` and
`scripts/tests/**` are not fixture-copied — same PD-B mechanism the reviewer
independently verified). **Note for Pack Chat:** the CI workflow step
`git checkout HEAD -- test-fixtures/manifest.txt` between build and verify
was NOT run by me (`checkout` is a forbidden state-changing verb for agents);
the 0-line diff is the equivalent evidence — working manifest == committed
manifest, so `--verify` ran against identical content.

## 5. Plan deviations

Zero deviations from the four approved findings. Two implementation choices
disclosed (both within the review's recommended fix shapes):

1. **SHOULD-1 env seam.** `TRACKER_DOCTOR_COH_LIMIT` (default 1000) was
   introduced so the saturation path is deterministically testable (leg
   9.4c) without a 1000-item fixture. It follows the repo's established
   `TMF_*`/`TMR_*` env-override pattern and changes no default behavior.
2. **SHOULD-2 Step-9 shape.** Implemented exactly as the review recommended
   ("pass `_stamp_tree=1` only when `emit_failed==0`, and gate the
   summary/rc"): Step 9 still runs on a failed pack emit (preserving the
   inherited `last_reverse_run` stamp — no consumer, no contract change),
   while `last_tree_regen` + summary + rc are gated. The client surface and
   the flip=1 atomicity gate are byte-untouched.

## 6. New POQs

None.

## 7. Boundary discipline check

All five touched files are pack-side (`README.md`, `scripts/lib/` ×2,
`scripts/tests/` ×2). **No project-side file was touched** — no
`project-template/` or `supporting-docs/` path appears in the diff
(`git diff --name-only | grep -cE "^(project-template/|supporting-docs/)"`
→ 0), so no project-side SSOT investigation was triggered and no
boundary-discipline stop occurred. Added prose references pack-side
mechanisms only (review report name, pack lib symbols, BD-207).

## 8. Definition of Done

| Item | Result |
|---|---|
| MUST-1: README row lists all ten verbs, matching HELP-FRAGMENT-PACK.md ordering | PASS (both rows quoted, in agreement; no third enumeration surface) |
| SHOULD-1: leg (h) full-coverage read (1000) + loud saturation WARN; tests updated | PASS (legs 9.4b/9.4c green; bd130 40/0) |
| SHOULD-2: stamp + success summary + rc all gated on `emit_failed==0`; failure test leg added | PASS (leg 8.7's 6 assertions green; reverse 196/0) |
| NIT-1: 7 `gh repo view` leaks wrapped; suite fully offline-deterministic; no assertion changes | PASS (exploding-stub run: ZERO real-gh calls, 196/0) |
| `validate-pack.py` + DEEP green | PASS (rc=0 ×2, "PASSED — all checks clean") |
| Full CI battery green (52/52, workflow order, foreground) | PASS |
| Fixture manifest: rebuild + diff + verify | PASS (rc=0; diff 0 lines; 6/6 rows OK) |
| Live `tracker.toml` / `.pack-tracker/` untouched | PASS (23 lines before/after; never written) |
| pack-only: diff inside the permitted set | PASS (26 paths, 0 deny-set hits) |
| No git state changes | PASS (read-only verbs only) |

## 9. Files changed (this fix pass)

| Path | Change | Finding |
|---|---|---|
| `README.md` | modified (1 line) | MUST-1 |
| `scripts/lib/tracker-doctor.sh` | modified (leg-(h) comment + limit + saturation guard) | SHOULD-1 |
| `scripts/tests/tracker-bd130-doctor-wired-test.sh` | modified (FG9 argv log; legs 9.4b/9.4c) | SHOULD-1 |
| `scripts/lib/tracker-migrate-reverse.sh` | modified (Step-9 stamp gate + fail-loud gate) | SHOULD-2 |
| `scripts/tests/tracker-migrate-reverse-test.sh` | modified (Group-2 hermetic wrap; leg 8.7) | SHOULD-2 + NIT-1 |

No new files (other than this report — workflow-artifact class, exempt).
No deletions. The total working-tree diff remains 26 files (all five of the
above were already in the inherited 26). Edit-in-place: every edit was a
targeted `Edit` (zero full-file Writes on source); each edited region was
re-read from disk after editing and is quoted/verified above; untouched text
byte-stable by construction (Edit old-string match) and confirmed by the
unchanged remainder of the suites.

## 10. READ-IN-FULL attestation (path + line count, read this session)

| # | File | Proof |
|---|---|---|
| 1 | `/Users/david/Developer/optiquity-ai-agent-config-pack-v11-dev/CLAUDE.md` | `## Pack memory` section read via Read tool lines 140–590 of 590 (`wc -l` verified); the full file also present verbatim in session context. |
| 2 | `maintenance-docs/v11-implementation/PACK-REVIEW-MODE3-OPS-COMMIT2.md` | Read IN FULL via Read tool, 437 lines (`wc -l` verified) — findings + §INCIDENT skim per prompt (skipped as instructed for action, read as part of the full-file read). |
| 3 | `maintenance-docs/v11-implementation/ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT-AMENDMENT-2.md` | Read IN FULL via Read tool, 624 lines (`wc -l` verified), incl. §B3 (freshness) + §B7 (validation) for consistency. |
| 4 | `~/.claude/projects/…/memory/feedback_edit_in_place_not_full_rewrite.md` | Read IN FULL, 14 lines. |
| 5 | `~/.claude/projects/…/memory/feedback_verify_full_ci_suite.md` | Read IN FULL, 42 lines. |
| 6 | `~/.claude/projects/…/memory/feedback_agent_output_rules_applied_block.md` | Read IN FULL, 14 lines; its conditional MUST-READ honored — `pack-ops/PACK-MEMORY-RATIONALE.md` § `rules-applied-verification-block` read directly (lines 206–235 of 601). |
| 7 | Standing rule docs: `/backlog/_rules.md` (151 lines, FULL), `/changelog/_rules.md` (76 lines, FULL), `pack-ops/PACK-AGENTS.md` § "Agent permission rules" through end (lines 110–223 of 223; structure map via heading grep). | Read via Read/Bash tools this session. |
| 8 | Section-reads, each verified directly: `scripts/lib/tracker-doctor.sh` legs (g)/(h) region; `scripts/lib/tracker-migrate-reverse.sh` (`_tmr_fetch_first_class_blocked_by`, `_tmr_emit_pack_tree`, `_tmr_update_tracker_toml`, `tracker_migrate_reverse_run` head + emit/atomicity/Step-9 region); `scripts/lib/tracker-provider-gh.sh` (`_gh_run`, `_gh_list_fields`, `_gh_normalize_issue`, `tracker_provider_gh_list`, `tracker_provider_gh_raw`); `scripts/lib/per-entry/_lib.sh` (`pe_write_atomic`, `pe_die`); `scripts/lib/tracker-migrate-forward.sh` stabilization-limit region; `scripts/lib/tracker-errors.sh` (`tracker_error_emit`/`tracker_error_format`); both test suites' helper heads + Groups 2/8 (reverse) and Group 9 (bd130) in full; `README.md` layout region; `pack-ops/HELP-FRAGMENT-PACK.md` scripts table; `.github/workflows/validate-pack.yml` all 59 run lines. |

## 11. Rules-Applied Verification

| Rule | Verification evidence | Conclusion |
|---|---|---|
| **agents-never-commit** | Git verbs run this session: `rev-parse`, `status`, `diff` (+ `--name-only`/`--stat`) — all read-only; zero `add/commit/push/tag/stash/reset/restore/checkout` (the CI workflow's `git checkout HEAD -- test-fixtures/manifest.txt` step was explicitly SKIPPED and substituted with the 0-line-diff evidence, §4). Output = 5 scoped working-tree edits + this report. | COMPLIANT |
| **per-action-approval-sub-agents** | Zero destructive ops on trusted files: `rm -rf` limited to my own `/tmp/leakgh` stub dir contents and the test suites' own mktemp fixtures; report path verified non-existent pre-write (`ls … No such file or directory`); live `tracker.toml` 23 lines before/after; `.pack-tracker/` untouched. | COMPLIANT |
| **preflight-stop-means-stop** | Emitted before this Write, verbatim: `PREFLIGHT: 4/4 fixes complete; verification PASS; HEAD 358310e4e3586fd94d838e0097954c804638f530; about to Write IMPL-REPORT to maintenance-docs/v11-implementation/IMPL-REPORT-MODE3-OPS-COMMIT2-FIX1.md`. Every command ran FOREGROUND to completion (zero background tasks armed). No parent stop/halt/revert message received. | COMPLIANT |
| **agent-output-rules-applied-block** | This table: 10 rows (one per prompt "Rules in force" item), each with quoted command/output evidence, zero empty cells, no AMBIGUOUS terminal state; format per `pack-ops/PACK-MEMORY-RATIONALE.md` § `rules-applied-verification-block` (read this session, lines 206–235). | COMPLIANT |
| **agents-read-rule-docs-in-full** | §10 attestation: all 6 prompt-named files with line counts (590-section / 437 / 624 / 14 / 42 / 14), the conditional MUST-READ honored, the standing `_rules.md` pair + PACK-AGENTS.md rows, and every instructed section-read enumerated. | COMPLIANT |
| **verify-full-ci-suite** | §3: `validate-pack.py` rc=0 "PASSED — all checks clean"; DEEP rc=0; **52/52** workflow suites foreground in workflow order with per-suite counts quoted (detect 100/0, reverse 196/0, bd130 40/0, per-entry 57, checks-32 96, integration 33/33, …); reverse suite ALSO green under an exploding `gh` stub with **zero** real-gh invocations (the prompt's hermeticity-proof requirement); live oracle default-SKIP. | COMPLIANT |
| **regenerate-manifest-v11-surface** | §4: `bash test-fixtures/build.sh --all --clean` rc=0; `git diff test-fixtures/manifest.txt | wc -l` → **0**; `--verify` 6/6 rows OK (SHAs quoted, match the reviewer's values). Empty diff → nothing rides; nothing to stage. | COMPLIANT |
| **edit-in-place-not-full-rewrite** | All 5 file changes were targeted `Edit` calls (old-string exact-match; zero full-file Writes on source). Post-edit re-reads quoted in-session: README row (grep line 197), doctor leg-(h) region (sed 314–372), reverse Step-9 gate region (grep + sed of the `SHOULD-2` block); test-file edits verified by their green runs (196/0, 40/0) including every pre-existing assertion. | COMPLIANT |
| **pack-only** | `git diff --name-only` → 26 paths; `grep -cE "^(project-template/|supporting-docs/)"` → **0**. My 5 touched files all pack-side; this report is `maintenance-docs/` (pack-side). Boundary check §7: no project-side SSOT triggered. | COMPLIANT |
| **scope-deliverables-to-the-ask** | Exactly the four findings fixed; zero edits outside them (the 26-file diff set is UNCHANGED — my 5 files were already in it); no entry files touched; zero phase references in added pack-side text (added prose names BD-207/verbs/symbols only); no new BD numbers; the env seam + test legs are the findings' own "update the leg's test" / "add the test leg" requirements. | COMPLIANT |

---

**End of IMPL-REPORT-MODE3-OPS-COMMIT2-FIX1.md**
