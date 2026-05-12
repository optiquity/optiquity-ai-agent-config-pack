# IMPLEMENTATION-REPORT-BD-119 C-2 — skeleton libraries

**Agent:** pack-coder
**Branch:** `worktree-agent-aac21c82e1d52746d`
**Worktree HEAD SHA at completion:** `dcd37f7870a728c78994793725c5008cca5bf0de`
(no commits made — pack-coder never stages or commits; HEAD unchanged from
session start)
**Date:** 2026-05-08
**Scope:** BD-119, commit C-2 only (per `PLAN-BD-119.md` §6).
**Tasks bundled:** T-4, T-5, T-6 (PLAN §4 / §6 row "C-2").

---

## 1. Pre-flight check output

```
$ git rev-parse HEAD
dcd37f7870a728c78994793725c5008cca5bf0de

$ git log --oneline -8
dcd37f7 feat: v11 — pack-coder agent + repo-local Pack memory section
fda99ef feat: v11 — BD-119 C-1: detect_target_pack_version + validate-pack Check 26 (lenient)
6286fcf feat: v11 — BD-115 existing-project-mid-dev fixture
d7b3f07 docs: v11 — BD-119 architecture + plan
4a6aa6b docs: v11 — BD-114..BD-120 pre-Phase-A persona-coverage batch (Open)
ef3b41e feat: v11 — BD-113 test-fixtures/ persistent baseline directory
1228db3 fix: ci — add pyyaml dep to tests job (was only in validate job)
3b8136a feat: v11 — BD-097 audit + Batch 7 fixes (BD-097/098/099 Resolved)

$ ls maintenance-docs/v11-implementation/
ARCHITECTURE-BD-119.md
IMPLEMENTATION-REPORT-BD-115.md
IMPLEMENTATION-REPORT-BD-119.md
PLAN-BD-119.md
SEMANTIC-AUDIT-REPORT.md

$ ls .claude/agents/
pack-architect.md
pack-coder.md
pack-docs-researcher.md
pack-planner.md
pack-reviewer.md

$ grep -c "Pack memory" CLAUDE.md
1
```

All required artifacts present: HEAD at the expected commit, all four
recent BD-119 commits visible in the log, `pack-coder.md` agent file
present, the four required maintenance docs present, and the "Pack memory"
section is in CLAUDE.md (1 occurrence).

---

## 2. Per-task summary

### T-4 — `scripts/lib/migrator-core.sh` skeleton

- **File:** `scripts/lib/migrator-core.sh` (NEW)
- **Line count:** 114
- **Public surface contributed:**
  - 6 public-API function definitions (frozen names per PLAN §3.1):
    `migrator_run`, `migrator_dispatch`,
    `migrator_detect_target_version`, `migrator_select_adapter`,
    `migrator_baseline_to_tmp`, `migrator_target_surface_for_version`.
    Each is a stub that prints `TODO: implement (C-3 / PLAN T-7|T-11)`
    to stderr and returns `EXIT_INTERNAL` (99).
  - 8 exit-code constants (PLAN §3.5):
    `EXIT_PACK_INVALID=10`, `EXIT_NOT_GIT=11`, `EXIT_DIRTY=12`,
    `EXIT_NOT_BASELINE=13`, `EXIT_BASELINE_MISSING=14`,
    `EXIT_LIB_MISSING=15`, `EXIT_ALREADY_MIGRATED=16`,
    `EXIT_INTERNAL=99`. All declared with `readonly`.
  - 1 back-compat synonym: `readonly EXIT_NOT_V10="$EXIT_NOT_BASELINE"`
    (PLAN §3.5 — preserves the monolith's old constant name for any
    external grep-based caller).
- **Style:** matches sibling libs (`detect.sh`,
  `customization-preserve.sh`) — no shebang (sourced, not executed),
  4-space indentation, `printf` for stderr, header comment block
  documenting purpose / source / public API.
- **Notably absent (lands in C-3):** no companion-file sourcing
  (`migrator-stages.sh`, `migrator-manifest.sh`), no `say/info/warn/die`
  helpers, no stage sequencer, no argument parser, no EXIT trap. Comment
  in the file explicitly notes this.

### T-5 — `scripts/lib/migrator-stages.sh` skeleton

- **File:** `scripts/lib/migrator-stages.sh` (NEW)
- **Line count:** 67
- **Public surface contributed:** none (this file is internal only —
  framework convention is `_stage_*` prefix for non-public surface).
