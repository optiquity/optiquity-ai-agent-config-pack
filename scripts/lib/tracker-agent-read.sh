# scripts/lib/tracker-agent-read.sh — LCD agent read path (V1 §8.1).
# (BD-071 D-9 implementation)
#
# Per V1 §8.1: agents have a Bash tool. Their read of pack-managed
# entries (BD-NNN, TD-NNN, phase-N, phase-N.M) goes through this
# script, which is mode-agnostic at the agent's surface:
#   - flat-file mode: greps the BACKLOG.md mirror for the entry block
#   - tracker mode:   resolves pack-id → gh-id via the mapping file,
#                     then `provider_get`
#
# This script is BOTH sourced and executed:
#   - Sourced by libs that want the public function inside an existing
#     bash environment.
#   - Executed by agents as a one-shot:
#       bash scripts/lib/tracker-agent-read.sh BD-001 [<repo-root>]
#     The script emits the entry's content to stdout in markdown.
#
# Public API:
#   - tracker_agent_read_entry <pack-id> [<repo-root>]
#       Reads one entry. Mode-agnostic. Emits to stdout.
#   - tracker_agent_read_mode [<repo-root>]
#       Emits the active mode ("flat-file" or "tracker") on stdout.
#       Useful for agent prompts that want to branch their report
#       wording but rely on this lib for the actual data read.
#
# Reference: ARCHITECTURE.md §8.1, §8.4, §8.5; ARCHITECTURE-V3.md
# (D-9 LCD agent read path).
#
# Bash 3.2 compatible (macOS default).

# Source siblings idempotently when this file is sourced. When run
# directly we still need them — the same source-block runs in both
# modes since `declare -f` checks are cheap.
_tar_self="${BASH_SOURCE[0]:-$0}"
_tar_dir="$(cd "$(dirname "$_tar_self")" && pwd)"

# shellcheck disable=SC1091
[[ -z "$(declare -f tracker_error_emit 2>/dev/null)" ]] && \
    source "$_tar_dir/tracker-errors.sh"
# shellcheck disable=SC1091
[[ -z "$(declare -f tracker_mode 2>/dev/null)" ]] && \
    source "$_tar_dir/tracker-config.sh"
# shellcheck disable=SC1091
[[ -z "$(declare -f provider_get 2>/dev/null)" ]] && {
    source "$_tar_dir/tracker-provider.sh"
    source "$_tar_dir/tracker-provider-gh.sh"
}
unset _tar_self _tar_dir

# ─────────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────────

# tracker_agent_read_mode [<repo-root>]
# Emits the active mode on stdout. Defaults to flat-file when the
# tracker.toml is absent.
tracker_agent_read_mode() {
    local repo_root="${1:-$(pwd)}"
    local cfg_path surface
    surface=$(tracker_config_auto_surface "$repo_root" 2>/dev/null) || surface="pack"
    cfg_path=$(tracker_config_resolve_path "$surface" "$repo_root" 2>/dev/null) || {
        echo "flat-file"
        return 0
    }
    tracker_mode "$cfg_path"
}

# tracker_agent_read_entry <pack-id> [<repo-root>]
# Reads one entry. Returns 1 with typed error if not found.
tracker_agent_read_entry() {
    local pack_id="$1"
    local repo_root="${2:-$(pwd)}"

    if [[ -z "$pack_id" ]]; then
        tracker_error_emit "validation" "agent_read: pack-id required"
        return 1
    fi
    if [[ ! -d "$repo_root" ]]; then
        tracker_error_emit "validation" "agent_read: repo-root not a directory: $repo_root"
        return 1
    fi

    local mode
    mode=$(tracker_agent_read_mode "$repo_root")

    case "$mode" in
        tracker)
            _tar_read_entry_tracker "$pack_id" "$repo_root"
            ;;
        flat-file|*)
            _tar_read_entry_flat "$pack_id" "$repo_root"
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────────
# Private: tracker-mode read
# ─────────────────────────────────────────────────────────────────

