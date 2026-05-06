# scripts/lib/tracker-migrate-reverse.sh — V1 §6.5 reverse migration
# (BD-067).
#
# Reverse direction: tracker → flat-file. Triggered by:
#   - `scripts/tracker-migrate.sh reverse` (explicit user command).
#   - `pack tracker disable` chat command (runs reverse + flips
#     mode.state to flat-file).
#   - Pack-upgrade preflight, when an upgrade requires it.
#
# Sourced by scripts/tracker-migrate.sh. Depends on:
#   - scripts/lib/tracker-provider.sh + tracker-provider-gh.sh (BD-060)
#   - scripts/lib/tracker-config.sh (BD-061)
#   - scripts/lib/tracker-errors.sh (BD-070)
#   - scripts/lib/tracker-mirror.sh (BD-067)
#   - scripts/lib/tracker-sidecar.sh (BD-067)
#
# Algorithm (V1 §6.5 steps 1–9):
#   1. provider_list with td-entry / bd-entry filter (full body).
#   2. provider_search for phase epics (in:title "Phase").
#   3. For each entry, reconstruct the v10 BACKLOG record:
#        Type        ← title prefix decode + scope/severity labels
#        Status      ← status:* label
#        Blockers    ← blocked-by edges + sub-issue parent
#        Unblocks    ← inverse of Blockers across the dataset (pass 2)
#        File/Symbol ← body section
#        Description ← body section
#        Context     ← body section
#        Resolution  ← latest comment if status=Resolved, else null
#   4. Sort by ID (BD-NNN ascending, then TD-NNN ascending) and emit
#      BACKLOG.md.
#   5. Emit IMPLEMENTATION_PLAN.md from phase-epic titles
#      (only if it does not already exist).
#   6. Emit STATUS.md from phase-epic state + entry counts.
#   7. Emit CHANGELOG.md skeleton (real audit-log walking is deferred;
#      provider_events op does not exist in BD-060).
#   8. Strip the read-only mirror header from the emitted files.
#   9. Update tracker.toml [migration].last_reverse_run.
#
# Sidecar (V1 §6.6 + §6.6.1) is emitted alongside in step 7.5 via
# scripts/lib/tracker-sidecar.sh — separate file, not fileset.
#
# Public API:
#   - tracker_migrate_reverse_run <repo-root> [<dry-run>] [<include-comments>]
#       Top-level reverse migration entry point.
#
# Reference: ARCHITECTURE.md §6.5, §6.6, §6.6.1, §6.7;
#            ARCHITECTURE-V3.1-DELTA.md §A2.
#
# Do NOT add a shebang — this file is sourced, not executed.

# Source siblings idempotently.
# shellcheck disable=SC1091
if ! declare -f tracker_mirror_header_strip >/dev/null 2>&1; then
    _tmr_self="${BASH_SOURCE[0]}"
    _tmr_dir="$(cd "$(dirname "$_tmr_self")" && pwd)"
    source "$_tmr_dir/tracker-mirror.sh"
    unset _tmr_self _tmr_dir
fi
# shellcheck disable=SC1091
if ! declare -f tracker_sidecar_emit >/dev/null 2>&1; then
    _tmr_self="${BASH_SOURCE[0]}"
    _tmr_dir="$(cd "$(dirname "$_tmr_self")" && pwd)"
    source "$_tmr_dir/tracker-sidecar.sh"
    unset _tmr_self _tmr_dir
fi

# ─────────────────────────────────────────────────────────────────
# Per-entry reconstruction (V1 §6.5 step 3)
# ─────────────────────────────────────────────────────────────────