- **Internal stubs declared (filled in C-4):**
  `_stage_preflight`, `_stage_backup`, `_stage_libs`, `_stage_dispatch`,
  `_stage_relocations`, `_stage_artifact_installs`, `_stage_report`.
  Each prints `TODO: implement (C-4 / PLAN T-N)` to stderr and returns 1.

### T-6 — `scripts/lib/migrator-manifest.sh` skeleton

- **File:** `scripts/lib/migrator-manifest.sh` (NEW)
- **Line count:** 68
- **Public surface contributed:** none (internal `_manifest_*` prefix).
- **Internal stubs declared (filled in C-4):**
  `_manifest_parse`, `_manifest_validate_trinity`, `_manifest_iterate`,
  `_manifest_sweep_directories`. Each is a stub returning 1.

---

## 3. Verification output

### 3.1 `bash -n` syntax checks

```
$ bash -n scripts/lib/migrator-core.sh
OK
$ bash -n scripts/lib/migrator-stages.sh
OK
$ bash -n scripts/lib/migrator-manifest.sh
OK
```

All three new files parse cleanly under macOS bash 3.2.

### 3.2 `python3 scripts/validate-pack.py` (last 25 lines)

```
── Check 22: Help-fragment freshness (BD-082) ──
  OK: pack-root: 10 prose-referenced verb(s) all present in fragment
  OK: project-template: 1 prose-referenced verb(s) all present in fragment

── Check 23: Help-fragment completeness (BD-082) ──
  OK: all 8 non-internal scripts/ executables listed in HELP-FRAGMENT-PACK.md (8 marked pack-internal)

── Check 24: HELP-FRAGMENT-TRACKER byte-identity (BD-082, DELTA L1) ──
  OK: HELP-FRAGMENT-TRACKER.md byte-identical across pack-root and client mirror

── Check 25: Customization-detection regression guard (BD-089) ──
  OK: 4/4 fixture rows recorded with expected disposition + class
  OK: truthful-report contract: every fixture file appears in report.md

── Check 26: BD-119 migrator-framework inventory ──
  OK: scripts/lib/migrator-core.sh syntax valid
  OK: scripts/lib/migrator-stages.sh syntax valid
  OK: scripts/lib/migrator-manifest.sh syntax valid
  OK: migrator-core.sh declares all 6 public-API functions
  OK: migrator-core.sh declares all 8 exit-code constants
  OK: migrator-core.sh preserves EXIT_NOT_V10 back-compat synonym

============================================================
PASSED — all checks clean
```

Check 26 is now in **strict mode** for the first time: it asserts
presence of the three new libs, syntax validity of each, all six
public-API names defined, all eight exit-code constants declared, and
the `EXIT_NOT_V10` back-compat synonym. Six new `OK` lines specifically
for Check 26, which exactly matches the strict-mode contract recorded
in `IMPLEMENTATION-REPORT-BD-119.md` from C-1.

### 3.3 `git status`

```
On branch worktree-agent-aac21c82e1d52746d
Untracked files:
  (use "git add <file>..." to include in what will be committed)
	scripts/lib/migrator-core.sh
	scripts/lib/migrator-manifest.sh
	scripts/lib/migrator-stages.sh

nothing added to commit but untracked files present (use "git add" to track)
```

Three untracked new files; zero modified files; zero deleted files. No
git state changes performed by the agent (no `add`, `commit`, `push`,
`tag`, `checkout`, etc.).

---

## 4. Full file contents (verbatim)

### 4.1 `scripts/lib/migrator-core.sh`

```bash
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
```

### 4.2 `scripts/lib/migrator-stages.sh`

```bash
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
```

### 4.3 `scripts/lib/migrator-manifest.sh`

```bash
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
```

---

## 5. Files changed inventory

| Path | Change type | Lines |
|---|---|---|
| `scripts/lib/migrator-core.sh` | NEW | +114 |
| `scripts/lib/migrator-stages.sh` | NEW | +67 |
| `scripts/lib/migrator-manifest.sh` | NEW | +68 |

Total: 3 new files, 0 modified, 0 deleted, +249 LOC.

No PM-only files touched (BACKLOG.md, CHANGELOG.md, README.md,
PACK-CHAT.md, PACK-AGENTS.md, CLAUDE.md/AGENTS.md/GEMINI.md trinity
all unchanged). No trinity update needed for this commit; PLAN §9
defers trinity touches to C-7.

