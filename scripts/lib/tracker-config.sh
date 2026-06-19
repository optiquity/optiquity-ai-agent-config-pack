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
# Additive v11.0 fields (BD-108):
#   - [graph] cycle_check_k = <positive integer, default 10>
#       Per V3.3 §5.5 + IPLAN-ADDENDUM-4 §6.Q recommendation (a):
#       maximum BFS hop count for the link-creation-time cycle
#       detector (scripts/lib/tracker-cycle-check.sh). Read by
#       tracker_cycle_check_get_k(); falls back to 10 when absent.
#       Existing tracker.toml schemas continue to load (additive).
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
    # BD-214 deferral clamp (2026-06-12): tracker mode is deferred
    # indefinitely; flat-file per-entry is the SOLE supported mode.
    # PACK_TRACKER_DEFERRAL_OVERRIDE=1 is a TEST-ONLY seam that keeps the
    # dormant tracker code testable; it must NEVER be set in a live run.
    # Recorded in BD-214 / BD-204.
    if [[ "${PACK_TRACKER_DEFERRAL_OVERRIDE:-0}" != "1" ]]; then
        echo "tracker mode is deferred; operating flat-file" >&2
        echo "flat-file"
        return 0
    fi
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

# tracker_gh_repo_setup
# Export GH_REPO from the active tracker.toml so every `gh` invocation
# in the tracker libs targets the configured backend.repo, regardless
# of what `git remote -v` says in the working copy. This addresses
# BD-129 / D-1: clones from local-path sources, repos with non-GitHub
# remotes, internal mirrors, and freshly-cloned repos before
# `git remote` setup all break gh's auto-resolution from git remotes
# with the misleading "none of the git remotes configured for this
# repository point to a known GitHub host" error. GH_REPO (a
# documented gh CLI env var) overrides remote resolution for the
# entire process.
#
# Resolution:
#   - If GH_REPO is already set in the environment (caller override,
#     test seam, or a previous setup) it is preserved — the function
#     is a no-op in that case.
#   - Otherwise, reads _TRACKER_PROVIDER_CONFIG_PATH (set by every
#     tracker verb's orchestrator: tracker_init_run,
#     tracker_migrate_forward_run, tracker_migrate_reverse_run,
#     tracker_doctor_run, tracker_agent_read).
#   - Reads backend.repo from that tracker.toml; if non-empty,
#     exports GH_REPO=<slug>.
#   - All failures (no env var, missing file, parse error, missing
#     key) are silent: the function never returns non-zero. The
#     downstream gh call will surface the appropriate typed error if
#     no slug is reachable.
#
# Idempotent and safe to call from any tracker library that wraps a
# gh invocation. Belt-and-suspenders: planted in _gh_run (covers the
# provider surface) and tracker_labels_ensure (covers the labels
# surface, which uses raw gh outside _gh_run).
tracker_gh_repo_setup() {
    if [[ -n "${GH_REPO:-}" ]]; then
        return 0
    fi
    local cfg="${_TRACKER_PROVIDER_CONFIG_PATH:-}"
    [[ -z "$cfg" || ! -f "$cfg" ]] && return 0
    local slug
    slug=$(tracker_repo_slug "$cfg" 2>/dev/null) || return 0
    [[ -z "$slug" ]] && return 0
    # BD-129 retro-fix F4: validate the slug shape before exporting.
    # A malformed `backend.repo` (e.g. an HTTPS URL pasted instead of
    # `owner/repo`, internal whitespace, or a missing slash) propagates
    # silently into `GH_REPO` and gh fails downstream with a less-
    # targeted error than the original BD-129 problem the helper was
    # meant to eliminate. Accept only the canonical `[HOST/]OWNER/REPO`
    # shape gh's own GH_REPO contract documents:
    #   - must contain at least one '/'
    #   - no scheme separators ('://')
    #   - no whitespace
    # On rejection, emit a typed validation error to stderr and
    # continue (helper still returns 0 — fail-soft so the downstream
    # gh call can surface its own typed error if appropriate).
    if [[ "$slug" != */* ]] || [[ "$slug" == *"://"* ]] \
       || [[ "$slug" == *' '* ]] || [[ "$slug" == *$'\t'* ]]; then
        tracker_error_emit "validation" \
            "tracker.toml backend.repo='$slug' is not a canonical [HOST/]OWNER/REPO slug; refusing to export as GH_REPO" \
            "(expected forms: 'owner/repo' or 'github.example.com/owner/repo'; got a value with a scheme, whitespace, or no slash)"
        return 0
    fi
    export GH_REPO="$slug"
    return 0
}

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
    if [[ -d "$repo_root/pack-ops" ]]; then
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
