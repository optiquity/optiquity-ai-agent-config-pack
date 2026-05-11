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

# Source the shared mirror-header helpers (BD-067 refactor).
# Idempotent: tracker-mirror.sh has no side effects beyond function
# definitions.
# shellcheck disable=SC1091
if ! declare -f tracker_mirror_header_write >/dev/null 2>&1; then
    _tmf_self="${BASH_SOURCE[0]}"
    _tmf_dir="$(cd "$(dirname "$_tmf_self")" && pwd)"
    source "$_tmf_dir/tracker-mirror.sh"
    unset _tmf_self _tmf_dir
fi

# ─────────────────────────────────────────────────────────────────
# Constants
# ─────────────────────────────────────────────────────────────────

# Write a checkpoint after every N successful issue creations
# (V1 §6.4 specifies 25; can be overridden by env for tests).
# Not declared readonly because integration tests re-source the lib
# with a smaller interval to exercise the cadence (PACK-REVIEW-BD065
# Finding #6 closure).
TMF_CHECKPOINT_INTERVAL="${TMF_CHECKPOINT_INTERVAL:-25}"

# Standard local-state directory; gitignored via BD-061.
# Not readonly so test re-sourcing (with overridden TMF_CHECKPOINT_INTERVAL)
# works without redeclaration errors.
TMF_PACK_TRACKER_DIR=".pack-tracker"

# BD-132 close-stabilization wait parameters. After the close loop
# completes, we poll `provider_list state=closed` until the count is
# stable across two successive reads (gh issue close is eventually
# consistent — issues take a measurable beat to reflect closed state
# in subsequent list/get calls; running disable mid-window saw
# inconsistent body/labels and silently dropped ~33% of entries in
# BD-102 Phase A dog-food).
#
# Defaults: poll up to 30 attempts × 2-second sleep (60s ceiling).
# Test seam: TMF_STABILIZE_MAX_ATTEMPTS / TMF_STABILIZE_SLEEP_SECS
# can be overridden to 0 / fractional values to keep test runtimes
# bounded (the deterministic mock test uses 2 attempts × 0s).
# F-8: TMF_STABILIZE_FAIL_LIMIT bounds consecutive provider_list
# failures (default 3) so transient API failures don't silently
# masquerade as "stable at 0".
TMF_STABILIZE_MAX_ATTEMPTS="${TMF_STABILIZE_MAX_ATTEMPTS:-30}"
TMF_STABILIZE_SLEEP_SECS="${TMF_STABILIZE_SLEEP_SECS:-2}"
TMF_STABILIZE_FAIL_LIMIT="${TMF_STABILIZE_FAIL_LIMIT:-3}"

# BD-134 close-retry parameters. The initial step-8 close loop has a
# ~5% partial-write rate observed in BD-102 Phase A dog-food (3 of 56
# named close failures: BD-021/022/023). Cause is most likely transient
# `gh` API rate-limiting or eventually-consistent state on the GitHub
# side. The retry sweep runs AFTER the initial close loop completes —
# this lets the rate-limit window drain before re-attempting, and keeps
# the main close loop simple/fast for the 95% common case.
#
# Approach (b) per BD-134 (end-of-init re-run-failed-closes pass) was
# chosen over approach (a) (per-call retry inline) because:
#   * Failures don't slow down the main close loop — retries happen
#     in a focused sweep at the end where transient errors have time
#     to clear naturally.
#   * Composes cleanly with BD-132 `_tmf_wait_for_close_stabilization`,
#     which runs AFTER the retry sweep. Stabilization sees the final
#     close count and waits for the propagation delay to drain.
#   * Smaller, more contained change to the orchestrator vs. wrapping
#     every provider_close call site.
#
# Defaults: 3 attempts max with 1s/2s/4s exponential backoff between
# attempts (the schedule is held in a space-separated string so bash
# 3.2 can iterate without associative arrays). Test seam: the env
# overrides accept "0" and a "0 0 0" backoff schedule for fast tests
# (the deterministic mock test uses these to keep runtime sub-second).
#
# Bounded by design: TMF_CLOSE_RETRY_MAX_ATTEMPTS caps the per-close
# work at exactly that many provider_close calls. A close that fails
# every attempt is surfaced as a partial-write entry naming the gh-id
# (same as today); the loop never recurses or extends.
TMF_CLOSE_RETRY_MAX_ATTEMPTS="${TMF_CLOSE_RETRY_MAX_ATTEMPTS:-3}"
TMF_CLOSE_RETRY_BACKOFF_SECS="${TMF_CLOSE_RETRY_BACKOFF_SECS:-1 2 4}"

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

