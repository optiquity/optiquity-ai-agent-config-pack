# PACK-REVIEW-BD-204-C6-REVIEW2 — post-fix confirmation (F-1 / NIT-1 / NIT-2 + census closure)

> **Reviewer:** pack-reviewer (READ-ONLY). **HEAD:** `4ab4a08`. **Branch:** `v11-dev`.
> **Scope:** uncommitted C-6 + fix changes (6 pack-side `scripts/` files). **Basis:**
> independent re-grep census + full CI re-run. Did NOT read the coder IMPL-REPORTs.

## HEADLINE: **PASS — fix correct, no regression, census closed**

F-1 is fixed: `tracker_migrate_status_report()` pack branch now reads
`/backlog/_toc.md` (DP-4 tree-regen analogue), never `pack-ops/BACKLOG.md`. The
independent re-grep of `scripts/lib/` finds ZERO live pack-surface monolith reads
— every remaining hit is a comment, an error-message string, a retained metadata
constant, or a client-`else`-only path (the flagged 8th candidate
`tracker-header-snapshot.sh:216-217` is reachable in production only from the
client `else` branch). NIT-1 (fall-through consolidation) and NIT-2 (stale `:1425`
comment) are both fixed with behavior byte-preserved. The rest of C-6 (agent-read
fail-loud tree read, doctor `_toc` repoint, `--mirror-only` POQ-1 error) is intact
and undisturbed by the fix. Project/client branches are byte-unchanged.
**Full CI: 52/52 commands exit 0** (validate-pack + 51 test scripts);
realistic-ot 33/33; manifest unchanged. No findings.

---

## Check results

### Check 1 — F-1 fixed (status-report pack branch repointed) — **PASS**
`tracker_migrate_status_report()` (`tracker-migrate-forward.sh:1391`), pack branch
`:1435-1442`: on `surface=="pack"` it now sets `toc_path="$repo_root/backlog/_toc.md"`
and reports `mirror_age` from its mtime (or `(no /backlog/_toc.md)`). NO
`pack-ops/BACKLOG.md` read — consistent with the C7b doctor repoint and the F-1
recipe.
The client `else` branch (`:1443-1456`) is logic-byte-unchanged — `mirror_path=
"$repo_root/BACKLOG.md"`, the `-f` guard, the `<!--` header check, the
`(no mirror header)` / `(no BACKLOG.md)` outputs. The only diff is re-indent +
`local mirror_path`/`local first_line` now declared inside the `else` (previously
`mirror_path` was declared above the `if`); behavior identical (pack branch
returns its own `mirror_age` before reaching the else). Confirmed re-indent only,
no logic change.

### Check 2 — Census exhaustive + closed (key check) — **PASS**
Independent re-grep `grep -rn 'pack-ops/BACKLOG.md' scripts/lib/` @ `4ab4a08`, every
hit classified:

| File:line | Kind | Pack-surface READ? |
|---|---|---|
| `tracker-agent-read.sh:255` | comment | No |
| `tracker-migrate-reverse.sh:1209` | comment ("pack reverse never writes…") | No |
| `recommendation.sh:132` | comment | No |
| `tracker-header-snapshot.sh:213` | comment | No |
| `tracker-header-snapshot.sh:216-217` | **live code** | **No — client-`else`-only (see below)** |
| `tracker-doctor.sh:116` | comment | No |
| `tracker-migrate-forward.sh:767` | comment | No |
| `tracker-migrate-forward.sh:779` | error-message **string** | No |
| `tracker-migrate-forward.sh:803` | comment | No |
| `tracker-migrate-forward.sh:1425` | comment (post-fix; NIT-2 updated) | No |
| `detect.sh:26` | comment | No |
| `per-entry/_lib.sh:85` | retained metadata **constant** (`mirror` attr; documented dead-for-pack) | No (not a runtime read; deletion-target reference per BD-203) |

**Flagged 8th candidate `tracker-header-snapshot.sh:216-217` — confirmed
client-only.** `tracker_header_snapshot_capture()` is invoked in production by
exactly one site: `tracker-migrate-reverse.sh:1282`, which sits inside the
**client `else`** of the reverse surface branch (`else  # Client surface (legacy
monolith path — BD-207, UNTOUCHED)`). The pack branch (`:1265-1276`) retired
capture in C-4 and emits the per-entry tree directly. The only other callers are
in `tracker-bd133-header-preservation-test.sh` (the BD-133 client/legacy header
test). So `:216-217` is unreachable from any pack-surface path.

