# scripts/lib/migrator-core.sh — orchestrator for the BD-119 N→N+1 migrator
# framework.
#
# Sourced by per-version adapters (e.g. `scripts/migrate-v10-to-v11.sh`) and by
# external harnesses (BD-114 `dry-run-real-ot.sh`). Adapters declare a small
# version-specific contract via `MIGRATOR_*` environment variables and a set
# of hook functions, then call `migrator_run "$@"`. Every shared safety
# concern (preflight, backup, three-way dispatch, report rendering, exit
# codes, dry-run, idempotency) lives here so per-version adapters can never
# regress the N→N+1 safety contract.
#
# Architecture: maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md
# Plan:         maintenance-docs/v11-implementation/PLAN-BD-119.md §3
#
# This file is the C-2 SKELETON. Function bodies are intentionally minimal:
# they print `TODO: implement` to stderr and return non-zero so any premature
# call surfaces a clear error. The public API surface (function names + env
# var names + exit-code constants) is FROZEN as of this commit — see PLAN
# §3 "Public surface lock-down". Subsequent commits (C-3..C-7) fill in
# behavior without changing names.
#
# Do NOT add a shebang — this file is sourced, not executed.

# ── Exit-code constants (PLAN §3.5; FROZEN) ────────────────────────────────
#
# Adapters reference these by name, never by literal value. Stage failures
# use the `20+N` formula owned by the core (see C-3).

readonly EXIT_PACK_INVALID=10
readonly EXIT_NOT_GIT=11
readonly EXIT_DIRTY=12
readonly EXIT_NOT_BASELINE=13
readonly EXIT_BASELINE_MISSING=14
readonly EXIT_LIB_MISSING=15
readonly EXIT_ALREADY_MIGRATED=16
readonly EXIT_INTERNAL=99

# Back-compat synonym — the monolithic v10→v11 migrator exposed
# `EXIT_NOT_V10`. Architecture §C1 / PLAN §3.5 require the rename to
# `EXIT_NOT_BASELINE` plus a synonym so any external caller that grepped the
# old name still resolves. Adapters SHOULD use `EXIT_NOT_BASELINE` directly.
readonly EXIT_NOT_V10="$EXIT_NOT_BASELINE"

# ── Public API (PLAN §3.1; FROZEN) ─────────────────────────────────────────
#
# Six functions form the public surface. Each is callable from adapters and
# from external harnesses. Names + arities are frozen for the duration of
# v11.x; renames require a new BD that explicitly amends BD-119.

# migrator_run "$@"
#   Full end-to-end migration with the calling adapter's declared contract.
#   Drives the stage sequencer; returns 0 on success or a documented exit
#   code on failure. Implemented in C-3 (PLAN T-7).
migrator_run() {
    printf 'migrator_run: TODO: implement (C-3 / PLAN T-7)\n' >&2
    return "$EXIT_INTERNAL"
}

# migrator_dispatch <target-dir>
#   Programmatic entry point — same effect as `migrator_run "$target-dir"`
#   but skips usage printing. Used by external harnesses (BD-114).
#   Implemented in C-3 (PLAN T-7).
migrator_dispatch() {
    printf 'migrator_dispatch: TODO: implement (C-3 / PLAN T-7)\n' >&2
    return "$EXIT_INTERNAL"
}

# migrator_detect_target_version <target-dir>
#   Echo the major pack version installed in the target (e.g. `v10`,
#   `v11`, `unknown`). Delegates to `detect_target_pack_version` from
#   `lib/detect.sh`. Implemented in C-3 (PLAN T-11).
migrator_detect_target_version() {
    printf 'migrator_detect_target_version: TODO: implement (C-3 / PLAN T-11)\n' >&2
    return "$EXIT_INTERNAL"
}

# migrator_select_adapter <from-version>
#   Echo the absolute path to `migrate-v<from>-to-v<from+1>.sh`. Errors if
#   no such adapter exists in the pack. Adapter discovery is glob-based
#   (PLAN OQ3 → glob). Implemented in C-3 (PLAN T-11).
migrator_select_adapter() {
    printf 'migrator_select_adapter: TODO: implement (C-3 / PLAN T-11)\n' >&2
    return "$EXIT_INTERNAL"
}

# migrator_baseline_to_tmp <pack-relpath> <tmpfile>
#   Side-effect helper: write the BASE blob (pack repo file at
#   `MIGRATOR_BASELINE_TAG`) into `<tmpfile>` for three-way dispatch.
#   Replaces the monolith's `v10_baseline_to_tmp`. Implemented in C-3
#   (PLAN T-11).
migrator_baseline_to_tmp() {
    printf 'migrator_baseline_to_tmp: TODO: implement (C-3 / PLAN T-11)\n' >&2
    return "$EXIT_INTERNAL"
}

# migrator_target_surface_for_version <vN>
#   Echo a newline-delimited list of project relative paths that a vN
#   install creates and that customization can target. Consumed by
#   BD-120 fixture parameterization. Implemented in C-3 (PLAN T-11).
migrator_target_surface_for_version() {
    printf 'migrator_target_surface_for_version: TODO: implement (C-3 / PLAN T-11)\n' >&2
    return "$EXIT_INTERNAL"
}

# ── Internal helpers (filled in by C-3 / C-4) ──────────────────────────────
#
# `say / info / warn / die / fail_stage`, the stage sequencer, argument
# parsing, the EXIT trap that guarantees a final report render, and the
# adapter-contract reader (`MIGRATOR_*` env vars + hook detection via
# `declare -F`) all land in C-3. The companion files
# `migrator-stages.sh` and `migrator-manifest.sh` are sourced from here at
# that point. The skeleton intentionally does not source them yet so this
# commit's `bash -n` and source-time semantics are independent of the
# sibling skeletons.
