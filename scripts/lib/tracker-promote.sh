# scripts/lib/tracker-promote.sh — TD promotion orchestration (BD-107;
# V3.3 §3 D-22 + §3.2 / §3.3 / §3.4 / §3.5 + §7.3).
#
# This library is the single point of entry for the V3.3 §3 two-path TD
# promotion flow plus the "small-no-blocker direct close" wrapper.
#
# Three outcomes (V3.3 §3.1 outcome table):
#
#   1. Direct close (V3.3 §3.2)
#        verb: pack td resolve  (existing v10 lifecycle; no new entity;
#                                no `promoted-to:` label; no
#                                `derived-from:` reverse-pointer)
#        function: tracker_promote_direct_close
#
#   2. Path 1 — TD becomes a new phase epic (V3.3 §3.3)
#        verb: pack td promote --to=phase-N
#        function: tracker_promote_path1
#        Mechanics:
#          - flat-file: append `## Phase N — <title>` to
#            IMPLEMENTATION-PLAN.md sourced from the TD's content
#          - tracker mode: provider_create() phase-epic with labels:
#              phase-epic, phase-N, template:phase-epic-v11.0,
#              derived-from:TD-NNN
#          - re-key TD: status → Resolved, Resolution
#            `[YYYY-MM-DD, completed, promoted to phase-N]`
#          - tracker mode: close TD issue with state_reason=completed
#            and labels status:resolved + promoted-to:phase-N
#
#   3. Path 2 — TD becomes a new phase task (V3.3 §3.4)
#        verb: pack td promote --to=phase-N.M
#        function: tracker_promote_path2
#        Mechanics:
#          - flat-file: append `#### N.M — <title>` to phase N's
#            `### Tasks` block in IMPLEMENTATION-PLAN.md (next available
#            M; if a specific M is requested and free, use it)
#          - tracker mode: provider_create() phase-task parented to
#            phase-N epic via provider_sub_issue_create() when
#            hierarchy.supported, else link.kind="parent" + label
#            parent:phase-N. Labels: phase-task, phase-N,
#            template:phase-task-v11.0, derived-from:TD-NNN
#          - for each `Dependencies` bullet entry, call
#            tracker_links_create_blocked_by (BD-108)
#          - re-key TD: status → Resolved, Resolution
#            `[YYYY-MM-DD, completed, promoted to phase-N.M]`; close TD
#            with status:resolved + promoted-to:phase-N.M labels
#
# Reverse handlers per §3.3 / §3.4 reconstruct the source flat-file by
# reading the `derived-from:` / `promoted-to:` label pairs and the TD's
# Resolution text. Round-trip safety is the binding contract per V1
# §6.7 (whitespace-tolerant flat-file; byte-identical labels).
#
# Path 3 is FORBIDDEN per V3.3 §3 line 27 / V3.3 §1 supersession. This
# library does NOT have a `--fold-into` orchestrator, does NOT recognize
# any `folded-into:` label, and does NOT emit any inline `(from TD-NNN)`
# body marker. The release-readiness grep (BD-082 ext) verifies the
# absence at the corpus level.
#
# Public API:
#
#   - tracker_promote_path1 <td-id> <phase-N> <repo-root> [<flat-file-only>]
#       Path 1 forward orchestrator. Emits a JSON result on stdout:
#         {
#           "td_id":          "<TD-NNN>",
#           "target":         "phase-<N>",
#           "phase_title":    "<derived from TD title>",
#           "tracker_id":     "<gh-id or empty in flat-file mode>",
#           "labels_created": ["phase-epic", ..., "derived-from:TD-NNN",
#                              "promoted-to:phase-N"],
#           "mode":           "tracker|flat-file"
#         }
#
#   - tracker_promote_path2 <td-id> <phase-N.M> <repo-root> \
#                           <id-map-json> <store-path> [<flat-file-only>]
#       Path 2 forward orchestrator. Same shape JSON output plus a
#       "dependency_edges" array per Dependencies bullet entry the
#       parser found on the new task.
#
#   - tracker_promote_direct_close <td-id> [<note>]
#       Thin wrapper over the existing v10 status-flip flow. Emits the
#       JSON shape:
#         {
#           "td_id":  "<TD-NNN>",
#           "outcome": "direct-close",
#           "promotion_labels": [],
#           "new_entity": null,
#           "resolution_note": "<note or default>"
#         }
#       The wrapper exists so PM Chat has a single uniform entry point
#       across the three V3.3 §3.1 outcomes — implementation explicitly
#       creates NO promotion labels and NO new entities (V3.3 §3.2).
#
#   - tracker_promote_reverse_path1 <phase-N> <repo-root>
#       Read the `derived-from:TD-NNN` label on the phase epic and
#       reconstruct the source TD's Resolution text. Emits JSON:
#         {
#           "phase":         "phase-<N>",
#           "derived_from":  "TD-NNN",
#           "resolution":    "[YYYY-MM-DD, completed, promoted to phase-<N>]"
#         }
#
#   - tracker_promote_reverse_path2 <phase-N.M> <repo-root>
#       Symmetric to reverse_path1 but for phase tasks.
#
#   - tracker_promote_compose_phase_section <td-entry-json> <phase-N>
#       Pure formatter: returns the `## Phase N — <title>` block + the
#       phase shell (Goal / Prerequisite / ### Tasks placeholder /
#       ### Verification / ### Agent / ### Risks placeholders). Used
#       by Path 1; isolated for testability.
#
#   - tracker_promote_compose_phase_task_block <td-entry-json> <phase-N> <M>
#       Pure formatter: returns the `#### N.M — <title>` block + the
#       four METHODOLOGY § Part 4 bullets. Used by Path 2; isolated
#       for testability.
#
#   - tracker_promote_next_phase_task_M <repo-root> <phase-N>
#       Compute the next available M for phase N. Reads
#       IMPLEMENTATION-PLAN.md and returns max(existing M) + 1 (or 1
#       when the phase has no existing tasks). Pure read; no side
#       effects.
#
#   - tracker_promote_phase_task_M_in_use <repo-root> <phase-N.M>
#       Reverse of next_phase_task_M's slot logic, scoped to a single
#       requested M. rc=0 if phase-N.M already exists in the active
#       IMPLEMENTATION-PLAN.md; rc=1 if free / not in use; rc=2 if
#       input is invalid (target shape not phase-N.M, plan unreadable,
#       or parser unavailable). The rc=2 disambiguation (BD-107 review
#       F10) lets Path 2's idempotency check distinguish "M is free"
#       from "cannot tell" without ambiguity. Pure read; no side
#       effects. Total public function count: 9 (BATCH-17 review F5
#       — header undercounted as 6/8; this is the previously-omitted
#       9th entry).
#
# §6.P resolution (architect-default for Path 1) is HONOURED at the
# orchestration-policy layer by PM Chat (PM-CHAT.md TD resolution
# orchestration section); the library itself does not invoke any agent
# (libraries are orchestration primitives, not agent dispatchers).
#
# Reference:
#   - ARCHITECTURE-V3.3-DELTA.md §3.1 (outcome table)
#   - ARCHITECTURE-V3.3-DELTA.md §3.2 (direct close shape)
#   - ARCHITECTURE-V3.3-DELTA.md §3.3 (Path 1 mechanics)
#   - ARCHITECTURE-V3.3-DELTA.md §3.4 (Path 2 mechanics)
#   - ARCHITECTURE-V3.3-DELTA.md §3.5 (label family — two kinds)
#   - ARCHITECTURE-V3.3-DELTA.md §7.1 (advisory heuristic — PM Chat)
#   - ARCHITECTURE-V3.3-DELTA.md §7.2 (execution workflow — PM Chat)
#   - ARCHITECTURE-V3.3-DELTA.md §7.3 (verb shape)
#   - IMPLEMENTATION-PLAN-ADDENDUM-4.md §6.P (architect-default for
#     Path 1; option (a))
#   - METHODOLOGY.md § Part 4 (phase format: Goal / Prerequisite /
#     ### Tasks / ### Verification / ### Agent / ### Risks)
#   - METHODOLOGY.md § Part 7 (BACKLOG entry format; status state
#     machine; resolution path decision logic)
#
# Constraints:
#   - Bash 3.2 compatible (no associative arrays, no mapfile).
#   - No new provider operation; reuses provider_create / provider_link
#     / provider_close / provider_set_labels / provider_sub_issue_create.
#   - No new capability flag; honours the existing hierarchy.supported
#     branching used by tracker-migrate-forward.sh.
#   - No state-changing git verbs.
#   - No third verb form; no `--fold-into` flag.
#   - No `folded-into:` label constructor (release-readiness invariant).
#
# Do NOT add a shebang — this file is sourced, not executed.

