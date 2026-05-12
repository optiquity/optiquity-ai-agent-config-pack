# IMPLEMENTATION REPORT — BD-119 C-5

**BD:** BD-119 (migrator framework refactor)
**Commit:** C-5 — behavior-preservation harness (mandatory gate before C-6 cutover)
**Author:** pack-coder
**Date:** 2026-05-08
**Branch:** `worktree-agent-a76fc6093a00ab6fb`
**Final HEAD SHA:** `0532526ed0e38b1b6cc8f13a18d5c4138a7a3f3e`

> **Note on HEAD.** No git state changes are made by pack-coder; HEAD
> here is identical to the worktree base SHA recorded in pre-flight.
> Pack Chat will commit C-5 against this same HEAD to produce the C-5
> commit (parent = `0532526`). The worktree is intentionally clean
> apart from the new untracked harness script (and the gitignored
> snapshot file recovered per POQ-4).

---

## 1. Pre-flight check (verbatim)

```
$ pwd
/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a76fc6093a00ab6fb

$ git rev-parse HEAD
0532526ed0e38b1b6cc8f13a18d5c4138a7a3f3e

$ git rev-parse --abbrev-ref HEAD
worktree-agent-a76fc6093a00ab6fb

$ git log --oneline -10
0532526 docs: v11 — clarify BD-116 sequencing note + expand BD-121 scope (validate-pack + supporting-docs ripple)
23b0cb0 feat: v11 — BD-119 C-4b: add test-migrator-core.sh (T-12 unit tests; closes POQ-6)
e41831f docs: v11 — BD-124 pack-coder skills (implementation-report, verification-harness, commit-discipline) (Open, blocked on BD-119)
9d4efd6 feat: v11 — BD-119 C-4: implement stages + manifest engine + manifest unit tests
5934547 docs: v11 — BD-121/122/123 v9 sunset + fixture convention + tracker.toml.example relocation (Open)
5f11419 feat: v11 — BD-119 C-3: implement core sequencer + public API (surface lock)
2b17184 feat: v11 — BD-119 C-2: land migrator-core/stages/manifest skeletons
dcd37f7 feat: v11 — pack-coder agent + repo-local Pack memory section
fda99ef feat: v11 — BD-119 C-1: existed before commit, BD-119 C-1: detect_target_pack_version + validate-pack Check 26 (lenient)
6286fcf feat: v11 — BD-115 existing-project-mid-dev fixture

$ ls scripts/lib/ | grep migrator
migrator-core.sh
migrator-manifest.sh
migrator-stages.sh

$ ls scripts/ | grep -E "test-(detect|migrator)"
test-detect.sh
test-migrator-core.sh
test-migrator-manifest.sh

$ ls test-fixtures/
build.sh
manifest.txt
README.md

$ ls scripts/.bd119-pre-refactor-monolith.sh.snapshot 2>&1 || echo "(snapshot missing — see C-1 report)"
ls: scripts/.bd119-pre-refactor-monolith.sh.snapshot: No such file or directory
(snapshot missing — see C-1 report)
```

**Pre-flight verdict:** all asserted checks pass except the snapshot
file, which is gitignored and missing on this worktree. The user prompt
and PLAN POQ-4 both anticipate this case and specify the recovery path.
**Recovery applied immediately:**

```
$ git show d7b3f07:scripts/migrate-v10-to-v11.sh > \
    scripts/.bd119-pre-refactor-monolith.sh.snapshot
$ wc -l scripts/.bd119-pre-refactor-monolith.sh.snapshot scripts/migrate-v10-to-v11.sh
     437 scripts/.bd119-pre-refactor-monolith.sh.snapshot
     437 scripts/migrate-v10-to-v11.sh
```

The snapshot recovers byte-for-byte to `scripts/migrate-v10-to-v11.sh`
on the current worktree (pre-cutover monolith is unchanged from C-1).
This is the expected pre-C-6 state and is what the harness self-test
exercises.

