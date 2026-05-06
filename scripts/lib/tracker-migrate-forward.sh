# scripts/lib/tracker-migrate-forward.sh — V1 §6.2 forward migration
# (BD-065).
#
# Forward direction: flat-file → tracker. Idempotent across re-runs;
# checkpoint resumes a partial run exactly where it left off (V1 §6.4).
#
# Sourced by scripts/tracker-migrate.sh. Depends on:
#   - scripts/lib/tracker-provider.sh + tracker-provider-gh.sh (BD-060)
#   - scripts/lib/tracker-config.sh (BD-061)
#   - scripts/lib/tracker-errors.sh (BD-070)
#
# Algorithm (V1 §6.2 steps 1–11):
#   1. Read flat-file source-of-truth.
#   2. Parse with v10 grammar.
#   3. Load mapping file from .pack-tracker/id-map.json.
#   4. For each BACKLOG entry: skip-if-mapped → search-for-marker →
#      provider_create.
#   5. For each phase: create phase epic.
#   6. Sub-issue link TD→phase.
#   7. Blocked-by links.
#   8. Close on Resolved.
#   9. Comment with Resolution.
#   10. Regenerate flat-file mirror with the V1 §6.3 read-only header.
#   11. Write mapping file + tracker.toml [migration].last_forward_run.
#
# Idempotency markers (V1 §6.2):
#   - Title marker: `<PREFIX>-NNN:` is grep-able via `gh search issues`.
#   - Body footer marker: `<!-- pack-id: <PREFIX>-NNN -->` survives
#     GH's Markdown sanitizer.
#   - Mapping file: .pack-tracker/id-map.json is the fast path; markers
#     are the recovery path.
#
# Checkpoint (V1 §6.4): write .pack-tracker/forward.checkpoint.json
# after every $TMF_CHECKPOINT_INTERVAL issues. Resume from this file
# when invoked with --resume.
#
# Phase-task parsing (#### N.M headings) and cross-entity dependency
# orchestration are deferred to BD-106 + BD-108 per Addendum 4 §2.3;
# this BD lands the v10-grammar 11-step algorithm only.
#
# Do NOT add a shebang — this file is sourced, not executed.

# ─────────────────────────────────────────────────────────────────
# Constants
# ─────────────────────────────────────────────────────────────────

# Write a checkpoint after every N successful issue creations
# (V1 §6.4 specifies 25; can be overridden by env for tests).
readonly TMF_CHECKPOINT_INTERVAL="${TMF_CHECKPOINT_INTERVAL:-25}"

# Standard local-state directory; gitignored via BD-061.
readonly TMF_PACK_TRACKER_DIR=".pack-tracker"

# ─────────────────────────────────────────────────────────────────
# Path resolvers
# ─────────────────────────────────────────────────────────────────

_tmf_pack_tracker_dir() {
    local repo_root="$1"
    echo "$repo_root/$TMF_PACK_TRACKER_DIR"
}

_tmf_mapping_file() {
    local repo_root="$1"
    echo "$repo_root/$TMF_PACK_TRACKER_DIR/id-map.json"
}

_tmf_checkpoint_file() {
    local repo_root="$1"
    echo "$repo_root/$TMF_PACK_TRACKER_DIR/forward.checkpoint.json"
}

# ─────────────────────────────────────────────────────────────────
# Mapping file (V1 §6.2 step 3, step 11)
# ─────────────────────────────────────────────────────────────────

# Load mapping file. Emits the JSON content on stdout. If the file
# does not exist, emits an empty object {}.
tmf_mapping_load() {
    local path="$1"
    if [[ -f "$path" ]]; then
        cat "$path"
    else
        echo '{}'
    fi
}

# Save mapping JSON to file atomically (write-tmp + rename).
# Creates parent dir if needed.
tmf_mapping_save() {
    local path="$1"
    local data="$2"
    local dir
    dir=$(dirname "$path")
    mkdir -p "$dir"
    local tmp
    tmp=$(mktemp -t tmf-map.XXXXXX)
    printf '%s\n' "$data" > "$tmp"
    mv "$tmp" "$path"
}

