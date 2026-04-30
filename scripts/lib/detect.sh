# scripts/lib/detect.sh — shared detection helpers for v10 pack scripts.
#
# Sourced by init-project.sh, migrate-v9-to-v10.sh, and add-capability.sh.
# Every function prints a single `key: value` line (or multiple lines, one
# per match, for list-valued functions) to stdout. Every function is
# read-only with respect to the target project — no file writes, no git
# writes.
#
# Environment:
#   PACK   Absolute path to the pack repo. Required by detect_pack_path
#          (when no positional argument is given), detect_pack_version
#          (likewise), and detect_improperly_added_files (for roster
#          lookup).
#
# Functions default the target project to the current working directory;
# pass a path as the first positional argument to override.
#
# Do NOT add a shebang — this file is sourced, not executed.

# working-tree: clean|dirty
detect_clean_working_tree() {
    local target="${1:-.}"
    if ! git -C "$target" rev-parse --git-dir >/dev/null 2>&1; then
        echo "working-tree: dirty"
        return
    fi
    if [[ -z "$(git -C "$target" status --porcelain 2>/dev/null)" ]]; then
        echo "working-tree: clean"
    else
        echo "working-tree: dirty"
    fi
}

# git-repo: yes|no
detect_git_repo() {
    local target="${1:-.}"
    if git -C "$target" rev-parse --git-dir >/dev/null 2>&1; then
        echo "git-repo: yes"
    else
        echo "git-repo: no"
    fi
}

# pack-path: valid|missing|not-a-repo
detect_pack_path() {
    local pack="${1:-${PACK:-}}"
    if [[ -z "$pack" || ! -d "$pack" ]]; then
        echo "pack-path: missing"
        return
    fi
    if ! git -C "$pack" rev-parse --git-dir >/dev/null 2>&1; then
        echo "pack-path: not-a-repo"
        return
    fi
    if [[ ! -d "$pack/project-template" ]]; then
        echo "pack-path: not-a-repo"
        return
    fi
    echo "pack-path: valid"
}

