#!/usr/bin/env bash
# add-capability.sh — add a pack-supported capability (platform, language,
# protocol, or role) to an existing AI Agent Config Pack v10.0 project.
#
# ┌──────────────────────────────────────────────────────────────────────┐
# │  Pack file convention (BD-059, OQ-6 — forward contract)              │
# │                                                                      │
# │  This script is currently add-only — it copies conditional pack      │
# │  files; it never removes files. If a future revision introduces a    │
# │  deletion site in any pack-controlled directory                      │
# │  (.{claude,codex,gemini}/agents/, .{claude,codex,gemini}/skills/,    │
# │  scripts/, docs/pack/prompts/), that deletion MUST skip files whose  │
# │  basename begins with `x-`. Project-added files use the `x-` prefix  │
# │  (see supporting-docs/INSTALL-PROCEDURES.md § "Project file          │
# │  conventions in pack-controlled directories"); pack-controlled       │
# │  scripts must never remove them.                                     │
# │                                                                      │
# │  init-project.sh and migrate-v9-to-v10.sh both honor this contract;  │
# │  any new deletion site here must follow the same pattern (see        │
# │  init-project.sh stage_s9_conditional_remove() for the canonical     │
# │  is_x_prefixed guard).                                               │
# └──────────────────────────────────────────────────────────────────────┘
#
# Per V10-DESIGN §5.14, the script runs nine stages A0..A8 with preview
# and confirmation before any writes. Per §5.14.7 it sources
# scripts/lib/detect.sh and inverts the init-project.sh §7.6 stage S9
# conditional-file table (single source of truth for the conditional-file
# mapping).
#
# BD-048 (v11.0): stages A7-discovery (read-only `command -v` discovery
# of capability-implied tooling) + install-hint summary embedded in the
# A8 PM-chat prompt mirror the BD-047 kickoff Form-R / Form-I shape at
# capability-addition time. The script never installs anything itself —
# it surfaces missing tools with concrete install commands that the
# developer (or the PM chat following Procedure 6) chooses to run.
# The discovery table (`capability_install_checks()`) is parallel to
# `capability_skills()` and `capability_files()` and is the single
# extension point for new capability rows.
#
# Usage:
#     bash "$PACK/scripts/add-capability.sh" --project . \
#         --add language:python \
#         --add protocol:grpc
#
# Flags:
#     --project <path>   Target project directory (required).
#     --add <dim>:<val>  Capability to add. May be repeated.
#                        Recognized dimensions: platform, language, protocol,
#                        role, deployment.
#                        Examples: language:python, platform:ios,
#                        protocol:grpc, role:python-server, deployment:apple,
#                        deployment:linux-container.
#     --pack <path>      Override $PACK environment variable.
#
# Exit codes:
#     0   Success, developer declined, degenerate no-op, or already-active.
#     10  $PACK invalid.
#     11  Target is not a git repo.
#     12  Working tree not clean.
#     20  STOP — target has no AI config (not a pack-initialized project).
#     21  Unrecognized --add dimension:value.
#     99  Internal error.

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROMPT_FILE=".pack-add-capability-prompt.md"

readonly EXIT_PACK_INVALID=10
readonly EXIT_NOT_GIT=11
readonly EXIT_DIRTY=12
readonly EXIT_NO_AI_CONFIG=20
readonly EXIT_UNKNOWN_CAPABILITY=21
readonly EXIT_INTERNAL=99

# ── Helpers ────────────────────────────────────────────────────────────────

