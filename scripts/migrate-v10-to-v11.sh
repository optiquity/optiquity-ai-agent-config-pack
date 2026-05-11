#!/usr/bin/env bash
# migrate-v10-to-v11.sh — v10 → v11 migrator. Adapter against migrator-core.sh.
#
# This is a thin per-version adapter on the BD-119 migrator framework
# (`scripts/lib/migrator-core.sh` + `migrator-stages.sh` +
# `migrator-manifest.sh`). All shared safety concerns — preflight, backup,
# state-dir hygiene, three-way dispatch via BD-088, report rendering,
# exit codes — live in the framework. This file declares only what is
# v10→v11-specific.
#
# Replaces the pre-BD-119 monolith (refactor at BD-119 C-6).
#
# Design rationale, contract, and adapter-authoring rules:
#   maintenance-docs/v11-implementation/ARCHITECTURE-BD-119.md
# Implementation plan + verification recipe:
#   maintenance-docs/v11-implementation/PLAN-BD-119.md
# A future migrate-v11-to-v12.sh is the same shape as this file: declare
# the MIGRATOR_* contract + the small set of hook functions, then source
# the framework and call migrator_run "$@".
#
# Architectural note on hook usage:
#
# The v10→v11 transition's post-dispatch work (BD-042 legacy-doc
# relocation; additive install of v11 artifacts like HELP-FRAGMENT,
# tracker.toml.example — sourced from
# project-template/tracker.toml.project-example,
# ISSUE_TEMPLATE forms, per-CLI pack-help, and the
# bare scripts/pack-help.sh + scripts/lib/detect.sh files) is performed
# inside `migrator_post_dispatch_hook` rather than via the framework's
# declarative `migrator_relocations` / `migrator_artifact_installs`
# hooks. Two reasons:
#   1. The pre-BD-119 monolith printed v10→v11-specific banners
#      ("── S4 — BD-042 relocation of legacy root docs (if any) ──",
#      "── S5 — install v11 client artifacts ──") and never recorded
#      additive installs into the BD-088 dispositions TSV. The
#      behavior-preservation harness (PLAN-BD-119.md §8) gates C-6 on
#      byte-equivalent stdout + report.md, which means the adapter
#      reproduces that wording and that no-record semantics exactly.
#   2. The framework's declarative hooks correctly record dispositions
#      (architecture §4.3, structural payoff M9). For a future v11→v12
#      adapter, using the declarative hooks is the right call. v10→v11
#      stays on `migrator_post_dispatch_hook` for backward compatibility.
#
# Usage:
#     PACK=/path/to/pack ./scripts/migrate-v10-to-v11.sh [target-dir] [mode-flag]
#
# Modes (BD-095 two-phase workflow):
#     --dry-run   Preview only; writes report + dispositions + a fingerprint
#                 the apply mode will check. No project files are mutated.
#     --apply     Default. Refuses to run unless a fresh (<24h) dry-run
#                 fingerprint exists for the current working tree (§6.G).
#                 Pauses cleanly before S4 if dispatch produces sidecars
#                 the user must reconcile.
#     --resume    Continues a paused --apply after sidecar reconciliation.
#                 Forward-only (§6.H). Accepts both `.resolved` flag-files
#                 AND extension removal as conflict-resolution signals.
#     <bare>      Backwards-compat: equivalent to --apply, BUT auto-runs
#                 --dry-run first if no fresh dry-run output exists. Users
#                 of pre-BD-095 invocations do not need to learn the new
#                 flags for the no-conflict path.
#
# Exit codes are inherited from the framework
# (`scripts/lib/migrator-core.sh`). The pre-refactor `EXIT_NOT_V10=13` is
# preserved as a synonym of `EXIT_NOT_BASELINE=13` per
# ARCHITECTURE-BD-119.md §C1 / PLAN §3.5.

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Adapter-declared contract (read by migrator-core.sh) ───────────────────

MIGRATOR_FROM_VERSION="v10"
MIGRATOR_TO_VERSION="v11"
MIGRATOR_BASELINE_TAG="${V10_TAG:-v10}"
MIGRATOR_OWN_SIDECAR_SUFFIX="v10-customized"
# Prior-version sidecar suffixes the framework's preflight refuses to
# coexist with. Mirrors the monolith's stale-sidecar refusal at lines
# 99–108 (only `.pre-update`, the suffix `init-project.sh --update` writes).
MIGRATOR_PRIOR_SIDECAR_SUFFIXES=("pre-update")