# Decode the entry's v10 Status. Accepts either:
#   - A JSON array of label strings (legacy/test path; labels-only)
#   - A full canonical Issue JSON object (production path; reads
#     state + state_reason and falls back to label hints)
#
# Production path (V3.3 §6.3 mapping + addresses Finding #4 from
# PACK-REVIEW-BD066-068):
#   state=closed + state_reason=completed              → Resolved
#   state=closed + state_reason=not_planned/duplicate  → Cancelled
#                                       (or Deprecated if label hints)
#   state=open + status:unblocked label                 → Unblocked
#   state=open + (no/other label)                       → Open
#
# Legacy/test path is preserved for the existing labels-only test
# fixtures in tracker-migrate-reverse-test.sh Group 1.
_tmr_decode_status() {
    local input="$1"
    local first_char
    first_char=$(printf '%s' "$input" | head -c 1)

    if [[ "$first_char" == "[" ]]; then
        # Legacy: input is a label array.
        local label
        label=$(printf '%s' "$input" | jq -r 'if type=="array" then .[] else empty end' 2>/dev/null \
            | grep -E '^status:' | head -n 1)
        case "$label" in
            status:open)        echo "Open" ;;
            status:unblocked)   echo "Unblocked" ;;
            status:resolved)    echo "Resolved" ;;
            status:cancelled)   echo "Cancelled" ;;
            status:deprecated)  echo "Deprecated" ;;
            *)                  echo "Open" ;;
        esac
        return 0
    fi

    # New: input is a full canonical Issue object. Prefer GH state
    # over labels (manual closes have no status:* label).
    local state state_reason label
    state=$(printf '%s' "$input" | jq -r '.state // "open"')
    state_reason=$(printf '%s' "$input" | jq -r '.state_reason // ""')
    label=$(printf '%s' "$input" | jq -r '(.labels // []) | if type=="array" then .[] else empty end' 2>/dev/null \
        | grep -E '^status:' | head -n 1)

    if [[ "$state" == "closed" ]]; then
        case "$state_reason" in
            completed)
                echo "Resolved"
                ;;
            not_planned|duplicate)
                # status:deprecated label distinguishes Deprecated
                # from Cancelled (V3.3 §6.3 line table); both map
                # to GH state_reason=not_planned.
                if [[ "$label" == "status:deprecated" ]]; then
                    echo "Deprecated"
                else
                    echo "Cancelled"
                fi
                ;;
            *)
                # Closed with unknown reason → Resolved (safest read).
                echo "Resolved"
                ;;
        esac
        return 0
    fi

    # Open: derive from label.
    case "$label" in
        status:unblocked)   echo "Unblocked" ;;
        *)                  echo "Open" ;;
    esac
}

# Decode the entry's v10 Type from labels.
#
# v10 grammar (METHODOLOGY §988):
#   Type: TODO(<scope>) | KNOWN GAP(<severity>) | VERIFY(<source>)
#
# The parenthetical takes the actual scope/severity VALUE from the
# corresponding label (`scope:dependency` → `TODO(dependency)`,
# `severity:critical` → `KNOWN GAP(critical)`). When the label is
# absent we fall back to the literal placeholder name (`scope`,
# `severity`) so v10 fixtures that author the type as `TODO(scope)`
# round-trip byte-equivalent through forward → reverse.
_tmr_decode_type() {
    local pack_id="$1"
    local labels_json="$2"
    case "$pack_id" in
        BD-*) echo "TODO(version)" ;;
        TD-*)
            local severity scope
            severity=$(_tmr_decode_severity "$labels_json")
            if [[ -n "$severity" ]]; then
                echo "KNOWN GAP($severity)"
            else
                scope=$(_tmr_decode_scope "$labels_json")
                [[ -z "$scope" ]] && scope="scope"
                echo "TODO($scope)"
            fi
            ;;
        *)    echo "TODO" ;;
    esac
}

# Decode the entry's scope from `scope:*` label. Returns empty if
# absent. Used for TD entries' v10 deferral-comment grammar.
_tmr_decode_scope() {
    local labels_json="$1"
    printf '%s' "$labels_json" | jq -r 'if type=="array" then .[] else empty end' 2>/dev/null \
        | grep -E '^scope:' | head -n 1 | sed 's/^scope://'
}

# Decode severity from `severity:*` label.
_tmr_decode_severity() {
    local labels_json="$1"
    printf '%s' "$labels_json" | jq -r 'if type=="array" then .[] else empty end' 2>/dev/null \
        | grep -E '^severity:' | head -n 1 | sed 's/^severity://'
}

