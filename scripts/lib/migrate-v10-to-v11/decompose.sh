# scripts/lib/migrate-v10-to-v11/decompose.sh — adapter-private 6th sub-op
# of the v10→v11 migrator's `migrator_post_dispatch_hook`. Decomposes the
# just-installed v11-shape monolithic BACKLOG.md / CHANGELOG.md /
# IMPLEMENTATION-PLAN.md files into per-entry trees + regenerated mirrors
# under `docs/project/<stream>/`.
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
#     §4 (BD-095 two-phase contract bridge — this helper sets
#         PE_FORCE_OVERWRITE_MIRROR from _MIGRATOR_FORCE_OVERWRITE_MIRROR
#         before invoking the BD-164 mirror generator)
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
#       tree under `docs/project/<stream>/`, then regenerates the
#       mirror + TOC from the resulting tree. Idempotent: re-running
#       on an already-decomposed tree is a no-op (the decompose step
#       writes byte-identical per-entry files; the mirror regen
#       short-circuits on cmp-equal).
#
# Implementation contract:
#   - Sources `scripts/lib/per-entry/_lib.sh` + `decompose.sh` +
#     `mirror-generate.sh` + `toc-regenerate.sh` (the BD-164 helpers).
#     Does NOT reimplement decompose / mirror / TOC logic — that lives
#     in the BD-164 helpers and serves three call sites (this migrator
#     sub-op, init-project.sh greenfield path per BD-166, fixture
#     builder per BD-160 + BD-170).
#   - Skips streams whose monolithic input is absent (a v10 client
#     may have only a `BACKLOG.md` and never a `CHANGELOG.md`; a
#     greenfield v10 may have neither — both are valid pre-states).
#   - Honors `_MIGRATOR_FORCE_OVERWRITE_MIRROR` (set by the
#     `--force-overwrite-mirror` flag in `migrator-core.sh`'s parser)
#     by exporting `PE_FORCE_OVERWRITE_MIRROR` to match. This is the
#     Addendum #2 §4 bridge from the BD-095 mode flag to the BD-164
#     helpers' divergence-detection routing.
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
if ! type per_entry_regenerate_mirror >/dev/null 2>&1; then
    # shellcheck disable=SC1091
    . "$_v10_v11_decompose_lib_dir/mirror-generate.sh"
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
    say "── S5d (decompose) — BD-165 per-entry decomposition + mirror+TOC regenerate ──"

    # Bridge the BD-095 mode flag to the BD-164 helpers' divergence
    # routing (Addendum #2 §4). The mirror generator reads
    # PE_FORCE_OVERWRITE_MIRROR; the migrator's flag is
    # _MIGRATOR_FORCE_OVERWRITE_MIRROR; bridge them here so the BD-164
    # helpers do not need to know about the migrator-core internal
    # state-var convention. PE_FORCE_OVERWRITE_MIRROR=1 is the
    # explicit-overwrite signal; absence (or "0") is the default-block
    # signal. The mirror-generate.sh non-interactive routing reads
    # _MIGRATOR_MODE directly to select dry-run-report vs apply-block.
    if [[ "${_MIGRATOR_FORCE_OVERWRITE_MIRROR:-0}" == "1" ]]; then
        export PE_FORCE_OVERWRITE_MIRROR=1
    fi

    # Three project-side streams. Each tuple: stream_key + relative
    # mirror filename + relative stream directory. Pack-side streams
    # (pack-backlog / pack-changelog) are NOT decomposed by this
    # migrator — pack-self decomposition lands in Batch 22 dog-food
    # per ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §10.5 (last
    # paragraph). The v10→v11 client migrator only touches
    # docs/project/<stream>/.
    #
    # Per ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION.md §3.3 / §9.7 the
    # _rules.md / _intro.md / _format.md (project-changelog only)
    # supporting files were installed in the prior sub-op
    # (_v10_to_v11_install_v11_artifacts) at the BD-167 templates step
    # — verified by `ls scripts/migrate-v10-to-v11.sh:355-374`. The
    # decompose step relies on them being present.
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
            info "$stream_key: stream dir $stream_dir_rel not present (BD-167 templates not installed?) — skip"
            skipped_count=$((skipped_count + 1))
            continue
        fi

        # ── Decompose ──
        # The BD-164 decompose helper writes per-entry files under
        # $stream_dir/<id>.md with line-1 HTML-comment back-pointers
        # (Addendum #2 §2). Idempotent: same input → byte-identical
        # output.
        if ! per_entry_decompose "$stream_key" "$mirror_path" "$stream_dir"; then
            fail_stage S5 "S5d-decompose: per_entry_decompose failed for $stream_key (mirror=$mirror_rel, dir=$stream_dir_rel)"
        fi

        # ── Regenerate the mirror ──
        # The just-decomposed per-entry tree, when re-emitted by the
        # mirror generator, should produce a file byte-identical to
        # the input mirror (round-trip identity per integration
        # parent §6.2 + Addendum #1 §4.4). We invoke the regenerator
        # so the on-disk mirror picks up the back-pointer-stripping
        # pipeline and so future runs share the same "regenerated by
        # tooling" provenance. With force=on (or no prior divergence)
        # this is a no-op for byte-identical input; with force=off
        # and divergence the regenerator's apply-mode block returns
        # EXIT_GATE_FAILED — we treat that as fail_stage so the
        # operator sees the same recovery flow as a BD-101 gate
        # failure.
        local regen_rc=0
        per_entry_regenerate_mirror "$stream_key" "$stream_dir" "$mirror_path" </dev/null || regen_rc=$?
        if (( regen_rc != 0 )); then
            fail_stage S5 "S5d-decompose: per_entry_regenerate_mirror failed for $stream_key (rc=$regen_rc; mirror=$mirror_rel). If divergence-blocked, re-run with --force-overwrite-mirror to overwrite the hand-edited mirror."
        fi

        # ── Regenerate the TOC ──
        # Always-emitted, deterministic, idempotent (matches the
        # BD-164 contract per scripts/lib/per-entry/toc-regenerate.sh).
        if ! per_entry_regenerate_toc "$stream_key" "$stream_dir"; then
            fail_stage S5 "S5d-decompose: per_entry_regenerate_toc failed for $stream_key (dir=$stream_dir_rel)"
        fi

        info "$stream_key: decomposed $mirror_rel → $stream_dir_rel/ + regenerated mirror + TOC"
        decomposed_count=$((decomposed_count + 1))
    done

    info "BD-165 per-entry decomposition: $decomposed_count stream(s) decomposed, $skipped_count skipped"
}