# Look up an entry id (e.g. "BD-001") in the mapping. Emits the
# tracker's GH issue number on stdout if mapped; rc=1 otherwise.
tmf_mapping_get() {
    local data="$1"
    local pack_id="$2"
    local val
    val=$(printf '%s' "$data" | jq -r --arg k "$pack_id" 'if has($k) then .[$k].id else empty end')
    if [[ -z "$val" || "$val" == "null" ]]; then
        return 1
    fi
    echo "$val"
}

# Append an entry to the mapping. Returns the new JSON on stdout.
tmf_mapping_set() {
    local data="$1"
    local pack_id="$2"
    local gh_id="$3"
    local url="${4:-}"
    printf '%s' "$data" | jq --arg k "$pack_id" --arg id "$gh_id" --arg url "$url" \
        '. + {($k): {id: $id, url: $url}}'
}

# ─────────────────────────────────────────────────────────────────
# Checkpoint file (V1 §6.4)
# ─────────────────────────────────────────────────────────────────

# Write checkpoint state. State is a JSON object containing:
#   {
#     "last_step": "<step name>",
#     "completed_pack_ids": ["BD-001", ...],
#     "timestamp": "<ISO8601>"
#   }
tmf_checkpoint_write() {
    local path="$1"
    local state="$2"
    local dir
    dir=$(dirname "$path")
    mkdir -p "$dir"
    local tmp
    tmp=$(mktemp -t tmf-ckp.XXXXXX)
    printf '%s\n' "$state" > "$tmp"
    mv "$tmp" "$path"
}

# Load checkpoint state. Emits JSON on stdout, or {} if missing.
tmf_checkpoint_load() {
    local path="$1"
    if [[ -f "$path" ]]; then
        cat "$path"
    else
        echo '{}'
    fi
}

# Remove checkpoint after a successful full run.
tmf_checkpoint_clear() {
    local path="$1"
    [[ -f "$path" ]] && rm -f "$path"
}

# ─────────────────────────────────────────────────────────────────
# v10-grammar parser (V1 §6.2 step 2)
# ─────────────────────────────────────────────────────────────────

