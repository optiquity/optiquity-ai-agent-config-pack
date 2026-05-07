#!/usr/bin/env bash
# scripts/pack-help.sh — `pack help` LCD shell verb (BD-075, V3 §28.2).
#
# Detects the active surface (pack vs client per V3 §28.2.3), reads the
# matching HELP-FRAGMENT-*.md, inlines the sibling HELP-FRAGMENT-TRACKER.md
# (DELTA L1 sibling-include), and prints to stdout.
#
# Usage:
#   pack help                         # auto-detect surface from cwd
#   pack help --surface pack|client   # explicit override
#   pack help --root <path>           # use <path> as the target tree (default: cwd)
#
# Output cost target: ~400 tokens per V3 §28.2.3.
#
# This is the LCD floor for D-20 / OQ-20 — it works on every CLI's
# terminal pane regardless of whether per-CLI slash commands have been
# installed yet. The per-CLI `/pack-help` skills/commands (BD-077)
# invoke this same script.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"
# shellcheck disable=SC1091
source "$LIB_DIR/detect.sh"

usage() {
    cat <<'EOF'
Usage: pack-help.sh [--surface pack|client] [--root <path>]

Prints the pack verb manifest for the active surface. With no flags,
auto-detects surface from the working directory (per V3 §28.2.3:
BACKLOG.md with `^**BD-` entries → pack; with `^**TD-` entries →
client; ambiguous trees print both fragments).

Reads the appropriate HELP-FRAGMENT-*.md and inlines the sibling
HELP-FRAGMENT-TRACKER.md per V3 §28.2.4 / DELTA L1.
EOF
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

# emit_fragment <fragment-path> <tracker-fragment-path>
# Reads <fragment-path> and inlines the sibling tracker fragment in
# place of the placeholder line. Prints to stdout. Returns 1 if the
# top-level fragment is missing.
emit_fragment() {
    local fragment="$1"
    local tracker_fragment="$2"
    if [[ ! -f "$fragment" ]]; then
        echo "pack-help: fragment not found at $fragment" >&2
        return 1
    fi
    if [[ ! -f "$tracker_fragment" ]]; then
        # Print the fragment verbatim — placeholder line stays. Surface
        # the missing-tracker situation on stderr (informational; not
        # a hard error since the user can still read the rest).
        echo "pack-help: tracker fragment not found at $tracker_fragment (printing top-level fragment only)" >&2
        cat "$fragment"
        return 0
    fi
    # The placeholder line is `[Included from \`HELP-FRAGMENT-TRACKER.md\` ...]`.
    # Replace exactly that one line with the tracker fragment body.
    awk -v tracker="$tracker_fragment" '
        /^\[Included from `HELP-FRAGMENT-TRACKER\.md`/ {
            while ((getline line < tracker) > 0) print line
            close(tracker)
            next
        }
        { print }
    ' "$fragment"
}

case "$surface" in
    pack)
        emit_fragment "$root/HELP-FRAGMENT-PACK.md" \
                      "$root/HELP-FRAGMENT-TRACKER.md"
        ;;
    client)
        emit_fragment "$root/docs/pack/HELP-FRAGMENT.md" \
                      "$root/docs/pack/HELP-FRAGMENT-TRACKER.md"
        ;;
    ambiguous|"")
        # No clear signal: print pack-side first if its fragment exists,
        # then client-side (separated by a divider). Either or both may
        # be missing in unusual layouts; emit_fragment surfaces either
        # case to stderr without aborting.
        local_emit_count=0
        if [[ -f "$root/HELP-FRAGMENT-PACK.md" ]]; then
            emit_fragment "$root/HELP-FRAGMENT-PACK.md" \
                          "$root/HELP-FRAGMENT-TRACKER.md"
            local_emit_count=$((local_emit_count + 1))
        fi
        if [[ -f "$root/docs/pack/HELP-FRAGMENT.md" ]]; then
            if (( local_emit_count > 0 )); then
                echo
                echo "─── client surface ───"
                echo
            fi
            emit_fragment "$root/docs/pack/HELP-FRAGMENT.md" \
                          "$root/docs/pack/HELP-FRAGMENT-TRACKER.md"
            local_emit_count=$((local_emit_count + 1))
        fi
        if (( local_emit_count == 0 )); then
            echo "pack-help: no HELP-FRAGMENT-*.md found under $root" >&2
            echo "pack-help: expected HELP-FRAGMENT-PACK.md (pack repo) or" >&2
            echo "           docs/pack/HELP-FRAGMENT.md (client project)." >&2
            exit 1
        fi
        ;;
    *)
        echo "pack-help: surface must be pack|client; got '$surface'" >&2
        exit 1
        ;;
esac
