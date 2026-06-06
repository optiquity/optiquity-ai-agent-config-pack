# PACK-REVIEW-BD-204-C6 — Mode-3 read surfaces repoint (agent-read + doctor) + POQ-1 mirror-only retire

> **Reviewer:** pack-reviewer (READ-ONLY). **HEAD:** `4ab4a08`. **Branch:** `v11-dev`.
> **Scope:** uncommitted C-6 changes (6 pack-side `scripts/` files). **Verdict basis:**
> independent re-measurement + full CI re-run. Did NOT read the coder IMPL-REPORT.

## HEADLINE: **PASS (with findings)**

The three named C-6 repoints are correct: agent-read's pack `BD-*` + `*)` fall-through fail
loud with a typed not-found (no monolith fallback) while the project `TD-*`/`phase-*` mirror
branches are byte-preserved; doctor's pack-surface freshness maps to the `/backlog/_toc.md`
regen index while the project `*)` branch is relocated verbatim (no logic change); and POQ-1
is discharged — the `--mirror-only` pack branch now emits a typed `validation` error +
`return 1` before any monolith read/regen, with the client `else` untouched. The full CI
battery (validate-pack + 52 test scripts incl. all three C-6 tests + realistic-ot) is green;
manifest unchanged. **One new finding (SHOULD): a SEVENTH live pack-surface monolith read
site — `tracker_migrate_status_report` (`tracker-migrate-forward.sh:1427-1442`) — was missed
by the architect's "6-site census" and is unmapped to any commit.** It is dormant (the deleted
monolith makes the `-f` test false → reports `(no BACKLOG.md)`; no CI red), so NOT a C-6
commit blocker, but it is exactly the POQ-1 class and must be retired-or-errored before the
C-8 flip. Not in C-6's named scope to fix.

---

## Check results

### Check 1 — Agent-read repoint (C4) — **PASS**
- `git diff --name-only` = the 6 expected files; no others. Single hunk in agent-read at
  `@@ -244,27 +244,40 @@` — entirely inside the fall-through region.
- Pack `BD-*` and `*)` default now FAIL LOUD with a typed `not-found` (no monolith fallback):
  - `*)` default (`:266-269`): `tracker_error_emit "not-found" "... no monolith fallback —
    BD-203 no-mirror SSOT"` + `return 1`.
  - `BD-*` (`:272-275`): same typed error naming `$repo_root/backlog/$pack_id.md`.
- The prefer-branch (lines 1-243, reads `/backlog/BD-NNN.md` directly via `pe`-style
  back-pointer strip) is UNTOUCHED — the BD-* tree read already lives there; C-6 only removes
  the deleted-monolith *fallback*.
- The project `TD-*`/`phase-*` mirror-path branch (`:277-285`) is byte-preserved: the removed
  lines were exactly `BD-*) mirror_path=".../pack-ops/BACKLOG.md"` and the `*) → pack-ops`
  default; `TD-* → docs/project/BACKLOG.md` and `phase-* → docs/project/IMPLEMENTATION-PLAN.md`
  remain, and the downstream python parse (`:287-309`) is unchanged.
- Minor structural note (NIT-1): the fall-through is now a `case` (`BD-*|TD-*|phase-*) : ;;` /
  `*) error`) FOLLOWED by a separate `if [[ "$pack_id" == BD-* ]]` error block. Functionally
  correct (BD-* and `*)` both error; TD-*/phase- pass to the mirror block) but two passes where
  one `case` arm could carry the BD-* error too. Cosmetic; no behavior issue.

### Check 2 — Doctor repoint (C7b) — **PASS**
- Single hunk `@@ -111,49 +111,81 @@` inside `tracker_doctor_run` (d)-block only.
- Pack branch (`:126-154`) now stats `$repo_root/backlog/_toc.md` mtime vs
  `migration.last_forward_run`, emitting `/backlog tree regen index` OK/WARN, or
  `[INFO] /backlog/_toc.md absent` — the no-mirror analogue of the old monolith-header mtime
  (DP-4 cadence). Never reads `pack-ops/BACKLOG.md`.
- Project `*)` branch (`:155-187`): RELOCATED verbatim. Pre-C-6 the project logic lived in a
  shared `if [[ -n "$backlog_path" ]]` block AFTER `esac`; it is now moved INSIDE the `*)` arm.
  The `docs/project/BACKLOG.md` → legacy `$repo_root/BACKLOG.md` resolution, the `<!--`
  header check, mtime compare, `BACKLOG.md mirror is current/older` OK/WARN, `n_warn`
  increment, `mirror-rebuild` hint, and the no-header `[INFO]` line are byte-for-byte
  unchanged. Confirmed NO logic change — relocation only.