# Source dependencies idempotently. Mirrors the pattern used in
# tracker-links.sh / tracker-cycle-check.sh.
# shellcheck disable=SC1091
if ! declare -f tracker_error_emit >/dev/null 2>&1; then
    _tpr_self="${BASH_SOURCE[0]}"
    _tpr_dir="$(cd "$(dirname "$_tpr_self")" && pwd)"
    source "$_tpr_dir/tracker-errors.sh"
    unset _tpr_self _tpr_dir
fi
# shellcheck disable=SC1091
if ! declare -f tracker_labels_derived_from >/dev/null 2>&1; then
    _tpr_self="${BASH_SOURCE[0]}"
    _tpr_dir="$(cd "$(dirname "$_tpr_self")" && pwd)"
    source "$_tpr_dir/tracker-labels.sh"
    unset _tpr_self _tpr_dir
fi
# shellcheck disable=SC1091
if ! declare -f tracker_phase_task_compose_pack_id >/dev/null 2>&1; then
    _tpr_self="${BASH_SOURCE[0]}"
    _tpr_dir="$(cd "$(dirname "$_tpr_self")" && pwd)"
    source "$_tpr_dir/tracker-phase-task.sh"
    unset _tpr_self _tpr_dir
fi
# shellcheck disable=SC1091
if ! declare -f tracker_links_create_blocked_by >/dev/null 2>&1; then
    _tpr_self="${BASH_SOURCE[0]}"
    _tpr_dir="$(cd "$(dirname "$_tpr_self")" && pwd)"
    source "$_tpr_dir/tracker-links.sh"
    unset _tpr_self _tpr_dir
fi

# ─────────────────────────────────────────────────────────────────
# Internal helpers — TD lookup + phase content composition
# ─────────────────────────────────────────────────────────────────

# _tpr_today_iso
# UTC YYYY-MM-DD per V3.3 §3.2 Resolution date convention.
_tpr_today_iso() {
    date -u '+%Y-%m-%d'
}

# _tpr_validate_td_id <td-id>
# rc=0 if shape matches `^TD-[0-9]+$`; rc=1 with typed error otherwise.
_tpr_validate_td_id() {
    local td="$1"
    if [[ -z "$td" ]]; then
        tracker_error_emit "validation" \
            "promote: TD id required (e.g. TD-031)"
        return 1
    fi
    if [[ ! "$td" =~ ^TD-[0-9]+$ ]]; then
        tracker_error_emit "validation" \
            "promote: invalid TD id shape: '$td'" \
            "(expected TD-NNN; only TDs promote per V3.3 §3 — BD promotion is not in scope at v11.0)"
        return 1
    fi
    return 0
}

# _tpr_validate_phase_target <target>
# rc=0 if matches phase-N or phase-N.M; rc=1 with typed error
# otherwise. Returns "path1" or "path2" on stdout for the caller to
# disambiguate.
_tpr_classify_target() {
    local target="$1"
    if [[ -z "$target" ]]; then
        tracker_error_emit "validation" \
            "promote: --to target required (e.g. phase-7 for Path 1, phase-7.4 for Path 2)"
        return 1
    fi
    if [[ "$target" =~ ^phase-[0-9]+$ ]]; then
        printf 'path1\n'
        return 0
    fi
    if [[ "$target" =~ ^phase-[0-9]+\.[0-9]+$ ]]; then
        printf 'path2\n'
        return 0
    fi
    tracker_error_emit "validation" \
        "promote: invalid --to target: '$target'" \
        "(expected phase-N for Path 1 or phase-N.M for Path 2; Path 3 is forbidden per V3.3 §3)"
    return 1
}

# _tpr_read_td_entry <td-id> <repo-root>
# Look up a TD by id. Emits the parsed entry JSON on stdout (the same
# shape tmf_parse_backlog produces). rc=1 with typed error if the TD is
# not present.
#
# Source resolution (BD-206 no-mirror repoint): the project per-entry
# tree under docs/project/backlog/ is the no-mirror SSOT (the
# docs/project/BACKLOG.md monolith is abolished). A client-root
# $repo_root/BACKLOG.md v10-shape entry-stream is still honored as the
# primary read (flat-file root / tracker→file read-only mirror — the
# tracker-mirror header marks it read-only); when absent, the project
# per-entry tree is enumerated into the same entries-JSON shape via
# tmf_parse_backlog_tree.
_tpr_read_td_entry() {
    local td="$1"
    local repo_root="$2"
    local backlog_path="$repo_root/BACKLOG.md"
    local project_tree="$repo_root/docs/project/backlog"

    # tmf_parse_backlog / tmf_parse_backlog_tree must be sourced by the
    # dispatcher before invoking this orchestrator. We do not source
    # them ourselves to avoid pulling in the full forward-migration
    # surface (which has its own initialization side effects via
    # tracker-mirror.sh).
    if ! declare -f tmf_parse_backlog >/dev/null 2>&1; then
        tracker_error_emit "validation" \
            "promote: tmf_parse_backlog not loaded" \
            "(source scripts/lib/tracker-migrate-forward.sh before invoking promote)"
        return 1
    fi

    local entries
    if [[ -f "$backlog_path" ]]; then
        entries=$(tmf_parse_backlog "$backlog_path") || return 1
    elif [[ -d "$project_tree" ]] && declare -f tmf_parse_backlog_tree >/dev/null 2>&1; then
        # BD-206 no-mirror: read the project per-entry tree directly.
        entries=$(tmf_parse_backlog_tree "project-backlog" "$project_tree") || return 1
    else
        tracker_error_emit "not-found" \
            "promote: no backlog source under $repo_root" \
            "(checked $repo_root/BACKLOG.md and the per-entry tree $project_tree/)"
        return 1
    fi

    local entry
    entry=$(printf '%s' "$entries" | jq -c --arg k "$td" \
        '.[] | select(.pack_id == $k)')
    if [[ -z "$entry" ]]; then
        tracker_error_emit "not-found" \
            "promote: $td not found in the backlog source" \
            "(read $repo_root/BACKLOG.md or the per-entry tree $project_tree/)"
        return 1
    fi
    printf '%s\n' "$entry"
}

# _tpr_resolve_plan_read_path <repo-root>
# Resolve a READ-ONLY implementation-plan source path. Echoes a path on
# stdout the phase-task parser can consume:
#   - the client-root $repo_root/IMPLEMENTATION-PLAN.md flat-file (or the
#     tracker→file read-only mirror) when present — KEEP; OR
#   - a temp file concatenating the project per-entry implementation-plan
#     tree (docs/project/implementation-plan/phase-N.md, back-pointers
#     stripped) when the per-entry tree exists (BD-206 no-mirror repoint
#     of the abolished docs/project/IMPLEMENTATION-PLAN.md monolith).
# Echoes nothing (rc=1) when no plan source exists. The caller owns the
# returned temp file: it is created in the system temp dir via
# `mktemp -t tpr-plan-tree.XXXXXX`, so a resumed caller cleans it
# deterministically by the tpr-plan-tree.* basename glob; tree
# concatenation is a pure read (the per-entry tree is never mutated).
_tpr_resolve_plan_read_path() {
    local repo_root="$1"
    local root_plan="$repo_root/IMPLEMENTATION-PLAN.md"
    if [[ -f "$root_plan" ]]; then
        printf '%s\n' "$root_plan"
        return 0
    fi
    local plan_tree="$repo_root/docs/project/implementation-plan"
    if [[ -d "$plan_tree" ]] \
       && declare -f pe_list_entry_files >/dev/null 2>&1 \
       && declare -f pe_strip_backpointer_stdin >/dev/null 2>&1; then
        local stream_file f
        stream_file=$(mktemp -t tpr-plan-tree.XXXXXX) || return 1
        while IFS= read -r f; do
            [[ -n "$f" ]] || continue
            pe_strip_backpointer_stdin < "$f" >> "$stream_file"
            printf '\n' >> "$stream_file"
        done < <(pe_list_entry_files "project-implementation-plan" "$plan_tree")
        printf '%s\n' "$stream_file"
        return 0
    fi
    return 1
}

# _tpr_read_backlog_entries <repo-root>
# Echo the backlog entries-JSON array (the same shape tmf_parse_backlog
# produces) for a READ-ONLY scan. Reads the client-root
# $repo_root/BACKLOG.md flat-file (or tracker→file read-only mirror) when
# present — KEEP; else enumerates the project per-entry tree
# docs/project/backlog/ via tmf_parse_backlog_tree (BD-206 no-mirror
# repoint of the abolished docs/project/BACKLOG.md monolith). Echoes `[]`
# when no source / no parser is available (the caller treats `[]` as
# "no match", preserving the prior best-effort semantics).
_tpr_read_backlog_entries() {
    local repo_root="$1"
    local root_backlog="$repo_root/BACKLOG.md"
    local project_tree="$repo_root/docs/project/backlog"
    if [[ -f "$root_backlog" ]] && declare -f tmf_parse_backlog >/dev/null 2>&1; then
        tmf_parse_backlog "$root_backlog" 2>/dev/null || printf '[]\n'
        return 0
    fi
    if [[ -d "$project_tree" ]] && declare -f tmf_parse_backlog_tree >/dev/null 2>&1; then
        tmf_parse_backlog_tree "project-backlog" "$project_tree" 2>/dev/null || printf '[]\n'
        return 0
    fi
    printf '[]\n'
}

