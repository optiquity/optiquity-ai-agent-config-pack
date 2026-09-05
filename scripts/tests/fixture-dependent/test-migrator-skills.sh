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
#        from the pre-extraction inline implementation. This IS the
#        byte-identity mitigation for that extraction refactor: the
#        helper was lifted out of the adapter, so only a golden snapshot
#        proves the extraction changed no emitted byte.
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
# Usage:    bash scripts/tests/fixture-dependent/test-migrator-skills.sh
# Exit 0 on all pass; exit 1 on any failure.
#
# Per BD-147.
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
# scripts/tests/fixture-dependent/ → pack root is three levels up (BD-219
# location-based fixture cohesion).
PACK_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

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

FIXTURE_BASE="$(mktemp -d "${TMPDIR:-/tmp}/test-migrator-skills.XXXXXX")"
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
HELPER_TMP="$(mktemp "${TMPDIR:-/tmp}/bd147-helper.XXXXXX")"
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
# advisory golden regenerated 2026-06-18: the advisory preamble was
# de-leaked of its pack-internal BD-NNN token (client-facing output);
# the trinity + PLATFORM-SKILLS goldens are unaffected (no BD token in
# those transformed files).
#
# macOS bash 3.2 has no associative arrays — encode goldens as a
# newline-separated `<sha>  <relpath>` table and look up via grep.
G1_GOLDEN_TABLE='2372280f9674727cdd205103299d1dd0e2303a4dc899e190da2c3df4720a339a  CLAUDE.md
25341e813f44de7c674c77615d6acf27f967108535c3478fab205fb7161958bc  AGENTS.md
34a71464b16faadaa7a1b97356728b5506e9ec73275b03c092f3e2e0afb138f4  GEMINI.md
8809830faed34a213347a3cda1c49d1cfe14b09972d6dc9eee69e885f0bec182  docs/pack/PLATFORM-SKILLS.md
ef6a025af220070bc182a9db7542db3e0fdb508c612500e2caa2c83b24343cd6  .pack-migrate-v10-to-v11/python-architecture-rename.advisory'

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
# G3.f — advisory exists with the expected preamble + 1 entry
if [[ -f "$ADV" ]]; then
    if head -1 "$ADV" | grep -q '^# python-architecture skill-rename advisory (split)$'; then
        pass "G3.f advisory uses byte-equivalent preamble"
    else
        fail "G3.f advisory preamble drifted"
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

# ─────────────────────────────────────────────────────────────────────────
# G4 — migrator_retire_skill_dirs: the filesystem half of a retirement
# ─────────────────────────────────────────────────────────────────────────
#
# The retired set is DERIVED here exactly as the library derives it (v10
# tag pool minus tracked v11 pool) so the test names no skill; it asserts
# the set is non-empty and drives the API against a synthetic target whose
# three homes hold, for the first retired skill: a PRISTINE copy (v10
# blob) in .claude, an EDITED copy in .codex, and in .agents a directory
# holding ONLY a client symlink (no regular file — the shape a
# regular-files-only census would call pristine and delete). A shared
# v10∩v11 skill (c-language) is seeded in every home as the must-NOT-touch
# control.
echo "=== G4: migrator_retire_skill_dirs ==="

G4_DIR="$FIXTURE_BASE/g4"
mkdir -p "$G4_DIR"
G4_TARGET="$G4_DIR/project"
G4_STATE="$G4_TARGET/.pack-migrate-v10-to-v11"
mkdir -p "$G4_TARGET/.claude/skills" "$G4_TARGET/.codex/skills" "$G4_TARGET/.agents/skills"

g4_retired=$(comm -23 \
    <(git -C "$PACK_ROOT" ls-tree -r --name-only v10 -- project-template/skills/ \
        | sed -n 's#^project-template/skills/\([^/]*\)/SKILL\.md$#\1#p' | sort -u) \
    <(git -C "$PACK_ROOT" ls-files -- 'project-template/skills/*/SKILL.md' \
        | sed -n 's#^project-template/skills/\([^/]*\)/SKILL\.md$#\1#p' | sort -u))
g4_first=$(printf '%s\n' "$g4_retired" | head -1)
if [[ -n "$g4_first" ]]; then
    pass "G4.a retired set derived from v10-vs-v11 pool inventory is non-empty (first: $g4_first)"
else
    fail "G4.a retired set is EMPTY — nothing to drive the API against"