**Result: ZERO pack-surface code paths read or regenerate the deleted monolith.**
All three previously-named C-6 sites (agent-read fall-through, doctor freshness,
`--mirror-only`) plus the F-1 status-report site are repointed; `header-snapshot`
is client-only by construction. Census closed.

### Check 3 — NIT-1 + NIT-2 fixed — **PASS**
- **NIT-1 (fall-through consolidation):** `tracker-agent-read.sh:270-283` is now a
  single `case`: `BD-*` and `*)` each `tracker_error_emit "not-found" … "no
  monolith fallback — BD-203 no-mirror SSOT"` + `return 1`; `TD-*` →
  `docs/project/BACKLOG.md`, `phase-*` → `docs/project/IMPLEMENTATION-PLAN.md`
  fall through to the project mirror block. The prior no-op `case` arm + separate
  `if BD-*` error block is gone. Fail-loud strings are byte-identical to review-1's
  observed wording (behavior preserved).
- **NIT-2 (stale comment):** the old `:1425` `# BD-175: pack-side BACKLOG canonical
  at pack-ops/BACKLOG.md` is replaced (`tracker-migrate-forward.sh:1423-1433`) with
  the BD-204 C-6-FIX1 no-mirror reality (tree + `_toc.md` is the SSOT; project
  `else` still reads legacy `BACKLOG.md`). Matches the no-mirror state.

### Check 4 — Rest of C-6 undisturbed — **PASS**
- **agent-read tree-read + fail-loud fallback:** prefer-branch (tree read) untouched;
  fall-through fails loud (`:272-283`) — unchanged by the fix except the NIT-1
  consolidation. Tests 2.1/2.7/5.7 green.
- **doctor `_toc` repoint:** `tracker-doctor.sh:126-154` pack branch stats
  `/backlog/_toc.md` mtime vs `last_forward_run`; `*)` project branch relocated
  verbatim. Not touched by the fix. Group 8 8.1-8.4 green.
- **`--mirror-only` POQ-1 error:** `tracker-migrate-forward.sh:777-781` pack branch
  emits `ERROR: validation` + `return 1` before any regen; client `else` preserved.
  Not touched by the fix. Test 4.5 green.

### Check 5 — Pack/project separation (project branches byte-unchanged) — **PASS**
`git diff --name-only` = the 6 expected `scripts/` files; NO `project-template/`,
NO `supporting-docs/`. Every diff hunk is in a pack-surface branch:
- agent-read: only the pack fall-through arms changed; `TD-*`/`phase-*` mirror
  lines (`:277-278`) byte-preserved.
- doctor: pack arm rewritten; `*)` project arm relocated with logic byte-equal.
- forward `--mirror-only`: pack arm errors; client `else` (`backlog_path=
  "$repo_root/BACKLOG.md"`, `! -f` guard, `_tmf_regen_mirror`) byte-unchanged
  (re-indent only after the pack-return relocation).
- forward status-report: pack arm repointed; client `else` logic byte-unchanged
  (re-indent + scoped `local` only).
`test-v11-realistic-ot.sh` 33/33 PASSED — no project regression.

### Check 6 — Tests genuine — **PASS**
- **migrate-forward 3.10b (NEW, F-1 coverage):** plants `/backlog/_toc.md` AND a
  stale `pack-ops/BACKLOG.md` `<!--`-header sentinel, then asserts the
  `mirror freshness:` line equals the `_toc.md` mtime, never names
  `pack-ops/BACKLOG.md`, and never shows `(no mirror header)` (which would prove the
  deleted monolith was inspected). All 3 sub-asserts PASS. Positive + defensive —
  coverage strengthened, not weakened.
- **agent-read 2.7/5.7:** 2.7 plants a STALE monolith sentinel and asserts
  `STALE MONOLITH` never appears + `not-found` + `no monolith fallback`; 5.7 (`*)`
  unknown prefix) asserts `not-found` + `no monolith fallback`. PASS.
- **bd130 Group 8 (8.1-8.4):** pack fixture with tree + stale monolith; asserts
  doctor reports `/backlog`, NOT `BACKLOG.md mirror`, NOT the mirror header, no
  `command not found`. PASS.
- **migrate-forward 4.5:** asserts pack `--mirror-only` returns non-zero,
  `ERROR: validation`, the no-mirror message, writes no monolith, 0 gh calls, no
  id-map. PASS. No coverage weakened.

### Check 7 — FULL CI suite — **PASS (52/52 exit 0)**
Enumerated all 52 `run:` commands from `.github/workflows/validate-pack.yml`
(1 `validate-pack.py` + 51 test scripts) and ran every one.

