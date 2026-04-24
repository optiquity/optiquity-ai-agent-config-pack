#!/usr/bin/env bash
# migrate-v9-to-v10.sh — migrate a v9.3 project install to v10.0 pack content.
#
# Per V10-DESIGN §6.8, the migration is eight stages S0..S7. Each stage
# writes a sentinel under $BACKUP_DIR; a resumed run skips completed
# stages. S0 pre-flight implements the B4 sentinel-cleanup flow (plan
# C-046-15): if any prior-run sentinels exist in the backup dir, prompt
# Resume / Start fresh / Abort before proceeding. Default is Abort.
#
# Usage:
#     PACK=/path/to/pack ./scripts/migrate-v9-to-v10.sh
#
# The script refuses to proceed unless:
#   - $PACK is set and points at a valid pack repo with the v9.3 tag
#     resolvable and v10 content present on the current branch.
#   - The target working tree is clean.
#   - The §6.2 baseline invariants (v9.3 state) hold.
#
# The script does NOT commit. Review `git diff` and the report in
# $BACKUP_DIR/report.md before committing.

set -euo pipefail

readonly BACKUP_DIR=".pack-migration-backup/v9.3-to-v10.0"
readonly MIGRATION_BRANCH="migration-v9-to-v10"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Helpers ────────────────────────────────────────────────────────────────

say()  { printf '%s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

require_env() {
    local var="$1"
    if [[ -z "${!var:-}" ]]; then
        die "$var must be set"
    fi
}

prompt_default_no() {
    local prompt="$1" ans lower
    read -r -p "$prompt [y/N] " ans || ans=""
    lower=$(printf '%s' "$ans" | tr '[:upper:]' '[:lower:]')
    case "$lower" in
        y|yes) return 0 ;;
        *)     return 1 ;;
    esac
}

sentinel_path() { echo "$BACKUP_DIR/stage-$1.done"; }
sentinel_exists() { [[ -f "$(sentinel_path "$1")" ]]; }
write_sentinel() { date -u +"%Y-%m-%dT%H:%M:%SZ" > "$(sentinel_path "$1")"; }

# ── Source shared detection library ────────────────────────────────────────

if [[ ! -f "$SCRIPT_DIR/lib/detect.sh" ]]; then
    die "missing shared detection library: $SCRIPT_DIR/lib/detect.sh"
fi
# shellcheck source=lib/detect.sh
source "$SCRIPT_DIR/lib/detect.sh"

# ── Stage S0 — pre-flight ──────────────────────────────────────────────────