# Parse a v10-shape BACKLOG.md and emit a JSON array of entries on
# stdout. Each entry is:
#   {
#     "pack_id": "BD-001",
#     "title": "<title>",
#     "type": "<TODO(version)|...>",
#     "status": "Open|Unblocked|Resolved|Cancelled|Deprecated",
#     "blockers": ["BD-002", "phase-3", ...],
#     "unblocks": ["BD-003", ...],
#     "file_symbol": "<path or symbol>",
#     "description": "<free text>",
#     "context": "<free text or null>",
#     "resolution": "<free text or null>"
#   }
#
# Implementation: regex-based Python parser. Handles:
#   - **<PREFIX>-NNN — <title>**          (entry header; PREFIX ∈ {BD, TD})
#   - Type:        <value>
#   - Status:      <value>
#   - Blockers:    <value> | one-line OR multi-line indented continuation
#   - Unblocks:    same
#   - File/Symbol: <value>
#   - Description: <multi-line until next field>
#   - Context:     <multi-line until next field>
#   - Resolution:  <multi-line until --- or next entry>
#
# Lines starting with `## ` are treated as section headers (e.g.
# "## Active — v11 Scope") and skipped.
#
# Per V1 §6.2 line 1005: "Parse with the same grammar pm-chat.md
# backlog-status-update variant uses." The v10 grammar is permissive;
# this parser handles the common shapes that appear in pack-repo
# BACKLOG.md, project-template BACKLOGs, and the migrate-v9-to-v10
# fixtures.
tmf_parse_backlog() {
    local path="$1"
    if [[ ! -f "$path" ]]; then
        tracker_error_emit "not-found" "BACKLOG.md not found at $path"
        return 1
    fi
    python3 - "$path" <<'PYEOF'
import re, json, sys
path = sys.argv[1]
with open(path) as f:
    text = f.read()

ENTRY_HEADER = re.compile(r'^\*\*((?:BD|TD)-\d{3})\s*[—-]\s*(.+?)\*\*\s*$')
FIELD_LINE   = re.compile(r'^([A-Z][A-Za-z/ -]+):\s*(.*)$')
SEPARATOR    = re.compile(r'^---\s*$')
SECTION_H2   = re.compile(r'^##\s+')

def parse_id_list(text):
    if not text or text.strip().lower() == "none":
        return []
    items = []
    for chunk in re.split(r'[,;\n]', text):
        chunk = chunk.strip()
        if not chunk or chunk.lower() == "none":
            continue
        items.append(chunk)
    return items

entries = []
current = None
field_being_collected = None

def flush_field():
    global field_being_collected, current
    if not current or not field_being_collected:
        return
    val = current[field_being_collected]
    if isinstance(val, list):
        return
    current[field_being_collected] = val.rstrip()

def flush_entry():
    global current, field_being_collected
    if current is None:
        return
    flush_field()
    field_being_collected = None
    for k in ("blockers", "unblocks"):
        if isinstance(current.get(k), str):
            current[k] = parse_id_list(current[k])
    entries.append(current)
    current = None

for raw in text.splitlines():
    line = raw

    if SEPARATOR.match(line):
        flush_entry()
        continue
    if SECTION_H2.match(line):
        flush_entry()
        continue

    m = ENTRY_HEADER.match(line)
    if m:
        flush_entry()
        current = {
            "pack_id":     m.group(1),
            "title":       m.group(2).strip(),
            "type":        "",
            "status":      "",
            "blockers":    "",
            "unblocks":    "",
            "file_symbol": "",
            "description": "",
            "context":     "",
            "resolution":  "",
        }
        field_being_collected = None
        continue

    if current is None:
        continue

    fm = FIELD_LINE.match(line)
    if fm:
        field_name_raw = fm.group(1).strip().lower()
        rest = fm.group(2).rstrip()
        flush_field()
        # Map header names to entry keys.
        mapping = {
            "type":        "type",
            "status":      "status",
            "blockers":    "blockers",
            "unblocks":    "unblocks",
            "file/symbol": "file_symbol",
            "file-symbol": "file_symbol",
            "description": "description",
            "context":     "context",
            "resolution":  "resolution",
            "resolved":    "resolution",
        }
        key = mapping.get(field_name_raw)
        if key is None:
            field_being_collected = None
            continue
        current[key] = rest
        field_being_collected = key
        continue

    # Continuation line (indented or unindented free text).
    if field_being_collected:
        if current[field_being_collected]:
            current[field_being_collected] += "\n" + line
        else:
            current[field_being_collected] = line
        continue

flush_entry()
print(json.dumps(entries, ensure_ascii=False))
PYEOF
}

# Parse IMPLEMENTATION_PLAN.md and emit a JSON array of phase entries:
#   [
#     {"phase_number": "1", "title": "<phase title>", "anchor": "Phase 1 — <title>"},
#     ...
#   ]
#
# Recognizes `### Phase N — <title>` headings (V1 §6.5 / V3.3 §6.4).
# Phase-task `#### N.M` parsing is deferred to BD-106 per Addendum 4 §2.3.
tmf_parse_implementation_plan() {
    local path="$1"
    if [[ ! -f "$path" ]]; then
        tracker_error_emit "not-found" "IMPLEMENTATION_PLAN.md not found at $path"
        return 1
    fi
    python3 - "$path" <<'PYEOF'
import re, json, sys
path = sys.argv[1]
with open(path) as f:
    text = f.read()

PHASE_HEADER = re.compile(r'^###\s+Phase\s+(\d+)\s*[—-]\s*(.+?)\s*$')

phases = []
for raw in text.splitlines():
    m = PHASE_HEADER.match(raw)
    if m:
        n = m.group(1)
        title = m.group(2).strip()
        phases.append({
            "phase_number": n,
            "title":        title,
            "anchor":       f"Phase {n} — {title}",
        })

print(json.dumps(phases, ensure_ascii=False))
PYEOF
}

# ─────────────────────────────────────────────────────────────────
# Issue body composer (V1 §6.2 step 4c)
# ─────────────────────────────────────────────────────────────────

