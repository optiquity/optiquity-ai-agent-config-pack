# IMPL-REPORT — BD-228 Commit C1 (the method + shared SoT + its test + design archive)

**Agent:** pack-coder
**Date:** 2026-06-17
**Regime:** ISOLATED WORKTREE (verified)
**Working-tree pwd:** `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a320c05ebccaf8d9c`
**Branch:** `worktree-agent-a320c05ebccaf8d9c`
**HEAD at start AND end:** `3bad27667c10aa0888e6f30ae452e39efdb2075b` (`3bad276`) — UNCHANGED (agents never commit)
**Scope:** `pack-only`
**Plan:** `/tmp/handoff-bd228-planner/PLAN-BD-228-MANIFEST-METHOD.md` (commit C1)
**Design:** `/tmp/handoff-bd226-manifest-method/DESIGN-MANIFEST-PUSH-METHOD.md` (§2, §2.3, §7.1)

**Patch NOT emitted** (per prompt HARD CONSTRAINT — reviewed-clean patch requested later, after a reviewer confirms CLEAN). Edits left in the working tree; report only.

---

## 0. Regime self-verification (STEP 0)

- `pwd` → `/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a320c05ebccaf8d9c` — a `.claude/worktrees/agent-…` path. CONFIRMED isolated worktree.
- `git rev-parse --short HEAD` → `3bad276` (matches the expected `3bad276` or later). CONFIRMED.
- `mkdir -p /tmp/handoff-bd228-C1` — created. CONFIRMED.

---

## 1. Files changed inventory

| Path | Change type | Notes |
|------|-------------|-------|
| `scripts/manifest-sync.sh` | NEW | Push-time regen tool. Marked `# pack-internal: true` (Check 23). |
| `scripts/lib/manifest-inputs.sh` | NEW | Single SoT for the fixture-input predicate. |
| `scripts/tests/manifest-method-test.sh` | NEW | Self-provisioned `/tmp`-scratch test (34 cases). |
| `maintenance-docs/v11-implementation/DESIGN-MANIFEST-PUSH-METHOD.md` | NEW | Design doc archived verbatim (byte-identical to source). |

**No manifest staged** (self-hosting — see §4). **No other file touched.** `git status --short` at end:
```
?? maintenance-docs/v11-implementation/DESIGN-MANIFEST-PUSH-METHOD.md
?? scripts/lib/manifest-inputs.sh
?? scripts/manifest-sync.sh
?? scripts/tests/manifest-method-test.sh
```

---

## 2. Per-task summary

### Task 1 — `scripts/manifest-sync.sh` (NEW, ~175 ln)

Implements design §2. Functions:
- `_resolve_push_range` — `@{upstream}..HEAD` (primary) → `origin/<branch>..HEAD` (fallback) → `HEAD` tip + warn (last resort). Honors `PACK_MANIFEST_RANGE` override (used by the test).
- `_fixture_inputs_changed` — union `git diff --name-only <range>` ∩ the SoT predicate (`manifest_path_is_input`). Commit-count-agnostic set test (not a per-commit loop). `HEAD` pseudo-range diffs `HEAD~1..HEAD` (or lists tree if HEAD is root).
- `_regen_manifest` — runs `bash test-fixtures/build.sh --all --clean` ONCE, then `git diff --quiet -- test-fixtures/manifest.txt` to decide NOOP vs CHANGED.
- `main` — exit-code contract (§2.7): `0`=SKIP/NOOP, `10`=MANIFEST-CHANGED, `1`=error. Stdout tokens `MANIFEST-SKIP` / `MANIFEST-NOOP` / `MANIFEST-CHANGED`.
- NEVER stages/commits/pushes. No-op + idempotent (§2.6).
- Line 2 marker `# pack-internal: true  (push-time build/release tool; not a user-facing verb)` — required by Check 23 (BD-082); see §3 deviation note.

Verification: `bash -n` clean; SKIP smoke against the real repo (`PACK_MANIFEST_RANGE="HEAD..HEAD"` → `MANIFEST-SKIP`, exit 0, no build triggered).

### Task 2 — `scripts/lib/manifest-inputs.sh` (NEW, ~135 ln)

The single SoT (design §2.3). Exposes `MANIFEST_INPUT_GLOBS`, `MANIFEST_DENY_GLOBS`, and the pure predicate `manifest_path_is_input <path>`. Input set = `project-template/*` + `scripts/*` + `test-fixtures/build.sh` + exactly `supporting-docs/METHODOLOGY.md` + `supporting-docs/INSTALL-PROCEDURES.md`. Deny set = `scripts/test*.sh` + `scripts/tests/*` + `scripts/manifest-sync.sh` + `scripts/lib/manifest-inputs.sh`. Sourceable, idempotent (double-source guard), bash 3.2-compatible, no side effects. The ONLY place the set is written (consumed by the tool + the predicate-drift test).

Verification: `bash -n` clean; inline membership smoke confirmed all 6 input cases → INPUT and all 8 deny/excluded cases → skip (`pack-ops/`, `maintenance-docs/`, other `supporting-docs/`, the tool/SoT/tests, `test-fixtures/manifest.txt`, `README.md`).

### Task 3 — `scripts/tests/manifest-method-test.sh` (NEW, ~215 ln)

Self-provisioned test (design §7.1; rule `test-infra-self-provisioned`). NEVER touches the real repo/fixtures/manifest — every case builds a fresh `/tmp` scratch git repo (`mktemp -d`) with the real tool + SoT copied in and a STUB `build.sh` (offline + fast; spies each invocation via a run-marker file). 6 groups / 34 assertions:
- G1 POSITIVE input change → exit 10 + MANIFEST-CHANGED + manifest differs + build.sh ran once.
- G2 NEGATIVE non-input commit (`maintenance-docs/` + `pack-ops/`) → exit 0 + MANIFEST-SKIP + build.sh NOT run (proven with a `change`-behavior stub that would change the manifest if ever called).
- G3 NEGATIVE comment-only input edit → exit 0 + MANIFEST-NOOP + build.sh ran once, manifest unchanged.
- G4 IDEMPOTENCY → both runs exit 0, manifest stable.
- G5 RANGE/commit-count-agnostic → 3 input commits → exit 10 + build.sh ran EXACTLY ONCE.
- G6 PREDICATE-DRIFT screen against the REAL SoT — 14 include/exclude assertions (project-template/, scripts/ minus tests, build.sh, the 2 supporting-docs; EXCLUDES pack-ops/ + maintenance-docs/ + the tool/SoT/tests + test-fixtures/manifest.txt).
- `trap cleanup EXIT` removes all scratch dirs.