_tar_read_entry_tracker() {
    local pack_id="$1"
    local repo_root="$2"

    local mapping_file mapping gh_id cfg_path surface
    mapping_file="$repo_root/.pack-tracker/id-map.json"
    if [[ ! -f "$mapping_file" ]]; then
        tracker_error_emit "not-found" \
            "agent_read: tracker mode but mapping file absent at $mapping_file"
        return 1
    fi
    mapping=$(cat "$mapping_file")
    gh_id=$(printf '%s' "$mapping" | jq -r --arg k "$pack_id" \
        'if has($k) then .[$k].id else empty end')
    if [[ -z "$gh_id" || "$gh_id" == "null" ]]; then
        tracker_error_emit "not-found" \
            "agent_read: $pack_id not in mapping (tracker mode)"
        return 1
    fi

    surface=$(tracker_config_auto_surface "$repo_root" 2>/dev/null) || surface="pack"
    cfg_path=$(tracker_config_resolve_path "$surface" "$repo_root" 2>/dev/null) || cfg_path=""
    [[ -n "$cfg_path" ]] && export _TRACKER_PROVIDER_CONFIG_PATH="$cfg_path"

    local issue
    if ! issue=$(provider_get "$gh_id" 2>/dev/null); then
        tracker_error_emit "not-found" \
            "agent_read: provider_get failed for $pack_id (gh #$gh_id)"
        return 1
    fi
    # Format: header line + body. Mirrors the flat-file shape so
    # agents see equivalent output across modes.
    local title body status
    title=$(printf  '%s' "$issue" | jq -r '.title // ""')
    body=$(printf   '%s' "$issue" | jq -r '.body // ""')
    # Normalize state to lowercase per V1 §2.2 canonical Issue shape.
    # gh CLI emits OPEN/CLOSED uppercase; the canonical form is
    # lowercase. Cross-mode `Source:` annotations now consistently use
    # lowercase (PACK-REVIEW-BD062-069-071 #19 closure).
    status=$(printf '%s' "$issue" | jq -r '.state // "open" | ascii_downcase')

    cat <<EOF
**$title**
Source: tracker (gh #$gh_id, state=$status)

$body
EOF
}

# ─────────────────────────────────────────────────────────────────
# Private: flat-file read
# ─────────────────────────────────────────────────────────────────

_tar_read_entry_flat() {
    local pack_id="$1"
    local repo_root="$2"

    # BD-167 (per-entry split, mandatory v11.0): prefer the per-entry
    # file when the per-entry tree exists for the stream this pack-id
    # belongs to. Fall back to the regenerated mirror for backward
    # compatibility with pre-v11.0 clients (which have no per-entry
    # tree; the mirror IS source of truth there).
    #
    # Mode-awareness per ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-
    # ADDENDUM.md §3.2: the prefer-then-fall-back logic is independent
    # of tracker mode (this function is the flat-file leg; tracker
    # mode goes through _tar_read_entry_tracker). The per-entry tree
    # is source of truth in flat-file mode (Mode 2) and a regenerated
    # mirror of tracker state in tracker mode (Mode 3) — but tracker
    # mode does not call this function, so the per-entry-prefer
    # behavior here is correct for the flat-file leg in both modes.
    #
    # Per ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §6.3 + §18.1 #10:
    # extend the existing function rather than add a sibling.
    # Per §18.2 #2: backward-compatibility for pre-v11.0 clients via
    # mirror fallback when no per-entry tree present.
    #
    # Stream resolution from pack-id prefix:
    #   BD-NNN     → pack backlog tree at $repo_root/backlog/
    #   TD-NNN     → project backlog tree at
    #                $repo_root/docs/project/backlog/
    #   phase-N    → project implementation-plan tree at
    #                $repo_root/docs/project/implementation-plan/
    #   phase-N.M  → also project implementation-plan tree (tasks
    #                live inline in their phase-N.md per
    #                ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-
    #                ADDENDUM.md §6.4 BD-167 spec; reduce to phase-N
    #                file lookup).
    local per_entry_dir="" per_entry_file="" per_entry_id="$pack_id"
    case "$pack_id" in
        BD-*)
            per_entry_dir="$repo_root/backlog"
            per_entry_file="$per_entry_dir/$pack_id.md"
            ;;
        TD-*)
            per_entry_dir="$repo_root/docs/project/backlog"
            per_entry_file="$per_entry_dir/$pack_id.md"
            ;;
        phase-*)
            per_entry_dir="$repo_root/docs/project/implementation-plan"
            # Per Addendum §6.4 BD-167 spec: tasks inline; phase-N.M
            # lookups resolve to the phase-N.md file.
            case "$pack_id" in
                phase-*.*)
                    per_entry_id="${pack_id%%.*}"
                    ;;
            esac
            per_entry_file="$per_entry_dir/$per_entry_id.md"
            ;;
    esac

    if [[ -n "$per_entry_dir" && -d "$per_entry_dir" \
       && -f "$per_entry_file" ]]; then
        # Per-entry tree exists AND per-entry file is present —
        # source of truth in flat-file mode. Read the per-entry file
        # directly. Strip the line-1 HTML-comment back-pointer per
        # ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2.md §2
        # (the comment is meaningful only on the per-entry file as a
        # recovery anchor; agent-readable output should be the
        # byte-identical entry span starting at the bold-header /
        # H2 / H3).
        printf 'Source: flat-file (per-entry: %s)\n\n' "$per_entry_file"
        python3 - "$per_entry_file" <<'PYEOF' || return 1
import re, sys
path = sys.argv[1]
try:
    with open(path) as f:
        text = f.read()
except OSError as e:
    sys.stderr.write("ERROR: not-found\nMESSAGE: %s\n→ Run: verify the issue id and re-run\n" % e)
    sys.exit(1)
# Strip the line-1 HTML-comment back-pointer if present
# (Addendum #2 §2 — line-1 only, ABOVE the byte-identical span).
lines = text.split('\n', 1)
if lines and re.match(r'^<!-- per-entry source: .*; contract: .* -->\s*$', lines[0]):
    text = lines[1] if len(lines) > 1 else ''
