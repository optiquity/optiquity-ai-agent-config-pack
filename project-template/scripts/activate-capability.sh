#!/usr/bin/env bash
# activate-capability.sh — ACTIVATE a supported capability (platform,
# language, protocol, or role) on this project, with NO external clone
# required. Self-contained and runnable on ANY clone of the project.
#
# How it differs from a fresh install: the skills for every supported
# capability are already on disk (installed once at project setup), and the
# conditional files for capabilities the project did not originally use were
# removed from the live tree. This script RE-MATERIALIZES those conditional
# files from the tracked pool at pack-capability-pool/ — a complete,
# version-controlled mirror of the conditional-file masters that travels with
# the repo. Activation therefore works on a fresh clone with nothing else
# present: P5 copies the resolved files out of pack-capability-pool/ into the
# live tree.
#
# This realizes the project-side capability-ACTIVATION design described in
# docs/pack/METHODOLOGY.md Procedure 6 (the self-contained activation
# workflow). The capability → (skills, files) resolution comes from the
# sibling, single-source scripts/capability-tables.sh (function
# capability_files()); this script never re-defines those tables.
#
# `x-` contract: P5 NEVER overwrites a live-tree file whose basename begins
# with `x-`. Those are project-authored files; the activation copy skips them
# and warns rather than clobbering a project file (docs/pack/INSTALL-
# PROCEDURES.md § "Project file conventions in pack-controlled directories").
#
# Usage:
#     bash scripts/activate-capability.sh --add language:python
#     bash scripts/activate-capability.sh --add protocol:grpc --add language:python
#
# Flags:
#     --add <dim>:<val>  Capability to activate. May be repeated.
#                        Recognized dimensions: platform, language, protocol,
#                        role, deployment.
#                        Examples: language:python, platform:ios,
#                        protocol:grpc, role:python-server, deployment:apple,
#                        deployment:linux-container.
#     --project <path>   Target project directory (default: repo root that
#                        contains this script's parent scripts/ dir).
#
# Exit codes:
#     0   Success, or all requested capabilities already materialized.
#     11  Target is not a git repo.
#     12  Working tree not clean.
#     20  STOP — target has no AI config (not a configured project).
#     21  Unrecognized --add dimension:value.
#     22  STOP — capability pool (pack-capability-pool/) is absent.
#     99  Internal error.

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROMPT_FILE=".pack-activate-capability-prompt.md"

readonly EXIT_NOT_GIT=11
readonly EXIT_DIRTY=12
readonly EXIT_NO_AI_CONFIG=20
readonly EXIT_UNKNOWN_CAPABILITY=21
readonly EXIT_NO_POOL=22
readonly EXIT_INTERNAL=99

# ── Helpers ────────────────────────────────────────────────────────────────

say()  { printf '%s\n' "$*"; }
info() { printf '  %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$1" >&2; exit "${2:-$EXIT_INTERNAL}"; }

# True when a path's basename begins with x- (a project-authored file the
# `x-` contract protects from pack-controlled overwrite). Used by P2's delta
# pass-through and P5's overwrite guard; defined here so it precedes first use.
is_x_prefixed() { [[ "$(basename "$1")" == x-* ]]; }

# ensure_prompt_gitignored — make $PROMPT_FILE present in $TARGET/.gitignore.
# The prompt is ephemeral local state (its `.pack-*` name MEANS gitignored
# local state); without this the developer's closing `git add -A` would sweep
# it into the client commit. Mirrors the sibling capability-addition script's
# prompt-gitignore behavior; creates .gitignore if absent and de-dupes.
ensure_prompt_gitignored() {
    local gi="$TARGET/.gitignore"
    if [[ -f "$gi" ]] && grep -Fxq "$PROMPT_FILE" "$gi"; then
        return 0
    fi
    printf '%s\n' "$PROMPT_FILE" >> "$gi"
    info "+ $PROMPT_FILE to .gitignore"
}

# ── Source the single-source capability tables (own installed copy) ─────────
# The client sources its OWN installed copy of the tables — never an external
# location. capability-tables.sh is sourceable-only (no top-level side
# effects); sourcing it defines capability_skills(), capability_files(), and
# capability_install_checks().

if [[ ! -f "$SCRIPT_DIR/capability-tables.sh" ]]; then
    die "missing capability tables: $SCRIPT_DIR/capability-tables.sh" "$EXIT_INTERNAL"
fi
# shellcheck source=capability-tables.sh
source "$SCRIPT_DIR/capability-tables.sh"

# ── Arg parsing ────────────────────────────────────────────────────────────
# Default target = the project root (the parent of this script's scripts/
# directory), so the script runs with no arguments from a fresh clone.

TARGET="$(cd "$SCRIPT_DIR/.." && pwd)"
ADD_ARGS=()

while (( $# > 0 )); do
    case "$1" in
        --project) TARGET="$2"; shift 2 ;;
        --add)     ADD_ARGS+=("$2"); shift 2 ;;
        --help|-h)
            sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
            exit 0 ;;
        *) die "unknown argument: $1" ;;
    esac