Verification: `bash -n` clean; direct run → **PASS: 34   FAIL: 0**.

### Task 4 — design-doc archive

`cp /tmp/handoff-bd226-manifest-method/DESIGN-MANIFEST-PUSH-METHOD.md maintenance-docs/v11-implementation/DESIGN-MANIFEST-PUSH-METHOD.md`. `diff -q` → byte-identical. (Matches the `backlog/BD-228.md` References pointer per plan EB-6.)

---

## 3. Plan deviations

**One deviation (mechanical, design-correct — surfaced for reviewer awareness):**

- **D1 — `# pack-internal: true` marker added to `scripts/manifest-sync.sh`.** The plan/design did not enumerate this. On the first `validate-pack` run, **Check 23 (Help-fragment completeness, BD-082)** FAILed with `scripts/ executables missing from HELP-FRAGMENT-PACK.md (or mark with # pack-internal: true): manifest-sync.sh`. Check 23 requires every top-level `scripts/*.{sh,py}` executable to either appear in `HELP-FRAGMENT-PACK.md` or carry the `# pack-internal: true` marker. `manifest-sync.sh` is a pack-internal push-time build/release tool (NOT a user-facing `pack help` verb; does not ship — `dependency-direction-placement`), so the marker is the design-correct disposition (identical to how the 11 existing internal scripts, e.g. `test-detect.sh`, are handled). I did NOT add it to `HELP-FRAGMENT-PACK.md` (that would mislabel it as a user verb). The SoT lib (`scripts/lib/`) and test (`scripts/tests/`) are NOT scanned by Check 23 (it iterates top-level `scripts/` only — verified in `validate-pack.py` line 2155 `scripts_dir.iterdir()`), so no marker needed there. This is a lock-step encoding-surface obligation (`enumerate-encoding-surfaces`), folded mechanically; no design fork.

Zero other deviations. The design's resolved PICKs are carried unchanged: exact predicate, all-`scripts/`-minus-tests-minus-tool, exit-code contract `0/10/1`, tool never commits, self-hosting (no per-commit manifest).

---

## 4. Self-hosting manifest handling (critical — followed exactly)

Per prompt "SELF-HOSTING MANIFEST" + plan §3: **no per-commit manifest carried in C1.** I did NOT stage `test-fixtures/manifest.txt`.

**Pre-existing baseline manifest drift discovered (out-of-scope; surfaced, NOT fixed):** to run the fixture-dependent battery (`verify-full-ci-suite`), I built fixtures once (`build.sh --all --clean`, exit 0). The rebuild produced **different SHAs for the 3 v11 fixtures** vs the committed baseline:
```
-v11-realistic-ot  49a4b801...   +v11-realistic-ot  12de16d4...
-v11-flat-file     688fbff2...   +v11-flat-file     2eaad161...
-v11-tracker-on    67fa09c0...   +v11-tracker-on    17b1e663...
```
Investigation (read-only git):
- The committed manifest's last touch is `1143267` (BD-221 C10, project-template). `git log 1143267..HEAD -- project-template/` is EMPTY — no project-template commit since.
- My 4 C1 files are ALL untracked and ALL outside the fixture-input set (proven by the G6 predicate-drift assertions). **None of my edits can affect any fixture SHA.**
- Therefore the committed manifest was **already stale at baseline `3bad276`**, invisible to `validate-pack` (which does NOT rebuild fixtures; the new Check 62 that screens the manifest does not exist until C2, and even it is structural-only). It is exactly the kind of drift `build.sh --verify` (the authoritative gate) catches at push. This is the situation BD-228 installs the push-time tool to resolve.

**Action taken:** I restored the working-tree manifest to the committed baseline via read-only git (`git show HEAD:test-fixtures/manifest.txt > test-fixtures/manifest.txt`) so I leave ZERO manifest change in C1. Final `git diff --stat -- test-fixtures/manifest.txt` is EMPTY.

**Recommendation for the orchestrator (NOT a C1 action):** at BD-228's push, run `bash scripts/manifest-sync.sh` over the unpushed range. BD-228's `scripts/` edits will match the predicate ⇒ the tool runs `build.sh --all --clean` once. Given the pre-existing v11 drift above, the rebuilt manifest will DIFFER ⇒ the tool exits **10 (MANIFEST-CHANGED)**, and the orchestrator commits the regenerated manifest (the trailing-commit shape, scope-neutral for Check 36) with user approval. NOTE: this differs from the plan §3 "likely MANIFEST-NOOP" prediction because the plan's prediction assumed the committed manifest was already current — empirically it is NOT (pre-existing drift). The orchestrator must follow the tool's ACTUAL exit (10), not the prediction. This is the designed loud-catch path (design §6.2) working as intended.

---

## 5. Verification results (all quoted)

### validate-pack (default + DEEP)
```
python3 scripts/validate-pack.py            → default exit=0   "PASSED — all checks clean"
PACK_VALIDATE_DEEP=1 python3 scripts/validate-pack.py → deep exit=0   "PASSED — all checks clean"
```
NEW fail-lines: **EMPTY** (only pre-existing JC-5 advisory WARNs about removed-doc citations — explicitly "advisory only, NOT a gate failure"; present at baseline, untouched). Check 23 now reports: `OK: all 9 non-internal scripts/ executables listed in HELP-FRAGMENT-PACK.md (11 marked pack-internal)`.

### New test direct run
```
bash scripts/tests/manifest-method-test.sh  → "PASS: 34   FAIL: 0"  (exit 0)
```

