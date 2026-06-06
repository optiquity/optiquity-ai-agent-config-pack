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
#   5. Emit IMPLEMENTATION-PLAN.md from phase-epic titles
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
# shellcheck disable=SC1091
# BD-133 / D-6: header preservation across init→disable round-trips.
# The reverse emitter writes BACKLOG.md from scratch; without this
# module, every reverse destroys the user-authored preamble (title,
# intro paragraph, "How to use this file" section, etc.).
if ! declare -f tracker_header_snapshot_capture >/dev/null 2>&1; then
    _tmr_self="${BASH_SOURCE[0]}"
    _tmr_dir="$(cd "$(dirname "$_tmr_self")" && pwd)"
    source "$_tmr_dir/tracker-header-snapshot.sh"
    unset _tmr_self _tmr_dir
fi

# ─────────────────────────────────────────────────────────────────
# BD-106 helpers: phase-task id-map reads (V3.2 §4.2 / V3.3 §4.2)
# ─────────────────────────────────────────────────────────────────
#
# Phase tasks are stored at the same top level of id-map.json as
# BD-NNN / TD-NNN (`mapping["phase-N.M"] = {id, url}`). The reverse
# emitter reads them via the existing tmf_mapping_get path. The
# helpers below add:
#
#   _tmr_phase_task_order — read mapping["phase-N"].task_order so
#     reverse emits tasks in the original file order (V3.2 §4.2
#     step 5c). If unset, falls back to numeric sort of the task
#     numbers found in mapping (mapping["phase-N.M"]).
#
# Implementation note: id-map handling is additive — existing v10
# entries are untouched; v11 phase-task entries simply add new keys
# alongside. Round-trip safety holds because the reverse emitter
# reads only the keys it needs.

# _tmr_phase_task_order <mapping-json> <phase-id>
# Emit a JSON array of task numbers (e.g. ["1","2","3"]) in the
# canonical emit order. Falls back to ascending numeric order over
# all `phase-<N>.<M>` keys whose phase prefix matches.
_tmr_phase_task_order() {
    local mapping="$1"
    local phase_id="$2"
    if [[ ! "$phase_id" =~ ^phase-[0-9]+$ ]]; then
        tracker_error_emit "validation" "_tmr_phase_task_order: invalid phase id $phase_id"
        return 1
    fi
    # Mapping JSON is passed via env var (TMR_MAPPING_JSON) instead
    # of stdin because bash heredocs replace stdin with the heredoc
    # body — a stdin pipe would be silently dropped.
    TMR_MAPPING_JSON="$mapping" python3 - "$phase_id" <<'PYEOF'
import json, os, re, sys
mapping = json.loads(os.environ['TMR_MAPPING_JSON'])
phase_id = sys.argv[1]
phase_num = phase_id.split('-', 1)[1]

# 1) explicit task_order on the phase entry, if present.
phase_entry = mapping.get(phase_id, {})
if isinstance(phase_entry, dict) and isinstance(phase_entry.get('task_order'), list):
    print(json.dumps([str(x) for x in phase_entry['task_order']]))
    sys.exit(0)

# 2) fall back to ascending numeric scan of phase-<N>.<M> keys.
task_re = re.compile(r'^phase-' + re.escape(phase_num) + r'\.(\d+)$')
nums = []
for k in mapping.keys():
    m = task_re.match(k)
    if m:
        nums.append(int(m.group(1)))
nums.sort()
print(json.dumps([str(n) for n in nums]))
PYEOF
}

# ─────────────────────────────────────────────────────────────────
# BD-132 helpers: race detection + skip tracking
# ─────────────────────────────────────────────────────────────────

# Emit the age in whole seconds of the mapping file (now - mtime).
# Returns "" on stdout if the file is missing (no race possible).
#
# Implementation: defers to python3's `os.path.getmtime`, which is
# documented to return the file's mtime as a Unix timestamp on every
# platform Python supports (macOS, Linux, *BSD). This avoids the
# BSD-vs-GNU `stat` flag mismatch (`stat -f %m` is "filesystem status"
# on Linux GNU coreutils, NOT mtime — the previous BSD/GNU fallback
# silently produced bogus values on Linux). Python3 is already a
# hard dependency of the rest of this codebase (see
# tracker-migrate-forward.sh:1105 et al), so this introduces no new
# requirement. Bash 3.2 + BSD utils compatible.
_tmr_mapping_age_secs() {
    local path="$1"
    if [[ ! -f "$path" ]]; then
        echo ""
        return 0
    fi
    local secs
    if ! secs=$(python3 -c '
import os, sys, time
try:
    print(int(time.time() - os.path.getmtime(sys.argv[1])))
except Exception:
    sys.exit(2)
' "$path" 2>/dev/null); then
        # Could not read mtime; report -1 so caller treats as
        # "unknown" (race-detection is permissive, not blocking).
        echo "-1"
        return 0
    fi
    echo "$secs"
}

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
            status:deferred)    echo "Deferred" ;;
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
        status:deferred)    echo "Deferred" ;;
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

