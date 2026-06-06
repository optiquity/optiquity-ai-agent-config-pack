# PACK-REVIEW-BD-204-C3 — Mode-3 full-CRUD `provider_update` wiring

> **Reviewer:** pack-reviewer (READ-ONLY). **Commit under review:** BD-204 C-3.
> **Branch:** `v11-dev`. **HEAD:** `3a8ba3e`. **Date:** 2026-06-06.
> **Verdict:** **PASS.** All 6 checks pass; CI re-run green (validate-pack +
> Group-4 provider tests + realistic-ot). Zero findings above NIT.

---

## Headline: PASS

The new pack-side lib `scripts/lib/tracker-edit.sh` (`tracker_edit_entry`) is
correct, tracker-agnostic, correctly placed, and Check-47-safe. The boundary-
cross `state_reason` mapping matches the DP-3 matrix exactly. Group-4 tests
genuinely assert the right `provider_*` op + `state_reason`, not just exit code.

Files (uncommitted): `scripts/lib/tracker-edit.sh` (new),
`scripts/pack-tracker.sh` (one source line), `scripts/tests/tracker-provider-test.sh`
(Group 4). `git diff --name-only` + untracked = exactly these three + the
coder's IMPL-REPORT (not reviewed per prompt).

---

## Check 1 — `tracker_edit_entry` correctness — PASS

**Id-map resolution (PASS).** `tracker-edit.sh:188-201` resolves `pack-id → gh-id`
via `$repo_root/.pack-tracker/id-map.json` + `jq -r 'if has($k) then .[$k].id
else empty end'`. This is byte-for-byte the same mechanism as
`tracker-agent-read.sh:105-116` (the READ side). Unmapped id errors cleanly:
absent mapping file → `not-found` "mapping file absent" (`:189-193`); id not in
map → `not-found` "$pack_id not in mapping" (`:197-201`). Both return 1 before
any provider op fires.