# Parse IMPLEMENTATION-PLAN.md and emit a JSON array of phase entries:
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
        tracker_error_emit "not-found" "IMPLEMENTATION-PLAN.md not found at $path"
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
# Mirror header (V1 §6.3) — shared with reverse migration via
# scripts/lib/tracker-mirror.sh (BD-067 refactor).
# ─────────────────────────────────────────────────────────────────

# Back-compat shim: tmf_mirror_header was the BD-065 inline helper.
# Forward callers and tests still use it; we re-export the shared
# tracker_mirror_header_emit under the original name.
tmf_mirror_header() {
    tracker_mirror_header_emit "$@"
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

    local cfg_path surface
    # Auto-detect surface; fall back to pack on indeterminate trees
    # (e.g. test fixtures that have tracker.toml at root without
    # PACK-CHAT.md). BD-066's `init` verb prompts on the same
    # ambiguity; here we choose a permissive default since reverse /
    # status / doctor / mirror-rebuild are diagnostic verbs.
    surface=$(tracker_config_auto_surface "$repo_root" 2>/dev/null) || surface="pack"
    cfg_path=$(tracker_config_resolve_path "$surface" "$repo_root") || return 1
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

    # Step 1+2: read + parse BACKLOG and IMPLEMENTATION-PLAN.
    local backlog_path plan_path
    backlog_path="$repo_root/BACKLOG.md"
    plan_path="$repo_root/IMPLEMENTATION-PLAN.md"
    [[ ! -f "$plan_path" ]] && plan_path="$repo_root/maintenance-docs/IMPLEMENTATION-PLAN.md"

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

    # BD-131: explicit creation-success flag. Set to 0 immediately
    # before any provider_create early-return so step 11's
    # tracker.toml writer can pass the right value to
    # `forward_complete`. Reaching the bottom of the function with
    # creation_ok=1 means: every BACKLOG entry + phase epic produced
    # a usable gh id (close / link / mirror failures are best-effort
    # post-create steps and do NOT degrade the create surface — see
    # _tmf_update_tracker_toml header for the BD-131 semantics).
    local creation_ok=1

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
                    # BD-131: mark creation surface incomplete so any
                    # future refactor that elects to continue past a
                    # create failure (instead of early-return) routes
                    # through step 11 with the right semantics.
                    creation_ok=0
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

        # Track completion + checkpoint. Steps 8 (close) + 9 (comment)
        # are deferred to a dedicated post-link block below per V1 §6.2
        # numeric step order (PACK-REVIEW-BD065 Finding #4 closure).
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

    # Step 5: phase epics (one per phase from IMPLEMENTATION-PLAN).
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
            # BD-131: see paired creation_ok comment above.
            creation_ok=0
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

    # Steps 8 + 9: close-on-Resolved + Resolution comment.
    # Per V1 §6.2 numeric step order, these execute AFTER step 7
    # (link emission) so links land on still-open issues — some
    # backends reject linking to closed issues. PACK-REVIEW-BD065
    # Finding #4 closure: previously these ran inline with step 4,
    # which is the wrong ordering for failure semantics.
    #
    # BD-134: the initial close loop appends failed (pack_id,gh_id,reason)
    # tuples to `failed_closes` rather than to `partial_failures`
    # directly. After the loop completes, _tmf_retry_failed_closes
    # re-attempts each failed close with bounded exponential backoff
    # (TMF_CLOSE_RETRY_MAX_ATTEMPTS / TMF_CLOSE_RETRY_BACKOFF_SECS).
    # Successes are added to `closed`; persistent failures are
    # surfaced via partial_failures (preserving today's contract).
    local failed_closes
    failed_closes=$(mktemp -t tmf-fc.XXXXXX)
    : > "$failed_closes"
    local cidx=0
    while [[ $cidx -lt $entry_count ]]; do
        local entry pack_id gh_id status resolution
        entry=$(printf '%s' "$entries" | jq -c ".[$cidx]")
        pack_id=$(printf '%s' "$entry" | jq -r '.pack_id')
        gh_id=$(tmf_mapping_get "$mapping" "$pack_id" || echo "")
        if [[ -z "$gh_id" ]]; then
            cidx=$((cidx + 1))
            continue
        fi
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
                    # BD-134: defer surfacing — record the (id, reason)
                    # for the retry sweep below. Tab-separated to keep
                    # parsing trivial in bash 3.2.
                    printf '%s\t%s\t%s\n' "$pack_id" "$gh_id" "$reason" >> "$failed_closes"
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
        cidx=$((cidx + 1))
    done

    # BD-134 step-8.4: retry sweep for failed closes. Re-attempts each
    # failed close up to TMF_CLOSE_RETRY_MAX_ATTEMPTS-1 more times with
    # exponential backoff. Closes that succeed in the sweep increment
    # `closed`. Closes that fail every attempt are surfaced as
    # partial-write entries (same observable contract as today minus
    # the transient-failure noise).
    if [[ -s "$failed_closes" ]]; then
        local _retry_recovered _retry_persistent
        _retry_recovered=0
        _retry_persistent=0
        while IFS=$'\t' read -r _rc_pack_id _rc_gh_id _rc_reason; do
            [[ -z "$_rc_gh_id" ]] && continue
            if _tmf_retry_one_close "$_rc_gh_id" "$_rc_reason"; then
                closed=$((closed + 1))
                _retry_recovered=$((_retry_recovered + 1))
            else
                printf 'step-8 close: %s (%s) — failed after %s attempts\n' \
                    "$_rc_pack_id" "gh_id=$_rc_gh_id" "$TMF_CLOSE_RETRY_MAX_ATTEMPTS" \
                    >> "$partial_failures"
                _retry_persistent=$((_retry_persistent + 1))
            fi
        done < "$failed_closes"
        if [[ $_retry_recovered -gt 0 || $_retry_persistent -gt 0 ]]; then
            echo "forward: close-retry sweep — recovered=$_retry_recovered persistent=$_retry_persistent (max-attempts=$TMF_CLOSE_RETRY_MAX_ATTEMPTS)"
        fi
    fi
    rm -f "$failed_closes"

    # BD-132 step 8.5: close-stabilization wait. `gh issue close` is
    # eventually consistent; if a downstream `pack tracker disable` runs
    # while closes are still propagating, the reverse-loop sees
    # inconsistent body/labels and silently skipped ~33% of entries in
    # the BD-102 Phase A dog-food. Block here until the closed-issue
    # count is stable across two consecutive reads, OR the timeout
    # ceiling is hit (in which case we append to partial_failures so
    # the user knows the close ops are still in flight).
    #
    # F-4: track stabilization success/failure. On timeout we DO NOT
    # clear the forward checkpoint below — it remains as a Part 2a
    # race-detection signal for any downstream `disable` from a
    # separate shell that has no visibility into this run's exit code.
    local stabilization_ok=1
    if [[ "$closed" -gt 0 ]]; then
        if ! _tmf_wait_for_close_stabilization "$closed"; then
            stabilization_ok=0
            printf 'step-8.5 close-stabilization timed out after %s attempts — checkpoint preserved as race signal for downstream disable; close ops may still be propagating, wait then re-run forward to clear, OR run `pack tracker init --resume`\n' \
                "$TMF_STABILIZE_MAX_ATTEMPTS" >> "$partial_failures"
        fi
    fi

    # Step 10: regenerate flat-file mirror (BACKLOG.md rewrite with
    # the V1 §6.3 read-only header). Failures surface to the
    # partial_failures list so the user knows to re-run with
    # --mirror-only per V1 §6.4 (PACK-REVIEW-BD065 Finding #9 closure).
    local backend_slug
    backend_slug=$(tracker_repo_slug "$cfg_path" 2>/dev/null || echo "unknown")
    if ! _tmf_regen_mirror "$backlog_path" "$backend_slug" 2>/dev/null; then
        printf 'step-10 mirror regen: %s (re-run with --mirror-only to recover)\n' \
            "$backlog_path" >> "$partial_failures"
    fi

    # Step 11: write mapping + tracker.toml [migration].
    # BD-131: forward_complete is "true" iff the create surface
    # (steps 4 + 5) emitted a usable gh id for every BACKLOG entry +
    # phase epic. By construction, reaching this point with
    # creation_ok=1 means every provider_create either succeeded or
    # was already mapped (skip / recover). Partial closes (step 8) +
    # partial links (steps 6 + 7) + mirror regen failures (step 10)
    # are best-effort and surfaced via the `partial-write` typed
    # error below, but they do NOT degrade the create surface — see
    # the _tmf_update_tracker_toml header for the full semantics.
    tmf_mapping_save "$mapping_file" "$mapping"
    local fc_value
    if [[ "$creation_ok" == "1" ]]; then
        fc_value="true"
    else
        fc_value="false"
    fi
    _tmf_update_tracker_toml "$cfg_path" "$fc_value"
    # BD-131 defense-in-depth: read back the value we just wrote so a
    # silent regex regression in `_tmf_update_tracker_toml` produces
    # a visible WARN instead of leaving downstream `tracker_mode()`
    # quietly resolving to flat-file. Read-back failure does NOT
    # abort the run (the mapping + closes already landed); the
    # operator gets the WARN and can re-run init to recover.
    _tmf_verify_forward_complete "$cfg_path" "$fc_value" || true
    # F-4: only clear the checkpoint if stabilization succeeded.
    # On timeout we preserve it so a separate-shell `disable` will see
    # the Part 2a checkpoint signal and refuse — even if the calling
    # shell's non-zero exit was missed by the operator.
    if [[ "$stabilization_ok" == "1" ]]; then
        tmf_checkpoint_clear "$checkpoint_file"
    fi

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
    local cfg_path surface
    # Auto-detect surface; fall back to pack on indeterminate trees
    # (e.g. test fixtures that have tracker.toml at root without
    # PACK-CHAT.md). BD-066's `init` verb prompts on the same
    # ambiguity; here we choose a permissive default since reverse /
    # status / doctor / mirror-rebuild are diagnostic verbs.
    surface=$(tracker_config_auto_surface "$repo_root" 2>/dev/null) || surface="pack"
    cfg_path=$(tracker_config_resolve_path "$surface" "$repo_root") || return 1

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
# read-only header. Idempotent. Delegated to the shared helper in
# scripts/lib/tracker-mirror.sh (BD-067 refactor).
_tmf_regen_mirror() {
    tracker_mirror_header_write "$@"
}

# BD-132 close-stabilization wait. Poll provider_list scoped to the
# entry-labels this migration uses (`bd-entry`, `td-entry`,
# `phase-epic`) with state=closed, and aggregate the per-label closed
# count, until the count stops growing across two consecutive reads
# AND the count is at least `closes_attempted`, OR the bounded timeout
# is hit. This addresses `gh issue close`'s eventual consistency —
# the BD-102 Phase A dog-food race where init exited with closes in
# flight, then disable saw inconsistent issue state and silently
# dropped ~33% of entries.
#
# F-7: scoping to entry-labels (rather than all closed issues in the
# repo) is necessary on production-scale repos. A bare
# `provider_list state=closed limit=200` on a repo with >200 pre-
# existing closed issues returns 200 on every poll regardless of
# in-flight migration closes; the count appears trivially "stable"
# and the function returns immediately with no actual stabilization
# guarantee. By scoping to entry-labels (which are applied during
# this migration's create step at line 1020-1021), we count only
# migration-relevant issues — re-establishing the stability signal.
#
# F-6: arg renamed `closes_attempted` (the count this migration just
# tried to close). Beyond the no-op short-circuit, it is also used
# as a sanity floor: if the post-stabilization count is < the
# attempted count, propagation is incomplete even if stable across
# two reads, so we keep polling.
#
# F-8: `provider_list` failure (network blip, gh auth glitch) is
# distinguished from "0 results". On per-attempt failure we do NOT
# update prev_count, do NOT count the attempt as evidence of
# stability, and continue. After STAB_FAIL_LIMIT consecutive failures
# we return 1 (timeout-equivalent) to surface the API problem rather
# than silently masking it as "stable at 0".
#
# Args:
#   closes_attempted: integer count of close calls that returned 0
#                     in the just-finished close loop.
# Emits:
#   stdout: per-attempt progress lines.
# Returns:
#   0 on stable count reached (and count >= closes_attempted).
#   1 on timeout OR repeated provider_list failure (caller appends
#                 to partial_failures so the user knows to wait +
#                 re-run before disable).
_tmf_wait_for_close_stabilization() {
    local closes_attempted="${1:-0}"
    if [[ "$closes_attempted" -le 0 ]]; then
        # No closes attempted → nothing to stabilize.
        return 0
    fi
    local prev_count=-1 cur_count attempt=0
    local consecutive_failures=0
    local stab_fail_limit="${TMF_STABILIZE_FAIL_LIMIT:-3}"
    while [[ $attempt -lt $TMF_STABILIZE_MAX_ATTEMPTS ]]; do
        # F-7: scope the closed-count poll to migration entry-labels.
        # Aggregate across the three label families this migration
        # creates, deduplicating by id (a single issue can in
        # principle carry multiple entry labels, though current
        # forward never assigns more than one).
        local read_failed=0
        local _label _list_json _ids_json
        _ids_json='[]'
        for _label in "bd-entry" "td-entry" "phase-epic"; do
            if _list_json=$(provider_list \
                "{\"label\":\"$_label\",\"state\":\"closed\"}" 1000 2>/dev/null); then
                _ids_json=$(printf '%s' "$_list_json" \
                    | jq -nc --argjson acc "$_ids_json" \
                             --argjson l "$_list_json" \
                             '$acc + (($l.items // []) | map(.id // .number | tostring))' \
                    2>/dev/null) || { read_failed=1; break; }
            else
                read_failed=1
                break
            fi
        done
        if [[ "$read_failed" == "1" ]]; then
            # F-8: provider_list failure path. Do NOT update prev_count,
            # do NOT count toward "stable". Track consecutive failures
            # and surface as rc=1 if they pile up.
            consecutive_failures=$((consecutive_failures + 1))
            if [[ "$consecutive_failures" -ge "$stab_fail_limit" ]]; then
                echo "forward: close-stabilization FAILED (provider_list failed $consecutive_failures consecutive times; aborting wait)" >&2
                return 1
            fi
            attempt=$((attempt + 1))
            if [[ $attempt -lt $TMF_STABILIZE_MAX_ATTEMPTS ]]; then
                sleep "$TMF_STABILIZE_SLEEP_SECS" 2>/dev/null || true
            fi
            continue
        fi
        consecutive_failures=0
        cur_count=$(printf '%s' "$_ids_json" | jq -r 'unique | length' 2>/dev/null || echo "0")

        # F-6: stable AND the count meets the floor we attempted to
        # close. If we attempted 53 closes but only see 40 reflected,
        # propagation is still incomplete even if 40 was stable
        # across two reads — keep polling.
        if [[ "$cur_count" == "$prev_count" \
              && "$cur_count" -ge "$closes_attempted" ]]; then
            echo "forward: close-stabilization OK (closed entry-issue count stable at $cur_count, >= $closes_attempted attempted, after $attempt poll(s))"
            return 0
        fi
        prev_count="$cur_count"
        attempt=$((attempt + 1))
        # Skip sleep on the last iteration (we'll just exit the loop).
        if [[ $attempt -lt $TMF_STABILIZE_MAX_ATTEMPTS ]]; then
            # Bash 3.2-compatible: `sleep` accepts fractional/zero values
            # on macOS BSD coreutils. `sleep 0` returns immediately.
            sleep "$TMF_STABILIZE_SLEEP_SECS" 2>/dev/null || true
        fi
    done
    return 1
}

# BD-134 close retry helper. Re-attempts a single failed close up to
# `TMF_CLOSE_RETRY_MAX_ATTEMPTS - 1` times (the original attempt
# already happened in the main close loop), with the backoff schedule
# read from `TMF_CLOSE_RETRY_BACKOFF_SECS`. Returns 0 on the first
# successful attempt; returns 1 if every retry attempt fails.
#
# Bounded by design — the loop iterates exactly
# `TMF_CLOSE_RETRY_MAX_ATTEMPTS - 1` times. A persistent close failure
# (e.g. permission revoked, issue locked, repo archived) cannot loop
# forever.
#
# Backoff schedule is a space-separated list of seconds. With the
# default ("1 2 4") and TMF_CLOSE_RETRY_MAX_ATTEMPTS=3, we wait 1s
# before retry attempt 2 and 2s before retry attempt 3. The 4 is the
# tail value used if the schedule is shorter than the attempt count.
# bash 3.2 + BSD sleep both accept fractional/zero values, so test
# overrides like "0 0 0" run in microseconds.
#
# Args:
#   $1  gh_id   — issue id to close.
#   $2  reason  — close reason (completed | not_planned | duplicate).
# Returns:
#   0 on eventual success; 1 if all attempts fail.
_tmf_retry_one_close() {
    local gh_id="$1"
    local reason="$2"
    local max_attempts="${TMF_CLOSE_RETRY_MAX_ATTEMPTS:-3}"
    if [[ "$max_attempts" -le 1 ]]; then
        # No retries allowed (either disabled or pathological config).
        return 1
    fi
    # Parse the backoff schedule into a positional array. bash 3.2 has
    # no associative arrays, but indexed arrays + word-splitting on a
    # space-separated string work fine.
    # shellcheck disable=SC2206
    local -a backoff=( ${TMF_CLOSE_RETRY_BACKOFF_SECS:-1 2 4} )
    local n_backoff=${#backoff[@]}
    local last_backoff
    if [[ $n_backoff -gt 0 ]]; then
        last_backoff="${backoff[$((n_backoff - 1))]}"
    else
        last_backoff="0"
    fi
    # `attempt` indexes the RETRY pass (1..max_attempts-1). The
    # original attempt already happened and failed, so attempt=1 here
    # is the first retry.
    local attempt=1
    local sleep_secs
    while [[ $attempt -lt $max_attempts ]]; do
        # Pick the backoff value: index = attempt - 1, fall back to
        # the last value if the schedule is shorter.
        local idx=$((attempt - 1))
        if [[ $idx -lt $n_backoff ]]; then
            sleep_secs="${backoff[$idx]}"
        else
            sleep_secs="$last_backoff"
        fi
        sleep "$sleep_secs" 2>/dev/null || true
        if provider_close "$gh_id" "$reason" >/dev/null 2>&1; then
            return 0
        fi
        attempt=$((attempt + 1))
    done
    return 1
}

# Update tracker.toml [migration] section after a forward run.
# V1 §3.1 schema + V1 §3.2 D-5: writes
#   - last_forward_run = "<ISO8601>"
#   - forward_complete = "true" | "false"   (caller-decided)
# so `tracker_mode()` resolves to "tracker" on subsequent invocations
# only when the caller asserts the run produced a usable tracker
# state. Done as a line-targeted edit since the parser is read-only
# by design.
#
# BD-131 semantics — what `forward_complete = true` means:
#   * "All issues created successfully" (the strong signal that the
#     mapping covers every BACKLOG entry + phase epic).
#   * NOT "all close ops succeeded" — close-on-Resolved is best-effort
#     in v11.0 and BD-134 lands the retry-with-backoff that drives
#     the ~5% partial-close residual to ~0. Treating partial closes
#     as forward_incomplete would silently route downstream tooling
#     to flat-file mode after an otherwise successful migration —
#     defeating the opt-in.
#   * Partial-CREATE failures (provider_create returned non-zero on
#     any entry or phase epic): caller MUST pass "false" so
#     `tracker_mode()` keeps resolving to "flat-file" until the next
#     `pack tracker init --resume` completes the create surface.
#
# Args:
#   $1  cfg  — path to the tracker.toml to update
#   $2  fc   — value to write for forward_complete: "true" or "false"
#              (defaults to "true" to preserve pre-BD-131 behavior at
#              every existing call site).
_tmf_update_tracker_toml() {
    local cfg="$1"
    local fc="${2:-true}"
    if [[ ! -f "$cfg" ]]; then
        return 0
    fi
    if [[ "$fc" != "true" && "$fc" != "false" ]]; then
        # Defensive: caller passed something unexpected. Do not write
        # — silently leaving the file unchanged is safer than writing
        # an out-of-schema value.
        echo "forward: _tmf_update_tracker_toml: refusing to write unexpected forward_complete value '$fc' (must be 'true' or 'false')" >&2
        return 1
    fi
    local now_iso
    now_iso=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    python3 - "$cfg" "$now_iso" "$fc" <<'PYEOF'
import re, sys
cfg, now, fc = sys.argv[1], sys.argv[2], sys.argv[3]
with open(cfg) as f:
    text = f.read()

# Use [ \t]* not \s* — \s consumes newlines and breaks line boundaries
# needed for re.sub line-replacement.
def set_in_block(block, key, value_literal):
    """Replace, uncomment, or append `<key> = <value_literal>` in `block`."""
    live_re    = re.compile(r'^[ \t]*' + re.escape(key) + r'[ \t]*=.*$', re.M)
    commented  = re.compile(r'^[ \t]*#[ \t]*' + re.escape(key) + r'[ \t]*=.*$', re.M)
    new_line   = f'{key} = {value_literal}'
    if live_re.search(block):
        return live_re.sub(new_line, block)
    if commented.search(block):
        return commented.sub(new_line, block)
    return block.rstrip() + '\n' + new_line + '\n'

updates = [
    ("last_forward_run", f'"{now}"'),
    ("forward_complete", fc),
]

section_re = re.compile(r'^\[migration\][ \t]*$', re.M)
m = section_re.search(text)
if not m:
    new_section = "\n\n[migration]\n"
    for k, v in updates:
        new_section += f'{k} = {v}\n'
    text = text.rstrip() + new_section
else:
    start = m.end()
    nxt = re.search(r'^\[', text[start:], re.M)
    end = start + (nxt.start() if nxt else len(text) - start)
    block = text[start:end]
    for k, v in updates:
        block = set_in_block(block, k, v)
    text = text[:start] + block + text[end:]

with open(cfg, 'w') as f:
    f.write(text)
PYEOF
}

# Defensive read-back: confirm the on-disk forward_complete matches
# the value we just wrote. Catches any future regex regression in
# `_tmf_update_tracker_toml` that would silently leave the flag at
# its prior value (the BD-131 surface mode — `tracker_mode()` would
# then resolve to flat-file even after a clean forward).
#
# Returns 0 on match, 1 on mismatch. On mismatch, emits a stderr
# warning naming the expected vs actual value. Caller decides
# whether to escalate.
_tmf_verify_forward_complete() {
    local cfg="$1"
    local expected="$2"
    if [[ ! -f "$cfg" ]]; then
        return 0
    fi
    local actual
    actual=$(tracker_config_get "$cfg" "migration.forward_complete" 2>/dev/null || echo "")
    if [[ "$actual" != "$expected" ]]; then
        echo "forward: WARN: tracker.toml [migration].forward_complete read-back mismatch — expected='$expected' actual='${actual:-<empty>}' at $cfg" >&2
        return 1
    fi
    return 0
}