# Fetch the first-class GH issue-dependency edges (`blocked-by`) for
# a given issue number via GraphQL. BD-111 retrofit (PACK-REVIEW-BD-111
# F1, scope-extended 2026-05-15, second extension): post-BD-111 forward
# writes go to first-class `addBlockedBy` edges, so the reverse decoder
# must query those edges to round-trip Blockers. Legacy comment-body
# markers continue to be read by `_tmr_decode_blockers` itself.
#
# Returns a JSON array of integer issue numbers on stdout (the
# upstream issues that block the given issue). Empty array on error
# or no edges. Errors are swallowed (best-effort): the decoder fall
# back to comment-marker-only behavior, which is still strictly an
# improvement over the pre-BD-111 state for legacy issues.
#
# GraphQL query — repository(owner, name).issue(number).blockedByIssues
# (first: 50) { nodes { number } }. The field name `blockedByIssues`
# is the symmetric guess paired with the `addBlockedBy` mutation
# (EXTERNAL-RESEARCH §1.3 line 86) and the existing `subIssues` field
# accessor used at `tracker_provider_gh_sub_issue_list:686` (which
# pairs with the `addSubIssue` mutation). The cap of 50 matches the
# documented per-relationship ceiling (EXTERNAL-RESEARCH §1.8 line
# 188; capabilities.dependencies.per_relationship_ceiling=50). The
# exact field name is unverified offline; flagged for confirmation
# at BD-088 / BD-093 integration-test land-time same as the link /
# unlink mutation names. If GH's actual field is named `blockedBy`
# (no `Issues` suffix) or `blockingIssues`, the fix is one line in
# the query string below plus one path in the jq filter.
#
# Routes through `provider_raw "POST" "graphql" "$query"`; any backend
# error (auth, network, schema-reshape) classifies via
# `_gh_classify_error` and emits a typed error block to stderr — but
# we ignore the rc here because the reverse decoder must remain
# best-effort: a missing GraphQL response should not abort the whole
# reverse run, only degrade Blockers reconstruction for that one
# issue.
_tmr_fetch_first_class_blocked_by() {
    local issue_number="$1"
    if [[ -z "$issue_number" ]]; then
        echo "[]"
        return 0
    fi
    # Resolve owner/repo from the active gh context. tracker-config
    # may export GH_REPO; failing that, fall back to `gh repo view`.
    local owner_repo owner repo
    if [[ -n "${GH_REPO:-}" && "$GH_REPO" == */* ]]; then
        owner_repo="$GH_REPO"
    else
        owner_repo=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null) || {
            echo "[]"
            return 0
        }
    fi
    if [[ -z "$owner_repo" || "$owner_repo" != */* ]]; then
        echo "[]"
        return 0
    fi
    owner=$(printf '%s' "$owner_repo" | cut -d/ -f1)
    repo=$(printf  '%s' "$owner_repo" | cut -d/ -f2)
    # Build the query with shell-interpolated owner/repo/number. The
    # values are tracker-controlled (owner/repo from gh; number is
    # integer), so direct interpolation is safe.
    local query response
    query='query { repository(owner: "'"$owner"'", name: "'"$repo"'") { issue(number: '"$issue_number"') { blockedByIssues(first: 50) { nodes { number } } } } }'
    # provider_raw routes through _gh_run → _gh_classify_error. We
    # swallow any error and fall back to []; the reverse decoder must
    # remain best-effort per the function header rationale.
    if ! response=$(provider_raw "POST" "graphql" "$query" 2>/dev/null); then
        echo "[]"
        return 0
    fi
    if [[ -z "$response" ]]; then
        echo "[]"
        return 0
    fi
    # Extract the issue numbers. A well-formed response is:
    #   {"data": {"repository": {"issue": {"blockedByIssues": {"nodes": [{"number": N}, ...]}}}}}
    # The jq filter is defensive against missing keys (`// empty`)
    # and emits the integer numbers as a JSON array. On parse failure,
    # echo [] (the // [] guard at the end).
    printf '%s' "$response" \
        | jq -c '[.data.repository.issue.blockedByIssues.nodes[]?.number] // []' 2>/dev/null \
        || echo "[]"
}

