# scripts/lib/tracker-cycle-check.sh — link-creation-time cycle
# detection for the cross-entity dependency graph (BD-108; V3.3 §5.5).
#
# Per V3.3 §5.5: cycle detection runs at link-creation time in PM Chat
# (not in the provider). We traverse `blocked-by` edges starting at the
# proposed-target for K hops (K = configurable, default 10 per V3.3 §5.5
# / IPLAN-ADDENDUM-4 §6.Q recommendation (a)). If the proposed-source
# appears anywhere in the closure, the new edge would close a cycle and
# we must refuse the link.
#
# The algorithm is **type-agnostic**: it walks edges regardless of
# entity type at either end. This covers the full V3.3 §5.1 entity
# graph (TD ↔ TD; TD ↔ phase epic; TD ↔ phase task; phase task ↔ phase
# task in same/different phase; TD ↔ BD).
#
# Public API:
#   - tracker_cycle_check_get_k <repo-root>
#       Read tracker.toml [graph] cycle_check_k and emit it on stdout.
#       Falls back to 10 if the field is absent. rc=0 always.
#
#   - tracker_cycle_check_would_form_cycle \
#         <proposed-source-pack-id> \
#         <proposed-target-pack-id> \
#         <cycle-graph-store-path>
#       Walk `blocked-by` edges in the cycle-graph store starting at
#       the proposed-target. If the proposed-source appears within
#       K hops (default 10), rc=1 (the link would close a cycle);
#       otherwise rc=0 (the link is safe to create).
#
#       The store argument names the cycle-graph store (the runtime
#       edge index this lib maintains) — NOT the V3.3 §6.R sidecar
#       `dependency_edges` block. They are two distinct artifacts;
#       see "Cycle-graph store contract" below for schema. (BD-108
#       review F8 — parameter rename for unambiguous artifact
#       identity.)
#
#       Traversal direction (algorithm-correct rationale; BD-108
#       review F6):
#         out[X] = [things X is blocked by]. Walking forward from
#         `tgt` along blocked-by edges enumerates the set of nodes
#         that `tgt` is (transitively) blocked by. If we reach the
#         proposed-source from the proposed-target, then
#         **proposed-target is (transitively) blocked-by
#         proposed-source** in the existing graph. Adding the
#         proposed edge `S blocked-by T` (i.e., S → T) would then
#         close a cycle S → T → ... → S, so we refuse it.
#
#       Note on the V3.3 §5.5 prose ("traverses `blocked-by` from
#       the new edge's source for K hops; if the target appears in
#       the closure, refuse"): if read literally that wording would
#       NOT detect cycles correctly — walking from S along blocked-by
#       enumerates what S is blocked by, not what blocks S, so
#       reaching T from S would mean S is already blocked by T, which
#       is the inverse of the cycle condition for "S blocked-by T".
#       The implementation here (walk from tgt) matches graph-
#       theoretic correctness; the spec text wording is a known
#       imprecision and should be re-tightened in a future spec
#       revision.
#
#       Fail-closed semantics: traversal errors (malformed sidecar,
#       unreadable JSON, etc.) emit a typed error and rc=1 — the
#       caller refuses the link. Per V3.3 §5.6, no silent retry.
#
# Cycle-graph store contract:
#   The <cycle-graph-store-path> argument is the path to a JSON file
#   shaped:
#     {
#       "edges": [
#         {"source": "<pack-id>", "target": "<pack-id>", "kind": "blocked-by"},
#         ...
#       ]
#     }
#   This is the in-memory edge index that tracker_links_create_blocked_by
#   maintains; it is a thin projection of the sidecar's
#   `phase_tasks[].dependency_edges` block (V3.3 §6.R) plus the
#   non-phase-task BD/TD edges that the existing forward orchestrator
#   has historically created via provider_link.
#
#   The cycle-graph store is the durable runtime view used by cycle
#   detection; the V3.3 §6.R sidecar is the durable persistence view.
#   Keeping them as separate files lets the cycle check stay O(K)
#   per query without re-deriving the edge set from a per-task YAML
#   block on every link attempt. (BD-108 review F8: do NOT confuse
#   the cycle-graph store with the §6.R sidecar — they have
#   different schemas and different lifetimes.)
#
# Reference:
#   - ARCHITECTURE-V3.3-DELTA.md §5.5 (cycle detection)
#   - ARCHITECTURE-V3.3-DELTA.md §5.6 (A1 failure-mode UX; verb naming)
#   - IMPLEMENTATION-PLAN-ADDENDUM-4.md §6.Q (K-value MAINTAINER CHECK;
#     option (a): K=10 default, configurable via tracker.toml [graph]
#     cycle_check_k)
#   - ARCHITECTURE.md §9 (typed errors); ARCHITECTURE-V3.md §27.1 Layer 2
#     (verb naming)
#
# Constraints:
#   - Bash 3.2 compatible (no associative arrays, no mapfile).
#   - Heavy graph walking offloaded to python3 (already a hard dependency).
#   - No state-changing git verbs.
#
# Do NOT add a shebang — this file is sourced, not executed.

