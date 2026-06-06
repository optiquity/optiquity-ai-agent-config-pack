# IMPL-REPORT-BD-204-C6-FIX1 — C-6 review fixes (F-1 + NIT-1 + NIT-2)

> **Coder:** pack-coder (fix pass). **Branch:** `v11-dev`. **Base HEAD:** `4ab4a08`
> (no commits made — see Agents-never-commit). **Scope:** pack-only; the
> uncommitted Commit C-6 working tree + this fix pass on top.
>
> Applies the three findings from `PACK-REVIEW-BD-204-C6.md`: **F-1** (the 7th
> live pack-surface monolith read in `tracker_migrate_status_report`), **NIT-2**
> (its stale `:1425` comment), **NIT-1** (agent-read fall-through consolidation).

---

## Pre-flight (HEAD `4ab4a08`, branch `v11-dev`)

- `git rev-parse HEAD` → `4ab4a08a4bf908b7d0a4fa8e9ecab7e3a65e2f38`.
- `git status` → 6 modified `scripts/` files (the C-6 working tree) + 2 untracked
  C-6 reports. Clean otherwise.
- Verified base contains the named docs (`PACK-REVIEW-BD-204-C6.md`, the 3 lib
  files, the workflow). Base correct → proceeded.

---

## Files changed in THIS fix pass (3)

| Path | Change type | Finding |
|---|---|---|
| `scripts/lib/tracker-migrate-forward.sh` | modified | **F-1** (status-report pack repoint) + **NIT-2** (comment) |
| `scripts/lib/tracker-agent-read.sh` | modified | **NIT-1** (fall-through consolidation) |
| `scripts/tests/tracker-migrate-forward-test.sh` | modified | Test **3.10b** (pin pack status reads the tree) |

The other 3 C-6 files (`tracker-doctor.sh`,
`tracker-bd130-doctor-wired-test.sh`, `tracker-agent-read-test.sh`) carry the
prior coder's C-6 changes and were **NOT touched** in this pass.

`git diff --name-only` (whole working tree = C-6 + this fix):
```
scripts/lib/tracker-agent-read.sh
scripts/lib/tracker-doctor.sh
scripts/lib/tracker-migrate-forward.sh
scripts/tests/tracker-agent-read-test.sh
scripts/tests/tracker-bd130-doctor-wired-test.sh
scripts/tests/tracker-migrate-forward-test.sh
```
No `project-template/` / `supporting-docs/` — **pack-only clean.**

---

## F-1 — `tracker_migrate_status_report` pack branch repointed off the monolith

**Problem (from review):** on `surface=="pack"` the function set
`mirror_path="$repo_root/pack-ops/BACKLOG.md"` (former `:1428`, LIVE code) and
stat'd it for the "mirror freshness" status line — the 7th live pack-surface
monolith read, missed by the architect's 6-site census. Invoked on pack by
`pack tracker status` (`pack-tracker.sh` → `tracker-migrate.sh` →
`tracker_migrate_status_report`).

**Fix:** the PACK branch now reads the `/backlog/_toc.md` tree regen index mtime
— the no-mirror analogue of the old monolith-header mtime (DP-4 regen cadence),
**identical in shape to the C7b doctor repoint**. The CLIENT `else` branch keeps
reading `$repo_root/BACKLOG.md` with its `<!--` header check, byte-equivalent to
pre-C-6 (only re-indented one level into the `else`). Final code:

```sh
    # Mirror / tree-regen freshness.
    #
    # BD-204 C-6-FIX1 (F-1 REPOINT): the pack monolith `pack-ops/BACKLOG.md`
    # is DELETED (BD-203 no-mirror SSOT — the `/backlog/` per-entry tree
    # + generated `_toc.md` index IS the pack SSOT, there is no
    # regenerated monolithic mirror). On the PACK surface the
    # "mirror freshness" line maps to the tree's regen-state via the
    # `_toc.md` mtime — the no-mirror analogue of the old monolith-header
    # mtime (DP-4 regen cadence), mirroring the C7b doctor repoint. The
    # PROJECT (`else`) surface still reads the legacy `BACKLOG.md`
    # monolith mirror header (BD-207 owns the client tree repoint).
    local mirror_age
    if [[ "$surface" == "pack" ]]; then
        local toc_path
        toc_path="$repo_root/backlog/_toc.md"
        if [[ -f "$toc_path" ]]; then
            mirror_age=$(date -r "$toc_path" -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo "unknown")
        else
            mirror_age="(no /backlog/_toc.md)"
        fi
    else
        local mirror_path
        mirror_path="$repo_root/BACKLOG.md"
        if [[ -f "$mirror_path" ]]; then
            local first_line
            first_line=$(head -n 1 "$mirror_path" 2>/dev/null || echo "")
            if [[ "$first_line" == "<!--" ]]; then
                mirror_age=$(date -r "$mirror_path" -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo "unknown")
            else
                mirror_age="(no mirror header)"
            fi
        else
            mirror_age="(no BACKLOG.md)"
        fi
    fi
```

