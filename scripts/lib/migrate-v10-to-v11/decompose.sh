# scripts/lib/migrate-v10-to-v11/decompose.sh — adapter-private 6th sub-op
# of the v10→v11 migrator's `migrator_post_dispatch_hook`. Decomposes the
# just-installed v11-shape monolithic BACKLOG.md / CHANGELOG.md /
# IMPLEMENTATION-PLAN.md files into per-entry trees + regenerated TOCs
# under `docs/project/<stream>/`, then DELETES each v10 source monolith
# after its decomposition is verified written. The per-entry tree +
# generated `_toc.md` is the sole source of truth + readable form; NO
# monolithic mirror is regenerated (BD-206 no-mirror model).
#
# Sourced by `scripts/migrate-v10-to-v11.sh` only. Not part of the
# BD-119 framework — adapter-scope, like `apply.sh` / `dry-run.sh` /
# `resume.sh` siblings under this directory.
#
# Architecture:
#   maintenance-docs/v11-research/ARCHITECTURE-PER-ENTRY-SPLIT.md
#     §1.3 (constraint statement: function name + placement)
#     §10.2 (post-dispatch hook is the right hook for this sub-op)
#   maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md
#     §3.1 (downgrade-to-constraint: 6th sub-op MUST run AFTER all 5
#           existing sub-ops so the decompose step reads the FINAL
#           v11-shape monolithic content)
#     §9.1 (hook integration restated for the planner)
#     §9.6 (sequencing inside the v10→v11 hook)
#     §9.7 (`_intro.md` and `_v8-resolved-archive.md` initial install)
#     §10.2 (helper location: this directory)
#     §18.1 #3, #4 (helper location + sequencing planner-deferred items
#                   resolved in this commit per plan §5.4)
#   maintenance-docs/v11-implementation/ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM-2.md
#     §6.4 (verify-by-`ls` for the per-entry helpers' location at
#           scripts/lib/per-entry/)
#   maintenance-docs/v11-implementation/PLAN-PER-ENTRY-SPLIT-BATCH-19.md
#     §5.4 (this commit's binding spec)
#
# Public API (sourced into the adapter's shell):
#   _v10_to_v11_decompose_streams
#       Adapter-private 6th sub-op. Iterates the three project-side
#       streams (backlog, implementation-plan, changelog), decomposes
#       each just-installed v11-shape monolithic file into a per-entry
#       tree under `docs/project/<stream>/`, regenerates the `_toc.md`
#       from the resulting tree, then DELETES the source monolith once
#       the per-entry tree is verified written (fail-safe: only after a
#       successful decompose + a present `_toc.md`). NO monolithic mirror
#       is regenerated (BD-206 no-mirror model). Idempotent: on a re-run
#       the source monolith is already gone, so the stream is skipped
#       (a no-op).
#
# Implementation contract:
#   - Sources `scripts/lib/per-entry/_lib.sh` + `decompose.sh` +
#     `toc-regenerate.sh` (the BD-164 helpers). Does NOT reimplement
#     decompose / TOC logic — that lives in the BD-164 helpers and
#     serves the per-entry tree generation paths.
#   - Skips streams whose monolithic input is absent (a v10 client
#     may have only a `BACKLOG.md` and never a `CHANGELOG.md`; a
#     greenfield v10 may have neither — both are valid pre-states).
#   - Reads each v10 monolith as DECOMPOSE INPUT, then DELETES it after
#     the per-entry tree + `_toc.md` are verified written (fail-safe).
#     It is never regenerated as a mirror (BD-206 no-mirror model).
#   - Emits `say` / `info` lines matching the prevailing adapter style
#     (see `_v10_to_v11_install_v11_artifacts` for the pattern).
#   - On any helper failure, calls `fail_stage S5` (the post-dispatch
#     hook fires inside the framework's S3 → S4 transition, but the
#     adapter's wording uses S4 / S5 sub-banners per the existing
#     `_v10_to_v11_*` precedent — this helper aligns with the S5
#     family because the BD-167 canonical templates install in S5).
#
# Bash 3.2 + macOS BSD utility compatible. NO associative arrays, NO
# `&>`, NO GNU-only flags.
#
# Do NOT add a shebang — this file is sourced, not executed.

# ── Source the BD-164 per-entry helpers ────────────────────────────────────
#
# The helpers live one level up at `scripts/lib/per-entry/`. This file is
# at `scripts/lib/migrate-v10-to-v11/decompose.sh` so the helpers' dir is
# `../per-entry/` relative to BASH_SOURCE.
#
# Guard each source with a `type` check so re-sourcing this file is a
# no-op (matches the per-entry helpers' own convention at
# scripts/lib/per-entry/decompose.sh:30-33).

_v10_v11_decompose_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../per-entry" && pwd)"

if ! type pe_die >/dev/null 2>&1; then
    # shellcheck disable=SC1091
    . "$_v10_v11_decompose_lib_dir/_lib.sh"
fi
if ! type per_entry_decompose >/dev/null 2>&1; then
    # shellcheck disable=SC1091
    . "$_v10_v11_decompose_lib_dir/decompose.sh"
fi
if ! type per_entry_regenerate_toc >/dev/null 2>&1; then
    # shellcheck disable=SC1091
    . "$_v10_v11_decompose_lib_dir/toc-regenerate.sh"
fi

# ── Adapter-private 6th sub-op ─────────────────────────────────────────────

