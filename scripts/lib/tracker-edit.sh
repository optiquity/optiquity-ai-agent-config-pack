# scripts/lib/tracker-edit.sh — Mode-3 pack edit path (BD-204 §2.3).
#
# The full-CRUD "Update" verb for the tracker SSOT. When the pack is
# in tracker mode (Mode 3), an edit to a tracked entry — a `Status:`
# flip, a `Resolution:` fill, an edited `Description:`/body — is
# applied AGAINST the tracker (the SSOT), not against a flat file.
# The per-entry tree is regenerated FROM tracker state (§2.1, §2.5);
# tree files are not the edit target in Mode 3.
#
# This is the symmetric WRITE counterpart to tracker-agent-read.sh's
# READ path: both resolve pack-id → gh-id via the id-map, then call
# the provider abstraction. Read uses provider_get; edit uses
# provider_update + provider_close / provider_reopen on the open/closed
# boundary cross (DP-3 matrix, §2.6).
#
# CRUD mapping (BD-204 §2.3):
#   - Create — provider_create (forward migration Step 4/5; not here).
#   - Read   — provider_get / provider_list (tracker-agent-read.sh).
#   - Update — provider_update on body/labels (THIS file) + a
#              provider_close / provider_reopen when the new Status
#              crosses the open↔closed boundary (DP-3).
#   - Delete — NO hard-delete. The pack lifecycle resolves entries in
#              place by status flip (backlog/_rules.md); deprecation /
#              cancellation are CLOSED states, not deletions. So
#              "delete" maps to provider_close with a state_reason
#              (the Deprecated / Cancelled rows of DP-3) — there is NO
#              provider_delete op (adding one would widen the
#              abstraction with no consumer; §2.3).
#
# Tracker-agnostic: every mutation goes through a provider_* op, never
# a raw `gh` call. A Jira / Linear backend implements the same verbs
# (update / close / reopen), so this path ports unchanged.
#
# Reference: ARCHITECTURE-BD-204.md §2.3 (full CRUD), §2.6 / DP-3
# (status matrix + state_reason). Reuses the standard
# `provider_update "$gh_id" "$payload"` call shape.
#
# Bash 3.2 compatible (macOS default). Do NOT add a shebang — this
# file is sourced, not executed.

# Source siblings idempotently when this file is sourced (mirrors the
# tracker-agent-read.sh source block). `declare -f` checks are cheap.
_ted_self="${BASH_SOURCE[0]:-$0}"
_ted_dir="$(cd "$(dirname "$_ted_self")" && pwd)"

# shellcheck disable=SC1091
[[ -z "$(declare -f tracker_error_emit 2>/dev/null)" ]] && \
    source "$_ted_dir/tracker-errors.sh"
# shellcheck disable=SC1091
[[ -z "$(declare -f tracker_mode 2>/dev/null)" ]] && \
    source "$_ted_dir/tracker-config.sh"
# shellcheck disable=SC1091
[[ -z "$(declare -f provider_update 2>/dev/null)" ]] && {
    source "$_ted_dir/tracker-provider.sh"
    source "$_ted_dir/tracker-provider-gh.sh"
}
# BD-204 §3.3a (i): a body-content edit MUST regenerate BOTH the H2 sections
# AND the pack-entry-body-gz64 blob from the SAME entry object — the edit path
# is the producer that owns keeping the two views in sync. It calls the C-4.5
# blob-aware composer (`tmf_compose_issue_body`); it does NOT re-implement the
# gz64 blob or the H2 emit here. Source the forward lib idempotently so the
# composer is available.
# shellcheck disable=SC1091
[[ -z "$(declare -f tmf_compose_issue_body 2>/dev/null)" ]] && \
    source "$_ted_dir/tracker-migrate-forward.sh"
unset _ted_self _ted_dir

# ─────────────────────────────────────────────────────────────────
# DP-3 status matrix (§2.6) — the single source of open/closed +
# state_reason + status:* label for every pack-backlog Status value.
# ─────────────────────────────────────────────────────────────────

