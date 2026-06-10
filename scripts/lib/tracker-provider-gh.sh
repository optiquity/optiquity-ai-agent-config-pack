# scripts/lib/tracker-provider-gh.sh — GitHub backend for the
# TrackerProvider abstraction.
#
# Implements the 18 ops + raw + capabilities for the github backend
# per V1 §2.7. Sourced by tracker-provider.sh.
#
# Function naming: tracker_provider_gh_<op>(). Each op:
#   - Reads positional args.
#   - Shells out via gh CLI (V1 §2.7.1 ops-to-commands mapping) or
#     gh api graphql for sub-issue/dependency mutations.
#   - Emits canonical Issue JSON (V1 §2.2) to stdout for read ops or
#     a small status JSON for write ops.
#   - On error, emits typed code + message to stderr via
#     tracker_error_emit and returns 1.
#
# Helpers are private (prefix _gh_) and not part of the public API.
#
# Capability flags hardcoded per V1 §2.7.2 and surfaced via
# tracker_provider_gh_capabilities().
#
# Reference:
#   - maintenance-docs/v11-research/ARCHITECTURE.md §2.7
#   - maintenance-docs/v11-research/EXTERNAL-RESEARCH.md §1.3
#     (issue dependencies GA 2025-08-21; sub-issues per §1.2)
#
# Do NOT add a shebang — this file is sourced, not executed.

# ─────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────

# Detect gh-sub-issue extension at first call; cache result.
# The extension provides `gh sub-issue add/list/remove`. When absent,
# sub-issue ops fall back to GraphQL.
#
# BD-129 retro-fix F5: this `gh extension list` call is intentionally
# NOT routed through `_gh_run` (and therefore does not trigger the
# `tracker_gh_repo_setup` helper). `gh extension list` is a global
# user-scope command that enumerates locally-installed gh extensions;
# it does NOT consult git-remote resolution and does NOT need
# `GH_REPO`. Sending it through `_gh_run` would buy nothing and would
# add the typed-error classification overhead to a probe whose only
# meaningful failure mode is "extension absent" (handled by the
# fall-through to "no" via the grep -q exit). The result is cached for
# the lifetime of the process so the global call happens at most once
# per pack-tracker invocation.
_gh_has_sub_issue_extension() {
    if [[ -z "${_GH_SUB_ISSUE_EXT_CACHED:-}" ]]; then
        if gh extension list 2>/dev/null | grep -q "sub-issue"; then
            _GH_SUB_ISSUE_EXT_CACHED="yes"
        else
            _GH_SUB_ISSUE_EXT_CACHED="no"
        fi
    fi
    [[ "$_GH_SUB_ISSUE_EXT_CACHED" == "yes" ]]
}

# Map gh CLI failure (stderr content) to a typed error code per V1 §2.5.
# Reads stderr from a temp file passed as arg 1; emits typed error.
# Order matters: more-specific patterns are tested first.
_gh_classify_error() {
    local stderr_file="$1"
    local content
    content=$(cat "$stderr_file" 2>/dev/null)
    case "$content" in
        *"could not resolve to a Resource"*|*"Not Found"*|*"HTTP 404"*|*"404 Not Found"*)
            tracker_error_emit "not-found" "$content"
            ;;
        *"secondary rate limit"*|*"abuse detection"*|*"abuse rate limit"*)
            tracker_error_emit "rate-limit-secondary" "$content"
            ;;
        *"API rate limit exceeded"*|*"rate limit"*|*"X-RateLimit-Remaining: 0"*)
            tracker_error_emit "rate-limit-primary" "$content"
            ;;
        *"authentication required"*|*"not logged in"*|*"gh auth login"*|*"no authentication token"*)
            tracker_error_emit "auth-missing" "$content"
            ;;
        *"HTTP 401"*|*"Bad credentials"*|*"token has expired"*|*"401 Unauthorized"*)
            tracker_error_emit "auth-expired" "$content"
            ;;
        *"HTTP 403"*|*"insufficient_scope"*|*"requires the"*"scope"*|*"forbidden"*|*"Forbidden"*|*"FORBIDDEN"*)
            # FORBIDDEN: all-caps form is the documented EMU wire shape
            # for cross-enterprise dependency calls per EXTERNAL-RESEARCH
            # §1.3 line 87 ("FORBIDDEN: Unauthorized; path: addBlockedBy").
            tracker_error_emit "auth-insufficient-scope" "$content"
            ;;
        *"could not resolve host"*|*"connection refused"*|*"connection reset"*|*"timeout"*|*"TLS handshake"*|*"network is unreachable"*)
            tracker_error_emit "network-unreachable" "$content"
            ;;
        *"HTTP 422"*|*"unprocessable"*|*"Validation Failed"*|*"422 Unprocessable"*)
            tracker_error_emit "validation" "$content"
            ;;
        *"undefined field"*|*"type mismatch"*|*"unknown field"*|*"Schema is not configured"*)
            tracker_error_emit "schema-reshape" "$content"
            ;;
        *)
            tracker_error_emit "validation" "$content"
            ;;
    esac
}