say()  { printf '%s\n' "$*"; }
info() { printf '  %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$1" >&2; exit "${2:-$EXIT_INTERNAL}"; }

# ── Source shared detection library ────────────────────────────────────────

if [[ ! -f "$SCRIPT_DIR/lib/detect.sh" ]]; then
    die "missing shared detection library: $SCRIPT_DIR/lib/detect.sh"
fi
# shellcheck source=lib/detect.sh
source "$SCRIPT_DIR/lib/detect.sh"

# ── Arg parsing ────────────────────────────────────────────────────────────

TARGET=""
PACK_OVERRIDE=""
ADD_ARGS=()

while (( $# > 0 )); do
    case "$1" in
        --project) TARGET="$2"; shift 2 ;;
        --add)     ADD_ARGS+=("$2"); shift 2 ;;
        --pack)    PACK_OVERRIDE="$2"; shift 2 ;;
        --help|-h)
            sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
            exit 0 ;;
        *) die "unknown argument: $1" ;;
    esac
done

[[ -n "$TARGET" ]] || die "--project <path> is required"
(( ${#ADD_ARGS[@]} > 0 )) || die "at least one --add <dim>:<val> is required"

if [[ -n "$PACK_OVERRIDE" ]]; then
    export PACK="$PACK_OVERRIDE"
fi

TARGET=$(cd "$TARGET" 2>/dev/null && pwd || echo "$TARGET")

# ── Capability → (skills, files, install-checks) resolution tables ─────────
# The three table functions capability_skills(), capability_files(), and
# capability_install_checks() are single-sourced in
# project-template/scripts/capability-tables.sh (sourced lazily by
# _load_capability_tables() below, after $PACK is validated at stage A0).
# Mirrors init-project.sh §7.6 stage S9 conditional-removal table, inverted.

# _load_capability_tables — source the single-source capability tables.
#
# The authored source lives at project-template/scripts/capability-tables.sh
# (it ships to clients via the S5 glob; the client activate-capability.sh
# sources its own installed copy). The pack-side path requires $PACK, which
# is only guaranteed AFTER stage_a0_preflight validates it — so this helper
# is invoked from stage_a1_resolve (the first stage that calls the tables),
# NOT at top-level load. Guarded against double-source.
_load_capability_tables() {
    [[ -n "${_CAPABILITY_TABLES_LOADED:-}" ]] && return 0
    local tables="$PACK/project-template/scripts/capability-tables.sh"
    if [[ ! -f "$tables" ]]; then
        die "missing capability tables: $tables" "$EXIT_PACK_INVALID"
    fi
    # shellcheck source=../project-template/scripts/capability-tables.sh
    source "$tables"
    _CAPABILITY_TABLES_LOADED=1
}

# warn_if_missing_skills <skill> [<skill>...]
#
# BD-144: forward-declared platform rows (platform:android,
# platform:web-browser, platform:embedded-mcu) reference SKILL.md targets
# that don't yet ship in v11.0 (they ship in Phase 3 per
# PLAN-SKILL-DIMENSIONS.md §6). When a resolved skill is absent from
# $PACK/project-template/skills/<skill>/SKILL.md, emit a stderr warning
# but allow the operation to proceed — the PM-chat-driven workflow can
# declare D1 ahead of skill ship.
#
# Returns 0 always (advisory only).
warn_if_missing_skills() {
    local skill
    for skill in "$@"; do
        [[ -z "$skill" ]] && continue
        if [[ ! -f "$PACK/project-template/skills/$skill/SKILL.md" ]]; then
            warn "skill '$skill' has no SKILL.md in pack ($PACK/project-template/skills/$skill/SKILL.md missing); the capability row is forward-declared and the skill ships in a later release"
        fi
    done
    return 0
}

# probe_tool_present <tool>
#
# Read-only presence check — the BD-048 discovery stage's only side effect
# beyond stdout/stderr is a `command -v` lookup. Returns 0 if present,
# 1 otherwise. Centralized so future rows can swap to alternate probes
# (e.g., `python3 -c 'import <pkg>'`) by adding cases here.
probe_tool_present() {
    local tool="$1"
    case "$tool" in
        # Python-package probe pattern (none today; reserved):
        # py:*) python3 -c "import ${tool#py:}" >/dev/null 2>&1 ;;
        *) command -v "$tool" >/dev/null 2>&1 ;;
    esac
}

# ── Stage A0 — pre-flight ──────────────────────────────────────────────────

stage_a0_preflight() {
    say "── A0 — pre-flight ──"

    if [[ -z "${PACK:-}" ]]; then
        die "PACK environment variable not set (or pass --pack <path>)" "$EXIT_PACK_INVALID"
    fi
    local pack_status
    pack_status=$(detect_pack_path "$PACK" | awk -F': ' '{print $2}')
    if [[ "$pack_status" != "valid" ]]; then
        die "PACK ($PACK) is not a valid pack repo: $pack_status" "$EXIT_PACK_INVALID"
    fi
    info "pack: $PACK"

    if ! git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1; then
        die "target is not a git repo: $TARGET" "$EXIT_NOT_GIT"
    fi

    local wt
    wt=$(detect_clean_working_tree "$TARGET" | awk -F': ' '{print $2}')
    if [[ "$wt" != "clean" ]]; then
        die "target working tree is dirty; commit or stash first" "$EXIT_DIRTY"
    fi

    # Inverse of init's stop: this script REQUIRES AI config (a v10 project).
    local ai
    ai=$(detect_ai_config "$TARGET" | awk -F': ' '{print $2}')
    if [[ "$ai" == "(none)" ]]; then
        say ""
        say "STOP — target has no AI config; this is not a pack-initialized project."
        say "Use scripts/init-project.sh to install the pack first."
        exit "$EXIT_NO_AI_CONFIG"
    fi

    # Pack-version compatibility — warning only, not a stop.
    local banner_version=""
    if [[ -f "$TARGET/CLAUDE.md" ]]; then
        banner_version=$(grep -oE "Agent Config Pack v[0-9]+(\.[0-9]+)?" "$TARGET/CLAUDE.md" | head -1 | awk '{print $NF}' || true)
    fi
    local pack_version
    pack_version=$(detect_pack_version "$PACK" | awk -F': ' '{print $2}')
    if [[ -n "$banner_version" && "$banner_version" != "$pack_version" && "$pack_version" != *dev* ]]; then
        warn "project installed from pack $banner_version; \$PACK is $pack_version — proceed only if you understand the compatibility impact"
    fi

    info "target: $TARGET"
    info "pack version: $pack_version"
}

# ── Stage A1 — resolve --add args ──────────────────────────────────────────

stage_a1_resolve() {
    say ""
    say "── A1 — resolve capability arguments ──"
    # Load the single-source capability tables now that stage A0 has
    # validated $PACK. The tables live at
    # $PACK/project-template/scripts/capability-tables.sh and are first
    # called below — sourcing them earlier (top-level) would dereference
    # $PACK before A0's validation.
    _load_capability_tables
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

    # BD-144: warn (don't fail) when any resolved skill is forward-declared
    # — i.e. the SKILL.md ships in a later release. Allows PM-chat-driven
    # projects to declare D1 substrate ahead of Phase 3 skill ship.
    if (( ${#RESOLVED_SKILLS[@]} > 0 )); then
        warn_if_missing_skills "${RESOLVED_SKILLS[@]}"
    fi
}

# ── Stage A2 — delta vs active skills ──────────────────────────────────────

stage_a2_delta() {
    say ""
    say "── A2 — compute delta against Active skills ──"

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
    for s in "${RESOLVED_SKILLS[@]}"; do
        local found=0
        local a
        for a in "${ACTIVE_SKILLS[@]:-}"; do
            if [[ "$a" == "$s" ]]; then found=1; break; fi
        done
        (( found == 0 )) && SKILLS_TO_ADD+=("$s")
    done

    # Files to add = resolved files that don't already exist in target.
    FILES_TO_ADD=()
    local f
    for f in "${RESOLVED_FILES[@]:-}"; do
        [[ -e "$TARGET/$f" ]] && continue
        FILES_TO_ADD+=("$f")
    done

    info "skills already active: ${#ACTIVE_SKILLS[@]}"
    info "skills to add:         ${#SKILLS_TO_ADD[@]}"
    info "files to add:          ${#FILES_TO_ADD[@]}"

    # Degenerate case: if resolution yielded no skills or files, exit 0.
    if (( ${#RESOLVED_SKILLS[@]} == 0 )) && (( ${#RESOLVED_FILES[@]} == 0 )); then
        say ""
        say "nothing to add — this dimension/value is already covered by existing active skills and files."
        exit 0
    fi
    # Already-active exit: union is identical to current state.
    if (( ${#SKILLS_TO_ADD[@]} == 0 )) && (( ${#FILES_TO_ADD[@]} == 0 )); then
        say ""
        say "all requested capabilities already active; no changes needed."
        write_prompt_file "already-active"
        exit 0
    fi
}

# ── Stage A3 — preview ─────────────────────────────────────────────────────

stage_a3_preview() {
    say ""
    say "── A3 — preview ──"
    say ""
    say "Planned changes:"
    if (( ${#FILES_TO_ADD[@]} > 0 )); then
        say "  Files to copy from pack:"
        local f
        for f in "${FILES_TO_ADD[@]}"; do info "    + $f"; done
    else
        info "  (no conditional files to copy)"
    fi
    say ""
    if (( ${#SKILLS_TO_ADD[@]} > 0 )); then
        say "  Skills the PM chat will add to the Active skills line (via Procedure 6):"
        local s
        for s in "${SKILLS_TO_ADD[@]}"; do info "    + $s"; done
    else
        info "  (no new skills — all requested already active)"
    fi
    say ""
    say "  .gitignore entries will be re-merged (append missing pack lines; dedupe)."
    say "  The end-of-run PM chat prompt will be written to stdout and to $PROMPT_FILE"
    say "  in the project root (gitignored)."
}

# ── Stage A4 — confirm ─────────────────────────────────────────────────────

stage_a4_confirm() {
    say ""
    local ans lower
    read -r -p "Proceed? [y/N] " ans || ans=""
    lower=$(printf '%s' "$ans" | tr '[:upper:]' '[:lower:]')
    case "$lower" in
        y|yes) say "Proceeding..." ;;
        *)     say "Declined. No changes made."; exit 0 ;;
    esac
}

# ── Stage A5 — copy conditional files ──────────────────────────────────────

stage_a5_copy() {
    say ""
    say "── A5 — copy conditional files ──"
    if (( ${#FILES_TO_ADD[@]} == 0 )); then
        info "(nothing to copy)"
        return
    fi
    local f src dst
    for f in "${FILES_TO_ADD[@]}"; do
        src="$PACK/project-template/$f"
        dst="$TARGET/$f"
        if [[ ! -e "$src" ]]; then
            warn "pack source missing: $src — skipping"
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
    # Ensure any shell scripts are executable.
    find "$TARGET/scripts" -maxdepth 1 -name "*.sh" -exec chmod +x {} + 2>/dev/null || true
}

# ── Stage A6 — .gitignore merge ────────────────────────────────────────────

stage_a6_gitignore() {
    say ""
    say "── A6 — .gitignore merge ──"
    local pack_gi="$PACK/project-template/.gitignore"
    if [[ ! -f "$pack_gi" ]]; then
        info "(no pack .gitignore template — skipping)"
    else
        local header="# --- AI Agent Config Pack additions (v11.0) ---"
        if [[ ! -f "$TARGET/.gitignore" ]]; then
            cp "$pack_gi" "$TARGET/.gitignore"
        else
            local existing added=0 dup=0 line
            existing=$(cat "$TARGET/.gitignore")
            if ! printf '%s' "$existing" | grep -Fxq "$header"; then
                printf '\n%s\n' "$header" >> "$TARGET/.gitignore"
            fi
            while IFS= read -r line; do
                [[ -z "$line" ]] && continue
                [[ "$line" == "#"* ]] && continue
                if printf '%s' "$existing" | grep -Fxq "$line"; then
                    dup=$((dup + 1))
                    continue
                fi
                printf '%s\n' "$line" >> "$TARGET/.gitignore"
                added=$((added + 1))
            done < "$pack_gi"
            info ".gitignore: $added added, $dup duplicates skipped"
        fi
    fi
    # Ensure the prompt file pattern is gitignored.
    if [[ -f "$TARGET/.gitignore" ]] && ! grep -Fxq "$PROMPT_FILE" "$TARGET/.gitignore"; then
        printf '%s\n' "$PROMPT_FILE" >> "$TARGET/.gitignore"
        info "+ $PROMPT_FILE to .gitignore"
    fi
}

# ── Stage A7 — capability install-check discovery (BD-048) ─────────────────
#
# Read-only Form-R-shaped discovery: for each requested capability, look
# up its install-check rows and probe each tool with `command -v`. Build
# two arrays exposed to the A8 prompt: DISCOVERY_LINES (one line per
# probed tool with present/missing status) and INSTALL_HINTS (one line
# per missing tool with the concrete install command).
#
# Mirrors INSTALL-PROCEDURES.md Procedure 7 §7.1 K1 read-only discovery
# — the script never installs anything; it surfaces the proposal so the
# developer (or PM chat Procedure 6) can decide.

stage_a7_install_check() {
    say ""
    say "── A7 — capability install-check discovery (read-only) ──"
    DISCOVERY_LINES=()
    INSTALL_HINTS=()

    # Track tools we've already probed this run — a single tool may be
    # implied by multiple capabilities (e.g., xcodebuild ↔ platform:macos +
    # deployment:apple). Probe once; report once.
    local probed_tools=""

    local cap rows row tool inst purpose status
    for cap in "${ADD_ARGS[@]}"; do
        rows=$(capability_install_checks "$cap" || true)
        if [[ -z "$rows" ]]; then
            DISCOVERY_LINES+=("$cap: (no machine-level installs implied)")
            continue
        fi
        while IFS= read -r row; do
            [[ -z "$row" ]] && continue
            # Field separator is ':::' (BD-048) — install commands themselves
            # often contain `|` as an "or" between platform alternatives, so
            # pipe-based parsing would break. awk -F treats the arg as ERE;
            # ':::' is a literal three-colon match.
            tool=$(printf '%s' "$row" | awk -F':::' '{print $1}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            inst=$(printf '%s' "$row" | awk -F':::' '{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            purpose=$(printf '%s' "$row" | awk -F':::' '{print $3}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            [[ -z "$tool" ]] && continue

            # Dedup probes across capabilities.
            if [[ " $probed_tools " == *" $tool "* ]]; then
                continue
            fi
            probed_tools="$probed_tools $tool"

            if probe_tool_present "$tool"; then
                status="present"
                DISCOVERY_LINES+=("  [present] $tool — $purpose")
            else
                status="missing"
                DISCOVERY_LINES+=("  [missing] $tool — $purpose")
                INSTALL_HINTS+=("  $tool: $inst")
            fi
            info "$cap → $tool: $status"
        done <<< "$rows"
    done

    say ""
    if (( ${#INSTALL_HINTS[@]} == 0 )); then
        info "all probed tools present (or no machine-level installs implied)"
    else
        info "${#INSTALL_HINTS[@]} tool(s) missing — install commands surfaced in the A8 prompt below"
        local h
        for h in "${INSTALL_HINTS[@]}"; do
            info "$h"
        done
    fi
}

# ── Stage A8 — end-of-run PM chat prompt ───────────────────────────────────

write_prompt_file() {
    local mode="${1:-normal}"
    local abs
    abs=$(cd "$TARGET" && pwd)
    local pack_ver
    pack_ver=$(detect_pack_version "$PACK" | awk -F': ' '{print $2}')

    # Current Active-skills contents.
    local active_display
    if (( ${#ACTIVE_SKILLS[@]} == 0 )); then
        active_display="(placeholder or empty)"
    else
        active_display=$(printf '%s, ' "${ACTIVE_SKILLS[@]}" | sed 's/, $//')
    fi
    # Union skill list.
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

scripts/add-capability.sh has just run and processed the following
pack-supported capabilities on this project:

EOF
)
    local cap
    for cap in "${ADD_ARGS[@]}"; do
        report+=$'\n'"  --add $cap"
    done
    report+=$'\n\n'
    if [[ "$mode" == "already-active" ]]; then
        report+="Mode: all requested capabilities were already active; no files were copied."$'\n\n'
    else
        if (( ${#FILES_TO_ADD[@]} > 0 )); then
            report+="Files copied:"$'\n'
            local f
            for f in "${FILES_TO_ADD[@]}"; do
                report+="  - $f"$'\n'
            done
        else
            report+="Files copied: (none)"$'\n'
        fi
        report+=$'\n'
    fi
    report+="Active skills currently in CLAUDE.md:"$'\n'"  $active_display"$'\n\n'
    report+="Active skills after your Procedure 6 run should be:"$'\n'"  $union_display"$'\n\n'

    # BD-048 install-check section. Stage A7 populates DISCOVERY_LINES and
    # INSTALL_HINTS; the already-active early-exit path skips A7, so guard
    # with `:-` defaults to keep this prompt block well-formed in both modes.
    local dl il
    if (( ${#DISCOVERY_LINES[@]:-0} > 0 )); then
        report+="Capability install-check discovery (read-only, BD-048):"$'\n'
        for dl in "${DISCOVERY_LINES[@]}"; do
            report+="$dl"$'\n'
        done
        report+=$'\n'
        if (( ${#INSTALL_HINTS[@]:-0} > 0 )); then
            report+="Missing tools — proposed install commands (run with developer approval per Procedure 6 G6-install):"$'\n'
            for il in "${INSTALL_HINTS[@]}"; do
                report+="$il"$'\n'
            done
            report+=$'\n'
            report+=$'Render a Form I (INSTALL-PROCEDURES.md § 7.2.3 shape) for each\nmissing tool before running any install. Skip-by-default: a missing\ntool is reported, never auto-installed.\n\n'
        else
            report+="All probed tools present — no Form I follow-up required."$'\n\n'
        fi
    fi

    report+=$'Please run METHODOLOGY.md Procedure 6 (Adding a pack-supported\ncapability). Present your trinity-file drafts for approval at G6-drafts\nbefore writing, the install commands at G6-install before running them,\nand the commit message at G6-commit before committing.\n\nDo NOT modify any file starting with `x-`.\nDo NOT modify PLATFORM-SKILLS.md project-owned sections\n(`## Custom agents`, `## Custom skills`).\n'

    printf '%s' "$report" > "$TARGET/$PROMPT_FILE"
    printf '%s' "$report"
}

stage_a8_prompt() {
    say ""
    say "── A8 — end-of-run PM chat prompt ──"
    say ""
    say "──── PM chat prompt (also written to $PROMPT_FILE) ────"
    write_prompt_file "normal"
    say ""
    say "──── End of prompt ────"
}

# ── Main ───────────────────────────────────────────────────────────────────

main() {
    say "add-capability.sh — add pack-supported capability to v10 project"
    say ""

    # BD-048: ensure discovery arrays exist even on early-exit paths
    # (already-active short-circuit in stage_a2_delta calls write_prompt_file
    # before stage_a7_install_check runs).
    DISCOVERY_LINES=()
    INSTALL_HINTS=()

    stage_a0_preflight
    stage_a1_resolve
    stage_a2_delta
    stage_a3_preview
    stage_a4_confirm
    stage_a5_copy
    stage_a6_gitignore
    stage_a7_install_check
    stage_a8_prompt

    say ""
    say "Done. Review git diff, then follow the PM chat prompt above (or read it"
    say "from $PROMPT_FILE) to complete Procedure 6 and commit on a feature branch."
}

main "$@"
