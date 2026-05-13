#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/test-migrator-skills.sh — BD-147 tests for the migrator-skills.sh
# library and for the v10→v11 S5b helper that dispatches to it.
#
# Three test groups:
#
#   G1 — Golden-snapshot regression for the v10→v11 S5b helper.
#        Drives the (post-extraction) `_v10_to_v11_rename_python_architecture_refs`
#        helper from `scripts/migrate-v10-to-v11.sh` against a copy of
#        the `test-fixtures/v10-realistic-ot` fixture and asserts that
#        the rewritten PLATFORM-SKILLS.md, the trinity files, AND the
#        generated advisory match the byte-identical sha256 set captured
#        from the pre-extraction inline implementation. This is the
#        PLAN-SKILL-DIMENSIONS.md §4.5 mitigation.
#
#   G2 — `migrator_skill_rename` SIMPLE-mode unit tests.
#        Synthetic fixture exercising the bare 2-arg API:
#           a. clean rename of a fictional skill `foo-bar` → `baz-quux`;
#           b. token-boundary correctness — `foo-bar-extra` and
#              `extra-foo-bar` are NOT rewritten;
#           c. idempotent re-run is a no-op (file unchanged after
#              second invocation; no advisory written).
#
#   G3 — `migrator_skill_rename` SPLIT-mode unit tests.
#        Synthetic fixture exercising the 5-rule disambiguation:
#           a. line containing post-split server token rewrites stale
#              token to server name;
#           b. line containing post-split data token rewrites to data;
#           c. line containing only a server-tier signal rewrites to
#              server name; ditto data;
#           d. ambiguous line (no signals, no post-split tokens) is
#              left untouched and recorded in the advisory.
#
# Plus: `migrator_skill_split` thin-wrapper smoke check (G3.e) — the
# forward-declared API signature accepts (old, new-server, new-data,
# advisory) and produces equivalent output.
#
# Usage:    bash scripts/test-migrator-skills.sh
# Exit 0 on all pass; exit 1 on any failure.
#
# Per BD-147 / PLAN-SKILL-DIMENSIONS.md §2 Batch 8 + §4.5 + §7.2.
#
# ## Preconditions (BD-163)
#
# G1 depends on the built `test-fixtures/v10-realistic-ot/` fixture
# (a gitignored build artifact, not source — only present after running
# `bash test-fixtures/build.sh --name v10-realistic-ot`). G2 / G3 are
# self-contained (synthesize their own fixtures under `$TMPDIR`).
#
# `require_fixture` (below) validates fixture preconditions explicitly
# and fails fast with a clear, actionable error if a required fixture is
# missing — converting the prior silent `cp: cannot stat ...` failure
# into a self-documenting precondition. Add a `require_fixture <name>`
# call at the top of any future G-section that touches `test-fixtures/`.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ── BD-163 — fixture-precondition helper ───────────────────────────────
# Verifies that `test-fixtures/<name>/` exists AND has been built (per
# `test-fixtures/build.sh`, every fixture is initialized as a git repo,
# so `.git/HEAD` is the canonical built-fixture marker). On failure,
# prints the exact build command and exits non-zero. Portable bash 3.2
# / BSD-utils — no GNU-only constructs.
require_fixture() {
    local name="${1:?require_fixture: missing <name>}"
    local fx="$PACK_ROOT/test-fixtures/$name"
    if [[ ! -d "$fx" || ! -f "$fx/.git/HEAD" ]]; then
        printf 'ERROR: %s requires test-fixtures/%s/ but it does not exist or is not a built fixture.\n' \
            "$(basename "${BASH_SOURCE[1]:-$0}")" "$name" >&2
        printf '       Build it with: bash test-fixtures/build.sh --name %s\n' "$name" >&2
        printf '       (or build all fixtures: bash test-fixtures/build.sh --all --clean)\n' >&2
        exit 3
    fi
}

FIXTURE_BASE="$(mktemp -d -t test-migrator-skills.XXXXXX)"
trap 'rm -rf "$FIXTURE_BASE"' EXIT

passes=0
fails=0

pass() { printf '  pass: %s\n' "$1"; passes=$((passes + 1)); }
fail() {
    printf '  FAIL: %s\n' "$1" >&2
    [[ -n "${2:-}" ]] && printf '    expected: %s\n' "$2" >&2
    [[ -n "${3:-}" ]] && printf '    actual:   %s\n' "$3" >&2
    fails=$((fails + 1))
}
assert_eq() {
    local label="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        pass "$label"
    else
        fail "$label" "$expected" "$actual"
    fi
}