# Run gh command, capture stdout and stderr separately. On non-zero
# exit, classify stderr into a typed error and return 1. On success,
# print stdout to caller's stdout.
#
# Pre-flight: ensure GH_REPO is exported from the active tracker.toml's
# backend.repo so gh does not fall back to (and fail on) git-remote
# resolution. BD-129 / D-1: without this, repos with no GitHub remote
# (local-path clones, internal mirrors, freshly cloned with no remote
# configured) emit the misleading "none of the git remotes configured
# for this repository point to a known GitHub host" error and the
# tracker verb aborts with a labels_ensure read failure. The helper
# is a no-op when GH_REPO is already set or when no tracker config is
# in scope, so non-tracker callers and test seams are unaffected.
_gh_run() {
    if declare -f tracker_gh_repo_setup >/dev/null 2>&1; then
        tracker_gh_repo_setup
    fi
    local stderr_tmp
    stderr_tmp=$(mktemp -t tracker-gh-stderr.XXXXXX)
    local stdout
    stdout=$("$@" 2>"$stderr_tmp")
    local rc=$?
    if [[ $rc -ne 0 ]]; then
        _gh_classify_error "$stderr_tmp"
        rm -f "$stderr_tmp"
        return 1
    fi
    rm -f "$stderr_tmp"
    printf '%s' "$stdout"
}

# _gh_owner_repo
# Resolve the bare OWNER/REPO slug used by REST paths
# (/repos/<owner_repo>/issues/N) and GraphQL owner/name splits.
#
# BD-204 (closes a BD-129-class gap): the previous idiom at the five
# resolution sites in this file — argument-less `gh repo view --json
# nameWithOwner` — does NOT honor the GH_REPO env var. From a working
# directory that is not a clone of the target repo it dies with
# "failed to run git: fatal: not a git repository", killing
# link/unlink/sub-issue ops before any mutation fires (observed
# empirically in the BD-204 live rehearsal: the forward migration
# runs from a temp seeded tree, not a clone). The five sites slipped
# past BD-129 because they resolve the slug ITSELF rather than
# passing --repo to an operation.
#
# Resolution order:
#   1. Ensure tracker_gh_repo_setup has run (same guard _gh_run uses)
#      so GH_REPO is exported from the active tracker.toml's
#      backend.repo when a tracker config is in scope.
#   2. Prefer ${GH_REPO} when set. tracker-config.sh exports the
#      canonical `[HOST/]OWNER/REPO` shape; strip the optional HOST/
#      prefix because REST paths and owner/name splits need the bare
#      `OWNER/REPO` form. A set-but-degenerate GH_REPO (slash-less,
#      >=3 slashes like a/b/c/d, empty owner or repo segment after
#      the strip e.g. a trailing slash) is a typed validation error
#      (fail loud, never silently fall back past a caller-supplied
#      value). Exception: a leading slash on a two-slash value
#      (/owner/repo) is normalized — the empty leading segment is
#      stripped as a zero-length HOST — and accepted.
#   3. ONLY when GH_REPO is unset/empty: fall back to `gh repo view
#      --json nameWithOwner` via _gh_run (which classifies failures
#      into typed errors). This path requires a cwd whose git remote
#      points at a known GitHub host.
#   4. If neither source yields a slug, fail loud with a typed
#      validation error.
_gh_owner_repo() {
    if declare -f tracker_gh_repo_setup >/dev/null 2>&1; then
        tracker_gh_repo_setup
    fi
    local slug="${GH_REPO:-}"
    if [[ -n "$slug" ]]; then
        # [HOST/]OWNER/REPO → OWNER/REPO (two slashes → strip the
        # leading HOST/ segment; one slash → already bare).
        case "$slug" in
            */*/*) slug="${slug#*/}" ;;
        esac
        # Post-strip shape guard (BD-204 review F-4): accept exactly
        # OWNER/REPO — one slash, both segments non-empty. Degenerate
        # shapes (slash-less; >=3 slashes pre-strip, e.g. a/b/c/d;
        # trailing slash; empty owner or repo segment post-strip,
        # e.g. /owner or host//repo) fail loud here with a typed
        # validation error instead of passing a malformed slug through
        # to the REST path / owner-name split. One benign exception:
        # a leading slash on a two-slash value (/owner/repo) is NOT
        # rejected — the empty leading segment is stripped above as a
        # zero-length HOST and the remaining valid OWNER/REPO is
        # accepted.
        local owner_part="${slug%%/*}"
        local repo_part="${slug#*/}"
        if [[ "$slug" != */* || -z "$owner_part" || -z "$repo_part" \
              || "$repo_part" == */* ]]; then
            tracker_error_emit "validation" \
                "owner_repo: GH_REPO='$GH_REPO' is not a [HOST/]OWNER/REPO slug"
            return 1
        fi
        printf '%s' "$slug"
        return 0
    fi
    slug=$(_gh_run gh repo view --json nameWithOwner --jq '.nameWithOwner') || return 1
    if [[ -z "$slug" ]]; then
        tracker_error_emit "validation" \
            "owner_repo: cannot resolve OWNER/REPO (GH_REPO unset and 'gh repo view' returned empty); set backend.repo in tracker.toml or export GH_REPO"
        return 1
    fi
    printf '%s' "$slug"
}

