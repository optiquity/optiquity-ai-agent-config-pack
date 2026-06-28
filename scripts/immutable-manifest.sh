#!/usr/bin/env bash
# pack-internal: true  (release-cadence authoring tool; not a user-facing verb)
# scripts/immutable-manifest.sh — regenerate the pack-shipped immutable-file
# content-checksum manifest (project-template/docs/project/immutable-manifest.txt).
#
# Generated per the BD-246 immutable-manifest design; see backlog/BD-246.md.
# The manifest is a per-VERSION integrity baseline: a sha256 content
# checksum for each pack-shipped immutable file (the 3 per-stream `_rules.md`).
# Run at RELEASE cadence (alongside the README version bump), NOT per-push.
# Check 76 in scripts/validate-pack.py verifies the pack's own copies against
# this manifest; the shipped client leg project-template/scripts/verify-immutable.sh
# verifies a client's installed copies against the shipped manifest.
#
# The immutable set MUST stay consistent with `_IMMUTABLE_SHIPPED` in
# scripts/validate-pack.py (the frozen declaration). The two surfaces list
# the same 3 paths; Check 76's set-equality guard catches any drift between
# them. Growing the set requires architect+user sign-off (set-equality freeze).
#
# This tool NEVER stages, commits, or pushes (CLAUDE.md "agents-never-commit" —
# tools do not commit; only the orchestrator commits, with user approval). It
# regenerates the manifest file on disk only.
#
# Dependency direction (CLAUDE.md "dependency-direction-placement"): pack-internal
# authoring tool. NEVER a runtime dependency of a project deliverable; no client
# surface invokes it; it does NOT ship (absent from the install-map and from
# _SANCTIONED_PACK_SIDE_SHIPPED). The MANIFEST it emits ships as data; the verify
# leg (verify-immutable.sh) is the separate shipped client artifact.
#
# Version-header source: the README version table (the first `| vMAJOR.MINOR `
# data row → e.g. `v11.0`), NOT detect_pack_version (which yields the branch
# name on an untagged dev HEAD). Override with --pack-version vN.M.
#
# Usage:
#   bash scripts/immutable-manifest.sh --regen                 # regenerate from README version
#   bash scripts/immutable-manifest.sh --regen --pack-version v11.0   # explicit version
#
# Idempotent: re-running --regen on an unchanged tree reproduces a byte-identical
# manifest (deterministic hashing + stable row order).
# Exit 0 on success; exit 1 on error.

set -u

# ── Locate repo ──────────────────────────────────────────────────────────────
THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$THIS_DIR/.." && pwd)"
README="$REPO_ROOT/README.md"
MANIFEST="$REPO_ROOT/project-template/docs/project/immutable-manifest.txt"

say()  { printf '%s\n' "$*"; }
err()  { printf 'immutable-manifest: error: %s\n' "$*" >&2; }

# ── The frozen immutable set (project-relative client-installed paths) ────────
# Keep consistent with `_IMMUTABLE_SHIPPED` in scripts/validate-pack.py. Rows
# store the CLIENT-INSTALLED project-relative path; the pack-side copy is at
# project-template/<project-rel>.
IMMUTABLE_PROJECT_RELS="
docs/project/backlog/_rules.md
docs/project/implementation-plan/_rules.md
docs/project/changelog/_rules.md
"

# ── Portable sha256 of a file → 64-hex, no filename ──────────────────────────
# Prefer shasum -a 256 (BSD/macOS), then sha256sum (GNU/Linux), then python3
# hashlib. All three emit "<hash>  <name>"; we split and take field 1.
_sha256_hex() {
    local file="$1" out=""
    if command -v shasum >/dev/null 2>&1; then
        out="$(shasum -a 256 "$file" 2>/dev/null)" || return 1
    elif command -v sha256sum >/dev/null 2>&1; then
        out="$(sha256sum "$file" 2>/dev/null)" || return 1
    elif command -v python3 >/dev/null 2>&1; then
        out="$(python3 -c 'import hashlib,sys; print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "$file" 2>/dev/null)" || return 1
    else
        err "no sha256 tool available (need shasum, sha256sum, or python3)"
        return 1
    fi
    # First whitespace-delimited field is the hex digest.
    printf '%s\n' "${out%% *}"
}