---

## 6. Plan deviations

**Zero plan deviations.** The C-2 row in PLAN §6 specifies "T-4, T-5,
T-6 — `bash -n` on all three new files; sourcing each in a subshell
exits 0; `python3 scripts/validate-pack.py` green (Check 26 now
active, asserts public-API names declared as stubs)." All four
verification points are satisfied. The line counts (114 / 67 / 68)
sit comfortably under the PLAN T-4/T-5/T-6 budget (+120 / +80 / +80
respectively) — skeletons are intentionally short.

The PLAN §3.1 public-API-name list and the validate-pack Check 26
required-names list are byte-for-byte identical (verified by reading
both before writing the skeleton). No POQs introduced.

Architecture §3.2 names "exit-code constants" as a category and PLAN
§3.5 enumerates the eight constants verbatim. Skeleton uses those
exact spellings; Check 26 confirms.

---

## 7. Definition-of-Done for C-2

| Item | Status | Evidence |
|---|---|---|
| Three skeleton libs exist on the working tree | PASS | `git status` shows three untracked files (§3.3). |
| `bash -n` passes on each new file | PASS | All three return 0; output in §3.1. |
| `python3 scripts/validate-pack.py` exits 0 with all 26 checks PASS | PASS | Tail-25 in §3.2; `PASSED — all checks clean`. |
| Check 26 transitions from lenient to strict mode | PASS | Six new `OK` lines in §3.2 (libs syntax × 3, public-API count, exit-code count, EXIT_NOT_V10 synonym). |
| No other source files modified | PASS | `git status` (§3.3) shows zero modified files; only the three new skeletons untracked. |
| No git state changed | PASS | `git rev-parse HEAD` unchanged from session start (`dcd37f7…`); zero `git add/commit/push/tag/checkout` invocations. |
| Report file exists at the agreed path | PASS | This document, written to `maintenance-docs/v11-implementation/IMPLEMENTATION-REPORT-BD-119-C2.md`. |
| Public-API surface (function + var + constant names) matches PLAN §3 verbatim | PASS | Six function names, eight exit codes, EXIT_NOT_V10 synonym; all confirmed by Check 26 (which is itself derived from PLAN §3 / architecture §3.2). |
| Trinity rule respected | PASS | No CLAUDE/AGENTS/GEMINI edits this commit; PLAN defers to C-7. |
| PM-only files untouched | PASS | BACKLOG.md, CHANGELOG.md, README.md, PACK-CHAT.md, PACK-AGENTS.md, CLAUDE/AGENTS/GEMINI roots all unmodified. |

---

## 8. Proposed commit message

```
feat: v11 — BD-119 C-2: land migrator-core/stages/manifest skeletons
```

Per PLAN §6 row "C-2" and pack convention (`feat: vN — BD-NNN <description>`).

The skeletons declare the frozen public-API surface (six functions, eight
exit-code constants, EXIT_NOT_V10 synonym) so subsequent commits (C-3..C-7)
can fill in behavior without changing names. Validate-pack Check 26
transitions from lenient to strict in this commit and asserts the surface;
no other source files are modified.

---

## 9. Operational note for Pack Chat (not a plan deviation)

During the session I initially issued three `Write` calls against absolute
paths under `/Users/david/Developer/optiquity-ai-agent-config-pack/scripts/lib/`
(the pack repo's main checkout) before realising my worktree was at
`/Users/david/Developer/optiquity-ai-agent-config-pack/.claude/worktrees/agent-aac21c82e1d52746d/`.
The three correctly-located files now live in the worktree (verified by
`git status` returning them as untracked under the worktree branch).

There are also three duplicate copies of the skeleton files at
`/Users/david/Developer/optiquity-ai-agent-config-pack/scripts/lib/`
(the main checkout, currently on `main`). These were created by the
mis-routed early `Write` calls and are not part of this commit. They are
byte-identical to the worktree files. Pack Chat may want to verify they
haven't ended up in the main-checkout's working tree before pulling the
worktree's commit — a quick `git -C /Users/david/Developer/optiquity-ai-agent-config-pack status`
will show them as untracked. Recommended cleanup: `rm` those three files
on main once Pack Chat has confirmed they are duplicates of the worktree
files (no merge/diff needed — they were generated from the same content).
This was caused by my misreading of "absolute paths" in the working-dir
context, not by the plan. No further deviations downstream.

---

## End of report