# ─────────────────────────────────────────────────────────────────
# Public: pure formatters (Path 1 + Path 2 content composers)
# ─────────────────────────────────────────────────────────────────

# tracker_promote_compose_phase_section <td-entry-json> <phase-N>
#
# Emit the `## Phase N — <title>` skeleton populated from the TD's
# fields. Per METHODOLOGY § Part 4 the phase has Goal / Prerequisite /
# ### Tasks / ### Verification / ### Agent / ### Risks subsections.
# The architect's pass (per V3.3 §7.2 + §6.P resolution (a)) fills in
# the substantive content; this function emits a usable skeleton so
# Path 1 produces valid IMPLEMENTATION-PLAN.md content even when run
# without an architect (e.g. by automation tests, dry-run preview).
tracker_promote_compose_phase_section() {
    local td_json="$1"
    local target="$2"
    if [[ -z "$td_json" || -z "$target" ]]; then
        tracker_error_emit "validation" \
            "compose_phase_section: TD entry JSON and phase-N target required"
        return 1
    fi
    if [[ ! "$target" =~ ^phase-([0-9]+)$ ]]; then
        tracker_error_emit "validation" \
            "compose_phase_section: target must be phase-N; got '$target'"
        return 1
    fi
    local phase_n="${BASH_REMATCH[1]}"
    TPR_TD_JSON="$td_json" TPR_PHASE_N="$phase_n" python3 - <<'PYEOF'
import json
import os

td = json.loads(os.environ['TPR_TD_JSON'])
n = os.environ['TPR_PHASE_N']
title = td.get('title', '').strip() or '(title from TD)'
desc = (td.get('description', '') or '').strip()
context = (td.get('context', '') or '').strip()
file_symbol = (td.get('file_symbol', '') or '').strip()
td_id = td.get('pack_id', 'TD-???')

print(f'## Phase {n} — {title}')
print()
# F12 (BD-107 review): use a placeholder Goal sourced from the TD id
# rather than a one-line truncation of the multi-paragraph TD
# description. The full description survives in the auto-generated 9.1
# task's Problem bullet AND in the HTML-comment context block at the
# end of the section, so no information is lost. Architect refines per
# §6.P (a).
print(f'**Goal:** (derived from {td_id}; architect to refine — full TD description retained in task Problem bullet + context comment below)')
print()
print('**Prerequisite:** none stated; architect to validate against current phase state.')
print()
print('### Tasks')
print(f'#### {n}.1 — (architect to enumerate)')
print(f'- **Problem / Goal / Success**: {desc if desc else "(populate from " + td_id + " Description)"}')
if file_symbol:
    print(f'- **Files created/modified**: {file_symbol}')
else:
    print('- **Files created/modified**: (architect to enumerate)')
print('- **Definition of done**: (architect to specify)')
print('- **Dependencies**:')
print('  - (none / architect to enumerate)')
print()
print('### Verification')
print('(architect to specify)')
print()
print('### Agent')
print('(architect to assign per phase routing — METHODOLOGY § Part 4)')
print()
print('### Risks')
print('| Risk | Severity | Mitigation |')
print('| --- | --- | --- |')
print('| (architect to enumerate) | | |')
if context:
    print()
    print(f'<!-- promoted from {td_id}; original TD context follows for architect reference -->')
    print('<!--')
    for line in context.splitlines():
        print(line)
    print('-->')
PYEOF
}

# tracker_promote_compose_phase_task_block <td-entry-json> <phase-N> <M>
#
# Emit the `#### N.M — <title>` block + the four METHODOLOGY § Part 4
# bullets sourced from the TD. Used by Path 2 to drop a new task block
# into phase N's `### Tasks` zone.
#
# Dependencies bullet handling: the TD entry's blockers field is a
# list of v10 grammar tokens (TD-NNN, phase-N, phase-N.M). We emit them
# verbatim — the user can hand-edit at promotion time before Path 2's
# link orchestrator picks them up. A `BD-` blocker is NOT a valid
# phase-task dependency target (JC-1) — it is passed through to the
# flat-file but is not linked as a phase-task dependency edge. Empty
# blockers → emit "(none)" placeholder so the bullet is well-formed.
tracker_promote_compose_phase_task_block() {
    local td_json="$1"
    local phase_n="$2"
    local task_m="$3"
    if [[ -z "$td_json" || -z "$phase_n" || -z "$task_m" ]]; then
        tracker_error_emit "validation" \
            "compose_phase_task_block: TD entry JSON + phase-N + M required"
        return 1
    fi
    if [[ ! "$phase_n" =~ ^[0-9]+$ ]] || [[ ! "$task_m" =~ ^[0-9]+$ ]]; then
        tracker_error_emit "validation" \
            "compose_phase_task_block: phase_n and M must be integers"
        return 1
    fi
    TPR_TD_JSON="$td_json" TPR_PHASE_N="$phase_n" TPR_TASK_M="$task_m" python3 - <<'PYEOF'
import json
import os

td = json.loads(os.environ['TPR_TD_JSON'])
n = os.environ['TPR_PHASE_N']
m = os.environ['TPR_TASK_M']
title = td.get('title', '').strip() or '(title from TD)'
desc = (td.get('description', '') or '').strip()
file_symbol = (td.get('file_symbol', '') or '').strip()
blockers = td.get('blockers') or []
td_id = td.get('pack_id', 'TD-???')

print(f'#### {n}.{m} — {title}')
if desc:
    first_line = desc.split('\n', 1)[0]
    print(f'- **Problem / Goal / Success**: {first_line}')
    extra = desc.split('\n', 1)[1] if '\n' in desc else ''
    if extra:
        for line in extra.splitlines():
            print(line)
else:
    print(f'- **Problem / Goal / Success**: (populate from {td_id} Description)')
if file_symbol:
    print(f'- **Files created/modified**: {file_symbol}')
else:
    print('- **Files created/modified**: (populate from TD File/Symbol)')
print('- **Definition of done**: (populate from TD review)')
print('- **Dependencies**:')
if not blockers:
    print('  - (none)')
else:
    for b in blockers:
        b_clean = (b or '').strip()
        # Strip leading bullet marker if the parser passed through the
        # v10 multi-line bullet form (METHODOLOGY § Part 7 Blockers
        # field syntax). Either single-line CSV or indented `- <id>`
        # bullets are valid input.
        if b_clean.startswith('- '):
            b_clean = b_clean[2:].strip()
        elif b_clean.startswith('-'):
            b_clean = b_clean[1:].strip()
        if b_clean:
            print(f'  - {b_clean}')
PYEOF
}

# ─────────────────────────────────────────────────────────────────
# Public: phase task M-allocator
# ─────────────────────────────────────────────────────────────────

