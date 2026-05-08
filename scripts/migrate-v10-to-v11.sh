#!/usr/bin/env bash
# migrate-v10-to-v11.sh — one-shot v10 → v11 migrator (BD-085).
#
# Phase A only: applies the forced v10→v11 changes (trinity addenda,
# HELP-FRAGMENT installs, tracker.toml.example, issue-template forms,
# per-CLI pack-help surfaces, BD-042 doc relocation if any v9-era files
# remain at project root). Tracker opt-in is NOT part of this script —
# users run `pack tracker init` post-migration to opt in.
#
# Customization preservation is delegated to scripts/lib/customization-preserve.sh
# (BD-088); a truthful per-file report.md is rendered to
# .pack-migrate-v10-to-v11/report.md.
#
# Usage:
#     PACK=/path/to/pack ./scripts/migrate-v10-to-v11.sh [target-dir]
#
# Exit codes:
#     0   Success
#     10  $PACK invalid
#     11  Target is not a git repo
#     12  Working tree not clean
#     13  Target does not appear to be a v10 pack-configured project
#     14  v10 baseline not available in pack repo (tag missing)
#     15  BD-088 customization library unavailable
#     21–30  Stage failure
#     99  Internal error (set -euo pipefail trap)
#
# BD-095 will extend this script with --dry-run / --apply / --resume
# modes; the current implementation is a single non-resumable run.

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly EXIT_PACK_INVALID=10
readonly EXIT_NOT_GIT=11
readonly EXIT_DIRTY=12
readonly EXIT_NOT_V10=13
readonly EXIT_BASELINE_MISSING=14
readonly EXIT_LIB_MISSING=15
readonly EXIT_INTERNAL=99

# v10 tag that anchors the baseline extraction. Floats by design — both
# `v10` and `v10.0` should resolve to the same commit; we prefer the
# floating major tag.
readonly V10_TAG="${V10_TAG:-v10}"