**Client-`else` byte-preservation proof:** `git diff` shows the `else` block's
`mirror_path="$repo_root/BACKLOG.md"`, the `[[ -f ]]` guard, the `first_line` /
`<!--` header check, and all three `mirror_age` outcomes
(`mtime` / `(no mirror header)` / `(no BACKLOG.md)`) unchanged — only one extra
level of indentation. The `$mirror_path` variable is now scoped inside `else`
only; the heredoc references `$mirror_age` (`:1489`), not `$mirror_path`.

## NIT-2 — stale `:1425` comment corrected

The old comment `# BD-175: pack-side BACKLOG canonical at pack-ops/BACKLOG.md.`
is replaced by the multi-line `BD-204 C-6-FIX1 (F-1 REPOINT)` block quoted above,
stating the canonical no-mirror reality (the `/backlog/` tree + `_toc.md` IS the
pack SSOT; no regenerated monolith) and citing BD-204 / BD-203.

## NIT-1 — agent-read fall-through consolidated (behavior-preserving)

**Before:** a `case "$pack_id"` with a no-op arm `BD-*|TD-*|phase-*) : ;;` + a
`*) error` arm, FOLLOWED by a separate `if [[ "$pack_id" == BD-* ]]` error block,
then a second `case` assigning `mirror_path` for TD-*/phase-. Two passes.

**After:** one `case` dispatches everything — `BD-*)` errors, `*)` errors,
`TD-*)` / `phase-*)` assign `mirror_path` and fall through to the project mirror
block. The `local mirror_path=""` declaration was hoisted above the `case`:

```sh
    local mirror_path=""
    case "$pack_id" in
        BD-*)
            tracker_error_emit "not-found" \
                "agent_read: $pack_id not found in pack per-entry tree at $repo_root/backlog/$pack_id.md (no monolith fallback — BD-203 no-mirror SSOT)"
            return 1
            ;;
        TD-*)    mirror_path="$repo_root/docs/project/BACKLOG.md" ;;
        phase-*) mirror_path="$repo_root/docs/project/IMPLEMENTATION-PLAN.md" ;;
        *)
            tracker_error_emit "not-found" \
                "agent_read: $pack_id not found in pack per-entry tree at $repo_root/backlog (no monolith fallback — BD-203 no-mirror SSOT)"
            return 1
            ;;
    esac
```