# tracker_promote_next_phase_task_M <repo-root> <phase-N>
#
# Read the implementation-plan source (the client-root flat-file or the
# project per-entry implementation-plan tree, BD-206 no-mirror — see
# _tpr_resolve_plan_read_path) and return max(existing M) + 1 for phase
# N. If phase N has no existing tasks (sparse phase), return 1.
#
# Pure read; no side effects. Used by Path 2 when the user does not
# specify a particular M (or to verify a requested M is free).
tracker_promote_next_phase_task_M() {
    local repo_root="$1"
    local target="$2"
    if [[ ! "$target" =~ ^phase-([0-9]+)$ ]]; then
        tracker_error_emit "validation" \
            "next_phase_task_M: target must be phase-N (no .M); got '$target'"
        return 1
    fi
    local phase_n="${BASH_REMATCH[1]}"

    local plan_path
    plan_path=$(_tpr_resolve_plan_read_path "$repo_root") || {
        # No plan source → fresh phase → start at 1.
        printf '1\n'
        return 0
    }

    if ! declare -f tracker_phase_task_parse >/dev/null 2>&1; then
        [[ "$plan_path" == /*/tpr-plan-tree.* ]] && rm -f "$plan_path"
        tracker_error_emit "validation" \
            "next_phase_task_M: tracker_phase_task_parse not loaded"
        return 1
    fi

    local parsed
    parsed=$(tracker_phase_task_parse "$plan_path" 2>/dev/null) || {
        # Parser failure → conservative: start at 1.
        [[ "$plan_path" == /*/tpr-plan-tree.* ]] && rm -f "$plan_path"
        printf '1\n'
        return 0
    }
    [[ "$plan_path" == /*/tpr-plan-tree.* ]] && rm -f "$plan_path"

    local max_m
    max_m=$(printf '%s' "$parsed" | jq -r --arg n "$phase_n" \
        '[.phases[] | select(.phase_number == $n) | .tasks[].task_number | tonumber] | (max // 0)')
    if [[ -z "$max_m" || "$max_m" == "null" ]]; then
        max_m=0
    fi
    printf '%s\n' "$((max_m + 1))"
}

# tracker_promote_phase_task_M_in_use <repo-root> <phase-N.M>
# rc=0 if phase-N.M already exists in the implementation-plan source.
# rc=1 if free / not in use.
# rc=2 if input is invalid (target shape not phase-N.M, plan unreadable,
#      parser unavailable). F10 (BD-107 review): disambiguates "M is
#      free" (rc=1) from "invalid input" (rc=2) so future callers don't
#      accidentally treat a malformed target as a free slot.
# Reads the client-root flat-file or the project per-entry plan tree
# (BD-206 no-mirror — see _tpr_resolve_plan_read_path).
tracker_promote_phase_task_M_in_use() {
    local repo_root="$1"
    local target="$2"
    if [[ ! "$target" =~ ^phase-([0-9]+)\.([0-9]+)$ ]]; then
        return 2
    fi
    local phase_n="${BASH_REMATCH[1]}"
    local task_m="${BASH_REMATCH[2]}"

    local plan_path
    plan_path=$(_tpr_resolve_plan_read_path "$repo_root") || return 1

    declare -f tracker_phase_task_parse >/dev/null 2>&1 || {
        [[ "$plan_path" == /*/tpr-plan-tree.* ]] && rm -f "$plan_path"
        return 2
    }
    local parsed
    parsed=$(tracker_phase_task_parse "$plan_path" 2>/dev/null) || {
        [[ "$plan_path" == /*/tpr-plan-tree.* ]] && rm -f "$plan_path"
        return 2
    }
    [[ "$plan_path" == /*/tpr-plan-tree.* ]] && rm -f "$plan_path"
    local hit
    hit=$(printf '%s' "$parsed" | jq -r --arg n "$phase_n" --arg m "$task_m" \
        '[.phases[] | select(.phase_number == $n) | .tasks[] | select(.task_number == $m)] | length')
    [[ "$hit" -gt 0 ]] && return 0 || return 1
}

# ─────────────────────────────────────────────────────────────────
# Public: Path 1 forward orchestrator
# ─────────────────────────────────────────────────────────────────

