#!/usr/bin/env bash
# pack-internal: true  (install-time generation tool; not a user-facing verb)
# scripts/immutable-manifest.sh — generate a client tree's immutable-file
# content-checksum manifest (docs/project/immutable-manifest.txt) at install.
#
# Invoked by scripts/init-project.sh (fresh install AND --update) and by
# scripts/migrate-v10-to-v11.sh against their target tree AFTER the
# per-stream `_rules.md` are placed: it hashes the files ACTUALLY INSTALLED
# in the client tree and writes the manifest beside them. The shipped client
# leg project-template/scripts/verify-immutable.sh verifies the client's
# installed copies against this install-time manifest (client-immutable:
# clients must not edit the `_rules.md` set; pack-side editing is free).
#
# The immutable set is the frozen IMMUTABLE_PROJECT_RELS below (the 4
# per-stream `_rules.md`), mirrored with verify-immutable.sh for parser
# symmetry. Growing the set requires architect+user sign-off (the
# groupings row landed under the BD-189/BD-263 OQ-9 sign-off).
#
# This tool NEVER stages, commits, or pushes (CLAUDE.md "agents-never-commit" —
# tools do not commit; only the orchestrator commits, with user approval). It
# writes the manifest file into the given client tree only.
#
# Dependency direction (CLAUDE.md "dependency-direction-placement"): pack-internal
# install-time tool. NEVER a runtime dependency of a project deliverable; no client
# surface invokes it; it does NOT ship (absent from the install-map and from
# _SANCTIONED_PACK_SIDE_SHIPPED). The MANIFEST it emits is client-tree data; the
# verify leg (verify-immutable.sh) is the separate shipped client artifact.
#
# Version-header source: the README version table (the first `| vMAJOR.MINOR `
# data row → e.g. `v11.0`), NOT detect_pack_version (which yields the branch
# name on an untagged dev HEAD). Override with --pack-version vN.M.
#
# Usage:
#   bash scripts/immutable-manifest.sh --client-tree <root>          # version from README
#   bash scripts/immutable-manifest.sh --client-tree <root> --pack-version v11.0
#
# Idempotent: re-running against an unchanged client tree reproduces a
# byte-identical manifest (deterministic hashing + stable row order).
# Exit 0 on success; exit 1 on error.

set -u

# ── Locate repo ──────────────────────────────────────────────────────────────
THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$THIS_DIR/.." && pwd)"
README="$REPO_ROOT/README.md"

say()  { printf '%s\n' "$*"; }
err()  { printf 'immutable-manifest: error: %s\n' "$*" >&2; }

# ── The frozen immutable set (project-relative client-installed paths) ────────
# Mirrored with the client verify leg
# project-template/scripts/verify-immutable.sh for parser symmetry: it checks
# the installed copies against the manifest this list generates. Rows store the
# CLIENT-INSTALLED project-relative path; the pack-side copy is at
# project-template/<project-rel>.
IMMUTABLE_PROJECT_RELS="
docs/project/backlog/_rules.md
docs/project/implementation-plan/_rules.md
docs/project/changelog/_rules.md
docs/project/groupings/_rules.md
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

# ── Generate the client-tree manifest ────────────────────────────────────────
_generate() {
    local root="$1" pack_version="$2" rel file_path hash tmp manifest
    if [[ ! -d "$root" ]]; then
        err "client tree not found: $root"
        return 1
    fi
    if [[ -z "$pack_version" ]]; then
        pack_version="$(_pack_version_from_readme)" || return 1
    fi
    if [[ -z "$pack_version" ]]; then
        err "could not determine pack version"
        return 1
    fi

    manifest="$root/docs/project/immutable-manifest.txt"
    tmp="$(mktemp "${TMPDIR:-/tmp}/immutable-manifest.XXXXXX")" || { err "mktemp failed"; return 1; }

    {
        printf '%s\n' '# immutable-manifest.txt — sha256 content checksums for client-immutable files'
        printf '%s\n' '# Generated at install time by the pack installer/updater; do not hand-edit.'
        printf '%s\n' "# pack-version: $pack_version"
        printf '%s\n' '# Format: <project-relative-path>  <sha256>'
        printf '%s\n' '#'
    } > "$tmp"

    while IFS= read -r rel; do
        [[ -n "$rel" ]] || continue
        file_path="$root/$rel"
        if [[ ! -f "$file_path" ]]; then
            err "installed immutable file missing: $file_path"
            rm -f "$tmp"
            return 1
        fi
        hash="$(_sha256_hex "$file_path")" || { err "hashing failed: $file_path"; rm -f "$tmp"; return 1; }
        if [[ -z "$hash" ]]; then
            err "empty hash for: $file_path"
            rm -f "$tmp"
            return 1
        fi
        printf '%s  %s\n' "$rel" "$hash" >> "$tmp"
    done <<EOF
$IMMUTABLE_PROJECT_RELS
EOF

    mkdir -p "$(dirname "$manifest")"
    # Write only when the CONTENT differs. `mv` always stamps a fresh mtime,
    # and this file is regenerated unconditionally on every install AND every
    # `--update`, so an otherwise no-op refresh still left the client one
    # modified file in `git status` every single run. The manifest is a
    # deterministic function of the installed immutable files, so identical
    # content means there is nothing to record.
    if [[ -f "$manifest" ]] && cmp -s "$tmp" "$manifest"; then
        rm -f "$tmp"
    else
        mv "$tmp" "$manifest"
    fi
    say "immutable-manifest: generated $manifest (pack-version: $pack_version)"
    return 0
}

main() {
    local client_tree="" pack_version=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --client-tree) client_tree="${2:-}"; shift 2 ;;
            --client-tree=*) client_tree="${1#*=}"; shift ;;
            --pack-version) pack_version="${2:-}"; shift 2 ;;
            --pack-version=*) pack_version="${1#*=}"; shift ;;
            -h|--help)
                say "Usage: bash scripts/immutable-manifest.sh --client-tree <root> [--pack-version vN.M]"
                exit 0
                ;;
            *)
                err "unknown argument: $1"
                exit 1
                ;;
        esac
    done

    if [[ -z "$client_tree" ]]; then
        err "no client tree given (expected --client-tree <root>)"
        exit 1
    fi

    _generate "$client_tree" "$pack_version"
    exit $?
}

main "$@"