fi

for cli in .claude .codex .agents; do
    mkdir -p "$G4_TARGET/$cli/skills/c-language"
    git -C "$PACK_ROOT" show "v10:project-template/skills/c-language/SKILL.md" \
        > "$G4_TARGET/$cli/skills/c-language/SKILL.md"
done
mkdir -p "$G4_TARGET/.claude/skills/$g4_first" "$G4_TARGET/.codex/skills/$g4_first"
git -C "$PACK_ROOT" show "v10:project-template/skills/$g4_first/SKILL.md" \
    > "$G4_TARGET/.claude/skills/$g4_first/SKILL.md"
git -C "$PACK_ROOT" show "v10:project-template/skills/$g4_first/SKILL.md" \
    > "$G4_TARGET/.codex/skills/$g4_first/SKILL.md"
printf '\n<!-- project edit -->\n' >> "$G4_TARGET/.codex/skills/$g4_first/SKILL.md"
# .agents: the retired dir holds ONLY a client symlink — client content that
# a `-type f`-only census cannot see.
mkdir -p "$G4_TARGET/.agents/skills/$g4_first"
ln -s ../../../README.md "$G4_TARGET/.agents/skills/$g4_first/notes.md"

# Drive the API inside a subshell with the framework env the adapter
# supplies, plus an initialised customization-preserve state so _cp_record
# has a dispositions file to write.
(
    export _CP_PACK_ROOT="$PACK_ROOT"
    # shellcheck source=/dev/null
    . "$PACK_ROOT/scripts/lib/three-way.sh"
    # shellcheck source=/dev/null
    . "$PACK_ROOT/scripts/lib/customization-preserve.sh"
    _MIGRATOR_TARGET="$G4_TARGET"
    _MIGRATOR_STATE_DIR="$G4_STATE"
    customization_preserve_init "$G4_STATE" ".v10-customized"
    migrator_retire_skill_dirs .claude .codex .agents
) > "$G4_DIR/run1.log" 2>&1; g4_rc=$?
assert_eq "G4.b migrator_retire_skill_dirs rc=0" "0" "$g4_rc"

[[ ! -e "$G4_TARGET/.claude/skills/$g4_first" ]] \
    && pass "G4.c pristine retired dir removed from .claude" \
    || fail "G4.c pristine retired dir still present in .claude"
[[ ! -e "$G4_TARGET/.codex/skills/$g4_first" ]] \
    && pass "G4.d edited retired dir no longer in .codex" \
    || fail "G4.d edited retired dir still present in .codex"
g4_moved="$G4_STATE/retired-skills/.codex/skills/$g4_first/SKILL.md"
if [[ -f "$g4_moved" ]] && grep -q '<!-- project edit -->' "$g4_moved"; then
    pass "G4.e edited retired dir MOVED under the state dir with the project edit intact"
else
    fail "G4.e edited retired copy not preserved at $g4_moved"
fi
[[ ! -e "$G4_STATE/retired-skills/.claude" ]] \
    && pass "G4.f pristine copy was deleted, not parked (no .claude holding copy)" \
    || fail "G4.f pristine copy was parked although byte-identical to the v10 blob"
g4_link="$G4_STATE/retired-skills/.agents/skills/$g4_first/notes.md"
if [[ ! -e "$G4_TARGET/.agents/skills/$g4_first" && -L "$g4_link" ]]; then
    pass "G4.m symlink-only retired dir in .agents MOVED with the client symlink intact at the holding path, not deleted"
else
    fail "G4.m symlink-only retired dir in .agents" "moved; $g4_link is a symlink" \
         "still-present=$([[ -e "$G4_TARGET/.agents/skills/$g4_first" ]] && echo yes || echo no) holding-symlink=$([[ -L "$g4_link" ]] && echo yes || echo no)"
fi
for cli in .claude .codex .agents; do
    if cmp -s <(git -C "$PACK_ROOT" show "v10:project-template/skills/c-language/SKILL.md") \
              "$G4_TARGET/$cli/skills/c-language/SKILL.md"; then
        pass "G4.g control: shared v10∩v11 skill c-language untouched in $cli"
    else
        fail "G4.g control: c-language altered or removed in $cli"
    fi
