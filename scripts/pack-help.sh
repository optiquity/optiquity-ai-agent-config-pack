#!/usr/bin/env bash
# scripts/pack-help.sh — `pack help` LCD shell verb.
#
# Detects the active surface (pack vs client), reads the matching
# HELP-FRAGMENT-*.md, and prints to stdout.
#
# Usage:
#   pack help                         # auto-detect surface from cwd
#   pack help --surface pack|client   # explicit override
#   pack help --root <path>           # use <path> as the target tree (default: cwd)
#
# Output cost target: ~400 tokens.
#
# This is the lowest-common-denominator floor — it works on every CLI's
# terminal pane regardless of whether per-CLI slash commands have been
# installed yet. The per-CLI `/pack-help` skills/commands invoke this
# same script.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"
# shellcheck disable=SC1091
source "$LIB_DIR/detect.sh"

usage() {
    # <!-- DENY-LIST-CONTENT-START -->
    cat <<'EOF'
Usage: pack-help.sh [--surface pack|client] [--root <path>]

Prints the pack verb manifest for the active surface. With no flags,
auto-detects surface from the working directory (a `backlog/` per-entry
tree with `BD-NNN.md` entries → pack; a `docs/project/backlog/`
per-entry tree with `TD-NNN.md` entries → client; a legacy `BACKLOG.md`
monolith with `^**BD-`/`^**TD-` entries is the pre-v11 fallback;
ambiguous trees print both fragments).

Reads the appropriate HELP-FRAGMENT-*.md. The pack-side fragment lives
at pack-ops/HELP-FRAGMENT-PACK.md.
EOF
    # <!-- DENY-LIST-CONTENT-END -->
}

surface=""
root="$(pwd)"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --surface) surface="$2"; shift 2 ;;
        --root)    root="$2";    shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *)
            echo "pack-help: unknown option '$1'" >&2
            usage >&2
            exit 1
            ;;
    esac
done

# Resolve the auto-detected surface when not explicit. detect_pack_surface
# returns "pack-surface: pack|client|ambiguous"; strip the prefix.
if [[ -z "$surface" ]]; then
    surface="$(detect_pack_surface "$root" | sed 's/^pack-surface: //')"
fi

# emit_fragment <fragment-path>
# Reads <fragment-path> and prints it to stdout. Returns 1 if the
# fragment is missing.
emit_fragment() {
    local fragment="$1"
    if [[ ! -f "$fragment" ]]; then
        echo "pack-help: fragment not found at $fragment" >&2
        return 1
    fi
    cat "$fragment"
}

# <!-- DENY-LIST-CONTENT-START -->
# Pack-side fragments live at $root/pack-ops/ (canonical). Root-fallback
# retained so test fixtures (and unusual overlay trees) that materialise
# the fragment files at $root/ continue to resolve — same back-compat
# pattern as detect.sh::detect_pack_surface legacy-root fallback.
_pack_fragment_path() {
    if [[ -f "$root/pack-ops/HELP-FRAGMENT-PACK.md" ]]; then
        echo "$root/pack-ops/HELP-FRAGMENT-PACK.md"
    elif [[ -f "$root/HELP-FRAGMENT-PACK.md" ]]; then
        echo "$root/HELP-FRAGMENT-PACK.md"
    fi
}
# <!-- DENY-LIST-CONTENT-END -->

case "$surface" in
    pack)
        pack_frag=$(_pack_fragment_path)
        # <!-- DENY-LIST-CONTENT-START -->
        if [[ -z "$pack_frag" ]]; then
            # Fall back to canonical path for the error message that
            # emit_fragment will surface.
            pack_frag="$root/pack-ops/HELP-FRAGMENT-PACK.md"
        fi
        # <!-- DENY-LIST-CONTENT-END -->
        emit_fragment "$pack_frag"
        ;;
    client)
        emit_fragment "$root/docs/pack/HELP-FRAGMENT.md"
        ;;
    ambiguous|"")
        # No clear signal: print pack-side first if its fragment exists,
        # then client-side (separated by a divider). Either or both may
        # be missing in unusual layouts; emit_fragment surfaces either
        # case to stderr without aborting.
        local_emit_count=0
        pack_frag=$(_pack_fragment_path)
        if [[ -n "$pack_frag" ]]; then
            emit_fragment "$pack_frag"
            local_emit_count=$((local_emit_count + 1))
        fi
        if [[ -f "$root/docs/pack/HELP-FRAGMENT.md" ]]; then
            if (( local_emit_count > 0 )); then
                echo
                echo "─── client surface ───"
                echo
            fi
            emit_fragment "$root/docs/pack/HELP-FRAGMENT.md"
            local_emit_count=$((local_emit_count + 1))
        fi
        if (( local_emit_count == 0 )); then
            echo "pack-help: no HELP-FRAGMENT-*.md found under $root" >&2
            # <!-- DENY-LIST-CONTENT-START -->
            echo "pack-help: expected pack-ops/HELP-FRAGMENT-PACK.md (pack repo) or" >&2
            # <!-- DENY-LIST-CONTENT-END -->
            echo "           docs/pack/HELP-FRAGMENT.md (client project)." >&2
            exit 1
        fi
        ;;
    *)
        echo "pack-help: surface must be pack|client; got '$surface'" >&2
        exit 1
        ;;
esac