stage_s0_preflight() {
    say "── S0 — pre-flight ──"

    # B4 — sentinel cleanup flow.
    if [[ -d "$BACKUP_DIR" ]]; then
        local existing
        existing=$(find "$BACKUP_DIR" -maxdepth 1 -type f -name "stage-S*.done" 2>/dev/null | sort)
        if [[ -n "$existing" ]]; then
            say "Prior migration run detected — sentinels:"
            printf '  %s\n' $existing
            local ans="" lower=""
            read -r -p "Resume [r] / Start fresh [f] / Abort [a]? " ans || ans="a"
            lower=$(printf '%s' "$ans" | tr '[:upper:]' '[:lower:]')
            case "$lower" in
                r|resume)
                    say "Resuming from first stage without a sentinel."
                    ;;
                f|fresh|start*)
                    say "Removing .pack-migration-backup/ and starting fresh."
                    rm -rf .pack-migration-backup
                    ;;
                *)
                    say "Aborted. No changes made."
                    exit 0
                    ;;
            esac
        fi
    fi

    # Skip rest of S0 if already completed.
    if sentinel_exists "S0"; then
        say "S0 sentinel present — skipping pre-flight."
        return 0
    fi

    # 1. Clean working tree.
    local wt
    wt=$(detect_clean_working_tree | awk -F': ' '{print $2}')
    if [[ "$wt" != "clean" ]]; then
        die "working tree is dirty; commit or stash before proceeding"
    fi

    # 2. Migration branch.
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD)
    if [[ "$branch" != "$MIGRATION_BRANCH" ]]; then
        say "creating and checking out branch $MIGRATION_BRANCH"
        git checkout -b "$MIGRATION_BRANCH"
    fi

    # 3. Pack repo + v9.3 tag + v10 content.
    require_env PACK
    local pack_status
    pack_status=$(detect_pack_path "$PACK" | awk -F': ' '{print $2}')
    if [[ "$pack_status" != "valid" ]]; then
        die "PACK ($PACK) is not a valid pack repo: $pack_status"
    fi
    if ! git -C "$PACK" rev-parse v9.3 >/dev/null 2>&1; then
        die "v9.3 tag not resolvable in $PACK — required for PROMPT-TEMPLATES.md diff"
    fi
    if [[ ! -d "$PACK/project-template/docs/pack/prompts" ]]; then
        die "v10 content not present in $PACK (no docs/pack/prompts/ in project-template)"
    fi

    # 4. §6.2 baseline invariants.
    [[ -f docs/pack/PROMPT-TEMPLATES.md ]] || die "baseline failed: docs/pack/PROMPT-TEMPLATES.md missing"
    [[ -d .claude/agents ]] || die "baseline failed: .claude/agents/ missing"
    local claude_count
    claude_count=$(find .claude/agents -mindepth 1 -maxdepth 1 -name "*.md" ! -name "x-*" | wc -l | tr -d ' ')
    if (( claude_count < 16 )); then
        die "baseline failed: fewer than 16 pack agents in .claude/agents/ (found $claude_count)"
    fi
    [[ -d .gemini/agents ]] || die "baseline failed: .gemini/agents/ missing (v9.3 BD-043)"
    [[ -f docs/pack/PLATFORM-SKILLS.md ]] || die "baseline failed: docs/pack/PLATFORM-SKILLS.md missing"

    # 5. x-file audit.
    say "x-file audit:"
    detect_x_files | sed 's/^/  /'

    # 6. Improperly-added file audit.
    say "improperly-added-file audit:"
    detect_improperly_added_files | sed 's/^/  /' || true

    # 7. Stray x- files inside pack skill subdirectories.
    local stray=0 tool stray_file
    for tool in claude codex gemini; do
        if [[ -d ".${tool}/skills" ]]; then
            while IFS= read -r stray_file; do
                [[ -z "$stray_file" ]] && continue
                warn "stray x- file inside pack skill directory: $stray_file"
                stray=1
            done < <(find ".${tool}/skills" -mindepth 2 -name "x-*" 2>/dev/null)
        fi
    done
    (( stray == 0 )) || die "resolve stray x- files inside pack skill directories before migrating"

    # 8. Create backup dir + .gitignore entry.
    mkdir -p "$BACKUP_DIR"
    if [[ -f .gitignore ]] && ! grep -Fxq ".pack-migration-backup/" .gitignore; then
        printf '\n.pack-migration-backup/\n' >> .gitignore
    elif [[ ! -f .gitignore ]]; then
        printf '.pack-migration-backup/\n' > .gitignore
    fi

    write_sentinel "S0"
    say "S0 complete."
}

# ── Stage S1 — selective-replace agent files (three tools) ─────────────────

