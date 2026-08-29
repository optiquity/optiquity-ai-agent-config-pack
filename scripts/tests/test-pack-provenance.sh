#!/usr/bin/env bash
# pack-internal: true  (CI test runner; not a user-facing verb)
# scripts/tests/test-pack-provenance.sh — T-PROBE-BOTH-WAYS: unit tests for the
# pack-provenance probe and the baseline-reachability gate
# (scripts/lib/pack-provenance.sh).
#
# The probe decides whether a file installed in a client project is one the pack
# itself authored. A wrong answer in either direction is expensive:
#   * a false POSITIVE overwrites real client work without a sidecar;
#   * a false NEGATIVE spuriously accuses the client of customising a file.
# Every leg below therefore asserts a DIRECTION, not merely a non-crash.
#
# LEGS
#   L1 positive       the v10 bytes at the pack SOURCE path -> rc 0 + the v10 blob sha
#   L2 negative       the same bytes plus one appended line -> rc 1 (NOT-FOUND),
#                     and rc 1 is distinct from the rc 2 error channel
#   L3 mapped-key     the CLIENT relpath is not a key: `docs/pack/METHODOLOGY.md`
#                     -> NOT-FOUND for the very bytes that match under
#                     `supporting-docs/METHODOLOGY.md`. Both directions asserted.
#                     Forward-armed: once the install map ships
#                     `install_map_source_for_dest`, the resolution itself is
#                     asserted end to end.
#   L4 --no-filters   a CRLF-mangled copy must NOT match, INCLUDING under a
#                     client `core.autocrlf=input`. Carries the counter-control
#                     proving the flag is what prevents the false positive.
#   L5 gate NEGATIVE  an anchor that does not resolve -> rc != 0, and the notice
#                     carries the shipped `git fetch origin v10:v10` remediation.
#                     A pack path that does not exist takes the USAGE channel
#                     (rc 2) instead, distinct from that verdict, and emits no
#                     remediation pointing into the missing directory.
#   L6 gate POSITIVE  the real anchor -> rc 0. Without this leg an always-fail
#                     stub passes every other leg while silently making the
#                     whole probe inert.
#   L7 reachability   read-only proof that the gate must test REACHABILITY and
#                     not shallowness, and that the index must walk `--all`
#   L8 budget         the index build stays inside its runtime bound, and is
#                     built ONCE per run rather than once per probed file
#   L9 memo scope     the memoised index never answers for a different pack
#
# This test creates, clones, and mutates NO repository and NO ref. It reads the
# pack's own object store, which already carries the baseline tag as a CI
# dependency.
#
# Usage:    bash scripts/tests/test-pack-provenance.sh
# Exit 0 on all pass; exit 1 on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIB_DIR="$REPO_ROOT/scripts/lib"

# BD-276: portable full-template mktemp (never `mktemp -d -t prefix.XXXXXX`,
# which leaves a literal XXXXXX on BSD).
WORK="$(mktemp -d "${TMPDIR:-/tmp}/bd293-provenance.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

passes=0
fails=0
pass() { echo "  pass: $1"; passes=$((passes + 1)); }
fail() {
    echo "  FAIL: $1"
    [[ -n "${2:-}" ]] && printf '    expected: %s\n' "$2"
    [[ -n "${3:-}" ]] && printf '    actual:   %s\n' "$3"
    fails=$((fails + 1))
}
assert_eq() { if [[ "$2" == "$3" ]]; then pass "$1"; else fail "$1" "$2" "$3"; fi; }

# ── Preconditions ─────────────────────────────────────────────────────────────

# shellcheck disable=SC1091
source "$LIB_DIR/pack-provenance.sh"

for fn in pack_provenance_init pack_provenance_baseline_reachable \
          pack_provenance_is_pack_authored; do
    if ! declare -F "$fn" >/dev/null 2>&1; then
        echo "FATAL: $fn not sourced from pack-provenance.sh"
        exit 1
    fi
done

BASELINE_REF="${PACK_PROVENANCE_BASELINE_REF:-v10}"
PACK_SRC="supporting-docs/METHODOLOGY.md"
CLIENT_REL="docs/pack/METHODOLOGY.md"

if ! BASELINE_BLOB=$(git -C "$REPO_ROOT" rev-parse --verify --quiet \
                         "${BASELINE_REF}:${PACK_SRC}"); then
    echo "FATAL: baseline blob ${BASELINE_REF}:${PACK_SRC} does not resolve in $REPO_ROOT."
    echo "       This test consumes the baseline tag, as ten committed tests already do."
    echo "       Recover it with: git fetch origin v10:v10"
    exit 1
fi

PACK="$REPO_ROOT"
export PACK