done
g4_rows=$(awk -F'\t' -v s="$g4_first" '$1 == "removed-by-design" && index($3, "/skills/" s "/") { print $3 "|" $5 }' "$G4_STATE/dispositions.tsv")
if [[ "$g4_rows" == *".claude/skills/$g4_first/SKILL.md|-"* \
   && "$g4_rows" == *".codex/skills/$g4_first/SKILL.md|$g4_moved"* ]]; then
    pass "G4.h both removals recorded as removed-by-design (moved copy named in the sidecar column)"
else
    fail "G4.h dispositions rows missing or wrong" \
         ".claude/…|- and .codex/…|<moved path>" "$g4_rows"
fi
[[ "$g4_rows" == *".agents/skills/$g4_first/notes.md|$g4_link"* ]] \
    && pass "G4.n the symlink's removal is recorded removed-by-design with the holding path in the sidecar column" \
    || fail "G4.n symlink disposition row missing" ".agents/skills/$g4_first/notes.md|$g4_link" "$g4_rows"
if grep -q "retired skill dir removed: .claude/skills/$g4_first (pristine)" "$G4_DIR/run1.log" \
   && grep -q "retired skill dir moved: .codex/skills/$g4_first" "$G4_DIR/run1.log"; then
    pass "G4.i info lines name each retired directory and its outcome"
else
    fail "G4.i info lines missing" "" "$(cat "$G4_DIR/run1.log")"
fi

# Idempotent re-run: nothing left to do, rc 0, no new rows.
g4_rows_before=$(wc -l < "$G4_STATE/dispositions.tsv" | tr -d ' ')
(
    export _CP_PACK_ROOT="$PACK_ROOT"
    # shellcheck source=/dev/null
    . "$PACK_ROOT/scripts/lib/three-way.sh"
    # shellcheck source=/dev/null
    . "$PACK_ROOT/scripts/lib/customization-preserve.sh"
    _MIGRATOR_TARGET="$G4_TARGET"
    _MIGRATOR_STATE_DIR="$G4_STATE"
    _CP_DISPOSITIONS_FILE="$G4_STATE/dispositions.tsv"
    _CP_FINDINGS_COUNT=0
    migrator_retire_skill_dirs .claude .codex .agents
) > "$G4_DIR/run2.log" 2>&1; g4_rc2=$?
g4_rows_after=$(wc -l < "$G4_STATE/dispositions.tsv" | tr -d ' ')
[[ "$g4_rc2" -eq 0 && "$g4_rows_before" == "$g4_rows_after" ]] \
    && pass "G4.j second run is a no-op (rc 0, no new disposition rows)" \
    || fail "G4.j second run changed state" "rc=0 rows=$g4_rows_before" "rc=$g4_rc2 rows=$g4_rows_after"

# Contract guards: no homes / missing framework env → rc 2, nothing touched.
(
    _MIGRATOR_TARGET="$G4_TARGET"; _MIGRATOR_STATE_DIR="$G4_STATE"
    migrator_retire_skill_dirs
) >/dev/null 2>&1; g4_rc3=$?
assert_eq "G4.k no homes → rc 2" "2" "$g4_rc3"
(
    unset _MIGRATOR_TARGET _MIGRATOR_STATE_DIR
    migrator_retire_skill_dirs .claude
) >/dev/null 2>&1; g4_rc4=$?
assert_eq "G4.l framework env unset → rc 2" "2" "$g4_rc4"

# ─────────────────────────────────────────────────────────────────────────
# G4s — migrator_retire_skill_dirs: the retired path ITSELF is a symlink
# ─────────────────────────────────────────────────────────────────────────
#
# A client who de-duplicated one skill across homes leaves a relative link
# (`.codex/skills/x -> ../../.claude/skills/x`); one who keeps skills
# outside the tree leaves an absolute link. The pack ships no symlinks, so
# the link is client content: it is MOVED as the link (never read through,
# followed, or removed through), recorded as ONE well-formed
# removed-by-design row (path `<home>/skills/<name>`, holding path in the
# sidecar column), and no home is left holding a dangling link. Both visit
# orders are driven — the link visited AFTER its target was deleted
# (dangling at visit) and BEFORE (live at visit) — because `-d` follows a
# live link and skips a dangling one, and each order fails differently.
echo "=== G4s: migrator_retire_skill_dirs — symlinked retired path ==="

