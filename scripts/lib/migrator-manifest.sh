# scripts/lib/migrator-manifest.sh — declarative manifest parser + dispatch
# engine for the BD-119 N→N+1 migrator framework.
#
# Sourced by `scripts/lib/migrator-core.sh` only. Adapters do NOT source
# this file directly — the engine is reached via the public API in
# migrator-core.sh. Every function here is internal and prefixed with
# `_manifest_` (framework convention for non-public surface).
#
# Responsibilities (architecture §3, §4.2; ARCHITECTURE-BD-119.md):
#   - Parse the TSV manifest the adapter emits via `migrator_manifest()`:
#       <pack-relpath>\t<project-relpath>\t<class>\t<action>
#     Actions: transform | add | remove | relocate-from <old-path>
#   - Validate trinity-parity (I5): if any of CLAUDE/AGENTS/GEMINI is
#     present, all three must be with matching class + action.
#   - Iterate entries and call `customization_preserve` per `transform`
#     row, additive write per `add`, no-op-with-report per `remove`,
#     git-mv-with-fallback per `relocate-from`.
#   - Drive the directory-sweep hook (`migrator_directory_sweeps`).
#
# This file is the C-2 SKELETON. Parser/validator/iterator are stubs that
# print `TODO: implement` to stderr and return non-zero. Bodies are filled
# in by C-4 (PLAN T-9).
#
# Do NOT add a shebang — this file is sourced, not executed.

# ── Manifest parser (filled in C-4 / PLAN T-9) ─────────────────────────────
#
# Reads the adapter's `migrator_manifest` stdout into an in-memory
# representation suitable for trinity-parity validation and iteration.
# bash 3.2 portable (no associative arrays); uses parallel indexed arrays.

_manifest_parse() {
    printf '_manifest_parse: TODO: implement (C-4 / PLAN T-9)\n' >&2
    return 1
}

# ── Trinity-parity validator (filled in C-4 / PLAN T-9) ────────────────────
#
# Architecture §6 I5: when any of CLAUDE.md / AGENTS.md / GEMINI.md
# appears as a manifest row, the other two must also appear with the same
# class + action. Errors before any mutation if violated.

_manifest_validate_trinity() {
    printf '_manifest_validate_trinity: TODO: implement (C-4 / PLAN T-9)\n' >&2
    return 1
}

# ── Iterator / dispatch engine (filled in C-4 / PLAN T-9) ──────────────────
#
# Walks parsed manifest entries and dispatches each to the appropriate
# action handler. Always-dispatch contract (M4): every entry goes through
# `customization_preserve` so the BD-088 truthful-report invariant holds.

_manifest_iterate() {
    printf '_manifest_iterate: TODO: implement (C-4 / PLAN T-9)\n' >&2
    return 1
}

# ── Directory-sweep iterator (filled in C-4 / PLAN T-9) ────────────────────
#
# Reads `migrator_directory_sweeps` output (`<pack-dir> <class>` rows) and
# dispatches each contained file with the declared class. Manifest-row
# precedence over sweep results when paths collide.

_manifest_sweep_directories() {
    printf '_manifest_sweep_directories: TODO: implement (C-4 / PLAN T-9)\n' >&2
    return 1
}
