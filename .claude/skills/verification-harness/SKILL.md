---
name: verification-harness
description: Use when authoring or extending a pack test runner under scripts/. Codifies the pack test-script pattern (header, fixtures, per-case lines, summary, exit code) and the bash 3.2 / BSD-utils portability requirements.
allowed-tools: Read, Write, Edit, Bash
---

# Verification harness

The pack test convention. Canonical examples:

- `scripts/test-detect.sh` — unit tests for `scripts/lib/detect.sh`
- `scripts/test-migrator-core.sh` — public-API surface of the migrator framework
- `scripts/test-migrator-manifest.sh` — engine-side manifest behavior

When adding a new test runner, match this pattern. When extending an
existing one, do not invent a parallel pattern — extend the script in
place.

## Required structural elements

### 1. Header comment

```bash
#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/test-<name>.sh — <one-line description of what is tested>
#
# <Expanded description: which functions, which contracts, which BD,
# which plan section. Reference the canonical doc that defines the
# behavior the tests are pinning down.>
#
# Usage:    bash scripts/test-<name>.sh
# Exit 0 on all pass; exit 1 on any failure.
```

The `pack-internal: true` marker tells the pack help / verb scanner that
this is not a user-facing command.

### 2. Fixture-temp setup

```bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

FIXTURE_BASE="$(mktemp -d "${TMPDIR:-/tmp}/test-<name>.XXXXXX")"
trap 'rm -rf "$FIXTURE_BASE"' EXIT
```

Notes:
- Use the portable full-path template `mktemp -d "${TMPDIR:-/tmp}/<prefix>.XXXXXX"`
  — it works identically on BSD (macOS) and GNU (Linux), which both expand a
  trailing-`XXXXXX` full path. Do NOT use `mktemp -d -t <prefix>.XXXXXX`: it is
  NON-portable (BSD treats the `-t` argument as a literal prefix and appends its
  own suffix, leaving a literal `XXXXXX` in the path), as is GNU-only `--tmpdir`
  (BSD lacks it). CI Check 92 enforces this.
- The `trap … EXIT` cleanup MUST be registered before any fixtures are
  created. A test failure mid-script must not leak `/tmp/` directories.
- `set -uo pipefail` (NOT `set -e`) — let assertion failures be tallied
  rather than aborting the run on the first failure.

### 3. Counter + helper functions

```bash
passes=0
fails=0

fail() {
    echo "  FAIL: $1"
    [[ -n "${2:-}" ]] && printf '    expected: %s\n' "$2"
    [[ -n "${3:-}" ]] && printf '    actual:   %s\n' "$3"
    fails=$((fails + 1))
}
pass() { echo "  pass: $1"; passes=$((passes + 1)); }

assert_eq() {
    local label="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        pass "$label"
    else
        fail "$label" "$expected" "$actual"
    fi
}
```

Inline these helpers in each test script. (Factoring into
`scripts/lib/test-helpers.sh` and sourcing is DECLINED for now.
Keeping helpers inline makes each script self-contained and
diff-friendly; a single shared lib is a future optimization, not a
current requirement.)

Common helpers beyond `assert_eq`:

- `assert_contains <haystack> <needle> <description>` — for substring
  matches in command output
- `assert_exit_code <expected-rc> <actual-rc> <description>` — for
  testing failure modes (use `cmd; rc=$?` to capture without aborting
  under `set -u`)

Define only the helpers the script actually uses; do not paste a kitchen
sink.

### 4. Fixture macros

When a script needs the same kind of fixture in many cases, factor a
small macro. Examples:

```bash
mkfixture() {
    local name="$1"
    local dir="$FIXTURE_BASE/$name"
    mkdir -p "$dir"
    printf '%s' "$dir"
}

mkgitrepo() {
    local dir
    dir=$(mkfixture "$1")
    git -C "$dir" init -q -b main
    git -C "$dir" config user.email test@example.com
    git -C "$dir" config user.name test
    printf '%s' "$dir"
}

make_v10_target() {
    # Synthesizes a minimal v10-shape target dir: CLAUDE.md without v11
    # fingerprint, docs/pack/PROMPT-TEMPLATES.md present, no
    # .claude/skills/pm-help/.
    local dir
    dir=$(mkfixture "$1")
    mkdir -p "$dir/.claude" "$dir/docs/pack"
    printf '# CLAUDE.md\nv10 shape\n' > "$dir/CLAUDE.md"
    : > "$dir/docs/pack/PROMPT-TEMPLATES.md"
    printf '%s' "$dir"
}
```