G4S_OUT="$FIXTURE_BASE/g4s-outside/$g4_first"
mkdir -p "$G4S_OUT"
git -C "$PACK_ROOT" show "v10:project-template/skills/$g4_first/SKILL.md" > "$G4S_OUT/SKILL.md"
printf 'outside marker\n' > "$G4S_OUT/marker.txt"
g4s_out_sum=$(cat "$G4S_OUT/SKILL.md" "$G4S_OUT/marker.txt" | cksum)

# (A) link visited AFTER its target: .claude real pristine, .codex -> .claude
#     (relative), .agents -> an ABSOLUTE path outside the target tree.
G4SA="$FIXTURE_BASE/g4s-a/project"
G4SA_STATE="$G4SA/.pack-migrate-v10-to-v11"
mkdir -p "$G4SA/.claude/skills/$g4_first" "$G4SA/.codex/skills" "$G4SA/.agents/skills"
git -C "$PACK_ROOT" show "v10:project-template/skills/$g4_first/SKILL.md" > "$G4SA/.claude/skills/$g4_first/SKILL.md"
ln -s "../../.claude/skills/$g4_first" "$G4SA/.codex/skills/$g4_first"
ln -s "$G4S_OUT" "$G4SA/.agents/skills/$g4_first"
[[ -L "$G4SA/.codex/skills/$g4_first" && -d "$G4SA/.codex/skills/$g4_first" && -L "$G4SA/.agents/skills/$g4_first" && -d "$G4SA/.agents/skills/$g4_first" ]] \
    && pass "G4s.a setup: .codex and .agents retired paths are LIVE symlinks (-L and -d) before the run" \
    || fail "G4s.a setup: link shapes not as intended"
(
    export _CP_PACK_ROOT="$PACK_ROOT"
    # shellcheck source=/dev/null
    . "$PACK_ROOT/scripts/lib/three-way.sh"
    # shellcheck source=/dev/null
    . "$PACK_ROOT/scripts/lib/customization-preserve.sh"
    _MIGRATOR_TARGET="$G4SA"
    _MIGRATOR_STATE_DIR="$G4SA_STATE"
    customization_preserve_init "$G4SA_STATE" ".v10-customized"
    migrator_retire_skill_dirs .claude .codex .agents
) > "$FIXTURE_BASE/g4s-a/run.log" 2>&1; g4s_rc=$?
assert_eq "G4s.b rc=0" "0" "$g4s_rc"
g4s_left=""
for cli in .claude .codex .agents; do
    [[ -e "$G4SA/$cli/skills/$g4_first" || -L "$G4SA/$cli/skills/$g4_first" ]] && g4s_left="$g4s_left $cli"
done
[[ -z "$g4s_left" ]] \
    && pass "G4s.c no home holds the retired path afterwards — not as a directory, not as a (dangling) link" \
    || fail "G4s.c retired path left in a home" "" "$g4s_left"
g4s_hold_c="$G4SA_STATE/retired-skills/.codex/skills/$g4_first"
if [[ -L "$g4s_hold_c" && "$(readlink "$g4s_hold_c")" == "../../.claude/skills/$g4_first" ]]; then
    pass "G4s.d .codex link (dangling at visit — .claude was deleted first) MOVED to the holding path AS THE LINK, target text preserved"
else
    fail "G4s.d .codex link not moved as a link" "symlink -> ../../.claude/skills/$g4_first" "islink=$([[ -L "$g4s_hold_c" ]] && echo yes || echo no) target=$(readlink "$g4s_hold_c" 2>/dev/null)"
fi
g4s_hold_a="$G4SA_STATE/retired-skills/.agents/skills/$g4_first"
if [[ -L "$g4s_hold_a" && "$(readlink "$g4s_hold_a")" == "$G4S_OUT" ]]; then
    pass "G4s.e .agents ABSOLUTE link to an outside dir MOVED as the link"
else
    fail "G4s.e .agents outside link not moved as a link" "symlink -> $G4S_OUT" "islink=$([[ -L "$g4s_hold_a" ]] && echo yes || echo no) target=$(readlink "$g4s_hold_a" 2>/dev/null)"
fi
[[ -f "$G4S_OUT/SKILL.md" && -f "$G4S_OUT/marker.txt" && "$(cat "$G4S_OUT/SKILL.md" "$G4S_OUT/marker.txt" | cksum)" == "$g4s_out_sum" ]] \
    && pass "G4s.f the outside target was never followed: both files intact, bytes unchanged" \
    || fail "G4s.f outside target altered or removed through the link"