**`provider_update` payload shape (PASS).** `tracker-edit.sh:225-242` builds a
`{title?, body?, add_labels[], remove_labels[]}` payload and calls
`provider_update "$gh_id" "$payload"`. The gh provider consumes exactly these
keys (`tracker-provider-gh.sh:319` "patch keys: title, body, add_labels[],
remove_labels[]", wired to `--add-label`/`--remove-label` at `:346-347`). The
`provider_update "$gh_id" "$payload"` call shape reuses
`tracker-promote.sh:801` (`provider_update "$td_gh_id" "$_f2_payload"`), as the
design directs.

**Boundary-cross `state_reason` (load-bearing — PASS).** Verified against the
DP-3 matrix (ARCHITECTURE-BD-204.md §2.6 / DP-3, lines 141-148):

| New Status | `_ted_status_openness` (`:69-75`) | `_ted_status_reason` (`:81-87`) | Provider op (`:249-279`) | DP-3 expected | Match |
|---|---|---|---|---|---|
| Open | open | (n/a) | reopen if was closed | open, reopen | ✓ |
| Unblocked | open | (n/a) | reopen if was closed | open | ✓ |
| Deferred | open | (n/a) | reopen if was closed | open (NEW row) | ✓ |
| Resolved | closed | `completed` | close `completed` | close `completed` | ✓ |
| Deprecated | closed | `not_planned` | close `not_planned` | close `not_planned` | ✓ |
| Cancelled | closed | `not_planned` | close `not_planned` | close `not_planned` | ✓ |

The cross fires only when `new_open != old_open` (`:260`): a closed-side new
status → `provider_close "$gh_id" "$reason"` (`:264`); an open-side new status →
`provider_reopen "$gh_id"` (`:271`). A non-crossing status change (Open→Deferred,
both open) skips close/reopen entirely (`:260` guard false) and calls only
`provider_update`. A body/title-only edit (no `status`) skips the whole block
(`:249` guard `[[ -n "$new_status" ]]`). The DP-3-correct reason is wrong-round-
trip-safe: `completed` only for Resolved; `not_planned` for Deprecated/Cancelled.

**Edge: `old_status` absent.** `:254-258` sets `old_open=""`, so any set status
always crosses once (close-if-closed / reopen-if-open) and is idempotent on the
backend — matches the documented intent (`:139-141`, `:244-248`). Correct.

---

## Check 2 — No abstraction widening — PASS

No `provider_delete` op is added anywhere. `grep -rn "provider_delete" scripts/`
returns exactly one hit: `tracker-edit.sh:27`, inside the CRUD-mapping comment
documenting its deliberate absence ("there is NO provider_delete op (adding one
would widen the abstraction with no consumer)"). Delete maps to close-with-
`state_reason` per the Deprecated/Cancelled rows (`:22-28` comment + the
`_ted_status_reason` `not_planned` path). Matches §2.3.

---

## Check 3 — Tracker-agnostic — PASS

No raw `gh` calls in the new lib. `grep -n "gh " scripts/lib/tracker-edit.sh`
returns one hit (`:30`) — a comment ("never a raw `gh` call"). Every mutation is
a `provider_*` op: `provider_update` (`:237`), `provider_close` (`:264`),
`provider_reopen` (`:271`). The `_ted_status_*` helpers are pure shell case maps.
A Jira/Linear backend implementing update/close/reopen ports unchanged.

---

## Check 4 — New-file placement + Check 47 — PASS

**Pack-side lib (PASS).** `tracker-edit.sh` lives in `scripts/lib/` (pack-side),
NOT `project-template/`. It is sourced by the pack op `pack-tracker.sh` and is a
runtime dependency of a pack operation only — dependency-direction-correct as a
pack-side file.

**Check 47 unviolated (PASS).** `python3 scripts/validate-pack.py` Check 47:
`OK: install-map pack-side subset == _SANCTIONED_PACK_SIDE_SHIPPED (2 entries):
['scripts/lib/detect.sh', 'scripts/pack-help.sh']`. The frozen sanctioned set is
unchanged at 2 entries. `tracker-edit.sh` is NOT referenced in `validate-pack.py`
and NOT in any install map (`grep -rn "tracker-edit" scripts/validate-pack.py` →
no match) — it is genuinely pack-side-only with no client install, so it cannot
trip the install-map↔constant set-equality check. The client-side counterpart is
correctly BD-207's job; its absence breaks nothing now (pack/project separation).

**Filename-uniqueness (PASS).** `find . -name "tracker-edit.sh" -not -path
"./.git/*"` → exactly one path. No collision.

**Source wiring (PASS).** `pack-tracker.sh:55` `source "$LIB_DIR/tracker-edit.sh"`,
placed in the tracker-lib source block (after `tracker-doctor.sh`, before
`recommendation.sh`). `grep -n "tracker-edit.sh" pack-tracker.sh` → single line;
no double-source. The lib self-sources its siblings idempotently
(`tracker-edit.sh:42-57`, `declare -f` guards), mirroring `tracker-agent-read.sh`.

---

## Check 5 — Tests genuine — PASS

Group 4 (`tracker-provider-test.sh:618-715`) stubs `provider_update/close/reopen`
to log argv into `TED_CALLS` (mirrors the Group-3 STUB pattern) and asserts the
actual op + args, not merely that the script runs:

- **4.1 update-only (no cross):** asserts `|update:42` present AND `|close:`/`|reopen:`
  absent AND `updated=true` in the returned JSON.
- **4.2 open→open (Open→Deferred):** asserts `|update:42` present AND no boundary
  cross — exercises the non-crossing-status path explicitly.
- **4.3 open→closed (Open→Resolved):** asserts `|update:42` AND `|close:42:completed`
  — pins the `completed` `state_reason`.
- **4.4 open→closed (Open→Cancelled):** asserts `|close:42:not_planned` — pins the
  `not_planned` `state_reason`.
- **4.5 closed→open (Resolved→Open):** asserts `|update:42` AND `|reopen:42` AND
  NOT `|close:` — pins reopen-not-close.
- **4.6 unmapped id (BD-999):** asserts `ERROR: not-found` AND zero provider ops
  dispatched.

All required cases present and assert the right `provider_*`/`state_reason`.

NIT (informational, not a C-3 defect): the `Deprecated → not_planned` reason is
covered transitively by 4.4 (`not_planned`) but no test exercises the
Deprecated→closed path by name. The reason map (`_ted_status_reason`) treats
Deprecated and Cancelled identically, so coverage is complete on the distinct
`state_reason` values (`completed` via 4.3, `not_planned` via 4.4). Optional add.

---

## Check 6 — Pack-only + full CI — PASS (re-run independently at HEAD 3a8ba3e)

- **Pack-only.** `git diff --name-only` → `scripts/pack-tracker.sh`,
  `scripts/tests/tracker-provider-test.sh`; untracked → `scripts/lib/tracker-edit.sh`
  (+ the IMPL-REPORT, not reviewed). All `scripts/` — no `project-template/` /
  `supporting-docs/` touch. Pack-only clean.
- **`python3 scripts/validate-pack.py`** → `PASSED — all checks clean` (Check 47
  OK, 2-entry sanctioned set unchanged; Check 48 WARNs are pre-existing advisory-
  only removed-doc citations, exit code unaffected).
- **`bash scripts/tests/tracker-provider-test.sh`** → `Passed: 111 / Failed: 0 /
  All tests passed.` (Group 4: all 13 assertions PASS, quoted above.)
- **`bash scripts/tests/test-v11-realistic-ot.sh`** → `PASS: 33 / FAIL: 0 / All
  v11-realistic-ot integration tests PASSED (33/33).`
- **Manifest.** `bash test-fixtures/build.sh --all --clean` then `git diff --stat
  test-fixtures/manifest.txt` → empty diff. `scripts/lib/` + `scripts/tests/`
  are not in the install-surface manifest, so no manifest update is required for
  this commit (regen-rule satisfied: non-empty-diff condition not met).

---

## Severity-ranked findings

- **BLOCKER:** none.
- **MUST:** none.
- **SHOULD:** none.
- **NIT (1):** Check 5 — no test names the `Deprecated → not_planned` close path
  explicitly; coverage of the distinct `state_reason` values is nonetheless
  complete (4.3 `completed`, 4.4 `not_planned`). Optional one-line add.

### Out-of-scope observation (surfaced, NOT a C-3 defect)
The forward-migrator label map `_tmf_labels_for_entry`
(`tracker-migrate-forward.sh:1414-1419`) still lacks a `Deferred` case (falls
through `*) status:open`), so forward-emit would label a Deferred entry
`status:open`. This is NOT C-3's scope: C-3 wires the edit path; the DP-3
`Deferred` row's reverse decode landed in C-1 (commit 7ba527c). The forward-emit
`Deferred` label belongs to the forward read-input repoint (C-5) — flagging for
Pack Chat so it is not lost before the C-8 dogfood flip, not a fix to apply here.

---

## Rules-Applied Verification Block

| Rule | Verification evidence | Conclusion |
|---|---|---|
| **Tracker portability (all CRUD via `provider_*`; no raw `gh`; verb set not widened)** | `grep -n "gh " tracker-edit.sh` → only `:30` (comment). Mutations: `provider_update` `:237`, `provider_close` `:264`, `provider_reopen` `:271`. `grep -rn "provider_delete" scripts/` → only `tracker-edit.sh:27` (absence-documenting comment). | COMPLIANT |
| **Dependency-direction placement (pack-side correct; Check 47 / install-map unviolated)** | File at `scripts/lib/`; runtime dep of pack op `pack-tracker.sh:55`; not in any install map; `grep -rn "tracker-edit" validate-pack.py` → none. Check 47 `OK ... (2 entries): ['scripts/lib/detect.sh', 'scripts/pack-help.sh']` unchanged. | COMPLIANT |
| **Pack/project separation (no project-side edit; client counterpart = BD-207, absence not a regression)** | `git diff --name-only` + untracked = `scripts/` only; zero `project-template/`/`supporting-docs/`. No client lib added; PLAN C-3 `:260` directs pack-side lib, NOT a client file. | COMPLIANT |
| **Pattern-matching antipattern (open/closed judged against actual DP-3 matrix)** | `_ted_status_openness`/`_ted_status_reason`/`_ted_status_label` (`:69-103`) compared row-by-row to ARCHITECTURE-BD-204.md DP-3 table (`:141-148`); 6/6 rows match (Check 1 table). | COMPLIANT |
| **Empirical evidence (findings + CI re-run cite diff lines / output at HEAD 3a8ba3e)** | `git rev-parse HEAD` → `3a8ba3e...`. All checks cite `file:line` + quoted command output (validate-pack PASSED, provider 111/0, realistic-ot 33/0). | COMPLIANT |
| **Filename-uniqueness** | `find . -name "tracker-edit.sh" -not -path "./.git/*"` → single path `./scripts/lib/tracker-edit.sh`. | COMPLIANT |
| **Rules-Applied Verification Block (this block; evidence quoted)** | Present; per-rule + per-read-doc; evidence quoted, not summarized. | COMPLIANT |

### Per-read-doc attestation

| Doc | Read | Evidence used |
|---|---|---|
| `PLAN-BD-204.md` § C-3 | full (`:251-279`) | scope = edit-path wiring, pack-side lib, no `provider_delete`, reuse `:801` shape |
| `ARCHITECTURE-BD-204.md` §2.3 + §2.6/DP-3 | full (`:129-180` DP-3, `:385-422` §2.3, §2.6) | DP-3 6-row matrix; CRUD design; delete=close-with-reason |
| `scripts/lib/tracker-edit.sh` | full (1-282) | every check above |
| `scripts/pack-tracker.sh` diff + context | read (`:40-58`) | single source line, correct placement, no double-source |
| `tracker-provider.sh` / `-gh.sh` signatures | read | `provider_update`/`close`/`reopen` sigs; patch keys `title/body/add_labels/remove_labels`; close reason enum |
| `tracker-promote.sh` near `:801` | read (`:790-830`) | `provider_update "$gh_id" "$payload"` reuse shape confirmed |
| `tracker-agent-read.sh` id-map pattern | read (`:104-145`) | id-map resolution matched byte-for-byte |
| `CLAUDE.md` `## Pack memory` | read (in context) | dependency-direction-placement, tracker-portability, pattern-matching, filename-uniqueness, empirical-evidence rules applied |
| Coder IMPL-REPORT | NOT read (per prompt — verified independently) | — |

**End of review. READ-ONLY: this report is the only file written; no stage, no commit.**