# Default JSON field set for list (matches V1 §2.2 list-projection).
_gh_list_fields() {
    echo "number,title,state,labels,milestone,assignees,createdAt,updatedAt,url"
}

# Full JSON field set for get (canonical Issue shape).
_gh_full_fields() {
    echo "number,title,body,state,stateReason,labels,assignees,milestone,createdAt,updatedAt,closedAt,url"
}

# Normalize a single gh `issue view` JSON object to the canonical
# Issue shape (V1 §2.2). Reads JSON from stdin; emits JSON to stdout.
_gh_normalize_issue() {
    python3 -c '
import json, sys
data = json.load(sys.stdin)
def opt(d, k, default=None):
    v = d.get(k, default)
    return v if v is not None else default
labels_in    = opt(data, "labels", []) or []
assignees_in = opt(data, "assignees", []) or []
milestone_in = opt(data, "milestone", None)
issue = {
    "id":           str(opt(data, "number", "")),
    "number":       str(opt(data, "number", "")),
    "title":        opt(data, "title", ""),
    "body":         opt(data, "body", ""),
    "state":        (opt(data, "state", "OPEN") or "OPEN").lower(),
    "state_reason": opt(data, "stateReason"),
    "labels":       [l.get("name", "") for l in labels_in if isinstance(l, dict)],
    "assignees":    [a.get("login", "") for a in assignees_in if isinstance(a, dict)],
    "milestone":    (milestone_in or {}).get("title") if isinstance(milestone_in, dict) else None,
    "type":         opt(data, "issueType"),
    "parent":       None,
    "children":     [],
    "links":        [],
    "iteration":    None,
    "priority":     None,
    "created_at":   opt(data, "createdAt"),
    "updated_at":   opt(data, "updatedAt"),
    "closed_at":    opt(data, "closedAt"),
    "url":          opt(data, "url", ""),
    "raw":          data,
}
print(json.dumps(issue))
'
}

# ─────────────────────────────────────────────────────────────────
# Read ops
# ─────────────────────────────────────────────────────────────────

# tracker_provider_gh_list <filter-json> [<limit>] [<cursor>]
# filter-json: {"label": "...", "state": "open|closed|all", "milestone": "...", "search": "..."}
# Returns: {"items": [...], "next_cursor": null}
tracker_provider_gh_list() {
    local filter="${1:-{\}}"
    local limit="${2:-30}"
    # cursor (arg 3) reserved for future GraphQL pagination; gh issue list is page-based.

    local label state milestone search_q
    label=$(printf '%s' "$filter"     | jq -r '.label // empty'     2>/dev/null)
    state=$(printf '%s' "$filter"     | jq -r '.state // empty'     2>/dev/null)
    milestone=$(printf '%s' "$filter" | jq -r '.milestone // empty' 2>/dev/null)
    search_q=$(printf '%s' "$filter"  | jq -r '.search // empty'    2>/dev/null)

    local args
    args=("issue" "list" "--json" "$(_gh_list_fields)" "--limit" "$limit")
    [[ -n "$label" ]]     && args+=("--label"     "$label")
    [[ -n "$state" ]]     && args+=("--state"     "$state")
    [[ -n "$milestone" ]] && args+=("--milestone" "$milestone")
    [[ -n "$search_q" ]]  && args+=("--search"    "$search_q")

    local output
    output=$(_gh_run gh "${args[@]}") || return 1

    printf '%s' "$output" | python3 -c '
import json, sys
items = json.load(sys.stdin) or []
out = []
for d in items:
    labels    = d.get("labels", []) or []
    assignees = d.get("assignees", []) or []
    milestone = d.get("milestone") or {}
    out.append({
        "id":         str(d.get("number", "")),
        "number":     str(d.get("number", "")),
        "title":      d.get("title", ""),
        "state":      (d.get("state", "OPEN") or "OPEN").lower(),
        "labels":     [l.get("name", "") for l in labels if isinstance(l, dict)],
        "assignees":  [a.get("login", "") for a in assignees if isinstance(a, dict)],
        "milestone":  milestone.get("title") if isinstance(milestone, dict) else None,
        "type":       None,
        "parent":     None,
        "url":        d.get("url", ""),
    })
print(json.dumps({"items": out, "next_cursor": None}))
'
}

# tracker_provider_gh_get <id>
tracker_provider_gh_get() {
    local id="$1"
    if [[ -z "$id" ]]; then
        tracker_error_emit "validation" "get: id required"
        return 1
    fi
    local output
    output=$(_gh_run gh issue view "$id" --json "$(_gh_full_fields)") || return 1
    printf '%s' "$output" | _gh_normalize_issue
}

