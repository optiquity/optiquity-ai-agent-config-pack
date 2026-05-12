# IMPLEMENTATION-REPORT-BD-120 — Parameterize realistic-OT fixture generator

**BD:** BD-120 — Parameterize realistic-OT fixture generator for any vN
**Branch:** `v11-dev`
**Worktree HEAD (start + end of session):** `4427eb1ffd4a053bd02a537fd1036c82965d3fc3`
**Files modified:** `test-fixtures/build.sh`, `test-fixtures/README.md`, `test-fixtures/manifest.txt` (auto-regenerated; see notes)
**Files added:** none
**Files deleted:** none

---

## 1. Pre-flight state

### 1.1 Git state

```
$ git rev-parse HEAD
4427eb1ffd4a053bd02a537fd1036c82965d3fc3

$ git status --short
?? maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-FLAT-FILES.md
?? maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-PACK-VS-CLIENT.md
?? maintenance-docs/v11-research/PACK-REVIEW-ARCHITECTURE-PER-ENTRY.md
?? maintenance-docs/v11-research/RESEARCH-CLAUDE-REPOS-SURVEY.md
?? maintenance-docs/v11-research/RESEARCH-GRAPHIFY-EXTERNAL.md
?? maintenance-docs/v11-research/RESEARCH-GRAPHIFY-PACK-INTEGRATION.md
?? maintenance-docs/v11-research/RESEARCH-GRAPHIFY-SYNTHESIS.md
```

The 7 untracked entries under `maintenance-docs/v11-research/` are out-of-band user work (per task brief, do-not-touch). All untouched.

### 1.2 Pre-existing `_build_v10_realistic_ot` shape

Located at `test-fixtures/build.sh` lines 165–297 (133 lines). Does, in order:

1. Sets `target` to `$THIS_DIR/v10-realistic-ot`.
2. Calls `_setup_v10_pack_src` (clones v10 tag with BD-128 sweep work-around).
3. Calls `_fixture_git_init "$target"` + initial empty commit.
4. Calls `_run_v10_init "$target"` + commits "v10 install".
5. Applies four canonical OT-style customizations:
   - C1: Trinity project-name fills (`[PROJECT_NAME]` → `FakeOT`, `[PLATFORM_TARGETS]` → `iOS 17, macOS 14`, `[TRANSPORT]` → `gRPC + Proto3`).
   - C2: `model_providers.ollama` block stripped from `.codex/config.toml` via inline Python regex.
   - C3: `x-fakeot-domain` agent written to all 3 CLI agent dirs (Claude `.md`, Gemini `.md` copy, Codex `.toml`).
   - C4: TD-NNN `BACKLOG.md` (5 entries: TD-001..TD-005).
6. Final commit "FakeOT customizations: project-name, ollama removed, x-agent, BACKLOG".

### 1.3 Caller grep results

```
$ grep -rn "_build_v10_realistic_ot\|build_realistic_for_version" \
    --include="*.sh" --include="*.py" --include="*.md" \
    | grep -v "maintenance-docs/v11-research/"

BACKLOG.md:1247                              (BD spec text)
BACKLOG.md:1250                              (BD spec text)
test-fixtures/build.sh:165                   (function definition — refactored)
test-fixtures/build.sh:631                   (dispatcher case — preserved)
maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-128.md:80   (historical reference)
maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md:610    (architecture pointer)
maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md:612    (architecture pointer)
```

**Conclusion:** Only one live caller exists (the dispatcher in `build.sh::_build_one`). The shim is therefore optional but is preserved for any external test runner that may name the v10-specific function (e.g., the dog-food harness or future `scripts/test-*` work). Removing it is a one-line change if a future audit confirms zero external callers.

### 1.4 Pre-refactor v10-realistic-ot fingerprint (byte-identity baseline)

```
HEAD SHA:  4c62945f72b037908b38967d5d8f019745263258
Tree SHA:  ef3bd4e100f538dddb5c11a08f1acc6cf729a1b3
ls-tree -r HEAD | sha256sum:
           28a315bfa0301856c3668ddec58c8c56b3f21424e34d8222e7279e0588d38a53

Commits:
  4c62945  ef3bd4e  FakeOT customizations: project-name, ollama removed, x-agent, BACKLOG
  b4c5059  b1e1bc0  v10 install
  a12a470  4b825dc  initial empty repo
```

