# scripts/lib/tracker-labels.sh — V1 §6.1 step-3 label set ensurer
# (BD-066).
#
# Sourced by tracker-init.sh during `pack tracker init`. Ensures
# every label the pack relies on exists in the tracker repository,
# creating any that are absent. Idempotent: existing labels are not
# touched. Backend-aware via the TrackerProvider abstraction (BD-060)
# — at v11.0 only the github backend ships, but the contract is
# identical across backends that support flat label sets
# (capabilities.labels.supported = true).
#
# Three label families are ensured:
#   - **Entry-type provenance**: `bd-entry`, `td-entry`, `phase-epic`,
#     `phase-task`, `work-item`, `inbound`, `external`, `pack-feedback`,
#     `needs-triage`.
#   - **Status / state** (V1 §4.1 + V3.3 §6.3): `status:open`,
#     `status:unblocked`, `status:in-review`, `status:resolved`,
#     `status:cancelled`, `status:deprecated`, `status:pending`,
#     `status:in-progress`, `status:done`, `status:deferred`.
#   - **Type / scope / severity** (METHODOLOGY § Part 7 + V1 §4.1):
#     `type:feat`, `type:fix`, `type:refactor`, `type:docs`,
#     `type:chore`, `type:infra`, `type:bug`, `type:feature`,
#     `scope:phase-N`, `scope:dependency`, `scope:feature`, `scope:perf`,
#     `scope:version`, `severity:critical`, `severity:functional`,
#     `severity:polish`.
#   - **Template-version** (V3.3 §6.5 D-18): `template:work-item-v11.0`,
#     `template:inbound-v11.0`, `template:bd-v11.0`, `template:td-v11.0`,
#     `template:phase-epic-v11.0`, `template:phase-task-v11.0`.
#   - **Pack-feedback subcategory** (V2 §4.3): `pf-category:workflow`,
#     `pf-category:prompt`, `pf-category:agent-perf`,
#     `pf-category:friction`, `pf-category:open-question`.
#
# Promotion-path label family (V3.3 §3.5; BD-106 lands the helpers):
#   - `derived-from:TD-NNN` — applied to the new phase epic (Path 1)
#     or new phase task (Path 2). Reverse pointer to the source TD.
#   - `promoted-to:phase-N` / `promoted-to:phase-N.M` — applied to
#     the closed TD-NNN issue. Forward pointer; TD became a phase or
#     phase task.
#   - `folded-into:` is NOT supported — Path 3 is forbidden by V3.3
#     §3 line 27. Helpers below intentionally have no `folded-into`
#     constructor.
# These are open-string label families (one label per concrete
# identifier); they are NOT ensured at init time — created at the
# moment of promotion / derivation via the helpers below.
#
# Public API:
#   - tracker_labels_canonical_set
#       Emits the canonical label set as one-name-per-line.
#   - tracker_labels_ensure
#       Reads the canonical set and creates any missing labels via
#       `gh label create`. Idempotent. Emits a one-line summary
#       (created / already-present / failed counts) on stdout.
#   - tracker_labels_derived_from <td-id>
#       Echoes `derived-from:TD-NNN`. Validates the input matches
#       `TD-\d+` and rejects anything else (BD-NNN derivation is not
#       a thing in V3.3 — only TDs promote per §3).
#   - tracker_labels_promoted_to <phase-or-task-id>
#       Echoes `promoted-to:phase-N` or `promoted-to:phase-N.M`.
#       Validates the input matches the phase / phase-task identifier
#       grammar.
#
# Reference: ARCHITECTURE.md §4.1, §6.1; ARCHITECTURE-V2.md §4.2 / §4.3;
# ARCHITECTURE-V3.3-DELTA.md §6.3 / §6.5; §3.5 (label family).
#
# Do NOT add a shebang — this file is sourced, not executed.

# ─────────────────────────────────────────────────────────────────
# Public: canonical set (one per line)
# ─────────────────────────────────────────────────────────────────

tracker_labels_canonical_set() {
    cat <<'EOF'
bd-entry
td-entry
phase-epic
phase-task
work-item
inbound
external
pack-feedback
needs-triage
status:open
status:unblocked
status:in-review
status:resolved
status:cancelled
status:deprecated
status:pending
status:in-progress
status:done
status:deferred
type:feat
type:fix
type:refactor
type:docs
type:chore
type:infra
type:bug
type:feature
scope:dependency
scope:feature
scope:perf
scope:version
severity:critical
severity:functional
severity:polish
template:work-item-v11.0
template:inbound-v11.0
template:bd-v11.0
template:td-v11.0
template:phase-epic-v11.0
template:phase-task-v11.0
pf-category:workflow
pf-category:prompt
pf-category:agent-perf
pf-category:friction
pf-category:open-question
EOF
}

# ─────────────────────────────────────────────────────────────────
# Public: ensure
# ─────────────────────────────────────────────────────────────────

