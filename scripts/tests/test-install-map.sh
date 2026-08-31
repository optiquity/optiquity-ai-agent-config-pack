#!/usr/bin/env bash
# scripts/tests/test-install-map.sh — unit tests for scripts/lib/install-map.sh.
#
# Covers both map blocks, the family fan-out, the `self` class, the marker
# contract, and the zero-match-pattern error. Every leg that guards a
# contract is paired with the MUTATION that must break it — a leg passing on
# both the good and the bad input is not a guard.
#
# Usage: bash scripts/tests/test-install-map.sh

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIB="$REPO_ROOT/scripts/lib/install-map.sh"

PASS=0
FAIL=0

t_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m %s\n" "$1"; }
t_fail() {
    FAIL=$((FAIL + 1))
    printf "  \033[31mFAIL\033[0m %s\n" "$1"
    # Diagnostics are truncated: a failing leg here can carry the whole
    # 259-row dispatch set, which buries every other result.
    [[ -n "${2:-}" ]] && printf '%s\n' "$2" | head -8 | sed 's/^/       /'
    return 0
}

# shellcheck source=/dev/null
. "$LIB"

TMPROOT="$(mktemp -d "${TMPDIR:-/tmp}/install-map-test.XXXXXX")"
cleanup() { [ -n "${TMPROOT:-}" ] && rm -rf "$TMPROOT"; }
trap cleanup EXIT

# Build a synthetic pack root. $1 = dir name; stdin = init-project.sh body.
# Also seeds the family source files the good fixtures expect.
mk_root() {
    # Two statements on purpose: `local a=$1 b=$TMP/$a` expands `$a` while the
    # `local` argument list is still being built, i.e. before `a` is assigned.
    local name="$1"
    local root="$TMPROOT/$name"
    mkdir -p "$root/scripts"
    cat > "$root/scripts/init-project.sh"
    printf '%s\n' "$root"
}

seed_family() {
    local root="$1"
    mkdir -p "$root/project-template/skills/alpha" \
             "$root/project-template/skills/beta" \
             "$root/project-template/bundle"
    printf 'a\n' > "$root/project-template/skills/alpha/SKILL.md"
    printf 'b\n' > "$root/project-template/skills/beta/SKILL.md"
    printf 'x\n' > "$root/project-template/bundle/one.md"
    printf 'y\n' > "$root/project-template/bundle/two.md"
    mkdir -p "$root/project-template/docs"
    printf 'd\n' > "$root/project-template/docs/GUIDE.md"
}

GOOD_MAP='#!/usr/bin/env bash
# _CLIENT_INSTALLED_FILES_START
#   project-template/docs/GUIDE.md  ->  docs/GUIDE.md  [stage:S6,cmd_update,migrate]  [class:generic]
# _CLIENT_INSTALLED_FILES_END
#
# _CLIENT_INSTALLED_GLOBS_START
#   project-template/skills/*/SKILL.md  ->  .{claude,codex,agents}/skills/*/SKILL.md  [stage:S4,cmd_update,migrate]  [class:generic]
#   project-template/bundle/*  ->  bundle/*  [stage:S2,migrate]  [class:self]
# _CLIENT_INSTALLED_GLOBS_END
main() { :; }
'

# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 1: entry points against a well-formed map ===\n"

G1="$(printf '%s' "$GOOD_MAP" | mk_root good)"
seed_family "$G1"
export INSTALL_MAP_PACK="$G1"

out="$(install_map_explicit_rows)"; rc=$?
if [ $rc -eq 0 ] && [ "$(printf '%s\n' "$out" | wc -l | tr -d ' ')" = "1" ]; then
    t_pass "install_map_explicit_rows emits one record per explicit row"
else
    t_fail "install_map_explicit_rows shape" "rc=$rc out=$out"
fi

if printf '%s' "$out" | grep -q "project-template/docs/GUIDE.md	docs/GUIDE.md	S6,cmd_update,migrate	generic"; then
    t_pass "explicit record is pack_rel<TAB>proj_rel<TAB>stages<TAB>class"
else
    t_fail "explicit record field layout" "$out"
fi

out="$(install_map_glob_rows)"
if printf '%s' "$out" | grep -q '\.{claude,codex,agents}/skills/\*/SKILL\.md'; then
    t_pass "install_map_glob_rows leaves the DEST brace group UNEXPANDED"
else
    t_fail "glob rows must not expand the brace group" "$out"
fi

# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 2: family fan-out + expansion ===\n"