# tracker_provider_gh_search <query> [<limit>]
tracker_provider_gh_search() {
    local query="$1"
    local limit="${2:-30}"
    if [[ -z "$query" ]]; then
        tracker_error_emit "validation" "search: query required"
        return 1
    fi
    local output
    output=$(_gh_run gh search issues "$query" --json number,title,url,state,labels --limit "$limit") || return 1
    printf '%s' "$output" | python3 -c '
import json, sys
items = json.load(sys.stdin) or []
out = []
for d in items:
    labels = d.get("labels", []) or []
    out.append({
        "id":     str(d.get("number", "")),
        "number": str(d.get("number", "")),
        "title":  d.get("title", ""),
        "state":  (d.get("state", "open") or "open").lower(),
        "labels": [l.get("name", "") for l in labels if isinstance(l, dict)],
        "url":    d.get("url", ""),
    })
print(json.dumps({"items": out, "next_cursor": None}))
'
}

# ─────────────────────────────────────────────────────────────────
# Write ops — simple
# ─────────────────────────────────────────────────────────────────

# tracker_provider_gh_create <payload-json>
# payload: {"title": "...", "body": "...", "labels": ["..."], "assignees": ["..."],
#           "milestone": "...", "type": "..."}
# Returns: {"id": "...", "number": "...", "url": "..."}
tracker_provider_gh_create() {
    local payload="${1:-{\}}"
    local title body labels assignees milestone
    title=$(printf '%s' "$payload"     | jq -r '.title // empty')
    body=$(printf '%s' "$payload"      | jq -r '.body // empty')
    labels=$(printf '%s' "$payload"    | jq -r '.labels // [] | join(",")')
    assignees=$(printf '%s' "$payload" | jq -r '.assignees // [] | join(",")')
    milestone=$(printf '%s' "$payload" | jq -r '.milestone // empty')

    if [[ -z "$title" ]]; then
        tracker_error_emit "validation" "create: title required"
        return 1
    fi

    local body_file
    body_file=$(mktemp -t tracker-gh-body.XXXXXX)
    printf '%s' "$body" > "$body_file"

    local args
    args=("issue" "create" "--title" "$title" "--body-file" "$body_file")
    [[ -n "$labels" ]]    && args+=("--label"     "$labels")
    [[ -n "$assignees" ]] && args+=("--assignee"  "$assignees")
    [[ -n "$milestone" ]] && args+=("--milestone" "$milestone")
    # NOTE: type field is set via labels at create time; for native
    # GH issue types (org-level), set post-create via raw().

    local url rc
    url=$(_gh_run gh "${args[@]}")
    rc=$?
    rm -f "$body_file"
    [[ $rc -ne 0 ]] && return 1

    local number
    number=$(printf '%s' "$url" | sed -E 's|.*/issues/([0-9]+).*|\1|')
    printf '{"id": "%s", "number": "%s", "url": "%s"}\n' "$number" "$number" "$url"
}

# tracker_provider_gh_update <id> <patch-json>
# patch keys: title, body, add_labels[], remove_labels[],
#             add_assignees[], remove_assignees[], milestone
tracker_provider_gh_update() {
    local id="$1"
    local patch="${2:-{\}}"
    if [[ -z "$id" ]]; then
        tracker_error_emit "validation" "update: id required"
        return 1
    fi

    local title body add_labels remove_labels add_assignees remove_assignees milestone
    title=$(printf '%s' "$patch"            | jq -r '.title // empty')
    body=$(printf '%s' "$patch"             | jq -r '.body // empty')
    add_labels=$(printf '%s' "$patch"       | jq -r '.add_labels // [] | join(",")')
    remove_labels=$(printf '%s' "$patch"    | jq -r '.remove_labels // [] | join(",")')
    add_assignees=$(printf '%s' "$patch"    | jq -r '.add_assignees // [] | join(",")')
    remove_assignees=$(printf '%s' "$patch" | jq -r '.remove_assignees // [] | join(",")')
    milestone=$(printf '%s' "$patch"        | jq -r '.milestone // empty')

    local args body_file=""
    args=("issue" "edit" "$id")
    [[ -n "$title" ]] && args+=("--title" "$title")
    if [[ -n "$body" ]]; then
        body_file=$(mktemp -t tracker-gh-body.XXXXXX)
        printf '%s' "$body" > "$body_file"
        args+=("--body-file" "$body_file")
    fi
    [[ -n "$add_labels" ]]       && args+=("--add-label"        "$add_labels")
    [[ -n "$remove_labels" ]]    && args+=("--remove-label"     "$remove_labels")
    [[ -n "$add_assignees" ]]    && args+=("--add-assignee"     "$add_assignees")
    [[ -n "$remove_assignees" ]] && args+=("--remove-assignee"  "$remove_assignees")
    [[ -n "$milestone" ]]        && args+=("--milestone"        "$milestone")

    _gh_run gh "${args[@]}"
    local rc=$?
    [[ -n "$body_file" ]] && rm -f "$body_file"
    [[ $rc -ne 0 ]] && return 1
    printf '{"id": "%s", "updated": true}\n' "$id"
}

