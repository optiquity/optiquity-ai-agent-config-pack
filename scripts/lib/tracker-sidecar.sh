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
#
# F10 (PACK-REVIEW-BD066-068 Finding #12): two reverse runs straddling
# UTC midnight emit two different sidecar files. To prevent disk-state
# growth, every emit removes any earlier `reverse.sidecar.YYYY-MM-DD.md`
# files in the sidecar dir before writing the current-date file. The
# user is told via stderr if a previous sidecar was removed (so they
# know it existed and can recover from a backup if they wanted it).
tracker_sidecar_emit() {
    local repo_root="$1"
    local mapping="$2"
    local include_comments="${3:-0}"

    local now_date sidecar_path sidecar_dir
    now_date=$(date -u '+%Y-%m-%d')
    sidecar_dir="$repo_root/.pack-tracker"
    sidecar_path="$sidecar_dir/reverse.sidecar.$now_date.md"
    mkdir -p "$sidecar_dir"

    # Clean up any older sidecar files (different date) before
    # writing the new one. The current-date file is preserved if it
    # already exists — it'll be overwritten by the open below.
    local older
    while IFS= read -r older; do
        [[ -z "$older" ]] && continue
        if [[ "$older" != "$sidecar_path" ]]; then
            rm -f "$older"
            echo "tracker_sidecar_emit: removed older sidecar at $older" >&2
        fi
    done < <(find "$sidecar_dir" -maxdepth 1 -name 'reverse.sidecar.*.md' 2>/dev/null)

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
    # entry not representable in v10 grammar. The content is emitted
    # by the _tmsc_extra_fields_for_entry hook so future BDs (BD-069
    # template-version reconciliation; BD-106 phase-task fields) can
    # extend the emitter without re-architecting the sidecar.
    _tmsc_extra_fields_for_entry "$pack_id" "$issue"
    echo

    cat <<EOF
### reactions

EOF
    # Extension hooks for the V1 §6.6 sub-blocks. v11.0 ships empty
    # defaults; future BDs that add provider ops (reactions via
    # `gh api /repos/.../reactions`; events via a provider_events op)
    # redefine these functions before sourcing tracker-sidecar.sh, or
    # source it then redefine — last definition wins. Mirrors the
    # _tmsc_extra_fields_for_entry pattern (PACK-REVIEW-BD062-069-071
    # Finding #8 ride-along).
    _tmsc_reactions_for_entry "$pack_id" "$issue"
    echo

    cat <<EOF
### attachments

EOF
    _tmsc_attachments_for_entry "$pack_id" "$issue"
    echo

    cat <<EOF
### audit_log

EOF
    _tmsc_audit_log_for_entry "$pack_id" "$issue"
    echo

    if [[ "$include_comments" == "1" ]]; then
        cat <<EOF
### comments

EOF
        _tmsc_comments_for_entry "$pack_id" "$issue"
        echo
    fi

    cat <<EOF

---

EOF
}

# Default extension hooks for the V1 §6.6 sidecar blocks.
#
# Contract: each hook takes <pack-id> <canonical-Issue-JSON> and
# emits one or more lines of text. v11.0 defaults emit an empty-
# state notice naming the missing provider op + the BD that will
# implement the real fetcher. Future BDs override by redefining the
# function before/after sourcing tracker-sidecar.sh — last
# definition wins.
#
# Findings #7 (extra_fields) + #8 (reactions/attachments/audit_log)
# ride-along from PACK-REVIEW-BD066-068 / PACK-REVIEW-BD062-069-071.

# _tmsc_extra_fields_for_entry <pack-id> <issue-json>
# V1 §6.6.1 extra_fields block — v11.x-only fields not in v10 grammar.
_tmsc_extra_fields_for_entry() {
    local pack_id="$1"
    local issue="$2"
    echo '(empty at v11.0; v11.x-only fields populate this section)'
}

# _tmsc_reactions_for_entry <pack-id> <issue-json>
# V1 §6.6 reactions block. Real fetch needs a separate provider call
# (gh api /repos/<slug>/issues/<n>/reactions); future BD wires it in.
_tmsc_reactions_for_entry() {
    local pack_id="$1"
    local issue="$2"
    echo '(reactions fetch not implemented at v11.0; awaiting future provider_reactions op)'
}

# _tmsc_attachments_for_entry <pack-id> <issue-json>
# V1 §6.6 attachments block. Real fetch needs a body-link extractor
# + a provider call to resolve attachment URLs.
_tmsc_attachments_for_entry() {
    local pack_id="$1"
    local issue="$2"
    echo '(attachments fetch not implemented at v11.0; awaiting future provider_attachments op)'
}

# _tmsc_audit_log_for_entry <pack-id> <issue-json>
# V1 §6.6 audit log of state changes. Real fetch needs a
# provider_events op (BD-060 did not ship one; future BD does).
_tmsc_audit_log_for_entry() {
    local pack_id="$1"
    local issue="$2"
    echo '(events fetch not implemented at v11.0; awaiting future provider_events op)'
}

# _tmsc_comments_for_entry <pack-id> <issue-json>
# V1 §6.7 comment-thread block (gated by --include-comments).
# Real fetch is `gh issue view --comments` plus body parsing.
_tmsc_comments_for_entry() {
    local pack_id="$1"
    local issue="$2"
    echo '(full comment-thread fetch not implemented at v11.0; --include-comments is a placeholder for the future provider_comments op)'
}