# ── Read the pack version from the README version table ───────────────────────
# The first markdown table data row whose Version cell starts with vMAJOR.MINOR.
# Strips any trailing display qualifier (e.g. " (RC1)") to the bare vN.M.
_pack_version_from_readme() {
    local line ver
    [[ -f "$README" ]] || { err "README not found: $README"; return 1; }
    # Match a table row whose first cell is `vN.M` (optionally `vN.M.P`).
    line="$(grep -m1 -E '^\| v[0-9]+\.[0-9]+' "$README" 2>/dev/null)" || true
    if [[ -z "$line" ]]; then
        err "no version row found in $README"
        return 1
    fi
    # Field 2 of the pipe-delimited row is the Version cell; trim spaces, then
    # keep only the leading vN.M[.P] token (drop any " (qualifier)").
    ver="$(printf '%s\n' "$line" | awk -F'|' '{print $2}' | tr -d ' ')"
    ver="${ver%%(*}"
    printf '%s\n' "$ver"
}

# ── Regenerate the manifest ──────────────────────────────────────────────────
_regen() {
    local pack_version="$1" rel pack_path hash tmp
    if [[ -z "$pack_version" ]]; then
        pack_version="$(_pack_version_from_readme)" || return 1
    fi
    if [[ -z "$pack_version" ]]; then
        err "could not determine pack version"
        return 1
    fi

    tmp="$(mktemp -t immutable-manifest.XXXXXX)" || { err "mktemp failed"; return 1; }

    {
        printf '%s\n' '# immutable-manifest.txt — sha256 content checksums for pack-shipped immutable files'
        printf '%s\n' '# Generated by scripts/immutable-manifest.sh; do not hand-edit.'
        printf '%s\n' "# pack-version: $pack_version"
        printf '%s\n' '# Format: <project-relative-path>  <sha256>'
        printf '%s\n' '#'
    } > "$tmp"

    while IFS= read -r rel; do
        [[ -n "$rel" ]] || continue
        pack_path="$REPO_ROOT/project-template/$rel"
        if [[ ! -f "$pack_path" ]]; then
            err "immutable file missing: $pack_path"
            rm -f "$tmp"
            return 1
        fi
        hash="$(_sha256_hex "$pack_path")" || { err "hashing failed: $pack_path"; rm -f "$tmp"; return 1; }
        if [[ -z "$hash" ]]; then
            err "empty hash for: $pack_path"
            rm -f "$tmp"
            return 1
        fi
        printf '%s  %s\n' "$rel" "$hash" >> "$tmp"
    done <<EOF
$IMMUTABLE_PROJECT_RELS
EOF

    mkdir -p "$(dirname "$MANIFEST")"
    mv "$tmp" "$MANIFEST"
    say "immutable-manifest: regenerated $MANIFEST (pack-version: $pack_version)"
    return 0
}

main() {
    local mode="" pack_version=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --regen) mode="regen"; shift ;;
            --pack-version) pack_version="${2:-}"; shift 2 ;;
            --pack-version=*) pack_version="${1#*=}"; shift ;;
            -h|--help)
                say "Usage: bash scripts/immutable-manifest.sh --regen [--pack-version vN.M]"
                exit 0
                ;;
            *)
                err "unknown argument: $1"
                exit 1
                ;;
        esac
    done

    if [[ "$mode" != "regen" ]]; then
        err "no mode given (expected --regen)"
        exit 1
    fi

    _regen "$pack_version"
    exit $?
}

main "$@"
