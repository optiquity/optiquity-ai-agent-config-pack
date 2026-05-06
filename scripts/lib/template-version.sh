# scripts/lib/template-version.sh — D-18 dual-carrier read/reconcile
# (BD-069).
#
# V3.3 §6.5 / D-18 specifies that every tracker entry carries its
# template version in two carriers:
#   - Body HTML comment: `<!-- template_version: bd-v11.0 -->`
#   - Label: `template:bd-v11.0`
#
# BD-065's body composer emits the comment; BD-066's label-ensure
# carries the label family; BD-065's label-set composer attaches
# the entry-specific template:* label at create-time. This module
# reads both and reconciles when they disagree.
#
# Reconciliation policy (V2 §26 + V3.3 §6.5):
#   - Both agree → return the agreed value.
#   - Mismatch  → emit `validation` typed error, return rc=1. The
#                 user runs `pack tracker doctor` (V2 §22.1) to see
#                 the divergence and `pack tracker update-templates`
#                 (V2 §19) to reconcile.
#   - One missing → return the present one with a warn log line on
#                 stderr. (Used for partial-entry recovery during a
#                 mid-upgrade run.)
#
# Public API:
#   - template_version_read_body <issue-json>
#       Extracts the value from the `<!-- template_version: ... -->`
#       comment in the issue body. Empty string when absent.
#   - template_version_read_label <labels>
#       Extracts the value from the first `template:*-vN.M` label.
#       Accepts either a JSON array of label strings or a JSON array
#       of label objects (with `.name`). Empty when absent.
#   - template_version_reconcile <body-version> <label-version>
#       Returns canonical version on stdout (rc=0) or surfaces typed
#       validation error (rc=1) on mismatch.
#   - template_version_extract_version_dir <template-version>
#       Helper used by the sidecar / archive path resolver:
#       `bd-v11.0` → `v11.0`, `phase-task-v11.2` → `v11.2`.
#
# Reference: ARCHITECTURE-V3.3-DELTA.md §6.5; ARCHITECTURE-V2.md §26.
#
# Do NOT add a shebang — this file is sourced, not executed.

# Source the typed-error formatter idempotently.
# shellcheck disable=SC1091
if ! declare -f tracker_error_emit >/dev/null 2>&1; then
    _tv_self="${BASH_SOURCE[0]}"
    _tv_dir="$(cd "$(dirname "$_tv_self")" && pwd)"
    source "$_tv_dir/tracker-errors.sh"
    unset _tv_self _tv_dir
fi

# ─────────────────────────────────────────────────────────────────
# Read the body-comment carrier
# ─────────────────────────────────────────────────────────────────

# template_version_read_body <issue-json>
# Reads `<!-- template_version: <value> -->` from the issue body.
# Emits the value (e.g. "bd-v11.0") on stdout, empty when absent.
template_version_read_body() {
    local issue="$1"
    printf '%s' "$issue" | python3 -c '
import json, re, sys
try:
    data = json.load(sys.stdin)
except json.JSONDecodeError:
    print("")
    sys.exit(0)
body = data.get("body", "") or ""
m = re.search(r"<!--\s*template_version:\s*([^\s-]+(?:-[^\s]*)?)\s*-->", body)
print(m.group(1) if m else "")
'
}

# ─────────────────────────────────────────────────────────────────
# Read the label carrier
# ─────────────────────────────────────────────────────────────────

# template_version_read_label <labels-json>
# Accepts either ["a", "b"] or [{"name": "a"}, {"name": "b"}].
# Emits the value from the first `template:<name>-v<X.Y>` label.
template_version_read_label() {
    local labels="$1"
    printf '%s' "$labels" | python3 -c '
import json, re, sys
try:
    arr = json.load(sys.stdin)
except json.JSONDecodeError:
    print("")
    sys.exit(0)
if not isinstance(arr, list):
    print("")
    sys.exit(0)
for item in arr:
    name = item if isinstance(item, str) else (item.get("name", "") if isinstance(item, dict) else "")
    m = re.match(r"^template:(.+-v[0-9]+\.[0-9]+)$", name)
    if m:
        print(m.group(1))
        sys.exit(0)
print("")
'
}