**Behavior preserved exactly:** the BD-* and `*)` error message strings are
byte-identical to before (the fail-loud "no monolith fallback — BD-203 no-mirror
SSOT" stays); TD-*/phase- `mirror_path` assignments are byte-identical; the
downstream `[[ ! -f "$mirror_path" ]]` not-found guard + python parse are
untouched. Confirmed by `tracker-agent-read-test.sh` 57/57 green (incl. 2.7 +
5.7 which assert the fail-loud not-found on the BD-* and `*)` paths).

---

## GREP-EXHAUSTIVE census — `pack-ops/BACKLOG.md` in `scripts/lib/` (post-fix)

`grep -rn 'pack-ops/BACKLOG.md' scripts/lib/` @ post-fix working tree:

```
scripts/lib/tracker-agent-read.sh:255:    # BD-204 C-6 (C4 REPOINT): the pack monolith `pack-ops/BACKLOG.md`
scripts/lib/recommendation.sh:132:    # (the no-mirror SSOT) — there is no monolithic pack-ops/BACKLOG.md.
scripts/lib/tracker-migrate-reverse.sh:1209:        # pack reverse never writes pack-ops/BACKLOG.md or pack-ops/CHANGELOG.md.
scripts/lib/tracker-doctor.sh:116:    # BD-204 C-6 (C7b REPOINT): the pack monolith `pack-ops/BACKLOG.md`
scripts/lib/tracker-header-snapshot.sh:213:    # BD-175: pack-side BACKLOG canonical at pack-ops/BACKLOG.md; client
scripts/lib/tracker-header-snapshot.sh:216:    if [[ -f "$repo_root/pack-ops/BACKLOG.md" ]]; then
scripts/lib/tracker-header-snapshot.sh:217:        backlog_path="$repo_root/pack-ops/BACKLOG.md"
scripts/lib/tracker-migrate-forward.sh:767:        # `pack-ops/BACKLOG.md` is DELETED (BD-203 no-mirror SSOT). On
scripts/lib/tracker-migrate-forward.sh:779:                "forward --mirror-only: ... BD-203 deleted pack-ops/BACKLOG.md."
scripts/lib/tracker-migrate-forward.sh:803:    # `pack-ops/BACKLOG.md` to read. The client `else` branch keeps reading
scripts/lib/tracker-migrate-forward.sh:1425:    # BD-204 C-6-FIX1 (F-1 REPOINT): the pack monolith `pack-ops/BACKLOG.md`
scripts/lib/per-entry/_lib.sh:85:                mirror) printf 'pack-ops/BACKLOG.md' ;;
scripts/lib/detect.sh:26:#                   SSOT; there is no monolithic pack-ops/BACKLOG.md).
```

### Classification of EVERY hit

| # | File:line | Kind | Classification | Rationale |
|---|---|---|---|---|
| 1 | `tracker-agent-read.sh:255` | comment | **KEEP** | C4 repoint doc comment; no read. |
| 2 | `recommendation.sh:132` | comment | **KEEP** | "there is no monolith" doc comment; no read. |
| 3 | `tracker-migrate-reverse.sh:1209` | comment | **KEEP** | "pack reverse never writes" doc comment; no read. |
| 4 | `tracker-doctor.sh:116` | comment | **KEEP** | C7b repoint doc comment; no read. |
| 5 | `tracker-header-snapshot.sh:213` | comment | **KEEP** | stale-ish BD-175 comment, but in **client-only-reachable** code (see #6/#7) and OUT OF THIS PASS'S pack-only SCOPE — surfaced below as an observation. |
| 6 | `tracker-header-snapshot.sh:216` | **LIVE code** | **KEEP (client-`else`-reachable, NOT a pack-surface read)** | `tracker_header_snapshot_capture` reads this only when invoked; its sole non-test caller is `tracker-migrate-reverse.sh:1282`, inside the reverse **client `else` branch** (`:1277` opens `else`; pack branch `:1265-1276` retired the capture in C-4). NEVER reached on pack. |
| 7 | `tracker-header-snapshot.sh:217` | **LIVE code** | **KEEP** | same site as #6 — the `backlog_path=` assignment under the client-only `[[ -f ]]`. |
| 8 | `tracker-migrate-forward.sh:767` | comment | **KEEP** | `--mirror-only` POQ-1 doc comment; no read. |
| 9 | `tracker-migrate-forward.sh:779` | error-message string | **KEEP** | the typed `validation` error text for the retired `--mirror-only` pack branch; legitimate string, not a read. |
| 10 | `tracker-migrate-forward.sh:803` | comment | **KEEP** | doc comment naming the client `else` branch; no read. |
| 11 | `tracker-migrate-forward.sh:1425` | comment | **KEEP** | the **NEW** NIT-2 F-1-repoint doc comment (was the LIVE `:1428` read pre-fix). |
| 12 | `per-entry/_lib.sh:85` | constant string in `case` | **KEEP** | `pe__stream_attr pack-backlog mirror` returns this string as a historical/deletion-target attribute; comment `:79-84` states it is RETAINED-only / dead-for-pack. Does NOT read/regen the file. Consumers (`init-project.sh:1124`, `decompose.sh:195`) pass `mirror_path` explicitly for **project/migration** streams, never to read `pack-ops/BACKLOG.md`. |
| 13 | `detect.sh:26` | comment | **KEEP** | "there is no monolith" doc comment; no read. |

**Result:** the former LIVE pack-surface read at `tracker-migrate-forward.sh:1428`
is GONE (now the comment at `:1425`). After the fix, the ONLY remaining LIVE-code
hits in `scripts/lib/` are #6/#7 (`tracker-header-snapshot.sh`) which are
**client-`else`-reachable only** (reachability proven below) and #12
(`per-entry/_lib.sh`) which is a dormant constant string, not a read.

**ZERO pack-surface code path reads or regenerates `pack-ops/BACKLOG.md`.** Only
client-`else` paths, comments, constant strings, and error strings mention it.

### Reachability proof for the 8th-site candidate (#6/#7)

The review's census found 7 sites. My exhaustive sweep surfaced an 8th LIVE-code
candidate (`tracker-header-snapshot.sh:216-217`) that the prompt warned to catch.
Proof it is NOT a pack-surface read:

- Sole non-test caller: `grep -rn 'tracker_header_snapshot_capture' scripts/lib/`
  → declaration `:71` (guard) + call `:1282` in `tracker-migrate-reverse.sh`.
- `:1282` sits in the reverse **client `else`** (`if [[ "$surface" == "pack" ]]`
  at `:1265`; `else` at `:1277`; the pack branch `:1265-1276` emits the per-entry
  tree directly and explicitly **retired** header-snapshot in C-4, per the
  `:1258-1263` comment).
- The test `tracker-bd133-header-preservation-test.sh:216` documents this
  invariant verbatim: reverse does "NOT call tracker_header_snapshot_capture /
  _apply on the pack surface."

So `:216-217` reads `pack-ops/BACKLOG.md` only with a CLIENT repo-root, never on
pack → classified KEEP (client-`else`-reachable). It is also OUTSIDE this pass's
scoped files (`tracker-migrate-forward.sh` + `tracker-agent-read.sh`); I left it
byte-unchanged. **Observation (not a fix):** the `:213` BD-175 comment is mildly
stale in wording, but the code path is correct (client-only). A future BD-207
client-tree repoint owns `tracker-header-snapshot.sh`; touching it here would be
out-of-scope and would touch a non-named file.

---

## Test updates

`scripts/tests/tracker-migrate-forward-test.sh` — added **Test 3.10b** right
after the existing 3.10 status-surface field assertions. It encodes the F-1
invariant in lock-step with the source fix (enumerate-encoding-surfaces):

- Seeds a PACK-surface repo (`pack-ops/` marker) with the `/backlog` tree +
  plants a real `/backlog/_toc.md` regen index, captures its mtime.
- Plants a STALE `pack-ops/BACKLOG.md` sentinel with a V1 `<!--` header (so if
  the pack branch ever read it, `mirror_age` would become its mtime or
  `(no mirror header)`).
- **Positive:** asserts the `mirror freshness:` line == the `/backlog/_toc.md`
  mtime.
- **Negative (defensive):** asserts the status output NEVER names
  `pack-ops/BACKLOG.md`, and the mirror line never shows `(no mirror header)`
  (which would prove the deleted monolith was consulted).

New assertions (all PASS):
```
PASS 3.10b pack mirror freshness reads /backlog/_toc.md mtime
PASS 3.10b pack status never names pack-ops/BACKLOG.md
PASS 3.10b pack status never inspects the monolith header
```

All existing C-6 test additions remain intact and green (agent-read-test
2.1/2.7/5.7; bd130-doctor-wired Group 8 8.1-8.4; migrate-forward Test 4.5).

---

## Verification — FULL CI suite (enumerated from `.github/workflows/validate-pack.yml`)

| Command | Result |
|---|---|
| `python3 scripts/validate-pack.py` | **PASSED — all checks clean** (exit 0); Check 32′ green; Check 48 removed-doc advisory WARNs only (pre-existing, exit unaffected) |
| Full `tests` battery (50 scripts: detect, all tracker-*, per-check 16/18/19/39-46/removed-doc/32-33-34/36-37-38, bd129-134, recommendation, pack-help, customization-preserve, init-project, migrate-v10-to-v11 ×4, migrator core/manifest/capability/skills, persona-contracts, template-translations, template-version, issue-forms) | **pass=50 fail=0** (all exit 0) |
| `tracker-migrate-forward-test.sh` (F-1 + Test 3.10b) | **148 passed / 0 failed** |
| `tracker-agent-read-test.sh` (NIT-1) | **57 passed / 0 failed** |
| `tracker-bd130-doctor-wired-test.sh` (C-6, untouched) | **24 passed / 0 failed** |
| `bash test-fixtures/build.sh --all --clean` | exit 0; `git diff --stat test-fixtures/manifest.txt` → **no diff** (manifest unchanged; restored to HEAD) |
| `bash test-fixtures/build.sh --verify` | exit 0 (all 3 fixtures OK) |
| `bash scripts/tests/test-v11-realistic-ot.sh` | **33/33 PASSED** (no project regression) |
| `bash -n` on the 3 edited files | all syntax OK |
| `git diff --name-only` | the 6 expected `scripts/` files only — **pack-only clean** |

**Aggregate: 1 (validate-pack) + 50 (battery) + realistic-ot + the 3 named-suite
re-runs + manifest build/verify = all exit 0. ZERO failures.**

Manifest-regen rule satisfied: `scripts/` is v11-surface; the `--all --clean`
build produced no change to `test-fixtures/manifest.txt`, so nothing to stage.

---

## Plan deviations

**None.** All three named findings (F-1, NIT-1, NIT-2) applied exactly as scoped;
the F-1 repoint follows the C7b doctor pattern the prompt specified.

## New POQs introduced

**None.** One **observation** (not a POQ, not a fix): the `tracker-header-snapshot.sh:213`
BD-175 comment is mildly stale in wording, but its code path is correct
(client-`else`-reachable only) and the file is outside this pass's named scope.
The forthcoming BD-207 client-tree repoint owns that file.

## Definition-of-Done checklist

| Item | Status |
|---|---|
| F-1 — status-report pack branch reads the `/backlog/` tree (`_toc.md`), not the monolith | **PASS** |
| F-1 — client `else` branch byte-preserved (BD-207) | **PASS** (diff = re-indent only) |
| NIT-2 — `:1425` comment corrected to no-mirror reality + cites BD-204 | **PASS** |
| NIT-1 — agent-read fall-through consolidated, behavior byte-preserved | **PASS** (57/57; fail-loud strings byte-identical) |
| Grep-exhaustive census: zero pack-surface monolith reads; every hit classified | **PASS** (13 hits classified; 8th candidate proven client-only) |
| Test for `tracker_migrate_status_report` pack path asserts tree-read | **PASS** (Test 3.10b, 3 assertions) |
| Existing C-6 test additions intact | **PASS** |
| validate-pack GREEN | **PASS** |
| FULL CI battery GREEN | **PASS** (50/50 + realistic-ot 33/33) |
| Manifest regenerated (no diff → nothing to stage) | **PASS** |
| `git diff --name-only` = pack-side scripts only | **PASS** |
| No git state-change verbs run | **PASS** |

## Files changed inventory

| Path | Change type |
|---|---|
| `scripts/lib/tracker-migrate-forward.sh` | modified (F-1 + NIT-2) |
| `scripts/lib/tracker-agent-read.sh` | modified (NIT-1) |
| `scripts/tests/tracker-migrate-forward-test.sh` | modified (Test 3.10b) |
| `maintenance-docs/v11-implementation/IMPL-REPORT-BD-204-C6-FIX1.md` | new (this report) |

No files deleted. No new source files (only this report).

---

## Rules-Applied Verification Block

| Rule | Verification evidence (quoted/measured) | Conclusion |
|---|---|---|
| **Fail-loud / no monolith + grep-exhaustive census** | Post-fix `grep -rn 'pack-ops/BACKLOG.md' scripts/lib/` = 13 hits, all classified (table above): the former LIVE `:1428` read is gone (now comment `:1425`); remaining LIVE hits #6/#7 proven client-`else`-reachable only (caller `tracker-migrate-reverse.sh:1282` in `else`; test `:216` invariant); #12 is a dormant constant string. ZERO pack-surface reads. agent-read BD-*/`*)` still emit typed `not-found` "no monolith fallback" (57/57). Check 32′ green. | COMPLIANT |
| **Pack/project separation** | Only pack-surface branches edited. `git diff` shows the status-report client `else` (`BACKLOG.md` path + `<!--` header + 3 `mirror_age` outcomes) byte-preserved (re-indent only); agent-read TD-*/phase- `mirror_path` assignments byte-identical; `--mirror-only` client `else` untouched. realistic-ot 33/33 green. No `project-template/`/`supporting-docs/` in diff. | COMPLIANT |
| **Verify the FULL CI suite, not just validate-pack** | Enumerated the workflow `tests` set; ran validate-pack + 50-script battery (pass=50 fail=0) + forward 148/148 + agent-read 57/57 + doctor-wired 24/24 + realistic-ot 33/33 + manifest build/verify. Aggregate quoted in the verification table. | COMPLIANT |
| **Enumerate ENCODING surfaces** | Source fix (status-report pack branch) shipped IN LOCK-STEP with its test (Test 3.10b) in the same diff; 3 new assertions pin the tree-read invariant + the defensive never-consult-monolith check. No asymmetric coverage. | COMPLIANT |
| **Regenerate manifest on v11-surface commits** | `scripts/` is v11-surface; `bash test-fixtures/build.sh --all --clean` exit 0 → `git diff --stat test-fixtures/manifest.txt` empty (no diff); nothing to stage; restored to HEAD. | COMPLIANT |
| **Empirical evidence** | Every claim cites command output: the post-fix grep (13 lines quoted), `git diff` hunk evidence, caller greps (`tracker_header_snapshot_capture` → `:1282`; `per_entry_regenerate_mirror` consumers), test-run counts (50/0, 148/0, 57/0, 24/0, 33/33), `bash -n` results, `git diff --name-only`. | COMPLIANT |
| **Agents never commit / PREFLIGHT + STOP-MEANS-STOP** | No `git add/commit/push/tag/checkout`-mutating verb run (only read-only `git status/diff/rev-parse` + `git checkout HEAD -- test-fixtures/manifest.txt` to restore the build artifact). PREFLIGHT line emitted only after the full suite + census passed. Sole write besides the 3 in-scope edits = this report. | COMPLIANT |
| **Rules-Applied Verification Block** | This table; every row carries quoted/measured evidence (none empty). | COMPLIANT |

### READ-IN-FULL attestation (this session, base HEAD `4ab4a08`)

| File | Proof |
|---|---|
| `PACK-REVIEW-BD-204-C6.md` | Read 1-195 in full — F-1 (`:1427-1442`), NIT-1 (`:159-160`), NIT-2 (`:161-163`), the 7-line census quote, the caller refs. |
| `tracker-migrate-forward.sh` `tracker_migrate_status_report` | Read `:1388-1479` directly (pack vs client `else` branches) before + after edit. |
| `tracker-doctor.sh` C7b pack branch | Read `:110-194` — confirmed the `_toc.md`-mtime pattern I mirrored in F-1. |
| `tracker-agent-read.sh` fall-through | Read `:240-311` directly — consolidated the `case` + separate `if BD-*` block. |
| `tracker-migrate-reverse.sh` reverse emit | Read `:1255-1299` — proved header-snapshot capture is client-`else`-only. |
| `tracker-header-snapshot.sh` capture | Read `:195-254` — confirmed the LIVE `:216-217` read + its first-existing logic. |
| `per-entry/_lib.sh` stream attrs | Read `:70-129` — confirmed `:85` is a dormant constant string. |
| `.github/workflows/validate-pack.yml` | Read the full `run:` list (lines 95-286) — enumerated + ran the entire `tests` set. |
| `CLAUDE.md` ## Pack memory | In session context — fail-loud, pack/project separation, enumerate-encoding-surfaces, manifest-regen, verify-full-ci, agents-never-commit, preflight-stop-means-stop, rules-applied-block. |
| memories: `feedback_fail_loud_delete_old_source.md`, `feedback_pack_project_separation_of_concerns.md`, `feedback_rename_plans_measure_then_bound.md`, `feedback_verify_full_ci_suite.md`, `feedback_agent_output_rules_applied_block.md` | Applied per the named rules (grep-zero census, client-byte-preservation, full-CI battery, this verification block). |

**No named document was derived rather than read. Did NOT stage or commit.**

**End of IMPL-REPORT-BD-204-C6-FIX1.md**