# Extract a body H2 section's content. Reads body text from stdin
# (a temp file is used internally because heredoc-based python3
# scripts cannot also read stdin via the same redirection). Arg is
# the heading name (without leading `## `). Emits the section's body
# verbatim (without the heading), trimmed of trailing whitespace.
_tmr_extract_section() {
    local heading="$1"
    local tmp
    tmp=$(mktemp -t tmrext.XXXXXX)
    cat > "$tmp"
    python3 - "$tmp" "$heading" <<'PYEOF'
import re, sys
with open(sys.argv[1]) as f:
    text = f.read()
heading = sys.argv[2]
pat = re.compile(r'^##\s+' + re.escape(heading) + r'\s*$', re.M)
m = pat.search(text)
if not m:
    print('')
    sys.exit(0)
start = m.end()
nxt = re.search(r'^##\s+', text[start:], re.M)
end = start + (nxt.start() if nxt else len(text) - start)
section = text[start:end].strip('\n')
print(section)
PYEOF
    rm -f "$tmp"
}

# Extract Blockers from the issue's link relationships. The provider
# does not have a generic "list links by kind" op (V1 §2.4 link.kind
# is open-string); for v11.0 we read the body for the comment-marker
# fallback ("Blocked by #NNN") and prepend any sub-issue parent.
#
# Returns a JSON array of pack-ids on stdout. Non-pack-id refs (e.g.
# `#42` to a non-mapped issue) are dropped.
_tmr_decode_blockers() {
    local body="$1"
    local mapping="$2"
    local sub_issue_parent="${3:-}"
    python3 - "$body" "$mapping" "$sub_issue_parent" <<'PYEOF'
import json, re, sys
body, mapping_json, sub_issue_parent = sys.argv[1], sys.argv[2], sys.argv[3]
mapping = json.loads(mapping_json) if mapping_json else {}

# Build reverse-lookup: gh-id → pack-id.
gh_to_pack = {}
for pack_id, info in mapping.items():
    if isinstance(info, dict) and info.get("id"):
        gh_to_pack[str(info["id"])] = pack_id

blockers = []

# Sub-issue parent → phase-N if it maps to one.
if sub_issue_parent:
    pack_parent = gh_to_pack.get(str(sub_issue_parent))
    if pack_parent and pack_parent.startswith("phase-"):
        blockers.append(pack_parent)

# Body comment markers: "Blocked by #NNN" lines.
for m in re.finditer(r'(?:Blocked by|blocked-by|blocks)[\s:]*#(\d+)', body):
    gh_id = m.group(1)
    pack_id = gh_to_pack.get(gh_id)
    if pack_id and pack_id not in blockers:
        blockers.append(pack_id)

print(json.dumps(blockers))
PYEOF
}

# Reconstruct one BACKLOG entry from a normalized Issue JSON
# (provider canonical shape per V1 §2.2). Returns a JSON object
# matching the v10 entry shape (compatible with BD-065's
# tmf_parse_backlog output).
tracker_migrate_reverse_reconstruct() {
    local issue="$1"
    local mapping="$2"

    local pack_id title body labels status type scope severity
    pack_id=$(printf '%s' "$issue" | python3 -c '
import json, re, sys
data = json.load(sys.stdin)
body = data.get("body", "") or ""
m = re.search(r"<!--\s*pack-id:\s*([A-Z]+-\d+|phase-\d+(?:\.\d+)?)\s*-->", body)
print(m.group(1) if m else "")')

    if [[ -z "$pack_id" ]]; then
        # Fall back to title prefix.
        pack_id=$(printf '%s' "$issue" | jq -r '.title // ""' \
            | sed -nE 's/^((BD|TD)-[0-9]+):.*/\1/p')
    fi

    title=$(printf '%s' "$issue" | jq -r '.title // ""' | sed -E 's/^(BD|TD)-[0-9]+:[[:space:]]*//')
    body=$(printf  '%s' "$issue" | jq -r '.body // ""')
    labels=$(printf '%s' "$issue" | jq -c '.labels // []')

    # Pass the full issue (state + state_reason + labels) so
    # manually-closed issues (no status:* label) classify correctly.
    status=$(_tmr_decode_status "$issue")
    type=$(_tmr_decode_type "$pack_id" "$labels")
    scope=$(_tmr_decode_scope "$labels")
    severity=$(_tmr_decode_severity "$labels")

    local description context resolution file_symbol
    description=$(printf '%s' "$body" | _tmr_extract_section "Description")
    context=$(printf     '%s' "$body" | _tmr_extract_section "Context")
    resolution=$(printf  '%s' "$body" | _tmr_extract_section "Resolution")
    file_symbol=$(printf '%s' "$body" | _tmr_extract_section "File / Symbol")

    local sub_issue_parent
    sub_issue_parent=$(printf '%s' "$issue" | jq -r '.parent // ""')

    local blockers
    blockers=$(_tmr_decode_blockers "$body" "$mapping" "$sub_issue_parent")

    jq -n \
        --arg pack_id "$pack_id" \
        --arg title "$title" \
        --arg type "$type" \
        --arg status "$status" \
        --arg scope "$scope" \
        --arg severity "$severity" \
        --argjson blockers "$blockers" \
        --arg file_symbol "$file_symbol" \
        --arg description "$description" \
        --arg context "$context" \
        --arg resolution "$resolution" \
        '{
            pack_id: $pack_id,
            title: $title,
            type: $type,
            status: $status,
            scope: $scope,
            severity: $severity,
            blockers: $blockers,
            unblocks: [],
            file_symbol: $file_symbol,
            description: $description,
            context: $context,
            resolution: $resolution
        }'
}

