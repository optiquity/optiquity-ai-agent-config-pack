# scripts/lib/tracker-links.sh — uniform cross-entity dependency
# orchestration (BD-108; V3.3 §5.1 / §5.2 / §5.5 / §5.6).
#
# This library is the single point of entry for creating cross-entity
# `blocks` / `blocked-by` edges across the V3.3 §5.1 entity graph:
#
#   1. TD-NNN ←→ phase epic
#   2. TD-NNN ←→ phase task
#   3. phase task ←→ phase task (same phase)
#   4. phase task ←→ phase task (different phase)
#   5. TD-NNN ←→ TD-NNN (already in v10; unchanged)
#   6. TD-NNN ←→ BD-NNN (rare, cross-namespace)
#
# All six pairs use the same provider operation (provider_link), the
# same v10 grammar slot, and the same direction conventions. Per V3.3
# §5.2 NO new provider operation is added; NO new capability flag is
# added. This library is the orchestration layer above provider_link
# that:
#
#   1. Resolves pack-ids (TD-NNN / BD-NNN / phase-N / phase-N.M) to
#      tracker IDs via the existing id-map (tmf_mapping_get).
#   2. Runs cycle detection at link-creation time
#      (tracker_cycle_check_would_form_cycle) BEFORE issuing the
#      provider call. On cycle detection, refuses the link with a
#      typed error per V3.3 §5.6 / V1 §9 naming `pack tracker doctor`
#      as the next-step verb.
#   3. Calls provider_link(source, target, "blocked-by") on success.
#   4. Persists the new edge to the in-memory cycle-graph store
#      (`_tracker_cycle_check_store_add`) so subsequent cycle checks
#      see it.
#   5. Returns the edge metadata in the success JSON so the caller
#      can persist it to the sidecar's `dependency_edges` array
#      (V3.3 §6.R schema: kind / target / annotation). The sidecar
#      mutation itself is the caller's responsibility — the success
#      JSON's `annotation` field is the hook (BD-108 review F7). The
#      sidecar is the durable persistence record; the cycle-graph
#      store is the runtime view used by cycle-check on the next
#      link attempt.
#
# Public API:
#   - tracker_links_create_blocked_by \
#         <source-pack-id> <target-pack-id> \
#         <id-map-json> <store-path> [<annotation>]
#       Create one "source blocked-by target" edge across the full
#       entity graph. Returns rc=0 on success; rc=1 on validation /
#       cycle / provider error (typed error on stderr).
#
#       <id-map-json>   The id-map produced by tmf_mapping_load. Maps
#                       pack-id → {id, url[, task_order]} per V3.2/V3.3.
#       <store-path>    The cycle-graph store JSON file. Created on
#                       first link if absent.
#       <annotation>    Optional free-text annotation captured per
#                       V3.3 §5.3 trailing-prose rule. Empty string
#                       when absent. Returned in the success JSON for
#                       caller consumption (the sidecar emit step on
#                       the migration scripts already knows where to
#                       persist it via tracker_phase_task_parse output).
#
#       Success output (stdout, JSON object):
#         {
#           "source_pack_id": "<src>",
#           "target_pack_id": "<tgt>",
#           "source_tracker_id": "<gh-id>",
#           "target_tracker_id": "<gh-id>",
#           "kind": "blocked-by",
#           "annotation": "<free-text or empty>"
#         }
#
#   - tracker_links_validate_id_shapes <source-pack-id> <target-pack-id>
#       Return rc=0 if both source and target are valid pack-id
#       shapes (`phase-N`, `phase-N.M`, `TD-NNN`, or `BD-NNN`); rc=1
#       with typed error otherwise. The validator is shape-only and
#       does NOT enforce the V3.3 §5.1 entity-pair table — the
#       provider's `link()` is cross-type per V1 §2.1, so accepting
#       e.g. BD↔BD is not a correctness issue. (BD-108 review F11 —
#       renamed from `tracker_links_validate_pair_type` to match
#       behaviour.)
#
# Provider-op confirmation (per BD-108 IMPLEMENTATION-REPORT call-out):
#   The library uses the existing provider_link function from
#   scripts/lib/tracker-provider.sh (signature: provider_link <id>
#   <other_id> <kind>). The github backend's implementation lives at
#   tracker_provider_gh_link in scripts/lib/tracker-provider-gh.sh
#   (V1 §2.7.1 row 12; first-class `addBlockedBy` GraphQL mutation
#   per BD-111 — formerly comment-marker fallback "Blocked by #NNN"
#   per the V3 §28 fallback path before BD-111 swapped it). NO new
#   provider operation is introduced.
#
# Reference:
#   - ARCHITECTURE-V3.3-DELTA.md §5.1 (entity-pair table)
#   - ARCHITECTURE-V3.3-DELTA.md §5.2 (tracker-level representation;
#     no new provider op; no new capability flag)
#   - ARCHITECTURE-V3.3-DELTA.md §5.5 (cycle detection at link-create)
#   - ARCHITECTURE-V3.3-DELTA.md §5.6 (typed error + verb naming)
#   - ARCHITECTURE-V3.3-DELTA.md §6.R (sidecar dependency_edges schema)
#   - ARCHITECTURE.md §5.3 (reserved link.kind open-string family)
#   - ARCHITECTURE.md §9 (typed errors per category)
#
# Constraints:
#   - Bash 3.2 compatible (no associative arrays, no mapfile).
#   - No state-changing git verbs.
#   - No new provider operation; no new capability flag.
#
# Do NOT add a shebang — this file is sourced, not executed.

