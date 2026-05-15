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
#   - tracker_sidecar_compose_phase_tasks_block <parsed-tasks-json>
#       (BD-106) Compose the V3.3 §4.3 `phase_tasks` block from the
#       output of tracker_phase_task_parse. Emits a YAML-shaped block
#       on stdout with per-phase `task_order` + per-task
#       `dependency_edges[]` (kind / target / annotation) — the
#       queryable face of the human-readable Dependencies bullet
#       (V3.3 §4.3 line 201). Idempotent + side-effect-free.
#
# Reference: ARCHITECTURE.md §6.6, §6.6.1; ARCHITECTURE-V3.1-DELTA.md A2;
#            ARCHITECTURE-V3.3-DELTA.md §4.3 (sidecar phase_tasks +
#            dependency_edges).
#
# Do NOT add a shebang — this file is sourced, not executed.

# Source template-version.sh idempotently for the body-marker reader
# + archive-path composer (PACK-REVIEW-BD062-069-071 #3 unification).
# shellcheck disable=SC1091
if ! declare -f template_version_read_body >/dev/null 2>&1; then
    _tmsc_self="${BASH_SOURCE[0]}"
    _tmsc_dir="$(cd "$(dirname "$_tmsc_self")" && pwd)"
    [[ -f "$_tmsc_dir/template-version.sh" ]] && source "$_tmsc_dir/template-version.sh"
    unset _tmsc_self _tmsc_dir
fi

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

    local title template_version template_archive_path
    title=$(printf '%s' "$issue" | jq -r '.title // ""')
    # Use the shared library reader from template-version.sh (BD-069
    # + PACK-REVIEW-BD062-069-071 #3 unification): single regex for
    # the body marker across the codebase. Falls back gracefully if
    # the library hasn't been sourced (e.g. legacy callers that source
    # only tracker-sidecar.sh).
    if declare -f template_version_read_body >/dev/null 2>&1; then
        template_version=$(template_version_read_body "$issue")
    else
        template_version=$(printf '%s' "$issue" | python3 -c '
import json, re, sys
data = json.load(sys.stdin)
body = data.get("body", "") or ""
m = re.search(r"<!--\s*template_version:\s*([^\s]+)\s*-->", body)
print(m.group(1) if m else "")')
    fi

    if [[ -n "$template_version" ]]; then
        # Use the shared library helper from template-version.sh
        # (PACK-REVIEW-BD062-069-071 #3 unification).
        if declare -f template_version_archive_path >/dev/null 2>&1; then
            template_archive_path=$(template_version_archive_path "$template_version" 2>/dev/null || echo "")
        else
            local version_dir
            version_dir=$(printf '%s' "$template_version" | sed -nE 's/^.*-(v[0-9]+\.[0-9]+)$/\1/p')
            if [[ -n "$version_dir" ]]; then
                template_archive_path="maintenance-docs/v11-research/templates-archive/$version_dir/$template_version/SCHEMA.md"
            else
                template_archive_path=""
            fi
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

# ─────────────────────────────────────────────────────────────────
# BD-106 — phase_tasks block composer (V3.3 §4.3)
# ─────────────────────────────────────────────────────────────────

# tracker_sidecar_compose_phase_tasks_block <parsed-tasks-json>
#
# Input: the JSON document tracker_phase_task_parse emits.
# Output: the V3.3 §4.3 `phase_tasks` block as YAML-shaped text.
#
# Per V3.2 §4.3 (carried forward in V3.3 §4.3) the schema is:
#
#   phase_tasks:
#     phase-N:
#       task_order: [N.1, N.2, ...]
#       tasks:
#         phase-N.M:
#           title: <title>
#           parent_phase: phase-N
#           dependency_edges:
#             - kind: blocked-by
#               target: phase-X.Y
#               annotation: <free-text annotation or empty>
#             - kind: blocked-by
#               target: TD-NNN
#               annotation: ""
#           template_version: phase-task-v11.0
#           extra_fields: {}
#
# The block composes with V1 §6.6.1 / A2 — the same `template_version`
# + `extra_fields` mechanism applies. v11.0 ships empty
# `extra_fields` because no v11.x-only fields exist yet.
#
# Side-effect-free; the caller decides where to write the output
# (sidecar emit path appends it; round-trip tests inspect it inline).
tracker_sidecar_compose_phase_tasks_block() {
    local parsed_json="$1"
    if [[ -z "$parsed_json" ]]; then
        printf 'ERROR: empty input to tracker_sidecar_compose_phase_tasks_block\n' >&2
        return 1
    fi
    # JSON is passed via env var (TMSC_PARSED_JSON) instead of stdin
    # because bash heredocs replace stdin with the heredoc body —
    # a stdin pipe would be silently dropped.
    TMSC_PARSED_JSON="$parsed_json" python3 - <<'PYEOF'
import json
import os
import sys

doc = json.loads(os.environ['TMSC_PARSED_JSON'])
phases = doc.get('phases', [])

def yaml_quote(s):
    """Quote a YAML string only if it contains characters that
    would change semantics. Round-trip stability is the priority,
    not pretty-printing."""
    if s is None:
        return '""'
    needs_quote = any(c in s for c in (':', '#', '"', "'", '\n', '\t'))
    if not needs_quote and s.strip() == s and s != '':
        return s
    escaped = s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')
    return f'"{escaped}"'

out = []
out.append('phase_tasks:')
if not phases:
    out.append('  {}')
for ph in phases:
    pn = ph['phase_number']
    out.append(f'  phase-{pn}:')
    order = ph.get('task_order') or [t['task_number'] for t in ph['tasks']]
    pretty_order = ', '.join(f'{pn}.{m}' for m in order)
    out.append(f'    task_order: [{pretty_order}]')
    if not ph['tasks']:
        out.append('    tasks: {}')
        continue
    out.append('    tasks:')
    for t in ph['tasks']:
        pid = t['pack_id']
        out.append(f'      {pid}:')
        out.append(f'        title: {yaml_quote(t.get("title", ""))}')
        out.append(f'        parent_phase: phase-{pn}')
        deps = t.get('dependencies', [])
        if not isinstance(deps, list) or not deps:
            out.append('        dependency_edges: []')
        else:
            out.append('        dependency_edges:')
            for dep in deps:
                kind = dep.get('kind', 'blocked-by')
                target = dep.get('target', '')
                ann = dep.get('annotation', '') or ''
                out.append(f'          - kind: {kind}')
                out.append(f'            target: {target}')
                out.append(f'            annotation: {yaml_quote(ann)}')
        out.append('        template_version: phase-task-v11.0')
        out.append('        extra_fields: {}')

print('\n'.join(out))
PYEOF
}