### 1.5 BD-119 adapter pattern (reference)

`scripts/lib/migrator-core.sh::migrator_target_surface_for_version <vN>` is the per-version helper this BD parallels. Uses a `case "$ver" in v10) … ;; v11) … ;; *) printf 'unknown\n'; return 1 ;; esac` shape with no global state, single string-arg input. BD-120's refactor mirrors this exactly.

### 1.6 Permission bit (pre-existing)

```
-rwxr-xr-x@ 1 david  staff  23230 May  9 12:23 test-fixtures/build.sh
```

---

## 2. Refactor: old → new function signatures

### 2.1 Old (single-purpose, v10-hardcoded)

```bash
_build_v10_realistic_ot() {
    local target="$THIS_DIR/v10-realistic-ot"
    info "  source: pack v10 tag + FakeOT customizations"
    _setup_v10_pack_src
    _fixture_git_init "$target"
    _fixture_commit_all "$target" "initial empty repo"
    _run_v10_init "$target"
    _fixture_commit_all "$target" "v10 install"
    # ... 4 customizations ...
    _fixture_commit_all "$target" "FakeOT customizations: ..."
}
```

### 2.2 New (parameterized + shim)

```bash
# _build_realistic_for_version <vN>
_build_realistic_for_version() {
    local ver="${1:?_build_realistic_for_version requires <vN>}"
    local target="$THIS_DIR/${ver}-realistic-ot"

    case "$ver" in
        v10) info "  source: pack v10 tag + FakeOT customizations"
             _setup_v10_pack_src ;;
        v11) info "  source: pack v11 (current HEAD) + FakeOT customizations" ;;
        *)   die "_build_realistic_for_version: unsupported version: $ver" 4 ;;
    esac

    _fixture_git_init "$target"
    _fixture_commit_all "$target" "initial empty repo"

    case "$ver" in
        v10) _run_v10_init "$target" ;;
        v11) _run_v11_init "$target" ;;
    esac
    _fixture_commit_all "$target" "${ver} install"

    # ... 4 customizations (verbatim — no logic change) ...
    _fixture_commit_all "$target" "FakeOT customizations: ..."
}

# Backwards-compat shim.
_build_v10_realistic_ot() {
    _build_realistic_for_version v10
}
```

### 2.3 Design properties

- **Two `case` blocks, not one merged block.** Source setup is needed before `_fixture_git_init` (which wipes target), and init dispatch happens after the initial-commit step. Splitting matches the data dependencies of the original linear function.
- **No global state.** Single string input (`$ver`); identifier `${ver}-realistic-ot` derived from input; output via the existing `_fixture_*` helpers. Mirrors BD-119's `migrator_target_surface_for_version` shape exactly.
- **`die` on unknown version.** Uses the existing `die` helper (exit 4). Keeps behavior consistent with `_build_one`'s "unknown fixture" path (which also exits via `die`).
- **Customization patterns are version-agnostic.** All four (trinity fills, ollama strip, x-agent, TD-BACKLOG) operate on file paths that exist in both v10 and v11 surfaces (per `migrator_target_surface_for_version` v10 vs v11 enumeration in `scripts/lib/migrator-core.sh`).
- **Shim preserved.** `_build_v10_realistic_ot()` is now a one-line delegate to `_build_realistic_for_version v10`. Existing dispatcher (line 631 — now line ~640) untouched and routes through the shim. Any external caller (e.g., a future test harness that scripts the v10-specific function name) continues to work.

### 2.4 Dispatcher path

`_build_one` `case "$name" in v10-realistic-ot) _build_v10_realistic_ot ;; …` is **unchanged**. v10 still routes through the v10-named entry point → shim → parameterized function. To add a `v11-realistic-ot` fixture in the future, the change is two lines: add `"v11-realistic-ot"` to `FIXTURE_NAMES` and add `v11-realistic-ot) _build_realistic_for_version v11 ;;` to the dispatcher. No new `_build_v11_realistic_ot` wrapper is required (though one could be added for symmetry if desired).

---

## 3. Byte-identity verification (v10-realistic-ot)

Pre-refactor and post-refactor full rebuild from `--clean`:

