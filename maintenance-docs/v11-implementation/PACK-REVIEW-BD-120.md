# PACK-REVIEW-BD-120 — Parameterize realistic-OT fixture generator for any vN

**Verdict:** APPROVE — implementation is byte-identity-clean against an independent rebuild, follows the BD-119 per-version adapter pattern faithfully, all 11 listed test suites green, footprint well within BD-159 §3.1, no out-of-scope edits.

---

## 1. Inputs reviewed

- `BACKLOG.md` BD-120 (lines 1255–1269) — authoritative spec.
- `EXECUTION-PLAN-V11.0.md` §1.1 (BD-120 listed as Group 1 launch-critical) and §4 Batch 3 (line 255: "BD-120 → BD-116; both touch `test-fixtures/build.sh`; BD-120 first because BD-116 builds on parameterization").
- `CLAUDE.md` Pack memory → "Repo conventions" (BD-159 mechanical-edit caps).
- `scripts/lib/migrator-core.sh` lines 459–513 (`migrator_target_surface_for_version`) — BD-119 per-version adapter pattern this BD parallels.
- `test-fixtures/build.sh` (current working tree).
- `test-fixtures/README.md` (current working tree).
- `test-fixtures/manifest.txt` (current working tree).
- `IMPLEMENTATION-REPORT-BD-120.md` (untracked).

I did NOT read any prior `PACK-REVIEW-*.md`.

---

## 2. Verification methodology

Independent of the IMPL report, I re-ran:

- `bash test-fixtures/build.sh --name v10-realistic-ot --clean` — fresh from-scratch rebuild.
- `git rev-parse HEAD` / `git rev-parse HEAD^{tree}` / `git ls-tree -r HEAD | sha256sum` against the rebuilt fixture.
- `python3 scripts/validate-pack.py` — full validator.
- `bash scripts/test-detect.sh` — detection tests.
- `bash scripts/test-migrator-core.sh` — migrator-core tests.
- `bash scripts/tests/test-migrate-v10-to-v11.sh` — end-to-end migrator (this is the suite most likely to regress on a fixture change).
- `bash -n test-fixtures/build.sh` — bash syntax check.
- `ls -la test-fixtures/build.sh` — permission bit.

I cross-checked grep results for `_build_v10_realistic_ot` and `_build_realistic_for_version` callers.

---

## 3. Per-concern findings

### 3.1 Refactor correctness — PASS

`test-fixtures/build.sh:186–336` defines `_build_realistic_for_version` with the exact shape called for in the spec:

- Single-arg: `local ver="${1:?_build_realistic_for_version requires <vN>}"` (line 187) — input-validated via parameter substitution (the `:?` form fails fast with a clear message).
- Target derived from input: `local target="$THIS_DIR/${ver}-realistic-ot"` (line 188).
- Two case blocks (lines 191–202 source-clone setup; lines 207–210 init dispatcher), correctly split because `_fixture_git_init` is a wipe-then-init step that must run between them.
- Customization-pattern body (C1 trinity fills, C2 ollama strip, C3 x-agent on 3 CLIs, C4 TD BACKLOG) at lines 213–332 is verbatim the v10 logic — no behavioral change.
- Final commit message uses `${ver} install` (line 211) and the same OT-suffix string as before (lines 334–335).

**Asymmetry vs. the original I want to flag (NIT, not blocking):** the C2 ollama-strip and C3 x-agent payloads still reference `FakeOT` and `.codex/config.toml` paths that may not exist in v11's surface. The IMPL report §6 acknowledges this scope limitation by noting v11-realistic-ot is not yet wired. Operationally this is fine — calling `_build_realistic_for_version v11` today would skip ollama strip (the `[[ -f ]]` guard at line 226 catches it) and successfully write the x-agent files (because v11 still ships per-CLI agent dirs). But there is no test today that proves v11 dispatch actually works end-to-end. The spec explicitly defers v11-realistic-ot wiring to a future BD, so this is consistent with the brief; just noting that the v11 path is unexercised until that BD lands.