### Check 3 — POQ-1: `--mirror-only` pack branch retired — **PASS**
- `tracker-migrate-forward.sh:765-792`. On `surface=="pack"` (`:777-781`) the short-circuit now
  emits `tracker_error_emit "validation" "... not applicable on the no-mirror pack surface ...
  BD-203 deleted pack-ops/BACKLOG.md."` + `return 1` BEFORE any `backlog_path` assignment,
  `_tmf_regen_mirror`, or monolith read.
- The client `else` path is byte-unchanged: `backend_slug` + `backlog_path="$repo_root/
  BACKLOG.md"` (`:782-784`), the `! -f` not-found guard (`:785-788`), `_tmf_regen_mirror`
  (`:790`), and the success echo (`:791`) are preserved. The pre-C-6 `local backend_slug
  backlog_path` was relocated from the top of the block to after the pack-error-return — a
  behavior-preserving move since the pack branch returns before reaching it.

### Check 4 — No pack monolith remains — **PASS for the 3 named files; FINDING F-1 in a 4th site**
`grep -rn 'pack-ops/BACKLOG.md' scripts/lib/tracker-agent-read.sh scripts/lib/tracker-doctor.sh
scripts/lib/tracker-migrate-forward.sh`:
```
tracker-agent-read.sh:255:    # ... comment
tracker-doctor.sh:116:        # ... comment
tracker-migrate-forward.sh:767:  # ... comment
tracker-migrate-forward.sh:779:  "... BD-203 deleted pack-ops/BACKLOG.md."   (error-message string)
tracker-migrate-forward.sh:803:  # ... comment
tracker-migrate-forward.sh:1425:  # BD-175: pack-side BACKLOG canonical at pack-ops/BACKLOG.md.
tracker-migrate-forward.sh:1428:      mirror_path="$repo_root/pack-ops/BACKLOG.md"   ← LIVE CODE
```
- The three C-6-named pack read/regen paths (agent-read fall-through, doctor freshness,
  mirror-only short-circuit) are gone — remaining hits in those scopes are comments + the one
  legitimate error-message string.
- **`:1428` is a LIVE pack-surface monolith read** in `tracker_migrate_status_report()`
  (function header `:1391`), NOT a comment. See F-1.
- `validate-pack.py` Check 32′ GREEN (exit 0).

### Check 5 — Project branches byte-unchanged (the key pack/project check) — **PASS**
Every diff hunk is in a pack-surface branch:
- agent-read hunk `244-271` — fall-through; TD-*/phase- mirror lines preserved (Check 1).
- doctor hunk `111-188` — (d)-block; `*)` project logic relocated verbatim (Check 2).
- forward hunk `763-788` — mirror-only pack branch; client `else` preserved (Check 3).
No `project-template/` or `supporting-docs/` in `git diff --name-only` (CLEAN). No
TD-*/phase-*/client-`else` logic change. `test-v11-realistic-ot.sh` 33/33 green (no project
regression). **No project-branch change → no BLOCKER.**

### Check 6 — Tests genuine — **PASS**
- **agent-read-test (Group 2/5):** 2.1 now asserts `Source: flat-file (per-entry:` +
  `backlog/BD-001.md` (tree read) and that the back-pointer is stripped; 2.7 asserts the
  no-tree `not-found` + `"no monolith fallback"`, AND plants a STALE `pack-ops/BACKLOG.md`
  sentinel and asserts `STALE MONOLITH` never appears (defensive — proves the deleted monolith
  is never consulted); 5.7 (`*)` unknown prefix) asserts `not-found` + `"no monolith fallback"`.
  Coverage strengthened, not weakened.
- **bd130-doctor-wired (new Group 8, 8.1-8.4):** sources the lib + deps, runs
  `tracker_doctor_run` against a pack fixture holding the `/backlog` tree + `_toc.md` AND a
  stale `pack-ops/BACKLOG.md` sentinel; asserts the output names `/backlog`, does NOT contain
  `BACKLOG.md mirror` or `BACKLOG.md has read-only mirror header`, and emits no `command not
  found`. Genuine end-to-end pack-surface assertion. Suite 24/24 green.
- **migrate-forward Test 4.5:** rewritten to seed the per-entry tree (no monolith) and assert
  the pack `--mirror-only` returns non-zero, `ERROR: validation`, the "not applicable on the
  no-mirror pack surface" message, that NO `pack-ops/BACKLOG.md` is written, 0 gh calls, and no
  id-map. Replaces the old "header refreshed" success assertions correctly.