# tracker_provider_gh_close <id> [<reason>]
# reason: completed|not_planned|duplicate (V1 §2.7.1 row 6)
tracker_provider_gh_close() {
    local id="$1"
    local reason="${2:-completed}"
    if [[ -z "$id" ]]; then
        tracker_error_emit "validation" "close: id required"
        return 1
    fi
    case "$reason" in
        completed|not_planned|duplicate) ;;
        *)
            tracker_error_emit "validation" "close: invalid reason '$reason'"
            return 1
            ;;
    esac
    _gh_run gh issue close "$id" --reason "$reason" >/dev/null || return 1
    printf '{"id": "%s", "state": "closed", "state_reason": "%s"}\n' "$id" "$reason"
}

# tracker_provider_gh_reopen <id>
tracker_provider_gh_reopen() {
    local id="$1"
    if [[ -z "$id" ]]; then
        tracker_error_emit "validation" "reopen: id required"
        return 1
    fi
    _gh_run gh issue reopen "$id" >/dev/null || return 1
    printf '{"id": "%s", "state": "open"}\n' "$id"
}

# tracker_provider_gh_comment <id> <body>
# Returns: {"id": "...", "comment_url": "..."}
tracker_provider_gh_comment() {
    local id="$1"
    local body="$2"
    if [[ -z "$id" ]]; then
        tracker_error_emit "validation" "comment: id required"
        return 1
    fi
    if [[ -z "$body" ]]; then
        tracker_error_emit "validation" "comment: body required"
        return 1
    fi
    local body_file
    body_file=$(mktemp -t tracker-gh-comment.XXXXXX)
    printf '%s' "$body" > "$body_file"
    local url rc
    url=$(_gh_run gh issue comment "$id" --body-file "$body_file")
    rc=$?
    rm -f "$body_file"
    [[ $rc -ne 0 ]] && return 1
    printf '{"id": "%s", "comment_url": "%s"}\n' "$id" "$url"
}

# tracker_provider_gh_set_labels <id> <labels-json-array>
# Replaces the issue's label set wholesale (remove all current,
# then add new). gh CLI has no atomic "set" op.
tracker_provider_gh_set_labels() {
    local id="$1"
    local labels="${2:-[]}"
    if [[ -z "$id" ]]; then
        tracker_error_emit "validation" "set_labels: id required"
        return 1
    fi
    local current to_remove new_labels
    current=$(_gh_run gh issue view "$id" --json labels --jq '[.labels[].name] | join(",")') || return 1
    new_labels=$(printf '%s' "$labels" | jq -r 'join(",")')
    to_remove="$current"

    local args
    args=("issue" "edit" "$id")
    [[ -n "$to_remove" ]]  && args+=("--remove-label" "$to_remove")
    [[ -n "$new_labels" ]] && args+=("--add-label"    "$new_labels")
    if [[ -z "$to_remove" && -z "$new_labels" ]]; then
        printf '{"id": "%s", "labels": %s}\n' "$id" "$labels"
        return 0
    fi
    _gh_run gh "${args[@]}" >/dev/null || return 1
    printf '{"id": "%s", "labels": %s}\n' "$id" "$labels"
}

# tracker_provider_gh_set_assignee <id> <assignees-json-array>
# Replaces the issue's assignees wholesale.
tracker_provider_gh_set_assignee() {
    local id="$1"
    local assignees="${2:-[]}"
    if [[ -z "$id" ]]; then
        tracker_error_emit "validation" "set_assignee: id required"
        return 1
    fi
    local current to_remove new_assignees
    current=$(_gh_run gh issue view "$id" --json assignees --jq '[.assignees[].login] | join(",")') || return 1
    new_assignees=$(printf '%s' "$assignees" | jq -r 'join(",")')
    to_remove="$current"

    local args
    args=("issue" "edit" "$id")
    [[ -n "$to_remove" ]]     && args+=("--remove-assignee" "$to_remove")
    [[ -n "$new_assignees" ]] && args+=("--add-assignee"    "$new_assignees")
    if [[ -z "$to_remove" && -z "$new_assignees" ]]; then
        printf '{"id": "%s", "assignees": %s}\n' "$id" "$assignees"
        return 0
    fi
    _gh_run gh "${args[@]}" >/dev/null || return 1
    printf '{"id": "%s", "assignees": %s}\n' "$id" "$assignees"
}

# tracker_provider_gh_set_milestone <id> <milestone-name>
# Empty milestone string clears the milestone.
tracker_provider_gh_set_milestone() {
    local id="$1"
    local milestone="${2:-}"
    if [[ -z "$id" ]]; then
        tracker_error_emit "validation" "set_milestone: id required"
        return 1
    fi
    if [[ -z "$milestone" ]]; then
        _gh_run gh issue edit "$id" --milestone "" >/dev/null || return 1
    else
        _gh_run gh issue edit "$id" --milestone "$milestone" >/dev/null || return 1
    fi
    printf '{"id": "%s", "milestone": "%s"}\n' "$id" "$milestone"
}

# ─────────────────────────────────────────────────────────────────
# Link / unlink
# ─────────────────────────────────────────────────────────────────

