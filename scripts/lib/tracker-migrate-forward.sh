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

# BD-204 C-5 (C2a): the pack-surface forward read-side enumerates the
# per-entry TREE (`/backlog/*.md`) instead of the deleted monolith. The
# per-entry engine provides the entry-file lister and the line-1
# back-pointer stripper. Source idempotently (no side effects beyond
# function definitions).
# shellcheck disable=SC1091
if ! declare -f pe_list_entry_files >/dev/null 2>&1; then
    _tmf_self="${BASH_SOURCE[0]}"
    _tmf_dir="$(cd "$(dirname "$_tmf_self")" && pwd)"
    source "$_tmf_dir/per-entry/_lib.sh"
    unset _tmf_self _tmf_dir
fi

# BATCH-17 F1 (cross-BD review): step 7 (Blockers: phase-N.M /
# BD-NNN / TD-NNN) and step 7b (phase-task Dependencies bullets) must
# go through BD-108's `tracker_links_create_blocked_by` orchestrator
# so the cycle-graph store at `<repo>/.pack-tracker/links-graph.json`
# is populated by initial forward migration. Without this, the
# cycle-graph store is empty until a `pack td promote --to=phase-N.M`
# runs, leaving forward-migration cycles invisible to subsequent
# link-creation cycle checks. Source the link orchestrator (which in
# turn sources tracker-cycle-check.sh, tracker-errors.sh) idempotently.
# shellcheck disable=SC1091
if ! declare -f tracker_links_create_blocked_by >/dev/null 2>&1; then
    _tmf_self="${BASH_SOURCE[0]}"
    _tmf_dir="$(cd "$(dirname "$_tmf_self")" && pwd)"
    source "$_tmf_dir/tracker-links.sh"
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

# BD-204 §3.3c size-budget safety margin (bytes). A small fixed reserve for
# the marker wrapper + provider-side rendering overhead, subtracted from the
# active provider's provider_body_limit before the overflow check. The
# composer FAILs loud (never truncates) when the composed body would exceed
# `provider_body_limit − TMF_SIZE_SAFETY_MARGIN`. Test seam.
TMF_SIZE_SAFETY_MARGIN="${TMF_SIZE_SAFETY_MARGIN:-2048}"

# BD-204 §3.3d bulk-create pacing. The forward create loop sleeps the active
# provider's declared min-write interval BEFORE each create after the first,
# so a 211-issue burst stays under GH's 80/min + 500/hour secondary cap and
# never trips abuse detection (R-OPS-2/3). The provider DECLARES the rate
# (rate_limits.min_write_interval_s); the loop ENFORCES the gap. TEST SEAM:
# TMF_PACING_SLEEP_CMD lets a unit test substitute a counting no-op for
# `sleep` so the pacing assertion needs no real wall-clock wait;
# TMF_PACING_INTERVAL_OVERRIDE pins the interval offline (no live provider).
TMF_PACING_SLEEP_CMD="${TMF_PACING_SLEEP_CMD:-sleep}"
TMF_PACING_INTERVAL_OVERRIDE="${TMF_PACING_INTERVAL_OVERRIDE:-}"
# Module-level pacing state: how many creates have fired this run. The gate
# sleeps only when >0 (i.e. before the SECOND and later creates).
_TMF_CREATES_DONE=0

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
#
# Additive on the entry level: re-invoking with the same pack_id
# preserves any extra fields previously written under that key (e.g.
# `task_order` set by tmf_mapping_set_phase_task_order). Per BD-106
# review F6 — the previous `. + {($k): ...}` form replaced the entry
# wholesale, silently wiping additive fields on retry / checkpoint
# resume. The new shape `'.[$k] = ((.[$k] // {}) + {id, url})'`
# matches the additive intent documented at line 197 ("v11 phase-task
# entries simply add new keys alongside") and is consistent with the
# pattern used by tmf_mapping_set_phase_task_order at line 234-235.
tmf_mapping_set() {
    local data="$1"
    local pack_id="$2"
    local gh_id="$3"
    local url="${4:-}"
    printf '%s' "$data" | jq --arg k "$pack_id" --arg id "$gh_id" --arg url "$url" \
        '.[$k] = ((.[$k] // {}) + {id: $id, url: $url})'
}

# ─────────────────────────────────────────────────────────────────
# BD-106 — phase-task id-map handling (additive)
# ─────────────────────────────────────────────────────────────────
#
# Phase task IDs (`phase-N.M`) are stored at the same top level as
# BD-NNN / TD-NNN — `mapping["phase-N.M"] = {id, url}` — so existing
# tmf_mapping_get / tmf_mapping_set continue to work for phase tasks
# without modification. The additive helpers below add:
#
#   tmf_mapping_set_phase_task_order — write the per-phase task_order
#     list into mapping["phase-N"].task_order (V3.2 §4.1 step 5e). The
#     phase epic's mapping entry already carries {id, url}; the
#     task_order field is added alongside, NOT replacing them.
#
#   tmf_mapping_get_phase_task_order — read the per-phase task_order.
#     Emits a JSON array on stdout; empty array if not set.
#
# These keep the V3.2/V3.3 schema honored: the phase epic entry can
# carry both the gh-id mapping and the task ordering. The schema is
# documented in maintenance-docs/v11-research/ARCHITECTURE-V3.3-DELTA.md
# §4.1.