### Check 7 — FULL CI suite — **PASS (all green @ `4ab4a08`)**
Enumerated the `tests` set from `.github/workflows/validate-pack.yml` (1 validate-pack + 52
test scripts) and ran the entire set.

| Suite | Result |
|---|---|
| `python3 scripts/validate-pack.py` | **PASSED — all checks clean** (exit 0); Check 32′ green; Check 48 advisory removed-doc WARNs only (pre-existing) |
| 6 migrator/detect/persona (`test-detect` 100, `-core` 19, `-manifest` 12, `-capability` 12, `-skills` 19, persona PASS) | all exit 0 |
| 16 batch-1 tracker/per-entry/migrate/template tests (per-entry 57/57, etc.) | all exit 0 |
| 14 validate-pack per-check tests (16/18/19/39-46/removed-doc/32-33-34=85/85/36-37-38) | all exit 0 |
| `tracker-agent-read-test.sh` (**C-6**) | **All tests passed** (exit 0) |
| `tracker-bd130-doctor-wired-test.sh` (**C-6**, new Group 8) | **24 passed / 0 failed** |
| `tracker-migrate-forward-test.sh` (**C-6**, Test 4.5) | **All tests passed** (exit 0) |
| `tracker-migrate-reverse-test.sh` / `-roundtrip-test.sh` / `tracker-provider-test.sh` | all **All tests passed** |
| `tracker-bd129/132/133/134`, config/config-schema/errors/init | all exit 0 |
| `test-v11-realistic-ot.sh` | **33/33 PASSED** (no project regression; banner-pinning green) |
| `git diff --name-only` | the 6 expected `scripts/` files only — `pack-only` clean |
| `test-fixtures/manifest.txt` | `build.sh --all --clean` produces **no diff** — manifest unchanged (changed files are `scripts/lib`+`scripts/tests`, not manifest-tracked); restored via `git checkout`. Manifest-regen rule satisfied (nothing to stage). |

**Aggregate: 53/53 CI commands exit 0. Zero failures.**

---

## Severity-ranked findings

- **BLOCKER:** none.
- **MUST:** none.
- **SHOULD:** **F-1 — a SEVENTH live pack-surface monolith read site, unmapped to any commit.**
  `tracker_migrate_status_report()` (`tracker-migrate-forward.sh:1391`) at `:1427-1442` does, on
  `surface=="pack"`, `mirror_path="$repo_root/pack-ops/BACKLOG.md"` and stats it for a "mirror
  freshness" status line (`tracker status` output). Invoked on the pack surface by
  `pack-tracker.sh:125` and `tracker-migrate.sh:120` (the `pack tracker status` command).
  - The architect's §2.2 "complete monolith-site census" (ARCHITECTURE-BD-204.md:298-308)
    grepped this exact file and reported "6 distinct runtime monolith sites" — this site was
    MISSED. It is not assigned to C-2..C-7 in PLAN-BD-204.
  - Dormant, so NOT a C-6 commit blocker and out of C-6's named scope to FIX: with the monolith
    deleted, `[[ -f "$mirror_path" ]]` is false → it reports `mirror_age="(no BACKLOG.md)"`. No
    CI red, no regression. But it is the SAME class as POQ-1 (a live pack-surface code path
    still pointed at the deleted monolith), and once C-8 flips the pack to a no-monolith tracker
    repo, this status line is permanently wrong/misleading rather than retired.
  - Per `deferred-work-tracked-anchor` + `fail-loud-delete-old-source`: this needs a concrete
    anchor before C-8. Natural fits: fold the status-report pack branch repoint (point at the
    `/backlog/_toc.md` regen-state, mirroring the C7b doctor fix) into a C-6 follow-up or open a
    tracked item. Surfaced, not fixed (read-only review).
- **NIT:** **NIT-1** — agent-read fall-through uses a `case` arm plus a separate `if BD-*`
  block where one `case` could carry both errors (Check 1). Cosmetic; no behavior impact.
- **NIT:** **NIT-2** — the `:1425` comment `# BD-175: pack-side BACKLOG canonical at
  pack-ops/BACKLOG.md` is now stale (the monolith is deleted); it sits above the F-1 site and
  should be corrected when F-1 is fixed.