# ── Hooks ──────────────────────────────────────────────────────────────────

# migrator_manifest — TSV of per-file v10→v11 transformations. Mirrors the
# monolith's S3 explicit-entry list (lines 185–200). One row per file:
#     <pack-relpath>\t<project-relpath>\t<class>\t<action>
# Trinity files (CLAUDE / AGENTS / GEMINI) ship with identical class +
# action so the framework's I5 trinity-parity validator succeeds.
migrator_manifest() {
    cat <<'EOF'
project-template/CLAUDE.md	CLAUDE.md	trinity	transform
project-template/AGENTS.md	AGENTS.md	trinity	transform
project-template/GEMINI.md	GEMINI.md	trinity	transform
project-template/.claude/settings.json	.claude/settings.json	claude-settings	transform
project-template/.mcp.json.example	.mcp.json.example	claude-mcp-example	transform
project-template/.codex/config.toml	.codex/config.toml	codex-config	transform
project-template/.codex/config.toml.example	.codex/config.toml.example	codex-config-example	transform
project-template/.codex/requirements.toml	.codex/requirements.toml	codex-config	transform
project-template/.gemini/.env.example	.gemini/.env	gemini-env	transform
project-template/.gemini/settings.json	.gemini/settings.json	claude-settings	transform
project-template/docs/pack/PM-CHAT.md	docs/pack/PM-CHAT.md	pm-chat	transform
project-template/docs/pack/PLATFORM-SKILLS.md	docs/pack/PLATFORM-SKILLS.md	generic	transform
project-template/docs/pack/PACK-FEEDBACK.md	docs/pack/PACK-FEEDBACK.md	generic	transform
project-template/docs/pack/PROMPT-TEMPLATES.md	docs/pack/PROMPT-TEMPLATES.md	generic	transform
EOF
}

# migrator_directory_sweeps — `<pack-dir> <class>` rows for whole-directory
# iteration. Mirrors the monolith's S3 _stage_s3_iter_dir invocations at
# lines 226–231 (one for `scripts/`, three for the per-CLI agents/ dirs).
migrator_directory_sweeps() {
    cat <<'EOF'
project-template/scripts pack-script
project-template/.claude/agents pack-agent
project-template/.codex/agents pack-agent
project-template/.gemini/agents pack-agent
EOF
}

# migrator_relocations — empty. The v10→v11 BD-042 legacy-doc relocation
# is performed inside migrator_post_dispatch_hook with monolith-faithful
# wording (see the architectural note at the top of this file).
migrator_relocations() { :; }

# migrator_artifact_installs — empty. The v11-specific additive installs
# are performed inside migrator_post_dispatch_hook with monolith-faithful
# silent (no-record) semantics (see the architectural note).
migrator_artifact_installs() { :; }

# migrator_post_dispatch_hook — runs between the framework's S3 dispatch
# and S4 relocations stages. We use this hook to perform both S4 and S5
# in a single unit so the adapter retains the exact stdout + report.md
# shape the pre-refactor monolith produced.
migrator_post_dispatch_hook() {
    # In --dry-run mode the framework's stage helpers short-circuit
    # writes; the adapter's hook must do the same so BD-095 can rely on
    # a true dry-run for the fingerprint comparator. The pre-BD-095
    # invariant (single-shot only) made this gate unnecessary; with
    # BD-095 the gate is required.
    if _migrator_is_dryrun; then
        info "[dry-run] would run BD-104 rename + BD-042 relocation + v11 artifact install + python-architecture skill rename"
        return 0
    fi
    _v10_to_v11_rename_implementation_plan
    _v10_to_v11_relocate_legacy_docs
    _v10_to_v11_install_v11_artifacts
    _v10_to_v11_rename_python_architecture_refs
}