out="$(install_map_dispatch_set cmd_update)"; rc=$?
n_alpha="$(printf '%s\n' "$out" | grep -c 'skills/alpha/SKILL.md' || true)"
if [ $rc -eq 0 ] && [ "$n_alpha" = "3" ]; then
    t_pass "a {a,b,c} DEST fans out to 3 expansions per matched source"
else
    t_fail "brace fan-out arity" "rc=$rc alpha=$n_alpha out=$out"
fi

if printf '%s\n' "$out" | grep -q '^project-template/skills/alpha/SKILL.md:.codex/skills/alpha/SKILL.md:generic$'; then
    t_pass "fan-out substitutes the capture into each brace member's DEST"
else
    t_fail "fan-out DEST substitution" "$out"
fi

# `migrate` reaches the [class:self] row; `cmd_update` does not (it is
# tagged S2,migrate only) — so the token filter is load-bearing.
if printf '%s\n' "$out" | grep -q 'bundle/'; then
    t_fail "stage-token filter leaked a non-cmd_update row into cmd_update" "$out"
else
    t_pass "stage-token filter excludes rows lacking the token"
fi

# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 3: [class:self] yields an EMPTY class field ===\n"

out="$(install_map_dispatch_set migrate)"
self_row="$(printf '%s\n' "$out" | grep 'bundle/one.md' || true)"
if [ "$self_row" = "project-template/bundle/one.md:bundle/one.md:" ]; then
    t_pass "[class:self] emits an empty class field (copy site passes no class arg)"
else
    t_fail "[class:self] must produce an empty trailing class field" "$self_row"
fi

if printf '%s\n' "$out" | grep -q ':self$'; then
    t_fail "the literal token 'self' must never be emitted as a class value" "$out"
else
    t_pass "the reserved token 'self' is never emitted as a class value"
fi

# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 4: declared_dests == dispatch_set dests (same token) ===\n"

a="$(install_map_dispatch_set migrate | cut -d: -f2 | sort -u)"
b="$(install_map_declared_dests migrate | sort -u)"
if [ "$a" = "$b" ]; then
    t_pass "install_map_declared_dests agrees set-wise with install_map_dispatch_set"
else
    t_fail "declared_dests / dispatch_set disagree" "$(diff <(printf '%s\n' "$a") <(printf '%s\n' "$b") | head -10)"
fi

# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 5: reverse lookup (the 1->N family collapse) ===\n"

ok_all=1
for d in .claude/skills/alpha/SKILL.md .codex/skills/alpha/SKILL.md .agents/skills/alpha/SKILL.md; do
    got="$(install_map_source_for_dest "$d")" || got="RC1"
    [ "$got" = "project-template/skills/alpha/SKILL.md" ] || ok_all=0
done
if [ "$ok_all" -eq 1 ]; then
    t_pass "all 3 client skills paths resolve back to the single pool source"
else
    t_fail "1->3 skills family must reverse-resolve to one pool source"
fi

got="$(install_map_source_for_dest docs/GUIDE.md)" || got="RC1"
if [ "$got" = "project-template/docs/GUIDE.md" ]; then
    t_pass "explicit DEST reverse-resolves to its pack source"
else
    t_fail "explicit reverse lookup" "$got"
fi

if install_map_source_for_dest no/such/file.md >/dev/null 2>&1; then
    t_fail "an unmapped DEST must return rc1"
else
    t_pass "an unmapped DEST returns rc1 and prints nothing"
fi

# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 6: MUTATION — duplicate START marker ⇒ rc≠0 ===\n"

DUP_MAP="$(printf '%s' "$GOOD_MAP" | sed 's|^# _CLIENT_INSTALLED_FILES_START$|# _CLIENT_INSTALLED_FILES_START\n# _CLIENT_INSTALLED_FILES_START|')"
G6="$(printf '%s' "$DUP_MAP" | mk_root dupmarker)"
seed_family "$G6"
export INSTALL_MAP_PACK="$G6"
err="$(install_map_explicit_rows 2>&1)"; rc=$?
if [ $rc -ne 0 ]; then
    t_pass "duplicate START marker ⇒ rc≠0 (rc=$rc)"
else
    t_fail "duplicate START marker MUST fail the marker contract" "$err"
fi
case "$err" in
    *"marker contract violated"*) t_pass "duplicate marker emits a diagnostic naming the contract" ;;
    *) t_fail "marker-contract diagnostic missing" "$err" ;;
esac

# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 7: MUTATION — missing GLOBS block ⇒ rc≠0 ===\n"