| Phase | Commands | Result |
|---|---|---|
| validate-pack + 6 migrator/detect/persona | 7 | 7/7 exit 0 |
| 22 tracker + per-entry + 13 per-check validate tests | 28 | 28/28 exit 0 |
| 5 bd-tests + recommendation/pack-help + 6 customize/init/migrate + realistic-ot + 3 template/issue | 17 | 17/17 exit 0 |
| **Aggregate** | **52** | **52/52 exit 0 — zero failures** |

Spot-confirmed: `validate-pack.py` PASS (Check 32′ green); realistic-ot **33/33
PASSED**; agent-read **57 passed / 0 failed**; bd130-doctor **24 passed / 0
failed**; migrate-forward **148 passed / 0 failed**.
**Manifest:** `bash test-fixtures/build.sh --all --clean` → `git diff --quiet
test-fixtures/manifest.txt` reports **MANIFEST UNCHANGED** (restored via
`git checkout`; nothing to stage).

---

## Severity-ranked findings

**None.** F-1, NIT-1, NIT-2 all fixed correctly; census closed; no regression;
full CI green.

(Observation, NOT a C-6 finding: `per-entry/_lib.sh:85` retains
`pack-ops/BACKLOG.md` as the `mirror` metadata constant — documented dead-for-pack
per BD-203, the deletion-target reference for project streams pending BD-206. Not a
runtime read; out of C-6 scope; no action needed at C-6.)

---

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured @ `4ab4a08`) | Conclusion |
|---|---|---|
| **Fail-loud / no monolith + exhaustive census** | Independent `grep -rn 'pack-ops/BACKLOG.md' scripts/lib/` → 13 hits, each classified (Check 2 table): 9 comments, 1 error-string (`:779`), 1 dead-for-pack constant (`_lib.sh:85`), 1 client-`else`-only live block (`tracker-header-snapshot.sh:216-217`, caller `tracker-migrate-reverse.sh:1282` inside the `else  # Client surface`), 0 pack-surface reads. F-1 site `tracker-migrate-forward.sh:1435-1442` now reads `/backlog/_toc.md`. Check 32′ green. | COMPLIANT |
| **Pack/project separation (project branches byte-unchanged)** | `git diff --name-only` = 6 `scripts/` files; no `project-template/`/`supporting-docs/`. agent-read TD-*/phase- arms preserved; doctor `*)` relocated verbatim; forward `--mirror-only` + status-report `else` logic byte-unchanged (re-indent + scoped `local` only). realistic-ot 33/33. | COMPLIANT |
| **Verify the FULL CI suite, not just validate-pack** | Enumerated 52 `run:` commands from `validate-pack.yml`; ran ALL; 52/52 exit 0 (Check 7 table + spot counts: realistic-ot 33/33, agent-read 57/0, bd130 24/0, migrate-forward 148/0). Manifest unchanged. | COMPLIANT |
| **Empirical evidence** | Every check cites file:line anchors (`:1435-1442`, `:270-283`, `:1423-1433`, `:777-781`, `:126-154`), the classified grep census, the caller-chain grep (`tracker_header_snapshot_capture` → `:1282` client `else`), CI exit aggregate, and the `git diff --quiet` manifest result. | COMPLIANT |
| **Rules-Applied Verification Block** | This table; every row carries quoted/measured evidence (none empty). | COMPLIANT |

### READ-IN-FULL attestation (this session, HEAD `4ab4a08`)
| File | Proof |
|---|---|
| `PACK-REVIEW-BD-204-C6.md` (F-1/NIT findings) | Read full (1-195) — F-1 = 7th live site `tracker_migrate_status_report`; NIT-1 = fall-through `case`+`if` redundancy; NIT-2 = stale `:1425` comment. |
| full `git diff` (6 files) | Read in full from the saved tool result (3 libs + 3 tests). |
| `tracker-migrate-forward.sh` `tracker_migrate_status_report` + C-6 regions | Read `:1390-1479` directly (pack vs client branch). |
| `tracker-agent-read.sh` fall-through | Read `:244-283` (NIT-1 consolidation + fail-loud strings). |
| `tracker-header-snapshot.sh:198-234` + caller chain | Read; caller grep → `tracker-migrate-reverse.sh:1282`; read `:1255-1299` (client `else`). |
| `.github/workflows/validate-pack.yml` | Enumerated all 52 `run:` commands; ran them all. |
| `CLAUDE.md` ## Pack memory | Read in full (session context) — fail-loud-delete-old-source, pack/project separation, verify-full-ci, empirical-evidence, rules-applied-block. |

**No named document was derived rather than read. Did NOT read the coder
IMPL-REPORTs (verified independently).**

**End of PACK-REVIEW-BD-204-C6-REVIEW2.md**