# Source dependencies idempotently. Mirrors the pattern used in
# tracker-config.sh / tracker-provider.sh.
# shellcheck disable=SC1091
if ! declare -f tracker_error_emit >/dev/null 2>&1; then
    _tlk_self="${BASH_SOURCE[0]}"
    _tlk_dir="$(cd "$(dirname "$_tlk_self")" && pwd)"
    source "$_tlk_dir/tracker-errors.sh"
    unset _tlk_self _tlk_dir
fi
# shellcheck disable=SC1091
if ! declare -f tracker_cycle_check_would_form_cycle >/dev/null 2>&1; then
    _tlk_self="${BASH_SOURCE[0]}"
    _tlk_dir="$(cd "$(dirname "$_tlk_self")" && pwd)"
    source "$_tlk_dir/tracker-cycle-check.sh"
    unset _tlk_self _tlk_dir
fi

# ─────────────────────────────────────────────────────────────────
# Public: pair-type validation
# ─────────────────────────────────────────────────────────────────

# tracker_links_validate_id_shapes <src> <tgt>
# Pack-id forms recognized:
#   - phase-<N>           (phase epic)
#   - phase-<N>.<M>       (phase task)
#   - TD-<NNN>            (TD-class entry)
#   - BD-<NNN>            (BD-class entry)
#
# Both source and target must each match one of the four shapes;
# a typed validation error is emitted on any unrecognized shape.
#
# This is a SHAPE check only — it does NOT enforce the V3.3 §5.1
# entity-pair table. The provider's `link()` is cross-type per V1 §2.1,
# so accepting e.g. BD↔BD or two phase epics is not a correctness
# issue (V3.3 §5.1's six-row table is descriptive, not restrictive).
# (BD-108 review F11 — renamed from `tracker_links_validate_pair_type`
# to match the actual behaviour, which is per-id-shape validation
# rather than pair-type enforcement.)
#
# Order-tolerant: src and tgt are validated independently — the
# directional convention (source blocked-by target) is enforced by
# the caller (tracker_links_create_blocked_by).
tracker_links_validate_id_shapes() {
    local src="$1"
    local tgt="$2"
    if [[ -z "$src" || -z "$tgt" ]]; then
        tracker_error_emit "validation" \
            "links: source and target pack-ids required"
        return 1
    fi
    if ! _tlk_is_valid_pack_id "$src"; then
        tracker_error_emit "validation" \
            "links: unrecognized source pack-id shape: '$src'" \
            "(expected phase-N, phase-N.M, TD-NNN, or BD-NNN)"
        return 1
    fi
    if ! _tlk_is_valid_pack_id "$tgt"; then
        tracker_error_emit "validation" \
            "links: unrecognized target pack-id shape: '$tgt'" \
            "(expected phase-N, phase-N.M, TD-NNN, or BD-NNN)"
        return 1
    fi
    return 0
}