NOGLOB_MAP='#!/usr/bin/env bash
# _CLIENT_INSTALLED_FILES_START
#   project-template/docs/GUIDE.md  ->  docs/GUIDE.md  [stage:S6,cmd_update]  [class:generic]
# _CLIENT_INSTALLED_FILES_END
'
G7="$(printf '%s' "$NOGLOB_MAP" | mk_root noglob)"
seed_family "$G7"
export INSTALL_MAP_PACK="$G7"
err="$(install_map_explicit_rows 2>&1)"; rc=$?
if [ $rc -ne 0 ]; then
    t_pass "an absent GLOBS block ⇒ rc≠0 (half-parsed map is never silently accepted)"
else
    t_fail "absent GLOBS block MUST fail the exactly-once contract" "$err"
fi

# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 8: MUTATION — zero-match family pattern ⇒ rc≠0 ===\n"

ZERO_MAP='#!/usr/bin/env bash
# _CLIENT_INSTALLED_FILES_START
#   project-template/docs/GUIDE.md  ->  docs/GUIDE.md  [stage:S6,cmd_update]  [class:generic]
# _CLIENT_INSTALLED_FILES_END
#
# _CLIENT_INSTALLED_GLOBS_START
#   project-template/nothing-here/*.md  ->  nothing-here/*.md  [stage:S4,cmd_update]  [class:generic]
# _CLIENT_INSTALLED_GLOBS_END
'
G8="$(printf '%s' "$ZERO_MAP" | mk_root zeromatch)"
seed_family "$G8"
export INSTALL_MAP_PACK="$G8"
err="$(install_map_dispatch_set cmd_update 2>&1)"; rc=$?
if [ $rc -ne 0 ]; then
    t_pass "a family pattern matching ZERO files ⇒ rc≠0 (never a silent skip)"
else
    t_fail "zero-match family pattern MUST error" "$err"
fi
case "$err" in
    *"matches nothing"*) t_pass "zero-match diagnostic names the dead pattern" ;;
    *) t_fail "zero-match diagnostic missing" "$err" ;;
esac

# Same map, with the family source materialised: the SAME leg now passes.
# This is what proves the leg discriminates rather than always failing.
mkdir -p "$G8/project-template/nothing-here"
printf 'now here\n' > "$G8/project-template/nothing-here/real.md"
unset _INSTALL_MAP_LOADED_ROOT
out="$(install_map_dispatch_set cmd_update 2>&1)"; rc=$?
if [ $rc -eq 0 ] && printf '%s\n' "$out" | grep -q 'nothing-here/real.md'; then
    t_pass "the same row PASSES once its pattern has backing (leg discriminates)"
else
    t_fail "zero-match leg must pass when backing exists" "rc=$rc $out"
fi

# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 9: the REAL pack map parses and is non-empty ===\n"

unset INSTALL_MAP_PACK
unset _INSTALL_MAP_LOADED_ROOT
real_explicit="$(install_map_explicit_rows)"; rc=$?
n_real="$(printf '%s\n' "$real_explicit" | grep -c '	' || true)"
if [ $rc -eq 0 ] && [ "$n_real" -ge 20 ]; then
    t_pass "the real install map parses ($n_real explicit rows)"
else
    t_fail "real install map parse" "rc=$rc rows=$n_real"
fi

real_glob="$(install_map_glob_rows)"
n_glob="$(printf '%s\n' "$real_glob" | grep -c '	' || true)"
if [ "$n_glob" -ge 1 ]; then
    t_pass "the real install map declares $n_glob family row(s)"
else
    t_fail "real install map GLOB block" "$real_glob"
fi

a="$(install_map_dispatch_set cmd_update | cut -d: -f2 | sort -u)"
b="$(install_map_declared_dests cmd_update | sort -u)"
if [ "$a" = "$b" ]; then
    t_pass "real map: declared_dests == dispatch_set dests on cmd_update"
else
    t_fail "real map: declared_dests / dispatch_set disagree"
fi

# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 10: candidate set is git-TRACKED REGULAR FILES ===\n"

# A family pattern is a FILE pattern. A bare existence test also matches a
# DIRECTORY, and `.gitignore` (pack root and project-template/) expects build
# and OS artifacts inside the directories these rows glob, so an unfiltered
# glob would hand a client a directory or a build artifact.