# tmf_mapping_set_phase_task_order <data> <phase-id> <task-numbers-csv>
# Add or update mapping["phase-N"].task_order = [<m1>, <m2>, ...].
# task_numbers_csv is a comma-separated list of integer task numbers
# (e.g. "1,3,2"). Preserves any existing fields on the phase entry.
tmf_mapping_set_phase_task_order() {
    local data="$1"
    local phase_id="$2"
    local task_csv="$3"
    if [[ ! "$phase_id" =~ ^phase-[0-9]+$ ]]; then
        tracker_error_emit "validation" "tmf_mapping_set_phase_task_order: invalid phase id $phase_id"
        return 1
    fi
    # Convert CSV → JSON array of strings.
    local order_json
    order_json=$(printf '%s' "$task_csv" | python3 -c '
import sys, json
parts = [p.strip() for p in sys.stdin.read().split(",") if p.strip()]
print(json.dumps(parts))
')
    printf '%s' "$data" | jq --arg k "$phase_id" --argjson order "$order_json" \
        '.[$k] = ((.[$k] // {}) + {task_order: $order})'
}

# tmf_mapping_get_phase_task_order <data> <phase-id>
# Read mapping["phase-N"].task_order. Emits a JSON array (possibly
# empty) on stdout. rc=0 always.
tmf_mapping_get_phase_task_order() {
    local data="$1"
    local phase_id="$2"
    printf '%s' "$data" | jq -c --arg k "$phase_id" \
        '(.[$k] // {}) | (.task_order // [])'
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
    _tmf_parse_backlog_file "$path"
}

# BD-204 C-5 (C2a): parse a monolith-grammar entry-stream FILE into the
# entries-JSON array. Factored out of tmf_parse_backlog so the pack
# read-side can feed it either the monolith file (client branch — BD-207)
# OR a tree-derived entry-stream temp file (pack branch — see
# tmf_parse_backlog_tree) WITHOUT diverging the parse grammar. The
# downstream entries-JSON shape (and therefore the provider_create payload
# path) is identical for both. The python heredoc reads the path via
# sys.argv (a `python3 - <file>` stdin-heredoc cannot ALSO read piped
# stdin), so the tree path materializes its stream to a temp file first.
_tmf_parse_backlog_file() {
    python3 - "$1" <<'PYEOF'
import re, json, sys
with open(sys.argv[1]) as _f:
    text = _f.read()

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

# BD-204 §3.3 verbatim-body-blob carrier: capture the entry's RAW span
# (lines 2..EOF of its per-entry file = the bold-header line + every
# field/prose line below it, verbatim — no re-parse, no parse_id_list, no
# continuation folding). This is the round-trip TRUTH the gz64 blob carries;
# the parsed fields below are only the label/link/H2 PROJECTION.
#
# The capture is DECOUPLED from the projection's flush logic (which closes a
# field-entry on an interior `## ` H2 — e.g. BD-167/169 in-body `## Sub-entry`
# sections). The raw span is bounded ONLY by the entry boundaries: the next
# `**BD-NNN — ...**` header or the inter-entry `---` separator. An interior
# H2 is entry CONTENT and rides into raw_body verbatim. raw_body excludes the
# line-1 back-pointer (stripped upstream) and the `---` separator (a stream
# artifact); trailing blank lines the separator-join injects are stripped so
# raw_body equals the original file's lines 2..EOF exactly (every per-entry
# file ends with one trailing newline, no blank line).
raw_body_by_pid = {}
raw_pid = None
raw_lines = None

def finalize_raw():
    global raw_pid, raw_lines
    if raw_pid is None:
        raw_lines = None
        return
    rl = list(raw_lines or [])
    while rl and rl[-1] == "":
        rl.pop()
    raw_body_by_pid[raw_pid] = ("\n".join(rl) + "\n") if rl else ""
    raw_pid = None
    raw_lines = None

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
    # BD-204 rehearsal run-3 Defect C: the `Resolved:` header maps onto the
    # `resolution` key (mapping below), and the entry grammar's UNRESOLVED
    # placeholder is the literal bare `n/a` (`Resolved: n/a` on every open
    # entry per backlog/_rules.md; the reverse emitter's inverse rule in
    # _tmr_emit_backlog writes `Resolution: <res>` when non-empty, else
    # `Resolved: n/a`). A bare `n/a` therefore means NO resolution — project
    # it as EMPTY so all three projection actors agree: the composer
    # (tmf_compose_issue_body) emits NO `## Resolution` H2 (empty-omission
    # rule), the divergence comparator (_tmr_check_blob_h2_divergence, which
    # re-parses the blob through THIS parser) expects NO H2, and a
    # tracker-side edit (tracker_edit_entry / the run-3 oracle CRUD leg)
    # that recomposes with an empty resolution matches both. Pre-fix, the
    # phantom `## Resolution\n\nn/a` projection made the post-edit reverse
    # flag a false `(Resolution)` divergence (run-3 issue #4 / BD-904).
    # Scope-audited: ONLY the resolution key normalizes, and ONLY a bare
    # (whitespace-trimmed, case-insensitive) `n/a` — placeholder-with-
    # content values (e.g. `File/Symbol: n/a — new dir`) and real
    # resolution text (`Resolved: 2026-04-01 — fixed...`) are untouched;
    # File/Symbol and Context have no bare-`n/a` placeholder convention.
    res = current.get("resolution", "")
    if isinstance(res, str) and res.strip().lower() == "n/a":
        current["resolution"] = ""
    entries.append(current)
    current = None

for raw in text.splitlines():
    line = raw

    if SEPARATOR.match(line):
        # The `---` separator is the entry boundary: it closes BOTH the
        # projection entry AND the verbatim raw-body capture.
        flush_entry()
        finalize_raw()
        continue
    if SECTION_H2.match(line):
        # An interior H2 closes the PROJECTION field-entry (a `## ` line is
        # not a carried field), but it is entry CONTENT for the verbatim
        # capture — keep accumulating raw_lines.
        flush_entry()
        if raw_lines is not None:
            raw_lines.append(line)
        continue

    m = ENTRY_HEADER.match(line)
    if m:
        # A new header is the entry boundary: close the prior projection +
        # raw capture, then begin both fresh WITH the header line captured.
        flush_entry()
        finalize_raw()
        raw_pid = m.group(1)
        raw_lines = [line]
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

    # Verbatim capture: every entry-body line (after the header, including
    # interior `## Sub-entry` H2 sections and the prose below them) rides into
    # raw_body exactly as read. This runs BEFORE the `current is None` guard so
    # that content following an interior H2 (which closed the projection entry)
    # is still captured for the verbatim blob.
    if raw_lines is not None:
        raw_lines.append(line)

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
finalize_raw()

# Attach the verbatim captured span to each parsed entry by pack_id. An
# interior `## Sub-entry` H2 closes the projection entry mid-file but the
# raw capture spans the whole entry (header → `---`), so each pack_id maps to
# exactly its full lines-2..EOF body.
for e in entries:
    e["raw_body"] = raw_body_by_pid.get(e.get("pack_id", ""), "")

print(json.dumps(entries, ensure_ascii=False))
PYEOF
}

# BD-204 C-5 (C2a): parse the per-entry TREE under <stream_dir> into the
# SAME entries-JSON array tmf_parse_backlog produces. Enumerates the
# stream's entry files via pe_list_entry_files (the SAME single source the
# backup set + `_toc.md` regen use), strips each file's line-1 back-pointer,
# and concatenates the entry bodies into the monolith-grammar stream the
# shared `_tmf_parse_backlog_text` core consumes — keeping the downstream
# provider_create payload path byte-for-byte identical to the monolith read.
# $1 = stream key (e.g. pack-backlog); $2 = stream dir (e.g. <root>/backlog).
tmf_parse_backlog_tree() {
    local key="$1"
    local stream_dir="$2"
    if [[ ! -d "$stream_dir" ]]; then
        tracker_error_emit "not-found" "per-entry tree not found at $stream_dir"
        return 1
    fi
    # Build the monolith-grammar entry stream into a temp file: each entry's
    # body (line-1 back-pointer stripped) followed by a `---` separator, in
    # the canonical sort order pe_list_entry_files returns. The temp file
    # lets the shared file-based parser core run unchanged.
    local stream_file f rc
    stream_file=$(mktemp -t tmf-tree-stream.XXXXXX) || {
        tracker_error_emit "validation" "tmf_parse_backlog_tree: mktemp failed"
        return 1
    }
    while IFS= read -r f; do
        [[ -n "$f" ]] || continue
        pe_strip_backpointer_stdin < "$f" >> "$stream_file"
        printf '\n---\n' >> "$stream_file"
    done < <(pe_list_entry_files "$key" "$stream_dir")
    _tmf_parse_backlog_file "$stream_file"
    rc=$?
    rm -f "$stream_file"
    return $rc
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

# tmf_blockers_cycle_precheck <entries-json>
#
# BD-204 (C-8 live-flip defect 2, 2026-06-11): parse-time cycle
# detection over the Blockers digraph, run BEFORE ANY provider call
# (including `--dry-run`, which makes the dry run a zero-mutation
# tree-level data check).
#
# Why: the live backlog carried a mutual block (BD-094 `Blockers: ...,
# BD-095, ...` + BD-095 `Blockers: ..., BD-094`). The per-edge BD-108
# cycle check inside tracker_links_create_blocked_by DID refuse the
# second edge pre-call on every run (verified empirically against the
# live cycle-graph store, 2026-06-11), but the step-7 arms swallowed
# its typed error (`>/dev/null 2>&1`), so each run ended partial-write
# with only the bare unactionable line `step-7 link blocked-by:
# BD-095 -> BD-094` — indistinguishable from a provider failure and
# retried verbatim on every re-run (3x live). GH itself can never
# represent the cycle (its own addBlockedBy validation rejects it), so
# cyclic Blockers data is a DATA error the user must fix in the
# backlog files; fail loud before mutating anything.
#
# Edge vocabulary: the participating tokens are those the step-7 link
# arms are DESIGNED to route to blocked-by edges (BD-108 F3) —
# `BD-NNN`, `TD-NNN`, `phase-N.M`. Bare `phase-N` tokens are v10
# sub-issue PARENT links (step 6) and do not participate in blocked-by
# cycle detection (same exclusion as the V3.3 §5.5 cycle checker).
# KNOWN GAP(functional): TD-TBD — step 7's actual phase-task glob
# (`phase-[0-9][0-9]*.[0-9][0-9]*`, the BD-108 F9 "tightening") only
# matches when BOTH N and M have two or more digits (`phase-12.34`
# matches; `phase-3.2` and `phase-10.2` fall to the `phase-[0-9]*`
# parent arm), so realistic single-digit `phase-N.M` blockers are
# misrouted to the sub-issue-parent path. Latent at v11.0
# (phase-tasks are never in the id-map per BD-108 §10.2, and both
# arms silent-skip absent targets); a dedicated backlog entry anchors
# the glob fix. Harmless for THIS pre-pass: `phase-N.M` tokens are
# pure sinks in the digraph (only BD/TD entries have outgoing edges),
# so they can never close a cycle, and the pre-pass matching a
# superset of actual step-7 routing cannot cause a false refusal.
# Step-7b phase-task `Dependencies` edges
# are not covered here (they come from IMPLEMENTATION-PLAN.md, parsed
# later); they remain guarded per-edge by the BD-108 orchestrator
# check, whose refusal the step-7/7b arms now surface instead of
# swallowing.
#
# Detection is a full (un-bounded) iterative DFS — unlike the K-hop
# BFS in tracker-cycle-check.sh this is a complete static pass over
# the parsed data, so even cycles longer than [graph] cycle_check_k
# are caught here.
#
# rc=0 → acyclic (safe to proceed); rc=1 → cycle(s) found, typed
# validation error on stderr naming every cycle's full path, or the
# entries JSON could not be parsed (fail-closed, schema-reshape).
tmf_blockers_cycle_precheck() {
    local entries="$1"
    local tmp
    tmp=$(mktemp -t tmf-cyclepre.XXXXXX)
    printf '%s' "$entries" > "$tmp"
    local cycles rc=0
    cycles=$(python3 - "$tmp" <<'PYEOF'
import json, re, sys

try:
    with open(sys.argv[1]) as f:
        entries = json.load(f)
except (OSError, ValueError):
    sys.exit(1)
if not isinstance(entries, list):
    sys.exit(1)

# Tokens step 7 is DESIGNED to route to blocked-by edges (BD-108 F3;
# most-specific-first routing in the link loop): BD-NNN / TD-NNN /
# phase-N.M. Bare phase-N is a sub-issue parent link, not a blocked-by
# edge. NOTE: this regex accepts single-digit phase-N.M, which step
# 7's actual glob currently misroutes to the parent arm (see the
# KNOWN GAP note in the shell-side docstring above) — a harmless
# superset here, since phase-N.M tokens are sinks and cannot close a
# cycle.
edge_re = re.compile(r'^(?:BD-[0-9]+|TD-[0-9]+|phase-[0-9]+\.[0-9]+)$')

out = {}
for e in entries:
    if not isinstance(e, dict):
        continue
    pid = e.get('pack_id')
    if not pid:
        continue
    for b in (e.get('blockers') or []):
        if isinstance(b, str) and edge_re.match(b):
            out.setdefault(pid, []).append(b)

# Iterative DFS with GRAY/BLACK coloring; every back edge to a GRAY
# node names one cycle via the current stack path.
WHITE, GRAY, BLACK = 0, 1, 2
color = {}
cycles = []
for start in sorted(out.keys()):
    if color.get(start, WHITE) != WHITE:
        continue
    stack = [(start, iter(out.get(start, [])))]
    stack_path = [start]
    color[start] = GRAY
    while stack:
        node, it = stack[-1]
        advanced = False
        for nxt in it:
            c = color.get(nxt, WHITE)
            if c == GRAY:
                i = stack_path.index(nxt)
                cycles.append(stack_path[i:] + [nxt])
            elif c == WHITE:
                color[nxt] = GRAY
                stack_path.append(nxt)
                stack.append((nxt, iter(out.get(nxt, []))))
                advanced = True
                break
        if not advanced:
            stack.pop()
            stack_path.pop()
            color[node] = BLACK

if cycles:
    for cyc in cycles:
        print("cycle path: %s ('->' = blocked-by)" % " -> ".join(cyc))
    sys.exit(2)
sys.exit(0)
PYEOF
)
    rc=$?
    rm -f "$tmp"
    if [[ $rc -eq 2 ]]; then
        {
            printf 'ERROR: validation\n'
            printf 'MESSAGE: forward: Blockers data contains dependency cycle(s) — refusing before any provider call. Cyclic Blockers data is a data error regardless of tracker backend; fix the Blockers: lines of the entries named below and re-run.\n'
            while IFS= read -r _tmf_cyc_line; do
                [[ -n "$_tmf_cyc_line" ]] && printf '  %s\n' "$_tmf_cyc_line"
            done <<<"$cycles"
            printf '→ Run: pack tracker doctor\n'
        } >&2
        return 1
    elif [[ $rc -ne 0 ]]; then
        tracker_error_emit "schema-reshape" \
            "forward: Blockers cycle pre-check could not parse the entries JSON (fail-closed)"
        return 1
    fi
    return 0
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
#
# BD-204 §3.3: the composer ALSO emits the verbatim-body-blob carrier — a
# 6th DEFAULTED `raw_body` param (`${6:-}`, so the 4-arg phase call site
# still works) is gzip(mtime=0)+base64-encoded into ONE
# `<!-- pack-entry-body-gz64: ... -->` marker alongside the existing trio.
# The blob is AUTHORITATIVE for reverse; the H2 sections are the advisory
# human/GH-render PROJECTION. Two further §3.3c/§3.3d invariants:
#   - SIZE BUDGET (§3.3c): the composer reads the ACTIVE provider's
#     provider_body_limit + provider_body_storage_format, FAILs loud on a
#     rich_text_normalizing backend, and FAILs loud (never truncates) when
#     the composed body exceeds provider_body_limit − TMF_SIZE_SAFETY_MARGIN.
#   - AUTOLINK NEUTRALIZATION (§3.3d): each VISIBLE H2 field value that
#     contains a `#NNN`/bare-`@`/bare-commit-SHA/bare-URL autolink trigger is
#     wrapped in an inline-code span (longer fence if it already has a
#     backtick). The BLOB is UNTOUCHED — it carries the verbatim bytes, so
#     reverse decodes the original tokens exactly (ZERO round-trip effect).

# BD-204 §3.3: deterministic gzip(mtime=0)+base64 of stdin → one line on
# stdout (the gz64 marker payload). Codec PINNED to python3 on EVERY path
# (forward encode + reverse decode) per the all-python3 tracker-lib idiom;
# NO shell gzip(1)/base64(1) whose flags/availability vary by platform.
_tmf_gz64_encode() {
    python3 -c '
import sys, gzip, io, base64
raw = sys.stdin.buffer.read()
buf = io.BytesIO()
with gzip.GzipFile(fileobj=buf, mode="wb", mtime=0) as gz:
    gz.write(raw)
sys.stdout.write(base64.b64encode(buf.getvalue()).decode("ascii"))
'
}

# BD-204 §3.LF.3a — BATCH MODE for the gz64 encode (Option B single-source;
# design §4.6 (S)). ADDITIVE: a NEW input shape (a length-framed multi-record
# stdin), NOT a behavior change to the single-record _tmf_gz64_encode above.
# The per-record transform is the IDENTICAL gzip(mtime=0)+base64 — there is ONE
# codec, looped internally in ONE python3 over all N records (no per-entry
# subprocess storm; ci-check-runtime-compounding). The C-4.6 deep guard calls
# THIS function so its byte leg shares the production codec (OQ-4 holds: no
# second copy can drift).
#
# FRAMING (the _TMF_BATCH length-prefixed protocol — arbitrary bytes safe,
# incl. NUL / newline, on both input and output):
#   stdin : a decimal record-count line "N\n"; then per record a decimal
#           byte-length line "L\n" followed by exactly L payload bytes.
#   stdout: the same shape — "N\n"; then per record "L\n" + L payload bytes,
#           where each payload is the base64(gzip(mtime=0, record)) ASCII text.
# The ordering of output records matches input order 1:1.
_tmf_gz64_encode_batch() {
    python3 -c '
import sys, gzip, io, base64
def read_frames(stream):
    n_line = stream.readline()
    if not n_line:
        return []
    n = int(n_line.decode("ascii").strip())
    out = []
    for _ in range(n):
        l = int(stream.readline().decode("ascii").strip())
        out.append(stream.read(l))
    return out
def encode_one(raw):
    buf = io.BytesIO()
    with gzip.GzipFile(fileobj=buf, mode="wb", mtime=0) as gz:
        gz.write(raw)
    return base64.b64encode(buf.getvalue())
recs = read_frames(sys.stdin.buffer)
w = sys.stdout.buffer
w.write(("%d\n" % len(recs)).encode("ascii"))
for raw in recs:
    payload = encode_one(raw)
    w.write(("%d\n" % len(payload)).encode("ascii"))
    w.write(payload)
'
}

# BD-204 §3.3d: neutralize the autolink/mention triggers in a VISIBLE H2
# field VALUE (stdin → stdout). Form-AGNOSTIC inline-code-span variant: if
# the value contains ANY trigger (`#NNN`, a bare `@token` outside code, a
# bare 7-40-hex commit-SHA outside code, or a bare `http(s)://` URL), wrap
# the WHOLE value in a backtick fence (n+1 backticks where the value already
# contains a run of n backticks) so GitHub renders no autolink form. A
# value with no trigger passes through byte-unchanged (no-op). The blob is
# never routed through this — only the advisory projection.
_tmf_neutralize_autolinks() {
    python3 -c '
import sys, re
val = sys.stdin.read()
# Strip the single trailing newline printf adds back later; operate on the
# value text only.
trigger = False
if re.search(r"#\d+", val):
    trigger = True
# bare @token (letter/digit/underscore start) — mention autolink
if re.search(r"(^|[^`\w])@[A-Za-z0-9][A-Za-z0-9_-]*", val):
    trigger = True
# bare commit-SHA hex 7..40 as a standalone token
if re.search(r"(^|[^`\w])[0-9a-fA-F]{7,40}([^`\w]|$)", val):
    trigger = True
# bare URL
if re.search(r"https?://", val):
    trigger = True
if not trigger:
    sys.stdout.write(val)
    sys.exit(0)
# Choose a fence longer than the longest backtick run already present.
runs = re.findall(r"`+", val)
longest = max((len(r) for r in runs), default=0)
fence = "`" * (longest + 1)
# A space pad keeps the span well-formed when the value starts/ends with a
# backtick (CommonMark inline-code trimming rule); harmless otherwise only
# when padding is needed.
if val.startswith("`") or val.endswith("`"):
    sys.stdout.write(fence + " " + val + " " + fence)
else:
    sys.stdout.write(fence + val + fence)
'
}

# BD-204 §3.LF.3a — BATCH MODE for the autolink neutralizer (Option B
# single-source; design §4.6 (S) item 2). ADDITIVE: a NEW length-framed
# multi-record input shape; the single-record _tmf_neutralize_autolinks above
# is byte-unchanged. The per-record transform is the IDENTICAL trigger-detect +
# fence-wrap logic, looped internally in ONE python3 over all N records. The
# C-4.6 SIZE leg projects the H2 field values through THIS function so the
# guard's projection is the production neutralizer, not a reproduction.
#
# FRAMING: the _TMF_BATCH length-prefixed protocol (see _tmf_gz64_encode_batch).
# Each record is a field-value string (decoded as UTF-8 text); the output
# payload is the neutralized text (UTF-8 bytes).
_tmf_neutralize_autolinks_batch() {
    python3 -c '
import sys, re
def read_frames(stream):
    n_line = stream.readline()
    if not n_line:
        return []
    n = int(n_line.decode("ascii").strip())
    out = []
    for _ in range(n):
        l = int(stream.readline().decode("ascii").strip())
        out.append(stream.read(l))
    return out
def neutralize(val):
    trigger = False
    if re.search(r"#\d+", val):
        trigger = True
    if re.search(r"(^|[^`\w])@[A-Za-z0-9][A-Za-z0-9_-]*", val):
        trigger = True
    if re.search(r"(^|[^`\w])[0-9a-fA-F]{7,40}([^`\w]|$)", val):
        trigger = True
    if re.search(r"https?://", val):
        trigger = True
    if not trigger:
        return val
    runs = re.findall(r"`+", val)
    longest = max((len(r) for r in runs), default=0)
    fence = "`" * (longest + 1)
    if val.startswith("`") or val.endswith("`"):
        return fence + " " + val + " " + fence
    return fence + val + fence
recs = read_frames(sys.stdin.buffer)
w = sys.stdout.buffer
w.write(("%d\n" % len(recs)).encode("ascii"))
for raw in recs:
    out = neutralize(raw.decode("utf-8")).encode("utf-8")
    w.write(("%d\n" % len(out)).encode("ascii"))
    w.write(out)
'
}

# BD-204 §3.3c: read a scalar capability value from the ACTIVE provider.
# $1 = jq path expression (e.g. .body_limit). Echoes the value or empty.
_tmf_provider_capability() {
    local jq_path="$1"
    local caps
    caps=$(provider_capabilities 2>/dev/null) || return 1
    printf '%s' "$caps" | jq -r "$jq_path // empty" 2>/dev/null
}

# BD-204 §3.3d: pacing gate. Call IMMEDIATELY BEFORE each provider_create in
# the forward bulk-create loops. Sleeps the active provider's declared
# min-write interval before the SECOND and every later create (the first
# create is not preceded by a gap). Reads the interval from the active
# provider's rate_limits.min_write_interval_s (or TMF_PACING_INTERVAL_OVERRIDE
# offline); a zero/absent interval is a no-op (non-rate-limited backends).
# The retry-after backoff on a 403/429 is handled at the create call site
# (the provider already classifies rate-limit-secondary; the loop BACKS OFF
# rather than tight-retrying — see _tmf_create_backoff).
_tmf_pace_before_create() {
    if [[ "${_TMF_CREATES_DONE:-0}" -eq 0 ]]; then
        return 0
    fi
    local interval="${TMF_PACING_INTERVAL_OVERRIDE:-}"
    if [[ -z "$interval" ]]; then
        interval=$(_tmf_provider_capability '.rate_limits.min_write_interval_s')
    fi
    [[ -n "$interval" && "$interval" =~ ^[0-9]+$ && "$interval" -gt 0 ]] || return 0
    "${TMF_PACING_SLEEP_CMD:-sleep}" "$interval" 2>/dev/null || true
}

# BD-204 §3.3d: on a create failure, back off (never tight-retry) when the
# provider classified the error as rate-limit-secondary. Honors a numeric
# retry-after hint when present in the captured stderr; otherwise falls back
# to the provider's min-write interval. Returns 0 if a backoff was applied
# (caller MAY retry), 1 if the error is not a pacing class (caller aborts).
# $1 = captured stderr text from the failed provider_create.
_tmf_create_backoff() {
    local err="$1"
    case "$err" in
        *"rate-limit-secondary"*|*"secondary rate limit"*|*"abuse"*) ;;
        *) return 1 ;;
    esac
    local wait_s
    wait_s=$(printf '%s' "$err" | sed -nE 's/.*[Rr]etry-?[Aa]fter:?[[:space:]]*([0-9]+).*/\1/p' | head -1)
    if [[ -z "$wait_s" || ! "$wait_s" =~ ^[0-9]+$ ]]; then
        wait_s="${TMF_PACING_INTERVAL_OVERRIDE:-}"
        [[ -z "$wait_s" ]] && wait_s=$(_tmf_provider_capability '.rate_limits.min_write_interval_s')
    fi
    [[ -n "$wait_s" && "$wait_s" =~ ^[0-9]+$ && "$wait_s" -gt 0 ]] || wait_s=1
    "${TMF_PACING_SLEEP_CMD:-sleep}" "$wait_s" 2>/dev/null || true
    return 0
}

tmf_compose_issue_body() {
    local pack_id="$1"
    local description="$2"
    local context="${3:-}"
    local resolution="${4:-}"
    local file_symbol="${5:-}"
    local raw_body="${6:-}"
    local template_version
    case "$pack_id" in
        BD-*) template_version="bd-v11.0" ;;
        TD-*) template_version="td-v11.0" ;;
        phase-*) template_version="phase-epic-v11.0" ;;
        *)    template_version="work-item-v11.0" ;;
    esac

    # §3.3d: neutralize the H2 PROJECTION field values (blob untouched).
    local n_description n_context n_resolution n_file_symbol
    n_description=$(printf '%s' "$description" | _tmf_neutralize_autolinks)
    n_context=$(printf     '%s' "$context"     | _tmf_neutralize_autolinks)
    n_resolution=$(printf  '%s' "$resolution"  | _tmf_neutralize_autolinks)
    n_file_symbol=$(printf '%s' "$file_symbol" | _tmf_neutralize_autolinks)

    # §3.3: the verbatim-body-blob (only when a raw_body span exists — a
    # synthesized phase epic passes none, so it gets no blob marker).
    local blob=""
    if [[ -n "$raw_body" ]]; then
        blob=$(printf '%s' "$raw_body" | _tmf_gz64_encode)
    fi

    local body
    body=$(
        printf '<!-- pack-id: %s -->\n' "$pack_id"
        printf '<!-- template_version: %s -->\n' "$template_version"
        printf '<!-- pack-version: v11 -->\n'
        if [[ -n "$blob" ]]; then
            printf '<!-- pack-entry-body-gz64: %s -->\n' "$blob"
        fi
        printf '\n## Description\n\n%s\n' "$n_description"
        if [[ -n "$file_symbol" ]]; then
            printf '\n## File / Symbol\n\n%s\n' "$n_file_symbol"
        fi
        if [[ -n "$context" ]]; then
            printf '\n## Context\n\n%s\n' "$n_context"
        fi
        if [[ -n "$resolution" ]]; then
            printf '\n## Resolution\n\n%s\n' "$n_resolution"
        fi
    )

    # §3.3c SIZE BUDGET — enforced on the STORED bytes of the ACTUAL composed
    # body against the ACTIVE provider's declared limit (NO hardcoded 65536).
    # A rich_text_normalizing backend MISFITS the raw_text gz64 carrier →
    # fail loud. Over budget → fail loud with id + byte count, never truncate.
    local storage_format body_limit
    storage_format=$(_tmf_provider_capability '.body.storage_format')
    if [[ "$storage_format" == "rich_text_normalizing" ]]; then
        tracker_error_emit "validation" \