echo "== pack-provenance probe =="
echo "  pack:          $REPO_ROOT"
echo "  baseline ref:  $BASELINE_REF"
echo "  baseline blob: $BASELINE_BLOB  ($PACK_SRC)"

# ── L8 budget — measured on the FIRST build, before anything memoises it ──────
#
# The bound catches an order-of-magnitude regression (a per-file walk over a
# ~240-path dispatch set would cost tens of seconds), not a few ms of jitter.
BUDGET_MS=2000
_t0=$(python3 -c 'import time; print(time.time())')
pack_provenance_init "$REPO_ROOT"
init_rc=$?
_t1=$(python3 -c 'import time; print(time.time())')
BUILD_MS=$(python3 -c "print(round(($_t1 - $_t0) * 1000, 1))")

echo
echo "-- L8 index build budget --"
assert_eq "L8a pack_provenance_init returns rc 0" "0" "$init_rc"
echo "  measured index build: ${BUILD_MS} ms (bound ${BUDGET_MS} ms)"
if python3 -c "import sys; sys.exit(0 if $BUILD_MS < $BUDGET_MS else 1)"; then
    pass "L8b index build within ${BUDGET_MS} ms budget"
else
    fail "L8b index build within ${BUDGET_MS} ms budget" "< ${BUDGET_MS} ms" "${BUILD_MS} ms"
fi

# ── Fixtures ─────────────────────────────────────────────────────────────────
git -C "$REPO_ROOT" show "${BASELINE_REF}:${PACK_SRC}" > "$WORK/pristine.md"
cp "$WORK/pristine.md" "$WORK/customized.md"
printf '\nA line the client added.\n' >> "$WORK/customized.md"
awk '{ printf "%s\r\n", $0 }' "$WORK/pristine.md" > "$WORK/crlf.md"

# L8c — the index must be built ONCE per run, not once per probed file. The
# index is memoised in the parent shell, so probes evaluated inside a command
# substitution inherit it instead of re-walking the object store.
#
# The bound is self-calibrating: it is a multiple of THIS machine's measured
# build, so it scales with machine speed instead of pinning wall-clock numbers.
# A memoised run costs ~2x the build for 10 probes; an un-memoised one costs
# ~11x. 4x separates them with wide margin on both sides.
MEMO_PROBES=10
MEMO_BOUND_MS=$(python3 -c "print(round(max(4 * $BUILD_MS, 400.0), 1))")
_t0=$(python3 -c 'import time; print(time.time())')
_i=0
while [ "$_i" -lt "$MEMO_PROBES" ]; do
    pack_provenance_is_pack_authored "$PACK_SRC" "$WORK/pristine.md" >/dev/null
    _i=$((_i + 1))
done
_t1=$(python3 -c 'import time; print(time.time())')
MEMO_MS=$(python3 -c "print(round(($_t1 - $_t0) * 1000, 1))")
echo "  ${MEMO_PROBES} memoised probes: ${MEMO_MS} ms (bound ${MEMO_BOUND_MS} ms)"
if python3 -c "import sys; sys.exit(0 if $MEMO_MS < $MEMO_BOUND_MS else 1)"; then
    pass "L8c the index is memoised across probes (one walk per run, not per file)"
else
    fail "L8c the index is memoised across probes (one walk per run, not per file)" \
        "< ${MEMO_BOUND_MS} ms for ${MEMO_PROBES} probes" "${MEMO_MS} ms"
fi

# ── L1 positive ──────────────────────────────────────────────────────────────
echo
echo "-- L1 positive: pack-authored bytes at the pack SOURCE path --"
out=$(pack_provenance_is_pack_authored "$PACK_SRC" "$WORK/pristine.md"); rc=$?
assert_eq "L1a rc 0 for a blob the pack has shipped at this path" "0" "$rc"
assert_eq "L1b stdout is the matching blob sha" "$BASELINE_BLOB" "$out"

# ── L2 negative ──────────────────────────────────────────────────────────────
echo
echo "-- L2 negative: one appended client line must break the match --"
out=$(pack_provenance_is_pack_authored "$PACK_SRC" "$WORK/customized.md"); rc=$?
assert_eq "L2a rc 1 (NOT-FOUND) for customised bytes" "1" "$rc"
assert_eq "L2b no sha is printed on NOT-FOUND" "" "$out"

# A NOT-FOUND verdict and a broken probe must never look alike to a caller.
out=$(pack_provenance_is_pack_authored "$PACK_SRC" "$WORK/does-not-exist.md" 2>/dev/null); rc=$?
assert_eq "L2c rc 2 (error) is distinct from rc 1 (NOT-FOUND)" "2" "$rc"