# ─────────────────────────────────────────────────────────────────
# Emission (V1 §6.5 steps 4–7)
# ─────────────────────────────────────────────────────────────────

# Compute Unblocks across the dataset (V1 §6.5 line 1112: inverse of
# Blockers). Reads JSON array of entries on stdin; emits the same
# array with `unblocks` populated for each entry.
_tmr_compute_unblocks() {
    python3 -c '
import json, sys
entries = json.load(sys.stdin)
unblocks_map = {}
for e in entries:
    pid = e.get("pack_id", "")
    for b in e.get("blockers", []):
        unblocks_map.setdefault(b, []).append(pid)
for e in entries:
    pid = e.get("pack_id", "")
    e["unblocks"] = sorted(unblocks_map.get(pid, []))
print(json.dumps(entries))
'
}

# Emit BACKLOG.md from a reconstructed entries array. Header line
# at top is `# BACKLOG`. Entries are sorted by pack_id (BD- before
# TD- by convention; numeric within each prefix).
_tmr_emit_backlog() {
    local entries="$1"
    local backend_slug="$2"
    local out_path="$3"

    # Pass entries via temp file (not heredoc-embedded triple-quoted
    # string) — addresses Finding #13 from PACK-REVIEW-BD066-068:
    # description text containing `"""` would terminate the embedded
    # string early. File-passing is robust against any payload.
    local entries_file
    entries_file=$(mktemp -t tmr-emit-backlog.XXXXXX)
    printf '%s' "$entries" > "$entries_file"
    python3 - "$out_path" "$entries_file" <<'PYEOF'
import json, sys
out_path = sys.argv[1]
with open(sys.argv[2]) as f:
    entries = json.load(f)

def sort_key(e):
    pid = e.get("pack_id", "ZZZ-000")
    prefix = pid.split("-")[0] if "-" in pid else "ZZZ"
    try:
        n = int(pid.split("-")[1]) if "-" in pid else 0
    except ValueError:
        n = 0
    # BD before TD, then numeric.
    order = {"BD": 0, "TD": 1}.get(prefix, 9)
    return (order, n, pid)

entries = sorted(entries, key=sort_key)
lines = ["# BACKLOG", ""]
for e in entries:
    pid    = e.get("pack_id", "")
    title  = e.get("title", "")
    typ    = e.get("type", "TODO(version)")
    status = e.get("status", "Open")
    scope  = e.get("scope", "") or ""
    sev    = e.get("severity", "") or ""
    bl     = e.get("blockers", []) or []
    ub     = e.get("unblocks", []) or []
    fs     = e.get("file_symbol", "") or ""
    desc   = e.get("description", "") or ""
    ctx    = e.get("context", "") or ""
    res    = e.get("resolution", "") or ""

    lines.append(f"**{pid} — {title}**")
    lines.append(f"Type: {typ}")
    lines.append(f"Status: {status}")
    if scope:
        lines.append(f"Scope: {scope}")
    if sev:
        lines.append(f"Severity: {sev}")
    lines.append("Blockers: " + (", ".join(bl) if bl else "None"))
    lines.append("Unblocks: " + (", ".join(ub) if ub else "None"))
    if fs:
        lines.append(f"File/Symbol: {fs}")
    if desc:
        lines.append(f"Description: {desc}")
    if ctx:
        lines.append(f"Context: {ctx}")
    if res:
        lines.append(f"Resolution: {res}")
    else:
        lines.append("Resolved: n/a")
    lines.append("")
    lines.append("---")
    lines.append("")

with open(out_path, "w") as f:
    f.write("\n".join(lines).rstrip("\n") + "\n")
PYEOF
    rm -f "$entries_file"
}