# ─────────────────────────────────────────────────────────────────
# Public: link orchestration
# ─────────────────────────────────────────────────────────────────

# tracker_links_create_blocked_by <src-pack-id> <tgt-pack-id> \
#                                 <id-map-json> <store-path> [<annotation>]
#
# End-to-end orchestration:
#   1. Validate both pack-id shapes (V3.3 §5.1 vocabulary; see
#      `tracker_links_validate_id_shapes`).
#   2. Resolve both pack-ids to tracker ids via the id-map. A missing
#      id is a typed error (the caller should run forward migration to
#      populate the id-map first).
#   3. Run cycle detection from proposed-target with K hops from
#      tracker.toml [graph] cycle_check_k (default 10). If a cycle
#      would form, refuse and surface a typed error.
#   4. Call provider_link(source-id, target-id, "blocked-by"). Any
#      backend error surfaces verbatim; provider_link is responsible
#      for emitting its own typed error block.
#   5. On success, append the edge to the cycle-graph store so the
#      next cycle check sees it.
#   6. Emit the success JSON on stdout for the caller (sidecar emit,
#      forward orchestrator counter, test harness, etc.).
#
# Reference: V3.3 §5.5 (cycle check); §5.6 (UX); §6.R (sidecar shape).
tracker_links_create_blocked_by() {
    local src="$1"
    local tgt="$2"
    local id_map="$3"
    local store_path="$4"
    local annotation="${5:-}"

    # Step 1: pack-id shape validation (V3.3 §5.1 vocabulary).
    tracker_links_validate_id_shapes "$src" "$tgt" || return 1

    if [[ -z "$id_map" ]]; then
        tracker_error_emit "validation" \
            "links: id-map JSON required (run forward migration first)"
        return 1
    fi
    if [[ -z "$store_path" ]]; then
        tracker_error_emit "validation" \
            "links: cycle-graph store path required"
        return 1
    fi

    # Step 2: resolve pack-ids → tracker ids.
    local src_id tgt_id
    src_id=$(_tlk_resolve_id "$id_map" "$src") || return 1
    tgt_id=$(_tlk_resolve_id "$id_map" "$tgt") || return 1

    # Step 3: cycle check (V3.3 §5.5). Read K from the cycle store's
    # repo root. The store conventionally lives at
    # <repo-root>/.pack-tracker/links-graph.json so we infer the repo
    # root by walking up from the store path. The cycle checker itself
    # accepts an explicit K if it cannot be inferred.
    local k
    k=$(_tlk_resolve_k_from_store_path "$store_path")
    if ! tracker_cycle_check_would_form_cycle "$src" "$tgt" "$store_path" "$k"; then
        # tracker_cycle_check_would_form_cycle already emitted the
        # typed error block (with the `pack tracker doctor` verb per
        # V3.3 §5.6). Surface its rc verbatim.
        return 1
    fi

    # Step 4: provider call. The github backend uses the first-class
    # `addBlockedBy` GraphQL mutation per BD-111 (was comment-marker
    # fallback pre-BD-111 per V1 §2.7.1 row 12). Tests for this
    # library run against a stub backend that echoes success without
    # hitting the network.
    #
    # RE-RUN IDEMPOTENCY (BD-204 rehearsal run-3 Defect B): the
    # already-exists consult is PROVIDER-TRUTH, inside provider_link
    # (the gh backend reads `Issue.blockedBy` and skips the mutation
    # when the edge exists). The cycle-graph store below is NOT used
    # as a create-dedup: its idempotency is WRITE-side only (store_add
    # dedups tuples) and it is the cycle-check runtime view — store
    # presence cannot prove the tracker-side edge still exists (store
    # loss / GH-side unlink would make a store-based skip silently
    # wrong), so the orchestrator intentionally re-calls provider_link
    # on every run and lets the provider decide.
    if ! provider_link "$src_id" "$tgt_id" "blocked-by" >/dev/null 2>&1; then
        # Provider already emitted its typed error block. We do not
        # double-format; just bubble up.
        return 1
    fi

    # Step 5: persist the edge to the cycle-graph store. If this fails,
    # the link DID create on the tracker side; we surface a partial-
    # write typed error so the user knows the in-memory state diverges
    # from the store. Per V3.3 §5.6 + V1 §9.6, partial writes name the
    # next-step verb explicitly.
    if ! _tracker_cycle_check_store_add "$store_path" "$src" "$tgt"; then
        tracker_error_emit "partial-write" \
            "links: provider link succeeded but cycle-graph store write failed" \
            "(edge: $src blocked-by $tgt; store: $store_path)" \
            "tracker side OK; cycle-store re-sync needed before next link"
        return 1
    fi

    # Step 6: success JSON.
    jq -n \
        --arg sp "$src" \
        --arg tp "$tgt" \
        --arg si "$src_id" \
        --arg ti "$tgt_id" \
        --arg an "$annotation" \
        '{
            source_pack_id:   $sp,
            target_pack_id:   $tp,
            source_tracker_id: $si,
            target_tracker_id: $ti,
            kind: "blocked-by",
            annotation: $an
        }'
    return 0
}