# pack-version: v<N.M> (exact tag at HEAD) | <branch-name> | unknown
detect_pack_version() {
    local pack="${1:-${PACK:-.}}"
    local tag
    tag=$(git -C "$pack" describe --tags --exact-match HEAD 2>/dev/null)
    if [[ -n "$tag" ]]; then
        echo "pack-version: $tag"
        return
    fi
    local branch
    branch=$(git -C "$pack" rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [[ -n "$branch" && "$branch" != "HEAD" ]]; then
        echo "pack-version: $branch"
    else
        echo "pack-version: unknown"
    fi
}

# ai-config-markers: <comma list> | (none)
detect_ai_config() {
    local target="${1:-.}"
    local markers=()
    [[ -d "$target/.claude" ]]   && markers+=(".claude/")
    [[ -d "$target/.codex" ]]    && markers+=(".codex/")
    [[ -d "$target/.gemini" ]]   && markers+=(".gemini/")
    [[ -f "$target/CLAUDE.md" ]] && markers+=("CLAUDE.md")
    [[ -f "$target/AGENTS.md" ]] && markers+=("AGENTS.md")
    [[ -f "$target/GEMINI.md" ]] && markers+=("GEMINI.md")
    if (( ${#markers[@]} == 0 )); then
        echo "ai-config-markers: (none)"
    else
        local joined
        joined=$(IFS=,; printf '%s' "${markers[*]}")
        echo "ai-config-markers: $joined"
    fi
}

# x-files: <loc>/<name> lines (one per match) | x-files: (none)
# Scans the seven pack scan locations for `x-`-prefixed entries.
detect_x_files() {
    local target="${1:-.}"
    local found=0
    local loc entry name
    for loc in \
        ".claude/agents" \
        ".codex/agents" \
        ".gemini/agents" \
        ".claude/skills" \
        ".codex/skills" \
        ".gemini/skills" \
        "docs/pack/prompts"
    do
        [[ -d "$target/$loc" ]] || continue
        for entry in "$target/$loc"/x-*; do
            [[ -e "$entry" ]] || continue
            name=$(basename "$entry")
            echo "x-files: $loc/$name"
            found=1
        done
    done
    (( found == 0 )) && echo "x-files: (none)"
}

# improperly-added: <loc>/<name> lines | improperly-added: (none)
# Entries in the seven scan locations that are NOT pack-supplied (by
# roster lookup against $PACK/project-template/) and NOT `x-` prefixed.
# Requires $PACK to be set and to point at a valid pack repo.
detect_improperly_added_files() {
    local target="${1:-.}"
    local pack="${PACK:-}"
    if [[ -z "$pack" || ! -d "$pack/project-template" ]]; then
        echo "improperly-added: (error — PACK not set or pack invalid)"
        return 1
    fi

    # Build pack roster sets (newline-separated, sorted, deduped).
    local agent_roster skill_roster
    agent_roster=$(
        cd "$pack/project-template/.claude/agents" 2>/dev/null || return 1
        for f in *.md; do
            [[ -e "$f" ]] && printf '%s\n' "${f%.md}"
        done | sort -u
    )
    skill_roster=$(
        cd "$pack/project-template/skills" 2>/dev/null || return 1
        for d in */; do
            [[ -d "$d" ]] && printf '%s\n' "${d%/}"
        done | sort -u
    )

    local found=0
    local loc entry name stem

    # Agent dirs: top-level .md or .toml files; stem must be in agent_roster.
    for loc in ".claude/agents" ".codex/agents" ".gemini/agents"; do
        [[ -d "$target/$loc" ]] || continue
        for entry in "$target/$loc"/*.md "$target/$loc"/*.toml; do
            [[ -e "$entry" ]] || continue
            name=$(basename "$entry")
            [[ "$name" == x-* ]] && continue
            stem="${name%.md}"
            stem="${stem%.toml}"
            if ! printf '%s\n' "$agent_roster" | grep -qx "$stem"; then
                echo "improperly-added: $loc/$name"
                found=1
            fi
        done
    done

    # Skills dirs: top-level subdirectories; name must be in skill_roster.
    for loc in ".claude/skills" ".codex/skills" ".gemini/skills"; do
        [[ -d "$target/$loc" ]] || continue
        for entry in "$target/$loc"/*/; do
            [[ -d "$entry" ]] || continue
            name=$(basename "$entry")
            [[ "$name" == x-* ]] && continue
            if ! printf '%s\n' "$skill_roster" | grep -qx "$name"; then
                echo "improperly-added: $loc/$name"
                found=1
            fi
        done
    done

    # Prompts dir: .md files; stem must be in agent_roster, start with
    # x-, or equal the reserved pm-chat identifier.
    if [[ -d "$target/docs/pack/prompts" ]]; then
        for entry in "$target/docs/pack/prompts"/*.md; do
            [[ -e "$entry" ]] || continue
            name=$(basename "$entry")
            [[ "$name" == x-* ]] && continue
            stem="${name%.md}"
            [[ "$stem" == "pm-chat" ]] && continue
            if ! printf '%s\n' "$agent_roster" | grep -qx "$stem"; then
                echo "improperly-added: docs/pack/prompts/$name"
                found=1
            fi
        done
    fi

    (( found == 0 )) && echo "improperly-added: (none)"
}

# capabilities: <dim>:<val>, <dim>:<val>, ... | (none) | (placeholder) | (no CLAUDE.md) | (no Active skills line)
# Reads the `**Active skills:**` line from the target project's CLAUDE.md
# and maps each skill to a dimension value using a hardcoded table that
# mirrors the PLATFORM-SKILLS.md dimension rows. Consumed by
# add-capability.sh stage A2 per V10-DESIGN §5.14.2.
detect_installed_capabilities() {
    local target="${1:-.}"
    local claude="$target/CLAUDE.md"
    if [[ ! -f "$claude" ]]; then
        echo "capabilities: (no CLAUDE.md)"
        return
    fi

    local skills_line content
    skills_line=$(grep -m1 "^\*\*Active skills:\*\*" "$claude" 2>/dev/null || true)
    if [[ -z "$skills_line" ]]; then
        echo "capabilities: (no Active skills line)"
        return
    fi
    content="${skills_line#*\*\*Active skills:\*\* }"
    content="${content# }"
    if [[ "$content" == "["* ]]; then
        echo "capabilities: (placeholder)"
        return
    fi

    # Normalize skill list: strip backticks, split on commas, trim whitespace.
    local normalized skill
    normalized=$(printf '%s' "$content" | tr -d '`' | tr ',' '\n' \
        | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$' || true)

    # Map skills → dimension:value. Skills that don't map to a standalone
    # dimension (architectural components, language-agnostic skills, or
    # general-purpose helpers) are silently ignored — they don't represent
    # independently-addable capabilities.
    local caps=()
    while IFS= read -r skill; do
        [[ -z "$skill" ]] && continue
        case "$skill" in
            swift-best-practices)  caps+=("language:swift") ;;
            python-best-practices) caps+=("language:python") ;;
            cpp-language)          caps+=("language:cpp") ;;
            c-language)            caps+=("language:c") ;;
            objc-language)         caps+=("language:objc") ;;
            macos-architecture)    caps+=("platform:macos") ;;
            ios-architecture)      caps+=("platform:ios") ;;
            grpc-patterns)         caps+=("protocol:grpc") ;;
            rest-patterns)         caps+=("protocol:rest") ;;
            graphql-patterns)      caps+=("protocol:graphql") ;;
            realtime-patterns)     caps+=("protocol:realtime") ;;
            messaging-patterns)    caps+=("protocol:messaging") ;;
            soap-patterns)         caps+=("protocol:soap") ;;
            deployment-apple)      caps+=("role:apple-app") ;;
            deployment-python)     caps+=("role:python-server") ;;
        esac
    done <<< "$normalized"

    if (( ${#caps[@]} == 0 )); then
        echo "capabilities: (none)"
    else
        local joined
        joined=$(printf '%s\n' "${caps[@]}" | sort -u | paste -sd, - | sed 's/,/, /g')
        echo "capabilities: $joined"
    fi
}