# Internal: BD-104 cross-pack rename of the client's IMPLEMENTATION_PLAN.md
# (underscore form) to IMPLEMENTATION-PLAN.md (hyphenated form). v11
# adopts the hyphenated all-caps convention for project state docs; the
# rename happens once, history-preserving, on every v10→v11 migration.
#
# Behavior:
#   - No-op if the source file does not exist (project never had one,
#     or the project-side adoption already happened out-of-band).
#   - Collision case (both old and new names present at the target root):
#     surface the typed error `migration-rename-collision` per BD-070 /
#     ARCHITECTURE.md §2.5 contract format (ERROR/MESSAGE/→ Run lines
#     to stderr) and fail the stage. The user resolves by inspecting
#     both files and deleting / merging before re-running.
#   - Tracked source: `git mv` (history-preserving). Untracked source
#     fallback: plain `mv` (matches the BD-042 _v10_to_v11_relocate_legacy_docs
#     pattern at lines 142–147 above).
_v10_to_v11_rename_implementation_plan() {
    # BD-139 F-3: sub-banner "S4a (rename)" disambiguates from the
    # BD-042 relocation that also runs inside migrator_post_dispatch_hook.
    # The fail_stage call still uses "S4" so the BD-095 sentinel filename
    # (`stage-S4.done`) and the framework exit-code formula (24 = 20+4)
    # remain stable; the failure-message prefix carries the sub-stage tag
    # ("S4a-rename: ...") so operators can tell rename vs. relocate apart
    # in a fail_stage report.
    say "── S4a (rename) — BD-104 rename IMPLEMENTATION_PLAN.md → IMPLEMENTATION-PLAN.md ──"
    local src="$_MIGRATOR_TARGET/IMPLEMENTATION_PLAN.md"
    local dst="$_MIGRATOR_TARGET/IMPLEMENTATION-PLAN.md"
    if [[ ! -f "$src" ]]; then
        info "no IMPLEMENTATION_PLAN.md at target root — nothing to rename"
        return 0
    fi
    if [[ -f "$dst" ]]; then
        # Typed-error block per BD-070 / tracker-errors.sh format. Emitted
        # directly here rather than via tracker_error_emit because the
        # `migration-rename-collision` code is migrator-scoped, not part
        # of the tracker provider's V1 §2.5 ten-code surface.
        {
            printf 'ERROR: %s\n' "migration-rename-collision"
            printf 'MESSAGE: %s\n' \
                "both IMPLEMENTATION_PLAN.md and IMPLEMENTATION-PLAN.md exist at $_MIGRATOR_TARGET"
            printf '%s\n' \
                "  source: $src" \
                "  target: $dst" \
                "v11 expects only IMPLEMENTATION-PLAN.md (hyphenated). Inspect both" \
                "files; delete or merge whichever is stale; then re-run the migration."
            printf '→ Run: %s\n' "inspect both files, resolve, then re-run migrate-v10-to-v11.sh"
        } >&2
        fail_stage S4 "S4a-rename: collision: $dst already exists"
    fi
    local mv_stderr
    mv_stderr=$(git -C "$_MIGRATOR_TARGET" mv "IMPLEMENTATION_PLAN.md" "IMPLEMENTATION-PLAN.md" 2>&1) || {
        if [[ "$mv_stderr" == *"not under version control"* \
           || "$mv_stderr" == *"did not match"* ]]; then
            # BD-139 F-4: surface the captured git-mv stderr so operators
            # can distinguish the two fallback-trigger sentinels (and any
            # third-class git-mv message that happens to match either
            # substring) when diagnosing why the fallback fired.
            info "git mv hint (taking untracked-fallback branch): $mv_stderr"
            mv "$src" "$dst"
            info "renamed (untracked): IMPLEMENTATION_PLAN.md → IMPLEMENTATION-PLAN.md"
            return 0
        else
            fail_stage S4 "S4a-rename: git mv IMPLEMENTATION_PLAN.md → IMPLEMENTATION-PLAN.md failed: $mv_stderr"
        fi
    }
    [[ -f "$dst" ]] \
        || fail_stage S4 "S4a-rename: post-rename verification failed: IMPLEMENTATION-PLAN.md missing"
    info "renamed: IMPLEMENTATION_PLAN.md → IMPLEMENTATION-PLAN.md"
}