_v10_to_v11_decompose_streams() {
    # Sub-banner per the BD-139 F-3 pattern (see
    # _v10_to_v11_relocate_legacy_docs at line 230 of
    # scripts/migrate-v10-to-v11.sh). The fail_stage call still uses
    # "S5" so the BD-095 sentinel filename + framework exit-code
    # formula stay stable; the failure-message prefix carries the
    # sub-stage tag ("S5d-decompose: ...") so operators can tell this
    # sub-op apart from S5 (artifact install), S5b (python-architecture
    # rename), and S5c (capability-token translation).
    say "── S5d (decompose) — per-entry decomposition + TOC regenerate ──"

    # Three project-side streams. Each tuple: stream_key + relative
    # monolith input filename + relative stream directory. Pack-side streams
    # (pack-backlog / pack-changelog) are NOT decomposed by this
    # migrator — pack-self decomposition lands in Batch 23 (BD-102)
    # dog-food per ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §10.5
    # (last paragraph). The v10→v11 client migrator only touches
    # docs/project/<stream>/.
    #
    # Per ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §3.3 / §9.7 the
    # _rules.md / _intro.md supporting files were installed in the
    # prior sub-op (_v10_to_v11_install_v11_artifacts) at the BD-167
    # templates step — verified by `ls scripts/migrate-v10-to-v11.sh:355-374`.
    # The decompose step relies on them being present.
    local stream_key mirror_rel stream_dir_rel mirror_path stream_dir
    local decomposed_count=0 skipped_count=0

    for spec in \
        "project-backlog|docs/project/BACKLOG.md|docs/project/backlog" \
        "project-implementation-plan|docs/project/IMPLEMENTATION-PLAN.md|docs/project/implementation-plan" \
        "project-changelog|docs/project/CHANGELOG.md|docs/project/changelog"; do
        stream_key="${spec%%|*}"
        local rest="${spec#*|}"
        mirror_rel="${rest%%|*}"
        stream_dir_rel="${rest##*|}"
        mirror_path="$_MIGRATOR_TARGET/$mirror_rel"
        stream_dir="$_MIGRATOR_TARGET/$stream_dir_rel"

        # Skip if the monolithic input is absent (greenfield-v10
        # client may have only a partial set; that's a valid pre-
        # state). Don't skip merely because the stream dir is
        # absent — the BD-167 install (S5) creates it; if absent
        # here something went wrong upstream.
        if [[ ! -f "$mirror_path" ]]; then
            info "$stream_key: no monolithic mirror at $mirror_rel — skip"
            skipped_count=$((skipped_count + 1))
            continue
        fi
        if [[ ! -d "$stream_dir" ]]; then
            info "$stream_key: stream dir $stream_dir_rel not present (templates not installed?) — skip"
            skipped_count=$((skipped_count + 1))
            continue
        fi

        # ── Decompose ──
        # The BD-164 decompose helper writes per-entry files under
        # $stream_dir/<id>.md with line-1 HTML-comment back-pointers
        # (Addendum #2 §2). Idempotent: same input → byte-identical
        # output.
        if ! per_entry_decompose "$stream_key" "$mirror_path" "$stream_dir"; then
            fail_stage S5 "S5d-decompose: per_entry_decompose failed for $stream_key (input=$mirror_rel, dir=$stream_dir_rel)"
        fi

        # ── Regenerate the TOC ──
        # Always-emitted, deterministic, idempotent (matches the
        # BD-164 contract per scripts/lib/per-entry/toc-regenerate.sh).
        # No monolithic mirror is regenerated — the per-entry tree +
        # generated `_toc.md` is the sole source of truth + readable
        # form (BD-206 no-mirror model). The v10 monolith was read as
        # decompose INPUT above; it is not re-emitted.
        if ! per_entry_regenerate_toc "$stream_key" "$stream_dir"; then
            fail_stage S5 "S5d-decompose: per_entry_regenerate_toc failed for $stream_key (dir=$stream_dir_rel)"
        fi

        # ── Delete the v10 source monolith (fail-safe) ──
        # Under the BD-206 no-mirror model the per-entry tree + generated
        # `_toc.md` is the sole source of truth + readable form; the v10
        # monolith was consumed as decompose INPUT and is now retired.
        # Delete it so no stale orphan monolith survives that the docs +
        # runtime advisory say no longer exists (MIGRATION-v10-to-v11.md
        # "Monolithic files are deleted"; the `fail-loud-delete-old-source`
        # rule — delete the old source so dangling refs break loudly).
        # Mirrors build.sh's `rm -f` after a successful decompose
        # (test-fixtures/build.sh, BD-206 decompose block).
        #
        # FAIL-SAFE: delete ONLY after the per-entry decomposition is
        # VERIFIED written. The real BD-164 helpers abort DIRECTLY via
        # `pe_die` (`exit 1`) on any internal error, so a failing
        # `per_entry_decompose` / `per_entry_regenerate_toc` never returns
        # to this loop at all; the `if ! …; then fail_stage S5` wrappers
        # above are a defensive backstop for a non-`pe_die` failure path
        # (a helper that RETURNS non-zero instead of exiting — e.g. the
        # stubbed/alternate helpers the fail-safe test drives). Either
        # way, reaching here already proves each sub-op returned 0. As a
        # belt-and-suspenders guard the regenerated `_toc.md` readable-
        # form index MUST also be present. If it is absent the tree is
        # unverified/partial — refuse to delete so client data is never
        # destroyed with no per-entry backing (a failed/partial decompose
        # leaves the source monolith intact).
        if [[ ! -f "$stream_dir/_toc.md" ]]; then
            fail_stage S5 "S5d-decompose: refusing to delete $mirror_rel — regenerated _toc.md absent at $stream_dir_rel/ (unverified decompose; source monolith preserved)"
        fi
        rm -f "$mirror_path"

        info "$stream_key: decomposed $mirror_rel → $stream_dir_rel/ + regenerated TOC; deleted source monolith $mirror_rel"
        decomposed_count=$((decomposed_count + 1))
    done

    info "per-entry decomposition: $decomposed_count stream(s) decomposed, $skipped_count skipped"
}