# Compose the issue body for a parsed BACKLOG entry (V1 §4.1
# field-to-METHODOLOGY mapping). Output:
#
#   <!-- pack-id: <ID> -->
#   <!-- template_version: <bd-v11.0|td-v11.0> -->
#   <!-- pack-version: v11 -->
#
#   ## Description
#
#   <description>
#
#   ## Context
#
#   <context>          (omitted if empty)
#
#   ## Resolution
#
#   <resolution>       (omitted if empty)
#
# Type: / Status: / Blockers: / Unblocks: / File-Symbol: are NOT in
# the body — they map to labels and link relationships per V1 §4.1.
tmf_compose_issue_body() {
    local pack_id="$1"
    local description="$2"
    local context="${3:-}"
    local resolution="${4:-}"
    local template_version
    case "$pack_id" in
        BD-*) template_version="bd-v11.0" ;;
        TD-*) template_version="td-v11.0" ;;
        phase-*) template_version="phase-epic-v11.0" ;;
        *)    template_version="work-item-v11.0" ;;
    esac

    {
        printf '<!-- pack-id: %s -->\n' "$pack_id"
        printf '<!-- template_version: %s -->\n' "$template_version"
        printf '<!-- pack-version: v11 -->\n'
        printf '\n## Description\n\n%s\n' "$description"
        if [[ -n "$context" ]]; then
            printf '\n## Context\n\n%s\n' "$context"
        fi
        if [[ -n "$resolution" ]]; then
            printf '\n## Resolution\n\n%s\n' "$resolution"
        fi
    }
}

# ─────────────────────────────────────────────────────────────────
# Mirror header (V1 §6.3)
# ─────────────────────────────────────────────────────────────────

# Emit the read-only mirror header on stdout. Caller is responsible
# for the rest of the file body.
tmf_mirror_header() {
    local backend_slug="$1"
    local now_iso
    now_iso=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    cat <<EOF
<!--
  This file is a read-only mirror generated from the tracker.
  Tracker: github / $backend_slug
  Last regenerated: $now_iso
  Direct edits will be overwritten. Edit via Pack Chat / PM Chat.
-->
EOF
}

# ─────────────────────────────────────────────────────────────────
# Issue create / lookup (V1 §6.2 step 4)
# ─────────────────────────────────────────────────────────────────

# tmf_create_or_lookup <entry-json> <mapping-json> [<dry-run>]
# Returns one of:
#   "skip"      already in mapping; nothing to do
#   "lookup"    not in mapping but title-marker found upstream;
#               caller updates mapping
#   "create"    needs creation; caller invokes provider_create
# Emits status to stdout; caller dispatches.
tmf_create_or_lookup() {
    local entry="$1"
    local mapping="$2"
    local pack_id
    pack_id=$(printf '%s' "$entry" | jq -r '.pack_id')

    # 4a: already mapped?
    if printf '%s' "$mapping" | jq -e --arg k "$pack_id" 'has($k)' >/dev/null 2>&1; then
        echo "skip"
        return 0
    fi

    # 4b: search tracker for title marker (provider_search returns rc=0
    # on success; we accept either a hit or empty result). The caller
    # interprets and updates the mapping; this function just reports
    # the routing decision.
    local search_result
    if search_result=$(provider_search "in:title \"$pack_id:\"" 5 2>/dev/null); then
        local hit_count
        hit_count=$(printf '%s' "$search_result" | jq -r '.items | length')
        if [[ "$hit_count" -gt 0 ]]; then
            echo "lookup"
            return 0
        fi
    fi

    # 4c: needs creation
    echo "create"
}

# ─────────────────────────────────────────────────────────────────
# Top-level orchestrator (V1 §6.2 steps 1–11)
# ─────────────────────────────────────────────────────────────────