# Source the typed-error formatter idempotently (same pattern as
# tracker-config.sh / tracker-provider.sh).
# shellcheck disable=SC1091
if ! declare -f tracker_error_emit >/dev/null 2>&1; then
    _tcc_self="${BASH_SOURCE[0]}"
    _tcc_dir="$(cd "$(dirname "$_tcc_self")" && pwd)"
    source "$_tcc_dir/tracker-errors.sh"
    unset _tcc_self _tcc_dir
fi

# Source tracker-config.sh idempotently for tracker_config_get.
# shellcheck disable=SC1091
if ! declare -f tracker_config_get >/dev/null 2>&1; then
    _tcc_self="${BASH_SOURCE[0]}"
    _tcc_dir="$(cd "$(dirname "$_tcc_self")" && pwd)"
    source "$_tcc_dir/tracker-config.sh"
    unset _tcc_self _tcc_dir
fi

# Default cycle-check K-hop count per V3.3 §5.5 + IPLAN-ADDENDUM-4
# §6.Q recommendation (a). Used as the fallback when tracker.toml
# does not set [graph] cycle_check_k.
readonly TRACKER_CYCLE_CHECK_K_DEFAULT=10

# ─────────────────────────────────────────────────────────────────
# Public: K-value resolver
# ─────────────────────────────────────────────────────────────────

# tracker_cycle_check_get_k <repo-root>
# Read [graph] cycle_check_k from the active tracker.toml. Resolution:
#   1. If <repo-root>/tracker.toml exists, read graph.cycle_check_k
#      from it and emit. Fall back to default on absent key or
#      non-integer value.
#   2. If <repo-root>/docs/pack/tracker.toml exists (client surface),
#      consult it instead.
#   3. Otherwise, emit TRACKER_CYCLE_CHECK_K_DEFAULT (10).
#
# Always rc=0; the function is deliberately permissive so callers can
# treat it as "give me a number to use" without worrying about config
# absence.
tracker_cycle_check_get_k() {
    local repo_root="$1"
    local cfg=""
    if [[ -f "$repo_root/tracker.toml" ]]; then
        cfg="$repo_root/tracker.toml"
    elif [[ -f "$repo_root/docs/pack/tracker.toml" ]]; then
        cfg="$repo_root/docs/pack/tracker.toml"
    fi
    if [[ -z "$cfg" ]]; then
        printf '%s\n' "$TRACKER_CYCLE_CHECK_K_DEFAULT"
        return 0
    fi
    local val
    if val=$(tracker_config_get "$cfg" "graph.cycle_check_k" 2>/dev/null); then
        # Guard against non-integer values surviving the parser.
        if [[ "$val" =~ ^[0-9]+$ ]] && [[ "$val" -gt 0 ]]; then
            printf '%s\n' "$val"
            return 0
        fi
    fi
    printf '%s\n' "$TRACKER_CYCLE_CHECK_K_DEFAULT"
}

# ─────────────────────────────────────────────────────────────────
# Public: cycle detector
# ─────────────────────────────────────────────────────────────────