### 3.2 Backwards-compat shim — PASS

`test-fixtures/build.sh:342–344`:

```bash
_build_v10_realistic_ot() {
    _build_realistic_for_version v10
}
```

One-line delegate. The dispatcher at line 678 (`v10-realistic-ot) _build_v10_realistic_ot ;;`) is unchanged — v10 routes through the shim → parameterized function. Confirmed by grep: only one live caller of the v10-named function exists (the dispatcher).

### 3.3 BD-119 pattern parallel — PASS

Side-by-side comparison:

| Property | `migrator_target_surface_for_version` (BD-119) | `_build_realistic_for_version` (BD-120) |
|---|---|---|
| Signature | `<vN>` single string arg | `<vN>` single string arg |
| Input validation | `local ver="${1:-}"` then case dispatch | `local ver="${1:?…}"` (slightly stricter — fails fast with message) |
| Dispatch shape | `case "$ver" in v10) … ;; v11) … ;; *) printf 'unknown\n'; return 1 ;; esac` | `case "$ver" in v10) … ;; v11) … ;; *) die "…" 4 ;; esac` |
| Global state | None | None |
| Error path | Returns 1 with `unknown\n` token | Calls `die` with exit 4 |

The error-path divergence (printf+return vs `die`) is appropriate per local convention: `migrator-core.sh` is a library used by callers that may want to handle "unknown version" recoverably (its public API documents the `unknown` token); `build.sh` is a script-runner where loud-fail is correct (mirrors the `_build_one` dispatcher's `die "unknown fixture: …"` at line 682). Pattern parallel preserved where it matters; divergence justified by call-site convention.

### 3.4 v10 byte-identity — PASS (independently verified)

I rebuilt v10-realistic-ot from `--clean`. Independent measurements:

| Metric | Pre-refactor (IMPL §1.4) | Post-refactor (independent rebuild) | Match |
|---|---|---|---|
| HEAD SHA | `4c62945f72b037908b38967d5d8f019745263258` | `4c62945f72b037908b38967d5d8f019745263258` | YES |
| Tree SHA | `ef3bd4e100f538dddb5c11a08f1acc6cf729a1b3` | `ef3bd4e100f538dddb5c11a08f1acc6cf729a1b3` | YES |
| `git ls-tree -r HEAD \| sha256sum` | `28a315bfa0301856c3668ddec58c8c56b3f21424e34d8222e7279e0588d38a53` | `28a315bfa0301856c3668ddec58c8c56b3f21424e34d8222e7279e0588d38a53` | YES |

Refactor is provably byte-equivalent for the v10-realistic-ot fixture.

### 3.5 Test regression check — PASS (independently re-run)

| Suite | Result | Verified by |
|---|---|---|
| `python3 scripts/validate-pack.py` | PASSED — all 31 checks clean | Re-ran; final line "PASSED — all checks clean" |
| `bash scripts/test-detect.sh` | 64/64 | Re-ran; "=== Results: 64 passed, 0 failed ===" |
| `bash scripts/test-migrator-core.sh` | 19/19 | Re-ran; "=== Results: 19 passed, 0 failed ===" |
| `bash scripts/test-migrator-manifest.sh` | 12/12 | IMPL §4.5 (not re-run by reviewer; spot-check confidence high after 4.10 passed) |
| `bash scripts/test-migrator-skills.sh` | 19/19 | IMPL §4.6 |
| `bash scripts/test-migrator-capability-translation.sh` | 12/12 | IMPL §4.7 |
| `bash scripts/tests/test-migrate-v10-to-v11-dry-run.sh` | 40/40 | IMPL §4.8 |
| `bash scripts/tests/test-migrate-v10-to-v11-gates.sh` | 41/41 | IMPL §4.9 |
| `bash scripts/tests/test-migrate-v10-to-v11.sh` | 43/43 | Re-ran; "=== Summary === Passed: 43 Failed: 0" |

The end-to-end migrator suite is the load-bearing one for fixture changes; I re-ran it and it passes.

### 3.6 Permission bit — PASS

```
-rwxr-xr-x@ 1 david  staff  25005 May 12 12:02 test-fixtures/build.sh
```

`-rwxr-xr-x` retained.

### 3.7 README update — PASS

`test-fixtures/README.md:140–154` adds the "Realistic-OT fixtures: per-version pattern (BD-120)" subsection under "Adding a new fixture". Content covers:

- Function name (`_build_realistic_for_version <vN>`).
- The four canonical OT-style customizations.
- How to add a `vN-realistic-ot` sibling (extend the two `case` blocks).
- Shim disclosure (`_build_v10_realistic_ot()` preserved as thin wrapper).
- Cross-reference to `migrator_target_surface_for_version` (BD-119).

BD-120 reference appears in the subsection heading.

**NIT (non-blocking):** The "Adding a new fixture" generic procedure (lines 129–138) still says "Add a `_build_<name>()` function". This is correct for non-realistic-OT additions, and the new subsection at line 140 is the realistic-OT-specific exception. Could be made more explicit by adding a one-line forward-pointer at the end of the generic procedure ("For a new realistic-OT version, see the per-version subsection below.") — but this is a stylistic improvement, not a defect.

### 3.8 Manifest update — PASS

`test-fixtures/manifest.txt`:

| Fixture | SHA | Verification |
|---|---|---|
| `v10-minimal` | `19558cbac58ed3e47642a6bbe64418a38c60bc16` | v10-pinned; not expected to drift |
| `v10-realistic-ot` | `4c62945f72b037908b38967d5d8f019745263258` | matches independently-rebuilt fixture (byte-identity proven) |
| `v11-flat-file` | `e54ab38fbb5d0099826b384de3c39d61bd7cb171` | v11-tracked HEAD; drift expected per IMPL §4.1.1 |
| `v11-tracker-on` | `ae6f0ae6d8fb3b27c29d1ba8a61e2af12edaac2f` | v11-tracked HEAD; drift expected per IMPL §4.1.1 |
| `existing-project-mid-dev` | `a54e081a9e1d04f293bfb38fa0af77fd9f7f8619` | version-agnostic; not expected to drift |

The v11-* drift explanation in IMPL §4.1.1 is internally consistent: `manifest.txt` was last regenerated at `7ae503b` (BD-128 fix-follow), and the v11-* fixtures track current pack HEAD which has moved through BD-143..BD-158 since. The v10-pinned and version-agnostic fixtures did NOT drift, which is the regression-safety signal.

`v11-trinity-marker-prepped` is documented in `README.md` (line 33) as a frozen snapshot NOT regenerable via `build.sh` and is not in `FIXTURE_NAMES`, so its absence from `manifest.txt` is correct.

### 3.9 No out-of-scope edits — PASS

`git status --short` (working tree as reviewed):

```
 M test-fixtures/README.md
 M test-fixtures/build.sh
 M test-fixtures/manifest.txt
?? maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-120.md
?? maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-FLAT-FILES.md
?? maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-PACK-VS-CLIENT.md
?? maintenance-docs/v11-research/PACK-REVIEW-ARCHITECTURE-PER-ENTRY.md
?? maintenance-docs/v11-research/RESEARCH-CLAUDE-REPOS-SURVEY.md
?? maintenance-docs/v11-research/RESEARCH-GRAPHIFY-EXTERNAL.md
?? maintenance-docs/v11-research/RESEARCH-GRAPHIFY-PACK-INTEGRATION.md
?? maintenance-docs/v11-research/RESEARCH-GRAPHIFY-SYNTHESIS.md
```

Three modified files exactly match the BD-120 scope. The 7 untracked files in `maintenance-docs/v11-research/` are the user out-of-band work flagged in the brief — not BD-120's responsibility. The IMPL report is the agent's own output and is appropriate (untracked, awaits Pack Chat staging decision).

No edits to BACKLOG.md, CHANGELOG.md, README.md (pack-root), or any of the trinity files. Trinity rule does not engage (no trinity files touched).

### 3.10 Maintainability principle (BD-159 §3.1) — PASS

- 2 substantive files (`build.sh` + `README.md`) + 1 mechanical regeneration (`manifest.txt`) = 3 files modified.
- Well below the ≤ 10 mechanical-batch cap.
- No new architecture / planner doc; no rule changes; no new dimensions or schemas.
- Refactor preserves observable behavior (byte-identity proven) — classic mechanical-equivalent refactor.
- Mirrors an existing pattern (`migrator_target_surface_for_version`), reducing surface area rather than adding new architecture.

Mechanical-edit classification: confirmed.

---

## 4. Cross-reference integrity

Searched for stale references to `_build_v10_realistic_ot`:

- `test-fixtures/build.sh:678` — dispatcher (kept; still routes through shim).
- `test-fixtures/build.sh:342` — shim definition (kept).
- `BACKLOG.md` — appears in BD-120 spec text (descriptive — not a code reference; appropriate).
- `maintenance-docs/archive/v11/IMPLEMENTATION-REPORT-BD-128.md` — historical reference (archived doc; should not be touched).
- `maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md` — architecture pointer to BD-120 future work (descriptive; appropriate).

No stale references. README/CHANGELOG (pack-root) intentionally untouched — those land at version pin.

---

## 5. IMPL report internal consistency

Spot-check of the IMPL report against working-tree state:

- `Worktree HEAD (start + end of session): 4427eb1f…` — at review time, HEAD has advanced to `16dc750` via a docs-only fix-follow commit (`docs: v11 — fix BD-150 reviewer nit #2`). This advance does NOT touch any BD-120 file (`test-fixtures/*`), so the report's evidence remains valid. (Minor: the IMPL report's "final state" SHA is one commit behind the worktree as I review it. Not blocking.)
- The 7 untracked-file list in IMPL §1.1 exactly matches `git status --short` (one extra file `PACK-REVIEW-ARCHITECTURE-PER-ENTRY.md` that the IMPL captured) — consistent.
- Files-touched table (§5) matches `git status` exactly.