# ── Adapter contract for migrator-core preflight ─────────────────────────
# Source migrator-core (which sources migrator-skills via the BD-147
# wiring). The test does not call migrator_run; it sets the public
# library API surface (`migrator_skill_rename`, `migrator_skill_split`)
# plus the framework's say/info/fail_stage helpers in scope, then drives
# helpers directly.

export PACK="$PACK_ROOT"
MIGRATOR_FROM_VERSION="v10"
MIGRATOR_TO_VERSION="v11"
MIGRATOR_BASELINE_TAG="v10"
MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"

# shellcheck source=lib/migrator-core.sh disable=SC1091
. "$PACK_ROOT/scripts/lib/migrator-core.sh"

if ! declare -F migrator_skill_rename >/dev/null; then
    printf 'FATAL: migrator_skill_rename not defined after sourcing migrator-core.sh\n' >&2
    exit 2
fi
if ! declare -F migrator_skill_split >/dev/null; then
    printf 'FATAL: migrator_skill_split not defined after sourcing migrator-core.sh\n' >&2
    exit 2
fi

# ────────────────────────────────────────────────────────────────────────
# G1 — Golden-snapshot regression for v10→v11 S5b
# ────────────────────────────────────────────────────────────────────────
#
# Fixture-of-record: test-fixtures/v10-realistic-ot. The fixture's
# CLAUDE/AGENTS/GEMINI plus docs/pack/PLATFORM-SKILLS.md carry the same
# `python-architecture` references the BD-035 S5b helper was designed to
# rewrite. The four golden sha256s below were captured from the
# pre-extraction inline implementation against this same fixture (during
# BD-147 development); the test asserts the post-extraction helper
# produces byte-identical files + advisory.
#
# When the fixture content legitimately changes, regenerate the goldens
# (the procedure is documented in IMPLEMENTATION-REPORT-BD-147.md
# §"Golden snapshot — regeneration recipe") and update this table in
# the same commit.

echo
echo "=== G1: golden-snapshot regression for v10→v11 S5b helper ==="

# BD-163: declare G1's fixture precondition explicitly. Fails fast with
# an actionable error if the gitignored build artifact is missing
# (instead of the prior silent `cp: cannot stat ...` failure).
require_fixture "v10-realistic-ot"

G1_DIR="$FIXTURE_BASE/g1"
mkdir -p "$G1_DIR"
cp -R "$PACK_ROOT/test-fixtures/v10-realistic-ot" "$G1_DIR/project"
mkdir -p "$G1_DIR/project/.pack-migrate-v10-to-v11"

# Extract the (rewritten) S5b helper from the migrator. It is now a thin
# wrapper around migrator_skill_rename; we still test it via this
# extraction pattern so we exercise the full call site, not the library
# in isolation.
HELPER_TMP="$(mktemp -t bd147-helper.XXXXXX.sh)"
awk '
    /^_v10_to_v11_rename_python_architecture_refs\(\) \{/ { capture = 1 }
    capture { print }
    capture && /^\}$/ { capture = 0 }
' "$PACK_ROOT/scripts/migrate-v10-to-v11.sh" > "$HELPER_TMP"
if ! grep -q '^_v10_to_v11_rename_python_architecture_refs()' "$HELPER_TMP"; then
    printf 'FATAL: could not extract S5b helper from migrate-v10-to-v11.sh\n' >&2
    rm -f "$HELPER_TMP"
    exit 2
fi
# shellcheck source=/dev/null
. "$HELPER_TMP"
rm -f "$HELPER_TMP"

_MIGRATOR_TARGET="$G1_DIR/project"
_MIGRATOR_STATE_DIR="$G1_DIR/project/.pack-migrate-v10-to-v11"
_v10_to_v11_rename_python_architecture_refs >"$G1_DIR/stdout.log" 2>&1 \
    || { fail "G1 helper exited non-zero"; cat "$G1_DIR/stdout.log" >&2; }