| Metric | Pre-refactor | Post-refactor | Match |
|---|---|---|---|
| HEAD SHA | `4c62945f72b037908b38967d5d8f019745263258` | `4c62945f72b037908b38967d5d8f019745263258` | YES |
| Root tree SHA | `ef3bd4e100f538dddb5c11a08f1acc6cf729a1b3` | `ef3bd4e100f538dddb5c11a08f1acc6cf729a1b3` | YES |
| `git ls-tree -r HEAD \| sha256sum` | `28a315bfa0301856c3668ddec58c8c56b3f21424e34d8222e7279e0588d38a53` | `28a315bfa0301856c3668ddec58c8c56b3f21424e34d8222e7279e0588d38a53` | YES |
| Commits (3) — SHAs | `4c62945`, `b4c5059`, `a12a470` | `4c62945`, `b4c5059`, `a12a470` | YES |

**Conclusion:** Refactor is provably byte-equivalent for the v10-realistic-ot fixture. The customization patterns + git-determinism pins reproduce an identical fixture tree and commit graph through the parameterized code path.

---

## 4. Test results

### 4.1 `bash test-fixtures/build.sh --all --clean`

Result: **PASS** — all 5 fixtures built without error.

```
── building v10-minimal ──
  HEAD:  19558cbac58ed3e47642a6bbe64418a38c60bc16   (matches manifest)
── building v10-realistic-ot ──
  HEAD:  4c62945f72b037908b38967d5d8f019745263258   (matches manifest — byte-identical)
── building v11-flat-file ──
  HEAD:  e54ab38fbb5d0099826b384de3c39d61bd7cb171   (drifted from manifest — see §4.1.1)
── building v11-tracker-on ──
  HEAD:  ae6f0ae6d8fb3b27c29d1ba8a61e2af12edaac2f   (drifted from manifest — see §4.1.1)
── building existing-project-mid-dev ──
  HEAD:  a54e081a9e1d04f293bfb38fa0af77fd9f7f8619   (matches manifest)
```

#### 4.1.1 v11-* SHA drift — pre-existing, NOT caused by BD-120

The `v11-flat-file` and `v11-tracker-on` SHAs drifted vs the committed `manifest.txt`. This drift is **pre-existing** and has the following provenance:

- `manifest.txt` was last regenerated at commit `7ae503b` (BD-128 fix-follow). Confirmed via `git log --oneline -1 test-fixtures/manifest.txt`.
- v11-* fixtures track current pack HEAD (not a frozen tag), per `test-fixtures/README.md` lines 105–110.
- Between `7ae503b` and current HEAD `4427eb1`, multiple v11 batches landed (BD-143, BD-144, BD-145, BD-146, BD-147, BD-148, BD-149, BD-156, BD-157, BD-158) that touched `project-template/` and `scripts/`. Any such change naturally moves the v11-* fixture SHAs.
- The v10-pinned and version-agnostic fixtures (`v10-minimal`, `v10-realistic-ot`, `existing-project-mid-dev`) **did not drift** — they remain byte-identical, confirming the refactor is the regression-safety net it was designed to be.

`manifest.txt` updated by `--all` reflects the new (correct) state of v11-* fixtures and is included in the modified-files inventory. This is normal manifest-regeneration behavior, not a BD-120 regression.

### 4.2 `python3 scripts/validate-pack.py`

Result: **PASS — all 31 checks clean**. Final lines:

```
── Check 31: Skill-cell consistency (BD-146, v11) ──
  OK: PLATFORM-SKILLS.md — 'Tier 0 base skills': 13 rows (header matches)
  OK: PLATFORM-SKILLS.md — 'Dimensional skills': 19 rows (header matches)
  OK: PLATFORM-SKILLS.md — 'Trigger-loaded skills': 1 rows (header matches)
  OK: PLATFORM-SKILLS.md — 'PM chat operational skill': 1 rows (header matches)
  OK: PLATFORM-SKILLS.md — total skills: 34 (header sum, inventory row count, and disk count all agree)
  OK: Skill-cell consistency: 34 SKILL.md on disk, all map to exactly one inventory cell; no orphans, phantoms, or double-counts

============================================================
PASSED — all checks clean
```

### 4.3 `bash scripts/test-detect.sh`

Result: **PASS — 64/64**.

```
=== Results: 64 passed, 0 failed ===
```