# ─────────────────────────────────────────────────────────────────
# Reconcile
# ─────────────────────────────────────────────────────────────────

# template_version_reconcile <body-version> <label-version>
# Returns canonical version on stdout, or typed validation error on
# mismatch (rc=1). When one is empty and the other present, returns
# the present one with a warn line on stderr. When both empty,
# returns "" with rc=0 (caller decides).
template_version_reconcile() {
    local body_v="$1"
    local label_v="$2"

    if [[ -z "$body_v" && -z "$label_v" ]]; then
        echo ""
        return 0
    fi
    if [[ -z "$body_v" ]]; then
        echo "WARN: template_version body marker missing; using label '$label_v'" >&2
        echo "$label_v"
        return 0
    fi
    if [[ -z "$label_v" ]]; then
        echo "WARN: template_version label missing; using body marker '$body_v'" >&2
        echo "$body_v"
        return 0
    fi
    if [[ "$body_v" == "$label_v" ]]; then
        echo "$body_v"
        return 0
    fi
    tracker_error_emit "validation" \
        "template_version mismatch: body says '$body_v', label says '$label_v'" \
        "Run 'pack tracker doctor' to see the divergence;" \
        "Run 'pack tracker update-templates' to reconcile."
    return 1
}

# ─────────────────────────────────────────────────────────────────
# Helper: extract version directory from template_version
# ─────────────────────────────────────────────────────────────────

# template_version_extract_version_dir <template-version>
# Maps `bd-v11.0` → `v11.0`, `phase-task-v11.2` → `v11.2`. Returns
# empty when the input does not match the `<entry-type>-v<X.Y>`
# pattern. Same logic the sidecar uses for template_archive_path
# (Finding #6 fix from PACK-REVIEW-BD066-068).
template_version_extract_version_dir() {
    local tv="$1"
    printf '%s' "$tv" | sed -nE 's/^.*-(v[0-9]+\.[0-9]+)$/\1/p'
}

# template_version_archive_path <template-version>
# Composes the path to the entry-type's archived SCHEMA.md per
# V3.3 §6.5 layout: templates-archive/<version_dir>/<template_version>/SCHEMA.md
template_version_archive_path() {
    local tv="$1"
    local vdir
    vdir=$(template_version_extract_version_dir "$tv")
    if [[ -z "$vdir" ]]; then
        echo ""
        return 1
    fi
    echo "maintenance-docs/v11-research/templates-archive/$vdir/$tv/SCHEMA.md"
}

# template_version_read_form <yaml-path>
# Reads the `<!-- template_version: ... -->` HTML comment from a
# .github/ISSUE_TEMPLATE/*.yml file's `markdown` block. The form
# YAML embeds the marker inside a `value: |` multiline string;
# YAML preserves the literal HTML comment text. Emits the marker
# value (e.g. "work-item-v11.0") on stdout, or "(missing)" if the
# file is absent, or "(none)" if the marker is not present.
#
# Used by `pack tracker update-templates` (V2 §19.2 step 1) and by
# `tracker doctor` (template-version freshness check, V2 §22.1).
# Unifies what was a duplicate inline regex in pack-tracker.sh.
template_version_read_form() {
    local path="$1"
    if [[ ! -f "$path" ]]; then
        echo "(missing)"
        return 0
    fi
    python3 - "$path" <<'PYEOF'
import re, sys
with open(sys.argv[1]) as f:
    text = f.read()
m = re.search(r'<!--\s*template_version:\s*([^\s-]+(?:-[^\s]*)?)\s*-->', text)
print(m.group(1) if m else "(none)")
PYEOF
}