DIR_MAP='#!/usr/bin/env bash
# _CLIENT_INSTALLED_FILES_START
#   project-template/docs/GUIDE.md  ->  docs/GUIDE.md  [stage:S6,cmd_update]  [class:generic]
# _CLIENT_INSTALLED_FILES_END
#
# _CLIENT_INSTALLED_GLOBS_START
#   project-template/bundle/*  ->  bundle/*  [stage:S6,cmd_update]  [class:generic]
# _CLIENT_INSTALLED_GLOBS_END
'
G10="$(printf '%s' "$DIR_MAP" | mk_root candidates)"
seed_family "$G10"
# A directory and an extra regular file, both matching `bundle/*`.
mkdir -p "$G10/project-template/bundle/__pycache__"
printf 'artifact\n' > "$G10/project-template/bundle/__pycache__/x.pyc"
printf 'stray\n' > "$G10/project-template/bundle/stray.md"
export INSTALL_MAP_PACK="$G10"
unset _INSTALL_MAP_LOADED_ROOT

out="$(install_map_dispatch_set cmd_update 2>&1)"; rc=$?
if [ $rc -eq 0 ] && ! printf '%s\n' "$out" | grep -q '__pycache__'; then
    t_pass "a DIRECTORY matching a family pattern never enters the dispatch set"
else
    t_fail "family expansion admitted a directory" "rc=$rc $out"
fi

# Discrimination for the leg above: a regular FILE in the SAME directory,
# matched by the SAME pattern, IS present — so the leg above is not passing
# merely because the whole family was dropped.
if printf '%s\n' "$out" | grep -q 'project-template/bundle/one.md:bundle/one.md:'; then
    t_pass "a regular file under the same pattern IS admitted (leg discriminates)"
else
    t_fail "family expansion dropped a legitimate regular file" "$out"
fi

# The tracked filter, exercised through its memo seam so the leg needs no
# scratch git repo. `_install_map_tracked_load` short-circuits when the root
# already matches, so seeding these three vars IS the "git said so" path.
_INSTALL_MAP_TRACKED_ROOT="$G10"
_INSTALL_MAP_TRACKED_ACTIVE=1
_INSTALL_MAP_TRACKED="
project-template/docs/GUIDE.md
project-template/bundle/one.md
project-template/bundle/two.md
"
out="$(install_map_dispatch_set cmd_update 2>&1)"; rc=$?
if [ $rc -eq 0 ] && ! printf '%s\n' "$out" | grep -q 'stray.md'; then
    t_pass "an UNTRACKED regular file never enters the dispatch set"
else
    t_fail "family expansion admitted an untracked file" "rc=$rc $out"
fi

if printf '%s\n' "$out" | grep -q 'bundle/one.md'; then
    t_pass "a tracked file under the same pattern IS admitted (leg discriminates)"
else
    t_fail "tracked filter dropped a tracked file" "$out"
fi

# Leniency: with the filter inactive (the non-git-work-tree case) the same
# untracked file reappears. This is the branch every synthetic-root group
# above runs on, asserted explicitly here.
_INSTALL_MAP_TRACKED_ACTIVE=0
out="$(install_map_dispatch_set cmd_update 2>&1)"
if printf '%s\n' "$out" | grep -q 'stray.md'; then
    t_pass "tracked filter is LENIENT when the root is not a git work tree"
else
    t_fail "inactive tracked filter must not exclude anything" "$out"
fi
unset _INSTALL_MAP_TRACKED_ROOT _INSTALL_MAP_TRACKED _INSTALL_MAP_TRACKED_ACTIVE

# Load-bearing leg: the REAL pack root, where the filter is live. Read-only
# git; one subprocess for the whole leg.
unset INSTALL_MAP_PACK
unset _INSTALL_MAP_LOADED_ROOT
real_src="$(install_map_dispatch_set cmd_update | cut -d: -f1 | sort -u)"

# The two legs below draw conclusions from `real_src`; an EMPTY set would let
# both pass while proving nothing. Assert the legs reach their data first.
n_real_src="$(printf '%s\n' "$real_src" | grep -c . || true)"
if [ "$n_real_src" -ge 100 ]; then
    t_pass "real map: the legs below reach their data ($n_real_src unique sources)"
else
    t_fail "real-map legs would pass VACUOUSLY — dispatch set empty/short" "n=$n_real_src"
fi

real_untracked=""
if git -C "$REPO_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    # Pathspec DERIVED from the rows, never hard-coded: the map sources from
    # `supporting-docs/` as well as `project-template/`, and a fixed prefix
    # would report every other root as untracked. Unquoted on purpose — the
    # specs are single path segments.
    real_specs="$(printf '%s\n' "$real_src" | cut -d/ -f1 | sort -u)"
    real_tracked="$(git -C "$REPO_ROOT" ls-files -- $real_specs | sort -u)"
    real_untracked="$(comm -23 <(printf '%s\n' "$real_src") <(printf '%s\n' "$real_tracked"))"
    if [ -z "$real_untracked" ]; then
        t_pass "real map: every cmd_update dispatch source is git-tracked"
    else
        t_fail "real map: untracked path(s) in the dispatch set" "$real_untracked"
    fi