# _ted_status_openness <Status>
# Emits "open" or "closed" on stdout per the DP-3 matrix. Open states:
# Open / Unblocked / Deferred. Closed states: Resolved / Deprecated /
# Cancelled. Unknown → open (safest: an unknown state stays live and
# visible in open-work queries rather than being silently closed).
_ted_status_openness() {
    case "$1" in
        Open|Unblocked|Deferred)        echo "open" ;;
        Resolved|Deprecated|Cancelled)  echo "closed" ;;
        *)                              echo "open" ;;
    esac
}

# _ted_status_reason <Status>
# Emits the GH state_reason for a CLOSED status per DP-3:
#   Resolved → completed ; Deprecated|Cancelled → not_planned.
# Empty for open states (no reason on a reopen/open issue).
_ted_status_reason() {
    case "$1" in
        Resolved)              echo "completed" ;;
        Deprecated|Cancelled)  echo "not_planned" ;;
        *)                     echo "" ;;
    esac
}

# _ted_status_label <Status>
# Emits the status:* label for a Status value per DP-3. Mirrors the
# forward-migration label map (tracker-migrate-forward.sh
# _tmf_labels_for_entry) and adds the Deferred row (§2.6 / DP-3).
_ted_status_label() {
    case "$1" in
        Open)        echo "status:open" ;;
        Unblocked)   echo "status:unblocked" ;;
        Deferred)    echo "status:deferred" ;;
        Resolved)    echo "status:resolved" ;;
        Deprecated)  echo "status:deprecated" ;;
        Cancelled)   echo "status:cancelled" ;;
        *)           echo "status:open" ;;
    esac
}

# ─────────────────────────────────────────────────────────────────
# BD-204 Mode-3 ops contract §2 — freshness bookkeeping
# ─────────────────────────────────────────────────────────────────

# tracker_edit_stamp_last_write <cfg-path>
# Stamp [migration].last_tracker_write (ISO 8601 UTC, now) into the
# LOCAL tracker.toml. Single-home writer for the key (the
# `set_in_section` pattern shared with `_tmr_update_tracker_toml` in
# scripts/lib/tracker-migrate-reverse.sh, which owns the sibling key
# migration.last_tree_regen). Callers: `tracker_edit_entry` below
# (after its full mutation sequence succeeds) and `cmd_new_entry` in
# scripts/pack-tracker.sh (after provider_create + id-map append).
# Consumer: `tracker_doctor_run` leg (d) pack arm in
# scripts/lib/tracker-doctor.sh (stale-tree comparison against
# migration.last_tree_regen). The key lives in LOCAL gitignored state
# per ARCHITECTURE-BD-204-MODE3-OPS-CONTRACT-AMENDMENT-2.md §B3.
# No-op (rc=0) when the config file is absent.
tracker_edit_stamp_last_write() {
    local cfg="$1"
    if [[ -z "$cfg" || ! -f "$cfg" ]]; then
        return 0
    fi
    local now_iso
    now_iso=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    python3 - "$cfg" "$now_iso" <<'PYEOF'
import re, sys
cfg, now = sys.argv[1], sys.argv[2]
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

text = set_in_section(text, "migration", "last_tracker_write", now)

with open(cfg, "w") as f:
    f.write(text)
PYEOF
}

# ─────────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────────

# tracker_edit_mode [<repo-root>]
# Emits the active mode ("flat-file" or "tracker") on stdout (mirrors
# tracker_agent_read_mode). Edits are applied against the tracker only
# in tracker mode; in flat-file mode the per-entry tree is the SSOT and
# this path is a no-op (callers edit the tree directly).
tracker_edit_mode() {
    local repo_root="${1:-$(pwd)}"
    local cfg_path surface
    surface=$(tracker_config_auto_surface "$repo_root" 2>/dev/null) || surface="pack"
    cfg_path=$(tracker_config_resolve_path "$surface" "$repo_root" 2>/dev/null) || {
        echo "flat-file"
        return 0
    }
    tracker_mode "$cfg_path"
}

