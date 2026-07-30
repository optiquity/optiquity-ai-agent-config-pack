# scripts/lib/template-translations.sh — V2 §19.4 translation manifest
# reader + V2 §19.3 body-patch applier (BD-069).
#
# The translation manifest is the single source of truth for
# `pack tracker update-templates`. It lives at
# `maintenance-docs/v11-research/templates-archive/translations.yaml`
# and lists every shipped template-version transition with its rules:
#
# ```yaml
# - from: bd-v11.0
#   to:   bd-v11.1
#   rules:
#     - kind: field-renamed
#       from: bd-blockers
#       to:   wi-blockers
#     - kind: field-added
#       to:   wi-priority
#       default: ""
#     - kind: field-removed
#       from: wi-old-field
#     - kind: label-renamed
#       from: status:open
#       to:   status:active
# ```
#
# At v11.0 the manifest is empty (no v11.x has shipped). The verb
# `pack tracker update-templates` reports "no upgrades available."
# Test fixtures populate a synthetic v11.0→v11.1 manifest under
# scripts/tests/fixtures/template-versions/translations.yaml.
#
# Public API:
#   - template_translations_load <manifest-path>
#       Loads the YAML manifest and emits it as JSON on stdout for
#       downstream jq consumption. Empty file → empty JSON array.
#   - template_translations_resolve_chain <from> <to> <manifest-json>
#       Computes the rule chain to translate from one version to
#       another, possibly through intermediate versions. V2 §19.4:
#       "a 2-version-skip (v11.0 → v12.0) chains v11.0→v11.1→v12.0
#       sequentially." Emits a JSON array of rules in apply order.
#       Returns rc=1 with typed validation error when no chain exists.
#   - template_translations_apply_rules <body> <rules-json>
#       Applies a chain's rules to an issue body per V2 §19.3 patch
#       semantics: pack-controlled scaffolding rewritten, user
#       content preserved by section. Emits the patched body.
#
# Reference: ARCHITECTURE-V2.md §19.2, §19.3, §19.4.
#
# Do NOT add a shebang — this file is sourced, not executed.

# Source the typed-error formatter idempotently.
# shellcheck disable=SC1091
if ! declare -f tracker_error_emit >/dev/null 2>&1; then
    _tt_self="${BASH_SOURCE[0]}"
    _tt_dir="$(cd "$(dirname "$_tt_self")" && pwd)"
    source "$_tt_dir/tracker-errors.sh"
    unset _tt_self _tt_dir
fi

# ─────────────────────────────────────────────────────────────────
# Manifest loader
# ─────────────────────────────────────────────────────────────────

# template_translations_load <manifest-path>
# Reads the YAML manifest and emits a JSON array of transitions.
# A missing or empty file emits `[]` (no upgrades available).
# Uses python3 + PyYAML for portability.
template_translations_load() {
    local path="$1"
    if [[ -z "$path" ]] || [[ ! -f "$path" ]]; then
        echo "[]"
        return 0
    fi
    python3 - "$path" <<'PYEOF'
import json, sys
try:
    import yaml
except ImportError:
    sys.stderr.write("ERROR: validation\nMESSAGE: PyYAML not installed; cannot read translations manifest\n→ Run: review the backend message above\n")
    sys.exit(1)
path = sys.argv[1]
try:
    with open(path) as f:
        data = yaml.safe_load(f)
except (OSError, yaml.YAMLError) as e:
    sys.stderr.write("ERROR: validation\nMESSAGE: %s\n→ Run: review the backend message above\n" % e)
    sys.exit(1)
if data is None:
    print("[]")
    sys.exit(0)
if not isinstance(data, list):
    sys.stderr.write("ERROR: validation\nMESSAGE: manifest top-level must be a list of transitions\n→ Run: review the backend message above\n")
    sys.exit(1)
print(json.dumps(data))
PYEOF
}

# ─────────────────────────────────────────────────────────────────
# Chain resolver
# ─────────────────────────────────────────────────────────────────