# ── L3 mapped-key ────────────────────────────────────────────────────────────
echo
echo "-- L3 mapped-key: the client relpath is not a key in the index --"
out=$(pack_provenance_is_pack_authored "$CLIENT_REL" "$WORK/pristine.md"); rc=$?
assert_eq "L3a client relpath key -> NOT-FOUND for pack-authored bytes" "1" "$rc"
out=$(pack_provenance_is_pack_authored "$PACK_SRC" "$WORK/pristine.md"); rc=$?
assert_eq "L3b the SAME bytes under the pack source key -> rc 0" "0" "$rc"

# Forward-armed: the dest -> source resolution itself, once the install map
# ships it. Present-but-broken is a hard failure; absent is an explicit notice,
# never a silent skip.
if [[ -f "$LIB_DIR/install-map.sh" ]]; then
    # shellcheck disable=SC1091
    source "$LIB_DIR/install-map.sh"
    if declare -F install_map_source_for_dest >/dev/null 2>&1; then
        resolved=$(install_map_source_for_dest "$CLIENT_REL")
        assert_eq "L3c install_map_source_for_dest resolves the dest to the pack source" \
            "$PACK_SRC" "$resolved"
        out=$(pack_provenance_is_pack_authored "$resolved" "$WORK/pristine.md"); rc=$?
        assert_eq "L3d probing the RESOLVED key -> rc 0" "0" "$rc"
    else
        fail "L3c install-map.sh is present but does not define install_map_source_for_dest" \
            "install_map_source_for_dest defined" "not defined"
    fi
else
    echo "  note: L3c/L3d inactive — scripts/lib/install-map.sh does not exist yet."
    echo "        L3a/L3b already assert both directions of the mapped-key trap;"
    echo "        L3c/L3d arm themselves the moment the install map ships."
fi

# ── L4 --no-filters ──────────────────────────────────────────────────────────
echo
echo "-- L4 --no-filters: a client's core.autocrlf must not flip the verdict --"

# Counter-control: WITHOUT --no-filters, a client with core.autocrlf=input makes
# a CRLF-mangled file hash to the pack's own blob. This is the false positive
# the flag exists to prevent; if this assertion ever stops holding, L4b has
# stopped proving anything.
filtered_sha=$(printf '%s\n' "$WORK/crlf.md" \
    | GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.autocrlf GIT_CONFIG_VALUE_0=input \
      git -C "$REPO_ROOT" hash-object --stdin-paths 2>/dev/null)
assert_eq "L4a counter-control: without --no-filters the CRLF copy hashes to the pack blob" \
    "$BASELINE_BLOB" "$filtered_sha"

out=$(
    export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.autocrlf GIT_CONFIG_VALUE_0=input
    pack_provenance_is_pack_authored "$PACK_SRC" "$WORK/crlf.md"
); rc=$?
assert_eq "L4b the probe still reports NOT-FOUND for the CRLF copy" "1" "$rc"
assert_eq "L4c no sha is printed for the CRLF copy" "" "$out"

# ── L5 gate NEGATIVE ─────────────────────────────────────────────────────────
echo
echo "-- L5 gate NEGATIVE: an unresolvable anchor --"
bogus="pack-provenance-no-such-ref-$$"
(
    PACK_PROVENANCE_BASELINE_REF="$bogus"
    export PACK_PROVENANCE_BASELINE_REF
    pack_provenance_baseline_reachable "$REPO_ROOT"
) >"$WORK/gate.out" 2>"$WORK/gate.err"
rc=$?
anchor_rc=$rc          # the VERDICT channel, kept for the L5e distinctness check
if [[ "$rc" -ne 0 ]]; then
    pass "L5a unresolvable anchor -> rc != 0 (got $rc)"
else
    fail "L5a unresolvable anchor -> rc != 0" "non-zero" "$rc"
fi
if grep -Fq 'git fetch origin v10:v10' "$WORK/gate.err"; then
    pass "L5b the notice carries the shipped remediation"
else
    fail "L5b the notice carries the shipped remediation" \
        "stderr contains 'git fetch origin v10:v10'" "$(tr '\n' '|' < "$WORK/gate.err")"
fi
if grep -Fq "$bogus" "$WORK/gate.err"; then
    pass "L5c the notice names the anchor that failed to resolve"
else
    fail "L5c the notice names the anchor that failed to resolve" \
        "stderr contains '$bogus'" "$(tr '\n' '|' < "$WORK/gate.err")"
fi