### Auto-wiring into CI shard matrix (confirmed picked up)
```
ci-shard-plan --print-partition → wired count 72 → 73 (KEEP 73), manifest-method-test.sh present @ 3.0s default weight
ci-shard-plan --assert-coverage → exit 0  "73 wired KEEP test(s) ... union == wired_KEEP_set; pairwise-disjoint; fixture cohesion co-located"
```
The tool `manifest-sync.sh` is correctly NOT swept into the test set (does not match the test glob); no allowlist/weights-TSV edit needed (graceful default weight).

### Full wired CI battery (enumerated via --print-partition; fixtures built once)
```
73 wired tests run once each (incl. 5 fixture-dependent + the new manifest-method-test.sh)
=== BATTERY TOTALS ===  PASS files: 73   FAIL files: 0   FAILED: (none)
```
The new test appears in the executed set (`scripts/tests/manifest-method-test.sh` → 34/34 PASS). Pre-existing manifest drift breaks NO wired test. Manifest left at committed baseline after the battery (empty diff).

### Syntax checks
```
bash -n scripts/manifest-sync.sh        → clean
bash -n scripts/lib/manifest-inputs.sh  → clean
bash -n scripts/tests/manifest-method-test.sh → clean
```

### Filename uniqueness (`filename-uniqueness-heuristic`)
```
find . -name <each-new-file> -not -path "./.git/*"  → exactly one hit each (all unique)
```

---

## 6. Full file contents of new files (for re-apply without re-derivation)

> The four new files are reproduced verbatim below for re-apply fidelity. (`DESIGN-MANIFEST-PUSH-METHOD.md` is a byte-identical copy of `/tmp/handoff-bd226-manifest-method/DESIGN-MANIFEST-PUSH-METHOD.md` — not re-pasted here to avoid a 780-line duplication; re-create with `cp` from that source.)

### `scripts/lib/manifest-inputs.sh`
```bash
#!/usr/bin/env bash
# scripts/lib/manifest-inputs.sh — the SINGLE source of truth for the
# fixture-input predicate used by the push-time manifest method.
#
# BD-228 (design maintenance-docs/v11-implementation/DESIGN-MANIFEST-PUSH-METHOD.md
# §2.3). A "fixture input" is any pack-side path whose content is copied into a
# test fixture by scripts/init-project.sh, OR is sourced by test-fixtures/build.sh
# at fixture-build time, OR is the fixture builder itself. When such an input
# changes, the deterministic fixture SHAs in test-fixtures/manifest.txt may
# change and the manifest must be regenerated (push-time, by
# scripts/manifest-sync.sh).
#
# This file is the ONLY place the input set is written. Both the push-time tool
# (scripts/manifest-sync.sh) and the predicate-drift test
# (scripts/tests/manifest-method-test.sh) source it so the set cannot silently
# drift. The realized consumers are:
#   - scripts/manifest-sync.sh           (membership-tests changed paths)
#   - scripts/tests/manifest-method-test.sh  (predicate-drift assertions)
#
# Dependency direction (CLAUDE.md "dependency-direction-placement"): this is
# pack-internal build/release tooling. It is NEVER a runtime dependency of any
# project-side deliverable and no client surface invokes it; it does NOT ship
# (absent from the install-map and from _SANCTIONED_PACK_SIDE_SHIPPED).
#
# Sourceable: it only defines variables + a pure shell predicate function with
# NO side effects, so it is safe to `source` from any bash 3.2+ context.
#
# Predicate semantics (design §2.3):
#   regen_needed(path) = (path matches an INPUT glob) AND (path matches NO DENY glob)
#
# Input globs (the measured fixture-input set — design EB-5/EB-6):
#   - project-template/**                  (the bulk fixture content)
#   - scripts/**                           (minus the deny set below)
#   - test-fixtures/build.sh               (the builder is itself an input)
#   - supporting-docs/METHODOLOGY.md       (copied to client docs/pack/)
#   - supporting-docs/INSTALL-PROCEDURES.md (copied to client docs/pack/)
#
# Deny globs (carved out of scripts/** because they are NOT installed into any
# fixture — editing them changes no fixture SHA; design §2.3):
#   - scripts/test*.sh                     (top-level test scripts)
#   - scripts/tests/**                     (the test tree)
#   - scripts/manifest-sync.sh             (this method's own tool)
#   - scripts/lib/manifest-inputs.sh       (this SoT)
#
# Excluded entirely (NOT inputs — zero copy sites; design EB-5): pack-ops/,
# maintenance-docs/, and all of supporting-docs/ except the two named files.

# Guard against double-source (idempotent).
if [[ -n "${_MANIFEST_INPUTS_SH_SOURCED:-}" ]]; then
    return 0 2>/dev/null || true
fi
_MANIFEST_INPUTS_SH_SOURCED=1

# The fixture-input globs (repo-relative). bash 3.2-compatible arrays.
MANIFEST_INPUT_GLOBS=(
    "project-template/*"
    "scripts/*"
    "test-fixtures/build.sh"
    "supporting-docs/METHODOLOGY.md"
    "supporting-docs/INSTALL-PROCEDURES.md"
)

# The deny globs (carved out of the input globs above).
MANIFEST_DENY_GLOBS=(
    "scripts/test*.sh"
    "scripts/tests/*"
    "scripts/manifest-sync.sh"
    "scripts/lib/manifest-inputs.sh"
)

# _path_matches_glob <path> <glob>
# Pure prefix/glob membership test. A trailing "/*" glob matches the directory
# subtree at ANY depth (bash `==` glob `*` does not cross `/`, so we special-case
# the recursive-subtree form by prefix). A non-subtree glob uses bash `==`
# pattern matching. Returns 0 on match, 1 otherwise. No side effects.
_path_matches_glob() {
    local path="$1" glob="$2"
    case "$glob" in
        */\*)
            # Recursive subtree: "<dir>/*" matches "<dir>/" + anything below.
            local prefix="${glob%\*}"   # keep the trailing slash
            case "$path" in
                "$prefix"*) return 0 ;;
                *)          return 1 ;;
            esac
            ;;
        *)
            # Exact or single-segment glob match.
            # shellcheck disable=SC2053
            [[ "$path" == $glob ]] && return 0
            return 1
            ;;
    esac
}

# manifest_path_is_input <path>
# The fixture-input predicate. Returns 0 (true) iff <path> matches at least one
# INPUT glob AND no DENY glob. Pure; safe to call in a loop. This is the single
# membership test both the tool and the test rely on.
manifest_path_is_input() {
    local path="$1" g
    local matched_input=1   # 1 = false (not yet matched)
    for g in "${MANIFEST_INPUT_GLOBS[@]}"; do
        if _path_matches_glob "$path" "$g"; then
            matched_input=0
            break
        fi
    done
    [[ $matched_input -eq 0 ]] || return 1
    for g in "${MANIFEST_DENY_GLOBS[@]}"; do
        if _path_matches_glob "$path" "$g"; then
            return 1   # denied → not an input
        fi
    done
    return 0
}
```