# tracker_cycle_check_would_form_cycle <src> <tgt> <cycle-graph-store-path> [<k>]
#
# Returns:
#   rc=0  → safe (the proposed edge does NOT close a cycle within K hops)
#   rc=1  → unsafe (cycle would form, OR traversal failed — fail-closed)
#
# Traversal:
#   Treats the cycle-graph store as a directed graph of "blocked-by"
#   edges. Every edge entry shape:
#     {"source": A, "target": B, "kind": "blocked-by"}
#   means "A is blocked by B". We walk forward from `tgt` along
#   blocked-by edges (target → its targets → ...). If `src` appears in
#   the closure within K hops, the new edge "src blocked-by tgt" would
#   close a cycle.
#
# Self-loop guard: if src == tgt, the edge is itself a 1-cycle and we
# refuse it immediately without even reading the store.
#
# Per V3.3 §5.6 + V1 §9 / §27.1 Layer 2 the typed error names the verb
# `pack tracker doctor` so the user has a clear next step.
tracker_cycle_check_would_form_cycle() {
    local src="$1"
    local tgt="$2"
    local store_path="$3"
    local k="${4:-}"

    if [[ -z "$src" || -z "$tgt" || -z "$store_path" ]]; then
        tracker_error_emit "validation" \
            "cycle_check: src, tgt, store_path required"
        return 1
    fi

    # Self-loop refused immediately. The store path doesn't even need
    # to exist for this guard — a 1-cycle is a closed-form refusal.
    #
    # Verb-naming: BD-108 review F2 — the self-loop refusal is a
    # cycle-class failure exactly like the BFS-detected cycle path
    # below. V3.3 §5.6 mandates that cross-entity link failures "name
    # the verb (`pack tracker doctor`)", so we format the error inline
    # (matching the BFS path's `→ Run: pack tracker doctor` line)
    # rather than going through tracker_error_emit "validation" whose
    # verb-table entry maps to "review the backend message above" —
    # which would be inconsistent with the BFS path for the same
    # class of failure.
    if [[ "$src" == "$tgt" ]]; then
        printf 'ERROR: validation\n' >&2
        printf 'MESSAGE: cycle_check: refusing self-loop edge: %s blocked-by %s\n' \
            "$src" "$tgt" >&2
        printf '→ Run: pack tracker doctor\n' >&2
        return 1
    fi

    # Resolve K. If caller did not pass it, fall back to the default
    # (the config-aware tracker_cycle_check_get_k is reserved for the
    # tracker_links layer that knows the repo root; the cycle detector
    # itself is repo-agnostic).
    if [[ -z "$k" ]]; then
        k="$TRACKER_CYCLE_CHECK_K_DEFAULT"
    fi
    if ! [[ "$k" =~ ^[0-9]+$ ]] || [[ "$k" -le 0 ]]; then
        tracker_error_emit "validation" \
            "cycle_check: K must be a positive integer; got '$k'"
        return 1
    fi

    # Empty / missing store: the only edges in the graph would be the
    # one we propose to add (src → tgt). No cycle possible. The cycle
    # detector returns rc=0 (safe); the caller (tracker_links) will
    # create the store on first link.
    if [[ ! -f "$store_path" ]]; then
        return 0
    fi

    # BFS via python3 — bash 3.2's lack of associative arrays makes a
    # native bash implementation O(K * |edges|) at best with awk
    # gymnastics, which is harder to read and slower than a 30-line
    # python BFS. Same offload pattern as tracker-phase-task.sh.
    local rc=0
    SRC_ARG="$src" TGT_ARG="$tgt" K_ARG="$k" python3 - "$store_path" <<'PYEOF' || rc=$?
import json
import os
import sys

src = os.environ['SRC_ARG']
tgt = os.environ['TGT_ARG']
k   = int(os.environ['K_ARG'])

try:
    with open(sys.argv[1]) as f:
        store = json.load(f)
except (OSError, ValueError) as e:
    sys.stderr.write(
        'ERROR: schema-reshape\n'
        'MESSAGE: cycle_check: cannot read edge store at %s: %s\n'
        '→ Run: pack tracker doctor\n' % (sys.argv[1], e)
    )
    sys.exit(1)

edges = store.get('edges', []) if isinstance(store, dict) else []

# Build out-adjacency for blocked-by edges only. Other kinds (related,
# duplicates, parent/child) do NOT participate in cycle detection per
# V3.3 §5.5 (only blocked-by is a hard ordering constraint).
out = {}
for e in edges:
    if not isinstance(e, dict):
        continue
    if e.get('kind') != 'blocked-by':
        continue
    s = e.get('source')
    t = e.get('target')
    if not s or not t:
        continue
    out.setdefault(s, []).append(t)

# BFS starting at the proposed target. Walk up to K hops.
# At hop d, we hold the set of nodes reachable in exactly d steps from
# tgt via blocked-by edges. If src ever appears, the new edge closes
# a cycle.
frontier = set([tgt])
visited  = set([tgt])
# BD-204 C-8 defect 2: track BFS predecessors so the refusal names the
# CONCRETE cycle path (both IDs + every intermediate hop), not just the
# cycle length — the bare length message left the live BD-094/BD-095
# mutual-block failure unactionable once the forward arms collapsed it
# into a generic step-7 partial-failure line.
parent = {}
for hop in range(1, k + 1):
    next_frontier = set()
    for node in frontier:
        for nxt in out.get(node, []):
            if nxt == src:
                # Cycle found within K hops. Refuse the edge, naming
                # the full cycle path. Reconstruct tgt → ... → node via
                # the predecessor map; the proposed edge src→tgt opens
                # the path and the found edge node→src closes it.
                seq = [node]
                while seq[-1] != tgt:
                    seq.append(parent[seq[-1]])
                seq.reverse()
                path = ' -> '.join([src] + seq + [src])
                sys.stderr.write(
                    'ERROR: validation\n'
                    'MESSAGE: cycle_check: edge %s blocked-by %s would '
                    'close a cycle of length %d '
                    "(cycle path: %s; '->' = blocked-by)\n"
                    '→ Run: pack tracker doctor\n' % (src, tgt, hop + 1, path)
                )
                sys.exit(2)
            if nxt not in visited:
                visited.add(nxt)
                parent[nxt] = node
                next_frontier.add(nxt)
    if not next_frontier:
        break
    frontier = next_frontier

# Reached K hops without finding src. Safe (within the bounded search).
sys.exit(0)
PYEOF

    # rc=0 → safe; rc=1 → traversal error (typed error already on
    # stderr via the python sys.stderr.write above); rc=2 → cycle
    # detected. BATCH-17 F10 (cross-BD review): the python rc bubbles
    # up directly so callers and tests CAN distinguish "would-cycle"
    # (rc=2) from "traversal/schema error" (rc=1). Both are still
    # fail-closed for the higher-level link-orchestrator (which only
    # treats rc=0 as "safe"), but the diagnostic dimension is now
    # available for the test harness to assert on without parsing
    # stderr text.
    return $rc
}