else
    t_pass "real map: not a git work tree — tracked leg skipped (lenient)"
fi

real_dirs=""
for s in $real_src; do
    [ -d "$REPO_ROOT/$s" ] && real_dirs="$real_dirs $s"
done
if [ -z "$real_dirs" ]; then
    t_pass "real map: no cmd_update dispatch source is a directory"
else
    t_fail "real map: directory(ies) in the dispatch set" "$real_dirs"
fi

# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 11: reverse lookup — '*' never crosses '/' ===\n"

# The forward direction gets segment semantics for free (shell pathname
# expansion does not cross `/`). The reverse direction matches with a `case`
# glob, which is unrestricted, so the capture is range-checked instead.

export INSTALL_MAP_PACK="$G1"
unset _INSTALL_MAP_LOADED_ROOT

got="$(install_map_source_for_dest '.claude/skills/a/b/SKILL.md')" || got="RC1"
if [ "$got" = "RC1" ]; then
    t_pass "a NESTED dest does not reverse-resolve onto a one-level family row"
else
    t_fail "reverse '*' crossed '/' and resolved a nested dest" "$got"
fi

# Discrimination: the one-level sibling of that same dest still resolves, so
# the leg above is not passing because the family stopped matching entirely.
got="$(install_map_source_for_dest '.claude/skills/alpha/SKILL.md')" || got="RC1"
if [ "$got" = "project-template/skills/alpha/SKILL.md" ]; then
    t_pass "the one-level sibling still resolves (leg discriminates)"
else
    t_fail "segment check broke a legitimate one-level reverse lookup" "$got"
fi

unset INSTALL_MAP_PACK
unset _INSTALL_MAP_LOADED_ROOT

# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 12: MUTATION — a block parsing to ZERO rows ⇒ rc≠0 ===\n"

# The NON-EMPTY FLOOR. Markers exactly-once — so Group 6/7's contract is
# satisfied — but the block yields nothing. That is a broken GRAMMAR, not an
# empty install set, and without the floor it returns rc 0 with zero rows and
# every derived consumer silently sees "the pack installs nothing".
# Each mutation is paired with the restore that must make the SAME leg pass.

# (a) FILES block: every row loses its `->`.
NOARROW_MAP='#!/usr/bin/env bash
# _CLIENT_INSTALLED_FILES_START
#   project-template/docs/GUIDE.md      docs/GUIDE.md  [stage:S6,cmd_update]  [class:generic]
# _CLIENT_INSTALLED_FILES_END
#
# _CLIENT_INSTALLED_GLOBS_START
#   project-template/bundle/*  ->  bundle/*  [stage:S6,cmd_update]  [class:generic]
# _CLIENT_INSTALLED_GLOBS_END
'
G12="$(printf '%s' "$NOARROW_MAP" | mk_root emptyblock)"
seed_family "$G12"
export INSTALL_MAP_PACK="$G12"
unset _INSTALL_MAP_LOADED_ROOT

err="$(install_map_explicit_rows 2>&1)"; rc=$?
if [ $rc -ne 0 ]; then
    t_pass "a FILES block with no parseable row ⇒ rc≠0 (rc=$rc)"
else
    t_fail "an emptied FILES block MUST fail the non-empty floor" "$err"
fi
case "$err" in
    *_CLIENT_INSTALLED_FILES_START*"no parseable entries"*)
        t_pass "floor diagnostic names the FILES block and the required row form" ;;
    *) t_fail "FILES-block floor diagnostic missing or unnamed" "$err" ;;
esac

# (b) GLOBS block: markers kept, rows replaced by non-row prose.
NOROWS_MAP='#!/usr/bin/env bash
# _CLIENT_INSTALLED_FILES_START
#   project-template/docs/GUIDE.md  ->  docs/GUIDE.md  [stage:S6,cmd_update]  [class:generic]
# _CLIENT_INSTALLED_FILES_END
#
# _CLIENT_INSTALLED_GLOBS_START
#   (rows removed)
# _CLIENT_INSTALLED_GLOBS_END
'
printf '%s' "$NOROWS_MAP" > "$G12/scripts/init-project.sh"
unset _INSTALL_MAP_LOADED_ROOT
err="$(install_map_glob_rows 2>&1)"; rc=$?
if [ $rc -ne 0 ]; then
    t_pass "a GLOBS block with no parseable row ⇒ rc≠0 (rc=$rc)"
