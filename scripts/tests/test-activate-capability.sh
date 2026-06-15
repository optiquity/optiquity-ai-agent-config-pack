#!/usr/bin/env bash
# scripts/tests/test-activate-capability.sh — BD-200 behavioral tests for the
# project-side capability-ACTIVATION script
# (project-template/scripts/activate-capability.sh).
#
# This is the behavioral encoding-surface for activate-capability.sh: the
# validators (Check 43/37 leak gate, Check 22 verb resolution) assert the
# script's STATIC properties; this harness asserts its RUNTIME behavior.
#
# Test groups:
#   1. Fresh-clone activation walk — build a Swift-only project via
#      init-project.sh (pool populated by S5b; S9 removes the live-tree
#      Python files), clone it to a scratch dir with NO $PACK in env, run
#      `activate-capability.sh --add language:python`, and assert:
#        P0 passes with no $PACK; P5 re-materializes pyproject.toml +
#        server/ + the four *-python.sh FROM pack-capability-pool/; P8
#        emits a prompt with no external-clone tokens.
#   2. x--preserve-on-activate — drop a project-authored x--basename file at
#      a path P5 would otherwise write; assert it is PRESERVED + warned, and
#      that a non-x- resolved file IS (re)written.
#
# Scratch repos are self-provisioned under a /tmp mktemp dir and cleaned up;
# no real repo is ever used as a target.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
INIT_SH="$REPO_ROOT/scripts/init-project.sh"
ACTIVATE_REL="scripts/activate-capability.sh"

PASSED=0
FAILED=0
t_pass() { echo -e "  \033[32mPASS\033[0m $1"; PASSED=$((PASSED + 1)); }
t_fail() { echo -e "  \033[31mFAIL\033[0m $1${2:+ — $2}"; FAILED=$((FAILED + 1)); }

assert_contains() {
    if [[ "$2" == *"$3"* ]]; then t_pass "$1"
    else t_fail "$1" "expected to contain '$3'"; fi
}
assert_not_contains() {
    if [[ "$2" != *"$3"* ]]; then t_pass "$1"
    else t_fail "$1" "should NOT contain '$3'"; fi
}
assert_file() {
    if [[ -e "$2" ]]; then t_pass "$1"
    else t_fail "$1" "expected path to exist: $2"; fi
}
assert_no_file() {
    if [[ ! -e "$2" ]]; then t_pass "$1"
    else t_fail "$1" "expected path to be absent: $2"; fi
}

CLEANUP_DIRS=()
cleanup() {
    local d
    for d in "${CLEANUP_DIRS[@]:-}"; do
        [[ -n "$d" && -d "$d" ]] && rm -rf "$d"
    done
}
trap cleanup EXIT

# make_swift_only_install — create a Swift-only project, run init-project.sh
# against it (which populates pack-capability-pool/ via S5b and removes the
# live-tree Python conditional files via S9), then commit so the tree is
# clean. Echoes the install dir path on stdout.
make_swift_only_install() {
    local src
    src=$(mktemp -d -t bd200-swift.XXXXXX)
    CLEANUP_DIRS+=("$src")
    git init -q "$src" >/dev/null 2>&1
    git -C "$src" config user.email "test@example.com"
    git -C "$src" config user.name  "Test"
    # Swift-only language marker; no pyproject.toml / *.py anywhere.
    cat > "$src/Package.swift" <<'EOF'
// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "Widget", targets: [.target(name: "Widget")])
EOF
    mkdir -p "$src/Sources/Widget"
    echo 'public struct Widget {}' > "$src/Sources/Widget/Widget.swift"
    git -C "$src" add -A >/dev/null 2>&1
    git -C "$src" commit -q -m "swift scaffold" >/dev/null 2>&1 || true

    # Install the pack (consume the y/N confirmation). S9 removes the
    # live-tree Python set; S5b populates the full pool regardless.
    PACK="$REPO_ROOT" bash "$INIT_SH" "$src" <<<"y" >/dev/null 2>&1 || {
        echo "INIT_FAILED" ; return 1
    }
    git -C "$src" add -A >/dev/null 2>&1
    git -C "$src" commit -q -m "pack install" >/dev/null 2>&1 || true
    printf '%s\n' "$src"
}

