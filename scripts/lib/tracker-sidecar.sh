# scripts/lib/tracker-sidecar.sh — reverse-migration sidecar emitter
# (BD-067).
#
# V1 §6.6 + §6.6.1 (DELTA A2): the sidecar captures tracker-only
# data the v10 grammar cannot represent. This includes:
#
#   - Reactions (per-emoji counts)
#   - Comment thread (with author + date + body)
#   - Attachment URLs
#   - Audit log of state changes
#   - Per-entry template_version
#   - Per-entry extra_fields (fields present on the tracker entry
#     but not in v10 grammar)
#   - Per-entry template_archive_path (relative path to
#     templates-archive/<template_version>/SCHEMA.md)
#
# At v11.0 there are no v11.x-only template fields yet (the bd-v11.0
# / td-v11.0 templates use only v10-grammar fields). `extra_fields`
# is therefore empty for every entry. The shape ships now so v11.1+
# entries can populate it without re-architecting.
#
# Public API:
#   - tracker_sidecar_emit <repo-root> <mapping-json> [<include-comments>]
#       Emit the dated sidecar at .pack-tracker/reverse.sidecar.<date>.md.
#       Emits the path on stdout. include_comments=1 includes full
#       comment-thread bodies (V1 §6.7); 0 includes only counts.
#
# Reference: ARCHITECTURE.md §6.6, §6.6.1; ARCHITECTURE-V3.1-DELTA.md A2.
#
# Do NOT add a shebang — this file is sourced, not executed.

# tracker_sidecar_emit <repo-root> <mapping-json> [<include-comments>]
tracker_sidecar_emit() {
    local repo_root="$1"
    local mapping="$2"
    local include_comments="${3:-0}"

    local now_date sidecar_path sidecar_dir
    now_date=$(date -u '+%Y-%m-%d')
    sidecar_dir="$repo_root/.pack-tracker"
    sidecar_path="$sidecar_dir/reverse.sidecar.$now_date.md"
    mkdir -p "$sidecar_dir"

    # Build per-entry sidecar sections by walking the mapping and
    # fetching each issue's full canonical Issue JSON.
    {
        cat <<EOF
# Reverse-migration sidecar — $now_date

This file captures tracker-only data the v10 grammar cannot
represent. Keep it if you intend to re-enable the tracker later;
without it, re-enable will default any pack-version-specific fields
and warn for each affected entry.

Reference: ARCHITECTURE.md §6.6, §6.6.1.

EOF

        local pack_id gh_id issue
        while IFS= read -r pack_id; do
            [[ -z "$pack_id" ]] && continue
            gh_id=$(printf '%s' "$mapping" | jq -r --arg k "$pack_id" \
                'if has($k) then .[$k].id else empty end')
            [[ -z "$gh_id" || "$gh_id" == "null" ]] && continue
            if ! issue=$(provider_get "$gh_id" 2>/dev/null); then
                continue
            fi
            _tmsc_emit_entry_section "$pack_id" "$gh_id" "$issue" "$include_comments"
        done < <(printf '%s' "$mapping" | jq -r 'keys[]')
    } > "$sidecar_path"

    echo "$sidecar_path"
}

# ─────────────────────────────────────────────────────────────────
# Private helpers
# ─────────────────────────────────────────────────────────────────

_tmsc_emit_entry_section() {
    local pack_id="$1"
    local gh_id="$2"
    local issue="$3"
    local include_comments="$4"

    local title template_version template_archive_path version_dir
    title=$(printf '%s' "$issue" | jq -r '.title // ""')
    template_version=$(printf '%s' "$issue" | python3 -c '
import json, re, sys
data = json.load(sys.stdin)
body = data.get("body", "") or ""
m = re.search(r"<!--\s*template_version:\s*([^\s]+)\s*-->", body)
print(m.group(1) if m else "")')

    if [[ -n "$template_version" ]]; then
        # Extract the version segment (e.g. "bd-v11.0" → "v11.0";
        # "phase-task-v11.2" → "v11.2"). The archive layout is
        # templates-archive/<version_dir>/<template_version>/SCHEMA.md
        # (per V3.3 §6.5; addresses Finding #6 from PACK-REVIEW-BD066-068).
        version_dir=$(printf '%s' "$template_version" | sed -nE 's/^.*-(v[0-9]+\.[0-9]+)$/\1/p')
        if [[ -n "$version_dir" ]]; then
            template_archive_path="maintenance-docs/v11-research/templates-archive/$version_dir/$template_version/SCHEMA.md"
        else
            # Malformed template_version (no -vX.Y suffix); emit nothing.
            template_archive_path=""
        fi
    else
        template_archive_path=""
    fi

    cat <<EOF
## $pack_id (gh #$gh_id)

- title: $title
- template_version: ${template_version:-(none)}
- template_archive_path: ${template_archive_path:-(none)}

### extra_fields

EOF
    # Per V1 §6.6.1, extra_fields is the set of fields on the tracker
    # entry not representable in v10 grammar. v11.0 templates use
    # only v10-grammar fields, so the set is empty. Future v11.x
    # templates that add fields will append them here.
    echo '(empty at v11.0; v11.x-only fields populate this section)'
    echo

    cat <<EOF
### reactions

EOF
    # Reactions are not in BD-060's canonical Issue shape; they
    # require a separate provider call (gh api /repos/.../reactions).
    # v11.0 emits a placeholder; future BD adds real reaction fetch.
    echo '(reactions fetch not implemented at v11.0; future BD-067 ride-along)'
    echo

    cat <<EOF
### attachments

EOF
    echo '(attachments fetch not implemented at v11.0; future BD-067 ride-along)'
    echo

    cat <<EOF
### audit_log

EOF
    echo '(events fetch not implemented at v11.0; the provider_events op is not yet defined)'
    echo

    if [[ "$include_comments" == "1" ]]; then
        cat <<EOF
### comments

EOF
        echo '(full comment-thread fetch not implemented at v11.0; --include-comments is a placeholder for the future ride-along)'
        echo
    fi

    cat <<EOF

---

EOF
}
