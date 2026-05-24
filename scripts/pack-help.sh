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
    # <!-- DENY-LIST-CONTENT-START -->
    cat <<'EOF'
Usage: pack-help.sh [--surface pack|client] [--root <path>]

Prints the pack verb manifest for the active surface. With no flags,
auto-detects surface from the working directory (per V3 §28.2.3:
BACKLOG.md with `^**BD-` entries → pack; with `^**TD-` entries →
client; ambiguous trees print both fragments).

Reads the appropriate HELP-FRAGMENT-*.md and inlines the sibling
HELP-FRAGMENT-TRACKER.md per V3 §28.2.4 / DELTA L1. Pack-side
fragments live at pack-ops/HELP-FRAGMENT-PACK.md and
pack-ops/HELP-FRAGMENT-TRACKER.md (BD-175 reorg).
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
    # Replace the sibling-include placeholder line with the tracker
    # fragment body. emit_fragment is dual-surface and must match both
    # call sites' sentinel forms:
    # <!-- DENY-LIST-CONTENT-START -->
    #   - Pack-side (call site L127):  pack-ops/HELP-FRAGMENT-PACK.md L37
    #       sentinel = `[Included from \`pack-ops/HELP-FRAGMENT-TRACKER.md\` ...]`
    #   - Client-side (call site L130-131): project-template/docs/pack/
    #       HELP-FRAGMENT.md L26 sentinel =
    #       `[Included from \`HELP-FRAGMENT-TRACKER.md\` ...]`
    # The `(pack-ops\/)?` optional group matches both. BD-177 originally
    # tightened this to a `pack-ops/`-only prefix, which silently broke
    # <!-- DENY-LIST-CONTENT-END -->
    # the client-side substitution (sentinel leaked into rendered output);
    # the BD-177 fix-pass broadened the pattern back to cover both
    # surfaces while keeping the pack-side path-accurate sentinel.
    awk -v tracker="$tracker_fragment" '
        /^\[Included from `(pack-ops\/)?HELP-FRAGMENT-TRACKER\.md`/ {
            while ((getline line < tracker) > 0) print line
            close(tracker)
            next
        }
        { print }
    ' "$fragment"
}

# <!-- DENY-LIST-CONTENT-START -->
# BD-175 reorg: pack-side fragments live at $root/pack-ops/ (canonical
# post-v11.0). Root-fallback retained so test fixtures (and unusual
# overlay trees) that materialise the fragment files at $root/ continue
# to resolve — same back-compat pattern as detect.sh::detect_pack_surface
# legacy-root fallback.
_pack_fragment_path() {
    if [[ -f "$root/pack-ops/HELP-FRAGMENT-PACK.md" ]]; then
        echo "$root/pack-ops/HELP-FRAGMENT-PACK.md"
    elif [[ -f "$root/HELP-FRAGMENT-PACK.md" ]]; then
        echo "$root/HELP-FRAGMENT-PACK.md"
    fi
}
_pack_tracker_fragment_path() {
    if [[ -f "$root/pack-ops/HELP-FRAGMENT-TRACKER.md" ]]; then
        echo "$root/pack-ops/HELP-FRAGMENT-TRACKER.md"
    elif [[ -f "$root/HELP-FRAGMENT-TRACKER.md" ]]; then
        echo "$root/HELP-FRAGMENT-TRACKER.md"
    fi
}
# <!-- DENY-LIST-CONTENT-END -->

case "$surface" in
    pack)
        pack_frag=$(_pack_fragment_path)
        tracker_frag=$(_pack_tracker_fragment_path)
        # <!-- DENY-LIST-CONTENT-START -->
        if [[ -z "$pack_frag" ]]; then
            # Fall back to canonical path for the error message that
            # emit_fragment will surface.
            pack_frag="$root/pack-ops/HELP-FRAGMENT-PACK.md"
        fi
        if [[ -z "$tracker_frag" ]]; then
            tracker_frag="$root/pack-ops/HELP-FRAGMENT-TRACKER.md"
        fi
        # <!-- DENY-LIST-CONTENT-END -->
        emit_fragment "$pack_frag" "$tracker_frag"
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
        pack_frag=$(_pack_fragment_path)
        tracker_frag=$(_pack_tracker_fragment_path)
        if [[ -n "$pack_frag" ]]; then
            # <!-- DENY-LIST-CONTENT-START -->
            [[ -z "$tracker_frag" ]] && tracker_frag="$root/pack-ops/HELP-FRAGMENT-TRACKER.md"
            # <!-- DENY-LIST-CONTENT-END -->
            emit_fragment "$pack_frag" "$tracker_frag"
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