# tracker_migrate_forward_run <repo-root> <dry-run> <resume>
# Top-level forward migration entry point invoked by tracker-migrate.sh.
# Reports per-step status to stdout; emits typed errors to stderr.
tracker_migrate_forward_run() {
    local repo_root="$1"
    local dry_run="${2:-0}"
    local resume="${3:-0}"

    if [[ ! -d "$repo_root" ]]; then
        tracker_error_emit "validation" "forward: repo-root not a directory: $repo_root"
        return 1
    fi

    local cfg_path
    cfg_path=$(tracker_config_resolve_path pack "$repo_root") || return 1
    if [[ ! -f "$cfg_path" ]]; then
        tracker_error_emit "validation" \
            "forward: tracker.toml not found at $cfg_path  (run \`pack tracker init\` first)"
        return 1
    fi

    # Tell the dispatcher which config to consult for backend.name
    # selection (BD-061 dispatcher integration).
    export _TRACKER_PROVIDER_CONFIG_PATH="$cfg_path"

    local mapping_file checkpoint_file
    mapping_file=$(_tmf_mapping_file "$repo_root")
    checkpoint_file=$(_tmf_checkpoint_file "$repo_root")

    local mapping
    mapping=$(tmf_mapping_load "$mapping_file")

    local resume_state='{}'
    if [[ "$resume" == "1" ]]; then
        resume_state=$(tmf_checkpoint_load "$checkpoint_file")
    fi

    # Step 1+2: read + parse BACKLOG and IMPLEMENTATION_PLAN.
    local backlog_path plan_path
    backlog_path="$repo_root/BACKLOG.md"
    plan_path="$repo_root/IMPLEMENTATION_PLAN.md"
    [[ ! -f "$plan_path" ]] && plan_path="$repo_root/maintenance-docs/IMPLEMENTATION_PLAN.md"

    local entries phases
    entries=$(tmf_parse_backlog "$backlog_path") || return 1
    if [[ -f "$plan_path" ]]; then
        phases=$(tmf_parse_implementation_plan "$plan_path") || phases='[]'
    else
        phases='[]'
    fi

    local n_entries n_phases
    n_entries=$(printf '%s' "$entries" | jq 'length')
    n_phases=$(printf '%s'  "$phases"  | jq 'length')
    echo "forward: parsed $n_entries BACKLOG entries, $n_phases phase(s)"
    if [[ "$dry_run" == "1" ]]; then
        echo "forward: --dry-run set; stopping after parse + plan summary"
        return 0
    fi

    # Steps 4–9: per-entry work.
    local idx=0 created=0 skipped=0 looked_up=0 closed=0
    local completed_ids='[]'
    if [[ "$resume" == "1" ]]; then
        completed_ids=$(printf '%s' "$resume_state" | jq -c '.completed_pack_ids // []')
    fi

    local entry_count
    entry_count=$(printf '%s' "$entries" | jq 'length')
    while [[ $idx -lt $entry_count ]]; do
        local entry pack_id
        entry=$(printf '%s' "$entries" | jq -c ".[$idx]")
        pack_id=$(printf '%s' "$entry" | jq -r '.pack_id')

        # Resume: skip already-completed ids.
        if printf '%s' "$completed_ids" | jq -e --arg k "$pack_id" 'index($k)' >/dev/null 2>&1; then
            idx=$((idx + 1))
            continue
        fi

        local routing
        routing=$(tmf_create_or_lookup "$entry" "$mapping")
        case "$routing" in
            skip)
                skipped=$((skipped + 1))
                ;;
            lookup)
                # 4b: title-marker found; record the marker -> caller mapping.
                # In this BD-065 implementation we emit a placeholder; full
                # resolve-from-search logic ships when BD-068 round-trip lands.
                looked_up=$((looked_up + 1))
                ;;
            create)
                local title body labels_json result
                title="$pack_id: $(printf '%s' "$entry" | jq -r '.title')"
                local description context resolution
                description=$(printf '%s' "$entry" | jq -r '.description // ""')
                context=$(printf '%s'     "$entry" | jq -r '.context // ""')
                resolution=$(printf '%s'  "$entry" | jq -r '.resolution // ""')
                body=$(tmf_compose_issue_body "$pack_id" "$description" "$context" "$resolution")
                labels_json=$(_tmf_labels_for_entry "$entry")

                local payload
                payload=$(jq -n \
                    --arg t "$title" \
                    --arg b "$body" \
                    --argjson l "$labels_json" \
                    '{title: $t, body: $b, labels: $l}')

                if ! result=$(provider_create "$payload"); then
                    return 1
                fi
                local gh_id url
                gh_id=$(printf '%s' "$result" | jq -r '.id')
                url=$(printf '%s'   "$result" | jq -r '.url // ""')
                mapping=$(tmf_mapping_set "$mapping" "$pack_id" "$gh_id" "$url")
                created=$((created + 1))

                # Step 8: close on Resolved/Cancelled/Deprecated.
                local status
                status=$(printf '%s' "$entry" | jq -r '.status')
                case "$status" in
                    Resolved|Cancelled|Deprecated)
                        local reason
                        case "$status" in
                            Resolved)              reason="completed" ;;
                            Cancelled|Deprecated)  reason="not_planned" ;;
                        esac
                        provider_close "$gh_id" "$reason" >/dev/null || true
                        closed=$((closed + 1))
                        # Step 9: comment with resolution text if present.
                        if [[ -n "$resolution" ]]; then
                            provider_comment "$gh_id" "$resolution" >/dev/null || true
                        fi
                        ;;
                esac
                ;;
        esac

        # Track completion + checkpoint.
        completed_ids=$(printf '%s' "$completed_ids" | jq -c --arg k "$pack_id" '. + [$k]')
        idx=$((idx + 1))
        if [[ $((idx % TMF_CHECKPOINT_INTERVAL)) -eq 0 ]]; then
            local now_iso
            now_iso=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
            local state
            state=$(jq -n --argjson c "$completed_ids" --arg t "$now_iso" \
                '{last_step: "step-4", completed_pack_ids: $c, timestamp: $t}')
            tmf_checkpoint_write "$checkpoint_file" "$state"
            tmf_mapping_save "$mapping_file" "$mapping"
        fi
    done

    # Step 5: phase epics (one per phase from IMPLEMENTATION_PLAN).
    local pidx=0 phase_created=0
    local phase_count
    phase_count=$(printf '%s' "$phases" | jq 'length')
    while [[ $pidx -lt $phase_count ]]; do
        local phase phase_id
        phase=$(printf '%s' "$phases" | jq -c ".[$pidx]")
        phase_id="phase-$(printf '%s' "$phase" | jq -r '.phase_number')"
        if printf '%s' "$mapping" | jq -e --arg k "$phase_id" 'has($k)' >/dev/null 2>&1; then
            pidx=$((pidx + 1))
            continue
        fi
        local phase_title phase_body phase_payload phase_result phase_gh_id phase_url
        phase_title=$(printf '%s' "$phase" | jq -r '.anchor')
        phase_body=$(tmf_compose_issue_body "$phase_id" \
            "Phase epic for $(printf '%s' "$phase" | jq -r '.title')" "" "")
        phase_payload=$(jq -n \
            --arg t "$phase_title" \
            --arg b "$phase_body" \
            '{title: $t, body: $b, labels: ["phase-epic", "template:phase-epic-v11.0"]}')
        if ! phase_result=$(provider_create "$phase_payload"); then
            return 1
        fi
        phase_gh_id=$(printf '%s' "$phase_result" | jq -r '.id')
        phase_url=$(printf '%s'   "$phase_result" | jq -r '.url // ""')
        mapping=$(tmf_mapping_set "$mapping" "$phase_id" "$phase_gh_id" "$phase_url")
        phase_created=$((phase_created + 1))
        pidx=$((pidx + 1))
    done

    # Step 6+7: per-entry parent + blocked-by links.
    local lidx=0 linked_parent=0 linked_blocked=0
    while [[ $lidx -lt $entry_count ]]; do
        local entry pack_id gh_id
        entry=$(printf '%s' "$entries" | jq -c ".[$lidx]")
        pack_id=$(printf '%s' "$entry" | jq -r '.pack_id')
        gh_id=$(tmf_mapping_get "$mapping" "$pack_id" || echo "")
        if [[ -z "$gh_id" ]]; then
            lidx=$((lidx + 1))
            continue
        fi

        # Step 6: phase parent (if Blockers contains a phase-N token,
        # treat the phase epic as a parent for sub-issue purposes).
        local blockers
        blockers=$(printf '%s' "$entry" | jq -c '.blockers // []')
        local b_count b_idx=0
        b_count=$(printf '%s' "$blockers" | jq 'length')
        while [[ $b_idx -lt $b_count ]]; do
            local raw
            raw=$(printf '%s' "$blockers" | jq -r ".[$b_idx]")
            case "$raw" in
                phase-[0-9]*)
                    local parent_gh_id
                    parent_gh_id=$(tmf_mapping_get "$mapping" "$raw" || echo "")
                    if [[ -n "$parent_gh_id" ]]; then
                        provider_sub_issue_create "$parent_gh_id" \
                            "{\"existing_id\": \"$gh_id\"}" >/dev/null || true
                        linked_parent=$((linked_parent + 1))
                    fi
                    ;;
                BD-*|TD-*)
                    local other_gh_id
                    other_gh_id=$(tmf_mapping_get "$mapping" "$raw" || echo "")
                    if [[ -n "$other_gh_id" ]]; then
                        provider_link "$gh_id" "$other_gh_id" "blocked-by" >/dev/null || true
                        linked_blocked=$((linked_blocked + 1))
                    fi
                    ;;
            esac
            b_idx=$((b_idx + 1))
        done
        lidx=$((lidx + 1))
    done

    # Step 10: regenerate flat-file mirror (BACKLOG.md rewrite with
    # the V1 §6.3 read-only header).
    local backend_slug
    backend_slug=$(tracker_repo_slug "$cfg_path" 2>/dev/null || echo "unknown")
    _tmf_regen_mirror "$backlog_path" "$backend_slug"

    # Step 11: write mapping + tracker.toml [migration].last_forward_run.
    tmf_mapping_save "$mapping_file" "$mapping"
    _tmf_update_tracker_toml "$cfg_path"
    tmf_checkpoint_clear "$checkpoint_file"

    cat <<EOF