stage_s1_agents() {
    say "── S1 — replace pack agents ──"
    if sentinel_exists "S1"; then say "S1 sentinel present — skipping."; return 0; fi

    mkdir -p "$BACKUP_DIR/.claude/agents" "$BACKUP_DIR/.codex/agents" "$BACKUP_DIR/.gemini/agents"

    local tool src_ext dst_dir pack_src
    for tool in claude codex gemini; do
        case "$tool" in
            codex)  src_ext="toml" ;;
            *)      src_ext="md" ;;
        esac
        pack_src="$PACK/project-template/.${tool}/agents"
        dst_dir=".${tool}/agents"
        mkdir -p "$dst_dir"
        # Backup every current pack agent file.
        for f in "$pack_src"/*.${src_ext}; do
            [[ -e "$f" ]] || continue
            local name
            name=$(basename "$f")
            if [[ -f "$dst_dir/$name" ]]; then
                cp "$dst_dir/$name" "$BACKUP_DIR/.${tool}/agents/$name"
                rm "$dst_dir/$name"
            fi
            cp "$f" "$dst_dir/$name"
        done
        # x-*.${src_ext} files in dst_dir are intentionally left untouched.
    done

    write_sentinel "S1"
    say "S1 complete."
}

# ── Stage S2 — selective-replace skill directories (three tools) ───────────

stage_s2_skills() {
    say "── S2 — replace pack skills ──"
    if sentinel_exists "S2"; then say "S2 sentinel present — skipping."; return 0; fi

    mkdir -p "$BACKUP_DIR/.claude/skills" "$BACKUP_DIR/.codex/skills" "$BACKUP_DIR/.gemini/skills"

    local tool dst_dir pack_src
    for tool in claude codex gemini; do
        pack_src="$PACK/project-template/skills"
        dst_dir=".${tool}/skills"
        mkdir -p "$dst_dir"
        local skill_dir skill_name
        for skill_dir in "$pack_src"/*/; do
            [[ -d "$skill_dir" ]] || continue
            skill_name=$(basename "$skill_dir")
            if [[ -d "$dst_dir/$skill_name" ]]; then
                cp -r "$dst_dir/$skill_name" "$BACKUP_DIR/.${tool}/skills/$skill_name"
                rm -rf "$dst_dir/$skill_name"
            fi
            mkdir -p "$dst_dir/$skill_name"
            cp "$skill_dir/SKILL.md" "$dst_dir/$skill_name/SKILL.md"
        done
        # x-*/ directories in dst_dir are intentionally left untouched.
    done

    write_sentinel "S2"
    say "S2 complete."
}

# ── Stage S3 — replace scripts, agent-run.sh, configs ─────────────────────

