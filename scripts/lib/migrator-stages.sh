# scripts/lib/migrator-stages.sh — per-stage implementations for the BD-119
# N→N+1 migrator framework.
#
# Sourced by `scripts/lib/migrator-core.sh` only. Adapters do NOT source
# this file directly — they go through the public API in migrator-core.sh.
# Every function here is an internal stage runner prefixed with `_stage_`
# (an underscore prefix is the framework's convention for "not part of
# the public surface").
#
# Stage order (architecture §6, ARCHITECTURE-BD-119.md):
#   _stage_preflight        — I1, I4, I8 (preflight + idempotency)
#   _stage_backup           — I2 (full-tree tar backup)
#   _stage_libs             — source three-way + customization-preserve
#   _stage_dispatch         — manifest-driven three-way per-file dispatch
#   _stage_relocations      — git-mv-with-fallback for `relocate-from`
#   _stage_artifact_installs— additive-only writes for `add` entries
#   _stage_report           — render report.md + post-report hook
#
# This file is the C-2 SKELETON. Stage functions are stubs that print
# `TODO: implement` to stderr and return non-zero so any premature call
# surfaces clearly. Bodies are filled in by C-4 (PLAN T-8, T-9, T-10).
#
# Do NOT add a shebang — this file is sourced, not executed.

# ── Preflight, backup, library setup (filled in C-4 / PLAN T-8) ────────────

_stage_preflight() {
    printf '_stage_preflight: TODO: implement (C-4 / PLAN T-8)\n' >&2
    return 1
}

_stage_backup() {
    printf '_stage_backup: TODO: implement (C-4 / PLAN T-8)\n' >&2
    return 1
}

_stage_libs() {
    printf '_stage_libs: TODO: implement (C-4 / PLAN T-8)\n' >&2
    return 1
}

# ── Manifest dispatch (filled in C-4 / PLAN T-9) ───────────────────────────
#
# The body lives in migrator-manifest.sh; this stage function is the named
# entry point the core's sequencer calls. Wiring lands at C-4.

_stage_dispatch() {
    printf '_stage_dispatch: TODO: implement (C-4 / PLAN T-9)\n' >&2
    return 1
}

# ── Relocation, artifact-install, report (filled in C-4 / PLAN T-10) ───────

_stage_relocations() {
    printf '_stage_relocations: TODO: implement (C-4 / PLAN T-10)\n' >&2
    return 1
}

_stage_artifact_installs() {
    printf '_stage_artifact_installs: TODO: implement (C-4 / PLAN T-10)\n' >&2
    return 1
}

_stage_report() {
    printf '_stage_report: TODO: implement (C-4 / PLAN T-10)\n' >&2
    return 1
}