forward: complete.
  entries:    $entry_count
  created:    $created
  skipped:    $skipped
  looked-up:  $looked_up
  closed:     $closed
  phases:     $phase_count (created: $phase_created)
  links:      parent=$linked_parent, blocked-by=$linked_blocked
  mapping:    $mapping_file
EOF
}

# ─────────────────────────────────────────────────────────────────
# Status subcommand (V1 §6.1 + V2 §22.1)
# ─────────────────────────────────────────────────────────────────

# tracker_migrate_status_report <repo-root>
# Reports mode, mapping freshness, and migration timestamps.
tracker_migrate_status_report() {
    local repo_root="$1"
    local cfg_path
    cfg_path=$(tracker_config_resolve_path pack "$repo_root") || return 1
    local mode mapping_file mapping_age last_forward
    mode=$(tracker_mode "$cfg_path")
    mapping_file=$(_tmf_mapping_file "$repo_root")

    if [[ -f "$mapping_file" ]]; then
        local n
        n=$(jq 'length' "$mapping_file" 2>/dev/null || echo "0")
        mapping_age=$(date -r "$mapping_file" -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo "unknown")
        echo "tracker mode: $mode"
        echo "mapping file: $mapping_file ($n entries, last write $mapping_age)"
    else
        echo "tracker mode: $mode"
        echo "mapping file: $mapping_file (absent)"
    fi
    if [[ -f "$cfg_path" ]]; then
        last_forward=$(tracker_config_get "$cfg_path" "migration.last_forward_run" 2>/dev/null || echo "(never)")
        echo "last forward run: $last_forward"
    fi
}