---

## 6. NITs (non-blocking)

1. **README "Adding a new fixture" generic procedure** could carry a one-line pointer to the per-version subsection so future contributors land in the right pattern without scrolling. Stylistic; not blocking.
2. **v11 dispatch path is untested** in `_build_realistic_for_version` because no `v11-realistic-ot` fixture is wired (per spec — explicitly deferred). When the deferred BD lands and adds the FIXTURE_NAMES entry + dispatcher case, that BD should also confirm the C2 ollama-strip and C3 x-agent customizations are still applicable on the v11 surface (they should be — `migrator_target_surface_for_version v11` enumerates `.codex/config.toml`, `.claude/agents`, `.codex/agents`, `.gemini/agents` — but worth re-verifying then).
3. **Shim sunset path** is well-documented in IMPL §7 POQ-BD-120-1 (mechanical: delete shim + change dispatcher to call parameterized function directly). No action required now.

None of these block APPROVE.

---

## 7. Summary

BD-120 ships a clean, byte-equivalent refactor that establishes the per-version dispatch shape for the realistic-OT fixture family. The function follows the BD-119 `migrator_target_surface_for_version` adapter pattern (single string arg, case dispatch, no global state, fails loud on unknown). Backwards-compat shim retained, dispatcher unchanged, customization-pattern body unchanged. v10 byte-identity verified independently against the IMPL report's pre-refactor baseline (HEAD / tree / ls-tree-sha256 all match). Manifest's v11-* drift explanation is internally consistent and orthogonal to the refactor. README documents the per-version pattern with BD-120 reference. Three files modified, well within BD-159 §3.1 mechanical-edit caps. All listed test suites green, including the end-to-end migrator I re-ran. No out-of-scope edits, trinity untouched.

Recommend Pack Chat stage `test-fixtures/build.sh`, `test-fixtures/README.md`, `test-fixtures/manifest.txt` and proceed to BD-116 (Batch 3 second-half).