# template_translations_resolve_chain <from> <to> <manifest-json>
# Walks the manifest to find a sequential chain from `<from>` to
# `<to>`. Emits a JSON array of rules (concatenated across the chain
# in apply order). Returns rc=1 + typed validation error when no
# chain exists (or when from==to and the manifest has no identity).
template_translations_resolve_chain() {
    local from="$1"
    local to="$2"
    local manifest="$3"

    if [[ -z "$from" || -z "$to" ]]; then
        tracker_error_emit "validation" \
            "translations_resolve_chain: from and to are required"
        return 1
    fi

    if [[ "$from" == "$to" ]]; then
        echo "[]"
        return 0
    fi

    # Heredoc-stdin collision: `python3 -` reads script from stdin,
    # so we cannot also pipe data to stdin. Pass the manifest via a
    # temp file as argv[3].
    local manifest_file
    manifest_file=$(mktemp "${TMPDIR:-/tmp}/tt-manifest.XXXXXX")
    printf '%s' "$manifest" > "$manifest_file"
    python3 - "$from" "$to" "$manifest_file" <<'PYEOF'
import json, sys
src, dst, manifest_path = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    with open(manifest_path) as f:
        manifest = json.load(f)
except (OSError, json.JSONDecodeError):
    sys.stderr.write("ERROR: validation\nMESSAGE: manifest is not valid JSON\n→ Run: review the backend message above\n")
    sys.exit(1)

# Build adjacency: from-version → list of (to-version, rules).
# Edges are indexed for an edge-level `seen` set (PACK-REVIEW-
# BD062-069-071 #4): two parallel paths to the same target via
# different intermediate versions can both be considered. Cycles
# are still safe because each edge is visited at most once.
adj = {}
edges = []
for ei, entry in enumerate(manifest):
    f = entry.get("from")
    t = entry.get("to")
    rules = entry.get("rules", []) or []
    if f and t:
        adj.setdefault(f, []).append((ei, t, rules))
        edges.append((f, t))

# BFS from src to dst, accumulating rules. Edge-level `seen` so
# parallel paths to the same node remain reachable. First path
# found (FIFO) wins on tie.
from collections import deque
queue = deque([(src, [], frozenset())])
while queue:
    cur, acc, seen_edges = queue.popleft()
    if cur == dst:
        print(json.dumps(acc))
        sys.exit(0)
    for ei, nxt, rules in adj.get(cur, []):
        if ei in seen_edges:
            continue
        queue.append((nxt, acc + rules, seen_edges | {ei}))

sys.stderr.write("ERROR: validation\nMESSAGE: no translation chain from '%s' to '%s' in manifest\n→ Run: review the backend message above\n" % (src, dst))
sys.exit(1)
PYEOF
    local rc=$?
    rm -f "$manifest_file"
    return $rc
}

# ─────────────────────────────────────────────────────────────────
# Body-patch applier (V2 §19.3 patch semantics)
# ─────────────────────────────────────────────────────────────────

# template_translations_apply_rules <body> <rules-json>
# Applies a chain's rules to an issue body in order. Per V2 §19.3:
#   - field-renamed: rewrite `## <old>` to `## <new>` preserving content
#   - field-added:   append `## <new>` empty section with TODO marker
#   - field-removed: rewrite `## <old>` to `## Context (legacy <old>)`
#   - label-renamed: no-op at body level (label patch is separate)
#
# User content inside each section is preserved verbatim. Pack-
# controlled scaffolding (the headings) is what changes.
template_translations_apply_rules() {
    local body="$1"
    local rules="$2"
    if [[ -z "$rules" || "$rules" == "[]" ]]; then
        printf '%s' "$body"
        return 0
    fi
    # Use temp file to avoid heredoc-stdin collision.
    local body_file
    body_file=$(mktemp "${TMPDIR:-/tmp}/tt-body.XXXXXX")
    printf '%s' "$body" > "$body_file"
    python3 - "$body_file" "$rules" <<'PYEOF'
import re, sys, json
path = sys.argv[1]
try:
    rules = json.loads(sys.argv[2])
except json.JSONDecodeError:
    sys.stderr.write("ERROR: validation\nMESSAGE: rules-json is not valid JSON\n→ Run: review the backend message above\n")
    sys.exit(1)

with open(path) as f:
    body = f.read()

def find_section(text, heading):
    """Return (start_of_heading_line, end_of_section) or (None, None)."""
    pat = re.compile(r'^##\s+' + re.escape(heading) + r'\s*$', re.M)
    m = pat.search(text)
    if not m:
        return None, None
    start = m.start()
    nxt = re.search(r'^##\s+', text[m.end():], re.M)
    end = m.end() + (nxt.start() if nxt else len(text) - m.end())
    return start, end

for r in rules:
    kind = r.get("kind", "")
    if kind == "field-renamed":
        old = r.get("from", "")
        new = r.get("to", "")
        if old and new:
            start, end = find_section(body, old)
            if start is not None:
                # Rewrite the heading line; preserve body.
                section = body[start:end]
                section = re.sub(r'^##\s+' + re.escape(old) + r'\s*$',
                                 f'## {new}', section, count=1, flags=re.M)
                body = body[:start] + section + body[end:]
    elif kind == "field-added":
        new = r.get("to", "")
        if new:
            start, _end = find_section(body, new)
            if start is None:
                # Append at end with TODO marker.
                tail = ('\n## ' + new + '\n\n'
                        '<!-- TODO: pack tracker update-templates added '
                        'this field; fill it in or leave blank -->\n')
                body = body.rstrip('\n') + '\n' + tail
    elif kind == "field-removed":
        old = r.get("from", "")
        if old:
            start, end = find_section(body, old)
            if start is not None:
                section = body[start:end]
                section = re.sub(r'^##\s+' + re.escape(old) + r'\s*$',
                                 f'## Context (legacy {old})', section, count=1, flags=re.M)
                body = body[:start] + section + body[end:]
    elif kind == "label-renamed":
        # Body has no labels; the verb's label-patch step (separate
        # from body-patch) handles label renames on the issue.
        continue

print(body, end='')
PYEOF
    rm -f "$body_file"
}