### `scripts/manifest-sync.sh`
```bash
#!/usr/bin/env bash
# pack-internal: true  (push-time build/release tool; not a user-facing verb)
# scripts/manifest-sync.sh — push-time fixture-manifest regeneration method.
#
# BD-228 (design maintenance-docs/v11-implementation/DESIGN-MANIFEST-PUSH-METHOD.md
# §2). Run by the orchestrator immediately BEFORE `git push`, after all commits
# for the push are landed locally. It regenerates test-fixtures/manifest.txt
# EXACTLY ONCE iff a fixture input changed in the commits about to be pushed, and
# is a complete no-op otherwise. Commit-count-agnostic: a 1-commit and a
# 20-commit push are screened by the same union-diff set test.
#
# This tool NEVER stages, commits, or pushes (CLAUDE.md "agents-never-commit" —
# tools do not commit; only the orchestrator commits, with user approval). It
# regenerates the manifest file on disk and reports via the exit-code contract +
# a stdout token; the orchestrator decides how to land any change.
#
# Dependency direction (CLAUDE.md "dependency-direction-placement"): pack-internal
# build/release tool. NEVER a runtime dependency of a project deliverable; no
# client surface invokes it; it does NOT ship (absent from the install-map and
# from _SANCTIONED_PACK_SIDE_SHIPPED).
#
# Exit-code contract (design §2.7), consumed by the orchestrator:
#   0   → no action needed:
#           MANIFEST-SKIP  (no fixture input changed; build.sh NOT run)
#           MANIFEST-NOOP  (an input changed, but the rebuilt manifest is identical)
#   10  → MANIFEST-CHANGED: the regenerated manifest differs; the orchestrator
#         must commit it before push.
#   1   → error (build.sh failed, or the git range is hard-unresolvable).
#
# Stdout tokens (one per run): MANIFEST-SKIP / MANIFEST-NOOP / MANIFEST-CHANGED
# (errors print to stderr).
#
# Usage:
#   bash scripts/manifest-sync.sh            # screen the unpushed range, regen iff needed
#   PACK_MANIFEST_RANGE="A..B" bash scripts/manifest-sync.sh   # override the range (tests)
#
# Idempotent: re-running on a current tree yields MANIFEST-NOOP/MANIFEST-SKIP +
# exit 0 (the rebuild is deterministic — design §2.6).

set -u

# ── Exit codes ──────────────────────────────────────────────────────────────
readonly EXIT_OK=0
readonly EXIT_CHANGED=10
readonly EXIT_ERR=1

# ── Locate repo + load the input predicate (single SoT) ─────────────────────
THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$THIS_DIR/.." && pwd)"
BUILD_SH="$REPO_ROOT/test-fixtures/build.sh"
MANIFEST="$REPO_ROOT/test-fixtures/manifest.txt"
INPUTS_LIB="$THIS_DIR/lib/manifest-inputs.sh"

say()  { printf '%s\n' "$*"; }
warn() { printf 'manifest-sync: warning: %s\n' "$*" >&2; }
err()  { printf 'manifest-sync: error: %s\n' "$*" >&2; }

if [[ ! -f "$INPUTS_LIB" ]]; then
    err "input predicate SoT not found: $INPUTS_LIB"
    exit "$EXIT_ERR"
fi
# shellcheck source=scripts/lib/manifest-inputs.sh
. "$INPUTS_LIB"

# ── Resolve the unpushed range (design §2.3) ────────────────────────────────
# Prefer an explicit override (used by the self-provisioned test). Otherwise:
#   @{upstream}..HEAD   — commits not yet on the tracking remote (primary)
#   origin/<branch>..HEAD — if no upstream is configured
#   HEAD               — tip-only screen + warn (no remote ref resolvable)
_resolve_push_range() {
    if [[ -n "${PACK_MANIFEST_RANGE:-}" ]]; then
        printf '%s\n' "$PACK_MANIFEST_RANGE"
        return 0
    fi
    if git -C "$REPO_ROOT" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' \
            >/dev/null 2>&1; then
        printf '%s\n' "@{upstream}..HEAD"
        return 0
    fi
    local branch
    branch="$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
    if [[ -n "$branch" && "$branch" != "HEAD" ]] \
            && git -C "$REPO_ROOT" rev-parse --verify -q "origin/$branch" >/dev/null 2>&1; then
        printf '%s\n' "origin/$branch..HEAD"
        return 0
    fi
    warn "no upstream/origin ref resolvable; screening HEAD tip only (push may under-scope)"
    printf '%s\n' "HEAD"
    return 0
}

# ── Determine whether any fixture input changed over the range ──────────────
# Union diff of changed paths over the range, then the SoT membership test.
# Commit-count-agnostic: one set test over the union, not a per-commit loop.
_fixture_inputs_changed() {
    local range="$1" changed path
    # For a tip-only "HEAD" pseudo-range, diff HEAD against its first parent so a
    # single unpushed tip commit is still screened; if HEAD has no parent, fall
    # back to listing the tree (treat all tracked paths as candidates).
    if [[ "$range" == "HEAD" ]]; then
        if git -C "$REPO_ROOT" rev-parse --verify -q "HEAD~1" >/dev/null 2>&1; then
            changed="$(git -C "$REPO_ROOT" diff --name-only "HEAD~1..HEAD" 2>/dev/null || true)"
        else
            changed="$(git -C "$REPO_ROOT" ls-files 2>/dev/null || true)"
        fi
    else
        changed="$(git -C "$REPO_ROOT" diff --name-only "$range" 2>/dev/null || true)"
    fi
    # Empty diff → no inputs changed.
    [[ -n "$changed" ]] || return 1
    while IFS= read -r path; do
        [[ -n "$path" ]] || continue
        if manifest_path_is_input "$path"; then
            return 0
        fi
    done <<EOF
$changed
EOF
    return 1
}

# ── Regenerate the manifest ONCE, report whether it changed on disk ─────────
# Returns: 0 = manifest unchanged after rebuild (NOOP); 10 = manifest changed
# (CHANGED); 1 = build.sh failed.
_regen_manifest() {
    if [[ ! -f "$BUILD_SH" ]]; then
        err "fixture builder not found: $BUILD_SH"
        return "$EXIT_ERR"
    fi
    say "manifest-sync: fixture input changed — rebuilding fixtures once (build.sh --all --clean)"
    if ! bash "$BUILD_SH" --all --clean >&2; then
        err "build.sh --all --clean failed"
        return "$EXIT_ERR"
    fi
    # Did the committed manifest change on disk?
    if git -C "$REPO_ROOT" diff --quiet -- "test-fixtures/manifest.txt" 2>/dev/null; then
        return "$EXIT_OK"      # unchanged → NOOP
    fi
    return "$EXIT_CHANGED"     # changed → orchestrator must commit it
}

main() {
    local range rc
    range="$(_resolve_push_range)"

    if ! _fixture_inputs_changed "$range"; then
        say "MANIFEST-SKIP: no fixture-input changed in $range"
        exit "$EXIT_OK"
    fi

    _regen_manifest
    rc=$?
    case "$rc" in
        "$EXIT_OK")
            say "MANIFEST-NOOP: input changed but $MANIFEST is unchanged after rebuild"
            exit "$EXIT_OK"
            ;;
        "$EXIT_CHANGED")
            say "MANIFEST-CHANGED: test-fixtures/manifest.txt"
            exit "$EXIT_CHANGED"
            ;;
        *)
            exit "$EXIT_ERR"
            ;;
    esac
}

main "$@"
```