# tracker_promote_path1 <td-id> <phase-N> <repo-root> [<flat-file-only>]
#
# End-to-end Path 1 orchestrator per V3.3 §3.3.
#
# Steps:
#   1. Validate TD id + phase-N target shape (phase-N only — Path 2
#      goes through tracker_promote_path2).
#   2. Read TD entry from BACKLOG.md (parsed via tmf_parse_backlog).
#   3. Idempotency check: if IMPLEMENTATION-PLAN.md already has a
#      `## Phase N` block AND the TD already carries Resolution naming
#      phase-N, this is a re-run. Refuse with typed validation error
#      (the user should resolve the conflict explicitly — see call-out
#      5 in IMPLEMENTATION-REPORT for the rationale).
#   4. Compose the phase section + append to IMPLEMENTATION-PLAN.md.
#   5. (tracker mode) provider_create() the phase epic with labels
#      [phase-epic, phase-N, template:phase-epic-v11.0,
#       derived-from:TD-NNN].
#   6. Re-key the TD's BACKLOG entry (status → Resolved; Resolution
#      naming phase-N).
#   7. (tracker mode) close TD issue with state_reason=completed +
#      labels status:resolved + promoted-to:phase-N.
#
# flat-file-only: when "1", skip steps 5 and 7 (no provider calls).
# Default: 0 (tracker mode if id-map.json exists, flat-file otherwise).
tracker_promote_path1() {
    local td="$1"
    local target="$2"
    local repo_root="$3"
    local flat_only="${4:-0}"

    _tpr_validate_td_id "$td" || return 1
    if [[ ! "$target" =~ ^phase-([0-9]+)$ ]]; then
        tracker_error_emit "validation" \
            "promote_path1: target must be phase-N (e.g. phase-7); got '$target'" \
            "(use tracker_promote_path2 for phase-N.M targets)"
        return 1
    fi
    local phase_n="${BASH_REMATCH[1]}"
    if [[ ! -d "$repo_root" ]]; then
        tracker_error_emit "validation" \
            "promote_path1: repo-root not a directory: $repo_root"
        return 1
    fi

    local td_entry
    td_entry=$(_tpr_read_td_entry "$td" "$repo_root") || return 1

    # Idempotency / round-trip-safety check (V3.3 §3.3 round-trip
    # contract): if the TD already has a Resolution naming phase-N AND
    # the implementation-plan source already carries the phase block, the
    # promotion has already happened. Refuse with a typed error so the
    # user notices and can decide whether to undo / replay / proceed
    # with a different target. The CHECK reads the existing plan source
    # (client-root flat-file or the project per-entry plan tree, BD-206
    # no-mirror — see _tpr_resolve_plan_read_path).
    local existing_resolution
    existing_resolution=$(printf '%s' "$td_entry" | jq -r '.resolution // ""')
    local check_plan="" already_has_block=0
    if check_plan=$(_tpr_resolve_plan_read_path "$repo_root"); then
        grep -qE "^## Phase $phase_n " "$check_plan" 2>/dev/null && already_has_block=1
        [[ "$check_plan" == /*/tpr-plan-tree.* ]] && rm -f "$check_plan"
    fi
    # F2 (BD-107 review): tighten substring match to the canonical
    # Resolution emit shape `[YYYY-MM-DD, completed, promoted to phase-N]`
    # so phase-7 does not false-positive against a prior phase-72/phase-70
    # Resolution. Match on `to <target>]` (right-anchor on the closing
    # bracket of the canonical Resolution token).
    if [[ "$existing_resolution" == *"to $target]"* ]] && [[ "$already_has_block" == "1" ]]; then
        tracker_error_emit "validation" \
            "promote_path1: $td already promoted to $target; refusing duplicate run" \
            "(BACKLOG entry has Resolution naming $target and the implementation-plan already carries ## Phase $phase_n)" \
            "→ Run: pack tracker doctor to inspect; or choose a different --to target"
        return 1
    fi

    local td_title
    td_title=$(printf '%s' "$td_entry" | jq -r '.title')

    # Step 4: append phase block to the implementation-plan flat-file.
    # BD-206 no-mirror: the abolished docs/project/IMPLEMENTATION-PLAN.md
    # monolith is never written; the dormant flat-file append targets the
    # client-root IMPLEMENTATION-PLAN.md. (The project per-entry tree EMIT
    # — writing one phase-N.md per phase — is BD-207's client-tree
    # materialization, gated OFF per BD-214, NOT activated here.)
    # F9 (BD-107 review): snapshot the pre-write plan so a downstream
    # tracker-mode failure can roll back the file mutation. The
    # snapshot is removed on success at the end of the function. If a
    # caller crashes between write + restore the snapshot remains as a
    # diagnostic artifact (intentional — visibility wins).
    local plan_path="$repo_root/IMPLEMENTATION-PLAN.md"
    if [[ ! -f "$plan_path" ]]; then
        printf '# Implementation Plan\n\n' > "$plan_path"
    fi
    local plan_snapshot=""
    if [[ -f "$plan_path" ]]; then
        plan_snapshot="$plan_path.pre-bd107"
        cp "$plan_path" "$plan_snapshot"
    fi
    local section
    if ! section=$(tracker_promote_compose_phase_section "$td_entry" "$target"); then
        [[ -n "$plan_snapshot" && -f "$plan_snapshot" ]] && rm -f "$plan_snapshot"
        return 1
    fi
    {
        printf '\n'
        printf '%s\n' "$section"
    } >> "$plan_path"

    # Step 6: re-key TD entry in BACKLOG (status → Resolved; Resolution
    # naming phase-N). The actual write back to BACKLOG.md is
    # delegated to PM Chat per the workflow rule (PM Chat owns
    # BACKLOG.md mutations; library returns the patch shape so PM Chat
    # can apply it). This avoids embedding string-based BACKLOG editor
    # logic here — that's the v10 lifecycle's province.
    local today
    today=$(_tpr_today_iso)
    local resolution_text="[$today, completed, promoted to $target]"

    # Step 5 + 7: tracker-mode side-effects. Detect tracker mode by
    # presence of .pack-tracker/id-map.json (the same signal
    # tracker-config uses). flat_only=1 forces flat-file regardless.
    local mode="flat-file"
    local tracker_id=""
    local labels_created="[\"phase-epic\", \"phase-$phase_n\", \"template:phase-epic-v11.0\", \"derived-from:$td\"]"
    local promoted_label
    promoted_label=$(tracker_labels_promoted_to "$target") || return 1
    local derived_label
    derived_label=$(tracker_labels_derived_from "$td") || return 1

    if [[ "$flat_only" != "1" ]] && [[ -f "$repo_root/.pack-tracker/id-map.json" ]]; then
        mode="tracker"
        # BD-129 retro-fix F2: ensure `GH_REPO` is exported from the
        # active tracker.toml's `backend.repo` before invoking
        # `_tracker_labels_create`. The labels helper bypasses
        # `_gh_run` (it shells `gh label create` directly), so the
        # `_gh_run`-internal helper call from BD-129 does NOT cover
        # this code path; without this defense, `pack td promote`
        # against a working copy with no GitHub remote would still
        # fail at the labels-pre-create step with the misleading
        # `none of the git remotes ...` error BD-129 was meant to
        # eliminate. The dispatcher (scripts/pack-td.sh::cmd_promote)
        # exports `_TRACKER_PROVIDER_CONFIG_PATH` so this helper has
        # the backend.repo source it needs. Helper is a no-op when
        # `GH_REPO` is already set or the env var is unset.
        if declare -f tracker_gh_repo_setup >/dev/null 2>&1; then
            tracker_gh_repo_setup
        fi
        # F3 (BD-107 review): pre-create the dynamic per-entity labels on
        # the GH repo before provider_create / provider_set_labels emits
        # them. modern `gh` rejects unknown labels at issue create/edit;
        # the canonical label set (tracker_labels_canonical_set) does
        # not include these per-entity labels by design (they're
        # per-promotion). _tracker_labels_create is idempotent
        # (--force).
        if declare -f _tracker_labels_create >/dev/null 2>&1; then
            if ! _tracker_labels_create "$derived_label"; then
                [[ -n "$plan_snapshot" && -f "$plan_snapshot" ]] && \
                    mv "$plan_snapshot" "$plan_path"
                tracker_error_emit "partial-write" \
                    "promote_path1: failed to ensure label '$derived_label' on tracker repo (Path 1 step 5 prerequisite)" \
                    "(plan-file mutation rolled back; re-run after addressing the gh label create failure)"
                return 1
            fi
            if ! _tracker_labels_create "$promoted_label"; then
                [[ -n "$plan_snapshot" && -f "$plan_snapshot" ]] && \
                    mv "$plan_snapshot" "$plan_path"
                tracker_error_emit "partial-write" \
                    "promote_path1: failed to ensure label '$promoted_label' on tracker repo (Path 1 step 7 prerequisite)" \
                    "(plan-file mutation rolled back; re-run after addressing the gh label create failure)"
                return 1
            fi
        fi
        # Compose payload + invoke provider_create.
        local body payload result
        body="<!-- pack-id: $target -->
<!-- template_version: phase-epic-v11.0 -->
<!-- pack-version: v11 -->

## Description

Phase epic derived from $td. See IMPLEMENTATION-PLAN.md ## Phase $phase_n for the substantive content."
        # F6 (BD-107 review): use --arg for $phase_n to align with the
        # rest of the file's jq-arg discipline (no shell-interpolation
        # inside the jq filter).
        payload=$(jq -n \
            --arg t "Phase $phase_n — $td_title" \
            --arg b "$body" \
            --arg dl "$derived_label" \
            --arg pn "$phase_n" \
            '{title: $t, body: $b, labels: ["phase-epic", "phase-\($pn)", "template:phase-epic-v11.0", $dl]}')
        # F9 (BD-107 review): on provider_create failure, roll back the
        # plan-file mutation to keep the user out of a partial state.
        if ! result=$(provider_create "$payload"); then
            [[ -n "$plan_snapshot" && -f "$plan_snapshot" ]] && \
                mv "$plan_snapshot" "$plan_path"
            tracker_error_emit "partial-write" \
                "promote_path1: provider_create failed for $target phase epic" \
                "(plan-file mutation rolled back; re-run after addressing the backend failure)"
            return 1
        fi
        tracker_id=$(printf '%s' "$result" | jq -r '.id')

        # BATCH-17 F3 (cross-BD review): persist the new phase-epic
        # mapping to disk so subsequent `pack td promote` / `pack
        # tracker doctor` invocations see it. Mirrors the
        # tracker-migrate-forward.sh:818 pattern (save after every
        # tmf_mapping_set). Without this, the on-disk id-map.json is
        # stale after Path 1 forward and follow-up tooling cannot
        # resolve the new phase-N entity.
        if declare -f tmf_mapping_load >/dev/null 2>&1; then
            local _f3_mapping
            _f3_mapping=$(tmf_mapping_load "$repo_root/.pack-tracker/id-map.json")
            local _f3_url
            _f3_url=$(printf '%s' "$result" | jq -r '.url // ""')
            _f3_mapping=$(tmf_mapping_set "$_f3_mapping" "$target" "$tracker_id" "$_f3_url")
            tmf_mapping_save "$repo_root/.pack-tracker/id-map.json" "$_f3_mapping"
        fi

        # Look up the TD's tracker id; close it with promoted-to label.
        # F3 (BD-107 review): surface backend failures as typed
        # partial-write errors instead of silently swallowing them via
        # `|| true`. The plan-file mutation has already happened, so we
        # do NOT roll back here (the new phase-epic was successfully
        # created; only the TD-side close failed). The user gets a
        # typed diagnostic to address the close-side failure.
        local td_gh_id
        if declare -f tmf_mapping_load >/dev/null 2>&1; then
            local mapping
            mapping=$(tmf_mapping_load "$repo_root/.pack-tracker/id-map.json")
            td_gh_id=$(tmf_mapping_get "$mapping" "$td" 2>/dev/null || echo "")
            if [[ -n "$td_gh_id" ]]; then
                if ! provider_set_labels "$td_gh_id" \
                    "[\"status:resolved\", \"$promoted_label\"]" >/dev/null 2>&1; then
                    tracker_error_emit "partial-write" \
                        "promote_path1: provider_set_labels failed for TD $td (gh-id $td_gh_id)" \
                        "(phase epic was created successfully; TD-side label update failed — re-run after addressing the backend failure)"
                    return 1
                fi
                if ! provider_close "$td_gh_id" "completed" >/dev/null 2>&1; then
                    tracker_error_emit "partial-write" \
                        "promote_path1: provider_close failed for TD $td (gh-id $td_gh_id)" \
                        "(phase epic + TD label update succeeded; TD close failed — re-run after addressing the backend failure)"
                    return 1
                fi

                # BATCH-17 F2 (cross-BD review): write the Resolution
                # text to the TD issue body's `## Resolution` section so
                # `pack tracker disable` reverse migration can recover it
                # via `_tmr_extract_section "Resolution"`. Without this
                # update, the V3.3 §3.3 round-trip carrier ("BACKLOG
                # entry's Resolution text — human-readable") is lost on
                # reverse: the `promoted-to:phase-N` label survives but
                # the human-readable timestamp + path text does not.
                # We re-compose the full body using the existing TD
                # entry's fields plus the new resolution_text and
                # provider_update with the merged shape. tmf_compose_
                # issue_body already orders Description / File-Symbol /
                # Context / Resolution per the v10 lifecycle convention.
                local _f2_description _f2_context _f2_file_symbol _f2_body _f2_payload
                _f2_description=$(printf '%s' "$td_entry" | jq -r '.description // ""')
                _f2_context=$(printf     '%s' "$td_entry" | jq -r '.context // ""')
                _f2_file_symbol=$(printf '%s' "$td_entry" | jq -r '.file_symbol // ""')
                if declare -f tmf_compose_issue_body >/dev/null 2>&1; then
                    _f2_body=$(tmf_compose_issue_body \
                        "$td" "$_f2_description" "$_f2_context" \
                        "$resolution_text" "$_f2_file_symbol")
                    _f2_payload=$(jq -n --arg b "$_f2_body" '{body: $b}')
                    if ! provider_update "$td_gh_id" "$_f2_payload" >/dev/null 2>&1; then
                        tracker_error_emit "partial-write" \
                            "promote_path1: provider_update failed for TD $td body Resolution sync (gh-id $td_gh_id)" \
                            "(phase epic + TD close succeeded; Resolution body sync failed — reverse migration will not recover human-readable Resolution; re-run after addressing the backend failure)"
                        return 1
                    fi
                fi
            fi
        fi
    fi
    # F9 (BD-107 review): success path — clean up the plan snapshot.
    [[ -n "$plan_snapshot" && -f "$plan_snapshot" ]] && rm -f "$plan_snapshot"

    jq -n \
        --arg td "$td" \
        --arg tg "$target" \
        --arg pt "$td_title" \
        --arg ti "$tracker_id" \
        --argjson lc "$labels_created" \
        --arg pl "$promoted_label" \
        --arg mo "$mode" \
        --arg rt "$resolution_text" \
        '{
            td_id:           $td,
            target:          $tg,
            phase_title:     $pt,
            tracker_id:      $ti,
            labels_created:  $lc,
            promoted_to:     $pl,
            mode:            $mo,
            resolution_text: $rt
         }'
    return 0
}

# ─────────────────────────────────────────────────────────────────
# Public: Path 2 forward orchestrator
# ─────────────────────────────────────────────────────────────────

# tracker_promote_path2 <td-id> <phase-N.M> <repo-root> \
#                       [<id-map-json>] [<store-path>] [<flat-file-only>]
#
# End-to-end Path 2 orchestrator per V3.3 §3.4.
#
# Steps (mirror Path 1 with phase-task differences):
#   1. Validate TD + phase-N.M shape; classify_target → must return path2.
#   2. Read TD entry.
#   3. Resolve M: if requested M is in use → typed error (idempotency
#      decision per call-out 6); if requested M is free → use it; if no
#      M was requested (caller passed phase-N.M with explicit M anyway,
#      so this branch is not exercised by the verb dispatcher) → use
#      the supplied M.
#   4. Compose `#### N.M — <title>` block + append to phase N's
#      `### Tasks` zone in IMPLEMENTATION-PLAN.md.
#   5. (tracker mode) provider_create() phase task; parent to phase-N
#      epic via provider_sub_issue_create (when hierarchy.supported)
#      or link.kind="parent" (otherwise).
#   6. (tracker mode) For each Dependencies bullet entry on the new
#      task, call tracker_links_create_blocked_by (BD-108 wires the
#      dependency edge per V3.3 §5.1).
#   7. Re-key TD (status → Resolved; Resolution naming phase-N.M);
#      close TD issue with status:resolved + promoted-to:phase-N.M.
tracker_promote_path2() {
    local td="$1"
    local target="$2"
    local repo_root="$3"
    local id_map="${4:-}"
    local store_path="${5:-}"
    local flat_only="${6:-0}"

    _tpr_validate_td_id "$td" || return 1
    if [[ ! "$target" =~ ^phase-([0-9]+)\.([0-9]+)$ ]]; then
        tracker_error_emit "validation" \
            "promote_path2: target must be phase-N.M (e.g. phase-7.4); got '$target'" \
            "(use tracker_promote_path1 for phase-N targets)"
        return 1
    fi
    local phase_n="${BASH_REMATCH[1]}"
    local task_m="${BASH_REMATCH[2]}"
    if [[ ! -d "$repo_root" ]]; then
        tracker_error_emit "validation" \
            "promote_path2: repo-root not a directory: $repo_root"
        return 1
    fi

    local td_entry
    td_entry=$(_tpr_read_td_entry "$td" "$repo_root") || return 1

    # Idempotency: if phase-N.M already exists in the plan, refuse.
    # F10 (BD-107 review): rc=0 → in use, rc=1 → free, rc=2 → invalid
    # input. We pre-validated target shape above (line 715), so rc=2 is
    # only reachable when the parser is missing — surface as validation
    # error so the user sees the diagnostic rather than silently
    # treating an unparseable plan as "free". The `|| m_rc=$?` suffix
    # protects callers that source this lib under `set -e` (rc=1 is
    # the common "free" case).
    local m_rc=0
    tracker_promote_phase_task_M_in_use "$repo_root" "$target" || m_rc=$?
    if [[ $m_rc -eq 0 ]]; then
        tracker_error_emit "validation" \
            "promote_path2: $target already exists in IMPLEMENTATION-PLAN.md; refusing to overwrite" \
            "(call-out 6: requested M is in use — pick a different M or run tracker_promote_next_phase_task_M for the next free slot)"
        return 1
    elif [[ $m_rc -eq 2 ]]; then
        tracker_error_emit "validation" \
            "promote_path2: cannot inspect IMPLEMENTATION-PLAN.md for $target (invalid input or parser missing)" \
            "(re-source scripts/lib/tracker-phase-task.sh and re-run; or run pack tracker doctor)"
        return 1
    fi

    local td_title
    td_title=$(printf '%s' "$td_entry" | jq -r '.title')

    # Step 4: append task block to phase N's ### Tasks zone in the
    # implementation-plan flat-file. We do this via a python rewriter to
    # locate the correct insertion point (within phase N's ### Tasks
    # block; preserving any subsequent ### Verification / ### Agent /
    # ### Risks subsections).
    # BD-206 no-mirror: the abolished docs/project/IMPLEMENTATION-PLAN.md
    # monolith is never written; the dormant in-place rewrite targets the
    # client-root IMPLEMENTATION-PLAN.md flat-file. (The project per-entry
    # tree EMIT — rewriting the phase's phase-N.md per-entry file — is
    # BD-207's client-tree materialization, gated OFF per BD-214.)
    local plan_path="$repo_root/IMPLEMENTATION-PLAN.md"
    if [[ ! -f "$plan_path" ]]; then
        tracker_error_emit "not-found" \
            "promote_path2: IMPLEMENTATION-PLAN.md not found at $plan_path" \
            "(use Path 1 to create a new phase first, then promote into it)"
        return 1
    fi
    local task_block
    task_block=$(tracker_promote_compose_phase_task_block "$td_entry" "$phase_n" "$task_m") || return 1

    # F9 (BD-107 review): snapshot the pre-write plan so a downstream
    # tracker-mode failure can roll back the file mutation.
    local plan_snapshot=""
    if [[ -f "$plan_path" ]]; then
        plan_snapshot="$plan_path.pre-bd107"
        cp "$plan_path" "$plan_snapshot"
    fi

    # In-place rewrite via tempfile + atomic replace.
    local tmp_plan
    tmp_plan=$(mktemp -t tpr-plan.XXXXXX)
    TPR_PLAN_PATH="$plan_path" \
    TPR_TASK_BLOCK="$task_block" \
    TPR_PHASE_N="$phase_n" \
    python3 - > "$tmp_plan" <<'PYEOF'
import os
import re

plan_path = os.environ['TPR_PLAN_PATH']
task_block = os.environ['TPR_TASK_BLOCK']
n = os.environ['TPR_PHASE_N']

with open(plan_path) as f:
    text = f.read()

PHASE_RE = re.compile(rf'^## Phase {re.escape(n)}\b', re.MULTILINE)
match = PHASE_RE.search(text)
if not match:
    # Phase doesn't exist — emit unchanged (caller surfaces error
    # below by post-check).
    print(text, end='')
    raise SystemExit(0)

# Find the phase's range: from `## Phase n` to the next `## ` heading
# at column 0 (or EOF).
phase_start = match.start()
NEXT_H2 = re.compile(r'^## ', re.MULTILINE)
next_match = NEXT_H2.search(text, phase_start + 1)
phase_end = next_match.start() if next_match else len(text)
phase_block = text[phase_start:phase_end]

# Inside the phase block, find ### Tasks; if absent, create it.
TASKS_RE = re.compile(r'^### Tasks\s*$', re.MULTILINE)
tm = TASKS_RE.search(phase_block)
if not tm:
    # Sparse phase — append ### Tasks + the new task at end of phase.
    insertion_marker = '\n### Tasks\n' + task_block + '\n'
    new_block = phase_block.rstrip() + insertion_marker
    new_text = text[:phase_start] + new_block + text[phase_end:]
    print(new_text, end='')
    raise SystemExit(0)

# Find end of Tasks zone within phase_block: the next `### ` heading
# at column 0 (or end of phase block).
NEXT_H3 = re.compile(r'^### ', re.MULTILINE)
tasks_zone_start = tm.end()
nm = NEXT_H3.search(phase_block, tasks_zone_start + 1)
tasks_zone_end = nm.start() if nm else len(phase_block)

# Insert the new task block at the end of the tasks zone (before the
# next ### subsection).
prefix = phase_block[:tasks_zone_end].rstrip('\n') + '\n\n'
suffix = phase_block[tasks_zone_end:]
new_phase_block = prefix + task_block + '\n' + suffix
new_text = text[:phase_start] + new_phase_block + text[phase_end:]
print(new_text, end='')
PYEOF
    mv "$tmp_plan" "$plan_path"

    # Step 5+6+7: tracker-mode side-effects.
    local today
    today=$(_tpr_today_iso)
    local resolution_text="[$today, completed, promoted to $target]"
    local mode="flat-file"
    local tracker_id=""
    local promoted_label
    promoted_label=$(tracker_labels_promoted_to "$target") || return 1
    local derived_label
    derived_label=$(tracker_labels_derived_from "$td") || return 1
    local labels_created="[\"phase-task\", \"phase-$phase_n\", \"template:phase-task-v11.0\", \"derived-from:$td\"]"
    local dependency_edges="[]"

    if [[ "$flat_only" != "1" ]] && [[ -f "$repo_root/.pack-tracker/id-map.json" ]]; then
        mode="tracker"
        # BD-129 retro-fix F2: ensure `GH_REPO` is exported from the
        # active tracker.toml's `backend.repo` before invoking
        # `_tracker_labels_create`. See the matching block in
        # `tracker_promote_path1` above for the full rationale.
        # Helper is a no-op when `GH_REPO` is already set or the
        # `_TRACKER_PROVIDER_CONFIG_PATH` env var is unset.
        if declare -f tracker_gh_repo_setup >/dev/null 2>&1; then
            tracker_gh_repo_setup
        fi
        # F3 (BD-107 review): pre-create the dynamic per-entity labels on
        # the GH repo before provider_create / provider_set_labels emits
        # them. modern `gh` rejects unknown labels at issue create/edit;
        # the canonical label set (tracker_labels_canonical_set) does
        # not include these per-entity labels by design (they're
        # per-promotion). _tracker_labels_create is idempotent (--force).
        if declare -f _tracker_labels_create >/dev/null 2>&1; then
            if ! _tracker_labels_create "$derived_label"; then
                [[ -n "$plan_snapshot" && -f "$plan_snapshot" ]] && \
                    mv "$plan_snapshot" "$plan_path"
                tracker_error_emit "partial-write" \
                    "promote_path2: failed to ensure label '$derived_label' on tracker repo (Path 2 step 5 prerequisite)" \
                    "(plan-file mutation rolled back; re-run after addressing the gh label create failure)"
                return 1
            fi
            if ! _tracker_labels_create "$promoted_label"; then
                [[ -n "$plan_snapshot" && -f "$plan_snapshot" ]] && \
                    mv "$plan_snapshot" "$plan_path"
                tracker_error_emit "partial-write" \
                    "promote_path2: failed to ensure label '$promoted_label' on tracker repo (Path 2 step 7 prerequisite)" \
                    "(plan-file mutation rolled back; re-run after addressing the gh label create failure)"
                return 1
            fi
        fi
        local body payload result
        body="<!-- pack-id: $target -->
<!-- template_version: phase-task-v11.0 -->
<!-- pack-version: v11 -->

## Description

Phase task derived from $td. See IMPLEMENTATION-PLAN.md ## Phase $phase_n / #### $phase_n.$task_m for the substantive content."
        # F6 (BD-107 review): use --arg for $phase_n to align with the
        # rest of the file's jq-arg discipline (no shell-interpolation
        # inside the jq filter).
        payload=$(jq -n \
            --arg t "Phase $phase_n.$task_m — $td_title" \
            --arg b "$body" \
            --arg dl "$derived_label" \
            --arg pn "$phase_n" \
            '{title: $t, body: $b, labels: ["phase-task", "phase-\($pn)", "template:phase-task-v11.0", $dl]}')
        # F9 (BD-107 review): on provider_create failure, roll back the
        # plan-file mutation to keep the user out of a partial state.
        if ! result=$(provider_create "$payload"); then
            [[ -n "$plan_snapshot" && -f "$plan_snapshot" ]] && \
                mv "$plan_snapshot" "$plan_path"
            tracker_error_emit "partial-write" \
                "promote_path2: provider_create failed for $target phase task" \
                "(plan-file mutation rolled back; re-run after addressing the backend failure)"
            return 1
        fi
        tracker_id=$(printf '%s' "$result" | jq -r '.id')

        # Parent to phase-N epic. Try sub_issue_create first; fall back
        # to link.kind=parent + label parent:phase-N for low-capability
        # backends. The capability check happens at the dispatcher
        # level (provider_capabilities); we keep a minimal sub_issue
        # attempt with a graceful fallback.
        local mapping
        if declare -f tmf_mapping_load >/dev/null 2>&1; then
            mapping=$(tmf_mapping_load "$repo_root/.pack-tracker/id-map.json")
            local phase_gh_id
            phase_gh_id=$(tmf_mapping_get "$mapping" "phase-$phase_n" 2>/dev/null || echo "")
            if [[ -n "$phase_gh_id" ]]; then
                if ! provider_sub_issue_create "$phase_gh_id" \
                    "{\"existing_id\": \"$tracker_id\"}" >/dev/null 2>&1; then
                    # Fall back to link + parent label.
                    provider_link "$tracker_id" "$phase_gh_id" "parent" >/dev/null 2>&1 || true
                fi
            fi
        fi

        # Step 6: dependency edges. For each Dependencies bullet entry
        # on the new task, call tracker_links_create_blocked_by. The
        # entries are on the TD entry's blockers field (we copy them
        # verbatim into the new task's Dependencies bullet) — that's
        # the source we walk here.
        if [[ -n "$id_map" ]] && [[ -n "$store_path" ]]; then
            # The new phase task was just created via provider_create
            # but its pack-id (phase-N.M) is not yet in the id-map JSON
            # the caller passed. Add it in-memory so
            # tracker_links_create_blocked_by can resolve it.
            local task_url
            task_url=$(printf '%s' "$result" | jq -r '.url // ""')
            id_map=$(printf '%s' "$id_map" | jq --arg k "$target" \
                --arg id "$tracker_id" --arg url "$task_url" \
                '. + {($k): {id: $id, url: $url}}')

            # BATCH-17 F3 (cross-BD review): persist the new phase-task
            # mapping to disk so subsequent `pack td promote` / `pack
            # tracker doctor` invocations see it. Mirrors the
            # tracker-migrate-forward.sh:818 pattern (save after every
            # tmf_mapping_set). Without this, the on-disk id-map.json
            # is stale after Path 2 forward and a follow-up promote
            # citing this phase-N.M as a Dependencies target will hit
            # the link-orchestrator's "not in id-map" typed error.
            if declare -f tmf_mapping_save >/dev/null 2>&1 \
                && declare -f tmf_mapping_load >/dev/null 2>&1 \
                && declare -f tmf_mapping_set  >/dev/null 2>&1; then
                local _f3_disk_mapping
                _f3_disk_mapping=$(tmf_mapping_load "$repo_root/.pack-tracker/id-map.json")
                _f3_disk_mapping=$(tmf_mapping_set "$_f3_disk_mapping" \
                    "$target" "$tracker_id" "$task_url")
                tmf_mapping_save "$repo_root/.pack-tracker/id-map.json" \
                    "$_f3_disk_mapping"
            fi

            local edges_arr="[]"
            local b_count b_idx=0 b_raw
            local blockers
            blockers=$(printf '%s' "$td_entry" | jq -c '.blockers // []')
            b_count=$(printf '%s' "$blockers" | jq 'length')
            while [[ $b_idx -lt $b_count ]]; do
                b_raw=$(printf '%s' "$blockers" | jq -r ".[$b_idx]")
                # tmf_parse_backlog leaves the v10 bullet-form leading
                # `- ` intact when the Blockers field uses the indented
                # multi-line shape (METHODOLOGY § Part 7 BACKLOG item
                # format). Strip it before pack-id matching so both
                # shapes route uniformly.
                b_raw="${b_raw#- }"
                b_raw="${b_raw#-}"
                # Trim trailing free-text annotation (V3.3 §5.3) so the
                # case-match below sees the bare pack-id.
                b_raw_id="${b_raw%% *}"
                # F8 (BD-107 review): use the canonical V3.3 §5.3 regex
                # rather than a permissive case-glob. This rejects
                # well-formed-but-not-quite tokens (e.g. TD-029X) at the
                # dispatcher seam, so they never reach the stricter
                # link-orchestrator. Only call
                # tracker_links_create_blocked_by for the valid
                # phase-task dependency-target shapes (phase-N,
                # phase-N.M, TD-NNN). `BD-` is NOT a valid phase-task
                # dependency target (JC-1): a `BD-` blocker on a
                # promoted TD is passed through to the flat-file but is
                # NOT linked as a phase-task dependency edge. Other
                # tokens (free-text blockers) are likewise passed through
                # but skipped at the link-orchestrator (they'll be
                # warnings on the next forward migration).
                if [[ "$b_raw_id" =~ ^(phase-[0-9]+(\.[0-9]+)?|TD-[0-9]+)$ ]]; then
                    local edge_out
                    if edge_out=$(tracker_links_create_blocked_by \
                        "$target" "$b_raw_id" "$id_map" "$store_path" "" 2>/dev/null); then
                        edges_arr=$(printf '%s' "$edges_arr" | \
                            jq --argjson e "$edge_out" '. + [$e]')
                    fi
                fi
                b_idx=$((b_idx + 1))
            done
            dependency_edges="$edges_arr"
        fi

        # Step 7: close TD with promoted-to label.
        # F3 (BD-107 review): surface backend failures as typed
        # partial-write errors instead of silently swallowing them via
        # `|| true`. The plan-file mutation has already happened, so we
        # do NOT roll back here (the new phase-task was successfully
        # created; only the TD-side close failed). The user gets a
        # typed diagnostic to address the close-side failure.
        local td_gh_id
        td_gh_id=$(tmf_mapping_get "$mapping" "$td" 2>/dev/null || echo "")
        if [[ -n "$td_gh_id" ]]; then
            if ! provider_set_labels "$td_gh_id" \
                "[\"status:resolved\", \"$promoted_label\"]" >/dev/null 2>&1; then
                tracker_error_emit "partial-write" \
                    "promote_path2: provider_set_labels failed for TD $td (gh-id $td_gh_id)" \
                    "(phase task was created successfully; TD-side label update failed — re-run after addressing the backend failure)"
                return 1
            fi
            if ! provider_close "$td_gh_id" "completed" >/dev/null 2>&1; then
                tracker_error_emit "partial-write" \
                    "promote_path2: provider_close failed for TD $td (gh-id $td_gh_id)" \
                    "(phase task + TD label update succeeded; TD close failed — re-run after addressing the backend failure)"
                return 1
            fi

            # BATCH-17 F2 (cross-BD review): write the Resolution text
            # to the TD issue body's `## Resolution` section so `pack
            # tracker disable` reverse migration recovers the human-
            # readable timestamp + path text via _tmr_extract_section
            # "Resolution". Symmetric to the Path 1 fix above. Without
            # this update, the V3.3 §3.3 round-trip carrier is reduced
            # to one (the `promoted-to:phase-N.M` label survives but
            # the human-readable Resolution text is lost on reverse).
            local _f2_description _f2_context _f2_file_symbol _f2_body _f2_payload
            _f2_description=$(printf '%s' "$td_entry" | jq -r '.description // ""')
            _f2_context=$(printf     '%s' "$td_entry" | jq -r '.context // ""')
            _f2_file_symbol=$(printf '%s' "$td_entry" | jq -r '.file_symbol // ""')
            if declare -f tmf_compose_issue_body >/dev/null 2>&1; then
                _f2_body=$(tmf_compose_issue_body \
                    "$td" "$_f2_description" "$_f2_context" \
                    "$resolution_text" "$_f2_file_symbol")
                _f2_payload=$(jq -n --arg b "$_f2_body" '{body: $b}')
                if ! provider_update "$td_gh_id" "$_f2_payload" >/dev/null 2>&1; then
                    tracker_error_emit "partial-write" \
                        "promote_path2: provider_update failed for TD $td body Resolution sync (gh-id $td_gh_id)" \
                        "(phase task + TD close succeeded; Resolution body sync failed — reverse migration will not recover human-readable Resolution; re-run after addressing the backend failure)"
                    return 1
                fi
            fi
        fi
    fi
    # F9 (BD-107 review): success path — clean up the plan snapshot.
    [[ -n "$plan_snapshot" && -f "$plan_snapshot" ]] && rm -f "$plan_snapshot"

    jq -n \
        --arg td "$td" \
        --arg tg "$target" \
        --arg pt "$td_title" \
        --arg ti "$tracker_id" \
        --argjson lc "$labels_created" \
        --arg pl "$promoted_label" \
        --arg mo "$mode" \
        --arg rt "$resolution_text" \
        --argjson de "$dependency_edges" \
        '{
            td_id:             $td,
            target:            $tg,
            task_title:        $pt,
            tracker_id:        $ti,
            labels_created:    $lc,
            promoted_to:       $pl,
            mode:              $mo,
            resolution_text:   $rt,
            dependency_edges:  $de
         }'
    return 0
}

# ─────────────────────────────────────────────────────────────────
# Public: direct close wrapper (V3.3 §3.2)
# ─────────────────────────────────────────────────────────────────

# tracker_promote_direct_close <td-id> [<note>]
#
# Per V3.3 §3.2: a TD that the user / PM Chat decides is small enough
# to close inline ends through the normal v10 lifecycle. NO promotion
# label, NO derived-from reverse-pointer, NO new entity.
#
# This wrapper exists so PM Chat has a uniform JSON-shaped entry point
# across the three V3.3 §3.1 outcomes — the implementation explicitly
# emits an empty promotion_labels array and a null new_entity to make
# the "nothing happens beyond v10 lifecycle" contract programmatically
# legible. The actual BACKLOG status flip + tracker-side close is
# delegated to the existing v10 procedures (METHODOLOGY § Part 7
# Procedure 4) — this wrapper does NOT mutate state.
#
# Call-out 7 disposition: thin pass-through marker (not a state-
# mutating wrapper). The implementation rationale is documented in
# IMPLEMENTATION-REPORT-BD-107.md §7.
tracker_promote_direct_close() {
    local td="$1"
    local note="${2:-completed inline}"
    _tpr_validate_td_id "$td" || return 1
    local today
    today=$(_tpr_today_iso)
    local resolution_text="[$today, completed, $note]"
    jq -n \
        --arg td "$td" \
        --arg rt "$resolution_text" \
        --arg nt "$note" \
        '{
            td_id:             $td,
            outcome:           "direct-close",
            promotion_labels:  [],
            new_entity:        null,
            resolution_text:   $rt,
            note:              $nt,
            v10_lifecycle:     "use existing pack td resolve / BACKLOG-edit procedure (METHODOLOGY § Part 7 Procedure 4)"
         }'
    return 0
}

# ─────────────────────────────────────────────────────────────────
# Public: reverse handlers (V3.3 §3.3 / §3.4 round-trip)
# ─────────────────────────────────────────────────────────────────

# tracker_promote_reverse_path1 <phase-N> <repo-root>
#
# Read the closed phase epic + look for `derived-from:TD-NNN` label.
# Reconstruct the source TD's expected Resolution text. Used by
# tracker-migrate-reverse for round-trip identity verification.
#
# In flat-file mode (no .pack-tracker/id-map.json), the function falls
# back to grepping IMPLEMENTATION-PLAN.md and BACKLOG.md for the
# `## Phase N` block and the matching TD's Resolution. Either path
# emits the same JSON shape so callers (round-trip tests) can compose
# uniformly.
tracker_promote_reverse_path1() {
    local target="$1"
    local repo_root="$2"
    if [[ ! "$target" =~ ^phase-([0-9]+)$ ]]; then
        tracker_error_emit "validation" \
            "reverse_path1: target must be phase-N; got '$target'"
        return 1
    fi
    local phase_n="${BASH_REMATCH[1]}"

    # Flat-file path: scan the backlog source for a TD whose Resolution
    # names the target phase (round-trip-safety read per V3.3 §3.3). The
    # source is the client-root $repo_root/BACKLOG.md flat-file or the
    # project per-entry tree docs/project/backlog/ (BD-206 no-mirror —
    # the docs/project/BACKLOG.md monolith is abolished).
    local entries=""
    entries=$(_tpr_read_backlog_entries "$repo_root")
    local derived_from=""
    local resolution_text=""
    if [[ -n "$entries" ]]; then
        # Walk entries; find first TD whose resolution names the target.
        local hit
        hit=$(printf '%s' "$entries" | jq -c --arg tg "$target" \
            'first(.[] | select((.pack_id // "") | startswith("TD-")) | select((.resolution // "") | contains($tg)))')
        if [[ -n "$hit" && "$hit" != "null" ]]; then
            derived_from=$(printf '%s' "$hit" | jq -r '.pack_id')
            resolution_text=$(printf '%s' "$hit" | jq -r '.resolution')
        fi
    fi

    jq -n \
        --arg ph "$target" \
        --arg df "$derived_from" \
        --arg rt "$resolution_text" \
        '{phase: $ph, derived_from: $df, resolution: $rt}'
    return 0
}

# tracker_promote_reverse_path2 <phase-N.M> <repo-root>
# Symmetric to reverse_path1 for phase tasks. Emits the same JSON
# shape with `phase` populated as `phase-N.M`.
tracker_promote_reverse_path2() {
    local target="$1"
    local repo_root="$2"
    if [[ ! "$target" =~ ^phase-([0-9]+)\.([0-9]+)$ ]]; then
        tracker_error_emit "validation" \
            "reverse_path2: target must be phase-N.M; got '$target'"
        return 1
    fi

    # BD-206 no-mirror: read the backlog source (client-root flat-file or
    # the project per-entry tree); the docs/project/BACKLOG.md monolith
    # is abolished.
    local entries=""
    entries=$(_tpr_read_backlog_entries "$repo_root")
    local derived_from=""
    local resolution_text=""
    if [[ -n "$entries" ]]; then
        local hit
        hit=$(printf '%s' "$entries" | jq -c --arg tg "$target" \
            'first(.[] | select((.pack_id // "") | startswith("TD-")) | select((.resolution // "") | contains($tg)))')
        if [[ -n "$hit" && "$hit" != "null" ]]; then
            derived_from=$(printf '%s' "$hit" | jq -r '.pack_id')
            resolution_text=$(printf '%s' "$hit" | jq -r '.resolution')
        fi
    fi

    jq -n \
        --arg ph "$target" \
        --arg df "$derived_from" \
        --arg rt "$resolution_text" \
        '{phase: $ph, derived_from: $df, resolution: $rt}'
    return 0
}