else
    t_fail "an emptied GLOBS block MUST fail the non-empty floor" "$err"
fi
case "$err" in
    *_CLIENT_INSTALLED_GLOBS_START*"no parseable entries"*)
        t_pass "floor diagnostic names the GLOBS block" ;;
    *) t_fail "GLOBS-block floor diagnostic missing or unnamed" "$err" ;;
esac

# (c) Markers relocated to wrap ZERO lines — the refactor shape that keeps
# the exactly-once contract intact while orphaning every row.
ADJACENT_MAP='#!/usr/bin/env bash
# _CLIENT_INSTALLED_FILES_START
# _CLIENT_INSTALLED_FILES_END
#   project-template/docs/GUIDE.md  ->  docs/GUIDE.md  [stage:S6,cmd_update]  [class:generic]
#
# _CLIENT_INSTALLED_GLOBS_START
#   project-template/bundle/*  ->  bundle/*  [stage:S6,cmd_update]  [class:generic]
# _CLIENT_INSTALLED_GLOBS_END
'
printf '%s' "$ADJACENT_MAP" > "$G12/scripts/init-project.sh"
unset _INSTALL_MAP_LOADED_ROOT
err="$(install_map_explicit_rows 2>&1)"; rc=$?
if [ $rc -ne 0 ]; then
    t_pass "markers wrapping ZERO lines ⇒ rc≠0 (orphaned rows are not an empty set)"
else
    t_fail "adjacent markers MUST fail the non-empty floor" "$err"
fi

# FAILING DIRECTION CLOSED: the same root, same entry points, one parseable
# row per block restored. Every leg above must now pass, or those legs were
# failing for some reason other than the floor.
printf '%s' "$GOOD_MAP" > "$G12/scripts/init-project.sh"
unset _INSTALL_MAP_LOADED_ROOT
out="$(install_map_explicit_rows 2>&1)"; rc=$?
if [ $rc -eq 0 ] && printf '%s\n' "$out" | grep -q 'docs/GUIDE.md'; then
    t_pass "FILES block PASSES once one row parses (floor discriminates)"
else
    t_fail "non-empty floor rejected a block that has a parseable row" "rc=$rc $out"
fi

out="$(install_map_glob_rows 2>&1)"; rc=$?
if [ $rc -eq 0 ] && printf '%s\n' "$out" | grep -q 'SKILL.md'; then
    t_pass "GLOBS block PASSES once one row parses (floor discriminates)"
else
    t_fail "non-empty floor rejected a GLOBS block that has a parseable row" "rc=$rc $out"
fi

unset INSTALL_MAP_PACK
unset _INSTALL_MAP_LOADED_ROOT

# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 13: the class operand is trimmed and shape-checked ===\n"

# Class is the one operand whose bad value silently CHANGES dispatch: an
# unrecognised token falls to the generic text merge, which three-ways a
# client `x-` custom in the shared bundle. So a stray space must not defeat
# the `self` sentinel, and a token that cannot be a class must not parse.

SPACED_MAP='#!/usr/bin/env bash
# _CLIENT_INSTALLED_FILES_START
#   project-template/docs/GUIDE.md  ->  docs/GUIDE.md  [stage:S6,cmd_update]  [class: self]
# _CLIENT_INSTALLED_FILES_END
#
# _CLIENT_INSTALLED_GLOBS_START
#   project-template/bundle/*  ->  bundle/*  [stage:S6,cmd_update]  [class: generic ]
# _CLIENT_INSTALLED_GLOBS_END
'
G13="$(printf '%s' "$SPACED_MAP" | mk_root spacedclass)"
seed_family "$G13"
export INSTALL_MAP_PACK="$G13"
unset _INSTALL_MAP_LOADED_ROOT

out="$(install_map_dispatch_set cmd_update 2>&1)"; rc=$?
if [ $rc -eq 0 ] && printf '%s\n' "$out" | grep -q '^project-template/docs/GUIDE.md:docs/GUIDE.md:$'; then
    t_pass "'[class: self]' still resolves to the self sentinel (empty class)"
else
    t_fail "a spaced 'self' must not become a FORCED class" "rc=$rc $out"
fi