# tracker_provider_gh_link <id> <other_id> <kind>
# kind: blocks|blocked-by|related|duplicates|parent|child
#
# Implementation per V1 §2.7.1 row 12:
#   - blocks/blocked-by: first-class GitHub issue-dependency GraphQL
#     mutation (BD-111; GA 2025-08-21 per EXTERNAL-RESEARCH §1.3).
#     Mutation name `addBlockedBy` per EXTERNAL-RESEARCH §1.3. The
#     argument shape (`issueId` + `blockingIssueId`) is LIVE-VERIFIED
#     (schema introspection of `AddBlockedByInput`, 2026-06-10,
#     BD-204): inputFields are `issueId: ID!` (the issue that IS
#     blocked) + `blockingIssueId: ID!` (the issue that BLOCKS it),
#     plus optional clientMutationId. `kind="blocks"` is expressed by
#     inverting the operands (B blocked-by A == A blocks B) since
#     EXTERNAL-RESEARCH names only the `addBlockedBy` direction.
#   - related/duplicates: comment-based marker (no first-class API).
#   - parent/child: delegates to sub_issue_create.
#
# Comment-based fallback for blocks/blocked-by remains available to
# callers that explicitly want it via provider_comment() or
# provider_raw() (BD-060-era comment-marker behavior — colloquially
# "the V3 §28 fallback" — is preserved as an escape hatch).
tracker_provider_gh_link() {
    local id="$1"
    local other_id="$2"
    local kind="$3"
    if [[ -z "$id" || -z "$other_id" || -z "$kind" ]]; then
        tracker_error_emit "validation" "link: id, other_id, kind required"
        return 1
    fi
    case "$kind" in
        blocks|blocked-by)
            # First-class GH issue-dependency mutation.
            # Resolve owner/repo via _gh_owner_repo (GH_REPO-preferred,
            # BD-204) and node-ids (matches sub_issue_create
            # extension-absent path).
            local owner_repo issue_node other_node query
            local source_node target_node
            owner_repo=$(_gh_owner_repo) || return 1
            issue_node=$(_gh_run gh api "/repos/$owner_repo/issues/$id"       --jq '.node_id') || return 1
            other_node=$(_gh_run gh api "/repos/$owner_repo/issues/$other_id" --jq '.node_id') || return 1
            # blocked-by: id is blocked by other_id  → addBlockedBy(issueId=id,       blockingIssueId=other_id)
            # blocks:     id blocks other_id          → addBlockedBy(issueId=other_id, blockingIssueId=id)
            if [[ "$kind" == "blocked-by" ]]; then
                source_node="$issue_node"
                target_node="$other_node"
            else
                source_node="$other_node"
                target_node="$issue_node"
            fi
            query='mutation($issueId: ID!, $blockingIssueId: ID!) { addBlockedBy(input: { issueId: $issueId, blockingIssueId: $blockingIssueId }) { issue { number } } }'
            _gh_run gh api graphql -f "query=$query" -F "issueId=$source_node" -F "blockingIssueId=$target_node" >/dev/null || return 1
            ;;
        related|duplicates)
            local body
            case "$kind" in
                related)     body="Related to #$other_id" ;;
                duplicates)  body="Duplicates #$other_id" ;;
            esac
            tracker_provider_gh_comment "$id" "$body" >/dev/null || return 1
            ;;
        parent)
            tracker_provider_gh_sub_issue_create "$other_id" "{\"existing_id\": \"$id\"}" >/dev/null || return 1
            ;;
        child)
            tracker_provider_gh_sub_issue_create "$id" "{\"existing_id\": \"$other_id\"}" >/dev/null || return 1
            ;;
        *)
            tracker_error_emit "validation" "link: unknown kind '$kind'"
            return 1
            ;;
    esac
    printf '{"id": "%s", "linked_to": "%s", "kind": "%s"}\n' "$id" "$other_id" "$kind"
}

