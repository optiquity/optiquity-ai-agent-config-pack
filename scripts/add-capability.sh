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
# Per V10-DESIGN §5.14, the script runs eight stages A0..A7 with preview
# and confirmation before any writes. Per §5.14.7 it sources
# scripts/lib/detect.sh and inverts the init-project.sh §7.6 stage S9
# conditional-file table (single source of truth for the conditional-file
# mapping).
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

# ── Capability → (skills, files) resolution table ──────────────────────────
# Mirrors init-project.sh §7.6 stage S9 conditional-removal table, inverted.

capability_skills() {
    local cap="$1"
    case "$cap" in
        # BD-141: python-data-architecture's load predicate is defined in
        # scripts/lib/detect.sh::python_data_marker_detected(). add-capability.sh
        # adds it as part of the language:python skill set (coarser tool —
        # explicit user intent to add the capability); init-project.sh applies
        # the predicate at scaffold time via pack_skill_coverage_for().
        language:python)    echo "python-best-practices python-data-architecture dependency-python" ;;
        language:swift)     echo "swift-best-practices apple-architecture-core dependency-swift" ;;
        language:cpp)       echo "cpp-language" ;;
        language:c)          echo "c-language" ;;
        language:objc)      echo "objc-language" ;;
        platform:macos)     echo "macos-architecture apple-architecture-core" ;;
        platform:ios)       echo "ios-architecture apple-architecture-core" ;;
        # BD-144 (v11.0 skill-dimensions reframe Batch 5): forward-declared
        # D1 platform rows. The SKILL.md targets ship in Phase 3
        # (web-architecture / android-architecture / embedded-mcu-architecture);
        # until then warn_if_missing_skills() emits a stderr warning when the
        # resolved skill directory is absent, but the operation still proceeds
        # so PM-chat-driven projects can declare D1 ahead of skill ship.
        platform:android)      echo "android-architecture" ;;
        platform:web-browser)  echo "web-architecture" ;;
        platform:embedded-mcu) echo "embedded-mcu-architecture" ;;
        # BD-156: protocol:grpc adds grpc-patterns only. The companion
        # `protobuf-patterns` skill is intersection-loaded by marker
        # (`scripts/lib/detect.sh::protobuf_marker_detected()`), not by
        # capability — the same `.proto` files that justify a `grpc`
        # capability also trigger the marker, so intersection loading
        # picks up protobuf-patterns automatically. Standalone-protobuf
        # projects (binary file format / IPC / Twirp / Connect) load
        # protobuf-patterns via the marker without ever declaring
        # protocol:grpc. See PLATFORM-SKILLS.md "Intersection table".
        protocol:grpc)      echo "grpc-patterns" ;;
        protocol:rest)      echo "rest-patterns" ;;
        protocol:graphql)   echo "graphql-patterns" ;;
        protocol:realtime)  echo "realtime-patterns" ;;
        protocol:messaging) echo "messaging-patterns" ;;
        protocol:soap)      echo "soap-patterns" ;;
        # BD-144 (v11.0 skill-dimensions reframe Batch 5): D5 deployment
        # surface. `role:apple-app` was renamed to `deployment:apple` (Apple-app
        # is a D5 deployment surface, not a D3 architectural role per
        # ARCHITECTURE-SKILL-DIMENSIONS.md §3.5). `deployment:linux-container`
        # carries `deployment-python` (formerly bundled into role:python-server,
        # which now resolves to the D2∩D3 intersection per architecture §3.7).
        deployment:apple)             echo "deployment-apple" ;;
        deployment:linux-container)   echo "deployment-python" ;;
        # BD-144: role:python-server preserved as a legitimate D3 role token.
        # Resolved skill list updated per architecture §3.7 intersection table:
        # D2=python ∩ D3=server → python-server-architecture +
        # python-data-architecture. `deployment-python` was dropped from this
        # row; it now loads via the new `deployment:linux-container` D5 row.
        role:python-server) echo "python-server-architecture python-data-architecture" ;;
        *) return 1 ;;
    esac
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

capability_files() {
    local cap="$1"
    case "$cap" in
        language:python)
            echo "pyproject.toml pyrightconfig.json server scripts/bootstrap-python.sh scripts/format-python.sh scripts/validate-python.sh scripts/test-python.sh" ;;
        language:swift)
            echo "scripts/bootstrap-swift.sh scripts/format-swift.sh scripts/validate-swift.sh scripts/test-swift.sh" ;;
        protocol:grpc)
            echo "proto scripts/proto-gen.sh scripts/validate-proto.sh" ;;
        *) echo "" ;;
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

# ── Stage A7 — end-of-run PM chat prompt ───────────────────────────────────

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
    report+=$'Please run METHODOLOGY.md Procedure 6 (Adding a pack-supported\ncapability). Present your trinity-file drafts for approval at G6-drafts\nbefore writing, and the commit message at G6-commit before committing.\n\nDo NOT modify any file starting with `x-`.\nDo NOT modify PLATFORM-SKILLS.md project-owned sections\n(`## Custom agents`, `## Custom skills`).\n'

    printf '%s' "$report" > "$TARGET/$PROMPT_FILE"
    printf '%s' "$report"
}

stage_a7_prompt() {
    say ""
    say "── A7 — end-of-run PM chat prompt ──"
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

    stage_a0_preflight
    stage_a1_resolve
    stage_a2_delta
    stage_a3_preview
    stage_a4_confirm
    stage_a5_copy
    stage_a6_gitignore
    stage_a7_prompt

    say ""
    say "Done. Review git diff, then follow the PM chat prompt above (or read it"
    say "from $PROMPT_FILE) to complete Procedure 6 and commit on a feature branch."
}

main "$@"