# clone_no_pack — clone an install dir to a fresh scratch dir, scrubbing
# $PACK from the environment so the activation runs as it would on a fresh
# machine with no pack present. Echoes the clone path.
clone_no_pack() {
    local src="$1" dst
    dst=$(mktemp -d -t bd200-clone.XXXXXX)
    CLEANUP_DIRS+=("$dst")
    rm -rf "$dst"
    git clone -q "$src" "$dst" >/dev/null 2>&1
    git -C "$dst" config user.email "test@example.com"
    git -C "$dst" config user.name  "Test"
    printf '%s\n' "$dst"
}

# ─────────────────────────────────────────────────────────────────────────
# Group 1: fresh-clone activation walk (no $PACK)
# ─────────────────────────────────────────────────────────────────────────
echo "Group 1: fresh-clone activation walk (no \$PACK)"

INSTALL=$(make_swift_only_install)
if [[ "$INSTALL" == "INIT_FAILED" || ! -d "$INSTALL" ]]; then
    t_fail "init-project.sh Swift-only install" "init failed; cannot run activation walk"
else
    # Sanity: the install has a populated pool and NO live-tree Python.
    assert_file   "S5b populated the pool"                 "$INSTALL/pack-capability-pool"
    assert_file   "pool holds pyproject.toml master"       "$INSTALL/pack-capability-pool/pyproject.toml"
    assert_file   "pool holds server/ master"              "$INSTALL/pack-capability-pool/server"
    assert_file   "pool holds bootstrap-python.sh master"  "$INSTALL/pack-capability-pool/scripts/bootstrap-python.sh"
    assert_no_file "S9 removed live-tree pyproject.toml"   "$INSTALL/pyproject.toml"
    assert_no_file "S9 removed live-tree server/"          "$INSTALL/server"
    assert_no_file "S9 removed live-tree bootstrap-python.sh" "$INSTALL/scripts/bootstrap-python.sh"

    CLONE=$(clone_no_pack "$INSTALL")
    if [[ ! -d "$CLONE" ]]; then
        t_fail "git clone of install" "clone dir absent"
    else
        # Run activation with PACK scrubbed from the environment.
        OUT=$(cd "$CLONE" && env -u PACK bash "$ACTIVATE_REL" --add language:python 2>&1) || true

        assert_contains "P0 banner present"  "$OUT" "── P0 — pre-flight ──"
        assert_contains "P5 banner present"  "$OUT" "── P5 — re-materialize conditional files"
        assert_contains "P8 banner present"  "$OUT" "── P8 — end-of-run PM chat prompt ──"
        assert_not_contains "P0 did not require an external clone (no PACK error)" \
            "$OUT" "PACK"

        # P5 re-materialized the Python set FROM the pool into the live tree.
        assert_file "P5 re-materialized pyproject.toml"         "$CLONE/pyproject.toml"
        assert_file "P5 re-materialized server/"                "$CLONE/server"
        assert_file "P5 re-materialized bootstrap-python.sh"    "$CLONE/scripts/bootstrap-python.sh"
        assert_file "P5 re-materialized format-python.sh"       "$CLONE/scripts/format-python.sh"
        assert_file "P5 re-materialized validate-python.sh"     "$CLONE/scripts/validate-python.sh"
        assert_file "P5 re-materialized test-python.sh"         "$CLONE/scripts/test-python.sh"

        # Re-materialized scripts are executable.
        if [[ -x "$CLONE/scripts/bootstrap-python.sh" ]]; then
            t_pass "re-materialized bootstrap-python.sh is executable"
        else
            t_fail "re-materialized bootstrap-python.sh should be executable"
        fi

        # P8 prompt is present and free of external-clone tokens.
        PROMPT="$CLONE/.pack-activate-capability-prompt.md"
        assert_file "P8 wrote the prompt file" "$PROMPT"
        if [[ -f "$PROMPT" ]]; then
            PTXT=$(cat "$PROMPT")
            assert_contains    "prompt references Procedure 6"      "$PTXT" "Procedure 6"
            assert_not_contains "prompt has no \$PACK token"        "$PTXT" "\$PACK"
            assert_not_contains "prompt has no 'from the pack'"     "$PTXT" "from the pack"
        fi

        # F1 — the ephemeral prompt artifact MUST be gitignored so the
        # developer's closing `git add -A` never commits it into the client repo.
        if git -C "$CLONE" check-ignore -q ".pack-activate-capability-prompt.md"; then
            t_pass "prompt artifact is gitignored (git check-ignore reports IGNORED)"
        else
            t_fail "prompt artifact should be gitignored" "git check-ignore did not match"
        fi

        # A second activation run must NOT duplicate the .gitignore line (dedupe).
        env -u PACK bash -c "cd '$CLONE' && bash '$ACTIVATE_REL' --add language:python" >/dev/null 2>&1 || true
        GI_HITS=$(grep -Fxc ".pack-activate-capability-prompt.md" "$CLONE/.gitignore" 2>/dev/null || true)
        if [[ "$GI_HITS" == "1" ]]; then
            t_pass "second activation run does not duplicate the .gitignore line (count=1)"
        else
            t_fail "prompt .gitignore line should appear exactly once" "count=$GI_HITS"
        fi
    fi