# ─────────────────────────────────────────────────────────────────
# Internal: store-mutation helpers (consumed by tracker-links.sh)
# ─────────────────────────────────────────────────────────────────

# _tracker_cycle_check_store_add <store-path> <src> <tgt>
# Append a blocked-by edge to the store, creating the file if absent.
# Used by tracker_links_create_blocked_by AFTER the cycle check passes
# AND the provider call succeeds. Idempotent: if the same edge already
# exists, the store is left unchanged.
#
# Co-located here (private helper) because the store schema is owned
# by this file — adding the mutator here keeps schema knowledge in
# one place.
_tracker_cycle_check_store_add() {
    local store_path="$1"
    local src="$2"
    local tgt="$3"
    if [[ -z "$store_path" || -z "$src" || -z "$tgt" ]]; then
        tracker_error_emit "validation" \
            "_tracker_cycle_check_store_add: store_path, src, tgt required"
        return 1
    fi
    mkdir -p "$(dirname "$store_path")" 2>/dev/null || true
    if [[ ! -f "$store_path" ]]; then
        printf '%s\n' '{"edges":[]}' > "$store_path"
    fi
    # jq idempotency: only insert if (source, target, kind) tuple is
    # not already present.
    local tmp
    tmp=$(mktemp -t tcc-store.XXXXXX)
    if ! jq --arg s "$src" --arg t "$tgt" \
        '.edges = (.edges // []) | .edges = (
            if (.edges | map(select(.source == $s and .target == $t and .kind == "blocked-by")) | length) > 0
            then .edges
            else .edges + [{source: $s, target: $t, kind: "blocked-by"}]
            end)' "$store_path" > "$tmp"; then
        rm -f "$tmp"
        tracker_error_emit "schema-reshape" \
            "_tracker_cycle_check_store_add: jq failed on store $store_path"
        return 1
    fi
    mv "$tmp" "$store_path"
    return 0
}
