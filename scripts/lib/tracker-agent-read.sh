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
    local backlog="$repo_root/BACKLOG.md"
    if [[ ! -f "$backlog" ]]; then
        tracker_error_emit "not-found" \
            "agent_read: BACKLOG.md not found at $backlog"
        return 1
    fi
    python3 - "$backlog" "$pack_id" <<'PYEOF' || return 1
import re, sys
path, pack_id = sys.argv[1], sys.argv[2]
try:
    with open(path) as f:
        text = f.read()
except OSError as e:
    sys.stderr.write("ERROR: not-found\nMESSAGE: %s\n" % e)
    sys.exit(1)
# Match the entry header: **PACK_ID — Title**
pat = re.compile(r'^\*\*' + re.escape(pack_id) + r'\s*[—-]\s*.+?\*\*\s*$', re.M)
m = pat.search(text)
if not m:
    sys.stderr.write("ERROR: not-found\nMESSAGE: %s not found in BACKLOG.md\n" % pack_id)
    sys.exit(1)
start = m.start()
# End is the next `---` separator or next `**X-NNN —` header, whichever first.
nxt_sep = re.search(r'^---\s*$', text[m.end():], re.M)
nxt_hdr = re.search(r'^\*\*[A-Z]+-[0-9]+', text[m.end():], re.M)
candidates = [c.start() for c in (nxt_sep, nxt_hdr) if c]
end = m.end() + (min(candidates) if candidates else len(text) - m.end())
print("Source: flat-file (BACKLOG.md)\n")
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