done

(( ${#ADD_ARGS[@]} > 0 )) || die "at least one --add <dim>:<val> is required"

TARGET=$(cd "$TARGET" 2>/dev/null && pwd || echo "$TARGET")
POOL="$TARGET/pack-capability-pool"

# ── Stage P0 — pre-flight ──────────────────────────────────────────────────
# No external-clone check: activation is self-contained. The pool presence
# check replaces it — the pool IS the re-materialization source.

stage_p0_preflight() {
    say "── P0 — pre-flight ──"

    if ! git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1; then
        die "target is not a git repo: $TARGET" "$EXIT_NOT_GIT"
    fi

    if [[ -n "$(git -C "$TARGET" status --porcelain 2>/dev/null)" ]]; then
        die "target working tree is dirty; commit or stash first" "$EXIT_DIRTY"
    fi

    # This script REQUIRES an already-configured project (AI config present).
    if [[ ! -f "$TARGET/CLAUDE.md" && ! -f "$TARGET/AGENTS.md" && ! -f "$TARGET/GEMINI.md" ]]; then
        say ""
        say "STOP — target has no AI config; this is not a configured project."
        say "Run scripts/init-project.sh to set up the project first."
        exit "$EXIT_NO_AI_CONFIG"
    fi

    # The tracked pool is the activation source. Without it there is nothing
    # to re-materialize — fail with a project-actionable message.
    if [[ ! -d "$POOL" ]]; then
        say ""
        say "STOP — capability pool pack-capability-pool/ is absent."
        say "The pool is a tracked directory materialized only at fresh"
        say "project setup, by scripts/init-project.sh with a version that"
        say "supports capability activation. If it is missing, this project"
        say "was set up before that support existed."
        say "No in-place back-fill into an existing project exists yet:"
        say "scripts/init-project.sh --update does NOT create the pool. The"
        say "only path that populates it today is a fresh project setup."
        exit "$EXIT_NO_POOL"
    fi

    info "target: $TARGET"
    info "pool:   $POOL"
}

# ── Stage P1 — resolve --add args ──────────────────────────────────────────

stage_p1_resolve() {
    say ""
    say "── P1 — resolve capability arguments ──"
    RESOLVED_SKILLS=()
    RESOLVED_FILES=()
    local cap skills files
    for cap in "${ADD_ARGS[@]}"; do
        if ! skills=$(capability_skills "$cap"); then
            die "unknown --add dimension:value: $cap" "$EXIT_UNKNOWN_CAPABILITY"
        fi
        files=$(capability_files "$cap")
        info "$cap → skills: $skills"
        if [[ -n "$files" ]]; then
            info "$cap → files: $files"
        fi
        local s
        for s in $skills; do RESOLVED_SKILLS+=("$s"); done
        local f
        for f in $files; do RESOLVED_FILES+=("$f"); done
    done

    # Dedup resolved skills and files.
    local dedup
    dedup=$(printf '%s\n' "${RESOLVED_SKILLS[@]:-}" | sort -u | grep -v '^$' || true)
    RESOLVED_SKILLS=()
    while IFS= read -r s; do [[ -n "$s" ]] && RESOLVED_SKILLS+=("$s"); done <<< "$dedup"

    if (( ${#RESOLVED_FILES[@]} > 0 )); then
        dedup=$(printf '%s\n' "${RESOLVED_FILES[@]}" | sort -u | grep -v '^$' || true)
        RESOLVED_FILES=()
        while IFS= read -r f; do [[ -n "$f" ]] && RESOLVED_FILES+=("$f"); done <<< "$dedup"
    fi

    # Forward-declared platform rows (android/web/embedded) reference SKILL.md
    # targets that ship in a later release. Warn (don't fail) when a resolved
    # skill is absent on disk — activation still proceeds so the project can
    # declare a substrate ahead of skill ship. Skills are NOT copied here (all
    # supported skills are already on disk from project setup).
    warn_if_missing_skills() {
        local skill
        for skill in "$@"; do
            [[ -z "$skill" ]] && continue
            local present=0 tool
            for tool in claude codex gemini; do
                if [[ -f "$TARGET/.$tool/skills/$skill/SKILL.md" ]]; then
                    present=1; break
                fi
            done
            if (( present == 0 )); then
                warn "skill '$skill' has no SKILL.md on disk; the capability row is forward-declared and its skill ships in a later release"
            fi
        done
    }
    if (( ${#RESOLVED_SKILLS[@]} > 0 )); then
        warn_if_missing_skills "${RESOLVED_SKILLS[@]}"
    fi
}

# ── Stage P2 — delta vs active skills + on-disk files ───────────────────────

stage_p2_delta() {
    say ""
    say "── P2 — compute delta against active skills + live tree ──"

    local active_line active_content
    if [[ -f "$TARGET/CLAUDE.md" ]]; then
        active_line=$(grep -m1 "^\*\*Active skills:\*\*" "$TARGET/CLAUDE.md" 2>/dev/null || true)
    fi
    if [[ -z "${active_line:-}" ]]; then
        ACTIVE_SKILLS=()
    else
        active_content="${active_line#*\*\*Active skills:\*\* }"
        if [[ "$active_content" == "["* ]]; then
            ACTIVE_SKILLS=()
        else
            ACTIVE_SKILLS=()
            while IFS= read -r s; do
                [[ -n "$s" ]] && ACTIVE_SKILLS+=("$s")
            done < <(printf '%s' "$active_content" | tr -d '`' | tr ',' '\n' \
                | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$')
        fi
    fi

    # Skills to add = resolved − already active.
    SKILLS_TO_ADD=()
    local s
    for s in "${RESOLVED_SKILLS[@]:-}"; do
        [[ -z "$s" ]] && continue
        local found=0 a
        for a in "${ACTIVE_SKILLS[@]:-}"; do
            if [[ "$a" == "$s" ]]; then found=1; break; fi
        done
        (( found == 0 )) && SKILLS_TO_ADD+=("$s")
    done

    # Files to materialize = resolved files not already present in the live
    # tree. (A file already on disk is left alone — re-copying it would
    # clobber project edits.) Exception: a resolved dest that is already
    # present AND whose basename begins with x- is passed through to P5, so
    # the x- overwrite guard emits its explicit preserve-warn rather than
    # silently dropping it here — keeping the `x-` contract observable at the
    # copy site.
    FILES_TO_ADD=()
    local f
    for f in "${RESOLVED_FILES[@]:-}"; do
        [[ -z "$f" ]] && continue
        if [[ -e "$TARGET/$f" ]] && ! is_x_prefixed "$TARGET/$f"; then
            continue
        fi
        FILES_TO_ADD+=("$f")
    done

    info "skills already active: ${#ACTIVE_SKILLS[@]}"
    info "skills to add:         ${#SKILLS_TO_ADD[@]}"
    info "files to materialize:  ${#FILES_TO_ADD[@]}"

    if (( ${#RESOLVED_SKILLS[@]} == 0 )) && (( ${#RESOLVED_FILES[@]} == 0 )); then
        say ""
        say "nothing to activate — this dimension/value resolves to no skills or files."
        exit 0
    fi
    if (( ${#SKILLS_TO_ADD[@]} == 0 )) && (( ${#FILES_TO_ADD[@]} == 0 )); then
        say ""
        say "all requested capabilities already active; no changes needed."
        write_prompt_file "already-active"
        exit 0
    fi
}

# ── Stage P5 — re-materialize conditional files from the pool ───────────────
# Copy each resolved file FROM pack-capability-pool/<rel> INTO the live tree
# at <rel> (root files, server/ + proto/ dirs, conditional scripts/*).
# `x-` guard: never overwrite a project-authored x-* file.

stage_p5_copy() {
    say ""
    say "── P5 — re-materialize conditional files from pack-capability-pool/ ──"
    if (( ${#FILES_TO_ADD[@]} == 0 )); then
        info "(nothing to materialize)"
        return
    fi
    local f src dst
    for f in "${FILES_TO_ADD[@]}"; do
        src="$POOL/$f"
        dst="$TARGET/$f"
        if [[ ! -e "$src" ]]; then
            warn "pool file missing: pack-capability-pool/$f — skipping"
            continue
        fi
        # `x-` overwrite guard: a project-authored file whose basename begins
        # with x- is never clobbered, even if its relative path collides with
        # a resolved conditional file. Skip + warn, preserving the project file.
        if [[ -e "$dst" ]] && is_x_prefixed "$dst"; then
            warn "preserving project-authored file (x- prefix, not overwritten): $f"
            continue
        fi
        mkdir -p "$(dirname "$dst")"
        if [[ -d "$src" ]]; then
            cp -R "$src" "$dst"
        else
            cp "$src" "$dst"
        fi
        info "+ $f"
    done
    # Re-materialized shell scripts must be executable.
    if [[ -d "$TARGET/scripts" ]]; then
        find "$TARGET/scripts" -maxdepth 1 -name "*.sh" -exec chmod +x {} + 2>/dev/null || true
    fi
}

# ── Stage P8 — end-of-run PM-chat prompt ───────────────────────────────────

write_prompt_file() {
    local mode="${1:-normal}"
    local abs
    abs=$(cd "$TARGET" && pwd)

    local active_display
    if (( ${#ACTIVE_SKILLS[@]} == 0 )); then
        active_display="(placeholder or empty)"
    else
        active_display=$(printf '%s, ' "${ACTIVE_SKILLS[@]}" | sed 's/, $//')
    fi
    local all_skills=("${ACTIVE_SKILLS[@]:-}" "${SKILLS_TO_ADD[@]:-}")
    local union_display
    if (( ${#all_skills[@]} == 0 )); then
        union_display="(nothing to show)"
    else
        union_display=$(printf '%s\n' "${all_skills[@]}" | grep -v '^$' | sort -u | paste -sd, - | sed 's/,/, /g')
    fi

    local report
    report=$(cat <<EOF
You are the PM chat for [PROJECT_NAME at $abs].

scripts/activate-capability.sh has just run and activated the following
supported capabilities on this project:

EOF
)
    local cap
    for cap in "${ADD_ARGS[@]}"; do
        report+=$'\n'"  --add $cap"
    done
    report+=$'\n\n'
    if [[ "$mode" == "already-active" ]]; then
        report+="Mode: all requested capabilities were already active; no files were materialized."$'\n\n'
    else
        if (( ${#FILES_TO_ADD[@]} > 0 )); then
            report+="Files re-materialized from pack-capability-pool/:"$'\n'
            local f
            for f in "${FILES_TO_ADD[@]}"; do
                report+="  - $f"$'\n'
            done
        else
            report+="Files re-materialized: (none)"$'\n'
        fi
        report+=$'\n'
    fi
    report+="Active skills currently in CLAUDE.md:"$'\n'"  $active_display"$'\n\n'
    report+="Active skills after your Procedure 6 run should be:"$'\n'"  $union_display"$'\n\n'

    report+=$'Please run docs/pack/METHODOLOGY.md Procedure 6 (Activating a\nsupported capability). Update the **Active skills:** line in the trinity\nfiles (CLAUDE.md, AGENTS.md, GEMINI.md), update the project description\nplaceholders if the new capability changes them, then commit on a feature\nbranch. Present your trinity-file drafts for approval at G6-drafts before\nwriting, any install commands at G6-install before running them, and the\ncommit message at G6-commit before committing.\n\nDo NOT modify any file starting with `x-`.\nDo NOT modify PLATFORM-SKILLS.md project-owned sections\n(`## Custom agents`, `## Custom skills`).\n'

    # Ensure the ephemeral prompt artifact is gitignored BEFORE writing it, so
    # the developer's closing `git add -A` never sweeps it into the client
    # commit (its `.pack-*` name denotes gitignored local state).
    ensure_prompt_gitignored
    printf '%s' "$report" > "$TARGET/$PROMPT_FILE"
    printf '%s' "$report"
}

stage_p8_prompt() {
    say ""
    say "── P8 — end-of-run PM chat prompt ──"
    say ""
    say "──── PM chat prompt (also written to $PROMPT_FILE — gitignored) ────"
    write_prompt_file "normal"
    say ""
    say "──── End of prompt ────"
}

# ── Main ───────────────────────────────────────────────────────────────────

main() {
    say "activate-capability.sh — activate a supported capability on this project"
    say ""

    stage_p0_preflight
    stage_p1_resolve
    stage_p2_delta
    stage_p5_copy
    stage_p8_prompt

    say ""
    say "Done. Review git diff, then follow the PM chat prompt above (or read it"
    say "from $PROMPT_FILE) to complete Procedure 6 and commit on a feature branch."
}

main "$@"