Document each macro at definition with a one-line comment naming what
shape it produces.

### 5. Per-case structure

Every test case prints exactly one summary line:

- `  pass: <one-line description>`
- `  FAIL: <one-line description>` (plus optional `expected:` / `actual:`
  follow-up lines from the helper)

The description is specific and one line. Examples:

- `pass: trinity validator rejects when only 2 of 3 trinity files in manifest`
- `pass: detect_target_pack_version returns v10 for v10-shape target`
- `pass: migrator_dispatch with no args → die EXIT_INTERNAL (arity guard)`

Anti-pattern: multi-line case descriptions, generic descriptions like
"works correctly", or descriptions that do not name the input + expected
output.

Group related cases under section banners:

```bash
# ── detect_clean_working_tree ──────────────────────────────────────────
echo "== detect_clean_working_tree =="
```

### 6. Final summary

```bash
# ── Summary ────────────────────────────────────────────────────────────
echo
echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
```

The exact string `=== Results: N passed, M failed ===` is what Pack Chat
greps for in implementation reports. Do not vary the format. Exit 0 iff
M = 0.

## Portability requirements (macOS bash 3.2 + BSD utils)

The pack ships to developer macs running stock `/bin/bash` (3.2) and
BSD utilities. Pack CI also runs on Linux. Both must pass. Forbidden
constructs:

- `mapfile` / `readarray` — bash 4+ only. Use a `while read` loop.
- Associative arrays (`declare -A`) — bash 4+ only. Use parallel
  indexed arrays or a delimited string.
- GNU-only `sed -i` (no extension argument) — BSD `sed -i` requires an
  empty string argument. Portable form: write to a tempfile and `mv`.
- `${var^^}` / `${var,,}` (case modification) — bash 4+ only. Use
  `tr '[:lower:]' '[:upper:]'` / `tr '[:upper:]' '[:lower:]'`.
- `find -print0` paired with `xargs -0` — works on both, but only
  needed for paths containing whitespace or newlines. Test fixtures
  control their own path names — keep them whitespace-free and avoid
  `-print0` clutter.
- `&>file` redirection — POSIX form is `>file 2>&1`.
- `[[ … =~ … ]]` regex with PCRE-only constructs — BSD regex is BRE.

Allowed and recommended:

- `[[ "$a" == "$b" ]]` for string equality.
- `[[ "$haystack" == *"$needle"* ]]` for substring match (no regex).
- `printf '%s'` instead of `echo -n` (BSD `echo` does not support `-n`).
- `local` for function-scoped vars.
- `set -uo pipefail` (skip `-e` so individual assertion failures
  accumulate instead of aborting).

## Where a test runner lives (CI auto-discovery + fixture placement)

**Where a test runner lives.** A new pack test runner goes in
`scripts/tests/` (or, for the legacy top-level set, `scripts/test*.sh`).
CI **auto-discovers and shards** it — the `Validate Pack` workflow's
`tests` job is a DYNAMIC matrix derived at CI time from disk by
`scripts/lib/ci-shard-plan.py --emit-matrix`. There is **no
manual wiring step**: write the test, commit it, and it runs (sharded)
on the next push. (A test that genuinely cannot run offline-
deterministically in CI — a live-network/manual-only utility — is the
rare exception: add it to `scripts/ci-test-wiring-allowlist.txt` with a
one-line reason instead of leaving it unwired.)

**Fixture-dependent tests go in a dedicated subdir.** A test that
depends on a BUILT fixture (`test-fixtures/<name>/`, a gitignored build
artifact) MUST live in **`scripts/tests/fixture-dependent/`**. The
partitioner auto-pins everything in that subdir into the single shard
that builds fixtures, so the fixture is present before the test runs.
**Check 61** (`scripts/validate-pack.py`) enforces this: a fixture-
dependent test placed anywhere else fails loud with a "move it to
`scripts/tests/fixture-dependent/`" remediation. (Tests in that subdir
sit one level deeper, so compute the repo root with the matching `../`
depth — see the relocated examples there.)

## When to extend an existing script vs. add a new one

- Same target unit / same surface → extend the existing script.
- Different unit / different surface / different fixture style →
  new `scripts/test-<name>.sh`.
- A new BD that needs to verify multi-step behavior → consider a
  behavior-preservation harness (see `test-migrator-core.sh` for the
  adapter-test pattern).

Do not duplicate fixture macros across scripts; if two scripts need the
same fixture, that's the signal to factor — but per "DECLINED for now"
above, defer the factoring until at least three call-sites exist.