# Discrimination: a spaced ORDINARY class is trimmed to the bare token, so
# the leg above is not passing because every class went empty.
if printf '%s\n' "$out" | grep -q '^project-template/bundle/one.md:bundle/one.md:generic$'; then
    t_pass "'[class: generic ]' trims to 'generic' (not blanked, not padded)"
else
    t_fail "a spaced ordinary class must trim to the bare token" "$out"
fi

# The shape gate. A class that cannot be a class is a parse error, not a
# silent fall-through to the generic text merge.
BADCLASS_MAP='#!/usr/bin/env bash
# _CLIENT_INSTALLED_FILES_START
#   project-template/docs/GUIDE.md  ->  docs/GUIDE.md  [stage:S6,cmd_update]  [class:pack agent]
# _CLIENT_INSTALLED_FILES_END
#
# _CLIENT_INSTALLED_GLOBS_START
#   project-template/bundle/*  ->  bundle/*  [stage:S6,cmd_update]  [class:generic]
# _CLIENT_INSTALLED_GLOBS_END
'
printf '%s' "$BADCLASS_MAP" > "$G13/scripts/init-project.sh"
unset _INSTALL_MAP_LOADED_ROOT
err="$(install_map_explicit_rows 2>&1)"; rc=$?
if [ $rc -ne 0 ]; then
    t_pass "a class operand that is not a bare token ⇒ rc≠0 (rc=$rc)"
else
    t_fail "a malformed class MUST NOT parse into a forced class" "$err"
fi
case "$err" in
    *"not a bare lowercase token"*) t_pass "class diagnostic names the offending row" ;;
    *) t_fail "class shape diagnostic missing" "$err" ;;
esac

# An EMPTY but PRESENT class operand is the same defect, not self-classify:
# omitting `[class:...]` is how a row asks for self-classification.
EMPTYCLASS_MAP="$(printf '%s' "$BADCLASS_MAP" | sed 's/\[class:pack agent\]/[class:]/')"
printf '%s' "$EMPTYCLASS_MAP" > "$G13/scripts/init-project.sh"
unset _INSTALL_MAP_LOADED_ROOT
if install_map_explicit_rows >/dev/null 2>&1; then
    t_fail "a PRESENT but empty [class:] must not parse"
else
    t_pass "a PRESENT but empty [class:] ⇒ rc≠0 (omission is the self-classify form)"
fi

# FAILING DIRECTION CLOSED: the same rows with well-formed classes parse, and
# a row that OMITS the operand entirely still self-classifies.
OKCLASS_MAP='#!/usr/bin/env bash
# _CLIENT_INSTALLED_FILES_START
#   project-template/docs/GUIDE.md  ->  docs/GUIDE.md  [stage:S6,cmd_update]  [class:pack-agent]
#   project-template/bundle/one.md  ->  bundle/one.md  [stage:S6,cmd_update]
# _CLIENT_INSTALLED_FILES_END
#
# _CLIENT_INSTALLED_GLOBS_START
#   project-template/skills/*/SKILL.md  ->  .claude/skills/*/SKILL.md  [stage:S4,cmd_update]  [class:generic]
# _CLIENT_INSTALLED_GLOBS_END
'
printf '%s' "$OKCLASS_MAP" > "$G13/scripts/init-project.sh"
unset _INSTALL_MAP_LOADED_ROOT
out="$(install_map_dispatch_set cmd_update 2>&1)"; rc=$?
if [ $rc -eq 0 ] && printf '%s\n' "$out" | grep -q '^project-template/docs/GUIDE.md:docs/GUIDE.md:pack-agent$'; then
    t_pass "a well-formed class parses (shape gate discriminates)"
else
    t_fail "shape gate rejected a well-formed class" "rc=$rc $out"
fi
if printf '%s\n' "$out" | grep -q '^project-template/bundle/one.md:bundle/one.md:$'; then
    t_pass "a row that OMITS [class:] still self-classifies (gate is presence-scoped)"
else
    t_fail "shape gate broke the omitted-class row" "$out"
fi

unset INSTALL_MAP_PACK
unset _INSTALL_MAP_LOADED_ROOT

# ─────────────────────────────────────────────────────────────────
printf "\n=== Group 14: shell and Python parsers agree on the stage axis ===\n"

# ONE surface, TWO readers: this library, and the Python sibling in
# `scripts/lib/validate_checks/boundary_refs.py` that Checks 39/41 read the
# same map through. They must select the SAME rows for a stage token whatever
# whitespace the `[stage:]` list carries. A shell parser that drops a row the
# Python one counts is INVISIBLE — both checks stay green while `--update`
# never touches that file — so the agreement is asserted here rather than
# assumed. It is asserted against the REAL Python parser, never a
# re-implementation: a third copy of the token idiom would be a third thing
# that can drift.