# Internal: BD-042 relocation of legacy v9-era root docs to docs/pack/.
# Mirrors monolith stage_s4_bd042_relocation (lines 261–301). git-mv
# first, plain `mv` fallback for untracked sources, sidecar-the-root
# branch when both root and docs/pack/ have the file. The framework's
# `say`/`info`/`fail_stage` helpers are inherited from migrator-core.sh.
_v10_to_v11_relocate_legacy_docs() {
    # BD-139 F-3: sub-banner "S4b (relocate)" disambiguates from the
    # BD-104 rename above. fail_stage call still uses "S4" so the
    # BD-095 sentinel filename and exit-code formula stay stable.
    say "── S4b (relocate) — BD-042 relocation of legacy root docs (if any) ──"
    local moved=0
    local f
    for f in METHODOLOGY.md PROMPT-TEMPLATES.md PM-CHAT.md \
             PLATFORM-SKILLS.md PACK-FEEDBACK.md; do
        if [[ -f "$_MIGRATOR_TARGET/$f" ]]; then
            mkdir -p "$_MIGRATOR_TARGET/docs/pack"
            if [[ -f "$_MIGRATOR_TARGET/docs/pack/$f" ]]; then
                mv "$_MIGRATOR_TARGET/$f" \
                   "$_MIGRATOR_TARGET/$f.relocated-from-root"
                info "relocated: $f → $f.relocated-from-root (docs/pack/$f already present)"
            else
                local mv_stderr untracked=0
                mv_stderr=$(git -C "$_MIGRATOR_TARGET" mv "$f" "docs/pack/$f" 2>&1) || {
                    if [[ "$mv_stderr" == *"not under version control"* \
                       || "$mv_stderr" == *"did not match"* ]]; then
                        mv "$_MIGRATOR_TARGET/$f" "$_MIGRATOR_TARGET/docs/pack/$f"
                        untracked=1
                    else
                        fail_stage S4 "S4b-relocate: git mv $f → docs/pack/$f failed: $mv_stderr"
                    fi
                }
                [[ -f "$_MIGRATOR_TARGET/docs/pack/$f" ]] \
                    || fail_stage S4 "S4b-relocate: post-relocation verification failed: docs/pack/$f missing"
                if (( untracked == 1 )); then
                    info "relocated (untracked): $f → docs/pack/$f"
                else
                    info "relocated: $f → docs/pack/$f"
                fi
            fi
            moved=$((moved + 1))
        fi
    done
    info "BD-042 relocation: $moved legacy doc(s) moved"
}

