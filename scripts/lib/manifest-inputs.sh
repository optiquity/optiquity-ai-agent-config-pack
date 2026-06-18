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