PARITY_MAP='#!/usr/bin/env bash
# _CLIENT_INSTALLED_FILES_START
#   project-template/docs/GUIDE.md  ->  docs/GUIDE.md  [stage:S6,cmd_update]  [class:generic]
#   project-template/bundle/one.md  ->  bundle/one.md  [stage:S6, cmd_update]  [class:generic]
#   project-template/bundle/two.md  ->  bundle/two.md  [stage: S6 , cmd_update ]  [class:generic]
#   project-template/skills/alpha/SKILL.md  ->  skills/alpha/SKILL.md  [stage:S6,migrate]  [class:generic]
# _CLIENT_INSTALLED_FILES_END
#
# _CLIENT_INSTALLED_GLOBS_START
#   project-template/bundle/*  ->  bundle/*  [stage:S2]  [class:generic]
# _CLIENT_INSTALLED_GLOBS_END
'
G14="$(printf '%s' "$PARITY_MAP" | mk_root parity)"
seed_family "$G14"
export INSTALL_MAP_PACK="$G14"
unset _INSTALL_MAP_LOADED_ROOT

shell_axis="$(install_map_dispatch_set cmd_update 2>/dev/null | cut -d: -f1 | sort)"
python_axis="$(PARITY_ROOT="$G14" VALIDATE="$REPO_ROOT/scripts/validate-pack.py" \
    REPO_ROOT="$REPO_ROOT" python3 - <<'PY'
import os, sys, importlib.util
sys.path.insert(0, os.environ['REPO_ROOT'] + '/scripts')
spec = importlib.util.spec_from_file_location('vp', os.environ['VALIDATE'])
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
# Patch REPO_ROOT on every loaded validate_checks.* submodule: the parser body
# lives in boundary_refs and reads ITS module global, so a facade-only patch
# would not redirect the read (same wave-invariant the Check 41 tests honour).
import pathlib
root = pathlib.Path(os.environ['PARITY_ROOT'])
mod.REPO_ROOT = root
for _n, _m in list(sys.modules.items()):
    if (_n == 'validate_checks' or _n.startswith('validate_checks.')) \
       and hasattr(_m, 'REPO_ROOT'):
        _m.REPO_ROOT = root
for pack_rel, stages in sorted(mod._parse_client_installed_file_stages().items()):
    if 'cmd_update' in stages:
        print(pack_rel)
PY
)"
python_rc=$?

# Diagnose a Python-SIDE breakage as itself. Without this leg an import error
# or a patch-target rename yields an empty `python_axis`, and the comparison
# below would report it as a parser DISAGREEMENT — sending the next reader to
# the wrong file.
if [ "$python_rc" -eq 0 ] && [ -n "$python_axis" ]; then
    t_pass "the Python sibling parser ran and returned rows"
else
    t_fail "Python sibling parser did not run — the leg below cannot compare" \
        "rc=$python_rc out=$python_axis"
fi

if [ "$shell_axis" = "$python_axis" ]; then
    t_pass "both parsers select the same cmd_update rows (spaced lists included)"
else
    t_fail "shell and Python parsers DISAGREE on the cmd_update axis" \
        "shell:
$shell_axis
python:
$python_axis"
fi

# VACUITY GUARD for the leg above: equality of two EMPTY sets would pass it.
# The map declares three cmd_update rows written three different ways, and a
# fourth row that is deliberately OFF the axis.
n_axis="$(printf '%s\n' "$shell_axis" | grep -c .)"
if [ "$n_axis" = "3" ]; then
    t_pass "the agreed axis is the expected 3 rows (not an empty-set match)"
else
    t_fail "expected 3 rows on the cmd_update axis, got $n_axis" "$shell_axis"
fi

# DISCRIMINATION: the fourth row carries `[stage:S6,migrate]` and NO
# cmd_update, so a parser that ignored the token entirely would show 4 here.
case "$shell_axis" in
    *SKILL.md*) t_fail "a row without cmd_update leaked onto the axis" "$shell_axis" ;;
    *) t_pass "a row whose stage list omits cmd_update stays OFF the axis" ;;
esac

unset INSTALL_MAP_PACK
unset _INSTALL_MAP_LOADED_ROOT

# ─────────────────────────────────────────────────────────────────
printf "\n=== Summary ===\n"
printf "  PASS: %d\n  FAIL: %d\n" "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