# Emit IMPLEMENTATION_PLAN.md skeleton from phase epic titles. Per
# V1 §6.5 step 5, skipped if the file already exists.
_tmr_emit_implementation_plan() {
    local phases="$1"
    local out_path="$2"
    if [[ -f "$out_path" ]]; then
        return 0
    fi
    # File-pass per Finding #13 (PACK-REVIEW-BD066-068).
    local phases_file
    phases_file=$(mktemp -t tmr-emit-plan.XXXXXX)
    printf '%s' "$phases" > "$phases_file"
    python3 - "$out_path" "$phases_file" <<'PYEOF'
import json, sys
out_path = sys.argv[1]
with open(sys.argv[2]) as f:
    phases = json.load(f)
phases = sorted(phases, key=lambda p: int(p.get("phase_number", "0") or "0"))
lines = ["# IMPLEMENTATION PLAN", "", "## Phases", ""]
for p in phases:
    n = p.get("phase_number", "")
    t = p.get("title", "")
    lines.append(f"### Phase {n} — {t}")
    lines.append("")
with open(out_path, "w") as f:
    f.write("\n".join(lines).rstrip("\n") + "\n")
PYEOF
    rm -f "$phases_file"
}

# Emit STATUS.md skeleton from phase epics + entry counts.
_tmr_emit_status() {
    local entries="$1"
    local phases="$2"
    local out_path="$3"
    # File-pass per Finding #13 (PACK-REVIEW-BD066-068).
    local entries_file phases_file
    entries_file=$(mktemp -t tmr-emit-status-e.XXXXXX)
    phases_file=$(mktemp  -t tmr-emit-status-p.XXXXXX)
    printf '%s' "$entries" > "$entries_file"
    printf '%s' "$phases"  > "$phases_file"
    python3 - "$out_path" "$entries_file" "$phases_file" <<'PYEOF'
import json, sys
out_path = sys.argv[1]
with open(sys.argv[2]) as f:
    entries = json.load(f)
with open(sys.argv[3]) as f:
    phases = json.load(f)

open_count    = sum(1 for e in entries if e.get("status") in ("Open", "Unblocked"))
closed_count  = sum(1 for e in entries if e.get("status") in ("Resolved", "Cancelled", "Deprecated"))

lines = ["# STATUS", "", "## Phases", ""]
for p in sorted(phases, key=lambda p: int(p.get("phase_number", "0") or "0")):
    lines.append(f"- Phase {p.get('phase_number')} — {p.get('title')}")
lines.extend(["", "## Entries", ""])
lines.append(f"- Open: {open_count}")
lines.append(f"- Closed: {closed_count}")
with open(out_path, "w") as f:
    f.write("\n".join(lines).rstrip("\n") + "\n")
PYEOF
    rm -f "$entries_file" "$phases_file"
}

# Emit CHANGELOG.md skeleton. Real audit-log walking (V1 §6.5 step 7)
# requires a provider_events op that BD-060 did not ship; v11.0
# emits a skeleton with a TODO marker pointing at the future BD that
# adds events. This preserves reverse migration's no-data-loss
# semantic (the v10 grammar doesn't have a mechanical way to derive
# CHANGELOG from tracker state in v11.0).
_tmr_emit_changelog() {
    local out_path="$1"
    if [[ -f "$out_path" ]]; then
        return 0
    fi
    cat > "$out_path" <<'EOF'
# CHANGELOG

<!--
  This CHANGELOG was reverse-emitted from the tracker.
  v11.0 reverse migration cannot walk the per-issue audit log
  (provider_events op is not yet implemented). When the events op
  ships, future reverse runs will populate per-phase release notes
  here. Until then, this file is a stub — append entries by hand or
  re-run reverse after the events op lands.
-->

## Unreleased

(populated by future reverse runs once provider_events lands)
EOF
}