# Drop a single leading blank line that may sit between the
# back-pointer and the entry header (defensive, idempotent on files
# without the leading blank).
if text.startswith('\n'):
    text = text[1:]
sys.stdout.write(text.rstrip())
sys.stdout.write('\n')
PYEOF
        return 0
    fi

    # Fall through: per-entry tree absent OR per-entry file missing.
    # Per-stream-aware fallback selection mirroring the prefer-branch's
    # stream resolution above:
    #   BD-*     → pack per-entry tree IS the SSOT; NO monolith fallback
    #   TD-*     → project mirror docs/project/BACKLOG.md
    #   phase-*  → project mirror docs/project/IMPLEMENTATION-PLAN.md
    #   *        → pack surface (unknown prefix); NO monolith fallback
    #
    # BD-204 C-6 (C4 REPOINT): the pack monolith `pack-ops/BACKLOG.md`
    # is DELETED (BD-203 no-mirror SSOT). The pack-surface read path is
    # the per-entry tree handled by the prefer-branch above — when that
    # branch did not resolve the entry there is NO monolith to fall
    # back to, so the pack-surface fall-through (BD-* and the `*)`
    # unknown-prefix default) fails loud with a typed not-found error
    # rather than reading a deleted file. The project-side TD-* /
    # phase-* mirror fallback is UNTOUCHED (BD-207 owns the project
    # tree repoint): clients still ship those monolith mirrors.
    # Single-pass dispatch: the two pack-surface fall-through arms
    # (BD-* and the `*)` unknown-prefix default) fail loud with a typed
    # not-found (no monolith fallback); only TD-*/phase- proceed to the
    # project mirror block below. (BD-204 C-6-FIX1 / NIT-1: previously a
    # no-op `case` arm followed by a separate `if BD-*` error block —
    # consolidated to one `case` for clarity; behavior unchanged.)
    local mirror_path=""
    case "$pack_id" in
        BD-*)
            tracker_error_emit "not-found" \
                "agent_read: $pack_id not found in pack per-entry tree at $repo_root/backlog/$pack_id.md (no monolith fallback — BD-203 no-mirror SSOT)"
            return 1
            ;;
        TD-*)    mirror_path="$repo_root/docs/project/BACKLOG.md" ;;
        phase-*) mirror_path="$repo_root/docs/project/IMPLEMENTATION-PLAN.md" ;;
        *)
            tracker_error_emit "not-found" \
                "agent_read: $pack_id not found in pack per-entry tree at $repo_root/backlog (no monolith fallback — BD-203 no-mirror SSOT)"
            return 1
            ;;
    esac
    if [[ ! -f "$mirror_path" ]]; then
        tracker_error_emit "not-found" \
            "agent_read: mirror not found at $mirror_path for $pack_id"
        return 1
    fi
    python3 - "$mirror_path" "$pack_id" <<'PYEOF' || return 1
import os, re, sys
path, pack_id = sys.argv[1], sys.argv[2]
try:
    with open(path) as f:
        text = f.read()
except OSError as e:
    sys.stderr.write("ERROR: not-found\nMESSAGE: %s\n→ Run: verify the issue id and re-run\n" % e)
    sys.exit(1)
# Match the entry header: **PACK_ID — Title**
pat = re.compile(r'^\*\*' + re.escape(pack_id) + r'\s*[—-]\s*.+?\*\*\s*$', re.M)
m = pat.search(text)
if not m:
    sys.stderr.write("ERROR: not-found\nMESSAGE: %s not found in %s\n→ Run: verify the issue id and re-run\n" % (pack_id, os.path.basename(path)))
    sys.exit(1)
start = m.start()
# End is the next `---` separator or next `**X-NNN —` header, whichever first.
nxt_sep = re.search(r'^---\s*$', text[m.end():], re.M)
nxt_hdr = re.search(r'^\*\*[A-Z]+-[0-9]+', text[m.end():], re.M)
candidates = [c.start() for c in (nxt_sep, nxt_hdr) if c]
end = m.end() + (min(candidates) if candidates else len(text) - m.end())
print("Source: flat-file (%s)\n" % os.path.basename(path))
print(text[start:end].rstrip())
PYEOF
}

# ─────────────────────────────────────────────────────────────────
# Direct-execution entrypoint
# ─────────────────────────────────────────────────────────────────

# When invoked directly (not sourced), treat $1 as pack-id, $2 as
# optional repo-root.
if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
    if [[ $# -lt 1 ]]; then
        cat >&2 <<EOF
Usage: bash $0 <pack-id> [<repo-root>]

Reads one pack-managed entry (BD-NNN, TD-NNN, phase-N, phase-N.M).
Mode-agnostic — reads from the flat-file mirror in flat-file mode
and from the tracker in tracker mode (resolved via the trinity
\`## Document locations\` table semantically; technically via the
mapping file at .pack-tracker/id-map.json).
EOF
        exit 1
    fi
    tracker_agent_read_entry "$@"
fi