# L5d/e/f — a pack path that does not exist is a BROKEN PROBE, not a baseline
# verdict. The library declares rc 1 and rc 2 deliberately distinct, and the two
# gate/init siblings must agree about the same input: if the gate answered rc 1
# here, a caller would route "you gave me a bad path" into the same branch as
# "your clone is missing the baseline", and the notice would tell the operator
# to run `git fetch` inside a directory that does not exist.
missing_pack="$WORK/no-such-pack-dir"
pack_provenance_baseline_reachable "$missing_pack" \
    >"$WORK/gate-missing.out" 2>"$WORK/gate-missing.err"
rc=$?
assert_eq "L5d a non-existent pack path -> rc 2 (the usage channel)" "2" "$rc"

if [[ "$rc" -ne "$anchor_rc" ]]; then
    pass "L5e the usage rc ($rc) is distinct from the anchor verdict rc ($anchor_rc)"
else
    fail "L5e the usage rc is distinct from the anchor verdict rc" \
        "two different codes" "both rc $rc"
fi

if grep -Fq 'git fetch origin v10:v10' "$WORK/gate-missing.err"; then
    fail "L5f a usage error does not emit the baseline remediation" \
        "no remediation (the pack directory does not exist)" \
        "$(tr '\n' '|' < "$WORK/gate-missing.err")"
else
    pass "L5f a usage error does not point the operator into a missing directory"
fi

# ── L6 gate POSITIVE ─────────────────────────────────────────────────────────
echo
echo "-- L6 gate POSITIVE: the real anchor --"
pack_provenance_baseline_reachable "$REPO_ROOT" >"$WORK/gate2.out" 2>"$WORK/gate2.err"
rc=$?
assert_eq "L6a the real baseline anchor -> rc 0 (an always-fail gate makes the probe inert)" \
    "0" "$rc"
assert_eq "L6b a reachable baseline emits no notice" "" "$(cat "$WORK/gate2.err")"

# ── L7 reachability, not shallowness ─────────────────────────────────────────
#
# Read-only proof of the state the gate exists for: the baseline hangs off
# refs/tags alone, a tags-less clone would lose its blobs, and a shallowness
# test cannot see that.
echo
echo "-- L7 the gate must test reachability, not shallowness --"

if git -C "$REPO_ROOT" merge-base --is-ancestor "$BASELINE_REF" HEAD 2>/dev/null; then
    fail "L7a the baseline is NOT an ancestor of HEAD" \
        "not an ancestor (so it is reachable only via its own ref)" "is an ancestor"
else
    pass "L7a the baseline is NOT an ancestor of HEAD"
fi

assert_eq "L7b the repo is NOT shallow, so a shallowness test cannot detect the tags-less state" \
    "false" "$(git -C "$REPO_ROOT" rev-parse --is-shallow-repository 2>/dev/null)"

# The index must walk --all: a HEAD-only walk loses exactly the blobs the probe
# is for. This is the tags-less clone's object graph, observed read-only.
git -C "$REPO_ROOT" rev-list HEAD --objects --full-history \
    -- project-template supporting-docs 2>/dev/null > "$WORK/head-walk.txt"
if grep -q "^${BASELINE_BLOB} " "$WORK/head-walk.txt"; then
    fail "L7c a HEAD-only walk loses the baseline blob" \
        "absent from the HEAD-only walk" "present"
else
    pass "L7c a HEAD-only walk loses the baseline blob (--all is load-bearing)"
fi
out=$(pack_provenance_is_pack_authored "$PACK_SRC" "$WORK/pristine.md"); rc=$?
assert_eq "L7d the --all index still finds it" "0" "$rc"

# ── L9 the memoised index never answers for a different pack ─────────────────
#
# The index is memoised for speed, but it is a property of ONE pack. If a
# probe could answer from an index built for a different pack it would report
# pack-authorship the current pack never granted — the same false positive as
# L4, arriving by a different route.
echo
echo "-- L9 the memo follows the pack, it does not outlive it --"
mkdir -p "$WORK/other-pack"
rc=0
out=$(PACK="$WORK/other-pack" \
      pack_provenance_is_pack_authored "$PACK_SRC" "$WORK/pristine.md" 2>/dev/null) || rc=$?
if [[ "$rc" -ne 0 ]]; then
    pass "L9a a different \$PACK does not answer from the memoised index (rc $rc)"
else
    fail "L9a a different \$PACK does not answer from the memoised index" \
        "non-zero" "rc 0, sha $out"
fi
out=$(pack_provenance_is_pack_authored "$PACK_SRC" "$WORK/pristine.md"); rc=$?
assert_eq "L9b the original pack still answers correctly afterwards" "0" "$rc"

# ── Summary ──────────────────────────────────────────────────────────────────
echo
echo "passes: $passes   failures: $fails"
[[ "$fails" -eq 0 ]] || exit 1
exit 0