# Golden sha256s — captured 2026-05-12 from the pre-BD-147 inline helper
# against the v10-realistic-ot fixture at HEAD. If you legitimately
# change the fixture content (or the helper's transformations), follow
# the regeneration recipe in IMPLEMENTATION-REPORT-BD-147.md.
#
# macOS bash 3.2 has no associative arrays — encode goldens as a
# newline-separated `<sha>  <relpath>` table and look up via grep.
G1_GOLDEN_TABLE='2372280f9674727cdd205103299d1dd0e2303a4dc899e190da2c3df4720a339a  CLAUDE.md
25341e813f44de7c674c77615d6acf27f967108535c3478fab205fb7161958bc  AGENTS.md
34a71464b16faadaa7a1b97356728b5506e9ec73275b03c092f3e2e0afb138f4  GEMINI.md
8809830faed34a213347a3cda1c49d1cfe14b09972d6dc9eee69e885f0bec182  docs/pack/PLATFORM-SKILLS.md
80b5018cba33f5dd2349d1ca3dad35162ae2780ecb95d81755dc46c5bca7f011  .pack-migrate-v10-to-v11/python-architecture-rename.advisory'

for rel in "CLAUDE.md" "AGENTS.md" "GEMINI.md" \
           "docs/pack/PLATFORM-SKILLS.md" \
           ".pack-migrate-v10-to-v11/python-architecture-rename.advisory"; do
    f="$G1_DIR/project/$rel"
    if [[ ! -f "$f" ]]; then
        fail "G1 expected post-helper file present: $rel"
        continue
    fi
    expected=$(printf '%s\n' "$G1_GOLDEN_TABLE" \
        | awk -v r="$rel" '$2 == r { print $1; exit }')
    actual="$(shasum -a 256 "$f" | awk '{print $1}')"
    assert_eq "G1 golden sha256 $rel" "$expected" "$actual"
done

# ────────────────────────────────────────────────────────────────────────
# G2 — migrator_skill_rename SIMPLE-mode
# ────────────────────────────────────────────────────────────────────────
#
# Synthetic fixture: a single project file containing one bare-token hit,
# one substring hit (token-boundary check), and one already-renamed line.
# Exercises the unconditional simple-rename code path.

echo
echo "=== G2: migrator_skill_rename SIMPLE mode ==="

G2_DIR="$FIXTURE_BASE/g2"
mkdir -p "$G2_DIR/project/docs/pack" "$G2_DIR/project/.pack-migrate-v10-to-v11"
cat > "$G2_DIR/project/docs/pack/PLATFORM-SKILLS.md" <<'EOF'
# Synthetic file
- Loads foo-bar via the standard predicate.
- Do NOT touch foo-bar-extra (substring; longer hyphen identifier).
- Do NOT touch extra-foo-bar (substring; leading hyphen identifier).
- Already-renamed: baz-quux (untouched).
EOF
# Override the file list — the synthetic fixture only has one file.
export MIGRATOR_SKILLS_FILES='docs/pack/PLATFORM-SKILLS.md'
unset MIGRATOR_SKILLS_SPLIT_TO_SERVER MIGRATOR_SKILLS_SPLIT_TO_DATA

_MIGRATOR_TARGET="$G2_DIR/project"
_MIGRATOR_STATE_DIR="$G2_DIR/project/.pack-migrate-v10-to-v11"

migrator_skill_rename "foo-bar" "baz-quux" >"$G2_DIR/stdout.log" 2>&1 \
    || { fail "G2 rename exited non-zero"; cat "$G2_DIR/stdout.log" >&2; }

# G2.a — bare-token hit got rewritten
if grep -q 'Loads baz-quux via the standard predicate' \
        "$G2_DIR/project/docs/pack/PLATFORM-SKILLS.md"; then
    pass "G2.a bare-token rewrite (foo-bar → baz-quux)"
else
    fail "G2.a bare-token rewrite did not happen"
fi
# G2.b — substring `foo-bar-extra` left intact
if grep -q 'foo-bar-extra' \
        "$G2_DIR/project/docs/pack/PLATFORM-SKILLS.md"; then
    pass "G2.b substring foo-bar-extra preserved (token-boundary correctness)"
else
    fail "G2.b substring foo-bar-extra got incorrectly rewritten" \
         "(line preserved)" "(line gone)"
fi
# G2.c — substring `extra-foo-bar` left intact
if grep -q 'extra-foo-bar' \
        "$G2_DIR/project/docs/pack/PLATFORM-SKILLS.md"; then
    pass "G2.c substring extra-foo-bar preserved"