### `scripts/tests/manifest-method-test.sh`
```bash
#!/usr/bin/env bash
# scripts/tests/manifest-method-test.sh — self-provisioned tests for the
# push-time manifest method (scripts/manifest-sync.sh + scripts/lib/manifest-inputs.sh).
#
# BD-228 (design maintenance-docs/v11-implementation/DESIGN-MANIFEST-PUSH-METHOD.md
# §7.1). This test NEVER mutates the real repo, the real fixtures, or the real
# test-fixtures/manifest.txt (CLAUDE.md "Test infra is self-provisioned"). Every
# behavioral case runs against a fresh /tmp SCRATCH git repo built per-case, with
# a STUB test-fixtures/build.sh so the suite is offline + fast (no ~30-90s real
# fixture rebuild) while still exercising the tool's real predicate, range
# resolution, single-invocation, exit-code, and idempotency logic. The real
# scripts/lib/manifest-inputs.sh + scripts/manifest-sync.sh are copied verbatim
# into the scratch repo.
#
# Auto-wires into the CI shard matrix by the scripts/tests/*.sh disk glob
# (BD-219) — no manual wiring / allowlist edit.
#
# Coverage (design §7.1):
#   Group 1: POSITIVE input change → exit 10 + MANIFEST-CHANGED + manifest differs
#   Group 2: NEGATIVE non-input commit → exit 0 + MANIFEST-SKIP + build.sh NOT run
#   Group 3: NEGATIVE comment-only-input edit → exit 0 + MANIFEST-NOOP
#   Group 4: IDEMPOTENCY → re-run on current tree = exit 0, manifest unchanged
#   Group 5: RANGE / commit-count-agnostic → 3-commit range = build.sh runs ONCE
#   Group 6: PREDICATE-DRIFT screen against the REAL SoT (include/exclude assertions)
#
# Usage: bash scripts/tests/manifest-method-test.sh

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REAL_SYNC="$REPO_ROOT/scripts/manifest-sync.sh"
REAL_INPUTS="$REPO_ROOT/scripts/lib/manifest-inputs.sh"

PASS=0
FAIL=0
t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() {
    FAIL=$((FAIL + 1))
    printf "  \033[31mFAIL\033[0m %s\n" "$1"
    [[ -n "${2:-}" ]] && printf "       %s\n" "$2"
}

# Track scratch dirs for cleanup.
SCRATCH_DIRS=()
cleanup() {
    local d
    for d in "${SCRATCH_DIRS[@]:-}"; do
        [[ -n "$d" && -d "$d" ]] && rm -rf "$d"
    done
}
trap cleanup EXIT

# Deterministic git env for scratch commits (no dependency on the runner's git
# identity).
_gitc() {
    GIT_AUTHOR_NAME="MM Test" GIT_AUTHOR_EMAIL="mm@test" \
    GIT_COMMITTER_NAME="MM Test" GIT_COMMITTER_EMAIL="mm@test" \
    GIT_AUTHOR_DATE="2026-01-01T00:00:00Z" GIT_COMMITTER_DATE="2026-01-01T00:00:00Z" \
    git "$@"
}

# _new_scratch [behavior]
# Build a fresh scratch repo. The stub build.sh appends a run-marker to
# $SCRATCH/.build-runs each invocation (the spy), then (re)writes
# test-fixtures/manifest.txt per the chosen behavior:
#   stable  (default) → manifest content unchanged from the committed baseline
#   change            → manifest content updated (simulates a real SHA drift)
# Prints the scratch root path.
_new_scratch() {
    local behavior="${1:-stable}"
    local scratch
    scratch="$(mktemp -d "${TMPDIR:-/tmp}/mm-scratch.XXXXXX")"
    SCRATCH_DIRS+=("$scratch")

    mkdir -p "$scratch/scripts/lib" "$scratch/test-fixtures" \
             "$scratch/project-template" "$scratch/pack-ops" \
             "$scratch/maintenance-docs"
    cp "$REAL_SYNC" "$scratch/scripts/manifest-sync.sh"
    cp "$REAL_INPUTS" "$scratch/scripts/lib/manifest-inputs.sh"

    # Stub build.sh: records each run (spy) + rewrites the manifest per behavior.
    cat > "$scratch/test-fixtures/build.sh" <<STUB
#!/usr/bin/env bash
set -u
THIS_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
printf 'run\n' >> "\$THIS_DIR/../.build-runs"
if [[ "$behavior" == "change" ]]; then
    printf 'fixture-a  %040d\n' 1 > "\$THIS_DIR/manifest.txt"
else
    # stable: reproduce the committed baseline byte-for-byte.
    printf 'fixture-a  %040d\n' 0 > "\$THIS_DIR/manifest.txt"
fi
exit 0
STUB
    chmod +x "$scratch/test-fixtures/build.sh"

    # Committed baseline manifest (matches the stub's "stable" output).
    printf 'fixture-a  %040d\n' 0 > "$scratch/test-fixtures/manifest.txt"

    # Seed content + initial commit.
    printf 'seed\n' > "$scratch/project-template/seed.txt"
    printf 'doc\n'  > "$scratch/maintenance-docs/notes.md"
    _gitc -C "$scratch" init -q
    _gitc -C "$scratch" add -A
    _gitc -C "$scratch" commit -q -m "seed"
    printf '%s\n' "$scratch"
}

_build_runs() {
    local scratch="$1"
    [[ -f "$scratch/.build-runs" ]] && wc -l < "$scratch/.build-runs" | tr -d ' ' || echo 0
}

# Run the tool against a scratch repo over a given range; capture out + rc.
# Args: <scratch> <range>. Sets globals: MM_OUT, MM_RC.
_run_tool() {
    local scratch="$1" range="$2"
    MM_OUT="$(cd "$scratch" && PACK_MANIFEST_RANGE="$range" bash scripts/manifest-sync.sh 2>/dev/null)"
    MM_RC=$?
}

# ─────────────────────────────────────────────────────────────────
# Group 0: artifacts present
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 0: artifacts present ===\n"
[[ -f "$REAL_SYNC" ]]   && t_pass "scripts/manifest-sync.sh present"      || t_fail "scripts/manifest-sync.sh missing"
[[ -f "$REAL_INPUTS" ]] && t_pass "scripts/lib/manifest-inputs.sh present" || t_fail "scripts/lib/manifest-inputs.sh missing"
if bash -n "$REAL_SYNC" 2>/dev/null;   then t_pass "manifest-sync.sh syntax OK";   else t_fail "manifest-sync.sh syntax error"; fi
if bash -n "$REAL_INPUTS" 2>/dev/null; then t_pass "manifest-inputs.sh syntax OK"; else t_fail "manifest-inputs.sh syntax error"; fi

# ─────────────────────────────────────────────────────────────────
# Group 1: POSITIVE — input change → exit 10 + MANIFEST-CHANGED + manifest differs
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 1: input change → regen (exit 10) ===\n"
s1="$(_new_scratch change)"
before="$(cat "$s1/test-fixtures/manifest.txt")"
printf 'edit\n' >> "$s1/project-template/seed.txt"
_gitc -C "$s1" commit -q -am "touch a fixture input (project-template/)"
_run_tool "$s1" "HEAD~1..HEAD"
after="$(cat "$s1/test-fixtures/manifest.txt")"
[[ $MM_RC -eq 10 ]]                       && t_pass "exit 10 on input change"            || t_fail "expected exit 10, got $MM_RC" "$MM_OUT"
printf '%s' "$MM_OUT" | grep -q "MANIFEST-CHANGED" && t_pass "stdout MANIFEST-CHANGED"   || t_fail "expected MANIFEST-CHANGED token" "$MM_OUT"
[[ "$before" != "$after" ]]               && t_pass "manifest differs after regen"       || t_fail "manifest unchanged but should differ"
[[ "$(_build_runs "$s1")" == "1" ]]       && t_pass "build.sh ran exactly once"          || t_fail "build.sh ran $(_build_runs "$s1") times (expected 1)"

# ─────────────────────────────────────────────────────────────────
# Group 2: NEGATIVE — non-input commit → exit 0 + MANIFEST-SKIP + build.sh NOT run
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 2: non-input commit → no-op (SKIP, build.sh not run) ===\n"
s2="$(_new_scratch change)"   # 'change' behavior to PROVE build.sh is never called
printf 'more\n' >> "$s2/maintenance-docs/notes.md"
mkdir -p "$s2/pack-ops"; printf 'ops\n' > "$s2/pack-ops/PACK-CHAT.md"
_gitc -C "$s2" add -A
_gitc -C "$s2" commit -q -m "maintenance-docs/ + pack-ops/ only (non-input)"
before2="$(cat "$s2/test-fixtures/manifest.txt")"
_run_tool "$s2" "HEAD~1..HEAD"
after2="$(cat "$s2/test-fixtures/manifest.txt")"
[[ $MM_RC -eq 0 ]]                        && t_pass "exit 0 on non-input commit"         || t_fail "expected exit 0, got $MM_RC" "$MM_OUT"
printf '%s' "$MM_OUT" | grep -q "MANIFEST-SKIP" && t_pass "stdout MANIFEST-SKIP"         || t_fail "expected MANIFEST-SKIP token" "$MM_OUT"
[[ "$(_build_runs "$s2")" == "0" ]]       && t_pass "build.sh NOT invoked"               || t_fail "build.sh ran $(_build_runs "$s2") times (expected 0)"
[[ "$before2" == "$after2" ]]             && t_pass "manifest byte-unchanged"            || t_fail "manifest changed on a no-op"

# ─────────────────────────────────────────────────────────────────
# Group 3: NEGATIVE — comment-only input edit → exit 0 + MANIFEST-NOOP
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 3: comment-only input edit → NOOP (build ran, no diff) ===\n"
s3="$(_new_scratch stable)"   # 'stable' → rebuild reproduces the committed manifest
printf '# harmless comment\n' >> "$s3/scripts/init-fake.sh"  # a scripts/ input, no fixture-SHA effect
_gitc -C "$s3" add -A
_gitc -C "$s3" commit -q -m "comment-only input edit (scripts/)"
before3="$(cat "$s3/test-fixtures/manifest.txt")"
_run_tool "$s3" "HEAD~1..HEAD"
after3="$(cat "$s3/test-fixtures/manifest.txt")"
[[ $MM_RC -eq 0 ]]                        && t_pass "exit 0 on comment-only input edit"  || t_fail "expected exit 0, got $MM_RC" "$MM_OUT"
printf '%s' "$MM_OUT" | grep -q "MANIFEST-NOOP" && t_pass "stdout MANIFEST-NOOP"         || t_fail "expected MANIFEST-NOOP token" "$MM_OUT"
[[ "$(_build_runs "$s3")" == "1" ]]       && t_pass "build.sh ran once (input matched)"  || t_fail "build.sh ran $(_build_runs "$s3") times (expected 1)"
[[ "$before3" == "$after3" ]]             && t_pass "manifest unchanged (rebuild = baseline)" || t_fail "manifest changed on a NOOP"

# ─────────────────────────────────────────────────────────────────
# Group 4: IDEMPOTENCY — re-run on current tree = exit 0, manifest unchanged
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 4: idempotency ===\n"
s4="$(_new_scratch stable)"
printf 'x\n' >> "$s4/project-template/seed.txt"
_gitc -C "$s4" commit -q -am "input edit (stable rebuild)"
_run_tool "$s4" "HEAD~1..HEAD"; first_rc=$MM_RC
base4="$(cat "$s4/test-fixtures/manifest.txt")"
_run_tool "$s4" "HEAD~1..HEAD"; second_rc=$MM_RC
again4="$(cat "$s4/test-fixtures/manifest.txt")"
[[ $first_rc -eq 0 && $second_rc -eq 0 ]] && t_pass "both runs exit 0 (NOOP/stable)"     || t_fail "runs not both exit 0: $first_rc/$second_rc"
[[ "$base4" == "$again4" ]]               && t_pass "manifest stable across re-runs"     || t_fail "manifest drifted on re-run"

# ─────────────────────────────────────────────────────────────────
# Group 5: RANGE / commit-count-agnostic — 3 input commits → build.sh runs ONCE
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 5: 3-commit range → build.sh runs exactly once ===\n"
s5="$(_new_scratch change)"
printf 'c1\n' >> "$s5/project-template/seed.txt";       _gitc -C "$s5" commit -q -am "input commit 1"
printf 'c2\n' >  "$s5/scripts/extra.sh";                _gitc -C "$s5" add -A; _gitc -C "$s5" commit -q -m "input commit 2"
mkdir -p "$s5/supporting-docs"; printf 'c3\n' > "$s5/supporting-docs/METHODOLOGY.md"
_gitc -C "$s5" add -A; _gitc -C "$s5" commit -q -m "input commit 3"
_run_tool "$s5" "HEAD~3..HEAD"
[[ $MM_RC -eq 10 ]]                       && t_pass "3-commit range → exit 10"           || t_fail "expected exit 10, got $MM_RC" "$MM_OUT"
[[ "$(_build_runs "$s5")" == "1" ]]       && t_pass "build.sh ran exactly once for 3 commits" || t_fail "build.sh ran $(_build_runs "$s5") times (expected 1)"

# ─────────────────────────────────────────────────────────────────
# Group 6: PREDICATE-DRIFT screen against the REAL SoT
# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 6: predicate-drift screen (real SoT) ===\n"
# Source the REAL SoT in a subshell and assert include/exclude membership.
drift_check() {
    local desc="$1" path="$2" want="$3" got
    if ( . "$REAL_INPUTS"; manifest_path_is_input "$path" ); then got="include"; else got="exclude"; fi
    [[ "$got" == "$want" ]] && t_pass "$desc ($path → $want)" || t_fail "$desc: $path got $got want $want"
}
drift_check "project-template/ is an input"        "project-template/CLAUDE.md"            "include"
drift_check "scripts/ (non-test) is an input"      "scripts/init-project.sh"               "include"
drift_check "scripts/lib/ (non-test) is an input"  "scripts/lib/detect.sh"                 "include"
drift_check "test-fixtures/build.sh is an input"   "test-fixtures/build.sh"                "include"
drift_check "METHODOLOGY.md is an input"           "supporting-docs/METHODOLOGY.md"        "include"
drift_check "INSTALL-PROCEDURES.md is an input"    "supporting-docs/INSTALL-PROCEDURES.md" "include"
drift_check "scripts/test*.sh EXCLUDED"            "scripts/test-detect.sh"                "exclude"
drift_check "scripts/tests/** EXCLUDED"            "scripts/tests/manifest-method-test.sh" "exclude"
drift_check "the tool itself EXCLUDED"             "scripts/manifest-sync.sh"              "exclude"
drift_check "the SoT itself EXCLUDED"             "scripts/lib/manifest-inputs.sh"        "exclude"
drift_check "pack-ops/ EXCLUDED"                   "pack-ops/PACK-CHAT.md"                 "exclude"
drift_check "maintenance-docs/ EXCLUDED"           "maintenance-docs/x.md"                 "exclude"
drift_check "other supporting-docs/ EXCLUDED"      "supporting-docs/OTHER.md"              "exclude"
drift_check "test-fixtures/manifest.txt EXCLUDED"  "test-fixtures/manifest.txt"            "exclude"

# ─────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────
printf "\n=== Summary ===\n"
printf "PASS: %d   FAIL: %d\n" "$PASS" "$FAIL"
[[ $FAIL -eq 0 ]] || exit 1
exit 0
```