# Internal: v11 artifact install. Mirrors monolith stage_s5_v11_artifacts
# (lines 305–370). Plain `cp` with no BD-088 disposition record so the
# behavior-preservation harness's report.md A3 axis stays clean (the
# pre-refactor monolith never recorded these).
_v10_to_v11_install_v11_artifacts() {
    say "── S5 — install v11 client artifacts ──"

    # HELP-FRAGMENT*.md
    mkdir -p "$_MIGRATOR_TARGET/docs/pack"
    local help_src
    for help_src in HELP-FRAGMENT.md HELP-FRAGMENT-TRACKER.md; do
        local pack_file="$PACK/project-template/docs/pack/$help_src"
        if [[ -f "$pack_file" && ! -f "$_MIGRATOR_TARGET/docs/pack/$help_src" ]]; then
            cp "$pack_file" "$_MIGRATOR_TARGET/docs/pack/$help_src"
        fi
    done

    # tracker.toml.example
    #   Source: project-template/tracker.toml.project-example (BD-135).
    #   Destination basename remains tracker.toml.example client-side.
    if [[ -f "$PACK/project-template/tracker.toml.project-example" \
       && ! -f "$_MIGRATOR_TARGET/tracker.toml.example" ]]; then
        cp "$PACK/project-template/tracker.toml.project-example" \
            "$_MIGRATOR_TARGET/tracker.toml.example"
    fi

    # .github/ISSUE_TEMPLATE/*
    if [[ -d "$PACK/project-template/.github/ISSUE_TEMPLATE" ]]; then
        mkdir -p "$_MIGRATOR_TARGET/.github/ISSUE_TEMPLATE"
        local form
        for form in "$PACK/project-template/.github/ISSUE_TEMPLATE"/*.yml; do
            [[ -e "$form" ]] || continue
            local name; name=$(basename "$form")
            [[ -f "$_MIGRATOR_TARGET/.github/ISSUE_TEMPLATE/$name" ]] && continue
            cp "$form" "$_MIGRATOR_TARGET/.github/ISSUE_TEMPLATE/$name"
        done
    fi

    # Per-CLI pack-help surfaces.
    if [[ -d "$PACK/project-template/.claude/skills/pack-help" \
       && ! -f "$_MIGRATOR_TARGET/.claude/skills/pack-help/SKILL.md" ]]; then
        mkdir -p "$_MIGRATOR_TARGET/.claude/skills/pack-help"
        cp "$PACK/project-template/.claude/skills/pack-help/SKILL.md" \
            "$_MIGRATOR_TARGET/.claude/skills/pack-help/SKILL.md"
    fi
    if [[ -d "$PACK/project-template/.codex/skills/pack-help" \
       && ! -f "$_MIGRATOR_TARGET/.codex/skills/pack-help/SKILL.md" ]]; then
        mkdir -p "$_MIGRATOR_TARGET/.codex/skills/pack-help"
        cp "$PACK/project-template/.codex/skills/pack-help/SKILL.md" \
            "$_MIGRATOR_TARGET/.codex/skills/pack-help/SKILL.md"
    fi
    if [[ -f "$PACK/project-template/.gemini/commands/pack-help.toml" \
       && ! -f "$_MIGRATOR_TARGET/.gemini/commands/pack-help.toml" ]]; then
        mkdir -p "$_MIGRATOR_TARGET/.gemini/commands"
        cp "$PACK/project-template/.gemini/commands/pack-help.toml" \
            "$_MIGRATOR_TARGET/.gemini/commands/pack-help.toml"
    fi

    # The pack-help shell script + its single dep (lib/detect.sh) — BD-097
    # audit B-1 documented this as required because the per-CLI surfaces
    # invoke `bash scripts/pack-help.sh` relative to the project.
    mkdir -p "$_MIGRATOR_TARGET/scripts/lib"
    if [[ -f "$PACK/scripts/pack-help.sh" \
       && ! -f "$_MIGRATOR_TARGET/scripts/pack-help.sh" ]]; then
        cp "$PACK/scripts/pack-help.sh" "$_MIGRATOR_TARGET/scripts/pack-help.sh"
        chmod +x "$_MIGRATOR_TARGET/scripts/pack-help.sh"
    fi
    if [[ -f "$PACK/scripts/lib/detect.sh" \
       && ! -f "$_MIGRATOR_TARGET/scripts/lib/detect.sh" ]]; then
        cp "$PACK/scripts/lib/detect.sh" "$_MIGRATOR_TARGET/scripts/lib/detect.sh"
    fi
}

# Internal: BD-035-split client-side rename of `python-architecture`
# references to the post-split skill names (`python-server-architecture`
# / `python-data-architecture`).
#
# The v10.x `python-architecture` skill was split in v11 (BD-035) into
# `python-server-architecture` (servicers, grpc.aio handlers, server
# interceptors, background tasks) and `python-data-architecture`
# (repository pattern, N+1, Pydantic placement, ML isolation).
#
# This step scans the client's PLATFORM-SKILLS.md and CLAUDE.md /
# AGENTS.md / GEMINI.md (project root + project-template/) for stale
# `python-architecture` tokens introduced before the split and rewrites
# them in-place when the surrounding context is unambiguous. Ambiguous
# cases (single tokens in custom prose, comments, etc.) get an entry in
# a sidecar advisory file at the v11 sidecar suffix so the user can
# reconcile by hand.
#
# The rewrite is conservative: only the bare token `python-architecture`
# is rewritten, only when the line ALSO contains another server- or
# data-tier signal that disambiguates. Files are visited in a fixed
# order; per-file changes are recorded in a single advisory file under
# the migrator state dir.
#
# Files scanned (project-root-relative; only those that exist):
#   docs/pack/PLATFORM-SKILLS.md
#   CLAUDE.md, AGENTS.md, GEMINI.md
#
# Disambiguation rules (per-line):
#   1. Line contains `python-server-architecture` already → rewrite
#      stale `python-architecture` to `python-server-architecture`.
#   2. Line contains `python-data-architecture` already → rewrite
#      stale `python-architecture` to `python-data-architecture`.
#   3. Line contains another server-tier signal (`grpc-patterns`,
#      `deployment-python`, `Python server`, `python-server`) AND
#      no data-tier signal → rewrite to `python-server-architecture`.
#   4. Line contains a data-tier signal (`repository`, `N+1`,
#      `Pydantic`, `data / I/O`) AND no server-tier signal → rewrite
#      to `python-data-architecture`.
#   5. Otherwise → record an ambiguous-rename advisory entry; leave
#      the file untouched at this site.
#
# Advisory output: $_MIGRATOR_STATE_DIR/python-architecture-rename.advisory
# (created only when at least one ambiguous site is found). The advisory
# enumerates file:line pairs the user should reconcile by hand. The
# customization-preserve sidecar contract is intentionally NOT used
# here because none of the files in scope are customization-preserve
# managed at this point in the migration (PLATFORM-SKILLS.md is a
# `transform` target; the trinity files are `trinity` transforms; the
# v10→v11 transform pipeline has already replaced their pack-managed
# content). The advisory file is the canonical user-facing surface.
_v10_to_v11_rename_python_architecture_refs() {
    say "── S5b — BD-035 split: rename stale python-architecture refs ──"

    local advisory="$_MIGRATOR_STATE_DIR/python-architecture-rename.advisory"
    local rewrites=0
    local ambiguous=0
    local f rel
    local files=(
        "docs/pack/PLATFORM-SKILLS.md"
        "CLAUDE.md"
        "AGENTS.md"
        "GEMINI.md"
    )

    for rel in "${files[@]}"; do
        f="$_MIGRATOR_TARGET/$rel"
        [[ -f "$f" ]] || continue
        # Skip if the file has no stale references (cheap fast path).
        grep -q '\bpython-architecture\b' "$f" || continue

        local tmp linenum=0 line
        tmp=$(mktemp -t pack-py-arch-rename.XXXXXX) || \
            fail_stage S5 "S5b-rename: mktemp failed for $rel"
        # Read line-by-line. Per-line decision per the rules above.
        # The file is read once; rewrites are applied in the same pass
        # and written back atomically via mv.
        while IFS= read -r line || [[ -n "$line" ]]; do
            linenum=$((linenum + 1))
            if [[ "$line" != *"python-architecture"* ]]; then
                printf '%s\n' "$line" >>"$tmp"
                continue
            fi
            # Ignore lines that already mention only post-split names
            # (e.g., `python-server-architecture` matches the substring
            # `python-architecture` — exclude those from rewrite by
            # checking the bare-token form via word boundaries).
            if ! printf '%s' "$line" | grep -qE '(^|[^-])python-architecture([^-]|$)'; then
                printf '%s\n' "$line" >>"$tmp"
                continue
            fi
            local has_server=0 has_data=0 new_token=""
            [[ "$line" == *"python-server-architecture"* ]] && has_server=1
            [[ "$line" == *"python-data-architecture"* ]] && has_data=1
            if (( has_server == 1 && has_data == 0 )); then
                new_token="python-server-architecture"
            elif (( has_data == 1 && has_server == 0 )); then
                new_token="python-data-architecture"
            else
                # Look for other-token disambiguators on the same line.
                local server_signal=0 data_signal=0
                if printf '%s' "$line" | grep -qE 'grpc-patterns|deployment-python|Python server|python-server|gRPC servicer|grpc\.aio|interceptor'; then
                    server_signal=1
                fi
                if printf '%s' "$line" | grep -qE 'repository|N\+1|Pydantic|data ?/ ?I/O|data and I/O|ML inference'; then
                    data_signal=1
                fi
                if (( server_signal == 1 && data_signal == 0 )); then
                    new_token="python-server-architecture"
                elif (( data_signal == 1 && server_signal == 0 )); then
                    new_token="python-data-architecture"
                fi
            fi
            if [[ -n "$new_token" ]]; then
                # Replace only the bare-token form; leave any pre-existing
                # post-split occurrences intact.
                printf '%s\n' "$line" \
                    | sed "s/\\([^-]\\)python-architecture\\([^-]\\)/\\1${new_token}\\2/g; s/^python-architecture\\([^-]\\)/${new_token}\\1/g; s/\\([^-]\\)python-architecture$/\\1${new_token}/g; s/^python-architecture$/${new_token}/g" \
                    >>"$tmp"
                rewrites=$((rewrites + 1))
            else
                # Ambiguous: keep the line as-is and queue an advisory entry.
                printf '%s\n' "$line" >>"$tmp"
                if (( ambiguous == 0 )); then
                    {
                        printf '# python-architecture skill-rename advisory (BD-035 split)\n'
                        printf '#\n'
                        printf '# The v10.x `python-architecture` skill was split in v11 into\n'
                        printf '# `python-server-architecture` and `python-data-architecture`.\n'
                        printf '# The migrator could not unambiguously rewrite the references\n'
                        printf '# below. Inspect each line and rename to the appropriate\n'
                        printf '# post-split skill name by hand.\n'
                        printf '#\n'
                        printf '# Format: <file>:<line>: <text>\n'
                        printf '\n'
                    } >"$advisory"
                fi
                printf '%s:%d: %s\n' "$rel" "$linenum" "$line" >>"$advisory"
                ambiguous=$((ambiguous + 1))
            fi
        done <"$f"

        if ! mv "$tmp" "$f"; then
            rm -f "$tmp"
            fail_stage S5 "S5b-rename: failed to write rewritten $rel"
        fi
        info "scanned $rel for python-architecture rename"
    done

    if (( rewrites > 0 )); then
        info "BD-035 rename: $rewrites unambiguous reference(s) rewritten in place"
    else
        info "BD-035 rename: no unambiguous references found to rewrite"
    fi
    if (( ambiguous > 0 )); then
        info "BD-035 rename: $ambiguous ambiguous reference(s) recorded in $advisory"
        info "review the advisory and rename by hand before treating the migration as complete"
    fi
}

# migrator_post_report_hook — version-specific guidance text printed after
# the report is rendered. v10→v11 points users at `pack tracker init` for
# the opt-in tracker integration. Mirrors the monolith's stage_s6_report
# tail at lines 401–403.
migrator_post_report_hook() {
    say ""
    say "To opt into the v11 issue-tracker integration, run:"
    say "  pack tracker init"
}

# ── Source the framework + run ─────────────────────────────────────────────

# Source the framework via SCRIPT_DIR — the lib lives in the same pack as
# this adapter, so we do NOT need $PACK to be set just to source it. This
# preserves `--help` / unknown-option behavior even when PACK is unset, and
# lets the framework's `_stage_preflight` enforce the documented
# `EXIT_PACK_INVALID=10` path (architecture §3.2 invariant I1) when the
# user actually attempts a migration without exporting PACK.
#
# Do NOT auto-resolve PACK here. The architecture/PLAN treat unset PACK as
# a fatal preflight, not a recoverable default; substituting a fallback
# silently breaks the documented exit-code contract.

# shellcheck source=lib/migrator-core.sh disable=SC1091
. "$SCRIPT_DIR/lib/migrator-core.sh"

# ── BD-095 two-phase mode dispatch ─────────────────────────────────────────
#
# The three mode libs sit under scripts/lib/migrate-v10-to-v11/. dry-run.sh
# stamps a fingerprint, apply.sh enforces freshness + sentinel-based
# pause/resume, resume.sh continues a paused run after sidecar
# reconciliation. Each lib exposes a `migrate_v10_to_v11_<mode>_run`
# function that wraps `migrator_run` with the mode-specific concerns.
#
# We parse the FIRST `--<mode>` flag here and dispatch. The framework's
# arg parser still validates other flags + positional args downstream.

# shellcheck source=lib/migrate-v10-to-v11/dry-run.sh disable=SC1091
. "$SCRIPT_DIR/lib/migrate-v10-to-v11/dry-run.sh"
# shellcheck source=lib/migrate-v10-to-v11/apply.sh disable=SC1091
. "$SCRIPT_DIR/lib/migrate-v10-to-v11/apply.sh"
# shellcheck source=lib/migrate-v10-to-v11/resume.sh disable=SC1091
. "$SCRIPT_DIR/lib/migrate-v10-to-v11/resume.sh"

# BD-101 — verification gates (read-only checks at stage transitions).
# Each gate sources `checkpoint.sh` for its shared helpers.
# shellcheck source=lib/migrate-v10-to-v11/checkpoint.sh disable=SC1091
. "$SCRIPT_DIR/lib/migrate-v10-to-v11/checkpoint.sh"
# shellcheck source=lib/migrate-v10-to-v11/gate-1-dry-run-summary.sh disable=SC1091
. "$SCRIPT_DIR/lib/migrate-v10-to-v11/gate-1-dry-run-summary.sh"
# shellcheck source=lib/migrate-v10-to-v11/gate-2-phase-a-verify.sh disable=SC1091
. "$SCRIPT_DIR/lib/migrate-v10-to-v11/gate-2-phase-a-verify.sh"
# shellcheck source=lib/migrate-v10-to-v11/gate-3-phase-b-verify.sh disable=SC1091
. "$SCRIPT_DIR/lib/migrate-v10-to-v11/gate-3-phase-b-verify.sh"

# Mode detection: scan args for the first explicit mode flag. Drop the
# matched flag from the forwarded args because each mode dispatcher
# re-supplies its own canonical mode flag to `migrator_run`.
_mode=""
_passthru=()
for _a in "$@"; do
    case "$_a" in
        --dry-run|--apply|--resume)
            if [[ -z "$_mode" ]]; then
                _mode="$_a"
                continue
            fi
            # Multiple mode flags is a user error — let the framework's
            # parser reject the duplicate downstream rather than silently
            # picking one.
            _passthru+=("$_a")
            ;;
        *)
            _passthru+=("$_a")
            ;;
    esac
done

# Helper: scan passthru for --help and route through framework usage if present.
_dispatch_help_passthru() {
    local _a
    for _a in "${_passthru[@]:-}"; do
        case "$_a" in
            --help|-h)
                migrator_run "${_passthru[@]:-}"
                exit $?
                ;;
        esac
    done
}

case "$_mode" in
    --dry-run)
        _dispatch_help_passthru
        migrate_v10_to_v11_dry_run_run "${_passthru[@]:-}"
        ;;
    --resume)
        _dispatch_help_passthru
        migrate_v10_to_v11_resume_run "${_passthru[@]:-}"
        ;;
    --apply)
        # Explicit --apply: STRICTLY enforce the freshness gate. Refuses
        # to run without a pre-existing fresh dry-run fingerprint
        # (architecture §6.G). Users who want the auto-dry-run-then-
        # apply convenience drop the flag and use the bare invocation.
        _dispatch_help_passthru
        migrate_v10_to_v11_apply_run "${_passthru[@]:-}"
        ;;
    "")
        # Bare invocation: backwards-compat with the pre-BD-095 UX.
        # Auto-runs --dry-run first if no fresh dry-run output exists,
        # then runs --apply. Users of the legacy `migrate.sh <target>`
        # invocation pattern do NOT need to learn the new flags for the
        # no-conflict path.
        _dispatch_help_passthru
        _target="."
        for _a in "${_passthru[@]:-}"; do
            case "$_a" in
                -*|--*) ;;
                *) _target="$_a"; break ;;
            esac
        done
        _target_abs="$(cd "$_target" 2>/dev/null && pwd || printf '%s' "$_target")"
        _fp="$_target_abs/.pack-migrate-v10-to-v11/dry-run.fingerprint"
        # Determine whether a re-dry-run is needed:
        #   - fingerprint absent
        #   - fingerprint older than 24h (would fail freshness in apply)
        #   - working-tree fingerprint drifted from recorded fingerprint
        # Any of those → auto-rerun --dry-run so the bare-invocation UX
        # mirrors the pre-BD-095 single-shot path.
        _need_dry_run=0
        if [[ ! -f "$_fp" ]]; then
            _need_dry_run=1
        else
            _now=$(date +%s)
            _rec_epoch=$(grep '^epoch=' "$_fp" | head -1 | cut -d= -f2-)
            if [[ -z "$_rec_epoch" ]] \
               || (( _now - _rec_epoch > ${V10_V11_DRYRUN_MAX_AGE_SECS:-86400} )); then
                _need_dry_run=1
            else
                _rec_sha=$(grep '^target_sha256=' "$_fp" | head -1 | cut -d= -f2-)
                _cur_line=$(migrate_v10_to_v11_dry_run_compute_fingerprint "$_target_abs")
                _cur_sha=$(printf '%s' "$_cur_line" | awk '{print $1}')
                if [[ "$_rec_sha" != "$_cur_sha" ]]; then
                    _need_dry_run=1
                fi
            fi
        fi
        if (( _need_dry_run == 1 )); then
            say "── BD-095 backwards-compat: no fresh dry-run found ──"
            say "Auto-running --dry-run first; --apply will follow on success."
            say ""
            migrate_v10_to_v11_dry_run_run "${_passthru[@]:-}" || exit $?
            say ""
            say "── proceeding to --apply ──"
            say ""
        fi
        migrate_v10_to_v11_apply_run "${_passthru[@]:-}"
        ;;
esac