else
    fail "G2.c substring extra-foo-bar got incorrectly rewritten"
fi
# G2.d — already-renamed line untouched (no double-rewrite)
if grep -q 'Already-renamed: baz-quux (untouched)' \
        "$G2_DIR/project/docs/pack/PLATFORM-SKILLS.md"; then
    pass "G2.d already-renamed line preserved"
else
    fail "G2.d already-renamed line got mangled"
fi

# G2.e — idempotent re-run produces no further change
SHA_AFTER_RUN_1="$(shasum -a 256 \
    "$G2_DIR/project/docs/pack/PLATFORM-SKILLS.md" | awk '{print $1}')"
migrator_skill_rename "foo-bar" "baz-quux" >>"$G2_DIR/stdout.log" 2>&1 || true
SHA_AFTER_RUN_2="$(shasum -a 256 \
    "$G2_DIR/project/docs/pack/PLATFORM-SKILLS.md" | awk '{print $1}')"
assert_eq "G2.e idempotent re-run preserves file" \
    "$SHA_AFTER_RUN_1" "$SHA_AFTER_RUN_2"

# G2.f — no advisory written (every hit was unambiguous)
if [[ -f "$G2_DIR/project/.pack-migrate-v10-to-v11/foo-bar-rename.advisory" ]]; then
    fail "G2.f advisory written for clean rename" "(absent)" "(present)"
else
    pass "G2.f no advisory written for clean rename"
fi

unset MIGRATOR_SKILLS_FILES

# ────────────────────────────────────────────────────────────────────────
# G3 — migrator_skill_rename SPLIT-mode + migrator_skill_split smoke
# ────────────────────────────────────────────────────────────────────────

echo
echo "=== G3: migrator_skill_rename SPLIT mode + migrator_skill_split ==="

G3_DIR="$FIXTURE_BASE/g3"
mkdir -p "$G3_DIR/project/docs/pack" "$G3_DIR/project/.pack-migrate-v10-to-v11"
cat > "$G3_DIR/project/docs/pack/PLATFORM-SKILLS.md" <<'EOF'
- Server side: python-architecture, python-server-architecture coexist.
- Data side: python-architecture, python-data-architecture coexist.
- Server signal: python-architecture in a line mentioning grpc-patterns.
- Data signal: python-architecture in a line mentioning the repository pattern.
- Ambiguous: standalone python-architecture mention with no other tokens.
EOF
export MIGRATOR_SKILLS_FILES='docs/pack/PLATFORM-SKILLS.md'

_MIGRATOR_TARGET="$G3_DIR/project"
_MIGRATOR_STATE_DIR="$G3_DIR/project/.pack-migrate-v10-to-v11"

ADV="$G3_DIR/project/.pack-migrate-v10-to-v11/python-architecture-rename.advisory"

MIGRATOR_SKILLS_SPLIT_TO_SERVER="python-server-architecture" \
MIGRATOR_SKILLS_SPLIT_TO_DATA="python-data-architecture" \
    migrator_skill_rename "python-architecture" "python-server-architecture" "$ADV" \
        >"$G3_DIR/stdout.log" 2>&1 \
    || { fail "G3 split exited non-zero"; cat "$G3_DIR/stdout.log" >&2; }

# G3.a — line with post-split server token rewrites to server
if grep -q 'Server side: python-server-architecture, python-server-architecture coexist' \
        "$G3_DIR/project/docs/pack/PLATFORM-SKILLS.md"; then
    pass "G3.a R1 (post-split server-token line) rewrites to server"
else
    fail "G3.a R1 disambiguation failed" \
         "Server side: python-server-architecture, python-server-architecture coexist." \
         "$(grep '^- Server side' "$G3_DIR/project/docs/pack/PLATFORM-SKILLS.md")"
fi
# G3.b — line with post-split data token rewrites to data
if grep -q 'Data side: python-data-architecture, python-data-architecture coexist' \
        "$G3_DIR/project/docs/pack/PLATFORM-SKILLS.md"; then
    pass "G3.b R2 (post-split data-token line) rewrites to data"
else
    fail "G3.b R2 disambiguation failed" \
         "Data side: python-data-architecture, python-data-architecture coexist." \
         "$(grep '^- Data side' "$G3_DIR/project/docs/pack/PLATFORM-SKILLS.md")"