# tracker_edit_entry <pack-id> <patch-json> [<repo-root>]
#
# Apply an edit to a tracked entry against the tracker SSOT (Mode 3).
#
# <patch-json> describes the edit. Recognized keys (all optional):
#   description   — the entry's Description field value (drives the
#                   `## Description` H2 + rides into the recomposed blob)
#   context       — the entry's Context field value
#   resolution    — the entry's Resolution field value. A bare
#                   (trimmed, case-insensitive) `n/a` normalizes to
#                   EMPTY — the same `Resolved: n/a` unresolved-
#                   placeholder rule the forward parser applies
#                   (flush_entry in `_tmf_parse_backlog_file`,
#                   scripts/lib/tracker-migrate-forward.sh), so an
#                   explicit override and a parsed value pass through
#                   ONE normalization seam (no divergence-by-override).
#   file_symbol   — the entry's File / Symbol field value
#   raw_body      — the VERBATIM entry span (lines 2..EOF: the bold-header
#                   line + every field/prose line). When ANY of the five
#                   content keys above is present, the edit path RECOMPOSES
#                   the Issue body via the C-4.5 blob-aware composer
#                   (`tmf_compose_issue_body`), regenerating BOTH the H2
#                   sections AND the `pack-entry-body-gz64` blob from the
#                   SAME entry object atomically (§3.3a (i) / B-3). This is
#                   the producer that keeps the two body representations in
#                   sync — a tracker-side edit never updates one without the
#                   other. The composed body REPLACES any literal `body` key.
#                   PROJECTION DERIVATION + PRECEDENCE (C-8 maiden-run fix):
#                   when raw_body is present, any projection field
#                   (description / context / resolution / file_symbol)
#                   ABSENT from the patch is derived by PARSING raw_body
#                   through the REAL forward parser
#                   (`_tmf_parse_backlog_file`) — the same grammar the
#                   forward migration and the reverse divergence comparator
#                   use. An explicitly-provided patch field ALWAYS overrides
#                   the parsed value (per the cmd_edit patch contract,
#                   absent and empty are identical — empty flags never
#                   ride). The blob carries raw_body verbatim either way;
#                   only the H2 projection derivation is affected.
#                   RAW-BODY GUARDS: a parseable raw_body must contain
#                   exactly ONE entry span, and its bold-header ID must
#                   match <pack-id> — either mismatch refuses with a
#                   typed validation error BEFORE any provider op (the
#                   same single-entry + id-match gates `cmd_new_entry`
#                   in scripts/pack-tracker.sh enforces on this grammar).
#                   PROJECTION-ONLY GUARD: a patch carrying projection
#                   fields but NO raw_body, against an issue whose
#                   CURRENT body carries a `pack-entry-body-gz64` blob,
#                   is REFUSED fail-loud — recomposing from projection
#                   fields alone emits a blob-less body, and the
#                   provider_update would silently destroy the existing
#                   blob (the verbatim entry-span SSOT). Supply the full
#                   updated span via raw_body / --raw-body-file.
#                   Status / label / title-only patches (no content
#                   fields at all) never enter the recompose branch and
#                   are unaffected by both guards.
#   body          — a pre-composed Issue body (LEGACY / label-or-status-only
#                   edits). Used VERBATIM only when NO content key above is
#                   present; if a content key IS present, the recomposed body
#                   wins (so the blob+H2 sync is never bypassed).
#   title         — new title text
#   status        — the NEW pack Status value (Open / Unblocked /
#                   Deferred / Resolved / Deprecated / Cancelled).
#                   Drives BOTH a status:* label swap AND, when it
#                   crosses the open↔closed boundary, a provider_close
#                   (with the DP-3 state_reason) or provider_reopen.
#   old_status    — the PRIOR Status value, used to detect a boundary
#                   cross. When absent, the boundary cross is computed
#                   from the new status alone (close if new is closed,
#                   reopen if new is open) — idempotent on the backend.
#   add_labels    — extra labels to add (array; merged with the
#                   status:* label derived from `status`)
#   remove_labels — labels to remove (array)
#
# Mutation order (all provider_*; never raw gh):
#   1. provider_update — body / title / labels (the status:* label
#      swap rides remove_labels[old]→add_labels[new]).
#   2. provider_close / provider_reopen — ONLY when `status` crosses
#      the open↔closed boundary (DP-3). Update-only edits (a body
#      tweak, an open→open Status change like Open→Deferred) skip the
#      close/reopen entirely.
#
# Returns 1 with a typed error on missing args, flat-file mode, an
# unmapped pack-id, or a provider failure.
tracker_edit_entry() {
    local pack_id="$1"
    local patch="$2"
    local repo_root="${3:-$(pwd)}"

    if [[ -z "$pack_id" ]]; then
        tracker_error_emit "validation" "tracker_edit: pack-id required"
        return 1
    fi
    if [[ -z "$patch" ]]; then
        tracker_error_emit "validation" "tracker_edit: patch JSON required"
        return 1
    fi
    if [[ ! -d "$repo_root" ]]; then
        tracker_error_emit "validation" "tracker_edit: repo-root not a directory: $repo_root"
        return 1
    fi

    local mode
    mode=$(tracker_edit_mode "$repo_root")
    if [[ "$mode" != "tracker" ]]; then
        # Flat-file mode: the per-entry tree is the SSOT; this path
        # does not own flat-file edits. Surface a clear, non-fatal
        # signal so callers branch their own write.
        tracker_error_emit "validation" \
            "tracker_edit: not in tracker mode (mode=$mode); edit the per-entry tree directly"
        return 1
    fi

    # Resolve pack-id → gh-id via the id-map (same path as the read
    # side, tracker-agent-read.sh:_tar_read_entry_tracker).
    local mapping_file mapping gh_id cfg_path surface
    mapping_file="$repo_root/.pack-tracker/id-map.json"
    if [[ ! -f "$mapping_file" ]]; then
        tracker_error_emit "not-found" \
            "tracker_edit: tracker mode but mapping file absent at $mapping_file"
        return 1
    fi
    mapping=$(cat "$mapping_file")
    gh_id=$(printf '%s' "$mapping" | jq -r --arg k "$pack_id" \
        'if has($k) then .[$k].id else empty end')
    if [[ -z "$gh_id" || "$gh_id" == "null" ]]; then
        tracker_error_emit "not-found" \
            "tracker_edit: $pack_id not in mapping (tracker mode)"
        return 1
    fi

    surface=$(tracker_config_auto_surface "$repo_root" 2>/dev/null) || surface="pack"
    cfg_path=$(tracker_config_resolve_path "$surface" "$repo_root" 2>/dev/null) || cfg_path=""
    [[ -n "$cfg_path" ]] && export _TRACKER_PROVIDER_CONFIG_PATH="$cfg_path"

    # Parse the patch.
    local new_status old_status
    new_status=$(printf '%s' "$patch" | jq -r '.status // empty')
    old_status=$(printf '%s' "$patch" | jq -r '.old_status // empty')

    # BD-204 §3.3a (i): if the patch carries ANY entry-content field
    # (description / context / resolution / file_symbol / raw_body), RECOMPOSE
    # the Issue body via the C-4.5 blob-aware composer so BOTH the H2 sections
    # AND the pack-entry-body-gz64 blob are regenerated from the SAME entry
    # object atomically — a tracker-side edit never updates one representation
    # without the other. The composed body REPLACES any literal `body` key.
    # The composer (`tmf_compose_issue_body`) is the SINGLE real codec; no
    # gz64/H2 emit is re-implemented here. The projection-only guard below
    # enforces the never-one-without-the-other claim on the one shape that
    # could break it: content fields WITHOUT raw_body against a blob-carrying
    # issue are refused fail-loud, never recomposed-by-destruction.
    local has_content
    has_content=$(printf '%s' "$patch" | jq -r '
        if ((.description // "") != "" or (.context // "") != ""
            or (.resolution // "") != "" or (.file_symbol // "") != ""
            or (.raw_body // "") != "")
        then "1" else "" end')
    if [[ "$has_content" == "1" ]]; then
        local ed_description ed_context ed_resolution ed_file_symbol ed_raw_body
        ed_description=$(printf '%s' "$patch" | jq -r '.description // ""')
        ed_context=$(printf     '%s' "$patch" | jq -r '.context // ""')
        ed_resolution=$(printf  '%s' "$patch" | jq -r '.resolution // ""')
        ed_file_symbol=$(printf '%s' "$patch" | jq -r '.file_symbol // ""')
        # Trailing-newline-faithful raw_body extraction (jq -j + sentinel guard,
        # matching the forward BD call-site idiom) so the verbatim final newline
        # reaches the composer/encoder intact.
        ed_raw_body=$(printf '%s' "$patch" | jq -j '.raw_body // ""'; printf X)
        ed_raw_body="${ed_raw_body%X}"
        # n/a normalization symmetry: mirror the parser's resolution-only
        # bare-`n/a` placeholder rule (flush_entry in
        # `_tmf_parse_backlog_file`, scripts/lib/tracker-migrate-forward.sh)
        # on the EXPLICIT patch value too — one seam, no divergence-by-
        # override. A bare (trimmed, case-insensitive) `n/a` means NO
        # resolution (`Resolved: n/a` per backlog/_rules.md): it normalizes
        # to empty, and — when raw_body is present — derives from the parse
        # below like any other absent field (the parser applies the SAME
        # rule to the raw_body's `Resolved:` line, so the two sources agree
        # by construction). Pre-fix, an explicit literal `n/a` overrode the
        # parser-normalized EMPTY with a phantom `## Resolution` H2 — a
        # guaranteed comparator divergence even when the input textually
        # AGREED with the raw_body.
        local _ted_res_norm
        _ted_res_norm=$(printf '%s' "$ed_resolution" \
            | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
            | tr '[:upper:]' '[:lower:]')
        if [[ "$_ted_res_norm" == "n/a" ]]; then
            ed_resolution=""
        fi
        # C-8 maiden-run defect fix: when the patch carries raw_body but OMITS
        # a projection field (description / context / resolution /
        # file_symbol), derive the absent field by PARSING the raw_body
        # through the REAL forward parser (`_tmf_parse_backlog_file` in
        # scripts/lib/tracker-migrate-forward.sh — the single grammar the
        # forward migration, cmd_new_entry, and the reverse divergence
        # comparator `_tmr_check_blob_h2_divergence` all share; no field
        # extraction is re-implemented here). Pre-fix, a raw-body-only patch
        # composed EMPTY H2 projections while the blob carried the full body
        # — blob correct, H2 hollow — and every subsequent materialization
        # (correctly) failed the divergence comparator.
        #
        # PRECEDENCE: an explicitly-provided patch field ALWAYS overrides the
        # parsed value; only fields absent from the patch are parse-derived
        # (absent == empty per the cmd_edit patch contract — empty flags
        # never ride). An unparseable raw_body (no recognizable entry
        # header) derives nothing: the comparator skips the H2 check for
        # unparseable blobs (the corrupt-blob guards own that class), so
        # composing with the patch's literal fields stays
        # comparator-consistent.
        # PROJECTION-ONLY GUARD: a patch with content fields but NO raw_body
        # recomposes through the composer's empty-raw_body branch, which
        # emits NO `pack-entry-body-gz64` marker — against an issue whose
        # current body carries a blob, the provider_update below would
        # REPLACE the body and silently destroy the verbatim-span SSOT
        # (silent because both reverse comparators skip blob-less issues;
        # the raw span's Type:/Status:/Blockers:/Unblocks: lines and any
        # interior content outside the four H2 projections would be
        # unrecoverable). Read the current body and refuse fail-loud BEFORE
        # any provider write. Status/label/title-only patches never enter
        # this branch (no content field ⇒ no recompose), so they keep
        # working unchanged.
        # TODO(tracker): TD-TBD — merge-edit for projection-only patches
        # (read the current blob, splice the edited fields into raw_body,
        # recompose) is the follow-up merge-edit BD's scope; until it lands
        # this guard refuses the shape.
        if [[ -z "$ed_raw_body" ]]; then
            local _ted_cur_issue _ted_cur_body
            if ! _ted_cur_issue=$(provider_get "$gh_id" 2>/dev/null); then
                tracker_error_emit "validation" \
                    "tracker_edit: projection-only edit refused for $pack_id — cannot read the current issue body (gh-id $gh_id) to verify it carries no pack-entry-body-gz64 blob (recomposing without raw_body would destroy one); supply the FULL updated entry span via --raw-body-file, or re-run after addressing the backend failure"
                return 1
            fi
            _ted_cur_body=$(printf '%s' "$_ted_cur_issue" | jq -r '.body // ""')
            if [[ "$_ted_cur_body" == *"pack-entry-body-gz64"* ]]; then
                tracker_error_emit "validation" \
                    "tracker_edit: projection-only edit refused for $pack_id — the issue body carries a pack-entry-body-gz64 blob (the verbatim entry-span SSOT), and recomposing from projection fields alone would silently destroy it; supply the FULL updated entry span via --raw-body-file (projection-field merge-edit is the follow-up merge-edit BD's scope)"
                return 1
            fi
        fi
        if [[ -n "$ed_raw_body" ]]; then
            local _ted_tmp_raw _ted_parsed
            _ted_tmp_raw=$(mktemp -t ted-rawbody.XXXXXX) || {
                tracker_error_emit "validation" \
                    "tracker_edit: mktemp failed (raw_body projection parse)"
                return 1
            }
            printf '%s' "$ed_raw_body" > "$_ted_tmp_raw"
            _ted_parsed=$(_tmf_parse_backlog_file "$_ted_tmp_raw" 2>/dev/null)
            rm -f "$_ted_tmp_raw"
            if [[ -n "$_ted_parsed" && "$_ted_parsed" != "[]" ]]; then
                # RAW-BODY GUARDS: the SAME single-entry + id-match gates
                # `cmd_new_entry` (scripts/pack-tracker.sh) enforces on this
                # grammar. Pre-guard, a raw_body headed by a DIFFERENT entry
                # ID (or carrying several spans) rode into the blob verbatim
                # — the H2 comparator compares field VALUES, not ids, so the
                # corruption stayed invisible until the next tree
                # materialization emitted a wrong-headed entry file under
                # this pack-id's mapping.
                local _ted_n_parsed _ted_parsed_id
                _ted_n_parsed=$(printf '%s' "$_ted_parsed" | jq 'length')
                if [[ "$_ted_n_parsed" != "1" ]]; then
                    tracker_error_emit "validation" \
                        "tracker_edit: raw_body must contain exactly ONE entry span (parsed $_ted_n_parsed) — first line must be the \`**$pack_id — <Title>**\` bold header"
                    return 1
                fi
                _ted_parsed_id=$(printf '%s' "$_ted_parsed" | jq -r '.[0].pack_id // ""')
                if [[ "$_ted_parsed_id" != "$pack_id" ]]; then
                    tracker_error_emit "validation" \
                        "tracker_edit: edit target $pack_id does not match the raw_body's bold-header ID $_ted_parsed_id"
                    return 1
                fi
                if [[ -z "$ed_description" ]]; then
                    ed_description=$(printf '%s' "$_ted_parsed" | jq -r '.[0].description // ""')
                fi
                if [[ -z "$ed_context" ]]; then
                    ed_context=$(printf '%s' "$_ted_parsed" | jq -r '.[0].context // ""')
                fi
                if [[ -z "$ed_resolution" ]]; then
                    ed_resolution=$(printf '%s' "$_ted_parsed" | jq -r '.[0].resolution // ""')
                fi
                if [[ -z "$ed_file_symbol" ]]; then
                    ed_file_symbol=$(printf '%s' "$_ted_parsed" | jq -r '.[0].file_symbol // ""')
                fi
            fi
        fi
        local composed_body
        if ! composed_body=$(tmf_compose_issue_body "$pack_id" \
                "$ed_description" "$ed_context" "$ed_resolution" \
                "$ed_file_symbol" "$ed_raw_body"); then
            tracker_error_emit "validation" \
                "tracker_edit: body recompose failed for $pack_id (size-budget or storage-format; see backend message)" \
                "(no provider_update attempted — the blob+H2 sync would be incomplete)"
            return 1
        fi
        # Inject the recomposed body into the patch (overriding any literal
        # `body`), so the single payload build below carries the synced body.
        patch=$(printf '%s' "$patch" | jq --arg b "$composed_body" '.body = $b')
    fi

    # Build the provider_update payload (§2.3; the standard
    # `provider_update "$gh_id" "$payload"` call
    # shape). The status:* label swap rides add_labels / remove_labels:
    # remove the old status:* label, add the new one.
    local new_label old_label
    if [[ -n "$new_status" ]]; then
        new_label=$(_ted_status_label "$new_status")
    fi
    if [[ -n "$old_status" ]]; then
        old_label=$(_ted_status_label "$old_status")
    fi

    local payload
    payload=$(printf '%s' "$patch" | jq \
        --arg nl "${new_label:-}" \
        --arg ol "${old_label:-}" \
        '
        {}
        + (if (.title // "")  != "" then {title: .title} else {} end)
        + (if (.body  // "")  != "" then {body:  .body}  else {} end)
        + {add_labels:    ((.add_labels    // []) + (if $nl != "" then [$nl] else [] end) | unique)}
        + {remove_labels: ((.remove_labels // []) + (if ($ol != "" and $ol != $nl) then [$ol] else [] end) | unique)}
        ')

    # 1. Update — body / title / labels (tracker-agnostic provider op).
    if ! provider_update "$gh_id" "$payload" >/dev/null 2>&1; then
        tracker_error_emit "partial-write" \
            "tracker_edit: provider_update failed for $pack_id (gh-id $gh_id)" \
            "(no boundary cross attempted; re-run after addressing the backend failure)"
        return 1
    fi

    # 2. Open/closed boundary cross (DP-3). Only fires when the NEW
    # status is set AND it lands on the opposite side of the boundary
    # from the old status (or, when old_status is absent, whenever the
    # new status's side is determinable — close if closed, reopen if
    # open; idempotent on the backend).
    if [[ -n "$new_status" ]]; then
        local new_open old_open
        new_open=$(_ted_status_openness "$new_status")
        if [[ -n "$old_status" ]]; then
            old_open=$(_ted_status_openness "$old_status")
        else
            # No prior status given: treat as the inverse so any set
            # status applies its terminal state once (idempotent).
            old_open=""
        fi

        if [[ "$new_open" != "$old_open" ]]; then
            if [[ "$new_open" == "closed" ]]; then
                local reason
                reason=$(_ted_status_reason "$new_status")
                if ! provider_close "$gh_id" "$reason" >/dev/null 2>&1; then
                    tracker_error_emit "partial-write" \
                        "tracker_edit: provider_close failed for $pack_id (gh-id $gh_id, reason $reason)" \
                        "(body/label update succeeded; close failed — re-run after addressing the backend failure)"
                    return 1
                fi
            else
                if ! provider_reopen "$gh_id" >/dev/null 2>&1; then
                    tracker_error_emit "partial-write" \
                        "tracker_edit: provider_reopen failed for $pack_id (gh-id $gh_id)" \
                        "(body/label update succeeded; reopen failed — re-run after addressing the backend failure)"
                    return 1
                fi
            fi
        fi
    fi

    # BD-204 Mode-3 ops contract §2: stamp migration.last_tracker_write
    # ONLY after the FULL mutation sequence succeeded (provider_update +
    # any open↔closed boundary cross above) — a failed edit returns
    # before this line and stamps nothing. Consumer:
    # `tracker_doctor_run` leg (d) in scripts/lib/tracker-doctor.sh.
    tracker_edit_stamp_last_write "$cfg_path"

    printf '{"pack_id": "%s", "gh_id": "%s", "updated": true}\n' "$pack_id" "$gh_id"
}