# ─────────────────────────────────────────────────────────────────
# Helpers (private)
# ─────────────────────────────────────────────────────────────────

# Compose label set for a parsed entry (V1 §4.1 + V3.3 §6.5).
_tmf_labels_for_entry() {
    local entry="$1"
    local pack_id type status
    pack_id=$(printf '%s' "$entry" | jq -r '.pack_id')
    type=$(printf '%s'    "$entry" | jq -r '.type // ""')
    status=$(printf '%s'  "$entry" | jq -r '.status // "Open"')

    local prefix entry_label tmpl_label
    case "$pack_id" in
        BD-*) prefix="bd"; entry_label="bd-entry"; tmpl_label="template:bd-v11.0" ;;
        TD-*) prefix="td"; entry_label="td-entry"; tmpl_label="template:td-v11.0" ;;
        *)    prefix="";   entry_label="";         tmpl_label="" ;;
    esac

    local status_label
    case "$status" in
        Open)        status_label="status:open" ;;
        Unblocked)   status_label="status:unblocked" ;;
        Resolved)    status_label="status:resolved" ;;
        Cancelled)   status_label="status:cancelled" ;;
        Deprecated)  status_label="status:deprecated" ;;
        *)           status_label="status:open" ;;
    esac

    jq -n --arg el "$entry_label" --arg tl "$tmpl_label" --arg sl "$status_label" \
        '[$el, $tl, $sl] | map(select(. != ""))'
}

