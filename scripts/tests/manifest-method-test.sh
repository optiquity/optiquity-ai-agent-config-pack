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
drift_check "the SoT itself EXCLUDED"              "scripts/lib/manifest-inputs.sh"        "exclude"
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