# ─────────────────────────────────────────────────────────────────
# tracker.toml mode flip + last_reverse_run timestamp
# ─────────────────────────────────────────────────────────────────

# Update tracker.toml [migration].last_reverse_run timestamp +
# optionally flip mode.state to flat-file (for `pack tracker disable`).
_tmr_update_tracker_toml() {
    local cfg="$1"
    local flip_to_flat_file="${2:-0}"
    if [[ ! -f "$cfg" ]]; then
        return 0
    fi
    local now_iso
    now_iso=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    python3 - "$cfg" "$now_iso" "$flip_to_flat_file" <<'PYEOF'
import re, sys
cfg, now, flip = sys.argv[1], sys.argv[2], sys.argv[3] == "1"
with open(cfg) as f:
    text = f.read()

def set_in_section(text, section, key, value):
    section_re = re.compile(r'^\[' + re.escape(section) + r'\][ \t]*$', re.M)
    m = section_re.search(text)
    if not m:
        return text.rstrip() + f'\n\n[{section}]\n{key} = "{value}"\n'
    start = m.end()
    nxt = re.search(r'^\[', text[start:], re.M)
    end = start + (nxt.start() if nxt else len(text) - start)
    block = text[start:end]
    # Use [ \t]* not \s* — \s consumes newlines and breaks the
    # line boundary needed for re.sub line-replacement.
    if re.search(rf'^[ \t]*{re.escape(key)}[ \t]*=', block, re.M):
        block = re.sub(rf'^[ \t]*{re.escape(key)}[ \t]*=.*$',
                       f'{key} = "{value}"', block, flags=re.M)
    elif re.search(rf'^[ \t]*#[ \t]*{re.escape(key)}[ \t]*=', block, re.M):
        block = re.sub(rf'^[ \t]*#[ \t]*{re.escape(key)}[ \t]*=.*$',
                       f'{key} = "{value}"', block, flags=re.M)
    else:
        block = block.rstrip() + f'\n{key} = "{value}"\n'
    return text[:start] + block + text[end:]

text = set_in_section(text, "migration", "last_reverse_run", now)
if flip:
    text = set_in_section(text, "mode", "state", "flat-file")

with open(cfg, "w") as f:
    f.write(text)
PYEOF
}

# ─────────────────────────────────────────────────────────────────
# Top-level orchestrator
# ─────────────────────────────────────────────────────────────────