# Regenerate the BACKLOG.md mirror (in place) with the V1 §6.3
# read-only header. For BD-065's scope we keep the body content
# unchanged (the chat will regenerate on subsequent writes); we
# only add the header if absent.
_tmf_regen_mirror() {
    local path="$1"
    local backend_slug="$2"
    if [[ ! -f "$path" ]]; then
        return 0
    fi
    local first_line
    first_line=$(head -n 1 "$path" 2>/dev/null || echo "")
    if [[ "$first_line" == "<!--" ]]; then
        # Header already present; refresh the timestamp by replacing
        # the first 6 lines (the header block).
        local header body tmp
        header=$(tmf_mirror_header "$backend_slug")
        body=$(awk 'NR == 1 && $0 == "<!--" {flag=1; next} flag && $0 == "-->" {flag=0; next} !flag' "$path")
        tmp=$(mktemp -t tmf-mirror.XXXXXX)
        {
            printf '%s\n' "$header"
            printf '\n%s' "$body"
        } > "$tmp"
        mv "$tmp" "$path"
        return 0
    fi
    # No header; prepend.
    local header tmp
    header=$(tmf_mirror_header "$backend_slug")
    tmp=$(mktemp -t tmf-mirror.XXXXXX)
    {
        printf '%s\n\n' "$header"
        cat "$path"
    } > "$tmp"
    mv "$tmp" "$path"
}

# Update tracker.toml [migration].last_forward_run timestamp.
# V1 §3.1 schema. Done as a line-targeted edit since the parser is
# read-only by design.
_tmf_update_tracker_toml() {
    local cfg="$1"
    if [[ ! -f "$cfg" ]]; then
        return 0
    fi
    local now_iso
    now_iso=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    python3 - "$cfg" "$now_iso" <<'PYEOF'
import re, sys
cfg, now = sys.argv[1], sys.argv[2]
with open(cfg) as f:
    text = f.read()

# In-place line edit: under [migration], replace any existing
# last_forward_run = "..." line, or append one if absent.
section_re = re.compile(r'^\[migration\]\s*$', re.M)
m = section_re.search(text)
if not m:
    # Append the section.
    text = text.rstrip() + '\n\n[migration]\nlast_forward_run = "' + now + '"\n'
else:
    start = m.end()
    # Find the next section header or EOF.
    nxt = re.search(r'^\[', text[start:], re.M)
    end = start + (nxt.start() if nxt else len(text) - start)
    block = text[start:end]
    if re.search(r'^\s*last_forward_run\s*=', block, re.M):
        block = re.sub(r'^\s*last_forward_run\s*=.*$',
                       f'last_forward_run = "{now}"', block, flags=re.M)
    elif re.search(r'^\s*#\s*last_forward_run\s*=', block, re.M):
        block = re.sub(r'^\s*#\s*last_forward_run\s*=.*$',
                       f'last_forward_run = "{now}"', block, flags=re.M)
    else:
        block = block.rstrip() + f'\nlast_forward_run = "{now}"\n'
    text = text[:start] + block + text[end:]

with open(cfg, 'w') as f:
    f.write(text)
PYEOF
}