# tracker_provider_gh_unlink <id> <other_id> <kind>
# kind: blocks|blocked-by|related|duplicates|parent|child
#
# Implementation per V1 §2.7.1 row 13 (BD-111 scope-extended
# 2026-05-15 to include the symmetric `removeBlockedBy` unlink path):
#   - blocks/blocked-by: first-class GitHub issue-dependency removal
#     GraphQL mutation. Mutation name `removeBlockedBy` (the symmetric
#     pair of `addBlockedBy`, matching GH's `addSubIssue` /
#     `removeSubIssue` precedent already used in this file) and the
#     argument shape (`issueId` + `blockingIssueId`, mirroring
#     `addBlockedBy`) are LIVE-VERIFIED (schema introspection of
#     `RemoveBlockedByInput`, 2026-06-10, BD-204): inputFields are
#     `issueId` + `blockingIssueId` plus optional clientMutationId.
#     Operand inversion for `kind="blocks"` matches the link side:
#     removing "B blocked-by A" is the same edge as removing
#     "A blocks B".
#   - parent/child: first-class via sub_issue_unlink (unchanged).
#   - related/duplicates: still comment-based on the link side; surface
#     a typed validation error here (callers remove the marker comment
#     manually via the GH UI or via provider_raw()).
#
# Comment-based fallback for blocks/blocked-by remains available to
# callers that explicitly want it: callers can locate the marker
# comment via provider_get(id) (returns full body) and edit/delete it
# via provider_raw() with a DELETE on /repos/.../issues/comments/<N>.
tracker_provider_gh_unlink() {
    local id="$1"
    local other_id="$2"
    local kind="$3"
    if [[ -z "$id" || -z "$other_id" || -z "$kind" ]]; then
        tracker_error_emit "validation" "unlink: id, other_id, kind required"
        return 1
    fi
    case "$kind" in
        parent)
            tracker_provider_gh_sub_issue_unlink "$other_id" "$id" >/dev/null || return 1
            ;;
        child)
            tracker_provider_gh_sub_issue_unlink "$id" "$other_id" >/dev/null || return 1
            ;;
        blocks|blocked-by)
            # First-class GH issue-dependency removal mutation
            # (BD-111 symmetric pair of addBlockedBy in
            # tracker_provider_gh_link). Resolve owner/repo (via
            # _gh_owner_repo, GH_REPO-preferred — BD-204) and
            # node-ids the same way the link side does.
            local owner_repo issue_node other_node query
            local source_node target_node
            owner_repo=$(_gh_owner_repo) || return 1
            issue_node=$(_gh_run gh api "/repos/$owner_repo/issues/$id"       --jq '.node_id') || return 1
            other_node=$(_gh_run gh api "/repos/$owner_repo/issues/$other_id" --jq '.node_id') || return 1
            # blocked-by: id no-longer blocked by other_id  → removeBlockedBy(issueId=id,       blockingIssueId=other_id)
            # blocks:     id no-longer blocks other_id       → removeBlockedBy(issueId=other_id, blockingIssueId=id)
            if [[ "$kind" == "blocked-by" ]]; then
                source_node="$issue_node"
                target_node="$other_node"
            else
                source_node="$other_node"
                target_node="$issue_node"
            fi
            query='mutation($issueId: ID!, $blockingIssueId: ID!) { removeBlockedBy(input: { issueId: $issueId, blockingIssueId: $blockingIssueId }) { issue { number } } }'
            _gh_run gh api graphql -f "query=$query" -F "issueId=$source_node" -F "blockingIssueId=$target_node" >/dev/null || return 1
            ;;
        related|duplicates)
            tracker_error_emit "validation" \
                "unlink: kind '$kind' is comment-based (no first-class API); locate the marker comment via provider_get(id) and remove it manually or via provider_raw() DELETE on /repos/.../issues/comments/<comment-id>"
            return 1
            ;;
        *)
            tracker_error_emit "validation" "unlink: unknown kind '$kind'"
            return 1
            ;;
    esac
    printf '{"id": "%s", "unlinked_from": "%s", "kind": "%s"}\n' "$id" "$other_id" "$kind"
}

# ─────────────────────────────────────────────────────────────────
# Sub-issue ops
# ─────────────────────────────────────────────────────────────────

# tracker_provider_gh_sub_issue_create <parent_id> <payload-json>
# payload: either a full issue payload (creates new sub-issue) or
#          {"existing_id": "..."} (links existing issue as sub-issue).
# Uses gh-sub-issue extension if present, else GraphQL.
tracker_provider_gh_sub_issue_create() {
    local parent_id="$1"
    local payload="${2:-{\}}"
    if [[ -z "$parent_id" ]]; then
        tracker_error_emit "validation" "sub_issue_create: parent_id required"
        return 1
    fi

    local existing_id child_id
    existing_id=$(printf '%s' "$payload" | jq -r '.existing_id // empty')
    if [[ -n "$existing_id" ]]; then
        child_id="$existing_id"
    else
        local result
        result=$(tracker_provider_gh_create "$payload") || return 1
        child_id=$(printf '%s' "$result" | jq -r '.id')
    fi

    if _gh_has_sub_issue_extension; then
        _gh_run gh sub-issue add --parent "$parent_id" --child "$child_id" >/dev/null || return 1
    else
        local owner_repo parent_node child_node query
        owner_repo=$(_gh_owner_repo) || return 1
        parent_node=$(_gh_run gh api "/repos/$owner_repo/issues/$parent_id" --jq '.node_id') || return 1
        child_node=$(_gh_run gh api  "/repos/$owner_repo/issues/$child_id"  --jq '.node_id') || return 1
        query='mutation($parentId: ID!, $childId: ID!) { addSubIssue(input: { issueId: $parentId, subIssueId: $childId }) { issue { number } } }'
        _gh_run gh api graphql -f "query=$query" -F "parentId=$parent_node" -F "childId=$child_node" >/dev/null || return 1
    fi
    printf '{"parent_id": "%s", "child_id": "%s"}\n' "$parent_id" "$child_id"
}