---

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured @ `4ab4a08`) | Conclusion |
|---|---|---|
| **Fail-loud / no monolith (pack)** | agent-read pack `BD-*`+`*)` → typed `not-found`+`return 1` (`:266-275`, "no monolith fallback"); doctor pack reads `/backlog/_toc.md` not the monolith (`:126-154`); `--mirror-only` pack → `ERROR: validation`+`return 1` before any regen (`:777-781`); Check 32′ green (exit 0). RESIDUAL: a 7th live site `tracker-migrate-forward.sh:1428` (`tracker_migrate_status_report`) still reads `pack-ops/BACKLOG.md` on pack — surfaced as F-1 (dormant; missed by the 6-site census). | COMPLIANT for the 3 named C-6 sites; F-1 surfaced |
| **Pack/project separation (project branches byte-unchanged)** | `git diff --name-only` = 6 `scripts/` files; no `project-template/`/`supporting-docs/`. Each hunk is pack-surface: agent-read TD-*/phase- mirror lines preserved, doctor `*)` relocated verbatim (logic byte-equal), forward client `else` unchanged. realistic-ot 33/33 green. No project-branch change. | COMPLIANT |
| **Enumerate ENCODING surfaces** | agent-read + doctor + `--mirror-only` repointed IN LOCKSTEP with their three tests in THIS diff: agent-read-test (2.1/2.7/5.7), bd130-doctor-wired (new Group 8 8.1-8.4), migrate-forward (Test 4.5). All three suites green. No asymmetric coverage among the C-6 sites. (Audit gap is F-1: the status-report surface + any test pinning its output are NOT touched — but that is the unmapped 7th site, not a C-6 lockstep failure.) | COMPLIANT for C-6 scope; F-1 noted |
| **Verify the FULL CI suite, not just validate-pack** | Enumerated the workflow `tests` set (1 validate-pack + 52 scripts); ran ALL; 53/53 exit 0, counts quoted in Check 7; realistic-ot banner-pinning 33/33. | COMPLIANT |
| **Empirical evidence** | Every finding cites `git diff` hunk ranges (`244-271`/`111-188`/`763-788`) + file:line anchors + grep output (the 7-line `pack-ops/BACKLOG.md` grep with the `:1428` live hit) + caller grep (`pack-tracker.sh:125`, `tracker-migrate.sh:120`) + census quote (arch `:298-308` "6 distinct runtime monolith sites") + CI exit codes/counts. | COMPLIANT |
| **Regenerate manifest on v11-surface commits** | diff touches `scripts/` (v11-surface); `build.sh --all --clean` → no diff to `test-fixtures/manifest.txt`; nothing to stage; rule satisfied. Restored to HEAD via `git checkout`. | COMPLIANT |
| **Agents never commit / read-only** | No git state-changing verb run; manifest regen reverted via `git checkout`; working tree = the 6 coder files (+ unread IMPL-REPORT). Sole write = this report. | COMPLIANT |
| **Rules-Applied Verification Block** | This table; every row carries quoted/measured evidence (none empty). | COMPLIANT |

### READ-IN-FULL attestation (this session, HEAD `4ab4a08`)
| File | Proof |
|---|---|
| `PLAN-BD-204.md` § Commit C-6 | Read `:385-451` — file scope (agent-read BD-*+`*)`/doctor pack/2 tests), recipe (C4 repoint + C7b `_toc.md`), TD-*/phase- "UNTOUCHED = pack-only VIOLATION", verification battery. |
| `ARCHITECTURE-BD-204.md` C4/C7b + census | Read `:296-323` (6-site census EE block + retire/repoint table rows C4/C7b) + DP-4 `:184-202` (`_toc.md` regen cadence) — confirmed the census reports "6 distinct runtime monolith sites" and missed `:1428`. |
| `PACK-REVIEW-BD-204-C5.md` F-2/POQ-1 | Read full (1-212) — POQ-1 named the `--mirror-only` short-circuit only (`:765-782`), recommended folding the retire into C-6; C-6 discharges it. |
| 3 lib files | agent-read `:200-309`, doctor `:110-194`, forward `:760-793` + `:1391-1442` read directly (pack vs project/client branches). |
| full `git diff` | Read in full (6 files: 3 libs + 3 tests) from the tool result. |
| 3 test files | agent-read-test (Group 2/5 hunks), bd130-doctor-wired (Group 8), migrate-forward (Test 4.5) read from the diff. |
| `.github/workflows/validate-pack.yml` | Read — extracted the full 53-command `tests` set; ran it all. |
| `CLAUDE.md` ## Pack memory | Read in full (session context) — fail-loud, pack/project separation, enumerate-encoding-surfaces, manifest-regen, verify-full-ci, agents-never-commit, deferred-work-tracked-anchor. |

**No named document was derived rather than read. Did NOT read the coder IMPL-REPORT (verified independently).**

**End of PACK-REVIEW-BD-204-C6.md**