stage_s3_scripts_and_config() {
    say "── S3 — replace scripts, agent-run.sh, configs ──"
    if sentinel_exists "S3"; then say "S3 sentinel present — skipping."; return 0; fi

    # Backup and replace scripts/ (project-template/scripts/).
    mkdir -p "$BACKUP_DIR/scripts"
    if [[ -d scripts ]]; then
        cp -r scripts/. "$BACKUP_DIR/scripts/" 2>/dev/null || true
    fi
    mkdir -p scripts
    if [[ -d "$PACK/project-template/scripts" ]]; then
        for f in "$PACK/project-template/scripts"/*; do
            [[ -e "$f" ]] || continue
            cp "$f" scripts/
        done
        chmod +x scripts/*.sh 2>/dev/null || true
    fi

    # agent-run.sh at project root.
    if [[ -f agent-run.sh ]]; then
        cp agent-run.sh "$BACKUP_DIR/agent-run.sh"
    fi
    if [[ -f "$PACK/project-template/agent-run.sh" ]]; then
        cp "$PACK/project-template/agent-run.sh" agent-run.sh
        chmod +x agent-run.sh
    fi

    # .codex/config.toml, .claude/settings.json, .mcp.json.example.
    mkdir -p "$BACKUP_DIR/.codex" "$BACKUP_DIR/.claude"
    local f
    for f in .codex/config.toml .claude/settings.json .mcp.json.example; do
        if [[ -f "$f" ]]; then
            mkdir -p "$BACKUP_DIR/$(dirname "$f")"
            cp "$f" "$BACKUP_DIR/$f"
        fi
        if [[ -f "$PACK/project-template/$f" ]]; then
            mkdir -p "$(dirname "$f")"
            cp "$PACK/project-template/$f" "$f"
        fi
    done

    write_sentinel "S3"
    say "S3 complete."
}

# ── Stage S4 — create docs/pack/prompts/ + copy 11 files ──────────────────

stage_s4_prompts_dir() {
    say "── S4 — create docs/pack/prompts/ ──"
    if sentinel_exists "S4"; then say "S4 sentinel present — skipping."; return 0; fi

    mkdir -p docs/pack/prompts
    local src="$PACK/project-template/docs/pack/prompts"
    [[ -d "$src" ]] || die "missing $src in pack"
    local f
    for f in "$src"/*.md; do
        [[ -e "$f" ]] || continue
        cp "$f" docs/pack/prompts/
    done

    write_sentinel "S4"
    say "S4 complete."
}

# ── Stage S5 — trinity + PLATFORM-SKILLS + pack docs splice merge ──────────

stage_s5_trinity_splice() {
    say "── S5 — splice-merge trinity + pack docs ──"
    if sentinel_exists "S5"; then say "S5 sentinel present — skipping."; return 0; fi

    # PLATFORM-SKILLS.md splice.
    local ps_src="$PACK/project-template/docs/pack/PLATFORM-SKILLS.md"
    [[ -f "$ps_src" ]] || die "missing $ps_src"
    cp docs/pack/PLATFORM-SKILLS.md "$BACKUP_DIR/docs-pack-PLATFORM-SKILLS.md"
    python3 "$PACK/scripts/merge-platform-skills.py" \
        "$ps_src" docs/pack/PLATFORM-SKILLS.md docs/pack/PLATFORM-SKILLS.md.new
    mv docs/pack/PLATFORM-SKILLS.md.new docs/pack/PLATFORM-SKILLS.md

    # Trinity splice (atomic across three files — B6 pre-check inside helper).
    local trinity_tmp
    trinity_tmp=$(mktemp -d)
    # Backup current trinity before overwrite.
    local t
    for t in CLAUDE.md AGENTS.md GEMINI.md; do
        [[ -f "$t" ]] && cp "$t" "$BACKUP_DIR/$t"
    done
    if ! python3 "$PACK/scripts/merge-trinity.py" \
            "$PACK/project-template" "." "$trinity_tmp"; then
        rm -rf "$trinity_tmp"
        die "merge-trinity.py failed (B6 Active-skills pre-check or other); no trinity files written this run"
    fi
    for t in CLAUDE.md AGENTS.md GEMINI.md; do
        cp "$trinity_tmp/$t" "$t"
    done
    rm -rf "$trinity_tmp"

    # Pack-owned docs copied verbatim (no splice).
    # PM-CHAT.md: pack `project-template/docs/pack/PM-CHAT.md` → project `docs/pack/PM-CHAT.md`.
    if [[ -f docs/pack/PM-CHAT.md ]]; then
        mkdir -p "$BACKUP_DIR/docs/pack"
        cp docs/pack/PM-CHAT.md "$BACKUP_DIR/docs/pack/PM-CHAT.md"
    fi
    if [[ -f "$PACK/project-template/docs/pack/PM-CHAT.md" ]]; then
        mkdir -p docs/pack
        cp "$PACK/project-template/docs/pack/PM-CHAT.md" docs/pack/PM-CHAT.md
    fi
    # METHODOLOGY.md: pack `supporting-docs/METHODOLOGY.md` → project root `METHODOLOGY.md`.
    if [[ -f METHODOLOGY.md ]]; then
        cp METHODOLOGY.md "$BACKUP_DIR/METHODOLOGY.md"
    fi
    if [[ -f "$PACK/supporting-docs/METHODOLOGY.md" ]]; then
        cp "$PACK/supporting-docs/METHODOLOGY.md" METHODOLOGY.md
    fi

    write_sentinel "S5"
    say "S5 complete."
}

# ── Stage S6 — PROMPT-TEMPLATES.md diff vs v9.3 ──────────────────────────

stage_s6_prompt_templates_diff() {
    say "── S6 — PROMPT-TEMPLATES.md diff vs v9.3 ──"
    if sentinel_exists "S6"; then say "S6 sentinel present — skipping."; return 0; fi

    local proj_file="docs/pack/PROMPT-TEMPLATES.md"
    [[ -f "$proj_file" ]] || die "$proj_file missing at S6 (unexpected)"

    # Backup project file unconditionally.
    cp "$proj_file" "$BACKUP_DIR/docs-pack-PROMPT-TEMPLATES.md"

    # Compare normalized content with v9.3 baseline from the pack repo.
    local v93_content proj_content
    v93_content=$(git -C "$PACK" show v9.3:supporting-docs/PROMPT-TEMPLATES.md \
        | tr -d '\r' | sed 's/[[:space:]]*$//' )
    proj_content=$(cat "$proj_file" | tr -d '\r' | sed 's/[[:space:]]*$//' )

    if [[ "$v93_content" == "$proj_content" ]]; then
        say "customization: none — deleting PROMPT-TEMPLATES.md (backup preserved)"
        rm "$proj_file"
        echo "customization: none" > "$BACKUP_DIR/status.txt"
    else
        say "customization: divergence detected — preserving as docs/pack/prompts/_v9-backup.md"
        mv "$proj_file" docs/pack/prompts/_v9-backup.md
        echo "customization: divergence detected; reconciliation flag set" > "$BACKUP_DIR/status.txt"
        echo "reconciliation-flag: set" >> "$BACKUP_DIR/status.txt"
    fi

    write_sentinel "S6"
    say "S6 complete."
}

# ── Stage S7 — post-migration report ──────────────────────────────────────

stage_s7_report() {
    say "── S7 — write migration report ──"
    if sentinel_exists "S7"; then say "S7 sentinel present — skipping."; return 0; fi

    local report="$BACKUP_DIR/report.md"
    local pack_ver
    pack_ver=$(detect_pack_version "$PACK" | awk -F': ' '{print $2}')

    {
        echo "# v9.3 → v10.0 migration report"
        echo ""
        echo "**Date:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
        echo "**Pack version:** $pack_ver"
        echo "**Target project:** $(pwd)"
        echo ""
        echo "## Customization status"
        echo ""
        if [[ -f "$BACKUP_DIR/status.txt" ]]; then
            cat "$BACKUP_DIR/status.txt"
        fi
        echo ""
        echo "## x- files preserved"
        echo ""
        detect_x_files
        echo ""
        echo "## Improperly-added files (post-migration Procedure 5.4 candidates)"
        echo ""
        detect_improperly_added_files || true
        echo ""
        echo "## Next steps"
        echo ""
        echo "1. Review \`git diff\` and this report."
        echo "2. If \`_v9-backup.md\` exists under \`docs/pack/prompts/\`, expect"
        echo "   the PM chat to invoke Procedure 5-R on its next run."
        echo "3. Commit the migration ON THE \`$MIGRATION_BRANCH\` BRANCH."
        echo "4. Follow \`supporting-docs/MIGRATION-v9-to-v10.md\` Steps 5–7."
        echo ""
        echo "## Rollback"
        echo ""
        echo "See \`supporting-docs/MIGRATION-v9-to-v10.md\` §12 for rollback commands."
        echo "Backup is at \`$BACKUP_DIR/\`."
    } > "$report"

    write_sentinel "S7"
    say "S7 complete. Report written to $report"
}

# ── Main ───────────────────────────────────────────────────────────────────

main() {
    say "migrate-v9-to-v10.sh — v9.3 → v10.0 pack migration"
    say "target:  $(pwd)"
    say "pack:    ${PACK:-(unset)}"
    say ""

    stage_s0_preflight
    stage_s1_agents
    stage_s2_skills
    stage_s3_scripts_and_config
    stage_s4_prompts_dir
    stage_s5_trinity_splice
    stage_s6_prompt_templates_diff
    stage_s7_report

    say ""
    say "Migration complete. Review \`git diff\` and \`$BACKUP_DIR/report.md\`"
    say "before committing on branch $MIGRATION_BRANCH."
}

main "$@"