"provider declares rich_text_normalizing storage; the pack-entry-body-gz64 body-blob carrier requires raw_text — unsupported backend for v11.x (entry $pack_id)"
        return 1
    fi
    body_limit=$(_tmf_provider_capability '.body.limit')
    if [[ -n "$body_limit" && "$body_limit" =~ ^[0-9]+$ ]]; then
        local body_bytes budget
        body_bytes=$(printf '%s' "$body" | wc -c | tr -d ' ')
        budget=$(( body_limit - TMF_SIZE_SAFETY_MARGIN ))
        if [[ "$body_bytes" -gt "$budget" ]]; then
            tracker_error_emit "validation" \
"size-budget: entry $pack_id projected body $body_bytes bytes exceeds provider body limit $body_limit (margin $TMF_SIZE_SAFETY_MARGIN); forward aborted — split the entry or raise the limit; the migrator NEVER truncates"
            return 1
        fi
    fi

    printf '%s\n' "$body"
}

# BD-204 §3.LF.3a — BATCH MODE for the Issue-body composer (Option B
# single-source; design §4.6 (S) item 2 — "the architect recommends the
# batch-composer to keep ZERO mirrored logic"). ADDITIVE: a NEW length-framed
# multi-record input shape; the single-record tmf_compose_issue_body above is
# byte-unchanged. The per-record assembly is the IDENTICAL logic — same
# template_version selection, same _tmf_neutralize_autolinks projection (with
# the same command-substitution trailing-newline strip), same _tmf_gz64_encode
# blob, same printf layout, same whole-body trailing-newline collapse + single
# trailing "\n" — looped internally in ONE python3 over all N records. The
# C-4.6 SIZE leg calls THIS to measure the REAL composed body length, not a
# reproduction.
#
# Difference from the single-record path (BY DESIGN, not a regression): the
# batch composer does NOT apply the §3.3c provider size-budget / storage-format
# FAIL-LOUD gate. That gate is a production per-create concern; the guard
# measures the composed length itself against provider_body_limit - margin
# (§3.LF.5). For every input that the single-record path does NOT abort, the
# batch output is BYTE-IDENTICAL (asserted by the batch-equivalence test).
#
# FRAMING (the _TMF_BATCH length-prefixed protocol; arbitrary bytes safe):
#   stdin : "N\n"; then per record SIX length-framed fields in order —
#           pack_id, description, context, resolution, file_symbol, raw_body
#           (each: a decimal byte-length line "L\n" + L payload bytes).
#   stdout: "N\n"; then per record ONE length-framed composed-body payload.
tmf_compose_issue_body_batch() {
    python3 -c '
import sys, re, gzip, io, base64
def read_field(stream):
    l = int(stream.readline().decode("ascii").strip())
    return stream.read(l)
def neutralize(val):
    # IDENTICAL logic to _tmf_neutralize_autolinks.
    trigger = False
    if re.search(r"#\d+", val):
        trigger = True
    if re.search(r"(^|[^`\w])@[A-Za-z0-9][A-Za-z0-9_-]*", val):
        trigger = True
    if re.search(r"(^|[^`\w])[0-9a-fA-F]{7,40}([^`\w]|$)", val):
        trigger = True
    if re.search(r"https?://", val):
        trigger = True
    if not trigger:
        out = val
    else:
        runs = re.findall(r"`+", val)
        longest = max((len(r) for r in runs), default=0)
        fence = "`" * (longest + 1)
        if val.startswith("`") or val.endswith("`"):
            out = fence + " " + val + " " + fence
        else:
            out = fence + val + fence
    # The single-record callers capture via $(...), which strips trailing
    # newlines — mirror that here.
    return out.rstrip("\n")
def gz64(raw_bytes):
    buf = io.BytesIO()
    with gzip.GzipFile(fileobj=buf, mode="wb", mtime=0) as gz:
        gz.write(raw_bytes)
    return base64.b64encode(buf.getvalue()).decode("ascii")
def compose(pack_id, description, context, resolution, file_symbol, raw_body):
    if pack_id.startswith("BD-"):
        template_version = "bd-v11.0"
    elif pack_id.startswith("TD-"):
        template_version = "td-v11.0"
    elif pack_id.startswith("phase-"):
        template_version = "phase-epic-v11.0"
    else:
        template_version = "work-item-v11.0"
    n_description = neutralize(description)
    n_context = neutralize(context)
    n_resolution = neutralize(resolution)
    n_file_symbol = neutralize(file_symbol)
    blob = gz64(raw_body.encode("utf-8")) if raw_body != "" else ""
    parts = []
    parts.append("<!-- pack-id: %s -->\n" % pack_id)
    parts.append("<!-- template_version: %s -->\n" % template_version)
    parts.append("<!-- pack-version: v11 -->\n")
    if blob != "":
        parts.append("<!-- pack-entry-body-gz64: %s -->\n" % blob)
    parts.append("\n## Description\n\n%s\n" % n_description)
    if file_symbol != "":
        parts.append("\n## File / Symbol\n\n%s\n" % n_file_symbol)
    if context != "":
        parts.append("\n## Context\n\n%s\n" % n_context)
    if resolution != "":
        parts.append("\n## Resolution\n\n%s\n" % n_resolution)
    body = "".join(parts)
    # body=$(...) strips trailing newlines; printf %s\\n adds one back.
    return body.rstrip("\n") + "\n"
sin = sys.stdin.buffer
n_line = sin.readline()
n = int(n_line.decode("ascii").strip()) if n_line else 0
w = sys.stdout.buffer
w.write(("%d\n" % n).encode("ascii"))
for _ in range(n):
    fields = [read_field(sin).decode("utf-8") for _ in range(6)]
    out = compose(*fields).encode("utf-8")
    w.write(("%d\n" % len(out)).encode("ascii"))
    w.write(out)
'
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
        # BD-204 C-6 / POQ-1 (C5 review F-2): the pack monolith
        # `pack-ops/BACKLOG.md` is DELETED (BD-203 no-mirror SSOT). On
        # the PACK surface there is NO forward mirror to rebuild — the
        # per-entry tree under `/backlog/` IS the SSOT (flat-file mode)
        # and is regenerated FROM the tracker by the reverse/regen path
        # in tracker mode, NOT by a forward `--mirror-only`
        # short-circuit. Fail loud rather than reading/regenerating a
        # deleted monolith (fail-loud-delete-old-source). The client
        # `else` branch is UNTOUCHED (BD-207 owns the client tree
        # repoint): clients still ship a `BACKLOG.md` monolith mirror
        # that `mirror-rebuild` legitimately refreshes.
        if [[ "$surface" == "pack" ]]; then
            tracker_error_emit "validation" \
                "forward --mirror-only: mirror-rebuild is not applicable on the no-mirror pack surface — the /backlog per-entry tree is the SSOT (regenerated by the reverse/regen path in tracker mode, NOT a forward mirror-rebuild). BD-203 deleted pack-ops/BACKLOG.md."
            return 1
        fi
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
    # BD-204 C-5 (C2a): the pack-surface read-side enumerates the per-entry
    # TREE under `/backlog/` (the no-monolith SSOT) — there is NO
    # `pack-ops/BACKLOG.md` to read. The client `else` branch keeps reading
    # the monolith (BD-207 owns the client tree repoint).
    local backlog_path plan_path
    if [[ "$surface" == "pack" ]]; then
        backlog_path="$repo_root/backlog"
    else
        backlog_path="$repo_root/BACKLOG.md"
    fi
    plan_path="$repo_root/IMPLEMENTATION-PLAN.md"
    [[ ! -f "$plan_path" ]] && plan_path="$repo_root/maintenance-docs/IMPLEMENTATION-PLAN.md"

    local entries phases
    if [[ "$surface" == "pack" ]]; then
        # BD-204 C-5 (C2a): parse the per-entry tree into the same
        # entries-JSON shape the monolith parse produces.
        entries=$(tmf_parse_backlog_tree "pack-backlog" "$backlog_path") || return 1
    else
        entries=$(tmf_parse_backlog "$backlog_path") || return 1
    fi
    if [[ -f "$plan_path" ]]; then
        phases=$(tmf_parse_implementation_plan "$plan_path") || phases='[]'
    else
        phases='[]'
    fi

    local n_entries n_phases
    n_entries=$(printf '%s' "$entries" | jq 'length')
    n_phases=$(printf '%s'  "$phases"  | jq 'length')
    echo "forward: parsed $n_entries BACKLOG entries, $n_phases phase(s)"

    # BD-204 C-8 defect 2: parse-time Blockers cycle pre-pass. Runs
    # BEFORE the dry-run return and BEFORE any provider call, so (a) a
    # data cycle fails the run loud — naming both IDs and the full
    # cycle path — with ZERO tracker mutations, and (b) `--dry-run` is
    # a zero-cost tree-level check that catches cyclic Blockers data
    # before any live run. See tmf_blockers_cycle_precheck for the
    # live BD-094/BD-095 incident rationale.
    tmf_blockers_cycle_precheck "$entries" || return 1

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

    # BD-204 §3.3d: reset the per-run pacing counter so the FIRST create of
    # this run is un-paced and each later create sleeps the min-write gap.
    _TMF_CREATES_DONE=0

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
                local description context resolution file_symbol raw_body
                title="$pack_id: $(printf '%s' "$entry" | jq -r '.title')"
                description=$(printf '%s' "$entry" | jq -r '.description // ""')
                context=$(printf '%s'     "$entry" | jq -r '.context // ""')
                resolution=$(printf '%s'  "$entry" | jq -r '.resolution // ""')
                file_symbol=$(printf '%s' "$entry" | jq -r '.file_symbol // ""')
                # BD-204 §3.3: the verbatim captured span (raw_body) is the
                # round-trip TRUTH the gz64 blob carries. Capture it with a
                # trailing-newline guard — `$(...)` strips trailing newlines,
                # but raw_body ends with exactly one `\n` (the per-entry file's
                # final newline), so append a sentinel before capture and strip
                # it after, preserving the exact bytes the blob must encode.
                raw_body=$(printf '%s' "$entry" | jq -j '.raw_body // ""'; printf X)
                raw_body="${raw_body%X}"
                # BD-204 §3.3c: composer FAILs loud on a size-budget overflow
                # or a rich_text_normalizing backend; abort the run (never
                # create a partial Issue), mirroring the create-failure path.
                if ! body=$(tmf_compose_issue_body "$pack_id" "$description" "$context" "$resolution" "$file_symbol" "$raw_body"); then
                    creation_ok=0
                    rm -f "$partial_failures"
                    return 1
                fi
                labels_json=$(_tmf_labels_for_entry "$entry")

                local payload
                payload=$(jq -n \
                    --arg t "$title" \
                    --arg b "$body" \
                    --argjson l "$labels_json" \
                    '{title: $t, body: $b, labels: $l}')

                # BD-204 §3.3d: pace before each create after the first.
                _tmf_pace_before_create
                local create_err
                create_err=$(mktemp -t tmf-create-err.XXXXXX)
                if ! result=$(provider_create "$payload" 2>"$create_err"); then
                    # BD-204 §3.3d: on a secondary-rate-limit / abuse class
                    # failure, BACK OFF (honor retry-after) and retry ONCE —
                    # never tight-retry. Any other failure aborts as before.
                    if _tmf_create_backoff "$(cat "$create_err")"; then
                        result=$(provider_create "$payload" 2>"$create_err") || {
                            cat "$create_err" >&2
                            rm -f "$create_err"
                            creation_ok=0
                            rm -f "$partial_failures"
                            return 1
                        }
                    else
                        cat "$create_err" >&2
                        rm -f "$create_err"
                        # BD-131: mark creation surface incomplete so any
                        # future refactor that elects to continue past a
                        # create failure (instead of early-return) routes
                        # through step 11 with the right semantics.
                        creation_ok=0
                        rm -f "$partial_failures"
                        return 1
                    fi
                fi
                rm -f "$create_err"
                _TMF_CREATES_DONE=$((_TMF_CREATES_DONE + 1))
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
        # BD-204 §3.3d: pace before each create after the first (phase epics
        # are part of the same bulk-create burst as the entry creates).
        _tmf_pace_before_create
        if ! phase_result=$(provider_create "$phase_payload"); then
            # BD-131: see paired creation_ok comment above.
            creation_ok=0
            # BD-131 retro F3: mirror the entry-create cleanup (line
            # 827) so the partial_failures tempfile is not leaked when
            # phase creation fails. Pre-existing asymmetry; cleaned up
            # here so both early-return paths look identical.
            rm -f "$partial_failures"
            return 1
        fi
        _TMF_CREATES_DONE=$((_TMF_CREATES_DONE + 1))
        phase_gh_id=$(printf '%s' "$phase_result" | jq -r '.id')
        phase_url=$(printf '%s'   "$phase_result" | jq -r '.url // ""')
        mapping=$(tmf_mapping_set "$mapping" "$phase_id" "$phase_gh_id" "$phase_url")
        phase_created=$((phase_created + 1))
        pidx=$((pidx + 1))
    done

    # Step 6+7: per-entry parent + blocked-by links.
    #
    # BD-108: Blockers grammar admits `phase-N.M` form (V3.3 §5.3).
    # Distinct routing per token shape — preserved source order:
    #   - `phase-N`     → sub-issue parent (V1 §6.2 step 6 unchanged)
    #   - `phase-N.M`   → blocked-by link via tracker_links (V3.3 §5.1
    #                     pair type 2: TD ↔ phase task)
    #   - `BD-NNN|TD-NNN` → blocked-by link (V1 §6.2 step 7 unchanged)
    #
    # The case statement matches MOST-SPECIFIC FIRST so the v11.0
    # `phase-N.M` shape is recognised before the v10 `phase-N*` glob
    # would falsely catch it. The v10 ordering convention (Blockers
    # field order = forward processing order = reverse emission order)
    # is preserved per call-out 5 in the BD-108 IMPLEMENTATION-REPORT.
    #
    # BATCH-17 F1 (cross-BD review): both blocked-by arms now route
    # through `tracker_links_create_blocked_by` (BD-108) instead of
    # bare `provider_link`. The orchestrator runs cycle-check + persists
    # the new edge to the cycle-graph store so link-creation cycle
    # detection has a non-empty baseline after initial migration. The
    # store lives at `<repo>/.pack-tracker/links-graph.json` per
    # tracker-links.sh convention. The id-map JSON is the in-memory
    # `mapping` we have been maintaining; we re-serialize on each loop
    # iteration so the orchestrator sees the freshest mapping (entries
    # may be added by step 5 phase-creation between iterations).
    local cycle_store_path
    cycle_store_path="$repo_root/$TMF_PACK_TRACKER_DIR/links-graph.json"
    # BD-204 C-8 defect 2: capture the link orchestrator's stderr per
    # edge instead of swallowing it (`2>&1` → /dev/null pre-fix). The
    # BD-108 pre-call cycle refusal and any provider error both carry a
    # typed `MESSAGE:` line; folding it into the partial-failure entry
    # makes the two failure classes distinguishable and actionable
    # (the live C-8 flip retried the same swallowed BD-095 -> BD-094
    # cycle refusal 3x because the bare step-7 line named no cause).
    local link_err
    link_err=$(mktemp -t tmf-linkerr.XXXXXX)
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

        local blockers
        blockers=$(printf '%s' "$entry" | jq -c '.blockers // []')
        local b_count b_idx=0
        b_count=$(printf '%s' "$blockers" | jq 'length')
        while [[ $b_idx -lt $b_count ]]; do
            local raw
            raw=$(printf '%s' "$blockers" | jq -r ".[$b_idx]")
            case "$raw" in
                # Most-specific first: phase-N.M (v11.0 additive form).
                # BD-108 review F9: the glob is tightened so the N and
                # M positions accept only digits — `phase-[0-9][0-9]*`
                # rather than `phase-[0-9]*` — defense-in-depth against
                # malformed Blockers entries (e.g. `phase-3foo.4`,
                # `phase-3.2.5`) that would survive the parser. This
                # mirrors the canonical regex used by
                # `_tlk_is_valid_pack_id` in scripts/lib/tracker-links.sh.
                # Bash-3.2 compatible (no `+(...)` extglob).
                phase-[0-9][0-9]*.[0-9][0-9]*)
                    local pt_gh_id
                    pt_gh_id=$(tmf_mapping_get "$mapping" "$raw" || echo "")
                    if [[ -n "$pt_gh_id" ]]; then
                        # BATCH-17 F1: route through link orchestrator
                        # (BD-108). The orchestrator handles cycle-check
                        # + provider_link + cycle-graph store persist.
                        # Cycle check is a no-op on empty initial store
                        # but builds the baseline for subsequent links.
                        if tracker_links_create_blocked_by \
                            "$pack_id" "$raw" "$mapping" "$cycle_store_path" "" \
                            >/dev/null 2>"$link_err"; then
                            linked_blocked=$((linked_blocked + 1))
                        else
                            # BD-204 C-8 defect 2: surface the typed
                            # MESSAGE (cycle refusal vs provider error)
                            # instead of swallowing it.
                            local link_reason
                            link_reason=$(sed -n 's/^MESSAGE: //p' "$link_err" | head -n 1)
                            printf 'step-7 link blocked-by (phase-task): %s -> %s%s\n' \
                                "$pack_id" "$raw" "${link_reason:+ — $link_reason}" \
                                >> "$partial_failures"
                        fi
                    fi
                    ;;
                # phase-N (v10 sub-issue parent).
                phase-[0-9]*)
                    local parent_gh_id
                    parent_gh_id=$(tmf_mapping_get "$mapping" "$raw" || echo "")
                    if [[ -n "$parent_gh_id" ]]; then
                        if provider_sub_issue_create "$parent_gh_id" \
                            "{\"existing_id\": \"$gh_id\"}" >/dev/null 2>"$link_err"; then
                            linked_parent=$((linked_parent + 1))
                        else
                            # BD-204 C-8 defect 2 (review-2 NIT-2):
                            # surface the typed MESSAGE instead of
                            # swallowing it — mirrors the three
                            # blocked-by arms.
                            local parent_link_reason
                            parent_link_reason=$(sed -n 's/^MESSAGE: //p' "$link_err" | head -n 1)
                            printf 'step-6 sub_issue_create: %s -> %s%s\n' \
                                "$pack_id" "$raw" "${parent_link_reason:+ — $parent_link_reason}" \
                                >> "$partial_failures"
                        fi
                    fi
                    ;;
                BD-*|TD-*)
                    local other_gh_id
                    other_gh_id=$(tmf_mapping_get "$mapping" "$raw" || echo "")
                    if [[ -n "$other_gh_id" ]]; then
                        # BATCH-17 F1: route through link orchestrator
                        # (BD-108). Mirrors the phase-N.M arm above —
                        # the BD/TD blocked-by arm now also populates
                        # the cycle-graph store on initial migration.
                        if tracker_links_create_blocked_by \
                            "$pack_id" "$raw" "$mapping" "$cycle_store_path" "" \
                            >/dev/null 2>"$link_err"; then
                            linked_blocked=$((linked_blocked + 1))
                        else
                            # BD-204 C-8 defect 2: surface the typed
                            # MESSAGE (cycle refusal vs provider error)
                            # instead of swallowing it. The live flip
                            # retried `BD-095 -> BD-094` 3x because
                            # this line carried no cause.
                            local link_reason
                            link_reason=$(sed -n 's/^MESSAGE: //p' "$link_err" | head -n 1)
                            printf 'step-7 link blocked-by: %s -> %s%s\n' \
                                "$pack_id" "$raw" "${link_reason:+ — $link_reason}" \
                                >> "$partial_failures"
                        fi
                    fi
                    ;;
            esac
            b_idx=$((b_idx + 1))
        done
        lidx=$((lidx + 1))
    done

    # Step 7b (BD-108; V3.3 §5.7): second pass also processes phase-task
    # `Dependencies` bullets from IMPLEMENTATION-PLAN.md. The phase task
    # parser (BD-106 tracker-phase-task.sh) already extracts each task's
    # dependency_edges with `kind/target/annotation`; this loop replays
    # them as provider_link calls so the tracker reflects the same
    # blocked-by edges as the flat-file source.
    #
    # Sourced lazily so callers that don't need the v11.0 phase-task
    # surface (e.g. v10 fixtures with no IMPLEMENTATION-PLAN.md) don't
    # pay the load cost.
    if [[ -f "$plan_path" ]]; then
        # Lazy source — same idempotency guard pattern as the
        # tracker-config / tracker-errors siblings.
        if ! declare -f tracker_phase_task_parse >/dev/null 2>&1; then
            local _tmf_lib_dir
            _tmf_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            # shellcheck disable=SC1091
            source "$_tmf_lib_dir/tracker-phase-task.sh"
        fi
        local pt_doc pt_err
        # BD-108 review F10: capture parser stderr so a malformed
        # IMPLEMENTATION-PLAN (V3.3 §5.3 grammar violation) surfaces
        # via the partial_failures log rather than being silently
        # dropped. Without this capture, users would see "0 cross-
        # phase deps linked" with no diagnostic — violating V3.3 §5.6
        # ("no silent retry / no silent fallback") and V1 §9.6
        # partial-write contract.
        pt_err=$(mktemp -t tmf-pt-err.XXXXXX)
        if pt_doc=$(tracker_phase_task_parse "$plan_path" 2>"$pt_err"); then
            rm -f "$pt_err"
            local pt_pairs
            # Emit one "<src>\t<tgt>" line per phase-task dependency
            # for downstream loop. Awk-friendly; bash-3.2-portable.
            pt_pairs=$(printf '%s' "$pt_doc" | jq -r '
                .phases[]?.tasks[]? as $task |
                $task.dependencies[]? |
                [$task.pack_id, .target] | @tsv')
            while IFS=$'\t' read -r pt_src pt_tgt; do
                [[ -z "$pt_src" || -z "$pt_tgt" ]] && continue
                local pt_src_gh pt_tgt_gh
                pt_src_gh=$(tmf_mapping_get "$mapping" "$pt_src" || echo "")
                pt_tgt_gh=$(tmf_mapping_get "$mapping" "$pt_tgt" || echo "")
                if [[ -z "$pt_src_gh" ]]; then
                    # Source phase task not in id-map yet — phase-task
                    # creation is a future BD scope item. Surface as
                    # partial-failure so the user sees coverage gaps.
                    printf 'step-7b phase-task source not in id-map: %s\n' \
                        "$pt_src" >> "$partial_failures"
                    continue
                fi
                if [[ -z "$pt_tgt_gh" ]]; then
                    printf 'step-7b phase-task target not in id-map: %s -> %s\n' \
                        "$pt_src" "$pt_tgt" >> "$partial_failures"
                    continue
                fi
                # BATCH-17 F1: route through link orchestrator (BD-108)
                # so the cycle-graph store is populated for phase-task
                # ↔ phase-task edges that originate from the
                # IMPLEMENTATION-PLAN.md `Dependencies` bullets. This
                # mirrors the F1 fix to step 7's blocked-by arms.
                if tracker_links_create_blocked_by \
                    "$pt_src" "$pt_tgt" "$mapping" "$cycle_store_path" "" \
                    >/dev/null 2>"$link_err"; then
                    linked_blocked=$((linked_blocked + 1))
                else
                    # BD-204 C-8 defect 2: surface the typed MESSAGE
                    # (cycle refusal vs provider error) instead of
                    # swallowing it — mirrors the step-7 arms.
                    local pt_link_reason
                    pt_link_reason=$(sed -n 's/^MESSAGE: //p' "$link_err" | head -n 1)
                    printf 'step-7b link blocked-by (phase-task dep): %s -> %s%s\n' \
                        "$pt_src" "$pt_tgt" "${pt_link_reason:+ — $pt_link_reason}" \
                        >> "$partial_failures"
                fi
            done <<<"$pt_pairs"
        else
            # BD-108 review F10: parser failed — surface the typed
            # error block to the partial_failures log so the user
            # sees the diagnostic. Without this branch the migrator
            # would silently skip the entire phase-task dependency
            # replay. The leading marker line lets users grep the
            # log for "step-7b phase-task parser failed" to locate
            # malformed IMPLEMENTATION-PLAN inputs.
            printf 'step-7b phase-task parser failed (plan_path=%s):\n' \
                "$plan_path" >> "$partial_failures"
            cat "$pt_err" >> "$partial_failures" 2>/dev/null || true
            rm -f "$pt_err"
        fi
    fi

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
    # BD-204 C-5 (C2b RETIRE pack): the pack surface has NO monolith under
    # the no-monolith SSOT model — regenerating one would VIOLATE the
    # fail-loud / no-mirror standard and trip validate-pack Check 32′. The
    # tree IS the mirror and is regenerated by the reverse/regen path
    # (C-4), not by a forward mirror-write. So SKIP Step-10 on the pack
    # branch entirely; the client `else` branch keeps Step-10 (BD-207).
    local backend_slug
    backend_slug=$(tracker_repo_slug "$cfg_path" 2>/dev/null || echo "unknown")
    if [[ "$surface" != "pack" ]]; then
        if ! _tmf_regen_mirror "$backlog_path" "$backend_slug" 2>/dev/null; then
            printf 'step-10 mirror regen: %s (re-run with --mirror-only to recover)\n' \
                "$backlog_path" >> "$partial_failures"
        fi
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
    # BD-131 retro F4: surface the writer's defensive-validation rc=1
    # at the orchestrator layer. The writer rejects out-of-schema fc
    # values ("must be 'true' or 'false'") with a stderr WARN and rc=1;
    # the orchestrator's own conditional at lines above only ever
    # passes "true" or "false", so this branch is unreachable from
    # in-tree control flow today — but a future refactor that routes a
    # different value here (or a stale-symbol shim that returns rc=1)
    # would have been silently swallowed by the un-checked call. Emit a
    # clearer follow-up WARN so the operator's eye is drawn to the
    # writer's rejection without aborting the otherwise-successful run.
    if ! _tmf_update_tracker_toml "$cfg_path" "$fc_value"; then
        echo "forward: WARN: tracker.toml writer rejected forward_complete value '$fc_value' — see writer WARN above; tracker_mode() will resolve to flat-file until init is re-run" >&2
    fi
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

    # BD-204 F-2: the link counts are "ensured present" semantics, NOT
    # "created this run" — the provider's read-before-write skip returns
    # success (with an additive already_linked marker) for a pre-existing
    # edge, so a skip-all RE-run reports the same counts as the run that
    # created the links. The orchestrator discards provider stdout, so it
    # cannot split ensured-vs-created without threading the marker through;
    # the printed "(ensured present)" qualifier makes the semantics explicit.
    cat <<EOF
forward: complete.
  entries:    $entry_count
  created:    $created
  skipped:    $skipped
  recovered:  $recovered
  closed:     $closed
  phases:     $phase_count (created: $phase_created)
  links:      parent=$linked_parent, blocked-by=$linked_blocked (ensured present)
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
        rm -f "$partial_failures" "$link_err"
        tracker_error_emit "partial-write" \
            "Forward migration completed with $n_pf step failure(s); per-step list above. Idempotent re-run will retry." \
            "${extras[@]}"
        return 1
    fi
    rm -f "$partial_failures" "$link_err"
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

    # Mirror / tree-regen freshness.
    #
    # BD-204 C-6-FIX1 (F-1 REPOINT): the pack monolith `pack-ops/BACKLOG.md`
    # is DELETED (BD-203 no-mirror SSOT — the `/backlog/` per-entry tree
    # + generated `_toc.md` index IS the pack SSOT, there is no
    # regenerated monolithic mirror). On the PACK surface the
    # "mirror freshness" line maps to the tree's regen-state via the
    # `_toc.md` mtime — the no-mirror analogue of the old monolith-header
    # mtime (DP-4 regen cadence), mirroring the C7b doctor repoint. The
    # PROJECT (`else`) surface still reads the legacy `BACKLOG.md`
    # monolith mirror header (BD-207 owns the client tree repoint).
    local mirror_age
    if [[ "$surface" == "pack" ]]; then
        local toc_path
        toc_path="$repo_root/backlog/_toc.md"
        if [[ -f "$toc_path" ]]; then
            mirror_age=$(date -r "$toc_path" -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo "unknown")
        else
            mirror_age="(no /backlog/_toc.md)"
        fi
    else
        local mirror_path
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
        # BD-204 DP-3 (C-5 carry-forward #1): Deferred is an OPEN state
        # disambiguated by the status:deferred label — the FORWARD
        # complement to the C-1 reverse-decode `status:deferred → Deferred`
        # branch. Without this case, a Deferred entry fell through to the
        # `*) status:open` default and reverse-decoded to Open, breaking the
        # lossless round-trip on all 11 live Deferred entries.
        Deferred)    status_label="status:deferred" ;;
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