say()  { printf '%s\n' "$*"; }
info() { printf '  %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$1" >&2; exit "${2:-$EXIT_INTERNAL}"; }

fail_stage() {
    local stage="$1" msg="$2"
    local n="${stage#S}"
    local code=$(( 20 + n ))
    (( code > 30 )) && code=30
    printf 'error: stage %s failed: %s\n' "$stage" "$msg" >&2
    exit "$code"
}

# ── Pre-flight ─────────────────────────────────────────────────────────────

stage_s0_preflight() {
    say "── S0 — pre-flight ──"

    [[ -n "${PACK:-}" ]] || die "PACK environment variable not set" "$EXIT_PACK_INVALID"
    [[ -d "$PACK/project-template" ]] || die "PACK ($PACK) missing project-template/" "$EXIT_PACK_INVALID"
    [[ -f "$PACK/scripts/lib/three-way.sh" ]] || die "PACK missing three-way.sh" "$EXIT_PACK_INVALID"
    [[ -f "$PACK/scripts/lib/customization-preserve.sh" ]] \
        || die "PACK missing BD-088 customization-preserve library" "$EXIT_LIB_MISSING"
    [[ -f "$PACK/scripts/lib/customization-report.sh" ]] \
        || die "PACK missing BD-088 customization-report library" "$EXIT_LIB_MISSING"

    git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1 \
        || die "target is not a git repo: $TARGET" "$EXIT_NOT_GIT"

    if [[ -n "$(git -C "$TARGET" status --porcelain)" ]]; then
        die "target working tree is dirty; commit or stash first" "$EXIT_DIRTY"
    fi

    # Sanity: target must look like v10 — trinity present + .claude/ present.
    if [[ ! -f "$TARGET/CLAUDE.md" || ! -d "$TARGET/.claude" ]]; then
        die "target does not appear to be a pack-configured project (CLAUDE.md or .claude/ missing); BD-085 is for v10 → v11 migration only" \
            "$EXIT_NOT_V10"
    fi

    # v10 baseline tag must exist in pack repo.
    if ! git -C "$PACK" rev-parse "$V10_TAG" >/dev/null 2>&1; then
        die "v10 baseline tag '$V10_TAG' not present in pack repo at $PACK" \
            "$EXIT_BASELINE_MISSING"
    fi
    info "v10 baseline tag resolved: $V10_TAG"

    # Refuse to proceed when stale `--update` sidecars exist in the
    # working tree. Both upgrade paths use single-slot sidecars; mixing
    # `.pre-update` (from a prior init-project.sh --update) with
    # `.v10-customized` (this migrator) leaves the user with two
    # parallel pre-migration snapshots and ambiguous reconciliation.
    local stale_sidecars
    stale_sidecars=$(find "$TARGET" -type f -name "*.pre-update" \
        -not -path "*/.git/*" -not -path "*/.pack-update/*" \
        -not -path "*/.pack-migrate-v10-to-v11-backup/*" 2>/dev/null | head -20)
    if [[ -n "$stale_sidecars" ]]; then
        say "refusing to proceed: prior \`--update\` sidecars present:"
        printf '  %s\n' $stale_sidecars >&2
        die "reconcile or remove the .pre-update sidecars above before running migrate-v10-to-v11.sh" \
            "$EXIT_DIRTY"
    fi
}

# ── Backup ────────────────────────────────────────────────────────────────

stage_s1_backup() {
    say "── S1 — backup ──"
    BACKUP_DIR="$TARGET/.pack-migrate-v10-to-v11-backup"
    if [[ -d "$BACKUP_DIR" ]]; then
        fail_stage S1 "backup directory already exists: $BACKUP_DIR — rename it (mv $BACKUP_DIR $BACKUP_DIR.prev) or remove it before re-running"
    fi
    mkdir -p "$BACKUP_DIR"
    # Backup the entire working tree (not just HEAD). git archive HEAD
    # would miss gitignored files — `.gemini/.env` is gitignored by the
    # pack template and is exactly the file the gemini-env strategy
    # rewrites, so it must be in the backup. Excludes: .git/ itself,
    # the backup dir we just created, the BD-088 state dir, and the
    # legacy .pack-update dir (init-project --update). Use bash 3.2-
    # compatible find (no -prune-style; rely on tar's --exclude-from).
    local exclude_list
    exclude_list=$(mktemp)
    cat > "$exclude_list" <<EOF
.git
.pack-migrate-v10-to-v11
.pack-migrate-v10-to-v11-backup
.pack-update
EOF
    tar -cf - -C "$TARGET" --exclude-from="$exclude_list" . | tar -x -C "$BACKUP_DIR"
    rm -f "$exclude_list"
    [[ -f "$BACKUP_DIR/CLAUDE.md" ]] || fail_stage S1 "backup verification failed (CLAUDE.md missing in backup)"
    info "backup written: $BACKUP_DIR (full working tree, excludes .git/ + state dirs)"
}

# ── Customization-preserve library setup ──────────────────────────────────

stage_s2_libs() {
    say "── S2 — initialize BD-088 customization-preserve state ──"
    export _CP_PACK_ROOT="$PACK"
    # shellcheck source=lib/three-way.sh disable=SC1091
    source "$PACK/scripts/lib/three-way.sh"
    # shellcheck source=lib/customization-preserve.sh disable=SC1091
    source "$PACK/scripts/lib/customization-preserve.sh"
    # shellcheck source=lib/customization-report.sh disable=SC1091
    source "$PACK/scripts/lib/customization-report.sh"

    STATE_DIR="$TARGET/.pack-migrate-v10-to-v11"
    rm -rf "$STATE_DIR"
    customization_preserve_init "$STATE_DIR" ".v10-customized"
    info "state dir: $STATE_DIR"
}

# ── v10 baseline extraction ───────────────────────────────────────────────
#
# Extract a file from the v10 tag of the pack repo into a tmp file. Echo
# the tmp path on stdout, or empty string if the file did not exist at
# v10. Caller is responsible for `rm -f` on the path.
v10_baseline_to_tmp() {
    local pack_path="$1"
    local tmp; tmp=$(mktemp)
    if git -C "$PACK" show "$V10_TAG:$pack_path" > "$tmp" 2>/dev/null; then
        printf '%s\n' "$tmp"
    else
        rm -f "$tmp"
        printf ''
    fi
}

# ── Per-file dispatch via BD-088 ──────────────────────────────────────────
#
# entries syntax: pack_relpath:project_relpath:class
#   pack_relpath     — path under $PACK (used both for THEIRS and for
#                      `git show v10:<path>` extraction)
#   project_relpath  — path under $TARGET
#   class            — explicit BD-088 class
stage_s3_dispatch() {
    say "── S3 — dispatch v10 → v11 file changes via BD-088 ──"

    local entries=(
        "project-template/CLAUDE.md:CLAUDE.md:trinity"
        "project-template/AGENTS.md:AGENTS.md:trinity"
        "project-template/GEMINI.md:GEMINI.md:trinity"
        "project-template/.claude/settings.json:.claude/settings.json:claude-settings"
        "project-template/.mcp.json.example:.mcp.json.example:claude-mcp-example"
        "project-template/.codex/config.toml:.codex/config.toml:codex-config"
        "project-template/.codex/config.toml.example:.codex/config.toml.example:codex-config-example"
        "project-template/.codex/requirements.toml:.codex/requirements.toml:codex-config"
        "project-template/.gemini/.env.example:.gemini/.env:gemini-env"
        "project-template/.gemini/settings.json:.gemini/settings.json:claude-settings"
        "project-template/docs/pack/PM-CHAT.md:docs/pack/PM-CHAT.md:pm-chat"
        "project-template/docs/pack/PLATFORM-SKILLS.md:docs/pack/PLATFORM-SKILLS.md:generic"
        "project-template/docs/pack/PACK-FEEDBACK.md:docs/pack/PACK-FEEDBACK.md:generic"
        "project-template/docs/pack/PROMPT-TEMPLATES.md:docs/pack/PROMPT-TEMPLATES.md:generic"
    )

    local entry pack_rel proj_rel cls theirs ours dest base
    local processed=0
    for entry in "${entries[@]}"; do
        pack_rel="${entry%%:*}"
        local rest="${entry#*:}"
        proj_rel="${rest%%:*}"
        cls="${rest##*:}"
        theirs="$PACK/$pack_rel"
        ours="$TARGET/$proj_rel"
        dest="$TARGET/$proj_rel"
        base=$(v10_baseline_to_tmp "$pack_rel")
        [[ -f "$theirs" ]] || theirs=""
        [[ -f "$ours" ]]   || ours=""
        # Always dispatch — even when both sides absent, the BD-088
        # contract records `removed-everywhere` so the report is truthful.
        # Skipping would hide a planned-but-not-shipped pack-side file.
        customization_preserve "$base" "$ours" "$theirs" "$proj_rel" "$dest" "$cls" >/dev/null
        [[ -n "$base" ]] && rm -f "$base"
        processed=$((processed + 1))
    done
    info "BD-088 dispatch: $processed file(s) processed"

    # Pack-shipped scripts and per-CLI agents iterate the source dir to
    # capture additions/removals across the v10 → v11 delta.
    _stage_s3_iter_dir "project-template/scripts" "scripts" pack-script
    local tool
    for tool in claude codex gemini; do
        _stage_s3_iter_dir "project-template/.${tool}/agents" \
            ".${tool}/agents" pack-agent
    done
}

# Iterate every regular file under `$PACK/$pack_dir`, derive the parallel
# project-relative path under `$proj_dir`, and dispatch via BD-088.
_stage_s3_iter_dir() {
    local pack_dir="$1" proj_dir="$2" cls="$3"
    [[ -d "$PACK/$pack_dir" ]] || return 0
    local f rel pack_rel theirs ours dest base
    while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        rel="${f#"$PACK/$pack_dir/"}"
        pack_rel="$pack_dir/$rel"
        local proj_rel="$proj_dir/$rel"
        theirs="$f"
        ours="$TARGET/$proj_rel"
        dest="$TARGET/$proj_rel"
        base=$(v10_baseline_to_tmp "$pack_rel")
        [[ -f "$ours" ]] || ours=""
        customization_preserve "$base" "$ours" "$theirs" "$proj_rel" "$dest" "$cls" >/dev/null
        [[ -n "$base" ]] && rm -f "$base"
    done < <(find "$PACK/$pack_dir" -type f -print 2>/dev/null)
}

# ── BD-042 relocation (legacy root-level docs) ────────────────────────────
#
# v9 projects that upgraded to v10 may still have METHODOLOGY.md /
# PROMPT-TEMPLATES.md / etc. at project root. v11 confirms these belong
# under docs/pack/ — relocate any stragglers. The customization-preserve
# library is not invoked here: this is a `git mv` semantic move.
stage_s4_bd042_relocation() {
    say "── S4 — BD-042 relocation of legacy root docs (if any) ──"
    local moved=0
    local f
    for f in METHODOLOGY.md PROMPT-TEMPLATES.md PM-CHAT.md \
             PLATFORM-SKILLS.md PACK-FEEDBACK.md; do
        if [[ -f "$TARGET/$f" ]]; then
            mkdir -p "$TARGET/docs/pack"
            if [[ -f "$TARGET/docs/pack/$f" ]]; then
                # Both root and docs/pack have the file — keep docs/pack
                # canonical, sidecar the root copy for the user to inspect.
                mv "$TARGET/$f" "$TARGET/$f.relocated-from-root"
                info "relocated: $f → $f.relocated-from-root (docs/pack/$f already present)"
            else
                # Track via git when the root copy is tracked (clean-tree
                # invariant from S0 means HEAD-tracked is the typical case).
                # Fall back to plain `mv` ONLY when git mv reports the file
                # is not tracked; any other failure is a defect.
                local mv_stderr untracked=0
                mv_stderr=$(git -C "$TARGET" mv "$f" "docs/pack/$f" 2>&1) || {
                    if [[ "$mv_stderr" == *"not under version control"* \
                       || "$mv_stderr" == *"did not match"* ]]; then
                        mv "$TARGET/$f" "$TARGET/docs/pack/$f"
                        untracked=1
                    else
                        fail_stage S4 "git mv $f → docs/pack/$f failed: $mv_stderr"
                    fi
                }
                [[ -f "$TARGET/docs/pack/$f" ]] || \
                    fail_stage S4 "post-relocation verification failed: docs/pack/$f missing"
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

# ── v11 artifact install (S11 of init-project.sh equivalent) ──────────────

stage_s5_v11_artifacts() {
    say "── S5 — install v11 client artifacts ──"

    # HELP-FRAGMENT*.md
    mkdir -p "$TARGET/docs/pack"
    local help_src
    for help_src in HELP-FRAGMENT.md HELP-FRAGMENT-TRACKER.md; do
        local pack_file="$PACK/project-template/docs/pack/$help_src"
        if [[ -f "$pack_file" && ! -f "$TARGET/docs/pack/$help_src" ]]; then
            cp "$pack_file" "$TARGET/docs/pack/$help_src"
        fi
    done

    # tracker.toml.example
    if [[ -f "$PACK/project-template/tracker.toml.example" \
       && ! -f "$TARGET/tracker.toml.example" ]]; then
        cp "$PACK/project-template/tracker.toml.example" "$TARGET/tracker.toml.example"
    fi

    # .github/ISSUE_TEMPLATE/*
    if [[ -d "$PACK/project-template/.github/ISSUE_TEMPLATE" ]]; then
        mkdir -p "$TARGET/.github/ISSUE_TEMPLATE"
        local form
        for form in "$PACK/project-template/.github/ISSUE_TEMPLATE"/*.yml; do
            [[ -e "$form" ]] || continue
            local name; name=$(basename "$form")
            [[ -f "$TARGET/.github/ISSUE_TEMPLATE/$name" ]] && continue
            cp "$form" "$TARGET/.github/ISSUE_TEMPLATE/$name"
        done
    fi

    # Per-CLI pack-help surfaces.
    if [[ -d "$PACK/project-template/.claude/skills/pack-help" \
       && ! -f "$TARGET/.claude/skills/pack-help/SKILL.md" ]]; then
        mkdir -p "$TARGET/.claude/skills/pack-help"
        cp "$PACK/project-template/.claude/skills/pack-help/SKILL.md" \
            "$TARGET/.claude/skills/pack-help/SKILL.md"
    fi
    if [[ -d "$PACK/project-template/.codex/skills/pack-help" \
       && ! -f "$TARGET/.codex/skills/pack-help/SKILL.md" ]]; then
        mkdir -p "$TARGET/.codex/skills/pack-help"
        cp "$PACK/project-template/.codex/skills/pack-help/SKILL.md" \
            "$TARGET/.codex/skills/pack-help/SKILL.md"
    fi
    if [[ -f "$PACK/project-template/.gemini/commands/pack-help.toml" \
       && ! -f "$TARGET/.gemini/commands/pack-help.toml" ]]; then
        mkdir -p "$TARGET/.gemini/commands"
        cp "$PACK/project-template/.gemini/commands/pack-help.toml" \
            "$TARGET/.gemini/commands/pack-help.toml"
    fi

    # The pack-help shell script + its single dep (lib/detect.sh) — the
    # per-CLI skills/commands above invoke `bash scripts/pack-help.sh`
    # relative to the project. Without these copies the slash-command
    # surfaces fail at first invocation (BD-097 audit B-1).
    mkdir -p "$TARGET/scripts/lib"
    if [[ -f "$PACK/scripts/pack-help.sh" \
       && ! -f "$TARGET/scripts/pack-help.sh" ]]; then
        cp "$PACK/scripts/pack-help.sh" "$TARGET/scripts/pack-help.sh"
        chmod +x "$TARGET/scripts/pack-help.sh"
    fi
    if [[ -f "$PACK/scripts/lib/detect.sh" \
       && ! -f "$TARGET/scripts/lib/detect.sh" ]]; then
        cp "$PACK/scripts/lib/detect.sh" "$TARGET/scripts/lib/detect.sh"
    fi
}

# ── Render report ─────────────────────────────────────────────────────────

stage_s6_report() {
    say "── S6 — render truthful migration report ──"
    local report="$STATE_DIR/report.md"
    customization_report "$STATE_DIR/dispositions.tsv" "$report" \
        "v10 → v11 migration customization report"
    local count
    count=$(customization_findings_count)
    say ""
    say "Migration complete. $count files processed by BD-088 dispatch."
    say "Backup: $BACKUP_DIR (faithful working-tree snapshot)"
    say "Report: $report"
    say ""
    say "To revert this migration:"
    say "  1. From a clean shell:"
    say "       cd $TARGET"
    say "       rm -rf .pack-migrate-v10-to-v11"
    say "       (rsync -a --delete --exclude=.git/ \\"
    say "          --exclude=.pack-migrate-v10-to-v11-backup/ \\"
    say "          .pack-migrate-v10-to-v11-backup/ ./)"
    say "  2. Inspect with \`git diff\`."
    say "  3. When satisfied, remove .pack-migrate-v10-to-v11-backup/."
    if grep -q "needs-reconciliation" "$STATE_DIR/dispositions.tsv" 2>/dev/null; then
        say ""
        say "NOTE: one or more files need manual reconciliation. Review the"
        say "report's \"Files needing manual reconciliation\" section and"
        say "inspect the named .v10-customized sidecars."
    fi
    say ""
    say "To opt into the v11 issue-tracker integration, run:"
    say "  pack tracker init"
}

# ── Main ──────────────────────────────────────────────────────────────────

usage() {
    say "Usage: PACK=/path/to/pack migrate-v10-to-v11.sh [target-dir]"
    say ""
    say "  --help     Show this message and exit"
    say "  V10_TAG    Override the v10 baseline tag (default: v10)"
}

main() {
    local positional=()
    while (( $# > 0 )); do
        case "$1" in
            --help|-h) usage; exit 0 ;;
            --*)       die "unknown option: $1 (try --help)" "$EXIT_INTERNAL" ;;
            *)         positional+=("$1") ;;
        esac
        shift
    done
    TARGET="${positional[0]:-.}"
    TARGET=$(cd "$TARGET" 2>/dev/null && pwd || echo "$TARGET")

    stage_s0_preflight
    stage_s1_backup
    stage_s2_libs
    stage_s3_dispatch
    stage_s4_bd042_relocation
    stage_s5_v11_artifacts
    stage_s6_report
}

main "$@"
