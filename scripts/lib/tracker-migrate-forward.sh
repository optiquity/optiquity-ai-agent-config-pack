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
#   ## File / Symbol
#
#   <file_symbol>     (omitted if empty)
#
#   ## Context
#
#   <context>          (omitted if empty)
#
#   ## Resolution
#
#   <resolution>       (omitted if empty)
#
# Type: / Status: / Blockers: / Unblocks: are NOT in the body — they
# map to labels and link relationships per V1 §4.1. File/Symbol IS in
# the body per V1 §4.1 ("kept verbatim; not a GH first-class concept").
tmf_compose_issue_body() {
    local pack_id="$1"
    local description="$2"
    local context="${3:-}"
    local resolution="${4:-}"
    local file_symbol="${5:-}"
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
        if [[ -n "$file_symbol" ]]; then
            printf '\n## File / Symbol\n\n%s\n' "$file_symbol"
        fi
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

# tmf_create_or_lookup <entry-json> <mapping-json>
# Probes V1 §6.2's three idempotency markers in order:
#   (a) mapping file (fast path)
#   (b) title-marker search (recovery path)
#   (c) body-footer marker (verification of search hits, V1 §6.2
#       line 1031 "two redundant markers ... if a future GH version
#       strips it, we fall back to title marker only")
#
# Emits a JSON envelope on stdout:
#   {"action": "skip",   "gh_id": "<id>", "url": "<url>"}   (a) or (b+c) match
#   {"action": "create"}                                     no marker found
#
# When (b) returns a hit, this function calls provider_get on the
# first hit and verifies the body contains `<!-- pack-id: <ID> -->`.
# A title hit without the body marker is treated as a stale-title
# false positive and falls through to "create". This closes the
# Finding #1 + #8 recovery contract.
tmf_create_or_lookup() {
    local entry="$1"
    local mapping="$2"
    local pack_id
    pack_id=$(printf '%s' "$entry" | jq -r '.pack_id')

    # 4a: already mapped?
    local mapped_id mapped_url
    mapped_id=$(printf '%s' "$mapping" | jq -r --arg k "$pack_id" 'if has($k) then .[$k].id else empty end')
    if [[ -n "$mapped_id" && "$mapped_id" != "null" ]]; then
        mapped_url=$(printf '%s' "$mapping" | jq -r --arg k "$pack_id" 'if has($k) then .[$k].url else "" end')
        jq -n --arg id "$mapped_id" --arg url "$mapped_url" \
            '{action: "skip", gh_id: $id, url: $url}'
        return 0
    fi

    # 4b: title-marker search.
    local search_result
    if ! search_result=$(provider_search "in:title \"$pack_id:\"" 5 2>/dev/null); then
        echo '{"action": "create"}'
        return 0
    fi
    local hit_count
    hit_count=$(printf '%s' "$search_result" | jq -r '.items | length')
    if [[ "$hit_count" -eq 0 ]]; then
        echo '{"action": "create"}'
        return 0
    fi

    # 4c: verify body-footer marker on each hit. The first hit whose
    # body contains the canonical pack-id marker is a recovered match.
    local i=0 hit_id hit_url issue_json body
    while [[ $i -lt $hit_count ]]; do
        hit_id=$(printf '%s' "$search_result"  | jq -r ".items[$i].id // .items[$i].number")
        hit_url=$(printf '%s' "$search_result" | jq -r ".items[$i].url // \"\"")
        if issue_json=$(provider_get "$hit_id" 2>/dev/null); then
            body=$(printf '%s' "$issue_json" | jq -r '.body // ""')
            if [[ "$body" == *"<!-- pack-id: $pack_id -->"* ]]; then
                jq -n --arg id "$hit_id" --arg url "$hit_url" \
                    '{action: "skip", gh_id: $id, url: $url}'
                return 0
            fi
        fi
        i=$((i + 1))
    done

    # No verified body marker among title hits; treat as needs-create.
    echo '{"action": "create"}'
}

# ─────────────────────────────────────────────────────────────────
# Top-level orchestrator (V1 §6.2 steps 1–11)
# ─────────────────────────────────────────────────────────────────

# tracker_migrate_forward_run <repo-root> <dry-run> <resume> [<mirror-only>]
# Top-level forward migration entry point invoked by tracker-migrate.sh.
# Reports per-step status to stdout; emits typed errors to stderr.
#
# mirror_only=1 (BD-065 review fix #10): skip every step except step 10
# (mirror regen). Used by `pack tracker mirror-rebuild` to refresh the
# mirror header timestamp without touching the tracker. The mapping
# file is read but not modified.
tracker_migrate_forward_run() {
    local repo_root="$1"
    local dry_run="${2:-0}"
    local resume="${3:-0}"
    local mirror_only="${4:-0}"

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

    # Mirror-only short-circuit: skip steps 1–9 + step 11; just regen
    # the mirror header. Used by `pack tracker mirror-rebuild`.
    if [[ "$mirror_only" == "1" ]]; then
        local backend_slug backlog_path
        backend_slug=$(tracker_repo_slug "$cfg_path" 2>/dev/null || echo "unknown")
        backlog_path="$repo_root/BACKLOG.md"
        if [[ ! -f "$backlog_path" ]]; then
            tracker_error_emit "not-found" \
                "forward --mirror-only: BACKLOG.md not found at $backlog_path"
            return 1
        fi
        _tmf_regen_mirror "$backlog_path" "$backend_slug"
        echo "forward --mirror-only: BACKLOG.md mirror header refreshed"
        return 0
    fi

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

    # Partial-failure tracking (V1 §9.6 partial-write surface).
    # File-backed because bash 3.2 arrays do not survive subshells.
    local partial_failures
    partial_failures=$(mktemp -t tmf-pf.XXXXXX)
    : > "$partial_failures"

    # Steps 4–9: per-entry work.
    local idx=0 created=0 skipped=0 recovered=0 closed=0
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

        local routing action gh_id url
        routing=$(tmf_create_or_lookup "$entry" "$mapping")
        action=$(printf '%s' "$routing" | jq -r '.action')

        case "$action" in
            skip)
                # Already mapped, OR recovered via title+body marker probe
                # (Findings #1 + #8). If recovered and not yet in mapping,
                # register it now so subsequent steps (links/close) run.
                gh_id=$(printf '%s' "$routing" | jq -r '.gh_id // ""')
                url=$(printf   '%s' "$routing" | jq -r '.url   // ""')
                if [[ -n "$gh_id" ]]; then
                    if ! printf '%s' "$mapping" | jq -e --arg k "$pack_id" 'has($k)' >/dev/null 2>&1; then
                        mapping=$(tmf_mapping_set "$mapping" "$pack_id" "$gh_id" "$url")
                        tmf_mapping_save "$mapping_file" "$mapping"
                        recovered=$((recovered + 1))
                    fi
                fi
                skipped=$((skipped + 1))
                ;;
            create)
                local title body labels_json result
                local description context resolution file_symbol
                title="$pack_id: $(printf '%s' "$entry" | jq -r '.title')"
                description=$(printf '%s' "$entry" | jq -r '.description // ""')
                context=$(printf '%s'     "$entry" | jq -r '.context // ""')
                resolution=$(printf '%s'  "$entry" | jq -r '.resolution // ""')
                file_symbol=$(printf '%s' "$entry" | jq -r '.file_symbol // ""')
                body=$(tmf_compose_issue_body "$pack_id" "$description" "$context" "$resolution" "$file_symbol")
                labels_json=$(_tmf_labels_for_entry "$entry")

                local payload
                payload=$(jq -n \
                    --arg t "$title" \
                    --arg b "$body" \
                    --argjson l "$labels_json" \
                    '{title: $t, body: $b, labels: $l}')

                if ! result=$(provider_create "$payload"); then
                    rm -f "$partial_failures"
                    return 1
                fi
                gh_id=$(printf '%s' "$result" | jq -r '.id')
                url=$(printf '%s'   "$result" | jq -r '.url // ""')
                mapping=$(tmf_mapping_set "$mapping" "$pack_id" "$gh_id" "$url")
                # Finding #7: persist mapping after EVERY create so a
                # mid-loop failure cannot lose the create→mapping window.
                tmf_mapping_save "$mapping_file" "$mapping"
                created=$((created + 1))
                ;;
        esac

        # Steps 8 + 9: close-on-Resolved + Resolution comment. Run for
        # both create and skip-with-gh_id paths so a recovered entry's
        # status flip is honoured. Failures here are tracked, not fatal
        # (V1 §9.6 partial-write).
        if [[ -n "$gh_id" ]]; then
            local status resolution
            status=$(printf '%s' "$entry" | jq -r '.status')
            resolution=$(printf '%s' "$entry" | jq -r '.resolution // ""')
            case "$status" in
                Resolved|Cancelled|Deprecated)
                    local reason
                    case "$status" in
                        Resolved)              reason="completed" ;;
                        Cancelled|Deprecated)  reason="not_planned" ;;
                    esac
                    if ! provider_close "$gh_id" "$reason" >/dev/null 2>&1; then
                        printf 'step-8 close: %s (%s)\n' "$pack_id" "gh_id=$gh_id" >> "$partial_failures"
                    else
                        closed=$((closed + 1))
                    fi
                    if [[ -n "$resolution" ]]; then
                        if ! provider_comment "$gh_id" "$resolution" >/dev/null 2>&1; then
                            printf 'step-9 comment: %s (%s)\n' "$pack_id" "gh_id=$gh_id" >> "$partial_failures"
                        fi
                    fi
                    ;;
            esac
        fi

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
                        if provider_sub_issue_create "$parent_gh_id" \
                            "{\"existing_id\": \"$gh_id\"}" >/dev/null 2>&1; then
                            linked_parent=$((linked_parent + 1))
                        else
                            printf 'step-6 sub_issue_create: %s -> %s\n' \
                                "$pack_id" "$raw" >> "$partial_failures"
                        fi
                    fi
                    ;;
                BD-*|TD-*)
                    local other_gh_id
                    other_gh_id=$(tmf_mapping_get "$mapping" "$raw" || echo "")
                    if [[ -n "$other_gh_id" ]]; then
                        if provider_link "$gh_id" "$other_gh_id" "blocked-by" >/dev/null 2>&1; then
                            linked_blocked=$((linked_blocked + 1))
                        else
                            printf 'step-7 link blocked-by: %s -> %s\n' \
                                "$pack_id" "$raw" >> "$partial_failures"
                        fi
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
  recovered:  $recovered
  closed:     $closed
  phases:     $phase_count (created: $phase_created)
  links:      parent=$linked_parent, blocked-by=$linked_blocked
  mapping:    $mapping_file