---

## 7. New POQs introduced

**POQ-C1-1 (disposition: surfaced to orchestrator; NOT a C1 fix).** The committed `test-fixtures/manifest.txt` is PRE-EXISTING STALE at baseline `3bad276` for the 3 v11 fixture rows (full evidence in §4). This is out of C1 scope (none of C1's files are fixture inputs) and is precisely what BD-228's push-time tool reconciles. Disposition: the orchestrator's BD-228 push-time `manifest-sync.sh` run will detect it (exit 10) and commit the corrected manifest with user approval. No C1 action. (Note: this contradicts the plan §3 "likely MANIFEST-NOOP" prediction — the empirical drift means the push outcome is MANIFEST-CHANGED, not NOOP. Surfaced so the orchestrator follows the tool's actual exit.)

---

## 8. Definition-of-Done checklist

| # | Item | Status |
|---|------|--------|
| 1 | Regime verified (worktree pwd + HEAD `3bad276`); handoff dir created | PASS |
| 2 | `scripts/manifest-sync.sh` created per design §2 (range, predicate, regen-once, exit contract `0/10/1`, never commits) | PASS |
| 3 | `scripts/lib/manifest-inputs.sh` created — single SoT, exact predicate (project-template + scripts−tests−tool + build.sh + 2 supporting-docs; excludes pack-ops + maintenance-docs) | PASS |
| 4 | `scripts/tests/manifest-method-test.sh` created — self-provisioned `/tmp` scratch, never touches real repo/manifest; all design §7.1 cases | PASS (34/34) |
| 5 | Design doc archived to `maintenance-docs/v11-implementation/DESIGN-MANIFEST-PUSH-METHOD.md` (byte-identical) | PASS |
| 6 | Boundary `pack-only`: only the 4 scoped files created; no other file; NO manifest staged | PASS |
| 7 | `validate-pack.py` default exit 0; DEEP exit 0; NEW fail-lines EMPTY | PASS |
| 8 | New test auto-wires into CI shard matrix (wired 72→73; coverage assert green; no allowlist/weights edit) | PASS |
| 9 | Full wired CI battery run once (73 tests, fixtures built once) — PASS 73 / FAIL 0; new test in the set | PASS |
| 10 | `bash -n` clean on all 3 new scripts | PASS |
| 11 | Tool does NOT ship (no install-map / `_SANCTIONED_PACK_SIDE_SHIPPED` entry; marked pack-internal) | PASS |
| 12 | No state-changing git verb run; HEAD unchanged | PASS |
| 13 | No patch emitted (per prompt) | PASS |
| 14 | PREFLIGHT line emitted before this report | PASS |