fi
# G3.c — server-tier signal (grpc-patterns) routes to server
if grep -q 'Server signal: python-server-architecture in a line mentioning grpc-patterns' \
        "$G3_DIR/project/docs/pack/PLATFORM-SKILLS.md"; then
    pass "G3.c R3 (server signal) rewrites to server"
else
    fail "G3.c R3 disambiguation failed" \
         "Server signal: python-server-architecture in a line mentioning grpc-patterns." \
         "$(grep '^- Server signal' "$G3_DIR/project/docs/pack/PLATFORM-SKILLS.md")"
fi
# G3.d — data-tier signal (repository) routes to data
if grep -q 'Data signal: python-data-architecture in a line mentioning the repository pattern' \
        "$G3_DIR/project/docs/pack/PLATFORM-SKILLS.md"; then
    pass "G3.d R4 (data signal) rewrites to data"
else
    fail "G3.d R4 disambiguation failed" \
         "Data signal: python-data-architecture in a line mentioning the repository pattern." \
         "$(grep '^- Data signal' "$G3_DIR/project/docs/pack/PLATFORM-SKILLS.md")"
fi
# G3.e — ambiguous line untouched
if grep -q '^- Ambiguous: standalone python-architecture mention with no other tokens.' \
        "$G3_DIR/project/docs/pack/PLATFORM-SKILLS.md"; then
    pass "G3.e R5 (ambiguous) line preserved"
else
    fail "G3.e R5 ambiguous line was incorrectly rewritten"
fi
# G3.f — advisory exists with the BD-035 preamble + 1 entry
if [[ -f "$ADV" ]]; then
    if head -1 "$ADV" | grep -q '^# python-architecture skill-rename advisory (BD-035 split)$'; then
        pass "G3.f advisory uses BD-035-byte-equivalent preamble"
    else
        fail "G3.f advisory preamble drifted from BD-035"
    fi
    entry_count=$(grep -cE '^docs/pack/PLATFORM-SKILLS\.md:[0-9]+:' "$ADV" || true)
    assert_eq "G3.f advisory records exactly 1 ambiguous entry" "1" "$entry_count"
else
    fail "G3.f advisory missing"
fi

unset MIGRATOR_SKILLS_SPLIT_TO_SERVER MIGRATOR_SKILLS_SPLIT_TO_DATA MIGRATOR_SKILLS_FILES

# G3.g — migrator_skill_split forward-declared wrapper smoke check.
# Uses a fresh fixture so the prior split state does not contaminate.
G3G_DIR="$FIXTURE_BASE/g3g"
mkdir -p "$G3G_DIR/project/docs/pack" "$G3G_DIR/project/.pack-migrate-v10-to-v11"
cat > "$G3G_DIR/project/docs/pack/PLATFORM-SKILLS.md" <<'EOF'
- Server signal: python-architecture in a line mentioning grpc-patterns.
EOF
export MIGRATOR_SKILLS_FILES='docs/pack/PLATFORM-SKILLS.md'
_MIGRATOR_TARGET="$G3G_DIR/project"
_MIGRATOR_STATE_DIR="$G3G_DIR/project/.pack-migrate-v10-to-v11"

migrator_skill_split "python-architecture" \
    "python-server-architecture" "python-data-architecture" \
    "$G3G_DIR/project/.pack-migrate-v10-to-v11/python-architecture-rename.advisory" \
    >"$G3G_DIR/stdout.log" 2>&1 \
    || { fail "G3.g migrator_skill_split exited non-zero"; cat "$G3G_DIR/stdout.log" >&2; }

if grep -q 'Server signal: python-server-architecture in a line mentioning grpc-patterns' \
        "$G3G_DIR/project/docs/pack/PLATFORM-SKILLS.md"; then
    pass "G3.g migrator_skill_split wrapper applies split rules"
else
    fail "G3.g migrator_skill_split wrapper did not rewrite the server-signal line" \
         "Server signal: python-server-architecture in a line mentioning grpc-patterns." \
         "$(grep '^- Server signal' "$G3G_DIR/project/docs/pack/PLATFORM-SKILLS.md")"
fi

unset MIGRATOR_SKILLS_FILES

# ── Summary ──────────────────────────────────────────────────────────────
echo
echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