The fixture `test-fixtures/v10-realistic-ot/` was also missing and was
re-built via `bash test-fixtures/build.sh --name v10-realistic-ot
--clean` (allowed: fixture trees are gitignored per
`test-fixtures/.gitignore`). The build's incidental edit to the tracked
`test-fixtures/manifest.txt` (it marks unbuilt fixtures as
`(not built)`) was reverted by re-writing the canonical manifest from
`git show HEAD:test-fixtures/manifest.txt` so the tracked file stays
identical to HEAD.

---

## 2. T-task summary for C-5

PLAN-BD-119.md §6 row "C-5" originally framed the commit as
`T-14 partial — harness exists; runs old monolith only`. The user
prompt (and the §8 equivalence-contract spec, which is stricter than
§6's row) re-scopes C-5 to the **full** harness: BASELINE (snapshot)
vs ADAPTER (current `migrate-v10-to-v11.sh`) compared across all five
axes, both runs already required to match at C-5 because pre-cutover
they invoke the same monolith. This makes the C-5 deliverable a
correct, mandatory gate at the moment C-6 lands. Per the user prompt:
"the harness must already be correct so C-6's behavior-preservation
diff is meaningful."

| Task | Description | Status |
|------|-------------|--------|
| **T-13 (PLAN §1)** | Behavior-preservation harness implementing the §8 equivalence contract: 5 axes, 2 redaction families, BASELINE-vs-ADAPTER comparison, fail-loud on any non-trivial diff. | Done — harness file written; self-test green. |
| **POQ-4 recovery** | Snapshot file gitignored and absent on this worktree; recovered via `git show d7b3f07:...` per the C-1 IMPLEMENTATION-REPORT-BD-119.md guidance. | Done — file present, byte-identical to source SHA. |

No additional T-tasks from PLAN §6 row "C-5" were assigned to this
commit. T-13 (refactor of `migrate-v10-to-v11.sh` into the framework
adapter) and T-14/T-15 (CI hookup, README/trinity updates) belong to
C-6/C-7 and are explicitly out of scope per the user prompt:
"Do NOT do C-6 (cutover) or C-7 (docs)."

The harness does **not** yet wire into `.github/workflows/validate-pack.yml`
— that is the C-6 task per PLAN §8.5 ("At C-6, `BD119_REFACTOR_LANDED=1`
is set and the full diff runs"). At C-5 the harness exists on the
worktree as a runnable script that Pack Chat (and the implementer) can
exercise before authoring C-6's cutover commit.

---

## 3. Files inventory

| Path | Type | Lines | Notes |
|------|------|-------|-------|
| `scripts/test-migrator-behavior-preservation.sh` | new (untracked) | 369 | The harness. |
| `scripts/.bd119-pre-refactor-monolith.sh.snapshot` | recovered (gitignored) | 437 | POQ-4 snapshot from `d7b3f07`. |
| `test-fixtures/v10-realistic-ot/` | rebuilt (gitignored) | — | Materialized via `build.sh --name v10-realistic-ot --clean`. SHA `239c98a` matches manifest. |
| `test-fixtures/manifest.txt` | reverted | 9 | Build modified other fixtures' SHAs to "not built"; canonical content restored from HEAD. |

No source files under `scripts/lib/` were modified. Public API surface
remains frozen as required by C-3.

---

## 4. Plan deviations

**One scoping deviation — pre-approved by user prompt.**

PLAN §6 row "C-5" describes a *partial* harness (monolith-only smoke
check) gated by a `BD119_REFACTOR_LANDED=0` env. The user prompt
overrides this with a fuller scope: at C-5, run BOTH BASELINE and
ADAPTER, prove they match. Rationale (verbatim from prompt): "the
HARD test will be at C-6 when one side becomes the framework adapter —
the harness must already be correct so C-6's behavior-preservation
diff is meaningful." This is a **correctness improvement** over the
original §6 row and is consistent with §8 (the equivalence contract,
which is the authoritative spec for what the harness must do).

No `BD119_REFACTOR_LANDED` gate is implemented — the harness simply
runs both implementations and asserts equivalence. At C-5 they are
the same monolith (trivially equivalent); at C-6 they will be
monolith vs framework adapter (the meaningful test). This is simpler
and removes the failure mode where a soft-gate hides a real C-6
defect.

**No other deviations.** Public API surface untouched, no new redaction
regexes beyond timestamps + tmp paths, no allow-listing, no source
modification.

---

## 5. POQs introduced

**None.**

POQ-4 (snapshot recovery) was already documented in the C-1
implementation report; this commit consumes it (recovers the snapshot
file when missing) but does not add a new POQ.

---

## 6. Verification

### 6.1 Bash syntax check on the harness

```
$ bash -n scripts/test-migrator-behavior-preservation.sh
(no output — exit 0)
```

PASS.

### 6.2 Harness self-test (BASELINE vs current ADAPTER monolith)

```
$ bash scripts/test-migrator-behavior-preservation.sh
== pre-flight ==
  baseline source: /Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a76fc6093a00ab6fb/scripts/.bd119-pre-refactor-monolith.sh.snapshot (POQ-4 snapshot file)
  adapter source: /Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a76fc6093a00ab6fb/scripts/migrate-v10-to-v11.sh
  fixture:        /Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-a76fc6093a00ab6fb/test-fixtures/v10-realistic-ot
  results dir:    /var/folders/38/2gkt0krd4m55gktw0t7n8wrr0000gn/T/bd119-results.XXXXXX.H804CHmrdR
== running BASELINE (pre-refactor monolith) ==
  exit=0
== running ADAPTER (current scripts/migrate-v10-to-v11.sh) ==
  exit=0
== A5 — exit code equality ==
  pass: A5 exit codes match (baseline=0 adapter=0)
== A1 — file list equality ==
  pass: A1 file lists byte-identical
== A2 — per-file content equality ==
  pass: A2 per-file content byte-identical across all files
== A3 — report.md equality (post-redaction) ==
  pass: A3 report.md byte-identical post-redaction
== A4 — stdout equality (post-redaction) ==
  pass: A4 stdout byte-identical post-redaction

=== Results: 5 passed, 0 failed ===
```

**5/5 axes match.** Harness exits 0.

### 6.3 Regression suite

```
$ bash scripts/test-detect.sh
=== Results: 40 passed, 0 failed ===

$ bash scripts/test-migrator-core.sh
=== Results: 19 passed, 0 failed ===

$ bash scripts/test-migrator-manifest.sh
=== Results: 12 passed, 0 failed ===
```

All three regression test scripts green; 71 assertions pass, 0 fail.

### 6.4 validate-pack.py

```
$ python3 scripts/validate-pack.py
… [26 checks listed] …
── Check 26: BD-119 migrator-framework inventory ──
  OK: scripts/lib/migrator-core.sh syntax valid
  OK: scripts/lib/migrator-stages.sh syntax valid
  OK: scripts/lib/migrator-manifest.sh syntax valid
  OK: migrator-core.sh declares all 6 public-API functions
  OK: migrator-core.sh declares all 8 exit-code constants
  OK: migrator-core.sh preserves EXIT_NOT_V10 back-compat synonym

============================================================
PASSED — all checks clean
```

26/26 checks pass.

### 6.5 git status post-changes

```
$ git status
On branch worktree-agent-a76fc6093a00ab6fb
Untracked files:
  (use "git add <file>..." to include in what will be committed)
	scripts/test-migrator-behavior-preservation.sh

nothing added to commit but untracked files present (use "git add" to track)
```

Working tree is clean except for the new untracked harness script. The
gitignored snapshot file (`scripts/.bd119-pre-refactor-monolith.sh.snapshot`)
and the rebuilt fixture tree (`test-fixtures/v10-realistic-ot/`) do
not appear because they are in `.gitignore` /
`test-fixtures/.gitignore`. HEAD unchanged at `0532526`.

---

## 7. Definition of Done — C-5

| Criterion | Status |
|-----------|--------|
| Harness exists at `scripts/test-migrator-behavior-preservation.sh` | PASS |
| `bash -n` on the harness exits 0 | PASS |
| Harness self-test (BASELINE vs current ADAPTER, same monolith) passes 5/5 axes | PASS |
| All 5 axes (A1 file list, A2 file content, A3 report.md, A4 stdout, A5 exit code) implemented per PLAN §8.2 | PASS |
| No forbidden soft fixes (allow-list, extra redactions, continue-on-error, v11.0 tag-with-red) | PASS |
| Redactions limited to timestamps (ISO-8601 + epoch) + tmp paths (`/tmp`, `/var/folders`, `$TMPDIR`) | PASS |
| Snapshot recovered per POQ-4 (`d7b3f07:scripts/migrate-v10-to-v11.sh`) when absent | PASS |
| Regression suite green (`test-detect.sh`, `test-migrator-core.sh`, `test-migrator-manifest.sh`) | PASS |
| `python3 scripts/validate-pack.py` 26/26 | PASS |
| No source file under `scripts/lib/` modified | PASS |
| Public API surface unchanged (frozen at C-3) | PASS |
| No git state changed (no add/commit/push/tag/reset/etc.) | PASS |
| Implementation report written at `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-119-C5.md` | PASS |
| macOS bash 3.2 + BSD utils compatible (no `sed -i`, no GNU-only flags, no bash-4 features) | PASS |

**All 14 DoD criteria PASS.**

---

## 8. Proposed C-5 commit message

```
feat: v11 — BD-119 C-5: behavior-preservation harness (mandatory pre-C-6 gate)
```

Body suggestion:

```
Add scripts/test-migrator-behavior-preservation.sh implementing the
PLAN-BD-119.md §8 equivalence contract: BASELINE (pre-refactor
monolith pinned at d7b3f07, recovered from gitignored snapshot or
git-show fallback per POQ-4) vs ADAPTER (current
scripts/migrate-v10-to-v11.sh) compared across five axes — file list,
file content, report.md (post-redaction), stdout (post-redaction),
exit code — with redactions limited to ISO-8601 timestamps,
epoch-seconds, and tmp paths under /tmp, /var/folders, $TMPDIR.

At C-5 BASELINE and ADAPTER are byte-identical (the pre-cutover
monolith), so the harness self-test trivially passes 5/5 axes. The
gate is meaningful at C-6, when the adapter becomes the framework
shim and equivalence must still hold.

No allow-list, no extra redactions, no continue-on-error — PLAN §13.3
forbidden soft fixes are not supported.

Verification:
- bash -n on harness: clean
- harness self-test: 5/5 axes match, exit 0
- bash scripts/test-detect.sh: 40 passed
- bash scripts/test-migrator-core.sh: 19 passed
- bash scripts/test-migrator-manifest.sh: 12 passed
- python3 scripts/validate-pack.py: 26/26 PASSED
```

---

## 9. Full file contents

### `scripts/test-migrator-behavior-preservation.sh`

(369 lines; see Appendix A below for verbatim content.)

---

## Appendix A — `scripts/test-migrator-behavior-preservation.sh` (verbatim)

```bash
#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/test-migrator-behavior-preservation.sh — BD-119 C-5 harness.
#
# Behavior-preservation gate for the BD-119 framework refactor of
# `scripts/migrate-v10-to-v11.sh`. Per PLAN-BD-119.md §8 (the equivalence
# contract) and ARCHITECTURE-BD-119.md §10 (behavior-preservation
# rationale), this harness pins five axes across two independent runs of
# the migrator and asserts byte-equivalence (modulo two narrowly scoped
# redactions). It is the mandatory gate before C-6 cutover; without it,
# C-6's refactor of the monolith into a framework adapter cannot be
# proven equivalent to the pre-refactor monolith.
#
# Two runs are compared:
#
#   BASELINE — the pre-refactor monolith pinned at SHA d7b3f07. Sourced
#              from scripts/.bd119-pre-refactor-monolith.sh.snapshot
#              when present (gitignored, branch-local, see C-1 report
#              POQ-4); recovered via `git show d7b3f07:...` when absent.
#
#   ADAPTER  — whatever scripts/migrate-v10-to-v11.sh currently is on
#              this worktree. At C-5 (this commit) it is still the
#              same monolith, so equivalence is trivially true. At C-6
#              it will be the framework adapter (~120 lines) calling
#              `migrator_run`, and the harness must remain green.
#
# Equivalence axes (PLAN §8.2):
#
#   A1 — file list:    set of files written/touched in the post-migration
#                      tree, byte-identical (excludes .git/).
#   A2 — file content: every output file byte-identical (post-redaction
#                      not applied — file content is checked raw via cmp).
#   A3 — report.md:    .pack-migrate-v10-to-v11/report.md content,
#                      byte-identical post-redaction.
#   A4 — stdout:       runtime stdout, byte-identical post-redaction.
#   A5 — exit code:    numeric exit code from the migrator.
#
# Allowed redactions (and ONLY these — PLAN §13.3 forbids broader
# redactions):
#   - ISO-8601 timestamps:   [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]+Z?
#   - Epoch-seconds:         10-digit integers used as timestamps
#   - Tmp paths:             /tmp/*, /var/folders/*, $TMPDIR/*
#
# Per PLAN §13.3, the harness MUST NOT support any of:
#   - allow-listing diverging files
#   - additional redaction regexes
#   - continue-on-error in CI
#   - tagging v11.0 with the harness red
#
# Usage:
#     bash scripts/test-migrator-behavior-preservation.sh [fixture-name]
#
#     fixture-name defaults to v10-realistic-ot. The named fixture must
#     exist under test-fixtures/<name>/ — re-build with
#     `bash test-fixtures/build.sh --name <name> --clean` if missing.
#
# Exit 0 on all five axes matching across all subtests; exit 1 otherwise
# with a per-axis breakdown. The summary line follows the convention
# established by sibling test scripts:
#
#     === Results: <P> passed, <F> failed ===

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ── POQ-4 snapshot reference ───────────────────────────────────────────────
# The pre-refactor monolith canonical SHA. d7b3f07 is the worktree base
# at which the BD-119 work began; this is the byte snapshot the harness
# diffs against. PLAN POQ-4 mandates this SHA as the canonical reference
# and specifies the recovery path when the gitignored snapshot file is
# absent on the working tree.
readonly BD119_PRE_REFACTOR_SHA="d7b3f07"
readonly SNAPSHOT_FILE="$PACK_ROOT/scripts/.bd119-pre-refactor-monolith.sh.snapshot"

FIXTURE_NAME="${1:-v10-realistic-ot}"
FIXTURE_DIR="$PACK_ROOT/test-fixtures/$FIXTURE_NAME"

RESULTS_DIR="$(mktemp -d -t bd119-results.XXXXXX)"
KEEP_RESULTS="${BD119_KEEP_RESULTS:-0}"
trap '_cleanup' EXIT

_cleanup() {
    if [[ "$KEEP_RESULTS" = "1" ]]; then
        printf 'BD119_KEEP_RESULTS=1: results retained at %s\n' \
            "$RESULTS_DIR" >&2
    else
        rm -rf "$RESULTS_DIR"
    fi
}

passes=0
fails=0

pass() { echo "  pass: $1"; passes=$((passes + 1)); }
fail() {
    echo "  FAIL: $1"
    [[ -n "${2:-}" ]] && printf '    detail: %s\n' "$2"
    fails=$((fails + 1))
}

die()  { printf 'error: %s\n' "$1" >&2; exit 1; }

# ── 0. Pre-flight ──────────────────────────────────────────────────────────
echo "== pre-flight =="

if [[ ! -d "$PACK_ROOT/project-template" ]]; then
    die "PACK_ROOT does not look like the pack repo: $PACK_ROOT"
fi

if [[ ! -f "$PACK_ROOT/scripts/migrate-v10-to-v11.sh" ]]; then
    die "missing scripts/migrate-v10-to-v11.sh under $PACK_ROOT"
fi

# Materialize the BASELINE migrator. Prefer the on-disk gitignored
# snapshot (faster + offline-safe). Fall back to git-show at the pinned
# pre-refactor SHA per PLAN POQ-4. If neither is reachable, fail loud.
BASELINE_FILE="$RESULTS_DIR/baseline.sh"

if [[ -f "$SNAPSHOT_FILE" ]]; then
    cp "$SNAPSHOT_FILE" "$BASELINE_FILE"
    echo "  baseline source: $SNAPSHOT_FILE (POQ-4 snapshot file)"
elif git -C "$PACK_ROOT" cat-file -e \
        "$BD119_PRE_REFACTOR_SHA:scripts/migrate-v10-to-v11.sh" 2>/dev/null
then
    git -C "$PACK_ROOT" show \
        "$BD119_PRE_REFACTOR_SHA:scripts/migrate-v10-to-v11.sh" \
        > "$BASELINE_FILE" \
        || die "git show failed at $BD119_PRE_REFACTOR_SHA"
    echo "  baseline source: git show $BD119_PRE_REFACTOR_SHA (POQ-4 fallback)"
else
    die "cannot recover BASELINE: neither snapshot file ($SNAPSHOT_FILE)
        nor SHA $BD119_PRE_REFACTOR_SHA reachable from $PACK_ROOT"
fi
chmod +x "$BASELINE_FILE"

ADAPTER_FILE="$PACK_ROOT/scripts/migrate-v10-to-v11.sh"
echo "  adapter source: $ADAPTER_FILE"
echo "  fixture:        $FIXTURE_DIR"
echo "  results dir:    $RESULTS_DIR"

# Materialize the fixture if absent. The fixture's own state is verified
# against test-fixtures/manifest.txt (the build script does this when
# --clean is passed). For the harness's purpose we only need the fixture
# tree to exist; manifest verification is the build script's concern.
if [[ ! -d "$FIXTURE_DIR" ]]; then
    echo "  fixture missing — building via test-fixtures/build.sh"
    bash "$PACK_ROOT/test-fixtures/build.sh" --name "$FIXTURE_NAME" --clean \
        >/dev/null 2>&1 \
        || die "fixture build failed; rerun manually: bash test-fixtures/build.sh --name $FIXTURE_NAME --clean"
fi
[[ -d "$FIXTURE_DIR" ]] || die "fixture still missing after build: $FIXTURE_DIR"

# ── Helpers ────────────────────────────────────────────────────────────────

# Redact the only nondeterministic sources allowed by PLAN §8.2:
#   - ISO-8601 timestamps (with optional Z and fractional seconds)
#   - 10-digit epoch-seconds (only when bracketed by non-digits, to avoid
#     eating arbitrary 10-digit content elsewhere)
#   - Tmp paths under /tmp/, /var/folders/, and $TMPDIR (BSD mktemp on
#     macOS lands under /var/folders; Linux mktemp under /tmp; harness
#     itself may use $TMPDIR if set)
#
# No other redactions are permitted (PLAN §13.3). All sed -E patterns are
# bash-3.2 + BSD/GNU portable; no -i (BSD vs GNU divergent).
_redact() {
    local in="$1" out="$2"
    local tmpdir_pat
    tmpdir_pat=""
    if [[ -n "${TMPDIR:-}" ]]; then
        # Strip trailing slash for stable matching, escape for sed.
        local td="${TMPDIR%/}"
        tmpdir_pat=$(printf '%s' "$td" | sed -e 's/[][\.*^$/]/\\&/g')
    fi
    local sed_args=(
        -E
        -e 's#[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]+(\.[0-9]+)?Z?#<TS>#g'
        -e 's#(^|[^0-9])[0-9]{10}([^0-9]|$)#\1<EPOCH>\2#g'
        -e 's#/tmp/[^ "'"'"']*#<TMP>#g'
        -e 's#/var/folders/[^ "'"'"']*#<TMP>#g'
    )
    if [[ -n "$tmpdir_pat" ]]; then
        sed_args+=(-e "s#${tmpdir_pat}/[^ \"']*#<TMP>#g")
    fi
    sed "${sed_args[@]}" < "$in" > "$out"
}

# Run one impl (BASELINE or ADAPTER) against one /tmp clone of the
# fixture. Captures stdout, stderr, exit, post-tree filelist, and the
# tree itself (tar). Excludes .git/ from filelist + tar (per PLAN §8.2
# A1 rule and to keep the harness independent of git-internal flux).
_run_impl() {
    local impl="$1" migrator="$2"
    local clone="$RESULTS_DIR/$impl.tree"
    rm -rf "$clone"
    mkdir -p "$clone"

    # Copy the fixture content. The fixture is itself a git repo (built
    # by test-fixtures/build.sh) so we can `cp -R` and the .git/
    # subtree comes along — needed because the migrator requires a
    # clean git working tree (S0 preflight).
    cp -R "$FIXTURE_DIR/." "$clone/"

    PACK="$PACK_ROOT" \
    bash "$migrator" "$clone" \
        > "$RESULTS_DIR/$impl.stdout" 2> "$RESULTS_DIR/$impl.stderr"
    local rc=$?
    printf '%d\n' "$rc" > "$RESULTS_DIR/$impl.exit"

    # File list: every regular file post-migration, excluding .git/ and
    # the .pack-migrate-* state + backup directories. PLAN §8.3 spells
    # this exclusion out verbatim: the state dir contains diagnostic
    # files (three-way diff side-files, dispositions.tsv, etc.) whose
    # content embeds tmp paths and run timestamps that vary between
    # any two invocations of the migrator — even of the *same* monolith.
    # report.md (also under the state dir) is checked separately by axis
    # A3 with redactions applied. Use LC_ALL=C sort for deterministic
    # ordering across BSD vs GNU find.
    (
        cd "$clone" && \
        find . -type f \
            \! -path './.git/*' \
            \! -path './.git' \
            \! -path './.pack-migrate-*/*' \
            \! -path './.pack-migrate-*' \
            -print 2>/dev/null \
            | LC_ALL=C sort > "$RESULTS_DIR/$impl.filelist"
    )

    # Tar archive of the post-migration tree (excluding .git/ + every
    # .pack-migrate-* dir) so axis A2 can `cmp` per-file content without
    # re-walking the filesystem twice. BSD + GNU tar both accept
    # --exclude. Pattern matches both .pack-migrate-v10-to-v11/ and
    # .pack-migrate-v10-to-v11-backup/ in one expression.
    tar -C "$clone" \
        --exclude='./.git' \
        --exclude='./.pack-migrate-*' \
        -cf "$RESULTS_DIR/$impl.tar" . 2>/dev/null

    return 0
}

# ── 1. Run BASELINE + ADAPTER ──────────────────────────────────────────────
echo "== running BASELINE (pre-refactor monolith) =="
_run_impl baseline "$BASELINE_FILE"
b_rc=$(cat "$RESULTS_DIR/baseline.exit")
echo "  exit=$b_rc"

echo "== running ADAPTER (current scripts/migrate-v10-to-v11.sh) =="
_run_impl adapter "$ADAPTER_FILE"
a_rc=$(cat "$RESULTS_DIR/adapter.exit")
echo "  exit=$a_rc"

# Both must exit 0 for axes A1..A4 to be meaningfully comparable. If
# both are non-zero AND identical, A5 still passes (negative-leg
# behavior preservation), but A1..A3 are not asserted because the tree
# may be in an undefined intermediate state. Document this and treat
# the case as a partial run.
both_succeeded=0
if [[ "$b_rc" = "0" && "$a_rc" = "0" ]]; then
    both_succeeded=1
fi

# ── A5. Exit code equality ─────────────────────────────────────────────────
echo "== A5 — exit code equality =="
if [[ "$b_rc" = "$a_rc" ]]; then
    pass "A5 exit codes match (baseline=$b_rc adapter=$a_rc)"
else
    fail "A5 exit codes differ" "baseline=$b_rc adapter=$a_rc"
fi

# ── A1. File list equality ─────────────────────────────────────────────────
echo "== A1 — file list equality =="
if [[ "$both_succeeded" = "1" ]]; then
    if diff -u "$RESULTS_DIR/baseline.filelist" \
              "$RESULTS_DIR/adapter.filelist" \
              > "$RESULTS_DIR/A1.diff" 2>&1; then
        pass "A1 file lists byte-identical"
    else
        fail "A1 file lists differ" \
            "see $RESULTS_DIR/A1.diff (BD119_KEEP_RESULTS=1 to retain)"
        head -40 "$RESULTS_DIR/A1.diff" >&2
    fi
else
    fail "A1 skipped — at least one impl failed before completion" \
        "baseline=$b_rc adapter=$a_rc"
fi

# ── A2. Per-file content equality ──────────────────────────────────────────
echo "== A2 — per-file content equality =="
if [[ "$both_succeeded" = "1" ]]; then
    a2_misses=0
    a2_first_miss=""
    while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        # The filelist already excludes .pack-migrate-* (where report.md
        # and the diagnostic three-way diffs live), so no per-file
        # carve-out is needed here. report.md is asserted separately by
        # axis A3 with the allowed redactions applied.
        # Use tar -xO (POSIX, BSD + GNU) to extract one file each side.
        # cmp is POSIX. Both are bash-3.2 safe.
        if ! cmp -s \
            <(tar -xOf "$RESULTS_DIR/baseline.tar" "$f" 2>/dev/null) \
            <(tar -xOf "$RESULTS_DIR/adapter.tar" "$f" 2>/dev/null)
        then
            a2_misses=$((a2_misses + 1))
            [[ -z "$a2_first_miss" ]] && a2_first_miss="$f"
        fi
    done < "$RESULTS_DIR/baseline.filelist"
    if [[ "$a2_misses" -eq 0 ]]; then
        pass "A2 per-file content byte-identical across all files"
    else
        fail "A2 $a2_misses file(s) differ" \
            "first divergence: $a2_first_miss"
    fi
else
    fail "A2 skipped — at least one impl failed before completion" \
        "baseline=$b_rc adapter=$a_rc"
fi

# ── A3. report.md equality (post-redaction) ────────────────────────────────
echo "== A3 — report.md equality (post-redaction) =="
if [[ "$both_succeeded" = "1" ]]; then
    b_report="$RESULTS_DIR/baseline.tree/.pack-migrate-v10-to-v11/report.md"
    a_report="$RESULTS_DIR/adapter.tree/.pack-migrate-v10-to-v11/report.md"
    if [[ ! -f "$b_report" || ! -f "$a_report" ]]; then
        fail "A3 report.md missing on at least one side" \
            "baseline=$([[ -f $b_report ]] && echo present || echo absent) adapter=$([[ -f $a_report ]] && echo present || echo absent)"
    else
        _redact "$b_report" "$RESULTS_DIR/baseline.report.redacted"
        _redact "$a_report" "$RESULTS_DIR/adapter.report.redacted"
        if cmp -s "$RESULTS_DIR/baseline.report.redacted" \
                  "$RESULTS_DIR/adapter.report.redacted"; then
            pass "A3 report.md byte-identical post-redaction"
        else
            diff -u "$RESULTS_DIR/baseline.report.redacted" \
                    "$RESULTS_DIR/adapter.report.redacted" \
                    > "$RESULTS_DIR/A3.diff" 2>&1
            fail "A3 report.md differs post-redaction" \
                "see $RESULTS_DIR/A3.diff"
            head -40 "$RESULTS_DIR/A3.diff" >&2
        fi
    fi
else
    fail "A3 skipped — at least one impl failed before completion" \
        "baseline=$b_rc adapter=$a_rc"
fi

# ── A4. Stdout equality (post-redaction) ───────────────────────────────────
echo "== A4 — stdout equality (post-redaction) =="
_redact "$RESULTS_DIR/baseline.stdout" "$RESULTS_DIR/baseline.stdout.redacted"
_redact "$RESULTS_DIR/adapter.stdout"  "$RESULTS_DIR/adapter.stdout.redacted"
if cmp -s "$RESULTS_DIR/baseline.stdout.redacted" \
          "$RESULTS_DIR/adapter.stdout.redacted"; then
    pass "A4 stdout byte-identical post-redaction"
else
    diff -u "$RESULTS_DIR/baseline.stdout.redacted" \
            "$RESULTS_DIR/adapter.stdout.redacted" \
            > "$RESULTS_DIR/A4.diff" 2>&1
    fail "A4 stdout differs post-redaction" \
        "see $RESULTS_DIR/A4.diff"
    head -40 "$RESULTS_DIR/A4.diff" >&2
fi

# ── Summary ────────────────────────────────────────────────────────────────
echo
echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
```