---

## 9. Rules-Applied Verification Block

| # | Rule | Verification evidence (quoted) | Conclusion |
|---|------|-------------------------------|-----------|
| 1 | **agents-never-commit** | Ran only read-only git: `git rev-parse HEAD` → `3bad276…` (unchanged start↔end), `git status --short`, `git diff`, `git log`, `git show HEAD:test-fixtures/manifest.txt` (read-only file restore via stdout redirect — NOT a git state change). NO `git add/commit/push/tag/stash/checkout/reset/restore/apply`. Only writes = the 4 scoped files + this report. | COMPLIANT |
| 2 | **per-action-approval-sub-agents** | No destructive op on own authority. The only `rm -rf` is inside the test's `trap cleanup EXIT` against `mktemp -d` scratch dirs under `/tmp` (never the real tree). Manifest restore used read-only `git show >` (no destructive verb). | COMPLIANT |
| 3 | **preflight-stop-means-stop** | Emitted the PREFLIGHT line (`4/4 in-scope edits complete; verification PASS; HEAD 3bad276; about to Write IMPL-REPORT…`) only AFTER all edits + validate-pack default+DEEP + the 73-test battery + new-test 34/34 all PASS. No parent stop received. | COMPLIANT |
| 4 | **sub-agents-verify-regime** | STEP 0: `pwd` → `…/.claude/worktrees/agent-a320c05ebccaf8d9c` (worktree path CONFIRMED); `git rev-parse --short HEAD` → `3bad276` (matches expected). Branch `worktree-agent-a320c05ebccaf8d9c`. Both reported. | COMPLIANT |
| 5 | **test-infra-self-provisioned** | `manifest-method-test.sh` builds a fresh `mktemp -d "${TMPDIR:-/tmp}/mm-scratch.XXXXXX"` per case, copies the real tool/SoT in, uses a STUB build.sh; `trap cleanup EXIT` removes all scratch dirs. Asserted it never writes the real manifest: final `git diff --stat -- test-fixtures/manifest.txt` EMPTY after the test + battery. | COMPLIANT |
| 6 | **dependency-direction-placement** | Tool is pack-side build/release tooling: NOT added to install-map, NOT added to `_SANCTIONED_PACK_SIDE_SHIPPED` (Check 47 set stays `{scripts/lib/detect.sh, scripts/pack-help.sh}` — validate-pack green confirms). Marked `# pack-internal: true`; Check 23 reports `11 marked pack-internal`. No client surface invokes it. | COMPLIANT |
| 7 | **ci-check-runtime-compounding** | N/A for the tool. The NEW TEST runs offline + fast: a STUB build.sh (no ~30-90s real fixture rebuild), `/tmp` scratch repos. It picked up default weight `3.0s` in `ci-shard-plan --print-partition`. | N/A (tool); COMPLIANT (test fast/offline) |
| 8 | **verify-full-ci-suite** | Ran the FULL wired battery (73 tests via `ci-shard-plan --print-partition` enumeration, fixtures built once) → "PASS files: 73   FAIL files: 0", PLUS validate-pack default AND `PACK_VALIDATE_DEEP=1` (both exit 0), PLUS the new test direct (34/34). Not validate-pack alone. New test in the executed set. | COMPLIANT |
| 9 | **edit-in-place-not-full-rewrite** | All 4 deliverables are NEW files (no in-place rewrite of existing content). The one edit to an existing-tree concept (manifest) was a read-only restore to committed baseline, not a content rewrite. No incidental edits to any existing file. | N/A (new files); COMPLIANT |
| 10 | **rules-applied-verification-block** | This table — each rule: name + quoted evidence (command/path/count/exit) + conclusion; no empty-evidence cell. | COMPLIANT |

---

**End of IMPL-REPORT — C1.**