# tracker_labels_ensure
# Ensures every label in the canonical set exists in the active
# tracker repo. Reads existing labels via `gh label list --json name`
# and creates missing ones via `gh label create`. Returns 0 on full
# success, 1 if any label create fails (the failures are emitted as
# partial-write context lines).
tracker_labels_ensure() {
    local existing missing_count=0 created=0 failed=0 already_present=0
    local pf_file
    pf_file=$(mktemp "${TMPDIR:-/tmp}/tlbl-pf.XXXXXX")
    : > "$pf_file"

    # BD-129 / D-1: export GH_REPO from the active tracker.toml so the
    # `gh label list` and `gh label create` calls below target the
    # configured backend.repo, not whatever (possibly missing or
    # non-GitHub) remote the working repo's git config exposes. The
    # helper is a no-op when GH_REPO is already set or when no
    # tracker config is in scope.
    if declare -f tracker_gh_repo_setup >/dev/null 2>&1; then
        tracker_gh_repo_setup
    fi

    # Fetch existing labels. `gh label list --json name --limit 200`
    # is enough for v11.0's ~45 label set; bump the limit if a pack
    # extension grows beyond that.
    if ! existing=$(_tracker_labels_existing 2>/dev/null); then
        rm -f "$pf_file"
        tracker_error_emit "validation" \
            "labels_ensure: cannot read existing labels (gh auth or network failure)"
        return 1
    fi

    local label
    while IFS= read -r label; do
        [[ -z "$label" ]] && continue
        if printf '%s\n' "$existing" | grep -qFx "$label"; then
            already_present=$((already_present + 1))
            continue
        fi
        missing_count=$((missing_count + 1))
        if _tracker_labels_create "$label"; then
            created=$((created + 1))
        else
            failed=$((failed + 1))
            printf 'failed to create label: %s\n' "$label" >> "$pf_file"
        fi
    done < <(tracker_labels_canonical_set)

    cat <<EOF
labels: canonical=$(tracker_labels_canonical_set | wc -l | tr -d ' ')  missing=$missing_count  created=$created  already-present=$already_present  failed=$failed
EOF
    if [[ "$failed" -gt 0 ]]; then
        local extras=()
        while IFS= read -r line; do
            extras+=("  - $line")
        done < "$pf_file"
        rm -f "$pf_file"
        tracker_error_emit "partial-write" \
            "labels_ensure: $failed of $missing_count missing label(s) failed to create. Idempotent re-run will retry." \
            "${extras[@]}"
        return 1
    fi
    rm -f "$pf_file"
    return 0
}

# ─────────────────────────────────────────────────────────────────
# Private helpers
# ─────────────────────────────────────────────────────────────────

# Read the current label set in the active repo. Emits one name
# per line on stdout. Returns rc=1 with typed error on backend
# failure.
_tracker_labels_existing() {
    local out
    if ! out=$(gh label list --json name --limit 200 2>/dev/null); then
        return 1
    fi
    printf '%s' "$out" | jq -r '.[].name'
}

# Create a single label. Returns rc=0 on success, rc=1 on failure
# (caller logs which name failed). Color/description are minimal —
# the chat updates them at first use if needed.
_tracker_labels_create() {
    local name="$1"
    gh label create "$name" --description "v11 pack-managed label" --color "ededed" --force >/dev/null 2>&1
}

# ─────────────────────────────────────────────────────────────────
# BD-106 — promotion-path label family helpers (V3.3 §3.5)
# ─────────────────────────────────────────────────────────────────

# tracker_labels_derived_from <td-id>
# Compose the `derived-from:TD-NNN` label. Validates the input is a
# canonical TD identifier; rejects anything else with rc=1.
# (Only TDs derive new phase / phase-task entities per V3.3 §3 —
# BD derivation is not in scope for v11.0.)
tracker_labels_derived_from() {
    local td="$1"
    if [[ ! "$td" =~ ^TD-[0-9]+$ ]]; then
        tracker_error_emit "validation" "tracker_labels_derived_from: invalid TD id $td"
        return 1
    fi
    printf 'derived-from:%s\n' "$td"
}

# tracker_labels_promoted_to <phase-or-task-id>
# Compose the `promoted-to:phase-N` (Path 1) or
# `promoted-to:phase-N.M` (Path 2) label. Validates the input matches
# the phase / phase-task identifier grammar; rejects anything else
# with rc=1. Path 3 is forbidden — there is intentionally no
# `tracker_labels_folded_into` constructor.
tracker_labels_promoted_to() {
    local target="$1"
    if [[ ! "$target" =~ ^phase-[0-9]+(\.[0-9]+)?$ ]]; then
        tracker_error_emit "validation" "tracker_labels_promoted_to: invalid target $target"
        return 1
    fi
    printf 'promoted-to:%s\n' "$target"
}