# ─────────────────────────────────────────────────────────────────
# Internal helpers
# ─────────────────────────────────────────────────────────────────

# _tlk_is_valid_pack_id <pack-id>
# rc=0 if the pack-id matches one of the four V3.3 §5.1 forms;
# rc=1 otherwise. No error emission — caller decides how to surface.
_tlk_is_valid_pack_id() {
    local pid="$1"
    case "$pid" in
        # phase-N (phase epic) or phase-N.M (phase task)
        phase-[0-9]*)
            if [[ "$pid" =~ ^phase-[0-9]+(\.[0-9]+)?$ ]]; then
                return 0
            fi
            return 1
            ;;
        # TD-NNN
        TD-[0-9]*)
            if [[ "$pid" =~ ^TD-[0-9]+$ ]]; then
                return 0
            fi
            return 1
            ;;
        # BD-NNN
        BD-[0-9]*)
            if [[ "$pid" =~ ^BD-[0-9]+$ ]]; then
                return 0
            fi
            return 1
            ;;
        *)
            return 1
            ;;
    esac
}

# _tlk_resolve_id <id-map-json> <pack-id>
# Read mapping[<pack-id>].id. Emits the tracker id on stdout; rc=1
# with typed error if absent. The caller already validated the pair
# shape, so an absent id here is a "forward migration didn't populate
# this entry yet" signal.
_tlk_resolve_id() {
    local id_map="$1"
    local pid="$2"
    local val
    val=$(printf '%s' "$id_map" | jq -r --arg k "$pid" \
        'if has($k) then (.[$k].id // empty) else empty end' 2>/dev/null)
    if [[ -z "$val" || "$val" == "null" ]]; then
        tracker_error_emit "not-found" \
            "links: pack-id '$pid' not in id-map" \
            "(run \`pack tracker forward\` first to create the tracker entry)"
        return 1
    fi
    printf '%s\n' "$val"
}

# _tlk_resolve_k_from_store_path <store-path>
# Best-effort: infer the repo root from the store path by stripping
# the conventional `.pack-tracker/links-graph.json` suffix, then
# delegating to tracker_cycle_check_get_k. Falls back to the default
# K (10) if the store path doesn't follow the convention.
_tlk_resolve_k_from_store_path() {
    local sp="$1"
    local dir
    dir=$(dirname "$sp")
    local base
    base=$(basename "$dir")
    if [[ "$base" == ".pack-tracker" ]]; then
        local repo_root
        repo_root=$(dirname "$dir")
        tracker_cycle_check_get_k "$repo_root"
        return 0
    fi
    # Unconventional path: just use the default. This is the test-
    # fixture case (tests put the store wherever is convenient).
    printf '%s\n' "$TRACKER_CYCLE_CHECK_K_DEFAULT"
}