fi

# ─────────────────────────────────────────────────────────────────────────
# Group 2: x--preserve-on-activate (guard genuinely exercised)
# ─────────────────────────────────────────────────────────────────────────
# The P5 x- guard fires when a RESOLVED destination's basename begins with
# x-. The pack capability tables never resolve to an x- path, so against the
# stock tables the guard is defensive (forward-pinning), exactly like the
# is_x_prefixed guard in init-project.sh stage S9. To genuinely EXERCISE the
# skip+warn path, this group rewrites the CLONE's OWN installed capability
# tables so language:python resolves to an x--basename path, pre-places a
# project-authored file there, and asserts P5 preserves it + warns. (The
# script sources its own installed scripts/capability-tables.sh, so editing
# the clone's copy is the faithful injection point — no pack involvement.)
echo ""
echo "Group 2: x--preserve-on-activate (guard exercised)"

INSTALL2=$(make_swift_only_install)
if [[ "$INSTALL2" == "INIT_FAILED" || ! -d "$INSTALL2" ]]; then
    t_fail "init-project.sh Swift-only install (group 2)" "init failed"
else
    CLONE2=$(clone_no_pack "$INSTALL2")
    if [[ ! -d "$CLONE2" ]]; then
        t_fail "git clone (group 2)" "clone dir absent"
    else
        XCONTENT="PROJECT-AUTHORED-DO-NOT-CLOBBER"
        # Rewrite the clone's installed capability_files() so language:python
        # resolves to an x- basename (scripts/x-tool.sh) plus a normal
        # (non-x-) path (pyproject.toml) — proving the guard skips the x- dest
        # while still writing the non-x- dest in the same run.
        TABLES="$CLONE2/scripts/capability-tables.sh"
        cat >> "$TABLES" <<'EOF'

# Test override (BD-200 harness): force language:python to resolve to an x-
# destination plus a normal one, to exercise the P5 x- overwrite guard.
capability_files() {
    local cap="$1"
    case "$cap" in
        language:python) echo "pyproject.toml scripts/x-tool.sh" ;;
        *) echo "" ;;
    esac
}
EOF
        # Pre-place a project-authored file at the x- resolved destination, and
        # stage a corresponding x- master into the clone's pool so P5 has a
        # source to (attempt to) copy from.
        mkdir -p "$CLONE2/scripts" "$CLONE2/pack-capability-pool/scripts"
        printf '%s\n' "$XCONTENT" > "$CLONE2/scripts/x-tool.sh"
        printf '%s\n' "POOL-MASTER-WOULD-CLOBBER" > "$CLONE2/pack-capability-pool/scripts/x-tool.sh"
        git -C "$CLONE2" add -A >/dev/null 2>&1
        git -C "$CLONE2" commit -q -m "harness x- override" >/dev/null 2>&1 || true

        OUT2=$(cd "$CLONE2" && env -u PACK bash "$ACTIVATE_REL" --add language:python 2>&1) || true

        # The x- destination is preserved byte-for-byte (guard fired, no clobber).
        if [[ -f "$CLONE2/scripts/x-tool.sh" ]] && \
           grep -q "$XCONTENT" "$CLONE2/scripts/x-tool.sh"; then
            t_pass "x- resolved dest preserved (not clobbered by pool master)"
        else
            t_fail "x- resolved dest should be preserved unchanged"
        fi
        # The guard emitted a warn (stderr captured into OUT2).
        assert_contains "P5 warns when preserving an x- file" "$OUT2" "preserving project-authored file"
        # The non-x- resolved file in the SAME run IS materialized (guard is
        # path-faithful: it skips only the x- dest, not the whole run).
        assert_file "non-x- resolved file pyproject.toml materialized" \
            "$CLONE2/pyproject.toml"
    fi
fi

# ─────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────
echo ""
echo "── Summary ──"
echo "  passed: $PASSED"
echo "  failed: $FAILED"

if (( FAILED > 0 )); then
    exit 1
fi
exit 0
