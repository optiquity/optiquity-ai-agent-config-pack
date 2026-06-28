#!/usr/bin/env bash
# verify-immutable.sh — client-side integrity check for pack-shipped immutable files.
#
# Hashes each INSTALLED docs/project/.../_rules.md against the sha256 content
# checksum the pack shipped in docs/project/immutable-manifest.txt. A mismatch
# means an immutable contract file drifted from the pack baseline after install
# (an agent edit, a stray sed) — verify-immutable.sh fails LOUD, naming the file.
#
# This is the client twin of pack-side Check 76 (scripts/validate-pack.py). It
# is UNCONDITIONAL: it hashes-and-compares with NO version gate. The client
# received exactly ONE manifest + _rules.md baseline at install and has no pack
# README to gate against. The manifest's `# pack-version:` header is echoed as
# informational output only; it is NOT used to skip or relax any check.
#
# Threat model: this is tamper-EVIDENT for accidental drift (the common,
# honest-CI case), not tamper-PROOF — a client editing BOTH an installed
# _rules.md AND its manifest to a consistent pair is out of model.
#
# Reads ONLY shipped/installed files (no pack repo, no network).
#
# Usage:
#   bash scripts/verify-immutable.sh
# Exit 0 when every immutable file matches the manifest; exit 1 on any
# mismatch, missing file, missing/malformed manifest, or hashing failure.

set -u

# ── Locate the install root + the shipped manifest ────────────────────────────
# This script ships to <project>/scripts/verify-immutable.sh, so the project
# root is one level up; the manifest is at docs/project/immutable-manifest.txt.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$PROJECT_ROOT/docs/project/immutable-manifest.txt"

err() { printf 'verify-immutable: error: %s\n' "$*" >&2; }

# ── Portable sha256 of a file → 64-hex, no filename ──────────────────────────
# Prefer shasum -a 256 (BSD/macOS), then sha256sum (GNU/Linux), then python3
# hashlib. All three emit "<hash>  <name>"; we split and take field 1. Mirrors
# the pack-side generator (scripts/immutable-manifest.sh) for parser symmetry.
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

main() {
    if [[ ! -f "$MANIFEST" ]]; then
        err "manifest not found: $MANIFEST"
        err "expected the pack-shipped docs/project/immutable-manifest.txt; run the pack installer/updater to restore it."
        exit 1
    fi

    local pack_version="(unknown)"
    local checked=0 mismatches=0 rel hash_expected hash_actual file_path

    # Read line-by-line: capture the `# pack-version:` header (informational),
    # skip comments/blanks, and verify each `<project-rel-path>  <sha256>` row.
    while IFS= read -r line || [[ -n "$line" ]]; do
        case "$line" in
            "# pack-version:"*)
                # Trim the prefix + surrounding whitespace for the echo.
                pack_version="${line#\# pack-version:}"
                pack_version="${pack_version# }"
                continue
                ;;
            \#*|"")
                continue
                ;;
        esac

        # Whitespace-split into path + expected hash (fields 1 and 2).
        rel="${line%%[[:space:]]*}"
        hash_expected="${line##*[[:space:]]}"

        if [[ -z "$rel" || -z "$hash_expected" || "$rel" == "$hash_expected" ]]; then
            err "malformed manifest row: $line"
            exit 1
        fi
        # The hash must be 64 lowercase hex chars (sha256).
        case "$hash_expected" in
            *[!0-9a-f]*|"")
                err "malformed sha256 in manifest row: $line"
                exit 1
                ;;
        esac
        if [[ ${#hash_expected} -ne 64 ]]; then
            err "malformed sha256 (expected 64 hex chars) in manifest row: $line"
            exit 1
        fi

        file_path="$PROJECT_ROOT/$rel"
        if [[ ! -f "$file_path" ]]; then
            err "immutable file missing: $rel"
            mismatches=$((mismatches + 1))
            checked=$((checked + 1))
            continue
        fi

        hash_actual="$(_sha256_hex "$file_path")" || { err "hashing failed: $rel"; exit 1; }
        if [[ -z "$hash_actual" ]]; then
            err "empty hash computed for: $rel"
            exit 1
        fi

        checked=$((checked + 1))
        if [[ "$hash_actual" != "$hash_expected" ]]; then
            mismatches=$((mismatches + 1))
            err "INTEGRITY MISMATCH: $rel"
            err "  expected: $hash_expected"
            err "  actual:   $hash_actual"
        fi
    done < "$MANIFEST"

    if [[ "$checked" -eq 0 ]]; then
        err "no immutable-file rows found in manifest: $MANIFEST"
        exit 1
    fi

    if [[ "$mismatches" -gt 0 ]]; then
        printf 'verify-immutable: FAIL — %d of %d immutable file(s) differ from the pack baseline (pack-version: %s).\n' \
            "$mismatches" "$checked" "$pack_version" >&2
        exit 1
    fi

    printf 'verify-immutable: OK — %d immutable file(s) match the pack baseline (pack-version: %s).\n' \
        "$checked" "$pack_version"
    exit 0
}

main "$@"