EOF

    # Surface partial-write per V1 §9.6 if any post-create steps failed.
    # The forward-side state is consistent (mapping file persisted; idempotent
    # re-run will retry the failed steps); the user is told what to fix.
    if [[ -s "$partial_failures" ]]; then
        local n_pf
        n_pf=$(wc -l < "$partial_failures" | tr -d ' ')
        local extras=()
        while IFS= read -r line; do
            extras+=("  - $line")
        done < "$partial_failures"
        rm -f "$partial_failures"
        tracker_error_emit "partial-write" \
            "Forward migration completed with $n_pf step failure(s); per-step list above. Idempotent re-run will retry." \
            "${extras[@]}"
        return 1
    fi
    rm -f "$partial_failures"
    return 0
}

# ─────────────────────────────────────────────────────────────────
# Status subcommand (V1 §6.1 + V2 §22.1)
# ─────────────────────────────────────────────────────────────────

# tracker_migrate_status_report <repo-root>
# Reports the 8-field tracker state surface per V2 §22.1:
#   mode, backend, repo, mapping count + freshness, mirror freshness,
#   template freshness, last-forward-run, last-reverse-run.
#
# Each field that cannot be resolved (e.g. tracker.toml absent,
# mapping file absent, mirror file absent) reports "(none)" rather
# than failing — status is a diagnostic verb and must work in flat-
# file mode too.
tracker_migrate_status_report() {
    local repo_root="$1"
    local cfg_path
    cfg_path=$(tracker_config_resolve_path pack "$repo_root") || return 1

    local mode backend repo
    mode=$(tracker_mode "$cfg_path")
    if [[ -f "$cfg_path" ]]; then
        backend=$(tracker_backend_name "$cfg_path" 2>/dev/null || echo "(none)")
        repo=$(tracker_repo_slug    "$cfg_path" 2>/dev/null || echo "(none)")
    else
        backend="(none)"
        repo="(none)"
    fi

    # Mapping count + freshness.
    local mapping_file mapping_count mapping_age
    mapping_file=$(_tmf_mapping_file "$repo_root")
    if [[ -f "$mapping_file" ]]; then
        mapping_count=$(jq 'length' "$mapping_file" 2>/dev/null || echo "0")
        mapping_age=$(date -r "$mapping_file" -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo "unknown")
    else
        mapping_count="0"
        mapping_age="(no mapping file)"
    fi

    # Mirror freshness — file mtime of the BACKLOG.md mirror, or
    # "(none)" if the file lacks the V1 §6.3 read-only header.
    local mirror_path mirror_age
    mirror_path="$repo_root/BACKLOG.md"
    if [[ -f "$mirror_path" ]]; then
        local first_line
        first_line=$(head -n 1 "$mirror_path" 2>/dev/null || echo "")
        if [[ "$first_line" == "<!--" ]]; then
            mirror_age=$(date -r "$mirror_path" -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo "unknown")
        else
            mirror_age="(no mirror header)"
        fi
    else
        mirror_age="(no BACKLOG.md)"
    fi

    # Template freshness — newest mtime among the live issue templates.
    local tmpl_age tmpl_dir tmpl_newest
    tmpl_dir="$repo_root/.github/ISSUE_TEMPLATE"
    if [[ -d "$tmpl_dir" ]]; then
        tmpl_newest=$(ls -t "$tmpl_dir"/*.yml 2>/dev/null | head -n 1)
        if [[ -n "$tmpl_newest" && -f "$tmpl_newest" ]]; then
            tmpl_age=$(date -r "$tmpl_newest" -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo "unknown")
        else
            tmpl_age="(no templates)"
        fi
    else
        tmpl_age="(no .github/ISSUE_TEMPLATE)"
    fi

    # Last forward / reverse run from tracker.toml.
    local last_forward last_reverse
    if [[ -f "$cfg_path" ]]; then
        last_forward=$(tracker_config_get "$cfg_path" "migration.last_forward_run" 2>/dev/null || echo "(never)")
        last_reverse=$(tracker_config_get "$cfg_path" "migration.last_reverse_run" 2>/dev/null || echo "(never)")
    else
        last_forward="(never)"
        last_reverse="(never)"
    fi

    cat <<EOF
tracker mode:        $mode
backend:             $backend
repo:                $repo
mapping count:       $mapping_count entries
mapping freshness:   $mapping_age
mirror freshness:    $mirror_age
template freshness:  $tmpl_age
last forward run:    $last_forward
last reverse run:    $last_reverse
EOF
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
# read-only header. The body content is preserved verbatim modulo
# the header itself. Idempotent: N consecutive runs produce
# byte-equal output (modulo the timestamp inside the header).
#
# Invariant (V1 §6.7 round-trip safety): the body extraction is
# whitespace-tolerant — any leading whitespace on `<!--` / `-->`
# tags or a blank gap between header and body is normalized out.
_tmf_regen_mirror() {
    local path="$1"
    local backend_slug="$2"
    if [[ ! -f "$path" ]]; then
        return 0
    fi
    local now_iso
    now_iso=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    python3 - "$path" "$backend_slug" "$now_iso" <<'PYEOF' || return 1
import re, sys
path, backend_slug, now_iso = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path) as f:
    text = f.read()

# Strip a leading mirror-header block + any blank-line gap that
# follows it. The header opens with `<!--` (possibly indented or
# trailing-whitespace-padded) and closes with `-->`. Anything
# in between is replaced wholesale.
m = re.match(r'\s*<!--\s*\n.*?\n\s*-->\s*\n+', text, re.DOTALL)
if m:
    body = text[m.end():]
else:
    body = text

# Normalize: strip trailing newlines from body to a single one;
# we'll add exactly one blank line between header and body.
body = body.rstrip('\n') + '\n'

header = (
    "<!--\n"
    "  This file is a read-only mirror generated from the tracker.\n"
    f"  Tracker: github / {backend_slug}\n"
    f"  Last regenerated: {now_iso}\n"
    "  Direct edits will be overwritten. Edit via Pack Chat / PM Chat.\n"
    "-->\n"
)
out = header + "\n" + body
with open(path, 'w') as f:
    f.write(out)
PYEOF
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