# tracker_provider_gh_sub_issue_list <parent_id>
tracker_provider_gh_sub_issue_list() {
    local parent_id="$1"
    if [[ -z "$parent_id" ]]; then
        tracker_error_emit "validation" "sub_issue_list: parent_id required"
        return 1
    fi
    if _gh_has_sub_issue_extension; then
        _gh_run gh sub-issue list --parent "$parent_id" --json number,title,state || return 1
    else
        local owner_repo owner repo query
        owner_repo=$(_gh_owner_repo) || return 1
        owner=$(printf '%s' "$owner_repo" | cut -d/ -f1)
        repo=$(printf  '%s' "$owner_repo" | cut -d/ -f2)
        query='query($owner: String!, $repo: String!, $number: Int!) { repository(owner: $owner, name: $repo) { issue(number: $number) { subIssues(first: 100) { nodes { number title state } } } } }'
        _gh_run gh api graphql -f "query=$query" -F "owner=$owner" -F "repo=$repo" -F "number=$parent_id" --jq '.data.repository.issue.subIssues.nodes' || return 1
    fi
}

# tracker_provider_gh_sub_issue_unlink <parent_id> <child_id>
tracker_provider_gh_sub_issue_unlink() {
    local parent_id="$1"
    local child_id="$2"
    if [[ -z "$parent_id" || -z "$child_id" ]]; then
        tracker_error_emit "validation" "sub_issue_unlink: parent_id, child_id required"
        return 1
    fi
    if _gh_has_sub_issue_extension; then
        _gh_run gh sub-issue remove --parent "$parent_id" --child "$child_id" >/dev/null || return 1
    else
        local owner_repo parent_node child_node query
        owner_repo=$(_gh_owner_repo) || return 1
        parent_node=$(_gh_run gh api "/repos/$owner_repo/issues/$parent_id" --jq '.node_id') || return 1
        child_node=$(_gh_run gh api  "/repos/$owner_repo/issues/$child_id"  --jq '.node_id') || return 1
        query='mutation($parentId: ID!, $childId: ID!) { removeSubIssue(input: { issueId: $parentId, subIssueId: $childId }) { issue { number } } }'
        _gh_run gh api graphql -f "query=$query" -F "parentId=$parent_node" -F "childId=$child_node" >/dev/null || return 1
    fi
    printf '{"parent_id": "%s", "child_id": "%s", "unlinked": true}\n' "$parent_id" "$child_id"
}

# ─────────────────────────────────────────────────────────────────
# Capabilities (V1 §2.7.2 — hardcoded for github)
# ─────────────────────────────────────────────────────────────────

tracker_provider_gh_capabilities() {
    cat <<'CAPS'
{
  "backend_name": "github",
  "hierarchy": {
    "supported": true,
    "depth_ceiling": 8,
    "children_per_parent_ceiling": 100,
    "parent_per_child_ceiling": 1
  },
  "dependencies": {
    "supported": true,
    "kinds": ["blocks", "blocked-by", "duplicates", "related"],
    "per_relationship_ceiling": 50,
    "cross_repo_supported": "same-org-internal-only"
  },
  "labels": {
    "supported": true,
    "model": "flat",
    "per_issue_ceiling": 100
  },
  "milestone": {
    "supported": true,
    "per_issue_ceiling": 1
  },
  "type_field": {
    "supported": true,
    "values_managed_at": "org"
  },
  "iteration": {
    "supported": true,
    "where": "project"
  },
  "custom_fields": {
    "supported": true,
    "passthrough_only": true
  },
  "search": {
    "language": "github-qualifier",
    "result_ceiling_per_query": 1000
  },
  "body": {
    "limit": 65536,
    "storage_format": "raw_text"
  },
  "rate_limits": {
    "writes_per_minute_recommended": 60,
    "reads_per_minute_recommended": 120,
    "min_write_interval_s": 1,
    "writes_per_hour_max": 500
  },
  "raw_escape_hatch": true
}
CAPS
}

# ─────────────────────────────────────────────────────────────────
# Raw escape hatch (V1 §2.1, §2.7.1 last row)
# ─────────────────────────────────────────────────────────────────

# tracker_provider_gh_raw <method> <path> [<body>]
# - <path> beginning with "/" → gh api <path> [-X METHOD] [--input body]
# - <path> == "graphql"       → gh api graphql -f query=<body>
tracker_provider_gh_raw() {
    local method="$1"
    local path="$2"
    local body="${3:-}"
    if [[ -z "$method" || -z "$path" ]]; then
        tracker_error_emit "validation" "raw: method and path required"
        return 1
    fi
    if [[ "$path" == "graphql" ]]; then
        if [[ -z "$body" ]]; then
            tracker_error_emit "validation" "raw: graphql requires body (the query)"
            return 1
        fi
        _gh_run gh api graphql -f "query=$body" || return 1
        return 0
    fi
    local args body_file=""
    args=("api" "$path")
    [[ "$method" != "GET" ]] && args+=("-X" "$method")
    if [[ -n "$body" ]]; then
        body_file=$(mktemp -t tracker-gh-raw.XXXXXX)
        printf '%s' "$body" > "$body_file"
        args+=("--input" "$body_file")
    fi
    _gh_run gh "${args[@]}"
    local rc=$?
    [[ -n "$body_file" ]] && rm -f "$body_file"
    return $rc
}