g4s_rows=$(awk -F'\t' -v s="$g4_first" '$1 == "removed-by-design" && index($3, "/skills/" s) { print $3 "|" $5 }' "$G4SA_STATE/dispositions.tsv")
g4s_want=".claude/skills/$g4_first/SKILL.md|-
.codex/skills/$g4_first|$g4s_hold_c
.agents/skills/$g4_first|$g4s_hold_a"
if [[ "$g4s_rows" == "$g4s_want" ]]; then
    pass "G4s.g exactly three well-formed rows: the pristine file, and ONE row per link naming the link path and its holding path"
else
    fail "G4s.g disposition rows differ" "$g4s_want" "$g4s_rows"
fi
if grep -q "retired skill dir moved: .codex/skills/$g4_first (symlink)" "$FIXTURE_BASE/g4s-a/run.log" \
   && grep -q "retired skill dir moved: .agents/skills/$g4_first (symlink)" "$FIXTURE_BASE/g4s-a/run.log"; then
    pass "G4s.h info lines name each moved link"
else
    fail "G4s.h info lines missing" "" "$(cat "$FIXTURE_BASE/g4s-a/run.log")"
fi

# (B) link visited BEFORE its target: .claude -> .codex (relative, LIVE at
#     visit), .codex a real EDITED copy.
G4SB="$FIXTURE_BASE/g4s-b/project"
G4SB_STATE="$G4SB/.pack-migrate-v10-to-v11"
mkdir -p "$G4SB/.claude/skills" "$G4SB/.codex/skills/$g4_first" "$G4SB/.agents/skills"
git -C "$PACK_ROOT" show "v10:project-template/skills/$g4_first/SKILL.md" > "$G4SB/.codex/skills/$g4_first/SKILL.md"
printf '\n<!-- project edit -->\n' >> "$G4SB/.codex/skills/$g4_first/SKILL.md"
ln -s "../../.codex/skills/$g4_first" "$G4SB/.claude/skills/$g4_first"
(
    export _CP_PACK_ROOT="$PACK_ROOT"
    # shellcheck source=/dev/null
    . "$PACK_ROOT/scripts/lib/three-way.sh"
    # shellcheck source=/dev/null
    . "$PACK_ROOT/scripts/lib/customization-preserve.sh"
    _MIGRATOR_TARGET="$G4SB"
    _MIGRATOR_STATE_DIR="$G4SB_STATE"
    customization_preserve_init "$G4SB_STATE" ".v10-customized"
    migrator_retire_skill_dirs .claude .codex .agents
) > "$FIXTURE_BASE/g4s-b/run.log" 2>&1; g4s_rc2=$?
assert_eq "G4s.i (link first) rc=0" "0" "$g4s_rc2"
g4s_hold_b="$G4SB_STATE/retired-skills/.claude/skills/$g4_first"
if [[ ! -L "$G4SB/.claude/skills/$g4_first" && -L "$g4s_hold_b" && "$(readlink "$g4s_hold_b")" == "../../.codex/skills/$g4_first" ]]; then
    pass "G4s.j .claude link (LIVE at visit) moved as the link, not censused through"
else
    fail "G4s.j live link not moved as a link" "" "home-islink=$([[ -L "$G4SB/.claude/skills/$g4_first" ]] && echo yes || echo no) holding-islink=$([[ -L "$g4s_hold_b" ]] && echo yes || echo no)"
fi
g4s_rows2=$(awk -F'\t' -v s="$g4_first" '$1 == "removed-by-design" && index($3, "/skills/" s) { print $3 "|" $5 }' "$G4SB_STATE/dispositions.tsv")
g4s_want2=".claude/skills/$g4_first|$g4s_hold_b
.codex/skills/$g4_first/SKILL.md|$G4SB_STATE/retired-skills/.codex/skills/$g4_first/SKILL.md"
if [[ "$g4s_rows2" == "$g4s_want2" ]]; then
    pass "G4s.k rows well-formed when the link is visited first: link path is exactly .claude/skills/$g4_first (no absolute-path fragment), edited-copy row unchanged"
else
    fail "G4s.k disposition rows differ (link-first order)" "$g4s_want2" "$g4s_rows2"
fi

# ── Summary ──────────────────────────────────────────────────────────────
echo
echo "=== Results: $passes passed, $fails failed ==="
[[ $fails -eq 0 ]] && exit 0 || exit 1
