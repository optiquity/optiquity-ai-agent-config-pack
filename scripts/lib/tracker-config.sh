# scripts/lib/tracker-config.sh — tracker.toml schema reader and
# mode detection (V1 §3.1 + §3.2).
#
# Sourced by migration scripts, pack-startup / pm-startup / tracker-
# startup skills, and tracker-provider.sh's dispatcher.
#
# Provides:
#   - tracker_config_resolve_path <surface> <root>
#       surface: "pack" | "client"
#       Pack root:    <root>/tracker.toml
#       Client root:  <root>/docs/pack/tracker.toml
#   - tracker_config_read <path>
#       Parses tracker.toml; emits a flat JSON dotted-key map on stdout.
#       Returns 1 on missing file or parse error, with a typed-error
#       block on stderr (V1 §2.5 codes).
#   - tracker_config_get <path> <dotted-key>
#       Convenience: emit a single value; rc=1 if absent.
#   - tracker_mode <path>
#       Implements V1 §3.2 detection algorithm verbatim. Always rc=0;
#       emits "tracker" or "flat-file".
#   - tracker_backend_name <path>     → backend.name
#   - tracker_repo_slug <path>        → backend.repo
#   - tracker_id_prefix <path>        → id_namespace.prefix
#   - tracker_schema_version_check <path>
#       rc=0 if schema_version == 1; rc=1 + typed error otherwise.
#
# Schema reference: ARCHITECTURE.md §3.1.
# Detection reference: ARCHITECTURE.md §3.2.
#
# Implementation note: the parser is a tiny regex-based reader, not a
# full TOML parser. Our schema is flat (one section level, no arrays,
# no inline tables, no multiline strings), so a minimal parser is
# sufficient and avoids the Python tomllib (3.11+) / tomli (extra dep)
# fork. The parser tolerates the non-standard `null` literal that
# appears in V1 §3.1's example for unset timestamps; real TOML omits
# the key instead, and the example files we ship use commented-out
# placeholders. If schema grows to need real TOML, swap to tomllib.
#
# Errors emitted via tracker_error_emit (scripts/lib/tracker-errors.sh,
# sourced at load time; BD-070).
#
# Do NOT add a shebang — this file is sourced, not executed.

# Source the typed-error formatter. Idempotent: tracker-errors.sh has
# no top-level side effects beyond function definitions.
# shellcheck disable=SC1091
if ! declare -f tracker_error_emit >/dev/null 2>&1; then
    _tcfg_self="${BASH_SOURCE[0]}"
    _tcfg_dir="$(cd "$(dirname "$_tcfg_self")" && pwd)"
    source "$_tcfg_dir/tracker-errors.sh"
    unset _tcfg_self _tcfg_dir
fi

# Currently supported schema version. Bumped only on incompatible
# tracker.toml schema changes; minor additive changes do not bump.
readonly TRACKER_CONFIG_SCHEMA_VERSION=1

# ─────────────────────────────────────────────────────────────────
# Path resolution
# ─────────────────────────────────────────────────────────────────

# tracker_config_resolve_path <surface> <root>
# Emits the canonical path to tracker.toml for the given surface,
# regardless of whether the file exists.
tracker_config_resolve_path() {
    local surface="$1"
    local root="$2"
    if [[ -z "$surface" || -z "$root" ]]; then
        tracker_error_emit "validation" "resolve_path: surface and root required"
        return 1
    fi
    case "$surface" in
        pack)   echo "$root/tracker.toml" ;;
        client) echo "$root/docs/pack/tracker.toml" ;;
        *)
            tracker_error_emit "validation" "resolve_path: unknown surface '$surface' (expected pack|client)"
            return 1
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────────
# Reader
# ─────────────────────────────────────────────────────────────────

# tracker_config_read <path>
# Emits flat dotted-key JSON: {"schema_version": 1, "backend.name": "github", ...}
tracker_config_read() {
    local path="$1"
    if [[ -z "$path" ]]; then
        tracker_error_emit "validation" "read: path required"
        return 1
    fi
    if [[ ! -f "$path" ]]; then
        tracker_error_emit "not-found" "tracker.toml not present at $path"
        return 1
    fi
    python3 - "$path" <<'PYEOF'
import re, json, sys
path = sys.argv[1]
data = {}
section = ""
try:
    with open(path) as f:
        text = f.read()
except OSError as e:
    sys.stderr.write("ERROR: validation\nMESSAGE: %s\n→ Run: review the backend message above\n" % e)
    sys.exit(1)

for raw_line in text.splitlines():
    line = raw_line.strip()
    if not line or line.startswith("#"):
        continue
    m = re.match(r'^\[([A-Za-z0-9_]+)\]$', line)
    if m:
        section = m.group(1)
        continue
    # Strip trailing inline comment, but only when the # is outside
    # any quoted string (heuristic: balanced quotes in the prefix).
    parts = line.split('#', 1)
    candidate = parts[0]
    if candidate.count('"') % 2 == 1:
        candidate = line
    line = candidate.strip()
    if not line:
        continue
    m = re.match(r'^([A-Za-z_][A-Za-z0-9_-]*)\s*=\s*(.+?)\s*$', line)
    if not m:
        sys.stderr.write("ERROR: validation\nMESSAGE: cannot parse line: %r\n→ Run: review the backend message above\n" % raw_line)
        sys.exit(1)
    key, raw = m.group(1), m.group(2)
    if raw == "true":
        val = True
    elif raw == "false":
        val = False
    elif raw == "null":
        val = None
    elif len(raw) >= 2 and raw[0] == '"' and raw[-1] == '"':
        val = raw[1:-1]
    elif re.match(r'^-?\d+$', raw):
        val = int(raw)
    else:
        sys.stderr.write("ERROR: validation\nMESSAGE: unrecognized value %r on line: %r\n→ Run: review the backend message above\n" % (raw, raw_line))
        sys.exit(1)
    full_key = ("%s.%s" % (section, key)) if section else key
    data[full_key] = val

print(json.dumps(data))
PYEOF
}