# Extract Blockers from the issue's link relationships. The provider
# does not have a generic "list links by kind" op (V1 §2.4 link.kind
# is open-string); for v11.0 we combine three sources:
#
#   1. (NEW — BD-111 retrofit, PACK-REVIEW-BD-111 F1) First-class
#      `blockedByIssues` GraphQL edges. Pre-fetched by the caller
#      (typically `tracker_migrate_reverse_reconstruct`) via
#      `_tmr_fetch_first_class_blocked_by` and passed in as a JSON
#      array of gh-issue-numbers (arg 4). Post-BD-111 writes from
#      `provider_link blocked-by` go to this surface. Authoritative
#      when present.
#
#   2. (LEGACY — BD-060 era) Body comment markers ("Blocked by #NNN").
#      Pre-BD-111 writes left these markers in the issue body; they
#      persist after BD-111 and are still read for backward-compat.
#      Mixed-environment safe: an issue with both a first-class edge
#      AND a body marker pointing at the same upstream produces one
#      entry in the Blockers list (de-dup by pack-id).
#
#   3. Sub-issue parent (the `parent` field in the canonical Issue
#      JSON). Always prepended. Restricted to phase epics — see D-21
#      note below.
#
# BD-108 (V3.3 §5.3): The decoder admits the v11.0 additive `phase-N.M`
# form alongside v10's `phase-N` / `TD-NNN` / `BD-NNN`. Sub-issue parent
# is restricted to phase EPICS (`phase-N`) — phase tasks (`phase-N.M`)
# are not legal sub-issue parents per V3.3 §2 D-21. Body-comment-marker
# Blockers and first-class edge Blockers admit the full set per V3.3
# §5.3 line 263. Source order is preserved (sub-issue parent first if
# present, then first-class edges in GH-numeric order, then comment-
# marker order) per call-out 5 in the BD-108 IMPLEMENTATION-REPORT.
# De-duplication by pack-id: an upstream that appears in both the
# first-class edge graph and the body markers contributes one entry.
#
# Returns a JSON array of pack-ids on stdout. Non-pack-id refs (e.g.
# `#42` to a non-mapped issue) are dropped.
_tmr_decode_blockers() {
    local body="$1"
    local mapping="$2"
    local sub_issue_parent="${3:-}"
    local first_class_edges="${4:-[]}"  # JSON array of integer gh-numbers
    python3 - "$body" "$mapping" "$sub_issue_parent" "$first_class_edges" <<'PYEOF'
import json, re, sys
body, mapping_json, sub_issue_parent, first_class_json = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
mapping = json.loads(mapping_json) if mapping_json else {}
try:
    first_class_edges = json.loads(first_class_json) if first_class_json else []
except (ValueError, TypeError):
    first_class_edges = []

# Build reverse-lookup: gh-id → pack-id.
gh_to_pack = {}
for pack_id, info in mapping.items():
    if isinstance(info, dict) and info.get("id"):
        gh_to_pack[str(info["id"])] = pack_id

blockers = []

# Sub-issue parent → phase epic only. V3.3 §2 D-21: phase tasks
# (phase-N.M) are first-class L2 entities; they are NOT sub-issue
# parents. Restrict to phase-N (no `.M` component) to avoid
# misclassifying a phase-task parent as a phase-epic blocker.
if sub_issue_parent:
    pack_parent = gh_to_pack.get(str(sub_issue_parent))
    if pack_parent and re.match(r'^phase-\d+$', pack_parent):
        blockers.append(pack_parent)

# First-class blocked-by edges (BD-111 retrofit). Authoritative when
# present. Reverse-lookup yields the pack-id verbatim (phase-N,
# phase-N.M, TD-NNN, BD-NNN). Numeric source order from GH preserved.
for gh_num in first_class_edges:
    gh_id = str(gh_num)
    pack_id = gh_to_pack.get(gh_id)
    if pack_id and pack_id not in blockers:
        blockers.append(pack_id)

# Body comment markers: "Blocked by #NNN" lines (BD-060 legacy path,
# preserved for backward-compat with pre-BD-111 issues). De-dup
# against the first-class edge results by pack-id.
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

    local sub_issue_parent issue_number first_class_edges
    sub_issue_parent=$(printf '%s' "$issue" | jq -r '.parent // ""')
    issue_number=$(printf  '%s' "$issue" | jq -r '.number // ""')

    # BD-111 retrofit (PACK-REVIEW-BD-111 F1, scope-extension second
    # pass 2026-05-15): fetch first-class `blockedByIssues` GraphQL
    # edges so post-BD-111 forward writes round-trip through reverse.
    # Best-effort — empty array on any error (auth, network, schema-
    # reshape); the decoder still reads body comment markers as the
    # legacy-compat fallback.
    first_class_edges=$(_tmr_fetch_first_class_blocked_by "$issue_number")

    local blockers
    blockers=$(_tmr_decode_blockers "$body" "$mapping" "$sub_issue_parent" "$first_class_edges")

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

# Emit IMPLEMENTATION-PLAN.md skeleton from phase epic titles. Per
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

# tracker_migrate_reverse_run <repo-root> [<dry-run>] [<flip-mode-to-flat-file>] [<include-comments>] [<force>]
# Runs V1 §6.5 steps 1–9. flip_mode=1 turns this into the
# `pack tracker disable` semantic (reverse + flip mode).
#
# BD-132 race-detection (Part 2): when flip_mode=1 (the disable
# entry point), refuse to proceed if a forward run appears to be
# in flight (forward.checkpoint.json present, OR mapping file mtime
# is fresher than TMR_RACE_FRESHNESS_SECS). Override with force=1.
tracker_migrate_reverse_run() {
    local repo_root="$1"
    local dry_run="${2:-0}"
    local flip_mode="${3:-0}"
    local include_comments="${4:-0}"
    local force="${5:-0}"

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

    # BD-132 Part 2: race-detection pre-flight. Only applies when
    # flip_mode=1 (disable). Two signals:
    #   (a) forward.checkpoint.json present → forward is mid-run or
    #       crashed mid-run; reverse would race.
    #   (b) mapping file mtime is fresher than TMR_RACE_FRESHNESS_SECS
    #       seconds → forward just finished; eventual consistency on
    #       gh issue close means body/labels may be stale.
    # Either signal triggers refusal unless --force.
    if [[ "$flip_mode" == "1" && "$force" != "1" && "$dry_run" != "1" ]]; then
        local checkpoint_file
        checkpoint_file=$(_tmf_checkpoint_file "$repo_root")
        if [[ -f "$checkpoint_file" ]]; then
            tracker_error_emit "validation" \
                "disable: forward checkpoint file present at $checkpoint_file" \
                "A forward migration is in progress or crashed mid-run." \
                "Reverse now would race the forward path and silently drop entries." \
                "Wait for forward to finish, OR run \`pack tracker init --resume\` to clean up," \
                "OR pass --force to override (NOT recommended; you may lose data)."
            return 1
        fi
        local fresh_secs
        fresh_secs=$(_tmr_mapping_age_secs "$mapping_file")
        # F-5 calibration: default freshness threshold matches the
        # forward-side stabilization ceiling
        # (TMF_STABILIZE_MAX_ATTEMPTS=30 × TMF_STABILIZE_SLEEP_SECS=2
        # = 60s). Setting it lower (the previous 30s default) created
        # a window where stabilization had timed out, mapping was
        # older than 30s, but closes were still in flight — Part 2b
        # would not fire. Override via TMR_RACE_FRESHNESS_SECS env.
        local race_threshold="${TMR_RACE_FRESHNESS_SECS:-60}"
        if [[ -n "$fresh_secs" && "$fresh_secs" -ge 0 && "$fresh_secs" -lt "$race_threshold" ]]; then
            tracker_error_emit "validation" \
                "disable: mapping file modified ${fresh_secs}s ago (< ${race_threshold}s freshness threshold)" \
                "A forward migration just finished; tracker close ops may still be propagating." \
                "Eventual consistency means reverse now could read stale body/labels and" \
                "silently drop entries (BD-132 / D-5 silent-data-loss bug)." \
                "Wait at least ${race_threshold}s and re-run, OR pass --force to override" \
                "(NOT recommended unless you have independently verified \`gh issue list" \
                "--state closed\` count is stable)."
            return 1
        fi
    fi

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
    # BD-132 Part 3: skip tracking. Previously, any entry whose
    # provider_get failed OR whose body did not yield a pack_id was
    # silently `continue`-d — that is the silent-data-loss path the
    # BD-102 Phase A dog-food caught. Now we accumulate the skip ids
    # + reasons and surface them at the end (loud failure beats
    # silent loss; if any skips occurred we exit non-zero unless
    # the caller passes --force).
    local skipped_log
    skipped_log=$(mktemp -t tmr-skipped.XXXXXX)
    : > "$skipped_log"

    local n_roster i_roster=0 gh_id pack_id issue
    n_roster=$(printf '%s' "$roster" | jq 'length')
    while [[ $i_roster -lt $n_roster ]]; do
        gh_id=$(printf '%s' "$roster" | jq -r ".[$i_roster]")
        i_roster=$((i_roster + 1))
        if [[ -z "$gh_id" || "$gh_id" == "null" ]]; then
            # Roster entry with no id is a roster-build defect, not a
            # data-loss event — log and continue without escalation.
            continue
        fi
        if ! issue=$(provider_get "$gh_id" 2>/dev/null); then
            printf 'gh #%s: provider_get failed (issue may be in flight or unreadable)\n' \
                "$gh_id" >> "$skipped_log"
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
        if [[ -z "$pack_id" ]]; then
            printf 'gh #%s: pack-id not resolvable (no body marker, no mapping entry; body may be mid-update)\n' \
                "$gh_id" >> "$skipped_log"
            continue
        fi
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
            *)
                printf 'gh #%s: pack-id %s did not match BD-/TD-/phase- prefix\n' \
                    "$gh_id" "$pack_id" >> "$skipped_log"
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

    # BD-132 Part 3: surface the silent-skip path. Emit per-skip WARN
    # lines to stderr (so the user sees what was dropped, not just a
    # count), then refuse to write half-data into BACKLOG.md unless
    # --force is set. This converts the silent-data-loss bug
    # (BD-132 / D-5) into a loud failure with full diagnostic detail.
    local n_skipped=0
    if [[ -s "$skipped_log" ]]; then
        n_skipped=$(wc -l < "$skipped_log" | tr -d ' ')
        printf 'WARN: reverse: %s issue(s) skipped during reconstruction:\n' "$n_skipped" >&2
        local _line
        while IFS= read -r _line; do
            printf '  - %s\n' "$_line" >&2
        done < "$skipped_log"
    fi

    if [[ "$dry_run" == "1" ]]; then
        rm -f "$skipped_log"
        echo "reverse: --dry-run set; stopping after reconstruction"
        if [[ "$n_skipped" -gt 0 && "$force" != "1" ]]; then
            tracker_error_emit "partial-write" \
                "reverse --dry-run: $n_skipped issue(s) skipped (would lose data on a real run)" \
                "Per-skip diagnostic above; pass --force to acknowledge data loss."
            return 1
        fi
        return 0
    fi

    if [[ "$n_skipped" -gt 0 && "$force" != "1" ]]; then
        rm -f "$skipped_log"
        tracker_error_emit "partial-write" \
            "reverse: $n_skipped issue(s) failed to reconstruct (silent-data-loss guard)" \
            "Reconstructing BACKLOG.md now would drop these entries from disk." \
            "Cause is typically gh issue close eventual consistency (BD-132 / D-5):" \
            "wait 30+ seconds and re-run, OR run \`pack tracker init --no-forward\` to" \
            "refresh tracker state and try again. Pass --force only if you have" \
            "verified the missing entries are actually deleted, not in flight."
        return 1
    fi
    rm -f "$skipped_log"

    # Steps 4–7: emit flat files.
    local backend_slug
    backend_slug=$(tracker_repo_slug "$cfg_path" 2>/dev/null || echo "unknown")

    # BD-175: pack-side emits to pack-ops/; client-side emits to repo
    # root for IMPLEMENTATION-PLAN/STATUS and (legacy) BACKLOG/CHANGELOG.
    # Client side has its own canonical locations under docs/project/
    # already handled by the project-side reverse path; the legacy root
    # emit shape is preserved here for back-compat with pre-v10 client
    # flows that landed BACKLOG/CHANGELOG at root.
    local backlog_out plan_out status_out changelog_out
    if [[ "$surface" == "pack" ]]; then
        # Ensure pack-ops/ exists before emit (BD-175 directory reorg).
        mkdir -p "$repo_root/pack-ops"
        backlog_out="$repo_root/pack-ops/BACKLOG.md"
        changelog_out="$repo_root/pack-ops/CHANGELOG.md"
        plan_out="$repo_root/IMPLEMENTATION-PLAN.md"
        status_out="$repo_root/STATUS.md"
    else
        backlog_out="$repo_root/BACKLOG.md"
        plan_out="$repo_root/IMPLEMENTATION-PLAN.md"
        status_out="$repo_root/STATUS.md"
        changelog_out="$repo_root/CHANGELOG.md"
    fi

    # PACK-REVIEW-BD066-068 Finding #3 closure: when flip_mode=1
    # (the `pack tracker disable` flow), the reverse path must be
    # atomic with respect to the tracker.toml mode flip. Snapshot
    # the existing flat files into a backup directory; if any of
    # the emit / strip steps fail, restore from backup and surface
    # a partial-write error WITHOUT flipping the mode. Without this,
    # mid-run failure leaves the user with: (a) partial flat files,
    # (b) tracker.toml still saying mode=tracker — a split state.
    # BD-175: surface-aware backup loop. Pack-side BACKLOG/CHANGELOG live
    # under pack-ops/; client-side under root (legacy). Iterate the four
    # destination paths derived above so the backup/restore stays in sync
    # with the relocation.
    local _emit_path_list
    _emit_path_list="$backlog_out $plan_out $status_out $changelog_out"
    local backup_dir=""
    if [[ "$flip_mode" == "1" ]]; then
        backup_dir="$repo_root/$TMF_PACK_TRACKER_DIR/disable-backup"
        mkdir -p "$backup_dir"
        local f base
        for f in $_emit_path_list; do
            base=$(basename "$f")
            if [[ -f "$f" ]]; then
                cp "$f" "$backup_dir/$base"
            else
                # Sentinel: file did not exist before the run.
                : > "$backup_dir/$base.sentinel-absent"
            fi
        done
    fi

    # BD-133 / D-6: capture the BACKLOG.md header preamble (everything
    # before the first **BD-NNN — / **TD-NNN — / **phase-N heading)
    # BEFORE _tmr_emit_backlog overwrites the file. First-write-wins
    # via the snapshot file at .pack-tracker/backlog-header.snapshot,
    # so the header survives N round-trips byte-identical to its first
    # capture. Run on every reverse path (not gated by flip_mode) so
    # plain `reverse` (without --disable) also preserves the header.
    # The capture is a no-op if the snapshot already exists or if the
    # current preamble is trivial (bare `# BACKLOG`).
    tracker_header_snapshot_capture "$repo_root" || true

    local emit_failed=0
    _tmr_emit_backlog             "$issue_jsons" "$backend_slug" "$backlog_out" || emit_failed=1
    # BD-133 / D-6: re-prepend the captured preamble. Runs immediately
    # after the entries-only emit, before sidecar / mirror-strip /
    # atomicity-gate steps. If the emit failed (emit_failed=1) the
    # apply is skipped — the atomicity gate below will restore the
    # original BACKLOG.md from backup_dir, which already had the
    # preamble in place.
    if [[ "$emit_failed" == "0" ]]; then
        tracker_header_snapshot_apply "$repo_root" "$backlog_out" || emit_failed=1
    fi
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
    # BD-175: surface-aware restore — mirrors the backup loop's path
    # derivation above so pack-side pack-ops/ paths round-trip correctly.
    if [[ "$flip_mode" == "1" && "$emit_failed" == "1" ]]; then
        local restored=0
        local f base
        for f in $_emit_path_list; do
            base=$(basename "$f")
            if [[ -f "$backup_dir/$base.sentinel-absent" ]]; then
                # File didn't exist before the run; remove the half-written one.
                rm -f "$f"
                restored=$((restored + 1))
            elif [[ -f "$backup_dir/$base" ]]; then
                cp "$backup_dir/$base" "$f"
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
  files:      BACKLOG.md, IMPLEMENTATION-PLAN.md (if absent), STATUS.md, CHANGELOG.md (if absent)
  sidecar:    $sidecar_path
  mode-flip:  $([[ "$flip_mode" == "1" ]] && echo "yes (mode.state=flat-file)" || echo "no")
EOF
}