# tracker_migrate_reverse_run <repo-root> [<dry-run>] [<flip-mode-to-flat-file>] [<include-comments>]
# Runs V1 §6.5 steps 1–9. flip_mode=1 turns this into the
# `pack tracker disable` semantic (reverse + flip mode).
tracker_migrate_reverse_run() {
    local repo_root="$1"
    local dry_run="${2:-0}"
    local flip_mode="${3:-0}"
    local include_comments="${4:-0}"

    if [[ ! -d "$repo_root" ]]; then
        tracker_error_emit "validation" "reverse: repo-root not a directory: $repo_root"
        return 1
    fi

    local cfg_path surface
    surface=$(tracker_config_auto_surface "$repo_root" 2>/dev/null) || surface="pack"
    cfg_path=$(tracker_config_resolve_path "$surface" "$repo_root") || return 1
    if [[ ! -f "$cfg_path" ]]; then
        tracker_error_emit "validation" \
            "reverse: tracker.toml not found at $cfg_path  (nothing to reverse from)"
        return 1
    fi
    export _TRACKER_PROVIDER_CONFIG_PATH="$cfg_path"

    local mapping_file mapping
    mapping_file=$(_tmf_mapping_file "$repo_root")
    mapping=$(tmf_mapping_load "$mapping_file")

    # Steps 1+2 (V1 §6.5): discover entries via provider_list with
    # label filters (`bd-entry`, `td-entry`, `phase-epic`). The
    # mapping file is unioned in as a recovery fallback so entries
    # whose entry-label was stripped or that pre-date v11.0 (no
    # canonical labels yet) still round-trip. pack_id is resolved
    # from the canonical body marker; mapping serves only as a
    # gh_id → pack_id fallback when the body marker is absent.
    local roster='[]'
    local _tmr_label
    for _tmr_label in "bd-entry" "td-entry" "phase-epic"; do
        local _tmr_list
        if _tmr_list=$(provider_list "{\"label\":\"${_tmr_label}\",\"state\":\"all\"}" 100 2>/dev/null); then
            roster=$(jq -nc --argjson r "$roster" --argjson l "$_tmr_list" \
                '$r + (($l.items // []) | map(.id // .number | tostring))')
        fi
    done
    # Union with mapping gh_ids (recovery fallback).
    roster=$(jq -nc --argjson r "$roster" --argjson m "$mapping" \
        '$r + ([$m | to_entries[] | .value.id // empty | tostring]) | unique')

    local issue_jsons='[]' phase_jsons='[]'
    local n_roster i_roster=0 gh_id pack_id issue
    n_roster=$(printf '%s' "$roster" | jq 'length')
    while [[ $i_roster -lt $n_roster ]]; do
        gh_id=$(printf '%s' "$roster" | jq -r ".[$i_roster]")
        i_roster=$((i_roster + 1))
        [[ -z "$gh_id" || "$gh_id" == "null" ]] && continue
        if ! issue=$(provider_get "$gh_id" 2>/dev/null); then
            continue
        fi
        # Canonical: pack-id from body marker.
        pack_id=$(printf '%s' "$issue" | python3 -c '
import json, re, sys
d = json.load(sys.stdin)
b = d.get("body", "") or ""
m = re.search(r"<!--\s*pack-id:\s*([A-Za-z]+-\d+(?:\.\d+)?)\s*-->", b)
print(m.group(1) if m else "")')
        # Fallback: gh_id → pack_id via mapping reverse lookup.
        if [[ -z "$pack_id" ]]; then
            pack_id=$(printf '%s' "$mapping" | jq -r --arg g "$gh_id" \
                'to_entries | map(select(.value.id == $g)) | .[0].key // empty')
        fi
        [[ -z "$pack_id" ]] && continue
        case "$pack_id" in
            phase-*)
                phase_jsons=$(printf '%s' "$phase_jsons" | jq -c \
                    --argjson i "$issue" --arg p "$pack_id" \
                    '. + [{phase_number: ($p | sub("phase-"; "")), title: $i.title, gh_id: $i.id}]')
                ;;
            BD-*|TD-*)
                local rec
                rec=$(tracker_migrate_reverse_reconstruct "$issue" "$mapping")
                issue_jsons=$(printf '%s' "$issue_jsons" | jq -c --argjson r "$rec" '. + [$r]')
                ;;
        esac
    done

    # Step 3 second pass: compute Unblocks (inverse of Blockers).
    issue_jsons=$(printf '%s' "$issue_jsons" | _tmr_compute_unblocks)

    # Phase title cleanup: strip "Phase N — " prefix.
    phase_jsons=$(printf '%s' "$phase_jsons" | python3 -c '
import json, sys, re
phases = json.load(sys.stdin)
for p in phases:
    t = p.get("title", "")
    m = re.match(r"^Phase\s+\d+\s*[—-]\s*(.+)$", t)
    if m:
        p["title"] = m.group(1).strip()
print(json.dumps(phases))')

    local n_entries n_phases
    n_entries=$(printf '%s' "$issue_jsons" | jq 'length')
    n_phases=$(printf  '%s' "$phase_jsons" | jq 'length')
    echo "reverse: reconstructed $n_entries BACKLOG entries, $n_phases phase epic(s)"

    if [[ "$dry_run" == "1" ]]; then
        echo "reverse: --dry-run set; stopping after reconstruction"
        return 0
    fi

    # Steps 4–7: emit flat files.
    local backend_slug
    backend_slug=$(tracker_repo_slug "$cfg_path" 2>/dev/null || echo "unknown")

    local backlog_out plan_out status_out changelog_out
    backlog_out="$repo_root/BACKLOG.md"
    plan_out="$repo_root/IMPLEMENTATION_PLAN.md"
    status_out="$repo_root/STATUS.md"
    changelog_out="$repo_root/CHANGELOG.md"

    # PACK-REVIEW-BD066-068 Finding #3 closure: when flip_mode=1
    # (the `pack tracker disable` flow), the reverse path must be
    # atomic with respect to the tracker.toml mode flip. Snapshot
    # the existing flat files into a backup directory; if any of
    # the emit / strip steps fail, restore from backup and surface
    # a partial-write error WITHOUT flipping the mode. Without this,
    # mid-run failure leaves the user with: (a) partial flat files,
    # (b) tracker.toml still saying mode=tracker — a split state.
    local backup_dir=""
    if [[ "$flip_mode" == "1" ]]; then
        backup_dir="$repo_root/$TMF_PACK_TRACKER_DIR/disable-backup"
        mkdir -p "$backup_dir"
        local f
        for f in BACKLOG.md IMPLEMENTATION_PLAN.md STATUS.md CHANGELOG.md; do
            if [[ -f "$repo_root/$f" ]]; then
                cp "$repo_root/$f" "$backup_dir/$f"
            else
                # Sentinel: file did not exist before the run.
                : > "$backup_dir/$f.sentinel-absent"
            fi
        done
    fi

    local emit_failed=0
    _tmr_emit_backlog             "$issue_jsons" "$backend_slug" "$backlog_out" || emit_failed=1
    _tmr_emit_implementation_plan "$phase_jsons" "$plan_out"                    || emit_failed=1
    _tmr_emit_status              "$issue_jsons" "$phase_jsons"  "$status_out"  || emit_failed=1
    _tmr_emit_changelog           "$changelog_out"                              || emit_failed=1

    # Step 7.5: sidecar (V1 §6.6 + §6.6.1).
    local sidecar_path
    sidecar_path=$(tracker_sidecar_emit "$repo_root" "$mapping" "$include_comments") || true

    # Step 8: strip mirror header from emitted files. Reverse
    # convention: the file is now authoritative, no header needed.
    tracker_mirror_header_strip "$backlog_out"   || emit_failed=1
    tracker_mirror_header_strip "$plan_out"      || emit_failed=1
    tracker_mirror_header_strip "$status_out"    || emit_failed=1
    tracker_mirror_header_strip "$changelog_out" || emit_failed=1

    # Atomicity gate: if any emit/strip failed during a disable
    # flow, restore originals and abort BEFORE the mode flip.
    if [[ "$flip_mode" == "1" && "$emit_failed" == "1" ]]; then
        local restored=0
        for f in BACKLOG.md IMPLEMENTATION_PLAN.md STATUS.md CHANGELOG.md; do
            if [[ -f "$backup_dir/$f.sentinel-absent" ]]; then
                # File didn't exist before the run; remove the half-written one.
                rm -f "$repo_root/$f"
                restored=$((restored + 1))
            elif [[ -f "$backup_dir/$f" ]]; then
                cp "$backup_dir/$f" "$repo_root/$f"
                restored=$((restored + 1))
            fi
        done
        rm -rf "$backup_dir"
        tracker_error_emit "partial-write" \
            "disable: emit step failed; flat files restored from backup ($restored files); tracker mode unchanged" \
            "Re-run 'pack tracker disable' after addressing the underlying error."
        return 1
    fi

    # Step 9: update tracker.toml. Now safe to flip mode (if requested).
    _tmr_update_tracker_toml "$cfg_path" "$flip_mode"

    # Clean up backup on success.
    [[ -n "$backup_dir" && -d "$backup_dir" ]] && rm -rf "$backup_dir"

    cat <<EOF

reverse: complete.
  entries:    $n_entries
  phases:     $n_phases
  files:      BACKLOG.md, IMPLEMENTATION_PLAN.md (if absent), STATUS.md, CHANGELOG.md (if absent)
  sidecar:    $sidecar_path
  mode-flip:  $([[ "$flip_mode" == "1" ]] && echo "yes (mode.state=flat-file)" || echo "no")
EOF
}