# tracker_config_get <path> <dotted-key>
# Emits the value as a string; rc=1 if absent or read fails.
tracker_config_get() {
    local path="$1"
    local key="$2"
    if [[ -z "$path" || -z "$key" ]]; then
        tracker_error_emit "validation" "get: path and key required"
        return 1
    fi
    local data
    data=$(tracker_config_read "$path") || return 1
    local val
    val=$(printf '%s' "$data" | jq -r --arg k "$key" 'if has($k) then .[$k] else empty end')
    if [[ -z "$val" ]]; then
        return 1
    fi
    echo "$val"
}

# ─────────────────────────────────────────────────────────────────
# V1 §3.2 mode detection
# ─────────────────────────────────────────────────────────────────

# tracker_mode <path>
# Implements V1 §3.2 verbatim. Always rc=0 — the algorithm is
# deliberately tolerant: any failure to interpret the file as
# tracker-mode falls back to "flat-file".
tracker_mode() {
    local path="$1"
    if [[ -z "$path" ]] || [[ ! -f "$path" ]]; then
        echo "flat-file"
        return 0
    fi
    local data
    if ! data=$(tracker_config_read "$path" 2>/dev/null); then
        echo "flat-file"
        return 0
    fi
    local state forward
    state=$(printf '%s' "$data"   | jq -r '."mode.state" // empty')
    forward=$(printf '%s' "$data" | jq -r '."migration.forward_complete" // empty')
    if [[ "$state" != "tracker" ]]; then
        echo "flat-file"
        return 0
    fi
    if [[ "$forward" != "true" ]]; then
        echo "flat-file"
        return 0
    fi
    echo "tracker"
}

# ─────────────────────────────────────────────────────────────────
# Convenience getters
# ─────────────────────────────────────────────────────────────────

tracker_backend_name() { tracker_config_get "$1" "backend.name"; }
tracker_repo_slug()    { tracker_config_get "$1" "backend.repo"; }
tracker_id_prefix()    { tracker_config_get "$1" "id_namespace.prefix"; }
tracker_mapping_file() { tracker_config_get "$1" "migration.mapping_file"; }

# tracker_config_auto_surface <repo-root>
# Auto-detect pack vs client surface based on filesystem markers:
#   - PACK-CHAT.md present → pack
#   - docs/pack/ present   → client
# Emits "pack" or "client" on stdout. Returns 1 with typed validation
# error when neither marker is present (caller can fall back to a
# user prompt or a --surface override).
#
# Used by status / disable / doctor / mirror-rebuild verb wrappers
# so all V2 §22.1 verbs are surface-aware (Finding #2 from
# PACK-REVIEW-BD066-068, addresses V1 §3.4 independence axes).
tracker_config_auto_surface() {
    local repo_root="$1"
    if [[ -f "$repo_root/PACK-CHAT.md" ]]; then
        echo "pack"
    elif [[ -d "$repo_root/docs/pack" ]]; then
        echo "client"
    else
        tracker_error_emit "validation" \
            "cannot auto-detect surface in $repo_root; pass --surface pack|client"
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────────
# Schema-version compatibility
# ─────────────────────────────────────────────────────────────────

# tracker_schema_version_check <path>
# Emits a typed validation error if missing or unexpected.
tracker_schema_version_check() {
    local path="$1"
    local data ver
    data=$(tracker_config_read "$path") || return 1
    ver=$(printf '%s' "$data" | jq -r '.schema_version // empty')
    if [[ -z "$ver" ]]; then
        tracker_error_emit "validation" "tracker.toml: missing required key 'schema_version'"
        return 1
    fi
    if [[ "$ver" != "$TRACKER_CONFIG_SCHEMA_VERSION" ]]; then
        tracker_error_emit "validation" \
            "tracker.toml: schema_version=$ver (this build supports $TRACKER_CONFIG_SCHEMA_VERSION)"
        return 1
    fi
    return 0
}

# tracker_error_emit() is provided by scripts/lib/tracker-errors.sh,
# sourced at the top of this file (BD-070).