### 4.4 `bash scripts/test-migrator-core.sh`

Result: **PASS — 19/19**.

```
=== Results: 19 passed, 0 failed ===
```

### 4.5 `bash scripts/test-migrator-manifest.sh`

Result: **PASS — 12/12**.

```
=== Results: 12 passed, 0 failed ===
```

### 4.6 `bash scripts/test-migrator-skills.sh`

Result: **PASS — 19/19**.

```
=== Results: 19 passed, 0 failed ===
```

### 4.7 `bash scripts/test-migrator-capability-translation.sh`

Result: **PASS — 12/12**.

```
=== Results: 12 passed, 0 failed ===
```

### 4.8 `bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh`

Result: **PASS — 40/40**.

```
=== Summary ===
Passed: 40
Failed: 0
All BD-095 tests passed.
```

### 4.9 `bash scripts/tests/test-migrate-v10-to-v11-gates.sh`

Result: **PASS — 41/41**.

```
=== Summary ===
Passed: 41
Failed: 0
All BD-101 gate tests passed.
```

### 4.10 `bash scripts/tests/test-migrate-v10-to-v11.sh`

Result: **PASS — 43/43** (run twice — once before manifest regeneration to confirm refactor doesn't break the migrator end-to-end against the existing fixture; once after `--all --clean` rebuild to confirm it still passes against freshly-rebuilt v10-realistic-ot fixture).

```
=== Summary ===
Passed: 43
Failed: 0
All tests passed.
```

### 4.11 `bash -n test-fixtures/build.sh` + permission bit

```
$ ls -la test-fixtures/build.sh
-rwxr-xr-x@ 1 david  staff  25005 May 12 12:02 test-fixtures/build.sh
$ bash -n test-fixtures/build.sh && echo "syntax OK"
syntax OK
```

Permission bit `-rwxr-xr-x` preserved. Bash syntax clean.

---

## 5. Files-touched table

| Path | Change type | Net line delta | Rationale |
|---|---|---|---|
| `test-fixtures/build.sh` | modified | +56 / -25 (≈ +31 net) | Refactor `_build_v10_realistic_ot` → `_build_realistic_for_version <vN>` + retain shim. Customization-pattern body unchanged. |
| `test-fixtures/README.md` | modified | +14 / -0 | Add "Realistic-OT fixtures: per-version pattern (BD-120)" subsection under "Adding a new fixture". |
| `test-fixtures/manifest.txt` | modified | +2 / -2 | Auto-regenerated by `build.sh --all`. Contains pre-existing v11-* drift from BD-128→current HEAD pack content changes (NOT caused by BD-120 refactor — see §4.1.1). |

**Out-of-scope files NOT touched:** `BACKLOG.md`, `CHANGELOG.md`, `README.md`, `CLAUDE.md`/`AGENTS.md`/`GEMINI.md` (pack-repo or template trinity), `PACK-CHAT.md`, `PACK-AGENTS.md`, all of `maintenance-docs/v11-research/`.

---

## 6. Plan deviations

**None.**

The implementation follows the BD-120 spec verbatim:

- Function renamed to `_build_realistic_for_version <vN>` (success criterion 1).
- Shim `_build_v10_realistic_ot()` retained for backwards compat (success criterion 2). Caller grep showed only one live caller (the in-file dispatcher); the shim is therefore optional but kept per the brief's "document either way" — choice rationale documented in §1.3.
- Dispatcher routes v10 unchanged through the shim → parameterized path; v11 case is a two-line addition when the v11-realistic-ot fixture is needed (success criterion 3). No v11 fixture entry has been added to `FIXTURE_NAMES` yet — this BD's scope is strictly the parameterization; the v11-realistic-ot fixture itself is a separate work item and the brief specifies "for v10 and the new v11 case (when v11 fixtures are needed)", which we read as "make the path available, do not pre-build v11-realistic-ot".
- README.md updated with a per-version-pattern note (success criterion 4).

---

## 7. New POQs introduced

**POQ-BD-120-1 (informational, no action).** Should `_build_v10_realistic_ot` shim be sunset once a v11-realistic-ot fixture lands? Disposition: defer until v11-realistic-ot is actually wired (separate BD). Until then, the shim costs one line and removes a footgun for any external test harness scripting the v10 name. Sunset is mechanical (delete shim + update line 631 dispatcher to `v10-realistic-ot) _build_realistic_for_version v10 ;;`).

No POQs require Pack Chat triage today.

---

## 8. Definition-of-Done checklist

| # | Criterion | Status | Evidence |
|---|---|---|---|
| 1 | `_build_v10_realistic_ot` refactored to `_build_realistic_for_version <vN>` | PASS | §2.2 |
| 2 | Backwards-compat shim retained (or deletion documented) | PASS | §2.2 (shim retained); §1.3 (caller analysis) |
| 3 | Dispatcher routes v10 unchanged | PASS | §2.4; §3 byte-identity |
| 4 | `test-fixtures/README.md` updated with per-version note | PASS | §5 (file row 2) |
| 5 | `bash test-fixtures/build.sh --all --clean` PASS | PASS | §4.1 |
| 6 | v10-realistic-ot byte-identical pre/post (sha256) | PASS | §3 (HEAD SHA + tree SHA + ls-tree sha256 all match) |
| 7 | `python3 scripts/validate-pack.py` 31/31 PASS | PASS | §4.2 |
| 8 | `bash scripts/test-detect.sh` PASS | PASS | §4.3 (64/64) |
| 9 | `bash scripts/test-migrator-core.sh` PASS | PASS | §4.4 (19/19) |
| 10 | `bash scripts/test-migrator-manifest.sh` PASS | PASS | §4.5 (12/12) |
| 11 | `bash scripts/test-migrator-skills.sh` PASS | PASS | §4.6 (19/19) |
| 12 | `bash scripts/test-migrator-capability-translation.sh` PASS | PASS | §4.7 (12/12) |
| 13 | `bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh` PASS | PASS | §4.8 (40/40) |
| 14 | `bash scripts/tests/test-migrate-v10-to-v11-gates.sh` PASS | PASS | §4.9 (41/41) |
| 15 | `bash scripts/tests/test-migrate-v10-to-v11.sh` PASS | PASS | §4.10 (43/43) |
| 16 | Permission bit `-rwxr-xr-x` preserved on `build.sh` | PASS | §4.11 |
| 17 | No edits outside `test-fixtures/build.sh` + `test-fixtures/README.md` (manifest.txt regenerated mechanically) | PASS | §5 |
| 18 | `maintenance-docs/v11-research/` untouched | PASS | §1.1 (untracked entries unchanged) |
| 19 | No state-changing git verbs run | PASS | Session ran only `rev-parse`, `status`, `log`, `diff`, `ls-tree` |
| 20 | Trinity rule: no trinity files touched | N/A | Refactor scoped to test-fixtures/ |

---

## 9. BD-159 §3.1 mechanical-edit sanity check

BD-159 (skill-and-agent maintainability) §3.1 caps mechanical batch size at ≤ 10 files. BD-120 touched **2 files by intent** (`build.sh` + `README.md`) plus **1 mechanical artifact** (`manifest.txt` auto-regenerated). Well within the 10-file cap. No structural change (no new dimensions, no new schema, no rule changes) — purely mechanical refactor preserving observable behavior for v10 and adding a future-version dispatch path. Maintenance-mechanical classification: confirmed.

---

## 10. Notes for Pack Chat (commit guidance)

- Suggested commit message stem: `feat: v11 — BD-120 parameterize realistic-OT fixture builder for any vN (Batch 3)`.
- Three files to stage: `test-fixtures/build.sh`, `test-fixtures/README.md`, `test-fixtures/manifest.txt`. The manifest update is mechanical-correct: it captures legitimate v11-* fixture drift accumulated across BD-143..BD-158 that was overdue for a refresh; staging it now is appropriate (alternative: stage only the BD-120 functional changes and let manifest update with a future BD — Pack Chat's call).
- BD-159 maintainability principle: 2 functional files modified, well within the ≤ 10 cap.
- BACKLOG.md BD-120 status flip from `Open` → `Resolved` with `Resolved: 2026-05-12 — see maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-120.md` is the post-batch implicit flip per Pack memory rules; Pack Chat will handle this as the final batch step.

---

## 11. Final-state SHA

```
$ git rev-parse HEAD
4427eb1ffd4a053bd02a537fd1036c82965d3fc3
```

(Unchanged from session start — agent ran zero state-changing git verbs.)
